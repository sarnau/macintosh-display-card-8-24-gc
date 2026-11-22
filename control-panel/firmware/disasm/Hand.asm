* ==================================================================
*  ACEF_1 "Runtime" -- Hand  (Am29000, base $2000000)   *** UNMASKED ***
* ==================================================================
*  Disassembled with ../../am29k_dasm.py from Hand.unmasked.bin, which is
*  Hand.bin with its second mask removed by ../../unmask_runtime.py (see
*  ../README.md, "The second mask").  Before unmasking, this section decoded
*  as noise (random SPR numbers, jumps out of the section); after it,
*  all 351 direct jumps and calls land inside the section, every mfsr has
*  RB = 0, every mtsr has RC = 0, every iret has zero operands, and all SPR
*  numbers are architectural (0-14, 128-135).
*
*  What the code is: the Am29000 side of the 8.24 GC runtime -- trap / interrupt
*  entry and exit paths ($2000000 ...), a mailbox poll of the host interface
*  block ($4C007000, compared against $73333337 = ASCII 's337', the same
*  signature DRVR.s's cs51 writes), a table walker at $2001C2C used by most
*  handlers, and the reset / context save-restore code near $2002650-$2002D14.
*  The first instruction (jmp $2002808) is the entry point.  Delay slots are
*  marked.  'aseq trap64,gr1,gr1' is the usual Am29000 NOP.
* ==================================================================
* ------------------------------------------------------------------
*  READING GUIDE (all inferred from the code; names are mine)
* ------------------------------------------------------------------
*  Conventions seen throughout
*    gr1/gr126/gr127/lr1..   AMD register-stack convention (gr1 = frame,
*                            gr126/gr127 = spill bounds; vectors 64/65 below)
*    gr64                    kernel FLAGS word, loaded at init from
*                            PublicIn+$18 ($4C006418) = the unit flags
*                            DRVR.s's SetFeatureFlags/PostLoadPoke publish
*    gr65                    program break / heap pointer (service $101)
*    gr69 / gr70             return address for internal 'call gr69,..'
*                            (return = 'jmpi gr69'); gr70 for the service stubs
*    gr77                    REASON CODE handed to the fatal-trap reporter
*                            at $2002808 (table below)
*    gr82,gr86,gr87,gr88,gr89,gr90   handler copies of OPS,CHA,CHD,PC0,PC1,CHC
*    gr96, gr121             service result / service number (see $20011E8)
*    gr0 with IPA/IPC set    INDIRECT register access: the four 'or gr0,..'
*                            instructions are intentional, not noise
*    'aseq trap64,gr1,gr1'   the usual Am29000 NOP (assert that never fires)
*    CPS $047F / $007F       interrupts+traps disabled / enabled-ish sections
*
*  TRAP VECTOR TABLE (built by Boot at VAB = $4C000000; entry n at +4n)
*     0 illegal opcode ........ $2000000   1 unaligned access .... $2000008
*     2 out of range .......... $2000908   3 no coprocessor ...... $2000920
*     4 coprocessor exception . $2000928   5 protection violation . $2000940
*     6 instr access exception  $2000644   7 data access exception  $2000358
*     8,10 instr TLB miss ..... $2000670   9,11 data TLB miss .... $2000714
*    12 instr TLB prot viol ... $20008A0  13 data TLB prot viol ... $20008A8
*    14 timer ................. $2000960  15 trace ................ $2000A24
*    16 INTR0 $2000B08  17 INTR1 $2000B48  18 INTR2 $2000B98  19 INTR3 $2001064
*    20 TRAP0 $2001144  21 TRAP1 $2001164  22..63 default ........ $2001D08
*    64 register spill ....... $2001184   65 register fill ........ $20011B8
*         (Antelope's loader patches 293 'asgeu 64,gr1,gr126' and 454 'asleu 65,lr2,gr127')
*    66 SERVICE CALL (jump table) $20011E8   67 default
*    68 assertion / breakpoint $2000AE8   69 SERVICE CALL (HIF-style: 'asneq 69,gr1,gr1')
*                                         $2001A70
*    (Boot's loop 'jmpfdec' runs N+2 times, so there are 42 defaults, 22..63.)
*
*  REASON CODES (gr77 -> $2002808 -> mailbox word $4C007004)
*    8F no-coprocessor   90 data access        91 vector 0        92 unaligned
*    93 out-of-range     95 instr access/TLB   96..99 INTR0..3 with no handler
*    9A TRAP0  9B TRAP1  9C protection         9D coprocessor     9E,A1 pager
*    9F trace (unexpected)   A0 vector 68      A3 unknown vector  A5 stack bound
*    A6 TLB miss outside any mapped region     B4,B5 report/trace overflow
*
*  CARD ADDRESS MAP USED BY THIS CODE (inferred)
*    $4C000000 Vec   trap vector table (VAB)
*    $4C002500 PrivNZ service-call jump table (pointers to $0200xxxx)
*    $4C002810..$4C002E48  software TLB / page-table state (32-bucket hash at
*                    $4C002818, 20-byte entries from $4C002898, tables at
*                    $4C002CA8 / $4C002D78 / $4C002E48)
*    $4C003090       register save area of the data-access handler
*    $4C003168/316C  memory-region table: count, then 12-byte entries
*                    (base, size, aux); used by $2001C2C and the TLB handlers
*    $4C006400 PublicIn (host -> card): +00 boot poke $42005300, +10 address
*                    limit, +18 flags (-> gr64), +3C timer value
*    $4C00617C..$4C00618C  INTR0..INTR3 handler/enable words, pending flag
*    $4C0061BC..$4C0061CC  trace / single-step state;  $4C006748 fatal-trap
*                    register dump;  $4C006800 PublicOu (card -> host):
*                    +28 board config, +30/+34 timer tick counters
*    $4C006A5C,6A60,6A7C  last reason, trace count, PC1 trace buffer
*    $4C007000 HifComm mailbox:  +00 signature ($96666669 card posts,
*                    $73333337 's337' host acknowledges), +04 reason/status,
*                    +08 host argument, +10..+4F register dump
*    $4C007300 VidComm video command block (+04 ack, +08.. params, +1C command)
*    $44000000..$440000A0 card control registers (HW-ID bits +44/+48/+4C,
*                    interrupt acks +50/+54/+58, status +64/+68/+70, +7C/+80)
*    $46000000       interrupt mask/pending word;  $40003400 register spill area
*
*  HOST-WRITTEN FIELDS OF PublicIn ($4C006400), cross-checked with DRVR.s
*  (see ../../HOST_CARD_PROTOCOL.md):
*    +00 $42005300 boot go (Boot polls it)   +04 entry of the loaded program:
*    the init code ends with PC1 <- [+04], iretinv   +08 top of card DRAM (heap
*    end, service $20012AC)   +10 kernel heap pointer (written here by init)
*    +18 host flags -> gr64 (bit 11 = mailbox disabled, bit 20 = DRAM > $0D000000)
*    +20/24/28/2C/30 start/end/text/data/bss of the loaded program (init copies
*    the data section)   +40 region start (stack = +40 - $10000)
*    +3D4 RESTART REQUEST (tested by $2000C14 -> $2001FFC; doorbell = card
*    $44000050)   VidComm +18 holds 'WY1`' ($57593160) = "Am29000 present"
* ------------------------------------------------------------------
*
*  $2000000  VECTOR 0 / ENTRY: jmp $2002808 with reason $91 (illegal opcode),
*            i.e. the fatal-trap reporter.  Normal start-up is Boot -> $2001FFC.
  2000000:  a00a0002  jmp      $2002808                   ; -> L_2002808
  2000004:  03004d91  const    gr77, $0091                ; [delay slot]
* ==================================================================
*  VECTOR 1 -- UNALIGNED ACCESS: emulates unaligned word loads/stores
*  (and load/store-multiple) with two halfword accesses, calling the
*  address-range check $2001C2C per word; uses CHA/CHD/CHC, CR, IPA/IPC
*  (indirect register access, hence the 'or gr0,..' lines) and returns
*  with iret via $20000D0.  Failures end in reason $92.
* ==================================================================
L_2000008:
  2000008:  c6590b00  mfsr     gr89, PC1               
  200000c:  c6580a00  mfsr     gr88, PC0               
  2000010:  c6520100  mfsr     gr82, OPS               
  2000014:  0400027f  mtsrim   CPS, $007f              
  2000018:  c6470300  mfsr     gr71, CFG               
  200001c:  93474720  or       gr71, gr71, $20         
  2000020:  ce000347  mtsr     CFG, gr71               
  2000024:  c6560400  mfsr     gr86, CHA               
  2000028:  c65a0600  mfsr     gr90, CHC               
  200002c:  8147561f  sll      gr71, gr86, $1f         
  2000030:  ac004735  jmpt     gr71, $2000104             ; -> L_2000104
  2000034:  81575a10  sll      gr87, gr90, $10            ; [delay slot]
  2000038:  91475240  and      gr71, gr82, $40         
  200003c:  63474700  cpneq    gr71, gr71, $00         
  2000040:  ac00477b  jmpt     gr71, $200022c             ; -> L_200022c
  2000044:  81475a11  sll      gr71, gr90, $11            ; [delay slot]
  2000048:  ac00473a  jmpt     gr71, $2000130             ; -> L_2000130
  200004c:  03004704  const    gr71, $0004                ; [delay slot]
  2000050:  a80645f7  call     gr69, $2001c2c             ; -> L_2001c2c
  2000054:  81465600  sll      gr70, gr86, $00            ; [delay slot]
  2000058:  61474704  cpeq     gr71, gr71, $04         
  200005c:  a4004704  jmpf     gr71, $200006c             ; -> L_200006c
  2000060:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000064:  a0000075  jmp      $2000238                   ; -> L_2000238
  2000068:  81564600  sll      gr86, gr70, $00            ; [delay slot]
L_200006c:
  200006c:  ac00570b  jmpt     gr87, $2000098             ; -> L_2000098
  2000070:  c6440500  mfsr     gr68, CHD                  ; [delay slot]
  2000074:  835a4410  srl      gr90, gr68, $10         
  2000078:  1e025a46  store    0, 2, gr90, gr70        
  200007c:  03004702  const    gr71, $0002             
  2000080:  a80645eb  call     gr69, $2001c2c             ; -> L_2001c2c
  2000084:  15465602  add      gr70, gr86, $02            ; [delay slot]
  2000088:  1e024446  store    0, 2, gr68, gr70        
  200008c:  70400101  aseq     trap64, gr1, gr1        
  2000090:  a0000010  jmp      $20000d0                   ; -> L_20000d0
  2000094:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2000098:
  2000098:  030357fc  const    gr87, $03fc             
  200009c:  905a575a  and      gr90, gr87, gr90        
  20000a0:  c6578000  mfsr     gr87, IPC               
  20000a4:  16024446  load     0, 2, gr68, gr70        
  20000a8:  ce00805a  mtsr     IPC, gr90               
  20000ac:  03004702  const    gr71, $0002             
  20000b0:  a80645df  call     gr69, $2001c2c             ; -> L_2001c2c
  20000b4:  15465602  add      gr70, gr86, $02            ; [delay slot]
  20000b8:  81444410  sll      gr68, gr68, $10         
  20000bc:  16025a46  load     0, 2, gr90, gr70        
  20000c0:  9200445a  or       gr0, gr68, gr90         
  20000c4:  ce008057  mtsr     IPC, gr87               
  20000c8:  a0000002  jmp      $20000d0                   ; -> L_20000d0
  20000cc:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_20000d0:
  20000d0:  c65a0600  mfsr     gr90, CHC               
  20000d4:  03005a00  const    gr90, $0000             
  20000d8:  ce00065a  mtsr     CHC, gr90               
  20000dc:  8145400d  sll      gr69, gr64, $0d         
  20000e0:  ac004504  jmpt     gr69, $20000f0             ; -> L_20000f0
  20000e4:  c6470300  mfsr     gr71, CFG                  ; [delay slot]
  20000e8:  93474720  or       gr71, gr71, $20         
  20000ec:  ce000347  mtsr     CFG, gr71               
L_20000f0:
  20000f0:  0404027f  mtsrim   CPS, $047f              
  20000f4:  ce000b59  mtsr     PC1, gr89               
  20000f8:  ce000a58  mtsr     PC0, gr88               
  20000fc:  ce000152  mtsr     OPS, gr82               
  2000100:  88000000  iret                             
L_2000104:
  2000104:  c6470100  mfsr     gr71, OPS                  ; [delay slot]
  2000108:  91474701  and      gr71, gr71, $01         
  200010c:  61474700  cpeq     gr71, gr71, $00         
  2000110:  ac004706  jmpt     gr71, $2000128             ; -> L_2000128
  2000114:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000118:  25545404  sub      gr84, gr84, $04         
  200011c:  16005954  load     0, 0, gr89, gr84        
  2000120:  25545404  sub      gr84, gr84, $04         
  2000124:  16005854  load     0, 0, gr88, gr84        
L_2000128:
  2000128:  a00900b8  jmp      $2002808                   ; -> L_2002808
  200012c:  03004d92  const    gr77, $0092                ; [delay slot]
*  (store-multiple / load-multiple emulation path of the unaligned handler)
L_2000130:
  2000130:  c6448700  mfsr     gr68, CR                
  2000134:  814d4402  sll      gr77, gr68, $02         
  2000138:  81474d00  sll      gr71, gr77, $00         
  200013c:  a80645bc  call     gr69, $2001c2c             ; -> L_2001c2c
  2000140:  81465600  sll      gr70, gr86, $00            ; [delay slot]
  2000144:  6047474d  cpeq     gr71, gr71, gr77        
  2000148:  a4004704  jmpf     gr71, $2000158             ; -> L_2000158
  200014c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000150:  a000004f  jmp      $200028c                   ; -> L_200028c
  2000154:  81564600  sll      gr86, gr70, $00            ; [delay slot]
L_2000158:
  2000158:  a400571b  jmpf     gr87, $20001c4             ; -> L_20001c4
  200015c:  25444401  sub      gr68, gr68, $01            ; [delay slot]
  2000160:  030357fc  const    gr87, $03fc             
  2000164:  9057575a  and      gr87, gr87, gr90        
  2000168:  c64d8000  mfsr     gr77, IPC               
L_200016c:
  200016c:  61475700  cpeq     gr71, gr87, $00         
  2000170:  a4004703  jmpf     gr71, $200017c             ; -> L_200017c
  2000174:  03004704  const    gr71, $0004                ; [delay slot]
  2000178:  03025700  const    gr87, $0200             
L_200017c:
  200017c:  a80645ac  call     gr69, $2001c2c             ; -> L_2001c2c
  2000180:  81465600  sll      gr70, gr86, $00            ; [delay slot]
  2000184:  ce008057  mtsr     IPC, gr87               
  2000188:  16025a46  load     0, 2, gr90, gr70        
  200018c:  61474704  cpeq     gr71, gr71, $04         
  2000190:  ac004705  jmpt     gr71, $20001a4             ; -> L_20001a4
  2000194:  15464602  add      gr70, gr70, $02            ; [delay slot]
  2000198:  03004702  const    gr71, $0002             
  200019c:  a80645a4  call     gr69, $2001c2c             ; -> L_2001c2c
  20001a0:  15465602  add      gr70, gr86, $02            ; [delay slot]
L_20001a4:
  20001a4:  81495a10  sll      gr73, gr90, $10         
  20001a8:  16025a46  load     0, 2, gr90, gr70        
  20001ac:  92005a49  or       gr0, gr90, gr73         
  20001b0:  15565604  add      gr86, gr86, $04         
  20001b4:  b4ff44ee  jmpfdec  gr68, $200016c             ; -> L_200016c
  20001b8:  15575704  add      gr87, gr87, $04            ; [delay slot]
  20001bc:  a000001a  jmp      $2000224                   ; -> L_2000224
  20001c0:  ce00804d  mtsr     IPC, gr77                  ; [delay slot]
L_20001c4:
  20001c4:  030357fc  const    gr87, $03fc             
  20001c8:  9057575a  and      gr87, gr87, gr90        
  20001cc:  c64d8100  mfsr     gr77, IPA               
L_20001d0:
  20001d0:  61475700  cpeq     gr71, gr87, $00         
  20001d4:  a4004703  jmpf     gr71, $20001e0             ; -> L_20001e0
  20001d8:  03004704  const    gr71, $0004                ; [delay slot]
  20001dc:  03025700  const    gr87, $0200             
L_20001e0:
  20001e0:  ce008157  mtsr     IPA, gr87               
  20001e4:  a8064592  call     gr69, $2001c2c             ; -> L_2001c2c
  20001e8:  81465600  sll      gr70, gr86, $00            ; [delay slot]
  20001ec:  835a0010  srl      gr90, gr0, $10          
  20001f0:  1e025a46  store    0, 2, gr90, gr70        
  20001f4:  61474704  cpeq     gr71, gr71, $04         
  20001f8:  ac004705  jmpt     gr71, $200020c             ; -> L_200020c
  20001fc:  15464602  add      gr70, gr70, $02            ; [delay slot]
  2000200:  03004702  const    gr71, $0002             
  2000204:  a806458a  call     gr69, $2001c2c             ; -> L_2001c2c
  2000208:  15465602  add      gr70, gr86, $02            ; [delay slot]
L_200020c:
  200020c:  1e020046  store    0, 2, gr0, gr70         
  2000210:  15565604  add      gr86, gr86, $04         
  2000214:  b4ff44ef  jmpfdec  gr68, $20001d0             ; -> L_20001d0
  2000218:  15575704  add      gr87, gr87, $04            ; [delay slot]
  200021c:  a0000002  jmp      $2000224                   ; -> L_2000224
  2000220:  ce00814d  mtsr     IPA, gr77                  ; [delay slot]
L_2000224:
  2000224:  a0ff00ab  jmp      $20000d0                   ; -> L_20000d0
  2000228:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_200022c:
  200022c:  81475a11  sll      gr71, gr90, $11         
  2000230:  ac004717  jmpt     gr71, $200028c             ; -> L_200028c
  2000234:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2000238:
  2000238:  ac005709  jmpt     gr87, $200025c             ; -> L_200025c
  200023c:  c6440500  mfsr     gr68, CHD                  ; [delay slot]
  2000240:  835a4410  srl      gr90, gr68, $10         
  2000244:  1e025a56  store    0, 2, gr90, gr86        
  2000248:  15565602  add      gr86, gr86, $02         
  200024c:  1e024456  store    0, 2, gr68, gr86        
  2000250:  70400101  aseq     trap64, gr1, gr1        
  2000254:  a0ff009f  jmp      $20000d0                   ; -> L_20000d0
  2000258:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_200025c:
  200025c:  030357fc  const    gr87, $03fc             
  2000260:  16024456  load     0, 2, gr68, gr86        
  2000264:  905a575a  and      gr90, gr87, gr90        
  2000268:  c6578000  mfsr     gr87, IPC               
  200026c:  ce00805a  mtsr     IPC, gr90               
  2000270:  15565602  add      gr86, gr86, $02         
  2000274:  81444410  sll      gr68, gr68, $10         
  2000278:  16025a56  load     0, 2, gr90, gr86        
  200027c:  9200445a  or       gr0, gr68, gr90         
  2000280:  ce008057  mtsr     IPC, gr87               
  2000284:  a0ff0093  jmp      $20000d0                   ; -> L_20000d0
  2000288:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_200028c:
  200028c:  c6448700  mfsr     gr68, CR                
  2000290:  a4005714  jmpf     gr87, $20002e0             ; -> L_20002e0
  2000294:  25444401  sub      gr68, gr68, $01            ; [delay slot]
  2000298:  030357fc  const    gr87, $03fc             
  200029c:  9057575a  and      gr87, gr87, gr90        
  20002a0:  c64d8000  mfsr     gr77, IPC               
L_20002a4:
  20002a4:  61475700  cpeq     gr71, gr87, $00         
  20002a8:  a4004703  jmpf     gr71, $20002b4             ; -> L_20002b4
  20002ac:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20002b0:  03025700  const    gr87, $0200             
L_20002b4:
  20002b4:  16025a56  load     0, 2, gr90, gr86        
  20002b8:  ce008057  mtsr     IPC, gr87               
  20002bc:  15565602  add      gr86, gr86, $02         
  20002c0:  81475a10  sll      gr71, gr90, $10         
  20002c4:  16025a56  load     0, 2, gr90, gr86        
  20002c8:  92005a47  or       gr0, gr90, gr71         
  20002cc:  15565602  add      gr86, gr86, $02         
  20002d0:  b4ff44f5  jmpfdec  gr68, $20002a4             ; -> L_20002a4
  20002d4:  15575704  add      gr87, gr87, $04            ; [delay slot]
  20002d8:  a0ff00d3  jmp      $2000224                   ; -> L_2000224
  20002dc:  ce00804d  mtsr     IPC, gr77                  ; [delay slot]
L_20002e0:
  20002e0:  030357fc  const    gr87, $03fc             
  20002e4:  9057575a  and      gr87, gr87, gr90        
  20002e8:  c64d8100  mfsr     gr77, IPA               
L_20002ec:
  20002ec:  61475700  cpeq     gr71, gr87, $00         
  20002f0:  a4004703  jmpf     gr71, $20002fc             ; -> L_20002fc
  20002f4:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20002f8:  03025700  const    gr87, $0200             
L_20002fc:
  20002fc:  ce008157  mtsr     IPA, gr87               
  2000300:  835a0010  srl      gr90, gr0, $10          
  2000304:  1e025a56  store    0, 2, gr90, gr86        
  2000308:  15565602  add      gr86, gr86, $02         
  200030c:  1e020056  store    0, 2, gr0, gr86         
  2000310:  15565602  add      gr86, gr86, $02         
  2000314:  b4ff44f6  jmpfdec  gr68, $20002ec             ; -> L_20002ec
  2000318:  15575704  add      gr87, gr87, $04            ; [delay slot]
  200031c:  a0ff00c2  jmp      $2000224                   ; -> L_2000224
  2000320:  ce00814d  mtsr     IPA, gr77                  ; [delay slot]
L_2000324:
  2000324:  0404027f  mtsrim   CPS, $047f              
  2000328:  c6540400  mfsr     gr84, CHA               
  200032c:  91545403  and      gr84, gr84, $03         
  2000330:  61545400  cpeq     gr84, gr84, $00         
  2000334:  ac005450  jmpt     gr84, $2000474             ; -> L_2000474
  2000338:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  200033c:  0300555c  const    gr85, $005c             
  2000340:  02445500  consth   gr85, $4400             
  2000344:  03005400  const    gr84, $0000             
  2000348:  1e005455  store    0, 0, gr84, gr85        
  200034c:  01ff54ff  constn   gr84, $ffff             
  2000350:  a0ff002e  jmp      $2000008                   ; -> L_2000008
  2000354:  1e005455  store    0, 0, gr84, gr85           ; [delay slot]
* ==================================================================
*  VECTOR 7 -- DATA ACCESS EXCEPTION: saves registers to $4C003090,
*  clears the CHC fault bits, reads the bus status word at $46000000,
*  acknowledges the source (bit mask built from the faulting address)
*  and resumes (iret/iretinv) with CHA/CHC adjusted; unrecoverable
*  cases report reason $90.  [$20004A4: interrupt-style acknowledge path]
* ==================================================================
  2000358:  03045500  const    gr85, $0400             
  200035c:  03305490  const    gr84, $3090             
  2000360:  024c5400  consth   gr84, $4c00             
  2000364:  1e004454  store    0, 0, gr68, gr84        
  2000368:  15545404  add      gr84, gr84, $04         
  200036c:  1e005654  store    0, 0, gr86, gr84        
  2000370:  15545404  add      gr84, gr84, $04         
  2000374:  1e005a54  store    0, 0, gr90, gr84        
  2000378:  15545404  add      gr84, gr84, $04         
  200037c:  1e005754  store    0, 0, gr87, gr84        
  2000380:  15545404  add      gr84, gr84, $04         
  2000384:  1e005254  store    0, 0, gr82, gr84        
  2000388:  15545404  add      gr84, gr84, $04         
  200038c:  1e005854  store    0, 0, gr88, gr84        
  2000390:  15545404  add      gr84, gr84, $04         
  2000394:  1e005954  store    0, 0, gr89, gr84        
  2000398:  c65a0600  mfsr     gr90, CHC               
  200039c:  9c5a5a55  andn     gr90, gr90, gr85        
  20003a0:  935a5a01  or       gr90, gr90, $01         
  20003a4:  9d575a01  andn     gr87, gr90, $01         
  20003a8:  ce000657  mtsr     CHC, gr87               
  20003ac:  c6560400  mfsr     gr86, CHA               
  20003b0:  c6570500  mfsr     gr87, CHD               
  20003b4:  c6520100  mfsr     gr82, OPS               
  20003b8:  c6580a00  mfsr     gr88, PC0               
  20003bc:  c6590b00  mfsr     gr89, PC1               
  20003c0:  0400027f  mtsrim   CPS, $007f              
  20003c4:  03005500  const    gr85, $0000             
  20003c8:  02465500  consth   gr85, $4600             
  20003cc:  16005555  load     0, 0, gr85, gr85        
  20003d0:  0404027f  mtsrim   CPS, $047f              
  20003d4:  ce000b59  mtsr     PC1, gr89               
  20003d8:  ce000a58  mtsr     PC0, gr88               
  20003dc:  ce000152  mtsr     OPS, gr82               
  20003e0:  ce000456  mtsr     CHA, gr86               
  20003e4:  ce000557  mtsr     CHD, gr87               
  20003e8:  ce00065a  mtsr     CHC, gr90               
  20003ec:  16005954  load     0, 0, gr89, gr84        
  20003f0:  25545404  sub      gr84, gr84, $04         
  20003f4:  16005854  load     0, 0, gr88, gr84        
  20003f8:  25545404  sub      gr84, gr84, $04         
  20003fc:  16005254  load     0, 0, gr82, gr84        
  2000400:  25545404  sub      gr84, gr84, $04         
  2000404:  16005754  load     0, 0, gr87, gr84        
  2000408:  25545404  sub      gr84, gr84, $04         
  200040c:  16005a54  load     0, 0, gr90, gr84        
  2000410:  25545404  sub      gr84, gr84, $04         
  2000414:  16005654  load     0, 0, gr86, gr84        
  2000418:  25545404  sub      gr84, gr84, $04         
  200041c:  16004454  load     0, 0, gr68, gr84        
  2000420:  8154551b  sll      gr84, gr85, $1b         
  2000424:  ac00540f  jmpt     gr84, $2000460             ; -> L_2000460
  2000428:  8154551d  sll      gr84, gr85, $1d            ; [delay slot]
  200042c:  ac00541e  jmpt     gr84, $20004a4             ; -> L_20004a4
  2000430:  81544017  sll      gr84, gr64, $17            ; [delay slot]
  2000434:  a4005405  jmpf     gr84, $2000448             ; -> L_2000448
  2000438:  03005470  const    gr84, $0070                ; [delay slot]
  200043c:  02445400  consth   gr84, $4400             
  2000440:  16005454  load     0, 0, gr84, gr84        
  2000444:  acff54b8  jmpt     gr84, $2000324             ; -> L_2000324
L_2000448:
  2000448:  91555503  and      gr85, gr85, $03            ; [delay slot]
  200044c:  61545503  cpeq     gr84, gr85, $03         
  2000450:  ac005404  jmpt     gr84, $2000460             ; -> L_2000460
  2000454:  61545500  cpeq     gr84, gr85, $00            ; [delay slot]
  2000458:  a4005407  jmpf     gr84, $2000474             ; -> L_2000474
  200045c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2000460:
  2000460:  c6550600  mfsr     gr85, CHC               
  2000464:  81555501  sll      gr85, gr85, $01         
  2000468:  ac00554b  jmpt     gr85, $2000594             ; -> L_2000594
  200046c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000470:  88000000  iret                             
L_2000474:
  2000474:  036754e0  const    gr84, $67e0                ; [delay slot]
  2000478:  024c5400  consth   gr84, $4c00             
  200047c:  16005554  load     0, 0, gr85, gr84        
  2000480:  a4005507  jmpf     gr85, $200049c             ; -> L_200049c
  2000484:  15555501  add      gr85, gr85, $01            ; [delay slot]
  2000488:  1e005554  store    0, 0, gr85, gr84        
  200048c:  c6550600  mfsr     gr85, CHC               
  2000490:  9d555501  andn     gr85, gr85, $01         
  2000494:  ce000655  mtsr     CHC, gr85               
  2000498:  88000000  iret                             
L_200049c:
  200049c:  a00800db  jmp      $2002808                   ; -> L_2002808   ; [delay slot]
  20004a0:  03004d90  const    gr77, $0090                ; [delay slot]
L_20004a4:
  20004a4:  03305490  const    gr84, $3090             
  20004a8:  024c5400  consth   gr84, $4c00             
  20004ac:  1e004654  store    0, 0, gr70, gr84        
  20004b0:  15545404  add      gr84, gr84, $04         
  20004b4:  1e004354  store    0, 0, gr67, gr84        
  20004b8:  15545404  add      gr84, gr84, $04         
  20004bc:  1e004454  store    0, 0, gr68, gr84        
  20004c0:  15545404  add      gr84, gr84, $04         
  20004c4:  1e005654  store    0, 0, gr86, gr84        
  20004c8:  15545404  add      gr84, gr84, $04         
  20004cc:  1e005a54  store    0, 0, gr90, gr84        
  20004d0:  15545404  add      gr84, gr84, $04         
  20004d4:  1e005754  store    0, 0, gr87, gr84        
  20004d8:  15545404  add      gr84, gr84, $04         
  20004dc:  1e005854  store    0, 0, gr88, gr84        
  20004e0:  15545404  add      gr84, gr84, $04         
  20004e4:  1e005954  store    0, 0, gr89, gr84        
  20004e8:  03045501  const    gr85, $0401             
  20004ec:  c65a0600  mfsr     gr90, CHC               
  20004f0:  9c5a5a55  andn     gr90, gr90, gr85        
  20004f4:  ce00065a  mtsr     CHC, gr90               
  20004f8:  c6560400  mfsr     gr86, CHA               
  20004fc:  c6570500  mfsr     gr87, CHD               
  2000500:  c6580a00  mfsr     gr88, PC0               
  2000504:  c6590b00  mfsr     gr89, PC1               
  2000508:  0400027f  mtsrim   CPS, $007f              
  200050c:  8344561c  srl      gr68, gr86, $1c         
  2000510:  6146440f  cpeq     gr70, gr68, $0f         
  2000514:  03004300  const    gr67, $0000             
  2000518:  a4004604  jmpf     gr70, $2000528             ; -> L_2000528
  200051c:  02004301  consth   gr67, $0001                ; [delay slot]
  2000520:  83445618  srl      gr68, gr86, $18         
  2000524:  9144440f  and      gr68, gr68, $0f         
L_2000528:
  2000528:  80434344  sll      gr67, gr67, gr68        
  200052c:  03004400  const    gr68, $0000             
  2000530:  02464400  consth   gr68, $4600             
  2000534:  16004644  load     0, 0, gr70, gr68        
  2000538:  9c464643  andn     gr70, gr70, gr67        
  200053c:  1e004644  store    0, 0, gr70, gr68        
  2000540:  0404027f  mtsrim   CPS, $047f              
  2000544:  ce000b59  mtsr     PC1, gr89               
  2000548:  ce000a58  mtsr     PC0, gr88               
  200054c:  ce000456  mtsr     CHA, gr86               
  2000550:  ce000557  mtsr     CHD, gr87               
  2000554:  ce00065a  mtsr     CHC, gr90               
  2000558:  16005954  load     0, 0, gr89, gr84        
  200055c:  25545404  sub      gr84, gr84, $04         
  2000560:  16005854  load     0, 0, gr88, gr84        
  2000564:  25545404  sub      gr84, gr84, $04         
  2000568:  16005754  load     0, 0, gr87, gr84        
  200056c:  25545404  sub      gr84, gr84, $04         
  2000570:  16005a54  load     0, 0, gr90, gr84        
  2000574:  25545404  sub      gr84, gr84, $04         
  2000578:  16005654  load     0, 0, gr86, gr84        
  200057c:  25545404  sub      gr84, gr84, $04         
  2000580:  16004454  load     0, 0, gr68, gr84        
  2000584:  25545404  sub      gr84, gr84, $04         
  2000588:  16004354  load     0, 0, gr67, gr84        
  200058c:  25545404  sub      gr84, gr84, $04         
  2000590:  16004654  load     0, 0, gr70, gr84        
L_2000594:
  2000594:  a4004009  jmpf     gr64, $20005b8             ; -> L_20005b8
  2000598:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  200059c:  c6540600  mfsr     gr84, CHC               
  20005a0:  9d545401  andn     gr84, gr84, $01         
  20005a4:  ce000654  mtsr     CHC, gr84               
  20005a8:  ce000b79  mtsr     PC1, gr121              
  20005ac:  15547904  add      gr84, gr121, $04        
  20005b0:  ce000a54  mtsr     PC0, gr84               
  20005b4:  8c000000  iretinv                          
L_20005b8:
  20005b8:  c6550600  mfsr     gr85, CHC                  ; [delay slot]
  20005bc:  83545518  srl      gr84, gr85, $18         
  20005c0:  91545403  and      gr84, gr84, $03         
  20005c4:  03004402  const    gr68, $0002             
  20005c8:  80444454  sll      gr68, gr68, gr84        
  20005cc:  83545510  srl      gr84, gr85, $10         
  20005d0:  9154540f  and      gr84, gr84, $0f         
  20005d4:  15545401  add      gr84, gr84, $01         
  20005d8:  24434454  sub      gr67, gr68, gr84        
  20005dc:  25444401  sub      gr68, gr68, $01         
  20005e0:  81444410  sll      gr68, gr68, $10         
  20005e4:  03005400  const    gr84, $0000             
  20005e8:  020054ff  consth   gr84, $00ff             
  20005ec:  9c555554  andn     gr85, gr85, gr84        
  20005f0:  92555544  or       gr85, gr85, gr68        
  20005f4:  93555501  or       gr85, gr85, $01         
  20005f8:  83545502  srl      gr84, gr85, $02         
  20005fc:  915454ff  and      gr84, gr84, $ff         
  2000600:  24545443  sub      gr84, gr84, gr67        
  2000604:  c6448100  mfsr     gr68, IPA               
  2000608:  81545402  sll      gr84, gr84, $02         
  200060c:  ce008154  mtsr     IPA, gr84               
  2000610:  70400101  aseq     trap64, gr1, gr1        
  2000614:  81510000  sll      gr81, gr0, $00          
  2000618:  ce000551  mtsr     CHD, gr81               
  200061c:  ce008144  mtsr     IPA, gr68               
  2000620:  030344fc  const    gr68, $03fc             
  2000624:  9c555544  andn     gr85, gr85, gr68        
  2000628:  92555554  or       gr85, gr85, gr84        
  200062c:  ce000655  mtsr     CHC, gr85               
  2000630:  81434302  sll      gr67, gr67, $02         
  2000634:  c6540400  mfsr     gr84, CHA               
  2000638:  24545443  sub      gr84, gr84, gr67        
  200063c:  ce000454  mtsr     CHA, gr84               
  2000640:  88000000  iret                             
* ==================================================================
*  VECTOR 6 -- INSTRUCTION ACCESS EXCEPTION: records PC0/PC1 and reports
*  reason $95 through $2002808.
* ==================================================================
  2000644:  15825800  add      lr2, gr88, $00             ; [delay slot]
  2000648:  15835900  add      lr3, gr89, $00          
  200064c:  c6470100  mfsr     gr71, OPS               
  2000650:  91474701  and      gr71, gr71, $01         
  2000654:  61474700  cpeq     gr71, gr71, $00         
  2000658:  a4004704  jmpf     gr71, $2000668             ; -> L_2000668
  200065c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000660:  c6820a00  mfsr     lr2, PC0                
  2000664:  c6830b00  mfsr     lr3, PC1                
L_2000668:
  2000668:  a0080068  jmp      $2002808                   ; -> L_2002808
  200066c:  03004d95  const    gr77, $0095                ; [delay slot]
* ==================================================================
*  VECTORS 8 and 10 -- INSTRUCTION TLB MISS (software TLB refill).
*  If CHC bit 10 is set it just clears CHC bit 0 and returns.  Otherwise
*  it hashes the 1 KB page number ((PC1 >> 10) & $1F) into the bucket table
*  at $4C002818, walks the chain for a tag equal to the page, and loads the
*  two TLB words with 'mttlb' at the LRU slot (LRU, LRU+1); iretinv restarts
*  the instruction.  Not found -> $2001D10 (pager).  Reason $95 on null PC1.
* ==================================================================
  2000670:  c6540600  mfsr     gr84, CHC               
  2000674:  81555415  sll      gr85, gr84, $15         
  2000678:  a4005504  jmpf     gr85, $2000688             ; -> L_2000688
  200067c:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2000680:  ce000654  mtsr     CHC, gr84               
  2000684:  88000000  iret                             
L_2000688:
  2000688:  c6440b00  mfsr     gr68, PC1                  ; [delay slot]
  200068c:  614d4400  cpeq     gr77, gr68, $00         
  2000690:  ac084d5e  jmpt     gr77, $2002808             ; -> L_2002808
  2000694:  03004d95  const    gr77, $0095                ; [delay slot]
  2000698:  8344440a  srl      gr68, gr68, $0a         
  200069c:  914d441f  and      gr77, gr68, $1f         
  20006a0:  8144440a  sll      gr68, gr68, $0a         
  20006a4:  03284818  const    gr72, $2818             
  20006a8:  024c4800  consth   gr72, $4c00             
  20006ac:  81474d02  sll      gr71, gr77, $02         
  20006b0:  14474847  add      gr71, gr72, gr71        
  20006b4:  16004c47  load     0, 0, gr76, gr71        
  20006b8:  15484c00  add      gr72, gr76, $00         
L_20006bc:
  20006bc:  61474800  cpeq     gr71, gr72, $00         
  20006c0:  ac054794  jmpt     gr71, $2001d10             ; -> L_2001d10
  20006c4:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20006c8:  154c4800  add      gr76, gr72, $00         
  20006cc:  1600474c  load     0, 0, gr71, gr76        
  20006d0:  60474744  cpeq     gr71, gr71, gr68        
  20006d4:  ac004704  jmpt     gr71, $20006e4             ; -> L_20006e4
  20006d8:  15474c0c  add      gr71, gr76, $0c            ; [delay slot]
  20006dc:  a0ff00f8  jmp      $20006bc                   ; -> L_20006bc
  20006e0:  16004847  load     0, 0, gr72, gr71           ; [delay slot]
L_20006e4:
  20006e4:  15494c04  add      gr73, gr76, $04         
  20006e8:  16004349  load     0, 0, gr67, gr73        
L_20006ec:
  20006ec:  03805100  const    gr81, $8000             
  20006f0:  02ff51ff  consth   gr81, $ffff             
  20006f4:  90445144  and      gr68, gr81, gr68        
  20006f8:  03495100  const    gr81, $4900             
  20006fc:  92445144  or       gr68, gr81, gr68        
  2000700:  c6510e00  mfsr     gr81, LRU               
  2000704:  be005144  mttlb    gr81, gr68              
  2000708:  15515101  add      gr81, gr81, $01         
  200070c:  be005143  mttlb    gr81, gr67              
  2000710:  8c000000  iretinv                          
* ==================================================================
*  VECTORS 9 and 11 -- DATA TLB MISS.  Builds the TLB tag from CHA (page
*  address | $7600 flags), loads it at LRU, then checks whether the address
*  lies in a registered region of the table at $4C00316C (bitmask test on
*  the top nibble against gr91, then a linear scan over the entries); if it
*  does, remaps via the entry's offset and retries (mttlb + iret).  If not,
*  and gr64 bit 30 says to trap, it records the miss at $4C0061C8/61CC and
*  sets an OPS bit; otherwise reason $A6 (miss outside any region).
* ==================================================================
  2000714:  c64a0e00  mfsr     gr74, LRU                  ; [delay slot]
  2000718:  c6440400  mfsr     gr68, CHA               
  200071c:  03804c00  const    gr76, $8000             
  2000720:  02ff4cff  consth   gr76, $ffff             
  2000724:  9043444c  and      gr67, gr68, gr76        
  2000728:  03764c00  const    gr76, $7600             
  200072c:  92434c43  or       gr67, gr76, gr67        
  2000730:  be004a43  mttlb    gr74, gr67              
  2000734:  154a4a01  add      gr74, gr74, $01         
  2000738:  01fc4300  constn   gr67, $fc00             
  200073c:  90444443  and      gr68, gr68, gr67        
  2000740:  8347441c  srl      gr71, gr68, $1c         
  2000744:  15474710  add      gr71, gr71, $10         
  2000748:  03004801  const    gr72, $0001             
  200074c:  80484847  sll      gr72, gr72, gr71        
  2000750:  9048485b  and      gr72, gr72, gr91        
  2000754:  61484800  cpeq     gr72, gr72, $00         
  2000758:  ac00481f  jmpt     gr72, $20007d4             ; -> L_20007d4
  200075c:  81474004  sll      gr71, gr64, $04            ; [delay slot]
  2000760:  a400471d  jmpf     gr71, $20007d4             ; -> L_20007d4
  2000764:  03034cff  const    gr76, $03ff                ; [delay slot]
  2000768:  904c5b4c  and      gr76, gr91, gr76        
  200076c:  03314d6c  const    gr77, $316c             
  2000770:  024c4d00  consth   gr77, $4c00             
L_2000774:
  2000774:  254c4c01  sub      gr76, gr76, $01         
  2000778:  ac004c17  jmpt     gr76, $20007d4             ; -> L_20007d4
  200077c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000780:  1600514d  load     0, 0, gr81, gr77        
  2000784:  154d4d04  add      gr77, gr77, $04         
  2000788:  60454451  cpeq     gr69, gr68, gr81        
  200078c:  ac00450f  jmpt     gr69, $20007c8             ; -> L_20007c8
  2000790:  42454451  cpltu    gr69, gr68, gr81           ; [delay slot]
  2000794:  ac004507  jmpt     gr69, $20007b0             ; -> L_20007b0
  2000798:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  200079c:  1600434d  load     0, 0, gr67, gr77        
  20007a0:  14435143  add      gr67, gr81, gr67        
  20007a4:  42454443  cpltu    gr69, gr68, gr67        
  20007a8:  ac004504  jmpt     gr69, $20007b8             ; -> L_20007b8
  20007ac:  24434451  sub      gr67, gr68, gr81           ; [delay slot]
L_20007b0:
  20007b0:  a0ff00f1  jmp      $2000774                   ; -> L_2000774
  20007b4:  154d4d08  add      gr77, gr77, $08            ; [delay slot]
L_20007b8:
  20007b8:  154d4d04  add      gr77, gr77, $04         
  20007bc:  1600444d  load     0, 0, gr68, gr77        
  20007c0:  a0000036  jmp      $2000898                   ; -> L_2000898
  20007c4:  14444443  add      gr68, gr68, gr67           ; [delay slot]
L_20007c8:
  20007c8:  154d4d04  add      gr77, gr77, $04         
  20007cc:  a0000033  jmp      $2000898                   ; -> L_2000898
  20007d0:  1600444d  load     0, 0, gr68, gr77           ; [delay slot]
L_20007d4:
  20007d4:  81484001  sll      gr72, gr64, $01         
  20007d8:  a4004830  jmpf     gr72, $2000898             ; -> L_2000898
  20007dc:  036747dc  const    gr71, $67dc                ; [delay slot]
  20007e0:  024c4700  consth   gr71, $4c00             
  20007e4:  c6440400  mfsr     gr68, CHA               
  20007e8:  16004347  load     0, 0, gr67, gr71        
  20007ec:  036747d8  const    gr71, $67d8             
  20007f0:  024c4700  consth   gr71, $4c00             
  20007f4:  16004747  load     0, 0, gr71, gr71        
  20007f8:  8348471c  srl      gr72, gr71, $1c         
  20007fc:  03ff4bff  const    gr75, $ffff             
  2000800:  020f4bff  consth   gr75, $0fff             
  2000804:  61484804  cpeq     gr72, gr72, $04         
  2000808:  a4004804  jmpf     gr72, $2000818             ; -> L_2000818
  200080c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000810:  9047474b  and      gr71, gr71, gr75        
  2000814:  92474742  or       gr71, gr71, gr66        
L_2000818:
  2000818:  c6490400  mfsr     gr73, CHA               
  200081c:  8348491c  srl      gr72, gr73, $1c         
  2000820:  61484804  cpeq     gr72, gr72, $04         
  2000824:  a4004804  jmpf     gr72, $2000834             ; -> L_2000834
  2000828:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  200082c:  9049494b  and      gr73, gr73, gr75        
  2000830:  92494942  or       gr73, gr73, gr66        
L_2000834:
  2000834:  42484947  cpltu    gr72, gr73, gr71        
  2000838:  ac00480a  jmpt     gr72, $2000860             ; -> L_2000860
  200083c:  14474743  add      gr71, gr71, gr67           ; [delay slot]
  2000840:  4a484947  cpgtu    gr72, gr73, gr71        
  2000844:  ac004807  jmpt     gr72, $2000860             ; -> L_2000860
  2000848:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  200084c:  8344440a  srl      gr68, gr68, $0a         
  2000850:  8144440a  sll      gr68, gr68, $0a         
  2000854:  be004a44  mttlb    gr74, gr68              
  2000858:  a00700ec  jmp      $2002808                   ; -> L_2002808
  200085c:  03004da6  const    gr77, $00a6                ; [delay slot]
L_2000860:
  2000860:  8344440a  srl      gr68, gr68, $0a         
  2000864:  8144440a  sll      gr68, gr68, $0a         
  2000868:  036148c8  const    gr72, $61c8             
  200086c:  024c4800  consth   gr72, $4c00             
  2000870:  01ff47ff  constn   gr71, $ffff             
  2000874:  1e004748  store    0, 0, gr71, gr72        
  2000878:  036148cc  const    gr72, $61cc             
  200087c:  024c4800  consth   gr72, $4c00             
  2000880:  25474601  sub      gr71, gr70, $01         
  2000884:  1e004748  store    0, 0, gr71, gr72        
  2000888:  c6470100  mfsr     gr71, OPS               
  200088c:  03204b00  const    gr75, $2000             
  2000890:  9247474b  or       gr71, gr71, gr75        
  2000894:  ce000147  mtsr     OPS, gr71               
L_2000898:
  2000898:  be004a44  mttlb    gr74, gr68              
  200089c:  88000000  iret                             
*  VECTOR 12 -- INSTRUCTION TLB PROTECTION VIOLATION: reason $95
  20008a0:  a00700da  jmp      $2002808                   ; -> L_2002808   ; [delay slot]
  20008a4:  03004d95  const    gr77, $0095                ; [delay slot]
* ==================================================================
*  VECTOR 13 -- DATA TLB PROTECTION VIOLATION: if the miss recorded at
*  $4C0061C8/61CC matches (trace/step bookkeeping) clears OPS bit $2000 and
*  returns; else reason $9C.
* ==================================================================
  20008a8:  81474001  sll      gr71, gr64, $01         
  20008ac:  a4004714  jmpf     gr71, $20008fc             ; -> L_20008fc
  20008b0:  036147c8  const    gr71, $61c8                ; [delay slot]
  20008b4:  024c4700  consth   gr71, $4c00             
  20008b8:  16004847  load     0, 0, gr72, gr71        
  20008bc:  a4004810  jmpf     gr72, $20008fc             ; -> L_20008fc
  20008c0:  036149cc  const    gr73, $61cc                ; [delay slot]
  20008c4:  024c4900  consth   gr73, $4c00             
  20008c8:  16004949  load     0, 0, gr73, gr73        
  20008cc:  15494901  add      gr73, gr73, $01         
  20008d0:  604b4948  cpeq     gr75, gr73, gr72        
  20008d4:  ac004b04  jmpt     gr75, $20008e4             ; -> L_20008e4
  20008d8:  25484840  sub      gr72, gr72, $40            ; [delay slot]
  20008dc:  604b4948  cpeq     gr75, gr73, gr72        
  20008e0:  a4004b07  jmpf     gr75, $20008fc             ; -> L_20008fc
L_20008e4:
  20008e4:  03004600  const    gr70, $0000                ; [delay slot]
  20008e8:  1e004647  store    0, 0, gr70, gr71        
  20008ec:  c6460100  mfsr     gr70, OPS               
  20008f0:  03204900  const    gr73, $2000             
  20008f4:  9c464649  andn     gr70, gr70, gr73        
  20008f8:  ce000146  mtsr     OPS, gr70               
L_20008fc:
  20008fc:  88000000  iret                             
  2000900:  a00700c2  jmp      $2002808                   ; -> L_2002808   ; [delay slot]
  2000904:  03004d9c  const    gr77, $009c                ; [delay slot]
*  VECTOR 2 -- OUT OF RANGE: returns (iret) if gr64 bit 15 is set, else reason $93
  2000908:  81474010  sll      gr71, gr64, $10         
  200090c:  ac004704  jmpt     gr71, $200091c             ; -> L_200091c
  2000910:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000914:  a00700bd  jmp      $2002808                   ; -> L_2002808
  2000918:  03004d93  const    gr77, $0093                ; [delay slot]
L_200091c:
  200091c:  88000000  iret                             
*  VECTOR 3 -- NO COPROCESSOR: reason $8F
  2000920:  a00700ba  jmp      $2002808                   ; -> L_2002808   ; [delay slot]
  2000924:  03004d8f  const    gr77, $008f                ; [delay slot]
*  VECTOR 4 -- COPROCESSOR EXCEPTION: returns (iret) if gr64 bit 2 is set, else reason $9D
  2000928:  8147401d  sll      gr71, gr64, $1d         
  200092c:  ac004704  jmpt     gr71, $200093c             ; -> L_200093c
  2000930:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000934:  a00700b5  jmp      $2002808                   ; -> L_2002808
  2000938:  03004d9d  const    gr77, $009d                ; [delay slot]
L_200093c:
  200093c:  88000000  iret                             
*  VECTOR 5 -- PROTECTION VIOLATION: if CHC bit 10 is set clears CHC bit 0 and returns, else reason $9C
  2000940:  c6540600  mfsr     gr84, CHC                  ; [delay slot]
  2000944:  81555415  sll      gr85, gr84, $15         
  2000948:  a4005504  jmpf     gr85, $2000958             ; -> L_2000958
  200094c:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2000950:  ce000654  mtsr     CHC, gr84               
  2000954:  88000000  iret                             
L_2000958:
  2000958:  a00700ac  jmp      $2002808                   ; -> L_2002808   ; [delay slot]
  200095c:  03004d9c  const    gr77, $009c                ; [delay slot]
* ==================================================================
*  VECTOR 14 -- TIMER: reloads TMR with $01007530 (interrupt-enable bit +
*  30000 cycles), increments the tick counter at $4C006830 (every 65536
*  ticks copies the word at $4C00643C << 16 to $46000000), adds $7530 to
*  the cycle accumulator at $4C006834, and calls $2002794 (PC1 trace) when
*  tracing is enabled.  Returns with iret.
* ==================================================================
  2000960:  c6540600  mfsr     gr84, CHC               
  2000964:  81555415  sll      gr85, gr84, $15         
  2000968:  a4005504  jmpf     gr85, $2000978             ; -> L_2000978
  200096c:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2000970:  ce000654  mtsr     CHC, gr84               
  2000974:  88000000  iret                             
L_2000978:
  2000978:  8146400f  sll      gr70, gr64, $0f            ; [delay slot]
  200097c:  a4004608  jmpf     gr70, $200099c             ; -> L_200099c
  2000980:  036146bc  const    gr70, $61bc                ; [delay slot]
  2000984:  024c4600  consth   gr70, $4c00             
  2000988:  16004646  load     0, 0, gr70, gr70        
  200098c:  a4004604  jmpf     gr70, $200099c             ; -> L_200099c
  2000990:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000994:  a8074680  call     gr70, $2002794             ; -> L_2002794
  2000998:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_200099c:
  200099c:  03754730  const    gr71, $7530             
  20009a0:  02014700  consth   gr71, $0100             
  20009a4:  ce000947  mtsr     TMR, gr71               
  20009a8:  03684830  const    gr72, $6830             
  20009ac:  024c4800  consth   gr72, $4c00             
  20009b0:  16004948  load     0, 0, gr73, gr72        
  20009b4:  15494901  add      gr73, gr73, $01         
  20009b8:  1e004948  store    0, 0, gr73, gr72        
  20009bc:  03ff46ff  const    gr70, $ffff             
  20009c0:  90464946  and      gr70, gr73, gr70        
  20009c4:  61464600  cpeq     gr70, gr70, $00         
  20009c8:  a4004608  jmpf     gr70, $20009e8             ; -> L_20009e8
  20009cc:  0364463c  const    gr70, $643c                ; [delay slot]
  20009d0:  024c4600  consth   gr70, $4c00             
  20009d4:  16004746  load     0, 0, gr71, gr70        
  20009d8:  81474710  sll      gr71, gr71, $10         
  20009dc:  03004600  const    gr70, $0000             
  20009e0:  02464600  consth   gr70, $4600             
  20009e4:  1e004746  store    0, 0, gr71, gr70        
L_20009e8:
  20009e8:  03684834  const    gr72, $6834             
  20009ec:  024c4800  consth   gr72, $4c00             
  20009f0:  16004948  load     0, 0, gr73, gr72        
  20009f4:  03754a30  const    gr74, $7530             
  20009f8:  1449494a  add      gr73, gr73, gr74        
  20009fc:  c64b8400  mfsr     gr75, ALU               
  2000a00:  814b4b15  sll      gr75, gr75, $15         
  2000a04:  ac004b03  jmpt     gr75, $2000a10             ; -> L_2000a10
  2000a08:  1e004948  store    0, 0, gr73, gr72           ; [delay slot]
  2000a0c:  88000000  iret                             
L_2000a10:
  2000a10:  15484804  add      gr72, gr72, $04            ; [delay slot]
  2000a14:  16004948  load     0, 0, gr73, gr72        
  2000a18:  15494901  add      gr73, gr73, $01         
  2000a1c:  1e004948  store    0, 0, gr73, gr72        
  2000a20:  88000000  iret                             
* ==================================================================
*  VECTOR 15 -- TRACE: single-step support.  With the step state at
*  $4C0061C8/61CC armed it clears OPS bits, re-installs the TLB entry and
*  iretinv's; counts occurrences in $4C00684C/6850; otherwise reason $9F.
* ==================================================================
  2000a24:  c6540600  mfsr     gr84, CHC                  ; [delay slot]
  2000a28:  81555415  sll      gr85, gr84, $15         
  2000a2c:  a4005504  jmpf     gr85, $2000a3c             ; -> L_2000a3c
  2000a30:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2000a34:  ce000654  mtsr     CHC, gr84               
  2000a38:  88000000  iret                             
L_2000a3c:
  2000a3c:  c6430100  mfsr     gr67, OPS                  ; [delay slot]
  2000a40:  03104500  const    gr69, $1000             
  2000a44:  9c434345  andn     gr67, gr67, gr69        
  2000a48:  81474001  sll      gr71, gr64, $01         
  2000a4c:  a4004711  jmpf     gr71, $2000a90             ; -> L_2000a90
  2000a50:  036147c8  const    gr71, $61c8                ; [delay slot]
  2000a54:  024c4700  consth   gr71, $4c00             
  2000a58:  16004847  load     0, 0, gr72, gr71        
  2000a5c:  a400480d  jmpf     gr72, $2000a90             ; -> L_2000a90
  2000a60:  03204900  const    gr73, $2000                ; [delay slot]
  2000a64:  9c434349  andn     gr67, gr67, gr73        
  2000a68:  ce000143  mtsr     OPS, gr67               
  2000a6c:  03004600  const    gr70, $0000             
  2000a70:  1e004647  store    0, 0, gr70, gr71        
  2000a74:  036147cc  const    gr71, $61cc             
  2000a78:  024c4700  consth   gr71, $4c00             
  2000a7c:  16004747  load     0, 0, gr71, gr71        
  2000a80:  be004746  mttlb    gr71, gr70              
  2000a84:  15474701  add      gr71, gr71, $01         
  2000a88:  be004746  mttlb    gr71, gr70              
  2000a8c:  8c000000  iretinv                          
L_2000a90:
  2000a90:  81474015  sll      gr71, gr64, $15            ; [delay slot]
  2000a94:  ac004704  jmpt     gr71, $2000aa4             ; -> L_2000aa4
  2000a98:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000a9c:  a007005b  jmp      $2002808                   ; -> L_2002808
  2000aa0:  03004d9f  const    gr77, $009f                ; [delay slot]
L_2000aa4:
  2000aa4:  0368444c  const    gr68, $684c             
  2000aa8:  024c4400  consth   gr68, $4c00             
  2000aac:  16004644  load     0, 0, gr70, gr68        
  2000ab0:  15464601  add      gr70, gr70, $01         
  2000ab4:  1e004644  store    0, 0, gr70, gr68        
  2000ab8:  03204500  const    gr69, $2000             
  2000abc:  92434345  or       gr67, gr67, gr69        
  2000ac0:  ce000143  mtsr     OPS, gr67               
  2000ac4:  61464600  cpeq     gr70, gr70, $00         
  2000ac8:  ac004603  jmpt     gr70, $2000ad4             ; -> L_2000ad4
  2000acc:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000ad0:  88000000  iret                             
L_2000ad4:
  2000ad4:  15444404  add      gr68, gr68, $04            ; [delay slot]
  2000ad8:  16004644  load     0, 0, gr70, gr68        
  2000adc:  15464601  add      gr70, gr70, $01         
  2000ae0:  1e004644  store    0, 0, gr70, gr68        
  2000ae4:  88000000  iret                             
*  VECTOR 68 -- ASSERTION / BREAKPOINT: backs PC0/PC1 up by one instruction, reason $A0
  2000ae8:  c6430a00  mfsr     gr67, PC0                  ; [delay slot]
  2000aec:  25434304  sub      gr67, gr67, $04         
  2000af0:  ce000a43  mtsr     PC0, gr67               
  2000af4:  c6430b00  mfsr     gr67, PC1               
  2000af8:  25434304  sub      gr67, gr67, $04         
  2000afc:  ce000b43  mtsr     PC1, gr67               
  2000b00:  a0070042  jmp      $2002808                   ; -> L_2002808
  2000b04:  03004da0  const    gr77, $00a0                ; [delay slot]
*  VECTOR 16 -- INTR0: runs the handler enabled at $4C00617C via $20010A4, else reason $96
  2000b08:  c6540600  mfsr     gr84, CHC               
  2000b0c:  81555415  sll      gr85, gr84, $15         
  2000b10:  a4005504  jmpf     gr85, $2000b20             ; -> L_2000b20
  2000b14:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2000b18:  ce000654  mtsr     CHC, gr84               
  2000b1c:  88000000  iret                             
L_2000b20:
  2000b20:  0361477c  const    gr71, $617c                ; [delay slot]
  2000b24:  024c4700  consth   gr71, $4c00             
  2000b28:  16004847  load     0, 0, gr72, gr71        
  2000b2c:  61454800  cpeq     gr69, gr72, $00         
  2000b30:  ac004504  jmpt     gr69, $2000b40             ; -> L_2000b40
  2000b34:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000b38:  a001005b  jmp      $20010a4                   ; -> L_20010a4
  2000b3c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2000b40:
  2000b40:  a0070032  jmp      $2002808                   ; -> L_2002808
  2000b44:  03004d96  const    gr77, $0096                ; [delay slot]
*  VECTOR 17 -- INTR1: clears the source ($44000058 <- 0), handler word $4C006180 via $20010A4, else reason $97
  2000b48:  c6540600  mfsr     gr84, CHC               
  2000b4c:  81555415  sll      gr85, gr84, $15         
  2000b50:  a4005504  jmpf     gr85, $2000b60             ; -> L_2000b60
  2000b54:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2000b58:  ce000654  mtsr     CHC, gr84               
  2000b5c:  88000000  iret                             
L_2000b60:
  2000b60:  03004758  const    gr71, $0058                ; [delay slot]
  2000b64:  02444700  consth   gr71, $4400             
  2000b68:  03004600  const    gr70, $0000             
  2000b6c:  1e004647  store    0, 0, gr70, gr71        
  2000b70:  03614780  const    gr71, $6180             
  2000b74:  024c4700  consth   gr71, $4c00             
  2000b78:  16004847  load     0, 0, gr72, gr71        
  2000b7c:  61454800  cpeq     gr69, gr72, $00         
  2000b80:  ac004504  jmpt     gr69, $2000b90             ; -> L_2000b90
  2000b84:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000b88:  a0010047  jmp      $20010a4                   ; -> L_20010a4
  2000b8c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2000b90:
  2000b90:  a007001e  jmp      $2002808                   ; -> L_2002808
  2000b94:  03004d97  const    gr77, $0097                ; [delay slot]
*  VECTOR 18 -- INTR2: handler word $4C006184.  If none is registered it runs
*  the VidComm service $2000C14 and iretinv's; otherwise it acknowledges the
*  status registers ($44000050/54, only where $44000064/68 say they are set)
*  and dispatches the handler through $20010A4.
  2000b98:  c6540600  mfsr     gr84, CHC               
  2000b9c:  81555415  sll      gr85, gr84, $15         
  2000ba0:  a4005504  jmpf     gr85, $2000bb0             ; -> L_2000bb0
  2000ba4:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2000ba8:  ce000654  mtsr     CHC, gr84               
  2000bac:  88000000  iret                             
L_2000bb0:
  2000bb0:  03614784  const    gr71, $6184                ; [delay slot]
  2000bb4:  024c4700  consth   gr71, $4c00             
  2000bb8:  16004847  load     0, 0, gr72, gr71        
  2000bbc:  61474800  cpeq     gr71, gr72, $00         
  2000bc0:  ac004712  jmpt     gr71, $2000c08             ; -> L_2000c08
  2000bc4:  03004600  const    gr70, $0000                ; [delay slot]
  2000bc8:  03004764  const    gr71, $0064             
  2000bcc:  02444700  consth   gr71, $4400             
  2000bd0:  16004747  load     0, 0, gr71, gr71        
  2000bd4:  a4004704  jmpf     gr71, $2000be4             ; -> L_2000be4
  2000bd8:  03004750  const    gr71, $0050                ; [delay slot]
  2000bdc:  02444700  consth   gr71, $4400             
  2000be0:  1e004647  store    0, 0, gr70, gr71        
L_2000be4:
  2000be4:  03004768  const    gr71, $0068             
  2000be8:  02444700  consth   gr71, $4400             
  2000bec:  16004747  load     0, 0, gr71, gr71        
  2000bf0:  a4004704  jmpf     gr71, $2000c00             ; -> L_2000c00
  2000bf4:  03004754  const    gr71, $0054                ; [delay slot]
  2000bf8:  02444700  consth   gr71, $4400             
  2000bfc:  1e004647  store    0, 0, gr70, gr71        
L_2000c00:
  2000c00:  a0010029  jmp      $20010a4                   ; -> L_20010a4
  2000c04:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2000c08:
  2000c08:  a8004503  call     gr69, $2000c14             ; -> L_2000c14
  2000c0c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000c10:  8c000000  iretinv                          
* ==================================================================
*  $2000C14 -- VIDEO COMMAND SERVICE ($4C007300 VidComm).  Run from INTR2 (when no
*  handler is registered) and from the mailbox poll.  Returns at once if the
*  status register $44000064 is clear; otherwise acknowledges ($44000050 <- 0),
*  jumps to kernel init if the restart word PublicIn+$3D4 is set, and reads the
*  command word (+00, cleared), the frame-buffer base (+08), row bytes (+0C),
*  vertical size (+14) and the PAGE CONFIGURATION (+1C).  If command bit 0 is set
*  it writes 0 to +04 and spins until the host writes a non-zero value there (the
*  host retimes the clock meanwhile).  A 32-step multiply (Q register) gives the
*  frame-buffer size from row bytes x (rows + 4).  Page configuration 1 or 2 then
*  runs an in-place PERMUTATION of the 2 MB video window at $4C000000: for each of
*  $200 blocks of $1000 bytes ($1000 apart) it copies the block's $400 words to a
*  buffer at $40003800 and writes them back with a 16-byte stride in four passes
*  (word offsets 0, 8, 4, $C for configuration 2; the inverse order for 1), i.e.
*  it converts the window between a linear and a 4-way word-interleaved layout.
*  Other values skip the copy.  Afterwards it waits for $4400007C/$44000080 to
*  go idle, flushes the hardware TLB ('mttlb' over $1F pairs) and the software
*  tables ($4C002818, $4C002CA8) and re-enters kernel init ($2001FFC).  gr96..
*  gr103 are saved/restored through $40003400.
* ==================================================================
L_2000c14:
  2000c14:  03004600  const    gr70, $0000                ; [delay slot]
  2000c18:  03004764  const    gr71, $0064             
  2000c1c:  02444700  consth   gr71, $4400             
  2000c20:  16004747  load     0, 0, gr71, gr71        
  2000c24:  a401470c  jmpf     gr71, $2001054             ; -> L_2001054
  2000c28:  03004750  const    gr71, $0050                ; [delay slot]
  2000c2c:  02444700  consth   gr71, $4400             
  2000c30:  1e004647  store    0, 0, gr70, gr71        
  2000c34:  036747d4  const    gr71, $67d4             
  2000c38:  024c4700  consth   gr71, $4c00             
  2000c3c:  16004747  load     0, 0, gr71, gr71        
  2000c40:  ac0447ef  jmpt     gr71, $2001ffc             ; -> L_2001ffc
  2000c44:  03734700  const    gr71, $7300                ; [delay slot]
  2000c48:  024c4700  consth   gr71, $4c00             
  2000c4c:  16004947  load     0, 0, gr73, gr71        
  2000c50:  a4014901  jmpf     gr73, $2001054             ; -> L_2001054
  2000c54:  03004600  const    gr70, $0000                ; [delay slot]
  2000c58:  1e004647  store    0, 0, gr70, gr71        
  2000c5c:  8147491f  sll      gr71, gr73, $1f         
  2000c60:  a4004708  jmpf     gr71, $2000c80             ; -> L_2000c80
  2000c64:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000c68:  03734704  const    gr71, $7304             
  2000c6c:  024c4700  consth   gr71, $4c00             
  2000c70:  1e004647  store    0, 0, gr70, gr71        
L_2000c74:
  2000c74:  16004847  load     0, 0, gr72, gr71        
  2000c78:  a4ff48ff  jmpf     gr72, $2000c74             ; -> L_2000c74
  2000c7c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2000c80:
  2000c80:  03735108  const    gr81, $7308             
  2000c84:  024c5100  consth   gr81, $4c00             
  2000c88:  16004a51  load     0, 0, gr74, gr81        
  2000c8c:  15515104  add      gr81, gr81, $04         
  2000c90:  16004b51  load     0, 0, gr75, gr81        
  2000c94:  15515104  add      gr81, gr81, $04         
  2000c98:  16004c51  load     0, 0, gr76, gr81        
  2000c9c:  15515104  add      gr81, gr81, $04         
  2000ca0:  16004d51  load     0, 0, gr77, gr81        
  2000ca4:  0373511c  const    gr81, $731c             
  2000ca8:  024c5100  consth   gr81, $4c00             
  2000cac:  16004451  load     0, 0, gr68, gr81        
  2000cb0:  15474d04  add      gr71, gr77, $04         
  2000cb4:  ce008347  mtsr     Q, gr71                 
  2000cb8:  65474b00  mul      gr71, gr75, $00         
  2000cbc:  64474b47  mul      gr71, gr75, gr71        
  2000cc0:  64474b47  mul      gr71, gr75, gr71        
  2000cc4:  64474b47  mul      gr71, gr75, gr71        
  2000cc8:  64474b47  mul      gr71, gr75, gr71        
  2000ccc:  64474b47  mul      gr71, gr75, gr71        
  2000cd0:  64474b47  mul      gr71, gr75, gr71        
  2000cd4:  64474b47  mul      gr71, gr75, gr71        
  2000cd8:  64474b47  mul      gr71, gr75, gr71        
  2000cdc:  64474b47  mul      gr71, gr75, gr71        
  2000ce0:  64474b47  mul      gr71, gr75, gr71        
  2000ce4:  64474b47  mul      gr71, gr75, gr71        
  2000ce8:  64474b47  mul      gr71, gr75, gr71        
  2000cec:  64474b47  mul      gr71, gr75, gr71        
  2000cf0:  64474b47  mul      gr71, gr75, gr71        
  2000cf4:  64474b47  mul      gr71, gr75, gr71        
  2000cf8:  64474b47  mul      gr71, gr75, gr71        
  2000cfc:  64474b47  mul      gr71, gr75, gr71        
  2000d00:  64474b47  mul      gr71, gr75, gr71        
  2000d04:  64474b47  mul      gr71, gr75, gr71        
  2000d08:  64474b47  mul      gr71, gr75, gr71        
  2000d0c:  64474b47  mul      gr71, gr75, gr71        
  2000d10:  64474b47  mul      gr71, gr75, gr71        
  2000d14:  64474b47  mul      gr71, gr75, gr71        
  2000d18:  64474b47  mul      gr71, gr75, gr71        
  2000d1c:  64474b47  mul      gr71, gr75, gr71        
  2000d20:  64474b47  mul      gr71, gr75, gr71        
  2000d24:  64474b47  mul      gr71, gr75, gr71        
  2000d28:  64474b47  mul      gr71, gr75, gr71        
  2000d2c:  64474b47  mul      gr71, gr75, gr71        
  2000d30:  64474b47  mul      gr71, gr75, gr71        
  2000d34:  66474b47  mull     gr71, gr75, gr71        
  2000d38:  c6478300  mfsr     gr71, Q                 
  2000d3c:  1443474a  add      gr67, gr71, gr74        
  2000d40:  61474400  cpeq     gr71, gr68, $00         
  2000d44:  ac0047af  jmpt     gr71, $2001000             ; -> L_2001000
  2000d48:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000d4c:  03344800  const    gr72, $3400             
  2000d50:  02404800  consth   gr72, $4000             
  2000d54:  81464800  sll      gr70, gr72, $00         
  2000d58:  1e006046  store    0, 0, gr96, gr70        
  2000d5c:  15464604  add      gr70, gr70, $04         
  2000d60:  1e006146  store    0, 0, gr97, gr70        
  2000d64:  15464604  add      gr70, gr70, $04         
  2000d68:  1e006246  store    0, 0, gr98, gr70        
  2000d6c:  15464604  add      gr70, gr70, $04         
  2000d70:  1e006346  store    0, 0, gr99, gr70        
  2000d74:  15464604  add      gr70, gr70, $04         
  2000d78:  1e006446  store    0, 0, gr100, gr70       
  2000d7c:  15464604  add      gr70, gr70, $04         
  2000d80:  1e006546  store    0, 0, gr101, gr70       
  2000d84:  15464604  add      gr70, gr70, $04         
  2000d88:  1e006646  store    0, 0, gr102, gr70       
  2000d8c:  15464604  add      gr70, gr70, $04         
  2000d90:  1e006746  store    0, 0, gr103, gr70       
  2000d94:  15464604  add      gr70, gr70, $04         
  2000d98:  030166fe  const    gr102, $01fe            
  2000d9c:  03006400  const    gr100, $0000            
  2000da0:  024c6400  consth   gr100, $4c00            
  2000da4:  03046500  const    gr101, $0400            
  2000da8:  14654865  add      gr101, gr72, gr101      
  2000dac:  61474401  cpeq     gr71, gr68, $01         
  2000db0:  ac004737  jmpt     gr71, $2000e8c             ; -> L_2000e8c
  2000db4:  61474402  cpeq     gr71, gr68, $02            ; [delay slot]
  2000db8:  a4004767  jmpf     gr71, $2000f54             ; -> L_2000f54
L_2000dbc:
  2000dbc:  81606400  sll      gr96, gr100, $00           ; [delay slot]
  2000dc0:  81616500  sll      gr97, gr101, $00        
  2000dc4:  030363fe  const    gr99, $03fe             
L_2000dc8:
  2000dc8:  16006260  load     0, 0, gr98, gr96        
  2000dcc:  15606004  add      gr96, gr96, $04         
  2000dd0:  1e006261  store    0, 0, gr98, gr97        
  2000dd4:  b4ff63fd  jmpfdec  gr99, $2000dc8             ; -> L_2000dc8
  2000dd8:  15616104  add      gr97, gr97, $04            ; [delay slot]
  2000ddc:  81606500  sll      gr96, gr101, $00        
  2000de0:  81616400  sll      gr97, gr100, $00        
  2000de4:  030063fe  const    gr99, $00fe             
L_2000de8:
  2000de8:  16006260  load     0, 0, gr98, gr96        
  2000dec:  15606004  add      gr96, gr96, $04         
  2000df0:  1e006261  store    0, 0, gr98, gr97        
  2000df4:  b4ff63fd  jmpfdec  gr99, $2000de8             ; -> L_2000de8
  2000df8:  15616110  add      gr97, gr97, $10            ; [delay slot]
  2000dfc:  15616408  add      gr97, gr100, $08        
  2000e00:  030063fe  const    gr99, $00fe             
L_2000e04:
  2000e04:  16006260  load     0, 0, gr98, gr96        
  2000e08:  15606004  add      gr96, gr96, $04         
  2000e0c:  1e006261  store    0, 0, gr98, gr97        
  2000e10:  b4ff63fd  jmpfdec  gr99, $2000e04             ; -> L_2000e04
  2000e14:  15616110  add      gr97, gr97, $10            ; [delay slot]
  2000e18:  15616404  add      gr97, gr100, $04        
  2000e1c:  030063fe  const    gr99, $00fe             
L_2000e20:
  2000e20:  16006260  load     0, 0, gr98, gr96        
  2000e24:  15606004  add      gr96, gr96, $04         
  2000e28:  1e006261  store    0, 0, gr98, gr97        
  2000e2c:  b4ff63fd  jmpfdec  gr99, $2000e20             ; -> L_2000e20
  2000e30:  15616110  add      gr97, gr97, $10            ; [delay slot]
  2000e34:  1561640c  add      gr97, gr100, $0c        
  2000e38:  030063fe  const    gr99, $00fe             
L_2000e3c:
  2000e3c:  16006260  load     0, 0, gr98, gr96        
  2000e40:  15606004  add      gr96, gr96, $04         
  2000e44:  1e006261  store    0, 0, gr98, gr97        
  2000e48:  b4ff63fd  jmpfdec  gr99, $2000e3c             ; -> L_2000e3c
  2000e4c:  15616110  add      gr97, gr97, $10            ; [delay slot]
  2000e50:  03106300  const    gr99, $1000             
  2000e54:  b4ff66da  jmpfdec  gr102, $2000dbc            ; -> L_2000dbc
  2000e58:  14646463  add      gr100, gr100, gr99         ; [delay slot]
L_2000e5c:
  2000e5c:  0300447c  const    gr68, $007c             
  2000e60:  02444400  consth   gr68, $4400             
  2000e64:  16006244  load     0, 0, gr98, gr68        
  2000e68:  a4ff62fd  jmpf     gr98, $2000e5c             ; -> L_2000e5c
L_2000e6c:
  2000e6c:  03004480  const    gr68, $0080                ; [delay slot]
  2000e70:  02444400  consth   gr68, $4400             
  2000e74:  16006244  load     0, 0, gr98, gr68        
  2000e78:  acff62fd  jmpt     gr98, $2000e6c             ; -> L_2000e6c
  2000e7c:  03ff43ff  const    gr67, $ffff                ; [delay slot]
  2000e80:  027f43ff  consth   gr67, $7fff             
  2000e84:  a0000034  jmp      $2000f54                   ; -> L_2000f54
  2000e88:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2000e8c:
  2000e8c:  81606400  sll      gr96, gr100, $00        
  2000e90:  81616500  sll      gr97, gr101, $00        
  2000e94:  030363fe  const    gr99, $03fe             
L_2000e98:
  2000e98:  16006260  load     0, 0, gr98, gr96        
  2000e9c:  15606004  add      gr96, gr96, $04         
  2000ea0:  1e006261  store    0, 0, gr98, gr97        
  2000ea4:  b4ff63fd  jmpfdec  gr99, $2000e98             ; -> L_2000e98
  2000ea8:  15616104  add      gr97, gr97, $04            ; [delay slot]
  2000eac:  15606500  add      gr96, gr101, $00        
  2000eb0:  15616400  add      gr97, gr100, $00        
  2000eb4:  030063fe  const    gr99, $00fe             
L_2000eb8:
  2000eb8:  16006260  load     0, 0, gr98, gr96        
  2000ebc:  15606010  add      gr96, gr96, $10         
  2000ec0:  1e006261  store    0, 0, gr98, gr97        
  2000ec4:  b4ff63fd  jmpfdec  gr99, $2000eb8             ; -> L_2000eb8
  2000ec8:  15616104  add      gr97, gr97, $04            ; [delay slot]
  2000ecc:  15606508  add      gr96, gr101, $08        
  2000ed0:  030063fe  const    gr99, $00fe             
L_2000ed4:
  2000ed4:  16006260  load     0, 0, gr98, gr96        
  2000ed8:  15606010  add      gr96, gr96, $10         
  2000edc:  1e006261  store    0, 0, gr98, gr97        
  2000ee0:  b4ff63fd  jmpfdec  gr99, $2000ed4             ; -> L_2000ed4
  2000ee4:  15616104  add      gr97, gr97, $04            ; [delay slot]
  2000ee8:  15606504  add      gr96, gr101, $04        
  2000eec:  030063fe  const    gr99, $00fe             
L_2000ef0:
  2000ef0:  16006260  load     0, 0, gr98, gr96        
  2000ef4:  15606010  add      gr96, gr96, $10         
  2000ef8:  1e006261  store    0, 0, gr98, gr97        
  2000efc:  b4ff63fd  jmpfdec  gr99, $2000ef0             ; -> L_2000ef0
  2000f00:  15616104  add      gr97, gr97, $04            ; [delay slot]
  2000f04:  1560650c  add      gr96, gr101, $0c        
  2000f08:  030063fe  const    gr99, $00fe             
L_2000f0c:
  2000f0c:  16006260  load     0, 0, gr98, gr96        
  2000f10:  15606010  add      gr96, gr96, $10         
  2000f14:  1e006261  store    0, 0, gr98, gr97        
  2000f18:  b4ff63fd  jmpfdec  gr99, $2000f0c             ; -> L_2000f0c
  2000f1c:  15616104  add      gr97, gr97, $04            ; [delay slot]
  2000f20:  03106300  const    gr99, $1000             
  2000f24:  b4ff66da  jmpfdec  gr102, $2000e8c            ; -> L_2000e8c
  2000f28:  14646463  add      gr100, gr100, gr99         ; [delay slot]
L_2000f2c:
  2000f2c:  0300447c  const    gr68, $007c             
  2000f30:  02444400  consth   gr68, $4400             
  2000f34:  16006244  load     0, 0, gr98, gr68        
  2000f38:  acff62fd  jmpt     gr98, $2000f2c             ; -> L_2000f2c
L_2000f3c:
  2000f3c:  03004480  const    gr68, $0080                ; [delay slot]
  2000f40:  02444400  consth   gr68, $4400             
  2000f44:  16006244  load     0, 0, gr98, gr68        
  2000f48:  a4ff62fd  jmpf     gr98, $2000f3c             ; -> L_2000f3c
  2000f4c:  03ff43ff  const    gr67, $ffff                ; [delay slot]
  2000f50:  027f43ff  consth   gr67, $7fff             
L_2000f54:
  2000f54:  03286118  const    gr97, $2818             
  2000f58:  024c6100  consth   gr97, $4c00             
  2000f5c:  0300631e  const    gr99, $001e             
  2000f60:  03004400  const    gr68, $0000             
  2000f64:  03004600  const    gr70, $0000             
L_2000f68:
  2000f68:  1e004661  store    0, 0, gr70, gr97        
  2000f6c:  15616104  add      gr97, gr97, $04         
  2000f70:  be004446  mttlb    gr68, gr70              
  2000f74:  15444402  add      gr68, gr68, $02         
  2000f78:  be004446  mttlb    gr68, gr70              
  2000f7c:  b4ff63fb  jmpfdec  gr99, $2000f68             ; -> L_2000f68
  2000f80:  15444402  add      gr68, gr68, $02            ; [delay slot]
  2000f84:  03006332  const    gr99, $0032             
  2000f88:  032c61a8  const    gr97, $2ca8             
  2000f8c:  024c6100  consth   gr97, $4c00             
L_2000f90:
  2000f90:  1e004661  store    0, 0, gr70, gr97        
  2000f94:  b4ff63ff  jmpfdec  gr99, $2000f90             ; -> L_2000f90
  2000f98:  15616104  add      gr97, gr97, $04            ; [delay slot]
  2000f9c:  03286110  const    gr97, $2810             
  2000fa0:  024c6100  consth   gr97, $4c00             
  2000fa4:  1e004661  store    0, 0, gr70, gr97        
  2000fa8:  81464800  sll      gr70, gr72, $00         
  2000fac:  16006046  load     0, 0, gr96, gr70        
  2000fb0:  15464604  add      gr70, gr70, $04         
  2000fb4:  16006146  load     0, 0, gr97, gr70        
  2000fb8:  15464604  add      gr70, gr70, $04         
  2000fbc:  16006246  load     0, 0, gr98, gr70        
  2000fc0:  15464604  add      gr70, gr70, $04         
  2000fc4:  16006346  load     0, 0, gr99, gr70        
  2000fc8:  15464604  add      gr70, gr70, $04         
  2000fcc:  16006446  load     0, 0, gr100, gr70       
  2000fd0:  15464604  add      gr70, gr70, $04         
  2000fd4:  16006546  load     0, 0, gr101, gr70       
  2000fd8:  15464604  add      gr70, gr70, $04         
  2000fdc:  16006646  load     0, 0, gr102, gr70       
  2000fe0:  15464604  add      gr70, gr70, $04         
  2000fe4:  16006746  load     0, 0, gr103, gr70       
  2000fe8:  15464604  add      gr70, gr70, $04         
  2000fec:  03004600  const    gr70, $0000             
  2000ff0:  03734704  const    gr71, $7304             
  2000ff4:  024c4700  consth   gr71, $4c00             
  2000ff8:  a000000b  jmp      $2001024                   ; -> L_2001024
  2000ffc:  1e004647  store    0, 0, gr70, gr71           ; [delay slot]
L_2001000:
  2001000:  8147491f  sll      gr71, gr73, $1f         
  2001004:  ac004708  jmpt     gr71, $2001024             ; -> L_2001024
  2001008:  03004600  const    gr70, $0000                ; [delay slot]
  200100c:  03734704  const    gr71, $7304             
  2001010:  024c4700  consth   gr71, $4c00             
  2001014:  1e004647  store    0, 0, gr70, gr71        
L_2001018:
  2001018:  16004847  load     0, 0, gr72, gr71        
  200101c:  a4ff48ff  jmpf     gr72, $2001018             ; -> L_2001018
  2001020:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2001024:
  2001024:  0368471c  const    gr71, $681c             
  2001028:  024c4700  consth   gr71, $4c00             
  200102c:  1e004a47  store    0, 0, gr74, gr71        
  2001030:  03684724  const    gr71, $6824             
  2001034:  024c4700  consth   gr71, $4c00             
  2001038:  1e004b47  store    0, 0, gr75, gr71        
  200103c:  03684720  const    gr71, $6820             
  2001040:  024c4700  consth   gr71, $4c00             
  2001044:  1e004c47  store    0, 0, gr76, gr71        
  2001048:  03684728  const    gr71, $6828             
  200104c:  024c4700  consth   gr71, $4c00             
  2001050:  1e004d47  store    0, 0, gr77, gr71        
*  common return of $2000C14 (jmpi gr69); the next line reports reason $98
L_2001054:
  2001054:  c0000045  jmpi     gr69                    
  2001058:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  200105c:  a00500eb  jmp      $2002808                   ; -> L_2002808
  2001060:  03004d98  const    gr77, $0098                ; [delay slot]
*  VECTOR 19 -- INTR3: handler word $4C006188 via $20010A4, else reason $99
  2001064:  c6540600  mfsr     gr84, CHC               
  2001068:  81555415  sll      gr85, gr84, $15         
  200106c:  a4005504  jmpf     gr85, $200107c             ; -> L_200107c
  2001070:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2001074:  ce000654  mtsr     CHC, gr84               
  2001078:  88000000  iret                             
L_200107c:
  200107c:  03614788  const    gr71, $6188                ; [delay slot]
  2001080:  024c4700  consth   gr71, $4c00             
  2001084:  16004847  load     0, 0, gr72, gr71        
  2001088:  61454800  cpeq     gr69, gr72, $00         
  200108c:  ac004504  jmpt     gr69, $200109c             ; -> L_200109c
  2001090:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001094:  a0000004  jmp      $20010a4                   ; -> L_20010a4
  2001098:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_200109c:
  200109c:  a00500db  jmp      $2002808                   ; -> L_2002808
  20010a0:  03004d99  const    gr77, $0099                ; [delay slot]
* ------------------------------------------------------------------
*  $20010A4  INTERRUPT DISPATCH: if no dispatch is already active ($4C00618C)
*  it marks one active, re-enables interrupts, saves PC0/PC1/OPS/CHA/CHC/CHD
*  and gr96..gr99 in a frame at $4C00618C+4, sets OPS = $086E and iret's to
*  the registered handler (address in gr72).
* ------------------------------------------------------------------
L_20010a4:
  20010a4:  0361468c  const    gr70, $618c             
  20010a8:  024c4600  consth   gr70, $4c00             
  20010ac:  16004746  load     0, 0, gr71, gr70        
  20010b0:  ac004724  jmpt     gr71, $2001140             ; -> L_2001140
  20010b4:  01ff47ff  constn   gr71, $ffff                ; [delay slot]
  20010b8:  1e004746  store    0, 0, gr71, gr70        
  20010bc:  15464604  add      gr70, gr70, $04         
  20010c0:  0404027f  mtsrim   CPS, $047f              
  20010c4:  c6580a00  mfsr     gr88, PC0               
  20010c8:  c6590b00  mfsr     gr89, PC1               
  20010cc:  c6520100  mfsr     gr82, OPS               
  20010d0:  c6560400  mfsr     gr86, CHA               
  20010d4:  c65a0600  mfsr     gr90, CHC               
  20010d8:  c6570500  mfsr     gr87, CHD               
  20010dc:  1e005846  store    0, 0, gr88, gr70        
  20010e0:  15464604  add      gr70, gr70, $04         
  20010e4:  1e005946  store    0, 0, gr89, gr70        
  20010e8:  15464604  add      gr70, gr70, $04         
  20010ec:  1e005246  store    0, 0, gr82, gr70        
  20010f0:  15464604  add      gr70, gr70, $04         
  20010f4:  1e005646  store    0, 0, gr86, gr70        
  20010f8:  15464604  add      gr70, gr70, $04         
  20010fc:  1e005a46  store    0, 0, gr90, gr70        
  2001100:  15464604  add      gr70, gr70, $04         
  2001104:  1e005746  store    0, 0, gr87, gr70        
  2001108:  15464604  add      gr70, gr70, $04         
  200110c:  1e006046  store    0, 0, gr96, gr70        
  2001110:  15464604  add      gr70, gr70, $04         
  2001114:  1e006146  store    0, 0, gr97, gr70        
  2001118:  15464604  add      gr70, gr70, $04         
  200111c:  1e006246  store    0, 0, gr98, gr70        
  2001120:  15464604  add      gr70, gr70, $04         
  2001124:  1e006346  store    0, 0, gr99, gr70        
  2001128:  15464604  add      gr70, gr70, $04         
  200112c:  0408016e  mtsrim   OPS, $086e              
  2001130:  ce000b48  mtsr     PC1, gr72               
  2001134:  15484804  add      gr72, gr72, $04         
  2001138:  ce000a48  mtsr     PC0, gr72               
  200113c:  88000000  iret                             
L_2001140:
  2001140:  88000000  iret                                ; [delay slot]
*  VECTOR 20 -- TRAP0: reason $9A
  2001144:  c6540600  mfsr     gr84, CHC                  ; [delay slot]
  2001148:  81555415  sll      gr85, gr84, $15         
  200114c:  a4005504  jmpf     gr85, $200115c             ; -> L_200115c
  2001150:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2001154:  ce000654  mtsr     CHC, gr84               
  2001158:  88000000  iret                             
L_200115c:
  200115c:  a00500ab  jmp      $2002808                   ; -> L_2002808   ; [delay slot]
  2001160:  03004d9a  const    gr77, $009a                ; [delay slot]
*  VECTOR 21 -- TRAP1: reason $9B
  2001164:  c6540600  mfsr     gr84, CHC               
  2001168:  81555415  sll      gr85, gr84, $15         
  200116c:  a4005504  jmpf     gr85, $200117c             ; -> L_200117c
  2001170:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2001174:  ce000654  mtsr     CHC, gr84               
  2001178:  88000000  iret                             
L_200117c:
  200117c:  a00500a3  jmp      $2002808                   ; -> L_2002808   ; [delay slot]
  2001180:  03004d9b  const    gr77, $009b                ; [delay slot]
*  VECTOR 64 -- REGISTER STACK SPILL (overflow): checks the new bound
*  against the stack limit (reason $A5 if exceeded), then storem's
*  lr0.. into the memory stack and moves gr126/gr127.
  2001184:  24797e01  sub      gr121, gr126, gr1       
  2001188:  247e7f79  sub      gr126, gr127, gr121     
  200118c:  46457e41  cpleu    gr69, gr126, gr65       
  2001190:  ac004508  jmpt     gr69, $20011b0             ; -> L_20011b0
  2001194:  83797902  srl      gr121, gr121, $02          ; [delay slot]
  2001198:  25797901  sub      gr121, gr121, $01       
  200119c:  ce008779  mtsr     CR, gr121               
  20011a0:  3e00807e  storem   0, 0, lr0, gr126        
  20011a4:  817f7e00  sll      gr127, gr126, $00       
  20011a8:  817e0100  sll      gr126, gr1, $00         
  20011ac:  88000000  iret                             
L_20011b0:
  20011b0:  a0050096  jmp      $2002808                   ; -> L_2002808   ; [delay slot]
  20011b4:  03004da5  const    gr77, $00a5                ; [delay slot]
*  VECTOR 65 -- REGISTER STACK FILL (underflow): loadm refills lr0.. from the memory stack
  20011b8:  03027900  const    gr121, $0200            
  20011bc:  9279797f  or       gr121, gr121, gr127     
  20011c0:  ce008179  mtsr     IPA, gr121              
  20011c4:  2479817f  sub      gr121, lr1, gr127       
  20011c8:  147e7e79  add      gr126, gr126, gr121     
  20011cc:  83797902  srl      gr121, gr121, $02       
  20011d0:  25797901  sub      gr121, gr121, $01       
  20011d4:  ce008779  mtsr     CR, gr121               
  20011d8:  81797f00  sll      gr121, gr127, $00       
  20011dc:  817f8100  sll      gr127, lr1, $00         
  20011e0:  36000079  loadm    0, 0, gr0, gr121        
  20011e4:  88000000  iret                             
* ==================================================================
*  VECTOR 66 -- SERVICE CALL.  gr121 = service number; numbers $B6 ..
*  $B6+$D5 index the jump table at $4C002500 (probably the PrivNZ section,
*  pointers to the stubs below); anything else returns gr96 = $FFFFFFD6, gr121 = 0.
*  Arguments in lr2/lr3, result in gr96.  Service stubs that follow:
*    $2001224  wait for / clear the INTR2 status ($44000054 <- all-ones,
*              poll $44000068, then clear)       $2001250  gr96 = [$4C00682C]
*    $2001260  read/modify the word at $4C00643C (and mirror it to $46000000)
*              $2001294  restart kernel ($2001FFC) if gr64 bit 28 is set
*    $20012AC  free stack/heap space = gr127 - $3000 - gr65 ... (more below)
* ==================================================================
  20011e8:  157a7900  add      gr122, gr121, $00          ; [delay slot]
  20011ec:  257a7ab6  sub      gr122, gr122, $b6       
  20011f0:  ac007a0a  jmpt     gr122, $2001218            ; -> L_2001218
  20011f4:  4d797ad6  cpge     gr121, gr122, $d6          ; [delay slot]
  20011f8:  ac007908  jmpt     gr121, $2001218            ; -> L_2001218
  20011fc:  817a7a02  sll      gr122, gr122, $02          ; [delay slot]
  2001200:  03254600  const    gr70, $2500             
  2001204:  024c4600  consth   gr70, $4c00             
  2001208:  147a467a  add      gr122, gr70, gr122      
  200120c:  16007a7a  load     0, 0, gr122, gr122      
  2001210:  c000007a  jmpi     gr122                   
  2001214:  60797979  cpeq     gr121, gr121, gr121        ; [delay slot]
L_2001218:
  2001218:  01ff60d6  constn   gr96, $ffd6             
  200121c:  03007900  const    gr121, $0000            
  2001220:  88000000  iret                             
  2001224:  03004754  const    gr71, $0054                ; [delay slot]
  2001228:  02444700  consth   gr71, $4400             
  200122c:  02ff48ff  consth   gr72, $ffff             
  2001230:  1e004847  store    0, 0, gr72, gr71        
  2001234:  03004968  const    gr73, $0068             
  2001238:  02444900  consth   gr73, $4400             
L_200123c:
  200123c:  16004a49  load     0, 0, gr74, gr73        
  2001240:  a4ff4aff  jmpf     gr74, $200123c             ; -> L_200123c
  2001244:  03004800  const    gr72, $0000                ; [delay slot]
  2001248:  1e004847  store    0, 0, gr72, gr71        
  200124c:  88000000  iret                             
  2001250:  0368472c  const    gr71, $682c                ; [delay slot]
  2001254:  024c4700  consth   gr71, $4c00             
  2001258:  16006047  load     0, 0, gr96, gr71        
  200125c:  88000000  iret                             
  2001260:  0364463c  const    gr70, $643c                ; [delay slot]
  2001264:  024c4600  consth   gr70, $4c00             
  2001268:  16006046  load     0, 0, gr96, gr70        
  200126c:  ac008209  jmpt     lr2, $2001290              ; -> L_2001290
  2001270:  03004701  const    gr71, $0001                ; [delay slot]
  2001274:  80474782  sll      gr71, gr71, lr2         
  2001278:  9c476047  andn     gr71, gr96, gr71        
  200127c:  1e004746  store    0, 0, gr71, gr70        
  2001280:  81474710  sll      gr71, gr71, $10         
  2001284:  03004600  const    gr70, $0000             
  2001288:  02464600  consth   gr70, $4600             
  200128c:  1e004746  store    0, 0, gr71, gr70        
L_2001290:
  2001290:  88000000  iret                             
  2001294:  81474003  sll      gr71, gr64, $03            ; [delay slot]
  2001298:  a4004704  jmpf     gr71, $20012a8             ; -> L_20012a8
  200129c:  03006000  const    gr96, $0000                ; [delay slot]
  20012a0:  a0030057  jmp      $2001ffc                   ; -> L_2001ffc
  20012a4:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_20012a8:
  20012a8:  88000000  iret                             
  20012ac:  8145400b  sll      gr69, gr64, $0b            ; [delay slot]
  20012b0:  ac004506  jmpt     gr69, $20012c8             ; -> L_20012c8
  20012b4:  03304500  const    gr69, $3000                ; [delay slot]
  20012b8:  02004500  consth   gr69, $0000             
  20012bc:  24447f45  sub      gr68, gr127, gr69       
  20012c0:  24604441  sub      gr96, gr68, gr65        
  20012c4:  88000000  iret                             
L_20012c8:
  20012c8:  03644408  const    gr68, $6408                ; [delay slot]
  20012cc:  024c4400  consth   gr68, $4c00             
  20012d0:  16004444  load     0, 0, gr68, gr68        
  20012d4:  03104300  const    gr67, $1000             
  20012d8:  02004300  consth   gr67, $0000             
  20012dc:  24444443  sub      gr68, gr68, gr67        
  20012e0:  24604441  sub      gr96, gr68, gr65        
  20012e4:  88000000  iret                             
  20012e8:  03004680  const    gr70, $0080                ; [delay slot]
  20012ec:  02444600  consth   gr70, $4400             
  20012f0:  16004646  load     0, 0, gr70, gr70        
  20012f4:  a4004604  jmpf     gr70, $2001304             ; -> L_2001304
  20012f8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20012fc:  83828201  srl      lr2, lr2, $01           
  2001300:  83848401  srl      lr4, lr4, $01           
L_2001304:
  2001304:  61468200  cpeq     gr70, lr2, $00          
  2001308:  ac00460b  jmpt     gr70, $2001334             ; -> L_2001334
  200130c:  0368461c  const    gr70, $681c                ; [delay slot]
  2001310:  024c4600  consth   gr70, $4c00             
  2001314:  1e008246  store    0, 0, lr2, gr70         
  2001318:  03004600  const    gr70, $0000             
  200131c:  02444600  consth   gr70, $4400             
  2001320:  8148820a  sll      gr72, lr2, $0a          
  2001324:  03004712  const    gr71, $0012             
L_2001328:
  2001328:  1e004846  store    0, 0, gr72, gr70        
  200132c:  b4ff47ff  jmpfdec  gr71, $2001328             ; -> L_2001328
  2001330:  81484801  sll      gr72, gr72, $01            ; [delay slot]
L_2001334:
  2001334:  61468400  cpeq     gr70, lr4, $00          
  2001338:  ac00460b  jmpt     gr70, $2001364             ; -> L_2001364
  200133c:  03684624  const    gr70, $6824                ; [delay slot]
  2001340:  024c4600  consth   gr70, $4c00             
  2001344:  1e008446  store    0, 0, lr4, gr70         
  2001348:  030046a0  const    gr70, $00a0             
  200134c:  02444600  consth   gr70, $4400             
  2001350:  81488412  sll      gr72, lr4, $12          
  2001354:  0300470a  const    gr71, $000a             
L_2001358:
  2001358:  1e004846  store    0, 0, gr72, gr70        
  200135c:  b4ff47ff  jmpfdec  gr71, $2001358             ; -> L_2001358
  2001360:  81484801  sll      gr72, gr72, $01            ; [delay slot]
L_2001364:
  2001364:  03006000  const    gr96, $0000             
  2001368:  88000000  iret                             
  200136c:  01ff60ff  constn   gr96, $ffff                ; [delay slot]
  2001370:  88000000  iret                             
  2001374:  04008500  mtsrim   BP, $0000                  ; [delay slot]
  2001378:  03004700  const    gr71, $0000             
  200137c:  024647c0  consth   gr71, $46c0             
  2001380:  0c488282  inbyte   gr72, lr2, lr2          
  2001384:  1e014847  store    0, 1, gr72, gr71        
  2001388:  03004704  const    gr71, $0004             
  200138c:  024647c0  consth   gr71, $46c0             
  2001390:  0c488383  inbyte   gr72, lr3, lr3          
  2001394:  1e014847  store    0, 1, gr72, gr71        
  2001398:  0c488484  inbyte   gr72, lr4, lr4          
  200139c:  1e014847  store    0, 1, gr72, gr71        
  20013a0:  0c488585  inbyte   gr72, lr5, lr5          
  20013a4:  1e014847  store    0, 1, gr72, gr71        
  20013a8:  88000000  iret                             
  20013ac:  494782ff  cpgt     gr71, lr2, $ff             ; [delay slot]
  20013b0:  ac004715  jmpt     gr71, $2001404             ; -> L_2001404
  20013b4:  01ff60ff  constn   gr96, $ffff                ; [delay slot]
  20013b8:  03004900  const    gr73, $0000             
  20013bc:  02ff4900  consth   gr73, $ff00             
  20013c0:  04008500  mtsrim   BP, $0000               
  20013c4:  03004700  const    gr71, $0000             
  20013c8:  024647c0  consth   gr71, $46c0             
  20013cc:  0c488282  inbyte   gr72, lr2, lr2          
  20013d0:  1e014847  store    0, 1, gr72, gr71        
  20013d4:  03004704  const    gr71, $0004             
  20013d8:  024647c0  consth   gr71, $46c0             
  20013dc:  16006047  load     0, 0, gr96, gr71        
  20013e0:  83606008  srl      gr96, gr96, $08         
  20013e4:  16004847  load     0, 0, gr72, gr71        
  20013e8:  90484849  and      gr72, gr72, gr73        
  20013ec:  92606048  or       gr96, gr96, gr72        
  20013f0:  83606008  srl      gr96, gr96, $08         
  20013f4:  16004847  load     0, 0, gr72, gr71        
  20013f8:  90484849  and      gr72, gr72, gr73        
  20013fc:  92606048  or       gr96, gr96, gr72        
  2001400:  83606008  srl      gr96, gr96, $08         
L_2001404:
  2001404:  88000000  iret                             
  2001408:  03646000  const    gr96, $6400                ; [delay slot]
  200140c:  024c6000  consth   gr96, $4c00             
  2001410:  88000000  iret                             
  2001414:  8145400b  sll      gr69, gr64, $0b            ; [delay slot]
  2001418:  a4004510  jmpf     gr69, $2001458             ; -> L_2001458
  200141c:  03006000  const    gr96, $0000                ; [delay slot]
  2001420:  03314620  const    gr70, $3120             
  2001424:  024c4600  consth   gr70, $4c00             
  2001428:  16004746  load     0, 0, gr71, gr70        
  200142c:  14494782  add      gr73, gr71, lr2         
  2001430:  1e004946  store    0, 0, gr73, gr70        
  2001434:  03ff45ff  const    gr69, $ffff             
  2001438:  020f45ff  consth   gr69, $0fff             
  200143c:  90494945  and      gr73, gr73, gr69        
  2001440:  03004500  const    gr69, $0000             
  2001444:  020c4500  consth   gr69, $0c00             
  2001448:  42454945  cpltu    gr69, gr73, gr69        
  200144c:  a4004503  jmpf     gr69, $2001458             ; -> L_2001458
  2001450:  03006000  const    gr96, $0000                ; [delay slot]
  2001454:  15604700  add      gr96, gr71, $00         
L_2001458:
  2001458:  88000000  iret                             
  200145c:  01ff60d6  constn   gr96, $ffd6                ; [delay slot]
  2001460:  88000000  iret                             
  2001464:  01ff60d6  constn   gr96, $ffd6                ; [delay slot]
  2001468:  88000000  iret                             
  200146c:  a8004503  call     gr69, $2001478             ; -> L_2001478   ; [delay slot]
  2001470:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001474:  88000000  iret                             
* ==================================================================
*  $2001478 / $2001604  MEMORY-REGION TABLE MANAGEMENT.  The table at
*  $4C003168 (count) / $4C00316C (12-byte entries: base, size, aux) lists
*  the address ranges the TLB handlers accept.  $2001478 INSERTS a range
*  (lr2 = base, lr3 = size, lr4 = aux; both must be 1 KB aligned; merges /
*  rejects overlaps; sets gr64 bit $08000000 when the table was empty) and
*  $2001604 REMOVES / trims a range (lr2 = $FFFFFFFF clears the table);
*  both then rebuild the hardware TLB ('mftlb'/'mttlb' scan, entries
*  tagged $36 are the ones re-written).  (Parameter roles are a reading of
*  the loads/compares, not confirmed against a caller.)
* ==================================================================
L_2001478:
  2001478:  01fc4300  constn   gr67, $fc00                ; [delay slot]
  200147c:  90468243  and      gr70, lr2, gr67         
  2001480:  60464682  cpeq     gr70, gr70, lr2         
  2001484:  a4004659  jmpf     gr70, $20015e8             ; -> L_20015e8
  2001488:  01fc4300  constn   gr67, $fc00                ; [delay slot]
  200148c:  90468343  and      gr70, lr3, gr67         
  2001490:  60464683  cpeq     gr70, gr70, lr3         
  2001494:  a4004653  jmpf     gr70, $20015e0             ; -> L_20015e0
  2001498:  03314c68  const    gr76, $3168                ; [delay slot]
  200149c:  024c4c00  consth   gr76, $4c00             
  20014a0:  16004a4c  load     0, 0, gr74, gr76        
  20014a4:  61474a00  cpeq     gr71, gr74, $00         
  20014a8:  a4004704  jmpf     gr71, $20014b8             ; -> L_20014b8
  20014ac:  03004700  const    gr71, $0000                ; [delay slot]
  20014b0:  02084700  consth   gr71, $0800             
  20014b4:  92404047  or       gr64, gr64, gr71        
L_20014b8:
  20014b8:  030347ff  const    gr71, $03ff             
  20014bc:  4c474a47  cpge     gr71, gr74, gr71        
  20014c0:  ac00474c  jmpt     gr71, $20015f0             ; -> L_20015f0
  20014c4:  0331496c  const    gr73, $316c                ; [delay slot]
  20014c8:  024c4900  consth   gr73, $4c00             
  20014cc:  81474a02  sll      gr71, gr74, $02         
  20014d0:  81464a03  sll      gr70, gr74, $03         
  20014d4:  144b4647  add      gr75, gr70, gr71        
  20014d8:  144b494b  add      gr75, gr73, gr75        
  20014dc:  61484a00  cpeq     gr72, gr74, $00         
  20014e0:  ac004816  jmpt     gr72, $2001538             ; -> L_2001538
  20014e4:  81474900  sll      gr71, gr73, $00            ; [delay slot]
L_20014e8:
  20014e8:  16004647  load     0, 0, gr70, gr71        
  20014ec:  42488246  cpltu    gr72, lr2, gr70         
  20014f0:  ac00480e  jmpt     gr72, $2001528             ; -> L_2001528
  20014f4:  15484704  add      gr72, gr71, $04            ; [delay slot]
  20014f8:  16004848  load     0, 0, gr72, gr72        
  20014fc:  14484648  add      gr72, gr70, gr72        
  2001500:  4e488248  cpgeu    gr72, lr2, gr72         
  2001504:  ac004809  jmpt     gr72, $2001528             ; -> L_2001528
  2001508:  15484708  add      gr72, gr71, $08            ; [delay slot]
  200150c:  16004d48  load     0, 0, gr77, gr72        
  2001510:  24488246  sub      gr72, lr2, gr70         
  2001514:  14484d48  add      gr72, gr77, gr72        
  2001518:  60488348  cpeq     gr72, lr3, gr72         
  200151c:  a400482d  jmpf     gr72, $20015d0             ; -> L_20015d0
  2001520:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001524:  a000000c  jmp      $2001554                   ; -> L_2001554
L_2001528:
  2001528:  1547470c  add      gr71, gr71, $0c            ; [delay slot]
  200152c:  60484b47  cpeq     gr72, gr75, gr71        
  2001530:  a4ff48ee  jmpf     gr72, $20014e8             ; -> L_20014e8
  2001534:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2001538:
  2001538:  154a4a01  add      gr74, gr74, $01         
  200153c:  1e004a4c  store    0, 0, gr74, gr76        
  2001540:  1e00824b  store    0, 0, lr2, gr75         
  2001544:  154b4b04  add      gr75, gr75, $04         
  2001548:  1e00844b  store    0, 0, lr4, gr75         
  200154c:  154b4b04  add      gr75, gr75, $04         
  2001550:  1e00834b  store    0, 0, lr3, gr75         
L_2001554:
  2001554:  16005b4c  load     0, 0, gr91, gr76        
  2001558:  25465b01  sub      gr70, gr91, $01         
  200155c:  ac00460c  jmpt     gr70, $200158c             ; -> L_200158c
  2001560:  25465b01  sub      gr70, gr91, $01            ; [delay slot]
  2001564:  0331476c  const    gr71, $316c             
  2001568:  024c4700  consth   gr71, $4c00             
L_200156c:
  200156c:  16004847  load     0, 0, gr72, gr71        
  2001570:  03004901  const    gr73, $0001             
  2001574:  8348481c  srl      gr72, gr72, $1c         
  2001578:  15484810  add      gr72, gr72, $10         
  200157c:  80494948  sll      gr73, gr73, gr72        
  2001580:  925b5b49  or       gr91, gr91, gr73        
  2001584:  b4ff46fa  jmpfdec  gr70, $200156c             ; -> L_200156c
  2001588:  1547470c  add      gr71, gr71, $0c            ; [delay slot]
L_200158c:
  200158c:  0300497e  const    gr73, $007e             
  2001590:  03004800  const    gr72, $0000             
L_2001594:
  2001594:  b6474800  mftlb    gr71, gr72              
  2001598:  83474708  srl      gr71, gr71, $08         
  200159c:  9147473f  and      gr71, gr71, $3f         
  20015a0:  61474736  cpeq     gr71, gr71, $36         
  20015a4:  a4004703  jmpf     gr71, $20015b0             ; -> L_20015b0
  20015a8:  03004600  const    gr70, $0000                ; [delay slot]
  20015ac:  be004846  mttlb    gr72, gr70              
L_20015b0:
  20015b0:  b4ff49f9  jmpfdec  gr73, $2001594             ; -> L_2001594
  20015b4:  15484802  add      gr72, gr72, $02            ; [delay slot]
  20015b8:  c0000045  jmpi     gr69                    
  20015bc:  03006000  const    gr96, $0000                ; [delay slot]
L_20015c0:
  20015c0:  c0000045  jmpi     gr69                    
  20015c4:  01ff60f7  constn   gr96, $fff7                ; [delay slot]
L_20015c8:
  20015c8:  c0000045  jmpi     gr69                    
  20015cc:  01ff60f8  constn   gr96, $fff8                ; [delay slot]
L_20015d0:
  20015d0:  c0000045  jmpi     gr69                    
  20015d4:  01ff60f9  constn   gr96, $fff9                ; [delay slot]
  20015d8:  c0000045  jmpi     gr69                    
  20015dc:  01ff60fa  constn   gr96, $fffa                ; [delay slot]
L_20015e0:
  20015e0:  c0000045  jmpi     gr69                    
  20015e4:  01ff60fb  constn   gr96, $fffb                ; [delay slot]
L_20015e8:
  20015e8:  c0000045  jmpi     gr69                    
  20015ec:  01ff60fc  constn   gr96, $fffc                ; [delay slot]
L_20015f0:
  20015f0:  c0000045  jmpi     gr69                    
  20015f4:  01ff60fd  constn   gr96, $fffd                ; [delay slot]
  20015f8:  a8004503  call     gr69, $2001604             ; -> L_2001604
  20015fc:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001600:  88000000  iret                             
L_2001604:
  2001604:  01ff46ff  constn   gr70, $ffff                ; [delay slot]
  2001608:  60468246  cpeq     gr70, lr2, gr70         
  200160c:  ac004620  jmpt     gr70, $200168c             ; -> L_200168c
  2001610:  01fc4300  constn   gr67, $fc00                ; [delay slot]
  2001614:  90468243  and      gr70, lr2, gr67         
  2001618:  60464682  cpeq     gr70, gr70, lr2         
  200161c:  a4ff46f3  jmpf     gr70, $20015e8             ; -> L_20015e8
  2001620:  03314c68  const    gr76, $3168                ; [delay slot]
  2001624:  024c4c00  consth   gr76, $4c00             
  2001628:  16004a4c  load     0, 0, gr74, gr76        
  200162c:  61474a00  cpeq     gr71, gr74, $00         
  2001630:  acff47e6  jmpt     gr71, $20015c8             ; -> L_20015c8
  2001634:  0331496c  const    gr73, $316c                ; [delay slot]
  2001638:  024c4900  consth   gr73, $4c00             
  200163c:  81474a02  sll      gr71, gr74, $02         
  2001640:  81464a03  sll      gr70, gr74, $03         
  2001644:  144b4647  add      gr75, gr70, gr71        
  2001648:  144b494b  add      gr75, gr73, gr75        
  200164c:  81474900  sll      gr71, gr73, $00         
L_2001650:
  2001650:  16004647  load     0, 0, gr70, gr71        
  2001654:  42488246  cpltu    gr72, lr2, gr70         
  2001658:  ac004807  jmpt     gr72, $2001674             ; -> L_2001674
  200165c:  15484704  add      gr72, gr71, $04            ; [delay slot]
  2001660:  16004848  load     0, 0, gr72, gr72        
  2001664:  14484648  add      gr72, gr70, gr72        
  2001668:  42488248  cpltu    gr72, lr2, gr72         
  200166c:  ac00480d  jmpt     gr72, $20016a0             ; -> L_20016a0
  2001670:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2001674:
  2001674:  1547470c  add      gr71, gr71, $0c         
  2001678:  4c48474b  cpge     gr72, gr71, gr75        
  200167c:  a4ff48f5  jmpf     gr72, $2001650             ; -> L_2001650
  2001680:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001684:  a0ff00cf  jmp      $20015c0                   ; -> L_20015c0
  2001688:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_200168c:
  200168c:  03004600  const    gr70, $0000             
  2001690:  03314768  const    gr71, $3168             
  2001694:  024c4700  consth   gr71, $4c00             
  2001698:  a0000014  jmp      $20016e8                   ; -> L_20016e8
  200169c:  1e004647  store    0, 0, gr70, gr71           ; [delay slot]
L_20016a0:
  20016a0:  254a4a01  sub      gr74, gr74, $01         
  20016a4:  1e004a4c  store    0, 0, gr74, gr76        
  20016a8:  61484a00  cpeq     gr72, gr74, $00         
  20016ac:  ac00482c  jmpt     gr72, $200175c             ; -> L_200175c
  20016b0:  254b4b0c  sub      gr75, gr75, $0c            ; [delay slot]
  20016b4:  60484b47  cpeq     gr72, gr75, gr71        
  20016b8:  ac00480c  jmpt     gr72, $20016e8             ; -> L_20016e8
  20016bc:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20016c0:  1600484b  load     0, 0, gr72, gr75        
  20016c4:  154b4b04  add      gr75, gr75, $04         
  20016c8:  1e004847  store    0, 0, gr72, gr71        
  20016cc:  15474704  add      gr71, gr71, $04         
  20016d0:  1600484b  load     0, 0, gr72, gr75        
  20016d4:  154b4b04  add      gr75, gr75, $04         
  20016d8:  1e004847  store    0, 0, gr72, gr71        
  20016dc:  15474704  add      gr71, gr71, $04         
  20016e0:  1600484b  load     0, 0, gr72, gr75        
  20016e4:  1e004847  store    0, 0, gr72, gr71        
L_20016e8:
  20016e8:  0300497e  const    gr73, $007e             
  20016ec:  03004800  const    gr72, $0000             
L_20016f0:
  20016f0:  b6474800  mftlb    gr71, gr72              
  20016f4:  83474708  srl      gr71, gr71, $08         
  20016f8:  9147473f  and      gr71, gr71, $3f         
  20016fc:  61474736  cpeq     gr71, gr71, $36         
  2001700:  a4004703  jmpf     gr71, $200170c             ; -> L_200170c
  2001704:  03004600  const    gr70, $0000                ; [delay slot]
  2001708:  be004846  mttlb    gr72, gr70              
L_200170c:
  200170c:  b4ff49f9  jmpfdec  gr73, $20016f0             ; -> L_20016f0
  2001710:  15484802  add      gr72, gr72, $02            ; [delay slot]
  2001714:  03315b68  const    gr91, $3168             
  2001718:  024c5b00  consth   gr91, $4c00             
  200171c:  16005b5b  load     0, 0, gr91, gr91        
  2001720:  25465b01  sub      gr70, gr91, $01         
  2001724:  ac00460c  jmpt     gr70, $2001754             ; -> L_2001754
  2001728:  25465b01  sub      gr70, gr91, $01            ; [delay slot]
  200172c:  0331476c  const    gr71, $316c             
  2001730:  024c4700  consth   gr71, $4c00             
L_2001734:
  2001734:  16004847  load     0, 0, gr72, gr71        
  2001738:  03004901  const    gr73, $0001             
  200173c:  8348481c  srl      gr72, gr72, $1c         
  2001740:  15484810  add      gr72, gr72, $10         
  2001744:  80494948  sll      gr73, gr73, gr72        
  2001748:  925b5b49  or       gr91, gr91, gr73        
  200174c:  b4ff46fa  jmpfdec  gr70, $2001734             ; -> L_2001734
  2001750:  1547470c  add      gr71, gr71, $0c            ; [delay slot]
L_2001754:
  2001754:  c0000045  jmpi     gr69                    
  2001758:  03006000  const    gr96, $0000                ; [delay slot]
L_200175c:
  200175c:  03004700  const    gr71, $0000             
  2001760:  02084700  consth   gr71, $0800             
  2001764:  9c404047  andn     gr64, gr64, gr71        
  2001768:  03005b00  const    gr91, $0000             
  200176c:  c0000045  jmpi     gr69                    
  2001770:  03006000  const    gr96, $0000                ; [delay slot]
  2001774:  01fc4300  constn   gr67, $fc00             
  2001778:  90468243  and      gr70, lr2, gr67         
  200177c:  60464682  cpeq     gr70, gr70, lr2         
  2001780:  a4ff469a  jmpf     gr70, $20015e8             ; -> L_20015e8
  2001784:  03314c68  const    gr76, $3168                ; [delay slot]
  2001788:  024c4c00  consth   gr76, $4c00             
  200178c:  16004a4c  load     0, 0, gr74, gr76        
  2001790:  61474a00  cpeq     gr71, gr74, $00         
  2001794:  acff478d  jmpt     gr71, $20015c8             ; -> L_20015c8
  2001798:  0331496c  const    gr73, $316c                ; [delay slot]
  200179c:  024c4900  consth   gr73, $4c00             
  20017a0:  81474a02  sll      gr71, gr74, $02         
  20017a4:  81464a03  sll      gr70, gr74, $03         
  20017a8:  144b4647  add      gr75, gr70, gr71        
  20017ac:  144b494b  add      gr75, gr73, gr75        
  20017b0:  81474900  sll      gr71, gr73, $00         
L_20017b4:
  20017b4:  16004647  load     0, 0, gr70, gr71        
  20017b8:  42488246  cpltu    gr72, lr2, gr70         
  20017bc:  ac004807  jmpt     gr72, $20017d8             ; -> L_20017d8
  20017c0:  15484704  add      gr72, gr71, $04            ; [delay slot]
  20017c4:  16004848  load     0, 0, gr72, gr72        
  20017c8:  14484648  add      gr72, gr70, gr72        
  20017cc:  42488248  cpltu    gr72, lr2, gr72         
  20017d0:  ac004808  jmpt     gr72, $20017f0             ; -> L_20017f0
  20017d4:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_20017d8:
  20017d8:  1547470c  add      gr71, gr71, $0c         
  20017dc:  4c48474b  cpge     gr72, gr71, gr75        
  20017e0:  a4ff48f5  jmpf     gr72, $20017b4             ; -> L_20017b4
  20017e4:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20017e8:  a0ff0076  jmp      $20015c0                   ; -> L_20015c0
  20017ec:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_20017f0:
  20017f0:  24488246  sub      gr72, lr2, gr70         
  20017f4:  15474708  add      gr71, gr71, $08         
  20017f8:  16004747  load     0, 0, gr71, gr71        
  20017fc:  147a4748  add      gr122, gr71, gr72       
  2001800:  03006000  const    gr96, $0000             
  2001804:  88000000  iret                             
  2001808:  81468200  sll      gr70, lr2, $00             ; [delay slot]
  200180c:  a8014508  call     gr69, $2001c2c             ; -> L_2001c2c
  2001810:  81476000  sll      gr71, gr96, $00            ; [delay slot]
  2001814:  81604600  sll      gr96, gr70, $00         
  2001818:  817a4700  sll      gr122, gr71, $00        
  200181c:  88000000  iret                             
  2001820:  03684a48  const    gr74, $6848                ; [delay slot]
  2001824:  024c4a00  consth   gr74, $4c00             
  2001828:  1e00824a  store    0, 0, lr2, gr74         
  200182c:  c6520100  mfsr     gr82, OPS               
  2001830:  91465240  and      gr70, gr82, $40         
  2001834:  63604640  cpneq    gr96, gr70, $40         
  2001838:  8360601f  srl      gr96, gr96, $1f         
  200183c:  61468200  cpeq     gr70, lr2, $00          
  2001840:  a4004604  jmpf     gr70, $2001850             ; -> L_2001850
  2001844:  93525240  or       gr82, gr82, $40            ; [delay slot]
  2001848:  ce000152  mtsr     OPS, gr82               
  200184c:  88000000  iret                             
L_2001850:
  2001850:  0300497e  const    gr73, $007e                ; [delay slot]
  2001854:  03004800  const    gr72, $0000             
L_2001858:
  2001858:  b6474800  mftlb    gr71, gr72              
  200185c:  83474708  srl      gr71, gr71, $08         
  2001860:  9147473f  and      gr71, gr71, $3f         
  2001864:  61474736  cpeq     gr71, gr71, $36         
  2001868:  a4004703  jmpf     gr71, $2001874             ; -> L_2001874
  200186c:  03004600  const    gr70, $0000                ; [delay slot]
  2001870:  be004846  mttlb    gr72, gr70              
L_2001874:
  2001874:  b4ff49f9  jmpfdec  gr73, $2001858             ; -> L_2001858
  2001878:  15484802  add      gr72, gr72, $02            ; [delay slot]
  200187c:  9d525240  andn     gr82, gr82, $40         
  2001880:  ce000152  mtsr     OPS, gr82               
  2001884:  88000000  iret                             
  2001888:  03014900  const    gr73, $0100                ; [delay slot]
  200188c:  02004900  consth   gr73, $0000             
  2001890:  9c404049  andn     gr64, gr64, gr73        
  2001894:  03084900  const    gr73, $0800             
  2001898:  c6520100  mfsr     gr82, OPS               
  200189c:  92525249  or       gr82, gr82, gr73        
  20018a0:  ce000152  mtsr     OPS, gr82               
  20018a4:  0300495c  const    gr73, $005c             
  20018a8:  02444900  consth   gr73, $4400             
  20018ac:  03004c00  const    gr76, $0000             
  20018b0:  1e004c49  store    0, 0, gr76, gr73        
  20018b4:  88000000  iret                             
  20018b8:  c6460100  mfsr     gr70, OPS                  ; [delay slot]
  20018bc:  91484610  and      gr72, gr70, $10         
  20018c0:  63604800  cpneq    gr96, gr72, $00         
  20018c4:  61478200  cpeq     gr71, lr2, $00          
  20018c8:  ac004704  jmpt     gr71, $20018d8             ; -> L_20018d8
  20018cc:  93464610  or       gr70, gr70, $10            ; [delay slot]
  20018d0:  ce000146  mtsr     OPS, gr70               
  20018d4:  88000000  iret                             
L_20018d8:
  20018d8:  9d464610  andn     gr70, gr70, $10            ; [delay slot]
  20018dc:  ce000146  mtsr     OPS, gr70               
  20018e0:  88000000  iret                             
  20018e4:  c6470900  mfsr     gr71, TMR                  ; [delay slot]
  20018e8:  03004600  const    gr70, $0000             
  20018ec:  02014600  consth   gr70, $0100             
  20018f0:  90484746  and      gr72, gr71, gr70        
  20018f4:  63604800  cpneq    gr96, gr72, $00         
  20018f8:  61488200  cpeq     gr72, lr2, $00          
  20018fc:  ac004807  jmpt     gr72, $2001918             ; -> L_2001918
  2001900:  03754730  const    gr71, $7530                ; [delay slot]
  2001904:  02004700  consth   gr71, $0000             
  2001908:  ce000847  mtsr     TMC, gr71               
  200190c:  92474746  or       gr71, gr71, gr70        
  2001910:  ce000947  mtsr     TMR, gr71               
  2001914:  88000000  iret                             
L_2001918:
  2001918:  04000800  mtsrim   TMC, $0000                 ; [delay slot]
  200191c:  04000900  mtsrim   TMR, $0000              
  2001920:  88000000  iret                             
  2001924:  c6460100  mfsr     gr70, OPS                  ; [delay slot]
  2001928:  91484602  and      gr72, gr70, $02         
  200192c:  63604800  cpneq    gr96, gr72, $00         
  2001930:  61478200  cpeq     gr71, lr2, $00          
  2001934:  ac004704  jmpt     gr71, $2001944             ; -> L_2001944
  2001938:  93464602  or       gr70, gr70, $02            ; [delay slot]
  200193c:  ce000146  mtsr     OPS, gr70               
  2001940:  88000000  iret                             
L_2001944:
  2001944:  9d464602  andn     gr70, gr70, $02            ; [delay slot]
  2001948:  ce000146  mtsr     OPS, gr70               
  200194c:  88000000  iret                             
  2001950:  41458200  cplt     gr69, lr2, $00             ; [delay slot]
  2001954:  ac004518  jmpt     gr69, $20019b4             ; -> L_20019b4
  2001958:  49458203  cpgt     gr69, lr2, $03             ; [delay slot]
  200195c:  ac004516  jmpt     gr69, $20019b4             ; -> L_20019b4
  2001960:  61458200  cpeq     gr69, lr2, $00             ; [delay slot]
  2001964:  a4004504  jmpf     gr69, $2001974             ; -> L_2001974
  2001968:  0361467c  const    gr70, $617c                ; [delay slot]
  200196c:  024c4600  consth   gr70, $4c00             
  2001970:  a000000e  jmp      $20019a8                   ; -> L_20019a8
L_2001974:
  2001974:  61458201  cpeq     gr69, lr2, $01             ; [delay slot]
  2001978:  a4004504  jmpf     gr69, $2001988             ; -> L_2001988
  200197c:  03614680  const    gr70, $6180                ; [delay slot]
  2001980:  024c4600  consth   gr70, $4c00             
  2001984:  a0000009  jmp      $20019a8                   ; -> L_20019a8
L_2001988:
  2001988:  61458202  cpeq     gr69, lr2, $02             ; [delay slot]
  200198c:  a4004505  jmpf     gr69, $20019a0             ; -> L_20019a0
  2001990:  03614684  const    gr70, $6184                ; [delay slot]
  2001994:  024c4600  consth   gr70, $4c00             
  2001998:  a0000004  jmp      $20019a8                   ; -> L_20019a8
  200199c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_20019a0:
  20019a0:  03614688  const    gr70, $6188             
  20019a4:  024c4600  consth   gr70, $4c00             
L_20019a8:
  20019a8:  1e008346  store    0, 0, lr3, gr70         
  20019ac:  03006000  const    gr96, $0000             
  20019b0:  88000000  iret                             
L_20019b4:
  20019b4:  01ff60ff  constn   gr96, $ffff                ; [delay slot]
  20019b8:  88000000  iret                             
  20019bc:  0361468c  const    gr70, $618c                ; [delay slot]
  20019c0:  024c4600  consth   gr70, $4c00             
  20019c4:  16004746  load     0, 0, gr71, gr70        
  20019c8:  a400471f  jmpf     gr71, $2001a44             ; -> L_2001a44
  20019cc:  03004700  const    gr71, $0000                ; [delay slot]
  20019d0:  1e004746  store    0, 0, gr71, gr70        
  20019d4:  15464604  add      gr70, gr70, $04         
  20019d8:  16005846  load     0, 0, gr88, gr70        
  20019dc:  15464604  add      gr70, gr70, $04         
  20019e0:  16005946  load     0, 0, gr89, gr70        
  20019e4:  15464604  add      gr70, gr70, $04         
  20019e8:  16005246  load     0, 0, gr82, gr70        
  20019ec:  15464604  add      gr70, gr70, $04         
  20019f0:  16005646  load     0, 0, gr86, gr70        
  20019f4:  15464604  add      gr70, gr70, $04         
  20019f8:  16005a46  load     0, 0, gr90, gr70        
  20019fc:  15464604  add      gr70, gr70, $04         
  2001a00:  16005746  load     0, 0, gr87, gr70        
  2001a04:  15464604  add      gr70, gr70, $04         
  2001a08:  16006046  load     0, 0, gr96, gr70        
  2001a0c:  15464604  add      gr70, gr70, $04         
  2001a10:  16006146  load     0, 0, gr97, gr70        
  2001a14:  15464604  add      gr70, gr70, $04         
  2001a18:  16006246  load     0, 0, gr98, gr70        
  2001a1c:  15464604  add      gr70, gr70, $04         
  2001a20:  16006346  load     0, 0, gr99, gr70        
  2001a24:  15464604  add      gr70, gr70, $04         
  2001a28:  0404027f  mtsrim   CPS, $047f              
  2001a2c:  ce000a58  mtsr     PC0, gr88               
  2001a30:  ce000b59  mtsr     PC1, gr89               
  2001a34:  ce000152  mtsr     OPS, gr82               
  2001a38:  ce000456  mtsr     CHA, gr86               
  2001a3c:  ce00065a  mtsr     CHC, gr90               
  2001a40:  ce000557  mtsr     CHD, gr87               
L_2001a44:
  2001a44:  88000000  iret                             
  2001a48:  03684704  const    gr71, $6804                ; [delay slot]
  2001a4c:  024c4700  consth   gr71, $4c00             
  2001a50:  16006047  load     0, 0, gr96, gr71        
  2001a54:  88000000  iret                             
  2001a58:  81604000  sll      gr96, gr64, $00            ; [delay slot]
  2001a5c:  88000000  iret                             
  2001a60:  01ff60d6  constn   gr96, $ffd6                ; [delay slot]
  2001a64:  88000000  iret                             
  2001a68:  01ff60d6  constn   gr96, $ffd6                ; [delay slot]
  2001a6c:  88000000  iret                             
* ==================================================================
*  VECTOR 69 -- SERVICE CALL (HIF-style set; trap 69 is the usual AMD host-interface
*  call, 'asneq 69,gr1,gr1').  Services seen: $101 sbrk, $104 InpArgs pointer,
*  $111/$112 time, $121 set globals, 1 exit.  gr121 = service:
*    $101  sbrk:  gr96 = old break (gr65), break += lr2 rounded up to 4;
*                 fails ($0C in gr121) if it would cross gr127 - $3000
*    $102  compares lr2 with the limit at $4C006410; gr96 = 0
*    $103  gr96 = $400 (page / unit size)
*    $104  gr96 = $4C007800 (the InpArgs block)    $111  gr96 = tick count [$4C006830]
*    $112  gr96/gr97 = cycle time from TMC + [$4C006834]
*    $001  exit: posts the request to the host (reason = service) and parks the
*          CPU after storing 'BSBB' ($42534242) at VidComm+$18 and 1 at $4C006A5C
*    $121  lr2 = $40 -> gr92 = lr3, lr2 = $41 -> gr93 = lr3 (set globals)
*  further numbers are handled below and end in $2002650 (report to host).
* ==================================================================
  2001a70:  157a7900  add      gr122, gr121, $00          ; [delay slot]
  2001a74:  03017901  const    gr121, $0101            
  2001a78:  60797a79  cpeq     gr121, gr122, gr121     
  2001a7c:  a4007911  jmpf     gr121, $2001ac0            ; -> L_2001ac0
  2001a80:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001a84:  15468203  add      gr70, lr2, $03          
  2001a88:  9d464603  andn     gr70, gr70, $03         
  2001a8c:  15604100  add      gr96, gr65, $00         
  2001a90:  03304500  const    gr69, $3000             
  2001a94:  02004500  consth   gr69, $0000             
  2001a98:  24447f45  sub      gr68, gr127, gr69       
  2001a9c:  14434146  add      gr67, gr65, gr70        
  2001aa0:  4e454344  cpgeu    gr69, gr67, gr68        
  2001aa4:  ac004504  jmpt     gr69, $2001ab4             ; -> L_2001ab4
  2001aa8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001aac:  14414146  add      gr65, gr65, gr70        
  2001ab0:  88000000  iret                             
L_2001ab4:
  2001ab4:  03006000  const    gr96, $0000                ; [delay slot]
  2001ab8:  0300790c  const    gr121, $000c            
  2001abc:  88000000  iret                             
L_2001ac0:
  2001ac0:  03017902  const    gr121, $0102               ; [delay slot]
  2001ac4:  60797a79  cpeq     gr121, gr122, gr121     
  2001ac8:  a4007908  jmpf     gr121, $2001ae8            ; -> L_2001ae8
  2001acc:  03644310  const    gr67, $6410                ; [delay slot]
  2001ad0:  024c4300  consth   gr67, $4c00             
  2001ad4:  16004443  load     0, 0, gr68, gr67        
  2001ad8:  42438244  cpltu    gr67, lr2, gr68         
  2001adc:  ac004302  jmpt     gr67, $2001ae4             ; -> L_2001ae4
  2001ae0:  03006000  const    gr96, $0000                ; [delay slot]
L_2001ae4:
  2001ae4:  88000000  iret                             
L_2001ae8:
  2001ae8:  03017903  const    gr121, $0103               ; [delay slot]
  2001aec:  60797a79  cpeq     gr121, gr122, gr121     
  2001af0:  a4007903  jmpf     gr121, $2001afc            ; -> L_2001afc
  2001af4:  03046000  const    gr96, $0400                ; [delay slot]
  2001af8:  88000000  iret                             
L_2001afc:
  2001afc:  03017921  const    gr121, $0121               ; [delay slot]
  2001b00:  60797a79  cpeq     gr121, gr122, gr121     
  2001b04:  a400790f  jmpf     gr121, $2001b40            ; -> L_2001b40
  2001b08:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001b0c:  03006000  const    gr96, $0000             
  2001b10:  61798240  cpeq     gr121, lr2, $40         
  2001b14:  a4007904  jmpf     gr121, $2001b24            ; -> L_2001b24
  2001b18:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001b1c:  155c8300  add      gr92, lr3, $00          
  2001b20:  88000000  iret                             
L_2001b24:
  2001b24:  61798241  cpeq     gr121, lr2, $41            ; [delay slot]
  2001b28:  a4007904  jmpf     gr121, $2001b38            ; -> L_2001b38
  2001b2c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001b30:  155d8300  add      gr93, lr3, $00          
  2001b34:  88000000  iret                             
L_2001b38:
  2001b38:  01006001  constn   gr96, $0001                ; [delay slot]
  2001b3c:  88000000  iret                             
L_2001b40:
  2001b40:  03017904  const    gr121, $0104               ; [delay slot]
  2001b44:  60797a79  cpeq     gr121, gr122, gr121     
  2001b48:  a4007904  jmpf     gr121, $2001b58            ; -> L_2001b58
  2001b4c:  03786000  const    gr96, $7800                ; [delay slot]
  2001b50:  024c6000  consth   gr96, $4c00             
  2001b54:  88000000  iret                             
L_2001b58:
  2001b58:  03014311  const    gr67, $0111                ; [delay slot]
  2001b5c:  60797a43  cpeq     gr121, gr122, gr67      
  2001b60:  a4007905  jmpf     gr121, $2001b74            ; -> L_2001b74
  2001b64:  03684730  const    gr71, $6830                ; [delay slot]
  2001b68:  024c4700  consth   gr71, $4c00             
  2001b6c:  16006047  load     0, 0, gr96, gr71        
  2001b70:  88000000  iret                             
L_2001b74:
  2001b74:  03014312  const    gr67, $0112                ; [delay slot]
  2001b78:  60797a43  cpeq     gr121, gr122, gr67      
  2001b7c:  a4007911  jmpf     gr121, $2001bc0            ; -> L_2001bc0
  2001b80:  03684734  const    gr71, $6834                ; [delay slot]
  2001b84:  024c4700  consth   gr71, $4c00             
  2001b88:  16004747  load     0, 0, gr71, gr71        
  2001b8c:  03754830  const    gr72, $7530             
  2001b90:  c6490800  mfsr     gr73, TMC               
  2001b94:  24494849  sub      gr73, gr72, gr73        
  2001b98:  14604947  add      gr96, gr73, gr71        
  2001b9c:  15474704  add      gr71, gr71, $04         
  2001ba0:  16006147  load     0, 0, gr97, gr71        
  2001ba4:  c64b8400  mfsr     gr75, ALU               
  2001ba8:  814b4b18  sll      gr75, gr75, $18         
  2001bac:  a4004b03  jmpf     gr75, $2001bb8             ; -> L_2001bb8
  2001bb0:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001bb4:  88000000  iret                             
L_2001bb8:
  2001bb8:  15616101  add      gr97, gr97, $01            ; [delay slot]
  2001bbc:  88000000  iret                             
L_2001bc0:
  2001bc0:  81474014  sll      gr71, gr64, $14            ; [delay slot]
  2001bc4:  a4004703  jmpf     gr71, $2001bd0             ; -> L_2001bd0
  2001bc8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001bcc:  88000000  iret                             
L_2001bd0:
  2001bd0:  a80246a0  call     gr70, $2002650             ; -> L_2002650   ; [delay slot]
  2001bd4:  154d7a00  add      gr77, gr122, $00           ; [delay slot]
  2001bd8:  03007901  const    gr121, $0001            
  2001bdc:  60797a79  cpeq     gr121, gr122, gr121     
  2001be0:  a4007910  jmpf     gr121, $2001c20            ; -> L_2001c20
  2001be4:  03734818  const    gr72, $7318                ; [delay slot]
  2001be8:  024c4800  consth   gr72, $4c00             
  2001bec:  03424742  const    gr71, $4242             
  2001bf0:  02424753  consth   gr71, $4253             
  2001bf4:  1e004748  store    0, 0, gr71, gr72        
  2001bf8:  03004701  const    gr71, $0001             
  2001bfc:  036a485c  const    gr72, $6a5c             
  2001c00:  024c4800  consth   gr72, $4c00             
  2001c04:  1e004748  store    0, 0, gr71, gr72        
  2001c08:  036a4860  const    gr72, $6a60             
  2001c0c:  024c4800  consth   gr72, $4c00             
  2001c10:  c6470a00  mfsr     gr71, PC0               
  2001c14:  1e004748  store    0, 0, gr71, gr72        
L_2001c18:
  2001c18:  a0000000  jmp      $2001c18                   ; -> L_2001c18
  2001c1c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2001c20:
  2001c20:  60794747  cpeq     gr121, gr71, gr71       
  2001c24:  15604700  add      gr96, gr71, $00         
  2001c28:  88000000  iret                             
* ==================================================================
*  $2001C2C  RANGE CLIP / VALIDATE.  In: gr70 = address, gr71 = length,
*  gr91 = region mask.  Walks the (base, size) table at $4C00316C with
*  CPS = $047F (interrupts masked), trims the request to the matching
*  region(s) and returns the allowed length in gr71 / adjusted address in
*  gr70; return = jmpi gr69.  Used by the unaligned handler and others.
* ==================================================================
L_2001c2c:
  2001c2c:  81434004  sll      gr67, gr64, $04            ; [delay slot]
  2001c30:  c4004345  jmpfi    gr67, gr69              
  2001c34:  030343ff  const    gr67, $03ff                ; [delay slot]
  2001c38:  90435b43  and      gr67, gr91, gr67        
  2001c3c:  834c461c  srl      gr76, gr70, $1c         
  2001c40:  154c4c10  add      gr76, gr76, $10         
  2001c44:  03005101  const    gr81, $0001             
  2001c48:  804c514c  sll      gr76, gr81, gr76        
  2001c4c:  904c4c5b  and      gr76, gr76, gr91        
  2001c50:  614c4c00  cpeq     gr76, gr76, $00         
  2001c54:  cc004c45  jmpti    gr76, gr69              
  2001c58:  03034cff  const    gr76, $03ff                ; [delay slot]
  2001c5c:  9051464c  and      gr81, gr70, gr76        
  2001c60:  9c46464c  andn     gr70, gr70, gr76        
  2001c64:  0331486c  const    gr72, $316c             
  2001c68:  024c4800  consth   gr72, $4c00             
  2001c6c:  c64b0200  mfsr     gr75, CPS               
  2001c70:  0404027f  mtsrim   CPS, $047f              
L_2001c74:
  2001c74:  25434301  sub      gr67, gr67, $01         
  2001c78:  ac004320  jmpt     gr67, $2001cf8             ; -> L_2001cf8
  2001c7c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001c80:  16004948  load     0, 0, gr73, gr72        
  2001c84:  15484804  add      gr72, gr72, $04         
  2001c88:  604c4649  cpeq     gr76, gr70, gr73        
  2001c8c:  ac004c10  jmpt     gr76, $2001ccc             ; -> L_2001ccc
  2001c90:  424c4649  cpltu    gr76, gr70, gr73           ; [delay slot]
  2001c94:  ac004c07  jmpt     gr76, $2001cb0             ; -> L_2001cb0
  2001c98:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001c9c:  16004a48  load     0, 0, gr74, gr72        
  2001ca0:  144a494a  add      gr74, gr73, gr74        
  2001ca4:  424c464a  cpltu    gr76, gr70, gr74        
  2001ca8:  ac004c04  jmpt     gr76, $2001cb8             ; -> L_2001cb8
  2001cac:  24494649  sub      gr73, gr70, gr73           ; [delay slot]
L_2001cb0:
  2001cb0:  a0ff00f1  jmp      $2001c74                   ; -> L_2001c74
  2001cb4:  15484808  add      gr72, gr72, $08            ; [delay slot]
L_2001cb8:
  2001cb8:  244a4a46  sub      gr74, gr74, gr70        
  2001cbc:  15484804  add      gr72, gr72, $04         
  2001cc0:  16004648  load     0, 0, gr70, gr72        
  2001cc4:  a0000005  jmp      $2001cd8                   ; -> L_2001cd8
  2001cc8:  14464649  add      gr70, gr70, gr73           ; [delay slot]
L_2001ccc:
  2001ccc:  16004a48  load     0, 0, gr74, gr72        
  2001cd0:  15484804  add      gr72, gr72, $04         
  2001cd4:  16004648  load     0, 0, gr70, gr72        
L_2001cd8:
  2001cd8:  244a4a51  sub      gr74, gr74, gr81        
  2001cdc:  464c474a  cpleu    gr76, gr71, gr74        
  2001ce0:  ac004c03  jmpt     gr76, $2001cec             ; -> L_2001cec
  2001ce4:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001ce8:  81474a00  sll      gr71, gr74, $00         
L_2001cec:
  2001cec:  ce00024b  mtsr     CPS, gr75               
  2001cf0:  c0000045  jmpi     gr69                    
  2001cf4:  92464651  or       gr70, gr70, gr81           ; [delay slot]
L_2001cf8:
  2001cf8:  ce00024b  mtsr     CPS, gr75               
  2001cfc:  92464651  or       gr70, gr70, gr81        
  2001d00:  c0000045  jmpi     gr69                    
  2001d04:  03004700  const    gr71, $0000                ; [delay slot]
* ==================================================================
*  VECTORS 22..63, 67 (default): any unexpected vector -> reason $A3.
*
*  $2001D10  PAGER (read in detail): reached when the TLB-miss handlers find no
*  entry for the page in gr68 (bucket index in gr77).  It picks a victim slot
*  from a pool of 52 ($34) entries -- first the pool's free list at $4C002810,
*  otherwise a pseudo-random choice from the timer counter (TMC xor'ed down to a
*  6-bit index, retried while it hits a slot that is in use for the current
*  fault) -- unlinks the victim from its hash chain ($4C002818 + 4*bucket, chain
*  links at entry+$0C/+$10), invalidates its two hardware TLB entries (a
*  'mftlb'/'mttlb' scan that compares tags under the mask $FFFF8000), fills the
*  entry (+$00 page, +$04 data, +$08 bucket), links it at the head of the new
*  bucket, then brings the page in: it saves lr0..lr31 to $4C002E4C, bursts
*  seven 32-word 'loadm' reads (stride $80) from the page (address | $4C000000)
*  between writes of the page/bus control registers $4400008C/$44000088 (the
*  value for $4400008C is derived from gr64 bits 8-15), restores the registers
*  and jumps to $20006EC, the TLB reload ('mttlb' at LRU) of the miss handler.
*  Failures here give reasons $9E / $A1.
* ==================================================================
* ==================================================================
*  $2001FFC  KERNEL INIT (reached from Boot, and from the restart service).
*  CFG = $D0, CPS = $047F; gr64 <- PublicIn+$18 (host flags); acknowledges
*  and clears $44000050/54; clears the region table ($4C003168), the
*  interrupt handler words ($4C00617C..) and $4C006830.. counters; stores
*  $A2 at $4C006A5C; clears VidComm ($4C007300..), stores the 'WY1`' signature at
*  VidComm+$18, copies the loaded program's data section, sets the stack from
*  PublicIn+$40 and the break at PublicIn+$10, and ends ($20025E8-$2002644) by
*  loading PC1 from PublicIn+$04 and iretinv: it STARTS the loaded program.
* ==================================================================
L_2001ffc:
  2001ffc:  040003d0  mtsrim   CFG, $00d0              
  2002000:  0404027f  mtsrim   CPS, $047f              
  2002004:  03644318  const    gr67, $6418             
  2002008:  024c4300  consth   gr67, $4c00             
  200200c:  16004043  load     0, 0, gr64, gr67        
  2002010:  03004600  const    gr70, $0000             
  2002014:  01ff47ff  constn   gr71, $ffff             
  2002018:  03004850  const    gr72, $0050             
  200201c:  02444800  consth   gr72, $4400             
  2002020:  1e004648  store    0, 0, gr70, gr72        
  2002024:  03004854  const    gr72, $0054             
  2002028:  02444800  consth   gr72, $4400             
  200202c:  1e004648  store    0, 0, gr70, gr72        
  2002030:  03005b00  const    gr91, $0000             
  2002034:  03004800  const    gr72, $0000             
  2002038:  02084800  consth   gr72, $0800             
  200203c:  9c404048  andn     gr64, gr64, gr72        
  2002040:  03314868  const    gr72, $3168             
  2002044:  024c4800  consth   gr72, $4c00             
  2002048:  1e004648  store    0, 0, gr70, gr72        
  200204c:  0361487c  const    gr72, $617c             
  2002050:  024c4800  consth   gr72, $4c00             
  2002054:  1e004648  store    0, 0, gr70, gr72        
  2002058:  15484804  add      gr72, gr72, $04         
  200205c:  1e004648  store    0, 0, gr70, gr72        
  2002060:  15484804  add      gr72, gr72, $04         
  2002064:  1e004648  store    0, 0, gr70, gr72        
  2002068:  15484804  add      gr72, gr72, $04         
  200206c:  1e004648  store    0, 0, gr70, gr72        
  2002070:  15484804  add      gr72, gr72, $04         
  2002074:  1e004648  store    0, 0, gr70, gr72        
  2002078:  03684830  const    gr72, $6830             
  200207c:  024c4800  consth   gr72, $4c00             
  2002080:  03014934  const    gr73, $0134             
L_2002084:
  2002084:  1e004648  store    0, 0, gr70, gr72        
  2002088:  b4ff49ff  jmpfdec  gr73, $2002084             ; -> L_2002084
  200208c:  15484804  add      gr72, gr72, $04            ; [delay slot]
  2002090:  0368483c  const    gr72, $683c             
  2002094:  024c4800  consth   gr72, $4c00             
  2002098:  1e004748  store    0, 0, gr71, gr72        
  200209c:  030049a2  const    gr73, $00a2             
  20020a0:  036a485c  const    gr72, $6a5c             
  20020a4:  024c4800  consth   gr72, $4c00             
  20020a8:  1e004948  store    0, 0, gr73, gr72        
  20020ac:  036748d4  const    gr72, $67d4             
  20020b0:  024c4800  consth   gr72, $4c00             
  20020b4:  1e004648  store    0, 0, gr70, gr72        
  20020b8:  03734800  const    gr72, $7300             
  20020bc:  024c4800  consth   gr72, $4c00             
  20020c0:  1e004648  store    0, 0, gr70, gr72        
  20020c4:  03734804  const    gr72, $7304             
  20020c8:  024c4800  consth   gr72, $4c00             
  20020cc:  1e004748  store    0, 0, gr71, gr72        
  20020d0:  03314960  const    gr73, $3160             
  20020d4:  02574959  consth   gr73, $5759             
  20020d8:  03734818  const    gr72, $7318             
  20020dc:  024c4800  consth   gr72, $4c00             
  20020e0:  1e004948  store    0, 0, gr73, gr72        
  20020e4:  0373481c  const    gr72, $731c             
  20020e8:  024c4800  consth   gr72, $4c00             
  20020ec:  1e004648  store    0, 0, gr70, gr72        
  20020f0:  03644624  const    gr70, $6424             
  20020f4:  024c4600  consth   gr70, $4c00             
  20020f8:  16004746  load     0, 0, gr71, gr70        
  20020fc:  0364462c  const    gr70, $642c             
  2002100:  024c4600  consth   gr70, $4c00             
  2002104:  16004846  load     0, 0, gr72, gr70        
  2002108:  03644620  const    gr70, $6420             
  200210c:  024c4600  consth   gr70, $4c00             
  2002110:  16004946  load     0, 0, gr73, gr70        
  2002114:  03644628  const    gr70, $6428             
  2002118:  024c4600  consth   gr70, $4c00             
  200211c:  16004a46  load     0, 0, gr74, gr70        
  2002120:  1449494a  add      gr73, gr73, gr74        
  2002124:  83484802  srl      gr72, gr72, $02         
  2002128:  25484802  sub      gr72, gr72, $02         
L_200212c:
  200212c:  16004647  load     0, 0, gr70, gr71        
  2002130:  15474704  add      gr71, gr71, $04         
  2002134:  1e004649  store    0, 0, gr70, gr73        
  2002138:  b4ff48fd  jmpfdec  gr72, $200212c             ; -> L_200212c
  200213c:  15494904  add      gr73, gr73, $04            ; [delay slot]
  2002140:  03644630  const    gr70, $6430             
  2002144:  024c4600  consth   gr70, $4c00             
  2002148:  16004846  load     0, 0, gr72, gr70        
  200214c:  83484802  srl      gr72, gr72, $02         
  2002150:  25484802  sub      gr72, gr72, $02         
  2002154:  03004600  const    gr70, $0000             
L_2002158:
  2002158:  1e004649  store    0, 0, gr70, gr73        
  200215c:  b4ff48ff  jmpfdec  gr72, $2002158             ; -> L_2002158
  2002160:  15494904  add      gr73, gr73, $04            ; [delay slot]
  2002164:  0400073f  mtsrim   RBP, $003f              
  2002168:  0308526c  const    gr82, $086c             
  200216c:  03004600  const    gr70, $0000             
  2002170:  03004794  const    gr71, $0094             
  2002174:  02444700  consth   gr71, $4400             
  2002178:  16004847  load     0, 0, gr72, gr71        
  200217c:  a4004803  jmpf     gr72, $2002188             ; -> L_2002188
  2002180:  15474704  add      gr71, gr71, $04            ; [delay slot]
  2002184:  93464601  or       gr70, gr70, $01         
L_2002188:
  2002188:  81464601  sll      gr70, gr70, $01         
  200218c:  16004847  load     0, 0, gr72, gr71        
  2002190:  a4004803  jmpf     gr72, $200219c             ; -> L_200219c
  2002194:  15474704  add      gr71, gr71, $04            ; [delay slot]
  2002198:  93464601  or       gr70, gr70, $01         
L_200219c:
  200219c:  81464601  sll      gr70, gr70, $01         
  20021a0:  16004847  load     0, 0, gr72, gr71        
  20021a4:  a4004803  jmpf     gr72, $20021b0             ; -> L_20021b0
  20021a8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20021ac:  93464601  or       gr70, gr70, $01         
L_20021b0:
  20021b0:  61494600  cpeq     gr73, gr70, $00         
  20021b4:  a4004904  jmpf     gr73, $20021c4             ; -> L_20021c4
  20021b8:  03014900  const    gr73, $0100                ; [delay slot]
  20021bc:  02004900  consth   gr73, $0000             
  20021c0:  9c404049  andn     gr64, gr64, gr73        
L_20021c4:
  20021c4:  03684904  const    gr73, $6804             
  20021c8:  024c4900  consth   gr73, $4c00             
  20021cc:  16004a49  load     0, 0, gr74, gr73        
  20021d0:  814b4618  sll      gr75, gr70, $18         
  20021d4:  924a4a4b  or       gr74, gr74, gr75        
  20021d8:  03004600  const    gr70, $0000             
  20021dc:  02464600  consth   gr70, $4600             
  20021e0:  16004646  load     0, 0, gr70, gr70        
  20021e4:  8346460c  srl      gr70, gr70, $0c         
  20021e8:  8146461c  sll      gr70, gr70, $1c         
  20021ec:  924a4a46  or       gr74, gr74, gr70        
  20021f0:  1e004a49  store    0, 0, gr74, gr73        
  20021f4:  8346461c  srl      gr70, gr70, $1c         
  20021f8:  4d4b4601  cpge     gr75, gr70, $01         
  20021fc:  a4004b04  jmpf     gr75, $200220c             ; -> L_200220c
  2002200:  03004b00  const    gr75, $0000                ; [delay slot]
  2002204:  02204b00  consth   gr75, $2000             
  2002208:  9240404b  or       gr64, gr64, gr75        
L_200220c:
  200220c:  03754630  const    gr70, $7530             
  2002210:  02004600  consth   gr70, $0000             
  2002214:  8145400c  sll      gr69, gr64, $0c         
  2002218:  ac004505  jmpt     gr69, $200222c             ; -> L_200222c
  200221c:  ce000946  mtsr     TMR, gr70                  ; [delay slot]
  2002220:  03754630  const    gr70, $7530             
  2002224:  02014600  consth   gr70, $0100             
  2002228:  ce000946  mtsr     TMR, gr70               
L_200222c:
  200222c:  04000800  mtsrim   TMC, $0000              
  2002230:  c6470300  mfsr     gr71, CFG               
  2002234:  9d474704  andn     gr71, gr71, $04         
  2002238:  8145400d  sll      gr69, gr64, $0d         
  200223c:  ac004503  jmpt     gr69, $2002248             ; -> L_2002248
  2002240:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002244:  93474720  or       gr71, gr71, $20         
L_2002248:
  2002248:  83484718  srl      gr72, gr71, $18         
  200224c:  4d484802  cpge     gr72, gr72, $02         
  2002250:  a4004804  jmpf     gr72, $2002260             ; -> L_2002260
  2002254:  8149401f  sll      gr73, gr64, $1f            ; [delay slot]
  2002258:  ac004903  jmpt     gr73, $2002264             ; -> L_2002264
  200225c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2002260:
  2002260:  93474701  or       gr71, gr71, $01         
L_2002264:
  2002264:  9f000000  inv                              
  2002268:  8145401c  sll      gr69, gr64, $1c         
  200226c:  a4004504  jmpf     gr69, $200227c             ; -> L_200227c
  2002270:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002274:  a000000c  jmp      $20022a4                   ; -> L_20022a4
  2002278:  93474702  or       gr71, gr71, $02            ; [delay slot]
L_200227c:
  200227c:  8145401e  sll      gr69, gr64, $1e         
  2002280:  a4004509  jmpf     gr69, $20022a4             ; -> L_20022a4
  2002284:  9d474702  andn     gr71, gr71, $02            ; [delay slot]
  2002288:  93474702  or       gr71, gr71, $02         
  200228c:  ce000347  mtsr     CFG, gr71               
  2002290:  03084e20  const    gr78, $0820             
  2002294:  020f4ec0  consth   gr78, $0fc0             
  2002298:  03134f75  const    gr79, $1375             
  200229c:  02004f00  consth   gr79, $0000             
  20022a0:  1ee34e4f  store    1, 63, gr78, gr79       
L_20022a4:
  20022a4:  ce000347  mtsr     CFG, gr71               
  20022a8:  81454015  sll      gr69, gr64, $15         
  20022ac:  a4004503  jmpf     gr69, $20022b8             ; -> L_20022b8
  20022b0:  03204300  const    gr67, $2000                ; [delay slot]
  20022b4:  92525243  or       gr82, gr82, gr67        
L_20022b8:
  20022b8:  8145400e  sll      gr69, gr64, $0e         
  20022bc:  a4004503  jmpf     gr69, $20022c8             ; -> L_20022c8
  20022c0:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20022c4:  93525202  or       gr82, gr82, $02         
L_20022c8:
  20022c8:  8145400a  sll      gr69, gr64, $0a         
  20022cc:  a4004503  jmpf     gr69, $20022d8             ; -> L_20022d8
  20022d0:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20022d4:  93525210  or       gr82, gr82, $10         
L_20022d8:
  20022d8:  81454017  sll      gr69, gr64, $17         
  20022dc:  a4004507  jmpf     gr69, $20022f8             ; -> L_20022f8
  20022e0:  03084900  const    gr73, $0800                ; [delay slot]
  20022e4:  9c525249  andn     gr82, gr82, gr73        
  20022e8:  0300495c  const    gr73, $005c             
  20022ec:  02444900  consth   gr73, $4400             
  20022f0:  01ff4cff  constn   gr76, $ffff             
  20022f4:  1e004c49  store    0, 0, gr76, gr73        
L_20022f8:
  20022f8:  81494018  sll      gr73, gr64, $18         
  20022fc:  9a494949  nand     gr73, gr73, gr73        
  2002300:  03004c8c  const    gr76, $008c             
  2002304:  02444c00  consth   gr76, $4400             
  2002308:  1e00494c  store    0, 0, gr73, gr76        
  200230c:  81494019  sll      gr73, gr64, $19         
  2002310:  9a494949  nand     gr73, gr73, gr73        
  2002314:  03004c90  const    gr76, $0090             
  2002318:  02444c00  consth   gr76, $4400             
  200231c:  1e00494c  store    0, 0, gr73, gr76        
  2002320:  0300470a  const    gr71, $000a             
  2002324:  6148470a  cpeq     gr72, gr71, $0a         
  2002328:  a4004803  jmpf     gr72, $2002334             ; -> L_2002334
  200232c:  04000d00  mtsrim   MMU, $0000                 ; [delay slot]
  2002330:  a000000b  jmp      $200235c                   ; -> L_200235c
L_2002334:
  2002334:  6148470b  cpeq     gr72, gr71, $0b            ; [delay slot]
  2002338:  a4004803  jmpf     gr72, $2002344             ; -> L_2002344
  200233c:  04010d00  mtsrim   MMU, $0100                 ; [delay slot]
  2002340:  a0000007  jmp      $200235c                   ; -> L_200235c
L_2002344:
  2002344:  6148470c  cpeq     gr72, gr71, $0c            ; [delay slot]
  2002348:  a4004804  jmpf     gr72, $2002358             ; -> L_2002358
  200234c:  04020d00  mtsrim   MMU, $0200                 ; [delay slot]
  2002350:  a0000003  jmp      $200235c                   ; -> L_200235c
  2002354:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2002358:
  2002358:  04030d00  mtsrim   MMU, $0300              
L_200235c:
  200235c:  03304800  const    gr72, $3000             
  2002360:  02424800  consth   gr72, $4200             
  2002364:  032e4748  const    gr71, $2e48             
  2002368:  024c4700  consth   gr71, $4c00             
  200236c:  1e004847  store    0, 0, gr72, gr71        
  2002370:  814d401a  sll      gr77, gr64, $1a         
  2002374:  a4004d17  jmpf     gr77, $20023d0             ; -> L_20023d0
  2002378:  03284d18  const    gr77, $2818                ; [delay slot]
  200237c:  024c4d00  consth   gr77, $4c00             
  2002380:  0300451e  const    gr69, $001e             
  2002384:  03004400  const    gr68, $0000             
  2002388:  03004600  const    gr70, $0000             
L_200238c:
  200238c:  1e00464d  store    0, 0, gr70, gr77        
  2002390:  154d4d04  add      gr77, gr77, $04         
  2002394:  be004446  mttlb    gr68, gr70              
  2002398:  15444402  add      gr68, gr68, $02         
  200239c:  be004446  mttlb    gr68, gr70              
  20023a0:  b4ff45fb  jmpfdec  gr69, $200238c             ; -> L_200238c
  20023a4:  15444402  add      gr68, gr68, $02            ; [delay slot]
  20023a8:  9d525220  andn     gr82, gr82, $20         
  20023ac:  03004532  const    gr69, $0032             
  20023b0:  032c47a8  const    gr71, $2ca8             
  20023b4:  024c4700  consth   gr71, $4c00             
L_20023b8:
  20023b8:  1e004647  store    0, 0, gr70, gr71        
  20023bc:  b4ff45ff  jmpfdec  gr69, $20023b8             ; -> L_20023b8
  20023c0:  15474704  add      gr71, gr71, $04            ; [delay slot]
  20023c4:  03284710  const    gr71, $2810             
  20023c8:  024c4700  consth   gr71, $4c00             
  20023cc:  1e004647  store    0, 0, gr70, gr71        
L_20023d0:
  20023d0:  8147400f  sll      gr71, gr64, $0f         
  20023d4:  a400470f  jmpf     gr71, $2002410             ; -> L_2002410
  20023d8:  0300457e  const    gr69, $007e                ; [delay slot]
  20023dc:  9d525240  andn     gr82, gr82, $40         
  20023e0:  03004400  const    gr68, $0000             
  20023e4:  03044300  const    gr67, $0400             
  20023e8:  03004700  const    gr71, $0000             
  20023ec:  03004600  const    gr70, $0000             
  20023f0:  03804800  const    gr72, $8000             
  20023f4:  02ff48ff  consth   gr72, $ffff             
L_20023f8:
  20023f8:  be004446  mttlb    gr68, gr70              
  20023fc:  15444401  add      gr68, gr68, $01         
  2002400:  be004446  mttlb    gr68, gr70              
  2002404:  15444401  add      gr68, gr68, $01         
  2002408:  b4ff45fc  jmpfdec  gr69, $20023f8             ; -> L_20023f8
  200240c:  14474743  add      gr71, gr71, gr67           ; [delay slot]
L_2002410:
  2002410:  ce000152  mtsr     OPS, gr82               
  2002414:  03644740  const    gr71, $6440             
  2002418:  024c4700  consth   gr71, $4c00             
  200241c:  16007d47  load     0, 0, gr125, gr71       
  2002420:  03007f00  const    gr127, $0000            
  2002424:  02007f01  consth   gr127, $0001            
  2002428:  247f7d7f  sub      gr127, gr125, gr127     
  200242c:  25017f08  sub      gr1, gr127, $08         
  2002430:  03027e00  const    gr126, $0200            
  2002434:  247e7f7e  sub      gr126, gr127, gr126     
  2002438:  03268048  const    lr0, $2648              
  200243c:  02028000  consth   lr0, $0200              
  2002440:  15817f00  add      lr1, gr127, $00         
  2002444:  036d4708  const    gr71, $6d08             
  2002448:  024c4700  consth   gr71, $4c00             
  200244c:  16004847  load     0, 0, gr72, gr71        
  2002450:  61454803  cpeq     gr69, gr72, $03         
  2002454:  ac00451e  jmpt     gr69, $20024cc             ; -> L_20024cc
  2002458:  61454800  cpeq     gr69, gr72, $00            ; [delay slot]
  200245c:  ac00451c  jmpt     gr69, $20024cc             ; -> L_20024cc
  2002460:  61454801  cpeq     gr69, gr72, $01            ; [delay slot]
  2002464:  ac00451c  jmpt     gr69, $20024d4             ; -> L_20024d4
  2002468:  61454805  cpeq     gr69, gr72, $05            ; [delay slot]
  200246c:  ac00451a  jmpt     gr69, $20024d4             ; -> L_20024d4
  2002470:  61454804  cpeq     gr69, gr72, $04            ; [delay slot]
  2002474:  ac00451a  jmpt     gr69, $20024dc             ; -> L_20024dc
  2002478:  61454802  cpeq     gr69, gr72, $02            ; [delay slot]
  200247c:  ac00451e  jmpt     gr69, $20024f4             ; -> L_20024f4
  2002480:  61454806  cpeq     gr69, gr72, $06            ; [delay slot]
  2002484:  ac004510  jmpt     gr69, $20024c4             ; -> L_20024c4
  2002488:  030247df  const    gr71, $02df                ; [delay slot]
  200248c:  60454847  cpeq     gr69, gr72, gr71        
  2002490:  ac004521  jmpt     gr69, $2002514             ; -> L_2002514
  2002494:  0303470f  const    gr71, $030f                ; [delay slot]
  2002498:  60454847  cpeq     gr69, gr72, gr71        
  200249c:  ac004518  jmpt     gr69, $20024fc             ; -> L_20024fc
  20024a0:  0301474f  const    gr71, $014f                ; [delay slot]
  20024a4:  60454847  cpeq     gr69, gr72, gr71        
  20024a8:  ac00450d  jmpt     gr69, $20024dc             ; -> L_20024dc
  20024ac:  0300470f  const    gr71, $000f                ; [delay slot]
  20024b0:  60454847  cpeq     gr69, gr72, gr71        
  20024b4:  ac004512  jmpt     gr69, $20024fc             ; -> L_20024fc
  20024b8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20024bc:  a0000017  jmp      $2002518                   ; -> L_2002518
  20024c0:  03005150  const    gr81, $0050                ; [delay slot]
L_20024c4:
  20024c4:  a0000015  jmp      $2002518                   ; -> L_2002518
  20024c8:  030a5100  const    gr81, $0a00                ; [delay slot]
L_20024cc:
  20024cc:  a0000013  jmp      $2002518                   ; -> L_2002518
  20024d0:  03045180  const    gr81, $0480                ; [delay slot]
L_20024d4:
  20024d4:  a0000011  jmp      $2002518                   ; -> L_2002518
  20024d8:  03045100  const    gr81, $0400                ; [delay slot]
L_20024dc:
  20024dc:  03684728  const    gr71, $6828             
  20024e0:  024c4700  consth   gr71, $4c00             
  20024e4:  030149e6  const    gr73, $01e6             
  20024e8:  1e004947  store    0, 0, gr73, gr71        
  20024ec:  a000000b  jmp      $2002518                   ; -> L_2002518
  20024f0:  030a5100  const    gr81, $0a00                ; [delay slot]
L_20024f4:
  20024f4:  a0000009  jmp      $2002518                   ; -> L_2002518
  20024f8:  03085100  const    gr81, $0800                ; [delay slot]
L_20024fc:
  20024fc:  03684728  const    gr71, $6828             
  2002500:  024c4700  consth   gr71, $4c00             
  2002504:  03024940  const    gr73, $0240             
  2002508:  1e004947  store    0, 0, gr73, gr71        
  200250c:  a0000003  jmp      $2002518                   ; -> L_2002518
  2002510:  030a5100  const    gr81, $0a00                ; [delay slot]
L_2002514:
  2002514:  03065180  const    gr81, $0680             
L_2002518:
  2002518:  03684728  const    gr71, $6828             
  200251c:  024c4700  consth   gr71, $4c00             
  2002520:  16004947  load     0, 0, gr73, gr71        
  2002524:  15494906  add      gr73, gr73, $06         
  2002528:  ce008349  mtsr     Q, gr73                 
  200252c:  65495100  mul      gr73, gr81, $00         
  2002530:  64495149  mul      gr73, gr81, gr73        
  2002534:  64495149  mul      gr73, gr81, gr73        
  2002538:  64495149  mul      gr73, gr81, gr73        
  200253c:  64495149  mul      gr73, gr81, gr73        
  2002540:  64495149  mul      gr73, gr81, gr73        
  2002544:  64495149  mul      gr73, gr81, gr73        
  2002548:  64495149  mul      gr73, gr81, gr73        
  200254c:  64495149  mul      gr73, gr81, gr73        
  2002550:  64495149  mul      gr73, gr81, gr73        
  2002554:  64495149  mul      gr73, gr81, gr73        
  2002558:  64495149  mul      gr73, gr81, gr73        
  200255c:  64495149  mul      gr73, gr81, gr73        
  2002560:  64495149  mul      gr73, gr81, gr73        
  2002564:  64495149  mul      gr73, gr81, gr73        
  2002568:  64495149  mul      gr73, gr81, gr73        
  200256c:  64495149  mul      gr73, gr81, gr73        
  2002570:  64495149  mul      gr73, gr81, gr73        
  2002574:  64495149  mul      gr73, gr81, gr73        
  2002578:  64495149  mul      gr73, gr81, gr73        
  200257c:  64495149  mul      gr73, gr81, gr73        
  2002580:  64495149  mul      gr73, gr81, gr73        
  2002584:  64495149  mul      gr73, gr81, gr73        
  2002588:  64495149  mul      gr73, gr81, gr73        
  200258c:  64495149  mul      gr73, gr81, gr73        
  2002590:  64495149  mul      gr73, gr81, gr73        
  2002594:  64495149  mul      gr73, gr81, gr73        
  2002598:  64495149  mul      gr73, gr81, gr73        
  200259c:  64495149  mul      gr73, gr81, gr73        
  20025a0:  64495149  mul      gr73, gr81, gr73        
  20025a4:  64495149  mul      gr73, gr81, gr73        
  20025a8:  66495149  mull     gr73, gr81, gr73        
  20025ac:  c6498300  mfsr     gr73, Q                 
  20025b0:  0368471c  const    gr71, $681c             
  20025b4:  024c4700  consth   gr71, $4c00             
  20025b8:  16004847  load     0, 0, gr72, gr71        
  20025bc:  144a4849  add      gr74, gr72, gr73        
  20025c0:  03314620  const    gr70, $3120             
  20025c4:  024c4600  consth   gr70, $4c00             
  20025c8:  1e004a46  store    0, 0, gr74, gr70        
  20025cc:  8146400b  sll      gr70, gr64, $0b         
  20025d0:  03004800  const    gr72, $0000             
  20025d4:  020d4800  consth   gr72, $0d00             
  20025d8:  92484842  or       gr72, gr72, gr66        
  20025dc:  ac004603  jmpt     gr70, $20025e8             ; -> L_20025e8
  20025e0:  81414800  sll      gr65, gr72, $00            ; [delay slot]
  20025e4:  81414a00  sll      gr65, gr74, $00         
L_20025e8:
  20025e8:  03644710  const    gr71, $6410             
  20025ec:  024c4700  consth   gr71, $4c00             
  20025f0:  1e004147  store    0, 0, gr65, gr71        
  20025f4:  0364463c  const    gr70, $643c             
  20025f8:  024c4600  consth   gr70, $4c00             
  20025fc:  16004746  load     0, 0, gr71, gr70        
  2002600:  81474710  sll      gr71, gr71, $10         
  2002604:  03004600  const    gr70, $0000             
  2002608:  02464600  consth   gr70, $4600             
  200260c:  1e004746  store    0, 0, gr71, gr70        
  2002610:  15604e00  add      gr96, gr78, $00         
  2002614:  15614f00  add      gr97, gr79, $00         
  2002618:  ce000152  mtsr     OPS, gr82               
  200261c:  03644304  const    gr67, $6404             
  2002620:  024c4300  consth   gr67, $4c00             
  2002624:  16004343  load     0, 0, gr67, gr67        
  2002628:  ce000b43  mtsr     PC1, gr67               
  200262c:  15434304  add      gr67, gr67, $04         
  2002630:  ce000a43  mtsr     PC0, gr67               
  2002634:  8147400f  sll      gr71, gr64, $0f         
  2002638:  ac004774  jmpt     gr71, $2002808             ; -> L_2002808
  200263c:  03004da1  const    gr77, $00a1                ; [delay slot]
  2002640:  04000600  mtsrim   CHC, $0000              
  2002644:  8c000000  iretinv                          
  2002648:  a0000070  jmp      $2002808                   ; -> L_2002808   ; [delay slot]
  200264c:  03004d9e  const    gr77, $009e                ; [delay slot]
* ==================================================================
*  $2002650  REPORT TO HOST (mailbox $4C007000).  Saves PC0/PC1/OPS/CHC/CHA/CHD,
*  then loops: if the video status register ($44000064) asks for service it
*  calls $2000C14; reads the mailbox word; if it is $73333337 ('s337', the
*  host's acknowledge written by DRVR.s) it writes the reason code (gr77, with a
*  flag) to $4C007004, reads the host argument from $4C007008 and returns;
*  if it is $96666669 (the card's own 'posted' marker) keeps waiting; any other
*  value ends the wait.  Before waiting it posts: reason -> +04, a 16-word
*  register dump (storem from lr2) -> +10, $96666669 -> +00, and echoes +0C.
* ==================================================================
L_2002650:
  2002650:  c6590b00  mfsr     gr89, PC1               
  2002654:  c6580a00  mfsr     gr88, PC0               
  2002658:  c6520100  mfsr     gr82, OPS               
  200265c:  c65a0600  mfsr     gr90, CHC               
  2002660:  c6560400  mfsr     gr86, CHA               
  2002664:  c6570500  mfsr     gr87, CHD               
  2002668:  0400027f  mtsrim   CPS, $007f              
  200266c:  03004700  const    gr71, $0000             
L_2002670:
  2002670:  03004364  const    gr67, $0064             
  2002674:  02444300  consth   gr67, $4400             
  2002678:  16004343  load     0, 0, gr67, gr67        
  200267c:  a4004304  jmpf     gr67, $200268c             ; -> L_200268c
  2002680:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002684:  a8f94564  call     gr69, $2000c14             ; -> L_2000c14
  2002688:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_200268c:
  200268c:  03704300  const    gr67, $7000             
  2002690:  024c4300  consth   gr67, $4c00             
  2002694:  16004743  load     0, 0, gr71, gr67        
  2002698:  03334437  const    gr68, $3337             
  200269c:  02734433  consth   gr68, $7333             
  20026a0:  60454447  cpeq     gr69, gr68, gr71        
  20026a4:  ac004507  jmpt     gr69, $20026c0             ; -> L_20026c0
  20026a8:  03664469  const    gr68, $6669                ; [delay slot]
  20026ac:  02964466  consth   gr68, $9666             
  20026b0:  60454744  cpeq     gr69, gr71, gr68        
  20026b4:  acff45ef  jmpt     gr69, $2002670             ; -> L_2002670
  20026b8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20026bc:  a000002d  jmp      $2002770                   ; -> L_2002770
L_20026c0:
  20026c0:  03704304  const    gr67, $7004                ; [delay slot]
  20026c4:  024c4300  consth   gr67, $4c00             
  20026c8:  1e004d43  store    0, 0, gr77, gr67        
  20026cc:  03704310  const    gr67, $7010             
  20026d0:  024c4300  consth   gr67, $4c00             
  20026d4:  0400870f  mtsrim   CR, $000f               
  20026d8:  3e008243  storem   0, 0, lr2, gr67         
  20026dc:  03704300  const    gr67, $7000             
  20026e0:  024c4300  consth   gr67, $4c00             
  20026e4:  03664469  const    gr68, $6669             
  20026e8:  02964466  consth   gr68, $9666             
  20026ec:  1e004443  store    0, 0, gr68, gr67        
  20026f0:  0370430c  const    gr67, $700c             
  20026f4:  024c4300  consth   gr67, $4c00             
  20026f8:  16004343  load     0, 0, gr67, gr67        
  20026fc:  1e004443  store    0, 0, gr68, gr67        
L_2002700:
  2002700:  03004364  const    gr67, $0064             
  2002704:  02444300  consth   gr67, $4400             
  2002708:  16004543  load     0, 0, gr69, gr67        
  200270c:  a4004504  jmpf     gr69, $200271c             ; -> L_200271c
  2002710:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002714:  a8f94540  call     gr69, $2000c14             ; -> L_2000c14
  2002718:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_200271c:
  200271c:  03704300  const    gr67, $7000             
  2002720:  024c4300  consth   gr67, $4c00             
  2002724:  16004743  load     0, 0, gr71, gr67        
  2002728:  03334437  const    gr68, $3337             
  200272c:  02734433  consth   gr68, $7333             
  2002730:  60454447  cpeq     gr69, gr68, gr71        
  2002734:  ac004507  jmpt     gr69, $2002750             ; -> L_2002750
  2002738:  03664469  const    gr68, $6669                ; [delay slot]
  200273c:  02964466  consth   gr68, $9666             
  2002740:  60454447  cpeq     gr69, gr68, gr71        
  2002744:  acff45ef  jmpt     gr69, $2002700             ; -> L_2002700
  2002748:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  200274c:  a0000009  jmp      $2002770                   ; -> L_2002770
L_2002750:
  2002750:  03704304  const    gr67, $7004                ; [delay slot]
  2002754:  024c4300  consth   gr67, $4c00             
  2002758:  60444444  cpeq     gr68, gr68, gr68        
  200275c:  92444d44  or       gr68, gr77, gr68        
  2002760:  1e004443  store    0, 0, gr68, gr67        
  2002764:  03704308  const    gr67, $7008             
  2002768:  024c4300  consth   gr67, $4c00             
  200276c:  16004743  load     0, 0, gr71, gr67        
L_2002770:
  2002770:  0404027f  mtsrim   CPS, $047f              
  2002774:  ce000b59  mtsr     PC1, gr89               
  2002778:  ce000a58  mtsr     PC0, gr88               
  200277c:  ce000152  mtsr     OPS, gr82               
  2002780:  ce000456  mtsr     CHA, gr86               
  2002784:  ce000557  mtsr     CHD, gr87               
  2002788:  ce00065a  mtsr     CHC, gr90               
  200278c:  c0000046  jmpi     gr70                    
  2002790:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
* ==================================================================
*  $2002794  PC TRACE: increments the count at $4C0061C0 (limit $80) and
*  stores PC1 at $4C006A7C + 4*count, a ring of recent trap return
*  addresses; at the limit it reports reason $B5 through $2002650.
* ==================================================================
L_2002794:
  2002794:  036147c0  const    gr71, $61c0             
  2002798:  024c4700  consth   gr71, $4c00             
  200279c:  16004847  load     0, 0, gr72, gr71        
  20027a0:  4d494880  cpge     gr73, gr72, $80         
  20027a4:  ac00490b  jmpt     gr73, $20027d0             ; -> L_20027d0
  20027a8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20027ac:  15484801  add      gr72, gr72, $01         
L_20027b0:
  20027b0:  1e004847  store    0, 0, gr72, gr71        
  20027b4:  036a477c  const    gr71, $6a7c             
  20027b8:  024c4700  consth   gr71, $4c00             
  20027bc:  81484802  sll      gr72, gr72, $02         
  20027c0:  14474748  add      gr71, gr71, gr72        
  20027c4:  c6480b00  mfsr     gr72, PC1               
  20027c8:  c0000046  jmpi     gr70                    
  20027cc:  1e004847  store    0, 0, gr72, gr71           ; [delay slot]
L_20027d0:
  20027d0:  036147bc  const    gr71, $61bc             
  20027d4:  024c4700  consth   gr71, $4c00             
  20027d8:  1e004647  store    0, 0, gr70, gr71        
  20027dc:  a8ff469d  call     gr70, $2002650             ; -> L_2002650
  20027e0:  03004db5  const    gr77, $00b5                ; [delay slot]
  20027e4:  036147bc  const    gr71, $61bc             
  20027e8:  024c4700  consth   gr71, $4c00             
  20027ec:  16004647  load     0, 0, gr70, gr71        
  20027f0:  01ff49ff  constn   gr73, $ffff             
  20027f4:  1e004947  store    0, 0, gr73, gr71        
  20027f8:  036147c0  const    gr71, $61c0             
  20027fc:  024c4700  consth   gr71, $4c00             
  2002800:  a0ff00ec  jmp      $20027b0                   ; -> L_20027b0
  2002804:  03004800  const    gr72, $0000                ; [delay slot]
* ==================================================================
*  $2002808  FATAL-TRAP REPORTER.  Entry with gr77 = reason code.  Saves
*  the trap context (VAB, OPS, CPS, CFG, CHA, CHD, CHC, RBP, TMC, TMR, PC0,
*  PC1, PC2, LRU, the global and local registers) into the dump area at
*  $4C006748, moves it into lr2.. and calls $2002650 to tell the host; the
*  rest of the routine (to $2002D14) restores the register file in the order
*  VAB, OPS, CPS, CFG, CHA, CHD, CHC, RBP, TMC, TMR, PC0, PC1, PC2, LRU and
*  returns with iret.
* ==================================================================
L_2002808:
  2002808:  61464d92  cpeq     gr70, gr77, $92         
  200280c:  ac004606  jmpt     gr70, $2002824             ; -> L_2002824
  2002810:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002814:  15545800  add      gr84, gr88, $00         
  2002818:  15555900  add      gr85, gr89, $00         
  200281c:  c6580a00  mfsr     gr88, PC0               
  2002820:  c6590b00  mfsr     gr89, PC1               
L_2002824:
  2002824:  c6560400  mfsr     gr86, CHA               
  2002828:  c65a0600  mfsr     gr90, CHC               
  200282c:  c6570500  mfsr     gr87, CHD               
  2002830:  03674748  const    gr71, $6748             
  2002834:  024c4700  consth   gr71, $4c00             
  2002838:  c6460000  mfsr     gr70, VAB               
  200283c:  1e004647  store    0, 0, gr70, gr71        
  2002840:  15474704  add      gr71, gr71, $04         
  2002844:  1e005247  store    0, 0, gr82, gr71        
  2002848:  15474704  add      gr71, gr71, $04         
  200284c:  c6460200  mfsr     gr70, CPS               
  2002850:  1e004647  store    0, 0, gr70, gr71        
  2002854:  15474704  add      gr71, gr71, $04         
  2002858:  c6460300  mfsr     gr70, CFG               
  200285c:  1e004647  store    0, 0, gr70, gr71        
  2002860:  15474704  add      gr71, gr71, $04         
  2002864:  1e005647  store    0, 0, gr86, gr71        
  2002868:  15474704  add      gr71, gr71, $04         
  200286c:  1e005747  store    0, 0, gr87, gr71        
  2002870:  15474704  add      gr71, gr71, $04         
  2002874:  1e005a47  store    0, 0, gr90, gr71        
  2002878:  15474704  add      gr71, gr71, $04         
  200287c:  c6460700  mfsr     gr70, RBP               
  2002880:  1e004647  store    0, 0, gr70, gr71        
  2002884:  15474704  add      gr71, gr71, $04         
  2002888:  c6460800  mfsr     gr70, TMC               
  200288c:  1e004647  store    0, 0, gr70, gr71        
  2002890:  15474704  add      gr71, gr71, $04         
  2002894:  c6460900  mfsr     gr70, TMR               
  2002898:  1e004647  store    0, 0, gr70, gr71        
  200289c:  15474704  add      gr71, gr71, $04         
  20028a0:  1e005847  store    0, 0, gr88, gr71        
  20028a4:  15474704  add      gr71, gr71, $04         
  20028a8:  1e005947  store    0, 0, gr89, gr71        
  20028ac:  15474704  add      gr71, gr71, $04         
  20028b0:  c6460c00  mfsr     gr70, PC2               
  20028b4:  1e004647  store    0, 0, gr70, gr71        
  20028b8:  15474704  add      gr71, gr71, $04         
  20028bc:  c6460d00  mfsr     gr70, MMU               
  20028c0:  1e004647  store    0, 0, gr70, gr71        
  20028c4:  15474704  add      gr71, gr71, $04         
  20028c8:  c6460e00  mfsr     gr70, LRU               
  20028cc:  1e004647  store    0, 0, gr70, gr71        
  20028d0:  15474704  add      gr71, gr71, $04         
  20028d4:  03674788  const    gr71, $6788             
  20028d8:  024c4700  consth   gr71, $4c00             
  20028dc:  c6468000  mfsr     gr70, IPC               
  20028e0:  1e004647  store    0, 0, gr70, gr71        
  20028e4:  15474704  add      gr71, gr71, $04         
  20028e8:  c6468100  mfsr     gr70, IPA               
  20028ec:  1e004647  store    0, 0, gr70, gr71        
  20028f0:  15474704  add      gr71, gr71, $04         
  20028f4:  c6468200  mfsr     gr70, IPB               
  20028f8:  1e004647  store    0, 0, gr70, gr71        
  20028fc:  15474704  add      gr71, gr71, $04         
  2002900:  c6468300  mfsr     gr70, Q                 
  2002904:  1e004647  store    0, 0, gr70, gr71        
  2002908:  15474704  add      gr71, gr71, $04         
  200290c:  c6468400  mfsr     gr70, ALU               
  2002910:  1e004647  store    0, 0, gr70, gr71        
  2002914:  15474704  add      gr71, gr71, $04         
  2002918:  c6468500  mfsr     gr70, BP                
  200291c:  1e004647  store    0, 0, gr70, gr71        
  2002920:  15474704  add      gr71, gr71, $04         
  2002924:  c6468600  mfsr     gr70, FC                
  2002928:  1e004647  store    0, 0, gr70, gr71        
  200292c:  15474704  add      gr71, gr71, $04         
  2002930:  c6468700  mfsr     gr70, CR                
  2002934:  1e004647  store    0, 0, gr70, gr71        
  2002938:  15474704  add      gr71, gr71, $04         
  200293c:  03734818  const    gr72, $7318             
  2002940:  024c4800  consth   gr72, $4c00             
  2002944:  03424742  const    gr71, $4242             
  2002948:  02424753  consth   gr71, $4253             
  200294c:  1e004748  store    0, 0, gr71, gr72        
  2002950:  0300451e  const    gr69, $001e             
  2002954:  03004600  const    gr70, $0000             
  2002958:  03284718  const    gr71, $2818             
  200295c:  024c4700  consth   gr71, $4c00             
  2002960:  036c4b7c  const    gr75, $6c7c             
  2002964:  024c4b00  consth   gr75, $4c00             
  2002968:  0368495c  const    gr73, $685c             
  200296c:  024c4900  consth   gr73, $4c00             
  2002970:  03004400  const    gr68, $0000             
L_2002974:
  2002974:  b64a4400  mftlb    gr74, gr68              
  2002978:  1e004a49  store    0, 0, gr74, gr73        
  200297c:  15494904  add      gr73, gr73, $04         
  2002980:  be004446  mttlb    gr68, gr70              
  2002984:  15444401  add      gr68, gr68, $01         
  2002988:  b64a4400  mftlb    gr74, gr68              
  200298c:  15444401  add      gr68, gr68, $01         
  2002990:  1e004a49  store    0, 0, gr74, gr73        
  2002994:  15494904  add      gr73, gr73, $04         
  2002998:  b64a4400  mftlb    gr74, gr68              
  200299c:  1e004a49  store    0, 0, gr74, gr73        
  20029a0:  15494904  add      gr73, gr73, $04         
  20029a4:  be004446  mttlb    gr68, gr70              
  20029a8:  15444401  add      gr68, gr68, $01         
  20029ac:  b64a4400  mftlb    gr74, gr68              
  20029b0:  15444401  add      gr68, gr68, $01         
  20029b4:  1e004a49  store    0, 0, gr74, gr73        
  20029b8:  15494904  add      gr73, gr73, $04         
  20029bc:  16004a47  load     0, 0, gr74, gr71        
  20029c0:  1e004a4b  store    0, 0, gr74, gr75        
  20029c4:  154b4b04  add      gr75, gr75, $04         
  20029c8:  1e004647  store    0, 0, gr70, gr71        
  20029cc:  b4ff45ea  jmpfdec  gr69, $2002974             ; -> L_2002974
  20029d0:  15474704  add      gr71, gr71, $04            ; [delay slot]
  20029d4:  03004532  const    gr69, $0032             
  20029d8:  032c47a8  const    gr71, $2ca8             
  20029dc:  024c4700  consth   gr71, $4c00             
L_20029e0:
  20029e0:  1e004647  store    0, 0, gr70, gr71        
  20029e4:  b4ff45ff  jmpfdec  gr69, $20029e0             ; -> L_20029e0
  20029e8:  15474704  add      gr71, gr71, $04            ; [delay slot]
  20029ec:  03284710  const    gr71, $2810             
  20029f0:  024c4700  consth   gr71, $4c00             
  20029f4:  1e004647  store    0, 0, gr70, gr71        
  20029f8:  0400027f  mtsrim   CPS, $007f              
  20029fc:  03644744  const    gr71, $6444             
  2002a00:  024c4700  consth   gr71, $4c00             
  2002a04:  1e000147  store    0, 0, gr1, gr71         
  2002a08:  03644748  const    gr71, $6448             
  2002a0c:  024c4700  consth   gr71, $4c00             
  2002a10:  0400873f  mtsrim   CR, $003f               
  2002a14:  3e004047  storem   0, 0, gr64, gr71        
  2002a18:  70400101  aseq     trap64, gr1, gr1        
  2002a1c:  03654748  const    gr71, $6548             
  2002a20:  024c4700  consth   gr71, $4c00             
  2002a24:  83460102  srl      gr70, gr1, $02          
  2002a28:  9146467f  and      gr70, gr70, $7f         
  2002a2c:  93464680  or       gr70, gr70, $80         
  2002a30:  81464602  sll      gr70, gr70, $02         
  2002a34:  ce008146  mtsr     IPA, gr70               
  2002a38:  0400877f  mtsrim   CR, $007f               
  2002a3c:  3e000047  storem   0, 0, gr0, gr71         
  2002a40:  70400101  aseq     trap64, gr1, gr1        
  2002a44:  8146401e  sll      gr70, gr64, $1e         
  2002a48:  a4004609  jmpf     gr70, $2002a6c             ; -> L_2002a6c
  2002a4c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002a50:  036747c8  const    gr71, $67c8             
  2002a54:  024c4700  consth   gr71, $4c00             
  2002a58:  16834646  load     1, 3, gr70, gr70        
  2002a5c:  1e004647  store    0, 0, gr70, gr71        
  2002a60:  15474704  add      gr71, gr71, $04         
  2002a64:  16824646  load     1, 2, gr70, gr70        
  2002a68:  1e006947  store    0, 0, gr105, gr71       
L_2002a6c:
  2002a6c:  15825800  add      lr2, gr88, $00          
  2002a70:  15835900  add      lr3, gr89, $00          
  2002a74:  15845200  add      lr4, gr82, $00          
  2002a78:  15855600  add      lr5, gr86, $00          
  2002a7c:  15865a00  add      lr6, gr90, $00          
  2002a80:  15875700  add      lr7, gr87, $00          
  2002a84:  c6880300  mfsr     lr8, CFG                
  2002a88:  15814d00  add      lr1, gr77, $00          
  2002a8c:  036a475c  const    gr71, $6a5c             
  2002a90:  024c4700  consth   gr71, $4c00             
  2002a94:  04008707  mtsrim   CR, $0007               
  2002a98:  3e008147  storem   0, 0, lr1, gr71         
  2002a9c:  03684b58  const    gr75, $6858             
  2002aa0:  024c4b00  consth   gr75, $4c00             
  2002aa4:  c64c0e00  mfsr     gr76, LRU               
  2002aa8:  1e004c4b  store    0, 0, gr76, gr75        
  2002aac:  81474014  sll      gr71, gr64, $14         
  2002ab0:  ac004707  jmpt     gr71, $2002acc             ; -> L_2002acc
  2002ab4:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002ab8:  a8fe46e6  call     gr70, $2002650             ; -> L_2002650
  2002abc:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002ac0:  8147400f  sll      gr71, gr64, $0f         
  2002ac4:  ac004708  jmpt     gr71, $2002ae4             ; -> L_2002ae4
  2002ac8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2002acc:
  2002acc:  03734818  const    gr72, $7318             
  2002ad0:  024c4800  consth   gr72, $4c00             
  2002ad4:  03144621  const    gr70, $1421             
  2002ad8:  1e004648  store    0, 0, gr70, gr72        
  2002adc:  a0fd0048  jmp      $2001ffc                   ; -> L_2001ffc
  2002ae0:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2002ae4:
  2002ae4:  a8fe46db  call     gr70, $2002650             ; -> L_2002650
  2002ae8:  03004db4  const    gr77, $00b4                ; [delay slot]
  2002aec:  036146c4  const    gr70, $61c4             
  2002af0:  024c4600  consth   gr70, $4c00             
  2002af4:  1e004746  store    0, 0, gr71, gr70        
  2002af8:  03004800  const    gr72, $0000             
  2002afc:  61464701  cpeq     gr70, gr71, $01         
  2002b00:  ac00461e  jmpt     gr70, $2002b78             ; -> L_2002b78
  2002b04:  61464702  cpeq     gr70, gr71, $02            ; [delay slot]
  2002b08:  ac00461b  jmpt     gr70, $2002b74             ; -> L_2002b74
  2002b0c:  61464703  cpeq     gr70, gr71, $03            ; [delay slot]
  2002b10:  ac004608  jmpt     gr70, $2002b30             ; -> L_2002b30
  2002b14:  61464704  cpeq     gr70, gr71, $04            ; [delay slot]
  2002b18:  ac00460f  jmpt     gr70, $2002b54             ; -> L_2002b54
  2002b1c:  61464705  cpeq     gr70, gr71, $05            ; [delay slot]
  2002b20:  acfd4637  jmpt     gr70, $2001ffc             ; -> L_2001ffc
  2002b24:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002b28:  a0ff00ef  jmp      $2002ae4                   ; -> L_2002ae4
  2002b2c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2002b30:
  2002b30:  036147c0  const    gr71, $61c0             
  2002b34:  024c4700  consth   gr71, $4c00             
  2002b38:  03004600  const    gr70, $0000             
  2002b3c:  1e004647  store    0, 0, gr70, gr71        
  2002b40:  036147bc  const    gr71, $61bc             
  2002b44:  024c4700  consth   gr71, $4c00             
  2002b48:  01ff46ff  constn   gr70, $ffff             
  2002b4c:  a0ff00e6  jmp      $2002ae4                   ; -> L_2002ae4
  2002b50:  1e004647  store    0, 0, gr70, gr71           ; [delay slot]
L_2002b54:
  2002b54:  036147c0  const    gr71, $61c0             
  2002b58:  024c4700  consth   gr71, $4c00             
  2002b5c:  03004600  const    gr70, $0000             
  2002b60:  1e004647  store    0, 0, gr70, gr71        
  2002b64:  036147bc  const    gr71, $61bc             
  2002b68:  024c4700  consth   gr71, $4c00             
  2002b6c:  a0ff00de  jmp      $2002ae4                   ; -> L_2002ae4
  2002b70:  1e004647  store    0, 0, gr70, gr71           ; [delay slot]
L_2002b74:
  2002b74:  03204800  const    gr72, $2000             
L_2002b78:
  2002b78:  0400027f  mtsrim   CPS, $007f              
  2002b7c:  81454015  sll      gr69, gr64, $15         
  2002b80:  ac004509  jmpt     gr69, $2002ba4             ; -> L_2002ba4
  2002b84:  0367474c  const    gr71, $674c                ; [delay slot]
  2002b88:  024c4700  consth   gr71, $4c00             
  2002b8c:  16004947  load     0, 0, gr73, gr71        
  2002b90:  03304600  const    gr70, $3000             
  2002b94:  02004600  consth   gr70, $0000             
  2002b98:  9c494946  andn     gr73, gr73, gr70        
  2002b9c:  92494948  or       gr73, gr73, gr72        
  2002ba0:  1e004947  store    0, 0, gr73, gr71        
L_2002ba4:
  2002ba4:  03644744  const    gr71, $6444             
  2002ba8:  024c4700  consth   gr71, $4c00             
  2002bac:  16004647  load     0, 0, gr70, gr71        
  2002bb0:  15014600  add      gr1, gr70, $00          
  2002bb4:  83460102  srl      gr70, gr1, $02          
  2002bb8:  9146467f  and      gr70, gr70, $7f         
  2002bbc:  93464680  or       gr70, gr70, $80         
  2002bc0:  81464602  sll      gr70, gr70, $02         
  2002bc4:  ce008146  mtsr     IPA, gr70               
  2002bc8:  03654748  const    gr71, $6548             
  2002bcc:  024c4700  consth   gr71, $4c00             
  2002bd0:  0400877f  mtsrim   CR, $007f               
  2002bd4:  36000047  loadm    0, 0, gr0, gr71         
  2002bd8:  70400101  aseq     trap64, gr1, gr1        
  2002bdc:  03644748  const    gr71, $6448             
  2002be0:  024c4700  consth   gr71, $4c00             
  2002be4:  0400873f  mtsrim   CR, $003f               
  2002be8:  36004047  loadm    0, 0, gr64, gr71        
  2002bec:  70400101  aseq     trap64, gr1, gr1        
  2002bf0:  0404027f  mtsrim   CPS, $047f              
  2002bf4:  03674748  const    gr71, $6748             
  2002bf8:  024c4700  consth   gr71, $4c00             
  2002bfc:  16004647  load     0, 0, gr70, gr71        
  2002c00:  15474704  add      gr71, gr71, $04         
  2002c04:  ce000046  mtsr     VAB, gr70               
  2002c08:  16004647  load     0, 0, gr70, gr71        
  2002c0c:  15474704  add      gr71, gr71, $04         
  2002c10:  ce000146  mtsr     OPS, gr70               
  2002c14:  15474704  add      gr71, gr71, $04         
  2002c18:  16004647  load     0, 0, gr70, gr71        
  2002c1c:  15474704  add      gr71, gr71, $04         
  2002c20:  ce000346  mtsr     CFG, gr70               
  2002c24:  16004647  load     0, 0, gr70, gr71        
  2002c28:  15474704  add      gr71, gr71, $04         
  2002c2c:  ce000446  mtsr     CHA, gr70               
  2002c30:  16004647  load     0, 0, gr70, gr71        
  2002c34:  15474704  add      gr71, gr71, $04         
  2002c38:  ce000546  mtsr     CHD, gr70               
  2002c3c:  16004647  load     0, 0, gr70, gr71        
  2002c40:  15474704  add      gr71, gr71, $04         
  2002c44:  ce000646  mtsr     CHC, gr70               
  2002c48:  16004647  load     0, 0, gr70, gr71        
  2002c4c:  15474704  add      gr71, gr71, $04         
  2002c50:  ce000746  mtsr     RBP, gr70               
  2002c54:  16004647  load     0, 0, gr70, gr71        
  2002c58:  15474704  add      gr71, gr71, $04         
  2002c5c:  ce000846  mtsr     TMC, gr70               
  2002c60:  16004647  load     0, 0, gr70, gr71        
  2002c64:  15474704  add      gr71, gr71, $04         
  2002c68:  ce000946  mtsr     TMR, gr70               
  2002c6c:  16004647  load     0, 0, gr70, gr71        
  2002c70:  15474704  add      gr71, gr71, $04         
  2002c74:  ce000a46  mtsr     PC0, gr70               
  2002c78:  16004647  load     0, 0, gr70, gr71        
  2002c7c:  15474704  add      gr71, gr71, $04         
  2002c80:  ce000b46  mtsr     PC1, gr70               
  2002c84:  16004647  load     0, 0, gr70, gr71        
  2002c88:  15474704  add      gr71, gr71, $04         
  2002c8c:  ce000c46  mtsr     PC2, gr70               
  2002c90:  16004647  load     0, 0, gr70, gr71        
  2002c94:  15474704  add      gr71, gr71, $04         
  2002c98:  ce000d46  mtsr     MMU, gr70               
  2002c9c:  16004647  load     0, 0, gr70, gr71        
  2002ca0:  15474704  add      gr71, gr71, $04         
  2002ca4:  ce000e46  mtsr     LRU, gr70               
  2002ca8:  03674788  const    gr71, $6788             
  2002cac:  024c4700  consth   gr71, $4c00             
  2002cb0:  16004647  load     0, 0, gr70, gr71        
  2002cb4:  15474704  add      gr71, gr71, $04         
  2002cb8:  ce008046  mtsr     IPC, gr70               
  2002cbc:  16004647  load     0, 0, gr70, gr71        
  2002cc0:  15474704  add      gr71, gr71, $04         
  2002cc4:  ce008146  mtsr     IPA, gr70               
  2002cc8:  16004647  load     0, 0, gr70, gr71        
  2002ccc:  15474704  add      gr71, gr71, $04         
  2002cd0:  ce008246  mtsr     IPB, gr70               
  2002cd4:  16004647  load     0, 0, gr70, gr71        
  2002cd8:  15474704  add      gr71, gr71, $04         
  2002cdc:  ce008346  mtsr     Q, gr70                 
  2002ce0:  16004647  load     0, 0, gr70, gr71        
  2002ce4:  15474704  add      gr71, gr71, $04         
  2002ce8:  ce008446  mtsr     ALU, gr70               
  2002cec:  16004647  load     0, 0, gr70, gr71        
  2002cf0:  15474704  add      gr71, gr71, $04         
  2002cf4:  ce008546  mtsr     BP, gr70                
  2002cf8:  16004647  load     0, 0, gr70, gr71        
  2002cfc:  15474704  add      gr71, gr71, $04         
  2002d00:  ce008646  mtsr     FC, gr70                
  2002d04:  16004647  load     0, 0, gr70, gr71        
  2002d08:  15474704  add      gr71, gr71, $04         
  2002d0c:  ce008746  mtsr     CR, gr70                
  2002d10:  8c000000  iretinv                          
