#!/usr/bin/env python3
"""unmask_antelope_low.py -- PARTIAL unmask of Antelope (ACEF_100) sections.

Antelope's key is 24 bits (unlike Hand's 23).  Only its low bits are known.
Each level below is linear above a table indexed by k mod P, and is exact on
all 4,620 samples in firmware/ACEF_100_Antelope/mask_samples.tsv (plus
held-out tests: 920/920, 851/851, 397/397):

    bits 0-12   key mod 2^13 = J13[k mod  384] + $0400 * (k div  384)
    bits 0-14   key mod 2^15 = J15[k mod 1536] + $7000 * (k div 1536)
    bits 0-15   key mod 2^16 = J16[k mod 6144] + $4000 * (k div 6144)

k = word index from the start of the section (.text and .lit share the
generator).  The tables are rebuilt from the samples file.  J13 is complete.
J15 covers 96% and J16 55% of their classes, so a word gets bits 13-14 or 15
only where its class holds a sample.  Bits 16-23 stay masked; bits 24-31
(opcode) were never masked.

What that means for an Am29000 word (op | RC | RA | RB/I):
    bits  0- 7  RB / low immediate byte      -> plain
    bits  8-12  RA's low 5 bits              -> plain
    bits 13-14  RA bits 5-6                  -> plain for ~96% of words
    bit  15     RA bit 7 (local vs global)   -> plain for ~55% of words
    bits 16-23  RC / high immediate byte     -> masked

Usage:
    unmask_antelope_low.py IN.bin OUT.bin   # unmask as many low bits as known
        also writes OUT.bin.known: one byte per word = number of plain low
        bits in that word of OUT.bin (13, 15 or 16)
    unmask_antelope_low.py --check          # the validation checks
"""
import struct, sys, os, collections

HERE = os.path.dirname(os.path.abspath(__file__))
ANT = os.path.join(HERE, 'firmware', 'ACEF_100_Antelope')
P, D, MASK = 384, 1024, 0x1FFF                      # the complete 13-bit level
LEVELS = [(384, 0x0400, 13), (1536, 0x7000, 15), (6144, 0x4000, 16)]


def load_samples():
    S, kind = {}, {}
    for line in open(os.path.join(ANT, 'mask_samples.tsv')).read().split('\n')[1:]:
        if line:
            k, v, p = line.split('\t')
            S[int(k)] = int(v, 16)
            kind[int(k)] = p
    return S, kind


def build_level(per, step, bits):
    S, _ = load_samples()
    m, J = (1 << bits) - 1, {}
    for k, v in S.items():
        x = (v - step * (k // per)) & m
        assert J.setdefault(k % per, x) == x, (per, k)   # the model is exact
    return J


def build_table():
    J = build_level(*LEVELS[0])
    assert len(J) == P
    return [J[r] for r in range(P)]


def key13(k, J):
    return (J[k % P] + D * (k // P)) & MASK


class Key:
    """Best known low bits of the key at word k: (value, number of bits)."""
    def __init__(self):
        self.tabs = [(per, step, bits, build_level(per, step, bits))
                     for per, step, bits in LEVELS]

    def __call__(self, k):
        best = None
        for per, step, bits, J in self.tabs:
            if k % per in J:
                best = ((J[k % per] + step * (k // per)) & ((1 << bits) - 1), bits)
        return best


def words(path):
    b = open(path, 'rb').read()
    return list(struct.unpack('>%dI' % (len(b) // 4), b[:len(b) // 4 * 4]))


def unmask(W, J):
    """Bits 0-12 only (the complete level)."""
    return [w ^ key13(i, J) for i, w in enumerate(W)]


def unmask_best(W):
    key = Key()
    out, known = [], []
    for i, w in enumerate(W):
        v, n = key(i)
        out.append(w ^ v)
        known.append(n)
    return out, known


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
    # 3. coverage of the deeper levels over .text
    _, known = unmask_best(words(os.path.join(ANT, 'text.bin')))
    print('.text words by plain low bits:', sorted(collections.Counter(known).items()))


if __name__ == '__main__':
    if sys.argv[1:] == ['--check']:
        check()
    elif len(sys.argv) == 3:
        U, known = unmask_best(words(sys.argv[1]))
        open(sys.argv[2], 'wb').write(struct.pack('>%dI' % len(U), *U))
        open(sys.argv[2] + '.known', 'wb').write(bytes(known))
        print('wrote', sys.argv[2], len(U), 'words;', 'plain low bits:',
              sorted(collections.Counter(known).items()))
    else:
        print(__doc__)
