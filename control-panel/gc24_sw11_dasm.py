#!/usr/bin/env python3
# gc24_sw11_dasm.py -- plain recursive-descent disassembly (capstone 5) of a
# gc24 resource in the System 6 layout (44-byte dispatch entries).
# usage: gc24_sw11_dasm.py BIN NOTES.py OUT.s   (NOTES.py: HEADER and NOTES)
import sys, re, struct, capstone

d = open(sys.argv[1], 'rb').read()
notes = {}
exec(open(sys.argv[2]).read())          # defines HEADER (str) and NOTES {addr: [lines]}
N = len(d)
md = capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_M68K_020)
md.detail = False

def dis1(a):
    try:
        return next(md.disasm(d[a:a + 12], a))
    except StopIteration:
        return None

# dispatch table
entries = []
o = 0
while d[o + 4:o + 8] == bytes.fromhex('2f082078'):
    entries.append(o)
    o += 0x2c
TABEND = o

code = {}          # addr -> insn
labels = {}        # addr -> kind ('L'/'sub')
refs = {}          # insn addr -> target
jtabs = {}         # table addr -> (count, base)
seeds = []
for e in entries:
    seeds.append(e + 4)
    seeds.append(e + 0x28)
    labels[e + 4] = 'L'
seeds += EXTRA_SEEDS
for t in EXTRA_SEEDS:
    labels.setdefault(t, 'L')

TERM = {'rts', 'rte', 'rtd', 'rtr', 'bra', 'bra.b', 'bra.w', 'bra.l', 'jmp'}
hexre = re.compile(r'\$([0-9a-f]+)')

def run(seedlist):
    work = list(seedlist)
    while work:
        a = work.pop()
        prev = []
        while 0 <= a < N and a not in code and not any(t <= a < t + 2 * c for t, (c, b) in jtabs.items()):
            i = dis1(a)
            if i is None or i.size == 0:
                break
            code[a] = i
            m, ops = i.mnemonic, i.op_str
            tgt = None
            if (m.startswith('b') and not m.startswith(('btst', 'bset', 'bclr', 'bchg', 'bfext', 'bfins', 'bftst', 'bfset', 'bfclr', 'bfchg', 'bfffo', 'bkpt'))) or m.startswith('db'):
                h = hexre.findall(ops)
                if h:
                    tgt = int(h[-1], 16)
                    labels.setdefault(tgt, 'sub' if m.startswith('bsr') else 'L')
                    if m.startswith('bsr'):
                        labels[tgt] = 'sub'
            elif m in ('jsr', 'jmp') and re.fullmatch(r'\$[0-9a-f]+\(pc\)', ops):
                tgt = int(ops[1:ops.index('(')], 16)
                labels[tgt] = 'sub' if m == 'jsr' else labels.get(tgt, 'L')
            elif m == 'jmp' and re.fullmatch(r'\$[0-9a-f]+\(pc,d\d\.w\)', ops) and prev:
                p = prev[-1]
                mm = re.match(r'\$([0-9a-f]+)\(pc, d\d\.[wl]\), d\d', p.op_str)
                cnt = None
                for q in reversed(prev[-6:]):
                    mc = re.match(r'#\$([0-9a-f]+), d\d', q.op_str)
                    if q.mnemonic.startswith('cmpi') and mc:
                        cnt = int(mc.group(1), 16) + 1
                        break
                if p.mnemonic == 'move.w' and mm and cnt:
                    t = int(mm.group(1), 16)
                    base = int(ops[1:ops.index('(')], 16)
                    jtabs[t] = (cnt, base)
                    for k in range(cnt):
                        w = struct.unpack('>h', d[t + 2 * k:t + 2 * k + 2])[0]
                        labels.setdefault(base + w, 'L')
                        work.append(base + w)
            if tgt is not None:
                refs[a] = tgt
                work.append(tgt)
            elif m in ('lea', 'pea') and re.match(r'\$[0-9a-f]+\(pc\)', ops):
                t = int(ops[1:ops.index('(')], 16)
                refs[a] = t
                if d[t:t + 2] in (b'\x4e\x56', b'\x48\xe7'):
                    labels[t] = 'sub'
                    work.append(t)
            prev.append(i)
            if m in TERM:
                break
            a += i.size

