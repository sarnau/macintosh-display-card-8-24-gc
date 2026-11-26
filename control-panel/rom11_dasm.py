#!/usr/bin/env python3
# rom11_dasm.py -- plain listing of the later 8*24 GC declaration ROM 341-0266
# ("MDC 8*24 GC 1.1", 64 KB, data $0000-$5141).
#
# usage: python3 -E -P control-panel/rom11_dasm.py ROM OUTDIR
#
# Writes OUTDIR/PrimaryInit.s, SecondaryInit.s, VideoDriver.s (recursive-
# descent 68020 disassembly with capstone 5, data as dc.b/dc.w) and
# OUTDIR/sResources.txt (format block, sRsrc directory, every sRsrc decoded,
# the board sRsrc's id $7E timing sBlocks per monitor).  It then re-reads the
# three .s files and checks that every listed byte column equals the ROM.
# The listings are not annotated beyond labels, trap names and NOTES below.
import sys, os, re, struct, capstone

# ---------------------------------------------------------------- names ----
# Routines matched to the 1.0 listings (extracted-source/*.s, ROM 341-0812).
# addr: (label, comment)
NOTES = {
    # PrimaryInit
    0x1bbe: ('PrimaryInit', 'sExecBlock entry; 1.0: PrimaryInit $20A4'),
    0x1cf6: ('SenseMap', 'read the 3 sense lines and map them to the monitor code (sRsrc id bits 2-0): '
                         'raw 5 -> fallback, raw 0 -> 7 (21" Color), 7 -> extended sense $14/$00/$30/$2D/other; '
                         "1.0: PrimaryInit's sense map $21DC"),
    0x1fea: ('LoadBoardTiming', 'sFindStruct/sGetBlock of board id $7E, the timing sBlock (new in 1.1)'),
    0x240e: ('SerialShiftOutReg', '1.0: SerialShiftOutReg $2880'),
    0x242a: ('RegTouchLoop', '1.0: RegTouchLoop $289E'),
    0x243c: ('XtdSense', 'extended sense; 1.0: sub_28b0 $28B0'),
    0x2528: ('WaitForVBlankCopy', '1.0: WaitForVBlankCopy $299C'),
    0x2598: ('RAMDACProbe', 'RAMDAC probe (new in 1.1): $06 into PCBR0, 0 into PCBR1, PCBR0 read back; '
                            '$06 = AC842A -> D1 = 1 (16 bpp sRsrcs, id bit 5)'),
    0x25f0: ('SRsrcPairs', 'sRsrc id pairs deleted by the fallback path; 1.0: MonitorSRsrcPairs $2A1C'),
    0x2628: ('VideoSRsrcList', '28 video sRsrc ids (bit 4 added for the 24-bit bank); 1.0: BankAsRsrcList $2A2C'),
    # SecondaryInit
    0x2690: ('SecondaryInit', 'sExecBlock entry; 1.0: SecondaryInit $2F50'),
    # Video driver
    0x28a2: ('VideoOpen', '1.0: VideoOpen $52EE'),
    0x2a90: ('VideoCtl', 'Control: dispatch on csCode; 1.0: VideoCtl $553C'),
    0x30f4: ('VideoClose', '1.0: VideoClose $5ACC'),
    0x3128: ('VideoStatus', 'Status: dispatch on csCode; 1.0: VideoStatus $5AF6'),
    0x32f0: ('GoIODone', '1.0: GoIODone $5CB0'),
    0x3300: ('ChkMode', '1.0: ChkMode $5CC0'),
    0x33c4: ('ChkPage', '1.0: ChkPage $5D3A'),
    0x33c8: ('WaitForVBlank', '1.0: WaitForVBlank $5D3E'),
    0x3436: ('JMFBSetDepth', '1.0: JMFBSetDepth $5DA8'),
    0x3684: ('LoadTiming', 'timing loader: reads the record of saveModeTbl for the depth: RAMDAC mode, regs '
                           '$7C/$04/$00/$A0, TV clock, 15 timing regs; 1.0: sub_5fd4 $5FD4'),
    0x3884: ('GrayScreen', '1.0: GrayScreen $6176'),
    0x39ae: ('GrayPatterns', '1.0: GrayPatterns $6288'),
    0x39c6: ('SerialShiftOut', '1.0: SerialShiftOut $629C'),
    0x39e2: ('VBLInterruptTask', 'slot VBL handler (lea by sub_304a); 1.0: VBLInterruptTask $62BA'),
    0x3a1e: ('XtdSense', '1.0: XtdSense $62F6'),
}
# code the descent does not reach from the entry points (the VBL handler is
# only lea'd; the others have no reference); listed as code anyway
EXTRA_SEEDS = [0x242a, 0x2528, 0x32c2, 0x39e2, 0x3a1e]
# Labels from the csCode jump tables (index -> name)
CTL_NAMES = ['Ctl_Reset', 'Ctl_KillIO', 'Ctl_SetMode', 'Ctl_SetEntries', 'Ctl_SetGamma',
             'Ctl_GrayPage', 'Ctl_SetGray', 'Ctl_SetInterrupt', 'Ctl_DirectSetEntries',
             'Ctl_SetDefaultMode']
