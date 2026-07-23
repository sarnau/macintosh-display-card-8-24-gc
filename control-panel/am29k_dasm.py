#!/usr/bin/env python3
"""am29k_dasm.py -- AMD Am29000 disassembler.

Opcode table and instruction encoding ported faithfully from MAME's
am29dasm.cpp (BSD-3).  Am29000 instructions are 32-bit, big-endian:

    [ OP:8 | RC:8 | RA:8 | RB/I8:8 ]

Six operand formats (type1..type6); jumps are PC-relative (signed 16-bit word
displacement) unless the M bit selects an absolute word target.

Usage:  python3 am29k_dasm.py text.bin [base_vaddr_hex] [--labels]
"""
import sys, struct, os

def spr(n):
    return {0:'VAB',1:'OPS',2:'CPS',3:'CFG',4:'CHA',5:'CHD',6:'CHC',7:'RBP',
            8:'TMC',9:'TMR',10:'PC0',11:'PC1',12:'PC2',13:'MMU',14:'LRU',
            128:'IPC',129:'IPA',130:'IPB',131:'Q',132:'ALU',133:'BP',134:'FC',
            135:'CR',160:'FPE',161:'INTE',162:'FPS',164:'EXOP'}.get(n, 'spr%d'%n)

def reg(n):                              # 0-127 global, 128-255 local
    return 'gr%d'%n if n < 128 else 'lr%d'%(n-128)

def decode(op, pc):
    """Return (mnemonic, operand_str, target_or_None). pc = byte address."""
    RC=(op>>16)&0xff; RA=(op>>8)&0xff; RB=op&0xff; I8=op&0xff
    SA=(op>>8)&0xff; I16=((op>>8)&0xff00)|(op&0xff); VN=(op>>16)&0xff
    CE=(op>>23)&1; CNTL=(op>>16)&0x7f; M=(op>>24)&1
    IJMP=(I16<<2); SJMP=((I16-0x10000 if I16&0x8000 else I16)<<2)
    o=op>>24
    t1=(f"{reg(RC)}, {reg(RA)}, ${I8:02x}" if M else f"{reg(RC)}, {reg(RA)}, {reg(RB)}")
    t2=f"{reg(RC)}, {reg(RA)}, {reg(RB)}"
    t3=f"{reg(RA)}, ${I16:04x}"
    t4=(f"{reg(RA)}, ${IJMP:05x}", IJMP) if M else (f"{reg(RA)}, ${pc+SJMP:05x}", pc+SJMP)
    t5=(f"trap{VN}, {reg(RA)}, ${I8:02x}" if M else f"trap{VN}, {reg(RA)}, {reg(RB)}")
    t6=(f"{CE}, {CNTL:x}, {reg(RA)}, ${I8:02x}" if M else f"{CE}, {CNTL:x}, {reg(RA)}, {reg(RB)}")
    T={0x01:('constn',t3),0x02:('consth',t3),0x03:('const',t3)}
    if o in T: return (*T[o], None)
    tab1={0x0a:'exbyte',0x0c:'inbyte',0x10:'adds',0x12:'addu',0x14:'add',
          0x18:'addcs',0x1a:'addcu',0x1c:'addc',0x20:'subs',0x22:'subu',0x24:'sub',
          0x28:'subcs',0x2a:'subcu',0x2c:'subc',0x2e:'cpbyte',0x30:'subrs',0x32:'subru',
          0x34:'subr',0x38:'subrcs',0x3a:'subrcu',0x3c:'subrc',0x40:'cplt',0x42:'cpltu',
          0x44:'cple',0x46:'cpleu',0x48:'cpgt',0x4a:'cpgtu',0x4c:'cpge',0x4e:'cpgeu',
          0x60:'cpeq',0x62:'cpneq',0x64:'mul',0x66:'mull',0x6a:'div',0x6c:'divl',
          0x6e:'divrem',0x74:'mulu',0x78:'inhw',0x7a:'extract',0x7c:'exhw',
          0x80:'sll',0x82:'srl',0x86:'sra',0x90:'and',0x92:'or',0x94:'xor',
          0x96:'xnor',0x98:'nor',0x9a:'nand',0x9c:'andn'}
    if (o&~1) in tab1 and o not in (0x7e,): return (tab1[o&~1], t1, None)
    if o==0x7e: return ('exhws', t1, None)
    ls={0x06:'loadl',0x0e:'storel',0x16:'load',0x1e:'store',0x26:'loadset',
        0x36:'loadm',0x3e:'storem'}
    if (o&~1) in ls: return (ls[o&~1], t6, None)
    asrt={0x50:'aslt',0x52:'asltu',0x54:'asle',0x56:'asleu',0x58:'asgt',0x5a:'asgtu',
          0x5c:'asge',0x5e:'asgeu',0x70:'aseq',0x72:'asneq'}
    if (o&~1) in asrt: return (asrt[o&~1], t5, None)
    if o==0x04: return ('mtsrim', f"{spr(SA)}, ${I16:04x}", None)
    if o==0x08: return ('clz', f"{reg(RC)}, {reg(RB)}", None)
    if o==0x09: return ('clz', f"{reg(RC)}, ${I8:02x}", None)
    if o==0x68: return ('div0', f"{reg(RC)}, {reg(RB)}", None)
    if o==0x69: return ('div0', f"{reg(RC)}, ${I8:02x}", None)
    if o==0x88: return ('iret','',None)
    if o==0x89: return ('halt','',None)
    if o==0x8c: return ('iretinv','',None)
    if o==0x9e: return ('setip', t2, None)
    if o==0x9f: return ('inv','',None)
    if o==0xa0: return ('jmp', f"${pc+SJMP:05x}", pc+SJMP)
    if o==0xa1: return ('jmp', f"${IJMP:05x}", IJMP)
    if o in (0xa4,0xa5): return ('jmpf', t4[0], t4[1])
    if o in (0xa8,0xa9): return ('call', t4[0], t4[1])
    if o in (0xac,0xad): return ('jmpt', t4[0], t4[1])
    if o in (0xb4,0xb5): return ('jmpfdec', t4[0], t4[1])
    if o==0xb6: return ('mftlb', f"{reg(RC)}, {reg(RA)}", None)
    if o==0xbe: return ('mttlb', f"{reg(RA)}, {reg(RB)}", None)
    if o==0xc0: return ('jmpi', reg(RB), None)
    if o==0xc4: return ('jmpfi', f"{reg(RA)}, {reg(RB)}", None)
    if o==0xc6: return ('mfsr', f"{reg(RC)}, {spr(SA)}", None)
    if o==0xc8: return ('calli', f"{reg(RA)}, {reg(RB)}", None)
    if o==0xcc: return ('jmpti', f"{reg(RA)}, {reg(RB)}", None)
    if o==0xce: return ('mtsr', f"{spr(SA)}, {reg(RB)}", None)
    if o==0xd7: return ('emulate', t5, None)
    if o==0xde: return ('multm', t2, None)
    if o==0xdf: return ('multmu', t2, None)
    if o==0xe0: return ('multiply', t2, None)
    if o==0xe1: return ('divide', t2, None)
    return ('.word', f"${op:08x}", None)

