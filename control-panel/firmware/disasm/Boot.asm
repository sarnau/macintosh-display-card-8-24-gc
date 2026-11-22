* ==================================================================
*  ACEF_1 "Runtime" -- Boot  (Am29000, base $2003000)   *** UNMASKED (fitted) ***
* ==================================================================
*  Disassembled from Boot.unmasked.bin = Boot.bin with its second mask
*  removed by ../../unmask_runtime.py (tables COL_BOOT/ROW_BOOT).  Unlike
*  Hand's tables, which are exact, Boot's were FITTED: maximum likelihood
*  against field statistics of the unmasked Hand plus hard constraints.  Checks
*  that hold: all 58 direct jumps land inside the code ($2000000-$20037FF), the
*  five SPR instructions decode to VAB/CFG/CPS with mfsr RB = 0 and mtsr
*  RC = 0, 89 of 99 adjacent const/consth pairs share their register, and the
*  host-handshake constant below matches DRVR.s.  Some register fields (an
*  occasional gr70/gr71 swap) are probably still wrong.
*
*  What Boot does (in order):
*    $2003000  clears/touches a block of card registers from $4400000C
*    $2003030  mtsrim CPS,$0000 / CPS,$047F  (same CPS values Hand uses)
*    $2003078  POLLS $4C006400 (= PublicIn word 0) until it reads $42005300 --
*              the value DRVR.s pokes to image+$00 -- then writes 0 back
*    $20030CC  copies a parameter block, builds masks from the host's fields
*    $2003140  VAB <- $4C000000 (the Vec section), CFG |= $10, and fills the
*              trap vector table with handler addresses $0200xxxx (default
*              $2001D08 repeated; the host-visible 'noise' of Vec/PrivNZ is
*              this table before Boot overwrites it)
*    $2003368  reads the card's hardware-ID bits at $44000044/48/4C (= the
*              $0400004C/48/44 registers BuildUnitRecords reads), selects a
*              board configuration value ($1E0/$366/$1E6/$180/$240/$270) and
*              stores it to $4C006828 (PublicOu+$28)
*    $20037D4  jmp $2001FFC -- into Hand's reset/initialisation routine
* ==================================================================
  2003000:  0300460c  const    gr70, $000c             
  2003004:  02444600  consth   gr70, $4400             
  2003008:  03004200  const    gr66, $0000             
  200300c:  03004702  const    gr71, $0002             
L_2003010:
  2003010:  16004946  load     0, 0, gr73, gr70        
  2003014:  ac004903  jmpt     gr73, $2003020             ; -> L_2003020
  2003018:  1e004946  store    0, 0, gr73, gr70           ; [delay slot]
  200301c:  93424201  or       gr66, gr66, $01         
L_2003020:
  2003020:  15464704  add      gr70, gr71, $04         
  2003024:  b4ff46fb  jmpfdec  gr70, $2003010             ; -> L_2003010
  2003028:  81424301  sll      gr66, gr67, $01            ; [delay slot]
  200302c:  83424301  srl      gr66, gr67, $01         
  2003030:  04000200  mtsrim   CPS, $0000              
  2003034:  8142431c  sll      gr66, gr67, $1c         
  2003038:  0404037f  mtsrim   CFG, $047f              
  200303c:  0368472c  const    gr71, $682c             
  2003040:  024c4700  consth   gr71, $4c00             
  2003044:  1e004247  store    0, 0, gr66, gr71        
  2003048:  03644318  const    gr67, $6418             
  200304c:  024c4300  consth   gr67, $4c00             
  2003050:  16004043  load     0, 0, gr64, gr67        
  2003054:  036a485c  const    gr72, $6a5c             
  2003058:  024c4800  consth   gr72, $4c00             
  200305c:  03004694  const    gr70, $0094             
  2003060:  02004700  consth   gr71, $0000             
  2003064:  1e004749  store    0, 0, gr71, gr73        
  2003068:  03534700  const    gr71, $5300             
  200306c:  02424700  consth   gr71, $4200             
  2003070:  03644600  const    gr70, $6400             
  2003074:  024c4600  consth   gr70, $4c00             
