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

Bits 8-11 follow the same rule: bit b repeats every 24*2^(b-6) words (96,
192, 384, 768).  Bit 15 is plain in string words (ASCII bit 7 of the third
character).  For each bit and class, the value is chosen by two sources:

* the string words in the class: an English bigram score of the middle two
  characters (bigrams counted over this repository's own .md prose; the free
  higher bits are maximised over);
* the dispatcher entries in the class: whether the entry still matches a
  case-block start in bits 0..b.

Where both decide, they agree: bit 8 in 46 of 46 classes, bit 9 in 46 of
47 (printed).  Bits 10-11 come mostly from the table.  With them all 61
entries match a block start in bits 0-11, and every block offset is below
$1000, so bits 0-11 pick the block uniquely.

Usage:  antelope_lit_key.py [ACEF_100.bin]
        Without the ACEF file: the strings and the dispatcher table.  With it,
        every relocated .lit word is used (grouped by its relocation base, the
        symbol after the relocation's index), and all tables are decoded.
        Two groups are not case-block tables and are left out of the fit:
        base $06BAC (ColorMap's switch tables, mostly its default $0735C;
        pinned below instead) and base $30088 (offsets stepping by -$10:
        jumps into unrolled code).

        (takes a minute: the bits 8-11 search is brute force)
"""
import collections, math, os, sys
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


def main(acef=None):
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
    groups = {MODULE: list(range(TABLE, TABLE + NCMD))}
    cand = {MODULE: B}
    if acef:
        groups, cand = lit_tables(acef)
    # a group is used only if the string-derived bits 0-7 already fit it
    # (two groups are not case-block tables: see the docstring)
    use = {}
    for b, ks in groups.items():
        lows = {c & 0xFF for c in cand[b]}
        fit8 = sum(((W[k] ^ low8(k)) & 0xFF) in lows for k in ks)
        use[b] = fit8 >= 0.8 * len(ks)
    cons = {k: cand[b] for b, ks in groups.items() if use[b] for k in ks}
    if acef:
        # known plaintexts: DrawMultiObject's jump-table entries whose
        # targets the host's stream writer (gc24 EngineDispatch) settles
        for k, (b, t) in PINS.items():
            cons[k] = [t - b]
    fixed, check = fit_mid(W, key, sw, low8, cons)
    for bit, (a, d) in check.items():
        print('bit %d: table and strings both decided %d classes, disagree in %d' % (bit, a + d, d))
    print('\ndispatcher table .lit $%04x (command -> case block, bits 0-11 exact):' % (4 * TABLE))
    for i in range(NCMD):
        k = TABLE + i
        x = (W[k] ^ mid12(k, low8, fixed)) & 0xFFF
        c = [b for b in B if b & 0xFFF == x]
        print('  $%02X  -> %s' % (i, ' '.join('$%05X' % (MODULE + b) for b in c) or 'none'))
    if not acef:
        return
    print('\nall relocated .lit words, by relocation base (match = a case-block start in bits 0-n):')
    for b, ks in sorted(groups.items()):
        row = []
        for bit in (7, 9, 11):
            m = (1 << (bit + 1)) - 1
            hit = sum(any((c & m) == ((W[k] ^ mid12(k, low8, fixed)) & m) for c in cand[b]) for k in ks)
            chance = min(1.0, len({c & m for c in cand[b]}) / ((m + 1) / 4))
            row.append('0-%d: %d/%d (%.0f%%)' % (bit, hit, len(ks), 100 * chance))
        print('  base $%05X  .lit $%04x  %3d words  %s%s' % (b, 4 * ks[0], len(ks), '  '.join(row),
              '' if use[b] else '   [not a case-block table]'))
    print('\ndecoded tables (offset bits 0-11 -> matching case blocks):')
    for b, ks in sorted(groups.items()):
        if not use[b] or b == MODULE:
            continue
        print('  base $%05X:' % b)
        for k in ks:
            x = (W[k] ^ mid12(k, low8, fixed)) & 0xFFF
            c = [b + o for o in cand[b] if o & 0xFFF == x]
            print('    .lit $%04x  $%03x -> %s' % (4 * k, x, ' '.join('$%05X' % t for t in c[:3]) or '?'))


def lit_tables(acef):
    """Relocated .lit words grouped by relocation base, and each base's
    case-block candidates (offsets of words after an unconditional jump,
    inside the module that holds the base)."""
    import apply_reloc as ar
    d, _, sp, ns, secs = ar.load(acef)
    sym, _, _ = ar.make_resolver(d, sp, ns, secs)
    lit = [x for x in secs if x['name'] == '.lit'][0]
    groups = collections.defaultdict(list)
    for va, si, ty in sorted(ar.get_relocs(d, lit)):
        groups[sym(si + 1)[1]].append(va // 4)        # the symbol after the index
    mods = set()
    for ln in open(os.path.join(ANT, 'symbols.txt')):
        f = ln.split()
        if len(f) == 2 and f[0] == '.lit':
            mods.add(prev)
        if len(f) == 2 and f[0] == '.text':
            prev = int(f[1], 16)
    T = u.words(os.path.join(ANT, 'text.bin'))
    ends = sorted(mods | {4 * len(T)})
    cand = {}
    for b in groups:
        lo = max(x for x in ends if x <= b)
        hi = min(x for x in ends if x > b)
        cand[b] = sorted(a - b for a in range(lo + 8, hi, 4) if T[a // 4 - 2] >> 24 in (0xA0, 0xA1, 0xC0, 0xC1))
    cand[MODULE] = blocks()
    return dict(groups), cand

LEVELS = [(8, 96), (9, 192), (10, 384), (11, 768)]

# .lit word index -> (relocation base, true target).  DrawMultiObject's
# opcode 1 (the line, read by the $0BDB0 case), $6A (the clip region, which
# shares the $6C case at $0BBC4) and $72 (the "long" pattern record, the
# $0B72C case); the record layouts come from gc24's EngineDispatch, which
# writes them.  Without these, their key bits 8-11 classes fit wrongly.
#
# Every entry whose record layout the host confirms is pinned, not only the
# three that the unpinned fit got wrong: pinning only those moved shared
# key classes and broke opcodes 3 and $6E instead.
_DMO = {0x01: 0x0BDB0, 0x02: 0x0D9C4, 0x03: 0x0D9C4, 0x04: 0x0D9C4, 0x05: 0x0C754,
        0x6A: 0x0BBC4, 0x6B: 0x0B340, 0x73: 0x0B7D4,
        0x6C: 0x0BBC4, 0x6D: 0x0B584, 0x6E: 0x0BD98, 0x6F: 0x0B228,
        0x70: 0x0BB7C, 0x71: 0x0B6D8, 0x72: 0x0B72C, 0x74: 0x0B788,
        0x75: 0x0B7B8}
PINS = {(0x484 + 4 * (op - 1) if op < 0x6A else 0x498 + 4 * (op - 0x6A)) // 4:
        (0x0AD14, t) for op, t in _DMO.items()}

# ColorMap ($06F1C) replicates the fore/background pixel through a long with
# three switches on depth-1 (16 entries each).  Each enters an unrolled
# doubling chain (shift by 1, 2, 4, 8, 16) at the depth's step; every other
# depth goes to the switch's default.  A fourth switch, on mode & 3, sends
# srcXor (2) to the default.
def _depth_table(lit, chain, default):
    entry = {0: 0, 1: 16, 3: 32, 7: 48, 15: 64}
    return {lit // 4 + i: (0x06BAC, chain + entry[i] if i in entry else default)
            for i in range(16)}

PINS.update(_depth_table(0x128, 0x0710C, 0x0735C))
PINS.update(_depth_table(0x168, 0x071EC, 0x0735C))
PINS.update(_depth_table(0x1B8, 0x0754C, 0x0759C))
PINS[0x1A8 // 4 + 2] = (0x06BAC, 0x0735C)


def mid12(k, low8, fixed):
    return low8(k) | sum(fixed.get((b, k % P), 0) << b for b, P in LEVELS)


def fit_mid(W, key, sw, low8, cons):
    """Key bits 8-11 per class, from the strings and from table words.

    cons maps a relocated .lit word to its candidate plaintexts (case-block
    offsets from the word's relocation base)."""
    import glob
    here = os.path.dirname(os.path.abspath(__file__))
    txt = ''.join(open(f, errors='ignore').read() for f in
                  glob.glob(os.path.join(here, '*.md')) + glob.glob(os.path.join(here, '..', '*.md')))
    txt = ''.join(c for c in txt if 32 <= ord(c) < 127 or c == '\n')
    big, uni = collections.Counter(zip(txt, txt[1:])), collections.Counter(txt)
    ch = lambda c: chr(c) if c else '\n'
    lp = lambda a, b: math.log((big[(ch(a), ch(b))] + 0.1) / (uni[ch(a)] + 9.6))
    ok = lambda c: c in (0, 10) or 32 <= c < 127
    fixed, swset = {}, set(sw)
    tab = set(cons)

    def sscore(k):
        w, best = W[k], -99.0
        b0, b3 = w >> 24, (w ^ low8(k)) & 0xFF
        ms = [m for m in range(128) if all(((m >> (b - 8)) & 1) == fixed[(b, k % P)]
                                           for b, P in LEVELS if (b, k % P) in fixed)]
        for x in range(4):
            b1 = ((w >> 16) & 0xFF) ^ x
            if b1 & 0x80 or not ok(b1):
                continue
            for m in ms:
                b2 = ((w >> 8) & 0x7F) ^ m
                if ok(b2):
                    best = max(best, lp(b0, b1) + lp(b1, b2) + lp(b2, b3))
        return best

    weight = {}

    def tmatch(k, bit):
        # a match counts by how unlikely it is by chance: -ln(chance) for
        # this word's candidate set at this bit (a big module's many block
        # starts make a match weak evidence)
        m = (1 << (bit + 1)) - 1
        key_ = (id(cons[k]), bit)
        if key_ not in weight:
            ch = len({b & m for b in cons[k]}) / ((m + 1) / 4)
            weight[key_] = -math.log(min(max(ch, 0.02), 0.98))
        x = (W[k] ^ mid12(k, low8, fixed)) & m
        return weight[key_] if any((b & m) == x for b in cons[k]) else 0.0

    for bit, P in LEVELS:
        cls = collections.defaultdict(list)
        for k in list(sw) + list(tab):
            cls[k % P].append(k)
        for c, ks in cls.items():
            score = {}
            for v in (0, 1):
                fixed[(bit, c)] = v
                score[v] = sum(sscore(k) for k in ks if k in swset) + 4.0 * sum(tmatch(k, bit) for k in ks if k in tab)
            fixed[(bit, c)] = max(score, key=score.get)
    # check, with every other bit fixed: the strings alone against the table alone
    check = {}
    for bit, P in LEVELS:
        agree = dis = 0
        for c in sorted({k % P for k in tab}):
            ks = [k for k in sw if k % P == c]
            ks_t = [k for k in tab if k % P == c]
            if not ks:
                continue
            keep, st, tt = fixed[(bit, c)], {}, {}
            for v in (0, 1):
                fixed[(bit, c)] = v
                st[v] = sum(sscore(k) for k in ks)
                tt[v] = sum(tmatch(k, bit) for k in ks_t)
            fixed[(bit, c)] = keep
            if abs(st[0] - st[1]) >= 1.0 and tt[0] != tt[1]:
                if max(st, key=st.get) == max(tt, key=tt.get): agree += 1
                else: dis += 1
        check[bit] = (agree, dis)
    return fixed, check


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else None)
