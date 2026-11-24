#!/usr/bin/env python3
"""antelope6_switches.py -- the System 6 codec's switch targets (.lit base $331C0).

The 167 .lit entries relocated against $331C0 are 25 switch tables of the
'rpza' codec (HOST_CARD_PROTOCOL.md, section 10).  An entry is
target - $331C0, xored with the .lit key.  What is known of the key there:

  bits 0-10   periodic (antelope6_tables.lit_key: strings and checked table
              samples); bits 8-10 are open in some classes
  bits 16-23  every target lies in $331C4-$3DC84, so the offset is below
              $10000 and these key bits are the raw word's bits 16-23
  bits 11-15  not sampled this far into .lit (the last table sample is at
              .lit $10E4); they are fitted here

For each switch (table, size, jmpi site) and each value h of bits 11-15
(one per switch), the open low bits are tried in all combinations, and a
target counts if it lies in the jmpi's function and its word -2 is a jump
(jmp, jmpi: a case block starts after the previous one's delay slot).
Where bits 0-10 are all known and no h places an entry that way, a target
that a direct jump (24 low bits known) lands on is accepted as well
(marked "j"); it also breaks ties between values of h.  Used for every
entry, that test admits wrong targets (two four-way tables stop fitting),
so it is only a fallback.  The
h that places the most entries is kept.  Entries it does not place are
listed with every h that places them: the key's bits 11-15 change inside
some tables (for example between cases 6 and 7 of the 17-way table $1104).

For the sixteen four-way tables the result is also checked against the
shape of the code: case i at jmpi + 8 + $3C * i.  Where bits 0-10 are all
known, an unplaced entry also shows its target under the table's h without
the jump test: the decoder's cases 1, 2, 3, 5 go to $39CAC, a block entered
by jmp (from $393B4 and $39B44) whose word -2 is not a jump.

Usage:  antelope6_switches.py SYS7_ACEF_100.bin SYS6_ACEF_100.bin SYS6_OUTDIR
"""
import bisect, os, sys
import antelope6_tables as T
from am29k_dasm import decode

BASE = 0x331C0
FOUR = (0x35B54, 0x35C90, 0x35DCC, 0x35F08, 0x36044, 0x36180, 0x362BC, 0x363F8,
        0x36534, 0x36670, 0x367AC, 0x368E8, 0x36A24, 0x36B60, 0x36C9C, 0x36DD4)
TABLES = [(0x10F0, 5, 0x33414), (0x1104, 17, 0x34EE8)] + \
    [(0x1148 + 16 * i, 4, s) for i, s in enumerate(FOUR)] + \
    [(0x1248 + 32 * i, 8, s) for i, s in enumerate((0x38D6C, 0x3919C, 0x39580, 0x39A74))] + \
    [(0x12C8, 16, 0x3ACD8), (0x1308, 16, 0x3AF28), (0x1348, 17, 0x3BEBC)]


def main(acef7, acef6, d6):
    M, U6, W6, g6, r7, Smp, low = T.lit_key(acef7, acef6, d6)
    assert all(off // 4 + j in g6[BASE] for off, n, s in TABLES for j in range(n))
    st6 = sorted({int(q[1], 16) for q in (ln.split() for ln in open(os.path.join(d6, 'symbols.txt')))
                  if len(q) == 2 and q[0] == '.text'})
    K6 = open(os.path.join(d6, 'text.partial.bin.known'), 'rb').read()
    landed = set()
    for x in range(0x331C4, 0x3DC84, 4):
        if K6[x // 4] >= 24 and U6[x // 4] >> 24 in (0xA0, 0xA1, 0xAC, 0xAD, 0xA4, 0xA5):
            d = decode(U6[x // 4], x)
            if d[0] in ('jmp', 'jmpt', 'jmpf'):
                landed.add(int(str(d[1]).split('$')[-1], 16))
    isjmp = lambda a: U6[a // 4 - 2] >> 24 in (0xA0, 0xA1, 0xC0, 0xC1)

    def fallback(k, h, lo, hi):
        v, mk = low(k)
        if mk & 0x7FF != 0x7FF:
            return None
        t = BASE + ((W6[k] ^ (v & 0x7FF | h << 11 | W6[k] & 0xFF0000)) & 0xFFFFFF)
        return t if lo <= t < hi and t in landed else None

    def targets(k, h, lo, hi):
        v, mk = low(k)
        free = [b for b in range(11) if not mk >> b & 1]
        out = set()
        for m in range(1 << len(free)):
            vv = v & mk & 0x7FF
            for i, b in enumerate(free):
                vv |= (m >> i & 1) << b
            t = BASE + ((W6[k] ^ (vv | h << 11 | W6[k] & 0xFF0000)) & 0xFFFFFF)
            if lo <= t < hi and isjmp(t):
                out.add(t)
        return sorted(out), free
    print('last table sample: .lit $%04X; key bits 16-19 in the codec tables: %s' % (
        4 * max(Smp), sorted({W6[k] >> 16 & 0xF for k in g6[BASE]})))
    print('\nswitch tables (.lit offset, cases, jmpi site, function; h = key bits 11-15):')
    unplaced, four_ok = [], 0
    for off, n, site in TABLES:
        i = bisect.bisect_right(st6, site)
        lo, hi = st6[i - 1], st6[i] if i < len(st6) else 4 * len(U6)
        ks = [off // 4 + j for j in range(n)]
        best = max(((sum(1 for k in ks if targets(k, h, lo, hi)[0]),
                     sum(1 for k in ks if not targets(k, h, lo, hi)[0] and fallback(k, h, lo, hi)), h) for h in range(32)))
        h = best[2]
        tg = [targets(k, h, lo, hi) for k in ks]
        print('  .lit $%04X %2d  jmpi $%05X in $%05X-$%05X  h=$%02X: %d placed, %d by a jump to it' % (
            off, n, site, lo, hi, h, best[0], best[1]))
        cells = []
        for j, (o, free) in enumerate(tg):
            fb = None if o else fallback(ks[j], h, lo, hi)
            cells.append('$%05X' % o[0] if len(o) == 1 else '{%s}' % ' '.join('$%05X' % x for x in o) if o
                         else '$%05Xj' % fb if fb else '-')
            if not o and not fb:
                v, mk = low(ks[j])
                raw = BASE + ((W6[ks[j]] ^ (v & 0x7FF | h << 11 | W6[ks[j]] & 0xFF0000)) & 0xFFFFFF) \
                    if mk & 0x7FF == 0x7FF else None
                unplaced.append((off, j, h, free, [(hh, t) for hh in range(32) for t in targets(ks[j], hh, lo, hi)[0]], raw))
        print('      ' + ' '.join(cells))
        if site in FOUR:
            want = [site + 8 + 0x3C * j for j in range(4)]
            fits = all(not o or want[j] in o for j, (o, f) in enumerate(tg))
            four_ok += fits
            if not fits:
                print('      does not fit jmpi + 8 + $3C * case')
    print('\nfour-way tables that fit jmpi + 8 + $3C * case: %d of %d' % (four_ok, len(FOUR)))
    print('\nentries the switch\'s h does not place (every h that does, and the target):')
    print('  (j = placed only because a direct jump lands on the target)')
    for off, j, h, free, alts, raw in unplaced:
        print('  .lit $%04X case %2d (h=$%02X, open low bits %s): %s%s' % (
            off, j, h, free or '-', ' '.join('$%02X:$%05X' % a for a in alts) or 'none',
            '; with h, not after a jump: $%05X' % raw if raw else ''))


if __name__ == '__main__':
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