L_2003078:
  2003078:  16004846  load     0, 0, gr72, gr70        
  200307c:  60484847  cpeq     gr72, gr72, gr71        
  2003080:  a4ff48fe  jmpf     gr72, $2003078             ; -> L_2003078
  2003084:  03004800  const    gr72, $0000                ; [delay slot]
  2003088:  1e004846  store    0, 0, gr72, gr70        
  200308c:  1e004849  store    0, 0, gr72, gr73        
  2003090:  03644724  const    gr71, $6424             
  2003094:  024c4700  consth   gr71, $4c00             
  2003098:  16004747  load     0, 0, gr71, gr71        
  200309c:  03644820  const    gr72, $6420             
  20030a0:  024c4800  consth   gr72, $4c00             
  20030a4:  16004848  load     0, 0, gr72, gr72        
  20030a8:  03644928  const    gr73, $6428             
  20030ac:  024c4900  consth   gr73, $4c00             
  20030b0:  16004849  load     0, 0, gr72, gr73        
  20030b4:  14484949  add      gr72, gr73, gr73        
  20030b8:  0364482c  const    gr72, $642c             
  20030bc:  024c4800  consth   gr72, $4c00             
  20030c0:  16004949  load     0, 0, gr73, gr73        
  20030c4:  83494902  srl      gr73, gr73, $02         
  20030c8:  25494902  sub      gr73, gr73, $02         
