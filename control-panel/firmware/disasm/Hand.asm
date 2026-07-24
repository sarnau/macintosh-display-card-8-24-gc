* ==================================================================
*  ACEF_1 "Runtime" -- Hand  (Am29000, base $2000000)
* ==================================================================
*  Disassembled with am29k_dasm.py (../../am29k_dasm.py). Unlike
*  ACEF_100_Antelope, this ACEF carries NO symbol table (nsyms=0) and
*  NO relocations (nrel=0 in every section header) -- see
*  ../README.md "No relocations to apply here" for why: this is the
*  always-resident kernel, pre-linked to its fixed hardware map, not a
*  loadable/relocatable module. So there are no `sub_XXXXX:` function
*  boundaries here, only `L_XXXXXXX:` labels auto-generated for
*  in-section branch/call targets.
*
*  gr0-write check (same methodology, see firmware/README.md): 4 of
*  2885 instructions (0.14%) write to gr0 -- likely embedded literals,
*  not executed code. Addresses: $20000c0, $2000178, $20001ac,
*  $20021c4. 100% of the remaining instructions decode as valid
*  (0 `.word` fallbacks).
  2000000:  a00a0002  jmp      $2002808                   ; -> L_2002808
  2000004:  03004c71  const    gr76, $0071                ; [delay slot]
  2000008:  c65909e4  mfsr     gr89, TMR               
  200000c:  c6580840  mfsr     gr88, TMC               
  2000010:  c65202e8  mfsr     gr82, CPS               
  2000014:  040001a3  mtsrim   OPS, $00a3              
  2000018:  c6470070  mfsr     gr71, VAB               
  200001c:  93473bf0  or       gr71, gr59, $f0         
  2000020:  ce007ec3  mtsr     spr126, lr67            
  2000024:  c6567a90  mfsr     gr86, spr122            
  2000028:  c65a79b8  mfsr     gr90, spr121            
  200002c:  81472943  sll      gr71, gr41, $43         
  2000030:  ac003f95  jmpt     gr63, $2000284             ; -> L_2000284
  2000034:  81572290  sll      gr87, gr34, $90            ; [delay slot]
  2000038:  91472aa4  and      gr71, gr42, $a4         
  200003c:  63473f20  cpneq    gr71, gr63, $20         
  2000040:  ac003eb3  jmpt     gr62, $200030c             ; -> L_200030c
  2000044:  8147208d  sll      gr71, gr32, $8d            ; [delay slot]
  2000048:  ac003d2a  jmpt     gr61, $20000f0             ; -> L_20000f0
  200004c:  03003d74  const    gr61, $0074                ; [delay slot]
  2000050:  a8063ef3  call     gr62, $2001c1c             ; -> L_2001c1c
  2000054:  814622b0  sll      gr70, gr34, $b0            ; [delay slot]
  2000058:  614733dc  cpeq     gr71, gr51, $dc         
  200005c:  a4003318  jmpf     gr51, $20000bc             ; -> L_20000bc
  2000060:  70407481  aseq     trap64, gr116, lr1         ; [delay slot]
  2000064:  a0007515  jmp      $20000b8                   ; -> L_20000b8
  2000068:  815630e4  sll      gr86, gr48, $e4            ; [delay slot]
  200006c:  ac0021cb  jmpt     gr33, $2000398             ; -> L_2000398
  2000070:  c6447368  mfsr     gr68, spr115               ; [delay slot]
  2000074:  835a33cc  srl      gr90, gr51, $cc         
  2000078:  1e022ab6  store    0, 2, gr42, lr54        
  200007c:  03003752  const    gr55, $0052             
  2000080:  a806346f  call     gr52, $2001a3c             ; -> L_2001a3c
  2000084:  15462712  add      gr70, gr39, $12            ; [delay slot]
  2000088:  1e02367e  store    0, 2, gr54, gr126       
  200008c:  7040735d  aseq     trap64, gr115, gr93     
  2000090:  a0007330  jmp      $2000150                   ; -> L_2000150
  2000094:  70407201  aseq     trap64, gr114, gr1         ; [delay slot]
  2000098:  03033b18  const    gr59, $0318             
  200009c:  905a3afa  and      gr90, gr58, lr122       
  20000a0:  c657ed48  mfsr     gr87, spr237            
  20000a4:  16022ada  load     0, 2, gr42, lr90        
  20000a8:  ce00eeca  mtsr     spr238, lr74            
  20000ac:  030029f2  const    gr41, $00f2             
  20000b0:  a8062bdb  call     gr43, $2001c1c             ; -> L_2001c1c
L_20000b4:
  20000b4:  15463932  add      gr70, gr57, $32            ; [delay slot]
L_20000b8:
  20000b8:  81442b48  sll      gr68, gr43, $48         
L_20000bc:
  20000bc:  1602325a  load     0, 2, gr50, gr90        
  20000c0:  92002c5a  or       gr0, gr44, gr90         
  20000c4:  ce00e9b7  mtsr     spr233, lr55            
  20000c8:  a0006ae6  jmp      $2000460                   ; -> L_2000460
  20000cc:  70406b41  aseq     trap64, gr107, gr65        ; [delay slot]
  20000d0:  c65a6de8  mfsr     gr90, spr109            
  20000d4:  030031dc  const    gr49, $00dc             
  20000d8:  ce006d2a  mtsr     spr109, gr42            
  20000dc:  814524dd  sll      gr69, gr36, $dd         
  20000e0:  ac002080  jmpt     gr32, $20002e0             ; -> L_20002e0
  20000e4:  c6476590  mfsr     gr71, spr101               ; [delay slot]
  20000e8:  93472098  or       gr71, gr32, $98         
  20000ec:  ce00641b  mtsr     spr100, gr27            
L_20000f0:
  20000f0:  040462df  mtsrim   spr98, $04df            
L_20000f4:
  20000f4:  ce006bd9  mtsr     spr107, lr89            
  20000f8:  ce006abc  mtsr     spr106, lr60            
  20000fc:  ce006172  mtsr     spr97, gr114            
  2000100:  880061c8  iret                             
  2000104:  c647639c  mfsr     gr71, spr99                ; [delay slot]
  2000108:  91472511  and      gr71, gr37, $11         
  200010c:  61472570  cpeq     gr71, gr37, $70         
  2000110:  ac002402  jmpt     gr36, $2000118             ; -> L_2000118
  2000114:  70405db1  aseq     trap64, gr93, lr49         ; [delay slot]
L_2000118:
  2000118:  255408dc  sub      gr84, gr8, $dc          
  200011c:  16000548  load     0, 0, gr5, gr72         
  2000120:  25540984  sub      gr84, gr9, $84          
  2000124:  16000534  load     0, 0, gr5, gr52         
  2000128:  a0095e5c  jmp      $2002698                   ; -> L_2002698
  200012c:  03001352  const    gr19, $0052                ; [delay slot]
  2000130:  c644d968  mfsr     gr68, spr217            
  2000134:  814d1bde  sll      gr77, gr27, $de         
  2000138:  814715f0  sll      gr71, gr21, $f0         
  200013c:  a8061dec  call     gr29, $2001cec             ; -> L_2001cec
  2000140:  81460f84  sll      gr70, gr15, $84            ; [delay slot]
  2000144:  60471e5d  cpeq     gr71, gr30, gr93        
  2000148:  a4001d3c  jmpf     gr29, $2000238             ; -> L_2000238
  200014c:  70405b5d  aseq     trap64, gr91, gr93         ; [delay slot]
L_2000150:
  2000150:  a0005b6f  jmp      $200030c                   ; -> L_200030c
  2000154:  81561d00  sll      gr86, gr29, $00            ; [delay slot]
  2000158:  a40003ff  jmpf     gr3, $2000554              ; -> L_2000554
  200015c:  254411a1  sub      gr68, gr17, $a1            ; [delay slot]
  2000160:  030302b4  const    gr2, $03b4              
  2000164:  905701c6  and      gr87, gr1, lr70         
  2000168:  c64dd690  mfsr     gr77, spr214            
  200016c:  614701f0  cpeq     gr71, gr1, $f0          
  2000170:  a4001107  jmpf     gr17, $200018c             ; -> L_200018c
  2000174:  03001034  const    gr16, $0034                ; [delay slot]
  2000178:  03020058  const    gr0, $0258              
  200017c:  a80615b0  call     gr21, $2001c3c             ; -> L_2001c3c
  2000180:  81460600  sll      gr70, gr6, $00             ; [delay slot]
  2000184:  ce00d1b7  mtsr     spr209, lr55            
  2000188:  160208a2  load     0, 2, gr8, lr34         
L_200018c:
  200018c:  61471544  cpeq     gr71, gr21, $44         
  2000190:  ac0014ed  jmpt     gr20, $2000544             ; -> L_2000544
  2000194:  154615de  add      gr70, gr21, $de            ; [delay slot]
  2000198:  03001472  const    gr20, $0072             
  200019c:  a8060974  call     gr9, $2001b6c              ; -> L_2001b6c
  20001a0:  15461b86  add      gr70, gr27, $86            ; [delay slot]
  20001a4:  81491480  sll      gr73, gr20, $80         
  20001a8:  160215fe  load     0, 2, gr21, lr126       
  20001ac:  92001515  or       gr0, gr21, gr21         
  20001b0:  15561ea4  add      gr86, gr30, $a4         
  20001b4:  b4ff0c6e  jmpfdec  gr12, $1ffff6c          
  20001b8:  15571fe0  add      gr87, gr31, $e0            ; [delay slot]
  20001bc:  a000483a  jmp      $20002a4                   ; -> L_20002a4
  20001c0:  ce00c985  mtsr     spr201, lr5                ; [delay slot]
  20001c4:  03031d60  const    gr29, $0360             
  20001c8:  90571d4a  and      gr87, gr29, gr74        
  20001cc:  c64dcb70  mfsr     gr77, spr203            
L_20001d0:
  20001d0:  61471c04  cpeq     gr71, gr28, $04         
  20001d4:  a40003b3  jmpf     gr3, $20004a0              ; -> L_20004a0
  20001d8:  030003dc  const    gr3, $00dc                 ; [delay slot]
  20001dc:  0302131c  const    gr19, $021c             
  20001e0:  ce00c4d7  mtsr     spr196, lr87            
  20001e4:  a80600f2  call     gr0, $2001dac              ; -> L_2001dac
  20001e8:  814610e4  sll      gr70, gr16, $e4            ; [delay slot]
  20001ec:  835a46d0  srl      gr90, gr70, $d0         
  20001f0:  1e021c2e  store    0, 2, gr28, gr46        
  20001f4:  614700d8  cpeq     gr71, gr0, $d8          
  20001f8:  ac0007f5  jmpt     gr7, $20005cc              ; -> L_20005cc
  20001fc:  15460652  add      gr70, gr6, $52             ; [delay slot]
  2000200:  03000686  const    gr6, $0086              
  2000204:  a806049a  call     gr4, $2001c6c              ; -> L_2001c6c
  2000208:  1546143a  add      gr70, gr20, $3a            ; [delay slot]
  200020c:  1e02421a  store    0, 2, gr66, gr26        
  2000210:  15561524  add      gr86, gr21, $24         
  2000214:  b4ff07ef  jmpfdec  gr7, $20001d0              ; -> L_20001d0
  2000218:  1556ebe0  add      gr86, lr107, $e0           ; [delay slot]
  200021c:  a001bda2  jmp      $20008a4                   ; -> L_20008a4
  2000220:  ce013c05  mtsr     spr60, gr5                 ; [delay slot]
  2000224:  a0febe37  jmp      $1fffb00                
  2000228:  7041bf91  aseq     trap65, lr63, lr17         ; [delay slot]
  200022c:  8146e4e1  sll      gr70, lr100, $e1        
  2000230:  ac01f913  jmpt     lr121, $200067c            ; -> L_200067c
  2000234:  7041be31  aseq     trap65, lr62, gr49         ; [delay slot]
L_2000238:
  2000238:  ac01e851  jmpt     lr104, $200077c            ; -> L_200077c
  200023c:  c645bd1c  mfsr     gr69, spr189               ; [delay slot]
  2000240:  835bfc10  srl      gr91, lr124, $10        
  2000244:  1e03e3b6  store    0, 3, lr99, lr54        
  2000248:  1557ece6  add      gr87, lr108, $e6        
  200024c:  1e03fe16  store    0, 3, lr126, gr22       
  2000250:  7041bae9  aseq     trap65, lr58, lr105     
  2000254:  a0febb43  jmp      $1fffb60                
  2000258:  7041ba71  aseq     trap65, lr58, gr113        ; [delay slot]
  200025c:  0302e32c  const    lr99, $022c             
L_2000260:
  2000260:  1603f1d2  load     0, 3, lr113, lr82       
  2000264:  905be1ca  and      gr91, lr97, lr74        
  2000268:  c65637b8  mfsr     gr86, spr55             
L_200026c:
  200026c:  ce013706  mtsr     spr55, gr6              
  2000270:  1557e6a2  add      gr87, lr102, $a2        
  2000274:  8145f490  sll      gr69, lr116, $90        
L_2000278:
  2000278:  1603eab2  load     0, 3, lr106, lr50       
  200027c:  9201f47a  or       gr1, lr116, gr122       
  2000280:  ce01319f  mtsr     spr49, lr31             
L_2000284:
  2000284:  a0feb20f  jmp      $1fffac0                
  2000288:  7041b311  aseq     trap65, lr51, gr17         ; [delay slot]
  200028c:  c6453570  mfsr     gr69, spr53             
  2000290:  a401e410  jmpf     lr100, $20006d0            ; -> L_20006d0
  2000294:  2545e8b1  sub      gr69, lr104, $b1           ; [delay slot]
  2000298:  0302fb24  const    lr123, $0224            
  200029c:  9056fb46  and      gr86, lr123, gr70       
  20002a0:  c64c2d80  mfsr     gr76, spr45             
L_20002a4:
  20002a4:  6146fa60  cpeq     gr70, lr122, $60        
  20002a8:  a401e9e7  jmpf     lr105, $2000a44            ; -> L_2000a44
L_20002ac:
  20002ac:  7041afc1  aseq     trap65, lr47, lr65         ; [delay slot]
  20002b0:  0303f968  const    lr121, $0368            
  20002b4:  1603f58a  load     0, 3, lr117, lr10       
  20002b8:  ce0128a7  mtsr     spr40, lr39             
  20002bc:  1557fe52  add      gr87, lr126, $52        
  20002c0:  8146f394  sll      gr70, lr115, $94        
  20002c4:  1603f346  load     0, 3, lr115, gr70       
  20002c8:  9201f07f  or       gr1, lr112, gr127       
  20002cc:  1557fc5e  add      gr87, lr124, $5e        
  20002d0:  b4feefd5  jmpfdec  lr111, $1fffe24         
  20002d4:  1556fc04  add      gr86, lr124, $04           ; [delay slot]
  20002d8:  a0fea437  jmp      $1fffbb4                
L_20002dc:
  20002dc:  ce0125ed  mtsr     spr37, lr109               ; [delay slot]
L_20002e0:
  20002e0:  0302f2b4  const    lr114, $02b4            
  20002e4:  9056f1c6  and      gr86, lr113, lr70       
  20002e8:  c64c2790  mfsr     gr76, spr39             
  20002ec:  6146f1f0  cpeq     gr70, lr113, $f0        
  20002f0:  a401e107  jmpf     lr97, $200070c             ; -> L_200070c
  20002f4:  7041a631  aseq     trap65, lr38, gr49         ; [delay slot]
  20002f8:  0303f058  const    lr112, $0358            
  20002fc:  ce01214b  mtsr     spr33, gr75             
  2000300:  835ba010  srl      gr91, lr32, $10         
  2000304:  1e03fbb6  store    0, 3, lr123, lr54       
L_2000308:
  2000308:  1557f4e6  add      gr87, lr116, $e6        
L_200030c:
  200030c:  1e03a216  store    0, 3, lr34, gr22        
  2000310:  1557f5ea  add      gr87, lr117, $ea        
  2000314:  b4fee72a  jmpfdec  lr103, $1fffbbc         
  2000318:  1556f474  add      gr86, lr116, $74           ; [delay slot]
L_200031c:
  200031c:  a0fe9c12  jmp      $1fffb64                
  2000320:  ce011cc9  mtsr     spr28, lr73                ; [delay slot]
  2000324:  04059cef  mtsrim   spr156, $05ef           
  2000328:  c6559bb8  mfsr     gr85, spr155            
  200032c:  9155cb5f  and      gr85, lr75, $5f         
  2000330:  6155cca0  cpeq     gr85, lr76, $a0         
  2000334:  ac01ccd0  jmpt     lr76, $2000a74             ; -> L_2000a74
  2000338:  704199e5  aseq     trap65, lr25, lr101        ; [delay slot]
  200033c:  0301cd7c  const    lr77, $017c             
  2000340:  0245ccc8  consth   lr76, $45c8             
  2000344:  0301ce9c  const    lr78, $019c             
  2000348:  1e01ce45  store    0, 1, lr78, gr69        
  200034c:  01fece8f  constn   lr78, $fe8f             
  2000350:  a0fe9b2a  jmp      $1fffbf8                
  2000354:  1e01c0e5  store    0, 1, lr64, lr101          ; [delay slot]
  2000358:  0305c1d8  const    lr65, $05d8             
  200035c:  0331c08c  const    lr64, $318c             
  2000360:  024dc180  consth   lr65, $4d80             
  2000364:  1e01d134  store    0, 1, lr81, gr52        
  2000368:  1555c2e0  add      gr85, lr66, $e0         
  200036c:  1e01c094  store    0, 1, lr64, lr20        
  2000370:  1555c26c  add      gr85, lr66, $6c         
  2000374:  1e01cd88  store    0, 1, lr77, lr8         
  2000378:  1555c4f4  add      gr85, lr68, $f4         
L_200037c:
  200037c:  1e01c704  store    0, 1, lr71, gr4         
  2000380:  1555c580  add      gr85, lr69, $80         
  2000384:  1e01c344  store    0, 1, lr67, gr68        
  2000388:  1555c63c  add      gr85, lr70, $3c         
  200038c:  1e01ca08  store    0, 1, lr74, gr8         
  2000390:  1555c724  add      gr85, lr71, $24         
  2000394:  1e01ca54  store    0, 1, lr74, gr84        
L_2000398:
  2000398:  c65b8ae4  mfsr     gr91, spr138            
L_200039c:
  200039c:  9c5bd7f5  andn     gr91, lr87, lr117       
  20003a0:  935bd749  or       gr91, lr87, $49         
  20003a4:  9d56d49d  andn     gr86, lr84, $9d         
  20003a8:  ce0188c7  mtsr     spr136, lr71            
  20003ac:  c6578af0  mfsr     gr87, spr138            
  20003b0:  c6568b04  mfsr     gr86, spr139            
  20003b4:  c6538e30  mfsr     gr83, spr142            
  20003b8:  c6598558  mfsr     gr89, BP                
  20003bc:  c658831c  mfsr     gr88, Q                 
  20003c0:  04018a7f  mtsrim   spr138, $017f           
  20003c4:  0301dce0  const    lr92, $01e0             
  20003c8:  0247dfe4  consth   lr95, $47e4             
  20003cc:  1601df15  load     0, 1, lr95, gr21        
  20003d0:  04058997  mtsrim   spr137, $0597           
  20003d4:  ce018085  mtsr     IPC, lr5                
  20003d8:  ce018128  mtsr     IPA, gr40               
  20003dc:  ce018582  mtsr     BP, lr2                 
  20003e0:  ce0181d2  mtsr     IPA, lr82               
  20003e4:  ce0183c7  mtsr     Q, lr71                 
  20003e8:  ce0181e2  mtsr     IPA, lr98               
  20003ec:  1601de08  load     0, 1, lr94, gr8         
  20003f0:  2555d4a4  sub      gr85, lr84, $a4         
  20003f4:  1601d8d4  load     0, 1, lr88, lr84        
  20003f8:  2555d4e0  sub      gr85, lr84, $e0         
  20003fc:  1601d274  load     0, 1, lr82, gr116       
  2000400:  2555d5cc  sub      gr85, lr85, $cc         
  2000404:  1601d5c8  load     0, 1, lr85, lr72        
  2000408:  2555d614  sub      gr85, lr86, $14         
  200040c:  1601d824  load     0, 1, lr88, gr36        
  2000410:  2555d700  sub      gr85, lr87, $00         
  2000414:  1601aae4  load     0, 1, lr42, lr100       
  2000418:  2555a8dc  sub      gr85, lr40, $dc         
  200041c:  1601b848  load     0, 1, lr56, gr72        
  2000420:  8155a89b  sll      gr85, lr40, $9b         
  2000424:  ac01a96f  jmpt     lr41, $20009e0             ; -> L_20009e0
L_2000428:
  2000428:  8155abf9  sll      gr85, lr43, $f9            ; [delay slot]
  200042c:  ac01aade  jmpt     lr42, $2000ba4             ; -> L_2000ba4
  2000430:  8155be7f  sll      gr85, lr62, $7f            ; [delay slot]
  2000434:  a401abd9  jmpf     lr43, $2000b98             ; -> L_2000b98
  2000438:  0301ac80  const    lr44, $0180                ; [delay slot]
  200043c:  0245ac50  consth   lr44, $4550             
  2000440:  1601add0  load     0, 1, lr45, lr80        
  2000444:  acfeada8  jmpt     lr45, $1fffee4          
  2000448:  9154af3b  and      gr84, lr47, $3b            ; [delay slot]
L_200044c:
  200044c:  6155af5f  cpeq     gr85, lr47, $5f         
  2000450:  ac01af24  jmpt     lr47, $20008e0             ; -> L_20008e0
  2000454:  6155ae00  cpeq     gr85, lr46, $00            ; [delay slot]
  2000458:  a401a0e3  jmpf     lr32, $2000be4             ; -> L_2000be4
  200045c:  7041f4a1  aseq     trap65, lr116, lr33        ; [delay slot]
L_2000460:
  2000460:  c654f348  mfsr     gr84, spr243            
  2000464:  8154a39d  sll      gr84, lr35, $9d         
  2000468:  ac01a3db  jmpt     lr35, $2000bd4             ; -> L_2000bd4
  200046c:  7041f7f1  aseq     trap65, lr119, lr113       ; [delay slot]
  2000470:  8801f604  iret                             
  2000474:  0366a3d0  const    lr35, $66d0                ; [delay slot]
  2000478:  024da358  consth   lr35, $4d58             
  200047c:  1601a548  load     0, 1, lr37, gr72        
  2000480:  a401a507  jmpf     lr37, $200089c             ; -> L_200089c
  2000484:  1554a4e1  add      gr84, lr36, $e1            ; [delay slot]
  2000488:  1e01a7b0  store    0, 1, lr39, lr48        
  200048c:  c654f440  mfsr     gr84, spr244            
  2000490:  9d54a6e9  andn     gr84, lr38, $e9         
  2000494:  ce01f589  mtsr     spr245, lr9             
  2000498:  8801f370  iret                             
  200049c:  a009ec0b  jmp      $20028c8                   ; -> L_20028c8   ; [delay slot]
L_20004a0:
  20004a0:  0301a014  const    lr32, $0114                ; [delay slot]
  20004a4:  0331ba00  const    lr58, $3100             
  20004a8:  024dbbb8  consth   lr59, $4db8             
  20004ac:  1e01a908  store    0, 1, lr41, gr8         
  20004b0:  1555bca4  add      gr85, lr60, $a4         
  20004b4:  1e01abd4  store    0, 1, lr43, lr84        
  20004b8:  1555bce0  add      gr85, lr60, $e0         
  20004bc:  1e01ac74  store    0, 1, lr44, gr116       
  20004c0:  1555bdcc  add      gr85, lr61, $cc         
  20004c4:  1e01bcc8  store    0, 1, lr60, lr72        
  20004c8:  1555be14  add      gr85, lr62, $14         
  20004cc:  1e01b024  store    0, 1, lr48, gr36        
  20004d0:  1555bf00  add      gr85, lr63, $00         
  20004d4:  1e01b3e4  store    0, 1, lr51, lr100       
L_20004d8:
  20004d8:  1555b0dc  add      gr85, lr48, $dc         
  20004dc:  1e01bc48  store    0, 1, lr60, gr72        
  20004e0:  1555b184  add      gr85, lr49, $84         
  20004e4:  1e01bc34  store    0, 1, lr60, gr52        
  20004e8:  0305b3e5  const    lr51, $05e5             
  20004ec:  c65be0c0  mfsr     gr91, spr224            
  20004f0:  9c5bbc3d  andn     gr91, lr60, gr61        
  20004f4:  ce01e186  mtsr     spr225, lr6             
  20004f8:  c657e4f0  mfsr     gr87, spr228            
  20004fc:  c656e550  mfsr     gr86, spr229            
  2000500:  c659eb84  mfsr     gr89, spr235            
  2000504:  c658ea10  mfsr     gr88, spr234            
  2000508:  0401e047  mtsrim   spr224, $0147           
  200050c:  8345b440  srl      gr69, lr52, $40         
  2000510:  6147a72f  cpeq     gr71, lr39, $2f         
  2000514:  0301a000  const    lr32, $0100             
L_2000518:
  2000518:  a4019ae0  jmpf     lr26, $2000c98             ; -> L_2000c98
  200051c:  02019ea1  consth   lr30, $01a1                ; [delay slot]
  2000520:  83458b50  srl      gr69, lr11, $50         
  2000524:  91459a93  and      gr69, lr26, $93         
  2000528:  80429dd4  sll      gr66, lr29, lr84        
  200052c:  03019af0  const    lr26, $01f0             
  2000530:  02479a04  consth   lr26, $4704             
  2000534:  16019974  load     0, 1, lr25, gr116       
  2000538:  9c47991b  andn     gr71, lr25, gr27        
  200053c:  1e019e58  store    0, 1, lr30, gr88        
  2000540:  0405da7f  mtsrim   spr218, $057f           
L_2000544:
  2000544:  ce01d2b9  mtsr     spr210, lr57            
  2000548:  ce01d0bc  mtsr     spr208, lr60            
