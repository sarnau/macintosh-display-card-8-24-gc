#!/usr/bin/env python3
"""antelope6_key.py -- the key of the System 6 Antelope (8.24 GC SW 1.1).

The System 6 ACEF 100 masks all 32 bits of a .text word, the opcode byte
included, with a key of its own.  Its structure, from the relocations and
then from the frame idioms:

    bits 24-31  $00 for words 0..20,557, $0F from about word 20,558 on
                (the switch point is fixed to within 4 words by the
                invalid-opcode count)
    bits 16-23  a step function of the word index: taken from the
                neighbouring samples where both sides agree
    bits  0-15  periodic, with no drift term: bit b repeats every 24 words
                for b <= 9 and every 24 * 2^(b-9) words above
                (bits 0-15: period 1,536)

Samples:
  * relocated const/consth pairs (R_ILOHALF/R_IHIHALF with the R_IHCONST
    addend): plaintext $03|addend<15:8>|RA|addend<7:0> and $02|00|RA|00,
    so key bits 0-7 and 16-31; pairs are matched by symbol and proximity,
    and the 9 whose low byte disagrees with the period-24 table are dropped;
  * direct calls with an R_IREL relocation: call lr0 with displacement 0,
    $A8008000 (all 32 bits);
  * once the opcode is plain: asgeu 64,gr1,gr126 (raw vector 0), asleu
    65,lr1,gr127 and jmpi lr0, which give bits 8-15.

Usage:  antelope6_key.py SYS6_ACEF_100.bin OUTDIR
        unpacks into OUTDIR and writes OUTDIR/text.partial.bin with
        text.partial.bin.known (one byte per word: number of plain low bits,
        counting the top byte as known separately; see the printout)
"""
import bisect, collections, os, struct, sys
import acef_unpack, apply_reloc as a
from am29k_dasm import decode

SWITCH = 20558          # first word of the $0F top-byte plateau (+-2)


def words(path):
    b = open(path, 'rb').read()
    return list(struct.unpack('>%dI' % (len(b) // 4), b[:len(b) // 4 * 4]))


def reloc_samples(acef, W):
    d, _, _, _, secs = a.load(acef)
    t = [s for s in secs if s['name'] == '.text'][0]
    lo, hi, ihc, irel = {}, {}, {}, {}
    for va, si, ty in a.get_relocs(d, t):
        {26: lo, 27: hi, 28: ihc, 24: irel}.get(ty, {})[(va - t['vaddr']) // 4] = si
    S = {}
    for k2, s in hi.items():
        if k2 in ihc:
            add = ihc[k2]
            S[k2] = (W[k2] ^ 0x02000000) & 0xFFFF00FF
            c = [k1 for k1 in lo if lo[k1] == s and 0 < k2 - k1 <= 16]
            if c:
                k1 = max(c)
                S[k1] = (W[k1] ^ (0x03000000 | ((add >> 8) & 0xFF) << 16 | (add & 0xFF))) & 0xFFFF00FF
    for k in irel:
        S[k] = W[k] ^ 0xA8008000
    return S


def build(W, S):
    votes = collections.defaultdict(collections.Counter)
    for k, v in S.items():
        votes[k % 24][v & 0xFF] += 1
    T24 = {r: c.most_common(1)[0][0] for r, c in votes.items()}
    S = {k: v for k, v in S.items() if v & 0xFF == T24[k % 24]}
    ks = sorted(S)

    def high(k):                        # key bits 16-31, or None
        if k in S:
            return S[k] >> 16
        i = bisect.bisect_left(ks, k)
        if 0 < i < len(ks) and S[ks[i - 1]] >> 16 == S[ks[i]] >> 16:
            return S[ks[i]] >> 16
        return None
    top = lambda k: 0 if k < SWITCH else 0x0F
    R = {}                              # k -> key bits 8-15 from the idioms
    for k, w in enumerate(W):
        h = high(k)
        if h is None:
            continue
        op, lo8, rc = (w >> 24) ^ top(k), (w ^ T24[k % 24]) & 0xFF, ((w >> 16) ^ h) & 0xFF
        if rc == 0:
            ra = {(0x5E, 0x7E): 0x01, (0x56, 0x7F): 0x81, (0xC0, 0x80): 0x00}.get((op, lo8))
            if ra is not None:
                R[k] = ((w >> 8) & 0xFF) ^ ra
    levels = []                         # (bits, period, table of bits 8..)
    for b in range(8, 16):
        P = 24 if b <= 9 else 24 << (b - 9)
        J = {}
        for k, x in R.items():
            v = (x >> (b - 8)) & 1
            assert J.setdefault(k % P, v) == v, ('period', b, P, k)
        levels.append((b, P, J))
    return T24, high, top, levels, len(S), len(R)


def unmask(W, T24, high, top, levels):
    out, known, ntop = [], [], 0
    for k, w in enumerate(W):
        kv, n = T24[k % 24], 8
        for b, P, J in levels:
            if k % P not in J:
                break
            kv |= J[k % P] << b
            n = b + 1
        h = high(k)
        if n == 16 and h is not None:
            kv |= (h & 0xFF) << 16
            n = 24
        kv |= top(k) << 24
        out.append(w ^ kv)
        known.append(n)
    return out, known


def main(acef, outdir):
    acef_unpack.unpack(acef, outdir)
    W = words(os.path.join(outdir, 'text.bin'))
    T24, high, top, levels, ns, ni = build(W, reloc_samples(acef, W))
    U, known = unmask(W, T24, high, top, levels)
    open(os.path.join(outdir, 'text.partial.bin'), 'wb').write(struct.pack('>%dI' % len(U), *U))
    open(os.path.join(outdir, 'text.partial.bin.known'), 'wb').write(bytes(known))
    inv = sum(decode(u & 0xFF000000, 0)[0] == '.word' for u in U)
    print('.text %d words; %d relocation samples, %d idiom samples' % (len(W), ns, ni))
    print('opcode byte plain for all words (top key $00 / $0F); invalid opcodes %.2f%%' % (100.0 * inv / len(W)))
    c = collections.Counter(known)
    for n in sorted(c):
        print('  plain low bits %2d: %6d words' % (n, c[n]))


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
