#!/usr/bin/env python3
"""antelope_lit_strings.py -- Antelope's .lit strings with key bits 12-23.

antelope_lit_key.py fits bits 0-11 of .lit's key.  Bits 12-23 carry the
second and third character of each string word.  They come here from full
24-bit key samples: relocated .lit words whose fitted 12-bit offset picks
exactly one case block in its module (and the PINS entries), whose
plaintext is then known in full (482 samples, all agreeing with the fitted
bits 0-11).  The key's high bits are a step function along .lit, so each
string word takes bits 12-23 from the nearest sample and bits 0-11 from the
fit.  Most strings read correctly; single-bit errors remain in the middle
characters where a step falls between samples or a bits-8-11 class is off.

Usage:  antelope_lit_strings.py ACEF_100.bin
"""
import os, sys, bisect, collections, io, contextlib

import antelope_lit_key as LK, unmask_antelope_low as u
acef = sys.argv[1]
W = u.words(os.path.join(LK.ANT, 'lit.bin'))
key = u.Key()
with contextlib.redirect_stdout(io.StringIO()):
    sw, low8 = LK.fit(W, key)
    groups, cand = LK.lit_tables(acef)
    use = {}
    for b, ks in groups.items():
        lows = {c & 0xFF for c in cand[b]}
        use[b] = sum(((W[k] ^ low8(k)) & 0xFF) in lows for k in ks) >= 0.8 * len(ks)
    cons = {k: cand[b] for b, ks in groups.items() if use[b] for k in ks}
    for k, (b, t) in LK.PINS.items(): cons[k] = [t - b]
    fixed, check = LK.fit_mid(W, key, sw, low8, cons)
m12 = lambda k: LK.mid12(k, low8, fixed)
samples = {}
for b, ks in groups.items():
    if not use[b]: continue
    for k in ks:
        x = (W[k] ^ m12(k)) & 0xFFF
        c = [o for o in cand[b] if o & 0xFFF == x]
        if len(c) == 1:
            samples[k] = (W[k] ^ c[0]) & 0xFFFFFF
for k, (b, t) in LK.PINS.items():
    samples[k] = (W[k] ^ (t - b)) & 0xFFFFFF
# consistency: sample's low 12 bits vs fitted
bad = sum(1 for k, v in samples.items() if (v ^ m12(k)) & 0xFFF)
print('full-key samples:', len(samples), ' disagree with fitted bits 0-11:', bad)
sk = sorted(samples)
# step model for bits 12-23: high part H = (key - low12-part) ... use key>>12 from nearest sample, keep bits 0-11 from fit
def full(k):
    i = bisect.bisect_left(sk, k)
    near = [sk[x] for x in (i - 1, i) if 0 <= x < len(sk)]
    hs = {samples[x] >> 12 for x in near}
    n = min(near, key=lambda x: abs(x - k))
    return (samples[n] & ~0xFFF) | (m12(k) & 0xFFF), len(hs) == 1
print('high key bits along .lit (index: key>>12):', ' '.join('%d:%x' % (k, samples[k] >> 12) for k in sk[::12]))
ch = lambda c: chr(c) if 32 <= c < 127 else ('_' if c == 0 else '.')
runs, cur = [], [sw[0]]
for k in sw[1:]:
    if k - cur[-1] <= 2: cur.append(k)
    else: runs.append(cur); cur = [k]
runs.append(cur)
for r in runs:
    if len(r) < 3: continue
    s = ''
    for k in range(r[0], r[-1] + 1):
        kk, sure = full(k)
        p = W[k] ^ kk
        s += ''.join(ch(c) for c in p.to_bytes(4, 'big'))
    print('.lit $%04X  %s' % (4 * r[0], s))
