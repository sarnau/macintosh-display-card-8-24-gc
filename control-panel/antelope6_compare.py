#!/usr/bin/env python3
"""antelope6_compare.py -- match the System 6 Antelope's functions to System 7's.

Both ACEF symbol tables list the .text entries without names, and in both
versions the opcode byte of every word is plain (System 7: the key covers
bits 0-23; System 6: the key's top byte is $00/$0F, see antelope6_key.py).
So each function (from one .text symbol to the next) has a known opcode
sequence in both, and the two function lists are aligned in order
(Needleman-Wunsch over functions, banded; a pair scores its difflib ratio
over the opcode bytes, pairs below 0.6 do not match).

For matched pairs with the same opcode sequence, the words whose 24 low
bits are known in both are compared too (System 7: unmask_estimated flags
S/=/t; System 6: 24 plain bits in text.partial.bin.known): a direct jump
or call differs where the targets moved, everything else should be equal.

Printed: the match statistics, the named System 7 functions (NAMES in
antelope_partial_dasm.py) with their System 6 addresses, and the functions
that differ.  With --map, every function pair.

Usage:  antelope6_compare.py SYS6_OUTDIR [--map]
        SYS6_OUTDIR as written by antelope6_key.py (text.bin, symbols.txt,
        text.partial.bin, text.partial.bin.known)
"""
import collections, difflib, os, struct, sys
import unmask_antelope_low as u
from am29k_dasm import decode
from antelope_partial_dasm import NAMES

BAND = 60
MIN_RATIO = 0.6


