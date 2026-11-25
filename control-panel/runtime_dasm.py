#!/usr/bin/env python3
"""runtime_dasm.py -- exact disassembly and data listing of a Runtime ACEF.

The Runtime ACEF (ACEF_1, the kernel the driver loads first) has no symbols
and no relocations; its sections sit at fixed card addresses.  Its data is
decrypted as DRVR's ACEFLoad does it (acef_unpack.decrypt).  Written to
OUTDIR:

  Hand.asm, Boot.asm   am29k_dasm.py listings with jump labels (skip Hand
                       with --no-hand, e.g. to keep an annotated listing)
  RuntimeData.asm      the data sections: PrivNZ (the vector-66 service
                       table, services $B6-$D6, with their handlers), Vec,
                       PublicIn, PublicOu, Apple, VidComm, as words + ASCII

Usage:  runtime_dasm.py ACEF_1.bin OUTDIR [--no-hand]
"""
import os, struct, sys
import acef_unpack, apply_reloc as ar
from am29k_dasm import disasm


def main(path, outdir, hand=True):
    d, key, sp, ns, secs = ar.load(path)
    get = lambda s: acef_unpack.decrypt(d[s['scnptr']:s['scnptr'] + s['size']], key, s['scnptr'])
    sec = {s['name']: s for s in secs}
    os.makedirs(outdir, exist_ok=True)
    for name in ('Hand', 'Boot') if hand else ('Boot',):
        s = sec[name]
        head = ['* ' + '=' * 66,
                '*  ACEF_1 "Runtime" -- %s (Am29000, base $%07X), exact' % (name, s['vaddr']),
                '* ' + '=' * 66,
                '*  Made by runtime_dasm.py: decrypted as DRVR\'s ACEFLoad does it,',
                '*  disassembled by am29k_dasm.py.  L_XXXXXXX = a jump target.',
                '* ' + '=' * 66]
        open(os.path.join(outdir, name + '.asm'), 'w').write(
            '\n'.join(head) + '\n' + disasm(get(s), s['vaddr'], True) + '\n')
    out = ['* ' + '=' * 66, '*  ACEF_1 "Runtime" -- data sections, exact (runtime_dasm.py)', '* ' + '=' * 66]
    hand_end = sec['Hand']['vaddr'] + sec['Hand']['size']
    for name in ('PrivNZ', 'Vec', 'PublicIn', 'PublicOu', 'Apple', 'VidComm'):
        s = sec[name]
        b = get(s)
        out.append('')
        out.append('%s:   ; $%08X, %d bytes' % (name, s['vaddr'], s['size']))
        for i in range(0, len(b) // 4 * 4, 4):
            w = struct.unpack('>I', b[i:i + 4])[0]
            if name == 'Vec' and w == 0:
                continue
            asc = ''.join(chr(c) if 32 <= c < 127 else '.' for c in b[i:i + 4])
            note = ''
            if name == 'PrivNZ':
                note = '  ; service $%02X -> $%08X%s' % (0xB6 + i // 4, w,
                        '' if sec['Hand']['vaddr'] <= w < hand_end else ' (outside Hand)')
            out.append('  %08x:  %08x  |%s|%s' % (s['vaddr'] + i, w, asc, note))
        for i in range(len(b) // 4 * 4, len(b)):
            out.append('  %08x:  %02x        (trailing byte, not loaded)' % (s['vaddr'] + i, b[i]))
        if name == 'Vec':
            out.append('  (all other words are 0; Boot fills the vector table at run time)')
    open(os.path.join(outdir, 'RuntimeData.asm'), 'w').write('\n'.join(out) + '\n')
    print('%s -> %s' % (path, outdir))


if __name__ == '__main__':
    a = [x for x in sys.argv[1:] if x != '--no-hand']
    if len(a) != 2:
        sys.exit(__doc__)
    main(a[0], a[1], '--no-hand' not in sys.argv)
