* ==================================================================
*  '8*24 GC' INIT  (resource 'INIT' id -4048, 3488 bytes, from 824GC.rsrc)
* ==================================================================
*  This is the boot-time driver-installer/handshake half of the 8*24 GC
*  control-panel software: it does NOT touch hardware directly (no
*  _SlotManager/_HWPriv/Set*TrapAddress calls anywhere in this file --
*  contrast DRVR.s and gc24.s) -- it only opens the '.GraphAccel'
*  driver by name and drives it through a short Control/Status
*  handshake, posting a Notification-Manager 'product ready' message
*  (localised via a STR# family also referenced from the cdev) and
*  closing the driver again afterwards.  See Main's header below for
*  the full boot sequence.
*
*  Two embedded MacsBug symbols (p2cstr, c2pstr -- shared with several
*  other 68k modules in this project) and two more (PLStrCat, PLStrCpy)
*  recovered the same way as in gc24.s (a length-prefixed name",
*  0x80|len, follows each function's rts).  Trap names from Apple
*  CIncludes/Traps.h; disassembled by recursive descent + linear sweep
*  (same toolchain as gc24.s / DRVR.s).
*
* ==================================================================
* Main  -  the '8*24 GC' INIT (id -4048).  Runs once at boot, from the
* System Folder's Extensions/INIT loading pass.
* ==================================================================
* Overall flow (all confirmed from the disassembly below):
*   1. _GetKeys, then ShowIconOrAlert(mode=-4047, id=50) -- returns a
*      fixed sentinel ($D8EF) on the expected/normal path; anything
*      else silently exits (an early up-front environment/identity
*      check, exact mechanism not fully reverse engineered).
*   2. Probes whether Toolbox trap $A8B5 is implemented (GetTrapAddr
*      vs. the address of _Unimplemented); bails if not.  (Apple's
*      Traps.h maps $A8B5 to _ScriptUtil; two more calls to it, with
*      selector-like longs $84020008/$8404000C, most likely fetch the
*      current script/language code into D6 -- D6 is then used
*      directly as '1000+D6' to pick a *localised* STR# resource
*      below, which is exactly the kind of thing ScriptUtil is for.)
*   3. Loads STR#(1000+D6) (falling back to STR#(1000) if that
*      language variant doesn't exist) -- this is the very same
*      STR#1000.. family of per-language string lists inventoried in
*      README.md.  Also loads STR(-4048) -- a single Pascal string
*      resource holding this product's display name.
*   4. Picks one string out of the STR# list via GetIndStringManual
*      (index clamped to 0 or 1 -- plausibly 'monitor attached' vs.
*      'no monitor attached', matching the develop article's note that
*      the 8*24 GC stays active with no monitor connected, unlike its
*      plain 8*24 sibling), and builds
*          fullMessage = productName + literal@$422 + pickedString
*      via PLStrCpy + PLStrCat, then posts it as a Notification
*      Manager alert (NMInstall) -- the boot-time 'product ready'
*      chime/blinking-icon notification.
*   5. OpenDriverByName('.GraphAccel', &refNum) -- opens the low-level
*      accelerator driver disassembled in DRVR.s.
*   6. Issues a short, hard-coded sequence of Control/Status calls to
*      it (csCode values 0x63, 0x15, 0x05, 0x0E, 0x05 again, 0x14,
*      0x0D) via ControlDriverSync/StatusDriverSync, branching on bits
*      of the Status results -- effectively a scripted 'bring the
*      accelerator up' handshake.  (Cross-referencing DRVR.s: Status
*      csCode 0x15=21 -> Sts_GetField_24c, csCode 5 -> Sts_GetField_008
*      -- the true meaning of those two globals fields isn't known,
*      so this handshake's exact semantics aren't claimed beyond
*      'success/failure gates the rest of the sequence'.)
*   7. On success: ShowIconOrAlert(mode=0, id=50) (the 'ok' chime,
*      using resource id 50 directly rather than a message string) and
*      CloseDriverSync -- the driver is NOT kept open by this INIT;
*      it is a one-shot boot-time handshake, not a resident client.
*   8. On any failure: ShowIconOrAlert(mode=-4047, id=50) (the 'error'
*      variant), a short _Delay, then CloseDriverSync -- same cleanup.
*
* Local frame (A6-relative) worth naming:
*   -$28(a6)  16-byte GetKeys map
*   -$40(a6)  the driver refNum returned by OpenDriverByName
*   -$3E(a6)  small Control/Status csParam scratch area
*   -$3C(a6)  Status-result long (bits tested to branch the handshake)
Main:
  00000:  4e 56 fe a4          link.w   a6, #$fea4
  00004:  48 e7 0f 38          movem.l  d4-d7/a2-a4, -(a7)
  00008:  48 6e ff d8          pea.l    -$28(a6)
  0000c:  a9 76                dc.w     $a976  ; _GetKeys
  0000e:  48 6e ff c0          pea.l    -$40(a6)
  00012:  48 7a 04 0e          pea.l    $422(pc)
  00016:  61 ff 00 00 0c e0    bsr.l    $cf8  ; -> OpenDriverByName
  0001c:  38 00                move.w   d0, d4
  0001e:  50 4f                addq.w   #$8, a7
  00020:  67 00 01 e4          beq.w    $206
  00024:  3f 3c f0 31          move.w   #$f031, -(a7)
  00028:  70 32                moveq    #$32, d0
  0002a:  3f 00                move.w   d0, -(a7)
  0002c:  61 ff 00 00 09 6c    bsr.l    $99a  ; -> ShowIconOrAlert
  00032:  0c 44 d8 ef          cmpi.w   #$d8ef, d4
  00036:  66 00 03 dc          bne.w    $414
  0003a:  2c 3c ff ff f0 3f    move.l   #$fffff03f, d6
  00040:  59 8f                subq.l   #$4, a7
  00042:  3f 3c a8 b5          move.w   #$a8b5, -(a7)
  00046:  70 01                moveq    #$1, d0
  00048:  1f 00                move.b   d0, -(a7)
  0004a:  61 ff 00 00 0b f0    bsr.l    $c3c  ; -> GetTrapAddr
  00050:  59 8f                subq.l   #$4, a7
  00052:  3f 3c a8 9f          move.w   #$a89f, -(a7)
  00056:  70 01                moveq    #$1, d0
  00058:  1f 00                move.b   d0, -(a7)
  0005a:  61 ff 00 00 0b e0    bsr.l    $c3c  ; -> GetTrapAddr
  00060:  20 1f                move.l   (a7)+, d0
  00062:  b0 9f                cmp.l    (a7)+, d0
  00064:  67 00 03 ae          beq.w    $414
  00068:  59 8f                subq.l   #$4, a7
  0006a:  59 8f                subq.l   #$4, a7
  0006c:  70 12                moveq    #$12, d0
  0006e:  3f 00                move.w   d0, -(a7)
  00070:  2f 3c 84 02 00 08    move.l   #$84020008, -(a7)
  00076:  a8 b5                dc.w     $a8b5  ; _ScriptUtil
  00078:  20 1f                move.l   (a7)+, d0
  0007a:  3f 00                move.w   d0, -(a7)
  0007c:  70 1c                moveq    #$1c, d0
  0007e:  3f 00                move.w   d0, -(a7)
  00080:  2f 3c 84 04 00 0c    move.l   #$8404000c, -(a7)
  00086:  a8 b5                dc.w     $a8b5  ; _ScriptUtil
  00088:  2c 1f                move.l   (a7)+, d6
  0008a:  2d 46 ff b0          move.l   d6, -$50(a6)
  0008e:  dc bc 00 00 03 e8    add.l    #$3e8, d6
  00094:  59 8f                subq.l   #$4, a7
  00096:  2f 3c 53 54 52 23    move.l   #$53545223, -(a7)
  0009c:  3f 06                move.w   d6, -(a7)
  0009e:  a8 1f                dc.w     $a81f  ; _Get1Resource
  000a0:  2d 5f ff b4          move.l   (a7)+, -$4c(a6)
  000a4:  66 02                bne.b    $a8
  000a6:  7c 00                moveq    #$0, d6
  000a8:  59 8f                subq.l   #$4, a7
  000aa:  2f 3c 53 54 52 23    move.l   #$53545223, -(a7)
  000b0:  3f 06                move.w   d6, -(a7)
  000b2:  a8 1f                dc.w     $a81f  ; _Get1Resource
  000b4:  2d 5f ff b4          move.l   (a7)+, -$4c(a6)
  000b8:  67 00 03 5a          beq.w    $414
  000bc:  2f 2e ff b4          move.l   -$4c(a6), -(a7)
  000c0:  a9 a2                dc.w     $a9a2  ; _LoadResource
  000c2:  48 c4                ext.l    d4
  000c4:  2a 3c ff ff d8 f1    move.l   #$ffffd8f1, d5
  000ca:  9a 84                sub.l    d4, d5
  000cc:  20 6e ff b4          movea.l  -$4c(a6), a0
  000d0:  20 50                movea.l  (a0), a0
  000d2:  2d 48 fe a8          move.l   a0, -$158(a6)
  000d6:  30 10                move.w   (a0), d0
  000d8:  48 c0                ext.l    d0
  000da:  b0 85                cmp.l    d5, d0
  000dc:  6d 06                blt.b    $e4
  000de:  70 01                moveq    #$1, d0
  000e0:  b0 85                cmp.l    d5, d0
  000e2:  6f 02                ble.b    $e6
  000e4:  7a 01                moveq    #$1, d5
  000e6:  59 8f                subq.l   #$4, a7
  000e8:  2f 3c 53 54 52 20    move.l   #$53545220, -(a7)
  000ee:  3f 3c f0 30          move.w   #$f030, -(a7)
  000f2:  a8 1f                dc.w     $a81f  ; _Get1Resource
  000f4:  2d 5f ff b8          move.l   (a7)+, -$48(a6)
  000f8:  67 00 01 02          beq.w    $1fc
  000fc:  2f 2e ff b8          move.l   -$48(a6), -(a7)
  00100:  a9 a2                dc.w     $a9a2  ; _LoadResource
  00102:  20 6e ff b8          movea.l  -$48(a6), a0
  00106:  a0 29                dc.w     $a029  ; _HLock
  00108:  20 6e ff b8          movea.l  -$48(a6), a0
  0010c:  2d 50 ff ac          move.l   (a0), -$54(a6)
  00110:  48 6e fe ac          pea.l    -$154(a6)
  00114:  3f 06                move.w   d6, -(a7)
  00116:  3f 05                move.w   d5, -(a7)
  00118:  61 ff 00 00 0b 98    bsr.l    $cb2  ; -> GetIndStringManual
  0011e:  20 3c 00 00 01 00    move.l   #$100, d0
  00124:  a5 1e                dc.w     $a51e  ; _NewPtrSys
  00126:  26 48                movea.l  a0, a3
  00128:  20 0b                move.l   a3, d0
  0012a:  67 00 00 ca          beq.w    $1f6
  0012e:  59 8f                subq.l   #$4, a7
  00130:  2f 0b                move.l   a3, -(a7)
  00132:  2f 2e ff ac          move.l   -$54(a6), -(a7)
  00136:  61 ff 00 00 0c 42    bsr.l    $d7a  ; -> PLStrCpy
  0013c:  59 8f                subq.l   #$4, a7
  0013e:  2f 0b                move.l   a3, -(a7)
  00140:  48 7a 02 dc          pea.l    $41e(pc)
  00144:  61 ff 00 00 0b f2    bsr.l    $d38  ; -> PLStrCat
  0014a:  59 8f                subq.l   #$4, a7
  0014c:  2f 0b                move.l   a3, -(a7)
  0014e:  48 6e fe ac          pea.l    -$154(a6)
  00152:  61 ff 00 00 0b e4    bsr.l    $d38  ; -> PLStrCat
  00158:  70 24                moveq    #$24, d0
  0015a:  a5 1e                dc.w     $a51e  ; _NewPtrSys
  0015c:  28 48                movea.l  a0, a4
  0015e:  20 0c                move.l   a4, d0
  00160:  4f ef 00 0c          lea.l    $c(a7), a7
  00164:  67 78                beq.b    $1de
  00166:  41 fb 01 70 00 00 03 00 lea.l    $300(a16, invalid.w), a0
  0016e:  43 fb 01 70 00 00 02 be lea.l    $2be(a16, invalid.w), a1
  00176:  91 c9                suba.l   a1, a0
  00178:  20 08                move.l   a0, d0
  0017a:  a5 1e                dc.w     $a51e  ; _NewPtrSys
  0017c:  2d 48 ff bc          move.l   a0, -$44(a6)
  00180:  20 08                move.l   a0, d0
  00182:  67 5a                beq.b    $1de
  00184:  41 fb 01 70 00 00 02 a8 lea.l    $2a8(a16, invalid.w), a0
  0018c:  22 6e ff bc          movea.l  -$44(a6), a1
  00190:  45 fb 01 70 00 00 02 d6 lea.l    $2d6(a16, invalid.w), a2
  00198:  2d 48 fe a4          move.l   a0, -$15c(a6)
  0019c:  41 fb 01 70 00 00 02 90 lea.l    $290(a16, invalid.w), a0
  001a4:  95 c8                suba.l   a0, a2
  001a6:  20 0a                move.l   a2, d0
  001a8:  20 6e fe a4          movea.l  -$15c(a6), a0
  001ac:  a0 2e                dc.w     $a02e  ; _BlockMove
  001ae:  39 7c 00 08 00 04    move.w   #$8, $4(a4)
  001b4:  42 6c 00 0e          clr.w    $e(a4)
  001b8:  70 00                moveq    #$0, d0
  001ba:  29 40 00 10          move.l   d0, $10(a4)
  001be:  29 40 00 14          move.l   d0, $14(a4)
  001c2:  29 4b 00 18          move.l   a3, $18(a4)
  001c6:  29 6e ff bc 00 1c    move.l   -$44(a6), $1c(a4)
  001cc:  29 4b 00 20          move.l   a3, $20(a4)
  001d0:  55 8f                subq.l   #$2, a7
  001d2:  2f 0c                move.l   a4, -(a7)
  001d4:  20 5f                movea.l  (a7)+, a0
  001d6:  a0 5e                dc.w     $a05e  ; _NMInstall
  001d8:  3e 80                move.w   d0, (a7)
  001da:  54 4f                addq.w   #$2, a7
  001dc:  60 18                bra.b    $1f6
  001de:  20 4b                movea.l  a3, a0
  001e0:  a0 1f                dc.w     $a01f  ; _DisposPtr
  001e2:  20 0c                move.l   a4, d0
  001e4:  67 04                beq.b    $1ea
  001e6:  20 4c                movea.l  a4, a0
  001e8:  a0 1f                dc.w     $a01f  ; _DisposPtr
  001ea:  4a ae ff bc          tst.l    -$44(a6)
  001ee:  67 06                beq.b    $1f6
  001f0:  20 6e ff bc          movea.l  -$44(a6), a0
  001f4:  a0 1f                dc.w     $a01f  ; _DisposPtr
  001f6:  2f 2e ff b8          move.l   -$48(a6), -(a7)
  001fa:  a9 a3                dc.w     $a9a3  ; _ReleaseResource
  001fc:  2f 2e ff b4          move.l   -$4c(a6), -(a7)
  00200:  a9 a3                dc.w     $a9a3  ; _ReleaseResource
  00202:  60 00 02 10          bra.w    $414
  00206:  42 6e ff c2          clr.w    -$3e(a6)
  0020a:  55 8f                subq.l   #$2, a7
  0020c:  3f 2e ff c0          move.w   -$40(a6), -(a7)
  00210:  70 63                moveq    #$63, d0
  00212:  3f 00                move.w   d0, -(a7)
  00214:  48 6e ff c2          pea.l    -$3e(a6)
  00218:  61 ff 00 00 0a 36    bsr.l    $c50  ; -> ControlDriverSync
  0021e:  4a 5f                tst.w    (a7)+
  00220:  66 00 01 ca          bne.w    $3ec
  00224:  55 8f                subq.l   #$2, a7
  00226:  3f 2e ff c0          move.w   -$40(a6), -(a7)
  0022a:  70 15                moveq    #$15, d0
  0022c:  3f 00                move.w   d0, -(a7)
  0022e:  48 6e ff c2          pea.l    -$3e(a6)
  00232:  61 ff 00 00 0a 52    bsr.l    $c86  ; -> StatusDriverSync
  00238:  4a 5f                tst.w    (a7)+
  0023a:  66 00 01 b0          bne.w    $3ec
  0023e:  4a ae ff c4          tst.l    -$3c(a6)
  00242:  6d 00 01 a8          blt.w    $3ec
  00246:  55 8f                subq.l   #$2, a7
  00248:  3f 2e ff c0          move.w   -$40(a6), -(a7)
  0024c:  70 05                moveq    #$5, d0
  0024e:  3f 00                move.w   d0, -(a7)
  00250:  48 6e ff c2          pea.l    -$3e(a6)
  00254:  61 ff 00 00 0a 30    bsr.l    $c86  ; -> StatusDriverSync
  0025a:  4a 5f                tst.w    (a7)+
  0025c:  66 00 01 8e          bne.w    $3ec
  00260:  2e 2e ff c4          move.l   -$3c(a6), d7
  00264:  70 01                moveq    #$1, d0
  00266:  c0 87                and.l    d7, d0
  00268:  67 00 01 82          beq.w    $3ec
  0026c:  70 07                moveq    #$7, d0
  0026e:  c0 87                and.l    d7, d0
  00270:  72 07                moveq    #$7, d1
  00272:  b2 80                cmp.l    d0, d1
  00274:  67 1e                beq.b    $294
  00276:  55 8f                subq.l   #$2, a7
  00278:  3f 2e ff c0          move.w   -$40(a6), -(a7)
  0027c:  70 05                moveq    #$5, d0
  0027e:  3f 00                move.w   d0, -(a7)
  00280:  48 6e ff c2          pea.l    -$3e(a6)
  00284:  61 ff 00 00 0a 00    bsr.l    $c86  ; -> StatusDriverSync
  0028a:  4a 5f                tst.w    (a7)+
  0028c:  66 00 01 5e          bne.w    $3ec
  00290:  2e 2e ff c4          move.l   -$3c(a6), d7
  00294:  70 20                moveq    #$20, d0
  00296:  c0 87                and.l    d7, d0
  00298:  66 00 00 ce          bne.w    $368
  0029c:  59 8f                subq.l   #$4, a7
  0029e:  2f 3c 50 75 70 53    move.l   #$50757053, -(a7)
  002a4:  70 00                moveq    #$0, d0
  002a6:  3f 00                move.w   d0, -(a7)
  002a8:  a8 1f                dc.w     $a81f  ; _Get1Resource
  002aa:  2d 5f ff f8          move.l   (a7)+, -$8(a6)
  002ae:  67 10                beq.b    $2c0
  002b0:  55 8f                subq.l   #$2, a7
  002b2:  a9 af                dc.w     $a9af  ; _ResError
  002b4:  4a 5f                tst.w    (a7)+
  002b6:  66 08                bne.b    $2c0
  002b8:  20 6e ff f8          movea.l  -$8(a6), a0
  002bc:  4a 90                tst.l    (a0)
  002be:  66 26                bne.b    $2e6
  002c0:  42 6e ff c2          clr.w    -$3e(a6)
  002c4:  2d 7c ff ff d8 db ff c4 move.l   #$ffffd8db, -$3c(a6)
  002cc:  55 8f                subq.l   #$2, a7
  002ce:  3f 2e ff c0          move.w   -$40(a6), -(a7)
  002d2:  70 14                moveq    #$14, d0
  002d4:  3f 00                move.w   d0, -(a7)
  002d6:  48 6e ff c2          pea.l    -$3e(a6)
  002da:  61 ff 00 00 09 74    bsr.l    $c50  ; -> ControlDriverSync
  002e0:  54 4f                addq.w   #$2, a7
  002e2:  60 00 01 08          bra.w    $3ec
  002e6:  20 6e ff f8          movea.l  -$8(a6), a0
  002ea:  20 50                movea.l  (a0), a0
  002ec:  43 ee ff e8          lea.l    -$18(a6), a1
  002f0:  22 d8                move.l   (a0)+, (a1)+
  002f2:  22 d8                move.l   (a0)+, (a1)+
  002f4:  22 d8                move.l   (a0)+, (a1)+
  002f6:  22 d8                move.l   (a0)+, (a1)+
  002f8:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  002fc:  a9 a3                dc.w     $a9a3  ; _ReleaseResource
  002fe:  55 8f                subq.l   #$2, a7
  00300:  a9 af                dc.w     $a9af  ; _ResError
  00302:  4a 5f                tst.w    (a7)+
  00304:  67 26                beq.b    $32c
  00306:  42 6e ff c2          clr.w    -$3e(a6)
  0030a:  2d 7c ff ff d8 db ff c4 move.l   #$ffffd8db, -$3c(a6)
  00312:  55 8f                subq.l   #$2, a7
  00314:  3f 2e ff c0          move.w   -$40(a6), -(a7)
  00318:  70 14                moveq    #$14, d0
  0031a:  3f 00                move.w   d0, -(a7)
  0031c:  48 6e ff c2          pea.l    -$3e(a6)
  00320:  61 ff 00 00 09 2e    bsr.l    $c50  ; -> ControlDriverSync
  00326:  54 4f                addq.w   #$2, a7
  00328:  60 00 00 c2          bra.w    $3ec
  0032c:  4a ae ff e8          tst.l    -$18(a6)
  00330:  67 1c                beq.b    $34e
  00332:  55 8f                subq.l   #$2, a7
  00334:  3f 2e ff c0          move.w   -$40(a6), -(a7)
  00338:  70 0d                moveq    #$d, d0
  0033a:  3f 00                move.w   d0, -(a7)
  0033c:  48 6e ff c2          pea.l    -$3e(a6)
  00340:  61 ff 00 00 09 0e    bsr.l    $c50  ; -> ControlDriverSync
  00346:  4a 5f                tst.w    (a7)+
  00348:  66 00 00 a2          bne.w    $3ec
  0034c:  60 1a                bra.b    $368
  0034e:  55 8f                subq.l   #$2, a7
  00350:  3f 2e ff c0          move.w   -$40(a6), -(a7)
  00354:  70 0e                moveq    #$e, d0
  00356:  3f 00                move.w   d0, -(a7)
  00358:  48 6e ff c2          pea.l    -$3e(a6)
  0035c:  61 ff 00 00 08 f2    bsr.l    $c50  ; -> ControlDriverSync
  00362:  4a 5f                tst.w    (a7)+
  00364:  66 00 00 86          bne.w    $3ec
  00368:  48 6e ff d8          pea.l    -$28(a6)
  0036c:  a9 76                dc.w     $a976  ; _GetKeys
  0036e:  20 2e ff dc          move.l   -$24(a6), d0
  00372:  08 00 00 00          btst.b   #$0, d0
  00376:  67 18                beq.b    $390
  00378:  55 8f                subq.l   #$2, a7
  0037a:  3f 2e ff c0          move.w   -$40(a6), -(a7)
  0037e:  70 0e                moveq    #$e, d0
  00380:  3f 00                move.w   d0, -(a7)
  00382:  48 6e ff c2          pea.l    -$3e(a6)
  00386:  61 ff 00 00 08 c8    bsr.l    $c50  ; -> ControlDriverSync
  0038c:  4a 5f                tst.w    (a7)+
  0038e:  66 5c                bne.b    $3ec
  00390:  55 8f                subq.l   #$2, a7
  00392:  3f 2e ff c0          move.w   -$40(a6), -(a7)
  00396:  70 05                moveq    #$5, d0
  00398:  3f 00                move.w   d0, -(a7)
  0039a:  48 6e ff c2          pea.l    -$3e(a6)
  0039e:  61 ff 00 00 08 e6    bsr.l    $c86  ; -> StatusDriverSync
  003a4:  4a 5f                tst.w    (a7)+
  003a6:  66 44                bne.b    $3ec
  003a8:  2e 2e ff c4          move.l   -$3c(a6), d7
  003ac:  70 20                moveq    #$20, d0
  003ae:  c0 87                and.l    d7, d0
  003b0:  66 1c                bne.b    $3ce
  003b2:  42 6e ff c2          clr.w    -$3e(a6)
  003b6:  55 8f                subq.l   #$2, a7
  003b8:  3f 2e ff c0          move.w   -$40(a6), -(a7)
  003bc:  70 15                moveq    #$15, d0
  003be:  3f 00                move.w   d0, -(a7)
  003c0:  48 6e ff c2          pea.l    -$3e(a6)
  003c4:  61 ff 00 00 08 8a    bsr.l    $c50  ; -> ControlDriverSync
  003ca:  54 4f                addq.w   #$2, a7
  003cc:  60 1e                bra.b    $3ec
  003ce:  70 00                moveq    #$0, d0
  003d0:  3f 00                move.w   d0, -(a7)
  003d2:  72 32                moveq    #$32, d1
  003d4:  3f 01                move.w   d1, -(a7)
  003d6:  61 ff 00 00 05 c2    bsr.l    $99a  ; -> ShowIconOrAlert
  003dc:  55 8f                subq.l   #$2, a7
  003de:  3f 2e ff c0          move.w   -$40(a6), -(a7)
  003e2:  61 ff 00 00 08 3a    bsr.l    $c1e  ; -> CloseDriverSync
  003e8:  54 4f                addq.w   #$2, a7
  003ea:  60 28                bra.b    $414
  003ec:  3f 3c f0 31          move.w   #$f031, -(a7)
  003f0:  70 32                moveq    #$32, d0
  003f2:  3f 00                move.w   d0, -(a7)
  003f4:  61 ff 00 00 05 a4    bsr.l    $99a  ; -> ShowIconOrAlert
  003fa:  30 7c 00 50          movea.w  #$50, a0
  003fe:  43 ee ff fc          lea.l    -$4(a6), a1
  00402:  a0 3b                dc.w     $a03b  ; _Delay
  00404:  22 80                move.l   d0, (a1)
  00406:  55 8f                subq.l   #$2, a7
  00408:  3f 2e ff c0          move.w   -$40(a6), -(a7)
  0040c:  61 ff 00 00 08 10    bsr.l    $c1e  ; -> CloseDriverSync
  00412:  54 4f                addq.w   #$2, a7
  00414:  4c ee 1c f0 fe 88    movem.l  -$178(a6), d4-d7/a2-a4
  0041a:  4e 5e                unlk     a6
  0041c:  4e 75                rts      
  0041e:  01 0d 00 00          movep.w  $0(a5), d0
  00422:  2e 47 72 61 70 68 41 63 63 65 6c 00 dc.b     $2e,$47,$72,$61,$70,$68,$41,$63,$63,$65,$6c,$00  ; .GraphAccel.
  0042e:  4e 56 00 00          link.w   a6, #$0
  00432:  2f 0c                move.l   a4, -(a7)
  00434:  28 6e 00 08          movea.l  $8(a6), a4
  00438:  4a ac 00 20          tst.l    $20(a4)
  0043c:  67 06                beq.b    $444
  0043e:  20 6c 00 20          movea.l  $20(a4), a0
  00442:  a0 1f                dc.w     $a01f  ; _DisposPtr
  00444:  55 8f                subq.l   #$2, a7
  00446:  2f 0c                move.l   a4, -(a7)
  00448:  20 5f                movea.l  (a7)+, a0
  0044a:  a0 5f                dc.w     $a05f  ; _NMRemove
  0044c:  3e 80                move.w   d0, (a7)
  0044e:  20 4c                movea.l  a4, a0
  00450:  a0 1f                dc.w     $a01f  ; _DisposPtr
  00452:  41 fb 01 70 ff ff ff da lea.l    $ffffffda(a16, invalid.w), a0
  0045a:  a0 1f                dc.w     $a01f  ; _DisposPtr
  0045c:  54 4f                addq.w   #$2, a7
  0045e:  28 6e ff fc          movea.l  -$4(a6), a4
  00462:  4e 5e                unlk     a6
  00464:  4e 74 00 04          rtd      #$4
  00468:  4e 56 00 00          link.w   a6, #$0
  0046c:  4e 5e                unlk     a6
  0046e:  4e 75                rts      
  00470:  4e 56 ff d4          link.w   a6, #$ffd4
  00474:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  00478:  18 2e 00 17          move.b   $17(a6), d4
  0047c:  2c 2e 00 0c          move.l   $c(a6), d6
  00480:  26 6e 00 10          movea.l  $10(a6), a3
  00484:  28 6e 00 08          movea.l  $8(a6), a4
  00488:  59 8f                subq.l   #$4, a7
  0048a:  aa 32                dc.w     $aa32  ; _GetGDevice
  0048c:  20 5f                movea.l  (a7)+, a0
  0048e:  2d 48 ff fc          move.l   a0, -$4(a6)
  00492:  20 50                movea.l  (a0), a0
  00494:  30 28 00 26          move.w   $26(a0), d0
  00498:  48 c0                ext.l    d0
  0049a:  2e 00                move.l   d0, d7
  0049c:  42 ae ff dc          clr.l    -$24(a6)
  004a0:  3d 7c 00 20 ff e2    move.w   #$20, -$1e(a6)
  004a6:  3d 7c 00 20 ff e0    move.w   #$20, -$20(a6)
  004ac:  42 ae ff ec          clr.l    -$14(a6)
  004b0:  3d 6c 00 2e ff d6    move.w   $2e(a4), -$2a(a6)
  004b6:  30 2c 00 2e          move.w   $2e(a4), d0
  004ba:  d0 7c 00 20          add.w    #$20, d0
  004be:  3d 40 ff da          move.w   d0, -$26(a6)
  004c2:  3d 46 ff d4          move.w   d6, -$2c(a6)
  004c6:  48 6e ff f4          pea.l    -$c(a6)
  004ca:  48 6e ff f8          pea.l    -$8(a6)
  004ce:  20 3c 00 08 00 05    move.l   #$80005, d0
  004d4:  ab 1d                dc.w     $ab1d  ; _QDExtensions
  004d6:  4a 2c 00 34          tst.b    $34(a4)
  004da:  67 36                beq.b    $512
  004dc:  42 2c 00 34          clr.b    $34(a4)
  004e0:  2f 0b                move.l   a3, -(a7)
  004e2:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  004e6:  20 3c 00 08 00 06    move.l   #$80006, d0
  004ec:  ab 1d                dc.w     $ab1d  ; _QDExtensions
  004ee:  20 6c 00 46          movea.l  $46(a4), a0
  004f2:  20 68 00 02          movea.l  $2(a0), a0
  004f6:  2f 10                move.l   (a0), -(a7)
  004f8:  48 6b 00 02          pea.l    $2(a3)
  004fc:  20 6c 00 46          movea.l  $46(a4), a0
  00500:  48 68 00 10          pea.l    $10(a0)
  00504:  48 6c 00 36          pea.l    $36(a4)
  00508:  70 00                moveq    #$0, d0
  0050a:  3f 00                move.w   d0, -(a7)
  0050c:  72 00                moveq    #$0, d1
  0050e:  2f 01                move.l   d1, -(a7)
  00510:  a8 ec                dc.w     $a8ec  ; _CopyBits
  00512:  3d 46 ff d4          move.w   d6, -$2c(a6)
  00516:  30 06                move.w   d6, d0
  00518:  d0 7c 00 20          add.w    #$20, d0
  0051c:  3d 40 ff d8          move.w   d0, -$28(a6)
  00520:  4a 04                tst.b    d4
  00522:  66 00 00 ae          bne.w    $5d2
  00526:  4a ac 00 08          tst.l    $8(a4)
  0052a:  67 00 00 a6          beq.w    $5d2
  0052e:  4a 6e ff d8          tst.w    -$28(a6)
  00532:  6f 00 00 9e          ble.w    $5d2
  00536:  20 6c 00 46          movea.l  $46(a4), a0
  0053a:  43 ee ff e4          lea.l    -$1c(a6), a1
  0053e:  41 e8 00 10          lea.l    $10(a0), a0
  00542:  22 d8                move.l   (a0)+, (a1)+
  00544:  22 d8                move.l   (a0)+, (a1)+
  00546:  41 ec 00 36          lea.l    $36(a4), a0
  0054a:  43 ee ff d4          lea.l    -$2c(a6), a1
  0054e:  20 d9                move.l   (a1)+, (a0)+
  00550:  20 d9                move.l   (a1)+, (a0)+
  00552:  19 7c 00 01 00 34    move.b   #$1, $34(a4)
  00558:  4a 6e ff d4          tst.w    -$2c(a6)
  0055c:  6c 0c                bge.b    $56a
  0055e:  30 2e ff d4          move.w   -$2c(a6), d0
  00562:  91 6e ff e4          sub.w    d0, -$1c(a6)
  00566:  42 6e ff d4          clr.w    -$2c(a6)
  0056a:  30 2e ff d8          move.w   -$28(a6), d0
  0056e:  48 c0                ext.l    d0
  00570:  be 80                cmp.l    d0, d7
  00572:  6c 16                bge.b    $58a
  00574:  30 2e ff d8          move.w   -$28(a6), d0
  00578:  48 c0                ext.l    d0
  0057a:  90 87                sub.l    d7, d0
  0057c:  53 40                subq.w   #$1, d0
  0057e:  91 6e ff e8          sub.w    d0, -$18(a6)
  00582:  30 07                move.w   d7, d0
  00584:  52 40                addq.w   #$1, d0
  00586:  3d 40 ff d8          move.w   d0, -$28(a6)
  0058a:  2f 2c 00 46          move.l   $46(a4), -(a7)
  0058e:  70 00                moveq    #$0, d0
  00590:  2f 00                move.l   d0, -(a7)
  00592:  20 3c 00 08 00 06    move.l   #$80006, d0
  00598:  ab 1d                dc.w     $ab1d  ; _QDExtensions
  0059a:  48 6b 00 02          pea.l    $2(a3)
  0059e:  20 6c 00 46          movea.l  $46(a4), a0
  005a2:  20 68 00 02          movea.l  $2(a0), a0
  005a6:  2f 10                move.l   (a0), -(a7)
  005a8:  48 6e ff d4          pea.l    -$2c(a6)
  005ac:  48 6e ff e4          pea.l    -$1c(a6)
  005b0:  70 00                moveq    #$0, d0
  005b2:  3f 00                move.w   d0, -(a7)
  005b4:  72 00                moveq    #$0, d1
  005b6:  2f 01                move.l   d1, -(a7)
  005b8:  a8 ec                dc.w     $a8ec  ; _CopyBits
  005ba:  2f 0b                move.l   a3, -(a7)
  005bc:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  005c0:  20 3c 00 08 00 06    move.l   #$80006, d0
  005c6:  ab 1d                dc.w     $ab1d  ; _QDExtensions
  005c8:  48 6c 00 36          pea.l    $36(a4)
  005cc:  2f 2c 00 08          move.l   $8(a4), -(a7)
  005d0:  aa 1f                dc.w     $aa1f  ; _PlotCIcon
  005d2:  4a 2c 00 35          tst.b    $35(a4)
  005d6:  67 36                beq.b    $60e
  005d8:  42 2c 00 35          clr.b    $35(a4)
  005dc:  2f 0b                move.l   a3, -(a7)
  005de:  70 00                moveq    #$0, d0
  005e0:  2f 00                move.l   d0, -(a7)
  005e2:  20 3c 00 08 00 06    move.l   #$80006, d0
  005e8:  ab 1d                dc.w     $ab1d  ; _QDExtensions
  005ea:  20 6c 00 4a          movea.l  $4a(a4), a0
  005ee:  20 68 00 02          movea.l  $2(a0), a0
  005f2:  2f 10                move.l   (a0), -(a7)
  005f4:  48 6b 00 02          pea.l    $2(a3)
  005f8:  20 6c 00 4a          movea.l  $4a(a4), a0
  005fc:  48 68 00 10          pea.l    $10(a0)
  00600:  48 6c 00 3e          pea.l    $3e(a4)
  00604:  70 00                moveq    #$0, d0
  00606:  3f 00                move.w   d0, -(a7)
  00608:  72 00                moveq    #$0, d1
  0060a:  2f 01                move.l   d1, -(a7)
  0060c:  a8 ec                dc.w     $a8ec  ; _CopyBits
  0060e:  4a 94                tst.l    (a4)
  00610:  67 00 00 d6          beq.w    $6e8
  00614:  06 6e 00 20 ff d4    addi.w   #$20, -$2c(a6)
  0061a:  30 2e ff d4          move.w   -$2c(a6), d0
  0061e:  d0 7c 00 20          add.w    #$20, d0
  00622:  3d 40 ff d8          move.w   d0, -$28(a6)
  00626:  20 2c 00 04          move.l   $4(a4), d0
  0062a:  52 ac 00 04          addq.l   #$1, $4(a4)
  0062e:  4c 54 08 01          divs.l   (a4), d0
  00632:  2a 01                move.l   d1, d5
  00634:  4a 04                tst.b    d4
  00636:  66 00 00 b0          bne.w    $6e8
  0063a:  2d 74 5c 0c ff f0    move.l   $c(a4, d5.l), -$10(a6)
  00640:  67 00 00 a6          beq.w    $6e8
  00644:  4a 6e ff d8          tst.w    -$28(a6)
  00648:  6f 00 00 9e          ble.w    $6e8
  0064c:  20 6c 00 4a          movea.l  $4a(a4), a0
  00650:  43 ee ff e4          lea.l    -$1c(a6), a1
  00654:  41 e8 00 10          lea.l    $10(a0), a0
  00658:  22 d8                move.l   (a0)+, (a1)+
  0065a:  22 d8                move.l   (a0)+, (a1)+
  0065c:  41 ec 00 3e          lea.l    $3e(a4), a0
  00660:  43 ee ff d4          lea.l    -$2c(a6), a1
  00664:  20 d9                move.l   (a1)+, (a0)+
  00666:  20 d9                move.l   (a1)+, (a0)+
  00668:  19 7c 00 01 00 35    move.b   #$1, $35(a4)
  0066e:  4a 6e ff d4          tst.w    -$2c(a6)
  00672:  6c 0c                bge.b    $680
  00674:  30 2e ff d4          move.w   -$2c(a6), d0
  00678:  91 6e ff e4          sub.w    d0, -$1c(a6)
  0067c:  42 6e ff d4          clr.w    -$2c(a6)
  00680:  30 2e ff d8          move.w   -$28(a6), d0
  00684:  48 c0                ext.l    d0
  00686:  be 80                cmp.l    d0, d7
  00688:  6c 16                bge.b    $6a0
  0068a:  30 2e ff d8          move.w   -$28(a6), d0
  0068e:  48 c0                ext.l    d0
  00690:  90 87                sub.l    d7, d0
  00692:  53 40                subq.w   #$1, d0
  00694:  91 6e ff e8          sub.w    d0, -$18(a6)
  00698:  30 07                move.w   d7, d0
  0069a:  52 40                addq.w   #$1, d0
  0069c:  3d 40 ff d8          move.w   d0, -$28(a6)
  006a0:  2f 2c 00 4a          move.l   $4a(a4), -(a7)
  006a4:  70 00                moveq    #$0, d0
  006a6:  2f 00                move.l   d0, -(a7)
  006a8:  20 3c 00 08 00 06    move.l   #$80006, d0
  006ae:  ab 1d                dc.w     $ab1d  ; _QDExtensions
  006b0:  48 6b 00 02          pea.l    $2(a3)
  006b4:  20 6c 00 4a          movea.l  $4a(a4), a0
  006b8:  20 68 00 02          movea.l  $2(a0), a0
  006bc:  2f 10                move.l   (a0), -(a7)
  006be:  48 6e ff d4          pea.l    -$2c(a6)
  006c2:  48 6e ff e4          pea.l    -$1c(a6)
  006c6:  70 00                moveq    #$0, d0
  006c8:  3f 00                move.w   d0, -(a7)
  006ca:  72 00                moveq    #$0, d1
  006cc:  2f 01                move.l   d1, -(a7)
  006ce:  a8 ec                dc.w     $a8ec  ; _CopyBits
  006d0:  2f 0b                move.l   a3, -(a7)
  006d2:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  006d6:  20 3c 00 08 00 06    move.l   #$80006, d0
  006dc:  ab 1d                dc.w     $ab1d  ; _QDExtensions
  006de:  48 6c 00 3e          pea.l    $3e(a4)
  006e2:  2f 34 5c 0c          move.l   $c(a4, d5.l), -(a7)
  006e6:  aa 1f                dc.w     $aa1f  ; _PlotCIcon
  006e8:  29 46 00 30          move.l   d6, $30(a4)
  006ec:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  006f0:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  006f4:  20 3c 00 08 00 06    move.l   #$80006, d0
  006fa:  ab 1d                dc.w     $ab1d  ; _QDExtensions
  006fc:  4c ee 18 f0 ff bc    movem.l  -$44(a6), d4-d7/a3-a4
  00702:  4e 5e                unlk     a6
  00704:  4e 75                rts      
  00706:  4e 56 ff 80          link.w   a6, #$ff80
  0070a:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  0070e:  26 6e 00 0c          movea.l  $c(a6), a3
  00712:  28 6e 00 08          movea.l  $8(a6), a4
  00716:  a8 52                dc.w     $a852  ; _HideCursor
  00718:  2f 0c                move.l   a4, -(a7)
  0071a:  a8 73                dc.w     $a873  ; _SetPort
  0071c:  42 6e ff b4          clr.w    -$4c(a6)
  00720:  70 00                moveq    #$0, d0
  00722:  2d 40 ff ca          move.l   d0, -$36(a6)
  00726:  2d 40 ff c6          move.l   d0, -$3a(a6)
  0072a:  32 13                move.w   (a3), d1
  0072c:  48 c1                ext.l    d1
  0072e:  2d 41 ff b0          move.l   d1, -$50(a6)
  00732:  2a 01                move.l   d1, d5
  00734:  32 2b 00 02          move.w   $2(a3), d1
  00738:  48 c1                ext.l    d1
  0073a:  2d 41 ff ac          move.l   d1, -$54(a6)
  0073e:  2d 40 ff 80          move.l   d0, -$80(a6)
  00742:  70 1e                moveq    #$1e, d0
  00744:  2f 00                move.l   d0, -(a7)
  00746:  a8 63                dc.w     $a863  ; _BackColor
  00748:  70 21                moveq    #$21, d0
  0074a:  2f 00                move.l   d0, -(a7)
  0074c:  a8 62                dc.w     $a862  ; _ForeColor
  0074e:  42 ae ff f2          clr.l    -$e(a6)
  00752:  3d 7c 00 20 ff f6    move.w   #$20, -$a(a6)
  00758:  3d 7c 00 20 ff f8    move.w   #$20, -$8(a6)
  0075e:  70 20                moveq    #$20, d0
  00760:  b0 53                cmp.w    (a3), d0
  00762:  6c 00 02 00          bge.w    $964
  00766:  59 8f                subq.l   #$4, a7
  00768:  3f 3c ab 03          move.w   #$ab03, -(a7)
  0076c:  70 01                moveq    #$1, d0
  0076e:  1f 00                move.b   d0, -(a7)
  00770:  61 ff 00 00 04 ca    bsr.l    $c3c  ; -> GetTrapAddr
  00776:  59 8f                subq.l   #$4, a7
  00778:  3f 3c a8 9f          move.w   #$a89f, -(a7)
  0077c:  70 01                moveq    #$1, d0
  0077e:  1f 00                move.b   d0, -(a7)
  00780:  61 ff 00 00 04 ba    bsr.l    $c3c  ; -> GetTrapAddr
  00786:  20 1f                move.l   (a7)+, d0
  00788:  b0 9f                cmp.l    (a7)+, d0
  0078a:  67 00 01 d8          beq.w    $964
  0078e:  55 8f                subq.l   #$2, a7
  00790:  48 6e ff ca          pea.l    -$36(a6)
  00794:  70 00                moveq    #$0, d0
  00796:  3f 00                move.w   d0, -(a7)
  00798:  48 6e ff f2          pea.l    -$e(a6)
  0079c:  72 00                moveq    #$0, d1
  0079e:  2f 01                move.l   d1, -(a7)
  007a0:  2f 01                move.l   d1, -(a7)
  007a2:  2f 01                move.l   d1, -(a7)
  007a4:  20 3c 00 16 00 00    move.l   #$160000, d0
  007aa:  ab 1d                dc.w     $ab1d  ; _QDExtensions
  007ac:  4a 5f                tst.w    (a7)+
  007ae:  66 00 01 b4          bne.w    $964
  007b2:  4a ae ff ca          tst.l    -$36(a6)
  007b6:  67 00 01 ac          beq.w    $964
  007ba:  55 8f                subq.l   #$2, a7
  007bc:  48 6e ff c6          pea.l    -$3a(a6)
  007c0:  70 00                moveq    #$0, d0
  007c2:  3f 00                move.w   d0, -(a7)
  007c4:  48 6e ff f2          pea.l    -$e(a6)
  007c8:  72 00                moveq    #$0, d1
  007ca:  2f 01                move.l   d1, -(a7)
  007cc:  2f 01                move.l   d1, -(a7)
  007ce:  2f 01                move.l   d1, -(a7)
  007d0:  20 3c 00 16 00 00    move.l   #$160000, d0
  007d6:  ab 1d                dc.w     $ab1d  ; _QDExtensions
  007d8:  4a 5f                tst.w    (a7)+
  007da:  66 00 01 88          bne.w    $964
  007de:  4a ae ff c6          tst.l    -$3a(a6)
  007e2:  67 00 01 80          beq.w    $964
  007e6:  1d 78 08 f2 ff fb    move.b   $8f2.w, -$5(a6)
  007ec:  42 38 08 f2          clr.b    $8f2.w
  007f0:  7c 00                moveq    #$0, d6
  007f2:  7e 00                moveq    #$0, d7
  007f4:  59 8f                subq.l   #$4, a7
  007f6:  30 07                move.w   d7, d0
  007f8:  d0 7c 00 64          add.w    #$64, d0
  007fc:  3f 00                move.w   d0, -(a7)
  007fe:  aa 1e                dc.w     $aa1e  ; _GetCIcon
  00800:  2d 5f ff 88          move.l   (a7)+, -$78(a6)
  00804:  67 2a                beq.b    $830
  00806:  70 00                moveq    #$0, d0
  00808:  2f 00                move.l   d0, -(a7)
  0080a:  2f 0c                move.l   a4, -(a7)
  0080c:  2f 2e ff b0          move.l   -$50(a6), -(a7)
  00810:  48 6e ff 80          pea.l    -$80(a6)
  00814:  61 ff ff ff fc 5a    bsr.l    $470
  0081a:  2f 2e ff 88          move.l   -$78(a6), -(a7)
  0081e:  aa 25                dc.w     $aa25  ; _DisposCIcon
  00820:  30 7c 00 02          movea.w  #$2, a0
  00824:  43 ee ff fc          lea.l    -$4(a6), a1
  00828:  a0 3b                dc.w     $a03b  ; _Delay
  0082a:  22 80                move.l   d0, (a1)
  0082c:  4f ef 00 10          lea.l    $10(a7), a7
  00830:  20 07                move.l   d7, d0
  00832:  52 87                addq.l   #$1, d7
  00834:  70 05                moveq    #$5, d0
  00836:  b0 87                cmp.l    d7, d0
  00838:  6e ba                bgt.b    $7f4
  0083a:  20 06                move.l   d6, d0
  0083c:  52 86                addq.l   #$1, d6
  0083e:  70 02                moveq    #$2, d0
  00840:  b0 86                cmp.l    d6, d0
  00842:  6e ae                bgt.b    $7f2
  00844:  59 8f                subq.l   #$4, a7
  00846:  70 64                moveq    #$64, d0
  00848:  3f 00                move.w   d0, -(a7)
  0084a:  aa 1e                dc.w     $aa1e  ; _GetCIcon
  0084c:  2d 5f ff 88          move.l   (a7)+, -$78(a6)
  00850:  70 04                moveq    #$4, d0
  00852:  2d 40 ff 80          move.l   d0, -$80(a6)
  00856:  72 00                moveq    #$0, d1
  00858:  2d 41 ff 84          move.l   d1, -$7c(a6)
  0085c:  59 8f                subq.l   #$4, a7
  0085e:  3f 3c 00 c8          move.w   #$c8, -(a7)
  00862:  aa 1e                dc.w     $aa1e  ; _GetCIcon
  00864:  2d 5f ff 8c          move.l   (a7)+, -$74(a6)
  00868:  59 8f                subq.l   #$4, a7
  0086a:  3f 3c 00 c9          move.w   #$c9, -(a7)
  0086e:  aa 1e                dc.w     $aa1e  ; _GetCIcon
  00870:  2d 5f ff 90          move.l   (a7)+, -$70(a6)
  00874:  59 8f                subq.l   #$4, a7
  00876:  3f 3c 00 ca          move.w   #$ca, -(a7)
  0087a:  aa 1e                dc.w     $aa1e  ; _GetCIcon
  0087c:  2d 5f ff 94          move.l   (a7)+, -$6c(a6)
  00880:  59 8f                subq.l   #$4, a7
  00882:  3f 3c 00 cb          move.w   #$cb, -(a7)
  00886:  aa 1e                dc.w     $aa1e  ; _GetCIcon
  00888:  2d 5f ff 98          move.l   (a7)+, -$68(a6)
  0088c:  2c 2e ff b0          move.l   -$50(a6), d6
  00890:  78 00                moveq    #$0, d4
  00892:  60 2a                bra.b    $8be
  00894:  70 00                moveq    #$0, d0
  00896:  2f 00                move.l   d0, -(a7)
  00898:  2f 0c                move.l   a4, -(a7)
  0089a:  2f 06                move.l   d6, -(a7)
  0089c:  48 6e ff 80          pea.l    -$80(a6)
  008a0:  61 ff ff ff fb ce    bsr.l    $470
  008a6:  56 84                addq.l   #$3, d4
  008a8:  20 04                move.l   d4, d0
  008aa:  e2 80                asr.l    #$1, d0
  008ac:  9c 80                sub.l    d0, d6
  008ae:  30 7c 00 02          movea.w  #$2, a0
  008b2:  43 ee ff fc          lea.l    -$4(a6), a1
  008b6:  a0 3b                dc.w     $a03b  ; _Delay
  008b8:  22 80                move.l   d0, (a1)
  008ba:  4f ef 00 10          lea.l    $10(a7), a7
  008be:  70 c0                moveq    #$c0, d0
  008c0:  b0 ae ff b0          cmp.l    -$50(a6), d0
  008c4:  6d ce                blt.b    $894
  008c6:  70 01                moveq    #$1, d0
  008c8:  2f 00                move.l   d0, -(a7)
  008ca:  2f 0c                move.l   a4, -(a7)
  008cc:  2f 06                move.l   d6, -(a7)
  008ce:  48 6e ff 80          pea.l    -$80(a6)
  008d2:  61 ff ff ff fb 9c    bsr.l    $470
  008d8:  7e 00                moveq    #$0, d7
  008da:  4f ef 00 10          lea.l    $10(a7), a7
  008de:  60 0e                bra.b    $8ee
  008e0:  20 07                move.l   d7, d0
  008e2:  e5 80                asl.l    #$2, d0
  008e4:  2f 36 08 8c          move.l   -$74(a6, d0.l), -(a7)
  008e8:  aa 25                dc.w     $aa25  ; _DisposCIcon
  008ea:  20 07                move.l   d7, d0
  008ec:  52 87                addq.l   #$1, d7
  008ee:  be ae ff 80          cmp.l    -$80(a6), d7
  008f2:  6d ec                blt.b    $8e0
  008f4:  70 00                moveq    #$0, d0
  008f6:  2d 40 ff 80          move.l   d0, -$80(a6)
  008fa:  2c 05                move.l   d5, d6
  008fc:  72 28                moveq    #$28, d1
  008fe:  dc 81                add.l    d1, d6
  00900:  60 24                bra.b    $926
  00902:  70 00                moveq    #$0, d0
  00904:  2f 00                move.l   d0, -(a7)
  00906:  2f 0c                move.l   a4, -(a7)
  00908:  2f 06                move.l   d6, -(a7)
  0090a:  48 6e ff 80          pea.l    -$80(a6)
  0090e:  61 ff ff ff fb 60    bsr.l    $470
  00914:  30 7c 00 02          movea.w  #$2, a0
  00918:  43 ee ff fc          lea.l    -$4(a6), a1
  0091c:  a0 3b                dc.w     $a03b  ; _Delay
  0091e:  22 80                move.l   d0, (a1)
  00920:  4f ef 00 10          lea.l    $10(a7), a7
  00924:  55 86                subq.l   #$2, d6
  00926:  ba 86                cmp.l    d6, d5
  00928:  6d d8                blt.b    $902
  0092a:  70 01                moveq    #$1, d0
  0092c:  2f 00                move.l   d0, -(a7)
  0092e:  2f 0c                move.l   a4, -(a7)
  00930:  2f 05                move.l   d5, -(a7)
  00932:  48 6e ff 80          pea.l    -$80(a6)
  00936:  61 ff ff ff fb 38    bsr.l    $470
  0093c:  2f 2e ff 88          move.l   -$78(a6), -(a7)
  00940:  aa 25                dc.w     $aa25  ; _DisposCIcon
  00942:  2f 2e ff c6          move.l   -$3a(a6), -(a7)
  00946:  20 3c 00 04 00 04    move.l   #$40004, d0
  0094c:  ab 1d                dc.w     $ab1d  ; _QDExtensions
  0094e:  2f 2e ff ca          move.l   -$36(a6), -(a7)
  00952:  20 3c 00 04 00 04    move.l   #$40004, d0
  00958:  ab 1d                dc.w     $ab1d  ; _QDExtensions
  0095a:  11 ee ff fb 08 f2    move.b   -$5(a6), $8f2.w
  00960:  4f ef 00 10          lea.l    $10(a7), a7
  00964:  59 8f                subq.l   #$4, a7
  00966:  70 64                moveq    #$64, d0
  00968:  3f 00                move.w   d0, -(a7)
  0096a:  aa 1e                dc.w     $aa1e  ; _GetCIcon
  0096c:  2d 5f ff 88          move.l   (a7)+, -$78(a6)
  00970:  67 1a                beq.b    $98c
  00972:  2f 0b                move.l   a3, -(a7)
  00974:  2f 2e ff 88          move.l   -$78(a6), -(a7)
  00978:  aa 1f                dc.w     $aa1f  ; _PlotCIcon
  0097a:  2f 2e ff 88          move.l   -$78(a6), -(a7)
  0097e:  aa 25                dc.w     $aa25  ; _DisposCIcon
  00980:  30 7c 00 02          movea.w  #$2, a0
  00984:  43 ee ff fc          lea.l    -$4(a6), a1
  00988:  a0 3b                dc.w     $a03b  ; _Delay
  0098a:  22 80                move.l   d0, (a1)
  0098c:  a8 53                dc.w     $a853  ; _ShowCursor
  0098e:  4c ee 18 f0 ff 68    movem.l  -$98(a6), d4-d7/a3-a4
  00994:  4e 5e                unlk     a6
  00996:  4e 74 00 08          rtd      #$8
* ==================================================================
* ShowIconOrAlert
* ==================================================================
* Called both for the boot-time "product identified" flash and for the
* error path.  D0 return value bit pattern comes back as the D4 sentinel
* Main checks against $D8EF; mode(A6+$A)==0 shows something via a
* helper at $BA4 (message-box-like: builds a small param block and
* jsr's through a fixed vector at $706(pc)); mode!=0 instead loads an
* ICN# resource (id = A6+$8) and processes it via sub_0AFE, falling
* back to a single _SysBeep if the icon resource is missing.  The
* inner helpers ($A78, $AD0, $AFE, $B7E -- the latter two using
* _NewGrowRgn-family traps $AA1E/$AA25) are icon/alert plumbing not
* traced further here.
ShowIconOrAlert:
  0099a:  4e 56 00 00          link.w   a6, #$0
  0099e:  48 e7 1f 38          movem.l  d3-d7/a2-a4, -(a7)
  009a2:  08 38 00 06 02 8e    btst.b   #$6, $28e.w
  009a8:  67 4c                beq.b    $9f6
  009aa:  0c 6e 00 00 00 0a    cmpi.w   #$0, $a(a6)
  009b0:  66 0c                bne.b    $9be
  009b2:  2f 00                move.l   d0, -(a7)
  009b4:  3f 2e 00 08          move.w   $8(a6), -(a7)
  009b8:  61 00 01 ea          bsr.w    $ba4
  009bc:  60 24                bra.b    $9e2
  009be:  42 a7                clr.l    -(a7)
  009c0:  2f 3c 49 43 4e 23    move.l   #$49434e23, -(a7)
  009c6:  3f 2e 00 0a          move.w   $a(a6), -(a7)
  009ca:  a9 a0                dc.w     $a9a0  ; _GetResource
  009cc:  20 1f                move.l   (a7)+, d0
  009ce:  67 1e                beq.b    $9ee
  009d0:  2f 00                move.l   d0, -(a7)
  009d2:  20 40                movea.l  d0, a0
  009d4:  20 50                movea.l  (a0), a0
  009d6:  2f 08                move.l   a0, -(a7)
  009d8:  3f 2e 00 08          move.w   $8(a6), -(a7)
  009dc:  61 00 01 20          bsr.w    $afe  ; -> sub_0afe
  009e0:  a9 a3                dc.w     $a9a3  ; _ReleaseResource
  009e2:  4c df 1c f8          movem.l  (a7)+, d3-d7/a2-a4
  009e6:  4e 5e                unlk     a6
  009e8:  20 5f                movea.l  (a7)+, a0
  009ea:  58 8f                addq.l   #$4, a7
  009ec:  4e d0                jmp      (a0)
  009ee:  3f 3c 00 01          move.w   #$1, -(a7)
  009f2:  a9 c8                dc.w     $a9c8  ; _SysBeep
  009f4:  60 ec                bra.b    $9e2
  009f6:  20 78 08 a4          movea.l  $8a4.w, a0
  009fa:  20 50                movea.l  (a0), a0
  009fc:  20 68 00 16          movea.l  $16(a0), a0
  00a00:  20 50                movea.l  (a0), a0
  00a02:  0c 68 00 04 00 20    cmpi.w   #$4, $20(a0)
  00a08:  6d a0                blt.b    $9aa
  00a0a:  0c 6e 00 00 00 0a    cmpi.w   #$0, $a(a6)
  00a10:  66 0c                bne.b    $a1e
  00a12:  2f 00                move.l   d0, -(a7)
  00a14:  3f 2e 00 08          move.w   $8(a6), -(a7)
  00a18:  61 00 01 8a          bsr.w    $ba4
  00a1c:  60 c4                bra.b    $9e2
  00a1e:  42 a7                clr.l    -(a7)
  00a20:  3f 2e 00 0a          move.w   $a(a6), -(a7)
  00a24:  aa 1e                dc.w     $aa1e  ; _GetCIcon
  00a26:  20 1f                move.l   (a7)+, d0
  00a28:  67 80                beq.b    $9aa
  00a2a:  2f 00                move.l   d0, -(a7)
  00a2c:  2f 00                move.l   d0, -(a7)
  00a2e:  3f 2e 00 08          move.w   $8(a6), -(a7)
  00a32:  61 00 01 4a          bsr.w    $b7e  ; -> sub_0b7e
  00a36:  aa 25                dc.w     $aa25  ; _DisposCIcon
  00a38:  60 a8                bra.b    $9e2
  00a3a:  53 68 6f 77          subq.w   #$1, $6f77(a0)
  00a3e:  49                   dc.b     $49  ; I
  00a3f:  4e 49                trap     #$9
  00a41:  54 20                addq.b   #$2, -(a0)
  00a43:  62 79                bhi.b    $abe
  00a45:  20 50                movea.l  (a0), a0
  00a47:  61 75                bsr.b    $abe
  00a49:  6c 20                bge.b    $a6b
  00a4b:  4d                   dc.b     $4d  ; M
  00a4c:  65 72                bcs.b    $ac0
  00a4e:  63 65                bls.b    $ab5
  00a50:  72 00                moveq    #$0, d1
  00a52:  43                   dc.b     $43  ; C
  00a53:  6f 70                ble.b    $ac5
  00a55:  79                   dc.b     $79  ; y
  00a56:  72 69                moveq    #$69, d1
  00a58:  67 68                beq.b    $ac2
  00a5a:  74 20                moveq    #$20, d2
  00a5c:  31 39 38 37 2d 31    move.w   $38372d31.l, -(a0)
  00a62:  39 38 38 00          move.w   $3800.w, -(a4)
  00a66:  56 65                addq.w   #$3, -(a5)
  00a68:  72 73                moveq    #$73, d1
  00a6a:  69 6f                bvs.b    $adb
  00a6c:  6e 20                bgt.b    $a8e
  00a6e:  6f 66                ble.b    $ad6
  00a70:  20 37 2f 31 35 2f 38 38 move.l   ([$352f3838, a7, d2.l * 8]), d0
sub_0a78:
  00a78:  2d 78 09 04 ff fc    move.l   $904.w, -$4(a6)
  00a7e:  4b ee ff f8          lea.l    -$8(a6), a5
  00a82:  21 cd 09 04          move.l   a5, $904.w
  00a86:  48 6e ff f4          pea.l    -$c(a6)
  00a8a:  a8 6e                dc.w     $a86e  ; _InitGraf
  00a8c:  48 6e fe a8          pea.l    -$158(a6)
  00a90:  a8 6f                dc.w     $a86f  ; _OpenPort
  00a92:  30 38 09 2c          move.w   $92c.w, d0
  00a96:  e3 58                rol.w    #$1, d0
  00a98:  0a 40 10 21          eori.w   #$1021, d0
  00a9c:  b0 78 09 2e          cmp.w    $92e.w, d0
  00aa0:  67 06                beq.b    $aa8
  00aa2:  31 fc 00 08 09 2c    move.w   #$8, $92c.w
  00aa8:  41 ee fe a8          lea.l    -$158(a6), a0
  00aac:  30 28 00 0c          move.w   $c(a0), d0
  00ab0:  04 40 00 28          subi.w   #$28, d0
  00ab4:  48 40                swap     d0
  00ab6:  30 38 09 2c          move.w   $92c.w, d0
  00aba:  2d 40 ff 22          move.l   d0, -$de(a6)
  00abe:  2d 40 ff 26          move.l   d0, -$da(a6)
  00ac2:  06 6e 00 20 ff 28    addi.w   #$20, -$d8(a6)
  00ac8:  06 6e 00 20 ff 26    addi.w   #$20, -$da(a6)
  00ace:  4e 75                rts      
sub_0ad0:
  00ad0:  30 38 09 2c          move.w   $92c.w, d0
  00ad4:  32 2e 00 08          move.w   $8(a6), d1
  00ad8:  6a 04                bpl.b    $ade
  00ada:  32 3c 00 28          move.w   #$28, d1
  00ade:  d0 41                add.w    d1, d0
  00ae0:  31 c0 09 2c          move.w   d0, $92c.w
  00ae4:  e3 58                rol.w    #$1, d0
  00ae6:  0a 40 10 21          eori.w   #$1021, d0
  00aea:  31 c0 09 2e          move.w   d0, $92e.w
  00aee:  48 6e fe a8          pea.l    -$158(a6)
  00af2:  a8 7d                dc.w     $a87d  ; _ClosePort
  00af4:  2a 6e ff fc          movea.l  -$4(a6), a5
  00af8:  21 cd 09 04          move.l   a5, $904.w
  00afc:  4e 75                rts      
sub_0afe:
  00afe:  4e 56 fe a8          link.w   a6, #$fea8
  00b02:  48 e7 1f 38          movem.l  d3-d7/a2-a4, -(a7)
  00b06:  61 00 ff 70          bsr.w    $a78  ; -> sub_0a78
  00b0a:  26 6e 00 0a          movea.l  $a(a6), a3
  00b0e:  49 ee ff 14          lea.l    -$ec(a6), a4
  00b12:  28 8b                move.l   a3, (a4)
  00b14:  06 94 00 00 00 80    addi.l   #$80, (a4)
  00b1a:  39 7c 00 04 00 04    move.w   #$4, $4(a4)
  00b20:  42 ac 00 06          clr.l    $6(a4)
  00b24:  39 7c 00 20 00 0a    move.w   #$20, $a(a4)
  00b2a:  39 7c 00 20 00 0c    move.w   #$20, $c(a4)
  00b30:  2f 0c                move.l   a4, -(a7)
  00b32:  45 ee fe a8          lea.l    -$158(a6), a2
  00b36:  48 6a 00 02          pea.l    $2(a2)
  00b3a:  48 7a 00 3a          pea.l    $b76(pc)
  00b3e:  48 6e ff 22          pea.l    -$de(a6)
  00b42:  3f 3c 00 03          move.w   #$3, -(a7)
  00b46:  42 a7                clr.l    -(a7)
  00b48:  a8 ec                dc.w     $a8ec  ; _CopyBits
  00b4a:  04 94 00 00 00 80    subi.l   #$80, (a4)
  00b50:  2f 0c                move.l   a4, -(a7)
  00b52:  48 6a 00 02          pea.l    $2(a2)
  00b56:  48 7a 00 1e          pea.l    $b76(pc)
  00b5a:  48 6e ff 22          pea.l    -$de(a6)
  00b5e:  3f 3c 00 01          move.w   #$1, -(a7)
  00b62:  42 a7                clr.l    -(a7)
  00b64:  a8 ec                dc.w     $a8ec  ; _CopyBits
  00b66:  61 00 ff 68          bsr.w    $ad0  ; -> sub_0ad0
  00b6a:  4c df 1c f8          movem.l  (a7)+, d3-d7/a2-a4
  00b6e:  4e 5e                unlk     a6
  00b70:  20 5f                movea.l  (a7)+, a0
  00b72:  5c 8f                addq.l   #$6, a7
  00b74:  4e d0                jmp      (a0)
  00b76:  00 00 00 00          ori.b    #$0, d0
  00b7a:  00 20 00 20          ori.b    #$20, -(a0)
sub_0b7e:
  00b7e:  4e 56 fe a8          link.w   a6, #$fea8
  00b82:  48 e7 1f 38          movem.l  d3-d7/a2-a4, -(a7)
  00b86:  61 00 fe f0          bsr.w    $a78  ; -> sub_0a78
  00b8a:  48 6e ff 22          pea.l    -$de(a6)
  00b8e:  2f 2e 00 0a          move.l   $a(a6), -(a7)
  00b92:  aa 1f                dc.w     $aa1f  ; _PlotCIcon
  00b94:  61 00 ff 3a          bsr.w    $ad0  ; -> sub_0ad0
  00b98:  4c df 1c f8          movem.l  (a7)+, d3-d7/a2-a4
  00b9c:  4e 5e                unlk     a6
  00b9e:  20 5f                movea.l  (a7)+, a0
  00ba0:  5c 8f                addq.l   #$6, a7
  00ba2:  4e d0                jmp      (a0)
  00ba4:  4e 56 fe a8          link.w   a6, #$fea8
  00ba8:  48 e7 1f 38          movem.l  d3-d7/a2-a4, -(a7)
  00bac:  61 00 fe ca          bsr.w    $a78  ; -> sub_0a78
  00bb0:  48 6e ff 22          pea.l    -$de(a6)
  00bb4:  48 6e fe a8          pea.l    -$158(a6)
  00bb8:  4e ba fb 4c          jsr      $706(pc)
  00bbc:  61 00 ff 12          bsr.w    $ad0  ; -> sub_0ad0
  00bc0:  4c df 1c f8          movem.l  (a7)+, d3-d7/a2-a4
  00bc4:  4e 5e                unlk     a6
  00bc6:  20 5f                movea.l  (a7)+, a0
  00bc8:  5c 8f                addq.l   #$6, a7
  00bca:  4e d0                jmp      (a0)
* p2cstr  -  convert a Pascal string to a C string in place
* (shift the characters left one byte, drop the length byte,
* NUL-terminate).
p2cstr:
  00bcc:  20 2f 00 04          move.l   $4(a7), d0
  00bd0:  67 12                beq.b    $be4
  00bd2:  20 40                movea.l  d0, a0
  00bd4:  42 41                clr.w    d1
  00bd6:  12 10                move.b   (a0), d1
  00bd8:  60 04                bra.b    $bde
  00bda:  10 e8 00 01          move.b   $1(a0), (a0)+
  00bde:  51 c9 ff fa          dbra     d1, $bda
  00be2:  42 10                clr.b    (a0)
  00be4:  4e 75                rts      
  00be6:  86 70 32 63 73 74 72 00 00 00 dc.b     $86,$70,$32,$63,$73,$74,$72,$00,$00,$00  ; .p2cstr...
* c2pstr  -  convert a C string to a Pascal string in place
* (single forward pass: shift every byte right by one while scanning
* for the NUL, then write the computed length into byte 0).
c2pstr:
  00bf0:  20 2f 00 04          move.l   $4(a7), d0
  00bf4:  67 1c                beq.b    $c12
  00bf6:  20 40                movea.l  d0, a0
  00bf8:  22 40                movea.l  d0, a1
  00bfa:  34 3c 00 ff          move.w   #$ff, d2
  00bfe:  12 10                move.b   (a0), d1
  00c00:  10 c0                move.b   d0, (a0)+
  00c02:  10 01                move.b   d1, d0
  00c04:  57 ca ff f8          dbeq     d2, $bfe
  00c08:  22 08                move.l   a0, d1
  00c0a:  20 09                move.l   a1, d0
  00c0c:  92 80                sub.l    d0, d1
  00c0e:  53 01                subq.b   #$1, d1
  00c10:  12 81                move.b   d1, (a1)
  00c12:  4e 75                rts      
  00c14:  86 63 32 70 73 74 72 00 00 00 dc.b     $86,$63,$32,$70,$73,$74,$72,$00,$00,$00  ; .c2pstr...
* CloseDriverSync  -  build a minimal IOParam on the stack
* (ioRefNum = the passed refNum) and call _Close (0xA001) directly --
* a hand-rolled PBCloseSync, avoiding the full Device Manager glue.
CloseDriverSync:
  00c1e:  30 2f 00 04          move.w   $4(a7), d0
  00c22:  9e fc 00 1e          suba.w   #$1e, a7
  00c26:  3f 40 00 18          move.w   d0, $18(a7)
  00c2a:  20 4f                movea.l  a7, a0
  00c2c:  a0 01                dc.w     $a001  ; _Close
  00c2e:  4f ef 00 1e          lea.l    $1e(a7), a7
  00c32:  3f 40 00 06          move.w   d0, $6(a7)
  00c36:  20 5f                movea.l  (a7)+, a0
  00c38:  54 4f                addq.w   #$2, a7
  00c3a:  4e d0                jmp      (a0)
* GetTrapAddr  -  (trapNum, isToolboxFlag) -> trap address, via
* _GetToolTrapAddress or _GetOSTrapAddress.  Same shape as the
* Get/SetTrap helpers in DRVR.s (DRVR.s installs trap patches;
* this INIT only ever *reads* trap addresses to probe capabilities).
GetTrapAddr:
  00c3c:  22 5f                movea.l  (a7)+, a1
  00c3e:  12 1f                move.b   (a7)+, d1
  00c40:  30 1f                move.w   (a7)+, d0
  00c42:  4a 01                tst.b    d1
  00c44:  67 04                beq.b    $c4a
  00c46:  a7 46                dc.w     $a746  ; _GetToolTrapAddress
  00c48:  60 02                bra.b    $c4c
  00c4a:  a3 46                dc.w     $a346  ; _GetOSTrapAddress
  00c4c:  2e 88                move.l   a0, (a7)
  00c4e:  4e d1                jmp      (a1)
* ControlDriverSync  -  build a CntrlParam on the stack
* (ioCRefNum + csCode from the caller, csParam copied in via
* _BlockMove if non-NULL) and call _Control (0xA004) directly --
* a hand-rolled PBControlSync.
ControlDriverSync:
  00c50:  4e 56 ff ce          link.w   a6, #$ffce
  00c54:  20 4f                movea.l  a7, a0
  00c56:  31 6e 00 0e 00 18    move.w   $e(a6), $18(a0)
  00c5c:  31 6e 00 0c 00 1a    move.w   $c(a6), $1a(a0)
  00c62:  4a ae 00 08          tst.l    $8(a6)
  00c66:  67 10                beq.b    $c78
  00c68:  43 e8 00 1c          lea.l    $1c(a0), a1
  00c6c:  20 6e 00 08          movea.l  $8(a6), a0
  00c70:  70 16                moveq    #$16, d0
  00c72:  a0 2e                dc.w     $a02e  ; _BlockMove
  00c74:  41 ee ff ce          lea.l    -$32(a6), a0
  00c78:  a0 04                dc.w     $a004  ; _Control
  00c7a:  3d 40 00 10          move.w   d0, $10(a6)
  00c7e:  4e 5e                unlk     a6
  00c80:  22 5f                movea.l  (a7)+, a1
  00c82:  50 8f                addq.l   #$8, a7
  00c84:  4e d1                jmp      (a1)
* StatusDriverSync  -  same shape as ControlDriverSync above,
* calling _Status (0xA005) -- a hand-rolled PBStatusSync.
StatusDriverSync:
  00c86:  4e 56 ff ce          link.w   a6, #$ffce
  00c8a:  20 4f                movea.l  a7, a0
  00c8c:  31 6e 00 0e 00 18    move.w   $e(a6), $18(a0)
  00c92:  31 6e 00 0c 00 1a    move.w   $c(a6), $1a(a0)
  00c98:  a0 05                dc.w     $a005  ; _Status
  00c9a:  3d 40 00 10          move.w   d0, $10(a6)
  00c9e:  41 ee ff ea          lea.l    -$16(a6), a0
  00ca2:  22 6e 00 08          movea.l  $8(a6), a1
  00ca6:  70 16                moveq    #$16, d0
  00ca8:  a0 2e                dc.w     $a02e  ; _BlockMove
  00caa:  4e 5e                unlk     a6
  00cac:  22 5f                movea.l  (a7)+, a1
  00cae:  50 8f                addq.l   #$8, a7
  00cb0:  4e d1                jmp      (a1)
* GetIndStringManual  -  fetch STR# resource (id = A6+$A),
* then manually walk its Pascal-string list to extract entry index
* (A6+$8) into the caller's buffer (A6+$C).  Written by hand with
* _GetResource + a walking loop rather than calling the real
* _GetIndString trap -- possibly because the resource was just
* loaded and the routine wants to index it directly rather than by
* name/current-resource-file lookup.
GetIndStringManual:
  00cb2:  4e 56 00 00          link.w   a6, #$0
  00cb6:  59 4f                subq.w   #$4, a7
  00cb8:  2f 3c 53 54 52 23    move.l   #$53545223, -(a7)
  00cbe:  3f 2e 00 0a          move.w   $a(a6), -(a7)
  00cc2:  a9 a0                dc.w     $a9a0  ; _GetResource
  00cc4:  22 6e 00 0c          movea.l  $c(a6), a1
  00cc8:  42 11                clr.b    (a1)
  00cca:  20 1f                move.l   (a7)+, d0
  00ccc:  67 22                beq.b    $cf0
  00cce:  20 40                movea.l  d0, a0
  00cd0:  20 50                movea.l  (a0), a0
  00cd2:  30 18                move.w   (a0)+, d0
  00cd4:  32 2e 00 08          move.w   $8(a6), d1
  00cd8:  67 16                beq.b    $cf0
  00cda:  b2 40                cmp.w    d0, d1
  00cdc:  62 12                bhi.b    $cf0
  00cde:  70 00                moveq    #$0, d0
  00ce0:  53 41                subq.w   #$1, d1
  00ce2:  67 06                beq.b    $cea
  00ce4:  10 18                move.b   (a0)+, d0
  00ce6:  d1 c0                adda.l   d0, a0
  00ce8:  60 f6                bra.b    $ce0
  00cea:  10 10                move.b   (a0), d0
  00cec:  52 40                addq.w   #$1, d0
  00cee:  a0 2e                dc.w     $a02e  ; _BlockMove
  00cf0:  4e 5e                unlk     a6
  00cf2:  20 5f                movea.l  (a7)+, a0
  00cf4:  50 8f                addq.l   #$8, a7
  00cf6:  4e d0                jmp      (a0)
* OpenDriverByName  -  c2pstr the driver-name argument in
* place, build a minimal IOParam with ioNamePtr set to it, and call
* _Open (0xA000) directly -- a hand-rolled PBOpenSync by name.
OpenDriverByName:
  00cf8:  2f 2f 00 04          move.l   $4(a7), -(a7)
  00cfc:  4e ba fe f2          jsr      $bf0(pc)  ; -> c2pstr
  00d00:  58 4f                addq.w   #$4, a7
  00d02:  20 6f 00 04          movea.l  $4(a7), a0
  00d06:  22 6f 00 08          movea.l  $8(a7), a1
  00d0a:  70 18                moveq    #$18, d0
  00d0c:  42 67                clr.w    -(a7)
  00d0e:  51 c8 ff fc          dbra     d0, $d0c
  00d12:  2f 48 00 12          move.l   a0, $12(a7)
  00d16:  42 2f 00 1b          clr.b    $1b(a7)
  00d1a:  20 4f                movea.l  a7, a0
  00d1c:  a0 00                dc.w     $a000  ; _Open
  00d1e:  32 af 00 18          move.w   $18(a7), (a1)
  00d22:  4f ef 00 32          lea.l    $32(a7), a7
  00d26:  3f 00                move.w   d0, -(a7)
  00d28:  2f 2f 00 06          move.l   $6(a7), -(a7)
  00d2c:  4e ba fe 9e          jsr      $bcc(pc)  ; -> p2cstr
  00d30:  58 4f                addq.w   #$4, a7
  00d32:  30 1f                move.w   (a7)+, d0
  00d34:  48 c0                ext.l    d0
  00d36:  4e 75                rts      
* PLStrCat  -  Pascal string concatenate (dest += src), with
* the classic 255-byte Pascal length cap (clamps rather than
* overflowing).
PLStrCat:
  00d38:  20 1f                move.l   (a7)+, d0
  00d3a:  22 5f                movea.l  (a7)+, a1
  00d3c:  20 5f                movea.l  (a7)+, a0
  00d3e:  2e 88                move.l   a0, (a7)
  00d40:  2f 00                move.l   d0, -(a7)
  00d42:  70 00                moveq    #$0, d0
  00d44:  72 00                moveq    #$0, d1
  00d46:  10 10                move.b   (a0), d0
  00d48:  12 19                move.b   (a1)+, d1
  00d4a:  24 01                move.l   d1, d2
  00d4c:  67 1e                beq.b    $d6c
  00d4e:  d2 40                add.w    d0, d1
  00d50:  0c 41 00 ff          cmpi.w   #$ff, d1
  00d54:  6f 0a                ble.b    $d60
  00d56:  04 41 00 ff          subi.w   #$ff, d1
  00d5a:  94 41                sub.w    d1, d2
  00d5c:  12 3c 00 ff          move.b   #$ff, d1
  00d60:  10 c1                move.b   d1, (a0)+
  00d62:  d1 c0                adda.l   d0, a0
  00d64:  53 02                subq.b   #$1, d2
  00d66:  10 d9                move.b   (a1)+, (a0)+
  00d68:  51 ca ff fc          dbra     d2, $d66
  00d6c:  4e 75                rts      
  00d6e:  88 50 4c 53 74 72 43 61 74 00 00 00 dc.b     $88,$50,$4c,$53,$74,$72,$43,$61,$74,$00,$00,$00  ; .PLStrCat...
* PLStrCpy  -  Pascal string copy (dest = src): copies the
* length byte plus that many data bytes.
PLStrCpy:
  00d7a:  20 1f                move.l   (a7)+, d0
  00d7c:  22 5f                movea.l  (a7)+, a1
  00d7e:  20 5f                movea.l  (a7)+, a0
  00d80:  2e 88                move.l   a0, (a7)
  00d82:  2f 00                move.l   d0, -(a7)
  00d84:  70 00                moveq    #$0, d0
  00d86:  10 19                move.b   (a1)+, d0
  00d88:  10 c0                move.b   d0, (a0)+
  00d8a:  60 02                bra.b    $d8e
  00d8c:  10 d9                move.b   (a1)+, (a0)+
  00d8e:  51 c8 ff fc          dbra     d0, $d8c
  00d92:  4e 75                rts      
  00d94:  88 50 4c 53 74 72 43 70 79 00 00 00 dc.b     $88,$50,$4c,$53,$74,$72,$43,$70,$79,$00,$00,$00  ; .PLStrCpy...
