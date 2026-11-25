#!/usr/bin/env python3
"""antelope_hif_stubs.py -- check Antelope's HIF stubs against AMD's library source.

AMD's HIF library (later part of newlib as libc/sys/a29khif, "Copyright 1990
Advanced Micro Devices"; e.g. newlib-1.8.2) has one assembly file per system
call, each 9 words:

    .word   (nargs+2) << 16           ; Debugger tag word
    const   tav,HIF_xxx               ; tav = gr121
    asneq   V_SYSCALL,gr1,gr1         ; V_SYSCALL = 69
    jmpti   tav,lr0                   ; success: return
    const   tpc,_errno                ; tpc = gr122 (relocated)
    consth  tpc,_errno
    store   0,0,tav,tpc               ; errno = error code
    jmpi    lr0
    constn  v0,-1                     ; v0 = gr96: return -1

This script builds those words for each stub and compares them in full with
the exact .text of an Antelope ACEF (antelope_dasm.Image).  The two
relocated words (_errno) are skipped.  The stub is identified by the low
byte of its HIF number.

Usage:  antelope_hif_stubs.py ACEF_100.bin START [START ...]   (START = tag word address, hex)
"""
import sys

HIF = {0x01: ('exit', 1), 0x11: ('open', 3), 0x12: ('close', 1), 0x13: ('read', 3),
       0x14: ('write', 3), 0x15: ('lseek', 3), 0x16: ('remove', 1), 0x21: ('tmpnam', 1)}
NAMES = ('tag word', 'const tav,N', 'asneq 69', 'jmpti tav,lr0', 'const tpc,_errno',
         'consth tpc,_errno', 'store tav', 'jmpi lr0', 'constn v0,-1')


def expect(n, nargs):
    return [(nargs + 2) << 16, 0x03007900 | n, 0x72450101, 0xCC007980, None, None,
            0x1E00797A, 0xC0000080, 0x01FF60FF]


def main(acef, starts):
    from antelope_dasm import Image
    U = Image(acef).words('.text')
    total = 0
    for b in starts:
        w = [U[b // 4 + i] for i in range(9)]
        n = w[1] & 0xFF
        name, nargs = HIF.get(n, ('?', 1))
        e = expect(n, nargs)
        bad = [NAMES[i] for i in range(9) if e[i] is not None and w[i] != e[i]]
        total += 1
        print('$%05X  %-7s HIF $%03X  %s' % (b + 4, name, ((w[1] >> 8) & 0xFF00) | n,
              'matches in full' if not bad else 'DIFFERS in ' + ', '.join(bad)))
    print('%d stubs' % total)


if __name__ == '__main__':
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    main(sys.argv[1], [int(x, 16) for x in sys.argv[2:]])
