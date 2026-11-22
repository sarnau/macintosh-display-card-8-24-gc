#!/usr/bin/env python3
"""Unmask the ACEF_1 'Runtime' code sections (Hand.bin exactly, Boot.bin fitted).

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

# Boot.bin uses the same generator with its own tables.  These were fitted
# (maximum likelihood against field statistics of the unmasked Hand, plus
# hard constraints: same-register const/consth pairs, jump targets inside the
# code, valid SPR numbers, mfsr RB = 0, mtsr RC = 0); a few entries may be off.
COL_BOOT = [0, 76, 8, 24, 68, 24, 16, 108, 120, 72, 4, 8,
            64, 12, 8, 88, 4, 24, 80, 44, 120, 8, 68, 8]
ROW_BOOT = [0, 4, 7, 10, 10, -2, -1, 0, 2, 2, 9, 8, 8, 0, 1, 0,
            0, 3, 4, 7, 8, 9, 10, 1, 0, 4, 7, 10, 10, -2, -1, 0,
            0, 4, 7, 10, 10, -2, -1, 0, 0, 3, 4, 7, 10, 9, 10, 1]
TABLES = {'Hand': (COL, ROW), 'Boot': (COL_BOOT, ROW_BOOT)}

def key(k, tables='Hand'):
    COL, ROW = TABLES[tables]
    r = 0x4000 + 0x80 * (ROW[k % 48] - k) + COL[k % 24]
    y = ((-(r >> 16) & 7) << 16) | ((r & 0xFFFF) ^ 0x4000)
    if y & 0x40000:
        y |= ~0x7FFFF
    return y & 0x7FFFFF

def unmask(words, tables='Hand'):
    return [x ^ key(k, tables) for k, x in enumerate(words)]

if __name__ == '__main__':
    b = open(sys.argv[1], 'rb').read()
    w = struct.unpack('>%dI' % (len(b)//4), b[:len(b)//4*4])
    import os
    name = os.path.basename(sys.argv[1])
    u = unmask(w, 'Boot' if name.startswith('Boot') else 'Hand')
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
