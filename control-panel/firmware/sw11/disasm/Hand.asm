* ==================================================================
*  ACEF_1 "Runtime" -- Hand (Am29000, base $2000000), exact
* ==================================================================
*  Made by runtime_dasm.py: decrypted as DRVR's ACEFLoad does it,
*  disassembled by am29k_dasm.py.  L_XXXXXXX = a jump target.
* ==================================================================
  2000000:  a009009a  jmp      $2002668                   ; -> L_2002668
  2000004:  03004d91  const    gr77, $0091                ; [delay slot]
L_2000008:
  2000008:  c6590b00  mfsr     gr89, PC1               
  200000c:  c6580a00  mfsr     gr88, PC0               
  2000010:  c6520100  mfsr     gr82, OPS               
  2000014:  0400027f  mtsrim   CPS, $007f              
  2000018:  c6470300  mfsr     gr71, CFG               
  200001c:  9d474720  andn     gr71, gr71, $20         
  2000020:  ce000347  mtsr     CFG, gr71               
  2000024:  c6560400  mfsr     gr86, CHA               
  2000028:  c65a0600  mfsr     gr90, CHC               
  200002c:  8147561f  sll      gr71, gr86, $1f         
  2000030:  ac00472f  jmpt     gr71, $20000ec             ; -> L_20000ec
  2000034:  81575a10  sll      gr87, gr90, $10            ; [delay slot]
  2000038:  9d5a5a01  andn     gr90, gr90, $01         
  200003c:  81475a11  sll      gr71, gr90, $11         
  2000040:  ac004736  jmpt     gr71, $2000118             ; -> L_2000118
  2000044:  ce00065a  mtsr     CHC, gr90                  ; [delay slot]
  2000048:  03004702  const    gr71, $0002             
  200004c:  a8064599  call     gr69, $2001ab0             ; -> L_2001ab0
  2000050:  81465600  sll      gr70, gr86, $00            ; [delay slot]
  2000054:  81494600  sll      gr73, gr70, $00         
  2000058:  ac00570c  jmpt     gr87, $2000088             ; -> L_2000088
  200005c:  c6440500  mfsr     gr68, CHD                  ; [delay slot]
  2000060:  835a4410  srl      gr90, gr68, $10         
  2000064:  1e025a49  store    0, 2, gr90, gr73        
  2000068:  15565602  add      gr86, gr86, $02         
  200006c:  03004702  const    gr71, $0002             
  2000070:  a8064590  call     gr69, $2001ab0             ; -> L_2001ab0
  2000074:  81465600  sll      gr70, gr86, $00            ; [delay slot]
  2000078:  81494600  sll      gr73, gr70, $00         
  200007c:  81444410  sll      gr68, gr68, $10         
  2000080:  1e024449  store    0, 2, gr68, gr73        
  2000084:  a0000010  jmp      $20000c4                   ; -> L_20000c4
L_2000088:
  2000088:  030357fc  const    gr87, $03fc                ; [delay slot]
  200008c:  16024449  load     0, 2, gr68, gr73        
  2000090:  905a575a  and      gr90, gr87, gr90        
  2000094:  c6578000  mfsr     gr87, IPC               
  2000098:  ce00805a  mtsr     IPC, gr90               
  200009c:  15565602  add      gr86, gr86, $02         
  20000a0:  03004702  const    gr71, $0002             
  20000a4:  a8064583  call     gr69, $2001ab0             ; -> L_2001ab0
  20000a8:  81465600  sll      gr70, gr86, $00            ; [delay slot]
  20000ac:  81494600  sll      gr73, gr70, $00         
  20000b0:  16025a49  load     0, 2, gr90, gr73        
  20000b4:  81444410  sll      gr68, gr68, $10         
  20000b8:  835a5a10  srl      gr90, gr90, $10         
  20000bc:  92005a44  or       gr0, gr90, gr68         
  20000c0:  ce008057  mtsr     IPC, gr87               
L_20000c4:
  20000c4:  8145400d  sll      gr69, gr64, $0d         
  20000c8:  ac004503  jmpt     gr69, $20000d4             ; -> L_20000d4
  20000cc:  c6470300  mfsr     gr71, CFG                  ; [delay slot]
  20000d0:  93474720  or       gr71, gr71, $20         
L_20000d4:
  20000d4:  ce000347  mtsr     CFG, gr71               
  20000d8:  0404027f  mtsrim   CPS, $047f              
  20000dc:  ce000b59  mtsr     PC1, gr89               
  20000e0:  ce000a58  mtsr     PC0, gr88               
  20000e4:  ce000152  mtsr     OPS, gr82               
  20000e8:  88000000  iret                             
L_20000ec:
  20000ec:  c6470100  mfsr     gr71, OPS               
  20000f0:  91474701  and      gr71, gr71, $01         
  20000f4:  61474700  cpeq     gr71, gr71, $00         
  20000f8:  ac004706  jmpt     gr71, $2000110             ; -> L_2000110
  20000fc:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000100:  25545404  sub      gr84, gr84, $04         
  2000104:  16005954  load     0, 0, gr89, gr84        
  2000108:  25545404  sub      gr84, gr84, $04         
  200010c:  16005854  load     0, 0, gr88, gr84        
L_2000110:
  2000110:  a0090056  jmp      $2002668                   ; -> L_2002668
  2000114:  03004d92  const    gr77, $0092                ; [delay slot]
L_2000118:
  2000118:  c6448700  mfsr     gr68, CR                
  200011c:  a4005717  jmpf     gr87, $2000178             ; -> L_2000178
  2000120:  25444401  sub      gr68, gr68, $01            ; [delay slot]
  2000124:  030357fc  const    gr87, $03fc             
  2000128:  9057575a  and      gr87, gr87, gr90        
  200012c:  c6488000  mfsr     gr72, IPC               
L_2000130:
  2000130:  03004702  const    gr71, $0002             
  2000134:  a806455f  call     gr69, $2001ab0             ; -> L_2001ab0
  2000138:  81465600  sll      gr70, gr86, $00            ; [delay slot]
  200013c:  16025a46  load     0, 2, gr90, gr70        
  2000140:  ce008057  mtsr     IPC, gr87               
  2000144:  15565602  add      gr86, gr86, $02         
  2000148:  03004702  const    gr71, $0002             
  200014c:  a8064559  call     gr69, $2001ab0             ; -> L_2001ab0
  2000150:  81465600  sll      gr70, gr86, $00            ; [delay slot]
  2000154:  81475a10  sll      gr71, gr90, $10         
  2000158:  16025a46  load     0, 2, gr90, gr70        
  200015c:  835a5a10  srl      gr90, gr90, $10         
  2000160:  92005a47  or       gr0, gr90, gr71         
  2000164:  15575704  add      gr87, gr87, $04         
  2000168:  b4ff44f2  jmpfdec  gr68, $2000130             ; -> L_2000130
  200016c:  15565602  add      gr86, gr86, $02            ; [delay slot]
  2000170:  a0000015  jmp      $20001c4                   ; -> L_20001c4
  2000174:  ce008048  mtsr     IPC, gr72                  ; [delay slot]
L_2000178:
  2000178:  030357fc  const    gr87, $03fc             
  200017c:  9057575a  and      gr87, gr87, gr90        
  2000180:  c6488100  mfsr     gr72, IPA               
L_2000184:
  2000184:  ce008157  mtsr     IPA, gr87               
  2000188:  03004702  const    gr71, $0002             
  200018c:  a8064549  call     gr69, $2001ab0             ; -> L_2001ab0
  2000190:  81465600  sll      gr70, gr86, $00            ; [delay slot]
  2000194:  835a0010  srl      gr90, gr0, $10          
  2000198:  1e025a46  store    0, 2, gr90, gr70        
  200019c:  15565602  add      gr86, gr86, $02         
  20001a0:  03004702  const    gr71, $0002             
  20001a4:  a8064543  call     gr69, $2001ab0             ; -> L_2001ab0
  20001a8:  81465600  sll      gr70, gr86, $00            ; [delay slot]
  20001ac:  81470010  sll      gr71, gr0, $10          
  20001b0:  1e024746  store    0, 2, gr71, gr70        
  20001b4:  15575704  add      gr87, gr87, $04         
  20001b8:  b4ff44f3  jmpfdec  gr68, $2000184             ; -> L_2000184
  20001bc:  15565602  add      gr86, gr86, $02            ; [delay slot]
  20001c0:  ce008148  mtsr     IPA, gr72               
L_20001c4:
  20001c4:  03404600  const    gr70, $4000             
  20001c8:  9c5a5a46  andn     gr90, gr90, gr70        
  20001cc:  a0ff00be  jmp      $20000c4                   ; -> L_20000c4
  20001d0:  04008700  mtsrim   CR, $0000                  ; [delay slot]
L_20001d4:
  20001d4:  0404027f  mtsrim   CPS, $047f              
  20001d8:  c6540400  mfsr     gr84, CHA               
  20001dc:  91545403  and      gr84, gr84, $03         
  20001e0:  61545400  cpeq     gr84, gr84, $00         
  20001e4:  ac005450  jmpt     gr84, $2000324             ; -> L_2000324
  20001e8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20001ec:  0300555c  const    gr85, $005c             
  20001f0:  02445500  consth   gr85, $4400             
  20001f4:  03005400  const    gr84, $0000             
  20001f8:  1e005455  store    0, 0, gr84, gr85        
  20001fc:  01ff54ff  constn   gr84, $ffff             
  2000200:  a0ff0082  jmp      $2000008                   ; -> L_2000008
  2000204:  1e005455  store    0, 0, gr84, gr85           ; [delay slot]
  2000208:  03045500  const    gr85, $0400             
  200020c:  03305490  const    gr84, $3090             
  2000210:  024c5400  consth   gr84, $4c00             
  2000214:  1e004454  store    0, 0, gr68, gr84        
  2000218:  15545404  add      gr84, gr84, $04         
  200021c:  1e005654  store    0, 0, gr86, gr84        
  2000220:  15545404  add      gr84, gr84, $04         
  2000224:  1e005a54  store    0, 0, gr90, gr84        
  2000228:  15545404  add      gr84, gr84, $04         
  200022c:  1e005754  store    0, 0, gr87, gr84        
  2000230:  15545404  add      gr84, gr84, $04         
  2000234:  1e005254  store    0, 0, gr82, gr84        
  2000238:  15545404  add      gr84, gr84, $04         
  200023c:  1e005854  store    0, 0, gr88, gr84        
  2000240:  15545404  add      gr84, gr84, $04         
  2000244:  1e005954  store    0, 0, gr89, gr84        
  2000248:  c65a0600  mfsr     gr90, CHC               
  200024c:  9c5a5a55  andn     gr90, gr90, gr85        
  2000250:  935a5a01  or       gr90, gr90, $01         
  2000254:  9d575a01  andn     gr87, gr90, $01         
  2000258:  ce000657  mtsr     CHC, gr87               
  200025c:  c6560400  mfsr     gr86, CHA               
  2000260:  c6570500  mfsr     gr87, CHD               
  2000264:  c6520100  mfsr     gr82, OPS               
  2000268:  c6580a00  mfsr     gr88, PC0               
  200026c:  c6590b00  mfsr     gr89, PC1               
  2000270:  0400027f  mtsrim   CPS, $007f              
  2000274:  03005500  const    gr85, $0000             
  2000278:  02465500  consth   gr85, $4600             
  200027c:  16005555  load     0, 0, gr85, gr85        
  2000280:  0404027f  mtsrim   CPS, $047f              
  2000284:  ce000b59  mtsr     PC1, gr89               
  2000288:  ce000a58  mtsr     PC0, gr88               
  200028c:  ce000152  mtsr     OPS, gr82               
  2000290:  ce000456  mtsr     CHA, gr86               
  2000294:  ce000557  mtsr     CHD, gr87               
  2000298:  ce00065a  mtsr     CHC, gr90               
  200029c:  16005954  load     0, 0, gr89, gr84        
  20002a0:  25545404  sub      gr84, gr84, $04         
  20002a4:  16005854  load     0, 0, gr88, gr84        
  20002a8:  25545404  sub      gr84, gr84, $04         
  20002ac:  16005254  load     0, 0, gr82, gr84        
  20002b0:  25545404  sub      gr84, gr84, $04         
  20002b4:  16005754  load     0, 0, gr87, gr84        
  20002b8:  25545404  sub      gr84, gr84, $04         
  20002bc:  16005a54  load     0, 0, gr90, gr84        
  20002c0:  25545404  sub      gr84, gr84, $04         
  20002c4:  16005654  load     0, 0, gr86, gr84        
  20002c8:  25545404  sub      gr84, gr84, $04         
  20002cc:  16004454  load     0, 0, gr68, gr84        
  20002d0:  8154551b  sll      gr84, gr85, $1b         
  20002d4:  ac00540f  jmpt     gr84, $2000310             ; -> L_2000310
  20002d8:  8154551d  sll      gr84, gr85, $1d            ; [delay slot]
  20002dc:  ac00541e  jmpt     gr84, $2000354             ; -> L_2000354
  20002e0:  81544017  sll      gr84, gr64, $17            ; [delay slot]
  20002e4:  a4005405  jmpf     gr84, $20002f8             ; -> L_20002f8
  20002e8:  03005470  const    gr84, $0070                ; [delay slot]
  20002ec:  02445400  consth   gr84, $4400             
  20002f0:  16005454  load     0, 0, gr84, gr84        
  20002f4:  acff54b8  jmpt     gr84, $20001d4             ; -> L_20001d4
L_20002f8:
  20002f8:  91555503  and      gr85, gr85, $03            ; [delay slot]
  20002fc:  61545503  cpeq     gr84, gr85, $03         
  2000300:  ac005404  jmpt     gr84, $2000310             ; -> L_2000310
  2000304:  61545500  cpeq     gr84, gr85, $00            ; [delay slot]
  2000308:  a4005407  jmpf     gr84, $2000324             ; -> L_2000324
  200030c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2000310:
  2000310:  c6550600  mfsr     gr85, CHC               
  2000314:  81555501  sll      gr85, gr85, $01         
  2000318:  ac00554b  jmpt     gr85, $2000444             ; -> L_2000444
  200031c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000320:  88000000  iret                             
L_2000324:
  2000324:  036754e0  const    gr84, $67e0             
  2000328:  024c5400  consth   gr84, $4c00             
  200032c:  16005554  load     0, 0, gr85, gr84        
  2000330:  a4005507  jmpf     gr85, $200034c             ; -> L_200034c
  2000334:  15555501  add      gr85, gr85, $01            ; [delay slot]
  2000338:  1e005554  store    0, 0, gr85, gr84        
  200033c:  c6550600  mfsr     gr85, CHC               
  2000340:  9d555501  andn     gr85, gr85, $01         
  2000344:  ce000655  mtsr     CHC, gr85               
  2000348:  88000000  iret                             
L_200034c:
  200034c:  a00800c7  jmp      $2002668                   ; -> L_2002668
  2000350:  03004d90  const    gr77, $0090                ; [delay slot]
L_2000354:
  2000354:  03305490  const    gr84, $3090             
  2000358:  024c5400  consth   gr84, $4c00             
  200035c:  1e004654  store    0, 0, gr70, gr84        
  2000360:  15545404  add      gr84, gr84, $04         
  2000364:  1e004354  store    0, 0, gr67, gr84        
  2000368:  15545404  add      gr84, gr84, $04         
  200036c:  1e004454  store    0, 0, gr68, gr84        
  2000370:  15545404  add      gr84, gr84, $04         
  2000374:  1e005654  store    0, 0, gr86, gr84        
  2000378:  15545404  add      gr84, gr84, $04         
  200037c:  1e005a54  store    0, 0, gr90, gr84        
  2000380:  15545404  add      gr84, gr84, $04         
  2000384:  1e005754  store    0, 0, gr87, gr84        
  2000388:  15545404  add      gr84, gr84, $04         
  200038c:  1e005854  store    0, 0, gr88, gr84        
  2000390:  15545404  add      gr84, gr84, $04         
  2000394:  1e005954  store    0, 0, gr89, gr84        
  2000398:  03045501  const    gr85, $0401             
  200039c:  c65a0600  mfsr     gr90, CHC               
  20003a0:  9c5a5a55  andn     gr90, gr90, gr85        
  20003a4:  ce00065a  mtsr     CHC, gr90               
  20003a8:  c6560400  mfsr     gr86, CHA               
  20003ac:  c6570500  mfsr     gr87, CHD               
  20003b0:  c6580a00  mfsr     gr88, PC0               
  20003b4:  c6590b00  mfsr     gr89, PC1               
  20003b8:  0400027f  mtsrim   CPS, $007f              
  20003bc:  8344561c  srl      gr68, gr86, $1c         
  20003c0:  6146440f  cpeq     gr70, gr68, $0f         
  20003c4:  03004300  const    gr67, $0000             
  20003c8:  a4004604  jmpf     gr70, $20003d8             ; -> L_20003d8
  20003cc:  02004301  consth   gr67, $0001                ; [delay slot]
  20003d0:  83445618  srl      gr68, gr86, $18         
  20003d4:  9144440f  and      gr68, gr68, $0f         
L_20003d8:
  20003d8:  80434344  sll      gr67, gr67, gr68        
  20003dc:  03004400  const    gr68, $0000             
  20003e0:  02464400  consth   gr68, $4600             
  20003e4:  16004644  load     0, 0, gr70, gr68        
  20003e8:  9c464643  andn     gr70, gr70, gr67        
  20003ec:  1e004644  store    0, 0, gr70, gr68        
  20003f0:  0404027f  mtsrim   CPS, $047f              
  20003f4:  ce000b59  mtsr     PC1, gr89               
  20003f8:  ce000a58  mtsr     PC0, gr88               
  20003fc:  ce000456  mtsr     CHA, gr86               
  2000400:  ce000557  mtsr     CHD, gr87               
  2000404:  ce00065a  mtsr     CHC, gr90               
  2000408:  16005954  load     0, 0, gr89, gr84        
  200040c:  25545404  sub      gr84, gr84, $04         
  2000410:  16005854  load     0, 0, gr88, gr84        
  2000414:  25545404  sub      gr84, gr84, $04         
  2000418:  16005754  load     0, 0, gr87, gr84        
  200041c:  25545404  sub      gr84, gr84, $04         
  2000420:  16005a54  load     0, 0, gr90, gr84        
  2000424:  25545404  sub      gr84, gr84, $04         
  2000428:  16005654  load     0, 0, gr86, gr84        
  200042c:  25545404  sub      gr84, gr84, $04         
  2000430:  16004454  load     0, 0, gr68, gr84        
  2000434:  25545404  sub      gr84, gr84, $04         
  2000438:  16004354  load     0, 0, gr67, gr84        
  200043c:  25545404  sub      gr84, gr84, $04         
  2000440:  16004654  load     0, 0, gr70, gr84        
L_2000444:
  2000444:  a4004009  jmpf     gr64, $2000468             ; -> L_2000468
  2000448:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  200044c:  c6540600  mfsr     gr84, CHC               
  2000450:  9d545401  andn     gr84, gr84, $01         
  2000454:  ce000654  mtsr     CHC, gr84               
  2000458:  ce000b79  mtsr     PC1, gr121              
  200045c:  15547904  add      gr84, gr121, $04        
  2000460:  ce000a54  mtsr     PC0, gr84               
  2000464:  8c000000  iretinv                          
L_2000468:
  2000468:  c6550600  mfsr     gr85, CHC               
  200046c:  83545518  srl      gr84, gr85, $18         
  2000470:  91545403  and      gr84, gr84, $03         
  2000474:  03004402  const    gr68, $0002             
  2000478:  80444454  sll      gr68, gr68, gr84        
  200047c:  83545510  srl      gr84, gr85, $10         
  2000480:  9154540f  and      gr84, gr84, $0f         
  2000484:  15545401  add      gr84, gr84, $01         
  2000488:  24434454  sub      gr67, gr68, gr84        
  200048c:  25444401  sub      gr68, gr68, $01         
  2000490:  81444410  sll      gr68, gr68, $10         
  2000494:  03005400  const    gr84, $0000             
  2000498:  020054ff  consth   gr84, $00ff             
  200049c:  9c555554  andn     gr85, gr85, gr84        
  20004a0:  92555544  or       gr85, gr85, gr68        
  20004a4:  93555501  or       gr85, gr85, $01         
  20004a8:  83545502  srl      gr84, gr85, $02         
  20004ac:  915454ff  and      gr84, gr84, $ff         
  20004b0:  24545443  sub      gr84, gr84, gr67        
  20004b4:  c6448100  mfsr     gr68, IPA               
  20004b8:  81545402  sll      gr84, gr84, $02         
  20004bc:  ce008154  mtsr     IPA, gr84               
  20004c0:  70400101  aseq     trap64, gr1, gr1        
  20004c4:  81510000  sll      gr81, gr0, $00          
  20004c8:  ce000551  mtsr     CHD, gr81               
  20004cc:  ce008144  mtsr     IPA, gr68               
  20004d0:  030344fc  const    gr68, $03fc             
  20004d4:  9c555544  andn     gr85, gr85, gr68        
  20004d8:  92555554  or       gr85, gr85, gr84        
  20004dc:  ce000655  mtsr     CHC, gr85               
  20004e0:  81434302  sll      gr67, gr67, $02         
  20004e4:  c6540400  mfsr     gr84, CHA               
  20004e8:  24545443  sub      gr84, gr84, gr67        
  20004ec:  ce000454  mtsr     CHA, gr84               
  20004f0:  88000000  iret                             
  20004f4:  15825800  add      lr2, gr88, $00          
  20004f8:  15835900  add      lr3, gr89, $00          
  20004fc:  c6470100  mfsr     gr71, OPS               
  2000500:  91474701  and      gr71, gr71, $01         
  2000504:  61474700  cpeq     gr71, gr71, $00         
  2000508:  a4004704  jmpf     gr71, $2000518             ; -> L_2000518
  200050c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000510:  c6820a00  mfsr     lr2, PC0                
  2000514:  c6830b00  mfsr     lr3, PC1                
L_2000518:
  2000518:  a0080054  jmp      $2002668                   ; -> L_2002668
  200051c:  03004d95  const    gr77, $0095                ; [delay slot]
  2000520:  c6540600  mfsr     gr84, CHC               
  2000524:  81555415  sll      gr85, gr84, $15         
  2000528:  a4005504  jmpf     gr85, $2000538             ; -> L_2000538
  200052c:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2000530:  ce000654  mtsr     CHC, gr84               
  2000534:  88000000  iret                             
L_2000538:
  2000538:  c6440b00  mfsr     gr68, PC1               
  200053c:  614d4400  cpeq     gr77, gr68, $00         
  2000540:  ac084d4a  jmpt     gr77, $2002668             ; -> L_2002668
  2000544:  03004d95  const    gr77, $0095                ; [delay slot]
  2000548:  8344440a  srl      gr68, gr68, $0a         
  200054c:  914d441f  and      gr77, gr68, $1f         
  2000550:  8144440a  sll      gr68, gr68, $0a         
  2000554:  03284818  const    gr72, $2818             
  2000558:  024c4800  consth   gr72, $4c00             
  200055c:  81474d02  sll      gr71, gr77, $02         
  2000560:  14474847  add      gr71, gr72, gr71        
  2000564:  16004c47  load     0, 0, gr76, gr71        
  2000568:  15484c00  add      gr72, gr76, $00         
