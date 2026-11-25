#!/usr/bin/env python3
"""antelope_modules.py -- the object files an Antelope ACEF was linked from.

The ACEF symbol table (6-byte records [scnum:s16][value:u32], no names) keeps
the COFF layout of the linker's output:

  * one .file symbol per object file (scnum -2); its value is the index of
    the next .file symbol, so the chain checks itself
  * scnum -3 is a placeholder: the converter wrote a symbol that had an aux
    entry into the aux slot, so the record after a -3 is the symbol (symbol
    indices stay those of the original COFF file, which the relocations use)
  * per file: its symbols, and the section symbols .text/.data/.bss/(.lit)
    with the file's start in each section
  * after the last file, the global symbols that carry no aux entry

Three kinds of file show up, by how their symbols look:

  C-g   every function has an aux entry (function size and debug links;
        line numbers were stripped), symbols in address order, and the file
        ends with .text .data .bss .lit, .lit always present (also empty)
  C     no function aux entries; the file ends with .text .data .bss, .lit
        and .data1 only where used (the C library)
  asm   one .text section symbol, labels without aux entries in no address
        order (hash order), no .data/.bss (the HIF stubs, millicode, crt0)

A file's .text section symbol lies 4 bytes before its first function in C
and most assembly files: the AMD calling convention's tag word (opcode byte
0, never executed) precedes each function.  These section symbols are in
symbols.txt as .text entries too, so they are not function entries.

Usage:  antelope_modules.py ACEF_100.bin [ACEF_100.bin ...]
"""
import collections, datetime, struct, sys

SEC = {1: 'Code', 2: '.text', 3: '.lit', 4: '.data', 5: 'Apple', 6: '.data1', 7: '.bss'}


def header(d):
    key = d[7]
    magic, nscns, timdat, symptr, nsyms, opthdr, flags = struct.unpack('>HHIIIHH', d[:20])
    oh, k = bytearray(opthdr), 0x14
    for i in range(opthdr):
        oh[i] = d[0x14 + i] ^ k; k = (k + key) & 0xFF
    w = struct.unpack('>7I', oh[:28])
    name = oh[0x1C:0x3C].split(b'\0')[0].decode('latin1')
    mac = lambda t: datetime.datetime(1904, 1, 1) + datetime.timedelta(seconds=t)
    return dict(name=name, version=w[5], built=mac(w[6]), packed=mac(timdat), flags=flags,
                sizes=w[2:5], entry=w[0], symptr=symptr, nsyms=nsyms)


def files(d, symptr, nsyms):
    S = [struct.unpack('>hI', d[symptr + 6 * i:symptr + 6 * i + 6]) for i in range(nsyms)]
    out, i, chain_ok = [], 0, True
    while i < nsyms:
        s, v = S[i]
        aux = s == -3
        if aux:
            i += 1
            s, v = S[i]
        if s == -2:
            if out and out[-1]['next'] + 1 != i:
                chain_ok = False
            out.append(dict(index=i, next=v, syms=[]))
        elif out:
            out[-1]['syms'].append((s, v, aux))
        i += 1
    return out, chain_ok, S


def split_globals(f):
    """The last file's own symbols end with its section symbols; what follows
    is the table of global symbols without aux entries."""
    sy = f['syms']
    j = max(i for i, (s, v, a) in enumerate(sy) if a and s in (2, 3, 4, 6, 7))
    return sy[:j + 1], sy[j + 1:]


def classify(sy):
    taux = [v for s, v, a in sy if s == 2 and a]
    tplain = [v for s, v, a in sy if s == 2 and not a]
    secs = {}
    for s, v, a in sy:
        if a and s in (3, 4, 6, 7):
            secs[s] = v
    start = min(taux) if taux else None
    if sy and sy[0][0] == 1:
        kind = 'asm'
    elif not sy:
        kind = '-'
    elif len(taux) > 1:
        kind = 'C-g'
    elif 4 in secs or 7 in secs:
        kind = 'C'
    else:
        kind = 'asm'
    funcs = set(v for v in taux + tplain if v != start)
    return dict(kind=kind, start=start, funcs=funcs, secs=secs,
                other=collections.Counter(SEC.get(s, s) for s, v, a in sy if s != 2))


def main(paths):
    for p in paths:
        d = open(p, 'rb').read()
        h = header(d)
        fs, ok, S = files(d, h['symptr'], h['nsyms'])
        print('%s: program %r version $%08X, built %s, packed %s (Mac time); file flags $%04X' % (
            p, h['name'], h['version'], h['built'], h['packed'], h['flags']))
        print('  %d object files (.file chain %s)' % (len(fs), 'consistent' if ok else 'BROKEN'))
        own, glob = split_globals(fs[-1])
        rows = [classify(f['syms']) for f in fs[:-1]] + [classify(own)]
        ends = []
        for n, r in enumerate(rows):
            nxt = next((q['start'] for q in rows[n + 1:] if q['start'] is not None), h['sizes'][0])
            ends.append(nxt)
        gt = [v for s, v, a in glob if s == 2]
        for v in gt:              # global functions back to their files
            for r, e in zip(rows, ends):
                if r['start'] is not None and r['start'] <= v < e:
                    r['funcs'].add(v)
                    break
        allt = {v for s, v in S if s == 2}
        starts = {r['start'] for r in rows if r['start'] is not None}
        nfun = allt - (starts - {f for r in rows for f in r['funcs']})
        print('  trailing globals: %s' % ', '.join('%d %s' % (c, SEC.get(k, {0: 'undefined', -1: 'absolute'}.get(k, k)))
                                                  for k, c in sorted(collections.Counter(s for s, v, a in glob).items())))
        print('  .text symbols: %d distinct addresses = %d functions + %d file starts (tag words)' % (
            len(allt), len(nfun), len(allt) - len(nfun)))
        print('   #  kind  .text start  size    funcs  .data   .bss   .lit   other symbols')
        for n, (r, e) in enumerate(zip(rows, ends)):
            st = r['start']
            g = lambda s: '$%04X' % r['secs'][s] if s in r['secs'] else '-'
            other = ' '.join('%s %d' % kv for kv in sorted(r['other'].items())
                             if kv[0] not in ('.data', '.bss', '.lit') or kv[1] > 1)
            print('  %2d  %-4s  %-11s %6s  %5d  %-6s %-6s %-6s %s' % (
                n, r['kind'], '$%05X' % st if st is not None else '-', e - st if st is not None else '',
                len(r['funcs']), g(4), g(7), g(3), other))
        print()


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1:])
