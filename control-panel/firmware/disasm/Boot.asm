* ==================================================================
*  ACEF_1 "Runtime" -- Boot  (Am29000, base $2003000)
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
*  gr0-write check (same methodology as ACEF_100_Antelope, see
*  firmware/README.md): 1 of 512 instructions (0.20%) writes to the
*  hardwired-zero gr0 register -- an architecturally impossible
*  instruction, so this is almost certainly an embedded literal, not
*  executed code. Address: $20031e8. The trailing 4 words at
*  $20037f0-$20037fc also decode as `.word` (not valid instructions),
*  consistent with a small data table at the end of the boot code.
  2003000:  0300460c  const    gr70, $000c             
  2003004:  024447cc  consth   gr71, $44cc             
  2003008:  03004088  const    gr64, $0088             
  200300c:  0300449a  const    gr68, $009a             
  2003010:  16004a02  load     0, 0, gr74, gr2         
  2003014:  ac00359b  jmpt     gr53, $2003280             ; -> L_2003280
  2003018:  1e0035d6  store    0, 0, gr53, lr86           ; [delay slot]
L_200301c:
  200301c:  93423eed  or       gr66, gr62, $ed         
  2003020:  15463a7c  add      gr70, gr58, $7c         
  2003024:  b4ff3a33  jmpfdec  gr58, $2002cf0          
  2003028:  81423c85  sll      gr66, gr60, $85            ; [delay slot]
  200302c:  83423d89  srl      gr66, gr61, $89         
  2003030:  04007c40  mtsrim   spr124, $0040           
  2003034:  81423a90  sll      gr66, gr58, $90         
  2003038:  04047af7  mtsrim   spr122, $04f7           
  200303c:  03683ff4  const    gr63, $68f4             
  2003040:  024c3f04  consth   gr63, $4c04             
  2003044:  1e003b5f  store    0, 0, gr59, gr95        
  2003048:  03643a48  const    gr58, $6448             
  200304c:  024c392c  consth   gr57, $4c2c             
  2003050:  16003a3b  load     0, 0, gr58, gr59        
  2003054:  036a3254  const    gr50, $6a54             
  2003058:  024c3244  consth   gr50, $4c44             
  200305c:  0300339c  const    gr51, $009c             
  2003060:  02003300  consth   gr51, $0000             
  2003064:  1e003285  store    0, 0, gr50, lr5         
  2003068:  03533188  const    gr49, $5388             
  200306c:  02423098  consth   gr48, $4298             
  2003070:  03643144  const    gr49, $6444             
  2003074:  024c3698  consth   gr54, $4c98             
  2003078:  160038d6  load     0, 0, gr56, lr86        
  200307c:  604838ab  cpeq     gr72, gr56, lr43        
  2003080:  a4ff3886  jmpf     gr56, $2002e98          
  2003084:  030039c8  const    gr57, $00c8                ; [delay slot]
  2003088:  1e003ac2  store    0, 0, gr58, lr66        
  200308c:  1e003bc1  store    0, 0, gr59, lr65        
  2003090:  03643464  const    gr52, $6464             
  2003094:  024c2b8c  consth   gr43, $4c8c             
  2003098:  16002bcf  load     0, 0, gr43, lr79        
  200309c:  036424f8  const    gr36, $64f8             
  20030a0:  024c2404  consth   gr36, $4c04             
  20030a4:  16002550  load     0, 0, gr37, gr80        
  20030a8:  03642478  const    gr36, $6478             
  20030ac:  024c272c  consth   gr39, $4c2c             
  20030b0:  16002731  load     0, 0, gr39, gr49        
  20030b4:  14482741  add      gr72, gr39, gr65        
  20030b8:  03642668  const    gr38, $6468             
  20030bc:  024c2108  consth   gr33, $4c08             
  20030c0:  16002149  load     0, 0, gr33, gr73        
  20030c4:  834920ce  srl      gr73, gr32, $ce         
  20030c8:  2549238a  sub      gr73, gr35, $8a         
  20030cc:  160021d0  load     0, 0, gr33, lr80        
  20030d0:  15482340  add      gr72, gr35, $40         
  20030d4:  1e002edf  store    0, 0, gr46, lr95        
  20030d8:  b4ff2d6d  jmpfdec  gr45, $2002e8c          
  20030dc:  154723e8  add      gr71, gr35, $e8            ; [delay slot]
  20030e0:  03ff2d87  const    gr45, $ff87             
  20030e4:  020f2c37  consth   gr44, $0f37             
  20030e8:  03682188  const    gr33, $6888             
  20030ec:  024c2088  consth   gr32, $4c88             
  20030f0:  16002f07  load     0, 0, gr47, gr7         
  20030f4:  904828c5  and      gr72, gr40, lr69        
  20030f8:  924828ca  or       gr72, gr40, lr74        
  20030fc:  1e00289f  store    0, 0, gr40, lr31        
  2003100:  15472700  add      gr71, gr39, $00         
  2003104:  1600295f  load     0, 0, gr41, gr95        
  2003108:  90482919  and      gr72, gr41, gr25        
  200310c:  92482a6e  or       gr72, gr42, gr110       
  2003110:  1e002a3f  store    0, 0, gr42, gr63        
  2003114:  1547240c  add      gr71, gr36, $0c         
  2003118:  16002b03  load     0, 0, gr43, gr3         
  200311c:  90481441  and      gr72, gr20, gr65        
  2003120:  92481442  or       gr72, gr20, gr66        
  2003124:  1e00158b  store    0, 0, gr21, lr11        
  2003128:  1547198c  add      gr71, gr25, $8c         
  200312c:  160017df  load     0, 0, gr23, lr95        
  2003130:  9048170d  and      gr72, gr23, gr13        
  2003134:  924810da  or       gr72, gr16, lr90        
  2003138:  1e0010d7  store    0, 0, gr16, lr87        
  200313c:  03001fec  const    gr31, $00ec             
  2003140:  024c1f78  consth   gr31, $4c78             
  2003144:  ce00598f  mtsr     spr89, lr15             