L_200056c:
  200056c:  61474800  cpeq     gr71, gr72, $00         
  2000570:  ac054789  jmpt     gr71, $2001b94             ; -> L_2001b94
  2000574:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000578:  154c4800  add      gr76, gr72, $00         
  200057c:  1600474c  load     0, 0, gr71, gr76        
  2000580:  60474744  cpeq     gr71, gr71, gr68        
  2000584:  ac004704  jmpt     gr71, $2000594             ; -> L_2000594
  2000588:  15474c0c  add      gr71, gr76, $0c            ; [delay slot]
  200058c:  a0ff00f8  jmp      $200056c                   ; -> L_200056c
  2000590:  16004847  load     0, 0, gr72, gr71           ; [delay slot]
L_2000594:
  2000594:  15494c04  add      gr73, gr76, $04         
  2000598:  16004349  load     0, 0, gr67, gr73        
L_200059c:
  200059c:  03805100  const    gr81, $8000             
  20005a0:  02ff51ff  consth   gr81, $ffff             
  20005a4:  90445144  and      gr68, gr81, gr68        
  20005a8:  03495100  const    gr81, $4900             
  20005ac:  92445144  or       gr68, gr81, gr68        
  20005b0:  c6510e00  mfsr     gr81, LRU               
  20005b4:  be005144  mttlb    gr81, gr68              
  20005b8:  15515101  add      gr81, gr81, $01         
  20005bc:  be005143  mttlb    gr81, gr67              
  20005c0:  8c000000  iretinv                          
  20005c4:  c64a0e00  mfsr     gr74, LRU               
  20005c8:  c6440400  mfsr     gr68, CHA               
  20005cc:  03804c00  const    gr76, $8000             
  20005d0:  02ff4cff  consth   gr76, $ffff             
  20005d4:  9043444c  and      gr67, gr68, gr76        
  20005d8:  03764c00  const    gr76, $7600             
  20005dc:  92434c43  or       gr67, gr76, gr67        
  20005e0:  be004a43  mttlb    gr74, gr67              
  20005e4:  154a4a01  add      gr74, gr74, $01         
  20005e8:  01fc4300  constn   gr67, $fc00             
  20005ec:  90444443  and      gr68, gr68, gr67        
  20005f0:  8347441c  srl      gr71, gr68, $1c         
  20005f4:  15474710  add      gr71, gr71, $10         
  20005f8:  03004801  const    gr72, $0001             
  20005fc:  80484847  sll      gr72, gr72, gr71        
  2000600:  9048485b  and      gr72, gr72, gr91        
  2000604:  61484800  cpeq     gr72, gr72, $00         
  2000608:  ac00481f  jmpt     gr72, $2000684             ; -> L_2000684
  200060c:  81474004  sll      gr71, gr64, $04            ; [delay slot]
  2000610:  a400471d  jmpf     gr71, $2000684             ; -> L_2000684
  2000614:  03034cff  const    gr76, $03ff                ; [delay slot]
  2000618:  904c5b4c  and      gr76, gr91, gr76        
  200061c:  03314d6c  const    gr77, $316c             
  2000620:  024c4d00  consth   gr77, $4c00             
L_2000624:
  2000624:  254c4c01  sub      gr76, gr76, $01         
  2000628:  ac004c17  jmpt     gr76, $2000684             ; -> L_2000684
  200062c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000630:  1600514d  load     0, 0, gr81, gr77        
  2000634:  154d4d04  add      gr77, gr77, $04         
  2000638:  60454451  cpeq     gr69, gr68, gr81        
  200063c:  ac00450f  jmpt     gr69, $2000678             ; -> L_2000678
  2000640:  42454451  cpltu    gr69, gr68, gr81           ; [delay slot]
  2000644:  ac004507  jmpt     gr69, $2000660             ; -> L_2000660
  2000648:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  200064c:  1600434d  load     0, 0, gr67, gr77        
  2000650:  14435143  add      gr67, gr81, gr67        
  2000654:  42454443  cpltu    gr69, gr68, gr67        
  2000658:  ac004504  jmpt     gr69, $2000668             ; -> L_2000668
  200065c:  24434451  sub      gr67, gr68, gr81           ; [delay slot]
L_2000660:
  2000660:  a0ff00f1  jmp      $2000624                   ; -> L_2000624
  2000664:  154d4d08  add      gr77, gr77, $08            ; [delay slot]
L_2000668:
  2000668:  154d4d04  add      gr77, gr77, $04         
  200066c:  1600444d  load     0, 0, gr68, gr77        
  2000670:  a0000036  jmp      $2000748                   ; -> L_2000748
  2000674:  14444443  add      gr68, gr68, gr67           ; [delay slot]
L_2000678:
  2000678:  154d4d04  add      gr77, gr77, $04         
  200067c:  a0000033  jmp      $2000748                   ; -> L_2000748
  2000680:  1600444d  load     0, 0, gr68, gr77           ; [delay slot]
L_2000684:
  2000684:  81484001  sll      gr72, gr64, $01         
  2000688:  a4004830  jmpf     gr72, $2000748             ; -> L_2000748
  200068c:  036747dc  const    gr71, $67dc                ; [delay slot]
  2000690:  024c4700  consth   gr71, $4c00             
  2000694:  c6440400  mfsr     gr68, CHA               
  2000698:  16004347  load     0, 0, gr67, gr71        
  200069c:  036747d8  const    gr71, $67d8             
  20006a0:  024c4700  consth   gr71, $4c00             
  20006a4:  16004747  load     0, 0, gr71, gr71        
  20006a8:  8348471c  srl      gr72, gr71, $1c         
  20006ac:  03ff4bff  const    gr75, $ffff             
  20006b0:  020f4bff  consth   gr75, $0fff             
  20006b4:  61484804  cpeq     gr72, gr72, $04         
  20006b8:  a4004804  jmpf     gr72, $20006c8             ; -> L_20006c8
  20006bc:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20006c0:  9047474b  and      gr71, gr71, gr75        
  20006c4:  92474742  or       gr71, gr71, gr66        
L_20006c8:
  20006c8:  c6490400  mfsr     gr73, CHA               
  20006cc:  8348491c  srl      gr72, gr73, $1c         
  20006d0:  61484804  cpeq     gr72, gr72, $04         
  20006d4:  a4004804  jmpf     gr72, $20006e4             ; -> L_20006e4
  20006d8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20006dc:  9049494b  and      gr73, gr73, gr75        
  20006e0:  92494942  or       gr73, gr73, gr66        
L_20006e4:
  20006e4:  42484947  cpltu    gr72, gr73, gr71        
  20006e8:  ac00480a  jmpt     gr72, $2000710             ; -> L_2000710
  20006ec:  14474743  add      gr71, gr71, gr67           ; [delay slot]
  20006f0:  4a484947  cpgtu    gr72, gr73, gr71        
  20006f4:  ac004807  jmpt     gr72, $2000710             ; -> L_2000710
  20006f8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20006fc:  8344440a  srl      gr68, gr68, $0a         
  2000700:  8144440a  sll      gr68, gr68, $0a         
  2000704:  be004a44  mttlb    gr74, gr68              
  2000708:  a00700d8  jmp      $2002668                   ; -> L_2002668
  200070c:  03004da6  const    gr77, $00a6                ; [delay slot]
L_2000710:
  2000710:  8344440a  srl      gr68, gr68, $0a         
  2000714:  8144440a  sll      gr68, gr68, $0a         
  2000718:  036148c8  const    gr72, $61c8             
  200071c:  024c4800  consth   gr72, $4c00             
  2000720:  01ff47ff  constn   gr71, $ffff             
  2000724:  1e004748  store    0, 0, gr71, gr72        
  2000728:  036148cc  const    gr72, $61cc             
  200072c:  024c4800  consth   gr72, $4c00             
  2000730:  25474601  sub      gr71, gr70, $01         
  2000734:  1e004748  store    0, 0, gr71, gr72        
  2000738:  c6470100  mfsr     gr71, OPS               
  200073c:  03204b00  const    gr75, $2000             
  2000740:  9247474b  or       gr71, gr71, gr75        
  2000744:  ce000147  mtsr     OPS, gr71               
L_2000748:
  2000748:  be004a44  mttlb    gr74, gr68              
  200074c:  88000000  iret                             
  2000750:  a00700c6  jmp      $2002668                   ; -> L_2002668
  2000754:  03004d95  const    gr77, $0095                ; [delay slot]
  2000758:  81474001  sll      gr71, gr64, $01         
  200075c:  a4004714  jmpf     gr71, $20007ac             ; -> L_20007ac
  2000760:  036147c8  const    gr71, $61c8                ; [delay slot]
  2000764:  024c4700  consth   gr71, $4c00             
  2000768:  16004847  load     0, 0, gr72, gr71        
  200076c:  a4004810  jmpf     gr72, $20007ac             ; -> L_20007ac
  2000770:  036149cc  const    gr73, $61cc                ; [delay slot]
  2000774:  024c4900  consth   gr73, $4c00             
  2000778:  16004949  load     0, 0, gr73, gr73        
  200077c:  15494901  add      gr73, gr73, $01         
  2000780:  604b4948  cpeq     gr75, gr73, gr72        
  2000784:  ac004b04  jmpt     gr75, $2000794             ; -> L_2000794
  2000788:  25484840  sub      gr72, gr72, $40            ; [delay slot]
  200078c:  604b4948  cpeq     gr75, gr73, gr72        
  2000790:  a4004b07  jmpf     gr75, $20007ac             ; -> L_20007ac
L_2000794:
  2000794:  03004600  const    gr70, $0000                ; [delay slot]
  2000798:  1e004647  store    0, 0, gr70, gr71        
  200079c:  c6460100  mfsr     gr70, OPS               
  20007a0:  03204900  const    gr73, $2000             
  20007a4:  9c464649  andn     gr70, gr70, gr73        
  20007a8:  ce000146  mtsr     OPS, gr70               
L_20007ac:
  20007ac:  88000000  iret                             
  20007b0:  a00700ae  jmp      $2002668                   ; -> L_2002668
  20007b4:  03004d9c  const    gr77, $009c                ; [delay slot]
  20007b8:  81474010  sll      gr71, gr64, $10         
  20007bc:  ac004704  jmpt     gr71, $20007cc             ; -> L_20007cc
  20007c0:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20007c4:  a00700a9  jmp      $2002668                   ; -> L_2002668
  20007c8:  03004d93  const    gr77, $0093                ; [delay slot]
L_20007cc:
  20007cc:  88000000  iret                             
  20007d0:  a00700a6  jmp      $2002668                   ; -> L_2002668
  20007d4:  03004d8f  const    gr77, $008f                ; [delay slot]
  20007d8:  8147401d  sll      gr71, gr64, $1d         
  20007dc:  ac004704  jmpt     gr71, $20007ec             ; -> L_20007ec
  20007e0:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20007e4:  a00700a1  jmp      $2002668                   ; -> L_2002668
  20007e8:  03004d9d  const    gr77, $009d                ; [delay slot]
L_20007ec:
  20007ec:  88000000  iret                             
  20007f0:  c6540600  mfsr     gr84, CHC               
  20007f4:  81555415  sll      gr85, gr84, $15         
  20007f8:  a4005504  jmpf     gr85, $2000808             ; -> L_2000808
  20007fc:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2000800:  ce000654  mtsr     CHC, gr84               
  2000804:  88000000  iret                             
L_2000808:
  2000808:  a0070098  jmp      $2002668                   ; -> L_2002668
  200080c:  03004d9c  const    gr77, $009c                ; [delay slot]
  2000810:  c6540600  mfsr     gr84, CHC               
  2000814:  81555415  sll      gr85, gr84, $15         
  2000818:  a4005504  jmpf     gr85, $2000828             ; -> L_2000828
  200081c:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2000820:  ce000654  mtsr     CHC, gr84               
  2000824:  88000000  iret                             
L_2000828:
  2000828:  8146400f  sll      gr70, gr64, $0f         
  200082c:  a4004608  jmpf     gr70, $200084c             ; -> L_200084c
  2000830:  036146bc  const    gr70, $61bc                ; [delay slot]
  2000834:  024c4600  consth   gr70, $4c00             
  2000838:  16004646  load     0, 0, gr70, gr70        
  200083c:  a4004604  jmpf     gr70, $200084c             ; -> L_200084c
  2000840:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000844:  a807466c  call     gr70, $20025f4             ; -> L_20025f4
  2000848:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_200084c:
  200084c:  03754730  const    gr71, $7530             
  2000850:  02014700  consth   gr71, $0100             
  2000854:  ce000947  mtsr     TMR, gr71               
  2000858:  03684830  const    gr72, $6830             
  200085c:  024c4800  consth   gr72, $4c00             
  2000860:  16004948  load     0, 0, gr73, gr72        
  2000864:  15494901  add      gr73, gr73, $01         
  2000868:  1e004948  store    0, 0, gr73, gr72        
  200086c:  03ff46ff  const    gr70, $ffff             
  2000870:  90464946  and      gr70, gr73, gr70        
  2000874:  61464600  cpeq     gr70, gr70, $00         
  2000878:  a4004608  jmpf     gr70, $2000898             ; -> L_2000898
  200087c:  0364463c  const    gr70, $643c                ; [delay slot]
  2000880:  024c4600  consth   gr70, $4c00             
  2000884:  16004746  load     0, 0, gr71, gr70        
  2000888:  81474710  sll      gr71, gr71, $10         
  200088c:  03004600  const    gr70, $0000             
  2000890:  02464600  consth   gr70, $4600             
  2000894:  1e004746  store    0, 0, gr71, gr70        
L_2000898:
  2000898:  03684834  const    gr72, $6834             
  200089c:  024c4800  consth   gr72, $4c00             
  20008a0:  16004948  load     0, 0, gr73, gr72        
  20008a4:  03754a30  const    gr74, $7530             
  20008a8:  1449494a  add      gr73, gr73, gr74        
  20008ac:  c64b8400  mfsr     gr75, ALU               
  20008b0:  814b4b15  sll      gr75, gr75, $15         
  20008b4:  ac004b03  jmpt     gr75, $20008c0             ; -> L_20008c0
  20008b8:  1e004948  store    0, 0, gr73, gr72           ; [delay slot]
  20008bc:  88000000  iret                             
L_20008c0:
  20008c0:  15484804  add      gr72, gr72, $04         
  20008c4:  16004948  load     0, 0, gr73, gr72        
  20008c8:  15494901  add      gr73, gr73, $01         
  20008cc:  1e004948  store    0, 0, gr73, gr72        
  20008d0:  88000000  iret                             
  20008d4:  c6540600  mfsr     gr84, CHC               
  20008d8:  81555415  sll      gr85, gr84, $15         
  20008dc:  a4005504  jmpf     gr85, $20008ec             ; -> L_20008ec
  20008e0:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  20008e4:  ce000654  mtsr     CHC, gr84               
  20008e8:  88000000  iret                             
L_20008ec:
  20008ec:  c6430100  mfsr     gr67, OPS               
  20008f0:  03104500  const    gr69, $1000             
  20008f4:  9c434345  andn     gr67, gr67, gr69        
  20008f8:  81474001  sll      gr71, gr64, $01         
  20008fc:  a4004711  jmpf     gr71, $2000940             ; -> L_2000940
  2000900:  036147c8  const    gr71, $61c8                ; [delay slot]
  2000904:  024c4700  consth   gr71, $4c00             
  2000908:  16004847  load     0, 0, gr72, gr71        
  200090c:  a400480d  jmpf     gr72, $2000940             ; -> L_2000940
  2000910:  03204900  const    gr73, $2000                ; [delay slot]
  2000914:  9c434349  andn     gr67, gr67, gr73        
  2000918:  ce000143  mtsr     OPS, gr67               
  200091c:  03004600  const    gr70, $0000             
  2000920:  1e004647  store    0, 0, gr70, gr71        
  2000924:  036147cc  const    gr71, $61cc             
  2000928:  024c4700  consth   gr71, $4c00             
  200092c:  16004747  load     0, 0, gr71, gr71        
  2000930:  be004746  mttlb    gr71, gr70              
  2000934:  15474701  add      gr71, gr71, $01         
  2000938:  be004746  mttlb    gr71, gr70              
  200093c:  8c000000  iretinv                          
L_2000940:
  2000940:  81474015  sll      gr71, gr64, $15         
  2000944:  ac004704  jmpt     gr71, $2000954             ; -> L_2000954
  2000948:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  200094c:  a0070047  jmp      $2002668                   ; -> L_2002668
  2000950:  03004d9f  const    gr77, $009f                ; [delay slot]
L_2000954:
  2000954:  0368444c  const    gr68, $684c             
  2000958:  024c4400  consth   gr68, $4c00             
  200095c:  16004644  load     0, 0, gr70, gr68        
  2000960:  15464601  add      gr70, gr70, $01         
  2000964:  1e004644  store    0, 0, gr70, gr68        
  2000968:  03204500  const    gr69, $2000             
  200096c:  92434345  or       gr67, gr67, gr69        
  2000970:  ce000143  mtsr     OPS, gr67               
  2000974:  61464600  cpeq     gr70, gr70, $00         
  2000978:  ac004603  jmpt     gr70, $2000984             ; -> L_2000984
  200097c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000980:  88000000  iret                             
L_2000984:
  2000984:  15444404  add      gr68, gr68, $04         
  2000988:  16004644  load     0, 0, gr70, gr68        
  200098c:  15464601  add      gr70, gr70, $01         
  2000990:  1e004644  store    0, 0, gr70, gr68        
  2000994:  88000000  iret                             
  2000998:  c6430a00  mfsr     gr67, PC0               
  200099c:  25434304  sub      gr67, gr67, $04         
  20009a0:  ce000a43  mtsr     PC0, gr67               
  20009a4:  c6430b00  mfsr     gr67, PC1               
  20009a8:  25434304  sub      gr67, gr67, $04         
  20009ac:  ce000b43  mtsr     PC1, gr67               
  20009b0:  a007002e  jmp      $2002668                   ; -> L_2002668
  20009b4:  03004da0  const    gr77, $00a0                ; [delay slot]
  20009b8:  c6540600  mfsr     gr84, CHC               
  20009bc:  81555415  sll      gr85, gr84, $15         
  20009c0:  a4005504  jmpf     gr85, $20009d0             ; -> L_20009d0
  20009c4:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  20009c8:  ce000654  mtsr     CHC, gr84               
  20009cc:  88000000  iret                             
L_20009d0:
  20009d0:  0361477c  const    gr71, $617c             
  20009d4:  024c4700  consth   gr71, $4c00             
  20009d8:  16004847  load     0, 0, gr72, gr71        
  20009dc:  61454800  cpeq     gr69, gr72, $00         
  20009e0:  ac004504  jmpt     gr69, $20009f0             ; -> L_20009f0
  20009e4:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20009e8:  a001005b  jmp      $2000f54                   ; -> L_2000f54
  20009ec:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_20009f0:
  20009f0:  a007001e  jmp      $2002668                   ; -> L_2002668
  20009f4:  03004d96  const    gr77, $0096                ; [delay slot]
  20009f8:  c6540600  mfsr     gr84, CHC               
  20009fc:  81555415  sll      gr85, gr84, $15         
  2000a00:  a4005504  jmpf     gr85, $2000a10             ; -> L_2000a10
  2000a04:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2000a08:  ce000654  mtsr     CHC, gr84               
  2000a0c:  88000000  iret                             
L_2000a10:
  2000a10:  03004758  const    gr71, $0058             
  2000a14:  02444700  consth   gr71, $4400             
  2000a18:  03004600  const    gr70, $0000             
  2000a1c:  1e004647  store    0, 0, gr70, gr71        
  2000a20:  03614780  const    gr71, $6180             
  2000a24:  024c4700  consth   gr71, $4c00             
  2000a28:  16004847  load     0, 0, gr72, gr71        
  2000a2c:  61454800  cpeq     gr69, gr72, $00         
  2000a30:  ac004504  jmpt     gr69, $2000a40             ; -> L_2000a40
  2000a34:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000a38:  a0010047  jmp      $2000f54                   ; -> L_2000f54
  2000a3c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2000a40:
  2000a40:  a007000a  jmp      $2002668                   ; -> L_2002668
  2000a44:  03004d97  const    gr77, $0097                ; [delay slot]
  2000a48:  c6540600  mfsr     gr84, CHC               
  2000a4c:  81555415  sll      gr85, gr84, $15         
  2000a50:  a4005504  jmpf     gr85, $2000a60             ; -> L_2000a60
  2000a54:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2000a58:  ce000654  mtsr     CHC, gr84               
  2000a5c:  88000000  iret                             
L_2000a60:
  2000a60:  03614784  const    gr71, $6184             
  2000a64:  024c4700  consth   gr71, $4c00             
  2000a68:  16004847  load     0, 0, gr72, gr71        
  2000a6c:  61474800  cpeq     gr71, gr72, $00         
  2000a70:  ac004712  jmpt     gr71, $2000ab8             ; -> L_2000ab8
  2000a74:  03004600  const    gr70, $0000                ; [delay slot]
  2000a78:  03004764  const    gr71, $0064             
  2000a7c:  02444700  consth   gr71, $4400             
  2000a80:  16004747  load     0, 0, gr71, gr71        
  2000a84:  a4004704  jmpf     gr71, $2000a94             ; -> L_2000a94
  2000a88:  03004750  const    gr71, $0050                ; [delay slot]
  2000a8c:  02444700  consth   gr71, $4400             
  2000a90:  1e004647  store    0, 0, gr70, gr71        
L_2000a94:
  2000a94:  03004768  const    gr71, $0068             
  2000a98:  02444700  consth   gr71, $4400             
  2000a9c:  16004747  load     0, 0, gr71, gr71        
  2000aa0:  a4004704  jmpf     gr71, $2000ab0             ; -> L_2000ab0
  2000aa4:  03004754  const    gr71, $0054                ; [delay slot]
  2000aa8:  02444700  consth   gr71, $4400             
  2000aac:  1e004647  store    0, 0, gr70, gr71        
L_2000ab0:
  2000ab0:  a0010029  jmp      $2000f54                   ; -> L_2000f54
  2000ab4:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2000ab8:
  2000ab8:  a8004503  call     gr69, $2000ac4             ; -> L_2000ac4
  2000abc:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000ac0:  8c000000  iretinv                          
