#!/usr/bin/env python3
"""antelope_data_key.py -- Antelope's .data mask: structure and a first fit of its low bits.

.data does not decode with the .text key, neither at the same word index
nor restarted at each object file's .data start (antelope_modules.py).
But its low bits repeat like the .text key's: over words whose top byte is
zero (mostly small values and zeros), bits 0-4 are equal at distance 24 in
~76% of pairs and bits 0-7 at distance 48 in ~68%, against a few percent at
other distances.  So .data is masked by the same kind of generator (column
tables of period 24, 48, 96, ...) with its own tables.

This script prints that periodicity test and a per-bit majority fit, then
the model used for decoding:

  bits 0-12   key mod 2^13 = J13[k mod P] + D * (k div P); System 7:
              P = 48, D = $800 (pairs 48 apart differ by $800 in 145 of 149
              cases); System 6: P = 96, D = $1000.  Picked from the data.
  bits 13-23  a step function of k, taken from the nearest sample:
              - words that decode to 0 in bits 0-12 (assumed zero, raw = key)
              - the 101 relocated words (type 31, against a file's .text or
                .data1 start): their plaintext is an offset inside a file
                smaller than 8 KB, so its bits 13-23 are 0
              J13 is refitted on the zero words three times.

Check: each relocated word, decoded with the other samples only, must be a
4-aligned offset inside its target file: 98 of 101 are.  With the ACEF
given, the decoded section is written to data.partial.bin; the sidecar
data.partial.bin.flag has one byte per word: 'z' a sample (zero word),
'r' a relocated word, '=' both neighbouring samples agree on bits 13-23,
'~' they differ (nearest taken: bits 13-23 less sure).

Usage:  antelope_data_key.py [ACEF_100.bin [DIR]]   (DIR: the unpacked image, default the System 7 one)
"""
import bisect, collections, os, struct, sys
import unmask_antelope_low as u

PER = {0: 24, 1: 24, 2: 24, 3: 24, 4: 24, 5: 48, 6: 48, 7: 96, 8: 192, 9: 384, 10: 768}


def main():
    out = sys.argv[2] if len(sys.argv) > 2 else u.ANT
    D = u.words(os.path.join(out, 'data.bin'))
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

    if len(sys.argv) > 1:
        decode(D, sys.argv[1], out)


def decode(D, acef, outdir):
    import apply_reloc as a
    import antelope_modules as am
    N = len(D)
    cands = [j for j in range(N) if D[j] >> 24 == 0]
    # period and step of the 13-bit level: the smallest P (48, 96, 192) at
    # which word pairs P apart that both decode to 0 in bits 0-4 differ by
    # one constant in bits 0-12 (System 7: 48/$800, System 6: 96/$1000)
    lo5 = {}
    for r in range(24):
        c = collections.Counter(D[j] & 0x1F for j in cands if j % 24 == r)
        lo5[r] = c.most_common(1)[0][0]
    Z5 = set(j for j in cands if (D[j] ^ lo5[j % 24]) & 0x1F == 0)
    P0 = D0 = None
    for P in (48, 96, 192):
        c = collections.Counter((D[j + P] - D[j]) & 0x1FFF for j in Z5 if j + P in Z5)
        v, n = c.most_common(1)[0]
        if n >= 0.7 * sum(c.values()):
            P0, D0 = P, v
            break
    print('13-bit level: key mod 2^13 = J13[k mod %d] + $%X * (k div %d)' % (P0, D0, P0))

    def fit(js):
        J = {}
        for r in range(P0):
            c = collections.Counter((D[j] - D0 * (j // P0)) & 0x1FFF for j in js if j % P0 == r)
            if c:
                J[r] = c.most_common(1)[0][0]
        return J
    J = fit(cands)
    for _ in range(3):
        J = fit([j for j in cands if (D[j] - J.get(j % P0, 0) - D0 * (j // P0)) & 0x1FFF == 0])
    L = lambda j: J.get(j % P0, 0) + D0 * (j // P0)
    H = {j: (D[j] - L(j)) & 0xFFFFFF for j in cands if (D[j] - L(j)) & 0x1FFF == 0}
    kind = {j: 'z' for j in H}
    d, _, sp, ns, secs = a.load(acef)
    S = lambda i: struct.unpack('>hI', d[sp + 6 * i:sp + 6 * i + 6])
    h = am.header(d)
    fs, _, _ = am.files(d, h['symptr'], h['nsyms'])
    own, _ = am.split_globals(fs[-1])
    rows = [am.classify(f['syms']) for f in fs[:-1]] + [am.classify(own)]
    ts = sorted({r['start'] for r in rows if r['start'] is not None})
    size = lambda t: next((x for x in ts if x > t), h['sizes'][0]) - t
    sec = [x for x in secs if x['name'] == '.data'][0]
    rel = []
    for i in range(sec['nrel']):
        va, si, ty = struct.unpack('>IHH', d[sec['relptr'] + 8 * i:sec['relptr'] + 8 * i + 8])
        sc, val = S(si + 1) if S(si)[0] == -3 else S(si)
        lim = size(val) if sc == 2 else 0x4C
        rel.append((va // 4, lim))
    for j, lim in rel:
        if lim <= 0x2000:
            H[j] = ((D[j] >> 13 << 13) - (L(j) & ~0x1FFF)) & 0xFFFFFF
            kind[j] = 'r' if j not in kind else kind[j]
    zs = sorted(H)

    def key(j, skip=None):
        i = bisect.bisect_left(zs, j)
        near = [zs[x] for x in range(max(0, i - 2), min(len(zs), i + 2)) if zs[x] != skip]
        lo = [x for x in near if x <= j][-1:]
        hi = [x for x in near if x >= j][:1]
        both = lo + hi
        hh = H[min(both, key=lambda x: abs(x - j))]
        same = len({H[x] >> 13 for x in both}) == 1
        return (hh + L(j)) & 0xFFFFFF, same
    good = 0
    for j, lim in rel:
        k, _ = key(j, skip=j)
        p = (D[j] ^ k) & 0xFFFFFF
        good += p < lim and p % 4 == 0
    print('relocated words decoding (held out) to an aligned offset inside their file: %d of %d' % (good, len(rel)))
    out, flag = [], []
    for j in range(N):
        k, same = key(j)
        out.append(D[j] ^ k)
        flag.append(kind.get(j, '=' if same else '~'))
    base = os.path.join(outdir, 'data.partial.bin')
    open(base, 'wb').write(struct.pack('>%dI' % N, *out))
    open(base + '.flag', 'w').write(''.join(flag))
    print('wrote %s (+ .flag): %s' % (base, dict(collections.Counter(flag))))


if __name__ == '__main__':
    main()