STS_NAMES = ['Sts_DefaultErr', 'Sts_DefaultErr', 'Sts_GetMode', 'Sts_GetEntries', 'Sts_GetPages',
             'Sts_GetBaseAddr', 'Sts_GetGray', 'Sts_GetInterrupt', 'Sts_GetGamma',
             'Sts_GetDefaultMode', 'Sts_GetCurMode']
# 1.0 addresses of the handlers (extracted-source/VideoDriver.s)
OLD10 = {'Ctl_Reset': 0x558A, 'Ctl_KillIO': 0x5582, 'Ctl_SetMode': 0x55AC, 'Ctl_SetEntries': 0x562A,
         'Ctl_SetGamma': 0x57AA, 'Ctl_GrayPage': 0x58FA, 'Ctl_SetGray': 0x599A,
         'Ctl_SetInterrupt': 0x59B8, 'Ctl_DirectSetEntries': 0x5A88, 'Ctl_SetDefaultMode': 0x5A9C,
         'Sts_DefaultErr': 0x5B2E, 'Sts_GetMode': 0x5B3A, 'Sts_GetEntries': 0x5B48,
         'Sts_GetPages': 0x5BDC, 'Sts_GetBaseAddr': 0x5C0C, 'Sts_GetGray': 0x5C68,
         'Sts_GetInterrupt': 0x5C76, 'Sts_GetGamma': 0x5C7A, 'Sts_GetDefaultMode': 0x5C86,
         'Sts_GetCurMode': 0x5CAC}

TRAPS = {0xa01f: '_DisposePtr', 0xa023: '_DisposHandle', 0xa029: '_HLock', 0xa02a: '_HUnlock',
         0xa055: '_StripAddress', 0xa05d: '_SwapMMUMode', 0xa06e: '_SlotManager',
         0xa075: '_SIntInstall', 0xa076: '_SIntRemove', 0xa080: '_GetVideoDefault',
         0xa081: '_SetVideoDefault', 0xa1ad: '_Gestalt', 0xa346: '_GetOSTrapAddress',
         0xa440: '_ReserveMem,SYS', 0xa51e: '_NewPtrSys', 0xa71e: '_NewPtrSysClear',
         0xa722: '_NewHandle,SYS,CLEAR', 0xa746: '_GetToolBoxTrapAddress', 0xa11e: '_NewPtr',
         0xa31e: '_NewPtr,CLEAR', 0xa122: '_NewHandle', 0xa322: '_NewHandle,CLEAR',
         0xa522: '_NewHandle,SYS', 0xa02e: '_BlockMove', 0xa9ff: '_Debugger'}
SLOTSEL = {0x00: 'sReadByte', 0x01: 'sReadWord', 0x02: 'sReadLong', 0x03: 'sGetCString',
           0x05: 'sGetBlock', 0x06: 'sFindStruct', 0x07: 'sReadStruct', 0x08: 'sVersion',
           0x09: 'sSetsRsrcState', 0x0a: 'sInsertSRTRec', 0x0b: 'sGetsRsrc', 0x0c: 'sGetTypesRsrc',
           0x10: 'sReadInfo', 0x11: 'sReadPRAMRec', 0x12: 'sPutPRAMRec', 0x13: 'sReadFHeader',
           0x14: 'sNextSRsrc', 0x15: 'sNextTypeSRsrc', 0x16: 'sRsrcInfo', 0x17: 'sDisposePtr',
           0x18: 'sCkCardStat', 0x19: 'sReadDrvrName', 0x1a: 'sFindSRTRec', 0x1b: 'sFindDevBase',
           0x1c: 'sFindBigDevBase', 0x1d: 'sGetsRsrcPtr', 0x2d: 'sGetDriver', 0x31: 'sDeleteSRTRec'}

# ------------------------------------------------------------- ROM access --
d = b''
def u8(a): return d[a]
def u16(a): return int.from_bytes(d[a:a + 2], 'big')
def u32(a): return int.from_bytes(d[a:a + 4], 'big')
def s16(a): return struct.unpack('>h', d[a:a + 2])[0]
def off24(a):
    v = int.from_bytes(d[a + 1:a + 4], 'big')
    return a + (v - 0x1000000 if v & 0x800000 else v)