L_200054c:
  200054c:  ce01de16  mtsr     spr222, gr22            
  2000550:  ce01debf  mtsr     spr222, lr63            
L_2000554:
  2000554:  ce01dd86  mtsr     spr221, lr6             
  2000558:  16018224  load     0, 1, lr2, gr36         
  200055c:  255580d4  sub      gr85, lr0, $d4          
  2000560:  16018dd0  load     0, 1, lr13, lr80        
  2000564:  25558294  sub      gr85, lr2, $94          
  2000568:  160180ec  load     0, 1, lr0, lr108        
  200056c:  25558358  sub      gr85, lr3, $58          
  2000570:  16018af4  load     0, 1, lr10, lr116       
  2000574:  25558484  sub      gr85, lr4, $84          
  2000578:  160186b0  load     0, 1, lr6, lr48         
  200057c:  25558424  sub      gr85, lr4, $24          
  2000580:  1601959c  load     0, 1, lr21, lr28        
L_2000584:
  2000584:  25558698  sub      gr85, lr6, $98          
  2000588:  16019144  load     0, 1, lr17, gr68        
  200058c:  25558674  sub      gr85, lr6, $74          
  2000590:  16019550  load     0, 1, lr21, gr80        
  2000594:  a4018cb9  jmpf     lr12, $2000c78             ; -> L_2000c78
  2000598:  7041cdd9  aseq     trap65, lr77, lr89         ; [delay slot]
  200059c:  c655ca1c  mfsr     gr85, spr202            
  20005a0:  9d559981  andn     gr85, lr25, $81         
  20005a4:  ce01cb34  mtsr     spr203, gr52            
  20005a8:  ce01c59d  mtsr     spr197, lr29            
  20005ac:  1555b7c4  add      gr85, lr55, $c4         
  20005b0:  ce01c43c  mtsr     spr196, gr60            
L_20005b4:
  20005b4:  8c01cfdc  iretinv                          
  20005b8:  c654cef0  mfsr     gr84, spr206               ; [delay slot]
  20005bc:  83559d48  srl      gr85, lr29, $48         
  20005c0:  91559d87  and      gr85, lr29, $87         
  20005c4:  03018d12  const    lr13, $0112             
  20005c8:  80458e6c  sll      gr69, lr14, gr108       
L_20005cc:
  20005cc:  83559f4c  srl      gr85, lr31, $4c         
  20005d0:  91559f2f  and      gr85, lr31, $2f         
  20005d4:  15559f01  add      gr85, lr31, $01         
  20005d8:  244280b0  sub      gr66, lr0, lr48         
  20005dc:  254581a1  sub      gr69, lr1, $a1          
  20005e0:  81458158  sll      gr69, lr1, $58          
  20005e4:  0301929c  const    lr18, $019c             
  20005e8:  0201926f  consth   lr18, $016f             
  20005ec:  9c5493a4  andn     gr84, lr19, lr36        
  20005f0:  92549340  or       gr84, lr19, gr64        
  20005f4:  93549231  or       gr84, lr18, $31         
  20005f8:  8355925a  srl      gr85, lr18, $5a         
  20005fc:  915594e3  and      gr85, lr20, $e3         
  2000600:  24559443  sub      gr85, lr20, gr67        
  2000604:  c64540e0  mfsr     gr69, spr64             
  2000608:  815596e6  sll      gr85, lr22, $e6         
  200060c:  ce014314  mtsr     spr67, gr20             
  2000610:  7041c2e9  aseq     trap65, lr66, lr105     
  2000614:  8150c3dc  sll      gr80, lr67, $dc         
  2000618:  ce01c621  mtsr     spr198, gr33            
  200061c:  ce01bd94  mtsr     spr189, lr20            
  2000620:  03027978  const    gr121, $0278            
  2000624:  9c546bd4  andn     gr84, gr107, lr84       
L_2000628:
  2000628:  92546aec  or       gr84, gr106, lr108      
  200062c:  ce013909  mtsr     spr57, gr9              
  2000630:  81427ba2  sll      gr66, gr123, $a2        
  2000634:  c6553c80  mfsr     gr85, spr60             
  2000638:  24556ca7  sub      gr85, gr108, lr39       
  200063c:  ce013c74  mtsr     spr60, gr116            
  2000640:  880139c8  iret                             
  2000644:  1583629c  add      lr3, gr98, $9c             ; [delay slot]
  2000648:  15826310  add      lr2, gr99, $10          
  200064c:  c6463b70  mfsr     gr70, spr59             
  2000650:  91467c05  and      gr70, gr124, $05        
  2000654:  614673b0  cpeq     gr70, gr115, $b0        
  2000658:  a40173dc  jmpf     gr115, $2000dc8            ; -> L_2000dc8
  200065c:  7041351d  aseq     trap65, gr53, gr29         ; [delay slot]
  2000660:  c6833f80  mfsr     lr3, spr63              
  2000664:  c6823e60  mfsr     lr2, spr62              
L_2000668:
  2000668:  a009368c  jmp      $2002c98                   ; -> L_2002c98
  200066c:  03017b55  const    gr123, $0155               ; [delay slot]
  2000670:  c6553068  mfsr     gr85, spr48             
  2000674:  815463c9  sll      gr84, gr99, $c9         
L_2000678:
  2000678:  a40165f4  jmpf     gr101, $2000e48            ; -> L_2000e48
L_200067c:
  200067c:  9d556451  andn     gr85, gr100, $51           ; [delay slot]
L_2000680:
  2000680:  ce0137d0  mtsr     spr55, lr80             
  2000684:  88013110  iret                             
  2000688:  c6453938  mfsr     gr69, spr57                ; [delay slot]
  200068c:  614c765c  cpeq     gr76, gr118, $5c        
  2000690:  ac097e7e  jmpt     gr126, $2002c88            ; -> L_2002c88
  2000694:  03017e95  const    gr126, $0195               ; [delay slot]
  2000698:  834568ee  srl      gr69, gr104, $ee        
  200069c:  914c69bf  and      gr76, gr105, $bf        
  20006a0:  81456942  sll      gr69, gr105, $42        
  20006a4:  03296684  const    gr102, $2984            
  20006a8:  024d6690  consth   gr102, $4d90            
  20006ac:  814663f2  sll      gr70, gr99, $f2         
  20006b0:  14466643  add      gr70, gr102, gr67       
  20006b4:  16016377  load     0, 1, gr99, gr119       
  20006b8:  15496358  add      gr73, gr99, $58         
  20006bc:  6146601c  cpeq     gr70, gr96, $1c         
  20006c0:  ac046f94  jmpt     gr111, $2001910            ; -> L_2001910
  20006c4:  704128e1  aseq     trap65, gr40, lr97         ; [delay slot]
  20006c8:  154d62e4  add      gr77, gr98, $e4         
  20006cc:  16016d0c  load     0, 1, gr109, gr12       
L_20006d0:
  20006d0:  60466cac  cpeq     gr70, gr108, lr44       
  20006d4:  ac016cd8  jmpt     gr108, $2000e34            ; -> L_2000e34
  20006d8:  1546677c  add      gr70, gr103, $7c           ; [delay slot]
  20006dc:  a0fe2428  jmp      $1ffff7c                
  20006e0:  16016dc3  load     0, 1, gr109, lr67          ; [delay slot]
  20006e4:  15486a94  add      gr72, gr106, $94        
  20006e8:  160164f1  load     0, 1, gr100, lr113      
  20006ec:  0381765c  const    gr118, $815c            
  20006f0:  02fe715f  consth   gr113, $fe5f            
  20006f4:  904571c4  and      gr69, gr113, lr68       
  20006f8:  034871e4  const    gr113, $48e4            
L_20006fc:
  20006fc:  92457164  or       gr69, gr113, gr100      
  2000700:  c6502fc8  mfsr     gr80, spr47             
  2000704:  be0173d8  mttlb    gr115, lr88             
  2000708:  15507311  add      gr80, gr115, $11        
L_200070c:
  200070c:  be017333  mttlb    gr115, gr51             
  2000710:  8c012304  iretinv                          
  2000714:  c64b12b0  mfsr     gr75, spr18                ; [delay slot]
  2000718:  c64518d8  mfsr     gr69, spr24             
  200071c:  0381501c  const    gr80, $811c             
  2000720:  02fe517f  consth   gr81, $fe7f             
  2000724:  9042592c  and      gr66, gr89, gr44        
  2000728:  037752e4  const    gr82, $77e4             
  200072c:  92425283  or       gr66, gr82, lr3         
  2000730:  be01542b  mttlb    gr84, gr43              
  2000734:  154b55dd  add      gr75, gr85, $dd         
  2000738:  01fd5bf0  constn   gr91, $fdf0             
  200073c:  90455c13  and      gr69, gr92, gr19        
L_2000740:
  2000740:  83465d98  srl      gr70, gr93, $98         
  2000744:  15465e00  add      gr70, gr94, $00         
  2000748:  03015239  const    gr82, $0139             
  200074c:  8049521b  sll      gr73, gr82, gr27        
  2000750:  9049537b  and      gr73, gr83, gr123       
  2000754:  61495300  cpeq     gr73, gr83, $00         
  2000758:  ac015cfb  jmpt     gr92, $2000f44             ; -> L_2000f44
  200075c:  814655a4  sll      gr70, gr85, $a4            ; [delay slot]
  2000760:  a4015255  jmpf     gr82, $2000cb4             ; -> L_2000cb4
  2000764:  03025a63  const    gr90, $0263                ; [delay slot]
  2000768:  904d4ddc  and      gr77, gr77, lr92        
  200076c:  03305b9c  const    gr91, $309c             
  2000770:  024d5b04  consth   gr91, $4d04             
  2000774:  254d5b31  sub      gr77, gr91, $31         
  2000778:  ac015b4f  jmpt     gr91, $2000cb4             ; -> L_2000cb4
L_200077c:
  200077c:  7041111d  aseq     trap65, gr17, gr29         ; [delay slot]
  2000780:  1601414d  load     0, 1, gr65, gr77        
  2000784:  154c5ce4  add      gr76, gr92, $e4         
  2000788:  604456b5  cpeq     gr68, gr86, lr53        
  200078c:  ac01574f  jmpt     gr87, $2000cc8             ; -> L_2000cc8
L_2000790:
  2000790:  424457b9  cpltu    gr68, gr87, lr57           ; [delay slot]
  2000794:  ac0156db  jmpt     gr86, $2000f00             ; -> L_2000f00
  2000798:  70411271  aseq     trap65, gr18, gr113        ; [delay slot]
  200079c:  16014f9d  load     0, 1, gr79, lr29        
  20007a0:  14425cc7  add      gr66, gr92, lr71        
  20007a4:  42444ad3  cpltu    gr68, gr74, lr83        
L_20007a8:
  20007a8:  ac014abc  jmpt     gr74, $2000e98             ; -> L_2000e98
  20007ac:  24424b0d  sub      gr66, gr75, gr13           ; [delay slot]
  20007b0:  a0fe0851  jmp      $20000f4                   ; -> L_20000f4
  20007b4:  154c4588  add      gr76, gr69, $88            ; [delay slot]
  20007b8:  154c45e0  add      gr76, gr69, $e0         
  20007bc:  16014c6d  load     0, 1, gr76, gr109       
  20007c0:  a00109fe  jmp      $2000fb8                   ; -> L_2000fb8
  20007c4:  14454edf  add      gr69, gr78, lr95           ; [delay slot]
  20007c8:  154c4714  add      gr76, gr71, $14         
  20007cc:  a0010a43  jmp      $2000cd8                   ; -> L_2000cd8
  20007d0:  16014f49  load     0, 1, gr79, gr73           ; [delay slot]
  20007d4:  814944b1  sll      gr73, gr68, $b1         
  20007d8:  a4014ce8  jmpf     gr76, $2000f78             ; -> L_2000f78
  20007dc:  036643c0  const    gr67, $66c0                ; [delay slot]
  20007e0:  024d4280  consth   gr66, $4d80             
  20007e4:  c6450160  mfsr     gr69, OPS               
  20007e8:  160145a3  load     0, 1, gr69, lr35        
  20007ec:  03664118  const    gr65, $6618             
  20007f0:  024d4168  consth   gr65, $4d68             
  20007f4:  1601409b  load     0, 1, gr64, lr27        
  20007f8:  834947ec  srl      gr73, gr71, $ec         
  20007fc:  03fe4baf  const    gr75, $feaf             
  2000800:  020e4a7b  consth   gr74, $0e7b             
  2000804:  61494914  cpeq     gr73, gr73, $14         
  2000808:  a4014a3c  jmpf     gr74, $2000cf8             ; -> L_2000cf8
  200080c:  7041035d  aseq     trap65, gr3, gr93          ; [delay slot]
  2000810:  9046446b  and      gr70, gr68, gr107       
  2000814:  92464442  or       gr70, gr68, gr66        
  2000818:  c64878e4  mfsr     gr72, spr120            
  200081c:  834934bc  srl      gr73, gr52, $bc         
  2000820:  6149354c  cpeq     gr73, gr53, $4c         
  2000824:  a4013698  jmpf     gr54, $2000e84             ; -> L_2000e84
  2000828:  70417f91  aseq     trap65, gr127, lr17        ; [delay slot]
  200082c:  904837bb  and      gr72, gr55, lr59        
  2000830:  92483746  or       gr72, gr55, gr70        
  2000834:  42493677  cpltu    gr73, gr54, gr119       
  2000838:  ac013752  jmpt     gr55, $2000d80             ; -> L_2000d80
  200083c:  14463f5f  add      gr70, gr63, gr95           ; [delay slot]
  2000840:  4a493147  cpgtu    gr73, gr49, gr71        
  2000844:  ac0131e7  jmpt     gr49, $2000fe0             ; -> L_2000fe0
  2000848:  70417be5  aseq     trap65, gr123, lr101       ; [delay slot]
  200084c:  83453e4a  srl      gr69, gr62, $4a         
  2000850:  81453fe2  sll      gr69, gr63, $e2         
  2000854:  be013198  mttlb    gr49, lr24              
  2000858:  a0067b9c  jmp      $20022c8                   ; -> L_20022c8
  200085c:  03013976  const    gr57, $0176                ; [delay slot]
  2000860:  8345318e  srl      gr69, gr49, $8e         
  2000864:  8145329a  sll      gr69, gr50, $9a         
L_2000868:
  2000868:  03603f70  const    gr63, $6070             
  200086c:  024d3f5c  consth   gr63, $4d5c             
  2000870:  01fe375f  constn   gr55, $fe5f             
  2000874:  1e0137c8  store    0, 1, gr55, lr72        
  2000878:  03603828  const    gr56, $6028             
  200087c:  024d3820  consth   gr56, $4d20             
  2000880:  254637c9  sub      gr70, gr55, $c9         
  2000884:  1e0135d4  store    0, 1, gr53, lr84        
L_2000888:
  2000888:  c6467310  mfsr     gr70, spr115            
  200088c:  03213970  const    gr57, $2170             
  2000890:  9246344f  or       gr70, gr52, gr79        
  2000894:  ce016df7  mtsr     spr109, lr119           
  2000898:  be01269c  mttlb    gr38, lr28              
L_200089c:
  200089c:  88016c1c  iret                             
  20008a0:  a0066d5a  jmp      $2002208                   ; -> L_2002208   ; [delay slot]
L_20008a4:
  20008a4:  030120f5  const    gr32, $01f5                ; [delay slot]
  20008a8:  81462ee5  sll      gr70, gr46, $e5         
  20008ac:  a40129d4  jmpf     gr41, $2000ffc             ; -> L_2000ffc
  20008b0:  036029a0  const    gr41, $60a0                ; [delay slot]
  20008b4:  024d28dc  consth   gr40, $4ddc             
  20008b8:  160120b7  load     0, 1, gr32, lr55        
  20008bc:  a4012040  jmpf     gr32, $2000dbc             ; -> L_2000dbc
  20008c0:  03602048  const    gr32, $6048                ; [delay slot]
  20008c4:  024d2010  consth   gr32, $4d10             
L_20008c8:
  20008c8:  16012371  load     0, 1, gr35, gr113       
  20008cc:  1548235d  add      gr72, gr35, $5d         
  20008d0:  604a2268  cpeq     gr74, gr34, gr104       
  20008d4:  ac012004  jmpt     gr32, $2000ce4             ; -> L_2000ce4
  20008d8:  25492ca4  sub      gr73, gr44, $a4            ; [delay slot]
  20008dc:  604a2ce8  cpeq     gr74, gr44, lr104       
L_20008e0:
  20008e0:  a4012e4f  jmpf     gr46, $2000e1c             ; -> L_2000e1c
  20008e4:  0301209c  const    gr32, $019c                ; [delay slot]
  20008e8:  1e0120d7  store    0, 1, gr32, lr87        
  20008ec:  c64767f0  mfsr     gr71, spr103            
  20008f0:  03212f04  const    gr47, $2104             
  20008f4:  9c472179  andn     gr71, gr33, gr121       
  20008f8:  ce01661e  mtsr     spr102, gr30            
  20008fc:  8801601c  iret                             
  2000900:  a00660c2  jmp      $2002408                   ; -> L_2002408   ; [delay slot]
  2000904:  03012c7c  const    gr44, $017c                ; [delay slot]
L_2000908:
  2000908:  814622f4  sll      gr70, gr34, $f4         
  200090c:  ac012544  jmpt     gr37, $2000e1c             ; -> L_2000e1c
  2000910:  704162e9  aseq     trap65, gr98, lr105        ; [delay slot]
  2000914:  a0066361  jmp      $2002298                   ; -> L_2002298
  2000918:  03012ee3  const    gr46, $01e3                ; [delay slot]
  200091c:  88015cd0  iret                             
  2000920:  a0065d3e  jmp      $2002218                   ; -> L_2002218   ; [delay slot]
  2000924:  0301131f  const    gr19, $011f                ; [delay slot]
  2000928:  81461fa5  sll      gr70, gr31, $a5         
L_200092c:
  200092c:  ac011858  jmpt     gr24, $2000e8c             ; -> L_2000e8c
  2000930:  704159a1  aseq     trap65, gr89, lr33         ; [delay slot]
  2000934:  a0065835  jmp      $2002208                   ; -> L_2002208
  2000938:  03011579  const    gr21, $0179                ; [delay slot]
  200093c:  88015820  iret                             
  2000940:  c6555fc8  mfsr     gr85, spr95                ; [delay slot]
  2000944:  81540e89  sll      gr84, gr14, $89         
  2000948:  a4010f14  jmpf     gr15, $2000d98             ; -> L_2000d98
  200094c:  9d550e71  andn     gr85, gr14, $71            ; [delay slot]
  2000950:  ce015d50  mtsr     spr93, gr80             
  2000954:  880154b0  iret                             
  2000958:  a0065474  jmp      $2002328                   ; -> L_2002328   ; [delay slot]
  200095c:  03011980  const    gr25, $0180                ; [delay slot]
  2000960:  c6555380  mfsr     gr85, spr83             
  2000964:  81540175  sll      gr84, gr1, $75          
  2000968:  a40103e0  jmpf     gr3, $20010e8              ; -> L_20010e8
  200096c:  9d5502c1  andn     gr85, gr2, $c1             ; [delay slot]
  2000970:  ce01503c  mtsr     spr80, gr60             
  2000974:  880157dc  iret                             
  2000978:  814710ff  sll      gr71, gr16, $ff            ; [delay slot]
  200097c:  a4011658  jmpf     gr22, $2000edc             ; -> L_2000edc
  2000980:  03601738  const    gr23, $6038                ; [delay slot]
  2000984:  024d1710  consth   gr23, $4d10             
  2000988:  1601147e  load     0, 1, gr20, gr126       
  200098c:  a4011458  jmpf     gr20, $2000eec             ; -> L_2000eec
  2000990:  70415221  aseq     trap65, gr82, gr33         ; [delay slot]
  2000994:  a8061580  call     gr21, $2002394             ; -> L_2002394
  2000998:  70414de5  aseq     trap65, gr77, lr101        ; [delay slot]
  200099c:  03740a90  const    gr10, $7490             
L_20009a0:
  20009a0:  02000a48  consth   gr10, $0048             
L_20009a4:
  20009a4:  ce0147db  mtsr     spr71, lr91             
  20009a8:  036906a0  const    gr6, $69a0              
  20009ac:  024d06f0  consth   gr6, $4df0              
  20009b0:  1601074c  load     0, 1, gr7, gr76         
  20009b4:  15480631  add      gr72, gr6, $31          
  20009b8:  1e010610  store    0, 1, gr6, gr16         
  20009bc:  03fe0ee3  const    gr14, $fee3             
  20009c0:  90470146  and      gr71, gr1, gr70         
  20009c4:  61470fe0  cpeq     gr71, gr15, $e0         
  20009c8:  a4010cec  jmpf     gr12, $2001178             ; -> L_2001178
  20009cc:  03650c7c  const    gr12, $657c                ; [delay slot]
  20009d0:  024d0de8  consth   gr13, $4de8             
  20009d4:  16010c9a  load     0, 1, gr12, lr26        
L_20009d8:
  20009d8:  81460c60  sll      gr70, gr12, $60         
  20009dc:  030102d0  const    gr2, $01d0              
L_20009e0:
  20009e0:  02470384  consth   gr3, $4784              
  20009e4:  1e0101d6  store    0, 1, gr1, lr86         
  20009e8:  03690f8c  const    gr15, $698c             
  20009ec:  024d0f5c  consth   gr15, $4d5c             
  20009f0:  160109e8  load     0, 1, gr9, lr104        
  20009f4:  03740ab0  const    gr10, $74b0             
  20009f8:  144809ae  add      gr72, gr9, lr46         
  20009fc:  c64ac420  mfsr     gr74, spr196            
  2000a00:  814a0add  sll      gr74, gr10, $dd         
  2000a04:  ac01099f  jmpt     gr9, $2001080              ; -> L_2001080
  2000a08:  1e010b58  store    0, 1, gr11, gr88           ; [delay slot]
  2000a0c:  88014270  iret                             
  2000a10:  15490b00  add      gr73, gr11, $00            ; [delay slot]
  2000a14:  1602f5f8  load     0, 2, lr117, lr120      
  2000a18:  154bf5d9  add      gr75, lr117, $d9        
  2000a1c:  1e02f554  store    0, 2, lr117, gr84       
L_2000a20:
  2000a20:  8802bd80  iret                             
  2000a24:  c656bb60  mfsr     gr86, spr187               ; [delay slot]
  2000a28:  8157eaf1  sll      gr87, lr106, $f1        
  2000a2c:  a402ebc4  jmpf     lr107, $200153c            ; -> L_200153c
  2000a30:  9d56ea69  andn     gr86, lr106, $69           ; [delay slot]
L_2000a34:
  2000a34:  ce02b988  mtsr     spr185, lr8             
  2000a38:  8802b8f0  iret                             
  2000a3c:  c641b950  mfsr     gr65, spr185               ; [delay slot]
  2000a40:  0312fc84  const    lr124, $1284            
L_2000a44:
  2000a44:  9c41fa55  andn     gr65, lr122, gr85       
  2000a48:  8145fa39  sll      gr69, lr122, $39        
  2000a4c:  a402fd4d  jmpf     lr125, $2001380            ; -> L_2001380
  2000a50:  0363fce8  const    lr124, $63e8               ; [delay slot]
  2000a54:  024efc00  consth   lr124, $4e00            
  2000a58:  1602fca3  load     0, 2, lr124, lr35       
  2000a5c:  a402fdad  jmpf     lr125, $2001510            ; -> L_2001510
  2000a60:  0322fc48  const    lr124, $2248               ; [delay slot]
  2000a64:  9c41f5d5  andn     gr65, lr117, lr85       
  2000a68:  ce02b7d3  mtsr     spr183, lr83            
  2000a6c:  0302f0f0  const    lr112, $02f0            
  2000a70:  1e02f043  store    0, 2, lr112, gr67       
L_2000a74:
  2000a74:  0363f0fc  const    lr112, $63fc            
  2000a78:  024ef058  consth   lr112, $4e58            
  2000a7c:  1602f75b  load     0, 2, lr119, gr91       
  2000a80:  be02f746  mttlb    lr119, gr70             
  2000a84:  1545f6e1  add      gr69, lr118, $e1        
  2000a88:  be02f5a2  mttlb    lr117, lr34             
  2000a8c:  8c02b240  iretinv                          
  2000a90:  8145f3fd  sll      gr69, lr115, $fd           ; [delay slot]
  2000a94:  ac02f4d8  jmpt     lr116, $20015f4            ; -> L_20015f4
  2000a98:  7042b271  aseq     trap66, lr50, gr113        ; [delay slot]
  2000a9c:  a005ac8b  jmp      $20020c8                   ; -> L_20020c8
  2000aa0:  0302e01b  const    lr96, $021b                ; [delay slot]
  2000aa4:  036aeadc  const    lr106, $6adc            
  2000aa8:  024eebb8  consth   lr107, $4eb8            
  2000aac:  1602e918  load     0, 2, lr105, gr24       
  2000ab0:  1544eea1  add      gr68, lr110, $a1        
  2000ab4:  1e02eec4  store    0, 2, lr110, lr68       
  2000ab8:  0322ede4  const    lr109, $22e4            
  2000abc:  9241eb65  or       gr65, lr107, gr101      
  2000ac0:  ce02a88b  mtsr     spr168, lr11            
  2000ac4:  6144ec9c  cpeq     gr68, lr108, $9c        
  2000ac8:  ac02ec13  jmpt     lr108, $2001314            ; -> L_2001314
  2000acc:  7042ab71  aseq     trap66, lr43, gr113        ; [delay slot]
  2000ad0:  8802ab04  iret                             
