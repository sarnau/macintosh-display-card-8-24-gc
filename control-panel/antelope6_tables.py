#!/usr/bin/env python3
"""antelope6_tables.py -- System 6 Antelope: jump tables, dispatcher, pointers.

1. Address map System 7 -> System 6: functions as aligned by
   antelope6_compare.py; inside a pair, word by word (same opcodes) or along
   difflib's matching opcode runs.
2. Table samples: System 7's resolved .lit table entries
   (antelope_lit_high.py) are paired with System 6's by relocation base
   (System 7's base mapped) and entry index.  The mapped target gives the
   System 6 plaintext, so W6 ^ plaintext is a full key sample.  Checked
   against the string-derived key bits 0-8 (antelope6_lit.py) and printed.
3. Key bits 8-19 from the samples that agree: the conflicts per period
   (bits 9 and 10 repeat every 384 and 768 words; bits 11-19 are a step
   function, printed as plateaus).
4. The dispatcher table (base $2D59C, 60 entries): each command's System 6
   case blocks under bits 0-10, and the block System 7's handler maps to.
   Bit 11 is not sampled, so "same" means the mapped block fits bits 0-10
   (it need not follow a jump: the epilogue after the jmpi does not).
5. Address loads (const/consth with a .text symbol; an index whose symbol
   has section -3 names the next symbol) into the System 6-only block
   $331C4-$3DC84 and into the stubs $01378-$017C4, from outside them,
   with the System 7 site and what System 7 loads there.

Usage:  antelope6_tables.py SYS7_ACEF_100.bin SYS6_ACEF_100.bin SYS6_OUTDIR
"""
import bisect, collections, contextlib, difflib, io, os, sys
import antelope6_compare as C
import antelope6_lit as L6
import antelope_lit_high as H
import apply_reloc as a
import unmask_antelope_low as u
from antelope_partial_dasm import NAMES

PER = {0: 24, 1: 24, 2: 24, 3: 24, 4: 24, 5: 48, 6: 48, 7: 96, 8: 192, 9: 384, 10: 768}
DISP6, DISP7 = 0x2D59C, 0x31DA8
BLOCK6, STUBS6 = (0x331C4, 0x3DC84), (0x1378, 0x17F0)