L_20030cc:
  20030cc:  16004a48  load     0, 0, gr74, gr72        
  20030d0:  15484804  add      gr72, gr72, $04         
  20030d4:  1e004a47  store    0, 0, gr74, gr71        
  20030d8:  b4ff49fd  jmpfdec  gr73, $20030cc             ; -> L_20030cc
  20030dc:  15474704  add      gr71, gr71, $04            ; [delay slot]
  20030e0:  03ff48ff  const    gr72, $ffff             
  20030e4:  020f48ff  consth   gr72, $0fff             
  20030e8:  0368460c  const    gr70, $680c             
  20030ec:  024c4600  consth   gr70, $4c00             
  20030f0:  16004947  load     0, 0, gr73, gr71        
  20030f4:  90484949  and      gr72, gr73, gr73        
  20030f8:  92484942  or       gr72, gr73, gr66        
  20030fc:  1e004847  store    0, 0, gr72, gr71        
  2003100:  15474704  add      gr71, gr71, $04         
  2003104:  16004847  load     0, 0, gr72, gr71        
  2003108:  90484849  and      gr72, gr72, gr73        
  200310c:  92484842  or       gr72, gr72, gr66        
  2003110:  1e004847  store    0, 0, gr72, gr71        
  2003114:  15474604  add      gr71, gr70, $04         
  2003118:  16004947  load     0, 0, gr73, gr71        
  200311c:  90484949  and      gr72, gr73, gr73        
  2003120:  92484842  or       gr72, gr72, gr66        
  2003124:  1e004847  store    0, 0, gr72, gr71        
  2003128:  15474704  add      gr71, gr71, $04         
  200312c:  16004847  load     0, 0, gr72, gr71        
  2003130:  90484849  and      gr72, gr72, gr73        
  2003134:  92484842  or       gr72, gr72, gr66        
  2003138:  1e004847  store    0, 0, gr72, gr71        
  200313c:  03004700  const    gr71, $0000             
  2003140:  024c4700  consth   gr71, $4c00             
  2003144:  ce000047  mtsr     VAB, gr71               
  2003148:  c6460300  mfsr     gr70, CFG               
  200314c:  93464610  or       gr70, gr70, $10         
  2003150:  ce000346  mtsr     CFG, gr70               
  2003154:  03004600  const    gr70, $0000             
  2003158:  02024600  consth   gr70, $0200             
  200315c:  1e004647  store    0, 0, gr70, gr71        
  2003160:  15474704  add      gr71, gr71, $04         
  2003164:  03004608  const    gr70, $0008             
  2003168:  02024600  consth   gr70, $0200             
  200316c:  1e004647  store    0, 0, gr70, gr71        
  2003170:  15474604  add      gr71, gr70, $04         
  2003174:  03094708  const    gr71, $0908             
  2003178:  02024700  consth   gr71, $0200             
  200317c:  1e004747  store    0, 0, gr71, gr71        
  2003180:  15474704  add      gr71, gr71, $04         
  2003184:  03094620  const    gr70, $0920             
  2003188:  02024600  consth   gr70, $0200             
  200318c:  1e004647  store    0, 0, gr70, gr71        
  2003190:  15474704  add      gr71, gr71, $04         
  2003194:  03094628  const    gr70, $0928             
  2003198:  02024600  consth   gr70, $0200             
  200319c:  1e004647  store    0, 0, gr70, gr71        
  20031a0:  15474604  add      gr71, gr70, $04         
  20031a4:  03094740  const    gr71, $0940             
  20031a8:  02024700  consth   gr71, $0200             
  20031ac:  1e004747  store    0, 0, gr71, gr71        
  20031b0:  15474604  add      gr71, gr70, $04         
  20031b4:  03064744  const    gr71, $0644             
  20031b8:  02024700  consth   gr71, $0200             
  20031bc:  1e004647  store    0, 0, gr70, gr71        
  20031c0:  15474704  add      gr71, gr71, $04         
  20031c4:  03034658  const    gr70, $0358             
  20031c8:  02024600  consth   gr70, $0200             
  20031cc:  1e004647  store    0, 0, gr70, gr71        
  20031d0:  15474704  add      gr71, gr71, $04         
  20031d4:  03064770  const    gr71, $0670             
  20031d8:  02024700  consth   gr71, $0200             
  20031dc:  1e004747  store    0, 0, gr71, gr71        
  20031e0:  15474704  add      gr71, gr71, $04         
  20031e4:  03074614  const    gr70, $0714             
  20031e8:  02024600  consth   gr70, $0200             
  20031ec:  1e004647  store    0, 0, gr70, gr71        
  20031f0:  15474704  add      gr71, gr71, $04         
  20031f4:  03064670  const    gr70, $0670             
  20031f8:  02024600  consth   gr70, $0200             
  20031fc:  1e004647  store    0, 0, gr70, gr71        
  2003200:  15474704  add      gr71, gr71, $04         
  2003204:  03074614  const    gr70, $0714             
  2003208:  02024600  consth   gr70, $0200             
  200320c:  1e004647  store    0, 0, gr70, gr71        
  2003210:  15474704  add      gr71, gr71, $04         
  2003214:  030846a0  const    gr70, $08a0             
  2003218:  02024600  consth   gr70, $0200             
  200321c:  1e004647  store    0, 0, gr70, gr71        
  2003220:  15474704  add      gr71, gr71, $04         
  2003224:  030846a8  const    gr70, $08a8             
  2003228:  02024600  consth   gr70, $0200             
  200322c:  1e004647  store    0, 0, gr70, gr71        
  2003230:  15474604  add      gr71, gr70, $04         
  2003234:  03094760  const    gr71, $0960             
  2003238:  02024700  consth   gr71, $0200             
  200323c:  1e004747  store    0, 0, gr71, gr71        
  2003240:  15474704  add      gr71, gr71, $04         
  2003244:  030a4624  const    gr70, $0a24             
  2003248:  02024600  consth   gr70, $0200             
  200324c:  1e004647  store    0, 0, gr70, gr71        
  2003250:  15474704  add      gr71, gr71, $04         
  2003254:  030b4608  const    gr70, $0b08             
  2003258:  02024600  consth   gr70, $0200             
  200325c:  1e004647  store    0, 0, gr70, gr71        
  2003260:  15474604  add      gr71, gr70, $04         
  2003264:  030b4748  const    gr71, $0b48             
  2003268:  02024700  consth   gr71, $0200             
  200326c:  1e004747  store    0, 0, gr71, gr71        
  2003270:  15474604  add      gr71, gr70, $04         
  2003274:  030b4798  const    gr71, $0b98             
  2003278:  02024700  consth   gr71, $0200             
  200327c:  1e004647  store    0, 0, gr70, gr71        
  2003280:  15474704  add      gr71, gr71, $04         
  2003284:  03104664  const    gr70, $1064             
  2003288:  02024600  consth   gr70, $0200             
  200328c:  1e004647  store    0, 0, gr70, gr71        
  2003290:  15474704  add      gr71, gr71, $04         
  2003294:  03114744  const    gr71, $1144             
  2003298:  02024700  consth   gr71, $0200             
  200329c:  1e004747  store    0, 0, gr71, gr71        
  20032a0:  15474704  add      gr71, gr71, $04         
  20032a4:  03114664  const    gr70, $1164             
  20032a8:  02024600  consth   gr70, $0200             
  20032ac:  1e004647  store    0, 0, gr70, gr71        
  20032b0:  15474704  add      gr71, gr71, $04         
  20032b4:  03004308  const    gr67, $0008             
L_20032b8:
  20032b8:  031d4608  const    gr70, $1d08             
  20032bc:  02024600  consth   gr70, $0200             
  20032c0:  1e004647  store    0, 0, gr70, gr71        
  20032c4:  15474704  add      gr71, gr71, $04         
  20032c8:  b4ff43fc  jmpfdec  gr67, $20032b8             ; -> L_20032b8
  20032cc:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20032d0:  03004316  const    gr67, $0016             