L_2000ad4:
  2000ad4:  1546e0b4  add      gr70, lr96, $b4            ; [delay slot]
  2000ad8:  1602e29c  load     0, 2, lr98, lr28        
  2000adc:  1544e21d  add      gr68, lr98, $1d         
  2000ae0:  1e02e3c4  store    0, 2, lr99, lr68        
  2000ae4:  8802a560  iret                             
  2000ae8:  c641ace4  mfsr     gr65, spr172               ; [delay slot]
  2000aec:  2541e5c4  sub      gr65, lr101, $c4        
  2000af0:  ce02ac2b  mtsr     spr172, gr43            
  2000af4:  c641acdc  mfsr     gr65, spr172            
  2000af8:  2541e3f4  sub      gr65, lr99, $f4         
  2000afc:  ce02ab13  mtsr     spr171, gr19            
  2000b00:  a005a1c6  jmp      $2002218                   ; -> L_2002218
  2000b04:  0302ecb0  const    lr108, $02b0               ; [delay slot]
  2000b08:  c656a438  mfsr     gr86, EXOP              
  2000b0c:  8157f649  sll      gr87, lr118, $49        
  2000b10:  a402f624  jmpf     lr118, $20013a0            ; -> L_20013a0
  2000b14:  9d56f701  andn     gr86, lr119, $01           ; [delay slot]
  2000b18:  ce029ab0  mtsr     spr154, lr48            
  2000b1c:  88029da0  iret                             
  2000b20:  0363da34  const    lr90, $6334                ; [delay slot]
  2000b24:  024ed99c  consth   lr89, $4e9c             
  2000b28:  1602d6d7  load     0, 2, lr86, lr87        
  2000b2c:  6147d6f0  cpeq     gr71, lr86, $f0         
  2000b30:  ac02db00  jmpt     lr91, $2001330             ; -> L_2001330
  2000b34:  70429e31  aseq     trap66, lr30, gr49         ; [delay slot]
  2000b38:  a0039f03  jmp      $2001744                   ; -> L_2001744
  2000b3c:  7042991d  aseq     trap66, lr25, gr29         ; [delay slot]
  2000b40:  a0059832  jmp      $2002008                   ; -> L_2002008
  2000b44:  0302d476  const    lr84, $0276                ; [delay slot]
  2000b48:  c6569ce4  mfsr     gr86, spr156            
  2000b4c:  8157ce55  sll      gr87, lr78, $55         
  2000b50:  a402ceec  jmpf     lr78, $2001700             ; -> L_2001700
  2000b54:  9d56cfdd  andn     gr86, lr79, $dd            ; [delay slot]
  2000b58:  ce029d24  mtsr     spr157, gr36            
  2000b5c:  880294d0  iret                             
  2000b60:  0302d2dc  const    lr82, $02dc                ; [delay slot]
  2000b64:  0246d190  consth   lr81, $4690             
  2000b68:  0302d1b8  const    lr81, $02b8             
  2000b6c:  1e02d11b  store    0, 2, lr81, gr27        
  2000b70:  0363d720  const    lr87, $6320             
  2000b74:  024ed780  consth   lr87, $4e80             
  2000b78:  1602d8a3  load     0, 2, lr88, lr35        
  2000b7c:  6147d820  cpeq     gr71, lr88, $20         
L_2000b80:
  2000b80:  ac02d4cc  jmpt     lr84, $20016b0             ; -> L_20016b0
  2000b84:  7042939d  aseq     trap66, lr19, lr29         ; [delay slot]
  2000b88:  a0039257  jmp      $20018e4                   ; -> L_20018e4
  2000b8c:  70429371  aseq     trap66, lr19, gr113        ; [delay slot]
  2000b90:  a005931a  jmp      $2001ff8                   ; -> L_2001ff8
  2000b94:  0302c127  const    lr65, $0227                ; [delay slot]
L_2000b98:
  2000b98:  c6568ad8  mfsr     gr86, spr138            
  2000b9c:  8157d809  sll      gr87, lr88, $09         
  2000ba0:  a402d884  jmpf     lr88, $20015b0             ; -> L_20015b0
L_2000ba4:
  2000ba4:  9d56d961  andn     gr86, lr89, $61            ; [delay slot]
  2000ba8:  ce0288b0  mtsr     spr136, lr48            
  2000bac:  88028ec0  iret                             
  2000bb0:  0363c9ec  const    lr73, $63ec                ; [delay slot]
  2000bb4:  024ec8dc  consth   lr72, $4edc             
  2000bb8:  1602c0b7  load     0, 2, lr64, lr55        
  2000bbc:  6145c050  cpeq     gr69, lr64, $50         
  2000bc0:  ac02ce96  jmpt     lr78, $2001618             ; -> L_2001618
  2000bc4:  0302cf10  const    lr79, $0210                ; [delay slot]
  2000bc8:  0302cd5c  const    lr77, $025c             
  2000bcc:  0246cd5c  consth   lr77, $465c             
  2000bd0:  1602cc67  load     0, 2, lr76, gr103       
L_2000bd4:
  2000bd4:  a402cc04  jmpf     lr76, $20013e4             ; -> L_20013e4
  2000bd8:  0302c3b4  const    lr67, $02b4                ; [delay slot]
  2000bdc:  0246c2a0  consth   lr66, $46a0             
  2000be0:  1e02c30f  store    0, 2, lr67, gr15        
L_2000be4:
  2000be4:  0302c1f4  const    lr65, $02f4             
  2000be8:  0246c190  consth   lr65, $4690             
  2000bec:  1602c1b7  load     0, 2, lr65, lr55        
  2000bf0:  a402c100  jmpf     lr65, $20013f0             ; -> L_20013f0
  2000bf4:  0302c064  const    lr64, $0264                ; [delay slot]
  2000bf8:  0246c058  consth   lr64, $4658             
  2000bfc:  1e02c65b  store    0, 2, lr70, gr91        
  2000c00:  a0038029  jmp      $20018a4                   ; -> L_20018a4
  2000c04:  704280e1  aseq     trap66, lr0, lr97          ; [delay slot]
  2000c08:  a802c7e7  call     lr71, $20017a4             ; -> L_20017a4
  2000c0c:  70428341  aseq     trap66, lr3, gr65          ; [delay slot]
  2000c10:  8c0283e8  iretinv                          
  2000c14:  0302c5dc  const    lr69, $02dc                ; [delay slot]
  2000c18:  0302c414  const    lr68, $0214             
  2000c1c:  0246bbd0  consth   lr59, $46d0             
  2000c20:  1602bac3  load     0, 2, lr58, lr67        
  2000c24:  a403b99c  jmpf     lr57, $2001a94             ; -> L_2001a94
  2000c28:  0302b8e8  const    lr56, $02e8                ; [delay slot]
  2000c2c:  0246b85c  consth   lr56, $465c             
  2000c30:  1e02bee7  store    0, 2, lr62, lr103       
  2000c34:  0365bf54  const    lr63, $6554             
  2000c38:  024ebfe4  consth   lr63, $4ee4             
  2000c3c:  1602bf67  load     0, 2, lr63, gr103       
  2000c40:  ac06be27  jmpt     lr62, $20024dc             ; -> L_20024dc
  2000c44:  0371bd9c  const    lr61, $719c                ; [delay slot]
  2000c48:  024ebd10  consth   lr61, $4e10             
  2000c4c:  1602b337  load     0, 2, lr51, gr55        
  2000c50:  a403b205  jmpf     lr50, $2001864             ; -> L_2001864
  2000c54:  0302b2b0  const    lr50, $02b0                ; [delay slot]
  2000c58:  1e02b29f  store    0, 2, lr50, lr31        
  2000c5c:  8145bd03  sll      gr69, lr61, $03         
  2000c60:  a402b288  jmpf     lr50, $2001680             ; -> L_2001680
  2000c64:  7042f461  aseq     trap66, lr116, gr97        ; [delay slot]
  2000c68:  0371b1e0  const    lr49, $71e0             
  2000c6c:  024eb1c0  consth   lr49, $4ec0             
  2000c70:  1e02b02f  store    0, 2, lr48, gr47        
  2000c74:  1602bf9b  load     0, 2, lr63, lr27        
L_2000c78:
  2000c78:  a4fdb80f  jmpf     lr56, $20000b4             ; -> L_20000b4
  2000c7c:  7042f151  aseq     trap66, lr113, gr81        ; [delay slot]
  2000c80:  0371a08c  const    lr32, $718c             
  2000c84:  024ea010  consth   lr32, $4e10             
  2000c88:  1602b869  load     0, 2, lr56, gr105       
  2000c8c:  1553a358  add      gr83, lr35, $58         
  2000c90:  1602b871  load     0, 2, lr56, gr113       
  2000c94:  1553a204  add      gr83, lr34, $04         
L_2000c98:
  2000c98:  1602a0b5  load     0, 2, lr32, lr53        
  2000c9c:  1553bca4  add      gr83, lr60, $a4         
  2000ca0:  1602a019  load     0, 2, lr32, gr25        
  2000ca4:  0371bf80  const    lr63, $7180             
  2000ca8:  024ebf90  consth   lr63, $4e90             
  2000cac:  1602aaa1  load     0, 2, lr42, lr33        
  2000cb0:  1545a300  add      gr69, lr35, $00         
L_2000cb4:
  2000cb4:  ce026c77  mtsr     spr108, gr119           
  2000cb8:  6545a458  mul      gr69, lr36, $58         
  2000cbc:  6445a35b  mul      gr69, lr35, gr91        
  2000cc0:  6445a347  mul      gr69, lr35, gr71        
  2000cc4:  6445a2a7  mul      gr69, lr34, lr39        
L_2000cc8:
  2000cc8:  6445a1a3  mul      gr69, lr33, lr35        
  2000ccc:  6445a107  mul      gr69, lr33, gr7         
  2000cd0:  6445a0af  mul      gr69, lr32, lr47        
  2000cd4:  6445a09b  mul      gr69, lr32, lr27        
L_2000cd8:
  2000cd8:  6445a037  mul      gr69, lr32, gr55        
  2000cdc:  6445af97  mul      gr69, lr47, lr23        
  2000ce0:  6445aec3  mul      gr69, lr46, lr67        
L_2000ce4:
  2000ce4:  6445add7  mul      gr69, lr45, lr87        
  2000ce8:  6445acff  mul      gr69, lr44, lr127       
  2000cec:  6445ac1b  mul      gr69, lr44, gr27        
  2000cf0:  6445abe7  mul      gr69, lr43, lr103       
  2000cf4:  6445abc7  mul      gr69, lr43, lr71        
L_2000cf8:
  2000cf8:  6445aba3  mul      gr69, lr43, lr35        
  2000cfc:  6445ab67  mul      gr69, lr43, gr103       
  2000d00:  6445aa8f  mul      gr69, lr42, lr15        
  2000d04:  6445a9db  mul      gr69, lr41, lr91        
  2000d08:  6445a957  mul      gr69, lr41, gr87        
  2000d0c:  6445a937  mul      gr69, lr41, gr55        
  2000d10:  6445a843  mul      gr69, lr40, gr67        
  2000d14:  644597f7  mul      gr69, lr23, lr119       
  2000d18:  6445979f  mul      gr69, lr23, lr31        
  2000d1c:  6445975b  mul      gr69, lr23, gr91        
  2000d20:  644596c7  mul      gr69, lr22, lr71        
  2000d24:  64459627  mul      gr69, lr22, gr39        
  2000d28:  644595a3  mul      gr69, lr21, lr35        
  2000d2c:  64459587  mul      gr69, lr21, lr7         
  2000d30:  6445952f  mul      gr69, lr21, gr47        
  2000d34:  6645949b  mull     gr69, lr20, lr27        
  2000d38:  c6455bf0  mfsr     gr69, spr91             
  2000d3c:  14419f1a  add      gr65, lr31, gr26        
  2000d40:  61459d84  cpeq     gr69, lr29, $84         
  2000d44:  ac029ebf  jmpt     lr30, $2001840             ; -> L_2001840
  2000d48:  7042db39  aseq     trap66, lr91, gr57         ; [delay slot]
  2000d4c:  0336925c  const    lr18, $365c             
  2000d50:  02429320  consth   lr19, $4220             
  2000d54:  81449300  sll      gr68, lr19, $00         
  2000d58:  1e02b4a2  store    0, 2, lr52, lr34        
  2000d5c:  154493a4  add      gr68, lr19, $a4         
  2000d60:  1e02b40e  store    0, 2, lr52, gr14        
  2000d64:  15449098  add      gr68, lr16, $98         
  2000d68:  1e02b4d6  store    0, 2, lr52, lr86        
  2000d6c:  154490f4  add      gr68, lr16, $f4         
  2000d70:  1e02b542  store    0, 2, lr53, gr66        
  2000d74:  15449134  add      gr68, lr17, $34         
  2000d78:  1e02b31e  store    0, 2, lr51, gr30        
  2000d7c:  15449618  add      gr68, lr22, $18         
L_2000d80:
  2000d80:  1e02b546  store    0, 2, lr53, gr70        
  2000d84:  154497e4  add      gr68, lr23, $e4         
  2000d88:  1e02b4a2  store    0, 2, lr52, lr34        
  2000d8c:  15449444  add      gr68, lr20, $44         
  2000d90:  1e02b4ae  store    0, 2, lr52, lr46        
  2000d94:  154495d8  add      gr68, lr21, $d8         
L_2000d98:
  2000d98:  0303b58e  const    lr53, $038e             
  2000d9c:  0302a8d0  const    lr40, $02d0             
  2000da0:  024ea984  consth   lr41, $4e84             
  2000da4:  0306ab90  const    lr43, $0690             
  2000da8:  146787dd  add      gr103, lr7, lr93        
  2000dac:  61458b5d  cpeq     gr69, lr11, $5d         
  2000db0:  ac028f97  jmpt     lr15, $200180c             ; -> L_200180c
  2000db4:  61458c82  cpeq     gr69, lr12, $82            ; [delay slot]
  2000db8:  a4028f83  jmpf     lr15, $20017c4             ; -> L_20017c4
L_2000dbc:
  2000dbc:  8162ac20  sll      gr98, lr44, $20            ; [delay slot]
  2000dc0:  8163acc8  sll      gr99, lr44, $c8         
  2000dc4:  0301a962  const    lr41, $0162             
L_2000dc8:
  2000dc8:  1602a870  load     0, 2, lr40, gr112       
  2000dcc:  1562aa74  add      gr98, lr42, $74         
  2000dd0:  1e02a965  store    0, 2, lr41, gr101       
  2000dd4:  b4fda74d  jmpfdec  lr39, $2000308             ; -> L_2000308
  2000dd8:  1563a5dc  add      gr99, lr37, $dc            ; [delay slot]
  2000ddc:  8162a11c  sll      gr98, lr33, $1c         
  2000de0:  8163a180  sll      gr99, lr33, $80         
  2000de4:  0302a69e  const    lr38, $029e             
  2000de8:  1602a484  load     0, 2, lr36, lr4         
  2000dec:  1562a6c4  add      gr98, lr38, $c4         
  2000df0:  1e02a409  store    0, 2, lr36, gr9         
  2000df4:  b4fda421  jmpfdec  lr36, $2000278             ; -> L_2000278
  2000df8:  1563a1e0  add      gr99, lr33, $e0            ; [delay slot]
  2000dfc:  1563a458  add      gr99, lr36, $58         
  2000e00:  0302a27a  const    lr34, $027a             
  2000e04:  1602a370  load     0, 2, lr35, gr112       
  2000e08:  1562a23c  add      gr98, lr34, $3c         
  2000e0c:  1e02a03d  store    0, 2, lr32, gr61        
  2000e10:  b4fda0dd  jmpfdec  lr32, $2000584             ; -> L_2000584
  2000e14:  1563a210  add      gr99, lr34, $10            ; [delay slot]
  2000e18:  156358e0  add      gr99, gr88, $e0         
L_2000e1c:
  2000e1c:  03025e5e  const    gr94, $025e             
  2000e20:  16025f28  load     0, 2, gr95, gr40        
  2000e24:  15625e98  add      gr98, gr94, $98         
  2000e28:  1e025cf1  store    0, 2, gr92, lr113       
  2000e2c:  b4fd5d0d  jmpfdec  gr93, $2000260             ; -> L_2000260
  2000e30:  15635f14  add      gr99, gr95, $14            ; [delay slot]
L_2000e34:
  2000e34:  15635b3c  add      gr99, gr91, $3c         
  2000e38:  03025ca6  const    gr92, $02a6             
  2000e3c:  16025a7c  load     0, 2, gr90, gr124       
  2000e40:  15625804  add      gr98, gr88, $04         
  2000e44:  1e025b81  store    0, 2, gr91, lr1         
L_2000e48:
  2000e48:  b4fd5919  jmpfdec  gr89, $20002ac             ; -> L_20002ac
  2000e4c:  15635b50  add      gr99, gr91, $50            ; [delay slot]
  2000e50:  031258e8  const    gr88, $12e8             
  2000e54:  b4fd5d06  jmpfdec  gr93, $200026c             ; -> L_200026c
  2000e58:  14665f13  add      gr102, gr95, gr19          ; [delay slot]
  2000e5c:  030270ac  const    gr112, $02ac            
  2000e60:  02467184  consth   gr113, $4684            
  2000e64:  160254d4  load     0, 2, gr84, lr84        
  2000e68:  a4fd5545  jmpf     gr85, $200037c             ; -> L_200037c
  2000e6c:  030273dc  const    gr115, $02dc               ; [delay slot]
  2000e70:  024674a0  consth   gr116, $46a0            
  2000e74:  160252c4  load     0, 2, gr82, lr68        
  2000e78:  acfd5219  jmpt     gr82, $20002dc             ; -> L_20002dc
  2000e7c:  03fd73df  const    gr115, $fddf               ; [delay slot]
  2000e80:  027d7237  consth   gr114, $7d37            
L_2000e84:
  2000e84:  a00232a8  jmp      $2001924                   ; -> L_2001924
  2000e88:  70423311  aseq     trap66, gr51, gr17         ; [delay slot]
L_2000e8c:
  2000e8c:  81625670  sll      gr98, gr86, $70         
  2000e90:  81635604  sll      gr99, gr86, $04         
  2000e94:  03014f4e  const    gr79, $014e             
L_2000e98:
  2000e98:  16024eb8  load     0, 2, gr78, lr56        
  2000e9c:  15624c18  add      gr98, gr76, $18         
  2000ea0:  1e024fe1  store    0, 2, gr79, lr97        
  2000ea4:  b4fd4e9d  jmpfdec  gr78, $2000518             ; -> L_2000518
  2000ea8:  15634fe0  add      gr99, gr79, $e0            ; [delay slot]
  2000eac:  15624bc0  add      gr98, gr75, $c0         
  2000eb0:  15634a68  add      gr99, gr74, $68         
  2000eb4:  03024c22  const    gr76, $0222             
  2000eb8:  16024a90  load     0, 2, gr74, lr16        
  2000ebc:  15624840  add      gr98, gr72, $40         
  2000ec0:  1e024be5  store    0, 2, gr75, lr101       
  2000ec4:  b4fd4aed  jmpfdec  gr74, $2000678             ; -> L_2000678
  2000ec8:  15634b3c  add      gr99, gr75, $3c            ; [delay slot]
  2000ecc:  15624f54  add      gr98, gr79, $54         
  2000ed0:  030248de  const    gr72, $02de             
  2000ed4:  16024960  load     0, 2, gr73, gr96        
  2000ed8:  156244f4  add      gr98, gr68, $f4         
L_2000edc:
  2000edc:  1e0247c1  store    0, 2, gr71, lr65        
  2000ee0:  b4fd46b5  jmpfdec  gr70, $20005b4             ; -> L_20005b4
  2000ee4:  15634798  add      gr99, gr71, $98            ; [delay slot]
  2000ee8:  15624394  add      gr98, gr67, $94         
L_2000eec:
  2000eec:  0302450e  const    gr69, $020e             
  2000ef0:  16024464  load     0, 2, gr68, gr100       
  2000ef4:  15624720  add      gr98, gr71, $20         
  2000ef8:  1e024539  store    0, 2, gr69, gr57        
  2000efc:  b4fd43e1  jmpfdec  gr67, $2000680             ; -> L_2000680
L_2000f00:
  2000f00:  15634104  add      gr99, gr65, $04            ; [delay slot]
  2000f04:  156244ec  add      gr98, gr68, $ec         
  2000f08:  0302411a  const    gr65, $021a             
  2000f0c:  16024020  load     0, 2, gr64, gr32        
  2000f10:  156243f8  add      gr98, gr67, $f8         
  2000f14:  1e0241bd  store    0, 2, gr65, lr61        
  2000f18:  b4fd408d  jmpfdec  gr64, $200054c             ; -> L_200054c
  2000f1c:  15637dd4  add      gr99, gr125, $d4           ; [delay slot]
  2000f20:  03127e84  const    gr126, $1284            
  2000f24:  b4fd784a  jmpfdec  gr120, $200044c            ; -> L_200044c
  2000f28:  14667bdb  add      gr102, gr123, lr91         ; [delay slot]
  2000f2c:  03025b20  const    gr91, $0220             
  2000f30:  02465ca0  consth   gr92, $46a0             
  2000f34:  16027ac4  load     0, 2, gr122, lr68       
  2000f38:  acfd7a19  jmpt     gr122, $200039c            ; -> L_200039c
  2000f3c:  03025ca0  const    gr92, $02a0                ; [delay slot]
  2000f40:  02465dc8  consth   gr93, $46c8             
L_2000f44:
  2000f44:  160278d8  load     0, 2, gr120, lr88       
  2000f48:  a4fd78ed  jmpf     gr120, $20006fc            ; -> L_20006fc
  2000f4c:  03fd598f  const    gr89, $fd8f                ; [delay slot]
  2000f50:  027d58fb  consth   gr88, $7dfb             
  2000f54:  032a75a8  const    gr117, $2aa8            
  2000f58:  024e75d8  consth   gr117, $4ed8            
  2000f5c:  03027702  const    gr119, $0202            
  2000f60:  03025180  const    gr81, $0280             
  2000f64:  03025360  const    gr83, $0260             
  2000f68:  1e025085  store    0, 2, gr80, lr5         
  2000f6c:  156377c4  add      gr99, gr119, $c4        
  2000f70:  be02522e  mttlb    gr82, gr46              
  2000f74:  154653de  add      gr70, gr83, $de         
L_2000f78:
  2000f78:  be0254b6  mttlb    gr84, lr54              
  2000f7c:  b4fd73ab  jmpfdec  gr115, $2000628            ; -> L_2000628
  2000f80:  15465586  add      gr70, gr85, $86            ; [delay slot]
  2000f84:  03027222  const    gr114, $0222            
  2000f88:  032e7390  const    gr115, $2e90            
  2000f8c:  024e735c  consth   gr115, $4e5c            
  2000f90:  1e025541  store    0, 2, gr85, gr65        
  2000f94:  b4fd70ff  jmpfdec  gr112, $2000790            ; -> L_2000790
  2000f98:  15636de0  add      gr99, gr109, $e0           ; [delay slot]
  2000f9c:  032a6cb0  const    gr108, $2ab0            
  2000fa0:  024e6c48  consth   gr108, $4e48            
  2000fa4:  1e0248fd  store    0, 2, gr72, lr125       
  2000fa8:  81444690  sll      gr68, gr70, $90         
  2000fac:  16026eb6  load     0, 2, gr110, lr54       
  2000fb0:  15444800  add      gr68, gr72, $00         
  2000fb4:  16026e76  load     0, 2, gr110, gr118      
L_2000fb8:
  2000fb8:  1544495c  add      gr68, gr73, $5c         
  2000fbc:  16026a5a  load     0, 2, gr106, gr90       
  2000fc0:  15444e04  add      gr68, gr78, $04         
  2000fc4:  16026aa6  load     0, 2, gr106, lr38       
  2000fc8:  15444ce0  add      gr68, gr76, $e0         
  2000fcc:  16026e06  load     0, 2, gr110, gr6        
  2000fd0:  15444dec  add      gr68, gr77, $ec         
  2000fd4:  16026e9a  load     0, 2, gr110, lr26       
  2000fd8:  15444d74  add      gr68, gr77, $74         
  2000fdc:  16026296  load     0, 2, gr98, lr22        
L_2000fe0:
  2000fe0:  15444380  add      gr68, gr67, $80         
  2000fe4:  160261d6  load     0, 2, gr97, lr86        
  2000fe8:  154441bc  add      gr68, gr65, $bc         
  2000fec:  0302415c  const    gr65, $025c             
  2000ff0:  037147a4  const    gr71, $71a4             
  2000ff4:  024e4780  consth   gr71, $4e80             
  2000ff8:  a00200ef  jmp      $2001bb4                   ; -> L_2001bb4
L_2000ffc:
  2000ffc:  1e024667  store    0, 2, gr70, gr103          ; [delay slot]
  2001000:  814548d7  sll      gr69, gr72, $d7         
  2001004:  ac024594  jmpt     gr69, $2001a54             ; -> L_2001a54
  2001008:  03024410  const    gr68, $0210                ; [delay slot]
  200100c:  03714574  const    gr69, $7174             
  2001010:  024e4404  consth   gr68, $4e04             
  2001014:  1e023af7  store    0, 2, gr58, lr119       
  2001018:  1602349f  load     0, 2, gr52, lr31        
  200101c:  a4fd34e3  jmpf     gr52, $20007a8             ; -> L_20007a8
  2001020:  70427c81  aseq     trap66, gr124, lr1         ; [delay slot]
  2001024:  036a3a7c  const    gr58, $6a7c             
  2001028:  024e39e4  consth   gr57, $4ee4             
  200102c:  1e023487  store    0, 2, gr52, lr7         
  2001030:  036a394c  const    gr57, $6a4c             
  2001034:  024e38dc  consth   gr56, $4edc             
  2001038:  1e0233b7  store    0, 2, gr51, lr55        
  200103c:  036a3f70  const    gr63, $6a70             
  2001040:  024e3e84  consth   gr62, $4e84             
  2001044:  1e023557  store    0, 2, gr53, gr87        
  2001048:  036a3d10  const    gr61, $6a10             
  200104c:  024e3d5c  consth   gr61, $4e5c             
  2001050:  1e023667  store    0, 2, gr54, gr103       
  2001054:  c0027b45  jmpi     gr69                    
  2001058:  704275e5  aseq     trap66, gr117, lr101       ; [delay slot]
  200105c:  a007754b  jmp      $2002d88                
  2001060:  030238d0  const    gr56, $02d0                ; [delay slot]
  2001064:  c656709c  mfsr     gr86, spr112            
  2001068:  81572285  sll      gr87, gr34, $85         
  200106c:  a40223f4  jmpf     gr35, $2001c3c             ; -> L_2001c3c
  2001070:  9d562205  andn     gr86, gr34, $05            ; [delay slot]
  2001074:  ce027164  mtsr     spr113, gr100           
  2001078:  88027758  iret                             
  200107c:  03633794  const    gr55, $6394                ; [delay slot]
