*  Reconstructed 68020 disassembly of the 8*24 GC control panel cdev.
*  A-trap names from Apple CIncludes/Traps.h; comments/labels analytical.
*
* ==================================================================
* Macintosh Display Card 8•24 GC  -  control panel ('cdev' -4064), v7.0.1
* ==================================================================
* Standard System-7 Control Panel device.  Compiled C; message-dispatched.
* Entry (Pascal): cdevValue = cdev(message, item, numItems, CPanelID,
*                                  theEvent, cdevValue, cpDialog)
* Stack frame (A6):  $08 cpDialog   $0C cdevValue   $10 theEvent
*                    $16 numItems   $18 item        $1A message
*                    $1C = function result (cdevValue out)
* Registers: D7 = message, D6 = numItems, A3 = cpDialog, A4 = cdevValue
*            handle, -$4(A6) = saved cdevValue handle.
*
* cdevValue is a handle to ~106 bytes of private state (allocated in
* initDev).  message 8 (macDev) returns 1 = "this cdev can run here".
cdevMain:
  000000:  4e 56 ff ec          link.w   a6, #$ffec
  000004:  48 e7 07 18          movem.l  d5-d7/a3-a4, -(a7)
  000008:  3e 2e 00 1a          move.w   $1a(a6), d7
  00000c:  26 6e 00 08          movea.l  $8(a6), a3
  000010:  3c 2e 00 16          move.w   $16(a6), d6
  000014:  28 6e 00 0c          movea.l  $c(a6), a4
  000018:  42 6e ff ec          clr.w    -$14(a6)
  00001c:  2d 4c ff fc          move.l   a4, -$4(a6)
  000020:  0c 47 00 08          cmpi.w   #$8, d7
  000024:  66 0a                bne.b    $30  ; -> L30
  000026:  70 01                moveq    #$1, d0
  000028:  2d 40 00 1c          move.l   d0, $1c(a6)
  00002c:  60 00 04 34          bra.w    $462  ; -> L462
L30:
  000030:  20 0c                move.l   a4, d0
  000032:  67 00 04 16          beq.w    $44a  ; -> msg_nulDev
  000036:  30 07                move.w   d7, d0
  000038:  6b 00 04 10          bmi.w    $44a  ; -> msg_nulDev
  00003c:  0c 40 00 07          cmpi.w   #$7, d0
  000040:  6e 00 04 08          bgt.w    $44a  ; -> msg_nulDev
  000044:  d0 40                add.w    d0, d0
  000046:  30 3b 00 06          move.w   $4e(pc, d0.w), d0
  00004a:  4e fb 00 00          jmp      $4c(pc,d0.w)  ; -> L4c
* jump table (word offsets relative to $004C, indexed by selector*2):
  00004e:  00 12                dc.w     $0012    ; message 0 initDev -> msg_initDev
  000050:  03 2e                dc.w     $032E    ; message 1 hitDev -> msg_hitDev
  000052:  02 1c                dc.w     $021C    ; message 2 closeDev -> msg_closeDev
  000054:  03 fe                dc.w     $03FE    ; message 3 nulDev -> msg_nulDev
  000056:  02 3a                dc.w     $023A    ; message 4 updateDev -> msg_updateDev
  000058:  03 fe                dc.w     $03FE    ; message 5 activDev -> msg_nulDev
  00005a:  03 fe                dc.w     $03FE    ; message 6 deactivDev -> msg_nulDev
  00005c:  03 fe                dc.w     $03FE    ; message 7 keyEvtDev -> msg_nulDev
* message 0  initDev  -  allocate private state, read the card/driver
* status, and populate the dialog items (depth radios, gray checkbox,
* monitor popup, gamma popup, the preview area).
msg_initDev:
  00005e:  70 6a                moveq    #$6a, d0
  000060:  a1 22                dc.w     $a122  ; _NewHandle
  000062:  28 48                movea.l  a0, a4
  000064:  20 0c                move.l   a4, d0
  000066:  67 00 03 e2          beq.w    $44a  ; -> msg_nulDev
  00006a:  2d 4c ff fc          move.l   a4, -$4(a6)
  00006e:  20 4c                movea.l  a4, a0
  000070:  20 50                movea.l  (a0), a0
  000072:  42 28 00 0d          clr.b    $d(a0)
  000076:  20 6e ff fc          movea.l  -$4(a6), a0
  00007a:  20 50                movea.l  (a0), a0
  00007c:  42 28 00 0c          clr.b    $c(a0)
  000080:  20 6e ff fc          movea.l  -$4(a6), a0
  000084:  20 50                movea.l  (a0), a0
  000086:  42 28 00 10          clr.b    $10(a0)
  00008a:  20 6e ff fc          movea.l  -$4(a6), a0
  00008e:  20 50                movea.l  (a0), a0
  000090:  70 00                moveq    #$0, d0
  000092:  21 40 00 1e          move.l   d0, $1e(a0)
  000096:  20 6e ff fc          movea.l  -$4(a6), a0
  00009a:  20 50                movea.l  (a0), a0
  00009c:  21 40 00 12          move.l   d0, $12(a0)
  0000a0:  2f 0b                move.l   a3, -(a7)
  0000a2:  30 06                move.w   d6, d0
  0000a4:  52 40                addq.w   #$1, d0
  0000a6:  3f 00                move.w   d0, -(a7)
  0000a8:  48 6e ff ee          pea.l    -$12(a6)
  0000ac:  48 6e ff f0          pea.l    -$10(a6)
  0000b0:  48 6e ff f4          pea.l    -$c(a6)
  0000b4:  a9 8d                dc.w     $a98d  ; _GetDItem
  0000b6:  59 8f                subq.l   #$4, a7
  0000b8:  3f 3c f0 30          move.w   #$f030, -(a7)
  0000bc:  aa 1e                dc.w     $aa1e  ; _GetCIcon
  0000be:  20 6e ff fc          movea.l  -$4(a6), a0
  0000c2:  20 50                movea.l  (a0), a0
  0000c4:  21 5f 00 12          move.l   (a7)+, $12(a0)
  0000c8:  66 1e                bne.b    $e8  ; -> Le8
  0000ca:  2f 0c                move.l   a4, -(a7)
  0000cc:  2f 0b                move.l   a3, -(a7)
  0000ce:  48 c6                ext.l    d6
  0000d0:  2f 06                move.l   d6, -(a7)
  0000d2:  61 ff 00 00 03 a6    bsr.l    $47a  ; -> sub_47a
  0000d8:  20 4c                movea.l  a4, a0
  0000da:  a0 23                dc.w     $a023  ; _DisposHandle
  0000dc:  70 00                moveq    #$0, d0
  0000de:  28 40                movea.l  d0, a4
  0000e0:  4f ef 00 0c          lea.l    $c(a7), a7
  0000e4:  60 00 03 64          bra.w    $44a  ; -> msg_nulDev
Le8:
  0000e8:  20 6e ff fc          movea.l  -$4(a6), a0
  0000ec:  20 50                movea.l  (a0), a0
  0000ee:  41 e8 00 16          lea.l    $16(a0), a0
  0000f2:  43 ee ff f4          lea.l    -$c(a6), a1
  0000f6:  20 d9                move.l   (a1)+, (a0)+
  0000f8:  20 d9                move.l   (a1)+, (a0)+
  0000fa:  70 00                moveq    #$0, d0
  0000fc:  2d 40 ff f0          move.l   d0, -$10(a6)
  000100:  2f 0b                move.l   a3, -(a7)
  000102:  30 06                move.w   d6, d0
  000104:  52 40                addq.w   #$1, d0
  000106:  3f 00                move.w   d0, -(a7)
  000108:  3f 2e ff ee          move.w   -$12(a6), -(a7)
  00010c:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  000110:  48 6e ff f4          pea.l    -$c(a6)
  000114:  a9 8e                dc.w     $a98e  ; _SetDItem
  000116:  2f 0b                move.l   a3, -(a7)
  000118:  30 06                move.w   d6, d0
  00011a:  54 40                addq.w   #$2, d0
  00011c:  3f 00                move.w   d0, -(a7)
  00011e:  48 6e ff ee          pea.l    -$12(a6)
  000122:  48 6e ff f0          pea.l    -$10(a6)
  000126:  48 6e ff f4          pea.l    -$c(a6)
  00012a:  a9 8d                dc.w     $a98d  ; _GetDItem
  00012c:  70 00                moveq    #$0, d0
  00012e:  2d 40 ff f0          move.l   d0, -$10(a6)
  000132:  59 8f                subq.l   #$4, a7
  000134:  3f 3c f0 31          move.w   #$f031, -(a7)
  000138:  aa 1e                dc.w     $aa1e  ; _GetCIcon
  00013a:  20 6e ff fc          movea.l  -$4(a6), a0
  00013e:  20 50                movea.l  (a0), a0
  000140:  21 5f 00 1e          move.l   (a7)+, $1e(a0)
  000144:  66 1e                bne.b    $164  ; -> L164
  000146:  2f 0c                move.l   a4, -(a7)
  000148:  2f 0b                move.l   a3, -(a7)
  00014a:  48 c6                ext.l    d6
  00014c:  2f 06                move.l   d6, -(a7)
  00014e:  61 ff 00 00 03 2a    bsr.l    $47a  ; -> sub_47a
  000154:  20 4c                movea.l  a4, a0
  000156:  a0 23                dc.w     $a023  ; _DisposHandle
  000158:  70 00                moveq    #$0, d0
  00015a:  28 40                movea.l  d0, a4
  00015c:  4f ef 00 0c          lea.l    $c(a7), a7
  000160:  60 00 02 e8          bra.w    $44a  ; -> msg_nulDev
L164:
  000164:  20 6e ff fc          movea.l  -$4(a6), a0
  000168:  20 50                movea.l  (a0), a0
  00016a:  41 e8 00 22          lea.l    $22(a0), a0
  00016e:  43 ee ff f4          lea.l    -$c(a6), a1
  000172:  20 d9                move.l   (a1)+, (a0)+
  000174:  20 d9                move.l   (a1)+, (a0)+
  000176:  70 00                moveq    #$0, d0
  000178:  2d 40 ff f0          move.l   d0, -$10(a6)
  00017c:  20 6e ff fc          movea.l  -$4(a6), a0
  000180:  20 50                movea.l  (a0), a0
  000182:  42 28 00 0e          clr.b    $e(a0)
  000186:  2f 0b                move.l   a3, -(a7)
  000188:  30 06                move.w   d6, d0
  00018a:  54 40                addq.w   #$2, d0
  00018c:  3f 00                move.w   d0, -(a7)
  00018e:  3f 2e ff ee          move.w   -$12(a6), -(a7)
  000192:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  000196:  48 6e ff f4          pea.l    -$c(a6)
  00019a:  a9 8e                dc.w     $a98e  ; _SetDItem
  00019c:  48 6e ff ec          pea.l    -$14(a6)
  0001a0:  48 7a 02 cc          pea.l    $46e(pc)
  0001a4:  61 ff 00 00 1b ec    bsr.l    $1d92  ; -> sub_1d92
  0001aa:  48 c0                ext.l    d0
  0001ac:  2e 00                move.l   d0, d7
  0001ae:  50 4f                addq.w   #$8, a7
  0001b0:  67 3c                beq.b    $1ee  ; -> L1ee
  0001b2:  42 6e ff ec          clr.w    -$14(a6)
  0001b6:  0c 87 ff ff d8 f0    cmpi.l   #$ffffd8f0, d7
  0001bc:  6e 24                bgt.b    $1e2  ; -> L1e2
  0001be:  0c 87 ff ff d8 da    cmpi.l   #$ffffd8da, d7
  0001c4:  6f 1c                ble.b    $1e2  ; -> L1e2
  0001c6:  70 00                moveq    #$0, d0
  0001c8:  2f 00                move.l   d0, -(a7)
  0001ca:  2f 07                move.l   d7, -(a7)
  0001cc:  2f 0c                move.l   a4, -(a7)
  0001ce:  2f 0b                move.l   a3, -(a7)
  0001d0:  48 c6                ext.l    d6
  0001d2:  2f 06                move.l   d6, -(a7)
  0001d4:  61 ff 00 00 0c 66    bsr.l    $e3c  ; -> sub_e3c
  0001da:  4f ef 00 14          lea.l    $14(a7), a7
  0001de:  60 00 02 6a          bra.w    $44a  ; -> msg_nulDev
L1e2:
  0001e2:  20 6e ff fc          movea.l  -$4(a6), a0
  0001e6:  20 50                movea.l  (a0), a0
  0001e8:  11 7c 00 01 00 0c    move.b   #$1, $c(a0)
L1ee:
  0001ee:  20 6e ff fc          movea.l  -$4(a6), a0
  0001f2:  20 50                movea.l  (a0), a0
  0001f4:  30 ae ff ec          move.w   -$14(a6), (a0)
  0001f8:  2f 0c                move.l   a4, -(a7)
  0001fa:  2f 0b                move.l   a3, -(a7)
  0001fc:  48 c6                ext.l    d6
  0001fe:  2f 06                move.l   d6, -(a7)
  000200:  61 ff 00 00 0d bc    bsr.l    $fbe  ; -> sub_fbe
  000206:  2e 00                move.l   d0, d7
  000208:  4f ef 00 0c          lea.l    $c(a7), a7
  00020c:  6c 2c                bge.b    $23a  ; -> L23a
  00020e:  0c 87 ff ff d8 f0    cmpi.l   #$ffffd8f0, d7
  000214:  6e 24                bgt.b    $23a  ; -> L23a
  000216:  0c 87 ff ff d8 da    cmpi.l   #$ffffd8da, d7
  00021c:  6f 1c                ble.b    $23a  ; -> L23a
  00021e:  70 00                moveq    #$0, d0
  000220:  2f 00                move.l   d0, -(a7)
  000222:  2f 07                move.l   d7, -(a7)
  000224:  2f 0c                move.l   a4, -(a7)
  000226:  2f 0b                move.l   a3, -(a7)
  000228:  48 c6                ext.l    d6
  00022a:  2f 06                move.l   d6, -(a7)
  00022c:  61 ff 00 00 0c 0e    bsr.l    $e3c  ; -> sub_e3c
  000232:  4f ef 00 14          lea.l    $14(a7), a7
  000236:  60 00 02 12          bra.w    $44a  ; -> msg_nulDev
L23a:
  00023a:  2f 0c                move.l   a4, -(a7)
  00023c:  2f 0b                move.l   a3, -(a7)
  00023e:  48 c6                ext.l    d6
  000240:  2f 06                move.l   d6, -(a7)
  000242:  61 ff 00 00 03 02    bsr.l    $546  ; -> sub_546
  000248:  4a 80                tst.l    d0
  00024a:  4f ef 00 0c          lea.l    $c(a7), a7
  00024e:  67 00 01 fa          beq.w    $44a  ; -> msg_nulDev
  000252:  2f 0c                move.l   a4, -(a7)
  000254:  2f 0b                move.l   a3, -(a7)
  000256:  48 c6                ext.l    d6
  000258:  2f 06                move.l   d6, -(a7)
  00025a:  61 ff 00 00 02 1e    bsr.l    $47a  ; -> sub_47a
  000260:  4f ef 00 0c          lea.l    $c(a7), a7
  000264:  60 00 01 e4          bra.w    $44a  ; -> msg_nulDev
* message 2  closeDev  -  dispose the private-state handle.
msg_closeDev:
  000268:  2f 0c                move.l   a4, -(a7)
  00026a:  2f 0b                move.l   a3, -(a7)
  00026c:  48 c6                ext.l    d6
  00026e:  2f 06                move.l   d6, -(a7)
  000270:  61 ff 00 00 02 08    bsr.l    $47a  ; -> sub_47a
  000276:  20 4c                movea.l  a4, a0
  000278:  a0 23                dc.w     $a023  ; _DisposHandle
  00027a:  70 00                moveq    #$0, d0
  00027c:  28 40                movea.l  d0, a4
  00027e:  4f ef 00 0c          lea.l    $c(a7), a7
  000282:  60 00 01 c6          bra.w    $44a  ; -> msg_nulDev
* message 4  updateDev  -  redraw the custom items: the monitor
* preview and colour swatches (InsetRect / FrameRoundRect / PtInRect etc.).
msg_updateDev:
  000286:  20 6e ff fc          movea.l  -$4(a6), a0
  00028a:  20 50                movea.l  (a0), a0
  00028c:  4a 28 00 0c          tst.b    $c(a0)
  000290:  66 00 00 a8          bne.w    $33a  ; -> L33a
  000294:  20 6e ff fc          movea.l  -$4(a6), a0
  000298:  20 50                movea.l  (a0), a0
  00029a:  4a 28 00 0d          tst.b    $d(a0)
  00029e:  66 00 00 9a          bne.w    $33a  ; -> L33a
  0002a2:  48 6e ff ec          pea.l    -$14(a6)
  0002a6:  48 7a 01 c6          pea.l    $46e(pc)
  0002aa:  61 ff 00 00 1a e6    bsr.l    $1d92  ; -> sub_1d92
  0002b0:  48 c0                ext.l    d0
  0002b2:  2e 00                move.l   d0, d7
  0002b4:  50 4f                addq.w   #$8, a7
  0002b6:  67 40                beq.b    $2f8  ; -> L2f8
  0002b8:  0c 87 ff ff d8 f0    cmpi.l   #$ffffd8f0, d7
  0002be:  6e 22                bgt.b    $2e2  ; -> L2e2
  0002c0:  0c 87 ff ff d8 da    cmpi.l   #$ffffd8da, d7
  0002c6:  6f 1a                ble.b    $2e2  ; -> L2e2
  0002c8:  70 01                moveq    #$1, d0
  0002ca:  2f 00                move.l   d0, -(a7)
  0002cc:  2f 07                move.l   d7, -(a7)
  0002ce:  2f 0c                move.l   a4, -(a7)
  0002d0:  2f 0b                move.l   a3, -(a7)
  0002d2:  48 c6                ext.l    d6
  0002d4:  2f 06                move.l   d6, -(a7)
  0002d6:  61 ff 00 00 0b 64    bsr.l    $e3c  ; -> sub_e3c
  0002dc:  4f ef 00 14          lea.l    $14(a7), a7
  0002e0:  60 0c                bra.b    $2ee  ; -> L2ee
L2e2:
  0002e2:  70 01                moveq    #$1, d0
  0002e4:  2f 00                move.l   d0, -(a7)
  0002e6:  61 ff 00 00 09 e0    bsr.l    $cc8  ; -> sub_cc8
  0002ec:  58 4f                addq.w   #$4, a7
L2ee:
  0002ee:  20 6e ff fc          movea.l  -$4(a6), a0
  0002f2:  20 50                movea.l  (a0), a0
  0002f4:  30 ae ff ec          move.w   -$14(a6), (a0)
L2f8:
  0002f8:  2f 0c                move.l   a4, -(a7)
  0002fa:  2f 0b                move.l   a3, -(a7)
  0002fc:  48 c6                ext.l    d6
  0002fe:  2f 06                move.l   d6, -(a7)
  000300:  61 ff 00 00 0c bc    bsr.l    $fbe  ; -> sub_fbe
  000306:  2e 00                move.l   d0, d7
  000308:  4f ef 00 0c          lea.l    $c(a7), a7
  00030c:  6c 2c                bge.b    $33a  ; -> L33a
  00030e:  0c 87 ff ff d8 f0    cmpi.l   #$ffffd8f0, d7
  000314:  6e 24                bgt.b    $33a  ; -> L33a
  000316:  0c 87 ff ff d8 da    cmpi.l   #$ffffd8da, d7
  00031c:  6f 1c                ble.b    $33a  ; -> L33a
  00031e:  70 00                moveq    #$0, d0
  000320:  2f 00                move.l   d0, -(a7)
  000322:  2f 07                move.l   d7, -(a7)
  000324:  2f 0c                move.l   a4, -(a7)
  000326:  2f 0b                move.l   a3, -(a7)
  000328:  48 c6                ext.l    d6
  00032a:  2f 06                move.l   d6, -(a7)
  00032c:  61 ff 00 00 0b 0e    bsr.l    $e3c  ; -> sub_e3c
  000332:  4f ef 00 14          lea.l    $14(a7), a7
  000336:  60 00 01 12          bra.w    $44a  ; -> msg_nulDev
L33a:
  00033a:  20 6e ff fc          movea.l  -$4(a6), a0
  00033e:  20 50                movea.l  (a0), a0
  000340:  1a 28 00 10          move.b   $10(a0), d5
  000344:  2f 0c                move.l   a4, -(a7)
  000346:  2f 0b                move.l   a3, -(a7)
  000348:  48 c6                ext.l    d6
  00034a:  2f 06                move.l   d6, -(a7)
  00034c:  61 ff 00 00 03 0e    bsr.l    $65c  ; -> sub_65c
  000352:  20 6e ff fc          movea.l  -$4(a6), a0
  000356:  20 50                movea.l  (a0), a0
  000358:  ba 28 00 10          cmp.b    $10(a0), d5
  00035c:  56 c0                sne.b    d0
  00035e:  44 00                neg.b    d0
  000360:  49 c0                extb.l   d0
  000362:  2f 00                move.l   d0, -(a7)
  000364:  2f 0c                move.l   a4, -(a7)
  000366:  2f 0b                move.l   a3, -(a7)
  000368:  48 c6                ext.l    d6
  00036a:  2f 06                move.l   d6, -(a7)
  00036c:  61 ff 00 00 01 4e    bsr.l    $4bc  ; -> sub_4bc
  000372:  4f ef 00 1c          lea.l    $1c(a7), a7
  000376:  60 00 00 d2          bra.w    $44a  ; -> msg_nulDev