def words(path):
    b = open(path, 'rb').read()
    return list(struct.unpack('>%dI' % (len(b) // 4), b[:len(b) // 4 * 4]))


def functions(symfile, nwords):
    s = sorted({int(p[1], 16) for p in (ln.split() for ln in open(symfile))
                if len(p) == 2 and p[0] == '.text'})
    s = [a for a in s if a < 4 * nwords]
    return [(a, (s[i + 1] if i + 1 < len(s) else 4 * nwords)) for i, a in enumerate(s)]


def align(A, B):
    """A, B: lists of opcode byte strings.  Returns [(i or None, j or None, ratio)]."""
    n, m = len(A), len(B)
    NEG = -1.0
    S, P = {}, {}
    S[(0, 0)] = 0.0

    def sim(i, j):
        a, b = A[i], B[j]
        if a == b:
            return 1.0
        sm = difflib.SequenceMatcher(None, a, b, autojunk=False)
        if sm.real_quick_ratio() < MIN_RATIO or sm.quick_ratio() < MIN_RATIO:
            return 0.0
        r = sm.ratio()
        return r if r >= MIN_RATIO else 0.0
    R = {}
    for i in range(n + 1):
        jc = i * m // max(n, 1)
        for j in range(max(0, jc - BAND), min(m, jc + BAND) + 1):
            if (i, j) == (0, 0):
                continue
            best, bp = NEG, None
            if i > 0 and (i - 1, j) in S and S[(i - 1, j)] > best:
                best, bp = S[(i - 1, j)], 'a'
            if j > 0 and (i, j - 1) in S and S[(i, j - 1)] > best:
                best, bp = S[(i, j - 1)], 'b'
            if i > 0 and j > 0 and (i - 1, j - 1) in S:
                r = sim(i - 1, j - 1)
                if r > 0 and S[(i - 1, j - 1)] + r > best:
                    best, bp = S[(i - 1, j - 1)] + r, 'm'
                    R[(i, j)] = r
            if bp:
                S[(i, j)], P[(i, j)] = best, bp
    out, i, j = [], n, m
    while (i, j) != (0, 0):
        bp = P[(i, j)]
        if bp == 'm':
            out.append((i - 1, j - 1, R[(i, j)]))
            i, j = i - 1, j - 1
        elif bp == 'a':
            out.append((i - 1, None, 0))
            i -= 1
        else:
            out.append((None, j - 1, 0))
            j -= 1
    return out[::-1]


def main(d6, show_map):
    W7 = u.words(os.path.join(u.ANT, 'text.bin'))
    E7, F7 = u.unmask_estimated(W7)
    U6 = words(os.path.join(d6, 'text.partial.bin'))
    K6 = open(os.path.join(d6, 'text.partial.bin.known'), 'rb').read()
    f7 = functions(os.path.join(u.ANT, 'symbols.txt'), len(W7))
    f6 = functions(os.path.join(d6, 'symbols.txt'), len(U6))
    ops = lambda X, a, e: bytes(X[k] >> 24 for k in range(a // 4, e // 4))
    A = [ops(E7, a, e) for a, e in f7]
    B = [ops(U6, a, e) for a, e in f6]
    al = align(A, B)
    # second pass: unmatched functions paired in any order (moved code)
    u7 = [i for i, j, r in al if j is None]
    u6 = [j for i, j, r in al if i is None]
    pairs = []
    for i in u7:
        for j in u6:
            if min(len(A[i]), len(B[j])) < 4:
                continue
            sm = difflib.SequenceMatcher(None, A[i], B[j], autojunk=False)
            if sm.real_quick_ratio() >= MIN_RATIO and sm.quick_ratio() >= MIN_RATIO:
                r = sm.ratio()
                if r >= MIN_RATIO:
                    pairs.append((r, i, j))
    moved, used7, used6 = [], set(), set()
    for r, i, j in sorted(pairs, reverse=True):
        if i not in used7 and j not in used6:
            used7.add(i); used6.add(j)
            moved.append((i, j, r))
    al = [x for x in al if not (x[1] is None and x[0] in used7) and not (x[0] is None and x[1] in used6)]
    st = collections.Counter()
    m76 = {}
    wcmp = collections.Counter()
    diff_words = collections.Counter()
    for i, j, r in al:
        if i is None:
            st['System 6 only'] += 1
            continue
        if j is None:
            st['System 7 only'] += 1
            continue
        m76[f7[i][0]] = (f6[j][0], r)
        if A[i] == B[j]:
            st['same opcodes'] += 1
            d = f6[j][0] - f7[i][0]
            for x in range(len(A[i])):
                k7, k6 = f7[i][0] // 4 + x, f6[j][0] // 4 + x
                if F7[k7] == '?' or K6[k6] < 24:
                    continue
                w7, w6 = E7[k7], U6[k6]
                if w7 == w6:
                    wcmp['equal'] += 1
                    continue
                mn = decode(w7, 4 * k7)[0]
                if mn in ('call', 'jmp', 'jmpt', 'jmpf', 'jmpfdec'):
                    # a pc-relative target: equal if both point at matched code
                    wcmp['pc-relative, differs'] += 1
                else:
                    wcmp['differs'] += 1
                    diff_words[mn] += 1
        else:
            st['similar (ratio >= %.1f)' % MIN_RATIO] += 1
    print('System 7: %d functions, %d words; System 6: %d functions, %d words' % (
        len(f7), len(W7), len(f6), len(U6)))
    for i, j, r in moved:
        m76[f7[i][0]] = (f6[j][0], r)
    st['moved'] = len(moved)
    for k in ('same opcodes', 'similar (ratio >= %.1f)' % MIN_RATIO, 'moved', 'System 7 only', 'System 6 only'):
        print('  %-24s %d' % (k, st[k]))
    w7only = sum(len(A[i]) for i, j, r in al if j is None)
    w6only = sum(len(B[j]) for i, j, r in al if i is None)
    print('  words in System 7 only %d, in System 6 only %d' % (w7only, w6only))
    print('words known in both, in functions with the same opcodes:')
    for k, v in wcmp.most_common():
        print('  %-24s %d' % (k, v))
    if diff_words:
        print('  differing words by mnemonic:', ', '.join('%s %d' % kv for kv in diff_words.most_common(8)))
    print('\nnamed System 7 functions:')
    for a in sorted(NAMES):
        if a in m76:
            b, r = m76[a]
            print('  %05X -> %05X  %-22s %s' % (a, b, NAMES[a], 'same opcodes' if r == 1.0 else 'ratio %.2f' % r))
        elif a in dict(f7):
            print('  %05X -> -      %-22s no match' % (a, NAMES[a]))
    print('\nfunctions that differ (System 7 -> System 6, words):')
    for i, j, r in al:
        if i is not None and j is not None and A[i] == B[j]:
            continue
        s7 = '%05X %5d' % (f7[i][0], len(A[i])) if i is not None else '-' + ' ' * 10
        s6 = '%05X %5d' % (f6[j][0], len(B[j])) if j is not None else '-' + ' ' * 10
        nm = NAMES.get(f7[i][0], '') if i is not None else ''
        print('  %s -> %s  %s %s' % (s7, s6, 'ratio %.2f' % r if r else '', nm))  # moved ones listed below
    print('\nmoved (System 7 -> System 6, words, ratio):')
    for i, j, r in sorted(moved):
        print('  %05X %5d -> %05X %5d  %.2f %s' % (f7[i][0], len(A[i]), f6[j][0], len(B[j]), r, NAMES.get(f7[i][0], '')))
    if show_map:
        print('\nall pairs:')
        for i, j, r in al:
            print('  %s %s %.2f' % ('%05X' % f7[i][0] if i is not None else '-    ',
                                    '%05X' % f6[j][0] if j is not None else '-    ', r))


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1], '--map' in sys.argv)