L_2001080:
  2001080:  024e3700  consth   gr55, $4e00             
  2001084:  160239a7  load     0, 2, gr57, lr39        
  2001088:  61473ae4  cpeq     gr71, gr58, $e4         
  200108c:  ac023744  jmpt     gr55, $200199c             ; -> L_200199c
  2001090:  704272e9  aseq     trap66, gr114, lr105       ; [delay slot]
  2001094:  a00273d8  jmp      $2001bf4                   ; -> L_2001bf4
  2001098:  70427271  aseq     trap66, gr114, gr113       ; [delay slot]
  200109c:  a0076c0b  jmp      $2002cc8                   ; -> L_2002cc8
  20010a0:  0302201d  const    gr32, $021d                ; [delay slot]
  20010a4:  0363281c  const    gr40, $631c             
  20010a8:  024e29b8  consth   gr41, $4eb8             
  20010ac:  1602281a  load     0, 2, gr40, gr26        
  20010b0:  ac022f84  jmpt     gr47, $2001ac0             ; -> L_2001ac0
  20010b4:  01fd2f7f  constn   gr47, $fd7f                ; [delay slot]
  20010b8:  1e022fa2  store    0, 2, gr47, lr34        
  20010bc:  15442e24  add      gr68, gr46, $24         
  20010c0:  04066bb7  mtsrim   spr107, $06b7           
  20010c4:  c65a609c  mfsr     gr90, spr96             
  20010c8:  c65b6110  mfsr     gr91, spr97             
  20010cc:  c6506b70  mfsr     gr80, spr107            
  20010d0:  c6546f04  mfsr     gr84, spr111            
  20010d4:  c65862b0  mfsr     gr88, spr98             
  20010d8:  c65561d8  mfsr     gr85, spr97             
  20010dc:  1e023c5a  store    0, 2, gr60, gr90        
  20010e0:  15442384  add      gr68, gr35, $84         
  20010e4:  1e023c26  store    0, 2, gr60, gr38        
L_20010e8:
  20010e8:  154420e0  add      gr68, gr32, $e0         
  20010ec:  1e023486  store    0, 2, gr52, lr6         
  20010f0:  1544206c  add      gr68, gr32, $6c         
  20010f4:  1e02319a  store    0, 2, gr49, lr26        
  20010f8:  154426f4  add      gr68, gr38, $f4         
  20010fc:  1e023a16  store    0, 2, gr58, gr22        
  2001100:  15442780  add      gr68, gr39, $80         
  2001104:  1e023656  store    0, 2, gr54, gr86        
  2001108:  1544243c  add      gr68, gr36, $3c         
  200110c:  1e02021a  store    0, 2, gr2, gr26         
  2001110:  15442524  add      gr68, gr37, $24         
  2001114:  1e020246  store    0, 2, gr2, gr70         
  2001118:  15441ae0  add      gr68, gr26, $e0         
  200111c:  1e023fe6  store    0, 2, gr63, lr102       
  2001120:  15441b4c  add      gr68, gr27, $4c         
  2001124:  1e023dda  store    0, 2, gr61, lr90        
  2001128:  15441894  add      gr68, gr24, $94         
  200112c:  040a5f9e  mtsrim   spr95, $0a9e            
  2001130:  ce02554c  mtsr     spr85, gr76             
  2001134:  154a1734  add      gr74, gr23, $34         
  2001138:  ce025510  mtsr     spr85, gr16             
  200113c:  8802581c  iret                             
  2001140:  88025800  iret                                ; [delay slot]
  2001144:  c6565fe0  mfsr     gr86, spr95                ; [delay slot]
  2001148:  81570ef1  sll      gr87, gr14, $f1         
  200114c:  a4020f44  jmpf     gr15, $2001a5c             ; -> L_2001a5c
  2001150:  9d560fe9  andn     gr86, gr15, $e9            ; [delay slot]
  2001154:  ce025d88  mtsr     spr93, lr8              
  2001158:  88025b70  iret                             
  200115c:  a007547b  jmp      $2002f48                   ; [delay slot]
  2001160:  0302181e  const    gr24, $021e                ; [delay slot]
  2001164:  c6565090  mfsr     gr86, spr80             
  2001168:  815703ad  sll      gr87, gr3, $ad          
  200116c:  a4020258  jmpf     gr2, $2001acc              ; -> L_2001acc
  2001170:  9d5604a1  andn     gr86, gr4, $a1             ; [delay slot]
  2001174:  ce0256d4  mtsr     spr86, lr84             
L_2001178:
  2001178:  880250e4  iret                             
  200117c:  a0075083  jmp      $2002f88                   ; [delay slot]
  2001180:  03021c53  const    gr28, $0253                ; [delay slot]
  2001184:  247b2c9d  sub      gr123, gr44, lr29       
  2001188:  247c2d69  sub      gr124, gr45, gr105      
  200118c:  46472c31  cpleu    gr71, gr44, gr49        
  2001190:  ac02160c  jmpt     gr22, $20019c0             ; -> L_20019c0
  2001194:  837b35b2  srl      gr123, gr53, $b2           ; [delay slot]
  2001198:  257b35d9  sub      gr123, gr53, $d9        
  200119c:  ce02cb65  mtsr     spr203, gr101           
  20011a0:  3e02cdfe  storem   0, 2, lr77, lr126       
  20011a4:  817d3360  sll      gr125, gr51, $60        
  20011a8:  817c4fe4  sll      gr124, gr79, $e4        
  20011ac:  88024ec0  iret                             
  20011b0:  a0074efe  jmp      $20031a8                   ; [delay slot]
  20011b4:  03020279  const    gr2, $0279                 ; [delay slot]
  20011b8:  030031f0  const    gr49, $00f0             
  20011bc:  927b312f  or       gr123, gr49, gr47       
  20011c0:  ce02c8fd  mtsr     spr200, lr125           
  20011c4:  247bc86f  sub      gr123, lr72, gr111      
  20011c8:  147c3441  add      gr124, gr52, gr65       
  20011cc:  837b335e  srl      gr123, gr51, $5e        
  20011d0:  257b3221  sub      gr123, gr50, $21        
  20011d4:  ce02cc79  mtsr     spr204, gr121           
  20011d8:  817b3be4  sll      gr123, gr59, $e4        
  20011dc:  817dc4a0  sll      gr125, lr68, $a0        
  20011e0:  36024531  loadm    0, 2, gr69, gr49        
  20011e4:  8802469c  iret                             
  20011e8:  15783f90  add      gr120, gr63, $90           ; [delay slot]
  20011ec:  25783c46  sub      gr120, gr60, $46        
  20011f0:  ac023c0e  jmpt     gr60, $2001a28             ; -> L_2001a28
  20011f4:  4d7b3de6  cpge     gr123, gr61, $e6           ; [delay slot]
  20011f8:  ac023e50  jmpt     gr62, $2001b38             ; -> L_2001b38
  20011fc:  81783a1e  sll      gr120, gr58, $1e           ; [delay slot]
  2001200:  03270600  const    gr6, $2700              
  2001204:  024e07e0  consth   gr7, $4ee0              
  2001208:  1478049e  add      gr120, gr4, lr30        
  200120c:  1602383a  load     0, 2, gr56, gr58        
  2001210:  c0024392  jmpi     lr18                    
  2001214:  607b3aa5  cpeq     gr123, gr58, lr37          ; [delay slot]
  2001218:  01fd23a6  constn   gr35, $fda6             
  200121c:  0303c5d0  const    lr69, $03d0             
  2001220:  8803bd84  iret                             
  2001224:  0303f9c4  const    lr121, $03c4               ; [delay slot]
  2001228:  0247f8b8  consth   lr120, $47b8            
  200122c:  02fcf7a3  consth   lr119, $fca3            
  2001230:  1e03f0e7  store    0, 3, lr112, lr103      
  2001234:  0303f1e8  const    lr113, $03e8            
  2001238:  0247f1e4  consth   lr113, $47e4            
  200123c:  1603f269  load     0, 3, lr114, gr105      
  2001240:  a4fcf337  jmpf     lr115, $200031c            ; -> L_200031c
  2001244:  0303f29c  const    lr114, $039c               ; [delay slot]
  2001248:  1e03f257  store    0, 3, lr114, gr87       
  200124c:  8803ba70  iret                             
  2001250:  036bfc28  const    lr124, $6b28               ; [delay slot]
  2001254:  024ff3b0  consth   lr115, $4fb0            
  2001258:  1603d49f  load     0, 3, lr84, lr31        
  200125c:  8803b41c  iret                             
  2001260:  0367f3bc  const    lr115, $67bc               ; [delay slot]
  2001264:  024ff360  consth   lr115, $4f60            
  2001268:  1603d6a2  load     0, 3, lr86, lr34        
  200126c:  ac0334c9  jmpt     gr52, $2002190             ; -> L_2002190
  2001270:  0303f169  const    lr113, $0369               ; [delay slot]
  2001274:  8044f05e  sll      gr68, lr112, gr94       
  2001278:  9c44d0b7  andn     gr68, lr80, lr55        
  200127c:  1e03f716  store    0, 3, lr119, gr22       
  2001280:  8144f694  sll      gr68, lr118, $94        
  2001284:  0303f710  const    lr119, $0310            
  2001288:  0245f438  consth   lr116, $4538            
  200128c:  1e03f51a  store    0, 3, lr117, gr26       
  2001290:  8803b320  iret                             
  2001294:  8144f303  sll      gr68, lr115, $03           ; [delay slot]
  2001298:  a403ebe0  jmpf     lr107, $2002218            ; -> L_2002218
  200129c:  0303cda0  const    lr77, $03a0                ; [delay slot]
  20012a0:  a000ad1f  jmp      $200131c                   ; -> L_200131c
  20012a4:  7043af9d  aseq     trap67, lr47, lr29         ; [delay slot]
  20012a8:  8803ae90  iret                             
  20012ac:  8146eefb  sll      gr70, lr110, $fb           ; [delay slot]
  20012b0:  ac03eb02  jmpt     lr107, $2001eb8            ; -> L_2001eb8
  20012b4:  0333ea30  const    lr106, $3330               ; [delay slot]
  20012b8:  0203ea58  consth   lr106, $0358            
  20012bc:  2447d759  sub      gr71, lr87, gr89        
  20012c0:  2463ec41  sub      gr99, lr108, gr65       
  20012c4:  8803a9e0  iret                             
  20012c8:  0367eeec  const    lr110, $67ec               ; [delay slot]
  20012cc:  024fee40  consth   lr110, $4f40            
  20012d0:  1603efac  load     0, 3, lr111, lr44       
  20012d4:  0313e8dc  const    lr104, $13dc            
  20012d8:  0203e870  consth   lr104, $0370            
  20012dc:  2447e093  sub      gr71, lr96, lr19        
  20012e0:  2463e1c5  sub      gr99, lr97, lr69        
  20012e4:  8803a690  iret                             
  20012e8:  0303e138  const    lr97, $0338                ; [delay slot]
  20012ec:  0247e15c  consth   lr97, $475c             
  20012f0:  1603e6e6  load     0, 3, lr102, lr102      
  20012f4:  a403e684  jmpf     lr102, $2002104            ; -> L_2002104
  20012f8:  7043a1e5  aseq     trap67, lr33, lr101        ; [delay slot]
  20012fc:  83812221  srl      lr1, gr34, $21          
  2001300:  838725c9  srl      lr7, gr37, $c9          
  2001304:  6145209c  cpeq     gr69, gr32, $9c         
  2001308:  ac03e41b  jmpt     lr100, $2001f74            ; -> L_2001f74
  200130c:  036be46c  const    lr100, $6b6c               ; [delay slot]
  2001310:  024fe504  consth   lr101, $4f04            
L_2001314:
  2001314:  1e031ef6  store    0, 3, gr30, lr118       
  2001318:  0303dad8  const    lr90, $03d8             
L_200131c:
  200131c:  0247da1c  consth   lr90, $471c             
  2001320:  814b1f8a  sll      gr75, gr31, $8a         
  2001324:  0303da72  const    lr90, $0372             
  2001328:  1e03d6a2  store    0, 3, lr86, lr34        
  200132c:  b4fcd93f  jmpfdec  lr89, $2000428             ; -> L_2000428
L_2001330:
  2001330:  814bd669  sll      gr75, lr86, $69            ; [delay slot]
  2001334:  61451bdc  cpeq     gr69, gr27, $dc         
  2001338:  ac03defb  jmpt     lr94, $2002324             ; -> L_2002324
  200133c:  036bde74  const    lr94, $6b74                ; [delay slot]
  2001340:  024fdf84  consth   lr95, $4f84             
  2001344:  1e031d56  store    0, 3, gr29, gr86        
  2001348:  0303dc98  const    lr92, $0398             
  200134c:  0247dc5c  consth   lr92, $475c             
  2001350:  814b1f32  sll      gr75, gr31, $32         
  2001354:  0303dc0a  const    lr92, $030a             
  2001358:  1e03dca2  store    0, 3, lr92, lr34        
  200135c:  b4fcd25f  jmpfdec  lr82, $20004d8             ; -> L_20004d8
  2001360:  814bdd49  sll      gr75, lr93, $49            ; [delay slot]
  2001364:  0303f69c  const    lr118, $039c            
  2001368:  88039690  iret                             
  200136c:  01fcf60f  constn   lr118, $fc0f               ; [delay slot]
  2001370:  88039604  iret                             
  2001374:  04031230  mtsrim   spr18, $0330               ; [delay slot]
  2001378:  0303d058  const    lr80, $0358             
  200137c:  0245d7dc  consth   lr87, $45dc             
L_2001380:
  2001380:  0c4b1282  inbyte   gr75, gr18, lr2         
  2001384:  1e02d9a7  store    0, 2, lr89, lr39        
  2001388:  0303d5e0  const    lr85, $03e0             
  200138c:  0245d580  consth   lr85, $4580             
  2001390:  0c4b106b  inbyte   gr75, gr16, gr107       
  2001394:  1e02db9b  store    0, 2, lr91, lr27        
  2001398:  0c4b17f4  inbyte   gr75, gr23, lr116       
  200139c:  1e02c497  store    0, 2, lr68, lr23        
L_20013a0:
  20013a0:  0c4b0801  inbyte   gr75, gr8, gr1          
  20013a4:  1e02c6d7  store    0, 2, lr70, lr87        
  20013a8:  88038fb8  iret                             
  20013ac:  49440da3  cpgt     gr68, gr13, $a3            ; [delay slot]
  20013b0:  ac03cfb5  jmpt     lr79, $2002284             ; -> L_2002284
  20013b4:  01fce87f  constn   lr104, $fc7f               ; [delay slot]
  20013b8:  0303c1e4  const    lr65, $03e4             
  20013bc:  02fcc120  consth   lr65, $fc20             
  20013c0:  04030cc8  mtsrim   PC2, $03c8              
  20013c4:  0303cd9c  const    lr77, $039c             
  20013c8:  0245cdd0  consth   lr77, $45d0             
  20013cc:  0c4b08f2  inbyte   gr75, gr8, lr114        
  20013d0:  1e02c343  store    0, 2, lr67, gr67        
  20013d4:  0303c3b4  const    lr67, $03b4             
  20013d8:  0245c318  consth   lr67, $4518             
  20013dc:  1603e45b  load     0, 3, lr100, gr91       
  20013e0:  8363e588  srl      gr99, lr101, $88        
L_20013e4:
  20013e4:  1603cd27  load     0, 3, lr77, gr39        
  20013e8:  904bcead  and      gr75, lr78, lr45        
  20013ec:  9263e688  or       gr99, lr102, lr8        
L_20013f0:
  20013f0:  8363e660  srl      gr99, lr102, $60        
  20013f4:  1603cf9b  load     0, 3, lr79, lr27        
  20013f8:  904bc8b9  and      gr75, lr72, lr57        
  20013fc:  9263e018  or       gr99, lr96, gr24        
  2001400:  8363e18c  srl      gr99, lr97, $8c         
  2001404:  88038110  iret                             
  2001408:  0367e238  const    lr98, $6738                ; [delay slot]
  200140c:  024fe25c  consth   lr98, $4f5c             
  2001410:  88038320  iret                             
  2001414:  8146c30b  sll      gr70, lr67, $0b            ; [delay slot]
  2001418:  a403b9f4  jmpf     lr57, $20023e8             ; -> L_20023e8
  200141c:  03039da0  const    lr29, $03a0                ; [delay slot]
  2001420:  0332bb68  const    lr59, $3268             
  2001424:  024fb89c  consth   lr56, $4f9c             
  2001428:  1603b9d6  load     0, 3, lr57, lr86        
  200142c:  144ab972  add      gr74, lr57, gr114       
  2001430:  1e03b742  store    0, 3, lr55, gr66        
  2001434:  03fcbacf  const    lr58, $fccf             
  2001438:  020cbaa7  consth   lr58, $0ca7             
  200143c:  904ab159  and      gr74, lr49, gr89        
  2001440:  0303bd00  const    lr61, $0300             
  2001444:  020fbce0  consth   lr60, $0fe0             
  2001448:  4246b3a1  cpltu    gr70, lr51, lr33        
  200144c:  a403bf43  jmpf     lr63, $2002158             ; -> L_2002158
  2001450:  03039be8  const    lr27, $03e8                ; [delay slot]
  2001454:  1563bcdc  add      gr99, lr60, $dc         
  2001458:  8803fb70  iret                             
  200145c:  01fc9406  constn   lr20, $fc06                ; [delay slot]
  2001460:  8803f584  iret                             
  2001464:  01fc9646  constn   lr22, $fc46                ; [delay slot]
  2001468:  8803f7b8  iret                             
  200146c:  a803b25f  call     lr50, $20021e8             ; -> L_20021e8   ; [delay slot]
  2001470:  7043f1a1  aseq     trap67, lr113, lr33        ; [delay slot]
  2001474:  8803f080  iret                             
  2001478:  01ffb3e4  constn   lr51, $ffe4                ; [delay slot]
  200147c:  90457263  and      gr69, gr114, gr99       
  2001480:  6045b74a  cpeq     gr69, lr55, gr74        
  2001484:  a403b4c5  jmpf     lr52, $2002398             ; -> L_2002398
  2001488:  01ffb110  constn   lr49, $ff10                ; [delay slot]
  200148c:  90457133  and      gr69, gr113, gr51       
  2001490:  6045b587  cpeq     gr69, lr53, lr7         
  2001494:  a403aae3  jmpf     lr42, $2002420             ; -> L_2002420
  2001498:  0332a0b0  const    lr32, $32b0                ; [delay slot]
  200149c:  024fa01c  consth   lr32, $4f1c             
  20014a0:  1603a7cc  load     0, 3, lr39, lr76        
  20014a4:  6144a760  cpeq     gr68, lr39, $60         
  20014a8:  a403a9e0  jmpf     lr41, $2002428             ; -> L_2002428
  20014ac:  0303a9c0  const    lr41, $03c0                ; [delay slot]
  20014b0:  020ba968  consth   lr41, $0b68             
  20014b4:  9243af9b  or       gr67, lr47, lr27        
  20014b8:  0300af0f  const    lr47, $000f             
  20014bc:  4c44a217  cpge     gr68, lr34, gr23        
  20014c0:  ac03aec8  jmpt     lr46, $20023e0             ; -> L_20023e0
  20014c4:  0332a07c  const    lr32, $327c                ; [delay slot]
  20014c8:  024fa338  consth   lr35, $4f38             
  20014cc:  8144a05e  sll      gr68, lr32, $5e         
  20014d0:  8145a123  sll      gr69, lr33, $23         
  20014d4:  1448ad47  add      gr72, lr45, gr71        
  20014d8:  1448adaf  add      gr72, lr45, lr47        
  20014dc:  614bafa0  cpeq     gr75, lr47, $a0         
  20014e0:  ac03ad5e  jmpt     lr45, $2002258             ; -> L_2002258
  20014e4:  8144af9c  sll      gr68, lr47, $9c            ; [delay slot]
  20014e8:  1603a0d7  load     0, 3, lr32, lr87        
  20014ec:  424b64b6  cpltu    gr75, gr100, lr54       
  20014f0:  ac03ae0a  jmpt     lr46, $2002118             ; -> L_2002118
  20014f4:  154ba034  add      gr75, lr32, $34            ; [delay slot]
  20014f8:  1603af10  load     0, 3, lr47, gr16        
  20014fc:  144ba654  add      gr75, lr38, gr84        
  2001500:  4e4b6248  cpgeu    gr75, gr98, gr72        
  2001504:  ac03a9e9  jmpt     lr41, $20024a8             ; -> L_20024a8
  2001508:  154ba5ec  add      gr75, lr37, $ec            ; [delay slot]
  200150c:  1603af08  load     0, 3, lr47, gr8         
L_2001510:
  2001510:  244b61ae  sub      gr75, gr97, lr46        
  2001514:  144bae94  add      gr75, lr46, lr20        
  2001518:  604b6038  cpeq     gr75, gr96, gr56        
  200151c:  a40394fd  jmpf     lr20, $2002510             ; -> L_2002510
  2001520:  7043dc85  aseq     trap67, lr92, lr5          ; [delay slot]
  2001524:  a003de9c  jmp      $2002394                   ; -> L_2002394
  2001528:  154498b4  add      gr68, lr24, $b4            ; [delay slot]
  200152c:  604b941b  cpeq     gr75, lr20, gr27        
  2001530:  a4fc904e  jmpf     lr16, $2000668             ; -> L_2000668
  2001534:  7043d981  aseq     trap67, lr89, lr1          ; [delay slot]
  2001538:  154992e5  add      gr73, lr18, $e5         
L_200153c:
  200153c:  1e03926c  store    0, 3, lr18, gr108       
  2001540:  1e035b83  store    0, 3, gr91, lr3         
  2001544:  15489198  add      gr72, lr17, $98         
  2001548:  1e035e5b  store    0, 3, gr94, gr91        
  200154c:  15489174  add      gr72, lr17, $74         
  2001550:  1e03584f  store    0, 3, gr88, gr79        
  2001554:  16038ffc  load     0, 3, lr15, lr124       
  2001558:  25458fd9  sub      gr69, lr15, $d9         
  200155c:  ac039210  jmpt     lr18, $200219c             ; -> L_200219c
  2001560:  25458e81  sub      gr69, lr14, $81            ; [delay slot]
  2001564:  0332920c  const    lr18, $320c             
  2001568:  024f91e4  consth   lr17, $4fe4             
  200156c:  16039e87  load     0, 3, lr30, lr7         
  2001570:  03039f69  const    lr31, $0369             
  2001574:  834b9fc0  srl      gr75, lr31, $c0         
  2001578:  154b98e0  add      gr75, lr24, $e0         
  200157c:  804a9918  sll      gr74, lr25, gr24        
  2001580:  92588acd  or       gr88, lr10, lr77        
  2001584:  b4fc97ea  jmpfdec  lr23, $200092c             ; -> L_200092c
  2001588:  15449534  add      gr68, lr21, $34            ; [delay slot]
  200158c:  03039b22  const    lr27, $0322             
  2001590:  03039b20  const    lr27, $0320             
  2001594:  b6449b00  mftlb    gr68, lr27              
  2001598:  83448bec  srl      gr68, lr11, $ec         
  200159c:  91448a9f  and      gr68, lr10, $9f         
  20015a0:  61448a7e  cpeq     gr68, lr10, $7e         
  20015a4:  a403899f  jmpf     lr9, $2002420              ; -> L_2002420
  20015a8:  03038890  const    lr8, $0390                 ; [delay slot]
  20015ac:  be0386b6  mttlb    lr6, lr54               
L_20015b0:
  20015b0:  b4fc87fd  jmpfdec  lr7, $20009a4              ; -> L_20009a4
  20015b4:  154b8732  add      gr75, lr7, $32             ; [delay slot]
  20015b8:  c003cf1d  jmpi     gr29                    
  20015bc:  0303a81c  const    lr40, $031c                ; [delay slot]
  20015c0:  c003c845  jmpi     gr69                    
  20015c4:  01fca917  constn   lr41, $fc17                ; [delay slot]
  20015c8:  c003caa1  jmpi     lr33                    
  20015cc:  01fcaab8  constn   lr42, $fcb8                ; [delay slot]
  20015d0:  c003cbad  jmpi     lr45                    
  20015d4:  01fcab25  constn   lr43, $fc25                ; [delay slot]
  20015d8:  c003cb35  jmpi     gr53                    
  20015dc:  01fca42a  constn   lr36, $fc2a                ; [delay slot]
  20015e0:  c003c5c1  jmpi     lr65                    
  20015e4:  01fca66b  constn   lr38, $fc6b                ; [delay slot]
  20015e8:  c003c7fd  jmpi     lr125                   
  20015ec:  01fca7a0  constn   lr39, $fca0                ; [delay slot]
  20015f0:  c003c0e5  jmpi     lr101                   
L_20015f4:
  20015f4:  01fca07d  constn   lr32, $fc7d                ; [delay slot]
  20015f8:  a80385e7  call     lr5, $2002594              ; -> L_2002594
  20015fc:  7043c121  aseq     trap67, lr65, gr33         ; [delay slot]
  2001600:  8803c1c8  iret                             
  2001604:  01fc8463  constn   lr4, $fc63                 ; [delay slot]
  2001608:  60454056  cpeq     gr69, gr64, gr86        
  200160c:  ac038450  jmpt     lr4, $200234c              ; -> L_200234c
  2001610:  01ff8004  constn   lr0, $ff04                 ; [delay slot]
  2001614:  9045bef3  and      gr69, lr62, lr115       