* message 1  hitDev  -  a dialog item was clicked.  Hit-test the
* custom areas, then dispatch to the matching control handler (depth,
* gray, monitor, gamma) and update the card.
msg_hitDev:
  00037a:  20 6e ff fc          movea.l  -$4(a6), a0
  00037e:  20 50                movea.l  (a0), a0
  000380:  4a 28 00 0c          tst.b    $c(a0)
  000384:  66 62                bne.b    $3e8  ; -> L3e8
  000386:  20 6e ff fc          movea.l  -$4(a6), a0
  00038a:  20 50                movea.l  (a0), a0
  00038c:  4a 28 00 0d          tst.b    $d(a0)
  000390:  66 56                bne.b    $3e8  ; -> L3e8
  000392:  48 6e ff ec          pea.l    -$14(a6)
  000396:  48 7a 00 d6          pea.l    $46e(pc)
  00039a:  61 ff 00 00 19 f6    bsr.l    $1d92  ; -> sub_1d92
  0003a0:  48 c0                ext.l    d0
  0003a2:  2e 00                move.l   d0, d7
  0003a4:  50 4f                addq.w   #$8, a7
  0003a6:  67 40                beq.b    $3e8  ; -> L3e8
  0003a8:  0c 87 ff ff d8 f0    cmpi.l   #$ffffd8f0, d7
  0003ae:  6e 22                bgt.b    $3d2  ; -> L3d2
  0003b0:  0c 87 ff ff d8 da    cmpi.l   #$ffffd8da, d7
  0003b6:  6f 1a                ble.b    $3d2  ; -> L3d2
  0003b8:  70 01                moveq    #$1, d0
  0003ba:  2f 00                move.l   d0, -(a7)
  0003bc:  2f 07                move.l   d7, -(a7)
  0003be:  2f 0c                move.l   a4, -(a7)
  0003c0:  2f 0b                move.l   a3, -(a7)
  0003c2:  48 c6                ext.l    d6
  0003c4:  2f 06                move.l   d6, -(a7)
  0003c6:  61 ff 00 00 0a 74    bsr.l    $e3c  ; -> sub_e3c
  0003cc:  4f ef 00 14          lea.l    $14(a7), a7
  0003d0:  60 0c                bra.b    $3de  ; -> L3de
L3d2:
  0003d2:  70 01                moveq    #$1, d0
  0003d4:  2f 00                move.l   d0, -(a7)
  0003d6:  61 ff 00 00 08 f0    bsr.l    $cc8  ; -> sub_cc8
  0003dc:  58 4f                addq.w   #$4, a7
L3de:
  0003de:  20 6e ff fc          movea.l  -$4(a6), a0
  0003e2:  20 50                movea.l  (a0), a0
  0003e4:  30 ae ff ec          move.w   -$14(a6), (a0)
L3e8:
  0003e8:  2f 0c                move.l   a4, -(a7)
  0003ea:  2f 0b                move.l   a3, -(a7)
  0003ec:  48 c6                ext.l    d6
  0003ee:  2f 06                move.l   d6, -(a7)
  0003f0:  61 ff 00 00 02 6a    bsr.l    $65c  ; -> sub_65c
  0003f6:  2f 0c                move.l   a4, -(a7)
  0003f8:  2f 0b                move.l   a3, -(a7)
  0003fa:  48 c6                ext.l    d6
  0003fc:  2f 06                move.l   d6, -(a7)
  0003fe:  30 2e 00 18          move.w   $18(a6), d0
  000402:  48 c0                ext.l    d0
  000404:  2f 00                move.l   d0, -(a7)
  000406:  61 ff 00 00 03 c4    bsr.l    $7cc  ; -> sub_7cc
  00040c:  2f 0c                move.l   a4, -(a7)
  00040e:  2f 0b                move.l   a3, -(a7)
  000410:  48 c6                ext.l    d6
  000412:  2f 06                move.l   d6, -(a7)
  000414:  61 ff 00 00 0b a8    bsr.l    $fbe  ; -> sub_fbe
  00041a:  2e 00                move.l   d0, d7
  00041c:  4f ef 00 28          lea.l    $28(a7), a7
  000420:  6c 28                bge.b    $44a  ; -> msg_nulDev
  000422:  0c 87 ff ff d8 f0    cmpi.l   #$ffffd8f0, d7
  000428:  6e 20                bgt.b    $44a  ; -> msg_nulDev
  00042a:  0c 87 ff ff d8 da    cmpi.l   #$ffffd8da, d7
  000430:  6f 18                ble.b    $44a  ; -> msg_nulDev
  000432:  70 00                moveq    #$0, d0
  000434:  2f 00                move.l   d0, -(a7)
  000436:  2f 07                move.l   d7, -(a7)
  000438:  2f 0c                move.l   a4, -(a7)
  00043a:  2f 0b                move.l   a3, -(a7)
  00043c:  48 c6                ext.l    d6
  00043e:  2f 06                move.l   d6, -(a7)
  000440:  61 ff 00 00 09 fa    bsr.l    $e3c  ; -> sub_e3c
  000446:  4f ef 00 14          lea.l    $14(a7), a7
* nulDev / activDev / deactivDev / keyEvtDev  -  nothing to do;
* return the cdevValue unchanged.
msg_nulDev:
  00044a:  4a 6e ff ec          tst.w    -$14(a6)
  00044e:  67 0e                beq.b    $45e  ; -> L45e
  000450:  55 8f                subq.l   #$2, a7
  000452:  3f 2e ff ec          move.w   -$14(a6), -(a7)
  000456:  61 ff 00 00 18 62    bsr.l    $1cba  ; -> sub_1cba
  00045c:  54 4f                addq.w   #$2, a7
L45e:
  00045e:  2d 4c 00 1c          move.l   a4, $1c(a6)
* common exit: store cdevValue in the function result and return.
L462:
  000462:  4c ee 18 e0 ff d8    movem.l  -$28(a6), d5-d7/a3-a4
  000468:  4e 5e                unlk     a6
  00046a:  4e 74 00 14          rtd      #$14
  00046e:  2e 47                movea.l  d7, a7
  000470:  72 61                moveq    #$61, d1
  000472:  70 68                moveq    #$68, d0
  000474:  41                   dc.b     $41  ; A
  000475:  63 63                bls.b    $4da
  000477:  65 6c                bcs.b    $4e5
  000479:  00                   dc.b     $00  ; .
sub_47a:
  00047a:  4e 56 00 00          link.w   a6, #$0
  00047e:  2f 0c                move.l   a4, -(a7)
  000480:  28 6e 00 10          movea.l  $10(a6), a4
  000484:  20 0c                move.l   a4, d0
  000486:  67 2c                beq.b    $4b4  ; -> L4b4
  000488:  20 54                movea.l  (a4), a0
  00048a:  4a a8 00 1e          tst.l    $1e(a0)
  00048e:  67 0e                beq.b    $49e  ; -> L49e
  000490:  2f 28 00 1e          move.l   $1e(a0), -(a7)
  000494:  aa 25                dc.w     $aa25  ; _DisposCIcon
  000496:  20 54                movea.l  (a4), a0
  000498:  70 00                moveq    #$0, d0
  00049a:  21 40 00 1e          move.l   d0, $1e(a0)
L49e:
  00049e:  20 54                movea.l  (a4), a0
  0004a0:  4a a8 00 12          tst.l    $12(a0)
  0004a4:  67 0e                beq.b    $4b4  ; -> L4b4
  0004a6:  2f 28 00 12          move.l   $12(a0), -(a7)
  0004aa:  aa 25                dc.w     $aa25  ; _DisposCIcon
  0004ac:  20 54                movea.l  (a4), a0
  0004ae:  70 00                moveq    #$0, d0
  0004b0:  21 40 00 12          move.l   d0, $12(a0)
L4b4:
  0004b4:  28 6e ff fc          movea.l  -$4(a6), a4
  0004b8:  4e 5e                unlk     a6
  0004ba:  4e 75                rts      
sub_4bc:
  0004bc:  4e 56 00 00          link.w   a6, #$0
  0004c0:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  0004c4:  1e 2e 00 17          move.b   $17(a6), d7
  0004c8:  26 6e 00 0c          movea.l  $c(a6), a3
  0004cc:  28 6e 00 10          movea.l  $10(a6), a4
  0004d0:  20 4c                movea.l  a4, a0
  0004d2:  a0 69                dc.w     $a069  ; _HGetState
  0004d4:  1c 00                move.b   d0, d6
  0004d6:  20 4c                movea.l  a4, a0
  0004d8:  a0 29                dc.w     $a029  ; _HLock
  0004da:  20 54                movea.l  (a4), a0
  0004dc:  4a 28 00 0c          tst.b    $c(a0)
  0004e0:  67 1a                beq.b    $4fc  ; -> L4fc
  0004e2:  2f 3c ff ff d8 e6    move.l   #$ffffd8e6, -(a7)
  0004e8:  30 2e 00 0a          move.w   $a(a6), d0
  0004ec:  48 c0                ext.l    d0
  0004ee:  2f 00                move.l   d0, -(a7)
  0004f0:  2f 0b                move.l   a3, -(a7)
  0004f2:  61 ff 00 00 09 96    bsr.l    $e8a  ; -> sub_e8a
  0004f8:  4f ef 00 0c          lea.l    $c(a7), a7
L4fc:
  0004fc:  20 54                movea.l  (a4), a0
  0004fe:  4a 28 00 0d          tst.b    $d(a0)
  000502:  66 06                bne.b    $50a  ; -> L50a
  000504:  4a 28 00 0c          tst.b    $c(a0)
  000508:  67 10                beq.b    $51a  ; -> L51a
L50a:
  00050a:  20 54                movea.l  (a4), a0
  00050c:  48 68 00 10          pea.l    $10(a0)
  000510:  61 ff 00 00 12 92    bsr.l    $17a4  ; -> sub_17a4
  000516:  58 4f                addq.w   #$4, a7
  000518:  60 1e                bra.b    $538  ; -> L538
L51a:
  00051a:  4a 07                tst.b    d7
  00051c:  67 04                beq.b    $522  ; -> L522
  00051e:  2f 0b                move.l   a3, -(a7)
  000520:  a9 23                dc.w     $a923  ; _EndUpDate
L522:
  000522:  20 54                movea.l  (a4), a0
  000524:  48 68 00 10          pea.l    $10(a0)
  000528:  61 ff 00 00 13 0a    bsr.l    $1834  ; -> sub_1834
  00052e:  4a 07                tst.b    d7
  000530:  58 4f                addq.w   #$4, a7
  000532:  67 04                beq.b    $538  ; -> L538
  000534:  2f 0b                move.l   a3, -(a7)
  000536:  a9 22                dc.w     $a922  ; _BeginUpDate
L538:
  000538:  20 4c                movea.l  a4, a0
  00053a:  a0 2a                dc.w     $a02a  ; _HUnlock
  00053c:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  000542:  4e 5e                unlk     a6
  000544:  4e 75                rts      
sub_546:
  000546:  4e 56 ff ea          link.w   a6, #$ffea
  00054a:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  00054e:  26 6e 00 0c          movea.l  $c(a6), a3
  000552:  2c 2e 00 08          move.l   $8(a6), d6
  000556:  28 6e 00 10          movea.l  $10(a6), a4
  00055a:  7e ff                moveq    #$ff, d7
  00055c:  20 54                movea.l  (a4), a0
  00055e:  4a 28 00 0c          tst.b    $c(a0)
  000562:  66 06                bne.b    $56a  ; -> L56a
  000564:  4a 28 00 0d          tst.b    $d(a0)
  000568:  67 06                beq.b    $570  ; -> L570
L56a:
  00056a:  70 00                moveq    #$0, d0
  00056c:  60 00 00 e4          bra.w    $652  ; -> L652
L570:
  000570:  20 54                movea.l  (a4), a0
  000572:  3e 10                move.w   (a0), d7
  000574:  55 8f                subq.l   #$2, a7
  000576:  3f 07                move.w   d7, -(a7)
  000578:  70 02                moveq    #$2, d0
  00057a:  3f 00                move.w   d0, -(a7)
  00057c:  48 6e ff ea          pea.l    -$16(a6)
  000580:  61 ff 00 00 17 8c    bsr.l    $1d0e  ; -> sub_1d0e
  000586:  4a 5f                tst.w    (a7)+
  000588:  67 16                beq.b    $5a0  ; -> L5a0
  00058a:  70 09                moveq    #$9, d0
  00058c:  2f 00                move.l   d0, -(a7)
  00058e:  61 ff 00 00 07 38    bsr.l    $cc8  ; -> sub_cc8
  000594:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  00059a:  58 4f                addq.w   #$4, a7
  00059c:  60 00 00 b4          bra.w    $652  ; -> L652
L5a0:
  0005a0:  4a ae ff ec          tst.l    -$14(a6)
  0005a4:  66 0a                bne.b    $5b0  ; -> L5b0
  0005a6:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  0005ac:  60 00 00 a4          bra.w    $652  ; -> L652
L5b0:
  0005b0:  70 01                moveq    #$1, d0
  0005b2:  b0 ae ff ec          cmp.l    -$14(a6), d0
  0005b6:  6c 14                bge.b    $5cc  ; -> L5cc
  0005b8:  2f 3c ff ff d8 e7    move.l   #$ffffd8e7, -(a7)
  0005be:  2f 06                move.l   d6, -(a7)
  0005c0:  2f 0b                move.l   a3, -(a7)
  0005c2:  61 ff 00 00 08 c6    bsr.l    $e8a  ; -> sub_e8a
  0005c8:  4f ef 00 0c          lea.l    $c(a7), a7
L5cc:
  0005cc:  42 6e ff ea          clr.w    -$16(a6)
  0005d0:  55 8f                subq.l   #$2, a7
  0005d2:  3f 07                move.w   d7, -(a7)
  0005d4:  70 63                moveq    #$63, d0
  0005d6:  3f 00                move.w   d0, -(a7)
  0005d8:  48 6e ff ea          pea.l    -$16(a6)
  0005dc:  61 ff 00 00 16 fa    bsr.l    $1cd8  ; -> sub_1cd8
  0005e2:  4a 5f                tst.w    (a7)+
  0005e4:  67 14                beq.b    $5fa  ; -> L5fa
  0005e6:  70 11                moveq    #$11, d0
  0005e8:  2f 00                move.l   d0, -(a7)
  0005ea:  61 ff 00 00 06 dc    bsr.l    $cc8  ; -> sub_cc8
  0005f0:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  0005f6:  58 4f                addq.w   #$4, a7
  0005f8:  60 58                bra.b    $652  ; -> L652
L5fa:
  0005fa:  55 8f                subq.l   #$2, a7
  0005fc:  3f 07                move.w   d7, -(a7)
  0005fe:  70 07                moveq    #$7, d0
  000600:  3f 00                move.w   d0, -(a7)
  000602:  48 6e ff ea          pea.l    -$16(a6)
  000606:  61 ff 00 00 17 06    bsr.l    $1d0e  ; -> sub_1d0e
  00060c:  4a 5f                tst.w    (a7)+
  00060e:  67 14                beq.b    $624  ; -> L624
  000610:  70 0c                moveq    #$c, d0
  000612:  2f 00                move.l   d0, -(a7)
  000614:  61 ff 00 00 06 b2    bsr.l    $cc8  ; -> sub_cc8
  00061a:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  000620:  58 4f                addq.w   #$4, a7
  000622:  60 2e                bra.b    $652  ; -> L652
L624:
  000624:  20 54                movea.l  (a4), a0
  000626:  21 6e ff ec 00 04    move.l   -$14(a6), $4(a0)
  00062c:  20 3c 80 00 00 00    move.l   #$80000000, d0
  000632:  c0 ae ff ec          and.l    -$14(a6), d0
  000636:  67 0a                beq.b    $642  ; -> L642
  000638:  2f 0c                move.l   a4, -(a7)
  00063a:  61 ff 00 00 07 56    bsr.l    $d92  ; -> sub_d92
  000640:  58 4f                addq.w   #$4, a7
L642:
  000642:  2f 0c                move.l   a4, -(a7)
  000644:  2f 0b                move.l   a3, -(a7)
  000646:  2f 06                move.l   d6, -(a7)
  000648:  61 ff 00 00 00 12    bsr.l    $65c  ; -> sub_65c
  00064e:  4f ef 00 0c          lea.l    $c(a7), a7
L652:
  000652:  4c ee 18 c0 ff da    movem.l  -$26(a6), d6-d7/a3-a4
  000658:  4e 5e                unlk     a6
  00065a:  4e 75                rts      
sub_65c:
  00065c:  4e 56 ff ea          link.w   a6, #$ffea
  000660:  48 e7 01 08          movem.l  d7/a4, -(a7)
  000664:  28 6e 00 10          movea.l  $10(a6), a4
  000668:  20 54                movea.l  (a4), a0
  00066a:  4a 28 00 0c          tst.b    $c(a0)
  00066e:  66 06                bne.b    $676  ; -> L676
  000670:  4a 28 00 0d          tst.b    $d(a0)
  000674:  67 0a                beq.b    $680  ; -> L680
L676:
  000676:  20 3c ff ff d8 e6    move.l   #$ffffd8e6, d0
  00067c:  60 00 01 44          bra.w    $7c2  ; -> L7c2
L680:
  000680:  42 6e ff ea          clr.w    -$16(a6)
  000684:  55 8f                subq.l   #$2, a7
  000686:  20 54                movea.l  (a4), a0
  000688:  3f 10                move.w   (a0), -(a7)
  00068a:  70 63                moveq    #$63, d0
  00068c:  3f 00                move.w   d0, -(a7)
  00068e:  48 6e ff ea          pea.l    -$16(a6)
  000692:  61 ff 00 00 16 44    bsr.l    $1cd8  ; -> sub_1cd8
  000698:  4a 5f                tst.w    (a7)+
  00069a:  67 16                beq.b    $6b2  ; -> L6b2
  00069c:  70 11                moveq    #$11, d0
  00069e:  2f 00                move.l   d0, -(a7)
  0006a0:  61 ff 00 00 06 26    bsr.l    $cc8  ; -> sub_cc8
  0006a6:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  0006ac:  58 4f                addq.w   #$4, a7
  0006ae:  60 00 01 12          bra.w    $7c2  ; -> L7c2
L6b2:
  0006b2:  55 8f                subq.l   #$2, a7
  0006b4:  20 54                movea.l  (a4), a0
  0006b6:  3f 10                move.w   (a0), -(a7)
  0006b8:  70 15                moveq    #$15, d0
  0006ba:  3f 00                move.w   d0, -(a7)
  0006bc:  48 6e ff ea          pea.l    -$16(a6)
  0006c0:  61 ff 00 00 16 4c    bsr.l    $1d0e  ; -> sub_1d0e
  0006c6:  4a 5f                tst.w    (a7)+
  0006c8:  67 16                beq.b    $6e0  ; -> L6e0
  0006ca:  70 08                moveq    #$8, d0
  0006cc:  2f 00                move.l   d0, -(a7)
  0006ce:  61 ff 00 00 05 f8    bsr.l    $cc8  ; -> sub_cc8
  0006d4:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  0006da:  58 4f                addq.w   #$4, a7
  0006dc:  60 00 00 e4          bra.w    $7c2  ; -> L7c2
L6e0:
  0006e0:  4a ae ff ec          tst.l    -$14(a6)
  0006e4:  6c 08                bge.b    $6ee  ; -> L6ee
  0006e6:  20 2e ff ec          move.l   -$14(a6), d0
  0006ea:  60 00 00 d6          bra.w    $7c2  ; -> L7c2
L6ee:
  0006ee:  55 8f                subq.l   #$2, a7
  0006f0:  20 54                movea.l  (a4), a0
  0006f2:  3f 10                move.w   (a0), -(a7)
  0006f4:  70 05                moveq    #$5, d0
  0006f6:  3f 00                move.w   d0, -(a7)
  0006f8:  48 6e ff ea          pea.l    -$16(a6)
  0006fc:  61 ff 00 00 16 10    bsr.l    $1d0e  ; -> sub_1d0e
  000702:  4a 5f                tst.w    (a7)+
  000704:  67 16                beq.b    $71c  ; -> L71c
  000706:  70 08                moveq    #$8, d0
  000708:  2f 00                move.l   d0, -(a7)
  00070a:  61 ff 00 00 05 bc    bsr.l    $cc8  ; -> sub_cc8
  000710:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  000716:  58 4f                addq.w   #$4, a7
  000718:  60 00 00 a8          bra.w    $7c2  ; -> L7c2
L71c:
  00071c:  20 54                movea.l  (a4), a0
  00071e:  21 6e ff ec 00 08    move.l   -$14(a6), $8(a0)
  000724:  20 54                movea.l  (a4), a0
  000726:  02 a8 ff ff f7 ff 00 08 andi.l   #$fffff7ff, $8(a0)
  00072e:  20 54                movea.l  (a4), a0
  000730:  70 01                moveq    #$1, d0
  000732:  c0 a8 00 08          and.l    $8(a0), d0
  000736:  66 14                bne.b    $74c  ; -> L74c
  000738:  70 02                moveq    #$2, d0
  00073a:  2f 00                move.l   d0, -(a7)
  00073c:  61 ff 00 00 05 8a    bsr.l    $cc8  ; -> sub_cc8
  000742:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  000748:  58 4f                addq.w   #$4, a7
  00074a:  60 76                bra.b    $7c2  ; -> L7c2
L74c:
  00074c:  20 54                movea.l  (a4), a0
  00074e:  70 06                moveq    #$6, d0
  000750:  c0 a8 00 08          and.l    $8(a0), d0
  000754:  72 06                moveq    #$6, d1
  000756:  b2 80                cmp.l    d0, d1
  000758:  67 1a                beq.b    $774  ; -> L774
  00075a:  70 00                moveq    #$0, d0
  00075c:  2f 00                move.l   d0, -(a7)
  00075e:  2f 0c                move.l   a4, -(a7)
  000760:  61 ff 00 00 03 2a    bsr.l    $a8c  ; -> sub_a8c
  000766:  4a 80                tst.l    d0
  000768:  50 4f                addq.w   #$8, a7
  00076a:  67 08                beq.b    $774  ; -> L774
  00076c:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  000772:  60 4e                bra.b    $7c2  ; -> L7c2
L774:
  000774:  20 4c                movea.l  a4, a0
  000776:  a0 69                dc.w     $a069  ; _HGetState
  000778:  1e 00                move.b   d0, d7
  00077a:  20 4c                movea.l  a4, a0
  00077c:  a0 29                dc.w     $a029  ; _HLock
  00077e:  20 54                movea.l  (a4), a0
  000780:  70 20                moveq    #$20, d0
  000782:  c0 a8 00 08          and.l    $8(a0), d0
  000786:  67 08                beq.b    $790  ; -> L790
  000788:  11 7c 00 01 00 10    move.b   #$1, $10(a0)
  00078e:  60 2c                bra.b    $7bc  ; -> L7bc