L_2003148:
  2003148:  c6465984  mfsr     gr70, spr89             
  200314c:  93461d98  or       gr70, gr29, $98         
  2003150:  ce005806  mtsr     spr88, gr6              
  2003154:  0300128c  const    gr18, $008c             
  2003158:  02021288  consth   gr18, $0288             
  200315c:  1e00129f  store    0, 0, gr18, lr31        
  2003160:  15471300  add      gr71, gr19, $00         
  2003164:  03001310  const    gr19, $0010             
  2003168:  02021350  consth   gr19, $0250             
  200316c:  1e00106b  store    0, 0, gr16, gr107       
  2003170:  1547117c  add      gr71, gr17, $7c         
  2003174:  03091100  const    gr17, $0900             
  2003178:  02021144  consth   gr17, $0244             
  200317c:  1e00164f  store    0, 0, gr22, gr79        
  2003180:  15471704  add      gr71, gr23, $04         
  2003184:  030917ec  const    gr23, $09ec             
  2003188:  02021488  consth   gr20, $0288             
  200318c:  1e0015df  store    0, 0, gr21, lr95        
  2003190:  15471440  add      gr71, gr20, $40         
  2003194:  03090ab0  const    gr10, $09b0             
  2003198:  02020a90  consth   gr10, $0290             
  200319c:  1e000aab  store    0, 0, gr10, lr43        
  20031a0:  15470b7c  add      gr71, gr11, $7c         
  20031a4:  03090b88  const    gr11, $0988             
  20031a8:  02020884  consth   gr8, $0284              
  20031ac:  1e0009cf  store    0, 0, gr9, lr79         
  20031b0:  15470844  add      gr71, gr8, $44          
  20031b4:  03060ec8  const    gr14, $06c8             
  20031b8:  02020e88  consth   gr14, $0288             
  20031bc:  1e000e9f  store    0, 0, gr14, lr31        
  20031c0:  15470f00  add      gr71, gr15, $00         
  20031c4:  03030f40  const    gr15, $0340             
  20031c8:  02020f50  consth   gr15, $0250             
