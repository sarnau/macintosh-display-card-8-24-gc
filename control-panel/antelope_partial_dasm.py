#!/usr/bin/env python3
"""antelope_partial_dasm.py -- partial disassembly of Antelope's .text.

Uses unmask_antelope_low.py for the key: its exact low bits (bits 0-14 of
every word, bit 15 for ~96%, bits 16-18 for some) and, for 98% of the words,
bits 16-23 from the neighbouring samples (unmask_antelope_low.high_key; '~'
after the hex word, or '!' where the word lies inside a step of the key and
the switch point was chosen from opcode statistics).  Those words decode in
full, with jump and call targets.  In the rest, fields that are still
masked print as '?':

    RB / I8 (bits 0-7)    always plain
    RA      (bits 8-15)   plain when 16 bits are known, else '?rN' = gr/lr N
    RC      (bits 16-23)  '?'
    I16 high byte         '??' (it lives in the RC field)
    jump / call targets   '?' with the known low displacement byte

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


# Function names established in HOST_CARD_PROTOCOL.md (by role where the
# original name is unknown).  Printed on the label line and after targets.
NAMES = {
    0x00140: 'Report', 0x00248: 'CopyLongsBurst', 0x00294: 'Fill2LongsBurst',
    0x00348: 'FillLongsBurst', 0x00F84: 'ReportToLog', 0x16C48: 'CopyHostMemory',
    0x17264: 'Fill2Longs', 0x3B814: 'mul_millicode',
    0x01494: 'RSect', 0x01654: 'TrimRect', 0x01A50: 'BitBlt',
    0x06650: 'ITabMatch', 0x06BEC: 'BitsToPixMap', 0x06F1C: 'ColorMap',
    0x075DC: 'DrawArc', 0x08618: 'DrawLine', 0x0AD18: 'DrawMultiObject',
    0x11AD8: 'DrawText', 0x13F54: 'IsOnThisCard', 0x14034: 'DisposeOffscreen',
    0x14168: 'FlushOffscreen', 0x141F8: 'FlushColorTable', 0x14564: 'ConvertFontStrike', 0x14A80: 'UploadFontStrike',
    0x15958: 'CacheAlloc', 0x15B3C: 'CacheRelease', 0x376A0: 'HeapFree',
    0x14B64: 'UploadWidthTable', 0x14F64: 'CacheGDevice', 0x151C4: 'CachePixPat',
    0x15808: 'FlushGDevice', 0x158F4: 'FlushPixPat', 0x15D28: 'CacheFind',
    0x15E8C: 'CacheFindStamp', 0x15EE4: 'CacheCreate', 0x15FF4: 'CacheFindOrCreate',
    0x161F8: 'PRInit', 0x16A04: 'PRAlloc', 0x1701C: 'FillLongs',
    0x19270: 'QuickPolys', 0x19DA4: 'RgnBlt', 0x22A8C: 'scaleBlt',
    0x253D4: 'GetSeek', 0x2D7B8: 'StretchBits', 0x31E20: 'CommandDispatcher',
    0x32C10: 'ShieldCursor', 0x32EF8: 'ShowCursorAfterDraw', 0x3373C: 'MapVirtual',
    0x33A9C: 'UnmapAll', 0x33EBC: 'CallBack', 0x37000: 'TestSlotBurst', 0x37C10: 'FillPatternStorem',
    0x37D68: 'FillLongsStorem', 0x38218: 'CopyLongsStorem', 0x388D0: 'CopyLongsBackStorem',
    # C library (HIF)
    0x39214: 'vprintf', 0x39284: 'printf', 0x39304: 'fseek', 0x39864: 'sprintf',
    0x399E0: '_doprnt', 0x3AA9C: 'isupper', 0x3AAB8: 'islower', 0x3AAD4: 'isalpha',
    0x3AAF0: 'isdigit', 0x3AB0C: 'isxdigit', 0x3AB28: 'isspace', 0x3AB44: 'ispunct',
    0x3AB60: 'isalnum', 0x3AB7C: 'isgraph', 0x3AB98: 'isprint', 0x3ABB4: 'iscntrl',
    0x3ABD0: 'isascii', 0x3ABF8: 'toupper', 0x3AC24: 'tolower', 0x3AC88: 'exit',
    0x3B404: '_hif_close', 0x3B428: '_hif_exit', 0x3B44C: '_hif_lseek',
    0x3B470: '_hif_open', 0x3B494: '_hif_read', 0x3B4B8: '_hif_21',
    0x3B4DC: '_hif_write', 0x3B500: 'memset',
}


def tname(v):
    return ' (sub_%05x %s)' % (v, NAMES[v]) if v in NAMES else ' (sub_%05x)' % v


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
    E, flag = u.unmask_estimated(W)
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
            out.append('sub_%05x:' % pc + ('   ; %s' % NAMES[pc] if pc in NAMES else ''))
        n = known[i]
        jann = ''
        if i in plain:
            p = plain[i]
            mn, ops, _ = decode(p, pc)
            if p == 0x70400101:
                mn, ops = 'nop', ''
            hexs = '%08x ' % p
        elif flag[i] in '=t':
            p = E[i]
            mn, ops, tgt = decode(p, pc)
            if p == 0x70400101:
                mn, ops = 'nop', ''
            hexs = '%08x%s' % (p, '~' if flag[i] == '=' else '!')
            if tgt is not None and mn in ('jmp', 'jmpf', 'jmpt', 'jmpfdec', 'call') \
                    and not p & 0x01000000 and pc not in rel:
                if tgt in syms:
                    jann = '   ; ->' + tname(tgt)
        else:
            mn, ops = partial(w, n, pc)
            hexs = '%02x??%04x ' % (w >> 24, w & 0xFFFF) if n >= 16 else \
                   '%02x??%04x ' % (w >> 24, w & 0x7FFF)
        mix[mn] += 1
        ann = jann + ('   ; [delay slot]' if delay else '')
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
                    ann += tname(v)
            else:
                add = ihc.get(pc)
                tgt = v + (add or 0)
                ann += '   ; -> %s $%05x' % (sec, tgt) if sec == '.text' else \
                       '   ; -> %s+$%04x' % (sec, tgt)
                if sec == '.text' and tgt in syms:
                    ann += tname(tgt)
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
        '*  The hex column shows the unmasked word.  A "~" after it marks',
        '*  bits 16-23 taken from the neighbouring samples (both sides',
        '*  agree), a "!" bits 16-23 inside a step of the key, where the',
        '*  switch point was chosen from opcode statistics (less sure).',
        '*  Both are decoded in full, with jump and call targets.  "??" is',
        '*  a byte still masked (no estimate).  Labels sub_XXXXX are the 768',
        '*  .text entries of the (unmasked) ACEF symbol table.  Functions',
        '*  named in HOST_CARD_PROTOCOL.md carry their name on the label line',
        '*  and after each target that points at them (NAMES in the script;',
        '*  names by role where the original is unknown).',
        '*',
        '*  Instruction mix (top 24 mnemonics):',
    ]
    for mn, c in mix.most_common(24):
        head.append('*    %-8s %6d' % (mn, c))
    head.append('*')
    print('\n'.join(head + out))


if __name__ == '__main__':
    main()