L790:
  000790:  20 54                movea.l  (a4), a0
  000792:  20 3c 00 00 08 00    move.l   #$800, d0
  000798:  c0 a8 00 08          and.l    $8(a0), d0
  00079c:  67 0a                beq.b    $7a8  ; -> L7a8
  00079e:  22 48                movea.l  a0, a1
  0007a0:  13 68 00 0e 00 10    move.b   $e(a0), $10(a1)
  0007a6:  60 14                bra.b    $7bc  ; -> L7bc
L7a8:
  0007a8:  70 00                moveq    #$0, d0
  0007aa:  2f 00                move.l   d0, -(a7)
  0007ac:  2f 0c                move.l   a4, -(a7)
  0007ae:  61 ff 00 00 01 1a    bsr.l    $8ca  ; -> sub_8ca
  0007b4:  20 54                movea.l  (a4), a0
  0007b6:  42 28 00 10          clr.b    $10(a0)
  0007ba:  50 4f                addq.w   #$8, a7
L7bc:
  0007bc:  20 4c                movea.l  a4, a0
  0007be:  a0 2a                dc.w     $a02a  ; _HUnlock
  0007c0:  70 00                moveq    #$0, d0
L7c2:
  0007c2:  4c ee 10 80 ff e2    movem.l  -$1e(a6), d7/a4
  0007c8:  4e 5e                unlk     a6
  0007ca:  4e 75                rts      
sub_7cc:
  0007cc:  4e 56 00 00          link.w   a6, #$0
  0007d0:  48 e7 07 18          movem.l  d5-d7/a3-a4, -(a7)
  0007d4:  2c 2e 00 0c          move.l   $c(a6), d6
  0007d8:  26 6e 00 10          movea.l  $10(a6), a3
  0007dc:  28 6e 00 14          movea.l  $14(a6), a4
  0007e0:  42 07                clr.b    d7
  0007e2:  20 54                movea.l  (a4), a0
  0007e4:  4a 28 00 0c          tst.b    $c(a0)
  0007e8:  66 06                bne.b    $7f0  ; -> L7f0
  0007ea:  4a 28 00 0d          tst.b    $d(a0)
  0007ee:  67 0a                beq.b    $7fa  ; -> L7fa
L7f0:
  0007f0:  70 01                moveq    #$1, d0
  0007f2:  3f 00                move.w   d0, -(a7)
  0007f4:  a9 c8                dc.w     $a9c8  ; _SysBeep
  0007f6:  60 00 00 c8          bra.w    $8c0  ; -> L8c0
L7fa:
  0007fa:  30 2e 00 0a          move.w   $a(a6), d0
  0007fe:  48 c0                ext.l    d0
  000800:  90 86                sub.l    d6, d0
  000802:  53 80                subq.l   #$1, d0
  000804:  67 06                beq.b    $80c  ; -> L80c
  000806:  53 80                subq.l   #$1, d0
  000808:  66 00 00 b6          bne.w    $8c0  ; -> L8c0
L80c:
  00080c:  20 4c                movea.l  a4, a0
  00080e:  a0 69                dc.w     $a069  ; _HGetState
  000810:  1a 00                move.b   d0, d5
  000812:  20 4c                movea.l  a4, a0
  000814:  a0 29                dc.w     $a029  ; _HLock
  000816:  2f 0b                move.l   a3, -(a7)
  000818:  20 54                movea.l  (a4), a0
  00081a:  48 68 00 10          pea.l    $10(a0)
  00081e:  61 ff 00 00 11 00    bsr.l    $1920  ; -> sub_1920
  000824:  2a 00                move.l   d0, d5
  000826:  50 4f                addq.w   #$8, a7
  000828:  66 2c                bne.b    $856  ; -> L856
  00082a:  20 54                movea.l  (a4), a0
  00082c:  4a 28 00 10          tst.b    $10(a0)
  000830:  67 24                beq.b    $856  ; -> L856
  000832:  42 28 00 0e          clr.b    $e(a0)
  000836:  70 00                moveq    #$0, d0
  000838:  2f 00                move.l   d0, -(a7)
  00083a:  2f 0c                move.l   a4, -(a7)
  00083c:  61 ff 00 00 04 f2    bsr.l    $d30  ; -> sub_d30
  000842:  7e 01                moveq    #$1, d7
  000844:  70 00                moveq    #$0, d0
  000846:  2f 00                move.l   d0, -(a7)
  000848:  2f 0c                move.l   a4, -(a7)
  00084a:  61 ff 00 00 00 7e    bsr.l    $8ca  ; -> sub_8ca
  000850:  4f ef 00 10          lea.l    $10(a7), a7
  000854:  60 3c                bra.b    $892  ; -> L892
L856:
  000856:  70 01                moveq    #$1, d0
  000858:  b0 85                cmp.l    d5, d0
  00085a:  66 36                bne.b    $892  ; -> L892
  00085c:  20 54                movea.l  (a4), a0
  00085e:  4a 28 00 10          tst.b    $10(a0)
  000862:  66 2e                bne.b    $892  ; -> L892
  000864:  11 7c 00 01 00 0e    move.b   #$1, $e(a0)
  00086a:  70 01                moveq    #$1, d0
  00086c:  2f 00                move.l   d0, -(a7)
  00086e:  2f 0c                move.l   a4, -(a7)
  000870:  61 ff 00 00 04 be    bsr.l    $d30  ; -> sub_d30
  000876:  7e 01                moveq    #$1, d7
  000878:  70 01                moveq    #$1, d0
  00087a:  2f 00                move.l   d0, -(a7)
  00087c:  2f 0c                move.l   a4, -(a7)
  00087e:  61 ff 00 00 00 4a    bsr.l    $8ca  ; -> sub_8ca
  000884:  4a 80                tst.l    d0
  000886:  4f ef 00 10          lea.l    $10(a7), a7
  00088a:  67 06                beq.b    $892  ; -> L892
  00088c:  70 01                moveq    #$1, d0
  00088e:  3f 00                move.w   d0, -(a7)
  000890:  a9 c8                dc.w     $a9c8  ; _SysBeep
L892:
  000892:  4a 07                tst.b    d7
  000894:  67 26                beq.b    $8bc  ; -> L8bc
  000896:  2f 0b                move.l   a3, -(a7)
  000898:  20 54                movea.l  (a4), a0
  00089a:  70 00                moveq    #$0, d0
  00089c:  10 28 00 0e          move.b   $e(a0), d0
  0008a0:  2f 00                move.l   d0, -(a7)
  0008a2:  48 68 00 10          pea.l    $10(a0)
  0008a6:  61 ff 00 00 10 5a    bsr.l    $1902  ; -> sub_1902
  0008ac:  2f 0c                move.l   a4, -(a7)
  0008ae:  2f 0b                move.l   a3, -(a7)
  0008b0:  2f 06                move.l   d6, -(a7)
  0008b2:  61 ff ff ff fd a8    bsr.l    $65c  ; -> sub_65c
  0008b8:  4f ef 00 18          lea.l    $18(a7), a7
L8bc:
  0008bc:  20 4c                movea.l  a4, a0
  0008be:  a0 2a                dc.w     $a02a  ; _HUnlock
L8c0:
  0008c0:  4c ee 18 e0 ff ec    movem.l  -$14(a6), d5-d7/a3-a4
  0008c6:  4e 5e                unlk     a6
  0008c8:  4e 75                rts      
sub_8ca:
  0008ca:  4e 56 ff ea          link.w   a6, #$ffea
  0008ce:  2f 0c                move.l   a4, -(a7)
  0008d0:  28 6e 00 08          movea.l  $8(a6), a4
  0008d4:  42 6e ff ea          clr.w    -$16(a6)
  0008d8:  4a 2e 00 0f          tst.b    $f(a6)
  0008dc:  67 00 00 f4          beq.w    $9d2  ; -> L9d2
  0008e0:  55 8f                subq.l   #$2, a7
  0008e2:  20 54                movea.l  (a4), a0
  0008e4:  3f 10                move.w   (a0), -(a7)
  0008e6:  70 63                moveq    #$63, d0
  0008e8:  3f 00                move.w   d0, -(a7)
  0008ea:  48 6e ff ea          pea.l    -$16(a6)
  0008ee:  61 ff 00 00 13 e8    bsr.l    $1cd8  ; -> sub_1cd8
  0008f4:  4a 5f                tst.w    (a7)+
  0008f6:  67 0a                beq.b    $902  ; -> L902
  0008f8:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  0008fe:  60 00 01 3e          bra.w    $a3e  ; -> La3e
L902:
  000902:  55 8f                subq.l   #$2, a7
  000904:  20 54                movea.l  (a4), a0
  000906:  3f 10                move.w   (a0), -(a7)
  000908:  70 05                moveq    #$5, d0
  00090a:  3f 00                move.w   d0, -(a7)
  00090c:  48 6e ff ea          pea.l    -$16(a6)
  000910:  61 ff 00 00 13 fc    bsr.l    $1d0e  ; -> sub_1d0e
  000916:  4a 5f                tst.w    (a7)+
  000918:  67 16                beq.b    $930  ; -> L930
  00091a:  70 08                moveq    #$8, d0
  00091c:  2f 00                move.l   d0, -(a7)
  00091e:  61 ff 00 00 03 a8    bsr.l    $cc8  ; -> sub_cc8
  000924:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  00092a:  58 4f                addq.w   #$4, a7
  00092c:  60 00 01 10          bra.w    $a3e  ; -> La3e
L930:
  000930:  20 54                movea.l  (a4), a0
  000932:  21 6e ff ec 00 08    move.l   -$14(a6), $8(a0)
  000938:  20 54                movea.l  (a4), a0
  00093a:  02 a8 ff ff f7 ff 00 08 andi.l   #$fffff7ff, $8(a0)
  000942:  20 54                movea.l  (a4), a0
  000944:  20 3c 00 00 08 00    move.l   #$800, d0
  00094a:  c0 a8 00 08          and.l    $8(a0), d0
  00094e:  67 06                beq.b    $956  ; -> L956
  000950:  70 00                moveq    #$0, d0
  000952:  60 00 00 ea          bra.w    $a3e  ; -> La3e
L956:
  000956:  20 54                movea.l  (a4), a0
  000958:  70 02                moveq    #$2, d0
  00095a:  c0 a8 00 08          and.l    $8(a0), d0
  00095e:  66 0e                bne.b    $96e  ; -> L96e
  000960:  70 01                moveq    #$1, d0
  000962:  2f 00                move.l   d0, -(a7)
  000964:  2f 0c                move.l   a4, -(a7)
  000966:  61 ff 00 00 01 24    bsr.l    $a8c  ; -> sub_a8c
  00096c:  50 4f                addq.w   #$8, a7
L96e:
  00096e:  55 8f                subq.l   #$2, a7
  000970:  20 54                movea.l  (a4), a0
  000972:  3f 10                move.w   (a0), -(a7)
  000974:  70 05                moveq    #$5, d0
  000976:  3f 00                move.w   d0, -(a7)
  000978:  48 6e ff ea          pea.l    -$16(a6)
  00097c:  61 ff 00 00 13 90    bsr.l    $1d0e  ; -> sub_1d0e
  000982:  4a 5f                tst.w    (a7)+
  000984:  67 16                beq.b    $99c  ; -> L99c
  000986:  70 08                moveq    #$8, d0
  000988:  2f 00                move.l   d0, -(a7)
  00098a:  61 ff 00 00 03 3c    bsr.l    $cc8  ; -> sub_cc8
  000990:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  000996:  58 4f                addq.w   #$4, a7
  000998:  60 00 00 a4          bra.w    $a3e  ; -> La3e
L99c:
  00099c:  20 54                movea.l  (a4), a0
  00099e:  21 6e ff ec 00 08    move.l   -$14(a6), $8(a0)
  0009a4:  20 54                movea.l  (a4), a0
  0009a6:  02 a8 ff ff f7 ff 00 08 andi.l   #$fffff7ff, $8(a0)
  0009ae:  42 6e ff ea          clr.w    -$16(a6)
  0009b2:  55 8f                subq.l   #$2, a7
  0009b4:  20 54                movea.l  (a4), a0
  0009b6:  3f 10                move.w   (a0), -(a7)
  0009b8:  70 0d                moveq    #$d, d0
  0009ba:  3f 00                move.w   d0, -(a7)
  0009bc:  48 6e ff ea          pea.l    -$16(a6)
  0009c0:  61 ff 00 00 13 16    bsr.l    $1cd8  ; -> sub_1cd8
  0009c6:  4a 5f                tst.w    (a7)+
  0009c8:  67 34                beq.b    $9fe  ; -> L9fe
  0009ca:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  0009d0:  60 6c                bra.b    $a3e  ; -> La3e
L9d2:
  0009d2:  55 8f                subq.l   #$2, a7
  0009d4:  20 54                movea.l  (a4), a0
  0009d6:  3f 10                move.w   (a0), -(a7)
  0009d8:  70 0e                moveq    #$e, d0
  0009da:  3f 00                move.w   d0, -(a7)
  0009dc:  48 6e ff ea          pea.l    -$16(a6)
  0009e0:  61 ff 00 00 12 f6    bsr.l    $1cd8  ; -> sub_1cd8
  0009e6:  4a 5f                tst.w    (a7)+
  0009e8:  67 14                beq.b    $9fe  ; -> L9fe
  0009ea:  70 12                moveq    #$12, d0
  0009ec:  2f 00                move.l   d0, -(a7)
  0009ee:  61 ff 00 00 02 d8    bsr.l    $cc8  ; -> sub_cc8
  0009f4:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  0009fa:  58 4f                addq.w   #$4, a7
  0009fc:  60 40                bra.b    $a3e  ; -> La3e
L9fe:
  0009fe:  55 8f                subq.l   #$2, a7
  000a00:  20 54                movea.l  (a4), a0
  000a02:  3f 10                move.w   (a0), -(a7)
  000a04:  70 05                moveq    #$5, d0
  000a06:  3f 00                move.w   d0, -(a7)
  000a08:  48 6e ff ea          pea.l    -$16(a6)
  000a0c:  61 ff 00 00 13 00    bsr.l    $1d0e  ; -> sub_1d0e
  000a12:  4a 5f                tst.w    (a7)+
  000a14:  67 14                beq.b    $a2a  ; -> La2a
  000a16:  70 08                moveq    #$8, d0
  000a18:  2f 00                move.l   d0, -(a7)
  000a1a:  61 ff 00 00 02 ac    bsr.l    $cc8  ; -> sub_cc8
  000a20:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  000a26:  58 4f                addq.w   #$4, a7
  000a28:  60 14                bra.b    $a3e  ; -> La3e
La2a:
  000a2a:  20 54                movea.l  (a4), a0
  000a2c:  21 6e ff ec 00 08    move.l   -$14(a6), $8(a0)
  000a32:  20 54                movea.l  (a4), a0
  000a34:  02 a8 ff ff f7 ff 00 08 andi.l   #$fffff7ff, $8(a0)
  000a3c:  70 00                moveq    #$0, d0
La3e:
  000a3e:  28 6e ff e6          movea.l  -$1a(a6), a4
  000a42:  4e 5e                unlk     a6
  000a44:  4e 75                rts      
sub_a46:
  000a46:  4e 56 00 00          link.w   a6, #$0
  000a4a:  48 e7 00 18          movem.l  a3-a4, -(a7)
  000a4e:  a1 1a                dc.w     $a11a  ; _GetZone
  000a50:  26 48                movea.l  a0, a3
  000a52:  20 78 02 a6          movea.l  $2a6.w, a0
  000a56:  a0 1b                dc.w     $a01b  ; _SetZone
  000a58:  59 8f                subq.l   #$4, a7
  000a5a:  2f 3c 41 43 45 46    move.l   #$41434546, -(a7)  ; 'ACEF'
  000a60:  3f 2e 00 0a          move.w   $a(a6), -(a7)
  000a64:  a8 1f                dc.w     $a81f  ; _Get1Resource
  000a66:  28 5f                movea.l  (a7)+, a4
  000a68:  20 0c                move.l   a4, d0
  000a6a:  67 08                beq.b    $a74  ; -> La74
  000a6c:  55 8f                subq.l   #$2, a7
  000a6e:  a9 af                dc.w     $a9af  ; _ResError
  000a70:  4a 5f                tst.w    (a7)+
  000a72:  67 04                beq.b    $a78  ; -> La78
La74:
  000a74:  70 00                moveq    #$0, d0
  000a76:  60 0a                bra.b    $a82  ; -> La82
La78:
  000a78:  2f 0c                move.l   a4, -(a7)
  000a7a:  a9 a2                dc.w     $a9a2  ; _LoadResource
  000a7c:  20 4b                movea.l  a3, a0
  000a7e:  a0 1b                dc.w     $a01b  ; _SetZone
  000a80:  20 0c                move.l   a4, d0
La82:
  000a82:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  000a88:  4e 5e                unlk     a6
  000a8a:  4e 75                rts      
sub_a8c:
  000a8c:  4e 56 ff e6          link.w   a6, #$ffe6
  000a90:  48 e7 0f 08          movem.l  d4-d7/a4, -(a7)
  000a94:  28 6e 00 08          movea.l  $8(a6), a4
  000a98:  28 3c ff ff d8 da    move.l   #$ffffd8da, d4
  000a9e:  7c 00                moveq    #$0, d6
  000aa0:  20 54                movea.l  (a4), a0
  000aa2:  2d 68 00 04 ff fc    move.l   $4(a0), -$4(a6)
  000aa8:  20 54                movea.l  (a4), a0
  000aaa:  3e 10                move.w   (a0), d7
  000aac:  3d 46 ff e6          move.w   d6, -$1a(a6)
  000ab0:  55 8f                subq.l   #$2, a7
  000ab2:  3f 07                move.w   d7, -(a7)
  000ab4:  70 63                moveq    #$63, d0
  000ab6:  3f 00                move.w   d0, -(a7)
  000ab8:  48 6e ff e6          pea.l    -$1a(a6)
  000abc:  61 ff 00 00 12 1a    bsr.l    $1cd8  ; -> sub_1cd8
  000ac2:  4a 5f                tst.w    (a7)+
  000ac4:  67 10                beq.b    $ad6  ; -> Lad6
  000ac6:  70 11                moveq    #$11, d0
  000ac8:  2f 00                move.l   d0, -(a7)
  000aca:  61 ff 00 00 01 fc    bsr.l    $cc8  ; -> sub_cc8
  000ad0:  58 4f                addq.w   #$4, a7
  000ad2:  60 00 01 70          bra.w    $c44  ; -> Lc44
Lad6:
  000ad6:  55 8f                subq.l   #$2, a7
  000ad8:  3f 07                move.w   d7, -(a7)
  000ada:  70 05                moveq    #$5, d0
  000adc:  3f 00                move.w   d0, -(a7)
  000ade:  48 6e ff e6          pea.l    -$1a(a6)
  000ae2:  61 ff 00 00 12 2a    bsr.l    $1d0e  ; -> sub_1d0e
  000ae8:  4a 5f                tst.w    (a7)+
  000aea:  67 10                beq.b    $afc  ; -> Lafc
  000aec:  70 08                moveq    #$8, d0
  000aee:  2f 00                move.l   d0, -(a7)
  000af0:  61 ff 00 00 01 d6    bsr.l    $cc8  ; -> sub_cc8
  000af6:  58 4f                addq.w   #$4, a7
  000af8:  60 00 01 4a          bra.w    $c44  ; -> Lc44
Lafc:
  000afc:  3d 46 ff e6          move.w   d6, -$1a(a6)
  000b00:  2a 2e ff e8          move.l   -$18(a6), d5
  000b04:  70 20                moveq    #$20, d0
  000b06:  c0 85                and.l    d5, d0
  000b08:  67 26                beq.b    $b30  ; -> Lb30
  000b0a:  55 8f                subq.l   #$2, a7
  000b0c:  3f 07                move.w   d7, -(a7)
  000b0e:  70 0e                moveq    #$e, d0
  000b10:  3f 00                move.w   d0, -(a7)
  000b12:  48 6e ff e6          pea.l    -$1a(a6)
  000b16:  61 ff 00 00 11 c0    bsr.l    $1cd8  ; -> sub_1cd8
  000b1c:  4a 5f                tst.w    (a7)+
  000b1e:  67 10                beq.b    $b30  ; -> Lb30
  000b20:  70 12                moveq    #$12, d0
  000b22:  2f 00                move.l   d0, -(a7)
  000b24:  61 ff 00 00 01 a2    bsr.l    $cc8  ; -> sub_cc8
  000b2a:  58 4f                addq.w   #$4, a7
  000b2c:  60 00 01 16          bra.w    $c44  ; -> Lc44
Lb30:
  000b30:  4a ae 00 0c          tst.l    $c(a6)
  000b34:  67 00 00 b8          beq.w    $bee  ; -> Lbee
  000b38:  3d 46 ff e6          move.w   d6, -$1a(a6)
  000b3c:  70 01                moveq    #$1, d0
  000b3e:  2f 00                move.l   d0, -(a7)
  000b40:  61 ff ff ff ff 04    bsr.l    $a46  ; -> sub_a46
  000b46:  2d 40 ff e8          move.l   d0, -$18(a6)
  000b4a:  58 4f                addq.w   #$4, a7
  000b4c:  67 26                beq.b    $b74  ; -> Lb74
  000b4e:  55 8f                subq.l   #$2, a7
  000b50:  3f 07                move.w   d7, -(a7)
  000b52:  70 02                moveq    #$2, d0
  000b54:  3f 00                move.w   d0, -(a7)
  000b56:  48 6e ff e6          pea.l    -$1a(a6)
  000b5a:  61 ff 00 00 11 7c    bsr.l    $1cd8  ; -> sub_1cd8
  000b60:  4a 5f                tst.w    (a7)+
  000b62:  67 20                beq.b    $b84  ; -> Lb84
  000b64:  70 13                moveq    #$13, d0
  000b66:  2f 00                move.l   d0, -(a7)
  000b68:  61 ff 00 00 01 5e    bsr.l    $cc8  ; -> sub_cc8
  000b6e:  58 4f                addq.w   #$4, a7
  000b70:  60 00 00 d2          bra.w    $c44  ; -> Lc44
