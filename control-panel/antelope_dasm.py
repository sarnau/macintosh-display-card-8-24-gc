#!/usr/bin/env python3
"""antelope_dasm.py -- exact disassembly and data listings of an Antelope ACEF.

The section data is decrypted exactly as DRVR's ACEFLoad does it
(acef_unpack.decrypt), so every word is plaintext.  Written to OUTDIR:

  text.asm   .text with function labels (the ACEF symbol table), object-file
             starts (antelope_modules.py), names (antelope_names.py) and the
             target of every relocated word and direct jump/call
  Code.asm   the Code section (the entry stub at $F000)
  lit.asm    .lit: its strings, then a word listing with relocation targets
  data.asm   .data and .data1: word listing with object-file starts, symbols,
             ASCII and relocation targets

Relocations (8-byte records [vaddr:u32][symndx:u16][type:u16]; a symbol with
section number -3 is a placeholder, the symbol is the next record):
  24  call: the word's displacement is filled with the symbol
  26  const: target = symbol + the word's 16-bit immediate
  27  consth: target = symbol + (immediate << 16 | low half); the low half of
      the addend is the symbol index of the type-28 record that follows
  29, 31  a 32-bit word (target = symbol + word) or, at byte 1 of a word,
      one byte (the trap numbers V_SPILL/V_FILL of the spill/fill asserts)

Names: the System 7 names in antelope_names.NAMES.  For another build, give
the System 7 ACEF with --names-from: a function whose code is identical to a
named System 7 function (relocated words and call displacements ignored)
takes its name.

Usage:  antelope_dasm.py ACEF_100.bin OUTDIR [--names-from S7_ACEF_100.bin]
"""
import collections, os, struct, sys
import acef_unpack, apply_reloc as ar, antelope_modules as am
from am29k_dasm import decode
from antelope_names import NAMES, BANNERS

SECNAME = {1: 'Code', 2: '.text', 3: '.lit', 4: '.data', 5: 'Apple', 6: '.data1', 7: '.bss'}
BR = {'jmp', 'jmpf', 'jmpt', 'jmpfdec', 'call', 'jmpi', 'jmpfi', 'calli', 'jmpti'}
HIF = {0x01: 'exit', 0x11: 'open', 0x12: 'close', 0x13: 'read', 0x14: 'write',
       0x15: 'lseek', 0x16: 'remove', 0x21: 'tmpnam', 0x111: 'clock', 0x112: 'cycles',
       0x101: 'sysalloc', 0x103: 'getpsize', 0x104: 'getargs', 0x121: 'setvec'}


