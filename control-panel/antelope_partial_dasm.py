#!/usr/bin/env python3
"""antelope_partial_dasm.py -- partial disassembly of Antelope's .text.

Uses unmask_antelope_low.py for the low key bits it knows (bits 0-14 of every
word, bit 15 for ~96%, bits 16-17 for some).  Fields that are still masked
print as '?':

    RB / I8 (bits 0-7)    always plain
    RA      (bits 8-15)   plain when 16 bits are known, else '?rN' = gr/lr N
    RC      (bits 16-23)  '?' (masked), except in fully known sample words
    I16 high byte         '??' (it lives in the RC field)
    jump / call targets   unknown (their displacement's high byte is in RC);
                          shown as '?' with the known low displacement byte

Words whose whole plaintext is known (the samples in mask_samples.tsv: nop,
jmpi lr0, the spill/fill asserts, sub/add gr1/lr1 frame words, and the
relocated const/consth words) are decoded in full.  Function labels come from
the ACEF symbol table (symbols.txt, 768 .text entries), which is not masked.

Given the ACEF file, each direct call with an R_IREL relocation (type 24,
133 of them) gets its target, and each relocated const/consth its target as a
comment ('-> .text $15808', '-> .bss+$0004').  The symbol a relocation names
is the entry AFTER its symbol index (the index points at a (-3, 0) entry in
front of the real one; checked on the dispatcher's table, whose const names
1135 and whose address .lit $D60 + $80 is entry 1136).

Usage:  antelope_partial_dasm.py [ACEF_100.bin] > firmware/disasm/text.partial.asm
"""
import os, sys, collections
import unmask_antelope_low as u
from am29k_dasm import decode, spr

ANT = u.ANT
FULL = {'nop': 0x70400101, 'jmpi_lr0': 0xC0000080,
        'asleu65': 0x5641817F, 'asgeu64': 0x5E40017E}     # vectors as patched
FRAME = {'sub_gr1': 0x25010100, 'add_gr1': 0x15010100, 'add_lr1': 0x15810100}
BR = {'jmp', 'jmpf', 'jmpt', 'jmpfdec', 'call', 'jmpi', 'jmpfi', 'calli',
      'jmpti', 'iret', 'iretinv'}


def reg(n):
    return 'gr%d' % n if n < 128 else 'lr%d' % (n - 128)


def ra_str(w, n):
    ra = (w >> 8) & 0xFF
    return reg(ra) if n >= 16 else '?r%d' % (ra & 0x7F)


def partial(w, n, pc):
    """Decode a word whose low n bits are plain (n >= 15, < 24)."""
    o = w >> 24
    rb = w & 0xFF
    M = o & 1
    RA = ra_str(w, n)
    RB = '$%02x' % rb if M else reg(rb)
    if o in (0x01, 0x02, 0x03):
        return {1: 'constn', 2: 'consth', 3: 'const'}[o], '%s, $??%02x' % (RA, rb)
    mn, _, _ = decode(w, pc)                # mnemonic from the opcode byte only
    if mn == '.word':
        return mn, '$%02x??%04x' % (o, w & 0xFFFF)
    if mn in ('jmp',):
        return mn, '? (disp lo $%02x)' % rb
    if mn in ('jmpf', 'jmpt', 'jmpfdec', 'call'):
        return mn, '%s, ? (disp lo $%02x)' % (RA, rb)
    if mn in ('jmpi',):
        return mn, reg(rb)
    if mn in ('jmpfi', 'jmpti', 'calli', 'mttlb', 'setip'):
        return mn, '%s, %s' % (RA, reg(rb))
    if mn == 'mtsr':
        return mn, '%s, %s' % (spr((w >> 8) & 0xFF) if n >= 16 else '?', reg(rb))
    if mn == 'mfsr':
        return mn, '?, %s' % (spr((w >> 8) & 0xFF) if n >= 16 else '?')
    if mn == 'mtsrim':
        return mn, '%s, $??%02x' % (spr((w >> 8) & 0xFF) if n >= 16 else '?', rb)
    if mn in ('load', 'loadl', 'store', 'storel', 'loadset', 'loadm', 'storem'):
        return mn, '?, ?, %s, %s' % (RA, RB)
    if mn.startswith('as'):
        return mn, 'trap?, %s, %s' % (RA, RB)
    if mn in ('iret', 'iretinv', 'halt', 'inv'):
        return mn, ''
    if mn in ('clz', 'div0'):
        return mn, '?, %s' % RB
    # ALU ops (type1): RC masked
    return mn, '?, %s, %s' % (RA, RB)


SECNAME = {1: 'Code', 2: '.text', 3: '.lit', 4: '.data', 5: 'Apple', 6: '.data1', 7: '.bss'}