Lb74:
  000b74:  70 04                moveq    #$4, d0
  000b76:  2f 00                move.l   d0, -(a7)
  000b78:  61 ff 00 00 01 4e    bsr.l    $cc8  ; -> sub_cc8
  000b7e:  58 4f                addq.w   #$4, a7
  000b80:  60 00 00 c2          bra.w    $c44  ; -> Lc44
Lb84:
  000b84:  70 64                moveq    #$64, d0
  000b86:  2f 00                move.l   d0, -(a7)
  000b88:  61 ff ff ff fe bc    bsr.l    $a46  ; -> sub_a46
  000b8e:  2d 40 ff e8          move.l   d0, -$18(a6)
  000b92:  58 4f                addq.w   #$4, a7
  000b94:  67 26                beq.b    $bbc  ; -> Lbbc
  000b96:  55 8f                subq.l   #$2, a7
  000b98:  3f 07                move.w   d7, -(a7)
  000b9a:  70 03                moveq    #$3, d0
  000b9c:  3f 00                move.w   d0, -(a7)
  000b9e:  48 6e ff e6          pea.l    -$1a(a6)
  000ba2:  61 ff 00 00 11 34    bsr.l    $1cd8  ; -> sub_1cd8
  000ba8:  4a 5f                tst.w    (a7)+
  000baa:  67 1e                beq.b    $bca  ; -> Lbca
  000bac:  70 10                moveq    #$10, d0
  000bae:  2f 00                move.l   d0, -(a7)
  000bb0:  61 ff 00 00 01 16    bsr.l    $cc8  ; -> sub_cc8
  000bb6:  58 4f                addq.w   #$4, a7
  000bb8:  60 00 00 8a          bra.w    $c44  ; -> Lc44
Lbbc:
  000bbc:  70 06                moveq    #$6, d0
  000bbe:  2f 00                move.l   d0, -(a7)
  000bc0:  61 ff 00 00 01 06    bsr.l    $cc8  ; -> sub_cc8
  000bc6:  58 4f                addq.w   #$4, a7
  000bc8:  60 7a                bra.b    $c44  ; -> Lc44
Lbca:
  000bca:  55 8f                subq.l   #$2, a7
  000bcc:  3f 07                move.w   d7, -(a7)
  000bce:  70 05                moveq    #$5, d0
  000bd0:  3f 00                move.w   d0, -(a7)
  000bd2:  48 6e ff e6          pea.l    -$1a(a6)
  000bd6:  61 ff 00 00 11 00    bsr.l    $1cd8  ; -> sub_1cd8
  000bdc:  4a 5f                tst.w    (a7)+
  000bde:  67 36                beq.b    $c16  ; -> Lc16
  000be0:  70 15                moveq    #$15, d0
  000be2:  2f 00                move.l   d0, -(a7)
  000be4:  61 ff 00 00 00 e2    bsr.l    $cc8  ; -> sub_cc8
  000bea:  58 4f                addq.w   #$4, a7
  000bec:  60 56                bra.b    $c44  ; -> Lc44
Lbee:
  000bee:  3d 46 ff e6          move.w   d6, -$1a(a6)
  000bf2:  55 8f                subq.l   #$2, a7
  000bf4:  3f 07                move.w   d7, -(a7)
  000bf6:  70 30                moveq    #$30, d0
  000bf8:  3f 00                move.w   d0, -(a7)
  000bfa:  48 6e ff e6          pea.l    -$1a(a6)
  000bfe:  61 ff 00 00 10 d8    bsr.l    $1cd8  ; -> sub_1cd8
  000c04:  4a 5f                tst.w    (a7)+
  000c06:  67 0e                beq.b    $c16  ; -> Lc16
  000c08:  70 16                moveq    #$16, d0
  000c0a:  2f 00                move.l   d0, -(a7)
  000c0c:  61 ff 00 00 00 ba    bsr.l    $cc8  ; -> sub_cc8
  000c12:  58 4f                addq.w   #$4, a7
  000c14:  60 2e                bra.b    $c44  ; -> Lc44
Lc16:
  000c16:  78 00                moveq    #$0, d4
  000c18:  3d 46 ff e6          move.w   d6, -$1a(a6)
  000c1c:  70 20                moveq    #$20, d0
  000c1e:  c0 85                and.l    d5, d0
  000c20:  67 22                beq.b    $c44  ; -> Lc44
  000c22:  55 8f                subq.l   #$2, a7
  000c24:  3f 07                move.w   d7, -(a7)
  000c26:  70 0d                moveq    #$d, d0
  000c28:  3f 00                move.w   d0, -(a7)
  000c2a:  48 6e ff e6          pea.l    -$1a(a6)
  000c2e:  61 ff 00 00 10 a8    bsr.l    $1cd8  ; -> sub_1cd8
  000c34:  4a 5f                tst.w    (a7)+
  000c36:  67 0c                beq.b    $c44  ; -> Lc44
  000c38:  70 18                moveq    #$18, d0
  000c3a:  2f 00                move.l   d0, -(a7)
  000c3c:  61 ff 00 00 00 8a    bsr.l    $cc8  ; -> sub_cc8
  000c42:  58 4f                addq.w   #$4, a7
Lc44:
  000c44:  20 04                move.l   d4, d0
  000c46:  4c ee 10 f0 ff d2    movem.l  -$2e(a6), d4-d7/a4
  000c4c:  4e 5e                unlk     a6
  000c4e:  4e 75                rts      
sub_c50:
  000c50:  4e 56 ff ea          link.w   a6, #$ffea
  000c54:  2f 0c                move.l   a4, -(a7)
  000c56:  28 6e 00 08          movea.l  $8(a6), a4
  000c5a:  42 6e ff ea          clr.w    -$16(a6)
  000c5e:  70 ff                moveq    #$ff, d0
  000c60:  2d 40 ff ec          move.l   d0, -$14(a6)
  000c64:  55 8f                subq.l   #$2, a7
  000c66:  20 54                movea.l  (a4), a0
  000c68:  3f 10                move.w   (a0), -(a7)
  000c6a:  70 04                moveq    #$4, d0
  000c6c:  3f 00                move.w   d0, -(a7)
  000c6e:  48 6e ff ea          pea.l    -$16(a6)
  000c72:  61 ff 00 00 10 64    bsr.l    $1cd8  ; -> sub_1cd8
  000c78:  4a 5f                tst.w    (a7)+
  000c7a:  67 14                beq.b    $c90  ; -> Lc90
  000c7c:  70 17                moveq    #$17, d0
  000c7e:  2f 00                move.l   d0, -(a7)
  000c80:  61 ff 00 00 00 46    bsr.l    $cc8  ; -> sub_cc8
  000c86:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  000c8c:  58 4f                addq.w   #$4, a7
  000c8e:  60 30                bra.b    $cc0  ; -> Lcc0
Lc90:
  000c90:  55 8f                subq.l   #$2, a7
  000c92:  20 54                movea.l  (a4), a0
  000c94:  3f 10                move.w   (a0), -(a7)
  000c96:  70 0a                moveq    #$a, d0
  000c98:  3f 00                move.w   d0, -(a7)
  000c9a:  48 6e ff ea          pea.l    -$16(a6)
  000c9e:  61 ff 00 00 10 6e    bsr.l    $1d0e  ; -> sub_1d0e
  000ca4:  4a 5f                tst.w    (a7)+
  000ca6:  67 14                beq.b    $cbc  ; -> Lcbc
  000ca8:  70 07                moveq    #$7, d0
  000caa:  2f 00                move.l   d0, -(a7)
  000cac:  61 ff 00 00 00 1a    bsr.l    $cc8  ; -> sub_cc8
  000cb2:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  000cb8:  58 4f                addq.w   #$4, a7
  000cba:  60 04                bra.b    $cc0  ; -> Lcc0
Lcbc:
  000cbc:  20 2e ff ec          move.l   -$14(a6), d0
Lcc0:
  000cc0:  28 6e ff e6          movea.l  -$1a(a6), a4
  000cc4:  4e 5e                unlk     a6
  000cc6:  4e 75                rts      
sub_cc8:
  000cc8:  4e 56 00 00          link.w   a6, #$0
  000ccc:  2f 0c                move.l   a4, -(a7)
  000cce:  59 8f                subq.l   #$4, a7
  000cd0:  2f 3c 53 54 52 20    move.l   #$53545220, -(a7)  ; 'STR '
  000cd6:  3f 3c f0 31          move.w   #$f031, -(a7)
  000cda:  a8 1f                dc.w     $a81f  ; _Get1Resource
  000cdc:  28 57                movea.l  (a7), a4
  000cde:  a9 a2                dc.w     $a9a2  ; _LoadResource
  000ce0:  20 4c                movea.l  a4, a0
  000ce2:  a0 29                dc.w     $a029  ; _HLock
  000ce4:  2f 14                move.l   (a4), -(a7)
  000ce6:  2f 2e 00 08          move.l   $8(a6), -(a7)
  000cea:  61 ff 00 00 0f 62    bsr.l    $1c4e  ; -> sub_1c4e
  000cf0:  2f 0c                move.l   a4, -(a7)
  000cf2:  a9 aa                dc.w     $a9aa  ; _ChangedResource
  000cf4:  2f 0c                move.l   a4, -(a7)
  000cf6:  a9 b0                dc.w     $a9b0  ; _WriteResource
  000cf8:  70 00                moveq    #$0, d0
  000cfa:  2f 00                move.l   d0, -(a7)
  000cfc:  2f 14                move.l   (a4), -(a7)
  000cfe:  2f 00                move.l   d0, -(a7)
  000d00:  2f 00                move.l   d0, -(a7)
  000d02:  61 ff 00 00 10 ce    bsr.l    $1dd2  ; -> sub_1dd2
  000d08:  55 8f                subq.l   #$2, a7
  000d0a:  3f 3c f0 38          move.w   #$f038, -(a7)
  000d0e:  70 00                moveq    #$0, d0
  000d10:  2f 00                move.l   d0, -(a7)
  000d12:  a9 85                dc.w     $a985  ; _Alert
  000d14:  70 00                moveq    #$0, d0
  000d16:  2f 00                move.l   d0, -(a7)
  000d18:  2f 00                move.l   d0, -(a7)
  000d1a:  2f 00                move.l   d0, -(a7)
  000d1c:  2f 00                move.l   d0, -(a7)
  000d1e:  61 ff 00 00 10 b2    bsr.l    $1dd2  ; -> sub_1dd2
  000d24:  2f 0c                move.l   a4, -(a7)
  000d26:  a9 a3                dc.w     $a9a3  ; _ReleaseResource
  000d28:  28 6e ff fc          movea.l  -$4(a6), a4
  000d2c:  4e 5e                unlk     a6
  000d2e:  4e 75                rts      
sub_d30:
  000d30:  4e 56 00 00          link.w   a6, #$0
  000d34:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  000d38:  20 6e 00 08          movea.l  $8(a6), a0
  000d3c:  20 50                movea.l  (a0), a0
  000d3e:  3e 10                move.w   (a0), d7
  000d40:  7e 00                moveq    #$0, d7
  000d42:  59 8f                subq.l   #$4, a7
  000d44:  2f 3c 50 75 70 53    move.l   #$50757053, -(a7)  ; 'PupS'
  000d4a:  3f 07                move.w   d7, -(a7)
  000d4c:  a8 1f                dc.w     $a81f  ; _Get1Resource
  000d4e:  28 5f                movea.l  (a7)+, a4
  000d50:  20 0c                move.l   a4, d0
  000d52:  67 08                beq.b    $d5c  ; -> Ld5c
  000d54:  55 8f                subq.l   #$2, a7
  000d56:  a9 af                dc.w     $a9af  ; _ResError
  000d58:  4a 5f                tst.w    (a7)+
  000d5a:  67 14                beq.b    $d70  ; -> Ld70
Ld5c:
  000d5c:  70 03                moveq    #$3, d0
  000d5e:  2f 00                move.l   d0, -(a7)
  000d60:  61 ff ff ff ff 66    bsr.l    $cc8  ; -> sub_cc8
  000d66:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  000d6c:  58 4f                addq.w   #$4, a7
  000d6e:  60 18                bra.b    $d88  ; -> Ld88
Ld70:
  000d70:  2f 0c                move.l   a4, -(a7)
  000d72:  a9 a2                dc.w     $a9a2  ; _LoadResource
  000d74:  26 54                movea.l  (a4), a3
  000d76:  26 ae 00 0c          move.l   $c(a6), (a3)
  000d7a:  2f 0c                move.l   a4, -(a7)
  000d7c:  a9 aa                dc.w     $a9aa  ; _ChangedResource
  000d7e:  2f 0c                move.l   a4, -(a7)
  000d80:  a9 b0                dc.w     $a9b0  ; _WriteResource
  000d82:  2f 0c                move.l   a4, -(a7)
  000d84:  a9 a3                dc.w     $a9a3  ; _ReleaseResource
  000d86:  70 00                moveq    #$0, d0
Ld88:
  000d88:  4c ee 18 80 ff f4    movem.l  -$c(a6), d7/a3-a4
  000d8e:  4e 5e                unlk     a6
  000d90:  4e 75                rts      
sub_d92:
  000d92:  4e 56 ff da          link.w   a6, #$ffda
  000d96:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  000d9a:  28 6e 00 08          movea.l  $8(a6), a4
  000d9e:  20 54                movea.l  (a4), a0
  000da0:  3e 10                move.w   (a0), d7
  000da2:  7e 00                moveq    #$0, d7
  000da4:  59 8f                subq.l   #$4, a7
  000da6:  2f 3c 50 75 70 53    move.l   #$50757053, -(a7)  ; 'PupS'
  000dac:  3f 07                move.w   d7, -(a7)
  000dae:  a8 1f                dc.w     $a81f  ; _Get1Resource
  000db0:  26 5f                movea.l  (a7)+, a3
  000db2:  20 0b                move.l   a3, d0
  000db4:  67 08                beq.b    $dbe  ; -> Ldbe
  000db6:  55 8f                subq.l   #$2, a7
  000db8:  a9 af                dc.w     $a9af  ; _ResError
  000dba:  4a 5f                tst.w    (a7)+
  000dbc:  67 14                beq.b    $dd2  ; -> Ldd2
Ldbe:
  000dbe:  70 03                moveq    #$3, d0
  000dc0:  2f 00                move.l   d0, -(a7)
  000dc2:  61 ff ff ff ff 04    bsr.l    $cc8  ; -> sub_cc8
  000dc8:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  000dce:  58 4f                addq.w   #$4, a7
  000dd0:  60 60                bra.b    $e32  ; -> Le32
Ldd2:
  000dd2:  2f 0b                move.l   a3, -(a7)
  000dd4:  a9 a2                dc.w     $a9a2  ; _LoadResource
  000dd6:  20 53                movea.l  (a3), a0
  000dd8:  43 ee ff f0          lea.l    -$10(a6), a1
  000ddc:  22 d8                move.l   (a0)+, (a1)+
  000dde:  22 d8                move.l   (a0)+, (a1)+
  000de0:  22 d8                move.l   (a0)+, (a1)+
  000de2:  22 d8                move.l   (a0)+, (a1)+
  000de4:  2f 0b                move.l   a3, -(a7)
  000de6:  a9 a3                dc.w     $a9a3  ; _ReleaseResource
  000de8:  20 54                movea.l  (a4), a0
  000dea:  21 6e ff f8 00 04    move.l   -$8(a6), $4(a0)
  000df0:  3d 47 ff da          move.w   d7, -$26(a6)
  000df4:  20 54                movea.l  (a4), a0
  000df6:  2d 68 00 04 ff dc    move.l   $4(a0), -$24(a6)
  000dfc:  55 8f                subq.l   #$2, a7
  000dfe:  20 54                movea.l  (a4), a0
  000e00:  3f 10                move.w   (a0), -(a7)
  000e02:  70 11                moveq    #$11, d0
  000e04:  3f 00                move.w   d0, -(a7)
  000e06:  48 6e ff da          pea.l    -$26(a6)
  000e0a:  61 ff 00 00 0e cc    bsr.l    $1cd8  ; -> sub_1cd8
  000e10:  4a 5f                tst.w    (a7)+
  000e12:  67 0e                beq.b    $e22  ; -> Le22
  000e14:  70 0e                moveq    #$e, d0
  000e16:  2f 00                move.l   d0, -(a7)
  000e18:  61 ff ff ff fe ae    bsr.l    $cc8  ; -> sub_cc8
  000e1e:  58 4f                addq.w   #$4, a7
  000e20:  60 10                bra.b    $e32  ; -> Le32
Le22:
  000e22:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  000e26:  2f 0c                move.l   a4, -(a7)
  000e28:  61 ff ff ff fa a0    bsr.l    $8ca  ; -> sub_8ca
  000e2e:  70 00                moveq    #$0, d0
  000e30:  50 4f                addq.w   #$8, a7
Le32:
  000e32:  4c ee 18 80 ff ce    movem.l  -$32(a6), d7/a3-a4
  000e38:  4e 5e                unlk     a6
  000e3a:  4e 75                rts      
sub_e3c:
  000e3c:  4e 56 00 00          link.w   a6, #$0
  000e40:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  000e44:  26 6e 00 10          movea.l  $10(a6), a3
  000e48:  28 6e 00 0c          movea.l  $c(a6), a4
  000e4c:  2e 2e 00 08          move.l   $8(a6), d7
  000e50:  4a 2e 00 1b          tst.b    $1b(a6)
  000e54:  67 10                beq.b    $e66  ; -> Le66
  000e56:  2f 0b                move.l   a3, -(a7)
  000e58:  2f 0c                move.l   a4, -(a7)
  000e5a:  2f 07                move.l   d7, -(a7)
  000e5c:  61 ff 00 00 01 60    bsr.l    $fbe  ; -> sub_fbe
  000e62:  4f ef 00 0c          lea.l    $c(a7), a7
Le66:
  000e66:  2f 2e 00 14          move.l   $14(a6), -(a7)
  000e6a:  2f 07                move.l   d7, -(a7)
  000e6c:  2f 0c                move.l   a4, -(a7)
  000e6e:  61 ff 00 00 00 1a    bsr.l    $e8a  ; -> sub_e8a
  000e74:  20 53                movea.l  (a3), a0
  000e76:  11 7c 00 01 00 0d    move.b   #$1, $d(a0)
  000e7c:  4f ef 00 0c          lea.l    $c(a7), a7
  000e80:  4c ee 18 80 ff f4    movem.l  -$c(a6), d7/a3-a4
  000e86:  4e 5e                unlk     a6
  000e88:  4e 75                rts      
sub_e8a:
  000e8a:  4e 56 fe d6          link.w   a6, #$fed6
  000e8e:  48 e7 07 18          movem.l  d5-d7/a3-a4, -(a7)
  000e92:  2a 2e 00 10          move.l   $10(a6), d5
  000e96:  49 ee fe fc          lea.l    -$104(a6), a4
  000e9a:  2e 3c ff ff f0 3f    move.l   #$fffff03f, d7
  000ea0:  59 8f                subq.l   #$4, a7
  000ea2:  59 8f                subq.l   #$4, a7
  000ea4:  70 12                moveq    #$12, d0
  000ea6:  3f 00                move.w   d0, -(a7)
  000ea8:  2f 3c 84 02 00 08    move.l   #$84020008, -(a7)
  000eae:  a8 b5                dc.w     $a8b5  ; _ScriptUtil
  000eb0:  20 1f                move.l   (a7)+, d0
  000eb2:  3f 00                move.w   d0, -(a7)
  000eb4:  70 1c                moveq    #$1c, d0
  000eb6:  3f 00                move.w   d0, -(a7)
  000eb8:  2f 3c 84 04 00 0c    move.l   #$8404000c, -(a7)
  000ebe:  a8 b5                dc.w     $a8b5  ; _ScriptUtil
  000ec0:  2c 1f                move.l   (a7)+, d6
  000ec2:  2e 06                move.l   d6, d7
  000ec4:  de bc 00 00 03 e8    add.l    #$3e8, d7
  000eca:  59 8f                subq.l   #$4, a7
  000ecc:  2f 3c 53 54 52 23    move.l   #$53545223, -(a7)  ; 'STR#'
  000ed2:  3f 07                move.w   d7, -(a7)
  000ed4:  a8 1f                dc.w     $a81f  ; _Get1Resource
  000ed6:  2d 5f fe f8          move.l   (a7)+, -$108(a6)
  000eda:  66 02                bne.b    $ede  ; -> Lede
  000edc:  7e 00                moveq    #$0, d7
Lede:
  000ede:  59 8f                subq.l   #$4, a7
  000ee0:  2f 3c 53 54 52 23    move.l   #$53545223, -(a7)  ; 'STR#'
  000ee6:  3f 07                move.w   d7, -(a7)
  000ee8:  a8 1f                dc.w     $a81f  ; _Get1Resource
  000eea:  2d 5f fe f8          move.l   (a7)+, -$108(a6)
  000eee:  67 00 00 c4          beq.w    $fb4  ; -> Lfb4
  000ef2:  2f 2e fe f8          move.l   -$108(a6), -(a7)
  000ef6:  a9 a2                dc.w     $a9a2  ; _LoadResource
  000ef8:  2c 3c ff ff d8 f1    move.l   #$ffffd8f1, d6
  000efe:  9c 85                sub.l    d5, d6
  000f00:  20 6e fe f8          movea.l  -$108(a6), a0
  000f04:  26 50                movea.l  (a0), a3
  000f06:  30 13                move.w   (a3), d0
  000f08:  48 c0                ext.l    d0
  000f0a:  b0 86                cmp.l    d6, d0
  000f0c:  6d 06                blt.b    $f14  ; -> Lf14
  000f0e:  70 01                moveq    #$1, d0
  000f10:  b0 86                cmp.l    d6, d0
  000f12:  6f 02                ble.b    $f16  ; -> Lf16
Lf14:
  000f14:  7c 01                moveq    #$1, d6