def disasm(data, base=0, labels=False, syms=None):
    n=len(data)//4
    syms=syms or set()
    # pass 1: collect branch/call targets for labels
    lab={}
    for s in syms:                            # symbol-table entries = function starts
        if base <= s < base+n*4: lab[s]='sub_%05x'%s
    if labels:
        for i in range(n):
            op=struct.unpack('>I', data[i*4:i*4+4])[0]
            mn,ops,tgt=decode(op, base+i*4)
            if tgt is not None and 0<=tgt-base<n*4 and (tgt&3)==0:
                lab.setdefault(tgt, 'L_%05x'%tgt)
    BR={'jmp','jmpf','jmpt','jmpfdec','call','jmpi','jmpfi','calli','jmpti','iret','iretinv'}
    out=[]; delay=False
    for i in range(n):
        a=base+i*4
        op=struct.unpack('>I', data[i*4:i*4+4])[0]
        mn,ops,tgt=decode(op, a)
        if labels and a in lab: out.append(lab[a]+':')
        ann=''
        if labels and tgt is not None and tgt in lab: ann='   ; -> '+lab[tgt]
        if delay: ann=(ann+'   ; [delay slot]') if ann else '   ; [delay slot]'
        out.append('  %05x:  %08x  %-8s %-24s%s'%(a, op, mn, ops, ann))
        delay = mn in BR                       # Am29000 executes 1 instr after a branch
    return '\n'.join(out)

if __name__=='__main__':
    path=sys.argv[1]
    base=int(sys.argv[2],16) if len(sys.argv)>2 and not sys.argv[2].startswith('--') else 0
    lab='--labels' in sys.argv
    syms=set()
    if '--syms' in sys.argv:                  # symbols.txt: "<section>\t<0xaddr>" per line
        secfilter=os.path.basename(path).split('.')[0].lstrip('.').lower()  # e.g. "text"
        for ln in open(sys.argv[sys.argv.index('--syms')+1]):
            p=ln.split()
            if len(p)==2 and p[0].lstrip('.').lower()==secfilter:
                syms.add(int(p[1],16)+base)
    print(disasm(open(path,'rb').read(), base, lab, syms))
