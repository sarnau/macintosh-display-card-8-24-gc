#!/usr/bin/env python3
"""apply_reloc.py -- resolve the ACEF_100 COFF relocation table and annotate
the .text/Code disassembly, and dump the .lit/.data sections, with the
resolved target of each relocation.

Format (reverse-engineered; see firmware/README.md "COFF relocations"):
  8-byte PLAINTEXT records (unobfuscated, unlike headers/section data):
      [vaddr:u32][symndx:u16][type:u16]     (big-endian, vaddr section-relative)
  Symbol table (already decoded by acef_unpack.py): 6-byte records
      [scnum:s16][value:u32], scnum 1-based into the section-header list;
      scnum 0/-2/-3 = external to this ACEF image (unresolvable here),
      scnum -1 = N_ABS (value is already an absolute constant).

  type 26 = 'const'  (low 16 of a const/consth pair)
  type 27 = 'consth' (high 16 of the pair)
  type 28 = null companion of type 27 (symndx always 0) -- no independent
            info, just marks the pair as a matched unit
  type 24 = 'call'  absolute target fixup (single instruction)
  type 29 = raw 32-bit WORD fixup -- hits both code words used as literals
            and genuine embedded data words (corroborates the gr0-write
            "embedded data table" finding in am29k_dasm.py)
  type 31 = raw 32-bit WORD fixup, seen only in .lit/.data -- same idea as
            29 but apparently reserved for pure-data sections

Usage:  python3 apply_reloc.py ACEF_100.bin disasm/text.asm disasm/Code.asm \
            disasm/lit.asm disasm/data.asm
Patches text.asm/Code.asm in place (appends "; RELOC ..." comments; hex-byte
columns are never touched, so byte-exact verification still passes) and
(re)generates lit.asm/data.asm from scratch as plain word dumps annotated
the same way, since .lit/.data are literal pools / initialised data, not
Am29000 code.
"""
import struct, re, sys, os

def load(path):
    d = open(path, 'rb').read()
    magic, nscns, timdat = struct.unpack('>HHI', d[:8])
    KEY = d[7]
    symptr, nsyms, opthdr, flags = struct.unpack('>IIHH', d[8:20])

    def lin(off, n, seed):
        out = bytearray(n); k = seed & 0xff
        for i in range(n):
            out[i] = d[off+i] ^ k; k = (k+KEY) & 0xff
        return bytes(out)

    shoff = 0x98 if magic == 0x12b else 0x58
    secs = []
    for i in range(nscns):
        h = lin(shoff + i*40, 40, shoff + i*40)
        name = h[:8].split(b'\x00')[0].decode('latin1', 'replace').strip()
        paddr, vaddr, size, scnptr, relptr, lnno = struct.unpack('>IIIIII', h[8:32])
        nrel, nln = struct.unpack('>HH', h[32:36]); fl = struct.unpack('>I', h[36:40])[0]
        secs.append(dict(name=name, vaddr=vaddr, size=size, scnptr=scnptr,
                          relptr=relptr, nrel=nrel, flags=fl))
    return d, KEY, symptr, nsyms, secs

def make_resolver(d, symptr, nsyms, secs):
    def sym(symndx):
        if symndx >= nsyms: return None
        return struct.unpack('>hI', d[symptr+symndx*6:symptr+symndx*6+6])  # (scnum, value)

    def resolve(symndx):
        r = sym(symndx)
        if r is None: return None
        scn, val = r
        if scn == -1: return val                                # N_ABS
        if 1 <= scn <= len(secs): return secs[scn-1]['vaddr'] + val
        return None                                              # external/debug

    def section_of(addr):
        for s in secs:
            if s['size'] and s['vaddr'] <= addr < s['vaddr'] + s['size']:
                return s
        return None

    def fmt_target(v):
        s = section_of(v)
        if s:
            off = v - s['vaddr']
            return f'${v:08x} ({s["name"]}+{off:#x})' if off else f'${v:08x} ({s["name"]})'
        return f'${v:08x}'

    return sym, resolve, fmt_target

def get_relocs(d, sec):
    raw = d[sec['relptr']:sec['relptr']+sec['nrel']*8]
    return [struct.unpack('>IHH', raw[i*8:i*8+8]) for i in range(sec['nrel'])]

def build_line_annotations(d, sec, sym, resolve, fmt_target):
    """4-byte-aligned line address -> list of RELOC comment strings, plus stats."""
    line_ann = {}
    stats = dict(resolved=0, unresolved=0, total=0)
    for va, symndx, rtype in get_relocs(d, sec):
        if rtype == 28:
            continue  # companion; carries no independent info
        stats['total'] += 1
        r = resolve(symndx)
        base = va & ~3
        if r is None:
            s = sym(symndx)
            scn_txt = f'symndx {symndx} scn={s[0]}' if s else f'symndx {symndx} (out of range)'
            text = f'RELOC: unresolved external ({scn_txt}) -- not defined in this ACEF image'
            stats['unresolved'] += 1
        else:
            stats['resolved'] += 1
            kind = {26: 'lo16', 27: 'hi16', 24: 'call target', 29: 'word'}.get(rtype, f'type {rtype}')
            text = f'RELOC({kind}): -> {fmt_target(r)}'
        if va != base:
            text += f' [byte +{va-base} of word]'
        line_ann.setdefault(base, []).append(text)
    return line_ann, stats