L_2000ac4:
  2000ac4:  03004600  const    gr70, $0000             
  2000ac8:  03004764  const    gr71, $0064             
  2000acc:  02444700  consth   gr71, $4400             
  2000ad0:  16004747  load     0, 0, gr71, gr71        
  2000ad4:  a401470c  jmpf     gr71, $2000f04             ; -> L_2000f04
  2000ad8:  03004750  const    gr71, $0050                ; [delay slot]
  2000adc:  02444700  consth   gr71, $4400             
  2000ae0:  1e004647  store    0, 0, gr70, gr71        
  2000ae4:  036747d4  const    gr71, $67d4             
  2000ae8:  024c4700  consth   gr71, $4c00             
  2000aec:  16004747  load     0, 0, gr71, gr71        
  2000af0:  ac0447e4  jmpt     gr71, $2001e80             ; -> L_2001e80
  2000af4:  03734700  const    gr71, $7300                ; [delay slot]
  2000af8:  024c4700  consth   gr71, $4c00             
  2000afc:  16004947  load     0, 0, gr73, gr71        
  2000b00:  a4014901  jmpf     gr73, $2000f04             ; -> L_2000f04
  2000b04:  03004600  const    gr70, $0000                ; [delay slot]
  2000b08:  1e004647  store    0, 0, gr70, gr71        
  2000b0c:  8147491f  sll      gr71, gr73, $1f         
  2000b10:  a4004708  jmpf     gr71, $2000b30             ; -> L_2000b30
  2000b14:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000b18:  03734704  const    gr71, $7304             
  2000b1c:  024c4700  consth   gr71, $4c00             
  2000b20:  1e004647  store    0, 0, gr70, gr71        
L_2000b24:
  2000b24:  16004847  load     0, 0, gr72, gr71        
  2000b28:  a4ff48ff  jmpf     gr72, $2000b24             ; -> L_2000b24
  2000b2c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2000b30:
  2000b30:  03735108  const    gr81, $7308             
  2000b34:  024c5100  consth   gr81, $4c00             
  2000b38:  16004a51  load     0, 0, gr74, gr81        
  2000b3c:  15515104  add      gr81, gr81, $04         
  2000b40:  16004b51  load     0, 0, gr75, gr81        
  2000b44:  15515104  add      gr81, gr81, $04         
  2000b48:  16004c51  load     0, 0, gr76, gr81        
  2000b4c:  15515104  add      gr81, gr81, $04         
  2000b50:  16004d51  load     0, 0, gr77, gr81        
  2000b54:  0373511c  const    gr81, $731c             
  2000b58:  024c5100  consth   gr81, $4c00             
  2000b5c:  16004451  load     0, 0, gr68, gr81        
  2000b60:  15474d04  add      gr71, gr77, $04         
  2000b64:  ce008347  mtsr     Q, gr71                 
  2000b68:  65474b00  mul      gr71, gr75, $00         
  2000b6c:  64474b47  mul      gr71, gr75, gr71        
  2000b70:  64474b47  mul      gr71, gr75, gr71        
  2000b74:  64474b47  mul      gr71, gr75, gr71        
  2000b78:  64474b47  mul      gr71, gr75, gr71        
  2000b7c:  64474b47  mul      gr71, gr75, gr71        
  2000b80:  64474b47  mul      gr71, gr75, gr71        
  2000b84:  64474b47  mul      gr71, gr75, gr71        
  2000b88:  64474b47  mul      gr71, gr75, gr71        
  2000b8c:  64474b47  mul      gr71, gr75, gr71        
  2000b90:  64474b47  mul      gr71, gr75, gr71        
  2000b94:  64474b47  mul      gr71, gr75, gr71        
  2000b98:  64474b47  mul      gr71, gr75, gr71        
  2000b9c:  64474b47  mul      gr71, gr75, gr71        
  2000ba0:  64474b47  mul      gr71, gr75, gr71        
  2000ba4:  64474b47  mul      gr71, gr75, gr71        
  2000ba8:  64474b47  mul      gr71, gr75, gr71        
  2000bac:  64474b47  mul      gr71, gr75, gr71        
  2000bb0:  64474b47  mul      gr71, gr75, gr71        
  2000bb4:  64474b47  mul      gr71, gr75, gr71        
  2000bb8:  64474b47  mul      gr71, gr75, gr71        
  2000bbc:  64474b47  mul      gr71, gr75, gr71        
  2000bc0:  64474b47  mul      gr71, gr75, gr71        
  2000bc4:  64474b47  mul      gr71, gr75, gr71        
  2000bc8:  64474b47  mul      gr71, gr75, gr71        
  2000bcc:  64474b47  mul      gr71, gr75, gr71        
  2000bd0:  64474b47  mul      gr71, gr75, gr71        
  2000bd4:  64474b47  mul      gr71, gr75, gr71        
  2000bd8:  64474b47  mul      gr71, gr75, gr71        
  2000bdc:  64474b47  mul      gr71, gr75, gr71        
  2000be0:  64474b47  mul      gr71, gr75, gr71        
  2000be4:  66474b47  mull     gr71, gr75, gr71        
  2000be8:  c6478300  mfsr     gr71, Q                 
  2000bec:  1443474a  add      gr67, gr71, gr74        
  2000bf0:  61474400  cpeq     gr71, gr68, $00         
  2000bf4:  ac0047af  jmpt     gr71, $2000eb0             ; -> L_2000eb0
  2000bf8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000bfc:  03344800  const    gr72, $3400             
  2000c00:  02404800  consth   gr72, $4000             
  2000c04:  81464800  sll      gr70, gr72, $00         
  2000c08:  1e006046  store    0, 0, gr96, gr70        
  2000c0c:  15464604  add      gr70, gr70, $04         
  2000c10:  1e006146  store    0, 0, gr97, gr70        
  2000c14:  15464604  add      gr70, gr70, $04         
  2000c18:  1e006246  store    0, 0, gr98, gr70        
  2000c1c:  15464604  add      gr70, gr70, $04         
  2000c20:  1e006346  store    0, 0, gr99, gr70        
  2000c24:  15464604  add      gr70, gr70, $04         
  2000c28:  1e006446  store    0, 0, gr100, gr70       
  2000c2c:  15464604  add      gr70, gr70, $04         
  2000c30:  1e006546  store    0, 0, gr101, gr70       
  2000c34:  15464604  add      gr70, gr70, $04         
  2000c38:  1e006646  store    0, 0, gr102, gr70       
  2000c3c:  15464604  add      gr70, gr70, $04         
  2000c40:  1e006746  store    0, 0, gr103, gr70       
  2000c44:  15464604  add      gr70, gr70, $04         
  2000c48:  030166fe  const    gr102, $01fe            
  2000c4c:  03006400  const    gr100, $0000            
  2000c50:  024c6400  consth   gr100, $4c00            
  2000c54:  03046500  const    gr101, $0400            
  2000c58:  14654865  add      gr101, gr72, gr101      
  2000c5c:  61474401  cpeq     gr71, gr68, $01         
  2000c60:  ac004737  jmpt     gr71, $2000d3c             ; -> L_2000d3c
  2000c64:  61474402  cpeq     gr71, gr68, $02            ; [delay slot]
  2000c68:  a4004767  jmpf     gr71, $2000e04             ; -> L_2000e04
L_2000c6c:
  2000c6c:  81606400  sll      gr96, gr100, $00           ; [delay slot]
  2000c70:  81616500  sll      gr97, gr101, $00        
  2000c74:  030363fe  const    gr99, $03fe             
L_2000c78:
  2000c78:  16006260  load     0, 0, gr98, gr96        
  2000c7c:  15606004  add      gr96, gr96, $04         
  2000c80:  1e006261  store    0, 0, gr98, gr97        
  2000c84:  b4ff63fd  jmpfdec  gr99, $2000c78             ; -> L_2000c78
  2000c88:  15616104  add      gr97, gr97, $04            ; [delay slot]
  2000c8c:  81606500  sll      gr96, gr101, $00        
  2000c90:  81616400  sll      gr97, gr100, $00        
  2000c94:  030063fe  const    gr99, $00fe             
L_2000c98:
  2000c98:  16006260  load     0, 0, gr98, gr96        
  2000c9c:  15606004  add      gr96, gr96, $04         
  2000ca0:  1e006261  store    0, 0, gr98, gr97        
  2000ca4:  b4ff63fd  jmpfdec  gr99, $2000c98             ; -> L_2000c98
  2000ca8:  15616110  add      gr97, gr97, $10            ; [delay slot]
  2000cac:  15616408  add      gr97, gr100, $08        
  2000cb0:  030063fe  const    gr99, $00fe             
L_2000cb4:
  2000cb4:  16006260  load     0, 0, gr98, gr96        
  2000cb8:  15606004  add      gr96, gr96, $04         
  2000cbc:  1e006261  store    0, 0, gr98, gr97        
  2000cc0:  b4ff63fd  jmpfdec  gr99, $2000cb4             ; -> L_2000cb4
  2000cc4:  15616110  add      gr97, gr97, $10            ; [delay slot]
  2000cc8:  15616404  add      gr97, gr100, $04        
  2000ccc:  030063fe  const    gr99, $00fe             
L_2000cd0:
  2000cd0:  16006260  load     0, 0, gr98, gr96        
  2000cd4:  15606004  add      gr96, gr96, $04         
  2000cd8:  1e006261  store    0, 0, gr98, gr97        
  2000cdc:  b4ff63fd  jmpfdec  gr99, $2000cd0             ; -> L_2000cd0
  2000ce0:  15616110  add      gr97, gr97, $10            ; [delay slot]
  2000ce4:  1561640c  add      gr97, gr100, $0c        
  2000ce8:  030063fe  const    gr99, $00fe             
L_2000cec:
  2000cec:  16006260  load     0, 0, gr98, gr96        
  2000cf0:  15606004  add      gr96, gr96, $04         
  2000cf4:  1e006261  store    0, 0, gr98, gr97        
  2000cf8:  b4ff63fd  jmpfdec  gr99, $2000cec             ; -> L_2000cec
  2000cfc:  15616110  add      gr97, gr97, $10            ; [delay slot]
  2000d00:  03106300  const    gr99, $1000             
  2000d04:  b4ff66da  jmpfdec  gr102, $2000c6c            ; -> L_2000c6c
  2000d08:  14646463  add      gr100, gr100, gr99         ; [delay slot]
L_2000d0c:
  2000d0c:  0300447c  const    gr68, $007c             
  2000d10:  02444400  consth   gr68, $4400             
  2000d14:  16006244  load     0, 0, gr98, gr68        
  2000d18:  a4ff62fd  jmpf     gr98, $2000d0c             ; -> L_2000d0c
L_2000d1c:
  2000d1c:  03004480  const    gr68, $0080                ; [delay slot]
  2000d20:  02444400  consth   gr68, $4400             
  2000d24:  16006244  load     0, 0, gr98, gr68        
  2000d28:  acff62fd  jmpt     gr98, $2000d1c             ; -> L_2000d1c
  2000d2c:  03ff43ff  const    gr67, $ffff                ; [delay slot]
  2000d30:  027f43ff  consth   gr67, $7fff             
  2000d34:  a0000034  jmp      $2000e04                   ; -> L_2000e04
  2000d38:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2000d3c:
  2000d3c:  81606400  sll      gr96, gr100, $00        
  2000d40:  81616500  sll      gr97, gr101, $00        
  2000d44:  030363fe  const    gr99, $03fe             
L_2000d48:
  2000d48:  16006260  load     0, 0, gr98, gr96        
  2000d4c:  15606004  add      gr96, gr96, $04         
  2000d50:  1e006261  store    0, 0, gr98, gr97        
  2000d54:  b4ff63fd  jmpfdec  gr99, $2000d48             ; -> L_2000d48
  2000d58:  15616104  add      gr97, gr97, $04            ; [delay slot]
  2000d5c:  15606500  add      gr96, gr101, $00        
  2000d60:  15616400  add      gr97, gr100, $00        
  2000d64:  030063fe  const    gr99, $00fe             
L_2000d68:
  2000d68:  16006260  load     0, 0, gr98, gr96        
  2000d6c:  15606010  add      gr96, gr96, $10         
  2000d70:  1e006261  store    0, 0, gr98, gr97        
  2000d74:  b4ff63fd  jmpfdec  gr99, $2000d68             ; -> L_2000d68
  2000d78:  15616104  add      gr97, gr97, $04            ; [delay slot]
  2000d7c:  15606508  add      gr96, gr101, $08        
  2000d80:  030063fe  const    gr99, $00fe             
L_2000d84:
  2000d84:  16006260  load     0, 0, gr98, gr96        
  2000d88:  15606010  add      gr96, gr96, $10         
  2000d8c:  1e006261  store    0, 0, gr98, gr97        
  2000d90:  b4ff63fd  jmpfdec  gr99, $2000d84             ; -> L_2000d84
  2000d94:  15616104  add      gr97, gr97, $04            ; [delay slot]
  2000d98:  15606504  add      gr96, gr101, $04        
  2000d9c:  030063fe  const    gr99, $00fe             
L_2000da0:
  2000da0:  16006260  load     0, 0, gr98, gr96        
  2000da4:  15606010  add      gr96, gr96, $10         
  2000da8:  1e006261  store    0, 0, gr98, gr97        
  2000dac:  b4ff63fd  jmpfdec  gr99, $2000da0             ; -> L_2000da0
  2000db0:  15616104  add      gr97, gr97, $04            ; [delay slot]
  2000db4:  1560650c  add      gr96, gr101, $0c        
  2000db8:  030063fe  const    gr99, $00fe             
L_2000dbc:
  2000dbc:  16006260  load     0, 0, gr98, gr96        
  2000dc0:  15606010  add      gr96, gr96, $10         
  2000dc4:  1e006261  store    0, 0, gr98, gr97        
  2000dc8:  b4ff63fd  jmpfdec  gr99, $2000dbc             ; -> L_2000dbc
  2000dcc:  15616104  add      gr97, gr97, $04            ; [delay slot]
  2000dd0:  03106300  const    gr99, $1000             
  2000dd4:  b4ff66da  jmpfdec  gr102, $2000d3c            ; -> L_2000d3c
  2000dd8:  14646463  add      gr100, gr100, gr99         ; [delay slot]
L_2000ddc:
  2000ddc:  0300447c  const    gr68, $007c             
  2000de0:  02444400  consth   gr68, $4400             
  2000de4:  16006244  load     0, 0, gr98, gr68        
  2000de8:  acff62fd  jmpt     gr98, $2000ddc             ; -> L_2000ddc
L_2000dec:
  2000dec:  03004480  const    gr68, $0080                ; [delay slot]
  2000df0:  02444400  consth   gr68, $4400             
  2000df4:  16006244  load     0, 0, gr98, gr68        
  2000df8:  a4ff62fd  jmpf     gr98, $2000dec             ; -> L_2000dec
  2000dfc:  03ff43ff  const    gr67, $ffff                ; [delay slot]
  2000e00:  027f43ff  consth   gr67, $7fff             
L_2000e04:
  2000e04:  03286118  const    gr97, $2818             
  2000e08:  024c6100  consth   gr97, $4c00             
  2000e0c:  0300631e  const    gr99, $001e             
  2000e10:  03004400  const    gr68, $0000             
  2000e14:  03004600  const    gr70, $0000             
L_2000e18:
  2000e18:  1e004661  store    0, 0, gr70, gr97        
  2000e1c:  15616104  add      gr97, gr97, $04         
  2000e20:  be004446  mttlb    gr68, gr70              
  2000e24:  15444402  add      gr68, gr68, $02         
  2000e28:  be004446  mttlb    gr68, gr70              
  2000e2c:  b4ff63fb  jmpfdec  gr99, $2000e18             ; -> L_2000e18
  2000e30:  15444402  add      gr68, gr68, $02            ; [delay slot]
  2000e34:  03006332  const    gr99, $0032             
  2000e38:  032c61a8  const    gr97, $2ca8             
  2000e3c:  024c6100  consth   gr97, $4c00             
L_2000e40:
  2000e40:  1e004661  store    0, 0, gr70, gr97        
  2000e44:  b4ff63ff  jmpfdec  gr99, $2000e40             ; -> L_2000e40
  2000e48:  15616104  add      gr97, gr97, $04            ; [delay slot]
  2000e4c:  03286110  const    gr97, $2810             
  2000e50:  024c6100  consth   gr97, $4c00             
  2000e54:  1e004661  store    0, 0, gr70, gr97        
  2000e58:  81464800  sll      gr70, gr72, $00         
  2000e5c:  16006046  load     0, 0, gr96, gr70        
  2000e60:  15464604  add      gr70, gr70, $04         
  2000e64:  16006146  load     0, 0, gr97, gr70        
  2000e68:  15464604  add      gr70, gr70, $04         
  2000e6c:  16006246  load     0, 0, gr98, gr70        
  2000e70:  15464604  add      gr70, gr70, $04         
  2000e74:  16006346  load     0, 0, gr99, gr70        
  2000e78:  15464604  add      gr70, gr70, $04         
  2000e7c:  16006446  load     0, 0, gr100, gr70       
  2000e80:  15464604  add      gr70, gr70, $04         
  2000e84:  16006546  load     0, 0, gr101, gr70       
  2000e88:  15464604  add      gr70, gr70, $04         
  2000e8c:  16006646  load     0, 0, gr102, gr70       
  2000e90:  15464604  add      gr70, gr70, $04         
  2000e94:  16006746  load     0, 0, gr103, gr70       
  2000e98:  15464604  add      gr70, gr70, $04         
  2000e9c:  03004600  const    gr70, $0000             
  2000ea0:  03734704  const    gr71, $7304             
  2000ea4:  024c4700  consth   gr71, $4c00             
  2000ea8:  a000000b  jmp      $2000ed4                   ; -> L_2000ed4
  2000eac:  1e004647  store    0, 0, gr70, gr71           ; [delay slot]
L_2000eb0:
  2000eb0:  8147491f  sll      gr71, gr73, $1f         
  2000eb4:  ac004708  jmpt     gr71, $2000ed4             ; -> L_2000ed4
  2000eb8:  03004600  const    gr70, $0000                ; [delay slot]
  2000ebc:  03734704  const    gr71, $7304             
  2000ec0:  024c4700  consth   gr71, $4c00             
  2000ec4:  1e004647  store    0, 0, gr70, gr71        
L_2000ec8:
  2000ec8:  16004847  load     0, 0, gr72, gr71        
  2000ecc:  a4ff48ff  jmpf     gr72, $2000ec8             ; -> L_2000ec8
  2000ed0:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2000ed4:
  2000ed4:  0368471c  const    gr71, $681c             
  2000ed8:  024c4700  consth   gr71, $4c00             
  2000edc:  1e004a47  store    0, 0, gr74, gr71        
  2000ee0:  03684724  const    gr71, $6824             
  2000ee4:  024c4700  consth   gr71, $4c00             
  2000ee8:  1e004b47  store    0, 0, gr75, gr71        
  2000eec:  03684720  const    gr71, $6820             
  2000ef0:  024c4700  consth   gr71, $4c00             
  2000ef4:  1e004c47  store    0, 0, gr76, gr71        
  2000ef8:  03684728  const    gr71, $6828             
  2000efc:  024c4700  consth   gr71, $4c00             
  2000f00:  1e004d47  store    0, 0, gr77, gr71        
L_2000f04:
  2000f04:  c0000045  jmpi     gr69                    
  2000f08:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000f0c:  a00500d7  jmp      $2002668                   ; -> L_2002668
  2000f10:  03004d98  const    gr77, $0098                ; [delay slot]
  2000f14:  c6540600  mfsr     gr84, CHC               
  2000f18:  81555415  sll      gr85, gr84, $15         
  2000f1c:  a4005504  jmpf     gr85, $2000f2c             ; -> L_2000f2c
  2000f20:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2000f24:  ce000654  mtsr     CHC, gr84               
  2000f28:  88000000  iret                             
L_2000f2c:
  2000f2c:  03614788  const    gr71, $6188             
  2000f30:  024c4700  consth   gr71, $4c00             
  2000f34:  16004847  load     0, 0, gr72, gr71        
  2000f38:  61454800  cpeq     gr69, gr72, $00         
  2000f3c:  ac004504  jmpt     gr69, $2000f4c             ; -> L_2000f4c
  2000f40:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2000f44:  a0000004  jmp      $2000f54                   ; -> L_2000f54
  2000f48:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2000f4c:
  2000f4c:  a00500c7  jmp      $2002668                   ; -> L_2002668
  2000f50:  03004d99  const    gr77, $0099                ; [delay slot]
L_2000f54:
  2000f54:  0361468c  const    gr70, $618c             
  2000f58:  024c4600  consth   gr70, $4c00             
  2000f5c:  16004746  load     0, 0, gr71, gr70        
  2000f60:  ac004724  jmpt     gr71, $2000ff0             ; -> L_2000ff0
  2000f64:  01ff47ff  constn   gr71, $ffff                ; [delay slot]
  2000f68:  1e004746  store    0, 0, gr71, gr70        
  2000f6c:  15464604  add      gr70, gr70, $04         
  2000f70:  0404027f  mtsrim   CPS, $047f              
  2000f74:  c6580a00  mfsr     gr88, PC0               
  2000f78:  c6590b00  mfsr     gr89, PC1               
  2000f7c:  c6520100  mfsr     gr82, OPS               
  2000f80:  c6560400  mfsr     gr86, CHA               
  2000f84:  c65a0600  mfsr     gr90, CHC               
  2000f88:  c6570500  mfsr     gr87, CHD               
  2000f8c:  1e005846  store    0, 0, gr88, gr70        
  2000f90:  15464604  add      gr70, gr70, $04         
  2000f94:  1e005946  store    0, 0, gr89, gr70        
  2000f98:  15464604  add      gr70, gr70, $04         
  2000f9c:  1e005246  store    0, 0, gr82, gr70        
  2000fa0:  15464604  add      gr70, gr70, $04         
  2000fa4:  1e005646  store    0, 0, gr86, gr70        
  2000fa8:  15464604  add      gr70, gr70, $04         
  2000fac:  1e005a46  store    0, 0, gr90, gr70        
  2000fb0:  15464604  add      gr70, gr70, $04         
  2000fb4:  1e005746  store    0, 0, gr87, gr70        
  2000fb8:  15464604  add      gr70, gr70, $04         
  2000fbc:  1e006046  store    0, 0, gr96, gr70        
  2000fc0:  15464604  add      gr70, gr70, $04         
  2000fc4:  1e006146  store    0, 0, gr97, gr70        
  2000fc8:  15464604  add      gr70, gr70, $04         
  2000fcc:  1e006246  store    0, 0, gr98, gr70        
  2000fd0:  15464604  add      gr70, gr70, $04         
  2000fd4:  1e006346  store    0, 0, gr99, gr70        
  2000fd8:  15464604  add      gr70, gr70, $04         
  2000fdc:  0408016e  mtsrim   OPS, $086e              
  2000fe0:  ce000b48  mtsr     PC1, gr72               
  2000fe4:  15484804  add      gr72, gr72, $04         
  2000fe8:  ce000a48  mtsr     PC0, gr72               
  2000fec:  88000000  iret                             
L_2000ff0:
  2000ff0:  88000000  iret                             
  2000ff4:  c6540600  mfsr     gr84, CHC               
  2000ff8:  81555415  sll      gr85, gr84, $15         
  2000ffc:  a4005504  jmpf     gr85, $200100c             ; -> L_200100c
  2001000:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2001004:  ce000654  mtsr     CHC, gr84               
  2001008:  88000000  iret                             
L_200100c:
  200100c:  a0050097  jmp      $2002668                   ; -> L_2002668
  2001010:  03004d9a  const    gr77, $009a                ; [delay slot]
  2001014:  c6540600  mfsr     gr84, CHC               
  2001018:  81555415  sll      gr85, gr84, $15         
  200101c:  a4005504  jmpf     gr85, $200102c             ; -> L_200102c
  2001020:  9d545401  andn     gr84, gr84, $01            ; [delay slot]
  2001024:  ce000654  mtsr     CHC, gr84               
  2001028:  88000000  iret                             