Lf16:
  000f16:  59 8f                subq.l   #$4, a7
  000f18:  2f 3c 53 54 52 20    move.l   #$53545220, -(a7)  ; 'STR '
  000f1e:  3f 3c f0 30          move.w   #$f030, -(a7)
  000f22:  a8 1f                dc.w     $a81f  ; _Get1Resource
  000f24:  26 5f                movea.l  (a7)+, a3
  000f26:  20 0b                move.l   a3, d0
  000f28:  67 1a                beq.b    $f44  ; -> Lf44
  000f2a:  2f 0b                move.l   a3, -(a7)
  000f2c:  a9 a2                dc.w     $a9a2  ; _LoadResource
  000f2e:  20 4b                movea.l  a3, a0
  000f30:  a0 29                dc.w     $a029  ; _HLock
  000f32:  2d 53 ff fc          move.l   (a3), -$4(a6)
  000f36:  70 00                moveq    #$0, d0
  000f38:  2f 00                move.l   d0, -(a7)
  000f3a:  2f 00                move.l   d0, -(a7)
  000f3c:  2f 00                move.l   d0, -(a7)
  000f3e:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  000f42:  a9 8b                dc.w     $a98b  ; _ParamText
Lf44:
  000f44:  2f 2e fe f8          move.l   -$108(a6), -(a7)
  000f48:  a9 a3                dc.w     $a9a3  ; _ReleaseResource
  000f4a:  2f 0b                move.l   a3, -(a7)
  000f4c:  a9 a3                dc.w     $a9a3  ; _ReleaseResource
  000f4e:  2f 0c                move.l   a4, -(a7)
  000f50:  3f 07                move.w   d7, -(a7)
  000f52:  3f 06                move.w   d6, -(a7)
  000f54:  61 ff 00 00 0d e4    bsr.l    $1d3a  ; -> sub_1d3a
  000f5a:  2f 2e 00 08          move.l   $8(a6), -(a7)
  000f5e:  30 2e 00 0e          move.w   $e(a6), d0
  000f62:  56 40                addq.w   #$3, d0
  000f64:  3f 00                move.w   d0, -(a7)
  000f66:  48 6e fe f6          pea.l    -$10a(a6)
  000f6a:  48 6e fe ea          pea.l    -$116(a6)
  000f6e:  48 6e fe ee          pea.l    -$112(a6)
  000f72:  a9 8d                dc.w     $a98d  ; _GetDItem
  000f74:  70 01                moveq    #$1, d0
  000f76:  b0 86                cmp.l    d6, d0
  000f78:  66 32                bne.b    $fac  ; -> Lfac
  000f7a:  48 6e fe d6          pea.l    -$12a(a6)
  000f7e:  2f 05                move.l   d5, -(a7)
  000f80:  61 ff 00 00 0c cc    bsr.l    $1c4e  ; -> sub_1c4e
  000f86:  2f 0c                move.l   a4, -(a7)
  000f88:  61 ff 00 00 0c de    bsr.l    $1c68  ; -> sub_1c68
  000f8e:  48 6e fe d6          pea.l    -$12a(a6)
  000f92:  2f 0c                move.l   a4, -(a7)
  000f94:  61 ff 00 00 0c 90    bsr.l    $1c26  ; -> sub_1c26
  000f9a:  2f 0c                move.l   a4, -(a7)
  000f9c:  2f 2e fe ea          move.l   -$116(a6), -(a7)
  000fa0:  61 ff 00 00 0e 7c    bsr.l    $1e1e  ; -> sub_1e1e
  000fa6:  4f ef 00 1c          lea.l    $1c(a7), a7
  000faa:  60 08                bra.b    $fb4  ; -> Lfb4
Lfac:
  000fac:  2f 2e fe ea          move.l   -$116(a6), -(a7)
  000fb0:  2f 0c                move.l   a4, -(a7)
  000fb2:  a9 8f                dc.w     $a98f  ; _SetIText
Lfb4:
  000fb4:  4c ee 18 e0 fe c2    movem.l  -$13e(a6), d5-d7/a3-a4
  000fba:  4e 5e                unlk     a6
  000fbc:  4e 75                rts      
sub_fbe:
  000fbe:  4e 56 ff 98          link.w   a6, #$ff98
  000fc2:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  000fc6:  28 6e 00 10          movea.l  $10(a6), a4
  000fca:  20 54                movea.l  (a4), a0
  000fcc:  3e 10                move.w   (a0), d7
  000fce:  42 2e ff ae          clr.b    -$52(a6)
  000fd2:  42 46                clr.w    d6
  000fd4:  7a 00                moveq    #$0, d5
  000fd6:  59 8f                subq.l   #$4, a7
  000fd8:  2f 3c 44 61 74 65    move.l   #$44617465, -(a7)  ; 'Date'
  000fde:  3f 3c f0 30          move.w   #$f030, -(a7)
  000fe2:  a8 1f                dc.w     $a81f  ; _Get1Resource
  000fe4:  2d 5f ff fc          move.l   (a7)+, -$4(a6)
  000fe8:  67 14                beq.b    $ffe  ; -> Lffe
  000fea:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  000fee:  a9 a2                dc.w     $a9a2  ; _LoadResource
  000ff0:  20 6e ff fc          movea.l  -$4(a6), a0
  000ff4:  20 50                movea.l  (a0), a0
  000ff6:  2a 10                move.l   (a0), d5
  000ff8:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  000ffc:  a9 a3                dc.w     $a9a3  ; _ReleaseResource
Lffe:
  000ffe:  59 8f                subq.l   #$4, a7
  001000:  2f 3c 76 65 72 73    move.l   #$76657273, -(a7)  ; 'vers'
  001006:  70 01                moveq    #$1, d0
  001008:  3f 00                move.w   d0, -(a7)
  00100a:  a8 1f                dc.w     $a81f  ; _Get1Resource
  00100c:  2d 5f ff fc          move.l   (a7)+, -$4(a6)
  001010:  67 00 00 b0          beq.w    $10c2  ; -> L10c2
  001014:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  001018:  a9 a2                dc.w     $a9a2  ; _LoadResource
  00101a:  20 6e ff fc          movea.l  -$4(a6), a0
  00101e:  26 50                movea.l  (a0), a3
  001020:  10 2b 00 02          move.b   $2(a3), d0
  001024:  04 00 00 20          subi.b   #$20, d0
  001028:  67 14                beq.b    $103e  ; -> L103e
  00102a:  04 00 00 20          subi.b   #$20, d0
  00102e:  67 16                beq.b    $1046  ; -> L1046
  001030:  04 00 00 20          subi.b   #$20, d0
  001034:  67 18                beq.b    $104e  ; -> L104e
  001036:  04 00 00 20          subi.b   #$20, d0
  00103a:  67 1a                beq.b    $1056  ; -> L1056
  00103c:  60 1c                bra.b    $105a  ; -> L105a
L103e:
  00103e:  17 7c 00 0d 00 02    move.b   #$d, $2(a3)
  001044:  60 14                bra.b    $105a  ; -> L105a
L1046:
  001046:  17 7c 00 0a 00 02    move.b   #$a, $2(a3)
  00104c:  60 0c                bra.b    $105a  ; -> L105a
L104e:
  00104e:  17 7c 00 0b 00 02    move.b   #$b, $2(a3)
  001054:  60 04                bra.b    $105a  ; -> L105a
L1056:
  001056:  42 2b 00 02          clr.b    $2(a3)
L105a:
  00105a:  70 00                moveq    #$0, d0
  00105c:  10 13                move.b   (a3), d0
  00105e:  72 14                moveq    #$14, d1
  001060:  e3 a8                lsl.l    d1, d0
  001062:  72 00                moveq    #$0, d1
  001064:  12 2b 00 01          move.b   $1(a3), d1
  001068:  74 0c                moveq    #$c, d2
  00106a:  e5 a9                lsl.l    d2, d1
  00106c:  82 80                or.l     d0, d1
  00106e:  70 00                moveq    #$0, d0
  001070:  10 2b 00 02          move.b   $2(a3), d0
  001074:  e1 88                lsl.l    #$8, d0
  001076:  80 81                or.l     d1, d0
  001078:  72 00                moveq    #$0, d1
  00107a:  12 2b 00 03          move.b   $3(a3), d1
  00107e:  28 01                move.l   d1, d4
  001080:  88 80                or.l     d0, d4
  001082:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  001086:  a9 a3                dc.w     $a9a3  ; _ReleaseResource
  001088:  2f 05                move.l   d5, -(a7)
  00108a:  2f 04                move.l   d4, -(a7)
  00108c:  48 6e ff ae          pea.l    -$52(a6)
  001090:  61 ff 00 00 04 de    bsr.l    $1570  ; -> sub_1570
  001096:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00109a:  30 2e 00 0a          move.w   $a(a6), d0
  00109e:  58 40                addq.w   #$4, d0
  0010a0:  3f 00                move.w   d0, -(a7)
  0010a2:  48 6e ff ee          pea.l    -$12(a6)
  0010a6:  48 6e ff f0          pea.l    -$10(a6)
  0010aa:  48 6e ff f4          pea.l    -$c(a6)
  0010ae:  a9 8d                dc.w     $a98d  ; _GetDItem
  0010b0:  48 6e ff ae          pea.l    -$52(a6)
  0010b4:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  0010b8:  61 ff 00 00 0d 64    bsr.l    $1e1e  ; -> sub_1e1e
  0010be:  4f ef 00 14          lea.l    $14(a7), a7
L10c2:
  0010c2:  20 54                movea.l  (a4), a0
  0010c4:  4a 28 00 0c          tst.b    $c(a0)
  0010c8:  67 0a                beq.b    $10d4  ; -> L10d4
  0010ca:  20 3c ff ff d8 e6    move.l   #$ffffd8e6, d0
  0010d0:  60 00 04 24          bra.w    $14f6  ; -> L14f6
L10d4:
  0010d4:  59 8f                subq.l   #$4, a7
  0010d6:  2f 3c 50 75 70 53    move.l   #$50757053, -(a7)  ; 'PupS'
  0010dc:  3f 06                move.w   d6, -(a7)
  0010de:  a8 1f                dc.w     $a81f  ; _Get1Resource
  0010e0:  2d 5f ff fc          move.l   (a7)+, -$4(a6)
  0010e4:  66 32                bne.b    $1118  ; -> L1118
  0010e6:  20 54                movea.l  (a4), a0
  0010e8:  11 7c 00 01 00 0c    move.b   #$1, $c(a0)
  0010ee:  3d 46 ff 98          move.w   d6, -$68(a6)
  0010f2:  2d 7c ff ff d8 11 ff 9a move.l   #$ffffd811, -$66(a6)
  0010fa:  55 8f                subq.l   #$2, a7
  0010fc:  3f 07                move.w   d7, -(a7)
  0010fe:  70 14                moveq    #$14, d0
  001100:  3f 00                move.w   d0, -(a7)
  001102:  48 6e ff 98          pea.l    -$68(a6)
  001106:  61 ff 00 00 0b d0    bsr.l    $1cd8  ; -> sub_1cd8
  00110c:  20 3c ff ff d8 11    move.l   #$ffffd811, d0
  001112:  54 4f                addq.w   #$2, a7
  001114:  60 00 03 e0          bra.w    $14f6  ; -> L14f6
L1118:
  001118:  3d 46 ff 98          move.w   d6, -$68(a6)
  00111c:  55 8f                subq.l   #$2, a7
  00111e:  3f 07                move.w   d7, -(a7)
  001120:  70 63                moveq    #$63, d0
  001122:  3f 00                move.w   d0, -(a7)
  001124:  48 6e ff 98          pea.l    -$68(a6)
  001128:  61 ff 00 00 0b ae    bsr.l    $1cd8  ; -> sub_1cd8
  00112e:  4a 5f                tst.w    (a7)+
  001130:  67 0a                beq.b    $113c  ; -> L113c
  001132:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  001138:  60 00 03 bc          bra.w    $14f6  ; -> L14f6
L113c:
  00113c:  55 8f                subq.l   #$2, a7
  00113e:  3f 07                move.w   d7, -(a7)
  001140:  70 14                moveq    #$14, d0
  001142:  3f 00                move.w   d0, -(a7)
  001144:  48 6e ff 98          pea.l    -$68(a6)
  001148:  61 ff 00 00 0b c4    bsr.l    $1d0e  ; -> sub_1d0e
  00114e:  4a 5f                tst.w    (a7)+
  001150:  67 0a                beq.b    $115c  ; -> L115c
  001152:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  001158:  60 00 03 9c          bra.w    $14f6  ; -> L14f6
L115c:
  00115c:  4a ae ff 9a          tst.l    -$66(a6)
  001160:  67 38                beq.b    $119a  ; -> L119a
  001162:  ba ae ff 9a          cmp.l    -$66(a6), d5
  001166:  67 32                beq.b    $119a  ; -> L119a
  001168:  20 54                movea.l  (a4), a0
  00116a:  11 7c 00 01 00 0c    move.b   #$1, $c(a0)
  001170:  3d 46 ff 98          move.w   d6, -$68(a6)
  001174:  2d 7c ff ff d8 11 ff 9a move.l   #$ffffd811, -$66(a6)
  00117c:  55 8f                subq.l   #$2, a7
  00117e:  3f 07                move.w   d7, -(a7)
  001180:  70 14                moveq    #$14, d0
  001182:  3f 00                move.w   d0, -(a7)
  001184:  48 6e ff 98          pea.l    -$68(a6)
  001188:  61 ff 00 00 0b 4e    bsr.l    $1cd8  ; -> sub_1cd8
  00118e:  20 3c ff ff d8 e6    move.l   #$ffffd8e6, d0
  001194:  54 4f                addq.w   #$2, a7
  001196:  60 00 03 5e          bra.w    $14f6  ; -> L14f6
L119a:
  00119a:  3d 46 ff 98          move.w   d6, -$68(a6)
  00119e:  55 8f                subq.l   #$2, a7
  0011a0:  3f 07                move.w   d7, -(a7)
  0011a2:  70 63                moveq    #$63, d0
  0011a4:  3f 00                move.w   d0, -(a7)
  0011a6:  48 6e ff 98          pea.l    -$68(a6)
  0011aa:  61 ff 00 00 0b 2c    bsr.l    $1cd8  ; -> sub_1cd8
  0011b0:  4a 5f                tst.w    (a7)+
  0011b2:  67 0a                beq.b    $11be  ; -> L11be
  0011b4:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  0011ba:  60 00 03 3a          bra.w    $14f6  ; -> L14f6
L11be:
  0011be:  55 8f                subq.l   #$2, a7
  0011c0:  3f 07                move.w   d7, -(a7)
  0011c2:  70 05                moveq    #$5, d0
  0011c4:  3f 00                move.w   d0, -(a7)
  0011c6:  48 6e ff 98          pea.l    -$68(a6)
  0011ca:  61 ff 00 00 0b 42    bsr.l    $1d0e  ; -> sub_1d0e
  0011d0:  4a 5f                tst.w    (a7)+
  0011d2:  67 0a                beq.b    $11de  ; -> L11de
  0011d4:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  0011da:  60 00 03 1a          bra.w    $14f6  ; -> L14f6
L11de:
  0011de:  20 3c 00 00 02 00    move.l   #$200, d0
  0011e4:  c0 ae ff 9a          and.l    -$66(a6), d0
  0011e8:  67 0a                beq.b    $11f4  ; -> L11f4
  0011ea:  20 3c ff ff d8 e9    move.l   #$ffffd8e9, d0
  0011f0:  60 00 03 04          bra.w    $14f6  ; -> L14f6
L11f4:
  0011f4:  3d 46 ff 98          move.w   d6, -$68(a6)
  0011f8:  55 8f                subq.l   #$2, a7
  0011fa:  3f 07                move.w   d7, -(a7)
  0011fc:  70 63                moveq    #$63, d0
  0011fe:  3f 00                move.w   d0, -(a7)
  001200:  48 6e ff 98          pea.l    -$68(a6)
  001204:  61 ff 00 00 0a d2    bsr.l    $1cd8  ; -> sub_1cd8
  00120a:  4a 5f                tst.w    (a7)+
  00120c:  67 0a                beq.b    $1218  ; -> L1218
  00120e:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  001214:  60 00 02 e0          bra.w    $14f6  ; -> L14f6
L1218:
  001218:  55 8f                subq.l   #$2, a7
  00121a:  3f 07                move.w   d7, -(a7)
  00121c:  70 0c                moveq    #$c, d0
  00121e:  3f 00                move.w   d0, -(a7)
  001220:  48 6e ff 98          pea.l    -$68(a6)
  001224:  61 ff 00 00 0a e8    bsr.l    $1d0e  ; -> sub_1d0e
  00122a:  4a 5f                tst.w    (a7)+
  00122c:  66 26                bne.b    $1254  ; -> L1254
  00122e:  4a ae ff 9a          tst.l    -$66(a6)
  001232:  6c 08                bge.b    $123c  ; -> L123c
  001234:  20 2e ff 9a          move.l   -$66(a6), d0
  001238:  60 00 02 bc          bra.w    $14f6  ; -> L14f6
L123c:
  00123c:  2f 2e ff 9a          move.l   -$66(a6), -(a7)
  001240:  2f 0c                move.l   a4, -(a7)
  001242:  2f 2e 00 08          move.l   $8(a6), -(a7)
  001246:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00124a:  61 ff 00 00 04 90    bsr.l    $16dc  ; -> sub_16dc
  001250:  4f ef 00 10          lea.l    $10(a7), a7
L1254:
  001254:  55 8f                subq.l   #$2, a7
  001256:  20 54                movea.l  (a4), a0
  001258:  3f 10                move.w   (a0), -(a7)
  00125a:  70 15                moveq    #$15, d0
  00125c:  3f 00                move.w   d0, -(a7)
  00125e:  48 6e ff 98          pea.l    -$68(a6)
  001262:  61 ff 00 00 0a aa    bsr.l    $1d0e  ; -> sub_1d0e
  001268:  4a 5f                tst.w    (a7)+
  00126a:  67 16                beq.b    $1282  ; -> L1282
  00126c:  70 08                moveq    #$8, d0
  00126e:  2f 00                move.l   d0, -(a7)
  001270:  61 ff ff ff fa 56    bsr.l    $cc8  ; -> sub_cc8
  001276:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  00127c:  58 4f                addq.w   #$4, a7
  00127e:  60 00 02 76          bra.w    $14f6  ; -> L14f6
L1282:
  001282:  55 8f                subq.l   #$2, a7
  001284:  3f 07                move.w   d7, -(a7)
  001286:  70 05                moveq    #$5, d0
  001288:  3f 00                move.w   d0, -(a7)
  00128a:  48 6e ff 98          pea.l    -$68(a6)
  00128e:  61 ff 00 00 0a 7e    bsr.l    $1d0e  ; -> sub_1d0e
  001294:  4a 5f                tst.w    (a7)+
  001296:  67 0a                beq.b    $12a2  ; -> L12a2
  001298:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  00129e:  60 00 02 56          bra.w    $14f6  ; -> L14f6
L12a2:
  0012a2:  4a ae ff 9a          tst.l    -$66(a6)
  0012a6:  6c 08                bge.b    $12b0  ; -> L12b0
  0012a8:  20 2e ff 9a          move.l   -$66(a6), d0
  0012ac:  60 00 02 48          bra.w    $14f6  ; -> L14f6
L12b0:
  0012b0:  70 06                moveq    #$6, d0
  0012b2:  c0 ae ff 9a          and.l    -$66(a6), d0
  0012b6:  72 06                moveq    #$6, d1
  0012b8:  b2 80                cmp.l    d0, d1
  0012ba:  67 00 00 c0          beq.w    $137c  ; -> L137c
  0012be:  70 01                moveq    #$1, d0
  0012c0:  2f 00                move.l   d0, -(a7)
  0012c2:  2f 0c                move.l   a4, -(a7)
  0012c4:  61 ff ff ff f7 c6    bsr.l    $a8c  ; -> sub_a8c
  0012ca:  55 8f                subq.l   #$2, a7
  0012cc:  3f 07                move.w   d7, -(a7)
  0012ce:  70 05                moveq    #$5, d0
  0012d0:  3f 00                move.w   d0, -(a7)
  0012d2:  48 6e ff 98          pea.l    -$68(a6)
  0012d6:  61 ff 00 00 0a 36    bsr.l    $1d0e  ; -> sub_1d0e
  0012dc:  4a 5f                tst.w    (a7)+
  0012de:  50 4f                addq.w   #$8, a7
  0012e0:  67 16                beq.b    $12f8  ; -> L12f8
  0012e2:  70 08                moveq    #$8, d0
  0012e4:  2f 00                move.l   d0, -(a7)
  0012e6:  61 ff ff ff f9 e0    bsr.l    $cc8  ; -> sub_cc8
  0012ec:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  0012f2:  58 4f                addq.w   #$4, a7
  0012f4:  60 00 02 00          bra.w    $14f6  ; -> L14f6
L12f8:
  0012f8:  2f 0c                move.l   a4, -(a7)
  0012fa:  61 ff ff ff f9 54    bsr.l    $c50  ; -> sub_c50
  001300:  72 01                moveq    #$1, d1
  001302:  b2 80                cmp.l    d0, d1
  001304:  58 4f                addq.w   #$4, a7
  001306:  67 74                beq.b    $137c  ; -> L137c
  001308:  70 01                moveq    #$1, d0
  00130a:  2f 00                move.l   d0, -(a7)
  00130c:  2f 0c                move.l   a4, -(a7)
  00130e:  61 ff ff ff f7 7c    bsr.l    $a8c  ; -> sub_a8c
  001314:  4a 80                tst.l    d0
  001316:  50 4f                addq.w   #$8, a7
  001318:  67 2a                beq.b    $1344  ; -> L1344
  00131a:  3d 46 ff 98          move.w   d6, -$68(a6)
  00131e:  2d 7c ff ff d8 10 ff 9a move.l   #$ffffd810, -$66(a6)
  001326:  55 8f                subq.l   #$2, a7
  001328:  3f 07                move.w   d7, -(a7)
  00132a:  70 14                moveq    #$14, d0
  00132c:  3f 00                move.w   d0, -(a7)
  00132e:  48 6e ff 98          pea.l    -$68(a6)
  001332:  61 ff 00 00 09 a4    bsr.l    $1cd8  ; -> sub_1cd8
  001338:  20 3c ff ff d8 ea    move.l   #$ffffd8ea, d0
  00133e:  54 4f                addq.w   #$2, a7
  001340:  60 00 01 b4          bra.w    $14f6  ; -> L14f6