def load_section_symbols(symbols_path, secname):
    """symbols.txt lines are '<section>\\t<0xaddr>'; return sorted unique addrs."""
    if not symbols_path or not os.path.exists(symbols_path):
        return []
    want = secname.lstrip('.').lower()
    addrs = set()
    for ln in open(symbols_path):
        p = ln.split()
        if len(p) == 2 and p[0].lstrip('.').lower() == want:
            addrs.add(int(p[1], 16))
    return sorted(addrs)

def ascii_hint(word_bytes):
    return ''.join(chr(c) if 0x20 <= c < 0x7f else '.' for c in word_bytes)

def dump_data_section(d, KEY, sec, sym, resolve, fmt_target, obj_addrs, header_lines):
    data = bytes(c ^ KEY for c in d[sec['scnptr']:sec['scnptr']+sec['size']])
    line_ann, stats = build_line_annotations(d, sec, sym, resolve, fmt_target)
    obj_set = set(obj_addrs)
    out = [f'* ' + '=' * 66,
           f"*  ACEF_100 \"32-Bit Antelope\" -- {sec['name']}  "
           f"({sec['size']} bytes, {stats['resolved']}/{stats['total']} "
           f"relocations resolved)",
           '* ' + '=' * 66]
    out += ['* ' + l if l else '*' for l in header_lines]
    out.append('*')
    n = sec['size'] // 4
    for i in range(n):
        a = i * 4
        if a in obj_set:
            out.append(f'obj_{a:05x}:')
        w = data[a:a+4]
        val = struct.unpack('>I', w)[0]
        line = f'  {a:05x}:  {val:08x}  .long    ${val:08x}             |{ascii_hint(w)}|'
        if a in line_ann:
            line += '  ; ' + ' | '.join(line_ann[a])
        out.append(line)
    return '\n'.join(out) + '\n', stats

def patch_file(path, line_ann):
    lines = open(path).read().splitlines()
    addr_re = re.compile(r'^  ([0-9a-f]{5}):')
    patched = 0
    out = []
    for ln in lines:
        m = addr_re.match(ln)
        if m:
            addr = int(m.group(1), 16)
            if addr in line_ann:
                ln = ln.rstrip() + '  ; ' + ' | '.join(line_ann[addr])
                patched += 1
        out.append(ln)
    open(path, 'w').write('\n'.join(out) + '\n')
    return patched

DATA_HEADER = [
    "Not Am29000 code -- a plain word dump of the section's raw content.",
    "`obj_XXXXX:` labels come from the ACEF symbol table (symbols.txt) at",
    "this section's object boundaries; RELOC lines are decoded the same",
    "way as text.asm/Code.asm (see apply_reloc.py / firmware/README.md).",
    "The trailing |....| column is the 4 bytes read as ASCII (unprintable",
    "bytes shown as '.') -- several entries are plainly literal strings,",
    "not addresses, confirming '.lit' holds a mix of numeric and string",
    "constants, not just floats.",
]

if __name__ == '__main__':
    acef_path = sys.argv[1] if len(sys.argv) > 1 else 'ACEF_100.bin'
    d, KEY, symptr, nsyms, secs = load(acef_path)
    sym, resolve, fmt_target = make_resolver(d, symptr, nsyms, secs)
    symbols_path = sys.argv[6] if len(sys.argv) > 6 else None

    targets = {
        '.text': (next(s for s in secs if s['name'] == '.text'), sys.argv[2] if len(sys.argv) > 2 else None),
        'Code': (next(s for s in secs if s['name'] == 'Code'), sys.argv[3] if len(sys.argv) > 3 else None),
    }
    for label, (sec, path) in targets.items():
        line_ann, stats = build_line_annotations(d, sec, sym, resolve, fmt_target)
        msg = (f"{label}: {stats['total']} symbol-bearing relocations, "
               f"{stats['resolved']} resolved ({100*stats['resolved']/stats['total']:.1f}%), "
               f"{stats['unresolved']} unresolved")
        if path and os.path.exists(path):
            patched = patch_file(path, line_ann)
            msg += f' -- {patched} lines annotated in {path}'
        print(msg)

    data_targets = {
        '.lit': (next(s for s in secs if s['name'] == '.lit'), sys.argv[4] if len(sys.argv) > 4 else None),
        '.data': (next(s for s in secs if s['name'] == '.data'), sys.argv[5] if len(sys.argv) > 5 else None),
    }
    for label, (sec, path) in data_targets.items():
        obj_addrs = load_section_symbols(symbols_path, label)
        text, stats = dump_data_section(d, KEY, sec, sym, resolve, fmt_target, obj_addrs, DATA_HEADER)
        msg = (f"{label}: {stats['total']} symbol-bearing relocations, "
               f"{stats['resolved']} resolved ({100*stats['resolved']/stats['total']:.1f}%), "
               f"{stats['unresolved']} unresolved")
        if path:
            open(path, 'w').write(text)
            msg += f' -- wrote {path}'
        print(msg)
