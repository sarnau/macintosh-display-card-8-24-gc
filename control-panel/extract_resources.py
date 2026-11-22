#!/usr/bin/env python3
"""extract_resources.py -- dump resources from a Mac resource-fork file.

Reproduces the inputs of this project's pipeline from the original
`Macintosh Control Panel/824GC.rsrc`:
    ACEF  100  -> ACEF_100.bin   (the 'Antelope' firmware, feed to acef_unpack.py)
    ACEF    1  -> ACEF_1.bin     (the 'Runtime' kernel)
    DRVR -4048 -> DRVR_-4048.bin (.GraphAccel, the 68k byte image DRVR.s lists)
    ...and every other resource if asked.

Usage:  python3 extract_resources.py FILE.rsrc OUTDIR [TYPE ...]
        (no TYPE = list everything and extract only ACEF/DRVR/INIT/CDEV/PACK)
"""
import struct, sys, os

def resources(path):
    d = open(path, 'rb').read()
    do, mo, dl, ml = struct.unpack('>IIII', d[:16])
    m = d[mo:mo + ml]
    tlo = struct.unpack('>H', m[24:26])[0]
    n = struct.unpack('>H', m[tlo:tlo + 2])[0] + 1
    for i in range(n):
        t, cnt, ro = struct.unpack('>4sHH', m[tlo + 2 + i * 8:tlo + 10 + i * 8])
        for j in range(cnt + 1):
            e = m[tlo + ro + j * 12: tlo + ro + j * 12 + 12]
            rid, no = struct.unpack('>hH', e[:4])
            off = int.from_bytes(e[5:8], 'big')
            L = struct.unpack('>I', d[do + off:do + off + 4])[0]
            name = ''
            if no != 0xFFFF:
                nl = m[struct.unpack('>H', m[26:28])[0] + no]
                name = m[struct.unpack('>H', m[26:28])[0] + no + 1:][:nl].decode('latin1')
            yield t.decode('latin1'), rid, name, d[do + off + 4: do + off + 4 + L]

if __name__ == '__main__':
    src, out = sys.argv[1], sys.argv[2]
    want = set(sys.argv[3:]) or {'ACEF', 'DRVR', 'INIT', 'cdev', 'PACK'}
    os.makedirs(out, exist_ok=True)
    for t, rid, name, data in resources(src):
        mark = ''
        if t in want:
            fn = os.path.join(out, f'{t}_{rid}.bin')
            open(fn, 'wb').write(data)
            mark = '  -> ' + fn
        print(f'{t:5} {rid:6}  {len(data):7}  {name}{mark}')