L1344:
  001344:  2f 0c                move.l   a4, -(a7)
  001346:  61 ff ff ff f9 08    bsr.l    $c50  ; -> sub_c50
  00134c:  4a 80                tst.l    d0
  00134e:  58 4f                addq.w   #$4, a7
  001350:  67 2a                beq.b    $137c  ; -> L137c
  001352:  3d 46 ff 98          move.w   d6, -$68(a6)
  001356:  2d 7c ff ff d8 ea ff 9a move.l   #$ffffd8ea, -$66(a6)
  00135e:  55 8f                subq.l   #$2, a7
  001360:  3f 07                move.w   d7, -(a7)
  001362:  70 14                moveq    #$14, d0
  001364:  3f 00                move.w   d0, -(a7)
  001366:  48 6e ff 98          pea.l    -$68(a6)
  00136a:  61 ff 00 00 09 6c    bsr.l    $1cd8  ; -> sub_1cd8
  001370:  20 3c ff ff d8 ea    move.l   #$ffffd8ea, d0
  001376:  54 4f                addq.w   #$2, a7
  001378:  60 00 01 7c          bra.w    $14f6  ; -> L14f6
L137c:
  00137c:  20 3c 00 00 01 00    move.l   #$100, d0
  001382:  c0 ae ff 9a          and.l    -$66(a6), d0
  001386:  67 2a                beq.b    $13b2  ; -> L13b2
  001388:  3d 46 ff 98          move.w   d6, -$68(a6)
  00138c:  2d 7c ff ff d8 ea ff 9a move.l   #$ffffd8ea, -$66(a6)
  001394:  55 8f                subq.l   #$2, a7
  001396:  3f 07                move.w   d7, -(a7)
  001398:  70 14                moveq    #$14, d0
  00139a:  3f 00                move.w   d0, -(a7)
  00139c:  48 6e ff 98          pea.l    -$68(a6)
  0013a0:  61 ff 00 00 09 36    bsr.l    $1cd8  ; -> sub_1cd8
  0013a6:  20 3c ff ff d8 ea    move.l   #$ffffd8ea, d0
  0013ac:  54 4f                addq.w   #$2, a7
  0013ae:  60 00 01 46          bra.w    $14f6  ; -> L14f6
L13b2:
  0013b2:  55 8f                subq.l   #$2, a7
  0013b4:  3f 07                move.w   d7, -(a7)
  0013b6:  70 11                moveq    #$11, d0
  0013b8:  3f 00                move.w   d0, -(a7)
  0013ba:  48 6e ff 98          pea.l    -$68(a6)
  0013be:  61 ff 00 00 09 4e    bsr.l    $1d0e  ; -> sub_1d0e
  0013c4:  4a 5f                tst.w    (a7)+
  0013c6:  67 0a                beq.b    $13d2  ; -> L13d2
  0013c8:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  0013ce:  60 00 01 26          bra.w    $14f6  ; -> L14f6
L13d2:
  0013d2:  70 ff                moveq    #$ff, d0
  0013d4:  b0 ae ff 9a          cmp.l    -$66(a6), d0
  0013d8:  66 12                bne.b    $13ec  ; -> L13ec
  0013da:  20 54                movea.l  (a4), a0
  0013dc:  11 7c 00 01 00 0c    move.b   #$1, $c(a0)
  0013e2:  20 3c ff ff d8 e6    move.l   #$ffffd8e6, d0
  0013e8:  60 00 01 0c          bra.w    $14f6  ; -> L14f6
L13ec:
  0013ec:  4a ae ff 9e          tst.l    -$62(a6)
  0013f0:  67 3c                beq.b    $142e  ; -> L142e
  0013f2:  2f 2e ff 9a          move.l   -$66(a6), -(a7)
  0013f6:  2f 04                move.l   d4, -(a7)
  0013f8:  61 ff 00 00 01 06    bsr.l    $1500  ; -> sub_1500
  0013fe:  4a 80                tst.l    d0
  001400:  50 4f                addq.w   #$8, a7
  001402:  67 2a                beq.b    $142e  ; -> L142e
  001404:  3d 46 ff 98          move.w   d6, -$68(a6)
  001408:  2d 7c ff ff d8 dd ff 9a move.l   #$ffffd8dd, -$66(a6)
  001410:  55 8f                subq.l   #$2, a7
  001412:  3f 07                move.w   d7, -(a7)
  001414:  70 14                moveq    #$14, d0
  001416:  3f 00                move.w   d0, -(a7)
  001418:  48 6e ff 98          pea.l    -$68(a6)
  00141c:  61 ff 00 00 08 ba    bsr.l    $1cd8  ; -> sub_1cd8
  001422:  20 3c ff ff d8 dd    move.l   #$ffffd8dd, d0
  001428:  54 4f                addq.w   #$2, a7
  00142a:  60 00 00 ca          bra.w    $14f6  ; -> L14f6
L142e:
  00142e:  55 8f                subq.l   #$2, a7
  001430:  3f 07                move.w   d7, -(a7)
  001432:  70 12                moveq    #$12, d0
  001434:  3f 00                move.w   d0, -(a7)
  001436:  48 6e ff 98          pea.l    -$68(a6)
  00143a:  61 ff 00 00 08 d2    bsr.l    $1d0e  ; -> sub_1d0e
  001440:  4a 5f                tst.w    (a7)+
  001442:  67 0a                beq.b    $144e  ; -> L144e
  001444:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  00144a:  60 00 00 aa          bra.w    $14f6  ; -> L14f6
L144e:
  00144e:  70 ff                moveq    #$ff, d0
  001450:  b0 ae ff 9e          cmp.l    -$62(a6), d0
  001454:  66 12                bne.b    $1468  ; -> L1468
  001456:  20 54                movea.l  (a4), a0
  001458:  11 7c 00 01 00 0c    move.b   #$1, $c(a0)
  00145e:  20 3c ff ff d8 e6    move.l   #$ffffd8e6, d0
  001464:  60 00 00 90          bra.w    $14f6  ; -> L14f6
L1468:
  001468:  4a ae ff 9e          tst.l    -$62(a6)
  00146c:  67 3a                beq.b    $14a8  ; -> L14a8
  00146e:  2f 2e ff 9a          move.l   -$66(a6), -(a7)
  001472:  2f 04                move.l   d4, -(a7)
  001474:  61 ff 00 00 00 8a    bsr.l    $1500  ; -> sub_1500
  00147a:  4a 80                tst.l    d0
  00147c:  50 4f                addq.w   #$8, a7
  00147e:  67 28                beq.b    $14a8  ; -> L14a8
  001480:  3d 46 ff 98          move.w   d6, -$68(a6)
  001484:  2d 7c ff ff d8 de ff 9a move.l   #$ffffd8de, -$66(a6)
  00148c:  55 8f                subq.l   #$2, a7
  00148e:  3f 07                move.w   d7, -(a7)
  001490:  70 14                moveq    #$14, d0
  001492:  3f 00                move.w   d0, -(a7)
  001494:  48 6e ff 98          pea.l    -$68(a6)
  001498:  61 ff 00 00 08 3e    bsr.l    $1cd8  ; -> sub_1cd8
  00149e:  20 3c ff ff d8 de    move.l   #$ffffd8de, d0
  0014a4:  54 4f                addq.w   #$2, a7
  0014a6:  60 4e                bra.b    $14f6  ; -> L14f6
L14a8:
  0014a8:  55 8f                subq.l   #$2, a7
  0014aa:  3f 07                move.w   d7, -(a7)
  0014ac:  70 13                moveq    #$13, d0
  0014ae:  3f 00                move.w   d0, -(a7)
  0014b0:  48 6e ff 98          pea.l    -$68(a6)
  0014b4:  61 ff 00 00 08 58    bsr.l    $1d0e  ; -> sub_1d0e
  0014ba:  4a 5f                tst.w    (a7)+
  0014bc:  67 08                beq.b    $14c6  ; -> L14c6
  0014be:  20 3c ff ff d8 da    move.l   #$ffffd8da, d0
  0014c4:  60 30                bra.b    $14f6  ; -> L14f6
L14c6:
  0014c6:  4a ae ff 9e          tst.l    -$62(a6)
  0014ca:  66 28                bne.b    $14f4  ; -> L14f4
  0014cc:  3d 46 ff 98          move.w   d6, -$68(a6)
  0014d0:  2d 7c ff ff d8 df ff 9a move.l   #$ffffd8df, -$66(a6)
  0014d8:  55 8f                subq.l   #$2, a7
  0014da:  3f 07                move.w   d7, -(a7)
  0014dc:  70 14                moveq    #$14, d0
  0014de:  3f 00                move.w   d0, -(a7)
  0014e0:  48 6e ff 98          pea.l    -$68(a6)
  0014e4:  61 ff 00 00 07 f2    bsr.l    $1cd8  ; -> sub_1cd8
  0014ea:  20 3c ff ff d8 df    move.l   #$ffffd8df, d0
  0014f0:  54 4f                addq.w   #$2, a7
  0014f2:  60 02                bra.b    $14f6  ; -> L14f6
L14f4:
  0014f4:  70 00                moveq    #$0, d0
L14f6:
  0014f6:  4c ee 18 f0 ff 80    movem.l  -$80(a6), d4-d7/a3-a4
  0014fc:  4e 5e                unlk     a6
  0014fe:  4e 75                rts      
sub_1500:
  001500:  4e 56 00 00          link.w   a6, #$0
  001504:  48 e7 03 00          movem.l  d6-d7, -(a7)
  001508:  2c 2e 00 0c          move.l   $c(a6), d6
  00150c:  2e 2e 00 08          move.l   $8(a6), d7
  001510:  70 14                moveq    #$14, d0
  001512:  22 07                move.l   d7, d1
  001514:  e0 a9                lsr.l    d0, d1
  001516:  70 0f                moveq    #$f, d0
  001518:  c0 81                and.l    d1, d0
  00151a:  72 14                moveq    #$14, d1
  00151c:  24 06                move.l   d6, d2
  00151e:  e2 aa                lsr.l    d1, d2
  001520:  72 0f                moveq    #$f, d1
  001522:  c2 82                and.l    d2, d1
  001524:  b2 80                cmp.l    d0, d1
  001526:  6f 04                ble.b    $152c  ; -> L152c
  001528:  70 ff                moveq    #$ff, d0
  00152a:  60 3a                bra.b    $1566  ; -> L1566
L152c:
  00152c:  70 10                moveq    #$10, d0
  00152e:  22 07                move.l   d7, d1
  001530:  e0 a9                lsr.l    d0, d1
  001532:  70 0f                moveq    #$f, d0
  001534:  c0 81                and.l    d1, d0
  001536:  72 10                moveq    #$10, d1
  001538:  24 06                move.l   d6, d2
  00153a:  e2 aa                lsr.l    d1, d2
  00153c:  72 0f                moveq    #$f, d1
  00153e:  c2 82                and.l    d2, d1
  001540:  b2 80                cmp.l    d0, d1
  001542:  6f 04                ble.b    $1548  ; -> L1548
  001544:  70 fe                moveq    #$fe, d0
  001546:  60 1e                bra.b    $1566  ; -> L1566
L1548:
  001548:  70 0c                moveq    #$c, d0
  00154a:  22 07                move.l   d7, d1
  00154c:  e0 a9                lsr.l    d0, d1
  00154e:  70 0f                moveq    #$f, d0
  001550:  c0 81                and.l    d1, d0
  001552:  72 0c                moveq    #$c, d1
  001554:  24 06                move.l   d6, d2
  001556:  e2 aa                lsr.l    d1, d2
  001558:  72 0f                moveq    #$f, d1
  00155a:  c2 82                and.l    d2, d1
  00155c:  b2 80                cmp.l    d0, d1
  00155e:  6f 04                ble.b    $1564  ; -> L1564
  001560:  70 fd                moveq    #$fd, d0
  001562:  60 02                bra.b    $1566  ; -> L1566
L1564:
  001564:  70 00                moveq    #$0, d0
L1566:
  001566:  4c ee 00 c0 ff f8    movem.l  -$8(a6), d6-d7
  00156c:  4e 5e                unlk     a6
  00156e:  4e 75                rts      
sub_1570:
  001570:  4e 56 ff b8          link.w   a6, #$ffb8
  001574:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  001578:  2c 2e 00 0c          move.l   $c(a6), d6
  00157c:  26 6e 00 08          movea.l  $8(a6), a3
  001580:  49 ee ff b8          lea.l    -$48(a6), a4
  001584:  70 00                moveq    #$0, d0
  001586:  2d 40 ff fc          move.l   d0, -$4(a6)
  00158a:  42 13                clr.b    (a3)
  00158c:  59 8f                subq.l   #$4, a7
  00158e:  2f 3c 53 54 52 20    move.l   #$53545220, -(a7)  ; 'STR '
  001594:  3f 3c f0 30          move.w   #$f030, -(a7)
  001598:  a8 1f                dc.w     $a81f  ; _Get1Resource
  00159a:  2d 5f ff f8          move.l   (a7)+, -$8(a6)
  00159e:  67 2e                beq.b    $15ce  ; -> L15ce
  0015a0:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  0015a4:  a9 a2                dc.w     $a9a2  ; _LoadResource
  0015a6:  20 6e ff f8          movea.l  -$8(a6), a0
  0015aa:  2d 50 ff fc          move.l   (a0), -$4(a6)
  0015ae:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  0015b2:  61 ff 00 00 06 b4    bsr.l    $1c68  ; -> sub_1c68
  0015b8:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  0015bc:  2f 0b                move.l   a3, -(a7)
  0015be:  61 ff 00 00 06 66    bsr.l    $1c26  ; -> sub_1c26
  0015c4:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  0015c8:  a9 a3                dc.w     $a9a3  ; _ReleaseResource
  0015ca:  4f ef 00 0c          lea.l    $c(a7), a7
L15ce:
  0015ce:  48 7a 01 0a          pea.l    $16da(pc)
  0015d2:  2f 0b                move.l   a3, -(a7)
  0015d4:  61 ff 00 00 06 50    bsr.l    $1c26  ; -> sub_1c26
  0015da:  2f 0c                move.l   a4, -(a7)
  0015dc:  70 14                moveq    #$14, d0
  0015de:  22 06                move.l   d6, d1
  0015e0:  e0 a9                lsr.l    d0, d1
  0015e2:  70 0f                moveq    #$f, d0
  0015e4:  c0 81                and.l    d1, d0
  0015e6:  2f 00                move.l   d0, -(a7)
  0015e8:  61 ff 00 00 06 64    bsr.l    $1c4e  ; -> sub_1c4e
  0015ee:  2f 0c                move.l   a4, -(a7)
  0015f0:  2f 0b                move.l   a3, -(a7)
  0015f2:  61 ff 00 00 06 32    bsr.l    $1c26  ; -> sub_1c26
  0015f8:  48 7a 00 de          pea.l    $16d8(pc)
  0015fc:  2f 0b                move.l   a3, -(a7)
  0015fe:  61 ff 00 00 06 26    bsr.l    $1c26  ; -> sub_1c26
  001604:  2f 0c                move.l   a4, -(a7)
  001606:  70 10                moveq    #$10, d0
  001608:  22 06                move.l   d6, d1
  00160a:  e0 a9                lsr.l    d0, d1
  00160c:  70 0f                moveq    #$f, d0
  00160e:  c0 81                and.l    d1, d0
  001610:  2f 00                move.l   d0, -(a7)
  001612:  61 ff 00 00 06 3a    bsr.l    $1c4e  ; -> sub_1c4e
  001618:  2f 0c                move.l   a4, -(a7)
  00161a:  2f 0b                move.l   a3, -(a7)
  00161c:  61 ff 00 00 06 08    bsr.l    $1c26  ; -> sub_1c26
  001622:  70 0c                moveq    #$c, d0
  001624:  22 06                move.l   d6, d1
  001626:  e0 a9                lsr.l    d0, d1
  001628:  7e 0f                moveq    #$f, d7
  00162a:  ce 81                and.l    d1, d7
  00162c:  4a 87                tst.l    d7
  00162e:  4f ef 00 30          lea.l    $30(a7), a7
  001632:  67 24                beq.b    $1658  ; -> L1658
  001634:  48 7a 00 a2          pea.l    $16d8(pc)
  001638:  2f 0b                move.l   a3, -(a7)
  00163a:  61 ff 00 00 05 ea    bsr.l    $1c26  ; -> sub_1c26
  001640:  2f 0c                move.l   a4, -(a7)
  001642:  2f 07                move.l   d7, -(a7)
  001644:  61 ff 00 00 06 08    bsr.l    $1c4e  ; -> sub_1c4e
  00164a:  2f 0c                move.l   a4, -(a7)
  00164c:  2f 0b                move.l   a3, -(a7)
  00164e:  61 ff 00 00 05 d6    bsr.l    $1c26  ; -> sub_1c26
  001654:  4f ef 00 18          lea.l    $18(a7), a7
L1658:
  001658:  20 06                move.l   d6, d0
  00165a:  e0 88                lsr.l    #$8, d0
  00165c:  7e 0f                moveq    #$f, d7
  00165e:  ce 80                and.l    d0, d7
  001660:  4a 87                tst.l    d7
  001662:  67 6a                beq.b    $16ce  ; -> L16ce
  001664:  4a 87                tst.l    d7
  001666:  66 04                bne.b    $166c  ; -> L166c
  001668:  70 20                moveq    #$20, d0
  00166a:  60 10                bra.b    $167c  ; -> L167c
L166c:
  00166c:  70 0b                moveq    #$b, d0
  00166e:  b0 87                cmp.l    d7, d0
  001670:  66 04                bne.b    $1676  ; -> L1676
  001672:  70 42                moveq    #$42, d0
  001674:  60 06                bra.b    $167c  ; -> L167c
L1676:
  001676:  10 07                move.b   d7, d0
  001678:  72 a9                moveq    #$a9, d1
  00167a:  90 01                sub.b    d1, d0
L167c:
  00167c:  18 80                move.b   d0, (a4)
  00167e:  42 2c 00 01          clr.b    $1(a4)
  001682:  2f 0c                move.l   a4, -(a7)
  001684:  2f 0b                move.l   a3, -(a7)
  001686:  61 ff 00 00 05 9e    bsr.l    $1c26  ; -> sub_1c26
  00168c:  20 06                move.l   d6, d0
  00168e:  e8 88                lsr.l    #$4, d0
  001690:  7e 0f                moveq    #$f, d7
  001692:  ce 80                and.l    d0, d7
  001694:  4a 87                tst.l    d7
  001696:  50 4f                addq.w   #$8, a7
  001698:  67 18                beq.b    $16b2  ; -> L16b2
  00169a:  2f 0c                move.l   a4, -(a7)
  00169c:  2f 07                move.l   d7, -(a7)
  00169e:  61 ff 00 00 05 ae    bsr.l    $1c4e  ; -> sub_1c4e
  0016a4:  2f 0c                move.l   a4, -(a7)
  0016a6:  2f 0b                move.l   a3, -(a7)
  0016a8:  61 ff 00 00 05 7c    bsr.l    $1c26  ; -> sub_1c26
  0016ae:  4f ef 00 10          lea.l    $10(a7), a7
L16b2:
  0016b2:  2f 0c                move.l   a4, -(a7)
  0016b4:  70 0f                moveq    #$f, d0
  0016b6:  c0 86                and.l    d6, d0
  0016b8:  2f 00                move.l   d0, -(a7)
  0016ba:  61 ff 00 00 05 92    bsr.l    $1c4e  ; -> sub_1c4e
  0016c0:  2f 0c                move.l   a4, -(a7)
  0016c2:  2f 0b                move.l   a3, -(a7)
  0016c4:  61 ff 00 00 05 60    bsr.l    $1c26  ; -> sub_1c26
  0016ca:  4f ef 00 10          lea.l    $10(a7), a7
L16ce:
  0016ce:  4c ee 18 c0 ff a8    movem.l  -$58(a6), d6-d7/a3-a4
  0016d4:  4e 5e                unlk     a6
  0016d6:  4e 75                rts      
  0016d8:  2e 00                move.l   d0, d7
  0016da:  20 00                move.l   d0, d0
sub_16dc:
  0016dc:  4e 56 ff b2          link.w   a6, #$ffb2
  0016e0:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  0016e4:  47 ee ff c0          lea.l    -$40(a6), a3
  0016e8:  2e 2e 00 14          move.l   $14(a6), d7
  0016ec:  28 6e 00 10          movea.l  $10(a6), a4
  0016f0:  20 4c                movea.l  a4, a0
  0016f2:  a0 69                dc.w     $a069  ; _HGetState
  0016f4:  1c 00                move.b   d0, d6
  0016f6:  20 4c                movea.l  a4, a0
  0016f8:  a0 29                dc.w     $a029  ; _HLock
  0016fa:  70 10                moveq    #$10, d0
  0016fc:  22 07                move.l   d7, d1
  0016fe:  e0 a1                asr.l    d0, d1
  001700:  20 3c 00 00 00 ff    move.l   #$ff, d0
  001706:  c0 81                and.l    d1, d0
  001708:  4c 3c 08 00 00 00 04 00 muls.l   #$400, d0
  001710:  2f 00                move.l   d0, -(a7)
  001712:  20 54                movea.l  (a4), a0
  001714:  48 68 00 4a          pea.l    $4a(a0)
  001718:  61 ff 00 00 06 66    bsr.l    $1d80  ; -> sub_1d80
  00171e:  20 54                movea.l  (a4), a0
  001720:  42 28 00 2a          clr.b    $2a(a0)
  001724:  70 00                moveq    #$0, d0
  001726:  c0 87                and.l    d7, d0
  001728:  67 1c                beq.b    $1746  ; -> L1746
  00172a:  20 54                movea.l  (a4), a0
  00172c:  48 68 00 2a          pea.l    $2a(a0)
  001730:  3f 3c f0 31          move.w   #$f031, -(a7)
  001734:  20 3c 00 00 00 ff    move.l   #$ff, d0
  00173a:  c0 87                and.l    d7, d0
  00173c:  52 40                addq.w   #$1, d0
  00173e:  3f 00                move.w   d0, -(a7)
  001740:  61 ff 00 00 05 f8    bsr.l    $1d3a  ; -> sub_1d3a
