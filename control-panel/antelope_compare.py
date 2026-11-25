#!/usr/bin/env python3
"""antelope_compare.py -- compare two Antelope builds function by function.

Both ACEFs are decrypted exactly (antelope_dasm.Image).  A function's
signature is its word sequence with relocated words reduced to their opcode
byte and call displacements dropped, so moved code compares equal.  The two
function lists are aligned in order (difflib) on these signatures; inside a
replaced stretch, functions are paired in order when their opcode sequences
are similar (ratio >= 0.6).  Printed: the counts, then every function that
is not identical (changed pairs with their similarity, and the functions
found in only one build), with names from antelope_names.py.

Usage:  antelope_compare.py OLD_ACEF_100.bin NEW_ACEF_100.bin
        (names are taken from NEW, the System 7 build, by default)
"""
import difflib, sys
from antelope_dasm import Image, functions, signature, match_names
from antelope_names import NAMES


def funcs(img):
    W, rel = img.words('.text'), img.relocs('.text')
    syms, _, _ = functions(img)
    ends = syms[1:] + [4 * len(W)]
    return [(a, b, signature(W, rel, a, b), tuple(W[k] >> 24 for k in range(a // 4, b // 4)))
            for a, b in zip(syms, ends)]


def main(old, new):
    io, inew = Image(old), Image(new)
    A, B = funcs(io), funcs(inew)
    nm_old = match_names(io, inew)
    nm = lambda a, names: (' ' + names[a]) if a in names else ''
    sm = difflib.SequenceMatcher(None, [f[2] for f in A], [f[2] for f in B], autojunk=False)
    same = changed = only_a = only_b = 0
    rows = []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == 'equal':
            same += i2 - i1
            continue
        i, j = i1, j1
        while i < i2 or j < j2:
            if i < i2 and j < j2:
                r = difflib.SequenceMatcher(None, A[i][3], B[j][3], autojunk=False).ratio()
                if r >= 0.6:
                    changed += 1
                    rows.append('changed  $%05X (%d words) -> $%05X (%d words)  %.2f%s' % (
                        A[i][0], (A[i][1] - A[i][0]) // 4, B[j][0], (B[j][1] - B[j][0]) // 4, r, nm(B[j][0], NAMES)))
                    i += 1; j += 1
                    continue
            if i < i2 and (j >= j2 or (A[i][1] - A[i][0]) <= (B[j][1] - B[j][0])):
                only_a += 1
                rows.append('only old $%05X (%d words)%s' % (A[i][0], (A[i][1] - A[i][0]) // 4, nm(A[i][0], nm_old)))
                i += 1
            else:
                only_b += 1
                rows.append('only new $%05X (%d words)%s' % (B[j][0], (B[j][1] - B[j][0]) // 4, nm(B[j][0], NAMES)))
                j += 1
    print('%s: %d functions; %s: %d functions' % (old, len(A), new, len(B)))
    print('identical %d, changed %d, only in old %d, only in new %d\n' % (same, changed, only_a, only_b))
    print('\n'.join(rows))


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