L_200102c:
  200102c:  a005008f  jmp      $2002668                   ; -> L_2002668
  2001030:  03004d9b  const    gr77, $009b                ; [delay slot]
  2001034:  24797e01  sub      gr121, gr126, gr1       
  2001038:  247e7f79  sub      gr126, gr127, gr121     
  200103c:  46457e41  cpleu    gr69, gr126, gr65       
  2001040:  ac004508  jmpt     gr69, $2001060             ; -> L_2001060
  2001044:  83797902  srl      gr121, gr121, $02          ; [delay slot]
  2001048:  25797901  sub      gr121, gr121, $01       
  200104c:  ce008779  mtsr     CR, gr121               
  2001050:  3e00807e  storem   0, 0, lr0, gr126        
  2001054:  817f7e00  sll      gr127, gr126, $00       
  2001058:  817e0100  sll      gr126, gr1, $00         
  200105c:  88000000  iret                             
L_2001060:
  2001060:  a0050082  jmp      $2002668                   ; -> L_2002668
  2001064:  03004da5  const    gr77, $00a5                ; [delay slot]
  2001068:  03027900  const    gr121, $0200            
  200106c:  9279797f  or       gr121, gr121, gr127     
  2001070:  ce008179  mtsr     IPA, gr121              
  2001074:  2479817f  sub      gr121, lr1, gr127       
  2001078:  147e7e79  add      gr126, gr126, gr121     
  200107c:  83797902  srl      gr121, gr121, $02       
  2001080:  25797901  sub      gr121, gr121, $01       
  2001084:  ce008779  mtsr     CR, gr121               
  2001088:  81797f00  sll      gr121, gr127, $00       
  200108c:  817f8100  sll      gr127, lr1, $00         
  2001090:  36000079  loadm    0, 0, gr0, gr121        
  2001094:  88000000  iret                             
  2001098:  157a7900  add      gr122, gr121, $00       
  200109c:  257a7ab6  sub      gr122, gr122, $b6       
  20010a0:  ac007a0a  jmpt     gr122, $20010c8            ; -> L_20010c8
  20010a4:  4d797ad5  cpge     gr121, gr122, $d5          ; [delay slot]
  20010a8:  ac007908  jmpt     gr121, $20010c8            ; -> L_20010c8
  20010ac:  817a7a02  sll      gr122, gr122, $02          ; [delay slot]
  20010b0:  03254600  const    gr70, $2500             
  20010b4:  024c4600  consth   gr70, $4c00             
  20010b8:  147a467a  add      gr122, gr70, gr122      
  20010bc:  16007a7a  load     0, 0, gr122, gr122      
  20010c0:  c000007a  jmpi     gr122                   
  20010c4:  60797979  cpeq     gr121, gr121, gr121        ; [delay slot]
L_20010c8:
  20010c8:  01ff60d6  constn   gr96, $ffd6             
  20010cc:  03007900  const    gr121, $0000            
  20010d0:  88000000  iret                             
  20010d4:  03004754  const    gr71, $0054             
  20010d8:  02444700  consth   gr71, $4400             
  20010dc:  02ff48ff  consth   gr72, $ffff             
  20010e0:  1e004847  store    0, 0, gr72, gr71        
  20010e4:  03004968  const    gr73, $0068             
  20010e8:  02444900  consth   gr73, $4400             
L_20010ec:
  20010ec:  16004a49  load     0, 0, gr74, gr73        
  20010f0:  a4ff4aff  jmpf     gr74, $20010ec             ; -> L_20010ec
  20010f4:  03004800  const    gr72, $0000                ; [delay slot]
  20010f8:  1e004847  store    0, 0, gr72, gr71        
  20010fc:  88000000  iret                             
  2001100:  0368472c  const    gr71, $682c             
  2001104:  024c4700  consth   gr71, $4c00             
  2001108:  16006047  load     0, 0, gr96, gr71        
  200110c:  88000000  iret                             
  2001110:  0364463c  const    gr70, $643c             
  2001114:  024c4600  consth   gr70, $4c00             
  2001118:  16006046  load     0, 0, gr96, gr70        
  200111c:  ac008209  jmpt     lr2, $2001140              ; -> L_2001140
  2001120:  03004701  const    gr71, $0001                ; [delay slot]
  2001124:  80474782  sll      gr71, gr71, lr2         
  2001128:  9c476047  andn     gr71, gr96, gr71        
  200112c:  1e004746  store    0, 0, gr71, gr70        
  2001130:  81474710  sll      gr71, gr71, $10         
  2001134:  03004600  const    gr70, $0000             
  2001138:  02464600  consth   gr70, $4600             
  200113c:  1e004746  store    0, 0, gr71, gr70        
L_2001140:
  2001140:  88000000  iret                             
  2001144:  81474003  sll      gr71, gr64, $03         
  2001148:  a4004704  jmpf     gr71, $2001158             ; -> L_2001158
  200114c:  03006000  const    gr96, $0000                ; [delay slot]
  2001150:  a003004c  jmp      $2001e80                   ; -> L_2001e80
  2001154:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2001158:
  2001158:  88000000  iret                             
  200115c:  8145400b  sll      gr69, gr64, $0b         
  2001160:  ac004506  jmpt     gr69, $2001178             ; -> L_2001178
  2001164:  03304500  const    gr69, $3000                ; [delay slot]
  2001168:  02004500  consth   gr69, $0000             
  200116c:  24447f45  sub      gr68, gr127, gr69       
  2001170:  24604441  sub      gr96, gr68, gr65        
  2001174:  88000000  iret                             
L_2001178:
  2001178:  03644408  const    gr68, $6408             
  200117c:  024c4400  consth   gr68, $4c00             
  2001180:  16004444  load     0, 0, gr68, gr68        
  2001184:  03104300  const    gr67, $1000             
  2001188:  02004300  consth   gr67, $0000             
  200118c:  24444443  sub      gr68, gr68, gr67        
  2001190:  24604441  sub      gr96, gr68, gr65        
  2001194:  88000000  iret                             
  2001198:  03004680  const    gr70, $0080             
  200119c:  02444600  consth   gr70, $4400             
  20011a0:  16004646  load     0, 0, gr70, gr70        
  20011a4:  a4004604  jmpf     gr70, $20011b4             ; -> L_20011b4
  20011a8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20011ac:  83828201  srl      lr2, lr2, $01           
  20011b0:  83848401  srl      lr4, lr4, $01           
L_20011b4:
  20011b4:  61468200  cpeq     gr70, lr2, $00          
  20011b8:  ac00460b  jmpt     gr70, $20011e4             ; -> L_20011e4
  20011bc:  0368461c  const    gr70, $681c                ; [delay slot]
  20011c0:  024c4600  consth   gr70, $4c00             
  20011c4:  1e008246  store    0, 0, lr2, gr70         
  20011c8:  03004600  const    gr70, $0000             
  20011cc:  02444600  consth   gr70, $4400             
  20011d0:  8148820a  sll      gr72, lr2, $0a          
  20011d4:  03004712  const    gr71, $0012             
L_20011d8:
  20011d8:  1e004846  store    0, 0, gr72, gr70        
  20011dc:  b4ff47ff  jmpfdec  gr71, $20011d8             ; -> L_20011d8
  20011e0:  81484801  sll      gr72, gr72, $01            ; [delay slot]
L_20011e4:
  20011e4:  61468400  cpeq     gr70, lr4, $00          
  20011e8:  ac00460b  jmpt     gr70, $2001214             ; -> L_2001214
  20011ec:  03684624  const    gr70, $6824                ; [delay slot]
  20011f0:  024c4600  consth   gr70, $4c00             
  20011f4:  1e008446  store    0, 0, lr4, gr70         
  20011f8:  030046a0  const    gr70, $00a0             
  20011fc:  02444600  consth   gr70, $4400             
  2001200:  81488412  sll      gr72, lr4, $12          
  2001204:  0300470a  const    gr71, $000a             
L_2001208:
  2001208:  1e004846  store    0, 0, gr72, gr70        
  200120c:  b4ff47ff  jmpfdec  gr71, $2001208             ; -> L_2001208
  2001210:  81484801  sll      gr72, gr72, $01            ; [delay slot]
L_2001214:
  2001214:  03006000  const    gr96, $0000             
  2001218:  88000000  iret                             
  200121c:  01ff60ff  constn   gr96, $ffff             
  2001220:  88000000  iret                             
  2001224:  04008500  mtsrim   BP, $0000               
  2001228:  03004700  const    gr71, $0000             
  200122c:  024647c0  consth   gr71, $46c0             
  2001230:  0c488282  inbyte   gr72, lr2, lr2          
  2001234:  1e014847  store    0, 1, gr72, gr71        
  2001238:  03004704  const    gr71, $0004             
  200123c:  024647c0  consth   gr71, $46c0             
  2001240:  0c488383  inbyte   gr72, lr3, lr3          
  2001244:  1e014847  store    0, 1, gr72, gr71        
  2001248:  0c488484  inbyte   gr72, lr4, lr4          
  200124c:  1e014847  store    0, 1, gr72, gr71        
  2001250:  0c488585  inbyte   gr72, lr5, lr5          
  2001254:  1e014847  store    0, 1, gr72, gr71        
  2001258:  88000000  iret                             
  200125c:  494782ff  cpgt     gr71, lr2, $ff          
  2001260:  ac004715  jmpt     gr71, $20012b4             ; -> L_20012b4
  2001264:  01ff60ff  constn   gr96, $ffff                ; [delay slot]
  2001268:  03004900  const    gr73, $0000             
  200126c:  02ff4900  consth   gr73, $ff00             
  2001270:  04008500  mtsrim   BP, $0000               
  2001274:  03004700  const    gr71, $0000             
  2001278:  024647c0  consth   gr71, $46c0             
  200127c:  0c488282  inbyte   gr72, lr2, lr2          
  2001280:  1e014847  store    0, 1, gr72, gr71        
  2001284:  03004704  const    gr71, $0004             
  2001288:  024647c0  consth   gr71, $46c0             
  200128c:  16006047  load     0, 0, gr96, gr71        
  2001290:  83606008  srl      gr96, gr96, $08         
  2001294:  16004847  load     0, 0, gr72, gr71        
  2001298:  90484849  and      gr72, gr72, gr73        
  200129c:  92606048  or       gr96, gr96, gr72        
  20012a0:  83606008  srl      gr96, gr96, $08         
  20012a4:  16004847  load     0, 0, gr72, gr71        
  20012a8:  90484849  and      gr72, gr72, gr73        
  20012ac:  92606048  or       gr96, gr96, gr72        
  20012b0:  83606008  srl      gr96, gr96, $08         
L_20012b4:
  20012b4:  88000000  iret                             
  20012b8:  03646000  const    gr96, $6400             
  20012bc:  024c6000  consth   gr96, $4c00             
  20012c0:  88000000  iret                             
  20012c4:  8145400b  sll      gr69, gr64, $0b         
  20012c8:  a4004510  jmpf     gr69, $2001308             ; -> L_2001308
  20012cc:  03006000  const    gr96, $0000                ; [delay slot]
  20012d0:  03314620  const    gr70, $3120             
  20012d4:  024c4600  consth   gr70, $4c00             
  20012d8:  16004746  load     0, 0, gr71, gr70        
  20012dc:  14494782  add      gr73, gr71, lr2         
  20012e0:  1e004946  store    0, 0, gr73, gr70        
  20012e4:  03ff45ff  const    gr69, $ffff             
  20012e8:  020f45ff  consth   gr69, $0fff             
  20012ec:  90494945  and      gr73, gr73, gr69        
  20012f0:  03004500  const    gr69, $0000             
  20012f4:  020c4500  consth   gr69, $0c00             
  20012f8:  42454945  cpltu    gr69, gr73, gr69        
  20012fc:  a4004503  jmpf     gr69, $2001308             ; -> L_2001308
  2001300:  03006000  const    gr96, $0000                ; [delay slot]
  2001304:  15604700  add      gr96, gr71, $00         
L_2001308:
  2001308:  88000000  iret                             
  200130c:  01ff60d6  constn   gr96, $ffd6             
  2001310:  88000000  iret                             
  2001314:  01ff60d6  constn   gr96, $ffd6             
  2001318:  88000000  iret                             
  200131c:  a8004503  call     gr69, $2001328             ; -> L_2001328
  2001320:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001324:  88000000  iret                             
L_2001328:
  2001328:  01fc4300  constn   gr67, $fc00             
  200132c:  90468243  and      gr70, lr2, gr67         
  2001330:  60464682  cpeq     gr70, gr70, lr2         
  2001334:  a400465d  jmpf     gr70, $20014a8             ; -> L_20014a8
  2001338:  01fc4300  constn   gr67, $fc00                ; [delay slot]
  200133c:  90468343  and      gr70, lr3, gr67         
  2001340:  60464683  cpeq     gr70, gr70, lr3         
  2001344:  a4004657  jmpf     gr70, $20014a0             ; -> L_20014a0
  2001348:  01fc4300  constn   gr67, $fc00                ; [delay slot]
  200134c:  90468443  and      gr70, lr4, gr67         
  2001350:  60464684  cpeq     gr70, gr70, lr4         
  2001354:  a4004651  jmpf     gr70, $2001498             ; -> L_2001498
  2001358:  03314c68  const    gr76, $3168                ; [delay slot]
  200135c:  024c4c00  consth   gr76, $4c00             
  2001360:  16004a4c  load     0, 0, gr74, gr76        
  2001364:  61474a00  cpeq     gr71, gr74, $00         
  2001368:  a4004704  jmpf     gr71, $2001378             ; -> L_2001378
  200136c:  03004700  const    gr71, $0000                ; [delay slot]
  2001370:  02084700  consth   gr71, $0800             
  2001374:  92404047  or       gr64, gr64, gr71        
L_2001378:
  2001378:  030347ff  const    gr71, $03ff             
  200137c:  4c474a47  cpge     gr71, gr74, gr71        
  2001380:  ac00474c  jmpt     gr71, $20014b0             ; -> L_20014b0
  2001384:  0331496c  const    gr73, $316c                ; [delay slot]
  2001388:  024c4900  consth   gr73, $4c00             
  200138c:  81474a02  sll      gr71, gr74, $02         
  2001390:  81464a03  sll      gr70, gr74, $03         
  2001394:  144b4647  add      gr75, gr70, gr71        
  2001398:  144b494b  add      gr75, gr73, gr75        
  200139c:  61484a00  cpeq     gr72, gr74, $00         
  20013a0:  ac004816  jmpt     gr72, $20013f8             ; -> L_20013f8
  20013a4:  81474900  sll      gr71, gr73, $00            ; [delay slot]
L_20013a8:
  20013a8:  16004647  load     0, 0, gr70, gr71        
  20013ac:  42488246  cpltu    gr72, lr2, gr70         
  20013b0:  ac00480e  jmpt     gr72, $20013e8             ; -> L_20013e8
  20013b4:  15484704  add      gr72, gr71, $04            ; [delay slot]
  20013b8:  16004848  load     0, 0, gr72, gr72        
  20013bc:  14484648  add      gr72, gr70, gr72        
  20013c0:  4e488248  cpgeu    gr72, lr2, gr72         
  20013c4:  ac004809  jmpt     gr72, $20013e8             ; -> L_20013e8
  20013c8:  15484708  add      gr72, gr71, $08            ; [delay slot]
  20013cc:  16004d48  load     0, 0, gr77, gr72        
  20013d0:  24488246  sub      gr72, lr2, gr70         
  20013d4:  14484d48  add      gr72, gr77, gr72        
  20013d8:  60488348  cpeq     gr72, lr3, gr72         
  20013dc:  a400482d  jmpf     gr72, $2001490             ; -> L_2001490
  20013e0:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20013e4:  a000000c  jmp      $2001414                   ; -> L_2001414
L_20013e8:
  20013e8:  1547470c  add      gr71, gr71, $0c            ; [delay slot]
  20013ec:  60484b47  cpeq     gr72, gr75, gr71        
  20013f0:  a4ff48ee  jmpf     gr72, $20013a8             ; -> L_20013a8
  20013f4:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_20013f8:
  20013f8:  154a4a01  add      gr74, gr74, $01         
  20013fc:  1e004a4c  store    0, 0, gr74, gr76        
  2001400:  1e00824b  store    0, 0, lr2, gr75         
  2001404:  154b4b04  add      gr75, gr75, $04         
  2001408:  1e00844b  store    0, 0, lr4, gr75         
  200140c:  154b4b04  add      gr75, gr75, $04         
  2001410:  1e00834b  store    0, 0, lr3, gr75         
L_2001414:
  2001414:  16005b4c  load     0, 0, gr91, gr76        
  2001418:  25465b01  sub      gr70, gr91, $01         
  200141c:  ac00460c  jmpt     gr70, $200144c             ; -> L_200144c
  2001420:  25465b01  sub      gr70, gr91, $01            ; [delay slot]
  2001424:  0331476c  const    gr71, $316c             
  2001428:  024c4700  consth   gr71, $4c00             
L_200142c:
  200142c:  16004847  load     0, 0, gr72, gr71        
  2001430:  03004901  const    gr73, $0001             
  2001434:  8348481c  srl      gr72, gr72, $1c         
  2001438:  15484810  add      gr72, gr72, $10         
  200143c:  80494948  sll      gr73, gr73, gr72        
  2001440:  925b5b49  or       gr91, gr91, gr73        
  2001444:  b4ff46fa  jmpfdec  gr70, $200142c             ; -> L_200142c
  2001448:  1547470c  add      gr71, gr71, $0c            ; [delay slot]
L_200144c:
  200144c:  0300493e  const    gr73, $003e             
  2001450:  03004800  const    gr72, $0000             
L_2001454:
  2001454:  b6474800  mftlb    gr71, gr72              
  2001458:  83474708  srl      gr71, gr71, $08         
  200145c:  9147473f  and      gr71, gr71, $3f         
  2001460:  61474736  cpeq     gr71, gr71, $36         
  2001464:  a4004703  jmpf     gr71, $2001470             ; -> L_2001470
  2001468:  03004600  const    gr70, $0000                ; [delay slot]
  200146c:  be004846  mttlb    gr72, gr70              
L_2001470:
  2001470:  b4ff49f9  jmpfdec  gr73, $2001454             ; -> L_2001454
  2001474:  15484802  add      gr72, gr72, $02            ; [delay slot]
  2001478:  c0000045  jmpi     gr69                    
  200147c:  03006000  const    gr96, $0000                ; [delay slot]
L_2001480:
  2001480:  c0000045  jmpi     gr69                    
  2001484:  01ff60f7  constn   gr96, $fff7                ; [delay slot]
L_2001488:
  2001488:  c0000045  jmpi     gr69                    
  200148c:  01ff60f8  constn   gr96, $fff8                ; [delay slot]
L_2001490:
  2001490:  c0000045  jmpi     gr69                    
  2001494:  01ff60f9  constn   gr96, $fff9                ; [delay slot]
L_2001498:
  2001498:  c0000045  jmpi     gr69                    
  200149c:  01ff60fa  constn   gr96, $fffa                ; [delay slot]
L_20014a0:
  20014a0:  c0000045  jmpi     gr69                    
  20014a4:  01ff60fb  constn   gr96, $fffb                ; [delay slot]
L_20014a8:
  20014a8:  c0000045  jmpi     gr69                    
  20014ac:  01ff60fc  constn   gr96, $fffc                ; [delay slot]
L_20014b0:
  20014b0:  c0000045  jmpi     gr69                    
  20014b4:  01ff60fd  constn   gr96, $fffd                ; [delay slot]
  20014b8:  01ff46ff  constn   gr70, $ffff             
  20014bc:  60468246  cpeq     gr70, lr2, gr70         
  20014c0:  ac004620  jmpt     gr70, $2001540             ; -> L_2001540
  20014c4:  01fc4300  constn   gr67, $fc00                ; [delay slot]
  20014c8:  90468243  and      gr70, lr2, gr67         
  20014cc:  60464682  cpeq     gr70, gr70, lr2         
  20014d0:  a4ff46f6  jmpf     gr70, $20014a8             ; -> L_20014a8
  20014d4:  03314c68  const    gr76, $3168                ; [delay slot]
  20014d8:  024c4c00  consth   gr76, $4c00             
  20014dc:  16004a4c  load     0, 0, gr74, gr76        
  20014e0:  61474a00  cpeq     gr71, gr74, $00         
  20014e4:  acff47e9  jmpt     gr71, $2001488             ; -> L_2001488
  20014e8:  0331496c  const    gr73, $316c                ; [delay slot]
  20014ec:  024c4900  consth   gr73, $4c00             
  20014f0:  81474a02  sll      gr71, gr74, $02         
  20014f4:  81464a03  sll      gr70, gr74, $03         
  20014f8:  144b4647  add      gr75, gr70, gr71        
  20014fc:  144b494b  add      gr75, gr73, gr75        
  2001500:  81474900  sll      gr71, gr73, $00         
L_2001504:
  2001504:  16004647  load     0, 0, gr70, gr71        
  2001508:  42488246  cpltu    gr72, lr2, gr70         
  200150c:  ac004807  jmpt     gr72, $2001528             ; -> L_2001528
  2001510:  15484704  add      gr72, gr71, $04            ; [delay slot]
  2001514:  16004848  load     0, 0, gr72, gr72        
  2001518:  14484648  add      gr72, gr70, gr72        
  200151c:  42488248  cpltu    gr72, lr2, gr72         
  2001520:  ac00480d  jmpt     gr72, $2001554             ; -> L_2001554
  2001524:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2001528:
  2001528:  1547470c  add      gr71, gr71, $0c         
  200152c:  4c48474b  cpge     gr72, gr71, gr75        
  2001530:  a4ff48f5  jmpf     gr72, $2001504             ; -> L_2001504
  2001534:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001538:  a0ff00d2  jmp      $2001480                   ; -> L_2001480
  200153c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2001540:
  2001540:  03004600  const    gr70, $0000             
  2001544:  03314768  const    gr71, $3168             
  2001548:  024c4700  consth   gr71, $4c00             
  200154c:  a0000014  jmp      $200159c                   ; -> L_200159c
  2001550:  1e004647  store    0, 0, gr70, gr71           ; [delay slot]
L_2001554:
  2001554:  254a4a01  sub      gr74, gr74, $01         
  2001558:  1e004a4c  store    0, 0, gr74, gr76        
  200155c:  61484a00  cpeq     gr72, gr74, $00         
  2001560:  ac00482c  jmpt     gr72, $2001610             ; -> L_2001610
  2001564:  254b4b0c  sub      gr75, gr75, $0c            ; [delay slot]
  2001568:  60484b47  cpeq     gr72, gr75, gr71        
  200156c:  ac00480c  jmpt     gr72, $200159c             ; -> L_200159c
  2001570:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001574:  1600484b  load     0, 0, gr72, gr75        
  2001578:  154b4b04  add      gr75, gr75, $04         
  200157c:  1e004847  store    0, 0, gr72, gr71        
  2001580:  15474704  add      gr71, gr71, $04         
  2001584:  1600484b  load     0, 0, gr72, gr75        
  2001588:  154b4b04  add      gr75, gr75, $04         
  200158c:  1e004847  store    0, 0, gr72, gr71        
  2001590:  15474704  add      gr71, gr71, $04         
  2001594:  1600484b  load     0, 0, gr72, gr75        
  2001598:  1e004847  store    0, 0, gr72, gr71        
