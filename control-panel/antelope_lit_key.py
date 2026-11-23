#!/usr/bin/env python3
"""antelope_lit_key.py -- Antelope's .lit key, bits 0-7, from the ASCII strings in .lit.

The mask covers bits 0-23 of each word, so a .lit word's top byte is plain.
Words whose top byte is printable are string words (396 of them, outside the
relocated runs).  Their fourth character (bits 0-7) is masked, and two facts
recover the key there:

* bits 0-6 of .lit's key repeat every 24 words (the dispatcher table shows
  it; .text's bit 6 needs 48).  Bits 0-1 equal the .text key at the same
  index (all 662 relocated words are 4-aligned with it).  So each of the 24
  classes k mod 24 has 32 candidates; the one whose string words decode to
  the most English-like fourth characters wins.
* bit 7 of an ASCII byte is 0, so key bit 7 is the raw bit 7.  It repeats
  every 48 words (0 conflicts in 348 repeats).

Checks (printed): the reporter's format string at .lit $0DC8 then reads
"U..no.. F..ct..n:..x%" ("Unknown Function: 0x%x"), and all 61 entries of the
dispatcher table (.lit $0DE0) decode to the low byte of a case-block start.

The table's bits 8-13 are estimated from the .text key 19 words earlier (the
lag found from the table's high bits), and each entry is matched to the case
block with the same low byte nearest that estimate.

Usage:  antelope_lit_key.py            # strings and the dispatcher table
"""
import collections, math, os
import unmask_antelope_low as u

ANT = u.ANT
LIT_RELOC_RUNS = [(0x008, 50), (0x128, 63), (0x228, 38), (0x454, 61), (0x760, 104),
                  (0x958, 40), (0xA28, 27), (0xA98, 177), (0xDE0, 61), (0xF78, 41)]
MODULE = 0x31DA8                     # .text start of the dispatcher's module
TABLE, NCMD = 0xDE0 // 4, 61


def english():
    lp = {c: math.log(0.004) for c in range(0x20, 0x7F)}
    for i, c in enumerate('etaoinshrdlucmfwypvbgkjqxz'):
        lp[ord(c)] = math.log(0.13 * 0.88 ** i)
    for c in b'%:.,=()-/0123456789':
        lp[c] = math.log(0.01)
    for c in b'ABCDEFGHIJKLMNOPQRSTUVWXYZ':
        lp[c] = math.log(0.006)
    lp[0x20], lp[0x0A], lp[0] = math.log(0.18), math.log(0.01), math.log(0.01)
    return lambda c: lp.get(c, -12.0)


def fit(W, key):
    rel = set(a // 4 + i for a, n in LIT_RELOC_RUNS for i in range(n))
    sw = [k for k in range(len(W)) if k not in rel and 32 <= W[k] >> 24 < 127]
    score = english()
    k7 = {}
    for cl in range(24):
        ws = [k for k in sw if k % 24 == cl]
        best = max(range(32), key=lambda lo5: sum(
            score((W[k] ^ ((lo5 << 2) | (key(k)[0] & 3))) & 0x7F) for k in ws))
        k7[cl] = best
    b7 = {}
    for k in sw:
        b7.setdefault(k % 48, (W[k] >> 7) & 1)
    low8 = lambda k: (k7[k % 24] << 2) | (key(k)[0] & 3) | (b7[k % 48] << 7)
    return sw, low8


def blocks():
    """Case-block starts of the dispatcher: words after a jmp/jmpi + delay slot."""
    T = u.words(os.path.join(ANT, 'text.bin'))
    B = {a - MODULE for a in range(0x31E20, 0x328CC, 4) if T[a // 4 - 2] >> 24 in (0xA0, 0xA1, 0xC0, 0xC1)}
    return sorted(B | {0xA70})


def main():
    W = u.words(os.path.join(ANT, 'lit.bin'))
    key = u.Key()
    sw, low8 = fit(W, key)
    ch = lambda c: chr(c) if 32 <= c < 127 else '_'
    print('%d string words; low key byte fitted for 24 + 48 classes' % len(sw))
    runs, cur = [], [sw[0]]
    for k in sw[1:]:
        if k - cur[-1] <= 2: cur.append(k)
        else: runs.append(cur); cur = [k]
    runs.append(cur)
    print('\nstrings (1st and 4th character of each word plain, "." = masked):')
    for r in runs:
        if len(r) >= 4:
            s = ''.join(ch(W[k] >> 24) + '..' + ch((W[k] ^ low8(k)) & 0xFF) for k in range(r[0], r[-1] + 1))
            print('  .lit $%04x  %s' % (4 * r[0], s))
    B = blocks()
    lows = {b & 0xFF for b in B}
    print('\ndispatcher table .lit $%04x (command -> case block, offset from $%05X):' % (4 * TABLE, MODULE))
    hit = 0
    for i in range(NCMD):
        k = TABLE + i
        est = (W[k] ^ (low8(k) | (key(k - 19)[0] & 0x3F00))) & 0x3FFF
        hit += (est & 0xFF) in lows
        c = sorted((b for b in B if b & 0xFF == est & 0xFF), key=lambda b: abs(b - est))
        print('  $%02X  est $%04x  -> %s' % (i, est, '  '.join(
            '$%05X%s' % (MODULE + b, '' if b == c[0] else '?') for b in c[:2]) or 'none'))
    print('low byte is a case-block low byte: %d of %d (chance about %.0f%%)'
          % (hit, NCMD, 100 * len(lows) / 64))


if __name__ == '__main__':
    main()
