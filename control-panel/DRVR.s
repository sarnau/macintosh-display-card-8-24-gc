* ==================================================================
*  .GraphAccel  -  low-level driver for the 8*24 GC accelerator
*  (resource 'DRVR' id -4048, 18470 bytes, from 824GC.rsrc)
* ==================================================================
*  This is a SEPARATE driver from the ROM's '.Display_Video_Apple_MDCGC'
*  (see ../extracted-source/VideoDriver.s) -- it does not draw pixels; it
*  is the low-level counterpart of the 'gc24' QuickDraw accelerator engine
*  (../control-panel/gc24.s): it owns a private globals struct, installs
*  the QuickDraw-bottleneck trap patches, exposes ~18 custom Status
*  selectors that return fields of that struct, and can itself drive the
*  ACEF (Am29000 COFF) loader to download firmware to the card.
*
*  Calling convention confirmed from the code: standard classic Device
*  Manager driver ABI.  On entry to each handler (via CommonDispatch):
*    A0 = DCE (Device Control Entry) -- dCtlStorage at DCE+$14 is a
*         Handle to this driver's private globals struct ($BAA = 2986
*         bytes, allocated+locked by DoOpen).
*    A1 = ParamBlock (CntrlParam/IOParam) -- csCode at +$1A, csParam at
*         +$1C, matching the classic Mac struct offsets exactly.
*  Trap names from Apple CIncludes/Traps.h; labels/comments analytical.
*  Disassembled by recursive descent + linear sweep + compiler
*  switch-table recovery (same toolchain as ../control-panel/gc24.s).
*
DRVR_Header:
  00000:  4c 00 00 00 00 00 00 00     dc.w     $4C00,$0000,$0000,$0000  ; drvrFlags,drvrDelay,drvrEMask,drvrMenu
  00008:  00 32 00 36 00 3a 00 3e 00 42   dc.w     $0032,$0036,$003A,$003E,$0042  ; Open,Prime,Ctl,Status,Close offsets
  00012:  0b 2e 47 72 61 70 68 41 63 63 65 6c   dc.b     11, '.GraphAccel'   ; drvrName (Pascal string)
Open_vec:
  00032:  60 00 00 12          bra.w    $46
Prime_vec:
  00036:  60 00 00 14          bra.w    $4c
Control_vec:
  0003a:  60 00 00 16          bra.w    $52
Status_vec:
  0003e:  60 00 00 18          bra.w    $58
Close_vec:
  00042:  60 00 00 1a          bra.w    $5e
  00046:  48 7a 00 40          pea.l    $88(pc)  ; -> DoOpen
  0004a:  60 16                bra.b    $62  ; -> CommonDispatch
  0004c:  48 7a 02 96          pea.l    $2e4(pc)  ; -> DoPrime
  00050:  60 10                bra.b    $62  ; -> CommonDispatch
  00052:  48 7a 06 bc          pea.l    $710(pc)  ; -> DoControl
  00056:  60 0a                bra.b    $62  ; -> CommonDispatch
  00058:  48 7a 02 98          pea.l    $2f2(pc)  ; -> DoStatus
  0005c:  60 04                bra.b    $62  ; -> CommonDispatch
  0005e:  48 7a 0f 78          pea.l    $fd8(pc)  ; -> DoClose
* ==================================================================
* CommonDispatch  -  shared trap-vector dispatcher
* ==================================================================
* Every Open/Prime/Control/Status/Close vector is a 'pea handler ; bra
* CommonDispatch' stub.  CommonDispatch saves A0/A1, re-pushes them as
* the two call args (A0=DCE=$8(A6), A1=ParamBlock=$c(A6) inside the
* callee), jsr's through the handler address left on the stack by the
* pea, then on return checks dCtlFlags bit 1 ($6(a0)) and if clear jumps
* through the standard JIODone vector [$8FC.w]; otherwise just rts's
* (the caller -- Device Manager -- will complete the I/O itself).
CommonDispatch:
  00062:  48 e7 00 c0          movem.l  a0-a1, -(a7)
  00066:  42 67                clr.w    -(a7)
  00068:  2f 08                move.l   a0, -(a7)
  0006a:  2f 09                move.l   a1, -(a7)
  0006c:  20 6f 00 12          movea.l  $12(a7), a0
  00070:  4e 90                jsr      (a0)
  00072:  30 1f                move.w   (a7)+, d0
  00074:  4c df 03 00          movem.l  (a7)+, a0-a1
  00078:  58 4f                addq.w   #$4, a7
  0007a:  08 28 00 01 00 06    btst.b   #$1, $6(a0)
  00080:  66 04                bne.b    $86
  00082:  2f 38 08 fc          move.l   $8fc.w, -(a7)
  00086:  4e 75                rts      
* ==================================================================
* DoOpen
* ==================================================================
* A3 = DCE.  If DCE.dCtlStorage ($14) is already set, this unit is
* already open -- skip init.  Otherwise: probes the environment via a
* helper (checks Gestalt/CPU/etc, returns an error code in D0 on
* failure), switches to the System heap, allocates a $BAA (2986-byte)
* relocatable block for the driver's private 'engine globals' struct,
* stores its Handle in DCE.dCtlStorage, HNoPurge+HLock's it, and
* initialises it: builds a slot/queue value from dCtlRefNum ($18(a3))
* into globals+$00, zeroes an 8-slot callback-vector table at
* globals+$A78 (slots seen used: +$A7C, +$A80, +$A84 -- see
* Sts_GetField_a7c / Sts_InvokeHook3 below), and sets globals+$AA6 =
* $FFFF (a 'nothing selected' sentinel -- gc24.s's engine globals use
* this SAME field offset, StoreCtxWord_AA6: strong evidence the two
* share a struct layout/convention).
* Finishes by calling InstallPatches to hook the QuickDraw bottlenecks.
DoOpen:
  00088:  4e 56 ff fc          link.w   a6, #$fffc
  0008c:  48 e7 1f 18          movem.l  d3-d7/a3-a4, -(a7)
  00090:  26 6e 00 08          movea.l  $8(a6), a3
  00094:  42 04                clr.b    d4
  00096:  42 05                clr.b    d5
  00098:  4a ab 00 14          tst.l    $14(a3)
  0009c:  66 00 02 36          bne.w    $2d4
  000a0:  61 ff 00 00 18 ac    bsr.l    $194e
  000a6:  2e 00                move.l   d0, d7
  000a8:  6c 08                bge.b    $b2
  000aa:  3d 47 00 10          move.w   d7, $10(a6)
  000ae:  60 00 02 28          bra.w    $2d8
  000b2:  a1 1a                dc.w     $a11a  ; _GetZone
  000b4:  2d 48 ff fc          move.l   a0, -$4(a6)
  000b8:  20 78 02 a6          movea.l  $2a6.w, a0
  000bc:  a0 1b                dc.w     $a01b  ; _SetZone
  000be:  20 3c 00 00 0b aa    move.l   #$baa, d0
  000c4:  a0 40                dc.w     $a040  ; _ResrvMem
  000c6:  20 3c 00 00 0b aa    move.l   #$baa, d0
  000cc:  a1 22                dc.w     $a122  ; _NewHandle
  000ce:  27 48 00 14          move.l   a0, $14(a3)
  000d2:  20 08                move.l   a0, d0
  000d4:  66 10                bne.b    $e6
  000d6:  20 6e ff fc          movea.l  -$4(a6), a0
  000da:  a0 1b                dc.w     $a01b  ; _SetZone
  000dc:  3d 7c ff e9 00 10    move.w   #$ffe9, $10(a6)
  000e2:  60 00 01 f4          bra.w    $2d8
  000e6:  20 6b 00 14          movea.l  $14(a3), a0
  000ea:  a0 4a                dc.w     $a04a  ; _HNoPurge
  000ec:  20 6b 00 14          movea.l  $14(a3), a0
  000f0:  a0 29                dc.w     $a029  ; _HLock
  000f2:  20 6b 00 14          movea.l  $14(a3), a0
  000f6:  28 50                movea.l  (a0), a4
  000f8:  70 00                moveq    #$0, d0
  000fa:  29 40 0a a0          move.l   d0, $aa0(a4)
  000fe:  32 2b 00 18          move.w   $18(a3), d1
  00102:  48 c1                ext.l    d1
  00104:  44 81                neg.l    d1
  00106:  53 41                subq.w   #$1, d1
  00108:  48 c1                ext.l    d1
  0010a:  eb 89                lsl.l    #$5, d1
  0010c:  82 bc 00 00 c0 00    or.l     #$c000, d1
  00112:  28 81                move.l   d1, (a4)
  00114:  7e 00                moveq    #$0, d7
  00116:  76 08                moveq    #$8, d3
  00118:  41 ec 0a 78          lea.l    $a78(a4), a0
  0011c:  70 00                moveq    #$0, d0
  0011e:  21 80 7c 00          move.l   d0, (a0, d7.l * 4)
  00122:  20 07                move.l   d7, d0
  00124:  52 87                addq.l   #$1, d7
  00126:  b6 87                cmp.l    d7, d3
  00128:  6e ee                bgt.b    $118
  0012a:  39 7c ff ff 0a a6    move.w   #$ffff, $aa6(a4)
  00130:  70 00                moveq    #$0, d0
  00132:  29 40 02 70          move.l   d0, $270(a4)
  00136:  29 40 02 6c          move.l   d0, $26c(a4)
  0013a:  29 7c 00 00 10 00 02 68 move.l   #$1000, $268(a4)
  00142:  72 ff                moveq    #$ff, d1
  00144:  b2 6c 0a a6          cmp.w    $aa6(a4), d1
  00148:  67 12                beq.b    $15c
  0014a:  55 8f                subq.l   #$2, a7
  0014c:  3f 2c 0a a6          move.w   $aa6(a4), -(a7)
  00150:  48 6c 0a a8          pea.l    $aa8(a4)
  00154:  61 ff 00 00 44 44    bsr.l    $459a
  0015a:  54 4f                addq.w   #$2, a7
  0015c:  48 78 00 a8          pea.l    $a8.w
  00160:  2f 0c                move.l   a4, -(a7)
  00162:  61 ff 00 00 13 98    bsr.l    $14fc
  00168:  4a 80                tst.l    d0
  0016a:  50 4f                addq.w   #$8, a7
  0016c:  67 1c                beq.b    $18a
  0016e:  20 6b 00 14          movea.l  $14(a3), a0
  00172:  a0 23                dc.w     $a023  ; _DisposHandle
  00174:  70 00                moveq    #$0, d0
  00176:  27 40 00 14          move.l   d0, $14(a3)
  0017a:  20 6e ff fc          movea.l  -$4(a6), a0
  0017e:  a0 1b                dc.w     $a01b  ; _SetZone
  00180:  3d 7c ff e9 00 10    move.w   #$ffe9, $10(a6)
  00186:  60 00 01 50          bra.w    $2d8
  0018a:  39 7c 53 42 0a a4    move.w   #$5342, $aa4(a4)
  00190:  42 6c 02 2e          clr.w    $22e(a4)
  00194:  42 6c 00 10          clr.w    $10(a4)
  00198:  20 2c 02 34          move.l   $234(a4), d0
  0019c:  72 60                moveq    #$60, d1
  0019e:  d0 81                add.l    d1, d0
  001a0:  29 40 0a 9c          move.l   d0, $a9c(a4)
  001a4:  29 7c 00 00 00 d3 02 50 move.l   #$d3, $250(a4)
  001ac:  70 ff                moveq    #$ff, d0
  001ae:  29 40 02 4c          move.l   d0, $24c(a4)
  001b2:  42 2c 02 56          clr.b    $256(a4)
  001b6:  72 00                moveq    #$0, d1
  001b8:  29 41 02 48          move.l   d1, $248(a4)
  001bc:  29 41 02 40          move.l   d1, $240(a4)
  001c0:  29 41 02 44          move.l   d1, $244(a4)
  001c4:  29 41 02 74          move.l   d1, $274(a4)
  001c8:  7e 00                moveq    #$0, d7
  001ca:  76 06                moveq    #$6, d3
  001cc:  41 ec 02 14          lea.l    $214(a4), a0
  001d0:  70 00                moveq    #$0, d0
  001d2:  21 80 7c 00          move.l   d0, (a0, d7.l * 4)
  001d6:  20 07                move.l   d7, d0
  001d8:  52 87                addq.l   #$1, d7
  001da:  b6 87                cmp.l    d7, d3
  001dc:  6e ee                bgt.b    $1cc
  001de:  7c 09                moveq    #$9, d6
  001e0:  7e 00                moveq    #$0, d7
  001e2:  60 00 00 8a          bra.w    $26e
  001e6:  2f 0c                move.l   a4, -(a7)
  001e8:  2f 06                move.l   d6, -(a7)
  001ea:  61 ff 00 00 1c 5e    bsr.l    $1e4a
  001f0:  41 ec 02 14          lea.l    $214(a4), a0
  001f4:  21 80 7c 00          move.l   d0, (a0, d7.l * 4)
  001f8:  50 4f                addq.w   #$8, a7
  001fa:  67 6a                beq.b    $266
  001fc:  43 ec 02 14          lea.l    $214(a4), a1
  00200:  20 71 7c 00          movea.l  (a1, d7.l * 4), a0
  00204:  20 50                movea.l  (a0), a0
  00206:  7c 00                moveq    #$0, d6
  00208:  3c 10                move.w   (a0), d6
  0020a:  4a 86                tst.l    d6
  0020c:  43 ec 02 14          lea.l    $214(a4), a1
  00210:  20 71 7c 00          movea.l  (a1, d7.l * 4), a0
  00214:  20 50                movea.l  (a0), a0
  00216:  70 00                moveq    #$0, d0
  00218:  30 28 01 62          move.w   $162(a0), d0
  0021c:  72 7d                moveq    #$7d, d1
  0021e:  b2 80                cmp.l    d0, d1
  00220:  66 0e                bne.b    $230
  00222:  78 01                moveq    #$1, d4
  00224:  43 ec 02 14          lea.l    $214(a4), a1
  00228:  20 71 7c 00          movea.l  (a1, d7.l * 4), a0
  0022c:  a0 23                dc.w     $a023  ; _DisposHandle
  0022e:  60 36                bra.b    $266
  00230:  43 ec 02 14          lea.l    $214(a4), a1
  00234:  20 71 7c 00          movea.l  (a1, d7.l * 4), a0
  00238:  20 50                movea.l  (a0), a0
  0023a:  70 ff                moveq    #$ff, d0
  0023c:  b0 68 01 5e          cmp.w    $15e(a0), d0
  00240:  66 0e                bne.b    $250
  00242:  7a 01                moveq    #$1, d5
  00244:  43 ec 02 14          lea.l    $214(a4), a1
  00248:  20 71 7c 00          movea.l  (a1, d7.l * 4), a0
  0024c:  a0 23                dc.w     $a023  ; _DisposHandle
  0024e:  60 16                bra.b    $266
  00250:  43 ec 02 14          lea.l    $214(a4), a1
  00254:  20 71 7c 00          movea.l  (a1, d7.l * 4), a0
  00258:  20 50                movea.l  (a0), a0
  0025a:  31 47 01 60          move.w   d7, $160(a0)
  0025e:  52 6c 00 10          addq.w   #$1, $10(a4)
  00262:  52 6c 02 2e          addq.w   #$1, $22e(a4)
  00266:  20 07                move.l   d7, d0
  00268:  52 87                addq.l   #$1, d7
  0026a:  20 06                move.l   d6, d0
  0026c:  52 86                addq.l   #$1, d6
  0026e:  70 06                moveq    #$6, d0
  00270:  b0 87                cmp.l    d7, d0
  00272:  6f 08                ble.b    $27c
  00274:  70 0e                moveq    #$e, d0
  00276:  b0 86                cmp.l    d6, d0
  00278:  6c 00 ff 6c          bge.w    $1e6
  0027c:  4a 6c 00 10          tst.w    $10(a4)
  00280:  66 30                bne.b    $2b2
  00282:  20 6b 00 14          movea.l  $14(a3), a0
  00286:  a0 23                dc.w     $a023  ; _DisposHandle
  00288:  2f 0c                move.l   a4, -(a7)
  0028a:  61 ff 00 00 15 ea    bsr.l    $1876
  00290:  20 6e ff fc          movea.l  -$4(a6), a0
  00294:  a0 1b                dc.w     $a01b  ; _SetZone
  00296:  70 00                moveq    #$0, d0
  00298:  27 40 00 14          move.l   d0, $14(a3)
  0029c:  4a 05                tst.b    d5
  0029e:  58 4f                addq.w   #$4, a7
  002a0:  67 08                beq.b    $2aa
  002a2:  3d 7c d8 ed 00 10    move.w   #$d8ed, $10(a6)
  002a8:  60 2e                bra.b    $2d8
  002aa:  3d 7c d8 eb 00 10    move.w   #$d8eb, $10(a6)
  002b0:  60 26                bra.b    $2d8
  002b2:  2f 2b 00 14          move.l   $14(a3), -(a7)
  002b6:  61 ff 00 00 0d 2e    bsr.l    $fe6  ; -> InstallPatches
  002bc:  61 ff 00 00 16 14    bsr.l    $18d2
  002c2:  42 2c 0a aa          clr.b    $aaa(a4)
  002c6:  70 00                moveq    #$0, d0
  002c8:  29 40 00 04          move.l   d0, $4(a4)
  002cc:  20 6e ff fc          movea.l  -$4(a6), a0
  002d0:  a0 1b                dc.w     $a01b  ; _SetZone
  002d2:  58 4f                addq.w   #$4, a7
  002d4:  42 6e 00 10          clr.w    $10(a6)
  002d8:  4c ee 18 f8 ff e0    movem.l  -$20(a6), d3-d7/a3-a4
  002de:  4e 5e                unlk     a6
  002e0:  4e 74 00 08          rtd      #$8
* ==================================================================
* DoPrime
* ==================================================================
* Stub: falls straight through into DoStatus.
DoPrime:
  002e4:  4e 56 00 00          link.w   a6, #$0
  002e8:  42 6e 00 10          clr.w    $10(a6)
  002ec:  4e 5e                unlk     a6
  002ee:  4e 74 00 08          rtd      #$8
* ==================================================================
* DoStatus
* ==================================================================
* A0=DCE ($8(a6)), A1/ParamBlock ($c(a6)), A3 = &ParamBlock.csParam
* ($1c(a0)).  Bails statusErr if DCE.dCtlStorage is unset.  Reads the
* engine globals pointer (dCtlStorage Handle -> deref -> A4), does a
* bounds/liveness check against globals fields, then dispatches on
* csCode ($1A of the ParamBlock, range 2..54) via StatusJumpTable.
*
* Every implemented csCode is a plain getter:
*   move.l a4,d0 ; bne.b ok ; <statusErr> ; ok: movea.l (a4),a0
*   move.l <FIELD>(a0), $2(a3)   ; copy one globals field to csParam+2
*   bra.w StsOK
* i.e. 'Sts_GetField_XXX' below is literally: return globals+$XXX.
* Named by the field offset they read, since the true Apple selector
* names for these driver-private csCodes aren't recoverable from the
* binary.  Most csCodes (3,4,22-53) are unimplemented -> StsDefaultErr;
* csCode 54 is a distinct 'invoke callback #3' entry (Sts_InvokeHook3).
DoStatus:
  002f2:  4e 56 ff fc          link.w   a6, #$fffc
  002f6:  48 e7 11 18          movem.l  d3/d7/a3-a4, -(a7)
  002fa:  20 6e 00 08          movea.l  $8(a6), a0
  002fe:  4a a8 00 14          tst.l    $14(a0)
  00302:  66 0a                bne.b    $30e
  00304:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  0030a:  60 00 03 f8          bra.w    $704  ; -> StsExit
  0030e:  20 6e 00 0c          movea.l  $c(a6), a0
  00312:  47 e8 00 1c          lea.l    $1c(a0), a3
  00316:  20 6e 00 08          movea.l  $8(a6), a0
  0031a:  20 68 00 14          movea.l  $14(a0), a0
  0031e:  2d 48 ff fc          move.l   a0, -$4(a6)
  00322:  20 50                movea.l  (a0), a0
  00324:  30 28 02 2e          move.w   $22e(a0), d0
  00328:  48 c0                ext.l    d0
  0032a:  2e 00                move.l   d0, d7
  0032c:  36 87                move.w   d7, (a3)
  0032e:  20 6e ff fc          movea.l  -$4(a6), a0
  00332:  20 50                movea.l  (a0), a0
  00334:  30 28 00 10          move.w   $10(a0), d0
  00338:  48 c0                ext.l    d0
  0033a:  b0 87                cmp.l    d7, d0
  0033c:  6d 10                blt.b    $34e
  0033e:  20 6e ff fc          movea.l  -$4(a6), a0
  00342:  20 50                movea.l  (a0), a0
  00344:  41 e8 02 14          lea.l    $214(a0), a0
  00348:  4a b0 7c 00          tst.l    (a0, d7.l * 4)
  0034c:  66 06                bne.b    $354
  0034e:  70 00                moveq    #$0, d0
  00350:  28 40                movea.l  d0, a4
  00352:  60 12                bra.b    $366
  00354:  20 6e 00 08          movea.l  $8(a6), a0
  00358:  20 68 00 14          movea.l  $14(a0), a0
  0035c:  20 50                movea.l  (a0), a0
  0035e:  41 e8 02 14          lea.l    $214(a0), a0
  00362:  28 70 7c 00          movea.l  (a0, d7.l * 4), a4
  00366:  20 6e 00 0c          movea.l  $c(a6), a0
  0036a:  30 28 00 1a          move.w   $1a(a0), d0
  0036e:  55 40                subq.w   #$2, d0
  00370:  6b 00 03 86          bmi.w    $6f8  ; -> StsDefaultErr
  00374:  0c 40 00 34          cmpi.w   #$34, d0
  00378:  6e 00 03 7e          bgt.w    $6f8  ; -> StsDefaultErr
  0037c:  d0 40                add.w    d0, d0
  0037e:  30 3b 00 06          move.w   $386(pc, d0.w), d0
  00382:  4e fb 00 00          jmp      $384(pc,d0.w)
* StatusJumpTable  -  csCode 2..54.  Most slots alias
* StsDefaultErr; see DoStatus's header above for the real getters.
StatusJumpTable:
* jump table (word offsets relative to $0384):
  00386:  00 6c                dc.w     $006C    ; csCode 2 -> Sts_GetField_010
  00388:  03 74                dc.w     $0374    ; csCode 3 -> StsDefaultErr
  0038a:  03 74                dc.w     $0374    ; csCode 4 -> StsDefaultErr
  0038c:  01 94                dc.w     $0194    ; csCode 5 -> Sts_GetField_008
  0038e:  00 90                dc.w     $0090    ; csCode 6 -> Sts_GetField_250
  00390:  01 c8                dc.w     $01C8    ; csCode 7 -> Sts_GetField_128
  00392:  01 e2                dc.w     $01E2    ; csCode 8 -> Sts_GetField_002
  00394:  02 00                dc.w     $0200    ; csCode 9 -> Sts_GetField_000
  00396:  02 c2                dc.w     $02C2    ; csCode 10 -> Sts_GetField_a7c
  00398:  01 28                dc.w     $0128    ; csCode 11 -> Sts_GetField_162
  0039a:  01 46                dc.w     $0146    ; csCode 12 -> Sts_GetField_164
  0039c:  01 60                dc.w     $0160    ; csCode 13 -> Sts_GetField_168
  0039e:  01 7a                dc.w     $017A    ; csCode 14 -> Sts_GetField_004
  003a0:  02 1c                dc.w     $021C    ; csCode 15 -> Sts_GetField_168
  003a2:  02 7a                dc.w     $027A    ; csCode 16 -> Sts_GetField_144
  003a4:  00 a0                dc.w     $00A0    ; csCode 17 -> Sts_GetField_14c
  003a6:  00 c2                dc.w     $00C2    ; csCode 18 -> Sts_GetField_154
  003a8:  00 e4                dc.w     $00E4    ; csCode 19 -> Sts_cs19
  003aa:  00 80                dc.w     $0080    ; csCode 20 -> Sts_GetField_24c
  003ac:  01 ae                dc.w     $01AE    ; csCode 21 -> Sts_GetField_17c
  003ae:  03 74                dc.w     $0374    ; csCode 22 -> StsDefaultErr
  003b0:  03 74                dc.w     $0374    ; csCode 23 -> StsDefaultErr
  003b2:  03 74                dc.w     $0374    ; csCode 24 -> StsDefaultErr
  003b4:  03 74                dc.w     $0374    ; csCode 25 -> StsDefaultErr
  003b6:  03 74                dc.w     $0374    ; csCode 26 -> StsDefaultErr
  003b8:  03 74                dc.w     $0374    ; csCode 27 -> StsDefaultErr
  003ba:  03 74                dc.w     $0374    ; csCode 28 -> StsDefaultErr
  003bc:  03 74                dc.w     $0374    ; csCode 29 -> StsDefaultErr
  003be:  03 74                dc.w     $0374    ; csCode 30 -> StsDefaultErr
  003c0:  03 74                dc.w     $0374    ; csCode 31 -> StsDefaultErr
  003c2:  03 74                dc.w     $0374    ; csCode 32 -> StsDefaultErr
  003c4:  03 74                dc.w     $0374    ; csCode 33 -> StsDefaultErr
  003c6:  03 74                dc.w     $0374    ; csCode 34 -> StsDefaultErr
  003c8:  03 74                dc.w     $0374    ; csCode 35 -> StsDefaultErr
  003ca:  03 74                dc.w     $0374    ; csCode 36 -> StsDefaultErr
  003cc:  03 74                dc.w     $0374    ; csCode 37 -> StsDefaultErr
  003ce:  03 74                dc.w     $0374    ; csCode 38 -> StsDefaultErr
  003d0:  03 74                dc.w     $0374    ; csCode 39 -> StsDefaultErr
  003d2:  03 74                dc.w     $0374    ; csCode 40 -> StsDefaultErr
  003d4:  03 74                dc.w     $0374    ; csCode 41 -> StsDefaultErr
  003d6:  03 74                dc.w     $0374    ; csCode 42 -> StsDefaultErr
  003d8:  03 74                dc.w     $0374    ; csCode 43 -> StsDefaultErr
  003da:  03 74                dc.w     $0374    ; csCode 44 -> StsDefaultErr
  003dc:  03 74                dc.w     $0374    ; csCode 45 -> StsDefaultErr
  003de:  03 74                dc.w     $0374    ; csCode 46 -> StsDefaultErr
  003e0:  03 74                dc.w     $0374    ; csCode 47 -> StsDefaultErr
  003e2:  03 74                dc.w     $0374    ; csCode 48 -> StsDefaultErr
  003e4:  03 74                dc.w     $0374    ; csCode 49 -> StsDefaultErr
  003e6:  03 74                dc.w     $0374    ; csCode 50 -> StsDefaultErr
  003e8:  03 74                dc.w     $0374    ; csCode 51 -> StsDefaultErr
  003ea:  03 74                dc.w     $0374    ; csCode 52 -> StsDefaultErr
  003ec:  03 74                dc.w     $0374    ; csCode 53 -> StsDefaultErr
  003ee:  03 4c                dc.w     $034C    ; csCode 54 -> Sts_InvokeHook3
Sts_GetField_010:
  003f0:  20 6e ff fc          movea.l  -$4(a6), a0
  003f4:  20 50                movea.l  (a0), a0
  003f6:  30 28 00 10          move.w   $10(a0), d0
  003fa:  48 c0                ext.l    d0
  003fc:  27 40 00 02          move.l   d0, $2(a3)
  00400:  60 00 02 fe          bra.w    $700  ; -> StsOK
Sts_GetField_24c:
  00404:  20 6e ff fc          movea.l  -$4(a6), a0
  00408:  20 50                movea.l  (a0), a0
  0040a:  27 68 02 4c 00 02    move.l   $24c(a0), $2(a3)
  00410:  60 00 02 ee          bra.w    $700  ; -> StsOK
Sts_GetField_250:
  00414:  20 6e ff fc          movea.l  -$4(a6), a0
  00418:  20 50                movea.l  (a0), a0
  0041a:  27 68 02 50 00 02    move.l   $250(a0), $2(a3)
  00420:  60 00 02 de          bra.w    $700  ; -> StsOK
Sts_GetField_14c:
  00424:  20 0c                move.l   a4, d0
  00426:  66 0a                bne.b    $432
  00428:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  0042e:  60 00 02 d4          bra.w    $704  ; -> StsExit
  00432:  20 54                movea.l  (a4), a0
  00434:  27 68 01 4c 00 02    move.l   $14c(a0), $2(a3)
  0043a:  20 54                movea.l  (a4), a0
  0043c:  27 68 01 50 00 06    move.l   $150(a0), $6(a3)
  00442:  60 00 02 bc          bra.w    $700  ; -> StsOK
Sts_GetField_154:
  00446:  20 0c                move.l   a4, d0
  00448:  66 0a                bne.b    $454
  0044a:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  00450:  60 00 02 b2          bra.w    $704  ; -> StsExit
  00454:  20 54                movea.l  (a4), a0
  00456:  27 68 01 54 00 02    move.l   $154(a0), $2(a3)
  0045c:  20 54                movea.l  (a4), a0
  0045e:  27 68 01 58 00 06    move.l   $158(a0), $6(a3)
  00464:  60 00 02 9a          bra.w    $700  ; -> StsOK
Sts_cs19:
  00468:  20 0c                move.l   a4, d0
  0046a:  66 0a                bne.b    $476
  0046c:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  00472:  60 00 02 90          bra.w    $704  ; -> StsExit
  00476:  48 6b 00 06          pea.l    $6(a3)
  0047a:  48 6b 00 02          pea.l    $2(a3)
  0047e:  20 54                movea.l  (a4), a0
  00480:  70 00                moveq    #$0, d0
  00482:  30 10                move.w   (a0), d0
  00484:  2f 00                move.l   d0, -(a7)
  00486:  70 00                moveq    #$0, d0
  00488:  30 28 01 62          move.w   $162(a0), d0
  0048c:  2f 00                move.l   d0, -(a7)
  0048e:  61 ff 00 00 16 1a    bsr.l    $1aaa
  00494:  4a 80                tst.l    d0
  00496:  4f ef 00 10          lea.l    $10(a7), a7
  0049a:  67 00 02 64          beq.w    $700  ; -> StsOK
  0049e:  70 00                moveq    #$0, d0
  004a0:  27 40 00 02          move.l   d0, $2(a3)
  004a4:  27 40 00 06          move.l   d0, $6(a3)
  004a8:  60 00 02 56          bra.w    $700  ; -> StsOK
Sts_GetField_162:
  004ac:  20 0c                move.l   a4, d0
  004ae:  66 0a                bne.b    $4ba
  004b0:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  004b6:  60 00 02 4c          bra.w    $704  ; -> StsExit
  004ba:  20 54                movea.l  (a4), a0
  004bc:  70 00                moveq    #$0, d0
  004be:  30 28 01 62          move.w   $162(a0), d0
  004c2:  27 40 00 02          move.l   d0, $2(a3)
  004c6:  60 00 02 38          bra.w    $700  ; -> StsOK
Sts_GetField_164:
  004ca:  20 0c                move.l   a4, d0
  004cc:  66 0a                bne.b    $4d8
  004ce:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  004d4:  60 00 02 2e          bra.w    $704  ; -> StsExit
  004d8:  20 54                movea.l  (a4), a0
  004da:  27 68 01 64 00 02    move.l   $164(a0), $2(a3)
  004e0:  60 00 02 1e          bra.w    $700  ; -> StsOK
Sts_GetField_168:
  004e4:  20 0c                move.l   a4, d0
  004e6:  66 0a                bne.b    $4f2
  004e8:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  004ee:  60 00 02 14          bra.w    $704  ; -> StsExit
  004f2:  20 54                movea.l  (a4), a0
  004f4:  27 68 01 68 00 02    move.l   $168(a0), $2(a3)
  004fa:  60 00 02 04          bra.w    $700  ; -> StsOK
Sts_GetField_004:
  004fe:  20 0c                move.l   a4, d0
  00500:  66 0a                bne.b    $50c
  00502:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  00508:  60 00 01 fa          bra.w    $704  ; -> StsExit
  0050c:  20 54                movea.l  (a4), a0
  0050e:  27 68 00 04 00 02    move.l   $4(a0), $2(a3)
  00514:  60 00 01 ea          bra.w    $700  ; -> StsOK
Sts_GetField_008:
  00518:  20 0c                move.l   a4, d0
  0051a:  66 0a                bne.b    $526
  0051c:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  00522:  60 00 01 e0          bra.w    $704  ; -> StsExit
  00526:  20 54                movea.l  (a4), a0
  00528:  27 68 00 08 00 02    move.l   $8(a0), $2(a3)
  0052e:  60 00 01 d0          bra.w    $700  ; -> StsOK
Sts_GetField_17c:
  00532:  20 0c                move.l   a4, d0
  00534:  66 0a                bne.b    $540
  00536:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  0053c:  60 00 01 c6          bra.w    $704  ; -> StsExit
  00540:  20 54                movea.l  (a4), a0
  00542:  27 68 01 7c 00 02    move.l   $17c(a0), $2(a3)
  00548:  60 00 01 b6          bra.w    $700  ; -> StsOK
Sts_GetField_128:
  0054c:  20 0c                move.l   a4, d0
  0054e:  66 0a                bne.b    $55a
  00550:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  00556:  60 00 01 ac          bra.w    $704  ; -> StsExit
  0055a:  20 54                movea.l  (a4), a0
  0055c:  27 68 01 28 00 02    move.l   $128(a0), $2(a3)
  00562:  60 00 01 9c          bra.w    $700  ; -> StsOK
Sts_GetField_002:
  00566:  20 0c                move.l   a4, d0
  00568:  66 0a                bne.b    $574
  0056a:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  00570:  60 00 01 92          bra.w    $704  ; -> StsExit
  00574:  20 54                movea.l  (a4), a0
  00576:  70 00                moveq    #$0, d0
  00578:  30 28 00 02          move.w   $2(a0), d0
  0057c:  27 40 00 02          move.l   d0, $2(a3)
  00580:  60 00 01 7e          bra.w    $700  ; -> StsOK
Sts_GetField_000:
  00584:  20 0c                move.l   a4, d0
  00586:  66 0a                bne.b    $592
  00588:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  0058e:  60 00 01 74          bra.w    $704  ; -> StsExit
  00592:  20 54                movea.l  (a4), a0
  00594:  70 00                moveq    #$0, d0
  00596:  30 10                move.w   (a0), d0
  00598:  27 40 00 02          move.l   d0, $2(a3)
  0059c:  60 00 01 62          bra.w    $700  ; -> StsOK
Sts_GetField_168:
  005a0:  20 0c                move.l   a4, d0
  005a2:  66 0a                bne.b    $5ae
  005a4:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  005aa:  60 00 01 58          bra.w    $704  ; -> StsExit
  005ae:  20 54                movea.l  (a4), a0
  005b0:  20 3c 00 00 08 00    move.l   #$800, d0
  005b6:  c0 a8 01 68          and.l    $168(a0), d0
  005ba:  67 0a                beq.b    $5c6
  005bc:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  005c2:  60 00 01 40          bra.w    $704  ; -> StsExit
  005c6:  20 54                movea.l  (a4), a0
  005c8:  20 68 01 3c          movea.l  $13c(a0), a0
  005cc:  0c 90 96 66 66 69    cmpi.l   #$96666669, (a0)
  005d2:  67 0a                beq.b    $5de
  005d4:  70 00                moveq    #$0, d0
  005d6:  27 40 00 02          move.l   d0, $2(a3)
  005da:  60 00 01 24          bra.w    $700  ; -> StsOK
  005de:  20 54                movea.l  (a4), a0
  005e0:  70 00                moveq    #$0, d0
  005e2:  30 10                move.w   (a0), d0
  005e4:  2f 00                move.l   d0, -(a7)
  005e6:  20 28 01 44          move.l   $144(a0), d0
  005ea:  58 80                addq.l   #$4, d0
  005ec:  2f 00                move.l   d0, -(a7)
  005ee:  61 ff 00 00 29 94    bsr.l    $2f84
  005f4:  27 40 00 02          move.l   d0, $2(a3)
  005f8:  50 4f                addq.w   #$8, a7
  005fa:  60 00 01 04          bra.w    $700  ; -> StsOK
Sts_GetField_144:
  005fe:  20 0c                move.l   a4, d0
  00600:  66 0a                bne.b    $60c
  00602:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  00608:  60 00 00 fa          bra.w    $704  ; -> StsExit
  0060c:  20 54                movea.l  (a4), a0
  0060e:  20 3c 00 00 08 00    move.l   #$800, d0
  00614:  c0 a8 01 68          and.l    $168(a0), d0
  00618:  67 0a                beq.b    $624
  0061a:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  00620:  60 00 00 e2          bra.w    $704  ; -> StsExit
  00624:  20 54                movea.l  (a4), a0
  00626:  20 28 01 44          move.l   $144(a0), d0
  0062a:  72 10                moveq    #$10, d1
  0062c:  d0 81                add.l    d1, d0
  0062e:  c0 bc 0f ff ff ff    and.l    #$fffffff, d0
  00634:  74 00                moveq    #$0, d2
  00636:  34 10                move.w   (a0), d2
  00638:  76 1c                moveq    #$1c, d3
  0063a:  e7 aa                lsl.l    d3, d2
  0063c:  84 80                or.l     d0, d2
  0063e:  27 42 00 02          move.l   d2, $2(a3)
  00642:  60 00 00 bc          bra.w    $700  ; -> StsOK
Sts_GetField_a7c:
  00646:  20 0c                move.l   a4, d0
  00648:  66 0a                bne.b    $654
  0064a:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  00650:  60 00 00 b2          bra.w    $704  ; -> StsExit
  00654:  20 6e 00 08          movea.l  $8(a6), a0
  00658:  20 68 00 14          movea.l  $14(a0), a0
  0065c:  20 50                movea.l  (a0), a0
  0065e:  4a a8 0a 80          tst.l    $a80(a0)
  00662:  67 14                beq.b    $678
  00664:  2f 0c                move.l   a4, -(a7)
  00666:  20 6e 00 08          movea.l  $8(a6), a0
  0066a:  20 68 00 14          movea.l  $14(a0), a0
  0066e:  20 50                movea.l  (a0), a0
  00670:  22 68 0a 80          movea.l  $a80(a0), a1
  00674:  4e 91                jsr      (a1)
  00676:  58 4f                addq.w   #$4, a7
  00678:  20 6e 00 08          movea.l  $8(a6), a0
  0067c:  20 68 00 14          movea.l  $14(a0), a0
  00680:  20 50                movea.l  (a0), a0
  00682:  4a a8 0a 7c          tst.l    $a7c(a0)
  00686:  67 20                beq.b    $6a8
  00688:  20 54                movea.l  (a4), a0
  0068a:  2f 28 01 2c          move.l   $12c(a0), -(a7)
  0068e:  2f 0c                move.l   a4, -(a7)
  00690:  20 6e 00 08          movea.l  $8(a6), a0
  00694:  20 68 00 14          movea.l  $14(a0), a0
  00698:  20 50                movea.l  (a0), a0
  0069a:  22 68 0a 7c          movea.l  $a7c(a0), a1
  0069e:  4e 91                jsr      (a1)
  006a0:  20 54                movea.l  (a4), a0
  006a2:  21 40 01 2c          move.l   d0, $12c(a0)
  006a6:  50 4f                addq.w   #$8, a7
  006a8:  20 54                movea.l  (a4), a0
  006aa:  27 68 01 2c 00 02    move.l   $12c(a0), $2(a3)
  006b0:  70 01                moveq    #$1, d0
  006b2:  b0 a8 01 2c          cmp.l    $12c(a0), d0
  006b6:  67 0c                beq.b    $6c4
  006b8:  20 54                movea.l  (a4), a0
  006ba:  00 a8 00 00 01 00 00 08 ori.l    #$100, $8(a0)
  006c2:  60 3c                bra.b    $700  ; -> StsOK
  006c4:  20 54                movea.l  (a4), a0
  006c6:  02 a8 ff ff fe ff 00 08 andi.l   #$fffffeff, $8(a0)
  006ce:  60 30                bra.b    $700  ; -> StsOK
* Sts_InvokeHook3 (csCode 54)  -  calls the client-installable
* callback at globals+$A84 (see DoOpen's $A78 8-slot table) with
* (globals+$AA0, 0, $FF), returning its D0 result via csParam+2.
Sts_InvokeHook3:
  006d0:  20 6e ff fc          movea.l  -$4(a6), a0
  006d4:  20 50                movea.l  (a0), a0
  006d6:  48 68 0a a0          pea.l    $aa0(a0)
  006da:  70 00                moveq    #$0, d0
  006dc:  2f 00                move.l   d0, -(a7)
  006de:  72 ff                moveq    #$ff, d1
  006e0:  2f 01                move.l   d1, -(a7)
  006e2:  20 6e ff fc          movea.l  -$4(a6), a0
  006e6:  20 50                movea.l  (a0), a0
  006e8:  22 68 0a 84          movea.l  $a84(a0), a1
  006ec:  4e 91                jsr      (a1)
  006ee:  27 40 00 02          move.l   d0, $2(a3)
  006f2:  4f ef 00 0c          lea.l    $c(a7), a7
  006f6:  60 08                bra.b    $700  ; -> StsOK
* StsDefaultErr  -  statusErr (-18) for any unimplemented csCode.
StsDefaultErr:
  006f8:  3d 7c ff ee 00 10    move.w   #$ffee, $10(a6)
  006fe:  60 04                bra.b    $704  ; -> StsExit
* StsOK  -  shared success landing point (falls into StsExit).
StsOK:
  00700:  42 6e 00 10          clr.w    $10(a6)
* StsExit  -  restore saved regs, unlk, rtd #8 (pop the 2
* longword args CommonDispatch pushed).
StsExit:
  00704:  4c ee 18 88 ff ec    movem.l  -$14(a6), d3/d7/a3-a4
  0070a:  4e 5e                unlk     a6
  0070c:  4e 74 00 08          rtd      #$8
* ==================================================================
* DoControl
* ==================================================================
* Same A0/A1/A3 setup as DoStatus.  ParamBlock.csCode == $FF is treated
* as a sentinel/no-op (returns noErr immediately without touching
* csParam) -- likely the 'ping'/'is this driver alive' pattern used by
* higher-level software (INIT/gc24) probing for the driver before
* issuing real commands.  Otherwise HLock's the dCtlStorage handle,
* derefs to the engine globals (A3), and validates an index (D7) taken
* from csParam against globals+$10 (a count field) before continuing.
* One Control path (via LoadFirmware, bsr'd at $AEC below) drives
* this driver's own copy of the ACEFLoad Am29000-COFF loader -- i.e.
* *this* driver, not just gc24, can download firmware to the card.
DoControl:
  00710:  4e 56 ff ec          link.w   a6, #$ffec
  00714:  48 e7 07 18          movem.l  d5-d7/a3-a4, -(a7)
  00718:  20 6e 00 08          movea.l  $8(a6), a0
  0071c:  4a a8 00 14          tst.l    $14(a0)
  00720:  66 0a                bne.b    $72c
  00722:  3d 7c ff ef 00 10    move.w   #$ffef, $10(a6)
  00728:  60 00 08 58          bra.w    $f82
  0072c:  4a ae 00 0c          tst.l    $c(a6)
  00730:  67 0c                beq.b    $73e
  00732:  20 6e 00 0c          movea.l  $c(a6), a0
  00736:  70 ff                moveq    #$ff, d0
  00738:  b0 68 00 1a          cmp.w    $1a(a0), d0
  0073c:  66 08                bne.b    $746
  0073e:  42 6e 00 10          clr.w    $10(a6)
  00742:  60 00 08 3e          bra.w    $f82
  00746:  20 6e 00 0c          movea.l  $c(a6), a0
  0074a:  41 e8 00 1c          lea.l    $1c(a0), a0
  0074e:  2d 48 ff f4          move.l   a0, -$c(a6)
  00752:  20 08                move.l   a0, d0
  00754:  66 08                bne.b    $75e
  00756:  42 6e 00 10          clr.w    $10(a6)
  0075a:  60 00 08 26          bra.w    $f82
  0075e:  20 6e 00 08          movea.l  $8(a6), a0
  00762:  20 68 00 14          movea.l  $14(a0), a0
  00766:  a0 29                dc.w     $a029  ; _HLock
  00768:  20 6e 00 08          movea.l  $8(a6), a0
  0076c:  20 68 00 14          movea.l  $14(a0), a0
  00770:  26 50                movea.l  (a0), a3
  00772:  20 6e ff f4          movea.l  -$c(a6), a0
  00776:  3e 10                move.w   (a0), d7
  00778:  6d 06                blt.b    $780
  0077a:  be 6b 00 10          cmp.w    $10(a3), d7
  0077e:  6d 0c                blt.b    $78c
  00780:  29 7c ff ff d8 da 01 7c move.l   #$ffffd8da, $17c(a4)
  00788:  60 00 07 ea          bra.w    $f74
  0078c:  37 47 02 2e          move.w   d7, $22e(a3)
  00790:  4a 6b 00 10          tst.w    $10(a3)
  00794:  67 0c                beq.b    $7a2
  00796:  48 c7                ext.l    d7
  00798:  41 eb 02 14          lea.l    $214(a3), a0
  0079c:  4a b0 7c 00          tst.l    (a0, d7.l * 4)
  007a0:  66 06                bne.b    $7a8
  007a2:  70 00                moveq    #$0, d0
  007a4:  28 40                movea.l  d0, a4
  007a6:  60 18                bra.b    $7c0
  007a8:  48 c7                ext.l    d7
  007aa:  41 eb 02 14          lea.l    $214(a3), a0
  007ae:  2d 70 7c 00 ff f0    move.l   (a0, d7.l * 4), -$10(a6)
  007b4:  20 6e ff f0          movea.l  -$10(a6), a0
  007b8:  a0 29                dc.w     $a029  ; _HLock
  007ba:  20 6e ff f0          movea.l  -$10(a6), a0
  007be:  28 50                movea.l  (a0), a4
  007c0:  20 6e 00 0c          movea.l  $c(a6), a0
  007c4:  30 28 00 1a          move.w   $1a(a0), d0
  007c8:  55 40                subq.w   #$2, d0
  007ca:  67 00 01 3e          beq.w    $90a
  007ce:  53 40                subq.w   #$1, d0
  007d0:  67 00 02 fc          beq.w    $ace
  007d4:  53 40                subq.w   #$1, d0
  007d6:  67 00 03 30          beq.w    $b08
  007da:  53 40                subq.w   #$1, d0
  007dc:  67 00 03 5a          beq.w    $b38
  007e0:  53 40                subq.w   #$1, d0
  007e2:  67 00 03 80          beq.w    $b64
  007e6:  59 40                subq.w   #$4, d0
  007e8:  67 00 07 5c          beq.w    $f46
  007ec:  53 40                subq.w   #$1, d0
  007ee:  67 00 07 60          beq.w    $f50
  007f2:  53 40                subq.w   #$1, d0
  007f4:  67 00 07 64          beq.w    $f5a
  007f8:  53 40                subq.w   #$1, d0
  007fa:  67 00 06 20          beq.w    $e1c
  007fe:  53 40                subq.w   #$1, d0
  00800:  67 00 06 d6          beq.w    $ed8
  00804:  55 40                subq.w   #$2, d0
  00806:  67 78                beq.b    $880
  00808:  53 40                subq.w   #$1, d0
  0080a:  67 00 05 0c          beq.w    $d18
  0080e:  53 40                subq.w   #$1, d0
  00810:  67 00 07 24          beq.w    $f36
  00814:  53 40                subq.w   #$1, d0
  00816:  67 00 03 12          beq.w    $b2a
  0081a:  53 40                subq.w   #$1, d0
  0081c:  67 00 00 9a          beq.w    $8b8
  00820:  53 40                subq.w   #$1, d0
  00822:  67 00 00 d4          beq.w    $8f8
  00826:  04 40 00 1b          subi.w   #$1b, d0
  0082a:  67 00 03 56          beq.w    $b82
  0082e:  53 40                subq.w   #$1, d0
  00830:  67 00 02 64          beq.w    $a96
  00834:  53 40                subq.w   #$1, d0
  00836:  67 00 03 de          beq.w    $c16
  0083a:  53 40                subq.w   #$1, d0
  0083c:  67 00 03 68          beq.w    $ba6
  00840:  53 40                subq.w   #$1, d0
  00842:  67 2e                beq.b    $872
  00844:  53 40                subq.w   #$1, d0
  00846:  67 12                beq.b    $85a
  00848:  53 40                subq.w   #$1, d0
  0084a:  67 00 06 be          beq.w    $f0a
  0084e:  04 40 00 2d          subi.w   #$2d, d0
  00852:  67 00 07 1a          beq.w    $f6e
  00856:  60 00 07 0c          bra.w    $f64
  0085a:  20 6e ff f4          movea.l  -$c(a6), a0
  0085e:  2f 28 00 02          move.l   $2(a0), -(a7)
  00862:  48 6b 0a aa          pea.l    $aaa(a3)
  00866:  61 ff 00 00 10 46    bsr.l    $18ae
  0086c:  50 4f                addq.w   #$8, a7
  0086e:  60 00 06 fe          bra.w    $f6e
  00872:  20 6e ff f4          movea.l  -$c(a6), a0
  00876:  37 68 00 04 0a a6    move.w   $4(a0), $aa6(a3)
  0087c:  60 00 06 f0          bra.w    $f6e
  00880:  20 6e ff f4          movea.l  -$c(a6), a0
  00884:  27 68 00 02 02 50    move.l   $2(a0), $250(a3)
  0088a:  4a 2b 02 57          tst.b    $257(a3)
  0088e:  67 00 06 de          beq.w    $f6e
  00892:  20 6e 00 08          movea.l  $8(a6), a0
  00896:  20 68 00 14          movea.l  $14(a0), a0
  0089a:  2f 10                move.l   (a0), -(a7)
  0089c:  61 ff 00 00 0b 98    bsr.l    $1436
  008a2:  20 6e 00 08          movea.l  $8(a6), a0
  008a6:  20 68 00 14          movea.l  $14(a0), a0
  008aa:  2f 10                move.l   (a0), -(a7)
  008ac:  61 ff 00 00 0c 02    bsr.l    $14b0
  008b2:  50 4f                addq.w   #$8, a7
  008b4:  60 00 06 b8          bra.w    $f6e
  008b8:  20 0c                move.l   a4, d0
  008ba:  67 00 06 c0          beq.w    $f7c
  008be:  20 6e ff f4          movea.l  -$c(a6), a0
  008c2:  29 68 00 02 01 7c    move.l   $2(a0), $17c(a4)
  008c8:  00 ac 00 00 04 00 00 08 ori.l    #$400, $8(a4)
  008d0:  4a 2b 02 57          tst.b    $257(a3)
  008d4:  67 12                beq.b    $8e8
  008d6:  20 6e 00 08          movea.l  $8(a6), a0
  008da:  20 68 00 14          movea.l  $14(a0), a0
  008de:  2f 10                move.l   (a0), -(a7)
  008e0:  61 ff 00 00 0b 54    bsr.l    $1436
  008e6:  58 4f                addq.w   #$4, a7
  008e8:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  008ec:  61 ff 00 00 14 a0    bsr.l    $1d8e
  008f2:  58 4f                addq.w   #$4, a7
  008f4:  60 00 06 78          bra.w    $f6e
  008f8:  20 0c                move.l   a4, d0
  008fa:  67 00 06 80          beq.w    $f7c
  008fe:  00 ac 00 00 08 00 00 08 ori.l    #$800, $8(a4)
  00906:  60 00 06 66          bra.w    $f6e
  0090a:  20 0c                move.l   a4, d0
  0090c:  67 00 06 6e          beq.w    $f7c
  00910:  2f 0b                move.l   a3, -(a7)
  00912:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00916:  61 ff 00 00 21 ba    bsr.l    $2ad2
  0091c:  20 6e ff f4          movea.l  -$c(a6), a0
  00920:  2d 68 00 02 ff fc    move.l   $2(a0), -$4(a6)
  00926:  50 4f                addq.w   #$8, a7
  00928:  67 74                beq.b    $99e
  0092a:  4a ac 01 48          tst.l    $148(a4)
  0092e:  66 54                bne.b    $984
  00930:  a1 1a                dc.w     $a11a  ; _GetZone
  00932:  2d 48 ff f8          move.l   a0, -$8(a6)
  00936:  20 78 02 a6          movea.l  $2a6.w, a0
  0093a:  a0 1b                dc.w     $a01b  ; _SetZone
  0093c:  59 8f                subq.l   #$4, a7
  0093e:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  00942:  61 ff 00 00 3c 20    bsr.l    $4564
  00948:  2c 1f                move.l   (a7)+, d6
  0094a:  20 06                move.l   d6, d0
  0094c:  a1 22                dc.w     $a122  ; _NewHandle
  0094e:  29 48 01 48          move.l   a0, $148(a4)
  00952:  20 08                move.l   a0, d0
  00954:  66 0c                bne.b    $962
  00956:  29 7c ff ff d8 da 01 7c move.l   #$ffffd8da, $17c(a4)
  0095e:  60 00 06 14          bra.w    $f74
  00962:  20 6c 01 48          movea.l  $148(a4), a0
  00966:  a0 64                dc.w     $a064  ; _MoveHHi
  00968:  20 6c 01 48          movea.l  $148(a4), a0
  0096c:  a0 4a                dc.w     $a04a  ; _HNoPurge
  0096e:  20 6e ff fc          movea.l  -$4(a6), a0
  00972:  20 50                movea.l  (a0), a0
  00974:  22 6c 01 48          movea.l  $148(a4), a1
  00978:  22 51                movea.l  (a1), a1
  0097a:  20 06                move.l   d6, d0
  0097c:  a0 2e                dc.w     $a02e  ; _BlockMove
  0097e:  20 6e ff f8          movea.l  -$8(a6), a0
  00982:  a0 1b                dc.w     $a01b  ; _SetZone
  00984:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  00988:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  0098c:  61 ff 00 00 1a 3e    bsr.l    $23cc
  00992:  4a 80                tst.l    d0
  00994:  50 4f                addq.w   #$8, a7
  00996:  67 00 05 d6          beq.w    $f6e
  0099a:  60 00 05 d8          bra.w    $f74
  0099e:  4a ac 01 48          tst.l    $148(a4)
  009a2:  67 0a                beq.b    $9ae
  009a4:  20 6c 01 48          movea.l  $148(a4), a0
  009a8:  4a 90                tst.l    (a0)
  009aa:  66 00 00 a6          bne.w    $a52
  009ae:  42 47                clr.w    d7
  009b0:  60 00 00 98          bra.w    $a4a
  009b4:  48 c7                ext.l    d7
  009b6:  41 eb 02 14          lea.l    $214(a3), a0
  009ba:  4a b0 7c 00          tst.l    (a0, d7.l * 4)
  009be:  67 00 00 86          beq.w    $a46
  009c2:  48 c7                ext.l    d7
  009c4:  43 eb 02 14          lea.l    $214(a3), a1
  009c8:  20 71 7c 00          movea.l  (a1, d7.l * 4), a0
  009cc:  20 50                movea.l  (a0), a0
  009ce:  2d 48 ff ec          move.l   a0, -$14(a6)
  009d2:  30 2c 01 62          move.w   $162(a4), d0
  009d6:  b0 68 01 62          cmp.w    $162(a0), d0
  009da:  66 6a                bne.b    $a46
  009dc:  4a a8 01 48          tst.l    $148(a0)
  009e0:  67 64                beq.b    $a46
  009e2:  a1 1a                dc.w     $a11a  ; _GetZone
  009e4:  2d 48 ff f8          move.l   a0, -$8(a6)
  009e8:  20 78 02 a6          movea.l  $2a6.w, a0
  009ec:  a0 1b                dc.w     $a01b  ; _SetZone
  009ee:  59 8f                subq.l   #$4, a7
  009f0:  20 6e ff ec          movea.l  -$14(a6), a0
  009f4:  2f 28 01 48          move.l   $148(a0), -(a7)
  009f8:  61 ff 00 00 3b 6a    bsr.l    $4564
  009fe:  2c 1f                move.l   (a7)+, d6
  00a00:  20 06                move.l   d6, d0
  00a02:  a1 22                dc.w     $a122  ; _NewHandle
  00a04:  29 48 01 48          move.l   a0, $148(a4)
  00a08:  20 08                move.l   a0, d0
  00a0a:  66 12                bne.b    $a1e
  00a0c:  20 6e ff f8          movea.l  -$8(a6), a0
  00a10:  a0 1b                dc.w     $a01b  ; _SetZone
  00a12:  29 7c ff ff d8 da 01 7c move.l   #$ffffd8da, $17c(a4)
  00a1a:  60 00 05 58          bra.w    $f74
  00a1e:  20 6c 01 48          movea.l  $148(a4), a0
  00a22:  a0 64                dc.w     $a064  ; _MoveHHi
  00a24:  20 6c 01 48          movea.l  $148(a4), a0
  00a28:  a0 4a                dc.w     $a04a  ; _HNoPurge
  00a2a:  20 6e ff f8          movea.l  -$8(a6), a0
  00a2e:  a0 1b                dc.w     $a01b  ; _SetZone
  00a30:  20 6e ff ec          movea.l  -$14(a6), a0
  00a34:  20 68 01 48          movea.l  $148(a0), a0
  00a38:  20 50                movea.l  (a0), a0
  00a3a:  22 6c 01 48          movea.l  $148(a4), a1
  00a3e:  22 51                movea.l  (a1), a1
  00a40:  20 06                move.l   d6, d0
  00a42:  a0 2e                dc.w     $a02e  ; _BlockMove
  00a44:  60 0c                bra.b    $a52
  00a46:  30 07                move.w   d7, d0
  00a48:  52 47                addq.w   #$1, d7
  00a4a:  be 6b 00 10          cmp.w    $10(a3), d7
  00a4e:  6d 00 ff 64          blt.w    $9b4
  00a52:  4a ac 01 48          tst.l    $148(a4)
  00a56:  66 18                bne.b    $a70
  00a58:  48 7a 05 52          pea.l    $fac(pc)
  00a5c:  61 ff 00 00 26 3e    bsr.l    $309c
  00a62:  29 7c ff ff d8 da 01 7c move.l   #$ffffd8da, $17c(a4)
  00a6a:  58 4f                addq.w   #$4, a7
  00a6c:  60 00 05 06          bra.w    $f74
  00a70:  2f 2c 01 48          move.l   $148(a4), -(a7)
  00a74:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00a78:  61 ff 00 00 19 52    bsr.l    $23cc
  00a7e:  4a 80                tst.l    d0
  00a80:  50 4f                addq.w   #$8, a7
  00a82:  67 00 04 ea          beq.w    $f6e
  00a86:  48 7a 05 06          pea.l    $f8e(pc)
  00a8a:  61 ff 00 00 26 10    bsr.l    $309c
  00a90:  58 4f                addq.w   #$4, a7
  00a92:  60 00 04 e0          bra.w    $f74
  00a96:  20 0c                move.l   a4, d0
  00a98:  67 00 04 e2          beq.w    $f7c
  00a9c:  2f 2c 01 30          move.l   $130(a4), -(a7)
  00aa0:  70 00                moveq    #$0, d0
  00aa2:  30 14                move.w   (a4), d0
  00aa4:  2f 00                move.l   d0, -(a7)
  00aa6:  20 6e ff f4          movea.l  -$c(a6), a0
  00aaa:  2f 28 00 06          move.l   $6(a0), -(a7)
  00aae:  2f 28 00 02          move.l   $2(a0), -(a7)
  00ab2:  61 ff 00 00 22 90    bsr.l    $2d44
  00ab8:  4a 80                tst.l    d0
  00aba:  4f ef 00 10          lea.l    $10(a7), a7
  00abe:  67 00 04 ae          beq.w    $f6e
  00ac2:  29 7c ff ff d8 da 01 7c move.l   #$ffffd8da, $17c(a4)
  00aca:  60 00 04 a8          bra.w    $f74
  00ace:  20 0c                move.l   a4, d0
  00ad0:  67 00 04 aa          beq.w    $f7c
  00ad4:  2f 0b                move.l   a3, -(a7)
  00ad6:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00ada:  61 ff 00 00 1f f6    bsr.l    $2ad2
  00ae0:  20 6e ff f4          movea.l  -$c(a6), a0
  00ae4:  2f 28 00 02          move.l   $2(a0), -(a7)
  00ae8:  2f 2e ff f0          move.l   -$10(a6), -(a7)
* (a Control sub-path) -> calls LoadFirmware, which in turn calls
* ACEFLoad -- this Control selector loads/reloads the Am29000 firmware.
  00aec:  61 ff 00 00 1e 38    bsr.l    $2926  ; -> LoadFirmware
  00af2:  4a 80                tst.l    d0
  00af4:  4f ef 00 10          lea.l    $10(a7), a7
  00af8:  67 00 04 74          beq.w    $f6e
  00afc:  29 7c ff ff d8 da 01 7c move.l   #$ffffd8da, $17c(a4)
  00b04:  60 00 04 6e          bra.w    $f74
  00b08:  20 0c                move.l   a4, d0
  00b0a:  67 00 04 70          beq.w    $f7c
  00b0e:  2f 0b                move.l   a3, -(a7)
  00b10:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00b14:  61 ff 00 00 1f bc    bsr.l    $2ad2
  00b1a:  20 6e ff f4          movea.l  -$c(a6), a0
  00b1e:  29 68 00 02 01 2c    move.l   $2(a0), $12c(a4)
  00b24:  50 4f                addq.w   #$8, a7
  00b26:  60 00 04 46          bra.w    $f6e
  00b2a:  20 6e ff f4          movea.l  -$c(a6), a0
  00b2e:  27 68 00 02 02 4c    move.l   $2(a0), $24c(a3)
  00b34:  60 00 04 38          bra.w    $f6e
  00b38:  20 0c                move.l   a4, d0
  00b3a:  67 00 04 40          beq.w    $f7c
  00b3e:  2f 0b                move.l   a3, -(a7)
  00b40:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00b44:  61 ff 00 00 1f 8c    bsr.l    $2ad2
  00b4a:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00b4e:  61 ff 00 00 12 8c    bsr.l    $1ddc
  00b54:  00 ac 00 00 00 04 00 08 ori.l    #$4, $8(a4)
  00b5c:  4f ef 00 0c          lea.l    $c(a7), a7
  00b60:  60 00 04 0c          bra.w    $f6e
  00b64:  20 0c                move.l   a4, d0
  00b66:  67 00 04 14          beq.w    $f7c
  00b6a:  02 ac ff ff ff fb 00 08 andi.l   #$fffffffb, $8(a4)
  00b72:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00b76:  61 ff 00 00 12 16    bsr.l    $1d8e
  00b7c:  58 4f                addq.w   #$4, a7
  00b7e:  60 00 03 ee          bra.w    $f6e
  00b82:  20 0c                move.l   a4, d0
  00b84:  67 00 03 f6          beq.w    $f7c
  00b88:  2f 0b                move.l   a3, -(a7)
  00b8a:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00b8e:  61 ff 00 00 1f 42    bsr.l    $2ad2
  00b94:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00b98:  61 ff 00 00 1e 9e    bsr.l    $2a38
  00b9e:  4f ef 00 0c          lea.l    $c(a7), a7
  00ba2:  60 00 03 ca          bra.w    $f6e
  00ba6:  20 0c                move.l   a4, d0
  00ba8:  67 00 03 d2          beq.w    $f7c
  00bac:  20 3c 00 00 08 00    move.l   #$800, d0
  00bb2:  c0 ac 01 68          and.l    $168(a4), d0
  00bb6:  66 00 03 bc          bne.w    $f74
  00bba:  70 04                moveq    #$4, d0
  00bbc:  c0 ac 00 08          and.l    $8(a4), d0
  00bc0:  67 00 03 b2          beq.w    $f74
  00bc4:  20 3c 00 00 06 00    move.l   #$600, d0
  00bca:  c0 ac 00 08          and.l    $8(a4), d0
  00bce:  66 00 03 a4          bne.w    $f74
  00bd2:  20 6c 01 3c          movea.l  $13c(a4), a0
  00bd6:  70 00                moveq    #$0, d0
  00bd8:  20 80                move.l   d0, (a0)
  00bda:  70 00                moveq    #$0, d0
  00bdc:  30 14                move.w   (a4), d0
  00bde:  2f 00                move.l   d0, -(a7)
  00be0:  20 6e ff f4          movea.l  -$c(a6), a0
  00be4:  2f 28 00 02          move.l   $2(a0), -(a7)
  00be8:  20 2c 01 44          move.l   $144(a4), d0
  00bec:  50 80                addq.l   #$8, d0
  00bee:  2f 00                move.l   d0, -(a7)
  00bf0:  61 ff 00 00 23 d6    bsr.l    $2fc8
  00bf6:  70 00                moveq    #$0, d0
  00bf8:  30 14                move.w   (a4), d0
  00bfa:  2f 00                move.l   d0, -(a7)
  00bfc:  2f 3c 73 33 33 37    move.l   #$73333337, -(a7)
  00c02:  20 2c 01 44          move.l   $144(a4), d0
  00c06:  2f 00                move.l   d0, -(a7)
  00c08:  61 ff 00 00 23 be    bsr.l    $2fc8
  00c0e:  4f ef 00 18          lea.l    $18(a7), a7
  00c12:  60 00 03 5a          bra.w    $f6e
  00c16:  20 0c                move.l   a4, d0
  00c18:  67 00 03 62          beq.w    $f7c
  00c1c:  20 3c 00 00 06 00    move.l   #$600, d0
  00c22:  c0 ac 00 08          and.l    $8(a4), d0
  00c26:  66 00 03 4c          bne.w    $f74
  00c2a:  00 ac 00 00 01 00 01 28 ori.l    #$100, $128(a4)
  00c32:  70 07                moveq    #$7, d0
  00c34:  c0 ac 00 08          and.l    $8(a4), d0
  00c38:  72 07                moveq    #$7, d1
  00c3a:  b2 80                cmp.l    d0, d1
  00c3c:  66 00 03 30          bne.w    $f6e
  00c40:  70 20                moveq    #$20, d0
  00c42:  c0 ac 00 08          and.l    $8(a4), d0
  00c46:  67 00 00 a6          beq.w    $cee
  00c4a:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00c4e:  20 6b 0a 80          movea.l  $a80(a3), a0
  00c52:  4e 90                jsr      (a0)
  00c54:  2f 0b                move.l   a3, -(a7)
  00c56:  61 ff 00 00 07 de    bsr.l    $1436
  00c5c:  02 ac ff ff ff df 00 08 andi.l   #$ffffffdf, $8(a4)
  00c64:  20 6e 00 08          movea.l  $8(a6), a0
  00c68:  20 68 00 14          movea.l  $14(a0), a0
  00c6c:  2f 10                move.l   (a0), -(a7)
  00c6e:  61 ff 00 00 08 40    bsr.l    $14b0
  00c74:  4a 80                tst.l    d0
  00c76:  4f ef 00 0c          lea.l    $c(a7), a7
  00c7a:  67 0c                beq.b    $c88
  00c7c:  29 7c ff ff d8 da 01 7c move.l   #$ffffd8da, $17c(a4)
  00c84:  60 00 02 ee          bra.w    $f74
  00c88:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00c8c:  2f 0b                move.l   a3, -(a7)
  00c8e:  61 ff 00 00 10 4c    bsr.l    $1cdc
  00c94:  4a 80                tst.l    d0
  00c96:  50 4f                addq.w   #$8, a7
  00c98:  67 16                beq.b    $cb0
  00c9a:  29 7c ff ff d8 da 01 7c move.l   #$ffffd8da, $17c(a4)
  00ca2:  2f 0b                move.l   a3, -(a7)
  00ca4:  61 ff 00 00 07 90    bsr.l    $1436
  00caa:  58 4f                addq.w   #$4, a7
  00cac:  60 00 02 c6          bra.w    $f74
  00cb0:  2f 0b                move.l   a3, -(a7)
  00cb2:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00cb6:  61 ff 00 00 1e 1a    bsr.l    $2ad2
  00cbc:  70 04                moveq    #$4, d0
  00cbe:  c0 ac 00 08          and.l    $8(a4), d0
  00cc2:  50 4f                addq.w   #$8, a7
  00cc4:  67 0c                beq.b    $cd2
  00cc6:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00cca:  61 ff 00 00 1d 6c    bsr.l    $2a38
  00cd0:  58 4f                addq.w   #$4, a7
  00cd2:  00 ac 00 00 00 20 00 08 ori.l    #$20, $8(a4)
  00cda:  70 00                moveq    #$0, d0
  00cdc:  2f 00                move.l   d0, -(a7)
  00cde:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00ce2:  20 6b 0a 7c          movea.l  $a7c(a3), a0
  00ce6:  4e 90                jsr      (a0)
  00ce8:  50 4f                addq.w   #$8, a7
  00cea:  60 00 02 82          bra.w    $f6e
  00cee:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00cf2:  2f 0b                move.l   a3, -(a7)
  00cf4:  61 ff 00 00 0f e6    bsr.l    $1cdc
  00cfa:  2f 0b                move.l   a3, -(a7)
  00cfc:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00d00:  61 ff 00 00 1d d0    bsr.l    $2ad2
  00d06:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00d0a:  61 ff 00 00 1d 2c    bsr.l    $2a38
  00d10:  4f ef 00 14          lea.l    $14(a7), a7
  00d14:  60 00 02 58          bra.w    $f6e
  00d18:  20 0c                move.l   a4, d0
  00d1a:  67 00 02 60          beq.w    $f7c
  00d1e:  20 3c 00 00 06 00    move.l   #$600, d0
  00d24:  c0 ac 00 08          and.l    $8(a4), d0
  00d28:  66 00 02 4a          bne.w    $f74
  00d2c:  20 6e ff f4          movea.l  -$c(a6), a0
  00d30:  29 68 00 02 01 28    move.l   $2(a0), $128(a4)
  00d36:  70 07                moveq    #$7, d0
  00d38:  c0 ac 00 08          and.l    $8(a4), d0
  00d3c:  72 07                moveq    #$7, d1
  00d3e:  b2 80                cmp.l    d0, d1
  00d40:  66 00 02 2c          bne.w    $f6e
  00d44:  70 20                moveq    #$20, d0
  00d46:  c0 ac 00 08          and.l    $8(a4), d0
  00d4a:  67 00 00 a6          beq.w    $df2
  00d4e:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00d52:  20 6b 0a 80          movea.l  $a80(a3), a0
  00d56:  4e 90                jsr      (a0)
  00d58:  2f 0b                move.l   a3, -(a7)
  00d5a:  61 ff 00 00 06 da    bsr.l    $1436
  00d60:  02 ac ff ff ff df 00 08 andi.l   #$ffffffdf, $8(a4)
  00d68:  20 6e 00 08          movea.l  $8(a6), a0
  00d6c:  20 68 00 14          movea.l  $14(a0), a0
  00d70:  2f 10                move.l   (a0), -(a7)
  00d72:  61 ff 00 00 07 3c    bsr.l    $14b0
  00d78:  4a 80                tst.l    d0
  00d7a:  4f ef 00 0c          lea.l    $c(a7), a7
  00d7e:  67 0c                beq.b    $d8c
  00d80:  29 7c ff ff d8 da 01 7c move.l   #$ffffd8da, $17c(a4)
  00d88:  60 00 01 ea          bra.w    $f74
  00d8c:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00d90:  2f 0b                move.l   a3, -(a7)
  00d92:  61 ff 00 00 0f 48    bsr.l    $1cdc
  00d98:  4a 80                tst.l    d0
  00d9a:  50 4f                addq.w   #$8, a7
  00d9c:  67 16                beq.b    $db4
  00d9e:  29 7c ff ff d8 da 01 7c move.l   #$ffffd8da, $17c(a4)
  00da6:  2f 0b                move.l   a3, -(a7)
  00da8:  61 ff 00 00 06 8c    bsr.l    $1436
  00dae:  58 4f                addq.w   #$4, a7
  00db0:  60 00 01 c2          bra.w    $f74
  00db4:  2f 0b                move.l   a3, -(a7)
  00db6:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00dba:  61 ff 00 00 1d 16    bsr.l    $2ad2
  00dc0:  70 04                moveq    #$4, d0
  00dc2:  c0 ac 00 08          and.l    $8(a4), d0
  00dc6:  50 4f                addq.w   #$8, a7
  00dc8:  67 0c                beq.b    $dd6
  00dca:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00dce:  61 ff 00 00 1c 68    bsr.l    $2a38
  00dd4:  58 4f                addq.w   #$4, a7
  00dd6:  00 ac 00 00 00 20 00 08 ori.l    #$20, $8(a4)
  00dde:  70 00                moveq    #$0, d0
  00de0:  2f 00                move.l   d0, -(a7)
  00de2:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00de6:  20 6b 0a 7c          movea.l  $a7c(a3), a0
  00dea:  4e 90                jsr      (a0)
  00dec:  50 4f                addq.w   #$8, a7
  00dee:  60 00 01 7e          bra.w    $f6e
  00df2:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00df6:  2f 0b                move.l   a3, -(a7)
  00df8:  61 ff 00 00 0e e2    bsr.l    $1cdc
  00dfe:  2f 0b                move.l   a3, -(a7)
  00e00:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00e04:  61 ff 00 00 1c cc    bsr.l    $2ad2
  00e0a:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00e0e:  61 ff 00 00 1c 28    bsr.l    $2a38
  00e14:  4f ef 00 14          lea.l    $14(a7), a7
  00e18:  60 00 01 54          bra.w    $f6e
  00e1c:  20 0c                move.l   a4, d0
  00e1e:  67 00 01 5c          beq.w    $f7c
  00e22:  70 07                moveq    #$7, d0
  00e24:  c0 ac 00 08          and.l    $8(a4), d0
  00e28:  72 07                moveq    #$7, d1
  00e2a:  b2 80                cmp.l    d0, d1
  00e2c:  66 00 01 46          bne.w    $f74
  00e30:  20 3c 00 00 06 00    move.l   #$600, d0
  00e36:  c0 ac 00 08          and.l    $8(a4), d0
  00e3a:  66 00 01 38          bne.w    $f74
  00e3e:  70 20                moveq    #$20, d0
  00e40:  c0 ac 00 08          and.l    $8(a4), d0
  00e44:  66 00 01 28          bne.w    $f6e
  00e48:  a8 52                dc.w     $a852  ; _HideCursor
  00e4a:  20 6e 00 08          movea.l  $8(a6), a0
  00e4e:  20 68 00 14          movea.l  $14(a0), a0
  00e52:  2f 10                move.l   (a0), -(a7)
  00e54:  61 ff 00 00 06 5a    bsr.l    $14b0
  00e5a:  4a 80                tst.l    d0
  00e5c:  58 4f                addq.w   #$4, a7
  00e5e:  67 0e                beq.b    $e6e
  00e60:  29 7c ff ff d8 da 01 7c move.l   #$ffffd8da, $17c(a4)
  00e68:  a8 53                dc.w     $a853  ; _ShowCursor
  00e6a:  60 00 01 08          bra.w    $f74
  00e6e:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00e72:  2f 0b                move.l   a3, -(a7)
  00e74:  61 ff 00 00 0e 66    bsr.l    $1cdc
  00e7a:  4a 80                tst.l    d0
  00e7c:  50 4f                addq.w   #$8, a7
  00e7e:  67 18                beq.b    $e98
  00e80:  29 7c ff ff d8 da 01 7c move.l   #$ffffd8da, $17c(a4)
  00e88:  2f 0b                move.l   a3, -(a7)
  00e8a:  61 ff 00 00 05 aa    bsr.l    $1436
  00e90:  a8 53                dc.w     $a853  ; _ShowCursor
  00e92:  58 4f                addq.w   #$4, a7
  00e94:  60 00 00 de          bra.w    $f74
  00e98:  2f 0b                move.l   a3, -(a7)
  00e9a:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00e9e:  61 ff 00 00 1c 32    bsr.l    $2ad2
  00ea4:  70 04                moveq    #$4, d0
  00ea6:  c0 ac 00 08          and.l    $8(a4), d0
  00eaa:  50 4f                addq.w   #$8, a7
  00eac:  67 0c                beq.b    $eba
  00eae:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00eb2:  61 ff 00 00 1b 84    bsr.l    $2a38
  00eb8:  58 4f                addq.w   #$4, a7
  00eba:  00 ac 00 00 00 20 00 08 ori.l    #$20, $8(a4)
  00ec2:  70 00                moveq    #$0, d0
  00ec4:  2f 00                move.l   d0, -(a7)
  00ec6:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00eca:  20 6b 0a 7c          movea.l  $a7c(a3), a0
  00ece:  4e 90                jsr      (a0)
  00ed0:  a8 53                dc.w     $a853  ; _ShowCursor
  00ed2:  50 4f                addq.w   #$8, a7
  00ed4:  60 00 00 98          bra.w    $f6e
  00ed8:  20 0c                move.l   a4, d0
  00eda:  67 00 00 a0          beq.w    $f7c
  00ede:  70 20                moveq    #$20, d0
  00ee0:  c0 ac 00 08          and.l    $8(a4), d0
  00ee4:  67 00 00 88          beq.w    $f6e
  00ee8:  a8 52                dc.w     $a852  ; _HideCursor
  00eea:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00eee:  20 6b 0a 80          movea.l  $a80(a3), a0
  00ef2:  4e 90                jsr      (a0)
  00ef4:  2f 0b                move.l   a3, -(a7)
  00ef6:  61 ff 00 00 05 3e    bsr.l    $1436
  00efc:  02 ac ff ff ff df 00 08 andi.l   #$ffffffdf, $8(a4)
  00f04:  a8 53                dc.w     $a853  ; _ShowCursor
  00f06:  50 4f                addq.w   #$8, a7
  00f08:  60 64                bra.b    $f6e
  00f0a:  7a 00                moveq    #$0, d5
  00f0c:  3a 2c 00 02          move.w   $2(a4), d5
  00f10:  39 7c 07 d0 00 02    move.w   #$7d0, $2(a4)
  00f16:  48 6b 0a a0          pea.l    $aa0(a3)
  00f1a:  20 6e ff f4          movea.l  -$c(a6), a0
  00f1e:  2f 28 00 06          move.l   $6(a0), -(a7)
  00f22:  2f 28 00 02          move.l   $2(a0), -(a7)
  00f26:  20 6b 0a 84          movea.l  $a84(a3), a0
  00f2a:  4e 90                jsr      (a0)
  00f2c:  39 45 00 02          move.w   d5, $2(a4)
  00f30:  4f ef 00 0c          lea.l    $c(a7), a7
  00f34:  60 38                bra.b    $f6e
  00f36:  20 0c                move.l   a4, d0
  00f38:  67 42                beq.b    $f7c
  00f3a:  20 6e ff f4          movea.l  -$c(a6), a0
  00f3e:  39 68 00 04 00 02    move.w   $4(a0), $2(a4)
  00f44:  60 28                bra.b    $f6e
  00f46:  29 7c ff ff d8 da 01 7c move.l   #$ffffd8da, $17c(a4)
  00f4e:  60 24                bra.b    $f74
  00f50:  29 7c ff ff d8 da 01 7c move.l   #$ffffd8da, $17c(a4)
  00f58:  60 1a                bra.b    $f74
  00f5a:  29 7c ff ff d8 da 01 7c move.l   #$ffffd8da, $17c(a4)
  00f62:  60 10                bra.b    $f74
  00f64:  29 7c ff ff d8 da 01 7c move.l   #$ffffd8da, $17c(a4)
  00f6c:  60 06                bra.b    $f74
  00f6e:  42 6e 00 10          clr.w    $10(a6)
  00f72:  60 0e                bra.b    $f82
  00f74:  3d 7c ff ef 00 10    move.w   #$ffef, $10(a6)
  00f7a:  60 06                bra.b    $f82
  00f7c:  3d 7c ff ef 00 10    move.w   #$ffef, $10(a6)
  00f82:  4c ee 18 e0 ff d8    movem.l  -$28(a6), d5-d7/a3-a4
  00f88:  4e 5e                unlk     a6
  00f8a:  4e 74 00 08          rtd      #$8
  00f8e:  47 41                dc.b     $47,$41  ; GA
  00f90:  5f 44                subq.w   #$7, d4
  00f92:  72 76                moveq    #$76, d1
  00f94:  72 63                moveq    #$63, d1
  00f96:  6f 6e                ble.b    $1006
  00f98:  74 72                moveq    #$72, d2
  00f9a:  6f 6c                ble.b    $1008
  00f9c:  3a 20                move.w   -(a0), d5
  00f9e:  49                   dc.b     $49  ; I
  00f9f:  6e 69                bgt.b    $100a
  00fa1:  74 32                moveq    #$32, d2
  00fa3:  39 4b 20 65          move.w   a3, $2065(a4)
  00fa7:  72 72                moveq    #$72, d1
  00fa9:  6f 72                ble.b    $101d
  00fab:  00 47 41 5f          ori.w    #$415f, d7
  00faf:  44 52                neg.w    (a2)
  00fb1:  56 52                addq.w   #$3, (a2)
  00fb3:  63 6f                bls.b    $1024
  00fb5:  6e 74                bgt.b    $102b
  00fb7:  72 6f                moveq    #$6f, d1
  00fb9:  6c 3a                bge.b    $ff5
  00fbb:  20 6e 6f 20          movea.l  $6f20(a6), a0
  00fbf:  41 43 45             dc.b     $41,$43,$45  ; ACE
  00fc2:  46 20                not.b    -(a0)
  00fc4:  67 69                beq.b    $102f
  00fc6:  76 65                moveq    #$65, d3
  00fc8:  6e 20                bgt.b    $fea
  00fca:  66 6f                bne.b    $103b
  00fcc:  72 20                moveq    #$20, d1
  00fce:  69 6e                bvs.b    $103e
  00fd0:  69 74                bvs.b    $1046
  00fd2:  20 63                movea.l  -(a3), a0
  00fd4:  61 6c                bsr.b    $1042
  00fd6:  6c 00 4e 56          bge.w    $5e2e
  00fda:  00 00 42 6e          ori.b    #$6e, d0
  00fde:  00 10 4e 5e          ori.b    #$5e, (a0)
  00fe2:  4e 74 00 08          rtd      #$8
* ==================================================================
* InstallPatches
* ==================================================================
* Called once from DoOpen (A0=engine globals).  First clears a
* 128-entry (globals+$278, $80 slots) trap-patch table, then re-walks
* up to globals+$22C (a count field) *active* entries (16 bytes each,
* leading long = trap number, non-zero = in use).  For each: calls
* ClassifyTrapNum to normalise the trap number, then SetTrap to swap
* in this driver's replacement handler via _Get/SetToolTrapAddress or
* _Get/SetOSTrapAddress (selected by a flag byte) -- i.e. this is the
* actual **QuickDraw-bottleneck-patch installer** for the accelerator.
InstallPatches:
  00fe6:  4e 56 ff dc          link.w   a6, #$ffdc
  00fea:  48 e7 17 18          movem.l  d3/d5-d7/a3-a4, -(a7)
  00fee:  26 6e 00 08          movea.l  $8(a6), a3
  00ff2:  20 53                movea.l  (a3), a0
  00ff4:  42 28 02 57          clr.b    $257(a0)
  00ff8:  7e 00                moveq    #$0, d7
  00ffa:  20 53                movea.l  (a3), a0
  00ffc:  49 e8 02 78          lea.l    $278(a0), a4
  01000:  26 3c 00 00 00 80    move.l   #$80, d3
  01006:  60 0c                bra.b    $1014
  01008:  70 00                moveq    #$0, d0
  0100a:  28 80                move.l   d0, (a4)
  0100c:  20 07                move.l   d7, d0
  0100e:  52 87                addq.l   #$1, d7
  01010:  49 ec 00 10          lea.l    $10(a4), a4
  01014:  b6 87                cmp.l    d7, d3
  01016:  6e f0                bgt.b    $1008
  01018:  59 8f                subq.l   #$4, a7
  0101a:  2f 3c 67 63 32 34    move.l   #$67633234, -(a7)
  01020:  3f 3c f0 30          move.w   #$f030, -(a7)
  01024:  a8 1f                dc.w     $a81f  ; _Get1Resource
  01026:  2d 5f ff f8          move.l   (a7)+, -$8(a6)
  0102a:  66 14                bne.b    $1040
  0102c:  55 8f                subq.l   #$2, a7
  0102e:  a9 af                dc.w     $a9af  ; _ResError
  01030:  4a 5f                tst.w    (a7)+
  01032:  67 06                beq.b    $103a
  01034:  70 ff                moveq    #$ff, d0
  01036:  60 00 03 56          bra.w    $138e
  0103a:  70 ff                moveq    #$ff, d0
  0103c:  60 00 03 50          bra.w    $138e
  01040:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  01044:  a9 92                dc.w     $a992  ; _DetachResource
  01046:  20 6e ff f8          movea.l  -$8(a6), a0
  0104a:  a0 29                dc.w     $a029  ; _HLock
  0104c:  59 8f                subq.l   #$4, a7
  0104e:  20 6e ff f8          movea.l  -$8(a6), a0
  01052:  2f 10                move.l   (a0), -(a7)
  01054:  61 ff 00 00 37 9e    bsr.l    $47f4
  0105a:  2d 5f ff fc          move.l   (a7)+, -$4(a6)
  0105e:  7e 00                moveq    #$0, d7
  01060:  76 08                moveq    #$8, d3
  01062:  20 53                movea.l  (a3), a0
  01064:  41 e8 0a 78          lea.l    $a78(a0), a0
  01068:  70 00                moveq    #$0, d0
  0106a:  21 80 7c 00          move.l   d0, (a0, d7.l * 4)
  0106e:  20 07                move.l   d7, d0
  01070:  52 87                addq.l   #$1, d7
  01072:  b6 87                cmp.l    d7, d3
  01074:  6e ec                bgt.b    $1062
  01076:  20 6e ff fc          movea.l  -$4(a6), a0
  0107a:  2a 10                move.l   (a0), d5
  0107c:  6c 28                bge.b    $10a6
  0107e:  20 05                move.l   d5, d0
  01080:  44 80                neg.l    d0
  01082:  2c 00                move.l   d0, d6
  01084:  70 08                moveq    #$8, d0
  01086:  b0 86                cmp.l    d6, d0
  01088:  6d ec                blt.b    $1076
  0108a:  20 2e ff fc          move.l   -$4(a6), d0
  0108e:  72 28                moveq    #$28, d1
  01090:  d0 81                add.l    d1, d0
  01092:  20 53                movea.l  (a3), a0
  01094:  41 e8 0a 78          lea.l    $a78(a0), a0
  01098:  21 80 6c 00          move.l   d0, (a0, d6.l * 4)
  0109c:  06 ae 00 00 00 30 ff fc addi.l   #$30, -$4(a6)
  010a4:  60 d0                bra.b    $1076
  010a6:  4a 85                tst.l    d5
  010a8:  6f 3c                ble.b    $10e6
  010aa:  20 53                movea.l  (a3), a0
  010ac:  48 68 02 78          pea.l    $278(a0)
  010b0:  20 2e ff fc          move.l   -$4(a6), d0
  010b4:  58 80                addq.l   #$4, d0
  010b6:  2f 00                move.l   d0, -(a7)
  010b8:  20 2e ff fc          move.l   -$4(a6), d0
  010bc:  72 28                moveq    #$28, d1
  010be:  d0 81                add.l    d1, d0
  010c0:  2f 00                move.l   d0, -(a7)
  010c2:  2f 05                move.l   d5, -(a7)
  010c4:  61 ff 00 00 03 04    bsr.l    $13ca
  010ca:  20 53                movea.l  (a3), a0
  010cc:  31 40 02 2c          move.w   d0, $22c(a0)
  010d0:  4f ef 00 10          lea.l    $10(a7), a7
  010d4:  6c 06                bge.b    $10dc
  010d6:  70 ff                moveq    #$ff, d0
  010d8:  60 00 02 b4          bra.w    $138e
  010dc:  06 ae 00 00 00 30 ff fc addi.l   #$30, -$4(a6)
  010e4:  60 90                bra.b    $1076
  010e6:  20 6e ff fc          movea.l  -$4(a6), a0
  010ea:  4a a8 00 04          tst.l    $4(a0)
  010ee:  67 0c                beq.b    $10fc
  010f0:  06 ae 00 00 00 30 ff fc addi.l   #$30, -$4(a6)
  010f8:  60 00 ff 7c          bra.w    $1076
  010fc:  70 ff                moveq    #$ff, d0
  010fe:  b0 b8 0d 62          cmp.l    $d62.w, d0
  01102:  66 02                bne.b    $1106
  01104:  aa 1d                dc.w     $aa1d  ; _AllocCursor
  01106:  11 fc 00 01 08 cd    move.b   #$1, $8cd.w
  0110c:  a8 52                dc.w     $a852  ; _HideCursor
  0110e:  42 ae ff f0          clr.l    -$10(a6)
  01112:  42 ae ff ec          clr.l    -$14(a6)
  01116:  20 53                movea.l  (a3), a0
  01118:  49 e8 02 78          lea.l    $278(a0), a4
  0111c:  7e 00                moveq    #$0, d7
  0111e:  60 16                bra.b    $1136
  01120:  0c 94 00 00 06 44    cmpi.l   #$644, (a4)
  01126:  66 06                bne.b    $112e
  01128:  2d 6c 00 04 ff f4    move.l   $4(a4), -$c(a6)
  0112e:  20 07                move.l   d7, d0
  01130:  52 87                addq.l   #$1, d7
  01132:  49 ec 00 10          lea.l    $10(a4), a4
  01136:  20 53                movea.l  (a3), a0
  01138:  30 28 02 2c          move.w   $22c(a0), d0
  0113c:  48 c0                ext.l    d0
  0113e:  b0 87                cmp.l    d7, d0
  01140:  6e de                bgt.b    $1120
  01142:  2d 68 02 14 ff e8    move.l   $214(a0), -$18(a6)
  01148:  20 78 0d 62          movea.l  $d62.w, a0
  0114c:  2d 50 ff e0          move.l   (a0), -$20(a6)
  01150:  59 8f                subq.l   #$4, a7
  01152:  20 6e ff e0          movea.l  -$20(a6), a0
  01156:  20 68 00 12          movea.l  $12(a0), a0
  0115a:  2f 10                move.l   (a0), -(a7)
  0115c:  61 ff 00 00 36 96    bsr.l    $47f4
  01162:  2d 5f ff e4          move.l   (a7)+, -$1c(a6)
  01166:  20 53                movea.l  (a3), a0
  01168:  2d 68 0a 9c ff dc    move.l   $a9c(a0), -$24(a6)
  0116e:  70 08                moveq    #$8, d0
  01170:  2f 00                move.l   d0, -(a7)
  01172:  48 78 08 3c          pea.l    $83c.w
  01176:  2f 13                move.l   (a3), -(a7)
  01178:  61 ff 00 00 0b 7c    bsr.l    $1cf6
  0117e:  20 6e ff e8          movea.l  -$18(a6), a0
  01182:  20 50                movea.l  (a0), a0
  01184:  20 68 00 0c          movea.l  $c(a0), a0
  01188:  21 40 05 f8          move.l   d0, $5f8(a0)
  0118c:  70 01                moveq    #$1, d0
  0118e:  2f 00                move.l   d0, -(a7)
  01190:  48 78 08 cc          pea.l    $8cc.w
  01194:  2f 13                move.l   (a3), -(a7)
  01196:  61 ff 00 00 0b 5e    bsr.l    $1cf6
  0119c:  20 6e ff e8          movea.l  -$18(a6), a0
  011a0:  20 50                movea.l  (a0), a0
  011a2:  20 68 00 0c          movea.l  $c(a0), a0
  011a6:  21 40 05 fc          move.l   d0, $5fc(a0)
  011aa:  70 04                moveq    #$4, d0
  011ac:  2f 00                move.l   d0, -(a7)
  011ae:  48 78 08 9c          pea.l    $89c.w
  011b2:  2f 13                move.l   (a3), -(a7)
  011b4:  61 ff 00 00 0b 40    bsr.l    $1cf6
  011ba:  20 6e ff e8          movea.l  -$18(a6), a0
  011be:  20 50                movea.l  (a0), a0
  011c0:  20 68 00 0c          movea.l  $c(a0), a0
  011c4:  21 40 06 00          move.l   d0, $600(a0)
  011c8:  70 50                moveq    #$50, d0
  011ca:  2f 00                move.l   d0, -(a7)
  011cc:  2f 2e ff e0          move.l   -$20(a6), -(a7)
  011d0:  2f 13                move.l   (a3), -(a7)
  011d2:  61 ff 00 00 0b 22    bsr.l    $1cf6
  011d8:  20 6e ff e8          movea.l  -$18(a6), a0
  011dc:  20 50                movea.l  (a0), a0
  011de:  20 68 00 0c          movea.l  $c(a0), a0
  011e2:  21 40 01 e4          move.l   d0, $1e4(a0)
  011e6:  48 78 04 00          pea.l    $400.w
  011ea:  2f 2e ff e4          move.l   -$1c(a6), -(a7)
  011ee:  2f 13                move.l   (a3), -(a7)
  011f0:  61 ff 00 00 0b 04    bsr.l    $1cf6
  011f6:  20 6e ff e8          movea.l  -$18(a6), a0
  011fa:  20 50                movea.l  (a0), a0
  011fc:  20 68 00 0c          movea.l  $c(a0), a0
  01200:  21 40 01 e8          move.l   d0, $1e8(a0)
  01204:  21 ee ff dc 08 88    move.l   -$24(a6), $888.w
  0120a:  20 6e ff dc          movea.l  -$24(a6), a0
  0120e:  20 8b                move.l   a3, (a0)
  01210:  20 6e ff dc          movea.l  -$24(a6), a0
  01214:  21 6e ff e8 00 24    move.l   -$18(a6), $24(a0)
  0121a:  20 6e ff dc          movea.l  -$24(a6), a0
  0121e:  21 6e ff e4 00 04    move.l   -$1c(a6), $4(a0)
  01224:  20 6e ff e8          movea.l  -$18(a6), a0
  01228:  20 50                movea.l  (a0), a0
  0122a:  20 68 00 0c          movea.l  $c(a0), a0
  0122e:  41 e8 01 d4          lea.l    $1d4(a0), a0
  01232:  22 6e ff dc          movea.l  -$24(a6), a1
  01236:  23 48 00 08          move.l   a0, $8(a1)
  0123a:  20 6e ff e8          movea.l  -$18(a6), a0
  0123e:  20 50                movea.l  (a0), a0
  01240:  20 68 00 0c          movea.l  $c(a0), a0
  01244:  41 e8 01 d8          lea.l    $1d8(a0), a0
  01248:  22 6e ff dc          movea.l  -$24(a6), a1
  0124c:  23 48 00 0c          move.l   a0, $c(a1)
  01250:  20 6e ff e8          movea.l  -$18(a6), a0
  01254:  20 50                movea.l  (a0), a0
  01256:  20 68 00 0c          movea.l  $c(a0), a0
  0125a:  41 e8 01 dc          lea.l    $1dc(a0), a0
  0125e:  22 6e ff dc          movea.l  -$24(a6), a1
  01262:  23 48 00 10          move.l   a0, $10(a1)
  01266:  20 6e ff e8          movea.l  -$18(a6), a0
  0126a:  20 50                movea.l  (a0), a0
  0126c:  20 68 00 0c          movea.l  $c(a0), a0
  01270:  41 e8 01 30          lea.l    $130(a0), a0
  01274:  22 6e ff dc          movea.l  -$24(a6), a1
  01278:  23 48 00 1c          move.l   a0, $1c(a1)
  0127c:  20 6e ff dc          movea.l  -$24(a6), a0
  01280:  20 68 00 0c          movea.l  $c(a0), a0
  01284:  70 00                moveq    #$0, d0
  01286:  20 80                move.l   d0, (a0)
  01288:  20 6e ff dc          movea.l  -$24(a6), a0
  0128c:  20 68 00 08          movea.l  $8(a0), a0
  01290:  20 80                move.l   d0, (a0)
  01292:  20 6e ff dc          movea.l  -$24(a6), a0
  01296:  21 40 00 18          move.l   d0, $18(a0)
  0129a:  20 6e ff dc          movea.l  -$24(a6), a0
  0129e:  20 68 00 10          movea.l  $10(a0), a0
  012a2:  43 ee ff ec          lea.l    -$14(a6), a1
  012a6:  20 d9                move.l   (a1)+, (a0)+
  012a8:  20 d9                move.l   (a1)+, (a0)+
  012aa:  20 6e ff dc          movea.l  -$24(a6), a0
  012ae:  20 68 00 1c          movea.l  $1c(a0), a0
  012b2:  43 ee ff ec          lea.l    -$14(a6), a1
  012b6:  20 d9                move.l   (a1)+, (a0)+
  012b8:  20 d9                move.l   (a1)+, (a0)+
  012ba:  20 6e ff e8          movea.l  -$18(a6), a0
  012be:  20 50                movea.l  (a0), a0
  012c0:  20 68 00 0c          movea.l  $c(a0), a0
  012c4:  41 e8 01 ec          lea.l    $1ec(a0), a0
  012c8:  22 6e ff dc          movea.l  -$24(a6), a1
  012cc:  23 48 00 28          move.l   a0, $28(a1)
  012d0:  20 6e ff e8          movea.l  -$18(a6), a0
  012d4:  20 50                movea.l  (a0), a0
  012d6:  20 68 00 0c          movea.l  $c(a0), a0
  012da:  41 e8 01 f0          lea.l    $1f0(a0), a0
  012de:  22 6e ff dc          movea.l  -$24(a6), a1
  012e2:  23 48 00 2c          move.l   a0, $2c(a1)
  012e6:  20 6e ff e8          movea.l  -$18(a6), a0
  012ea:  20 50                movea.l  (a0), a0
  012ec:  20 68 00 0c          movea.l  $c(a0), a0
  012f0:  41 e8 05 f0          lea.l    $5f0(a0), a0
  012f4:  22 6e ff dc          movea.l  -$24(a6), a1
  012f8:  23 48 00 30          move.l   a0, $30(a1)
  012fc:  20 6e ff e8          movea.l  -$18(a6), a0
  01300:  20 50                movea.l  (a0), a0
  01302:  20 68 00 0c          movea.l  $c(a0), a0
  01306:  41 e8 05 f4          lea.l    $5f4(a0), a0
  0130a:  22 6e ff dc          movea.l  -$24(a6), a1
  0130e:  23 48 00 34          move.l   a0, $34(a1)
  01312:  20 6e ff dc          movea.l  -$24(a6), a0
  01316:  20 68 00 28          movea.l  $28(a0), a0
  0131a:  20 80                move.l   d0, (a0)
  0131c:  20 6e ff dc          movea.l  -$24(a6), a0
  01320:  21 6e ff f4 00 14    move.l   -$c(a6), $14(a0)
  01326:  20 6e ff dc          movea.l  -$24(a6), a0
  0132a:  21 7c 07 5b cd 15 00 20 move.l   #$75bcd15, $20(a0)
  01332:  42 38 08 cd          clr.b    $8cd.w
  01336:  a8 53                dc.w     $a853  ; _ShowCursor
  01338:  20 53                movea.l  (a3), a0
  0133a:  49 e8 02 78          lea.l    $278(a0), a4
  0133e:  7e 00                moveq    #$0, d7
  01340:  4f ef 00 3c          lea.l    $3c(a7), a7
  01344:  60 3a                bra.b    $1380
  01346:  4a 94                tst.l    (a4)
  01348:  67 2e                beq.b    $1378
  0134a:  20 53                movea.l  (a3), a0
  0134c:  21 ac 00 04 7c 14    move.l   $4(a4), $14(a0, d7.l)
  01352:  2f 14                move.l   (a4), -(a7)
  01354:  61 ff 00 00 00 42    bsr.l    $1398  ; -> ClassifyTrapNum
  0135a:  2c 00                move.l   d0, d6
  0135c:  58 4f                addq.w   #$4, a7
  0135e:  6f 12                ble.b    $1372
  01360:  2f 2c 00 0c          move.l   $c(a4), -(a7)
  01364:  3f 06                move.w   d6, -(a7)
  01366:  70 01                moveq    #$1, d0
  01368:  1f 00                move.b   d0, -(a7)
  0136a:  61 ff 00 00 32 1a    bsr.l    $4586  ; -> SetTrap
  01370:  60 06                bra.b    $1378
  01372:  20 54                movea.l  (a4), a0
  01374:  20 ac 00 0c          move.l   $c(a4), (a0)
  01378:  20 07                move.l   d7, d0
  0137a:  52 87                addq.l   #$1, d7
  0137c:  49 ec 00 10          lea.l    $10(a4), a4
  01380:  20 53                movea.l  (a3), a0
  01382:  30 28 02 2c          move.w   $22c(a0), d0
  01386:  48 c0                ext.l    d0
  01388:  b0 87                cmp.l    d7, d0
  0138a:  6e ba                bgt.b    $1346
  0138c:  70 00                moveq    #$0, d0
  0138e:  4c ee 18 e8 ff c4    movem.l  -$3c(a6), d3/d5-d7/a3-a4
  01394:  4e 5e                unlk     a6
  01396:  4e 75                rts      
* ClassifyTrapNum  -  normalise a raw trap number: two specific
* values collapse to the sentinel $FF, otherwise (trapNum-$E00)>>2.
ClassifyTrapNum:
  01398:  4e 56 00 00          link.w   a6, #$0
  0139c:  2f 07                move.l   d7, -(a7)
  0139e:  2e 2e 00 08          move.l   $8(a6), d7
  013a2:  20 07                move.l   d7, d0
  013a4:  04 80 00 00 08 04    subi.l   #$804, d0
  013aa:  67 08                beq.b    $13b4
  013ac:  04 80 00 00 00 10    subi.l   #$10, d0
  013b2:  66 04                bne.b    $13b8
  013b4:  70 ff                moveq    #$ff, d0
  013b6:  60 0a                bra.b    $13c2
  013b8:  20 07                move.l   d7, d0
  013ba:  90 bc 00 00 0e 00    sub.l    #$e00, d0
  013c0:  e4 80                asr.l    #$2, d0
  013c2:  2e 2e ff fc          move.l   -$4(a6), d7
  013c6:  4e 5e                unlk     a6
  013c8:  4e 75                rts      
  013ca:  4e 56 00 00          link.w   a6, #$0
  013ce:  48 e7 13 18          movem.l  d3/d6-d7/a3-a4, -(a7)
  013d2:  26 6e 00 08          movea.l  $8(a6), a3
  013d6:  28 6e 00 14          movea.l  $14(a6), a4
  013da:  7e 00                moveq    #$0, d7
  013dc:  4a 94                tst.l    (a4)
  013de:  66 3a                bne.b    $141a
  013e0:  28 8b                move.l   a3, (a4)
  013e2:  2f 0b                move.l   a3, -(a7)
  013e4:  61 ff ff ff ff b2    bsr.l    $1398  ; -> ClassifyTrapNum
  013ea:  2c 00                move.l   d0, d6
  013ec:  58 4f                addq.w   #$4, a7
  013ee:  6f 14                ble.b    $1404
  013f0:  59 8f                subq.l   #$4, a7
  013f2:  3f 06                move.w   d6, -(a7)
  013f4:  70 01                moveq    #$1, d0
  013f6:  1f 00                move.b   d0, -(a7)
  013f8:  61 ff 00 00 31 78    bsr.l    $4572  ; -> GetTrap
  013fe:  29 5f 00 04          move.l   (a7)+, $4(a4)
  01402:  60 04                bra.b    $1408
  01404:  29 53 00 04          move.l   (a3), $4(a4)
  01408:  29 6e 00 0c 00 08    move.l   $c(a6), $8(a4)
  0140e:  29 6e 00 10 00 0c    move.l   $10(a6), $c(a4)
  01414:  52 87                addq.l   #$1, d7
  01416:  20 07                move.l   d7, d0
  01418:  60 12                bra.b    $142c
  0141a:  20 07                move.l   d7, d0
  0141c:  52 87                addq.l   #$1, d7
  0141e:  49 ec 00 10          lea.l    $10(a4), a4
  01422:  0c 87 00 00 00 80    cmpi.l   #$80, d7
  01428:  6d b2                blt.b    $13dc
  0142a:  70 ff                moveq    #$ff, d0
  0142c:  4c ee 18 c8 ff ec    movem.l  -$14(a6), d3/d6-d7/a3-a4
  01432:  4e 5e                unlk     a6
  01434:  4e 75                rts      
  01436:  4e 56 ff fc          link.w   a6, #$fffc
  0143a:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  0143e:  26 6e 00 08          movea.l  $8(a6), a3
  01442:  49 eb 02 78          lea.l    $278(a3), a4
  01446:  2d 6b 0a 9c ff fc    move.l   $a9c(a3), -$4(a6)
  0144c:  42 2b 02 57          clr.b    $257(a3)
  01450:  7e 00                moveq    #$0, d7
  01452:  49 eb 02 78          lea.l    $278(a3), a4
  01456:  60 12                bra.b    $146a
  01458:  4a 94                tst.l    (a4)
  0145a:  67 06                beq.b    $1462
  0145c:  27 ac 00 04 7c 14    move.l   $4(a4), $14(a3, d7.l)
  01462:  20 07                move.l   d7, d0
  01464:  52 87                addq.l   #$1, d7
  01466:  49 ec 00 10          lea.l    $10(a4), a4
  0146a:  30 2b 02 2c          move.w   $22c(a3), d0
  0146e:  48 c0                ext.l    d0
  01470:  b0 87                cmp.l    d7, d0
  01472:  6e e4                bgt.b    $1458
  01474:  20 6e ff fc          movea.l  -$4(a6), a0
  01478:  20 68 00 28          movea.l  $28(a0), a0
  0147c:  2e 10                move.l   (a0), d7
  0147e:  67 24                beq.b    $14a4
  01480:  20 6e ff fc          movea.l  -$4(a6), a0
  01484:  20 68 00 2c          movea.l  $2c(a0), a0
  01488:  22 6e ff fc          movea.l  -$4(a6), a1
  0148c:  22 69 00 04          movea.l  $4(a1), a1
  01490:  20 07                move.l   d7, d0
  01492:  52 80                addq.l   #$1, d0
  01494:  e5 88                lsl.l    #$2, d0
  01496:  a0 2e                dc.w     $a02e  ; _BlockMove
  01498:  20 6e ff fc          movea.l  -$4(a6), a0
  0149c:  20 68 00 28          movea.l  $28(a0), a0
  014a0:  70 00                moveq    #$0, d0
  014a2:  20 80                move.l   d0, (a0)
  014a4:  70 00                moveq    #$0, d0
  014a6:  4c ee 18 80 ff f0    movem.l  -$10(a6), d7/a3-a4
  014ac:  4e 5e                unlk     a6
  014ae:  4e 75                rts      
  014b0:  4e 56 00 00          link.w   a6, #$0
  014b4:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  014b8:  26 6e 00 08          movea.l  $8(a6), a3
  014bc:  4a 2b 02 57          tst.b    $257(a3)
  014c0:  67 04                beq.b    $14c6
  014c2:  70 01                moveq    #$1, d0
  014c4:  60 2c                bra.b    $14f2
  014c6:  7e 00                moveq    #$0, d7
  014c8:  49 eb 02 78          lea.l    $278(a3), a4
  014cc:  60 12                bra.b    $14e0
  014ce:  4a 94                tst.l    (a4)
  014d0:  67 06                beq.b    $14d8
  014d2:  27 ac 00 08 7c 14    move.l   $8(a4), $14(a3, d7.l)
  014d8:  20 07                move.l   d7, d0
  014da:  52 87                addq.l   #$1, d7
  014dc:  49 ec 00 10          lea.l    $10(a4), a4
  014e0:  30 2b 02 2c          move.w   $22c(a3), d0
  014e4:  48 c0                ext.l    d0
  014e6:  b0 87                cmp.l    d7, d0
  014e8:  6e e4                bgt.b    $14ce
  014ea:  17 7c 00 01 02 57    move.b   #$1, $257(a3)
  014f0:  70 00                moveq    #$0, d0
  014f2:  4c ee 18 80 ff f4    movem.l  -$c(a6), d7/a3-a4
  014f8:  4e 5e                unlk     a6
  014fa:  4e 75                rts      
  014fc:  4e 56 ff 30          link.w   a6, #$ff30
  01500:  48 e7 1f 18          movem.l  d3-d7/a3-a4, -(a7)
  01504:  47 ee ff 7c          lea.l    -$84(a6), a3
  01508:  49 ee ff bc          lea.l    -$44(a6), a4
  0150c:  2e 2e 00 0c          move.l   $c(a6), d7
  01510:  20 6e 00 08          movea.l  $8(a6), a0
  01514:  42 28 02 54          clr.b    $254(a0)
  01518:  20 6e 00 08          movea.l  $8(a6), a0
  0151c:  42 28 02 58          clr.b    $258(a0)
  01520:  59 8f                subq.l   #$4, a7
  01522:  3f 3c a1 5c          move.w   #$a15c, -(a7)
  01526:  70 00                moveq    #$0, d0
  01528:  1f 00                move.b   d0, -(a7)
  0152a:  61 ff 00 00 30 46    bsr.l    $4572  ; -> GetTrap
  01530:  59 8f                subq.l   #$4, a7
  01532:  3f 3c a8 9f          move.w   #$a89f, -(a7)
  01536:  70 01                moveq    #$1, d0
  01538:  1f 00                move.b   d0, -(a7)
  0153a:  61 ff 00 00 30 36    bsr.l    $4572  ; -> GetTrap
  01540:  20 1f                move.l   (a7)+, d0
  01542:  b0 9f                cmp.l    (a7)+, d0
  01544:  67 0a                beq.b    $1550
  01546:  20 6e 00 08          movea.l  $8(a6), a0
  0154a:  11 7c 00 01 02 58    move.b   #$1, $258(a0)
  01550:  59 8f                subq.l   #$4, a7
  01552:  3f 3c 00 ad          move.w   #$ad, -(a7)
  01556:  70 00                moveq    #$0, d0
  01558:  1f 00                move.b   d0, -(a7)
  0155a:  61 ff 00 00 30 16    bsr.l    $4572  ; -> GetTrap
  01560:  59 8f                subq.l   #$4, a7
  01562:  3f 3c 00 9f          move.w   #$9f, -(a7)
  01566:  70 01                moveq    #$1, d0
  01568:  1f 00                move.b   d0, -(a7)
  0156a:  61 ff 00 00 30 06    bsr.l    $4572  ; -> GetTrap
  01570:  20 1f                move.l   (a7)+, d0
  01572:  b0 9f                cmp.l    (a7)+, d0
  01574:  67 00 00 8e          beq.w    $1604
  01578:  55 8f                subq.l   #$2, a7
  0157a:  2f 3c 76 6d 20 20    move.l   #$766d2020, -(a7)
  01580:  48 6e ff fc          pea.l    -$4(a6)
  01584:  61 ff 00 00 30 60    bsr.l    $45e6
  0158a:  4a 5f                tst.w    (a7)+
  0158c:  66 08                bne.b    $1596
  0158e:  4a ae ff fc          tst.l    -$4(a6)
  01592:  66 00 00 b2          bne.w    $1646
  01596:  20 07                move.l   d7, d0
  01598:  58 80                addq.l   #$4, d0
  0159a:  a1 1e                dc.w     $a11e  ; _NewPtr
  0159c:  22 6e 00 08          movea.l  $8(a6), a1
  015a0:  23 48 02 30          move.l   a0, $230(a1)
  015a4:  20 08                move.l   a0, d0
  015a6:  66 06                bne.b    $15ae
  015a8:  70 ff                moveq    #$ff, d0
  015aa:  60 00 02 c0          bra.w    $186c
  015ae:  20 6e 00 08          movea.l  $8(a6), a0
  015b2:  20 28 02 30          move.l   $230(a0), d0
  015b6:  56 80                addq.l   #$3, d0
  015b8:  72 fc                moveq    #$fc, d1
  015ba:  c2 80                and.l    d0, d1
  015bc:  21 41 02 34          move.l   d1, $234(a0)
  015c0:  20 6e 00 08          movea.l  $8(a6), a0
  015c4:  21 47 02 38          move.l   d7, $238(a0)
  015c8:  20 6e 00 08          movea.l  $8(a6), a0
  015cc:  28 28 02 34          move.l   $234(a0), d4
  015d0:  2a 04                move.l   d4, d5
  015d2:  4a 28 02 58          tst.b    $258(a0)
  015d6:  67 14                beq.b    $15ec
  015d8:  70 01                moveq    #$1, d0
  015da:  2f 00                move.l   d0, -(a7)
  015dc:  2f 04                move.l   d4, -(a7)
  015de:  2f 08                move.l   a0, -(a7)
  015e0:  61 ff 00 00 07 14    bsr.l    $1cf6
  015e6:  2a 00                move.l   d0, d5
  015e8:  4f ef 00 0c          lea.l    $c(a7), a7
  015ec:  b8 85                cmp.l    d5, d4
  015ee:  67 04                beq.b    $15f4
  015f0:  20 05                move.l   d5, d0
  015f2:  60 02                bra.b    $15f6
  015f4:  70 ff                moveq    #$ff, d0
  015f6:  20 6e 00 08          movea.l  $8(a6), a0
  015fa:  21 40 02 3c          move.l   d0, $23c(a0)
  015fe:  70 00                moveq    #$0, d0
  01600:  60 00 02 6a          bra.w    $186c
  01604:  20 07                move.l   d7, d0
  01606:  58 80                addq.l   #$4, d0
  01608:  a1 1e                dc.w     $a11e  ; _NewPtr
  0160a:  22 6e 00 08          movea.l  $8(a6), a1
  0160e:  23 48 02 30          move.l   a0, $230(a1)
  01612:  20 08                move.l   a0, d0
  01614:  66 06                bne.b    $161c
  01616:  70 ff                moveq    #$ff, d0
  01618:  60 00 02 52          bra.w    $186c
  0161c:  20 6e 00 08          movea.l  $8(a6), a0
  01620:  20 28 02 30          move.l   $230(a0), d0
  01624:  56 80                addq.l   #$3, d0
  01626:  72 fc                moveq    #$fc, d1
  01628:  c2 80                and.l    d0, d1
  0162a:  21 41 02 34          move.l   d1, $234(a0)
  0162e:  20 6e 00 08          movea.l  $8(a6), a0
  01632:  21 47 02 38          move.l   d7, $238(a0)
  01636:  20 6e 00 08          movea.l  $8(a6), a0
  0163a:  70 ff                moveq    #$ff, d0
  0163c:  21 40 02 3c          move.l   d0, $23c(a0)
  01640:  70 00                moveq    #$0, d0
  01642:  60 00 02 28          bra.w    $186c
  01646:  20 6e 00 08          movea.l  $8(a6), a0
  0164a:  11 7c 00 01 02 54    move.b   #$1, $254(a0)
  01650:  20 6e 00 08          movea.l  $8(a6), a0
  01654:  70 00                moveq    #$0, d0
  01656:  21 40 02 38          move.l   d0, $238(a0)
  0165a:  2d 40 ff fc          move.l   d0, -$4(a6)
  0165e:  20 07                move.l   d7, d0
  01660:  58 80                addq.l   #$4, d0
  01662:  a1 1e                dc.w     $a11e  ; _NewPtr
  01664:  30 2e ff fe          move.w   -$2(a6), d0
  01668:  27 88 04 00          move.l   a0, (a3, d0.w * 4)
  0166c:  20 08                move.l   a0, d0
  0166e:  66 2c                bne.b    $169c
  01670:  60 1a                bra.b    $168c
  01672:  30 2e ff fe          move.w   -$2(a6), d0
  01676:  20 74 04 00          movea.l  (a4, d0.w * 4), a0
  0167a:  22 47                movea.l  d7, a1
  0167c:  70 03                moveq    #$3, d0
  0167e:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  01680:  4a 40                tst.w    d0
  01682:  30 2e ff fe          move.w   -$2(a6), d0
  01686:  20 73 04 00          movea.l  (a3, d0.w * 4), a0
  0168a:  a0 1f                dc.w     $a01f  ; _DisposPtr
  0168c:  53 ae ff fc          subq.l   #$1, -$4(a6)
  01690:  4a ae ff fc          tst.l    -$4(a6)
  01694:  6c dc                bge.b    $1672
  01696:  70 ff                moveq    #$ff, d0
  01698:  60 00 01 d2          bra.w    $186c
  0169c:  30 2e ff fe          move.w   -$2(a6), d0
  016a0:  20 33 04 00          move.l   (a3, d0.w * 4), d0
  016a4:  56 80                addq.l   #$3, d0
  016a6:  72 fc                moveq    #$fc, d1
  016a8:  c2 80                and.l    d0, d1
  016aa:  30 2e ff fe          move.w   -$2(a6), d0
  016ae:  29 81 04 00          move.l   d1, (a4, d0.w * 4)
  016b2:  30 2e ff fe          move.w   -$2(a6), d0
  016b6:  2d 74 04 00 ff 30    move.l   (a4, d0.w * 4), -$d0(a6)
  016bc:  2d 47 ff 34          move.l   d7, -$cc(a6)
  016c0:  61 ff 00 00 2f 1c    bsr.l    $45de
  016c6:  20 6e ff 30          movea.l  -$d0(a6), a0
  016ca:  22 6e ff 34          movea.l  -$cc(a6), a1
  016ce:  70 00                moveq    #$0, d0
  016d0:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  016d2:  48 c0                ext.l    d0
  016d4:  2c 00                move.l   d0, d6
  016d6:  67 2c                beq.b    $1704
  016d8:  60 1a                bra.b    $16f4
  016da:  30 2e ff fe          move.w   -$2(a6), d0
  016de:  20 74 04 00          movea.l  (a4, d0.w * 4), a0
  016e2:  22 47                movea.l  d7, a1
  016e4:  70 01                moveq    #$1, d0
  016e6:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  016e8:  4a 40                tst.w    d0
  016ea:  30 2e ff fe          move.w   -$2(a6), d0
  016ee:  20 73 04 00          movea.l  (a3, d0.w * 4), a0
  016f2:  a0 1f                dc.w     $a01f  ; _DisposPtr
  016f4:  53 ae ff fc          subq.l   #$1, -$4(a6)
  016f8:  4a ae ff fc          tst.l    -$4(a6)
  016fc:  6c dc                bge.b    $16da
  016fe:  20 06                move.l   d6, d0
  01700:  60 00 01 6a          bra.w    $186c
  01704:  20 6e ff 30          movea.l  -$d0(a6), a0
  01708:  22 6e ff 34          movea.l  -$cc(a6), a1
  0170c:  70 02                moveq    #$2, d0
  0170e:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  01710:  48 c0                ext.l    d0
  01712:  2c 00                move.l   d0, d6
  01714:  67 3c                beq.b    $1752
  01716:  60 2a                bra.b    $1742
  01718:  30 2e ff fe          move.w   -$2(a6), d0
  0171c:  20 74 04 00          movea.l  (a4, d0.w * 4), a0
  01720:  22 47                movea.l  d7, a1
  01722:  70 01                moveq    #$1, d0
  01724:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  01726:  4a 40                tst.w    d0
  01728:  30 2e ff fe          move.w   -$2(a6), d0
  0172c:  20 74 04 00          movea.l  (a4, d0.w * 4), a0
  01730:  22 47                movea.l  d7, a1
  01732:  70 03                moveq    #$3, d0
  01734:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  01736:  4a 40                tst.w    d0
  01738:  30 2e ff fe          move.w   -$2(a6), d0
  0173c:  20 73 04 00          movea.l  (a3, d0.w * 4), a0
  01740:  a0 1f                dc.w     $a01f  ; _DisposPtr
  01742:  53 ae ff fc          subq.l   #$1, -$4(a6)
  01746:  4a ae ff fc          tst.l    -$4(a6)
  0174a:  6c cc                bge.b    $1718
  0174c:  20 06                move.l   d6, d0
  0174e:  60 00 01 1c          bra.w    $186c
  01752:  70 01                moveq    #$1, d0
  01754:  2d 40 ff 78          move.l   d0, -$88(a6)
  01758:  32 2e ff fe          move.w   -$2(a6), d1
  0175c:  20 6e 00 08          movea.l  $8(a6), a0
  01760:  21 73 14 00 02 30    move.l   (a3, d1.w * 4), $230(a0)
  01766:  32 2e ff fe          move.w   -$2(a6), d1
  0176a:  20 6e 00 08          movea.l  $8(a6), a0
  0176e:  21 74 14 00 02 34    move.l   (a4, d1.w * 4), $234(a0)
  01774:  55 8f                subq.l   #$2, a7
  01776:  48 6e ff 30          pea.l    -$d0(a6)
  0177a:  48 6e ff 78          pea.l    -$88(a6)
  0177e:  61 ff 00 00 30 8e    bsr.l    $480e
  01784:  30 1f                move.w   (a7)+, d0
  01786:  48 c0                ext.l    d0
  01788:  2c 00                move.l   d0, d6
  0178a:  66 00 00 88          bne.w    $1814
  0178e:  70 01                moveq    #$1, d0
  01790:  b0 ae ff 78          cmp.l    -$88(a6), d0
  01794:  65 00 00 8c          bcs.w    $1822
  01798:  20 6e 00 08          movea.l  $8(a6), a0
  0179c:  21 6e ff 38 02 3c    move.l   -$c8(a6), $23c(a0)
  017a2:  20 6e 00 08          movea.l  $8(a6), a0
  017a6:  21 47 02 38          move.l   d7, $238(a0)
  017aa:  53 ae ff fc          subq.l   #$1, -$4(a6)
  017ae:  60 2a                bra.b    $17da
  017b0:  30 2e ff fe          move.w   -$2(a6), d0
  017b4:  20 74 04 00          movea.l  (a4, d0.w * 4), a0
  017b8:  22 47                movea.l  d7, a1
  017ba:  70 01                moveq    #$1, d0
  017bc:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  017be:  4a 40                tst.w    d0
  017c0:  30 2e ff fe          move.w   -$2(a6), d0
  017c4:  20 74 04 00          movea.l  (a4, d0.w * 4), a0
  017c8:  22 47                movea.l  d7, a1
  017ca:  70 03                moveq    #$3, d0
  017cc:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  017ce:  4a 40                tst.w    d0
  017d0:  30 2e ff fe          move.w   -$2(a6), d0
  017d4:  20 73 04 00          movea.l  (a3, d0.w * 4), a0
  017d8:  a0 1f                dc.w     $a01f  ; _DisposPtr
  017da:  53 ae ff fc          subq.l   #$1, -$4(a6)
  017de:  4a ae ff fc          tst.l    -$4(a6)
  017e2:  6c cc                bge.b    $17b0
  017e4:  70 00                moveq    #$0, d0
  017e6:  60 00 00 84          bra.w    $186c
  017ea:  30 2e ff fe          move.w   -$2(a6), d0
  017ee:  20 74 04 00          movea.l  (a4, d0.w * 4), a0
  017f2:  22 47                movea.l  d7, a1
  017f4:  70 01                moveq    #$1, d0
  017f6:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  017f8:  4a 40                tst.w    d0
  017fa:  30 2e ff fe          move.w   -$2(a6), d0
  017fe:  20 74 04 00          movea.l  (a4, d0.w * 4), a0
  01802:  22 47                movea.l  d7, a1
  01804:  70 03                moveq    #$3, d0
  01806:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  01808:  4a 40                tst.w    d0
  0180a:  30 2e ff fe          move.w   -$2(a6), d0
  0180e:  20 73 04 00          movea.l  (a3, d0.w * 4), a0
  01812:  a0 1f                dc.w     $a01f  ; _DisposPtr
  01814:  53 ae ff fc          subq.l   #$1, -$4(a6)
  01818:  4a ae ff fc          tst.l    -$4(a6)
  0181c:  6c cc                bge.b    $17ea
  0181e:  20 06                move.l   d6, d0
  01820:  60 4a                bra.b    $186c
  01822:  20 2e ff fc          move.l   -$4(a6), d0
  01826:  52 ae ff fc          addq.l   #$1, -$4(a6)
  0182a:  70 10                moveq    #$10, d0
  0182c:  b0 ae ff fc          cmp.l    -$4(a6), d0
  01830:  6e 00 fe 2c          bgt.w    $165e
  01834:  60 2a                bra.b    $1860
  01836:  30 2e ff fe          move.w   -$2(a6), d0
  0183a:  20 74 04 00          movea.l  (a4, d0.w * 4), a0
  0183e:  22 47                movea.l  d7, a1
  01840:  70 01                moveq    #$1, d0
  01842:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  01844:  4a 40                tst.w    d0
  01846:  30 2e ff fe          move.w   -$2(a6), d0
  0184a:  20 74 04 00          movea.l  (a4, d0.w * 4), a0
  0184e:  22 47                movea.l  d7, a1
  01850:  70 03                moveq    #$3, d0
  01852:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  01854:  4a 40                tst.w    d0
  01856:  30 2e ff fe          move.w   -$2(a6), d0
  0185a:  20 73 04 00          movea.l  (a3, d0.w * 4), a0
  0185e:  a0 1f                dc.w     $a01f  ; _DisposPtr
  01860:  53 ae ff fc          subq.l   #$1, -$4(a6)
  01864:  4a ae ff fc          tst.l    -$4(a6)
  01868:  6c cc                bge.b    $1836
  0186a:  70 ff                moveq    #$ff, d0
  0186c:  4c ee 18 f8 ff 14    movem.l  -$ec(a6), d3-d7/a3-a4
  01872:  4e 5e                unlk     a6
  01874:  4e 75                rts      
  01876:  4e 56 00 00          link.w   a6, #$0
  0187a:  2f 0c                move.l   a4, -(a7)
  0187c:  28 6e 00 08          movea.l  $8(a6), a4
  01880:  70 ff                moveq    #$ff, d0
  01882:  b0 ac 02 3c          cmp.l    $23c(a4), d0
  01886:  67 18                beq.b    $18a0
  01888:  20 6c 02 34          movea.l  $234(a4), a0
  0188c:  22 6c 02 38          movea.l  $238(a4), a1
  01890:  70 01                moveq    #$1, d0
  01892:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  01894:  20 6c 02 34          movea.l  $234(a4), a0
  01898:  22 6c 02 38          movea.l  $238(a4), a1
  0189c:  70 03                moveq    #$3, d0
  0189e:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  018a0:  20 6c 02 30          movea.l  $230(a4), a0
  018a4:  a0 1f                dc.w     $a01f  ; _DisposPtr
  018a6:  28 6e ff fc          movea.l  -$4(a6), a4
  018aa:  4e 5e                unlk     a6
  018ac:  4e 75                rts      
  018ae:  4e 56 00 00          link.w   a6, #$0
  018b2:  48 e7 00 18          movem.l  a3-a4, -(a7)
  018b6:  26 6e 00 08          movea.l  $8(a6), a3
  018ba:  28 6e 00 0c          movea.l  $c(a6), a4
  018be:  60 02                bra.b    $18c2
  018c0:  16 dc                move.b   (a4)+, (a3)+
  018c2:  4a 14                tst.b    (a4)
  018c4:  66 fa                bne.b    $18c0
  018c6:  42 13                clr.b    (a3)
  018c8:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  018ce:  4e 5e                unlk     a6
  018d0:  4e 75                rts      
  018d2:  4e 56 ff fc          link.w   a6, #$fffc
  018d6:  55 8f                subq.l   #$2, a7
  018d8:  2f 3c 76 6d 20 20    move.l   #$766d2020, -(a7)
  018de:  48 6e ff fc          pea.l    -$4(a6)
  018e2:  61 ff 00 00 2d 02    bsr.l    $45e6
  018e8:  4a 5f                tst.w    (a7)+
  018ea:  66 5e                bne.b    $194a
  018ec:  4a ae ff fc          tst.l    -$4(a6)
  018f0:  67 58                beq.b    $194a
  018f2:  55 8f                subq.l   #$2, a7
  018f4:  2f 3c 62 75 67 7a    move.l   #$6275677a, -(a7)
  018fa:  48 6e ff fc          pea.l    -$4(a6)
  018fe:  61 ff 00 00 2c e6    bsr.l    $45e6
  01904:  4a 5f                tst.w    (a7)+
  01906:  66 0c                bne.b    $1914
  01908:  20 3c 00 00 04 00    move.l   #$400, d0
  0190e:  c0 ae ff fc          and.l    -$4(a6), d0
  01912:  66 36                bne.b    $194a
  01914:  55 8f                subq.l   #$2, a7
  01916:  2f 3c 73 79 73 76    move.l   #$73797376, -(a7)
  0191c:  48 6e ff fc          pea.l    -$4(a6)
  01920:  61 ff 00 00 2c c4    bsr.l    $45e6
  01926:  4a 5f                tst.w    (a7)+
  01928:  66 20                bne.b    $194a
  0192a:  0c ae 00 00 07 00 ff fc cmpi.l   #$700, -$4(a6)
  01932:  66 0c                bne.b    $1940
  01934:  20 78 0b 78          movea.l  $b78.w, a0
  01938:  21 78 08 ee 00 78    move.l   $8ee.w, $78(a0)
  0193e:  60 0a                bra.b    $194a
  01940:  20 78 0b 78          movea.l  $b78.w, a0
  01944:  21 78 08 ee 00 d0    move.l   $8ee.w, $d0(a0)
  0194a:  4e 5e                unlk     a6
  0194c:  4e 75                rts      
  0194e:  4e 56 ff fc          link.w   a6, #$fffc
  01952:  59 8f                subq.l   #$4, a7
  01954:  3f 3c 00 ad          move.w   #$ad, -(a7)
  01958:  70 00                moveq    #$0, d0
  0195a:  1f 00                move.b   d0, -(a7)
  0195c:  61 ff 00 00 2c 14    bsr.l    $4572  ; -> GetTrap
  01962:  59 8f                subq.l   #$4, a7
  01964:  3f 3c 00 9f          move.w   #$9f, -(a7)
  01968:  70 01                moveq    #$1, d0
  0196a:  1f 00                move.b   d0, -(a7)
  0196c:  61 ff 00 00 2c 04    bsr.l    $4572  ; -> GetTrap
  01972:  20 1f                move.l   (a7)+, d0
  01974:  b0 9f                cmp.l    (a7)+, d0
  01976:  66 0a                bne.b    $1982
  01978:  20 3c ff ff d8 ef    move.l   #$ffffd8ef, d0
  0197e:  60 00 01 26          bra.w    $1aa6
  01982:  55 8f                subq.l   #$2, a7
  01984:  2f 3c 70 72 6f 63    move.l   #$70726f63, -(a7)
  0198a:  48 6e ff fc          pea.l    -$4(a6)
  0198e:  61 ff 00 00 2c 56    bsr.l    $45e6
  01994:  4a 5f                tst.w    (a7)+
  01996:  66 12                bne.b    $19aa
  01998:  70 05                moveq    #$5, d0
  0199a:  b0 ae ff fc          cmp.l    -$4(a6), d0
  0199e:  66 0a                bne.b    $19aa
  019a0:  20 3c ff ff d8 e4    move.l   #$ffffd8e4, d0
  019a6:  60 00 00 fe          bra.w    $1aa6
  019aa:  55 8f                subq.l   #$2, a7
  019ac:  2f 3c 6d 61 63 68    move.l   #$6d616368, -(a7)
  019b2:  48 6e ff fc          pea.l    -$4(a6)
  019b6:  61 ff 00 00 2c 2e    bsr.l    $45e6
  019bc:  4a 5f                tst.w    (a7)+
  019be:  66 3a                bne.b    $19fa
  019c0:  70 06                moveq    #$6, d0
  019c2:  b0 ae ff fc          cmp.l    -$4(a6), d0
  019c6:  6e 28                bgt.b    $19f0
  019c8:  70 11                moveq    #$11, d0
  019ca:  b0 ae ff fc          cmp.l    -$4(a6), d0
  019ce:  67 20                beq.b    $19f0
  019d0:  70 17                moveq    #$17, d0
  019d2:  b0 ae ff fc          cmp.l    -$4(a6), d0
  019d6:  67 18                beq.b    $19f0
  019d8:  70 15                moveq    #$15, d0
  019da:  b0 ae ff fc          cmp.l    -$4(a6), d0
  019de:  67 10                beq.b    $19f0
  019e0:  70 18                moveq    #$18, d0
  019e2:  b0 ae ff fc          cmp.l    -$4(a6), d0
  019e6:  67 08                beq.b    $19f0
  019e8:  70 19                moveq    #$19, d0
  019ea:  b0 ae ff fc          cmp.l    -$4(a6), d0
  019ee:  66 0a                bne.b    $19fa
  019f0:  20 3c ff ff d8 eb    move.l   #$ffffd8eb, d0
  019f6:  60 00 00 ae          bra.w    $1aa6
  019fa:  55 8f                subq.l   #$2, a7
  019fc:  2f 3c 73 79 73 76    move.l   #$73797376, -(a7)
  01a02:  48 6e ff fc          pea.l    -$4(a6)
  01a06:  61 ff 00 00 2b de    bsr.l    $45e6
  01a0c:  4a 5f                tst.w    (a7)+
  01a0e:  66 14                bne.b    $1a24
  01a10:  0c ae 00 00 07 00 ff fc cmpi.l   #$700, -$4(a6)
  01a18:  6c 0a                bge.b    $1a24
  01a1a:  20 3c ff ff d8 ef    move.l   #$ffffd8ef, d0
  01a20:  60 00 00 84          bra.w    $1aa6
  01a24:  55 8f                subq.l   #$2, a7
  01a26:  2f 3c 72 61 6d 20    move.l   #$72616d20, -(a7)
  01a2c:  48 6e ff fc          pea.l    -$4(a6)
  01a30:  61 ff 00 00 2b b4    bsr.l    $45e6
  01a36:  4a 5f                tst.w    (a7)+
  01a38:  66 1c                bne.b    $1a56
  01a3a:  20 2e ff fc          move.l   -$4(a6), d0
  01a3e:  4c 7c 08 00 00 00 04 00 divs.l   #$400, d0
  01a46:  0c 80 00 00 08 00    cmpi.l   #$800, d0
  01a4c:  6e 08                bgt.b    $1a56
  01a4e:  20 3c ff ff d8 ec    move.l   #$ffffd8ec, d0
  01a54:  60 50                bra.b    $1aa6
  01a56:  55 8f                subq.l   #$2, a7
  01a58:  2f 3c 71 64 20 20    move.l   #$71642020, -(a7)
  01a5e:  48 6e ff fc          pea.l    -$4(a6)
  01a62:  61 ff 00 00 2b 82    bsr.l    $45e6
  01a68:  4a 5f                tst.w    (a7)+
  01a6a:  66 38                bne.b    $1aa4
  01a6c:  0c ae 00 00 02 00 ff fc cmpi.l   #$200, -$4(a6)
  01a74:  6c 2e                bge.b    $1aa4
  01a76:  59 8f                subq.l   #$4, a7
  01a78:  3f 3c ab 03          move.w   #$ab03, -(a7)
  01a7c:  70 01                moveq    #$1, d0
  01a7e:  1f 00                move.b   d0, -(a7)
  01a80:  61 ff 00 00 2a f0    bsr.l    $4572  ; -> GetTrap
  01a86:  59 8f                subq.l   #$4, a7
  01a88:  3f 3c a8 9f          move.w   #$a89f, -(a7)
  01a8c:  70 01                moveq    #$1, d0
  01a8e:  1f 00                move.b   d0, -(a7)
  01a90:  61 ff 00 00 2a e0    bsr.l    $4572  ; -> GetTrap
  01a96:  20 1f                move.l   (a7)+, d0
  01a98:  b0 9f                cmp.l    (a7)+, d0
  01a9a:  66 08                bne.b    $1aa4
  01a9c:  20 3c ff ff d8 ee    move.l   #$ffffd8ee, d0
  01aa2:  60 02                bra.b    $1aa6
  01aa4:  70 00                moveq    #$0, d0
  01aa6:  4e 5e                unlk     a6
  01aa8:  4e 75                rts      
  01aaa:  4e 56 ff c8          link.w   a6, #$ffc8
  01aae:  48 e7 03 08          movem.l  d6-d7/a4, -(a7)
  01ab2:  2c 2e 00 0c          move.l   $c(a6), d6
  01ab6:  2e 2e 00 08          move.l   $8(a6), d7
  01aba:  70 7e                moveq    #$7e, d0
  01abc:  b0 87                cmp.l    d7, d0
  01abe:  67 08                beq.b    $1ac8
  01ac0:  70 2c                moveq    #$2c, d0
  01ac2:  b0 87                cmp.l    d7, d0
  01ac4:  66 00 01 1a          bne.w    $1be0
  01ac8:  1d 46 ff f9          move.b   d6, -$7(a6)
  01acc:  42 2e ff fa          clr.b    -$6(a6)
  01ad0:  3d 7c 00 01 ff f0    move.w   #$1, -$10(a6)
  01ad6:  42 6e ff f2          clr.w    -$e(a6)
  01ada:  1d 7c 00 03 ff f8    move.b   #$3, -$8(a6)
  01ae0:  41 ee ff c8          lea.l    -$38(a6), a0
  01ae4:  70 15                moveq    #$15, d0
  01ae6:  a0 6e                dc.w     $a06e  ; _SlotManager
  01ae8:  4a 40                tst.w    d0
  01aea:  67 06                beq.b    $1af2
  01aec:  70 ff                moveq    #$ff, d0
  01aee:  60 00 00 f2          bra.w    $1be2
  01af2:  1d 7c 00 20 ff fa    move.b   #$20, -$6(a6)
  01af8:  41 ee ff c8          lea.l    -$38(a6), a0
  01afc:  70 01                moveq    #$1, d0
  01afe:  a0 6e                dc.w     $a06e  ; _SlotManager
  01b00:  4a 40                tst.w    d0
  01b02:  67 06                beq.b    $1b0a
  01b04:  70 ff                moveq    #$ff, d0
  01b06:  60 00 00 da          bra.w    $1be2
  01b0a:  30 2e ff ca          move.w   -$36(a6), d0
  01b0e:  48 c0                ext.l    d0
  01b10:  b0 87                cmp.l    d7, d0
  01b12:  66 00 00 c8          bne.w    $1bdc
  01b16:  1d 7c 00 24 ff fa    move.b   #$24, -$6(a6)
  01b1c:  41 ee ff c8          lea.l    -$38(a6), a0
  01b20:  70 06                moveq    #$6, d0
  01b22:  a0 6e                dc.w     $a06e  ; _SlotManager
  01b24:  48 c0                ext.l    d0
  01b26:  2e 00                move.l   d0, d7
  01b28:  67 06                beq.b    $1b30
  01b2a:  70 ff                moveq    #$ff, d0
  01b2c:  60 00 00 b4          bra.w    $1be2
  01b30:  1d 46 ff f9          move.b   d6, -$7(a6)
  01b34:  1d 7c 00 03 ff fa    move.b   #$3, -$6(a6)
  01b3a:  41 ee ff c8          lea.l    -$38(a6), a0
  01b3e:  70 03                moveq    #$3, d0
  01b40:  a0 6e                dc.w     $a06e  ; _SlotManager
  01b42:  48 c0                ext.l    d0
  01b44:  2e 00                move.l   d0, d7
  01b46:  67 06                beq.b    $1b4e
  01b48:  70 ff                moveq    #$ff, d0
  01b4a:  60 00 00 96          bra.w    $1be2
  01b4e:  28 6e ff c8          movea.l  -$38(a6), a4
  01b52:  70 20                moveq    #$20, d0
  01b54:  2f 00                move.l   d0, -(a7)
  01b56:  2f 0c                move.l   a4, -(a7)
  01b58:  61 ff 00 00 14 ae    bsr.l    $3008
  01b5e:  52 80                addq.l   #$1, d0
  01b60:  50 8f                addq.l   #$8, a7
  01b62:  2f 00                move.l   d0, -(a7)
  01b64:  61 ff 00 00 01 14    bsr.l    $1c7a
  01b6a:  20 6e 00 14          movea.l  $14(a6), a0
  01b6e:  20 80                move.l   d0, (a0)
  01b70:  10 1c                move.b   (a4)+, d0
  01b72:  48 80                ext.w    d0
  01b74:  90 7c 00 30          sub.w    #$30, d0
  01b78:  48 c0                ext.l    d0
  01b7a:  72 14                moveq    #$14, d1
  01b7c:  2e 00                move.l   d0, d7
  01b7e:  e3 af                lsl.l    d1, d7
  01b80:  10 1c                move.b   (a4)+, d0
  01b82:  48 80                ext.w    d0
  01b84:  90 7c 00 30          sub.w    #$30, d0
  01b88:  48 c0                ext.l    d0
  01b8a:  72 10                moveq    #$10, d1
  01b8c:  e3 a8                lsl.l    d1, d0
  01b8e:  8e 80                or.l     d0, d7
  01b90:  10 1c                move.b   (a4)+, d0
  01b92:  48 80                ext.w    d0
  01b94:  90 7c 00 30          sub.w    #$30, d0
  01b98:  48 c0                ext.l    d0
  01b9a:  72 0c                moveq    #$c, d1
  01b9c:  e3 a8                lsl.l    d1, d0
  01b9e:  8e 80                or.l     d0, d7
  01ba0:  10 1c                move.b   (a4)+, d0
  01ba2:  48 80                ext.w    d0
  01ba4:  90 7c 00 57          sub.w    #$57, d0
  01ba8:  48 c0                ext.l    d0
  01baa:  e1 88                lsl.l    #$8, d0
  01bac:  8e 80                or.l     d0, d7
  01bae:  4a 2c 00 02          tst.b    $2(a4)
  01bb2:  58 4f                addq.w   #$4, a7
  01bb4:  67 02                beq.b    $1bb8
  01bb6:  52 4c                addq.w   #$1, a4
  01bb8:  10 1c                move.b   (a4)+, d0
  01bba:  48 80                ext.w    d0
  01bbc:  90 7c 00 30          sub.w    #$30, d0
  01bc0:  48 c0                ext.l    d0
  01bc2:  e9 88                lsl.l    #$4, d0
  01bc4:  8e 80                or.l     d0, d7
  01bc6:  10 14                move.b   (a4), d0
  01bc8:  48 80                ext.w    d0
  01bca:  90 7c 00 30          sub.w    #$30, d0
  01bce:  48 c0                ext.l    d0
  01bd0:  8e 80                or.l     d0, d7
  01bd2:  20 6e 00 10          movea.l  $10(a6), a0
  01bd6:  20 87                move.l   d7, (a0)
  01bd8:  70 00                moveq    #$0, d0
  01bda:  60 06                bra.b    $1be2
  01bdc:  70 ff                moveq    #$ff, d0
  01bde:  60 02                bra.b    $1be2
  01be0:  70 ff                moveq    #$ff, d0
  01be2:  4c ee 10 c0 ff bc    movem.l  -$44(a6), d6-d7/a4
  01be8:  4e 5e                unlk     a6
  01bea:  4e 75                rts      
  01bec:  4e 56 00 00          link.w   a6, #$0
  01bf0:  2f 07                move.l   d7, -(a7)
  01bf2:  2e 2e 00 08          move.l   $8(a6), d7
  01bf6:  70 14                moveq    #$14, d0
  01bf8:  22 07                move.l   d7, d1
  01bfa:  e0 a9                lsr.l    d0, d1
  01bfc:  70 01                moveq    #$1, d0
  01bfe:  b0 81                cmp.l    d1, d0
  01c00:  64 04                bcc.b    $1c06
  01c02:  70 01                moveq    #$1, d0
  01c04:  60 6c                bra.b    $1c72
  01c06:  70 14                moveq    #$14, d0
  01c08:  22 07                move.l   d7, d1
  01c0a:  e0 a9                lsr.l    d0, d1
  01c0c:  70 01                moveq    #$1, d0
  01c0e:  b0 81                cmp.l    d1, d0
  01c10:  63 04                bls.b    $1c16
  01c12:  70 00                moveq    #$0, d0
  01c14:  60 5c                bra.b    $1c72
  01c16:  70 0c                moveq    #$c, d0
  01c18:  22 07                move.l   d7, d1
  01c1a:  e0 a9                lsr.l    d0, d1
  01c1c:  20 3c 00 00 00 ff    move.l   #$ff, d0
  01c22:  c0 81                and.l    d1, d0
  01c24:  6f 04                ble.b    $1c2a
  01c26:  70 01                moveq    #$1, d0
  01c28:  60 48                bra.b    $1c72
  01c2a:  20 07                move.l   d7, d0
  01c2c:  e0 88                lsr.l    #$8, d0
  01c2e:  72 0f                moveq    #$f, d1
  01c30:  c2 80                and.l    d0, d1
  01c32:  70 0d                moveq    #$d, d0
  01c34:  b0 81                cmp.l    d1, d0
  01c36:  66 04                bne.b    $1c3c
  01c38:  70 00                moveq    #$0, d0
  01c3a:  60 36                bra.b    $1c72
  01c3c:  20 07                move.l   d7, d0
  01c3e:  e0 88                lsr.l    #$8, d0
  01c40:  72 0f                moveq    #$f, d1
  01c42:  c2 80                and.l    d0, d1
  01c44:  70 0b                moveq    #$b, d0
  01c46:  b0 81                cmp.l    d1, d0
  01c48:  66 04                bne.b    $1c4e
  01c4a:  70 01                moveq    #$1, d0
  01c4c:  60 24                bra.b    $1c72
  01c4e:  20 07                move.l   d7, d0
  01c50:  e0 88                lsr.l    #$8, d0
  01c52:  72 0f                moveq    #$f, d1
  01c54:  c2 80                and.l    d0, d1
  01c56:  70 0a                moveq    #$a, d0
  01c58:  b0 81                cmp.l    d1, d0
  01c5a:  67 04                beq.b    $1c60
  01c5c:  70 00                moveq    #$0, d0
  01c5e:  60 12                bra.b    $1c72
  01c60:  70 00                moveq    #$0, d0
  01c62:  22 3c 00 00 00 ff    move.l   #$ff, d1
  01c68:  c2 87                and.l    d7, d1
  01c6a:  74 10                moveq    #$10, d2
  01c6c:  b4 81                cmp.l    d1, d2
  01c6e:  5f c0                sle.b    d0
  01c70:  44 00                neg.b    d0
  01c72:  2e 2e ff fc          move.l   -$4(a6), d7
  01c76:  4e 5e                unlk     a6
  01c78:  4e 75                rts      
  01c7a:  4e 56 00 00          link.w   a6, #$0
  01c7e:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  01c82:  28 6e 00 08          movea.l  $8(a6), a4
  01c86:  7c 00                moveq    #$0, d6
  01c88:  60 02                bra.b    $1c8c
  01c8a:  52 4c                addq.w   #$1, a4
  01c8c:  1e 14                move.b   (a4), d7
  01c8e:  0c 07 00 30          cmpi.b   #$30, d7
  01c92:  6d f6                blt.b    $1c8a
  01c94:  0c 07 00 39          cmpi.b   #$39, d7
  01c98:  6e f0                bgt.b    $1c8a
  01c9a:  26 4c                movea.l  a4, a3
  01c9c:  60 02                bra.b    $1ca0
  01c9e:  52 4c                addq.w   #$1, a4
  01ca0:  1e 14                move.b   (a4), d7
  01ca2:  0c 07 00 30          cmpi.b   #$30, d7
  01ca6:  6d 06                blt.b    $1cae
  01ca8:  0c 07 00 39          cmpi.b   #$39, d7
  01cac:  6f f0                ble.b    $1c9e
  01cae:  7e 01                moveq    #$1, d7
  01cb0:  60 18                bra.b    $1cca
  01cb2:  10 14                move.b   (a4), d0
  01cb4:  48 80                ext.w    d0
  01cb6:  90 7c 00 30          sub.w    #$30, d0
  01cba:  48 c0                ext.l    d0
  01cbc:  4c 07 08 00          muls.l   d7, d0
  01cc0:  dc 80                add.l    d0, d6
  01cc2:  de 87                add.l    d7, d7
  01cc4:  20 07                move.l   d7, d0
  01cc6:  e5 8f                lsl.l    #$2, d7
  01cc8:  de 80                add.l    d0, d7
  01cca:  53 4c                subq.w   #$1, a4
  01ccc:  b7 cc                cmpa.l   a4, a3
  01cce:  63 e2                bls.b    $1cb2
  01cd0:  20 06                move.l   d6, d0
  01cd2:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  01cd8:  4e 5e                unlk     a6
  01cda:  4e 75                rts      
  01cdc:  4e 56 00 00          link.w   a6, #$0
  01ce0:  4a ae 00 0c          tst.l    $c(a6)
  01ce4:  67 06                beq.b    $1cec
  01ce6:  4a ae 00 08          tst.l    $8(a6)
  01cea:  66 04                bne.b    $1cf0
  01cec:  70 00                moveq    #$0, d0
  01cee:  60 02                bra.b    $1cf2
  01cf0:  70 00                moveq    #$0, d0
  01cf2:  4e 5e                unlk     a6
  01cf4:  4e 75                rts      
  01cf6:  4e 56 ff b4          link.w   a6, #$ffb4
  01cfa:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  01cfe:  26 6e 00 08          movea.l  $8(a6), a3
  01d02:  2e 2e 00 10          move.l   $10(a6), d7
  01d06:  28 6e 00 0c          movea.l  $c(a6), a4
  01d0a:  59 8f                subq.l   #$4, a7
  01d0c:  2f 0c                move.l   a4, -(a7)
  01d0e:  61 ff 00 00 2a e4    bsr.l    $47f4
  01d14:  28 5f                movea.l  (a7)+, a4
  01d16:  4a 2b 02 54          tst.b    $254(a3)
  01d1a:  67 34                beq.b    $1d50
  01d1c:  20 4c                movea.l  a4, a0
  01d1e:  22 47                movea.l  d7, a1
  01d20:  70 04                moveq    #$4, d0
  01d22:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  01d24:  4a 40                tst.w    d0
  01d26:  66 5a                bne.b    $1d82
  01d28:  2d 4c ff b4          move.l   a4, -$4c(a6)
  01d2c:  2d 47 ff b8          move.l   d7, -$48(a6)
  01d30:  70 01                moveq    #$1, d0
  01d32:  2d 40 ff fc          move.l   d0, -$4(a6)
  01d36:  55 8f                subq.l   #$2, a7
  01d38:  48 6e ff b4          pea.l    -$4c(a6)
  01d3c:  48 6e ff fc          pea.l    -$4(a6)
  01d40:  61 ff 00 00 2a cc    bsr.l    $480e
  01d46:  4a 5f                tst.w    (a7)+
  01d48:  66 38                bne.b    $1d82
  01d4a:  20 2e ff bc          move.l   -$44(a6), d0
  01d4e:  60 34                bra.b    $1d84
  01d50:  4a 2b 02 58          tst.b    $258(a3)
  01d54:  67 2c                beq.b    $1d82
  01d56:  2d 4c ff b4          move.l   a4, -$4c(a6)
  01d5a:  2d 47 ff b8          move.l   d7, -$48(a6)
  01d5e:  70 08                moveq    #$8, d0
  01d60:  2d 40 ff fc          move.l   d0, -$4(a6)
  01d64:  55 8f                subq.l   #$2, a7
  01d66:  48 6e ff b4          pea.l    -$4c(a6)
  01d6a:  48 6e ff fc          pea.l    -$4(a6)
  01d6e:  61 ff 00 00 2a 9e    bsr.l    $480e
  01d74:  4a 5f                tst.w    (a7)+
  01d76:  66 06                bne.b    $1d7e
  01d78:  20 2e ff bc          move.l   -$44(a6), d0
  01d7c:  60 06                bra.b    $1d84
  01d7e:  20 0c                move.l   a4, d0
  01d80:  60 02                bra.b    $1d84
  01d82:  20 0c                move.l   a4, d0
  01d84:  4c ee 18 80 ff a8    movem.l  -$58(a6), d7/a3-a4
  01d8a:  4e 5e                unlk     a6
  01d8c:  4e 75                rts      
  01d8e:  4e 56 00 00          link.w   a6, #$0
  01d92:  48 e7 01 08          movem.l  d7/a4, -(a7)
  01d96:  28 6e 00 08          movea.l  $8(a6), a4
  01d9a:  7e 01                moveq    #$1, d7
  01d9c:  20 54                movea.l  (a4), a0
  01d9e:  30 28 01 62          move.w   $162(a0), d0
  01da2:  04 40 00 2c          subi.w   #$2c, d0
  01da6:  67 06                beq.b    $1dae
  01da8:  04 40 00 52          subi.w   #$52, d0
  01dac:  66 1e                bne.b    $1dcc
  01dae:  20 54                movea.l  (a4), a0
  01db0:  70 00                moveq    #$0, d0
  01db2:  30 10                move.w   (a0), d0
  01db4:  2f 00                move.l   d0, -(a7)
  01db6:  70 00                moveq    #$0, d0
  01db8:  2f 00                move.l   d0, -(a7)
  01dba:  2f 3c 04 00 00 28    move.l   #$4000028, -(a7)
  01dc0:  61 ff 00 00 12 06    bsr.l    $2fc8
  01dc6:  4f ef 00 0c          lea.l    $c(a7), a7
  01dca:  60 04                bra.b    $1dd0
  01dcc:  70 00                moveq    #$0, d0
  01dce:  60 02                bra.b    $1dd2
  01dd0:  70 01                moveq    #$1, d0
  01dd2:  4c ee 10 80 ff f8    movem.l  -$8(a6), d7/a4
  01dd8:  4e 5e                unlk     a6
  01dda:  4e 75                rts      
  01ddc:  4e 56 00 00          link.w   a6, #$0
  01de0:  48 e7 01 08          movem.l  d7/a4, -(a7)
  01de4:  28 6e 00 08          movea.l  $8(a6), a4
  01de8:  7e 01                moveq    #$1, d7
  01dea:  20 54                movea.l  (a4), a0
  01dec:  70 00                moveq    #$0, d0
  01dee:  30 10                move.w   (a0), d0
  01df0:  2f 00                move.l   d0, -(a7)
  01df2:  2f 28 01 68          move.l   $168(a0), -(a7)
  01df6:  20 28 01 30          move.l   $130(a0), d0
  01dfa:  72 18                moveq    #$18, d1
  01dfc:  d0 81                add.l    d1, d0
  01dfe:  2f 00                move.l   d0, -(a7)
  01e00:  61 ff 00 00 11 c6    bsr.l    $2fc8
  01e06:  20 54                movea.l  (a4), a0
  01e08:  30 28 01 62          move.w   $162(a0), d0
  01e0c:  04 40 00 2c          subi.w   #$2c, d0
  01e10:  4f ef 00 0c          lea.l    $c(a7), a7
  01e14:  67 06                beq.b    $1e1c
  01e16:  04 40 00 52          subi.w   #$52, d0
  01e1a:  66 1e                bne.b    $1e3a
  01e1c:  20 54                movea.l  (a4), a0
  01e1e:  70 00                moveq    #$0, d0
  01e20:  30 10                move.w   (a0), d0
  01e22:  2f 00                move.l   d0, -(a7)
  01e24:  70 ff                moveq    #$ff, d0
  01e26:  2f 00                move.l   d0, -(a7)
  01e28:  2f 3c 04 00 00 28    move.l   #$4000028, -(a7)
  01e2e:  61 ff 00 00 11 98    bsr.l    $2fc8
  01e34:  4f ef 00 0c          lea.l    $c(a7), a7
  01e38:  60 04                bra.b    $1e3e
  01e3a:  70 00                moveq    #$0, d0
  01e3c:  60 02                bra.b    $1e40
  01e3e:  70 01                moveq    #$1, d0
  01e40:  4c ee 10 80 ff f8    movem.l  -$8(a6), d7/a4
  01e46:  4e 5e                unlk     a6
  01e48:  4e 75                rts      
  01e4a:  4e 56 ff 3c          link.w   a6, #$ff3c
  01e4e:  48 e7 1f 18          movem.l  d3-d7/a3-a4, -(a7)
  01e52:  28 2e 00 08          move.l   $8(a6), d4
  01e56:  26 6e 00 0c          movea.l  $c(a6), a3
  01e5a:  2e 04                move.l   d4, d7
  01e5c:  60 00 03 5c          bra.w    $21ba
  01e60:  1d 47 ff 71          move.b   d7, -$8f(a6)
  01e64:  1d 7c 00 01 ff 72    move.b   #$1, -$8e(a6)
  01e6a:  41 ee ff 78          lea.l    -$88(a6), a0
  01e6e:  2d 48 ff 40          move.l   a0, -$c0(a6)
  01e72:  42 2e ff 7a          clr.b    -$86(a6)
  01e76:  41 ee ff 40          lea.l    -$c0(a6), a0
  01e7a:  70 19                moveq    #$19, d0
  01e7c:  a0 6e                dc.w     $a06e  ; _SlotManager
  01e7e:  4a 40                tst.w    d0
  01e80:  66 00 03 34          bne.w    $21b6
  01e84:  10 2e ff 78          move.b   -$88(a6), d0
  01e88:  48 80                ext.w    d0
  01e8a:  52 40                addq.w   #$1, d0
  01e8c:  41 ee ff 78          lea.l    -$88(a6), a0
  01e90:  42 30 00 00          clr.b    (a0, d0.w)
  01e94:  70 20                moveq    #$20, d0
  01e96:  2f 00                move.l   d0, -(a7)
  01e98:  41 ee ff 78          lea.l    -$88(a6), a0
  01e9c:  54 48                addq.w   #$2, a0
  01e9e:  2f 08                move.l   a0, -(a7)
  01ea0:  61 ff 00 00 11 66    bsr.l    $3008
  01ea6:  20 40                movea.l  d0, a0
  01ea8:  42 10                clr.b    (a0)
  01eaa:  42 2e ff 72          clr.b    -$8e(a6)
  01eae:  3d 7c 00 01 ff 68    move.w   #$1, -$98(a6)
  01eb4:  42 6e ff 6a          clr.w    -$96(a6)
  01eb8:  1d 7c 00 03 ff 70    move.b   #$3, -$90(a6)
  01ebe:  41 ee ff 40          lea.l    -$c0(a6), a0
  01ec2:  70 15                moveq    #$15, d0
  01ec4:  a0 6e                dc.w     $a06e  ; _SlotManager
  01ec6:  4a 40                tst.w    d0
  01ec8:  50 4f                addq.w   #$8, a7
  01eca:  67 06                beq.b    $1ed2
  01ecc:  70 00                moveq    #$0, d0
  01ece:  60 00 02 f4          bra.w    $21c4
  01ed2:  1d 7c 00 20 ff 72    move.b   #$20, -$8e(a6)
  01ed8:  41 ee ff 40          lea.l    -$c0(a6), a0
  01edc:  70 01                moveq    #$1, d0
  01ede:  a0 6e                dc.w     $a06e  ; _SlotManager
  01ee0:  4a 40                tst.w    d0
  01ee2:  67 06                beq.b    $1eea
  01ee4:  70 00                moveq    #$0, d0
  01ee6:  60 00 02 dc          bra.w    $21c4
  01eea:  3c 2e ff 42          move.w   -$be(a6), d6
  01eee:  76 00                moveq    #$0, d3
  01ef0:  2f 03                move.l   d3, -(a7)
  01ef2:  48 6e ff fc          pea.l    -$4(a6)
  01ef6:  48 6e ff f8          pea.l    -$8(a6)
  01efa:  2f 07                move.l   d7, -(a7)
  01efc:  70 2c                moveq    #$2c, d0
  01efe:  2f 00                move.l   d0, -(a7)
  01f00:  61 ff ff ff fb a8    bsr.l    $1aaa
  01f06:  4f ef 00 10          lea.l    $10(a7), a7
  01f0a:  26 1f                move.l   (a7)+, d3
  01f0c:  4a 80                tst.l    d0
  01f0e:  66 16                bne.b    $1f26
  01f10:  2f 03                move.l   d3, -(a7)
  01f12:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  01f16:  61 ff ff ff fc d4    bsr.l    $1bec
  01f1c:  58 8f                addq.l   #$4, a7
  01f1e:  26 1f                move.l   (a7)+, d3
  01f20:  4a 80                tst.l    d0
  01f22:  67 02                beq.b    $1f26
  01f24:  76 01                moveq    #$1, d3
  01f26:  1a 03                move.b   d3, d5
  01f28:  0c 46 00 2c          cmpi.w   #$2c, d6
  01f2c:  67 36                beq.b    $1f64
  01f2e:  7c 7e                moveq    #$7e, d6
  01f30:  41 ee ff 78          lea.l    -$88(a6), a0
  01f34:  54 48                addq.w   #$2, a0
  01f36:  2f 08                move.l   a0, -(a7)
  01f38:  48 7a 02 9c          pea.l    $21d6(pc)
  01f3c:  61 ff 00 00 10 f6    bsr.l    $3034
  01f42:  4a 80                tst.l    d0
  01f44:  50 4f                addq.w   #$8, a7
  01f46:  67 1c                beq.b    $1f64
  01f48:  7c 7e                moveq    #$7e, d6
  01f4a:  41 ee ff 78          lea.l    -$88(a6), a0
  01f4e:  54 48                addq.w   #$2, a0
  01f50:  2f 08                move.l   a0, -(a7)
  01f52:  48 7a 02 7a          pea.l    $21ce(pc)
  01f56:  61 ff 00 00 10 dc    bsr.l    $3034
  01f5c:  4a 80                tst.l    d0
  01f5e:  50 4f                addq.w   #$8, a7
  01f60:  66 00 02 54          bne.w    $21b6
  01f64:  20 3c 00 00 06 00    move.l   #$600, d0
  01f6a:  a1 22                dc.w     $a122  ; _NewHandle
  01f6c:  2d 48 ff 3c          move.l   a0, -$c4(a6)
  01f70:  20 08                move.l   a0, d0
  01f72:  66 06                bne.b    $1f7a
  01f74:  70 00                moveq    #$0, d0
  01f76:  60 00 02 4c          bra.w    $21c4
  01f7a:  20 6e ff 3c          movea.l  -$c4(a6), a0
  01f7e:  a0 64                dc.w     $a064  ; _MoveHHi
  01f80:  20 6e ff 3c          movea.l  -$c4(a6), a0
  01f84:  a0 4a                dc.w     $a04a  ; _HNoPurge
  01f86:  20 6e ff 3c          movea.l  -$c4(a6), a0
  01f8a:  a0 29                dc.w     $a029  ; _HLock
  01f8c:  20 6e ff 3c          movea.l  -$c4(a6), a0
  01f90:  28 50                movea.l  (a0), a4
  01f92:  42 6c 01 5c          clr.w    $15c(a4)
  01f96:  70 00                moveq    #$0, d0
  01f98:  29 40 01 7c          move.l   d0, $17c(a4)
  01f9c:  72 53                moveq    #$53, d1
  01f9e:  29 41 01 74          move.l   d1, $174(a4)
  01fa2:  38 87                move.w   d7, (a4)
  01fa4:  4a 2b 02 54          tst.b    $254(a3)
  01fa8:  67 04                beq.b    $1fae
  01faa:  74 08                moveq    #$8, d2
  01fac:  60 02                bra.b    $1fb0
  01fae:  74 01                moveq    #$1, d2
  01fb0:  49 c2                extb.l   d2
  01fb2:  29 42 00 04          move.l   d2, $4(a4)
  01fb6:  39 46 01 62          move.w   d6, $162(a4)
  01fba:  70 00                moveq    #$0, d0
  01fbc:  29 40 01 68          move.l   d0, $168(a4)
  01fc0:  32 06                move.w   d6, d1
  01fc2:  04 41 00 2c          subi.w   #$2c, d1
  01fc6:  67 08                beq.b    $1fd0
  01fc8:  04 41 00 52          subi.w   #$52, d1
  01fcc:  66 00 00 cc          bne.w    $209a
  01fd0:  70 18                moveq    #$18, d0
  01fd2:  22 07                move.l   d7, d1
  01fd4:  e1 a9                lsl.l    d0, d1
  01fd6:  82 bc f0 00 00 00    or.l     #$f0000000, d1
  01fdc:  70 14                moveq    #$14, d0
  01fde:  24 07                move.l   d7, d2
  01fe0:  e1 aa                lsl.l    d0, d2
  01fe2:  84 81                or.l     d1, d2
  01fe4:  29 42 01 6c          move.l   d2, $16c(a4)
  01fe8:  20 02                move.l   d2, d0
  01fea:  d0 bc 00 00 8c 00    add.l    #$8c00, d0
  01ff0:  29 40 00 0c          move.l   d0, $c(a4)
  01ff4:  2f 2e ff 3c          move.l   -$c4(a6), -(a7)
  01ff8:  61 ff ff ff fd 94    bsr.l    $1d8e
  01ffe:  42 6c 01 5e          clr.w    $15e(a4)
  02002:  2f 07                move.l   d7, -(a7)
  02004:  2f 3c 04 00 00 4c    move.l   #$400004c, -(a7)
  0200a:  61 ff 00 00 0f 78    bsr.l    $2f84
  02010:  22 3c 80 00 00 00    move.l   #$80000000, d1
  02016:  c2 80                and.l    d0, d1
  02018:  4f ef 00 0c          lea.l    $c(a7), a7
  0201c:  67 06                beq.b    $2024
  0201e:  00 6c 00 01 01 5e    ori.w    #$1, $15e(a4)
  02024:  2f 07                move.l   d7, -(a7)
  02026:  2f 3c 04 00 00 48    move.l   #$4000048, -(a7)
  0202c:  61 ff 00 00 0f 56    bsr.l    $2f84
  02032:  22 3c 80 00 00 00    move.l   #$80000000, d1
  02038:  c2 80                and.l    d0, d1
  0203a:  50 4f                addq.w   #$8, a7
  0203c:  67 06                beq.b    $2044
  0203e:  00 6c 00 02 01 5e    ori.w    #$2, $15e(a4)
  02044:  2f 07                move.l   d7, -(a7)
  02046:  2f 3c 04 00 00 44    move.l   #$4000044, -(a7)
  0204c:  61 ff 00 00 0f 36    bsr.l    $2f84
  02052:  22 3c 80 00 00 00    move.l   #$80000000, d1
  02058:  c2 80                and.l    d0, d1
  0205a:  50 4f                addq.w   #$8, a7
  0205c:  67 06                beq.b    $2064
  0205e:  00 6c 00 04 01 5e    ori.w    #$4, $15e(a4)
  02064:  4a 05                tst.b    d5
  02066:  66 1c                bne.b    $2084
  02068:  70 07                moveq    #$7, d0
  0206a:  b0 6c 01 5e          cmp.w    $15e(a4), d0
  0206e:  66 14                bne.b    $2084
  02070:  20 6e ff 3c          movea.l  -$c4(a6), a0
  02074:  a0 4a                dc.w     $a04a  ; _HNoPurge
  02076:  39 7c ff ff 01 5e    move.w   #$ffff, $15e(a4)
  0207c:  20 2e ff 3c          move.l   -$c4(a6), d0
  02080:  60 00 01 42          bra.w    $21c4
  02084:  2f 07                move.l   d7, -(a7)
  02086:  61 ff 00 00 01 56    bsr.l    $21de
  0208c:  29 40 01 64          move.l   d0, $164(a4)
  02090:  58 4f                addq.w   #$4, a7
  02092:  64 06                bcc.b    $209a
  02094:  29 6c 01 64 01 7c    move.l   $164(a4), $17c(a4)
  0209a:  70 01                moveq    #$1, d0
  0209c:  29 40 00 08          move.l   d0, $8(a4)
  020a0:  32 2b 02 2e          move.w   $22e(a3), d1
  020a4:  48 c1                ext.l    d1
  020a6:  e5 81                asl.l    #$2, d1
  020a8:  d2 ab 02 34          add.l    $234(a3), d1
  020ac:  29 41 00 10          move.l   d1, $10(a4)
  020b0:  72 ff                moveq    #$ff, d1
  020b2:  b2 ab 02 3c          cmp.l    $23c(a3), d1
  020b6:  67 12                beq.b    $20ca
  020b8:  30 2b 02 2e          move.w   $22e(a3), d0
  020bc:  48 c0                ext.l    d0
  020be:  e5 80                asl.l    #$2, d0
  020c0:  d0 ab 02 3c          add.l    $23c(a3), d0
  020c4:  29 40 00 14          move.l   d0, $14(a4)
  020c8:  60 10                bra.b    $20da
  020ca:  30 2b 02 2e          move.w   $22e(a3), d0
  020ce:  48 c0                ext.l    d0
  020d0:  e5 80                asl.l    #$2, d0
  020d2:  d0 ab 02 34          add.l    $234(a3), d0
  020d6:  29 40 00 14          move.l   d0, $14(a4)
  020da:  20 2b 02 34          move.l   $234(a3), d0
  020de:  72 18                moveq    #$18, d1
  020e0:  d0 81                add.l    d1, d0
  020e2:  34 2b 02 2e          move.w   $22e(a3), d2
  020e6:  48 c2                ext.l    d2
  020e8:  e5 82                asl.l    #$2, d2
  020ea:  d4 80                add.l    d0, d2
  020ec:  29 42 01 3c          move.l   d2, $13c(a4)
  020f0:  70 ff                moveq    #$ff, d0
  020f2:  b0 ab 02 3c          cmp.l    $23c(a3), d0
  020f6:  67 18                beq.b    $2110
  020f8:  20 2b 02 3c          move.l   $23c(a3), d0
  020fc:  72 18                moveq    #$18, d1
  020fe:  d0 81                add.l    d1, d0
  02100:  34 2b 02 2e          move.w   $22e(a3), d2
  02104:  48 c2                ext.l    d2
  02106:  e5 82                asl.l    #$2, d2
  02108:  d4 80                add.l    d0, d2
  0210a:  29 42 01 40          move.l   d2, $140(a4)
  0210e:  60 16                bra.b    $2126
  02110:  20 2b 02 34          move.l   $234(a3), d0
  02114:  72 18                moveq    #$18, d1
  02116:  d0 81                add.l    d1, d0
  02118:  34 2b 02 2e          move.w   $22e(a3), d2
  0211c:  48 c2                ext.l    d2
  0211e:  e5 82                asl.l    #$2, d2
  02120:  d4 80                add.l    d0, d2
  02122:  29 42 01 40          move.l   d2, $140(a4)
  02126:  20 6c 01 3c          movea.l  $13c(a4), a0
  0212a:  70 00                moveq    #$0, d0
  0212c:  20 80                move.l   d0, (a0)
  0212e:  29 40 01 58          move.l   d0, $158(a4)
  02132:  29 40 01 54          move.l   d0, $154(a4)
  02136:  29 40 01 50          move.l   d0, $150(a4)
  0213a:  29 40 01 4c          move.l   d0, $14c(a4)
  0213e:  29 40 00 1c          move.l   d0, $1c(a4)
  02142:  29 40 00 20          move.l   d0, $20(a4)
  02146:  29 40 05 f0          move.l   d0, $5f0(a4)
  0214a:  29 40 01 8e          move.l   d0, $18e(a4)
  0214e:  29 7c 80 00 00 00 01 28 move.l   #$80000000, $128(a4)
  02156:  39 7c 01 2c 00 02    move.w   #$12c, $2(a4)
  0215c:  29 40 01 2c          move.l   d0, $12c(a4)
  02160:  29 40 00 28          move.l   d0, $28(a4)
  02164:  29 6b 02 70 00 c4    move.l   $270(a3), $c4(a4)
  0216a:  29 6b 02 6c 00 ac    move.l   $26c(a3), $ac(a4)
  02170:  29 6c 00 ac 00 b0    move.l   $ac(a4), $b0(a4)
  02176:  29 40 00 b4          move.l   d0, $b4(a4)
  0217a:  4a ac 00 ac          tst.l    $ac(a4)
  0217e:  67 06                beq.b    $2186
  02180:  29 6b 02 68 00 bc    move.l   $268(a3), $bc(a4)
  02186:  70 00                moveq    #$0, d0
  02188:  29 40 01 02          move.l   d0, $102(a4)
  0218c:  29 40 01 06          move.l   d0, $106(a4)
  02190:  29 40 00 c0          move.l   d0, $c0(a4)
  02194:  29 40 00 c8          move.l   d0, $c8(a4)
  02198:  29 40 01 24          move.l   d0, $124(a4)
  0219c:  29 40 01 78          move.l   d0, $178(a4)
  021a0:  39 7c 00 01 01 80    move.w   #$1, $180(a4)
  021a6:  29 40 01 48          move.l   d0, $148(a4)
  021aa:  20 6e ff 3c          movea.l  -$c4(a6), a0
  021ae:  a0 4a                dc.w     $a04a  ; _HNoPurge
  021b0:  20 2e ff 3c          move.l   -$c4(a6), d0
  021b4:  60 0e                bra.b    $21c4
  021b6:  20 07                move.l   d7, d0
  021b8:  52 87                addq.l   #$1, d7
  021ba:  70 0e                moveq    #$e, d0
  021bc:  b0 87                cmp.l    d7, d0
  021be:  6c 00 fc a0          bge.w    $1e60
  021c2:  70 00                moveq    #$0, d0
  021c4:  4c ee 18 f8 ff 20    movem.l  -$e0(a6), d3-d7/a3-a4
  021ca:  4e 5e                unlk     a6
  021cc:  4e 75                rts      
  021ce:  54 69 62 75          addq.w   #$2, $6275(a1)
  021d2:  72 6f                moveq    #$6f, d1
  021d4:  6e 00 43 68          bgt.w    $653e
  021d8:  65 65                bcs.b    $223f
  021da:  74 61                moveq    #$61, d2
  021dc:  68 00 4e 56          bvc.w    $7034
  021e0:  00 00 48 e7          ori.b    #$e7, d0
  021e4:  0f 00                btst.l   d7, d0
  021e6:  2c 2e 00 08          move.l   $8(a6), d6
  021ea:  78 00                moveq    #$0, d4
  021ec:  7a 00                moveq    #$0, d5
  021ee:  2f 06                move.l   d6, -(a7)
  021f0:  2f 3c 04 00 00 9c    move.l   #$400009c, -(a7)
  021f6:  61 ff 00 00 0d 8c    bsr.l    $2f84
  021fc:  22 3c 80 00 00 00    move.l   #$80000000, d1
  02202:  c2 80                and.l    d0, d1
  02204:  50 4f                addq.w   #$8, a7
  02206:  67 40                beq.b    $2248
  02208:  2f 06                move.l   d6, -(a7)
  0220a:  2f 3c 06 00 00 00    move.l   #$6000000, -(a7)
  02210:  61 ff 00 00 0d 72    bsr.l    $2f84
  02216:  72 0c                moveq    #$c, d1
  02218:  e2 a0                asr.l    d1, d0
  0221a:  72 0f                moveq    #$f, d1
  0221c:  c2 80                and.l    d0, d1
  0221e:  50 4f                addq.w   #$8, a7
  02220:  66 04                bne.b    $2226
  02222:  78 03                moveq    #$3, d4
  02224:  60 24                bra.b    $224a
  02226:  2f 06                move.l   d6, -(a7)
  02228:  2f 3c 06 00 00 00    move.l   #$6000000, -(a7)
  0222e:  61 ff 00 00 0d 54    bsr.l    $2f84
  02234:  72 0c                moveq    #$c, d1
  02236:  e2 a0                asr.l    d1, d0
  02238:  72 0f                moveq    #$f, d1
  0223a:  c2 80                and.l    d0, d1
  0223c:  70 01                moveq    #$1, d0
  0223e:  b0 81                cmp.l    d1, d0
  02240:  50 4f                addq.w   #$8, a7
  02242:  66 06                bne.b    $224a
  02244:  78 04                moveq    #$4, d4
  02246:  60 02                bra.b    $224a
  02248:  78 02                moveq    #$2, d4
  0224a:  7e 00                moveq    #$0, d7
  0224c:  60 1a                bra.b    $2268
  0224e:  2f 06                move.l   d6, -(a7)
  02250:  20 07                move.l   d7, d0
  02252:  46 80                not.l    d0
  02254:  2f 00                move.l   d0, -(a7)
  02256:  2f 07                move.l   d7, -(a7)
  02258:  61 ff 00 00 0d 6e    bsr.l    $2fc8
  0225e:  4f ef 00 0c          lea.l    $c(a7), a7
  02262:  06 87 00 00 01 00    addi.l   #$100, d7
  02268:  0c 87 00 02 00 00    cmpi.l   #$20000, d7
  0226e:  65 de                bcs.b    $224e
  02270:  7e 00                moveq    #$0, d7
  02272:  60 1a                bra.b    $228e
  02274:  2f 06                move.l   d6, -(a7)
  02276:  2f 07                move.l   d7, -(a7)
  02278:  61 ff 00 00 0d 0a    bsr.l    $2f84
  0227e:  22 07                move.l   d7, d1
  02280:  46 81                not.l    d1
  02282:  b2 80                cmp.l    d0, d1
  02284:  50 4f                addq.w   #$8, a7
  02286:  66 0e                bne.b    $2296
  02288:  06 87 00 00 01 00    addi.l   #$100, d7
  0228e:  0c 87 00 02 00 00    cmpi.l   #$20000, d7
  02294:  65 de                bcs.b    $2274
  02296:  0c 87 00 01 00 00    cmpi.l   #$10000, d7
  0229c:  64 0a                bcc.b    $22a8
  0229e:  20 3c ff ff d8 ea    move.l   #$ffffd8ea, d0
  022a4:  60 00 01 1c          bra.w    $23c2
  022a8:  0c 87 00 02 00 00    cmpi.l   #$20000, d7
  022ae:  66 06                bne.b    $22b6
  022b0:  00 84 00 00 01 00    ori.l    #$100, d4
  022b6:  7a 00                moveq    #$0, d5
  022b8:  2f 06                move.l   d6, -(a7)
  022ba:  2f 3c 0c 00 00 00    move.l   #$c000000, -(a7)
  022c0:  61 ff 00 00 04 7a    bsr.l    $273c
  022c6:  4a 80                tst.l    d0
  022c8:  50 4f                addq.w   #$8, a7
  022ca:  67 14                beq.b    $22e0
  022cc:  2f 06                move.l   d6, -(a7)
  022ce:  2f 3c 0c 1f ff f0    move.l   #$c1ffff0, -(a7)
  022d4:  61 ff 00 00 04 66    bsr.l    $273c
  022da:  4a 80                tst.l    d0
  022dc:  50 4f                addq.w   #$8, a7
  022de:  66 0a                bne.b    $22ea
  022e0:  20 3c ff ff d8 ea    move.l   #$ffffd8ea, d0
  022e6:  60 00 00 da          bra.w    $23c2
  022ea:  2f 06                move.l   d6, -(a7)
  022ec:  2f 3c 0c 20 00 00    move.l   #$c200000, -(a7)
  022f2:  61 ff 00 00 04 48    bsr.l    $273c
  022f8:  4a 80                tst.l    d0
  022fa:  50 4f                addq.w   #$8, a7
  022fc:  67 1a                beq.b    $2318
  022fe:  7a 01                moveq    #$1, d5
  02300:  2f 06                move.l   d6, -(a7)
  02302:  2f 3c 0c 30 00 00    move.l   #$c300000, -(a7)
  02308:  61 ff 00 00 04 32    bsr.l    $273c
  0230e:  4a 80                tst.l    d0
  02310:  50 4f                addq.w   #$8, a7
  02312:  67 22                beq.b    $2336
  02314:  7a 02                moveq    #$2, d5
  02316:  60 1e                bra.b    $2336
  02318:  2f 06                move.l   d6, -(a7)
  0231a:  2f 3c 0c 30 00 00    move.l   #$c300000, -(a7)
  02320:  61 ff 00 00 04 1a    bsr.l    $273c
  02326:  4a 80                tst.l    d0
  02328:  50 4f                addq.w   #$8, a7
  0232a:  67 0a                beq.b    $2336
  0232c:  20 3c ff ff d8 e8    move.l   #$ffffd8e8, d0
  02332:  60 00 00 8e          bra.w    $23c2
  02336:  2f 06                move.l   d6, -(a7)
  02338:  2f 3c 0c 20 00 00    move.l   #$c200000, -(a7)
  0233e:  2f 3c 0d 10 00 00    move.l   #$d100000, -(a7)
  02344:  61 ff 00 00 04 ba    bsr.l    $2800
  0234a:  4a 80                tst.l    d0
  0234c:  4f ef 00 0c          lea.l    $c(a7), a7
  02350:  67 40                beq.b    $2392
  02352:  7a 04                moveq    #$4, d5
  02354:  2f 06                move.l   d6, -(a7)
  02356:  2f 3c 0d 00 00 00    move.l   #$d000000, -(a7)
  0235c:  2f 3c 0d 40 00 00    move.l   #$d400000, -(a7)
  02362:  61 ff 00 00 04 9c    bsr.l    $2800
  02368:  4a 80                tst.l    d0
  0236a:  4f ef 00 0c          lea.l    $c(a7), a7
  0236e:  67 02                beq.b    $2372
  02370:  7a 05                moveq    #$5, d5
  02372:  2f 06                move.l   d6, -(a7)
  02374:  2f 3c 0c 30 00 00    move.l   #$c300000, -(a7)
  0237a:  2f 3c 0d 50 00 00    move.l   #$d500000, -(a7)
  02380:  61 ff 00 00 04 7e    bsr.l    $2800
  02386:  4a 80                tst.l    d0
  02388:  4f ef 00 0c          lea.l    $c(a7), a7
  0238c:  67 28                beq.b    $23b6
  0238e:  7a 08                moveq    #$8, d5
  02390:  60 24                bra.b    $23b6
  02392:  2f 06                move.l   d6, -(a7)
  02394:  2f 3c 0c 30 00 00    move.l   #$c300000, -(a7)
  0239a:  2f 3c 0d 50 00 00    move.l   #$d500000, -(a7)
  023a0:  61 ff 00 00 04 5e    bsr.l    $2800
  023a6:  4a 80                tst.l    d0
  023a8:  4f ef 00 0c          lea.l    $c(a7), a7
  023ac:  67 08                beq.b    $23b6
  023ae:  20 3c ff ff d8 e8    move.l   #$ffffd8e8, d0
  023b4:  60 0c                bra.b    $23c2
  023b6:  20 05                move.l   d5, d0
  023b8:  54 80                addq.l   #$2, d0
  023ba:  72 10                moveq    #$10, d1
  023bc:  e3 a8                lsl.l    d1, d0
  023be:  88 80                or.l     d0, d4
  023c0:  20 04                move.l   d4, d0
  023c2:  4c ee 00 f0 ff f0    movem.l  -$10(a6), d4-d7
  023c8:  4e 5e                unlk     a6
  023ca:  4e 75                rts      
  023cc:  4e 56 ff f6          link.w   a6, #$fff6
  023d0:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  023d4:  26 6e 00 08          movea.l  $8(a6), a3
  023d8:  1d 7c 00 01 ff f7    move.b   #$1, -$9(a6)
  023de:  20 53                movea.l  (a3), a0
  023e0:  7c 00                moveq    #$0, d6
  023e2:  3c 10                move.w   (a0), d6
  023e4:  3d 7c ff ff ff fc    move.w   #$ffff, -$4(a6)
  023ea:  4a 86                tst.l    d6
  023ec:  66 06                bne.b    $23f4
  023ee:  70 ff                moveq    #$ff, d0
  023f0:  60 00 03 40          bra.w    $2732
  023f4:  20 4b                movea.l  a3, a0
  023f6:  a0 69                dc.w     $a069  ; _HGetState
  023f8:  1d 40 ff ff          move.b   d0, -$1(a6)
  023fc:  20 4b                movea.l  a3, a0
  023fe:  a0 29                dc.w     $a029  ; _HLock
  02400:  28 53                movea.l  (a3), a4
  02402:  2a 2c 01 68          move.l   $168(a4), d5
  02406:  30 2c 01 62          move.w   $162(a4), d0
  0240a:  04 40 00 2c          subi.w   #$2c, d0
  0240e:  67 08                beq.b    $2418
  02410:  04 40 00 52          subi.w   #$52, d0
  02414:  66 00 03 0a          bne.w    $2720
  02418:  2f 0b                move.l   a3, -(a7)
  0241a:  61 ff ff ff f9 72    bsr.l    $1d8e
  02420:  7e 00                moveq    #$0, d7
  02422:  58 4f                addq.w   #$4, a7
  02424:  2f 06                move.l   d6, -(a7)
  02426:  20 07                move.l   d7, d0
  02428:  46 80                not.l    d0
  0242a:  2f 00                move.l   d0, -(a7)
  0242c:  2f 07                move.l   d7, -(a7)
  0242e:  61 ff 00 00 0b 98    bsr.l    $2fc8
  02434:  4f ef 00 0c          lea.l    $c(a7), a7
  02438:  06 87 00 00 10 00    addi.l   #$1000, d7
  0243e:  0c 87 00 02 00 00    cmpi.l   #$20000, d7
  02444:  6d de                blt.b    $2424
  02446:  7e 00                moveq    #$0, d7
  02448:  2f 06                move.l   d6, -(a7)
  0244a:  2f 07                move.l   d7, -(a7)
  0244c:  61 ff 00 00 0b 36    bsr.l    $2f84
  02452:  22 07                move.l   d7, d1
  02454:  46 81                not.l    d1
  02456:  b2 80                cmp.l    d0, d1
  02458:  50 4f                addq.w   #$8, a7
  0245a:  66 0e                bne.b    $246a
  0245c:  06 87 00 00 10 00    addi.l   #$1000, d7
  02462:  0c 87 00 02 00 00    cmpi.l   #$20000, d7
  02468:  6d de                blt.b    $2448
  0246a:  0c 87 00 01 00 00    cmpi.l   #$10000, d7
  02470:  6c 0c                bge.b    $247e
  02472:  29 7c ff ff d8 ea 01 7c move.l   #$ffffd8ea, $17c(a4)
  0247a:  60 00 02 a8          bra.w    $2724
  0247e:  2f 06                move.l   d6, -(a7)
  02480:  2f 3c 0c 00 00 00    move.l   #$c000000, -(a7)
  02486:  61 ff 00 00 02 b4    bsr.l    $273c
  0248c:  4a 80                tst.l    d0
  0248e:  50 4f                addq.w   #$8, a7
  02490:  66 0c                bne.b    $249e
  02492:  29 7c ff ff d8 ea 01 7c move.l   #$ffffd8ea, $17c(a4)
  0249a:  60 00 02 88          bra.w    $2724
  0249e:  2f 06                move.l   d6, -(a7)
  024a0:  2f 3c 0c 00 00 00    move.l   #$c000000, -(a7)
  024a6:  2f 3c 0c 10 00 00    move.l   #$c100000, -(a7)
  024ac:  61 ff 00 00 03 52    bsr.l    $2800
  024b2:  4a 80                tst.l    d0
  024b4:  4f ef 00 0c          lea.l    $c(a7), a7
  024b8:  66 0c                bne.b    $24c6
  024ba:  29 7c ff ff d8 ea 01 7c move.l   #$ffffd8ea, $17c(a4)
  024c2:  60 00 02 60          bra.w    $2724
  024c6:  2e 3c 0c 1f ff ff    move.l   #$c1fffff, d7
  024cc:  2f 06                move.l   d6, -(a7)
  024ce:  2f 3c 0c 20 00 00    move.l   #$c200000, -(a7)
  024d4:  61 ff 00 00 02 66    bsr.l    $273c
  024da:  4a 80                tst.l    d0
  024dc:  50 4f                addq.w   #$8, a7
  024de:  67 22                beq.b    $2502
  024e0:  2e 3c 0c 2f ff ff    move.l   #$c2fffff, d7
  024e6:  2f 06                move.l   d6, -(a7)
  024e8:  2f 3c 0c 30 00 00    move.l   #$c300000, -(a7)
  024ee:  61 ff 00 00 02 4c    bsr.l    $273c
  024f4:  4a 80                tst.l    d0
  024f6:  50 4f                addq.w   #$8, a7
  024f8:  67 28                beq.b    $2522
  024fa:  2e 3c 0c 3f ff ff    move.l   #$c3fffff, d7
  02500:  60 20                bra.b    $2522
  02502:  2f 06                move.l   d6, -(a7)
  02504:  2f 3c 0c 30 00 00    move.l   #$c300000, -(a7)
  0250a:  61 ff 00 00 02 30    bsr.l    $273c
  02510:  4a 80                tst.l    d0
  02512:  50 4f                addq.w   #$8, a7
  02514:  67 0c                beq.b    $2522
  02516:  29 7c ff ff d8 e8 01 7c move.l   #$ffffd8e8, $17c(a4)
  0251e:  60 00 02 04          bra.w    $2724
  02522:  2f 06                move.l   d6, -(a7)
  02524:  2f 3c 0c 20 00 00    move.l   #$c200000, -(a7)
  0252a:  2f 3c 0d 10 00 00    move.l   #$d100000, -(a7)
  02530:  61 ff 00 00 02 ce    bsr.l    $2800
  02536:  4a 80                tst.l    d0
  02538:  4f ef 00 0c          lea.l    $c(a7), a7
  0253c:  67 4c                beq.b    $258a
  0253e:  2e 3c 0d 3f ff ff    move.l   #$d3fffff, d7
  02544:  2f 06                move.l   d6, -(a7)
  02546:  2f 3c 0d 00 00 00    move.l   #$d000000, -(a7)
  0254c:  2f 3c 0d 40 00 00    move.l   #$d400000, -(a7)
  02552:  61 ff 00 00 02 ac    bsr.l    $2800
  02558:  4a 80                tst.l    d0
  0255a:  4f ef 00 0c          lea.l    $c(a7), a7
  0255e:  67 06                beq.b    $2566
  02560:  2e 3c 0d 4f ff ff    move.l   #$d4fffff, d7
  02566:  2f 06                move.l   d6, -(a7)
  02568:  2f 3c 0c 30 00 00    move.l   #$c300000, -(a7)
  0256e:  2f 3c 0d 50 00 00    move.l   #$d500000, -(a7)
  02574:  61 ff 00 00 02 8a    bsr.l    $2800
  0257a:  4a 80                tst.l    d0
  0257c:  4f ef 00 0c          lea.l    $c(a7), a7
  02580:  67 30                beq.b    $25b2
  02582:  2e 3c 0d 7f ff ff    move.l   #$d7fffff, d7
  02588:  60 28                bra.b    $25b2
  0258a:  2f 06                move.l   d6, -(a7)
  0258c:  2f 3c 0c 30 00 00    move.l   #$c300000, -(a7)
  02592:  2f 3c 0d 50 00 00    move.l   #$d500000, -(a7)
  02598:  61 ff 00 00 02 66    bsr.l    $2800
  0259e:  4a 80                tst.l    d0
  025a0:  4f ef 00 0c          lea.l    $c(a7), a7
  025a4:  67 0c                beq.b    $25b2
  025a6:  29 7c ff ff d8 e8 01 7c move.l   #$ffffd8e8, $17c(a4)
  025ae:  60 00 01 74          bra.w    $2724
  025b2:  29 47 01 38          move.l   d7, $138(a4)
  025b6:  2f 0b                move.l   a3, -(a7)
  025b8:  61 ff ff ff f7 d4    bsr.l    $1d8e
  025be:  20 53                movea.l  (a3), a0
  025c0:  7a 10                moveq    #$10, d5
  025c2:  8a a8 01 68          or.l     $168(a0), d5
  025c6:  70 00                moveq    #$0, d0
  025c8:  29 40 01 30          move.l   d0, $130(a4)
  025cc:  20 6e 00 0c          movea.l  $c(a6), a0
  025d0:  a0 69                dc.w     $a069  ; _HGetState
  025d2:  18 00                move.b   d0, d4
  025d4:  20 6e 00 0c          movea.l  $c(a6), a0
  025d8:  a0 29                dc.w     $a029  ; _HLock
  025da:  2f 0b                move.l   a3, -(a7)
  025dc:  2f 05                move.l   d5, -(a7)
  025de:  59 8f                subq.l   #$4, a7
  025e0:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  025e4:  61 ff 00 00 1f 7e    bsr.l    $4564
  025ea:  2f 06                move.l   d6, -(a7)
  025ec:  48 6c 01 30          pea.l    $130(a4)
  025f0:  20 6e 00 0c          movea.l  $c(a6), a0
  025f4:  2f 10                move.l   (a0), -(a7)
  025f6:  61 ff 00 00 0a b4    bsr.l    $30ac  ; -> ACEFLoad
  025fc:  4a 80                tst.l    d0
  025fe:  4f ef 00 1c          lea.l    $1c(a7), a7
  02602:  66 14                bne.b    $2618
  02604:  20 6e 00 0c          movea.l  $c(a6), a0
  02608:  10 04                move.b   d4, d0
  0260a:  a0 6a                dc.w     $a06a  ; _HSetState
  0260c:  29 7c ff ff d8 ea 01 7c move.l   #$ffffd8ea, $17c(a4)
  02614:  60 00 01 0e          bra.w    $2724
  02618:  20 6e 00 0c          movea.l  $c(a6), a0
  0261c:  10 04                move.b   d4, d0
  0261e:  a0 6a                dc.w     $a06a  ; _HSetState
  02620:  2d 6c 01 30 ff f8    move.l   $130(a4), -$8(a6)
  02626:  2f 06                move.l   d6, -(a7)
  02628:  20 2e ff f8          move.l   -$8(a6), d0
  0262c:  d0 bc 00 00 04 00    add.l    #$400, d0
  02632:  2f 00                move.l   d0, -(a7)
  02634:  61 ff 00 00 09 4e    bsr.l    $2f84
  0263a:  0c 80 32 10 04 56    cmpi.l   #$32100456, d0
  02640:  50 4f                addq.w   #$8, a7
  02642:  67 0c                beq.b    $2650
  02644:  29 7c ff ff d8 ea 01 7c move.l   #$ffffd8ea, $17c(a4)
  0264c:  60 00 00 d6          bra.w    $2724
  02650:  2f 06                move.l   d6, -(a7)
  02652:  2f 2c 01 68          move.l   $168(a4), -(a7)
  02656:  20 2e ff f8          move.l   -$8(a6), d0
  0265a:  72 18                moveq    #$18, d1
  0265c:  d0 81                add.l    d1, d0
  0265e:  2f 00                move.l   d0, -(a7)
  02660:  61 ff 00 00 09 66    bsr.l    $2fc8
  02666:  2f 06                move.l   d6, -(a7)
  02668:  2f 3c 42 00 53 00    move.l   #$42005300, -(a7)
  0266e:  20 2e ff f8          move.l   -$8(a6), d0
  02672:  2f 00                move.l   d0, -(a7)
  02674:  61 ff 00 00 09 52    bsr.l    $2fc8
  0267a:  2f 06                move.l   d6, -(a7)
  0267c:  2f 06                move.l   d6, -(a7)
  0267e:  2f 2c 01 38          move.l   $138(a4), -(a7)
  02682:  61 ff 00 00 08 78    bsr.l    $2efc
  02688:  50 8f                addq.l   #$8, a7
  0268a:  2f 00                move.l   d0, -(a7)
  0268c:  20 2e ff f8          move.l   -$8(a6), d0
  02690:  50 80                addq.l   #$8, d0
  02692:  2f 00                move.l   d0, -(a7)
  02694:  61 ff 00 00 09 32    bsr.l    $2fc8
  0269a:  2f 06                move.l   d6, -(a7)
  0269c:  2f 06                move.l   d6, -(a7)
  0269e:  20 2c 01 34          move.l   $134(a4), d0
  026a2:  90 bc 00 00 06 d1    sub.l    #$6d1, d0
  026a8:  22 3c ff ff ff 00    move.l   #$ffffff00, d1
  026ae:  c2 80                and.l    d0, d1
  026b0:  2f 01                move.l   d1, -(a7)
  026b2:  61 ff 00 00 08 48    bsr.l    $2efc
  026b8:  50 8f                addq.l   #$8, a7
  026ba:  2f 00                move.l   d0, -(a7)
  026bc:  20 2e ff f8          move.l   -$8(a6), d0
  026c0:  72 14                moveq    #$14, d1
  026c2:  d0 81                add.l    d1, d0
  026c4:  2f 00                move.l   d0, -(a7)
  026c6:  61 ff 00 00 09 00    bsr.l    $2fc8
  026cc:  20 3c 00 00 08 00    move.l   #$800, d0
  026d2:  c0 85                and.l    d5, d0
  026d4:  4f ef 00 30          lea.l    $30(a7), a7
  026d8:  66 46                bne.b    $2720
  026da:  2f 06                move.l   d6, -(a7)
  026dc:  20 2e ff f8          move.l   -$8(a6), d0
  026e0:  d0 bc 00 00 04 0c    add.l    #$40c, d0
  026e6:  2f 00                move.l   d0, -(a7)
  026e8:  61 ff 00 00 08 9a    bsr.l    $2f84
  026ee:  29 40 01 44          move.l   d0, $144(a4)
  026f2:  2f 06                move.l   d6, -(a7)
  026f4:  2f 2c 01 40          move.l   $140(a4), -(a7)
  026f8:  20 2c 01 44          move.l   $144(a4), d0
  026fc:  72 0c                moveq    #$c, d1
  026fe:  d0 81                add.l    d1, d0
  02700:  2f 00                move.l   d0, -(a7)
  02702:  61 ff 00 00 08 c4    bsr.l    $2fc8
  02708:  2f 06                move.l   d6, -(a7)
  0270a:  2f 3c 73 33 33 37    move.l   #$73333337, -(a7)
  02710:  20 2c 01 44          move.l   $144(a4), d0
  02714:  2f 00                move.l   d0, -(a7)
  02716:  61 ff 00 00 08 b0    bsr.l    $2fc8
  0271c:  4f ef 00 20          lea.l    $20(a7), a7
  02720:  42 6e ff fc          clr.w    -$4(a6)
  02724:  20 4b                movea.l  a3, a0
  02726:  10 2e ff ff          move.b   -$1(a6), d0
  0272a:  a0 6a                dc.w     $a06a  ; _HSetState
  0272c:  30 2e ff fc          move.w   -$4(a6), d0
  02730:  48 c0                ext.l    d0
  02732:  4c ee 18 f0 ff de    movem.l  -$22(a6), d4-d7/a3-a4
  02738:  4e 5e                unlk     a6
  0273a:  4e 75                rts      
  0273c:  4e 56 00 00          link.w   a6, #$0
  02740:  48 e7 0f 00          movem.l  d4-d7, -(a7)
  02744:  2a 2e 00 0c          move.l   $c(a6), d5
  02748:  2c 2e 00 08          move.l   $8(a6), d6
  0274c:  2f 05                move.l   d5, -(a7)
  0274e:  2f 06                move.l   d6, -(a7)
  02750:  61 ff 00 00 08 32    bsr.l    $2f84
  02756:  28 00                move.l   d0, d4
  02758:  7e 00                moveq    #$0, d7
  0275a:  50 4f                addq.w   #$8, a7
  0275c:  2f 05                move.l   d5, -(a7)
  0275e:  70 01                moveq    #$1, d0
  02760:  ef a8                lsl.l    d7, d0
  02762:  2f 00                move.l   d0, -(a7)
  02764:  2f 06                move.l   d6, -(a7)
  02766:  61 ff 00 00 08 60    bsr.l    $2fc8
  0276c:  2f 05                move.l   d5, -(a7)
  0276e:  2f 06                move.l   d6, -(a7)
  02770:  61 ff 00 00 08 12    bsr.l    $2f84
  02776:  72 01                moveq    #$1, d1
  02778:  ef a9                lsl.l    d7, d1
  0277a:  b2 80                cmp.l    d0, d1
  0277c:  4f ef 00 14          lea.l    $14(a7), a7
  02780:  66 62                bne.b    $27e4
  02782:  20 07                move.l   d7, d0
  02784:  52 87                addq.l   #$1, d7
  02786:  70 20                moveq    #$20, d0
  02788:  b0 87                cmp.l    d7, d0
  0278a:  6e d0                bgt.b    $275c
  0278c:  2f 05                move.l   d5, -(a7)
  0278e:  2f 06                move.l   d6, -(a7)
  02790:  2f 06                move.l   d6, -(a7)
  02792:  61 ff 00 00 08 34    bsr.l    $2fc8
  02798:  2f 05                move.l   d5, -(a7)
  0279a:  2f 06                move.l   d6, -(a7)
  0279c:  61 ff 00 00 07 e6    bsr.l    $2f84
  027a2:  bc 80                cmp.l    d0, d6
  027a4:  4f ef 00 14          lea.l    $14(a7), a7
  027a8:  66 3a                bne.b    $27e4
  027aa:  2f 05                move.l   d5, -(a7)
  027ac:  20 06                move.l   d6, d0
  027ae:  46 80                not.l    d0
  027b0:  2f 00                move.l   d0, -(a7)
  027b2:  2f 06                move.l   d6, -(a7)
  027b4:  61 ff 00 00 08 12    bsr.l    $2fc8
  027ba:  2f 05                move.l   d5, -(a7)
  027bc:  2f 06                move.l   d6, -(a7)
  027be:  61 ff 00 00 07 c4    bsr.l    $2f84
  027c4:  22 06                move.l   d6, d1
  027c6:  46 81                not.l    d1
  027c8:  b2 80                cmp.l    d0, d1
  027ca:  4f ef 00 14          lea.l    $14(a7), a7
  027ce:  66 14                bne.b    $27e4
  027d0:  2f 05                move.l   d5, -(a7)
  027d2:  2f 04                move.l   d4, -(a7)
  027d4:  2f 06                move.l   d6, -(a7)
  027d6:  61 ff 00 00 07 f0    bsr.l    $2fc8
  027dc:  70 01                moveq    #$1, d0
  027de:  4f ef 00 0c          lea.l    $c(a7), a7
  027e2:  60 12                bra.b    $27f6
  027e4:  2f 05                move.l   d5, -(a7)
  027e6:  2f 04                move.l   d4, -(a7)
  027e8:  2f 06                move.l   d6, -(a7)
  027ea:  61 ff 00 00 07 dc    bsr.l    $2fc8
  027f0:  70 00                moveq    #$0, d0
  027f2:  4f ef 00 0c          lea.l    $c(a7), a7
  027f6:  4c ee 00 f0 ff f0    movem.l  -$10(a6), d4-d7
  027fc:  4e 5e                unlk     a6
  027fe:  4e 75                rts      
  02800:  4e 56 ff f8          link.w   a6, #$fff8
  02804:  48 e7 0f 00          movem.l  d4-d7, -(a7)
  02808:  28 2e 00 0c          move.l   $c(a6), d4
  0280c:  2a 2e 00 08          move.l   $8(a6), d5
  02810:  2c 2e 00 10          move.l   $10(a6), d6
  02814:  2f 06                move.l   d6, -(a7)
  02816:  2f 05                move.l   d5, -(a7)
  02818:  61 ff 00 00 07 6a    bsr.l    $2f84
  0281e:  2d 40 ff f8          move.l   d0, -$8(a6)
  02822:  2f 06                move.l   d6, -(a7)
  02824:  2f 04                move.l   d4, -(a7)
  02826:  61 ff 00 00 07 5c    bsr.l    $2f84
  0282c:  2d 40 ff fc          move.l   d0, -$4(a6)
  02830:  7e 00                moveq    #$0, d7
  02832:  4f ef 00 10          lea.l    $10(a7), a7
  02836:  2f 06                move.l   d6, -(a7)
  02838:  70 01                moveq    #$1, d0
  0283a:  ef a8                lsl.l    d7, d0
  0283c:  2f 00                move.l   d0, -(a7)
  0283e:  2f 05                move.l   d5, -(a7)
  02840:  61 ff 00 00 07 86    bsr.l    $2fc8
  02846:  2f 06                move.l   d6, -(a7)
  02848:  70 00                moveq    #$0, d0
  0284a:  2f 00                move.l   d0, -(a7)
  0284c:  2f 04                move.l   d4, -(a7)
  0284e:  61 ff 00 00 07 78    bsr.l    $2fc8
  02854:  2f 06                move.l   d6, -(a7)
  02856:  2f 05                move.l   d5, -(a7)
  02858:  61 ff 00 00 07 2a    bsr.l    $2f84
  0285e:  72 01                moveq    #$1, d1
  02860:  ef a9                lsl.l    d7, d1
  02862:  b2 80                cmp.l    d0, d1
  02864:  4f ef 00 20          lea.l    $20(a7), a7
  02868:  66 00 00 90          bne.w    $28fa
  0286c:  20 07                move.l   d7, d0
  0286e:  52 87                addq.l   #$1, d7
  02870:  70 20                moveq    #$20, d0
  02872:  b0 87                cmp.l    d7, d0
  02874:  6e c0                bgt.b    $2836
  02876:  2f 06                move.l   d6, -(a7)
  02878:  2f 05                move.l   d5, -(a7)
  0287a:  2f 05                move.l   d5, -(a7)
  0287c:  61 ff 00 00 07 4a    bsr.l    $2fc8
  02882:  2f 06                move.l   d6, -(a7)
  02884:  20 05                move.l   d5, d0
  02886:  46 80                not.l    d0
  02888:  2f 00                move.l   d0, -(a7)
  0288a:  2f 04                move.l   d4, -(a7)
  0288c:  61 ff 00 00 07 3a    bsr.l    $2fc8
  02892:  2f 06                move.l   d6, -(a7)
  02894:  2f 05                move.l   d5, -(a7)
  02896:  61 ff 00 00 06 ec    bsr.l    $2f84
  0289c:  ba 80                cmp.l    d0, d5
  0289e:  4f ef 00 20          lea.l    $20(a7), a7
  028a2:  66 56                bne.b    $28fa
  028a4:  2f 06                move.l   d6, -(a7)
  028a6:  20 05                move.l   d5, d0
  028a8:  46 80                not.l    d0
  028aa:  2f 00                move.l   d0, -(a7)
  028ac:  2f 05                move.l   d5, -(a7)
  028ae:  61 ff 00 00 07 18    bsr.l    $2fc8
  028b4:  2f 06                move.l   d6, -(a7)
  028b6:  2f 05                move.l   d5, -(a7)
  028b8:  2f 04                move.l   d4, -(a7)
  028ba:  61 ff 00 00 07 0c    bsr.l    $2fc8
  028c0:  2f 06                move.l   d6, -(a7)
  028c2:  2f 05                move.l   d5, -(a7)
  028c4:  61 ff 00 00 06 be    bsr.l    $2f84
  028ca:  22 05                move.l   d5, d1
  028cc:  46 81                not.l    d1
  028ce:  b2 80                cmp.l    d0, d1
  028d0:  4f ef 00 20          lea.l    $20(a7), a7
  028d4:  66 24                bne.b    $28fa
  028d6:  2f 06                move.l   d6, -(a7)
  028d8:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  028dc:  2f 05                move.l   d5, -(a7)
  028de:  61 ff 00 00 06 e8    bsr.l    $2fc8
  028e4:  2f 06                move.l   d6, -(a7)
  028e6:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  028ea:  2f 04                move.l   d4, -(a7)
  028ec:  61 ff 00 00 06 da    bsr.l    $2fc8
  028f2:  70 01                moveq    #$1, d0
  028f4:  4f ef 00 18          lea.l    $18(a7), a7
  028f8:  60 22                bra.b    $291c
  028fa:  2f 06                move.l   d6, -(a7)
  028fc:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  02900:  2f 05                move.l   d5, -(a7)
  02902:  61 ff 00 00 06 c4    bsr.l    $2fc8
  02908:  2f 06                move.l   d6, -(a7)
  0290a:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  0290e:  2f 04                move.l   d4, -(a7)
  02910:  61 ff 00 00 06 b6    bsr.l    $2fc8
  02916:  70 00                moveq    #$0, d0
  02918:  4f ef 00 18          lea.l    $18(a7), a7
  0291c:  4c ee 00 f0 ff e8    movem.l  -$18(a6), d4-d7
  02922:  4e 5e                unlk     a6
  02924:  4e 75                rts      
* ==================================================================
* LoadFirmware
* ==================================================================
* Orchestrates a firmware download: prepares the source/relocation
* context then calls ACEFLoad (twice, for two different inputs -- 
* compare gc24.s's ACEFLoad, called once from its own loader path).
LoadFirmware:
  02926:  4e 56 ff f8          link.w   a6, #$fff8
  0292a:  48 e7 07 18          movem.l  d5-d7/a3-a4, -(a7)
  0292e:  26 6e 00 0c          movea.l  $c(a6), a3
  02932:  28 6e 00 08          movea.l  $8(a6), a4
  02936:  7a 00                moveq    #$0, d5
  02938:  70 00                moveq    #$0, d0
  0293a:  2d 40 ff f8          move.l   d0, -$8(a6)
  0293e:  20 54                movea.l  (a4), a0
  02940:  7e 00                moveq    #$0, d7
  02942:  3e 10                move.w   (a0), d7
  02944:  72 00                moveq    #$0, d1
  02946:  32 28 01 62          move.w   $162(a0), d1
  0294a:  74 7e                moveq    #$7e, d2
  0294c:  b4 81                cmp.l    d1, d2
  0294e:  67 0e                beq.b    $295e
  02950:  70 00                moveq    #$0, d0
  02952:  30 28 01 62          move.w   $162(a0), d0
  02956:  72 2c                moveq    #$2c, d1
  02958:  b2 80                cmp.l    d0, d1
  0295a:  66 00 00 d0          bne.w    $2a2c
  0295e:  20 4b                movea.l  a3, a0
  02960:  a0 69                dc.w     $a069  ; _HGetState
  02962:  1c 00                move.b   d0, d6
  02964:  20 4b                movea.l  a3, a0
  02966:  a0 29                dc.w     $a029  ; _HLock
  02968:  2f 0c                move.l   a4, -(a7)
  0296a:  20 54                movea.l  (a4), a0
  0296c:  2f 28 01 68          move.l   $168(a0), -(a7)
  02970:  59 8f                subq.l   #$4, a7
  02972:  2f 0b                move.l   a3, -(a7)
  02974:  61 ff 00 00 1b ee    bsr.l    $4564
  0297a:  2f 07                move.l   d7, -(a7)
  0297c:  48 6e ff f8          pea.l    -$8(a6)
  02980:  2f 13                move.l   (a3), -(a7)
  02982:  61 ff 00 00 07 28    bsr.l    $30ac  ; -> ACEFLoad
  02988:  2a 00                move.l   d0, d5
  0298a:  4f ef 00 18          lea.l    $18(a7), a7
  0298e:  66 0c                bne.b    $299c
  02990:  20 4b                movea.l  a3, a0
  02992:  10 06                move.b   d6, d0
  02994:  a0 6a                dc.w     $a06a  ; _HSetState
  02996:  70 ff                moveq    #$ff, d0
  02998:  60 00 00 94          bra.w    $2a2e
  0299c:  20 54                movea.l  (a4), a0
  0299e:  2d 68 01 30 ff fc    move.l   $130(a0), -$4(a6)
  029a4:  2f 07                move.l   d7, -(a7)
  029a6:  20 54                movea.l  (a4), a0
  029a8:  2f 28 01 68          move.l   $168(a0), -(a7)
  029ac:  20 2e ff fc          move.l   -$4(a6), d0
  029b0:  72 18                moveq    #$18, d1
  029b2:  d0 81                add.l    d1, d0
  029b4:  2f 00                move.l   d0, -(a7)
  029b6:  61 ff 00 00 06 10    bsr.l    $2fc8
  029bc:  2f 07                move.l   d7, -(a7)
  029be:  2f 07                move.l   d7, -(a7)
  029c0:  2f 05                move.l   d5, -(a7)
  029c2:  61 ff 00 00 05 38    bsr.l    $2efc
  029c8:  50 8f                addq.l   #$8, a7
  029ca:  2f 00                move.l   d0, -(a7)
  029cc:  20 2e ff fc          move.l   -$4(a6), d0
  029d0:  72 0c                moveq    #$c, d1
  029d2:  d0 81                add.l    d1, d0
  029d4:  2f 00                move.l   d0, -(a7)
  029d6:  61 ff 00 00 05 f0    bsr.l    $2fc8
  029dc:  2f 07                move.l   d7, -(a7)
  029de:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  029e2:  20 2e ff fc          move.l   -$4(a6), d0
  029e6:  58 80                addq.l   #$4, d0
  029e8:  2f 00                move.l   d0, -(a7)
  029ea:  61 ff 00 00 05 dc    bsr.l    $2fc8
  029f0:  2f 07                move.l   d7, -(a7)
  029f2:  2f 07                move.l   d7, -(a7)
  029f4:  20 54                movea.l  (a4), a0
  029f6:  2f 28 01 34          move.l   $134(a0), -(a7)
  029fa:  61 ff 00 00 05 00    bsr.l    $2efc
  02a00:  50 8f                addq.l   #$8, a7
  02a02:  2f 00                move.l   d0, -(a7)
  02a04:  20 2e ff fc          move.l   -$4(a6), d0
  02a08:  72 40                moveq    #$40, d1
  02a0a:  d0 81                add.l    d1, d0
  02a0c:  2f 00                move.l   d0, -(a7)
  02a0e:  61 ff 00 00 05 b8    bsr.l    $2fc8
  02a14:  20 4b                movea.l  a3, a0
  02a16:  10 06                move.b   d6, d0
  02a18:  a0 6a                dc.w     $a06a  ; _HSetState
  02a1a:  20 54                movea.l  (a4), a0
  02a1c:  00 a8 00 00 00 02 00 08 ori.l    #$2, $8(a0)
  02a24:  70 00                moveq    #$0, d0
  02a26:  4f ef 00 30          lea.l    $30(a7), a7
  02a2a:  60 02                bra.b    $2a2e
  02a2c:  70 ff                moveq    #$ff, d0
  02a2e:  4c ee 18 e0 ff e4    movem.l  -$1c(a6), d5-d7/a3-a4
  02a34:  4e 5e                unlk     a6
  02a36:  4e 75                rts      
  02a38:  4e 56 00 00          link.w   a6, #$0
  02a3c:  2f 0c                move.l   a4, -(a7)
  02a3e:  28 6e 00 08          movea.l  $8(a6), a4
  02a42:  20 54                movea.l  (a4), a0
  02a44:  70 00                moveq    #$0, d0
  02a46:  30 28 01 62          move.w   $162(a0), d0
  02a4a:  72 7e                moveq    #$7e, d1
  02a4c:  b2 80                cmp.l    d0, d1
  02a4e:  67 0c                beq.b    $2a5c
  02a50:  70 00                moveq    #$0, d0
  02a52:  30 28 01 62          move.w   $162(a0), d0
  02a56:  72 2c                moveq    #$2c, d1
  02a58:  b2 80                cmp.l    d0, d1
  02a5a:  66 6c                bne.b    $2ac8
  02a5c:  20 54                movea.l  (a4), a0
  02a5e:  70 02                moveq    #$2, d0
  02a60:  c0 a8 00 08          and.l    $8(a0), d0
  02a64:  67 5e                beq.b    $2ac4
  02a66:  70 00                moveq    #$0, d0
  02a68:  30 10                move.w   (a0), d0
  02a6a:  2f 00                move.l   d0, -(a7)
  02a6c:  2f 28 01 68          move.l   $168(a0), -(a7)
  02a70:  20 28 01 30          move.l   $130(a0), d0
  02a74:  72 18                moveq    #$18, d1
  02a76:  d0 81                add.l    d1, d0
  02a78:  2f 00                move.l   d0, -(a7)
  02a7a:  61 ff 00 00 05 4c    bsr.l    $2fc8
  02a80:  20 54                movea.l  (a4), a0
  02a82:  70 00                moveq    #$0, d0
  02a84:  30 10                move.w   (a0), d0
  02a86:  2f 00                move.l   d0, -(a7)
  02a88:  70 ff                moveq    #$ff, d0
  02a8a:  2f 00                move.l   d0, -(a7)
  02a8c:  22 28 01 30          move.l   $130(a0), d1
  02a90:  d2 bc 00 00 03 d4    add.l    #$3d4, d1
  02a96:  2f 01                move.l   d1, -(a7)
  02a98:  61 ff 00 00 05 2e    bsr.l    $2fc8
  02a9e:  20 54                movea.l  (a4), a0
  02aa0:  70 00                moveq    #$0, d0
  02aa2:  30 10                move.w   (a0), d0
  02aa4:  2f 00                move.l   d0, -(a7)
  02aa6:  70 ff                moveq    #$ff, d0
  02aa8:  2f 00                move.l   d0, -(a7)
  02aaa:  2f 3c 04 00 00 50    move.l   #$4000050, -(a7)
  02ab0:  61 ff 00 00 05 16    bsr.l    $2fc8
  02ab6:  20 54                movea.l  (a4), a0
  02ab8:  00 a8 00 00 00 04 00 08 ori.l    #$4, $8(a0)
  02ac0:  4f ef 00 24          lea.l    $24(a7), a7
  02ac4:  70 00                moveq    #$0, d0
  02ac6:  60 02                bra.b    $2aca
  02ac8:  70 ff                moveq    #$ff, d0
  02aca:  28 6e ff fc          movea.l  -$4(a6), a4
  02ace:  4e 5e                unlk     a6
  02ad0:  4e 75                rts      
  02ad2:  4e 56 00 00          link.w   a6, #$0
  02ad6:  2f 0c                move.l   a4, -(a7)
  02ad8:  20 6e 00 08          movea.l  $8(a6), a0
  02adc:  28 50                movea.l  (a0), a4
  02ade:  29 7c 00 00 08 00 01 68 move.l   #$800, $168(a4)
  02ae6:  70 20                moveq    #$20, d0
  02ae8:  c0 ac 01 28          and.l    $128(a4), d0
  02aec:  67 08                beq.b    $2af6
  02aee:  00 ac 00 00 00 01 01 68 ori.l    #$1, $168(a4)
  02af6:  70 40                moveq    #$40, d0
  02af8:  c0 ac 01 28          and.l    $128(a4), d0
  02afc:  67 08                beq.b    $2b06
  02afe:  00 ac 00 00 02 00 01 68 ori.l    #$200, $168(a4)
  02b06:  20 3c 00 00 01 00    move.l   #$100, d0
  02b0c:  c0 ac 01 28          and.l    $128(a4), d0
  02b10:  67 08                beq.b    $2b1a
  02b12:  02 ac ff ff f7 ff 01 68 andi.l   #$fffff7ff, $168(a4)
  02b1a:  20 6e 00 0c          movea.l  $c(a6), a0
  02b1e:  4a 28 02 54          tst.b    $254(a0)
  02b22:  67 08                beq.b    $2b2c
  02b24:  00 ac 01 00 00 00 01 68 ori.l    #$1000000, $168(a4)
  02b2c:  30 2c 01 62          move.w   $162(a4), d0
  02b30:  04 40 00 2c          subi.w   #$2c, d0
  02b34:  67 06                beq.b    $2b3c
  02b36:  04 40 00 52          subi.w   #$52, d0
  02b3a:  66 1a                bne.b    $2b56
  02b3c:  00 ac 00 a0 01 20 01 68 ori.l    #$a00120, $168(a4)
  02b44:  0c ac 0d 00 00 00 01 38 cmpi.l   #$d000000, $138(a4)
  02b4c:  63 08                bls.b    $2b56
  02b4e:  00 ac 00 10 00 00 01 68 ori.l    #$100000, $168(a4)
  02b56:  28 6e ff fc          movea.l  -$4(a6), a4
  02b5a:  4e 5e                unlk     a6
  02b5c:  4e 75                rts      
  02b5e:  4e 56 00 00          link.w   a6, #$0
  02b62:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  02b66:  28 2e 00 0c          move.l   $c(a6), d4
  02b6a:  2c 2e 00 08          move.l   $8(a6), d6
  02b6e:  28 6e 00 14          movea.l  $14(a6), a4
  02b72:  20 54                movea.l  (a4), a0
  02b74:  26 68 01 30          movea.l  $130(a0), a3
  02b78:  7e 00                moveq    #$0, d7
  02b7a:  3e 10                move.w   (a0), d7
  02b7c:  20 06                move.l   d6, d0
  02b7e:  d0 bc 00 00 03 ff    add.l    #$3ff, d0
  02b84:  22 3c ff ff fc 00    move.l   #$fffffc00, d1
  02b8a:  c2 80                and.l    d0, d1
  02b8c:  2c 01                move.l   d1, d6
  02b8e:  20 04                move.l   d4, d0
  02b90:  d0 80                add.l    d0, d0
  02b92:  d0 86                add.l    d6, d0
  02b94:  22 2e 00 10          move.l   $10(a6), d1
  02b98:  d2 80                add.l    d0, d1
  02b9a:  d2 bc 00 00 04 00    add.l    #$400, d1
  02ba0:  20 28 01 38          move.l   $138(a0), d0
  02ba4:  90 81                sub.l    d1, d0
  02ba6:  d0 bc 00 00 03 ff    add.l    #$3ff, d0
  02bac:  22 3c ff ff fc 00    move.l   #$fffffc00, d1
  02bb2:  c2 80                and.l    d0, d1
  02bb4:  20 54                movea.l  (a4), a0
  02bb6:  21 41 01 34          move.l   d1, $134(a0)
  02bba:  20 54                movea.l  (a4), a0
  02bbc:  0c a8 0c 00 00 00 01 34 cmpi.l   #$c000000, $134(a0)
  02bc4:  64 0c                bcc.b    $2bd2
  02bc6:  20 54                movea.l  (a4), a0
  02bc8:  70 00                moveq    #$0, d0
  02bca:  21 40 01 34          move.l   d0, $134(a0)
  02bce:  60 00 00 bc          bra.w    $2c8c
  02bd2:  20 54                movea.l  (a4), a0
  02bd4:  2a 28 01 34          move.l   $134(a0), d5
  02bd8:  20 0b                move.l   a3, d0
  02bda:  67 00 00 ae          beq.w    $2c8a
  02bde:  2f 07                move.l   d7, -(a7)
  02be0:  2f 07                move.l   d7, -(a7)
  02be2:  2f 05                move.l   d5, -(a7)
  02be4:  61 ff 00 00 03 16    bsr.l    $2efc
  02bea:  50 8f                addq.l   #$8, a7
  02bec:  2f 00                move.l   d0, -(a7)
  02bee:  20 0b                move.l   a3, d0
  02bf0:  72 20                moveq    #$20, d1
  02bf2:  d0 81                add.l    d1, d0
  02bf4:  2f 00                move.l   d0, -(a7)
  02bf6:  61 ff 00 00 03 d0    bsr.l    $2fc8
  02bfc:  2f 07                move.l   d7, -(a7)
  02bfe:  20 54                movea.l  (a4), a0
  02c00:  70 00                moveq    #$0, d0
  02c02:  30 10                move.w   (a0), d0
  02c04:  2f 00                move.l   d0, -(a7)
  02c06:  20 06                move.l   d6, d0
  02c08:  d0 84                add.l    d4, d0
  02c0a:  22 2e 00 10          move.l   $10(a6), d1
  02c0e:  d2 80                add.l    d0, d1
  02c10:  d2 85                add.l    d5, d1
  02c12:  2f 01                move.l   d1, -(a7)
  02c14:  61 ff 00 00 02 e6    bsr.l    $2efc
  02c1a:  50 8f                addq.l   #$8, a7
  02c1c:  2f 00                move.l   d0, -(a7)
  02c1e:  20 0b                move.l   a3, d0
  02c20:  72 24                moveq    #$24, d1
  02c22:  d0 81                add.l    d1, d0
  02c24:  2f 00                move.l   d0, -(a7)
  02c26:  61 ff 00 00 03 a0    bsr.l    $2fc8
  02c2c:  2f 07                move.l   d7, -(a7)
  02c2e:  2f 06                move.l   d6, -(a7)
  02c30:  20 0b                move.l   a3, d0
  02c32:  72 28                moveq    #$28, d1
  02c34:  d0 81                add.l    d1, d0
  02c36:  2f 00                move.l   d0, -(a7)
  02c38:  61 ff 00 00 03 8e    bsr.l    $2fc8
  02c3e:  2f 07                move.l   d7, -(a7)
  02c40:  2f 04                move.l   d4, -(a7)
  02c42:  20 0b                move.l   a3, d0
  02c44:  72 2c                moveq    #$2c, d1
  02c46:  d0 81                add.l    d1, d0
  02c48:  2f 00                move.l   d0, -(a7)
  02c4a:  61 ff 00 00 03 7c    bsr.l    $2fc8
  02c50:  2f 07                move.l   d7, -(a7)
  02c52:  2f 2e 00 10          move.l   $10(a6), -(a7)
  02c56:  20 0b                move.l   a3, d0
  02c58:  72 30                moveq    #$30, d1
  02c5a:  d0 81                add.l    d1, d0
  02c5c:  2f 00                move.l   d0, -(a7)
  02c5e:  61 ff 00 00 03 68    bsr.l    $2fc8
  02c64:  2f 07                move.l   d7, -(a7)
  02c66:  2f 07                move.l   d7, -(a7)
  02c68:  20 54                movea.l  (a4), a0
  02c6a:  2f 28 01 34          move.l   $134(a0), -(a7)
  02c6e:  61 ff 00 00 02 8c    bsr.l    $2efc
  02c74:  50 8f                addq.l   #$8, a7
  02c76:  2f 00                move.l   d0, -(a7)
  02c78:  20 0b                move.l   a3, d0
  02c7a:  72 40                moveq    #$40, d1
  02c7c:  d0 81                add.l    d1, d0
  02c7e:  2f 00                move.l   d0, -(a7)
  02c80:  61 ff 00 00 03 46    bsr.l    $2fc8
  02c86:  4f ef 00 48          lea.l    $48(a7), a7
  02c8a:  20 05                move.l   d5, d0
  02c8c:  4c ee 18 f0 ff e8    movem.l  -$18(a6), d4-d7/a3-a4
  02c92:  4e 5e                unlk     a6
  02c94:  4e 75                rts      
  02c96:  4e 56 00 00          link.w   a6, #$0
  02c9a:  48 e7 03 08          movem.l  d6-d7/a4, -(a7)
  02c9e:  2c 2e 00 10          move.l   $10(a6), d6
  02ca2:  2e 2e 00 0c          move.l   $c(a6), d7
  02ca6:  20 6e 00 14          movea.l  $14(a6), a0
  02caa:  28 50                movea.l  (a0), a4
  02cac:  70 07                moveq    #$7, d0
  02cae:  2f 00                move.l   d0, -(a7)
  02cb0:  48 7a 00 80          pea.l    $2d32(pc)
  02cb4:  2f 2e 00 08          move.l   $8(a6), -(a7)
  02cb8:  61 ff 00 00 03 a8    bsr.l    $3062
  02cbe:  4a 80                tst.l    d0
  02cc0:  4f ef 00 0c          lea.l    $c(a7), a7
  02cc4:  66 32                bne.b    $2cf8
  02cc6:  be ac 01 54          cmp.l    $154(a4), d7
  02cca:  67 06                beq.b    $2cd2
  02ccc:  4a ac 01 54          tst.l    $154(a4)
  02cd0:  66 06                bne.b    $2cd8
  02cd2:  29 47 01 54          move.l   d7, $154(a4)
  02cd6:  60 06                bra.b    $2cde
  02cd8:  70 ff                moveq    #$ff, d0
  02cda:  29 40 01 54          move.l   d0, $154(a4)
  02cde:  bc ac 01 58          cmp.l    $158(a4), d6
  02ce2:  67 06                beq.b    $2cea
  02ce4:  4a ac 01 58          tst.l    $158(a4)
  02ce8:  66 06                bne.b    $2cf0
  02cea:  29 46 01 58          move.l   d6, $158(a4)
  02cee:  60 38                bra.b    $2d28
  02cf0:  70 ff                moveq    #$ff, d0
  02cf2:  29 40 01 58          move.l   d0, $158(a4)
  02cf6:  60 30                bra.b    $2d28
  02cf8:  be ac 01 4c          cmp.l    $14c(a4), d7
  02cfc:  67 06                beq.b    $2d04
  02cfe:  4a ac 01 4c          tst.l    $14c(a4)
  02d02:  66 06                bne.b    $2d0a
  02d04:  29 47 01 4c          move.l   d7, $14c(a4)
  02d08:  60 06                bra.b    $2d10
  02d0a:  70 ff                moveq    #$ff, d0
  02d0c:  29 40 01 4c          move.l   d0, $14c(a4)
  02d10:  bc ac 01 50          cmp.l    $150(a4), d6
  02d14:  67 06                beq.b    $2d1c
  02d16:  4a ac 01 50          tst.l    $150(a4)
  02d1a:  66 06                bne.b    $2d22
  02d1c:  29 46 01 50          move.l   d6, $150(a4)
  02d20:  60 06                bra.b    $2d28
  02d22:  70 ff                moveq    #$ff, d0
  02d24:  29 40 01 50          move.l   d0, $150(a4)
  02d28:  4c ee 10 c0 ff f4    movem.l  -$c(a6), d6-d7/a4
  02d2e:  4e 5e                unlk     a6
  02d30:  4e 75                rts      
  02d32:  52 75 6e 74          addq.w   #$1, $74(a5, d6.l)
  02d36:  69 6d                bvs.b    $2da5
  02d38:  65 00 4e 56          bcs.w    $7b90
  02d3c:  00 00 70 00          ori.b    #$0, d0
  02d40:  4e 5e                unlk     a6
  02d42:  4e 75                rts      
  02d44:  4e 56 ff f8          link.w   a6, #$fff8
  02d48:  48 e7 07 18          movem.l  d5-d7/a3-a4, -(a7)
  02d4c:  2a 2e 00 08          move.l   $8(a6), d5
  02d50:  2e 2e 00 10          move.l   $10(a6), d7
  02d54:  2f 07                move.l   d7, -(a7)
  02d56:  20 2e 00 14          move.l   $14(a6), d0
  02d5a:  d0 bc 00 00 04 10    add.l    #$410, d0
  02d60:  2f 00                move.l   d0, -(a7)
  02d62:  61 ff 00 00 02 20    bsr.l    $2f84
  02d68:  2d 40 ff f8          move.l   d0, -$8(a6)
  02d6c:  d0 bc 00 00 10 00    add.l    #$1000, d0
  02d72:  2d 40 ff fc          move.l   d0, -$4(a6)
  02d76:  20 05                move.l   d5, d0
  02d78:  52 80                addq.l   #$1, d0
  02d7a:  e5 80                asl.l    #$2, d0
  02d7c:  28 40                movea.l  d0, a4
  02d7e:  d9 ee ff f8          adda.l   -$8(a6), a4
  02d82:  7c 00                moveq    #$0, d6
  02d84:  50 4f                addq.w   #$8, a7
  02d86:  60 66                bra.b    $2dee
  02d88:  2f 07                move.l   d7, -(a7)
  02d8a:  2f 07                move.l   d7, -(a7)
  02d8c:  2f 0c                move.l   a4, -(a7)
  02d8e:  61 ff 00 00 01 6c    bsr.l    $2efc
  02d94:  50 8f                addq.l   #$8, a7
  02d96:  2f 00                move.l   d0, -(a7)
  02d98:  20 2e ff f8          move.l   -$8(a6), d0
  02d9c:  58 ae ff f8          addq.l   #$4, -$8(a6)
  02da0:  2f 00                move.l   d0, -(a7)
  02da2:  61 ff 00 00 02 24    bsr.l    $2fc8
  02da8:  20 6e 00 0c          movea.l  $c(a6), a0
  02dac:  26 70 6c 00          movea.l  (a0, d6.l * 4), a3
  02db0:  4f ef 00 0c          lea.l    $c(a7), a7
  02db4:  60 1a                bra.b    $2dd0
  02db6:  2f 07                move.l   d7, -(a7)
  02db8:  10 13                move.b   (a3), d0
  02dba:  49 c0                extb.l   d0
  02dbc:  2f 00                move.l   d0, -(a7)
  02dbe:  2f 0c                move.l   a4, -(a7)
  02dc0:  52 4c                addq.w   #$1, a4
  02dc2:  61 ff 00 00 01 76    bsr.l    $2f3a
  02dc8:  4a 1b                tst.b    (a3)+
  02dca:  4f ef 00 0c          lea.l    $c(a7), a7
  02dce:  67 06                beq.b    $2dd6
  02dd0:  b9 ee ff fc          cmpa.l   -$4(a6), a4
  02dd4:  65 e0                bcs.b    $2db6
  02dd6:  20 0c                move.l   a4, d0
  02dd8:  56 80                addq.l   #$3, d0
  02dda:  72 fc                moveq    #$fc, d1
  02ddc:  c2 80                and.l    d0, d1
  02dde:  28 41                movea.l  d1, a4
  02de0:  b9 ee ff fc          cmpa.l   -$4(a6), a4
  02de4:  65 04                bcs.b    $2dea
  02de6:  70 ff                moveq    #$ff, d0
  02de8:  60 24                bra.b    $2e0e
  02dea:  20 06                move.l   d6, d0
  02dec:  52 86                addq.l   #$1, d6
  02dee:  ba 86                cmp.l    d6, d5
  02df0:  6e 96                bgt.b    $2d88
  02df2:  2f 07                move.l   d7, -(a7)
  02df4:  70 00                moveq    #$0, d0
  02df6:  2f 00                move.l   d0, -(a7)
  02df8:  22 2e ff f8          move.l   -$8(a6), d1
  02dfc:  58 ae ff f8          addq.l   #$4, -$8(a6)
  02e00:  2f 01                move.l   d1, -(a7)
  02e02:  61 ff 00 00 01 c4    bsr.l    $2fc8
  02e08:  70 00                moveq    #$0, d0
  02e0a:  4f ef 00 0c          lea.l    $c(a7), a7
  02e0e:  4c ee 18 e0 ff e4    movem.l  -$1c(a6), d5-d7/a3-a4
  02e14:  4e 5e                unlk     a6
  02e16:  4e 75                rts      
  02e18:  4e 56 ff fe          link.w   a6, #$fffe
  02e1c:  48 e7 01 08          movem.l  d7/a4, -(a7)
  02e20:  2e 2e 00 0c          move.l   $c(a6), d7
  02e24:  28 6e 00 08          movea.l  $8(a6), a4
  02e28:  1d 7c 00 01 ff ff    move.b   #$1, -$1(a6)
  02e2e:  e4 8f                lsr.l    #$2, d7
  02e30:  2f 2e 00 10          move.l   $10(a6), -(a7)
  02e34:  2f 0c                move.l   a4, -(a7)
  02e36:  61 ff 00 00 00 c4    bsr.l    $2efc
  02e3c:  28 40                movea.l  d0, a4
  02e3e:  41 ee ff ff          lea.l    -$1(a6), a0
  02e42:  10 10                move.b   (a0), d0
  02e44:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  02e46:  10 80                move.b   d0, (a0)
  02e48:  50 4f                addq.w   #$8, a7
  02e4a:  60 28                bra.b    $2e74
  02e4c:  70 00                moveq    #$0, d0
  02e4e:  28 c0                move.l   d0, (a4)+
  02e50:  28 c0                move.l   d0, (a4)+
  02e52:  28 c0                move.l   d0, (a4)+
  02e54:  28 c0                move.l   d0, (a4)+
  02e56:  28 c0                move.l   d0, (a4)+
  02e58:  28 c0                move.l   d0, (a4)+
  02e5a:  28 c0                move.l   d0, (a4)+
  02e5c:  28 c0                move.l   d0, (a4)+
  02e5e:  28 c0                move.l   d0, (a4)+
  02e60:  28 c0                move.l   d0, (a4)+
  02e62:  28 c0                move.l   d0, (a4)+
  02e64:  28 c0                move.l   d0, (a4)+
  02e66:  28 c0                move.l   d0, (a4)+
  02e68:  28 c0                move.l   d0, (a4)+
  02e6a:  28 c0                move.l   d0, (a4)+
  02e6c:  28 c0                move.l   d0, (a4)+
  02e6e:  04 87 00 00 00 10    subi.l   #$10, d7
  02e74:  70 10                moveq    #$10, d0
  02e76:  b0 87                cmp.l    d7, d0
  02e78:  65 d2                bcs.b    $2e4c
  02e7a:  60 04                bra.b    $2e80
  02e7c:  70 00                moveq    #$0, d0
  02e7e:  28 c0                move.l   d0, (a4)+
  02e80:  20 07                move.l   d7, d0
  02e82:  53 87                subq.l   #$1, d7
  02e84:  4a 80                tst.l    d0
  02e86:  66 f4                bne.b    $2e7c
  02e88:  41 ee ff ff          lea.l    -$1(a6), a0
  02e8c:  10 10                move.b   (a0), d0
  02e8e:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  02e90:  10 80                move.b   d0, (a0)
  02e92:  4c ee 10 80 ff f6    movem.l  -$a(a6), d7/a4
  02e98:  4e 5e                unlk     a6
  02e9a:  4e 75                rts      
  02e9c:  4e 56 00 00          link.w   a6, #$0
  02ea0:  48 e7 03 08          movem.l  d6-d7/a4, -(a7)
  02ea4:  2c 2e 00 08          move.l   $8(a6), d6
  02ea8:  a1 1a                dc.w     $a11a  ; _GetZone
  02eaa:  28 48                movea.l  a0, a4
  02eac:  20 78 02 a6          movea.l  $2a6.w, a0
  02eb0:  a0 1b                dc.w     $a01b  ; _SetZone
  02eb2:  4a 86                tst.l    d6
  02eb4:  67 1c                beq.b    $2ed2
  02eb6:  20 06                move.l   d6, d0
  02eb8:  a1 1e                dc.w     $a11e  ; _NewPtr
  02eba:  2e 08                move.l   a0, d7
  02ebc:  66 0c                bne.b    $2eca
  02ebe:  20 78 02 aa          movea.l  $2aa.w, a0
  02ec2:  a0 1b                dc.w     $a01b  ; _SetZone
  02ec4:  20 06                move.l   d6, d0
  02ec6:  a1 1e                dc.w     $a11e  ; _NewPtr
  02ec8:  2e 08                move.l   a0, d7
  02eca:  20 4c                movea.l  a4, a0
  02ecc:  a0 1b                dc.w     $a01b  ; _SetZone
  02ece:  20 07                move.l   d7, d0
  02ed0:  60 06                bra.b    $2ed8
  02ed2:  20 4c                movea.l  a4, a0
  02ed4:  a0 1b                dc.w     $a01b  ; _SetZone
  02ed6:  70 00                moveq    #$0, d0
  02ed8:  4c ee 10 c0 ff f4    movem.l  -$c(a6), d6-d7/a4
  02ede:  4e 5e                unlk     a6
  02ee0:  4e 75                rts      
  02ee2:  4e 56 00 00          link.w   a6, #$0
  02ee6:  2f 0c                move.l   a4, -(a7)
  02ee8:  28 6e 00 08          movea.l  $8(a6), a4
  02eec:  20 0c                move.l   a4, d0
  02eee:  67 04                beq.b    $2ef4
  02ef0:  20 4c                movea.l  a4, a0
  02ef2:  a0 1f                dc.w     $a01f  ; _DisposPtr
  02ef4:  28 6e ff fc          movea.l  -$4(a6), a4
  02ef8:  4e 5e                unlk     a6
  02efa:  4e 75                rts      
  02efc:  4e 56 00 00          link.w   a6, #$0
  02f00:  2f 0c                move.l   a4, -(a7)
  02f02:  28 6e 00 08          movea.l  $8(a6), a4
  02f06:  20 0c                move.l   a4, d0
  02f08:  22 3c f0 00 00 00    move.l   #$f0000000, d1
  02f0e:  c2 80                and.l    d0, d1
  02f10:  0c 81 f0 00 00 00    cmpi.l   #$f0000000, d1
  02f16:  66 04                bne.b    $2f1c
  02f18:  20 0c                move.l   a4, d0
  02f1a:  60 16                bra.b    $2f32
  02f1c:  20 0c                move.l   a4, d0
  02f1e:  22 3c 0f ff ff ff    move.l   #$fffffff, d1
  02f24:  c2 80                and.l    d0, d1
  02f26:  70 1c                moveq    #$1c, d0
  02f28:  24 2e 00 0c          move.l   $c(a6), d2
  02f2c:  e1 aa                lsl.l    d0, d2
  02f2e:  d4 81                add.l    d1, d2
  02f30:  20 02                move.l   d2, d0
  02f32:  28 6e ff fc          movea.l  -$4(a6), a4
  02f36:  4e 5e                unlk     a6
  02f38:  4e 75                rts      
  02f3a:  4e 56 ff fe          link.w   a6, #$fffe
  02f3e:  2f 07                move.l   d7, -(a7)
  02f40:  2e 2e 00 08          move.l   $8(a6), d7
  02f44:  1d 7c 00 01 ff ff    move.b   #$1, -$1(a6)
  02f4a:  2f 2e 00 10          move.l   $10(a6), -(a7)
  02f4e:  2f 07                move.l   d7, -(a7)
  02f50:  61 ff ff ff ff aa    bsr.l    $2efc
  02f56:  2e 00                move.l   d0, d7
  02f58:  41 ee ff ff          lea.l    -$1(a6), a0
  02f5c:  10 10                move.b   (a0), d0
  02f5e:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  02f60:  10 80                move.b   d0, (a0)
  02f62:  10 2e 00 0f          move.b   $f(a6), d0
  02f66:  48 80                ext.w    d0
  02f68:  32 3c 00 ff          move.w   #$ff, d1
  02f6c:  c2 00                and.b    d0, d1
  02f6e:  20 47                movea.l  d7, a0
  02f70:  10 81                move.b   d1, (a0)
  02f72:  41 ee ff ff          lea.l    -$1(a6), a0
  02f76:  10 10                move.b   (a0), d0
  02f78:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  02f7a:  10 80                move.b   d0, (a0)
  02f7c:  2e 2e ff fa          move.l   -$6(a6), d7
  02f80:  4e 5e                unlk     a6
  02f82:  4e 75                rts      
  02f84:  4e 56 ff fe          link.w   a6, #$fffe
  02f88:  48 e7 01 08          movem.l  d7/a4, -(a7)
  02f8c:  1d 7c 00 01 ff ff    move.b   #$1, -$1(a6)
  02f92:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  02f96:  2f 2e 00 08          move.l   $8(a6), -(a7)
  02f9a:  61 ff ff ff ff 60    bsr.l    $2efc
  02fa0:  72 fc                moveq    #$fc, d1
  02fa2:  c2 80                and.l    d0, d1
  02fa4:  28 41                movea.l  d1, a4
  02fa6:  41 ee ff ff          lea.l    -$1(a6), a0
  02faa:  10 10                move.b   (a0), d0
  02fac:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  02fae:  10 80                move.b   d0, (a0)
  02fb0:  2e 14                move.l   (a4), d7
  02fb2:  41 ee ff ff          lea.l    -$1(a6), a0
  02fb6:  10 10                move.b   (a0), d0
  02fb8:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  02fba:  10 80                move.b   d0, (a0)
  02fbc:  20 07                move.l   d7, d0
  02fbe:  4c ee 10 80 ff f6    movem.l  -$a(a6), d7/a4
  02fc4:  4e 5e                unlk     a6
  02fc6:  4e 75                rts      
  02fc8:  4e 56 ff fe          link.w   a6, #$fffe
  02fcc:  2f 0c                move.l   a4, -(a7)
  02fce:  1d 7c 00 01 ff ff    move.b   #$1, -$1(a6)
  02fd4:  2f 2e 00 10          move.l   $10(a6), -(a7)
  02fd8:  2f 2e 00 08          move.l   $8(a6), -(a7)
  02fdc:  61 ff ff ff ff 1e    bsr.l    $2efc
  02fe2:  72 fc                moveq    #$fc, d1
  02fe4:  c2 80                and.l    d0, d1
  02fe6:  28 41                movea.l  d1, a4
  02fe8:  41 ee ff ff          lea.l    -$1(a6), a0
  02fec:  10 10                move.b   (a0), d0
  02fee:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  02ff0:  10 80                move.b   d0, (a0)
  02ff2:  28 ae 00 0c          move.l   $c(a6), (a4)
  02ff6:  41 ee ff ff          lea.l    -$1(a6), a0
  02ffa:  10 10                move.b   (a0), d0
  02ffc:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  02ffe:  10 80                move.b   d0, (a0)
  03000:  28 6e ff fa          movea.l  -$6(a6), a4
  03004:  4e 5e                unlk     a6
  03006:  4e 75                rts      
  03008:  4e 56 00 00          link.w   a6, #$0
  0300c:  48 e7 01 08          movem.l  d7/a4, -(a7)
  03010:  1e 2e 00 0f          move.b   $f(a6), d7
  03014:  28 6e 00 08          movea.l  $8(a6), a4
  03018:  60 0a                bra.b    $3024
  0301a:  be 14                cmp.b    (a4), d7
  0301c:  66 04                bne.b    $3022
  0301e:  20 0c                move.l   a4, d0
  03020:  60 08                bra.b    $302a
  03022:  52 4c                addq.w   #$1, a4
  03024:  4a 14                tst.b    (a4)
  03026:  66 f2                bne.b    $301a
  03028:  70 00                moveq    #$0, d0
  0302a:  4c ee 10 80 ff f8    movem.l  -$8(a6), d7/a4
  03030:  4e 5e                unlk     a6
  03032:  4e 75                rts      
  03034:  4e 56 00 00          link.w   a6, #$0
  03038:  48 e7 00 18          movem.l  a3-a4, -(a7)
  0303c:  26 6e 00 0c          movea.l  $c(a6), a3
  03040:  28 6e 00 08          movea.l  $8(a6), a4
  03044:  4a 14                tst.b    (a4)
  03046:  67 04                beq.b    $304c
  03048:  b9 0b                cmpm.b   (a3)+, (a4)+
  0304a:  67 f8                beq.b    $3044
  0304c:  10 24                move.b   -(a4), d0
  0304e:  48 80                ext.w    d0
  03050:  12 23                move.b   -(a3), d1
  03052:  48 81                ext.w    d1
  03054:  90 41                sub.w    d1, d0
  03056:  48 c0                ext.l    d0
  03058:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  0305e:  4e 5e                unlk     a6
  03060:  4e 75                rts      
  03062:  4e 56 00 00          link.w   a6, #$0
  03066:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  0306a:  2e 2e 00 10          move.l   $10(a6), d7
  0306e:  26 6e 00 0c          movea.l  $c(a6), a3
  03072:  28 6e 00 08          movea.l  $8(a6), a4
  03076:  4a 14                tst.b    (a4)
  03078:  67 0c                beq.b    $3086
  0307a:  b9 0b                cmpm.b   (a3)+, (a4)+
  0307c:  66 08                bne.b    $3086
  0307e:  20 07                move.l   d7, d0
  03080:  53 87                subq.l   #$1, d7
  03082:  4a 80                tst.l    d0
  03084:  66 f0                bne.b    $3076
  03086:  10 24                move.b   -(a4), d0
  03088:  48 80                ext.w    d0
  0308a:  12 23                move.b   -(a3), d1
  0308c:  48 81                ext.w    d1
  0308e:  90 41                sub.w    d1, d0
  03090:  48 c0                ext.l    d0
  03092:  4c ee 18 80 ff f4    movem.l  -$c(a6), d7/a3-a4
  03098:  4e 5e                unlk     a6
  0309a:  4e 75                rts      
  0309c:  4e 56 00 00          link.w   a6, #$0
  030a0:  4e 5e                unlk     a6
  030a2:  4e 75                rts      
  030a4:  4e 56 00 00          link.w   a6, #$0
  030a8:  4e 5e                unlk     a6
  030aa:  4e 75                rts      
* ==================================================================
* ACEFLoad
* ==================================================================
* This DRVR's own copy of the ACEF (Am29000 COFF) loader -- same
* $FEBA-byte stack frame / structural shape as gc24.s's ACEFLoad (see
* ../control-panel/gc24.s and firmware/README.md for the ACEF file
* format: 20-byte header with a magic 0x12A/0x12B and an obfuscation
* key, an optional header, N section headers, then section data).
* Not re-diagrammed line-by-line here; see gc24.s's ACEFLoad for the
* fully-commented twin of this routine (this copy checks the same
* 0x12A/0x12B magic at file-relative $3162/$3170).
ACEFLoad:
  030ac:  4e 56 fe ba          link.w   a6, #$feba
  030b0:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  030b4:  1d 7c 00 01 fe dd    move.b   #$1, -$123(a6)
  030ba:  70 00                moveq    #$0, d0
  030bc:  2d 40 fe ee          move.l   d0, -$112(a6)
  030c0:  42 2e ff d7          clr.b    -$29(a6)
  030c4:  2d 40 ff e4          move.l   d0, -$1c(a6)
  030c8:  2d 40 ff ec          move.l   d0, -$14(a6)
  030cc:  1d 7c 00 01 ff f5    move.b   #$1, -$b(a6)
  030d2:  42 6e ff f6          clr.w    -$a(a6)
  030d6:  2d 40 ff fc          move.l   d0, -$4(a6)
  030da:  4a ae 00 0c          tst.l    $c(a6)
  030de:  67 18                beq.b    $30f8
  030e0:  2f 2e 00 10          move.l   $10(a6), -(a7)
  030e4:  20 6e 00 0c          movea.l  $c(a6), a0
  030e8:  2f 10                move.l   (a0), -(a7)
  030ea:  61 ff ff ff fe 10    bsr.l    $2efc
  030f0:  2d 40 ff f0          move.l   d0, -$10(a6)
  030f4:  50 4f                addq.w   #$8, a7
  030f6:  60 14                bra.b    $310c
  030f8:  2f 2e 00 10          move.l   $10(a6), -(a7)
  030fc:  70 00                moveq    #$0, d0
  030fe:  2f 00                move.l   d0, -(a7)
  03100:  61 ff ff ff fd fa    bsr.l    $2efc
  03106:  2d 40 ff f0          move.l   d0, -$10(a6)
  0310a:  50 4f                addq.w   #$8, a7
  0310c:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  03110:  61 ff ff ff fc 28    bsr.l    $2d3a
  03116:  2d 40 ff be          move.l   d0, -$42(a6)
  0311a:  58 4f                addq.w   #$4, a7
  0311c:  67 12                beq.b    $3130
  0311e:  48 7a 13 f8          pea.l    $4518(pc)
  03122:  61 ff ff ff ff 78    bsr.l    $309c
  03128:  70 00                moveq    #$0, d0
  0312a:  58 4f                addq.w   #$4, a7
  0312c:  60 00 10 cc          bra.w    $41fa
  03130:  2d 6e 00 08 fe d8    move.l   $8(a6), -$128(a6)
  03136:  20 2e 00 14          move.l   $14(a6), d0
  0313a:  d0 ae 00 08          add.l    $8(a6), d0
  0313e:  2d 40 ff d2          move.l   d0, -$2e(a6)
  03142:  20 6e fe d8          movea.l  -$128(a6), a0
  03146:  43 ee ff 22          lea.l    -$de(a6), a1
  0314a:  70 04                moveq    #$4, d0
  0314c:  22 d8                move.l   (a0)+, (a1)+
  0314e:  51 c8 ff fc          dbra     d0, $314c
  03152:  06 ae 00 00 00 14 fe d8 addi.l   #$14, -$128(a6)
  0315a:  70 00                moveq    #$0, d0
  0315c:  30 2e ff 22          move.w   -$de(a6), d0
  03160:  0c 80 00 00 01 2a    cmpi.l   #$12a, d0
  03166:  67 58                beq.b    $31c0
  03168:  70 00                moveq    #$0, d0
  0316a:  30 2e ff 22          move.w   -$de(a6), d0
  0316e:  0c 80 00 00 01 2b    cmpi.l   #$12b, d0
  03174:  67 12                beq.b    $3188
  03176:  48 7a 13 8c          pea.l    $4504(pc)
  0317a:  61 ff ff ff ff 20    bsr.l    $309c
  03180:  70 00                moveq    #$0, d0
  03182:  58 4f                addq.w   #$4, a7
  03184:  60 00 10 74          bra.w    $41fa
  03188:  1d 6e ff 29 ff f6    move.b   -$d7(a6), -$a(a6)
  0318e:  70 20                moveq    #$20, d0
  03190:  2f 00                move.l   d0, -(a7)
  03192:  22 2e fe d8          move.l   -$128(a6), d1
  03196:  74 44                moveq    #$44, d2
  03198:  d2 82                add.l    d2, d1
  0319a:  2f 01                move.l   d1, -(a7)
  0319c:  48 7a 13 30          pea.l    $44ce(pc)
  031a0:  61 ff ff ff fe c0    bsr.l    $3062
  031a6:  4a 80                tst.l    d0
  031a8:  4f ef 00 0c          lea.l    $c(a7), a7
  031ac:  67 12                beq.b    $31c0
  031ae:  48 7a 13 0e          pea.l    $44be(pc)
  031b2:  61 ff ff ff fe e8    bsr.l    $309c
  031b8:  70 00                moveq    #$0, d0
  031ba:  58 4f                addq.w   #$4, a7
  031bc:  60 00 10 3c          bra.w    $41fa
  031c0:  20 6e fe d8          movea.l  -$128(a6), a0
  031c4:  43 ee ff 36          lea.l    -$ca(a6), a1
  031c8:  70 10                moveq    #$10, d0
  031ca:  22 d8                move.l   (a0)+, (a1)+
  031cc:  51 c8 ff fc          dbra     d0, $31ca
  031d0:  4a 2e ff f6          tst.b    -$a(a6)
  031d4:  67 4a                beq.b    $3220
  031d6:  20 2e fe d8          move.l   -$128(a6), d0
  031da:  90 ae 00 08          sub.l    $8(a6), d0
  031de:  1d 40 ff f7          move.b   d0, -$9(a6)
  031e2:  70 00                moveq    #$0, d0
  031e4:  2d 40 ff c6          move.l   d0, -$3a(a6)
  031e8:  41 ee ff 36          lea.l    -$ca(a6), a0
  031ec:  2d 48 ff f8          move.l   a0, -$8(a6)
  031f0:  60 1e                bra.b    $3210
  031f2:  20 6e ff f8          movea.l  -$8(a6), a0
  031f6:  52 ae ff f8          addq.l   #$1, -$8(a6)
  031fa:  10 2e ff f7          move.b   -$9(a6), d0
  031fe:  b1 10                eor.b    d0, (a0)
  03200:  20 2e ff c6          move.l   -$3a(a6), d0
  03204:  52 ae ff c6          addq.l   #$1, -$3a(a6)
  03208:  10 2e ff f6          move.b   -$a(a6), d0
  0320c:  d1 2e ff f7          add.b    d0, -$9(a6)
  03210:  70 44                moveq    #$44, d0
  03212:  b0 ae ff c6          cmp.l    -$3a(a6), d0
  03216:  62 da                bhi.b    $31f2
  03218:  06 ae 00 00 00 40 fe d8 addi.l   #$40, -$128(a6)
  03220:  06 ae 00 00 00 44 fe d8 addi.l   #$44, -$128(a6)
  03228:  2f 2e 00 1c          move.l   $1c(a6), -(a7)
  0322c:  2f 2e ff 4e          move.l   -$b2(a6), -(a7)
  03230:  2f 2e ff 4a          move.l   -$b6(a6), -(a7)
  03234:  48 6e ff 52          pea.l    -$ae(a6)
  03238:  61 ff ff ff fa 5c    bsr.l    $2c96
  0323e:  2f 2e ff 4e          move.l   -$b2(a6), -(a7)
  03242:  2f 2e ff 4a          move.l   -$b6(a6), -(a7)
  03246:  48 6e ff 52          pea.l    -$ae(a6)
  0324a:  48 7a 12 4e          pea.l    $449a(pc)
  0324e:  61 ff ff ff fe 54    bsr.l    $30a4
  03254:  70 00                moveq    #$0, d0
  03256:  30 2e ff 34          move.w   -$cc(a6), d0
  0325a:  72 02                moveq    #$2, d1
  0325c:  c2 40                and.w    d0, d1
  0325e:  4f ef 00 20          lea.l    $20(a7), a7
  03262:  66 0c                bne.b    $3270
  03264:  70 00                moveq    #$0, d0
  03266:  30 2e ff 34          move.w   -$cc(a6), d0
  0326a:  72 01                moveq    #$1, d1
  0326c:  c2 40                and.w    d0, d1
  0326e:  67 04                beq.b    $3274
  03270:  42 2e ff f5          clr.b    -$b(a6)
  03274:  70 00                moveq    #$0, d0
  03276:  30 2e ff 34          move.w   -$cc(a6), d0
  0327a:  2f 00                move.l   d0, -(a7)
  0327c:  2f 2e ff 2e          move.l   -$d2(a6), -(a7)
  03280:  70 00                moveq    #$0, d0
  03282:  30 2e ff 24          move.w   -$dc(a6), d0
  03286:  2f 00                move.l   d0, -(a7)
  03288:  70 00                moveq    #$0, d0
  0328a:  30 2e ff 22          move.w   -$de(a6), d0
  0328e:  2f 00                move.l   d0, -(a7)
  03290:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  03294:  48 7a 11 c2          pea.l    $4458(pc)
  03298:  61 ff ff ff fe 0a    bsr.l    $30a4
  0329e:  20 2e fe d8          move.l   -$128(a6), d0
  032a2:  90 ae 00 08          sub.l    $8(a6), d0
  032a6:  2d 40 fe f6          move.l   d0, -$10a(a6)
  032aa:  2d 6e ff 2e ff e0    move.l   -$d2(a6), -$20(a6)
  032b0:  4f ef 00 18          lea.l    $18(a7), a7
  032b4:  67 56                beq.b    $330c
  032b6:  59 8f                subq.l   #$4, a7
  032b8:  22 2e ff e0          move.l   -$20(a6), d1
  032bc:  d2 81                add.l    d1, d1
  032be:  20 01                move.l   d1, d0
  032c0:  d0 80                add.l    d0, d0
  032c2:  d2 80                add.l    d0, d1
  032c4:  2f 01                move.l   d1, -(a7)
  032c6:  61 ff ff ff fb d4    bsr.l    $2e9c
  032cc:  58 8f                addq.l   #$4, a7
  032ce:  2f 00                move.l   d0, -(a7)
  032d0:  61 ff 00 00 15 22    bsr.l    $47f4
  032d6:  2d 5f ff e4          move.l   (a7)+, -$1c(a6)
  032da:  66 12                bne.b    $32ee
  032dc:  48 7a 11 5e          pea.l    $443c(pc)
  032e0:  61 ff ff ff fd ba    bsr.l    $309c
  032e6:  70 00                moveq    #$0, d0
  032e8:  58 4f                addq.w   #$4, a7
  032ea:  60 00 0f 0e          bra.w    $41fa
  032ee:  20 2e ff 2a          move.l   -$d6(a6), d0
  032f2:  d0 ae 00 08          add.l    $8(a6), d0
  032f6:  20 40                movea.l  d0, a0
  032f8:  22 6e ff e4          movea.l  -$1c(a6), a1
  032fc:  22 2e ff e0          move.l   -$20(a6), d1
  03300:  d2 81                add.l    d1, d1
  03302:  20 01                move.l   d1, d0
  03304:  d0 80                add.l    d0, d0
  03306:  d2 80                add.l    d0, d1
  03308:  20 01                move.l   d1, d0
  0330a:  a0 2e                dc.w     $a02e  ; _BlockMove
  0330c:  20 3c 00 80 00 00    move.l   #$800000, d0
  03312:  c0 ae 00 18          and.l    $18(a6), d0
  03316:  67 5c                beq.b    $3374
  03318:  20 2e ff 3e          move.l   -$c2(a6), d0
  0331c:  d0 bc 00 00 03 ff    add.l    #$3ff, d0
  03322:  22 3c ff ff fc 00    move.l   #$fffffc00, d1
  03328:  c2 80                and.l    d0, d1
  0332a:  2d 41 ff 3e          move.l   d1, -$c2(a6)
  0332e:  2f 2e 00 1c          move.l   $1c(a6), -(a7)
  03332:  2f 2e ff 46          move.l   -$ba(a6), -(a7)
  03336:  2f 2e ff 42          move.l   -$be(a6), -(a7)
  0333a:  2f 2e ff 3e          move.l   -$c2(a6), -(a7)
  0333e:  61 ff ff ff f8 1e    bsr.l    $2b5e
  03344:  2d 40 ff ec          move.l   d0, -$14(a6)
  03348:  4f ef 00 10          lea.l    $10(a7), a7
  0334c:  66 10                bne.b    $335e
  0334e:  48 7a 10 c8          pea.l    $4418(pc)
  03352:  61 ff ff ff fd 48    bsr.l    $309c
  03358:  58 4f                addq.w   #$4, a7
  0335a:  60 00 0e 8a          bra.w    $41e6
  0335e:  2f 2e ff ec          move.l   -$14(a6), -(a7)
  03362:  48 7a 10 a4          pea.l    $4408(pc)
  03366:  61 ff ff ff fd 3c    bsr.l    $30a4
  0336c:  2d 6e ff ec ff f0    move.l   -$14(a6), -$10(a6)
  03372:  50 4f                addq.w   #$8, a7
  03374:  70 00                moveq    #$0, d0
  03376:  30 2e ff 24          move.w   -$dc(a6), d0
  0337a:  2f 00                move.l   d0, -(a7)
  0337c:  48 7a 10 74          pea.l    $43f2(pc)
  03380:  61 ff ff ff fd 22    bsr.l    $30a4
  03386:  70 00                moveq    #$0, d0
  03388:  2d 40 ff ce          move.l   d0, -$32(a6)
  0338c:  72 01                moveq    #$1, d1
  0338e:  2d 41 ff ba          move.l   d1, -$46(a6)
  03392:  50 4f                addq.w   #$8, a7
  03394:  42 2e fe d3          clr.b    -$12d(a6)
  03398:  70 00                moveq    #$0, d0
  0339a:  2d 40 fe d4          move.l   d0, -$12c(a6)
  0339e:  72 02                moveq    #$2, d1
  033a0:  b2 ae ff ba          cmp.l    -$46(a6), d1
  033a4:  66 1a                bne.b    $33c0
  033a6:  20 3c 00 80 00 00    move.l   #$800000, d0
  033ac:  c0 ae 00 18          and.l    $18(a6), d0
  033b0:  67 0e                beq.b    $33c0
  033b2:  20 3c 20 00 00 00    move.l   #$20000000, d0
  033b8:  c0 ae 00 18          and.l    $18(a6), d0
  033bc:  66 00 0d d8          bne.w    $4196
  033c0:  2d 6e ff ec ff f0    move.l   -$14(a6), -$10(a6)
  033c6:  2d 6e ff f0 fe ea    move.l   -$10(a6), -$116(a6)
  033cc:  2d 6e fe f6 fe f2    move.l   -$10a(a6), -$10e(a6)
  033d2:  70 00                moveq    #$0, d0
  033d4:  2d 40 ff ca          move.l   d0, -$36(a6)
  033d8:  60 00 0d 9c          bra.w    $4176
  033dc:  4a 2e ff f5          tst.b    -$b(a6)
  033e0:  67 1e                beq.b    $3400
  033e2:  20 3c 00 80 00 00    move.l   #$800000, d0
  033e8:  c0 ae 00 18          and.l    $18(a6), d0
  033ec:  67 12                beq.b    $3400
  033ee:  4a ae fe d4          tst.l    -$12c(a6)
  033f2:  67 0c                beq.b    $3400
  033f4:  2d 6e ff f0 fe ea    move.l   -$10(a6), -$116(a6)
  033fa:  70 00                moveq    #$0, d0
  033fc:  2d 40 fe d4          move.l   d0, -$12c(a6)
  03400:  20 2e fe f2          move.l   -$10e(a6), d0
  03404:  d0 ae 00 08          add.l    $8(a6), d0
  03408:  2d 40 fe d8          move.l   d0, -$128(a6)
  0340c:  b0 ae ff d2          cmp.l    -$2e(a6), d0
  03410:  63 1a                bls.b    $342c
  03412:  20 2e fe d8          move.l   -$128(a6), d0
  03416:  90 ae ff d2          sub.l    -$2e(a6), d0
  0341a:  2f 00                move.l   d0, -(a7)
  0341c:  48 7a 0e 96          pea.l    $42b4(pc)
  03420:  61 ff ff ff fc 7a    bsr.l    $309c
  03426:  50 4f                addq.w   #$8, a7
  03428:  60 00 0d bc          bra.w    $41e6
  0342c:  20 6e fe d8          movea.l  -$128(a6), a0
  03430:  43 ee fe fa          lea.l    -$106(a6), a1
  03434:  70 09                moveq    #$9, d0
  03436:  22 d8                move.l   (a0)+, (a1)+
  03438:  51 c8 ff fc          dbra     d0, $3436
  0343c:  4a 2e ff f6          tst.b    -$a(a6)
  03440:  67 42                beq.b    $3484
  03442:  20 2e fe d8          move.l   -$128(a6), d0
  03446:  90 ae 00 08          sub.l    $8(a6), d0
  0344a:  1d 40 ff f7          move.b   d0, -$9(a6)
  0344e:  70 00                moveq    #$0, d0
  03450:  2d 40 ff c6          move.l   d0, -$3a(a6)
  03454:  41 ee fe fa          lea.l    -$106(a6), a0
  03458:  2d 48 ff f8          move.l   a0, -$8(a6)
  0345c:  60 1e                bra.b    $347c
  0345e:  20 6e ff f8          movea.l  -$8(a6), a0
  03462:  52 ae ff f8          addq.l   #$1, -$8(a6)
  03466:  10 2e ff f7          move.b   -$9(a6), d0
  0346a:  b1 10                eor.b    d0, (a0)
  0346c:  20 2e ff c6          move.l   -$3a(a6), d0
  03470:  52 ae ff c6          addq.l   #$1, -$3a(a6)
  03474:  10 2e ff f6          move.b   -$a(a6), d0
  03478:  d1 2e ff f7          add.b    d0, -$9(a6)
  0347c:  70 28                moveq    #$28, d0
  0347e:  b0 ae ff c6          cmp.l    -$3a(a6), d0
  03482:  62 da                bhi.b    $345e
  03484:  06 ae 00 00 00 28 fe d8 addi.l   #$28, -$128(a6)
  0348c:  2f 2e ff 12          move.l   -$ee(a6), -(a7)
  03490:  2f 2e ff 0e          move.l   -$f2(a6), -(a7)
  03494:  2f 2e ff ba          move.l   -$46(a6), -(a7)
  03498:  48 7a 0f 30          pea.l    $43ca(pc)
  0349c:  61 ff ff ff fc 06    bsr.l    $30a4
  034a2:  20 2e fe d8          move.l   -$128(a6), d0
  034a6:  b0 ae ff d2          cmp.l    -$2e(a6), d0
  034aa:  4f ef 00 10          lea.l    $10(a7), a7
  034ae:  63 1a                bls.b    $34ca
  034b0:  20 2e fe d8          move.l   -$128(a6), d0
  034b4:  90 ae ff d2          sub.l    -$2e(a6), d0
  034b8:  2f 00                move.l   d0, -(a7)
  034ba:  48 7a 0d f8          pea.l    $42b4(pc)
  034be:  61 ff ff ff fb dc    bsr.l    $309c
  034c4:  50 4f                addq.w   #$8, a7
  034c6:  60 00 0d 1e          bra.w    $41e6
  034ca:  20 2e fe d8          move.l   -$128(a6), d0
  034ce:  90 ae 00 08          sub.l    $8(a6), d0
  034d2:  2d 40 fe f2          move.l   d0, -$10e(a6)
  034d6:  20 3c 00 00 0e 1b    move.l   #$e1b, d0
  034dc:  c0 ae ff 1e          and.l    -$e2(a6), d0
  034e0:  66 06                bne.b    $34e8
  034e2:  4a ae ff 0a          tst.l    -$f6(a6)
  034e6:  66 34                bne.b    $351c
  034e8:  70 01                moveq    #$1, d0
  034ea:  b0 ae ff ba          cmp.l    -$46(a6), d0
  034ee:  66 00 0c 7e          bne.w    $416e
  034f2:  2f 2e ff 0a          move.l   -$f6(a6), -(a7)
  034f6:  2f 2e ff 02          move.l   -$fe(a6), -(a7)
  034fa:  20 2e ff ca          move.l   -$36(a6), d0
  034fe:  52 80                addq.l   #$1, d0
  03500:  2f 00                move.l   d0, -(a7)
  03502:  2f 2e ff 1e          move.l   -$e2(a6), -(a7)
  03506:  48 6e fe fa          pea.l    -$106(a6)
  0350a:  48 7a 0e 86          pea.l    $4392(pc)
  0350e:  61 ff ff ff fb 94    bsr.l    $30a4
  03514:  4f ef 00 18          lea.l    $18(a7), a7
  03518:  60 00 0c 54          bra.w    $416e
  0351c:  70 01                moveq    #$1, d0
  0351e:  b0 ae ff ba          cmp.l    -$46(a6), d0
  03522:  66 64                bne.b    $3588
  03524:  4a ae 00 0c          tst.l    $c(a6)
  03528:  67 5e                beq.b    $3588
  0352a:  70 08                moveq    #$8, d0
  0352c:  2f 00                move.l   d0, -(a7)
  0352e:  48 6e fe fa          pea.l    -$106(a6)
  03532:  48 7a 0e 54          pea.l    $4388(pc)
  03536:  61 ff ff ff fb 2a    bsr.l    $3062
  0353c:  4a 80                tst.l    d0
  0353e:  4f ef 00 0c          lea.l    $c(a7), a7
  03542:  66 1c                bne.b    $3560
  03544:  2f 2e 00 10          move.l   $10(a6), -(a7)
  03548:  2f 2e ff 3a          move.l   -$c6(a6), -(a7)
  0354c:  61 ff ff ff f9 ae    bsr.l    $2efc
  03552:  20 6e 00 0c          movea.l  $c(a6), a0
  03556:  20 80                move.l   d0, (a0)
  03558:  1d 7c 00 01 ff d7    move.b   #$1, -$29(a6)
  0355e:  50 4f                addq.w   #$8, a7
  03560:  70 04                moveq    #$4, d0
  03562:  2f 00                move.l   d0, -(a7)
  03564:  48 6e fe fa          pea.l    -$106(a6)
  03568:  48 7a 0d aa          pea.l    $4314(pc)
  0356c:  61 ff ff ff fa f4    bsr.l    $3062
  03572:  4a 80                tst.l    d0
  03574:  4f ef 00 0c          lea.l    $c(a7), a7
  03578:  66 0e                bne.b    $3588
  0357a:  20 6e 00 0c          movea.l  $c(a6), a0
  0357e:  20 ae ff 36          move.l   -$ca(a6), (a0)
  03582:  1d 7c 00 01 ff d7    move.b   #$1, -$29(a6)
  03588:  42 2e fe d2          clr.b    -$12e(a6)
  0358c:  70 20                moveq    #$20, d0
  0358e:  c0 ae ff 1e          and.l    -$e2(a6), d0
  03592:  67 00 00 8c          beq.w    $3620
  03596:  20 3c 00 00 80 20    move.l   #$8020, d0
  0359c:  c0 ae ff 1e          and.l    -$e2(a6), d0
  035a0:  0c 80 00 00 80 20    cmpi.l   #$8020, d0
  035a6:  67 78                beq.b    $3620
  035a8:  1d 7c 00 01 fe d3    move.b   #$1, -$12d(a6)
  035ae:  20 3c 00 80 00 00    move.l   #$800000, d0
  035b4:  c0 ae 00 18          and.l    $18(a6), d0
  035b8:  67 20                beq.b    $35da
  035ba:  70 10                moveq    #$10, d0
  035bc:  c0 ae 00 18          and.l    $18(a6), d0
  035c0:  67 18                beq.b    $35da
  035c2:  20 3c 0e 00 00 00    move.l   #$e000000, d0
  035c8:  c0 ae ff 02          and.l    -$fe(a6), d0
  035cc:  0c 80 0c 00 00 00    cmpi.l   #$c000000, d0
  035d2:  67 06                beq.b    $35da
  035d4:  1d 7c 00 01 fe d2    move.b   #$1, -$12e(a6)
  035da:  70 01                moveq    #$1, d0
  035dc:  b0 ae ff ba          cmp.l    -$46(a6), d0
  035e0:  66 66                bne.b    $3648
  035e2:  4a ae ff ce          tst.l    -$32(a6)
  035e6:  66 06                bne.b    $35ee
  035e8:  2d 6e fe ea ff d8    move.l   -$116(a6), -$28(a6)
  035ee:  70 20                moveq    #$20, d0
  035f0:  b0 ae ff ce          cmp.l    -$32(a6), d0
  035f4:  6e 10                bgt.b    $3606
  035f6:  48 7a 0d 6e          pea.l    $4366(pc)
  035fa:  61 ff ff ff fa a0    bsr.l    $309c
  03600:  58 4f                addq.w   #$4, a7
  03602:  60 00 0b e2          bra.w    $41e6
  03606:  30 2e ff cc          move.w   -$34(a6), d0
  0360a:  52 40                addq.w   #$1, d0
  0360c:  22 2e ff ce          move.l   -$32(a6), d1
  03610:  52 ae ff ce          addq.l   #$1, -$32(a6)
  03614:  d2 41                add.w    d1, d1
  03616:  41 ee ff 7a          lea.l    -$86(a6), a0
  0361a:  31 80 10 00          move.w   d0, (a0, d1.w)
  0361e:  60 28                bra.b    $3648
  03620:  4a 2e fe d3          tst.b    -$12d(a6)
  03624:  67 22                beq.b    $3648
  03626:  20 2e fe ea          move.l   -$116(a6), d0
  0362a:  2d 40 fe ce          move.l   d0, -$132(a6)
  0362e:  d0 bc 00 00 03 ff    add.l    #$3ff, d0
  03634:  22 3c ff ff fc 00    move.l   #$fffffc00, d1
  0363a:  c2 80                and.l    d0, d1
  0363c:  2d 41 fe ce          move.l   d1, -$132(a6)
  03640:  2d 41 fe ea          move.l   d1, -$116(a6)
  03644:  42 2e fe d3          clr.b    -$12d(a6)
  03648:  70 01                moveq    #$1, d0
  0364a:  b0 ae ff ba          cmp.l    -$46(a6), d0
  0364e:  66 46                bne.b    $3696
  03650:  2f 2e fe ea          move.l   -$116(a6), -(a7)
  03654:  20 3c 00 00 00 80    move.l   #$80, d0
  0365a:  c0 ae ff 1e          and.l    -$e2(a6), d0
  0365e:  67 08                beq.b    $3668
  03660:  41 fa 0c fc          lea.l    $435e(pc), a0
  03664:  20 08                move.l   a0, d0
  03666:  60 06                bra.b    $366e
  03668:  41 fa 0c ec          lea.l    $4356(pc), a0
  0366c:  20 08                move.l   a0, d0
  0366e:  2f 00                move.l   d0, -(a7)
  03670:  2f 2e ff 0a          move.l   -$f6(a6), -(a7)
  03674:  2f 2e ff 02          move.l   -$fe(a6), -(a7)
  03678:  20 2e ff ca          move.l   -$36(a6), d0
  0367c:  52 80                addq.l   #$1, d0
  0367e:  2f 00                move.l   d0, -(a7)
  03680:  2f 2e ff 1e          move.l   -$e2(a6), -(a7)
  03684:  48 6e fe fa          pea.l    -$106(a6)
  03688:  48 7a 0c 90          pea.l    $431a(pc)
  0368c:  61 ff ff ff fa 16    bsr.l    $30a4
  03692:  4f ef 00 20          lea.l    $20(a7), a7
  03696:  4a 6e ff 1a          tst.w    -$e6(a6)
  0369a:  67 34                beq.b    $36d0
  0369c:  0c ae 00 00 ff ff ff e0 cmpi.l   #$ffff, -$20(a6)
  036a4:  6f 16                ble.b    $36bc
  036a6:  59 8f                subq.l   #$4, a7
  036a8:  20 2e ff 12          move.l   -$ee(a6), d0
  036ac:  d0 ae 00 08          add.l    $8(a6), d0
  036b0:  2f 00                move.l   d0, -(a7)
  036b2:  61 ff 00 00 11 40    bsr.l    $47f4
  036b8:  26 5f                movea.l  (a7)+, a3
  036ba:  60 14                bra.b    $36d0
  036bc:  59 8f                subq.l   #$4, a7
  036be:  20 2e ff 12          move.l   -$ee(a6), d0
  036c2:  d0 ae 00 08          add.l    $8(a6), d0
  036c6:  2f 00                move.l   d0, -(a7)
  036c8:  61 ff 00 00 11 2a    bsr.l    $47f4
  036ce:  28 5f                movea.l  (a7)+, a4
  036d0:  20 2e ff 0e          move.l   -$f2(a6), d0
  036d4:  d0 ae 00 08          add.l    $8(a6), d0
  036d8:  2d 40 fe d8          move.l   d0, -$128(a6)
  036dc:  2d 6e ff 0a fe de    move.l   -$f6(a6), -$122(a6)
  036e2:  20 2e ff 06          move.l   -$fa(a6), d0
  036e6:  c0 bc 0f ff ff ff    and.l    #$fffffff, d0
  036ec:  2d 40 fe e2          move.l   d0, -$11e(a6)
  036f0:  4a 2e ff f5          tst.b    -$b(a6)
  036f4:  66 34                bne.b    $372a
  036f6:  70 20                moveq    #$20, d0
  036f8:  c0 ae ff 1e          and.l    -$e2(a6), d0
  036fc:  67 1a                beq.b    $3718
  036fe:  20 3c 00 00 80 20    move.l   #$8020, d0
  03704:  c0 ae ff 1e          and.l    -$e2(a6), d0
  03708:  0c 80 00 00 80 20    cmpi.l   #$8020, d0
  0370e:  67 08                beq.b    $3718
  03710:  2d 6e ff 02 fe ea    move.l   -$fe(a6), -$116(a6)
  03716:  60 12                bra.b    $372a
  03718:  20 3c f0 00 00 00    move.l   #$f0000000, d0
  0371e:  c0 ae ff 02          and.l    -$fe(a6), d0
  03722:  67 06                beq.b    $372a
  03724:  2d 6e ff 02 fe ea    move.l   -$fe(a6), -$116(a6)
  0372a:  20 3c 00 00 40 00    move.l   #$4000, d0
  03730:  c0 ae ff 1e          and.l    -$e2(a6), d0
  03734:  67 48                beq.b    $377e
  03736:  2d 6e ff 02 fe ea    move.l   -$fe(a6), -$116(a6)
  0373c:  20 3c 00 80 00 00    move.l   #$800000, d0
  03742:  c0 ae 00 18          and.l    $18(a6), d0
  03746:  67 00 02 62          beq.w    $39aa
  0374a:  70 04                moveq    #$4, d0
  0374c:  2f 00                move.l   d0, -(a7)
  0374e:  48 6e fe fa          pea.l    -$106(a6)
  03752:  48 7a 0b c0          pea.l    $4314(pc)
  03756:  61 ff ff ff f9 0a    bsr.l    $3062
  0375c:  4a 80                tst.l    d0
  0375e:  4f ef 00 0c          lea.l    $c(a7), a7
  03762:  66 00 02 46          bne.w    $39aa
  03766:  20 2e ff 02          move.l   -$fe(a6), d0
  0376a:  d0 bc 0c 00 00 00    add.l    #$c000000, d0
  03770:  2d 40 fe ea          move.l   d0, -$116(a6)
  03774:  70 01                moveq    #$1, d0
  03776:  2d 40 fe d4          move.l   d0, -$12c(a6)
  0377a:  60 00 02 2e          bra.w    $39aa
  0377e:  70 01                moveq    #$1, d0
  03780:  b0 ae ff ba          cmp.l    -$46(a6), d0
  03784:  66 00 02 24          bne.w    $39aa
  03788:  20 3c 00 00 00 80    move.l   #$80, d0
  0378e:  c0 ae ff 1e          and.l    -$e2(a6), d0
  03792:  67 00 01 44          beq.w    $38d8
  03796:  4a ae fe ee          tst.l    -$112(a6)
  0379a:  67 10                beq.b    $37ac
  0379c:  48 7a 0b 3e          pea.l    $42dc(pc)
  037a0:  61 ff ff ff f8 fa    bsr.l    $309c
  037a6:  58 4f                addq.w   #$4, a7
  037a8:  60 00 0a 3c          bra.w    $41e6
  037ac:  2d 6e fe ea fe ee    move.l   -$116(a6), -$112(a6)
  037b2:  70 00                moveq    #$0, d0
  037b4:  2d 40 ff c2          move.l   d0, -$3e(a6)
  037b8:  60 00 00 92          bra.w    $384c
  037bc:  20 6e ff e4          movea.l  -$1c(a6), a0
  037c0:  20 2e ff c2          move.l   -$3e(a6), d0
  037c4:  d0 80                add.l    d0, d0
  037c6:  22 00                move.l   d0, d1
  037c8:  d2 81                add.l    d1, d1
  037ca:  d0 81                add.l    d1, d0
  037cc:  22 2e ff ca          move.l   -$36(a6), d1
  037d0:  52 81                addq.l   #$1, d1
  037d2:  30 30 08 00          move.w   (a0, d0.l), d0
  037d6:  48 c0                ext.l    d0
  037d8:  b2 80                cmp.l    d0, d1
  037da:  66 68                bne.b    $3844
  037dc:  2f 2e 00 10          move.l   $10(a6), -(a7)
  037e0:  20 6e ff e4          movea.l  -$1c(a6), a0
  037e4:  20 2e ff c2          move.l   -$3e(a6), d0
  037e8:  d0 80                add.l    d0, d0
  037ea:  22 00                move.l   d0, d1
  037ec:  d2 81                add.l    d1, d1
  037ee:  d0 81                add.l    d1, d0
  037f0:  2f 30 08 02          move.l   $2(a0, d0.l), -(a7)
  037f4:  61 ff ff ff f7 06    bsr.l    $2efc
  037fa:  20 6e ff e4          movea.l  -$1c(a6), a0
  037fe:  22 2e ff c2          move.l   -$3e(a6), d1
  03802:  d2 81                add.l    d1, d1
  03804:  24 01                move.l   d1, d2
  03806:  d4 82                add.l    d2, d2
  03808:  d2 82                add.l    d2, d1
  0380a:  21 80 18 02          move.l   d0, $2(a0, d1.l)
  0380e:  20 6e ff e4          movea.l  -$1c(a6), a0
  03812:  20 2e ff c2          move.l   -$3e(a6), d0
  03816:  d0 80                add.l    d0, d0
  03818:  22 00                move.l   d0, d1
  0381a:  d2 81                add.l    d1, d1
  0381c:  d0 81                add.l    d1, d0
  0381e:  22 2e fe ea          move.l   -$116(a6), d1
  03822:  d2 b0 08 02          add.l    $2(a0, d0.l), d1
  03826:  92 ae ff 02          sub.l    -$fe(a6), d1
  0382a:  20 6e ff e4          movea.l  -$1c(a6), a0
  0382e:  20 2e ff c2          move.l   -$3e(a6), d0
  03832:  d0 80                add.l    d0, d0
  03834:  24 00                move.l   d0, d2
  03836:  d4 82                add.l    d2, d2
  03838:  d0 82                add.l    d2, d0
  0383a:  21 81 08 02          move.l   d1, $2(a0, d0.l)
  0383e:  2d 41 fe ee          move.l   d1, -$112(a6)
  03842:  50 4f                addq.w   #$8, a7
  03844:  20 2e ff c2          move.l   -$3e(a6), d0
  03848:  52 ae ff c2          addq.l   #$1, -$3e(a6)
  0384c:  20 2e ff c2          move.l   -$3e(a6), d0
  03850:  b0 ae ff e0          cmp.l    -$20(a6), d0
  03854:  65 00 ff 66          bcs.w    $37bc
  03858:  70 00                moveq    #$0, d0
  0385a:  2d 40 ff c2          move.l   d0, -$3e(a6)
  0385e:  60 6a                bra.b    $38ca
  03860:  20 6e ff e4          movea.l  -$1c(a6), a0
  03864:  20 2e ff c2          move.l   -$3e(a6), d0
  03868:  d0 80                add.l    d0, d0
  0386a:  22 00                move.l   d0, d1
  0386c:  d2 81                add.l    d1, d1
  0386e:  d0 81                add.l    d1, d0
  03870:  4a 70 08 00          tst.w    (a0, d0.l)
  03874:  66 4c                bne.b    $38c2
  03876:  20 6e ff e4          movea.l  -$1c(a6), a0
  0387a:  20 2e ff c2          move.l   -$3e(a6), d0
  0387e:  d0 80                add.l    d0, d0
  03880:  22 00                move.l   d0, d1
  03882:  d2 81                add.l    d1, d1
  03884:  d0 81                add.l    d1, d0
  03886:  2d 70 08 02 ff dc    move.l   $2(a0, d0.l), -$24(a6)
  0388c:  67 34                beq.b    $38c2
  0388e:  02 ae 0f ff ff ff ff dc andi.l   #$fffffff, -$24(a6)
  03896:  2f 2e 00 10          move.l   $10(a6), -(a7)
  0389a:  2f 2e fe ee          move.l   -$112(a6), -(a7)
  0389e:  61 ff ff ff f6 5c    bsr.l    $2efc
  038a4:  20 6e ff e4          movea.l  -$1c(a6), a0
  038a8:  22 2e ff c2          move.l   -$3e(a6), d1
  038ac:  d2 81                add.l    d1, d1
  038ae:  24 01                move.l   d1, d2
  038b0:  d4 82                add.l    d2, d2
  038b2:  d2 82                add.l    d2, d1
  038b4:  21 80 18 02          move.l   d0, $2(a0, d1.l)
  038b8:  20 2e ff dc          move.l   -$24(a6), d0
  038bc:  d1 ae fe ee          add.l    d0, -$112(a6)
  038c0:  50 4f                addq.w   #$8, a7
  038c2:  20 2e ff c2          move.l   -$3e(a6), d0
  038c6:  52 ae ff c2          addq.l   #$1, -$3e(a6)
  038ca:  20 2e ff c2          move.l   -$3e(a6), d0
  038ce:  b0 ae ff e0          cmp.l    -$20(a6), d0
  038d2:  65 8c                bcs.b    $3860
  038d4:  60 00 00 d4          bra.w    $39aa
  038d8:  70 00                moveq    #$0, d0
  038da:  2d 40 ff c2          move.l   d0, -$3e(a6)
  038de:  60 00 00 be          bra.w    $399e
  038e2:  2f 2e 00 10          move.l   $10(a6), -(a7)
  038e6:  20 6e ff e4          movea.l  -$1c(a6), a0
  038ea:  20 2e ff c2          move.l   -$3e(a6), d0
  038ee:  d0 80                add.l    d0, d0
  038f0:  22 00                move.l   d0, d1
  038f2:  d2 81                add.l    d1, d1
  038f4:  d0 81                add.l    d1, d0
  038f6:  2f 30 08 02          move.l   $2(a0, d0.l), -(a7)
  038fa:  61 ff ff ff f6 00    bsr.l    $2efc
  03900:  20 6e ff e4          movea.l  -$1c(a6), a0
  03904:  22 2e ff c2          move.l   -$3e(a6), d1
  03908:  d2 81                add.l    d1, d1
  0390a:  24 01                move.l   d1, d2
  0390c:  d4 82                add.l    d2, d2
  0390e:  d2 82                add.l    d2, d1
  03910:  21 80 18 02          move.l   d0, $2(a0, d1.l)
  03914:  20 6e ff e4          movea.l  -$1c(a6), a0
  03918:  20 2e ff c2          move.l   -$3e(a6), d0
  0391c:  d0 80                add.l    d0, d0
  0391e:  22 00                move.l   d0, d1
  03920:  d2 81                add.l    d1, d1
  03922:  d0 81                add.l    d1, d0
  03924:  22 2e ff ca          move.l   -$36(a6), d1
  03928:  52 81                addq.l   #$1, d1
  0392a:  30 30 08 00          move.w   (a0, d0.l), d0
  0392e:  48 c0                ext.l    d0
  03930:  b2 80                cmp.l    d0, d1
  03932:  50 4f                addq.w   #$8, a7
  03934:  66 60                bne.b    $3996
  03936:  20 6e ff e4          movea.l  -$1c(a6), a0
  0393a:  20 2e ff c2          move.l   -$3e(a6), d0
  0393e:  d0 80                add.l    d0, d0
  03940:  22 00                move.l   d0, d1
  03942:  d2 81                add.l    d1, d1
  03944:  d0 81                add.l    d1, d0
  03946:  22 48                movea.l  a0, a1
  03948:  22 2e ff c2          move.l   -$3e(a6), d1
  0394c:  d2 81                add.l    d1, d1
  0394e:  24 01                move.l   d1, d2
  03950:  d4 82                add.l    d2, d2
  03952:  d2 82                add.l    d2, d1
  03954:  24 2e fe ea          move.l   -$116(a6), d2
  03958:  d4 b1 18 02          add.l    $2(a1, d1.l), d2
  0395c:  94 ae ff 02          sub.l    -$fe(a6), d2
  03960:  b4 b0 08 02          cmp.l    $2(a0, d0.l), d2
  03964:  67 30                beq.b    $3996
  03966:  20 6e ff e4          movea.l  -$1c(a6), a0
  0396a:  20 2e ff c2          move.l   -$3e(a6), d0
  0396e:  d0 80                add.l    d0, d0
  03970:  22 00                move.l   d0, d1
  03972:  d2 81                add.l    d1, d1
  03974:  d0 81                add.l    d1, d0
  03976:  22 2e fe ea          move.l   -$116(a6), d1
  0397a:  d2 b0 08 02          add.l    $2(a0, d0.l), d1
  0397e:  92 ae ff 02          sub.l    -$fe(a6), d1
  03982:  20 6e ff e4          movea.l  -$1c(a6), a0
  03986:  20 2e ff c2          move.l   -$3e(a6), d0
  0398a:  d0 80                add.l    d0, d0
  0398c:  24 00                move.l   d0, d2
  0398e:  d4 82                add.l    d2, d2
  03990:  d0 82                add.l    d2, d0
  03992:  21 81 08 02          move.l   d1, $2(a0, d0.l)
  03996:  20 2e ff c2          move.l   -$3e(a6), d0
  0399a:  52 ae ff c2          addq.l   #$1, -$3e(a6)
  0399e:  20 2e ff c2          move.l   -$3e(a6), d0
  039a2:  b0 ae ff e0          cmp.l    -$20(a6), d0
  039a6:  65 00 ff 3a          bcs.w    $38e2
  039aa:  2f 2e 00 10          move.l   $10(a6), -(a7)
  039ae:  2f 2e fe ea          move.l   -$116(a6), -(a7)
  039b2:  61 ff ff ff f5 48    bsr.l    $2efc
  039b8:  2d 40 fe e6          move.l   d0, -$11a(a6)
  039bc:  90 ae ff 02          sub.l    -$fe(a6), d0
  039c0:  2d 40 fe e2          move.l   d0, -$11e(a6)
  039c4:  20 2e fe de          move.l   -$122(a6), d0
  039c8:  e4 88                lsr.l    #$2, d0
  039ca:  e5 80                asl.l    #$2, d0
  039cc:  d1 ae fe ea          add.l    d0, -$116(a6)
  039d0:  70 02                moveq    #$2, d0
  039d2:  b0 ae ff ba          cmp.l    -$46(a6), d0
  039d6:  50 4f                addq.w   #$8, a7
  039d8:  66 00 07 94          bne.w    $416e
  039dc:  20 3c 00 00 00 80    move.l   #$80, d0
  039e2:  c0 ae ff 1e          and.l    -$e2(a6), d0
  039e6:  67 1a                beq.b    $3a02
  039e8:  2f 2e 00 10          move.l   $10(a6), -(a7)
  039ec:  2f 2e fe de          move.l   -$122(a6), -(a7)
  039f0:  2f 2e fe e6          move.l   -$11a(a6), -(a7)
  039f4:  61 ff ff ff f4 22    bsr.l    $2e18
  039fa:  4f ef 00 0c          lea.l    $c(a7), a7
  039fe:  60 00 07 6e          bra.w    $416e
  03a02:  20 2e fe de          move.l   -$122(a6), d0
  03a06:  d0 ae fe d8          add.l    -$128(a6), d0
  03a0a:  b0 ae ff d2          cmp.l    -$2e(a6), d0
  03a0e:  63 1a                bls.b    $3a2a
  03a10:  20 2e fe d8          move.l   -$128(a6), d0
  03a14:  90 ae ff d2          sub.l    -$2e(a6), d0
  03a18:  2f 00                move.l   d0, -(a7)
  03a1a:  48 7a 08 98          pea.l    $42b4(pc)
  03a1e:  61 ff ff ff f6 7c    bsr.l    $309c
  03a24:  50 4f                addq.w   #$8, a7
  03a26:  60 00 07 be          bra.w    $41e6
  03a2a:  2d 6e fe e6 fe ce    move.l   -$11a(a6), -$132(a6)
  03a30:  59 8f                subq.l   #$4, a7
  03a32:  2f 2e fe d8          move.l   -$128(a6), -(a7)
  03a36:  61 ff 00 00 0d bc    bsr.l    $47f4
  03a3c:  2d 5f fe c6          move.l   (a7)+, -$13a(a6)
  03a40:  4a 2e ff f6          tst.b    -$a(a6)
  03a44:  67 22                beq.b    $3a68
  03a46:  1d 6e ff 11 ff f7    move.b   -$ef(a6), -$9(a6)
  03a4c:  70 00                moveq    #$0, d0
  03a4e:  10 2e ff f6          move.b   -$a(a6), d0
  03a52:  2d 40 ff fc          move.l   d0, -$4(a6)
  03a56:  e1 88                lsl.l    #$8, d0
  03a58:  81 ae ff fc          or.l     d0, -$4(a6)
  03a5c:  70 10                moveq    #$10, d0
  03a5e:  22 2e ff fc          move.l   -$4(a6), d1
  03a62:  e1 a9                lsl.l    d0, d1
  03a64:  83 ae ff fc          or.l     d1, -$4(a6)
  03a68:  1d 7c 00 01 fe dd    move.b   #$1, -$123(a6)
  03a6e:  41 ee fe dd          lea.l    -$123(a6), a0
  03a72:  10 10                move.b   (a0), d0
  03a74:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  03a76:  10 80                move.b   d0, (a0)
  03a78:  2f 2e 00 10          move.l   $10(a6), -(a7)
  03a7c:  4a 2e fe d2          tst.b    -$12e(a6)
  03a80:  67 0c                beq.b    $3a8e
  03a82:  20 3c 00 01 ff ff    move.l   #$1ffff, d0
  03a88:  c0 ae fe ce          and.l    -$132(a6), d0
  03a8c:  60 04                bra.b    $3a92
  03a8e:  20 2e fe ce          move.l   -$132(a6), d0
  03a92:  2f 00                move.l   d0, -(a7)
  03a94:  61 ff ff ff f4 66    bsr.l    $2efc
  03a9a:  2d 40 fe ca          move.l   d0, -$136(a6)
  03a9e:  70 00                moveq    #$0, d0
  03aa0:  30 2e ff 1a          move.w   -$e6(a6), d0
  03aa4:  4a 80                tst.l    d0
  03aa6:  50 4f                addq.w   #$8, a7
  03aa8:  67 00 06 30          beq.w    $40da
  03aac:  0c ae 00 00 ff ff ff e0 cmpi.l   #$ffff, -$20(a6)
  03ab4:  6f 00 03 12          ble.w    $3dc8
  03ab8:  70 00                moveq    #$0, d0
  03aba:  2d 40 ff c2          move.l   d0, -$3e(a6)
  03abe:  60 00 02 f8          bra.w    $3db8
  03ac2:  70 00                moveq    #$0, d0
  03ac4:  2d 40 ff e8          move.l   d0, -$18(a6)
  03ac8:  20 6e fe c6          movea.l  -$13a(a6), a0
  03acc:  58 ae fe c6          addq.l   #$4, -$13a(a6)
  03ad0:  2e 10                move.l   (a0), d7
  03ad2:  22 2e ff fc          move.l   -$4(a6), d1
  03ad6:  b3 87                eor.l    d1, d7
  03ad8:  72 00                moveq    #$0, d1
  03ada:  12 2e ff f7          move.b   -$9(a6), d1
  03ade:  d3 ae ff fc          add.l    d1, -$4(a6)
  03ae2:  12 2e ff ff          move.b   -$1(a6), d1
  03ae6:  b3 2e ff f7          eor.b    d1, -$9(a6)
  03aea:  60 00 02 84          bra.w    $3d70
  03aee:  70 00                moveq    #$0, d0
  03af0:  30 2b 00 08          move.w   $8(a3), d0
  03af4:  72 1c                moveq    #$1c, d1
  03af6:  b2 80                cmp.l    d0, d1
  03af8:  67 34                beq.b    $3b2e
  03afa:  60 04                bra.b    $3b00
  03afc:  52 ab 00 04          addq.l   #$1, $4(a3)
  03b00:  20 6e ff e4          movea.l  -$1c(a6), a0
  03b04:  20 2b 00 04          move.l   $4(a3), d0
  03b08:  d0 80                add.l    d0, d0
  03b0a:  22 00                move.l   d0, d1
  03b0c:  d2 81                add.l    d1, d1
  03b0e:  d0 81                add.l    d1, d0
  03b10:  72 fd                moveq    #$fd, d1
  03b12:  b2 70 08 00          cmp.w    (a0, d0.l), d1
  03b16:  67 e4                beq.b    $3afc
  03b18:  20 6e ff e4          movea.l  -$1c(a6), a0
  03b1c:  20 2b 00 04          move.l   $4(a3), d0
  03b20:  d0 80                add.l    d0, d0
  03b22:  22 00                move.l   d0, d1
  03b24:  d2 81                add.l    d1, d1
  03b26:  d0 81                add.l    d1, d0
  03b28:  2d 70 08 02 fe ba    move.l   $2(a0, d0.l), -$146(a6)
* ==================================================================
* CmdTable1 lookup
* ==================================================================
* Index*6 into a 6-byte-stride table (entry = 2 header bytes + 4-byte
* value at +2), bound-checked to 0..34 (35 entries -> the jump table
* below).  Same shape as the CmdTable2 lookup further down; likely a
* per-selector command/info record, structurally reminiscent of
* gc24.s's 106-entry Am29000 dispatch table, but this copy is local to
* (a different, smaller) DRVR-internal command set.  Not deep-dived
* case-by-case here (low marginal value vs. effort); case targets are
* listed for reference.
  03b2e:  30 2b 00 08          move.w   $8(a3), d0
  03b32:  65 00 02 30          bcs.w    $3d64
  03b36:  0c 40 00 22          cmpi.w   #$22, d0
  03b3a:  62 00 02 28          bhi.w    $3d64
  03b3e:  d0 40                add.w    d0, d0
  03b40:  30 3b 00 06          move.w   $3b48(pc, d0.w), d0
  03b44:  4e fb 00 00          jmp      $3b46(pc,d0.w)
CmdTableJumpTable_03b48:
* jump table (word offsets relative to $3B46):
  03b48:  02 1e                dc.w     $021E    ; sel 0 -> L03d64
  03b4a:  02 1e                dc.w     $021E    ; sel 1 -> L03d64
  03b4c:  02 1e                dc.w     $021E    ; sel 2 -> L03d64
  03b4e:  02 1e                dc.w     $021E    ; sel 3 -> L03d64
  03b50:  02 1e                dc.w     $021E    ; sel 4 -> L03d64
  03b52:  02 1e                dc.w     $021E    ; sel 5 -> L03d64
  03b54:  02 1e                dc.w     $021E    ; sel 6 -> L03d64
  03b56:  02 1e                dc.w     $021E    ; sel 7 -> L03d64
  03b58:  02 1e                dc.w     $021E    ; sel 8 -> L03d64
  03b5a:  02 1e                dc.w     $021E    ; sel 9 -> L03d64
  03b5c:  02 1e                dc.w     $021E    ; sel 10 -> L03d64
  03b5e:  02 1e                dc.w     $021E    ; sel 11 -> L03d64
  03b60:  02 1e                dc.w     $021E    ; sel 12 -> L03d64
  03b62:  02 1e                dc.w     $021E    ; sel 13 -> L03d64
  03b64:  02 1e                dc.w     $021E    ; sel 14 -> L03d64
  03b66:  02 1e                dc.w     $021E    ; sel 15 -> L03d64
  03b68:  02 1e                dc.w     $021E    ; sel 16 -> L03d64
  03b6a:  02 1e                dc.w     $021E    ; sel 17 -> L03d64
  03b6c:  02 1e                dc.w     $021E    ; sel 18 -> L03d64
  03b6e:  02 1e                dc.w     $021E    ; sel 19 -> L03d64
  03b70:  02 1e                dc.w     $021E    ; sel 20 -> L03d64
  03b72:  02 1e                dc.w     $021E    ; sel 21 -> L03d64
  03b74:  02 1e                dc.w     $021E    ; sel 22 -> L03d64
  03b76:  02 1e                dc.w     $021E    ; sel 23 -> L03d64
  03b78:  00 4c                dc.w     $004C    ; sel 24 -> L03b92
  03b7a:  00 b2                dc.w     $00B2    ; sel 25 -> L03bf8
  03b7c:  01 0a                dc.w     $010A    ; sel 26 -> L03c50
  03b7e:  01 5a                dc.w     $015A    ; sel 27 -> L03ca0
  03b80:  02 1e                dc.w     $021E    ; sel 28 -> L03d64
  03b82:  01 c6                dc.w     $01C6    ; sel 29 -> L03d0c
  03b84:  01 e4                dc.w     $01E4    ; sel 30 -> L03d2a
  03b86:  02 02                dc.w     $0202    ; sel 31 -> L03d48
  03b88:  02 1e                dc.w     $021E    ; sel 32 -> L03d64
  03b8a:  02 1e                dc.w     $021E    ; sel 33 -> L03d64
  03b8c:  02 1e                dc.w     $021E    ; sel 34 -> L03d64
  03b8e:  60 00 01 d4          bra.w    $3d64
  03b92:  20 2e fe ba          move.l   -$146(a6), d0
  03b96:  90 ae fe e6          sub.l    -$11a(a6), d0
  03b9a:  2a 00                move.l   d0, d5
  03b9c:  e4 85                asr.l    #$2, d5
  03b9e:  0c 85 00 00 7f ff    cmpi.l   #$7fff, d5
  03ba4:  6e 08                bgt.b    $3bae
  03ba6:  0c 85 ff ff 80 00    cmpi.l   #$ffff8000, d5
  03bac:  6c 24                bge.b    $3bd2
  03bae:  41 ee fe dd          lea.l    -$123(a6), a0
  03bb2:  10 10                move.b   (a0), d0
  03bb4:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  03bb6:  10 80                move.b   d0, (a0)
  03bb8:  2f 2e fe e6          move.l   -$11a(a6), -(a7)
  03bbc:  2f 2e fe ba          move.l   -$146(a6), -(a7)
  03bc0:  48 7a 06 b8          pea.l    $427a(pc)
  03bc4:  61 ff ff ff f4 d6    bsr.l    $309c
  03bca:  4f ef 00 0c          lea.l    $c(a7), a7
  03bce:  60 00 06 16          bra.w    $41e6
  03bd2:  20 3c ff 00 ff 00    move.l   #$ff00ff00, d0
  03bd8:  c0 87                and.l    d7, d0
  03bda:  22 3c 00 00 00 ff    move.l   #$ff, d1
  03be0:  c2 85                and.l    d5, d1
  03be2:  82 80                or.l     d0, d1
  03be4:  20 05                move.l   d5, d0
  03be6:  e1 88                lsl.l    #$8, d0
  03be8:  24 3c 00 ff 00 00    move.l   #$ff0000, d2
  03bee:  c4 80                and.l    d0, d2
  03bf0:  84 81                or.l     d1, d2
  03bf2:  2e 02                move.l   d2, d7
  03bf4:  60 00 01 6e          bra.w    $3d64
  03bf8:  2a 2e fe ba          move.l   -$146(a6), d5
  03bfc:  e4 85                asr.l    #$2, d5
  03bfe:  0c 85 00 00 ff ff    cmpi.l   #$ffff, d5
  03c04:  6f 24                ble.b    $3c2a
  03c06:  41 ee fe dd          lea.l    -$123(a6), a0
  03c0a:  10 10                move.b   (a0), d0
  03c0c:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  03c0e:  10 80                move.b   d0, (a0)
  03c10:  2f 2e fe e6          move.l   -$11a(a6), -(a7)
  03c14:  2f 2e fe ba          move.l   -$146(a6), -(a7)
  03c18:  48 7a 06 26          pea.l    $4240(pc)
  03c1c:  61 ff ff ff f4 7e    bsr.l    $309c
  03c22:  4f ef 00 0c          lea.l    $c(a7), a7
  03c26:  60 00 05 be          bra.w    $41e6
  03c2a:  20 3c ff 00 ff 00    move.l   #$ff00ff00, d0
  03c30:  c0 87                and.l    d7, d0
  03c32:  22 3c 00 00 00 ff    move.l   #$ff, d1
  03c38:  c2 85                and.l    d5, d1
  03c3a:  82 80                or.l     d0, d1
  03c3c:  20 05                move.l   d5, d0
  03c3e:  e1 88                lsl.l    #$8, d0
  03c40:  24 3c 00 ff 00 00    move.l   #$ff0000, d2
  03c46:  c4 80                and.l    d0, d2
  03c48:  84 81                or.l     d1, d2
  03c4a:  2e 02                move.l   d2, d7
  03c4c:  60 00 01 16          bra.w    $3d64
  03c50:  20 3c 00 00 00 ff    move.l   #$ff, d0
  03c56:  c0 87                and.l    d7, d0
  03c58:  22 07                move.l   d7, d1
  03c5a:  e0 89                lsr.l    #$8, d1
  03c5c:  24 3c 00 00 ff 00    move.l   #$ff00, d2
  03c62:  c4 81                and.l    d1, d2
  03c64:  2a 02                move.l   d2, d5
  03c66:  8a 80                or.l     d0, d5
  03c68:  2f 2e 00 10          move.l   $10(a6), -(a7)
  03c6c:  2f 2e fe ba          move.l   -$146(a6), -(a7)
  03c70:  61 ff ff ff f2 8a    bsr.l    $2efc
  03c76:  da 80                add.l    d0, d5
  03c78:  20 3c ff 00 ff 00    move.l   #$ff00ff00, d0
  03c7e:  c0 87                and.l    d7, d0
  03c80:  22 3c 00 00 00 ff    move.l   #$ff, d1
  03c86:  c2 85                and.l    d5, d1
  03c88:  82 80                or.l     d0, d1
  03c8a:  20 05                move.l   d5, d0
  03c8c:  e1 88                lsl.l    #$8, d0
  03c8e:  24 3c 00 ff 00 00    move.l   #$ff0000, d2
  03c94:  c4 80                and.l    d0, d2
  03c96:  84 81                or.l     d1, d2
  03c98:  2e 02                move.l   d2, d7
  03c9a:  50 4f                addq.w   #$8, a7
  03c9c:  60 00 00 c6          bra.w    $3d64
  03ca0:  20 3c 00 00 00 ff    move.l   #$ff, d0
  03ca6:  c0 87                and.l    d7, d0
  03ca8:  22 07                move.l   d7, d1
  03caa:  e0 89                lsr.l    #$8, d1
  03cac:  24 3c 00 00 ff 00    move.l   #$ff00, d2
  03cb2:  c4 81                and.l    d1, d2
  03cb4:  84 80                or.l     d0, d2
  03cb6:  70 10                moveq    #$10, d0
  03cb8:  2a 02                move.l   d2, d5
  03cba:  e1 ad                lsl.l    d0, d5
  03cbc:  47 eb 00 0a          lea.l    $a(a3), a3
  03cc0:  30 2e ff 1a          move.w   -$e6(a6), d0
  03cc4:  53 6e ff 1a          subq.w   #$1, -$e6(a6)
  03cc8:  70 00                moveq    #$0, d0
  03cca:  30 2b 00 06          move.w   $6(a3), d0
  03cce:  8a 80                or.l     d0, d5
  03cd0:  2f 2e 00 10          move.l   $10(a6), -(a7)
  03cd4:  2f 2e fe ba          move.l   -$146(a6), -(a7)
  03cd8:  61 ff ff ff f2 22    bsr.l    $2efc
  03cde:  d0 85                add.l    d5, d0
  03ce0:  2a 00                move.l   d0, d5
  03ce2:  70 10                moveq    #$10, d0
  03ce4:  e0 a5                asr.l    d0, d5
  03ce6:  20 3c ff 00 ff 00    move.l   #$ff00ff00, d0
  03cec:  c0 87                and.l    d7, d0
  03cee:  22 3c 00 00 00 ff    move.l   #$ff, d1
  03cf4:  c2 85                and.l    d5, d1
  03cf6:  82 80                or.l     d0, d1
  03cf8:  20 05                move.l   d5, d0
  03cfa:  e1 88                lsl.l    #$8, d0
  03cfc:  24 3c 00 ff 00 00    move.l   #$ff0000, d2
  03d02:  c4 80                and.l    d0, d2
  03d04:  84 81                or.l     d1, d2
  03d06:  2e 02                move.l   d2, d7
  03d08:  50 4f                addq.w   #$8, a7
  03d0a:  60 58                bra.b    $3d64
  03d0c:  20 6e fe ca          movea.l  -$136(a6), a0
  03d10:  20 87                move.l   d7, (a0)
  03d12:  70 01                moveq    #$1, d0
  03d14:  2d 40 ff e8          move.l   d0, -$18(a6)
  03d18:  72 03                moveq    #$3, d1
  03d1a:  c2 93                and.l    (a3), d1
  03d1c:  d2 ae fe ca          add.l    -$136(a6), d1
  03d20:  20 41                movea.l  d1, a0
  03d22:  12 2e fe bd          move.b   -$143(a6), d1
  03d26:  d3 10                add.b    d1, (a0)
  03d28:  60 3a                bra.b    $3d64
  03d2a:  20 6e fe ca          movea.l  -$136(a6), a0
  03d2e:  20 87                move.l   d7, (a0)
  03d30:  70 01                moveq    #$1, d0
  03d32:  2d 40 ff e8          move.l   d0, -$18(a6)
  03d36:  72 03                moveq    #$3, d1
  03d38:  c2 93                and.l    (a3), d1
  03d3a:  d2 ae fe ca          add.l    -$136(a6), d1
  03d3e:  20 41                movea.l  d1, a0
  03d40:  32 2e fe bc          move.w   -$144(a6), d1
  03d44:  d3 50                add.w    d1, (a0)
  03d46:  60 1c                bra.b    $3d64
  03d48:  20 6e fe ca          movea.l  -$136(a6), a0
  03d4c:  20 87                move.l   d7, (a0)
  03d4e:  70 01                moveq    #$1, d0
  03d50:  2d 40 ff e8          move.l   d0, -$18(a6)
  03d54:  72 03                moveq    #$3, d1
  03d56:  c2 93                and.l    (a3), d1
  03d58:  d2 ae fe ca          add.l    -$136(a6), d1
  03d5c:  20 41                movea.l  d1, a0
  03d5e:  22 2e fe ba          move.l   -$146(a6), d1
  03d62:  d3 90                add.l    d1, (a0)
  03d64:  30 2e ff 1a          move.w   -$e6(a6), d0
  03d68:  53 6e ff 1a          subq.w   #$1, -$e6(a6)
  03d6c:  47 eb 00 0a          lea.l    $a(a3), a3
  03d70:  70 00                moveq    #$0, d0
  03d72:  30 2e ff 1a          move.w   -$e6(a6), d0
  03d76:  4a 80                tst.l    d0
  03d78:  67 1e                beq.b    $3d98
  03d7a:  20 13                move.l   (a3), d0
  03d7c:  d0 ae fe e2          add.l    -$11e(a6), d0
  03d80:  b0 ae fe e6          cmp.l    -$11a(a6), d0
  03d84:  65 12                bcs.b    $3d98
  03d86:  20 2e fe e6          move.l   -$11a(a6), d0
  03d8a:  58 80                addq.l   #$4, d0
  03d8c:  22 13                move.l   (a3), d1
  03d8e:  d2 ae fe e2          add.l    -$11e(a6), d1
  03d92:  b2 80                cmp.l    d0, d1
  03d94:  65 00 fd 58          bcs.w    $3aee
  03d98:  4a ae ff e8          tst.l    -$18(a6)
  03d9c:  66 06                bne.b    $3da4
  03d9e:  20 6e fe ca          movea.l  -$136(a6), a0
  03da2:  20 87                move.l   d7, (a0)
  03da4:  20 2e fe ca          move.l   -$136(a6), d0
  03da8:  58 ae fe ca          addq.l   #$4, -$136(a6)
  03dac:  20 2e fe e6          move.l   -$11a(a6), d0
  03db0:  58 ae fe e6          addq.l   #$4, -$11a(a6)
  03db4:  58 ae ff c2          addq.l   #$4, -$3e(a6)
  03db8:  20 2e ff c2          move.l   -$3e(a6), d0
  03dbc:  b0 ae fe de          cmp.l    -$122(a6), d0
  03dc0:  65 00 fd 00          bcs.w    $3ac2
  03dc4:  60 00 03 9e          bra.w    $4164
  03dc8:  70 00                moveq    #$0, d0
  03dca:  2d 40 ff c2          move.l   d0, -$3e(a6)
  03dce:  60 00 02 fa          bra.w    $40ca
  03dd2:  70 00                moveq    #$0, d0
  03dd4:  2d 40 ff e8          move.l   d0, -$18(a6)
  03dd8:  20 6e fe c6          movea.l  -$13a(a6), a0
  03ddc:  58 ae fe c6          addq.l   #$4, -$13a(a6)
  03de0:  2e 10                move.l   (a0), d7
  03de2:  22 2e ff fc          move.l   -$4(a6), d1
  03de6:  b3 87                eor.l    d1, d7
  03de8:  72 00                moveq    #$0, d1
  03dea:  12 2e ff f7          move.b   -$9(a6), d1
  03dee:  d3 ae ff fc          add.l    d1, -$4(a6)
  03df2:  12 2e ff ff          move.b   -$1(a6), d1
  03df6:  b3 2e ff f7          eor.b    d1, -$9(a6)
  03dfa:  60 00 02 86          bra.w    $4082
  03dfe:  70 00                moveq    #$0, d0
  03e00:  30 2c 00 06          move.w   $6(a4), d0
  03e04:  72 1c                moveq    #$1c, d1
  03e06:  b2 80                cmp.l    d0, d1
  03e08:  67 36                beq.b    $3e40
  03e0a:  60 04                bra.b    $3e10
  03e0c:  52 6c 00 04          addq.w   #$1, $4(a4)
  03e10:  30 2c 00 04          move.w   $4(a4), d0
  03e14:  48 c0                ext.l    d0
  03e16:  20 6e ff e4          movea.l  -$1c(a6), a0
  03e1a:  d0 80                add.l    d0, d0
  03e1c:  22 00                move.l   d0, d1
  03e1e:  d2 81                add.l    d1, d1
  03e20:  d0 81                add.l    d1, d0
  03e22:  72 fd                moveq    #$fd, d1
  03e24:  b2 70 08 00          cmp.w    (a0, d0.l), d1
  03e28:  67 e2                beq.b    $3e0c
  03e2a:  30 2c 00 04          move.w   $4(a4), d0
  03e2e:  48 c0                ext.l    d0
  03e30:  20 6e ff e4          movea.l  -$1c(a6), a0
  03e34:  d0 80                add.l    d0, d0
  03e36:  22 00                move.l   d0, d1
  03e38:  d2 81                add.l    d1, d1
  03e3a:  d0 81                add.l    d1, d0
  03e3c:  28 30 08 02          move.l   $2(a0, d0.l), d4
* ==================================================================
* CmdTable2 lookup
* ==================================================================
* Same index*6 addressing as CmdTable1 above, keyed off a different
* selector field.
  03e40:  30 2c 00 06          move.w   $6(a4), d0
  03e44:  65 00 02 32          bcs.w    $4078
  03e48:  0c 40 00 22          cmpi.w   #$22, d0
  03e4c:  62 00 02 2a          bhi.w    $4078
  03e50:  d0 40                add.w    d0, d0
  03e52:  30 3b 00 06          move.w   $3e5a(pc, d0.w), d0
  03e56:  4e fb 00 00          jmp      $3e58(pc,d0.w)
CmdTableJumpTable_03e5a:
* jump table (word offsets relative to $3E58):
  03e5a:  02 20                dc.w     $0220    ; sel 0 -> L04078
  03e5c:  02 20                dc.w     $0220    ; sel 1 -> L04078
  03e5e:  02 20                dc.w     $0220    ; sel 2 -> L04078
  03e60:  02 20                dc.w     $0220    ; sel 3 -> L04078
  03e62:  02 20                dc.w     $0220    ; sel 4 -> L04078
  03e64:  02 20                dc.w     $0220    ; sel 5 -> L04078
  03e66:  02 20                dc.w     $0220    ; sel 6 -> L04078
  03e68:  02 20                dc.w     $0220    ; sel 7 -> L04078
  03e6a:  02 20                dc.w     $0220    ; sel 8 -> L04078
  03e6c:  02 20                dc.w     $0220    ; sel 9 -> L04078
  03e6e:  02 20                dc.w     $0220    ; sel 10 -> L04078
  03e70:  02 20                dc.w     $0220    ; sel 11 -> L04078
  03e72:  02 20                dc.w     $0220    ; sel 12 -> L04078
  03e74:  02 20                dc.w     $0220    ; sel 13 -> L04078
  03e76:  02 20                dc.w     $0220    ; sel 14 -> L04078
  03e78:  02 20                dc.w     $0220    ; sel 15 -> L04078
  03e7a:  02 20                dc.w     $0220    ; sel 16 -> L04078
  03e7c:  02 20                dc.w     $0220    ; sel 17 -> L04078
  03e7e:  02 20                dc.w     $0220    ; sel 18 -> L04078
  03e80:  02 20                dc.w     $0220    ; sel 19 -> L04078
  03e82:  02 20                dc.w     $0220    ; sel 20 -> L04078
  03e84:  02 20                dc.w     $0220    ; sel 21 -> L04078
  03e86:  02 20                dc.w     $0220    ; sel 22 -> L04078
  03e88:  02 20                dc.w     $0220    ; sel 23 -> L04078
  03e8a:  00 4c                dc.w     $004C    ; sel 24 -> L03ea4
  03e8c:  00 ae                dc.w     $00AE    ; sel 25 -> L03f06
  03e8e:  01 02                dc.w     $0102    ; sel 26 -> L03f5a
  03e90:  01 50                dc.w     $0150    ; sel 27 -> L03fa8
  03e92:  02 20                dc.w     $0220    ; sel 28 -> L04078
  03e94:  01 d4                dc.w     $01D4    ; sel 29 -> L0402c
  03e96:  01 ee                dc.w     $01EE    ; sel 30 -> L04046
  03e98:  02 08                dc.w     $0208    ; sel 31 -> L04060
  03e9a:  02 20                dc.w     $0220    ; sel 32 -> L04078
  03e9c:  02 20                dc.w     $0220    ; sel 33 -> L04078
  03e9e:  02 20                dc.w     $0220    ; sel 34 -> L04078
  03ea0:  60 00 01 d6          bra.w    $4078
  03ea4:  20 04                move.l   d4, d0
  03ea6:  90 ae fe e6          sub.l    -$11a(a6), d0
  03eaa:  2c 00                move.l   d0, d6
  03eac:  e4 86                asr.l    #$2, d6
  03eae:  0c 86 00 00 7f ff    cmpi.l   #$7fff, d6
  03eb4:  6e 08                bgt.b    $3ebe
  03eb6:  0c 86 ff ff 80 00    cmpi.l   #$ffff8000, d6
  03ebc:  6c 22                bge.b    $3ee0
  03ebe:  41 ee fe dd          lea.l    -$123(a6), a0
  03ec2:  10 10                move.b   (a0), d0
  03ec4:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  03ec6:  10 80                move.b   d0, (a0)
  03ec8:  2f 2e fe e6          move.l   -$11a(a6), -(a7)
  03ecc:  2f 04                move.l   d4, -(a7)
  03ece:  48 7a 03 aa          pea.l    $427a(pc)
  03ed2:  61 ff ff ff f1 c8    bsr.l    $309c
  03ed8:  4f ef 00 0c          lea.l    $c(a7), a7
  03edc:  60 00 03 08          bra.w    $41e6
  03ee0:  20 3c ff 00 ff 00    move.l   #$ff00ff00, d0
  03ee6:  c0 87                and.l    d7, d0
  03ee8:  22 3c 00 00 00 ff    move.l   #$ff, d1
  03eee:  c2 86                and.l    d6, d1
  03ef0:  82 80                or.l     d0, d1
  03ef2:  20 06                move.l   d6, d0
  03ef4:  e1 88                lsl.l    #$8, d0
  03ef6:  24 3c 00 ff 00 00    move.l   #$ff0000, d2
  03efc:  c4 80                and.l    d0, d2
  03efe:  84 81                or.l     d1, d2
  03f00:  2e 02                move.l   d2, d7
  03f02:  60 00 01 74          bra.w    $4078
  03f06:  2c 04                move.l   d4, d6
  03f08:  e4 86                asr.l    #$2, d6
  03f0a:  0c 86 00 00 ff ff    cmpi.l   #$ffff, d6
  03f10:  6f 22                ble.b    $3f34
  03f12:  41 ee fe dd          lea.l    -$123(a6), a0
  03f16:  10 10                move.b   (a0), d0
  03f18:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  03f1a:  10 80                move.b   d0, (a0)
  03f1c:  2f 2e fe e6          move.l   -$11a(a6), -(a7)
  03f20:  2f 04                move.l   d4, -(a7)
  03f22:  48 7a 03 1c          pea.l    $4240(pc)
  03f26:  61 ff ff ff f1 74    bsr.l    $309c
  03f2c:  4f ef 00 0c          lea.l    $c(a7), a7
  03f30:  60 00 02 b4          bra.w    $41e6
  03f34:  20 3c ff 00 ff 00    move.l   #$ff00ff00, d0
  03f3a:  c0 87                and.l    d7, d0
  03f3c:  22 3c 00 00 00 ff    move.l   #$ff, d1
  03f42:  c2 86                and.l    d6, d1
  03f44:  82 80                or.l     d0, d1
  03f46:  20 06                move.l   d6, d0
  03f48:  e1 88                lsl.l    #$8, d0
  03f4a:  24 3c 00 ff 00 00    move.l   #$ff0000, d2
  03f50:  c4 80                and.l    d0, d2
  03f52:  84 81                or.l     d1, d2
  03f54:  2e 02                move.l   d2, d7
  03f56:  60 00 01 20          bra.w    $4078
  03f5a:  20 3c 00 00 00 ff    move.l   #$ff, d0
  03f60:  c0 87                and.l    d7, d0
  03f62:  22 07                move.l   d7, d1
  03f64:  e0 89                lsr.l    #$8, d1
  03f66:  24 3c 00 00 ff 00    move.l   #$ff00, d2
  03f6c:  c4 81                and.l    d1, d2
  03f6e:  2c 02                move.l   d2, d6
  03f70:  8c 80                or.l     d0, d6
  03f72:  2f 2e 00 10          move.l   $10(a6), -(a7)
  03f76:  2f 04                move.l   d4, -(a7)
  03f78:  61 ff ff ff ef 82    bsr.l    $2efc
  03f7e:  dc 80                add.l    d0, d6
  03f80:  20 3c ff 00 ff 00    move.l   #$ff00ff00, d0
  03f86:  c0 87                and.l    d7, d0
  03f88:  22 3c 00 00 00 ff    move.l   #$ff, d1
  03f8e:  c2 86                and.l    d6, d1
  03f90:  82 80                or.l     d0, d1
  03f92:  20 06                move.l   d6, d0
  03f94:  e1 88                lsl.l    #$8, d0
  03f96:  24 3c 00 ff 00 00    move.l   #$ff0000, d2
  03f9c:  c4 80                and.l    d0, d2
  03f9e:  84 81                or.l     d1, d2
  03fa0:  2e 02                move.l   d2, d7
  03fa2:  50 4f                addq.w   #$8, a7
  03fa4:  60 00 00 d2          bra.w    $4078
  03fa8:  20 3c 00 00 00 ff    move.l   #$ff, d0
  03fae:  c0 87                and.l    d7, d0
  03fb0:  22 07                move.l   d7, d1
  03fb2:  e0 89                lsr.l    #$8, d1
  03fb4:  24 3c 00 00 ff 00    move.l   #$ff00, d2
  03fba:  c4 81                and.l    d1, d2
  03fbc:  84 80                or.l     d0, d2
  03fbe:  70 10                moveq    #$10, d0
  03fc0:  2c 02                move.l   d2, d6
  03fc2:  e1 ae                lsl.l    d0, d6
  03fc4:  50 4c                addq.w   #$8, a4
  03fc6:  70 00                moveq    #$0, d0
  03fc8:  30 2c 00 06          move.w   $6(a4), d0
  03fcc:  72 1c                moveq    #$1c, d1
  03fce:  b2 80                cmp.l    d0, d1
  03fd0:  67 10                beq.b    $3fe2
  03fd2:  48 7a 02 40          pea.l    $4214(pc)
  03fd6:  70 00                moveq    #$0, d0
  03fd8:  2f 00                move.l   d0, -(a7)
  03fda:  61 ff 00 00 05 54    bsr.l    $4530
  03fe0:  50 4f                addq.w   #$8, a7
  03fe2:  30 2e ff 1a          move.w   -$e6(a6), d0
  03fe6:  53 6e ff 1a          subq.w   #$1, -$e6(a6)
  03fea:  70 00                moveq    #$0, d0
  03fec:  30 2c 00 04          move.w   $4(a4), d0
  03ff0:  8c 80                or.l     d0, d6
  03ff2:  2f 2e 00 10          move.l   $10(a6), -(a7)
  03ff6:  2f 04                move.l   d4, -(a7)
  03ff8:  61 ff ff ff ef 02    bsr.l    $2efc
  03ffe:  d0 86                add.l    d6, d0
  04000:  2c 00                move.l   d0, d6
  04002:  70 10                moveq    #$10, d0
  04004:  e0 a6                asr.l    d0, d6
  04006:  20 3c ff 00 ff 00    move.l   #$ff00ff00, d0
  0400c:  c0 87                and.l    d7, d0
  0400e:  22 3c 00 00 00 ff    move.l   #$ff, d1
  04014:  c2 86                and.l    d6, d1
  04016:  82 80                or.l     d0, d1
  04018:  20 06                move.l   d6, d0
  0401a:  e1 88                lsl.l    #$8, d0
  0401c:  24 3c 00 ff 00 00    move.l   #$ff0000, d2
  04022:  c4 80                and.l    d0, d2
  04024:  84 81                or.l     d1, d2
  04026:  2e 02                move.l   d2, d7
  04028:  50 4f                addq.w   #$8, a7
  0402a:  60 4c                bra.b    $4078
  0402c:  20 6e fe ca          movea.l  -$136(a6), a0
  04030:  20 87                move.l   d7, (a0)
  04032:  70 01                moveq    #$1, d0
  04034:  2d 40 ff e8          move.l   d0, -$18(a6)
  04038:  72 03                moveq    #$3, d1
  0403a:  c2 94                and.l    (a4), d1
  0403c:  d2 ae fe ca          add.l    -$136(a6), d1
  04040:  20 41                movea.l  d1, a0
  04042:  d9 10                add.b    d4, (a0)
  04044:  60 32                bra.b    $4078
  04046:  20 6e fe ca          movea.l  -$136(a6), a0
  0404a:  20 87                move.l   d7, (a0)
  0404c:  70 01                moveq    #$1, d0
  0404e:  2d 40 ff e8          move.l   d0, -$18(a6)
  04052:  72 03                moveq    #$3, d1
  04054:  c2 94                and.l    (a4), d1
  04056:  d2 ae fe ca          add.l    -$136(a6), d1
  0405a:  20 41                movea.l  d1, a0
  0405c:  d9 50                add.w    d4, (a0)
  0405e:  60 18                bra.b    $4078
  04060:  20 6e fe ca          movea.l  -$136(a6), a0
  04064:  20 87                move.l   d7, (a0)
  04066:  70 01                moveq    #$1, d0
  04068:  2d 40 ff e8          move.l   d0, -$18(a6)
  0406c:  72 03                moveq    #$3, d1
  0406e:  c2 94                and.l    (a4), d1
  04070:  d2 ae fe ca          add.l    -$136(a6), d1
  04074:  20 41                movea.l  d1, a0
  04076:  d9 90                add.l    d4, (a0)
  04078:  30 2e ff 1a          move.w   -$e6(a6), d0
  0407c:  53 6e ff 1a          subq.w   #$1, -$e6(a6)
  04080:  50 4c                addq.w   #$8, a4
  04082:  70 00                moveq    #$0, d0
  04084:  30 2e ff 1a          move.w   -$e6(a6), d0
  04088:  4a 80                tst.l    d0
  0408a:  67 1e                beq.b    $40aa
  0408c:  20 14                move.l   (a4), d0
  0408e:  d0 ae fe e2          add.l    -$11e(a6), d0
  04092:  b0 ae fe e6          cmp.l    -$11a(a6), d0
  04096:  65 12                bcs.b    $40aa
  04098:  20 2e fe e6          move.l   -$11a(a6), d0
  0409c:  58 80                addq.l   #$4, d0
  0409e:  22 14                move.l   (a4), d1
  040a0:  d2 ae fe e2          add.l    -$11e(a6), d1
  040a4:  b2 80                cmp.l    d0, d1
  040a6:  65 00 fd 56          bcs.w    $3dfe
  040aa:  4a ae ff e8          tst.l    -$18(a6)
  040ae:  66 06                bne.b    $40b6
  040b0:  20 6e fe ca          movea.l  -$136(a6), a0
  040b4:  20 87                move.l   d7, (a0)
  040b6:  20 2e fe ca          move.l   -$136(a6), d0
  040ba:  58 ae fe ca          addq.l   #$4, -$136(a6)
  040be:  20 2e fe e6          move.l   -$11a(a6), d0
  040c2:  58 ae fe e6          addq.l   #$4, -$11a(a6)
  040c6:  58 ae ff c2          addq.l   #$4, -$3e(a6)
  040ca:  20 2e ff c2          move.l   -$3e(a6), d0
  040ce:  b0 ae fe de          cmp.l    -$122(a6), d0
  040d2:  65 00 fc fe          bcs.w    $3dd2
  040d6:  60 00 00 8c          bra.w    $4164
  040da:  4a ae ff fc          tst.l    -$4(a6)
  040de:  67 60                beq.b    $4140
  040e0:  2d 6e fe ca fe be    move.l   -$136(a6), -$142(a6)
  040e6:  59 8f                subq.l   #$4, a7
  040e8:  2f 2e fe d8          move.l   -$128(a6), -(a7)
  040ec:  61 ff 00 00 07 06    bsr.l    $47f4
  040f2:  2d 5f fe c2          move.l   (a7)+, -$13e(a6)
  040f6:  70 00                moveq    #$0, d0
  040f8:  2d 40 ff c6          move.l   d0, -$3a(a6)
  040fc:  60 34                bra.b    $4132
  040fe:  20 6e fe c2          movea.l  -$13e(a6), a0
  04102:  58 ae fe c2          addq.l   #$4, -$13e(a6)
  04106:  20 2e ff fc          move.l   -$4(a6), d0
  0410a:  22 10                move.l   (a0), d1
  0410c:  b1 81                eor.l    d0, d1
  0410e:  20 6e fe be          movea.l  -$142(a6), a0
  04112:  58 ae fe be          addq.l   #$4, -$142(a6)
  04116:  20 81                move.l   d1, (a0)
  04118:  70 00                moveq    #$0, d0
  0411a:  10 2e ff f7          move.b   -$9(a6), d0
  0411e:  d1 ae ff fc          add.l    d0, -$4(a6)
  04122:  10 2e ff ff          move.b   -$1(a6), d0
  04126:  b1 2e ff f7          eor.b    d0, -$9(a6)
  0412a:  20 2e ff c6          move.l   -$3a(a6), d0
  0412e:  52 ae ff c6          addq.l   #$1, -$3a(a6)
  04132:  20 2e fe de          move.l   -$122(a6), d0
  04136:  e4 88                lsr.l    #$2, d0
  04138:  b0 ae ff c6          cmp.l    -$3a(a6), d0
  0413c:  62 c0                bhi.b    $40fe
  0413e:  60 18                bra.b    $4158
  04140:  59 8f                subq.l   #$4, a7
  04142:  2f 2e fe d8          move.l   -$128(a6), -(a7)
  04146:  61 ff 00 00 06 ac    bsr.l    $47f4
  0414c:  20 5f                movea.l  (a7)+, a0
  0414e:  22 6e fe ca          movea.l  -$136(a6), a1
  04152:  20 2e fe de          move.l   -$122(a6), d0
  04156:  a0 2e                dc.w     $a02e  ; _BlockMove
  04158:  20 2e fe de          move.l   -$122(a6), d0
  0415c:  e4 88                lsr.l    #$2, d0
  0415e:  e5 80                asl.l    #$2, d0
  04160:  d1 ae fe e6          add.l    d0, -$11a(a6)
  04164:  41 ee fe dd          lea.l    -$123(a6), a0
  04168:  10 10                move.b   (a0), d0
  0416a:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  0416c:  10 80                move.b   d0, (a0)
  0416e:  20 2e ff ca          move.l   -$36(a6), d0
  04172:  52 ae ff ca          addq.l   #$1, -$36(a6)
  04176:  70 00                moveq    #$0, d0
  04178:  30 2e ff 24          move.w   -$dc(a6), d0
  0417c:  b0 ae ff ca          cmp.l    -$36(a6), d0
  04180:  62 00 f2 5a          bhi.w    $33dc
  04184:  20 2e ff ba          move.l   -$46(a6), d0
  04188:  52 ae ff ba          addq.l   #$1, -$46(a6)
  0418c:  70 02                moveq    #$2, d0
  0418e:  b0 ae ff ba          cmp.l    -$46(a6), d0
  04192:  6c 00 f2 00          bge.w    $3394
  04196:  4a ae 00 0c          tst.l    $c(a6)
  0419a:  67 12                beq.b    $41ae
  0419c:  4a 2e ff d7          tst.b    -$29(a6)
  041a0:  66 0c                bne.b    $41ae
  041a2:  20 2e ff d8          move.l   -$28(a6), d0
  041a6:  58 80                addq.l   #$4, d0
  041a8:  20 6e 00 0c          movea.l  $c(a6), a0
  041ac:  20 80                move.l   d0, (a0)
  041ae:  2f 2e 00 10          move.l   $10(a6), -(a7)
  041b2:  2f 2e fe ea          move.l   -$116(a6), -(a7)
  041b6:  61 ff ff ff ed 44    bsr.l    $2efc
  041bc:  2d 40 fe ea          move.l   d0, -$116(a6)
  041c0:  4a ae ff e4          tst.l    -$1c(a6)
  041c4:  50 4f                addq.w   #$8, a7
  041c6:  67 0c                beq.b    $41d4
  041c8:  2f 2e ff e4          move.l   -$1c(a6), -(a7)
  041cc:  61 ff ff ff ed 14    bsr.l    $2ee2
  041d2:  58 4f                addq.w   #$4, a7
  041d4:  48 7a 00 2e          pea.l    $4204(pc)
  041d8:  61 ff ff ff ee ca    bsr.l    $30a4
  041de:  20 2e fe ea          move.l   -$116(a6), d0
  041e2:  58 4f                addq.w   #$4, a7
  041e4:  60 14                bra.b    $41fa
  041e6:  4a ae ff e4          tst.l    -$1c(a6)
  041ea:  67 0c                beq.b    $41f8
  041ec:  2f 2e ff e4          move.l   -$1c(a6), -(a7)
  041f0:  61 ff ff ff ec f0    bsr.l    $2ee2
  041f6:  58 4f                addq.w   #$4, a7
  041f8:  70 00                moveq    #$0, d0
  041fa:  4c ee 18 f0 fe a2    movem.l  -$15e(a6), d4-d7/a3-a4
  04200:  4e 5e                unlk     a6
  04202:  4e 75                rts      
  04204:  4c                   dc.b     $4c  ; L
  04205:  6f 61                ble.b    $4268
  04207:  64 20                bcc.b    $4229
  04209:  43                   dc.b     $43  ; C
  0420a:  6f 6d                ble.b    $4279
  0420c:  70 6c                moveq    #$6c, d0
  0420e:  65 74                bcs.b    $4284
  04210:  65 2e                bcs.b    $4240
  04212:  0d 00                btst.l   d6, d0
  04214:  65 72                bcs.b    $4288
  04216:  72 6f                moveq    #$6f, d1
  04218:  72 3a                moveq    #$3a, d1
  0421a:  20 72 65 6c 6f 63    movea.l  $6f63(a2, invalid.w), a0
  04220:  61 74                bsr.b    $4296
  04222:  69 6f                bvs.b    $4293
  04224:  6e 20                bgt.b    $4246
  04226:  72 65                moveq    #$65, d1
  04228:  63 6f                bls.b    $4299
  0422a:  72 64                moveq    #$64, d1
  0422c:  73                   dc.b     $73  ; s
  0422d:  20 6f 75 74          movea.l  $7574(a7), a0
  04231:  20 6f 66 20          movea.l  $6620(a7), a0
  04235:  73                   dc.b     $73  ; s
  04236:  65 71                bcs.b    $42a9
  04238:  75                   dc.b     $75  ; u
  04239:  65 6e                bcs.b    $42a9
  0423b:  63 65                bls.b    $42a2
  0423d:  0d 00                btst.l   d6, d0
  0423f:  00 41 62 73          ori.w    #$6273, d1
  04243:  6f 6c                ble.b    $42b1
  04245:  75                   dc.b     $75  ; u
  04246:  74 65                moveq    #$65, d2
  04248:  20 42                movea.l  d2, a0
  0424a:  72 61                moveq    #$61, d1
  0424c:  6e 63                bgt.b    $42b1
  0424e:  68 20                bvc.b    $4270
  04250:  54 61                addq.w   #$2, -(a1)
  04252:  72 67                moveq    #$67, d1
  04254:  65 74                bcs.b    $42ca
  04256:  20 28 30 78          move.l   $3078(a0), d0
  0425a:  25 30 38 78          move.l   $78(a0, d3.l), -(a2)
  0425e:  29 20                move.l   -(a0), -(a4)
  04260:  4f 75                dc.b     $4f,$75  ; Ou
  04262:  74 20                moveq    #$20, d2
  04264:  6f 66                ble.b    $42cc
  04266:  20 52                movea.l  (a2), a0
  04268:  61 6e                bsr.b    $42d8
  0426a:  67 65                beq.b    $42d1
  0426c:  20 61                movea.l  -(a1), a0
  0426e:  74 20                moveq    #$20, d2
  04270:  30 78 25 30          movea.w  $2530.w, a0
  04274:  38 58                movea.w  (a0)+, a4
  04276:  20 0d                move.l   a5, d0
  04278:  00 00 52 65          ori.b    #$65, d0
  0427c:  6c 61                bge.b    $42df
  0427e:  74 69                moveq    #$69, d2
  04280:  76 65                moveq    #$65, d3
  04282:  20 42                movea.l  d2, a0
  04284:  72 61                moveq    #$61, d1
  04286:  6e 63                bgt.b    $42eb
  04288:  68 20                bvc.b    $42aa
  0428a:  54 61                addq.w   #$2, -(a1)
  0428c:  72 67                moveq    #$67, d1
  0428e:  65 74                bcs.b    $4304
  04290:  20 28 30 78          move.l   $3078(a0), d0
  04294:  25 30 38 78          move.l   $78(a0, d3.l), -(a2)
  04298:  29 20                move.l   -(a0), -(a4)
  0429a:  4f 75                dc.b     $4f,$75  ; Ou
  0429c:  74 20                moveq    #$20, d2
  0429e:  6f 66                ble.b    $4306
  042a0:  20 52                movea.l  (a2), a0
  042a2:  61 6e                bsr.b    $4312
  042a4:  67 65                beq.b    $430b
  042a6:  20 61                movea.l  -(a1), a0
  042a8:  74 20                moveq    #$20, d2
  042aa:  30 78 25 30          movea.w  $2530.w, a0
  042ae:  38 58                movea.w  (a0)+, a4
  042b0:  20 0d                move.l   a5, d0
  042b2:  00 00 73 65          ori.b    #$65, d0
  042b6:  65 6b                bcs.b    $4323
  042b8:  20 70 61 73 74 20 65 6e 64 20 movea.l  ([$7420656e, a0], $aaaaaaaa), a0
  042c2:  6f 66                ble.b    $432a
  042c4:  20 66                movea.l  -(a6), a0
  042c6:  69 6c                bvs.b    $4334
  042c8:  65 20                bcs.b    $42ea
  042ca:  69 6e                bvs.b    $433a
  042cc:  20 41                movea.l  d1, a0
  042ce:  43 45                dc.b     $43,$45  ; CE
  042d0:  46 6c 6f 61          not.w    $6f61(a4)
  042d4:  64 3a                bcc.b    $4310
  042d6:  20 25                move.l   -(a5), d0
  042d8:  64 0d                bcc.b    $42e7
  042da:  00 00 4d 75          ori.b    #$75, d0
  042de:  6c 74                bge.b    $4354
  042e0:  69 70                bvs.b    $4352
  042e2:  6c 65                bge.b    $4349
  042e4:  20 2e 42 53          move.l   $4253(a6), d0
  042e8:  53 20                subq.b   #$1, -(a0)
  042ea:  73                   dc.b     $73  ; s
  042eb:  65 63                bcs.b    $4350
  042ed:  74 69                moveq    #$69, d2
  042ef:  6f 6e                ble.b    $435f
  042f1:  73                   dc.b     $73  ; s
  042f2:  20 6e 6f 74          movea.l  $6f74(a6), a0
  042f6:  20 61                movea.l  -(a1), a0
  042f8:  6c 6c                bge.b    $4366
  042fa:  6f 77                ble.b    $4373
  042fc:  65 64                bcs.b    $4362
  042fe:  20 69 6e 20          movea.l  $6e20(a1), a0
  04302:  72 65                moveq    #$65, d1
  04304:  6c 6f                bge.b    $4375
  04306:  63 61                bls.b    $4369
  04308:  74 61                moveq    #$61, d2
  0430a:  62 6c                bhi.b    $4378
  0430c:  65 20                bcs.b    $432e
  0430e:  66 69                bne.b    $4379
  04310:  6c 65                bge.b    $4377
  04312:  00 00 43 6f          ori.b    #$6f, d0
  04316:  64 65                bcc.b    $437d
  04318:  00 00 53 65          ori.b    #$65, d0
  0431c:  63 74                bls.b    $4392
  0431e:  69 6f                bvs.b    $438f
  04320:  6e 20                bgt.b    $4342
  04322:  25 38 73 3a          move.l   $733a.w, -(a2)
  04326:  20 28 30 78          move.l   $3078(a0), d0
  0432a:  25 30 38 78          move.l   $78(a0, d3.l), -(a2)
  0432e:  29 20                move.l   -(a0), -(a4)
  04330:  25 64 20 41          move.l   -(a4), $2041(a2)
  04334:  64 64                bcc.b    $439a
  04336:  72 65                moveq    #$65, d1
  04338:  73 73                dc.b     $73,$73  ; ss
  0433a:  3a 20                move.w   -(a0), d5
  0433c:  25 58 20 73          move.l   (a0)+, $2073(a2)
  04340:  69 7a                bvs.b    $43bc
  04342:  65 3a                bcs.b    $437e
  04344:  20 25                move.l   -(a5), d0
  04346:  64 20                bcc.b    $4368
  04348:  25 73 20 61 74 20    move.l   $61(a3, d2.w), $7420(a2)
  0434e:  30 78 25 30          movea.w  $2530.w, a0
  04352:  38 58                movea.w  (a0)+, a4
  04354:  0d 00                btst.l   d6, d0
  04356:  6c 6f                bge.b    $43c7
  04358:  61 64                bsr.b    $43be
  0435a:  65 64                bcs.b    $43c0
  0435c:  00 00 7a 65          ori.b    #$65, d0
  04360:  72 6f                moveq    #$6f, d1
  04362:  65 64                bcs.b    $43c8
  04364:  00 00 4c 6f          ori.b    #$6f, d0
  04368:  61 64                bsr.b    $43ce
  0436a:  65 72                bcs.b    $43de
  0436c:  20 6c 69 6d          movea.l  $696d(a4), a0
  04370:  69 74                bvs.b    $43e6
  04372:  20 6f 66 20          movea.l  $6620(a7), a0
  04376:  33 32 20 74          move.w   $74(a2, d2.w), -(a1)
  0437a:  65 78                bcs.b    $43f4
  0437c:  74 20                moveq    #$20, d2
  0437e:  73                   dc.b     $73  ; s
  0437f:  65 63                bcs.b    $43e4
  04381:  74 69                moveq    #$69, d2
  04383:  6f 6e                ble.b    $43f3
  04385:  73                   dc.b     $73  ; s
  04386:  0d 00                btst.l   d6, d0
  04388:  50 75 62 6c          addq.w   #$8, $6c(a5, d6.w)
  0438c:  69 63                bvs.b    $43f1
  0438e:  49                   dc.b     $49  ; I
  0438f:  6e 00 00 53          bgt.w    $43e4
  04393:  6b 69                bmi.b    $43fe
  04395:  70 70                moveq    #$70, d0
  04397:  69 6e                bvs.b    $4407
  04399:  67 20                beq.b    $43bb
  0439b:  53 65                subq.w   #$1, -(a5)
  0439d:  63 74                bls.b    $4413
  0439f:  69 6f                bvs.b    $4410
  043a1:  6e 20                bgt.b    $43c3
  043a3:  25 38 73 3a          move.l   $733a.w, -(a2)
  043a7:  20 28 30 78          move.l   $3078(a0), d0
  043ab:  25 30 38 78          move.l   $78(a0, d3.l), -(a2)
  043af:  29 20                move.l   -(a0), -(a4)
  043b1:  25 64 20 41          move.l   -(a4), $2041(a2)
  043b5:  64 64                bcc.b    $441b
  043b7:  72 65                moveq    #$65, d1
  043b9:  73 73                dc.b     $73,$73  ; ss
  043bb:  3a 20                move.w   -(a0), d5
  043bd:  25 58 20 73          move.l   (a0)+, $2073(a2)
  043c1:  69 7a                bvs.b    $443d
  043c3:  65 3a                bcs.b    $43ff
  043c5:  20 25                move.l   -(a5), d0
  043c7:  64 0d                bcc.b    $43d6
  043c9:  00 70 61 73 73 20 25 64 ori.w    #$6173, $2564(a0, d7.w * 2)
  043d1:  3a 20                move.w   -(a0), d5
  043d3:  73                   dc.b     $73  ; s
  043d4:  63 6e                bls.b    $4444
  043d6:  5f 70 74 72          subq.w   #$7, $72(a0, d7.w)
  043da:  20                   dc.b     $20  ;  
  043db:  3d 20                move.w   -(a0), -(a6)
  043dd:  25 30 38 78          move.l   $78(a0, d3.l), -(a2)
  043e1:  2c 72 65 6c 5f 70    movea.l  $5f70(a2, invalid.w), a6
  043e7:  74 72                moveq    #$72, d2
  043e9:  20                   dc.b     $20  ;  
  043ea:  3d 20                move.w   -(a0), -(a6)
  043ec:  25 30 38 78          move.l   $78(a0, d3.l), -(a2)
  043f0:  0d 00                btst.l   d6, d0
  043f2:  4c                   dc.b     $4c  ; L
  043f3:  6f 61                ble.b    $4456
  043f5:  64 69                bcc.b    $4460
  043f7:  6e 67                bgt.b    $4460
  043f9:  20 25                move.l   -(a5), d0
  043fb:  64 20                bcc.b    $441d
  043fd:  73                   dc.b     $73  ; s
  043fe:  65 63                bcs.b    $4463
  04400:  74 69                moveq    #$69, d2
  04402:  6f 6e                ble.b    $4472
  04404:  73                   dc.b     $73  ; s
  04405:  2e 0d                move.l   a5, d7
  04407:  00 54 65 78          ori.w    #$6578, (a4)
  0440b:  74 20                moveq    #$20, d2
  0440d:  62 61                bhi.b    $4470
  0440f:  73                   dc.b     $73  ; s
  04410:  65 20                bcs.b    $4432
  04412:  3d 20                move.w   -(a0), -(a6)
  04414:  25 58 0d 00          move.l   (a0)+, $d00(a2)
  04418:  4e 6f                move     usp, a7
  0441a:  74 20                moveq    #$20, d2
  0441c:  65 6e                bcs.b    $448c
  0441e:  6f 75                ble.b    $4495
  04420:  67 68                beq.b    $448a
  04422:  20 6d 65 6d          movea.l  $656d(a5), a0
  04426:  6f 72                ble.b    $449a
  04428:  79                   dc.b     $79  ; y
  04429:  20 74 6f 20 6c 6f    movea.l  $6c6f(a4, d6.l * 8), a0
  0442f:  61 64                bsr.b    $4495
  04431:  20 70 72 6f          movea.l  $6f(a0, d7.w), a0
  04435:  67 72                beq.b    $44a9
  04437:  61 6d                bsr.b    $44a6
  04439:  0d 00                btst.l   d6, d0
  0443b:  00                   dc.b     $00  ; .
  0443c:  4e 6f                move     usp, a7
  0443e:  20 4d                movea.l  a5, a0
  04440:  65 6d                bcs.b    $44af
  04442:  6f 72                ble.b    $44b6
  04444:  79                   dc.b     $79  ; y
  04445:  20 66                movea.l  -(a6), a0
  04447:  6f 72                ble.b    $44bb
  04449:  20 73 79 6d 62 6f    movea.l  ([$626f, a3]), a0
  0444f:  6c 20                bge.b    $4471
  04451:  74 61                moveq    #$61, d2
  04453:  62 6c                bhi.b    $44c1
  04455:  65 00 00 4c          bcs.w    $44a3
  04459:  6f 61                ble.b    $44bc
  0445b:  64 20                bcc.b    $447d
  0445d:  61 74                bsr.b    $44d3
  0445f:  20 25                move.l   -(a5), d0
  04461:  30 38 58 2c          move.w   $582c.w, d0
  04465:  20 4d                movea.l  a5, a0
  04467:  61 67                bsr.b    $44d0
  04469:  69 63                bvs.b    $44ce
  0446b:  3a 20                move.w   -(a0), d5
  0446d:  30 78 25 30          movea.w  $2530.w, a0
  04471:  38 78 20 53          movea.w  $2053.w, a4
  04475:  65 63                bcs.b    $44da
  04477:  74 69                moveq    #$69, d2
  04479:  6f 6e                ble.b    $44e9
  0447b:  73                   dc.b     $73  ; s
  0447c:  3a 20                move.w   -(a0), d5
  0447e:  25 64 20 53          move.l   -(a4), $2053(a2)
  04482:  79                   dc.b     $79  ; y
  04483:  6d 62                blt.b    $44e7
  04485:  6f 6c                ble.b    $44f3
  04487:  73                   dc.b     $73  ; s
  04488:  3a 20                move.w   -(a0), d5
  0448a:  25 64 20 46          move.l   -(a4), $2046(a2)
  0448e:  6c 61                bge.b    $44f1
  04490:  67 73                beq.b    $4505
  04492:  3a 20                move.w   -(a0), d5
  04494:  25 30 78 0d          move.l   $d(a0, d7.l), -(a2)
  04498:  00 00 50 72          ori.b    #$72, d0
  0449c:  6f 67                ble.b    $4505
  0449e:  72 61                moveq    #$61, d1
  044a0:  6d 20                blt.b    $44c2
  044a2:  27 25                move.l   -(a5), -(a3)
  044a4:  73                   dc.b     $73  ; s
  044a5:  27 20                move.l   -(a0), -(a3)
  044a7:  76 65                moveq    #$65, d3
  044a9:  72 73                moveq    #$73, d1
  044ab:  69 6f                bvs.b    $451c
  044ad:  6e 20                bgt.b    $44cf
  044af:  25 30 38 78          move.l   $78(a0, d3.l), -(a2)
  044b3:  20 64                movea.l  -(a4), a0
  044b5:  61 74                bsr.b    $452b
  044b7:  65 20                bcs.b    $44d9
  044b9:  25 64 0d 00          move.l   -(a4), $d00(a2)
  044bd:  00 49                dc.b     $00,$49  ; .I
  044bf:  6e 76                bgt.b    $4537
  044c1:  61 6c                bsr.b    $452f
  044c3:  69 64                bvs.b    $4529
  044c5:  20 66                movea.l  -(a6), a0
  044c7:  6f 72                ble.b    $453b
  044c9:  6d 61                blt.b    $452c
  044cb:  74 21                moveq    #$21, d2
  044cd:  00 28 63 29 20 43    ori.b    #$29, $2043(a0)
  044d3:  6f 70                ble.b    $4545
  044d5:  79                   dc.b     $79  ; y
  044d6:  72 69                moveq    #$69, d1
  044d8:  67 68                beq.b    $4542
  044da:  74 20                moveq    #$20, d2
  044dc:  41                   dc.b     $41  ; A
  044dd:  70 70                moveq    #$70, d0
  044df:  6c 65                bge.b    $4546
  044e1:  20 43                movea.l  d3, a0
  044e3:  6f 6d                ble.b    $4552
  044e5:  70 75                moveq    #$75, d0
  044e7:  74 65                moveq    #$65, d2
  044e9:  72 2c                moveq    #$2c, d1
  044eb:  31 39 39 30 2e 41    move.w   $39302e41.l, -(a0)
  044f1:  6c 6c                bge.b    $455f
  044f3:  20 52                movea.l  (a2), a0
  044f5:  69 67                bvs.b    $455e
  044f7:  68 74                bvc.b    $456d
  044f9:  73                   dc.b     $73  ; s
  044fa:  20 52                movea.l  (a2), a0
  044fc:  65 73                bcs.b    $4571
  044fe:  65 72                bcs.b    $4572  ; -> GetTrap
  04500:  76 65                moveq    #$65, d3
  04502:  64 00 4e 6f          bcc.w    $9373
  04506:  74 20                moveq    #$20, d2
  04508:  69 6e                bvs.b    $4578
  0450a:  20 41                movea.l  d1, a0
  0450c:  43 45                dc.b     $43,$45  ; CE
  0450e:  46 20                not.b    -(a0)
  04510:  66 6f                bne.b    $4581
  04512:  72 6d                moveq    #$6d, d1
  04514:  61 74                bsr.b    $458a
  04516:  21 00                move.l   d0, -(a0)
  04518:  49                   dc.b     $49  ; I
  04519:  6e 69                bgt.b    $4584
  0451b:  74 69                moveq    #$69, d2
  0451d:  61 6c                bsr.b    $458b
  0451f:  69 7a                bvs.b    $459b
  04521:  61 74                bsr.b    $4597
  04523:  69 6f                bvs.b    $4594
  04525:  6e 20                bgt.b    $4547
  04527:  66 61                bne.b    $458a
  04529:  69 6c                bvs.b    $4597
  0452b:  65 64                bcs.b    $4591
  0452d:  0d 00                btst.l   d6, d0
  0452f:  00                   dc.b     $00  ; .
  04530:  4e 56 00 00          link.w   a6, #$0
  04534:  4a ae 00 08          tst.l    $8(a6)
  04538:  67 26                beq.b    $4560
  0453a:  2f 2e 00 28          move.l   $28(a6), -(a7)
  0453e:  2f 2e 00 24          move.l   $24(a6), -(a7)
  04542:  2f 2e 00 20          move.l   $20(a6), -(a7)
  04546:  2f 2e 00 1c          move.l   $1c(a6), -(a7)
  0454a:  2f 2e 00 18          move.l   $18(a6), -(a7)
  0454e:  2f 2e 00 14          move.l   $14(a6), -(a7)
  04552:  2f 2e 00 10          move.l   $10(a6), -(a7)
  04556:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  0455a:  61 ff ff ff eb 48    bsr.l    $30a4
  04560:  4e 5e                unlk     a6
  04562:  4e 75                rts      
  04564:  22 5f                movea.l  (a7)+, a1
  04566:  20 5f                movea.l  (a7)+, a0
  04568:  a0 25                dc.w     $a025  ; _GetHandleSize
  0456a:  2e 80                move.l   d0, (a7)
  0456c:  6a 02                bpl.b    $4570
  0456e:  42 97                clr.l    (a7)
  04570:  4e d1                jmp      (a1)
* GetTrap  -  fetch the current handler of a Toolbox or OS trap
* (selected by the caller's flag byte) via _Get*TrapAddress.  Used to
* save the original bottleneck routine before InstallPatches replaces it.
GetTrap:
  04572:  22 5f                movea.l  (a7)+, a1
  04574:  12 1f                move.b   (a7)+, d1
  04576:  30 1f                move.w   (a7)+, d0
  04578:  4a 01                tst.b    d1
  0457a:  67 04                beq.b    $4580
  0457c:  a7 46                dc.w     $a746  ; _GetToolTrapAddress
  0457e:  60 02                bra.b    $4582
  04580:  a3 46                dc.w     $a346  ; _GetOSTrapAddress
  04582:  2e 88                move.l   a0, (a7)
  04584:  4e d1                jmp      (a1)
* SetTrap  -  install a new handler at a Toolbox or OS trap
* (selected by the caller's flag byte) via _Get*/_Set*TrapAddress.
SetTrap:
  04586:  22 5f                movea.l  (a7)+, a1
  04588:  12 1f                move.b   (a7)+, d1
  0458a:  30 1f                move.w   (a7)+, d0
  0458c:  20 5f                movea.l  (a7)+, a0
  0458e:  4a 01                tst.b    d1
  04590:  67 04                beq.b    $4596
  04592:  a6 47                dc.w     $a647  ; _SetToolTrapAddress
  04594:  60 02                bra.b    $4598
  04596:  a2 47                dc.w     $a247  ; _SetOSTrapAddress
  04598:  4e d1                jmp      (a1)
  0459a:  22 5f                movea.l  (a7)+, a1
  0459c:  72 00                moveq    #$0, d1
  0459e:  32 2f 00 04          move.w   $4(a7), d1
  045a2:  20 78 03 4e          movea.l  $34e.w, a0
  045a6:  30 38 03 f6          move.w   $3f6.w, d0
  045aa:  6b 04                bmi.b    $45b0
  045ac:  82 c0                divu.w   d0, d1
  045ae:  60 04                bra.b    $45b4
  045b0:  82 fc 00 5e          divu.w   #$5e, d1
  045b4:  48 41                swap     d1
  045b6:  55 41                subq.w   #$2, d1
  045b8:  66 14                bne.b    $45ce
  045ba:  30 2f 00 04          move.w   $4(a7), d0
  045be:  b0 50                cmp.w    (a0), d0
  045c0:  64 0c                bcc.b    $45ce
  045c2:  20 70 00 14          movea.l  $14(a0, d0.w), a0
  045c6:  30 28 00 4e          move.w   $4e(a0), d0
  045ca:  72 00                moveq    #$0, d1
  045cc:  60 06                bra.b    $45d4
  045ce:  70 00                moveq    #$0, d0
  045d0:  32 3c ff cd          move.w   #$ffcd, d1
  045d4:  20 57                movea.l  (a7), a0
  045d6:  30 80                move.w   d0, (a0)
  045d8:  5c 4f                addq.w   #$6, a7
  045da:  3e 81                move.w   d1, (a7)
  045dc:  4e d1                jmp      (a1)
  045de:  22 5f                movea.l  (a7)+, a1
  045e0:  70 03                moveq    #$3, d0
  045e2:  a1 98                dc.w     $a198  ; _HWPriv
  045e4:  4e d1                jmp      (a1)
  045e6:  4e 56 00 00          link.w   a6, #$0
  045ea:  20 3c 00 00 a8 9f    move.l   #$a89f, d0
  045f0:  a7 46                dc.w     $a746  ; _GetToolTrapAddress
  045f2:  2f 08                move.l   a0, -(a7)
  045f4:  20 3c 00 00 a0 ad    move.l   #$a0ad, d0
  045fa:  a3 46                dc.w     $a346  ; _GetOSTrapAddress
  045fc:  b1 df                cmpa.l   (a7)+, a0
  045fe:  67 0e                beq.b    $460e
  04600:  20 2e 00 0c          move.l   $c(a6), d0
  04604:  a1 ad                dc.w     $a1ad  ; _Gestalt
  04606:  22 6e 00 08          movea.l  $8(a6), a1
  0460a:  22 88                move.l   a0, (a1)
  0460c:  60 26                bra.b    $4634
  0460e:  41 fa 00 36          lea.l    $4646(pc), a0
  04612:  30 3c ea 51          move.w   #$ea51, d0
  04616:  22 2e 00 0c          move.l   $c(a6), d1
  0461a:  b2 98                cmp.l    (a0)+, d1
  0461c:  67 06                beq.b    $4624
  0461e:  4a 98                tst.l    (a0)+
  04620:  67 12                beq.b    $4634
  04622:  60 f6                bra.b    $461a
  04624:  43 fa 00 20          lea.l    $4646(pc), a1
  04628:  d3 d0                adda.l   (a0), a1
  0462a:  4e d1                jmp      (a1)
  0462c:  22 6e 00 08          movea.l  $8(a6), a1
  04630:  22 80                move.l   d0, (a1)
  04632:  42 40                clr.w    d0
  04634:  3d 40 00 10          move.w   d0, $10(a6)
  04638:  4e 5e                unlk     a6
  0463a:  20 5f                movea.l  (a7)+, a0
  0463c:  50 8f                addq.l   #$8, a7
  0463e:  4e d0                jmp      (a0)
  04640:  30 3c ea 52          move.w   #$ea52, d0
  04644:  60 ee                bra.b    $4634
  04646:  76 65                moveq    #$65, d3
  04648:  72 73                moveq    #$73, d1
  0464a:  00 00 00 60          ori.b    #$60, d0
  0464e:  6d 61                blt.b    $46b1
  04650:  63 68                bls.b    $46ba
  04652:  00 00 00 64          ori.b    #$64, d0
  04656:  73 79 73             dc.b     $73,$79,$73  ; sys
  04659:  76 00                moveq    #$0, d3
  0465b:  00 00 88 70          ori.b    #$70, d0
  0465f:  72 6f                moveq    #$6f, d1
  04661:  63 00 00 00          bls.w    $4663
  04665:  92 66                sub.w    -(a6), d1
  04667:  70 75                moveq    #$75, d0
  04669:  20 00                move.l   d0, d0
  0466b:  00 00 9e 71          ori.b    #$71, d0
  0466f:  64 20                bcc.b    $4691
  04671:  20 00                move.l   d0, d0
  04673:  00 00 e8 6b          ori.b    #$6b, d0
  04677:  62 64                bhi.b    $46dd
  04679:  20 00                move.l   d0, d0
  0467b:  00 01 1a 61          ori.b    #$61, d1
  0467f:  74 6c                moveq    #$6c, d2
  04681:  6b 00 00 01          bmi.w    $4684
  04685:  42 6d 6d 75          clr.w    $6d75(a5)
  04689:  20 00                move.l   d0, d0
  0468b:  00 01 64 72          ori.b    #$72, d1
  0468f:  61 6d                bsr.b    $46fe
  04691:  20 00                move.l   d0, d0
  04693:  00 01 88 6c          ori.b    #$6c, d1
  04697:  72 61                moveq    #$61, d1
  04699:  6d 00 00 01          blt.w    $469c
  0469d:  88 00                or.b     d0, d4
  0469f:  00 00 00 00          ori.b    #$0, d0
  046a3:  00 00 00 70          ori.b    #$70, d0
  046a7:  01 60                bchg.b   d0, -(a0)
  046a9:  82 22                or.b     -(a2), d1
  046ab:  78 02                moveq    #$2, d4
  046ad:  ae 70                dc.w     $ae70  ; A-trap 0xae70 (unidentified)
  046af:  04                   dc.b     $04  ; .
  046b0:  0c 69 00 75 00 08    cmpi.w   #$75, $8(a1)
  046b6:  67 12                beq.b    $46ca
  046b8:  0c 69 02 76 00 08    cmpi.w   #$276, $8(a1)
  046be:  66 04                bne.b    $46c4
  046c0:  52 40                addq.w   #$1, d0
  046c2:  60 06                bra.b    $46ca
  046c4:  10 38 0c b3          move.b   $cb3.w, d0
  046c8:  5c 80                addq.l   #$6, d0
  046ca:  60 00 ff 60          bra.w    $462c
  046ce:  70 00                moveq    #$0, d0
  046d0:  30 38 01 5a          move.w   $15a.w, d0
  046d4:  60 00 ff 56          bra.w    $462c
  046d8:  70 00                moveq    #$0, d0
  046da:  10 38 01 2f          move.b   $12f.w, d0
  046de:  52 40                addq.w   #$1, d0
  046e0:  60 00 ff 4a          bra.w    $462c
  046e4:  0c 38 00 04 01 2f    cmpi.b   #$4, $12f.w
  046ea:  67 38                beq.b    $4724
  046ec:  08 38 00 04 0b 22    btst.b   #$4, $b22.w
  046f2:  67 34                beq.b    $4728
  046f4:  20 4f                movea.l  a7, a0
  046f6:  f2 80 00 00          fnop     
  046fa:  f3 27                fsave    -(a7)
  046fc:  30 17                move.w   (a7), d0
  046fe:  2e 48                movea.l  a0, a7
  04700:  0c 40 1f 18          cmpi.w   #$1f18, d0
  04704:  67 16                beq.b    $471c
  04706:  0c 40 3f 18          cmpi.w   #$3f18, d0
  0470a:  67 10                beq.b    $471c
  0470c:  0c 40 3f 38          cmpi.w   #$3f38, d0
  04710:  67 0e                beq.b    $4720
  04712:  0c 40 1f 38          cmpi.w   #$1f38, d0
  04716:  67 08                beq.b    $4720
  04718:  70 00                moveq    #$0, d0
  0471a:  60 0e                bra.b    $472a
  0471c:  70 01                moveq    #$1, d0
  0471e:  60 0a                bra.b    $472a
  04720:  70 02                moveq    #$2, d0
  04722:  60 06                bra.b    $472a
  04724:  70 03                moveq    #$3, d0
  04726:  60 02                bra.b    $472a
  04728:  70 00                moveq    #$0, d0
  0472a:  60 00 ff 00          bra.w    $462c
  0472e:  0c 78 3f ff 02 8e    cmpi.w   #$3fff, $28e.w
  04734:  6e 1c                bgt.b    $4752
  04736:  30 3c a8 9f          move.w   #$a89f, d0
  0473a:  a7 46                dc.w     $a746  ; _GetToolTrapAddress
  0473c:  24 08                move.l   a0, d2
  0473e:  20 3c 00 00 ab 03    move.l   #$ab03, d0
  04744:  a7 46                dc.w     $a746  ; _GetToolTrapAddress
  04746:  20 3c 00 00 01 00    move.l   #$100, d0
  0474c:  b4 88                cmp.l    a0, d2
  0474e:  66 06                bne.b    $4756
  04750:  60 0a                bra.b    $475c
  04752:  70 00                moveq    #$0, d0
  04754:  60 06                bra.b    $475c
  04756:  20 3c 00 00 02 00    move.l   #$200, d0
  0475c:  60 00 fe ce          bra.w    $462c
  04760:  10 38 02 1e          move.b   $21e.w, d0
  04764:  41 fa 00 16          lea.l    $477c(pc), a0
  04768:  22 48                movea.l  a0, a1
  0476a:  12 18                move.b   (a0)+, d1
  0476c:  67 00 fe d2          beq.w    $4640
  04770:  b2 00                cmp.b    d0, d1
  04772:  66 f6                bne.b    $476a
  04774:  91 c9                suba.l   a1, a0
  04776:  20 08                move.l   a0, d0
  04778:  60 00 fe b2          bra.w    $462c
  0477c:  03 13                btst.l   d1, (a3)
  0477e:  0b 02                btst.l   d5, d2
  04780:  01 06                btst.l   d0, d6
  04782:  07 04                btst.l   d3, d4
  04784:  05 08 09 00          movep.w  $900(a0), d2
  04788:  70 00                moveq    #$0, d0
  0478a:  4a 38 02 91          tst.b    $291.w
  0478e:  6b 16                bmi.b    $47a6
  04790:  12 38 01 fb          move.b   $1fb.w, d1
  04794:  02 01 00 0f          andi.b   #$f, d1
  04798:  0c 01 00 01          cmpi.b   #$1, d1
  0479c:  66 08                bne.b    $47a6
  0479e:  20 78 02 dc          movea.l  $2dc.w, a0
  047a2:  10 28 00 07          move.b   $7(a0), d0
  047a6:  60 00 fe 84          bra.w    $462c
  047aa:  0c 38 00 02 01 2f    cmpi.b   #$2, $12f.w
  047b0:  6d 16                blt.b    $47c8
  047b2:  70 00                moveq    #$0, d0
  047b4:  10 38 0c b1          move.b   $cb1.w, d0
  047b8:  0c 00 00 01          cmpi.b   #$1, d0
  047bc:  67 0c                beq.b    $47ca
  047be:  0c 00 00 03          cmpi.b   #$3, d0
  047c2:  6d 04                blt.b    $47c8
  047c4:  53 40                subq.w   #$1, d0
  047c6:  60 02                bra.b    $47ca
  047c8:  70 00                moveq    #$0, d0
  047ca:  60 00 fe 60          bra.w    $462c
  047ce:  30 3c a8 9f          move.w   #$a89f, d0
  047d2:  a7 46                dc.w     $a746  ; _GetToolTrapAddress
  047d4:  24 08                move.l   a0, d2
  047d6:  20 3c 00 00 a8 8f    move.l   #$a88f, d0
  047dc:  a7 46                dc.w     $a746  ; _GetToolTrapAddress
  047de:  20 38 01 08          move.l   $108.w, d0
  047e2:  b4 88                cmp.l    a0, d2
  047e4:  67 0a                beq.b    $47f0
  047e6:  59 8f                subq.l   #$4, a7
  047e8:  3f 3c 00 16          move.w   #$16, -(a7)
  047ec:  a8 8f                dc.w     $a88f  ; _OSDispatch
  047ee:  20 1f                move.l   (a7)+, d0
  047f0:  60 00 fe 3a          bra.w    $462c
  047f4:  22 5f                movea.l  (a7)+, a1
  047f6:  20 1f                move.l   (a7)+, d0
  047f8:  08 38 00 06 02 8e    btst.b   #$6, $28e.w
  047fe:  66 06                bne.b    $4806
  04800:  a0 55                dc.w     $a055  ; _StripAddress
  04802:  2e 80                move.l   d0, (a7)
  04804:  4e d1                jmp      (a1)
  04806:  c0 b8 03 1a          and.l    $31a.w, d0
  0480a:  2e 80                move.l   d0, (a7)
  0480c:  4e d1                jmp      (a1)
  0480e:  22 1f                move.l   (a7)+, d1
  04810:  24 1f                move.l   (a7)+, d2
  04812:  22 42                movea.l  d2, a1
  04814:  22 51                movea.l  (a1), a1
  04816:  20 5f                movea.l  (a7)+, a0
  04818:  70 05                moveq    #$5, d0
  0481a:  a1 5c                dc.w     $a15c  ; _MemoryDispatchA0Result
  0481c:  3e 80                move.w   d0, (a7)
  0481e:  22 42                movea.l  d2, a1
  04820:  22 88                move.l   a0, (a1)
  04822:  22 41                movea.l  d1, a1
  04824:  4e d1                jmp      (a1)
