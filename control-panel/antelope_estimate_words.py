#!/usr/bin/env python3
"""antelope_estimate_words.py -- full decode of Antelope .text words by
borrowing key bits 16-23 from neighbouring samples.

Key bits 18-23 change slowly (a 3-bit count, sign-extended), and bits 16-17
often stay put for a dozen words.  So where the nearest full 24-bit samples
on both sides of a word share bits 16-23, the word very likely has them too
('='); where they share only bits 18-23 and the low key model gives bits
16-17, those are combined ('~').  '-' is like '=' but bit 15 (RA's gr/lr
bit) is not known.  'S' is a sample word, '?' not estimated.

Checked on the dispatcher (sub_31e20): every estimated compare writes the
register its conditional jump tests, the wait loop jumps back to its own
start, and the exits land on the common epilogue.

Usage:  antelope_estimate_words.py START END     (hex .text addresses)
"""
import bisect, os, sys
import unmask_antelope_low as u
from am29k_dasm import decode


def main(lo, hi):
    T = u.words(os.path.join(u.ANT, 'text.bin'))
    key = u.Key()
    S, _ = u.load_samples()
    ks = sorted(S)
    for a in range(lo, hi, 4):
        k = a // 4
        if k in S:
            kv, f = S[k], 'S'
        else:
            v, n = key(k)
            i = bisect.bisect_left(ks, k)
            ha, hb = S[ks[i - 1]] >> 16, S[ks[min(i, len(ks) - 1)]] >> 16
            if ha == hb and n >= 16:
                kv, f = (ha << 16) | (v & 0xFFFF), '='
            elif ha == hb:                      # bit 15 (RA bit 7) not known
                kv, f = (ha << 16) | (v & 0x7FFF), '-'
            elif ha >> 2 == hb >> 2 and n >= 18:
                kv, f = ((ha >> 2) << 18) | (v & 0x3FFFF), '~'
            else:
                print('  %05x ?' % a)
                continue
        p = T[k] ^ kv
        mn, ops, _ = decode(p, a)
        print('  %05x %s %08x  %-8s %s' % (a, f, p, mn, ops))


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(int(sys.argv[1], 16), int(sys.argv[2], 16))
