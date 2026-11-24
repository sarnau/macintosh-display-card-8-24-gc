#!/usr/bin/env python3
"""antelope_lit_high.py -- .lit key bits 11-17 for the relocated jump tables.

.lit's key is 0 in bits 18-23 (all relocated words have raw bits 18-23 = 0,
and their plaintexts are .text offsets below $40000).  Bits 11-17, like
.text's key above bit 15, behave as a step function of the word index: in
the dispatcher table, whose offsets are all below $1000, bits 12-17 of the
raw words are the key and read $3B x20, $24 x34, $25 x7.  Bit 11 belongs to
the step too (within each plateau of bits 12-17 it is 1 first, then 0);
taking it as periodic, as antelope_lit_key.py does, gives wrong targets.

For every relocated word, antelope_lit_key.py's bits 0-10 select the
candidate case-block starts (words after an unconditional jump in the module)
with the same low 11 bits.  Each candidate implies a value for key bits
11-17.  Then, in turn:

  agree      one candidate, and its value is that of the nearest sample on
             one side or the other (a sample: an entry whose candidates all
             imply one value)
  resolved   several candidates, exactly one with such a value
  joint      bits 0-10 of the key repeat (bit b every 24, 48, 96, 192, 384
             words for b <= 6, 7, 8, 9, 10); classes no agree/resolved entry
             pins are left free, and an entry with exactly one candidate
             under the free bits pins them (repeated until nothing changes)
  function   several candidates left, exactly one in the function of the
             nearest resolved entry on either side
  open       none of these

Printed per relocation base, with a check: how many targets lie in the same
function as a neighbouring target (some modules have two switches, so a
base can cover two tables).
With --list, every entry with its target.

Usage:  antelope_lit_high.py ACEF_100.bin [--list]
"""
import bisect, collections, contextlib, io, os, sys
import unmask_antelope_low as u
import antelope_lit_key as L

PER = {b: 24 if b <= 6 else 48 if b == 7 else 24 << (b - 6) for b in range(11)}


def entries(acef):
    """[(k, base, {offset: key bits 11-17})], .lit words, model bits 0-10."""
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
    m11 = {}
    rows = []
    for b, ks in sorted(groups.items()):
        if not use[b]:
            continue
        for k in ks:
            m11[k] = L.mid12(k, low8, fixed) & 0x7FF
            os_ = [L.PINS[k][1] - b] if k in L.PINS else cand[b]
            rows.append((k, b, os_))
    return sorted(rows), W, m11


def func_starts():
    s = []
    for ln in open(os.path.join(L.ANT, 'symbols.txt')):
        p = ln.split()
        if len(p) == 2 and p[0] == '.text':
            s.append(int(p[1], 16))
    return sorted(s)


def resolve(rows, W, m11):
    """{k: (base, how, target offset or None)}"""
    hi = lambda k, o: ((W[k] ^ o) >> 11) & 0x7F
    C = {k: {o: hi(k, o) for o in os_ if (W[k] ^ o) & 0x7FF == m11[k]} for k, b, os_ in rows}
    base = {k: b for k, b, _ in rows}
    smp = {k: next(iter(c.values())) for k, c in C.items() if c and len(set(c.values())) == 1}
    sk = sorted(smp)

    def allowed(k):
        i = bisect.bisect_left(sk, k)
        a = set()
        if i > 0:
            a.add(smp[sk[i - 1]])
        j = i + 1 if i < len(sk) and sk[i] == k else i
        if j < len(sk):
            a.add(smp[sk[j]])
        return a

    res = {}
    for k, b, os_ in rows:
        ok = [o for o, v in C[k].items() if v in allowed(k)]
        if len(ok) == 1:
            res[k] = (b, 'agree' if len(C[k]) == 1 else 'resolved', ok[0])
    pin = {}
    for k, (b, _, o) in res.items():
        for bit in range(11):
            pin[(bit, k % PER[bit])] = ((W[k] ^ o) >> bit) & 1

    def options(k, b, os_):
        free = [bit for bit in range(11) if (bit, k % PER[bit]) not in pin]
        want = sum(pin.get((bit, k % PER[bit]), (m11[k] >> bit) & 1) << bit for bit in range(11))
        fm = sum(1 << bit for bit in free)
        al = allowed(k)
        return [o for o in os_ if ((W[k] ^ o) ^ want) & 0x7FF & ~fm == 0 and hi(k, o) in al], free

    changed = True
    while changed:
        changed = False
        for k, b, os_ in rows:
            if k in res:
                continue
            opt, free = options(k, b, os_)
            if len(opt) == 1:
                res[k] = (b, 'joint', opt[0])
                for bit in free:
                    pin[(bit, k % PER[bit])] = ((W[k] ^ opt[0]) >> bit) & 1
                changed = True
    starts = func_starts()
    fn = lambda a: starts[bisect.bisect_right(starts, a) - 1]
    def near_fns(k, b):                 # functions of the nearest resolved
        rk = sorted(x for x, r in res.items() if r[0] == b and r[2] is not None and x != k)
        i = bisect.bisect_left(rk, k)
        return {fn(b + res[x][2]) for x in rk[max(0, i - 1):i + 1]}
    for k, b, os_ in rows:
        if k in res:
            continue
        opt, _ = options(k, b, os_)
        nf = near_fns(k, b)
        inm = [o for o in opt if fn(b + o) in nf]
        res[k] = (b, 'function', inm[0]) if len(inm) == 1 else (b, 'open', None)
    inmain = {k: r[2] is not None and fn(r[0] + r[2]) in near_fns(k, r[0]) for k, r in res.items()}
    return res, inmain


def main(acef, listing):
    rows, W, m11 = entries(acef)
    res, inmain = resolve(rows, W, m11)
    per = collections.defaultdict(collections.Counter)
    for k, (b, r, t) in res.items():
        per[b][r] += 1
        per[b]['in fn'] += inmain[k]
    tot = collections.Counter()
    order = ['agree', 'resolved', 'joint', 'function', 'open']
    for b in sorted(per):
        tot.update(per[b])
        n = sum(per[b][r] for r in order)
        print('base $%05X  %s; %d of %d targets next to one in their function' % (
            b, ', '.join('%s %d' % (r, per[b][r]) for r in order if per[b][r]), per[b]['in fn'], n - per[b]['open']))
    n = sum(tot[r] for r in order)
    print('total       %s; %d of %d targets next to one in their function' % (
        ', '.join('%s %d' % (r, tot[r]) for r in order), tot['in fn'], n - tot['open']))
    if listing:
        for k in sorted(res):
            b, r, t = res[k]
            print('  .lit $%04x  base $%05X  %-9s %s%s' % (4 * k, b, r, '$%05X' % (b + t) if t is not None else '-',
                                                           '' if t is None or inmain[k] else '  (outside)'))


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1], '--list' in sys.argv)
