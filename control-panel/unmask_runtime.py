#!/usr/bin/env python3
"""Partially unmask the ACEF_1 'Runtime' code sections (Hand.bin, Boot.bin).

Findings (see firmware/README.md): the low 24 bits of every 32-bit word are
XORed with a key  key(k) = 0x80*m(k) + COL[k % 24],  k = word index.
Bits 0-14 of the key are known for 38 of 48 phases of k % 48:
    bits 0-6  = COL[k % 24]                 (24 constants)
    bits 7-14 = (ROW[k % 48] - k) & 0xFF    (38 of 48 constants known)
Bits 15-23 of the key (jumps of 0x8000/0x18000) are NOT understood, so those
bits of every word stay masked.  Output: <name>.low15.bin (words with bits
0-14 unmasked where known) and <name>.known.bin (mask of the bits that are
valid).  Usage:  unmask_runtime.py Hand.bin OUTDIR"""
import struct, sys, os
COL = [0x00,0x60,0x64,0x40,0x68,0x5c,0x70,0x50,0x04,0x10,0x38,0x5c,
       0x20,0x00,0x64,0x20,0x48,0x1c,0x10,0x70,0x04,0x30,0x58,0x1c]
ROW = {0:0,1:4,3:7,5:12,6:12,7:0,8:3,9:6,10:9,11:9,12:253,13:254,14:255,15:255,
       16:3,19:7,20:10,21:254,23:255,24:3,25:3,26:7,27:8,28:8,29:12,30:255,
       31:255,32:3,33:3,35:7,36:10,39:2,41:6,42:7,44:8,45:11,46:12,47:255}
src, out = sys.argv[1], sys.argv[2]
b = open(src, 'rb').read()
w = struct.unpack('>%dI' % (len(b)//4), b[:len(b)//4*4])
dec, known = [], []
for k, x in enumerate(w):
    p = k % 48
    if p in ROW:
        key = ((((ROW[p] - k) & 0xFF) << 7) | COL[k % 24]) & 0x7FFF
        dec.append((x & ~0x7FFF) | ((x ^ key) & 0x7FFF)); known.append(0x7FFF)
    else:
        key = COL[k % 24]
        dec.append((x & ~0x7F) | ((x ^ key) & 0x7F)); known.append(0x7F)
os.makedirs(out, exist_ok=True)
n = os.path.basename(src)[:-4]
open(os.path.join(out, n + '.low15.bin'), 'wb').write(struct.pack('>%dI' % len(dec), *dec))
open(os.path.join(out, n + '.known.bin'), 'wb').write(struct.pack('>%dI' % len(known), *known))
print(n, len(w), 'words;', sum(1 for k in range(len(w)) if k % 48 in ROW), 'with bits 0-14 known')
