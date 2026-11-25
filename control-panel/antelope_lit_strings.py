#!/usr/bin/env python3
"""antelope_lit_strings.py -- Antelope's .lit strings with key bits 8-23.

antelope_lit_key.py fits bits 0-11 of .lit's key.  Bits 12-23 carry the
second and third character of each string word.  They come here from full
24-bit key samples: relocated .lit words whose fitted 12-bit offset picks
exactly one case block in its module (and the PINS entries), whose
plaintext is then known in full (482 samples, all agreeing with the fitted
bits 0-11).  The key's high bits are a step function along .lit.

Refinement, scored with character bigrams of this repository's prose:
  1. each string word takes bits 12-23 from one of the nearest samples (two
     on each side), whichever reads best with its neighbours;
  2. bits 8-11 are refitted per class (bit b repeats every 24*2^(b-6)
     words) on the whole decoded string words; a class may change only if
     no relocated table word in it stops matching a case block.
Steps 1 and 2 alternate until nothing changes.  Printed: the strings before
and after, and the number of characters outside [ -~].

Usage:  antelope_lit_strings.py ACEF_100.bin
"""
import bisect, collections, contextlib, glob, io, math, os, sys
import antelope_lit_key as LK

# Strings whose text is certain (read from the decode, and the first and
# fourth character of every word is plain, which the script checks): each
# word they cover in full gives a full key sample.
KNOWN = [(0x0548, b'DisposeOffscreen: NULL offscreen Handle\0'),
         (0x00D0, b'ITabMatch: Inverse Table is not up-to-date\0')]
import unmask_antelope_low as u


def bigram():
    here = os.path.dirname(os.path.abspath(__file__))
    txt = ''.join(open(f, errors='ignore').read() for f in
                  glob.glob(os.path.join(here, '*.md')) + glob.glob(os.path.join(here, '..', '*.md')))
    txt = ''.join(c for c in txt if 32 <= ord(c) < 127)
    big, uni = collections.Counter(zip(txt, txt[1:])), collections.Counter(txt)
    ch = lambda c: chr(c) if 32 <= c < 127 else ('\0' if c == 0 else None)

    def lp(a, b):
        ca, cb = ch(a), ch(b)
        if ca is None or cb is None:
            return -12.0
        if ca == '\0' or cb == '\0':
            return -3.0
        return math.log((big[(ca, cb)] + 0.1) / (uni[ca] + 9.6))
    return lp


def main(acef):
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
        for k, (b, t) in LK.PINS.items():
            cons[k] = [t - b]
        fixed, _ = LK.fit_mid(W, key, sw, low8, cons)
    m12 = lambda k: LK.mid12(k, low8, fixed)
    samples = {}
    for b, ks in groups.items():
        if use[b]:
            for k in ks:
                x = (W[k] ^ m12(k)) & 0xFFF
                c = [o for o in cand[b] if o & 0xFFF == x]
                if len(c) == 1:
                    samples[k] = (W[k] ^ c[0]) & 0xFFFFFF
    for k, (b, t) in LK.PINS.items():
        samples[k] = (W[k] ^ (t - b)) & 0xFFFFFF
    used = 0
    for off, txt in KNOWN:
        for i in range(len(txt) // 4):
            k = off // 4 + i
            w = int.from_bytes(txt[4 * i:4 * i + 4], 'big')
            if (W[k] ^ w) >> 24 == 0 and ((W[k] ^ m12(k)) ^ w) & 0xFF == 0:
                samples.setdefault(k, (W[k] ^ w) & 0xFFFFFF)
                used += 1
            else:
                print('known text does not fit .lit $%04X' % (4 * k))
    print('known-text words used as samples: %d' % used)
    bad = sum(1 for k, v in samples.items() if (v ^ m12(k)) & 0xFFF)
    print('full-key samples: %d (disagree with fitted bits 0-11: %d; known text may correct bits 8-11)' % (len(samples), bad))
    sk = sorted(samples)

    def highs(k):
        i = bisect.bisect_left(sk, k)
        near = [sk[x] for x in range(max(0, i - 2), min(len(sk), i + 2))]
        near.sort(key=lambda x: abs(x - k))
        out = []
        for x in near:
            if samples[x] & ~0xFFF not in out:
                out.append(samples[x] & ~0xFFF)
        return out
    swset = set(sw)
    hi = {k: highs(k)[0] for k in sw}
    lp = bigram()
    dec = lambda k: W[k] ^ samples[k] if k in samples else W[k] ^ (hi[k] | m12(k))
    by = lambda k: dec(k).to_bytes(4, 'big') if k in swset else b'\0\0\0\0'

    def wscore(k):
        p = by(k - 1)[3:] + by(k) + by(k + 1)[:1]
        return sum(lp(p[i], p[i + 1]) for i in range(len(p) - 1))

    def render():
        runs, cur = [], [sw[0]]
        for k in sw[1:]:
            if k - cur[-1] <= 2:
                cur.append(k)
            else:
                runs.append(cur)
                cur = [k]
        runs.append(cur)
        ch = lambda c: chr(c) if 32 <= c < 127 else ('_' if c == 0 else '.')
        lines, odd = [], 0
        for r in runs:
            if len(r) < 3:
                continue
            s = ''.join(ch(c) for k in range(r[0], r[-1] + 1) for c in by(k))
            odd += sum(1 for k in r for c in by(k) if not (32 <= c < 127 or c == 0))
            lines.append('.lit $%04X  %s' % (4 * r[0], s))
        return lines, odd
    before, odd0 = render()

    def tmatch_ok(bit, c):
        m = (1 << (bit + 1)) - 1
        t = sum(1 for k in cons if k % P_of[bit] == c and
                any((b & m) == ((W[k] ^ m12(k)) & m) for b in cons[k]))
        # full-key samples (table words with one candidate, known text) count double
        return t + 2 * sum(1 for k, v in samples.items() if k % P_of[bit] == c and not (v ^ m12(k)) & m)
    P_of = dict(LK.LEVELS)
    for it in range(4):
        changed = 0
        for k in sw:
            best = max(highs(k), key=lambda h: (hi.__setitem__(k, h), wscore(k))[1])
            if best != hi[k]:
                changed += 1
            hi[k] = best
        for bit, P in LK.LEVELS:
            for c in range(P):
                ks = [k for k in sw if k % P == c]
                if not ks:
                    continue
                keep = fixed.get((bit, c), 0)
                t0 = tmatch_ok(bit, c)
                s0 = sum(wscore(k) for k in ks)
                fixed[(bit, c)] = keep ^ 1
                if tmatch_ok(bit, c) >= t0 and sum(wscore(k) for k in ks) > s0 + 1.0:
                    changed += 1
                else:
                    fixed[(bit, c)] = keep
        if not changed:
            break
    after, odd1 = render()
    print('characters outside printable ASCII: %d before refinement, %d after\n' % (odd0, odd1))
    for ln in after:
        print(ln)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