L_200159c:
  200159c:  0300453e  const    gr69, $003e             
  20015a0:  03004800  const    gr72, $0000             
L_20015a4:
  20015a4:  b6474800  mftlb    gr71, gr72              
  20015a8:  83474708  srl      gr71, gr71, $08         
  20015ac:  9147473f  and      gr71, gr71, $3f         
  20015b0:  61474736  cpeq     gr71, gr71, $36         
  20015b4:  a4004703  jmpf     gr71, $20015c0             ; -> L_20015c0
  20015b8:  03004600  const    gr70, $0000                ; [delay slot]
  20015bc:  be004846  mttlb    gr72, gr70              
L_20015c0:
  20015c0:  b4ff45f9  jmpfdec  gr69, $20015a4             ; -> L_20015a4
  20015c4:  15484802  add      gr72, gr72, $02            ; [delay slot]
  20015c8:  03315b68  const    gr91, $3168             
  20015cc:  024c5b00  consth   gr91, $4c00             
  20015d0:  16005b5b  load     0, 0, gr91, gr91        
  20015d4:  25465b01  sub      gr70, gr91, $01         
  20015d8:  ac00460c  jmpt     gr70, $2001608             ; -> L_2001608
  20015dc:  25465b01  sub      gr70, gr91, $01            ; [delay slot]
  20015e0:  0331476c  const    gr71, $316c             
  20015e4:  024c4700  consth   gr71, $4c00             
L_20015e8:
  20015e8:  16004847  load     0, 0, gr72, gr71        
  20015ec:  03004901  const    gr73, $0001             
  20015f0:  8348481c  srl      gr72, gr72, $1c         
  20015f4:  15484810  add      gr72, gr72, $10         
  20015f8:  80494948  sll      gr73, gr73, gr72        
  20015fc:  925b5b49  or       gr91, gr91, gr73        
  2001600:  b4ff46fa  jmpfdec  gr70, $20015e8             ; -> L_20015e8
  2001604:  1547470c  add      gr71, gr71, $0c            ; [delay slot]
L_2001608:
  2001608:  03006000  const    gr96, $0000             
  200160c:  88000000  iret                             
L_2001610:
  2001610:  03004700  const    gr71, $0000             
  2001614:  02084700  consth   gr71, $0800             
  2001618:  9c404047  andn     gr64, gr64, gr71        
  200161c:  03005b00  const    gr91, $0000             
  2001620:  03006000  const    gr96, $0000             
  2001624:  88000000  iret                             
  2001628:  01fc4300  constn   gr67, $fc00             
  200162c:  90468243  and      gr70, lr2, gr67         
  2001630:  60464682  cpeq     gr70, gr70, lr2         
  2001634:  a4ff469d  jmpf     gr70, $20014a8             ; -> L_20014a8
  2001638:  03314c68  const    gr76, $3168                ; [delay slot]
  200163c:  024c4c00  consth   gr76, $4c00             
  2001640:  16004a4c  load     0, 0, gr74, gr76        
  2001644:  61474a00  cpeq     gr71, gr74, $00         
  2001648:  acff4790  jmpt     gr71, $2001488             ; -> L_2001488
  200164c:  0331496c  const    gr73, $316c                ; [delay slot]
  2001650:  024c4900  consth   gr73, $4c00             
  2001654:  81474a02  sll      gr71, gr74, $02         
  2001658:  81464a03  sll      gr70, gr74, $03         
  200165c:  144b4647  add      gr75, gr70, gr71        
  2001660:  144b494b  add      gr75, gr73, gr75        
  2001664:  81474900  sll      gr71, gr73, $00         
L_2001668:
  2001668:  16004647  load     0, 0, gr70, gr71        
  200166c:  42488246  cpltu    gr72, lr2, gr70         
  2001670:  ac004807  jmpt     gr72, $200168c             ; -> L_200168c
  2001674:  15484704  add      gr72, gr71, $04            ; [delay slot]
  2001678:  16004848  load     0, 0, gr72, gr72        
  200167c:  14484648  add      gr72, gr70, gr72        
  2001680:  42488248  cpltu    gr72, lr2, gr72         
  2001684:  ac004808  jmpt     gr72, $20016a4             ; -> L_20016a4
  2001688:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_200168c:
  200168c:  1547470c  add      gr71, gr71, $0c         
  2001690:  4c48474b  cpge     gr72, gr71, gr75        
  2001694:  a4ff48f5  jmpf     gr72, $2001668             ; -> L_2001668
  2001698:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  200169c:  a0ff0079  jmp      $2001480                   ; -> L_2001480
  20016a0:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_20016a4:
  20016a4:  24488246  sub      gr72, lr2, gr70         
  20016a8:  15474708  add      gr71, gr71, $08         
  20016ac:  16004747  load     0, 0, gr71, gr71        
  20016b0:  147a4748  add      gr122, gr71, gr72       
  20016b4:  03006000  const    gr96, $0000             
  20016b8:  88000000  iret                             
  20016bc:  81468200  sll      gr70, lr2, $00          
  20016c0:  a80045fc  call     gr69, $2001ab0             ; -> L_2001ab0
  20016c4:  81476000  sll      gr71, gr96, $00            ; [delay slot]
  20016c8:  81604600  sll      gr96, gr70, $00         
  20016cc:  817a4700  sll      gr122, gr71, $00        
  20016d0:  88000000  iret                             
  20016d4:  03684a48  const    gr74, $6848             
  20016d8:  024c4a00  consth   gr74, $4c00             
  20016dc:  1e00824a  store    0, 0, lr2, gr74         
  20016e0:  c6520100  mfsr     gr82, OPS               
  20016e4:  91465240  and      gr70, gr82, $40         
  20016e8:  63604640  cpneq    gr96, gr70, $40         
  20016ec:  8360601f  srl      gr96, gr96, $1f         
  20016f0:  61468200  cpeq     gr70, lr2, $00          
  20016f4:  a4004604  jmpf     gr70, $2001704             ; -> L_2001704
  20016f8:  93525240  or       gr82, gr82, $40            ; [delay slot]
  20016fc:  ce000152  mtsr     OPS, gr82               
  2001700:  88000000  iret                             
L_2001704:
  2001704:  0300493e  const    gr73, $003e             
  2001708:  03004800  const    gr72, $0000             
L_200170c:
  200170c:  b6474800  mftlb    gr71, gr72              
  2001710:  83474708  srl      gr71, gr71, $08         
  2001714:  9147473f  and      gr71, gr71, $3f         
  2001718:  61474736  cpeq     gr71, gr71, $36         
  200171c:  a4004703  jmpf     gr71, $2001728             ; -> L_2001728
  2001720:  03004600  const    gr70, $0000                ; [delay slot]
  2001724:  be004846  mttlb    gr72, gr70              
L_2001728:
  2001728:  b4ff49f9  jmpfdec  gr73, $200170c             ; -> L_200170c
  200172c:  15484802  add      gr72, gr72, $02            ; [delay slot]
  2001730:  9d525240  andn     gr82, gr82, $40         
  2001734:  ce000152  mtsr     OPS, gr82               
  2001738:  88000000  iret                             
  200173c:  c6460100  mfsr     gr70, OPS               
  2001740:  91484610  and      gr72, gr70, $10         
  2001744:  63604800  cpneq    gr96, gr72, $00         
  2001748:  61478200  cpeq     gr71, lr2, $00          
  200174c:  ac004704  jmpt     gr71, $200175c             ; -> L_200175c
  2001750:  93464610  or       gr70, gr70, $10            ; [delay slot]
  2001754:  ce000146  mtsr     OPS, gr70               
  2001758:  88000000  iret                             
L_200175c:
  200175c:  9d464610  andn     gr70, gr70, $10         
  2001760:  ce000146  mtsr     OPS, gr70               
  2001764:  88000000  iret                             
  2001768:  c6470900  mfsr     gr71, TMR               
  200176c:  03004600  const    gr70, $0000             
  2001770:  02014600  consth   gr70, $0100             
  2001774:  90484746  and      gr72, gr71, gr70        
  2001778:  63604800  cpneq    gr96, gr72, $00         
  200177c:  61488200  cpeq     gr72, lr2, $00          
  2001780:  ac004807  jmpt     gr72, $200179c             ; -> L_200179c
  2001784:  03754730  const    gr71, $7530                ; [delay slot]
  2001788:  02004700  consth   gr71, $0000             
  200178c:  ce000847  mtsr     TMC, gr71               
  2001790:  92474746  or       gr71, gr71, gr70        
  2001794:  ce000947  mtsr     TMR, gr71               
  2001798:  88000000  iret                             
L_200179c:
  200179c:  04000800  mtsrim   TMC, $0000              
  20017a0:  04000900  mtsrim   TMR, $0000              
  20017a4:  88000000  iret                             
  20017a8:  c6460100  mfsr     gr70, OPS               
  20017ac:  91484602  and      gr72, gr70, $02         
  20017b0:  63604800  cpneq    gr96, gr72, $00         
  20017b4:  61478200  cpeq     gr71, lr2, $00          
  20017b8:  ac004704  jmpt     gr71, $20017c8             ; -> L_20017c8
  20017bc:  93464602  or       gr70, gr70, $02            ; [delay slot]
  20017c0:  ce000146  mtsr     OPS, gr70               
  20017c4:  88000000  iret                             
L_20017c8:
  20017c8:  9d464602  andn     gr70, gr70, $02         
  20017cc:  ce000146  mtsr     OPS, gr70               
  20017d0:  88000000  iret                             
  20017d4:  41458200  cplt     gr69, lr2, $00          
  20017d8:  ac004518  jmpt     gr69, $2001838             ; -> L_2001838
  20017dc:  49458203  cpgt     gr69, lr2, $03             ; [delay slot]
  20017e0:  ac004516  jmpt     gr69, $2001838             ; -> L_2001838
  20017e4:  61458200  cpeq     gr69, lr2, $00             ; [delay slot]
  20017e8:  a4004504  jmpf     gr69, $20017f8             ; -> L_20017f8
  20017ec:  0361467c  const    gr70, $617c                ; [delay slot]
  20017f0:  024c4600  consth   gr70, $4c00             
  20017f4:  a000000e  jmp      $200182c                   ; -> L_200182c
L_20017f8:
  20017f8:  61458201  cpeq     gr69, lr2, $01             ; [delay slot]
  20017fc:  a4004504  jmpf     gr69, $200180c             ; -> L_200180c
  2001800:  03614680  const    gr70, $6180                ; [delay slot]
  2001804:  024c4600  consth   gr70, $4c00             
  2001808:  a0000009  jmp      $200182c                   ; -> L_200182c
L_200180c:
  200180c:  61458202  cpeq     gr69, lr2, $02             ; [delay slot]
  2001810:  a4004505  jmpf     gr69, $2001824             ; -> L_2001824
  2001814:  03614684  const    gr70, $6184                ; [delay slot]
  2001818:  024c4600  consth   gr70, $4c00             
  200181c:  a0000004  jmp      $200182c                   ; -> L_200182c
  2001820:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2001824:
  2001824:  03614688  const    gr70, $6188             
  2001828:  024c4600  consth   gr70, $4c00             
L_200182c:
  200182c:  1e008346  store    0, 0, lr3, gr70         
  2001830:  03006000  const    gr96, $0000             
  2001834:  88000000  iret                             
L_2001838:
  2001838:  01ff60ff  constn   gr96, $ffff             
  200183c:  88000000  iret                             
  2001840:  0361468c  const    gr70, $618c             
  2001844:  024c4600  consth   gr70, $4c00             
  2001848:  16004746  load     0, 0, gr71, gr70        
  200184c:  a400471f  jmpf     gr71, $20018c8             ; -> L_20018c8
  2001850:  03004700  const    gr71, $0000                ; [delay slot]
  2001854:  1e004746  store    0, 0, gr71, gr70        
  2001858:  15464604  add      gr70, gr70, $04         
  200185c:  16005846  load     0, 0, gr88, gr70        
  2001860:  15464604  add      gr70, gr70, $04         
  2001864:  16005946  load     0, 0, gr89, gr70        
  2001868:  15464604  add      gr70, gr70, $04         
  200186c:  16005246  load     0, 0, gr82, gr70        
  2001870:  15464604  add      gr70, gr70, $04         
  2001874:  16005646  load     0, 0, gr86, gr70        
  2001878:  15464604  add      gr70, gr70, $04         
  200187c:  16005a46  load     0, 0, gr90, gr70        
  2001880:  15464604  add      gr70, gr70, $04         
  2001884:  16005746  load     0, 0, gr87, gr70        
  2001888:  15464604  add      gr70, gr70, $04         
  200188c:  16006046  load     0, 0, gr96, gr70        
  2001890:  15464604  add      gr70, gr70, $04         
  2001894:  16006146  load     0, 0, gr97, gr70        
  2001898:  15464604  add      gr70, gr70, $04         
  200189c:  16006246  load     0, 0, gr98, gr70        
  20018a0:  15464604  add      gr70, gr70, $04         
  20018a4:  16006346  load     0, 0, gr99, gr70        
  20018a8:  15464604  add      gr70, gr70, $04         
  20018ac:  0404027f  mtsrim   CPS, $047f              
  20018b0:  ce000a58  mtsr     PC0, gr88               
  20018b4:  ce000b59  mtsr     PC1, gr89               
  20018b8:  ce000152  mtsr     OPS, gr82               
  20018bc:  ce000456  mtsr     CHA, gr86               
  20018c0:  ce00065a  mtsr     CHC, gr90               
  20018c4:  ce000557  mtsr     CHD, gr87               
L_20018c8:
  20018c8:  88000000  iret                             
  20018cc:  03684704  const    gr71, $6804             
  20018d0:  024c4700  consth   gr71, $4c00             
  20018d4:  16006047  load     0, 0, gr96, gr71        
  20018d8:  88000000  iret                             
  20018dc:  81604000  sll      gr96, gr64, $00         
  20018e0:  88000000  iret                             
  20018e4:  01ff60d6  constn   gr96, $ffd6             
  20018e8:  88000000  iret                             
  20018ec:  01ff60d6  constn   gr96, $ffd6             
  20018f0:  88000000  iret                             
  20018f4:  157a7900  add      gr122, gr121, $00       
  20018f8:  03017901  const    gr121, $0101            
  20018fc:  60797a79  cpeq     gr121, gr122, gr121     
  2001900:  a4007911  jmpf     gr121, $2001944            ; -> L_2001944
  2001904:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001908:  15468203  add      gr70, lr2, $03          
  200190c:  9d464603  andn     gr70, gr70, $03         
  2001910:  15604100  add      gr96, gr65, $00         
  2001914:  03304500  const    gr69, $3000             
  2001918:  02004500  consth   gr69, $0000             
  200191c:  24447f45  sub      gr68, gr127, gr69       
  2001920:  14434146  add      gr67, gr65, gr70        
  2001924:  4e454344  cpgeu    gr69, gr67, gr68        
  2001928:  ac004504  jmpt     gr69, $2001938             ; -> L_2001938
  200192c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001930:  14414146  add      gr65, gr65, gr70        
  2001934:  88000000  iret                             
L_2001938:
  2001938:  03006000  const    gr96, $0000             
  200193c:  0300790c  const    gr121, $000c            
  2001940:  88000000  iret                             
L_2001944:
  2001944:  03017902  const    gr121, $0102            
  2001948:  60797a79  cpeq     gr121, gr122, gr121     
  200194c:  a4007908  jmpf     gr121, $200196c            ; -> L_200196c
  2001950:  03644310  const    gr67, $6410                ; [delay slot]
  2001954:  024c4300  consth   gr67, $4c00             
  2001958:  16004443  load     0, 0, gr68, gr67        
  200195c:  42438244  cpltu    gr67, lr2, gr68         
  2001960:  ac004302  jmpt     gr67, $2001968             ; -> L_2001968
  2001964:  03006000  const    gr96, $0000                ; [delay slot]
L_2001968:
  2001968:  88000000  iret                             
L_200196c:
  200196c:  03017903  const    gr121, $0103            
  2001970:  60797a79  cpeq     gr121, gr122, gr121     
  2001974:  a4007903  jmpf     gr121, $2001980            ; -> L_2001980
  2001978:  03046000  const    gr96, $0400                ; [delay slot]
  200197c:  88000000  iret                             
L_2001980:
  2001980:  03017921  const    gr121, $0121            
  2001984:  60797a79  cpeq     gr121, gr122, gr121     
  2001988:  a400790f  jmpf     gr121, $20019c4            ; -> L_20019c4
  200198c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001990:  03006000  const    gr96, $0000             
  2001994:  61798240  cpeq     gr121, lr2, $40         
  2001998:  a4007904  jmpf     gr121, $20019a8            ; -> L_20019a8
  200199c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20019a0:  155c8300  add      gr92, lr3, $00          
  20019a4:  88000000  iret                             
L_20019a8:
  20019a8:  61798241  cpeq     gr121, lr2, $41         
  20019ac:  a4007904  jmpf     gr121, $20019bc            ; -> L_20019bc
  20019b0:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20019b4:  155d8300  add      gr93, lr3, $00          
  20019b8:  88000000  iret                             
L_20019bc:
  20019bc:  01006001  constn   gr96, $0001             
  20019c0:  88000000  iret                             
L_20019c4:
  20019c4:  03017904  const    gr121, $0104            
  20019c8:  60797a79  cpeq     gr121, gr122, gr121     
  20019cc:  a4007904  jmpf     gr121, $20019dc            ; -> L_20019dc
  20019d0:  03786000  const    gr96, $7800                ; [delay slot]
  20019d4:  024c6000  consth   gr96, $4c00             
  20019d8:  88000000  iret                             
L_20019dc:
  20019dc:  03014311  const    gr67, $0111             
  20019e0:  60797a43  cpeq     gr121, gr122, gr67      
  20019e4:  a4007905  jmpf     gr121, $20019f8            ; -> L_20019f8
  20019e8:  03684730  const    gr71, $6830                ; [delay slot]
  20019ec:  024c4700  consth   gr71, $4c00             
  20019f0:  16006047  load     0, 0, gr96, gr71        
  20019f4:  88000000  iret                             
L_20019f8:
  20019f8:  03014312  const    gr67, $0112             
  20019fc:  60797a43  cpeq     gr121, gr122, gr67      
  2001a00:  a4007911  jmpf     gr121, $2001a44            ; -> L_2001a44
  2001a04:  03684734  const    gr71, $6834                ; [delay slot]
  2001a08:  024c4700  consth   gr71, $4c00             
  2001a0c:  16004747  load     0, 0, gr71, gr71        
  2001a10:  03754830  const    gr72, $7530             
  2001a14:  c6490800  mfsr     gr73, TMC               
  2001a18:  24494849  sub      gr73, gr72, gr73        
  2001a1c:  14604947  add      gr96, gr73, gr71        
  2001a20:  15474704  add      gr71, gr71, $04         
  2001a24:  16006147  load     0, 0, gr97, gr71        
  2001a28:  c64b8400  mfsr     gr75, ALU               
  2001a2c:  814b4b18  sll      gr75, gr75, $18         
  2001a30:  a4004b03  jmpf     gr75, $2001a3c             ; -> L_2001a3c
  2001a34:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001a38:  88000000  iret                             
L_2001a3c:
  2001a3c:  15616101  add      gr97, gr97, $01         
  2001a40:  88000000  iret                             
L_2001a44:
  2001a44:  81474014  sll      gr71, gr64, $14         
  2001a48:  a4004703  jmpf     gr71, $2001a54             ; -> L_2001a54
  2001a4c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001a50:  88000000  iret                             
L_2001a54:
  2001a54:  a8024697  call     gr70, $20024b0             ; -> L_20024b0
  2001a58:  154d7a00  add      gr77, gr122, $00           ; [delay slot]
  2001a5c:  03007901  const    gr121, $0001            
  2001a60:  60797a79  cpeq     gr121, gr122, gr121     
  2001a64:  a4007910  jmpf     gr121, $2001aa4            ; -> L_2001aa4
  2001a68:  03734818  const    gr72, $7318                ; [delay slot]
  2001a6c:  024c4800  consth   gr72, $4c00             
  2001a70:  03424742  const    gr71, $4242             
  2001a74:  02424753  consth   gr71, $4253             
  2001a78:  1e004748  store    0, 0, gr71, gr72        
  2001a7c:  03004701  const    gr71, $0001             
  2001a80:  036a485c  const    gr72, $6a5c             
  2001a84:  024c4800  consth   gr72, $4c00             
  2001a88:  1e004748  store    0, 0, gr71, gr72        
  2001a8c:  036a4860  const    gr72, $6a60             
  2001a90:  024c4800  consth   gr72, $4c00             
  2001a94:  c6470a00  mfsr     gr71, PC0               
  2001a98:  1e004748  store    0, 0, gr71, gr72        
L_2001a9c:
  2001a9c:  a0000000  jmp      $2001a9c                   ; -> L_2001a9c
  2001aa0:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2001aa4:
  2001aa4:  60794747  cpeq     gr121, gr71, gr71       
  2001aa8:  15604700  add      gr96, gr71, $00         
  2001aac:  88000000  iret                             
L_2001ab0:
  2001ab0:  81434004  sll      gr67, gr64, $04         
  2001ab4:  c4004345  jmpfi    gr67, gr69              
  2001ab8:  030343ff  const    gr67, $03ff                ; [delay slot]
  2001abc:  90435b43  and      gr67, gr91, gr67        
  2001ac0:  834c461c  srl      gr76, gr70, $1c         
  2001ac4:  154c4c10  add      gr76, gr76, $10         
  2001ac8:  03005101  const    gr81, $0001             
  2001acc:  804c514c  sll      gr76, gr81, gr76        
  2001ad0:  904c4c5b  and      gr76, gr76, gr91        
  2001ad4:  614c4c00  cpeq     gr76, gr76, $00         
  2001ad8:  cc004c45  jmpti    gr76, gr69              
  2001adc:  03034cff  const    gr76, $03ff                ; [delay slot]
  2001ae0:  9051464c  and      gr81, gr70, gr76        
  2001ae4:  9c46464c  andn     gr70, gr70, gr76        
  2001ae8:  0331486c  const    gr72, $316c             
  2001aec:  024c4800  consth   gr72, $4c00             
  2001af0:  c64b0200  mfsr     gr75, CPS               
  2001af4:  0404027f  mtsrim   CPS, $047f              
L_2001af8:
  2001af8:  25434301  sub      gr67, gr67, $01         
  2001afc:  ac004320  jmpt     gr67, $2001b7c             ; -> L_2001b7c
  2001b00:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001b04:  16004948  load     0, 0, gr73, gr72        
  2001b08:  15484804  add      gr72, gr72, $04         
  2001b0c:  604c4649  cpeq     gr76, gr70, gr73        
  2001b10:  ac004c10  jmpt     gr76, $2001b50             ; -> L_2001b50
  2001b14:  424c4649  cpltu    gr76, gr70, gr73           ; [delay slot]
  2001b18:  ac004c07  jmpt     gr76, $2001b34             ; -> L_2001b34
  2001b1c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001b20:  16004a48  load     0, 0, gr74, gr72        
  2001b24:  144a494a  add      gr74, gr73, gr74        
  2001b28:  424c464a  cpltu    gr76, gr70, gr74        
  2001b2c:  ac004c04  jmpt     gr76, $2001b3c             ; -> L_2001b3c
  2001b30:  24494649  sub      gr73, gr70, gr73           ; [delay slot]