def raw24(a): return int.from_bytes(d[a + 1:a + 4], 'big')
def dirent(a):
    out = []
    while d[a] != 0xff:
        out.append((d[a], a, off24(a), raw24(a)))
        a += 4
    return out
def cstr(a):
    return d[a:d.index(b'\0', a)].decode('mac_roman')

md = capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_M68K_020)
md.detail = True

def dis1(a, end):
    w = u16(a)
    if w >> 12 == 0xA:
        return ('trap', a, 2, 'dc.w', '$%04x' % w, None)
    try:
        i = next(md.disasm(d[a:min(a + 12, end)], a))
    except StopIteration:
        return None
    return ('ins', a, i.size, i.mnemonic, i.op_str, i)

RE_PC = re.compile(r'\$([0-9a-f]+)\(pc')
RE_TGT = re.compile(r'\$([0-9a-f]+)$')

# ---------------------------------------------------------- disassembler --
class Region:
    def __init__(self, name, start, end, seeds, title):
        self.name, self.start, self.end, self.title = name, start, end, title
        self.ins = {}            # addr -> tuple from dis1
        self.labels = {}         # addr -> label
        self.lcomment = {}       # addr -> label comment
        self.icomment = {}       # addr -> extra comment
        self.tables = {}         # table addr -> [(entry addr, target)]
        self.datarefs = set()
        self.calls = set()
        self.special = {}        # addr -> (size, [lines]) emitted verbatim
        self.refs = {}           # target -> first referencing instruction
        self.walk(seeds)
        extra = [a for a in EXTRA_SEEDS if self.inside(a) and a not in self.ins]
        if extra:
            self.walk(extra)
            for a in extra:
                self.labels.setdefault(a, 'sub_%x' % a)
                how = ('only referenced by the instruction at $%04X' % self.refs[a]) if a in self.refs \
                    else 'no reference in this code'
                self.lcomment[a] = 'not reached from the entry points (%s)' % how

    def inside(self, a): return self.start <= a < self.end

    def walk(self, seeds):
        todo = list(seeds)
        while todo:
            a = todo.pop()
            while self.inside(a) and a not in self.ins:
                r = dis1(a, self.end)
                if r is None:
                    break
                self.ins[a] = r
                kind, _, size, mn, ops, i = r
                nxt = a + size
                if kind == 'trap':
                    a = nxt
                    continue
                isbr = any(o.type == capstone.m68k.M68K_OP_BR_DISP for o in i.operands)
                mpc = RE_PC.search(ops)
                if isbr or mpc:
                    t = int((RE_TGT.search(ops) if isbr else mpc).group(1), 16)
                    self.refs.setdefault(t, a)
                if isbr:
                    t = int(RE_TGT.search(ops).group(1), 16)
                    if mn.startswith('bsr'):
                        self.calls.add(t)
                    elif not mn.startswith('bra'):
                        self.labels.setdefault(t, 'L%x' % t)
                    else:
                        self.labels.setdefault(t, 'L%x' % t)
                    todo.append(t)
                    if mn.startswith('bra'):
                        break
                    a = nxt
                    continue
                m = RE_PC.search(ops)
                if mn in ('jsr', 'jmp') and m:
                    t = int(m.group(1), 16)
                    if '(pc, ' in ops:              # jump table
                        self.jumptable(t, todo)
                        break
                    if mn == 'jsr':
                        self.calls.add(t)
                        todo.append(t)
                    else:
                        self.labels.setdefault(t, 'L%x' % t)
                        todo.append(t)
                        break
                elif m:
                    t = int(m.group(1), 16)
                    if '(pc, ' not in ops:
                        self.datarefs.add(t)
                if mn in ('rts', 'rte', 'rtd', 'rtr', 'jmp'):
                    break
                a = nxt
        # unify labels
        for t in self.calls:
            self.labels[t] = 'sub_%x' % t
        for t in self.datarefs:
            if t not in self.ins and t not in self.labels:
                self.labels[t] = 'D_%x' % t

    def jumptable(self, T, todo):
        ents, lim, k = [], self.end, 0
        while T + 2 * k < lim:
            t = T + s16(T + 2 * k)
            if not self.inside(t) or t & 1 or t <= T + 2 * k:
                break
            ents.append((T + 2 * k, t))
            lim = min(lim, t)
            k += 1
        self.tables[T] = ents
        self.labels.setdefault(T, 'JumpTable_%x' % T)
        for _, t in ents:
            self.labels.setdefault(t, 'L%x' % t)
            todo.append(t)

    def name_table(self, T, names, prefix):
        for k, (ea, t) in enumerate(self.tables.get(T, [])):
            n = names[k] if k < len(names) else '%s%d' % (prefix, k)
            if self.labels.get(t, '').startswith(('L', 'sub_')):
                self.labels[t] = n
                if n in OLD10:
                    self.lcomment[t] = '1.0: %s $%04X' % (n, OLD10[n])
            self.icomment[ea] = 'csCode %d -> %s' % (k, self.labels[t])

    def comment_for(self, a, r):
        kind, _, size, mn, ops, i = r
        c = []
        if kind == 'trap':
            w = u16(a)
            nm = TRAPS.get(w, 'A-trap')
            if w == 0xa06e:
                p = self.prev(a)
                if p and p[3] == 'moveq' and p[4].endswith(', d0'):
                    sel = int(p[4].split(',')[0][2:], 16)
                    nm += ' selector=%s' % SLOTSEL.get(sel, '$%x' % sel)
            c.append(nm)
        else:
            m = RE_TGT.search(ops)
            if any(o.type == capstone.m68k.M68K_OP_BR_DISP for o in i.operands) and m:
                t = int(m.group(1), 16)
                c.append('-> ' + self.labels.get(t, '$%x' % t))
            else:
                m = RE_PC.search(ops)
                if m:
                    t = int(m.group(1), 16)
                    if t in self.labels:
                        c.append('-> ' + self.labels[t])
        if a in self.icomment:
            c.append(self.icomment[a])
        return '  ; ' + '  '.join(c) if c else ''

    def prev(self, a):
        for k in (2, 4, 6):
            r = self.ins.get(a - k)
            if r and r[2] == k:
                return r
        return None

    def render(self, header, extra_data=None):
        out = list(header)
        # coverage: code bytes, tables
        cover = {}
        for a, r in self.ins.items():
            cover[a] = ('ins', r[2])
        for T, ents in self.tables.items():
            for ea, t in ents:
                cover[ea] = ('tab', 2)
        a = self.start
        lab = self.labels
        while a < self.end:
            if a in lab:
                if a in NOTES and NOTES[a][1]:
                    out.append('* ' + NOTES[a][1])
                if a in self.lcomment and not (a in NOTES and self.lcomment[a] in NOTES[a][1]):
                    out.append('* ' + self.lcomment[a])
                out.append(lab[a] + ':')
            if a in self.special:
                size, ls = self.special[a]
                out.extend(ls)
                a += size
                continue
            if a in cover and cover[a][0] == 'ins':
                r = self.ins[a]
                size = r[2]
                hb = ' '.join('%02x' % x for x in d[a:a + size])
                line = '  %06x:  %-20s %-8s %s' % (a, hb, r[3], r[4])
                out.append((line.rstrip() + self.comment_for(a, r)))
                a += size
                continue
            if a in cover and cover[a][0] == 'tab':
                ea, t = a, a + 0
                T = max(x for x in self.tables if x <= a)
                t = T + s16(a)
                out.append('  %06x:  %-20s %-8s $%04X  ; %s' % (a, '%02x %02x' % (d[a], d[a + 1]), 'dc.w', u16(a), self.icomment.get(a, '-> ' + lab.get(t, '$%x' % t))))
                a += 2
                continue
            # data run up to next covered byte / label
            b = a + 1
            while b < self.end and b not in cover and b not in lab and b not in self.special and b - a < 8:
                b += 1
            out.extend(datalines(a, b, extra_data))
            a = b
        return out

