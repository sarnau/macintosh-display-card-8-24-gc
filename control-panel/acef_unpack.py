#!/usr/bin/env python3
"""acef_unpack.py -- unpack an ACEF resource (the 8*24 GC's Am29000 firmware).

The ACEF format is Am29000 COFF, lightly obfuscated.  Reverse-engineered from
the DRVR/gc24 loaders (ACEFLoad) in the 8*24 GC control-panel software:

  file header  (20 bytes, plaintext)
      +0  magic   (u16)   0x012A = plain COFF, 0x012B = obfuscated variant
      +2  nscns   (u16)
      +4  timdat  (u32)
      +7  KEY     (u8)    = the obfuscation key (also the low byte of timdat)
      +8  symptr  (u32)
      +12 nsyms   (u32)
      +16 opthdr  (u16)   (always 68 here)
      +18 flags   (u16)
  optional header (68 bytes @ 0x14)   XOR keystream  key(i)=(0x14 + KEY*i) & 0xFF
      program name ("32-Bit Antelope") at +0x1C, sizes, version, date
  [0x12B only] 64-byte copyright signature (plaintext) @ 0x58
  section headers (40 bytes each)     XOR keystream  key(i)=(offset + KEY*i)&0xFF
  section raw data (@ s_scnptr)       running 32-bit key, per word (0x12B only):
        K = KEY * 0x01010101,  b = s_scnptr & 0xFF       at the section start
        plain = word ^ K;  K = (K + b) mod 2^32;  b ^= K & 0xFF   per word
  relocations / symbols               plaintext

The section-data key is DRVR's ACEFLoad ($3A46-$3A64 sets K and b, $3AD0-
$3AE6 and $40FE-$4126 run it); it copies only size/4 words, so a section's
trailing 1-3 bytes never reach the card (they are written here XORed with
KEY only).  Versions of this script before November 2026 XORed every byte
with KEY alone, i.e. they used the starting K for every word; the
remainder is the "second mask" that SECOND_MASK.md and the *_key / unmask_*
tools model approximately.  gc24's own ACEFLoad accepts plain 0x12A files
only.

Usage:  python3 acef_unpack.py ACEF_100.bin  [outdir]
"""
import sys, struct, os

def decrypt(raw, KEY, scnptr):
    """Section data of a 0x12B file, as DRVR's ACEFLoad decodes it."""
    n = len(raw) // 4
    K, b = KEY * 0x01010101, scnptr & 0xFF
    out = bytearray(raw)
    for i in range(n):
        w = int.from_bytes(raw[4*i:4*i+4], 'big') ^ K
        out[4*i:4*i+4] = w.to_bytes(4, 'big')
        K = (K + b) & 0xFFFFFFFF
        b ^= K & 0xFF
    for i in range(4*n, len(raw)):         # not loaded by ACEFLoad
        out[i] = raw[i] ^ KEY
    return bytes(out)

def unpack(path, outdir):
    d = open(path, 'rb').read()
    magic, nscns, timdat = struct.unpack('>HHI', d[:8])
    KEY = d[7]
    symptr, nsyms, opthdr, flags = struct.unpack('>IIHH', d[8:20])
    if magic not in (0x12a, 0x12b):
        raise SystemExit(f'{path}: not ACEF (magic {magic:#x})')

    def lin(off, n, seed):                    # linear-keystream XOR (metadata)
        out = bytearray(n); k = seed & 0xff
        for i in range(n):
            out[i] = d[off+i] ^ k; k = (k+KEY) & 0xff
        return bytes(out)

    oh = lin(0x14, opthdr, 0x14)
    prog = oh[0x1c:0x1c+32].split(b'\x00')[0].decode('latin1','replace')
    ssz, dsz, bsz = struct.unpack('>III', oh[8:20])
    print(f'{os.path.basename(path)}: magic={magic:#x} key={KEY:#04x} nscns={nscns} '
          f'nsyms={nsyms} flags={flags:#x}')
    print(f'  program {prog!r}  text={ssz:#x} data={dsz:#x} bss={bsz:#x}')

    shoff = 0x98 if magic == 0x12b else 0x58   # copyright block adds 0x40 for 0x12B
    secs = []
    for i in range(nscns):
        h = lin(shoff + i*40, 40, shoff + i*40)
        name = h[:8].split(b'\x00')[0].decode('latin1','replace')
        paddr, vaddr, size, scnptr, relptr, lnno = struct.unpack('>IIIIII', h[8:32])
        nrel, nln = struct.unpack('>HH', h[32:36]); fl = struct.unpack('>I', h[36:40])[0]
        secs.append((name, vaddr, size, scnptr, relptr, nrel, fl))

    os.makedirs(outdir, exist_ok=True)
    print('  sec        vaddr      size      scnptr   nrel  flags   file')
    extracted = []
    for name, vaddr, size, scnptr, relptr, nrel, fl in secs:
        data = decrypt(d[scnptr:scnptr+size], KEY, scnptr) if (scnptr and size and fl & 0x80 == 0) else b''
        if data and magic == 0x12a:
            data = d[scnptr:scnptr+size]
        fn = ''
        if data:
            fn = os.path.join(outdir, (name.strip('.') or 'sec') + '.bin')
            open(fn, 'wb').write(data)
            extracted.append((vaddr, data))
        print(f'  {name:10} {vaddr:#010x} {size:#08x} {scnptr:#08x} {nrel:5d} {fl:#06x}  '
              f'{os.path.basename(fn) if fn else "(bss/none)"}')
    # ---- symbol table (6-byte records: scnum:s16, value:u32) -----------------
    # Names are stripped in this ACEF (no string table), but the section+address
    # of every symbol survives -> real function/label boundaries.
    if nsyms:
        secname = {i+1: secs[i][0] for i in range(len(secs))}
        lines = []
        for i in range(nsyms):
            scn, val = struct.unpack('>hI', d[symptr+i*6:symptr+i*6+6])
            if scn > 0:                       # skip debug/abs/undef markers (<=0)
                lines.append(f'{secname.get(scn,"?"+str(scn))}\t{val:#010x}')
        sp = os.path.join(outdir, 'symbols.txt')
        open(sp, 'w').write('\n'.join(lines) + '\n')
        print(f'  symbols: {len(lines)} section-relative addresses -> {os.path.basename(sp)} '
              f'(names stripped from file)')

    # flat load image only when the address span is sane (< 16 MB)
    if extracted:
        lo = min(v for v, _ in extracted); hi = max(v+len(x) for v, x in extracted)
        if 0 < hi-lo <= 0x1000000:
            image = bytearray(hi-lo)
            for v, x in extracted: image[v-lo:v-lo+len(x)] = x
            img = os.path.join(outdir, 'firmware_image.bin')
            open(img, 'wb').write(image)
            print(f'  -> {img}  ({len(image)} bytes, load base {lo:#x})')
        else:
            print(f'  (sections span {lo:#x}..{hi:#x}; kept as separate .bin files)')

if __name__ == '__main__':
    src = sys.argv[1] if len(sys.argv) > 1 else 'ACEF_100.bin'
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(os.path.basename(src))[0] + '_unpacked'
    unpack(src, out)
