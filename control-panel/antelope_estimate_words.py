#!/usr/bin/env python3
"""antelope_estimate_words.py -- full decode of Antelope .text words, with
key bits 16-23 from unmask_antelope_low.high_key().

key >> 16 is a monotone step function of the word index (about 240 steps
over .text).  Flags:
    S   a sample word (its key is known)
    =   both neighbouring samples have the same bits 16-23 (never wrong in a
        leave-one-out test on 8,268 samples)
    t   inside a step: the switch point was chosen from opcode statistics
        (703/703 held-out samples right, but those are idiom words)
    ?   not estimated (ambiguous step, or bit 15 unknown): low bits only

Independent check (not used in the fit): of the 7,773 direct jumps and
calls among '=' and 't' words, every call lands on a function start and
all jumps but one stay in their function or are tail jumps to a function
start.

Usage:  antelope_estimate_words.py START END     (hex .text addresses)
"""
import os, sys
import unmask_antelope_low as u
from am29k_dasm import decode


def main(lo, hi):
    W = u.words(os.path.join(u.ANT, 'text.bin'))
    E, F = u.unmask_estimated(W)
    for a in range(lo, hi, 4):
        k = a // 4
        if F[k] == '?':
            print('  %05x ? %02x??%04x' % (a, E[k] >> 24, E[k] & 0xFFFF))
            continue
        mn, ops, _ = decode(E[k], a)
        print('  %05x %s %08x  %-8s %s' % (a, F[k], E[k], mn, ops))


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(int(sys.argv[1], 16), int(sys.argv[2], 16))