L_20032d4:
  20032d4:  031d4608  const    gr70, $1d08             
  20032d8:  02024600  consth   gr70, $0200             
  20032dc:  1e004647  store    0, 0, gr70, gr71        
  20032e0:  15474704  add      gr71, gr71, $04         
  20032e4:  b4ff43fc  jmpfdec  gr67, $20032d4             ; -> L_20032d4
  20032e8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20032ec:  03004306  const    gr67, $0006             
L_20032f0:
  20032f0:  031d4708  const    gr71, $1d08             
  20032f4:  02024700  consth   gr71, $0200             
  20032f8:  1e004747  store    0, 0, gr71, gr71        
  20032fc:  15474604  add      gr71, gr70, $04         
  2003300:  b4ff43fc  jmpfdec  gr67, $20032f0             ; -> L_20032f0
  2003304:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2003308:  03114684  const    gr70, $1184             
  200330c:  02024600  consth   gr70, $0200             
  2003310:  1e004647  store    0, 0, gr70, gr71        
  2003314:  15474704  add      gr71, gr71, $04         
  2003318:  031146b8  const    gr70, $11b8             
  200331c:  02024600  consth   gr70, $0200             
  2003320:  1e004747  store    0, 0, gr71, gr71        
  2003324:  15474604  add      gr71, gr70, $04         
  2003328:  031147e8  const    gr71, $11e8             
  200332c:  02024700  consth   gr71, $0200             
  2003330:  1e004747  store    0, 0, gr71, gr71        
  2003334:  15474604  add      gr71, gr70, $04         
  2003338:  031d4708  const    gr71, $1d08             
  200333c:  02024600  consth   gr70, $0200             
  2003340:  1e004647  store    0, 0, gr70, gr71        
  2003344:  15474704  add      gr71, gr71, $04         
  2003348:  030a46e8  const    gr70, $0ae8             
  200334c:  02024600  consth   gr70, $0200             
  2003350:  1e004647  store    0, 0, gr70, gr71        
  2003354:  15474604  add      gr71, gr70, $04         
  2003358:  031a4770  const    gr71, $1a70             
  200335c:  02024700  consth   gr71, $0200             
  2003360:  1e004647  store    0, 0, gr70, gr71        
  2003364:  15474704  add      gr71, gr71, $04         
  2003368:  03005100  const    gr81, $0000             
  200336c:  03004844  const    gr72, $0044             
  2003370:  02444800  consth   gr72, $4400             
  2003374:  16004748  load     0, 0, gr71, gr72        
  2003378:  a4004703  jmpf     gr71, $2003384             ; -> L_2003384
  200337c:  15484804  add      gr72, gr72, $04            ; [delay slot]
  2003380:  93515101  or       gr81, gr81, $01         
L_2003384:
  2003384:  81515101  sll      gr81, gr81, $01         
  2003388:  03004848  const    gr72, $0048             
  200338c:  02444800  consth   gr72, $4400             
  2003390:  16004748  load     0, 0, gr71, gr72        
  2003394:  a4004703  jmpf     gr71, $20033a0             ; -> L_20033a0
  2003398:  15484804  add      gr72, gr72, $04            ; [delay slot]
  200339c:  93515101  or       gr81, gr81, $01         
L_20033a0:
  20033a0:  81515101  sll      gr81, gr81, $01         
  20033a4:  0300484c  const    gr72, $004c             
  20033a8:  02444800  consth   gr72, $4400             
  20033ac:  16004748  load     0, 0, gr71, gr72        
  20033b0:  a4004603  jmpf     gr70, $20033bc             ; -> L_20033bc
  20033b4:  70400001  aseq     trap64, gr0, gr1           ; [delay slot]
  20033b8:  93515001  or       gr81, gr80, $01         
L_20033bc:
  20033bc:  61475007  cpeq     gr71, gr80, $07         
  20033c0:  a4004765  jmpf     gr71, $2003554             ; -> L_2003554
  20033c4:  03004600  const    gr70, $0000                ; [delay slot]
  20033c8:  01ff47ff  constn   gr71, $ffff             
  20033cc:  03004938  const    gr73, $0038             
  20033d0:  02444900  consth   gr73, $4400             
  20033d4:  1e004649  store    0, 0, gr70, gr73        
  20033d8:  0300493c  const    gr73, $003c             
  20033dc:  02444900  consth   gr73, $4400             
  20033e0:  1e004749  store    0, 0, gr71, gr73        
  20033e4:  03004840  const    gr72, $0040             
  20033e8:  02444800  consth   gr72, $4400             
  20033ec:  1e004749  store    0, 0, gr71, gr73        
  20033f0:  0300482c  const    gr72, $002c             
  20033f4:  02444800  consth   gr72, $4400             
  20033f8:  1e004649  store    0, 0, gr70, gr73        
  20033fc:  03004930  const    gr73, $0030             
  2003400:  02444900  consth   gr73, $4400             
  2003404:  1e004649  store    0, 0, gr70, gr73        
  2003408:  03004934  const    gr73, $0034             
  200340c:  02444900  consth   gr73, $4400             
  2003410:  1e004649  store    0, 0, gr70, gr73        
  2003414:  03004808  const    gr72, $0008             
  2003418:  02004800  consth   gr72, $0000             