L_2001618:
  2001618:  60457a5a  cpeq     gr69, gr122, gr90       
  200161c:  a4fc7aef  jmpf     gr122, $20009d8            ; -> L_20009d8
  2001620:  033271e8  const    gr113, $32e8               ; [delay slot]
  2001624:  024f7160  consth   gr113, $4f60            
  2001628:  160374a8  load     0, 3, gr116, lr40       
  200162c:  614474c0  cpeq     gr68, gr116, $c0        
  2001630:  acfc798e  jmpt     gr121, $2000868            ; -> L_2000868
  2001634:  033276b0  const    gr118, $32b0               ; [delay slot]
  2001638:  024f71f0  consth   gr113, $4ff0            
  200163c:  81447252  sll      gr68, gr114, $52        
  2001640:  81457387  sll      gr69, gr115, $87        
  2001644:  14487f57  add      gr72, gr127, gr87       
  2001648:  14487373  add      gr72, gr115, gr115      
  200164c:  8144735c  sll      gr68, gr115, $5c        
  2001650:  16037d67  load     0, 3, gr125, gr103      
  2001654:  424bb946  cpltu    gr75, lr57, gr70        
  2001658:  ac037ce3  jmpt     gr124, $20025e4            ; -> L_20025e4
  200165c:  154b72a4  add      gr75, gr114, $a4           ; [delay slot]
  2001660:  16037d00  load     0, 3, gr125, gr0        
  2001664:  144b70d4  add      gr75, gr112, lr84       
  2001668:  424bb4d8  cpltu    gr75, lr52, lr88        
  200166c:  ac037efd  jmpt     gr126, $2002660            ; -> L_2002660
  2001670:  70433705  aseq     trap67, gr55, gr5          ; [delay slot]
  2001674:  1544703c  add      gr68, gr112, $3c        
  2001678:  4c4b7013  cpge     gr75, gr112, gr19       
  200167c:  a4fc78e9  jmpf     gr120, $2000a20            ; -> L_2000a20
L_2001680:
  2001680:  70433101  aseq     trap67, gr49, gr1          ; [delay slot]
  2001684:  a0fc312f  jmp      $2000740                   ; -> L_2000740
  2001688:  704333e5  aseq     trap67, gr51, lr101        ; [delay slot]
  200168c:  03037440  const    gr116, $0340            
  2001690:  03327480  const    gr116, $3280            
  2001694:  024f74dc  consth   gr116, $4fdc            
  2001698:  a0033364  jmp      $2002428                   ; -> L_2002428
  200169c:  1e036a97  store    0, 3, gr106, lr23          ; [delay slot]
  20016a0:  25496785  sub      gr73, gr103, $85        
  20016a4:  1e0364dc  store    0, 3, gr100, lr92       
  20016a8:  614b65b8  cpeq     gr75, gr101, $b8        
  20016ac:  ac036770  jmpt     gr103, $200246c            ; -> L_200246c
L_20016b0:
  20016b0:  254863ac  sub      gr72, gr99, $ac            ; [delay slot]
  20016b4:  604b63c7  cpeq     gr75, gr99, lr71        
  20016b8:  ac0360e8  jmpt     gr96, $2002658             ; -> L_2002658
  20016bc:  70432921  aseq     trap67, gr41, gr33         ; [delay slot]
  20016c0:  16036183  load     0, 3, gr97, lr3         
  20016c4:  15486198  add      gr72, gr97, $98         
  20016c8:  1e036257  store    0, 3, gr98, gr87        
  20016cc:  15446d74  add      gr68, gr109, $74        
  20016d0:  1603634f  load     0, 3, gr99, gr79        
  20016d4:  15486fb4  add      gr72, gr111, $b4        
  20016d8:  1e036c9f  store    0, 3, gr108, lr31       
  20016dc:  15446318  add      gr68, gr99, $18         
  20016e0:  16036dcb  load     0, 3, gr109, lr75       
  20016e4:  1e036d27  store    0, 3, gr109, gr39       
  20016e8:  03036f9a  const    gr111, $039a            
  20016ec:  03036ec0  const    gr110, $03c0            
  20016f0:  b6446e68  mftlb    gr68, gr110             
  20016f4:  834460d4  srl      gr68, gr96, $d4         
  20016f8:  914467cf  and      gr68, gr103, $cf        
  20016fc:  61446766  cpeq     gr68, gr103, $66        
L_2001700:
  2001700:  a4036687  jmpf     gr102, $200251c            ; -> L_200251c
  2001704:  03036710  const    gr103, $0310               ; [delay slot]
  2001708:  be036a7e  mttlb    gr106, gr126            
  200170c:  b4fc6ba5  jmpfdec  gr107, $20009a0            ; -> L_20009a0
  2001710:  154b6b22  add      gr75, gr107, $22           ; [delay slot]
  2001714:  03327868  const    gr120, $3268            
  2001718:  024f47e4  consth   gr71, $4fe4             
  200171c:  160346fb  load     0, 3, gr70, lr123       
  2001720:  25454649  sub      gr69, gr70, $49         
  2001724:  ac035890  jmpt     gr88, $2002564             ; -> L_2002564
  2001728:  25454591  sub      gr69, gr69, $91            ; [delay slot]
  200172c:  0332599c  const    gr89, $329c             
  2001730:  024f5904  consth   gr89, $4f04             
  2001734:  16035777  load     0, 3, gr87, gr119       
  2001738:  03035659  const    gr86, $0359             
  200173c:  834b5000  srl      gr75, gr80, $00         
  2001740:  154b5010  add      gr75, gr80, $10         
L_2001744:
  2001744:  804a50a8  sll      gr74, gr80, lr40        
  2001748:  925841ad  or       gr88, gr65, lr45        
  200174c:  b4fc5cba  jmpfdec  gr92, $2000a34             ; -> L_2000a34
  2001750:  15445ce4  add      gr68, gr92, $e4            ; [delay slot]
  2001754:  c0031b99  jmpi     lr25                    
  2001758:  03037b70  const    gr123, $0370               ; [delay slot]
  200175c:  030353d0  const    gr83, $03d0             
  2001760:  020b5284  consth   gr82, $0b84             
  2001764:  9c4356d7  andn     gr67, gr86, lr87        
  2001768:  03034cb8  const    gr76, $03b8             
  200176c:  c0031719  jmpi     gr25                    
  2001770:  030370a0  const    gr112, $03a0               ; [delay slot]
  2001774:  01ff5380  constn   gr83, $ff80             
  2001778:  904592a7  and      gr69, lr18, lr39        
  200177c:  604556a2  cpeq     gr69, gr86, lr34        
  2001780:  a4fc5752  jmpf     gr87, $20008c8             ; -> L_20008c8
  2001784:  03325ef4  const    gr94, $32f4                ; [delay slot]
  2001788:  024f5e10  consth   gr94, $4f10             
  200178c:  1603583c  load     0, 3, gr88, gr60        
  2001790:  61445904  cpeq     gr68, gr89, $04         
  2001794:  acfc4b3d  jmpt     gr75, $2000888             ; -> L_2000888
  2001798:  033245b4  const    gr69, $32b4                ; [delay slot]
  200179c:  024f451c  consth   gr69, $4f1c             
  20017a0:  81444782  sll      gr68, gr71, $82         
L_20017a4:
  20017a4:  81454763  sll      gr69, gr71, $63         
  20017a8:  144848a3  add      gr72, gr72, lr35        
  20017ac:  1448478b  add      gr72, gr71, lr11        
  20017b0:  81444768  sll      gr68, gr71, $68         
  20017b4:  1603499b  load     0, 3, gr73, lr27        
  20017b8:  424b8ab6  cpltu    gr75, lr10, lr54        
  20017bc:  ac034057  jmpt     gr64, $2002518             ; -> L_2002518
  20017c0:  154b4e80  add      gr75, gr78, $80            ; [delay slot]
L_20017c4:
  20017c4:  16034158  load     0, 3, gr65, gr88        
  20017c8:  144b4c70  add      gr75, gr76, gr112       
  20017cc:  424b8814  cpltu    gr75, lr8, gr20         
  20017d0:  ac034328  jmpt     gr67, $2002470             ; -> L_2002470
  20017d4:  70430a01  aseq     trap67, gr10, gr1          ; [delay slot]
  20017d8:  154443e8  add      gr68, gr67, $e8         
  20017dc:  4c4b42eb  cpge     gr75, gr66, lr107       
  20017e0:  a4fc4dbd  jmpf     gr77, $2000ad4             ; -> L_2000ad4
  20017e4:  7043079d  aseq     trap67, gr7, lr29          ; [delay slot]
  20017e8:  a0fc06e6  jmp      $2000b80                   ; -> L_2000b80
  20017ec:  704307f1  aseq     trap67, gr7, lr113         ; [delay slot]
  20017f0:  244b8442  sub      gr75, lr4, gr66         
  20017f4:  15444038  add      gr68, gr64, $38         
  20017f8:  1603401f  load     0, 3, gr64, gr31        
  20017fc:  14794754  add      gr121, gr71, gr84       
  2001800:  03036000  const    gr96, $0300             
  2001804:  880301e0  iret                             
  2001808:  814580e4  sll      gr69, lr0, $e4             ; [delay slot]
L_200180c:
  200180c:  a8024748  call     gr71, $200212c             ; -> L_200212c
  2001810:  814463e8  sll      gr68, gr99, $e8            ; [delay slot]
  2001814:  816345dc  sll      gr99, gr69, $dc         
  2001818:  81794470  sll      gr121, gr68, $70        
  200181c:  88037cd0  iret                             
  2001820:  036b37cc  const    gr55, $6bcc                ; [delay slot]
  2001824:  024f3490  consth   gr52, $4f90             
  2001828:  1e03fdf2  store    0, 3, lr125, lr114      
  200182c:  c6517e5c  mfsr     gr81, spr126            
  2001830:  91452ae0  and      gr69, gr42, $e0         
  2001834:  63633ec0  cpneq    gr99, gr62, $c0         
  2001838:  836318fb  srl      gr99, gr24, $fb         
  200183c:  6145fa20  cpeq     gr69, lr122, $20        
L_2001840:
  2001840:  a4033fcc  jmpf     gr63, $2002770             ; -> L_2002770
  2001844:  935128dc  or       gr81, gr40, $dc            ; [delay slot]
  2001848:  ce037b42  mtsr     spr123, gr66            
  200184c:  88037a70  iret                             
  2001850:  0303327a  const    gr50, $037a                ; [delay slot]
  2001854:  03033cb0  const    gr60, $03b0             
  2001858:  b6443cd8  mftlb    gr68, gr60              
  200185c:  83443314  srl      gr68, gr51, $14         
  2001860:  914432bf  and      gr68, gr50, $bf         
L_2001864:
  2001864:  61443256  cpeq     gr68, gr50, $56         
  2001868:  a40331e7  jmpf     gr49, $2002804             ; -> L_2002804
  200186c:  030330c0  const    gr48, $03c0                ; [delay slot]
  2001870:  be033e2e  mttlb    gr62, gr46              
  2001874:  b4fc3e25  jmpfdec  gr62, $2000908             ; -> L_2000908
  2001878:  154b38f2  add      gr75, gr56, $f2            ; [delay slot]
  200187c:  9d512210  andn     gr81, gr34, $10         
  2001880:  ce0370d6  mtsr     spr112, lr86            
  2001884:  88037110  iret                             
  2001888:  03023b38  const    gr59, $0238                ; [delay slot]
  200188c:  02033b5c  consth   gr59, $035c             
  2001890:  9c433369  andn     gr67, gr51, gr105       
  2001894:  030b3a00  const    gr58, $0b00             
  2001898:  c6516de4  mfsr     gr81, spr109            
  200189c:  92513fe9  or       gr81, gr63, lr105       
  20018a0:  ce036c1a  mtsr     spr108, gr26            
L_20018a4:
  20018a4:  030327c0  const    gr39, $03c0             
  20018a8:  02472790  consth   gr39, $4790             
  20018ac:  030322f0  const    gr34, $03f0             
  20018b0:  1e03224d  store    0, 3, gr34, gr77        
  20018b4:  88036f30  iret                             
  20018b8:  c6456e58  mfsr     gr69, spr110               ; [delay slot]
  20018bc:  914b2e0c  and      gr75, gr46, $0c         
  20018c0:  63632000  cpneq    gr99, gr32, $00         
  20018c4:  6144ebe0  cpeq     gr68, lr107, $e0        
  20018c8:  ac032de0  jmpt     gr45, $2002848             ; -> L_2002848
  20018cc:  93452c50  or       gr69, gr44, $50            ; [delay slot]
  20018d0:  ce036aae  mtsr     spr106, lr46            
  20018d4:  88036bdc  iret                             
  20018d8:  9d452d60  andn     gr69, gr45, $60            ; [delay slot]
  20018dc:  ce036596  mtsr     spr101, lr22            
  20018e0:  88036584  iret                             
L_20018e4:
  20018e4:  c6446f90  mfsr     gr68, spr111               ; [delay slot]
  20018e8:  030321b8  const    gr33, $03b8             
  20018ec:  0202215c  consth   gr33, $025c             
  20018f0:  904b27e6  and      gr75, gr39, lr102       
  20018f4:  63632880  cpneq    gr99, gr40, $80         
  20018f8:  614be2e4  cpeq     gr75, lr98, $e4         
  20018fc:  ac032827  jmpt     gr40, $2002598             ; -> L_2002598
  2001900:  037626f8  const    gr38, $76f8                ; [delay slot]
  2001904:  0203259c  consth   gr37, $039c             
  2001908:  ce036a57  mtsr     spr106, gr87            
  200190c:  92442536  or       gr68, gr37, gr54        
L_2001910:
  2001910:  ce036a43  mtsr     spr106, gr67            
  2001914:  88035cb0  iret                             
  2001918:  040354d8  mtsrim   spr84, $03d8               ; [delay slot]
  200191c:  0403551c  mtsrim   spr85, $031c            
  2001920:  88035d80  iret                             
L_2001924:
  2001924:  c6455c60  mfsr     gr69, spr92                ; [delay slot]
  2001928:  914b18e6  and      gr75, gr24, $e6         
  200192c:  636316c0  cpneq    gr99, gr22, $c0         
  2001930:  6144dc68  cpeq     gr68, lr92, $68         
  2001934:  ac0318d8  jmpt     gr24, $2002894             ; -> L_2002894
  2001938:  93451ef2  or       gr69, gr30, $f2            ; [delay slot]
  200193c:  ce035916  mtsr     spr89, gr22             
  2001940:  88035984  iret                             
  2001944:  9d451f12  andn     gr69, gr31, $12            ; [delay slot]
  2001948:  ce035b7e  mtsr     spr91, gr126            
  200194c:  88035a5c  iret                             
  2001950:  4146d920  cplt     gr70, lr89, $20            ; [delay slot]
  2001954:  ac031e18  jmpt     gr30, $20025b4             ; -> L_20025b4
  2001958:  4946d6e7  cpgt     gr70, lr86, $e7            ; [delay slot]
  200195c:  ac0310b6  jmpt     gr16, $2002834             ; -> L_2002834
  2001960:  6146d748  cpeq     gr70, lr87, $48            ; [delay slot]
  2001964:  a4031398  jmpf     gr19, $20027c4             ; -> L_20027c4
  2001968:  036210ec  const    gr16, $62ec                ; [delay slot]
  200196c:  024f10f0  consth   gr16, $4ff0             
  2001970:  a003560a  jmp      $2002598                   ; -> L_2002598
  2001974:  6146d531  cpeq     gr70, lr85, $31            ; [delay slot]
  2001978:  a403125c  jmpf     gr18, $20026e8             ; -> L_20026e8
  200197c:  0362169c  const    gr22, $629c                ; [delay slot]
  2001980:  024f1600  consth   gr22, $4f00             
  2001984:  a00351e9  jmp      $2002928                   ; -> L_2002928
  2001988:  6146d0e6  cpeq     gr70, lr80, $e6            ; [delay slot]
  200198c:  a4031745  jmpf     gr23, $20026a0             ; -> L_20026a0
  2001990:  0362156c  const    gr21, $626c                ; [delay slot]
  2001994:  024f15dc  consth   gr21, $4fdc             
  2001998:  a0035374  jmp      $2002768                   ; -> L_2002768
L_200199c:
  200199c:  70434dd1  aseq     trap67, gr77, lr81         ; [delay slot]
  20019a0:  03620b0c  const    gr11, $620c             
  20019a4:  024f0890  consth   gr8, $4f90              
  20019a8:  1e03ccfe  store    0, 3, lr76, lr126       
  20019ac:  03032f5c  const    gr47, $035c             
  20019b0:  880348a0  iret                             
  20019b4:  01fc287f  constn   gr40, $fc7f                ; [delay slot]
  20019b8:  880348e4  iret                             
  20019bc:  03620eac  const    gr14, $62ac                ; [delay slot]
L_20019c0:
  20019c0:  024f0fc8  consth   gr15, $4fc8             
  20019c4:  16030dda  load     0, 3, gr13, lr90        
  20019c8:  a4030d0f  jmpf     gr13, $2002604             ; -> L_2002604
  20019cc:  03030d70  const    gr13, $0370                ; [delay slot]
  20019d0:  1e030c42  store    0, 3, gr12, gr66        
  20019d4:  154502b4  add      gr69, gr2, $b4          
  20019d8:  16031c9e  load     0, 3, gr28, lr30        
  20019dc:  15450218  add      gr69, gr2, $18          
  20019e0:  16031cc6  load     0, 3, gr28, lr70        
  20019e4:  15450364  add      gr69, gr3, $64          
  20019e8:  160314a2  load     0, 3, gr20, lr34        
  20019ec:  154500c4  add      gr69, gr0, $c4          
  20019f0:  1603102e  load     0, 3, gr16, gr46        
  20019f4:  154501d8  add      gr69, gr1, $d8          
  20019f8:  16031ab6  load     0, 3, gr26, lr54        
  20019fc:  15450654  add      gr69, gr6, $54          
  2001a00:  160316c2  load     0, 3, gr22, lr66        
  2001a04:  15450714  add      gr69, gr7, $14          
  2001a08:  1603227e  load     0, 3, gr34, gr126       
  2001a0c:  15450458  add      gr69, gr4, $58          
  2001a10:  16032266  load     0, 3, gr34, gr102       
  2001a14:  15450504  add      gr69, gr5, $04          
  2001a18:  167cdea2  load     0, 7c, lr94, lr34       
  2001a1c:  153afba4  add      gr58, lr123, $a4        
  2001a20:  167cde0e  load     0, 7c, lr94, gr14       
  2001a24:  153af898  add      gr58, lr120, $98        
L_2001a28:
  2001a28:  0478bcef  mtsrim   spr188, $78ef           
  2001a2c:  ce7cb4a8  mtsr     spr180, lr40            
  2001a30:  ce7cb55d  mtsr     spr181, gr93            
  2001a34:  ce7cbe62  mtsr     spr190, gr98            
  2001a38:  ce7cbb0e  mtsr     spr187, gr14            
L_2001a3c:
  2001a3c:  ce7cbe46  mtsr     spr190, gr70            
  2001a40:  ce7cbd57  mtsr     spr189, gr87            
  2001a44:  887cb9e0  iret                             
  2001a48:  0314fde0  const    lr125, $14e0               ; [delay slot]
  2001a4c:  0230fd40  consth   lr125, $3040            
  2001a50:  167cdbaf  load     0, 7c, lr91, lr47       
L_2001a54:
  2001a54:  887cbbdc  iret                             
  2001a58:  811cfb70  sll      gr28, lr123, $70           ; [delay slot]
L_2001a5c:
  2001a5c:  887cb4d0  iret                             
  2001a60:  0183d552  constn   lr85, $8352                ; [delay slot]
  2001a64:  887cb690  iret                             
  2001a68:  0183d76e  constn   lr87, $836e                ; [delay slot]
  2001a6c:  887cb75c  iret                             
  2001a70:  1506c9a0  add      gr6, lr73, $a0             ; [delay slot]
  2001a74:  037dc981  const    lr73, $7d81             
  2001a78:  6005ca9d  cpeq     gr5, lr74, lr29         
  2001a7c:  a47cc931  jmpf     lr73, $2020b40          
  2001a80:  703cb0c9  aseq     trap60, lr48, lr73         ; [delay slot]
  2001a84:  153a309f  add      gr58, gr48, $9f         
  2001a88:  9d3af413  andn     gr58, lr116, $13        
  2001a8c:  151cf370  add      gr28, lr115, $70        
  2001a90:  034cf604  const    lr118, $4c04            
L_2001a94:
  2001a94:  027ce9b0  consth   lr105, $7cb0            
  2001a98:  2438d39d  sub      gr56, lr83, lr29        
  2001a9c:  143fed5a  add      gr63, lr109, gr90       
  2001aa0:  4e39eec4  cpgeu    gr57, lr110, lr68       
  2001aa4:  ac7ce864  jmpt     lr104, $2020c34         
  2001aa8:  703cafe5  aseq     trap60, lr47, lr101        ; [delay slot]
  2001aac:  143def86  add      gr61, lr111, lr6        
  2001ab0:  887cae68  iret                             
  2001ab4:  037ccfdc  const    lr79, $7cdc                ; [delay slot]
  2001ab8:  037cd1fc  const    lr81, $7cfc             
  2001abc:  887ca850  iret                             
L_2001ac0:
  2001ac0:  037dd086  const    lr80, $7d86                ; [delay slot]
  2001ac4:  6005d369  cpeq     gr5, lr83, gr105        
  2001ac8:  a47cd330  jmpf     lr83, $2020b88          
L_2001acc:
  2001acc:  0318e94c  const    lr105, $184c               ; [delay slot]
  2001ad0:  0230e820  consth   lr104, $3020            
  2001ad4:  167cef43  load     0, 7c, lr111, gr67      
  2001ad8:  423f26a0  cpltu    gr63, gr38, lr32        
  2001adc:  ac7ce6a2  jmpt     lr102, $2020d64         
  2001ae0:  037cc548  const    lr69, $7c48                ; [delay slot]
  2001ae4:  887ca69c  iret                             
  2001ae8:  037ddf93  const    lr95, $7d93                ; [delay slot]
  2001aec:  6005dc89  cpeq     gr5, lr92, lr9          
  2001af0:  a47cdf07  jmpf     lr95, $2020b0c          
  2001af4:  0378c730  const    lr71, $7830                ; [delay slot]
  2001af8:  887ca758  iret                             
  2001afc:  037dd93d  const    lr89, $7d3d                ; [delay slot]
  2001b00:  6005da79  cpeq     gr5, lr90, gr121        
  2001b04:  a47cd8ef  jmpf     lr88, $2020ec0          
  2001b08:  703ca3e5  aseq     trap60, lr35, lr101        ; [delay slot]
  2001b0c:  037cc240  const    lr66, $7c40             
  2001b10:  610521a8  cpeq     gr5, gr33, $a8          
  2001b14:  a47cdad8  jmpf     lr90, $2020e74          
  2001b18:  703ca271  aseq     trap60, lr34, gr113        ; [delay slot]
  2001b1c:  15201fd0  add      gr32, gr31, $d0         
  2001b20:  887c9d84  iret                             
  2001b24:  61051cd1  cpeq     gr5, gr28, $d1             ; [delay slot]
  2001b28:  a47ce6bc  jmpf     lr102, $2020e18         
  2001b2c:  703c9e5d  aseq     trap60, lr30, gr93         ; [delay slot]
  2001b30:  15211ba0  add      gr33, gr27, $a0         
  2001b34:  887c9880  iret                             
L_2001b38:
  2001b38:  017cf8e5  constn   lr120, $7ce5               ; [delay slot]
  2001b3c:  887c9820  iret                             
  2001b40:  037de0cc  const    lr96, $7dcc                ; [delay slot]
  2001b44:  6005e0e5  cpeq     gr5, lr96, lr101        
  2001b48:  a47ce314  jmpf     lr99, $2020b98          
  2001b4c:  0304fa70  const    lr122, $0470               ; [delay slot]
  2001b50:  0230fb04  consth   lr123, $3004            
  2001b54:  887c94b0  iret                             
  2001b58:  037dd7c9  const    lr87, $7dc9                ; [delay slot]
  2001b5c:  6005ee5f  cpeq     gr5, lr110, gr95        
  2001b60:  a47cec85  jmpf     lr108, $2020d74         
  2001b64:  0314d250  const    lr82, $1450                ; [delay slot]
  2001b68:  0230d1e4  consth   lr81, $30e4             
L_2001b6c:
  2001b6c:  167cf687  load     0, 7c, lr118, lr7       
  2001b70:  887c9668  iret                             
  2001b74:  037dd4ce  const    lr84, $7dce                ; [delay slot]
  2001b78:  6005eab3  cpeq     gr5, lr106, lr51        
  2001b7c:  a47ce941  jmpf     lr105, $2020c80         
  2001b80:  0314d6b0  const    lr86, $14b0                ; [delay slot]
  2001b84:  0230d610  consth   lr86, $3010             
  2001b88:  167cd57f  load     0, 7c, lr85, gr127      
  2001b8c:  0309da6c  const    lr90, $096c             
  2001b90:  c6359b20  mfsr     gr53, spr155            
  2001b94:  2435db49  sub      gr53, lr91, gr73        
  2001b98:  141cc5a3  add      gr28, lr69, lr35        
  2001b9c:  153bcaa4  add      gr59, lr74, $a4         
  2001ba0:  167cec0f  load     0, 7c, lr108, gr15      
  2001ba4:  c6370a9c  mfsr     gr55, PC0               
  2001ba8:  8137c588  sll      gr55, lr69, $88         
  2001bac:  a47cc5f3  jmpf     lr69, $2020f78          
  2001bb0:  703c8f05  aseq     trap60, lr15, gr5          ; [delay slot]
