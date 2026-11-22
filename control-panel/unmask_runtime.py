#!/usr/bin/env python3
"""Fully unmask the ACEF_1 'Runtime' code sections (Hand.bin, Boot.bin).

The low 23 bits of every 32-bit word (k = word index from the start of the
section) are XORed with a generator found by fitting `iret`/`mtsr` words:

    r   = 0x4000 + 0x80*(ROW[k % 48] - k) + COL[k % 24]
    key = signext19( ((-(r >> 16)) & 7) << 16 | ((r & 0xFFFF) ^ 0x4000) ) & 0x7FFFFF

(ROW is signed; COL has 24 entries.)  Usage:
    unmask_runtime.py Hand.bin OUT.bin          write the unmasked words
    unmask_runtime.py Hand.bin --sprs           print mfsr/mtsr/mtsrim SPRs
"""
import struct, sys
COL = [0x00,0x60,0x64,0x40,0x68,0x5c,0x70,0x50,0x04,0x10,0x38,0x5c,
       0x20,0x00,0x64,0x20,0x48,0x1c,0x10,0x70,0x04,0x30,0x58,0x1c]
ROW = [0, 4, 7, 7, 11, 12, 12, 0, 3, 6, 9, 9, -3, -2, -1, -1,
       3, 6, 6, 7, 10, -2, -1, -1, 3, 3, 7, 8, 8, 12, -1, -1,
       3, 3, 6, 7, 10, 11, -1, 2, 2, 6, 7, 8, 8, 11, 12, -1]

def key(k):
    r = 0x4000 + 0x80 * (ROW[k % 48] - k) + COL[k % 24]
    y = ((-(r >> 16) & 7) << 16) | ((r & 0xFFFF) ^ 0x4000)
    if y & 0x40000:
        y |= ~0x7FFFF
    return y & 0x7FFFFF

def unmask(words):
    return [x ^ key(k) for k, x in enumerate(words)]

if __name__ == '__main__':
    b = open(sys.argv[1], 'rb').read()
    w = struct.unpack('>%dI' % (len(b)//4), b[:len(b)//4*4])
    u = unmask(w)
    if sys.argv[2] == '--sprs':
        N = 'VAB OPS CPS CFG CHA CHD CHC RBP TMC TMR PC0 PC1 PC2 MMU LRU'.split()
        for k, x in enumerate(u):
            if x >> 24 in (0xC6, 0xCE, 0x04):
                ra = (x >> 8) & 0xFF
                print('%5d  %-6s %s' % (k, {0xC6:'mfsr',0xCE:'mtsr',0x04:'mtsrim'}[x >> 24],
                      N[ra] if ra < 15 else 'spr%d' % ra))
    else:
        open(sys.argv[2], 'wb').write(struct.pack('>%dI' % len(u), *u) + b[len(b)//4*4:])
        print('wrote', sys.argv[2], len(u), 'words')