L_2001b34:
  2001b34:  a0ff00f1  jmp      $2001af8                   ; -> L_2001af8
  2001b38:  15484808  add      gr72, gr72, $08            ; [delay slot]
L_2001b3c:
  2001b3c:  244a4a46  sub      gr74, gr74, gr70        
  2001b40:  15484804  add      gr72, gr72, $04         
  2001b44:  16004648  load     0, 0, gr70, gr72        
  2001b48:  a0000005  jmp      $2001b5c                   ; -> L_2001b5c
  2001b4c:  14464649  add      gr70, gr70, gr73           ; [delay slot]
L_2001b50:
  2001b50:  16004a48  load     0, 0, gr74, gr72        
  2001b54:  15484804  add      gr72, gr72, $04         
  2001b58:  16004648  load     0, 0, gr70, gr72        
L_2001b5c:
  2001b5c:  244a4a51  sub      gr74, gr74, gr81        
  2001b60:  464c474a  cpleu    gr76, gr71, gr74        
  2001b64:  ac004c03  jmpt     gr76, $2001b70             ; -> L_2001b70
  2001b68:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001b6c:  81474a00  sll      gr71, gr74, $00         
L_2001b70:
  2001b70:  ce00024b  mtsr     CPS, gr75               
  2001b74:  c0000045  jmpi     gr69                    
  2001b78:  92464651  or       gr70, gr70, gr81           ; [delay slot]
L_2001b7c:
  2001b7c:  ce00024b  mtsr     CPS, gr75               
  2001b80:  92464651  or       gr70, gr70, gr81        
  2001b84:  c0000045  jmpi     gr69                    
  2001b88:  03004700  const    gr71, $0000                ; [delay slot]
  2001b8c:  a00200b7  jmp      $2002668                   ; -> L_2002668
  2001b90:  03004da3  const    gr77, $00a3                ; [delay slot]
L_2001b94:
  2001b94:  03284810  const    gr72, $2810             
  2001b98:  024c4800  consth   gr72, $4c00             
  2001b9c:  16004748  load     0, 0, gr71, gr72        
  2001ba0:  ac004739  jmpt     gr71, $2001c84             ; -> L_2001c84
  2001ba4:  03004b00  const    gr75, $0000                ; [delay slot]
L_2001ba8:
  2001ba8:  032c47a8  const    gr71, $2ca8             
  2001bac:  024c4700  consth   gr71, $4c00             
  2001bb0:  81484b02  sll      gr72, gr75, $02         
  2001bb4:  14484748  add      gr72, gr71, gr72        
  2001bb8:  16004748  load     0, 0, gr71, gr72        
  2001bbc:  ac00472a  jmpt     gr71, $2001c64             ; -> L_2001c64
  2001bc0:  01ff49ff  constn   gr73, $ffff                ; [delay slot]
  2001bc4:  1e004948  store    0, 0, gr73, gr72        
  2001bc8:  03004900  const    gr73, $0000             
  2001bcc:  81484b02  sll      gr72, gr75, $02         
  2001bd0:  1448484b  add      gr72, gr72, gr75        
  2001bd4:  81484802  sll      gr72, gr72, $02         
  2001bd8:  03284798  const    gr71, $2898             
  2001bdc:  024c4700  consth   gr71, $4c00             
  2001be0:  144a4748  add      gr74, gr71, gr72        
  2001be4:  15474a0c  add      gr71, gr74, $0c         
  2001be8:  1e004947  store    0, 0, gr73, gr71        
  2001bec:  63474c00  cpneq    gr71, gr76, $00         
  2001bf0:  ac004709  jmpt     gr71, $2001c14             ; -> L_2001c14
  2001bf4:  15474a10  add      gr71, gr74, $10            ; [delay slot]
  2001bf8:  1e004947  store    0, 0, gr73, gr71        
  2001bfc:  81474d02  sll      gr71, gr77, $02         
  2001c00:  03284818  const    gr72, $2818             
  2001c04:  024c4800  consth   gr72, $4c00             
  2001c08:  14474847  add      gr71, gr72, gr71        
  2001c0c:  a0000005  jmp      $2001c20                   ; -> L_2001c20
  2001c10:  1e004a47  store    0, 0, gr74, gr71           ; [delay slot]
L_2001c14:
  2001c14:  1e004c47  store    0, 0, gr76, gr71        
  2001c18:  15474c0c  add      gr71, gr76, $0c         
  2001c1c:  1e004a47  store    0, 0, gr74, gr71        
L_2001c20:
  2001c20:  154c4a00  add      gr76, gr74, $00         
  2001c24:  032e4748  const    gr71, $2e48             
  2001c28:  024c4700  consth   gr71, $4c00             
  2001c2c:  16004747  load     0, 0, gr71, gr71        
  2001c30:  81484b0a  sll      gr72, gr75, $0a         
  2001c34:  14434748  add      gr67, gr71, gr72        
  2001c38:  1e00444c  store    0, 0, gr68, gr76        
  2001c3c:  15494c04  add      gr73, gr76, $04         
  2001c40:  1e004349  store    0, 0, gr67, gr73        
  2001c44:  15474c08  add      gr71, gr76, $08         
  2001c48:  1e004d47  store    0, 0, gr77, gr71        
  2001c4c:  81484b02  sll      gr72, gr75, $02         
  2001c50:  032d4778  const    gr71, $2d78             
  2001c54:  024c4700  consth   gr71, $4c00             
  2001c58:  14474748  add      gr71, gr71, gr72        
  2001c5c:  a0000062  jmp      $2001de4                   ; -> L_2001de4
  2001c60:  1e004c47  store    0, 0, gr76, gr71           ; [delay slot]
L_2001c64:
  2001c64:  154b4b01  add      gr75, gr75, $01         
  2001c68:  41474b34  cplt     gr71, gr75, $34         
  2001c6c:  acff47cf  jmpt     gr71, $2001ba8             ; -> L_2001ba8
  2001c70:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2001c74:  01ff47ff  constn   gr71, $ffff             
  2001c78:  03284810  const    gr72, $2810             
  2001c7c:  024c4800  consth   gr72, $4c00             
  2001c80:  1e004748  store    0, 0, gr71, gr72        
L_2001c84:
  2001c84:  c6470800  mfsr     gr71, TMC               
  2001c88:  94498280  xor      gr73, lr2, lr0          
L_2001c8c:
  2001c8c:  944747cc  xor      gr71, gr71, lr76        
  2001c90:  24474701  sub      gr71, gr71, gr1         
  2001c94:  94474947  xor      gr71, gr73, gr71        
  2001c98:  0300483f  const    gr72, $003f             
  2001c9c:  90484748  and      gr72, gr71, gr72        
  2001ca0:  2547480c  sub      gr71, gr72, $0c         
  2001ca4:  acff47fa  jmpt     gr71, $2001c8c             ; -> L_2001c8c
  2001ca8:  15494935  add      gr73, gr73, $35            ; [delay slot]
  2001cac:  83484801  srl      gr72, gr72, $01         
  2001cb0:  81484702  sll      gr72, gr71, $02         
  2001cb4:  032d4778  const    gr71, $2d78             
  2001cb8:  024c4700  consth   gr71, $4c00             
  2001cbc:  14474748  add      gr71, gr71, gr72        
  2001cc0:  16004a47  load     0, 0, gr74, gr71        
  2001cc4:  60474a4c  cpeq     gr71, gr74, gr76        
  2001cc8:  acff47f1  jmpt     gr71, $2001c8c             ; -> L_2001c8c
  2001ccc:  1547492a  add      gr71, gr73, $2a            ; [delay slot]
  2001cd0:  15474a10  add      gr71, gr74, $10         
  2001cd4:  16004847  load     0, 0, gr72, gr71        
  2001cd8:  61474800  cpeq     gr71, gr72, $00         
  2001cdc:  ac004706  jmpt     gr71, $2001cf4             ; -> L_2001cf4
  2001ce0:  15474a0c  add      gr71, gr74, $0c            ; [delay slot]
  2001ce4:  16004947  load     0, 0, gr73, gr71        
  2001ce8:  1547480c  add      gr71, gr72, $0c         
  2001cec:  a000000e  jmp      $2001d24                   ; -> L_2001d24
  2001cf0:  1e004947  store    0, 0, gr73, gr71           ; [delay slot]
L_2001cf4:
  2001cf4:  15474a08  add      gr71, gr74, $08         
  2001cf8:  16004747  load     0, 0, gr71, gr71        
  2001cfc:  03284818  const    gr72, $2818             
  2001d00:  024c4800  consth   gr72, $4c00             
  2001d04:  81474702  sll      gr71, gr71, $02         
  2001d08:  14484748  add      gr72, gr71, gr72        
  2001d0c:  16004748  load     0, 0, gr71, gr72        
  2001d10:  6247474a  cpneq    gr71, gr71, gr74        
  2001d14:  ac004704  jmpt     gr71, $2001d24             ; -> L_2001d24
  2001d18:  15474a0c  add      gr71, gr74, $0c            ; [delay slot]
  2001d1c:  16004947  load     0, 0, gr73, gr71        
  2001d20:  1e004948  store    0, 0, gr73, gr72        
L_2001d24:
  2001d24:  15474a0c  add      gr71, gr74, $0c         
  2001d28:  16004947  load     0, 0, gr73, gr71        
  2001d2c:  61474900  cpeq     gr71, gr73, $00         
  2001d30:  ac004705  jmpt     gr71, $2001d44             ; -> L_2001d44
  2001d34:  15474a10  add      gr71, gr74, $10            ; [delay slot]
  2001d38:  16004847  load     0, 0, gr72, gr71        
  2001d3c:  15474910  add      gr71, gr73, $10         
  2001d40:  1e004847  store    0, 0, gr72, gr71        
L_2001d44:
  2001d44:  15474a10  add      gr71, gr74, $10         
  2001d48:  1e004c47  store    0, 0, gr76, gr71        
  2001d4c:  03004900  const    gr73, $0000             
  2001d50:  15474a0c  add      gr71, gr74, $0c         
  2001d54:  1e004947  store    0, 0, gr73, gr71        
  2001d58:  61474c00  cpeq     gr71, gr76, $00         
  2001d5c:  ac004704  jmpt     gr71, $2001d6c             ; -> L_2001d6c
  2001d60:  15474c0c  add      gr71, gr76, $0c            ; [delay slot]
  2001d64:  a0000007  jmp      $2001d80                   ; -> L_2001d80
  2001d68:  1e004a47  store    0, 0, gr74, gr71           ; [delay slot]
L_2001d6c:
  2001d6c:  81474d02  sll      gr71, gr77, $02         
  2001d70:  03284818  const    gr72, $2818             
  2001d74:  024c4800  consth   gr72, $4c00             
  2001d78:  14474847  add      gr71, gr72, gr71        
  2001d7c:  1e004a47  store    0, 0, gr74, gr71        
L_2001d80:
  2001d80:  03804b00  const    gr75, $8000             
  2001d84:  02ff4bff  consth   gr75, $ffff             
  2001d88:  1600494a  load     0, 0, gr73, gr74        
  2001d8c:  9049494b  and      gr73, gr73, gr75        
  2001d90:  15474a08  add      gr71, gr74, $08         
  2001d94:  16004847  load     0, 0, gr72, gr71        
  2001d98:  81484801  sll      gr72, gr72, $01         
  2001d9c:  b6474800  mftlb    gr71, gr72              
  2001da0:  9047474b  and      gr71, gr71, gr75        
  2001da4:  60474749  cpeq     gr71, gr71, gr73        
  2001da8:  a4004703  jmpf     gr71, $2001db4             ; -> L_2001db4
  2001dac:  03004700  const    gr71, $0000                ; [delay slot]
  2001db0:  be004847  mttlb    gr72, gr71              
L_2001db4:
  2001db4:  15484840  add      gr72, gr72, $40         
  2001db8:  b6474800  mftlb    gr71, gr72              
  2001dbc:  9047474b  and      gr71, gr71, gr75        
  2001dc0:  60474749  cpeq     gr71, gr71, gr73        
  2001dc4:  a4004703  jmpf     gr71, $2001dd0             ; -> L_2001dd0
  2001dc8:  03004700  const    gr71, $0000                ; [delay slot]
  2001dcc:  be004847  mttlb    gr72, gr71              
L_2001dd0:
  2001dd0:  1e00444a  store    0, 0, gr68, gr74        
  2001dd4:  15474a08  add      gr71, gr74, $08         
  2001dd8:  1e004d47  store    0, 0, gr77, gr71        
  2001ddc:  15494a04  add      gr73, gr74, $04         
  2001de0:  16004349  load     0, 0, gr67, gr73        
L_2001de4:
  2001de4:  03ff51ff  const    gr81, $ffff             
  2001de8:  020f51ff  consth   gr81, $0fff             
  2001dec:  90514451  and      gr81, gr68, gr81        
  2001df0:  03004900  const    gr73, $0000             
  2001df4:  024c4900  consth   gr73, $4c00             
  2001df8:  92495149  or       gr73, gr81, gr73        
  2001dfc:  03005100  const    gr81, $0000             
  2001e00:  03004c8c  const    gr76, $008c             
  2001e04:  02444c00  consth   gr76, $4400             
  2001e08:  1e00514c  store    0, 0, gr81, gr76        
  2001e0c:  c65a0600  mfsr     gr90, CHC               
  2001e10:  032e454c  const    gr69, $2e4c             
  2001e14:  024c4500  consth   gr69, $4c00             
  2001e18:  0400871f  mtsrim   CR, $001f               
  2001e1c:  3e008045  storem   0, 0, lr0, gr69         
  2001e20:  01ff51ff  constn   gr81, $ffff             
  2001e24:  03004c88  const    gr76, $0088             
  2001e28:  02444c00  consth   gr76, $4400             
  2001e2c:  1e00514c  store    0, 0, gr81, gr76        
  2001e30:  25514304  sub      gr81, gr67, $04         
  2001e34:  1e004351  store    0, 0, gr67, gr81        
  2001e38:  03004680  const    gr70, $0080             
  2001e3c:  03005106  const    gr81, $0006             
L_2001e40:
  2001e40:  0400871f  mtsrim   CR, $001f               
  2001e44:  36008049  loadm    0, 0, lr0, gr73         
  2001e48:  b4ff51fe  jmpfdec  gr81, $2001e40             ; -> L_2001e40
  2001e4c:  14494946  add      gr73, gr73, gr70           ; [delay slot]
  2001e50:  03005100  const    gr81, $0000             
  2001e54:  1e00514c  store    0, 0, gr81, gr76        
  2001e58:  0400871f  mtsrim   CR, $001f               
  2001e5c:  36008045  loadm    0, 0, lr0, gr69         
  2001e60:  ce00065a  mtsr     CHC, gr90               
  2001e64:  81514018  sll      gr81, gr64, $18         
  2001e68:  9a515151  nand     gr81, gr81, gr81        
  2001e6c:  03004c8c  const    gr76, $008c             
  2001e70:  02444c00  consth   gr76, $4400             
  2001e74:  1e00514c  store    0, 0, gr81, gr76        
  2001e78:  a0f900c9  jmp      $200059c                   ; -> L_200059c
  2001e7c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2001e80:
  2001e80:  040003d0  mtsrim   CFG, $00d0              
  2001e84:  0404027f  mtsrim   CPS, $047f              
  2001e88:  03644318  const    gr67, $6418             
  2001e8c:  024c4300  consth   gr67, $4c00             
  2001e90:  16004043  load     0, 0, gr64, gr67        
  2001e94:  03004600  const    gr70, $0000             
  2001e98:  01ff47ff  constn   gr71, $ffff             
  2001e9c:  03004850  const    gr72, $0050             
  2001ea0:  02444800  consth   gr72, $4400             
  2001ea4:  1e004648  store    0, 0, gr70, gr72        
  2001ea8:  03004854  const    gr72, $0054             
  2001eac:  02444800  consth   gr72, $4400             
  2001eb0:  1e004648  store    0, 0, gr70, gr72        
  2001eb4:  03005b00  const    gr91, $0000             
  2001eb8:  03004800  const    gr72, $0000             
  2001ebc:  02084800  consth   gr72, $0800             
  2001ec0:  9c404048  andn     gr64, gr64, gr72        
  2001ec4:  03314868  const    gr72, $3168             
  2001ec8:  024c4800  consth   gr72, $4c00             
  2001ecc:  1e004648  store    0, 0, gr70, gr72        
  2001ed0:  0361487c  const    gr72, $617c             
  2001ed4:  024c4800  consth   gr72, $4c00             
  2001ed8:  1e004648  store    0, 0, gr70, gr72        
  2001edc:  15484804  add      gr72, gr72, $04         
  2001ee0:  1e004648  store    0, 0, gr70, gr72        
  2001ee4:  15484804  add      gr72, gr72, $04         
  2001ee8:  1e004648  store    0, 0, gr70, gr72        
  2001eec:  15484804  add      gr72, gr72, $04         
  2001ef0:  1e004648  store    0, 0, gr70, gr72        
  2001ef4:  15484804  add      gr72, gr72, $04         
  2001ef8:  1e004648  store    0, 0, gr70, gr72        
  2001efc:  03684830  const    gr72, $6830             
  2001f00:  024c4800  consth   gr72, $4c00             
  2001f04:  03014934  const    gr73, $0134             
L_2001f08:
  2001f08:  1e004648  store    0, 0, gr70, gr72        
  2001f0c:  b4ff49ff  jmpfdec  gr73, $2001f08             ; -> L_2001f08
  2001f10:  15484804  add      gr72, gr72, $04            ; [delay slot]
  2001f14:  0368483c  const    gr72, $683c             
  2001f18:  024c4800  consth   gr72, $4c00             
  2001f1c:  1e004748  store    0, 0, gr71, gr72        
  2001f20:  030049a2  const    gr73, $00a2             
  2001f24:  036a485c  const    gr72, $6a5c             
  2001f28:  024c4800  consth   gr72, $4c00             
  2001f2c:  1e004948  store    0, 0, gr73, gr72        
  2001f30:  036748d4  const    gr72, $67d4             
  2001f34:  024c4800  consth   gr72, $4c00             
  2001f38:  1e004648  store    0, 0, gr70, gr72        
  2001f3c:  03734800  const    gr72, $7300             
  2001f40:  024c4800  consth   gr72, $4c00             
  2001f44:  1e004648  store    0, 0, gr70, gr72        
  2001f48:  03734804  const    gr72, $7304             
  2001f4c:  024c4800  consth   gr72, $4c00             
  2001f50:  1e004748  store    0, 0, gr71, gr72        
  2001f54:  03314960  const    gr73, $3160             
  2001f58:  02574959  consth   gr73, $5759             
  2001f5c:  03734818  const    gr72, $7318             
  2001f60:  024c4800  consth   gr72, $4c00             
  2001f64:  1e004948  store    0, 0, gr73, gr72        
  2001f68:  0373481c  const    gr72, $731c             
  2001f6c:  024c4800  consth   gr72, $4c00             
  2001f70:  1e004648  store    0, 0, gr70, gr72        
  2001f74:  03644624  const    gr70, $6424             
  2001f78:  024c4600  consth   gr70, $4c00             
  2001f7c:  16004746  load     0, 0, gr71, gr70        
  2001f80:  0364462c  const    gr70, $642c             
  2001f84:  024c4600  consth   gr70, $4c00             
  2001f88:  16004846  load     0, 0, gr72, gr70        
  2001f8c:  03644620  const    gr70, $6420             
  2001f90:  024c4600  consth   gr70, $4c00             
  2001f94:  16004946  load     0, 0, gr73, gr70        
  2001f98:  03644628  const    gr70, $6428             
  2001f9c:  024c4600  consth   gr70, $4c00             
  2001fa0:  16004a46  load     0, 0, gr74, gr70        
  2001fa4:  1449494a  add      gr73, gr73, gr74        
  2001fa8:  83484802  srl      gr72, gr72, $02         
  2001fac:  25484802  sub      gr72, gr72, $02         
L_2001fb0:
  2001fb0:  16004647  load     0, 0, gr70, gr71        
  2001fb4:  15474704  add      gr71, gr71, $04         
  2001fb8:  1e004649  store    0, 0, gr70, gr73        
  2001fbc:  b4ff48fd  jmpfdec  gr72, $2001fb0             ; -> L_2001fb0
  2001fc0:  15494904  add      gr73, gr73, $04            ; [delay slot]
  2001fc4:  03644630  const    gr70, $6430             
  2001fc8:  024c4600  consth   gr70, $4c00             
  2001fcc:  16004846  load     0, 0, gr72, gr70        
  2001fd0:  83484802  srl      gr72, gr72, $02         
  2001fd4:  25484802  sub      gr72, gr72, $02         
  2001fd8:  03004600  const    gr70, $0000             
L_2001fdc:
  2001fdc:  1e004649  store    0, 0, gr70, gr73        
  2001fe0:  b4ff48ff  jmpfdec  gr72, $2001fdc             ; -> L_2001fdc
  2001fe4:  15494904  add      gr73, gr73, $04            ; [delay slot]
  2001fe8:  0400073f  mtsrim   RBP, $003f              
  2001fec:  0308526c  const    gr82, $086c             
  2001ff0:  03004600  const    gr70, $0000             
  2001ff4:  03004794  const    gr71, $0094             
  2001ff8:  02444700  consth   gr71, $4400             
  2001ffc:  16004847  load     0, 0, gr72, gr71        
  2002000:  a4004803  jmpf     gr72, $200200c             ; -> L_200200c
  2002004:  15474704  add      gr71, gr71, $04            ; [delay slot]
  2002008:  93464601  or       gr70, gr70, $01         
L_200200c:
  200200c:  81464601  sll      gr70, gr70, $01         
  2002010:  16004847  load     0, 0, gr72, gr71        
  2002014:  a4004803  jmpf     gr72, $2002020             ; -> L_2002020
  2002018:  15474704  add      gr71, gr71, $04            ; [delay slot]
  200201c:  93464601  or       gr70, gr70, $01         
L_2002020:
  2002020:  81464601  sll      gr70, gr70, $01         
  2002024:  16004847  load     0, 0, gr72, gr71        
  2002028:  a4004803  jmpf     gr72, $2002034             ; -> L_2002034
  200202c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002030:  93464601  or       gr70, gr70, $01         
L_2002034:
  2002034:  61494600  cpeq     gr73, gr70, $00         
  2002038:  a4004904  jmpf     gr73, $2002048             ; -> L_2002048
  200203c:  03014900  const    gr73, $0100                ; [delay slot]
  2002040:  02004900  consth   gr73, $0000             
  2002044:  9c404049  andn     gr64, gr64, gr73        