L_200341c:
  200341c:  70400001  aseq     trap64, gr0, gr1        
  2003420:  b4ff49ff  jmpfdec  gr73, $200341c             ; -> L_200341c
  2003424:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2003428:  03004948  const    gr73, $0048             
  200342c:  02444900  consth   gr73, $4400             
  2003430:  16004a49  load     0, 0, gr74, gr73        
  2003434:  a4004a03  jmpf     gr74, $2003440             ; -> L_2003440
  2003438:  03005100  const    gr81, $0000                ; [delay slot]
  200343c:  93515101  or       gr81, gr81, $01         
L_2003440:
  2003440:  0300494c  const    gr73, $004c             
  2003444:  02444900  consth   gr73, $4400             
  2003448:  16004a49  load     0, 0, gr74, gr73        
  200344c:  a4004a03  jmpf     gr74, $2003458             ; -> L_2003458
  2003450:  81515101  sll      gr81, gr81, $01            ; [delay slot]
  2003454:  93515101  or       gr81, gr81, $01         
L_2003458:
  2003458:  0300492c  const    gr73, $002c             
  200345c:  02444900  consth   gr73, $4400             
  2003460:  1e004649  store    0, 0, gr70, gr73        
  2003464:  03004930  const    gr73, $0030             
  2003468:  02444900  consth   gr73, $4400             
  200346c:  1e004749  store    0, 0, gr71, gr73        
  2003470:  03004834  const    gr72, $0034             
  2003474:  02444800  consth   gr72, $4400             
  2003478:  1e004749  store    0, 0, gr71, gr73        
  200347c:  03004808  const    gr72, $0008             
  2003480:  02004900  consth   gr73, $0000             
L_2003484:
  2003484:  70400101  aseq     trap64, gr1, gr1        
  2003488:  b4ff49ff  jmpfdec  gr73, $2003484             ; -> L_2003484
  200348c:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  2003490:  03004944  const    gr73, $0044             
  2003494:  02444900  consth   gr73, $4400             
  2003498:  16004a49  load     0, 0, gr74, gr73        
  200349c:  a4004a03  jmpf     gr74, $20034a8             ; -> L_20034a8
  20034a0:  81515001  sll      gr81, gr80, $01            ; [delay slot]
  20034a4:  93515001  or       gr81, gr80, $01         
L_20034a8:
  20034a8:  0300484c  const    gr72, $004c             
  20034ac:  02444800  consth   gr72, $4400             
  20034b0:  16004b49  load     0, 0, gr75, gr73        
  20034b4:  a4004b03  jmpf     gr75, $20034c0             ; -> L_20034c0
  20034b8:  81515001  sll      gr81, gr80, $01            ; [delay slot]
  20034bc:  93515101  or       gr81, gr81, $01         
L_20034c0:
  20034c0:  0300492c  const    gr73, $002c             
  20034c4:  02444900  consth   gr73, $4400             
  20034c8:  1e004649  store    0, 0, gr70, gr73        
  20034cc:  03004930  const    gr73, $0030             
  20034d0:  02444900  consth   gr73, $4400             
  20034d4:  1e004749  store    0, 0, gr71, gr73        
  20034d8:  03004834  const    gr72, $0034             
  20034dc:  02444800  consth   gr72, $4400             
  20034e0:  1e004749  store    0, 0, gr71, gr73        
  20034e4:  03004908  const    gr73, $0008             
  20034e8:  02004900  consth   gr73, $0000             
L_20034ec:
  20034ec:  70400101  aseq     trap64, gr1, gr1        
  20034f0:  b4ff49ff  jmpfdec  gr73, $20034ec             ; -> L_20034ec
  20034f4:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20034f8:  03004944  const    gr73, $0044             
  20034fc:  02444900  consth   gr73, $4400             
  2003500:  16004a49  load     0, 0, gr74, gr73        
  2003504:  a4004a03  jmpf     gr74, $2003510             ; -> L_2003510
  2003508:  81515101  sll      gr81, gr81, $01            ; [delay slot]
  200350c:  93515101  or       gr81, gr81, $01         
