#!/usr/bin/env python3
"""apply_reloc.py -- resolve the ACEF_100 COFF relocation table and annotate
the .text/Code disassembly with the resolved target of each relocation.

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

Usage:  python3 apply_reloc.py ACEF_100.bin disasm/text.asm disasm/Code.asm
Patches the .asm files in place, appending "; RELOC ..." comments to any
line with a relocation.  Original hex-byte columns are never touched, so
existing byte-exact verification against the binary still passes.
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

if __name__ == '__main__':
    acef_path = sys.argv[1] if len(sys.argv) > 1 else 'ACEF_100.bin'
    d, KEY, symptr, nsyms, secs = load(acef_path)
    sym, resolve, fmt_target = make_resolver(d, symptr, nsyms, secs)
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
