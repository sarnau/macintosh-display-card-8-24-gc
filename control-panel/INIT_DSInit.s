* ==================================================================
*  'DSInit'  (resource 'INIT' id -4080, 1552 bytes, from 824GC.rsrc)
* ==================================================================
*  A second, much smaller boot-time INIT ("DSInit" = plausibly "Display
*  Slot Init" or "Device/Screen Init" -- not spelled out anywhere in the
*  binary).  Unlike the '8*24 GC' INIT (INIT_main.s -- opens
*  '.GraphAccel' and drives a Control/Status handshake), this one talks
*  to the Slot Manager and Device Manager DIRECTLY (no named-driver
*  Open/Control/Status calls at all) to find and reconcile *every*
*  8*24-GC-family card in the machine, not just the accelerator.  See
*  FindGCSlot's header below for the full, well-supported reasoning.
*
*  Trap names from Apple CIncludes/Traps.h; disassembled by recursive
*  descent (same toolchain as gc24.s / DRVR.s).  The file's first
*  $446 bytes are unreached data (an unconditional 'bra' at the very
*  start jumps straight to the real code); shown as plain data.
*
* ==================================================================
* 'DSInit'  (resource 'INIT' id -4080, this file, 1552 bytes)
* ==================================================================
* The whole first $446 bytes (everything before the real entry) is
* data -- constant tables the code below reaches via PC-relative
* literals (a per-slot record-size table, a driver-name comparison
* string, and a jump-back offset table for the final cleanup).  Not
* reverse engineered field-by-field; shown as plain data.
EntryStub:
  00000:  60 00 04 44          bra.w    $446  ; -> FindGCSlot
  00004:  00 00 49 4e 49 54 f0 10 01 00 1a 2e 44 69 73 70 dc.b     $00,$00,$49,$4e,$49,$54,$f0,$10,$01,$00,$1a,$2e,$44,$69,$73,$70  ; ..INIT......Disp
  00014:  6c 61 79 5f 56 69 64 65 6f 5f 41 70 70 6c 65 5f dc.b     $6c,$61,$79,$5f,$56,$69,$64,$65,$6f,$5f,$41,$70,$70,$6c,$65,$5f  ; lay_Video_Apple_
  00024:  4d 44 43 47 43 00 01 0c 00 00 00 1d 00 00 00 01 dc.b     $4d,$44,$43,$47,$43,$00,$01,$0c,$00,$00,$00,$1d,$00,$00,$00,$01  ; MDCGC...........
  00034:  01 00 00 08 00 0a 14 1d 23 26 2b 2e 30 32 34 37 dc.b     $01,$00,$00,$08,$00,$0a,$14,$1d,$23,$26,$2b,$2e,$30,$32,$34,$37  ; ........#&+.0247
  00044:  39 3b 3c 3e 40 41 42 44 45 47 48 4a 4b 4d 4e 4f dc.b     $39,$3b,$3c,$3e,$40,$41,$42,$44,$45,$47,$48,$4a,$4b,$4d,$4e,$4f  ; 9;<>@ABDEGHJKMNO
  00054:  50 51 52 54 55 56 57 58 5a 5b 5c 5d 5e 5f 60 61 dc.b     $50,$51,$52,$54,$55,$56,$57,$58,$5a,$5b,$5c,$5d,$5e,$5f,$60,$61  ; PQRTUVWXZ[\]^_`a
  00064:  63 64 65 66 67 68 69 6a 6b 6c 6d 6e 6f 70 71 71 dc.b     $63,$64,$65,$66,$67,$68,$69,$6a,$6b,$6c,$6d,$6e,$6f,$70,$71,$71  ; cdefghijklmnopqq
  00074:  72 73 74 75 76 77 78 79 7a 7b 7c 7d 7e 7f 80 80 dc.b     $72,$73,$74,$75,$76,$77,$78,$79,$7a,$7b,$7c,$7d,$7e,$7f,$80,$80  ; rstuvwxyz{|}~...
  00084:  81 82 83 84 84 85 86 87 88 89 8a 8a 8b 8c 8d 8e dc.b     $81,$82,$83,$84,$84,$85,$86,$87,$88,$89,$8a,$8a,$8b,$8c,$8d,$8e  ; ................
  00094:  8f 90 90 91 92 92 93 94 95 96 97 97 98 99 9a 9a dc.b     $8f,$90,$90,$91,$92,$92,$93,$94,$95,$96,$97,$97,$98,$99,$9a,$9a  ; ................
  000a4:  9b 9c 9d 9e 9e 9f a0 a1 a1 a2 a3 a3 a4 a5 a6 a7 dc.b     $9b,$9c,$9d,$9e,$9e,$9f,$a0,$a1,$a1,$a2,$a3,$a3,$a4,$a5,$a6,$a7  ; ................
  000b4:  a7 a8 a9 aa aa ab ac ad ad ae af af b0 b1 b2 b2 dc.b     $a7,$a8,$a9,$aa,$aa,$ab,$ac,$ad,$ad,$ae,$af,$af,$b0,$b1,$b2,$b2  ; ................
  000c4:  b3 b4 b4 b5 b6 b6 b7 b7 b8 b9 b9 ba bb bc bc bd dc.b     $b3,$b4,$b4,$b5,$b6,$b6,$b7,$b7,$b8,$b9,$b9,$ba,$bb,$bc,$bc,$bd  ; ................
  000d4:  be be bf c0 c0 c1 c2 c2 c3 c4 c5 c5 c6 c6 c7 c8 dc.b     $be,$be,$bf,$c0,$c0,$c1,$c2,$c2,$c3,$c4,$c5,$c5,$c6,$c6,$c7,$c8  ; ................
  000e4:  c8 c9 ca cb cc cd cd ce cf cf d0 d0 d1 d2 d2 d3 dc.b     $c8,$c9,$ca,$cb,$cc,$cd,$cd,$ce,$cf,$cf,$d0,$d0,$d1,$d2,$d2,$d3  ; ................
  000f4:  d3 d4 d5 d6 d6 d7 d7 d8 d9 d9 da da db dc dd dd dc.b     $d3,$d4,$d5,$d6,$d6,$d7,$d7,$d8,$d9,$d9,$da,$da,$db,$dc,$dd,$dd  ; ................
  00104:  de df df e0 e0 e1 e2 e3 e3 e4 e5 e5 e6 e6 e7 e7 dc.b     $de,$df,$df,$e0,$e0,$e1,$e2,$e3,$e3,$e4,$e5,$e5,$e6,$e6,$e7,$e7  ; ................
  00114:  e8 e8 e9 ea ea eb eb ec ed ed ee ef f0 f0 f1 f2 dc.b     $e8,$e8,$e9,$ea,$ea,$eb,$eb,$ec,$ed,$ed,$ee,$ef,$f0,$f0,$f1,$f2  ; ................
  00124:  f2 f3 f4 f4 f5 f5 f6 f7 f7 f8 f9 fa fa fb fc fc dc.b     $f2,$f3,$f4,$f4,$f5,$f5,$f6,$f7,$f7,$f8,$f9,$fa,$fa,$fb,$fc,$fc  ; ................
  00134:  fd fe fe ff 03 0c 00 00 00 1d 00 00 00 03 01 00 dc.b     $fd,$fe,$fe,$ff,$03,$0c,$00,$00,$00,$1d,$00,$00,$00,$03,$01,$00  ; ................
  00144:  00 08 00 03 06 09 0c 10 10 12 13 15 16 16 18 1b dc.b     $00,$08,$00,$03,$06,$09,$0c,$10,$10,$12,$13,$15,$16,$16,$18,$1b  ; ................
  00154:  1c 1e 1f 22 23 26 28 2b 2c 2f 32 34 37 3a 3c 3f dc.b     $1c,$1e,$1f,$22,$23,$26,$28,$2b,$2c,$2f,$32,$34,$37,$3a,$3c,$3f  ; ..."#&(+,/247:<?
  00164:  40 41 42 43 44 45 46 47 47 49 4a 4b 4c 4d 4e 4f dc.b     $40,$41,$42,$43,$44,$45,$46,$47,$47,$49,$4a,$4b,$4c,$4d,$4e,$4f  ; @ABCDEFGGIJKLMNO
  00174:  50 51 52 53 54 54 56 56 57 58 59 5a 5b 5c 5d 5e dc.b     $50,$51,$52,$53,$54,$54,$56,$56,$57,$58,$59,$5a,$5b,$5c,$5d,$5e  ; PQRSTTVVWXYZ[\]^
  00184:  5f 60 61 62 63 64 65 66 67 68 69 6a 6b 6c 6d 6e dc.b     $5f,$60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6a,$6b,$6c,$6d,$6e  ; _`abcdefghijklmn
  00194:  6f 70 71 72 72 73 74 75 76 77 78 79 7a 7a 7b 7c dc.b     $6f,$70,$71,$72,$72,$73,$74,$75,$76,$77,$78,$79,$7a,$7a,$7b,$7c  ; opqrrstuvwxyzz{|
  001a4:  7d 7e 7f 81 82 83 83 84 85 86 87 88 89 8a 8a 8b dc.b     $7d,$7e,$7f,$81,$82,$83,$83,$84,$85,$86,$87,$88,$89,$8a,$8a,$8b  ; }~..............
  001b4:  8c 8d 8e 8f 90 91 92 93 93 94 95 96 97 98 98 99 dc.b     $8c,$8d,$8e,$8f,$90,$91,$92,$93,$93,$94,$95,$96,$97,$98,$98,$99  ; ................
  001c4:  9a 9b 9c 9d 9e 9f a0 a1 a1 a2 a3 a4 a4 a5 a6 a7 dc.b     $9a,$9b,$9c,$9d,$9e,$9f,$a0,$a1,$a1,$a2,$a3,$a4,$a4,$a5,$a6,$a7  ; ................
  001d4:  a8 a8 a9 aa ab ac ad ad ae af b0 b1 b2 b2 b3 b4 dc.b     $a8,$a8,$a9,$aa,$ab,$ac,$ad,$ad,$ae,$af,$b0,$b1,$b2,$b2,$b3,$b4  ; ................
  001e4:  b5 b5 b6 b7 b8 b8 b9 ba bb bc bc bd be bf c0 c0 dc.b     $b5,$b5,$b6,$b7,$b8,$b8,$b9,$ba,$bb,$bc,$bc,$bd,$be,$bf,$c0,$c0  ; ................
  001f4:  c1 c2 c3 c3 c4 c5 c6 c6 c7 c8 c9 c9 ca cb cc cd dc.b     $c1,$c2,$c3,$c3,$c4,$c5,$c6,$c6,$c7,$c8,$c9,$c9,$ca,$cb,$cc,$cd  ; ................
  00204:  cd ce cf d0 d1 d1 d2 d3 d4 d4 d5 d6 d7 d7 d8 d9 dc.b     $cd,$ce,$cf,$d0,$d1,$d1,$d2,$d3,$d4,$d4,$d5,$d6,$d7,$d7,$d8,$d9  ; ................
  00214:  da da db dc dd de de df e0 e1 e1 e2 e3 e4 e4 e5 dc.b     $da,$da,$db,$dc,$dd,$de,$de,$df,$e0,$e1,$e1,$e2,$e3,$e4,$e4,$e5  ; ................
  00224:  e6 e7 e7 e8 e9 ea ea eb ec ed ee ee ef f0 f1 f1 dc.b     $e6,$e7,$e7,$e8,$e9,$ea,$ea,$eb,$ec,$ed,$ee,$ee,$ef,$f0,$f1,$f1  ; ................
  00234:  f2 f3 f4 f4 f5 f6 f7 f8 f8 f9 fa fb fb fc fd fe dc.b     $f2,$f3,$f4,$f4,$f5,$f6,$f7,$f8,$f8,$f9,$fa,$fb,$fb,$fc,$fd,$fe  ; ................
  00244:  ff ff 00 03 06 09 0c 10 10 18 20 20 22 23 24 25 dc.b     $ff,$ff,$00,$03,$06,$09,$0c,$10,$10,$18,$20,$20,$22,$23,$24,$25  ; ..........  "#$%
  00254:  27 28 29 2c 2d 2e 30 32 34 37 38 3a 3d 3f 40 41 dc.b     $27,$28,$29,$2c,$2d,$2e,$30,$32,$34,$37,$38,$3a,$3d,$3f,$40,$41  ; '(),-.02478:=?@A
  00264:  42 42 43 44 44 45 46 47 48 49 4a 4a 4b 4c 4d 4e dc.b     $42,$42,$43,$44,$44,$45,$46,$47,$48,$49,$4a,$4a,$4b,$4c,$4d,$4e  ; BBCDDEFGHIJJKLMN
  00274:  4f 50 51 52 53 54 55 56 57 58 59 5b 5c 5d 5e 5f dc.b     $4f,$50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5b,$5c,$5d,$5e,$5f  ; OPQRSTUVWXY[\]^_
  00284:  60 61 62 63 64 65 65 66 67 68 69 6a 6b 6c 6d 6e dc.b     $60,$61,$62,$63,$64,$65,$65,$66,$67,$68,$69,$6a,$6b,$6c,$6d,$6e  ; `abcdeefghijklmn
  00294:  6f 70 71 71 72 73 74 74 75 76 77 78 79 79 7a 7b dc.b     $6f,$70,$71,$71,$72,$73,$74,$74,$75,$76,$77,$78,$79,$79,$7a,$7b  ; opqqrsttuvwxyyz{
  002a4:  7c 7d 7e 7f 80 81 82 83 84 84 85 86 87 88 88 89 dc.b     $7c,$7d,$7e,$7f,$80,$81,$82,$83,$84,$84,$85,$86,$87,$88,$88,$89  ; |}~.............
  002b4:  8a 8b 8c 8d 8e 8e 8f 90 91 92 93 93 94 95 96 96 dc.b     $8a,$8b,$8c,$8d,$8e,$8e,$8f,$90,$91,$92,$93,$93,$94,$95,$96,$96  ; ................
  002c4:  97 98 99 9a 9a 9b 9c 9d 9e 9e 9f a0 a1 a2 a2 a3 dc.b     $97,$98,$99,$9a,$9a,$9b,$9c,$9d,$9e,$9e,$9f,$a0,$a1,$a2,$a2,$a3  ; ................
  002d4:  a4 a5 a5 a6 a7 a8 a8 a9 aa ab ab ac ad ae af af dc.b     $a4,$a5,$a5,$a6,$a7,$a8,$a8,$a9,$aa,$ab,$ab,$ac,$ad,$ae,$af,$af  ; ................
  002e4:  b0 b1 b2 b2 b3 b4 b5 b5 b6 b7 b7 b8 b9 ba ba bb dc.b     $b0,$b1,$b2,$b2,$b3,$b4,$b5,$b5,$b6,$b7,$b7,$b8,$b9,$ba,$ba,$bb  ; ................
  002f4:  bc bd bd be bf c0 c1 c1 c2 c3 c3 c4 c5 c6 c6 c7 dc.b     $bc,$bd,$bd,$be,$bf,$c0,$c1,$c1,$c2,$c3,$c3,$c4,$c5,$c6,$c6,$c7  ; ................
  00304:  c8 c9 c9 ca cb cc cc cd ce cf cf d0 d1 d2 d2 d3 dc.b     $c8,$c9,$c9,$ca,$cb,$cc,$cc,$cd,$ce,$cf,$cf,$d0,$d1,$d2,$d2,$d3  ; ................
  00314:  d4 d4 d5 d6 d6 d7 d8 d9 d9 da db dc dc dd de de dc.b     $d4,$d4,$d5,$d6,$d6,$d7,$d8,$d9,$d9,$da,$db,$dc,$dc,$dd,$de,$de  ; ................
  00324:  df e0 e1 e1 e2 e3 e4 e4 e5 e6 e6 e7 e8 e9 e9 ea dc.b     $df,$e0,$e1,$e1,$e2,$e3,$e4,$e4,$e5,$e6,$e6,$e7,$e8,$e9,$e9,$ea  ; ................
  00334:  eb ec ec ed ee ef ef f0 f1 f2 f2 f3 f4 f4 f5 f6 dc.b     $eb,$ec,$ec,$ed,$ee,$ef,$ef,$f0,$f1,$f2,$f2,$f3,$f4,$f4,$f5,$f6  ; ................
  00344:  f7 f7 00 02 05 08 0a 0d 10 10 10 20 20 22 23 23 dc.b     $f7,$f7,$00,$02,$05,$08,$0a,$0d,$10,$10,$10,$20,$20,$22,$23,$23  ; ...........  "##
  00354:  24 25 25 27 28 29 2a 2c 2d 2e 2f 30 32 33 34 36 dc.b     $24,$25,$25,$27,$28,$29,$2a,$2c,$2d,$2e,$2f,$30,$32,$33,$34,$36  ; $%%'()*,-./02346
  00364:  37 38 3a 3c 3d 3f 40 41 41 42 42 43 44 44 45 45 dc.b     $37,$38,$3a,$3c,$3d,$3f,$40,$41,$41,$42,$42,$43,$44,$44,$45,$45  ; 78:<=?@AABBCDDEE
  00374:  46 47 47 48 49 4a 4a 4b 4c 4d 4d 4e 4f 4f 51 51 dc.b     $46,$47,$47,$48,$49,$4a,$4a,$4b,$4c,$4d,$4d,$4e,$4f,$4f,$51,$51  ; FGGHIJJKLMMNOOQQ
  00384:  52 53 54 55 56 56 57 58 59 5a 5b 5c 5d 5e 5f 60 dc.b     $52,$53,$54,$55,$56,$56,$57,$58,$59,$5a,$5b,$5c,$5d,$5e,$5f,$60  ; RSTUVVWXYZ[\]^_`
  00394:  60 61 62 62 63 64 64 65 66 66 67 68 69 69 6a 6b dc.b     $60,$61,$62,$62,$63,$64,$64,$65,$66,$66,$67,$68,$69,$69,$6a,$6b  ; `abbcddeffghiijk
  003a4:  6c 6c 6d 6e 6f 6f 70 71 72 72 73 74 74 75 76 77 dc.b     $6c,$6c,$6d,$6e,$6f,$6f,$70,$71,$72,$72,$73,$74,$74,$75,$76,$77  ; llmnoopqrrsttuvw
  003b4:  77 78 79 79 7a 7b 7c 7c 7d 7e 7f 80 81 82 82 83 dc.b     $77,$78,$79,$79,$7a,$7b,$7c,$7c,$7d,$7e,$7f,$80,$81,$82,$82,$83  ; wxyyz{||}~......
  003c4:  84 84 85 86 86 87 88 88 89 8a 8a 8b 8c 8d 8d 8e dc.b     $84,$84,$85,$86,$86,$87,$88,$88,$89,$8a,$8a,$8b,$8c,$8d,$8d,$8e  ; ................
  003d4:  8f 90 90 91 91 92 93 93 94 95 95 96 97 97 98 99 dc.b     $8f,$90,$90,$91,$91,$92,$93,$93,$94,$95,$95,$96,$97,$97,$98,$99  ; ................
  003e4:  99 9a 9b 9b 9c 9d 9d 9e 9f a0 a0 a1 a1 a2 a3 a3 dc.b     $99,$9a,$9b,$9b,$9c,$9d,$9d,$9e,$9f,$a0,$a0,$a1,$a1,$a2,$a3,$a3  ; ................
  003f4:  a4 a4 a5 a6 a6 a7 a7 a8 a9 a9 aa ab ab ac ad ad dc.b     $a4,$a4,$a5,$a6,$a6,$a7,$a7,$a8,$a9,$a9,$aa,$ab,$ab,$ac,$ad,$ad  ; ................
  00404:  ae af af b0 b0 b1 b2 b2 b3 b3 b4 b5 b5 b6 b6 b7 dc.b     $ae,$af,$af,$b0,$b0,$b1,$b2,$b2,$b3,$b3,$b4,$b5,$b5,$b6,$b6,$b7  ; ................
  00414:  b8 b8 b9 ba ba bb bb bc bd bd be bf bf c0 c0 c1 dc.b     $b8,$b8,$b9,$ba,$ba,$bb,$bb,$bc,$bd,$bd,$be,$bf,$bf,$c0,$c0,$c1  ; ................
  00424:  c2 c2 c3 c3 c4 c5 c5 c6 c6 c7 c8 c8 c9 c9 ca cb dc.b     $c2,$c2,$c3,$c3,$c4,$c5,$c5,$c6,$c6,$c7,$c8,$c8,$c9,$c9,$ca,$cb  ; ................
  00434:  cb cc cc cd ce ce cf d0 d0 d1 d1 d2 d3 d3 d4 d4 dc.b     $cb,$cc,$cc,$cd,$ce,$ce,$cf,$d0,$d0,$d1,$d1,$d2,$d3,$d3,$d4,$d4  ; ................
  00444:  d5 d6                dc.b     $d5,$d6  ; ..
* ==================================================================
* FindGCSlot
* ==================================================================
* Bails out immediately (no-op) unless three low-memory environment
* checks all pass: $28E.w == $3FFF (a full-featured-Memory-Manager /
* 32-bit-clean flag combination -- the same $28E flag byte the ROM's
* Strip24 helper tests bit 6 of), the current OS/ROM version word at
* $15A.w >= $0700 (System/ROM version >= 7.0), and the GDevice list
* head ($8A8.w, the classic low-mem 'DeviceList' global) is non-NULL
* with at least one device.  I.e. this only runs under Color
* QuickDraw with a real GDevice list -- System 7 or a comparably
* Color-QuickDraw-capable System 6 configuration.
*
* Then walks every NuBus slot 0..14 via a stack-allocated SpBlock
* (same structure/roles as DRVR.s and ../extracted-source's
* PrimaryInit/SecondaryInit -- $31 spSlot, $28 spCategory=3 (catDisplay),
* $2A spCType=1 (typVideo), $2C spDrvrSW=1 (Apple), $2E spDrvrHW=$1D),
* i.e. it is searching for **every 8*24 GC-family video card** in the
* machine (spDrvrHW=$1D is the exact same hardware-device id used
* throughout this project's declaration ROM and DRVR).
*
* For each matching slot: chases the Unit Table ($11C.w, 'UTableBase')
* by the sResource's slot RefNum to its DCE, checks a name-comparison
* table (a fixed literal Pascal-ish string, PC-relative, in the data
* block above -- almost certainly the driver name, so this is really
* 'find slots whose driver is exactly this one'), skips any card whose
* GDevice/driver flags mark it monochrome (bit 12 of dCtlStorage's
* flags word -- this is the exact GFlags.MonoFlag bit position
* documented in ../extracted-source/VideoDriver.s, i.e. it's
* reading the ROM/DRVR video driver's own private-storage flag word
* to see whether THAT slot's monitor is black-and-white).
*
* For each surviving (colour, matching-driver) slot: loads a 'scrn'
* (id 0) resource -- a per-slot screen/monitor-calibration table
* used by several Apple monitor-configuration tools of this era --
* and looks up the entry for this slot number.  If found (and not the
* sentinel value $FFFF), it's consumed (_ReleaseResource either way).
* It then issues what looks like two _GDevice-family calls through an
* unidentified OS trap ($A204, not in Apple's published Traps.h) --
* once with a small built record (selector 3) and once with a colour-
* table handle pulled out of the matching GDevice (selector 4) -- most
* plausibly registering/refreshing that slot's device with the
* Device/Palette Manager machinery, but the exact trap's identity
* isn't established here.
*
* This lines up precisely with the develop-magazine description of
* the 8*24 GC's multi-card behaviour ("you can have as many 8*24 GC
* boards as you want... only one will function as a graphics
* accelerator; any other becomes a glorified display card") -- this
* routine is very plausibly the code that walks every installed GC
* card and registers/reconciles the ones that are NOT the primary
* accelerator as ordinary Color QuickDraw display devices.
FindGCSlot:
  00446:  0c 78 3f ff 02 8e    cmpi.w   #$3fff, $28e.w
  0044c:  66 1a                bne.b    $468
  0044e:  0c 78 07 00 01 5a    cmpi.w   #$700, $15a.w
  00454:  6d 12                blt.b    $468
  00456:  4a b8 08 a8          tst.l    $8a8.w
  0045a:  67 0c                beq.b    $468
  0045c:  20 78 08 a8          movea.l  $8a8.w, a0
  00460:  20 50                movea.l  (a0), a0
  00462:  30 10                move.w   (a0), d0
  00464:  67 02                beq.b    $468
  00466:  60 02                bra.b    $46a
  00468:  4e 75                rts      
  0046a:  4e 56 00 00          link.w   a6, #$0
  0046e:  48 e7 1e 38          movem.l  d3-d6/a2-a4, -(a7)
  00472:  9e fc 00 32          suba.w   #$32, a7
  00476:  28 4f                movea.l  a7, a4
  00478:  9e fc 00 38          suba.w   #$38, a7
  0047c:  26 4f                movea.l  a7, a3
  0047e:  9e fc 00 0c          suba.w   #$c, a7
  00482:  24 4f                movea.l  a7, a2
  00484:  76 00                moveq    #$0, d3
  00486:  60 0a                bra.b    $492
  00488:  52 43                addq.w   #$1, d3
  0048a:  0c 03 00 0f          cmpi.b   #$f, d3
  0048e:  6c 00 01 74          bge.w    $604  ; -> FindGCSlot_exit
  00492:  20 4b                movea.l  a3, a0
  00494:  11 43 00 31          move.b   d3, $31(a0)
  00498:  42 28 00 32          clr.b    $32(a0)
  0049c:  42 28 00 33          clr.b    $33(a0)
  004a0:  42 28 00 30          clr.b    $30(a0)
  004a4:  31 7c 00 03 00 28    move.w   #$3, $28(a0)
  004aa:  31 7c 00 01 00 2a    move.w   #$1, $2a(a0)
  004b0:  31 7c 00 01 00 2c    move.w   #$1, $2c(a0)
  004b6:  31 7c 00 1d 00 2e    move.w   #$1d, $2e(a0)
  004bc:  42 a8 00 18          clr.l    $18(a0)
  004c0:  70 0c                moveq    #$c, d0
  004c2:  a0 6e                dc.w     $a06e  ; _SlotManager
  004c4:  67 04                beq.b    $4ca
  004c6:  60 00 01 3c          bra.w    $604  ; -> FindGCSlot_exit
  004ca:  16 28 00 31          move.b   $31(a0), d3
  004ce:  7a 00                moveq    #$0, d5
  004d0:  3a 28 00 26          move.w   $26(a0), d5
  004d4:  67 b2                beq.b    $488
  004d6:  3c 05                move.w   d5, d6
  004d8:  46 45                not.w    d5
  004da:  e5 4d                lsl.w    #$2, d5
  004dc:  da b8 01 1c          add.l    $11c.w, d5
  004e0:  20 45                movea.l  d5, a0
  004e2:  20 50                movea.l  (a0), a0
  004e4:  20 50                movea.l  (a0), a0
  004e6:  2a 08                move.l   a0, d5
  004e8:  20 50                movea.l  (a0), a0
  004ea:  20 50                movea.l  (a0), a0
  004ec:  70 00                moveq    #$0, d0
  004ee:  41 e8 00 12          lea.l    $12(a0), a0
  004f2:  28 08                move.l   a0, d4
  004f4:  10 18                move.b   (a0)+, d0
  004f6:  48 40                swap     d0
  004f8:  43 fa fb 14          lea.l    $e(pc), a1
  004fc:  10 19                move.b   (a1)+, d0
  004fe:  a0 3c                dc.w     $a03c  ; _CmpString
  00500:  4a 40                tst.w    d0
  00502:  66 84                bne.b    $488
  00504:  20 44                movea.l  d4, a0
  00506:  10 10                move.b   (a0), d0
  00508:  54 40                addq.w   #$2, d0
  0050a:  08 80 00 00          bclr.b   #$0, d0
  0050e:  30 30 00 00          move.w   (a0, d0.w), d0
  00512:  66 00 ff 74          bne.w    $488
  00516:  20 45                movea.l  d5, a0
  00518:  18 28 00 29          move.b   $29(a0), d4
  0051c:  02 04 00 07          andi.b   #$7, d4
  00520:  0c 04 00 03          cmpi.b   #$3, d4
  00524:  66 00 ff 62          bne.w    $488
  00528:  20 68 00 14          movea.l  $14(a0), a0
  0052c:  20 50                movea.l  (a0), a0
  0052e:  08 28 00 0c 00 1c    btst.b   #$c, $1c(a0)
  00534:  66 00 ff 52          bne.w    $488
  00538:  20 68 00 18          movea.l  $18(a0), a0
  0053c:  43 fa fa ec          lea.l    $2a(pc), a1
  00540:  30 19                move.w   (a1)+, d0
  00542:  e2 48                lsr.w    #$1, d0
  00544:  53 40                subq.w   #$1, d0
  00546:  b3 48                cmpm.w   (a0)+, (a1)+
  00548:  66 00 ff 3e          bne.w    $488
  0054c:  51 c8 ff f8          dbra     d0, $546
  00550:  42 a7                clr.l    -(a7)
  00552:  2f 3c 73 63 72 6e    move.l   #$7363726e, -(a7)
  00558:  42 67                clr.w    -(a7)
  0055a:  a9 a0                dc.w     $a9a0  ; _GetResource
  0055c:  20 1f                move.l   (a7)+, d0
  0055e:  67 2e                beq.b    $58e
  00560:  2f 00                move.l   d0, -(a7)
  00562:  20 40                movea.l  d0, a0
  00564:  a0 4a                dc.w     $a04a  ; _HNoPurge
  00566:  a0 29                dc.w     $a029  ; _HLock
  00568:  20 50                movea.l  (a0), a0
  0056a:  30 18                move.w   (a0)+, d0
  0056c:  53 40                subq.w   #$1, d0
  0056e:  b6 68 00 02          cmp.w    $2(a0), d3
  00572:  67 0a                beq.b    $57e
  00574:  41 e8 00 1c          lea.l    $1c(a0), a0
  00578:  51 c8 ff f4          dbra     d0, $56e
  0057c:  60 0e                bra.b    $58c
  0057e:  0c 68 ff ff 00 10    cmpi.w   #$ffff, $10(a0)
  00584:  67 06                beq.b    $58c
  00586:  a9 a3                dc.w     $a9a3  ; _ReleaseResource
  00588:  60 00 fe fe          bra.w    $488
  0058c:  a9 a3                dc.w     $a9a3  ; _ReleaseResource
  0058e:  43 fa fb a8          lea.l    $138(pc), a1
  00592:  4a 59                tst.w    (a1)+
  00594:  24 89                move.l   a1, (a2)
  00596:  20 4c                movea.l  a4, a0
  00598:  31 46 00 18          move.w   d6, $18(a0)
  0059c:  31 7c 00 04 00 1a    move.w   #$4, $1a(a0)
  005a2:  21 4a 00 1c          move.l   a2, $1c(a0)
  005a6:  a2 04                dc.w     $a204  ; A-trap 0xa204 (unidentified)
  005a8:  20 78 08 a8          movea.l  $8a8.w, a0
  005ac:  20 50                movea.l  (a0), a0
  005ae:  bc 50                cmp.w    (a0), d6
  005b0:  67 0e                beq.b    $5c0
  005b2:  20 28 00 1e          move.l   $1e(a0), d0
  005b6:  67 00 fe d0          beq.w    $488
  005ba:  20 40                movea.l  d0, a0
  005bc:  20 50                movea.l  (a0), a0
  005be:  60 ee                bra.b    $5ae
  005c0:  0c 68 00 02 00 04    cmpi.w   #$2, $4(a0)
  005c6:  67 00 fe c0          beq.w    $488
  005ca:  20 68 00 16          movea.l  $16(a0), a0
  005ce:  20 50                movea.l  (a0), a0
  005d0:  20 68 00 2a          movea.l  $2a(a0), a0
  005d4:  a0 29                dc.w     $a029  ; _HLock
  005d6:  2f 08                move.l   a0, -(a7)
  005d8:  22 50                movea.l  (a0), a1
  005da:  42 6a 00 04          clr.w    $4(a2)
  005de:  35 69 00 06 00 06    move.w   $6(a1), $6(a2)
  005e4:  43 e9 00 08          lea.l    $8(a1), a1
  005e8:  24 89                move.l   a1, (a2)
  005ea:  20 4c                movea.l  a4, a0
  005ec:  31 46 00 18          move.w   d6, $18(a0)
  005f0:  31 7c 00 03 00 1a    move.w   #$3, $1a(a0)
  005f6:  21 4a 00 1c          move.l   a2, $1c(a0)
  005fa:  a2 04                dc.w     $a204  ; A-trap 0xa204 (unidentified)
  005fc:  20 5f                movea.l  (a7)+, a0
  005fe:  a0 2a                dc.w     $a02a  ; _HUnlock
  00600:  60 00 fe 86          bra.w    $488
* Common exit: restore saved regs, unlk, rts.
FindGCSlot_exit:
  00604:  4f ef 00 76          lea.l    $76(a7), a7
  00608:  4c df 1c 78          movem.l  (a7)+, d3-d6/a2-a4
  0060c:  4e 5e                unlk     a6
  0060e:  4e 75                rts      
