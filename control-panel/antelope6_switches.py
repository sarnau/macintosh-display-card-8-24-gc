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
              .lit $10EC); they are fitted here

Bits 11-15 step along .lit like the sampled plateaus of bits 11-19
(antelope6_tables.py): within a group of eight values the low three bits
run 2 3 0 1 6 7 4 5 (complete in the group $1D0-$1D7 at .lit $0B08-$0CB8),
then the group drops by 8.  The last plateau, $1BA at .lit $10E4, gives for
the codec tables the order SEQ below.  Each entry's h is one value of SEQ,
never earlier than the previous entry's; the assignment that places the
most entries (dynamic programming over .lit order) is kept.  An entry is
placed if, with its open low bits tried in all combinations, the target
lies in the jmpi's function and its word -2 is a jump (jmp, jmpi: a case
block starts after the previous one's delay slot).  Failing that, a target
that a direct jump (24 low bits known) lands on counts half (marked "j"):
used as a full test, it admits wrong targets.  Entries the assignment does
not place are listed with every h that places them.

For the sixteen four-way tables the result is also checked against the
shape of the code: case i at jmpi + 8 + $3C * i.  Where bits 0-10 are all
known, an unplaced entry also shows its target under its h without the
jump test.

Usage:  antelope6_switches.py SYS7_ACEF_100.bin SYS6_ACEF_100.bin SYS6_OUTDIR
"""
import bisect, os, sys
import antelope6_tables as T
from am29k_dasm import decode

BASE = 0x331C0
SEQ = (0x1A, 0x1B, 0x18, 0x19, 0x1E, 0x1F, 0x1C, 0x1D, 0x12, 0x13, 0x10, 0x11, 0x16, 0x17, 0x14, 0x15)
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

    def targets(k, h, lo, hi):
        v, mk = low(k)
        free = [b for b in range(11) if not mk >> b & 1]
        out, fb = set(), set()
        for m in range(1 << len(free)):
            vv = v & mk & 0x7FF
            for i, b in enumerate(free):
                vv |= (m >> i & 1) << b
            t = BASE + ((W6[k] ^ (vv | h << 11 | W6[k] & 0xFF0000)) & 0xFFFFFF)
            if lo <= t < hi:
                (out if isjmp(t) else fb if t in landed else set()).add(t)
        return sorted(out), sorted(fb), free

    def raw(k, h):
        v, mk = low(k)
        return BASE + ((W6[k] ^ (v & 0x7FF | h << 11 | W6[k] & 0xFF0000)) & 0xFFFFFF) if mk & 0x7FF == 0x7FF else None
    print('last table sample: .lit $%04X; key bits 16-19 in the codec tables: %s' % (
        4 * max(Smp), sorted({W6[k] >> 16 & 0xF for k in g6[BASE]})))
    ents = []
    for off, n, site in TABLES:
        i = bisect.bisect_right(st6, site)
        lo, hi = st6[i - 1], st6[i] if i < len(st6) else 4 * len(U6)
        for j in range(n):
            ents.append((off, j, off // 4 + j, lo, hi, [targets(off // 4 + j, h, lo, hi) for h in SEQ]))
    score = lambda r: 2 if r[0] else 1 if r[1] else 0
    best = [[score(ents[0][5][s]) for s in range(len(SEQ))]]
    back = [[0] * len(SEQ)]
    for e in ents[1:]:
        row, bk, run, arg = [], [], -1, 0
        for s in range(len(SEQ)):
            if best[-1][s] > run:
                run, arg = best[-1][s], s
            row.append(run + score(e[5][s])); bk.append(arg)
        best.append(row); back.append(bk)
    s = max(range(len(SEQ)), key=lambda s: best[-1][s])
    path = [s]
    for e in range(len(ents) - 1, 0, -1):
        s = back[e][s]; path.append(s)
    path.reverse()
    print('h = key bits 11-15, in the order %s; score %d of %d (2 per entry placed, 1 by a jump to it)' % (
        ' '.join('$%02X' % h for h in SEQ), best[-1][path[-1]], 2 * len(ents)))
    print('\nswitch tables (.lit offset, cases, jmpi site, function; [h] where h changes):')
    unplaced, four_ok, cur, e = [], 0, None, 0
    for off, n, site in TABLES:
        lo, hi = ents[e][3], ents[e][4]
        cells, tg = [], []
        for j in range(n):
            o, fb, free = ents[e][5][path[e]]
            h = SEQ[path[e]]
            tg.append(o)
            c = '$%05X' % o[0] if len(o) == 1 else '{%s}' % ' '.join('$%05X' % x for x in o) if o \
                else '$%05Xj' % fb[0] if len(fb) == 1 else '-'
            cells.append(('[$%02X]' % h if h != cur else '') + c)
            cur = h
            if not o and len(fb) != 1:
                k = ents[e][2]
                unplaced.append((off, j, h, free, [(hh, t) for hh in range(32) for t in targets(k, hh, lo, hi)[0]], raw(k, h)))
            e += 1
        print('  .lit $%04X %2d  jmpi $%05X in $%05X-$%05X' % (off, n, site, lo, hi))
        print('      ' + ' '.join(cells))
        if site in FOUR:
            want = [site + 8 + 0x3C * j for j in range(4)]
            fits = all(not o or want[j] in o for j, o in enumerate(tg))
            four_ok += fits
            if not fits:
                print('      does not fit jmpi + 8 + $3C * case')
    print('\nfour-way tables that fit jmpi + 8 + $3C * case: %d of %d' % (four_ok, len(FOUR)))
    print('\nentries not placed (every h that places them, and the target under their h):')
    for off, j, h, free, alts, rw in unplaced:
        print('  .lit $%04X case %2d (h=$%02X, open low bits %s): %s%s' % (
            off, j, h, free or '-', ' '.join('$%02X:$%05X' % a for a in alts) or 'none',
            '; with h, not after a jump: $%05X' % rw if rw else ''))

if __name__ == '__main__':
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