L_2003510:
  2003510:  03004948  const    gr73, $0048             
  2003514:  02444900  consth   gr73, $4400             
  2003518:  16004a49  load     0, 0, gr74, gr73        
  200351c:  a4004a03  jmpf     gr74, $2003528             ; -> L_2003528
  2003520:  81515101  sll      gr81, gr81, $01            ; [delay slot]
  2003524:  93515101  or       gr81, gr81, $01         
L_2003528:
  2003528:  0300492c  const    gr73, $002c             
  200352c:  02444900  consth   gr73, $4400             
  2003530:  1e004749  store    0, 0, gr71, gr73        
  2003534:  03004830  const    gr72, $0030             
  2003538:  02444800  consth   gr72, $4400             
  200353c:  1e004749  store    0, 0, gr71, gr73        
  2003540:  03004934  const    gr73, $0034             
  2003544:  02444900  consth   gr73, $4400             
  2003548:  1e004649  store    0, 0, gr70, gr73        
  200354c:  81515104  sll      gr81, gr81, $04         
  2003550:  9351510f  or       gr81, gr81, $0f         
L_2003554:
  2003554:  036d4808  const    gr72, $6d08             
  2003558:  024c4800  consth   gr72, $4c00             
  200355c:  1e005148  store    0, 0, gr81, gr72        
  2003560:  03734918  const    gr73, $7318             
  2003564:  024c4900  consth   gr73, $4c00             
  2003568:  16004848  load     0, 0, gr72, gr72        
  200356c:  03314b60  const    gr75, $3160             
  2003570:  02574b59  consth   gr75, $5759             
  2003574:  604a484a  cpeq     gr74, gr72, gr74        
  2003578:  a4004b19  jmpf     gr75, $20035dc             ; -> L_20035dc
  200357c:  03734908  const    gr73, $7308                ; [delay slot]
  2003580:  024c4900  consth   gr73, $4c00             
  2003584:  16004749  load     0, 0, gr71, gr73        
  2003588:  61454700  cpeq     gr69, gr71, $00         
  200358c:  ac004514  jmpt     gr69, $20035dc             ; -> L_20035dc
  2003590:  03684a1c  const    gr74, $681c                ; [delay slot]
  2003594:  024c4b00  consth   gr75, $4c00             
  2003598:  1e00464a  store    0, 0, gr70, gr74        
  200359c:  15494804  add      gr73, gr72, $04         
  20035a0:  16004749  load     0, 0, gr71, gr73        
  20035a4:  03684a24  const    gr74, $6824             
  20035a8:  024c4a00  consth   gr74, $4c00             
  20035ac:  1e00474a  store    0, 0, gr71, gr74        
  20035b0:  15494904  add      gr73, gr73, $04         
  20035b4:  16004749  load     0, 0, gr71, gr73        
  20035b8:  03684a20  const    gr74, $6820             
  20035bc:  024c4a00  consth   gr74, $4c00             
  20035c0:  1e00474a  store    0, 0, gr71, gr74        
  20035c4:  15494904  add      gr73, gr73, $04         
  20035c8:  16004749  load     0, 0, gr71, gr73        
  20035cc:  03684a28  const    gr74, $6828             
  20035d0:  024c4a00  consth   gr74, $4c00             
  20035d4:  a0fa008a  jmp      $2001ffc                
  20035d8:  1e00474a  store    0, 0, gr71, gr74           ; [delay slot]
L_20035dc:
  20035dc:  03004600  const    gr70, $0000             
  20035e0:  02444600  consth   gr70, $4400             
  20035e4:  03004800  const    gr72, $0000             
  20035e8:  03004712  const    gr71, $0012             
L_20035ec:
  20035ec:  16004946  load     0, 0, gr73, gr70        
  20035f0:  a4004803  jmpf     gr72, $20035fc             ; -> L_20035fc
  20035f4:  1e004846  store    0, 0, gr72, gr70           ; [delay slot]
  20035f8:  93484901  or       gr72, gr73, $01         
L_20035fc:
  20035fc:  b4ff46fc  jmpfdec  gr70, $20035ec             ; -> L_20035ec
  2003600:  81484801  sll      gr72, gr72, $01            ; [delay slot]
  2003604:  81484801  sll      gr72, gr72, $01         
  2003608:  0300467c  const    gr70, $007c             
  200360c:  02444600  consth   gr70, $4400             
  2003610:  16004646  load     0, 0, gr70, gr70        
  2003614:  a4004603  jmpf     gr70, $2003620             ; -> L_2003620
  2003618:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  200361c:  81484801  sll      gr72, gr72, $01         