def address_map(d6):
    W7 = u.words(os.path.join(u.ANT, 'text.bin'))
    E7, _ = u.unmask_estimated(W7)
    U6 = C.words(os.path.join(d6, 'text.partial.bin'))
    f7 = C.functions(os.path.join(u.ANT, 'symbols.txt'), len(W7))
    f6 = C.functions(os.path.join(d6, 'symbols.txt'), len(U6))
    ops = lambda X, s, e: bytes(X[k] >> 24 for k in range(s // 4, e // 4))
    A = [ops(E7, s, e) for s, e in f7]
    B = [ops(U6, s, e) for s, e in f6]
    al = C.align(A, B)
    u7 = [i for i, j, r in al if j is None]
    u6 = [j for i, j, r in al if i is None]
    cand = []
    for i in u7:
        for j in u6:
            if min(len(A[i]), len(B[j])) >= 4:
                sm = difflib.SequenceMatcher(None, A[i], B[j], autojunk=False)
                if sm.real_quick_ratio() >= C.MIN_RATIO and sm.quick_ratio() >= C.MIN_RATIO and sm.ratio() >= C.MIN_RATIO:
                    cand.append((sm.ratio(), i, j))
    pairs, s7, s6 = [(i, j) for i, j, r in al if i is not None and j is not None], set(), set()
    for r, i, j in sorted(cand, reverse=True):
        if i not in s7 and j not in s6:
            s7.add(i); s6.add(j); pairs.append((i, j))
    M = {}
    for i, j in pairs:
        a7, a6 = f7[i][0], f6[j][0]
        blocks = [(0, 0, len(A[i]))] if A[i] == B[j] else \
            difflib.SequenceMatcher(None, A[i], B[j], autojunk=False).get_matching_blocks()
        for p, q, n in blocks:
            for x in range(n):
                M[a7 + 4 * (p + x)] = a6 + 4 * (q + x)
    return M, U6


def lit_groups(acef):
    d, _, sp, ns, secs = a.load(acef)
    sym, _, _ = a.make_resolver(d, sp, ns, secs)
    s = [s for s in secs if s['name'] == '.lit'][0]
    g = collections.defaultdict(list)
    for va, si, ty in a.get_relocs(d, s):
        g[sym(si + 1)[1]].append(va // 4)
    return {b: sorted(v) for b, v in g.items()}


def text_pointers(acef):
    """{site: .text target} of the relocated const/consth pairs."""
    d, _, sp, ns, secs = a.load(acef)
    sym, _, _ = a.make_resolver(d, sp, ns, secs)
    t = [s for s in secs if s['name'] == '.text'][0]
    R = a.get_relocs(d, t)
    out = {}
    for i, (va, si, ty) in enumerate(R):
        if ty == 28 and i and R[i - 1][2] == 27:
            n = R[i - 1][1]
            n = n + 1 if sym(n)[0] == -3 else n
            sc, v = sym(n)
            if sc == 2:
                out[va - t['vaddr']] = v + si
    return out


def main(acef7, acef6, d6):
    M, U6 = address_map(d6)
    inv = {v: k for k, v in M.items()}
    print('address map: %d System 7 words placed in System 6' % len(M))
    with contextlib.redirect_stdout(io.StringIO()):
        rows, W7, m11 = H.entries(acef7)
        r7, _ = H.resolve(rows, W7, m11)
        W7s, K7, sw = L6.key7(acef7)
    W6 = L6.words(os.path.join(d6, 'lit.bin'))
    _, spairs = L6.align(W7s, W6, sw)
    X = {k6: ((W6[k6] ^ W7s[k7]) & 0xFFF) ^ K7[k7] for k7, k6 in spairs}
    T = {b: L6.periodic(X, b, P)[0] for b, P in L6.PER.items()}

    def low9(k):
        v = 0
        for b, P in L6.PER.items():
            r = T[b].get(k % P)
            if r is None:
                return None
            v |= r << b
        return v
    g7, g6 = lit_groups(acef7), lit_groups(acef6)
    print('\n.lit tables, System 7 -> System 6 (entries paired by index; target mapped; check: key bits 0-8):')
    Smp = {}
    for b7, ks7 in sorted(g7.items()):
        m = M.get(b7 + 4)
        b6 = next((b for b in g6 if m is not None and abs(b - (m - 4)) <= 8), None)
        if b6 is None:
            print('  $%05X %3d  -> no System 6 table' % (b7, len(ks7)))
            continue
        st = collections.Counter()
        for k7, k6 in zip(ks7, g6[b6]):
            r = r7.get(k7)
            if not r or r[2] is None:
                st['open in System 7'] += 1
                continue
            t6 = M.get(b7 + r[2])
            if t6 is None:
                st['target not mapped'] += 1
                continue
            kk, l = W6[k6] ^ (t6 - b6), low9(k6)
            if l is None:
                st['bits 0-8 unsampled'] += 1
            elif kk & 0x1FF == l:
                st['agree'] += 1
            else:
                st['differ'] += 1
                continue
            Smp[k6] = kk & 0xFFFFFF
        print('  $%05X %3d  -> $%05X %3d  %s' % (b7, len(ks7), b6, len(g6[b6]), ', '.join('%s %d' % kv for kv in sorted(st.items()))))
    print('\nkey bits 8-19 from %d table samples (conflicts/classes per period):' % len(Smp))
    for bit in range(8, 20):
        row = []
        for P in (192, 384, 768, 1536):
            c = collections.defaultdict(collections.Counter)
            for k, v in Smp.items():
                c[k % P][(v >> bit) & 1] += 1
            row.append('%d: %d/%d' % (P, sum(min(s.values()) for s in c.values() if len(s) > 1), len(c)))
        print('  bit %2d  %s' % (bit, '  '.join(row)))
    plat, prev = [], None
    for k in sorted(Smp):
        h = (Smp[k] >> 11) & 0x1FF
        if h != prev:
            plat.append('$%04x:%03x' % (4 * k, h)); prev = h
    print('  bits 11-19 plateaus (first .lit offset: value): ' + ' '.join(plat))
    P_ = {b: dict(T.get(b, {})) for b in PER}
    for b, per in PER.items():
        c = collections.defaultdict(collections.Counter)
        for k, v in Smp.items():
            c[k % per][(v >> b) & 1] += 1
        for r, cc in c.items():
            P_[b].setdefault(r, cc.most_common(1)[0][0])

    def low(k):
        v = mk = 0
        for b, per in PER.items():
            r = P_[b].get(k % per)
            if r is not None:
                v |= r << b; mk |= 1 << b
        return v, mk
    nb = min(b for b in g6 if b > DISP6)
    blocks = [x for x in range(DISP6 + 8, nb, 4) if U6[x // 4 - 2] >> 24 in (0xA0, 0xA1, 0xC0, 0xC1)]
    k7s = list(range(0xDE0 // 4, 0xDE0 // 4 + 61))
    print('\ndispatcher: command -> System 6 case blocks (bits 0-10 where sampled, offset < $1000) | System 7 handler mapped:')
    st = collections.Counter()
    for i, k6 in enumerate(g6[DISP6]):
        v, mk = low(k6)
        fits = lambda x: ((W6[k6] ^ (x - DISP6)) & mk & 0x7FF) == v & 0x7FF
        c = [x for x in blocks if fits(x) and x - DISP6 < 0x1000]
        t7 = DISP7 + r7[k7s[i]][2]
        p = M.get(t7)
        # bit 11 is not sampled here: a mapped target that fits bits 0-10 is
        # kept even if it is no block start (the epilogue after the jmpi)
        tag = 'open' if not mk & 0x7FF else 'same' if p is not None and fits(p) else 'differs' if c else 'open'
        st[tag] += 1
        print('  $%02X  %-24s | $%05X -> %s  %s' % (i, ' '.join('$%05X' % x for x in c[:3]) or '-', t7, '$%05X' % p if p else '-', tag))
    print('  ' + ', '.join('%s %d' % kv for kv in sorted(st.items())))
    p6, p7 = text_pointers(acef6), text_pointers(acef7)
    st6 = sorted({int(q[1], 16) for q in (ln.split() for ln in open(os.path.join(d6, 'symbols.txt'))) if len(q) == 2 and q[0] == '.text'})
    fn6 = lambda x: st6[bisect.bisect_right(st6, x) - 1]
    for name, (lo, hi) in (('the System 6-only block', BLOCK6), ('the name stubs', STUBS6)):
        print('\naddress loads into %s from outside it (site, function, target | System 7 site and its loads):' % name)
        for va, v in sorted(p6.items()):
            if lo <= v < hi and not lo <= va < hi:
                s7 = inv.get(va)
                near = sorted(v7 for x, v7 in p7.items() if s7 is not None and abs(x - s7) <= 8)
                f7 = inv.get(fn6(va))
                print('  $%05X in $%05X%s -> $%05X | %s' % (
                    va, fn6(va), ' (S7 $%05X %s)' % (f7, NAMES.get(f7, '')) if f7 else '', v,
                    'S7 $%05X loads %s' % (s7, ' '.join('$%05X' % x for x in near) or '-') if s7 else 'no System 7 site'))


if __name__ == '__main__':
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