L_2001bb4:
  2001bb4:  887c8f30  iret                             
  2001bb8:  151dee59  add      gr29, lr110, $59           ; [delay slot]
  2001bbc:  887c881c  iret                             
  2001bc0:  813bc814  sll      gr59, lr72, $14            ; [delay slot]
  2001bc4:  a47ccee3  jmpf     lr78, $2020f50          
  2001bc8:  703c8be5  aseq     trap60, lr11, lr101        ; [delay slot]
  2001bcc:  887c8a40  iret                             
  2001bd0:  a87ecd48  call     lr77, $20214f0             ; [delay slot]
  2001bd4:  1531f1dc  add      gr49, lr113, $dc           ; [delay slot]
  2001bd8:  037cf271  const    lr114, $7c71            
  2001bdc:  6005fea9  cpeq     gr5, lr126, lr41        
  2001be0:  a47cfc94  jmpf     lr124, $2020e30         
  2001be4:  030fce88  const    lr78, $0f88                ; [delay slot]
  2001be8:  0230cfb8  consth   lr79, $30b8             
  2001bec:  033ec01e  const    lr64, $3e1e             
  2001bf0:  023ec7f3  consth   lr71, $3ef3             
L_2001bf4:
  2001bf4:  1e7cc7c8  store    0, 7c, lr71, lr72       
  2001bf8:  037cc7e5  const    lr71, $7ce5             
  2001bfc:  0316c87c  const    lr72, $167c             
  2001c00:  0230c9c8  consth   lr73, $30c8             
  2001c04:  1e7cc5d4  store    0, 7c, lr69, lr84       
  2001c08:  0316ca70  const    lr74, $1670             
  2001c0c:  0230ca70  consth   lr74, $3070             
  2001c10:  c63b8904  mfsr     gr59, spr137            
  2001c14:  1e7cbbf8  store    0, 7c, lr59, lr120      
  2001c18:  a07cfcd8  jmp      $2020f78                
L_2001c1c:
  2001c1c:  703cfd1d  aseq     trap60, lr125, gr29        ; [delay slot]
  2001c20:  6005bac7  cpeq     gr5, lr58, lr71         
  2001c24:  151cba60  add      gr28, lr58, $60         
  2001c28:  887cfee4  iret                             
  2001c2c:  813fbec4  sll      gr63, lr62, $c4            ; [delay slot]
  2001c30:  c47cbd2d  jmpfi    lr61, gr45              
  2001c34:  037fbc23  const    lr60, $7f23                ; [delay slot]
  2001c38:  903fa3b3  and      gr63, lr35, lr51        
L_2001c3c:
  2001c3c:  8330be4c  srl      gr48, lr62, $4c         
  2001c40:  1530b594  add      gr48, lr53, $94         
  2001c44:  037ca811  const    lr40, $7c11             
  2001c48:  8030ab74  sll      gr48, lr43, gr116       
  2001c4c:  9030b607  and      gr48, lr54, gr7         
  2001c50:  6130b720  cpeq     gr48, lr55, $20         
  2001c54:  cc7cb745  jmpti    lr55, gr69              
  2001c58:  037fb81b  const    lr56, $7f1b                ; [delay slot]
  2001c5c:  902db3ec  and      gr45, lr51, lr108       
  2001c60:  9c3ab304  andn     gr58, lr51, gr4         
  2001c64:  034dbef0  const    lr62, $4df0             
  2001c68:  0230be90  consth   lr62, $3090             
L_2001c6c:
  2001c6c:  c637f4f0  mfsr     gr55, spr244            
  2001c70:  0478f47b  mtsrim   spr244, $787b           
  2001c74:  253fb431  sub      gr63, lr52, $31         
  2001c78:  ac7cb478  jmpt     lr52, $2020e58          
  2001c7c:  703cf11d  aseq     trap60, lr113, gr29        ; [delay slot]
  2001c80:  167cb948  load     0, 7c, lr57, gr72       
  2001c84:  1534b9e4  add      gr52, lr57, $e4         
  2001c88:  6030b4ad  cpeq     gr48, lr52, lr45        
  2001c8c:  ac7cbe50  jmpt     lr62, $2020dcc          
  2001c90:  4230b5a1  cpltu    gr48, lr53, lr33           ; [delay slot]
  2001c94:  ac7cbfdb  jmpt     lr63, $2021000          
  2001c98:  703cf271  aseq     trap60, lr114, gr113       ; [delay slot]
  2001c9c:  167ca698  load     0, 7c, lr38, lr24       
  2001ca0:  1436a4ce  add      gr54, lr36, lr78        
  2001ca4:  4230a8da  cpltu    gr48, lr40, lr90        
  2001ca8:  ac7ca3bc  jmpt     lr35, $2020f98          
  2001cac:  2435a915  sub      gr53, lr41, gr21           ; [delay slot]
  2001cb0:  a083e851  jmp      $1fe29f4                
  2001cb4:  1534a088  add      gr52, lr32, $88            ; [delay slot]
  2001cb8:  2436a2a2  sub      gr54, lr34, lr34        
  2001cbc:  1534a024  add      gr52, lr32, $24         
  2001cc0:  167caf80  load     0, 7c, lr47, lr0        
  2001cc4:  a07cea99  jmp      $2020f28                
  2001cc8:  143aac59  add      gr58, lr44, gr89           ; [delay slot]
  2001ccc:  167ca038  load     0, 7c, lr32, gr56       
  2001cd0:  1534a300  add      gr52, lr35, $00         
  2001cd4:  167ca2f8  load     0, 7c, lr34, lr120      
  2001cd8:  2436ae89  sub      gr54, lr46, lr9         
  2001cdc:  4630a356  cpleu    gr48, lr35, gr86        
  2001ce0:  ac7ca983  jmpt     lr41, $2020eec          
  2001ce4:  703ce461  aseq     trap60, lr100, gr97        ; [delay slot]
  2001ce8:  813bace4  sll      gr59, lr44, $e4         
L_2001cec:
  2001cec:  ce7ce48b  mtsr     spr228, lr11            
  2001cf0:  c07ce62d  jmpi     gr45                    
  2001cf4:  923aa18d  or       gr58, lr33, lr13           ; [delay slot]
  2001cf8:  ce7ce2bb  mtsr     spr226, lr59            
  2001cfc:  923aa601  or       gr58, lr38, gr1         
  2001d00:  c07ce1c1  jmpi     lr65                    
  2001d04:  037ca610  const    lr38, $7c10                ; [delay slot]
  2001d08:  a07ee2f8  jmp      $20218e8                
  2001d0c:  037cafff  const    lr47, $7cff                ; [delay slot]
  2001d10:  0354ab30  const    lr43, $5430             
  2001d14:  0230ab00  consth   lr43, $3000             
  2001d18:  167c9bac  load     0, 7c, lr27, lr44       
  2001d1c:  ac7c9a99  jmpt     lr26, $2020f80          
  2001d20:  037c9648  const    lr22, $7c48                ; [delay slot]
  2001d24:  03509934  const    lr25, $5034             
  2001d28:  02309990  consth   lr25, $3090             
  2001d2c:  813495f2  sll      gr52, lr21, $f2         
  2001d30:  1434994c  add      gr52, lr25, gr76        
  2001d34:  167c9878  load     0, 7c, lr24, gr120      
  2001d38:  ac7c9872  jmpt     lr24, $2020f00          
  2001d3c:  018391e3  constn   lr17, $83e3                ; [delay slot]
  2001d40:  1e7c9148  store    0, 7c, lr17, gr72       
  2001d44:  037c90e0  const    lr16, $7ce0             
  2001d48:  813491e6  sll      gr52, lr17, $e6         
  2001d4c:  1434920b  add      gr52, lr18, gr11        
  2001d50:  813493ea  sll      gr52, lr19, $ea         
  2001d54:  03549c44  const    lr28, $5444             
  2001d58:  02309c70  consth   lr28, $3070             
  2001d5c:  14369398  add      gr54, lr19, lr24        
  2001d60:  153b9f88  add      gr59, lr31, $88         
  2001d64:  1e7c9fd7  store    0, 7c, lr31, lr87       
  2001d68:  633b9bb8  cpneq    gr59, lr27, $b8         
  2001d6c:  ac7c9055  jmpt     lr16, $2020ec0          
  2001d70:  153b9ab0  add      gr59, lr26, $b0            ; [delay slot]
  2001d74:  1e7c99c7  store    0, 7c, lr25, lr71       
  2001d78:  813b9de6  sll      gr59, lr29, $e6         
  2001d7c:  03549838  const    lr24, $5438             
  2001d80:  023099c8  consth   lr25, $30c8             
  2001d84:  143b9adb  add      gr59, lr26, lr91        
  2001d88:  a07cd215  jmp      $2020ddc                
  2001d8c:  1e7c9837  store    0, 7c, lr24, gr55          ; [delay slot]
  2001d90:  1e7c9f43  store    0, 7c, lr31, gr67       
  2001d94:  153b80bc  add      gr59, lr0, $bc          
  2001d98:  1e7c869f  store    0, 7c, lr6, lr31        
  2001d9c:  1530861c  add      gr48, lr6, $1c          
  2001da0:  03528ac8  const    lr10, $52c8             
  2001da4:  02308a60  consth   lr10, $3060             
  2001da8:  167c89a3  load     0, 7c, lr9, lr35        
L_2001dac:
  2001dac:  813485ca  sll      gr52, lr5, $ca          
  2001db0:  143f8920  add      gr63, lr9, gr32         
  2001db4:  1e7c8b90  store    0, 7c, lr11, lr16       
  2001db8:  153584f4  add      gr53, lr4, $f4          
  2001dbc:  1e7c8b19  store    0, 7c, lr11, gr25       
  2001dc0:  153b858c  add      gr59, lr5, $8c          
  2001dc4:  1e7c8457  store    0, 7c, lr4, gr87        
  2001dc8:  8134813a  sll      gr52, lr1, $3a          
  2001dcc:  03518d24  const    lr13, $5124             
  2001dd0:  02308c20  consth   lr12, $3020             
  2001dd4:  143b8c48  add      gr59, lr12, gr72        
  2001dd8:  a07cc486  jmp      $2020ff0                
  2001ddc:  1e7c89e7  store    0, 7c, lr9, lr103          ; [delay slot]
  2001de0:  15378e49  add      gr55, lr14, $49         
  2001de4:  413b8da8  cplt     gr59, lr13, $a8         
  2001de8:  ac83815f  jmpt     lr1, $1fe2b64           
  2001dec:  703cc7f1  aseq     trap60, lr71, lr113        ; [delay slot]
  2001df0:  018381fb  constn   lr1, $83fb              
  2001df4:  03548f20  const    lr15, $5420             
  2001df8:  02308f58  consth   lr15, $3058             
  2001dfc:  1e7c8754  store    0, 7c, lr7, gr84        
  2001e00:  c63bc800  mfsr     gr59, spr200            
  2001e04:  94354360  xor      gr53, gr67, gr96        
  2001e08:  943b8528  xor      gr59, lr5, gr40         
  2001e0c:  243b8541  sub      gr59, lr5, gr65         
  2001e10:  943b8aaf  xor      gr59, lr10, lr47        
  2001e14:  037c8be3  const    lr11, $7ce3             
  2001e18:  90348438  and      gr52, lr4, gr56         
  2001e1c:  253b74dc  sub      gr59, gr116, $dc        
  2001e20:  ac837a7e  jmpt     gr122, $1fe2c18         
  2001e24:  153577a5  add      gr53, gr119, $a5           ; [delay slot]
  2001e28:  833477b9  srl      gr52, gr119, $b9        
  2001e2c:  8134785e  sll      gr52, gr120, $5e        
  2001e30:  03517fd8  const    gr127, $51d8            
  2001e34:  02307f80  consth   gr127, $3080            
  2001e38:  143b7fac  add      gr59, gr127, lr44       
  2001e3c:  167c7267  load     0, 7c, gr114, gr103     
  2001e40:  603b7384  cpeq     gr59, gr115, lr4        
  2001e44:  ac837d6d  jmpt     gr125, $1fe2bf8         
  2001e48:  153b733a  add      gr59, gr115, $3a           ; [delay slot]
  2001e4c:  153b7060  add      gr59, gr112, $60        
  2001e50:  167c7343  load     0, 7c, gr115, gr67      
  2001e54:  613b7cb0  cpeq     gr59, gr124, $b0        
  2001e58:  ac7c73de  jmpt     gr115, $20211d0         
  2001e5c:  153b7e10  add      gr59, gr126, $10           ; [delay slot]
  2001e60:  167c7cc7  load     0, 7c, gr124, lr71      
  2001e64:  153b7d6c  add      gr59, gr125, $6c        
  2001e68:  a07c36ea  jmp      $2021210                
  2001e6c:  1e7c7f87  store    0, 7c, gr127, lr7          ; [delay slot]
  2001e70:  153b7c60  add      gr59, gr124, $60        
  2001e74:  167c709b  load     0, 7c, gr112, lr27      
  2001e78:  035478e8  const    gr120, $54e8            
  2001e7c:  02307850  consth   gr120, $3050            
  2001e80:  813b7686  sll      gr59, gr118, $86        
  2001e84:  14347658  add      gr52, gr118, gr88       
  2001e88:  167c7570  load     0, 7c, gr117, gr112     
  2001e8c:  623b7516  cpneq    gr59, gr117, gr22       
  2001e90:  ac7c7424  jmpt     gr116, $2020f20         
  2001e94:  153b790c  add      gr59, gr121, $0c           ; [delay slot]
  2001e98:  167c65a3  load     0, 7c, gr101, lr35      
  2001e9c:  1e7c64e8  store    0, 7c, gr100, lr104     
  2001ea0:  153b6744  add      gr59, gr103, $44        
  2001ea4:  167c67db  load     0, 7c, gr103, lr91      
  2001ea8:  613b6790  cpeq     gr59, gr103, $90        
  2001eac:  ac7c69f5  jmpt     gr105, $2021280         
  2001eb0:  153b6414  add      gr59, gr100, $14           ; [delay slot]
  2001eb4:  167c6777  load     0, 7c, gr103, gr119     
L_2001eb8:
  2001eb8:  153b6648  add      gr59, gr102, $48        
  2001ebc:  1e7c605b  store    0, 7c, gr96, gr91       
  2001ec0:  153b6210  add      gr59, gr98, $10         
  2001ec4:  1e7c65a7  store    0, 7c, gr101, lr39      
  2001ec8:  037c63e4  const    gr99, $7ce4             
  2001ecc:  153b604c  add      gr59, gr96, $4c         
  2001ed0:  1e7c62af  store    0, 7c, gr98, lr47       
  2001ed4:  613b67dc  cpeq     gr59, gr103, $dc        
  2001ed8:  ac7c6c74  jmpt     gr108, $20210a8         
  2001edc:  153b68dc  add      gr59, gr104, $dc           ; [delay slot]
  2001ee0:  a07c2583  jmp      $20210ec                
  2001ee4:  1e7c6cd7  store    0, 7c, gr108, lr87         ; [delay slot]
  2001ee8:  813b6aba  sll      gr59, gr106, $ba        
  2001eec:  03546f44  const    gr111, $5444            
  2001ef0:  023068a0  consth   gr104, $30a0            
  2001ef4:  143b68c7  add      gr59, gr104, lr71       
  2001ef8:  1e7c6aa3  store    0, 7c, gr106, lr35      
  2001efc:  03fc6b20  const    gr107, $fc20            
  2001f00:  02836a37  consth   gr106, $8337            
  2001f04:  167c6bd6  load     0, 7c, gr107, lr86      
  2001f08:  90356b5b  and      gr53, gr107, gr91       
  2001f0c:  153b6878  add      gr59, gr104, $78        
  2001f10:  167c6b43  load     0, 7c, gr107, gr67      
  2001f14:  813454b1  sll      gr52, gr84, $b1         
  2001f18:  b63b54d8  mftlb    gr59, gr84              
  2001f1c:  903b5b57  and      gr59, gr91, gr87        
  2001f20:  603b5ac9  cpeq     gr59, gr90, lr73        
  2001f24:  a47c5a63  jmpf     gr90, $20210b0          
  2001f28:  037c59e4  const    gr89, $7ce4                ; [delay slot]
  2001f2c:  be7c5687  mttlb    gr86, lr7               
  2001f30:  15345628  add      gr52, gr86, $28         
  2001f34:  b63b57dc  mftlb    gr59, gr87              
  2001f38:  903b5fbb  and      gr59, gr95, lr59        
  2001f3c:  603b5f19  cpeq     gr59, gr95, gr25        
  2001f40:  a47c5e87  jmpf     gr94, $202115c          
  2001f44:  037c5e10  const    gr94, $7c10                ; [delay slot]
  2001f48:  be7c527f  mttlb    gr82, gr127             
  2001f4c:  1e7c5e16  store    0, 7c, gr94, gr22       
  2001f50:  153b5128  add      gr59, gr81, $28         
  2001f54:  1e7c5647  store    0, 7c, gr86, gr71       
  2001f58:  15355ee0  add      gr53, gr94, $e0         
  2001f5c:  167c56e9  load     0, 7c, gr86, lr105      
  2001f60:  038344b7  const    gr68, $83b7             
  2001f64:  02734763  consth   gr71, $7363             
  2001f68:  902d52c1  and      gr45, gr82, lr65        
  2001f6c:  037c5ff0  const    gr95, $7cf0             
  2001f70:  02305f04  consth   gr95, $3004             
L_2001f74:
  2001f74:  92354679  or       gr53, gr70, gr121       
  2001f78:  037c4658  const    gr70, $7c58             
  2001f7c:  037c5c90  const    gr92, $7c90             
  2001f80:  02385c00  consth   gr92, $3800             
  2001f84:  1e7c40ac  store    0, 7c, gr64, lr44       
  2001f88:  c62614e4  mfsr     gr38, spr20             
  2001f8c:  0352570c  const    gr87, $520c             
  2001f90:  023056e8  consth   gr86, $30e8             
  2001f94:  047c94c3  mtsrim   spr148, $7cc3           
  2001f98:  3e7c9335  storem   0, 7c, lr19, gr53       
  2001f9c:  01835d2f  constn   gr93, $832f             
  2001fa0:  037c410c  const    gr65, $7c0c             
  2001fa4:  02384290  consth   gr66, $3890             
  2001fa8:  1e7c5ef4  store    0, 7c, gr94, lr116      
  2001fac:  252d4c58  sub      gr45, gr76, $58         
  2001fb0:  1e7c4bf1  store    0, 7c, gr75, lr113      
  2001fb4:  037c4e00  const    gr78, $7c00             
  2001fb8:  037c59e2  const    gr89, $7ce2             
  2001fbc:  047c8f3f  mtsrim   spr143, $7c3f           
  2001fc0:  367c8981  loadm    0, 7c, lr9, lr1         
  2001fc4:  b4835b62  jmpfdec  gr91, $1fe2d4c          
  2001fc8:  14354356  add      gr53, gr67, gr86           ; [delay slot]
  2001fcc:  037c5b70  const    gr91, $7c70             
  2001fd0:  1e7c5a48  store    0, 7c, gr90, gr72       
  2001fd4:  047c83af  mtsrim   Q, $7caf                
  2001fd8:  367c849d  loadm    0, 7c, lr4, lr29        
  2001fdc:  ce7c0246  mtsr     CPS, gr70               
  2001fe0:  812d4598  sll      gr45, gr69, $98         
  2001fe4:  9a2d5431  nand     gr45, gr84, gr49        
  2001fe8:  037c4a68  const    gr74, $7c68             
  2001fec:  02384ac0  consth   gr74, $38c0             
  2001ff0:  1e7c5724  store    0, 7c, gr87, gr36       
  2001ff4:  a0850762  jmp      $1fe357c                
L_2001ff8:
  2001ff8:  703c01f1  aseq     trap60, gr1, lr113         ; [delay slot]
  2001ffc:  047c0380  mtsrim   CFG, $7c80              
  2002000:  047803fb  mtsrim   CFG, $78fb              
  2002004:  03184208  const    gr66, $1808             
L_2002008:
  2002008:  02304138  consth   gr65, $3038             
  200200c:  167c421f  load     0, 7c, gr66, gr31       
  2002010:  037c4520  const    gr69, $7c20             
  2002014:  018344ff  constn   gr68, $83ff             
  2002018:  037c34b4  const    gr52, $7cb4             
  200201c:  023835a0  consth   gr53, $38a0             
  2002020:  1e7c3b00  store    0, 7c, gr59, gr0        
  2002024:  037c36c8  const    gr54, $7cc8             
  2002028:  02383690  consth   gr54, $3890             
  200202c:  1e7c38b8  store    0, 7c, gr56, lr56       
  2002030:  037c2504  const    gr37, $7c04             
  2002034:  037c3730  const    gr55, $7c30             
  2002038:  02743758  consth   gr55, $7458             
  200203c:  9c3c3854  andn     gr60, gr56, gr84        
  2002040:  034d3068  const    gr48, $4d68             
  2002044:  023031e0  consth   gr49, $30e0             
  2002048:  1e7c3cac  store    0, 7c, gr60, lr44       
  200204c:  031d323c  const    gr50, $1d3c             
  2002050:  023033e8  consth   gr51, $30e8             
  2002054:  1e7c3d94  store    0, 7c, gr61, lr20       
  2002058:  15343374  add      gr52, gr51, $74         
  200205c:  1e7c3298  store    0, 7c, gr50, lr24       
  2002060:  15343d80  add      gr52, gr61, $80         
  2002064:  1e7c30d8  store    0, 7c, gr48, lr88       
  2002068:  15343fbc  add      gr52, gr63, $bc         
  200206c:  1e7c3114  store    0, 7c, gr49, gr20       
  2002070:  153438a4  add      gr52, gr56, $a4         
  2002074:  1e7c36c8  store    0, 7c, gr54, lr72       
  2002078:  031438d4  const    gr56, $14d4             
  200207c:  02303820  consth   gr56, $3020             
  2002080:  037d38fc  const    gr56, $7dfc             
  2002084:  1e7c34d4  store    0, 7c, gr52, lr84       
  2002088:  b4833bef  jmpfdec  gr59, $1fe3044          
  200208c:  15343a74  add      gr52, gr58, $74            ; [delay slot]
  2002090:  03143b38  const    gr59, $1438             
  2002094:  023024b0  consth   gr36, $30b0             
  2002098:  1e7c2b90  store    0, 7c, gr43, lr16       
  200209c:  037c25be  const    gr37, $7cbe             
  20020a0:  031625dc  const    gr37, $16dc             
  20020a4:  02302560  consth   gr37, $3060             
  20020a8:  1e7c27ac  store    0, 7c, gr39, lr44       
  20020ac:  031b2614  const    gr38, $1b14             
  20020b0:  02302668  consth   gr38, $3068             
  20020b4:  1e7c2994  store    0, 7c, gr41, lr20       
  20020b8:  030f20f0  const    gr32, $0ff0             
  20020bc:  02302050  consth   gr32, $3050             
  20020c0:  1e7c2fcc  store    0, 7c, gr47, lr76       
  20020c4:  030f2114  const    gr33, $0f14             
L_20020c8:
  20020c8:  02302238  consth   gr34, $3038             
  20020cc:  1e7c2d14  store    0, 7c, gr45, gr20       
  20020d0:  034d2240  const    gr34, $4d40             
  20020d4:  022b2259  consth   gr34, $2b59             
  20020d8:  030f2cfc  const    gr44, $0ffc             
  20020dc:  02302da0  consth   gr45, $30a0             
  20020e0:  1e7c2c00  store    0, 7c, gr44, gr0        
  20020e4:  030f2e80  const    gr46, $0f80             
  20020e8:  02302e90  consth   gr46, $3090             
  20020ec:  1e7c20b8  store    0, 7c, gr32, lr56       
  20020f0:  03182020  const    gr32, $1820             
  20020f4:  02302130  consth   gr33, $3030             
  20020f8:  167c201e  load     0, 7c, gr32, gr30       
  20020fc:  03182630  const    gr38, $1830             
  2002100:  02302600  consth   gr38, $3000             
L_2002104:
  2002104:  167c29a6  load     0, 7c, gr41, lr38       
  2002108:  031824c4  const    gr36, $18c4             
  200210c:  02302440  consth   gr36, $3040             
  2002110:  167c2aae  load     0, 7c, gr42, lr46       
  2002114:  031825f4  const    gr37, $18f4             
L_2002118:
  2002118:  02302570  consth   gr37, $3070             
  200211c:  167c1696  load     0, 7c, gr22, lr22       
  2002120:  143514ce  add      gr53, gr20, lr78        
  2002124:  83341692  srl      gr52, gr22, $92         
  2002128:  253417ba  sub      gr52, gr23, $ba         
L_200212c:
  200212c:  167c191b  load     0, 7c, gr25, gr27       
  2002130:  153b1fa4  add      gr59, gr31, $a4         
  2002134:  1e7c1ec9  store    0, 7c, gr30, lr73       
  2002138:  b4831019  jmpfdec  gr16, $1fe2d9c          
  200213c:  15351124  add      gr53, gr17, $24            ; [delay slot]
  2002140:  03181ff8  const    gr31, $18f8             
  2002144:  02301c9c  consth   gr28, $309c             
  2002148:  167c1256  load     0, 7c, gr18, gr86       
  200214c:  83341272  srl      gr52, gr18, $72         
  2002150:  25341306  sub      gr52, gr19, $06         
  2002154:  037c12b0  const    gr18, $7cb0             
L_2002158:
  2002158:  1e7c1291  store    0, 7c, gr18, lr17       
  200215c:  b4831ce3  jmpfdec  gr28, $1fe30e8          
  2002160:  15351c84  add      gr53, gr28, $84            ; [delay slot]
  2002164:  047c525f  mtsrim   spr82, $7c5f            
  2002168:  03740488  const    gr4, $7488              
  200216c:  037c10c0  const    gr16, $7cc0             
  2002170:  037c11fc  const    gr17, $7cfc             
  2002174:  023810dc  consth   gr16, $38dc             
  2002178:  167c18b7  load     0, 7c, gr24, lr55       
  200217c:  a47c1853  jmpf     gr24, $20212c8          
  2002180:  153b1680  add      gr59, gr22, $80            ; [delay slot]
  2002184:  933a1711  or       gr58, gr23, $11         
  2002188:  813a1439  sll      gr58, gr20, $39         
  200218c:  167c1a1b  load     0, 7c, gr26, gr27       