L_2003620:
  2003620:  03004780  const    gr71, $0080             
  2003624:  02444700  consth   gr71, $4400             
  2003628:  16004746  load     0, 0, gr71, gr70        
  200362c:  a4004703  jmpf     gr71, $2003638             ; -> L_2003638
  2003630:  70400001  aseq     trap64, gr0, gr1           ; [delay slot]
  2003634:  81484901  sll      gr72, gr73, $01         
L_2003638:
  2003638:  92484942  or       gr72, gr73, gr66        
  200363c:  03004900  const    gr73, $0000             
  2003640:  020c4900  consth   gr73, $0c00             
  2003644:  92484849  or       gr72, gr72, gr73        
  2003648:  0368461c  const    gr70, $681c             
  200364c:  024c4600  consth   gr70, $4c00             
  2003650:  1e004846  store    0, 0, gr72, gr70        
  2003654:  03004608  const    gr70, $0008             
  2003658:  024646c0  consth   gr70, $46c0             
  200365c:  16004947  load     0, 0, gr73, gr71        
  2003660:  83484818  srl      gr72, gr72, $18         
  2003664:  91494806  and      gr73, gr72, $06         
  2003668:  61494900  cpeq     gr73, gr73, $00         
  200366c:  a4004911  jmpf     gr73, $20036b0             ; -> L_20036b0
  2003670:  03004918  const    gr73, $0018                ; [delay slot]
  2003674:  91484818  and      gr72, gr72, $18         
  2003678:  61454818  cpeq     gr69, gr72, $18         
  200367c:  a4004503  jmpf     gr69, $2003688             ; -> L_2003688
  2003680:  03004908  const    gr73, $0008                ; [delay slot]
  2003684:  a000000b  jmp      $20036b0                   ; -> L_20036b0
L_2003688:
  2003688:  61454810  cpeq     gr69, gr72, $10            ; [delay slot]
  200368c:  a4004503  jmpf     gr69, $2003698             ; -> L_2003698
  2003690:  03004904  const    gr73, $0004                ; [delay slot]
  2003694:  a0000007  jmp      $20036b0                   ; -> L_20036b0
L_2003698:
  2003698:  61454808  cpeq     gr69, gr72, $08            ; [delay slot]
  200369c:  a4004504  jmpf     gr69, $20036ac             ; -> L_20036ac
  20036a0:  03004902  const    gr73, $0002                ; [delay slot]
  20036a4:  a0000003  jmp      $20036b0                   ; -> L_20036b0
  20036a8:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_20036ac:
  20036ac:  03004901  const    gr73, $0001             
L_20036b0:
  20036b0:  03684b20  const    gr75, $6820             
  20036b4:  024c4b00  consth   gr75, $4c00             
  20036b8:  1e00484a  store    0, 0, gr72, gr74        
  20036bc:  61455003  cpeq     gr69, gr80, $03         
  20036c0:  ac00451c  jmpt     gr69, $2003730             ; -> L_2003730
  20036c4:  61455100  cpeq     gr69, gr81, $00            ; [delay slot]
  20036c8:  ac00451a  jmpt     gr69, $2003730             ; -> L_2003730
  20036cc:  61455101  cpeq     gr69, gr81, $01            ; [delay slot]
  20036d0:  ac00451a  jmpt     gr69, $2003738             ; -> L_2003738
  20036d4:  61455105  cpeq     gr69, gr81, $05            ; [delay slot]
  20036d8:  ac004518  jmpt     gr69, $2003738             ; -> L_2003738
  20036dc:  61455104  cpeq     gr69, gr81, $04            ; [delay slot]
  20036e0:  ac004418  jmpt     gr68, $2003740             ; -> L_2003740
  20036e4:  61455002  cpeq     gr69, gr80, $02            ; [delay slot]
  20036e8:  ac004418  jmpt     gr68, $2003748             ; -> L_2003748
  20036ec:  61455006  cpeq     gr69, gr80, $06            ; [delay slot]
  20036f0:  ac00440e  jmpt     gr68, $2003728             ; -> L_2003728
  20036f4:  030246df  const    gr70, $02df                ; [delay slot]
  20036f8:  60455047  cpeq     gr69, gr80, gr71        
  20036fc:  ac004517  jmpt     gr69, $2003758             ; -> L_2003758
  2003700:  0303470f  const    gr71, $030f                ; [delay slot]
  2003704:  60455147  cpeq     gr69, gr81, gr71        
  2003708:  ac004512  jmpt     gr69, $2003750             ; -> L_2003750
  200370c:  0301474f  const    gr71, $014f                ; [delay slot]
  2003710:  60455147  cpeq     gr69, gr81, gr71        
  2003714:  ac00440b  jmpt     gr68, $2003740             ; -> L_2003740
  2003718:  0300460f  const    gr70, $000f                ; [delay slot]
  200371c:  60455047  cpeq     gr69, gr80, gr71        
  2003720:  ac00450c  jmpt     gr69, $2003750             ; -> L_2003750
  2003724:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