L_20031cc:
  20031cc:  1e000c6b  store    0, 0, gr12, gr107       
  20031d0:  15470d7c  add      gr71, gr13, $7c         
  20031d4:  03060d78  const    gr13, $0678             
  20031d8:  02020d44  consth   gr13, $0244             
  20031dc:  1e00024f  store    0, 0, gr2, gr79         
  20031e0:  15470304  add      gr71, gr3, $04          
  20031e4:  030703d8  const    gr3, $07d8              
  20031e8:  02020088  consth   gr0, $0288              
  20031ec:  1e0001df  store    0, 0, gr1, lr95         
  20031f0:  15470040  add      gr71, gr0, $40          
  20031f4:  030606e8  const    gr6, $06e8              
  20031f8:  02020690  consth   gr6, $0290              
  20031fc:  1e0006ab  store    0, 0, gr6, lr43         
  2003200:  1547077c  add      gr71, gr7, $7c          
  2003204:  030707dc  const    gr7, $07dc              
  2003208:  02020484  consth   gr4, $0284              
  200320c:  1e0005cf  store    0, 0, gr5, lr79         
  2003210:  15470444  add      gr71, gr4, $44          
  2003214:  0309fa2c  const    lr122, $092c            
  2003218:  0203fa88  consth   lr122, $0388            
  200321c:  1e01fa9f  store    0, 1, lr122, lr31       
  2003220:  1546fb00  add      gr70, lr123, $00        
  2003224:  0309fbb0  const    lr123, $09b0            
  2003228:  0203fb50  consth   lr123, $0350            
  200322c:  1e01f86b  store    0, 1, lr120, gr107      
  2003230:  1546f97c  add      gr70, lr121, $7c        
  2003234:  0308f968  const    lr121, $0868            
  2003238:  0203f944  consth   lr121, $0344            
  200323c:  1e01fe4f  store    0, 1, lr126, gr79       
  2003240:  1546ff04  add      gr70, lr127, $04        
  2003244:  030bffe8  const    lr127, $0be8            
  2003248:  0203fc88  consth   lr124, $0388            
  200324c:  1e01fddf  store    0, 1, lr125, lr95       
  2003250:  1546fc40  add      gr70, lr124, $40        
  2003254:  030af290  const    lr114, $0a90            
  2003258:  0203f290  consth   lr114, $0390            
  200325c:  1e01f2ab  store    0, 1, lr114, lr43       
  2003260:  1546f37c  add      gr70, lr115, $7c        
  2003264:  030af380  const    lr115, $0a80            
  2003268:  0203f084  consth   lr112, $0384            
  200326c:  1e01f1cf  store    0, 1, lr113, lr79       
  2003270:  1546f044  add      gr70, lr112, $44        
  2003274:  030af614  const    lr118, $0a14            
  2003278:  0203f688  consth   lr118, $0388            
  200327c:  1e01f69f  store    0, 1, lr118, lr31       