def datalines(a, b, extra=None):
    chunk = d[a:b]
    hb = ' '.join('%02x' % x for x in chunk)
    asc = ''.join(chr(x) if 32 <= x < 127 else '.' for x in chunk)
    vals = ','.join('$%02X' % x for x in chunk)
    return ['  %06x:  %-20s %-8s %s  ; %s' % (a, hb, 'dc.b', vals, asc)]

# ------------------------------------------------------------ sResources --
SRSRC_IDS = {1: 'sRsrcType', 2: 'sRsrcName', 3: 'sRsrcIcon', 4: 'sRsrcDrvrDir', 5: 'sRsrcLoadDir',
             6: 'sRsrcBootRec', 7: 'sRsrcFlags', 8: 'sRsrcHWDevId', 10: 'MinorBaseOS',
             11: 'MinorLength', 12: 'MajorBaseOS', 13: 'MajorLength', 15: 'sRsrccicn',
             16: 'sRsrcicl8', 17: 'sRsrcicl4', 0x40: 'sGammaDir', 0x41: 'sRsrcVidNames'}
BOARD_IDS = {1: 'sRsrcType', 2: 'sRsrcName', 0x20: 'BoardId', 0x21: 'PRAMInitData',
             0x22: 'PrimaryInit', 0x23: 'TimeOutConst', 0x24: 'VendorInfo', 0x25: 'BoardFlags',
             0x26: 'SecondaryInit'}