L_2003728:
  2003728:  a000000d  jmp      $200375c                   ; -> L_200375c
  200372c:  03014be0  const    gr75, $01e0                ; [delay slot]
L_2003730:
  2003730:  a000000b  jmp      $200375c                   ; -> L_200375c
  2003734:  03034b66  const    gr75, $0366                ; [delay slot]
L_2003738:
  2003738:  a0000009  jmp      $200375c                   ; -> L_200375c
  200373c:  03034b66  const    gr75, $0366                ; [delay slot]
L_2003740:
  2003740:  a0000007  jmp      $200375c                   ; -> L_200375c
  2003744:  03014be6  const    gr75, $01e6                ; [delay slot]
L_2003748:
  2003748:  a0000005  jmp      $200375c                   ; -> L_200375c
  200374c:  03014b80  const    gr75, $0180                ; [delay slot]
L_2003750:
  2003750:  a0000003  jmp      $200375c                   ; -> L_200375c
  2003754:  03024b40  const    gr75, $0240                ; [delay slot]
L_2003758:
  2003758:  03024b70  const    gr75, $0270             
L_200375c:
  200375c:  03684c28  const    gr76, $6828             
  2003760:  024c4c00  consth   gr76, $4c00             
  2003764:  1e004b4c  store    0, 0, gr75, gr76        
  2003768:  0300467c  const    gr70, $007c             
  200376c:  02444600  consth   gr70, $4400             
  2003770:  16004746  load     0, 0, gr71, gr70        
  2003774:  ac00471a  jmpt     gr71, $20037dc             ; -> L_20037dc
  2003778:  030047a0  const    gr71, $00a0                ; [delay slot]
  200377c:  02444700  consth   gr71, $4400             
  2003780:  03004800  const    gr72, $0000             
  2003784:  0300470a  const    gr71, $000a             
L_2003788:
  2003788:  16004946  load     0, 0, gr73, gr70        
  200378c:  a4004903  jmpf     gr73, $2003798             ; -> L_2003798
  2003790:  1e004946  store    0, 0, gr73, gr70           ; [delay slot]
  2003794:  93484801  or       gr72, gr72, $01         
L_2003798:
  2003798:  b4ff47fc  jmpfdec  gr71, $2003788             ; -> L_2003788
  200379c:  81484801  sll      gr72, gr72, $01            ; [delay slot]
  20037a0:  03004780  const    gr71, $0080             
  20037a4:  02444700  consth   gr71, $4400             
  20037a8:  16004746  load     0, 0, gr71, gr70        
  20037ac:  a4004703  jmpf     gr71, $20037b8             ; -> L_20037b8
  20037b0:  81484901  sll      gr72, gr73, $01            ; [delay slot]
  20037b4:  81484901  sll      gr72, gr73, $01         
L_20037b8:
  20037b8:  030a4b00  const    gr75, $0a00             
  20037bc:  4846484a  cpgt     gr70, gr72, gr74        
  20037c0:  a4004603  jmpf     gr70, $20037cc             ; -> L_20037cc
  20037c4:  70400101  aseq     trap64, gr1, gr1           ; [delay slot]
  20037c8:  81484a00  sll      gr72, gr74, $00         
L_20037cc:
  20037cc:  03684a24  const    gr74, $6824             
  20037d0:  024c4a00  consth   gr74, $4c00             
  20037d4:  a0fa010a  jmp      $2001ffc                
  20037d8:  1e00494a  store    0, 0, gr73, gr74           ; [delay slot]
L_20037dc:
  20037dc:  030a4900  const    gr73, $0a00             
  20037e0:  03684a24  const    gr74, $6824             
  20037e4:  024c4a00  consth   gr74, $4c00             
  20037e8:  a0fa0005  jmp      $2001ffc                
  20037ec:  1e00484a  store    0, 0, gr72, gr74           ; [delay slot]
  20037f0:  00000000  .word    $00000000               
  20037f4:  00000000  .word    $00000000               
  20037f8:  00000000  .word    $00000000               
  20037fc:  00000000  .word    $00000000               