L_2003280:
  2003280:  1546f700  add      gr70, lr119, $00        
  2003284:  0311f77c  const    lr119, $117c            
  2003288:  0203f750  consth   lr119, $0350            
  200328c:  1e01f46b  store    0, 1, lr116, gr107      
  2003290:  1546f57c  add      gr70, lr117, $7c        
  2003294:  0310f54c  const    lr117, $104c            
  2003298:  0203f544  consth   lr117, $0344            
  200329c:  1e01ea4f  store    0, 1, lr106, gr79       
  20032a0:  1546eb04  add      gr70, lr107, $04        
  20032a4:  0310eba8  const    lr107, $10a8            
  20032a8:  0203e888  consth   lr104, $0388            
  20032ac:  1e01e9df  store    0, 1, lr105, lr95       
  20032b0:  1546e840  add      gr70, lr104, $40        
  20032b4:  0301eb90  const    lr107, $0190            
  20032b8:  031cee98  const    lr110, $1c98            
  20032bc:  0203eeec  consth   lr110, $03ec            
  20032c0:  1e01ee3f  store    0, 1, lr110, gr63       
  20032c4:  1546eecc  add      gr70, lr110, $cc        
  20032c8:  b4fee978  jmpfdec  lr105, $2002ca8         
  20032cc:  7041aa89  aseq     trap65, lr42, lr9          ; [delay slot]
  20032d0:  0301e856  const    lr104, $0156            
  20032d4:  031ce284  const    lr98, $1c84             
  20032d8:  0203e288  consth   lr98, $0388             
  20032dc:  1e01e29f  store    0, 1, lr98, lr31        
  20032e0:  1546e300  add      gr70, lr99, $00         
  20032e4:  b4fee6e4  jmpfdec  lr102, $2002e74         
  20032e8:  7041a451  aseq     trap65, lr36, gr81         ; [delay slot]
  20032ec:  0301e52a  const    lr101, $012a            
  20032f0:  031ce070  const    lr96, $1c70             
  20032f4:  0203e108  consth   lr97, $0308             
  20032f8:  1e01e103  store    0, 1, lr97, gr3         
  20032fc:  1546e70c  add      gr70, lr103, $0c        
  2003300:  b4fee3fc  jmpfdec  lr99, $2002ef0          
  2003304:  7041a0cd  aseq     trap65, lr32, lr77         ; [delay slot]
  2003308:  0310e40c  const    lr100, $100c            
  200330c:  0203e598  consth   lr101, $0398            
  2003310:  1e01e503  store    0, 1, lr101, gr3        
  2003314:  1546db9c  add      gr70, lr91, $9c         
  2003318:  0310da28  const    lr90, $1028             
  200331c:  0203daec  consth   lr90, $03ec             
  2003320:  1e01da3f  store    0, 1, lr90, gr63        
  2003324:  1546dacc  add      gr70, lr90, $cc         
  2003328:  0310d86c  const    lr88, $106c             
  200332c:  0203d988  consth   lr89, $0388             
  2003330:  1e01d907  store    0, 1, lr89, gr7         
  2003334:  1546df88  add      gr70, lr95, $88         
  2003338:  031cde80  const    lr94, $1c80             
  200333c:  0203ded8  consth   lr94, $03d8             
  2003340:  1e01de43  store    0, 1, lr94, gr67        
  2003344:  1546de1c  add      gr70, lr94, $1c         
  2003348:  030bdfb8  const    lr95, $0bb8             
  200334c:  0203dc2c  consth   lr92, $032c             
  2003350:  1e01dc3f  store    0, 1, lr92, gr63        
  2003354:  1546dc0c  add      gr70, lr92, $0c         
  2003358:  031bdd34  const    lr93, $1b34             
  200335c:  0203d208  consth   lr82, $0308             
  2003360:  1e01d247  store    0, 1, lr82, gr71        
  2003364:  1546d2c8  add      gr70, lr82, $c8         
  2003368:  0301c788  const    lr71, $0188             
  200336c:  0301dfdc  const    lr95, $01dc             
  2003370:  0245df44  consth   lr95, $4544             
  2003374:  1601d7d0  load     0, 1, lr87, lr80        
  2003378:  a401d793  jmpf     lr87, $20039c4          
  200337c:  1549d8e8  add      gr73, lr88, $e8            ; [delay slot]
  2003380:  9350c179  or       gr80, lr65, $79         
  2003384:  8150c0c9  sll      gr80, lr64, $c9         
  2003388:  0301dacc  const    lr90, $01cc             
  200338c:  0245db88  consth   lr91, $4588             
  2003390:  1601d408  load     0, 1, lr84, gr8         
  2003394:  a401cb8f  jmpf     lr75, $20039d0          
  2003398:  1549c48c  add      gr73, lr68, $8c            ; [delay slot]
  200339c:  9350ddd9  or       gr80, lr93, $d9         
  20033a0:  8150dd05  sll      gr80, lr93, $05         
  20033a4:  0301c554  const    lr69, $0154             
  20033a8:  0245c550  consth   lr69, $4550             
  20033ac:  1601c964  load     0, 1, lr73, gr100       
  20033b0:  a401c97b  jmpf     lr73, $200399c          
  20033b4:  70418e09  aseq     trap65, lr14, gr9          ; [delay slot]
  20033b8:  9350de45  or       gr80, lr94, $45         
  20033bc:  6146d90f  cpeq     gr70, lr89, $0f         
  20033c0:  a401cf65  jmpf     lr79, $2003954          
  20033c4:  0301cfcc  const    lr79, $01cc                ; [delay slot]
  20033c8:  01fecd77  constn   lr77, $fe77             
  20033cc:  0301c2a0  const    lr66, $01a0             
  20033d0:  0245c244  consth   lr66, $4544             
  20033d4:  1e01c2d1  store    0, 1, lr66, lr81        
  20033d8:  0301cdac  const    lr77, $01ac             
  20033dc:  0245cdec  consth   lr77, $45ec             
  20033e0:  1e01c231  store    0, 1, lr66, gr49        
  20033e4:  0301cc88  const    lr76, $0188             
  20033e8:  0245cf84  consth   lr79, $4584             
  20033ec:  1e01c1c1  store    0, 1, lr65, lr65        
  20033f0:  0301ce6c  const    lr78, $016c             
  20033f4:  0245c98c  consth   lr73, $458c             
  20033f8:  1e01c7c1  store    0, 1, lr71, lr65        
  20033fc:  0301c9e8  const    lr73, $01e8             
  2003400:  0245c904  consth   lr73, $4504             
  2003404:  1e01c751  store    0, 1, lr71, gr81        
  2003408:  0301c864  const    lr72, $0164             
  200340c:  0245cb2c  consth   lr75, $452c             
  2003410:  1e01c431  store    0, 1, lr68, gr49        
  2003414:  0301ca00  const    lr74, $0100             
  2003418:  0201ca44  consth   lr74, $0144             
  200341c:  7041fd09  aseq     trap65, lr125, gr9      
  2003420:  b4feb5ff  jmpfdec  lr53, $200301c             ; -> L_200301c
  2003424:  7041fccd  aseq     trap65, lr124, lr77        ; [delay slot]
  2003428:  0301b7c0  const    lr55, $01c0             
  200342c:  0245b698  consth   lr54, $4598             
  2003430:  1601b50d  load     0, 1, lr53, gr13        
  2003434:  a401b29b  jmpf     lr50, $2003aa0          
  2003438:  0301a990  const    lr41, $0190                ; [delay slot]
  200343c:  9350a9ed  or       gr80, lr41, $ed         
  2003440:  0301b134  const    lr49, $0134             
  2003444:  0245b0c8  consth   lr48, $45c8             
  2003448:  1601b0cd  load     0, 1, lr48, lr77        
  200344c:  a401b18b  jmpf     lr49, $2003a78          
  2003450:  8150aa41  sll      gr80, lr42, $41            ; [delay slot]
  2003454:  9350a58d  or       gr80, lr37, $8d         
  2003458:  0301bda4  const    lr61, $01a4             
  200345c:  0245bdd8  consth   lr61, $45d8             
  2003460:  1e01b24d  store    0, 1, lr50, gr77        
  2003464:  0301bc28  const    lr60, $0128             
  2003468:  0245bc50  consth   lr60, $4550             
  200346c:  1e01b165  store    0, 1, lr49, gr101       
  2003470:  0301bf4c  const    lr63, $014c             
  2003474:  0245be08  consth   lr62, $4508             
  2003478:  1e01b10d  store    0, 1, lr49, gr13        
  200347c:  0301b900  const    lr57, $0100             
  2003480:  0201b900  consth   lr57, $0100             
  2003484:  7041f0cd  aseq     trap65, lr112, lr77     
  2003488:  b4febb77  jmpfdec  lr59, $2002e64          
  200348c:  7041f299  aseq     trap65, lr114, lr25        ; [delay slot]
  2003490:  0301ba00  const    lr58, $0100             
  2003494:  0245a598  consth   lr37, $4598             
  2003498:  1601a6d9  load     0, 1, lr38, lr89        
  200349c:  a401a6ef  jmpf     lr38, $2003c58          
  20034a0:  8150bd79  sll      gr80, lr61, $79            ; [delay slot]
  20034a4:  9350bcc9  or       gr80, lr60, $c9         
  20034a8:  0301a7c8  const    lr39, $01c8             
  20034ac:  0245a688  consth   lr38, $4588             
  20034b0:  1601a509  load     0, 1, lr37, gr9         
  20034b4:  a401a28f  jmpf     lr34, $2003af0          
  20034b8:  8150b989  sll      gr80, lr57, $89            ; [delay slot]
  20034bc:  9350b9d9  or       gr80, lr57, $d9         
  20034c0:  0301a128  const    lr33, $0128             
  20034c4:  0245a018  consth   lr32, $4518             
  20034c8:  1e01af19  store    0, 1, lr47, gr25        
  20034cc:  0301a31c  const    lr35, $011c             
  20034d0:  0245a378  consth   lr35, $4578             
  20034d4:  1e01ad41  store    0, 1, lr45, gr65        
  20034d8:  0301a270  const    lr34, $0170             
  20034dc:  0245ad08  consth   lr45, $4508             
  20034e0:  1e01a349  store    0, 1, lr35, gr73        
  20034e4:  0301acc4  const    lr44, $01c4             
  20034e8:  0201af88  consth   lr47, $0188             
  20034ec:  7041e699  aseq     trap65, lr102, lr25     
  20034f0:  b4feaebb  jmpfdec  lr46, $2002fdc          
  20034f4:  7041e199  aseq     trap65, lr97, lr25         ; [delay slot]
  20034f8:  0301a9d4  const    lr41, $01d4             
  20034fc:  0245a9ec  consth   lr41, $45ec             
  2003500:  1601aa31  load     0, 1, lr42, gr49        
  2003504:  a401abcb  jmpf     lr43, $2003c30          
  2003508:  8150b385  sll      gr80, lr51, $85            ; [delay slot]
  200350c:  9350b289  or       gr80, lr50, $89         
  2003510:  0301aa08  const    lr42, $0108             
  2003514:  0245958c  consth   lr21, $458c             
  2003518:  160196c1  load     0, 1, lr22, lr65        
  200351c:  a40196db  jmpf     lr22, $2003c88          
  2003520:  81508d05  sll      gr80, lr13, $05            ; [delay slot]
  2003524:  93508c19  or       gr80, lr12, $19         
  2003528:  0301947c  const    lr20, $017c             
  200352c:  0245972c  consth   lr23, $452c             
  2003530:  1e019831  store    0, 1, lr24, gr49        
  2003534:  03019638  const    lr22, $0138             
  2003538:  02459644  consth   lr22, $4544             
  200353c:  1e019e41  store    0, 1, lr30, gr65        
  2003540:  03019134  const    lr17, $0134             
  2003544:  024590cc  consth   lr16, $45cc             
  2003548:  1e019cc1  store    0, 1, lr28, lr65        
  200354c:  81508a9c  sll      gr80, lr10, $9c         
  2003550:  93508a4b  or       gr80, lr10, $4b         
  2003554:  036c9c90  const    lr28, $6c90             
  2003558:  024d9c90  consth   lr28, $4d90             
  200355c:  1e0185a4  store    0, 1, lr5, lr36         
  2003560:  03729c60  const    lr28, $7260             
  2003564:  024d9dc8  consth   lr29, $4dc8             
  2003568:  16019fcc  load     0, 1, lr31, lr76        
  200356c:  03309de8  const    lr29, $30e8             
  2003570:  02569d19  consth   lr29, $5619             
  2003574:  604b99c6  cpeq     gr75, lr25, lr70        
  2003578:  a4019a91  jmpf     lr26, $2003bbc          
  200357c:  037299d0  const    lr25, $72d0                ; [delay slot]
  2003580:  024d9904  consth   lr25, $4d04             
  2003584:  16019651  load     0, 1, lr22, gr81        
  2003588:  61449650  cpeq     gr68, lr22, $50         
  200358c:  ac019738  jmpt     lr23, $2003a6c          
  2003590:  03699864  const    lr24, $6964                ; [delay slot]
  2003594:  024d9908  consth   lr25, $4d08             
  2003598:  1e01940e  store    0, 1, lr20, gr14        
  200359c:  1548850c  add      gr72, lr5, $0c          
  20035a0:  16018b49  load     0, 1, lr11, gr73        
  20035a4:  036987e8  const    lr7, $69e8              
  20035a8:  024d8488  consth   lr4, $4d88              
  20035ac:  1e0188d2  store    0, 1, lr8, lr82         
  20035b0:  15488640  add      gr72, lr6, $40          
  20035b4:  16018fd1  load     0, 1, lr15, lr81        
  20035b8:  036982b0  const    lr2, $69b0              
  20035bc:  024d82ec  consth   lr2, $4dec              
  20035c0:  1e018f32  store    0, 1, lr15, gr50        
  20035c4:  154880cc  add      gr72, lr0, $cc          
  20035c8:  16018dcd  load     0, 1, lr13, lr77        
  20035cc:  036981a0  const    lr1, $69a0              
  20035d0:  024d8140  consth   lr1, $4d40              
  20035d4:  a0fbc406  jmp      $20021ec                
  20035d8:  1e0183c2  store    0, 1, lr3, lr66            ; [delay slot]
  20035dc:  030182d8  const    lr2, $01d8              
  20035e0:  02458204  consth   lr2, $4504              
  20035e4:  03018d18  const    lr13, $0118             
  20035e8:  03018242  const    lr2, $0142              
  20035ec:  16018f6a  load     0, 1, lr15, gr106       
  20035f0:  a4018f7b  jmpf     lr15, $2003bdc          
  20035f4:  1e018e4e  store    0, 1, lr14, gr78           ; [delay slot]
  20035f8:  93498f45  or       gr73, lr15, $45         
  20035fc:  b4fe87f4  jmpfdec  lr7, $20031cc              ; -> L_20031cc
  2003600:  81498801  sll      gr73, lr8, $01             ; [delay slot]
  2003604:  814989cd  sll      gr73, lr9, $cd          
  2003608:  030184f4  const    lr4, $01f4              
  200360c:  02458598  consth   lr5, $4598              
  2003610:  16018502  load     0, 1, lr5, gr2          
  2003614:  a4017a9b  jmpf     gr122, $2003c80         
  2003618:  70413d91  aseq     trap65, gr61, lr17         ; [delay slot]
  200361c:  814974ed  sll      gr73, gr116, $ed        
  2003620:  03017af8  const    gr122, $01f8            
  2003624:  02457bc8  consth   gr123, $45c8            
  2003628:  160178c2  load     0, 1, gr120, lr66       
  200362c:  a401798b  jmpf     gr121, $2003c58         
  2003630:  70413e41  aseq     trap65, gr62, gr65         ; [delay slot]
  2003634:  8149708d  sll      gr73, gr112, $8d        
  2003638:  924970ca  or       gr73, gr112, lr74       
  200363c:  030171d8  const    gr113, $01d8            
  2003640:  020d7104  consth   gr113, $0d04            
  2003644:  92497151  or       gr73, gr113, gr81       
  2003648:  03697f4c  const    gr127, $694c            
  200364c:  024d7c2c  consth   gr124, $4d2c            
  2003650:  1e01723e  store    0, 1, gr114, gr62       
  2003654:  03017c00  const    gr124, $0100            
  2003658:  02477c84  consth   gr124, $4784            
  200365c:  16017c4f  load     0, 1, gr124, gr79       
  2003660:  83497c18  srl      gr73, gr124, $18        
  2003664:  91487dca  and      gr72, gr125, $ca        
  2003668:  61487f88  cpeq     gr72, gr127, $88        
  200366c:  a4017e89  jmpf     gr126, $2003c90         
  2003670:  03017e5c  const    gr126, $015c               ; [delay slot]
  2003674:  91497880  and      gr73, gr120, $80        
  2003678:  61447888  cpeq     gr68, gr120, $88        
  200367c:  a40175ef  jmpf     gr117, $2003e38         
  2003680:  03017970  const    gr121, $0170               ; [delay slot]
  2003684:  a00131c3  jmp      $2003d90                
  2003688:  61447a94  cpeq     gr68, gr122, $94           ; [delay slot]
  200368c:  a401768b  jmpf     gr118, $2003cb8         
  2003690:  03017a44  const    gr122, $0144               ; [delay slot]
  2003694:  a0012c8b  jmp      $2003cc0                
  2003698:  61446480  cpeq     gr68, gr100, $80           ; [delay slot]
  200369c:  a40169dc  jmpf     gr105, $2003e0c         
  20036a0:  03016506  const    gr101, $0106               ; [delay slot]
  20036a4:  a0012d1b  jmp      $2003b10                
  20036a8:  70412c51  aseq     trap65, gr44, gr81         ; [delay slot]
  20036ac:  0301672d  const    gr103, $012d            
  20036b0:  03696458  const    gr100, $6958            
  20036b4:  024d6508  consth   gr101, $4d08            
  20036b8:  1e01660e  store    0, 1, gr102, gr14       
  20036bc:  6144790b  cpeq     gr68, gr121, $0b        
  20036c0:  ac016d1c  jmpt     gr109, $2003b30         
  20036c4:  614478cc  cpeq     gr68, gr120, $cc           ; [delay slot]
  20036c8:  ac016f92  jmpt     gr111, $2003d10         
  20036cc:  61447a99  cpeq     gr68, gr122, $99           ; [delay slot]
  20036d0:  ac016e5e  jmpt     gr110, $2003c48         
  20036d4:  6144759d  cpeq     gr68, gr117, $9d           ; [delay slot]
  20036d8:  ac016188  jmpt     gr97, $2003cf8          
  20036dc:  614475e8  cpeq     gr68, gr117, $e8           ; [delay slot]
  20036e0:  ac016160  jmpt     gr97, $2003c60          
  20036e4:  614474ca  cpeq     gr68, gr116, $ca           ; [delay slot]
  20036e8:  ac01639c  jmpt     gr99, $2003d58          
  20036ec:  6144768e  cpeq     gr68, gr118, $8e           ; [delay slot]
  20036f0:  ac01624e  jmpt     gr98, $2003c28          
  20036f4:  03036753  const    gr103, $0353               ; [delay slot]
  20036f8:  604471cf  cpeq     gr68, gr113, lr79       
  20036fc:  ac0165cf  jmpt     gr101, $2003e38         
  2003700:  0302670b  const    gr103, $020b               ; [delay slot]
  2003704:  6044705f  cpeq     gr68, gr112, gr95       
  2003708:  ac016442  jmpt     gr100, $2003c10         
  200370c:  03006563  const    gr101, $0063               ; [delay slot]
  2003710:  6044733f  cpeq     gr68, gr115, gr63       
  2003714:  ac016603  jmpt     gr102, $2003b20         
  2003718:  0301644b  const    gr100, $014b               ; [delay slot]
  200371c:  60444d4f  cpeq     gr68, gr77, gr79        
  2003720:  ac01590c  jmpt     gr89, $2003b50          
  2003724:  70411ccd  aseq     trap65, gr28, lr77         ; [delay slot]
  2003728:  a0011e85  jmp      $2003d3c                
  200372c:  03005478  const    gr84, $0078                ; [delay slot]
  2003730:  a0011f4f  jmp      $2003c6c                
  2003734:  030253fe  const    gr83, $02fe                ; [delay slot]
  2003738:  a0011899  jmp      $2003d9c                
  200373c:  0302538a  const    gr83, $028a                ; [delay slot]
  2003740:  a001187f  jmp      $2003d3c                
  2003744:  0300522e  const    gr82, $002e                ; [delay slot]
  2003748:  a0011a81  jmp      $2003d4c                
  200374c:  03005008  const    gr80, $0008                ; [delay slot]
  2003750:  a0011b43  jmp      $2003c5c                
  2003754:  03035fcc  const    gr95, $03cc                ; [delay slot]
  2003758:  03035ff8  const    gr95, $03f8             
  200375c:  036958f0  const    gr88, $69f0             
  2003760:  024d5804  consth   gr88, $4d04             
  2003764:  1e015e54  store    0, 1, gr94, gr84        
  2003768:  0301532c  const    gr83, $012c             
  200376c:  0245502c  consth   gr80, $452c             
  2003770:  1601503e  load     0, 1, gr80, gr62        
  2003774:  ac015112  jmpt     gr81, $2003bbc          
  2003778:  030151e4  const    gr81, $01e4                ; [delay slot]
  200377c:  02455608  consth   gr86, $4508             
  2003780:  03015800  const    gr88, $0100             
  2003784:  030156c6  const    gr86, $01c6             
  2003788:  16015bce  load     0, 1, gr91, lr78        
  200378c:  a4015a9b  jmpf     gr90, $2003df8          
  2003790:  1e015a02  store    0, 1, gr90, gr2            ; [delay slot]
  2003794:  93494499  or       gr73, gr68, $99         
  2003798:  b4fe4b6c  jmpfdec  gr75, $2003148             ; -> L_2003148
  200379c:  814944ed  sll      gr73, gr68, $ed            ; [delay slot]
  20037a0:  03014af8  const    gr74, $01f8             
  20037a4:  02454bc8  consth   gr75, $45c8             
  20037a8:  160148c2  load     0, 1, gr72, lr66        
  20037ac:  a401498b  jmpf     gr73, $2003dd8          
  20037b0:  81494741  sll      gr73, gr71, $41            ; [delay slot]
  20037b4:  8149408d  sll      gr73, gr64, $8d         
  20037b8:  030b4288  const    gr66, $0b88             
  20037bc:  48474092  cpgt     gr71, gr64, lr18        
  20037c0:  a4014e07  jmpf     gr78, $2003bdc          
  20037c4:  70410819  aseq     trap65, gr8, gr25          ; [delay slot]
  20037c8:  81494350  sll      gr73, gr67, $50         
  20037cc:  03694008  const    gr64, $6908             
  20037d0:  024d4078  consth   gr64, $4d78             
  20037d4:  a0fb0b02  jmp      $20023dc                
  20037d8:  1e01430e  store    0, 1, gr67, gr14           ; [delay slot]
  20037dc:  030b4c08  const    gr76, $0b08             
  20037e0:  03694e24  const    gr78, $6924             
  20037e4:  024d4fcc  consth   gr79, $4dcc             
  20037e8:  a0fb068d  jmp      $200261c                
  20037ec:  1e014fd2  store    0, 1, gr79, lr82           ; [delay slot]
  20037f0:  00010744  .word    $00010744               
  20037f4:  00010098  .word    $00010098               
  20037f8:  00010090  .word    $00010090               
  20037fc:  000100ec  .word    $000100ec               