L_2002190:
  2002190:  a47c1b23  jmpf     gr27, $202121c          
  2002194:  153b1404  add      gr59, gr20, $04            ; [delay slot]
  2002198:  933a0ae5  or       gr58, gr10, $e5         
L_200219c:
  200219c:  813a0ba1  sll      gr58, gr11, $a1         
  20021a0:  167c050f  load     0, 7c, gr5, gr15        
  20021a4:  a47c069f  jmpf     gr6, $2021420           
  20021a8:  703c4f91  aseq     trap60, gr79, lr17         ; [delay slot]
  20021ac:  933a08f1  or       gr58, gr8, $f1          
  20021b0:  61350804  cpeq     gr53, gr8, $04          
  20021b4:  a47c0634  jmpf     gr6, $2021284           
  20021b8:  037d0658  const    gr6, $7d58                 ; [delay slot]
  20021bc:  027c011c  consth   gr1, $7c1c              
  20021c0:  9c3c0849  andn     gr60, gr8, gr73         
  20021c4:  031400e4  const    gr0, $14e4              
  20021c8:  023003e4  consth   gr3, $30e4              
  20021cc:  167c0009  load     0, 7c, gr0, gr9         
  20021d0:  81370df0  sll      gr55, gr13, $f0         
  20021d4:  92360197  or       gr54, gr1, lr23         
  20021d8:  037c0d70  const    gr13, $7c70             
  20021dc:  023a02d0  consth   gr2, $3ad0              
  20021e0:  167c03c2  load     0, 7c, gr3, lr66        
  20021e4:  833a009c  srl      gr58, gr0, $9c          
L_20021e8:
  20021e8:  813a01a4  sll      gr58, gr1, $a4          
  20021ec:  92360d1a  or       gr54, gr13, gr26        
  20021f0:  1e7c0ae9  store    0, 7c, gr10, lr105      
  20021f4:  833a069c  srl      gr58, gr6, $9c          
  20021f8:  4d3706e5  cpge     gr55, gr6, $e5          
  20021fc:  a47c0b24  jmpf     gr11, $202128c          
  2002200:  037c0ac8  const    gr10, $7cc8                ; [delay slot]
  2002204:  025c099c  consth   gr9, $5c9c              
L_2002208:
  2002208:  923c025b  or       gr60, gr2, gr91         
  200220c:  03090440  const    gr4, $0940              
  2002210:  027c0504  consth   gr5, $7c04              
  2002214:  8138fcbc  sll      gr56, lr124, $bc        
L_2002218:
  2002218:  ac7df9dd  jmpt     lr121, $202198c         
  200221c:  ce7db55a  mtsr     spr181, gr90               ; [delay slot]
  2002220:  0308fbb0  const    lr123, $08b0            
  2002224:  027cfb60  consth   lr123, $7c60            
  2002228:  ce7db7a2  mtsr     spr183, lr34            
  200222c:  047db6c0  mtsrim   spr182, $7dc0           
  2002230:  c63abd68  mfsr     gr58, spr189            
  2002234:  9d3af8d8  andn     gr58, lr120, $d8        
  2002238:  8138f8fd  sll      gr56, lr120, $fd        
  200223c:  ac7dfd53  jmpt     lr125, $2021788         
  2002240:  703db885  aseq     trap61, lr56, lr5          ; [delay slot]
  2002244:  933afe30  or       gr58, lr126, $30        
  2002248:  8335fd20  srl      gr53, lr125, $20        
  200224c:  4d35f25e  cpge     gr53, lr114, $5e        
  2002250:  a47df324  jmpf     lr115, $20216e0         
  2002254:  8134fb1f  sll      gr52, lr123, $1f           ; [delay slot]
L_2002258:
  2002258:  ac7dfde7  jmpt     lr125, $20219f4         
  200225c:  703db4a1  aseq     trap61, lr52, lr33         ; [delay slot]
  2002260:  933af249  or       gr58, lr114, $49        
  2002264:  9f7db69c  inv                              
  2002268:  8138f68c  sll      gr56, lr118, $8c        
  200226c:  a47df3f4  jmpf     lr115, $2021a3c         
  2002270:  703db705  aseq     trap61, lr55, gr5          ; [delay slot]
  2002274:  a07db73c  jmp      $2021764                
  2002278:  933af05a  or       gr58, lr112, $5a           ; [delay slot]
  200227c:  8138f002  sll      gr56, lr112, $02        
  2002280:  a47df509  jmpf     lr117, $20216a4         
L_2002284:
  2002284:  9d3af6e2  andn     gr58, lr118, $e2           ; [delay slot]
  2002288:  933af5e6  or       gr58, lr117, $e6        
  200228c:  ce7db107  mtsr     spr177, gr7             
  2002290:  0375fdc8  const    lr125, $75c8            
  2002294:  0272fd1c  consth   lr125, $721c            
L_2002298:
  2002298:  036efc05  const    lr124, $6e05            
  200229c:  027de3d0  consth   lr99, $7dd0             
  20022a0:  1e9ee3cb  store    1, 1e, lr99, lr75       
  20022a4:  ce7dadd7  mtsr     spr173, lr87            
  20022a8:  8138efad  sll      gr56, lr111, $ad        
  20022ac:  a47dea5f  jmpf     lr106, $2021828         
  20022b0:  035deba0  const    lr107, $5da0               ; [delay slot]
  20022b4:  922ffac3  or       gr47, lr122, lr67       
  20022b8:  8138e8ea  sll      gr56, lr104, $ea        
  20022bc:  a47ded23  jmpf     lr109, $2021748         
  20022c0:  703da8c9  aseq     trap61, lr40, lr73         ; [delay slot]
  20022c4:  932ff89e  or       gr47, lr120, $9e        
L_20022c8:
  20022c8:  8138ea1a  sll      gr56, lr106, $1a        
  20022cc:  a47def73  jmpf     lr111, $2021898         
  20022d0:  703daa05  aseq     trap61, lr42, gr5          ; [delay slot]
  20022d4:  932ff6a0  or       gr47, lr118, $a0        
  20022d8:  8138e4cf  sll      gr56, lr100, $cf        
  20022dc:  a47de11b  jmpf     lr97, $2021748          
  20022e0:  0375ec80  const    lr108, $7580               ; [delay slot]
  20022e4:  9c2ff729  andn     gr47, lr119, gr41       
  20022e8:  037defb8  const    lr111, $7db8            
  20022ec:  0239efc0  consth   lr111, $39c0            
  20022f0:  0182ea97  constn   lr106, $8297            
  20022f4:  1e7deb95  store    0, 7d, lr107, lr21      
  20022f8:  8134e0e8  sll      gr52, lr96, $e8         
  20022fc:  9a34e919  nand     gr52, lr105, gr25       
  2002300:  037ded08  const    lr109, $7d08            
  2002304:  0239ed10  consth   lr109, $3910            
  2002308:  1e7deb74  store    0, 7d, lr107, gr116     
  200230c:  8134e245  sll      gr52, lr98, $45         
  2002310:  9a34ea69  nand     gr52, lr106, gr105      
  2002314:  037def90  const    lr111, $7d90            
  2002318:  0239d0e4  consth   lr80, $39e4             
  200231c:  1e7dd4ec  store    0, 7d, lr84, lr108      
  2002320:  037dda42  const    lr90, $7d42             
L_2002324:
  2002324:  6135d996  cpeq     gr53, lr89, $96         
L_2002328:
  2002328:  a47dd693  jmpf     lr86, $2021974          
  200232c:  047d93f0  mtsrim   spr147, $7df0              ; [delay slot]
  2002330:  a07d9e0f  jmp      $202176c                
  2002334:  6135d83b  cpeq     gr53, lr88, $3b            ; [delay slot]
  2002338:  a47dd75b  jmpf     lr87, $20218a4          
  200233c:  047c951c  mtsrim   spr149, $7c1c              ; [delay slot]
  2002340:  a07d9807  jmp      $202175c                
  2002344:  6135deec  cpeq     gr53, lr94, $ec            ; [delay slot]
  2002348:  a47dd2e0  jmpf     lr82, $2021ac8          
L_200234c:
  200234c:  047f9740  mtsrim   spr151, $7f40              ; [delay slot]
  2002350:  a07d9beb  jmp      $2021afc                
  2002354:  703d9add  aseq     trap61, lr26, lr93         ; [delay slot]
  2002358:  047e9670  mtsrim   spr150, $7e70           
  200235c:  034ddcd0  const    lr92, $4dd0             
  2002360:  023fdd84  consth   lr93, $3f84             
  2002364:  0353d1d8  const    lr81, $53d8             
  2002368:  0231d0b8  consth   lr80, $31b8             
  200236c:  1e7ddf1b  store    0, 7d, lr95, gr27       
  2002370:  8130d0ba  sll      gr48, lr80, $ba         
  2002374:  a47ddd97  jmpf     lr93, $20219d0          
  2002378:  0355ddfc  const    lr93, $55fc                ; [delay slot]
  200237c:  0231dd20  consth   lr93, $3120             
  2002380:  037dd4d6  const    lr84, $7dd6             
  2002384:  037dd69c  const    lr86, $7d9c             
  2002388:  037dd410  const    lr84, $7d10             
  200238c:  1e7dd43d  store    0, 7d, lr84, gr61       
  2002390:  1530de00  add      gr48, lr94, $00         
L_2002394:
  2002394:  be7dc8f6  mttlb    lr72, lr118             
L_2002398:
  2002398:  1539c8da  add      gr57, lr72, $da         
  200239c:  be7dc85a  mttlb    lr72, gr90              
  20023a0:  b482c87b  jmpfdec  lr72, $1fe2d8c          
  20023a4:  1539c962  add      gr57, lr73, $62            ; [delay slot]
  20023a8:  9d2fdcc4  andn     gr47, lr92, $c4         
  20023ac:  037dcbf2  const    lr75, $7df2             
  20023b0:  0351c9c0  const    lr73, $51c0             
  20023b4:  0231c8dc  consth   lr72, $31dc             
  20023b8:  1e7dceb7  store    0, 7d, lr78, lr55       
  20023bc:  b482cdaf  jmpfdec  lr77, $1fe2e78          
  20023c0:  153ace80  add      gr58, lr78, $80            ; [delay slot]
  20023c4:  0355ce00  const    lr78, $5500             
  20023c8:  0231cd38  consth   lr77, $3138             
  20023cc:  1e7dcc1b  store    0, 7d, lr76, gr27       
  20023d0:  813acb2f  sll      gr58, lr75, $2f         
  20023d4:  a47dcc0f  jmpf     lr76, $2021810          
  20023d8:  037dc19a  const    lr65, $7d9a                ; [delay slot]
  20023dc:  9d2fd7e0  andn     gr47, lr87, $e0         
L_20023e0:
  20023e0:  037dc148  const    lr65, $7d48             
  20023e4:  0379c59c  const    lr69, $799c             
L_20023e8:
  20023e8:  037dc190  const    lr65, $7d90             
  20023ec:  037dc0f0  const    lr64, $7df0             
  20023f0:  03fdce04  const    lr78, $fd04             
  20023f4:  0282cfcf  consth   lr79, $82cf             
  20023f8:  be7dc31e  mttlb    lr67, gr30              
  20023fc:  1539c41d  add      gr57, lr68, $1d         
  2002400:  be7dc446  mttlb    lr68, gr70              
  2002404:  1539c5e1  add      gr57, lr69, $e1         
L_2002408:
  2002408:  b482c718  jmpfdec  lr71, $1fe2c68          
  200240c:  143ac503  add      gr58, lr69, gr3            ; [delay slot]
  2002410:  ce7d82ba  mtsr     IPB, lr58               
  2002414:  0319c49c  const    lr68, $199c             
  2002418:  0231c470  consth   lr68, $3170             
  200241c:  167d8197  load     0, 7d, lr1, lr23        
L_2002420:
  2002420:  037d8284  const    lr2, $7d84              
  2002424:  027d8191  consth   lr1, $7d91              
L_2002428:
  2002428:  240282c7  sub      gr2, lr2, lr71          
  200242c:  257c8054  sub      gr124, lr0, $54         
  2002430:  037f86a0  const    lr6, $7fa0              
  2002434:  240387fe  sub      gr3, lr7, lr126         
  2002438:  035b78ac  const    gr120, $5bac            
  200243c:  027f7820  consth   gr120, $7f20            
  2002440:  15fc86c8  add      lr124, lr6, $c8         
  2002444:  0310bd94  const    lr61, $1094             
  2002448:  0231bd10  consth   lr61, $3110             
  200244c:  167db237  load     0, 7d, lr50, gr55       
  2002450:  6138b307  cpeq     gr56, lr51, $07         
  2002454:  ac7db1ae  jmpt     lr49, $2021b0c          
  2002458:  6138bcd8  cpeq     gr56, lr60, $d8            ; [delay slot]
  200245c:  ac7db100  jmpt     lr49, $202185c          
  2002460:  6138bd81  cpeq     gr56, lr61, $81            ; [delay slot]
  2002464:  ac7db07c  jmpt     lr48, $2021a54          
  2002468:  6138bee1  cpeq     gr56, lr62, $e1            ; [delay slot]
L_200246c:
  200246c:  ac7db3da  jmpt     lr51, $2021bd4          
L_2002470:
  2002470:  6138be6c  cpeq     gr56, lr62, $6c            ; [delay slot]
  2002474:  ac7db2c6  jmpt     lr50, $2021b8c          
  2002478:  6138b8f2  cpeq     gr56, lr56, $f2            ; [delay slot]
  200247c:  ac7db54e  jmpt     lr53, $20219b4          
  2002480:  6138b982  cpeq     gr56, lr57, $82            ; [delay slot]
  2002484:  ac7db400  jmpt     lr52, $2021884          
  2002488:  037fb5e7  const    lr53, $7fe7                ; [delay slot]
  200248c:  6038ba1b  cpeq     gr56, lr58, gr27        
  2002490:  ac7db601  jmpt     lr54, $2021894          
  2002494:  037eb40f  const    lr52, $7e0f                ; [delay slot]
  2002498:  6038a4a3  cpeq     gr56, lr36, lr35        
  200249c:  ac7da8b8  jmpt     lr40, $2021b7c          
  20024a0:  037caa07  const    lr42, $7c07                ; [delay slot]
  20024a4:  6038a6db  cpeq     gr56, lr38, lr91        
L_20024a8:
  20024a8:  ac7dab9d  jmpt     lr43, $2021b1c          
  20024ac:  037da9ff  const    lr41, $7dff                ; [delay slot]
  20024b0:  6038a643  cpeq     gr56, lr38, gr67        
  20024b4:  ac7daa22  jmpt     lr42, $202193c          
  20024b8:  703dee59  aseq     trap61, lr110, gr89        ; [delay slot]
  20024bc:  a07de80b  jmp      $20218e8                
  20024c0:  037db950  const    lr57, $7d50                ; [delay slot]
  20024c4:  a07de9f5  jmp      $2021c98                
  20024c8:  0377bbe4  const    lr59, $77e4                ; [delay slot]
  20024cc:  a07dea53  jmp      $2021a18                
  20024d0:  0379ba68  const    lr58, $7968                ; [delay slot]
  20024d4:  a07debcd  jmp      $2021c08                
  20024d8:  0379ba70  const    lr58, $7970                ; [delay slot]
L_20024dc:
  20024dc:  0315a3f8  const    lr35, $15f8             
  20024e0:  0231a284  consth   lr34, $3184             
  20024e4:  037caf76  const    lr47, $7c76             
  20024e8:  1e7daeff  store    0, 7d, lr46, lr127      
  20024ec:  a07de757  jmp      $2021a48                
  20024f0:  0377b1a0  const    lr49, $77a0                ; [delay slot]
  20024f4:  a07de089  jmp      $2021b18                
  20024f8:  0375b1e4  const    lr49, $75e4                ; [delay slot]
  20024fc:  0315a708  const    lr39, $1508             
  2002500:  0231a6c8  consth   lr38, $31c8             
  2002504:  037fabdc  const    lr43, $7fdc             
  2002508:  1e7dab57  store    0, 7d, lr43, gr87       
  200250c:  a07de273  jmp      $2021ad8                
L_2002510:
  2002510:  0377b204  const    lr50, $7704                ; [delay slot]
  2002514:  037b8d30  const    lr13, $7b30             
L_2002518:
  2002518:  03159bf0  const    lr27, $15f0             
L_200251c:
  200251c:  02319b1c  consth   lr27, $311c             
  2002520:  167d94c7  load     0, 7d, lr20, lr71       
  2002524:  15349466  add      gr52, lr20, $66         
  2002528:  ce7d5dad  mtsr     spr93, lr45             
  200252c:  65348fc0  mul      gr52, lr15, $c0         
  2002530:  64348f21  mul      gr52, lr15, gr33        
  2002534:  64348e95  mul      gr52, lr14, lr21        
  2002538:  643489b9  mul      gr52, lr9, lr57         
  200253c:  64348919  mul      gr52, lr9, gr25         
  2002540:  643488cd  mul      gr52, lr8, lr77         
  2002544:  64348859  mul      gr52, lr8, gr89         
  2002548:  64348b71  mul      gr52, lr11, gr113       
  200254c:  64348b15  mul      gr52, lr11, gr21        
  2002550:  64348a69  mul      gr52, lr10, gr105       
  2002554:  64348a49  mul      gr52, lr10, gr73        
  2002558:  643485ad  mul      gr52, lr5, lr45         
  200255c:  643484e9  mul      gr52, lr4, lr105        
  2002560:  64348401  mul      gr52, lr4, gr1          
L_2002564:
  2002564:  643487d5  mul      gr52, lr7, lr85         
  2002568:  643487d9  mul      gr52, lr7, lr89         
  200256c:  643487b9  mul      gr52, lr7, lr57         
  2002570:  6434874d  mul      gr52, lr7, gr77         
  2002574:  64348679  mul      gr52, lr6, gr121        
  2002578:  64348611  mul      gr52, lr6, gr17         
  200257c:  64348155  mul      gr52, lr1, gr85         
  2002580:  64348149  mul      gr52, lr1, gr73         
  2002584:  643480a9  mul      gr52, lr0, lr41         
  2002588:  643483ad  mul      gr52, lr3, lr45         
  200258c:  64348309  mul      gr52, lr3, gr9          
  2002590:  643482a1  mul      gr52, lr2, lr33         
L_2002594:
  2002594:  64348295  mul      gr52, lr2, lr21         
L_2002598:
  2002598:  64348239  mul      gr52, lr2, gr57         
  200259c:  64349d99  mul      gr52, lr29, lr25        
  20025a0:  64349ccd  mul      gr52, lr28, lr77        
  20025a4:  64349fd9  mul      gr52, lr31, lr89        
  20025a8:  66349ef1  mull     gr52, lr30, lr113       
  20025ac:  c6344c5c  mfsr     gr52, spr76             
  20025b0:  03158fbc  const    lr15, $15bc             
L_20025b4:
  20025b4:  02318f80  consth   lr15, $3180             
  20025b8:  167d80a3  load     0, 7d, lr0, lr35        
  20025bc:  14378069  add      gr55, lr0, gr105        
  20025c0:  034c8fe8  const    lr15, $4ce8             
  20025c4:  02318c9c  consth   lr12, $319c             
  20025c8:  1e7d8056  store    0, 7d, lr0, gr86        
  20025cc:  813b8a7b  sll      gr59, lr10, $7b         
  20025d0:  037d8304  const    lr3, $7d04              
  20025d4:  02708cb0  consth   lr12, $70b0             
  20025d8:  92358c9a  or       gr53, lr12, lr26        
  20025dc:  ac7d821f  jmpt     lr2, $2021a58           
  20025e0:  813c8d80  sll      gr60, lr13, $80            ; [delay slot]
L_20025e4:
  20025e4:  813c8f60  sll      gr60, lr15, $60         
  20025e8:  031981f4  const    lr1, $19f4              
  20025ec:  023181c0  consth   lr1, $31c0              
  20025f0:  1e7d872f  store    0, 7d, lr7, gr47        
  20025f4:  031981e0  const    lr1, $19e0              
  20025f8:  023186f0  consth   lr6, $31f0              
  20025fc:  167d8716  load     0, 7d, lr7, gr22        
  2002600:  813a8694  sll      gr58, lr6, $94          
L_2002604:
  2002604:  037d8710  const    lr7, $7d10              
  2002608:  023b8438  consth   lr4, $3b38              
  200260c:  1e7d851a  store    0, 7d, lr5, gr26        
  2002610:  151d8d20  add      gr29, lr13, $20         
  2002614:  151c8c00  add      gr28, lr12, $00         
  2002618:  ce7d3db6  mtsr     spr61, lr54             
  200261c:  03197ea4  const    gr126, $19a4            
  2002620:  02317e48  consth   gr126, $3148            
  2002624:  167d7ddf  load     0, 7d, gr125, lr95      
  2002628:  ce7d35d3  mtsr     spr53, lr83             
  200262c:  153e7df4  add      gr62, gr125, $f4        
  2002630:  ce7d3447  mtsr     spr52, gr71             
  2002634:  813a7f3f  sll      gr58, gr127, $3f        
  2002638:  ac7d782c  jmpt     gr120, $2021ae8         
  200263c:  037d75bd  const    gr117, $7dbd               ; [delay slot]
  2002640:  047d3e00  mtsrim   spr62, $7d00            
  2002644:  8c7d39e0  iretinv                          
  2002648:  a07d3a94  jmp      $2021c98                   ; [delay slot]
  200264c:  037d77de  const    gr119, $7dde               ; [delay slot]
  2002650:  c62430e8  mfsr     gr36, spr48             
  2002654:  c62531dc  mfsr     gr37, spr49             
L_2002658:
  2002658:  c62f3a70  mfsr     gr47, spr58             
  200265c:  c62732d0  mfsr     gr39, spr50             
L_2002660:
  2002660:  c62b3184  mfsr     gr43, spr49             
  2002664:  c62a3390  mfsr     gr42, spr51             
  2002668:  047d35c7  mtsrim   spr53, $7dc7            
  200266c:  037d705c  const    gr112, $7d5c            
  2002670:  037d73c4  const    gr115, $7dc4            
  2002674:  02397380  consth   gr115, $3980            
  2002678:  167d73a7  load     0, 7d, gr115, lr39      
  200267c:  a47d7324  jmpf     gr115, $2021b0c         
  2002680:  703d30c9  aseq     trap61, gr48, lr73         ; [delay slot]
  2002684:  a88477f8  call     gr119, $1fe3a64         
  2002688:  703d3311  aseq     trap61, gr51, gr17         ; [delay slot]
  200268c:  030d7170  const    gr113, $0d70            
  2002690:  02317004  consth   gr112, $3104            
  2002694:  167d6bf3  load     0, 7d, gr107, lr115     
L_2002698:
  2002698:  034e68ef  const    gr104, $4eef            
  200269c:  020e682f  consth   gr104, $0e2f            
L_20026a0:
  20026a0:  603869c7  cpeq     gr56, gr105, lr71       
  20026a4:  ac7d6867  jmpt     gr104, $2021c40         
  20026a8:  031b6a8d  const    gr106, $1b8d               ; [delay slot]
  20026ac:  02eb6aa6  consth   gr106, $eba6            
  20026b0:  6038692c  cpeq     gr56, gr105, gr44       
  20026b4:  ac826a33  jmpt     gr106, $1fe2f80         
  20026b8:  703d29f1  aseq     trap61, gr41, lr113        ; [delay slot]
  20026bc:  a07d287d  jmp      $2021cb0                
  20026c0:  030d6a80  const    gr106, $0d80               ; [delay slot]
  20026c4:  02316a10  consth   gr106, $3110            
  20026c8:  1e7d677b  store    0, 7d, gr103, gr123     
  20026cc:  030d694c  const    gr105, $0d4c            
  20026d0:  02316820  consth   gr104, $3120            
  20026d4:  047dac0f  mtsrim   spr172, $7d0f           
  20026d8:  3e7da6a7  storem   0, 7d, lr38, lr39       
  20026dc:  030d66a0  const    gr102, $0da0            
  20026e0:  02316648  consth   gr102, $3148            
  20026e4:  031b62f5  const    gr98, $1bf5             
L_20026e8:
  20026e8:  02eb62f6  consth   gr98, $ebf6             
  20026ec:  1e7d62b3  store    0, 7d, gr98, lr51       
  20026f0:  030d6508  const    gr101, $0d08            
  20026f4:  02316430  consth   gr100, $3130            
  20026f8:  167d641b  load     0, 7d, gr100, gr27      
  20026fc:  1e7d645f  store    0, 7d, gr100, gr95      
  2002700:  037d6364  const    gr99, $7d64             
  2002704:  023962e0  consth   gr98, $39e0             
  2002708:  167d67a7  load     0, 7d, gr103, lr39      
  200270c:  a47d6744  jmpf     gr103, $2021c1c         
  2002710:  703d22e9  aseq     trap61, gr34, lr105        ; [delay slot]
  2002714:  a884669c  call     gr102, $1fe3984         
  2002718:  703d2271  aseq     trap61, gr34, gr113        ; [delay slot]
  200271c:  030d5fd0  const    gr95, $0dd0             
  2002720:  02315e84  consth   gr94, $3184             
  2002724:  167d59d3  load     0, 7d, gr89, lr83       
  2002728:  034e5b8f  const    gr91, $4e8f             
  200272c:  020e5b6f  consth   gr91, $0e6f             
  2002730:  60385ce7  cpeq     gr56, gr92, lr103       
  2002734:  ac7d5d87  jmpt     gr93, $2021d50          
  2002738:  031b5c8d  const    gr92, $1b8d                ; [delay slot]
  200273c:  02eb5c46  consth   gr92, $eb46             
  2002740:  60385d8f  cpeq     gr56, gr93, lr15        
  2002744:  ac825f73  jmpt     gr95, $1fe3110          
  2002748:  703d1b11  aseq     trap61, gr27, gr17         ; [delay slot]
  200274c:  a07d1a79  jmp      $2021d30                
  2002750:  030d5800  const    gr88, $0d00                ; [delay slot]
  2002754:  023157b0  consth   gr87, $31b0             
  2002758:  6039509c  cpeq     gr57, gr80, lr28        
  200275c:  92395958  or       gr57, gr89, gr88        
  2002760:  1e7d51c3  store    0, 7d, gr81, lr67       
  2002764:  030d5668  const    gr86, $0d68             