VENDOR = {1: 'VendorId', 2: 'SerialNum', 3: 'RevLevel', 4: 'PartNum', 5: 'Date'}
IMMEDIATE = {7, 8, 0x20}
MONITOR = ['PAL 640', 'Portrait', '12"', 'Two-Page', 'NTSC 512', '16" Color', '13"', '21" Color']
DEPTHS = [1, 2, 4, 8, 16, 32]

def clock(b):
    nib = {x >> 4: x & 15 for x in b}
    N = nib[0] | nib[1] << 4 | nib[2] << 8 | nib[3] << 12
    R = nib[4] | nib[5] << 4 | nib[6] << 8
    P = nib[9]
    return N, R, P, 20.0 * N / R / (1 << P)

def fmtclock(a):
    b = d[a:a + 16]
    N, R, P, f = clock(b)
    return '%s   N=%d R=%d P=%d  PCLK=%.3f MHz' % (' '.join('%02x' % x for x in b), N, R, P, f)

def sresources(path):
    L = []
    fb = len(d) - 20
    top = off24(fb)          # fhDirOffset is a 24-bit offset in the low 3 bytes
    flen, crc = u32(fb + 4), u32(fb + 8)
    L += ['sResources of the 8*24 GC declaration ROM 341-0266 ("MDC 8*24 GC 1.1")',
          'Written by control-panel/rom11_dasm.py from the ROM image; decoded, not annotated.',
          'Offsets are ROM byte offsets (ByteLanes $E1: one ROM byte per NuBus long).',
          'Video sRsrc id bits and the monitor names: HOST_CARD_PROTOCOL.md section 10.10.',
          '', '== Format block ($%04X)' % fb,
          '  DirectoryOffset  $%06X -> directory at $%04X' % (raw24(fb), top),
          '  Length           $%08X' % flen,
          '  CRC              $%08X' % crc,
          '  RevisionLevel    %d' % d[fb + 12], '  Format           %d' % d[fb + 13],
          '  TestPattern      $%08X' % u32(fb + 14), '  Reserved         $%02X' % d[fb + 18],
          '  ByteLanes        $%02X' % d[fb + 19], '']
    top_ents = dirent(top)
    L.append('== sResource directory ($%04X, %d entries)' % (top, len(top_ents)))
    for i, ea, t, raw in top_ents:
        nm = ''
        for j, _, u, _ in dirent(t):
            if j == 2: nm = cstr(u)
        L.append('  $%02X -> $%04X  %s' % (i, t, nm))
    L.append('')
    # board
    i, ea, board, raw = top_ents[0]
    L.append('== Board sRsrc $%02X ($%04X)' % (i, board))
    timing_dir = None
    for j, ea, u, raw in dirent(board):
        n = BOARD_IDS.get(j, 'vendor-specific')
        if j == 1:
            v = d[u:u + 8]
            L.append('  $%02X %-16s $%04X  cat %d type %d DrSW %d DrHW %d' % ((j, n, u) + struct.unpack('>4H', v)))
        elif j == 2:
            L.append("  $%02X %-16s $%04X  '%s'" % (j, n, u, cstr(u)))
        elif j in IMMEDIATE:
            L.append('  $%02X %-16s immediate $%06X' % (j, n, raw))
        elif j in (0x22, 0x26):
            ln, rev, cpu = u32(u), d[u + 4], d[u + 5]
            code = u + 8 + u32(u + 8)
            L.append('  $%02X %-16s $%04X  sExecBlock len $%X rev %d cpu %d, code at $%04X (%s.s)'
                     % (j, n, u, ln, rev, cpu, code, n))
        elif j == 0x24:
            L.append('  $%02X %-16s $%04X' % (j, n, u))
            for k, _, uu, _ in dirent(u):
                L.append("        %-10s '%s'" % (VENDOR.get(k, '$%02X' % k), cstr(uu)))
        elif j == 0x41:
            L.append('  $%02X %-16s $%04X  monitor-name records (sBlock: length, $02, monitor code, name)' % (j, 'vendor: names', u))
            for k, _, uu, _ in dirent(u):
                L.append("        $%02X -> $%04X  len $%02X  $%02X code %2d  '%s'"
                         % (k, uu, u32(uu), d[uu + 4], d[uu + 5], cstr(uu + 6)))
        elif j == 0x7e:
            timing_dir = u
            L.append('  $%02X %-16s $%04X  timing sBlocks, one per video sRsrc id (decoded below)' % (j, 'vendor: timing', u))
        else:
            L.append('  $%02X %-16s offset $%06X -> $%04X, bytes there: %s' % (j, n, raw, u, d[u:u + 8].hex(' ')))
    L.append('')
    # video sRsrcs
    seenvp = {}
    L.append('== Video sRsrcs')
    L.append('  id bits (10.10): 2-0 monitor, 3 other TV size, 4 24-bit bank, 5 16 bpp, 6 unconvolved TV')
    drvr_dir = None
    for i, ea, t, raw in top_ents[1:]:
        ents = dirent(t)
        bits = '%s%s%s%s%s' % (MONITOR[i & 7], ' +TVsize' if i & 8 else '', ' bank24' if i & 0x10 else '',
                               ' 16bpp' if i & 0x20 else '', ' unconv' if i & 0x40 else '')
        L.append('')
        L.append('-- sRsrc $%02X ($%04X)  [%s]' % (i, t, bits))
        for j, ea2, u, raw2 in ents:
            n = SRSRC_IDS.get(j, 'mode $%02X' % j if j >= 0x80 else 'id $%02X' % j)
            if j == 1:
                L.append('   $%02X %-13s cat %d type %d DrSW %d DrHW $%X' % ((j, n) + struct.unpack('>4H', d[u:u + 8])))
            elif j == 2:
                L.append("   $%02X %-13s '%s'" % (j, n, cstr(u)))
            elif j == 4:
                drvr_dir = u
                L.append('   $%02X %-13s $%04X' % (j, n, u))
            elif j in IMMEDIATE:
                L.append('   $%02X %-13s $%X' % (j, n, raw2))
            elif j in (10, 11, 12, 13):
                L.append('   $%02X %-13s $%04X -> $%08X' % (j, n, u, u32(u)))
            elif j == 0x40:
                g = ['$%02X:%s' % (k, repr(cstr(uu + 6))) for k, _, uu, _ in dirent(u)]
                L.append('   $%02X %-13s $%04X  %s' % (j, n, u, ', '.join(g)))
            elif j >= 0x80:
                md_ = {k: (uu, rr) for k, _, uu, rr in dirent(u)}
                vp = md_[1][0]
                (ln, base, rb, top_, lft, bot, rgt, ver, pkt, pks, hr, vr, pxt, psz, cc, cs,
                 pl) = struct.unpack('>IIHhhhhhhIIIhhhhI', d[vp:vp + 46])
                pages = md_.get(3, (0, 0))[1] & 0xffff
                dev = md_.get(4, (0, 0))[1] & 0xffff
                L.append('   $%02X %-13s $%04X  pages %d devType %d  VPBlock $%04X: base $%X rowBytes %d '
                         'bounds (%d,%d,%d,%d) %dx%d  %d bpp (type %d, %d x %d)  res %g/%g dpi%s'
                         % (j, n, u, pages, dev, vp, base, rb, top_, lft, bot, rgt, rgt - lft, bot - top_,
                            psz, pxt, cc, cs, hr / 65536, vr / 65536,
                            '' if ln == 0x2e else ' (len $%X)' % ln))
            else:
                L.append('   $%02X %-13s $%04X' % (j, n, u))
    L.append('')
    if drvr_dir is not None:
        for j, _, u, _ in dirent(drvr_dir):
            L.append('== Driver directory $%04X: $%02X -> $%04X  DRVR sBlock length $%X (VideoDriver.s)'
                     % (drvr_dir, j, u, u32(u)))
    L.append('')
    # timing sBlocks
    L.append('== Board id $7E: timing sBlocks')
    L.append('  header: length, pages (12 bytes: 6 for 32-bit, 6 for 24-bit addressing), 6 rowBytes,')
    L.append('  vRes, 16 DP8531 clock writes (byte = register<<4 | nibble; N = nibbles 0-3,')
    L.append('  R = 4-6, P = 9; PCLK = 20 MHz * N / R / 2^P); then one 40-byte record per depth')
    L.append('  (1, 2, 4, 8, 16, 32 bpp), with 6 more bytes after the first; TV blocks end with a')
    L.append('  second clock (direct modes).  Record: L0 (RAMDAC mode in the high byte), L1 (reg $7C),')
    L.append('  L2 (reg $04, 8 bits), L3 (reg $00, 20 bits), L4 (reg $A0, 12 bits), 15 timing words.')
    users = {}
    for k, _, u, _ in dirent(timing_dir):
        users.setdefault(u, []).append(k)
    for t in sorted(users):
        ln = u32(t)
        ids = users[t]
        names = sorted({cstr(uu + 6) for k, _, uu, _ in dirent(board_entry(board, 0x41)) if k in ids})
        L.append('')
        L.append('-- $%04X  len $%X  used by %s  (%s)' % (t, ln, ' '.join('$%02X' % x for x in ids), '; '.join(names)))
        L.append('   pages  %s' % d[t + 4:t + 16].hex(' '))
        L.append('   rowBytes %s   vRes %d' % (' '.join(str(x) for x in struct.unpack('>6H', d[t + 16:t + 28])), u16(t + 28)))
        L.append('   clock  ' + fmtclock(t + 30))
        a, k = t + 46, 0
        while a + 40 <= t + ln:
            if t + ln - a == 16:
                break
            w = struct.unpack('>5H', d[a:a + 10])
            r = struct.unpack('>15H', d[a + 10:a + 40])
            L.append('   %2d bpp L0 $%04X L1 $%X L2 $%02X L3 $%04X L4 $%03X  timing %s'
                     % ((DEPTHS[k],) + w + (' '.join('%03x' % x for x in r),)))
            a += 40
            if k == 0:
                L.append('          +6 bytes after record 0: %s' % ' '.join('$%X' % x for x in struct.unpack('>3H', d[a:a + 6])))
                a += 6
            k += 1
        if t + ln - a == 16:
            L.append('   clock2 ' + fmtclock(a))
            a += 16
        if a != t + ln:
            L.append('   (%d bytes left over)' % (t + ln - a))
    return L