L_2002048:
  2002048:  03684904  const    gr73, $6804             
  200204c:  024c4900  consth   gr73, $4c00             
  2002050:  16004a49  load     0, 0, gr74, gr73        
  2002054:  814b4618  sll      gr75, gr70, $18         
  2002058:  924a4a4b  or       gr74, gr74, gr75        
  200205c:  03004600  const    gr70, $0000             
  2002060:  02464600  consth   gr70, $4600             
  2002064:  16004646  load     0, 0, gr70, gr70        
  2002068:  8346460c  srl      gr70, gr70, $0c         
  200206c:  8146461c  sll      gr70, gr70, $1c         
  2002070:  924a4a46  or       gr74, gr74, gr70        
  2002074:  1e004a49  store    0, 0, gr74, gr73        
  2002078:  8346461c  srl      gr70, gr70, $1c         
  200207c:  4d4b4601  cpge     gr75, gr70, $01         
  2002080:  a4004b04  jmpf     gr75, $2002090             ; -> L_2002090
  2002084:  03004b00  const    gr75, $0000                ; [delay slot]
  2002088:  02204b00  consth   gr75, $2000             
  200208c:  9240404b  or       gr64, gr64, gr75        
L_2002090:
  2002090:  03754630  const    gr70, $7530             
  2002094:  02004600  consth   gr70, $0000             
  2002098:  8145400c  sll      gr69, gr64, $0c         
  200209c:  ac004505  jmpt     gr69, $20020b0             ; -> L_20020b0
  20020a0:  ce000946  mtsr     TMR, gr70                  ; [delay slot]
  20020a4:  03754630  const    gr70, $7530             
  20020a8:  02014600  consth   gr70, $0100             
  20020ac:  ce000946  mtsr     TMR, gr70               
L_20020b0:
  20020b0:  04000800  mtsrim   TMC, $0000              
  20020b4:  c6470300  mfsr     gr71, CFG               
  20020b8:  9d474704  andn     gr71, gr71, $04         
  20020bc:  8145400d  sll      gr69, gr64, $0d         
  20020c0:  ac004503  jmpt     gr69, $20020cc             ; -> L_20020cc
  20020c4:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20020c8:  93474720  or       gr71, gr71, $20         
L_20020cc:
  20020cc:  83484718  srl      gr72, gr71, $18         
  20020d0:  4d484802  cpge     gr72, gr72, $02         
  20020d4:  a4004804  jmpf     gr72, $20020e4             ; -> L_20020e4
  20020d8:  8149401f  sll      gr73, gr64, $1f            ; [delay slot]
  20020dc:  ac004903  jmpt     gr73, $20020e8             ; -> L_20020e8
  20020e0:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_20020e4:
  20020e4:  93474701  or       gr71, gr71, $01         
L_20020e8:
  20020e8:  9f000000  inv                              
  20020ec:  8145401c  sll      gr69, gr64, $1c         
  20020f0:  a4004504  jmpf     gr69, $2002100             ; -> L_2002100
  20020f4:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20020f8:  a000000c  jmp      $2002128                   ; -> L_2002128
  20020fc:  93474702  or       gr71, gr71, $02            ; [delay slot]
L_2002100:
  2002100:  8145401e  sll      gr69, gr64, $1e         
  2002104:  a4004509  jmpf     gr69, $2002128             ; -> L_2002128
  2002108:  9d474702  andn     gr71, gr71, $02            ; [delay slot]
  200210c:  93474702  or       gr71, gr71, $02         
  2002110:  ce000347  mtsr     CFG, gr71               
  2002114:  03084e20  const    gr78, $0820             
  2002118:  020f4ec0  consth   gr78, $0fc0             
  200211c:  03134f75  const    gr79, $1375             
  2002120:  02004f00  consth   gr79, $0000             
  2002124:  1ee34e4f  store    1, 63, gr78, gr79       
L_2002128:
  2002128:  ce000347  mtsr     CFG, gr71               
  200212c:  81454015  sll      gr69, gr64, $15         
  2002130:  a4004503  jmpf     gr69, $200213c             ; -> L_200213c
  2002134:  03204300  const    gr67, $2000                ; [delay slot]
  2002138:  92525243  or       gr82, gr82, gr67        
L_200213c:
  200213c:  8145400e  sll      gr69, gr64, $0e         
  2002140:  a4004503  jmpf     gr69, $200214c             ; -> L_200214c
  2002144:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002148:  93525202  or       gr82, gr82, $02         
L_200214c:
  200214c:  8145400a  sll      gr69, gr64, $0a         
  2002150:  a4004503  jmpf     gr69, $200215c             ; -> L_200215c
  2002154:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002158:  93525210  or       gr82, gr82, $10         
L_200215c:
  200215c:  81454017  sll      gr69, gr64, $17         
  2002160:  a4004507  jmpf     gr69, $200217c             ; -> L_200217c
  2002164:  03084900  const    gr73, $0800                ; [delay slot]
  2002168:  9c525249  andn     gr82, gr82, gr73        
  200216c:  0300495c  const    gr73, $005c             
  2002170:  02444900  consth   gr73, $4400             
  2002174:  01ff4cff  constn   gr76, $ffff             
  2002178:  1e004c49  store    0, 0, gr76, gr73        
L_200217c:
  200217c:  81494018  sll      gr73, gr64, $18         
  2002180:  9a494949  nand     gr73, gr73, gr73        
  2002184:  03004c8c  const    gr76, $008c             
  2002188:  02444c00  consth   gr76, $4400             
  200218c:  1e00494c  store    0, 0, gr73, gr76        
  2002190:  81494019  sll      gr73, gr64, $19         
  2002194:  9a494949  nand     gr73, gr73, gr73        
  2002198:  03004c90  const    gr76, $0090             
  200219c:  02444c00  consth   gr76, $4400             
  20021a0:  1e00494c  store    0, 0, gr73, gr76        
  20021a4:  0300470a  const    gr71, $000a             
  20021a8:  6148470a  cpeq     gr72, gr71, $0a         
  20021ac:  a4004803  jmpf     gr72, $20021b8             ; -> L_20021b8
  20021b0:  04000d00  mtsrim   MMU, $0000                 ; [delay slot]
  20021b4:  a000000b  jmp      $20021e0                   ; -> L_20021e0
L_20021b8:
  20021b8:  6148470b  cpeq     gr72, gr71, $0b            ; [delay slot]
  20021bc:  a4004803  jmpf     gr72, $20021c8             ; -> L_20021c8
  20021c0:  04010d00  mtsrim   MMU, $0100                 ; [delay slot]
  20021c4:  a0000007  jmp      $20021e0                   ; -> L_20021e0
L_20021c8:
  20021c8:  6148470c  cpeq     gr72, gr71, $0c            ; [delay slot]
  20021cc:  a4004804  jmpf     gr72, $20021dc             ; -> L_20021dc
  20021d0:  04020d00  mtsrim   MMU, $0200                 ; [delay slot]
  20021d4:  a0000003  jmp      $20021e0                   ; -> L_20021e0
  20021d8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_20021dc:
  20021dc:  04030d00  mtsrim   MMU, $0300              
L_20021e0:
  20021e0:  03304800  const    gr72, $3000             
  20021e4:  02424800  consth   gr72, $4200             
  20021e8:  032e4748  const    gr71, $2e48             
  20021ec:  024c4700  consth   gr71, $4c00             
  20021f0:  1e004847  store    0, 0, gr72, gr71        
  20021f4:  814d401a  sll      gr77, gr64, $1a         
  20021f8:  a4004d17  jmpf     gr77, $2002254             ; -> L_2002254
  20021fc:  03284d18  const    gr77, $2818                ; [delay slot]
  2002200:  024c4d00  consth   gr77, $4c00             
  2002204:  0300451e  const    gr69, $001e             
  2002208:  03004400  const    gr68, $0000             
  200220c:  03004600  const    gr70, $0000             
L_2002210:
  2002210:  1e00464d  store    0, 0, gr70, gr77        
  2002214:  154d4d04  add      gr77, gr77, $04         
  2002218:  be004446  mttlb    gr68, gr70              
  200221c:  15444402  add      gr68, gr68, $02         
  2002220:  be004446  mttlb    gr68, gr70              
  2002224:  b4ff45fb  jmpfdec  gr69, $2002210             ; -> L_2002210
  2002228:  15444402  add      gr68, gr68, $02            ; [delay slot]
  200222c:  9d525220  andn     gr82, gr82, $20         
  2002230:  03004532  const    gr69, $0032             
  2002234:  032c47a8  const    gr71, $2ca8             
  2002238:  024c4700  consth   gr71, $4c00             
L_200223c:
  200223c:  1e004647  store    0, 0, gr70, gr71        
  2002240:  b4ff45ff  jmpfdec  gr69, $200223c             ; -> L_200223c
  2002244:  15474704  add      gr71, gr71, $04            ; [delay slot]
  2002248:  03284710  const    gr71, $2810             
  200224c:  024c4700  consth   gr71, $4c00             
  2002250:  1e004647  store    0, 0, gr70, gr71        
L_2002254:
  2002254:  8147400f  sll      gr71, gr64, $0f         
  2002258:  a400470f  jmpf     gr71, $2002294             ; -> L_2002294
  200225c:  0300453e  const    gr69, $003e                ; [delay slot]
  2002260:  9d525240  andn     gr82, gr82, $40         
  2002264:  03004400  const    gr68, $0000             
  2002268:  03044300  const    gr67, $0400             
  200226c:  03004700  const    gr71, $0000             
  2002270:  03004600  const    gr70, $0000             
  2002274:  03804800  const    gr72, $8000             
  2002278:  02ff48ff  consth   gr72, $ffff             
L_200227c:
  200227c:  be004446  mttlb    gr68, gr70              
  2002280:  15444401  add      gr68, gr68, $01         
  2002284:  be004446  mttlb    gr68, gr70              
  2002288:  15444401  add      gr68, gr68, $01         
  200228c:  b4ff45fc  jmpfdec  gr69, $200227c             ; -> L_200227c
  2002290:  14474743  add      gr71, gr71, gr67           ; [delay slot]
L_2002294:
  2002294:  ce000152  mtsr     OPS, gr82               
  2002298:  03644740  const    gr71, $6440             
  200229c:  024c4700  consth   gr71, $4c00             
  20022a0:  16007d47  load     0, 0, gr125, gr71       
  20022a4:  03007f00  const    gr127, $0000            
  20022a8:  02007f01  consth   gr127, $0001            
  20022ac:  247f7d7f  sub      gr127, gr125, gr127     
  20022b0:  25017f08  sub      gr1, gr127, $08         
  20022b4:  03027e00  const    gr126, $0200            
  20022b8:  247e7f7e  sub      gr126, gr127, gr126     
  20022bc:  032480a8  const    lr0, $24a8              
  20022c0:  02028000  consth   lr0, $0200              
  20022c4:  15817f00  add      lr1, gr127, $00         
  20022c8:  036d4708  const    gr71, $6d08             
  20022cc:  024c4700  consth   gr71, $4c00             
  20022d0:  16004847  load     0, 0, gr72, gr71        
  20022d4:  61454803  cpeq     gr69, gr72, $03         
  20022d8:  ac004517  jmpt     gr69, $2002334             ; -> L_2002334
  20022dc:  61454800  cpeq     gr69, gr72, $00            ; [delay slot]
  20022e0:  ac004515  jmpt     gr69, $2002334             ; -> L_2002334
  20022e4:  61454801  cpeq     gr69, gr72, $01            ; [delay slot]
  20022e8:  ac004515  jmpt     gr69, $200233c             ; -> L_200233c
  20022ec:  61454805  cpeq     gr69, gr72, $05            ; [delay slot]
  20022f0:  ac004513  jmpt     gr69, $200233c             ; -> L_200233c
  20022f4:  61454804  cpeq     gr69, gr72, $04            ; [delay slot]
  20022f8:  ac004513  jmpt     gr69, $2002344             ; -> L_2002344
  20022fc:  61454802  cpeq     gr69, gr72, $02            ; [delay slot]
  2002300:  ac004517  jmpt     gr69, $200235c             ; -> L_200235c
  2002304:  61454806  cpeq     gr69, gr72, $06            ; [delay slot]
  2002308:  ac004509  jmpt     gr69, $200232c             ; -> L_200232c
  200230c:  6145480f  cpeq     gr69, gr72, $0f            ; [delay slot]
  2002310:  ac004515  jmpt     gr69, $2002364             ; -> L_2002364
  2002314:  0301474f  const    gr71, $014f                ; [delay slot]
  2002318:  60454847  cpeq     gr69, gr72, gr71        
  200231c:  ac00450a  jmpt     gr69, $2002344             ; -> L_2002344
  2002320:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002324:  a0000015  jmp      $2002378                   ; -> L_2002378
  2002328:  03005150  const    gr81, $0050                ; [delay slot]
L_200232c:
  200232c:  a0000013  jmp      $2002378                   ; -> L_2002378
  2002330:  030a5100  const    gr81, $0a00                ; [delay slot]
L_2002334:
  2002334:  a0000011  jmp      $2002378                   ; -> L_2002378
  2002338:  03045180  const    gr81, $0480                ; [delay slot]
L_200233c:
  200233c:  a000000f  jmp      $2002378                   ; -> L_2002378
  2002340:  03045100  const    gr81, $0400                ; [delay slot]
L_2002344:
  2002344:  03684728  const    gr71, $6828             
  2002348:  024c4700  consth   gr71, $4c00             
  200234c:  030149e6  const    gr73, $01e6             
  2002350:  1e004947  store    0, 0, gr73, gr71        
  2002354:  a0000009  jmp      $2002378                   ; -> L_2002378
  2002358:  030a5100  const    gr81, $0a00                ; [delay slot]
L_200235c:
  200235c:  a0000007  jmp      $2002378                   ; -> L_2002378
  2002360:  03085100  const    gr81, $0800                ; [delay slot]
L_2002364:
  2002364:  03684728  const    gr71, $6828             
  2002368:  024c4700  consth   gr71, $4c00             
  200236c:  03024930  const    gr73, $0230             
  2002370:  1e004947  store    0, 0, gr73, gr71        
  2002374:  030a5100  const    gr81, $0a00             
L_2002378:
  2002378:  03684728  const    gr71, $6828             
  200237c:  024c4700  consth   gr71, $4c00             
  2002380:  16004947  load     0, 0, gr73, gr71        
  2002384:  15494906  add      gr73, gr73, $06         
  2002388:  ce008349  mtsr     Q, gr73                 
  200238c:  65495100  mul      gr73, gr81, $00         
  2002390:  64495149  mul      gr73, gr81, gr73        
  2002394:  64495149  mul      gr73, gr81, gr73        
  2002398:  64495149  mul      gr73, gr81, gr73        
  200239c:  64495149  mul      gr73, gr81, gr73        
  20023a0:  64495149  mul      gr73, gr81, gr73        
  20023a4:  64495149  mul      gr73, gr81, gr73        
  20023a8:  64495149  mul      gr73, gr81, gr73        
  20023ac:  64495149  mul      gr73, gr81, gr73        
  20023b0:  64495149  mul      gr73, gr81, gr73        
  20023b4:  64495149  mul      gr73, gr81, gr73        
  20023b8:  64495149  mul      gr73, gr81, gr73        
  20023bc:  64495149  mul      gr73, gr81, gr73        
  20023c0:  64495149  mul      gr73, gr81, gr73        
  20023c4:  64495149  mul      gr73, gr81, gr73        
  20023c8:  64495149  mul      gr73, gr81, gr73        
  20023cc:  64495149  mul      gr73, gr81, gr73        
  20023d0:  64495149  mul      gr73, gr81, gr73        
  20023d4:  64495149  mul      gr73, gr81, gr73        
  20023d8:  64495149  mul      gr73, gr81, gr73        
  20023dc:  64495149  mul      gr73, gr81, gr73        
  20023e0:  64495149  mul      gr73, gr81, gr73        
  20023e4:  64495149  mul      gr73, gr81, gr73        
  20023e8:  64495149  mul      gr73, gr81, gr73        
  20023ec:  64495149  mul      gr73, gr81, gr73        
  20023f0:  64495149  mul      gr73, gr81, gr73        
  20023f4:  64495149  mul      gr73, gr81, gr73        
  20023f8:  64495149  mul      gr73, gr81, gr73        
  20023fc:  64495149  mul      gr73, gr81, gr73        
  2002400:  64495149  mul      gr73, gr81, gr73        
  2002404:  64495149  mul      gr73, gr81, gr73        
  2002408:  66495149  mull     gr73, gr81, gr73        
  200240c:  c6498300  mfsr     gr73, Q                 
  2002410:  0368471c  const    gr71, $681c             
  2002414:  024c4700  consth   gr71, $4c00             
  2002418:  16004847  load     0, 0, gr72, gr71        
  200241c:  144a4849  add      gr74, gr72, gr73        
  2002420:  03314620  const    gr70, $3120             
  2002424:  024c4600  consth   gr70, $4c00             
  2002428:  1e004a46  store    0, 0, gr74, gr70        
  200242c:  8146400b  sll      gr70, gr64, $0b         
  2002430:  03004800  const    gr72, $0000             
  2002434:  020d4800  consth   gr72, $0d00             
  2002438:  92484842  or       gr72, gr72, gr66        
  200243c:  ac004603  jmpt     gr70, $2002448             ; -> L_2002448
  2002440:  81414800  sll      gr65, gr72, $00            ; [delay slot]
  2002444:  81414a00  sll      gr65, gr74, $00         
L_2002448:
  2002448:  03644710  const    gr71, $6410             
  200244c:  024c4700  consth   gr71, $4c00             
  2002450:  1e004147  store    0, 0, gr65, gr71        
  2002454:  0364463c  const    gr70, $643c             
  2002458:  024c4600  consth   gr70, $4c00             
  200245c:  16004746  load     0, 0, gr71, gr70        
  2002460:  81474710  sll      gr71, gr71, $10         
  2002464:  03004600  const    gr70, $0000             
  2002468:  02464600  consth   gr70, $4600             
  200246c:  1e004746  store    0, 0, gr71, gr70        
  2002470:  15604e00  add      gr96, gr78, $00         
  2002474:  15614f00  add      gr97, gr79, $00         
  2002478:  ce000152  mtsr     OPS, gr82               
  200247c:  03644304  const    gr67, $6404             
  2002480:  024c4300  consth   gr67, $4c00             
  2002484:  16004343  load     0, 0, gr67, gr67        
  2002488:  ce000b43  mtsr     PC1, gr67               
  200248c:  15434304  add      gr67, gr67, $04         
  2002490:  ce000a43  mtsr     PC0, gr67               
  2002494:  8147400f  sll      gr71, gr64, $0f         
  2002498:  ac004774  jmpt     gr71, $2002668             ; -> L_2002668
  200249c:  03004da1  const    gr77, $00a1                ; [delay slot]
  20024a0:  04000600  mtsrim   CHC, $0000              
  20024a4:  8c000000  iretinv                          
  20024a8:  a0000070  jmp      $2002668                   ; -> L_2002668
  20024ac:  03004d9e  const    gr77, $009e                ; [delay slot]
L_20024b0:
  20024b0:  c6590b00  mfsr     gr89, PC1               
  20024b4:  c6580a00  mfsr     gr88, PC0               
  20024b8:  c6520100  mfsr     gr82, OPS               
  20024bc:  c65a0600  mfsr     gr90, CHC               
  20024c0:  c6560400  mfsr     gr86, CHA               
  20024c4:  c6570500  mfsr     gr87, CHD               
  20024c8:  0400027f  mtsrim   CPS, $007f              
  20024cc:  03004700  const    gr71, $0000             
L_20024d0:
  20024d0:  03004364  const    gr67, $0064             
  20024d4:  02444300  consth   gr67, $4400             
  20024d8:  16004343  load     0, 0, gr67, gr67        
  20024dc:  a4004304  jmpf     gr67, $20024ec             ; -> L_20024ec
  20024e0:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20024e4:  a8f94578  call     gr69, $2000ac4             ; -> L_2000ac4
  20024e8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_20024ec:
  20024ec:  03704300  const    gr67, $7000             
  20024f0:  024c4300  consth   gr67, $4c00             
  20024f4:  16004743  load     0, 0, gr71, gr67        
  20024f8:  03334437  const    gr68, $3337             
  20024fc:  02734433  consth   gr68, $7333             
  2002500:  60454447  cpeq     gr69, gr68, gr71        
  2002504:  ac004507  jmpt     gr69, $2002520             ; -> L_2002520
  2002508:  03664469  const    gr68, $6669                ; [delay slot]
  200250c:  02964466  consth   gr68, $9666             
  2002510:  60454744  cpeq     gr69, gr71, gr68        
  2002514:  acff45ef  jmpt     gr69, $20024d0             ; -> L_20024d0
  2002518:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  200251c:  a000002d  jmp      $20025d0                   ; -> L_20025d0
L_2002520:
  2002520:  03704304  const    gr67, $7004                ; [delay slot]
  2002524:  024c4300  consth   gr67, $4c00             
  2002528:  1e004d43  store    0, 0, gr77, gr67        
  200252c:  03704310  const    gr67, $7010             
  2002530:  024c4300  consth   gr67, $4c00             
  2002534:  0400870f  mtsrim   CR, $000f               
  2002538:  3e008243  storem   0, 0, lr2, gr67         
  200253c:  03704300  const    gr67, $7000             
  2002540:  024c4300  consth   gr67, $4c00             
  2002544:  03664469  const    gr68, $6669             
  2002548:  02964466  consth   gr68, $9666             
  200254c:  1e004443  store    0, 0, gr68, gr67        
  2002550:  0370430c  const    gr67, $700c             
  2002554:  024c4300  consth   gr67, $4c00             
  2002558:  16004343  load     0, 0, gr67, gr67        
  200255c:  1e004443  store    0, 0, gr68, gr67        
L_2002560:
  2002560:  03004364  const    gr67, $0064             
  2002564:  02444300  consth   gr67, $4400             
  2002568:  16004543  load     0, 0, gr69, gr67        
  200256c:  a4004504  jmpf     gr69, $200257c             ; -> L_200257c
  2002570:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002574:  a8f94554  call     gr69, $2000ac4             ; -> L_2000ac4
  2002578:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_200257c:
  200257c:  03704300  const    gr67, $7000             
  2002580:  024c4300  consth   gr67, $4c00             
  2002584:  16004743  load     0, 0, gr71, gr67        
  2002588:  03334437  const    gr68, $3337             
  200258c:  02734433  consth   gr68, $7333             
  2002590:  60454447  cpeq     gr69, gr68, gr71        
  2002594:  ac004507  jmpt     gr69, $20025b0             ; -> L_20025b0
  2002598:  03664469  const    gr68, $6669                ; [delay slot]
  200259c:  02964466  consth   gr68, $9666             
  20025a0:  60454447  cpeq     gr69, gr68, gr71        
  20025a4:  acff45ef  jmpt     gr69, $2002560             ; -> L_2002560
  20025a8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20025ac:  a0000009  jmp      $20025d0                   ; -> L_20025d0
L_20025b0:
  20025b0:  03704304  const    gr67, $7004                ; [delay slot]
  20025b4:  024c4300  consth   gr67, $4c00             
  20025b8:  60444444  cpeq     gr68, gr68, gr68        
  20025bc:  92444d44  or       gr68, gr77, gr68        
  20025c0:  1e004443  store    0, 0, gr68, gr67        
  20025c4:  03704308  const    gr67, $7008             
  20025c8:  024c4300  consth   gr67, $4c00             
  20025cc:  16004743  load     0, 0, gr71, gr67        