L_2002768:
  2002768:  023155e4  consth   gr85, $31e4             
  200276c:  167d5183  load     0, 7d, gr81, lr3        
L_2002770:
  2002770:  04791417  mtsrim   spr20, $7917            
  2002774:  ce7d1c85  mtsr     spr28, lr5              
  2002778:  ce7d1aa8  mtsr     spr26, lr40             
  200277c:  ce7d1102  mtsr     spr17, gr2              
  2002780:  ce7d15d2  mtsr     spr21, lr82             
  2002784:  ce7d1447  mtsr     spr20, gr71             
  2002788:  ce7d1462  mtsr     spr20, gr98             
  200278c:  c07d121a  jmpi     gr26                    
  2002790:  703d1221  aseq     trap61, gr18, gr33         ; [delay slot]
  2002794:  031c54c0  const    gr84, $1cc0             
  2002798:  02314be4  consth   gr75, $31e4             
  200279c:  167d45e7  load     0, 7d, gr69, lr103      
  20027a0:  4d3445c8  cpge     gr52, gr69, $c8         
  20027a4:  ac7d4797  jmpt     gr71, $2021e00          
  20027a8:  703d0f91  aseq     trap61, gr15, lr17         ; [delay slot]
  20027ac:  153546f1  add      gr53, gr70, $f1         
  20027b0:  1e7d4643  store    0, 7d, gr70, gr67       
  20027b4:  0317484c  const    gr72, $174c             
  20027b8:  02314858  consth   gr72, $3158             
  20027bc:  8135401e  sll      gr53, gr64, $1e         
  20027c0:  143a4f48  add      gr58, gr79, gr72        
L_20027c4:
  20027c4:  c63502e0  mfsr     gr53, CPS               
  20027c8:  c07d0aa2  jmpi     lr34                    
  20027cc:  1e7d4207  store    0, 7d, gr66, gr7           ; [delay slot]
  20027d0:  031c4c54  const    gr76, $1c54             
  20027d4:  02314cdc  consth   gr76, $31dc             
  20027d8:  1e7d4d37  store    0, 7d, gr77, gr55       
  20027dc:  a882424d  call     gr66, $1fe3110          
  20027e0:  037d4831  const    gr72, $7d31                ; [delay slot]
  20027e4:  031c412c  const    gr65, $1c2c             
  20027e8:  023140b8  consth   gr64, $31b8             
  20027ec:  167d411b  load     0, 7d, gr65, gr27       
  20027f0:  0182495f  constn   gr73, $825f             
  20027f4:  1e7d49c7  store    0, 7d, gr73, lr71       
  20027f8:  031c4724  const    gr71, $1c24             
  20027fc:  02314720  consth   gr71, $3120             
  2002800:  a0820124  jmp      $1fe3090                
L_2002804:
  2002804:  037d4a9c  const    gr74, $7d9c                ; [delay slot]
L_2002808:
  2002808:  613b4f82  cpeq     gr59, gr79, $82         
  200280c:  ac7d4476  jmpt     gr68, $2021de4          
  2002810:  703d0205  aseq     trap61, gr2, gr5           ; [delay slot]
  2002814:  152924b0  add      gr41, gr36, $b0         
  2002818:  152825d8  add      gr40, gr37, $d8         
  200281c:  c625761c  mfsr     gr37, spr118            
  2002820:  c6247680  mfsr     gr36, spr118            
  2002824:  c62b7960  mfsr     gr43, spr121            
  2002828:  c62778e4  mfsr     gr39, spr120            
  200282c:  c62a7bc0  mfsr     gr42, spr123            
  2002830:  031a3920  const    gr57, $1a20             
L_2002834:
  2002834:  023138dc  consth   gr56, $31dc             
  2002838:  c63b78f0  mfsr     gr59, spr120            
  200283c:  1e7d3e17  store    0, 7d, gr62, gr23       
  2002840:  153a3e80  add      gr58, gr62, $80         
  2002844:  1e7d2b57  store    0, 7d, gr43, gr87       
L_2002848:
  2002848:  153a3d3c  add      gr58, gr61, $3c         
  200284c:  c63b785c  mfsr     gr59, spr120            
  2002850:  1e7d3d67  store    0, 7d, gr61, gr103      
  2002854:  153a3c04  add      gr58, gr60, $04         
  2002858:  c63b77e4  mfsr     gr59, spr119            
  200285c:  1e7d33e7  store    0, 7d, gr51, lr103      
  2002860:  153a324c  add      gr58, gr50, $4c         
  2002864:  1e7d20db  store    0, 7d, gr32, lr91       
  2002868:  153a3194  add      gr58, gr49, $94         
  200286c:  1e7d21b7  store    0, 7d, gr33, lr55       
  2002870:  153a3100  add      gr58, gr49, $00         
  2002874:  1e7d2d77  store    0, 7d, gr45, gr119      
  2002878:  153a305c  add      gr58, gr48, $5c         
  200287c:  c63b771c  mfsr     gr59, spr119            
  2002880:  1e7d3647  store    0, 7d, gr54, gr71       
  2002884:  153a36e4  add      gr58, gr54, $e4         
  2002888:  c63b7ae4  mfsr     gr59, spr122            
  200288c:  1e7d3407  store    0, 7d, gr52, gr7        
  2002890:  153a34ec  add      gr58, gr52, $ec         
L_2002894:
  2002894:  c63b7adc  mfsr     gr59, spr122            
  2002898:  1e7d3537  store    0, 7d, gr53, gr55       
  200289c:  153a2bd4  add      gr58, gr43, $d4         
  20028a0:  1e7d35c3  store    0, 7d, gr53, lr67       
  20028a4:  153a2994  add      gr58, gr41, $94         
  20028a8:  1e7d36ff  store    0, 7d, gr54, lr127      
  20028ac:  153a2858  add      gr58, gr40, $58         
  20028b0:  c63b64a0  mfsr     gr59, spr100            
  20028b4:  1e7d2ec7  store    0, 7d, gr46, lr71       
  20028b8:  153a2fe0  add      gr58, gr47, $e0         
  20028bc:  c63b6520  mfsr     gr59, spr101            
  20028c0:  1e7d2f8f  store    0, 7d, gr47, lr15       
  20028c4:  153a2d98  add      gr58, gr45, $98         
L_20028c8:
  20028c8:  c63b6410  mfsr     gr59, spr100            
  20028cc:  1e7d2c37  store    0, 7d, gr44, gr55       
  20028d0:  153a2c00  add      gr58, gr44, $00         
  20028d4:  031a2338  const    gr35, $1a38             
  20028d8:  023123d8  consth   gr35, $31d8             
  20028dc:  c63be41c  mfsr     gr59, spr228            
  20028e0:  1e7d23c7  store    0, 7d, gr35, lr71       
  20028e4:  153a2264  add      gr58, gr34, $64         
  20028e8:  c63be7e4  mfsr     gr59, spr231            
  20028ec:  1e7d2087  store    0, 7d, gr32, lr7        
  20028f0:  153a216c  add      gr58, gr33, $6c         
  20028f4:  c63be5dc  mfsr     gr59, spr229            
  20028f8:  1e7d26b7  store    0, 7d, gr38, lr55       
  20028fc:  153a2754  add      gr58, gr39, $54         
  2002900:  c63be284  mfsr     gr59, spr226            
  2002904:  1e7d2757  store    0, 7d, gr39, gr87       
  2002908:  153a253c  add      gr58, gr37, $3c         
  200290c:  c63be65c  mfsr     gr59, spr230            
  2002910:  1e7d2567  store    0, 7d, gr37, gr103      
  2002914:  153a2404  add      gr58, gr36, $04         
  2002918:  c63bd9e4  mfsr     gr59, spr217            
  200291c:  1e7d1be7  store    0, 7d, gr27, lr103      
  2002920:  153a1a4c  add      gr58, gr26, $4c         
  2002924:  c63bd89c  mfsr     gr59, spr216            
L_2002928:
  2002928:  1e7d18d7  store    0, 7d, gr24, lr87       
  200292c:  153a19f4  add      gr58, gr25, $f4         
  2002930:  c63bd904  mfsr     gr59, spr217            
  2002934:  1e7d1977  store    0, 7d, gr25, gr119      
  2002938:  153a185c  add      gr58, gr24, $5c         
  200293c:  030e1004  const    gr16, $0e04             
  2002940:  02311000  consth   gr16, $3100             
  2002944:  033f1ea2  const    gr30, $3fa2             
  2002948:  023f1db7  consth   gr29, $3fb7             
  200294c:  1e7d1d08  store    0, 7d, gr29, gr8        
  2002950:  037d1ef6  const    gr30, $7df6             
  2002954:  037d1ddc  const    gr29, $7ddc             
  2002958:  03551c68  const    gr28, $5568             
  200295c:  023113d0  consth   gr19, $31d0             
  2002960:  03111ef8  const    gr30, $11f8             
  2002964:  02311d90  consth   gr29, $3190             
  2002968:  03151ee4  const    gr30, $15e4             
  200296c:  02311e5c  consth   gr30, $315c             
  2002970:  037d14a0  const    gr20, $7da0             
  2002974:  b6371480  mftlb    gr55, gr20              
  2002978:  1e7d1aad  store    0, 7d, gr26, lr45       
  200297c:  15341924  add      gr52, gr25, $24         
  2002980:  be7d158e  mttlb    gr21, lr14              
  2002984:  1539169d  add      gr57, gr22, $9d         
  2002988:  b6371610  mftlb    gr55, gr22              
  200298c:  15391671  add      gr57, gr22, $71         
  2002990:  1e7d194d  store    0, 7d, gr25, gr77       
  2002994:  153405b4  add      gr52, gr5, $b4          
  2002998:  b63708d8  mftlb    gr55, gr8               
  200299c:  1e7d0655  store    0, 7d, gr6, gr85        
  20029a0:  15340484  add      gr52, gr4, $84          
  20029a4:  be7d0926  mttlb    gr9, gr38               
  20029a8:  15390ae5  add      gr57, gr10, $e5         
  20029ac:  b6370ac0  mftlb    gr55, gr10              
  20029b0:  15390a69  add      gr57, gr10, $69         
  20029b4:  1e7d0595  store    0, 7d, gr5, lr21        
  20029b8:  153401f4  add      gr52, gr1, $f4          
  20029bc:  167d0217  load     0, 7d, gr2, gr23        
  20029c0:  1e7d03cf  store    0, 7d, gr3, lr79        
  20029c4:  15360214  add      gr54, gr2, $14          
  20029c8:  1e7d0c7f  store    0, 7d, gr12, gr127      
  20029cc:  b4820fb6  jmpfdec  gr15, $1fe34a4          
  20029d0:  153a0c24  add      gr58, gr12, $24            ; [delay slot]
  20029d4:  037d0e32  const    gr14, $7d32             
  20029d8:  0351034c  const    gr3, $514c              
  20029dc:  023102a0  consth   gr2, $31a0              
  20029e0:  1e7d030f  store    0, 7d, gr3, gr15        
  20029e4:  b4820363  jmpfdec  gr3, $1fe3370           
  20029e8:  153a0194  add      gr58, gr1, $94             ; [delay slot]
  20029ec:  035501e0  const    gr1, $55e0              
  20029f0:  02310104  consth   gr1, $3104              
  20029f4:  1e7d0177  store    0, 7d, gr1, gr119       
  20029f8:  047d4527  mtsrim   spr69, $7d27            
  20029fc:  03190758  const    gr7, $1958              
  2002a00:  02310700  consth   gr7, $3100              
  2002a04:  1e7d40a7  store    0, 7d, gr64, lr39       
  2002a08:  031905ac  const    gr5, $19ac              
  2002a0c:  02310540  consth   gr5, $3140              
  2002a10:  047dc4d7  mtsrim   spr196, $7dd7           
  2002a14:  3e7d039b  storem   0, 7d, gr3, lr27        
  2002a18:  703d4271  aseq     trap61, gr66, gr113     
  2002a1c:  031bfb98  const    lr123, $1b98            
  2002a20:  0232fa84  consth   lr122, $3284            
  2002a24:  8338bf92  srl      gr56, lr63, $92         
  2002a28:  9138f9c7  and      gr56, lr121, $c7        
  2002a2c:  9338f9dc  or       gr56, lr121, $dc        
  2002a30:  8138fea2  sll      gr56, lr126, $a2        
  2002a34:  ce7e39c6  mtsr     spr57, lr70             
  2002a38:  047e3f9b  mtsrim   spr63, $7e9b            
  2002a3c:  3e7eb867  storem   0, 7e, lr56, gr103      
  2002a40:  703eb8c9  aseq     trap62, lr56, lr73      
  2002a44:  8138fa82  sll      gr56, lr122, $82        
  2002a48:  a47efc19  jmpf     lr124, $20222ac         
  2002a4c:  703ebb71  aseq     trap62, lr59, gr113        ; [delay slot]
  2002a50:  0319fccc  const    lr124, $19cc            
  2002a54:  0232f3b0  consth   lr115, $32b0            
  2002a58:  16fdf29e  load     1, 7d, lr114, lr30      
  2002a5c:  1e7ef25b  store    0, 7e, lr114, gr91      
  2002a60:  1539f284  add      gr57, lr114, $84        
  2002a64:  16fcf326  load     1, 7c, lr115, gr38      
  2002a68:  1e7edfa3  store    0, 7e, lr95, lr35       
  2002a6c:  15fceec0  add      lr124, lr110, $c0       
  2002a70:  15fdef68  add      lr125, lr111, $68       
  2002a74:  15fae5dc  add      lr122, lr101, $dc       
  2002a78:  15fbe6f0  add      lr123, lr102, $f0       
  2002a7c:  15f8ea50  add      lr120, lr106, $50       
  2002a80:  15f9e684  add      lr121, lr102, $84       
  2002a84:  c6f6b210  mfsr     lr118, spr178           
  2002a88:  15ffff38  add      lr127, lr127, $38       
  2002a8c:  0314f500  const    lr117, $1400            
  2002a90:  0232f420  consth   lr116, $3220            
  2002a94:  047e3407  mtsrim   spr52, $7e07            
  2002a98:  3e7e2da3  storem   0, 7e, gr45, lr35       
  2002a9c:  0316e6f8  const    lr102, $16f8            
  2002aa0:  0232e648  consth   lr102, $3248            
  2002aa4:  c632a09c  mfsr     gr50, FPE               
  2002aa8:  1e7ee2db  store    0, 7e, lr98, lr91       
  2002aac:  8139eee4  sll      gr57, lr110, $e4        
  2002ab0:  ac7ee903  jmpt     lr105, $20222bc         
  2002ab4:  703eae31  aseq     trap62, lr46, gr49         ; [delay slot]
  2002ab8:  a880e9be  call     lr105, $1fe2db0         
  2002abc:  703ea91d  aseq     trap62, lr41, gr29         ; [delay slot]
  2002ac0:  8139e80f  sll      gr57, lr104, $0f        
  2002ac4:  ac7eeee8  jmpt     lr110, $2022664         
  2002ac8:  703eabe5  aseq     trap62, lr43, lr101        ; [delay slot]
  2002acc:  030de258  const    lr98, $0d58             
  2002ad0:  0232e3e8  consth   lr99, $32e8             
  2002ad4:  036aedfd  const    lr109, $6afd            
  2002ad8:  1e7eed38  store    0, 7e, lr109, gr56      
  2002adc:  a083a498  jmp      $1fe393c                
  2002ae0:  703ea485  aseq     trap62, lr36, lr5          ; [delay slot]
  2002ae4:  a880e04b  call     lr96, $1fe2c10          
  2002ae8:  037eea0c  const    lr106, $7e0c               ; [delay slot]
  2002aec:  031fe198  const    lr97, $1f98             
  2002af0:  0232e6a0  consth   lr102, $32a0            
  2002af4:  1e7ee7c6  store    0, 7e, lr103, lr70      
  2002af8:  037ee8e4  const    lr104, $7ee4            
  2002afc:  6138e721  cpeq     gr56, lr103, $21        
  2002b00:  ac7ee7d6  jmpt     lr103, $2022658         
  2002b04:  6138e59e  cpeq     gr56, lr101, $9e           ; [delay slot]
  2002b08:  ac7ee40b  jmpt     lr100, $2022334         
  2002b0c:  6138e573  cpeq     gr56, lr101, $73           ; [delay slot]
  2002b10:  ac7ee50c  jmpt     lr101, $2022340         
  2002b14:  6138dbb4  cpeq     gr56, lr91, $b4            ; [delay slot]
  2002b18:  ac7edad7  jmpt     lr90, $2022674          
  2002b1c:  6138db19  cpeq     gr56, lr91, $19            ; [delay slot]
  2002b20:  ac83dbb7  jmpt     lr91, $1fe39fc          
  2002b24:  703e9c61  aseq     trap62, lr28, gr97         ; [delay slot]
  2002b28:  a0819e0b  jmp      $1fe2f54                
  2002b2c:  703e9fc1  aseq     trap62, lr31, lr65         ; [delay slot]
  2002b30:  031fd9a8  const    lr89, $1fa8             
  2002b34:  0232d8dc  consth   lr88, $32dc             
  2002b38:  037edef0  const    lr94, $7ef0             
  2002b3c:  1e7ede17  store    0, 7e, lr94, gr23       
  2002b40:  031fde38  const    lr94, $1f38             
  2002b44:  0232de10  consth   lr94, $3210             
  2002b48:  0181dcc7  constn   lr92, $81c7             
  2002b4c:  a0819aba  jmp      $1fe3234                
  2002b50:  1e7edd67  store    0, 7e, lr93, gr103         ; [delay slot]
  2002b54:  031fdcc0  const    lr92, $1fc0             
  2002b58:  0232d3e4  consth   lr83, $32e4             
  2002b5c:  037ed3a0  const    lr83, $7ea0             
  2002b60:  1e7ed30f  store    0, 7e, lr83, gr15       
  2002b64:  031fd120  const    lr81, $1f20             
  2002b68:  0232d190  consth   lr81, $3290             
  2002b6c:  a081962e  jmp      $1fe3024                
  2002b70:  1e7ed043  store    0, 7e, lr80, gr67          ; [delay slot]
  2002b74:  035edf30  const    lr95, $5e30             
  2002b78:  047e9527  mtsrim   spr149, $7e27           
  2002b7c:  813bd009  sll      gr59, lr80, $09         
  2002b80:  ac7ed509  jmpt     lr85, $20223a4          
  2002b84:  0319d6ac  const    lr86, $19ac                ; [delay slot]
  2002b88:  0232d5e4  consth   lr85, $32e4             
  2002b8c:  167edb07  load     0, 7e, lr91, gr7        
  2002b90:  034ed5e8  const    lr85, $4ee8             
  2002b94:  027ed5dc  consth   lr85, $7edc             
  2002b98:  9c37da36  andn     gr55, lr90, gr54        
  2002b9c:  9237c598  or       gr55, lr69, lr24        
  2002ba0:  1e7ec4c3  store    0, 7e, lr68, lr67       
  2002ba4:  031ac9d4  const    lr73, $1ad4             
  2002ba8:  0232c8b8  consth   lr72, $32b8             
  2002bac:  167ec91b  load     0, 7e, lr73, gr27       
  2002bb0:  157fcea0  add      gr127, lr78, $a0        
  2002bb4:  83388982  srl      gr56, lr9, $82          
  2002bb8:  9138ce9b  and      gr56, lr78, $9b         
  2002bbc:  9338cea0  or       gr56, lr78, $a0         
  2002bc0:  8138cfca  sll      gr56, lr79, $ca         
  2002bc4:  ce7e0bda  mtsr     PC1, lr90               
  2002bc8:  031bcd58  const    lr77, $1b58             
  2002bcc:  0232cd70  consth   lr77, $3270             
  2002bd0:  047e0c7b  mtsrim   PC2, $7e7b              
  2002bd4:  367e84f7  loadm    0, 7e, lr4, lr119       
  2002bd8:  703e85d9  aseq     trap62, lr5, lr89       
  2002bdc:  031ac354  const    lr67, $1a54             
  2002be0:  0232c280  consth   lr66, $3280             
  2002be4:  047e025f  mtsrim   CPS, $7e5f              
  2002be8:  367ec6a3  loadm    0, 7e, lr70, lr35       
  2002bec:  703e87c1  aseq     trap62, lr7, lr65       
  2002bf0:  047a8417  mtsrim   ALU, $7a17              
  2002bf4:  0319c094  const    lr64, $1994             
  2002bf8:  0232c7f0  consth   lr71, $32f0             
  2002bfc:  167ec617  load     0, 7e, lr70, gr23       
  2002c00:  1539c680  add      gr57, lr70, $80         
  2002c04:  ce7e8156  mtsr     IPA, gr86               
  2002c08:  167ec47f  load     0, 7e, lr68, gr127      
  2002c0c:  1539c558  add      gr57, lr69, $58         
  2002c10:  ce7e8266  mtsr     IPB, gr102              
  2002c14:  1539c404  add      gr57, lr68, $04         
  2002c18:  167ebaa3  load     0, 7e, lr58, lr35       
  2002c1c:  1539baa4  add      gr57, lr58, $a4         
  2002c20:  ce7efe0e  mtsr     spr254, gr14            
  2002c24:  167eb8db  load     0, 7e, lr56, lr91       
  2002c28:  1539b994  add      gr57, lr57, $94         
  2002c2c:  ce7efab6  mtsr     spr250, lr54            
  2002c30:  167eb843  load     0, 7e, lr56, gr67       
  2002c34:  1539b834  add      gr57, lr56, $34         
  2002c38:  ce7efa1e  mtsr     spr250, gr30            
  2002c3c:  167ebe5b  load     0, 7e, lr62, gr91       
  2002c40:  1539bf04  add      gr57, lr63, $04         
  2002c44:  ce7effa6  mtsr     spr255, lr38            
  2002c48:  167ebca3  load     0, 7e, lr60, lr35       
  2002c4c:  1539bd44  add      gr57, lr61, $44         
  2002c50:  ce7efcae  mtsr     spr252, lr46            
  2002c54:  167ebd9b  load     0, 7e, lr61, lr27       
  2002c58:  1539bc74  add      gr57, lr60, $74         
  2002c5c:  ce7efc96  mtsr     spr252, lr22            
  2002c60:  167eb3c3  load     0, 7e, lr51, lr67       
  2002c64:  1539b194  add      gr57, lr49, $94         
  2002c68:  ce7efefe  mtsr     spr254, lr126           
  2002c6c:  167eb11b  load     0, 7e, lr49, gr27       
  2002c70:  1539b7a4  add      gr57, lr55, $a4         
  2002c74:  ce7efac6  mtsr     spr250, lr70            
  2002c78:  167eb6a3  load     0, 7e, lr54, lr35       
  2002c7c:  1539b724  add      gr57, lr55, $24         
  2002c80:  ce7efa8e  mtsr     spr250, lr14            
  2002c84:  167eb4db  load     0, 7e, lr52, lr91       
L_2002c88:
  2002c88:  1539b514  add      gr57, lr53, $14         
  2002c8c:  ce7efe36  mtsr     spr254, gr54            
  2002c90:  167eb543  load     0, 7e, lr53, gr67       
  2002c94:  1539abb4  add      gr57, lr43, $b4         
L_2002c98:
  2002c98:  ce7ee19e  mtsr     spr225, lr30            
  2002c9c:  167eaa5b  load     0, 7e, lr42, gr91       
  2002ca0:  1539aa84  add      gr57, lr42, $84         
  2002ca4:  ce7ee326  mtsr     spr227, gr38            
  2002ca8:  0319a96c  const    lr41, $196c             
  2002cac:  0232a9c0  consth   lr41, $32c0             
  2002cb0:  167ea82f  load     0, 7e, lr40, gr47       
  2002cb4:  1539a8d8  add      gr57, lr40, $d8         
  2002cb8:  ce7e68b6  mtsr     spr104, lr54            
  2002cbc:  167eae17  load     0, 7e, lr46, gr23       
  2002cc0:  1539ae80  add      gr57, lr46, $80         
  2002cc4:  ce7e6856  mtsr     spr104, gr86            
L_2002cc8:
  2002cc8:  167eac7f  load     0, 7e, lr44, gr127      
  2002ccc:  1539ad58  add      gr57, lr45, $58         
  2002cd0:  ce7e6966  mtsr     spr105, gr102           
  2002cd4:  167ead47  load     0, 7e, lr45, gr71       
  2002cd8:  1539a3e0  add      gr57, lr35, $e0         
  2002cdc:  ce7e66e6  mtsr     spr102, lr102           
  2002ce0:  167ea30f  load     0, 7e, lr35, gr15       
  2002ce4:  1539a198  add      gr57, lr33, $98         
  2002ce8:  ce7e62d6  mtsr     spr98, lr86             
  2002cec:  167ea0b7  load     0, 7e, lr32, lr55       
  2002cf0:  1539a100  add      gr57, lr33, $00         
  2002cf4:  ce7e6276  mtsr     spr98, gr118            
  2002cf8:  167ea11f  load     0, 7e, lr33, gr31       
  2002cfc:  1539a718  add      gr57, lr39, $18         
  2002d00:  ce7e6646  mtsr     spr102, gr70            
  2002d04:  167ea7a7  load     0, 7e, lr39, lr39       
  2002d08:  1539a5e0  add      gr57, lr37, $e0         
  2002d0c:  ce7e6506  mtsr     spr101, gr6             
  2002d10:  8c7ee3e8  iretinv                          