def board_entry(board, ident):
    for j, _, u, _ in dirent(board):
        if j == ident:
            return u

def apply_notes(R):
    for a, (nm, c) in NOTES.items():
        if R.inside(a):
            if a in R.ins or a in R.labels:
                R.labels[a] = nm
            else:
                print('warning: NOTES $%04X (%s) is not an instruction or label' % (a, nm))

# --------------------------------------------------------------- headers --
def header(title, lines):
    h = ['* ' + '=' * 74,
         '*  %s' % title,
         '*  Macintosh Display Card 8*24 GC  --  later declaration ROM 341-0266',
         '*  ("MDC 8*24 GC 1.1", 16-Sep-91, 64 KB, data $0000-$5141).',
         '*  Generated by control-panel/rom11_dasm.py: capstone 5 (68020), recursive',
         '*  descent from the entry points, branches, bsr/jsr and jump tables; bytes not',
         '*  reached as code are listed as dc.b.  Byte columns are the ROM bytes.',
         '*  Not annotated beyond labels, A-trap / Slot Manager names and the few',
         '*  routines matched to the 1.0 listings ("1.0: name $addr", ROM 341-0812).',
         '* ' + '=' * 74, '*']
    return h + ['*  ' + x for x in lines] + ['*']

# ----------------------------------------------------------------- check --
LINE = re.compile(r'^  ([0-9a-f]{6}):  (.*)$')
def listed_bytes(ln):
    """(addr, bytes) of a listing line, or None."""
    m = LINE.match(ln)
    if not m:
        return None
    hb = []
    for tok in m.group(2).split(' '):
        if not re.fullmatch('[0-9a-f]{2}', tok):
            break
        hb.append(tok)
    return int(m.group(1), 16), bytes.fromhex(''.join(hb))

