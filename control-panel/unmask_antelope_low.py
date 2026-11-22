#!/usr/bin/env python3
"""unmask_antelope_low.py -- PARTIAL unmask of Antelope (ACEF_100) sections.

Only key bits 0-12 are known.  Model (exact on all 3,726 samples in
firmware/ACEF_100_Antelope/mask_samples.tsv, 726/726 on held-out samples):

    key(k) mod 2^13 = J[k mod 384] + 1024 * (k div 384)      (mod 2^13)

k = word index from the start of the section (.text and .lit share the
generator).  J is rebuilt from the samples file.  Bits 13-22 of the output
are STILL MASKED, and bits 24-31 (opcode) were never masked.

What that means for an Am29000 word (op | RC | RA | RB/I):
    bits  0- 7  RB / low immediate byte      -> plain
    bits  8-12  RA's low 5 bits              -> plain
    bits 13-15  RA's top 3 bits (lr/gr)      -> masked
    bits 16-22  RC's low 7 bits / high imm   -> masked
    bit  23     never masked

Usage:
    unmask_antelope_low.py IN.bin OUT.bin      # XOR bits 0-12 of every word
    unmask_antelope_low.py --check             # the validation checks below
"""
import struct, sys, os, collections

HERE = os.path.dirname(os.path.abspath(__file__))
ANT = os.path.join(HERE, 'firmware', 'ACEF_100_Antelope')
P, D, MASK = 384, 1024, 0x1FFF


def load_samples():
    S, kind = {}, {}
    for line in open(os.path.join(ANT, 'mask_samples.tsv')).read().split('\n')[1:]:
        if line:
            k, v, p = line.split('\t')
            S[int(k)] = int(v, 16)
            kind[int(k)] = p
    return S, kind


def build_table():
    S, _ = load_samples()
    J = {}
    for k, v in S.items():
        x = (v - D * (k // P)) & MASK
        assert J.setdefault(k % P, x) == x, k      # the model is exact
    assert len(J) == P
    return [J[r] for r in range(P)]


def key13(k, J):
    return (J[k % P] + D * (k // P)) & MASK


def words(path):
    b = open(path, 'rb').read()
    return list(struct.unpack('>%dI' % (len(b) // 4), b[:len(b) // 4 * 4]))


def unmask(W, J):
    return [w ^ key13(i, J) for i, w in enumerate(W)]


def check():
    J = build_table()
    S, kind = load_samples()
    U = unmask(words(os.path.join(ANT, 'text.bin')), J)
    # 1. prologues: the word before each 'asgeu 64' is sub gr1,gr1,N
    ag = [k for k in S if kind[k] == 'asgeu64']
    pre = [U[k - 1] for k in ag]
    sub = [w for w in pre if w >> 24 == 0x25 and (w >> 8) & 0x1F == 1]
    print('word before asgeu 64: sub gr1,gr1,N in %d/%d; N%%8==0 in %d' %
          (len(sub), len(ag), sum(1 for w in sub if w & 7 == 0)))
    print('  frame sizes N:', collections.Counter(w & 0xFF for w in sub).most_common(10))
    # 2. .lit switch tables: decoded targets are aligned and clustered
    L = unmask(words(os.path.join(ANT, 'lit.bin')), J)
    print('.lit words 2..51 (first relocated run), target mod 8 KB:')
    print('  ' + ' '.join('%04x' % (w & MASK) for w in L[2:52]))


if __name__ == '__main__':
    if sys.argv[1:] == ['--check']:
        check()
    elif len(sys.argv) == 3:
        J = build_table()
        U = unmask(words(sys.argv[1]), J)
        open(sys.argv[2], 'wb').write(struct.pack('>%dI' % len(U), *U))
        print('wrote', sys.argv[2], len(U), 'words (bits 0-12 unmasked only)')
    else:
        print(__doc__)