L_20025d0:
  20025d0:  0404027f  mtsrim   CPS, $047f              
  20025d4:  ce000b59  mtsr     PC1, gr89               
  20025d8:  ce000a58  mtsr     PC0, gr88               
  20025dc:  ce000152  mtsr     OPS, gr82               
  20025e0:  ce000456  mtsr     CHA, gr86               
  20025e4:  ce000557  mtsr     CHD, gr87               
  20025e8:  ce00065a  mtsr     CHC, gr90               
  20025ec:  c0000046  jmpi     gr70                    
  20025f0:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_20025f4:
  20025f4:  036147c0  const    gr71, $61c0             
  20025f8:  024c4700  consth   gr71, $4c00             
  20025fc:  16004847  load     0, 0, gr72, gr71        
  2002600:  4d494880  cpge     gr73, gr72, $80         
  2002604:  ac00490b  jmpt     gr73, $2002630             ; -> L_2002630
  2002608:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  200260c:  15484801  add      gr72, gr72, $01         
L_2002610:
  2002610:  1e004847  store    0, 0, gr72, gr71        
  2002614:  036a477c  const    gr71, $6a7c             
  2002618:  024c4700  consth   gr71, $4c00             
  200261c:  81484802  sll      gr72, gr72, $02         
  2002620:  14474748  add      gr71, gr71, gr72        
  2002624:  c6480b00  mfsr     gr72, PC1               
  2002628:  c0000046  jmpi     gr70                    
  200262c:  1e004847  store    0, 0, gr72, gr71           ; [delay slot]
L_2002630:
  2002630:  036147bc  const    gr71, $61bc             
  2002634:  024c4700  consth   gr71, $4c00             
  2002638:  1e004647  store    0, 0, gr70, gr71        
  200263c:  a8ff469d  call     gr70, $20024b0             ; -> L_20024b0
  2002640:  03004db5  const    gr77, $00b5                ; [delay slot]
  2002644:  036147bc  const    gr71, $61bc             
  2002648:  024c4700  consth   gr71, $4c00             
  200264c:  16004647  load     0, 0, gr70, gr71        
  2002650:  01ff49ff  constn   gr73, $ffff             
  2002654:  1e004947  store    0, 0, gr73, gr71        
  2002658:  036147c0  const    gr71, $61c0             
  200265c:  024c4700  consth   gr71, $4c00             
  2002660:  a0ff00ec  jmp      $2002610                   ; -> L_2002610
  2002664:  03004800  const    gr72, $0000                ; [delay slot]
L_2002668:
  2002668:  61464d92  cpeq     gr70, gr77, $92         
  200266c:  ac004606  jmpt     gr70, $2002684             ; -> L_2002684
  2002670:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002674:  15545800  add      gr84, gr88, $00         
  2002678:  15555900  add      gr85, gr89, $00         
  200267c:  c6580a00  mfsr     gr88, PC0               
  2002680:  c6590b00  mfsr     gr89, PC1               
L_2002684:
  2002684:  c6560400  mfsr     gr86, CHA               
  2002688:  c65a0600  mfsr     gr90, CHC               
  200268c:  c6570500  mfsr     gr87, CHD               
  2002690:  03674748  const    gr71, $6748             
  2002694:  024c4700  consth   gr71, $4c00             
  2002698:  c6460000  mfsr     gr70, VAB               
  200269c:  1e004647  store    0, 0, gr70, gr71        
  20026a0:  15474704  add      gr71, gr71, $04         
  20026a4:  1e005247  store    0, 0, gr82, gr71        
  20026a8:  15474704  add      gr71, gr71, $04         
  20026ac:  c6460200  mfsr     gr70, CPS               
  20026b0:  1e004647  store    0, 0, gr70, gr71        
  20026b4:  15474704  add      gr71, gr71, $04         
  20026b8:  c6460300  mfsr     gr70, CFG               
  20026bc:  1e004647  store    0, 0, gr70, gr71        
  20026c0:  15474704  add      gr71, gr71, $04         
  20026c4:  1e005647  store    0, 0, gr86, gr71        
  20026c8:  15474704  add      gr71, gr71, $04         
  20026cc:  1e005747  store    0, 0, gr87, gr71        
  20026d0:  15474704  add      gr71, gr71, $04         
  20026d4:  1e005a47  store    0, 0, gr90, gr71        
  20026d8:  15474704  add      gr71, gr71, $04         
  20026dc:  c6460700  mfsr     gr70, RBP               
  20026e0:  1e004647  store    0, 0, gr70, gr71        
  20026e4:  15474704  add      gr71, gr71, $04         
  20026e8:  c6460800  mfsr     gr70, TMC               
  20026ec:  1e004647  store    0, 0, gr70, gr71        
  20026f0:  15474704  add      gr71, gr71, $04         
  20026f4:  c6460900  mfsr     gr70, TMR               
  20026f8:  1e004647  store    0, 0, gr70, gr71        
  20026fc:  15474704  add      gr71, gr71, $04         
  2002700:  1e005847  store    0, 0, gr88, gr71        
  2002704:  15474704  add      gr71, gr71, $04         
  2002708:  1e005947  store    0, 0, gr89, gr71        
  200270c:  15474704  add      gr71, gr71, $04         
  2002710:  c6460c00  mfsr     gr70, PC2               
  2002714:  1e004647  store    0, 0, gr70, gr71        
  2002718:  15474704  add      gr71, gr71, $04         
  200271c:  c6460d00  mfsr     gr70, MMU               
  2002720:  1e004647  store    0, 0, gr70, gr71        
  2002724:  15474704  add      gr71, gr71, $04         
  2002728:  c6460e00  mfsr     gr70, LRU               
  200272c:  1e004647  store    0, 0, gr70, gr71        
  2002730:  15474704  add      gr71, gr71, $04         
  2002734:  03674788  const    gr71, $6788             
  2002738:  024c4700  consth   gr71, $4c00             
  200273c:  c6468000  mfsr     gr70, IPC               
  2002740:  1e004647  store    0, 0, gr70, gr71        
  2002744:  15474704  add      gr71, gr71, $04         
  2002748:  c6468100  mfsr     gr70, IPA               
  200274c:  1e004647  store    0, 0, gr70, gr71        
  2002750:  15474704  add      gr71, gr71, $04         
  2002754:  c6468200  mfsr     gr70, IPB               
  2002758:  1e004647  store    0, 0, gr70, gr71        
  200275c:  15474704  add      gr71, gr71, $04         
  2002760:  c6468300  mfsr     gr70, Q                 
  2002764:  1e004647  store    0, 0, gr70, gr71        
  2002768:  15474704  add      gr71, gr71, $04         
  200276c:  c6468400  mfsr     gr70, ALU               
  2002770:  1e004647  store    0, 0, gr70, gr71        
  2002774:  15474704  add      gr71, gr71, $04         
  2002778:  c6468500  mfsr     gr70, BP                
  200277c:  1e004647  store    0, 0, gr70, gr71        
  2002780:  15474704  add      gr71, gr71, $04         
  2002784:  c6468600  mfsr     gr70, FC                
  2002788:  1e004647  store    0, 0, gr70, gr71        
  200278c:  15474704  add      gr71, gr71, $04         
  2002790:  c6468700  mfsr     gr70, CR                
  2002794:  1e004647  store    0, 0, gr70, gr71        
  2002798:  15474704  add      gr71, gr71, $04         
  200279c:  03734818  const    gr72, $7318             
  20027a0:  024c4800  consth   gr72, $4c00             
  20027a4:  03424742  const    gr71, $4242             
  20027a8:  02424753  consth   gr71, $4253             
  20027ac:  1e004748  store    0, 0, gr71, gr72        
  20027b0:  0300451e  const    gr69, $001e             
  20027b4:  03004600  const    gr70, $0000             
  20027b8:  03284718  const    gr71, $2818             
  20027bc:  024c4700  consth   gr71, $4c00             
  20027c0:  036c4b7c  const    gr75, $6c7c             
  20027c4:  024c4b00  consth   gr75, $4c00             
  20027c8:  0368495c  const    gr73, $685c             
  20027cc:  024c4900  consth   gr73, $4c00             
  20027d0:  03004400  const    gr68, $0000             
L_20027d4:
  20027d4:  b64a4400  mftlb    gr74, gr68              
  20027d8:  1e004a49  store    0, 0, gr74, gr73        
  20027dc:  15494904  add      gr73, gr73, $04         
  20027e0:  be004446  mttlb    gr68, gr70              
  20027e4:  15444401  add      gr68, gr68, $01         
  20027e8:  b64a4400  mftlb    gr74, gr68              
  20027ec:  15444401  add      gr68, gr68, $01         
  20027f0:  1e004a49  store    0, 0, gr74, gr73        
  20027f4:  15494904  add      gr73, gr73, $04         
  20027f8:  b64a4400  mftlb    gr74, gr68              
  20027fc:  1e004a49  store    0, 0, gr74, gr73        
  2002800:  15494904  add      gr73, gr73, $04         
  2002804:  be004446  mttlb    gr68, gr70              
  2002808:  15444401  add      gr68, gr68, $01         
  200280c:  b64a4400  mftlb    gr74, gr68              
  2002810:  15444401  add      gr68, gr68, $01         
  2002814:  1e004a49  store    0, 0, gr74, gr73        
  2002818:  15494904  add      gr73, gr73, $04         
  200281c:  16004a47  load     0, 0, gr74, gr71        
  2002820:  1e004a4b  store    0, 0, gr74, gr75        
  2002824:  154b4b04  add      gr75, gr75, $04         
  2002828:  1e004647  store    0, 0, gr70, gr71        
  200282c:  b4ff45ea  jmpfdec  gr69, $20027d4             ; -> L_20027d4
  2002830:  15474704  add      gr71, gr71, $04            ; [delay slot]
  2002834:  03004532  const    gr69, $0032             
  2002838:  032c47a8  const    gr71, $2ca8             
  200283c:  024c4700  consth   gr71, $4c00             
L_2002840:
  2002840:  1e004647  store    0, 0, gr70, gr71        
  2002844:  b4ff45ff  jmpfdec  gr69, $2002840             ; -> L_2002840
  2002848:  15474704  add      gr71, gr71, $04            ; [delay slot]
  200284c:  03284710  const    gr71, $2810             
  2002850:  024c4700  consth   gr71, $4c00             
  2002854:  1e004647  store    0, 0, gr70, gr71        
  2002858:  0400027f  mtsrim   CPS, $007f              
  200285c:  03644744  const    gr71, $6444             
  2002860:  024c4700  consth   gr71, $4c00             
  2002864:  1e000147  store    0, 0, gr1, gr71         
  2002868:  03644748  const    gr71, $6448             
  200286c:  024c4700  consth   gr71, $4c00             
  2002870:  0400873f  mtsrim   CR, $003f               
  2002874:  3e004047  storem   0, 0, gr64, gr71        
  2002878:  70400101  aseq     trap64, gr1, gr1        
  200287c:  03654748  const    gr71, $6548             
  2002880:  024c4700  consth   gr71, $4c00             
  2002884:  83460102  srl      gr70, gr1, $02          
  2002888:  9146467f  and      gr70, gr70, $7f         
  200288c:  93464680  or       gr70, gr70, $80         
  2002890:  81464602  sll      gr70, gr70, $02         
  2002894:  ce008146  mtsr     IPA, gr70               
  2002898:  0400877f  mtsrim   CR, $007f               
  200289c:  3e000047  storem   0, 0, gr0, gr71         
  20028a0:  70400101  aseq     trap64, gr1, gr1        
  20028a4:  8146401e  sll      gr70, gr64, $1e         
  20028a8:  a4004609  jmpf     gr70, $20028cc             ; -> L_20028cc
  20028ac:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20028b0:  036747c8  const    gr71, $67c8             
  20028b4:  024c4700  consth   gr71, $4c00             
  20028b8:  16834646  load     1, 3, gr70, gr70        
  20028bc:  1e004647  store    0, 0, gr70, gr71        
  20028c0:  15474704  add      gr71, gr71, $04         
  20028c4:  16824646  load     1, 2, gr70, gr70        
  20028c8:  1e006947  store    0, 0, gr105, gr71       
L_20028cc:
  20028cc:  15825800  add      lr2, gr88, $00          
  20028d0:  15835900  add      lr3, gr89, $00          
  20028d4:  15845200  add      lr4, gr82, $00          
  20028d8:  15855600  add      lr5, gr86, $00          
  20028dc:  15865a00  add      lr6, gr90, $00          
  20028e0:  15875700  add      lr7, gr87, $00          
  20028e4:  c6880300  mfsr     lr8, CFG                
  20028e8:  15814d00  add      lr1, gr77, $00          
  20028ec:  036a475c  const    gr71, $6a5c             
  20028f0:  024c4700  consth   gr71, $4c00             
  20028f4:  04008707  mtsrim   CR, $0007               
  20028f8:  3e008147  storem   0, 0, lr1, gr71         
  20028fc:  03684b58  const    gr75, $6858             
  2002900:  024c4b00  consth   gr75, $4c00             
  2002904:  c64c0e00  mfsr     gr76, LRU               
  2002908:  1e004c4b  store    0, 0, gr76, gr75        
  200290c:  81474014  sll      gr71, gr64, $14         
  2002910:  ac004707  jmpt     gr71, $200292c             ; -> L_200292c
  2002914:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002918:  a8fe46e6  call     gr70, $20024b0             ; -> L_20024b0
  200291c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002920:  8147400f  sll      gr71, gr64, $0f         
  2002924:  ac004708  jmpt     gr71, $2002944             ; -> L_2002944
  2002928:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_200292c:
  200292c:  03734818  const    gr72, $7318             
  2002930:  024c4800  consth   gr72, $4c00             
  2002934:  03144621  const    gr70, $1421             
  2002938:  1e004648  store    0, 0, gr70, gr72        
  200293c:  a0fd0051  jmp      $2001e80                   ; -> L_2001e80
  2002940:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2002944:
  2002944:  a8fe46db  call     gr70, $20024b0             ; -> L_20024b0
  2002948:  03004db4  const    gr77, $00b4                ; [delay slot]
  200294c:  036146c4  const    gr70, $61c4             
  2002950:  024c4600  consth   gr70, $4c00             
  2002954:  1e004746  store    0, 0, gr71, gr70        
  2002958:  03004800  const    gr72, $0000             
  200295c:  61464701  cpeq     gr70, gr71, $01         
  2002960:  ac00461e  jmpt     gr70, $20029d8             ; -> L_20029d8
  2002964:  61464702  cpeq     gr70, gr71, $02            ; [delay slot]
  2002968:  ac00461b  jmpt     gr70, $20029d4             ; -> L_20029d4
  200296c:  61464703  cpeq     gr70, gr71, $03            ; [delay slot]
  2002970:  ac004608  jmpt     gr70, $2002990             ; -> L_2002990
  2002974:  61464704  cpeq     gr70, gr71, $04            ; [delay slot]
  2002978:  ac00460f  jmpt     gr70, $20029b4             ; -> L_20029b4
  200297c:  61464705  cpeq     gr70, gr71, $05            ; [delay slot]
  2002980:  acfd4640  jmpt     gr70, $2001e80             ; -> L_2001e80
  2002984:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2002988:  a0ff00ef  jmp      $2002944                   ; -> L_2002944
  200298c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2002990:
  2002990:  036147c0  const    gr71, $61c0             
  2002994:  024c4700  consth   gr71, $4c00             
  2002998:  03004600  const    gr70, $0000             
  200299c:  1e004647  store    0, 0, gr70, gr71        
  20029a0:  036147bc  const    gr71, $61bc             
  20029a4:  024c4700  consth   gr71, $4c00             
  20029a8:  01ff46ff  constn   gr70, $ffff             
  20029ac:  a0ff00e6  jmp      $2002944                   ; -> L_2002944
  20029b0:  1e004647  store    0, 0, gr70, gr71           ; [delay slot]
L_20029b4:
  20029b4:  036147c0  const    gr71, $61c0             
  20029b8:  024c4700  consth   gr71, $4c00             
  20029bc:  03004600  const    gr70, $0000             
  20029c0:  1e004647  store    0, 0, gr70, gr71        
  20029c4:  036147bc  const    gr71, $61bc             
  20029c8:  024c4700  consth   gr71, $4c00             
  20029cc:  a0ff00de  jmp      $2002944                   ; -> L_2002944
  20029d0:  1e004647  store    0, 0, gr70, gr71           ; [delay slot]
L_20029d4:
  20029d4:  03204800  const    gr72, $2000             
L_20029d8:
  20029d8:  0400027f  mtsrim   CPS, $007f              
  20029dc:  81454015  sll      gr69, gr64, $15         
  20029e0:  ac004509  jmpt     gr69, $2002a04             ; -> L_2002a04
  20029e4:  0367474c  const    gr71, $674c                ; [delay slot]
  20029e8:  024c4700  consth   gr71, $4c00             
  20029ec:  16004947  load     0, 0, gr73, gr71        
  20029f0:  03304600  const    gr70, $3000             
  20029f4:  02004600  consth   gr70, $0000             
  20029f8:  9c494946  andn     gr73, gr73, gr70        
  20029fc:  92494948  or       gr73, gr73, gr72        
  2002a00:  1e004947  store    0, 0, gr73, gr71        
L_2002a04:
  2002a04:  03644744  const    gr71, $6444             
  2002a08:  024c4700  consth   gr71, $4c00             
  2002a0c:  16004647  load     0, 0, gr70, gr71        
  2002a10:  15014600  add      gr1, gr70, $00          
  2002a14:  83460102  srl      gr70, gr1, $02          
  2002a18:  9146467f  and      gr70, gr70, $7f         
  2002a1c:  93464680  or       gr70, gr70, $80         
  2002a20:  81464602  sll      gr70, gr70, $02         
  2002a24:  ce008146  mtsr     IPA, gr70               
  2002a28:  03654748  const    gr71, $6548             
  2002a2c:  024c4700  consth   gr71, $4c00             
  2002a30:  0400877f  mtsrim   CR, $007f               
  2002a34:  36000047  loadm    0, 0, gr0, gr71         
  2002a38:  70400101  aseq     trap64, gr1, gr1        
  2002a3c:  03644748  const    gr71, $6448             
  2002a40:  024c4700  consth   gr71, $4c00             
  2002a44:  0400873f  mtsrim   CR, $003f               
  2002a48:  36004047  loadm    0, 0, gr64, gr71        
  2002a4c:  70400101  aseq     trap64, gr1, gr1        
  2002a50:  0404027f  mtsrim   CPS, $047f              
  2002a54:  03674748  const    gr71, $6748             
  2002a58:  024c4700  consth   gr71, $4c00             
  2002a5c:  16004647  load     0, 0, gr70, gr71        
  2002a60:  15474704  add      gr71, gr71, $04         
  2002a64:  ce000046  mtsr     VAB, gr70               
  2002a68:  16004647  load     0, 0, gr70, gr71        
  2002a6c:  15474704  add      gr71, gr71, $04         
  2002a70:  ce000146  mtsr     OPS, gr70               
  2002a74:  15474704  add      gr71, gr71, $04         
  2002a78:  16004647  load     0, 0, gr70, gr71        
  2002a7c:  15474704  add      gr71, gr71, $04         
  2002a80:  ce000346  mtsr     CFG, gr70               
  2002a84:  16004647  load     0, 0, gr70, gr71        
  2002a88:  15474704  add      gr71, gr71, $04         
  2002a8c:  ce000446  mtsr     CHA, gr70               
  2002a90:  16004647  load     0, 0, gr70, gr71        
  2002a94:  15474704  add      gr71, gr71, $04         
  2002a98:  ce000546  mtsr     CHD, gr70               
  2002a9c:  16004647  load     0, 0, gr70, gr71        
  2002aa0:  15474704  add      gr71, gr71, $04         
  2002aa4:  ce000646  mtsr     CHC, gr70               
  2002aa8:  16004647  load     0, 0, gr70, gr71        
  2002aac:  15474704  add      gr71, gr71, $04         
  2002ab0:  ce000746  mtsr     RBP, gr70               
  2002ab4:  16004647  load     0, 0, gr70, gr71        
  2002ab8:  15474704  add      gr71, gr71, $04         
  2002abc:  ce000846  mtsr     TMC, gr70               
  2002ac0:  16004647  load     0, 0, gr70, gr71        
  2002ac4:  15474704  add      gr71, gr71, $04         
  2002ac8:  ce000946  mtsr     TMR, gr70               
  2002acc:  16004647  load     0, 0, gr70, gr71        
  2002ad0:  15474704  add      gr71, gr71, $04         
  2002ad4:  ce000a46  mtsr     PC0, gr70               
  2002ad8:  16004647  load     0, 0, gr70, gr71        
  2002adc:  15474704  add      gr71, gr71, $04         
  2002ae0:  ce000b46  mtsr     PC1, gr70               
  2002ae4:  16004647  load     0, 0, gr70, gr71        
  2002ae8:  15474704  add      gr71, gr71, $04         
  2002aec:  ce000c46  mtsr     PC2, gr70               
  2002af0:  16004647  load     0, 0, gr70, gr71        
  2002af4:  15474704  add      gr71, gr71, $04         
  2002af8:  ce000d46  mtsr     MMU, gr70               
  2002afc:  16004647  load     0, 0, gr70, gr71        
  2002b00:  15474704  add      gr71, gr71, $04         
  2002b04:  ce000e46  mtsr     LRU, gr70               
  2002b08:  03674788  const    gr71, $6788             
  2002b0c:  024c4700  consth   gr71, $4c00             
  2002b10:  16004647  load     0, 0, gr70, gr71        
  2002b14:  15474704  add      gr71, gr71, $04         
  2002b18:  ce008046  mtsr     IPC, gr70               
  2002b1c:  16004647  load     0, 0, gr70, gr71        
  2002b20:  15474704  add      gr71, gr71, $04         
  2002b24:  ce008146  mtsr     IPA, gr70               
  2002b28:  16004647  load     0, 0, gr70, gr71        
  2002b2c:  15474704  add      gr71, gr71, $04         
  2002b30:  ce008246  mtsr     IPB, gr70               
  2002b34:  16004647  load     0, 0, gr70, gr71        
  2002b38:  15474704  add      gr71, gr71, $04         
  2002b3c:  ce008346  mtsr     Q, gr70                 
  2002b40:  16004647  load     0, 0, gr70, gr71        
  2002b44:  15474704  add      gr71, gr71, $04         
  2002b48:  ce008446  mtsr     ALU, gr70               
  2002b4c:  16004647  load     0, 0, gr70, gr71        
  2002b50:  15474704  add      gr71, gr71, $04         
  2002b54:  ce008546  mtsr     BP, gr70                
  2002b58:  16004647  load     0, 0, gr70, gr71        
  2002b5c:  15474704  add      gr71, gr71, $04         
  2002b60:  ce008646  mtsr     FC, gr70                
  2002b64:  16004647  load     0, 0, gr70, gr71        
  2002b68:  15474704  add      gr71, gr71, $04         
  2002b6c:  ce008746  mtsr     CR, gr70                
  2002b70:  8c000000  iretinv                          