def check(paths, ranges):
    """every listed byte column equals the ROM, and the lines of each file
    cover their range [start, end) without gaps or overlaps"""
    n = bad = 0
    for p, (start, end) in zip(paths, ranges):
        prev = start
        for ln in open(p):
            r = listed_bytes(ln.rstrip('\n'))
            if not r:
                continue
            a, b = r
            n += 1
            if not b or d[a:a + len(b)] != b:
                bad += 1
                print('MISMATCH %s: %s' % (p, ln.rstrip()))
            if a != prev:
                bad += 1
                print('GAP/OVERLAP %s at %06x (expected %06x)' % (p, a, prev))
            prev = a + len(b)
        if prev != end:
            bad += 1
            print('%s ends at %06x, region ends at %06x' % (p, prev, end))
    return n, bad

# ------------------------------------------------------------------ main --
def main():
    global d
    rom, outdir = sys.argv[1], sys.argv[2]
    d = open(rom, 'rb').read()
    os.makedirs(outdir, exist_ok=True)
    fb = len(d) - 20
    top = off24(fb)
    board = dirent(top)[0][2]
    pi = board_entry(board, 0x22)
    si = board_entry(board, 0x26)
    pi_code, si_code = pi + 8 + u32(pi + 8), si + 8 + u32(si + 8)
    # driver: from the first video sRsrc's driver directory
    vid = dirent(top)[1][2]
    ddir = [u for j, _, u, _ in dirent(vid) if j == 4][0]
    dblk = dirent(ddir)[0][2]
    dlen = u32(dblk)
    dh = dblk + 4
    drv_entries = [dh + u16(dh + o) for o in (8, 10, 12, 14, 16) if u16(dh + o)]

    files, ranges = [], []
    # PrimaryInit
    R = Region('PrimaryInit', pi_code, pi + u32(pi), [pi_code], 'PrimaryInit')
    apply_notes(R)
    hdr = header('PrimaryInit', [
        'sExecBlock at $%04X (board sRsrc id $22): length $%X, rev %d, cpu %d; code $%04X-$%04X.'
        % (pi, u32(pi), d[pi + 4], d[pi + 5], pi_code, pi + u32(pi)),
        'Entry: A0 = SEBlock (seSlot at +0).'])
    files.append(('PrimaryInit.s', R.render(hdr)))
    ranges.append((R.start, R.end))
    # SecondaryInit
    R = Region('SecondaryInit', si_code, si + u32(si), [si_code], 'SecondaryInit')
    apply_notes(R)
    hdr = header('SecondaryInit', [
        'sExecBlock at $%04X (board sRsrc id $26): length $%X, rev %d, cpu %d; code $%04X-$%04X.'
        % (si, u32(si), d[si + 4], d[si + 5], si_code, si + u32(si)),
        'Entry: A0 = SEBlock.'])
    files.append(('SecondaryInit.s', R.render(hdr)))
    ranges.append((R.start, R.end))
    # Video driver
    R = Region('VideoDriver', dblk, dblk + dlen, drv_entries, 'VideoDriver')
    ctl, sts = dh + u16(dh + 12), dh + u16(dh + 14)
    for T in sorted(R.tables):
        if ctl < T < sts:
            R.labels[T] = 'ControlJumpTable'; R.name_table(T, CTL_NAMES, 'Ctl_')
        elif T > sts:
            R.labels[T] = 'StatusJumpTable'; R.name_table(T, STS_NAMES, 'Sts_')
    apply_notes(R)
    R.labels[dh] = 'DRVRHeader'
    names = ['drvrFlags', 'drvrDelay', 'drvrEMask', 'drvrMenu', 'drvrOpen', 'drvrPrime',
             'drvrCtl', 'drvrStatus', 'drvrClose']
    hdr = header('VideoDriver  (%s)' % d[dh + 19:dh + 19 + d[dh + 18]].decode('mac_roman'), [
        'DRVR sBlock at $%04X (driver directory $%04X, id $02 sMacOS68020), length $%X,'
        % (dblk, ddir, dlen),
        'driver header at $%04X: flags $%04X, Open $%04X, Prime %s, Control $%04X, Status $%04X, Close $%04X.'
        % (dh, u16(dh), dh + u16(dh + 8), '-' if not u16(dh + 10) else '$%04X' % (dh + u16(dh + 10)),
           ctl, sts, dh + u16(dh + 16)),
        'Control/Status dispatch on csCode through the word tables ControlJumpTable /',
        'StatusJumpTable (csCode names as in Video.h; the 1.0 driver has the same calls).'])
    hl = []
    for k in range(9):
        x = dh + 2 * k
        hl.append('  %06x:  %-20s %-8s $%04X  ; %s%s' % (x, '%02x %02x' % (d[x], d[x + 1]), 'dc.w', u16(x), names[k],
                  (' -> %s' % R.labels.get(dh + u16(x), '$%04X' % (dh + u16(x)))) if k >= 4 and u16(x) else ''))
    nl = d[dh + 18]
    x = dh + 18
    hl.append("  %06x:  %-20s %-8s $%02X  ; drvrName length" % (x, '%02x' % nl, 'dc.b', nl))
    R.special[dh] = (19, hl)
    R.special[dblk] = (4, ['  %06x:  %-20s %-8s $%08X  ; sBlock length' % (dblk, d[dblk:dblk + 4].hex(' '), 'dc.l', dlen)])
    out = R.render(hdr)
    files.append(('VideoDriver.s', out))
    ranges.append((R.start, R.end))
    # sResources
    paths = []
    for fn, ls in files:
        p = os.path.join(outdir, fn)
        open(p, 'w').write('\n'.join(ls) + '\n')
        paths.append(p)
    open(os.path.join(outdir, 'sResources.txt'), 'w').write('\n'.join(sresources(rom)) + '\n')
    n, bad = check(paths, ranges)
    print('check: %d listing lines with bytes, %d mismatches/gaps' % (n, bad))
    return 1 if bad else 0

if __name__ == '__main__':
    sys.exit(main())
