#!/usr/bin/env python3
"""antelope_reloc_samples.py -- key samples from Antelope's const/consth relocations.

Antelope's .text loads addresses with a const/consth pair.  The pair carries
three relocation records: R_ILOHALF (type 26) on the const, R_IHIHALF (27) on
the consth, and R_IHCONST (28), whose symbol-index field is not a symbol but
the low 16 bits of the addend.  The instructions hold the addend only (the
loader adds the symbol), so the plaintext is known:

    const  rX, addend & $FFFF   ->  RC = addend bits 8-15, I8 = addend bits 0-7
    consth rX, addend >> 16     ->  RC = 0, I8 = 0  (every addend is < $10000)

RC is bits 16-23 of the word, so each relocated word gives key bits 16-23
exactly.  Bits 0-15 come from unmask_antelope_low.py where it knows them.

Checks (printed): the const's plain low byte equals the addend's low byte in
1,889 of 1,898 pairs (the 9 others are not used); the derived bits 16-17
agree with the levels already known from the idiom samples in every case.

Usage:  antelope_reloc_samples.py ACEF_100.bin
        (rewrites firmware/ACEF_100_Antelope/mask_samples.tsv: drops old
        'ihconst' rows, adds the new ones, keeps the file sorted by k)
"""
import os, sys
import apply_reloc as a
import unmask_antelope_low as u

TSV = os.path.join(u.ANT, 'mask_samples.tsv')


def pairs(d, secs, W, key):
    """(const offset, consth offset, addend) for each relocated const/consth pair."""
    t = [s for s in secs if s['name'] == '.text'][0]
    lo, hi, ihc = {}, {}, {}
    for va, si, ty in a.get_relocs(d, t):
        o = va - t['vaddr']
        {26: lo, 27: hi, 28: ihc}.get(ty, {})[o] = si
    ra = lambda o: ((W[o // 4] ^ key(o // 4)[0]) >> 8) & 0x7F
    out = []
    for o2, s in sorted(hi.items()):
        if o2 in ihc:
            c = [o1 for o1 in lo if lo[o1] == s and 0 < o2 - o1 <= 64 and ra(o1) == ra(o2)]
            if c:
                out.append((max(c), o2, ihc[o2]))
    return out


def main(path):
    rows = [l for l in open(TSV).read().split('\n') if l]
    head, rows = rows[0], [r for r in rows[1:] if r.split('\t')[2] != 'ihconst']
    open(TSV, 'w').write('\n'.join([head] + rows) + '\n')     # Key() without old rows
    d, K, sp, ns, secs = a.load(path)
    W = u.words(os.path.join(u.ANT, 'text.bin'))
    key = u.Key()
    P = pairs(d, secs, W, key)
    good = [p for p in P if (W[p[0] // 4] ^ key(p[0] // 4)[0]) & 0xFF == p[2] & 0xFF]
    print('const/consth pairs: %d, const low byte = addend low byte: %d' % (len(P), len(good)))
    new, agree, bad, b15 = {}, 0, 0, 0
    for o1, o2, add in good:
        ks = (o1 // 4, o2 // 4)
        # both words name the same register: where one word's bit 15 (RA bit
        # 7, gr/lr) is plain, it gives the other word's key bit 15 too
        ra7 = [((W[k] ^ key(k)[0]) >> 15) & 1 for k in ks if key(k)[1] >= 16]
        for k, rc in ((ks[0], (add >> 8) & 0xFF), (ks[1], 0)):
            v, n = key(k)
            h = ((W[k] >> 16) & 0xFF) ^ rc
            if n < 16 and ra7:
                v, n = v | ((((W[k] >> 15) & 1) ^ ra7[0]) << 15), 16
                b15 += 1
            if n > 16:
                m = (1 << (n - 16)) - 1
                if (v >> 16) & m == h & m: agree += 1
                else: bad += 1
            if n >= 16:
                new[k] = (h << 16) | (v & 0xFFFF)
    print('bits 16-17 against the known levels: %d agree, %d disagree' % (agree, bad))
    print('words whose key bit 15 comes from the paired word: %d' % b15)
    assert bad == 0
    rows += ['%d\t%06x\tihconst' % (k, v) for k, v in new.items()]
    # a 16-bit 'pattern16' row (4 fields) goes before a 24-bit row at the same k
    rows.sort(key=lambda r: (int(r.split('\t')[0]), -len(r.split('\t'))))
    open(TSV, 'w').write('\n'.join([head] + rows) + '\n')
    print('added %d ihconst samples (24 bits) to %s' % (len(new), TSV))


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
