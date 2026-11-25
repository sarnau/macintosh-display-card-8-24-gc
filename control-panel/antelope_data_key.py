#!/usr/bin/env python3
"""antelope_data_key.py -- Antelope's .data mask: structure and a first fit of its low bits.

.data does not decode with the .text key, neither at the same word index
nor restarted at each object file's .data start (antelope_modules.py).
But its low bits repeat like the .text key's: over words whose top byte is
zero (mostly small values and zeros), bits 0-4 are equal at distance 24 in
~76% of pairs and bits 0-7 at distance 48 in ~68%, against a few percent at
other distances.  So .data is masked by the same kind of generator (column
tables of period 24, 48, 96, ...) with its own tables.

This script prints that periodicity test, then fits key bits 0-10 per
class (bit b over k mod PER[b]) by majority over the zero-top-byte words,
assuming they are mostly zero, and reports how many decode to zero.  Bits
0-8 are well determined; bits 9-10 have only 2-4 samples per class and are
often wrong (decodes of $600/$400 where 0 is expected).

Usage:  antelope_data_key.py
"""
import collections, os
import unmask_antelope_low as u

PER = {0: 24, 1: 24, 2: 24, 3: 24, 4: 24, 5: 48, 6: 48, 7: 96, 8: 192, 9: 384, 10: 768}


def main():
    D = u.words(os.path.join(u.ANT, 'data.bin'))
    Z = [j for j, w in enumerate(D) if w >> 24 == 0]
    print('.data: %d words, %d with top byte 0' % (len(D), len(Z)))
    for bits in (5, 8):
        m = (1 << bits) - 1
        row = []
        for P in (1, 2, 4, 8, 12, 16, 24, 32, 48, 64, 96):
            pairs = [(D[j], D[j + P]) for j in Z if j + P < len(D) and D[j + P] >> 24 == 0]
            row.append('%d:%.0f%%' % (P, 100.0 * sum(1 for a, b in pairs if (a ^ b) & m == 0) / len(pairs)))
        print('bits 0-%d equal at distance P: %s' % (bits - 1, ' '.join(row)))
    key = {}
    for b, P in PER.items():
        for r in range(P):
            c = collections.Counter((D[j] >> b) & 1 for j in range(r, len(D), P) if D[j] >> 24 == 0)
            if c:
                key[(b, r)] = c.most_common(1)[0][0]
    k = lambda j: sum(key.get((b, j % P), 0) << b for b, P in PER.items())
    dec = [D[j] ^ k(j) for j in range(len(D))]
    for b in (5, 7, 9, 11):
        m = (1 << b) - 1
        n = sum(1 for j in Z if dec[j] & m == 0)
        print('zero-top words decoding to 0 in bits 0-%-2d: %3d  (chance %.1f)' % (b - 1, n, len(Z) / 2.0 ** b))


if __name__ == '__main__':
    main()
