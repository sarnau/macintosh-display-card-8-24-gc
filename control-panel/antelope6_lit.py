#!/usr/bin/env python3
"""antelope6_lit.py -- the System 6 Antelope's .lit key, low bits, from System 7.

Both versions keep the same strings in .lit, and in both the top byte of a
.lit word is plain, so the two sections line up by their top bytes (difflib
over the whole section: five runs, shifted by 77 to 220 words).  For a
string word at System 7 index k7 and System 6 index k6 the plaintexts are
equal, so

    key6(k6) = W6[k6] ^ W7[k7] ^ key7(k7)

wherever System 7's key is known (bits 0-11 from antelope_lit_key.py).
The samples show, with no conflict at all:

    bits 0-4   period 24
    bits 5-6   period 48
    bit  7     period 96
    bit  8     period 192 (136 of the 192 classes sampled)

Bit 9 fits period 384 with 11 conflicts, bits 10-11 fit no period (System
7's own bits 9-11 are weak in string words, so these are not used).  Bits
12-19 of key6 ^ key7 are a step function of the word index, as in System
7; the step is 0 in bits 16-19 at the start of .lit, so the second
character of the first strings is plain.  Bits 18-23: not needed here.

With bits 0-8 every word's fourth character decodes (where its bit-8 class
is sampled).  Printed: the alignment, the bit periods, and System 6's
string runs as "c1 c2 . c4" per word ("." = the third character, masked;
the second character is raw, i.e. right where the step is 0).

With the System 6 ACEF, also the .lit references of the 26 eleven-word
stubs at $01378-$017C4 (const/consth of .lit+addend, then call $00E88),
with the string run each one names.

Usage:  antelope6_lit.py SYS7_ACEF_100.bin SYS6_OUTDIR [SYS6_ACEF_100.bin]
        SYS6_OUTDIR as written by antelope6_key.py
"""
import collections, contextlib, difflib, io, os, struct, sys
import antelope_lit_key as L
import unmask_antelope_low as u

PER = {0: 24, 1: 24, 2: 24, 3: 24, 4: 24, 5: 48, 6: 48, 7: 96, 8: 192}


def words(path):
    b = open(path, 'rb').read()
    return list(struct.unpack('>%dI' % (len(b) // 4), b[:len(b) // 4 * 4]))


def key7(acef7):
    """System 7 .lit words, key bits 0-11 per word, string word indices."""
    W7 = u.words(os.path.join(L.ANT, 'lit.bin'))
    key = u.Key()
    with contextlib.redirect_stdout(io.StringIO()):
        sw, low8 = L.fit(W7, key)
        groups, cand = L.lit_tables(acef7)
        use = {}
        for b, ks in groups.items():
            lows = {c & 0xFF for c in cand[b]}
            use[b] = sum(((W7[k] ^ low8(k)) & 0xFF) in lows for k in ks) >= 0.8 * len(ks)
        cons = {k: cand[b] for b, ks in groups.items() if use[b] for k in ks}
        for k, (b, t) in L.PINS.items():
            cons[k] = [t - b]
        fixed, _ = L.fit_mid(W7, key, sw, low8, cons)
    return W7, [L.mid12(k, low8, fixed) & 0xFFF for k in range(len(W7))], set(sw)


def align(W7, W6, sw):
    t7, t6 = bytes(w >> 24 for w in W7), bytes(w >> 24 for w in W6)
    sm = difflib.SequenceMatcher(None, t7, t6, autojunk=False)
    runs = [(a, b, n) for a, b, n in sm.get_matching_blocks() if n >= 4]
    pairs = [(a + i, b + i) for a, b, n in runs for i in range(n) if a + i in sw]
    return runs, pairs


def periodic(X, bit, P):
    c = collections.defaultdict(collections.Counter)
    for k, v in X.items():
        c[k % P][(v >> bit) & 1] += 1
    bad = sum(min(s.values()) for s in c.values() if len(s) > 1)
    return {r: s.most_common(1)[0][0] for r, s in c.items()}, bad, len(c)


def stubs(acef6):
    """[(stub address, .lit addend)] of the name stubs."""
    import apply_reloc as a
    d, _, _, _, secs = a.load(acef6)
    t = [s for s in secs if s['name'] == '.text'][0]
    out = []
    for va, si, ty in a.get_relocs(d, t):
        if ty == 28 and 0x1378 <= va - t['vaddr'] < 0x17F0:
            out.append(((va - t['vaddr'] - 0x14) & ~3, si))   # consth is word 5 of the stub
    return out


def main(acef7, d6, acef6):
    W7, K7, sw = key7(acef7)
    W6 = words(os.path.join(d6, 'lit.bin'))
    runs, pairs = align(W7, W6, sw)
    print('System 7 .lit %d words, System 6 .lit %d words; runs with the same top bytes:' % (len(W7), len(W6)))
    for a, b, n in runs:
        print('  S7 .lit $%04x  S6 .lit $%04x  %3d words  shift %+d' % (4 * a, 4 * b, n, b - a))
    X = {k6: ((W6[k6] ^ W7[k7]) & 0xFFF) ^ K7[k7] for k7, k6 in pairs}
    print('%d string-word pairs; key6 bits by period (conflicts / classes sampled):' % len(X))
    T = {}
    for bit in range(12):
        row = []
        for P in (24, 48, 96, 192, 384):
            tab, bad, n = periodic(X, bit, P)
            row.append('%d: %d/%d' % (P, bad, n))
            if bit in PER and P == PER[bit]:
                T[bit] = tab
        print('  bit %2d  %s' % (bit, '  '.join(row)))

    def low(k):
        v = 0
        for bit in range(9):
            r = T[bit].get(k % PER[bit])
            if r is None:
                return v, bit
            v |= r << bit
        return v, 9
    ch = lambda c: chr(c) if 32 <= c < 127 else '_'
    strw = [k for k in range(len(W6)) if 32 <= W6[k] >> 24 < 127 or (W6[k] >> 24 == 0 and k < 0x1A0 // 4)]
    runs6, cur = [], [strw[0]]
    for k in strw[1:]:
        if k - cur[-1] <= 2:
            cur.append(k)
        else:
            runs6.append(cur); cur = [k]
    runs6.append(cur)
    print('\nSystem 6 strings (per word: 1st, 2nd raw, 3rd masked, 4th decoded; "?" = bit-8 class not sampled):')
    for r in runs6:
        if len(r) < 4:
            continue
        s = []
        for k in range(r[0], r[-1] + 1):
            v, n = low(k)
            s.append(ch(W6[k] >> 24) + ch((W6[k] >> 16) & 0xFF) + '.' + (ch((W6[k] ^ v) & 0xFF) if n >= 8 else '?'))
        print('  .lit $%04x  %s' % (4 * r[0], ' '.join(s)))
    if acef6:
        print('\nname stubs (stub -> .lit offset, the string there):')
        for a, off in stubs(acef6):
            k, s = off // 4, ''
            while k < 0x1A0 // 4:
                v, n = low(k)
                w = W6[k]
                cs = [w >> 24, (w >> 16) & 0xFF, None, (w ^ v) & 0xFF if n >= 8 else None]
                s += ''.join('.' if c is None else '' if c == 0 else ch(c) for c in cs)
                if 0 in cs:
                    break
                k += 1
            print('  $%05X  .lit $%03x  %s' % (a, off, s))


if __name__ == '__main__':
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