run(seeds)
# second pass: link-a6 prologues in gaps
for _ in range(4):
    new = []
    a = TABEND
    while a < N - 1:
        if a in code:
            a += code[a].size
            continue
        if a % 2 == 0 and d[a:a + 2] == b'\x4e\x56' and dis1(a) is not None:
            new.append(a)
            labels.setdefault(a, 'sub')
        a += 2
    if not new:
        break
    run(new)

def name(t):
    if t in NAMES:
        return NAMES[t]
    return ('sub_%x' if labels.get(t) == 'sub' else 'L%x') % t

def macsbug(a):
    b = d[a]
    if 0x81 <= b <= 0x9f:
        n = b & 0x1f
        s = d[a + 1:a + 1 + n]
        if len(s) == n and all(32 < c < 127 for c in s):
            n2 = 1 + n
            if n2 % 2:
                n2 += 1
            return n2 + 2, s.decode()
    return None

out = []
w = out.append
w(HEADER.rstrip('\n'))
a = 0
while a < N:
    for ln in NOTES.get(a, []):
        w('* ' + ln if ln else '*')
    if a in labels and (a in code):
        w(name(a) + ':')
    if a in entries:
        v = struct.unpack('>I', d[a:a + 4])[0]
        idx = entries.index(a)
        w('  %06x:  %-20s %-8s $%08X  ; dispatch #%d' % (a, ' '.join('%02x' % c for c in d[a:a + 4]), 'dc.l', v, idx))
        a += 4
        continue
    if a in code:
        i = code[a]
        hb = ' '.join('%02x' % c for c in d[a:a + i.size])
        cmt = ''
        if a in refs and (refs[a] in code):
            cmt = '  ; -> ' + name(refs[a])
        w(('  %06x:  %-20s %-8s %s' % (a, hb, i.mnemonic, i.op_str)).rstrip() + cmt)
        a += i.size
        continue
    if a in jtabs:
        cnt, base = jtabs[a]
        for k in range(cnt):
            v = struct.unpack('>h', d[a:a + 2])[0]
            w('  %06x:  %-20s %-8s $%04X    ; [%d] -> %s' % (a, '%02x %02x' % (d[a], d[a + 1]), 'dc.w', v & 0xffff, k, name(base + v)))
            a += 2
        continue
    # data up to next code/table
    e = a + 1
    while e < N and e not in code and e not in jtabs:
        e += 1
    while a < e:
        ms = macsbug(a) if ((a - 2) in code and code[a - 2].mnemonic in ('rts', 'jmp')) or ((a - 4) in code and code[a - 4].mnemonic.startswith('rtd')) else None
        if ms and a + ms[0] <= e:
            n, s = ms
            w('  %06x:  %-20s %-8s "%s"  ; MacsBug name' % (a, ' '.join('%02x' % c for c in d[a:a + min(n, 8)]) + (' ..' if n > 8 else ''), 'dc.b', s))
            a += n
            continue
        k = min(8, e - a)
        chunk = d[a:a + k]
        asc = ''.join(chr(c) if 32 <= c < 127 else '.' for c in chunk)
        w('  %06x:  %-20s %-8s %s  ; %s' % (a, ' '.join('%02x' % c for c in chunk), 'dc.b', ', '.join('$%02X' % c for c in chunk), asc))
        a += k
open(sys.argv[3], 'w').write('\n'.join(out) + '\n')
print('entries', len(entries), 'tabend', hex(TABEND), 'code bytes', sum(i.size for i in code.values()), 'of', N, 'jtabs', len(jtabs))
