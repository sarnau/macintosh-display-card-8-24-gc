#!/usr/bin/env python3
"""antelope_lit_high.py -- .lit key bits 12-17 for the relocated jump tables.

.lit's key is 0 in bits 18-23 (all relocated words have raw bits 18-23 = 0,
and their plaintexts are .text offsets below $40000).  Bits 12-17, like
.text's key above bit 15, behave as a step function of the word index: in
the dispatcher table, whose offsets are all below $1000, the raw bits are the
key and read $3B x20, $24 x34, $25 x7.

For every relocated word, antelope_lit_key.py's bits 0-11 select the
candidate case-block starts (words after an unconditional jump in the module)
with the same low 12 bits.  Each candidate implies a value for key bits 12-17.
Words with one candidate give samples; each word then takes the candidate
whose implied value is the mode of the nearest +-6 samples (when that mode is
at least twice as common as the next one).

Printed per table: agree (single candidate, fits its neighbours), resolved
(several candidates, one fits), outlier (single candidate against a clear
mode: probably a wrong bits 0-11 fit), unclear, and no candidate.  With
--list, every entry with its chosen target.

Usage:  antelope_lit_high.py ACEF_100.bin [--list]     (takes about a minute)
"""
import bisect, collections, contextlib, io, os, sys
import unmask_antelope_low as u
import antelope_lit_key as L


def entries(acef):
    W = u.words(os.path.join(L.ANT, 'lit.bin'))
    key = u.Key()
    with contextlib.redirect_stdout(io.StringIO()):
        sw, low8 = L.fit(W, key)
        groups, cand = L.lit_tables(acef)
        use = {}
        for b, ks in groups.items():
            lows = {c & 0xFF for c in cand[b]}
            use[b] = sum(((W[k] ^ low8(k)) & 0xFF) in lows for k in ks) >= 0.8 * len(ks)
        cons = {k: cand[b] for b, ks in groups.items() if use[b] for k in ks}
        for k, (b, t) in L.PINS.items():
            cons[k] = [t - b]
        fixed, _ = L.fit_mid(W, key, sw, low8, cons)
    rows = []
    for b, ks in sorted(groups.items()):
        if not use[b]:
            continue
        for k in ks:
            x = (W[k] ^ L.mid12(k, low8, fixed)) & 0xFFF
            c = [o for o in cand[b] if o & 0xFFF == x]
            if k in L.PINS:
                c = [L.PINS[k][1] - b]
            imp = {}
            for o in c:
                imp.setdefault(((W[k] >> 12) ^ (o >> 12)) & 0x3F, []).append(o)
            rows.append((k, b, imp))
    return sorted(rows)


def resolve(rows, w=6):
    uni = [(k, next(iter(imp))) for k, b, imp in rows if len(imp) == 1]
    uk = [k for k, _ in uni]
    out = []
    for k, b, imp in rows:
        i = bisect.bisect_left(uk, k)
        m = collections.Counter(v for kk, v in uni[max(0, i - w):i + w + 1] if kk != k).most_common(2)
        top = m[0][0] if m else None
        strong = bool(m) and (len(m) == 1 or m[0][1] >= 2 * m[1][1])
        if not imp:
            r, t = 'no candidate', None
        elif len(imp) == 1:
            v = next(iter(imp))
            r = 'agree' if v == top else ('outlier' if strong else 'unclear')
            t = imp[v][0] if r != 'outlier' else None
        elif strong and top in imp:
            r, t = 'resolved', imp[top][0]
        else:
            r, t = 'unclear', None
        out.append((k, b, r, t))
    return out


def main(acef, listing):
    res = resolve(entries(acef))
    per = collections.defaultdict(collections.Counter)
    for k, b, r, t in res:
        per[b][r] += 1
    tot = collections.Counter()
    for b in sorted(per):
        tot.update(per[b])
        print('base $%05X  %s' % (b, ', '.join('%s %d' % kv for kv in sorted(per[b].items()))))
    print('total       %s' % ', '.join('%s %d' % kv for kv in sorted(tot.items())))
    if listing:
        for k, b, r, t in res:
            print('  .lit $%04x  base $%05X  %-12s %s' % (4 * k, b, r, '$%05X' % (b + t) if t is not None else '-'))


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1], '--list' in sys.argv)
