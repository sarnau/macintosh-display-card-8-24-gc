#!/usr/bin/env python3
"""antelope_data_dump.py -- labelled listing of Antelope's decoded .data.

Reads data.partial.bin and its .flag sidecar (antelope_data_key.py) and
prints every word with:
  * labels: the object file whose .data starts there (antelope_modules.py)
    and the .data symbols of the table (symbols.txt; obj_XXXX);
  * the decoded value, its flag (z/r sample, = neighbours agree, ~ less
    sure in bits 13-23) and ASCII;
  * for relocated words: the target (the file's .text or .data1 start plus
    the decoded offset) and the function name from antelope_partial_dasm.

Usage:  antelope_data_dump.py ACEF_100.bin > firmware/disasm/data.partial.asm
"""
import bisect, os, struct, sys
import apply_reloc as a
import antelope_modules as am
from antelope_partial_dasm import NAMES
import unmask_antelope_low as u


def main(acef):
    B = open(os.path.join(u.ANT, 'data.partial.bin'), 'rb').read()
    F = open(os.path.join(u.ANT, 'data.partial.bin.flag')).read()
    W = struct.unpack('>%dI' % (len(B) // 4), B)
    d, _, sp, ns, secs = a.load(acef)
    S = lambda i: struct.unpack('>hI', d[sp + 6 * i:sp + 6 * i + 6])
    h = am.header(d)
    fs, _, _ = am.files(d, h['symptr'], h['nsyms'])
    own, _ = am.split_globals(fs[-1])
    rows = [am.classify(f['syms']) for f in fs[:-1]] + [am.classify(own)]
    filestart = {}
    for n, r in enumerate(rows):
        if 4 in r['secs']:
            filestart.setdefault(r['secs'][4], []).append(n)
    syms = sorted({int(l.split()[1], 16) for l in open(os.path.join(u.ANT, 'symbols.txt')) if l.startswith('.data')})
    funcs = sorted({int(l.split()[1], 16) for l in open(os.path.join(u.ANT, 'symbols.txt')) if l.startswith('.text')})
    sec = [x for x in secs if x['name'] == '.data'][0]
    rel = {}
    for i in range(sec['nrel']):
        va, si, ty = struct.unpack('>IHH', d[sec['relptr'] + 8 * i:sec['relptr'] + 8 * i + 8])
        rel[va] = S(si + 1) if S(si)[0] == -3 else S(si)
    print('* ' + '=' * 66)
    print('*  ACEF_100 "32-Bit Antelope" -- .data, decoded (antelope_data_key.py)')
    print('* ' + '=' * 66)
    print('*  flag: z = sample (decodes to 0; may be a value with bits 0-12 zero),')
    print('*  r = relocated word, k = known table entry, x = from System 6,')
    print('*  = both neighbouring samples agree on key bits 13-23, ~ they differ')
    print('*  (bits 13-23 may be off by a step).  Bits 0-12 are the J13 model.')
    print('*  Relocated words show their target: the file\'s .text start + value.')
    print('*')
    for x in range(0, 4 * len(W), 4):
        if x in filestart:
            print('\n; ---- object file %s: .data starts here' % ', '.join(map(str, filestart[x])))
        if x in syms:
            print('obj_%04x:' % x)
        w = W[x // 4]
        asc = ''.join(chr(c) if 32 <= c < 127 else '.' for c in w.to_bytes(4, 'big'))
        note = ''
        if x in rel:
            sc, base = rel[x]
            if sc == 2:
                t = base + (w & 0xFFFFFF)
                fn = funcs[bisect.bisect_right(funcs, t) - 1] if funcs else 0
                note = '  ; -> .text $%05X%s' % (t, (' (%s)' % NAMES[t]) if t in NAMES else
                                                (' (sub_%05x+$%x)' % (fn, t - fn) if t != fn else ' (sub_%05x)' % fn))
            else:
                note = '  ; -> .data1+$%X' % (base + (w & 0xFFFFFF))
        print('  %04x:  %08x %s  %s%s' % (x, w, F[x // 4], asc, note))


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