L1746:
  001746:  2f 0b                move.l   a3, -(a7)
  001748:  3f 3c f0 31          move.w   #$f031, -(a7)
  00174c:  70 01                moveq    #$1, d0
  00174e:  3f 00                move.w   d0, -(a7)
  001750:  61 ff 00 00 05 e8    bsr.l    $1d3a  ; -> sub_1d3a
  001756:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00175a:  30 2e 00 0e          move.w   $e(a6), d0
  00175e:  5a 40                addq.w   #$5, d0
  001760:  3f 00                move.w   d0, -(a7)
  001762:  48 6e ff be          pea.l    -$42(a6)
  001766:  48 6e ff b2          pea.l    -$4e(a6)
  00176a:  48 6e ff b6          pea.l    -$4a(a6)
  00176e:  a9 8d                dc.w     $a98d  ; _GetDItem
  001770:  20 54                movea.l  (a4), a0
  001772:  48 68 00 2a          pea.l    $2a(a0)
  001776:  48 68 00 4a          pea.l    $4a(a0)
  00177a:  70 00                moveq    #$0, d0
  00177c:  2f 00                move.l   d0, -(a7)
  00177e:  2f 00                move.l   d0, -(a7)
  001780:  a9 8b                dc.w     $a98b  ; _ParamText
  001782:  2f 2e ff b2          move.l   -$4e(a6), -(a7)
  001786:  2f 0b                move.l   a3, -(a7)
  001788:  a9 8f                dc.w     $a98f  ; _SetIText
  00178a:  70 00                moveq    #$0, d0
  00178c:  2f 00                move.l   d0, -(a7)
  00178e:  2f 00                move.l   d0, -(a7)
  001790:  2f 00                move.l   d0, -(a7)
  001792:  2f 00                move.l   d0, -(a7)
  001794:  a9 8b                dc.w     $a98b  ; _ParamText
  001796:  20 4c                movea.l  a4, a0
  001798:  a0 2a                dc.w     $a02a  ; _HUnlock
  00179a:  4c ee 18 c0 ff a2    movem.l  -$5e(a6), d6-d7/a3-a4
  0017a0:  4e 5e                unlk     a6
  0017a2:  4e 75                rts      
sub_17a4:
  0017a4:  4e 56 ff f0          link.w   a6, #$fff0
  0017a8:  48 e7 00 18          movem.l  a3-a4, -(a7)
  0017ac:  26 6e 00 08          movea.l  $8(a6), a3
  0017b0:  49 ee ff f8          lea.l    -$8(a6), a4
  0017b4:  18 bc 00 55          move.b   #$55, (a4)
  0017b8:  19 7c 00 aa 00 01    move.b   #$aa, $1(a4)
  0017be:  19 7c 00 55 00 02    move.b   #$55, $2(a4)
  0017c4:  19 7c 00 aa 00 03    move.b   #$aa, $3(a4)
  0017ca:  19 7c 00 55 00 04    move.b   #$55, $4(a4)
  0017d0:  19 7c 00 aa 00 05    move.b   #$aa, $5(a4)
  0017d6:  19 7c 00 55 00 06    move.b   #$55, $6(a4)
  0017dc:  19 7c 00 aa 00 07    move.b   #$aa, $7(a4)
  0017e2:  41 ee ff f0          lea.l    -$10(a6), a0
  0017e6:  22 4b                movea.l  a3, a1
  0017e8:  5c 89                addq.l   #$6, a1
  0017ea:  20 d9                move.l   (a1)+, (a0)+
  0017ec:  20 d9                move.l   (a1)+, (a0)+
  0017ee:  48 6e ff f0          pea.l    -$10(a6)
  0017f2:  70 f8                moveq    #$f8, d0
  0017f4:  3f 00                move.w   d0, -(a7)
  0017f6:  3f 00                move.w   d0, -(a7)
  0017f8:  a8 a9                dc.w     $a8a9  ; _InsetRect
  0017fa:  70 0b                moveq    #$b, d0
  0017fc:  3f 00                move.w   d0, -(a7)
  0017fe:  a8 9c                dc.w     $a89c  ; _PenMode
  001800:  2f 0c                move.l   a4, -(a7)
  001802:  a8 9d                dc.w     $a89d  ; _PenPat
  001804:  48 6e ff f0          pea.l    -$10(a6)
  001808:  a8 a2                dc.w     $a8a2  ; _PaintRect
  00180a:  41 ee ff f0          lea.l    -$10(a6), a0
  00180e:  43 eb 00 12          lea.l    $12(a3), a1
  001812:  20 d9                move.l   (a1)+, (a0)+
  001814:  20 d9                move.l   (a1)+, (a0)+
  001816:  48 6e ff f0          pea.l    -$10(a6)
  00181a:  70 f8                moveq    #$f8, d0
  00181c:  3f 00                move.w   d0, -(a7)
  00181e:  3f 00                move.w   d0, -(a7)
  001820:  a8 a9                dc.w     $a8a9  ; _InsetRect
  001822:  48 6e ff f0          pea.l    -$10(a6)
  001826:  a8 a2                dc.w     $a8a2  ; _PaintRect
  001828:  a8 9e                dc.w     $a89e  ; _PenNormal
  00182a:  4c ee 18 00 ff e8    movem.l  -$18(a6), a3-a4
  001830:  4e 5e                unlk     a6
  001832:  4e 75                rts      
sub_1834:
  001834:  4e 56 ff f8          link.w   a6, #$fff8
  001838:  2f 0c                move.l   a4, -(a7)
  00183a:  28 6e 00 08          movea.l  $8(a6), a4
  00183e:  41 ee ff f8          lea.l    -$8(a6), a0
  001842:  22 4c                movea.l  a4, a1
  001844:  5c 89                addq.l   #$6, a1
  001846:  20 d9                move.l   (a1)+, (a0)+
  001848:  20 d9                move.l   (a1)+, (a0)+
  00184a:  a8 9e                dc.w     $a89e  ; _PenNormal
  00184c:  48 6e ff f8          pea.l    -$8(a6)
  001850:  70 f8                moveq    #$f8, d0
  001852:  3f 00                move.w   d0, -(a7)
  001854:  3f 00                move.w   d0, -(a7)
  001856:  a8 a9                dc.w     $a8a9  ; _InsetRect
  001858:  48 6e ff f8          pea.l    -$8(a6)
  00185c:  a8 a3                dc.w     $a8a3  ; _EraseRect
  00185e:  48 6e ff f8          pea.l    -$8(a6)
  001862:  70 06                moveq    #$6, d0
  001864:  3f 00                move.w   d0, -(a7)
  001866:  3f 00                move.w   d0, -(a7)
  001868:  a8 a9                dc.w     $a8a9  ; _InsetRect
  00186a:  70 01                moveq    #$1, d0
  00186c:  3f 00                move.w   d0, -(a7)
  00186e:  3f 00                move.w   d0, -(a7)
  001870:  a8 9b                dc.w     $a89b  ; _PenSize
  001872:  48 6e ff f8          pea.l    -$8(a6)
  001876:  70 0c                moveq    #$c, d0
  001878:  3f 00                move.w   d0, -(a7)
  00187a:  3f 00                move.w   d0, -(a7)
  00187c:  a8 b0                dc.w     $a8b0  ; _FrameRoundRect
  00187e:  48 6c 00 06          pea.l    $6(a4)
  001882:  2f 2c 00 02          move.l   $2(a4), -(a7)
  001886:  aa 1f                dc.w     $aa1f  ; _PlotCIcon
  001888:  41 ee ff f8          lea.l    -$8(a6), a0
  00188c:  43 ec 00 12          lea.l    $12(a4), a1
  001890:  20 d9                move.l   (a1)+, (a0)+
  001892:  20 d9                move.l   (a1)+, (a0)+
  001894:  48 6e ff f8          pea.l    -$8(a6)
  001898:  70 f8                moveq    #$f8, d0
  00189a:  3f 00                move.w   d0, -(a7)
  00189c:  3f 00                move.w   d0, -(a7)
  00189e:  a8 a9                dc.w     $a8a9  ; _InsetRect
  0018a0:  48 6e ff f8          pea.l    -$8(a6)
  0018a4:  a8 a3                dc.w     $a8a3  ; _EraseRect
  0018a6:  48 6e ff f8          pea.l    -$8(a6)
  0018aa:  70 06                moveq    #$6, d0
  0018ac:  3f 00                move.w   d0, -(a7)
  0018ae:  3f 00                move.w   d0, -(a7)
  0018b0:  a8 a9                dc.w     $a8a9  ; _InsetRect
  0018b2:  70 01                moveq    #$1, d0
  0018b4:  3f 00                move.w   d0, -(a7)
  0018b6:  3f 00                move.w   d0, -(a7)
  0018b8:  a8 9b                dc.w     $a89b  ; _PenSize
  0018ba:  48 6e ff f8          pea.l    -$8(a6)
  0018be:  70 0c                moveq    #$c, d0
  0018c0:  3f 00                move.w   d0, -(a7)
  0018c2:  3f 00                move.w   d0, -(a7)
  0018c4:  a8 b0                dc.w     $a8b0  ; _FrameRoundRect
  0018c6:  a8 9e                dc.w     $a89e  ; _PenNormal
  0018c8:  48 6c 00 12          pea.l    $12(a4)
  0018cc:  2f 2c 00 0e          move.l   $e(a4), -(a7)
  0018d0:  aa 1f                dc.w     $aa1f  ; _PlotCIcon
  0018d2:  4a 14                tst.b    (a4)
  0018d4:  67 06                beq.b    $18dc  ; -> L18dc
  0018d6:  20 4c                movea.l  a4, a0
  0018d8:  5c 88                addq.l   #$6, a0
  0018da:  60 04                bra.b    $18e0  ; -> L18e0
L18dc:
  0018dc:  41 ec 00 12          lea.l    $12(a4), a0
L18e0:
  0018e0:  43 ee ff f8          lea.l    -$8(a6), a1
  0018e4:  22 d8                move.l   (a0)+, (a1)+
  0018e6:  22 d8                move.l   (a0)+, (a1)+
  0018e8:  02 38 00 7f 09 38    andi.b   #$7f, $938.w
  0018ee:  48 6e ff f8          pea.l    -$8(a6)
  0018f2:  70 0c                moveq    #$c, d0
  0018f4:  3f 00                move.w   d0, -(a7)
  0018f6:  3f 00                move.w   d0, -(a7)
  0018f8:  a8 b3                dc.w     $a8b3  ; _InverRoundRect
  0018fa:  28 6e ff f4          movea.l  -$c(a6), a4
  0018fe:  4e 5e                unlk     a6
  001900:  4e 75                rts      
sub_1902:
  001902:  4e 56 00 00          link.w   a6, #$0
  001906:  2f 0c                move.l   a4, -(a7)
  001908:  28 6e 00 08          movea.l  $8(a6), a4
  00190c:  18 ae 00 0f          move.b   $f(a6), (a4)
  001910:  2f 0c                move.l   a4, -(a7)
  001912:  61 ff ff ff ff 20    bsr.l    $1834  ; -> sub_1834
  001918:  28 6e ff fc          movea.l  -$4(a6), a4
  00191c:  4e 5e                unlk     a6
  00191e:  4e 75                rts      
sub_1920:
  001920:  4e 56 ff e4          link.w   a6, #$ffe4
  001924:  48 e7 07 08          movem.l  d5-d7/a4, -(a7)
  001928:  28 6e 00 08          movea.l  $8(a6), a4
  00192c:  1c 14                move.b   (a4), d6
  00192e:  41 ee ff e4          lea.l    -$1c(a6), a0
  001932:  43 ec 00 12          lea.l    $12(a4), a1
  001936:  20 d9                move.l   (a1)+, (a0)+
  001938:  20 d9                move.l   (a1)+, (a0)+
  00193a:  48 6e ff e4          pea.l    -$1c(a6)
  00193e:  70 fc                moveq    #$fc, d0
  001940:  3f 00                move.w   d0, -(a7)
  001942:  3f 00                move.w   d0, -(a7)
  001944:  a8 a9                dc.w     $a8a9  ; _InsetRect
  001946:  41 ee ff ec          lea.l    -$14(a6), a0
  00194a:  22 4c                movea.l  a4, a1
  00194c:  5c 89                addq.l   #$6, a1
  00194e:  20 d9                move.l   (a1)+, (a0)+
  001950:  20 d9                move.l   (a1)+, (a0)+
  001952:  48 6e ff ec          pea.l    -$14(a6)
  001956:  70 fc                moveq    #$fc, d0
  001958:  3f 00                move.w   d0, -(a7)
  00195a:  3f 00                move.w   d0, -(a7)
  00195c:  a8 a9                dc.w     $a8a9  ; _InsetRect
  00195e:  a8 9e                dc.w     $a89e  ; _PenNormal
  001960:  41 ee ff f4          lea.l    -$c(a6), a0
  001964:  22 4c                movea.l  a4, a1
  001966:  5c 89                addq.l   #$6, a1
  001968:  20 d9                move.l   (a1)+, (a0)+
  00196a:  20 d9                move.l   (a1)+, (a0)+
  00196c:  48 6e ff f4          pea.l    -$c(a6)
  001970:  70 f8                moveq    #$f8, d0
  001972:  3f 00                move.w   d0, -(a7)
  001974:  3f 00                move.w   d0, -(a7)
  001976:  a8 a9                dc.w     $a8a9  ; _InsetRect
  001978:  48 6e ff f4          pea.l    -$c(a6)
  00197c:  a8 a3                dc.w     $a8a3  ; _EraseRect
  00197e:  48 6e ff f4          pea.l    -$c(a6)
  001982:  70 06                moveq    #$6, d0
  001984:  3f 00                move.w   d0, -(a7)
  001986:  3f 00                move.w   d0, -(a7)
  001988:  a8 a9                dc.w     $a8a9  ; _InsetRect
  00198a:  70 01                moveq    #$1, d0
  00198c:  3f 00                move.w   d0, -(a7)
  00198e:  3f 00                move.w   d0, -(a7)
  001990:  a8 9b                dc.w     $a89b  ; _PenSize
  001992:  48 6e ff f4          pea.l    -$c(a6)
  001996:  70 0c                moveq    #$c, d0
  001998:  3f 00                move.w   d0, -(a7)
  00199a:  3f 00                move.w   d0, -(a7)
  00199c:  a8 b0                dc.w     $a8b0  ; _FrameRoundRect
  00199e:  48 6c 00 06          pea.l    $6(a4)
  0019a2:  2f 2c 00 02          move.l   $2(a4), -(a7)
  0019a6:  aa 1f                dc.w     $aa1f  ; _PlotCIcon
  0019a8:  41 ee ff f4          lea.l    -$c(a6), a0
  0019ac:  43 ec 00 12          lea.l    $12(a4), a1
  0019b0:  20 d9                move.l   (a1)+, (a0)+
  0019b2:  20 d9                move.l   (a1)+, (a0)+
  0019b4:  48 6e ff f4          pea.l    -$c(a6)
  0019b8:  70 f8                moveq    #$f8, d0
  0019ba:  3f 00                move.w   d0, -(a7)
  0019bc:  3f 00                move.w   d0, -(a7)
  0019be:  a8 a9                dc.w     $a8a9  ; _InsetRect
  0019c0:  48 6e ff f4          pea.l    -$c(a6)
  0019c4:  a8 a3                dc.w     $a8a3  ; _EraseRect
  0019c6:  48 6e ff f4          pea.l    -$c(a6)
  0019ca:  70 06                moveq    #$6, d0
  0019cc:  3f 00                move.w   d0, -(a7)
  0019ce:  3f 00                move.w   d0, -(a7)
  0019d0:  a8 a9                dc.w     $a8a9  ; _InsetRect
  0019d2:  70 01                moveq    #$1, d0
  0019d4:  3f 00                move.w   d0, -(a7)
  0019d6:  3f 00                move.w   d0, -(a7)
  0019d8:  a8 9b                dc.w     $a89b  ; _PenSize
  0019da:  48 6e ff f4          pea.l    -$c(a6)
  0019de:  70 0c                moveq    #$c, d0
  0019e0:  3f 00                move.w   d0, -(a7)
  0019e2:  3f 00                move.w   d0, -(a7)
  0019e4:  a8 b0                dc.w     $a8b0  ; _FrameRoundRect
  0019e6:  a8 9e                dc.w     $a89e  ; _PenNormal
  0019e8:  48 6c 00 12          pea.l    $12(a4)
  0019ec:  2f 2c 00 0e          move.l   $e(a4), -(a7)
  0019f0:  aa 1f                dc.w     $aa1f  ; _PlotCIcon
  0019f2:  4a 14                tst.b    (a4)
  0019f4:  67 06                beq.b    $19fc  ; -> L19fc
  0019f6:  20 4c                movea.l  a4, a0
  0019f8:  5c 88                addq.l   #$6, a0
  0019fa:  60 04                bra.b    $1a00  ; -> L1a00
L19fc:
  0019fc:  41 ec 00 12          lea.l    $12(a4), a0
L1a00:
  001a00:  43 ee ff f4          lea.l    -$c(a6), a1
  001a04:  22 d8                move.l   (a0)+, (a1)+
  001a06:  22 d8                move.l   (a0)+, (a1)+
  001a08:  02 38 00 7f 09 38    andi.b   #$7f, $938.w
  001a0e:  48 6e ff f4          pea.l    -$c(a6)
  001a12:  70 0c                moveq    #$c, d0
  001a14:  3f 00                move.w   d0, -(a7)
  001a16:  3f 00                move.w   d0, -(a7)
  001a18:  a8 b3                dc.w     $a8b3  ; _InverRoundRect
  001a1a:  48 6e ff fc          pea.l    -$4(a6)
  001a1e:  a9 72                dc.w     $a972  ; _GetMouse
  001a20:  55 8f                subq.l   #$2, a7
  001a22:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  001a26:  48 6c 00 06          pea.l    $6(a4)
  001a2a:  a8 ad                dc.w     $a8ad  ; _PtInRect
  001a2c:  1c 1f                move.b   (a7)+, d6
  001a2e:  55 8f                subq.l   #$2, a7
  001a30:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  001a34:  48 6c 00 12          pea.l    $12(a4)
  001a38:  a8 ad                dc.w     $a8ad  ; _PtInRect
  001a3a:  1e 1f                move.b   (a7)+, d7
  001a3c:  4a 06                tst.b    d6
  001a3e:  67 1a                beq.b    $1a5a  ; -> L1a5a
  001a40:  7a 01                moveq    #$1, d5
  001a42:  70 03                moveq    #$3, d0
  001a44:  3f 00                move.w   d0, -(a7)
  001a46:  3f 00                move.w   d0, -(a7)
  001a48:  a8 9b                dc.w     $a89b  ; _PenSize
  001a4a:  48 6e ff ec          pea.l    -$14(a6)
  001a4e:  70 10                moveq    #$10, d0
  001a50:  3f 00                move.w   d0, -(a7)
  001a52:  3f 00                move.w   d0, -(a7)
  001a54:  a8 b0                dc.w     $a8b0  ; _FrameRoundRect
  001a56:  60 00 01 34          bra.w    $1b8c  ; -> L1b8c
L1a5a:
  001a5a:  4a 07                tst.b    d7
  001a5c:  67 00 01 2e          beq.w    $1b8c  ; -> L1b8c
  001a60:  42 05                clr.b    d5
  001a62:  70 03                moveq    #$3, d0
  001a64:  3f 00                move.w   d0, -(a7)
  001a66:  3f 00                move.w   d0, -(a7)
  001a68:  a8 9b                dc.w     $a89b  ; _PenSize
  001a6a:  48 6e ff e4          pea.l    -$1c(a6)
  001a6e:  70 10                moveq    #$10, d0
  001a70:  3f 00                move.w   d0, -(a7)
  001a72:  3f 00                move.w   d0, -(a7)
  001a74:  a8 b0                dc.w     $a8b0  ; _FrameRoundRect
  001a76:  60 00 01 14          bra.w    $1b8c  ; -> L1b8c
L1a7a:
  001a7a:  48 6e ff fc          pea.l    -$4(a6)
  001a7e:  a9 72                dc.w     $a972  ; _GetMouse
  001a80:  4a 06                tst.b    d6
  001a82:  67 56                beq.b    $1ada  ; -> L1ada
  001a84:  55 8f                subq.l   #$2, a7
  001a86:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  001a8a:  48 6c 00 06          pea.l    $6(a4)
  001a8e:  a8 ad                dc.w     $a8ad  ; _PtInRect
  001a90:  4a 1f                tst.b    (a7)+
  001a92:  66 00 00 9c          bne.w    $1b30  ; -> L1b30
  001a96:  70 0a                moveq    #$a, d0
  001a98:  3f 00                move.w   d0, -(a7)
  001a9a:  a8 9c                dc.w     $a89c  ; _PenMode
  001a9c:  70 03                moveq    #$3, d0
  001a9e:  3f 00                move.w   d0, -(a7)
  001aa0:  3f 00                move.w   d0, -(a7)
  001aa2:  a8 9b                dc.w     $a89b  ; _PenSize
  001aa4:  48 6e ff ec          pea.l    -$14(a6)
  001aa8:  70 10                moveq    #$10, d0
  001aaa:  3f 00                move.w   d0, -(a7)
  001aac:  3f 00                move.w   d0, -(a7)
  001aae:  a8 b0                dc.w     $a8b0  ; _FrameRoundRect
  001ab0:  a8 9e                dc.w     $a89e  ; _PenNormal
  001ab2:  41 ee ff f4          lea.l    -$c(a6), a0
  001ab6:  43 ee ff ec          lea.l    -$14(a6), a1
  001aba:  20 d9                move.l   (a1)+, (a0)+
  001abc:  20 d9                move.l   (a1)+, (a0)+
  001abe:  48 6e ff f4          pea.l    -$c(a6)
  001ac2:  70 02                moveq    #$2, d0
  001ac4:  3f 00                move.w   d0, -(a7)
  001ac6:  3f 00                move.w   d0, -(a7)
  001ac8:  a8 a9                dc.w     $a8a9  ; _InsetRect
  001aca:  48 6e ff f4          pea.l    -$c(a6)
  001ace:  70 0c                moveq    #$c, d0
  001ad0:  3f 00                move.w   d0, -(a7)
  001ad2:  3f 00                move.w   d0, -(a7)
  001ad4:  a8 b0                dc.w     $a8b0  ; _FrameRoundRect
  001ad6:  42 06                clr.b    d6
  001ad8:  60 56                bra.b    $1b30  ; -> L1b30