def reloc_targets(path):
    """word offset -> 'section+addend' for the const/consth relocations."""
    import apply_reloc as a
    d, K, sp, ns, secs = a.load(path)
    sym, _, _ = a.make_resolver(d, sp, ns, secs)
    t = [s for s in secs if s['name'] == '.text'][0]
    R = a.get_relocs(d, t)
    ihc = {va - t['vaddr']: si for va, si, ty in R if ty == 28}
    out = {}
    for va, si, ty in R:
        if ty == 24:                            # R_IREL: a direct 'call'
            n = si + 1 if sym(si)[0] == -3 else si
            sc, v = sym(n)
            out[va - t['vaddr']] = (SECNAME.get(sc, str(sc)), v, ty)
        elif ty in (26, 27):
            n = si + 1 if sym(si)[0] == -3 else si
            sc, v = sym(n)
            if sc == 0:                         # undefined: an external symbol
                out[va - t['vaddr']] = ('extern#%d' % n, 0, ty)
            else:
                out[va - t['vaddr']] = (SECNAME.get(sc, str(sc)), v, ty)
    return out, ihc


def main():
    W = u.words(os.path.join(ANT, 'text.bin'))
    U, known = u.unmask_best(W)
    S, kind = u.load_samples()
    plain = {}
    for k in S:
        if kind[k] in FULL:
            plain[k] = FULL[kind[k]]
        elif kind[k] in FRAME:
            plain[k] = FRAME[kind[k]] | (U[k] & 0xFF)
        else:
            plain[k] = W[k] ^ S[k]
    rel, ihc = reloc_targets(sys.argv[1]) if len(sys.argv) > 1 else ({}, {})
    syms = set()
    for ln in open(os.path.join(ANT, 'symbols.txt')):
        p = ln.split()
        if len(p) == 2 and p[0] == '.text':
            syms.add(int(p[1], 16))
    def tgt_is_stub(v):                     # 'const gr121, N' starts a stub
        x = U[v // 4]
        return x >> 24 == 0x03 and (x >> 8) & 0xFF == 121

    out, delay = [], False
    mix = collections.Counter()
    for i, w in enumerate(U):
        pc = 4 * i
        if pc in syms:
            out.append('')
            out.append('sub_%05x:' % pc)
        n = known[i]
        if i in plain:
            p = plain[i]
            mn, ops, _ = decode(p, pc)
            if p == 0x70400101:
                mn, ops = 'nop', ''
            hexs = '%08x' % p
        else:
            mn, ops = partial(w, n, pc)
            hexs = '%02x??%04x' % (w >> 24, w & 0xFFFF) if n >= 16 else \
                   '%02x??%04x' % (w >> 24, w & 0x7FFF)
        mix[mn] += 1
        ann = '   ; [delay slot]' if delay else ''
        if pc in rel:
            sec, v, ty = rel[pc]
            if ty == 26:
                ann += '   ; lo of %s' % sec + ('+$%x' % v if v else '')
            elif ty == 24:
                ops = '%s, $%05x' % (ops.split(',')[0], v)
                ann += '   ; R_IREL call -> %s $%05x' % (sec, v)
                if sec == '.text' and tgt_is_stub(v):
                    ann += ' (service $??%02x)' % (U[v // 4] & 0xFF)
                elif sec == '.text' and v in syms:
                    ann += ' (sub_%05x)' % v
            else:
                add = ihc.get(pc)
                tgt = v + (add or 0)
                ann += '   ; -> %s $%05x' % (sec, tgt) if sec == '.text' else \
                       '   ; -> %s+$%04x' % (sec, tgt)
                if sec == '.text' and tgt in syms:
                    ann += ' (sub_%05x)' % tgt
        out.append('  %05x:  %s  %-8s %s%s' % (pc, hexs, mn, ops, ann))
        delay = mn in BR
    head = [
        '* ' + '=' * 66,
        '*  ACEF_100 "32-Bit Antelope" -- .text, PARTIAL disassembly',
        '* ' + '=' * 66,
        '*  Made by ../../antelope_partial_dasm.py from the partly unmasked',
        '*  words (../../unmask_antelope_low.py).  Fields still masked print',
        '*  as "?": RC (the destination of ALU ops and loads), the high byte',
        '*  of every 16-bit immediate, and so every jump/call target.  RA is',
        '*  printed as "?rN" (gr or lr N) where its top bit is not known.',
        '*  Words whose full plaintext is known (frame and padding idioms,',
        '*  relocated const/consth) are decoded completely.  A relocated',
        '*  const/consth pair is commented with its target ("-> .text $15808",',
        '*  "-> .bss+$0004"; "extern#N" is an undefined symbol, N its index',
        '*  in the symbol table).  A direct call with an R_IREL relocation',
        '*  (displacement 0 in the file, filled in by the loader) shows its',
        '*  target and, for the 16-byte system-call stubs, the service.',
        '*  The hex column shows the unmasked word',
        '*  with the masked byte as "??".  Labels sub_XXXXX are the 768',
        '*  .text entries of the (unmasked) ACEF symbol table.',
        '*',
        '*  Instruction mix (top 24 mnemonics):',
    ]
    for mn, c in mix.most_common(24):
        head.append('*    %-8s %6d' % (mn, c))
    head.append('*')
    print('\n'.join(head + out))


if __name__ == '__main__':
    main()