class Image:
    def __init__(self, path):
        self.d, self.key, self.sp, self.ns, self.secs = ar.load(path)
        self.sec = {s['name']: s for s in self.secs}
        self.idx = {s['name']: i + 1 for i, s in enumerate(self.secs)}

    def data(self, name):
        s = self.sec[name]
        if not (s['scnptr'] and s['size']):
            return b''
        return acef_unpack.decrypt(self.d[s['scnptr']:s['scnptr'] + s['size']], self.key, s['scnptr'])

    def words(self, name):
        b = self.data(name)
        return list(struct.unpack('>%dI' % (len(b) // 4), b[:len(b) // 4 * 4]))

    def S(self, i):
        return struct.unpack('>hI', self.d[self.sp + 6 * i:self.sp + 6 * i + 6])

    def symbol(self, si):
        """(section name or 'extern#N' or 'abs', value) of a relocation's symbol."""
        n = si + 1 if self.S(si)[0] == -3 else si
        sc, v = self.S(n)
        if sc == 0:
            return 'extern#%d' % n, 0
        if sc == -1:
            return 'abs', v
        return SECNAME.get(sc, 'sec%d' % sc), v

    def relocs(self, name):
        """offset in section -> (type, section, target)."""
        s = self.sec[name]
        raw = self.d[s['relptr']:s['relptr'] + 8 * s['nrel']]
        R = [struct.unpack('>IHH', raw[8 * i:8 * i + 8]) for i in range(s['nrel'])]
        W = self.data(name)
        word = lambda off: struct.unpack('>I', W[off & ~3:(off & ~3) + 4])[0]
        i16 = lambda w: ((w >> 8) & 0xFF00) | (w & 0xFF)
        out = {}
        for j, (va, si, ty) in enumerate(R):
            off = va - s['vaddr']
            if ty == 28:
                continue
            sec, v = self.symbol(si)
            w = word(off)
            if ty == 24:
                t = v
            elif ty == 26:
                t = v + i16(w)
            elif ty == 27:
                lo = R[j + 1][1] if j + 1 < len(R) and R[j + 1][2] == 28 else 0
                t = v + ((i16(w) << 16) | lo)
            elif ty in (29, 31):
                t = v + w if off % 4 == 0 else v
            else:
                t = v
            out[off] = (ty, sec, t & 0xFFFFFFFF)
        return out


def functions(img):
    """Sorted .text symbol addresses, object-file starts {addr: (n, kind)},
    and per-file section starts."""
    h = am.header(img.d)
    fs, _, _ = am.files(img.d, h['symptr'], h['nsyms'])
    own, _ = am.split_globals(fs[-1])
    rows = [am.classify(f['syms']) for f in fs[:-1]] + [am.classify(own)]
    funcs = {v for r in rows for v in r['funcs']}
    files = {}
    for n, r in enumerate(rows):
        if r['start'] is not None and r['start'] not in funcs and r['start'] not in files:
            files[r['start']] = (n, r['kind'])
    syms = sorted({v for i in range(img.ns) for sc, v in [img.S(i)] if sc == 2})
    return syms, files, rows


def signature(W, rel, a, b):
    sig = []
    for k in range(a // 4, b // 4):
        w = W[k]
        if 4 * k in rel or (w >> 24) in (0x03, 0x02) and 4 * k in rel:
            sig.append(w >> 24)
        elif (w >> 24) in (0xA8, 0xA9):
            sig.append(w & 0xFFFF0000 & 0xFF00FF00)     # call: displacement ignored
        else:
            sig.append(w)
    return tuple(sig)


def match_names(img, ref):
    """Names for img's functions by identical code in the named reference."""
    W, Wr = img.words('.text'), ref.words('.text')
    rel, relr = img.relocs('.text'), ref.relocs('.text')
    syms, _, _ = functions(img)
    symr, _, _ = functions(ref)
    ends = lambda s, n: [(x, (s + [n])[i + 1]) for i, x in enumerate(s)]
    sigs = collections.defaultdict(list)
    for a, b in ends(symr, 4 * len(Wr)):
        if a in NAMES:
            sigs[signature(Wr, relr, a, b)].append(a)
    out = {}
    for a, b in ends(syms, 4 * len(W)):
        c = sigs.get(signature(W, rel, a, b), [])
        if len(c) == 1:
            out[a] = NAMES[c[0]]
    return out


def dasm_section(img, name, base, names, syms, files, svc):
    W = img.words(name)
    rel = img.relocs(name)
    lab = {a: 'sub_%05x' % a for a in syms}
    for i, w in enumerate(W):
        mn, ops, t = decode(w, base + 4 * i)
        if t is not None and 4 * i not in rel and mn in ('jmp', 'jmpf', 'jmpt', 'jmpfdec') \
                and base <= t < base + 4 * len(W):
            lab.setdefault(t, 'L_%05x' % t)

    def tname(sec, t):
        if sec in ('.text', 'Code'):
            s = '%s $%05x' % (sec, t)
            if t in names:
                s += ' (%s)' % names[t]
            elif t in svc:
                s += ' (%s)' % svc[t]
            elif t in lab:
                s += ' (%s)' % lab[t]
            return s
        if sec == 'abs':
            return '$%x' % t
        return '%s+$%04x' % (sec, t) if not sec.startswith('extern') else '%s+$%x' % (sec, t)
    out, delay = [], False
    mix = collections.Counter()
    for i, w in enumerate(W):
        pc = base + 4 * i
        if pc in files:
            out.append('')
            bn = BANNERS.get(names.get(pc + 4) or names.get(pc) or svc.get(pc + 4) or svc.get(pc))
            if bn:
                if bn[0]:
                    out += ['* ' + '=' * 66, '*  ' + bn[0], '* ' + '=' * 66]
                out += ['*  ' + l for l in bn[1:]]
            out.append('file_%02d:   ; object file %d (%s): .text starts here' % (
                files[pc][0], files[pc][0], files[pc][1]))
        if pc in lab:
            if lab[pc].startswith('sub_'):
                if pc not in files:
                    out.append('')
                nm = names.get(pc) or svc.get(pc)
                out.append(lab[pc] + ':' + ('   ; %s' % nm if nm else ''))
            else:
                out.append(lab[pc] + ':')
        mn, ops, t = decode(w, pc)
        if w == 0x70400101:
            mn, ops = 'nop', ''
        if w >> 24 == 0 and (pc + 4) in syms:
            mn, ops = '.word', '$%08x   ; tag word: %d arguments, frame $%x' % (w, (w >> 16) - 2, w & 0xFFFF) \
                if w >> 16 >= 2 else '$%08x   ; tag word' % w
        mix[mn] += 1
        ann = ''
        if pc - base in rel:
            ty, sec, tt = rel[pc - base]
            if ty == 24:
                ops = ops.split(',')[0] + ', ' + ('$%05x' % tt if sec in ('.text', 'Code') else sec)
                ann = '   ; -> ' + tname(sec, tt)
            elif ty == 26:
                ann = '   ; lo of ' + tname(sec, tt)
            elif ty == 27:
                ann = '   ; hi of ' + tname(sec, tt)
            elif pc % 4 == 0:
                ann = '   ; word -> ' + tname(sec, tt)
        elif t is not None and mn in BR:
            if t in names or t in lab or t in svc:
                ann = '   ; -> ' + (names.get(t) or svc.get(t) or lab[t])
        if pc - base + 1 in rel:             # byte relocation: the trap number
            ops = ops.replace('trap0,', 'trap%d,' % rel[pc - base + 1][2], 1)
        if delay:
            ann += '   ; [delay slot]'
        out.append('  %05x:  %08x  %-8s %s%s' % (pc, w, mn, ops, ann))
        delay = mn in BR
    return out, mix


def services(img, syms):
    """Stub functions 'const gr121, N; asneq ...' -> name by service."""
    W = img.words('.text')
    out = {}
    for a in syms:
        if a // 4 + 1 >= len(W):
            continue
        w = W[a // 4]
        if w >> 24 == 0x03 and (w >> 8) & 0xFF == 121:
            n = ((w >> 8) & 0xFF00) | (w & 0xFF)
            out[a] = 'svc_%X' % n + (' = HIF %s' % HIF[n] if n in HIF else '')
    return out


def strings(b, base=0, minlen=4):
    out, cur, st = [], b'', None
    for i, c in enumerate(b):
        if 32 <= c < 127 or c in (9, 10, 13):
            if st is None:
                st = i
            cur += bytes([c])
        else:
            if c == 0 and st is not None and len(cur) >= minlen:
                out.append((base + st, cur.decode('latin1')))
            cur, st = b'', None
    return out


def listing(img, name, names, svc, labels, title):
    b = img.data(name)
    rel = img.relocs(name) if img.sec[name]['nrel'] else {}
    out = ['* ' + '=' * 66, '*  %s -- %s (%d bytes, %d relocations)' % (title, name, len(b), len(rel)), '* ' + '=' * 66]
    st = strings(b)
    if st:
        out.append('*  Strings (NUL-terminated, 4 characters or more):')
        for a, s in st:
            out.append('*    $%04x  %r' % (a, s))
        out.append('*')
    for i in range(0, len(b) - len(b) % 4, 4):
        for l in labels.get(i, []):
            out.append(l)
        w = struct.unpack('>I', b[i:i + 4])[0]
        asc = ''.join(chr(c) if 32 <= c < 127 else '.' for c in b[i:i + 4])
        ann = ''
        if i in rel:
            ty, sec, t = rel[i]
            if sec in ('.text', 'Code'):
                ann = '  ; -> %s $%05x' % (sec, t) + (' (%s)' % (names.get(t) or svc.get(t) or 'sub_%05x' % t)
                                                     if t in names or t in svc else '')
            elif sec == 'abs':
                ann = '  ; -> $%x' % t
            else:
                ann = '  ; -> %s+$%04x' % (sec, t)
        out.append('  %04x:  %08x  |%s|%s' % (i, w, asc, ann))
    for i in range(len(b) - len(b) % 4, len(b)):
        out.append('  %04x:  %02x        (trailing byte, not loaded by ACEFLoad)' % (i, b[i]))
    return out


def main(path, outdir, ref=None):
    img = Image(path)
    h = am.header(img.d)
    title = 'ACEF "%s" version $%08X' % (h['name'], h['version'])
    syms, files, rows = functions(img)
    names = dict(NAMES) if ref is None else match_names(img, Image(ref))
    svc = services(img, syms)
    os.makedirs(outdir, exist_ok=True)
    out, mix = dasm_section(img, '.text', 0, names, set(syms), files, svc)
    head = ['* ' + '=' * 66, '*  %s -- .text, exact disassembly' % title, '* ' + '=' * 66,
            '*  Made by antelope_dasm.py from the section data decrypted as DRVR\'s',
            '*  ACEFLoad does it (acef_unpack.decrypt).  sub_XXXXX = a function of the',
            '*  ACEF symbol table, file_NN = the .text start of object file NN',
            '*  (antelope_modules.py), L_XXXXX = a jump target.  Names after a label',
            '*  come from antelope_names.py%s; svc_N = a kernel/HIF service stub.' % (
                '' if ref is None else ' via identical code in System 7'),
            '*  Relocated words show their target (symbol + the addend in the word);',
            '*  "extern#N" is an undefined symbol (N = its symbol index).  The spill/',
            '*  fill asserts carry trap number 0 in the file; the loader patches',
            '*  in V_SPILL/V_FILL (64/65) from the byte relocations.',
            '*  Banners (antelope_names.BANNERS) open each object file whose first',
            '*  function is named, grouped under subsystem headings.',
            '*  %d functions named.' % sum(1 for a in syms if a in names),
            '*', '*  Instruction mix (top 24 mnemonics):']
    head += ['*    %-8s %6d' % kv for kv in mix.most_common(24)] + ['*']
    open(os.path.join(outdir, 'text.asm'), 'w').write('\n'.join(head + out) + '\n')
    code, _ = dasm_section(img, 'Code', img.sec['Code']['vaddr'], names, set(), {}, svc)
    open(os.path.join(outdir, 'Code.asm'), 'w').write('\n'.join(
        ['* %s -- Code (the entry stub), exact' % title] + code) + '\n')
    open(os.path.join(outdir, 'lit.asm'), 'w').write('\n'.join(listing(img, '.lit', names, svc, {}, title)) + '\n')
    dl = collections.defaultdict(list)
    for n, r in enumerate(rows):
        if 4 in r['secs']:
            dl[r['secs'][4]].append('\n; ---- object file %d: .data starts here' % n)
    for i in range(img.ns):
        sc, v = img.S(i)
        if sc == 4 and 'obj_%04x:' % v not in dl[v]:
            dl[v].append('obj_%04x:' % v)
    data = listing(img, '.data', names, svc, dl, title)
    if '.data1' in img.sec:
        data += [''] + listing(img, '.data1', names, svc, {}, title)
    open(os.path.join(outdir, 'data.asm'), 'w').write('\n'.join(data) + '\n')
    print('%s: %d .text words, %d functions (%d named), %d object files -> %s' % (
        path, len(img.words('.text')), len(syms), sum(1 for a in syms if a in names), len(rows), outdir))


if __name__ == '__main__':
    a = sys.argv[1:]
    ref = None
    if '--names-from' in a:
        i = a.index('--names-from'); ref = a[i + 1]; del a[i:i + 2]
    if len(a) != 2:
        sys.exit(__doc__)
    main(a[0], a[1], ref)