L1ada:
  001ada:  4a 07                tst.b    d7
  001adc:  67 52                beq.b    $1b30  ; -> L1b30
  001ade:  55 8f                subq.l   #$2, a7
  001ae0:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  001ae4:  48 6c 00 12          pea.l    $12(a4)
  001ae8:  a8 ad                dc.w     $a8ad  ; _PtInRect
  001aea:  4a 1f                tst.b    (a7)+
  001aec:  66 42                bne.b    $1b30  ; -> L1b30
  001aee:  70 0a                moveq    #$a, d0
  001af0:  3f 00                move.w   d0, -(a7)
  001af2:  a8 9c                dc.w     $a89c  ; _PenMode
  001af4:  70 03                moveq    #$3, d0
  001af6:  3f 00                move.w   d0, -(a7)
  001af8:  3f 00                move.w   d0, -(a7)
  001afa:  a8 9b                dc.w     $a89b  ; _PenSize
  001afc:  48 6e ff e4          pea.l    -$1c(a6)
  001b00:  70 10                moveq    #$10, d0
  001b02:  3f 00                move.w   d0, -(a7)
  001b04:  3f 00                move.w   d0, -(a7)
  001b06:  a8 b0                dc.w     $a8b0  ; _FrameRoundRect
  001b08:  a8 9e                dc.w     $a89e  ; _PenNormal
  001b0a:  41 ee ff f4          lea.l    -$c(a6), a0
  001b0e:  43 ee ff e4          lea.l    -$1c(a6), a1
  001b12:  20 d9                move.l   (a1)+, (a0)+
  001b14:  20 d9                move.l   (a1)+, (a0)+
  001b16:  48 6e ff f4          pea.l    -$c(a6)
  001b1a:  70 02                moveq    #$2, d0
  001b1c:  3f 00                move.w   d0, -(a7)
  001b1e:  3f 00                move.w   d0, -(a7)
  001b20:  a8 a9                dc.w     $a8a9  ; _InsetRect
  001b22:  48 6e ff f4          pea.l    -$c(a6)
  001b26:  70 0c                moveq    #$c, d0
  001b28:  3f 00                move.w   d0, -(a7)
  001b2a:  3f 00                move.w   d0, -(a7)
  001b2c:  a8 b0                dc.w     $a8b0  ; _FrameRoundRect
  001b2e:  42 07                clr.b    d7
L1b30:
  001b30:  4a 05                tst.b    d5
  001b32:  66 2a                bne.b    $1b5e  ; -> L1b5e
  001b34:  4a 07                tst.b    d7
  001b36:  66 26                bne.b    $1b5e  ; -> L1b5e
  001b38:  55 8f                subq.l   #$2, a7
  001b3a:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  001b3e:  48 6c 00 12          pea.l    $12(a4)
  001b42:  a8 ad                dc.w     $a8ad  ; _PtInRect
  001b44:  4a 1f                tst.b    (a7)+
  001b46:  67 16                beq.b    $1b5e  ; -> L1b5e
  001b48:  70 03                moveq    #$3, d0
  001b4a:  3f 00                move.w   d0, -(a7)
  001b4c:  3f 00                move.w   d0, -(a7)
  001b4e:  a8 9b                dc.w     $a89b  ; _PenSize
  001b50:  48 6e ff e4          pea.l    -$1c(a6)
  001b54:  70 10                moveq    #$10, d0
  001b56:  3f 00                move.w   d0, -(a7)
  001b58:  3f 00                move.w   d0, -(a7)
  001b5a:  a8 b0                dc.w     $a8b0  ; _FrameRoundRect
  001b5c:  7e 01                moveq    #$1, d7
L1b5e:
  001b5e:  4a 05                tst.b    d5
  001b60:  67 2a                beq.b    $1b8c  ; -> L1b8c
  001b62:  4a 06                tst.b    d6
  001b64:  66 26                bne.b    $1b8c  ; -> L1b8c
  001b66:  55 8f                subq.l   #$2, a7
  001b68:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  001b6c:  48 6c 00 06          pea.l    $6(a4)
  001b70:  a8 ad                dc.w     $a8ad  ; _PtInRect
  001b72:  4a 1f                tst.b    (a7)+
  001b74:  67 16                beq.b    $1b8c  ; -> L1b8c
  001b76:  70 03                moveq    #$3, d0
  001b78:  3f 00                move.w   d0, -(a7)
  001b7a:  3f 00                move.w   d0, -(a7)
  001b7c:  a8 9b                dc.w     $a89b  ; _PenSize
  001b7e:  48 6e ff ec          pea.l    -$14(a6)
  001b82:  70 10                moveq    #$10, d0
  001b84:  3f 00                move.w   d0, -(a7)
  001b86:  3f 00                move.w   d0, -(a7)
  001b88:  a8 b0                dc.w     $a8b0  ; _FrameRoundRect
  001b8a:  7c 01                moveq    #$1, d6
L1b8c:
  001b8c:  55 8f                subq.l   #$2, a7
  001b8e:  a9 73                dc.w     $a973  ; _StillDown
  001b90:  4a 1f                tst.b    (a7)+
  001b92:  66 00 fe e6          bne.w    $1a7a  ; -> L1a7a
  001b96:  70 ff                moveq    #$ff, d0
  001b98:  3f 00                move.w   d0, -(a7)
  001b9a:  72 00                moveq    #$0, d1
  001b9c:  3f 01                move.w   d1, -(a7)
  001b9e:  20 1f                move.l   (a7)+, d0
  001ba0:  a0 32                dc.w     $a032  ; _FlushEvents
  001ba2:  70 0b                moveq    #$b, d0
  001ba4:  3f 00                move.w   d0, -(a7)
  001ba6:  a8 9c                dc.w     $a89c  ; _PenMode
  001ba8:  48 6e ff ec          pea.l    -$14(a6)
  001bac:  70 10                moveq    #$10, d0
  001bae:  3f 00                move.w   d0, -(a7)
  001bb0:  3f 00                move.w   d0, -(a7)
  001bb2:  a8 b0                dc.w     $a8b0  ; _FrameRoundRect
  001bb4:  48 6e ff e4          pea.l    -$1c(a6)
  001bb8:  70 10                moveq    #$10, d0
  001bba:  3f 00                move.w   d0, -(a7)
  001bbc:  3f 00                move.w   d0, -(a7)
  001bbe:  a8 b0                dc.w     $a8b0  ; _FrameRoundRect
  001bc0:  a8 9e                dc.w     $a89e  ; _PenNormal
  001bc2:  41 ee ff f4          lea.l    -$c(a6), a0
  001bc6:  43 ee ff ec          lea.l    -$14(a6), a1
  001bca:  20 d9                move.l   (a1)+, (a0)+
  001bcc:  20 d9                move.l   (a1)+, (a0)+
  001bce:  48 6e ff f4          pea.l    -$c(a6)
  001bd2:  70 02                moveq    #$2, d0
  001bd4:  3f 00                move.w   d0, -(a7)
  001bd6:  3f 00                move.w   d0, -(a7)
  001bd8:  a8 a9                dc.w     $a8a9  ; _InsetRect
  001bda:  48 6e ff f4          pea.l    -$c(a6)
  001bde:  70 0c                moveq    #$c, d0
  001be0:  3f 00                move.w   d0, -(a7)
  001be2:  3f 00                move.w   d0, -(a7)
  001be4:  a8 b0                dc.w     $a8b0  ; _FrameRoundRect
  001be6:  41 ee ff f4          lea.l    -$c(a6), a0
  001bea:  43 ee ff e4          lea.l    -$1c(a6), a1
  001bee:  20 d9                move.l   (a1)+, (a0)+
  001bf0:  20 d9                move.l   (a1)+, (a0)+
  001bf2:  48 6e ff f4          pea.l    -$c(a6)
  001bf6:  70 02                moveq    #$2, d0
  001bf8:  3f 00                move.w   d0, -(a7)
  001bfa:  3f 00                move.w   d0, -(a7)
  001bfc:  a8 a9                dc.w     $a8a9  ; _InsetRect
  001bfe:  48 6e ff f4          pea.l    -$c(a6)
  001c02:  70 0c                moveq    #$c, d0
  001c04:  3f 00                move.w   d0, -(a7)
  001c06:  3f 00                move.w   d0, -(a7)
  001c08:  a8 b0                dc.w     $a8b0  ; _FrameRoundRect
  001c0a:  4a 06                tst.b    d6
  001c0c:  67 04                beq.b    $1c12  ; -> L1c12
  001c0e:  70 01                moveq    #$1, d0
  001c10:  60 0a                bra.b    $1c1c  ; -> L1c1c
L1c12:
  001c12:  4a 07                tst.b    d7
  001c14:  67 04                beq.b    $1c1a  ; -> L1c1a
  001c16:  70 00                moveq    #$0, d0
  001c18:  60 02                bra.b    $1c1c  ; -> L1c1c
L1c1a:
  001c1a:  70 ff                moveq    #$ff, d0
L1c1c:
  001c1c:  4c ee 10 e0 ff d4    movem.l  -$2c(a6), d5-d7/a4
  001c22:  4e 5e                unlk     a6
  001c24:  4e 75                rts      
sub_1c26:
  001c26:  4e 56 00 00          link.w   a6, #$0
  001c2a:  48 e7 00 18          movem.l  a3-a4, -(a7)
  001c2e:  26 6e 00 0c          movea.l  $c(a6), a3
  001c32:  28 6e 00 08          movea.l  $8(a6), a4
  001c36:  60 02                bra.b    $1c3a  ; -> L1c3a
L1c38:
  001c38:  52 4c                addq.w   #$1, a4
L1c3a:
  001c3a:  4a 14                tst.b    (a4)
  001c3c:  66 fa                bne.b    $1c38  ; -> L1c38
L1c3e:
  001c3e:  18 9b                move.b   (a3)+, (a4)
  001c40:  4a 1c                tst.b    (a4)+
  001c42:  66 fa                bne.b    $1c3e  ; -> L1c3e
  001c44:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  001c4a:  4e 5e                unlk     a6
  001c4c:  4e 75                rts      
sub_1c4e:
  001c4e:  2f 02                move.l   d2, -(a7)
  001c50:  20 2f 00 08          move.l   $8(a7), d0
  001c54:  20 6f 00 0c          movea.l  $c(a7), a0
  001c58:  42 67                clr.w    -(a7)
  001c5a:  a9 ee                dc.w     $a9ee  ; _DECSTR68K
  001c5c:  2f 08                move.l   a0, -(a7)
  001c5e:  4e ba 00 08          jsr      $1c68(pc)  ; -> sub_1c68
  001c62:  58 4f                addq.w   #$4, a7
  001c64:  24 1f                move.l   (a7)+, d2
  001c66:  4e 75                rts      
sub_1c68:
  001c68:  20 2f 00 04          move.l   $4(a7), d0
  001c6c:  67 12                beq.b    $1c80  ; -> L1c80
  001c6e:  20 40                movea.l  d0, a0
  001c70:  42 41                clr.w    d1
  001c72:  12 10                move.b   (a0), d1
  001c74:  60 04                bra.b    $1c7a  ; -> L1c7a
L1c76:
  001c76:  10 e8 00 01          move.b   $1(a0), (a0)+
L1c7a:
  001c7a:  51 c9 ff fa          dbra     d1, $1c76  ; -> L1c76
  001c7e:  42 10                clr.b    (a0)
L1c80:
  001c80:  4e 75                rts      
  001c82:  86 70 32 63          or.w     $63(a0, d3.w), d3
  001c86:  73                   dc.b     $73  ; s
  001c87:  74 72                moveq    #$72, d2
  001c89:  00 00 00 20          ori.b    #$20, d0
  001c8d:  2f 00                move.l   d0, -(a7)
  001c8f:  04 67 1c 20          subi.w   #$1c20, -(a7)
  001c93:  40 22                negx.b   -(a2)
  001c95:  40 34 3c 00          negx.b   (a4, d3.l * 4)
  001c99:  ff 12                fsave    (a2)
  001c9b:  10 10                move.b   (a0), d0
  001c9d:  c0 10                and.b    (a0), d0
  001c9f:  01 57                bchg.b   d0, (a7)
  001ca1:  ca                   dc.b     $ca  ; .
  001ca2:  ff f8                dc.w     $fff8
  001ca4:  22 08                move.l   a0, d1
  001ca6:  20 09                move.l   a1, d0
  001ca8:  92 80                sub.l    d0, d1
  001caa:  53 01                subq.b   #$1, d1
  001cac:  12 81                move.b   d1, (a1)
L1cae:
  001cae:  4e 75                rts      
  001cb0:  86 63                or.w     -(a3), d3
  001cb2:  32 70 73 74 72 00 00 00 movea.w  $72000000(a0, invalid.w), a1
sub_1cba:
  001cba:  30 2f 00 04          move.w   $4(a7), d0
  001cbe:  9e fc 00 1e          suba.w   #$1e, a7
  001cc2:  3f 40 00 18          move.w   d0, $18(a7)
  001cc6:  20 4f                movea.l  a7, a0
  001cc8:  a0 01                dc.w     $a001  ; _Close
  001cca:  4f ef 00 1e          lea.l    $1e(a7), a7
  001cce:  3f 40 00 06          move.w   d0, $6(a7)
  001cd2:  20 5f                movea.l  (a7)+, a0
  001cd4:  54 4f                addq.w   #$2, a7
  001cd6:  4e d0                jmp      (a0)
sub_1cd8:
  001cd8:  4e 56 ff ce          link.w   a6, #$ffce
  001cdc:  20 4f                movea.l  a7, a0
  001cde:  31 6e 00 0e 00 18    move.w   $e(a6), $18(a0)
  001ce4:  31 6e 00 0c 00 1a    move.w   $c(a6), $1a(a0)
  001cea:  4a ae 00 08          tst.l    $8(a6)
  001cee:  67 10                beq.b    $1d00  ; -> L1d00
  001cf0:  43 e8 00 1c          lea.l    $1c(a0), a1
  001cf4:  20 6e 00 08          movea.l  $8(a6), a0
  001cf8:  70 16                moveq    #$16, d0
  001cfa:  a0 2e                dc.w     $a02e  ; _BlockMove
  001cfc:  41 ee ff ce          lea.l    -$32(a6), a0
L1d00:
  001d00:  a0 04                dc.w     $a004  ; _Control
  001d02:  3d 40 00 10          move.w   d0, $10(a6)
  001d06:  4e 5e                unlk     a6
  001d08:  22 5f                movea.l  (a7)+, a1
  001d0a:  50 8f                addq.l   #$8, a7
  001d0c:  4e d1                jmp      (a1)
sub_1d0e:
  001d0e:  4e 56 ff ce          link.w   a6, #$ffce
  001d12:  20 4f                movea.l  a7, a0
  001d14:  31 6e 00 0e 00 18    move.w   $e(a6), $18(a0)
  001d1a:  31 6e 00 0c 00 1a    move.w   $c(a6), $1a(a0)
  001d20:  a0 05                dc.w     $a005  ; _Status
  001d22:  3d 40 00 10          move.w   d0, $10(a6)
  001d26:  41 ee ff ea          lea.l    -$16(a6), a0
  001d2a:  22 6e 00 08          movea.l  $8(a6), a1
  001d2e:  70 16                moveq    #$16, d0
  001d30:  a0 2e                dc.w     $a02e  ; _BlockMove
  001d32:  4e 5e                unlk     a6
  001d34:  22 5f                movea.l  (a7)+, a1
  001d36:  50 8f                addq.l   #$8, a7
  001d38:  4e d1                jmp      (a1)
sub_1d3a:
  001d3a:  4e 56 00 00          link.w   a6, #$0
  001d3e:  59 4f                subq.w   #$4, a7
  001d40:  2f 3c 53 54 52 23    move.l   #$53545223, -(a7)  ; 'STR#'
  001d46:  3f 2e 00 0a          move.w   $a(a6), -(a7)
  001d4a:  a9 a0                dc.w     $a9a0  ; _GetResource
  001d4c:  22 6e 00 0c          movea.l  $c(a6), a1
  001d50:  42 11                clr.b    (a1)
  001d52:  20 1f                move.l   (a7)+, d0
  001d54:  67 22                beq.b    $1d78  ; -> L1d78
  001d56:  20 40                movea.l  d0, a0
  001d58:  20 50                movea.l  (a0), a0
  001d5a:  30 18                move.w   (a0)+, d0
  001d5c:  32 2e 00 08          move.w   $8(a6), d1
  001d60:  67 16                beq.b    $1d78  ; -> L1d78
  001d62:  b2 40                cmp.w    d0, d1
  001d64:  62 12                bhi.b    $1d78  ; -> L1d78
  001d66:  70 00                moveq    #$0, d0
L1d68:
  001d68:  53 41                subq.w   #$1, d1
  001d6a:  67 06                beq.b    $1d72  ; -> L1d72
  001d6c:  10 18                move.b   (a0)+, d0
  001d6e:  d1 c0                adda.l   d0, a0
  001d70:  60 f6                bra.b    $1d68  ; -> L1d68
L1d72:
  001d72:  10 10                move.b   (a0), d0
  001d74:  52 40                addq.w   #$1, d0
  001d76:  a0 2e                dc.w     $a02e  ; _BlockMove
L1d78:
  001d78:  4e 5e                unlk     a6
  001d7a:  20 5f                movea.l  (a7)+, a0
  001d7c:  50 8f                addq.l   #$8, a7
  001d7e:  4e d0                jmp      (a0)
sub_1d80:
  001d80:  20 6f 00 04          movea.l  $4(a7), a0
  001d84:  20 2f 00 08          move.l   $8(a7), d0
  001d88:  42 67                clr.w    -(a7)
  001d8a:  a9 ee                dc.w     $a9ee  ; _DECSTR68K
  001d8c:  20 5f                movea.l  (a7)+, a0
  001d8e:  50 4f                addq.w   #$8, a7
  001d90:  4e d0                jmp      (a0)
sub_1d92:
  001d92:  2f 2f 00 04          move.l   $4(a7), -(a7)
  001d96:  4e ba fe f4          jsr      $1c8c(pc)  ; -> sub_1c8c
  001d9a:  58 4f                addq.w   #$4, a7
  001d9c:  20 6f 00 04          movea.l  $4(a7), a0
  001da0:  22 6f 00 08          movea.l  $8(a7), a1
  001da4:  70 18                moveq    #$18, d0
L1da6:
  001da6:  42 67                clr.w    -(a7)
  001da8:  51 c8 ff fc          dbra     d0, $1da6  ; -> L1da6
  001dac:  2f 48 00 12          move.l   a0, $12(a7)
  001db0:  42 2f 00 1b          clr.b    $1b(a7)
  001db4:  20 4f                movea.l  a7, a0
  001db6:  a0 00                dc.w     $a000  ; _Open
  001db8:  32 af 00 18          move.w   $18(a7), (a1)
  001dbc:  4f ef 00 32          lea.l    $32(a7), a7
  001dc0:  3f 00                move.w   d0, -(a7)
  001dc2:  2f 2f 00 06          move.l   $6(a7), -(a7)
  001dc6:  4e ba fe a0          jsr      $1c68(pc)  ; -> sub_1c68
  001dca:  58 4f                addq.w   #$4, a7
  001dcc:  30 1f                move.w   (a7)+, d0
  001dce:  48 c0                ext.l    d0
  001dd0:  4e 75                rts      
sub_1dd2:
  001dd2:  2f 02                move.l   d2, -(a7)
  001dd4:  2f 2f 00 08          move.l   $8(a7), -(a7)
  001dd8:  4e ba fe b2          jsr      $1c8c(pc)  ; -> sub_1c8c
  001ddc:  2f 2f 00 10          move.l   $10(a7), -(a7)
  001de0:  4e ba fe aa          jsr      $1c8c(pc)  ; -> sub_1c8c
  001de4:  2f 2f 00 18          move.l   $18(a7), -(a7)
  001de8:  4e ba fe a2          jsr      $1c8c(pc)  ; -> sub_1c8c
  001dec:  2f 2f 00 20          move.l   $20(a7), -(a7)
  001df0:  4e ba fe 9a          jsr      $1c8c(pc)  ; -> sub_1c8c
  001df4:  a9 8b                dc.w     $a98b  ; _ParamText
  001df6:  2f 2f 00 08          move.l   $8(a7), -(a7)
  001dfa:  4e ba fe 6c          jsr      $1c68(pc)  ; -> sub_1c68
  001dfe:  2f 2f 00 10          move.l   $10(a7), -(a7)
  001e02:  4e ba fe 64          jsr      $1c68(pc)  ; -> sub_1c68
  001e06:  2f 2f 00 18          move.l   $18(a7), -(a7)
  001e0a:  4e ba fe 5c          jsr      $1c68(pc)  ; -> sub_1c68
  001e0e:  2f 2f 00 20          move.l   $20(a7), -(a7)
  001e12:  4e ba fe 54          jsr      $1c68(pc)  ; -> sub_1c68
  001e16:  4f ef 00 10          lea.l    $10(a7), a7
  001e1a:  24 1f                move.l   (a7)+, d2
  001e1c:  4e 75                rts      
sub_1e1e:
  001e1e:  2f 02                move.l   d2, -(a7)
  001e20:  2f 2f 00 08          move.l   $8(a7), -(a7)
  001e24:  2f 2f 00 10          move.l   $10(a7), -(a7)
  001e28:  4e ba fe 62          jsr      $1c8c(pc)  ; -> sub_1c8c
  001e2c:  a9 8f                dc.w     $a98f  ; _SetIText
  001e2e:  2f 2f 00 0c          move.l   $c(a7), -(a7)
  001e32:  4e ba fe 34          jsr      $1c68(pc)  ; -> sub_1c68
  001e36:  58 4f                addq.w   #$4, a7
  001e38:  24 1f                move.l   (a7)+, d2
  001e3a:  4e 75                rts      
