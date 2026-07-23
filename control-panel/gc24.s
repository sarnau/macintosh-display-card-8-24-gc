* ==================================================================
*  gc24  -  QuickDraw GC accelerator engine (resource 'gc24' id -4048)
*           48 KB, 68020.  Host side of the 8*24 GC acceleration.
* ==================================================================
*  For each accelerated drawing op it marshals a command + parameters and
*  appends them to the on-card Am29000's command queue, falling back to
*  software QuickDraw when acceleration is unavailable.
*
*  Layout:
*    $0000..$13E3  dispatch table  - 106 entries x $30 bytes.  Each entry:
*                    +$00  dc.l  Am29000 command code / firmware offset
*                    +$04  stub  (GlobalsAccessor) - fetch engine globals via
*                                low-mem [$888] and tail-jump through them
*                    +$28  bra.l handler_NN   (the 68k handler for this op)
*    $13E4..$C27C  handler + engine code.
*
*  Engine globals: reached everywhere as [[ [$888] stripped ]].
*    +$14   dispatch pointer (used by GlobalsAccessor)
*    +$214  device record (EngineDispatch checks its ready flags at +$8)
*    +$AA6  per-op scratch word (StoreCtxWord_AA6)
*
*  gc24 also contains ACEFLoad - the relocating loader that parses the ACEF
*  Am29000 object format (magic/sections/symbols/relocations) and downloads
*  the firmware to the card (see the log strings near $3080).
*
*  Labels: infrastructure routines named by inspection (GlobalsAccessor,
*  Strip24, GetA5, EngineDispatch, StoreCtxWord_AA6, HWPrivProbe,
*  CopyParamsToQueue, GestaltSelectorTable, ACEFLoad).  A dozen leaf routines
*  carry their REAL names, recovered from the embedded MacsBug symbols that
*  the compiler placed after each function (GA_MoveHHi, FixScale, GetD2,
*  GACursorTask, GA_PMGR, ...).  The 106 op-handlers keep generic names
*  (handler_NN, with their Am29000 command code in the table): pinning each
*  to a specific QuickDraw op needs the (still packed) ACEF firmware.
*  Embedded strings (log messages + MacsBug symbols) are shown as data.
*
*  Trap names from Apple CIncludes/Traps.h.  Disassembled by recursive
*  descent + linear sweep; tables shown as structured data, rest as code.
*
disp_00:
  000000:  00 00 06 44          dc.l     $00000644  ; dispatch #0, Am29000 cmd/offset $644
* GlobalsAccessor  -  every dispatch stub tail-jumps through here.
* Fetches the engine globals via low-mem [$888] (a handle), derefs and
* 24-bit-strips it, then dispatches through globals+$14.  The engine
* globals are reached everywhere as  [[ [$888] stripped ]].
GlobalsAccessor:
  000004:  2f 08                move.l   a0, -(a7)
  000006:  20 78 08 88          movea.l  $888.w, a0
  00000a:  20 50                movea.l  (a0), a0
  00000c:  2f 00                move.l   d0, -(a7)
  00000e:  20 10                move.l   (a0), d0
  000010:  e1 88                lsl.l    #$8, d0
  000012:  e0 88                lsr.l    #$8, d0
  000014:  20 40                movea.l  d0, a0
  000016:  20 1f                move.l   (a7)+, d0
  000018:  41 e8 00 14          lea.l    $14(a0), a0
  00001c:  2f 10                move.l   (a0), -(a7)
  00001e:  20 6f 00 04          movea.l  $4(a7), a0
  000022:  2e 9f                move.l   (a7)+, (a7)
  000024:  4e 75                rts      
  000026:  4e 71                nop      
  000028:  60 ff 00 00 7f 26    bra.l    $7f50  ; -> handler_00
  00002e:  4e 71                nop      
disp_01:
  000030:  00 00 08 ee          dc.l     $000008EE  ; dispatch #1, Am29000 cmd/offset $8EE
L34:
  000034:  2f 08                move.l   a0, -(a7)
  000036:  20 78 08 88          movea.l  $888.w, a0
  00003a:  20 50                movea.l  (a0), a0
  00003c:  2f 00                move.l   d0, -(a7)
  00003e:  20 10                move.l   (a0), d0
  000040:  e1 88                lsl.l    #$8, d0
  000042:  e0 88                lsr.l    #$8, d0
  000044:  20 40                movea.l  d0, a0
  000046:  20 1f                move.l   (a7)+, d0
  000048:  41 e8 00 14          lea.l    $14(a0), a0
  00004c:  2f 28 00 04          move.l   $4(a0), -(a7)
  000050:  20 6f 00 04          movea.l  $4(a7), a0
  000054:  2e 9f                move.l   (a7)+, (a7)
  000056:  4e 75                rts      
  000058:  60 ff 00 00 7f c2    bra.l    $801c  ; -> GACursorTask
  00005e:  4e 71                nop      
disp_02:
  000060:  00 00 11 b0          dc.l     $000011B0  ; dispatch #2, Am29000 cmd/offset $11B0
L64:
  000064:  2f 08                move.l   a0, -(a7)
  000066:  20 78 08 88          movea.l  $888.w, a0
  00006a:  20 50                movea.l  (a0), a0
  00006c:  2f 00                move.l   d0, -(a7)
  00006e:  20 10                move.l   (a0), d0
  000070:  e1 88                lsl.l    #$8, d0
  000072:  e0 88                lsr.l    #$8, d0
  000074:  20 40                movea.l  d0, a0
  000076:  20 1f                move.l   (a7)+, d0
  000078:  41 e8 00 14          lea.l    $14(a0), a0
  00007c:  2f 28 00 08          move.l   $8(a0), -(a7)
  000080:  20 6f 00 04          movea.l  $4(a7), a0
  000084:  2e 9f                move.l   (a7)+, (a7)
  000086:  4e 75                rts      
  000088:  60 ff 00 00 47 b2    bra.l    $483c  ; -> handler_02
  00008e:  4e 71                nop      
disp_03:
  000090:  00 00 10 40          dc.l     $00001040  ; dispatch #3, Am29000 cmd/offset $1040
L94:
  000094:  2f 08                move.l   a0, -(a7)
  000096:  20 78 08 88          movea.l  $888.w, a0
  00009a:  20 50                movea.l  (a0), a0
  00009c:  2f 00                move.l   d0, -(a7)
  00009e:  20 10                move.l   (a0), d0
  0000a0:  e1 88                lsl.l    #$8, d0
  0000a2:  e0 88                lsr.l    #$8, d0
  0000a4:  20 40                movea.l  d0, a0
  0000a6:  20 1f                move.l   (a7)+, d0
  0000a8:  41 e8 00 14          lea.l    $14(a0), a0
  0000ac:  2f 28 00 0c          move.l   $c(a0), -(a7)
  0000b0:  20 6f 00 04          movea.l  $4(a7), a0
  0000b4:  2e 9f                move.l   (a7)+, (a7)
  0000b6:  4e 75                rts      
  0000b8:  60 ff 00 00 35 c8    bra.l    $3682  ; -> handler_03
  0000be:  4e 71                nop      
disp_04:
  0000c0:  00 00 10 f4          dc.l     $000010F4  ; dispatch #4, Am29000 cmd/offset $10F4
Lc4:
  0000c4:  2f 08                move.l   a0, -(a7)
  0000c6:  20 78 08 88          movea.l  $888.w, a0
  0000ca:  20 50                movea.l  (a0), a0
  0000cc:  2f 00                move.l   d0, -(a7)
  0000ce:  20 10                move.l   (a0), d0
  0000d0:  e1 88                lsl.l    #$8, d0
  0000d2:  e0 88                lsr.l    #$8, d0
  0000d4:  20 40                movea.l  d0, a0
  0000d6:  20 1f                move.l   (a7)+, d0
  0000d8:  41 e8 00 14          lea.l    $14(a0), a0
  0000dc:  2f 28 00 10          move.l   $10(a0), -(a7)
  0000e0:  20 6f 00 04          movea.l  $4(a7), a0
  0000e4:  2e 9f                move.l   (a7)+, (a7)
  0000e6:  4e 75                rts      
  0000e8:  60 ff 00 00 3c f2    bra.l    $3ddc  ; -> handler_04
  0000ee:  4e 71                nop      
disp_05:
  0000f0:  00 00 10 08          dc.l     $00001008  ; dispatch #5, Am29000 cmd/offset $1008
Lf4:
  0000f4:  2f 08                move.l   a0, -(a7)
  0000f6:  20 78 08 88          movea.l  $888.w, a0
  0000fa:  20 50                movea.l  (a0), a0
  0000fc:  2f 00                move.l   d0, -(a7)
  0000fe:  20 10                move.l   (a0), d0
  000100:  e1 88                lsl.l    #$8, d0
  000102:  e0 88                lsr.l    #$8, d0
  000104:  20 40                movea.l  d0, a0
  000106:  20 1f                move.l   (a7)+, d0
  000108:  41 e8 00 14          lea.l    $14(a0), a0
  00010c:  2f 28 00 14          move.l   $14(a0), -(a7)
  000110:  20 6f 00 04          movea.l  $4(a7), a0
  000114:  2e 9f                move.l   (a7)+, (a7)
  000116:  4e 75                rts      
  000118:  60 ff 00 00 39 82    bra.l    $3a9c  ; -> handler_05
  00011e:  4e 71                nop      
disp_06:
  000120:  00 00 1a 9c          dc.l     $00001A9C  ; dispatch #6, Am29000 cmd/offset $1A9C
L124:
  000124:  2f 08                move.l   a0, -(a7)
  000126:  20 78 08 88          movea.l  $888.w, a0
  00012a:  20 50                movea.l  (a0), a0
  00012c:  2f 00                move.l   d0, -(a7)
  00012e:  20 10                move.l   (a0), d0
  000130:  e1 88                lsl.l    #$8, d0
  000132:  e0 88                lsr.l    #$8, d0
  000134:  20 40                movea.l  d0, a0
  000136:  20 1f                move.l   (a7)+, d0
  000138:  41 e8 00 14          lea.l    $14(a0), a0
  00013c:  2f 28 00 18          move.l   $18(a0), -(a7)
  000140:  20 6f 00 04          movea.l  $4(a7), a0
  000144:  2e 9f                move.l   (a7)+, (a7)
  000146:  4e 75                rts      
  000148:  60 ff 00 00 31 72    bra.l    $32bc  ; -> handler_06
  00014e:  4e 71                nop      
disp_07:
  000150:  00 00 08 00          dc.l     $00000800  ; dispatch #7, Am29000 cmd/offset $800
L154:
  000154:  2f 08                move.l   a0, -(a7)
  000156:  20 78 08 88          movea.l  $888.w, a0
  00015a:  20 50                movea.l  (a0), a0
  00015c:  2f 00                move.l   d0, -(a7)
  00015e:  20 10                move.l   (a0), d0
  000160:  e1 88                lsl.l    #$8, d0
  000162:  e0 88                lsr.l    #$8, d0
  000164:  20 40                movea.l  d0, a0
  000166:  20 1f                move.l   (a7)+, d0
  000168:  41 e8 00 14          lea.l    $14(a0), a0
  00016c:  2f 28 00 1c          move.l   $1c(a0), -(a7)
  000170:  20 6f 00 04          movea.l  $4(a7), a0
  000174:  2e 9f                move.l   (a7)+, (a7)
  000176:  4e 75                rts      
  000178:  60 ff 00 00 41 3e    bra.l    $42b8  ; -> handler_07
  00017e:  4e 71                nop      
disp_08:
  000180:  00 00 08 04          dc.l     $00000804  ; dispatch #8, Am29000 cmd/offset $804
L184:
  000184:  2f 08                move.l   a0, -(a7)
  000186:  20 78 08 88          movea.l  $888.w, a0
  00018a:  20 50                movea.l  (a0), a0
  00018c:  2f 00                move.l   d0, -(a7)
  00018e:  20 10                move.l   (a0), d0
  000190:  e1 88                lsl.l    #$8, d0
  000192:  e0 88                lsr.l    #$8, d0
  000194:  20 40                movea.l  d0, a0
  000196:  20 1f                move.l   (a7)+, d0
  000198:  41 e8 00 14          lea.l    $14(a0), a0
  00019c:  2f 28 00 20          move.l   $20(a0), -(a7)
  0001a0:  20 6f 00 04          movea.l  $4(a7), a0
  0001a4:  2e 9f                move.l   (a7)+, (a7)
  0001a6:  4e 75                rts      
  0001a8:  60 ff 00 00 40 62    bra.l    $420c  ; -> handler_08
  0001ae:  4e 71                nop      
disp_09:
  0001b0:  00 00 08 08          dc.l     $00000808  ; dispatch #9, Am29000 cmd/offset $808
L1b4:
  0001b4:  2f 08                move.l   a0, -(a7)
  0001b6:  20 78 08 88          movea.l  $888.w, a0
  0001ba:  20 50                movea.l  (a0), a0
  0001bc:  2f 00                move.l   d0, -(a7)
  0001be:  20 10                move.l   (a0), d0
  0001c0:  e1 88                lsl.l    #$8, d0
  0001c2:  e0 88                lsr.l    #$8, d0
  0001c4:  20 40                movea.l  d0, a0
  0001c6:  20 1f                move.l   (a7)+, d0
  0001c8:  41 e8 00 14          lea.l    $14(a0), a0
  0001cc:  2f 28 00 24          move.l   $24(a0), -(a7)
  0001d0:  20 6f 00 04          movea.l  $4(a7), a0
  0001d4:  2e 9f                move.l   (a7)+, (a7)
  0001d6:  4e 75                rts      
  0001d8:  60 ff 00 00 42 ea    bra.l    $44c4  ; -> handler_09
  0001de:  4e 71                nop      
disp_10:
  0001e0:  00 00 1c 68          dc.l     $00001C68  ; dispatch #10, Am29000 cmd/offset $1C68
L1e4:
  0001e4:  2f 08                move.l   a0, -(a7)
  0001e6:  20 78 08 88          movea.l  $888.w, a0
  0001ea:  20 50                movea.l  (a0), a0
  0001ec:  2f 00                move.l   d0, -(a7)
  0001ee:  20 10                move.l   (a0), d0
  0001f0:  e1 88                lsl.l    #$8, d0
  0001f2:  e0 88                lsr.l    #$8, d0
  0001f4:  20 40                movea.l  d0, a0
  0001f6:  20 1f                move.l   (a7)+, d0
  0001f8:  41 e8 00 14          lea.l    $14(a0), a0
  0001fc:  2f 28 00 28          move.l   $28(a0), -(a7)
  000200:  20 6f 00 04          movea.l  $4(a7), a0
  000204:  2e 9f                move.l   (a7)+, (a7)
  000206:  4e 75                rts      
  000208:  60 ff 00 00 90 6e    bra.l    $9278  ; -> handler_10
  00020e:  4e 71                nop      
disp_11:
  000210:  00 00 10 64          dc.l     $00001064  ; dispatch #11, Am29000 cmd/offset $1064
L214:
  000214:  2f 08                move.l   a0, -(a7)
  000216:  20 78 08 88          movea.l  $888.w, a0
  00021a:  20 50                movea.l  (a0), a0
  00021c:  2f 00                move.l   d0, -(a7)
  00021e:  20 10                move.l   (a0), d0
  000220:  e1 88                lsl.l    #$8, d0
  000222:  e0 88                lsr.l    #$8, d0
  000224:  20 40                movea.l  d0, a0
  000226:  20 1f                move.l   (a7)+, d0
  000228:  41 e8 00 14          lea.l    $14(a0), a0
  00022c:  2f 28 00 2c          move.l   $2c(a0), -(a7)
  000230:  20 6f 00 04          movea.l  $4(a7), a0
  000234:  2e 9f                move.l   (a7)+, (a7)
  000236:  4e 75                rts      
  000238:  60 ff 00 00 9c ca    bra.l    $9f04  ; -> handler_11
  00023e:  4e 71                nop      
disp_12:
  000240:  00 00 10 6c          dc.l     $0000106C  ; dispatch #12, Am29000 cmd/offset $106C
L244:
  000244:  2f 08                move.l   a0, -(a7)
  000246:  20 78 08 88          movea.l  $888.w, a0
  00024a:  20 50                movea.l  (a0), a0
  00024c:  2f 00                move.l   d0, -(a7)
  00024e:  20 10                move.l   (a0), d0
  000250:  e1 88                lsl.l    #$8, d0
  000252:  e0 88                lsr.l    #$8, d0
  000254:  20 40                movea.l  d0, a0
  000256:  20 1f                move.l   (a7)+, d0
  000258:  41 e8 00 14          lea.l    $14(a0), a0
  00025c:  2f 28 00 30          move.l   $30(a0), -(a7)
  000260:  20 6f 00 04          movea.l  $4(a7), a0
  000264:  2e 9f                move.l   (a7)+, (a7)
  000266:  4e 75                rts      
  000268:  60 ff 00 00 9d 66    bra.l    $9fd0  ; -> handler_12
  00026e:  4e 71                nop      
disp_13:
  000270:  00 00 10 70          dc.l     $00001070  ; dispatch #13, Am29000 cmd/offset $1070
L274:
  000274:  2f 08                move.l   a0, -(a7)
  000276:  20 78 08 88          movea.l  $888.w, a0
  00027a:  20 50                movea.l  (a0), a0
  00027c:  2f 00                move.l   d0, -(a7)
  00027e:  20 10                move.l   (a0), d0
  000280:  e1 88                lsl.l    #$8, d0
  000282:  e0 88                lsr.l    #$8, d0
  000284:  20 40                movea.l  d0, a0
  000286:  20 1f                move.l   (a7)+, d0
  000288:  41 e8 00 14          lea.l    $14(a0), a0
  00028c:  2f 28 00 34          move.l   $34(a0), -(a7)
  000290:  20 6f 00 04          movea.l  $4(a7), a0
  000294:  2e 9f                move.l   (a7)+, (a7)
  000296:  4e 75                rts      
  000298:  60 ff 00 00 9d c6    bra.l    $a060  ; -> handler_13
  00029e:  4e 71                nop      
disp_14:
  0002a0:  00 00 10 78          dc.l     $00001078  ; dispatch #14, Am29000 cmd/offset $1078
L2a4:
  0002a4:  2f 08                move.l   a0, -(a7)
  0002a6:  20 78 08 88          movea.l  $888.w, a0
  0002aa:  20 50                movea.l  (a0), a0
  0002ac:  2f 00                move.l   d0, -(a7)
  0002ae:  20 10                move.l   (a0), d0
  0002b0:  e1 88                lsl.l    #$8, d0
  0002b2:  e0 88                lsr.l    #$8, d0
  0002b4:  20 40                movea.l  d0, a0
  0002b6:  20 1f                move.l   (a7)+, d0
  0002b8:  41 e8 00 14          lea.l    $14(a0), a0
  0002bc:  2f 28 00 38          move.l   $38(a0), -(a7)
  0002c0:  20 6f 00 04          movea.l  $4(a7), a0
  0002c4:  2e 9f                move.l   (a7)+, (a7)
  0002c6:  4e 75                rts      
  0002c8:  60 ff 00 00 9f 18    bra.l    $a1e2  ; -> handler_14
  0002ce:  4e 71                nop      
disp_15:
  0002d0:  00 00 1a 8c          dc.l     $00001A8C  ; dispatch #15, Am29000 cmd/offset $1A8C
L2d4:
  0002d4:  2f 08                move.l   a0, -(a7)
  0002d6:  20 78 08 88          movea.l  $888.w, a0
  0002da:  20 50                movea.l  (a0), a0
  0002dc:  2f 00                move.l   d0, -(a7)
  0002de:  20 10                move.l   (a0), d0
  0002e0:  e1 88                lsl.l    #$8, d0
  0002e2:  e0 88                lsr.l    #$8, d0
  0002e4:  20 40                movea.l  d0, a0
  0002e6:  20 1f                move.l   (a7)+, d0
  0002e8:  41 e8 00 14          lea.l    $14(a0), a0
  0002ec:  2f 28 00 3c          move.l   $3c(a0), -(a7)
  0002f0:  20 6f 00 04          movea.l  $4(a7), a0
  0002f4:  2e 9f                move.l   (a7)+, (a7)
  0002f6:  4e 75                rts      
  0002f8:  60 ff 00 00 7a b2    bra.l    $7dac  ; -> handler_15
  0002fe:  4e 71                nop      
disp_16:
  000300:  00 00 0f 88          dc.l     $00000F88  ; dispatch #16, Am29000 cmd/offset $F88
L304:
  000304:  2f 08                move.l   a0, -(a7)
  000306:  20 78 08 88          movea.l  $888.w, a0
  00030a:  20 50                movea.l  (a0), a0
  00030c:  2f 00                move.l   d0, -(a7)
  00030e:  20 10                move.l   (a0), d0
  000310:  e1 88                lsl.l    #$8, d0
  000312:  e0 88                lsr.l    #$8, d0
  000314:  20 40                movea.l  d0, a0
  000316:  20 1f                move.l   (a7)+, d0
  000318:  41 e8 00 14          lea.l    $14(a0), a0
  00031c:  2f 28 00 40          move.l   $40(a0), -(a7)
  000320:  20 6f 00 04          movea.l  $4(a7), a0
  000324:  2e 9f                move.l   (a7)+, (a7)
  000326:  4e 75                rts      
  000328:  60 ff 00 00 aa c6    bra.l    $adf0  ; -> handler_16
  00032e:  4e 71                nop      
disp_17:
  000330:  00 00 16 50          dc.l     $00001650  ; dispatch #17, Am29000 cmd/offset $1650
L334:
  000334:  2f 08                move.l   a0, -(a7)
  000336:  20 78 08 88          movea.l  $888.w, a0
  00033a:  20 50                movea.l  (a0), a0
  00033c:  2f 00                move.l   d0, -(a7)
  00033e:  20 10                move.l   (a0), d0
  000340:  e1 88                lsl.l    #$8, d0
  000342:  e0 88                lsr.l    #$8, d0
  000344:  20 40                movea.l  d0, a0
  000346:  20 1f                move.l   (a7)+, d0
  000348:  41 e8 00 14          lea.l    $14(a0), a0
  00034c:  2f 28 00 44          move.l   $44(a0), -(a7)
  000350:  20 6f 00 04          movea.l  $4(a7), a0
  000354:  2e 9f                move.l   (a7)+, (a7)
  000356:  4e 75                rts      
  000358:  60 ff 00 00 aa fc    bra.l    $ae56  ; -> handler_17
  00035e:  4e 71                nop      
disp_18:
  000360:  00 00 18 5c          dc.l     $0000185C  ; dispatch #18, Am29000 cmd/offset $185C
L364:
  000364:  2f 08                move.l   a0, -(a7)
  000366:  20 78 08 88          movea.l  $888.w, a0
  00036a:  20 50                movea.l  (a0), a0
  00036c:  2f 00                move.l   d0, -(a7)
  00036e:  20 10                move.l   (a0), d0
  000370:  e1 88                lsl.l    #$8, d0
  000372:  e0 88                lsr.l    #$8, d0
  000374:  20 40                movea.l  d0, a0
  000376:  20 1f                move.l   (a7)+, d0
  000378:  41 e8 00 14          lea.l    $14(a0), a0
  00037c:  2f 28 00 48          move.l   $48(a0), -(a7)
  000380:  20 6f 00 04          movea.l  $4(a7), a0
  000384:  2e 9f                move.l   (a7)+, (a7)
  000386:  4e 75                rts      
  000388:  60 ff 00 00 ab 76    bra.l    $af00  ; -> handler_18
  00038e:  4e 71                nop      
disp_19:
  000390:  00 00 18 60          dc.l     $00001860  ; dispatch #19, Am29000 cmd/offset $1860
L394:
  000394:  2f 08                move.l   a0, -(a7)
  000396:  20 78 08 88          movea.l  $888.w, a0
  00039a:  20 50                movea.l  (a0), a0
  00039c:  2f 00                move.l   d0, -(a7)
  00039e:  20 10                move.l   (a0), d0
  0003a0:  e1 88                lsl.l    #$8, d0
  0003a2:  e0 88                lsr.l    #$8, d0
  0003a4:  20 40                movea.l  d0, a0
  0003a6:  20 1f                move.l   (a7)+, d0
  0003a8:  41 e8 00 14          lea.l    $14(a0), a0
  0003ac:  2f 28 00 4c          move.l   $4c(a0), -(a7)
  0003b0:  20 6f 00 04          movea.l  $4(a7), a0
  0003b4:  2e 9f                move.l   (a7)+, (a7)
  0003b6:  4e 75                rts      
  0003b8:  60 ff 00 00 ac f6    bra.l    $b0b0  ; -> handler_19
  0003be:  4e 71                nop      
disp_20:
  0003c0:  00 00 10 80          dc.l     $00001080  ; dispatch #20, Am29000 cmd/offset $1080
L3c4:
  0003c4:  2f 08                move.l   a0, -(a7)
  0003c6:  20 78 08 88          movea.l  $888.w, a0
  0003ca:  20 50                movea.l  (a0), a0
  0003cc:  2f 00                move.l   d0, -(a7)
  0003ce:  20 10                move.l   (a0), d0
  0003d0:  e1 88                lsl.l    #$8, d0
  0003d2:  e0 88                lsr.l    #$8, d0
  0003d4:  20 40                movea.l  d0, a0
  0003d6:  20 1f                move.l   (a7)+, d0
  0003d8:  41 e8 00 14          lea.l    $14(a0), a0
  0003dc:  2f 28 00 50          move.l   $50(a0), -(a7)
  0003e0:  20 6f 00 04          movea.l  $4(a7), a0
  0003e4:  2e 9f                move.l   (a7)+, (a7)
  0003e6:  4e 75                rts      
  0003e8:  60 ff 00 00 3d 2c    bra.l    $4116  ; -> handler_20
  0003ee:  4e 71                nop      
disp_21:
  0003f0:  00 00 10 d8          dc.l     $000010D8  ; dispatch #21, Am29000 cmd/offset $10D8
L3f4:
  0003f4:  2f 08                move.l   a0, -(a7)
  0003f6:  20 78 08 88          movea.l  $888.w, a0
  0003fa:  20 50                movea.l  (a0), a0
  0003fc:  2f 00                move.l   d0, -(a7)
  0003fe:  20 10                move.l   (a0), d0
  000400:  e1 88                lsl.l    #$8, d0
  000402:  e0 88                lsr.l    #$8, d0
  000404:  20 40                movea.l  d0, a0
  000406:  20 1f                move.l   (a7)+, d0
  000408:  41 e8 00 14          lea.l    $14(a0), a0
  00040c:  2f 28 00 54          move.l   $54(a0), -(a7)
  000410:  20 6f 00 04          movea.l  $4(a7), a0
  000414:  2e 9f                move.l   (a7)+, (a7)
  000416:  4e 75                rts      
  000418:  60 ff 00 00 3c 06    bra.l    $4020  ; -> handler_21
  00041e:  4e 71                nop      
disp_22:
  000420:  00 00 10 bc          dc.l     $000010BC  ; dispatch #22, Am29000 cmd/offset $10BC
L424:
  000424:  2f 08                move.l   a0, -(a7)
  000426:  20 78 08 88          movea.l  $888.w, a0
  00042a:  20 50                movea.l  (a0), a0
  00042c:  2f 00                move.l   d0, -(a7)
  00042e:  20 10                move.l   (a0), d0
  000430:  e1 88                lsl.l    #$8, d0
  000432:  e0 88                lsr.l    #$8, d0
  000434:  20 40                movea.l  d0, a0
  000436:  20 1f                move.l   (a7)+, d0
  000438:  41 e8 00 14          lea.l    $14(a0), a0
  00043c:  2f 28 00 58          move.l   $58(a0), -(a7)
  000440:  20 6f 00 04          movea.l  $4(a7), a0
  000444:  2e 9f                move.l   (a7)+, (a7)
  000446:  4e 75                rts      
  000448:  60 ff 00 00 3a b0    bra.l    $3efa  ; -> handler_22
  00044e:  4e 71                nop      
disp_23:
  000450:  00 00 11 14          dc.l     $00001114  ; dispatch #23, Am29000 cmd/offset $1114
L454:
  000454:  2f 08                move.l   a0, -(a7)
  000456:  20 78 08 88          movea.l  $888.w, a0
  00045a:  20 50                movea.l  (a0), a0
  00045c:  2f 00                move.l   d0, -(a7)
  00045e:  20 10                move.l   (a0), d0
  000460:  e1 88                lsl.l    #$8, d0
  000462:  e0 88                lsr.l    #$8, d0
  000464:  20 40                movea.l  d0, a0
  000466:  20 1f                move.l   (a7)+, d0
  000468:  41 e8 00 14          lea.l    $14(a0), a0
  00046c:  2f 28 00 5c          move.l   $5c(a0), -(a7)
  000470:  20 6f 00 04          movea.l  $4(a7), a0
  000474:  2e 9f                move.l   (a7)+, (a7)
  000476:  4e 75                rts      
  000478:  60 ff 00 00 32 f2    bra.l    $376c  ; -> handler_23
  00047e:  4e 71                nop      
disp_24:
  000480:  00 00 11 44          dc.l     $00001144  ; dispatch #24, Am29000 cmd/offset $1144
L484:
  000484:  2f 08                move.l   a0, -(a7)
  000486:  20 78 08 88          movea.l  $888.w, a0
  00048a:  20 50                movea.l  (a0), a0
  00048c:  2f 00                move.l   d0, -(a7)
  00048e:  20 10                move.l   (a0), d0
  000490:  e1 88                lsl.l    #$8, d0
  000492:  e0 88                lsr.l    #$8, d0
  000494:  20 40                movea.l  d0, a0
  000496:  20 1f                move.l   (a7)+, d0
  000498:  41 e8 00 14          lea.l    $14(a0), a0
  00049c:  2f 28 00 60          move.l   $60(a0), -(a7)
  0004a0:  20 6f 00 04          movea.l  $4(a7), a0
  0004a4:  2e 9f                move.l   (a7)+, (a7)
  0004a6:  4e 75                rts      
  0004a8:  60 ff 00 00 30 e2    bra.l    $358c  ; -> handler_24
  0004ae:  4e 71                nop      
disp_25:
  0004b0:  00 00 16 e8          dc.l     $000016E8  ; dispatch #25, Am29000 cmd/offset $16E8
L4b4:
  0004b4:  2f 08                move.l   a0, -(a7)
  0004b6:  20 78 08 88          movea.l  $888.w, a0
  0004ba:  20 50                movea.l  (a0), a0
  0004bc:  2f 00                move.l   d0, -(a7)
  0004be:  20 10                move.l   (a0), d0
  0004c0:  e1 88                lsl.l    #$8, d0
  0004c2:  e0 88                lsr.l    #$8, d0
  0004c4:  20 40                movea.l  d0, a0
  0004c6:  20 1f                move.l   (a7)+, d0
  0004c8:  41 e8 00 14          lea.l    $14(a0), a0
  0004cc:  2f 28 00 64          move.l   $64(a0), -(a7)
  0004d0:  20 6f 00 04          movea.l  $4(a7), a0
  0004d4:  2e 9f                move.l   (a7)+, (a7)
  0004d6:  4e 75                rts      
  0004d8:  60 ff 00 00 91 de    bra.l    $96b8  ; -> handler_25
  0004de:  4e 71                nop      
disp_26:
  0004e0:  00 00 17 30          dc.l     $00001730  ; dispatch #26, Am29000 cmd/offset $1730
L4e4:
  0004e4:  2f 08                move.l   a0, -(a7)
  0004e6:  20 78 08 88          movea.l  $888.w, a0
  0004ea:  20 50                movea.l  (a0), a0
  0004ec:  2f 00                move.l   d0, -(a7)
  0004ee:  20 10                move.l   (a0), d0
  0004f0:  e1 88                lsl.l    #$8, d0
  0004f2:  e0 88                lsr.l    #$8, d0
  0004f4:  20 40                movea.l  d0, a0
  0004f6:  20 1f                move.l   (a7)+, d0
  0004f8:  41 e8 00 14          lea.l    $14(a0), a0
  0004fc:  2f 28 00 68          move.l   $68(a0), -(a7)
  000500:  20 6f 00 04          movea.l  $4(a7), a0
  000504:  2e 9f                move.l   (a7)+, (a7)
  000506:  4e 75                rts      
  000508:  60 ff 00 00 92 8a    bra.l    $9794  ; -> handler_26
  00050e:  4e 71                nop      
disp_27:
  000510:  00 00 16 ec          dc.l     $000016EC  ; dispatch #27, Am29000 cmd/offset $16EC
L514:
  000514:  2f 08                move.l   a0, -(a7)
  000516:  20 78 08 88          movea.l  $888.w, a0
  00051a:  20 50                movea.l  (a0), a0
  00051c:  2f 00                move.l   d0, -(a7)
  00051e:  20 10                move.l   (a0), d0
  000520:  e1 88                lsl.l    #$8, d0
  000522:  e0 88                lsr.l    #$8, d0
  000524:  20 40                movea.l  d0, a0
  000526:  20 1f                move.l   (a7)+, d0
  000528:  41 e8 00 14          lea.l    $14(a0), a0
  00052c:  2f 28 00 6c          move.l   $6c(a0), -(a7)
  000530:  20 6f 00 04          movea.l  $4(a7), a0
  000534:  2e 9f                move.l   (a7)+, (a7)
  000536:  4e 75                rts      
  000538:  60 ff 00 00 92 a8    bra.l    $97e2  ; -> handler_27
  00053e:  4e 71                nop      
disp_28:
  000540:  00 00 17 34          dc.l     $00001734  ; dispatch #28, Am29000 cmd/offset $1734
L544:
  000544:  2f 08                move.l   a0, -(a7)
  000546:  20 78 08 88          movea.l  $888.w, a0
  00054a:  20 50                movea.l  (a0), a0
  00054c:  2f 00                move.l   d0, -(a7)
  00054e:  20 10                move.l   (a0), d0
  000550:  e1 88                lsl.l    #$8, d0
  000552:  e0 88                lsr.l    #$8, d0
  000554:  20 40                movea.l  d0, a0
  000556:  20 1f                move.l   (a7)+, d0
  000558:  41 e8 00 14          lea.l    $14(a0), a0
  00055c:  2f 28 00 70          move.l   $70(a0), -(a7)
  000560:  20 6f 00 04          movea.l  $4(a7), a0
  000564:  2e 9f                move.l   (a7)+, (a7)
  000566:  4e 75                rts      
  000568:  60 ff 00 00 92 c6    bra.l    $9830  ; -> handler_28
  00056e:  4e 71                nop      
disp_29:
  000570:  00 00 16 20          dc.l     $00001620  ; dispatch #29, Am29000 cmd/offset $1620
L574:
  000574:  2f 08                move.l   a0, -(a7)
  000576:  20 78 08 88          movea.l  $888.w, a0
  00057a:  20 50                movea.l  (a0), a0
  00057c:  2f 00                move.l   d0, -(a7)
  00057e:  20 10                move.l   (a0), d0
  000580:  e1 88                lsl.l    #$8, d0
  000582:  e0 88                lsr.l    #$8, d0
  000584:  20 40                movea.l  d0, a0
  000586:  20 1f                move.l   (a7)+, d0
  000588:  41 e8 00 14          lea.l    $14(a0), a0
  00058c:  2f 28 00 74          move.l   $74(a0), -(a7)
  000590:  20 6f 00 04          movea.l  $4(a7), a0
  000594:  2e 9f                move.l   (a7)+, (a7)
  000596:  4e 75                rts      
  000598:  60 ff 00 00 92 e4    bra.l    $987e  ; -> handler_29
  00059e:  4e 71                nop      
disp_30:
  0005a0:  00 00 16 24          dc.l     $00001624  ; dispatch #30, Am29000 cmd/offset $1624
L5a4:
  0005a4:  2f 08                move.l   a0, -(a7)
  0005a6:  20 78 08 88          movea.l  $888.w, a0
  0005aa:  20 50                movea.l  (a0), a0
  0005ac:  2f 00                move.l   d0, -(a7)
  0005ae:  20 10                move.l   (a0), d0
  0005b0:  e1 88                lsl.l    #$8, d0
  0005b2:  e0 88                lsr.l    #$8, d0
  0005b4:  20 40                movea.l  d0, a0
  0005b6:  20 1f                move.l   (a7)+, d0
  0005b8:  41 e8 00 14          lea.l    $14(a0), a0
  0005bc:  2f 28 00 78          move.l   $78(a0), -(a7)
  0005c0:  20 6f 00 04          movea.l  $4(a7), a0
  0005c4:  2e 9f                move.l   (a7)+, (a7)
  0005c6:  4e 75                rts      
  0005c8:  60 ff 00 00 92 e8    bra.l    $98b2  ; -> handler_30
  0005ce:  4e 71                nop      
disp_31:
  0005d0:  00 00 16 34          dc.l     $00001634  ; dispatch #31, Am29000 cmd/offset $1634
L5d4:
  0005d4:  2f 08                move.l   a0, -(a7)
  0005d6:  20 78 08 88          movea.l  $888.w, a0
  0005da:  20 50                movea.l  (a0), a0
  0005dc:  2f 00                move.l   d0, -(a7)
  0005de:  20 10                move.l   (a0), d0
  0005e0:  e1 88                lsl.l    #$8, d0
  0005e2:  e0 88                lsr.l    #$8, d0
  0005e4:  20 40                movea.l  d0, a0
  0005e6:  20 1f                move.l   (a7)+, d0
  0005e8:  41 e8 00 14          lea.l    $14(a0), a0
  0005ec:  2f 28 00 7c          move.l   $7c(a0), -(a7)
  0005f0:  20 6f 00 04          movea.l  $4(a7), a0
  0005f4:  2e 9f                move.l   (a7)+, (a7)
  0005f6:  4e 75                rts      
  0005f8:  60 ff 00 00 93 4e    bra.l    $9948  ; -> handler_31
  0005fe:  4e 71                nop      
disp_32:
  000600:  00 00 1a 44          dc.l     $00001A44  ; dispatch #32, Am29000 cmd/offset $1A44
L604:
  000604:  2f 08                move.l   a0, -(a7)
  000606:  20 78 08 88          movea.l  $888.w, a0
  00060a:  20 50                movea.l  (a0), a0
  00060c:  2f 00                move.l   d0, -(a7)
  00060e:  20 10                move.l   (a0), d0
  000610:  e1 88                lsl.l    #$8, d0
  000612:  e0 88                lsr.l    #$8, d0
  000614:  20 40                movea.l  d0, a0
  000616:  20 1f                move.l   (a7)+, d0
  000618:  41 e8 00 14          lea.l    $14(a0), a0
  00061c:  2f 28 00 80          move.l   $80(a0), -(a7)
  000620:  20 6f 00 04          movea.l  $4(a7), a0
  000624:  2e 9f                move.l   (a7)+, (a7)
  000626:  4e 75                rts      
  000628:  60 ff 00 00 93 ac    bra.l    $99d6  ; -> handler_32
  00062e:  4e 71                nop      
disp_33:
  000630:  00 00 0f d4          dc.l     $00000FD4  ; dispatch #33, Am29000 cmd/offset $FD4
L634:
  000634:  2f 08                move.l   a0, -(a7)
  000636:  20 78 08 88          movea.l  $888.w, a0
  00063a:  20 50                movea.l  (a0), a0
  00063c:  2f 00                move.l   d0, -(a7)
  00063e:  20 10                move.l   (a0), d0
  000640:  e1 88                lsl.l    #$8, d0
  000642:  e0 88                lsr.l    #$8, d0
  000644:  20 40                movea.l  d0, a0
  000646:  20 1f                move.l   (a7)+, d0
  000648:  41 e8 00 14          lea.l    $14(a0), a0
  00064c:  2f 28 00 84          move.l   $84(a0), -(a7)
  000650:  20 6f 00 04          movea.l  $4(a7), a0
  000654:  2e 9f                move.l   (a7)+, (a7)
  000656:  4e 75                rts      
  000658:  60 ff 00 00 95 70    bra.l    $9bca  ; -> handler_33
  00065e:  4e 71                nop      
disp_34:
  000660:  00 00 0f d8          dc.l     $00000FD8  ; dispatch #34, Am29000 cmd/offset $FD8
L664:
  000664:  2f 08                move.l   a0, -(a7)
  000666:  20 78 08 88          movea.l  $888.w, a0
  00066a:  20 50                movea.l  (a0), a0
  00066c:  2f 00                move.l   d0, -(a7)
  00066e:  20 10                move.l   (a0), d0
  000670:  e1 88                lsl.l    #$8, d0
  000672:  e0 88                lsr.l    #$8, d0
  000674:  20 40                movea.l  d0, a0
  000676:  20 1f                move.l   (a7)+, d0
  000678:  41 e8 00 14          lea.l    $14(a0), a0
  00067c:  2f 28 00 88          move.l   $88(a0), -(a7)
  000680:  20 6f 00 04          movea.l  $4(a7), a0
  000684:  2e 9f                move.l   (a7)+, (a7)
  000686:  4e 75                rts      
  000688:  60 ff 00 00 95 d8    bra.l    $9c62  ; -> handler_34
  00068e:  4e 71                nop      
disp_35:
  000690:  00 00 0f dc          dc.l     $00000FDC  ; dispatch #35, Am29000 cmd/offset $FDC
L694:
  000694:  2f 08                move.l   a0, -(a7)
  000696:  20 78 08 88          movea.l  $888.w, a0
  00069a:  20 50                movea.l  (a0), a0
  00069c:  2f 00                move.l   d0, -(a7)
  00069e:  20 10                move.l   (a0), d0
  0006a0:  e1 88                lsl.l    #$8, d0
  0006a2:  e0 88                lsr.l    #$8, d0
  0006a4:  20 40                movea.l  d0, a0
  0006a6:  20 1f                move.l   (a7)+, d0
  0006a8:  41 e8 00 14          lea.l    $14(a0), a0
  0006ac:  2f 28 00 8c          move.l   $8c(a0), -(a7)
  0006b0:  20 6f 00 04          movea.l  $4(a7), a0
  0006b4:  2e 9f                move.l   (a7)+, (a7)
  0006b6:  4e 75                rts      
  0006b8:  60 ff 00 00 96 38    bra.l    $9cf2  ; -> handler_35
  0006be:  4e 71                nop      
disp_36:
  0006c0:  00 00 0f e0          dc.l     $00000FE0  ; dispatch #36, Am29000 cmd/offset $FE0
L6c4:
  0006c4:  2f 08                move.l   a0, -(a7)
  0006c6:  20 78 08 88          movea.l  $888.w, a0
  0006ca:  20 50                movea.l  (a0), a0
  0006cc:  2f 00                move.l   d0, -(a7)
  0006ce:  20 10                move.l   (a0), d0
  0006d0:  e1 88                lsl.l    #$8, d0
  0006d2:  e0 88                lsr.l    #$8, d0
  0006d4:  20 40                movea.l  d0, a0
  0006d6:  20 1f                move.l   (a7)+, d0
  0006d8:  41 e8 00 14          lea.l    $14(a0), a0
  0006dc:  2f 28 00 90          move.l   $90(a0), -(a7)
  0006e0:  20 6f 00 04          movea.l  $4(a7), a0
  0006e4:  2e 9f                move.l   (a7)+, (a7)
  0006e6:  4e 75                rts      
  0006e8:  60 ff 00 00 96 62    bra.l    $9d4c  ; -> handler_36
  0006ee:  4e 71                nop      
disp_37:
  0006f0:  00 00 0f e4          dc.l     $00000FE4  ; dispatch #37, Am29000 cmd/offset $FE4
L6f4:
  0006f4:  2f 08                move.l   a0, -(a7)
  0006f6:  20 78 08 88          movea.l  $888.w, a0
  0006fa:  20 50                movea.l  (a0), a0
  0006fc:  2f 00                move.l   d0, -(a7)
  0006fe:  20 10                move.l   (a0), d0
  000700:  e1 88                lsl.l    #$8, d0
  000702:  e0 88                lsr.l    #$8, d0
  000704:  20 40                movea.l  d0, a0
  000706:  20 1f                move.l   (a7)+, d0
  000708:  41 e8 00 14          lea.l    $14(a0), a0
  00070c:  2f 28 00 94          move.l   $94(a0), -(a7)
  000710:  20 6f 00 04          movea.l  $4(a7), a0
  000714:  2e 9f                move.l   (a7)+, (a7)
  000716:  4e 75                rts      
  000718:  60 ff 00 00 96 a4    bra.l    $9dbe  ; -> handler_37
  00071e:  4e 71                nop      
disp_38:
  000720:  00 00 0f ec          dc.l     $00000FEC  ; dispatch #38, Am29000 cmd/offset $FEC
L724:
  000724:  2f 08                move.l   a0, -(a7)
  000726:  20 78 08 88          movea.l  $888.w, a0
  00072a:  20 50                movea.l  (a0), a0
  00072c:  2f 00                move.l   d0, -(a7)
  00072e:  20 10                move.l   (a0), d0
  000730:  e1 88                lsl.l    #$8, d0
  000732:  e0 88                lsr.l    #$8, d0
  000734:  20 40                movea.l  d0, a0
  000736:  20 1f                move.l   (a7)+, d0
  000738:  41 e8 00 14          lea.l    $14(a0), a0
  00073c:  2f 28 00 98          move.l   $98(a0), -(a7)
  000740:  20 6f 00 04          movea.l  $4(a7), a0
  000744:  2e 9f                move.l   (a7)+, (a7)
  000746:  4e 75                rts      
  000748:  60 ff 00 00 96 ea    bra.l    $9e34  ; -> handler_38
  00074e:  4e 71                nop      
disp_39:
  000750:  00 00 10 58          dc.l     $00001058  ; dispatch #39, Am29000 cmd/offset $1058
L754:
  000754:  2f 08                move.l   a0, -(a7)
  000756:  20 78 08 88          movea.l  $888.w, a0
  00075a:  20 50                movea.l  (a0), a0
  00075c:  2f 00                move.l   d0, -(a7)
  00075e:  20 10                move.l   (a0), d0
  000760:  e1 88                lsl.l    #$8, d0
  000762:  e0 88                lsr.l    #$8, d0
  000764:  20 40                movea.l  d0, a0
  000766:  20 1f                move.l   (a7)+, d0
  000768:  41 e8 00 14          lea.l    $14(a0), a0
  00076c:  2f 28 00 9c          move.l   $9c(a0), -(a7)
  000770:  20 6f 00 04          movea.l  $4(a7), a0
  000774:  2e 9f                move.l   (a7)+, (a7)
  000776:  4e 75                rts      
  000778:  60 ff 00 00 97 56    bra.l    $9ed0  ; -> handler_39
  00077e:  4e 71                nop      
disp_40:
  000780:  00 00 10 5c          dc.l     $0000105C  ; dispatch #40, Am29000 cmd/offset $105C
L784:
  000784:  2f 08                move.l   a0, -(a7)
  000786:  20 78 08 88          movea.l  $888.w, a0
  00078a:  20 50                movea.l  (a0), a0
  00078c:  2f 00                move.l   d0, -(a7)
  00078e:  20 10                move.l   (a0), d0
  000790:  e1 88                lsl.l    #$8, d0
  000792:  e0 88                lsr.l    #$8, d0
  000794:  20 40                movea.l  d0, a0
  000796:  20 1f                move.l   (a7)+, d0
  000798:  41 e8 00 14          lea.l    $14(a0), a0
  00079c:  2f 28 00 a0          move.l   $a0(a0), -(a7)
  0007a0:  20 6f 00 04          movea.l  $4(a7), a0
  0007a4:  2e 9f                move.l   (a7)+, (a7)
  0007a6:  4e 75                rts      
  0007a8:  60 ff 00 00 97 40    bra.l    $9eea  ; -> handler_40
  0007ae:  4e 71                nop      
disp_41:
  0007b0:  00 00 0f 8c          dc.l     $00000F8C  ; dispatch #41, Am29000 cmd/offset $F8C
L7b4:
  0007b4:  2f 08                move.l   a0, -(a7)
  0007b6:  20 78 08 88          movea.l  $888.w, a0
  0007ba:  20 50                movea.l  (a0), a0
  0007bc:  2f 00                move.l   d0, -(a7)
  0007be:  20 10                move.l   (a0), d0
  0007c0:  e1 88                lsl.l    #$8, d0
  0007c2:  e0 88                lsr.l    #$8, d0
  0007c4:  20 40                movea.l  d0, a0
  0007c6:  20 1f                move.l   (a7)+, d0
  0007c8:  41 e8 00 14          lea.l    $14(a0), a0
  0007cc:  2f 28 00 a4          move.l   $a4(a0), -(a7)
  0007d0:  20 6f 00 04          movea.l  $4(a7), a0
  0007d4:  2e 9f                move.l   (a7)+, (a7)
  0007d6:  4e 75                rts      
  0007d8:  60 ff 00 00 a7 c6    bra.l    $afa0  ; -> handler_41
  0007de:  4e 71                nop      
disp_42:
  0007e0:  00 00 0f 90          dc.l     $00000F90  ; dispatch #42, Am29000 cmd/offset $F90
L7e4:
  0007e4:  2f 08                move.l   a0, -(a7)
  0007e6:  20 78 08 88          movea.l  $888.w, a0
  0007ea:  20 50                movea.l  (a0), a0
  0007ec:  2f 00                move.l   d0, -(a7)
  0007ee:  20 10                move.l   (a0), d0
  0007f0:  e1 88                lsl.l    #$8, d0
  0007f2:  e0 88                lsr.l    #$8, d0
  0007f4:  20 40                movea.l  d0, a0
  0007f6:  20 1f                move.l   (a7)+, d0
  0007f8:  41 e8 00 14          lea.l    $14(a0), a0
  0007fc:  2f 28 00 a8          move.l   $a8(a0), -(a7)
  000800:  20 6f 00 04          movea.l  $4(a7), a0
  000804:  2e 9f                move.l   (a7)+, (a7)
  000806:  4e 75                rts      
  000808:  60 ff 00 00 9a ae    bra.l    $a2b8  ; -> handler_42
  00080e:  4e 71                nop      
disp_43:
  000810:  00 00 11 68          dc.l     $00001168  ; dispatch #43, Am29000 cmd/offset $1168
L814:
  000814:  2f 08                move.l   a0, -(a7)
  000816:  20 78 08 88          movea.l  $888.w, a0
  00081a:  20 50                movea.l  (a0), a0
  00081c:  2f 00                move.l   d0, -(a7)
  00081e:  20 10                move.l   (a0), d0
  000820:  e1 88                lsl.l    #$8, d0
  000822:  e0 88                lsr.l    #$8, d0
  000824:  20 40                movea.l  d0, a0
  000826:  20 1f                move.l   (a7)+, d0
  000828:  41 e8 00 14          lea.l    $14(a0), a0
  00082c:  2f 28 00 ac          move.l   $ac(a0), -(a7)
  000830:  20 6f 00 04          movea.l  $4(a7), a0
  000834:  2e 9f                move.l   (a7)+, (a7)
  000836:  4e 75                rts      
  000838:  60 ff 00 00 9a e4    bra.l    $a31e  ; -> handler_43
  00083e:  4e 71                nop      
disp_44:
  000840:  00 00 11 cc          dc.l     $000011CC  ; dispatch #44, Am29000 cmd/offset $11CC
L844:
  000844:  2f 08                move.l   a0, -(a7)
  000846:  20 78 08 88          movea.l  $888.w, a0
  00084a:  20 50                movea.l  (a0), a0
  00084c:  2f 00                move.l   d0, -(a7)
  00084e:  20 10                move.l   (a0), d0
  000850:  e1 88                lsl.l    #$8, d0
  000852:  e0 88                lsr.l    #$8, d0
  000854:  20 40                movea.l  d0, a0
  000856:  20 1f                move.l   (a7)+, d0
  000858:  41 e8 00 14          lea.l    $14(a0), a0
  00085c:  2f 28 00 b0          move.l   $b0(a0), -(a7)
  000860:  20 6f 00 04          movea.l  $4(a7), a0
  000864:  2e 9f                move.l   (a7)+, (a7)
  000866:  4e 75                rts      
  000868:  60 ff 00 00 9a ce    bra.l    $a338  ; -> handler_44
  00086e:  4e 71                nop      
disp_45:
  000870:  00 00 11 2c          dc.l     $0000112C  ; dispatch #45, Am29000 cmd/offset $112C
L874:
  000874:  2f 08                move.l   a0, -(a7)
  000876:  20 78 08 88          movea.l  $888.w, a0
  00087a:  20 50                movea.l  (a0), a0
  00087c:  2f 00                move.l   d0, -(a7)
  00087e:  20 10                move.l   (a0), d0
  000880:  e1 88                lsl.l    #$8, d0
  000882:  e0 88                lsr.l    #$8, d0
  000884:  20 40                movea.l  d0, a0
  000886:  20 1f                move.l   (a7)+, d0
  000888:  41 e8 00 14          lea.l    $14(a0), a0
  00088c:  2f 28 00 b4          move.l   $b4(a0), -(a7)
  000890:  20 6f 00 04          movea.l  $4(a7), a0
  000894:  2e 9f                move.l   (a7)+, (a7)
  000896:  4e 75                rts      
  000898:  60 ff 00 00 9a c4    bra.l    $a35e  ; -> handler_45
  00089e:  4e 71                nop      
disp_46:
  0008a0:  00 00 11 70          dc.l     $00001170  ; dispatch #46, Am29000 cmd/offset $1170
L8a4:
  0008a4:  2f 08                move.l   a0, -(a7)
  0008a6:  20 78 08 88          movea.l  $888.w, a0
  0008aa:  20 50                movea.l  (a0), a0
  0008ac:  2f 00                move.l   d0, -(a7)
  0008ae:  20 10                move.l   (a0), d0
  0008b0:  e1 88                lsl.l    #$8, d0
  0008b2:  e0 88                lsr.l    #$8, d0
  0008b4:  20 40                movea.l  d0, a0
  0008b6:  20 1f                move.l   (a7)+, d0
  0008b8:  41 e8 00 14          lea.l    $14(a0), a0
  0008bc:  2f 28 00 b8          move.l   $b8(a0), -(a7)
  0008c0:  20 6f 00 04          movea.l  $4(a7), a0
  0008c4:  2e 9f                move.l   (a7)+, (a7)
  0008c6:  4e 75                rts      
  0008c8:  60 ff 00 00 9b a8    bra.l    $a472  ; -> handler_46
  0008ce:  4e 71                nop      
disp_47:
  0008d0:  00 00 11 78          dc.l     $00001178  ; dispatch #47, Am29000 cmd/offset $1178
L8d4:
  0008d4:  2f 08                move.l   a0, -(a7)
  0008d6:  20 78 08 88          movea.l  $888.w, a0
  0008da:  20 50                movea.l  (a0), a0
  0008dc:  2f 00                move.l   d0, -(a7)
  0008de:  20 10                move.l   (a0), d0
  0008e0:  e1 88                lsl.l    #$8, d0
  0008e2:  e0 88                lsr.l    #$8, d0
  0008e4:  20 40                movea.l  d0, a0
  0008e6:  20 1f                move.l   (a7)+, d0
  0008e8:  41 e8 00 14          lea.l    $14(a0), a0
  0008ec:  2f 28 00 bc          move.l   $bc(a0), -(a7)
  0008f0:  20 6f 00 04          movea.l  $4(a7), a0
  0008f4:  2e 9f                move.l   (a7)+, (a7)
  0008f6:  4e 75                rts      
  0008f8:  60 ff 00 00 9c b0    bra.l    $a5aa  ; -> handler_47
  0008fe:  4e 71                nop      
disp_48:
  000900:  00 00 11 7c          dc.l     $0000117C  ; dispatch #48, Am29000 cmd/offset $117C
L904:
  000904:  2f 08                move.l   a0, -(a7)
  000906:  20 78 08 88          movea.l  $888.w, a0
  00090a:  20 50                movea.l  (a0), a0
  00090c:  2f 00                move.l   d0, -(a7)
  00090e:  20 10                move.l   (a0), d0
  000910:  e1 88                lsl.l    #$8, d0
  000912:  e0 88                lsr.l    #$8, d0
  000914:  20 40                movea.l  d0, a0
  000916:  20 1f                move.l   (a7)+, d0
  000918:  41 e8 00 14          lea.l    $14(a0), a0
  00091c:  2f 28 00 c0          move.l   $c0(a0), -(a7)
  000920:  20 6f 00 04          movea.l  $4(a7), a0
  000924:  2e 9f                move.l   (a7)+, (a7)
  000926:  4e 75                rts      
  000928:  60 ff 00 00 9d 48    bra.l    $a672  ; -> handler_48
  00092e:  4e 71                nop      
disp_49:
  000930:  00 00 11 80          dc.l     $00001180  ; dispatch #49, Am29000 cmd/offset $1180
L934:
  000934:  2f 08                move.l   a0, -(a7)
  000936:  20 78 08 88          movea.l  $888.w, a0
  00093a:  20 50                movea.l  (a0), a0
  00093c:  2f 00                move.l   d0, -(a7)
  00093e:  20 10                move.l   (a0), d0
  000940:  e1 88                lsl.l    #$8, d0
  000942:  e0 88                lsr.l    #$8, d0
  000944:  20 40                movea.l  d0, a0
  000946:  20 1f                move.l   (a7)+, d0
  000948:  41 e8 00 14          lea.l    $14(a0), a0
  00094c:  2f 28 00 c4          move.l   $c4(a0), -(a7)
  000950:  20 6f 00 04          movea.l  $4(a7), a0
  000954:  2e 9f                move.l   (a7)+, (a7)
  000956:  4e 75                rts      
  000958:  60 ff 00 00 9d cc    bra.l    $a726  ; -> handler_49
  00095e:  4e 71                nop      
disp_50:
  000960:  00 00 11 84          dc.l     $00001184  ; dispatch #50, Am29000 cmd/offset $1184
L964:
  000964:  2f 08                move.l   a0, -(a7)
  000966:  20 78 08 88          movea.l  $888.w, a0
  00096a:  20 50                movea.l  (a0), a0
  00096c:  2f 00                move.l   d0, -(a7)
  00096e:  20 10                move.l   (a0), d0
  000970:  e1 88                lsl.l    #$8, d0
  000972:  e0 88                lsr.l    #$8, d0
  000974:  20 40                movea.l  d0, a0
  000976:  20 1f                move.l   (a7)+, d0
  000978:  41 e8 00 14          lea.l    $14(a0), a0
  00097c:  2f 28 00 c8          move.l   $c8(a0), -(a7)
  000980:  20 6f 00 04          movea.l  $4(a7), a0
  000984:  2e 9f                move.l   (a7)+, (a7)
  000986:  4e 75                rts      
  000988:  60 ff 00 00 9e 96    bra.l    $a820  ; -> handler_50
  00098e:  4e 71                nop      
disp_51:
  000990:  00 00 11 90          dc.l     $00001190  ; dispatch #51, Am29000 cmd/offset $1190
L994:
  000994:  2f 08                move.l   a0, -(a7)
  000996:  20 78 08 88          movea.l  $888.w, a0
  00099a:  20 50                movea.l  (a0), a0
  00099c:  2f 00                move.l   d0, -(a7)
  00099e:  20 10                move.l   (a0), d0
  0009a0:  e1 88                lsl.l    #$8, d0
  0009a2:  e0 88                lsr.l    #$8, d0
  0009a4:  20 40                movea.l  d0, a0
  0009a6:  20 1f                move.l   (a7)+, d0
  0009a8:  41 e8 00 14          lea.l    $14(a0), a0
  0009ac:  2f 28 00 cc          move.l   $cc(a0), -(a7)
  0009b0:  20 6f 00 04          movea.l  $4(a7), a0
  0009b4:  2e 9f                move.l   (a7)+, (a7)
  0009b6:  4e 75                rts      
  0009b8:  60 ff 00 00 9f 60    bra.l    $a91a  ; -> handler_51
  0009be:  4e 71                nop      
disp_52:
  0009c0:  00 00 11 94          dc.l     $00001194  ; dispatch #52, Am29000 cmd/offset $1194
L9c4:
  0009c4:  2f 08                move.l   a0, -(a7)
  0009c6:  20 78 08 88          movea.l  $888.w, a0
  0009ca:  20 50                movea.l  (a0), a0
  0009cc:  2f 00                move.l   d0, -(a7)
  0009ce:  20 10                move.l   (a0), d0
  0009d0:  e1 88                lsl.l    #$8, d0
  0009d2:  e0 88                lsr.l    #$8, d0
  0009d4:  20 40                movea.l  d0, a0
  0009d6:  20 1f                move.l   (a7)+, d0
  0009d8:  41 e8 00 14          lea.l    $14(a0), a0
  0009dc:  2f 28 00 d0          move.l   $d0(a0), -(a7)
  0009e0:  20 6f 00 04          movea.l  $4(a7), a0
  0009e4:  2e 9f                move.l   (a7)+, (a7)
  0009e6:  4e 75                rts      
  0009e8:  60 ff 00 00 a0 20    bra.l    $aa0a  ; -> handler_52
  0009ee:  4e 71                nop      
disp_53:
  0009f0:  00 00 11 98          dc.l     $00001198  ; dispatch #53, Am29000 cmd/offset $1198
L9f4:
  0009f4:  2f 08                move.l   a0, -(a7)
  0009f6:  20 78 08 88          movea.l  $888.w, a0
  0009fa:  20 50                movea.l  (a0), a0
  0009fc:  2f 00                move.l   d0, -(a7)
  0009fe:  20 10                move.l   (a0), d0
  000a00:  e1 88                lsl.l    #$8, d0
  000a02:  e0 88                lsr.l    #$8, d0
  000a04:  20 40                movea.l  d0, a0
  000a06:  20 1f                move.l   (a7)+, d0
  000a08:  41 e8 00 14          lea.l    $14(a0), a0
  000a0c:  2f 28 00 d4          move.l   $d4(a0), -(a7)
  000a10:  20 6f 00 04          movea.l  $4(a7), a0
  000a14:  2e 9f                move.l   (a7)+, (a7)
  000a16:  4e 75                rts      
  000a18:  60 ff 00 00 a0 e0    bra.l    $aafa  ; -> handler_53
  000a1e:  4e 71                nop      
disp_54:
  000a20:  00 00 11 9c          dc.l     $0000119C  ; dispatch #54, Am29000 cmd/offset $119C
La24:
  000a24:  2f 08                move.l   a0, -(a7)
  000a26:  20 78 08 88          movea.l  $888.w, a0
  000a2a:  20 50                movea.l  (a0), a0
  000a2c:  2f 00                move.l   d0, -(a7)
  000a2e:  20 10                move.l   (a0), d0
  000a30:  e1 88                lsl.l    #$8, d0
  000a32:  e0 88                lsr.l    #$8, d0
  000a34:  20 40                movea.l  d0, a0
  000a36:  20 1f                move.l   (a7)+, d0
  000a38:  41 e8 00 14          lea.l    $14(a0), a0
  000a3c:  2f 28 00 d8          move.l   $d8(a0), -(a7)
  000a40:  20 6f 00 04          movea.l  $4(a7), a0
  000a44:  2e 9f                move.l   (a7)+, (a7)
  000a46:  4e 75                rts      
  000a48:  60 ff 00 00 a1 a0    bra.l    $abea  ; -> handler_54
  000a4e:  4e 71                nop      
disp_55:
  000a50:  00 00 11 ec          dc.l     $000011EC  ; dispatch #55, Am29000 cmd/offset $11EC
La54:
  000a54:  2f 08                move.l   a0, -(a7)
  000a56:  20 78 08 88          movea.l  $888.w, a0
  000a5a:  20 50                movea.l  (a0), a0
  000a5c:  2f 00                move.l   d0, -(a7)
  000a5e:  20 10                move.l   (a0), d0
  000a60:  e1 88                lsl.l    #$8, d0
  000a62:  e0 88                lsr.l    #$8, d0
  000a64:  20 40                movea.l  d0, a0
  000a66:  20 1f                move.l   (a7)+, d0
  000a68:  41 e8 00 14          lea.l    $14(a0), a0
  000a6c:  2f 28 00 dc          move.l   $dc(a0), -(a7)
  000a70:  20 6f 00 04          movea.l  $4(a7), a0
  000a74:  2e 9f                move.l   (a7)+, (a7)
  000a76:  4e 75                rts      
  000a78:  60 ff 00 00 a2 60    bra.l    $acda  ; -> handler_55
  000a7e:  4e 71                nop      
disp_56:
  000a80:  00 00 16 54          dc.l     $00001654  ; dispatch #56, Am29000 cmd/offset $1654
La84:
  000a84:  2f 08                move.l   a0, -(a7)
  000a86:  20 78 08 88          movea.l  $888.w, a0
  000a8a:  20 50                movea.l  (a0), a0
  000a8c:  2f 00                move.l   d0, -(a7)
  000a8e:  20 10                move.l   (a0), d0
  000a90:  e1 88                lsl.l    #$8, d0
  000a92:  e0 88                lsr.l    #$8, d0
  000a94:  20 40                movea.l  d0, a0
  000a96:  20 1f                move.l   (a7)+, d0
  000a98:  41 e8 00 14          lea.l    $14(a0), a0
  000a9c:  2f 28 00 e0          move.l   $e0(a0), -(a7)
  000aa0:  20 6f 00 04          movea.l  $4(a7), a0
  000aa4:  2e 9f                move.l   (a7)+, (a7)
  000aa6:  4e 75                rts      
  000aa8:  60 ff 00 00 a5 5c    bra.l    $b006  ; -> handler_56
  000aae:  4e 71                nop      
disp_57:
  000ab0:  00 00 16 14          dc.l     $00001614  ; dispatch #57, Am29000 cmd/offset $1614
Lab4:
  000ab4:  2f 08                move.l   a0, -(a7)
  000ab6:  20 78 08 88          movea.l  $888.w, a0
  000aba:  20 50                movea.l  (a0), a0
  000abc:  2f 00                move.l   d0, -(a7)
  000abe:  20 10                move.l   (a0), d0
  000ac0:  e1 88                lsl.l    #$8, d0
  000ac2:  e0 88                lsr.l    #$8, d0
  000ac4:  20 40                movea.l  d0, a0
  000ac6:  20 1f                move.l   (a7)+, d0
  000ac8:  41 e8 00 14          lea.l    $14(a0), a0
  000acc:  2f 28 00 e4          move.l   $e4(a0), -(a7)
  000ad0:  20 6f 00 04          movea.l  $4(a7), a0
  000ad4:  2e 9f                move.l   (a7)+, (a7)
  000ad6:  4e 75                rts      
  000ad8:  60 ff 00 00 aa a4    bra.l    $b57e  ; -> handler_57
  000ade:  4e 71                nop      
disp_58:
  000ae0:  00 00 16 28          dc.l     $00001628  ; dispatch #58, Am29000 cmd/offset $1628
Lae4:
  000ae4:  2f 08                move.l   a0, -(a7)
  000ae6:  20 78 08 88          movea.l  $888.w, a0
  000aea:  20 50                movea.l  (a0), a0
  000aec:  2f 00                move.l   d0, -(a7)
  000aee:  20 10                move.l   (a0), d0
  000af0:  e1 88                lsl.l    #$8, d0
  000af2:  e0 88                lsr.l    #$8, d0
  000af4:  20 40                movea.l  d0, a0
  000af6:  20 1f                move.l   (a7)+, d0
  000af8:  41 e8 00 14          lea.l    $14(a0), a0
  000afc:  2f 28 00 e8          move.l   $e8(a0), -(a7)
  000b00:  20 6f 00 04          movea.l  $4(a7), a0
  000b04:  2e 9f                move.l   (a7)+, (a7)
  000b06:  4e 75                rts      
  000b08:  60 ff 00 00 aa da    bra.l    $b5e4  ; -> handler_58
  000b0e:  4e 71                nop      
disp_59:
  000b10:  00 00 16 2c          dc.l     $0000162C  ; dispatch #59, Am29000 cmd/offset $162C
Lb14:
  000b14:  2f 08                move.l   a0, -(a7)
  000b16:  20 78 08 88          movea.l  $888.w, a0
  000b1a:  20 50                movea.l  (a0), a0
  000b1c:  2f 00                move.l   d0, -(a7)
  000b1e:  20 10                move.l   (a0), d0
  000b20:  e1 88                lsl.l    #$8, d0
  000b22:  e0 88                lsr.l    #$8, d0
  000b24:  20 40                movea.l  d0, a0
  000b26:  20 1f                move.l   (a7)+, d0
  000b28:  41 e8 00 14          lea.l    $14(a0), a0
  000b2c:  2f 28 00 ec          move.l   $ec(a0), -(a7)
  000b30:  20 6f 00 04          movea.l  $4(a7), a0
  000b34:  2e 9f                move.l   (a7)+, (a7)
  000b36:  4e 75                rts      
  000b38:  60 ff 00 00 ab a4    bra.l    $b6de  ; -> handler_59
  000b3e:  4e 71                nop      
disp_60:
  000b40:  00 00 16 18          dc.l     $00001618  ; dispatch #60, Am29000 cmd/offset $1618
Lb44:
  000b44:  2f 08                move.l   a0, -(a7)
  000b46:  20 78 08 88          movea.l  $888.w, a0
  000b4a:  20 50                movea.l  (a0), a0
  000b4c:  2f 00                move.l   d0, -(a7)
  000b4e:  20 10                move.l   (a0), d0
  000b50:  e1 88                lsl.l    #$8, d0
  000b52:  e0 88                lsr.l    #$8, d0
  000b54:  20 40                movea.l  d0, a0
  000b56:  20 1f                move.l   (a7)+, d0
  000b58:  41 e8 00 14          lea.l    $14(a0), a0
  000b5c:  2f 28 00 f0          move.l   $f0(a0), -(a7)
  000b60:  20 6f 00 04          movea.l  $4(a7), a0
  000b64:  2e 9f                move.l   (a7)+, (a7)
  000b66:  4e 75                rts      
  000b68:  60 ff 00 00 ac 6e    bra.l    $b7d8  ; -> handler_60
  000b6e:  4e 71                nop      
disp_61:
  000b70:  00 00 16 84          dc.l     $00001684  ; dispatch #61, Am29000 cmd/offset $1684
Lb74:
  000b74:  2f 08                move.l   a0, -(a7)
  000b76:  20 78 08 88          movea.l  $888.w, a0
  000b7a:  20 50                movea.l  (a0), a0
  000b7c:  2f 00                move.l   d0, -(a7)
  000b7e:  20 10                move.l   (a0), d0
  000b80:  e1 88                lsl.l    #$8, d0
  000b82:  e0 88                lsr.l    #$8, d0
  000b84:  20 40                movea.l  d0, a0
  000b86:  20 1f                move.l   (a7)+, d0
  000b88:  41 e8 00 14          lea.l    $14(a0), a0
  000b8c:  2f 28 00 f4          move.l   $f4(a0), -(a7)
  000b90:  20 6f 00 04          movea.l  $4(a7), a0
  000b94:  2e 9f                move.l   (a7)+, (a7)
  000b96:  4e 75                rts      
  000b98:  60 ff 00 00 ac a4    bra.l    $b83e  ; -> handler_61
  000b9e:  4e 71                nop      
disp_62:
  000ba0:  00 00 16 88          dc.l     $00001688  ; dispatch #62, Am29000 cmd/offset $1688
Lba4:
  000ba4:  2f 08                move.l   a0, -(a7)
  000ba6:  20 78 08 88          movea.l  $888.w, a0
  000baa:  20 50                movea.l  (a0), a0
  000bac:  2f 00                move.l   d0, -(a7)
  000bae:  20 10                move.l   (a0), d0
  000bb0:  e1 88                lsl.l    #$8, d0
  000bb2:  e0 88                lsr.l    #$8, d0
  000bb4:  20 40                movea.l  d0, a0
  000bb6:  20 1f                move.l   (a7)+, d0
  000bb8:  41 e8 00 14          lea.l    $14(a0), a0
  000bbc:  2f 28 00 f8          move.l   $f8(a0), -(a7)
  000bc0:  20 6f 00 04          movea.l  $4(a7), a0
  000bc4:  2e 9f                move.l   (a7)+, (a7)
  000bc6:  4e 75                rts      
  000bc8:  60 ff 00 00 ac f4    bra.l    $b8be  ; -> handler_62
  000bce:  4e 71                nop      
disp_63:
  000bd0:  00 00 11 74          dc.l     $00001174  ; dispatch #63, Am29000 cmd/offset $1174
Lbd4:
  000bd4:  2f 08                move.l   a0, -(a7)
  000bd6:  20 78 08 88          movea.l  $888.w, a0
  000bda:  20 50                movea.l  (a0), a0
  000bdc:  2f 00                move.l   d0, -(a7)
  000bde:  20 10                move.l   (a0), d0
  000be0:  e1 88                lsl.l    #$8, d0
  000be2:  e0 88                lsr.l    #$8, d0
  000be4:  20 40                movea.l  d0, a0
  000be6:  20 1f                move.l   (a7)+, d0
  000be8:  41 e8 00 14          lea.l    $14(a0), a0
  000bec:  2f 28 00 fc          move.l   $fc(a0), -(a7)
  000bf0:  20 6f 00 04          movea.l  $4(a7), a0
  000bf4:  2e 9f                move.l   (a7)+, (a7)
  000bf6:  4e 75                rts      
  000bf8:  60 ff 00 00 99 0c    bra.l    $a506  ; -> handler_63
  000bfe:  4e 71                nop      
disp_64:
  000c00:  00 00 10 74          dc.l     $00001074  ; dispatch #64, Am29000 cmd/offset $1074
Lc04:
  000c04:  2f 08                move.l   a0, -(a7)
  000c06:  20 78 08 88          movea.l  $888.w, a0
  000c0a:  20 50                movea.l  (a0), a0
  000c0c:  2f 00                move.l   d0, -(a7)
  000c0e:  20 10                move.l   (a0), d0
  000c10:  e1 88                lsl.l    #$8, d0
  000c12:  e0 88                lsr.l    #$8, d0
  000c14:  20 40                movea.l  d0, a0
  000c16:  20 1f                move.l   (a7)+, d0
  000c18:  41 e8 00 14          lea.l    $14(a0), a0
  000c1c:  2f 28 01 00          move.l   $100(a0), -(a7)
  000c20:  20 6f 00 04          movea.l  $4(a7), a0
  000c24:  2e 9f                move.l   (a7)+, (a7)
  000c26:  4e 75                rts      
  000c28:  60 ff 00 00 94 56    bra.l    $a080  ; -> handler_64
  000c2e:  4e 71                nop      
disp_65:
  000c30:  00 00 0f f0          dc.l     $00000FF0  ; dispatch #65, Am29000 cmd/offset $FF0
Lc34:
  000c34:  2f 08                move.l   a0, -(a7)
  000c36:  20 78 08 88          movea.l  $888.w, a0
  000c3a:  20 50                movea.l  (a0), a0
  000c3c:  2f 00                move.l   d0, -(a7)
  000c3e:  20 10                move.l   (a0), d0
  000c40:  e1 88                lsl.l    #$8, d0
  000c42:  e0 88                lsr.l    #$8, d0
  000c44:  20 40                movea.l  d0, a0
  000c46:  20 1f                move.l   (a7)+, d0
  000c48:  41 e8 00 14          lea.l    $14(a0), a0
  000c4c:  2f 28 01 04          move.l   $104(a0), -(a7)
  000c50:  20 6f 00 04          movea.l  $4(a7), a0
  000c54:  2e 9f                move.l   (a7)+, (a7)
  000c56:  4e 75                rts      
  000c58:  60 ff 00 00 94 e0    bra.l    $a13a  ; -> handler_65
  000c5e:  4e 71                nop      
disp_66:
  000c60:  00 00 1a 74          dc.l     $00001A74  ; dispatch #66, Am29000 cmd/offset $1A74
Lc64:
  000c64:  2f 08                move.l   a0, -(a7)
  000c66:  20 78 08 88          movea.l  $888.w, a0
  000c6a:  20 50                movea.l  (a0), a0
  000c6c:  2f 00                move.l   d0, -(a7)
  000c6e:  20 10                move.l   (a0), d0
  000c70:  e1 88                lsl.l    #$8, d0
  000c72:  e0 88                lsr.l    #$8, d0
  000c74:  20 40                movea.l  d0, a0
  000c76:  20 1f                move.l   (a7)+, d0
  000c78:  41 e8 00 14          lea.l    $14(a0), a0
  000c7c:  2f 28 01 08          move.l   $108(a0), -(a7)
  000c80:  20 6f 00 04          movea.l  $4(a7), a0
  000c84:  2e 9f                move.l   (a7)+, (a7)
  000c86:  4e 75                rts      
  000c88:  60 ff 00 00 74 8e    bra.l    $8118  ; -> handler_66
  000c8e:  4e 71                nop      
disp_67:
  000c90:  00 00 16 64          dc.l     $00001664  ; dispatch #67, Am29000 cmd/offset $1664
Lc94:
  000c94:  2f 08                move.l   a0, -(a7)
  000c96:  20 78 08 88          movea.l  $888.w, a0
  000c9a:  20 50                movea.l  (a0), a0
  000c9c:  2f 00                move.l   d0, -(a7)
  000c9e:  20 10                move.l   (a0), d0
  000ca0:  e1 88                lsl.l    #$8, d0
  000ca2:  e0 88                lsr.l    #$8, d0
  000ca4:  20 40                movea.l  d0, a0
  000ca6:  20 1f                move.l   (a7)+, d0
  000ca8:  41 e8 00 14          lea.l    $14(a0), a0
  000cac:  2f 28 01 0c          move.l   $10c(a0), -(a7)
  000cb0:  20 6f 00 04          movea.l  $4(a7), a0
  000cb4:  2e 9f                move.l   (a7)+, (a7)
  000cb6:  4e 75                rts      
  000cb8:  60 ff 00 00 a7 84    bra.l    $b43e  ; -> handler_67
  000cbe:  4e 71                nop      
disp_68:
  000cc0:  00 00 16 68          dc.l     $00001668  ; dispatch #68, Am29000 cmd/offset $1668
Lcc4:
  000cc4:  2f 08                move.l   a0, -(a7)
  000cc6:  20 78 08 88          movea.l  $888.w, a0
  000cca:  20 50                movea.l  (a0), a0
  000ccc:  2f 00                move.l   d0, -(a7)
  000cce:  20 10                move.l   (a0), d0
  000cd0:  e1 88                lsl.l    #$8, d0
  000cd2:  e0 88                lsr.l    #$8, d0
  000cd4:  20 40                movea.l  d0, a0
  000cd6:  20 1f                move.l   (a7)+, d0
  000cd8:  41 e8 00 14          lea.l    $14(a0), a0
  000cdc:  2f 28 01 10          move.l   $110(a0), -(a7)
  000ce0:  20 6f 00 04          movea.l  $4(a7), a0
  000ce4:  2e 9f                move.l   (a7)+, (a7)
  000ce6:  4e 75                rts      
  000ce8:  60 ff 00 00 a7 e0    bra.l    $b4ca  ; -> handler_68
  000cee:  4e 71                nop      
disp_69:
  000cf0:  00 00 08 14          dc.l     $00000814  ; dispatch #69, Am29000 cmd/offset $814
Lcf4:
  000cf4:  2f 08                move.l   a0, -(a7)
  000cf6:  20 78 08 88          movea.l  $888.w, a0
  000cfa:  20 50                movea.l  (a0), a0
  000cfc:  2f 00                move.l   d0, -(a7)
  000cfe:  20 10                move.l   (a0), d0
  000d00:  e1 88                lsl.l    #$8, d0
  000d02:  e0 88                lsr.l    #$8, d0
  000d04:  20 40                movea.l  d0, a0
  000d06:  20 1f                move.l   (a7)+, d0
  000d08:  41 e8 00 14          lea.l    $14(a0), a0
  000d0c:  2f 28 01 14          move.l   $114(a0), -(a7)
  000d10:  20 6f 00 04          movea.l  $4(a7), a0
  000d14:  2e 9f                move.l   (a7)+, (a7)
  000d16:  4e 75                rts      
  000d18:  60 ff 00 00 38 ba    bra.l    $45d4  ; -> handler_69
  000d1e:  4e 71                nop      
disp_70:
  000d20:  00 00 08 18          dc.l     $00000818  ; dispatch #70, Am29000 cmd/offset $818
Ld24:
  000d24:  2f 08                move.l   a0, -(a7)
  000d26:  20 78 08 88          movea.l  $888.w, a0
  000d2a:  20 50                movea.l  (a0), a0
  000d2c:  2f 00                move.l   d0, -(a7)
  000d2e:  20 10                move.l   (a0), d0
  000d30:  e1 88                lsl.l    #$8, d0
  000d32:  e0 88                lsr.l    #$8, d0
  000d34:  20 40                movea.l  d0, a0
  000d36:  20 1f                move.l   (a7)+, d0
  000d38:  41 e8 00 14          lea.l    $14(a0), a0
  000d3c:  2f 28 01 18          move.l   $118(a0), -(a7)
  000d40:  20 6f 00 04          movea.l  $4(a7), a0
  000d44:  2e 9f                move.l   (a7)+, (a7)
  000d46:  4e 75                rts      
  000d48:  60 ff 00 00 35 f4    bra.l    $433e  ; -> handler_70
  000d4e:  4e 71                nop      
disp_71:
  000d50:  00 00 08 1c          dc.l     $0000081C  ; dispatch #71, Am29000 cmd/offset $81C
Ld54:
  000d54:  2f 08                move.l   a0, -(a7)
  000d56:  20 78 08 88          movea.l  $888.w, a0
  000d5a:  20 50                movea.l  (a0), a0
  000d5c:  2f 00                move.l   d0, -(a7)
  000d5e:  20 10                move.l   (a0), d0
  000d60:  e1 88                lsl.l    #$8, d0
  000d62:  e0 88                lsr.l    #$8, d0
  000d64:  20 40                movea.l  d0, a0
  000d66:  20 1f                move.l   (a7)+, d0
  000d68:  41 e8 00 14          lea.l    $14(a0), a0
  000d6c:  2f 28 01 1c          move.l   $11c(a0), -(a7)
  000d70:  20 6f 00 04          movea.l  $4(a7), a0
  000d74:  2e 9f                move.l   (a7)+, (a7)
  000d76:  4e 75                rts      
  000d78:  60 ff 00 00 36 50    bra.l    $43ca  ; -> handler_71
  000d7e:  4e 71                nop      
disp_72:
  000d80:  00 00 08 90          dc.l     $00000890  ; dispatch #72, Am29000 cmd/offset $890
Ld84:
  000d84:  2f 08                move.l   a0, -(a7)
  000d86:  20 78 08 88          movea.l  $888.w, a0
  000d8a:  20 50                movea.l  (a0), a0
  000d8c:  2f 00                move.l   d0, -(a7)
  000d8e:  20 10                move.l   (a0), d0
  000d90:  e1 88                lsl.l    #$8, d0
  000d92:  e0 88                lsr.l    #$8, d0
  000d94:  20 40                movea.l  d0, a0
  000d96:  20 1f                move.l   (a7)+, d0
  000d98:  41 e8 00 14          lea.l    $14(a0), a0
  000d9c:  2f 28 01 20          move.l   $120(a0), -(a7)
  000da0:  20 6f 00 04          movea.l  $4(a7), a0
  000da4:  2e 9f                move.l   (a7)+, (a7)
  000da6:  4e 75                rts      
  000da8:  60 ff 00 00 36 9a    bra.l    $4444  ; -> handler_72
  000dae:  4e 71                nop      
disp_73:
  000db0:  00 00 16 b4          dc.l     $000016B4  ; dispatch #73, Am29000 cmd/offset $16B4
Ldb4:
  000db4:  2f 08                move.l   a0, -(a7)
  000db6:  20 78 08 88          movea.l  $888.w, a0
  000dba:  20 50                movea.l  (a0), a0
  000dbc:  2f 00                move.l   d0, -(a7)
  000dbe:  20 10                move.l   (a0), d0
  000dc0:  e1 88                lsl.l    #$8, d0
  000dc2:  e0 88                lsr.l    #$8, d0
  000dc4:  20 40                movea.l  d0, a0
  000dc6:  20 1f                move.l   (a7)+, d0
  000dc8:  41 e8 00 14          lea.l    $14(a0), a0
  000dcc:  2f 28 01 24          move.l   $124(a0), -(a7)
  000dd0:  20 6f 00 04          movea.l  $4(a7), a0
  000dd4:  2e 9f                move.l   (a7)+, (a7)
  000dd6:  4e 75                rts      
  000dd8:  60 ff 00 00 88 5a    bra.l    $9634  ; -> handler_73
  000dde:  4e 71                nop      
disp_74:
  000de0:  00 00 16 c0          dc.l     $000016C0  ; dispatch #74, Am29000 cmd/offset $16C0
Lde4:
  000de4:  2f 08                move.l   a0, -(a7)
  000de6:  20 78 08 88          movea.l  $888.w, a0
  000dea:  20 50                movea.l  (a0), a0
  000dec:  2f 00                move.l   d0, -(a7)
  000dee:  20 10                move.l   (a0), d0
  000df0:  e1 88                lsl.l    #$8, d0
  000df2:  e0 88                lsr.l    #$8, d0
  000df4:  20 40                movea.l  d0, a0
  000df6:  20 1f                move.l   (a7)+, d0
  000df8:  41 e8 00 14          lea.l    $14(a0), a0
  000dfc:  2f 28 01 28          move.l   $128(a0), -(a7)
  000e00:  20 6f 00 04          movea.l  $4(a7), a0
  000e04:  2e 9f                move.l   (a7)+, (a7)
  000e06:  4e 75                rts      
  000e08:  60 ff 00 00 88 7a    bra.l    $9684  ; -> handler_74
  000e0e:  4e 71                nop      
disp_75:
  000e10:  00 00 11 d8          dc.l     $000011D8  ; dispatch #75, Am29000 cmd/offset $11D8
Le14:
  000e14:  2f 08                move.l   a0, -(a7)
  000e16:  20 78 08 88          movea.l  $888.w, a0
  000e1a:  20 50                movea.l  (a0), a0
  000e1c:  2f 00                move.l   d0, -(a7)
  000e1e:  20 10                move.l   (a0), d0
  000e20:  e1 88                lsl.l    #$8, d0
  000e22:  e0 88                lsr.l    #$8, d0
  000e24:  20 40                movea.l  d0, a0
  000e26:  20 1f                move.l   (a7)+, d0
  000e28:  41 e8 00 14          lea.l    $14(a0), a0
  000e2c:  2f 28 01 2c          move.l   $12c(a0), -(a7)
  000e30:  20 6f 00 04          movea.l  $4(a7), a0
  000e34:  2e 9f                move.l   (a7)+, (a7)
  000e36:  4e 75                rts      
  000e38:  60 ff 00 00 38 f0    bra.l    $472a  ; -> handler_75
  000e3e:  4e 71                nop      
disp_76:
  000e40:  00 00 16 0c          dc.l     $0000160C  ; dispatch #76, Am29000 cmd/offset $160C
Le44:
  000e44:  2f 08                move.l   a0, -(a7)
  000e46:  20 78 08 88          movea.l  $888.w, a0
  000e4a:  20 50                movea.l  (a0), a0
  000e4c:  2f 00                move.l   d0, -(a7)
  000e4e:  20 10                move.l   (a0), d0
  000e50:  e1 88                lsl.l    #$8, d0
  000e52:  e0 88                lsr.l    #$8, d0
  000e54:  20 40                movea.l  d0, a0
  000e56:  20 1f                move.l   (a7)+, d0
  000e58:  41 e8 00 14          lea.l    $14(a0), a0
  000e5c:  2f 28 01 30          move.l   $130(a0), -(a7)
  000e60:  20 6f 00 04          movea.l  $4(a7), a0
  000e64:  2e 9f                move.l   (a7)+, (a7)
  000e66:  4e 75                rts      
  000e68:  60 ff 00 00 a6 ec    bra.l    $b556  ; -> handler_76
  000e6e:  4e 71                nop      
disp_77:
  000e70:  00 00 16 fc          dc.l     $000016FC  ; dispatch #77, Am29000 cmd/offset $16FC
Le74:
  000e74:  2f 08                move.l   a0, -(a7)
  000e76:  20 78 08 88          movea.l  $888.w, a0
  000e7a:  20 50                movea.l  (a0), a0
  000e7c:  2f 00                move.l   d0, -(a7)
  000e7e:  20 10                move.l   (a0), d0
  000e80:  e1 88                lsl.l    #$8, d0
  000e82:  e0 88                lsr.l    #$8, d0
  000e84:  20 40                movea.l  d0, a0
  000e86:  20 1f                move.l   (a7)+, d0
  000e88:  41 e8 00 14          lea.l    $14(a0), a0
  000e8c:  2f 28 01 34          move.l   $134(a0), -(a7)
  000e90:  20 6f 00 04          movea.l  $4(a7), a0
  000e94:  2e 9f                move.l   (a7)+, (a7)
  000e96:  4e 75                rts      
  000e98:  60 ff 00 00 87 28    bra.l    $95c2  ; -> handler_77
  000e9e:  4e 71                nop      
disp_78:
  000ea0:  00 00 10 a8          dc.l     $000010A8  ; dispatch #78, Am29000 cmd/offset $10A8
Lea4:
  000ea4:  2f 08                move.l   a0, -(a7)
  000ea6:  20 78 08 88          movea.l  $888.w, a0
  000eaa:  20 50                movea.l  (a0), a0
  000eac:  2f 00                move.l   d0, -(a7)
  000eae:  20 10                move.l   (a0), d0
  000eb0:  e1 88                lsl.l    #$8, d0
  000eb2:  e0 88                lsr.l    #$8, d0
  000eb4:  20 40                movea.l  d0, a0
  000eb6:  20 1f                move.l   (a7)+, d0
  000eb8:  41 e8 00 14          lea.l    $14(a0), a0
  000ebc:  2f 28 01 38          move.l   $138(a0), -(a7)
  000ec0:  20 6f 00 04          movea.l  $4(a7), a0
  000ec4:  2e 9f                move.l   (a7)+, (a7)
  000ec6:  4e 75                rts      
  000ec8:  60 ff 00 00 94 b4    bra.l    $a37e  ; -> handler_78
  000ece:  4e 71                nop      
disp_79:
  000ed0:  00 00 0f f4          dc.l     $00000FF4  ; dispatch #79, Am29000 cmd/offset $FF4
Led4:
  000ed4:  2f 08                move.l   a0, -(a7)
  000ed6:  20 78 08 88          movea.l  $888.w, a0
  000eda:  20 50                movea.l  (a0), a0
  000edc:  2f 00                move.l   d0, -(a7)
  000ede:  20 10                move.l   (a0), d0
  000ee0:  e1 88                lsl.l    #$8, d0
  000ee2:  e0 88                lsr.l    #$8, d0
  000ee4:  20 40                movea.l  d0, a0
  000ee6:  20 1f                move.l   (a7)+, d0
  000ee8:  41 e8 00 14          lea.l    $14(a0), a0
  000eec:  2f 28 01 3c          move.l   $13c(a0), -(a7)
  000ef0:  20 6f 00 04          movea.l  $4(a7), a0
  000ef4:  2e 9f                move.l   (a7)+, (a7)
  000ef6:  4e 75                rts      
  000ef8:  60 ff 00 00 ad 28    bra.l    $bc22  ; -> handler_79
  000efe:  4e 71                nop      
disp_80:
  000f00:  00 00 16 5c          dc.l     $0000165C  ; dispatch #80, Am29000 cmd/offset $165C
Lf04:
  000f04:  2f 08                move.l   a0, -(a7)
  000f06:  20 78 08 88          movea.l  $888.w, a0
  000f0a:  20 50                movea.l  (a0), a0
  000f0c:  2f 00                move.l   d0, -(a7)
  000f0e:  20 10                move.l   (a0), d0
  000f10:  e1 88                lsl.l    #$8, d0
  000f12:  e0 88                lsr.l    #$8, d0
  000f14:  20 40                movea.l  d0, a0
  000f16:  20 1f                move.l   (a7)+, d0
  000f18:  41 e8 00 14          lea.l    $14(a0), a0
  000f1c:  2f 28 01 40          move.l   $140(a0), -(a7)
  000f20:  20 6f 00 04          movea.l  $4(a7), a0
  000f24:  2e 9f                move.l   (a7)+, (a7)
  000f26:  4e 75                rts      
  000f28:  60 ff 00 00 a4 22    bra.l    $b34c  ; -> handler_80
  000f2e:  4e 71                nop      
disp_81:
  000f30:  00 00 0f 94          dc.l     $00000F94  ; dispatch #81, Am29000 cmd/offset $F94
Lf34:
  000f34:  2f 08                move.l   a0, -(a7)
  000f36:  20 78 08 88          movea.l  $888.w, a0
  000f3a:  20 50                movea.l  (a0), a0
  000f3c:  2f 00                move.l   d0, -(a7)
  000f3e:  20 10                move.l   (a0), d0
  000f40:  e1 88                lsl.l    #$8, d0
  000f42:  e0 88                lsr.l    #$8, d0
  000f44:  20 40                movea.l  d0, a0
  000f46:  20 1f                move.l   (a7)+, d0
  000f48:  41 e8 00 14          lea.l    $14(a0), a0
  000f4c:  2f 28 01 44          move.l   $144(a0), -(a7)
  000f50:  20 6f 00 04          movea.l  $4(a7), a0
  000f54:  2e 9f                move.l   (a7)+, (a7)
  000f56:  4e 75                rts      
  000f58:  60 ff 00 00 a2 e4    bra.l    $b23e  ; -> handler_81
  000f5e:  4e 71                nop      
disp_82:
  000f60:  00 00 17 40          dc.l     $00001740  ; dispatch #82, Am29000 cmd/offset $1740
Lf64:
  000f64:  2f 08                move.l   a0, -(a7)
  000f66:  20 78 08 88          movea.l  $888.w, a0
  000f6a:  20 50                movea.l  (a0), a0
  000f6c:  2f 00                move.l   d0, -(a7)
  000f6e:  20 10                move.l   (a0), d0
  000f70:  e1 88                lsl.l    #$8, d0
  000f72:  e0 88                lsr.l    #$8, d0
  000f74:  20 40                movea.l  d0, a0
  000f76:  20 1f                move.l   (a7)+, d0
  000f78:  41 e8 00 14          lea.l    $14(a0), a0
  000f7c:  2f 28 01 48          move.l   $148(a0), -(a7)
  000f80:  20 6f 00 04          movea.l  $4(a7), a0
  000f84:  2e 9f                move.l   (a7)+, (a7)
  000f86:  4e 75                rts      
  000f88:  60 ff 00 00 37 d8    bra.l    $4762  ; -> handler_82
  000f8e:  4e 71                nop      
disp_83:
  000f90:  00 00 17 3c          dc.l     $0000173C  ; dispatch #83, Am29000 cmd/offset $173C
Lf94:
  000f94:  2f 08                move.l   a0, -(a7)
  000f96:  20 78 08 88          movea.l  $888.w, a0
  000f9a:  20 50                movea.l  (a0), a0
  000f9c:  2f 00                move.l   d0, -(a7)
  000f9e:  20 10                move.l   (a0), d0
  000fa0:  e1 88                lsl.l    #$8, d0
  000fa2:  e0 88                lsr.l    #$8, d0
  000fa4:  20 40                movea.l  d0, a0
  000fa6:  20 1f                move.l   (a7)+, d0
  000fa8:  41 e8 00 14          lea.l    $14(a0), a0
  000fac:  2f 28 01 4c          move.l   $14c(a0), -(a7)
  000fb0:  20 6f 00 04          movea.l  $4(a7), a0
  000fb4:  2e 9f                move.l   (a7)+, (a7)
  000fb6:  4e 75                rts      
  000fb8:  60 ff 00 00 38 02    bra.l    $47bc  ; -> handler_83
  000fbe:  4e 71                nop      
disp_84:
  000fc0:  00 00 17 24          dc.l     $00001724  ; dispatch #84, Am29000 cmd/offset $1724
Lfc4:
  000fc4:  2f 08                move.l   a0, -(a7)
  000fc6:  20 78 08 88          movea.l  $888.w, a0
  000fca:  20 50                movea.l  (a0), a0
  000fcc:  2f 00                move.l   d0, -(a7)
  000fce:  20 10                move.l   (a0), d0
  000fd0:  e1 88                lsl.l    #$8, d0
  000fd2:  e0 88                lsr.l    #$8, d0
  000fd4:  20 40                movea.l  d0, a0
  000fd6:  20 1f                move.l   (a7)+, d0
  000fd8:  41 e8 00 14          lea.l    $14(a0), a0
  000fdc:  2f 28 01 50          move.l   $150(a0), -(a7)
  000fe0:  20 6f 00 04          movea.l  $4(a7), a0
  000fe4:  2e 9f                move.l   (a7)+, (a7)
  000fe6:  4e 75                rts      
  000fe8:  60 ff 00 00 84 dc    bra.l    $94c6  ; -> handler_84
  000fee:  4e 71                nop      
disp_85:
  000ff0:  00 00 17 28          dc.l     $00001728  ; dispatch #85, Am29000 cmd/offset $1728
Lff4:
  000ff4:  2f 08                move.l   a0, -(a7)
  000ff6:  20 78 08 88          movea.l  $888.w, a0
  000ffa:  20 50                movea.l  (a0), a0
  000ffc:  2f 00                move.l   d0, -(a7)
  000ffe:  20 10                move.l   (a0), d0
  001000:  e1 88                lsl.l    #$8, d0
  001002:  e0 88                lsr.l    #$8, d0
  001004:  20 40                movea.l  d0, a0
  001006:  20 1f                move.l   (a7)+, d0
  001008:  41 e8 00 14          lea.l    $14(a0), a0
  00100c:  2f 28 01 54          move.l   $154(a0), -(a7)
  001010:  20 6f 00 04          movea.l  $4(a7), a0
  001014:  2e 9f                move.l   (a7)+, (a7)
  001016:  4e 75                rts      
  001018:  60 ff 00 00 85 00    bra.l    $951a  ; -> handler_85
  00101e:  4e 71                nop      
disp_86:
  001020:  00 00 16 dc          dc.l     $000016DC  ; dispatch #86, Am29000 cmd/offset $16DC
L1024:
  001024:  2f 08                move.l   a0, -(a7)
  001026:  20 78 08 88          movea.l  $888.w, a0
  00102a:  20 50                movea.l  (a0), a0
  00102c:  2f 00                move.l   d0, -(a7)
  00102e:  20 10                move.l   (a0), d0
  001030:  e1 88                lsl.l    #$8, d0
  001032:  e0 88                lsr.l    #$8, d0
  001034:  20 40                movea.l  d0, a0
  001036:  20 1f                move.l   (a7)+, d0
  001038:  41 e8 00 14          lea.l    $14(a0), a0
  00103c:  2f 28 01 58          move.l   $158(a0), -(a7)
  001040:  20 6f 00 04          movea.l  $4(a7), a0
  001044:  2e 9f                move.l   (a7)+, (a7)
  001046:  4e 75                rts      
  001048:  60 ff 00 00 85 24    bra.l    $956e  ; -> handler_86
  00104e:  4e 71                nop      
disp_87:
  001050:  00 00 16 a0          dc.l     $000016A0  ; dispatch #87, Am29000 cmd/offset $16A0
L1054:
  001054:  2f 08                move.l   a0, -(a7)
  001056:  20 78 08 88          movea.l  $888.w, a0
  00105a:  20 50                movea.l  (a0), a0
  00105c:  2f 00                move.l   d0, -(a7)
  00105e:  20 10                move.l   (a0), d0
  001060:  e1 88                lsl.l    #$8, d0
  001062:  e0 88                lsr.l    #$8, d0
  001064:  20 40                movea.l  d0, a0
  001066:  20 1f                move.l   (a7)+, d0
  001068:  41 e8 00 14          lea.l    $14(a0), a0
  00106c:  2f 28 01 5c          move.l   $15c(a0), -(a7)
  001070:  20 6f 00 04          movea.l  $4(a7), a0
  001074:  2e 9f                move.l   (a7)+, (a7)
  001076:  4e 75                rts      
  001078:  60 ff 00 00 70 1e    bra.l    $8098  ; -> GA_GETCTSEED
  00107e:  4e 71                nop      
disp_88:
  001080:  00 00 18 88          dc.l     $00001888  ; dispatch #88, Am29000 cmd/offset $1888
L1084:
  001084:  2f 08                move.l   a0, -(a7)
  001086:  20 78 08 88          movea.l  $888.w, a0
  00108a:  20 50                movea.l  (a0), a0
  00108c:  2f 00                move.l   d0, -(a7)
  00108e:  20 10                move.l   (a0), d0
  001090:  e1 88                lsl.l    #$8, d0
  001092:  e0 88                lsr.l    #$8, d0
  001094:  20 40                movea.l  d0, a0
  001096:  20 1f                move.l   (a7)+, d0
  001098:  41 e8 00 14          lea.l    $14(a0), a0
  00109c:  2f 28 01 60          move.l   $160(a0), -(a7)
  0010a0:  20 6f 00 04          movea.l  $4(a7), a0
  0010a4:  2e 9f                move.l   (a7)+, (a7)
  0010a6:  4e 75                rts      
  0010a8:  60 ff 00 00 70 2a    bra.l    $80d4  ; -> GA_PMGR
  0010ae:  4e 71                nop      
disp_89:
  0010b0:  00 00 18 50          dc.l     $00001850  ; dispatch #89, Am29000 cmd/offset $1850
L10b4:
  0010b4:  2f 08                move.l   a0, -(a7)
  0010b6:  20 78 08 88          movea.l  $888.w, a0
  0010ba:  20 50                movea.l  (a0), a0
  0010bc:  2f 00                move.l   d0, -(a7)
  0010be:  20 10                move.l   (a0), d0
  0010c0:  e1 88                lsl.l    #$8, d0
  0010c2:  e0 88                lsr.l    #$8, d0
  0010c4:  20 40                movea.l  d0, a0
  0010c6:  20 1f                move.l   (a7)+, d0
  0010c8:  41 e8 00 14          lea.l    $14(a0), a0
  0010cc:  2f 28 01 64          move.l   $164(a0), -(a7)
  0010d0:  20 6f 00 04          movea.l  $4(a7), a0
  0010d4:  2e 9f                move.l   (a7)+, (a7)
  0010d6:  4e 75                rts      
  0010d8:  60 ff 00 00 83 1a    bra.l    $93f4  ; -> handler_89
  0010de:  4e 71                nop      
disp_90:
  0010e0:  00 00 18 54          dc.l     $00001854  ; dispatch #90, Am29000 cmd/offset $1854
L10e4:
  0010e4:  2f 08                move.l   a0, -(a7)
  0010e6:  20 78 08 88          movea.l  $888.w, a0
  0010ea:  20 50                movea.l  (a0), a0
  0010ec:  2f 00                move.l   d0, -(a7)
  0010ee:  20 10                move.l   (a0), d0
  0010f0:  e1 88                lsl.l    #$8, d0
  0010f2:  e0 88                lsr.l    #$8, d0
  0010f4:  20 40                movea.l  d0, a0
  0010f6:  20 1f                move.l   (a7)+, d0
  0010f8:  41 e8 00 14          lea.l    $14(a0), a0
  0010fc:  2f 28 01 68          move.l   $168(a0), -(a7)
  001100:  20 6f 00 04          movea.l  $4(a7), a0
  001104:  2e 9f                move.l   (a7)+, (a7)
  001106:  4e 75                rts      
  001108:  60 ff 00 00 82 ae    bra.l    $93b8  ; -> handler_90
  00110e:  4e 71                nop      
disp_91:
  001110:  00 00 18 80          dc.l     $00001880  ; dispatch #91, Am29000 cmd/offset $1880
L1114:
  001114:  2f 08                move.l   a0, -(a7)
  001116:  20 78 08 88          movea.l  $888.w, a0
  00111a:  20 50                movea.l  (a0), a0
  00111c:  2f 00                move.l   d0, -(a7)
  00111e:  20 10                move.l   (a0), d0
  001120:  e1 88                lsl.l    #$8, d0
  001122:  e0 88                lsr.l    #$8, d0
  001124:  20 40                movea.l  d0, a0
  001126:  20 1f                move.l   (a7)+, d0
  001128:  41 e8 00 14          lea.l    $14(a0), a0
  00112c:  2f 28 01 6c          move.l   $16c(a0), -(a7)
  001130:  20 6f 00 04          movea.l  $4(a7), a0
  001134:  2e 9f                move.l   (a7)+, (a7)
  001136:  4e 75                rts      
  001138:  60 ff 00 00 82 ee    bra.l    $9428  ; -> handler_91
  00113e:  4e 71                nop      
disp_92:
  001140:  00 00 16 e4          dc.l     $000016E4  ; dispatch #92, Am29000 cmd/offset $16E4
L1144:
  001144:  2f 08                move.l   a0, -(a7)
  001146:  20 78 08 88          movea.l  $888.w, a0
  00114a:  20 50                movea.l  (a0), a0
  00114c:  2f 00                move.l   d0, -(a7)
  00114e:  20 10                move.l   (a0), d0
  001150:  e1 88                lsl.l    #$8, d0
  001152:  e0 88                lsr.l    #$8, d0
  001154:  20 40                movea.l  d0, a0
  001156:  20 1f                move.l   (a7)+, d0
  001158:  41 e8 00 14          lea.l    $14(a0), a0
  00115c:  2f 28 01 70          move.l   $170(a0), -(a7)
  001160:  20 6f 00 04          movea.l  $4(a7), a0
  001164:  2e 9f                move.l   (a7)+, (a7)
  001166:  4e 75                rts      
  001168:  60 ff 00 00 82 f6    bra.l    $9460  ; -> handler_92
  00116e:  4e 71                nop      
disp_93:
  001170:  00 00 0f b8          dc.l     $00000FB8  ; dispatch #93, Am29000 cmd/offset $FB8
L1174:
  001174:  2f 08                move.l   a0, -(a7)
  001176:  20 78 08 88          movea.l  $888.w, a0
  00117a:  20 50                movea.l  (a0), a0
  00117c:  2f 00                move.l   d0, -(a7)
  00117e:  20 10                move.l   (a0), d0
  001180:  e1 88                lsl.l    #$8, d0
  001182:  e0 88                lsr.l    #$8, d0
  001184:  20 40                movea.l  d0, a0
  001186:  20 1f                move.l   (a7)+, d0
  001188:  41 e8 00 14          lea.l    $14(a0), a0
  00118c:  2f 28 01 74          move.l   $174(a0), -(a7)
  001190:  20 6f 00 04          movea.l  $4(a7), a0
  001194:  2e 9f                move.l   (a7)+, (a7)
  001196:  4e 75                rts      
  001198:  60 ff 00 00 34 be    bra.l    $4658  ; -> handler_93
  00119e:  4e 71                nop      
disp_94:
  0011a0:  00 00 0f b4          dc.l     $00000FB4  ; dispatch #94, Am29000 cmd/offset $FB4
L11a4:
  0011a4:  2f 08                move.l   a0, -(a7)
  0011a6:  20 78 08 88          movea.l  $888.w, a0
  0011aa:  20 50                movea.l  (a0), a0
  0011ac:  2f 00                move.l   d0, -(a7)
  0011ae:  20 10                move.l   (a0), d0
  0011b0:  e1 88                lsl.l    #$8, d0
  0011b2:  e0 88                lsr.l    #$8, d0
  0011b4:  20 40                movea.l  d0, a0
  0011b6:  20 1f                move.l   (a7)+, d0
  0011b8:  41 e8 00 14          lea.l    $14(a0), a0
  0011bc:  2f 28 01 78          move.l   $178(a0), -(a7)
  0011c0:  20 6f 00 04          movea.l  $4(a7), a0
  0011c4:  2e 9f                move.l   (a7)+, (a7)
  0011c6:  4e 75                rts      
  0011c8:  60 ff 00 00 34 b8    bra.l    $4682  ; -> handler_94
  0011ce:  4e 71                nop      
disp_95:
  0011d0:  00 00 0f bc          dc.l     $00000FBC  ; dispatch #95, Am29000 cmd/offset $FBC
L11d4:
  0011d4:  2f 08                move.l   a0, -(a7)
  0011d6:  20 78 08 88          movea.l  $888.w, a0
  0011da:  20 50                movea.l  (a0), a0
  0011dc:  2f 00                move.l   d0, -(a7)
  0011de:  20 10                move.l   (a0), d0
  0011e0:  e1 88                lsl.l    #$8, d0
  0011e2:  e0 88                lsr.l    #$8, d0
  0011e4:  20 40                movea.l  d0, a0
  0011e6:  20 1f                move.l   (a7)+, d0
  0011e8:  41 e8 00 14          lea.l    $14(a0), a0
  0011ec:  2f 28 01 7c          move.l   $17c(a0), -(a7)
  0011f0:  20 6f 00 04          movea.l  $4(a7), a0
  0011f4:  2e 9f                move.l   (a7)+, (a7)
  0011f6:  4e 75                rts      
  0011f8:  60 ff 00 00 34 b2    bra.l    $46ac  ; -> handler_95
  0011fe:  4e 71                nop      
disp_96:
  001200:  00 00 16 04          dc.l     $00001604  ; dispatch #96, Am29000 cmd/offset $1604
L1204:
  001204:  2f 08                move.l   a0, -(a7)
  001206:  20 78 08 88          movea.l  $888.w, a0
  00120a:  20 50                movea.l  (a0), a0
  00120c:  2f 00                move.l   d0, -(a7)
  00120e:  20 10                move.l   (a0), d0
  001210:  e1 88                lsl.l    #$8, d0
  001212:  e0 88                lsr.l    #$8, d0
  001214:  20 40                movea.l  d0, a0
  001216:  20 1f                move.l   (a7)+, d0
  001218:  41 e8 00 14          lea.l    $14(a0), a0
  00121c:  2f 28 01 80          move.l   $180(a0), -(a7)
  001220:  20 6f 00 04          movea.l  $4(a7), a0
  001224:  2e 9f                move.l   (a7)+, (a7)
  001226:  4e 75                rts      
  001228:  60 ff 00 00 34 ac    bra.l    $46d6  ; -> handler_96
  00122e:  4e 71                nop      
disp_97:
  001230:  00 00 16 00          dc.l     $00001600  ; dispatch #97, Am29000 cmd/offset $1600
L1234:
  001234:  2f 08                move.l   a0, -(a7)
  001236:  20 78 08 88          movea.l  $888.w, a0
  00123a:  20 50                movea.l  (a0), a0
  00123c:  2f 00                move.l   d0, -(a7)
  00123e:  20 10                move.l   (a0), d0
  001240:  e1 88                lsl.l    #$8, d0
  001242:  e0 88                lsr.l    #$8, d0
  001244:  20 40                movea.l  d0, a0
  001246:  20 1f                move.l   (a7)+, d0
  001248:  41 e8 00 14          lea.l    $14(a0), a0
  00124c:  2f 28 01 84          move.l   $184(a0), -(a7)
  001250:  20 6f 00 04          movea.l  $4(a7), a0
  001254:  2e 9f                move.l   (a7)+, (a7)
  001256:  4e 75                rts      
  001258:  60 ff 00 00 34 a6    bra.l    $4700  ; -> handler_97
  00125e:  4e 71                nop      
disp_98:
  001260:  00 00 16 08          dc.l     $00001608  ; dispatch #98, Am29000 cmd/offset $1608
L1264:
  001264:  2f 08                move.l   a0, -(a7)
  001266:  20 78 08 88          movea.l  $888.w, a0
  00126a:  20 50                movea.l  (a0), a0
  00126c:  2f 00                move.l   d0, -(a7)
  00126e:  20 10                move.l   (a0), d0
  001270:  e1 88                lsl.l    #$8, d0
  001272:  e0 88                lsr.l    #$8, d0
  001274:  20 40                movea.l  d0, a0
  001276:  20 1f                move.l   (a7)+, d0
  001278:  41 e8 00 14          lea.l    $14(a0), a0
  00127c:  2f 28 01 88          move.l   $188(a0), -(a7)
  001280:  20 6f 00 04          movea.l  $4(a7), a0
  001284:  2e 9f                move.l   (a7)+, (a7)
  001286:  4e 75                rts      
  001288:  60 ff 00 00 a9 98    bra.l    $bc22  ; -> handler_79
  00128e:  4e 71                nop      
disp_99:
  001290:  00 00 16 b8          dc.l     $000016B8  ; dispatch #99, Am29000 cmd/offset $16B8
L1294:
  001294:  2f 08                move.l   a0, -(a7)
  001296:  20 78 08 88          movea.l  $888.w, a0
  00129a:  20 50                movea.l  (a0), a0
  00129c:  2f 00                move.l   d0, -(a7)
  00129e:  20 10                move.l   (a0), d0
  0012a0:  e1 88                lsl.l    #$8, d0
  0012a2:  e0 88                lsr.l    #$8, d0
  0012a4:  20 40                movea.l  d0, a0
  0012a6:  20 1f                move.l   (a7)+, d0
  0012a8:  41 e8 00 14          lea.l    $14(a0), a0
  0012ac:  2f 28 01 8c          move.l   $18c(a0), -(a7)
  0012b0:  20 6f 00 04          movea.l  $4(a7), a0
  0012b4:  2e 9f                move.l   (a7)+, (a7)
  0012b6:  4e 75                rts      
  0012b8:  60 ff 00 00 84 4c    bra.l    $9706  ; -> handler_99
  0012be:  4e 71                nop      
disp_100:
  0012c0:  00 00 11 5c          dc.l     $0000115C  ; dispatch #100, Am29000 cmd/offset $115C
L12c4:
  0012c4:  2f 08                move.l   a0, -(a7)
  0012c6:  20 78 08 88          movea.l  $888.w, a0
  0012ca:  20 50                movea.l  (a0), a0
  0012cc:  2f 00                move.l   d0, -(a7)
  0012ce:  20 10                move.l   (a0), d0
  0012d0:  e1 88                lsl.l    #$8, d0
  0012d2:  e0 88                lsr.l    #$8, d0
  0012d4:  20 40                movea.l  d0, a0
  0012d6:  20 1f                move.l   (a7)+, d0
  0012d8:  41 e8 00 14          lea.l    $14(a0), a0
  0012dc:  2f 28 01 90          move.l   $190(a0), -(a7)
  0012e0:  20 6f 00 04          movea.l  $4(a7), a0
  0012e4:  2e 9f                move.l   (a7)+, (a7)
  0012e6:  4e 75                rts      
  0012e8:  60 ff 00 00 ac 22    bra.l    $bf0c  ; -> handler_100
  0012ee:  4e 71                nop      
disp_101:
  0012f0:  00 00 16 8c          dc.l     $0000168C  ; dispatch #101, Am29000 cmd/offset $168C
L12f4:
  0012f4:  2f 08                move.l   a0, -(a7)
  0012f6:  20 78 08 88          movea.l  $888.w, a0
  0012fa:  20 50                movea.l  (a0), a0
  0012fc:  2f 00                move.l   d0, -(a7)
  0012fe:  20 10                move.l   (a0), d0
  001300:  e1 88                lsl.l    #$8, d0
  001302:  e0 88                lsr.l    #$8, d0
  001304:  20 40                movea.l  d0, a0
  001306:  20 1f                move.l   (a7)+, d0
  001308:  41 e8 00 14          lea.l    $14(a0), a0
  00130c:  2f 28 01 94          move.l   $194(a0), -(a7)
  001310:  20 6f 00 04          movea.l  $4(a7), a0
  001314:  2e 9f                move.l   (a7)+, (a7)
  001316:  4e 75                rts      
  001318:  60 ff 00 00 a9 28    bra.l    $bc42  ; -> handler_101
  00131e:  4e 71                nop      
disp_102:
  001320:  00 00 05 90          dc.l     $00000590  ; dispatch #102, Am29000 cmd/offset $590
L1324:
  001324:  2f 08                move.l   a0, -(a7)
  001326:  20 78 08 88          movea.l  $888.w, a0
  00132a:  20 50                movea.l  (a0), a0
  00132c:  2f 00                move.l   d0, -(a7)
  00132e:  20 10                move.l   (a0), d0
  001330:  e1 88                lsl.l    #$8, d0
  001332:  e0 88                lsr.l    #$8, d0
  001334:  20 40                movea.l  d0, a0
  001336:  20 1f                move.l   (a7)+, d0
  001338:  41 e8 00 14          lea.l    $14(a0), a0
  00133c:  2f 28 01 98          move.l   $198(a0), -(a7)
  001340:  20 6f 00 04          movea.l  $4(a7), a0
  001344:  2e 9f                move.l   (a7)+, (a7)
  001346:  4e 75                rts      
  001348:  60 ff 00 00 6a 92    bra.l    $7ddc  ; -> GA_MoveHHi
  00134e:  4e 71                nop      
disp_103:
  001350:  ff ff ff ff          dc.l     $FFFFFFFF  ; dispatch #103, Am29000 cmd/offset $FFFFFFFF
L1354:
  001354:  2f 08                move.l   a0, -(a7)
  001356:  20 78 08 88          movea.l  $888.w, a0
  00135a:  20 50                movea.l  (a0), a0
  00135c:  2f 00                move.l   d0, -(a7)
  00135e:  20 10                move.l   (a0), d0
  001360:  e1 88                lsl.l    #$8, d0
  001362:  e0 88                lsr.l    #$8, d0
  001364:  20 40                movea.l  d0, a0
  001366:  20 1f                move.l   (a7)+, d0
  001368:  41 e8 00 14          lea.l    $14(a0), a0
  00136c:  2f 28 01 9c          move.l   $19c(a0), -(a7)
  001370:  20 6f 00 04          movea.l  $4(a7), a0
  001374:  2e 9f                move.l   (a7)+, (a7)
  001376:  4e 75                rts      
  001378:  60 ff 00 00 59 10    bra.l    $6c8a  ; -> handler_103
  00137e:  4e 71                nop      
disp_104:
  001380:  ff ff ff fe          dc.l     $FFFFFFFE  ; dispatch #104, Am29000 cmd/offset $FFFFFFFE
L1384:
  001384:  2f 08                move.l   a0, -(a7)
  001386:  20 78 08 88          movea.l  $888.w, a0
  00138a:  20 50                movea.l  (a0), a0
  00138c:  2f 00                move.l   d0, -(a7)
  00138e:  20 10                move.l   (a0), d0
  001390:  e1 88                lsl.l    #$8, d0
  001392:  e0 88                lsr.l    #$8, d0
  001394:  20 40                movea.l  d0, a0
  001396:  20 1f                move.l   (a7)+, d0
  001398:  41 e8 00 14          lea.l    $14(a0), a0
  00139c:  2f 28 01 a0          move.l   $1a0(a0), -(a7)
  0013a0:  20 6f 00 04          movea.l  $4(a7), a0
  0013a4:  2e 9f                move.l   (a7)+, (a7)
  0013a6:  4e 75                rts      
  0013a8:  60 ff 00 00 59 74    bra.l    $6d1e  ; -> handler_104
  0013ae:  4e 71                nop      
disp_105:
  0013b0:  ff ff ff fd          dc.l     $FFFFFFFD  ; dispatch #105, Am29000 cmd/offset $FFFFFFFD
L13b4:
  0013b4:  2f 08                move.l   a0, -(a7)
  0013b6:  20 78 08 88          movea.l  $888.w, a0
  0013ba:  20 50                movea.l  (a0), a0
  0013bc:  2f 00                move.l   d0, -(a7)
  0013be:  20 10                move.l   (a0), d0
  0013c0:  e1 88                lsl.l    #$8, d0
  0013c2:  e0 88                lsr.l    #$8, d0
  0013c4:  20 40                movea.l  d0, a0
  0013c6:  20 1f                move.l   (a7)+, d0
  0013c8:  41 e8 00 14          lea.l    $14(a0), a0
  0013cc:  2f 28 01 a4          move.l   $1a4(a0), -(a7)
  0013d0:  20 6f 00 04          movea.l  $4(a7), a0
  0013d4:  2e 9f                move.l   (a7)+, (a7)
  0013d6:  4e 75                rts      
  0013d8:  60 ff 00 00 58 96    bra.l    $6c70  ; -> handler_105
  0013de:  4e 71                nop      
  0013e0:  00 00 00 00          ori.b    #$0, d0
  0013e4:  00 00 00 00          ori.b    #$0, d0
  0013e8:  00 00 00 00          ori.b    #$0, d0
  0013ec:  00 00 00 00          ori.b    #$0, d0
  0013f0:  00 00 00 00          ori.b    #$0, d0
  0013f4:  00 00 00 00          ori.b    #$0, d0
  0013f8:  00 00 00 00          ori.b    #$0, d0
  0013fc:  00 00 00 00          ori.b    #$0, d0
  001400:  00 00 00 00          ori.b    #$0, d0
sub_1404:
  001404:  4e 56 ff b2          link.w   a6, #$ffb2
  001408:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  00140c:  28 6e 00 0c          movea.l  $c(a6), a4
  001410:  7c ce                moveq    #$ce, d6
  001412:  42 04                clr.b    d4
  001414:  1d 7c 00 01 ff bf    move.b   #$1, -$41(a6)
  00141a:  20 6e 00 10          movea.l  $10(a6), a0
  00141e:  4a 90                tst.l    (a0)
  001420:  66 1a                bne.b    $143c  ; -> L143c
  001422:  70 7a                moveq    #$7a, d0
  001424:  a7 22                dc.w     $a722  ; _NewHandle,SYS,CLEAR
  001426:  26 48                movea.l  a0, a3
  001428:  20 6e 00 10          movea.l  $10(a6), a0
  00142c:  20 8b                move.l   a3, (a0)
  00142e:  2d 4b ff b2          move.l   a3, -$4e(a6)
  001432:  20 4b                movea.l  a3, a0
  001434:  20 50                movea.l  (a0), a0
  001436:  70 00                moveq    #$0, d0
  001438:  21 40 00 66          move.l   d0, $66(a0)
L143c:
  00143c:  20 6e 00 10          movea.l  $10(a6), a0
  001440:  26 50                movea.l  (a0), a3
  001442:  20 4b                movea.l  a3, a0
  001444:  a0 29                dc.w     $a029  ; _HLock
  001446:  2d 4b ff b2          move.l   a3, -$4e(a6)
  00144a:  20 2e 00 08          move.l   $8(a6), d0
  00144e:  52 80                addq.l   #$1, d0
  001450:  67 50                beq.b    $14a2  ; -> L14a2
  001452:  53 80                subq.l   #$1, d0
  001454:  67 5a                beq.b    $14b0  ; -> L14b0
  001456:  53 80                subq.l   #$1, d0
  001458:  67 6a                beq.b    $14c4  ; -> L14c4
  00145a:  53 80                subq.l   #$1, d0
  00145c:  67 7c                beq.b    $14da  ; -> L14da
  00145e:  53 80                subq.l   #$1, d0
  001460:  67 00 00 8a          beq.w    $14ec  ; -> L14ec
  001464:  53 80                subq.l   #$1, d0
  001466:  67 00 00 96          beq.w    $14fe  ; -> L14fe
  00146a:  53 80                subq.l   #$1, d0
  00146c:  67 00 00 a2          beq.w    $1510  ; -> L1510
  001470:  53 80                subq.l   #$1, d0
  001472:  67 00 00 ba          beq.w    $152e  ; -> L152e
  001476:  53 80                subq.l   #$1, d0
  001478:  67 00 00 c6          beq.w    $1540  ; -> L1540
  00147c:  53 80                subq.l   #$1, d0
  00147e:  67 00 00 d2          beq.w    $1552  ; -> L1552
  001482:  53 80                subq.l   #$1, d0
  001484:  67 00 00 de          beq.w    $1564  ; -> L1564
  001488:  53 80                subq.l   #$1, d0
  00148a:  67 00 00 de          beq.w    $156a  ; -> L156a
  00148e:  53 80                subq.l   #$1, d0
  001490:  67 00 00 dc          beq.w    $156e  ; -> L156e
  001494:  04 80 00 00 03 dc    subi.l   #$3dc, d0
  00149a:  67 00 00 ec          beq.w    $1588  ; -> L1588
  00149e:  60 00 01 4a          bra.w    $15ea  ; -> L15ea
L14a2:
  0014a2:  20 6e ff b2          movea.l  -$4e(a6), a0
  0014a6:  20 50                movea.l  (a0), a0
  0014a8:  2c 28 00 6a          move.l   $6a(a0), d6
  0014ac:  60 00 01 3c          bra.w    $15ea  ; -> L15ea
L14b0:
  0014b0:  59 8f                subq.l   #$4, a7
  0014b2:  70 00                moveq    #$0, d0
  0014b4:  3f 00                move.w   d0, -(a7)
  0014b6:  2f 0b                move.l   a3, -(a7)
  0014b8:  61 ff 00 00 01 4a    bsr.l    $1604  ; -> sub_1604
  0014be:  2c 1f                move.l   (a7)+, d6
  0014c0:  60 00 01 28          bra.w    $15ea  ; -> L15ea
L14c4:
  0014c4:  59 8f                subq.l   #$4, a7
  0014c6:  2f 0b                move.l   a3, -(a7)
  0014c8:  2f 14                move.l   (a4), -(a7)
  0014ca:  2f 2c 00 04          move.l   $4(a4), -(a7)
  0014ce:  61 ff 00 00 05 5e    bsr.l    $1a2e  ; -> sub_1a2e
  0014d4:  2c 1f                move.l   (a7)+, d6
  0014d6:  60 00 01 12          bra.w    $15ea  ; -> L15ea
L14da:
  0014da:  59 8f                subq.l   #$4, a7
  0014dc:  2f 0b                move.l   a3, -(a7)
  0014de:  2f 14                move.l   (a4), -(a7)
  0014e0:  61 ff 00 00 06 5a    bsr.l    $1b3c  ; -> sub_1b3c
  0014e6:  2c 1f                move.l   (a7)+, d6
  0014e8:  60 00 01 00          bra.w    $15ea  ; -> L15ea
L14ec:
  0014ec:  59 8f                subq.l   #$4, a7
  0014ee:  2f 0b                move.l   a3, -(a7)
  0014f0:  2f 14                move.l   (a4), -(a7)
  0014f2:  61 ff 00 00 07 a0    bsr.l    $1c94  ; -> sub_1c94
  0014f8:  2c 1f                move.l   (a7)+, d6
  0014fa:  60 00 00 ee          bra.w    $15ea  ; -> L15ea
L14fe:
  0014fe:  59 8f                subq.l   #$4, a7
  001500:  2f 0b                move.l   a3, -(a7)
  001502:  2f 14                move.l   (a4), -(a7)
  001504:  61 ff 00 00 08 6a    bsr.l    $1d70  ; -> sub_1d70
  00150a:  2c 1f                move.l   (a7)+, d6
  00150c:  60 00 00 dc          bra.w    $15ea  ; -> L15ea
L1510:
  001510:  59 8f                subq.l   #$4, a7
  001512:  2f 0b                move.l   a3, -(a7)
  001514:  2f 14                move.l   (a4), -(a7)
  001516:  2f 2c 00 04          move.l   $4(a4), -(a7)
  00151a:  2f 2c 00 08          move.l   $8(a4), -(a7)
  00151e:  2f 2c 00 0c          move.l   $c(a4), -(a7)
  001522:  61 ff 00 00 08 ee    bsr.l    $1e12  ; -> sub_1e12
  001528:  2c 1f                move.l   (a7)+, d6
  00152a:  60 00 00 be          bra.w    $15ea  ; -> L15ea
L152e:
  00152e:  59 8f                subq.l   #$4, a7
  001530:  2f 0b                move.l   a3, -(a7)
  001532:  2f 14                move.l   (a4), -(a7)
  001534:  61 ff 00 00 09 48    bsr.l    $1e7e  ; -> sub_1e7e
  00153a:  2c 1f                move.l   (a7)+, d6
  00153c:  60 00 00 ac          bra.w    $15ea  ; -> L15ea
L1540:
  001540:  59 8f                subq.l   #$4, a7
  001542:  2f 0b                move.l   a3, -(a7)
  001544:  2f 14                move.l   (a4), -(a7)
  001546:  61 ff 00 00 0a 8e    bsr.l    $1fd6  ; -> sub_1fd6
  00154c:  2c 1f                move.l   (a7)+, d6
  00154e:  60 00 00 9a          bra.w    $15ea  ; -> L15ea
L1552:
  001552:  59 8f                subq.l   #$4, a7
  001554:  2f 0b                move.l   a3, -(a7)
  001556:  2f 14                move.l   (a4), -(a7)
  001558:  61 ff 00 00 0b d6    bsr.l    $2130  ; -> sub_2130
  00155e:  2c 1f                move.l   (a7)+, d6
  001560:  60 00 00 88          bra.w    $15ea  ; -> L15ea
L1564:
  001564:  7c 01                moveq    #$1, d6
  001566:  60 00 00 82          bra.w    $15ea  ; -> L15ea
L156a:
  00156a:  7c 00                moveq    #$0, d6
  00156c:  60 7c                bra.b    $15ea  ; -> L15ea
L156e:
  00156e:  55 8f                subq.l   #$2, a7
  001570:  20 6e ff b2          movea.l  -$4e(a6), a0
  001574:  20 50                movea.l  (a0), a0
  001576:  2f 28 00 66          move.l   $66(a0), -(a7)
  00157a:  61 ff 00 00 0d 5e    bsr.l    $22da  ; -> sub_22da
  001580:  30 1f                move.w   (a7)+, d0
  001582:  48 c0                ext.l    d0
  001584:  2c 00                move.l   d0, d6
  001586:  60 62                bra.b    $15ea  ; -> L15ea
L1588:
  001588:  28 14                move.l   (a4), d4
  00158a:  2d 6c 00 04 ff b6    move.l   $4(a4), -$4a(a6)
  001590:  2a 2c 00 08          move.l   $8(a4), d5
  001594:  2d 6c 00 0c ff ba    move.l   $c(a4), -$46(a6)
  00159a:  41 ee ff bf          lea.l    -$41(a6), a0
  00159e:  10 10                move.b   (a0), d0
  0015a0:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  0015a2:  10 80                move.b   d0, (a0)
  0015a4:  42 47                clr.w    d7
  0015a6:  60 14                bra.b    $15bc  ; -> L15bc
L15a8:
  0015a8:  48 c7                ext.l    d7
  0015aa:  20 6e ff ba          movea.l  -$46(a6), a0
  0015ae:  20 07                move.l   d7, d0
  0015b0:  e5 40                asl.w    #$2, d0
  0015b2:  2d b0 7c 00 00 c0    move.l   (a0, d7.l * 4), -$40(a6, d0.w)
  0015b8:  30 07                move.w   d7, d0
  0015ba:  52 47                addq.w   #$1, d7
L15bc:
  0015bc:  48 c7                ext.l    d7
  0015be:  ba 87                cmp.l    d7, d5
  0015c0:  6e e6                bgt.b    $15a8  ; -> L15a8
  0015c2:  41 ee ff bf          lea.l    -$41(a6), a0
  0015c6:  10 10                move.b   (a0), d0
  0015c8:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  0015ca:  10 80                move.b   d0, (a0)
  0015cc:  48 6e ff c0          pea.l    -$40(a6)
  0015d0:  2f 05                move.l   d5, -(a7)
  0015d2:  2f 2e ff b6          move.l   -$4a(a6), -(a7)
  0015d6:  2f 04                move.l   d4, -(a7)
  0015d8:  20 6e ff b2          movea.l  -$4e(a6), a0
  0015dc:  2f 10                move.l   (a0), -(a7)
  0015de:  61 ff 00 00 02 de    bsr.l    $18be  ; -> sub_18be
  0015e4:  2c 00                move.l   d0, d6
  0015e6:  4f ef 00 14          lea.l    $14(a7), a7
L15ea:
  0015ea:  20 4b                movea.l  a3, a0
  0015ec:  a0 2a                dc.w     $a02a  ; _HUnlock
  0015ee:  20 6e ff b2          movea.l  -$4e(a6), a0
  0015f2:  20 50                movea.l  (a0), a0
  0015f4:  21 46 00 6a          move.l   d6, $6a(a0)
  0015f8:  20 06                move.l   d6, d0
  0015fa:  4c ee 18 f0 ff 9a    movem.l  -$66(a6), d4-d7/a3-a4
  001600:  4e 5e                unlk     a6
  001602:  4e 75                rts      
sub_1604:
  001604:  4e 56 00 00          link.w   a6, #$0
  001608:  48 e7 13 18          movem.l  d3/d6-d7/a3-a4, -(a7)
  00160c:  26 6e 00 08          movea.l  $8(a6), a3
  001610:  7c 00                moveq    #$0, d6
  001612:  20 4b                movea.l  a3, a0
  001614:  70 7a                moveq    #$7a, d0
  001616:  a0 24                dc.w     $a024  ; _SetPtrSize
  001618:  30 38 02 20          move.w   $220.w, d0
  00161c:  48 c0                ext.l    d0
  00161e:  2c 00                move.l   d0, d6
  001620:  67 08                beq.b    $162a  ; -> L162a
  001622:  2d 46 00 0e          move.l   d6, $e(a6)
  001626:  60 00 01 7e          bra.w    $17a6  ; -> L17a6
L162a:
  00162a:  20 4b                movea.l  a3, a0
  00162c:  a0 29                dc.w     $a029  ; _HLock
  00162e:  59 8f                subq.l   #$4, a7
  001630:  2f 13                move.l   (a3), -(a7)
  001632:  61 ff 00 00 ac 16    bsr.l    $c24a  ; -> Strip24
  001638:  28 5f                movea.l  (a7)+, a4
  00163a:  42 6c 00 0c          clr.w    $c(a4)
  00163e:  70 00                moveq    #$0, d0
  001640:  29 40 00 08          move.l   d0, $8(a4)
  001644:  29 40 00 66          move.l   d0, $66(a4)
  001648:  59 8f                subq.l   #$4, a7
  00164a:  30 2e 00 0c          move.w   $c(a6), d0
  00164e:  48 c0                ext.l    d0
  001650:  2f 00                move.l   d0, -(a7)
  001652:  61 ff 00 00 0c 08    bsr.l    $225c  ; -> sub_225c
  001658:  29 5f 00 66          move.l   (a7)+, $66(a4)
  00165c:  66 0a                bne.b    $1668  ; -> L1668
  00165e:  70 ff                moveq    #$ff, d0
  001660:  2d 40 00 0e          move.l   d0, $e(a6)
  001664:  60 00 01 40          bra.w    $17a6  ; -> L17a6
L1668:
  001668:  20 3c 00 00 01 c0    move.l   #$1c0, d0
  00166e:  a5 1e                dc.w     $a51e  ; _NewPtrSys
  001670:  28 88                move.l   a0, (a4)
  001672:  26 48                movea.l  a0, a3
  001674:  20 0b                move.l   a3, d0
  001676:  66 20                bne.b    $1698  ; -> L1698
  001678:  55 8f                subq.l   #$2, a7
  00167a:  2f 2c 00 66          move.l   $66(a4), -(a7)
  00167e:  70 01                moveq    #$1, d0
  001680:  1f 00                move.b   d0, -(a7)
  001682:  61 ff 00 00 0c 42    bsr.l    $22c6  ; -> sub_22c6
  001688:  30 38 02 20          move.w   $220.w, d0
  00168c:  48 c0                ext.l    d0
  00168e:  2d 40 00 0e          move.l   d0, $e(a6)
  001692:  54 4f                addq.w   #$2, a7
  001694:  60 00 01 10          bra.w    $17a6  ; -> L17a6
L1698:
  001698:  42 47                clr.w    d7
  00169a:  76 10                moveq    #$10, d3
L169c:
  00169c:  70 00                moveq    #$0, d0
  00169e:  26 80                move.l   d0, (a3)
  0016a0:  30 07                move.w   d7, d0
  0016a2:  52 47                addq.w   #$1, d7
  0016a4:  47 eb 00 1c          lea.l    $1c(a3), a3
  0016a8:  b6 47                cmp.w    d7, d3
  0016aa:  6e f0                bgt.b    $169c  ; -> L169c
  0016ac:  70 10                moveq    #$10, d0
  0016ae:  29 40 00 5e          move.l   d0, $5e(a4)
  0016b2:  20 3c 00 00 04 00    move.l   #$400, d0
  0016b8:  a5 1e                dc.w     $a51e  ; _NewPtrSys
  0016ba:  29 48 00 04          move.l   a0, $4(a4)
  0016be:  26 48                movea.l  a0, a3
  0016c0:  20 0b                move.l   a3, d0
  0016c2:  66 24                bne.b    $16e8  ; -> L16e8
  0016c4:  20 54                movea.l  (a4), a0
  0016c6:  a0 1f                dc.w     $a01f  ; _DisposePtr
  0016c8:  55 8f                subq.l   #$2, a7
  0016ca:  2f 2c 00 66          move.l   $66(a4), -(a7)
  0016ce:  70 01                moveq    #$1, d0
  0016d0:  1f 00                move.b   d0, -(a7)
  0016d2:  61 ff 00 00 0b f2    bsr.l    $22c6  ; -> sub_22c6
  0016d8:  30 38 02 20          move.w   $220.w, d0
  0016dc:  48 c0                ext.l    d0
  0016de:  2d 40 00 0e          move.l   d0, $e(a6)
  0016e2:  54 4f                addq.w   #$2, a7
  0016e4:  60 00 00 c0          bra.w    $17a6  ; -> L17a6
L16e8:
  0016e8:  42 47                clr.w    d7
  0016ea:  76 20                moveq    #$20, d3
L16ec:
  0016ec:  70 00                moveq    #$0, d0
  0016ee:  26 80                move.l   d0, (a3)
  0016f0:  30 07                move.w   d7, d0
  0016f2:  52 47                addq.w   #$1, d7
  0016f4:  47 eb 00 20          lea.l    $20(a3), a3
  0016f8:  b6 47                cmp.w    d7, d3
  0016fa:  6e f0                bgt.b    $16ec  ; -> L16ec
  0016fc:  70 20                moveq    #$20, d0
  0016fe:  29 40 00 5a          move.l   d0, $5a(a4)
  001702:  72 03                moveq    #$3, d1
  001704:  29 41 00 56          move.l   d1, $56(a4)
  001708:  29 7c 11 11 11 11 00 16 move.l   #$11111111, $16(a4)
  001710:  29 7c 22 22 22 22 00 1a move.l   #$22222222, $1a(a4)  ; '""""'
  001718:  29 7c 33 33 33 33 00 1e move.l   #$33333333, $1e(a4)  ; '3333'
  001720:  29 7c 00 00 80 04 00 0e move.l   #$8004, $e(a4)
  001728:  70 00                moveq    #$0, d0
  00172a:  29 40 00 12          move.l   d0, $12(a4)
  00172e:  42 2c 00 0d          clr.b    $d(a4)
  001732:  19 7c 00 01 00 0c    move.b   #$1, $c(a4)
  001738:  20 6c 00 66          movea.l  $66(a4), a0
  00173c:  20 50                movea.l  (a0), a0
  00173e:  21 4c 00 6c          move.l   a4, $6c(a0)
  001742:  60 0e                bra.b    $1752  ; -> L1752
L1744:
  001744:  55 8f                subq.l   #$2, a7
  001746:  2f 2c 00 66          move.l   $66(a4), -(a7)
  00174a:  61 ff 00 00 0b 8e    bsr.l    $22da  ; -> sub_22da
  001750:  54 4f                addq.w   #$2, a7
L1752:
  001752:  4a 2c 00 0d          tst.b    $d(a4)
  001756:  67 ec                beq.b    $1744  ; -> L1744
  001758:  0c ac 66 66 66 66 00 12 cmpi.l   #$66666666, $12(a4)  ; 'ffff'
  001760:  67 24                beq.b    $1786  ; -> L1786
  001762:  20 54                movea.l  (a4), a0
  001764:  a0 1f                dc.w     $a01f  ; _DisposePtr
  001766:  20 6c 00 04          movea.l  $4(a4), a0
  00176a:  a0 1f                dc.w     $a01f  ; _DisposePtr
  00176c:  55 8f                subq.l   #$2, a7
  00176e:  2f 2c 00 66          move.l   $66(a4), -(a7)
  001772:  70 01                moveq    #$1, d0
  001774:  1f 00                move.b   d0, -(a7)
  001776:  61 ff 00 00 0b 4e    bsr.l    $22c6  ; -> sub_22c6
  00177c:  70 fc                moveq    #$fc, d0
  00177e:  2d 40 00 0e          move.l   d0, $e(a6)
  001782:  54 4f                addq.w   #$2, a7
  001784:  60 20                bra.b    $17a6  ; -> L17a6
L1786:
  001786:  70 5c                moveq    #$5c, d0
  001788:  2f 00                move.l   d0, -(a7)
  00178a:  2f 0c                move.l   a4, -(a7)
  00178c:  61 ff 00 00 0a 2e    bsr.l    $21bc  ; -> sub_21bc
  001792:  29 40 00 76          move.l   d0, $76(a4)
  001796:  50 4f                addq.w   #$8, a7
  001798:  66 08                bne.b    $17a2  ; -> L17a2
  00179a:  70 fb                moveq    #$fb, d0
  00179c:  2d 40 00 0e          move.l   d0, $e(a6)
  0017a0:  60 04                bra.b    $17a6  ; -> L17a6
L17a2:
  0017a2:  2d 46 00 0e          move.l   d6, $e(a6)
L17a6:
  0017a6:  4c ee 18 c8 ff ec    movem.l  -$14(a6), d3/d6-d7/a3-a4
  0017ac:  4e 5e                unlk     a6
  0017ae:  4e 74 00 06          rtd      #$6
sub_17b2:
  0017b2:  4e 56 00 00          link.w   a6, #$0
  0017b6:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  0017ba:  26 6e 00 08          movea.l  $8(a6), a3
  0017be:  2c 2e 00 0c          move.l   $c(a6), d6
  0017c2:  28 53                movea.l  (a3), a4
  0017c4:  4a 86                tst.l    d6
  0017c6:  67 10                beq.b    $17d8  ; -> L17d8
  0017c8:  20 3c ff 00 00 00    move.l   #$ff000000, d0
  0017ce:  c0 86                and.l    d6, d0
  0017d0:  0c 80 53 00 00 00    cmpi.l   #$53000000, d0
  0017d6:  66 2c                bne.b    $1804  ; -> L1804
L17d8:
  0017d8:  42 47                clr.w    d7
  0017da:  60 20                bra.b    $17fc  ; -> L17fc
L17dc:
  0017dc:  20 3c 00 00 ff ff    move.l   #$ffff, d0
  0017e2:  c0 94                and.l    (a4), d0
  0017e4:  22 3c 00 00 ff ff    move.l   #$ffff, d1
  0017ea:  c2 86                and.l    d6, d1
  0017ec:  b2 80                cmp.l    d0, d1
  0017ee:  66 04                bne.b    $17f4  ; -> L17f4
  0017f0:  20 0c                move.l   a4, d0
  0017f2:  60 12                bra.b    $1806  ; -> L1806
L17f4:
  0017f4:  30 07                move.w   d7, d0
  0017f6:  52 47                addq.w   #$1, d7
  0017f8:  49 ec 00 1c          lea.l    $1c(a4), a4
L17fc:
  0017fc:  48 c7                ext.l    d7
  0017fe:  be ab 00 5e          cmp.l    $5e(a3), d7
  001802:  6d d8                blt.b    $17dc  ; -> L17dc
L1804:
  001804:  70 00                moveq    #$0, d0
L1806:
  001806:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  00180c:  4e 5e                unlk     a6
  00180e:  4e 75                rts      
sub_1810:
  001810:  4e 56 ff fc          link.w   a6, #$fffc
  001814:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  001818:  2c 2e 00 10          move.l   $10(a6), d6
  00181c:  26 6e 00 0c          movea.l  $c(a6), a3
  001820:  2e 2e 00 08          move.l   $8(a6), d7
  001824:  70 00                moveq    #$0, d0
  001826:  2d 40 ff fc          move.l   d0, -$4(a6)
  00182a:  4a 87                tst.l    d7
  00182c:  6e 06                bgt.b    $1834  ; -> L1834
  00182e:  70 ff                moveq    #$ff, d0
  001830:  60 00 00 82          bra.w    $18b4  ; -> L18b4
L1834:
  001834:  20 6e 00 14          movea.l  $14(a6), a0
  001838:  28 68 00 04          movea.l  $4(a0), a4
  00183c:  60 14                bra.b    $1852  ; -> L1852
L183e:
  00183e:  be 94                cmp.l    (a4), d7
  001840:  66 08                bne.b    $184a  ; -> L184a
  001842:  29 4b 00 04          move.l   a3, $4(a4)
  001846:  70 00                moveq    #$0, d0
  001848:  60 6a                bra.b    $18b4  ; -> L18b4
L184a:
  00184a:  2d 4c ff fc          move.l   a4, -$4(a6)
  00184e:  28 6c 00 0c          movea.l  $c(a4), a4
L1852:
  001852:  20 0c                move.l   a4, d0
  001854:  66 e8                bne.b    $183e  ; -> L183e
  001856:  20 6e 00 14          movea.l  $14(a6), a0
  00185a:  4a a8 00 04          tst.l    $4(a0)
  00185e:  66 2a                bne.b    $188a  ; -> L188a
  001860:  70 10                moveq    #$10, d0
  001862:  a5 1e                dc.w     $a51e  ; _NewPtrSys
  001864:  28 48                movea.l  a0, a4
  001866:  20 0c                move.l   a4, d0
  001868:  66 06                bne.b    $1870  ; -> L1870
  00186a:  30 38 02 20          move.w   $220.w, d0
  00186e:  60 44                bra.b    $18b4  ; -> L18b4
L1870:
  001870:  70 00                moveq    #$0, d0
  001872:  29 40 00 0c          move.l   d0, $c(a4)
  001876:  28 87                move.l   d7, (a4)
  001878:  29 4b 00 04          move.l   a3, $4(a4)
  00187c:  29 46 00 08          move.l   d6, $8(a4)
  001880:  20 6e 00 14          movea.l  $14(a6), a0
  001884:  21 4c 00 04          move.l   a4, $4(a0)
  001888:  60 28                bra.b    $18b2  ; -> L18b2
L188a:
  00188a:  70 10                moveq    #$10, d0
  00188c:  a5 1e                dc.w     $a51e  ; _NewPtrSys
  00188e:  28 48                movea.l  a0, a4
  001890:  20 0c                move.l   a4, d0
  001892:  66 06                bne.b    $189a  ; -> L189a
  001894:  30 38 02 20          move.w   $220.w, d0
  001898:  60 1a                bra.b    $18b4  ; -> L18b4
L189a:
  00189a:  70 00                moveq    #$0, d0
  00189c:  29 40 00 0c          move.l   d0, $c(a4)
  0018a0:  28 87                move.l   d7, (a4)
  0018a2:  29 4b 00 04          move.l   a3, $4(a4)
  0018a6:  29 46 00 08          move.l   d6, $8(a4)
  0018aa:  20 6e ff fc          movea.l  -$4(a6), a0
  0018ae:  21 4c 00 0c          move.l   a4, $c(a0)
L18b2:
  0018b2:  70 00                moveq    #$0, d0
L18b4:
  0018b4:  4c ee 18 c0 ff ec    movem.l  -$14(a6), d6-d7/a3-a4
  0018ba:  4e 5e                unlk     a6
  0018bc:  4e 75                rts      
sub_18be:
  0018be:  4e 56 00 00          link.w   a6, #$0
  0018c2:  48 e7 07 18          movem.l  d5-d7/a3-a4, -(a7)
  0018c6:  2e 2e 00 0c          move.l   $c(a6), d7
  0018ca:  28 6e 00 08          movea.l  $8(a6), a4
  0018ce:  2a 2e 00 14          move.l   $14(a6), d5
  0018d2:  2c 2e 00 10          move.l   $10(a6), d6
  0018d6:  70 00                moveq    #$0, d0
  0018d8:  26 40                movea.l  d0, a3
  0018da:  4a 87                tst.l    d7
  0018dc:  67 28                beq.b    $1906  ; -> L1906
  0018de:  20 3c ff 00 00 00    move.l   #$ff000000, d0
  0018e4:  c0 87                and.l    d7, d0
  0018e6:  0c 80 54 00 00 00    cmpi.l   #$54000000, d0
  0018ec:  67 06                beq.b    $18f4  ; -> L18f4
  0018ee:  70 ff                moveq    #$ff, d0
  0018f0:  60 00 01 32          bra.w    $1a24  ; -> L1a24
L18f4:
  0018f4:  20 3c 00 00 ff ff    move.l   #$ffff, d0
  0018fa:  c0 87                and.l    d7, d0
  0018fc:  20 6c 00 04          movea.l  $4(a4), a0
  001900:  eb 80                asl.l    #$5, d0
  001902:  47 f0 08 00          lea.l    (a0, d0.l), a3
L1906:
  001906:  4a 86                tst.l    d6
  001908:  6e 00 00 e0          bgt.w    $19ea  ; -> L19ea
  00190c:  20 06                move.l   d6, d0
  00190e:  04 80 ff ff 80 00    subi.l   #$ffff8000, d0
  001914:  6b 00 00 d0          bmi.w    $19e6  ; -> L19e6
  001918:  0c 80 00 00 00 10    cmpi.l   #$10, d0
  00191e:  6e 00 00 c6          bgt.w    $19e6  ; -> L19e6
  001922:  d0 80                add.l    d0, d0
  001924:  30 3b 08 06          move.w   $192c(pc, d0.l), d0
  001928:  4e fb 00 00          jmp      $192a(pc,d0.w)  ; -> L192a
* jump table (word offsets relative to $192A, indexed by selector*2):
  00192c:  00 f8                dc.w     $00F8    ; case 1 -> L1a22
  00192e:  00 bc                dc.w     $00BC    ; case 2 -> L19e6
  001930:  00 38                dc.w     $0038    ; case 3 -> L1962
  001932:  00 28                dc.w     $0028    ; case 4 -> L1952
  001934:  00 60                dc.w     $0060    ; case 5 -> L198a
  001936:  00 74                dc.w     $0074    ; case 6 -> L199e
  001938:  00 8a                dc.w     $008A    ; case 7 -> L19b4
  00193a:  00 98                dc.w     $0098    ; case 8 -> L19c2
  00193c:  00 bc                dc.w     $00BC    ; case 9 -> L19e6
  00193e:  00 bc                dc.w     $00BC    ; case 10 -> L19e6
  001940:  00 bc                dc.w     $00BC    ; case 11 -> L19e6
  001942:  00 bc                dc.w     $00BC    ; case 12 -> L19e6
  001944:  00 bc                dc.w     $00BC    ; case 13 -> L19e6
  001946:  00 bc                dc.w     $00BC    ; case 14 -> L19e6
  001948:  00 bc                dc.w     $00BC    ; case 15 -> L19e6
  00194a:  00 bc                dc.w     $00BC    ; case 16 -> L19e6
  00194c:  00 ac                dc.w     $00AC    ; case 17 -> L19d6
  00194e:  60 00                dc.w     $6000    ; case 18 -> L792a
  001950:  00 d2                dc.w     $00D2    ; case 19 -> L19fc
L1952:
  001952:  20 0b                move.l   a3, d0
  001954:  67 06                beq.b    $195c  ; -> L195c
  001956:  70 01                moveq    #$1, d0
  001958:  27 40 00 14          move.l   d0, $14(a3)
L195c:
  00195c:  7e 00                moveq    #$0, d7
  00195e:  60 00 00 c2          bra.w    $1a22  ; -> L1a22
L1962:
  001962:  20 0b                move.l   a3, d0
  001964:  67 10                beq.b    $1976  ; -> L1976
  001966:  20 6e 00 18          movea.l  $18(a6), a0
  00196a:  27 50 00 18          move.l   (a0), $18(a3)
  00196e:  70 02                moveq    #$2, d0
  001970:  27 40 00 14          move.l   d0, $14(a3)
  001974:  60 0e                bra.b    $1984  ; -> L1984
L1976:
  001976:  20 6e 00 18          movea.l  $18(a6), a0
  00197a:  29 50 00 12          move.l   (a0), $12(a4)
  00197e:  19 7c 00 01 00 0d    move.b   #$1, $d(a4)
L1984:
  001984:  7e 00                moveq    #$0, d7
  001986:  60 00 00 9a          bra.w    $1a22  ; -> L1a22
L198a:
  00198a:  20 0b                move.l   a3, d0
  00198c:  67 0a                beq.b    $1998  ; -> L1998
  00198e:  20 53                movea.l  (a3), a0
  001990:  2e 28 00 10          move.l   $10(a0), d7
  001994:  60 00 00 8c          bra.w    $1a22  ; -> L1a22
L1998:
  001998:  7e ce                moveq    #$ce, d7
  00199a:  60 00 00 86          bra.w    $1a22  ; -> L1a22
L199e:
  00199e:  20 0b                move.l   a3, d0
  0019a0:  66 04                bne.b    $19a6  ; -> L19a6
  0019a2:  7e ce                moveq    #$ce, d7
  0019a4:  60 7c                bra.b    $1a22  ; -> L1a22
L19a6:
  0019a6:  20 6e 00 18          movea.l  $18(a6), a0
  0019aa:  22 53                movea.l  (a3), a1
  0019ac:  23 50 00 10          move.l   (a0), $10(a1)
  0019b0:  7e 00                moveq    #$0, d7
  0019b2:  60 6e                bra.b    $1a22  ; -> L1a22
L19b4:
  0019b4:  20 0b                move.l   a3, d0
  0019b6:  66 04                bne.b    $19bc  ; -> L19bc
  0019b8:  7e ce                moveq    #$ce, d7
  0019ba:  60 66                bra.b    $1a22  ; -> L1a22
L19bc:
  0019bc:  2e 2b 00 08          move.l   $8(a3), d7
  0019c0:  60 60                bra.b    $1a22  ; -> L1a22
L19c2:
  0019c2:  20 0b                move.l   a3, d0
  0019c4:  66 04                bne.b    $19ca  ; -> L19ca
  0019c6:  7e ce                moveq    #$ce, d7
  0019c8:  60 58                bra.b    $1a22  ; -> L1a22
L19ca:
  0019ca:  20 6e 00 18          movea.l  $18(a6), a0
  0019ce:  27 50 00 08          move.l   (a0), $8(a3)
  0019d2:  7e 00                moveq    #$0, d7
  0019d4:  60 4c                bra.b    $1a22  ; -> L1a22
L19d6:
  0019d6:  a9 ff                dc.w     $a9ff  ; _Debugger
  0019d8:  20 6e 00 18          movea.l  $18(a6), a0
  0019dc:  4a 90                tst.l    (a0)
  0019de:  67 02                beq.b    $19e2  ; -> L19e2
  0019e0:  7e 01                moveq    #$1, d7
L19e2:
  0019e2:  7e 00                moveq    #$0, d7
  0019e4:  60 3c                bra.b    $1a22  ; -> L1a22
L19e6:
  0019e6:  7e ff                moveq    #$ff, d7
  0019e8:  60 38                bra.b    $1a22  ; -> L1a22
L19ea:
  0019ea:  20 0b                move.l   a3, d0
  0019ec:  67 32                beq.b    $1a20  ; -> L1a20
  0019ee:  28 6b 00 04          movea.l  $4(a3), a4
  0019f2:  60 28                bra.b    $1a1c  ; -> L1a1c
L19f4:
  0019f4:  bc 94                cmp.l    (a4), d6
  0019f6:  66 20                bne.b    $1a18  ; -> L1a18
  0019f8:  4a ac 00 04          tst.l    $4(a4)
L19fc:
  0019fc:  67 1a                beq.b    $1a18  ; -> L1a18
  0019fe:  59 8f                subq.l   #$4, a7
  001a00:  2f 05                move.l   d5, -(a7)
  001a02:  2f 2e 00 18          move.l   $18(a6), -(a7)
  001a06:  2f 2c 00 08          move.l   $8(a4), -(a7)
  001a0a:  2f 2c 00 04          move.l   $4(a4), -(a7)
  001a0e:  20 5f                movea.l  (a7)+, a0
  001a10:  4e 90                jsr      (a0)
  001a12:  2e 1f                move.l   (a7)+, d7
  001a14:  20 07                move.l   d7, d0
  001a16:  60 0c                bra.b    $1a24  ; -> L1a24
L1a18:
  001a18:  28 6c 00 0c          movea.l  $c(a4), a4
L1a1c:
  001a1c:  20 0c                move.l   a4, d0
  001a1e:  66 d4                bne.b    $19f4  ; -> L19f4
L1a20:
  001a20:  7e ff                moveq    #$ff, d7
L1a22:
  001a22:  20 07                move.l   d7, d0
L1a24:
  001a24:  4c ee 18 e0 ff ec    movem.l  -$14(a6), d5-d7/a3-a4
  001a2a:  4e 5e                unlk     a6
  001a2c:  4e 75                rts      
sub_1a2e:
  001a2e:  4e 56 ff f8          link.w   a6, #$fff8
  001a32:  48 e7 13 18          movem.l  d3/d6-d7/a3-a4, -(a7)
  001a36:  2c 2e 00 08          move.l   $8(a6), d6
  001a3a:  59 8f                subq.l   #$4, a7
  001a3c:  20 6e 00 10          movea.l  $10(a6), a0
  001a40:  2f 10                move.l   (a0), -(a7)
  001a42:  61 ff 00 00 a8 06    bsr.l    $c24a  ; -> Strip24
  001a48:  26 5f                movea.l  (a7)+, a3
  001a4a:  60 70                bra.b    $1abc  ; -> L1abc
L1a4c:
  001a4c:  20 2b 00 5e          move.l   $5e(a3), d0
  001a50:  72 10                moveq    #$10, d1
  001a52:  d0 81                add.l    d1, d0
  001a54:  74 1c                moveq    #$1c, d2
  001a56:  4c 02 08 00          muls.l   d2, d0
  001a5a:  a5 1e                dc.w     $a51e  ; _NewPtrSys
  001a5c:  2d 48 ff f8          move.l   a0, -$8(a6)
  001a60:  20 08                move.l   a0, d0
  001a62:  66 0a                bne.b    $1a6e  ; -> L1a6e
  001a64:  70 00                moveq    #$0, d0
  001a66:  2d 40 00 14          move.l   d0, $14(a6)
  001a6a:  60 00 00 c4          bra.w    $1b30  ; -> L1b30
L1a6e:
  001a6e:  20 53                movea.l  (a3), a0
  001a70:  22 6e ff f8          movea.l  -$8(a6), a1
  001a74:  22 2b 00 5e          move.l   $5e(a3), d1
  001a78:  70 1c                moveq    #$1c, d0
  001a7a:  4c 00 18 00          muls.l   d0, d1
  001a7e:  20 01                move.l   d1, d0
  001a80:  a0 2e                dc.w     $a02e  ; _BlockMove
  001a82:  22 2b 00 5e          move.l   $5e(a3), d1
  001a86:  70 1c                moveq    #$1c, d0
  001a88:  4c 00 18 00          muls.l   d0, d1
  001a8c:  28 41                movea.l  d1, a4
  001a8e:  d9 ee ff f8          adda.l   -$8(a6), a4
  001a92:  42 47                clr.w    d7
  001a94:  76 10                moveq    #$10, d3
L1a96:
  001a96:  70 00                moveq    #$0, d0
  001a98:  28 80                move.l   d0, (a4)
  001a9a:  30 07                move.w   d7, d0
  001a9c:  52 47                addq.w   #$1, d7
  001a9e:  49 ec 00 1c          lea.l    $1c(a4), a4
  001aa2:  b6 47                cmp.w    d7, d3
  001aa4:  6e f0                bgt.b    $1a96  ; -> L1a96
  001aa6:  2d 53 ff fc          move.l   (a3), -$4(a6)
  001aaa:  26 ae ff f8          move.l   -$8(a6), (a3)
  001aae:  20 6e ff fc          movea.l  -$4(a6), a0
  001ab2:  a0 1f                dc.w     $a01f  ; _DisposePtr
  001ab4:  06 ab 00 00 00 10 00 5e addi.l   #$10, $5e(a3)
L1abc:
  001abc:  70 00                moveq    #$0, d0
  001abe:  2f 00                move.l   d0, -(a7)
  001ac0:  2f 0b                move.l   a3, -(a7)
  001ac2:  61 ff ff ff fc ee    bsr.l    $17b2  ; -> sub_17b2
  001ac8:  28 40                movea.l  d0, a4
  001aca:  20 0c                move.l   a4, d0
  001acc:  50 4f                addq.w   #$8, a7
  001ace:  67 00 ff 7c          beq.w    $1a4c  ; -> L1a4c
  001ad2:  2f 06                move.l   d6, -(a7)
  001ad4:  2f 0b                move.l   a3, -(a7)
  001ad6:  61 ff 00 00 06 e4    bsr.l    $21bc  ; -> sub_21bc
  001adc:  29 40 00 08          move.l   d0, $8(a4)
  001ae0:  50 4f                addq.w   #$8, a7
  001ae2:  66 08                bne.b    $1aec  ; -> L1aec
  001ae4:  70 00                moveq    #$0, d0
  001ae6:  2d 40 00 14          move.l   d0, $14(a6)
  001aea:  60 44                bra.b    $1b30  ; -> L1b30
L1aec:
  001aec:  29 46 00 04          move.l   d6, $4(a4)
  001af0:  70 00                moveq    #$0, d0
  001af2:  29 40 00 10          move.l   d0, $10(a4)
  001af6:  29 40 00 14          move.l   d0, $14(a4)
  001afa:  2f 06                move.l   d6, -(a7)
  001afc:  2f 2c 00 08          move.l   $8(a4), -(a7)
  001b00:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  001b04:  61 ff 00 00 08 b0    bsr.l    $23b6  ; -> ACEFLoad
  001b0a:  29 40 00 0c          move.l   d0, $c(a4)
  001b0e:  4f ef 00 0c          lea.l    $c(a7), a7
  001b12:  66 08                bne.b    $1b1c  ; -> L1b1c
  001b14:  70 00                moveq    #$0, d0
  001b16:  2d 40 00 14          move.l   d0, $14(a6)
  001b1a:  60 14                bra.b    $1b30  ; -> L1b30
L1b1c:
  001b1c:  52 ab 00 08          addq.l   #$1, $8(a3)
  001b20:  20 3c 53 00 00 00    move.l   #$53000000, d0
  001b26:  80 ab 00 08          or.l     $8(a3), d0
  001b2a:  28 80                move.l   d0, (a4)
  001b2c:  2d 40 00 14          move.l   d0, $14(a6)
L1b30:
  001b30:  4c ee 18 c8 ff e4    movem.l  -$1c(a6), d3/d6-d7/a3-a4
  001b36:  4e 5e                unlk     a6
  001b38:  4e 74 00 0c          rtd      #$c
sub_1b3c:
  001b3c:  4e 56 ff fc          link.w   a6, #$fffc
  001b40:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  001b44:  2c 2e 00 08          move.l   $8(a6), d6
  001b48:  59 8f                subq.l   #$4, a7
  001b4a:  20 6e 00 0c          movea.l  $c(a6), a0
  001b4e:  2f 10                move.l   (a0), -(a7)
  001b50:  61 ff 00 00 a6 f8    bsr.l    $c24a  ; -> Strip24
  001b56:  26 5f                movea.l  (a7)+, a3
  001b58:  20 3c ff 00 00 00    move.l   #$ff000000, d0
  001b5e:  c0 86                and.l    d6, d0
  001b60:  0c 80 53 00 00 00    cmpi.l   #$53000000, d0
  001b66:  67 08                beq.b    $1b70  ; -> L1b70
  001b68:  70 ff                moveq    #$ff, d0
  001b6a:  2d 40 00 10          move.l   d0, $10(a6)
  001b6e:  60 72                bra.b    $1be2  ; -> L1be2
L1b70:
  001b70:  2f 06                move.l   d6, -(a7)
  001b72:  2f 0b                move.l   a3, -(a7)
  001b74:  61 ff ff ff fc 3c    bsr.l    $17b2  ; -> sub_17b2
  001b7a:  2d 40 ff fc          move.l   d0, -$4(a6)
  001b7e:  50 4f                addq.w   #$8, a7
  001b80:  66 08                bne.b    $1b8a  ; -> L1b8a
  001b82:  70 ff                moveq    #$ff, d0
  001b84:  2d 40 00 10          move.l   d0, $10(a6)
  001b88:  60 58                bra.b    $1be2  ; -> L1be2
L1b8a:
  001b8a:  28 6b 00 04          movea.l  $4(a3), a4
  001b8e:  42 47                clr.w    d7
  001b90:  60 2a                bra.b    $1bbc  ; -> L1bbc
L1b92:
  001b92:  20 14                move.l   (a4), d0
  001b94:  b0 ae ff fc          cmp.l    -$4(a6), d0
  001b98:  66 1a                bne.b    $1bb4  ; -> L1bb4
  001b9a:  48 c7                ext.l    d7
  001b9c:  2c 07                move.l   d7, d6
  001b9e:  8c bc 54 00 00 00    or.l     #$54000000, d6
  001ba4:  59 8f                subq.l   #$4, a7
  001ba6:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  001baa:  2f 06                move.l   d6, -(a7)
  001bac:  61 ff 00 00 01 c2    bsr.l    $1d70  ; -> sub_1d70
  001bb2:  58 4f                addq.w   #$4, a7
L1bb4:
  001bb4:  30 07                move.w   d7, d0
  001bb6:  52 47                addq.w   #$1, d7
  001bb8:  49 ec 00 20          lea.l    $20(a4), a4
L1bbc:
  001bbc:  48 c7                ext.l    d7
  001bbe:  be ab 00 5a          cmp.l    $5a(a3), d7
  001bc2:  6d ce                blt.b    $1b92  ; -> L1b92
  001bc4:  20 6e ff fc          movea.l  -$4(a6), a0
  001bc8:  2f 28 00 08          move.l   $8(a0), -(a7)
  001bcc:  2f 0b                move.l   a3, -(a7)
  001bce:  61 ff 00 00 06 3c    bsr.l    $220c  ; -> sub_220c
  001bd4:  20 6e ff fc          movea.l  -$4(a6), a0
  001bd8:  70 00                moveq    #$0, d0
  001bda:  20 80                move.l   d0, (a0)
  001bdc:  2d 40 00 10          move.l   d0, $10(a6)
  001be0:  50 4f                addq.w   #$8, a7
L1be2:
  001be2:  4c ee 18 c0 ff ec    movem.l  -$14(a6), d6-d7/a3-a4
  001be8:  4e 5e                unlk     a6
  001bea:  4e 74 00 08          rtd      #$8
sub_1bee:
  001bee:  4e 56 ff ec          link.w   a6, #$ffec
  001bf2:  48 e7 07 18          movem.l  d5-d7/a3-a4, -(a7)
  001bf6:  26 6e 00 0c          movea.l  $c(a6), a3
  001bfa:  7e 00                moveq    #$0, d7
  001bfc:  59 8f                subq.l   #$4, a7
  001bfe:  20 6e 00 08          movea.l  $8(a6), a0
  001c02:  2f 10                move.l   (a0), -(a7)
  001c04:  61 ff 00 00 a6 44    bsr.l    $c24a  ; -> Strip24
  001c0a:  20 5f                movea.l  (a7)+, a0
  001c0c:  2d 48 ff fc          move.l   a0, -$4(a6)
  001c10:  28 68 00 04          movea.l  $4(a0), a4
  001c14:  42 46                clr.w    d6
  001c16:  60 64                bra.b    $1c7c  ; -> L1c7c
L1c18:
  001c18:  4a 94                tst.l    (a4)
  001c1a:  66 58                bne.b    $1c74  ; -> L1c74
  001c1c:  28 8b                move.l   a3, (a4)
  001c1e:  70 00                moveq    #$0, d0
  001c20:  29 40 00 04          move.l   d0, $4(a4)
  001c24:  29 40 00 08          move.l   d0, $8(a4)
  001c28:  29 40 00 0c          move.l   d0, $c(a4)
  001c2c:  29 40 00 14          move.l   d0, $14(a4)
  001c30:  29 40 00 18          move.l   d0, $18(a4)
  001c34:  48 c6                ext.l    d6
  001c36:  2e 06                move.l   d6, d7
  001c38:  8e bc 54 00 00 00    or.l     #$54000000, d7
  001c3e:  2d 40 ff ec          move.l   d0, -$14(a6)
  001c42:  2d 47 ff f0          move.l   d7, -$10(a6)
  001c46:  42 6e ff f4          clr.w    -$c(a6)
  001c4a:  3d 7c ff ff ff f6    move.w   #$ffff, -$a(a6)
  001c50:  59 8f                subq.l   #$4, a7
  001c52:  2f 2e 00 08          move.l   $8(a6), -(a7)
  001c56:  48 6e ff ec          pea.l    -$14(a6)
  001c5a:  61 ff 00 00 02 22    bsr.l    $1e7e  ; -> sub_1e7e
  001c60:  20 1f                move.l   (a7)+, d0
  001c62:  3a 00                move.w   d0, d5
  001c64:  67 06                beq.b    $1c6c  ; -> L1c6c
  001c66:  70 00                moveq    #$0, d0
  001c68:  28 80                move.l   d0, (a4)
  001c6a:  7e 00                moveq    #$0, d7
L1c6c:
  001c6c:  52 ab 00 14          addq.l   #$1, $14(a3)
  001c70:  20 07                move.l   d7, d0
  001c72:  60 16                bra.b    $1c8a  ; -> L1c8a
L1c74:
  001c74:  30 06                move.w   d6, d0
  001c76:  52 46                addq.w   #$1, d6
  001c78:  49 ec 00 20          lea.l    $20(a4), a4
L1c7c:
  001c7c:  48 c6                ext.l    d6
  001c7e:  20 6e ff fc          movea.l  -$4(a6), a0
  001c82:  bc a8 00 5a          cmp.l    $5a(a0), d6
  001c86:  6d 90                blt.b    $1c18  ; -> L1c18
  001c88:  70 00                moveq    #$0, d0
L1c8a:
  001c8a:  4c ee 18 e0 ff d8    movem.l  -$28(a6), d5-d7/a3-a4
  001c90:  4e 5e                unlk     a6
  001c92:  4e 75                rts      
sub_1c94:
  001c94:  4e 56 ff f4          link.w   a6, #$fff4
  001c98:  48 e7 13 18          movem.l  d3/d6-d7/a3-a4, -(a7)
  001c9c:  2e 2e 00 08          move.l   $8(a6), d7
  001ca0:  7c 00                moveq    #$0, d6
  001ca2:  59 8f                subq.l   #$4, a7
  001ca4:  20 6e 00 0c          movea.l  $c(a6), a0
  001ca8:  2f 10                move.l   (a0), -(a7)
  001caa:  61 ff 00 00 a5 9e    bsr.l    $c24a  ; -> Strip24
  001cb0:  26 5f                movea.l  (a7)+, a3
  001cb2:  20 3c ff 00 00 00    move.l   #$ff000000, d0
  001cb8:  c0 87                and.l    d7, d0
  001cba:  0c 80 53 00 00 00    cmpi.l   #$53000000, d0
  001cc0:  67 0a                beq.b    $1ccc  ; -> L1ccc
  001cc2:  70 00                moveq    #$0, d0
  001cc4:  2d 40 00 10          move.l   d0, $10(a6)
  001cc8:  60 00 00 9a          bra.w    $1d64  ; -> L1d64
L1ccc:
  001ccc:  2f 07                move.l   d7, -(a7)
  001cce:  2f 0b                move.l   a3, -(a7)
  001cd0:  61 ff ff ff fa e0    bsr.l    $17b2  ; -> sub_17b2
  001cd6:  2d 40 ff f4          move.l   d0, -$c(a6)
  001cda:  50 4f                addq.w   #$8, a7
  001cdc:  66 6e                bne.b    $1d4c  ; -> L1d4c
  001cde:  70 00                moveq    #$0, d0
  001ce0:  2d 40 00 10          move.l   d0, $10(a6)
  001ce4:  60 7e                bra.b    $1d64  ; -> L1d64
L1ce6:
  001ce6:  20 2b 00 5a          move.l   $5a(a3), d0
  001cea:  72 20                moveq    #$20, d1
  001cec:  d0 81                add.l    d1, d0
  001cee:  eb 80                asl.l    #$5, d0
  001cf0:  a5 1e                dc.w     $a51e  ; _NewPtrSys
  001cf2:  2d 48 ff f8          move.l   a0, -$8(a6)
  001cf6:  20 08                move.l   a0, d0
  001cf8:  66 08                bne.b    $1d02  ; -> L1d02
  001cfa:  70 00                moveq    #$0, d0
  001cfc:  2d 40 00 10          move.l   d0, $10(a6)
  001d00:  60 62                bra.b    $1d64  ; -> L1d64
L1d02:
  001d02:  20 6b 00 04          movea.l  $4(a3), a0
  001d06:  22 6e ff f8          movea.l  -$8(a6), a1
  001d0a:  20 2b 00 5a          move.l   $5a(a3), d0
  001d0e:  eb 80                asl.l    #$5, d0
  001d10:  a0 2e                dc.w     $a02e  ; _BlockMove
  001d12:  20 2b 00 5a          move.l   $5a(a3), d0
  001d16:  eb 80                asl.l    #$5, d0
  001d18:  28 40                movea.l  d0, a4
  001d1a:  d9 ee ff f8          adda.l   -$8(a6), a4
  001d1e:  42 47                clr.w    d7
  001d20:  76 20                moveq    #$20, d3
L1d22:
  001d22:  70 00                moveq    #$0, d0
  001d24:  28 80                move.l   d0, (a4)
  001d26:  30 07                move.w   d7, d0
  001d28:  52 47                addq.w   #$1, d7
  001d2a:  49 ec 00 20          lea.l    $20(a4), a4
  001d2e:  b6 47                cmp.w    d7, d3
  001d30:  6e f0                bgt.b    $1d22  ; -> L1d22
  001d32:  2d 6b 00 04 ff fc    move.l   $4(a3), -$4(a6)
  001d38:  27 6e ff f8 00 04    move.l   -$8(a6), $4(a3)
  001d3e:  20 6e ff fc          movea.l  -$4(a6), a0
  001d42:  a0 1f                dc.w     $a01f  ; _DisposePtr
  001d44:  06 ab 00 00 00 20 00 5a addi.l   #$20, $5a(a3)
L1d4c:
  001d4c:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  001d50:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  001d54:  61 ff ff ff fe 98    bsr.l    $1bee  ; -> sub_1bee
  001d5a:  2c 00                move.l   d0, d6
  001d5c:  50 4f                addq.w   #$8, a7
  001d5e:  67 86                beq.b    $1ce6  ; -> L1ce6
  001d60:  2d 46 00 10          move.l   d6, $10(a6)
L1d64:
  001d64:  4c ee 18 c8 ff e0    movem.l  -$20(a6), d3/d6-d7/a3-a4
  001d6a:  4e 5e                unlk     a6
  001d6c:  4e 74 00 08          rtd      #$8
sub_1d70:
  001d70:  4e 56 ff ec          link.w   a6, #$ffec
  001d74:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  001d78:  28 6e 00 0c          movea.l  $c(a6), a4
  001d7c:  2e 2e 00 08          move.l   $8(a6), d7
  001d80:  59 8f                subq.l   #$4, a7
  001d82:  2f 14                move.l   (a4), -(a7)
  001d84:  61 ff 00 00 a4 c4    bsr.l    $c24a  ; -> Strip24
  001d8a:  26 5f                movea.l  (a7)+, a3
  001d8c:  20 3c ff 00 00 00    move.l   #$ff000000, d0
  001d92:  c0 87                and.l    d7, d0
  001d94:  0c 80 54 00 00 00    cmpi.l   #$54000000, d0
  001d9a:  67 08                beq.b    $1da4  ; -> L1da4
  001d9c:  70 ff                moveq    #$ff, d0
  001d9e:  2d 40 00 10          move.l   d0, $10(a6)
  001da2:  60 62                bra.b    $1e06  ; -> L1e06
L1da4:
  001da4:  70 00                moveq    #$0, d0
  001da6:  2d 40 ff f0          move.l   d0, -$10(a6)
  001daa:  2d 47 ff f4          move.l   d7, -$c(a6)
  001dae:  42 6e ff f8          clr.w    -$8(a6)
  001db2:  3d 7c ff fe ff fa    move.w   #$fffe, -$6(a6)
  001db8:  59 8f                subq.l   #$4, a7
  001dba:  2f 0c                move.l   a4, -(a7)
  001dbc:  48 6e ff f0          pea.l    -$10(a6)
  001dc0:  61 ff 00 00 00 bc    bsr.l    $1e7e  ; -> sub_1e7e
  001dc6:  20 3c 00 00 ff ff    move.l   #$ffff, d0
  001dcc:  c0 87                and.l    d7, d0
  001dce:  20 6b 00 04          movea.l  $4(a3), a0
  001dd2:  eb 80                asl.l    #$5, d0
  001dd4:  d1 c0                adda.l   d0, a0
  001dd6:  2d 48 ff ec          move.l   a0, -$14(a6)
  001dda:  28 68 00 04          movea.l  $4(a0), a4
  001dde:  58 4f                addq.w   #$4, a7
  001de0:  60 0a                bra.b    $1dec  ; -> L1dec
L1de2:
  001de2:  26 4c                movea.l  a4, a3
  001de4:  28 6c 00 0c          movea.l  $c(a4), a4
  001de8:  20 4b                movea.l  a3, a0
  001dea:  a0 1f                dc.w     $a01f  ; _DisposePtr
L1dec:
  001dec:  20 0c                move.l   a4, d0
  001dee:  66 f2                bne.b    $1de2  ; -> L1de2
  001df0:  20 6e ff ec          movea.l  -$14(a6), a0
  001df4:  20 50                movea.l  (a0), a0
  001df6:  53 a8 00 14          subq.l   #$1, $14(a0)
  001dfa:  20 6e ff ec          movea.l  -$14(a6), a0
  001dfe:  70 00                moveq    #$0, d0
  001e00:  20 80                move.l   d0, (a0)
  001e02:  2d 40 00 10          move.l   d0, $10(a6)
L1e06:
  001e06:  4c ee 18 80 ff e0    movem.l  -$20(a6), d7/a3-a4
  001e0c:  4e 5e                unlk     a6
  001e0e:  4e 74 00 08          rtd      #$8
sub_1e12:
  001e12:  4e 56 00 00          link.w   a6, #$0
  001e16:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  001e1a:  2e 2e 00 14          move.l   $14(a6), d7
  001e1e:  59 8f                subq.l   #$4, a7
  001e20:  20 6e 00 18          movea.l  $18(a6), a0
  001e24:  2f 10                move.l   (a0), -(a7)
  001e26:  61 ff 00 00 a4 22    bsr.l    $c24a  ; -> Strip24
  001e2c:  28 5f                movea.l  (a7)+, a4
  001e2e:  20 3c ff 00 00 00    move.l   #$ff000000, d0
  001e34:  c0 87                and.l    d7, d0
  001e36:  0c 80 54 00 00 00    cmpi.l   #$54000000, d0
  001e3c:  67 08                beq.b    $1e46  ; -> L1e46
  001e3e:  70 ff                moveq    #$ff, d0
  001e40:  2d 40 00 1c          move.l   d0, $1c(a6)
  001e44:  60 2c                bra.b    $1e72  ; -> L1e72
L1e46:
  001e46:  20 3c 00 00 ff ff    move.l   #$ffff, d0
  001e4c:  c0 87                and.l    d7, d0
  001e4e:  20 6c 00 04          movea.l  $4(a4), a0
  001e52:  eb 80                asl.l    #$5, d0
  001e54:  47 f0 08 00          lea.l    (a0, d0.l), a3
  001e58:  2f 0b                move.l   a3, -(a7)
  001e5a:  2f 2e 00 08          move.l   $8(a6), -(a7)
  001e5e:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  001e62:  2f 2e 00 10          move.l   $10(a6), -(a7)
  001e66:  61 ff ff ff f9 a8    bsr.l    $1810  ; -> sub_1810
  001e6c:  48 c0                ext.l    d0
  001e6e:  2d 40 00 1c          move.l   d0, $1c(a6)
L1e72:
  001e72:  4c ee 18 80 ff f4    movem.l  -$c(a6), d7/a3-a4
  001e78:  4e 5e                unlk     a6
  001e7a:  4e 74 00 14          rtd      #$14
sub_1e7e:
  001e7e:  4e 56 ff f2          link.w   a6, #$fff2
  001e82:  48 e7 11 18          movem.l  d3/d7/a3-a4, -(a7)
  001e86:  59 8f                subq.l   #$4, a7
  001e88:  20 6e 00 0c          movea.l  $c(a6), a0
  001e8c:  2f 10                move.l   (a0), -(a7)
  001e8e:  61 ff 00 00 a3 ba    bsr.l    $c24a  ; -> Strip24
  001e94:  26 5f                movea.l  (a7)+, a3
  001e96:  59 8f                subq.l   #$4, a7
  001e98:  2f 2e 00 08          move.l   $8(a6), -(a7)
  001e9c:  61 ff 00 00 a3 ac    bsr.l    $c24a  ; -> Strip24
  001ea2:  20 5f                movea.l  (a7)+, a0
  001ea4:  2d 48 00 08          move.l   a0, $8(a6)
  001ea8:  2e 28 00 04          move.l   $4(a0), d7
  001eac:  20 3c ff 00 00 00    move.l   #$ff000000, d0
  001eb2:  c0 87                and.l    d7, d0
  001eb4:  0c 80 54 00 00 00    cmpi.l   #$54000000, d0
  001eba:  67 0a                beq.b    $1ec6  ; -> L1ec6
  001ebc:  70 ff                moveq    #$ff, d0
  001ebe:  2d 40 00 10          move.l   d0, $10(a6)
  001ec2:  60 00 01 06          bra.w    $1fca  ; -> L1fca
L1ec6:
  001ec6:  20 3c 00 00 ff ff    move.l   #$ffff, d0
  001ecc:  c0 87                and.l    d7, d0
  001ece:  20 6b 00 04          movea.l  $4(a3), a0
  001ed2:  eb 80                asl.l    #$5, d0
  001ed4:  49 f0 08 00          lea.l    (a0, d0.l), a4
  001ed8:  60 0e                bra.b    $1ee8  ; -> L1ee8
L1eda:
  001eda:  55 8f                subq.l   #$2, a7
  001edc:  2f 2b 00 66          move.l   $66(a3), -(a7)
  001ee0:  61 ff 00 00 03 f8    bsr.l    $22da  ; -> sub_22da
  001ee6:  54 4f                addq.w   #$2, a7
L1ee8:
  001ee8:  70 02                moveq    #$2, d0
  001eea:  b0 ac 00 14          cmp.l    $14(a4), d0
  001eee:  67 06                beq.b    $1ef6  ; -> L1ef6
  001ef0:  4a ac 00 14          tst.l    $14(a4)
  001ef4:  66 e4                bne.b    $1eda  ; -> L1eda
L1ef6:
  001ef6:  70 03                moveq    #$3, d0
  001ef8:  27 40 00 56          move.l   d0, $56(a3)
  001efc:  1d 7c 00 01 ff f7    move.b   #$1, -$9(a6)
  001f02:  41 ee ff f7          lea.l    -$9(a6), a0
  001f06:  10 10                move.b   (a0), d0
  001f08:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  001f0a:  10 80                move.b   d0, (a0)
  001f0c:  20 6b 00 76          movea.l  $76(a3), a0
  001f10:  2d 48 ff f2          move.l   a0, -$e(a6)
  001f14:  21 47 00 04          move.l   d7, $4(a0)
  001f18:  20 6e 00 08          movea.l  $8(a6), a0
  001f1c:  22 6e ff f2          movea.l  -$e(a6), a1
  001f20:  33 68 00 0a 00 0a    move.w   $a(a0), $a(a1)
  001f26:  20 6e 00 08          movea.l  $8(a6), a0
  001f2a:  41 e8 00 0c          lea.l    $c(a0), a0
  001f2e:  2d 48 ff fc          move.l   a0, -$4(a6)
  001f32:  20 6e ff f2          movea.l  -$e(a6), a0
  001f36:  41 e8 00 0c          lea.l    $c(a0), a0
  001f3a:  2d 48 ff f8          move.l   a0, -$8(a6)
  001f3e:  20 6e 00 08          movea.l  $8(a6), a0
  001f42:  7e 00                moveq    #$0, d7
  001f44:  1e 28 00 09          move.b   $9(a0), d7
  001f48:  76 00                moveq    #$0, d3
  001f4a:  60 16                bra.b    $1f62  ; -> L1f62
L1f4c:
  001f4c:  20 6e ff fc          movea.l  -$4(a6), a0
  001f50:  58 ae ff fc          addq.l   #$4, -$4(a6)
  001f54:  20 2e ff f8          move.l   -$8(a6), d0
  001f58:  58 ae ff f8          addq.l   #$4, -$8(a6)
  001f5c:  22 40                movea.l  d0, a1
  001f5e:  22 90                move.l   (a0), (a1)
  001f60:  59 87                subq.l   #$4, d7
L1f62:
  001f62:  b6 87                cmp.l    d7, d3
  001f64:  6d e6                blt.b    $1f4c  ; -> L1f4c
  001f66:  41 ee ff f7          lea.l    -$9(a6), a0
  001f6a:  10 10                move.b   (a0), d0
  001f6c:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  001f6e:  10 80                move.b   d0, (a0)
  001f70:  27 6e ff f2 00 16    move.l   -$e(a6), $16(a3)
  001f76:  27 6c 00 08 00 1a    move.l   $8(a4), $1a(a3)
  001f7c:  20 54                movea.l  (a4), a0
  001f7e:  27 68 00 0c 00 1e    move.l   $c(a0), $1e(a3)
  001f84:  27 7c 00 00 80 01 00 0e move.l   #$8001, $e(a3)
  001f8c:  70 03                moveq    #$3, d0
  001f8e:  29 40 00 14          move.l   d0, $14(a4)
  001f92:  72 00                moveq    #$0, d1
  001f94:  29 41 00 18          move.l   d1, $18(a4)
  001f98:  29 7c 00 00 80 01 00 10 move.l   #$8001, $10(a4)
  001fa0:  17 7c 00 01 00 0c    move.b   #$1, $c(a3)
  001fa6:  60 0e                bra.b    $1fb6  ; -> L1fb6
L1fa8:
  001fa8:  55 8f                subq.l   #$2, a7
  001faa:  2f 2b 00 66          move.l   $66(a3), -(a7)
  001fae:  61 ff 00 00 03 2a    bsr.l    $22da  ; -> sub_22da
  001fb4:  54 4f                addq.w   #$2, a7
L1fb6:
  001fb6:  70 02                moveq    #$2, d0
  001fb8:  b0 ac 00 14          cmp.l    $14(a4), d0
  001fbc:  66 ea                bne.b    $1fa8  ; -> L1fa8
  001fbe:  70 00                moveq    #$0, d0
  001fc0:  29 40 00 14          move.l   d0, $14(a4)
  001fc4:  2d 6c 00 18 00 10    move.l   $18(a4), $10(a6)
L1fca:
  001fca:  4c ee 18 88 ff e2    movem.l  -$1e(a6), d3/d7/a3-a4
  001fd0:  4e 5e                unlk     a6
  001fd2:  4e 74 00 08          rtd      #$8
sub_1fd6:
  001fd6:  4e 56 ff f2          link.w   a6, #$fff2
  001fda:  48 e7 13 18          movem.l  d3/d6-d7/a3-a4, -(a7)
  001fde:  59 8f                subq.l   #$4, a7
  001fe0:  20 6e 00 0c          movea.l  $c(a6), a0
  001fe4:  2f 10                move.l   (a0), -(a7)
  001fe6:  61 ff 00 00 a2 62    bsr.l    $c24a  ; -> Strip24
  001fec:  26 5f                movea.l  (a7)+, a3
  001fee:  59 8f                subq.l   #$4, a7
  001ff0:  2f 2e 00 08          move.l   $8(a6), -(a7)
  001ff4:  61 ff 00 00 a2 54    bsr.l    $c24a  ; -> Strip24
  001ffa:  20 5f                movea.l  (a7)+, a0
  001ffc:  2d 48 00 08          move.l   a0, $8(a6)
  002000:  2c 28 00 04          move.l   $4(a0), d6
  002004:  20 3c ff 00 00 00    move.l   #$ff000000, d0
  00200a:  c0 86                and.l    d6, d0
  00200c:  0c 80 54 00 00 00    cmpi.l   #$54000000, d0
  002012:  67 0a                beq.b    $201e  ; -> L201e
  002014:  70 ff                moveq    #$ff, d0
  002016:  2d 40 00 10          move.l   d0, $10(a6)
  00201a:  60 00 01 08          bra.w    $2124  ; -> L2124
L201e:
  00201e:  20 3c 00 00 ff ff    move.l   #$ffff, d0
  002024:  c0 86                and.l    d6, d0
  002026:  20 6b 00 04          movea.l  $4(a3), a0
  00202a:  eb 80                asl.l    #$5, d0
  00202c:  49 f0 08 00          lea.l    (a0, d0.l), a4
  002030:  60 0e                bra.b    $2040  ; -> L2040
L2032:
  002032:  55 8f                subq.l   #$2, a7
  002034:  2f 2b 00 66          move.l   $66(a3), -(a7)
  002038:  61 ff 00 00 02 a0    bsr.l    $22da  ; -> sub_22da
  00203e:  54 4f                addq.w   #$2, a7
L2040:
  002040:  70 02                moveq    #$2, d0
  002042:  b0 ac 00 14          cmp.l    $14(a4), d0
  002046:  67 06                beq.b    $204e  ; -> L204e
  002048:  4a ac 00 14          tst.l    $14(a4)
  00204c:  66 e4                bne.b    $2032  ; -> L2032
L204e:
  00204e:  70 03                moveq    #$3, d0
  002050:  27 40 00 56          move.l   d0, $56(a3)
  002054:  1d 7c 00 01 ff f7    move.b   #$1, -$9(a6)
  00205a:  41 ee ff f7          lea.l    -$9(a6), a0
  00205e:  10 10                move.b   (a0), d0
  002060:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  002062:  10 80                move.b   d0, (a0)
  002064:  20 6b 00 76          movea.l  $76(a3), a0
  002068:  2d 48 ff f2          move.l   a0, -$e(a6)
  00206c:  21 46 00 04          move.l   d6, $4(a0)
  002070:  20 6e 00 08          movea.l  $8(a6), a0
  002074:  22 6e ff f2          movea.l  -$e(a6), a1
  002078:  33 68 00 0a 00 0a    move.w   $a(a0), $a(a1)
  00207e:  20 6e 00 08          movea.l  $8(a6), a0
  002082:  41 e8 00 0c          lea.l    $c(a0), a0
  002086:  2d 48 ff fc          move.l   a0, -$4(a6)
  00208a:  20 6e ff f2          movea.l  -$e(a6), a0
  00208e:  41 e8 00 0c          lea.l    $c(a0), a0
  002092:  2d 48 ff f8          move.l   a0, -$8(a6)
  002096:  20 6e 00 08          movea.l  $8(a6), a0
  00209a:  7e 00                moveq    #$0, d7
  00209c:  1e 28 00 09          move.b   $9(a0), d7
  0020a0:  76 00                moveq    #$0, d3
  0020a2:  60 16                bra.b    $20ba  ; -> L20ba
L20a4:
  0020a4:  20 6e ff fc          movea.l  -$4(a6), a0
  0020a8:  58 ae ff fc          addq.l   #$4, -$4(a6)
  0020ac:  20 2e ff f8          move.l   -$8(a6), d0
  0020b0:  58 ae ff f8          addq.l   #$4, -$8(a6)
  0020b4:  22 40                movea.l  d0, a1
  0020b6:  22 90                move.l   (a0), (a1)
  0020b8:  59 87                subq.l   #$4, d7
L20ba:
  0020ba:  b6 87                cmp.l    d7, d3
  0020bc:  6d e6                blt.b    $20a4  ; -> L20a4
  0020be:  41 ee ff f7          lea.l    -$9(a6), a0
  0020c2:  10 10                move.b   (a0), d0
  0020c4:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  0020c6:  10 80                move.b   d0, (a0)
  0020c8:  27 6e ff f2 00 16    move.l   -$e(a6), $16(a3)
  0020ce:  27 6c 00 08 00 1a    move.l   $8(a4), $1a(a3)
  0020d4:  20 54                movea.l  (a4), a0
  0020d6:  27 68 00 0c 00 1e    move.l   $c(a0), $1e(a3)
  0020dc:  27 7c 00 00 80 01 00 0e move.l   #$8001, $e(a3)
  0020e4:  20 6e 00 08          movea.l  $8(a6), a0
  0020e8:  00 28 00 80 00 08    ori.b    #$80, $8(a0)
  0020ee:  70 03                moveq    #$3, d0
  0020f0:  29 40 00 14          move.l   d0, $14(a4)
  0020f4:  72 00                moveq    #$0, d1
  0020f6:  29 41 00 18          move.l   d1, $18(a4)
  0020fa:  29 7c 00 00 80 01 00 10 move.l   #$8001, $10(a4)
  002102:  17 7c 00 01 00 0c    move.b   #$1, $c(a3)
  002108:  60 0e                bra.b    $2118  ; -> L2118
L210a:
  00210a:  55 8f                subq.l   #$2, a7
  00210c:  2f 2b 00 66          move.l   $66(a3), -(a7)
  002110:  61 ff 00 00 01 c8    bsr.l    $22da  ; -> sub_22da
  002116:  54 4f                addq.w   #$2, a7
L2118:
  002118:  70 03                moveq    #$3, d0
  00211a:  b0 ac 00 14          cmp.l    $14(a4), d0
  00211e:  67 ea                beq.b    $210a  ; -> L210a
  002120:  2d 46 00 10          move.l   d6, $10(a6)
L2124:
  002124:  4c ee 18 c8 ff de    movem.l  -$22(a6), d3/d6-d7/a3-a4
  00212a:  4e 5e                unlk     a6
  00212c:  4e 74 00 08          rtd      #$8
sub_2130:
  002130:  4e 56 00 00          link.w   a6, #$0
  002134:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  002138:  2e 2e 00 08          move.l   $8(a6), d7
  00213c:  59 8f                subq.l   #$4, a7
  00213e:  20 6e 00 0c          movea.l  $c(a6), a0
  002142:  2f 10                move.l   (a0), -(a7)
  002144:  61 ff 00 00 a1 04    bsr.l    $c24a  ; -> Strip24
  00214a:  26 5f                movea.l  (a7)+, a3
  00214c:  20 3c ff 00 00 00    move.l   #$ff000000, d0
  002152:  c0 87                and.l    d7, d0
  002154:  0c 80 54 00 00 00    cmpi.l   #$54000000, d0
  00215a:  67 08                beq.b    $2164  ; -> L2164
  00215c:  70 ff                moveq    #$ff, d0
  00215e:  2d 40 00 10          move.l   d0, $10(a6)
  002162:  60 4c                bra.b    $21b0  ; -> L21b0
L2164:
  002164:  20 3c 00 00 ff ff    move.l   #$ffff, d0
  00216a:  c0 87                and.l    d7, d0
  00216c:  20 6b 00 04          movea.l  $4(a3), a0
  002170:  eb 80                asl.l    #$5, d0
  002172:  49 f0 08 00          lea.l    (a0, d0.l), a4
  002176:  70 02                moveq    #$2, d0
  002178:  b0 ac 00 14          cmp.l    $14(a4), d0
  00217c:  67 1e                beq.b    $219c  ; -> L219c
  00217e:  70 01                moveq    #$1, d0
  002180:  b0 ac 00 14          cmp.l    $14(a4), d0
  002184:  67 16                beq.b    $219c  ; -> L219c
  002186:  70 ff                moveq    #$ff, d0
  002188:  2d 40 00 10          move.l   d0, $10(a6)
  00218c:  60 22                bra.b    $21b0  ; -> L21b0
L218e:
  00218e:  55 8f                subq.l   #$2, a7
  002190:  2f 2b 00 66          move.l   $66(a3), -(a7)
  002194:  61 ff 00 00 01 44    bsr.l    $22da  ; -> sub_22da
  00219a:  54 4f                addq.w   #$2, a7
L219c:
  00219c:  70 02                moveq    #$2, d0
  00219e:  b0 ac 00 14          cmp.l    $14(a4), d0
  0021a2:  66 ea                bne.b    $218e  ; -> L218e
  0021a4:  70 00                moveq    #$0, d0
  0021a6:  29 40 00 14          move.l   d0, $14(a4)
  0021aa:  2d 6c 00 18 00 10    move.l   $18(a4), $10(a6)
L21b0:
  0021b0:  4c ee 18 80 ff f4    movem.l  -$c(a6), d7/a3-a4
  0021b6:  4e 5e                unlk     a6
  0021b8:  4e 74 00 08          rtd      #$8
sub_21bc:
  0021bc:  4e 56 00 00          link.w   a6, #$0
  0021c0:  2f 0c                move.l   a4, -(a7)
  0021c2:  28 6e 00 08          movea.l  $8(a6), a4
  0021c6:  70 01                moveq    #$1, d0
  0021c8:  29 40 00 56          move.l   d0, $56(a4)
  0021cc:  29 6e 00 0c 00 16    move.l   $c(a6), $16(a4)
  0021d2:  29 7c 00 00 80 02 00 0e move.l   #$8002, $e(a4)
  0021da:  72 00                moveq    #$0, d1
  0021dc:  29 41 00 12          move.l   d1, $12(a4)
  0021e0:  42 2c 00 0d          clr.b    $d(a4)
  0021e4:  19 7c 00 01 00 0c    move.b   #$1, $c(a4)
  0021ea:  60 0e                bra.b    $21fa  ; -> L21fa
L21ec:
  0021ec:  55 8f                subq.l   #$2, a7
  0021ee:  2f 2c 00 66          move.l   $66(a4), -(a7)
  0021f2:  61 ff 00 00 00 e6    bsr.l    $22da  ; -> sub_22da
  0021f8:  54 4f                addq.w   #$2, a7
L21fa:
  0021fa:  4a 2c 00 0d          tst.b    $d(a4)
  0021fe:  67 ec                beq.b    $21ec  ; -> L21ec
  002200:  20 2c 00 12          move.l   $12(a4), d0
  002204:  28 6e ff fc          movea.l  -$4(a6), a4
  002208:  4e 5e                unlk     a6
  00220a:  4e 75                rts      
sub_220c:
  00220c:  4e 56 00 00          link.w   a6, #$0
  002210:  2f 0c                move.l   a4, -(a7)
  002212:  28 6e 00 08          movea.l  $8(a6), a4
  002216:  70 01                moveq    #$1, d0
  002218:  29 40 00 56          move.l   d0, $56(a4)
  00221c:  29 6e 00 0c 00 16    move.l   $c(a6), $16(a4)
  002222:  29 7c 00 00 80 03 00 0e move.l   #$8003, $e(a4)
  00222a:  72 00                moveq    #$0, d1
  00222c:  29 41 00 12          move.l   d1, $12(a4)
  002230:  42 2c 00 0d          clr.b    $d(a4)
  002234:  19 7c 00 01 00 0c    move.b   #$1, $c(a4)
  00223a:  60 0e                bra.b    $224a  ; -> L224a
L223c:
  00223c:  55 8f                subq.l   #$2, a7
  00223e:  2f 2c 00 66          move.l   $66(a4), -(a7)
  002242:  61 ff 00 00 00 96    bsr.l    $22da  ; -> sub_22da
  002248:  54 4f                addq.w   #$2, a7
L224a:
  00224a:  4a 2c 00 0d          tst.b    $d(a4)
  00224e:  67 ec                beq.b    $223c  ; -> L223c
  002250:  20 2c 00 12          move.l   $12(a4), d0
  002254:  28 6e ff fc          movea.l  -$4(a6), a4
  002258:  4e 5e                unlk     a6
  00225a:  4e 75                rts      
sub_225c:
  00225c:  4e 56 00 00          link.w   a6, #$0
  002260:  2f 0c                move.l   a4, -(a7)
  002262:  70 70                moveq    #$70, d0
  002264:  a7 22                dc.w     $a722  ; _NewHandle,SYS,CLEAR
  002266:  28 48                movea.l  a0, a4
  002268:  20 0c                move.l   a4, d0
  00226a:  67 4c                beq.b    $22b8  ; -> L22b8
  00226c:  20 54                movea.l  (a4), a0
  00226e:  31 6e 00 0a 00 04    move.w   $a(a6), $4(a0)
  002274:  20 54                movea.l  (a4), a0
  002276:  42 68 00 02          clr.w    $2(a0)
  00227a:  20 54                movea.l  (a4), a0
  00227c:  42 50                clr.w    (a0)
  00227e:  20 54                movea.l  (a4), a0
  002280:  70 00                moveq    #$0, d0
  002282:  21 40 00 14          move.l   d0, $14(a0)
  002286:  20 54                movea.l  (a4), a0
  002288:  21 40 00 58          move.l   d0, $58(a0)
  00228c:  20 54                movea.l  (a4), a0
  00228e:  21 40 00 5c          move.l   d0, $5c(a0)
  002292:  20 54                movea.l  (a4), a0
  002294:  21 40 00 60          move.l   d0, $60(a0)
  002298:  20 54                movea.l  (a4), a0
  00229a:  21 40 00 64          move.l   d0, $64(a0)
  00229e:  20 54                movea.l  (a4), a0
  0022a0:  21 40 00 68          move.l   d0, $68(a0)
  0022a4:  20 54                movea.l  (a4), a0
  0022a6:  31 7c 00 7e 00 06    move.w   #$7e, $6(a0)
  0022ac:  20 54                movea.l  (a4), a0
  0022ae:  21 40 00 0a          move.l   d0, $a(a0)
  0022b2:  20 54                movea.l  (a4), a0
  0022b4:  42 68 00 08          clr.w    $8(a0)
L22b8:
  0022b8:  2d 4c 00 0c          move.l   a4, $c(a6)
  0022bc:  28 6e ff fc          movea.l  -$4(a6), a4
  0022c0:  4e 5e                unlk     a6
  0022c2:  4e 74 00 04          rtd      #$4
sub_22c6:
  0022c6:  4e 56 00 00          link.w   a6, #$0
  0022ca:  20 6e 00 0a          movea.l  $a(a6), a0
  0022ce:  a0 23                dc.w     $a023  ; _DisposHandle
  0022d0:  42 6e 00 0e          clr.w    $e(a6)
  0022d4:  4e 5e                unlk     a6
  0022d6:  4e 74 00 06          rtd      #$6
sub_22da:
  0022da:  4e 56 ff f4          link.w   a6, #$fff4
  0022de:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  0022e2:  20 6e 00 08          movea.l  $8(a6), a0
  0022e6:  20 50                movea.l  (a0), a0
  0022e8:  28 68 00 6c          movea.l  $6c(a0), a4
  0022ec:  20 0c                move.l   a4, d0
  0022ee:  67 2a                beq.b    $231a  ; -> L231a
  0022f0:  4a 2c 00 0c          tst.b    $c(a4)
  0022f4:  67 24                beq.b    $231a  ; -> L231a
  0022f6:  42 2c 00 0c          clr.b    $c(a4)
  0022fa:  2f 2c 00 56          move.l   $56(a4), -(a7)
  0022fe:  48 6c 00 16          pea.l    $16(a4)
  002302:  2f 2c 00 0e          move.l   $e(a4), -(a7)
  002306:  61 ff 00 00 26 bc    bsr.l    $49c4  ; -> EngineDispatch
  00230c:  29 40 00 12          move.l   d0, $12(a4)
  002310:  19 7c 00 01 00 0d    move.b   #$1, $d(a4)
  002316:  4f ef 00 0c          lea.l    $c(a7), a7
L231a:
  00231a:  59 8f                subq.l   #$4, a7
  00231c:  2f 38 08 88          move.l   $888.w, -(a7)
  002320:  61 ff 00 00 9f 28    bsr.l    $c24a  ; -> Strip24
  002326:  28 5f                movea.l  (a7)+, a4
  002328:  20 54                movea.l  (a4), a0
  00232a:  20 50                movea.l  (a0), a0
  00232c:  20 68 02 14          movea.l  $214(a0), a0
  002330:  2d 48 ff fc          move.l   a0, -$4(a6)
  002334:  26 50                movea.l  (a0), a3
  002336:  2d 6b 00 0c ff f8    move.l   $c(a3), -$8(a6)
  00233c:  55 8f                subq.l   #$2, a7
  00233e:  70 00                moveq    #$0, d0
  002340:  1f 00                move.b   d0, -(a7)
  002342:  61 ff 00 00 9c d6    bsr.l    $c01a  ; -> HWPrivProbe
  002348:  1e 1f                move.b   (a7)+, d7
  00234a:  20 6b 00 10          movea.l  $10(a3), a0
  00234e:  2d 48 ff f4          move.l   a0, -$c(a6)
  002352:  70 04                moveq    #$4, d0
  002354:  c0 90                and.l    (a0), d0
  002356:  67 16                beq.b    $236e  ; -> L236e
  002358:  02 90 ff ff ff fb    andi.l   #$fffffffb, (a0)
  00235e:  48 6b 00 24          pea.l    $24(a3)
  002362:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  002366:  61 ff 00 00 40 da    bsr.l    $6442  ; -> sub_6442
  00236c:  50 4f                addq.w   #$8, a7
L236e:
  00236e:  20 6e ff f4          movea.l  -$c(a6), a0
  002372:  70 02                moveq    #$2, d0
  002374:  c0 90                and.l    (a0), d0
  002376:  67 08                beq.b    $2380  ; -> L2380
  002378:  02 ab ff ff ff fb 00 1c andi.l   #$fffffffb, $1c(a3)
L2380:
  002380:  55 8f                subq.l   #$2, a7
  002382:  1f 07                move.b   d7, -(a7)
  002384:  61 ff 00 00 9c 94    bsr.l    $c01a  ; -> HWPrivProbe
  00238a:  42 6e 00 0c          clr.w    $c(a6)
  00238e:  54 4f                addq.w   #$2, a7
  002390:  4c ee 18 80 ff e8    movem.l  -$18(a6), d7/a3-a4
  002396:  4e 5e                unlk     a6
  002398:  4e 74 00 04          rtd      #$4
sub_239c:
  00239c:  4e 56 00 00          link.w   a6, #$0
  0023a0:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0023a4:  61 ff 00 00 9b d0    bsr.l    $bf76  ; -> sub_bf76
  0023aa:  4e 5e                unlk     a6
  0023ac:  4e 75                rts      
sub_23ae:
  0023ae:  4e 56 00 00          link.w   a6, #$0
  0023b2:  4e 5e                unlk     a6
  0023b4:  4e 75                rts      
* ACEFLoad  -  the relocating loader for the Am29000 firmware (ACEF).
* Parses the ACEF object format (magic / sections / symbols / relocations),
* loads and zero-fills sections, fixes up absolute & relative branch
* targets, and reports progress via the log strings just below
* ("Loading %d sections", "Not in ACEF format!", "Load Complete." ...).
* This is the "ACEFLoad" the control panel's string table names.
ACEFLoad:
  0023b6:  4e 56 ff 1e          link.w   a6, #$ff1e
  0023ba:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  0023be:  1d 7c 00 01 ff 33    move.b   #$1, -$cd(a6)
  0023c4:  70 00                moveq    #$0, d0
  0023c6:  2d 40 ff 44          move.l   d0, -$bc(a6)
  0023ca:  2d 40 ff e6          move.l   d0, -$1a(a6)
  0023ce:  2d 40 ff ee          move.l   d0, -$12(a6)
  0023d2:  1d 7c 00 01 ff f3    move.b   #$1, -$d(a6)
  0023d8:  72 1c                moveq    #$1c, d1
  0023da:  24 2e 00 0c          move.l   $c(a6), d2
  0023de:  e2 aa                lsr.l    d1, d2
  0023e0:  2d 42 ff f4          move.l   d2, -$c(a6)
  0023e4:  2d 6e 00 08 ff 2e    move.l   $8(a6), -$d2(a6)
  0023ea:  22 2e 00 10          move.l   $10(a6), d1
  0023ee:  d2 ae 00 08          add.l    $8(a6), d1
  0023f2:  2d 41 ff da          move.l   d1, -$26(a6)
  0023f6:  20 6e ff 2e          movea.l  -$d2(a6), a0
  0023fa:  43 ee ff 78          lea.l    -$88(a6), a1
  0023fe:  72 04                moveq    #$4, d1
L2400:
  002400:  22 d8                move.l   (a0)+, (a1)+
  002402:  51 c9 ff fc          dbra     d1, $2400  ; -> L2400
  002406:  06 ae 00 00 00 14 ff 2e addi.l   #$14, -$d2(a6)
  00240e:  72 00                moveq    #$0, d1
  002410:  32 2e ff 78          move.w   -$88(a6), d1
  002414:  0c 81 00 00 01 2a    cmpi.l   #$12a, d1
  00241a:  67 12                beq.b    $242e  ; -> L242e
  00241c:  48 7a 0e 8a          pea.l    $32a8(pc)
  002420:  61 ff ff ff ff 7a    bsr.l    $239c  ; -> sub_239c
  002426:  70 00                moveq    #$0, d0
  002428:  58 4f                addq.w   #$4, a7
  00242a:  60 00 0c 4a          bra.w    $3076  ; -> L3076
L242e:
  00242e:  20 6e ff 2e          movea.l  -$d2(a6), a0
  002432:  43 ee ff 8c          lea.l    -$74(a6), a1
  002436:  70 10                moveq    #$10, d0
L2438:
  002438:  22 d8                move.l   (a0)+, (a1)+
  00243a:  51 c8 ff fc          dbra     d0, $2438  ; -> L2438
  00243e:  06 ae 00 00 00 44 ff 2e addi.l   #$44, -$d2(a6)
  002446:  2f 2e ff a4          move.l   -$5c(a6), -(a7)
  00244a:  2f 2e ff a0          move.l   -$60(a6), -(a7)
  00244e:  48 6e ff a8          pea.l    -$58(a6)
  002452:  48 7a 0e 30          pea.l    $3284(pc)
  002456:  61 ff ff ff ff 56    bsr.l    $23ae  ; -> sub_23ae
  00245c:  70 00                moveq    #$0, d0
  00245e:  30 2e ff 8a          move.w   -$76(a6), d0
  002462:  72 02                moveq    #$2, d1
  002464:  c2 40                and.w    d0, d1
  002466:  4f ef 00 10          lea.l    $10(a7), a7
  00246a:  66 0c                bne.b    $2478  ; -> L2478
  00246c:  70 00                moveq    #$0, d0
  00246e:  30 2e ff 8a          move.w   -$76(a6), d0
  002472:  72 01                moveq    #$1, d1
  002474:  c2 40                and.w    d0, d1
  002476:  67 04                beq.b    $247c  ; -> L247c
L2478:
  002478:  42 2e ff f3          clr.b    -$d(a6)
L247c:
  00247c:  70 00                moveq    #$0, d0
  00247e:  30 2e ff 8a          move.w   -$76(a6), d0
  002482:  2f 00                move.l   d0, -(a7)
  002484:  2f 2e ff 84          move.l   -$7c(a6), -(a7)
  002488:  70 00                moveq    #$0, d0
  00248a:  30 2e ff 7a          move.w   -$86(a6), d0
  00248e:  2f 00                move.l   d0, -(a7)
  002490:  70 00                moveq    #$0, d0
  002492:  30 2e ff 78          move.w   -$88(a6), d0
  002496:  2f 00                move.l   d0, -(a7)
  002498:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00249c:  48 7a 0d a4          pea.l    $3242(pc)
  0024a0:  61 ff ff ff ff 0c    bsr.l    $23ae  ; -> sub_23ae
  0024a6:  20 2e ff 2e          move.l   -$d2(a6), d0
  0024aa:  90 ae 00 08          sub.l    $8(a6), d0
  0024ae:  2d 40 ff 4c          move.l   d0, -$b4(a6)
  0024b2:  2d 6e ff 84 ff e2    move.l   -$7c(a6), -$1e(a6)
  0024b8:  4f ef 00 18          lea.l    $18(a7), a7
  0024bc:  67 50                beq.b    $250e  ; -> L250e
  0024be:  59 8f                subq.l   #$4, a7
  0024c0:  22 2e ff e2          move.l   -$1e(a6), d1
  0024c4:  d2 81                add.l    d1, d1
  0024c6:  20 01                move.l   d1, d0
  0024c8:  d0 80                add.l    d0, d0
  0024ca:  d2 80                add.l    d0, d1
  0024cc:  20 01                move.l   d1, d0
  0024ce:  a1 1e                dc.w     $a11e  ; _NewPtr
  0024d0:  2f 08                move.l   a0, -(a7)
  0024d2:  61 ff 00 00 9d 76    bsr.l    $c24a  ; -> Strip24
  0024d8:  2d 5f ff e6          move.l   (a7)+, -$1a(a6)
  0024dc:  66 12                bne.b    $24f0  ; -> L24f0
  0024de:  48 7a 0d 46          pea.l    $3226(pc)
  0024e2:  61 ff ff ff fe b8    bsr.l    $239c  ; -> sub_239c
  0024e8:  70 00                moveq    #$0, d0
  0024ea:  58 4f                addq.w   #$4, a7
  0024ec:  60 00 0b 88          bra.w    $3076  ; -> L3076
L24f0:
  0024f0:  20 2e ff 80          move.l   -$80(a6), d0
  0024f4:  d0 ae 00 08          add.l    $8(a6), d0
  0024f8:  20 40                movea.l  d0, a0
  0024fa:  22 6e ff e6          movea.l  -$1a(a6), a1
  0024fe:  22 2e ff e2          move.l   -$1e(a6), d1
  002502:  d2 81                add.l    d1, d1
  002504:  20 01                move.l   d1, d0
  002506:  d0 80                add.l    d0, d0
  002508:  d2 80                add.l    d0, d1
  00250a:  20 01                move.l   d1, d0
  00250c:  a0 2e                dc.w     $a02e  ; _BlockMove
L250e:
  00250e:  20 2e ff 94          move.l   -$6c(a6), d0
  002512:  56 80                addq.l   #$3, d0
  002514:  72 fc                moveq    #$fc, d1
  002516:  c2 80                and.l    d0, d1
  002518:  2d 41 ff 94          move.l   d1, -$6c(a6)
  00251c:  2d 6e 00 0c ff fc    move.l   $c(a6), -$4(a6)
  002522:  2d 6e ff fc ff ee    move.l   -$4(a6), -$12(a6)
  002528:  2d 6e ff 8c ff f8    move.l   -$74(a6), -$8(a6)
  00252e:  20 2e ff fc          move.l   -$4(a6), d0
  002532:  58 80                addq.l   #$4, d0
  002534:  2d 40 ff f8          move.l   d0, -$8(a6)
  002538:  70 00                moveq    #$0, d0
  00253a:  30 2e ff 7a          move.w   -$86(a6), d0
  00253e:  2f 00                move.l   d0, -(a7)
  002540:  48 7a 0c ce          pea.l    $3210(pc)
  002544:  61 ff ff ff fe 68    bsr.l    $23ae  ; -> sub_23ae
  00254a:  3d 7c 00 01 ff d0    move.w   #$1, -$30(a6)
  002550:  50 4f                addq.w   #$8, a7
L2552:
  002552:  2d 6e ff ee 00 0c    move.l   -$12(a6), $c(a6)
  002558:  2d 6e 00 0c ff 40    move.l   $c(a6), -$c0(a6)
  00255e:  2d 6e ff 4c ff 48    move.l   -$b4(a6), -$b8(a6)
  002564:  70 00                moveq    #$0, d0
  002566:  2d 40 ff d6          move.l   d0, -$2a(a6)
  00256a:  60 00 0a be          bra.w    $302a  ; -> L302a
L256e:
  00256e:  20 2e ff 48          move.l   -$b8(a6), d0
  002572:  d0 ae 00 08          add.l    $8(a6), d0
  002576:  2d 40 ff 2e          move.l   d0, -$d2(a6)
  00257a:  b0 ae ff da          cmp.l    -$26(a6), d0
  00257e:  63 1a                bls.b    $259a  ; -> L259a
  002580:  20 2e ff 2e          move.l   -$d2(a6), d0
  002584:  90 ae ff da          sub.l    -$26(a6), d0
  002588:  2f 00                move.l   d0, -(a7)
  00258a:  48 7a 0b 78          pea.l    $3104(pc)
  00258e:  61 ff ff ff fe 0c    bsr.l    $239c  ; -> sub_239c
  002594:  50 4f                addq.w   #$8, a7
  002596:  60 00 0a d0          bra.w    $3068  ; -> L3068
L259a:
  00259a:  20 6e ff 2e          movea.l  -$d2(a6), a0
  00259e:  43 ee ff 50          lea.l    -$b0(a6), a1
  0025a2:  70 09                moveq    #$9, d0
L25a4:
  0025a4:  22 d8                move.l   (a0)+, (a1)+
  0025a6:  51 c8 ff fc          dbra     d0, $25a4  ; -> L25a4
  0025aa:  06 ae 00 00 00 28 ff 2e addi.l   #$28, -$d2(a6)
  0025b2:  2f 2e ff 68          move.l   -$98(a6), -(a7)
  0025b6:  2f 2e ff 64          move.l   -$9c(a6), -(a7)
  0025ba:  30 2e ff d0          move.w   -$30(a6), d0
  0025be:  48 c0                ext.l    d0
  0025c0:  2f 00                move.l   d0, -(a7)
  0025c2:  48 7a 0c 24          pea.l    $31e8(pc)
  0025c6:  61 ff ff ff fd e6    bsr.l    $23ae  ; -> sub_23ae
  0025cc:  20 2e ff 2e          move.l   -$d2(a6), d0
  0025d0:  b0 ae ff da          cmp.l    -$26(a6), d0
  0025d4:  4f ef 00 10          lea.l    $10(a7), a7
  0025d8:  63 1a                bls.b    $25f4  ; -> L25f4
  0025da:  20 2e ff 2e          move.l   -$d2(a6), d0
  0025de:  90 ae ff da          sub.l    -$26(a6), d0
  0025e2:  2f 00                move.l   d0, -(a7)
  0025e4:  48 7a 0b 1e          pea.l    $3104(pc)
  0025e8:  61 ff ff ff fd b2    bsr.l    $239c  ; -> sub_239c
  0025ee:  50 4f                addq.w   #$8, a7
  0025f0:  60 00 0a 76          bra.w    $3068  ; -> L3068
L25f4:
  0025f4:  20 2e ff 2e          move.l   -$d2(a6), d0
  0025f8:  90 ae 00 08          sub.l    $8(a6), d0
  0025fc:  2d 40 ff 48          move.l   d0, -$b8(a6)
  002600:  20 3c 00 00 0e 1b    move.l   #$e1b, d0
  002606:  c0 ae ff 74          and.l    -$8c(a6), d0
  00260a:  66 06                bne.b    $2612  ; -> L2612
  00260c:  4a ae ff 60          tst.l    -$a0(a6)
  002610:  66 34                bne.b    $2646  ; -> L2646
L2612:
  002612:  70 01                moveq    #$1, d0
  002614:  b0 6e ff d0          cmp.w    -$30(a6), d0
  002618:  66 00 0a 08          bne.w    $3022  ; -> L3022
  00261c:  2f 2e ff 60          move.l   -$a0(a6), -(a7)
  002620:  2f 2e ff 58          move.l   -$a8(a6), -(a7)
  002624:  20 2e ff d6          move.l   -$2a(a6), d0
  002628:  52 80                addq.l   #$1, d0
  00262a:  2f 00                move.l   d0, -(a7)
  00262c:  2f 2e ff 74          move.l   -$8c(a6), -(a7)
  002630:  48 6e ff 50          pea.l    -$b0(a6)
  002634:  48 7a 0b 7a          pea.l    $31b0(pc)
  002638:  61 ff ff ff fd 74    bsr.l    $23ae  ; -> sub_23ae
  00263e:  4f ef 00 18          lea.l    $18(a7), a7
  002642:  60 00 09 de          bra.w    $3022  ; -> L3022
L2646:
  002646:  70 01                moveq    #$1, d0
  002648:  b0 6e ff d0          cmp.w    -$30(a6), d0
  00264c:  66 46                bne.b    $2694  ; -> L2694
  00264e:  2f 2e ff 40          move.l   -$c0(a6), -(a7)
  002652:  20 3c 00 00 00 80    move.l   #$80, d0
  002658:  c0 ae ff 74          and.l    -$8c(a6), d0
  00265c:  67 08                beq.b    $2666  ; -> L2666
  00265e:  41 fa 0b 48          lea.l    $31a8(pc), a0
  002662:  20 08                move.l   a0, d0
  002664:  60 06                bra.b    $266c  ; -> L266c
L2666:
  002666:  41 fa 0b 38          lea.l    $31a0(pc), a0
  00266a:  20 08                move.l   a0, d0
L266c:
  00266c:  2f 00                move.l   d0, -(a7)
  00266e:  2f 2e ff 60          move.l   -$a0(a6), -(a7)
  002672:  2f 2e ff 58          move.l   -$a8(a6), -(a7)
  002676:  20 2e ff d6          move.l   -$2a(a6), d0
  00267a:  52 80                addq.l   #$1, d0
  00267c:  2f 00                move.l   d0, -(a7)
  00267e:  2f 2e ff 74          move.l   -$8c(a6), -(a7)
  002682:  48 6e ff 50          pea.l    -$b0(a6)
  002686:  48 7a 0a dc          pea.l    $3164(pc)
  00268a:  61 ff ff ff fd 22    bsr.l    $23ae  ; -> sub_23ae
  002690:  4f ef 00 20          lea.l    $20(a7), a7
L2694:
  002694:  4a 6e ff 70          tst.w    -$90(a6)
  002698:  67 34                beq.b    $26ce  ; -> L26ce
  00269a:  0c ae 00 00 ff ff ff e2 cmpi.l   #$ffff, -$1e(a6)
  0026a2:  6f 16                ble.b    $26ba  ; -> L26ba
  0026a4:  59 8f                subq.l   #$4, a7
  0026a6:  20 2e ff 68          move.l   -$98(a6), d0
  0026aa:  d0 ae 00 08          add.l    $8(a6), d0
  0026ae:  2f 00                move.l   d0, -(a7)
  0026b0:  61 ff 00 00 9b 98    bsr.l    $c24a  ; -> Strip24
  0026b6:  26 5f                movea.l  (a7)+, a3
  0026b8:  60 14                bra.b    $26ce  ; -> L26ce
L26ba:
  0026ba:  59 8f                subq.l   #$4, a7
  0026bc:  20 2e ff 68          move.l   -$98(a6), d0
  0026c0:  d0 ae 00 08          add.l    $8(a6), d0
  0026c4:  2f 00                move.l   d0, -(a7)
  0026c6:  61 ff 00 00 9b 82    bsr.l    $c24a  ; -> Strip24
  0026cc:  28 5f                movea.l  (a7)+, a4
L26ce:
  0026ce:  20 2e ff 64          move.l   -$9c(a6), d0
  0026d2:  d0 ae 00 08          add.l    $8(a6), d0
  0026d6:  2d 40 ff 2e          move.l   d0, -$d2(a6)
  0026da:  2d 6e ff 60 ff 34    move.l   -$a0(a6), -$cc(a6)
  0026e0:  20 2e ff 5c          move.l   -$a4(a6), d0
  0026e4:  c0 bc 0f ff ff ff    and.l    #$fffffff, d0
  0026ea:  2d 40 ff 38          move.l   d0, -$c8(a6)
  0026ee:  4a 2e ff f3          tst.b    -$d(a6)
  0026f2:  66 34                bne.b    $2728  ; -> L2728
  0026f4:  70 20                moveq    #$20, d0
  0026f6:  c0 ae ff 74          and.l    -$8c(a6), d0
  0026fa:  67 1a                beq.b    $2716  ; -> L2716
  0026fc:  20 3c 00 00 80 20    move.l   #$8020, d0
  002702:  c0 ae ff 74          and.l    -$8c(a6), d0
  002706:  0c 80 00 00 80 20    cmpi.l   #$8020, d0
  00270c:  67 08                beq.b    $2716  ; -> L2716
  00270e:  2d 6e ff 58 ff 40    move.l   -$a8(a6), -$c0(a6)
  002714:  60 12                bra.b    $2728  ; -> L2728
L2716:
  002716:  20 3c f0 00 00 00    move.l   #$f0000000, d0
  00271c:  c0 ae ff 58          and.l    -$a8(a6), d0
  002720:  67 06                beq.b    $2728  ; -> L2728
  002722:  2d 6e ff 58 ff 40    move.l   -$a8(a6), -$c0(a6)
L2728:
  002728:  70 01                moveq    #$1, d0
  00272a:  b0 6e ff d0          cmp.w    -$30(a6), d0
  00272e:  66 00 02 24          bne.w    $2954  ; -> L2954
  002732:  20 3c 00 00 00 80    move.l   #$80, d0
  002738:  c0 ae ff 74          and.l    -$8c(a6), d0
  00273c:  67 00 01 44          beq.w    $2882  ; -> L2882
  002740:  4a ae ff 44          tst.l    -$bc(a6)
  002744:  67 10                beq.b    $2756  ; -> L2756
  002746:  48 7a 09 e4          pea.l    $312c(pc)
  00274a:  61 ff ff ff fc 50    bsr.l    $239c  ; -> sub_239c
  002750:  58 4f                addq.w   #$4, a7
  002752:  60 00 09 14          bra.w    $3068  ; -> L3068
L2756:
  002756:  2d 6e ff 40 ff 44    move.l   -$c0(a6), -$bc(a6)
  00275c:  70 00                moveq    #$0, d0
  00275e:  2d 40 ff d2          move.l   d0, -$2e(a6)
  002762:  60 00 00 92          bra.w    $27f6  ; -> L27f6
L2766:
  002766:  20 6e ff e6          movea.l  -$1a(a6), a0
  00276a:  20 2e ff d2          move.l   -$2e(a6), d0
  00276e:  d0 80                add.l    d0, d0
  002770:  22 00                move.l   d0, d1
  002772:  d2 81                add.l    d1, d1
  002774:  d0 81                add.l    d1, d0
  002776:  22 2e ff d6          move.l   -$2a(a6), d1
  00277a:  52 81                addq.l   #$1, d1
  00277c:  30 30 08 00          move.w   (a0, d0.l), d0
  002780:  48 c0                ext.l    d0
  002782:  b2 80                cmp.l    d0, d1
  002784:  66 68                bne.b    $27ee  ; -> L27ee
  002786:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  00278a:  20 6e ff e6          movea.l  -$1a(a6), a0
  00278e:  20 2e ff d2          move.l   -$2e(a6), d0
  002792:  d0 80                add.l    d0, d0
  002794:  22 00                move.l   d0, d1
  002796:  d2 81                add.l    d1, d1
  002798:  d0 81                add.l    d1, d0
  00279a:  2f 30 08 02          move.l   $2(a0, d0.l), -(a7)
  00279e:  61 ff 00 00 4d 56    bsr.l    $74f6  ; -> sub_74f6
  0027a4:  20 6e ff e6          movea.l  -$1a(a6), a0
  0027a8:  22 2e ff d2          move.l   -$2e(a6), d1
  0027ac:  d2 81                add.l    d1, d1
  0027ae:  24 01                move.l   d1, d2
  0027b0:  d4 82                add.l    d2, d2
  0027b2:  d2 82                add.l    d2, d1
  0027b4:  21 80 18 02          move.l   d0, $2(a0, d1.l)
  0027b8:  20 6e ff e6          movea.l  -$1a(a6), a0
  0027bc:  20 2e ff d2          move.l   -$2e(a6), d0
  0027c0:  d0 80                add.l    d0, d0
  0027c2:  22 00                move.l   d0, d1
  0027c4:  d2 81                add.l    d1, d1
  0027c6:  d0 81                add.l    d1, d0
  0027c8:  22 2e ff 40          move.l   -$c0(a6), d1
  0027cc:  d2 b0 08 02          add.l    $2(a0, d0.l), d1
  0027d0:  92 ae ff 58          sub.l    -$a8(a6), d1
  0027d4:  20 6e ff e6          movea.l  -$1a(a6), a0
  0027d8:  20 2e ff d2          move.l   -$2e(a6), d0
  0027dc:  d0 80                add.l    d0, d0
  0027de:  24 00                move.l   d0, d2
  0027e0:  d4 82                add.l    d2, d2
  0027e2:  d0 82                add.l    d2, d0
  0027e4:  21 81 08 02          move.l   d1, $2(a0, d0.l)
  0027e8:  2d 41 ff 44          move.l   d1, -$bc(a6)
  0027ec:  50 4f                addq.w   #$8, a7
L27ee:
  0027ee:  20 2e ff d2          move.l   -$2e(a6), d0
  0027f2:  52 ae ff d2          addq.l   #$1, -$2e(a6)
L27f6:
  0027f6:  20 2e ff d2          move.l   -$2e(a6), d0
  0027fa:  b0 ae ff e2          cmp.l    -$1e(a6), d0
  0027fe:  65 00 ff 66          bcs.w    $2766  ; -> L2766
  002802:  70 00                moveq    #$0, d0
  002804:  2d 40 ff d2          move.l   d0, -$2e(a6)
  002808:  60 6a                bra.b    $2874  ; -> L2874
L280a:
  00280a:  20 6e ff e6          movea.l  -$1a(a6), a0
  00280e:  20 2e ff d2          move.l   -$2e(a6), d0
  002812:  d0 80                add.l    d0, d0
  002814:  22 00                move.l   d0, d1
  002816:  d2 81                add.l    d1, d1
  002818:  d0 81                add.l    d1, d0
  00281a:  4a 70 08 00          tst.w    (a0, d0.l)
  00281e:  66 4c                bne.b    $286c  ; -> L286c
  002820:  20 6e ff e6          movea.l  -$1a(a6), a0
  002824:  20 2e ff d2          move.l   -$2e(a6), d0
  002828:  d0 80                add.l    d0, d0
  00282a:  22 00                move.l   d0, d1
  00282c:  d2 81                add.l    d1, d1
  00282e:  d0 81                add.l    d1, d0
  002830:  2d 70 08 02 ff de    move.l   $2(a0, d0.l), -$22(a6)
  002836:  67 34                beq.b    $286c  ; -> L286c
  002838:  02 ae 0f ff ff ff ff de andi.l   #$fffffff, -$22(a6)
  002840:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  002844:  2f 2e ff 44          move.l   -$bc(a6), -(a7)
  002848:  61 ff 00 00 4c ac    bsr.l    $74f6  ; -> sub_74f6
  00284e:  20 6e ff e6          movea.l  -$1a(a6), a0
  002852:  22 2e ff d2          move.l   -$2e(a6), d1
  002856:  d2 81                add.l    d1, d1
  002858:  24 01                move.l   d1, d2
  00285a:  d4 82                add.l    d2, d2
  00285c:  d2 82                add.l    d2, d1
  00285e:  21 80 18 02          move.l   d0, $2(a0, d1.l)
  002862:  20 2e ff de          move.l   -$22(a6), d0
  002866:  d1 ae ff 44          add.l    d0, -$bc(a6)
  00286a:  50 4f                addq.w   #$8, a7
L286c:
  00286c:  20 2e ff d2          move.l   -$2e(a6), d0
  002870:  52 ae ff d2          addq.l   #$1, -$2e(a6)
L2874:
  002874:  20 2e ff d2          move.l   -$2e(a6), d0
  002878:  b0 ae ff e2          cmp.l    -$1e(a6), d0
  00287c:  65 8c                bcs.b    $280a  ; -> L280a
  00287e:  60 00 00 d4          bra.w    $2954  ; -> L2954
L2882:
  002882:  70 00                moveq    #$0, d0
  002884:  2d 40 ff d2          move.l   d0, -$2e(a6)
  002888:  60 00 00 be          bra.w    $2948  ; -> L2948
L288c:
  00288c:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  002890:  20 6e ff e6          movea.l  -$1a(a6), a0
  002894:  20 2e ff d2          move.l   -$2e(a6), d0
  002898:  d0 80                add.l    d0, d0
  00289a:  22 00                move.l   d0, d1
  00289c:  d2 81                add.l    d1, d1
  00289e:  d0 81                add.l    d1, d0
  0028a0:  2f 30 08 02          move.l   $2(a0, d0.l), -(a7)
  0028a4:  61 ff 00 00 4c 50    bsr.l    $74f6  ; -> sub_74f6
  0028aa:  20 6e ff e6          movea.l  -$1a(a6), a0
  0028ae:  22 2e ff d2          move.l   -$2e(a6), d1
  0028b2:  d2 81                add.l    d1, d1
  0028b4:  24 01                move.l   d1, d2
  0028b6:  d4 82                add.l    d2, d2
  0028b8:  d2 82                add.l    d2, d1
  0028ba:  21 80 18 02          move.l   d0, $2(a0, d1.l)
  0028be:  20 6e ff e6          movea.l  -$1a(a6), a0
  0028c2:  20 2e ff d2          move.l   -$2e(a6), d0
  0028c6:  d0 80                add.l    d0, d0
  0028c8:  22 00                move.l   d0, d1
  0028ca:  d2 81                add.l    d1, d1
  0028cc:  d0 81                add.l    d1, d0
  0028ce:  22 2e ff d6          move.l   -$2a(a6), d1
  0028d2:  52 81                addq.l   #$1, d1
  0028d4:  30 30 08 00          move.w   (a0, d0.l), d0
  0028d8:  48 c0                ext.l    d0
  0028da:  b2 80                cmp.l    d0, d1
  0028dc:  50 4f                addq.w   #$8, a7
  0028de:  66 60                bne.b    $2940  ; -> L2940
  0028e0:  20 6e ff e6          movea.l  -$1a(a6), a0
  0028e4:  20 2e ff d2          move.l   -$2e(a6), d0
  0028e8:  d0 80                add.l    d0, d0
  0028ea:  22 00                move.l   d0, d1
  0028ec:  d2 81                add.l    d1, d1
  0028ee:  d0 81                add.l    d1, d0
  0028f0:  22 48                movea.l  a0, a1
  0028f2:  22 2e ff d2          move.l   -$2e(a6), d1
  0028f6:  d2 81                add.l    d1, d1
  0028f8:  24 01                move.l   d1, d2
  0028fa:  d4 82                add.l    d2, d2
  0028fc:  d2 82                add.l    d2, d1
  0028fe:  24 2e ff 40          move.l   -$c0(a6), d2
  002902:  d4 b1 18 02          add.l    $2(a1, d1.l), d2
  002906:  94 ae ff 58          sub.l    -$a8(a6), d2
  00290a:  b4 b0 08 02          cmp.l    $2(a0, d0.l), d2
  00290e:  67 30                beq.b    $2940  ; -> L2940
  002910:  20 6e ff e6          movea.l  -$1a(a6), a0
  002914:  20 2e ff d2          move.l   -$2e(a6), d0
  002918:  d0 80                add.l    d0, d0
  00291a:  22 00                move.l   d0, d1
  00291c:  d2 81                add.l    d1, d1
  00291e:  d0 81                add.l    d1, d0
  002920:  22 2e ff 40          move.l   -$c0(a6), d1
  002924:  d2 b0 08 02          add.l    $2(a0, d0.l), d1
  002928:  92 ae ff 58          sub.l    -$a8(a6), d1
  00292c:  20 6e ff e6          movea.l  -$1a(a6), a0
  002930:  20 2e ff d2          move.l   -$2e(a6), d0
  002934:  d0 80                add.l    d0, d0
  002936:  24 00                move.l   d0, d2
  002938:  d4 82                add.l    d2, d2
  00293a:  d0 82                add.l    d2, d0
  00293c:  21 81 08 02          move.l   d1, $2(a0, d0.l)
L2940:
  002940:  20 2e ff d2          move.l   -$2e(a6), d0
  002944:  52 ae ff d2          addq.l   #$1, -$2e(a6)
L2948:
  002948:  20 2e ff d2          move.l   -$2e(a6), d0
  00294c:  b0 ae ff e2          cmp.l    -$1e(a6), d0
  002950:  65 00 ff 3a          bcs.w    $288c  ; -> L288c
L2954:
  002954:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  002958:  2f 2e ff 40          move.l   -$c0(a6), -(a7)
  00295c:  61 ff 00 00 4b 98    bsr.l    $74f6  ; -> sub_74f6
  002962:  2d 40 ff 3c          move.l   d0, -$c4(a6)
  002966:  90 ae ff 58          sub.l    -$a8(a6), d0
  00296a:  2d 40 ff 38          move.l   d0, -$c8(a6)
  00296e:  20 2e ff 34          move.l   -$cc(a6), d0
  002972:  e4 88                lsr.l    #$2, d0
  002974:  e5 80                asl.l    #$2, d0
  002976:  d1 ae ff 40          add.l    d0, -$c0(a6)
  00297a:  70 02                moveq    #$2, d0
  00297c:  b0 6e ff d0          cmp.w    -$30(a6), d0
  002980:  50 4f                addq.w   #$8, a7
  002982:  66 00 06 9e          bne.w    $3022  ; -> L3022
  002986:  20 3c 00 00 00 80    move.l   #$80, d0
  00298c:  c0 ae ff 74          and.l    -$8c(a6), d0
  002990:  66 00 06 90          bne.w    $3022  ; -> L3022
  002994:  20 2e ff 34          move.l   -$cc(a6), d0
  002998:  d0 ae ff 2e          add.l    -$d2(a6), d0
  00299c:  b0 ae ff da          cmp.l    -$26(a6), d0
  0029a0:  63 1a                bls.b    $29bc  ; -> L29bc
  0029a2:  20 2e ff 2e          move.l   -$d2(a6), d0
  0029a6:  90 ae ff da          sub.l    -$26(a6), d0
  0029aa:  2f 00                move.l   d0, -(a7)
  0029ac:  48 7a 07 56          pea.l    $3104(pc)
  0029b0:  61 ff ff ff f9 ea    bsr.l    $239c  ; -> sub_239c
  0029b6:  50 4f                addq.w   #$8, a7
  0029b8:  60 00 06 ae          bra.w    $3068  ; -> L3068
L29bc:
  0029bc:  2d 6e ff 3c ff 2a    move.l   -$c4(a6), -$d6(a6)
  0029c2:  59 8f                subq.l   #$4, a7
  0029c4:  2f 2e ff 2e          move.l   -$d2(a6), -(a7)
  0029c8:  61 ff 00 00 98 80    bsr.l    $c24a  ; -> Strip24
  0029ce:  2d 5f ff 22          move.l   (a7)+, -$de(a6)
  0029d2:  1d 7c 00 01 ff 33    move.b   #$1, -$cd(a6)
  0029d8:  41 ee ff 33          lea.l    -$cd(a6), a0
  0029dc:  10 10                move.b   (a0), d0
  0029de:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  0029e0:  10 80                move.b   d0, (a0)
  0029e2:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  0029e6:  2f 2e ff 2a          move.l   -$d6(a6), -(a7)
  0029ea:  61 ff 00 00 4b 0a    bsr.l    $74f6  ; -> sub_74f6
  0029f0:  2d 40 ff 26          move.l   d0, -$da(a6)
  0029f4:  70 00                moveq    #$0, d0
  0029f6:  30 2e ff 70          move.w   -$90(a6), d0
  0029fa:  4a 80                tst.l    d0
  0029fc:  50 4f                addq.w   #$8, a7
  0029fe:  67 00 05 f4          beq.w    $2ff4  ; -> L2ff4
  002a02:  0c ae 00 00 ff ff ff e2 cmpi.l   #$ffff, -$1e(a6)
  002a0a:  6f 00 02 fc          ble.w    $2d08  ; -> L2d08
  002a0e:  70 00                moveq    #$0, d0
  002a10:  2d 40 ff d2          move.l   d0, -$2e(a6)
  002a14:  60 00 02 e2          bra.w    $2cf8  ; -> L2cf8
L2a18:
  002a18:  70 00                moveq    #$0, d0
  002a1a:  2d 40 ff ea          move.l   d0, -$16(a6)
  002a1e:  22 2e ff 22          move.l   -$de(a6), d1
  002a22:  58 ae ff 22          addq.l   #$4, -$de(a6)
  002a26:  20 41                movea.l  d1, a0
  002a28:  2e 10                move.l   (a0), d7
  002a2a:  60 00 02 84          bra.w    $2cb0  ; -> L2cb0
L2a2e:
  002a2e:  70 00                moveq    #$0, d0
  002a30:  30 2b 00 08          move.w   $8(a3), d0
  002a34:  72 1c                moveq    #$1c, d1
  002a36:  b2 80                cmp.l    d0, d1
  002a38:  67 34                beq.b    $2a6e  ; -> L2a6e
  002a3a:  60 04                bra.b    $2a40  ; -> L2a40
L2a3c:
  002a3c:  52 ab 00 04          addq.l   #$1, $4(a3)
L2a40:
  002a40:  20 6e ff e6          movea.l  -$1a(a6), a0
  002a44:  20 2b 00 04          move.l   $4(a3), d0
  002a48:  d0 80                add.l    d0, d0
  002a4a:  22 00                move.l   d0, d1
  002a4c:  d2 81                add.l    d1, d1
  002a4e:  d0 81                add.l    d1, d0
  002a50:  72 fd                moveq    #$fd, d1
  002a52:  b2 70 08 00          cmp.w    (a0, d0.l), d1
  002a56:  67 e4                beq.b    $2a3c  ; -> L2a3c
  002a58:  20 6e ff e6          movea.l  -$1a(a6), a0
  002a5c:  20 2b 00 04          move.l   $4(a3), d0
  002a60:  d0 80                add.l    d0, d0
  002a62:  22 00                move.l   d0, d1
  002a64:  d2 81                add.l    d1, d1
  002a66:  d0 81                add.l    d1, d0
  002a68:  2d 70 08 02 ff 1e    move.l   $2(a0, d0.l), -$e2(a6)
L2a6e:
  002a6e:  30 2b 00 08          move.w   $8(a3), d0
  002a72:  65 00 02 30          bcs.w    $2ca4  ; -> L2ca4
  002a76:  0c 40 00 22          cmpi.w   #$22, d0
  002a7a:  62 00 02 28          bhi.w    $2ca4  ; -> L2ca4
  002a7e:  d0 40                add.w    d0, d0
  002a80:  30 3b 00 06          move.w   $2a88(pc, d0.w), d0
  002a84:  4e fb 00 00          jmp      $2a86(pc,d0.w)  ; -> L2a86
* jump table (word offsets relative to $2A86, indexed by selector*2):
  002a88:  02 1e                dc.w     $021E    ; case 1 -> L2ca4
  002a8a:  02 1e                dc.w     $021E    ; case 2 -> L2ca4
  002a8c:  02 1e                dc.w     $021E    ; case 3 -> L2ca4
  002a8e:  02 1e                dc.w     $021E    ; case 4 -> L2ca4
  002a90:  02 1e                dc.w     $021E    ; case 5 -> L2ca4
  002a92:  02 1e                dc.w     $021E    ; case 6 -> L2ca4
  002a94:  02 1e                dc.w     $021E    ; case 7 -> L2ca4
  002a96:  02 1e                dc.w     $021E    ; case 8 -> L2ca4
  002a98:  02 1e                dc.w     $021E    ; case 9 -> L2ca4
  002a9a:  02 1e                dc.w     $021E    ; case 10 -> L2ca4
  002a9c:  02 1e                dc.w     $021E    ; case 11 -> L2ca4
  002a9e:  02 1e                dc.w     $021E    ; case 12 -> L2ca4
  002aa0:  02 1e                dc.w     $021E    ; case 13 -> L2ca4
  002aa2:  02 1e                dc.w     $021E    ; case 14 -> L2ca4
  002aa4:  02 1e                dc.w     $021E    ; case 15 -> L2ca4
  002aa6:  02 1e                dc.w     $021E    ; case 16 -> L2ca4
  002aa8:  02 1e                dc.w     $021E    ; case 17 -> L2ca4
  002aaa:  02 1e                dc.w     $021E    ; case 18 -> L2ca4
  002aac:  02 1e                dc.w     $021E    ; case 19 -> L2ca4
  002aae:  02 1e                dc.w     $021E    ; case 20 -> L2ca4
  002ab0:  02 1e                dc.w     $021E    ; case 21 -> L2ca4
  002ab2:  02 1e                dc.w     $021E    ; case 22 -> L2ca4
  002ab4:  02 1e                dc.w     $021E    ; case 23 -> L2ca4
  002ab6:  02 1e                dc.w     $021E    ; case 24 -> L2ca4
  002ab8:  00 4c                dc.w     $004C    ; case 25 -> L2ad2
  002aba:  00 b2                dc.w     $00B2    ; case 26 -> L2b38
  002abc:  01 0a                dc.w     $010A    ; case 27 -> L2b90
  002abe:  01 5a                dc.w     $015A    ; case 28 -> L2be0
  002ac0:  02 1e                dc.w     $021E    ; case 29 -> L2ca4
  002ac2:  01 c6                dc.w     $01C6    ; case 30 -> L2c4c
  002ac4:  01 e4                dc.w     $01E4    ; case 31 -> L2c6a
  002ac6:  02 02                dc.w     $0202    ; case 32 -> L2c88
  002ac8:  02 1e                dc.w     $021E    ; case 33 -> L2ca4
  002aca:  02 1e                dc.w     $021E    ; case 34 -> L2ca4
  002acc:  02 1e                dc.w     $021E    ; case 35 -> L2ca4
  002ace:  60 00 01 d4          bra.w    $2ca4  ; -> L2ca4
L2ad2:
  002ad2:  20 2e ff 1e          move.l   -$e2(a6), d0
  002ad6:  90 ae ff 3c          sub.l    -$c4(a6), d0
  002ada:  2a 00                move.l   d0, d5
  002adc:  e4 85                asr.l    #$2, d5
  002ade:  0c 85 00 00 7f ff    cmpi.l   #$7fff, d5
  002ae4:  6e 08                bgt.b    $2aee  ; -> L2aee
  002ae6:  0c 85 ff ff 80 00    cmpi.l   #$ffff8000, d5
  002aec:  6c 24                bge.b    $2b12  ; -> L2b12
L2aee:
  002aee:  41 ee ff 33          lea.l    -$cd(a6), a0
  002af2:  10 10                move.b   (a0), d0
  002af4:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  002af6:  10 80                move.b   d0, (a0)
  002af8:  2f 2e ff 3c          move.l   -$c4(a6), -(a7)
  002afc:  2f 2e ff 1e          move.l   -$e2(a6), -(a7)
  002b00:  48 7a 05 c8          pea.l    $30ca(pc)
  002b04:  61 ff ff ff f8 96    bsr.l    $239c  ; -> sub_239c
  002b0a:  4f ef 00 0c          lea.l    $c(a7), a7
  002b0e:  60 00 05 58          bra.w    $3068  ; -> L3068
L2b12:
  002b12:  20 3c ff 00 ff 00    move.l   #$ff00ff00, d0
  002b18:  c0 87                and.l    d7, d0
  002b1a:  22 3c 00 00 00 ff    move.l   #$ff, d1
  002b20:  c2 85                and.l    d5, d1
  002b22:  82 80                or.l     d0, d1
  002b24:  20 05                move.l   d5, d0
  002b26:  e1 88                lsl.l    #$8, d0
  002b28:  24 3c 00 ff 00 00    move.l   #$ff0000, d2
  002b2e:  c4 80                and.l    d0, d2
  002b30:  84 81                or.l     d1, d2
  002b32:  2e 02                move.l   d2, d7
  002b34:  60 00 01 6e          bra.w    $2ca4  ; -> L2ca4
L2b38:
  002b38:  2a 2e ff 1e          move.l   -$e2(a6), d5
  002b3c:  e4 85                asr.l    #$2, d5
  002b3e:  0c 85 00 00 ff ff    cmpi.l   #$ffff, d5
  002b44:  6f 24                ble.b    $2b6a  ; -> L2b6a
  002b46:  41 ee ff 33          lea.l    -$cd(a6), a0
  002b4a:  10 10                move.b   (a0), d0
  002b4c:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  002b4e:  10 80                move.b   d0, (a0)
  002b50:  2f 2e ff 3c          move.l   -$c4(a6), -(a7)
  002b54:  2f 2e ff 1e          move.l   -$e2(a6), -(a7)
  002b58:  48 7a 05 36          pea.l    $3090(pc)
  002b5c:  61 ff ff ff f8 3e    bsr.l    $239c  ; -> sub_239c
  002b62:  4f ef 00 0c          lea.l    $c(a7), a7
  002b66:  60 00 05 00          bra.w    $3068  ; -> L3068
L2b6a:
  002b6a:  20 3c ff 00 ff 00    move.l   #$ff00ff00, d0
  002b70:  c0 87                and.l    d7, d0
  002b72:  22 3c 00 00 00 ff    move.l   #$ff, d1
  002b78:  c2 85                and.l    d5, d1
  002b7a:  82 80                or.l     d0, d1
  002b7c:  20 05                move.l   d5, d0
  002b7e:  e1 88                lsl.l    #$8, d0
  002b80:  24 3c 00 ff 00 00    move.l   #$ff0000, d2
  002b86:  c4 80                and.l    d0, d2
  002b88:  84 81                or.l     d1, d2
  002b8a:  2e 02                move.l   d2, d7
  002b8c:  60 00 01 16          bra.w    $2ca4  ; -> L2ca4
L2b90:
  002b90:  20 3c 00 00 00 ff    move.l   #$ff, d0
  002b96:  c0 87                and.l    d7, d0
  002b98:  22 07                move.l   d7, d1
  002b9a:  e0 89                lsr.l    #$8, d1
  002b9c:  24 3c 00 00 ff 00    move.l   #$ff00, d2
  002ba2:  c4 81                and.l    d1, d2
  002ba4:  2a 02                move.l   d2, d5
  002ba6:  8a 80                or.l     d0, d5
  002ba8:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  002bac:  2f 2e ff 1e          move.l   -$e2(a6), -(a7)
  002bb0:  61 ff 00 00 49 44    bsr.l    $74f6  ; -> sub_74f6
  002bb6:  da 80                add.l    d0, d5
  002bb8:  20 3c ff 00 ff 00    move.l   #$ff00ff00, d0
  002bbe:  c0 87                and.l    d7, d0
  002bc0:  22 3c 00 00 00 ff    move.l   #$ff, d1
  002bc6:  c2 85                and.l    d5, d1
  002bc8:  82 80                or.l     d0, d1
  002bca:  20 05                move.l   d5, d0
  002bcc:  e1 88                lsl.l    #$8, d0
  002bce:  24 3c 00 ff 00 00    move.l   #$ff0000, d2
  002bd4:  c4 80                and.l    d0, d2
  002bd6:  84 81                or.l     d1, d2
  002bd8:  2e 02                move.l   d2, d7
  002bda:  50 4f                addq.w   #$8, a7
  002bdc:  60 00 00 c6          bra.w    $2ca4  ; -> L2ca4
L2be0:
  002be0:  20 3c 00 00 00 ff    move.l   #$ff, d0
  002be6:  c0 87                and.l    d7, d0
  002be8:  22 07                move.l   d7, d1
  002bea:  e0 89                lsr.l    #$8, d1
  002bec:  24 3c 00 00 ff 00    move.l   #$ff00, d2
  002bf2:  c4 81                and.l    d1, d2
  002bf4:  84 80                or.l     d0, d2
  002bf6:  70 10                moveq    #$10, d0
  002bf8:  2a 02                move.l   d2, d5
  002bfa:  e1 ad                lsl.l    d0, d5
  002bfc:  47 eb 00 0a          lea.l    $a(a3), a3
  002c00:  30 2e ff 70          move.w   -$90(a6), d0
  002c04:  53 6e ff 70          subq.w   #$1, -$90(a6)
  002c08:  70 00                moveq    #$0, d0
  002c0a:  30 2b 00 06          move.w   $6(a3), d0
  002c0e:  8a 80                or.l     d0, d5
  002c10:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  002c14:  2f 2e ff 1e          move.l   -$e2(a6), -(a7)
  002c18:  61 ff 00 00 48 dc    bsr.l    $74f6  ; -> sub_74f6
  002c1e:  d0 85                add.l    d5, d0
  002c20:  2a 00                move.l   d0, d5
  002c22:  70 10                moveq    #$10, d0
  002c24:  e0 a5                asr.l    d0, d5
  002c26:  20 3c ff 00 ff 00    move.l   #$ff00ff00, d0
  002c2c:  c0 87                and.l    d7, d0
  002c2e:  22 3c 00 00 00 ff    move.l   #$ff, d1
  002c34:  c2 85                and.l    d5, d1
  002c36:  82 80                or.l     d0, d1
  002c38:  20 05                move.l   d5, d0
  002c3a:  e1 88                lsl.l    #$8, d0
  002c3c:  24 3c 00 ff 00 00    move.l   #$ff0000, d2
  002c42:  c4 80                and.l    d0, d2
  002c44:  84 81                or.l     d1, d2
  002c46:  2e 02                move.l   d2, d7
  002c48:  50 4f 60 58          dc.b     $50,$4f,$60,$58  ; PO`X
L2c4c:
  002c4c:  20 6e                dc.b     $20,$6e  ;  n
  002c4e:  ff 26                fsave    -(a6)
  002c50:  20 87                move.l   d7, (a0)
  002c52:  70 01                moveq    #$1, d0
  002c54:  2d 40 ff ea          move.l   d0, -$16(a6)
  002c58:  72 03                moveq    #$3, d1
  002c5a:  c2 93                and.l    (a3), d1
  002c5c:  d2 ae ff 26          add.l    -$da(a6), d1
  002c60:  20 41                movea.l  d1, a0
  002c62:  12 2e ff 21          move.b   -$df(a6), d1
  002c66:  d3 10                add.b    d1, (a0)
  002c68:  60 3a                bra.b    $2ca4  ; -> L2ca4
L2c6a:
  002c6a:  20 6e ff 26          movea.l  -$da(a6), a0
  002c6e:  20 87                move.l   d7, (a0)
  002c70:  70 01                moveq    #$1, d0
  002c72:  2d 40 ff ea          move.l   d0, -$16(a6)
  002c76:  72 03                moveq    #$3, d1
  002c78:  c2 93                and.l    (a3), d1
  002c7a:  d2 ae ff 26          add.l    -$da(a6), d1
  002c7e:  20 41                movea.l  d1, a0
  002c80:  32 2e ff 20          move.w   -$e0(a6), d1
  002c84:  d3 50                add.w    d1, (a0)
  002c86:  60 1c                bra.b    $2ca4  ; -> L2ca4
L2c88:
  002c88:  20 6e ff 26          movea.l  -$da(a6), a0
  002c8c:  20 87                move.l   d7, (a0)
  002c8e:  70 01                moveq    #$1, d0
  002c90:  2d 40 ff ea          move.l   d0, -$16(a6)
  002c94:  72 03                moveq    #$3, d1
  002c96:  c2 93                and.l    (a3), d1
  002c98:  d2 ae ff 26          add.l    -$da(a6), d1
  002c9c:  20 41                movea.l  d1, a0
  002c9e:  22 2e ff 1e          move.l   -$e2(a6), d1
  002ca2:  d3 90                add.l    d1, (a0)
L2ca4:
  002ca4:  30 2e ff 70          move.w   -$90(a6), d0
  002ca8:  53 6e ff 70          subq.w   #$1, -$90(a6)
  002cac:  47 eb 00 0a          lea.l    $a(a3), a3
L2cb0:
  002cb0:  70 00                moveq    #$0, d0
  002cb2:  30 2e ff 70          move.w   -$90(a6), d0
  002cb6:  4a 80                tst.l    d0
  002cb8:  67 1e                beq.b    $2cd8  ; -> L2cd8
  002cba:  20 13                move.l   (a3), d0
  002cbc:  d0 ae ff 38          add.l    -$c8(a6), d0
  002cc0:  b0 ae ff 3c          cmp.l    -$c4(a6), d0
  002cc4:  65 12                bcs.b    $2cd8  ; -> L2cd8
  002cc6:  20 2e ff 3c          move.l   -$c4(a6), d0
  002cca:  58 80                addq.l   #$4, d0
  002ccc:  22 13                move.l   (a3), d1
  002cce:  d2 ae ff 38          add.l    -$c8(a6), d1
  002cd2:  b2 80                cmp.l    d0, d1
  002cd4:  65 00 fd 58          bcs.w    $2a2e  ; -> L2a2e
L2cd8:
  002cd8:  4a ae ff ea          tst.l    -$16(a6)
  002cdc:  66 06                bne.b    $2ce4  ; -> L2ce4
  002cde:  20 6e ff 26          movea.l  -$da(a6), a0
  002ce2:  20 87                move.l   d7, (a0)
L2ce4:
  002ce4:  20 2e ff 26          move.l   -$da(a6), d0
  002ce8:  58 ae ff 26          addq.l   #$4, -$da(a6)
  002cec:  20 2e ff 3c          move.l   -$c4(a6), d0
  002cf0:  58 ae ff 3c          addq.l   #$4, -$c4(a6)
  002cf4:  58 ae ff d2          addq.l   #$4, -$2e(a6)
L2cf8:
  002cf8:  20 2e ff d2          move.l   -$2e(a6), d0
  002cfc:  b0 ae ff 34          cmp.l    -$cc(a6), d0
  002d00:  65 00 fd 16          bcs.w    $2a18  ; -> L2a18
  002d04:  60 00 03 12          bra.w    $3018  ; -> L3018
L2d08:
  002d08:  70 00                moveq    #$0, d0
  002d0a:  2d 40 ff d2          move.l   d0, -$2e(a6)
  002d0e:  60 00 02 d6          bra.w    $2fe6  ; -> L2fe6
L2d12:
  002d12:  70 00                moveq    #$0, d0
  002d14:  2d 40 ff ea          move.l   d0, -$16(a6)
  002d18:  22 2e ff 22          move.l   -$de(a6), d1
  002d1c:  58 ae ff 22          addq.l   #$4, -$de(a6)
  002d20:  20 41                movea.l  d1, a0
  002d22:  2e 10                move.l   (a0), d7
  002d24:  60 00 02 78          bra.w    $2f9e  ; -> L2f9e
L2d28:
  002d28:  70 00                moveq    #$0, d0
  002d2a:  30 2c 00 06          move.w   $6(a4), d0
  002d2e:  72 1c                moveq    #$1c, d1
  002d30:  b2 80                cmp.l    d0, d1
  002d32:  67 36                beq.b    $2d6a  ; -> L2d6a
  002d34:  60 04                bra.b    $2d3a  ; -> L2d3a
L2d36:
  002d36:  52 6c 00 04          addq.w   #$1, $4(a4)
L2d3a:
  002d3a:  30 2c 00 04          move.w   $4(a4), d0
  002d3e:  48 c0                ext.l    d0
  002d40:  20 6e ff e6          movea.l  -$1a(a6), a0
  002d44:  d0 80                add.l    d0, d0
  002d46:  22 00                move.l   d0, d1
  002d48:  d2 81                add.l    d1, d1
  002d4a:  d0 81                add.l    d1, d0
  002d4c:  72 fd                moveq    #$fd, d1
  002d4e:  b2 70 08 00          cmp.w    (a0, d0.l), d1
  002d52:  67 e2                beq.b    $2d36  ; -> L2d36
  002d54:  30 2c 00 04          move.w   $4(a4), d0
  002d58:  48 c0                ext.l    d0
  002d5a:  20 6e ff e6          movea.l  -$1a(a6), a0
  002d5e:  d0 80                add.l    d0, d0
  002d60:  22 00                move.l   d0, d1
  002d62:  d2 81                add.l    d1, d1
  002d64:  d0 81                add.l    d1, d0
  002d66:  28 30 08 02          move.l   $2(a0, d0.l), d4
L2d6a:
  002d6a:  30 2c 00 06          move.w   $6(a4), d0
  002d6e:  65 00 02 24          bcs.w    $2f94  ; -> L2f94
  002d72:  0c 40 00 22          cmpi.w   #$22, d0
  002d76:  62 00 02 1c          bhi.w    $2f94  ; -> L2f94
  002d7a:  d0 40                add.w    d0, d0
  002d7c:  30 3b 00 06          move.w   $2d84(pc, d0.w), d0
  002d80:  4e fb 00 00          jmp      $2d82(pc,d0.w)  ; -> L2d82
* jump table (word offsets relative to $2D82, indexed by selector*2):
  002d84:  02 12                dc.w     $0212    ; case 1 -> L2f94
  002d86:  02 12                dc.w     $0212    ; case 2 -> L2f94
  002d88:  02 12                dc.w     $0212    ; case 3 -> L2f94
  002d8a:  02 12                dc.w     $0212    ; case 4 -> L2f94
  002d8c:  02 12                dc.w     $0212    ; case 5 -> L2f94
  002d8e:  02 12                dc.w     $0212    ; case 6 -> L2f94
  002d90:  02 12                dc.w     $0212    ; case 7 -> L2f94
  002d92:  02 12                dc.w     $0212    ; case 8 -> L2f94
  002d94:  02 12                dc.w     $0212    ; case 9 -> L2f94
  002d96:  02 12                dc.w     $0212    ; case 10 -> L2f94
  002d98:  02 12                dc.w     $0212    ; case 11 -> L2f94
  002d9a:  02 12                dc.w     $0212    ; case 12 -> L2f94
  002d9c:  02 12                dc.w     $0212    ; case 13 -> L2f94
  002d9e:  02 12                dc.w     $0212    ; case 14 -> L2f94
  002da0:  02 12                dc.w     $0212    ; case 15 -> L2f94
  002da2:  02 12                dc.w     $0212    ; case 16 -> L2f94
  002da4:  02 12                dc.w     $0212    ; case 17 -> L2f94
  002da6:  02 12                dc.w     $0212    ; case 18 -> L2f94
  002da8:  02 12                dc.w     $0212    ; case 19 -> L2f94
  002daa:  02 12                dc.w     $0212    ; case 20 -> L2f94
  002dac:  02 12                dc.w     $0212    ; case 21 -> L2f94
  002dae:  02 12                dc.w     $0212    ; case 22 -> L2f94
  002db0:  02 12                dc.w     $0212    ; case 23 -> L2f94
  002db2:  02 12                dc.w     $0212    ; case 24 -> L2f94
  002db4:  00 4c                dc.w     $004C    ; case 25 -> L2dce
  002db6:  00 ae                dc.w     $00AE    ; case 26 -> L2e30
  002db8:  01 02                dc.w     $0102    ; case 27 -> L2e84
  002dba:  01 50                dc.w     $0150    ; case 28 -> L2ed2
  002dbc:  02 12                dc.w     $0212    ; case 29 -> L2f94
  002dbe:  01 c6                dc.w     $01C6    ; case 30 -> L2f48
  002dc0:  01 e0                dc.w     $01E0    ; case 31 -> L2f62
  002dc2:  01 fa                dc.w     $01FA    ; case 32 -> L2f7c
  002dc4:  02 12                dc.w     $0212    ; case 33 -> L2f94
  002dc6:  02 12                dc.w     $0212    ; case 34 -> L2f94
  002dc8:  02 12                dc.w     $0212    ; case 35 -> L2f94
  002dca:  60 00 01 c8          bra.w    $2f94  ; -> L2f94
L2dce:
  002dce:  20 04                move.l   d4, d0
  002dd0:  90 ae ff 3c          sub.l    -$c4(a6), d0
  002dd4:  2c 00                move.l   d0, d6
  002dd6:  e4 86                asr.l    #$2, d6
  002dd8:  0c 86 00 00 7f ff    cmpi.l   #$7fff, d6
  002dde:  6e 08                bgt.b    $2de8  ; -> L2de8
  002de0:  0c 86 ff ff 80 00    cmpi.l   #$ffff8000, d6
  002de6:  6c 22                bge.b    $2e0a  ; -> L2e0a
L2de8:
  002de8:  41 ee ff 33          lea.l    -$cd(a6), a0
  002dec:  10 10                move.b   (a0), d0
  002dee:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  002df0:  10 80                move.b   d0, (a0)
  002df2:  2f 2e ff 3c          move.l   -$c4(a6), -(a7)
  002df6:  2f 04                move.l   d4, -(a7)
  002df8:  48 7a 02 d0          pea.l    $30ca(pc)
  002dfc:  61 ff ff ff f5 9e    bsr.l    $239c  ; -> sub_239c
  002e02:  4f ef 00 0c          lea.l    $c(a7), a7
  002e06:  60 00 02 60          bra.w    $3068  ; -> L3068
L2e0a:
  002e0a:  20 3c ff 00 ff 00    move.l   #$ff00ff00, d0
  002e10:  c0 87                and.l    d7, d0
  002e12:  22 3c 00 00 00 ff    move.l   #$ff, d1
  002e18:  c2 86                and.l    d6, d1
  002e1a:  82 80                or.l     d0, d1
  002e1c:  20 06                move.l   d6, d0
  002e1e:  e1 88                lsl.l    #$8, d0
  002e20:  24 3c 00 ff 00 00    move.l   #$ff0000, d2
  002e26:  c4 80                and.l    d0, d2
  002e28:  84 81                or.l     d1, d2
  002e2a:  2e 02                move.l   d2, d7
  002e2c:  60 00 01 66          bra.w    $2f94  ; -> L2f94
L2e30:
  002e30:  2c 04                move.l   d4, d6
  002e32:  e4 86                asr.l    #$2, d6
  002e34:  0c 86 00 00 ff ff    cmpi.l   #$ffff, d6
  002e3a:  6f 22                ble.b    $2e5e  ; -> L2e5e
  002e3c:  41 ee ff 33          lea.l    -$cd(a6), a0
  002e40:  10 10                move.b   (a0), d0
  002e42:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  002e44:  10 80                move.b   d0, (a0)
  002e46:  2f 2e ff 3c          move.l   -$c4(a6), -(a7)
  002e4a:  2f 04                move.l   d4, -(a7)
  002e4c:  48 7a 02 42          pea.l    $3090(pc)
  002e50:  61 ff ff ff f5 4a    bsr.l    $239c  ; -> sub_239c
  002e56:  4f ef 00 0c          lea.l    $c(a7), a7
  002e5a:  60 00 02 0c          bra.w    $3068  ; -> L3068
L2e5e:
  002e5e:  20 3c ff 00 ff 00    move.l   #$ff00ff00, d0
  002e64:  c0 87                and.l    d7, d0
  002e66:  22 3c 00 00 00 ff    move.l   #$ff, d1
  002e6c:  c2 86                and.l    d6, d1
  002e6e:  82 80                or.l     d0, d1
  002e70:  20 06                move.l   d6, d0
  002e72:  e1 88                lsl.l    #$8, d0
  002e74:  24 3c 00 ff 00 00    move.l   #$ff0000, d2
  002e7a:  c4 80                and.l    d0, d2
  002e7c:  84 81                or.l     d1, d2
  002e7e:  2e 02                move.l   d2, d7
  002e80:  60 00 01 12          bra.w    $2f94  ; -> L2f94
L2e84:
  002e84:  20 3c 00 00 00 ff    move.l   #$ff, d0
  002e8a:  c0 87                and.l    d7, d0
  002e8c:  22 07                move.l   d7, d1
  002e8e:  e0 89                lsr.l    #$8, d1
  002e90:  24 3c 00 00 ff 00    move.l   #$ff00, d2
  002e96:  c4 81                and.l    d1, d2
  002e98:  2c 02                move.l   d2, d6
  002e9a:  8c 80                or.l     d0, d6
  002e9c:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  002ea0:  2f 04                move.l   d4, -(a7)
  002ea2:  61 ff 00 00 46 52    bsr.l    $74f6  ; -> sub_74f6
  002ea8:  dc 80                add.l    d0, d6
  002eaa:  20 3c ff 00 ff 00    move.l   #$ff00ff00, d0
  002eb0:  c0 87                and.l    d7, d0
  002eb2:  22 3c 00 00 00 ff    move.l   #$ff, d1
  002eb8:  c2 86                and.l    d6, d1
  002eba:  82 80                or.l     d0, d1
  002ebc:  20 06                move.l   d6, d0
  002ebe:  e1 88                lsl.l    #$8, d0
  002ec0:  24 3c 00 ff 00 00    move.l   #$ff0000, d2
  002ec6:  c4 80                and.l    d0, d2
  002ec8:  84 81                or.l     d1, d2
  002eca:  2e 02                move.l   d2, d7
  002ecc:  50 4f                addq.w   #$8, a7
  002ece:  60 00 00 c4          bra.w    $2f94  ; -> L2f94
L2ed2:
  002ed2:  20 3c 00 00 00 ff    move.l   #$ff, d0
  002ed8:  c0 87                and.l    d7, d0
  002eda:  22 07                move.l   d7, d1
  002edc:  e0 89                lsr.l    #$8, d1
  002ede:  24 3c 00 00 ff 00    move.l   #$ff00, d2
  002ee4:  c4 81                and.l    d1, d2
  002ee6:  84 80                or.l     d0, d2
  002ee8:  70 10                moveq    #$10, d0
  002eea:  2c 02                move.l   d2, d6
  002eec:  e1 ae                lsl.l    d0, d6
  002eee:  50 4c                addq.w   #$8, a4
  002ef0:  70 00                moveq    #$0, d0
  002ef2:  30 2c 00 06          move.w   $6(a4), d0
  002ef6:  72 1c                moveq    #$1c, d1
  002ef8:  b2 80                cmp.l    d0, d1
  002efa:  67 02                beq.b    $2efe  ; -> L2efe
  002efc:  a9 ff                dc.w     $a9ff  ; _Debugger
L2efe:
  002efe:  30 2e ff 70          move.w   -$90(a6), d0
  002f02:  53 6e ff 70          subq.w   #$1, -$90(a6)
  002f06:  70 00                moveq    #$0, d0
  002f08:  30 2c 00 04          move.w   $4(a4), d0
  002f0c:  8c 80                or.l     d0, d6
  002f0e:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  002f12:  2f 04                move.l   d4, -(a7)
  002f14:  61 ff 00 00 45 e0    bsr.l    $74f6  ; -> sub_74f6
  002f1a:  d0 86                add.l    d6, d0
  002f1c:  2c 00                move.l   d0, d6
  002f1e:  70 10                moveq    #$10, d0
  002f20:  e0 a6                asr.l    d0, d6
  002f22:  20 3c ff 00 ff 00    move.l   #$ff00ff00, d0
  002f28:  c0 87                and.l    d7, d0
  002f2a:  22 3c 00 00 00 ff    move.l   #$ff, d1
  002f30:  c2 86                and.l    d6, d1
  002f32:  82 80                or.l     d0, d1
  002f34:  20 06                move.l   d6, d0
  002f36:  e1 88                lsl.l    #$8, d0
  002f38:  24 3c 00 ff 00 00    move.l   #$ff0000, d2
  002f3e:  c4 80                and.l    d0, d2
  002f40:  84 81                or.l     d1, d2
  002f42:  2e 02                move.l   d2, d7
  002f44:  50 4f 60 4c          dc.b     $50,$4f,$60,$4c  ; PO`L
L2f48:
  002f48:  20 6e                dc.b     $20,$6e  ;  n
  002f4a:  ff 26                fsave    -(a6)
  002f4c:  20 87                move.l   d7, (a0)
  002f4e:  70 01                moveq    #$1, d0
  002f50:  2d 40 ff ea          move.l   d0, -$16(a6)
  002f54:  72 03                moveq    #$3, d1
  002f56:  c2 94                and.l    (a4), d1
  002f58:  d2 ae ff 26          add.l    -$da(a6), d1
  002f5c:  20 41                movea.l  d1, a0
  002f5e:  d9 10                add.b    d4, (a0)
  002f60:  60 32                bra.b    $2f94  ; -> L2f94
L2f62:
  002f62:  20 6e ff 26          movea.l  -$da(a6), a0
  002f66:  20 87                move.l   d7, (a0)
  002f68:  70 01                moveq    #$1, d0
  002f6a:  2d 40 ff ea          move.l   d0, -$16(a6)
  002f6e:  72 03                moveq    #$3, d1
  002f70:  c2 94                and.l    (a4), d1
  002f72:  d2 ae ff 26          add.l    -$da(a6), d1
  002f76:  20 41                movea.l  d1, a0
  002f78:  d9 50                add.w    d4, (a0)
  002f7a:  60 18                bra.b    $2f94  ; -> L2f94
L2f7c:
  002f7c:  20 6e ff 26          movea.l  -$da(a6), a0
  002f80:  20 87                move.l   d7, (a0)
  002f82:  70 01                moveq    #$1, d0
  002f84:  2d 40 ff ea          move.l   d0, -$16(a6)
  002f88:  72 03                moveq    #$3, d1
  002f8a:  c2 94                and.l    (a4), d1
  002f8c:  d2 ae ff 26          add.l    -$da(a6), d1
  002f90:  20 41                movea.l  d1, a0
  002f92:  d9 90                add.l    d4, (a0)
L2f94:
  002f94:  30 2e ff 70          move.w   -$90(a6), d0
  002f98:  53 6e ff 70          subq.w   #$1, -$90(a6)
  002f9c:  50 4c                addq.w   #$8, a4
L2f9e:
  002f9e:  70 00                moveq    #$0, d0
  002fa0:  30 2e ff 70          move.w   -$90(a6), d0
  002fa4:  4a 80                tst.l    d0
  002fa6:  67 1e                beq.b    $2fc6  ; -> L2fc6
  002fa8:  20 14                move.l   (a4), d0
  002faa:  d0 ae ff 38          add.l    -$c8(a6), d0
  002fae:  b0 ae ff 3c          cmp.l    -$c4(a6), d0
  002fb2:  65 12                bcs.b    $2fc6  ; -> L2fc6
  002fb4:  20 2e ff 3c          move.l   -$c4(a6), d0
  002fb8:  58 80                addq.l   #$4, d0
  002fba:  22 14                move.l   (a4), d1
  002fbc:  d2 ae ff 38          add.l    -$c8(a6), d1
  002fc0:  b2 80                cmp.l    d0, d1
  002fc2:  65 00 fd 64          bcs.w    $2d28  ; -> L2d28
L2fc6:
  002fc6:  4a ae ff ea          tst.l    -$16(a6)
  002fca:  66 06                bne.b    $2fd2  ; -> L2fd2
  002fcc:  20 6e ff 26          movea.l  -$da(a6), a0
  002fd0:  20 87                move.l   d7, (a0)
L2fd2:
  002fd2:  20 2e ff 26          move.l   -$da(a6), d0
  002fd6:  58 ae ff 26          addq.l   #$4, -$da(a6)
  002fda:  20 2e ff 3c          move.l   -$c4(a6), d0
  002fde:  58 ae ff 3c          addq.l   #$4, -$c4(a6)
  002fe2:  58 ae ff d2          addq.l   #$4, -$2e(a6)
L2fe6:
  002fe6:  20 2e ff d2          move.l   -$2e(a6), d0
  002fea:  b0 ae ff 34          cmp.l    -$cc(a6), d0
  002fee:  65 00 fd 22          bcs.w    $2d12  ; -> L2d12
  002ff2:  60 24                bra.b    $3018  ; -> L3018
L2ff4:
  002ff4:  59 8f                subq.l   #$4, a7
  002ff6:  2f 2e ff 2e          move.l   -$d2(a6), -(a7)
  002ffa:  61 ff 00 00 92 4e    bsr.l    $c24a  ; -> Strip24
  003000:  20 5f                movea.l  (a7)+, a0
  003002:  22 6e ff 26          movea.l  -$da(a6), a1
  003006:  20 2e ff 34          move.l   -$cc(a6), d0
  00300a:  a0 2e                dc.w     $a02e  ; _BlockMove
  00300c:  20 2e ff 34          move.l   -$cc(a6), d0
  003010:  e4 88                lsr.l    #$2, d0
  003012:  e5 80                asl.l    #$2, d0
  003014:  d1 ae ff 3c          add.l    d0, -$c4(a6)
L3018:
  003018:  41 ee ff 33          lea.l    -$cd(a6), a0
  00301c:  10 10                move.b   (a0), d0
  00301e:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  003020:  10 80                move.b   d0, (a0)
L3022:
  003022:  20 2e ff d6          move.l   -$2a(a6), d0
  003026:  52 ae ff d6          addq.l   #$1, -$2a(a6)
L302a:
  00302a:  70 00                moveq    #$0, d0
  00302c:  30 2e ff 7a          move.w   -$86(a6), d0
  003030:  b0 ae ff d6          cmp.l    -$2a(a6), d0
  003034:  62 00 f5 38          bhi.w    $256e  ; -> L256e
  003038:  30 2e ff d0          move.w   -$30(a6), d0
  00303c:  52 6e ff d0          addq.w   #$1, -$30(a6)
  003040:  70 02                moveq    #$2, d0
  003042:  b0 6e ff d0          cmp.w    -$30(a6), d0
  003046:  6c 00 f5 0a          bge.w    $2552  ; -> L2552
  00304a:  4a ae ff e6          tst.l    -$1a(a6)
  00304e:  67 06                beq.b    $3056  ; -> L3056
  003050:  20 6e ff e6          movea.l  -$1a(a6), a0
  003054:  a0 1f                dc.w     $a01f  ; _DisposePtr
L3056:
  003056:  48 7a 00 28          pea.l    $3080(pc)
  00305a:  61 ff ff ff f3 52    bsr.l    $23ae  ; -> sub_23ae
  003060:  20 2e ff f8          move.l   -$8(a6), d0
  003064:  58 4f                addq.w   #$4, a7
  003066:  60 0e                bra.b    $3076  ; -> L3076
L3068:
  003068:  4a ae ff e6          tst.l    -$1a(a6)
  00306c:  67 06                beq.b    $3074  ; -> L3074
  00306e:  20 6e ff e6          movea.l  -$1a(a6), a0
  003072:  a0 1f                dc.w     $a01f  ; _DisposePtr
L3074:
  003074:  70 00                moveq    #$0, d0
L3076:
  003076:  4c ee 18 f0 ff 06    movem.l  -$fa(a6), d4-d7/a3-a4
  00307c:  4e 5e                unlk     a6
  00307e:  4e 75                rts      
  003080:  4c                   dc.b     $4c  ; L
  003081:  6f 61                ble.b    $30e4
  003083:  64 20                bcc.b    $30a5
  003085:  43                   dc.b     $43  ; C
  003086:  6f 6d                ble.b    $30f5
  003088:  70 6c                moveq    #$6c, d0
  00308a:  65 74                bcs.b    $3100
  00308c:  65 2e                bcs.b    $30bc
  00308e:  0d 00                btst.l   d6, d0
  003090:  41 62 73 6f 6c 75 74 65 20 42 72 61 6e 63 68 20 dc.b     $41,$62,$73,$6f,$6c,$75,$74,$65,$20,$42,$72,$61,$6e,$63,$68,$20  ; Absolute Branch 
  0030a0:  54 61 72 67 65 74 20 28 30 78 25 30 38 78 29 20 dc.b     $54,$61,$72,$67,$65,$74,$20,$28,$30,$78,$25,$30,$38,$78,$29,$20  ; Target (0x%08x) 
  0030b0:  4f 75 74 20 6f 66 20 52 61 6e 67 65 20 61 74 20 dc.b     $4f,$75,$74,$20,$6f,$66,$20,$52,$61,$6e,$67,$65,$20,$61,$74,$20  ; Out of Range at 
  0030c0:  30 78 25 30 38 58 20 0d dc.b     $30,$78,$25,$30,$38,$58,$20,$0d  ; 0x%08X .
  0030c8:  00 00 52 65          ori.b    #$65, d0
  0030cc:  6c 61 74 69 76 65 20 42 72 61 6e 63 68 20 54 61 dc.b     $6c,$61,$74,$69,$76,$65,$20,$42,$72,$61,$6e,$63,$68,$20,$54,$61  ; lative Branch Ta
  0030dc:  72 67 65 74 20 28 30 78 25 30 38 78 29 20 4f 75 dc.b     $72,$67,$65,$74,$20,$28,$30,$78,$25,$30,$38,$78,$29,$20,$4f,$75  ; rget (0x%08x) Ou
  0030ec:  74 20 6f 66 20 52 61 6e 67 65 20 61 74 20 30 78 dc.b     $74,$20,$6f,$66,$20,$52,$61,$6e,$67,$65,$20,$61,$74,$20,$30,$78  ; t of Range at 0x
  0030fc:  25 30 38 58 20 0d    dc.b     $25,$30,$38,$58,$20,$0d  ; %08X .
  003102:  00 00 73 65          ori.b    #$65, d0
  003106:  65 6b 20 70 61 73 74 20 65 6e 64 20 6f 66 20 66 dc.b     $65,$6b,$20,$70,$61,$73,$74,$20,$65,$6e,$64,$20,$6f,$66,$20,$66  ; ek past end of f
  003116:  69 6c 65 20 69 6e 20 41 43 45 46 6c 6f 61 64 3a dc.b     $69,$6c,$65,$20,$69,$6e,$20,$41,$43,$45,$46,$6c,$6f,$61,$64,$3a  ; ile in ACEFload:
  003126:  20 25 64 0d          dc.b     $20,$25,$64,$0d  ;  %d.
  00312a:  00 00 4d 75          ori.b    #$75, d0
  00312e:  6c 74 69 70 6c 65 20 2e 42 53 53 20 73 65 63 74 dc.b     $6c,$74,$69,$70,$6c,$65,$20,$2e,$42,$53,$53,$20,$73,$65,$63,$74  ; ltiple .BSS sect
  00313e:  69 6f 6e 73 20 6e 6f 74 20 61 6c 6c 6f 77 65 64 dc.b     $69,$6f,$6e,$73,$20,$6e,$6f,$74,$20,$61,$6c,$6c,$6f,$77,$65,$64  ; ions not allowed
  00314e:  20 69 6e 20 72 65 6c 6f 63 61 74 61 62 6c 65 20 dc.b     $20,$69,$6e,$20,$72,$65,$6c,$6f,$63,$61,$74,$61,$62,$6c,$65,$20  ;  in relocatable 
  00315e:  66 69 6c 65 00 00 53 65 63 74 69 6f 6e 20 25 38 dc.b     $66,$69,$6c,$65,$00,$00,$53,$65,$63,$74,$69,$6f,$6e,$20,$25,$38  ; file..Section %8
  00316e:  73 3a 20 28 30 78 25 30 38 78 29 20 25 64 20 41 dc.b     $73,$3a,$20,$28,$30,$78,$25,$30,$38,$78,$29,$20,$25,$64,$20,$41  ; s: (0x%08x) %d A
  00317e:  64 64 72 65 73 73 3a 20 25 58 20 73 69 7a 65 3a dc.b     $64,$64,$72,$65,$73,$73,$3a,$20,$25,$58,$20,$73,$69,$7a,$65,$3a  ; ddress: %X size:
  00318e:  20 25 64 20 25 73 20 61 74 20 30 78 25 30 38 58 dc.b     $20,$25,$64,$20,$25,$73,$20,$61,$74,$20,$30,$78,$25,$30,$38,$58  ;  %d %s at 0x%08X
  00319e:  0d 00                btst.l   d6, d0
  0031a0:  6c 6f 61 64 65 64 00 00 7a 65 72 6f 65 64 00 00 dc.b     $6c,$6f,$61,$64,$65,$64,$00,$00,$7a,$65,$72,$6f,$65,$64,$00,$00  ; loaded..zeroed..
  0031b0:  53 6b 69 70 70 69 6e 67 20 53 65 63 74 69 6f 6e dc.b     $53,$6b,$69,$70,$70,$69,$6e,$67,$20,$53,$65,$63,$74,$69,$6f,$6e  ; Skipping Section
  0031c0:  20 25 38 73 3a 20 28 30 78 25 30 38 78 29 20 25 dc.b     $20,$25,$38,$73,$3a,$20,$28,$30,$78,$25,$30,$38,$78,$29,$20,$25  ;  %8s: (0x%08x) %
  0031d0:  64 20 41 64 64 72 65 73 73 3a 20 25 58 20 73 69 dc.b     $64,$20,$41,$64,$64,$72,$65,$73,$73,$3a,$20,$25,$58,$20,$73,$69  ; d Address: %X si
  0031e0:  7a 65 3a 20 25 64    dc.b     $7a,$65,$3a,$20,$25,$64  ; ze: %d
  0031e6:  0d 00                btst.l   d6, d0
  0031e8:  70 61 73 73 20 25 64 3a 20 73 63 6e 5f 70 74 72 dc.b     $70,$61,$73,$73,$20,$25,$64,$3a,$20,$73,$63,$6e,$5f,$70,$74,$72  ; pass %d: scn_ptr
  0031f8:  20 3d 20 25 30 38 78 2c 72 65 6c 5f 70 74 72 20 dc.b     $20,$3d,$20,$25,$30,$38,$78,$2c,$72,$65,$6c,$5f,$70,$74,$72,$20  ;  = %08x,rel_ptr 
  003208:  3d 20 25 30 38 78    dc.b     $3d,$20,$25,$30,$38,$78  ; = %08x
  00320e:  0d 00                btst.l   d6, d0
  003210:  4c 6f 61 64 69 6e 67 20 25 64 20 73 65 63 74 69 dc.b     $4c,$6f,$61,$64,$69,$6e,$67,$20,$25,$64,$20,$73,$65,$63,$74,$69  ; Loading %d secti
  003220:  6f 6e 73 2e          dc.b     $6f,$6e,$73,$2e  ; ons.
  003224:  0d 00                btst.l   d6, d0
  003226:  4e 6f 20 4d 65 6d 6f 72 79 20 66 6f 72 20 73 79 dc.b     $4e,$6f,$20,$4d,$65,$6d,$6f,$72,$79,$20,$66,$6f,$72,$20,$73,$79  ; No Memory for sy
  003236:  6d 62 6f 6c 20 74 61 62 6c 65 00 00 4c 6f 61 64 dc.b     $6d,$62,$6f,$6c,$20,$74,$61,$62,$6c,$65,$00,$00,$4c,$6f,$61,$64  ; mbol table..Load
  003246:  20 61 74 20 25 30 38 58 2c 20 4d 61 67 69 63 3a dc.b     $20,$61,$74,$20,$25,$30,$38,$58,$2c,$20,$4d,$61,$67,$69,$63,$3a  ;  at %08X, Magic:
  003256:  20 30 78 25 30 38 78 20 53 65 63 74 69 6f 6e 73 dc.b     $20,$30,$78,$25,$30,$38,$78,$20,$53,$65,$63,$74,$69,$6f,$6e,$73  ;  0x%08x Sections
  003266:  3a 20 25 64 20 53 79 6d 62 6f 6c 73 3a 20 25 64 dc.b     $3a,$20,$25,$64,$20,$53,$79,$6d,$62,$6f,$6c,$73,$3a,$20,$25,$64  ; : %d Symbols: %d
  003276:  20 46 6c 61 67 73 3a 20 25 30 78 0d dc.b     $20,$46,$6c,$61,$67,$73,$3a,$20,$25,$30,$78,$0d  ;  Flags: %0x.
  003282:  00 00 50 72          ori.b    #$72, d0
  003286:  6f 67 72 61 6d 20 27 25 73 27 20 76 65 72 73 69 dc.b     $6f,$67,$72,$61,$6d,$20,$27,$25,$73,$27,$20,$76,$65,$72,$73,$69  ; ogram '%s' versi
  003296:  6f 6e 20 25 30 38 78 20 64 61 74 65 20 25 64 0d dc.b     $6f,$6e,$20,$25,$30,$38,$78,$20,$64,$61,$74,$65,$20,$25,$64,$0d  ; on %08x date %d.
  0032a6:  00 00 4e 6f          ori.b    #$6f, d0
  0032aa:  74 20 69 6e 20 41 43 45 46 20 66 6f 72 6d 61 74 dc.b     $74,$20,$69,$6e,$20,$41,$43,$45,$46,$20,$66,$6f,$72,$6d,$61,$74  ; t in ACEF format
  0032ba:  21 00                dc.b     $21,$00  ; !.
handler_06:
  0032bc:  4e 56 ff d4          link.w   a6, #$ffd4
  0032c0:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  0032c4:  38 2e 00 08          move.w   $8(a6), d4
  0032c8:  3a 2e 00 1a          move.w   $1a(a6), d5
  0032cc:  42 ae ff e4          clr.l    -$1c(a6)
  0032d0:  42 ae ff e0          clr.l    -$20(a6)
  0032d4:  59 8f                subq.l   #$4, a7
  0032d6:  2f 38 08 88          move.l   $888.w, -(a7)
  0032da:  61 ff 00 00 8f 6e    bsr.l    $c24a  ; -> Strip24
  0032e0:  20 5f                movea.l  (a7)+, a0
  0032e2:  20 50                movea.l  (a0), a0
  0032e4:  2d 50 ff fc          move.l   (a0), -$4(a6)
  0032e8:  59 8f                subq.l   #$4, a7
  0032ea:  2f 38 08 88          move.l   $888.w, -(a7)
  0032ee:  61 ff 00 00 8f 5a    bsr.l    $c24a  ; -> Strip24
  0032f4:  20 5f                movea.l  (a7)+, a0
  0032f6:  20 50                movea.l  (a0), a0
  0032f8:  20 50                movea.l  (a0), a0
  0032fa:  28 68 02 14          movea.l  $214(a0), a4
  0032fe:  20 0c                move.l   a4, d0
  003300:  67 00 01 86          beq.w    $3488  ; -> L3488
  003304:  4a ae 00 16          tst.l    $16(a6)
  003308:  66 00 01 7e          bne.w    $3488  ; -> L3488
  00330c:  20 54                movea.l  (a4), a0
  00330e:  2d 68 00 08 ff dc    move.l   $8(a0), -$24(a6)
  003314:  70 27                moveq    #$27, d0
  003316:  c0 a8 00 08          and.l    $8(a0), d0
  00331a:  72 27                moveq    #$27, d1
  00331c:  b2 80                cmp.l    d0, d1
  00331e:  66 00 01 68          bne.w    $3488  ; -> L3488
  003322:  20 3c 00 00 06 00    move.l   #$600, d0
  003328:  c0 ae ff dc          and.l    -$24(a6), d0
  00332c:  66 00 01 5a          bne.w    $3488  ; -> L3488
  003330:  20 54                movea.l  (a4), a0
  003332:  20 68 00 0c          movea.l  $c(a0), a0
  003336:  41 e8 00 58          lea.l    $58(a0), a0
  00333a:  2d 48 ff d8          move.l   a0, -$28(a6)
  00333e:  30 04                move.w   d4, d0
  003340:  e0 40                asr.w    #$8, d0
  003342:  20 6e ff fc          movea.l  -$4(a6), a0
  003346:  72 00                moveq    #$0, d1
  003348:  12 28 02 56          move.b   $256(a0), d1
  00334c:  82 40                or.w     d0, d1
  00334e:  2f 01                move.l   d1, -(a7)
  003350:  2f 2e 00 0a          move.l   $a(a6), -(a7)
  003354:  2f 2e 00 0e          move.l   $e(a6), -(a7)
  003358:  2f 2e 00 12          move.l   $12(a6), -(a7)
  00335c:  48 c5                ext.l    d5
  00335e:  2f 05                move.l   d5, -(a7)
  003360:  2f 2e 00 1c          move.l   $1c(a6), -(a7)
  003364:  2f 2e 00 20          move.l   $20(a6), -(a7)
  003368:  2f 2e 00 24          move.l   $24(a6), -(a7)
  00336c:  2f 2e 00 28          move.l   $28(a6), -(a7)
  003370:  2f 2e 00 2c          move.l   $2c(a6), -(a7)
  003374:  2f 2e 00 30          move.l   $30(a6), -(a7)
  003378:  2f 2e ff d8          move.l   -$28(a6), -(a7)
  00337c:  61 ff 00 00 4e e4    bsr.l    $8262  ; -> sub_8262
  003382:  2d 6e ff d8 ff d4    move.l   -$28(a6), -$2c(a6)
  003388:  70 01                moveq    #$1, d0
  00338a:  2f 00                move.l   d0, -(a7)
  00338c:  48 6e ff d4          pea.l    -$2c(a6)
  003390:  72 15                moveq    #$15, d1
  003392:  2f 01                move.l   d1, -(a7)
  003394:  61 ff 00 00 16 2e    bsr.l    $49c4  ; -> EngineDispatch
  00339a:  72 01                moveq    #$1, d1
  00339c:  b2 80                cmp.l    d0, d1
  00339e:  4f ef 00 3c          lea.l    $3c(a7), a7
  0033a2:  66 0a                bne.b    $33ae  ; -> L33ae
  0033a4:  00 38 00 80 09 38    ori.b    #$80, $938.w
  0033aa:  60 00 01 d4          bra.w    $3580  ; -> L3580
L33ae:
  0033ae:  59 8f                subq.l   #$4, a7
  0033b0:  2f 38 08 88          move.l   $888.w, -(a7)
  0033b4:  61 ff 00 00 8e 94    bsr.l    $c24a  ; -> Strip24
  0033ba:  26 5f                movea.l  (a7)+, a3
  0033bc:  4a ab 00 18          tst.l    $18(a3)
  0033c0:  67 00 00 c6          beq.w    $3488  ; -> L3488
  0033c4:  4a ab 00 40          tst.l    $40(a3)
  0033c8:  6f 00 00 88          ble.w    $3452  ; -> L3452
  0033cc:  20 6b 00 1c          movea.l  $1c(a3), a0
  0033d0:  4a 50                tst.w    (a0)
  0033d2:  66 12                bne.b    $33e6  ; -> L33e6
  0033d4:  4a 68 00 02          tst.w    $2(a0)
  0033d8:  66 0c                bne.b    $33e6  ; -> L33e6
  0033da:  4a 68 00 04          tst.w    $4(a0)
  0033de:  66 06                bne.b    $33e6  ; -> L33e6
  0033e0:  4a 68 00 06          tst.w    $6(a0)
  0033e4:  67 6c                beq.b    $3452  ; -> L3452
L33e6:
  0033e6:  20 6b 00 08          movea.l  $8(a3), a0
  0033ea:  2e 10                move.l   (a0), d7
L33ec:
  0033ec:  20 6b 00 0c          movea.l  $c(a3), a0
  0033f0:  4a 90                tst.l    (a0)
  0033f2:  66 f8                bne.b    $33ec  ; -> L33ec
  0033f4:  20 6b 00 08          movea.l  $8(a3), a0
  0033f8:  20 bc 00 00 08 08    move.l   #$808, (a0)
  0033fe:  20 6b 00 0c          movea.l  $c(a3), a0
  003402:  4a 90                tst.l    (a0)
  003404:  67 08                beq.b    $340e  ; -> L340e
  003406:  20 6b 00 08          movea.l  $8(a3), a0
  00340a:  20 87                move.l   d7, (a0)
  00340c:  60 de                bra.b    $33ec  ; -> L33ec
L340e:
  00340e:  20 6b 00 30          movea.l  $30(a3), a0
  003412:  4a 90                tst.l    (a0)
  003414:  67 0c                beq.b    $3422  ; -> L3422
  003416:  42 38 08 cc          clr.b    $8cc.w
  00341a:  20 6b 00 30          movea.l  $30(a3), a0
  00341e:  70 00                moveq    #$0, d0
  003420:  20 80                move.l   d0, (a0)
L3422:
  003422:  20 6b 00 1c          movea.l  $1c(a3), a0
  003426:  3f 28 00 02          move.w   $2(a0), -(a7)
  00342a:  3f 10                move.w   (a0), -(a7)
  00342c:  3f 28 00 06          move.w   $6(a0), -(a7)
  003430:  3f 28 00 04          move.w   $4(a0), -(a7)
  003434:  48 78 08 08          pea.l    $808.w
  003438:  61 ff 00 00 39 58    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00343e:  58 8f                addq.l   #$4, a7
  003440:  2f 00                move.l   d0, -(a7)
  003442:  20 5f                movea.l  (a7)+, a0
  003444:  4e 90                jsr      (a0)
  003446:  61 ff 00 00 8b ec    bsr.l    $c034  ; -> sub_c034
  00344c:  20 6b 00 08          movea.l  $8(a3), a0
  003450:  20 87                move.l   d7, (a0)
L3452:
  003452:  70 00                moveq    #$0, d0
  003454:  27 40 00 40          move.l   d0, $40(a3)
  003458:  60 16                bra.b    $3470  ; -> L3470
L345a:
  00345a:  48 78 08 04          pea.l    $804.w
  00345e:  61 ff 00 00 39 32    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003464:  58 8f                addq.l   #$4, a7
  003466:  2f 00                move.l   d0, -(a7)
  003468:  20 5f                movea.l  (a7)+, a0
  00346a:  4e 90                jsr      (a0)
  00346c:  52 ab 00 44          addq.l   #$1, $44(a3)
L3470:
  003470:  4a ab 00 44          tst.l    $44(a3)
  003474:  6d e4                blt.b    $345a  ; -> L345a
  003476:  20 6b 00 1c          movea.l  $1c(a3), a0
  00347a:  43 ee ff e0          lea.l    -$20(a6), a1
  00347e:  20 d9                move.l   (a1)+, (a0)+
  003480:  20 d9                move.l   (a1)+, (a0)+
  003482:  70 00                moveq    #$0, d0
  003484:  27 40 00 18          move.l   d0, $18(a3)
L3488:
  003488:  2f 0c                move.l   a4, -(a7)
  00348a:  61 ff 00 00 2f 24    bsr.l    $63b0  ; -> sub_63b0
  003490:  4a ae 00 2c          tst.l    $2c(a6)
  003494:  58 4f                addq.w   #$4, a7
  003496:  67 1a                beq.b    $34b2  ; -> L34b2
  003498:  48 6e ff fa          pea.l    -$6(a6)
  00349c:  48 6e ff f2          pea.l    -$e(a6)
  0034a0:  2f 2e 00 2c          move.l   $2c(a6), -(a7)
  0034a4:  61 ff 00 00 52 30    bsr.l    $86d6  ; -> sub_86d6
  0034aa:  1c 00                move.b   d0, d6
  0034ac:  4f ef 00 0c          lea.l    $c(a7), a7
  0034b0:  60 02                bra.b    $34b4  ; -> L34b4
L34b2:
  0034b2:  42 06                clr.b    d6
L34b4:
  0034b4:  48 6e ff f6          pea.l    -$a(a6)
  0034b8:  48 6e ff ea          pea.l    -$16(a6)
  0034bc:  2f 2e 00 30          move.l   $30(a6), -(a7)
  0034c0:  61 ff 00 00 52 14    bsr.l    $86d6  ; -> sub_86d6
  0034c6:  1d 40 ff e8          move.b   d0, -$18(a6)
  0034ca:  48 6e ff f8          pea.l    -$8(a6)
  0034ce:  48 6e ff ee          pea.l    -$12(a6)
  0034d2:  2f 2e 00 28          move.l   $28(a6), -(a7)
  0034d6:  61 ff 00 00 51 fe    bsr.l    $86d6  ; -> sub_86d6
  0034dc:  1d 40 ff e9          move.b   d0, -$17(a6)
  0034e0:  2f 2e 00 30          move.l   $30(a6), -(a7)
  0034e4:  2f 2e 00 2c          move.l   $2c(a6), -(a7)
  0034e8:  2f 2e 00 28          move.l   $28(a6), -(a7)
  0034ec:  2f 2e 00 24          move.l   $24(a6), -(a7)
  0034f0:  2f 2e 00 20          move.l   $20(a6), -(a7)
  0034f4:  2f 2e 00 1c          move.l   $1c(a6), -(a7)
  0034f8:  3f 05                move.w   d5, -(a7)
  0034fa:  2f 2e 00 16          move.l   $16(a6), -(a7)
  0034fe:  2f 2e 00 12          move.l   $12(a6), -(a7)
  003502:  2f 2e 00 0e          move.l   $e(a6), -(a7)
  003506:  2f 2e 00 0a          move.l   $a(a6), -(a7)
  00350a:  3f 04                move.w   d4, -(a7)
  00350c:  48 78 1a 9c          pea.l    $1a9c.w
  003510:  61 ff 00 00 38 80    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003516:  58 8f                addq.l   #$4, a7
  003518:  2f 00                move.l   d0, -(a7)
  00351a:  20 5f                movea.l  (a7)+, a0
  00351c:  4e 90                jsr      (a0)
  00351e:  4a 2e ff e8          tst.b    -$18(a6)
  003522:  4f ef 00 18          lea.l    $18(a7), a7
  003526:  67 1a                beq.b    $3542  ; -> L3542
  003528:  30 2e ff f6          move.w   -$a(a6), d0
  00352c:  48 c0                ext.l    d0
  00352e:  2f 00                move.l   d0, -(a7)
  003530:  2f 2e ff ea          move.l   -$16(a6), -(a7)
  003534:  2f 2e 00 30          move.l   $30(a6), -(a7)
  003538:  61 ff 00 00 52 60    bsr.l    $879a  ; -> sub_879a
  00353e:  4f ef 00 0c          lea.l    $c(a7), a7
L3542:
  003542:  4a 06                tst.b    d6
  003544:  67 1a                beq.b    $3560  ; -> L3560
  003546:  30 2e ff fa          move.w   -$6(a6), d0
  00354a:  48 c0                ext.l    d0
  00354c:  2f 00                move.l   d0, -(a7)
  00354e:  2f 2e ff f2          move.l   -$e(a6), -(a7)
  003552:  2f 2e 00 2c          move.l   $2c(a6), -(a7)
  003556:  61 ff 00 00 52 42    bsr.l    $879a  ; -> sub_879a
  00355c:  4f ef 00 0c          lea.l    $c(a7), a7
L3560:
  003560:  4a 2e ff e9          tst.b    -$17(a6)
  003564:  67 1a                beq.b    $3580  ; -> L3580
  003566:  30 2e ff f8          move.w   -$8(a6), d0
  00356a:  48 c0                ext.l    d0
  00356c:  2f 00                move.l   d0, -(a7)
  00356e:  2f 2e ff ee          move.l   -$12(a6), -(a7)
  003572:  2f 2e 00 28          move.l   $28(a6), -(a7)
  003576:  61 ff 00 00 52 22    bsr.l    $879a  ; -> sub_879a
  00357c:  4f ef 00 0c          lea.l    $c(a7), a7
L3580:
  003580:  4c ee 18 f0 ff bc    movem.l  -$44(a6), d4-d7/a3-a4
  003586:  4e 5e                unlk     a6
  003588:  4e 74 00 2c          rtd      #$2c
handler_24:
  00358c:  4e 56 ff f2          link.w   a6, #$fff2
  003590:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  003594:  26 6e 00 08          movea.l  $8(a6), a3
  003598:  1e 2e 00 0c          move.b   $c(a6), d7
  00359c:  61 ff 00 00 4a 72    bsr.l    $8010  ; -> GetA5
  0035a2:  20 40                movea.l  d0, a0
  0035a4:  20 50                movea.l  (a0), a0
  0035a6:  28 50                movea.l  (a0), a4
  0035a8:  42 06                clr.b    d6
  0035aa:  3a 2c 00 42          move.w   $42(a4), d5
  0035ae:  6d 00 00 a4          blt.w    $3654  ; -> L3654
  0035b2:  70 00                moveq    #$0, d0
  0035b4:  10 07                move.b   d7, d0
  0035b6:  2d 40 ff f2          move.l   d0, -$e(a6)
  0035ba:  2d 4b ff f6          move.l   a3, -$a(a6)
  0035be:  70 02                moveq    #$2, d0
  0035c0:  2f 00                move.l   d0, -(a7)
  0035c2:  48 6e ff f2          pea.l    -$e(a6)
  0035c6:  72 18                moveq    #$18, d1
  0035c8:  2f 01                move.l   d1, -(a7)
  0035ca:  61 ff 00 00 13 f8    bsr.l    $49c4  ; -> EngineDispatch
  0035d0:  28 00                move.l   d0, d4
  0035d2:  70 01                moveq    #$1, d0
  0035d4:  b0 84                cmp.l    d4, d0
  0035d6:  4f ef 00 0c          lea.l    $c(a7), a7
  0035da:  67 00 00 9a          beq.w    $3676  ; -> L3676
  0035de:  48 6e ff fe          pea.l    -$2(a6)
  0035e2:  48 6e ff fa          pea.l    -$6(a6)
  0035e6:  48 6c 00 02          pea.l    $2(a4)
  0035ea:  61 ff 00 00 50 ea    bsr.l    $86d6  ; -> sub_86d6
  0035f0:  1c 00                move.b   d0, d6
  0035f2:  70 02                moveq    #$2, d0
  0035f4:  b0 84                cmp.l    d4, d0
  0035f6:  4f ef 00 0c          lea.l    $c(a7), a7
  0035fa:  66 22                bne.b    $361e  ; -> L361e
  0035fc:  39 7c ff ff 00 42    move.w   #$ffff, $42(a4)
  003602:  1f 07                move.b   d7, -(a7)
  003604:  2f 0b                move.l   a3, -(a7)
  003606:  48 78 11 44          pea.l    $1144.w
  00360a:  61 ff 00 00 37 86    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003610:  58 8f                addq.l   #$4, a7
  003612:  2f 00                move.l   d0, -(a7)
  003614:  20 5f                movea.l  (a7)+, a0
  003616:  4e 90                jsr      (a0)
  003618:  39 45 00 42          move.w   d5, $42(a4)
  00361c:  60 16                bra.b    $3634  ; -> L3634
L361e:
  00361e:  1f 07                move.b   d7, -(a7)
  003620:  2f 0b                move.l   a3, -(a7)
  003622:  48 78 11 44          pea.l    $1144.w
  003626:  61 ff 00 00 37 6a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00362c:  58 8f                addq.l   #$4, a7
  00362e:  2f 00                move.l   d0, -(a7)
  003630:  20 5f                movea.l  (a7)+, a0
  003632:  4e 90                jsr      (a0)
L3634:
  003634:  4a 06                tst.b    d6
  003636:  67 3e                beq.b    $3676  ; -> L3676
  003638:  30 2e ff fe          move.w   -$2(a6), d0
  00363c:  48 c0                ext.l    d0
  00363e:  2f 00                move.l   d0, -(a7)
  003640:  2f 2e ff fa          move.l   -$6(a6), -(a7)
  003644:  48 6c 00 02          pea.l    $2(a4)
  003648:  61 ff 00 00 51 50    bsr.l    $879a  ; -> sub_879a
  00364e:  4f ef 00 0c          lea.l    $c(a7), a7
  003652:  60 22                bra.b    $3676  ; -> L3676
L3654:
  003654:  70 08                moveq    #$8, d0
  003656:  2f 00                move.l   d0, -(a7)
  003658:  61 ff 00 00 11 c8    bsr.l    $4822  ; -> sub_4822
  00365e:  1f 07                move.b   d7, -(a7)
  003660:  2f 0b                move.l   a3, -(a7)
  003662:  48 78 11 44          pea.l    $1144.w
  003666:  61 ff 00 00 37 2a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00366c:  58 8f                addq.l   #$4, a7
  00366e:  2f 00                move.l   d0, -(a7)
  003670:  20 5f                movea.l  (a7)+, a0
  003672:  4e 90                jsr      (a0)
  003674:  58 4f                addq.w   #$4, a7
L3676:
  003676:  4c ee 18 f0 ff da    movem.l  -$26(a6), d4-d7/a3-a4
  00367c:  4e 5e                unlk     a6
  00367e:  4e 74 00 06          rtd      #$6
handler_03:
  003682:  4e 56 ff f6          link.w   a6, #$fff6
  003686:  48 e7 07 08          movem.l  d5-d7/a4, -(a7)
  00368a:  61 ff 00 00 49 84    bsr.l    $8010  ; -> GetA5
  003690:  20 40                movea.l  d0, a0
  003692:  20 50                movea.l  (a0), a0
  003694:  28 50                movea.l  (a0), a4
  003696:  42 07                clr.b    d7
  003698:  3c 2c 00 42          move.w   $42(a4), d6
  00369c:  6d 00 00 a0          blt.w    $373e  ; -> L373e
  0036a0:  41 ee 00 08          lea.l    $8(a6), a0
  0036a4:  2d 48 ff f6          move.l   a0, -$a(a6)
  0036a8:  70 01                moveq    #$1, d0
  0036aa:  2f 00                move.l   d0, -(a7)
  0036ac:  48 6e ff f6          pea.l    -$a(a6)
  0036b0:  72 20                moveq    #$20, d1
  0036b2:  2f 01                move.l   d1, -(a7)
  0036b4:  61 ff 00 00 13 0e    bsr.l    $49c4  ; -> EngineDispatch
  0036ba:  2a 00                move.l   d0, d5
  0036bc:  70 01                moveq    #$1, d0
  0036be:  b0 85                cmp.l    d5, d0
  0036c0:  4f ef 00 0c          lea.l    $c(a7), a7
  0036c4:  67 00 00 9a          beq.w    $3760  ; -> L3760
  0036c8:  48 6e ff fe          pea.l    -$2(a6)
  0036cc:  48 6e ff fa          pea.l    -$6(a6)
  0036d0:  48 6c 00 02          pea.l    $2(a4)
  0036d4:  61 ff 00 00 50 00    bsr.l    $86d6  ; -> sub_86d6
  0036da:  1e 00                move.b   d0, d7
  0036dc:  70 02                moveq    #$2, d0
  0036de:  b0 85                cmp.l    d5, d0
  0036e0:  4f ef 00 0c          lea.l    $c(a7), a7
  0036e4:  66 22                bne.b    $3708  ; -> L3708
  0036e6:  39 7c ff ff 00 42    move.w   #$ffff, $42(a4)
  0036ec:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0036f0:  48 78 10 40          pea.l    $1040.w
  0036f4:  61 ff 00 00 36 9c    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0036fa:  58 8f                addq.l   #$4, a7
  0036fc:  2f 00                move.l   d0, -(a7)
  0036fe:  20 5f                movea.l  (a7)+, a0
  003700:  4e 90                jsr      (a0)
  003702:  39 46 00 42          move.w   d6, $42(a4)
  003706:  60 16                bra.b    $371e  ; -> L371e
L3708:
  003708:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00370c:  48 78 10 40          pea.l    $1040.w
  003710:  61 ff 00 00 36 80    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003716:  58 8f                addq.l   #$4, a7
  003718:  2f 00                move.l   d0, -(a7)
  00371a:  20 5f                movea.l  (a7)+, a0
  00371c:  4e 90                jsr      (a0)
L371e:
  00371e:  4a 07                tst.b    d7
  003720:  67 3e                beq.b    $3760  ; -> L3760
  003722:  30 2e ff fe          move.w   -$2(a6), d0
  003726:  48 c0                ext.l    d0
  003728:  2f 00                move.l   d0, -(a7)
  00372a:  2f 2e ff fa          move.l   -$6(a6), -(a7)
  00372e:  48 6c 00 02          pea.l    $2(a4)
  003732:  61 ff 00 00 50 66    bsr.l    $879a  ; -> sub_879a
  003738:  4f ef 00 0c          lea.l    $c(a7), a7
  00373c:  60 22                bra.b    $3760  ; -> L3760
L373e:
  00373e:  70 08                moveq    #$8, d0
  003740:  2f 00                move.l   d0, -(a7)
  003742:  61 ff 00 00 10 de    bsr.l    $4822  ; -> sub_4822
  003748:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00374c:  48 78 10 40          pea.l    $1040.w
  003750:  61 ff 00 00 36 40    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003756:  58 8f                addq.l   #$4, a7
  003758:  2f 00                move.l   d0, -(a7)
  00375a:  20 5f                movea.l  (a7)+, a0
  00375c:  4e 90                jsr      (a0)
  00375e:  58 4f                addq.w   #$4, a7
L3760:
  003760:  4c ee 10 e0 ff e6    movem.l  -$1a(a6), d5-d7/a4
  003766:  4e 5e                unlk     a6
  003768:  4e 74 00 04          rtd      #$4
handler_23:
  00376c:  4e 56 ff f2          link.w   a6, #$fff2
  003770:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  003774:  26 6e 00 08          movea.l  $8(a6), a3
  003778:  1e 2e 00 0c          move.b   $c(a6), d7
  00377c:  61 ff 00 00 48 92    bsr.l    $8010  ; -> GetA5
  003782:  20 40                movea.l  d0, a0
  003784:  20 50                movea.l  (a0), a0
  003786:  28 50                movea.l  (a0), a4
  003788:  42 05                clr.b    d5
  00378a:  3c 2c 00 42          move.w   $42(a4), d6
  00378e:  6d 00 00 aa          blt.w    $383a  ; -> L383a
  003792:  70 00                moveq    #$0, d0
  003794:  10 07                move.b   d7, d0
  003796:  2d 40 ff f2          move.l   d0, -$e(a6)
  00379a:  2d 4b ff f6          move.l   a3, -$a(a6)
  00379e:  70 02                moveq    #$2, d0
  0037a0:  2f 00                move.l   d0, -(a7)
  0037a2:  48 6e ff f2          pea.l    -$e(a6)
  0037a6:  72 31                moveq    #$31, d1
  0037a8:  2f 01                move.l   d1, -(a7)
  0037aa:  61 ff 00 00 12 18    bsr.l    $49c4  ; -> EngineDispatch
  0037b0:  28 00                move.l   d0, d4
  0037b2:  70 01                moveq    #$1, d0
  0037b4:  b0 84                cmp.l    d4, d0
  0037b6:  4f ef 00 0c          lea.l    $c(a7), a7
  0037ba:  67 00 00 a0          beq.w    $385c  ; -> L385c
  0037be:  3c 2c 00 42          move.w   $42(a4), d6
  0037c2:  6d 18                blt.b    $37dc  ; -> L37dc
  0037c4:  48 6e ff fe          pea.l    -$2(a6)
  0037c8:  48 6e ff fa          pea.l    -$6(a6)
  0037cc:  48 6c 00 02          pea.l    $2(a4)
  0037d0:  61 ff 00 00 4f 04    bsr.l    $86d6  ; -> sub_86d6
  0037d6:  1a 00                move.b   d0, d5
  0037d8:  4f ef 00 0c          lea.l    $c(a7), a7
L37dc:
  0037dc:  70 02                moveq    #$2, d0
  0037de:  b0 84                cmp.l    d4, d0
  0037e0:  66 22                bne.b    $3804  ; -> L3804
  0037e2:  39 7c ff ff 00 42    move.w   #$ffff, $42(a4)
  0037e8:  1f 07                move.b   d7, -(a7)
  0037ea:  2f 0b                move.l   a3, -(a7)
  0037ec:  48 78 11 14          pea.l    $1114.w
  0037f0:  61 ff 00 00 35 a0    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0037f6:  58 8f                addq.l   #$4, a7
  0037f8:  2f 00                move.l   d0, -(a7)
  0037fa:  20 5f                movea.l  (a7)+, a0
  0037fc:  4e 90                jsr      (a0)
  0037fe:  39 46 00 42          move.w   d6, $42(a4)
  003802:  60 16                bra.b    $381a  ; -> L381a
L3804:
  003804:  1f 07                move.b   d7, -(a7)
  003806:  2f 0b                move.l   a3, -(a7)
  003808:  48 78 11 14          pea.l    $1114.w
  00380c:  61 ff 00 00 35 84    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003812:  58 8f                addq.l   #$4, a7
  003814:  2f 00                move.l   d0, -(a7)
  003816:  20 5f                movea.l  (a7)+, a0
  003818:  4e 90                jsr      (a0)
L381a:
  00381a:  4a 05                tst.b    d5
  00381c:  67 3e                beq.b    $385c  ; -> L385c
  00381e:  30 2e ff fe          move.w   -$2(a6), d0
  003822:  48 c0                ext.l    d0
  003824:  2f 00                move.l   d0, -(a7)
  003826:  2f 2e ff fa          move.l   -$6(a6), -(a7)
  00382a:  48 6c 00 02          pea.l    $2(a4)
  00382e:  61 ff 00 00 4f 6a    bsr.l    $879a  ; -> sub_879a
  003834:  4f ef 00 0c          lea.l    $c(a7), a7
  003838:  60 22                bra.b    $385c  ; -> L385c
L383a:
  00383a:  70 08                moveq    #$8, d0
  00383c:  2f 00                move.l   d0, -(a7)
  00383e:  61 ff 00 00 0f e2    bsr.l    $4822  ; -> sub_4822
  003844:  1f 07                move.b   d7, -(a7)
  003846:  2f 0b                move.l   a3, -(a7)
  003848:  48 78 11 14          pea.l    $1114.w
  00384c:  61 ff 00 00 35 44    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003852:  58 8f                addq.l   #$4, a7
  003854:  2f 00                move.l   d0, -(a7)
  003856:  20 5f                movea.l  (a7)+, a0
  003858:  4e 90                jsr      (a0)
  00385a:  58 4f                addq.w   #$4, a7
L385c:
  00385c:  4c ee 18 f0 ff da    movem.l  -$26(a6), d4-d7/a3-a4
  003862:  4e 5e                unlk     a6
  003864:  4e 74 00 06          rtd      #$6
  003868:  4e 56 ff e0          link.w   a6, #$ffe0
  00386c:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  003870:  49 ee ff ec          lea.l    -$14(a6), a4
  003874:  26 6e 00 08          movea.l  $8(a6), a3
  003878:  20 6b 00 16          movea.l  $16(a3), a0
  00387c:  2d 48 ff fc          move.l   a0, -$4(a6)
  003880:  43 ee ff e0          lea.l    -$20(a6), a1
  003884:  41 e8 00 24          lea.l    $24(a0), a0
  003888:  22 d8                move.l   (a0)+, (a1)+
  00388a:  32 d8                move.w   (a0)+, (a1)+
  00388c:  20 6e ff fc          movea.l  -$4(a6), a0
  003890:  43 ee ff e6          lea.l    -$1a(a6), a1
  003894:  41 e8 00 2a          lea.l    $2a(a0), a0
  003898:  22 d8                move.l   (a0)+, (a1)+
  00389a:  32 d8                move.w   (a0)+, (a1)+
  00389c:  55 8f                subq.l   #$2, a7
  00389e:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  0038a2:  48 6e ff e6          pea.l    -$1a(a6)
  0038a6:  48 6e ff e0          pea.l    -$20(a6)
  0038aa:  30 3c 12 19          move.w   #$1219, d0
  0038ae:  aa a2                dc.w     $aaa2  ; _PaletteDispatch
  0038b0:  7e 00                moveq    #$0, d7
  0038b2:  1e 1f                move.b   (a7)+, d7
  0038b4:  4a 87                tst.l    d7
  0038b6:  67 00 00 de          beq.w    $3996
  0038ba:  48 6e ff e0          pea.l    -$20(a6)
  0038be:  aa 14                dc.w     $aa14  ; _RGBForeColor
  0038c0:  30 13                move.w   (a3), d0
  0038c2:  48 c0                ext.l    d0
  0038c4:  28 c0                move.l   d0, (a4)+
  0038c6:  28 eb 00 02          move.l   $2(a3), (a4)+
  0038ca:  20 4b                movea.l  a3, a0
  0038cc:  5c 88                addq.l   #$6, a0
  0038ce:  28 c8                move.l   a0, (a4)+
  0038d0:  41 eb 00 0a          lea.l    $a(a3), a0
  0038d4:  28 88                move.l   a0, (a4)
  0038d6:  70 04                moveq    #$4, d0
  0038d8:  2f 00                move.l   d0, -(a7)
  0038da:  48 6e ff ec          pea.l    -$14(a6)
  0038de:  72 21                moveq    #$21, d1
  0038e0:  2f 01                move.l   d1, -(a7)
  0038e2:  61 ff 00 00 10 e0    bsr.l    $49c4  ; -> EngineDispatch
  0038e8:  2e 00                move.l   d0, d7
  0038ea:  70 01                moveq    #$1, d0
  0038ec:  b0 87                cmp.l    d7, d0
  0038ee:  4f ef 00 0c          lea.l    $c(a7), a7
  0038f2:  67 00 01 96          beq.w    $3a8a
  0038f6:  48 6b 00 12          pea.l    $12(a3)
  0038fa:  48 6b 00 0e          pea.l    $e(a3)
  0038fe:  20 6e ff fc          movea.l  -$4(a6), a0
  003902:  48 68 00 02          pea.l    $2(a0)
  003906:  61 ff 00 00 4d ce    bsr.l    $86d6  ; -> sub_86d6
  00390c:  1c 00                move.b   d0, d6
  00390e:  70 02                moveq    #$2, d0
  003910:  b0 87                cmp.l    d7, d0
  003912:  4f ef 00 0c          lea.l    $c(a7), a7
  003916:  66 36                bne.b    $394e
  003918:  20 6e ff fc          movea.l  -$4(a6), a0
  00391c:  31 7c ff ff 00 42    move.w   #$ffff, $42(a0)
  003922:  3f 13                move.w   (a3), -(a7)
  003924:  2f 2b 00 02          move.l   $2(a3), -(a7)
  003928:  2f 2b 00 06          move.l   $6(a3), -(a7)
  00392c:  2f 2b 00 0a          move.l   $a(a3), -(a7)
  003930:  48 78 10 08          pea.l    $1008.w
  003934:  61 ff 00 00 34 5c    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00393a:  58 8f                addq.l   #$4, a7
  00393c:  2f 00                move.l   d0, -(a7)
  00393e:  20 5f                movea.l  (a7)+, a0
  003940:  4e 90                jsr      (a0)
  003942:  20 6e ff fc          movea.l  -$4(a6), a0
  003946:  31 6b 00 14 00 42    move.w   $14(a3), $42(a0)
  00394c:  60 20                bra.b    $396e
  00394e:  3f 13                move.w   (a3), -(a7)
  003950:  2f 2b 00 02          move.l   $2(a3), -(a7)
  003954:  2f 2b 00 06          move.l   $6(a3), -(a7)
  003958:  2f 2b 00 0a          move.l   $a(a3), -(a7)
  00395c:  48 78 10 08          pea.l    $1008.w
  003960:  61 ff 00 00 34 30    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003966:  58 8f                addq.l   #$4, a7
  003968:  2f 00                move.l   d0, -(a7)
  00396a:  20 5f                movea.l  (a7)+, a0
  00396c:  4e 90                jsr      (a0)
  00396e:  4a 06                tst.b    d6
  003970:  67 00 01 18          beq.w    $3a8a
  003974:  30 2b 00 12          move.w   $12(a3), d0
  003978:  48 c0                ext.l    d0
  00397a:  2f 00                move.l   d0, -(a7)
  00397c:  2f 2b 00 0e          move.l   $e(a3), -(a7)
  003980:  20 6e ff fc          movea.l  -$4(a6), a0
  003984:  48 68 00 02          pea.l    $2(a0)
  003988:  61 ff 00 00 4e 10    bsr.l    $879a  ; -> sub_879a
  00398e:  4f ef 00 0c          lea.l    $c(a7), a7
  003992:  60 00 00 f6          bra.w    $3a8a
  003996:  30 13                move.w   (a3), d0
  003998:  48 c0                ext.l    d0
  00399a:  28 c0                move.l   d0, (a4)+
  00399c:  28 eb 00 02          move.l   $2(a3), (a4)+
  0039a0:  20 4b                movea.l  a3, a0
  0039a2:  5c 88                addq.l   #$6, a0
  0039a4:  28 c8                move.l   a0, (a4)+
  0039a6:  41 eb 00 0a          lea.l    $a(a3), a0
  0039aa:  28 88                move.l   a0, (a4)
  0039ac:  70 04                moveq    #$4, d0
  0039ae:  2f 00                move.l   d0, -(a7)
  0039b0:  48 6e ff ec          pea.l    -$14(a6)
  0039b4:  72 21                moveq    #$21, d1
  0039b6:  2f 01                move.l   d1, -(a7)
  0039b8:  61 ff 00 00 10 0a    bsr.l    $49c4  ; -> EngineDispatch
  0039be:  2e 00                move.l   d0, d7
  0039c0:  70 01                moveq    #$1, d0
  0039c2:  b0 87                cmp.l    d7, d0
  0039c4:  4f ef 00 0c          lea.l    $c(a7), a7
  0039c8:  67 00 00 9c          beq.w    $3a66
  0039cc:  48 6b 00 12          pea.l    $12(a3)
  0039d0:  48 6b 00 0e          pea.l    $e(a3)
  0039d4:  20 6e ff fc          movea.l  -$4(a6), a0
  0039d8:  48 68 00 02          pea.l    $2(a0)
  0039dc:  61 ff 00 00 4c f8    bsr.l    $86d6  ; -> sub_86d6
  0039e2:  1c 00                move.b   d0, d6
  0039e4:  70 02                moveq    #$2, d0
  0039e6:  b0 87                cmp.l    d7, d0
  0039e8:  4f ef 00 0c          lea.l    $c(a7), a7
  0039ec:  66 36                bne.b    $3a24
  0039ee:  20 6e ff fc          movea.l  -$4(a6), a0
  0039f2:  31 7c ff ff 00 42    move.w   #$ffff, $42(a0)
  0039f8:  3f 13                move.w   (a3), -(a7)
  0039fa:  2f 2b 00 02          move.l   $2(a3), -(a7)
  0039fe:  2f 2b 00 06          move.l   $6(a3), -(a7)
  003a02:  2f 2b 00 0a          move.l   $a(a3), -(a7)
  003a06:  48 78 10 08          pea.l    $1008.w
  003a0a:  61 ff 00 00 33 86    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003a10:  58 8f                addq.l   #$4, a7
  003a12:  2f 00                move.l   d0, -(a7)
  003a14:  20 5f                movea.l  (a7)+, a0
  003a16:  4e 90                jsr      (a0)
  003a18:  20 6e ff fc          movea.l  -$4(a6), a0
  003a1c:  31 6b 00 14 00 42    move.w   $14(a3), $42(a0)
  003a22:  60 20                bra.b    $3a44
  003a24:  3f 13                move.w   (a3), -(a7)
  003a26:  2f 2b 00 02          move.l   $2(a3), -(a7)
  003a2a:  2f 2b 00 06          move.l   $6(a3), -(a7)
  003a2e:  2f 2b 00 0a          move.l   $a(a3), -(a7)
  003a32:  48 78 10 08          pea.l    $1008.w
  003a36:  61 ff 00 00 33 5a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003a3c:  58 8f                addq.l   #$4, a7
  003a3e:  2f 00                move.l   d0, -(a7)
  003a40:  20 5f                movea.l  (a7)+, a0
  003a42:  4e 90                jsr      (a0)
  003a44:  4a 06                tst.b    d6
  003a46:  67 1e                beq.b    $3a66
  003a48:  30 2b 00 12          move.w   $12(a3), d0
  003a4c:  48 c0                ext.l    d0
  003a4e:  2f 00                move.l   d0, -(a7)
  003a50:  2f 2b 00 0e          move.l   $e(a3), -(a7)
  003a54:  20 6e ff fc          movea.l  -$4(a6), a0
  003a58:  48 68 00 02          pea.l    $2(a0)
  003a5c:  61 ff 00 00 4d 3c    bsr.l    $879a  ; -> sub_879a
  003a62:  4f ef 00 0c          lea.l    $c(a7), a7
  003a66:  61 ff 00 00 45 a8    bsr.l    $8010  ; -> GetA5
  003a6c:  20 40                movea.l  d0, a0
  003a6e:  20 10                move.l   (a0), d0
  003a70:  90 bc 00 00 00 ca    sub.l    #$ca, d0
  003a76:  20 40                movea.l  d0, a0
  003a78:  48 68 00 b2          pea.l    $b2(a0)
  003a7c:  a8 9d                dc.w     $a89d  ; _PenPat
  003a7e:  70 0b                moveq    #$b, d0
  003a80:  3f 00                move.w   d0, -(a7)
  003a82:  a8 9c                dc.w     $a89c  ; _PenMode
  003a84:  48 6b 00 2c          pea.l    $2c(a3)
  003a88:  a8 a2                dc.w     $a8a2  ; _PaintRect
  003a8a:  48 6b 00 1a          pea.l    $1a(a3)
  003a8e:  a8 99                dc.w     $a899  ; _SetPenState
  003a90:  4c ee 18 c0 ff d0    movem.l  -$30(a6), d6-d7/a3-a4
  003a96:  4e 5e                unlk     a6
  003a98:  4e 74 00 0c          rtd      #$c
handler_05:
  003a9c:  4e 56 ff 78          link.w   a6, #$ff78
  003aa0:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  003aa4:  3e 2e 00 14          move.w   $14(a6), d7
  003aa8:  49 ee ff 78          lea.l    -$88(a6), a4
  003aac:  61 ff 00 00 45 62    bsr.l    $8010  ; -> GetA5
  003ab2:  20 40                movea.l  d0, a0
  003ab4:  20 50                movea.l  (a0), a0
  003ab6:  26 50                movea.l  (a0), a3
  003ab8:  42 06                clr.b    d6
  003aba:  70 00                moveq    #$0, d0
  003abc:  2d 40 ff 88          move.l   d0, -$78(a6)
  003ac0:  42 6e ff 8c          clr.w    -$74(a6)
  003ac4:  4a 47                tst.w    d7
  003ac6:  6f 00 03 08          ble.w    $3dd0  ; -> L3dd0
  003aca:  3a 2b 00 42          move.w   $42(a3), d5
  003ace:  6d 00 02 d4          blt.w    $3da4  ; -> L3da4
  003ad2:  70 31                moveq    #$31, d0
  003ad4:  b0 6b 00 48          cmp.w    $48(a3), d0
  003ad8:  66 00 02 0c          bne.w    $3ce6  ; -> L3ce6
  003adc:  2d 6b 00 5c ff c8    move.l   $5c(a3), -$38(a6)
  003ae2:  70 00                moveq    #$0, d0
  003ae4:  27 40 00 5c          move.l   d0, $5c(a3)
  003ae8:  48 6e ff 8e          pea.l    -$72(a6)
  003aec:  a8 98                dc.w     $a898  ; _GetPenState
  003aee:  37 7c 00 01 00 48    move.w   #$1, $48(a3)
  003af4:  a8 9e                dc.w     $a89e  ; _PenNormal
  003af6:  2d 6e 00 0c ff ac    move.l   $c(a6), -$54(a6)
  003afc:  2d 6e 00 08 ff b0    move.l   $8(a6), -$50(a6)
  003b02:  55 8f                subq.l   #$2, a7
  003b04:  3f 07                move.w   d7, -(a7)
  003b06:  2f 2e 00 10          move.l   $10(a6), -(a7)
  003b0a:  48 6e ff ac          pea.l    -$54(a6)
  003b0e:  48 6e ff b0          pea.l    -$50(a6)
  003b12:  48 6e ff b4          pea.l    -$4c(a6)
  003b16:  a8 ed                dc.w     $a8ed  ; _StdTxMeas
  003b18:  30 1f                move.w   (a7)+, d0
  003b1a:  48 c0                ext.l    d0
  003b1c:  28 00                move.l   d0, d4
  003b1e:  48 6e ff b4          pea.l    -$4c(a6)
  003b22:  a8 8b                dc.w     $a88b  ; _GetFontInfo
  003b24:  30 2e ff 90          move.w   -$70(a6), d0
  003b28:  3d 40 ff be          move.w   d0, -$42(a6)
  003b2c:  d0 44                add.w    d4, d0
  003b2e:  3d 40 ff c2          move.w   d0, -$3e(a6)
  003b32:  30 2e ff 8e          move.w   -$72(a6), d0
  003b36:  90 6e ff b4          sub.w    -$4c(a6), d0
  003b3a:  3d 40 ff bc          move.w   d0, -$44(a6)
  003b3e:  30 2e ff b6          move.w   -$4a(a6), d0
  003b42:  d0 6e ff 8e          add.w    -$72(a6), d0
  003b46:  3d 40 ff c0          move.w   d0, -$40(a6)
  003b4a:  59 8f                subq.l   #$4, a7
  003b4c:  a8 d8                dc.w     $a8d8  ; _NewRgn
  003b4e:  2d 57 ff c4          move.l   (a7), -$3c(a6)
  003b52:  48 6e ff bc          pea.l    -$44(a6)
  003b56:  a8 df                dc.w     $a8df  ; _RectRgn
  003b58:  4a 6b 00 06          tst.w    $6(a3)
  003b5c:  6c 00 00 92          bge.w    $3bf0  ; -> L3bf0
  003b60:  41 ee ff a0          lea.l    -$60(a6), a0
  003b64:  43 eb 00 24          lea.l    $24(a3), a1
  003b68:  20 d9                move.l   (a1)+, (a0)+
  003b6a:  30 d9                move.w   (a1)+, (a0)+
  003b6c:  41 ee ff a6          lea.l    -$5a(a6), a0
  003b70:  43 eb 00 2a          lea.l    $2a(a3), a1
  003b74:  20 d9                move.l   (a1)+, (a0)+
  003b76:  30 d9                move.w   (a1)+, (a0)+
  003b78:  3d 47 ff cc          move.w   d7, -$34(a6)
  003b7c:  2d 6e 00 10 ff ce    move.l   $10(a6), -$32(a6)
  003b82:  2d 6e 00 0c ff d2    move.l   $c(a6), -$2e(a6)
  003b88:  2d 6e 00 08 ff d6    move.l   $8(a6), -$2a(a6)
  003b8e:  2d 6e ff 88 ff da    move.l   -$78(a6), -$26(a6)
  003b94:  3d 6e ff 8c ff de    move.w   -$74(a6), -$22(a6)
  003b9a:  3d 45 ff e0          move.w   d5, -$20(a6)
  003b9e:  2d 4b ff e2          move.l   a3, -$1e(a6)
  003ba2:  41 ee ff e6          lea.l    -$1a(a6), a0
  003ba6:  43 ee ff 8e          lea.l    -$72(a6), a1
  003baa:  70 03                moveq    #$3, d0
L3bac:
  003bac:  20 d9                move.l   (a1)+, (a0)+
  003bae:  51 c8 ff fc          dbra     d0, $3bac  ; -> L3bac
  003bb2:  30 d9                move.w   (a1)+, (a0)+
  003bb4:  41 ee ff f8          lea.l    -$8(a6), a0
  003bb8:  43 ee ff bc          lea.l    -$44(a6), a1
  003bbc:  20 d9                move.l   (a1)+, (a0)+
  003bbe:  20 d9                move.l   (a1)+, (a0)+
  003bc0:  2f 2e ff c4          move.l   -$3c(a6), -(a7)
  003bc4:  48 7b 01 70 ff ff fc a2 pea.l    $fffffca2(a16, invalid.w)
  003bcc:  48 6e ff cc          pea.l    -$34(a6)
  003bd0:  70 00                moveq    #$0, d0
  003bd2:  2f 00                move.l   d0, -(a7)
  003bd4:  ab ca                dc.w     $abca  ; _DeviceLoop
  003bd6:  48 6e ff a0          pea.l    -$60(a6)
  003bda:  aa 14                dc.w     $aa14  ; _RGBForeColor
  003bdc:  48 6e ff a6          pea.l    -$5a(a6)
  003be0:  aa 15                dc.w     $aa15  ; _RGBBackColor
  003be2:  d9 6e ff 90          add.w    d4, -$70(a6)
  003be6:  48 6e ff 8e          pea.l    -$72(a6)
  003bea:  a8 99                dc.w     $a899  ; _SetPenState
  003bec:  60 00 00 e2          bra.w    $3cd0  ; -> L3cd0
L3bf0:
  003bf0:  48 c7                ext.l    d7
  003bf2:  28 c7                move.l   d7, (a4)+
  003bf4:  28 ee 00 10          move.l   $10(a6), (a4)+
  003bf8:  41 ee 00 0c          lea.l    $c(a6), a0
  003bfc:  28 c8                move.l   a0, (a4)+
  003bfe:  41 ee 00 08          lea.l    $8(a6), a0
  003c02:  28 88                move.l   a0, (a4)
  003c04:  70 04                moveq    #$4, d0
  003c06:  2f 00                move.l   d0, -(a7)
  003c08:  48 6e ff 78          pea.l    -$88(a6)
  003c0c:  72 21                moveq    #$21, d1
  003c0e:  2f 01                move.l   d1, -(a7)
  003c10:  61 ff 00 00 0d b2    bsr.l    $49c4  ; -> EngineDispatch
  003c16:  28 00                move.l   d0, d4
  003c18:  70 01                moveq    #$1, d0
  003c1a:  b0 84                cmp.l    d4, d0
  003c1c:  4f ef 00 0c          lea.l    $c(a7), a7
  003c20:  67 00 00 8a          beq.w    $3cac  ; -> L3cac
  003c24:  48 6e ff 8c          pea.l    -$74(a6)
  003c28:  48 6e ff 88          pea.l    -$78(a6)
  003c2c:  48 6b 00 02          pea.l    $2(a3)
  003c30:  61 ff 00 00 4a a4    bsr.l    $86d6  ; -> sub_86d6
  003c36:  1c 00                move.b   d0, d6
  003c38:  70 02                moveq    #$2, d0
  003c3a:  b0 84                cmp.l    d4, d0
  003c3c:  4f ef 00 0c          lea.l    $c(a7), a7
  003c40:  66 2c                bne.b    $3c6e  ; -> L3c6e
  003c42:  37 7c ff ff 00 42    move.w   #$ffff, $42(a3)
  003c48:  3f 07                move.w   d7, -(a7)
  003c4a:  2f 2e 00 10          move.l   $10(a6), -(a7)
  003c4e:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003c52:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003c56:  48 78 10 08          pea.l    $1008.w
  003c5a:  61 ff 00 00 31 36    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003c60:  58 8f                addq.l   #$4, a7
  003c62:  2f 00                move.l   d0, -(a7)
  003c64:  20 5f                movea.l  (a7)+, a0
  003c66:  4e 90                jsr      (a0)
  003c68:  37 45 00 42          move.w   d5, $42(a3)
  003c6c:  60 20                bra.b    $3c8e  ; -> L3c8e
L3c6e:
  003c6e:  3f 07                move.w   d7, -(a7)
  003c70:  2f 2e 00 10          move.l   $10(a6), -(a7)
  003c74:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003c78:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003c7c:  48 78 10 08          pea.l    $1008.w
  003c80:  61 ff 00 00 31 10    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003c86:  58 8f                addq.l   #$4, a7
  003c88:  2f 00                move.l   d0, -(a7)
  003c8a:  20 5f                movea.l  (a7)+, a0
  003c8c:  4e 90                jsr      (a0)
L3c8e:
  003c8e:  4a 06                tst.b    d6
  003c90:  67 1a                beq.b    $3cac  ; -> L3cac
  003c92:  30 2e ff 8c          move.w   -$74(a6), d0
  003c96:  48 c0                ext.l    d0
  003c98:  2f 00                move.l   d0, -(a7)
  003c9a:  2f 2e ff 88          move.l   -$78(a6), -(a7)
  003c9e:  48 6b 00 02          pea.l    $2(a3)
  003ca2:  61 ff 00 00 4a f6    bsr.l    $879a  ; -> sub_879a
  003ca8:  4f ef 00 0c          lea.l    $c(a7), a7
L3cac:
  003cac:  61 ff 00 00 43 62    bsr.l    $8010  ; -> GetA5
  003cb2:  20 40                movea.l  d0, a0
  003cb4:  20 10                move.l   (a0), d0
  003cb6:  90 bc 00 00 00 ca    sub.l    #$ca, d0
  003cbc:  20 40                movea.l  d0, a0
  003cbe:  48 68 00 b2          pea.l    $b2(a0)
  003cc2:  a8 9d                dc.w     $a89d  ; _PenPat
  003cc4:  70 0b                moveq    #$b, d0
  003cc6:  3f 00                move.w   d0, -(a7)
  003cc8:  a8 9c                dc.w     $a89c  ; _PenMode
  003cca:  48 6e ff bc          pea.l    -$44(a6)
  003cce:  a8 a2                dc.w     $a8a2  ; _PaintRect
L3cd0:
  003cd0:  2f 2e ff c4          move.l   -$3c(a6), -(a7)
  003cd4:  a8 d9                dc.w     $a8d9  ; _DisposRgn
  003cd6:  37 7c 00 31 00 48    move.w   #$31, $48(a3)
  003cdc:  27 6e ff c8 00 5c    move.l   -$38(a6), $5c(a3)
  003ce2:  60 00 00 ec          bra.w    $3dd0  ; -> L3dd0
L3ce6:
  003ce6:  48 c7                ext.l    d7
  003ce8:  28 c7                move.l   d7, (a4)+
  003cea:  28 ee 00 10          move.l   $10(a6), (a4)+
  003cee:  41 ee 00 0c          lea.l    $c(a6), a0
  003cf2:  28 c8                move.l   a0, (a4)+
  003cf4:  41 ee 00 08          lea.l    $8(a6), a0
  003cf8:  28 88                move.l   a0, (a4)
  003cfa:  70 04                moveq    #$4, d0
  003cfc:  2f 00                move.l   d0, -(a7)
  003cfe:  48 6e ff 78          pea.l    -$88(a6)
  003d02:  72 21                moveq    #$21, d1
  003d04:  2f 01                move.l   d1, -(a7)
  003d06:  61 ff 00 00 0c bc    bsr.l    $49c4  ; -> EngineDispatch
  003d0c:  28 00                move.l   d0, d4
  003d0e:  70 01                moveq    #$1, d0
  003d10:  b0 84                cmp.l    d4, d0
  003d12:  4f ef 00 0c          lea.l    $c(a7), a7
  003d16:  67 00 00 b8          beq.w    $3dd0  ; -> L3dd0
  003d1a:  48 6e ff 8c          pea.l    -$74(a6)
  003d1e:  48 6e ff 88          pea.l    -$78(a6)
  003d22:  48 6b 00 02          pea.l    $2(a3)
  003d26:  61 ff 00 00 49 ae    bsr.l    $86d6  ; -> sub_86d6
  003d2c:  1c 00                move.b   d0, d6
  003d2e:  70 02                moveq    #$2, d0
  003d30:  b0 84                cmp.l    d4, d0
  003d32:  4f ef 00 0c          lea.l    $c(a7), a7
  003d36:  66 2c                bne.b    $3d64  ; -> L3d64
  003d38:  37 7c ff ff 00 42    move.w   #$ffff, $42(a3)
  003d3e:  3f 07                move.w   d7, -(a7)
  003d40:  2f 2e 00 10          move.l   $10(a6), -(a7)
  003d44:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003d48:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003d4c:  48 78 10 08          pea.l    $1008.w
  003d50:  61 ff 00 00 30 40    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003d56:  58 8f                addq.l   #$4, a7
  003d58:  2f 00                move.l   d0, -(a7)
  003d5a:  20 5f                movea.l  (a7)+, a0
  003d5c:  4e 90                jsr      (a0)
  003d5e:  37 45 00 42          move.w   d5, $42(a3)
  003d62:  60 20                bra.b    $3d84  ; -> L3d84
L3d64:
  003d64:  3f 07                move.w   d7, -(a7)
  003d66:  2f 2e 00 10          move.l   $10(a6), -(a7)
  003d6a:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003d6e:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003d72:  48 78 10 08          pea.l    $1008.w
  003d76:  61 ff 00 00 30 1a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003d7c:  58 8f                addq.l   #$4, a7
  003d7e:  2f 00                move.l   d0, -(a7)
  003d80:  20 5f                movea.l  (a7)+, a0
  003d82:  4e 90                jsr      (a0)
L3d84:
  003d84:  4a 06                tst.b    d6
  003d86:  67 48                beq.b    $3dd0  ; -> L3dd0
  003d88:  30 2e ff 8c          move.w   -$74(a6), d0
  003d8c:  48 c0                ext.l    d0
  003d8e:  2f 00                move.l   d0, -(a7)
  003d90:  2f 2e ff 88          move.l   -$78(a6), -(a7)
  003d94:  48 6b 00 02          pea.l    $2(a3)
  003d98:  61 ff 00 00 4a 00    bsr.l    $879a  ; -> sub_879a
  003d9e:  4f ef 00 0c          lea.l    $c(a7), a7
  003da2:  60 2c                bra.b    $3dd0  ; -> L3dd0
L3da4:
  003da4:  70 08                moveq    #$8, d0
  003da6:  2f 00                move.l   d0, -(a7)
  003da8:  61 ff 00 00 0a 78    bsr.l    $4822  ; -> sub_4822
  003dae:  3f 07                move.w   d7, -(a7)
  003db0:  2f 2e 00 10          move.l   $10(a6), -(a7)
  003db4:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003db8:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003dbc:  48 78 10 08          pea.l    $1008.w
  003dc0:  61 ff 00 00 2f d0    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003dc6:  58 8f                addq.l   #$4, a7
  003dc8:  2f 00                move.l   d0, -(a7)
  003dca:  20 5f                movea.l  (a7)+, a0
  003dcc:  4e 90                jsr      (a0)
  003dce:  58 4f                addq.w   #$4, a7
L3dd0:
  003dd0:  4c ee 18 f0 ff 60    movem.l  -$a0(a6), d4-d7/a3-a4
  003dd6:  4e 5e                unlk     a6
  003dd8:  4e 74 00 0e          rtd      #$e
handler_04:
  003ddc:  4e 56 ff e4          link.w   a6, #$ffe4
  003de0:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  003de4:  3a 2e 00 08          move.w   $8(a6), d5
  003de8:  3c 2e 00 0a          move.w   $a(a6), d6
  003dec:  1e 2e 00 10          move.b   $10(a6), d7
  003df0:  49 ee ff e4          lea.l    -$1c(a6), a4
  003df4:  61 ff 00 00 42 1a    bsr.l    $8010  ; -> GetA5
  003dfa:  20 40                movea.l  d0, a0
  003dfc:  20 50                movea.l  (a0), a0
  003dfe:  26 50                movea.l  (a0), a3
  003e00:  42 04                clr.b    d4
  003e02:  3d 6b 00 42 ff fe    move.w   $42(a3), -$2(a6)
  003e08:  6d 00 00 bc          blt.w    $3ec6  ; -> L3ec6
  003e0c:  70 00                moveq    #$0, d0
  003e0e:  10 07                move.b   d7, d0
  003e10:  28 c0                move.l   d0, (a4)+
  003e12:  28 ee 00 0c          move.l   $c(a6), (a4)+
  003e16:  48 c6                ext.l    d6
  003e18:  28 c6                move.l   d6, (a4)+
  003e1a:  48 c5                ext.l    d5
  003e1c:  28 85                move.l   d5, (a4)
  003e1e:  70 04                moveq    #$4, d0
  003e20:  2f 00                move.l   d0, -(a7)
  003e22:  48 6e ff e4          pea.l    -$1c(a6)
  003e26:  72 23                moveq    #$23, d1
  003e28:  2f 01                move.l   d1, -(a7)
  003e2a:  61 ff 00 00 0b 98    bsr.l    $49c4  ; -> EngineDispatch
  003e30:  2d 40 ff fa          move.l   d0, -$6(a6)
  003e34:  72 01                moveq    #$1, d1
  003e36:  b2 80                cmp.l    d0, d1
  003e38:  4f ef 00 0c          lea.l    $c(a7), a7
  003e3c:  67 00 00 b0          beq.w    $3eee  ; -> L3eee
  003e40:  48 6e ff f8          pea.l    -$8(a6)
  003e44:  48 6e ff f4          pea.l    -$c(a6)
  003e48:  48 6b 00 02          pea.l    $2(a3)
  003e4c:  61 ff 00 00 48 88    bsr.l    $86d6  ; -> sub_86d6
  003e52:  18 00                move.b   d0, d4
  003e54:  70 02                moveq    #$2, d0
  003e56:  b0 ae ff fa          cmp.l    -$6(a6), d0
  003e5a:  4f ef 00 0c          lea.l    $c(a7), a7
  003e5e:  66 2a                bne.b    $3e8a  ; -> L3e8a
  003e60:  37 7c ff ff 00 42    move.w   #$ffff, $42(a3)
  003e66:  1f 07                move.b   d7, -(a7)
  003e68:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003e6c:  3f 06                move.w   d6, -(a7)
  003e6e:  3f 05                move.w   d5, -(a7)
  003e70:  48 78 10 f4          pea.l    $10f4.w
  003e74:  61 ff 00 00 2f 1c    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003e7a:  58 8f                addq.l   #$4, a7
  003e7c:  2f 00                move.l   d0, -(a7)
  003e7e:  20 5f                movea.l  (a7)+, a0
  003e80:  4e 90                jsr      (a0)
  003e82:  37 6e ff fe 00 42    move.w   -$2(a6), $42(a3)
  003e88:  60 1c                bra.b    $3ea6  ; -> L3ea6
L3e8a:
  003e8a:  1f 07                move.b   d7, -(a7)
  003e8c:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003e90:  3f 06                move.w   d6, -(a7)
  003e92:  3f 05                move.w   d5, -(a7)
  003e94:  48 78 10 f4          pea.l    $10f4.w
  003e98:  61 ff 00 00 2e f8    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003e9e:  58 8f                addq.l   #$4, a7
  003ea0:  2f 00                move.l   d0, -(a7)
  003ea2:  20 5f                movea.l  (a7)+, a0
  003ea4:  4e 90                jsr      (a0)
L3ea6:
  003ea6:  4a 04                tst.b    d4
  003ea8:  67 44                beq.b    $3eee  ; -> L3eee
  003eaa:  30 2e ff f8          move.w   -$8(a6), d0
  003eae:  48 c0                ext.l    d0
  003eb0:  2f 00                move.l   d0, -(a7)
  003eb2:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  003eb6:  48 6b 00 02          pea.l    $2(a3)
  003eba:  61 ff 00 00 48 de    bsr.l    $879a  ; -> sub_879a
  003ec0:  4f ef 00 0c          lea.l    $c(a7), a7
  003ec4:  60 28                bra.b    $3eee  ; -> L3eee
L3ec6:
  003ec6:  1f 07                move.b   d7, -(a7)
  003ec8:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003ecc:  3f 06                move.w   d6, -(a7)
  003ece:  3f 05                move.w   d5, -(a7)
  003ed0:  48 78 10 f4          pea.l    $10f4.w
  003ed4:  61 ff 00 00 2e bc    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003eda:  58 8f                addq.l   #$4, a7
  003edc:  2f 00                move.l   d0, -(a7)
  003ede:  20 5f                movea.l  (a7)+, a0
  003ee0:  4e 90                jsr      (a0)
  003ee2:  70 08                moveq    #$8, d0
  003ee4:  2f 00                move.l   d0, -(a7)
  003ee6:  61 ff 00 00 09 3a    bsr.l    $4822  ; -> sub_4822
  003eec:  58 4f                addq.w   #$4, a7
L3eee:
  003eee:  4c ee 18 f0 ff cc    movem.l  -$34(a6), d4-d7/a3-a4
  003ef4:  4e 5e                unlk     a6
  003ef6:  4e 74 00 0a          rtd      #$a
handler_22:
  003efa:  4e 56 ff e4          link.w   a6, #$ffe4
  003efe:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  003f02:  3a 2e 00 08          move.w   $8(a6), d5
  003f06:  3c 2e 00 0a          move.w   $a(a6), d6
  003f0a:  1e 2e 00 10          move.b   $10(a6), d7
  003f0e:  49 ee ff e4          lea.l    -$1c(a6), a4
  003f12:  61 ff 00 00 40 fc    bsr.l    $8010  ; -> GetA5
  003f18:  20 40                movea.l  d0, a0
  003f1a:  20 50                movea.l  (a0), a0
  003f1c:  26 50                movea.l  (a0), a3
  003f1e:  42 2e ff f5          clr.b    -$b(a6)
  003f22:  38 2b 00 42          move.w   $42(a3), d4
  003f26:  6d 00 00 c4          blt.w    $3fec  ; -> L3fec
  003f2a:  70 00                moveq    #$0, d0
  003f2c:  10 07                move.b   d7, d0
  003f2e:  28 c0                move.l   d0, (a4)+
  003f30:  28 ee 00 0c          move.l   $c(a6), (a4)+
  003f34:  48 c6                ext.l    d6
  003f36:  28 c6                move.l   d6, (a4)+
  003f38:  48 c5                ext.l    d5
  003f3a:  28 85                move.l   d5, (a4)
  003f3c:  70 04                moveq    #$4, d0
  003f3e:  2f 00                move.l   d0, -(a7)
  003f40:  48 6e ff e4          pea.l    -$1c(a6)
  003f44:  72 2e                moveq    #$2e, d1
  003f46:  2f 01                move.l   d1, -(a7)
  003f48:  61 ff 00 00 0a 7a    bsr.l    $49c4  ; -> EngineDispatch
  003f4e:  2d 40 ff fc          move.l   d0, -$4(a6)
  003f52:  72 01                moveq    #$1, d1
  003f54:  b2 80                cmp.l    d0, d1
  003f56:  4f ef 00 0c          lea.l    $c(a7), a7
  003f5a:  67 00 00 b8          beq.w    $4014  ; -> L4014
  003f5e:  38 2b 00 42          move.w   $42(a3), d4
  003f62:  6d 1a                blt.b    $3f7e  ; -> L3f7e
  003f64:  48 6e ff fa          pea.l    -$6(a6)
  003f68:  48 6e ff f6          pea.l    -$a(a6)
  003f6c:  48 6b 00 02          pea.l    $2(a3)
  003f70:  61 ff 00 00 47 64    bsr.l    $86d6  ; -> sub_86d6
  003f76:  1d 40 ff f5          move.b   d0, -$b(a6)
  003f7a:  4f ef 00 0c          lea.l    $c(a7), a7
L3f7e:
  003f7e:  70 02                moveq    #$2, d0
  003f80:  b0 ae ff fc          cmp.l    -$4(a6), d0
  003f84:  66 28                bne.b    $3fae  ; -> L3fae
  003f86:  37 7c ff ff 00 42    move.w   #$ffff, $42(a3)
  003f8c:  1f 07                move.b   d7, -(a7)
  003f8e:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003f92:  3f 06                move.w   d6, -(a7)
  003f94:  3f 05                move.w   d5, -(a7)
  003f96:  48 78 10 bc          pea.l    $10bc.w
  003f9a:  61 ff 00 00 2d f6    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003fa0:  58 8f                addq.l   #$4, a7
  003fa2:  2f 00                move.l   d0, -(a7)
  003fa4:  20 5f                movea.l  (a7)+, a0
  003fa6:  4e 90                jsr      (a0)
  003fa8:  37 44 00 42          move.w   d4, $42(a3)
  003fac:  60 1c                bra.b    $3fca  ; -> L3fca
L3fae:
  003fae:  1f 07                move.b   d7, -(a7)
  003fb0:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003fb4:  3f 06                move.w   d6, -(a7)
  003fb6:  3f 05                move.w   d5, -(a7)
  003fb8:  48 78 10 bc          pea.l    $10bc.w
  003fbc:  61 ff 00 00 2d d4    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  003fc2:  58 8f                addq.l   #$4, a7
  003fc4:  2f 00                move.l   d0, -(a7)
  003fc6:  20 5f                movea.l  (a7)+, a0
  003fc8:  4e 90                jsr      (a0)
L3fca:
  003fca:  4a 2e ff f5          tst.b    -$b(a6)
  003fce:  67 44                beq.b    $4014  ; -> L4014
  003fd0:  30 2e ff fa          move.w   -$6(a6), d0
  003fd4:  48 c0                ext.l    d0
  003fd6:  2f 00                move.l   d0, -(a7)
  003fd8:  2f 2e ff f6          move.l   -$a(a6), -(a7)
  003fdc:  48 6b 00 02          pea.l    $2(a3)
  003fe0:  61 ff 00 00 47 b8    bsr.l    $879a  ; -> sub_879a
  003fe6:  4f ef 00 0c          lea.l    $c(a7), a7
  003fea:  60 28                bra.b    $4014  ; -> L4014
L3fec:
  003fec:  70 08                moveq    #$8, d0
  003fee:  2f 00                move.l   d0, -(a7)
  003ff0:  61 ff 00 00 08 30    bsr.l    $4822  ; -> sub_4822
  003ff6:  1f 07                move.b   d7, -(a7)
  003ff8:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003ffc:  3f 06                move.w   d6, -(a7)
  003ffe:  3f 05                move.w   d5, -(a7)
  004000:  48 78 10 bc          pea.l    $10bc.w
  004004:  61 ff 00 00 2d 8c    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00400a:  58 8f                addq.l   #$4, a7
  00400c:  2f 00                move.l   d0, -(a7)
  00400e:  20 5f                movea.l  (a7)+, a0
  004010:  4e 90                jsr      (a0)
  004012:  58 4f                addq.w   #$4, a7
L4014:
  004014:  4c ee 18 f0 ff cc    movem.l  -$34(a6), d4-d7/a3-a4
  00401a:  4e 5e                unlk     a6
  00401c:  4e 74 00 0a          rtd      #$a
handler_21:
  004020:  4e 56 ff f2          link.w   a6, #$fff2
  004024:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  004028:  26 6e 00 08          movea.l  $8(a6), a3
  00402c:  1e 2e 00 0c          move.b   $c(a6), d7
  004030:  61 ff 00 00 3f de    bsr.l    $8010  ; -> GetA5
  004036:  20 40                movea.l  d0, a0
  004038:  20 50                movea.l  (a0), a0
  00403a:  28 50                movea.l  (a0), a4
  00403c:  42 06                clr.b    d6
  00403e:  3a 2c 00 42          move.w   $42(a4), d5
  004042:  6d 00 00 a4          blt.w    $40e8  ; -> L40e8
  004046:  70 00                moveq    #$0, d0
  004048:  10 07                move.b   d7, d0
  00404a:  2d 40 ff f2          move.l   d0, -$e(a6)
  00404e:  2d 4b ff f6          move.l   a3, -$a(a6)
  004052:  70 02                moveq    #$2, d0
  004054:  2f 00                move.l   d0, -(a7)
  004056:  48 6e ff f2          pea.l    -$e(a6)
  00405a:  72 2f                moveq    #$2f, d1
  00405c:  2f 01                move.l   d1, -(a7)
  00405e:  61 ff 00 00 09 64    bsr.l    $49c4  ; -> EngineDispatch
  004064:  28 00                move.l   d0, d4
  004066:  70 01                moveq    #$1, d0
  004068:  b0 84                cmp.l    d4, d0
  00406a:  4f ef 00 0c          lea.l    $c(a7), a7
  00406e:  67 00 00 9a          beq.w    $410a  ; -> L410a
  004072:  48 6e ff fe          pea.l    -$2(a6)
  004076:  48 6e ff fa          pea.l    -$6(a6)
  00407a:  48 6c 00 02          pea.l    $2(a4)
  00407e:  61 ff 00 00 46 56    bsr.l    $86d6  ; -> sub_86d6
  004084:  1c 00                move.b   d0, d6
  004086:  70 02                moveq    #$2, d0
  004088:  b0 84                cmp.l    d4, d0
  00408a:  4f ef 00 0c          lea.l    $c(a7), a7
  00408e:  66 22                bne.b    $40b2  ; -> L40b2
  004090:  39 7c ff ff 00 42    move.w   #$ffff, $42(a4)
  004096:  1f 07                move.b   d7, -(a7)
  004098:  2f 0b                move.l   a3, -(a7)
  00409a:  48 78 10 d8          pea.l    $10d8.w
  00409e:  61 ff 00 00 2c f2    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0040a4:  58 8f                addq.l   #$4, a7
  0040a6:  2f 00                move.l   d0, -(a7)
  0040a8:  20 5f                movea.l  (a7)+, a0
  0040aa:  4e 90                jsr      (a0)
  0040ac:  39 45 00 42          move.w   d5, $42(a4)
  0040b0:  60 16                bra.b    $40c8  ; -> L40c8
L40b2:
  0040b2:  1f 07                move.b   d7, -(a7)
  0040b4:  2f 0b                move.l   a3, -(a7)
  0040b6:  48 78 10 d8          pea.l    $10d8.w
  0040ba:  61 ff 00 00 2c d6    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0040c0:  58 8f                addq.l   #$4, a7
  0040c2:  2f 00                move.l   d0, -(a7)
  0040c4:  20 5f                movea.l  (a7)+, a0
  0040c6:  4e 90                jsr      (a0)
L40c8:
  0040c8:  4a 06                tst.b    d6
  0040ca:  67 3e                beq.b    $410a  ; -> L410a
  0040cc:  30 2e ff fe          move.w   -$2(a6), d0
  0040d0:  48 c0                ext.l    d0
  0040d2:  2f 00                move.l   d0, -(a7)
  0040d4:  2f 2e ff fa          move.l   -$6(a6), -(a7)
  0040d8:  48 6c 00 02          pea.l    $2(a4)
  0040dc:  61 ff 00 00 46 bc    bsr.l    $879a  ; -> sub_879a
  0040e2:  4f ef 00 0c          lea.l    $c(a7), a7
  0040e6:  60 22                bra.b    $410a  ; -> L410a
L40e8:
  0040e8:  70 08                moveq    #$8, d0
  0040ea:  2f 00                move.l   d0, -(a7)
  0040ec:  61 ff 00 00 07 34    bsr.l    $4822  ; -> sub_4822
  0040f2:  1f 07                move.b   d7, -(a7)
  0040f4:  2f 0b                move.l   a3, -(a7)
  0040f6:  48 78 10 d8          pea.l    $10d8.w
  0040fa:  61 ff 00 00 2c 96    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  004100:  58 8f                addq.l   #$4, a7
  004102:  2f 00                move.l   d0, -(a7)
  004104:  20 5f                movea.l  (a7)+, a0
  004106:  4e 90                jsr      (a0)
  004108:  58 4f                addq.w   #$4, a7
L410a:
  00410a:  4c ee 18 f0 ff da    movem.l  -$26(a6), d4-d7/a3-a4
  004110:  4e 5e                unlk     a6
  004112:  4e 74 00 06          rtd      #$6
handler_20:
  004116:  4e 56 ff f2          link.w   a6, #$fff2
  00411a:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  00411e:  26 6e 00 08          movea.l  $8(a6), a3
  004122:  1e 2e 00 0c          move.b   $c(a6), d7
  004126:  61 ff 00 00 3e e8    bsr.l    $8010  ; -> GetA5
  00412c:  20 40                movea.l  d0, a0
  00412e:  20 50                movea.l  (a0), a0
  004130:  28 50                movea.l  (a0), a4
  004132:  42 06                clr.b    d6
  004134:  3a 2c 00 42          move.w   $42(a4), d5
  004138:  6d 00 00 a4          blt.w    $41de  ; -> L41de
  00413c:  70 00                moveq    #$0, d0
  00413e:  10 07                move.b   d7, d0
  004140:  2d 40 ff f2          move.l   d0, -$e(a6)
  004144:  2d 4b ff f6          move.l   a3, -$a(a6)
  004148:  70 02                moveq    #$2, d0
  00414a:  2f 00                move.l   d0, -(a7)
  00414c:  48 6e ff f2          pea.l    -$e(a6)
  004150:  72 24                moveq    #$24, d1
  004152:  2f 01                move.l   d1, -(a7)
  004154:  61 ff 00 00 08 6e    bsr.l    $49c4  ; -> EngineDispatch
  00415a:  28 00                move.l   d0, d4
  00415c:  70 01                moveq    #$1, d0
  00415e:  b0 84                cmp.l    d4, d0
  004160:  4f ef 00 0c          lea.l    $c(a7), a7
  004164:  67 00 00 9a          beq.w    $4200  ; -> L4200
  004168:  48 6e ff fe          pea.l    -$2(a6)
  00416c:  48 6e ff fa          pea.l    -$6(a6)
  004170:  48 6c 00 02          pea.l    $2(a4)
  004174:  61 ff 00 00 45 60    bsr.l    $86d6  ; -> sub_86d6
  00417a:  1c 00                move.b   d0, d6
  00417c:  70 02                moveq    #$2, d0
  00417e:  b0 84                cmp.l    d4, d0
  004180:  4f ef 00 0c          lea.l    $c(a7), a7
  004184:  66 22                bne.b    $41a8  ; -> L41a8
  004186:  39 7c ff ff 00 42    move.w   #$ffff, $42(a4)
  00418c:  1f 07                move.b   d7, -(a7)
  00418e:  2f 0b                move.l   a3, -(a7)
  004190:  48 78 10 80          pea.l    $1080.w
  004194:  61 ff 00 00 2b fc    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00419a:  58 8f                addq.l   #$4, a7
  00419c:  2f 00                move.l   d0, -(a7)
  00419e:  20 5f                movea.l  (a7)+, a0
  0041a0:  4e 90                jsr      (a0)
  0041a2:  39 45 00 42          move.w   d5, $42(a4)
  0041a6:  60 16                bra.b    $41be  ; -> L41be
L41a8:
  0041a8:  1f 07                move.b   d7, -(a7)
  0041aa:  2f 0b                move.l   a3, -(a7)
  0041ac:  48 78 10 80          pea.l    $1080.w
  0041b0:  61 ff 00 00 2b e0    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0041b6:  58 8f                addq.l   #$4, a7
  0041b8:  2f 00                move.l   d0, -(a7)
  0041ba:  20 5f                movea.l  (a7)+, a0
  0041bc:  4e 90                jsr      (a0)
L41be:
  0041be:  4a 06                tst.b    d6
  0041c0:  67 3e                beq.b    $4200  ; -> L4200
  0041c2:  30 2e ff fe          move.w   -$2(a6), d0
  0041c6:  48 c0                ext.l    d0
  0041c8:  2f 00                move.l   d0, -(a7)
  0041ca:  2f 2e ff fa          move.l   -$6(a6), -(a7)
  0041ce:  48 6c 00 02          pea.l    $2(a4)
  0041d2:  61 ff 00 00 45 c6    bsr.l    $879a  ; -> sub_879a
  0041d8:  4f ef 00 0c          lea.l    $c(a7), a7
  0041dc:  60 22                bra.b    $4200  ; -> L4200
L41de:
  0041de:  70 08                moveq    #$8, d0
  0041e0:  2f 00                move.l   d0, -(a7)
  0041e2:  61 ff 00 00 06 3e    bsr.l    $4822  ; -> sub_4822
  0041e8:  1f 07                move.b   d7, -(a7)
  0041ea:  2f 0b                move.l   a3, -(a7)
  0041ec:  48 78 10 80          pea.l    $1080.w
  0041f0:  61 ff 00 00 2b a0    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0041f6:  58 8f                addq.l   #$4, a7
  0041f8:  2f 00                move.l   d0, -(a7)
  0041fa:  20 5f                movea.l  (a7)+, a0
  0041fc:  4e 90                jsr      (a0)
  0041fe:  58 4f                addq.w   #$4, a7
L4200:
  004200:  4c ee 18 f0 ff da    movem.l  -$26(a6), d4-d7/a3-a4
  004206:  4e 5e                unlk     a6
  004208:  4e 74 00 06          rtd      #$6
handler_08:
  00420c:  4e 56 00 00          link.w   a6, #$0
  004210:  48 e7 01 08          movem.l  d7/a4, -(a7)
  004214:  59 8f                subq.l   #$4, a7
  004216:  2f 38 08 88          move.l   $888.w, -(a7)
  00421a:  61 ff 00 00 80 2e    bsr.l    $c24a  ; -> Strip24
  004220:  28 5f                movea.l  (a7)+, a4
  004222:  4a ac 00 18          tst.l    $18(a4)
  004226:  66 5c                bne.b    $4284  ; -> L4284
  004228:  20 6c 00 08          movea.l  $8(a4), a0
  00422c:  2e 10                move.l   (a0), d7
L422e:
  00422e:  20 6c 00 0c          movea.l  $c(a4), a0
  004232:  4a 90                tst.l    (a0)
  004234:  66 f8                bne.b    $422e  ; -> L422e
  004236:  20 6c 00 08          movea.l  $8(a4), a0
  00423a:  20 bc 00 00 08 04    move.l   #$804, (a0)
  004240:  20 6c 00 0c          movea.l  $c(a4), a0
  004244:  4a 90                tst.l    (a0)
  004246:  67 08                beq.b    $4250  ; -> L4250
  004248:  20 6c 00 08          movea.l  $8(a4), a0
  00424c:  20 87                move.l   d7, (a0)
  00424e:  60 de                bra.b    $422e  ; -> L422e
L4250:
  004250:  20 6c 00 30          movea.l  $30(a4), a0
  004254:  4a 90                tst.l    (a0)
  004256:  67 0c                beq.b    $4264  ; -> L4264
  004258:  42 38 08 cc          clr.b    $8cc.w
  00425c:  20 6c 00 30          movea.l  $30(a4), a0
  004260:  70 00                moveq    #$0, d0
  004262:  20 80                move.l   d0, (a0)
L4264:
  004264:  48 78 08 04          pea.l    $804.w
  004268:  61 ff 00 00 2b 28    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00426e:  58 8f                addq.l   #$4, a7
  004270:  2f 00                move.l   d0, -(a7)
  004272:  20 5f                movea.l  (a7)+, a0
  004274:  4e 90                jsr      (a0)
  004276:  61 ff 00 00 7d bc    bsr.l    $c034  ; -> sub_c034
  00427c:  20 6c 00 08          movea.l  $8(a4), a0
  004280:  20 87                move.l   d7, (a0)
  004282:  60 2a                bra.b    $42ae  ; -> L42ae
L4284:
  004284:  20 2c 00 40          move.l   $40(a4), d0
  004288:  53 ac 00 40          subq.l   #$1, $40(a4)
  00428c:  4a 80                tst.l    d0
  00428e:  6c 06                bge.b    $4296  ; -> L4296
  004290:  70 00                moveq    #$0, d0
  004292:  29 40 00 40          move.l   d0, $40(a4)
L4296:
  004296:  4a ac 00 40          tst.l    $40(a4)
  00429a:  66 12                bne.b    $42ae  ; -> L42ae
  00429c:  20 2c 00 44          move.l   $44(a4), d0
  0042a0:  52 ac 00 44          addq.l   #$1, $44(a4)
  0042a4:  4a 80                tst.l    d0
  0042a6:  6f 06                ble.b    $42ae  ; -> L42ae
  0042a8:  70 00                moveq    #$0, d0
  0042aa:  29 40 00 44          move.l   d0, $44(a4)
L42ae:
  0042ae:  4c ee 10 80 ff f8    movem.l  -$8(a6), d7/a4
  0042b4:  4e 5e                unlk     a6
  0042b6:  4e 75                rts      
handler_07:
  0042b8:  4e 56 00 00          link.w   a6, #$0
  0042bc:  48 e7 01 08          movem.l  d7/a4, -(a7)
  0042c0:  59 8f                subq.l   #$4, a7
  0042c2:  2f 38 08 88          move.l   $888.w, -(a7)
  0042c6:  61 ff 00 00 7f 82    bsr.l    $c24a  ; -> Strip24
  0042cc:  28 5f                movea.l  (a7)+, a4
  0042ce:  4a ac 00 18          tst.l    $18(a4)
  0042d2:  67 06                beq.b    $42da  ; -> L42da
  0042d4:  53 ac 00 44          subq.l   #$1, $44(a4)
  0042d8:  60 5a                bra.b    $4334  ; -> L4334
L42da:
  0042da:  20 6c 00 08          movea.l  $8(a4), a0
  0042de:  2e 10                move.l   (a0), d7
L42e0:
  0042e0:  20 6c 00 0c          movea.l  $c(a4), a0
  0042e4:  4a 90                tst.l    (a0)
  0042e6:  66 f8                bne.b    $42e0  ; -> L42e0
  0042e8:  20 6c 00 08          movea.l  $8(a4), a0
  0042ec:  20 bc 00 00 08 00    move.l   #$800, (a0)
  0042f2:  20 6c 00 0c          movea.l  $c(a4), a0
  0042f6:  4a 90                tst.l    (a0)
  0042f8:  67 08                beq.b    $4302  ; -> L4302
  0042fa:  20 6c 00 08          movea.l  $8(a4), a0
  0042fe:  20 87                move.l   d7, (a0)
  004300:  60 de                bra.b    $42e0  ; -> L42e0
L4302:
  004302:  20 6c 00 30          movea.l  $30(a4), a0
  004306:  4a 90                tst.l    (a0)
  004308:  67 0c                beq.b    $4316  ; -> L4316
  00430a:  42 38 08 cc          clr.b    $8cc.w
  00430e:  20 6c 00 30          movea.l  $30(a4), a0
  004312:  70 00                moveq    #$0, d0
  004314:  20 80                move.l   d0, (a0)
L4316:
  004316:  48 78 08 00          pea.l    $800.w
  00431a:  61 ff 00 00 2a 76    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  004320:  58 8f                addq.l   #$4, a7
  004322:  2f 00                move.l   d0, -(a7)
  004324:  20 5f                movea.l  (a7)+, a0
  004326:  4e 90                jsr      (a0)
  004328:  61 ff 00 00 7d 0a    bsr.l    $c034  ; -> sub_c034
  00432e:  20 6c 00 08          movea.l  $8(a4), a0
  004332:  20 87                move.l   d7, (a0)
L4334:
  004334:  4c ee 10 80 ff f8    movem.l  -$8(a6), d7/a4
  00433a:  4e 5e                unlk     a6
  00433c:  4e 75                rts      
handler_70:
  00433e:  4e 56 00 00          link.w   a6, #$0
  004342:  48 e7 01 08          movem.l  d7/a4, -(a7)
  004346:  59 8f                subq.l   #$4, a7
  004348:  2f 38 08 88          move.l   $888.w, -(a7)
  00434c:  61 ff 00 00 7e fc    bsr.l    $c24a  ; -> Strip24
  004352:  28 5f                movea.l  (a7)+, a4
  004354:  20 6c 00 08          movea.l  $8(a4), a0
  004358:  2e 10                move.l   (a0), d7
L435a:
  00435a:  20 6c 00 0c          movea.l  $c(a4), a0
  00435e:  4a 90                tst.l    (a0)
  004360:  66 f8                bne.b    $435a  ; -> L435a
  004362:  20 6c 00 08          movea.l  $8(a4), a0
  004366:  20 bc 00 00 08 18    move.l   #$818, (a0)
  00436c:  20 6c 00 0c          movea.l  $c(a4), a0
  004370:  4a 90                tst.l    (a0)
  004372:  67 08                beq.b    $437c  ; -> L437c
  004374:  20 6c 00 08          movea.l  $8(a4), a0
  004378:  20 87                move.l   d7, (a0)
  00437a:  60 de                bra.b    $435a  ; -> L435a
L437c:
  00437c:  20 6c 00 30          movea.l  $30(a4), a0
  004380:  4a 90                tst.l    (a0)
  004382:  67 0c                beq.b    $4390  ; -> L4390
  004384:  42 38 08 cc          clr.b    $8cc.w
  004388:  20 6c 00 30          movea.l  $30(a4), a0
  00438c:  70 00                moveq    #$0, d0
  00438e:  20 80                move.l   d0, (a0)
L4390:
  004390:  2f 2e 00 12          move.l   $12(a6), -(a7)
  004394:  3f 2e 00 10          move.w   $10(a6), -(a7)
  004398:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00439c:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0043a0:  48 78 08 18          pea.l    $818.w
  0043a4:  61 ff 00 00 29 ec    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0043aa:  58 8f                addq.l   #$4, a7
  0043ac:  2f 00                move.l   d0, -(a7)
  0043ae:  20 5f                movea.l  (a7)+, a0
  0043b0:  4e 90                jsr      (a0)
  0043b2:  61 ff 00 00 7c 80    bsr.l    $c034  ; -> sub_c034
  0043b8:  20 6c 00 08          movea.l  $8(a4), a0
  0043bc:  20 87                move.l   d7, (a0)
  0043be:  4c ee 10 80 ff f8    movem.l  -$8(a6), d7/a4
  0043c4:  4e 5e                unlk     a6
  0043c6:  4e 74 00 0e          rtd      #$e
handler_71:
  0043ca:  4e 56 00 00          link.w   a6, #$0
  0043ce:  48 e7 01 08          movem.l  d7/a4, -(a7)
  0043d2:  59 8f                subq.l   #$4, a7
  0043d4:  2f 38 08 88          move.l   $888.w, -(a7)
  0043d8:  61 ff 00 00 7e 70    bsr.l    $c24a  ; -> Strip24
  0043de:  28 5f                movea.l  (a7)+, a4
  0043e0:  20 6c 00 08          movea.l  $8(a4), a0
  0043e4:  2e 10                move.l   (a0), d7
L43e6:
  0043e6:  20 6c 00 0c          movea.l  $c(a4), a0
  0043ea:  4a 90                tst.l    (a0)
  0043ec:  66 f8                bne.b    $43e6  ; -> L43e6
  0043ee:  20 6c 00 08          movea.l  $8(a4), a0
  0043f2:  20 bc 00 00 08 1c    move.l   #$81c, (a0)
  0043f8:  20 6c 00 0c          movea.l  $c(a4), a0
  0043fc:  4a 90                tst.l    (a0)
  0043fe:  67 08                beq.b    $4408  ; -> L4408
  004400:  20 6c 00 08          movea.l  $8(a4), a0
  004404:  20 87                move.l   d7, (a0)
  004406:  60 de                bra.b    $43e6  ; -> L43e6
L4408:
  004408:  20 6c 00 30          movea.l  $30(a4), a0
  00440c:  4a 90                tst.l    (a0)
  00440e:  67 0c                beq.b    $441c  ; -> L441c
  004410:  42 38 08 cc          clr.b    $8cc.w
  004414:  20 6c 00 30          movea.l  $30(a4), a0
  004418:  70 00                moveq    #$0, d0
  00441a:  20 80                move.l   d0, (a0)
L441c:
  00441c:  48 78 08 1c          pea.l    $81c.w
  004420:  61 ff 00 00 29 70    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  004426:  58 8f                addq.l   #$4, a7
  004428:  2f 00                move.l   d0, -(a7)
  00442a:  20 5f                movea.l  (a7)+, a0
  00442c:  4e 90                jsr      (a0)
  00442e:  61 ff 00 00 7c 04    bsr.l    $c034  ; -> sub_c034
  004434:  20 6c 00 08          movea.l  $8(a4), a0
  004438:  20 87                move.l   d7, (a0)
  00443a:  4c ee 10 80 ff f8    movem.l  -$8(a6), d7/a4
  004440:  4e 5e                unlk     a6
  004442:  4e 75                rts      
handler_72:
  004444:  4e 56 00 00          link.w   a6, #$0
  004448:  48 e7 01 08          movem.l  d7/a4, -(a7)
  00444c:  59 8f                subq.l   #$4, a7
  00444e:  2f 38 08 88          move.l   $888.w, -(a7)
  004452:  61 ff 00 00 7d f6    bsr.l    $c24a  ; -> Strip24
  004458:  28 5f                movea.l  (a7)+, a4
  00445a:  20 6c 00 08          movea.l  $8(a4), a0
  00445e:  2e 10                move.l   (a0), d7
L4460:
  004460:  20 6c 00 0c          movea.l  $c(a4), a0
  004464:  4a 90                tst.l    (a0)
  004466:  66 f8                bne.b    $4460  ; -> L4460
  004468:  20 6c 00 08          movea.l  $8(a4), a0
  00446c:  20 bc 00 00 08 90    move.l   #$890, (a0)
  004472:  20 6c 00 0c          movea.l  $c(a4), a0
  004476:  4a 90                tst.l    (a0)
  004478:  67 08                beq.b    $4482  ; -> L4482
  00447a:  20 6c 00 08          movea.l  $8(a4), a0
  00447e:  20 87                move.l   d7, (a0)
  004480:  60 de                bra.b    $4460  ; -> L4460
L4482:
  004482:  20 6c 00 30          movea.l  $30(a4), a0
  004486:  4a 90                tst.l    (a0)
  004488:  67 0c                beq.b    $4496  ; -> L4496
  00448a:  42 38 08 cc          clr.b    $8cc.w
  00448e:  20 6c 00 30          movea.l  $30(a4), a0
  004492:  70 00                moveq    #$0, d0
  004494:  20 80                move.l   d0, (a0)
L4496:
  004496:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00449a:  48 78 08 90          pea.l    $890.w
  00449e:  61 ff 00 00 28 f2    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0044a4:  58 8f                addq.l   #$4, a7
  0044a6:  2f 00                move.l   d0, -(a7)
  0044a8:  20 5f                movea.l  (a7)+, a0
  0044aa:  4e 90                jsr      (a0)
  0044ac:  61 ff 00 00 7b 86    bsr.l    $c034  ; -> sub_c034
  0044b2:  20 6c 00 08          movea.l  $8(a4), a0
  0044b6:  20 87                move.l   d7, (a0)
  0044b8:  4c ee 10 80 ff f8    movem.l  -$8(a6), d7/a4
  0044be:  4e 5e                unlk     a6
  0044c0:  4e 74 00 04          rtd      #$4
handler_09:
  0044c4:  4e 56 ff fc          link.w   a6, #$fffc
  0044c8:  48 e7 0f 08          movem.l  d4-d7/a4, -(a7)
  0044cc:  38 2e 00 08          move.w   $8(a6), d4
  0044d0:  3a 2e 00 0a          move.w   $a(a6), d5
  0044d4:  3c 2e 00 0c          move.w   $c(a6), d6
  0044d8:  3e 2e 00 0e          move.w   $e(a6), d7
  0044dc:  59 8f                subq.l   #$4, a7
  0044de:  2f 38 08 88          move.l   $888.w, -(a7)
  0044e2:  61 ff 00 00 7d 66    bsr.l    $c24a  ; -> Strip24
  0044e8:  28 5f                movea.l  (a7)+, a4
  0044ea:  4a ac 00 18          tst.l    $18(a4)
  0044ee:  67 70                beq.b    $4560  ; -> L4560
  0044f0:  20 6c 00 1c          movea.l  $1c(a4), a0
  0044f4:  4a 50                tst.w    (a0)
  0044f6:  66 2e                bne.b    $4526  ; -> L4526
  0044f8:  4a 68 00 02          tst.w    $2(a0)
  0044fc:  66 28                bne.b    $4526  ; -> L4526
  0044fe:  4a 68 00 06          tst.w    $6(a0)
  004502:  66 22                bne.b    $4526  ; -> L4526
  004504:  4a 68 00 04          tst.w    $4(a0)
  004508:  66 1c                bne.b    $4526  ; -> L4526
  00450a:  30 86                move.w   d6, (a0)
  00450c:  20 6c 00 1c          movea.l  $1c(a4), a0
  004510:  31 47 00 02          move.w   d7, $2(a0)
  004514:  20 6c 00 1c          movea.l  $1c(a4), a0
  004518:  31 45 00 06          move.w   d5, $6(a0)
  00451c:  20 6c 00 1c          movea.l  $1c(a4), a0
  004520:  31 44 00 04          move.w   d4, $4(a0)
  004524:  60 34                bra.b    $455a  ; -> L455a
L4526:
  004526:  20 6c 00 1c          movea.l  $1c(a4), a0
  00452a:  bc 50                cmp.w    (a0), d6
  00452c:  6c 02                bge.b    $4530  ; -> L4530
  00452e:  30 86                move.w   d6, (a0)
L4530:
  004530:  20 6c 00 1c          movea.l  $1c(a4), a0
  004534:  be 68 00 02          cmp.w    $2(a0), d7
  004538:  6c 04                bge.b    $453e  ; -> L453e
  00453a:  31 47 00 02          move.w   d7, $2(a0)
L453e:
  00453e:  20 6c 00 1c          movea.l  $1c(a4), a0
  004542:  ba 68 00 06          cmp.w    $6(a0), d5
  004546:  6f 04                ble.b    $454c  ; -> L454c
  004548:  31 45 00 06          move.w   d5, $6(a0)
L454c:
  00454c:  20 6c 00 1c          movea.l  $1c(a4), a0
  004550:  b8 68 00 04          cmp.w    $4(a0), d4
  004554:  6f 04                ble.b    $455a  ; -> L455a
  004556:  31 44 00 04          move.w   d4, $4(a0)
L455a:
  00455a:  52 ac 00 40          addq.l   #$1, $40(a4)
  00455e:  60 68                bra.b    $45c8  ; -> L45c8
L4560:
  004560:  20 6c 00 08          movea.l  $8(a4), a0
  004564:  2d 50 ff fc          move.l   (a0), -$4(a6)
L4568:
  004568:  20 6c 00 0c          movea.l  $c(a4), a0
  00456c:  4a 90                tst.l    (a0)
  00456e:  66 f8                bne.b    $4568  ; -> L4568
  004570:  20 6c 00 08          movea.l  $8(a4), a0
  004574:  20 bc 00 00 08 08    move.l   #$808, (a0)
  00457a:  20 6c 00 0c          movea.l  $c(a4), a0
  00457e:  4a 90                tst.l    (a0)
  004580:  67 0a                beq.b    $458c  ; -> L458c
  004582:  20 6c 00 08          movea.l  $8(a4), a0
  004586:  20 ae ff fc          move.l   -$4(a6), (a0)
  00458a:  60 dc                bra.b    $4568  ; -> L4568
L458c:
  00458c:  20 6c 00 30          movea.l  $30(a4), a0
  004590:  4a 90                tst.l    (a0)
  004592:  67 0c                beq.b    $45a0  ; -> L45a0
  004594:  42 38 08 cc          clr.b    $8cc.w
  004598:  20 6c 00 30          movea.l  $30(a4), a0
  00459c:  70 00                moveq    #$0, d0
  00459e:  20 80                move.l   d0, (a0)
L45a0:
  0045a0:  3f 07                move.w   d7, -(a7)
  0045a2:  3f 06                move.w   d6, -(a7)
  0045a4:  3f 05                move.w   d5, -(a7)
  0045a6:  3f 04                move.w   d4, -(a7)
  0045a8:  48 78 08 08          pea.l    $808.w
  0045ac:  61 ff 00 00 27 e4    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0045b2:  58 8f                addq.l   #$4, a7
  0045b4:  2f 00                move.l   d0, -(a7)
  0045b6:  20 5f                movea.l  (a7)+, a0
  0045b8:  4e 90                jsr      (a0)
  0045ba:  61 ff 00 00 7a 78    bsr.l    $c034  ; -> sub_c034
  0045c0:  20 6c 00 08          movea.l  $8(a4), a0
  0045c4:  20 ae ff fc          move.l   -$4(a6), (a0)
L45c8:
  0045c8:  4c ee 10 f0 ff e8    movem.l  -$18(a6), d4-d7/a4
  0045ce:  4e 5e                unlk     a6
  0045d0:  4e 74 00 08          rtd      #$8
handler_69:
  0045d4:  4e 56 00 00          link.w   a6, #$0
  0045d8:  48 e7 01 08          movem.l  d7/a4, -(a7)
  0045dc:  59 8f                subq.l   #$4, a7
  0045de:  2f 38 08 88          move.l   $888.w, -(a7)
  0045e2:  61 ff 00 00 7c 66    bsr.l    $c24a  ; -> Strip24
  0045e8:  28 5f                movea.l  (a7)+, a4
  0045ea:  70 00                moveq    #$0, d0
  0045ec:  29 40 00 44          move.l   d0, $44(a4)
  0045f0:  29 40 00 40          move.l   d0, $40(a4)
  0045f4:  20 6c 00 08          movea.l  $8(a4), a0
  0045f8:  2e 10                move.l   (a0), d7
L45fa:
  0045fa:  20 6c 00 0c          movea.l  $c(a4), a0
  0045fe:  4a 90                tst.l    (a0)
  004600:  66 f8                bne.b    $45fa  ; -> L45fa
  004602:  20 6c 00 08          movea.l  $8(a4), a0
  004606:  20 bc 00 00 08 14    move.l   #$814, (a0)
  00460c:  20 6c 00 0c          movea.l  $c(a4), a0
  004610:  4a 90                tst.l    (a0)
  004612:  67 08                beq.b    $461c  ; -> L461c
  004614:  20 6c 00 08          movea.l  $8(a4), a0
  004618:  20 87                move.l   d7, (a0)
  00461a:  60 de                bra.b    $45fa  ; -> L45fa
L461c:
  00461c:  20 6c 00 30          movea.l  $30(a4), a0
  004620:  4a 90                tst.l    (a0)
  004622:  67 0c                beq.b    $4630  ; -> L4630
  004624:  42 38 08 cc          clr.b    $8cc.w
  004628:  20 6c 00 30          movea.l  $30(a4), a0
  00462c:  70 00                moveq    #$0, d0
  00462e:  20 80                move.l   d0, (a0)
L4630:
  004630:  48 78 08 14          pea.l    $814.w
  004634:  61 ff 00 00 27 5c    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00463a:  58 8f                addq.l   #$4, a7
  00463c:  2f 00                move.l   d0, -(a7)
  00463e:  20 5f                movea.l  (a7)+, a0
  004640:  4e 90                jsr      (a0)
  004642:  61 ff 00 00 79 f0    bsr.l    $c034  ; -> sub_c034
  004648:  20 6c 00 08          movea.l  $8(a4), a0
  00464c:  20 87                move.l   d7, (a0)
  00464e:  4c ee 10 80 ff f8    movem.l  -$8(a6), d7/a4
  004654:  4e 5e                unlk     a6
  004656:  4e 75                rts      
handler_93:
  004658:  4e 56 00 00          link.w   a6, #$0
  00465c:  70 1f                moveq    #$1f, d0
  00465e:  2f 00                move.l   d0, -(a7)
  004660:  61 ff 00 00 01 c0    bsr.l    $4822  ; -> sub_4822
  004666:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00466a:  48 78 0f b8          pea.l    $fb8.w
  00466e:  61 ff 00 00 27 22    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  004674:  58 8f                addq.l   #$4, a7
  004676:  2f 00                move.l   d0, -(a7)
  004678:  20 5f                movea.l  (a7)+, a0
  00467a:  4e 90                jsr      (a0)
  00467c:  4e 5e                unlk     a6
  00467e:  4e 74 00 04          rtd      #$4
handler_94:
  004682:  4e 56 00 00          link.w   a6, #$0
  004686:  70 1e                moveq    #$1e, d0
  004688:  2f 00                move.l   d0, -(a7)
  00468a:  61 ff 00 00 01 96    bsr.l    $4822  ; -> sub_4822
  004690:  2f 2e 00 08          move.l   $8(a6), -(a7)
  004694:  48 78 0f b4          pea.l    $fb4.w
  004698:  61 ff 00 00 26 f8    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00469e:  58 8f                addq.l   #$4, a7
  0046a0:  2f 00                move.l   d0, -(a7)
  0046a2:  20 5f                movea.l  (a7)+, a0
  0046a4:  4e 90                jsr      (a0)
  0046a6:  4e 5e                unlk     a6
  0046a8:  4e 74 00 04          rtd      #$4
handler_95:
  0046ac:  4e 56 00 00          link.w   a6, #$0
  0046b0:  70 1e                moveq    #$1e, d0
  0046b2:  2f 00                move.l   d0, -(a7)
  0046b4:  61 ff 00 00 01 6c    bsr.l    $4822  ; -> sub_4822
  0046ba:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0046be:  48 78 0f bc          pea.l    $fbc.w
  0046c2:  61 ff 00 00 26 ce    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0046c8:  58 8f                addq.l   #$4, a7
  0046ca:  2f 00                move.l   d0, -(a7)
  0046cc:  20 5f                movea.l  (a7)+, a0
  0046ce:  4e 90                jsr      (a0)
  0046d0:  4e 5e                unlk     a6
  0046d2:  4e 74 00 04          rtd      #$4
handler_96:
  0046d6:  4e 56 00 00          link.w   a6, #$0
  0046da:  70 1e                moveq    #$1e, d0
  0046dc:  2f 00                move.l   d0, -(a7)
  0046de:  61 ff 00 00 01 42    bsr.l    $4822  ; -> sub_4822
  0046e4:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0046e8:  48 78 16 04          pea.l    $1604.w
  0046ec:  61 ff 00 00 26 a4    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0046f2:  58 8f                addq.l   #$4, a7
  0046f4:  2f 00                move.l   d0, -(a7)
  0046f6:  20 5f                movea.l  (a7)+, a0
  0046f8:  4e 90                jsr      (a0)
  0046fa:  4e 5e                unlk     a6
  0046fc:  4e 74 00 04          rtd      #$4
handler_97:
  004700:  4e 56 00 00          link.w   a6, #$0
  004704:  70 1e                moveq    #$1e, d0
  004706:  2f 00                move.l   d0, -(a7)
  004708:  61 ff 00 00 01 18    bsr.l    $4822  ; -> sub_4822
  00470e:  2f 2e 00 08          move.l   $8(a6), -(a7)
  004712:  48 78 16 00          pea.l    $1600.w
  004716:  61 ff 00 00 26 7a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00471c:  58 8f                addq.l   #$4, a7
  00471e:  2f 00                move.l   d0, -(a7)
  004720:  20 5f                movea.l  (a7)+, a0
  004722:  4e 90                jsr      (a0)
  004724:  4e 5e                unlk     a6
  004726:  4e 74 00 04          rtd      #$4
handler_75:
  00472a:  4e 56 00 00          link.w   a6, #$0
  00472e:  70 1a                moveq    #$1a, d0
  004730:  2f 00                move.l   d0, -(a7)
  004732:  61 ff 00 00 00 ee    bsr.l    $4822  ; -> sub_4822
  004738:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00473c:  2f 2e 00 08          move.l   $8(a6), -(a7)
  004740:  48 78 11 d8          pea.l    $11d8.w
  004744:  61 ff 00 00 26 4c    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00474a:  58 8f                addq.l   #$4, a7
  00474c:  2f 00                move.l   d0, -(a7)
  00474e:  20 5f                movea.l  (a7)+, a0
  004750:  4e 90                jsr      (a0)
  004752:  70 1a                moveq    #$1a, d0
  004754:  2f 00                move.l   d0, -(a7)
  004756:  61 ff 00 00 00 ca    bsr.l    $4822  ; -> sub_4822
  00475c:  4e 5e                unlk     a6
  00475e:  4e 74 00 08          rtd      #$8
handler_82:
  004762:  4e 56 00 00          link.w   a6, #$0
  004766:  2f 0c                move.l   a4, -(a7)
  004768:  59 8f                subq.l   #$4, a7
  00476a:  2f 38 08 88          move.l   $888.w, -(a7)
  00476e:  61 ff 00 00 7a da    bsr.l    $c24a  ; -> Strip24
  004774:  20 5f                movea.l  (a7)+, a0
  004776:  20 50                movea.l  (a0), a0
  004778:  28 50                movea.l  (a0), a4
  00477a:  19 7c 00 01 02 56    move.b   #$1, $256(a4)
  004780:  2f 2e 00 20          move.l   $20(a6), -(a7)
  004784:  2f 2e 00 1c          move.l   $1c(a6), -(a7)
  004788:  2f 2e 00 18          move.l   $18(a6), -(a7)
  00478c:  2f 2e 00 14          move.l   $14(a6), -(a7)
  004790:  2f 2e 00 10          move.l   $10(a6), -(a7)
  004794:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  004798:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00479c:  48 78 17 40          pea.l    $1740.w
  0047a0:  61 ff 00 00 25 f0    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0047a6:  58 8f                addq.l   #$4, a7
  0047a8:  2f 00                move.l   d0, -(a7)
  0047aa:  20 5f                movea.l  (a7)+, a0
  0047ac:  4e 90                jsr      (a0)
  0047ae:  42 2c 02 56          clr.b    $256(a4)
  0047b2:  28 6e ff fc          movea.l  -$4(a6), a4
  0047b6:  4e 5e                unlk     a6
  0047b8:  4e 74 00 1c          rtd      #$1c
handler_83:
  0047bc:  4e 56 ff fa          link.w   a6, #$fffa
  0047c0:  2f 0c                move.l   a4, -(a7)
  0047c2:  20 6e 00 10          movea.l  $10(a6), a0
  0047c6:  43 ee ff fa          lea.l    -$6(a6), a1
  0047ca:  22 d8                move.l   (a0)+, (a1)+
  0047cc:  32 d8                move.w   (a0)+, (a1)+
  0047ce:  59 8f                subq.l   #$4, a7
  0047d0:  2f 38 08 88          move.l   $888.w, -(a7)
  0047d4:  61 ff 00 00 7a 74    bsr.l    $c24a  ; -> Strip24
  0047da:  20 5f                movea.l  (a7)+, a0
  0047dc:  20 50                movea.l  (a0), a0
  0047de:  28 50                movea.l  (a0), a4
  0047e0:  19 7c 00 01 02 56    move.b   #$1, $256(a4)
  0047e6:  2f 2e 00 20          move.l   $20(a6), -(a7)
  0047ea:  2f 2e 00 1c          move.l   $1c(a6), -(a7)
  0047ee:  2f 2e 00 18          move.l   $18(a6), -(a7)
  0047f2:  2f 2e 00 14          move.l   $14(a6), -(a7)
  0047f6:  48 6e ff fa          pea.l    -$6(a6)
  0047fa:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  0047fe:  2f 2e 00 08          move.l   $8(a6), -(a7)
  004802:  48 78 17 3c          pea.l    $173c.w
  004806:  61 ff 00 00 25 8a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00480c:  58 8f                addq.l   #$4, a7
  00480e:  2f 00                move.l   d0, -(a7)
  004810:  20 5f                movea.l  (a7)+, a0
  004812:  4e 90                jsr      (a0)
  004814:  42 2c 02 56          clr.b    $256(a4)
  004818:  28 6e ff f6          movea.l  -$a(a6), a4
  00481c:  4e 5e                unlk     a6
  00481e:  4e 74 00 1c          rtd      #$1c
* example command wrapper: EngineDispatch(arg, 0, cmd=$26).
sub_4822:
  004822:  4e 56 00 00          link.w   a6, #$0
  004826:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00482a:  70 00                moveq    #$0, d0
  00482c:  2f 00                move.l   d0, -(a7)
  00482e:  72 26                moveq    #$26, d1
  004830:  2f 01                move.l   d1, -(a7)
  004832:  61 ff 00 00 01 90    bsr.l    $49c4  ; -> EngineDispatch
  004838:  4e 5e                unlk     a6
  00483a:  4e 75                rts      
handler_02:
  00483c:  4e 56 ff ee          link.w   a6, #$ffee
  004840:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  004844:  3e 2e 00 0c          move.w   $c(a6), d7
  004848:  26 6e 00 1a          movea.l  $1a(a6), a3
  00484c:  42 ae ff fc          clr.l    -$4(a6)
  004850:  42 ae ff f8          clr.l    -$8(a6)
  004854:  59 8f                subq.l   #$4, a7
  004856:  2f 38 08 88          move.l   $888.w, -(a7)
  00485a:  61 ff 00 00 79 ee    bsr.l    $c24a  ; -> Strip24
  004860:  28 5f                movea.l  (a7)+, a4
  004862:  4a ac 00 18          tst.l    $18(a4)
  004866:  66 16                bne.b    $487e  ; -> L487e
  004868:  20 6c 00 1c          movea.l  $1c(a4), a0
  00486c:  43 ee ff f8          lea.l    -$8(a6), a1
  004870:  20 d9                move.l   (a1)+, (a0)+
  004872:  20 d9                move.l   (a1)+, (a0)+
  004874:  70 00                moveq    #$0, d0
  004876:  29 40 00 40          move.l   d0, $40(a4)
  00487a:  29 40 00 44          move.l   d0, $44(a4)
L487e:
  00487e:  61 ff 00 00 37 90    bsr.l    $8010  ; -> GetA5
  004884:  20 40                movea.l  d0, a0
  004886:  20 50                movea.l  (a0), a0
  004888:  20 50                movea.l  (a0), a0
  00488a:  4a a8 00 5c          tst.l    $5c(a0)
  00488e:  67 5a                beq.b    $48ea  ; -> L48ea
  004890:  48 6e ff f2          pea.l    -$e(a6)
  004894:  48 6e ff ee          pea.l    -$12(a6)
  004898:  2f 0b                move.l   a3, -(a7)
  00489a:  61 ff 00 00 3e 3a    bsr.l    $86d6  ; -> sub_86d6
  0048a0:  1c 00                move.b   d0, d6
  0048a2:  2f 0b                move.l   a3, -(a7)
  0048a4:  2f 2e 00 16          move.l   $16(a6), -(a7)
  0048a8:  2f 2e 00 12          move.l   $12(a6), -(a7)
  0048ac:  2f 2e 00 0e          move.l   $e(a6), -(a7)
  0048b0:  3f 07                move.w   d7, -(a7)
  0048b2:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0048b6:  48 78 11 b0          pea.l    $11b0.w
  0048ba:  61 ff 00 00 24 d6    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0048c0:  58 8f                addq.l   #$4, a7
  0048c2:  2f 00                move.l   d0, -(a7)
  0048c4:  20 5f                movea.l  (a7)+, a0
  0048c6:  4e 90                jsr      (a0)
  0048c8:  4a 06                tst.b    d6
  0048ca:  4f ef 00 0c          lea.l    $c(a7), a7
  0048ce:  67 60                beq.b    $4930  ; -> L4930
  0048d0:  30 2e ff f2          move.w   -$e(a6), d0
  0048d4:  48 c0                ext.l    d0
  0048d6:  2f 00                move.l   d0, -(a7)
  0048d8:  2f 2e ff ee          move.l   -$12(a6), -(a7)
  0048dc:  2f 0b                move.l   a3, -(a7)
  0048de:  61 ff 00 00 3e ba    bsr.l    $879a  ; -> sub_879a
  0048e4:  4f ef 00 0c          lea.l    $c(a7), a7
  0048e8:  60 46                bra.b    $4930  ; -> L4930
L48ea:
  0048ea:  20 54                movea.l  (a4), a0
  0048ec:  20 50                movea.l  (a0), a0
  0048ee:  2d 68 02 14 ff f4    move.l   $214(a0), -$c(a6)
  0048f4:  52 ac 00 18          addq.l   #$1, $18(a4)
  0048f8:  2f 0b                move.l   a3, -(a7)
  0048fa:  2f 2e 00 16          move.l   $16(a6), -(a7)
  0048fe:  2f 2e 00 12          move.l   $12(a6), -(a7)
  004902:  2f 2e 00 0e          move.l   $e(a6), -(a7)
  004906:  3f 07                move.w   d7, -(a7)
  004908:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00490c:  48 78 11 b0          pea.l    $11b0.w
  004910:  61 ff 00 00 24 80    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  004916:  58 8f                addq.l   #$4, a7
  004918:  2f 00                move.l   d0, -(a7)
  00491a:  20 5f                movea.l  (a7)+, a0
  00491c:  4e 90                jsr      (a0)
  00491e:  20 2c 00 18          move.l   $18(a4), d0
  004922:  53 ac 00 18          subq.l   #$1, $18(a4)
  004926:  4a 80                tst.l    d0
  004928:  6e 06                bgt.b    $4930  ; -> L4930
  00492a:  70 00                moveq    #$0, d0
  00492c:  29 40 00 18          move.l   d0, $18(a4)
L4930:
  004930:  4a ac 00 18          tst.l    $18(a4)
  004934:  66 0c                bne.b    $4942  ; -> L4942
  004936:  20 6c 00 1c          movea.l  $1c(a4), a0
  00493a:  43 ee ff f8          lea.l    -$8(a6), a1
  00493e:  20 d9                move.l   (a1)+, (a0)+
  004940:  20 d9                move.l   (a1)+, (a0)+
L4942:
  004942:  4c ee 18 c0 ff de    movem.l  -$22(a6), d6-d7/a3-a4
  004948:  4e 5e                unlk     a6
  00494a:  4e 74 00 16          rtd      #$16
sub_494e:
  00494e:  4e 56 ff fc          link.w   a6, #$fffc
  004952:  48 e7 11 18          movem.l  d3/d7/a3-a4, -(a7)
  004956:  26 6e 00 08          movea.l  $8(a6), a3
  00495a:  20 53                movea.l  (a3), a0
  00495c:  20 3c 00 00 02 00    move.l   #$200, d0
  004962:  c0 a8 00 08          and.l    $8(a0), d0
  004966:  67 04                beq.b    $496c  ; -> L496c
  004968:  70 00                moveq    #$0, d0
  00496a:  60 4e                bra.b    $49ba  ; -> L49ba
L496c:
  00496c:  20 53                movea.l  (a3), a0
  00496e:  4a a8 00 1c          tst.l    $1c(a0)
  004972:  57 c3                seq.b    d3
  004974:  44 03                neg.b    d3
  004976:  08 03 00 00          btst.b   #$0, d3
  00497a:  67 04                beq.b    $4980  ; -> L4980
  00497c:  70 00                moveq    #$0, d0
  00497e:  60 3a                bra.b    $49ba  ; -> L49ba
L4980:
  004980:  20 53                movea.l  (a3), a0
  004982:  20 68 00 0c          movea.l  $c(a0), a0
  004986:  49 e8 06 04          lea.l    $604(a0), a4
  00498a:  2f 0c                move.l   a4, -(a7)
  00498c:  61 ff 00 00 38 2e    bsr.l    $81bc  ; -> sub_81bc
  004992:  2d 4c ff fc          move.l   a4, -$4(a6)
  004996:  70 01                moveq    #$1, d0
  004998:  2f 00                move.l   d0, -(a7)
  00499a:  48 6e ff fc          pea.l    -$4(a6)
  00499e:  72 17                moveq    #$17, d1
  0049a0:  2f 01                move.l   d1, -(a7)
  0049a2:  61 ff 00 00 00 20    bsr.l    $49c4  ; -> EngineDispatch
  0049a8:  2e 00                move.l   d0, d7
  0049aa:  70 01                moveq    #$1, d0
  0049ac:  b0 87                cmp.l    d7, d0
  0049ae:  66 08                bne.b    $49b8  ; -> L49b8
  0049b0:  20 53                movea.l  (a3), a0
  0049b2:  21 6c 00 04 01 82    move.l   $4(a4), $182(a0)
L49b8:
  0049b8:  20 07                move.l   d7, d0
L49ba:
  0049ba:  4c ee 18 88 ff ec    movem.l  -$14(a6), d3/d7/a3-a4
  0049c0:  4e 5e                unlk     a6
  0049c2:  4e 75                rts      
* EngineDispatch  -  the generic accelerator-command dispatcher (called
* ~137x through thin per-command wrappers).  Fetches the globals, walks to
* the device record at globals+$214, checks its ready flags ($8 of the
* device) and issues the command; on a not-ready state it branches to the
* software fallback.
EngineDispatch:
  0049c4:  4e 56 ff 90          link.w   a6, #$ff90
  0049c8:  48 e7 1f 38          movem.l  d3-d7/a2-a4, -(a7)
  0049cc:  70 01                moveq    #$1, d0
  0049ce:  2d 40 ff f4          move.l   d0, -$c(a6)
  0049d2:  59 8f                subq.l   #$4, a7
  0049d4:  2f 38 08 88          move.l   $888.w, -(a7)
  0049d8:  61 ff 00 00 78 70    bsr.l    $c24a  ; -> Strip24
  0049de:  20 5f                movea.l  (a7)+, a0
  0049e0:  20 50                movea.l  (a0), a0
  0049e2:  20 50                movea.l  (a0), a0
  0049e4:  20 68 02 14          movea.l  $214(a0), a0
  0049e8:  2d 48 ff f8          move.l   a0, -$8(a6)
  0049ec:  28 50                movea.l  (a0), a4
  0049ee:  70 27                moveq    #$27, d0
  0049f0:  c0 ac 00 08          and.l    $8(a4), d0
  0049f4:  72 27                moveq    #$27, d1
  0049f6:  b2 80                cmp.l    d0, d1
  0049f8:  66 00 18 2c          bne.w    $6226  ; -> L6226
  0049fc:  20 3c 00 00 06 00    move.l   #$600, d0
  004a02:  c0 ac 00 08          and.l    $8(a4), d0
  004a06:  66 00 18 1e          bne.w    $6226  ; -> L6226
  004a0a:  70 01                moveq    #$1, d0
  004a0c:  c0 ac 00 1c          and.l    $1c(a4), d0
  004a10:  67 08                beq.b    $4a1a  ; -> L4a1a
  004a12:  70 12                moveq    #$12, d0
  004a14:  c0 ac 00 1c          and.l    $1c(a4), d0
  004a18:  67 12                beq.b    $4a2c  ; -> L4a2c
L4a1a:
  004a1a:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  004a1e:  61 ff 00 00 25 2e    bsr.l    $6f4e  ; -> sub_6f4e
  004a24:  4a 80                tst.l    d0
  004a26:  58 4f                addq.w   #$4, a7
  004a28:  66 00 17 fc          bne.w    $6226  ; -> L6226
L4a2c:
  004a2c:  52 ac 01 14          addq.l   #$1, $114(a4)
  004a30:  20 2e 00 08          move.l   $8(a6), d0
  004a34:  04 80 00 00 00 0c    subi.l   #$c, d0
  004a3a:  6b 00 14 14          bmi.w    $5e50  ; -> L5e50
  004a3e:  0c 80 00 00 00 2c    cmpi.l   #$2c, d0
  004a44:  6e 00 14 0a          bgt.w    $5e50  ; -> L5e50
  004a48:  d0 80                add.l    d0, d0
  004a4a:  30 3b 08 06          move.w   $4a52(pc, d0.l), d0
  004a4e:  4e fb 00 00          jmp      $4a50(pc,d0.w)  ; -> L4a50
* jump table (word offsets relative to $4A50, indexed by selector*2):
  004a52:  14 1c                dc.w     $141C    ; case 1 -> L5e6c
  004a54:  14 00                dc.w     $1400    ; case 2 -> L5e50
  004a56:  14 00                dc.w     $1400    ; case 3 -> L5e50
  004a58:  14 00                dc.w     $1400    ; case 4 -> L5e50
  004a5a:  0f cc                dc.w     $0FCC    ; case 5 -> L5a1c
  004a5c:  14 00                dc.w     $1400    ; case 6 -> L5e50
  004a5e:  14 00                dc.w     $1400    ; case 7 -> L5e50
  004a60:  14 00                dc.w     $1400    ; case 8 -> L5e50
  004a62:  14 00                dc.w     $1400    ; case 9 -> L5e50
  004a64:  14 00                dc.w     $1400    ; case 10 -> L5e50
  004a66:  14 00                dc.w     $1400    ; case 11 -> L5e50
  004a68:  14 00                dc.w     $1400    ; case 12 -> L5e50
  004a6a:  00 5c                dc.w     $005C    ; case 13 -> L4aac
  004a6c:  14 00                dc.w     $1400    ; case 14 -> L5e50
  004a6e:  14 00                dc.w     $1400    ; case 15 -> L5e50
  004a70:  14 00                dc.w     $1400    ; case 16 -> L5e50
  004a72:  14 00                dc.w     $1400    ; case 17 -> L5e50
  004a74:  14 00                dc.w     $1400    ; case 18 -> L5e50
  004a76:  14 00                dc.w     $1400    ; case 19 -> L5e50
  004a78:  14 00                dc.w     $1400    ; case 20 -> L5e50
  004a7a:  00 5c                dc.w     $005C    ; case 21 -> L4aac
  004a7c:  00 5c                dc.w     $005C    ; case 22 -> L4aac
  004a7e:  14 00                dc.w     $1400    ; case 23 -> L5e50
  004a80:  00 5c                dc.w     $005C    ; case 24 -> L4aac
  004a82:  00 5c                dc.w     $005C    ; case 25 -> L4aac
  004a84:  14 00                dc.w     $1400    ; case 26 -> L5e50
  004a86:  13 34                dc.w     $1334    ; case 27 -> L5d84
  004a88:  14 00                dc.w     $1400    ; case 28 -> L5e50
  004a8a:  14 00                dc.w     $1400    ; case 29 -> L5e50
  004a8c:  14 00                dc.w     $1400    ; case 30 -> L5e50
  004a8e:  13 d0                dc.w     $13D0    ; case 31 -> L5e20
  004a90:  14 00                dc.w     $1400    ; case 32 -> L5e50
  004a92:  14 1c                dc.w     $141C    ; case 33 -> L5e6c
  004a94:  14 1c                dc.w     $141C    ; case 34 -> L5e6c
  004a96:  00 5c                dc.w     $005C    ; case 35 -> L4aac
  004a98:  00 5c                dc.w     $005C    ; case 36 -> L4aac
  004a9a:  14 1c                dc.w     $141C    ; case 37 -> L5e6c
  004a9c:  00 5c                dc.w     $005C    ; case 38 -> L4aac
  004a9e:  0f 1c                dc.w     $0F1C    ; case 39 -> L596c
  004aa0:  14 00                dc.w     $1400    ; case 40 -> L5e50
  004aa2:  17 9e                dc.w     $179E    ; case 41 -> L61ee
  004aa4:  12 e4                dc.w     $12E4    ; case 42 -> L5d34
  004aa6:  11 b0                dc.w     $11B0    ; case 43 -> L5c00
  004aa8:  10 7c                dc.w     $107C    ; case 44 -> L5acc
  004aaa:  13 90                dc.w     $1390    ; case 45 -> L5de0
L4aac:
  004aac:  42 05                clr.b    d5
  004aae:  42 6e ff aa          clr.w    -$56(a6)
  004ab2:  42 07                clr.b    d7
  004ab4:  42 06                clr.b    d6
  004ab6:  42 6e ff a4          clr.w    -$5c(a6)
  004aba:  42 6e ff a6          clr.w    -$5a(a6)
  004abe:  61 ff 00 00 35 50    bsr.l    $8010  ; -> GetA5
  004ac4:  20 40                movea.l  d0, a0
  004ac6:  20 50                movea.l  (a0), a0
  004ac8:  2d 50 ff d6          move.l   (a0), -$2a(a6)
  004acc:  66 10                bne.b    $4ade  ; -> L4ade
  004ace:  70 14                moveq    #$14, d0
  004ad0:  2f 00                move.l   d0, -(a7)
  004ad2:  61 ff ff ff fd 4e    bsr.l    $4822  ; -> sub_4822
  004ad8:  58 4f                addq.w   #$4, a7
  004ada:  60 00 17 4a          bra.w    $6226  ; -> L6226
L4ade:
  004ade:  20 6e ff d6          movea.l  -$2a(a6), a0
  004ae2:  4a a8 00 5c          tst.l    $5c(a0)
  004ae6:  66 0c                bne.b    $4af4  ; -> L4af4
  004ae8:  4a a8 00 60          tst.l    $60(a0)
  004aec:  66 06                bne.b    $4af4  ; -> L4af4
  004aee:  4a a8 00 64          tst.l    $64(a0)
  004af2:  67 20                beq.b    $4b14  ; -> L4b14
L4af4:
  004af4:  70 02                moveq    #$2, d0
  004af6:  2d 40 ff f4          move.l   d0, -$c(a6)
  004afa:  1d 78 09 38 ff eb    move.b   $938.w, -$15(a6)
  004b00:  20 6e ff d6          movea.l  -$2a(a6), a0
  004b04:  2d 68 00 30 ff ec    move.l   $30(a0), -$14(a6)
  004b0a:  32 28 00 0e          move.w   $e(a0), d1
  004b0e:  48 c1                ext.l    d1
  004b10:  2d 41 ff f0          move.l   d1, -$10(a6)
L4b14:
  004b14:  70 00                moveq    #$0, d0
  004b16:  2d 40 ff bc          move.l   d0, -$44(a6)
  004b1a:  20 6e ff d6          movea.l  -$2a(a6), a0
  004b1e:  22 2c 01 24          move.l   $124(a4), d1
  004b22:  b2 a8 00 1c          cmp.l    $1c(a0), d1
  004b26:  67 14                beq.b    $4b3c  ; -> L4b3c
  004b28:  20 68 00 1c          movea.l  $1c(a0), a0
  004b2c:  20 50                movea.l  (a0), a0
  004b2e:  70 00                moveq    #$0, d0
  004b30:  30 10                move.w   (a0), d0
  004b32:  5a 80                addq.l   #$5, d0
  004b34:  72 fc                moveq    #$fc, d1
  004b36:  c2 80                and.l    d0, d1
  004b38:  d3 ae ff bc          add.l    d1, -$44(a6)
L4b3c:
  004b3c:  20 6e ff d6          movea.l  -$2a(a6), a0
  004b40:  20 2c 01 20          move.l   $120(a4), d0
  004b44:  b0 a8 00 18          cmp.l    $18(a0), d0
  004b48:  67 14                beq.b    $4b5e  ; -> L4b5e
  004b4a:  20 68 00 18          movea.l  $18(a0), a0
  004b4e:  20 50                movea.l  (a0), a0
  004b50:  70 00                moveq    #$0, d0
  004b52:  30 10                move.w   (a0), d0
  004b54:  5a 80                addq.l   #$5, d0
  004b56:  72 fc                moveq    #$fc, d1
  004b58:  c2 80                and.l    d0, d1
  004b5a:  d3 ae ff bc          add.l    d1, -$44(a6)
L4b5e:
  004b5e:  20 2c 00 bc          move.l   $bc(a4), d0
  004b62:  90 bc 00 00 00 90    sub.l    #$90, d0
  004b68:  b0 ae ff bc          cmp.l    -$44(a6), d0
  004b6c:  6c 10                bge.b    $4b7e  ; -> L4b7e
  004b6e:  70 12                moveq    #$12, d0
  004b70:  2f 00                move.l   d0, -(a7)
  004b72:  61 ff ff ff fc ae    bsr.l    $4822  ; -> sub_4822
  004b78:  58 4f                addq.w   #$4, a7
  004b7a:  60 00 16 aa          bra.w    $6226  ; -> L6226
L4b7e:
  004b7e:  20 2e 00 08          move.l   $8(a6), d0
  004b82:  04 80 00 00 00 18    subi.l   #$18, d0
  004b88:  67 00 01 fc          beq.w    $4d86  ; -> L4d86
  004b8c:  51 80                subq.l   #$8, d0
  004b8e:  67 00 01 08          beq.w    $4c98  ; -> L4c98
  004b92:  53 80                subq.l   #$1, d0
  004b94:  67 14                beq.b    $4baa  ; -> L4baa
  004b96:  04 80 00 00 00 0d    subi.l   #$d, d0
  004b9c:  67 00 01 16          beq.w    $4cb4  ; -> L4cb4
  004ba0:  57 80                subq.l   #$3, d0
  004ba2:  67 00 01 2c          beq.w    $4cd0  ; -> L4cd0
  004ba6:  60 00 02 cc          bra.w    $4e74  ; -> L4e74
L4baa:
  004baa:  48 6c 01 0e          pea.l    $10e(a4)
  004bae:  48 6c 01 0a          pea.l    $10a(a4)
  004bb2:  2f 2e ff d6          move.l   -$2a(a6), -(a7)
  004bb6:  61 ff 00 00 41 ec    bsr.l    $8da4  ; -> sub_8da4
  004bbc:  1e 00                move.b   d0, d7
  004bbe:  48 6e ff aa          pea.l    -$56(a6)
  004bc2:  48 6e ff a6          pea.l    -$5a(a6)
  004bc6:  48 6e ff a8          pea.l    -$58(a6)
  004bca:  70 05                moveq    #$5, d0
  004bcc:  2f 00                move.l   d0, -(a7)
  004bce:  61 ff 00 00 42 68    bsr.l    $8e38  ; -> sub_8e38
  004bd4:  70 00                moveq    #$0, d0
  004bd6:  30 2c 00 cc          move.w   $cc(a4), d0
  004bda:  32 2e ff a8          move.w   -$58(a6), d1
  004bde:  48 c1                ext.l    d1
  004be0:  b0 81                cmp.l    d1, d0
  004be2:  4f ef 00 1c          lea.l    $1c(a7), a7
  004be6:  67 02                beq.b    $4bea  ; -> L4bea
  004be8:  7c 01                moveq    #$1, d6
L4bea:
  004bea:  20 6e 00 0c          movea.l  $c(a6), a0
  004bee:  2d 50 ff b8          move.l   (a0), -$48(a6)
  004bf2:  20 2e ff bc          move.l   -$44(a6), d0
  004bf6:  d0 bc 00 00 00 90    add.l    #$90, d0
  004bfc:  22 2e ff b8          move.l   -$48(a6), d1
  004c00:  74 13                moveq    #$13, d2
  004c02:  d2 82                add.l    d2, d1
  004c04:  76 fc                moveq    #$fc, d3
  004c06:  c6 81                and.l    d1, d3
  004c08:  d6 80                add.l    d0, d3
  004c0a:  20 2c 00 bc          move.l   $bc(a4), d0
  004c0e:  90 83                sub.l    d3, d0
  004c10:  b0 ac 00 c0          cmp.l    $c0(a4), d0
  004c14:  6e 00 02 5e          bgt.w    $4e74  ; -> L4e74
  004c18:  70 10                moveq    #$10, d0
  004c1a:  2f 00                move.l   d0, -(a7)
  004c1c:  61 ff ff ff fc 04    bsr.l    $4822  ; -> sub_4822
  004c22:  70 00                moveq    #$0, d0
  004c24:  2d 40 ff bc          move.l   d0, -$44(a6)
  004c28:  20 6e ff d6          movea.l  -$2a(a6), a0
  004c2c:  22 2c 01 24          move.l   $124(a4), d1
  004c30:  b2 a8 00 1c          cmp.l    $1c(a0), d1
  004c34:  58 4f                addq.w   #$4, a7
  004c36:  67 14                beq.b    $4c4c  ; -> L4c4c
  004c38:  20 68 00 1c          movea.l  $1c(a0), a0
  004c3c:  20 50                movea.l  (a0), a0
  004c3e:  70 00                moveq    #$0, d0
  004c40:  30 10                move.w   (a0), d0
  004c42:  5a 80                addq.l   #$5, d0
  004c44:  72 fc                moveq    #$fc, d1
  004c46:  c2 80                and.l    d0, d1
  004c48:  d3 ae ff bc          add.l    d1, -$44(a6)
L4c4c:
  004c4c:  20 6e ff d6          movea.l  -$2a(a6), a0
  004c50:  20 2c 01 20          move.l   $120(a4), d0
  004c54:  b0 a8 00 18          cmp.l    $18(a0), d0
  004c58:  67 14                beq.b    $4c6e  ; -> L4c6e
  004c5a:  20 68 00 18          movea.l  $18(a0), a0
  004c5e:  20 50                movea.l  (a0), a0
  004c60:  70 00                moveq    #$0, d0
  004c62:  30 10                move.w   (a0), d0
  004c64:  5a 80                addq.l   #$5, d0
  004c66:  72 fc                moveq    #$fc, d1
  004c68:  c2 80                and.l    d0, d1
  004c6a:  d3 ae ff bc          add.l    d1, -$44(a6)
L4c6e:
  004c6e:  20 2e ff bc          move.l   -$44(a6), d0
  004c72:  d0 bc 00 00 00 90    add.l    #$90, d0
  004c78:  22 2e ff b8          move.l   -$48(a6), d1
  004c7c:  74 13                moveq    #$13, d2
  004c7e:  d2 82                add.l    d2, d1
  004c80:  76 fc                moveq    #$fc, d3
  004c82:  c6 81                and.l    d1, d3
  004c84:  d6 80                add.l    d0, d3
  004c86:  20 2c 00 bc          move.l   $bc(a4), d0
  004c8a:  90 83                sub.l    d3, d0
  004c8c:  b0 ac 00 c0          cmp.l    $c0(a4), d0
  004c90:  6f 00 15 94          ble.w    $6226  ; -> L6226
  004c94:  60 00 01 de          bra.w    $4e74  ; -> L4e74
L4c98:
  004c98:  48 6c 01 0e          pea.l    $10e(a4)
  004c9c:  48 6c 01 0a          pea.l    $10a(a4)
  004ca0:  2f 2e ff d6          move.l   -$2a(a6), -(a7)
  004ca4:  61 ff 00 00 40 fe    bsr.l    $8da4  ; -> sub_8da4
  004caa:  1e 00                move.b   d0, d7
  004cac:  4f ef 00 0c          lea.l    $c(a7), a7
  004cb0:  60 00 01 c2          bra.w    $4e74  ; -> L4e74
L4cb4:
  004cb4:  20 6e 00 0c          movea.l  $c(a6), a0
  004cb8:  4a a8 00 08          tst.l    $8(a0)
  004cbc:  67 08                beq.b    $4cc6  ; -> L4cc6
  004cbe:  4a a8 00 0c          tst.l    $c(a0)
  004cc2:  66 00 01 b0          bne.w    $4e74  ; -> L4e74
L4cc6:
  004cc6:  70 24                moveq    #$24, d0
  004cc8:  2d 40 00 08          move.l   d0, $8(a6)
  004ccc:  60 00 01 a6          bra.w    $4e74  ; -> L4e74
L4cd0:
  004cd0:  20 2e ff bc          move.l   -$44(a6), d0
  004cd4:  d0 bc 00 00 00 90    add.l    #$90, d0
  004cda:  20 6e 00 0c          movea.l  $c(a6), a0
  004cde:  20 68 00 04          movea.l  $4(a0), a0
  004ce2:  20 50                movea.l  (a0), a0
  004ce4:  72 00                moveq    #$0, d1
  004ce6:  32 10                move.w   (a0), d1
  004ce8:  5e 81                addq.l   #$7, d1
  004cea:  74 fc                moveq    #$fc, d2
  004cec:  c4 81                and.l    d1, d2
  004cee:  d4 80                add.l    d0, d2
  004cf0:  20 2c 00 bc          move.l   $bc(a4), d0
  004cf4:  90 82                sub.l    d2, d0
  004cf6:  b0 ac 00 c0          cmp.l    $c0(a4), d0
  004cfa:  6e 00 01 78          bgt.w    $4e74  ; -> L4e74
  004cfe:  70 06                moveq    #$6, d0
  004d00:  2f 00                move.l   d0, -(a7)
  004d02:  61 ff ff ff fb 1e    bsr.l    $4822  ; -> sub_4822
  004d08:  70 00                moveq    #$0, d0
  004d0a:  2d 40 ff bc          move.l   d0, -$44(a6)
  004d0e:  20 6e ff d6          movea.l  -$2a(a6), a0
  004d12:  22 2c 01 24          move.l   $124(a4), d1
  004d16:  b2 a8 00 1c          cmp.l    $1c(a0), d1
  004d1a:  58 4f                addq.w   #$4, a7
  004d1c:  67 14                beq.b    $4d32  ; -> L4d32
  004d1e:  20 68 00 1c          movea.l  $1c(a0), a0
  004d22:  20 50                movea.l  (a0), a0
  004d24:  70 00                moveq    #$0, d0
  004d26:  30 10                move.w   (a0), d0
  004d28:  5a 80                addq.l   #$5, d0
  004d2a:  72 fc                moveq    #$fc, d1
  004d2c:  c2 80                and.l    d0, d1
  004d2e:  d3 ae ff bc          add.l    d1, -$44(a6)
L4d32:
  004d32:  20 6e ff d6          movea.l  -$2a(a6), a0
  004d36:  20 2c 01 20          move.l   $120(a4), d0
  004d3a:  b0 a8 00 18          cmp.l    $18(a0), d0
  004d3e:  67 14                beq.b    $4d54  ; -> L4d54
  004d40:  20 68 00 18          movea.l  $18(a0), a0
  004d44:  20 50                movea.l  (a0), a0
  004d46:  70 00                moveq    #$0, d0
  004d48:  30 10                move.w   (a0), d0
  004d4a:  5a 80                addq.l   #$5, d0
  004d4c:  72 fc                moveq    #$fc, d1
  004d4e:  c2 80                and.l    d0, d1
  004d50:  d3 ae ff bc          add.l    d1, -$44(a6)
L4d54:
  004d54:  20 2e ff bc          move.l   -$44(a6), d0
  004d58:  d0 bc 00 00 00 90    add.l    #$90, d0
  004d5e:  20 6e 00 0c          movea.l  $c(a6), a0
  004d62:  20 68 00 04          movea.l  $4(a0), a0
  004d66:  20 50                movea.l  (a0), a0
  004d68:  72 00                moveq    #$0, d1
  004d6a:  32 10                move.w   (a0), d1
  004d6c:  5e 81                addq.l   #$7, d1
  004d6e:  74 fc                moveq    #$fc, d2
  004d70:  c4 81                and.l    d1, d2
  004d72:  d4 80                add.l    d0, d2
  004d74:  20 2c 00 bc          move.l   $bc(a4), d0
  004d78:  90 82                sub.l    d2, d0
  004d7a:  b0 ac 00 c0          cmp.l    $c0(a4), d0
  004d7e:  6f 00 14 a6          ble.w    $6226  ; -> L6226
  004d82:  60 00 00 f0          bra.w    $4e74  ; -> L4e74
L4d86:
  004d86:  20 6e 00 0c          movea.l  $c(a6), a0
  004d8a:  20 68 00 04          movea.l  $4(a0), a0
  004d8e:  20 50                movea.l  (a0), a0
  004d90:  70 0a                moveq    #$a, d0
  004d92:  b0 50                cmp.w    (a0), d0
  004d94:  66 2c                bne.b    $4dc2  ; -> L4dc2
  004d96:  70 24                moveq    #$24, d0
  004d98:  2d 40 00 08          move.l   d0, $8(a6)
  004d9c:  20 6e 00 0c          movea.l  $c(a6), a0
  004da0:  20 68 00 04          movea.l  $4(a0), a0
  004da4:  20 10                move.l   (a0), d0
  004da6:  54 80                addq.l   #$2, d0
  004da8:  20 40                movea.l  d0, a0
  004daa:  43 ee ff e2          lea.l    -$1e(a6), a1
  004dae:  70 08                moveq    #$8, d0
  004db0:  a0 2e                dc.w     $a02e  ; _BlockMove
  004db2:  41 ee ff e2          lea.l    -$1e(a6), a0
  004db6:  22 6e 00 0c          movea.l  $c(a6), a1
  004dba:  23 48 00 04          move.l   a0, $4(a1)
  004dbe:  60 00 00 b4          bra.w    $4e74  ; -> L4e74
L4dc2:
  004dc2:  20 2e ff bc          move.l   -$44(a6), d0
  004dc6:  d0 bc 00 00 00 90    add.l    #$90, d0
  004dcc:  20 6e 00 0c          movea.l  $c(a6), a0
  004dd0:  20 68 00 04          movea.l  $4(a0), a0
  004dd4:  20 50                movea.l  (a0), a0
  004dd6:  72 00                moveq    #$0, d1
  004dd8:  32 10                move.w   (a0), d1
  004dda:  5e 81                addq.l   #$7, d1
  004ddc:  74 fc                moveq    #$fc, d2
  004dde:  c4 81                and.l    d1, d2
  004de0:  d4 80                add.l    d0, d2
  004de2:  20 2c 00 bc          move.l   $bc(a4), d0
  004de6:  90 82                sub.l    d2, d0
  004de8:  b0 ac 00 c0          cmp.l    $c0(a4), d0
  004dec:  6e 00 00 86          bgt.w    $4e74  ; -> L4e74
  004df0:  70 15                moveq    #$15, d0
  004df2:  2f 00                move.l   d0, -(a7)
  004df4:  61 ff ff ff fa 2c    bsr.l    $4822  ; -> sub_4822
  004dfa:  70 00                moveq    #$0, d0
  004dfc:  2d 40 ff bc          move.l   d0, -$44(a6)
  004e00:  20 6e ff d6          movea.l  -$2a(a6), a0
  004e04:  22 2c 01 24          move.l   $124(a4), d1
  004e08:  b2 a8 00 1c          cmp.l    $1c(a0), d1
  004e0c:  58 4f                addq.w   #$4, a7
  004e0e:  67 14                beq.b    $4e24  ; -> L4e24
  004e10:  20 68 00 1c          movea.l  $1c(a0), a0
  004e14:  20 50                movea.l  (a0), a0
  004e16:  70 00                moveq    #$0, d0
  004e18:  30 10                move.w   (a0), d0
  004e1a:  5a 80                addq.l   #$5, d0
  004e1c:  72 fc                moveq    #$fc, d1
  004e1e:  c2 80                and.l    d0, d1
  004e20:  d3 ae ff bc          add.l    d1, -$44(a6)
L4e24:
  004e24:  20 6e ff d6          movea.l  -$2a(a6), a0
  004e28:  20 2c 01 20          move.l   $120(a4), d0
  004e2c:  b0 a8 00 18          cmp.l    $18(a0), d0
  004e30:  67 14                beq.b    $4e46  ; -> L4e46
  004e32:  20 68 00 18          movea.l  $18(a0), a0
  004e36:  20 50                movea.l  (a0), a0
  004e38:  70 00                moveq    #$0, d0
  004e3a:  30 10                move.w   (a0), d0
  004e3c:  5a 80                addq.l   #$5, d0
  004e3e:  72 fc                moveq    #$fc, d1
  004e40:  c2 80                and.l    d0, d1
  004e42:  d3 ae ff bc          add.l    d1, -$44(a6)
L4e46:
  004e46:  20 2e ff bc          move.l   -$44(a6), d0
  004e4a:  d0 bc 00 00 00 90    add.l    #$90, d0
  004e50:  20 6e 00 0c          movea.l  $c(a6), a0
  004e54:  20 68 00 04          movea.l  $4(a0), a0
  004e58:  20 50                movea.l  (a0), a0
  004e5a:  72 00                moveq    #$0, d1
  004e5c:  32 10                move.w   (a0), d1
  004e5e:  5e 81                addq.l   #$7, d1
  004e60:  74 fc                moveq    #$fc, d2
  004e62:  c4 81                and.l    d1, d2
  004e64:  d4 80                add.l    d0, d2
  004e66:  20 2c 00 bc          move.l   $bc(a4), d0
  004e6a:  90 82                sub.l    d2, d0
  004e6c:  b0 ac 00 c0          cmp.l    $c0(a4), d0
  004e70:  6f 00 13 b4          ble.w    $6226  ; -> L6226
L4e74:
  004e74:  70 04                moveq    #$4, d0
  004e76:  b0 ac 00 c0          cmp.l    $c0(a4), d0
  004e7a:  6c 40                bge.b    $4ebc  ; -> L4ebc
  004e7c:  20 2e ff d6          move.l   -$2a(a6), d0
  004e80:  b0 ac 00 c8          cmp.l    $c8(a4), d0
  004e84:  67 14                beq.b    $4e9a  ; -> L4e9a
  004e86:  4a ac 00 c8          tst.l    $c8(a4)
  004e8a:  67 0e                beq.b    $4e9a  ; -> L4e9a
  004e8c:  70 08                moveq    #$8, d0
  004e8e:  2f 00                move.l   d0, -(a7)
  004e90:  61 ff ff ff f9 90    bsr.l    $4822  ; -> sub_4822
  004e96:  58 4f                addq.w   #$4, a7
  004e98:  60 22                bra.b    $4ebc  ; -> L4ebc
L4e9a:
  004e9a:  20 2e ff bc          move.l   -$44(a6), d0
  004e9e:  d0 bc 00 00 00 90    add.l    #$90, d0
  004ea4:  22 2c 00 bc          move.l   $bc(a4), d1
  004ea8:  92 80                sub.l    d0, d1
  004eaa:  b2 ac 00 c0          cmp.l    $c0(a4), d1
  004eae:  6e 0c                bgt.b    $4ebc  ; -> L4ebc
  004eb0:  70 09                moveq    #$9, d0
  004eb2:  2f 00                move.l   d0, -(a7)
  004eb4:  61 ff ff ff f9 6c    bsr.l    $4822  ; -> sub_4822
  004eba:  58 4f                addq.w   #$4, a7
L4ebc:
  004ebc:  20 2e ff d6          move.l   -$2a(a6), d0
  004ec0:  b0 ac 00 c8          cmp.l    $c8(a4), d0
  004ec4:  67 00 01 56          beq.w    $501c  ; -> L501c
  004ec8:  20 6c 00 0c          movea.l  $c(a4), a0
  004ecc:  41 e8 01 70          lea.l    $170(a0), a0
  004ed0:  2d 48 ff a0          move.l   a0, -$60(a6)
  004ed4:  70 00                moveq    #$0, d0
  004ed6:  2f 00                move.l   d0, -(a7)
  004ed8:  2f 00                move.l   d0, -(a7)
  004eda:  2f 00                move.l   d0, -(a7)
  004edc:  61 ff ff ff fa e6    bsr.l    $49c4  ; -> EngineDispatch
  004ee2:  2f 2e ff a0          move.l   -$60(a6), -(a7)
  004ee6:  61 ff 00 00 37 26    bsr.l    $860e  ; -> sub_860e
  004eec:  20 6e ff a0          movea.l  -$60(a6), a0
  004ef0:  43 ec 01 18          lea.l    $118(a4), a1
  004ef4:  41 e8 00 14          lea.l    $14(a0), a0
  004ef8:  22 d8                move.l   (a0)+, (a1)+
  004efa:  22 d8                move.l   (a0)+, (a1)+
  004efc:  2d 6e ff a0 ff da    move.l   -$60(a6), -$26(a6)
  004f02:  20 2c 00 ac          move.l   $ac(a4), d0
  004f06:  29 40 00 b4          move.l   d0, $b4(a4)
  004f0a:  58 80                addq.l   #$4, d0
  004f0c:  29 40 00 b0          move.l   d0, $b0(a4)
  004f10:  20 6c 00 ac          movea.l  $ac(a4), a0
  004f14:  30 bc 00 6f          move.w   #$6f, (a0)
  004f18:  70 04                moveq    #$4, d0
  004f1a:  29 40 00 c0          move.l   d0, $c0(a4)
  004f1e:  20 6e ff a0          movea.l  -$60(a6), a0
  004f22:  21 40 00 50          move.l   d0, $50(a0)
  004f26:  20 6e ff a0          movea.l  -$60(a6), a0
  004f2a:  21 6c 00 c4 00 4c    move.l   $c4(a4), $4c(a0)
  004f30:  70 00                moveq    #$0, d0
  004f32:  2f 00                move.l   d0, -(a7)
  004f34:  48 6e ff da          pea.l    -$26(a6)
  004f38:  72 2d                moveq    #$2d, d1
  004f3a:  2f 01                move.l   d1, -(a7)
  004f3c:  61 ff ff ff fa 86    bsr.l    $49c4  ; -> EngineDispatch
  004f42:  39 40 00 ce          move.w   d0, $ce(a4)
  004f46:  70 00                moveq    #$0, d0
  004f48:  30 2c 00 ce          move.w   $ce(a4), d0
  004f4c:  4a 80                tst.l    d0
  004f4e:  08 00 00 00          btst.b   #$0, d0
  004f52:  4f ef 00 1c          lea.l    $1c(a7), a7
  004f56:  67 42                beq.b    $4f9a  ; -> L4f9a
  004f58:  70 00                moveq    #$0, d0
  004f5a:  30 2c 00 ce          move.w   $ce(a4), d0
  004f5e:  72 06                moveq    #$6, d1
  004f60:  c2 40                and.w    d0, d1
  004f62:  70 00                moveq    #$0, d0
  004f64:  30 01                move.w   d1, d0
  004f66:  2d 40 ff da          move.l   d0, -$26(a6)
  004f6a:  29 6e ff d6 00 c8    move.l   -$2a(a6), $c8(a4)
  004f70:  70 01                moveq    #$1, d0
  004f72:  2f 00                move.l   d0, -(a7)
  004f74:  48 6e ff da          pea.l    -$26(a6)
  004f78:  72 36                moveq    #$36, d1
  004f7a:  2f 01                move.l   d1, -(a7)
  004f7c:  61 ff ff ff fa 46    bsr.l    $49c4  ; -> EngineDispatch
  004f82:  70 01                moveq    #$1, d0
  004f84:  2f 00                move.l   d0, -(a7)
  004f86:  48 6e ff da          pea.l    -$26(a6)
  004f8a:  72 37                moveq    #$37, d1
  004f8c:  2f 01                move.l   d1, -(a7)
  004f8e:  61 ff ff ff fa 34    bsr.l    $49c4  ; -> EngineDispatch
  004f94:  4f ef 00 18          lea.l    $18(a7), a7
  004f98:  60 10                bra.b    $4faa  ; -> L4faa
L4f9a:
  004f9a:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  004f9e:  61 ff 00 00 14 10    bsr.l    $63b0  ; -> sub_63b0
  004fa4:  58 4f                addq.w   #$4, a7
  004fa6:  60 00 12 7e          bra.w    $6226  ; -> L6226
L4faa:
  004faa:  7c 01                moveq    #$1, d6
  004fac:  1d 7c 00 01 ff a4    move.b   #$1, -$5c(a6)
  004fb2:  20 6e ff d6          movea.l  -$2a(a6), a0
  004fb6:  29 68 00 30 01 0a    move.l   $30(a0), $10a(a4)
  004fbc:  20 6e ff d6          movea.l  -$2a(a6), a0
  004fc0:  4a 68 00 06          tst.w    $6(a0)
  004fc4:  6c 08                bge.b    $4fce  ; -> L4fce
  004fc6:  30 28 00 0e          move.w   $e(a0), d0
  004fca:  48 c0                ext.l    d0
  004fcc:  60 06                bra.b    $4fd4  ; -> L4fd4
L4fce:
  004fce:  20 3c 00 00 80 00    move.l   #$8000, d0
L4fd4:
  004fd4:  39 40 01 0e          move.w   d0, $10e(a4)
  004fd8:  7e 01                moveq    #$1, d7
  004fda:  48 6c 00 e2          pea.l    $e2(a4)
  004fde:  48 6c 00 dc          pea.l    $dc(a4)
  004fe2:  2f 2c 00 c8          move.l   $c8(a4), -(a7)
  004fe6:  61 ff 00 00 3e 0a    bsr.l    $8df2  ; -> sub_8df2
  004fec:  53 6c 00 dc          subq.w   #$1, $dc(a4)
  004ff0:  53 6c 00 e2          subq.w   #$1, $e2(a4)
  004ff4:  02 6c ff f0 00 f2    andi.w   #$fff0, $f2(a4)
  004ffa:  00 6c 00 0f 00 f2    ori.w    #$f, $f2(a4)
  005000:  61 ff 00 00 30 0e    bsr.l    $8010  ; -> GetA5
  005006:  20 40                movea.l  d0, a0
  005008:  20 10                move.l   (a0), d0
  00500a:  90 bc 00 00 00 ca    sub.l    #$ca, d0
  005010:  20 40                movea.l  d0, a0
  005012:  29 68 00 22 00 e8    move.l   $22(a0), $e8(a4)
  005018:  4f ef 00 0c          lea.l    $c(a7), a7
L501c:
  00501c:  70 21                moveq    #$21, d0
  00501e:  b0 ae 00 08          cmp.l    $8(a6), d0
  005022:  66 00 00 b0          bne.w    $50d4  ; -> L50d4
  005026:  2f 2c 01 82          move.l   $182(a4), -(a7)
  00502a:  48 6c 01 ac          pea.l    $1ac(a4)
  00502e:  48 6c 01 06          pea.l    $106(a4)
  005032:  48 6c 01 92          pea.l    $192(a4)
  005036:  48 6e ff ac          pea.l    -$54(a6)
  00503a:  48 6e ff b4          pea.l    -$4c(a6)
  00503e:  48 6e ff b0          pea.l    -$50(a6)
  005042:  20 6e 00 0c          movea.l  $c(a6), a0
  005046:  20 68 00 0c          movea.l  $c(a0), a0
  00504a:  2f 10                move.l   (a0), -(a7)
  00504c:  20 6e 00 0c          movea.l  $c(a6), a0
  005050:  20 68 00 08          movea.l  $8(a0), a0
  005054:  2f 10                move.l   (a0), -(a7)
  005056:  2f 2e ff b8          move.l   -$48(a6), -(a7)
  00505a:  20 6e 00 0c          movea.l  $c(a6), a0
  00505e:  2f 28 00 04          move.l   $4(a0), -(a7)
  005062:  61 ff 00 00 38 82    bsr.l    $88e6  ; -> sub_88e6
  005068:  2d 40 ff a0          move.l   d0, -$60(a6)
  00506c:  72 ff                moveq    #$ff, d1
  00506e:  b2 80                cmp.l    d0, d1
  005070:  4f ef 00 2c          lea.l    $2c(a7), a7
  005074:  66 10                bne.b    $5086  ; -> L5086
  005076:  70 05                moveq    #$5, d0
  005078:  2f 00                move.l   d0, -(a7)
  00507a:  61 ff ff ff f7 a6    bsr.l    $4822  ; -> sub_4822
  005080:  58 4f                addq.w   #$4, a7
  005082:  60 00 11 a2          bra.w    $6226  ; -> L6226
L5086:
  005086:  70 01                moveq    #$1, d0
  005088:  b0 ae ff a0          cmp.l    -$60(a6), d0
  00508c:  66 06                bne.b    $5094  ; -> L5094
  00508e:  1d 7c 00 01 ff a5    move.b   #$1, -$5b(a6)
L5094:
  005094:  20 2e ff b8          move.l   -$48(a6), d0
  005098:  72 13                moveq    #$13, d1
  00509a:  d0 81                add.l    d1, d0
  00509c:  74 fc                moveq    #$fc, d2
  00509e:  c4 80                and.l    d0, d2
  0050a0:  d4 bc 00 00 00 90    add.l    #$90, d2
  0050a6:  4a 2e ff a5          tst.b    -$5b(a6)
  0050aa:  67 04                beq.b    $50b0  ; -> L50b0
  0050ac:  70 20                moveq    #$20, d0
  0050ae:  60 02                bra.b    $50b2  ; -> L50b2
L50b0:
  0050b0:  70 00                moveq    #$0, d0
L50b2:
  0050b2:  49 c0                extb.l   d0
  0050b4:  d0 82                add.l    d2, d0
  0050b6:  22 2c 00 bc          move.l   $bc(a4), d1
  0050ba:  92 80                sub.l    d0, d1
  0050bc:  b2 ac 00 c0          cmp.l    $c0(a4), d1
  0050c0:  6e 00 00 82          bgt.w    $5144  ; -> L5144
  0050c4:  70 10                moveq    #$10, d0
  0050c6:  2f 00                move.l   d0, -(a7)
  0050c8:  61 ff ff ff f7 58    bsr.l    $4822  ; -> sub_4822
  0050ce:  58 4f                addq.w   #$4, a7
  0050d0:  60 00 11 54          bra.w    $6226  ; -> L6226
L50d4:
  0050d4:  48 6e ff aa          pea.l    -$56(a6)
  0050d8:  48 6e ff a6          pea.l    -$5a(a6)
  0050dc:  48 6e ff a8          pea.l    -$58(a6)
  0050e0:  70 20                moveq    #$20, d0
  0050e2:  b0 ae 00 08          cmp.l    $8(a6), d0
  0050e6:  66 04                bne.b    $50ec  ; -> L50ec
  0050e8:  70 00                moveq    #$0, d0
  0050ea:  60 06                bra.b    $50f2  ; -> L50f2
L50ec:
  0050ec:  20 6e 00 0c          movea.l  $c(a6), a0
  0050f0:  20 10                move.l   (a0), d0
L50f2:
  0050f2:  2f 00                move.l   d0, -(a7)
  0050f4:  61 ff 00 00 3d 42    bsr.l    $8e38  ; -> sub_8e38
  0050fa:  70 00                moveq    #$0, d0
  0050fc:  30 2c 00 cc          move.w   $cc(a4), d0
  005100:  32 2e ff a8          move.w   -$58(a6), d1
  005104:  48 c1                ext.l    d1
  005106:  b0 81                cmp.l    d1, d0
  005108:  4f ef 00 10          lea.l    $10(a7), a7
  00510c:  67 02                beq.b    $5110  ; -> L5110
  00510e:  7c 01                moveq    #$1, d6
L5110:
  005110:  30 2c 00 f2          move.w   $f2(a4), d0
  005114:  c0 7c 00 0f          and.w    #$f, d0
  005118:  72 00                moveq    #$0, d1
  00511a:  32 00                move.w   d0, d1
  00511c:  30 2e ff aa          move.w   -$56(a6), d0
  005120:  48 c0                ext.l    d0
  005122:  b2 80                cmp.l    d0, d1
  005124:  67 06                beq.b    $512c  ; -> L512c
  005126:  1d 7c 00 01 ff a4    move.b   #$1, -$5c(a6)
L512c:
  00512c:  4a 6e ff a6          tst.w    -$5a(a6)
  005130:  67 12                beq.b    $5144  ; -> L5144
  005132:  70 0a                moveq    #$a, d0
  005134:  b0 6e ff a8          cmp.w    -$58(a6), d0
  005138:  67 08                beq.b    $5142  ; -> L5142
  00513a:  70 0e                moveq    #$e, d0
  00513c:  b0 6e ff a8          cmp.w    -$58(a6), d0
  005140:  66 02                bne.b    $5144  ; -> L5144
L5142:
  005142:  7a 01                moveq    #$1, d5
L5144:
  005144:  41 ec 00 ec          lea.l    $ec(a4), a0
  005148:  22 6e ff d6          movea.l  -$2a(a6), a1
  00514c:  43 e9 00 34          lea.l    $34(a1), a1
  005150:  70 00                moveq    #$0, d0
L5152:
  005152:  b1 89                cmpm.l   (a1)+, (a0)+
  005154:  56 c8 ff fc          dbne     d0, $5152  ; -> L5152
  005158:  67 20                beq.b    $517a  ; -> L517a
  00515a:  20 6e ff d6          movea.l  -$2a(a6), a0
  00515e:  2d 68 00 34 ff da    move.l   $34(a0), -$26(a6)
  005164:  70 01                moveq    #$1, d0
  005166:  2f 00                move.l   d0, -(a7)
  005168:  48 6e ff da          pea.l    -$26(a6)
  00516c:  72 35                moveq    #$35, d1
  00516e:  2f 01                move.l   d1, -(a7)
  005170:  61 ff ff ff f8 52    bsr.l    $49c4  ; -> EngineDispatch
  005176:  4f ef 00 0c          lea.l    $c(a7), a7
L517a:
  00517a:  20 6e ff d6          movea.l  -$2a(a6), a0
  00517e:  20 2c 01 24          move.l   $124(a4), d0
  005182:  b0 a8 00 1c          cmp.l    $1c(a0), d0
  005186:  67 1c                beq.b    $51a4  ; -> L51a4
  005188:  2d 68 00 1c ff da    move.l   $1c(a0), -$26(a6)
  00518e:  70 01                moveq    #$1, d0
  005190:  2f 00                move.l   d0, -(a7)
  005192:  48 6e ff da          pea.l    -$26(a6)
  005196:  72 32                moveq    #$32, d1
  005198:  2f 01                move.l   d1, -(a7)
  00519a:  61 ff ff ff f8 28    bsr.l    $49c4  ; -> EngineDispatch
  0051a0:  4f ef 00 0c          lea.l    $c(a7), a7
L51a4:
  0051a4:  20 6e ff d6          movea.l  -$2a(a6), a0
  0051a8:  20 2c 01 20          move.l   $120(a4), d0
  0051ac:  b0 a8 00 18          cmp.l    $18(a0), d0
  0051b0:  67 1c                beq.b    $51ce  ; -> L51ce
  0051b2:  2d 68 00 18 ff da    move.l   $18(a0), -$26(a6)
  0051b8:  70 01                moveq    #$1, d0
  0051ba:  2f 00                move.l   d0, -(a7)
  0051bc:  48 6e ff da          pea.l    -$26(a6)
  0051c0:  72 10                moveq    #$10, d1
  0051c2:  2f 01                move.l   d1, -(a7)
  0051c4:  61 ff ff ff f7 fe    bsr.l    $49c4  ; -> EngineDispatch
  0051ca:  4f ef 00 0c          lea.l    $c(a7), a7
L51ce:
  0051ce:  4a 06                tst.b    d6
  0051d0:  67 2e                beq.b    $5200  ; -> L5200
  0051d2:  20 6c 00 b0          movea.l  $b0(a4), a0
  0051d6:  30 bc 00 69          move.w   #$69, (a0)
  0051da:  20 6c 00 b0          movea.l  $b0(a4), a0
  0051de:  31 6e ff a8 00 02    move.w   -$58(a6), $2(a0)
  0051e4:  39 6e ff a8 00 cc    move.w   -$58(a6), $cc(a4)
  0051ea:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  0051f0:  78 04                moveq    #$4, d4
  0051f2:  20 04                move.l   d4, d0
  0051f4:  d0 ac 00 b0          add.l    $b0(a4), d0
  0051f8:  29 40 00 b0          move.l   d0, $b0(a4)
  0051fc:  d9 ac 00 c0          add.l    d4, $c0(a4)
L5200:
  005200:  70 20                moveq    #$20, d0
  005202:  c0 6e ff a8          and.w    -$58(a6), d0
  005206:  67 00 00 90          beq.w    $5298  ; -> L5298
  00520a:  48 6e ff 9e          pea.l    -$62(a6)
  00520e:  48 6e ff 98          pea.l    -$68(a6)
  005212:  2f 2c 00 c8          move.l   $c8(a4), -(a7)
  005216:  61 ff 00 00 3b da    bsr.l    $8df2  ; -> sub_8df2
  00521c:  41 ec 00 dc          lea.l    $dc(a4), a0
  005220:  43 ee ff 98          lea.l    -$68(a6), a1
  005224:  70 02                moveq    #$2, d0
L5226:
  005226:  b1 49                cmpm.w   (a1)+, (a0)+
  005228:  56 c8 ff fc          dbne     d0, $5226  ; -> L5226
  00522c:  4f ef 00 0c          lea.l    $c(a7), a7
  005230:  66 12                bne.b    $5244  ; -> L5244
  005232:  41 ec 00 e2          lea.l    $e2(a4), a0
  005236:  43 ee ff 9e          lea.l    -$62(a6), a1
  00523a:  70 02                moveq    #$2, d0
L523c:
  00523c:  b1 49                cmpm.w   (a1)+, (a0)+
  00523e:  56 c8 ff fc          dbne     d0, $523c  ; -> L523c
  005242:  67 54                beq.b    $5298  ; -> L5298
L5244:
  005244:  20 6c 00 b0          movea.l  $b0(a4), a0
  005248:  30 bc 00 70          move.w   #$70, (a0)
  00524c:  20 6c 00 b0          movea.l  $b0(a4), a0
  005250:  43 ee ff 98          lea.l    -$68(a6), a1
  005254:  45 e8 00 04          lea.l    $4(a0), a2
  005258:  24 d9                move.l   (a1)+, (a2)+
  00525a:  34 d9                move.w   (a1)+, (a2)+
  00525c:  43 ec 00 dc          lea.l    $dc(a4), a1
  005260:  58 88                addq.l   #$4, a0
  005262:  22 d8                move.l   (a0)+, (a1)+
  005264:  32 d8                move.w   (a0)+, (a1)+
  005266:  20 6c 00 b0          movea.l  $b0(a4), a0
  00526a:  43 ee ff 9e          lea.l    -$62(a6), a1
  00526e:  45 e8 00 0a          lea.l    $a(a0), a2
  005272:  24 d9                move.l   (a1)+, (a2)+
  005274:  34 d9                move.w   (a1)+, (a2)+
  005276:  43 ec 00 e2          lea.l    $e2(a4), a1
  00527a:  41 e8 00 0a          lea.l    $a(a0), a0
  00527e:  22 d8                move.l   (a0)+, (a1)+
  005280:  32 d8                move.w   (a0)+, (a1)+
  005282:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  005288:  78 10                moveq    #$10, d4
  00528a:  20 04                move.l   d4, d0
  00528c:  d0 ac 00 b0          add.l    $b0(a4), d0
  005290:  29 40 00 b0          move.l   d0, $b0(a4)
  005294:  d9 ac 00 c0          add.l    d4, $c0(a4)
L5298:
  005298:  4a 07                tst.b    d7
  00529a:  67 4c                beq.b    $52e8  ; -> L52e8
  00529c:  20 6e ff d6          movea.l  -$2a(a6), a0
  0052a0:  21 6c 01 0a 00 30    move.l   $10a(a4), $30(a0)
  0052a6:  20 6e ff d6          movea.l  -$2a(a6), a0
  0052aa:  4a 68 00 06          tst.w    $6(a0)
  0052ae:  6c 06                bge.b    $52b6  ; -> L52b6
  0052b0:  31 6c 01 0e 00 0e    move.w   $10e(a4), $e(a0)
L52b6:
  0052b6:  20 6c 00 b0          movea.l  $b0(a4), a0
  0052ba:  30 bc 00 68          move.w   #$68, (a0)
  0052be:  20 6c 00 b0          movea.l  $b0(a4), a0
  0052c2:  21 6c 01 0a 00 04    move.l   $10a(a4), $4(a0)
  0052c8:  20 6c 00 b0          movea.l  $b0(a4), a0
  0052cc:  31 6c 01 0e 00 02    move.w   $10e(a4), $2(a0)
  0052d2:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  0052d8:  78 08                moveq    #$8, d4
  0052da:  20 04                move.l   d4, d0
  0052dc:  d0 ac 00 b0          add.l    $b0(a4), d0
  0052e0:  29 40 00 b0          move.l   d0, $b0(a4)
  0052e4:  d9 ac 00 c0          add.l    d4, $c0(a4)
L52e8:
  0052e8:  61 ff 00 00 2d 26    bsr.l    $8010  ; -> GetA5
  0052ee:  20 40                movea.l  d0, a0
  0052f0:  20 10                move.l   (a0), d0
  0052f2:  90 bc 00 00 00 ca    sub.l    #$ca, d0
  0052f8:  20 40                movea.l  d0, a0
  0052fa:  20 2c 00 e8          move.l   $e8(a4), d0
  0052fe:  b0 a8 00 22          cmp.l    $22(a0), d0
  005302:  67 40                beq.b    $5344  ; -> L5344
  005304:  61 ff 00 00 2d 0a    bsr.l    $8010  ; -> GetA5
  00530a:  20 40                movea.l  d0, a0
  00530c:  20 10                move.l   (a0), d0
  00530e:  90 bc 00 00 00 ca    sub.l    #$ca, d0
  005314:  20 40                movea.l  d0, a0
  005316:  29 68 00 22 00 e8    move.l   $22(a0), $e8(a4)
  00531c:  20 6c 00 b0          movea.l  $b0(a4), a0
  005320:  30 bc 00 75          move.w   #$75, (a0)
  005324:  20 6c 00 b0          movea.l  $b0(a4), a0
  005328:  21 6c 00 e8 00 04    move.l   $e8(a4), $4(a0)
  00532e:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  005334:  78 08                moveq    #$8, d4
  005336:  20 04                move.l   d4, d0
  005338:  d0 ac 00 b0          add.l    $b0(a4), d0
  00533c:  29 40 00 b0          move.l   d0, $b0(a4)
  005340:  d9 ac 00 c0          add.l    d4, $c0(a4)
L5344:
  005344:  20 6c 00 c8          movea.l  $c8(a4), a0
  005348:  4a 68 00 06          tst.w    $6(a0)
  00534c:  6c 28                bge.b    $5376  ; -> L5376
  00534e:  30 2e ff aa          move.w   -$56(a6), d0
  005352:  48 c0                ext.l    d0
  005354:  2f 00                move.l   d0, -(a7)
  005356:  2f 08                move.l   a0, -(a7)
  005358:  61 ff 00 00 3d 94    bsr.l    $90ee  ; -> sub_90ee
  00535e:  4a 00                tst.b    d0
  005360:  50 4f                addq.w   #$8, a7
  005362:  66 12                bne.b    $5376  ; -> L5376
  005364:  30 2e ff aa          move.w   -$56(a6), d0
  005368:  72 10                moveq    #$10, d1
  00536a:  e1 a9                lsl.l    d0, d1
  00536c:  83 6c 00 f2          or.w     d1, $f2(a4)
  005370:  1d 7c 00 01 ff a4    move.b   #$1, -$5c(a6)
L5376:
  005376:  4a 2e ff a4          tst.b    -$5c(a6)
  00537a:  67 00 01 e0          beq.w    $555c  ; -> L555c
  00537e:  30 2e ff aa          move.w   -$56(a6), d0
  005382:  72 10                moveq    #$10, d1
  005384:  e1 a9                lsl.l    d0, d1
  005386:  30 2c 00 f2          move.w   $f2(a4), d0
  00538a:  48 c0                ext.l    d0
  00538c:  c0 81                and.l    d1, d0
  00538e:  67 00 01 7a          beq.w    $550a  ; -> L550a
  005392:  48 6c 01 8a          pea.l    $18a(a4)
  005396:  30 2e ff aa          move.w   -$56(a6), d0
  00539a:  48 c0                ext.l    d0
  00539c:  2f 00                move.l   d0, -(a7)
  00539e:  2f 2c 00 c8          move.l   $c8(a4), -(a7)
  0053a2:  61 ff 00 00 3b 60    bsr.l    $8f04  ; -> sub_8f04
  0053a8:  4a 80                tst.l    d0
  0053aa:  4f ef 00 0c          lea.l    $c(a7), a7
  0053ae:  6b 00 01 4a          bmi.w    $54fa  ; -> L54fa
  0053b2:  0c 80 00 00 00 04    cmpi.l   #$4, d0
  0053b8:  6e 00 01 40          bgt.w    $54fa  ; -> L54fa
  0053bc:  d0 80                add.l    d0, d0
  0053be:  30 3b 08 06          move.w   $53c6(pc, d0.l), d0
  0053c2:  4e fb 00 00          jmp      $53c4(pc,d0.w)  ; -> L53c4
* jump table (word offsets relative to $53C4, indexed by selector*2):
  0053c6:  01 46                dc.w     $0146    ; case 1 -> L550a
  0053c8:  00 10                dc.w     $0010    ; case 2 -> L53d4
  0053ca:  00 64                dc.w     $0064    ; case 3 -> L5428
  0053cc:  00 a8                dc.w     $00A8    ; case 4 -> L546c
  0053ce:  00 ee                dc.w     $00EE    ; case 5 -> L54b2
  0053d0:  60 00                dc.w     $6000    ; case 6 -> Lb3c4
  0053d2:  01 38                dc.w     $0138    ; case 7 -> L54fc
L53d4:
  0053d4:  20 6c 00 b0          movea.l  $b0(a4), a0
  0053d8:  30 bc 00 71          move.w   #$71, (a0)
  0053dc:  20 6c 00 b0          movea.l  $b0(a4), a0
  0053e0:  31 6e ff aa 00 02    move.w   -$56(a6), $2(a0)
  0053e6:  20 6c 01 8a          movea.l  $18a(a4), a0
  0053ea:  22 6c 00 b0          movea.l  $b0(a4), a1
  0053ee:  23 50 00 04          move.l   (a0), $4(a1)
  0053f2:  20 6c 01 8a          movea.l  $18a(a4), a0
  0053f6:  22 6c 00 b0          movea.l  $b0(a4), a1
  0053fa:  23 68 00 04 00 08    move.l   $4(a0), $8(a1)
  005400:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  005406:  78 0c                moveq    #$c, d4
  005408:  20 04                move.l   d4, d0
  00540a:  d0 ac 00 b0          add.l    $b0(a4), d0
  00540e:  29 40 00 b0          move.l   d0, $b0(a4)
  005412:  d9 ac 00 c0          add.l    d4, $c0(a4)
  005416:  30 2e ff aa          move.w   -$56(a6), d0
  00541a:  72 10                moveq    #$10, d1
  00541c:  e1 a9                lsl.l    d0, d1
  00541e:  46 81                not.l    d1
  005420:  c3 6c 00 f2          and.w    d1, $f2(a4)
  005424:  60 00 00 e4          bra.w    $550a  ; -> L550a
L5428:
  005428:  20 6c 00 b0          movea.l  $b0(a4), a0
  00542c:  30 bc 00 72          move.w   #$72, (a0)
  005430:  20 6c 00 b0          movea.l  $b0(a4), a0
  005434:  31 6e ff aa 00 02    move.w   -$56(a6), $2(a0)
  00543a:  20 6c 00 b0          movea.l  $b0(a4), a0
  00543e:  21 6c 01 8a 00 04    move.l   $18a(a4), $4(a0)
  005444:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  00544a:  78 08                moveq    #$8, d4
  00544c:  20 04                move.l   d4, d0
  00544e:  d0 ac 00 b0          add.l    $b0(a4), d0
  005452:  29 40 00 b0          move.l   d0, $b0(a4)
  005456:  d9 ac 00 c0          add.l    d4, $c0(a4)
  00545a:  30 2e ff aa          move.w   -$56(a6), d0
  00545e:  72 10                moveq    #$10, d1
  005460:  e1 a9                lsl.l    d0, d1
  005462:  46 81                not.l    d1
  005464:  c3 6c 00 f2          and.w    d1, $f2(a4)
  005468:  60 00 00 a0          bra.w    $550a  ; -> L550a
L546c:
  00546c:  20 6c 00 b0          movea.l  $b0(a4), a0
  005470:  30 bc 00 74          move.w   #$74, (a0)
  005474:  20 6c 00 b0          movea.l  $b0(a4), a0
  005478:  31 6e ff aa 00 04    move.w   -$56(a6), $4(a0)
  00547e:  20 6c 01 8a          movea.l  $18a(a4), a0
  005482:  22 6c 00 b0          movea.l  $b0(a4), a1
  005486:  5c 89                addq.l   #$6, a1
  005488:  22 d8                move.l   (a0)+, (a1)+
  00548a:  32 d8                move.w   (a0)+, (a1)+
  00548c:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  005492:  78 0c                moveq    #$c, d4
  005494:  20 04                move.l   d4, d0
  005496:  d0 ac 00 b0          add.l    $b0(a4), d0
  00549a:  29 40 00 b0          move.l   d0, $b0(a4)
  00549e:  d9 ac 00 c0          add.l    d4, $c0(a4)
  0054a2:  30 2e ff aa          move.w   -$56(a6), d0
  0054a6:  72 10                moveq    #$10, d1
  0054a8:  e1 a9                lsl.l    d0, d1
  0054aa:  46 81                not.l    d1
  0054ac:  c3 6c 00 f2          and.w    d1, $f2(a4)
  0054b0:  60 58                bra.b    $550a  ; -> L550a
L54b2:
  0054b2:  20 6c 00 b0          movea.l  $b0(a4), a0
  0054b6:  30 bc 00 72          move.w   #$72, (a0)
  0054ba:  20 6c 00 b0          movea.l  $b0(a4), a0
  0054be:  31 6e ff aa 00 02    move.w   -$56(a6), $2(a0)
  0054c4:  20 6c 00 b0          movea.l  $b0(a4), a0
  0054c8:  21 6c 01 8a 00 04    move.l   $18a(a4), $4(a0)
  0054ce:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  0054d4:  78 08                moveq    #$8, d4
  0054d6:  20 04                move.l   d4, d0
  0054d8:  d0 ac 00 b0          add.l    $b0(a4), d0
  0054dc:  29 40 00 b0          move.l   d0, $b0(a4)
  0054e0:  d9 ac 00 c0          add.l    d4, $c0(a4)
  0054e4:  30 2e ff aa          move.w   -$56(a6), d0
  0054e8:  72 10                moveq    #$10, d1
  0054ea:  e1 a9                lsl.l    d0, d1
  0054ec:  46 81                not.l    d1
  0054ee:  c3 6c 00 f2          and.w    d1, $f2(a4)
  0054f2:  00 6c 00 02 00 ce    ori.w    #$2, $ce(a4)
  0054f8:  60 10                bra.b    $550a  ; -> L550a
L54fa:
  0054fa:  70 00                moveq    #$0, d0
L54fc:
  0054fc:  2f 00                move.l   d0, -(a7)
  0054fe:  61 ff ff ff f3 22    bsr.l    $4822  ; -> sub_4822
  005504:  58 4f                addq.w   #$4, a7
  005506:  60 00 0d 1e          bra.w    $6226  ; -> L6226
L550a:
  00550a:  4a 6e ff aa          tst.w    -$56(a6)
  00550e:  67 4c                beq.b    $555c  ; -> L555c
  005510:  70 0f                moveq    #$f, d0
  005512:  c0 6c 00 f2          and.w    $f2(a4), d0
  005516:  72 00                moveq    #$0, d1
  005518:  32 00                move.w   d0, d1
  00551a:  30 2e ff aa          move.w   -$56(a6), d0
  00551e:  48 c0                ext.l    d0
  005520:  b2 80                cmp.l    d0, d1
  005522:  67 38                beq.b    $555c  ; -> L555c
  005524:  20 6c 00 b0          movea.l  $b0(a4), a0
  005528:  30 bc 00 73          move.w   #$73, (a0)
  00552c:  20 6c 00 b0          movea.l  $b0(a4), a0
  005530:  31 6e ff aa 00 02    move.w   -$56(a6), $2(a0)
  005536:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  00553c:  78 04                moveq    #$4, d4
  00553e:  20 04                move.l   d4, d0
  005540:  d0 ac 00 b0          add.l    $b0(a4), d0
  005544:  29 40 00 b0          move.l   d0, $b0(a4)
  005548:  d9 ac 00 c0          add.l    d4, $c0(a4)
  00554c:  02 6c ff f0 00 f2    andi.w   #$fff0, $f2(a4)
  005552:  70 0f                moveq    #$f, d0
  005554:  c0 6e ff aa          and.w    -$56(a6), d0
  005558:  81 6c 00 f2          or.w     d0, $f2(a4)
L555c:
  00555c:  20 2e 00 08          move.l   $8(a6), d0
  005560:  04 80 00 00 00 18    subi.l   #$18, d0
  005566:  67 00 01 f0          beq.w    $5758  ; -> L5758
  00556a:  51 80                subq.l   #$8, d0
  00556c:  67 2a                beq.b    $5598  ; -> L5598
  00556e:  53 80                subq.l   #$1, d0
  005570:  67 00 02 d8          beq.w    $584a  ; -> L584a
  005574:  55 80                subq.l   #$2, d0
  005576:  67 00 00 e8          beq.w    $5660  ; -> L5660
  00557a:  53 80                subq.l   #$1, d0
  00557c:  67 00 01 aa          beq.w    $5728  ; -> L5728
  005580:  04 80 00 00 00 0a    subi.l   #$a, d0
  005586:  67 00 01 54          beq.w    $56dc  ; -> L56dc
  00558a:  53 80                subq.l   #$1, d0
  00558c:  67 00 01 1e          beq.w    $56ac  ; -> L56ac
  005590:  55 80                subq.l   #$2, d0
  005592:  67 4e                beq.b    $55e2  ; -> L55e2
  005594:  60 00 0c 90          bra.w    $6226  ; -> L6226
L5598:
  005598:  20 6c 00 b0          movea.l  $b0(a4), a0
  00559c:  30 bc 00 01          move.w   #$1, (a0)
  0055a0:  20 6e 00 0c          movea.l  $c(a6), a0
  0055a4:  20 50                movea.l  (a0), a0
  0055a6:  22 6c 00 b0          movea.l  $b0(a4), a1
  0055aa:  23 50 00 04          move.l   (a0), $4(a1)
  0055ae:  20 6e 00 0c          movea.l  $c(a6), a0
  0055b2:  20 50                movea.l  (a0), a0
  0055b4:  22 6e ff d6          movea.l  -$2a(a6), a1
  0055b8:  23 50 00 30          move.l   (a0), $30(a1)
  0055bc:  20 6e ff d6          movea.l  -$2a(a6), a0
  0055c0:  4a 68 00 06          tst.w    $6(a0)
  0055c4:  6c 06                bge.b    $55cc  ; -> L55cc
  0055c6:  31 7c 80 00 00 0e    move.w   #$8000, $e(a0)
L55cc:
  0055cc:  20 6e 00 0c          movea.l  $c(a6), a0
  0055d0:  20 50                movea.l  (a0), a0
  0055d2:  29 50 01 0a          move.l   (a0), $10a(a4)
  0055d6:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  0055dc:  78 08                moveq    #$8, d4
  0055de:  60 00 03 32          bra.w    $5912  ; -> L5912
L55e2:
  0055e2:  20 6e 00 0c          movea.l  $c(a6), a0
  0055e6:  20 68 00 04          movea.l  $4(a0), a0
  0055ea:  20 50                movea.l  (a0), a0
  0055ec:  70 00                moveq    #$0, d0
  0055ee:  30 10                move.w   (a0), d0
  0055f0:  2d 40 ff 94          move.l   d0, -$6c(a6)
  0055f4:  20 6c 00 b0          movea.l  $b0(a4), a0
  0055f8:  30 bc 00 07          move.w   #$7, (a0)
  0055fc:  20 6c 00 b0          movea.l  $b0(a4), a0
  005600:  31 6e ff a6 00 02    move.w   -$5a(a6), $2(a0)
  005606:  70 00                moveq    #$0, d0
  005608:  30 2e ff 96          move.w   -$6a(a6), d0
  00560c:  5e 80                addq.l   #$7, d0
  00560e:  78 fc                moveq    #$fc, d4
  005610:  c8 80                and.l    d0, d4
  005612:  20 6e 00 0c          movea.l  $c(a6), a0
  005616:  20 68 00 04          movea.l  $4(a0), a0
  00561a:  20 50                movea.l  (a0), a0
  00561c:  22 6c 00 b0          movea.l  $b0(a4), a1
  005620:  58 89                addq.l   #$4, a1
  005622:  20 2e ff 94          move.l   -$6c(a6), d0
  005626:  a0 2e                dc.w     $a02e  ; _BlockMove
  005628:  4a 6e ff a6          tst.w    -$5a(a6)
  00562c:  67 28                beq.b    $5656  ; -> L5656
  00562e:  20 6e 00 0c          movea.l  $c(a6), a0
  005632:  20 50                movea.l  (a0), a0
  005634:  22 6e ff d6          movea.l  -$2a(a6), a1
  005638:  23 50 00 30          move.l   (a0), $30(a1)
  00563c:  20 6e 00 0c          movea.l  $c(a6), a0
  005640:  20 50                movea.l  (a0), a0
  005642:  29 50 01 0a          move.l   (a0), $10a(a4)
  005646:  20 6e ff d6          movea.l  -$2a(a6), a0
  00564a:  4a 68 00 06          tst.w    $6(a0)
  00564e:  6c 06                bge.b    $5656  ; -> L5656
  005650:  31 7c 80 00 00 0e    move.w   #$8000, $e(a0)
L5656:
  005656:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  00565c:  60 00 02 b4          bra.w    $5912  ; -> L5912
L5660:
  005660:  20 6c 00 b0          movea.l  $b0(a4), a0
  005664:  30 bc 00 02          move.w   #$2, (a0)
  005668:  20 6c 00 b0          movea.l  $b0(a4), a0
  00566c:  31 6e ff a6 00 02    move.w   -$5a(a6), $2(a0)
  005672:  20 6e 00 0c          movea.l  $c(a6), a0
  005676:  20 68 00 04          movea.l  $4(a0), a0
  00567a:  22 6c 00 b0          movea.l  $b0(a4), a1
  00567e:  58 89                addq.l   #$4, a1
  005680:  22 d8                move.l   (a0)+, (a1)+
  005682:  22 d8                move.l   (a0)+, (a1)+
  005684:  20 6e 00 0c          movea.l  $c(a6), a0
  005688:  22 6c 00 b0          movea.l  $b0(a4), a1
  00568c:  33 68 00 0a 00 0c    move.w   $a(a0), $c(a1)
  005692:  20 6e 00 0c          movea.l  $c(a6), a0
  005696:  22 6c 00 b0          movea.l  $b0(a4), a1
  00569a:  33 68 00 0e 00 0e    move.w   $e(a0), $e(a1)
  0056a0:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  0056a6:  78 10                moveq    #$10, d4
  0056a8:  60 00 02 68          bra.w    $5912  ; -> L5912
L56ac:
  0056ac:  20 6c 00 b0          movea.l  $b0(a4), a0
  0056b0:  30 bc 00 03          move.w   #$3, (a0)
  0056b4:  20 6c 00 b0          movea.l  $b0(a4), a0
  0056b8:  31 6e ff a6 00 02    move.w   -$5a(a6), $2(a0)
  0056be:  20 6e 00 0c          movea.l  $c(a6), a0
  0056c2:  20 68 00 04          movea.l  $4(a0), a0
  0056c6:  22 6c 00 b0          movea.l  $b0(a4), a1
  0056ca:  58 89                addq.l   #$4, a1
  0056cc:  22 d8                move.l   (a0)+, (a1)+
  0056ce:  22 d8                move.l   (a0)+, (a1)+
  0056d0:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  0056d6:  78 0c                moveq    #$c, d4
  0056d8:  60 00 02 38          bra.w    $5912  ; -> L5912
L56dc:
  0056dc:  20 6c 00 b0          movea.l  $b0(a4), a0
  0056e0:  30 bc 00 04          move.w   #$4, (a0)
  0056e4:  20 6c 00 b0          movea.l  $b0(a4), a0
  0056e8:  31 6e ff a6 00 02    move.w   -$5a(a6), $2(a0)
  0056ee:  20 6e 00 0c          movea.l  $c(a6), a0
  0056f2:  20 68 00 04          movea.l  $4(a0), a0
  0056f6:  22 6c 00 b0          movea.l  $b0(a4), a1
  0056fa:  58 89                addq.l   #$4, a1
  0056fc:  22 d8                move.l   (a0)+, (a1)+
  0056fe:  22 d8                move.l   (a0)+, (a1)+
  005700:  20 6e 00 0c          movea.l  $c(a6), a0
  005704:  22 6c 00 b0          movea.l  $b0(a4), a1
  005708:  33 68 00 0a 00 0c    move.w   $a(a0), $c(a1)
  00570e:  20 6e 00 0c          movea.l  $c(a6), a0
  005712:  22 6c 00 b0          movea.l  $b0(a4), a1
  005716:  33 68 00 0e 00 0e    move.w   $e(a0), $e(a1)
  00571c:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  005722:  78 10                moveq    #$10, d4
  005724:  60 00 01 ec          bra.w    $5912  ; -> L5912
L5728:
  005728:  20 6c 00 b0          movea.l  $b0(a4), a0
  00572c:  30 bc 00 05          move.w   #$5, (a0)
  005730:  20 6c 00 b0          movea.l  $b0(a4), a0
  005734:  31 6e ff a6 00 02    move.w   -$5a(a6), $2(a0)
  00573a:  20 6e 00 0c          movea.l  $c(a6), a0
  00573e:  20 68 00 04          movea.l  $4(a0), a0
  005742:  22 6c 00 b0          movea.l  $b0(a4), a1
  005746:  58 89                addq.l   #$4, a1
  005748:  22 d8                move.l   (a0)+, (a1)+
  00574a:  22 d8                move.l   (a0)+, (a1)+
  00574c:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  005752:  78 0c                moveq    #$c, d4
  005754:  60 00 01 bc          bra.w    $5912  ; -> L5912
L5758:
  005758:  20 6c 00 b0          movea.l  $b0(a4), a0
  00575c:  30 bc 00 08          move.w   #$8, (a0)
  005760:  20 6c 00 b0          movea.l  $b0(a4), a0
  005764:  29 48 00 b4          move.l   a0, $b4(a4)
  005768:  31 6e ff a6 00 02    move.w   -$5a(a6), $2(a0)
  00576e:  67 00 00 a2          beq.w    $5812  ; -> L5812
  005772:  30 2c 00 ec          move.w   $ec(a4), d0
  005776:  48 c0                ext.l    d0
  005778:  2f 00                move.l   d0, -(a7)
  00577a:  30 2c 00 ee          move.w   $ee(a4), d0
  00577e:  48 c0                ext.l    d0
  005780:  2f 00                move.l   d0, -(a7)
  005782:  20 6e 00 0c          movea.l  $c(a6), a0
  005786:  2f 28 00 04          move.l   $4(a0), -(a7)
  00578a:  61 ff 00 00 39 ba    bsr.l    $9146  ; -> sub_9146
  005790:  2d 40 ff 90          move.l   d0, -$70(a6)
  005794:  4f ef 00 0c          lea.l    $c(a7), a7
  005798:  67 68                beq.b    $5802  ; -> L5802
  00579a:  20 6e ff 90          movea.l  -$70(a6), a0
  00579e:  20 50                movea.l  (a0), a0
  0057a0:  70 00                moveq    #$0, d0
  0057a2:  30 10                move.w   (a0), d0
  0057a4:  2d 40 ff 94          move.l   d0, -$6c(a6)
  0057a8:  70 00                moveq    #$0, d0
  0057aa:  30 2e ff 96          move.w   -$6a(a6), d0
  0057ae:  5e 80                addq.l   #$7, d0
  0057b0:  78 fc                moveq    #$fc, d4
  0057b2:  c8 80                and.l    d0, d4
  0057b4:  20 04                move.l   d4, d0
  0057b6:  d0 bc 00 00 00 90    add.l    #$90, d0
  0057bc:  22 2c 00 bc          move.l   $bc(a4), d1
  0057c0:  92 80                sub.l    d0, d1
  0057c2:  b2 ac 00 c0          cmp.l    $c0(a4), d1
  0057c6:  6e 16                bgt.b    $57de  ; -> L57de
  0057c8:  2f 2e ff 90          move.l   -$70(a6), -(a7)
  0057cc:  a8 d9                dc.w     $a8d9  ; _DisposRgn
  0057ce:  70 15                moveq    #$15, d0
  0057d0:  2f 00                move.l   d0, -(a7)
  0057d2:  61 ff ff ff f0 4e    bsr.l    $4822  ; -> sub_4822
  0057d8:  58 4f                addq.w   #$4, a7
  0057da:  60 00 0a 4a          bra.w    $6226  ; -> L6226
L57de:
  0057de:  20 6c 00 b0          movea.l  $b0(a4), a0
  0057e2:  42 68 00 02          clr.w    $2(a0)
  0057e6:  20 6e ff 90          movea.l  -$70(a6), a0
  0057ea:  20 50                movea.l  (a0), a0
  0057ec:  22 6c 00 b0          movea.l  $b0(a4), a1
  0057f0:  58 89                addq.l   #$4, a1
  0057f2:  20 2e ff 94          move.l   -$6c(a6), d0
  0057f6:  a0 2e                dc.w     $a02e  ; _BlockMove
  0057f8:  2f 2e ff 90          move.l   -$70(a6), -(a7)
  0057fc:  a8 d9                dc.w     $a8d9  ; _DisposRgn
  0057fe:  60 00 01 12          bra.w    $5912  ; -> L5912
L5802:
  005802:  70 15                moveq    #$15, d0
  005804:  2f 00                move.l   d0, -(a7)
  005806:  61 ff ff ff f0 1a    bsr.l    $4822  ; -> sub_4822
  00580c:  58 4f                addq.w   #$4, a7
  00580e:  60 00 0a 16          bra.w    $6226  ; -> L6226
L5812:
  005812:  20 6e 00 0c          movea.l  $c(a6), a0
  005816:  20 68 00 04          movea.l  $4(a0), a0
  00581a:  20 50                movea.l  (a0), a0
  00581c:  70 00                moveq    #$0, d0
  00581e:  30 10                move.w   (a0), d0
  005820:  2d 40 ff 94          move.l   d0, -$6c(a6)
  005824:  70 00                moveq    #$0, d0
  005826:  30 2e ff 96          move.w   -$6a(a6), d0
  00582a:  5e 80                addq.l   #$7, d0
  00582c:  78 fc                moveq    #$fc, d4
  00582e:  c8 80                and.l    d0, d4
  005830:  20 6e 00 0c          movea.l  $c(a6), a0
  005834:  20 68 00 04          movea.l  $4(a0), a0
  005838:  20 50                movea.l  (a0), a0
  00583a:  22 6c 00 b0          movea.l  $b0(a4), a1
  00583e:  58 89                addq.l   #$4, a1
  005840:  20 2e ff 94          move.l   -$6c(a6), d0
  005844:  a0 2e                dc.w     $a02e  ; _BlockMove
  005846:  60 00 00 ca          bra.w    $5912  ; -> L5912
L584a:
  00584a:  4a 2e ff a5          tst.b    -$5b(a6)
  00584e:  67 36                beq.b    $5886  ; -> L5886
  005850:  20 6c 00 b0          movea.l  $b0(a4), a0
  005854:  30 bc 00 67          move.w   #$67, (a0)
  005858:  41 ec 01 92          lea.l    $192(a4), a0
  00585c:  22 6c 00 b0          movea.l  $b0(a4), a1
  005860:  54 89                addq.l   #$2, a1
  005862:  70 1a                moveq    #$1a, d0
  005864:  a0 2e                dc.w     $a02e  ; _BlockMove
  005866:  20 6c 00 b0          movea.l  $b0(a4), a0
  00586a:  21 6c 01 06 00 1c    move.l   $106(a4), $1c(a0)
  005870:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  005876:  78 20                moveq    #$20, d4
  005878:  20 04                move.l   d4, d0
  00587a:  d0 ac 00 b0          add.l    $b0(a4), d0
  00587e:  29 40 00 b0          move.l   d0, $b0(a4)
  005882:  d9 ac 00 c0          add.l    d4, $c0(a4)
L5886:
  005886:  70 10                moveq    #$10, d0
  005888:  22 2e ff b4          move.l   -$4c(a6), d1
  00588c:  e0 a1                asr.l    d0, d1
  00588e:  d3 6c 01 0c          add.w    d1, $10c(a4)
  005892:  20 3c 00 00 ff ff    move.l   #$ffff, d0
  005898:  c0 ae ff b4          and.l    -$4c(a6), d0
  00589c:  d1 6c 01 0e          add.w    d0, $10e(a4)
  0058a0:  20 6e ff d6          movea.l  -$2a(a6), a0
  0058a4:  21 6c 01 0a 00 30    move.l   $10a(a4), $30(a0)
  0058aa:  20 6e ff d6          movea.l  -$2a(a6), a0
  0058ae:  4a 68 00 06          tst.w    $6(a0)
  0058b2:  6c 06                bge.b    $58ba  ; -> L58ba
  0058b4:  31 6c 01 0e 00 0e    move.w   $10e(a4), $e(a0)
L58ba:
  0058ba:  20 6c 00 b0          movea.l  $b0(a4), a0
  0058be:  30 bc 00 06          move.w   #$6, (a0)
  0058c2:  20 6c 00 b0          movea.l  $b0(a4), a0
  0058c6:  21 6e ff ac 00 04    move.l   -$54(a6), $4(a0)
  0058cc:  20 6c 00 b0          movea.l  $b0(a4), a0
  0058d0:  21 6e ff b0 00 08    move.l   -$50(a6), $8(a0)
  0058d6:  20 6c 00 b0          movea.l  $b0(a4), a0
  0058da:  21 6e ff b4 00 0c    move.l   -$4c(a6), $c(a0)
  0058e0:  20 6c 00 b0          movea.l  $b0(a4), a0
  0058e4:  31 6e ff ba 00 02    move.w   -$46(a6), $2(a0)
  0058ea:  20 6e 00 0c          movea.l  $c(a6), a0
  0058ee:  20 68 00 04          movea.l  $4(a0), a0
  0058f2:  22 6c 00 b0          movea.l  $b0(a4), a1
  0058f6:  43 e9 00 10          lea.l    $10(a1), a1
  0058fa:  20 2e ff b8          move.l   -$48(a6), d0
  0058fe:  a0 2e                dc.w     $a02e  ; _BlockMove
  005900:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  005906:  20 2e ff b8          move.l   -$48(a6), d0
  00590a:  72 13                moveq    #$13, d1
  00590c:  d0 81                add.l    d1, d0
  00590e:  78 fc                moveq    #$fc, d4
  005910:  c8 80                and.l    d0, d4
L5912:
  005912:  20 04                move.l   d4, d0
  005914:  d0 ac 00 b0          add.l    $b0(a4), d0
  005918:  29 40 00 b0          move.l   d0, $b0(a4)
  00591c:  d9 ac 00 c0          add.l    d4, $c0(a4)
  005920:  29 6c 00 b0 00 b8    move.l   $b0(a4), $b8(a4)
  005926:  4a 05                tst.b    d5
  005928:  67 14                beq.b    $593e  ; -> L593e
  00592a:  70 00                moveq    #$0, d0
  00592c:  2f 00                move.l   d0, -(a7)
  00592e:  2f 00                move.l   d0, -(a7)
  005930:  72 38                moveq    #$38, d1
  005932:  2f 01                move.l   d1, -(a7)
  005934:  61 ff ff ff f0 8e    bsr.l    $49c4  ; -> EngineDispatch
  00593a:  4f ef 00 0c          lea.l    $c(a7), a7
L593e:
  00593e:  70 00                moveq    #$0, d0
  005940:  30 2c 00 ce          move.w   $ce(a4), d0
  005944:  72 0e                moveq    #$e, d1
  005946:  c2 40                and.w    d0, d1
  005948:  67 14                beq.b    $595e  ; -> L595e
  00594a:  70 00                moveq    #$0, d0
  00594c:  2f 00                move.l   d0, -(a7)
  00594e:  2f 00                move.l   d0, -(a7)
  005950:  72 38                moveq    #$38, d1
  005952:  2f 01                move.l   d1, -(a7)
  005954:  61 ff ff ff f0 6e    bsr.l    $49c4  ; -> EngineDispatch
  00595a:  4f ef 00 0c          lea.l    $c(a7), a7
L595e:
  00595e:  20 6c 00 0c          movea.l  $c(a4), a0
  005962:  21 6c 00 c0 01 c0    move.l   $c0(a4), $1c0(a0)
  005968:  60 00 08 84          bra.w    $61ee  ; -> L61ee
L596c:
  00596c:  20 6e 00 0c          movea.l  $c(a6), a0
  005970:  2d 50 ff bc          move.l   (a0), -$44(a6)
  005974:  4a ac 00 c8          tst.l    $c8(a4)
  005978:  67 00 08 74          beq.w    $61ee  ; -> L61ee
  00597c:  4a ae ff bc          tst.l    -$44(a6)
  005980:  67 00 08 6c          beq.w    $61ee  ; -> L61ee
  005984:  20 6e ff bc          movea.l  -$44(a6), a0
  005988:  20 50                movea.l  (a0), a0
  00598a:  70 00                moveq    #$0, d0
  00598c:  30 10                move.w   (a0), d0
  00598e:  5a 80                addq.l   #$5, d0
  005990:  78 fc                moveq    #$fc, d4
  005992:  c8 80                and.l    d0, d4
  005994:  4a 84                tst.l    d4
  005996:  6f 00 04 d4          ble.w    $5e6c  ; -> L5e6c
  00599a:  20 04                move.l   d4, d0
  00599c:  72 24                moveq    #$24, d1
  00599e:  d0 81                add.l    d1, d0
  0059a0:  24 2c 00 bc          move.l   $bc(a4), d2
  0059a4:  94 80                sub.l    d0, d2
  0059a6:  b4 ac 00 c0          cmp.l    $c0(a4), d2
  0059aa:  6e 10                bgt.b    $59bc  ; -> L59bc
  0059ac:  70 12                moveq    #$12, d0
  0059ae:  2f 00                move.l   d0, -(a7)
  0059b0:  61 ff ff ff ee 70    bsr.l    $4822  ; -> sub_4822
  0059b6:  58 4f                addq.w   #$4, a7
  0059b8:  60 00 08 34          bra.w    $61ee  ; -> L61ee
L59bc:
  0059bc:  4a ac 00 b4          tst.l    $b4(a4)
  0059c0:  67 1c                beq.b    $59de  ; -> L59de
  0059c2:  20 6c 00 b4          movea.l  $b4(a4), a0
  0059c6:  70 6a                moveq    #$6a, d0
  0059c8:  b0 50                cmp.w    (a0), d0
  0059ca:  66 12                bne.b    $59de  ; -> L59de
  0059cc:  20 2c 00 b0          move.l   $b0(a4), d0
  0059d0:  90 ac 00 b4          sub.l    $b4(a4), d0
  0059d4:  91 ac 00 c0          sub.l    d0, $c0(a4)
  0059d8:  29 6c 00 b4 00 b0    move.l   $b4(a4), $b0(a4)
L59de:
  0059de:  20 6c 00 b0          movea.l  $b0(a4), a0
  0059e2:  30 bc 00 6a          move.w   #$6a, (a0)
  0059e6:  20 6e ff bc          movea.l  -$44(a6), a0
  0059ea:  20 50                movea.l  (a0), a0
  0059ec:  22 6c 00 b0          movea.l  $b0(a4), a1
  0059f0:  54 89                addq.l   #$2, a1
  0059f2:  24 6e ff bc          movea.l  -$44(a6), a2
  0059f6:  24 52                movea.l  (a2), a2
  0059f8:  70 00                moveq    #$0, d0
  0059fa:  30 12                move.w   (a2), d0
  0059fc:  a0 2e                dc.w     $a02e  ; _BlockMove
  0059fe:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  005a04:  20 04                move.l   d4, d0
  005a06:  d0 ac 00 b0          add.l    $b0(a4), d0
  005a0a:  29 40 00 b0          move.l   d0, $b0(a4)
  005a0e:  d9 ac 00 c0          add.l    d4, $c0(a4)
  005a12:  29 6e ff bc 01 24    move.l   -$44(a6), $124(a4)
  005a18:  60 00 07 d4          bra.w    $61ee  ; -> L61ee
L5a1c:
  005a1c:  20 6e 00 0c          movea.l  $c(a6), a0
  005a20:  2d 50 ff bc          move.l   (a0), -$44(a6)
  005a24:  4a ac 00 c8          tst.l    $c8(a4)
  005a28:  67 00 07 c4          beq.w    $61ee  ; -> L61ee
  005a2c:  4a ae ff bc          tst.l    -$44(a6)
  005a30:  67 00 07 bc          beq.w    $61ee  ; -> L61ee
  005a34:  20 6e ff bc          movea.l  -$44(a6), a0
  005a38:  20 50                movea.l  (a0), a0
  005a3a:  70 00                moveq    #$0, d0
  005a3c:  30 10                move.w   (a0), d0
  005a3e:  5a 80                addq.l   #$5, d0
  005a40:  78 fc                moveq    #$fc, d4
  005a42:  c8 80                and.l    d0, d4
  005a44:  4a 84                tst.l    d4
  005a46:  6f 00 04 24          ble.w    $5e6c  ; -> L5e6c
  005a4a:  20 04                move.l   d4, d0
  005a4c:  72 24                moveq    #$24, d1
  005a4e:  d0 81                add.l    d1, d0
  005a50:  24 2c 00 bc          move.l   $bc(a4), d2
  005a54:  94 80                sub.l    d0, d2
  005a56:  b4 ac 00 c0          cmp.l    $c0(a4), d2
  005a5a:  6e 10                bgt.b    $5a6c  ; -> L5a6c
  005a5c:  70 18                moveq    #$18, d0
  005a5e:  2f 00                move.l   d0, -(a7)
  005a60:  61 ff ff ff ed c0    bsr.l    $4822  ; -> sub_4822
  005a66:  58 4f                addq.w   #$4, a7
  005a68:  60 00 07 84          bra.w    $61ee  ; -> L61ee
L5a6c:
  005a6c:  4a ac 00 b4          tst.l    $b4(a4)
  005a70:  67 1c                beq.b    $5a8e  ; -> L5a8e
  005a72:  20 6c 00 b4          movea.l  $b4(a4), a0
  005a76:  70 6c                moveq    #$6c, d0
  005a78:  b0 50                cmp.w    (a0), d0
  005a7a:  66 12                bne.b    $5a8e  ; -> L5a8e
  005a7c:  20 2c 00 b0          move.l   $b0(a4), d0
  005a80:  90 ac 00 b4          sub.l    $b4(a4), d0
  005a84:  91 ac 00 c0          sub.l    d0, $c0(a4)
  005a88:  29 6c 00 b4 00 b0    move.l   $b4(a4), $b0(a4)
L5a8e:
  005a8e:  20 6c 00 b0          movea.l  $b0(a4), a0
  005a92:  30 bc 00 6c          move.w   #$6c, (a0)
  005a96:  20 6e ff bc          movea.l  -$44(a6), a0
  005a9a:  20 50                movea.l  (a0), a0
  005a9c:  22 6c 00 b0          movea.l  $b0(a4), a1
  005aa0:  54 89                addq.l   #$2, a1
  005aa2:  24 6e ff bc          movea.l  -$44(a6), a2
  005aa6:  24 52                movea.l  (a2), a2
  005aa8:  70 00                moveq    #$0, d0
  005aaa:  30 12                move.w   (a2), d0
  005aac:  a0 2e                dc.w     $a02e  ; _BlockMove
  005aae:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  005ab4:  20 04                move.l   d4, d0
  005ab6:  d0 ac 00 b0          add.l    $b0(a4), d0
  005aba:  29 40 00 b0          move.l   d0, $b0(a4)
  005abe:  d9 ac 00 c0          add.l    d4, $c0(a4)
  005ac2:  29 6e ff bc 01 20    move.l   -$44(a6), $120(a4)
  005ac8:  60 00 07 24          bra.w    $61ee  ; -> L61ee
L5acc:
  005acc:  4a ac 00 c8          tst.l    $c8(a4)
  005ad0:  67 00 01 08          beq.w    $5bda  ; -> L5bda
  005ad4:  20 2c 00 bc          move.l   $bc(a4), d0
  005ad8:  90 bc 00 00 00 90    sub.l    #$90, d0
  005ade:  b0 ac 00 c0          cmp.l    $c0(a4), d0
  005ae2:  6e 10                bgt.b    $5af4  ; -> L5af4
  005ae4:  70 09                moveq    #$9, d0
  005ae6:  2f 00                move.l   d0, -(a7)
  005ae8:  61 ff ff ff ed 38    bsr.l    $4822  ; -> sub_4822
  005aee:  58 4f                addq.w   #$4, a7
  005af0:  60 00 06 fc          bra.w    $61ee  ; -> L61ee
L5af4:
  005af4:  02 6c ff fb 00 ce    andi.w   #$fffb, $ce(a4)
  005afa:  20 6e 00 0c          movea.l  $c(a6), a0
  005afe:  20 10                move.l   (a0), d0
  005b00:  c0 bc 00 00 00 04    and.l    #$4, d0
  005b06:  81 6c 00 ce          or.w     d0, $ce(a4)
  005b0a:  70 00                moveq    #$0, d0
  005b0c:  30 2c 00 ce          move.w   $ce(a4), d0
  005b10:  72 04                moveq    #$4, d1
  005b12:  c2 40                and.w    d0, d1
  005b14:  67 54                beq.b    $5b6a  ; -> L5b6a
  005b16:  20 6c 00 b0          movea.l  $b0(a4), a0
  005b1a:  30 bc 00 6d          move.w   #$6d, (a0)
  005b1e:  20 6c 00 c8          movea.l  $c8(a4), a0
  005b22:  20 68 00 08          movea.l  $8(a0), a0
  005b26:  20 50                movea.l  (a0), a0
  005b28:  22 6c 00 b0          movea.l  $b0(a4), a1
  005b2c:  33 68 00 16 00 0c    move.w   $16(a0), $c(a1)
  005b32:  20 6c 00 c8          movea.l  $c8(a4), a0
  005b36:  22 6c 00 b0          movea.l  $b0(a4), a1
  005b3a:  54 89                addq.l   #$2, a1
  005b3c:  41 e8 00 2a          lea.l    $2a(a0), a0
  005b40:  22 d8                move.l   (a0)+, (a1)+
  005b42:  32 d8                move.w   (a0)+, (a1)+
  005b44:  20 6c 00 c8          movea.l  $c8(a4), a0
  005b48:  22 6c 00 b0          movea.l  $b0(a4), a1
  005b4c:  23 68 00 54 00 08    move.l   $54(a0), $8(a1)
  005b52:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  005b58:  78 10                moveq    #$10, d4
  005b5a:  20 04                move.l   d4, d0
  005b5c:  d0 ac 00 b0          add.l    $b0(a4), d0
  005b60:  29 40 00 b0          move.l   d0, $b0(a4)
  005b64:  d9 ac 00 c0          add.l    d4, $c0(a4)
  005b68:  60 70                bra.b    $5bda  ; -> L5bda
L5b6a:
  005b6a:  20 6c 00 b0          movea.l  $b0(a4), a0
  005b6e:  30 bc 00 6b          move.w   #$6b, (a0)
  005b72:  20 6c 00 c8          movea.l  $c8(a4), a0
  005b76:  4a 68 00 06          tst.w    $6(a0)
  005b7a:  6c 1e                bge.b    $5b9a  ; -> L5b9a
  005b7c:  22 6c 00 b0          movea.l  $b0(a4), a1
  005b80:  23 68 00 54 00 08    move.l   $54(a0), $8(a1)
  005b86:  20 6c 00 c8          movea.l  $c8(a4), a0
  005b8a:  22 6c 00 b0          movea.l  $b0(a4), a1
  005b8e:  54 89                addq.l   #$2, a1
  005b90:  41 e8 00 2a          lea.l    $2a(a0), a0
  005b94:  22 d8                move.l   (a0)+, (a1)+
  005b96:  32 d8                move.w   (a0)+, (a1)+
  005b98:  60 2a                bra.b    $5bc4  ; -> L5bc4
L5b9a:
  005b9a:  20 6c 00 c8          movea.l  $c8(a4), a0
  005b9e:  22 6c 00 b0          movea.l  $b0(a4), a1
  005ba2:  23 68 00 54 00 08    move.l   $54(a0), $8(a1)
  005ba8:  20 6c 00 c8          movea.l  $c8(a4), a0
  005bac:  2f 28 00 54          move.l   $54(a0), -(a7)
  005bb0:  61 ff 00 00 35 cc    bsr.l    $917e  ; -> sub_917e
  005bb6:  20 40                movea.l  d0, a0
  005bb8:  22 6c 00 b0          movea.l  $b0(a4), a1
  005bbc:  54 89                addq.l   #$2, a1
  005bbe:  22 d8                move.l   (a0)+, (a1)+
  005bc0:  32 d8                move.w   (a0)+, (a1)+
  005bc2:  58 4f                addq.w   #$4, a7
L5bc4:
  005bc4:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  005bca:  78 0c                moveq    #$c, d4
  005bcc:  20 04                move.l   d4, d0
  005bce:  d0 ac 00 b0          add.l    $b0(a4), d0
  005bd2:  29 40 00 b0          move.l   d0, $b0(a4)
  005bd6:  d9 ac 00 c0          add.l    d4, $c0(a4)
L5bda:
  005bda:  70 00                moveq    #$0, d0
  005bdc:  30 2c 00 ce          move.w   $ce(a4), d0
  005be0:  72 0e                moveq    #$e, d1
  005be2:  c2 40                and.w    d0, d1
  005be4:  67 00 06 08          beq.w    $61ee  ; -> L61ee
  005be8:  70 00                moveq    #$0, d0
  005bea:  2f 00                move.l   d0, -(a7)
  005bec:  2f 00                move.l   d0, -(a7)
  005bee:  72 38                moveq    #$38, d1
  005bf0:  2f 01                move.l   d1, -(a7)
  005bf2:  61 ff ff ff ed d0    bsr.l    $49c4  ; -> EngineDispatch
  005bf8:  4f ef 00 0c          lea.l    $c(a7), a7
  005bfc:  60 00 05 f0          bra.w    $61ee  ; -> L61ee
L5c00:
  005c00:  4a ac 00 c8          tst.l    $c8(a4)
  005c04:  67 00 01 08          beq.w    $5d0e  ; -> L5d0e
  005c08:  20 2c 00 bc          move.l   $bc(a4), d0
  005c0c:  90 bc 00 00 00 90    sub.l    #$90, d0
  005c12:  b0 ac 00 c0          cmp.l    $c0(a4), d0
  005c16:  6e 10                bgt.b    $5c28  ; -> L5c28
  005c18:  70 09                moveq    #$9, d0
  005c1a:  2f 00                move.l   d0, -(a7)
  005c1c:  61 ff ff ff ec 04    bsr.l    $4822  ; -> sub_4822
  005c22:  58 4f                addq.w   #$4, a7
  005c24:  60 00 05 c8          bra.w    $61ee  ; -> L61ee
L5c28:
  005c28:  02 6c ff fd 00 ce    andi.w   #$fffd, $ce(a4)
  005c2e:  20 6e 00 0c          movea.l  $c(a6), a0
  005c32:  20 10                move.l   (a0), d0
  005c34:  c0 bc 00 00 00 02    and.l    #$2, d0
  005c3a:  81 6c 00 ce          or.w     d0, $ce(a4)
  005c3e:  70 00                moveq    #$0, d0
  005c40:  30 2c 00 ce          move.w   $ce(a4), d0
  005c44:  72 02                moveq    #$2, d1
  005c46:  c2 40                and.w    d0, d1
  005c48:  67 54                beq.b    $5c9e  ; -> L5c9e
  005c4a:  20 6c 00 b0          movea.l  $b0(a4), a0
  005c4e:  30 bc 00 66          move.w   #$66, (a0)
  005c52:  20 6c 00 c8          movea.l  $c8(a4), a0
  005c56:  20 68 00 08          movea.l  $8(a0), a0
  005c5a:  20 50                movea.l  (a0), a0
  005c5c:  22 6c 00 b0          movea.l  $b0(a4), a1
  005c60:  33 68 00 10 00 0c    move.w   $10(a0), $c(a1)
  005c66:  20 6c 00 c8          movea.l  $c8(a4), a0
  005c6a:  22 6c 00 b0          movea.l  $b0(a4), a1
  005c6e:  54 89                addq.l   #$2, a1
  005c70:  41 e8 00 24          lea.l    $24(a0), a0
  005c74:  22 d8                move.l   (a0)+, (a1)+
  005c76:  32 d8                move.w   (a0)+, (a1)+
  005c78:  20 6c 00 c8          movea.l  $c8(a4), a0
  005c7c:  22 6c 00 b0          movea.l  $b0(a4), a1
  005c80:  23 68 00 50 00 08    move.l   $50(a0), $8(a1)
  005c86:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  005c8c:  78 10                moveq    #$10, d4
  005c8e:  20 04                move.l   d4, d0
  005c90:  d0 ac 00 b0          add.l    $b0(a4), d0
  005c94:  29 40 00 b0          move.l   d0, $b0(a4)
  005c98:  d9 ac 00 c0          add.l    d4, $c0(a4)
  005c9c:  60 70                bra.b    $5d0e  ; -> L5d0e
L5c9e:
  005c9e:  20 6c 00 b0          movea.l  $b0(a4), a0
  005ca2:  30 bc 00 64          move.w   #$64, (a0)
  005ca6:  20 6c 00 c8          movea.l  $c8(a4), a0
  005caa:  4a 68 00 06          tst.w    $6(a0)
  005cae:  6c 1e                bge.b    $5cce  ; -> L5cce
  005cb0:  22 6c 00 b0          movea.l  $b0(a4), a1
  005cb4:  23 68 00 50 00 08    move.l   $50(a0), $8(a1)
  005cba:  20 6c 00 c8          movea.l  $c8(a4), a0
  005cbe:  22 6c 00 b0          movea.l  $b0(a4), a1
  005cc2:  54 89                addq.l   #$2, a1
  005cc4:  41 e8 00 24          lea.l    $24(a0), a0
  005cc8:  22 d8                move.l   (a0)+, (a1)+
  005cca:  32 d8                move.w   (a0)+, (a1)+
  005ccc:  60 2a                bra.b    $5cf8  ; -> L5cf8
L5cce:
  005cce:  20 6c 00 c8          movea.l  $c8(a4), a0
  005cd2:  22 6c 00 b0          movea.l  $b0(a4), a1
  005cd6:  23 68 00 50 00 08    move.l   $50(a0), $8(a1)
  005cdc:  20 6c 00 c8          movea.l  $c8(a4), a0
  005ce0:  2f 28 00 50          move.l   $50(a0), -(a7)
  005ce4:  61 ff 00 00 34 98    bsr.l    $917e  ; -> sub_917e
  005cea:  20 40                movea.l  d0, a0
  005cec:  22 6c 00 b0          movea.l  $b0(a4), a1
  005cf0:  54 89                addq.l   #$2, a1
  005cf2:  22 d8                move.l   (a0)+, (a1)+
  005cf4:  32 d8                move.w   (a0)+, (a1)+
  005cf6:  58 4f                addq.w   #$4, a7
L5cf8:
  005cf8:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  005cfe:  78 0c                moveq    #$c, d4
  005d00:  20 04                move.l   d4, d0
  005d02:  d0 ac 00 b0          add.l    $b0(a4), d0
  005d06:  29 40 00 b0          move.l   d0, $b0(a4)
  005d0a:  d9 ac 00 c0          add.l    d4, $c0(a4)
L5d0e:
  005d0e:  70 00                moveq    #$0, d0
  005d10:  30 2c 00 ce          move.w   $ce(a4), d0
  005d14:  72 0e                moveq    #$e, d1
  005d16:  c2 40                and.w    d0, d1
  005d18:  67 00 04 d4          beq.w    $61ee  ; -> L61ee
  005d1c:  70 00                moveq    #$0, d0
  005d1e:  2f 00                move.l   d0, -(a7)
  005d20:  2f 00                move.l   d0, -(a7)
  005d22:  72 38                moveq    #$38, d1
  005d24:  2f 01                move.l   d1, -(a7)
  005d26:  61 ff ff ff ec 9c    bsr.l    $49c4  ; -> EngineDispatch
  005d2c:  4f ef 00 0c          lea.l    $c(a7), a7
  005d30:  60 00 04 bc          bra.w    $61ee  ; -> L61ee
L5d34:
  005d34:  20 2c 00 bc          move.l   $bc(a4), d0
  005d38:  90 bc 00 00 00 90    sub.l    #$90, d0
  005d3e:  b0 ac 00 c0          cmp.l    $c0(a4), d0
  005d42:  6e 0c                bgt.b    $5d50  ; -> L5d50
  005d44:  70 09                moveq    #$9, d0
  005d46:  2f 00                move.l   d0, -(a7)
  005d48:  61 ff ff ff ea d8    bsr.l    $4822  ; -> sub_4822
  005d4e:  58 4f                addq.w   #$4, a7
L5d50:
  005d50:  20 6e 00 0c          movea.l  $c(a6), a0
  005d54:  29 50 00 ec          move.l   (a0), $ec(a4)
  005d58:  20 6c 00 b0          movea.l  $b0(a4), a0
  005d5c:  30 bc 00 6e          move.w   #$6e, (a0)
  005d60:  20 6c 00 b0          movea.l  $b0(a4), a0
  005d64:  21 6c 00 ec 00 04    move.l   $ec(a4), $4(a0)
  005d6a:  29 6c 00 b0 00 b4    move.l   $b0(a4), $b4(a4)
  005d70:  78 08                moveq    #$8, d4
  005d72:  20 04                move.l   d4, d0
  005d74:  d0 ac 00 b0          add.l    $b0(a4), d0
  005d78:  29 40 00 b0          move.l   d0, $b0(a4)
  005d7c:  d9 ac 00 c0          add.l    d4, $c0(a4)
  005d80:  60 00 04 6c          bra.w    $61ee  ; -> L61ee
L5d84:
  005d84:  70 04                moveq    #$4, d0
  005d86:  b0 ac 00 c0          cmp.l    $c0(a4), d0
  005d8a:  6c 20                bge.b    $5dac  ; -> L5dac
  005d8c:  70 00                moveq    #$0, d0
  005d8e:  30 2c 00 ce          move.w   $ce(a4), d0
  005d92:  72 0e                moveq    #$e, d1
  005d94:  c2 40                and.w    d0, d1
  005d96:  67 14                beq.b    $5dac  ; -> L5dac
  005d98:  70 00                moveq    #$0, d0
  005d9a:  2f 00                move.l   d0, -(a7)
  005d9c:  2f 00                move.l   d0, -(a7)
  005d9e:  72 38                moveq    #$38, d1
  005da0:  2f 01                move.l   d1, -(a7)
  005da2:  61 ff ff ff ec 20    bsr.l    $49c4  ; -> EngineDispatch
  005da8:  4f ef 00 0c          lea.l    $c(a7), a7
L5dac:
  005dac:  20 6c 00 ac          movea.l  $ac(a4), a0
  005db0:  30 bc 00 6f          move.w   #$6f, (a0)
  005db4:  41 ee ff da          lea.l    -$26(a6), a0
  005db8:  2d 48 00 0c          move.l   a0, $c(a6)
  005dbc:  70 02                moveq    #$2, d0
  005dbe:  2d 40 00 10          move.l   d0, $10(a6)
  005dc2:  20 ac 00 c4          move.l   $c4(a4), (a0)
  005dc6:  20 6e 00 0c          movea.l  $c(a6), a0
  005dca:  21 6c 00 c0 00 04    move.l   $c0(a4), $4(a0)
  005dd0:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  005dd4:  61 ff 00 00 05 da    bsr.l    $63b0  ; -> sub_63b0
  005dda:  58 4f                addq.w   #$4, a7
  005ddc:  60 00 00 8e          bra.w    $5e6c  ; -> L5e6c
L5de0:
  005de0:  70 04                moveq    #$4, d0
  005de2:  b0 ac 00 c0          cmp.l    $c0(a4), d0
  005de6:  6c 00 00 84          bge.w    $5e6c  ; -> L5e6c
  005dea:  29 6c 00 b0 00 b8    move.l   $b0(a4), $b8(a4)
  005df0:  20 6c 00 ac          movea.l  $ac(a4), a0
  005df4:  30 bc 00 6f          move.w   #$6f, (a0)
  005df8:  20 6c 00 ac          movea.l  $ac(a4), a0
  005dfc:  31 6c 00 f0 00 02    move.w   $f0(a4), $2(a0)
  005e02:  41 ee ff da          lea.l    -$26(a6), a0
  005e06:  2d 48 00 0c          move.l   a0, $c(a6)
  005e0a:  70 02                moveq    #$2, d0
  005e0c:  2d 40 00 10          move.l   d0, $10(a6)
  005e10:  20 ac 00 c4          move.l   $c4(a4), (a0)
  005e14:  20 6e 00 0c          movea.l  $c(a6), a0
  005e18:  21 6c 00 c0 00 04    move.l   $c0(a4), $4(a0)
  005e1e:  60 4c                bra.b    $5e6c  ; -> L5e6c
L5e20:
  005e20:  20 6e 00 0c          movea.l  $c(a6), a0
  005e24:  4a 90                tst.l    (a0)
  005e26:  67 0e                beq.b    $5e36  ; -> L5e36
  005e28:  70 13                moveq    #$13, d0
  005e2a:  2f 00                move.l   d0, -(a7)
  005e2c:  61 ff ff ff e9 f4    bsr.l    $4822  ; -> sub_4822
  005e32:  58 4f 60 36          dc.b     $58,$4f,$60,$36  ; XO`6
L5e36:
  005e36:  20 6e 00 0c          dc.b     $20,$6e,$00,$0c  ;  n..
  005e3a:  20 28 00 04          move.l   $4(a0), d0
  005e3e:  72 10                moveq    #$10, d1
  005e40:  e1 a9                lsl.l    d0, d1
  005e42:  83 6c 00 f2          or.w     d1, $f2(a4)
  005e46:  02 6c ff f0 00 f2    andi.w   #$fff0, $f2(a4)
  005e4c:  60 00 03 a0          bra.w    $61ee  ; -> L61ee
L5e50:
  005e50:  70 04                moveq    #$4, d0
  005e52:  b0 ac 00 c0          cmp.l    $c0(a4), d0
  005e56:  6c 14                bge.b    $5e6c  ; -> L5e6c
  005e58:  20 2e 00 08          move.l   $8(a6), d0
  005e5c:  d0 bc 00 00 01 00    add.l    #$100, d0
  005e62:  2f 00                move.l   d0, -(a7)
  005e64:  61 ff ff ff e9 bc    bsr.l    $4822  ; -> sub_4822
  005e6a:  58 4f                addq.w   #$4, a7
L5e6c:
  005e6c:  70 01                moveq    #$1, d0
  005e6e:  c0 ac 00 1c          and.l    $1c(a4), d0
  005e72:  67 08                beq.b    $5e7c  ; -> L5e7c
  005e74:  70 12                moveq    #$12, d0
  005e76:  c0 ac 00 1c          and.l    $1c(a4), d0
  005e7a:  67 12                beq.b    $5e8e  ; -> L5e8e
L5e7c:
  005e7c:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  005e80:  61 ff 00 00 10 cc    bsr.l    $6f4e  ; -> sub_6f4e
  005e86:  4a 80                tst.l    d0
  005e88:  58 4f                addq.w   #$4, a7
  005e8a:  66 00 03 9a          bne.w    $6226  ; -> L6226
L5e8e:
  005e8e:  70 10                moveq    #$10, d0
  005e90:  c0 ac 00 1c          and.l    $1c(a4), d0
  005e94:  67 2e                beq.b    $5ec4  ; -> L5ec4
  005e96:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  005e9a:  61 ff 00 00 10 b2    bsr.l    $6f4e  ; -> sub_6f4e
  005ea0:  4a 80                tst.l    d0
  005ea2:  58 4f                addq.w   #$4, a7
  005ea4:  67 1e                beq.b    $5ec4  ; -> L5ec4
  005ea6:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  005eaa:  61 ff 00 00 16 c4    bsr.l    $7570  ; -> sub_7570
  005eb0:  4a 80                tst.l    d0
  005eb2:  58 4f                addq.w   #$4, a7
  005eb4:  66 00 03 70          bne.w    $6226  ; -> L6226
  005eb8:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  005ebc:  61 ff 00 00 10 90    bsr.l    $6f4e  ; -> sub_6f4e
  005ec2:  58 4f                addq.w   #$4, a7
L5ec4:
  005ec4:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  005ec8:  61 ff 00 00 03 80    bsr.l    $624a  ; -> sub_624a
  005ece:  72 01                moveq    #$1, d1
  005ed0:  b2 80                cmp.l    d0, d1
  005ed2:  58 4f                addq.w   #$4, a7
  005ed4:  66 00 03 50          bne.w    $6226  ; -> L6226
  005ed8:  70 2d                moveq    #$2d, d0
  005eda:  b0 ae 00 08          cmp.l    $8(a6), d0
  005ede:  66 08                bne.b    $5ee8  ; -> L5ee8
  005ee0:  00 ac 00 00 00 40 00 1c ori.l    #$40, $1c(a4)
L5ee8:
  005ee8:  70 00                moveq    #$0, d0
  005eea:  2d 40 ff c0          move.l   d0, -$40(a6)
  005eee:  72 ff                moveq    #$ff, d1
  005ef0:  2d 41 ff c8          move.l   d1, -$38(a6)
  005ef4:  59 8f                subq.l   #$4, a7
  005ef6:  2f 38 08 88          move.l   $888.w, -(a7)
  005efa:  61 ff 00 00 63 4e    bsr.l    $c24a  ; -> Strip24
  005f00:  2d 5f ff fc          move.l   (a7)+, -$4(a6)
L5f04:
  005f04:  20 6e ff fc          movea.l  -$4(a6), a0
  005f08:  20 68 00 08          movea.l  $8(a0), a0
  005f0c:  4a 90                tst.l    (a0)
  005f0e:  66 f4                bne.b    $5f04  ; -> L5f04
  005f10:  55 8f                subq.l   #$2, a7
  005f12:  70 00                moveq    #$0, d0
  005f14:  1f 00                move.b   d0, -(a7)
  005f16:  61 ff 00 00 61 02    bsr.l    $c01a  ; -> HWPrivProbe
  005f1c:  1d 5f ff cd          move.b   (a7)+, -$33(a6)
  005f20:  2d 6c 00 0c ff d2    move.l   $c(a4), -$2e(a6)
  005f26:  26 6c 00 18          movea.l  $18(a4), a3
  005f2a:  20 6c 00 10          movea.l  $10(a4), a0
  005f2e:  2d 48 ff ce          move.l   a0, -$32(a6)
  005f32:  70 08                moveq    #$8, d0
  005f34:  c0 90                and.l    (a0), d0
  005f36:  67 0c                beq.b    $5f44  ; -> L5f44
  005f38:  00 ac 00 00 00 10 00 1c ori.l    #$10, $1c(a4)
  005f40:  60 00 02 34          bra.w    $6176  ; -> L6176
L5f44:
  005f44:  00 ac 00 00 00 04 00 1c ori.l    #$4, $1c(a4)
  005f4c:  20 6e ff ce          movea.l  -$32(a6), a0
  005f50:  70 00                moveq    #$0, d0
  005f52:  20 80                move.l   d0, (a0)
  005f54:  20 6e ff d2          movea.l  -$2e(a6), a0
  005f58:  21 40 00 18          move.l   d0, $18(a0)
  005f5c:  20 6e ff d2          movea.l  -$2e(a6), a0
  005f60:  21 6e 00 08 00 48    move.l   $8(a6), $48(a0)
  005f66:  20 6e ff d2          movea.l  -$2e(a6), a0
  005f6a:  21 6c 00 20 00 4c    move.l   $20(a4), $4c(a0)
  005f70:  52 ac 00 20          addq.l   #$1, $20(a4)
  005f74:  20 6e ff d2          movea.l  -$2e(a6), a0
  005f78:  21 6e 00 10 00 50    move.l   $10(a6), $50(a0)
  005f7e:  60 54                bra.b    $5fd4  ; -> L5fd4
L5f80:
  005f80:  20 6e 00 0c          movea.l  $c(a6), a0
  005f84:  58 ae 00 0c          addq.l   #$4, $c(a6)
  005f88:  26 d0                move.l   (a0), (a3)+
  005f8a:  20 6e 00 0c          movea.l  $c(a6), a0
  005f8e:  58 ae 00 0c          addq.l   #$4, $c(a6)
  005f92:  26 d0                move.l   (a0), (a3)+
  005f94:  20 6e 00 0c          movea.l  $c(a6), a0
  005f98:  58 ae 00 0c          addq.l   #$4, $c(a6)
  005f9c:  26 d0                move.l   (a0), (a3)+
  005f9e:  20 6e 00 0c          movea.l  $c(a6), a0
  005fa2:  58 ae 00 0c          addq.l   #$4, $c(a6)
  005fa6:  26 d0                move.l   (a0), (a3)+
  005fa8:  20 6e 00 0c          movea.l  $c(a6), a0
  005fac:  58 ae 00 0c          addq.l   #$4, $c(a6)
  005fb0:  26 d0                move.l   (a0), (a3)+
  005fb2:  20 6e 00 0c          movea.l  $c(a6), a0
  005fb6:  58 ae 00 0c          addq.l   #$4, $c(a6)
  005fba:  26 d0                move.l   (a0), (a3)+
  005fbc:  20 6e 00 0c          movea.l  $c(a6), a0
  005fc0:  58 ae 00 0c          addq.l   #$4, $c(a6)
  005fc4:  26 d0                move.l   (a0), (a3)+
  005fc6:  20 6e 00 0c          movea.l  $c(a6), a0
  005fca:  58 ae 00 0c          addq.l   #$4, $c(a6)
  005fce:  26 d0                move.l   (a0), (a3)+
  005fd0:  51 ae 00 10          subq.l   #$8, $10(a6)
L5fd4:
  005fd4:  70 08                moveq    #$8, d0
  005fd6:  b0 ae 00 10          cmp.l    $10(a6), d0
  005fda:  6f a4                ble.b    $5f80  ; -> L5f80
  005fdc:  20 2e 00 10          move.l   $10(a6), d0
  005fe0:  53 80                subq.l   #$1, d0
  005fe2:  6b 66                bmi.b    $604a  ; -> L604a
  005fe4:  0c 80 00 00 00 06    cmpi.l   #$6, d0
  005fea:  6e 5e                bgt.b    $604a  ; -> L604a
  005fec:  d0 80                add.l    d0, d0
  005fee:  30 3b 08 06          move.w   $5ff6(pc, d0.l), d0
* CopyParamsToQueue  -  a Duff's-device unrolled copy: a switch on the
* parameter count jumps into a chain of  move.l (params)+,(queue)+  ,
* appending N argument longs to the card command queue (case 7 = 1 long
* ... case 1 = 7 longs).
CopyParamsToQueue:
  005ff2:  4e fb 00 00          jmp      $5ff4(pc,d0.w)  ; -> L5ff4
* jump table (word offsets relative to $5FF4, indexed by selector*2):
  005ff6:  00 4c                dc.w     $004C    ; case 1 -> L6040
  005ff8:  00 42                dc.w     $0042    ; case 2 -> L6036
  005ffa:  00 38                dc.w     $0038    ; case 3 -> L602c
  005ffc:  00 2e                dc.w     $002E    ; case 4 -> L6022
  005ffe:  00 24                dc.w     $0024    ; case 5 -> L6018
  006000:  00 1a                dc.w     $001A    ; case 6 -> L600e
  006002:  00 10                dc.w     $0010    ; case 7 -> L6004
L6004:
  006004:  20 6e 00 0c          movea.l  $c(a6), a0
  006008:  58 ae 00 0c          addq.l   #$4, $c(a6)
  00600c:  26 d0                move.l   (a0), (a3)+
L600e:
  00600e:  20 6e 00 0c          movea.l  $c(a6), a0
  006012:  58 ae 00 0c          addq.l   #$4, $c(a6)
  006016:  26 d0                move.l   (a0), (a3)+
L6018:
  006018:  20 6e 00 0c          movea.l  $c(a6), a0
  00601c:  58 ae 00 0c          addq.l   #$4, $c(a6)
  006020:  26 d0                move.l   (a0), (a3)+
L6022:
  006022:  20 6e 00 0c          movea.l  $c(a6), a0
  006026:  58 ae 00 0c          addq.l   #$4, $c(a6)
  00602a:  26 d0                move.l   (a0), (a3)+
L602c:
  00602c:  20 6e 00 0c          movea.l  $c(a6), a0
  006030:  58 ae 00 0c          addq.l   #$4, $c(a6)
  006034:  26 d0                move.l   (a0), (a3)+
L6036:
  006036:  20 6e 00 0c          movea.l  $c(a6), a0
  00603a:  58 ae 00 0c          addq.l   #$4, $c(a6)
  00603e:  26 d0                move.l   (a0), (a3)+
L6040:
  006040:  20 6e 00 0c          movea.l  $c(a6), a0
  006044:  58 ae 00 0c          addq.l   #$4, $c(a6)
  006048:  26 d0                move.l   (a0), (a3)+
L604a:
  00604a:  20 6e ff d2          movea.l  -$2e(a6), a0
  00604e:  70 ff                moveq    #$ff, d0
  006050:  21 40 00 14          move.l   d0, $14(a0)
  006054:  00 ac 00 00 00 0c 00 1c ori.l    #$c, $1c(a4)
  00605c:  29 6e 00 08 01 70    move.l   $8(a6), $170(a4)
  006062:  72 00                moveq    #$0, d1
  006064:  32 2c 00 02          move.w   $2(a4), d1
  006068:  d2 b8 01 6a          add.l    $16a.w, d1
  00606c:  2d 41 ff c4          move.l   d1, -$3c(a6)
  006070:  60 00 00 9c          bra.w    $610e  ; -> L610e
L6074:
  006074:  20 6e ff ce          movea.l  -$32(a6), a0
  006078:  70 18                moveq    #$18, d0
  00607a:  c0 90                and.l    (a0), d0
  00607c:  67 1a                beq.b    $6098  ; -> L6098
  00607e:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  006082:  61 ff 00 00 0e ca    bsr.l    $6f4e  ; -> sub_6f4e
  006088:  4a 80                tst.l    d0
  00608a:  58 4f                addq.w   #$4, a7
  00608c:  67 0a                beq.b    $6098  ; -> L6098
  00608e:  70 00                moveq    #$0, d0
  006090:  2d 40 ff c8          move.l   d0, -$38(a6)
  006094:  60 00 00 e0          bra.w    $6176  ; -> L6176
L6098:
  006098:  20 6e ff ce          movea.l  -$32(a6), a0
  00609c:  70 04                moveq    #$4, d0
  00609e:  c0 90                and.l    (a0), d0
  0060a0:  67 24                beq.b    $60c6  ; -> L60c6
  0060a2:  02 90 ff ff ff fb    andi.l   #$fffffffb, (a0)
  0060a8:  48 6c 00 24          pea.l    $24(a4)
  0060ac:  2f 2e ff d2          move.l   -$2e(a6), -(a7)
  0060b0:  61 ff 00 00 03 90    bsr.l    $6442  ; -> sub_6442
  0060b6:  70 00                moveq    #$0, d0
  0060b8:  30 2c 00 02          move.w   $2(a4), d0
  0060bc:  d0 b8 01 6a          add.l    $16a.w, d0
  0060c0:  2d 40 ff c4          move.l   d0, -$3c(a6)
  0060c4:  50 4f                addq.w   #$8, a7
L60c6:
  0060c6:  20 38 01 6a          move.l   $16a.w, d0
  0060ca:  b0 ae ff c4          cmp.l    -$3c(a6), d0
  0060ce:  6f 3e                ble.b    $610e  ; -> L610e
  0060d0:  20 6c 00 0c          movea.l  $c(a4), a0
  0060d4:  20 28 01 c4          move.l   $1c4(a0), d0
  0060d8:  b0 ae ff c0          cmp.l    -$40(a6), d0
  0060dc:  67 16                beq.b    $60f4  ; -> L60f4
  0060de:  2d 68 01 c4 ff c0    move.l   $1c4(a0), -$40(a6)
  0060e4:  70 00                moveq    #$0, d0
  0060e6:  30 2c 00 02          move.w   $2(a4), d0
  0060ea:  d0 b8 01 6a          add.l    $16a.w, d0
  0060ee:  2d 40 ff c4          move.l   d0, -$3c(a6)
  0060f2:  60 1a                bra.b    $610e  ; -> L610e
L60f4:
  0060f4:  70 00                moveq    #$0, d0
  0060f6:  2f 00                move.l   d0, -(a7)
  0060f8:  72 02                moveq    #$2, d1
  0060fa:  2f 01                move.l   d1, -(a7)
  0060fc:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  006100:  61 ff 00 00 14 fc    bsr.l    $75fe  ; -> sub_75fe
  006106:  4f ef 00 0c          lea.l    $c(a7), a7
  00610a:  60 00 00 a4          bra.w    $61b0  ; -> L61b0
L610e:
  00610e:  20 6e ff ce          movea.l  -$32(a6), a0
  006112:  70 03                moveq    #$3, d0
  006114:  c0 90                and.l    (a0), d0
  006116:  67 00 ff 5c          beq.w    $6074  ; -> L6074
  00611a:  70 04                moveq    #$4, d0
  00611c:  c0 90                and.l    (a0), d0
  00611e:  67 16                beq.b    $6136  ; -> L6136
  006120:  02 90 ff ff ff fb    andi.l   #$fffffffb, (a0)
  006126:  48 6c 00 24          pea.l    $24(a4)
  00612a:  2f 2e ff d2          move.l   -$2e(a6), -(a7)
  00612e:  61 ff 00 00 03 12    bsr.l    $6442  ; -> sub_6442
  006134:  50 4f                addq.w   #$8, a7
L6136:
  006136:  70 26                moveq    #$26, d0
  006138:  b0 ae 00 08          cmp.l    $8(a6), d0
  00613c:  66 14                bne.b    $6152  ; -> L6152
  00613e:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  006142:  61 ff 00 00 02 6c    bsr.l    $63b0  ; -> sub_63b0
  006148:  02 ac ff ff ff bf 00 1c andi.l   #$ffffffbf, $1c(a4)
  006150:  58 4f                addq.w   #$4, a7
L6152:
  006152:  02 ac ff ff ff f7 00 1c andi.l   #$fffffff7, $1c(a4)
  00615a:  20 6e ff ce          movea.l  -$32(a6), a0
  00615e:  70 02                moveq    #$2, d0
  006160:  c0 90                and.l    (a0), d0
  006162:  67 08                beq.b    $616c  ; -> L616c
  006164:  02 ac ff ff ff fb 00 1c andi.l   #$fffffffb, $1c(a4)
L616c:
  00616c:  20 6e ff d2          movea.l  -$2e(a6), a0
  006170:  2d 68 00 1c ff c8    move.l   $1c(a0), -$38(a6)
L6176:
  006176:  20 6e ff fc          movea.l  -$4(a6), a0
  00617a:  20 68 00 08          movea.l  $8(a0), a0
  00617e:  4a 90                tst.l    (a0)
  006180:  66 f4                bne.b    $6176  ; -> L6176
  006182:  55 8f                subq.l   #$2, a7
  006184:  1f 2e ff cd          move.b   -$33(a6), -(a7)
  006188:  61 ff 00 00 5e 90    bsr.l    $c01a  ; -> HWPrivProbe
  00618e:  53 ac 01 14          subq.l   #$1, $114(a4)
  006192:  4a ac 01 14          tst.l    $114(a4)
  006196:  54 4f                addq.w   #$2, a7
  006198:  6e 06                bgt.b    $61a0  ; -> L61a0
  00619a:  70 00                moveq    #$0, d0
  00619c:  29 40 01 14          move.l   d0, $114(a4)
L61a0:
  0061a0:  02 ac ff ff ff f7 00 1c andi.l   #$fffffff7, $1c(a4)
  0061a8:  20 2e ff c8          move.l   -$38(a6), d0
  0061ac:  60 00 00 92          bra.w    $6240  ; -> L6240
L61b0:
  0061b0:  20 6e ff fc          movea.l  -$4(a6), a0
  0061b4:  20 68 00 08          movea.l  $8(a0), a0
  0061b8:  4a 90                tst.l    (a0)
  0061ba:  66 f4                bne.b    $61b0  ; -> L61b0
  0061bc:  55 8f                subq.l   #$2, a7
  0061be:  1f 2e ff cd          move.b   -$33(a6), -(a7)
  0061c2:  61 ff 00 00 5e 56    bsr.l    $c01a  ; -> HWPrivProbe
  0061c8:  53 ac 01 14          subq.l   #$1, $114(a4)
  0061cc:  4a ac 01 14          tst.l    $114(a4)
  0061d0:  54 4f                addq.w   #$2, a7
  0061d2:  6e 06                bgt.b    $61da  ; -> L61da
  0061d4:  70 00                moveq    #$0, d0
  0061d6:  29 40 01 14          move.l   d0, $114(a4)
L61da:
  0061da:  02 ac ff ff ff f3 00 1c andi.l   #$fffffff3, $1c(a4)
  0061e2:  00 ac 00 00 00 02 00 1c ori.l    #$2, $1c(a4)
  0061ea:  70 00                moveq    #$0, d0
  0061ec:  60 52                bra.b    $6240  ; -> L6240
L61ee:
  0061ee:  53 ac 01 14          subq.l   #$1, $114(a4)
  0061f2:  4a ac 01 14          tst.l    $114(a4)
  0061f6:  6e 06                bgt.b    $61fe  ; -> L61fe
  0061f8:  70 00                moveq    #$0, d0
  0061fa:  29 40 01 14          move.l   d0, $114(a4)
L61fe:
  0061fe:  70 02                moveq    #$2, d0
  006200:  b0 ae ff f4          cmp.l    -$c(a6), d0
  006204:  66 1a                bne.b    $6220  ; -> L6220
  006206:  11 ee ff eb 09 38    move.b   -$15(a6), $938.w
  00620c:  20 6e ff d6          movea.l  -$2a(a6), a0
  006210:  21 6e ff ec 00 30    move.l   -$14(a6), $30(a0)
  006216:  20 6e ff d6          movea.l  -$2a(a6), a0
  00621a:  31 6e ff f2 00 0e    move.w   -$e(a6), $e(a0)
L6220:
  006220:  20 2e ff f4          move.l   -$c(a6), d0
  006224:  60 1a                bra.b    $6240  ; -> L6240
L6226:
  006226:  53 ac 01 14          subq.l   #$1, $114(a4)
  00622a:  4a ac 01 14          tst.l    $114(a4)
  00622e:  6e 06                bgt.b    $6236  ; -> L6236
  006230:  70 00                moveq    #$0, d0
  006232:  29 40 01 14          move.l   d0, $114(a4)
L6236:
  006236:  02 ac ff ff ff f7 00 1c andi.l   #$fffffff7, $1c(a4)
  00623e:  70 00                moveq    #$0, d0
L6240:
  006240:  4c ee 1c f8 ff 70    movem.l  -$90(a6), d3-d7/a2-a4
  006246:  4e 5e                unlk     a6
  006248:  4e 75                rts      
sub_624a:
  00624a:  4e 56 ff f8          link.w   a6, #$fff8
  00624e:  48 e7 07 18          movem.l  d5-d7/a3-a4, -(a7)
  006252:  7a 00                moveq    #$0, d5
  006254:  7c ff                moveq    #$ff, d6
  006256:  59 8f                subq.l   #$4, a7
  006258:  2f 38 08 88          move.l   $888.w, -(a7)
  00625c:  61 ff 00 00 5f ec    bsr.l    $c24a  ; -> Strip24
  006262:  28 5f                movea.l  (a7)+, a4
L6264:
  006264:  20 6c 00 08          movea.l  $8(a4), a0
  006268:  4a 90                tst.l    (a0)
  00626a:  66 f8                bne.b    $6264  ; -> L6264
  00626c:  55 8f                subq.l   #$2, a7
  00626e:  70 00                moveq    #$0, d0
  006270:  1f 00                move.b   d0, -(a7)
  006272:  61 ff 00 00 5d a6    bsr.l    $c01a  ; -> HWPrivProbe
  006278:  1c 1f                move.b   (a7)+, d6
  00627a:  20 6e 00 08          movea.l  $8(a6), a0
  00627e:  26 50                movea.l  (a0), a3
  006280:  2d 6b 00 0c ff fc    move.l   $c(a3), -$4(a6)
  006286:  2d 6b 00 10 ff f8    move.l   $10(a3), -$8(a6)
  00628c:  70 00                moveq    #$0, d0
  00628e:  30 2b 00 02          move.w   $2(a3), d0
  006292:  2e 00                move.l   d0, d7
  006294:  de b8 01 6a          add.l    $16a.w, d7
  006298:  60 00 00 a8          bra.w    $6342  ; -> L6342
L629c:
  00629c:  20 6e ff f8          movea.l  -$8(a6), a0
  0062a0:  70 18                moveq    #$18, d0
  0062a2:  c0 90                and.l    (a0), d0
  0062a4:  67 2a                beq.b    $62d0  ; -> L62d0
  0062a6:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0062aa:  61 ff 00 00 0c a2    bsr.l    $6f4e  ; -> sub_6f4e
  0062b0:  4a 80                tst.l    d0
  0062b2:  58 4f                addq.w   #$4, a7
  0062b4:  67 1a                beq.b    $62d0  ; -> L62d0
L62b6:
  0062b6:  20 6c 00 08          movea.l  $8(a4), a0
  0062ba:  4a 90                tst.l    (a0)
  0062bc:  66 f8                bne.b    $62b6  ; -> L62b6
  0062be:  55 8f                subq.l   #$2, a7
  0062c0:  1f 06                move.b   d6, -(a7)
  0062c2:  61 ff 00 00 5d 56    bsr.l    $c01a  ; -> HWPrivProbe
  0062c8:  70 00                moveq    #$0, d0
  0062ca:  54 4f                addq.w   #$2, a7
  0062cc:  60 00 00 d8          bra.w    $63a6  ; -> L63a6
L62d0:
  0062d0:  20 6e ff f8          movea.l  -$8(a6), a0
  0062d4:  70 04                moveq    #$4, d0
  0062d6:  c0 90                and.l    (a0), d0
  0062d8:  67 22                beq.b    $62fc  ; -> L62fc
  0062da:  02 90 ff ff ff fb    andi.l   #$fffffffb, (a0)
  0062e0:  48 6b 00 24          pea.l    $24(a3)
  0062e4:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  0062e8:  61 ff 00 00 01 58    bsr.l    $6442  ; -> sub_6442
  0062ee:  70 00                moveq    #$0, d0
  0062f0:  30 2b 00 02          move.w   $2(a3), d0
  0062f4:  2e 00                move.l   d0, d7
  0062f6:  de b8 01 6a          add.l    $16a.w, d7
  0062fa:  50 4f                addq.w   #$8, a7
L62fc:
  0062fc:  be b8 01 6a          cmp.l    $16a.w, d7
  006300:  6c 40                bge.b    $6342  ; -> L6342
  006302:  20 6b 00 0c          movea.l  $c(a3), a0
  006306:  ba a8 01 c4          cmp.l    $1c4(a0), d5
  00630a:  67 12                beq.b    $631e  ; -> L631e
  00630c:  2a 28 01 c4          move.l   $1c4(a0), d5
  006310:  70 00                moveq    #$0, d0
  006312:  30 2b 00 02          move.w   $2(a3), d0
  006316:  2e 00                move.l   d0, d7
  006318:  de b8 01 6a          add.l    $16a.w, d7
  00631c:  60 24                bra.b    $6342  ; -> L6342
L631e:
  00631e:  37 7c 00 02 01 5c    move.w   #$2, $15c(a3)
L6324:
  006324:  20 6c 00 08          movea.l  $8(a4), a0
  006328:  4a 90                tst.l    (a0)
  00632a:  66 f8                bne.b    $6324  ; -> L6324
  00632c:  55 8f                subq.l   #$2, a7
  00632e:  1f 06                move.b   d6, -(a7)
  006330:  61 ff 00 00 5c e8    bsr.l    $c01a  ; -> HWPrivProbe
  006336:  70 00                moveq    #$0, d0
  006338:  27 40 05 e0          move.l   d0, $5e0(a3)
  00633c:  70 ff                moveq    #$ff, d0
  00633e:  54 4f                addq.w   #$2, a7
  006340:  60 64                bra.b    $63a6  ; -> L63a6
L6342:
  006342:  20 6e ff f8          movea.l  -$8(a6), a0
  006346:  70 02                moveq    #$2, d0
  006348:  c0 90                and.l    (a0), d0
  00634a:  67 00 ff 50          beq.w    $629c  ; -> L629c
  00634e:  70 04                moveq    #$4, d0
  006350:  c0 90                and.l    (a0), d0
  006352:  67 16                beq.b    $636a  ; -> L636a
  006354:  02 90 ff ff ff fb    andi.l   #$fffffffb, (a0)
  00635a:  48 6b 00 24          pea.l    $24(a3)
  00635e:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  006362:  61 ff 00 00 00 de    bsr.l    $6442  ; -> sub_6442
  006368:  50 4f                addq.w   #$8, a7
L636a:
  00636a:  02 ab ff ff ff fb 00 1c andi.l   #$fffffffb, $1c(a3)
L6372:
  006372:  20 6c 00 08          movea.l  $8(a4), a0
  006376:  4a 90                tst.l    (a0)
  006378:  66 f8                bne.b    $6372  ; -> L6372
  00637a:  55 8f                subq.l   #$2, a7
  00637c:  1f 06                move.b   d6, -(a7)
  00637e:  61 ff 00 00 5c 9a    bsr.l    $c01a  ; -> HWPrivProbe
  006384:  4a ab 05 e0          tst.l    $5e0(a3)
  006388:  54 4f                addq.w   #$2, a7
  00638a:  67 18                beq.b    $63a4  ; -> L63a4
  00638c:  20 6e 00 08          movea.l  $8(a6), a0
  006390:  20 50                movea.l  (a0), a0
  006392:  20 68 00 0c          movea.l  $c(a0), a0
  006396:  22 6b 05 e0          movea.l  $5e0(a3), a1
  00639a:  22 a8 00 1c          move.l   $1c(a0), (a1)
  00639e:  70 00                moveq    #$0, d0
  0063a0:  27 40 05 e0          move.l   d0, $5e0(a3)
L63a4:
  0063a4:  70 01                moveq    #$1, d0
L63a6:
  0063a6:  4c ee 18 e0 ff e4    movem.l  -$1c(a6), d5-d7/a3-a4
  0063ac:  4e 5e                unlk     a6
  0063ae:  4e 75                rts      
sub_63b0:
  0063b0:  4e 56 00 00          link.w   a6, #$0
  0063b4:  2f 0c                move.l   a4, -(a7)
  0063b6:  20 6e 00 08          movea.l  $8(a6), a0
  0063ba:  28 50                movea.l  (a0), a4
  0063bc:  4a ac 00 ac          tst.l    $ac(a4)
  0063c0:  67 78                beq.b    $643a  ; -> L643a
  0063c2:  29 6c 00 c0 01 86    move.l   $c0(a4), $186(a4)
  0063c8:  70 00                moveq    #$0, d0
  0063ca:  29 40 00 b4          move.l   d0, $b4(a4)
  0063ce:  29 6c 00 ac 00 b0    move.l   $ac(a4), $b0(a4)
  0063d4:  29 6c 00 b0 00 b8    move.l   $b0(a4), $b8(a4)
  0063da:  29 40 00 c0          move.l   d0, $c0(a4)
  0063de:  29 40 00 c8          move.l   d0, $c8(a4)
  0063e2:  39 7c ff ff 00 cc    move.w   #$ffff, $cc(a4)
  0063e8:  39 7c ff ff 00 ee    move.w   #$ffff, $ee(a4)
  0063ee:  39 7c ff ff 00 ec    move.w   #$ffff, $ec(a4)
  0063f4:  29 40 01 02          move.l   d0, $102(a4)
  0063f8:  29 40 01 06          move.l   d0, $106(a4)
  0063fc:  72 ff                moveq    #$ff, d1
  0063fe:  29 41 01 94          move.l   d1, $194(a4)
  006402:  29 41 01 ac          move.l   d1, $1ac(a4)
  006406:  29 40 01 20          move.l   d0, $120(a4)
  00640a:  29 40 01 24          move.l   d0, $124(a4)
  00640e:  20 6c 00 ac          movea.l  $ac(a4), a0
  006412:  30 bc 00 6f          move.w   #$6f, (a0)
  006416:  70 04                moveq    #$4, d0
  006418:  29 40 00 c0          move.l   d0, $c0(a4)
  00641c:  24 2c 00 ac          move.l   $ac(a4), d2
  006420:  58 82                addq.l   #$4, d2
  006422:  29 42 00 b0          move.l   d2, $b0(a4)
  006426:  70 00                moveq    #$0, d0
  006428:  29 40 01 70          move.l   d0, $170(a4)
  00642c:  39 7c ff ff 00 f2    move.w   #$ffff, $f2(a4)
  006432:  29 40 01 10          move.l   d0, $110(a4)
  006436:  42 6c 00 f0          clr.w    $f0(a4)
L643a:
  00643a:  28 6e ff fc          movea.l  -$4(a6), a4
  00643e:  4e 5e                unlk     a6
  006440:  4e 75                rts      
sub_6442:
  006442:  4e 56 ff 68          link.w   a6, #$ff68
  006446:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  00644a:  1d 7c 00 01 ff 85    move.b   #$1, -$7b(a6)
  006450:  20 6e 00 08          movea.l  $8(a6), a0
  006454:  41 e8 00 24          lea.l    $24(a0), a0
  006458:  2d 48 ff 86          move.l   a0, -$7a(a6)
  00645c:  59 8f                subq.l   #$4, a7
  00645e:  2f 38 08 88          move.l   $888.w, -(a7)
  006462:  61 ff 00 00 5d e6    bsr.l    $c24a  ; -> Strip24
  006468:  2d 5f ff fc          move.l   (a7)+, -$4(a6)
L646c:
  00646c:  20 6e ff fc          movea.l  -$4(a6), a0
  006470:  20 68 00 08          movea.l  $8(a0), a0
  006474:  4a 90                tst.l    (a0)
  006476:  66 f4                bne.b    $646c  ; -> L646c
  006478:  55 8f                subq.l   #$2, a7
  00647a:  70 00                moveq    #$0, d0
  00647c:  1f 00                move.b   d0, -(a7)
  00647e:  61 ff 00 00 5b 9a    bsr.l    $c01a  ; -> HWPrivProbe
  006484:  1d 5f ff 8b          move.b   (a7)+, -$75(a6)
  006488:  20 6e ff 86          movea.l  -$7a(a6), a0
  00648c:  20 3c 00 0f ff ff    move.l   #$fffff, d0
  006492:  c0 a8 00 14          and.l    $14(a0), d0
  006496:  22 3c ff f0 00 00    move.l   #$fff00000, d1
  00649c:  c2 ae 00 08          and.l    $8(a6), d1
  0064a0:  82 80                or.l     d0, d1
  0064a2:  2d 41 ff 80          move.l   d1, -$80(a6)
  0064a6:  20 6e ff 86          movea.l  -$7a(a6), a0
  0064aa:  70 00                moveq    #$0, d0
  0064ac:  21 40 00 08          move.l   d0, $8(a0)
  0064b0:  20 6e 00 08          movea.l  $8(a6), a0
  0064b4:  02 a8 ff ff ff fb 00 18 andi.l   #$fffffffb, $18(a0)
  0064bc:  20 6e ff 86          movea.l  -$7a(a6), a0
  0064c0:  2d 68 00 04 ff f8    move.l   $4(a0), -$8(a6)
  0064c6:  72 ff                moveq    #$ff, d1
  0064c8:  21 41 00 04          move.l   d1, $4(a0)
  0064cc:  74 64                moveq    #$64, d2
  0064ce:  b4 ae ff f8          cmp.l    -$8(a6), d2
  0064d2:  67 32                beq.b    $6506  ; -> L6506
  0064d4:  20 6e 00 0c          movea.l  $c(a6), a0
  0064d8:  22 6e ff 86          movea.l  -$7a(a6), a1
  0064dc:  20 10                move.l   (a0), d0
  0064de:  b0 a9 00 0c          cmp.l    $c(a1), d0
  0064e2:  67 22                beq.b    $6506  ; -> L6506
  0064e4:  20 49                movea.l  a1, a0
  0064e6:  70 ff                moveq    #$ff, d0
  0064e8:  21 40 00 08          move.l   d0, $8(a0)
  0064ec:  20 6e ff 86          movea.l  -$7a(a6), a0
  0064f0:  72 00                moveq    #$0, d1
  0064f2:  21 41 00 04          move.l   d1, $4(a0)
  0064f6:  20 6e ff 86          movea.l  -$7a(a6), a0
  0064fa:  22 6e 00 0c          movea.l  $c(a6), a1
  0064fe:  22 a8 00 0c          move.l   $c(a0), (a1)
  006502:  60 00 07 48          bra.w    $6c4c  ; -> L6c4c
L6506:
  006506:  20 2e ff f8          move.l   -$8(a6), d0
  00650a:  67 00 07 40          beq.w    $6c4c  ; -> L6c4c
  00650e:  57 80                subq.l   #$3, d0
  006510:  67 00 01 d0          beq.w    $66e2  ; -> L66e2
  006514:  53 80                subq.l   #$1, d0
  006516:  67 00 01 de          beq.w    $66f6  ; -> L66f6
  00651a:  53 80                subq.l   #$1, d0
  00651c:  67 00 01 e4          beq.w    $6702  ; -> L6702
  006520:  53 80                subq.l   #$1, d0
  006522:  67 00 01 f2          beq.w    $6716  ; -> L6716
  006526:  53 80                subq.l   #$1, d0
  006528:  67 00 02 00          beq.w    $672a  ; -> L672a
  00652c:  53 80                subq.l   #$1, d0
  00652e:  67 00 00 a8          beq.w    $65d8  ; -> L65d8
  006532:  59 80                subq.l   #$4, d0
  006534:  67 00 01 76          beq.w    $66ac  ; -> L66ac
  006538:  53 80                subq.l   #$1, d0
  00653a:  67 00 02 5e          beq.w    $679a  ; -> L679a
  00653e:  53 80                subq.l   #$1, d0
  006540:  67 00 03 66          beq.w    $68a8  ; -> L68a8
  006544:  53 80                subq.l   #$1, d0
  006546:  67 00 04 ce          beq.w    $6a16  ; -> L6a16
  00654a:  53 80                subq.l   #$1, d0
  00654c:  67 00 04 be          beq.w    $6a0c  ; -> L6a0c
  006550:  53 80                subq.l   #$1, d0
  006552:  67 00 01 f0          beq.w    $6744  ; -> L6744
  006556:  53 80                subq.l   #$1, d0
  006558:  67 72                beq.b    $65cc  ; -> L65cc
  00655a:  55 80                subq.l   #$2, d0
  00655c:  67 00 06 32          beq.w    $6b90  ; -> L6b90
  006560:  53 80                subq.l   #$1, d0
  006562:  67 00 00 ba          beq.w    $661e  ; -> L661e
  006566:  53 80                subq.l   #$1, d0
  006568:  67 00 03 f6          beq.w    $6960  ; -> L6960
  00656c:  04 80 00 00 00 4e    subi.l   #$4e, d0
  006572:  67 42                beq.b    $65b6  ; -> L65b6
  006574:  04 80 00 00 03 83    subi.l   #$383, d0
  00657a:  66 00 06 d0          bne.w    $6c4c  ; -> L6c4c
  00657e:  59 8f                subq.l   #$4, a7
  006580:  2f 38 08 88          move.l   $888.w, -(a7)
  006584:  61 ff 00 00 5c c4    bsr.l    $c24a  ; -> Strip24
  00658a:  20 5f                movea.l  (a7)+, a0
  00658c:  20 50                movea.l  (a0), a0
  00658e:  20 50                movea.l  (a0), a0
  006590:  2d 48 ff 72          move.l   a0, -$8e(a6)
  006594:  48 68 0a a0          pea.l    $aa0(a0)
  006598:  2f 2e ff 80          move.l   -$80(a6), -(a7)
  00659c:  48 78 03 e7          pea.l    $3e7.w
  0065a0:  61 ff ff ff ae 62    bsr.l    $1404  ; -> sub_1404
  0065a6:  20 6e ff 86          movea.l  -$7a(a6), a0
  0065aa:  21 40 00 08          move.l   d0, $8(a0)
  0065ae:  4f ef 00 0c          lea.l    $c(a7), a7
  0065b2:  60 00 06 88          bra.w    $6c3c  ; -> L6c3c
L65b6:
  0065b6:  20 6e 00 0c          movea.l  $c(a6), a0
  0065ba:  70 00                moveq    #$0, d0
  0065bc:  20 80                move.l   d0, (a0)
  0065be:  20 6e ff 86          movea.l  -$7a(a6), a0
  0065c2:  72 01                moveq    #$1, d1
  0065c4:  21 41 00 08          move.l   d1, $8(a0)
  0065c8:  60 00 06 72          bra.w    $6c3c  ; -> L6c3c
L65cc:
  0065cc:  20 6e ff 80          movea.l  -$80(a6), a0
  0065d0:  20 68 00 04          movea.l  $4(a0), a0
  0065d4:  28 50                movea.l  (a0), a4
  0065d6:  60 08                bra.b    $65e0  ; -> L65e0
L65d8:
  0065d8:  20 6e ff 80          movea.l  -$80(a6), a0
  0065dc:  28 68 00 04          movea.l  $4(a0), a4
L65e0:
  0065e0:  59 8f                subq.l   #$4, a7
  0065e2:  2f 0c                move.l   a4, -(a7)
  0065e4:  61 ff 00 00 5c 64    bsr.l    $c24a  ; -> Strip24
  0065ea:  28 5f                movea.l  (a7)+, a4
  0065ec:  4a 38 0c b2          tst.b    $cb2.w
  0065f0:  66 1c                bne.b    $660e  ; -> L660e
  0065f2:  20 0c                move.l   a4, d0
  0065f4:  22 3c 00 f0 00 00    move.l   #$f00000, d1
  0065fa:  c2 80                and.l    d0, d1
  0065fc:  0c 81 00 80 00 00    cmpi.l   #$800000, d1
  006602:  66 0a                bne.b    $660e  ; -> L660e
  006604:  20 0c                move.l   a4, d0
  006606:  00 80 40 00 00 00    ori.l    #$40000000, d0
  00660c:  28 40                movea.l  d0, a4
L660e:
  00660e:  20 6e ff 86          movea.l  -$7a(a6), a0
  006612:  21 4c 00 08          move.l   a4, $8(a0)
  006616:  20 6e ff 80          movea.l  -$80(a6), a0
  00661a:  26 50                movea.l  (a0), a3
  00661c:  60 22                bra.b    $6640  ; -> L6640
L661e:
  00661e:  20 6e ff 80          movea.l  -$80(a6), a0
  006622:  20 50                movea.l  (a0), a0
  006624:  26 50                movea.l  (a0), a3
  006626:  59 8f                subq.l   #$4, a7
  006628:  2f 0b                move.l   a3, -(a7)
  00662a:  61 ff 00 00 5c 1e    bsr.l    $c24a  ; -> Strip24
  006630:  26 5f                movea.l  (a7)+, a3
  006632:  20 0b                move.l   a3, d0
  006634:  67 00 06 06          beq.w    $6c3c  ; -> L6c3c
  006638:  20 6e ff 80          movea.l  -$80(a6), a0
  00663c:  28 68 00 04          movea.l  $4(a0), a4
L6640:
  006640:  20 6e ff 80          movea.l  -$80(a6), a0
  006644:  2e 28 00 08          move.l   $8(a0), d7
  006648:  1d 7c 00 01 ff 85    move.b   #$1, -$7b(a6)
  00664e:  48 6e ff 85          pea.l    -$7b(a6)
  006652:  20 57                movea.l  (a7), a0
  006654:  10 10                move.b   (a0), d0
  006656:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  006658:  20 57                movea.l  (a7), a0
  00665a:  10 80                move.b   d0, (a0)
  00665c:  58 4f                addq.w   #$4, a7
  00665e:  60 26                bra.b    $6686  ; -> L6686
L6660:
  006660:  26 dc                move.l   (a4)+, (a3)+
  006662:  26 dc                move.l   (a4)+, (a3)+
  006664:  26 dc                move.l   (a4)+, (a3)+
  006666:  26 dc                move.l   (a4)+, (a3)+
  006668:  26 dc                move.l   (a4)+, (a3)+
  00666a:  26 dc                move.l   (a4)+, (a3)+
  00666c:  26 dc                move.l   (a4)+, (a3)+
  00666e:  26 dc                move.l   (a4)+, (a3)+
  006670:  26 dc                move.l   (a4)+, (a3)+
  006672:  26 dc                move.l   (a4)+, (a3)+
  006674:  26 dc                move.l   (a4)+, (a3)+
  006676:  26 dc                move.l   (a4)+, (a3)+
  006678:  26 dc                move.l   (a4)+, (a3)+
  00667a:  26 dc                move.l   (a4)+, (a3)+
  00667c:  26 dc                move.l   (a4)+, (a3)+
  00667e:  26 dc                move.l   (a4)+, (a3)+
  006680:  04 87 00 00 00 10    subi.l   #$10, d7
L6686:
  006686:  70 10                moveq    #$10, d0
  006688:  b0 87                cmp.l    d7, d0
  00668a:  6f d4                ble.b    $6660  ; -> L6660
  00668c:  60 02                bra.b    $6690  ; -> L6690
L668e:
  00668e:  26 dc                move.l   (a4)+, (a3)+
L6690:
  006690:  20 07                move.l   d7, d0
  006692:  53 87                subq.l   #$1, d7
  006694:  4a 80                tst.l    d0
  006696:  6e f6                bgt.b    $668e  ; -> L668e
  006698:  48 6e ff 85          pea.l    -$7b(a6)
  00669c:  20 57                movea.l  (a7), a0
  00669e:  10 10                move.b   (a0), d0
  0066a0:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  0066a2:  20 57                movea.l  (a7), a0
  0066a4:  10 80                move.b   d0, (a0)
  0066a6:  58 4f                addq.w   #$4, a7
  0066a8:  60 00 05 92          bra.w    $6c3c  ; -> L6c3c
L66ac:
  0066ac:  20 6e ff fc          movea.l  -$4(a6), a0
  0066b0:  70 01                moveq    #$1, d0
  0066b2:  21 40 00 3c          move.l   d0, $3c(a0)
  0066b6:  20 6e ff 80          movea.l  -$80(a6), a0
  0066ba:  2f 10                move.l   (a0), -(a7)
  0066bc:  2f 28 00 04          move.l   $4(a0), -(a7)
  0066c0:  3f 28 00 0a          move.w   $a(a0), -(a7)
  0066c4:  aa 39                dc.w     $aa39  ; _MakeITable
  0066c6:  20 6e ff fc          movea.l  -$4(a6), a0
  0066ca:  70 00                moveq    #$0, d0
  0066cc:  21 40 00 3c          move.l   d0, $3c(a0)
  0066d0:  32 38 0d 6e          move.w   $d6e.w, d1
  0066d4:  48 c1                ext.l    d1
  0066d6:  20 6e ff 86          movea.l  -$7a(a6), a0
  0066da:  21 41 00 08          move.l   d1, $8(a0)
  0066de:  60 00 05 5c          bra.w    $6c3c  ; -> L6c3c
L66e2:
  0066e2:  20 6e ff 80          movea.l  -$80(a6), a0
  0066e6:  20 10                move.l   (a0), d0
  0066e8:  a1 22                dc.w     $a122  ; _NewHandle
  0066ea:  22 6e ff 86          movea.l  -$7a(a6), a1
  0066ee:  23 48 00 08          move.l   a0, $8(a1)
  0066f2:  60 00 05 48          bra.w    $6c3c  ; -> L6c3c
L66f6:
  0066f6:  20 6e ff 80          movea.l  -$80(a6), a0
  0066fa:  20 50                movea.l  (a0), a0
  0066fc:  a0 23                dc.w     $a023  ; _DisposHandle
  0066fe:  60 00 05 3c          bra.w    $6c3c  ; -> L6c3c
L6702:
  006702:  20 6e ff 80          movea.l  -$80(a6), a0
  006706:  20 50                movea.l  (a0), a0
  006708:  22 6e ff 80          movea.l  -$80(a6), a1
  00670c:  20 29 00 04          move.l   $4(a1), d0
  006710:  a0 27                dc.w     $a027  ; _ReallocHandle
  006712:  60 00 05 28          bra.w    $6c3c  ; -> L6c3c
L6716:
  006716:  20 6e ff 80          movea.l  -$80(a6), a0
  00671a:  20 50                movea.l  (a0), a0
  00671c:  22 6e ff 80          movea.l  -$80(a6), a1
  006720:  20 29 00 04          move.l   $4(a1), d0
  006724:  a0 24                dc.w     $a024  ; _SetPtrSize
  006726:  60 00 05 14          bra.w    $6c3c  ; -> L6c3c
L672a:
  00672a:  59 8f                subq.l   #$4, a7
  00672c:  20 6e ff 80          movea.l  -$80(a6), a0
  006730:  2f 10                move.l   (a0), -(a7)
  006732:  3f 28 00 06          move.w   $6(a0), -(a7)
  006736:  a8 0c                dc.w     $a80c  ; _RGetResource
  006738:  20 6e ff 86          movea.l  -$7a(a6), a0
  00673c:  21 5f 00 08          move.l   (a7)+, $8(a0)
  006740:  60 00 04 fa          bra.w    $6c3c  ; -> L6c3c
L6744:
  006744:  20 6e ff 80          movea.l  -$80(a6), a0
  006748:  2d 68 00 04 ff f0    move.l   $4(a0), -$10(a6)
  00674e:  67 0e                beq.b    $675e  ; -> L675e
  006750:  59 8f                subq.l   #$4, a7
  006752:  aa 32                dc.w     $aa32  ; _GetGDevice
  006754:  2d 5f ff f4          move.l   (a7)+, -$c(a6)
  006758:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00675c:  aa 31                dc.w     $aa31  ; _SetGDevice
L675e:
  00675e:  59 8f                subq.l   #$4, a7
  006760:  20 6e ff 80          movea.l  -$80(a6), a0
  006764:  3f 28 00 02          move.w   $2(a0), -(a7)
  006768:  70 00                moveq    #$0, d0
  00676a:  aa a2                dc.w     $aaa2  ; _PaletteDispatch
  00676c:  2e 1f                move.l   (a7)+, d7
  00676e:  4a 78 0d 6e          tst.w    $d6e.w
  006772:  66 0a                bne.b    $677e  ; -> L677e
  006774:  20 6e ff 86          movea.l  -$7a(a6), a0
  006778:  21 47 00 08          move.l   d7, $8(a0)
  00677c:  60 0a                bra.b    $6788  ; -> L6788
L677e:
  00677e:  20 6e ff 86          movea.l  -$7a(a6), a0
  006782:  70 ff                moveq    #$ff, d0
  006784:  21 40 00 08          move.l   d0, $8(a0)
L6788:
  006788:  4a ae ff f0          tst.l    -$10(a6)
  00678c:  67 00 04 ae          beq.w    $6c3c  ; -> L6c3c
  006790:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  006794:  aa 31                dc.w     $aa31  ; _SetGDevice
  006796:  60 00 04 a4          bra.w    $6c3c  ; -> L6c3c
L679a:
  00679a:  20 6e ff 80          movea.l  -$80(a6), a0
  00679e:  3d 68 00 06 ff 7a    move.w   $6(a0), -$86(a6)
  0067a4:  3d 68 00 0a ff 7c    move.w   $a(a0), -$84(a6)
  0067aa:  3d 68 00 0e ff 7e    move.w   $e(a0), -$82(a6)
  0067b0:  20 6e ff 80          movea.l  -$80(a6), a0
  0067b4:  2d 68 00 10 ff f0    move.l   $10(a0), -$10(a6)
  0067ba:  70 00                moveq    #$0, d0
  0067bc:  2d 40 ff f4          move.l   d0, -$c(a6)
  0067c0:  20 6e ff 86          movea.l  -$7a(a6), a0
  0067c4:  21 40 00 08          move.l   d0, $8(a0)
  0067c8:  4a ae ff f0          tst.l    -$10(a6)
  0067cc:  67 1c                beq.b    $67ea  ; -> L67ea
  0067ce:  59 8f                subq.l   #$4, a7
  0067d0:  aa 32                dc.w     $aa32  ; _GetGDevice
  0067d2:  2d 5f ff f4          move.l   (a7)+, -$c(a6)
  0067d6:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  0067da:  aa 31                dc.w     $aa31  ; _SetGDevice
  0067dc:  20 6e ff f0          movea.l  -$10(a6), a0
  0067e0:  20 50                movea.l  (a0), a0
  0067e2:  2d 68 00 0c ff 8c    move.l   $c(a0), -$74(a6)
  0067e8:  60 12                bra.b    $67fc  ; -> L67fc
L67ea:
  0067ea:  59 8f                subq.l   #$4, a7
  0067ec:  aa 32                dc.w     $aa32  ; _GetGDevice
  0067ee:  20 5f                movea.l  (a7)+, a0
  0067f0:  2d 48 ff f0          move.l   a0, -$10(a6)
  0067f4:  20 50                movea.l  (a0), a0
  0067f6:  2d 68 00 0c ff 8c    move.l   $c(a0), -$74(a6)
L67fc:
  0067fc:  4a ae ff 8c          tst.l    -$74(a6)
  006800:  66 60                bne.b    $6862  ; -> L6862
  006802:  70 01                moveq    #$1, d0
  006804:  2f 00                move.l   d0, -(a7)
  006806:  48 6e ff f0          pea.l    -$10(a6)
  00680a:  72 29                moveq    #$29, d1
  00680c:  2f 01                move.l   d1, -(a7)
  00680e:  61 ff ff ff e1 b4    bsr.l    $49c4  ; -> EngineDispatch
  006814:  4f ef 00 0c          lea.l    $c(a7), a7
  006818:  60 48                bra.b    $6862  ; -> L6862
L681a:
  00681a:  20 6e ff 8c          movea.l  -$74(a6), a0
  00681e:  4a 90                tst.l    (a0)
  006820:  67 36                beq.b    $6858  ; -> L6858
  006822:  20 50                movea.l  (a0), a0
  006824:  4a a8 00 04          tst.l    $4(a0)
  006828:  67 2e                beq.b    $6858  ; -> L6858
  00682a:  55 8f                subq.l   #$2, a7
  00682c:  48 6e ff 7a          pea.l    -$86(a6)
  006830:  48 6e ff 76          pea.l    -$8a(a6)
  006834:  20 6e ff 8c          movea.l  -$74(a6), a0
  006838:  20 50                movea.l  (a0), a0
  00683a:  22 68 00 04          movea.l  $4(a0), a1
  00683e:  4e 91                jsr      (a1)
  006840:  4a 1f                tst.b    (a7)+
  006842:  67 14                beq.b    $6858  ; -> L6858
  006844:  20 6e ff 80          movea.l  -$80(a6), a0
  006848:  20 ae ff 76          move.l   -$8a(a6), (a0)
  00684c:  20 6e ff 86          movea.l  -$7a(a6), a0
  006850:  70 01                moveq    #$1, d0
  006852:  21 40 00 08          move.l   d0, $8(a0)
  006856:  60 10                bra.b    $6868  ; -> L6868
L6858:
  006858:  20 6e ff 8c          movea.l  -$74(a6), a0
  00685c:  20 50                movea.l  (a0), a0
  00685e:  2d 50 ff 8c          move.l   (a0), -$74(a6)
L6862:
  006862:  4a ae ff 8c          tst.l    -$74(a6)
  006866:  66 b2                bne.b    $681a  ; -> L681a
L6868:
  006868:  4a ae ff f4          tst.l    -$c(a6)
  00686c:  67 06                beq.b    $6874  ; -> L6874
  00686e:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  006872:  aa 31                dc.w     $aa31  ; _SetGDevice
L6874:
  006874:  70 00                moveq    #$0, d0
  006876:  30 2e ff 7a          move.w   -$86(a6), d0
  00687a:  4a 80                tst.l    d0
  00687c:  20 6e ff 80          movea.l  -$80(a6), a0
  006880:  21 40 00 04          move.l   d0, $4(a0)
  006884:  70 00                moveq    #$0, d0
  006886:  30 2e ff 7c          move.w   -$84(a6), d0
  00688a:  4a 80                tst.l    d0
  00688c:  20 6e ff 80          movea.l  -$80(a6), a0
  006890:  21 40 00 08          move.l   d0, $8(a0)
  006894:  70 00                moveq    #$0, d0
  006896:  30 2e ff 7e          move.w   -$82(a6), d0
  00689a:  4a 80                tst.l    d0
  00689c:  20 6e ff 80          movea.l  -$80(a6), a0
  0068a0:  21 40 00 0c          move.l   d0, $c(a0)
  0068a4:  60 00 03 96          bra.w    $6c3c  ; -> L6c3c
L68a8:
  0068a8:  20 6e ff 80          movea.l  -$80(a6), a0
  0068ac:  3d 68 00 06 ff 7a    move.w   $6(a0), -$86(a6)
  0068b2:  3d 68 00 0a ff 7c    move.w   $a(a0), -$84(a6)
  0068b8:  3d 68 00 0e ff 7e    move.w   $e(a0), -$82(a6)
  0068be:  20 6e ff 86          movea.l  -$7a(a6), a0
  0068c2:  70 00                moveq    #$0, d0
  0068c4:  21 40 00 08          move.l   d0, $8(a0)
  0068c8:  20 6e ff 80          movea.l  -$80(a6), a0
  0068cc:  2d 68 00 10 ff f0    move.l   $10(a0), -$10(a6)
  0068d2:  67 0e                beq.b    $68e2  ; -> L68e2
  0068d4:  59 8f                subq.l   #$4, a7
  0068d6:  aa 32                dc.w     $aa32  ; _GetGDevice
  0068d8:  2d 5f ff f4          move.l   (a7)+, -$c(a6)
  0068dc:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  0068e0:  aa 31                dc.w     $aa31  ; _SetGDevice
L68e2:
  0068e2:  20 6e ff 80          movea.l  -$80(a6), a0
  0068e6:  2d 50 ff 90          move.l   (a0), -$70(a6)
  0068ea:  60 5c                bra.b    $6948  ; -> L6948
L68ec:
  0068ec:  55 8f                subq.l   #$2, a7
  0068ee:  48 6e ff 7a          pea.l    -$86(a6)
  0068f2:  20 6e ff 90          movea.l  -$70(a6), a0
  0068f6:  20 50                movea.l  (a0), a0
  0068f8:  22 68 00 04          movea.l  $4(a0), a1
  0068fc:  4e 91                jsr      (a1)
  0068fe:  4a 1f                tst.b    (a7)+
  006900:  67 3c                beq.b    $693e  ; -> L693e
  006902:  70 00                moveq    #$0, d0
  006904:  30 2e ff 7a          move.w   -$86(a6), d0
  006908:  4a 80                tst.l    d0
  00690a:  20 6e ff 80          movea.l  -$80(a6), a0
  00690e:  21 40 00 04          move.l   d0, $4(a0)
  006912:  70 00                moveq    #$0, d0
  006914:  30 2e ff 7c          move.w   -$84(a6), d0
  006918:  4a 80                tst.l    d0
  00691a:  20 6e ff 80          movea.l  -$80(a6), a0
  00691e:  21 40 00 08          move.l   d0, $8(a0)
  006922:  70 00                moveq    #$0, d0
  006924:  30 2e ff 7e          move.w   -$82(a6), d0
  006928:  4a 80                tst.l    d0
  00692a:  20 6e ff 80          movea.l  -$80(a6), a0
  00692e:  21 40 00 0c          move.l   d0, $c(a0)
  006932:  20 6e ff 86          movea.l  -$7a(a6), a0
  006936:  70 01                moveq    #$1, d0
  006938:  21 40 00 08          move.l   d0, $8(a0)
  00693c:  60 10                bra.b    $694e  ; -> L694e
L693e:
  00693e:  20 6e ff 90          movea.l  -$70(a6), a0
  006942:  20 50                movea.l  (a0), a0
  006944:  2d 50 ff 90          move.l   (a0), -$70(a6)
L6948:
  006948:  4a ae ff 90          tst.l    -$70(a6)
  00694c:  66 9e                bne.b    $68ec  ; -> L68ec
L694e:
  00694e:  4a ae ff f0          tst.l    -$10(a6)
  006952:  67 00 02 e8          beq.w    $6c3c  ; -> L6c3c
  006956:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  00695a:  aa 31                dc.w     $aa31  ; _SetGDevice
  00695c:  60 00 02 de          bra.w    $6c3c  ; -> L6c3c
L6960:
  006960:  59 8f                subq.l   #$4, a7
  006962:  2f 38 08 88          move.l   $888.w, -(a7)
  006966:  61 ff 00 00 58 e2    bsr.l    $c24a  ; -> Strip24
  00696c:  20 5f                movea.l  (a7)+, a0
  00696e:  20 50                movea.l  (a0), a0
  006970:  20 50                movea.l  (a0), a0
  006972:  20 68 02 14          movea.l  $214(a0), a0
  006976:  20 50                movea.l  (a0), a0
  006978:  2d 48 ff 70          move.l   a0, -$90(a6)
  00697c:  1d 68 05 e4 ff 75    move.b   $5e4(a0), -$8b(a6)
  006982:  66 5a                bne.b    $69de  ; -> L69de
  006984:  59 8f                subq.l   #$4, a7
  006986:  3f 3c a8 8f          move.w   #$a88f, -(a7)
  00698a:  70 01                moveq    #$1, d0
  00698c:  1f 00                move.b   d0, -(a7)
  00698e:  61 ff 00 00 56 5c    bsr.l    $bfec  ; -> sub_bfec
  006994:  59 8f                subq.l   #$4, a7
  006996:  3f 3c a8 9f          move.w   #$a89f, -(a7)
  00699a:  70 01                moveq    #$1, d0
  00699c:  1f 00                move.b   d0, -(a7)
  00699e:  61 ff 00 00 56 4c    bsr.l    $bfec  ; -> sub_bfec
  0069a4:  20 1f                move.l   (a7)+, d0
  0069a6:  b0 9f                cmp.l    (a7)+, d0
  0069a8:  56 c0                sne.b    d0
  0069aa:  44 00                neg.b    d0
  0069ac:  49 c0                extb.l   d0
  0069ae:  1d 40 ff 75          move.b   d0, -$8b(a6)
  0069b2:  20 6e ff 70          movea.l  -$90(a6), a0
  0069b6:  11 40 05 e4          move.b   d0, $5e4(a0)
  0069ba:  4a 2e ff 75          tst.b    -$8b(a6)
  0069be:  66 1e                bne.b    $69de  ; -> L69de
  0069c0:  20 6e ff 80          movea.l  -$80(a6), a0
  0069c4:  70 00                moveq    #$0, d0
  0069c6:  20 80                move.l   d0, (a0)
  0069c8:  20 6e ff 80          movea.l  -$80(a6), a0
  0069cc:  72 01                moveq    #$1, d1
  0069ce:  21 41 00 04          move.l   d1, $4(a0)
  0069d2:  20 6e ff 86          movea.l  -$7a(a6), a0
  0069d6:  21 41 00 08          move.l   d1, $8(a0)
  0069da:  60 00 02 60          bra.w    $6c3c  ; -> L6c3c
L69de:
  0069de:  55 8f                subq.l   #$2, a7
  0069e0:  48 6e ff 68          pea.l    -$98(a6)
  0069e4:  3f 3c 00 3f          move.w   #$3f, -(a7)
  0069e8:  a8 8f                dc.w     $a88f  ; _OSDispatch
  0069ea:  20 6e ff 80          movea.l  -$80(a6), a0
  0069ee:  20 ae ff 68          move.l   -$98(a6), (a0)
  0069f2:  20 6e ff 80          movea.l  -$80(a6), a0
  0069f6:  21 6e ff 6c 00 04    move.l   -$94(a6), $4(a0)
  0069fc:  20 6e ff 86          movea.l  -$7a(a6), a0
  006a00:  70 01                moveq    #$1, d0
  006a02:  21 40 00 08          move.l   d0, $8(a0)
  006a06:  54 4f                addq.w   #$2, a7
  006a08:  60 00 02 32          bra.w    $6c3c  ; -> L6c3c
L6a0c:
  006a0c:  20 6e ff 80          movea.l  -$80(a6), a0
  006a10:  20 50                movea.l  (a0), a0
  006a12:  28 10                move.l   (a0), d4
  006a14:  60 06                bra.b    $6a1c  ; -> L6a1c
L6a16:
  006a16:  20 6e ff 80          movea.l  -$80(a6), a0
  006a1a:  28 10                move.l   (a0), d4
L6a1c:
  006a1c:  20 6e ff 80          movea.l  -$80(a6), a0
  006a20:  2d 68 00 04 ff dc    move.l   $4(a0), -$24(a6)
  006a26:  2c 28 00 08          move.l   $8(a0), d6
  006a2a:  2d 68 00 0c ff e0    move.l   $c(a0), -$20(a6)
  006a30:  20 6e 00 08          movea.l  $8(a6), a0
  006a34:  70 08                moveq    #$8, d0
  006a36:  c0 a8 00 04          and.l    $4(a0), d0
  006a3a:  66 0e                bne.b    $6a4a  ; -> L6a4a
  006a3c:  20 6e ff 86          movea.l  -$7a(a6), a0
  006a40:  70 ff                moveq    #$ff, d0
  006a42:  21 40 00 08          move.l   d0, $8(a0)
  006a46:  60 00 01 f4          bra.w    $6c3c  ; -> L6c3c
L6a4a:
  006a4a:  1d 7c 00 01 ff 85    move.b   #$1, -$7b(a6)
  006a50:  48 6e ff 85          pea.l    -$7b(a6)
  006a54:  20 57                movea.l  (a7), a0
  006a56:  10 10                move.b   (a0), d0
  006a58:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  006a5a:  20 57                movea.l  (a7), a0
  006a5c:  10 80                move.b   d0, (a0)
  006a5e:  4a 86                tst.l    d6
  006a60:  58 4f                addq.w   #$4, a7
  006a62:  67 00 01 04          beq.w    $6b68  ; -> L6b68
  006a66:  2d 44 ff 94          move.l   d4, -$6c(a6)
  006a6a:  2d 6e ff dc ff 98    move.l   -$24(a6), -$68(a6)
  006a70:  20 6e ff 94          movea.l  -$6c(a6), a0
  006a74:  22 6e ff 98          movea.l  -$68(a6), a1
  006a78:  70 02                moveq    #$2, d0
  006a7a:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  006a7c:  48 c0                ext.l    d0
  006a7e:  2a 00                move.l   d0, d5
  006a80:  67 1c                beq.b    $6a9e  ; -> L6a9e
  006a82:  20 6e ff 86          movea.l  -$7a(a6), a0
  006a86:  21 45 00 08          move.l   d5, $8(a0)
  006a8a:  48 6e ff 85          pea.l    -$7b(a6)
  006a8e:  20 57                movea.l  (a7), a0
  006a90:  10 10                move.b   (a0), d0
  006a92:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  006a94:  20 57                movea.l  (a7), a0
  006a96:  10 80                move.b   d0, (a0)
  006a98:  58 4f                addq.w   #$4, a7
  006a9a:  60 00 01 a0          bra.w    $6c3c  ; -> L6c3c
L6a9e:
  006a9e:  70 00                moveq    #$0, d0
  006aa0:  2d 40 ff e8          move.l   d0, -$18(a6)
  006aa4:  72 08                moveq    #$8, d1
  006aa6:  2d 41 ff e4          move.l   d1, -$1c(a6)
  006aaa:  60 00 00 88          bra.w    $6b34  ; -> L6b34
L6aae:
  006aae:  bc ae ff e4          cmp.l    -$1c(a6), d6
  006ab2:  64 04                bcc.b    $6ab8  ; -> L6ab8
  006ab4:  2d 46 ff e4          move.l   d6, -$1c(a6)
L6ab8:
  006ab8:  55 8f                subq.l   #$2, a7
  006aba:  48 6e ff 94          pea.l    -$6c(a6)
  006abe:  48 6e ff e4          pea.l    -$1c(a6)
  006ac2:  61 ff 00 00 57 a0    bsr.l    $c264  ; -> sub_c264
  006ac8:  30 1f                move.w   (a7)+, d0
  006aca:  48 c0                ext.l    d0
  006acc:  2a 00                move.l   d0, d5
  006ace:  66 3c                bne.b    $6b0c  ; -> L6b0c
  006ad0:  7e 00                moveq    #$0, d7
  006ad2:  60 28                bra.b    $6afc  ; -> L6afc
L6ad4:
  006ad4:  20 07                move.l   d7, d0
  006ad6:  e7 80                asl.l    #$3, d0
  006ad8:  22 2e ff e0          move.l   -$20(a6), d1
  006adc:  58 ae ff e0          addq.l   #$4, -$20(a6)
  006ae0:  20 41                movea.l  d1, a0
  006ae2:  20 b6 08 9c          move.l   -$64(a6, d0.l), (a0)
  006ae6:  20 07                move.l   d7, d0
  006ae8:  e7 80                asl.l    #$3, d0
  006aea:  22 2e ff e0          move.l   -$20(a6), d1
  006aee:  58 ae ff e0          addq.l   #$4, -$20(a6)
  006af2:  20 41                movea.l  d1, a0
  006af4:  20 b6 08 a0          move.l   -$60(a6, d0.l), (a0)
  006af8:  20 07                move.l   d7, d0
  006afa:  52 87                addq.l   #$1, d7
L6afc:
  006afc:  be ae ff e4          cmp.l    -$1c(a6), d7
  006b00:  65 d2                bcs.b    $6ad4  ; -> L6ad4
  006b02:  20 2e ff e4          move.l   -$1c(a6), d0
  006b06:  d1 ae ff e8          add.l    d0, -$18(a6)
  006b0a:  60 24                bra.b    $6b30  ; -> L6b30
L6b0c:
  006b0c:  20 44                movea.l  d4, a0
  006b0e:  22 6e ff dc          movea.l  -$24(a6), a1
  006b12:  70 03                moveq    #$3, d0
  006b14:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  006b16:  20 6e ff 86          movea.l  -$7a(a6), a0
  006b1a:  21 45 00 08          move.l   d5, $8(a0)
  006b1e:  48 6e ff 85          pea.l    -$7b(a6)
  006b22:  20 57                movea.l  (a7), a0
  006b24:  10 10                move.b   (a0), d0
  006b26:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  006b28:  20 57                movea.l  (a7), a0
  006b2a:  10 80                move.b   d0, (a0)
  006b2c:  58 4f                addq.w   #$4, a7
  006b2e:  60 10                bra.b    $6b40  ; -> L6b40
L6b30:
  006b30:  9c ae ff e4          sub.l    -$1c(a6), d6
L6b34:
  006b34:  4a ae ff 98          tst.l    -$68(a6)
  006b38:  67 06                beq.b    $6b40  ; -> L6b40
  006b3a:  4a 86                tst.l    d6
  006b3c:  66 00 ff 70          bne.w    $6aae  ; -> L6aae
L6b40:
  006b40:  4a ae ff 98          tst.l    -$68(a6)
  006b44:  67 16                beq.b    $6b5c  ; -> L6b5c
  006b46:  20 44                movea.l  d4, a0
  006b48:  22 6e ff dc          movea.l  -$24(a6), a1
  006b4c:  70 03                moveq    #$3, d0
  006b4e:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  006b50:  20 6e ff 86          movea.l  -$7a(a6), a0
  006b54:  70 fe                moveq    #$fe, d0
  006b56:  21 40 00 08          move.l   d0, $8(a0)
  006b5a:  60 20                bra.b    $6b7c  ; -> L6b7c
L6b5c:
  006b5c:  20 6e ff 86          movea.l  -$7a(a6), a0
  006b60:  21 6e ff e8 00 08    move.l   -$18(a6), $8(a0)
  006b66:  60 14                bra.b    $6b7c  ; -> L6b7c
L6b68:
  006b68:  20 44                movea.l  d4, a0
  006b6a:  22 6e ff dc          movea.l  -$24(a6), a1
  006b6e:  70 03                moveq    #$3, d0
  006b70:  a0 5c                dc.w     $a05c  ; _MemoryDispatch
  006b72:  20 6e ff 86          movea.l  -$7a(a6), a0
  006b76:  70 00                moveq    #$0, d0
  006b78:  21 40 00 08          move.l   d0, $8(a0)
L6b7c:
  006b7c:  48 6e ff 85          pea.l    -$7b(a6)
  006b80:  20 57                movea.l  (a7), a0
  006b82:  10 10                move.b   (a0), d0
  006b84:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  006b86:  20 57                movea.l  (a7), a0
  006b88:  10 80                move.b   d0, (a0)
  006b8a:  58 4f                addq.w   #$4, a7
  006b8c:  60 00 00 ae          bra.w    $6c3c  ; -> L6c3c
L6b90:
  006b90:  59 8f                subq.l   #$4, a7
  006b92:  2f 38 08 88          move.l   $888.w, -(a7)
  006b96:  61 ff 00 00 56 b2    bsr.l    $c24a  ; -> Strip24
  006b9c:  20 5f                movea.l  (a7)+, a0
  006b9e:  20 50                movea.l  (a0), a0
  006ba0:  20 50                movea.l  (a0), a0
  006ba2:  2d 68 02 14 ff ec    move.l   $214(a0), -$14(a6)
  006ba8:  66 0e                bne.b    $6bb8  ; -> L6bb8
  006baa:  20 6e ff 86          movea.l  -$7a(a6), a0
  006bae:  70 ff                moveq    #$ff, d0
  006bb0:  21 40 00 08          move.l   d0, $8(a0)
  006bb4:  60 00 00 86          bra.w    $6c3c  ; -> L6c3c
L6bb8:
  006bb8:  48 6e ff 70          pea.l    -$90(a6)
  006bbc:  48 6e ff 6a          pea.l    -$96(a6)
  006bc0:  20 6e ff ec          movea.l  -$14(a6), a0
  006bc4:  20 50                movea.l  (a0), a0
  006bc6:  2f 28 00 c8          move.l   $c8(a0), -(a7)
  006bca:  61 ff 00 00 22 26    bsr.l    $8df2  ; -> sub_8df2
  006bd0:  70 00                moveq    #$0, d0
  006bd2:  30 2e ff 6a          move.w   -$96(a6), d0
  006bd6:  4a 80                tst.l    d0
  006bd8:  20 6e ff 80          movea.l  -$80(a6), a0
  006bdc:  20 80                move.l   d0, (a0)
  006bde:  70 00                moveq    #$0, d0
  006be0:  30 2e ff 6c          move.w   -$94(a6), d0
  006be4:  4a 80                tst.l    d0
  006be6:  20 6e ff 80          movea.l  -$80(a6), a0
  006bea:  21 40 00 04          move.l   d0, $4(a0)
  006bee:  70 00                moveq    #$0, d0
  006bf0:  30 2e ff 6e          move.w   -$92(a6), d0
  006bf4:  4a 80                tst.l    d0
  006bf6:  20 6e ff 80          movea.l  -$80(a6), a0
  006bfa:  21 40 00 08          move.l   d0, $8(a0)
  006bfe:  70 00                moveq    #$0, d0
  006c00:  30 2e ff 70          move.w   -$90(a6), d0
  006c04:  4a 80                tst.l    d0
  006c06:  20 6e ff 80          movea.l  -$80(a6), a0
  006c0a:  21 40 00 0c          move.l   d0, $c(a0)
  006c0e:  70 00                moveq    #$0, d0
  006c10:  30 2e ff 72          move.w   -$8e(a6), d0
  006c14:  4a 80                tst.l    d0
  006c16:  20 6e ff 80          movea.l  -$80(a6), a0
  006c1a:  21 40 00 10          move.l   d0, $10(a0)
  006c1e:  70 00                moveq    #$0, d0
  006c20:  30 2e ff 74          move.w   -$8c(a6), d0
  006c24:  4a 80                tst.l    d0
  006c26:  20 6e ff 80          movea.l  -$80(a6), a0
  006c2a:  21 40 00 14          move.l   d0, $14(a0)
  006c2e:  20 6e ff 86          movea.l  -$7a(a6), a0
  006c32:  70 00                moveq    #$0, d0
  006c34:  21 40 00 08          move.l   d0, $8(a0)
  006c38:  4f ef 00 0c          lea.l    $c(a7), a7
L6c3c:
  006c3c:  20 6e 00 0c          movea.l  $c(a6), a0
  006c40:  52 90                addq.l   #$1, (a0)
  006c42:  20 6e ff 86          movea.l  -$7a(a6), a0
  006c46:  70 00                moveq    #$0, d0
  006c48:  21 40 00 04          move.l   d0, $4(a0)
L6c4c:
  006c4c:  20 6e ff fc          movea.l  -$4(a6), a0
  006c50:  20 68 00 08          movea.l  $8(a0), a0
  006c54:  4a 90                tst.l    (a0)
  006c56:  66 f4                bne.b    $6c4c  ; -> L6c4c
  006c58:  55 8f                subq.l   #$2, a7
  006c5a:  1f 2e ff 8b          move.b   -$75(a6), -(a7)
  006c5e:  61 ff 00 00 53 ba    bsr.l    $c01a  ; -> HWPrivProbe
  006c64:  54 4f                addq.w   #$2, a7
  006c66:  4c ee 18 f0 ff 50    movem.l  -$b0(a6), d4-d7/a3-a4
  006c6c:  4e 5e                unlk     a6
  006c6e:  4e 75                rts      
handler_105:
  006c70:  4e 56 00 00          link.w   a6, #$0
  006c74:  2f 2e 00 10          move.l   $10(a6), -(a7)
  006c78:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  006c7c:  2f 2e 00 08          move.l   $8(a6), -(a7)
  006c80:  61 ff ff ff a7 82    bsr.l    $1404  ; -> sub_1404
  006c86:  4e 5e                unlk     a6
  006c88:  4e 75                rts      
handler_103:
  006c8a:  4e 56 00 00          link.w   a6, #$0
  006c8e:  48 e7 01 08          movem.l  d7/a4, -(a7)
  006c92:  28 6e 00 08          movea.l  $8(a6), a4
  006c96:  20 54                movea.l  (a4), a0
  006c98:  7e 00                moveq    #$0, d7
  006c9a:  3e 28 00 02          move.w   $2(a0), d7
  006c9e:  2f 0c                move.l   a4, -(a7)
  006ca0:  61 ff 00 00 02 ac    bsr.l    $6f4e  ; -> sub_6f4e
  006ca6:  20 54                movea.l  (a4), a0
  006ca8:  70 02                moveq    #$2, d0
  006caa:  c0 a8 00 1c          and.l    $1c(a0), d0
  006cae:  58 4f                addq.w   #$4, a7
  006cb0:  67 04                beq.b    $6cb6  ; -> L6cb6
  006cb2:  70 ff                moveq    #$ff, d0
  006cb4:  60 5e                bra.b    $6d14  ; -> L6d14
L6cb6:
  006cb6:  70 00                moveq    #$0, d0
  006cb8:  2f 00                move.l   d0, -(a7)
  006cba:  2f 00                move.l   d0, -(a7)
  006cbc:  2f 00                move.l   d0, -(a7)
  006cbe:  61 ff ff ff dd 04    bsr.l    $49c4  ; -> EngineDispatch
  006cc4:  4a ae 00 0c          tst.l    $c(a6)
  006cc8:  4f ef 00 0c          lea.l    $c(a7), a7
  006ccc:  67 40                beq.b    $6d0e  ; -> L6d0e
  006cce:  20 54                movea.l  (a4), a0
  006cd0:  31 7c 00 05 00 02    move.w   #$5, $2(a0)
  006cd6:  20 54                movea.l  (a4), a0
  006cd8:  31 7c 01 f4 00 02    move.w   #$1f4, $2(a0)
  006cde:  70 01                moveq    #$1, d0
  006ce0:  2f 00                move.l   d0, -(a7)
  006ce2:  48 6e 00 0c          pea.l    $c(a6)
  006ce6:  72 02                moveq    #$2, d1
  006ce8:  2f 01                move.l   d1, -(a7)
  006cea:  61 ff ff ff dc d8    bsr.l    $49c4  ; -> EngineDispatch
  006cf0:  20 54                movea.l  (a4), a0
  006cf2:  21 40 01 74          move.l   d0, $174(a0)
  006cf6:  20 54                movea.l  (a4), a0
  006cf8:  31 47 00 02          move.w   d7, $2(a0)
  006cfc:  70 00                moveq    #$0, d0
  006cfe:  2f 00                move.l   d0, -(a7)
  006d00:  2f 00                move.l   d0, -(a7)
  006d02:  2f 00                move.l   d0, -(a7)
  006d04:  61 ff ff ff dc be    bsr.l    $49c4  ; -> EngineDispatch
  006d0a:  4f ef 00 18          lea.l    $18(a7), a7
L6d0e:
  006d0e:  20 54                movea.l  (a4), a0
  006d10:  20 28 01 74          move.l   $174(a0), d0
L6d14:
  006d14:  4c ee 10 80 ff f8    movem.l  -$8(a6), d7/a4
  006d1a:  4e 5e                unlk     a6
  006d1c:  4e 75                rts      
handler_104:
  006d1e:  4e 56 00 00          link.w   a6, #$0
  006d22:  48 e7 11 08          movem.l  d3/d7/a4, -(a7)
  006d26:  59 8f                subq.l   #$4, a7
  006d28:  2f 38 08 88          move.l   $888.w, -(a7)
  006d2c:  61 ff 00 00 55 1c    bsr.l    $c24a  ; -> Strip24
  006d32:  20 5f                movea.l  (a7)+, a0
  006d34:  20 50                movea.l  (a0), a0
  006d36:  20 50                movea.l  (a0), a0
  006d38:  28 68 02 14          movea.l  $214(a0), a4
  006d3c:  20 0c                move.l   a4, d0
  006d3e:  67 46                beq.b    $6d86  ; -> L6d86
  006d40:  70 0e                moveq    #$e, d0
  006d42:  2f 00                move.l   d0, -(a7)
  006d44:  72 00                moveq    #$0, d1
  006d46:  2f 01                move.l   d1, -(a7)
  006d48:  70 26                moveq    #$26, d0
  006d4a:  2f 00                move.l   d0, -(a7)
  006d4c:  61 ff ff ff dc 76    bsr.l    $49c4  ; -> EngineDispatch
  006d52:  4a 80                tst.l    d0
  006d54:  57 c3                seq.b    d3
  006d56:  44 03                neg.b    d3
  006d58:  49 c3                extb.l   d3
  006d5a:  2e 03                move.l   d3, d7
  006d5c:  70 00                moveq    #$0, d0
  006d5e:  2f 00                move.l   d0, -(a7)
  006d60:  2f 00                move.l   d0, -(a7)
  006d62:  72 11                moveq    #$11, d1
  006d64:  2f 01                move.l   d1, -(a7)
  006d66:  61 ff ff ff dc 5c    bsr.l    $49c4  ; -> EngineDispatch
  006d6c:  70 00                moveq    #$0, d0
  006d6e:  2f 00                move.l   d0, -(a7)
  006d70:  2f 00                move.l   d0, -(a7)
  006d72:  2f 00                move.l   d0, -(a7)
  006d74:  61 ff ff ff dc 4e    bsr.l    $49c4  ; -> EngineDispatch
  006d7a:  20 54                movea.l  (a4), a0
  006d7c:  08 a8 00 00 00 1f    bclr.b   #$0, $1f(a0)
  006d82:  4f ef 00 24          lea.l    $24(a7), a7
L6d86:
  006d86:  20 07                move.l   d7, d0
  006d88:  4c ee 10 88 ff f4    movem.l  -$c(a6), d3/d7/a4
  006d8e:  4e 5e                unlk     a6
  006d90:  4e 75                rts      
* StoreCtxWord_AA6  -  the single most-called helper (~159x).  Fetches the
* engine globals and stores its word argument into globals+$AA6 (a field
* updated before most accelerated ops), then continues.
StoreCtxWord_AA6:
  006d92:  4e 56 00 00          link.w   a6, #$0
  006d96:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  006d9a:  2c 2e 00 08          move.l   $8(a6), d6
  006d9e:  59 8f                subq.l   #$4, a7
  006da0:  2f 38 08 88          move.l   $888.w, -(a7)
  006da4:  61 ff 00 00 54 a4    bsr.l    $c24a  ; -> Strip24
  006daa:  20 5f                movea.l  (a7)+, a0
  006dac:  20 50                movea.l  (a0), a0
  006dae:  26 50                movea.l  (a0), a3
  006db0:  20 0b                move.l   a3, d0
  006db2:  66 04                bne.b    $6db8  ; -> L6db8
  006db4:  70 00                moveq    #$0, d0
  006db6:  60 52                bra.b    $6e0a  ; -> L6e0a
L6db8:
  006db8:  37 46 0a a6          move.w   d6, $aa6(a3)
  006dbc:  7e 00                moveq    #$0, d7
  006dbe:  49 eb 02 78          lea.l    $278(a3), a4
  006dc2:  60 12                bra.b    $6dd6  ; -> L6dd6
L6dc4:
  006dc4:  bc 94                cmp.l    (a4), d6
  006dc6:  66 06                bne.b    $6dce  ; -> L6dce
  006dc8:  20 2c 00 04          move.l   $4(a4), d0
  006dcc:  60 3c                bra.b    $6e0a  ; -> L6e0a
L6dce:
  006dce:  20 07                move.l   d7, d0
  006dd0:  52 87                addq.l   #$1, d7
  006dd2:  49 ec 00 10          lea.l    $10(a4), a4
L6dd6:
  006dd6:  30 2b 02 2c          move.w   $22c(a3), d0
  006dda:  48 c0                ext.l    d0
  006ddc:  b0 87                cmp.l    d7, d0
  006dde:  6e e4                bgt.b    $6dc4  ; -> L6dc4
  006de0:  70 01                moveq    #$1, d0
  006de2:  2f 00                move.l   d0, -(a7)
  006de4:  72 07                moveq    #$7, d1
  006de6:  2f 01                move.l   d1, -(a7)
  006de8:  59 8f                subq.l   #$4, a7
  006dea:  2f 38 08 88          move.l   $888.w, -(a7)
  006dee:  61 ff 00 00 54 5a    bsr.l    $c24a  ; -> Strip24
  006df4:  20 5f                movea.l  (a7)+, a0
  006df6:  20 50                movea.l  (a0), a0
  006df8:  20 50                movea.l  (a0), a0
  006dfa:  2f 28 02 14          move.l   $214(a0), -(a7)
  006dfe:  61 ff 00 00 07 fe    bsr.l    $75fe  ; -> sub_75fe
  006e04:  70 ff                moveq    #$ff, d0
  006e06:  4f ef 00 0c          lea.l    $c(a7), a7
L6e0a:
  006e0a:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  006e10:  4e 5e                unlk     a6
  006e12:  4e 75                rts      
sub_6e14:
  006e14:  4e 56 00 00          link.w   a6, #$0
  006e18:  48 e7 07 18          movem.l  d5-d7/a3-a4, -(a7)
  006e1c:  59 8f                subq.l   #$4, a7
  006e1e:  2f 38 08 88          move.l   $888.w, -(a7)
  006e22:  61 ff 00 00 54 26    bsr.l    $c24a  ; -> Strip24
  006e28:  20 5f                movea.l  (a7)+, a0
  006e2a:  20 50                movea.l  (a0), a0
  006e2c:  20 50                movea.l  (a0), a0
  006e2e:  28 68 02 14          movea.l  $214(a0), a4
  006e32:  20 0c                move.l   a4, d0
  006e34:  66 06                bne.b    $6e3c  ; -> L6e3c
  006e36:  70 01                moveq    #$1, d0
  006e38:  60 00 00 d8          bra.w    $6f12  ; -> L6f12
L6e3c:
  006e3c:  26 54                movea.l  (a4), a3
  006e3e:  70 27                moveq    #$27, d0
  006e40:  c0 ab 00 08          and.l    $8(a3), d0
  006e44:  72 27                moveq    #$27, d1
  006e46:  b2 80                cmp.l    d0, d1
  006e48:  67 06                beq.b    $6e50  ; -> L6e50
  006e4a:  70 01                moveq    #$1, d0
  006e4c:  60 00 00 c4          bra.w    $6f12  ; -> L6f12
L6e50:
  006e50:  20 3c 00 00 06 00    move.l   #$600, d0
  006e56:  c0 ab 00 08          and.l    $8(a3), d0
  006e5a:  67 06                beq.b    $6e62  ; -> L6e62
  006e5c:  70 01                moveq    #$1, d0
  006e5e:  60 00 00 b2          bra.w    $6f12  ; -> L6f12
L6e62:
  006e62:  59 8f                subq.l   #$4, a7
  006e64:  2f 38 08 88          move.l   $888.w, -(a7)
  006e68:  61 ff 00 00 53 e0    bsr.l    $c24a  ; -> Strip24
  006e6e:  28 5f                movea.l  (a7)+, a4
L6e70:
  006e70:  20 6c 00 08          movea.l  $8(a4), a0
  006e74:  4a 90                tst.l    (a0)
  006e76:  66 f8                bne.b    $6e70  ; -> L6e70
  006e78:  55 8f                subq.l   #$2, a7
  006e7a:  70 00                moveq    #$0, d0
  006e7c:  1f 00                move.b   d0, -(a7)
  006e7e:  61 ff 00 00 51 9a    bsr.l    $c01a  ; -> HWPrivProbe
  006e84:  1a 1f                move.b   (a7)+, d5
  006e86:  20 6b 00 10          movea.l  $10(a3), a0
  006e8a:  2e 10                move.l   (a0), d7
  006e8c:  2c 2b 00 1c          move.l   $1c(a3), d6
L6e90:
  006e90:  20 6c 00 08          movea.l  $8(a4), a0
  006e94:  4a 90                tst.l    (a0)
  006e96:  66 f8                bne.b    $6e90  ; -> L6e90
  006e98:  55 8f                subq.l   #$2, a7
  006e9a:  1f 05                move.b   d5, -(a7)
  006e9c:  61 ff 00 00 51 7c    bsr.l    $c01a  ; -> HWPrivProbe
  006ea2:  70 18                moveq    #$18, d0
  006ea4:  c0 87                and.l    d7, d0
  006ea6:  54 4f                addq.w   #$2, a7
  006ea8:  67 04                beq.b    $6eae  ; -> L6eae
  006eaa:  70 01                moveq    #$1, d0
  006eac:  60 64                bra.b    $6f12  ; -> L6f12
L6eae:
  006eae:  70 04                moveq    #$4, d0
  006eb0:  c0 87                and.l    d7, d0
  006eb2:  67 1c                beq.b    $6ed0  ; -> L6ed0
  006eb4:  28 6b 00 0c          movea.l  $c(a3), a4
  006eb8:  20 6b 00 10          movea.l  $10(a3), a0
  006ebc:  02 90 ff ff ff fb    andi.l   #$fffffffb, (a0)
  006ec2:  48 6b 00 24          pea.l    $24(a3)
  006ec6:  2f 0c                move.l   a4, -(a7)
  006ec8:  61 ff ff ff f5 78    bsr.l    $6442  ; -> sub_6442
  006ece:  50 4f                addq.w   #$8, a7
L6ed0:
  006ed0:  70 40                moveq    #$40, d0
  006ed2:  c0 86                and.l    d6, d0
  006ed4:  67 12                beq.b    $6ee8  ; -> L6ee8
  006ed6:  20 6b 00 0c          movea.l  $c(a3), a0
  006eda:  20 28 01 c8          move.l   $1c8(a0), d0
  006ede:  b0 ab 00 b8          cmp.l    $b8(a3), d0
  006ee2:  54 c0                scc.b    d0
  006ee4:  44 00                neg.b    d0
  006ee6:  60 2a                bra.b    $6f12  ; -> L6f12
L6ee8:
  006ee8:  70 04                moveq    #$4, d0
  006eea:  c0 86                and.l    d6, d0
  006eec:  67 22                beq.b    $6f10  ; -> L6f10
  006eee:  4a ab 05 e0          tst.l    $5e0(a3)
  006ef2:  67 12                beq.b    $6f06  ; -> L6f06
  006ef4:  20 6b 00 0c          movea.l  $c(a3), a0
  006ef8:  22 6b 05 e0          movea.l  $5e0(a3), a1
  006efc:  22 a8 00 1c          move.l   $1c(a0), (a1)
  006f00:  70 00                moveq    #$0, d0
  006f02:  27 40 05 e0          move.l   d0, $5e0(a3)
L6f06:
  006f06:  70 02                moveq    #$2, d0
  006f08:  c0 87                and.l    d7, d0
  006f0a:  56 c0                sne.b    d0
  006f0c:  44 00                neg.b    d0
  006f0e:  60 02                bra.b    $6f12  ; -> L6f12
L6f10:
  006f10:  70 01                moveq    #$1, d0
L6f12:
  006f12:  4c ee 18 e0 ff ec    movem.l  -$14(a6), d5-d7/a3-a4
  006f18:  4e 5e                unlk     a6
  006f1a:  4e 75                rts      
sub_6f1c:
  006f1c:  4e 56 00 00          link.w   a6, #$0
  006f20:  2f 0c                move.l   a4, -(a7)
  006f22:  59 8f                subq.l   #$4, a7
  006f24:  2f 38 08 88          move.l   $888.w, -(a7)
  006f28:  61 ff 00 00 53 20    bsr.l    $c24a  ; -> Strip24
  006f2e:  20 5f                movea.l  (a7)+, a0
  006f30:  20 50                movea.l  (a0), a0
  006f32:  20 50                movea.l  (a0), a0
  006f34:  28 68 02 14          movea.l  $214(a0), a4
  006f38:  20 0c                move.l   a4, d0
  006f3a:  67 08                beq.b    $6f44  ; -> L6f44
  006f3c:  20 54                movea.l  (a4), a0
  006f3e:  20 28 00 c8          move.l   $c8(a0), d0
  006f42:  60 02                bra.b    $6f46  ; -> L6f46
L6f44:
  006f44:  70 00                moveq    #$0, d0
L6f46:
  006f46:  28 6e ff fc          movea.l  -$4(a6), a4
  006f4a:  4e 5e                unlk     a6
  006f4c:  4e 75                rts      
sub_6f4e:
  006f4e:  4e 56 ff e8          link.w   a6, #$ffe8
  006f52:  48 e7 13 18          movem.l  d3/d6-d7/a3-a4, -(a7)
  006f56:  42 ae ff f8          clr.l    -$8(a6)
  006f5a:  42 ae ff f4          clr.l    -$c(a6)
  006f5e:  20 6e 00 08          movea.l  $8(a6), a0
  006f62:  20 50                movea.l  (a0), a0
  006f64:  2d 48 ff fc          move.l   a0, -$4(a6)
  006f68:  20 3c 00 00 06 00    move.l   #$600, d0
  006f6e:  c0 a8 00 08          and.l    $8(a0), d0
  006f72:  67 06                beq.b    $6f7a  ; -> L6f7a
  006f74:  70 00                moveq    #$0, d0
  006f76:  60 00 04 42          bra.w    $73ba  ; -> L73ba
L6f7a:
  006f7a:  59 8f                subq.l   #$4, a7
  006f7c:  2f 38 08 88          move.l   $888.w, -(a7)
  006f80:  61 ff 00 00 52 c8    bsr.l    $c24a  ; -> Strip24
  006f86:  20 5f                movea.l  (a7)+, a0
  006f88:  20 50                movea.l  (a0), a0
  006f8a:  28 50                movea.l  (a0), a4
  006f8c:  20 0c                move.l   a4, d0
  006f8e:  66 06                bne.b    $6f96  ; -> L6f96
  006f90:  70 00                moveq    #$0, d0
  006f92:  60 00 04 26          bra.w    $73ba  ; -> L73ba
L6f96:
  006f96:  20 6e ff fc          movea.l  -$4(a6), a0
  006f9a:  70 02                moveq    #$2, d0
  006f9c:  c0 a8 00 1c          and.l    $1c(a0), d0
  006fa0:  67 30                beq.b    $6fd2  ; -> L6fd2
  006fa2:  2f 2e 00 08          move.l   $8(a6), -(a7)
  006fa6:  61 ff 00 00 05 c8    bsr.l    $7570  ; -> sub_7570
  006fac:  4a 80                tst.l    d0
  006fae:  58 4f                addq.w   #$4, a7
  006fb0:  67 20                beq.b    $6fd2  ; -> L6fd2
  006fb2:  20 6e ff fc          movea.l  -$4(a6), a0
  006fb6:  31 7c 00 06 01 5c    move.w   #$6, $15c(a0)
  006fbc:  70 01                moveq    #$1, d0
  006fbe:  2f 00                move.l   d0, -(a7)
  006fc0:  72 06                moveq    #$6, d1
  006fc2:  2f 01                move.l   d1, -(a7)
  006fc4:  2f 2e 00 08          move.l   $8(a6), -(a7)
  006fc8:  61 ff 00 00 06 34    bsr.l    $75fe  ; -> sub_75fe
  006fce:  4f ef 00 0c          lea.l    $c(a7), a7
L6fd2:
  006fd2:  59 8f                subq.l   #$4, a7
  006fd4:  2f 38 08 88          move.l   $888.w, -(a7)
  006fd8:  61 ff 00 00 52 70    bsr.l    $c24a  ; -> Strip24
  006fde:  2d 5f ff f0          move.l   (a7)+, -$10(a6)
L6fe2:
  006fe2:  20 6e ff f0          movea.l  -$10(a6), a0
  006fe6:  20 68 00 08          movea.l  $8(a0), a0
  006fea:  4a 90                tst.l    (a0)
  006fec:  66 f4                bne.b    $6fe2  ; -> L6fe2
  006fee:  55 8f                subq.l   #$2, a7
  006ff0:  70 00                moveq    #$0, d0
  006ff2:  1f 00                move.b   d0, -(a7)
  006ff4:  61 ff 00 00 50 24    bsr.l    $c01a  ; -> HWPrivProbe
  006ffa:  1c 1f                move.b   (a7)+, d6
  006ffc:  20 6e ff fc          movea.l  -$4(a6), a0
  007000:  26 68 00 0c          movea.l  $c(a0), a3
  007004:  4a ae ff f0          tst.l    -$10(a6)
  007008:  67 00 00 9a          beq.w    $70a4  ; -> L70a4
  00700c:  20 6e ff f0          movea.l  -$10(a6), a0
  007010:  0c a8 07 5b cd 15 00 20 cmpi.l   #$75bcd15, $20(a0)
  007018:  66 00 00 8a          bne.w    $70a4  ; -> L70a4
  00701c:  20 6e ff f0          movea.l  -$10(a6), a0
  007020:  20 68 00 0c          movea.l  $c(a0), a0
  007024:  70 00                moveq    #$0, d0
  007026:  20 80                move.l   d0, (a0)
  007028:  20 6e ff f0          movea.l  -$10(a6), a0
  00702c:  20 68 00 08          movea.l  $8(a0), a0
  007030:  20 80                move.l   d0, (a0)
  007032:  20 6e ff f0          movea.l  -$10(a6), a0
  007036:  20 68 00 10          movea.l  $10(a0), a0
  00703a:  43 ee ff f4          lea.l    -$c(a6), a1
  00703e:  20 d9                move.l   (a1)+, (a0)+
  007040:  20 d9                move.l   (a1)+, (a0)+
  007042:  20 6e ff f0          movea.l  -$10(a6), a0
  007046:  20 68 00 28          movea.l  $28(a0), a0
  00704a:  2d 50 ff ec          move.l   (a0), -$14(a6)
  00704e:  67 1a                beq.b    $706a  ; -> L706a
  007050:  20 6e ff f0          movea.l  -$10(a6), a0
  007054:  20 68 00 2c          movea.l  $2c(a0), a0
  007058:  22 6e ff f0          movea.l  -$10(a6), a1
  00705c:  22 69 00 04          movea.l  $4(a1), a1
  007060:  20 2e ff ec          move.l   -$14(a6), d0
  007064:  52 80                addq.l   #$1, d0
  007066:  e5 88                lsl.l    #$2, d0
  007068:  a0 2e                dc.w     $a02e  ; _BlockMove
L706a:
  00706a:  20 6e ff f0          movea.l  -$10(a6), a0
  00706e:  20 68 00 28          movea.l  $28(a0), a0
  007072:  70 00                moveq    #$0, d0
  007074:  20 80                move.l   d0, (a0)
  007076:  20 6e ff f0          movea.l  -$10(a6), a0
  00707a:  21 40 00 38          move.l   d0, $38(a0)
  00707e:  20 6e ff f0          movea.l  -$10(a6), a0
  007082:  21 40 00 18          move.l   d0, $18(a0)
  007086:  20 6e ff f0          movea.l  -$10(a6), a0
  00708a:  21 40 00 3c          move.l   d0, $3c(a0)
  00708e:  20 6e ff f0          movea.l  -$10(a6), a0
  007092:  20 68 00 1c          movea.l  $1c(a0), a0
  007096:  43 ee ff f4          lea.l    -$c(a6), a1
  00709a:  20 d9                move.l   (a1)+, (a0)+
  00709c:  20 d9                move.l   (a1)+, (a0)+
  00709e:  72 04                moveq    #$4, d1
  0070a0:  27 41 01 c0          move.l   d1, $1c0(a3)
L70a4:
  0070a4:  20 6e ff fc          movea.l  -$4(a6), a0
  0070a8:  02 a8 ff ff ff a0 00 1c andi.l   #$ffffffa0, $1c(a0)
  0070b0:  20 6e ff fc          movea.l  -$4(a6), a0
  0070b4:  70 00                moveq    #$0, d0
  0070b6:  21 40 00 18          move.l   d0, $18(a0)
  0070ba:  20 6e ff fc          movea.l  -$4(a6), a0
  0070be:  21 40 00 b0          move.l   d0, $b0(a0)
  0070c2:  20 6e ff fc          movea.l  -$4(a6), a0
  0070c6:  21 40 00 c0          move.l   d0, $c0(a0)
  0070ca:  20 6e ff fc          movea.l  -$4(a6), a0
  0070ce:  21 40 01 14          move.l   d0, $114(a0)
  0070d2:  20 6e ff fc          movea.l  -$4(a6), a0
  0070d6:  21 40 00 c8          move.l   d0, $c8(a0)
  0070da:  20 6e ff fc          movea.l  -$4(a6), a0
  0070de:  21 40 05 e0          move.l   d0, $5e0(a0)
  0070e2:  20 6e ff fc          movea.l  -$4(a6), a0
  0070e6:  52 68 01 80          addq.w   #$1, $180(a0)
  0070ea:  20 6e ff fc          movea.l  -$4(a6), a0
  0070ee:  42 28 05 e4          clr.b    $5e4(a0)
  0070f2:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0070f6:  61 ff ff ff f2 b8    bsr.l    $63b0  ; -> sub_63b0
  0070fc:  55 8f                subq.l   #$2, a7
  0070fe:  2f 3c 61 64 64 72    move.l   #$61646472, -(a7)  ; 'addr'
  007104:  48 6e ff ec          pea.l    -$14(a6)
  007108:  61 ff 00 00 4f 32    bsr.l    $c03c  ; -> sub_c03c
  00710e:  4a 5f                tst.w    (a7)+
  007110:  58 4f                addq.w   #$4, a7
  007112:  66 16                bne.b    $712a  ; -> L712a
  007114:  20 2e ff ec          move.l   -$14(a6), d0
  007118:  08 00 00 00          btst.b   #$0, d0
  00711c:  67 0c                beq.b    $712a  ; -> L712a
  00711e:  20 6e ff fc          movea.l  -$4(a6), a0
  007122:  00 a8 00 00 02 00 00 04 ori.l    #$200, $4(a0)
L712a:
  00712a:  70 00                moveq    #$0, d0
  00712c:  2d 40 ff ec          move.l   d0, -$14(a6)
L7130:
  007130:  20 6e ff fc          movea.l  -$4(a6), a0
  007134:  20 68 00 10          movea.l  $10(a0), a0
  007138:  2d 48 ff e8          move.l   a0, -$18(a6)
  00713c:  70 02                moveq    #$2, d0
  00713e:  20 80                move.l   d0, (a0)
  007140:  72 00                moveq    #$0, d1
  007142:  27 41 00 18          move.l   d1, $18(a3)
  007146:  27 41 00 20          move.l   d1, $20(a3)
  00714a:  70 01                moveq    #$1, d0
  00714c:  27 40 00 48          move.l   d0, $48(a3)
  007150:  20 6e ff fc          movea.l  -$4(a6), a0
  007154:  21 41 00 20          move.l   d1, $20(a0)
  007158:  27 41 00 4c          move.l   d1, $4c(a3)
  00715c:  20 6e ff fc          movea.l  -$4(a6), a0
  007160:  27 68 00 04 00 50    move.l   $4(a0), $50(a3)
  007166:  27 41 00 28          move.l   d1, $28(a3)
  00716a:  4a ae ff ec          tst.l    -$14(a6)
  00716e:  66 04                bne.b    $7174  ; -> L7174
  007170:  74 05                moveq    #$5, d2
  007172:  60 0c                bra.b    $7180  ; -> L7180
L7174:
  007174:  20 6e ff fc          movea.l  -$4(a6), a0
  007178:  70 00                moveq    #$0, d0
  00717a:  30 28 00 02          move.w   $2(a0), d0
  00717e:  24 00                move.l   d0, d2
L7180:
  007180:  70 00                moveq    #$0, d0
  007182:  30 02                move.w   d2, d0
  007184:  2e 00                move.l   d0, d7
  007186:  de b8 01 6a          add.l    $16a.w, d7
  00718a:  70 ff                moveq    #$ff, d0
  00718c:  27 40 00 14          move.l   d0, $14(a3)
  007190:  60 24                bra.b    $71b6  ; -> L71b6
L7192:
  007192:  4a ab 00 28          tst.l    $28(a3)
  007196:  67 12                beq.b    $71aa  ; -> L71aa
  007198:  20 6e ff fc          movea.l  -$4(a6), a0
  00719c:  48 68 00 24          pea.l    $24(a0)
  0071a0:  2f 0b                move.l   a3, -(a7)
  0071a2:  61 ff ff ff f2 9e    bsr.l    $6442  ; -> sub_6442
  0071a8:  50 4f                addq.w   #$8, a7
L71aa:
  0071aa:  4a ab 00 18          tst.l    $18(a3)
  0071ae:  67 06                beq.b    $71b6  ; -> L71b6
  0071b0:  4a ab 00 28          tst.l    $28(a3)
  0071b4:  67 06                beq.b    $71bc  ; -> L71bc
L71b6:
  0071b6:  be b8 01 6a          cmp.l    $16a.w, d7
  0071ba:  6c d6                bge.b    $7192  ; -> L7192
L71bc:
  0071bc:  4a ae ff ec          tst.l    -$14(a6)
  0071c0:  67 06                beq.b    $71c8  ; -> L71c8
  0071c2:  be b8 01 6a          cmp.l    $16a.w, d7
  0071c6:  6e 12                bgt.b    $71da  ; -> L71da
L71c8:
  0071c8:  20 2e ff ec          move.l   -$14(a6), d0
  0071cc:  52 ae ff ec          addq.l   #$1, -$14(a6)
  0071d0:  70 04                moveq    #$4, d0
  0071d2:  b0 ae ff ec          cmp.l    -$14(a6), d0
  0071d6:  6e 00 ff 58          bgt.w    $7130  ; -> L7130
L71da:
  0071da:  70 04                moveq    #$4, d0
  0071dc:  b0 ae ff ec          cmp.l    -$14(a6), d0
  0071e0:  66 40                bne.b    $7222  ; -> L7222
  0071e2:  70 01                moveq    #$1, d0
  0071e4:  2f 00                move.l   d0, -(a7)
  0071e6:  72 03                moveq    #$3, d1
  0071e8:  2f 01                move.l   d1, -(a7)
  0071ea:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0071ee:  61 ff 00 00 04 0e    bsr.l    $75fe  ; -> sub_75fe
  0071f4:  20 6e ff fc          movea.l  -$4(a6), a0
  0071f8:  00 a8 00 00 00 10 00 1c ori.l    #$10, $1c(a0)
  007200:  4f ef 00 0c          lea.l    $c(a7), a7
L7204:
  007204:  20 6e ff f0          movea.l  -$10(a6), a0
  007208:  20 68 00 08          movea.l  $8(a0), a0
  00720c:  4a 90                tst.l    (a0)
  00720e:  66 f4                bne.b    $7204  ; -> L7204
  007210:  55 8f                subq.l   #$2, a7
  007212:  1f 06                move.b   d6, -(a7)
  007214:  61 ff 00 00 4e 04    bsr.l    $c01a  ; -> HWPrivProbe
  00721a:  70 ff                moveq    #$ff, d0
  00721c:  54 4f                addq.w   #$2, a7
  00721e:  60 00 01 9a          bra.w    $73ba  ; -> L73ba
L7222:
  007222:  70 01                moveq    #$1, d0
  007224:  b0 ab 00 1c          cmp.l    $1c(a3), d0
  007228:  67 40                beq.b    $726a  ; -> L726a
  00722a:  70 01                moveq    #$1, d0
  00722c:  2f 00                move.l   d0, -(a7)
  00722e:  72 03                moveq    #$3, d1
  007230:  2f 01                move.l   d1, -(a7)
  007232:  2f 2e 00 08          move.l   $8(a6), -(a7)
  007236:  61 ff 00 00 03 c6    bsr.l    $75fe  ; -> sub_75fe
  00723c:  20 6e ff fc          movea.l  -$4(a6), a0
  007240:  00 a8 00 00 00 10 00 1c ori.l    #$10, $1c(a0)
  007248:  4f ef 00 0c          lea.l    $c(a7), a7
L724c:
  00724c:  20 6e ff f0          movea.l  -$10(a6), a0
  007250:  20 68 00 08          movea.l  $8(a0), a0
  007254:  4a 90                tst.l    (a0)
  007256:  66 f4                bne.b    $724c  ; -> L724c
  007258:  55 8f                subq.l   #$2, a7
  00725a:  1f 06                move.b   d6, -(a7)
  00725c:  61 ff 00 00 4d bc    bsr.l    $c01a  ; -> HWPrivProbe
  007262:  70 ff                moveq    #$ff, d0
  007264:  54 4f                addq.w   #$2, a7
  007266:  60 00 01 52          bra.w    $73ba  ; -> L73ba
L726a:
  00726a:  20 6e ff fc          movea.l  -$4(a6), a0
  00726e:  27 68 00 14 00 20    move.l   $14(a0), $20(a3)
  007274:  20 3c 00 0f ff ff    move.l   #$fffff, d0
  00727a:  c0 ab 00 54          and.l    $54(a3), d0
  00727e:  22 0b                move.l   a3, d1
  007280:  24 3c ff f0 00 00    move.l   #$fff00000, d2
  007286:  c4 81                and.l    d1, d2
  007288:  84 80                or.l     d0, d2
  00728a:  20 6e ff fc          movea.l  -$4(a6), a0
  00728e:  21 42 00 18          move.l   d2, $18(a0)
  007292:  20 6e ff fc          movea.l  -$4(a6), a0
  007296:  00 a8 00 00 00 01 00 1c ori.l    #$1, $1c(a0)
L729e:
  00729e:  20 6e ff f0          movea.l  -$10(a6), a0
  0072a2:  20 68 00 08          movea.l  $8(a0), a0
  0072a6:  4a 90                tst.l    (a0)
  0072a8:  66 f4                bne.b    $729e  ; -> L729e
  0072aa:  55 8f                subq.l   #$2, a7
  0072ac:  1f 06                move.b   d6, -(a7)
  0072ae:  61 ff 00 00 4d 6a    bsr.l    $c01a  ; -> HWPrivProbe
  0072b4:  70 00                moveq    #$0, d0
  0072b6:  2f 00                move.l   d0, -(a7)
  0072b8:  2f 00                move.l   d0, -(a7)
  0072ba:  2f 00                move.l   d0, -(a7)
  0072bc:  61 ff ff ff d7 06    bsr.l    $49c4  ; -> EngineDispatch
  0072c2:  61 ff 00 00 04 e2    bsr.l    $77a6  ; -> sub_77a6
  0072c8:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0072cc:  61 ff ff ff d6 80    bsr.l    $494e  ; -> sub_494e
  0072d2:  72 01                moveq    #$1, d1
  0072d4:  b2 80                cmp.l    d0, d1
  0072d6:  4f ef 00 12          lea.l    $12(a7), a7
  0072da:  67 4a                beq.b    $7326  ; -> L7326
  0072dc:  20 6e ff fc          movea.l  -$4(a6), a0
  0072e0:  70 02                moveq    #$2, d0
  0072e2:  c0 a8 00 1c          and.l    $1c(a0), d0
  0072e6:  67 18                beq.b    $7300  ; -> L7300
  0072e8:  70 00                moveq    #$0, d0
  0072ea:  2f 00                move.l   d0, -(a7)
  0072ec:  72 04                moveq    #$4, d1
  0072ee:  2f 01                move.l   d1, -(a7)
  0072f0:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0072f4:  61 ff 00 00 03 08    bsr.l    $75fe  ; -> sub_75fe
  0072fa:  4f ef 00 0c          lea.l    $c(a7), a7
  0072fe:  60 16                bra.b    $7316  ; -> L7316
L7300:
  007300:  70 01                moveq    #$1, d0
  007302:  2f 00                move.l   d0, -(a7)
  007304:  72 04                moveq    #$4, d1
  007306:  2f 01                move.l   d1, -(a7)
  007308:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00730c:  61 ff 00 00 02 f0    bsr.l    $75fe  ; -> sub_75fe
  007312:  4f ef 00 0c          lea.l    $c(a7), a7
L7316:
  007316:  20 6e ff fc          movea.l  -$4(a6), a0
  00731a:  08 a8 00 00 00 1f    bclr.b   #$0, $1f(a0)
  007320:  70 ff                moveq    #$ff, d0
  007322:  60 00 00 96          bra.w    $73ba  ; -> L73ba
L7326:
  007326:  20 6e ff fc          movea.l  -$4(a6), a0
  00732a:  4a a8 00 c4          tst.l    $c4(a0)
  00732e:  66 00 00 88          bne.w    $73b8  ; -> L73b8
  007332:  60 28                bra.b    $735c  ; -> L735c
L7334:
  007334:  04 ac 00 00 00 c8 02 68 subi.l   #$c8, $268(a4)
  00733c:  4a ac 02 68          tst.l    $268(a4)
  007340:  62 1a                bhi.b    $735c  ; -> L735c
  007342:  70 01                moveq    #$1, d0
  007344:  2f 00                move.l   d0, -(a7)
  007346:  72 09                moveq    #$9, d1
  007348:  2f 01                move.l   d1, -(a7)
  00734a:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00734e:  61 ff 00 00 02 ae    bsr.l    $75fe  ; -> sub_75fe
  007354:  70 ff                moveq    #$ff, d0
  007356:  4f ef 00 0c          lea.l    $c(a7), a7
  00735a:  60 5e                bra.b    $73ba  ; -> L73ba
L735c:
  00735c:  2f 2c 02 68          move.l   $268(a4), -(a7)
  007360:  20 6e ff fc          movea.l  -$4(a6), a0
  007364:  2f 28 00 0c          move.l   $c(a0), -(a7)
  007368:  61 ff 00 00 00 5a    bsr.l    $73c4  ; -> sub_73c4
  00736e:  26 40                movea.l  d0, a3
  007370:  20 0b                move.l   a3, d0
  007372:  50 4f                addq.w   #$8, a7
  007374:  67 be                beq.b    $7334  ; -> L7334
  007376:  20 2c 02 68          move.l   $268(a4), d0
  00737a:  72 64                moveq    #$64, d1
  00737c:  90 81                sub.l    d1, d0
  00737e:  20 6e ff fc          movea.l  -$4(a6), a0
  007382:  21 40 00 bc          move.l   d0, $bc(a0)
  007386:  20 6e ff fc          movea.l  -$4(a6), a0
  00738a:  21 4b 00 c4          move.l   a3, $c4(a0)
  00738e:  20 6e ff fc          movea.l  -$4(a6), a0
  007392:  21 4b 00 ac          move.l   a3, $ac(a0)
  007396:  20 6e ff fc          movea.l  -$4(a6), a0
  00739a:  22 48                movea.l  a0, a1
  00739c:  23 68 00 ac 00 b0    move.l   $ac(a0), $b0(a1)
  0073a2:  20 6e ff fc          movea.l  -$4(a6), a0
  0073a6:  70 00                moveq    #$0, d0
  0073a8:  21 40 00 b4          move.l   d0, $b4(a0)
  0073ac:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0073b0:  61 ff ff ff ef fe    bsr.l    $63b0  ; -> sub_63b0
  0073b6:  58 4f                addq.w   #$4, a7
L73b8:
  0073b8:  70 00                moveq    #$0, d0
L73ba:
  0073ba:  4c ee 18 c8 ff d4    movem.l  -$2c(a6), d3/d6-d7/a3-a4
  0073c0:  4e 5e                unlk     a6
  0073c2:  4e 75                rts      
sub_73c4:
  0073c4:  4e 56 ff fc          link.w   a6, #$fffc
  0073c8:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  0073cc:  2e 2e 00 0c          move.l   $c(a6), d7
  0073d0:  20 6e 00 08          movea.l  $8(a6), a0
  0073d4:  26 68 00 10          movea.l  $10(a0), a3
  0073d8:  20 0b                move.l   a3, d0
  0073da:  66 06                bne.b    $73e2  ; -> L73e2
  0073dc:  70 00                moveq    #$0, d0
  0073de:  60 00 00 d4          bra.w    $74b4  ; -> L74b4
L73e2:
  0073e2:  20 0b                move.l   a3, d0
  0073e4:  22 3c 00 0f ff ff    move.l   #$fffff, d1
  0073ea:  c2 80                and.l    d0, d1
  0073ec:  20 3c ff f0 00 00    move.l   #$fff00000, d0
  0073f2:  c0 ae 00 08          and.l    $8(a6), d0
  0073f6:  80 81                or.l     d1, d0
  0073f8:  28 40                movea.l  d0, a4
  0073fa:  0c 94 00 01 00 00    cmpi.l   #$10000, (a4)
  007400:  63 18                bls.b    $741a  ; -> L741a
  007402:  20 6e 00 08          movea.l  $8(a6), a0
  007406:  20 3c 00 00 ff fc    move.l   #$fffc, d0
  00740c:  c0 a8 00 10          and.l    $10(a0), d0
  007410:  22 3c 00 00 ff f0    move.l   #$fff0, d1
  007416:  92 80                sub.l    d0, d1
  007418:  28 81                move.l   d1, (a4)
L741a:
  00741a:  20 07                move.l   d7, d0
  00741c:  56 80                addq.l   #$3, d0
  00741e:  72 fc                moveq    #$fc, d1
  007420:  c2 80                and.l    d0, d1
  007422:  2e 01                move.l   d1, d7
  007424:  20 0b                move.l   a3, d0
  007426:  22 3c 00 0f ff ff    move.l   #$fffff, d1
  00742c:  c2 80                and.l    d0, d1
  00742e:  20 3c ff f0 00 00    move.l   #$fff00000, d0
  007434:  c0 ae 00 08          and.l    $8(a6), d0
  007438:  80 81                or.l     d1, d0
  00743a:  28 40                movea.l  d0, a4
  00743c:  60 1c                bra.b    $745a  ; -> L745a
L743e:
  00743e:  26 6c 00 04          movea.l  $4(a4), a3
  007442:  20 3c 00 0f ff ff    move.l   #$fffff, d0
  007448:  c0 ac 00 04          and.l    $4(a4), d0
  00744c:  22 3c ff f0 00 00    move.l   #$fff00000, d1
  007452:  c2 ae 00 08          and.l    $8(a6), d1
  007456:  82 80                or.l     d0, d1
  007458:  28 41                movea.l  d1, a4
L745a:
  00745a:  4a ac 00 04          tst.l    $4(a4)
  00745e:  66 de                bne.b    $743e  ; -> L743e
  007460:  be 94                cmp.l    (a4), d7
  007462:  63 04                bls.b    $7468  ; -> L7468
  007464:  70 00                moveq    #$0, d0
  007466:  60 4c                bra.b    $74b4  ; -> L74b4
L7468:
  007468:  20 0b                move.l   a3, d0
  00746a:  d0 87                add.l    d7, d0
  00746c:  50 80                addq.l   #$8, d0
  00746e:  29 40 00 04          move.l   d0, $4(a4)
  007472:  26 40                movea.l  d0, a3
  007474:  20 0b                move.l   a3, d0
  007476:  22 3c 00 0f ff ff    move.l   #$fffff, d1
  00747c:  c2 80                and.l    d0, d1
  00747e:  20 3c ff f0 00 00    move.l   #$fff00000, d0
  007484:  c0 ae 00 08          and.l    $8(a6), d0
  007488:  80 81                or.l     d1, d0
  00748a:  2d 40 ff fc          move.l   d0, -$4(a6)
  00748e:  20 40                movea.l  d0, a0
  007490:  70 00                moveq    #$0, d0
  007492:  21 40 00 04          move.l   d0, $4(a0)
  007496:  22 07                move.l   d7, d1
  007498:  50 81                addq.l   #$8, d1
  00749a:  24 14                move.l   (a4), d2
  00749c:  94 81                sub.l    d1, d2
  00749e:  20 6e ff fc          movea.l  -$4(a6), a0
  0074a2:  20 82                move.l   d2, (a0)
  0074a4:  20 6e 00 08          movea.l  $8(a6), a0
  0074a8:  21 4b 00 40          move.l   a3, $40(a0)
  0074ac:  28 87                move.l   d7, (a4)
  0074ae:  22 0c                move.l   a4, d1
  0074b0:  50 81                addq.l   #$8, d1
  0074b2:  20 01                move.l   d1, d0
L74b4:
  0074b4:  4c ee 18 80 ff f0    movem.l  -$10(a6), d7/a3-a4
  0074ba:  4e 5e                unlk     a6
  0074bc:  4e 75                rts      
sub_74be:
  0074be:  4e 56 00 00          link.w   a6, #$0
  0074c2:  48 e7 03 08          movem.l  d6-d7/a4, -(a7)
  0074c6:  2c 2e 00 08          move.l   $8(a6), d6
  0074ca:  a1 1a                dc.w     $a11a  ; _GetZone
  0074cc:  28 48                movea.l  a0, a4
  0074ce:  20 78 02 a6          movea.l  $2a6.w, a0
  0074d2:  a0 1b                dc.w     $a01b  ; _SetZone
  0074d4:  4a 86                tst.l    d6
  0074d6:  67 0e                beq.b    $74e6  ; -> L74e6
  0074d8:  20 06                move.l   d6, d0
  0074da:  a1 1e                dc.w     $a11e  ; _NewPtr
  0074dc:  2e 08                move.l   a0, d7
  0074de:  20 4c                movea.l  a4, a0
  0074e0:  a0 1b                dc.w     $a01b  ; _SetZone
  0074e2:  20 07                move.l   d7, d0
  0074e4:  60 06                bra.b    $74ec  ; -> L74ec
L74e6:
  0074e6:  20 4c                movea.l  a4, a0
  0074e8:  a0 1b                dc.w     $a01b  ; _SetZone
  0074ea:  70 00                moveq    #$0, d0
L74ec:
  0074ec:  4c ee 10 c0 ff f4    movem.l  -$c(a6), d6-d7/a4
  0074f2:  4e 5e                unlk     a6
  0074f4:  4e 75                rts      
sub_74f6:
  0074f6:  4e 56 00 00          link.w   a6, #$0
  0074fa:  2f 0c                move.l   a4, -(a7)
  0074fc:  28 6e 00 08          movea.l  $8(a6), a4
  007500:  20 0c                move.l   a4, d0
  007502:  22 3c f0 00 00 00    move.l   #$f0000000, d1
  007508:  c2 80                and.l    d0, d1
  00750a:  0c 81 f0 00 00 00    cmpi.l   #$f0000000, d1
  007510:  66 04                bne.b    $7516  ; -> L7516
  007512:  20 0c                move.l   a4, d0
  007514:  60 16                bra.b    $752c  ; -> L752c
L7516:
  007516:  20 0c                move.l   a4, d0
  007518:  22 3c 0f ff ff ff    move.l   #$fffffff, d1
  00751e:  c2 80                and.l    d0, d1
  007520:  70 1c                moveq    #$1c, d0
  007522:  24 2e 00 0c          move.l   $c(a6), d2
  007526:  e1 aa                lsl.l    d0, d2
  007528:  d4 81                add.l    d1, d2
  00752a:  20 02                move.l   d2, d0
L752c:
  00752c:  28 6e ff fc          movea.l  -$4(a6), a4
  007530:  4e 5e                unlk     a6
  007532:  4e 75                rts      
sub_7534:
  007534:  4e 56 ff fe          link.w   a6, #$fffe
  007538:  2f 0c                move.l   a4, -(a7)
  00753a:  1d 7c 00 01 ff ff    move.b   #$1, -$1(a6)
  007540:  2f 2e 00 10          move.l   $10(a6), -(a7)
  007544:  2f 2e 00 08          move.l   $8(a6), -(a7)
  007548:  61 ff ff ff ff ac    bsr.l    $74f6  ; -> sub_74f6
  00754e:  28 40                movea.l  d0, a4
  007550:  41 ee ff ff          lea.l    -$1(a6), a0
  007554:  10 10                move.b   (a0), d0
  007556:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  007558:  10 80                move.b   d0, (a0)
  00755a:  28 ae 00 0c          move.l   $c(a6), (a4)
  00755e:  41 ee ff ff          lea.l    -$1(a6), a0
  007562:  10 10                move.b   (a0), d0
  007564:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  007566:  10 80                move.b   d0, (a0)
  007568:  28 6e ff fa          movea.l  -$6(a6), a4
  00756c:  4e 5e                unlk     a6
  00756e:  4e 75                rts      
sub_7570:
  007570:  4e 56 00 00          link.w   a6, #$0
  007574:  2f 0c                move.l   a4, -(a7)
  007576:  28 6e 00 08          movea.l  $8(a6), a4
  00757a:  20 54                movea.l  (a4), a0
  00757c:  20 3c 00 00 00 80    move.l   #$80, d0
  007582:  c0 a8 01 28          and.l    $128(a0), d0
  007586:  67 04                beq.b    $758c  ; -> L758c
  007588:  70 00                moveq    #$0, d0
  00758a:  60 6a                bra.b    $75f6  ; -> L75f6
L758c:
  00758c:  20 54                movea.l  (a4), a0
  00758e:  70 02                moveq    #$2, d0
  007590:  c0 a8 00 08          and.l    $8(a0), d0
  007594:  67 5e                beq.b    $75f4  ; -> L75f4
  007596:  70 00                moveq    #$0, d0
  007598:  30 10                move.w   (a0), d0
  00759a:  2f 00                move.l   d0, -(a7)
  00759c:  2f 28 01 68          move.l   $168(a0), -(a7)
  0075a0:  20 28 01 30          move.l   $130(a0), d0
  0075a4:  72 18                moveq    #$18, d1
  0075a6:  d0 81                add.l    d1, d0
  0075a8:  2f 00                move.l   d0, -(a7)
  0075aa:  61 ff ff ff ff 88    bsr.l    $7534  ; -> sub_7534
  0075b0:  20 54                movea.l  (a4), a0
  0075b2:  70 00                moveq    #$0, d0
  0075b4:  30 10                move.w   (a0), d0
  0075b6:  2f 00                move.l   d0, -(a7)
  0075b8:  70 ff                moveq    #$ff, d0
  0075ba:  2f 00                move.l   d0, -(a7)
  0075bc:  22 28 01 30          move.l   $130(a0), d1
  0075c0:  d2 bc 00 00 03 d4    add.l    #$3d4, d1
  0075c6:  2f 01                move.l   d1, -(a7)
  0075c8:  61 ff ff ff ff 6a    bsr.l    $7534  ; -> sub_7534
  0075ce:  20 54                movea.l  (a4), a0
  0075d0:  70 00                moveq    #$0, d0
  0075d2:  30 10                move.w   (a0), d0
  0075d4:  2f 00                move.l   d0, -(a7)
  0075d6:  70 ff                moveq    #$ff, d0
  0075d8:  2f 00                move.l   d0, -(a7)
  0075da:  2f 3c 04 00 00 50    move.l   #$4000050, -(a7)  ; MFB reg +$50
  0075e0:  61 ff ff ff ff 52    bsr.l    $7534  ; -> sub_7534
  0075e6:  20 54                movea.l  (a4), a0
  0075e8:  00 a8 00 00 00 04 00 08 ori.l    #$4, $8(a0)
  0075f0:  4f ef 00 24          lea.l    $24(a7), a7
L75f4:
  0075f4:  70 00                moveq    #$0, d0
L75f6:
  0075f6:  28 6e ff fc          movea.l  -$4(a6), a4
  0075fa:  4e 5e                unlk     a6
  0075fc:  4e 75                rts      
sub_75fe:
  0075fe:  4e 56 00 00          link.w   a6, #$0
  007602:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  007606:  59 8f                subq.l   #$4, a7
  007608:  2f 38 08 88          move.l   $888.w, -(a7)
  00760c:  61 ff 00 00 4c 3c    bsr.l    $c24a  ; -> Strip24
  007612:  20 5f                movea.l  (a7)+, a0
  007614:  20 50                movea.l  (a0), a0
  007616:  28 50                movea.l  (a0), a4
  007618:  20 6e 00 08          movea.l  $8(a6), a0
  00761c:  26 50                movea.l  (a0), a3
  00761e:  37 6e 00 0e 01 5c    move.w   $e(a6), $15c(a3)
  007624:  20 3c 00 00 00 80    move.l   #$80, d0
  00762a:  c0 ab 01 28          and.l    $128(a3), d0
  00762e:  66 00 00 90          bne.w    $76c0  ; -> L76c0
  007632:  4a ae 00 10          tst.l    $10(a6)
  007636:  6f 00 00 88          ble.w    $76c0  ; -> L76c0
  00763a:  20 3c 00 00 02 00    move.l   #$200, d0
  007640:  c0 ab 00 08          and.l    $8(a3), d0
  007644:  66 7a                bne.b    $76c0  ; -> L76c0
  007646:  42 2c 02 57          clr.b    $257(a4)
  00764a:  00 ab 00 00 02 00 00 08 ori.l    #$200, $8(a3)
  007652:  7e 00                moveq    #$0, d7
  007654:  47 ec 02 78          lea.l    $278(a4), a3
  007658:  60 12                bra.b    $766c  ; -> L766c
L765a:
  00765a:  4a 93                tst.l    (a3)
  00765c:  67 06                beq.b    $7664  ; -> L7664
  00765e:  29 ab 00 04 7c 14    move.l   $4(a3), $14(a4, d7.l)
L7664:
  007664:  20 07                move.l   d7, d0
  007666:  52 87                addq.l   #$1, d7
  007668:  47 eb 00 10          lea.l    $10(a3), a3
L766c:
  00766c:  30 2c 02 2c          move.w   $22c(a4), d0
  007670:  48 c0                ext.l    d0
  007672:  b0 87                cmp.l    d7, d0
  007674:  6e e4                bgt.b    $765a  ; -> L765a
  007676:  70 24                moveq    #$24, d0
  007678:  2f 00                move.l   d0, -(a7)
  00767a:  61 ff ff ff fe 42    bsr.l    $74be  ; -> sub_74be
  007680:  26 40                movea.l  d0, a3
  007682:  20 0b                move.l   a3, d0
  007684:  58 4f                addq.w   #$4, a7
  007686:  67 38                beq.b    $76c0  ; -> L76c0
  007688:  37 7c 00 08 00 04    move.w   #$8, $4(a3)
  00768e:  42 6b 00 0e          clr.w    $e(a3)
  007692:  70 00                moveq    #$0, d0
  007694:  27 40 00 10          move.l   d0, $10(a3)
  007698:  27 40 00 14          move.l   d0, $14(a3)
  00769c:  41 fa 00 2c          lea.l    $76ca(pc), a0
  0076a0:  27 48 00 18          move.l   a0, $18(a3)
  0076a4:  41 fb 01 70 00 00 00 7a lea.l    $7a(a16, invalid.w), a0
  0076ac:  27 48 00 1c          move.l   a0, $1c(a3)
  0076b0:  27 40 00 20          move.l   d0, $20(a3)
  0076b4:  55 8f                subq.l   #$2, a7
  0076b6:  2f 0b                move.l   a3, -(a7)
  0076b8:  20 5f                movea.l  (a7)+, a0
  0076ba:  a0 5e                dc.w     $a05e  ; _NMInstall
  0076bc:  3e 80                move.w   d0, (a7)
  0076be:  54 4f                addq.w   #$2, a7
L76c0:
  0076c0:  4c ee 18 80 ff f4    movem.l  -$c(a6), d7/a3-a4
  0076c6:  4e 5e                unlk     a6
  0076c8:  4e 75                rts      
  0076ca:  53 47                subq.w   #$1, d7
  0076cc:  72 61                moveq    #$61, d1
  0076ce:  70 68                moveq    #$68, d0
  0076d0:  69 63                bvs.b    $7735
  0076d2:  73                   dc.b     $73  ; s
  0076d3:  20 61                movea.l  -(a1), a0
  0076d5:  63 63                bls.b    $773a
  0076d7:  65 6c                bcs.b    $7745
  0076d9:  65 72                bcs.b    $774d
  0076db:  61 74                bsr.b    $7751
  0076dd:  6f 72                ble.b    $7751
  0076df:  20 69 73 20          movea.l  $7320(a1), a0
  0076e3:  68 61                bvc.b    $7746
  0076e5:  76 69                moveq    #$69, d3
  0076e7:  6e 67                bgt.b    $7750
  0076e9:  20 64                movea.l  -(a4), a0
  0076eb:  69 66                bvs.b    $7753
  0076ed:  66 69                bne.b    $7758
  0076ef:  63 75                bls.b    $7766
  0076f1:  6c 74                bge.b    $7767
  0076f3:  79                   dc.b     $79  ; y
  0076f4:  2e 20                move.l   -(a0), d7
  0076f6:  59 6f 75 20          subq.w   #$4, $7520(a7)
  0076fa:  77                   dc.b     $77  ; w
  0076fb:  69 6c                bvs.b    $7769
  0076fd:  6c 20                bge.b    $771f
  0076ff:  6e 65                bgt.b    $7766
  007701:  65 64                bcs.b    $7767
  007703:  20 74 6f 20 72 65    movea.l  $7265(a4, d6.l * 8), a0
  007709:  62 6f                bhi.b    $777a
  00770b:  6f 74                ble.b    $7781
  00770d:  20 74 6f 20 72 65    movea.l  $7265(a4, d6.l * 8), a0
  007713:  2d 65 6e 61          move.l   -(a5), $6e61(a6)
  007717:  62 6c                bhi.b    $7785
  007719:  65 20                bcs.b    $773b
  00771b:  69 74                bvs.b    $7791
  00771d:  2e 00                move.l   d0, d7
  00771f:  00                   dc.b     $00  ; .
  007720:  4e 56 00 00          link.w   a6, #$0
  007724:  2f 0c                move.l   a4, -(a7)
  007726:  28 6e 00 08          movea.l  $8(a6), a4
  00772a:  55 8f                subq.l   #$2, a7
  00772c:  2f 0c                move.l   a4, -(a7)
  00772e:  20 5f                movea.l  (a7)+, a0
  007730:  a0 5f                dc.w     $a05f  ; _NMRemove
  007732:  3e 80                move.w   d0, (a7)
  007734:  20 4c                movea.l  a4, a0
  007736:  a0 1f                dc.w     $a01f  ; _DisposePtr
  007738:  28 6e ff fc          movea.l  -$4(a6), a4
  00773c:  4e 5e                unlk     a6
  00773e:  4e 74 00 04          rtd      #$4
sub_7742:
  007742:  4e 56 00 00          link.w   a6, #$0
  007746:  48 e7 01 08          movem.l  d7/a4, -(a7)
  00774a:  2e 2e 00 08          move.l   $8(a6), d7
  00774e:  59 8f                subq.l   #$4, a7
  007750:  aa 29                dc.w     $aa29  ; _GetDeviceList
  007752:  28 5f                movea.l  (a7)+, a4
  007754:  60 18                bra.b    $776e  ; -> L776e
L7756:
  007756:  2f 0c                move.l   a4, -(a7)
  007758:  61 ff 00 00 00 24    bsr.l    $777e  ; -> sub_777e
  00775e:  be 80                cmp.l    d0, d7
  007760:  58 4f                addq.w   #$4, a7
  007762:  66 04                bne.b    $7768  ; -> L7768
  007764:  20 0c                move.l   a4, d0
  007766:  60 0c                bra.b    $7774  ; -> L7774
L7768:
  007768:  20 54                movea.l  (a4), a0
  00776a:  28 68 00 1e          movea.l  $1e(a0), a4
L776e:
  00776e:  20 0c                move.l   a4, d0
  007770:  66 e4                bne.b    $7756  ; -> L7756
  007772:  70 00                moveq    #$0, d0
L7774:
  007774:  4c ee 10 80 ff f8    movem.l  -$8(a6), d7/a4
  00777a:  4e 5e                unlk     a6
  00777c:  4e 75                rts      
sub_777e:
  00777e:  4e 56 00 00          link.w   a6, #$0
  007782:  2f 0c                move.l   a4, -(a7)
  007784:  59 8f                subq.l   #$4, a7
  007786:  20 6e 00 08          movea.l  $8(a6), a0
  00778a:  20 50                movea.l  (a0), a0
  00778c:  3f 10                move.w   (a0), -(a7)
  00778e:  61 ff 00 00 48 70    bsr.l    $c000  ; -> sub_c000
  007794:  28 5f                movea.l  (a7)+, a4
  007796:  20 54                movea.l  (a4), a0
  007798:  10 28 00 28          move.b   $28(a0), d0
  00779c:  49 c0                extb.l   d0
  00779e:  28 6e ff fc          movea.l  -$4(a6), a4
  0077a2:  4e 5e                unlk     a6
  0077a4:  4e 75                rts      
sub_77a6:
  0077a6:  4e 56 ff 3c          link.w   a6, #$ff3c
  0077aa:  48 e7 1f 18          movem.l  d3-d7/a3-a4, -(a7)
  0077ae:  49 ee ff e6          lea.l    -$1a(a6), a4
  0077b2:  78 00                moveq    #$0, d4
  0077b4:  70 00                moveq    #$0, d0
  0077b6:  2d 40 ff f2          move.l   d0, -$e(a6)
  0077ba:  70 00                moveq    #$0, d0
  0077bc:  2f 00                move.l   d0, -(a7)
  0077be:  2f 00                move.l   d0, -(a7)
  0077c0:  72 12                moveq    #$12, d1
  0077c2:  2f 01                move.l   d1, -(a7)
  0077c4:  61 ff ff ff d1 fe    bsr.l    $49c4  ; -> EngineDispatch
  0077ca:  70 00                moveq    #$0, d0
  0077cc:  2d 40 ff d2          move.l   d0, -$2e(a6)
  0077d0:  55 8f                subq.l   #$2, a7
  0077d2:  2f 3c 76 6d 20 20    move.l   #$766d2020, -(a7)  ; 'vm  '
  0077d8:  48 6e ff d2          pea.l    -$2e(a6)
  0077dc:  61 ff 00 00 48 5e    bsr.l    $c03c  ; -> sub_c03c
  0077e2:  4a 5f                tst.w    (a7)+
  0077e4:  4f ef 00 0c          lea.l    $c(a7), a7
  0077e8:  66 00 01 ac          bne.w    $7996  ; -> L7996
  0077ec:  4a ae ff d2          tst.l    -$2e(a6)
  0077f0:  66 00 01 a4          bne.w    $7996  ; -> L7996
  0077f4:  59 8f                subq.l   #$4, a7
  0077f6:  3f 3c a1 5c          move.w   #$a15c, -(a7)
  0077fa:  70 00                moveq    #$0, d0
  0077fc:  1f 00                move.b   d0, -(a7)
  0077fe:  61 ff 00 00 47 ec    bsr.l    $bfec  ; -> sub_bfec
  007804:  59 8f                subq.l   #$4, a7
  007806:  3f 3c a8 9f          move.w   #$a89f, -(a7)
  00780a:  70 01                moveq    #$1, d0
  00780c:  1f 00                move.b   d0, -(a7)
  00780e:  61 ff 00 00 47 dc    bsr.l    $bfec  ; -> sub_bfec
  007814:  20 1f                move.l   (a7)+, d0
  007816:  b0 9f                cmp.l    (a7)+, d0
  007818:  67 00 01 7c          beq.w    $7996  ; -> L7996
  00781c:  70 00                moveq    #$0, d0
  00781e:  2d 40 ff 82          move.l   d0, -$7e(a6)
  007822:  2d 78 1e f4 ff 86    move.l   $1ef4.w, -$7a(a6)
  007828:  72 08                moveq    #$8, d1
  00782a:  2d 41 ff ca          move.l   d1, -$36(a6)
  00782e:  26 6e ff 82          movea.l  -$7e(a6), a3
  007832:  55 8f                subq.l   #$2, a7
  007834:  48 6e ff 82          pea.l    -$7e(a6)
  007838:  48 6e ff ca          pea.l    -$36(a6)
  00783c:  61 ff 00 00 4a 26    bsr.l    $c264  ; -> sub_c264
  007842:  3d 5f ff fa          move.w   (a7)+, -$6(a6)
  007846:  20 3c 00 ff ff ff    move.l   #$ffffff, d0
  00784c:  c0 b8 02 ae          and.l    $2ae.w, d0
  007850:  2d 40 ff fc          move.l   d0, -$4(a6)
  007854:  4a 6e ff fa          tst.w    -$6(a6)
  007858:  67 50                beq.b    $78aa  ; -> L78aa
  00785a:  20 2e ff 86          move.l   -$7a(a6), d0
  00785e:  b0 ae ff fc          cmp.l    -$4(a6), d0
  007862:  63 46                bls.b    $78aa  ; -> L78aa
  007864:  55 8f                subq.l   #$2, a7
  007866:  2f 3c 61 64 64 72    move.l   #$61646472, -(a7)  ; 'addr'
  00786c:  48 6e ff d2          pea.l    -$2e(a6)
  007870:  61 ff 00 00 47 ca    bsr.l    $c03c  ; -> sub_c03c
  007876:  70 01                moveq    #$1, d0
  007878:  c0 ae ff d2          and.l    -$2e(a6), d0
  00787c:  54 4f                addq.w   #$2, a7
  00787e:  66 2a                bne.b    $78aa  ; -> L78aa
  007880:  2d 6e ff fc ff 86    move.l   -$4(a6), -$7a(a6)
  007886:  70 00                moveq    #$0, d0
  007888:  2d 40 ff 82          move.l   d0, -$7e(a6)
  00788c:  72 08                moveq    #$8, d1
  00788e:  2d 41 ff ca          move.l   d1, -$36(a6)
  007892:  26 6e ff 82          movea.l  -$7e(a6), a3
  007896:  55 8f                subq.l   #$2, a7
  007898:  48 6e ff 82          pea.l    -$7e(a6)
  00789c:  48 6e ff ca          pea.l    -$36(a6)
  0078a0:  61 ff 00 00 49 c2    bsr.l    $c264  ; -> sub_c264
  0078a6:  3d 5f ff fa          move.w   (a7)+, -$6(a6)
L78aa:
  0078aa:  4a 6e ff fa          tst.w    -$6(a6)
  0078ae:  66 00 00 e0          bne.w    $7990  ; -> L7990
  0078b2:  70 01                moveq    #$1, d0
  0078b4:  b0 ae ff ca          cmp.l    -$36(a6), d0
  0078b8:  65 12                bcs.b    $78cc  ; -> L78cc
  0078ba:  70 01                moveq    #$1, d0
  0078bc:  b0 ae ff ca          cmp.l    -$36(a6), d0
  0078c0:  66 00 00 ce          bne.w    $7990  ; -> L7990
  0078c4:  b7 ee ff 8a          cmpa.l   -$76(a6), a3
  0078c8:  67 00 00 c6          beq.w    $7990  ; -> L7990
L78cc:
  0078cc:  70 00                moveq    #$0, d0
  0078ce:  2d 40 ff d2          move.l   d0, -$2e(a6)
  0078d2:  60 40                bra.b    $7914  ; -> L7914
L78d4:
  0078d4:  28 8b                move.l   a3, (a4)
  0078d6:  20 2e ff d2          move.l   -$2e(a6), d0
  0078da:  e7 80                asl.l    #$3, d0
  0078dc:  29 76 08 8a 00 04    move.l   -$76(a6, d0.l), $4(a4)
  0078e2:  20 2e ff d2          move.l   -$2e(a6), d0
  0078e6:  e7 80                asl.l    #$3, d0
  0078e8:  29 76 08 8e 00 08    move.l   -$72(a6, d0.l), $8(a4)
  0078ee:  70 03                moveq    #$3, d0
  0078f0:  2f 00                move.l   d0, -(a7)
  0078f2:  2f 0c                move.l   a4, -(a7)
  0078f4:  72 13                moveq    #$13, d1
  0078f6:  2f 01                move.l   d1, -(a7)
  0078f8:  61 ff ff ff d0 ca    bsr.l    $49c4  ; -> EngineDispatch
  0078fe:  20 2e ff d2          move.l   -$2e(a6), d0
  007902:  e7 80                asl.l    #$3, d0
  007904:  d7 f6 08 8e          adda.l   -$72(a6, d0.l), a3
  007908:  4f ef 00 0c          lea.l    $c(a7), a7
  00790c:  20 2e ff d2          move.l   -$2e(a6), d0
  007910:  52 ae ff d2          addq.l   #$1, -$2e(a6)
L7914:
  007914:  20 2e ff d2          move.l   -$2e(a6), d0
  007918:  b0 ae ff ca          cmp.l    -$36(a6), d0
  00791c:  65 b6                bcs.b    $78d4  ; -> L78d4
  00791e:  60 70                bra.b    $7990  ; -> L7990
L7920:
  007920:  70 08                moveq    #$8, d0
  007922:  2d 40 ff ca          move.l   d0, -$36(a6)
  007926:  26 6e ff 82          movea.l  -$7e(a6), a3
L792a:
  00792a:  55 8f                subq.l   #$2, a7
  00792c:  48 6e ff 82          pea.l    -$7e(a6)
  007930:  48 6e ff ca          pea.l    -$36(a6)
  007934:  61 ff 00 00 49 2e    bsr.l    $c264  ; -> sub_c264
  00793a:  4a 5f                tst.w    (a7)+
  00793c:  66 52                bne.b    $7990  ; -> L7990
  00793e:  70 00                moveq    #$0, d0
  007940:  2d 40 ff d2          move.l   d0, -$2e(a6)
  007944:  60 40                bra.b    $7986  ; -> L7986
L7946:
  007946:  28 8b                move.l   a3, (a4)
  007948:  20 2e ff d2          move.l   -$2e(a6), d0
  00794c:  e7 80                asl.l    #$3, d0
  00794e:  29 76 08 8a 00 04    move.l   -$76(a6, d0.l), $4(a4)
  007954:  20 2e ff d2          move.l   -$2e(a6), d0
  007958:  e7 80                asl.l    #$3, d0
  00795a:  29 76 08 8e 00 08    move.l   -$72(a6, d0.l), $8(a4)
  007960:  70 03                moveq    #$3, d0
  007962:  2f 00                move.l   d0, -(a7)
  007964:  2f 0c                move.l   a4, -(a7)
  007966:  72 13                moveq    #$13, d1
  007968:  2f 01                move.l   d1, -(a7)
  00796a:  61 ff ff ff d0 58    bsr.l    $49c4  ; -> EngineDispatch
  007970:  20 2e ff d2          move.l   -$2e(a6), d0
  007974:  e7 80                asl.l    #$3, d0
  007976:  d7 f6 08 8e          adda.l   -$72(a6, d0.l), a3
  00797a:  4f ef 00 0c          lea.l    $c(a7), a7
  00797e:  20 2e ff d2          move.l   -$2e(a6), d0
  007982:  52 ae ff d2          addq.l   #$1, -$2e(a6)
L7986:
  007986:  20 2e ff d2          move.l   -$2e(a6), d0
  00798a:  b0 ae ff ca          cmp.l    -$36(a6), d0
  00798e:  65 b6                bcs.b    $7946  ; -> L7946
L7990:
  007990:  4a ae ff 86          tst.l    -$7a(a6)
  007994:  66 8a                bne.b    $7920  ; -> L7920
L7996:
  007996:  70 00                moveq    #$0, d0
  007998:  2f 00                move.l   d0, -(a7)
  00799a:  61 ff ff ff fd a6    bsr.l    $7742  ; -> sub_7742
  0079a0:  2d 40 ff da          move.l   d0, -$26(a6)
  0079a4:  70 ff                moveq    #$ff, d0
  0079a6:  2d 40 ff ce          move.l   d0, -$32(a6)
  0079aa:  26 40                movea.l  d0, a3
  0079ac:  4a ae ff da          tst.l    -$26(a6)
  0079b0:  58 4f                addq.w   #$4, a7
  0079b2:  67 00 01 88          beq.w    $7b3c  ; -> L7b3c
  0079b6:  20 6e ff da          movea.l  -$26(a6), a0
  0079ba:  20 50                movea.l  (a0), a0
  0079bc:  20 68 00 16          movea.l  $16(a0), a0
  0079c0:  20 50                movea.l  (a0), a0
  0079c2:  2d 48 ff de          move.l   a0, -$22(a6)
  0079c6:  26 50                movea.l  (a0), a3
  0079c8:  2d 4b ff ce          move.l   a3, -$32(a6)
  0079cc:  55 8f                subq.l   #$2, a7
  0079ce:  2f 3c 6d 61 63 68    move.l   #$6d616368, -(a7)  ; 'mach'
  0079d4:  48 6e ff d6          pea.l    -$2a(a6)
  0079d8:  61 ff 00 00 46 62    bsr.l    $c03c  ; -> sub_c03c
  0079de:  70 0b                moveq    #$b, d0
  0079e0:  b0 ae ff d6          cmp.l    -$2a(a6), d0
  0079e4:  54 4f                addq.w   #$2, a7
  0079e6:  67 0a                beq.b    $79f2  ; -> L79f2
  0079e8:  70 12                moveq    #$12, d0
  0079ea:  b0 ae ff d6          cmp.l    -$2a(a6), d0
  0079ee:  66 00 00 8c          bne.w    $7a7c  ; -> L7a7c
L79f2:
  0079f2:  70 00                moveq    #$0, d0
  0079f4:  2d 40 ff ce          move.l   d0, -$32(a6)
  0079f8:  20 6e ff de          movea.l  -$22(a6), a0
  0079fc:  32 28 00 0a          move.w   $a(a0), d1
  007a00:  48 c1                ext.l    d1
  007a02:  34 28 00 06          move.w   $6(a0), d2
  007a06:  48 c2                ext.l    d2
  007a08:  92 82                sub.l    d2, d1
  007a0a:  2d 41 ff f6          move.l   d1, -$a(a6)
  007a0e:  20 6e ff de          movea.l  -$22(a6), a0
  007a12:  32 3c 3f ff          move.w   #$3fff, d1
  007a16:  c2 68 00 04          and.w    $4(a0), d1
  007a1a:  74 00                moveq    #$0, d2
  007a1c:  34 01                move.w   d1, d2
  007a1e:  4a 82                tst.l    d2
  007a20:  4c 2e 28 00 ff f6    muls.l   -$a(a6), d2
  007a26:  28 02                move.l   d2, d4
  007a28:  0c ae 00 00 01 f4 ff f6 cmpi.l   #$1f4, -$a(a6)
  007a30:  6f 04                ble.b    $7a36  ; -> L7a36
  007a32:  72 02                moveq    #$2, d1
  007a34:  60 02                bra.b    $7a38  ; -> L7a38
L7a36:
  007a36:  72 03                moveq    #$3, d1
L7a38:
  007a38:  e3 ac                lsl.l    d1, d4
  007a3a:  20 6e ff de          movea.l  -$22(a6), a0
  007a3e:  30 28 00 20          move.w   $20(a0), d0
  007a42:  48 c0                ext.l    d0
  007a44:  22 04                move.l   d4, d1
  007a46:  4c 40 18 01          divs.l   d0, d1
  007a4a:  28 01                move.l   d1, d4
  007a4c:  70 00                moveq    #$0, d0
  007a4e:  2d 40 ff e2          move.l   d0, -$1e(a6)
  007a52:  55 8f                subq.l   #$2, a7
  007a54:  2f 3c 70 67 73 7a    move.l   #$7067737a, -(a7)  ; 'pgsz'
  007a5a:  48 6e ff e2          pea.l    -$1e(a6)
  007a5e:  61 ff 00 00 45 dc    bsr.l    $c03c  ; -> sub_c03c
  007a64:  20 2e ff e2          move.l   -$1e(a6), d0
  007a68:  53 80                subq.l   #$1, d0
  007a6a:  d8 80                add.l    d0, d4
  007a6c:  20 2e ff e2          move.l   -$1e(a6), d0
  007a70:  53 80                subq.l   #$1, d0
  007a72:  46 80                not.l    d0
  007a74:  c8 80                and.l    d0, d4
  007a76:  54 4f                addq.w   #$2, a7
  007a78:  60 00 00 9c          bra.w    $7b16  ; -> L7b16
L7a7c:
  007a7c:  70 25                moveq    #$25, d0
  007a7e:  b0 ae ff d6          cmp.l    -$2a(a6), d0
  007a82:  6d 0a                blt.b    $7a8e  ; -> L7a8e
  007a84:  70 2a                moveq    #$2a, d0
  007a86:  b0 ae ff d6          cmp.l    -$2a(a6), d0
  007a8a:  6d 00 00 8a          blt.w    $7b16  ; -> L7b16
L7a8e:
  007a8e:  2d 7c 60 00 00 00 ff ce move.l   #$60000000, -$32(a6)
  007a96:  20 6e ff de          movea.l  -$22(a6), a0
  007a9a:  30 28 00 0a          move.w   $a(a0), d0
  007a9e:  48 c0                ext.l    d0
  007aa0:  32 28 00 06          move.w   $6(a0), d1
  007aa4:  48 c1                ext.l    d1
  007aa6:  90 81                sub.l    d1, d0
  007aa8:  2d 40 ff f6          move.l   d0, -$a(a6)
  007aac:  20 6e ff de          movea.l  -$22(a6), a0
  007ab0:  30 3c 3f ff          move.w   #$3fff, d0
  007ab4:  c0 68 00 04          and.w    $4(a0), d0
  007ab8:  72 00                moveq    #$0, d1
  007aba:  32 00                move.w   d0, d1
  007abc:  4a 81                tst.l    d1
  007abe:  4c 2e 18 00 ff f6    muls.l   -$a(a6), d1
  007ac4:  28 01                move.l   d1, d4
  007ac6:  0c ae 00 00 01 f4 ff f6 cmpi.l   #$1f4, -$a(a6)
  007ace:  6f 04                ble.b    $7ad4  ; -> L7ad4
  007ad0:  70 02                moveq    #$2, d0
  007ad2:  60 02                bra.b    $7ad6  ; -> L7ad6
L7ad4:
  007ad4:  70 03                moveq    #$3, d0
L7ad6:
  007ad6:  e1 ac                lsl.l    d0, d4
  007ad8:  20 6e ff de          movea.l  -$22(a6), a0
  007adc:  30 28 00 20          move.w   $20(a0), d0
  007ae0:  48 c0                ext.l    d0
  007ae2:  22 04                move.l   d4, d1
  007ae4:  4c 40 18 01          divs.l   d0, d1
  007ae8:  28 01                move.l   d1, d4
  007aea:  70 00                moveq    #$0, d0
  007aec:  2d 40 ff e2          move.l   d0, -$1e(a6)
  007af0:  55 8f                subq.l   #$2, a7
  007af2:  2f 3c 70 67 73 7a    move.l   #$7067737a, -(a7)  ; 'pgsz'
  007af8:  48 6e ff e2          pea.l    -$1e(a6)
  007afc:  61 ff 00 00 45 3e    bsr.l    $c03c  ; -> sub_c03c
  007b02:  20 2e ff e2          move.l   -$1e(a6), d0
  007b06:  53 80                subq.l   #$1, d0
  007b08:  d8 80                add.l    d0, d4
  007b0a:  20 2e ff e2          move.l   -$1e(a6), d0
  007b0e:  53 80                subq.l   #$1, d0
  007b10:  46 80                not.l    d0
  007b12:  c8 80                and.l    d0, d4
  007b14:  54 4f                addq.w   #$2, a7
L7b16:
  007b16:  b7 ee ff ce          cmpa.l   -$32(a6), a3
  007b1a:  67 20                beq.b    $7b3c  ; -> L7b3c
  007b1c:  28 8b                move.l   a3, (a4)
  007b1e:  29 6e ff ce 00 04    move.l   -$32(a6), $4(a4)
  007b24:  29 44 00 08          move.l   d4, $8(a4)
  007b28:  70 03                moveq    #$3, d0
  007b2a:  2f 00                move.l   d0, -(a7)
  007b2c:  2f 0c                move.l   a4, -(a7)
  007b2e:  72 13                moveq    #$13, d1
  007b30:  2f 01                move.l   d1, -(a7)
  007b32:  61 ff ff ff ce 90    bsr.l    $49c4  ; -> EngineDispatch
  007b38:  4f ef 00 0c          lea.l    $c(a7), a7
L7b3c:
  007b3c:  28 8b                move.l   a3, (a4)
  007b3e:  29 6e ff ce 00 04    move.l   -$32(a6), $4(a4)
  007b44:  70 02                moveq    #$2, d0
  007b46:  2f 00                move.l   d0, -(a7)
  007b48:  2f 0c                move.l   a4, -(a7)
  007b4a:  72 16                moveq    #$16, d1
  007b4c:  2f 01                move.l   d1, -(a7)
  007b4e:  61 ff ff ff ce 74    bsr.l    $49c4  ; -> EngineDispatch
  007b54:  70 00                moveq    #$0, d0
  007b56:  2d 40 ff 7a          move.l   d0, -$86(a6)
  007b5a:  59 8f                subq.l   #$4, a7
  007b5c:  2f 38 08 88          move.l   $888.w, -(a7)
  007b60:  61 ff 00 00 46 e8    bsr.l    $c24a  ; -> Strip24
  007b66:  20 5f                movea.l  (a7)+, a0
  007b68:  20 50                movea.l  (a0), a0
  007b6a:  20 50                movea.l  (a0), a0
  007b6c:  2d 68 02 14 ff 7e    move.l   $214(a0), -$82(a6)
  007b72:  7e 09                moveq    #$9, d7
  007b74:  4f ef 00 0c          lea.l    $c(a7), a7
L7b78:
  007b78:  42 06                clr.b    d6
  007b7a:  2f 07                move.l   d7, -(a7)
  007b7c:  61 ff ff ff fb c4    bsr.l    $7742  ; -> sub_7742
  007b82:  2d 40 ff da          move.l   d0, -$26(a6)
  007b86:  58 4f                addq.w   #$4, a7
  007b88:  66 06                bne.b    $7b90  ; -> L7b90
  007b8a:  7c 01                moveq    #$1, d6
  007b8c:  60 00 01 b6          bra.w    $7d44  ; -> L7d44
L7b90:
  007b90:  1d 47 ff 73          move.b   d7, -$8d(a6)
  007b94:  42 2e ff 74          clr.b    -$8c(a6)
  007b98:  3d 7c 00 01 ff 6a    move.w   #$1, -$96(a6)
  007b9e:  42 6e ff 6c          clr.w    -$94(a6)
  007ba2:  1d 7c 00 03 ff 72    move.b   #$3, -$8e(a6)
  007ba8:  41 ee ff 42          lea.l    -$be(a6), a0
  007bac:  70 15                moveq    #$15, d0
  007bae:  a0 6e                dc.w     $a06e  ; _SlotManager selector=sNextTypeSRsrc
  007bb0:  4a 40                tst.w    d0
  007bb2:  66 00 01 90          bne.w    $7d44  ; -> L7d44
  007bb6:  10 2e ff 73          move.b   -$8d(a6), d0
  007bba:  49 c0                extb.l   d0
  007bbc:  be 80                cmp.l    d0, d7
  007bbe:  67 06                beq.b    $7bc6  ; -> L7bc6
  007bc0:  7c 01                moveq    #$1, d6
  007bc2:  60 00 01 80          bra.w    $7d44  ; -> L7d44
L7bc6:
  007bc6:  1d 7c 00 20 ff 74    move.b   #$20, -$8c(a6)
  007bcc:  41 ee ff 42          lea.l    -$be(a6), a0
  007bd0:  70 01                moveq    #$1, d0
  007bd2:  a0 6e                dc.w     $a06e  ; _SlotManager selector=sReadWord
  007bd4:  4a 40                tst.w    d0
  007bd6:  66 00 01 6c          bne.w    $7d44  ; -> L7d44
  007bda:  70 27                moveq    #$27, d0
  007bdc:  b0 6e ff 44          cmp.w    -$bc(a6), d0
  007be0:  66 7e                bne.b    $7c60  ; -> L7c60
  007be2:  1d 7c 00 24 ff 74    move.b   #$24, -$8c(a6)
  007be8:  41 ee ff 42          lea.l    -$be(a6), a0
  007bec:  70 06                moveq    #$6, d0
  007bee:  a0 6e                dc.w     $a06e  ; _SlotManager selector=sFindStruct
  007bf0:  4a 40                tst.w    d0
  007bf2:  66 00 01 50          bne.w    $7d44  ; -> L7d44
  007bf6:  1d 47 ff 73          move.b   d7, -$8d(a6)
  007bfa:  1d 7c 00 03 ff 74    move.b   #$3, -$8c(a6)
  007c00:  41 ee ff 42          lea.l    -$be(a6), a0
  007c04:  70 03                moveq    #$3, d0
  007c06:  a0 6e                dc.w     $a06e  ; _SlotManager selector=sGetCString
  007c08:  4a 40                tst.w    d0
  007c0a:  66 00 01 38          bne.w    $7d44  ; -> L7d44
  007c0e:  48 7a 01 64          pea.l    $7d74(pc)
  007c12:  2f 2e ff 42          move.l   -$be(a6), -(a7)
  007c16:  61 ff 00 00 01 66    bsr.l    $7d7e  ; -> sub_7d7e
  007c1c:  4a 80                tst.l    d0
  007c1e:  50 4f                addq.w   #$8, a7
  007c20:  66 3e                bne.b    $7c60  ; -> L7c60
  007c22:  1d 7c 00 01 ff 3d    move.b   #$1, -$c3(a6)
  007c28:  70 18                moveq    #$18, d0
  007c2a:  22 07                move.l   d7, d1
  007c2c:  e1 a9                lsl.l    d0, d1
  007c2e:  82 bc f0 20 02 08    or.l     #$f0200208, d1
  007c34:  2d 41 ff 3e          move.l   d1, -$c2(a6)
  007c38:  41 ee ff 3d          lea.l    -$c3(a6), a0
  007c3c:  10 10                move.b   (a0), d0
  007c3e:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  007c40:  10 80                move.b   d0, (a0)
  007c42:  20 6e ff 3e          movea.l  -$c2(a6), a0
  007c46:  2a 10                move.l   (a0), d5
  007c48:  41 ee ff 3d          lea.l    -$c3(a6), a0
  007c4c:  10 10                move.b   (a0), d0
  007c4e:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  007c50:  10 80                move.b   d0, (a0)
  007c52:  70 01                moveq    #$1, d0
  007c54:  c0 85                and.l    d5, d0
  007c56:  57 c3                seq.b    d3
  007c58:  44 03                neg.b    d3
  007c5a:  1c 03                move.b   d3, d6
  007c5c:  60 00 00 e6          bra.w    $7d44  ; -> L7d44
L7c60:
  007c60:  1d 47 ff 73          move.b   d7, -$8d(a6)
  007c64:  42 2e ff 74          clr.b    -$8c(a6)
  007c68:  3d 7c 00 01 ff 6a    move.w   #$1, -$96(a6)
  007c6e:  42 6e ff 6c          clr.w    -$94(a6)
  007c72:  1d 7c 00 03 ff 72    move.b   #$3, -$8e(a6)
  007c78:  41 ee ff 42          lea.l    -$be(a6), a0
  007c7c:  70 15                moveq    #$15, d0
  007c7e:  a0 6e                dc.w     $a06e  ; _SlotManager selector=sNextTypeSRsrc
  007c80:  4a 40                tst.w    d0
  007c82:  66 00 00 c0          bne.w    $7d44  ; -> L7d44
  007c86:  10 2e ff 73          move.b   -$8d(a6), d0
  007c8a:  49 c0                extb.l   d0
  007c8c:  be 80                cmp.l    d0, d7
  007c8e:  67 06                beq.b    $7c96  ; -> L7c96
  007c90:  7c 01                moveq    #$1, d6
  007c92:  60 00 00 b0          bra.w    $7d44  ; -> L7d44
L7c96:
  007c96:  1d 7c 00 14 ff 74    move.b   #$14, -$8c(a6)
  007c9c:  41 ee ff 42          lea.l    -$be(a6), a0
  007ca0:  70 02                moveq    #$2, d0
  007ca2:  a0 6e                dc.w     $a06e  ; _SlotManager selector=sReadLong
  007ca4:  4a 40                tst.w    d0
  007ca6:  67 00 00 84          beq.w    $7d2c  ; -> L7d2c
  007caa:  3d 7c 00 03 ff 6a    move.w   #$3, -$96(a6)
  007cb0:  3d 7c 00 01 ff 6c    move.w   #$1, -$94(a6)
  007cb6:  3d 7c 00 01 ff 6e    move.w   #$1, -$92(a6)
  007cbc:  1d 7c 00 01 ff 72    move.b   #$1, -$8e(a6)
  007cc2:  42 2e ff 74          clr.b    -$8c(a6)
  007cc6:  1d 47 ff 73          move.b   d7, -$8d(a6)
  007cca:  41 ee ff 42          lea.l    -$be(a6), a0
  007cce:  70 15                moveq    #$15, d0
  007cd0:  a0 6e                dc.w     $a06e  ; _SlotManager selector=sNextTypeSRsrc
  007cd2:  4a 40                tst.w    d0
  007cd4:  66 6e                bne.b    $7d44  ; -> L7d44
  007cd6:  10 2e ff 73          move.b   -$8d(a6), d0
  007cda:  49 c0                extb.l   d0
  007cdc:  be 80                cmp.l    d0, d7
  007cde:  67 04                beq.b    $7ce4  ; -> L7ce4
  007ce0:  7c 01                moveq    #$1, d6
  007ce2:  60 60                bra.b    $7d44  ; -> L7d44
L7ce4:
  007ce4:  20 6e ff da          movea.l  -$26(a6), a0
  007ce8:  20 50                movea.l  (a0), a0
  007cea:  1d 68 00 2d ff 74    move.b   $2d(a0), -$8c(a6)
  007cf0:  41 ee ff 42          lea.l    -$be(a6), a0
  007cf4:  70 06                moveq    #$6, d0
  007cf6:  a0 6e                dc.w     $a06e  ; _SlotManager selector=sFindStruct
  007cf8:  4a 40                tst.w    d0
  007cfa:  66 48                bne.b    $7d44  ; -> L7d44
  007cfc:  1d 7c 00 05 ff 74    move.b   #$5, -$8c(a6)
  007d02:  41 ee ff 42          lea.l    -$be(a6), a0
  007d06:  70 02                moveq    #$2, d0
  007d08:  a0 6e                dc.w     $a06e  ; _SlotManager selector=sReadLong
  007d0a:  4a 40                tst.w    d0
  007d0c:  67 04                beq.b    $7d12  ; -> L7d12
  007d0e:  7c 01                moveq    #$1, d6
  007d10:  60 32                bra.b    $7d44  ; -> L7d44
L7d12:
  007d12:  20 3c 00 00 80 0e    move.l   #$800e, d0
  007d18:  c0 ae ff 42          and.l    -$be(a6), d0
  007d1c:  0c 80 00 00 80 0e    cmpi.l   #$800e, d0
  007d22:  57 c0                seq.b    d0
  007d24:  44 00                neg.b    d0
  007d26:  49 c0                extb.l   d0
  007d28:  1c 00                move.b   d0, d6
  007d2a:  60 18                bra.b    $7d44  ; -> L7d44
L7d2c:
  007d2c:  20 3c 00 00 80 0e    move.l   #$800e, d0
  007d32:  c0 ae ff 42          and.l    -$be(a6), d0
  007d36:  0c 80 00 00 80 0e    cmpi.l   #$800e, d0
  007d3c:  57 c0                seq.b    d0
  007d3e:  44 00                neg.b    d0
  007d40:  49 c0                extb.l   d0
  007d42:  1c 00                move.b   d0, d6
L7d44:
  007d44:  4a 06                tst.b    d6
  007d46:  66 16                bne.b    $7d5e  ; -> L7d5e
  007d48:  28 87                move.l   d7, (a4)
  007d4a:  70 01                moveq    #$1, d0
  007d4c:  2f 00                move.l   d0, -(a7)
  007d4e:  2f 0c                move.l   a4, -(a7)
  007d50:  72 14                moveq    #$14, d1
  007d52:  2f 01                move.l   d1, -(a7)
  007d54:  61 ff ff ff cc 6e    bsr.l    $49c4  ; -> EngineDispatch
  007d5a:  4f ef 00 0c          lea.l    $c(a7), a7
L7d5e:
  007d5e:  20 07                move.l   d7, d0
  007d60:  52 87                addq.l   #$1, d7
  007d62:  70 0f                moveq    #$f, d0
  007d64:  b0 87                cmp.l    d7, d0
  007d66:  6e 00 fe 10          bgt.w    $7b78  ; -> L7b78
  007d6a:  4c ee 18 f8 ff 20    movem.l  -$e0(a6), d3-d7/a3-a4
  007d70:  4e 5e                unlk     a6
  007d72:  4e 75                rts      
  007d74:  4d                   dc.b     $4d  ; M
  007d75:  44 43                neg.w    d3
  007d77:  20 31 2e 30          move.l   $30(a1, d2.l), d0
  007d7b:  2e 31 00 4e          move.l   $4e(a1, d0.w), d7
  007d7f:  56 00                addq.b   #$3, d0
  007d81:  00                   dc.b     $00  ; .
  007d82:  48 e7 00 18          movem.l  a3-a4, -(a7)
  007d86:  26 6e 00 0c          movea.l  $c(a6), a3
  007d8a:  28 6e 00 08          movea.l  $8(a6), a4
L7d8e:
  007d8e:  4a 14                tst.b    (a4)
  007d90:  67 04                beq.b    $7d96  ; -> L7d96
  007d92:  b9 0b                cmpm.b   (a3)+, (a4)+
  007d94:  67 f8                beq.b    $7d8e  ; -> L7d8e
L7d96:
  007d96:  10 24                move.b   -(a4), d0
  007d98:  48 80                ext.w    d0
  007d9a:  12 23                move.b   -(a3), d1
  007d9c:  48 81                ext.w    d1
  007d9e:  90 41                sub.w    d1, d0
  007da0:  48 c0                ext.l    d0
  007da2:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  007da8:  4e 5e                unlk     a6
  007daa:  4e 75                rts      
handler_15:
  007dac:  20 5f                movea.l  (a7)+, a0
  007dae:  3f 00                move.w   d0, -(a7)
  007db0:  2f 08                move.l   a0, -(a7)
  007db2:  4e fa 1c d4          jmp      $9a88(pc)  ; -> sub_9a88
  007db6:  47 41 5f 53 65 74 46 69 6c 6c 50 61 74 00 dc.b     $47,$41,$5f,$53,$65,$74,$46,$69,$6c,$6c,$50,$61,$74,$00  ; GA_SetFillPat.
* -- small utility leaf routines (names recovered from the
* embedded MacsBug symbols that follow each one) --
GetD2:
  007dc4:  20 02                move.l   d2, d0
  007dc6:  4e 75                rts      
  007dc8:  47 65 74 44 32 00 00 00 dc.b     $47,$65,$74,$44,$32,$00,$00,$00  ; GetD2...
SetD2:
  007dd0:  24 2f 00 04          move.l   $4(a7), d2
  007dd4:  4e 75                rts      
  007dd6:  53 65 74 44 32 00    dc.b     $53,$65,$74,$44,$32,$00  ; SetD2.
GA_MoveHHi:
  007ddc:  20 0f                move.l   a7, d0
  007dde:  22 00                move.l   d0, d1
  007de0:  08 81 00 01          bclr.b   #$1, d1
  007de4:  2e 41                movea.l  d1, a7
  007de6:  55 8f                subq.l   #$2, a7
  007de8:  2f 00                move.l   d0, -(a7)
  007dea:  2f 08                move.l   a0, -(a7)
  007dec:  2f 3c 00 00 05 90    move.l   #$590, -(a7)
  007df2:  4e ba ef 9e          jsr      $6d92(pc)  ; -> StoreCtxWord_AA6
  007df6:  58 8f                addq.l   #$4, a7
  007df8:  20 5f                movea.l  (a7)+, a0
  007dfa:  22 40                movea.l  d0, a1
  007dfc:  4e 91                jsr      (a1)
  007dfe:  2e 57 4e 75 47 41 5f 4d 6f 76 65 48 48 69 dc.b     $2e,$57,$4e,$75,$47,$41,$5f,$4d,$6f,$76,$65,$48,$48,$69  ; .WNuGA_MoveHHi
BitFieldExtract:
  007e0c:  20 6f 00 04 20 2f 00 08 22 2f 00 0c e9 d0 08 21 dc.b     $20,$6f,$00,$04,$20,$2f,$00,$08,$22,$2f,$00,$0c,$e9,$d0,$08,$21  ;  o.. /.."/.....!
  007e1c:  4e 75 42 69 74 46 69 65 6c 64 45 78 74 72 61 63 dc.b     $4e,$75,$42,$69,$74,$46,$69,$65,$6c,$64,$45,$78,$74,$72,$61,$63  ; NuBitFieldExtrac
  007e2c:  74 00 00 00          dc.b     $74,$00,$00,$00  ; t...
FixScale:
  007e30:  22 2f 00 08 48 41 42 41 20 2f 00 04 4c 01 04 01 dc.b     $22,$2f,$00,$08,$48,$41,$42,$41,$20,$2f,$00,$04,$4c,$01,$04,$01  ; "/..HABA /..L...
  007e40:  24 2f 00 0c 48 42 42 42 4c 42 04 01 4e 75 46 69 dc.b     $24,$2f,$00,$0c,$48,$42,$42,$42,$4c,$42,$04,$01,$4e,$75,$46,$69  ; $/..HBBBLB..NuFi
  007e50:  78 53 63 61 6c 65 00 00 dc.b     $78,$53,$63,$61,$6c,$65,$00,$00  ; xScale..
EqualFontOutput:
  007e58:  20 6f 00 04 5c 88 22 6f 00 08 5c 89 70 00 b3 48 dc.b     $20,$6f,$00,$04,$5c,$88,$22,$6f,$00,$08,$5c,$89,$70,$00,$b3,$48  ;  o..\."o..\.p..H
  007e68:  66 0e b3 88 66 0a b3 88 66 06 b3 48 66 02 70 01 dc.b     $66,$0e,$b3,$88,$66,$0a,$b3,$88,$66,$06,$b3,$48,$66,$02,$70,$01  ; f...f...f..Hf.p.
  007e78:  4e 75 45 71 75 61 6c 46 6f 6e 74 4f 75 74 70 75 dc.b     $4e,$75,$45,$71,$75,$61,$6c,$46,$6f,$6e,$74,$4f,$75,$74,$70,$75  ; NuEqualFontOutpu
  007e88:  74 00 00 00          dc.b     $74,$00,$00,$00  ; t...
sub_7e8c:
  007e8c:  20 6f 00 04 30 28 04 0e 48 c0 e2 98 d0 a8 04 14 dc.b     $20,$6f,$00,$04,$30,$28,$04,$0e,$48,$c0,$e2,$98,$d0,$a8,$04,$14  ;  o..0(..H.......
  007e9c:  e2 98 d0 a8 04 18 e2 98 72 01 61 50 58 88 32 3c dc.b     $e2,$98,$d0,$a8,$04,$18,$e2,$98,$72,$01,$61,$50,$58,$88,$32,$3c  ; ........r.aPX.2<
  007eac:  00 0c 61 48 d0 98 e2 98 d0 98 e2 98 d0 98 e2 98 dc.b     $00,$0c,$61,$48,$d0,$98,$e2,$98,$d0,$98,$e2,$98,$d0,$98,$e2,$98  ; ..aH............
  007ebc:  d0 98 e2 98 d0 98 e2 98 d0 98 e2 98 d0 98 e2 98 dc.b     $d0,$98,$e2,$98,$d0,$98,$e2,$98,$d0,$98,$e2,$98,$d0,$98,$e2,$98  ; ................
  007ecc:  d0 98 e2 98 d0 98 e2 98 d0 98 e2 98 d0 98 e2 98 dc.b     $d0,$98,$e2,$98,$d0,$98,$e2,$98,$d0,$98,$e2,$98,$d0,$98,$e2,$98  ; ................
  007edc:  d0 98 e2 98 d0 98 e2 98 d0 98 e2 98 d0 98 e2 98 dc.b     $d0,$98,$e2,$98,$d0,$98,$e2,$98,$d0,$98,$e2,$98,$d0,$98,$e2,$98  ; ................
  007eec:  48 40 32 00 48 40 d0 41 48 c0 4e 75 dc.b     $48,$40,$32,$00,$48,$40,$d0,$41,$48,$c0,$4e,$75  ; H@2.H@.AH.Nu
WidthTableCheckSum:
  007ef8:  d0 98 e2 98 d0 98 e2 98 d0 98 e2 98 d0 98 e2 98 dc.b     $d0,$98,$e2,$98,$d0,$98,$e2,$98,$d0,$98,$e2,$98,$d0,$98,$e2,$98  ; ................
  007f08:  d0 98 e2 98 d0 98 e2 98 d0 98 e2 98 d0 98 e2 98 dc.b     $d0,$98,$e2,$98,$d0,$98,$e2,$98,$d0,$98,$e2,$98,$d0,$98,$e2,$98  ; ................
  007f18:  d0 98 e2 98 d0 98 e2 98 d0 98 e2 98 d0 98 e2 98 dc.b     $d0,$98,$e2,$98,$d0,$98,$e2,$98,$d0,$98,$e2,$98,$d0,$98,$e2,$98  ; ................
  007f28:  d0 98 e2 98 d0 98 e2 98 d0 98 e2 98 d0 98 e2 98 dc.b     $d0,$98,$e2,$98,$d0,$98,$e2,$98,$d0,$98,$e2,$98,$d0,$98,$e2,$98  ; ................
  007f38:  51 c9 ff be 4e 75 57 69 64 74 68 54 61 62 6c 65 dc.b     $51,$c9,$ff,$be,$4e,$75,$57,$69,$64,$74,$68,$54,$61,$62,$6c,$65  ; Q...NuWidthTable
  007f48:  43 68 65 63 6b 53 75 6d dc.b     $43,$68,$65,$63,$6b,$53,$75,$6d  ; CheckSum
handler_00:
  007f50:  2f 08 2f 00 20 78 0d 62 20 10 a0 55 20 40 20 68 dc.b     $2f,$08,$2f,$00,$20,$78,$0d,$62,$20,$10,$a0,$55,$20,$40,$20,$68  ; /./. x.b ..U @ h
  007f60:  00 12 20 50 20 1f b0 88 67 10 20 78 08 88 2f 28 dc.b     $00,$12,$20,$50,$20,$1f,$b0,$88,$67,$10,$20,$78,$08,$88,$2f,$28  ; .. P ...g. x../(
  007f70:  00 14 20 6f 00 04 2e 9f 4e 75 48 e7 80 70 20 78 dc.b     $00,$14,$20,$6f,$00,$04,$2e,$9f,$4e,$75,$48,$e7,$80,$70,$20,$78  ; .. o....NuH..p x
  007f80:  08 88 22 6f 00 14 0c 51 22 40 67 54 0c 51 28 40 dc.b     $08,$88,$22,$6f,$00,$14,$0c,$51,$22,$40,$67,$54,$0c,$51,$28,$40  ; .."o...Q"@gT.Q(@
  007f90:  66 64 22 68 00 10 45 f8 08 3c 26 78 08 9c 26 53 dc.b     $66,$64,$22,$68,$00,$10,$45,$f8,$08,$3c,$26,$78,$08,$9c,$26,$53  ; fd"h..E..<&x..&S
  007fa0:  d6 fc 00 22 30 29 00 04 90 53 b0 5a 6d 2a 30 29 dc.b     $d6,$fc,$00,$22,$30,$29,$00,$04,$90,$53,$b0,$5a,$6d,$2a,$30,$29  ; ..."0)...S.Zm*0)
  007fb0:  00 06 90 6b 00 02 b0 5a 6f 1e 30 11 90 53 b0 5a dc.b     $00,$06,$90,$6b,$00,$02,$b0,$5a,$6f,$1e,$30,$11,$90,$53,$b0,$5a  ; ...k...Zo.0..S.Z
  007fc0:  6c 16 30 29 00 02 90 6b 00 02 b0 52 6c 0a de fc dc.b     $6c,$16,$30,$29,$00,$02,$90,$6b,$00,$02,$b0,$52,$6c,$0a,$de,$fc  ; l.0)...k...Rl...
  007fd0:  00 18 4c df 7f ff 4e 75 22 68 00 28 42 91 60 16 dc.b     $00,$18,$4c,$df,$7f,$ff,$4e,$75,$22,$68,$00,$28,$42,$91,$60,$16  ; ..L...Nu"h.(B.`.
  007fe0:  24 40 22 68 00 28 20 11 67 0c 26 68 00 2c 24 db dc.b     $24,$40,$22,$68,$00,$28,$20,$11,$67,$0c,$26,$68,$00,$2c,$24,$db  ; $@"h.( .g.&h.,$.
  007ff0:  51 c8 ff fc 42 91 4c df 0e 01 60 00 ff 6e 47 41 dc.b     $51,$c8,$ff,$fc,$42,$91,$4c,$df,$0e,$01,$60,$00,$ff,$6e,$47,$41  ; Q...B.L...`..nGA
  008000:  5f 54 72 61 6e 73 6c 61 74 65 32 34 54 6f 33 32 dc.b     $5f,$54,$72,$61,$6e,$73,$6c,$61,$74,$65,$32,$34,$54,$6f,$33,$32  ; _Translate24To32
* GetA5  -  returns A5 (the QuickDraw/app globals world) in D0.
GetA5:
  008010:  20 0d                move.l   a5, d0
  008012:  4e 75                rts      
  008014:  47 65 74 41 35 00 00 00 dc.b     $47,$65,$74,$41,$35,$00,$00,$00  ; GetA5...
GACursorTask:
  00801c:  48 e7 ff f8          movem.l  d0-d7/a0-a4, -(a7)
  008020:  20 38 08 88          move.l   $888.w, d0
  008024:  67 60                beq.b    $8086  ; -> L8086
  008026:  22 40                movea.l  d0, a1
  008028:  0c a9 07 5b cd 15 00 20 cmpi.l   #$75bcd15, $20(a1)
  008030:  66 54                bne.b    $8086  ; -> L8086
  008032:  20 69 00 08          movea.l  $8(a1), a0
  008036:  22 10                move.l   (a0), d1
  008038:  24 69 00 0c          movea.l  $c(a1), a2
  00803c:  4a 92                tst.l    (a2)
  00803e:  66 46                bne.b    $8086  ; -> L8086
  008040:  20 3c 00 00 08 ee    move.l   #$8ee, d0
  008046:  20 80                move.l   d0, (a0)
  008048:  24 69 00 30          movea.l  $30(a1), a2
  00804c:  4a 92                tst.l    (a2)
  00804e:  67 06                beq.b    $8056  ; -> L8056
  008050:  42 38 08 cc          clr.b    $8cc.w
  008054:  42 92                clr.l    (a2)
L8056:
  008056:  4a 38 08 d2          tst.b    $8d2.w
  00805a:  66 10                bne.b    $806c  ; -> L806c
  00805c:  24 69 00 34          movea.l  $34(a1), a2
  008060:  4a 92                tst.l    (a2)
  008062:  67 08                beq.b    $806c  ; -> L806c
  008064:  11 fc 00 01 08 ce    move.b   #$1, $8ce.w
  00806a:  42 92                clr.l    (a2)
L806c:
  00806c:  48 e7 40 80          movem.l  d1/a0, -(a7)
  008070:  2f 00                move.l   d0, -(a7)
  008072:  4e ba ed 1e          jsr      $6d92(pc)  ; -> StoreCtxWord_AA6
  008076:  58 8f                addq.l   #$4, a7
  008078:  20 40                movea.l  d0, a0
  00807a:  4e 90                jsr      (a0)
  00807c:  70 03                moveq    #$3, d0
  00807e:  a1 98                dc.w     $a198  ; _HWPriv
  008080:  4c df 01 02          movem.l  (a7)+, d1/a0
  008084:  20 81                move.l   d1, (a0)
L8086:
  008086:  4c df 1f ff          movem.l  (a7)+, d0-d7/a0-a4
  00808a:  4e 75                rts      
  00808c:  47 41 43 75 72 73 6f 72 54 61 73 6b dc.b     $47,$41,$43,$75,$72,$73,$6f,$72,$54,$61,$73,$6b  ; GACursorTask
GA_GETCTSEED:
  008098:  2f 08                move.l   a0, -(a7)
  00809a:  48 e7 e0 60          movem.l  d0-d2/a1-a2, -(a7)
  00809e:  42 a7                clr.l    -(a7)
  0080a0:  4e ba c7 80          jsr      $4822(pc)  ; -> sub_4822
  0080a4:  58 8f                addq.l   #$4, a7
  0080a6:  2f 3c 00 00 16 a0    move.l   #$16a0, -(a7)
  0080ac:  4e ba ec e4          jsr      $6d92(pc)  ; -> StoreCtxWord_AA6
  0080b0:  58 8f                addq.l   #$4, a7
  0080b2:  20 40                movea.l  d0, a0
  0080b4:  4c df 06 07          movem.l  (a7)+, d0-d2/a1-a2
  0080b8:  2f 08                move.l   a0, -(a7)
  0080ba:  20 6f 00 04          movea.l  $4(a7), a0
  0080be:  2f 57 00 04          move.l   (a7), $4(a7)
  0080c2:  58 8f                addq.l   #$4, a7
  0080c4:  4e 75                rts      
  0080c6:  47 41 5f 47 45 54 43 54 53 45 45 44 00 00 dc.b     $47,$41,$5f,$47,$45,$54,$43,$54,$53,$45,$45,$44,$00,$00  ; GA_GETCTSEED..
GA_PMGR:
  0080d4:  2f 08                move.l   a0, -(a7)
  0080d6:  48 e7 e0 60          movem.l  d0-d2/a1-a2, -(a7)
  0080da:  0c 40 00 0c          cmpi.w   #$c, d0
  0080de:  66 10                bne.b    $80f0  ; -> L80f0
  0080e0:  4e ba 30 dc          jsr      $b1be(pc)  ; -> sub_b1be
  0080e4:  4a 80                tst.l    d0
  0080e6:  66 08                bne.b    $80f0  ; -> L80f0
  0080e8:  4c df 06 07          movem.l  (a7)+, d0-d2/a1-a2
  0080ec:  20 5f                movea.l  (a7)+, a0
  0080ee:  4e 75                rts      
L80f0:
  0080f0:  2f 3c 00 00 18 88    move.l   #$1888, -(a7)
  0080f6:  4e ba ec 9a          jsr      $6d92(pc)  ; -> StoreCtxWord_AA6
  0080fa:  58 8f                addq.l   #$4, a7
  0080fc:  20 40                movea.l  d0, a0
  0080fe:  4c df 06 07          movem.l  (a7)+, d0-d2/a1-a2
  008102:  2f 08                move.l   a0, -(a7)
  008104:  20 6f 00 04          movea.l  $4(a7), a0
  008108:  2f 57 00 04          move.l   (a7), $4(a7)
  00810c:  58 8f                addq.l   #$4, a7
  00810e:  4e 75                rts      
  008110:  47 41 5f 50 4d 47 52 00 dc.b     $47,$41,$5f,$50,$4d,$47,$52,$00  ; GA_PMGR.
handler_66:
  008118:  0c 40 00 0e          cmpi.w   #$e, d0
  00811c:  67 6e                beq.b    $818c  ; -> L818c
  00811e:  0c 40 00 08          cmpi.w   #$8, d0
  008122:  67 6c                beq.b    $8190  ; -> L8190
  008124:  0c 40 00 01          cmpi.w   #$1, d0
  008128:  67 3a                beq.b    $8164  ; -> L8164
  00812a:  0c 40 00 04          cmpi.w   #$4, d0
  00812e:  67 38                beq.b    $8168  ; -> L8168
  008130:  0c 40 00 0a          cmpi.w   #$a, d0
  008134:  67 36                beq.b    $816c  ; -> L816c
  008136:  0c 40 00 0f          cmpi.w   #$f, d0
  00813a:  67 34                beq.b    $8170  ; -> L8170
  00813c:  0c 40 00 11          cmpi.w   #$11, d0
  008140:  67 32                beq.b    $8174  ; -> L8174
  008142:  0c 40 00 13          cmpi.w   #$13, d0
  008146:  67 30                beq.b    $8178  ; -> L8178
  008148:  0c 40 00 02          cmpi.w   #$2, d0
  00814c:  67 2e                beq.b    $817c  ; -> L817c
  00814e:  0c 40 00 03          cmpi.w   #$3, d0
  008152:  67 2c                beq.b    $8180  ; -> L8180
  008154:  0c 40 00 00          cmpi.w   #$0, d0
  008158:  67 2a                beq.b    $8184  ; -> L8184
  00815a:  0c 40 00 09          cmpi.w   #$9, d0
  00815e:  67 28                beq.b    $8188  ; -> L8188
  008160:  2f 00                move.l   d0, -(a7)
  008162:  60 36                bra.b    $819a  ; -> L819a
L8164:
  008164:  4e fa 37 da          jmp      $b940(pc)  ; -> Lb940
L8168:
  008168:  4e fa 39 aa          jmp      $bb14(pc)  ; -> Lbb14
L816c:
  00816c:  4e fa 3c 08          jmp      $bd76(pc)  ; -> Lbd76
L8170:
  008170:  4e fa 3c e6          jmp      $be58(pc)  ; -> Lbe58
L8174:
  008174:  4e fa 3c fe          jmp      $be74(pc)  ; -> Lbe74
L8178:
  008178:  4e fa 3d 52          jmp      $becc(pc)  ; -> Lbecc
L817c:
  00817c:  4e fa 38 36          jmp      $b9b4(pc)  ; -> Lb9b4
L8180:
  008180:  4e fa 38 e2          jmp      $ba64(pc)  ; -> Lba64
L8184:
  008184:  4e fa 38 76          jmp      $b9fc(pc)  ; -> Lb9fc
L8188:
  008188:  4e fa 3b bc          jmp      $bd46(pc)  ; -> Lbd46
L818c:
  00818c:  4e fa 39 fa          jmp      $bb88(pc)  ; -> Lbb88
L8190:
  008190:  2f 00                move.l   d0, -(a7)
  008192:  2f 2f 00 08          move.l   $8(a7), -(a7)
  008196:  4e ba 3b 30          jsr      $bcc8(pc)  ; -> sub_bcc8
L819a:
  00819a:  2f 3c 00 00 1a 74    move.l   #$1a74, -(a7)
  0081a0:  4e ba eb f0          jsr      $6d92(pc)  ; -> StoreCtxWord_AA6
  0081a4:  58 8f 20 40 20 1f 4e d0 47 41 5f 51 44 4f 46 46 dc.b     $58,$8f,$20,$40,$20,$1f,$4e,$d0,$47,$41,$5f,$51,$44,$4f,$46,$46  ; X. @ .N.GA_QDOFF
  0081b4:  53 43 52 45 45 4e 00 00 dc.b     $53,$43,$52,$45,$45,$4e,$00,$00  ; SCREEN..
sub_81bc:
  0081bc:  4e 56 00 00          link.w   a6, #$0
  0081c0:  2f 0c                move.l   a4, -(a7)
  0081c2:  28 6e 00 08          movea.l  $8(a6), a4
  0081c6:  28 b8 08 24          move.l   $824.w, (a4)
  0081ca:  29 78 08 a8 00 08    move.l   $8a8.w, $8(a4)
  0081d0:  28 6e ff fc          movea.l  -$4(a6), a4
  0081d4:  4e 5e                unlk     a6
  0081d6:  4e 75                rts      
sub_81d8:
  0081d8:  4e 56 00 00          link.w   a6, #$0
  0081dc:  48 e7 01 08          movem.l  d7/a4, -(a7)
  0081e0:  2e 2e 00 08          move.l   $8(a6), d7
  0081e4:  20 78 08 88          movea.l  $888.w, a0
  0081e8:  20 50                movea.l  (a0), a0
  0081ea:  20 50                movea.l  (a0), a0
  0081ec:  20 68 02 14          movea.l  $214(a0), a0
  0081f0:  28 50                movea.l  (a0), a4
  0081f2:  20 3c 00 00 02 00    move.l   #$200, d0
  0081f8:  c0 ac 00 04          and.l    $4(a4), d0
  0081fc:  67 14                beq.b    $8212  ; -> L8212
  0081fe:  70 1c                moveq    #$1c, d0
  008200:  22 07                move.l   d7, d1
  008202:  e0 a9                lsr.l    d0, d1
  008204:  70 0f                moveq    #$f, d0
  008206:  c0 81                and.l    d1, d0
  008208:  72 04                moveq    #$4, d1
  00820a:  b2 80                cmp.l    d0, d1
  00820c:  57 c0                seq.b    d0
  00820e:  44 00                neg.b    d0
  008210:  60 12                bra.b    $8224  ; -> L8224
L8212:
  008212:  70 14                moveq    #$14, d0
  008214:  22 07                move.l   d7, d1
  008216:  e0 a9                lsr.l    d0, d1
  008218:  70 0f                moveq    #$f, d0
  00821a:  c0 81                and.l    d1, d0
  00821c:  72 08                moveq    #$8, d1
  00821e:  b2 80                cmp.l    d0, d1
  008220:  57 c0                seq.b    d0
  008222:  44 00                neg.b    d0
L8224:
  008224:  4c ee 10 80 ff f8    movem.l  -$8(a6), d7/a4
  00822a:  4e 5e                unlk     a6
  00822c:  4e 75                rts      
sub_822e:
  00822e:  4e 56 ff fc          link.w   a6, #$fffc
  008232:  48 e7 00 18          movem.l  a3-a4, -(a7)
  008236:  26 6e 00 08          movea.l  $8(a6), a3
  00823a:  70 00                moveq    #$0, d0
  00823c:  28 40                movea.l  d0, a4
  00823e:  a1 1a                dc.w     $a11a  ; _GetZone
  008240:  2d 48 ff fc          move.l   a0, -$4(a6)
  008244:  20 0b                move.l   a3, d0
  008246:  d0 ae ff fc          add.l    -$4(a6), d0
  00824a:  b0 b8 1e f4          cmp.l    $1ef4.w, d0
  00824e:  64 06                bcc.b    $8256  ; -> L8256
  008250:  20 4b                movea.l  a3, a0
  008252:  a1 28                dc.w     $a128  ; _RecoverHandle
  008254:  28 48                movea.l  a0, a4
L8256:
  008256:  20 0c                move.l   a4, d0
  008258:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  00825e:  4e 5e                unlk     a6
  008260:  4e 75                rts      
sub_8262:
  008262:  4e 56 ff ea          link.w   a6, #$ffea
  008266:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  00826a:  2a 2e 00 24          move.l   $24(a6), d5
  00826e:  26 6e 00 14          movea.l  $14(a6), a3
  008272:  28 6e 00 08          movea.l  $8(a6), a4
  008276:  3c 2b 00 04          move.w   $4(a3), d6
  00827a:  5d c0                slt.b    d0
  00827c:  44 00                neg.b    d0
  00827e:  49 c0                extb.l   d0
  008280:  2d 40 ff ea          move.l   d0, -$16(a6)
  008284:  67 64                beq.b    $82ea  ; -> L82ea
  008286:  30 3c 40 00          move.w   #$4000, d0
  00828a:  c0 46                and.w    d6, d0
  00828c:  67 04                beq.b    $8292  ; -> L8292
  00828e:  20 53                movea.l  (a3), a0
  008290:  26 50                movea.l  (a0), a3
L8292:
  008292:  20 4c                movea.l  a4, a0
  008294:  54 88                addq.l   #$2, a0
  008296:  22 4b                movea.l  a3, a1
  008298:  70 0b                moveq    #$b, d0
L829a:
  00829a:  20 d9                move.l   (a1)+, (a0)+
  00829c:  51 c8 ff fc          dbra     d0, $829a  ; -> L829a
  0082a0:  30 d9                move.w   (a1)+, (a0)+
  0082a2:  3e 2b 00 0e          move.w   $e(a3), d7
  0082a6:  0c 47 00 01          cmpi.w   #$1, d7
  0082aa:  67 06                beq.b    $82b2  ; -> L82b2
  0082ac:  0c 47 00 02          cmpi.w   #$2, d7
  0082b0:  66 46                bne.b    $82f8  ; -> L82f8
L82b2:
  0082b2:  0c 47 00 02          cmpi.w   #$2, d7
  0082b6:  66 06                bne.b    $82be  ; -> L82be
  0082b8:  20 53                movea.l  (a3), a0
  0082ba:  29 50 00 02          move.l   (a0), $2(a4)
L82be:
  0082be:  20 2b 00 2e          move.l   $2e(a3), d0
  0082c2:  08 00 00 00          btst.b   #$0, d0
  0082c6:  67 08                beq.b    $82d0  ; -> L82d0
  0082c8:  70 00                moveq    #$0, d0
  0082ca:  29 40 00 9c          move.l   d0, $9c(a4)
  0082ce:  60 28                bra.b    $82f8  ; -> L82f8
L82d0:
  0082d0:  0c 47 00 02          cmpi.w   #$2, d7
  0082d4:  66 04                bne.b    $82da  ; -> L82da
  0082d6:  20 13                move.l   (a3), d0
  0082d8:  60 0a                bra.b    $82e4  ; -> L82e4
L82da:
  0082da:  2f 13                move.l   (a3), -(a7)
  0082dc:  61 ff ff ff ff 50    bsr.l    $822e  ; -> sub_822e
  0082e2:  58 4f                addq.w   #$4, a7
L82e4:
  0082e4:  29 40 00 9c          move.l   d0, $9c(a4)
  0082e8:  60 0e                bra.b    $82f8  ; -> L82f8
L82ea:
  0082ea:  20 4c                movea.l  a4, a0
  0082ec:  54 88                addq.l   #$2, a0
  0082ee:  22 4b                movea.l  a3, a1
  0082f0:  20 d9                move.l   (a1)+, (a0)+
  0082f2:  20 d9                move.l   (a1)+, (a0)+
  0082f4:  20 d9                move.l   (a1)+, (a0)+
  0082f6:  30 d9                move.w   (a1)+, (a0)+
L82f8:
  0082f8:  20 6e 00 20          movea.l  $20(a6), a0
  0082fc:  43 ec 00 a8          lea.l    $a8(a4), a1
  008300:  22 d8                move.l   (a0)+, (a1)+
  008302:  22 d8                move.l   (a0)+, (a1)+
  008304:  2d 78 08 24 ff f6    move.l   $824.w, -$a(a6)
  00830a:  4a ae 00 10          tst.l    $10(a6)
  00830e:  67 00 00 a8          beq.w    $83b8  ; -> L83b8
  008312:  20 6e 00 10          movea.l  $10(a6), a0
  008316:  3c 28 00 04          move.w   $4(a0), d6
  00831a:  6c 7e                bge.b    $839a  ; -> L839a
  00831c:  30 3c 40 00          move.w   #$4000, d0
  008320:  c0 46                and.w    d6, d0
  008322:  67 06                beq.b    $832a  ; -> L832a
  008324:  20 50                movea.l  (a0), a0
  008326:  2d 50 00 10          move.l   (a0), $10(a6)
L832a:
  00832a:  20 6e 00 10          movea.l  $10(a6), a0
  00832e:  43 ec 00 6a          lea.l    $6a(a4), a1
  008332:  70 0b                moveq    #$b, d0
L8334:
  008334:  22 d8                move.l   (a0)+, (a1)+
  008336:  51 c8 ff fc          dbra     d0, $8334  ; -> L8334
  00833a:  32 d8                move.w   (a0)+, (a1)+
  00833c:  20 6e 00 10          movea.l  $10(a6), a0
  008340:  3e 28 00 0e          move.w   $e(a0), d7
  008344:  0c 47 00 01          cmpi.w   #$1, d7
  008348:  67 06                beq.b    $8350  ; -> L8350
  00834a:  0c 47 00 02          cmpi.w   #$2, d7
  00834e:  66 5a                bne.b    $83aa  ; -> L83aa
L8350:
  008350:  0c 47 00 02          cmpi.w   #$2, d7
  008354:  66 0a                bne.b    $8360  ; -> L8360
  008356:  20 6e 00 10          movea.l  $10(a6), a0
  00835a:  20 50                movea.l  (a0), a0
  00835c:  29 50 00 6a          move.l   (a0), $6a(a4)
L8360:
  008360:  20 6e 00 10          movea.l  $10(a6), a0
  008364:  20 28 00 2e          move.l   $2e(a0), d0
  008368:  08 00 00 00          btst.b   #$0, d0
  00836c:  67 08                beq.b    $8376  ; -> L8376
  00836e:  70 00                moveq    #$0, d0
  008370:  29 40 00 a4          move.l   d0, $a4(a4)
  008374:  60 34                bra.b    $83aa  ; -> L83aa
L8376:
  008376:  0c 47 00 02          cmpi.w   #$2, d7
  00837a:  66 08                bne.b    $8384  ; -> L8384
  00837c:  20 6e 00 10          movea.l  $10(a6), a0
  008380:  20 50                movea.l  (a0), a0
  008382:  60 10                bra.b    $8394  ; -> L8394
L8384:
  008384:  20 6e 00 10          movea.l  $10(a6), a0
  008388:  2f 10                move.l   (a0), -(a7)
  00838a:  61 ff ff ff fe a2    bsr.l    $822e  ; -> sub_822e
  008390:  20 40                movea.l  d0, a0
  008392:  58 4f                addq.w   #$4, a7
L8394:
  008394:  29 48 00 a4          move.l   a0, $a4(a4)
  008398:  60 10                bra.b    $83aa  ; -> L83aa
L839a:
  00839a:  20 6e 00 10          movea.l  $10(a6), a0
  00839e:  43 ec 00 6a          lea.l    $6a(a4), a1
  0083a2:  22 d8                move.l   (a0)+, (a1)+
  0083a4:  22 d8                move.l   (a0)+, (a1)+
  0083a6:  22 d8                move.l   (a0)+, (a1)+
  0083a8:  32 d8                move.w   (a0)+, (a1)+
L83aa:
  0083aa:  20 6e 00 1c          movea.l  $1c(a6), a0
  0083ae:  43 ec 00 b8          lea.l    $b8(a4), a1
  0083b2:  22 d8                move.l   (a0)+, (a1)+
  0083b4:  22 d8                move.l   (a0)+, (a1)+
  0083b6:  60 06                bra.b    $83be  ; -> L83be
L83b8:
  0083b8:  70 00                moveq    #$0, d0
  0083ba:  29 40 00 6a          move.l   d0, $6a(a4)
L83be:
  0083be:  2d 78 0c c8 ff f2    move.l   $cc8.w, -$e(a6)
  0083c4:  29 78 0c c8 00 d0    move.l   $cc8.w, $d0(a4)
  0083ca:  61 ff ff ff fc 44    bsr.l    $8010  ; -> GetA5
  0083d0:  20 40                movea.l  d0, a0
  0083d2:  20 50                movea.l  (a0), a0
  0083d4:  20 50                movea.l  (a0), a0
  0083d6:  2d 48 ff ee          move.l   a0, -$12(a6)
  0083da:  4a 68 00 06          tst.w    $6(a0)
  0083de:  5d c0                slt.b    d0
  0083e0:  44 00                neg.b    d0
  0083e2:  48 80                ext.w    d0
  0083e4:  38 00                move.w   d0, d4
  0083e6:  39 44 00 f4          move.w   d4, $f4(a4)
  0083ea:  20 6e ff ee          movea.l  -$12(a6), a0
  0083ee:  29 68 00 50 00 e0    move.l   $50(a0), $e0(a4)
  0083f4:  20 6e ff ee          movea.l  -$12(a6), a0
  0083f8:  29 68 00 54 00 e4    move.l   $54(a0), $e4(a4)
  0083fe:  4a 44                tst.w    d4
  008400:  67 66                beq.b    $8468  ; -> L8468
  008402:  20 6e ff ee          movea.l  -$12(a6), a0
  008406:  43 ec 00 e8          lea.l    $e8(a4), a1
  00840a:  41 e8 00 24          lea.l    $24(a0), a0
  00840e:  22 d8                move.l   (a0)+, (a1)+
  008410:  32 d8                move.w   (a0)+, (a1)+
  008412:  20 6e ff ee          movea.l  -$12(a6), a0
  008416:  43 ec 00 ee          lea.l    $ee(a4), a1
  00841a:  41 e8 00 2a          lea.l    $2a(a0), a0
  00841e:  22 d8                move.l   (a0)+, (a1)+
  008420:  32 d8                move.w   (a0)+, (a1)+
  008422:  20 6e ff f2          movea.l  -$e(a6), a0
  008426:  20 50                movea.l  (a0), a0
  008428:  4a a8 00 0c          tst.l    $c(a0)
  00842c:  67 76                beq.b    $84a4  ; -> L84a4
  00842e:  20 6e ff ee          movea.l  -$12(a6), a0
  008432:  43 ee ff fa          lea.l    -$6(a6), a1
  008436:  41 e8 00 24          lea.l    $24(a0), a0
  00843a:  22 d8                move.l   (a0)+, (a1)+
  00843c:  32 d8                move.w   (a0)+, (a1)+
  00843e:  59 8f                subq.l   #$4, a7
  008440:  48 6e ff fa          pea.l    -$6(a6)
  008444:  aa 33                dc.w     $aa33  ; _Color2Index
  008446:  29 5f 00 e0          move.l   (a7)+, $e0(a4)
  00844a:  20 6e ff ee          movea.l  -$12(a6), a0
  00844e:  43 ee ff fa          lea.l    -$6(a6), a1
  008452:  41 e8 00 2a          lea.l    $2a(a0), a0
  008456:  22 d8                move.l   (a0)+, (a1)+
  008458:  32 d8                move.w   (a0)+, (a1)+
  00845a:  59 8f                subq.l   #$4, a7
  00845c:  48 6e ff fa          pea.l    -$6(a6)
  008460:  aa 33                dc.w     $aa33  ; _Color2Index
  008462:  29 5f 00 e4          move.l   (a7)+, $e4(a4)
  008466:  60 3c                bra.b    $84a4  ; -> L84a4
L8468:
  008468:  20 6e ff ee          movea.l  -$12(a6), a0
  00846c:  2f 28 00 50          move.l   $50(a0), -(a7)
  008470:  61 ff 00 00 0d 0c    bsr.l    $917e  ; -> sub_917e
  008476:  20 40                movea.l  d0, a0
  008478:  43 ec 00 e8          lea.l    $e8(a4), a1
  00847c:  22 d8                move.l   (a0)+, (a1)+
  00847e:  32 d8                move.w   (a0)+, (a1)+
  008480:  20 6e ff ee          movea.l  -$12(a6), a0
  008484:  2f 28 00 54          move.l   $54(a0), -(a7)
  008488:  61 ff 00 00 0c f4    bsr.l    $917e  ; -> sub_917e
  00848e:  20 40                movea.l  d0, a0
  008490:  43 ec 00 ee          lea.l    $ee(a4), a1
  008494:  22 d8                move.l   (a0)+, (a1)+
  008496:  32 d8                move.w   (a0)+, (a1)+
  008498:  20 6e ff ee          movea.l  -$12(a6), a0
  00849c:  39 68 00 58 00 f6    move.w   $58(a0), $f6(a4)
  0084a2:  50 4f                addq.w   #$8, a7
L84a4:
  0084a4:  20 6e 00 0c          movea.l  $c(a6), a0
  0084a8:  3c 28 00 04          move.w   $4(a0), d6
  0084ac:  6c 7e                bge.b    $852c  ; -> L852c
  0084ae:  30 3c 40 00          move.w   #$4000, d0
  0084b2:  c0 46                and.w    d6, d0
  0084b4:  67 06                beq.b    $84bc  ; -> L84bc
  0084b6:  20 50                movea.l  (a0), a0
  0084b8:  2d 50 00 0c          move.l   (a0), $c(a6)
L84bc:
  0084bc:  20 6e 00 0c          movea.l  $c(a6), a0
  0084c0:  43 ec 00 36          lea.l    $36(a4), a1
  0084c4:  70 0b                moveq    #$b, d0
L84c6:
  0084c6:  22 d8                move.l   (a0)+, (a1)+
  0084c8:  51 c8 ff fc          dbra     d0, $84c6  ; -> L84c6
  0084cc:  32 d8                move.w   (a0)+, (a1)+
  0084ce:  20 6e 00 0c          movea.l  $c(a6), a0
  0084d2:  3e 28 00 0e          move.w   $e(a0), d7
  0084d6:  0c 47 00 01          cmpi.w   #$1, d7
  0084da:  67 06                beq.b    $84e2  ; -> L84e2
  0084dc:  0c 47 00 02          cmpi.w   #$2, d7
  0084e0:  66 5a                bne.b    $853c  ; -> L853c
L84e2:
  0084e2:  0c 47 00 02          cmpi.w   #$2, d7
  0084e6:  66 0a                bne.b    $84f2  ; -> L84f2
  0084e8:  20 6e 00 0c          movea.l  $c(a6), a0
  0084ec:  20 50                movea.l  (a0), a0
  0084ee:  29 50 00 36          move.l   (a0), $36(a4)
L84f2:
  0084f2:  20 6e 00 0c          movea.l  $c(a6), a0
  0084f6:  20 28 00 2e          move.l   $2e(a0), d0
  0084fa:  08 00 00 00          btst.b   #$0, d0
  0084fe:  67 08                beq.b    $8508  ; -> L8508
  008500:  70 00                moveq    #$0, d0
  008502:  29 40 00 a0          move.l   d0, $a0(a4)
  008506:  60 34                bra.b    $853c  ; -> L853c
L8508:
  008508:  0c 47 00 02          cmpi.w   #$2, d7
  00850c:  66 08                bne.b    $8516  ; -> L8516
  00850e:  20 6e 00 0c          movea.l  $c(a6), a0
  008512:  20 50                movea.l  (a0), a0
  008514:  60 10                bra.b    $8526  ; -> L8526
L8516:
  008516:  20 6e 00 0c          movea.l  $c(a6), a0
  00851a:  2f 10                move.l   (a0), -(a7)
  00851c:  61 ff ff ff fd 10    bsr.l    $822e  ; -> sub_822e
  008522:  20 40                movea.l  d0, a0
  008524:  58 4f                addq.w   #$4, a7
L8526:
  008526:  29 48 00 a0          move.l   a0, $a0(a4)
  00852a:  60 10                bra.b    $853c  ; -> L853c
L852c:
  00852c:  20 6e 00 0c          movea.l  $c(a6), a0
  008530:  43 ec 00 36          lea.l    $36(a4), a1
  008534:  22 d8                move.l   (a0)+, (a1)+
  008536:  22 d8                move.l   (a0)+, (a1)+
  008538:  22 d8                move.l   (a0)+, (a1)+
  00853a:  32 d8                move.w   (a0)+, (a1)+
L853c:
  00853c:  20 6e 00 18          movea.l  $18(a6), a0
  008540:  43 ec 00 b0          lea.l    $b0(a4), a1
  008544:  22 d8                move.l   (a0)+, (a1)+
  008546:  22 d8                move.l   (a0)+, (a1)+
  008548:  70 02                moveq    #$2, d0
  00854a:  b0 85                cmp.l    d5, d0
  00854c:  66 08                bne.b    $8556  ; -> L8556
  00854e:  4a 38 09 38          tst.b    $938.w
  008552:  6d 02                blt.b    $8556  ; -> L8556
  008554:  7a 32                moveq    #$32, d5
L8556:
  008556:  29 78 08 a0 00 d4    move.l   $8a0.w, $d4(a4)
  00855c:  20 13                move.l   (a3), d0
  00855e:  b0 ae ff f6          cmp.l    -$a(a6), d0
  008562:  66 16                bne.b    $857a  ; -> L857a
  008564:  20 6e ff f2          movea.l  -$e(a6), a0
  008568:  20 50                movea.l  (a0), a0
  00856a:  20 68 00 16          movea.l  $16(a0), a0
  00856e:  20 50                movea.l  (a0), a0
  008570:  30 28 00 20          move.w   $20(a0), d0
  008574:  48 c0                ext.l    d0
  008576:  2e 00                move.l   d0, d7
  008578:  60 12                bra.b    $858c  ; -> L858c
L857a:
  00857a:  4a ae ff ea          tst.l    -$16(a6)
  00857e:  67 0a                beq.b    $858a  ; -> L858a
  008580:  30 2b 00 20          move.w   $20(a3), d0
  008584:  48 c0                ext.l    d0
  008586:  2e 00                move.l   d0, d7
  008588:  60 02                bra.b    $858c  ; -> L858c
L858a:
  00858a:  7e 01                moveq    #$1, d7
L858c:
  00858c:  70 20                moveq    #$20, d0
  00858e:  c0 85                and.l    d5, d0
  008590:  67 38                beq.b    $85ca  ; -> L85ca
  008592:  70 01                moveq    #$1, d0
  008594:  b0 87                cmp.l    d7, d0
  008596:  6c 32                bge.b    $85ca  ; -> L85ca
  008598:  4a 44                tst.w    d4
  00859a:  67 22                beq.b    $85be  ; -> L85be
  00859c:  20 6e ff ee          movea.l  -$12(a6), a0
  0085a0:  20 68 00 08          movea.l  $8(a0), a0
  0085a4:  26 50                movea.l  (a0), a3
  0085a6:  41 ec 00 f8          lea.l    $f8(a4), a0
  0085aa:  22 4b                movea.l  a3, a1
  0085ac:  20 d9                move.l   (a1)+, (a0)+
  0085ae:  30 d9                move.w   (a1)+, (a0)+
  0085b0:  41 ec 00 fe          lea.l    $fe(a4), a0
  0085b4:  22 4b                movea.l  a3, a1
  0085b6:  5c 89                addq.l   #$6, a1
  0085b8:  20 d9                move.l   (a1)+, (a0)+
  0085ba:  30 d9                move.w   (a1)+, (a0)+
  0085bc:  60 0c                bra.b    $85ca  ; -> L85ca
L85be:
  0085be:  41 ec 00 fe          lea.l    $fe(a4), a0
  0085c2:  43 f8 0d a0          lea.l    $da0.w, a1
  0085c6:  20 d9                move.l   (a1)+, (a0)+
  0085c8:  30 d9                move.w   (a1)+, (a0)+
L85ca:
  0085ca:  38 85                move.w   d5, (a4)
  0085cc:  4a ae 00 34          tst.l    $34(a6)
  0085d0:  56 c0                sne.b    d0
  0085d2:  44 00                neg.b    d0
  0085d4:  49 c0                extb.l   d0
  0085d6:  29 40 00 cc          move.l   d0, $cc(a4)
  0085da:  20 6e 00 28          movea.l  $28(a6), a0
  0085de:  26 50                movea.l  (a0), a3
  0085e0:  29 4b 00 c0          move.l   a3, $c0(a4)
  0085e4:  39 53 01 04          move.w   (a3), $104(a4)
  0085e8:  20 6e 00 2c          movea.l  $2c(a6), a0
  0085ec:  26 50                movea.l  (a0), a3
  0085ee:  29 4b 00 c4          move.l   a3, $c4(a4)
  0085f2:  39 53 01 06          move.w   (a3), $106(a4)
  0085f6:  20 6e 00 30          movea.l  $30(a6), a0
  0085fa:  26 50                movea.l  (a0), a3
  0085fc:  29 4b 00 c8          move.l   a3, $c8(a4)
  008600:  39 53 01 08          move.w   (a3), $108(a4)
  008604:  4c ee 18 f0 ff d2    movem.l  -$2e(a6), d4-d7/a3-a4
  00860a:  4e 5e                unlk     a6
  00860c:  4e 75                rts      
sub_860e:
  00860e:  4e 56 ff fc          link.w   a6, #$fffc
  008612:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  008616:  26 6e 00 08          movea.l  $8(a6), a3
  00861a:  61 ff ff ff f9 f4    bsr.l    $8010  ; -> GetA5
  008620:  20 40                movea.l  d0, a0
  008622:  20 50                movea.l  (a0), a0
  008624:  2d 50 ff fc          move.l   (a0), -$4(a6)
  008628:  20 6e ff fc          movea.l  -$4(a6), a0
  00862c:  26 88                move.l   a0, (a3)
  00862e:  49 e8 00 02          lea.l    $2(a0), a4
  008632:  4a 6c 00 04          tst.w    $4(a4)
  008636:  5d c0                slt.b    d0
  008638:  44 00                neg.b    d0
  00863a:  49 c0                extb.l   d0
  00863c:  1e 00                move.b   d0, d7
  00863e:  67 5c                beq.b    $869c  ; -> L869c
  008640:  20 54                movea.l  (a4), a0
  008642:  28 50                movea.l  (a0), a4
  008644:  41 eb 00 0e          lea.l    $e(a3), a0
  008648:  22 4c                movea.l  a4, a1
  00864a:  70 0b                moveq    #$b, d0
L864c:
  00864c:  20 d9                move.l   (a1)+, (a0)+
  00864e:  51 c8 ff fc          dbra     d0, $864c  ; -> L864c
  008652:  30 d9                move.w   (a1)+, (a0)+
  008654:  3e 2c 00 0e          move.w   $e(a4), d7
  008658:  0c 47 00 01          cmpi.w   #$1, d7
  00865c:  67 06                beq.b    $8664  ; -> L8664
  00865e:  0c 47 00 02          cmpi.w   #$2, d7
  008662:  66 44                bne.b    $86a8  ; -> L86a8
L8664:
  008664:  0c 47 00 02          cmpi.w   #$2, d7
  008668:  66 06                bne.b    $8670  ; -> L8670
  00866a:  20 54                movea.l  (a4), a0
  00866c:  27 50 00 0e          move.l   (a0), $e(a3)
L8670:
  008670:  20 2c 00 2e          move.l   $2e(a4), d0
  008674:  08 00 00 00          btst.b   #$0, d0
  008678:  67 08                beq.b    $8682  ; -> L8682
  00867a:  70 00                moveq    #$0, d0
  00867c:  27 40 00 04          move.l   d0, $4(a3)
  008680:  60 26                bra.b    $86a8  ; -> L86a8
L8682:
  008682:  0c 47 00 02          cmpi.w   #$2, d7
  008686:  66 04                bne.b    $868c  ; -> L868c
  008688:  20 14                move.l   (a4), d0
  00868a:  60 0a                bra.b    $8696  ; -> L8696
L868c:
  00868c:  2f 14                move.l   (a4), -(a7)
  00868e:  61 ff ff ff fb 9e    bsr.l    $822e  ; -> sub_822e
  008694:  58 4f                addq.w   #$4, a7
L8696:
  008696:  27 40 00 04          move.l   d0, $4(a3)
  00869a:  60 0c                bra.b    $86a8  ; -> L86a8
L869c:
  00869c:  41 eb 00 14          lea.l    $14(a3), a0
  0086a0:  22 4c                movea.l  a4, a1
  0086a2:  5c 89                addq.l   #$6, a1
  0086a4:  20 d9                move.l   (a1)+, (a0)+
  0086a6:  20 d9                move.l   (a1)+, (a0)+
L86a8:
  0086a8:  61 ff ff ff f9 66    bsr.l    $8010  ; -> GetA5
  0086ae:  20 40                movea.l  d0, a0
  0086b0:  20 10                move.l   (a0), d0
  0086b2:  90 bc 00 00 00 ca    sub.l    #$ca, d0
  0086b8:  20 40                movea.l  d0, a0
  0086ba:  27 68 00 22 00 40    move.l   $22(a0), $40(a3)
  0086c0:  27 78 0c c8 00 48    move.l   $cc8.w, $48(a3)
  0086c6:  27 78 08 a8 00 44    move.l   $8a8.w, $44(a3)
  0086cc:  4c ee 18 80 ff f0    movem.l  -$10(a6), d7/a3-a4
  0086d2:  4e 5e                unlk     a6
  0086d4:  4e 75                rts      
sub_86d6:
  0086d6:  4e 56 ff f8          link.w   a6, #$fff8
  0086da:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  0086de:  26 6e 00 08          movea.l  $8(a6), a3
  0086e2:  70 01                moveq    #$1, d0
  0086e4:  2f 00                move.l   d0, -(a7)
  0086e6:  72 00                moveq    #$0, d1
  0086e8:  2f 01                move.l   d1, -(a7)
  0086ea:  2f 01                move.l   d1, -(a7)
  0086ec:  70 38                moveq    #$38, d0
  0086ee:  2f 00                move.l   d0, -(a7)
  0086f0:  61 ff ff ff c2 d2    bsr.l    $49c4  ; -> EngineDispatch
  0086f6:  3e 2b 00 04          move.w   $4(a3), d7
  0086fa:  4f ef 00 10          lea.l    $10(a7), a7
  0086fe:  6d 06                blt.b    $8706  ; -> L8706
  008700:  70 00                moveq    #$0, d0
  008702:  60 00 00 8c          bra.w    $8790  ; -> L8790
L8706:
  008706:  30 3c 40 00          move.w   #$4000, d0
  00870a:  c0 47                and.w    d7, d0
  00870c:  67 06                beq.b    $8714  ; -> L8714
  00870e:  20 53                movea.l  (a3), a0
  008710:  28 50                movea.l  (a0), a4
  008712:  60 02                bra.b    $8716  ; -> L8716
L8714:
  008714:  28 4b                movea.l  a3, a4
L8716:
  008716:  30 2c 00 0e          move.w   $e(a4), d0
  00871a:  48 c0                ext.l    d0
  00871c:  2e 00                move.l   d0, d7
  00871e:  70 01                moveq    #$1, d0
  008720:  b0 87                cmp.l    d7, d0
  008722:  66 0e                bne.b    $8732  ; -> L8732
  008724:  2f 14                move.l   (a4), -(a7)
  008726:  61 ff ff ff fb 06    bsr.l    $822e  ; -> sub_822e
  00872c:  26 40                movea.l  d0, a3
  00872e:  58 4f                addq.w   #$4, a7
  008730:  60 0e                bra.b    $8740  ; -> L8740
L8732:
  008732:  70 02                moveq    #$2, d0
  008734:  b0 87                cmp.l    d7, d0
  008736:  66 04                bne.b    $873c  ; -> L873c
  008738:  26 54                movea.l  (a4), a3
  00873a:  60 04                bra.b    $8740  ; -> L8740
L873c:
  00873c:  70 00                moveq    #$0, d0
  00873e:  60 50                bra.b    $8790  ; -> L8790
L8740:
  008740:  20 0b                move.l   a3, d0
  008742:  67 28                beq.b    $876c  ; -> L876c
  008744:  2d 4b ff f8          move.l   a3, -$8(a6)
  008748:  70 00                moveq    #$0, d0
  00874a:  2d 40 ff fc          move.l   d0, -$4(a6)
  00874e:  70 01                moveq    #$1, d0
  008750:  2f 00                move.l   d0, -(a7)
  008752:  72 02                moveq    #$2, d1
  008754:  2f 01                move.l   d1, -(a7)
  008756:  48 6e ff f8          pea.l    -$8(a6)
  00875a:  70 0d                moveq    #$d, d0
  00875c:  2f 00                move.l   d0, -(a7)
  00875e:  61 ff ff ff c2 64    bsr.l    $49c4  ; -> EngineDispatch
  008764:  26 40                movea.l  d0, a3
  008766:  4f ef 00 10          lea.l    $10(a7), a7
  00876a:  60 04                bra.b    $8770  ; -> L8770
L876c:
  00876c:  70 00                moveq    #$0, d0
  00876e:  26 40                movea.l  d0, a3
L8770:
  008770:  20 0b                move.l   a3, d0
  008772:  66 04                bne.b    $8778  ; -> L8778
  008774:  70 00                moveq    #$0, d0
  008776:  60 18                bra.b    $8790  ; -> L8790
L8778:
  008778:  20 6e 00 0c          movea.l  $c(a6), a0
  00877c:  20 94                move.l   (a4), (a0)
  00877e:  20 6e 00 10          movea.l  $10(a6), a0
  008782:  30 ac 00 0e          move.w   $e(a4), (a0)
  008786:  28 8b                move.l   a3, (a4)
  008788:  39 7c 00 04 00 0e    move.w   #$4, $e(a4)
  00878e:  70 01                moveq    #$1, d0
L8790:
  008790:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  008796:  4e 5e                unlk     a6
  008798:  4e 75                rts      
sub_879a:
  00879a:  4e 56 00 00          link.w   a6, #$0
  00879e:  48 e7 00 18          movem.l  a3-a4, -(a7)
  0087a2:  26 6e 00 08          movea.l  $8(a6), a3
  0087a6:  30 3c 40 00          move.w   #$4000, d0
  0087aa:  c0 6b 00 04          and.w    $4(a3), d0
  0087ae:  67 06                beq.b    $87b6  ; -> L87b6
  0087b0:  20 53                movea.l  (a3), a0
  0087b2:  28 50                movea.l  (a0), a4
  0087b4:  60 02                bra.b    $87b8  ; -> L87b8
L87b6:
  0087b6:  28 4b                movea.l  a3, a4
L87b8:
  0087b8:  28 ae 00 0c          move.l   $c(a6), (a4)
  0087bc:  39 6e 00 12 00 0e    move.w   $12(a6), $e(a4)
  0087c2:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  0087c8:  4e 5e                unlk     a6
  0087ca:  4e 75                rts      
sub_87cc:
  0087cc:  4e 56 ff fe          link.w   a6, #$fffe
  0087d0:  48 e7 13 18          movem.l  d3/d6-d7/a3-a4, -(a7)
  0087d4:  2c 2e 00 0c          move.l   $c(a6), d6
  0087d8:  26 6e 00 08          movea.l  $8(a6), a3
  0087dc:  1d 7c 00 01 ff ff    move.b   #$1, -$1(a6)
  0087e2:  41 ee ff ff          lea.l    -$1(a6), a0
  0087e6:  10 10                move.b   (a0), d0
  0087e8:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  0087ea:  10 80                move.b   d0, (a0)
L87ec:
  0087ec:  4a ab 00 04          tst.l    $4(a3)
  0087f0:  66 fa                bne.b    $87ec  ; -> L87ec
  0087f2:  70 01                moveq    #$1, d0
  0087f4:  26 80                move.l   d0, (a3)
  0087f6:  4a ab 00 04          tst.l    $4(a3)
  0087fa:  67 0e                beq.b    $880a  ; -> L880a
  0087fc:  70 00                moveq    #$0, d0
  0087fe:  26 80                move.l   d0, (a3)
L8800:
  008800:  4a ab 00 04          tst.l    $4(a3)
  008804:  66 fa                bne.b    $8800  ; -> L8800
  008806:  70 01                moveq    #$1, d0
  008808:  26 80                move.l   d0, (a3)
L880a:
  00880a:  42 07                clr.b    d7
  00880c:  28 6b 00 08          movea.l  $8(a3), a4
  008810:  76 00                moveq    #$0, d3
  008812:  60 1c                bra.b    $8830  ; -> L8830
L8814:
  008814:  bc ac 00 0c          cmp.l    $c(a4), d6
  008818:  66 12                bne.b    $882c  ; -> L882c
  00881a:  20 3c 40 00 00 00    move.l   #$40000000, d0
  008820:  c0 94                and.l    (a4), d0
  008822:  66 08                bne.b    $882c  ; -> L882c
  008824:  7e 01                moveq    #$1, d7
  008826:  00 14 00 80          ori.b    #$80, (a4)
  00882a:  60 08                bra.b    $8834  ; -> L8834
L882c:
  00882c:  28 6c 00 08          movea.l  $8(a4), a4
L8830:
  008830:  b6 8c                cmp.l    a4, d3
  008832:  66 e0                bne.b    $8814  ; -> L8814
L8834:
  008834:  70 00                moveq    #$0, d0
  008836:  26 80                move.l   d0, (a3)
  008838:  41 ee ff ff          lea.l    -$1(a6), a0
  00883c:  10 10                move.b   (a0), d0
  00883e:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  008840:  10 80                move.b   d0, (a0)
  008842:  10 07                move.b   d7, d0
  008844:  4c ee 18 c8 ff ea    movem.l  -$16(a6), d3/d6-d7/a3-a4
  00884a:  4e 5e                unlk     a6
  00884c:  4e 75                rts      
sub_884e:
  00884e:  4e 56 ff fa          link.w   a6, #$fffa
  008852:  48 e7 17 18          movem.l  d3/d5-d7/a3-a4, -(a7)
  008856:  2a 2e 00 10          move.l   $10(a6), d5
  00885a:  2c 2e 00 0c          move.l   $c(a6), d6
  00885e:  26 6e 00 08          movea.l  $8(a6), a3
  008862:  1d 7c 00 01 ff fb    move.b   #$1, -$5(a6)
  008868:  41 ee ff fb          lea.l    -$5(a6), a0
  00886c:  10 10                move.b   (a0), d0
  00886e:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  008870:  10 80                move.b   d0, (a0)
L8872:
  008872:  4a ab 00 04          tst.l    $4(a3)
  008876:  66 fa                bne.b    $8872  ; -> L8872
  008878:  70 01                moveq    #$1, d0
  00887a:  26 80                move.l   d0, (a3)
  00887c:  4a ab 00 04          tst.l    $4(a3)
  008880:  67 0e                beq.b    $8890  ; -> L8890
  008882:  70 00                moveq    #$0, d0
  008884:  26 80                move.l   d0, (a3)
L8886:
  008886:  4a ab 00 04          tst.l    $4(a3)
  00888a:  66 fa                bne.b    $8886  ; -> L8886
  00888c:  70 01                moveq    #$1, d0
  00888e:  26 80                move.l   d0, (a3)
L8890:
  008890:  42 07                clr.b    d7
  008892:  28 6b 00 08          movea.l  $8(a3), a4
  008896:  76 00                moveq    #$0, d3
  008898:  60 2e                bra.b    $88c8  ; -> L88c8
L889a:
  00889a:  bc ac 00 0c          cmp.l    $c(a4), d6
  00889e:  66 24                bne.b    $88c4  ; -> L88c4
  0088a0:  20 3c 40 00 00 00    move.l   #$40000000, d0
  0088a6:  c0 94                and.l    (a4), d0
  0088a8:  66 1a                bne.b    $88c4  ; -> L88c4
  0088aa:  41 ec 00 10          lea.l    $10(a4), a0
  0088ae:  2d 48 ff fc          move.l   a0, -$4(a6)
  0088b2:  30 28 04 32          move.w   $432(a0), d0
  0088b6:  48 c0                ext.l    d0
  0088b8:  ba 80                cmp.l    d0, d5
  0088ba:  66 08                bne.b    $88c4  ; -> L88c4
  0088bc:  7e 01                moveq    #$1, d7
  0088be:  00 14 00 80          ori.b    #$80, (a4)
  0088c2:  60 08                bra.b    $88cc  ; -> L88cc
L88c4:
  0088c4:  28 6c 00 08          movea.l  $8(a4), a4
L88c8:
  0088c8:  b6 8c                cmp.l    a4, d3
  0088ca:  66 ce                bne.b    $889a  ; -> L889a
L88cc:
  0088cc:  70 00                moveq    #$0, d0
  0088ce:  26 80                move.l   d0, (a3)
  0088d0:  41 ee ff fb          lea.l    -$5(a6), a0
  0088d4:  10 10                move.b   (a0), d0
  0088d6:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  0088d8:  10 80                move.b   d0, (a0)
  0088da:  10 07                move.b   d7, d0
  0088dc:  4c ee 18 e8 ff e2    movem.l  -$1e(a6), d3/d5-d7/a3-a4
  0088e2:  4e 5e                unlk     a6
  0088e4:  4e 75                rts      
sub_88e6:
  0088e6:  4e 56 ff 9a          link.w   a6, #$ff9a
  0088ea:  48 e7 1f 18          movem.l  d3-d7/a3-a4, -(a7)
  0088ee:  28 6e 00 1c          movea.l  $1c(a6), a4
  0088f2:  26 6e 00 08          movea.l  $8(a6), a3
  0088f6:  2a 2e 00 0c          move.l   $c(a6), d5
  0088fa:  61 ff ff ff f7 14    bsr.l    $8010  ; -> GetA5
  008900:  20 40                movea.l  d0, a0
  008902:  20 10                move.l   (a0), d0
  008904:  90 bc 00 00 00 ca    sub.l    #$ca, d0
  00890a:  2d 40 ff 9a          move.l   d0, -$66(a6)
  00890e:  70 00                moveq    #$0, d0
  008910:  2d 40 ff b6          move.l   d0, -$4a(a6)
  008914:  7e 00                moveq    #$0, d7
  008916:  42 04                clr.b    d4
  008918:  42 2e ff fd          clr.b    -$3(a6)
  00891c:  42 2e ff fe          clr.b    -$2(a6)
  008920:  55 8f                subq.l   #$2, a7
  008922:  3f 05                move.w   d5, -(a7)
  008924:  2f 0b                move.l   a3, -(a7)
  008926:  48 6e 00 10          pea.l    $10(a6)
  00892a:  48 6e 00 14          pea.l    $14(a6)
  00892e:  48 6e ff 9e          pea.l    -$62(a6)
  008932:  a8 ed                dc.w     $a8ed  ; _StdTxMeas
  008934:  20 6e ff 9a          movea.l  -$66(a6), a0
  008938:  2c 28 00 1e          move.l   $1e(a0), d6
  00893c:  20 6e 00 18          movea.l  $18(a6), a0
  008940:  20 86                move.l   d6, (a0)
  008942:  3d 6e 00 12 ff b2    move.w   $12(a6), -$4e(a6)
  008948:  3d 6e 00 16 ff b4    move.w   $16(a6), -$4c(a6)
  00894e:  30 2e ff b2          move.w   -$4e(a6), d0
  008952:  b0 6e ff b4          cmp.w    -$4c(a6), d0
  008956:  54 4f                addq.w   #$2, a7
  008958:  66 04                bne.b    $895e  ; -> L895e
  00895a:  28 86                move.l   d6, (a4)
  00895c:  60 1e                bra.b    $897c  ; -> L897c
L895e:
  00895e:  30 2e ff b4          move.w   -$4c(a6), d0
  008962:  48 c0                ext.l    d0
  008964:  2f 00                move.l   d0, -(a7)
  008966:  30 2e ff b2          move.w   -$4e(a6), d0
  00896a:  48 c0                ext.l    d0
  00896c:  2f 00                move.l   d0, -(a7)
  00896e:  2f 06                move.l   d6, -(a7)
  008970:  61 ff ff ff f4 be    bsr.l    $7e30  ; -> FixScale
  008976:  28 80                move.l   d0, (a4)
  008978:  4f ef 00 0c          lea.l    $c(a7), a7
L897c:
  00897c:  20 6e 00 28          movea.l  $28(a6), a0
  008980:  28 50                movea.l  (a0), a4
  008982:  2d 78 0b 2a ff aa    move.l   $b2a.w, -$56(a6)
  008988:  20 6e ff aa          movea.l  -$56(a6), a0
  00898c:  20 50                movea.l  (a0), a0
  00898e:  2d 48 ff ae          move.l   a0, -$52(a6)
  008992:  4a 28 04 36          tst.b    $436(a0)
  008996:  67 06                beq.b    $899e  ; -> L899e
  008998:  70 ff                moveq    #$ff, d0
  00899a:  60 00 03 fe          bra.w    $8d9a  ; -> L8d9a
L899e:
  00899e:  20 6e ff ae          movea.l  -$52(a6), a0
  0089a2:  22 6e 00 20          movea.l  $20(a6), a1
  0089a6:  22 a8 00 80          move.l   $80(a0), (a1)
  0089aa:  2f 2e ff ae          move.l   -$52(a6), -(a7)
  0089ae:  61 ff ff ff f4 dc    bsr.l    $7e8c  ; -> sub_7e8c
  0089b4:  3d 40 ff ba          move.w   d0, -$46(a6)
  0089b8:  b9 ee ff aa          cmpa.l   -$56(a6), a4
  0089bc:  58 4f                addq.w   #$4, a7
  0089be:  66 0e                bne.b    $89ce  ; -> L89ce
  0089c0:  20 6e 00 2c          movea.l  $2c(a6), a0
  0089c4:  30 2e ff ba          move.w   -$46(a6), d0
  0089c8:  b0 68 04 32          cmp.w    $432(a0), d0
  0089cc:  67 0c                beq.b    $89da  ; -> L89da
L89ce:
  0089ce:  70 01                moveq    #$1, d0
  0089d0:  2d 40 ff b6          move.l   d0, -$4a(a6)
  0089d4:  1d 7c 00 01 ff fd    move.b   #$1, -$3(a6)
L89da:
  0089da:  20 6e ff ae          movea.l  -$52(a6), a0
  0089de:  30 2e ff ba          move.w   -$46(a6), d0
  0089e2:  b0 68 04 32          cmp.w    $432(a0), d0
  0089e6:  66 22                bne.b    $8a0a  ; -> L8a0a
  0089e8:  30 2e ff ba          move.w   -$46(a6), d0
  0089ec:  48 c0                ext.l    d0
  0089ee:  2f 00                move.l   d0, -(a7)
  0089f0:  2f 2e ff aa          move.l   -$56(a6), -(a7)
  0089f4:  20 6e 00 30          movea.l  $30(a6), a0
  0089f8:  48 68 00 f0          pea.l    $f0(a0)
  0089fc:  61 ff ff ff fe 50    bsr.l    $884e  ; -> sub_884e
  008a02:  4a 00                tst.b    d0
  008a04:  4f ef 00 0c          lea.l    $c(a7), a7
  008a08:  66 1a                bne.b    $8a24  ; -> L8a24
L8a0a:
  008a0a:  00 87 00 00 00 01    ori.l    #$1, d7
  008a10:  70 01                moveq    #$1, d0
  008a12:  2d 40 ff b6          move.l   d0, -$4a(a6)
  008a16:  1d 7c 00 01 ff fd    move.b   #$1, -$3(a6)
  008a1c:  b9 ee ff aa          cmpa.l   -$56(a6), a4
  008a20:  66 02                bne.b    $8a24  ; -> L8a24
  008a22:  78 01                moveq    #$1, d4
L8a24:
  008a24:  20 6e ff ae          movea.l  -$52(a6), a0
  008a28:  0c 68 40 00 04 1c    cmpi.w   #$4000, $41c(a0)
  008a2e:  6d 2a                blt.b    $8a5a  ; -> L8a5a
  008a30:  76 00                moveq    #$0, d3
  008a32:  60 22                bra.b    $8a56  ; -> L8a56
L8a34:
  008a34:  1c 1b                move.b   (a3)+, d6
  008a36:  70 00                moveq    #$0, d0
  008a38:  10 06                move.b   d6, d0
  008a3a:  0c 00 00 84          cmpi.b   #$84, d0
  008a3e:  65 12                bcs.b    $8a52  ; -> L8a52
  008a40:  70 00                moveq    #$0, d0
  008a42:  10 06                move.b   d6, d0
  008a44:  0c 00 00 9e          cmpi.b   #$9e, d0
  008a48:  62 08                bhi.b    $8a52  ; -> L8a52
  008a4a:  00 87 00 00 00 08    ori.l    #$8, d7
  008a50:  60 08                bra.b    $8a5a  ; -> L8a5a
L8a52:
  008a52:  20 05                move.l   d5, d0
  008a54:  53 85                subq.l   #$1, d5
L8a56:
  008a56:  b6 85                cmp.l    d5, d3
  008a58:  6d da                blt.b    $8a34  ; -> L8a34
L8a5a:
  008a5a:  20 6e ff ae          movea.l  -$52(a6), a0
  008a5e:  26 68 04 00          movea.l  $400(a0), a3
  008a62:  2f 13                move.l   (a3), -(a7)
  008a64:  61 ff ff ff f7 72    bsr.l    $81d8  ; -> sub_81d8
  008a6a:  1d 40 ff ff          move.b   d0, -$1(a6)
  008a6e:  58 4f                addq.w   #$4, a7
  008a70:  67 1e                beq.b    $8a90  ; -> L8a90
  008a72:  2f 0b                move.l   a3, -(a7)
  008a74:  20 6e 00 30          movea.l  $30(a6), a0
  008a78:  48 68 00 c0          pea.l    $c0(a0)
  008a7c:  61 ff ff ff fd 4e    bsr.l    $87cc  ; -> sub_87cc
  008a82:  4a 00                tst.b    d0
  008a84:  50 4f                addq.w   #$8, a7
  008a86:  66 2e                bne.b    $8ab6  ; -> L8ab6
  008a88:  00 87 00 00 00 02    ori.l    #$2, d7
  008a8e:  60 26                bra.b    $8ab6  ; -> L8ab6
L8a90:
  008a90:  20 53                movea.l  (a3), a0
  008a92:  30 3c 08 00          move.w   #$800, d0
  008a96:  c0 50                and.w    (a0), d0
  008a98:  67 16                beq.b    $8ab0  ; -> L8ab0
  008a9a:  2f 0b                move.l   a3, -(a7)
  008a9c:  20 6e 00 30          movea.l  $30(a6), a0
  008aa0:  48 68 00 c0          pea.l    $c0(a0)
  008aa4:  61 ff ff ff fd 26    bsr.l    $87cc  ; -> sub_87cc
  008aaa:  4a 00                tst.b    d0
  008aac:  50 4f                addq.w   #$8, a7
  008aae:  66 06                bne.b    $8ab6  ; -> L8ab6
L8ab0:
  008ab0:  00 87 00 00 00 02    ori.l    #$2, d7
L8ab6:
  008ab6:  70 0a                moveq    #$a, d0
  008ab8:  c0 87                and.l    d7, d0
  008aba:  67 0c                beq.b    $8ac8  ; -> L8ac8
  008abc:  20 6e 00 2c          movea.l  $2c(a6), a0
  008ac0:  b7 e8 04 00          cmpa.l   $400(a0), a3
  008ac4:  66 02                bne.b    $8ac8  ; -> L8ac8
  008ac6:  78 01                moveq    #$1, d4
L8ac8:
  008ac8:  20 6e ff 9a          movea.l  -$66(a6), a0
  008acc:  20 68 00 1a          movea.l  $1a(a0), a0
  008ad0:  2d 48 ff a6          move.l   a0, -$5a(a6)
  008ad4:  28 68 00 02          movea.l  $2(a0), a4
  008ad8:  20 6e 00 24          movea.l  $24(a6), a0
  008adc:  2d 68 00 02 ff bc    move.l   $2(a0), -$44(a6)
  008ae2:  20 54                movea.l  (a4), a0
  008ae4:  30 3c 01 00          move.w   #$100, d0
  008ae8:  c0 50                and.w    (a0), d0
  008aea:  67 02                beq.b    $8aee  ; -> L8aee
  008aec:  28 4b                movea.l  a3, a4
L8aee:
  008aee:  b9 ee ff bc          cmpa.l   -$44(a6), a4
  008af2:  66 40                bne.b    $8b34  ; -> L8b34
  008af4:  2f 2e 00 24          move.l   $24(a6), -(a7)
  008af8:  2f 2e ff a6          move.l   -$5a(a6), -(a7)
  008afc:  61 ff ff ff f3 5a    bsr.l    $7e58  ; -> EqualFontOutput
  008b02:  4a 00                tst.b    d0
  008b04:  50 4f                addq.w   #$8, a7
  008b06:  67 2c                beq.b    $8b34  ; -> L8b34
  008b08:  41 ee 00 10          lea.l    $10(a6), a0
  008b0c:  22 6e 00 24          movea.l  $24(a6), a1
  008b10:  43 e9 00 12          lea.l    $12(a1), a1
  008b14:  70 00                moveq    #$0, d0
L8b16:
  008b16:  b1 89                cmpm.l   (a1)+, (a0)+
  008b18:  56 c8 ff fc          dbne     d0, $8b16  ; -> L8b16
  008b1c:  66 16                bne.b    $8b34  ; -> L8b34
  008b1e:  41 ee 00 14          lea.l    $14(a6), a0
  008b22:  22 6e 00 24          movea.l  $24(a6), a1
  008b26:  43 e9 00 16          lea.l    $16(a1), a1
  008b2a:  70 00                moveq    #$0, d0
L8b2c:
  008b2c:  b1 89                cmpm.l   (a1)+, (a0)+
  008b2e:  56 c8 ff fc          dbne     d0, $8b2c  ; -> L8b2c
  008b32:  67 0c                beq.b    $8b40  ; -> L8b40
L8b34:
  008b34:  70 01                moveq    #$1, d0
  008b36:  2d 40 ff b6          move.l   d0, -$4a(a6)
  008b3a:  1d 7c 00 01 ff fe    move.b   #$1, -$2(a6)
L8b40:
  008b40:  b7 cc                cmpa.l   a4, a3
  008b42:  67 60                beq.b    $8ba4  ; -> L8ba4
  008b44:  2f 14                move.l   (a4), -(a7)
  008b46:  61 ff ff ff f6 90    bsr.l    $81d8  ; -> sub_81d8
  008b4c:  1c 00                move.b   d0, d6
  008b4e:  58 4f                addq.w   #$4, a7
  008b50:  67 1e                beq.b    $8b70  ; -> L8b70
  008b52:  2f 0c                move.l   a4, -(a7)
  008b54:  20 6e 00 30          movea.l  $30(a6), a0
  008b58:  48 68 00 c0          pea.l    $c0(a0)
  008b5c:  61 ff ff ff fc 6e    bsr.l    $87cc  ; -> sub_87cc
  008b62:  4a 00                tst.b    d0
  008b64:  50 4f                addq.w   #$8, a7
  008b66:  66 3c                bne.b    $8ba4  ; -> L8ba4
  008b68:  00 87 00 00 00 04    ori.l    #$4, d7
  008b6e:  60 34                bra.b    $8ba4  ; -> L8ba4
L8b70:
  008b70:  20 54                movea.l  (a4), a0
  008b72:  30 3c 08 00          move.w   #$800, d0
  008b76:  c0 50                and.w    (a0), d0
  008b78:  67 16                beq.b    $8b90  ; -> L8b90
  008b7a:  2f 0c                move.l   a4, -(a7)
  008b7c:  20 6e 00 30          movea.l  $30(a6), a0
  008b80:  48 68 00 c0          pea.l    $c0(a0)
  008b84:  61 ff ff ff fc 46    bsr.l    $87cc  ; -> sub_87cc
  008b8a:  4a 00                tst.b    d0
  008b8c:  50 4f                addq.w   #$8, a7
  008b8e:  66 08                bne.b    $8b98  ; -> L8b98
L8b90:
  008b90:  00 87 00 00 00 04    ori.l    #$4, d7
  008b96:  60 0c                bra.b    $8ba4  ; -> L8ba4
L8b98:
  008b98:  70 08                moveq    #$8, d0
  008b9a:  c0 87                and.l    d7, d0
  008b9c:  67 06                beq.b    $8ba4  ; -> L8ba4
  008b9e:  00 87 00 00 00 10    ori.l    #$10, d7
L8ba4:
  008ba4:  70 14                moveq    #$14, d0
  008ba6:  c0 87                and.l    d7, d0
  008ba8:  67 08                beq.b    $8bb2  ; -> L8bb2
  008baa:  b9 ee ff bc          cmpa.l   -$44(a6), a4
  008bae:  66 02                bne.b    $8bb2  ; -> L8bb2
  008bb0:  78 01                moveq    #$1, d4
L8bb2:
  008bb2:  4a 87                tst.l    d7
  008bb4:  67 00 01 8c          beq.w    $8d42  ; -> L8d42
  008bb8:  4a 04                tst.b    d4
  008bba:  67 18                beq.b    $8bd4  ; -> L8bd4
  008bbc:  70 01                moveq    #$1, d0
  008bbe:  2f 00                move.l   d0, -(a7)
  008bc0:  72 00                moveq    #$0, d1
  008bc2:  2f 01                move.l   d1, -(a7)
  008bc4:  2f 01                move.l   d1, -(a7)
  008bc6:  70 38                moveq    #$38, d0
  008bc8:  2f 00                move.l   d0, -(a7)
  008bca:  61 ff ff ff bd f8    bsr.l    $49c4  ; -> EngineDispatch
  008bd0:  4f ef 00 10          lea.l    $10(a7), a7
L8bd4:
  008bd4:  7a 00                moveq    #$0, d5
  008bd6:  20 05                move.l   d5, d0
  008bd8:  52 85                addq.l   #$1, d5
  008bda:  e5 40                asl.w    #$2, d0
  008bdc:  2d 87 00 c0          move.l   d7, -$40(a6, d0.w)
  008be0:  08 07 00 00          btst.b   #$0, d7
  008be4:  67 26                beq.b    $8c0c  ; -> L8c0c
  008be6:  20 6e ff ae          movea.l  -$52(a6), a0
  008bea:  38 28 04 32          move.w   $432(a0), d4
  008bee:  31 6e ff ba 04 32    move.w   -$46(a6), $432(a0)
  008bf4:  20 05                move.l   d5, d0
  008bf6:  52 85                addq.l   #$1, d5
  008bf8:  e5 40                asl.w    #$2, d0
  008bfa:  2d ae ff aa 00 c0    move.l   -$56(a6), -$40(a6, d0.w)
  008c00:  20 05                move.l   d5, d0
  008c02:  52 85                addq.l   #$1, d5
  008c04:  e5 40                asl.w    #$2, d0
  008c06:  2d ae ff ae 00 c0    move.l   -$52(a6), -$40(a6, d0.w)
L8c0c:
  008c0c:  70 02                moveq    #$2, d0
  008c0e:  c0 87                and.l    d7, d0
  008c10:  67 38                beq.b    $8c4a  ; -> L8c4a
  008c12:  20 0b                move.l   a3, d0
  008c14:  67 2e                beq.b    $8c44  ; -> L8c44
  008c16:  4a 93                tst.l    (a3)
  008c18:  67 2a                beq.b    $8c44  ; -> L8c44
  008c1a:  20 05                move.l   d5, d0
  008c1c:  52 85                addq.l   #$1, d5
  008c1e:  e5 40                asl.w    #$2, d0
  008c20:  2d 8b 00 c0          move.l   a3, -$40(a6, d0.w)
  008c24:  20 05                move.l   d5, d0
  008c26:  52 85                addq.l   #$1, d5
  008c28:  e5 40                asl.w    #$2, d0
  008c2a:  2d 93 00 c0          move.l   (a3), -$40(a6, d0.w)
  008c2e:  59 8f                subq.l   #$4, a7
  008c30:  2f 0b                move.l   a3, -(a7)
  008c32:  61 ff 00 00 33 aa    bsr.l    $bfde  ; -> sub_bfde
  008c38:  20 05                move.l   d5, d0
  008c3a:  52 85                addq.l   #$1, d5
  008c3c:  e5 40                asl.w    #$2, d0
  008c3e:  2d 9f 00 c0          move.l   (a7)+, -$40(a6, d0.w)
  008c42:  60 30                bra.b    $8c74  ; -> L8c74
L8c44:
  008c44:  70 ff                moveq    #$ff, d0
  008c46:  60 00 01 52          bra.w    $8d9a  ; -> L8d9a
L8c4a:
  008c4a:  70 08                moveq    #$8, d0
  008c4c:  c0 87                and.l    d7, d0
  008c4e:  67 24                beq.b    $8c74  ; -> L8c74
  008c50:  20 0b                move.l   a3, d0
  008c52:  67 1a                beq.b    $8c6e  ; -> L8c6e
  008c54:  4a 93                tst.l    (a3)
  008c56:  67 16                beq.b    $8c6e  ; -> L8c6e
  008c58:  20 05                move.l   d5, d0
  008c5a:  52 85                addq.l   #$1, d5
  008c5c:  e5 40                asl.w    #$2, d0
  008c5e:  2d 8b 00 c0          move.l   a3, -$40(a6, d0.w)
  008c62:  20 05                move.l   d5, d0
  008c64:  52 85                addq.l   #$1, d5
  008c66:  e5 40                asl.w    #$2, d0
  008c68:  2d 93 00 c0          move.l   (a3), -$40(a6, d0.w)
  008c6c:  60 06                bra.b    $8c74  ; -> L8c74
L8c6e:
  008c6e:  70 ff                moveq    #$ff, d0
  008c70:  60 00 01 28          bra.w    $8d9a  ; -> L8d9a
L8c74:
  008c74:  70 04                moveq    #$4, d0
  008c76:  c0 87                and.l    d7, d0
  008c78:  67 38                beq.b    $8cb2  ; -> L8cb2
  008c7a:  20 0c                move.l   a4, d0
  008c7c:  67 2e                beq.b    $8cac  ; -> L8cac
  008c7e:  4a 94                tst.l    (a4)
  008c80:  67 2a                beq.b    $8cac  ; -> L8cac
  008c82:  20 05                move.l   d5, d0
  008c84:  52 85                addq.l   #$1, d5
  008c86:  e5 40                asl.w    #$2, d0
  008c88:  2d 8c 00 c0          move.l   a4, -$40(a6, d0.w)
  008c8c:  20 05                move.l   d5, d0
  008c8e:  52 85                addq.l   #$1, d5
  008c90:  e5 40                asl.w    #$2, d0
  008c92:  2d 94 00 c0          move.l   (a4), -$40(a6, d0.w)
  008c96:  59 8f                subq.l   #$4, a7
  008c98:  2f 0c                move.l   a4, -(a7)
  008c9a:  61 ff 00 00 33 42    bsr.l    $bfde  ; -> sub_bfde
  008ca0:  20 05                move.l   d5, d0
  008ca2:  52 85                addq.l   #$1, d5
  008ca4:  e5 40                asl.w    #$2, d0
  008ca6:  2d 9f 00 c0          move.l   (a7)+, -$40(a6, d0.w)
  008caa:  60 30                bra.b    $8cdc  ; -> L8cdc
L8cac:
  008cac:  70 ff                moveq    #$ff, d0
  008cae:  60 00 00 ea          bra.w    $8d9a  ; -> L8d9a
L8cb2:
  008cb2:  70 10                moveq    #$10, d0
  008cb4:  c0 87                and.l    d7, d0
  008cb6:  67 24                beq.b    $8cdc  ; -> L8cdc
  008cb8:  20 0c                move.l   a4, d0
  008cba:  67 1a                beq.b    $8cd6  ; -> L8cd6
  008cbc:  4a 94                tst.l    (a4)
  008cbe:  67 16                beq.b    $8cd6  ; -> L8cd6
  008cc0:  20 05                move.l   d5, d0
  008cc2:  52 85                addq.l   #$1, d5
  008cc4:  e5 40                asl.w    #$2, d0
  008cc6:  2d 8c 00 c0          move.l   a4, -$40(a6, d0.w)
  008cca:  20 05                move.l   d5, d0
  008ccc:  52 85                addq.l   #$1, d5
  008cce:  e5 40                asl.w    #$2, d0
  008cd0:  2d 94 00 c0          move.l   (a4), -$40(a6, d0.w)
  008cd4:  60 06                bra.b    $8cdc  ; -> L8cdc
L8cd6:
  008cd6:  70 ff                moveq    #$ff, d0
  008cd8:  60 00 00 c0          bra.w    $8d9a  ; -> L8d9a
L8cdc:
  008cdc:  70 01                moveq    #$1, d0
  008cde:  2f 00                move.l   d0, -(a7)
  008ce0:  2f 05                move.l   d5, -(a7)
  008ce2:  48 6e ff c0          pea.l    -$40(a6)
  008ce6:  72 30                moveq    #$30, d1
  008ce8:  2f 01                move.l   d1, -(a7)
  008cea:  61 ff ff ff bc d8    bsr.l    $49c4  ; -> EngineDispatch
  008cf0:  4a 80                tst.l    d0
  008cf2:  4f ef 00 10          lea.l    $10(a7), a7
  008cf6:  66 14                bne.b    $8d0c  ; -> L8d0c
  008cf8:  08 07 00 00          btst.b   #$0, d7
  008cfc:  67 08                beq.b    $8d06  ; -> L8d06
  008cfe:  20 6e ff ae          movea.l  -$52(a6), a0
  008d02:  31 44 04 32          move.w   d4, $432(a0)
L8d06:
  008d06:  70 ff                moveq    #$ff, d0
  008d08:  60 00 00 90          bra.w    $8d9a  ; -> L8d9a
L8d0c:
  008d0c:  70 02                moveq    #$2, d0
  008d0e:  c0 87                and.l    d7, d0
  008d10:  67 16                beq.b    $8d28  ; -> L8d28
  008d12:  4a 2e ff ff          tst.b    -$1(a6)
  008d16:  66 10                bne.b    $8d28  ; -> L8d28
  008d18:  4a 93                tst.l    (a3)
  008d1a:  67 08                beq.b    $8d24  ; -> L8d24
  008d1c:  20 53                movea.l  (a3), a0
  008d1e:  00 50 08 00          ori.w    #$800, (a0)
  008d22:  60 04                bra.b    $8d28  ; -> L8d28
L8d24:
  008d24:  70 ff                moveq    #$ff, d0
  008d26:  60 72                bra.b    $8d9a  ; -> L8d9a
L8d28:
  008d28:  70 04                moveq    #$4, d0
  008d2a:  c0 87                and.l    d7, d0
  008d2c:  67 14                beq.b    $8d42  ; -> L8d42
  008d2e:  4a 06                tst.b    d6
  008d30:  66 10                bne.b    $8d42  ; -> L8d42
  008d32:  4a 94                tst.l    (a4)
  008d34:  67 08                beq.b    $8d3e  ; -> L8d3e
  008d36:  20 54                movea.l  (a4), a0
  008d38:  00 50 08 00          ori.w    #$800, (a0)
  008d3c:  60 04                bra.b    $8d42  ; -> L8d42
L8d3e:
  008d3e:  70 ff                moveq    #$ff, d0
  008d40:  60 58                bra.b    $8d9a  ; -> L8d9a
L8d42:
  008d42:  4a 2e ff fd          tst.b    -$3(a6)
  008d46:  67 1a                beq.b    $8d62  ; -> L8d62
  008d48:  20 6e 00 28          movea.l  $28(a6), a0
  008d4c:  20 ae ff aa          move.l   -$56(a6), (a0)
  008d50:  20 6e ff ae          movea.l  -$52(a6), a0
  008d54:  22 6e 00 2c          movea.l  $2c(a6), a1
  008d58:  30 3c 01 0c          move.w   #$10c, d0
L8d5c:
  008d5c:  22 d8                move.l   (a0)+, (a1)+
  008d5e:  51 c8 ff fc          dbra     d0, $8d5c  ; -> L8d5c
L8d62:
  008d62:  4a 2e ff fe          tst.b    -$2(a6)
  008d66:  67 2e                beq.b    $8d96  ; -> L8d96
  008d68:  20 6e ff a6          movea.l  -$5a(a6), a0
  008d6c:  22 6e 00 24          movea.l  $24(a6), a1
  008d70:  70 05                moveq    #$5, d0
L8d72:
  008d72:  22 d8                move.l   (a0)+, (a1)+
  008d74:  51 c8 ff fc          dbra     d0, $8d72  ; -> L8d72
  008d78:  32 d8                move.w   (a0)+, (a1)+
  008d7a:  20 6e 00 24          movea.l  $24(a6), a0
  008d7e:  21 4c 00 02          move.l   a4, $2(a0)
  008d82:  20 6e 00 24          movea.l  $24(a6), a0
  008d86:  21 6e 00 10 00 12    move.l   $10(a6), $12(a0)
  008d8c:  20 6e 00 24          movea.l  $24(a6), a0
  008d90:  21 6e 00 14 00 16    move.l   $14(a6), $16(a0)
L8d96:
  008d96:  20 2e ff b6          move.l   -$4a(a6), d0
L8d9a:
  008d9a:  4c ee 18 f8 ff 7e    movem.l  -$82(a6), d3-d7/a3-a4
  008da0:  4e 5e                unlk     a6
  008da2:  4e 75                rts      
sub_8da4:
  008da4:  4e 56 00 00          link.w   a6, #$0
  008da8:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  008dac:  26 6e 00 0c          movea.l  $c(a6), a3
  008db0:  28 6e 00 08          movea.l  $8(a6), a4
  008db4:  2c 2c 00 30          move.l   $30(a4), d6
  008db8:  4a 6c 00 06          tst.w    $6(a4)
  008dbc:  6c 08                bge.b    $8dc6  ; -> L8dc6
  008dbe:  30 2c 00 0e          move.w   $e(a4), d0
  008dc2:  48 c0                ext.l    d0
  008dc4:  60 06                bra.b    $8dcc  ; -> L8dcc
L8dc6:
  008dc6:  20 3c 00 00 80 00    move.l   #$8000, d0
L8dcc:
  008dcc:  3e 00                move.w   d0, d7
  008dce:  bc 93                cmp.l    (a3), d6
  008dd0:  66 08                bne.b    $8dda  ; -> L8dda
  008dd2:  20 6e 00 10          movea.l  $10(a6), a0
  008dd6:  be 50                cmp.w    (a0), d7
  008dd8:  67 0c                beq.b    $8de6  ; -> L8de6
L8dda:
  008dda:  26 86                move.l   d6, (a3)
  008ddc:  20 6e 00 10          movea.l  $10(a6), a0
  008de0:  30 87                move.w   d7, (a0)
  008de2:  70 01                moveq    #$1, d0
  008de4:  60 02                bra.b    $8de8  ; -> L8de8
L8de6:
  008de6:  70 00                moveq    #$0, d0
L8de8:
  008de8:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  008dee:  4e 5e                unlk     a6
  008df0:  4e 75                rts      
sub_8df2:
  008df2:  4e 56 00 00          link.w   a6, #$0
  008df6:  48 e7 00 18          movem.l  a3-a4, -(a7)
  008dfa:  26 6e 00 08          movea.l  $8(a6), a3
  008dfe:  4a 6b 00 06          tst.w    $6(a3)
  008e02:  6c 1e                bge.b    $8e22  ; -> L8e22
  008e04:  20 6b 00 08          movea.l  $8(a3), a0
  008e08:  28 50                movea.l  (a0), a4
  008e0a:  20 6e 00 10          movea.l  $10(a6), a0
  008e0e:  22 4c                movea.l  a4, a1
  008e10:  20 d9                move.l   (a1)+, (a0)+
  008e12:  30 d9                move.w   (a1)+, (a0)+
  008e14:  20 6e 00 0c          movea.l  $c(a6), a0
  008e18:  22 4c                movea.l  a4, a1
  008e1a:  5c 89                addq.l   #$6, a1
  008e1c:  20 d9                move.l   (a1)+, (a0)+
  008e1e:  30 d9                move.w   (a1)+, (a0)+
  008e20:  60 0c                bra.b    $8e2e  ; -> L8e2e
L8e22:
  008e22:  20 6e 00 0c          movea.l  $c(a6), a0
  008e26:  43 f8 0d a0          lea.l    $da0.w, a1
  008e2a:  20 d9                move.l   (a1)+, (a0)+
  008e2c:  30 d9                move.w   (a1)+, (a0)+
L8e2e:
  008e2e:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  008e34:  4e 5e                unlk     a6
  008e36:  4e 75                rts      
sub_8e38:
  008e38:  4e 56 00 00          link.w   a6, #$0
  008e3c:  48 e7 01 08          movem.l  d7/a4, -(a7)
  008e40:  3e 2e 00 0a          move.w   $a(a6), d7
  008e44:  28 6e 00 14          movea.l  $14(a6), a4
  008e48:  4a 47                tst.w    d7
  008e4a:  57 c0                seq.b    d0
  008e4c:  44 00                neg.b    d0
  008e4e:  48 80                ext.w    d0
  008e50:  20 6e 00 10          movea.l  $10(a6), a0
  008e54:  30 80                move.w   d0, (a0)
  008e56:  30 07                move.w   d7, d0
  008e58:  6b 7e                bmi.b    $8ed8  ; -> L8ed8
  008e5a:  0c 40 00 05          cmpi.w   #$5, d0
  008e5e:  6e 78                bgt.b    $8ed8  ; -> L8ed8
  008e60:  d0 40                add.w    d0, d0
  008e62:  30 3b 00 06          move.w   $8e6a(pc, d0.w), d0
  008e66:  4e fb 00 00          jmp      $8e68(pc,d0.w)  ; -> L8e68
* jump table (word offsets relative to $8E68, indexed by selector*2):
  008e6a:  00 0e                dc.w     $000E    ; case 1 -> L8e76
  008e6c:  00 0e                dc.w     $000E    ; case 2 -> L8e76
  008e6e:  00 26                dc.w     $0026    ; case 3 -> L8e8e
  008e70:  00 2e                dc.w     $002E    ; case 4 -> L8e96
  008e72:  00 56                dc.w     $0056    ; case 5 -> L8ebe
  008e74:  00 5e                dc.w     $005E    ; case 6 -> L8ec6
L8e76:
  008e76:  61 ff ff ff f1 98    bsr.l    $8010  ; -> GetA5
  008e7c:  20 40 20 50 20 50 7e 08 dc.b     $20,$40,$20,$50,$20,$50,$7e,$08  ;  @ P P~.
  008e84:  8e 68 00 38          or.w     $38(a0), d7
  008e88:  38 bc 00 01          move.w   #$1, (a4)
  008e8c:  60 4a                bra.b    $8ed8  ; -> L8ed8
L8e8e:
  008e8e:  7e 08                moveq    #$8, d7
  008e90:  38 bc 00 02          move.w   #$2, (a4)
  008e94:  60 42                bra.b    $8ed8  ; -> L8ed8
L8e96:
  008e96:  7e 0a                moveq    #$a, d7
  008e98:  61 ff ff ff f1 76    bsr.l    $8010  ; -> GetA5
  008e9e:  20 40                movea.l  d0, a0
  008ea0:  20 10                move.l   (a0), d0
  008ea2:  90 bc 00 00 00 ca    sub.l    #$ca, d0
  008ea8:  20 40                movea.l  d0, a0
  008eaa:  48 68 00 ba          pea.l    $ba(a0)
  008eae:  70 00                moveq    #$0, d0
  008eb0:  3f 00                move.w   d0, -(a7)
  008eb2:  61 ff 00 00 0b d4    bsr.l    $9a88  ; -> sub_9a88
  008eb8:  38 bc 00 03          move.w   #$3, (a4)
  008ebc:  60 1a                bra.b    $8ed8  ; -> L8ed8
L8ebe:
  008ebe:  7e 08                moveq    #$8, d7
  008ec0:  38 bc 00 03          move.w   #$3, (a4)
  008ec4:  60 12                bra.b    $8ed8  ; -> L8ed8
L8ec6:
  008ec6:  61 ff ff ff f1 48    bsr.l    $8010  ; -> GetA5
  008ecc:  20 40 20 50 20 50 7e f7 dc.b     $20,$40,$20,$50,$20,$50,$7e,$f7  ;  @ P P~.
  008ed4:  ce 68 00 48          and.w    $48(a0), d7
L8ed8:
  008ed8:  4a 38 09 38          tst.b    $938.w
  008edc:  6d 16                blt.b    $8ef4  ; -> L8ef4
  008ede:  0c 47 00 0a          cmpi.w   #$a, d7
  008ee2:  66 02                bne.b    $8ee6  ; -> L8ee6
  008ee4:  7e 3a                moveq    #$3a, d7
L8ee6:
  008ee6:  0c 47 00 02          cmpi.w   #$2, d7
  008eea:  66 02                bne.b    $8eee  ; -> L8eee
  008eec:  7e 32                moveq    #$32, d7
L8eee:
  008eee:  00 38 00 80 09 38    ori.b    #$80, $938.w
L8ef4:
  008ef4:  20 6e 00 0c          movea.l  $c(a6), a0
  008ef8:  30 87                move.w   d7, (a0)
  008efa:  4c ee 10 80 ff f8    movem.l  -$8(a6), d7/a4
  008f00:  4e 5e                unlk     a6
  008f02:  4e 75                rts      
sub_8f04:
  008f04:  4e 56 ff c4          link.w   a6, #$ffc4
  008f08:  48 e7 17 18          movem.l  d3/d5-d7/a3-a4, -(a7)
  008f0c:  2c 2e 00 0c          move.l   $c(a6), d6
  008f10:  49 ee ff c8          lea.l    -$38(a6), a4
  008f14:  4a 86                tst.l    d6
  008f16:  66 06                bne.b    $8f1e  ; -> L8f1e
  008f18:  70 00                moveq    #$0, d0
  008f1a:  60 00 01 c8          bra.w    $90e4  ; -> L90e4
L8f1e:
  008f1e:  20 6e 00 08          movea.l  $8(a6), a0
  008f22:  4a 68 00 06          tst.w    $6(a0)
  008f26:  6c 00 01 84          bge.w    $90ac  ; -> L90ac
  008f2a:  20 06                move.l   d6, d0
  008f2c:  53 80                subq.l   #$1, d0
  008f2e:  67 0a                beq.b    $8f3a  ; -> L8f3a
  008f30:  53 80                subq.l   #$1, d0
  008f32:  67 10                beq.b    $8f44  ; -> L8f44
  008f34:  53 80                subq.l   #$1, d0
  008f36:  67 16                beq.b    $8f4e  ; -> L8f4e
  008f38:  60 1c                bra.b    $8f56  ; -> L8f56
L8f3a:
  008f3a:  20 6e 00 08          movea.l  $8(a6), a0
  008f3e:  26 68 00 3a          movea.l  $3a(a0), a3
  008f42:  60 12                bra.b    $8f56  ; -> L8f56
L8f44:
  008f44:  20 6e 00 08          movea.l  $8(a6), a0
  008f48:  26 68 00 20          movea.l  $20(a0), a3
  008f4c:  60 08                bra.b    $8f56  ; -> L8f56
L8f4e:
  008f4e:  20 6e 00 08          movea.l  $8(a6), a0
  008f52:  26 68 00 3e          movea.l  $3e(a0), a3
L8f56:
  008f56:  20 53                movea.l  (a3), a0
  008f58:  2d 48 ff c4          move.l   a0, -$3c(a6)
  008f5c:  30 10                move.w   (a0), d0
  008f5e:  48 c0                ext.l    d0
  008f60:  2e 00                move.l   d0, d7
  008f62:  66 0e                bne.b    $8f72  ; -> L8f72
  008f64:  20 68 00 06          movea.l  $6(a0), a0
  008f68:  22 6e 00 10          movea.l  $10(a6), a1
  008f6c:  22 90                move.l   (a0), (a1)
  008f6e:  60 00 01 70          bra.w    $90e0  ; -> L90e0
L8f72:
  008f72:  70 02                moveq    #$2, d0
  008f74:  b0 87                cmp.l    d7, d0
  008f76:  66 28                bne.b    $8fa0  ; -> L8fa0
  008f78:  20 6e ff c4          movea.l  -$3c(a6), a0
  008f7c:  20 68 00 02          movea.l  $2(a0), a0
  008f80:  20 50                movea.l  (a0), a0
  008f82:  2d 68 00 2a ff f4    move.l   $2a(a0), -$c(a6)
  008f88:  67 00 01 56          beq.w    $90e0  ; -> L90e0
  008f8c:  20 6e ff f4          movea.l  -$c(a6), a0
  008f90:  20 50                movea.l  (a0), a0
  008f92:  41 e8 00 2a          lea.l    $2a(a0), a0
  008f96:  22 6e 00 10          movea.l  $10(a6), a1
  008f9a:  22 88                move.l   a0, (a1)
  008f9c:  60 00 01 42          bra.w    $90e0  ; -> L90e0
L8fa0:
  008fa0:  20 78 08 88          movea.l  $888.w, a0
  008fa4:  20 50                movea.l  (a0), a0
  008fa6:  20 50                movea.l  (a0), a0
  008fa8:  20 68 02 14          movea.l  $214(a0), a0
  008fac:  20 50                movea.l  (a0), a0
  008fae:  2d 48 ff fc          move.l   a0, -$4(a6)
  008fb2:  3a 28 01 80          move.w   $180(a0), d5
  008fb6:  46 45                not.w    d5
  008fb8:  20 6e ff c4          movea.l  -$3c(a6), a0
  008fbc:  20 68 00 02          movea.l  $2(a0), a0
  008fc0:  20 50                movea.l  (a0), a0
  008fc2:  2d 48 ff f0          move.l   a0, -$10(a6)
  008fc6:  2d 68 00 2a ff f4    move.l   $2a(a0), -$c(a6)
  008fcc:  20 6e ff c4          movea.l  -$3c(a6), a0
  008fd0:  ba 68 00 0e          cmp.w    $e(a0), d5
  008fd4:  66 1c                bne.b    $8ff2  ; -> L8ff2
  008fd6:  2f 0b                move.l   a3, -(a7)
  008fd8:  20 6e ff fc          movea.l  -$4(a6), a0
  008fdc:  20 68 01 82          movea.l  $182(a0), a0
  008fe0:  48 68 00 78          pea.l    $78(a0)
  008fe4:  61 ff ff ff f7 e6    bsr.l    $87cc  ; -> sub_87cc
  008fea:  4a 00                tst.b    d0
  008fec:  50 4f                addq.w   #$8, a7
  008fee:  66 00 00 8c          bne.w    $907c  ; -> L907c
L8ff2:
  008ff2:  20 6e 00 10          movea.l  $10(a6), a0
  008ff6:  b7 d0                cmpa.l   (a0), a3
  008ff8:  66 18                bne.b    $9012  ; -> L9012
  008ffa:  70 01                moveq    #$1, d0
  008ffc:  2f 00                move.l   d0, -(a7)
  008ffe:  72 00                moveq    #$0, d1
  009000:  2f 01                move.l   d1, -(a7)
  009002:  2f 01                move.l   d1, -(a7)
  009004:  70 38                moveq    #$38, d0
  009006:  2f 00                move.l   d0, -(a7)
  009008:  61 ff ff ff b9 ba    bsr.l    $49c4  ; -> EngineDispatch
  00900e:  4f ef 00 10          lea.l    $10(a7), a7
L9012:
  009012:  28 8b                move.l   a3, (a4)
  009014:  29 47 00 04          move.l   d7, $4(a4)
  009018:  29 6e ff f0 00 08    move.l   -$10(a6), $8(a4)
  00901e:  20 6e ff c4          movea.l  -$3c(a6), a0
  009022:  20 68 00 06          movea.l  $6(a0), a0
  009026:  29 50 00 0c          move.l   (a0), $c(a4)
  00902a:  4a ae ff f4          tst.l    -$c(a6)
  00902e:  66 0c                bne.b    $903c  ; -> L903c
  009030:  70 00                moveq    #$0, d0
  009032:  29 40 00 10          move.l   d0, $10(a4)
  009036:  29 40 00 14          move.l   d0, $14(a4)
  00903a:  60 1a                bra.b    $9056  ; -> L9056
L903c:
  00903c:  20 6e ff f4          movea.l  -$c(a6), a0
  009040:  2d 50 ff f8          move.l   (a0), -$8(a6)
  009044:  20 6e ff f8          movea.l  -$8(a6), a0
  009048:  29 48 00 10          move.l   a0, $10(a4)
  00904c:  30 28 00 06          move.w   $6(a0), d0
  009050:  48 c0                ext.l    d0
  009052:  29 40 00 14          move.l   d0, $14(a4)
L9056:
  009056:  70 01                moveq    #$1, d0
  009058:  2f 00                move.l   d0, -(a7)
  00905a:  72 06                moveq    #$6, d1
  00905c:  2f 01                move.l   d1, -(a7)
  00905e:  2f 0c                move.l   a4, -(a7)
  009060:  70 0c                moveq    #$c, d0
  009062:  2f 00                move.l   d0, -(a7)
  009064:  61 ff ff ff b9 5e    bsr.l    $49c4  ; -> EngineDispatch
  00906a:  4a 80                tst.l    d0
  00906c:  4f ef 00 10          lea.l    $10(a7), a7
  009070:  66 04                bne.b    $9076  ; -> L9076
  009072:  70 ff                moveq    #$ff, d0
  009074:  60 6e                bra.b    $90e4  ; -> L90e4
L9076:
  009076:  20 53                movea.l  (a3), a0
  009078:  31 45 00 0e          move.w   d5, $e(a0)
L907c:
  00907c:  76 00                moveq    #$0, d3
  00907e:  4a ae ff f4          tst.l    -$c(a6)
  009082:  67 12                beq.b    $9096  ; -> L9096
  009084:  20 6e ff f4          movea.l  -$c(a6), a0
  009088:  20 50                movea.l  (a0), a0
  00908a:  30 3c 40 00          move.w   #$4000, d0
  00908e:  c0 68 00 04          and.w    $4(a0), d0
  009092:  67 02                beq.b    $9096  ; -> L9096
  009094:  76 01                moveq    #$1, d3
L9096:
  009096:  4a 03                tst.b    d3
  009098:  67 04                beq.b    $909e  ; -> L909e
  00909a:  70 03                moveq    #$3, d0
  00909c:  60 02                bra.b    $90a0  ; -> L90a0
L909e:
  00909e:  70 01                moveq    #$1, d0
L90a0:
  0090a0:  49 c0                extb.l   d0
  0090a2:  2e 00                move.l   d0, d7
  0090a4:  20 6e 00 10          movea.l  $10(a6), a0
  0090a8:  20 8b                move.l   a3, (a0)
  0090aa:  60 34                bra.b    $90e0  ; -> L90e0
L90ac:
  0090ac:  20 06                move.l   d6, d0
  0090ae:  53 80                subq.l   #$1, d0
  0090b0:  67 0a                beq.b    $90bc  ; -> L90bc
  0090b2:  53 80                subq.l   #$1, d0
  0090b4:  67 10                beq.b    $90c6  ; -> L90c6
  0090b6:  53 80                subq.l   #$1, d0
  0090b8:  67 16                beq.b    $90d0  ; -> L90d0
  0090ba:  60 1c                bra.b    $90d8  ; -> L90d8
L90bc:
  0090bc:  20 6e 00 08          movea.l  $8(a6), a0
  0090c0:  47 e8 00 3a          lea.l    $3a(a0), a3
  0090c4:  60 12                bra.b    $90d8  ; -> L90d8
L90c6:
  0090c6:  20 6e 00 08          movea.l  $8(a6), a0
  0090ca:  47 e8 00 20          lea.l    $20(a0), a3
  0090ce:  60 08                bra.b    $90d8  ; -> L90d8
L90d0:
  0090d0:  20 6e 00 08          movea.l  $8(a6), a0
  0090d4:  47 e8 00 28          lea.l    $28(a0), a3
L90d8:
  0090d8:  7e 00                moveq    #$0, d7
  0090da:  20 6e 00 10          movea.l  $10(a6), a0
  0090de:  20 8b                move.l   a3, (a0)
L90e0:
  0090e0:  20 07                move.l   d7, d0
  0090e2:  52 80                addq.l   #$1, d0
L90e4:
  0090e4:  4c ee 18 e8 ff ac    movem.l  -$54(a6), d3/d5-d7/a3-a4
  0090ea:  4e 5e                unlk     a6
  0090ec:  4e 75                rts      
sub_90ee:
  0090ee:  4e 56 00 00          link.w   a6, #$0
  0090f2:  48 e7 10 18          movem.l  d3/a3-a4, -(a7)
  0090f6:  26 6e 00 08          movea.l  $8(a6), a3
  0090fa:  20 2e 00 0c          move.l   $c(a6), d0
  0090fe:  53 80                subq.l   #$1, d0
  009100:  67 0a                beq.b    $910c  ; -> L910c
  009102:  53 80                subq.l   #$1, d0
  009104:  67 0e                beq.b    $9114  ; -> L9114
  009106:  53 80                subq.l   #$1, d0
  009108:  67 12                beq.b    $911c  ; -> L911c
  00910a:  60 18                bra.b    $9124  ; -> L9124
L910c:
  00910c:  20 6b 00 3a          movea.l  $3a(a3), a0
  009110:  28 50                movea.l  (a0), a4
  009112:  60 14                bra.b    $9128  ; -> L9128
L9114:
  009114:  20 6b 00 20          movea.l  $20(a3), a0
  009118:  28 50                movea.l  (a0), a4
  00911a:  60 0c                bra.b    $9128  ; -> L9128
L911c:
  00911c:  20 6b 00 3e          movea.l  $3e(a3), a0
  009120:  28 50                movea.l  (a0), a4
  009122:  60 04                bra.b    $9128  ; -> L9128
L9124:
  009124:  70 01                moveq    #$1, d0
  009126:  60 14                bra.b    $913c  ; -> L913c
L9128:
  009128:  76 01                moveq    #$1, d3
  00912a:  70 01                moveq    #$1, d0
  00912c:  c0 54                and.w    (a4), d0
  00912e:  67 0a                beq.b    $913a  ; -> L913a
  009130:  70 ff                moveq    #$ff, d0
  009132:  b0 6c 00 0e          cmp.w    $e(a4), d0
  009136:  66 02                bne.b    $913a  ; -> L913a
  009138:  76 00                moveq    #$0, d3
L913a:
  00913a:  10 03                move.b   d3, d0
L913c:
  00913c:  4c ee 18 08 ff f4    movem.l  -$c(a6), d3/a3-a4
  009142:  4e 5e                unlk     a6
  009144:  4e 75                rts      
sub_9146:
  009146:  4e 56 00 00          link.w   a6, #$0
  00914a:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00914e:  26 6e 00 08          movea.l  $8(a6), a3
  009152:  59 8f                subq.l   #$4, a7
  009154:  a8 d8                dc.w     $a8d8  ; _NewRgn
  009156:  28 5f                movea.l  (a7)+, a4
  009158:  2f 0b                move.l   a3, -(a7)
  00915a:  2f 0c                move.l   a4, -(a7)
  00915c:  a8 dc                dc.w     $a8dc  ; _CopyRgn
  00915e:  2f 0c                move.l   a4, -(a7)
  009160:  3f 2e 00 0e          move.w   $e(a6), -(a7)
  009164:  3f 2e 00 12          move.w   $12(a6), -(a7)
  009168:  a8 e1                dc.w     $a8e1  ; _InsetRgn
  00916a:  2f 0b                move.l   a3, -(a7)
  00916c:  2f 0c                move.l   a4, -(a7)
  00916e:  2f 0c                move.l   a4, -(a7)
  009170:  a8 e6                dc.w     $a8e6  ; _DiffRgn
  009172:  20 0c                move.l   a4, d0
  009174:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  00917a:  4e 5e                unlk     a6
  00917c:  4e 75                rts      
sub_917e:
  00917e:  4e 56 00 00          link.w   a6, #$0
  009182:  2f 07                move.l   d7, -(a7)
  009184:  2e 2e 00 08          move.l   $8(a6), d7
  009188:  70 01                moveq    #$1, d0
  00918a:  c0 87                and.l    d7, d0
  00918c:  66 06                bne.b    $9194  ; -> L9194
  00918e:  00 87 00 00 01 c0    ori.l    #$1c0, d7
L9194:
  009194:  20 07                move.l   d7, d0
  009196:  ec 80                asr.l    #$6, d0
  009198:  20 78 08 b0          movea.l  $8b0.w, a0
  00919c:  41 f0 0e 02          lea.l    $2(a0, d0.l), a0
  0091a0:  20 08                move.l   a0, d0
  0091a2:  2e 2e ff fc          move.l   -$4(a6), d7
  0091a6:  4e 5e                unlk     a6
  0091a8:  4e 75                rts      
sub_91aa:
  0091aa:  4e 56 ff ec          link.w   a6, #$ffec
  0091ae:  48 e7 13 18          movem.l  d3/d6-d7/a3-a4, -(a7)
  0091b2:  1c 2e 00 17          move.b   $17(a6), d6
  0091b6:  1e 2e 00 0f          move.b   $f(a6), d7
  0091ba:  26 6e 00 10          movea.l  $10(a6), a3
  0091be:  28 6e 00 08          movea.l  $8(a6), a4
  0091c2:  4a 07                tst.b    d7
  0091c4:  66 1e                bne.b    $91e4  ; -> L91e4
  0091c6:  4a 06                tst.b    d6
  0091c8:  66 1a                bne.b    $91e4  ; -> L91e4
  0091ca:  76 00                moveq    #$0, d3
  0091cc:  20 14                move.l   (a4), d0
  0091ce:  b0 93                cmp.l    (a3), d0
  0091d0:  66 0c                bne.b    $91de  ; -> L91de
  0091d2:  20 2c 00 04          move.l   $4(a4), d0
  0091d6:  b0 ab 00 04          cmp.l    $4(a3), d0
  0091da:  66 02                bne.b    $91de  ; -> L91de
  0091dc:  76 01                moveq    #$1, d3
L91de:
  0091de:  10 03                move.b   d3, d0
  0091e0:  60 00 00 8c          bra.w    $926e  ; -> L926e
L91e4:
  0091e4:  4a 07                tst.b    d7
  0091e6:  67 1a                beq.b    $9202  ; -> L9202
  0091e8:  4a 06                tst.b    d6
  0091ea:  67 16                beq.b    $9202  ; -> L9202
  0091ec:  2d 54 ff f8          move.l   (a4), -$8(a6)
  0091f0:  2d 53 ff fc          move.l   (a3), -$4(a6)
  0091f4:  20 2e ff f8          move.l   -$8(a6), d0
  0091f8:  b0 ae ff fc          cmp.l    -$4(a6), d0
  0091fc:  57 c0                seq.b    d0
  0091fe:  44 00                neg.b    d0
  009200:  60 6c                bra.b    $926e  ; -> L926e
L9202:
  009202:  4a 07                tst.b    d7
  009204:  67 22                beq.b    $9228  ; -> L9228
  009206:  2d 54 ff f8          move.l   (a4), -$8(a6)
  00920a:  66 04                bne.b    $9210  ; -> L9210
  00920c:  70 00                moveq    #$0, d0
  00920e:  60 5e                bra.b    $926e  ; -> L926e
L9210:
  009210:  20 6e ff f8          movea.l  -$8(a6), a0
  009214:  20 50                movea.l  (a0), a0
  009216:  2d 48 ff ec          move.l   a0, -$14(a6)
  00921a:  20 68 00 06          movea.l  $6(a0), a0
  00921e:  2d 50 ff f4          move.l   (a0), -$c(a6)
  009222:  2d 4b ff f0          move.l   a3, -$10(a6)
  009226:  60 20                bra.b    $9248  ; -> L9248
L9228:
  009228:  2d 53 ff fc          move.l   (a3), -$4(a6)
  00922c:  66 04                bne.b    $9232  ; -> L9232
  00922e:  70 00                moveq    #$0, d0
  009230:  60 3c                bra.b    $926e  ; -> L926e
L9232:
  009232:  20 6e ff fc          movea.l  -$4(a6), a0
  009236:  20 50                movea.l  (a0), a0
  009238:  2d 48 ff ec          move.l   a0, -$14(a6)
  00923c:  20 68 00 06          movea.l  $6(a0), a0
  009240:  2d 50 ff f4          move.l   (a0), -$c(a6)
  009244:  2d 4c ff f0          move.l   a4, -$10(a6)
L9248:
  009248:  76 00                moveq    #$0, d3
  00924a:  20 6e ff ec          movea.l  -$14(a6), a0
  00924e:  4a 50                tst.w    (a0)
  009250:  66 1a                bne.b    $926c  ; -> L926c
  009252:  20 6e ff f0          movea.l  -$10(a6), a0
  009256:  22 6e ff f4          movea.l  -$c(a6), a1
  00925a:  20 10                move.l   (a0), d0
  00925c:  b0 91                cmp.l    (a1), d0
  00925e:  66 0c                bne.b    $926c  ; -> L926c
  009260:  20 28 00 04          move.l   $4(a0), d0
  009264:  b0 a9 00 04          cmp.l    $4(a1), d0
  009268:  66 02                bne.b    $926c  ; -> L926c
  00926a:  76 01                moveq    #$1, d3
L926c:
  00926c:  10 03                move.b   d3, d0
L926e:
  00926e:  4c ee 18 c8 ff d8    movem.l  -$28(a6), d3/d6-d7/a3-a4
  009274:  4e 5e                unlk     a6
  009276:  4e 75                rts      
handler_10:
  009278:  4e 56 ff e0          link.w   a6, #$ffe0
  00927c:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  009280:  70 00                moveq    #$0, d0
  009282:  2f 00                move.l   d0, -(a7)
  009284:  61 ff ff ff dc 96    bsr.l    $6f1c  ; -> sub_6f1c
  00928a:  28 40                movea.l  d0, a4
  00928c:  61 ff ff ff ed 82    bsr.l    $8010  ; -> GetA5
  009292:  20 40                movea.l  d0, a0
  009294:  20 50                movea.l  (a0), a0
  009296:  b9 d0                cmpa.l   (a0), a4
  009298:  58 4f                addq.w   #$4, a7
  00929a:  66 00 00 f4          bne.w    $9390  ; -> L9390
  00929e:  7e 00                moveq    #$0, d7
  0092a0:  4a 6c 00 06          tst.w    $6(a4)
  0092a4:  6d 00 00 96          blt.w    $933c  ; -> L933c
  0092a8:  41 ec 00 3a          lea.l    $3a(a4), a0
  0092ac:  2d 48 ff e0          move.l   a0, -$20(a6)
  0092b0:  2d 50 ff e8          move.l   (a0), -$18(a6)
  0092b4:  2d 68 00 04 ff ec    move.l   $4(a0), -$14(a6)
  0092ba:  41 ec 00 20          lea.l    $20(a4), a0
  0092be:  2d 48 ff e4          move.l   a0, -$1c(a6)
  0092c2:  2d 50 ff f0          move.l   (a0), -$10(a6)
  0092c6:  2d 68 00 04 ff f4    move.l   $4(a0), -$c(a6)
  0092cc:  47 ec 00 28          lea.l    $28(a4), a3
  0092d0:  28 13                move.l   (a3), d4
  0092d2:  2a 2b 00 04          move.l   $4(a3), d5
  0092d6:  55 8f                subq.l   #$2, a7
  0092d8:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0092dc:  48 78 1c 68          pea.l    $1c68.w
  0092e0:  61 ff ff ff da b0    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0092e6:  58 8f                addq.l   #$4, a7
  0092e8:  2f 00                move.l   d0, -(a7)
  0092ea:  20 5f                movea.l  (a7)+, a0
  0092ec:  4e 90                jsr      (a0)
  0092ee:  1c 1f                move.b   (a7)+, d6
  0092f0:  20 6e ff e0          movea.l  -$20(a6), a0
  0092f4:  58 ae ff e0          addq.l   #$4, -$20(a6)
  0092f8:  20 10                move.l   (a0), d0
  0092fa:  b0 ae ff e8          cmp.l    -$18(a6), d0
  0092fe:  66 0c                bne.b    $930c  ; -> L930c
  009300:  20 6e ff e0          movea.l  -$20(a6), a0
  009304:  20 10                move.l   (a0), d0
  009306:  b0 ae ff ec          cmp.l    -$14(a6), d0
  00930a:  67 04                beq.b    $9310  ; -> L9310
L930c:
  00930c:  7e 01                moveq    #$1, d7
  00930e:  60 52                bra.b    $9362  ; -> L9362
L9310:
  009310:  20 6e ff e4          movea.l  -$1c(a6), a0
  009314:  58 ae ff e4          addq.l   #$4, -$1c(a6)
  009318:  20 10                move.l   (a0), d0
  00931a:  b0 ae ff f0          cmp.l    -$10(a6), d0
  00931e:  66 0c                bne.b    $932c  ; -> L932c
  009320:  20 6e ff e4          movea.l  -$1c(a6), a0
  009324:  20 10                move.l   (a0), d0
  009326:  b0 ae ff f4          cmp.l    -$c(a6), d0
  00932a:  67 04                beq.b    $9330  ; -> L9330
L932c:
  00932c:  7e 02                moveq    #$2, d7
  00932e:  60 32                bra.b    $9362  ; -> L9362
L9330:
  009330:  b8 9b                cmp.l    (a3)+, d4
  009332:  66 04                bne.b    $9338  ; -> L9338
  009334:  ba 93                cmp.l    (a3), d5
  009336:  67 2a                beq.b    $9362  ; -> L9362
L9338:
  009338:  7e 03                moveq    #$3, d7
  00933a:  60 26                bra.b    $9362  ; -> L9362
L933c:
  00933c:  26 6c 00 3e          movea.l  $3e(a4), a3
  009340:  55 8f                subq.l   #$2, a7
  009342:  2f 2e 00 08          move.l   $8(a6), -(a7)
  009346:  48 78 1c 68          pea.l    $1c68.w
  00934a:  61 ff ff ff da 46    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009350:  58 8f                addq.l   #$4, a7
  009352:  2f 00                move.l   d0, -(a7)
  009354:  20 5f                movea.l  (a7)+, a0
  009356:  4e 90                jsr      (a0)
  009358:  1c 1f                move.b   (a7)+, d6
  00935a:  b7 ec 00 3e          cmpa.l   $3e(a4), a3
  00935e:  67 02                beq.b    $9362  ; -> L9362
  009360:  7e 03                moveq    #$3, d7
L9362:
  009362:  4a 87                tst.l    d7
  009364:  67 24                beq.b    $938a  ; -> L938a
  009366:  70 00                moveq    #$0, d0
  009368:  2d 40 ff f8          move.l   d0, -$8(a6)
  00936c:  2d 47 ff fc          move.l   d7, -$4(a6)
  009370:  70 01                moveq    #$1, d0
  009372:  2f 00                move.l   d0, -(a7)
  009374:  72 02                moveq    #$2, d1
  009376:  2f 01                move.l   d1, -(a7)
  009378:  48 6e ff f8          pea.l    -$8(a6)
  00937c:  70 2a                moveq    #$2a, d0
  00937e:  2f 00                move.l   d0, -(a7)
  009380:  61 ff ff ff b6 42    bsr.l    $49c4  ; -> EngineDispatch
  009386:  4f ef 00 10          lea.l    $10(a7), a7
L938a:
  00938a:  1d 46 00 0c          move.b   d6, $c(a6)
  00938e:  60 1c                bra.b    $93ac  ; -> L93ac
L9390:
  009390:  55 8f                subq.l   #$2, a7
  009392:  2f 2e 00 08          move.l   $8(a6), -(a7)
  009396:  48 78 1c 68          pea.l    $1c68.w
  00939a:  61 ff ff ff d9 f6    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0093a0:  58 8f                addq.l   #$4, a7
  0093a2:  2f 00                move.l   d0, -(a7)
  0093a4:  20 5f                movea.l  (a7)+, a0
  0093a6:  4e 90                jsr      (a0)
  0093a8:  1d 5f 00 0c          move.b   (a7)+, $c(a6)
L93ac:
  0093ac:  4c ee 18 f0 ff c8    movem.l  -$38(a6), d4-d7/a3-a4
  0093b2:  4e 5e                unlk     a6
  0093b4:  4e 74 00 04          rtd      #$4
handler_90:
  0093b8:  4e 56 00 00          link.w   a6, #$0
  0093bc:  70 01                moveq    #$1, d0
  0093be:  2f 00                move.l   d0, -(a7)
  0093c0:  72 00                moveq    #$0, d1
  0093c2:  2f 01                move.l   d1, -(a7)
  0093c4:  2f 01                move.l   d1, -(a7)
  0093c6:  70 26                moveq    #$26, d0
  0093c8:  2f 00                move.l   d0, -(a7)
  0093ca:  61 ff ff ff b5 f8    bsr.l    $49c4  ; -> EngineDispatch
  0093d0:  2f 2e 00 0e          move.l   $e(a6), -(a7)
  0093d4:  2f 2e 00 0a          move.l   $a(a6), -(a7)
  0093d8:  3f 2e 00 08          move.w   $8(a6), -(a7)
  0093dc:  48 78 18 54          pea.l    $1854.w
  0093e0:  61 ff ff ff d9 b0    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0093e6:  58 8f                addq.l   #$4, a7
  0093e8:  2f 00                move.l   d0, -(a7)
  0093ea:  20 5f                movea.l  (a7)+, a0
  0093ec:  4e 90                jsr      (a0)
  0093ee:  4e 5e                unlk     a6
  0093f0:  4e 74 00 0a          rtd      #$a
handler_89:
  0093f4:  4e 56 00 00          link.w   a6, #$0
  0093f8:  70 01                moveq    #$1, d0
  0093fa:  2f 00                move.l   d0, -(a7)
  0093fc:  72 00                moveq    #$0, d1
  0093fe:  2f 01                move.l   d1, -(a7)
  009400:  2f 01                move.l   d1, -(a7)
  009402:  70 26                moveq    #$26, d0
  009404:  2f 00                move.l   d0, -(a7)
  009406:  61 ff ff ff b5 bc    bsr.l    $49c4  ; -> EngineDispatch
  00940c:  2f 2e 00 08          move.l   $8(a6), -(a7)
  009410:  48 78 18 50          pea.l    $1850.w
  009414:  61 ff ff ff d9 7c    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00941a:  58 8f                addq.l   #$4, a7
  00941c:  2f 00                move.l   d0, -(a7)
  00941e:  20 5f                movea.l  (a7)+, a0
  009420:  4e 90                jsr      (a0)
  009422:  4e 5e                unlk     a6
  009424:  4e 74 00 04          rtd      #$4
handler_91:
  009428:  4e 56 00 00          link.w   a6, #$0
  00942c:  70 01                moveq    #$1, d0
  00942e:  2f 00                move.l   d0, -(a7)
  009430:  72 00                moveq    #$0, d1
  009432:  2f 01                move.l   d1, -(a7)
  009434:  2f 01                move.l   d1, -(a7)
  009436:  70 26                moveq    #$26, d0
  009438:  2f 00                move.l   d0, -(a7)
  00943a:  61 ff ff ff b5 88    bsr.l    $49c4  ; -> EngineDispatch
  009440:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  009444:  2f 2e 00 08          move.l   $8(a6), -(a7)
  009448:  48 78 18 80          pea.l    $1880.w
  00944c:  61 ff ff ff d9 44    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009452:  58 8f                addq.l   #$4, a7
  009454:  2f 00                move.l   d0, -(a7)
  009456:  20 5f                movea.l  (a7)+, a0
  009458:  4e 90                jsr      (a0)
  00945a:  4e 5e                unlk     a6
  00945c:  4e 74 00 08          rtd      #$8
handler_92:
  009460:  4e 56 ff fc          link.w   a6, #$fffc
  009464:  2f 0c                move.l   a4, -(a7)
  009466:  28 6e 00 0a          movea.l  $a(a6), a4
  00946a:  2f 2e 00 0e          move.l   $e(a6), -(a7)
  00946e:  2f 0c                move.l   a4, -(a7)
  009470:  3f 2e 00 08          move.w   $8(a6), -(a7)
  009474:  48 78 16 e4          pea.l    $16e4.w
  009478:  61 ff ff ff d9 18    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00947e:  58 8f                addq.l   #$4, a7
  009480:  2f 00                move.l   d0, -(a7)
  009482:  20 5f                movea.l  (a7)+, a0
  009484:  4e 90                jsr      (a0)
  009486:  20 78 08 88          movea.l  $888.w, a0
  00948a:  4a a8 00 3c          tst.l    $3c(a0)
  00948e:  66 2c                bne.b    $94bc  ; -> L94bc
  009490:  20 0c                move.l   a4, d0
  009492:  66 0a                bne.b    $949e  ; -> L949e
  009494:  20 78 0c c8          movea.l  $cc8.w, a0
  009498:  20 50                movea.l  (a0), a0
  00949a:  28 68 00 06          movea.l  $6(a0), a4
L949e:
  00949e:  20 54                movea.l  (a4), a0
  0094a0:  2d 50 ff fc          move.l   (a0), -$4(a6)
  0094a4:  70 01                moveq    #$1, d0
  0094a6:  2f 00                move.l   d0, -(a7)
  0094a8:  2f 00                move.l   d0, -(a7)
  0094aa:  48 6e ff fc          pea.l    -$4(a6)
  0094ae:  72 1b                moveq    #$1b, d1
  0094b0:  2f 01                move.l   d1, -(a7)
  0094b2:  61 ff ff ff b5 10    bsr.l    $49c4  ; -> EngineDispatch
  0094b8:  4f ef 00 10          lea.l    $10(a7), a7
L94bc:
  0094bc:  28 6e ff f8          movea.l  -$8(a6), a4
  0094c0:  4e 5e                unlk     a6
  0094c2:  4e 74 00 0a          rtd      #$a
handler_84:
  0094c6:  4e 56 00 00          link.w   a6, #$0
  0094ca:  2f 2e 00 10          move.l   $10(a6), -(a7)
  0094ce:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  0094d2:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0094d6:  48 78 17 24          pea.l    $1724.w
  0094da:  61 ff ff ff d8 b6    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0094e0:  58 8f                addq.l   #$4, a7
  0094e2:  2f 00                move.l   d0, -(a7)
  0094e4:  20 5f                movea.l  (a7)+, a0
  0094e6:  4e 90                jsr      (a0)
  0094e8:  4a ae 00 0c          tst.l    $c(a6)
  0094ec:  66 12                bne.b    $9500  ; -> L9500
  0094ee:  20 78 0c c8          movea.l  $cc8.w, a0
  0094f2:  20 50                movea.l  (a0), a0
  0094f4:  20 68 00 16          movea.l  $16(a0), a0
  0094f8:  20 50                movea.l  (a0), a0
  0094fa:  2d 68 00 2a 00 0c    move.l   $2a(a0), $c(a6)
L9500:
  009500:  70 01                moveq    #$1, d0
  009502:  2f 00                move.l   d0, -(a7)
  009504:  2f 00                move.l   d0, -(a7)
  009506:  48 6e 00 0c          pea.l    $c(a6)
  00950a:  72 1a                moveq    #$1a, d1
  00950c:  2f 01                move.l   d1, -(a7)
  00950e:  61 ff ff ff b4 b4    bsr.l    $49c4  ; -> EngineDispatch
  009514:  4e 5e                unlk     a6
  009516:  4e 74 00 0c          rtd      #$c
handler_85:
  00951a:  4e 56 00 00          link.w   a6, #$0
  00951e:  2f 2e 00 10          move.l   $10(a6), -(a7)
  009522:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  009526:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00952a:  48 78 17 28          pea.l    $1728.w
  00952e:  61 ff ff ff d8 62    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009534:  58 8f                addq.l   #$4, a7
  009536:  2f 00                move.l   d0, -(a7)
  009538:  20 5f                movea.l  (a7)+, a0
  00953a:  4e 90                jsr      (a0)
  00953c:  4a ae 00 0c          tst.l    $c(a6)
  009540:  66 12                bne.b    $9554  ; -> L9554
  009542:  20 78 0c c8          movea.l  $cc8.w, a0
  009546:  20 50                movea.l  (a0), a0
  009548:  20 68 00 16          movea.l  $16(a0), a0
  00954c:  20 50                movea.l  (a0), a0
  00954e:  2d 68 00 2a 00 0c    move.l   $2a(a0), $c(a6)
L9554:
  009554:  70 01                moveq    #$1, d0
  009556:  2f 00                move.l   d0, -(a7)
  009558:  2f 00                move.l   d0, -(a7)
  00955a:  48 6e 00 0c          pea.l    $c(a6)
  00955e:  72 1a                moveq    #$1a, d1
  009560:  2f 01                move.l   d1, -(a7)
  009562:  61 ff ff ff b4 60    bsr.l    $49c4  ; -> EngineDispatch
  009568:  4e 5e                unlk     a6
  00956a:  4e 74 00 0c          rtd      #$c
handler_86:
  00956e:  4e 56 00 00          link.w   a6, #$0
  009572:  2f 2e 00 0e          move.l   $e(a6), -(a7)
  009576:  3f 2e 00 0c          move.w   $c(a6), -(a7)
  00957a:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00957e:  48 78 16 dc          pea.l    $16dc.w
  009582:  61 ff ff ff d8 0e    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009588:  58 8f                addq.l   #$4, a7
  00958a:  2f 00                move.l   d0, -(a7)
  00958c:  20 5f                movea.l  (a7)+, a0
  00958e:  4e 90                jsr      (a0)
  009590:  4a ae 00 08          tst.l    $8(a6)
  009594:  66 12                bne.b    $95a8  ; -> L95a8
  009596:  20 78 0c c8          movea.l  $cc8.w, a0
  00959a:  20 50                movea.l  (a0), a0
  00959c:  20 68 00 16          movea.l  $16(a0), a0
  0095a0:  20 50                movea.l  (a0), a0
  0095a2:  2d 68 00 2a 00 08    move.l   $2a(a0), $8(a6)
L95a8:
  0095a8:  70 01                moveq    #$1, d0
  0095aa:  2f 00                move.l   d0, -(a7)
  0095ac:  2f 00                move.l   d0, -(a7)
  0095ae:  48 6e 00 08          pea.l    $8(a6)
  0095b2:  72 1a                moveq    #$1a, d1
  0095b4:  2f 01                move.l   d1, -(a7)
  0095b6:  61 ff ff ff b4 0c    bsr.l    $49c4  ; -> EngineDispatch
  0095bc:  4e 5e                unlk     a6
  0095be:  4e 74 00 0a          rtd      #$a
handler_77:
  0095c2:  4e 56 ff fc          link.w   a6, #$fffc
  0095c6:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  0095ca:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0095ce:  48 78 16 fc          pea.l    $16fc.w
  0095d2:  61 ff ff ff d7 be    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0095d8:  58 8f                addq.l   #$4, a7
  0095da:  2f 00                move.l   d0, -(a7)
  0095dc:  20 5f                movea.l  (a7)+, a0
  0095de:  4e 90                jsr      (a0)
  0095e0:  20 78 08 88          movea.l  $888.w, a0
  0095e4:  20 50                movea.l  (a0), a0
  0095e6:  20 50                movea.l  (a0), a0
  0095e8:  20 68 02 14          movea.l  $214(a0), a0
  0095ec:  20 50                movea.l  (a0), a0
  0095ee:  2d 68 01 8e ff fc    move.l   $18e(a0), -$4(a6)
  0095f4:  67 18                beq.b    $960e  ; -> L960e
  0095f6:  70 01                moveq    #$1, d0
  0095f8:  2f 00                move.l   d0, -(a7)
  0095fa:  2f 00                move.l   d0, -(a7)
  0095fc:  48 6e ff fc          pea.l    -$4(a6)
  009600:  72 29                moveq    #$29, d1
  009602:  2f 01                move.l   d1, -(a7)
  009604:  61 ff ff ff b3 be    bsr.l    $49c4  ; -> EngineDispatch
  00960a:  4f ef 00 10          lea.l    $10(a7), a7
L960e:
  00960e:  70 01                moveq    #$1, d0
  009610:  2f 00                move.l   d0, -(a7)
  009612:  2f 00                move.l   d0, -(a7)
  009614:  20 78 0c c8          movea.l  $cc8.w, a0
  009618:  20 50                movea.l  (a0), a0
  00961a:  20 68 00 16          movea.l  $16(a0), a0
  00961e:  20 50                movea.l  (a0), a0
  009620:  48 68 00 2a          pea.l    $2a(a0)
  009624:  72 1a                moveq    #$1a, d1
  009626:  2f 01                move.l   d1, -(a7)
  009628:  61 ff ff ff b3 9a    bsr.l    $49c4  ; -> EngineDispatch
  00962e:  4e 5e                unlk     a6
  009630:  4e 74 00 08          rtd      #$8
handler_73:
  009634:  4e 56 00 00          link.w   a6, #$0
  009638:  70 01                moveq    #$1, d0
  00963a:  2f 00                move.l   d0, -(a7)
  00963c:  72 00                moveq    #$0, d1
  00963e:  2f 01                move.l   d1, -(a7)
  009640:  2f 01                move.l   d1, -(a7)
  009642:  70 26                moveq    #$26, d0
  009644:  2f 00                move.l   d0, -(a7)
  009646:  61 ff ff ff b3 7c    bsr.l    $49c4  ; -> EngineDispatch
  00964c:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  009650:  3f 2e 00 0a          move.w   $a(a6), -(a7)
  009654:  1f 2e 00 08          move.b   $8(a6), -(a7)
  009658:  48 78 16 b4          pea.l    $16b4.w
  00965c:  61 ff ff ff d7 34    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009662:  58 8f                addq.l   #$4, a7
  009664:  2f 00                move.l   d0, -(a7)
  009666:  20 5f                movea.l  (a7)+, a0
  009668:  4e 90                jsr      (a0)
  00966a:  70 01                moveq    #$1, d0
  00966c:  2f 00                move.l   d0, -(a7)
  00966e:  2f 00                move.l   d0, -(a7)
  009670:  48 6e 00 0c          pea.l    $c(a6)
  009674:  72 29                moveq    #$29, d1
  009676:  2f 01                move.l   d1, -(a7)
  009678:  61 ff ff ff b3 4a    bsr.l    $49c4  ; -> EngineDispatch
  00967e:  4e 5e                unlk     a6
  009680:  4e 74 00 08          rtd      #$8
handler_74:
  009684:  4e 56 00 00          link.w   a6, #$0
  009688:  70 01                moveq    #$1, d0
  00968a:  2f 00                move.l   d0, -(a7)
  00968c:  2f 00                move.l   d0, -(a7)
  00968e:  48 6e 00 08          pea.l    $8(a6)
  009692:  72 2b                moveq    #$2b, d1
  009694:  2f 01                move.l   d1, -(a7)
  009696:  61 ff ff ff b3 2c    bsr.l    $49c4  ; -> EngineDispatch
  00969c:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0096a0:  48 78 16 c0          pea.l    $16c0.w
  0096a4:  61 ff ff ff d6 ec    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0096aa:  58 8f                addq.l   #$4, a7
  0096ac:  2f 00                move.l   d0, -(a7)
  0096ae:  20 5f                movea.l  (a7)+, a0
  0096b0:  4e 90                jsr      (a0)
  0096b2:  4e 5e                unlk     a6
  0096b4:  4e 74 00 04          rtd      #$4
handler_25:
  0096b8:  4e 56 ff fc          link.w   a6, #$fffc
  0096bc:  2d 78 0c c8 ff fc    move.l   $cc8.w, -$4(a6)
  0096c2:  70 01                moveq    #$1, d0
  0096c4:  2f 00                move.l   d0, -(a7)
  0096c6:  72 00                moveq    #$0, d1
  0096c8:  2f 01                move.l   d1, -(a7)
  0096ca:  2f 01                move.l   d1, -(a7)
  0096cc:  70 26                moveq    #$26, d0
  0096ce:  2f 00                move.l   d0, -(a7)
  0096d0:  61 ff ff ff b2 f2    bsr.l    $49c4  ; -> EngineDispatch
  0096d6:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0096da:  48 78 16 e8          pea.l    $16e8.w
  0096de:  61 ff ff ff d6 b2    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0096e4:  58 8f                addq.l   #$4, a7
  0096e6:  2f 00                move.l   d0, -(a7)
  0096e8:  20 5f                movea.l  (a7)+, a0
  0096ea:  4e 90                jsr      (a0)
  0096ec:  70 01                moveq    #$1, d0
  0096ee:  2f 00                move.l   d0, -(a7)
  0096f0:  2f 00                move.l   d0, -(a7)
  0096f2:  48 6e ff fc          pea.l    -$4(a6)
  0096f6:  72 29                moveq    #$29, d1
  0096f8:  2f 01                move.l   d1, -(a7)
  0096fa:  61 ff ff ff b2 c8    bsr.l    $49c4  ; -> EngineDispatch
  009700:  4e 5e                unlk     a6
  009702:  4e 74 00 04          rtd      #$4
handler_99:
  009706:  4e 56 00 00          link.w   a6, #$0
  00970a:  2f 0c                move.l   a4, -(a7)
  00970c:  20 78 08 88          movea.l  $888.w, a0
  009710:  20 50                movea.l  (a0), a0
  009712:  20 50                movea.l  (a0), a0
  009714:  20 68 02 14          movea.l  $214(a0), a0
  009718:  28 50                movea.l  (a0), a4
  00971a:  29 6e 00 08 01 8e    move.l   $8(a6), $18e(a4)
  009720:  70 01                moveq    #$1, d0
  009722:  2f 00                move.l   d0, -(a7)
  009724:  72 00                moveq    #$0, d1
  009726:  2f 01                move.l   d1, -(a7)
  009728:  2f 01                move.l   d1, -(a7)
  00972a:  70 26                moveq    #$26, d0
  00972c:  2f 00                move.l   d0, -(a7)
  00972e:  61 ff ff ff b2 94    bsr.l    $49c4  ; -> EngineDispatch
  009734:  70 01                moveq    #$1, d0
  009736:  2f 00                move.l   d0, -(a7)
  009738:  2f 00                move.l   d0, -(a7)
  00973a:  48 6e 00 08          pea.l    $8(a6)
  00973e:  72 29                moveq    #$29, d1
  009740:  2f 01                move.l   d1, -(a7)
  009742:  61 ff ff ff b2 80    bsr.l    $49c4  ; -> EngineDispatch
  009748:  a8 52                dc.w     $a852  ; _HideCursor
  00974a:  3f 2e 00 10          move.w   $10(a6), -(a7)
  00974e:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  009752:  2f 2e 00 08          move.l   $8(a6), -(a7)
  009756:  48 78 16 b8          pea.l    $16b8.w
  00975a:  61 ff ff ff d6 36    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009760:  58 8f                addq.l   #$4, a7
  009762:  2f 00                move.l   d0, -(a7)
  009764:  20 5f                movea.l  (a7)+, a0
  009766:  4e 90                jsr      (a0)
  009768:  a8 53                dc.w     $a853  ; _ShowCursor
  00976a:  61 ff ff ff e0 3a    bsr.l    $77a6  ; -> sub_77a6
  009770:  70 01                moveq    #$1, d0
  009772:  2f 00                move.l   d0, -(a7)
  009774:  2f 00                move.l   d0, -(a7)
  009776:  48 6e 00 08          pea.l    $8(a6)
  00977a:  72 29                moveq    #$29, d1
  00977c:  2f 01                move.l   d1, -(a7)
  00977e:  61 ff ff ff b2 44    bsr.l    $49c4  ; -> EngineDispatch
  009784:  70 00                moveq    #$0, d0
  009786:  29 40 01 8e          move.l   d0, $18e(a4)
  00978a:  28 6e ff fc          movea.l  -$4(a6), a4
  00978e:  4e 5e                unlk     a6
  009790:  4e 74 00 0a          rtd      #$a
handler_26:
  009794:  4e 56 ff fc          link.w   a6, #$fffc
  009798:  2d 78 0c c8 ff fc    move.l   $cc8.w, -$4(a6)
  00979e:  70 01                moveq    #$1, d0
  0097a0:  2f 00                move.l   d0, -(a7)
  0097a2:  72 00                moveq    #$0, d1
  0097a4:  2f 01                move.l   d1, -(a7)
  0097a6:  2f 01                move.l   d1, -(a7)
  0097a8:  70 26                moveq    #$26, d0
  0097aa:  2f 00                move.l   d0, -(a7)
  0097ac:  61 ff ff ff b2 16    bsr.l    $49c4  ; -> EngineDispatch
  0097b2:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0097b6:  48 78 17 30          pea.l    $1730.w
  0097ba:  61 ff ff ff d5 d6    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0097c0:  58 8f                addq.l   #$4, a7
  0097c2:  2f 00                move.l   d0, -(a7)
  0097c4:  20 5f                movea.l  (a7)+, a0
  0097c6:  4e 90                jsr      (a0)
  0097c8:  70 01                moveq    #$1, d0
  0097ca:  2f 00                move.l   d0, -(a7)
  0097cc:  2f 00                move.l   d0, -(a7)
  0097ce:  48 6e ff fc          pea.l    -$4(a6)
  0097d2:  72 29                moveq    #$29, d1
  0097d4:  2f 01                move.l   d1, -(a7)
  0097d6:  61 ff ff ff b1 ec    bsr.l    $49c4  ; -> EngineDispatch
  0097dc:  4e 5e                unlk     a6
  0097de:  4e 74 00 04          rtd      #$4
handler_27:
  0097e2:  4e 56 ff fc          link.w   a6, #$fffc
  0097e6:  2d 78 0c c8 ff fc    move.l   $cc8.w, -$4(a6)
  0097ec:  70 01                moveq    #$1, d0
  0097ee:  2f 00                move.l   d0, -(a7)
  0097f0:  72 00                moveq    #$0, d1
  0097f2:  2f 01                move.l   d1, -(a7)
  0097f4:  2f 01                move.l   d1, -(a7)
  0097f6:  70 26                moveq    #$26, d0
  0097f8:  2f 00                move.l   d0, -(a7)
  0097fa:  61 ff ff ff b1 c8    bsr.l    $49c4  ; -> EngineDispatch
  009800:  2f 2e 00 08          move.l   $8(a6), -(a7)
  009804:  48 78 16 ec          pea.l    $16ec.w
  009808:  61 ff ff ff d5 88    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00980e:  58 8f                addq.l   #$4, a7
  009810:  2f 00                move.l   d0, -(a7)
  009812:  20 5f                movea.l  (a7)+, a0
  009814:  4e 90                jsr      (a0)
  009816:  70 01                moveq    #$1, d0
  009818:  2f 00                move.l   d0, -(a7)
  00981a:  2f 00                move.l   d0, -(a7)
  00981c:  48 6e ff fc          pea.l    -$4(a6)
  009820:  72 29                moveq    #$29, d1
  009822:  2f 01                move.l   d1, -(a7)
  009824:  61 ff ff ff b1 9e    bsr.l    $49c4  ; -> EngineDispatch
  00982a:  4e 5e                unlk     a6
  00982c:  4e 74 00 04          rtd      #$4
handler_28:
  009830:  4e 56 ff fc          link.w   a6, #$fffc
  009834:  2d 78 0c c8 ff fc    move.l   $cc8.w, -$4(a6)
  00983a:  70 01                moveq    #$1, d0
  00983c:  2f 00                move.l   d0, -(a7)
  00983e:  72 00                moveq    #$0, d1
  009840:  2f 01                move.l   d1, -(a7)
  009842:  2f 01                move.l   d1, -(a7)
  009844:  70 26                moveq    #$26, d0
  009846:  2f 00                move.l   d0, -(a7)
  009848:  61 ff ff ff b1 7a    bsr.l    $49c4  ; -> EngineDispatch
  00984e:  2f 2e 00 08          move.l   $8(a6), -(a7)
  009852:  48 78 17 34          pea.l    $1734.w
  009856:  61 ff ff ff d5 3a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00985c:  58 8f                addq.l   #$4, a7
  00985e:  2f 00                move.l   d0, -(a7)
  009860:  20 5f                movea.l  (a7)+, a0
  009862:  4e 90                jsr      (a0)
  009864:  70 01                moveq    #$1, d0
  009866:  2f 00                move.l   d0, -(a7)
  009868:  2f 00                move.l   d0, -(a7)
  00986a:  48 6e ff fc          pea.l    -$4(a6)
  00986e:  72 29                moveq    #$29, d1
  009870:  2f 01                move.l   d1, -(a7)
  009872:  61 ff ff ff b1 50    bsr.l    $49c4  ; -> EngineDispatch
  009878:  4e 5e                unlk     a6
  00987a:  4e 74 00 04          rtd      #$4
handler_29:
  00987e:  4e 56 00 00          link.w   a6, #$0
  009882:  70 01                moveq    #$1, d0
  009884:  2f 00                move.l   d0, -(a7)
  009886:  2f 00                move.l   d0, -(a7)
  009888:  48 6e 00 08          pea.l    $8(a6)
  00988c:  72 2c                moveq    #$2c, d1
  00988e:  2f 01                move.l   d1, -(a7)
  009890:  61 ff ff ff b1 32    bsr.l    $49c4  ; -> EngineDispatch
  009896:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00989a:  48 78 16 20          pea.l    $1620.w
  00989e:  61 ff ff ff d4 f2    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  0098a4:  58 8f                addq.l   #$4, a7
  0098a6:  2f 00                move.l   d0, -(a7)
  0098a8:  20 5f                movea.l  (a7)+, a0
  0098aa:  4e 90                jsr      (a0)
  0098ac:  4e 5e                unlk     a6
  0098ae:  4e 74 00 04          rtd      #$4
handler_30:
  0098b2:  4e 56 ff f8          link.w   a6, #$fff8
  0098b6:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  0098ba:  26 6e 00 08          movea.l  $8(a6), a3
  0098be:  70 00                moveq    #$0, d0
  0098c0:  2f 00                move.l   d0, -(a7)
  0098c2:  61 ff ff ff d6 58    bsr.l    $6f1c  ; -> sub_6f1c
  0098c8:  28 40                movea.l  d0, a4
  0098ca:  7e 00                moveq    #$0, d7
  0098cc:  20 0c                move.l   a4, d0
  0098ce:  58 4f                addq.w   #$4, a7
  0098d0:  67 22                beq.b    $98f4  ; -> L98f4
  0098d2:  4a 6c 00 06          tst.w    $6(a4)
  0098d6:  6c 1c                bge.b    $98f4  ; -> L98f4
  0098d8:  b7 ec 00 3a          cmpa.l   $3a(a4), a3
  0098dc:  66 04                bne.b    $98e2  ; -> L98e2
  0098de:  7e 01                moveq    #$1, d7
  0098e0:  60 12                bra.b    $98f4  ; -> L98f4
L98e2:
  0098e2:  b7 ec 00 20          cmpa.l   $20(a4), a3
  0098e6:  66 04                bne.b    $98ec  ; -> L98ec
  0098e8:  7e 02                moveq    #$2, d7
  0098ea:  60 08                bra.b    $98f4  ; -> L98f4
L98ec:
  0098ec:  b7 ec 00 3e          cmpa.l   $3e(a4), a3
  0098f0:  66 02                bne.b    $98f4  ; -> L98f4
  0098f2:  7e 03                moveq    #$3, d7
L98f4:
  0098f4:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  0098f8:  2f 0b                move.l   a3, -(a7)
  0098fa:  48 78 16 24          pea.l    $1624.w
  0098fe:  61 ff ff ff d4 92    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009904:  58 8f                addq.l   #$4, a7
  009906:  2f 00                move.l   d0, -(a7)
  009908:  20 5f                movea.l  (a7)+, a0
  00990a:  4e 90                jsr      (a0)
  00990c:  20 53                movea.l  (a3), a0
  00990e:  31 7c ff ff 00 0e    move.w   #$ffff, $e(a0)
  009914:  4a 87                tst.l    d7
  009916:  67 24                beq.b    $993c  ; -> L993c
  009918:  70 00                moveq    #$0, d0
  00991a:  2d 40 ff f8          move.l   d0, -$8(a6)
  00991e:  2d 47 ff fc          move.l   d7, -$4(a6)
  009922:  70 01                moveq    #$1, d0
  009924:  2f 00                move.l   d0, -(a7)
  009926:  72 02                moveq    #$2, d1
  009928:  2f 01                move.l   d1, -(a7)
  00992a:  48 6e ff f8          pea.l    -$8(a6)
  00992e:  70 2a                moveq    #$2a, d0
  009930:  2f 00                move.l   d0, -(a7)
  009932:  61 ff ff ff b0 90    bsr.l    $49c4  ; -> EngineDispatch
  009938:  4f ef 00 10          lea.l    $10(a7), a7
L993c:
  00993c:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  009942:  4e 5e                unlk     a6
  009944:  4e 74 00 08          rtd      #$8
handler_31:
  009948:  4e 56 ff f8          link.w   a6, #$fff8
  00994c:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  009950:  26 6e 00 0c          movea.l  $c(a6), a3
  009954:  70 00                moveq    #$0, d0
  009956:  2f 00                move.l   d0, -(a7)
  009958:  61 ff ff ff d5 c2    bsr.l    $6f1c  ; -> sub_6f1c
  00995e:  28 40                movea.l  d0, a4
  009960:  7e 00                moveq    #$0, d7
  009962:  20 0c                move.l   a4, d0
  009964:  58 4f                addq.w   #$4, a7
  009966:  67 22                beq.b    $998a  ; -> L998a
  009968:  4a 6c 00 06          tst.w    $6(a4)
  00996c:  6c 1c                bge.b    $998a  ; -> L998a
  00996e:  b7 ec 00 3a          cmpa.l   $3a(a4), a3
  009972:  66 04                bne.b    $9978  ; -> L9978
  009974:  7e 01                moveq    #$1, d7
  009976:  60 12                bra.b    $998a  ; -> L998a
L9978:
  009978:  b7 ec 00 20          cmpa.l   $20(a4), a3
  00997c:  66 04                bne.b    $9982  ; -> L9982
  00997e:  7e 02                moveq    #$2, d7
  009980:  60 08                bra.b    $998a  ; -> L998a
L9982:
  009982:  b7 ec 00 3e          cmpa.l   $3e(a4), a3
  009986:  66 02                bne.b    $998a  ; -> L998a
  009988:  7e 03                moveq    #$3, d7
L998a:
  00998a:  2f 0b                move.l   a3, -(a7)
  00998c:  2f 2e 00 08          move.l   $8(a6), -(a7)
  009990:  48 78 16 34          pea.l    $1634.w
  009994:  61 ff ff ff d3 fc    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00999a:  58 8f                addq.l   #$4, a7
  00999c:  2f 00                move.l   d0, -(a7)
  00999e:  20 5f                movea.l  (a7)+, a0
  0099a0:  4e 90                jsr      (a0)
  0099a2:  4a 87                tst.l    d7
  0099a4:  67 24                beq.b    $99ca  ; -> L99ca
  0099a6:  70 00                moveq    #$0, d0
  0099a8:  2d 40 ff f8          move.l   d0, -$8(a6)
  0099ac:  2d 47 ff fc          move.l   d7, -$4(a6)
  0099b0:  70 01                moveq    #$1, d0
  0099b2:  2f 00                move.l   d0, -(a7)
  0099b4:  72 02                moveq    #$2, d1
  0099b6:  2f 01                move.l   d1, -(a7)
  0099b8:  48 6e ff f8          pea.l    -$8(a6)
  0099bc:  70 2a                moveq    #$2a, d0
  0099be:  2f 00                move.l   d0, -(a7)
  0099c0:  61 ff ff ff b0 02    bsr.l    $49c4  ; -> EngineDispatch
  0099c6:  4f ef 00 10          lea.l    $10(a7), a7
L99ca:
  0099ca:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  0099d0:  4e 5e                unlk     a6
  0099d2:  4e 74 00 08          rtd      #$8
handler_32:
  0099d6:  4e 56 ff f8          link.w   a6, #$fff8
  0099da:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  0099de:  70 00                moveq    #$0, d0
  0099e0:  2f 00                move.l   d0, -(a7)
  0099e2:  61 ff ff ff d5 38    bsr.l    $6f1c  ; -> sub_6f1c
  0099e8:  28 40                movea.l  d0, a4
  0099ea:  7e 00                moveq    #$0, d7
  0099ec:  20 6e 00 08          movea.l  $8(a6), a0
  0099f0:  26 50                movea.l  (a0), a3
  0099f2:  20 0b                move.l   a3, d0
  0099f4:  58 4f                addq.w   #$4, a7
  0099f6:  67 42                beq.b    $9a3a  ; -> L9a3a
  0099f8:  70 01                moveq    #$1, d0
  0099fa:  2f 00                move.l   d0, -(a7)
  0099fc:  2f 08                move.l   a0, -(a7)
  0099fe:  72 00                moveq    #$0, d1
  009a00:  2f 01                move.l   d1, -(a7)
  009a02:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  009a06:  61 ff ff ff f7 a2    bsr.l    $91aa  ; -> sub_91aa
  009a0c:  4a 00                tst.b    d0
  009a0e:  4f ef 00 10          lea.l    $10(a7), a7
  009a12:  66 68                bne.b    $9a7c  ; -> L9a7c
  009a14:  20 0c                move.l   a4, d0
  009a16:  67 22                beq.b    $9a3a  ; -> L9a3a
  009a18:  4a 6c 00 06          tst.w    $6(a4)
  009a1c:  6c 1c                bge.b    $9a3a  ; -> L9a3a
  009a1e:  b7 ec 00 3a          cmpa.l   $3a(a4), a3
  009a22:  66 04                bne.b    $9a28  ; -> L9a28
  009a24:  7e 01                moveq    #$1, d7
  009a26:  60 12                bra.b    $9a3a  ; -> L9a3a
L9a28:
  009a28:  b7 ec 00 20          cmpa.l   $20(a4), a3
  009a2c:  66 04                bne.b    $9a32  ; -> L9a32
  009a2e:  7e 02                moveq    #$2, d7
  009a30:  60 08                bra.b    $9a3a  ; -> L9a3a
L9a32:
  009a32:  b7 ec 00 3e          cmpa.l   $3e(a4), a3
  009a36:  66 02                bne.b    $9a3a  ; -> L9a3a
  009a38:  7e 03                moveq    #$3, d7
L9a3a:
  009a3a:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  009a3e:  2f 2e 00 08          move.l   $8(a6), -(a7)
  009a42:  48 78 1a 44          pea.l    $1a44.w
  009a46:  61 ff ff ff d3 4a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009a4c:  58 8f                addq.l   #$4, a7
  009a4e:  2f 00                move.l   d0, -(a7)
  009a50:  20 5f                movea.l  (a7)+, a0
  009a52:  4e 90                jsr      (a0)
  009a54:  4a 87                tst.l    d7
  009a56:  67 24                beq.b    $9a7c  ; -> L9a7c
  009a58:  70 00                moveq    #$0, d0
  009a5a:  2d 40 ff f8          move.l   d0, -$8(a6)
  009a5e:  2d 47 ff fc          move.l   d7, -$4(a6)
  009a62:  70 01                moveq    #$1, d0
  009a64:  2f 00                move.l   d0, -(a7)
  009a66:  72 02                moveq    #$2, d1
  009a68:  2f 01                move.l   d1, -(a7)
  009a6a:  48 6e ff f8          pea.l    -$8(a6)
  009a6e:  70 2a                moveq    #$2a, d0
  009a70:  2f 00                move.l   d0, -(a7)
  009a72:  61 ff ff ff af 50    bsr.l    $49c4  ; -> EngineDispatch
  009a78:  4f ef 00 10          lea.l    $10(a7), a7
L9a7c:
  009a7c:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  009a82:  4e 5e                unlk     a6
  009a84:  4e 74 00 08          rtd      #$8
sub_9a88:
  009a88:  4e 56 ff f4          link.w   a6, #$fff4
  009a8c:  48 e7 17 18          movem.l  d3/d5-d7/a3-a4, -(a7)
  009a90:  3a 2e 00 08          move.w   $8(a6), d5
  009a94:  70 00                moveq    #$0, d0
  009a96:  2f 00                move.l   d0, -(a7)
  009a98:  61 ff ff ff d4 82    bsr.l    $6f1c  ; -> sub_6f1c
  009a9e:  28 40                movea.l  d0, a4
  009aa0:  4a ae 00 0a          tst.l    $a(a6)
  009aa4:  58 4f                addq.w   #$4, a7
  009aa6:  67 00 01 16          beq.w    $9bbe  ; -> L9bbe
  009aaa:  4a 45                tst.w    d5
  009aac:  67 24                beq.b    $9ad2  ; -> L9ad2
  009aae:  20 6e 00 0a          movea.l  $a(a6), a0
  009ab2:  20 50                movea.l  (a0), a0
  009ab4:  20 68 00 02          movea.l  $2(a0), a0
  009ab8:  20 50                movea.l  (a0), a0
  009aba:  2d 68 00 2a ff fc    move.l   $2a(a0), -$4(a6)
  009ac0:  67 10                beq.b    $9ad2  ; -> L9ad2
  009ac2:  20 6e ff fc          movea.l  -$4(a6), a0
  009ac6:  26 50                movea.l  (a0), a3
  009ac8:  4a 93                tst.l    (a3)
  009aca:  66 06                bne.b    $9ad2  ; -> L9ad2
  009acc:  59 8f                subq.l   #$4, a7
  009ace:  aa 28                dc.w     $aa28  ; _GetCTSeed
  009ad0:  26 9f                move.l   (a7)+, (a3)
L9ad2:
  009ad2:  61 ff ff ff e5 3c    bsr.l    $8010  ; -> GetA5
  009ad8:  20 40                movea.l  d0, a0
  009ada:  20 50                movea.l  (a0), a0
  009adc:  b9 d0                cmpa.l   (a0), a4
  009ade:  66 00 00 c4          bne.w    $9ba4  ; -> L9ba4
  009ae2:  4a 6c 00 06          tst.w    $6(a4)
  009ae6:  5d c0                slt.b    d0
  009ae8:  44 00                neg.b    d0
  009aea:  49 c0                extb.l   d0
  009aec:  1e 00                move.b   d0, d7
  009aee:  67 08                beq.b    $9af8  ; -> L9af8
  009af0:  41 ec 00 3e          lea.l    $3e(a4), a0
  009af4:  20 08                move.l   a0, d0
  009af6:  60 06                bra.b    $9afe  ; -> L9afe
L9af8:
  009af8:  41 ec 00 28          lea.l    $28(a4), a0
  009afc:  20 08                move.l   a0, d0
L9afe:
  009afe:  26 40                movea.l  d0, a3
  009b00:  76 00                moveq    #$0, d3
  009b02:  4a 45                tst.w    d5
  009b04:  67 06                beq.b    $9b0c  ; -> L9b0c
  009b06:  4a 07                tst.b    d7
  009b08:  66 02                bne.b    $9b0c  ; -> L9b0c
  009b0a:  76 01                moveq    #$1, d3
L9b0c:
  009b0c:  1c 03                move.b   d3, d6
  009b0e:  67 20                beq.b    $9b30  ; -> L9b30
  009b10:  70 00                moveq    #$0, d0
  009b12:  2f 00                move.l   d0, -(a7)
  009b14:  20 6e 00 0a          movea.l  $a(a6), a0
  009b18:  20 50                movea.l  (a0), a0
  009b1a:  48 68 00 14          pea.l    $14(a0)
  009b1e:  2f 00                move.l   d0, -(a7)
  009b20:  2f 0b                move.l   a3, -(a7)
  009b22:  61 ff ff ff f6 86    bsr.l    $91aa  ; -> sub_91aa
  009b28:  4a 00                tst.b    d0
  009b2a:  4f ef 00 10          lea.l    $10(a7), a7
  009b2e:  67 32                beq.b    $9b62  ; -> L9b62
L9b30:
  009b30:  4a 06                tst.b    d6
  009b32:  66 00 00 8a          bne.w    $9bbe  ; -> L9bbe
  009b36:  48 c5                ext.l    d5
  009b38:  2f 05                move.l   d5, -(a7)
  009b3a:  4a 45                tst.w    d5
  009b3c:  67 08                beq.b    $9b46  ; -> L9b46
  009b3e:  41 ee 00 0a          lea.l    $a(a6), a0
  009b42:  20 08                move.l   a0, d0
  009b44:  60 04                bra.b    $9b4a  ; -> L9b4a
L9b46:
  009b46:  20 2e 00 0a          move.l   $a(a6), d0
L9b4a:
  009b4a:  2f 00                move.l   d0, -(a7)
  009b4c:  70 00                moveq    #$0, d0
  009b4e:  10 07                move.b   d7, d0
  009b50:  2f 00                move.l   d0, -(a7)
  009b52:  2f 0b                move.l   a3, -(a7)
  009b54:  61 ff ff ff f6 54    bsr.l    $91aa  ; -> sub_91aa
  009b5a:  4a 00                tst.b    d0
  009b5c:  4f ef 00 10          lea.l    $10(a7), a7
  009b60:  66 5c                bne.b    $9bbe  ; -> L9bbe
L9b62:
  009b62:  2f 2e 00 0a          move.l   $a(a6), -(a7)
  009b66:  48 78 1a 8c          pea.l    $1a8c.w
  009b6a:  61 ff ff ff d2 26    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009b70:  58 8f                addq.l   #$4, a7
  009b72:  2f 00                move.l   d0, -(a7)
  009b74:  3f 05                move.w   d5, -(a7)
  009b76:  30 1f                move.w   (a7)+, d0
  009b78:  20 5f                movea.l  (a7)+, a0
  009b7a:  4e 90                jsr      (a0)
  009b7c:  70 00                moveq    #$0, d0
  009b7e:  2d 40 ff f4          move.l   d0, -$c(a6)
  009b82:  72 03                moveq    #$3, d1
  009b84:  2d 41 ff f8          move.l   d1, -$8(a6)
  009b88:  70 01                moveq    #$1, d0
  009b8a:  2f 00                move.l   d0, -(a7)
  009b8c:  72 02                moveq    #$2, d1
  009b8e:  2f 01                move.l   d1, -(a7)
  009b90:  48 6e ff f4          pea.l    -$c(a6)
  009b94:  70 2a                moveq    #$2a, d0
  009b96:  2f 00                move.l   d0, -(a7)
  009b98:  61 ff ff ff ae 2a    bsr.l    $49c4  ; -> EngineDispatch
  009b9e:  4f ef 00 10          lea.l    $10(a7), a7
  009ba2:  60 1a                bra.b    $9bbe  ; -> L9bbe
L9ba4:
  009ba4:  2f 2e 00 0a          move.l   $a(a6), -(a7)
  009ba8:  48 78 1a 8c          pea.l    $1a8c.w
  009bac:  61 ff ff ff d1 e4    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009bb2:  58 8f                addq.l   #$4, a7
  009bb4:  2f 00                move.l   d0, -(a7)
  009bb6:  3f 05                move.w   d5, -(a7)
  009bb8:  30 1f                move.w   (a7)+, d0
  009bba:  20 5f                movea.l  (a7)+, a0
  009bbc:  4e 90                jsr      (a0)
L9bbe:
  009bbe:  4c ee 18 e8 ff dc    movem.l  -$24(a6), d3/d5-d7/a3-a4
  009bc4:  4e 5e                unlk     a6
  009bc6:  4e 74 00 06          rtd      #$6
handler_33:
  009bca:  4e 56 ff fc          link.w   a6, #$fffc
  009bce:  48 e7 00 18          movem.l  a3-a4, -(a7)
  009bd2:  26 6e 00 08          movea.l  $8(a6), a3
  009bd6:  70 00                moveq    #$0, d0
  009bd8:  2f 00                move.l   d0, -(a7)
  009bda:  61 ff ff ff d3 40    bsr.l    $6f1c  ; -> sub_6f1c
  009be0:  2d 40 ff fc          move.l   d0, -$4(a6)
  009be4:  61 ff ff ff e4 2a    bsr.l    $8010  ; -> GetA5
  009bea:  20 40                movea.l  d0, a0
  009bec:  20 50                movea.l  (a0), a0
  009bee:  20 2e ff fc          move.l   -$4(a6), d0
  009bf2:  b0 90                cmp.l    (a0), d0
  009bf4:  58 4f                addq.w   #$4, a7
  009bf6:  66 4a                bne.b    $9c42  ; -> L9c42
  009bf8:  20 6e ff fc          movea.l  -$4(a6), a0
  009bfc:  4a 68 00 06          tst.w    $6(a0)
  009c00:  6d 40                blt.b    $9c42  ; -> L9c42
  009c02:  49 e8 00 02          lea.l    $2(a0), a4
  009c06:  20 14                move.l   (a4), d0
  009c08:  b0 93                cmp.l    (a3), d0
  009c0a:  66 1e                bne.b    $9c2a  ; -> L9c2a
  009c0c:  30 2c 00 04          move.w   $4(a4), d0
  009c10:  b0 6b 00 04          cmp.w    $4(a3), d0
  009c14:  66 14                bne.b    $9c2a  ; -> L9c2a
  009c16:  20 2c 00 06          move.l   $6(a4), d0
  009c1a:  b0 ab 00 06          cmp.l    $6(a3), d0
  009c1e:  66 0a                bne.b    $9c2a  ; -> L9c2a
  009c20:  20 2c 00 0a          move.l   $a(a4), d0
  009c24:  b0 ab 00 0a          cmp.l    $a(a3), d0
  009c28:  67 18                beq.b    $9c42  ; -> L9c42
L9c2a:
  009c2a:  70 01                moveq    #$1, d0
  009c2c:  2f 00                move.l   d0, -(a7)
  009c2e:  72 00                moveq    #$0, d1
  009c30:  2f 01                move.l   d1, -(a7)
  009c32:  2f 01                move.l   d1, -(a7)
  009c34:  70 26                moveq    #$26, d0
  009c36:  2f 00                move.l   d0, -(a7)
  009c38:  61 ff ff ff ad 8a    bsr.l    $49c4  ; -> EngineDispatch
  009c3e:  4f ef 00 10          lea.l    $10(a7), a7
L9c42:
  009c42:  2f 0b                move.l   a3, -(a7)
  009c44:  48 78 0f d4          pea.l    $fd4.w
  009c48:  61 ff ff ff d1 48    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009c4e:  58 8f                addq.l   #$4, a7
  009c50:  2f 00                move.l   d0, -(a7)
  009c52:  20 5f                movea.l  (a7)+, a0
  009c54:  4e 90                jsr      (a0)
  009c56:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  009c5c:  4e 5e                unlk     a6
  009c5e:  4e 74 00 04          rtd      #$4
handler_34:
  009c62:  4e 56 00 00          link.w   a6, #$0
  009c66:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  009c6a:  3c 2e 00 08          move.w   $8(a6), d6
  009c6e:  3e 2e 00 0a          move.w   $a(a6), d7
  009c72:  70 00                moveq    #$0, d0
  009c74:  2f 00                move.l   d0, -(a7)
  009c76:  61 ff ff ff d2 a4    bsr.l    $6f1c  ; -> sub_6f1c
  009c7c:  26 40                movea.l  d0, a3
  009c7e:  61 ff ff ff e3 90    bsr.l    $8010  ; -> GetA5
  009c84:  20 40                movea.l  d0, a0
  009c86:  20 50                movea.l  (a0), a0
  009c88:  b7 d0                cmpa.l   (a0), a3
  009c8a:  58 4f                addq.w   #$4, a7
  009c8c:  66 42                bne.b    $9cd0  ; -> L9cd0
  009c8e:  49 eb 00 10          lea.l    $10(a3), a4
  009c92:  30 2c 00 06          move.w   $6(a4), d0
  009c96:  48 c0                ext.l    d0
  009c98:  32 2c 00 02          move.w   $2(a4), d1
  009c9c:  48 c1                ext.l    d1
  009c9e:  90 81                sub.l    d1, d0
  009ca0:  48 c7                ext.l    d7
  009ca2:  be 80                cmp.l    d0, d7
  009ca4:  66 12                bne.b    $9cb8  ; -> L9cb8
  009ca6:  30 2c 00 04          move.w   $4(a4), d0
  009caa:  48 c0                ext.l    d0
  009cac:  32 14                move.w   (a4), d1
  009cae:  48 c1                ext.l    d1
  009cb0:  90 81                sub.l    d1, d0
  009cb2:  48 c6                ext.l    d6
  009cb4:  bc 80                cmp.l    d0, d6
  009cb6:  67 18                beq.b    $9cd0  ; -> L9cd0
L9cb8:
  009cb8:  70 01                moveq    #$1, d0
  009cba:  2f 00                move.l   d0, -(a7)
  009cbc:  72 00                moveq    #$0, d1
  009cbe:  2f 01                move.l   d1, -(a7)
  009cc0:  2f 01                move.l   d1, -(a7)
  009cc2:  70 26                moveq    #$26, d0
  009cc4:  2f 00                move.l   d0, -(a7)
  009cc6:  61 ff ff ff ac fc    bsr.l    $49c4  ; -> EngineDispatch
  009ccc:  4f ef 00 10          lea.l    $10(a7), a7
L9cd0:
  009cd0:  3f 07                move.w   d7, -(a7)
  009cd2:  3f 06                move.w   d6, -(a7)
  009cd4:  48 78 0f d8          pea.l    $fd8.w
  009cd8:  61 ff ff ff d0 b8    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009cde:  58 8f                addq.l   #$4, a7
  009ce0:  2f 00                move.l   d0, -(a7)
  009ce2:  20 5f                movea.l  (a7)+, a0
  009ce4:  4e 90                jsr      (a0)
  009ce6:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  009cec:  4e 5e                unlk     a6
  009cee:  4e 74 00 04          rtd      #$4
handler_35:
  009cf2:  4e 56 00 00          link.w   a6, #$0
  009cf6:  2f 0c                move.l   a4, -(a7)
  009cf8:  70 00                moveq    #$0, d0
  009cfa:  2f 00                move.l   d0, -(a7)
  009cfc:  61 ff ff ff d2 1e    bsr.l    $6f1c  ; -> sub_6f1c
  009d02:  28 40                movea.l  d0, a4
  009d04:  61 ff ff ff e3 0a    bsr.l    $8010  ; -> GetA5
  009d0a:  20 40                movea.l  d0, a0
  009d0c:  20 50                movea.l  (a0), a0
  009d0e:  b9 d0                cmpa.l   (a0), a4
  009d10:  58 4f                addq.w   #$4, a7
  009d12:  66 18                bne.b    $9d2c  ; -> L9d2c
  009d14:  70 01                moveq    #$1, d0
  009d16:  2f 00                move.l   d0, -(a7)
  009d18:  72 00                moveq    #$0, d1
  009d1a:  2f 01                move.l   d1, -(a7)
  009d1c:  2f 01                move.l   d1, -(a7)
  009d1e:  70 26                moveq    #$26, d0
  009d20:  2f 00                move.l   d0, -(a7)
  009d22:  61 ff ff ff ac a0    bsr.l    $49c4  ; -> EngineDispatch
  009d28:  4f ef 00 10          lea.l    $10(a7), a7
L9d2c:
  009d2c:  2f 2e 00 08          move.l   $8(a6), -(a7)
  009d30:  48 78 0f dc          pea.l    $fdc.w
  009d34:  61 ff ff ff d0 5c    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009d3a:  58 8f                addq.l   #$4, a7
  009d3c:  2f 00                move.l   d0, -(a7)
  009d3e:  20 5f                movea.l  (a7)+, a0
  009d40:  4e 90                jsr      (a0)
  009d42:  28 6e ff fc          movea.l  -$4(a6), a4
  009d46:  4e 5e                unlk     a6
  009d48:  4e 74 00 04          rtd      #$4
handler_36:
  009d4c:  4e 56 00 00          link.w   a6, #$0
  009d50:  48 e7 03 08          movem.l  d6-d7/a4, -(a7)
  009d54:  3c 2e 00 08          move.w   $8(a6), d6
  009d58:  3e 2e 00 0a          move.w   $a(a6), d7
  009d5c:  70 00                moveq    #$0, d0
  009d5e:  2f 00                move.l   d0, -(a7)
  009d60:  61 ff ff ff d1 ba    bsr.l    $6f1c  ; -> sub_6f1c
  009d66:  28 40                movea.l  d0, a4
  009d68:  61 ff ff ff e2 a6    bsr.l    $8010  ; -> GetA5
  009d6e:  20 40                movea.l  d0, a0
  009d70:  20 50                movea.l  (a0), a0
  009d72:  b9 d0                cmpa.l   (a0), a4
  009d74:  58 4f                addq.w   #$4, a7
  009d76:  66 24                bne.b    $9d9c  ; -> L9d9c
  009d78:  bc 6c 00 10          cmp.w    $10(a4), d6
  009d7c:  66 06                bne.b    $9d84  ; -> L9d84
  009d7e:  be 6c 00 12          cmp.w    $12(a4), d7
  009d82:  67 2e                beq.b    $9db2  ; -> L9db2
L9d84:
  009d84:  70 01                moveq    #$1, d0
  009d86:  2f 00                move.l   d0, -(a7)
  009d88:  72 00                moveq    #$0, d1
  009d8a:  2f 01                move.l   d1, -(a7)
  009d8c:  2f 01                move.l   d1, -(a7)
  009d8e:  70 26                moveq    #$26, d0
  009d90:  2f 00                move.l   d0, -(a7)
  009d92:  61 ff ff ff ac 30    bsr.l    $49c4  ; -> EngineDispatch
  009d98:  4f ef 00 10          lea.l    $10(a7), a7
L9d9c:
  009d9c:  3f 07                move.w   d7, -(a7)
  009d9e:  3f 06                move.w   d6, -(a7)
  009da0:  48 78 0f e0          pea.l    $fe0.w
  009da4:  61 ff ff ff cf ec    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009daa:  58 8f                addq.l   #$4, a7
  009dac:  2f 00                move.l   d0, -(a7)
  009dae:  20 5f                movea.l  (a7)+, a0
  009db0:  4e 90                jsr      (a0)
L9db2:
  009db2:  4c ee 10 c0 ff f4    movem.l  -$c(a6), d6-d7/a4
  009db8:  4e 5e                unlk     a6
  009dba:  4e 74 00 04          rtd      #$4
handler_37:
  009dbe:  4e 56 00 00          link.w   a6, #$0
  009dc2:  2f 0c                move.l   a4, -(a7)
  009dc4:  70 00                moveq    #$0, d0
  009dc6:  2f 00                move.l   d0, -(a7)
  009dc8:  61 ff ff ff d1 52    bsr.l    $6f1c  ; -> sub_6f1c
  009dce:  28 40                movea.l  d0, a4
  009dd0:  20 0c                move.l   a4, d0
  009dd2:  58 4f                addq.w   #$4, a7
  009dd4:  67 3e                beq.b    $9e14  ; -> L9e14
  009dd6:  61 ff ff ff e2 38    bsr.l    $8010  ; -> GetA5
  009ddc:  20 40                movea.l  d0, a0
  009dde:  20 50                movea.l  (a0), a0
  009de0:  20 50                movea.l  (a0), a0
  009de2:  20 2c 00 1c          move.l   $1c(a4), d0
  009de6:  b0 a8 00 1c          cmp.l    $1c(a0), d0
  009dea:  66 28                bne.b    $9e14  ; -> L9e14
  009dec:  55 8f                subq.l   #$2, a7
  009dee:  2f 2e 00 08          move.l   $8(a6), -(a7)
  009df2:  2f 2c 00 1c          move.l   $1c(a4), -(a7)
  009df6:  a8 e3                dc.w     $a8e3  ; _EqualRgn
  009df8:  4a 1f                tst.b    (a7)+
  009dfa:  66 18                bne.b    $9e14  ; -> L9e14
  009dfc:  70 01                moveq    #$1, d0
  009dfe:  2f 00                move.l   d0, -(a7)
  009e00:  2f 00                move.l   d0, -(a7)
  009e02:  48 6e 00 08          pea.l    $8(a6)
  009e06:  72 32                moveq    #$32, d1
  009e08:  2f 01                move.l   d1, -(a7)
  009e0a:  61 ff ff ff ab b8    bsr.l    $49c4  ; -> EngineDispatch
  009e10:  4f ef 00 10          lea.l    $10(a7), a7
L9e14:
  009e14:  2f 2e 00 08          move.l   $8(a6), -(a7)
  009e18:  48 78 0f e4          pea.l    $fe4.w
  009e1c:  61 ff ff ff cf 74    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009e22:  58 8f                addq.l   #$4, a7
  009e24:  2f 00                move.l   d0, -(a7)
  009e26:  20 5f                movea.l  (a7)+, a0
  009e28:  4e 90                jsr      (a0)
  009e2a:  28 6e ff fc          movea.l  -$4(a6), a4
  009e2e:  4e 5e                unlk     a6
  009e30:  4e 74 00 04          rtd      #$4
handler_38:
  009e34:  4e 56 ff f8          link.w   a6, #$fff8
  009e38:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  009e3c:  26 6e 00 08          movea.l  $8(a6), a3
  009e40:  70 00                moveq    #$0, d0
  009e42:  2f 00                move.l   d0, -(a7)
  009e44:  61 ff ff ff d0 d6    bsr.l    $6f1c  ; -> sub_6f1c
  009e4a:  28 40                movea.l  d0, a4
  009e4c:  42 07                clr.b    d7
  009e4e:  20 0c                move.l   a4, d0
  009e50:  58 4f                addq.w   #$4, a7
  009e52:  67 40                beq.b    $9e94  ; -> L9e94
  009e54:  61 ff ff ff e1 ba    bsr.l    $8010  ; -> GetA5
  009e5a:  20 40                movea.l  d0, a0
  009e5c:  20 50                movea.l  (a0), a0
  009e5e:  20 50                movea.l  (a0), a0
  009e60:  20 2c 00 1c          move.l   $1c(a4), d0
  009e64:  b0 a8 00 1c          cmp.l    $1c(a0), d0
  009e68:  66 2a                bne.b    $9e94  ; -> L9e94
  009e6a:  20 6c 00 1c          movea.l  $1c(a4), a0
  009e6e:  2d 48 ff f8          move.l   a0, -$8(a6)
  009e72:  20 50                movea.l  (a0), a0
  009e74:  2d 48 ff fc          move.l   a0, -$4(a6)
  009e78:  49 e8 00 02          lea.l    $2(a0), a4
  009e7c:  70 0a                moveq    #$a, d0
  009e7e:  b0 50                cmp.w    (a0), d0
  009e80:  66 10                bne.b    $9e92  ; -> L9e92
  009e82:  20 14                move.l   (a4), d0
  009e84:  b0 93                cmp.l    (a3), d0
  009e86:  66 0a                bne.b    $9e92  ; -> L9e92
  009e88:  20 2c 00 04          move.l   $4(a4), d0
  009e8c:  b0 ab 00 04          cmp.l    $4(a3), d0
  009e90:  67 02                beq.b    $9e94  ; -> L9e94
L9e92:
  009e92:  7e 01                moveq    #$1, d7
L9e94:
  009e94:  2f 0b                move.l   a3, -(a7)
  009e96:  48 78 0f ec          pea.l    $fec.w
  009e9a:  61 ff ff ff ce f6    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009ea0:  58 8f                addq.l   #$4, a7
  009ea2:  2f 00                move.l   d0, -(a7)
  009ea4:  20 5f                movea.l  (a7)+, a0
  009ea6:  4e 90                jsr      (a0)
  009ea8:  4a 07                tst.b    d7
  009eaa:  67 18                beq.b    $9ec4  ; -> L9ec4
  009eac:  70 01                moveq    #$1, d0
  009eae:  2f 00                move.l   d0, -(a7)
  009eb0:  2f 00                move.l   d0, -(a7)
  009eb2:  48 6e ff f8          pea.l    -$8(a6)
  009eb6:  72 32                moveq    #$32, d1
  009eb8:  2f 01                move.l   d1, -(a7)
  009eba:  61 ff ff ff ab 08    bsr.l    $49c4  ; -> EngineDispatch
  009ec0:  4f ef 00 10          lea.l    $10(a7), a7
L9ec4:
  009ec4:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  009eca:  4e 5e                unlk     a6
  009ecc:  4e 74 00 04          rtd      #$4
handler_39:
  009ed0:  4e 56 00 00          link.w   a6, #$0
  009ed4:  48 78 10 58          pea.l    $1058.w
  009ed8:  61 ff ff ff ce b8    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009ede:  58 8f                addq.l   #$4, a7
  009ee0:  2f 00                move.l   d0, -(a7)
  009ee2:  20 5f                movea.l  (a7)+, a0
  009ee4:  4e 90                jsr      (a0)
  009ee6:  4e 5e                unlk     a6
  009ee8:  4e 75                rts      
handler_40:
  009eea:  4e 56 00 00          link.w   a6, #$0
  009eee:  48 78 10 5c          pea.l    $105c.w
  009ef2:  61 ff ff ff ce 9e    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009ef8:  58 8f                addq.l   #$4, a7
  009efa:  2f 00                move.l   d0, -(a7)
  009efc:  20 5f                movea.l  (a7)+, a0
  009efe:  4e 90                jsr      (a0)
  009f00:  4e 5e                unlk     a6
  009f02:  4e 75                rts      
handler_11:
  009f04:  4e 56 ff f4          link.w   a6, #$fff4
  009f08:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  009f0c:  26 6e 00 08          movea.l  $8(a6), a3
  009f10:  70 00                moveq    #$0, d0
  009f12:  2f 00                move.l   d0, -(a7)
  009f14:  61 ff ff ff d0 06    bsr.l    $6f1c  ; -> sub_6f1c
  009f1a:  28 40                movea.l  d0, a4
  009f1c:  7e 00                moveq    #$0, d7
  009f1e:  61 ff ff ff e0 f0    bsr.l    $8010  ; -> GetA5
  009f24:  20 40                movea.l  d0, a0
  009f26:  20 50                movea.l  (a0), a0
  009f28:  b9 d0                cmpa.l   (a0), a4
  009f2a:  58 4f                addq.w   #$4, a7
  009f2c:  66 5a                bne.b    $9f88  ; -> L9f88
  009f2e:  4a 6b 00 08          tst.w    $8(a3)
  009f32:  5d c0                slt.b    d0
  009f34:  44 00                neg.b    d0
  009f36:  49 c0                extb.l   d0
  009f38:  2f 00                move.l   d0, -(a7)
  009f3a:  48 6b 00 0a          pea.l    $a(a3)
  009f3e:  4a 6c 00 06          tst.w    $6(a4)
  009f42:  5d c0                slt.b    d0
  009f44:  44 00                neg.b    d0
  009f46:  49 c0                extb.l   d0
  009f48:  2f 00                move.l   d0, -(a7)
  009f4a:  48 6c 00 3a          pea.l    $3a(a4)
  009f4e:  61 ff ff ff f2 5a    bsr.l    $91aa  ; -> sub_91aa
  009f54:  4a 00                tst.b    d0
  009f56:  4f ef 00 10          lea.l    $10(a7), a7
  009f5a:  66 04                bne.b    $9f60  ; -> L9f60
  009f5c:  7e 01                moveq    #$1, d7
  009f5e:  60 28                bra.b    $9f88  ; -> L9f88
L9f60:
  009f60:  2d 6b 00 04 ff f4    move.l   $4(a3), -$c(a6)
  009f66:  20 2c 00 34          move.l   $34(a4), d0
  009f6a:  b0 ae ff f4          cmp.l    -$c(a6), d0
  009f6e:  67 18                beq.b    $9f88  ; -> L9f88
  009f70:  70 01                moveq    #$1, d0
  009f72:  2f 00                move.l   d0, -(a7)
  009f74:  2f 00                move.l   d0, -(a7)
  009f76:  48 6e ff f4          pea.l    -$c(a6)
  009f7a:  72 35                moveq    #$35, d1
  009f7c:  2f 01                move.l   d1, -(a7)
  009f7e:  61 ff ff ff aa 44    bsr.l    $49c4  ; -> EngineDispatch
  009f84:  4f ef 00 10          lea.l    $10(a7), a7
L9f88:
  009f88:  2f 0b                move.l   a3, -(a7)
  009f8a:  48 78 10 64          pea.l    $1064.w
  009f8e:  61 ff ff ff ce 02    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  009f94:  58 8f                addq.l   #$4, a7
  009f96:  2f 00                move.l   d0, -(a7)
  009f98:  20 5f                movea.l  (a7)+, a0
  009f9a:  4e 90                jsr      (a0)
  009f9c:  4a 87                tst.l    d7
  009f9e:  67 24                beq.b    $9fc4  ; -> L9fc4
  009fa0:  70 00                moveq    #$0, d0
  009fa2:  2d 40 ff f8          move.l   d0, -$8(a6)
  009fa6:  2d 47 ff fc          move.l   d7, -$4(a6)
  009faa:  70 01                moveq    #$1, d0
  009fac:  2f 00                move.l   d0, -(a7)
  009fae:  72 02                moveq    #$2, d1
  009fb0:  2f 01                move.l   d1, -(a7)
  009fb2:  48 6e ff f8          pea.l    -$8(a6)
  009fb6:  70 2a                moveq    #$2a, d0
  009fb8:  2f 00                move.l   d0, -(a7)
  009fba:  61 ff ff ff aa 08    bsr.l    $49c4  ; -> EngineDispatch
  009fc0:  4f ef 00 10          lea.l    $10(a7), a7
L9fc4:
  009fc4:  4c ee 18 80 ff e8    movem.l  -$18(a6), d7/a3-a4
  009fca:  4e 5e                unlk     a6
  009fcc:  4e 74 00 04          rtd      #$4
handler_12:
  009fd0:  4e 56 ff fc          link.w   a6, #$fffc
  009fd4:  48 e7 03 08          movem.l  d6-d7/a4, -(a7)
  009fd8:  3c 2e 00 08          move.w   $8(a6), d6
  009fdc:  3e 2e 00 0a          move.w   $a(a6), d7
  009fe0:  70 00                moveq    #$0, d0
  009fe2:  2f 00                move.l   d0, -(a7)
  009fe4:  61 ff ff ff cf 36    bsr.l    $6f1c  ; -> sub_6f1c
  009fea:  28 40                movea.l  d0, a4
  009fec:  61 ff ff ff e0 22    bsr.l    $8010  ; -> GetA5
  009ff2:  20 40                movea.l  d0, a0
  009ff4:  20 50                movea.l  (a0), a0
  009ff6:  b9 d0                cmpa.l   (a0), a4
  009ff8:  58 4f                addq.w   #$4, a7
  009ffa:  66 42                bne.b    $a03e  ; -> La03e
  009ffc:  3d 46 ff fc          move.w   d6, -$4(a6)
  00a000:  3d 47 ff fe          move.w   d7, -$2(a6)
  00a004:  20 2c 00 34          move.l   $34(a4), d0
  00a008:  b0 ae ff fc          cmp.l    -$4(a6), d0
  00a00c:  67 46                beq.b    $a054  ; -> La054
  00a00e:  70 01                moveq    #$1, d0
  00a010:  2f 00                move.l   d0, -(a7)
  00a012:  2f 00                move.l   d0, -(a7)
  00a014:  48 6e ff fc          pea.l    -$4(a6)
  00a018:  72 35                moveq    #$35, d1
  00a01a:  2f 01                move.l   d1, -(a7)
  00a01c:  61 ff ff ff a9 a6    bsr.l    $49c4  ; -> EngineDispatch
  00a022:  3f 07                move.w   d7, -(a7)
  00a024:  3f 06                move.w   d6, -(a7)
  00a026:  48 78 10 6c          pea.l    $106c.w
  00a02a:  61 ff ff ff cd 66    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a030:  58 8f                addq.l   #$4, a7
  00a032:  2f 00                move.l   d0, -(a7)
  00a034:  20 5f                movea.l  (a7)+, a0
  00a036:  4e 90                jsr      (a0)
  00a038:  4f ef 00 10          lea.l    $10(a7), a7
  00a03c:  60 16                bra.b    $a054  ; -> La054
La03e:
  00a03e:  3f 07                move.w   d7, -(a7)
  00a040:  3f 06                move.w   d6, -(a7)
  00a042:  48 78 10 6c          pea.l    $106c.w
  00a046:  61 ff ff ff cd 4a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a04c:  58 8f                addq.l   #$4, a7
  00a04e:  2f 00                move.l   d0, -(a7)
  00a050:  20 5f                movea.l  (a7)+, a0
  00a052:  4e 90                jsr      (a0)
La054:
  00a054:  4c ee 10 c0 ff f0    movem.l  -$10(a6), d6-d7/a4
  00a05a:  4e 5e                unlk     a6
  00a05c:  4e 74 00 04          rtd      #$4
handler_13:
  00a060:  4e 56 00 00          link.w   a6, #$0
  00a064:  3f 2e 00 08          move.w   $8(a6), -(a7)
  00a068:  48 78 10 70          pea.l    $1070.w
  00a06c:  61 ff ff ff cd 24    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a072:  58 8f                addq.l   #$4, a7
  00a074:  2f 00                move.l   d0, -(a7)
  00a076:  20 5f                movea.l  (a7)+, a0
  00a078:  4e 90                jsr      (a0)
  00a07a:  4e 5e                unlk     a6
  00a07c:  4e 74 00 02          rtd      #$2
handler_64:
  00a080:  4e 56 ff f8          link.w   a6, #$fff8
  00a084:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  00a088:  26 6e 00 08          movea.l  $8(a6), a3
  00a08c:  61 ff ff ff dd 36    bsr.l    $7dc4  ; -> GetD2
  00a092:  2e 00                move.l   d0, d7
  00a094:  70 00                moveq    #$0, d0
  00a096:  2f 00                move.l   d0, -(a7)
  00a098:  61 ff ff ff ce 82    bsr.l    $6f1c  ; -> sub_6f1c
  00a09e:  28 40                movea.l  d0, a4
  00a0a0:  61 ff ff ff df 6e    bsr.l    $8010  ; -> GetA5
  00a0a6:  20 40                movea.l  d0, a0
  00a0a8:  20 50                movea.l  (a0), a0
  00a0aa:  b9 d0                cmpa.l   (a0), a4
  00a0ac:  58 4f                addq.w   #$4, a7
  00a0ae:  66 60                bne.b    $a110  ; -> La110
  00a0b0:  70 00                moveq    #$0, d0
  00a0b2:  2f 00                move.l   d0, -(a7)
  00a0b4:  2f 0b                move.l   a3, -(a7)
  00a0b6:  4a 6c 00 06          tst.w    $6(a4)
  00a0ba:  5d c1                slt.b    d1
  00a0bc:  44 01                neg.b    d1
  00a0be:  49 c1                extb.l   d1
  00a0c0:  2f 01                move.l   d1, -(a7)
  00a0c2:  48 6c 00 3a          pea.l    $3a(a4)
  00a0c6:  61 ff ff ff f0 e2    bsr.l    $91aa  ; -> sub_91aa
  00a0cc:  4a 00                tst.b    d0
  00a0ce:  4f ef 00 10          lea.l    $10(a7), a7
  00a0d2:  66 50                bne.b    $a124  ; -> La124
  00a0d4:  2f 0b                move.l   a3, -(a7)
  00a0d6:  48 78 10 74          pea.l    $1074.w
  00a0da:  61 ff ff ff cc b6    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a0e0:  58 8f                addq.l   #$4, a7
  00a0e2:  2f 00                move.l   d0, -(a7)
  00a0e4:  20 5f                movea.l  (a7)+, a0
  00a0e6:  4e 90                jsr      (a0)
  00a0e8:  70 00                moveq    #$0, d0
  00a0ea:  2d 40 ff f8          move.l   d0, -$8(a6)
  00a0ee:  72 01                moveq    #$1, d1
  00a0f0:  2d 41 ff fc          move.l   d1, -$4(a6)
  00a0f4:  70 01                moveq    #$1, d0
  00a0f6:  2f 00                move.l   d0, -(a7)
  00a0f8:  72 02                moveq    #$2, d1
  00a0fa:  2f 01                move.l   d1, -(a7)
  00a0fc:  48 6e ff f8          pea.l    -$8(a6)
  00a100:  70 2a                moveq    #$2a, d0
  00a102:  2f 00                move.l   d0, -(a7)
  00a104:  61 ff ff ff a8 be    bsr.l    $49c4  ; -> EngineDispatch
  00a10a:  4f ef 00 10          lea.l    $10(a7), a7
  00a10e:  60 14                bra.b    $a124  ; -> La124
La110:
  00a110:  2f 0b                move.l   a3, -(a7)
  00a112:  48 78 10 74          pea.l    $1074.w
  00a116:  61 ff ff ff cc 7a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a11c:  58 8f                addq.l   #$4, a7
  00a11e:  2f 00                move.l   d0, -(a7)
  00a120:  20 5f                movea.l  (a7)+, a0
  00a122:  4e 90                jsr      (a0)
La124:
  00a124:  2f 07                move.l   d7, -(a7)
  00a126:  61 ff ff ff dc a8    bsr.l    $7dd0  ; -> SetD2
  00a12c:  58 4f                addq.w   #$4, a7
  00a12e:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  00a134:  4e 5e                unlk     a6
  00a136:  4e 74 00 04          rtd      #$4
handler_65:
  00a13a:  4e 56 ff f8          link.w   a6, #$fff8
  00a13e:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00a142:  26 6e 00 08          movea.l  $8(a6), a3
  00a146:  70 00                moveq    #$0, d0
  00a148:  2f 00                move.l   d0, -(a7)
  00a14a:  61 ff ff ff cd d0    bsr.l    $6f1c  ; -> sub_6f1c
  00a150:  28 40                movea.l  d0, a4
  00a152:  61 ff ff ff de bc    bsr.l    $8010  ; -> GetA5
  00a158:  20 40                movea.l  d0, a0
  00a15a:  20 50                movea.l  (a0), a0
  00a15c:  b9 d0                cmpa.l   (a0), a4
  00a15e:  58 4f                addq.w   #$4, a7
  00a160:  66 60                bne.b    $a1c2  ; -> La1c2
  00a162:  70 00                moveq    #$0, d0
  00a164:  2f 00                move.l   d0, -(a7)
  00a166:  2f 0b                move.l   a3, -(a7)
  00a168:  4a 6c 00 06          tst.w    $6(a4)
  00a16c:  5d c1                slt.b    d1
  00a16e:  44 01                neg.b    d1
  00a170:  49 c1                extb.l   d1
  00a172:  2f 01                move.l   d1, -(a7)
  00a174:  48 6c 00 20          pea.l    $20(a4)
  00a178:  61 ff ff ff f0 30    bsr.l    $91aa  ; -> sub_91aa
  00a17e:  4a 00                tst.b    d0
  00a180:  4f ef 00 10          lea.l    $10(a7), a7
  00a184:  66 50                bne.b    $a1d6  ; -> La1d6
  00a186:  2f 0b                move.l   a3, -(a7)
  00a188:  48 78 0f f0          pea.l    $ff0.w
  00a18c:  61 ff ff ff cc 04    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a192:  58 8f                addq.l   #$4, a7
  00a194:  2f 00                move.l   d0, -(a7)
  00a196:  20 5f                movea.l  (a7)+, a0
  00a198:  4e 90                jsr      (a0)
  00a19a:  70 00                moveq    #$0, d0
  00a19c:  2d 40 ff f8          move.l   d0, -$8(a6)
  00a1a0:  72 02                moveq    #$2, d1
  00a1a2:  2d 41 ff fc          move.l   d1, -$4(a6)
  00a1a6:  70 01                moveq    #$1, d0
  00a1a8:  2f 00                move.l   d0, -(a7)
  00a1aa:  72 02                moveq    #$2, d1
  00a1ac:  2f 01                move.l   d1, -(a7)
  00a1ae:  48 6e ff f8          pea.l    -$8(a6)
  00a1b2:  70 2a                moveq    #$2a, d0
  00a1b4:  2f 00                move.l   d0, -(a7)
  00a1b6:  61 ff ff ff a8 0c    bsr.l    $49c4  ; -> EngineDispatch
  00a1bc:  4f ef 00 10          lea.l    $10(a7), a7
  00a1c0:  60 14                bra.b    $a1d6  ; -> La1d6
La1c2:
  00a1c2:  2f 0b                move.l   a3, -(a7)
  00a1c4:  48 78 0f f0          pea.l    $ff0.w
  00a1c8:  61 ff ff ff cb c8    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a1ce:  58 8f                addq.l   #$4, a7
  00a1d0:  2f 00                move.l   d0, -(a7)
  00a1d2:  20 5f                movea.l  (a7)+, a0
  00a1d4:  4e 90                jsr      (a0)
La1d6:
  00a1d6:  4c ee 18 00 ff f0    movem.l  -$10(a6), a3-a4
  00a1dc:  4e 5e                unlk     a6
  00a1de:  4e 74 00 04          rtd      #$4
handler_14:
  00a1e2:  4e 56 ff f4          link.w   a6, #$fff4
  00a1e6:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  00a1ea:  47 ee ff f8          lea.l    -$8(a6), a3
  00a1ee:  70 00                moveq    #$0, d0
  00a1f0:  2f 00                move.l   d0, -(a7)
  00a1f2:  61 ff ff ff cd 28    bsr.l    $6f1c  ; -> sub_6f1c
  00a1f8:  28 40                movea.l  d0, a4
  00a1fa:  7e 00                moveq    #$0, d7
  00a1fc:  20 0c                move.l   a4, d0
  00a1fe:  58 4f                addq.w   #$4, a7
  00a200:  67 76                beq.b    $a278  ; -> La278
  00a202:  61 ff ff ff de 0c    bsr.l    $8010  ; -> GetA5
  00a208:  20 40                movea.l  d0, a0
  00a20a:  20 50                movea.l  (a0), a0
  00a20c:  b9 d0                cmpa.l   (a0), a4
  00a20e:  66 68                bne.b    $a278  ; -> La278
  00a210:  3d 7c 00 01 ff f6    move.w   #$1, -$a(a6)
  00a216:  3d 7c 00 01 ff f4    move.w   #$1, -$c(a6)
  00a21c:  20 2c 00 34          move.l   $34(a4), d0
  00a220:  b0 ae ff f4          cmp.l    -$c(a6), d0
  00a224:  67 18                beq.b    $a23e  ; -> La23e
  00a226:  70 01                moveq    #$1, d0
  00a228:  2f 00                move.l   d0, -(a7)
  00a22a:  2f 00                move.l   d0, -(a7)
  00a22c:  48 6e ff f4          pea.l    -$c(a6)
  00a230:  72 35                moveq    #$35, d1
  00a232:  2f 01                move.l   d1, -(a7)
  00a234:  61 ff ff ff a7 8e    bsr.l    $49c4  ; -> EngineDispatch
  00a23a:  4f ef 00 10          lea.l    $10(a7), a7
La23e:
  00a23e:  70 00                moveq    #$0, d0
  00a240:  2f 00                move.l   d0, -(a7)
  00a242:  61 ff ff ff dd cc    bsr.l    $8010  ; -> GetA5
  00a248:  20 40                movea.l  d0, a0
  00a24a:  20 10                move.l   (a0), d0
  00a24c:  90 bc 00 00 00 ca    sub.l    #$ca, d0
  00a252:  20 40                movea.l  d0, a0
  00a254:  48 68 00 ba          pea.l    $ba(a0)
  00a258:  4a 6c 00 06          tst.w    $6(a4)
  00a25c:  5d c0                slt.b    d0
  00a25e:  44 00                neg.b    d0
  00a260:  49 c0                extb.l   d0
  00a262:  2f 00                move.l   d0, -(a7)
  00a264:  48 6c 00 3a          pea.l    $3a(a4)
  00a268:  61 ff ff ff ef 40    bsr.l    $91aa  ; -> sub_91aa
  00a26e:  4a 00                tst.b    d0
  00a270:  4f ef 00 10          lea.l    $10(a7), a7
  00a274:  66 02                bne.b    $a278  ; -> La278
  00a276:  7e 01                moveq    #$1, d7
La278:
  00a278:  48 78 10 78          pea.l    $1078.w
  00a27c:  61 ff ff ff cb 14    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a282:  58 8f                addq.l   #$4, a7
  00a284:  2f 00                move.l   d0, -(a7)
  00a286:  20 5f                movea.l  (a7)+, a0
  00a288:  4e 90                jsr      (a0)
  00a28a:  4a 87                tst.l    d7
  00a28c:  67 20                beq.b    $a2ae  ; -> La2ae
  00a28e:  70 00                moveq    #$0, d0
  00a290:  26 80                move.l   d0, (a3)
  00a292:  27 47 00 04          move.l   d7, $4(a3)
  00a296:  70 01                moveq    #$1, d0
  00a298:  2f 00                move.l   d0, -(a7)
  00a29a:  72 02                moveq    #$2, d1
  00a29c:  2f 01                move.l   d1, -(a7)
  00a29e:  2f 0b                move.l   a3, -(a7)
  00a2a0:  70 2a                moveq    #$2a, d0
  00a2a2:  2f 00                move.l   d0, -(a7)
  00a2a4:  61 ff ff ff a7 1e    bsr.l    $49c4  ; -> EngineDispatch
  00a2aa:  4f ef 00 10          lea.l    $10(a7), a7
La2ae:
  00a2ae:  4c ee 18 80 ff e8    movem.l  -$18(a6), d7/a3-a4
  00a2b4:  4e 5e                unlk     a6
  00a2b6:  4e 75                rts      
handler_42:
  00a2b8:  4e 56 00 00          link.w   a6, #$0
  00a2bc:  48 e7 01 08          movem.l  d7/a4, -(a7)
  00a2c0:  3e 2e 00 08          move.w   $8(a6), d7
  00a2c4:  70 00                moveq    #$0, d0
  00a2c6:  2f 00                move.l   d0, -(a7)
  00a2c8:  61 ff ff ff cc 52    bsr.l    $6f1c  ; -> sub_6f1c
  00a2ce:  28 40                movea.l  d0, a4
  00a2d0:  61 ff ff ff dd 3e    bsr.l    $8010  ; -> GetA5
  00a2d6:  20 40                movea.l  d0, a0
  00a2d8:  20 50                movea.l  (a0), a0
  00a2da:  b9 d0                cmpa.l   (a0), a4
  00a2dc:  58 4f                addq.w   #$4, a7
  00a2de:  66 1e                bne.b    $a2fe  ; -> La2fe
  00a2e0:  be 6c 00 58          cmp.w    $58(a4), d7
  00a2e4:  67 18                beq.b    $a2fe  ; -> La2fe
  00a2e6:  70 01                moveq    #$1, d0
  00a2e8:  2f 00                move.l   d0, -(a7)
  00a2ea:  72 00                moveq    #$0, d1
  00a2ec:  2f 01                move.l   d1, -(a7)
  00a2ee:  2f 01                move.l   d1, -(a7)
  00a2f0:  70 26                moveq    #$26, d0
  00a2f2:  2f 00                move.l   d0, -(a7)
  00a2f4:  61 ff ff ff a6 ce    bsr.l    $49c4  ; -> EngineDispatch
  00a2fa:  4f ef 00 10          lea.l    $10(a7), a7
La2fe:
  00a2fe:  3f 07                move.w   d7, -(a7)
  00a300:  48 78 0f 90          pea.l    $f90.w
  00a304:  61 ff ff ff ca 8c    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a30a:  58 8f                addq.l   #$4, a7
  00a30c:  2f 00                move.l   d0, -(a7)
  00a30e:  20 5f                movea.l  (a7)+, a0
  00a310:  4e 90                jsr      (a0)
  00a312:  4c ee 10 80 ff f8    movem.l  -$8(a6), d7/a4
  00a318:  4e 5e                unlk     a6
  00a31a:  4e 74 00 02          rtd      #$2
handler_43:
  00a31e:  4e 56 00 00          link.w   a6, #$0
  00a322:  48 78 11 68          pea.l    $1168.w
  00a326:  61 ff ff ff ca 6a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a32c:  58 8f                addq.l   #$4, a7
  00a32e:  2f 00                move.l   d0, -(a7)
  00a330:  20 5f                movea.l  (a7)+, a0
  00a332:  4e 90                jsr      (a0)
  00a334:  4e 5e                unlk     a6
  00a336:  4e 75                rts      
handler_44:
  00a338:  4e 56 00 00          link.w   a6, #$0
  00a33c:  59 8f                subq.l   #$4, a7
  00a33e:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00a342:  48 78 11 cc          pea.l    $11cc.w
  00a346:  61 ff ff ff ca 4a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a34c:  58 8f                addq.l   #$4, a7
  00a34e:  2f 00                move.l   d0, -(a7)
  00a350:  20 5f                movea.l  (a7)+, a0
  00a352:  4e 90                jsr      (a0)
  00a354:  2d 5f 00 0c          move.l   (a7)+, $c(a6)
  00a358:  4e 5e                unlk     a6
  00a35a:  4e 74 00 04          rtd      #$4
handler_45:
  00a35e:  4e 56 00 00          link.w   a6, #$0
  00a362:  59 8f                subq.l   #$4, a7
  00a364:  48 78 11 2c          pea.l    $112c.w
  00a368:  61 ff ff ff ca 28    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a36e:  58 8f                addq.l   #$4, a7
  00a370:  2f 00                move.l   d0, -(a7)
  00a372:  20 5f                movea.l  (a7)+, a0
  00a374:  4e 90                jsr      (a0)
  00a376:  2d 5f 00 08          move.l   (a7)+, $8(a6)
  00a37a:  4e 5e                unlk     a6
  00a37c:  4e 75                rts      
handler_78:
  00a37e:  4e 56 ff f8          link.w   a6, #$fff8
  00a382:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  00a386:  28 6e 00 08          movea.l  $8(a6), a4
  00a38a:  20 78 08 88          movea.l  $888.w, a0
  00a38e:  20 50                movea.l  (a0), a0
  00a390:  20 50                movea.l  (a0), a0
  00a392:  20 68 02 14          movea.l  $214(a0), a0
  00a396:  26 50                movea.l  (a0), a3
  00a398:  4a ab 00 c8          tst.l    $c8(a3)
  00a39c:  67 00 00 a6          beq.w    $a444  ; -> La444
  00a3a0:  20 6b 01 20          movea.l  $120(a3), a0
  00a3a4:  20 50                movea.l  (a0), a0
  00a3a6:  54 88                addq.l   #$2, a0
  00a3a8:  b1 cc                cmpa.l   a4, a0
  00a3aa:  57 c0                seq.b    d0
  00a3ac:  44 00                neg.b    d0
  00a3ae:  49 c0                extb.l   d0
  00a3b0:  1e 00                move.b   d0, d7
  00a3b2:  20 6b 01 24          movea.l  $124(a3), a0
  00a3b6:  20 50                movea.l  (a0), a0
  00a3b8:  54 88                addq.l   #$2, a0
  00a3ba:  b1 cc                cmpa.l   a4, a0
  00a3bc:  57 c0                seq.b    d0
  00a3be:  44 00                neg.b    d0
  00a3c0:  49 c0                extb.l   d0
  00a3c2:  1c 00                move.b   d0, d6
  00a3c4:  4a 07                tst.b    d7
  00a3c6:  66 04                bne.b    $a3cc  ; -> La3cc
  00a3c8:  4a 06                tst.b    d6
  00a3ca:  67 78                beq.b    $a444  ; -> La444
La3cc:
  00a3cc:  41 ee ff f8          lea.l    -$8(a6), a0
  00a3d0:  22 4c                movea.l  a4, a1
  00a3d2:  20 d9                move.l   (a1)+, (a0)+
  00a3d4:  20 d9                move.l   (a1)+, (a0)+
  00a3d6:  55 8f                subq.l   #$2, a7
  00a3d8:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00a3dc:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00a3e0:  2f 0c                move.l   a4, -(a7)
  00a3e2:  48 78 10 a8          pea.l    $10a8.w
  00a3e6:  61 ff ff ff c9 aa    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a3ec:  58 8f                addq.l   #$4, a7
  00a3ee:  2f 00                move.l   d0, -(a7)
  00a3f0:  20 5f                movea.l  (a7)+, a0
  00a3f2:  4e 90                jsr      (a0)
  00a3f4:  1c 1f                move.b   (a7)+, d6
  00a3f6:  20 2e ff f8          move.l   -$8(a6), d0
  00a3fa:  b0 94                cmp.l    (a4), d0
  00a3fc:  66 0a                bne.b    $a408  ; -> La408
  00a3fe:  20 2e ff fc          move.l   -$4(a6), d0
  00a402:  b0 ac 00 04          cmp.l    $4(a4), d0
  00a406:  67 36                beq.b    $a43e  ; -> La43e
La408:
  00a408:  4a 07                tst.b    d7
  00a40a:  67 1a                beq.b    $a426  ; -> La426
  00a40c:  70 01                moveq    #$1, d0
  00a40e:  2f 00                move.l   d0, -(a7)
  00a410:  2f 00                move.l   d0, -(a7)
  00a412:  48 6b 01 20          pea.l    $120(a3)
  00a416:  72 10                moveq    #$10, d1
  00a418:  2f 01                move.l   d1, -(a7)
  00a41a:  61 ff ff ff a5 a8    bsr.l    $49c4  ; -> EngineDispatch
  00a420:  4f ef 00 10          lea.l    $10(a7), a7
  00a424:  60 18                bra.b    $a43e  ; -> La43e
La426:
  00a426:  70 01                moveq    #$1, d0
  00a428:  2f 00                move.l   d0, -(a7)
  00a42a:  2f 00                move.l   d0, -(a7)
  00a42c:  48 6b 01 24          pea.l    $124(a3)
  00a430:  72 32                moveq    #$32, d1
  00a432:  2f 01                move.l   d1, -(a7)
  00a434:  61 ff ff ff a5 8e    bsr.l    $49c4  ; -> EngineDispatch
  00a43a:  4f ef 00 10          lea.l    $10(a7), a7
La43e:
  00a43e:  1d 46 00 14          move.b   d6, $14(a6)
  00a442:  60 22                bra.b    $a466  ; -> La466
La444:
  00a444:  55 8f                subq.l   #$2, a7
  00a446:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00a44a:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00a44e:  2f 0c                move.l   a4, -(a7)
  00a450:  48 78 10 a8          pea.l    $10a8.w
  00a454:  61 ff ff ff c9 3c    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a45a:  58 8f                addq.l   #$4, a7
  00a45c:  2f 00                move.l   d0, -(a7)
  00a45e:  20 5f                movea.l  (a7)+, a0
  00a460:  4e 90                jsr      (a0)
  00a462:  1d 5f 00 14          move.b   (a7)+, $14(a6)
La466:
  00a466:  4c ee 18 c0 ff e8    movem.l  -$18(a6), d6-d7/a3-a4
  00a46c:  4e 5e                unlk     a6
  00a46e:  4e 74 00 0c          rtd      #$c
handler_46:
  00a472:  4e 56 00 00          link.w   a6, #$0
  00a476:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00a47a:  26 6e 00 0c          movea.l  $c(a6), a3
  00a47e:  20 78 08 88          movea.l  $888.w, a0
  00a482:  20 50                movea.l  (a0), a0
  00a484:  20 50                movea.l  (a0), a0
  00a486:  28 68 02 14          movea.l  $214(a0), a4
  00a48a:  55 8f                subq.l   #$2, a7
  00a48c:  2f 0b                move.l   a3, -(a7)
  00a48e:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00a492:  a8 e3                dc.w     $a8e3  ; _EqualRgn
  00a494:  4a 1f                tst.b    (a7)+
  00a496:  66 62                bne.b    $a4fa  ; -> La4fa
  00a498:  2f 0b                move.l   a3, -(a7)
  00a49a:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00a49e:  48 78 11 70          pea.l    $1170.w
  00a4a2:  61 ff ff ff c8 ee    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a4a8:  58 8f                addq.l   #$4, a7
  00a4aa:  2f 00                move.l   d0, -(a7)
  00a4ac:  20 5f                movea.l  (a7)+, a0
  00a4ae:  4e 90                jsr      (a0)
  00a4b0:  20 54                movea.l  (a4), a0
  00a4b2:  20 2e 00 08          move.l   $8(a6), d0
  00a4b6:  b0 a8 01 20          cmp.l    $120(a0), d0
  00a4ba:  66 1a                bne.b    $a4d6  ; -> La4d6
  00a4bc:  70 01                moveq    #$1, d0
  00a4be:  2f 00                move.l   d0, -(a7)
  00a4c0:  2f 00                move.l   d0, -(a7)
  00a4c2:  48 6e 00 08          pea.l    $8(a6)
  00a4c6:  72 10                moveq    #$10, d1
  00a4c8:  2f 01                move.l   d1, -(a7)
  00a4ca:  61 ff ff ff a4 f8    bsr.l    $49c4  ; -> EngineDispatch
  00a4d0:  4f ef 00 10          lea.l    $10(a7), a7
  00a4d4:  60 24                bra.b    $a4fa  ; -> La4fa
La4d6:
  00a4d6:  20 54                movea.l  (a4), a0
  00a4d8:  20 2e 00 08          move.l   $8(a6), d0
  00a4dc:  b0 a8 01 24          cmp.l    $124(a0), d0
  00a4e0:  66 18                bne.b    $a4fa  ; -> La4fa
  00a4e2:  70 01                moveq    #$1, d0
  00a4e4:  2f 00                move.l   d0, -(a7)
  00a4e6:  2f 00                move.l   d0, -(a7)
  00a4e8:  48 6e 00 08          pea.l    $8(a6)
  00a4ec:  72 32                moveq    #$32, d1
  00a4ee:  2f 01                move.l   d1, -(a7)
  00a4f0:  61 ff ff ff a4 d2    bsr.l    $49c4  ; -> EngineDispatch
  00a4f6:  4f ef 00 10          lea.l    $10(a7), a7
La4fa:
  00a4fa:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  00a500:  4e 5e                unlk     a6
  00a502:  4e 74 00 08          rtd      #$8
handler_63:
  00a506:  4e 56 ff fc          link.w   a6, #$fffc
  00a50a:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00a50e:  20 78 08 88          movea.l  $888.w, a0
  00a512:  20 50                movea.l  (a0), a0
  00a514:  20 50                movea.l  (a0), a0
  00a516:  2d 68 02 14 ff fc    move.l   $214(a0), -$4(a6)
  00a51c:  20 6e 00 08          movea.l  $8(a6), a0
  00a520:  26 50                movea.l  (a0), a3
  00a522:  49 eb 00 02          lea.l    $2(a3), a4
  00a526:  70 0a                moveq    #$a, d0
  00a528:  b0 53                cmp.w    (a3), d0
  00a52a:  66 0a                bne.b    $a536  ; -> La536
  00a52c:  4a 94                tst.l    (a4)
  00a52e:  66 06                bne.b    $a536  ; -> La536
  00a530:  4a ac 00 04          tst.l    $4(a4)
  00a534:  67 68                beq.b    $a59e  ; -> La59e
La536:
  00a536:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00a53a:  48 78 11 74          pea.l    $1174.w
  00a53e:  61 ff ff ff c8 52    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a544:  58 8f                addq.l   #$4, a7
  00a546:  2f 00                move.l   d0, -(a7)
  00a548:  20 5f                movea.l  (a7)+, a0
  00a54a:  4e 90                jsr      (a0)
  00a54c:  20 6e ff fc          movea.l  -$4(a6), a0
  00a550:  20 50                movea.l  (a0), a0
  00a552:  20 2e 00 08          move.l   $8(a6), d0
  00a556:  b0 a8 01 20          cmp.l    $120(a0), d0
  00a55a:  66 1a                bne.b    $a576  ; -> La576
  00a55c:  70 01                moveq    #$1, d0
  00a55e:  2f 00                move.l   d0, -(a7)
  00a560:  2f 00                move.l   d0, -(a7)
  00a562:  48 6e 00 08          pea.l    $8(a6)
  00a566:  72 10                moveq    #$10, d1
  00a568:  2f 01                move.l   d1, -(a7)
  00a56a:  61 ff ff ff a4 58    bsr.l    $49c4  ; -> EngineDispatch
  00a570:  4f ef 00 10          lea.l    $10(a7), a7
  00a574:  60 28                bra.b    $a59e  ; -> La59e
La576:
  00a576:  20 6e ff fc          movea.l  -$4(a6), a0
  00a57a:  20 50                movea.l  (a0), a0
  00a57c:  20 2e 00 08          move.l   $8(a6), d0
  00a580:  b0 a8 01 24          cmp.l    $124(a0), d0
  00a584:  66 18                bne.b    $a59e  ; -> La59e
  00a586:  70 01                moveq    #$1, d0
  00a588:  2f 00                move.l   d0, -(a7)
  00a58a:  2f 00                move.l   d0, -(a7)
  00a58c:  48 6e 00 08          pea.l    $8(a6)
  00a590:  72 32                moveq    #$32, d1
  00a592:  2f 01                move.l   d1, -(a7)
  00a594:  61 ff ff ff a4 2e    bsr.l    $49c4  ; -> EngineDispatch
  00a59a:  4f ef 00 10          lea.l    $10(a7), a7
La59e:
  00a59e:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  00a5a4:  4e 5e                unlk     a6
  00a5a6:  4e 74 00 04          rtd      #$4
handler_47:
  00a5aa:  4e 56 ff fc          link.w   a6, #$fffc
  00a5ae:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  00a5b2:  38 2e 00 08          move.w   $8(a6), d4
  00a5b6:  3a 2e 00 0a          move.w   $a(a6), d5
  00a5ba:  3c 2e 00 0c          move.w   $c(a6), d6
  00a5be:  3e 2e 00 0e          move.w   $e(a6), d7
  00a5c2:  20 78 08 88          movea.l  $888.w, a0
  00a5c6:  20 50                movea.l  (a0), a0
  00a5c8:  20 50                movea.l  (a0), a0
  00a5ca:  2d 68 02 14 ff fc    move.l   $214(a0), -$4(a6)
  00a5d0:  20 6e 00 10          movea.l  $10(a6), a0
  00a5d4:  26 50                movea.l  (a0), a3
  00a5d6:  49 eb 00 02          lea.l    $2(a3), a4
  00a5da:  70 0a                moveq    #$a, d0
  00a5dc:  b0 53                cmp.w    (a3), d0
  00a5de:  66 16                bne.b    $a5f6  ; -> La5f6
  00a5e0:  be 6c 00 02          cmp.w    $2(a4), d7
  00a5e4:  66 10                bne.b    $a5f6  ; -> La5f6
  00a5e6:  bc 54                cmp.w    (a4), d6
  00a5e8:  66 0c                bne.b    $a5f6  ; -> La5f6
  00a5ea:  ba 6c 00 06          cmp.w    $6(a4), d5
  00a5ee:  66 06                bne.b    $a5f6  ; -> La5f6
  00a5f0:  b8 6c 00 04          cmp.w    $4(a4), d4
  00a5f4:  67 70                beq.b    $a666  ; -> La666
La5f6:
  00a5f6:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00a5fa:  3f 07                move.w   d7, -(a7)
  00a5fc:  3f 06                move.w   d6, -(a7)
  00a5fe:  3f 05                move.w   d5, -(a7)
  00a600:  3f 04                move.w   d4, -(a7)
  00a602:  48 78 11 78          pea.l    $1178.w
  00a606:  61 ff ff ff c7 8a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a60c:  58 8f                addq.l   #$4, a7
  00a60e:  2f 00                move.l   d0, -(a7)
  00a610:  20 5f                movea.l  (a7)+, a0
  00a612:  4e 90                jsr      (a0)
  00a614:  20 6e ff fc          movea.l  -$4(a6), a0
  00a618:  20 50                movea.l  (a0), a0
  00a61a:  20 2e 00 10          move.l   $10(a6), d0
  00a61e:  b0 a8 01 20          cmp.l    $120(a0), d0
  00a622:  66 1a                bne.b    $a63e  ; -> La63e
  00a624:  70 01                moveq    #$1, d0
  00a626:  2f 00                move.l   d0, -(a7)
  00a628:  2f 00                move.l   d0, -(a7)
  00a62a:  48 6e 00 10          pea.l    $10(a6)
  00a62e:  72 10                moveq    #$10, d1
  00a630:  2f 01                move.l   d1, -(a7)
  00a632:  61 ff ff ff a3 90    bsr.l    $49c4  ; -> EngineDispatch
  00a638:  4f ef 00 10          lea.l    $10(a7), a7
  00a63c:  60 28                bra.b    $a666  ; -> La666
La63e:
  00a63e:  20 6e ff fc          movea.l  -$4(a6), a0
  00a642:  20 50                movea.l  (a0), a0
  00a644:  20 2e 00 10          move.l   $10(a6), d0
  00a648:  b0 a8 01 24          cmp.l    $124(a0), d0
  00a64c:  66 18                bne.b    $a666  ; -> La666
  00a64e:  70 01                moveq    #$1, d0
  00a650:  2f 00                move.l   d0, -(a7)
  00a652:  2f 00                move.l   d0, -(a7)
  00a654:  48 6e 00 10          pea.l    $10(a6)
  00a658:  72 32                moveq    #$32, d1
  00a65a:  2f 01                move.l   d1, -(a7)
  00a65c:  61 ff ff ff a3 66    bsr.l    $49c4  ; -> EngineDispatch
  00a662:  4f ef 00 10          lea.l    $10(a7), a7
La666:
  00a666:  4c ee 18 f0 ff e4    movem.l  -$1c(a6), d4-d7/a3-a4
  00a66c:  4e 5e                unlk     a6
  00a66e:  4e 74 00 0c          rtd      #$c
handler_48:
  00a672:  4e 56 ff f8          link.w   a6, #$fff8
  00a676:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00a67a:  28 6e 00 08          movea.l  $8(a6), a4
  00a67e:  20 78 08 88          movea.l  $888.w, a0
  00a682:  20 50                movea.l  (a0), a0
  00a684:  20 50                movea.l  (a0), a0
  00a686:  2d 68 02 14 ff f8    move.l   $214(a0), -$8(a6)
  00a68c:  20 6e 00 0c          movea.l  $c(a6), a0
  00a690:  20 50                movea.l  (a0), a0
  00a692:  2d 48 ff fc          move.l   a0, -$4(a6)
  00a696:  47 e8 00 02          lea.l    $2(a0), a3
  00a69a:  70 0a                moveq    #$a, d0
  00a69c:  b0 50                cmp.w    (a0), d0
  00a69e:  66 10                bne.b    $a6b0  ; -> La6b0
  00a6a0:  20 13                move.l   (a3), d0
  00a6a2:  b0 94                cmp.l    (a4), d0
  00a6a4:  66 0a                bne.b    $a6b0  ; -> La6b0
  00a6a6:  20 2b 00 04          move.l   $4(a3), d0
  00a6aa:  b0 ac 00 04          cmp.l    $4(a4), d0
  00a6ae:  67 6a                beq.b    $a71a  ; -> La71a
La6b0:
  00a6b0:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00a6b4:  2f 0c                move.l   a4, -(a7)
  00a6b6:  48 78 11 7c          pea.l    $117c.w
  00a6ba:  61 ff ff ff c6 d6    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a6c0:  58 8f                addq.l   #$4, a7
  00a6c2:  2f 00                move.l   d0, -(a7)
  00a6c4:  20 5f                movea.l  (a7)+, a0
  00a6c6:  4e 90                jsr      (a0)
  00a6c8:  20 6e ff f8          movea.l  -$8(a6), a0
  00a6cc:  20 50                movea.l  (a0), a0
  00a6ce:  20 2e 00 0c          move.l   $c(a6), d0
  00a6d2:  b0 a8 01 20          cmp.l    $120(a0), d0
  00a6d6:  66 1a                bne.b    $a6f2  ; -> La6f2
  00a6d8:  70 01                moveq    #$1, d0
  00a6da:  2f 00                move.l   d0, -(a7)
  00a6dc:  2f 00                move.l   d0, -(a7)
  00a6de:  48 6e 00 0c          pea.l    $c(a6)
  00a6e2:  72 10                moveq    #$10, d1
  00a6e4:  2f 01                move.l   d1, -(a7)
  00a6e6:  61 ff ff ff a2 dc    bsr.l    $49c4  ; -> EngineDispatch
  00a6ec:  4f ef 00 10          lea.l    $10(a7), a7
  00a6f0:  60 28                bra.b    $a71a  ; -> La71a
La6f2:
  00a6f2:  20 6e ff f8          movea.l  -$8(a6), a0
  00a6f6:  20 50                movea.l  (a0), a0
  00a6f8:  20 2e 00 0c          move.l   $c(a6), d0
  00a6fc:  b0 a8 01 24          cmp.l    $124(a0), d0
  00a700:  66 18                bne.b    $a71a  ; -> La71a
  00a702:  70 01                moveq    #$1, d0
  00a704:  2f 00                move.l   d0, -(a7)
  00a706:  2f 00                move.l   d0, -(a7)
  00a708:  48 6e 00 0c          pea.l    $c(a6)
  00a70c:  72 32                moveq    #$32, d1
  00a70e:  2f 01                move.l   d1, -(a7)
  00a710:  61 ff ff ff a2 b2    bsr.l    $49c4  ; -> EngineDispatch
  00a716:  4f ef 00 10          lea.l    $10(a7), a7
La71a:
  00a71a:  4c ee 18 00 ff f0    movem.l  -$10(a6), a3-a4
  00a720:  4e 5e                unlk     a6
  00a722:  4e 74 00 08          rtd      #$8
handler_49:
  00a726:  4e 56 00 00          link.w   a6, #$0
  00a72a:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  00a72e:  3c 2e 00 08          move.w   $8(a6), d6
  00a732:  3e 2e 00 0a          move.w   $a(a6), d7
  00a736:  20 78 08 88          movea.l  $888.w, a0
  00a73a:  20 50                movea.l  (a0), a0
  00a73c:  20 50                movea.l  (a0), a0
  00a73e:  26 68 02 14          movea.l  $214(a0), a3
  00a742:  4a 47                tst.w    d7
  00a744:  66 06                bne.b    $a74c  ; -> La74c
  00a746:  4a 46                tst.w    d6
  00a748:  67 00 00 ca          beq.w    $a814  ; -> La814
La74c:
  00a74c:  20 53                movea.l  (a3), a0
  00a74e:  20 2e 00 0c          move.l   $c(a6), d0
  00a752:  b0 a8 01 20          cmp.l    $120(a0), d0
  00a756:  57 c0                seq.b    d0
  00a758:  44 00                neg.b    d0
  00a75a:  49 c0                extb.l   d0
  00a75c:  1a 00                move.b   d0, d5
  00a75e:  20 2e 00 0c          move.l   $c(a6), d0
  00a762:  b0 a8 01 24          cmp.l    $124(a0), d0
  00a766:  57 c0                seq.b    d0
  00a768:  44 00                neg.b    d0
  00a76a:  49 c0                extb.l   d0
  00a76c:  18 00                move.b   d0, d4
  00a76e:  4a 05                tst.b    d5
  00a770:  66 06                bne.b    $a778  ; -> La778
  00a772:  4a 04                tst.b    d4
  00a774:  67 00 00 84          beq.w    $a7fa  ; -> La7fa
La778:
  00a778:  59 8f                subq.l   #$4, a7
  00a77a:  a8 d8                dc.w     $a8d8  ; _NewRgn
  00a77c:  28 5f                movea.l  (a7)+, a4
  00a77e:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00a782:  2f 0c                move.l   a4, -(a7)
  00a784:  48 78 11 70          pea.l    $1170.w
  00a788:  61 ff ff ff c6 08    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a78e:  58 8f                addq.l   #$4, a7
  00a790:  2f 00                move.l   d0, -(a7)
  00a792:  20 5f                movea.l  (a7)+, a0
  00a794:  4e 90                jsr      (a0)
  00a796:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00a79a:  3f 07                move.w   d7, -(a7)
  00a79c:  3f 06                move.w   d6, -(a7)
  00a79e:  48 78 11 80          pea.l    $1180.w
  00a7a2:  61 ff ff ff c5 ee    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a7a8:  58 8f                addq.l   #$4, a7
  00a7aa:  2f 00                move.l   d0, -(a7)
  00a7ac:  20 5f                movea.l  (a7)+, a0
  00a7ae:  4e 90                jsr      (a0)
  00a7b0:  55 8f                subq.l   #$2, a7
  00a7b2:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00a7b6:  2f 0c                move.l   a4, -(a7)
  00a7b8:  a8 e3                dc.w     $a8e3  ; _EqualRgn
  00a7ba:  4a 1f                tst.b    (a7)+
  00a7bc:  66 36                bne.b    $a7f4  ; -> La7f4
  00a7be:  4a 05                tst.b    d5
  00a7c0:  67 1a                beq.b    $a7dc  ; -> La7dc
  00a7c2:  70 01                moveq    #$1, d0
  00a7c4:  2f 00                move.l   d0, -(a7)
  00a7c6:  2f 00                move.l   d0, -(a7)
  00a7c8:  48 6e 00 0c          pea.l    $c(a6)
  00a7cc:  72 10                moveq    #$10, d1
  00a7ce:  2f 01                move.l   d1, -(a7)
  00a7d0:  61 ff ff ff a1 f2    bsr.l    $49c4  ; -> EngineDispatch
  00a7d6:  4f ef 00 10          lea.l    $10(a7), a7
  00a7da:  60 18                bra.b    $a7f4  ; -> La7f4
La7dc:
  00a7dc:  70 01                moveq    #$1, d0
  00a7de:  2f 00                move.l   d0, -(a7)
  00a7e0:  2f 00                move.l   d0, -(a7)
  00a7e2:  48 6e 00 0c          pea.l    $c(a6)
  00a7e6:  72 32                moveq    #$32, d1
  00a7e8:  2f 01                move.l   d1, -(a7)
  00a7ea:  61 ff ff ff a1 d8    bsr.l    $49c4  ; -> EngineDispatch
  00a7f0:  4f ef 00 10          lea.l    $10(a7), a7
La7f4:
  00a7f4:  2f 0c                move.l   a4, -(a7)
  00a7f6:  a8 d9                dc.w     $a8d9  ; _DisposRgn
  00a7f8:  60 1a                bra.b    $a814  ; -> La814
La7fa:
  00a7fa:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00a7fe:  3f 07                move.w   d7, -(a7)
  00a800:  3f 06                move.w   d6, -(a7)
  00a802:  48 78 11 80          pea.l    $1180.w
  00a806:  61 ff ff ff c5 8a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a80c:  58 8f                addq.l   #$4, a7
  00a80e:  2f 00                move.l   d0, -(a7)
  00a810:  20 5f                movea.l  (a7)+, a0
  00a812:  4e 90                jsr      (a0)
La814:
  00a814:  4c ee 18 f0 ff e8    movem.l  -$18(a6), d4-d7/a3-a4
  00a81a:  4e 5e                unlk     a6
  00a81c:  4e 74 00 08          rtd      #$8
handler_50:
  00a820:  4e 56 00 00          link.w   a6, #$0
  00a824:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  00a828:  3c 2e 00 08          move.w   $8(a6), d6
  00a82c:  3e 2e 00 0a          move.w   $a(a6), d7
  00a830:  20 78 08 88          movea.l  $888.w, a0
  00a834:  20 50                movea.l  (a0), a0
  00a836:  20 50                movea.l  (a0), a0
  00a838:  26 68 02 14          movea.l  $214(a0), a3
  00a83c:  4a 47                tst.w    d7
  00a83e:  66 06                bne.b    $a846  ; -> La846
  00a840:  4a 46                tst.w    d6
  00a842:  67 00 00 ca          beq.w    $a90e  ; -> La90e
La846:
  00a846:  20 53                movea.l  (a3), a0
  00a848:  20 2e 00 0c          move.l   $c(a6), d0
  00a84c:  b0 a8 01 20          cmp.l    $120(a0), d0
  00a850:  57 c0                seq.b    d0
  00a852:  44 00                neg.b    d0
  00a854:  49 c0                extb.l   d0
  00a856:  1a 00                move.b   d0, d5
  00a858:  20 2e 00 0c          move.l   $c(a6), d0
  00a85c:  b0 a8 01 24          cmp.l    $124(a0), d0
  00a860:  57 c0                seq.b    d0
  00a862:  44 00                neg.b    d0
  00a864:  49 c0                extb.l   d0
  00a866:  18 00                move.b   d0, d4
  00a868:  4a 05                tst.b    d5
  00a86a:  66 06                bne.b    $a872  ; -> La872
  00a86c:  4a 04                tst.b    d4
  00a86e:  67 00 00 84          beq.w    $a8f4  ; -> La8f4
La872:
  00a872:  59 8f                subq.l   #$4, a7
  00a874:  a8 d8                dc.w     $a8d8  ; _NewRgn
  00a876:  28 5f                movea.l  (a7)+, a4
  00a878:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00a87c:  2f 0c                move.l   a4, -(a7)
  00a87e:  48 78 11 70          pea.l    $1170.w
  00a882:  61 ff ff ff c5 0e    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a888:  58 8f                addq.l   #$4, a7
  00a88a:  2f 00                move.l   d0, -(a7)
  00a88c:  20 5f                movea.l  (a7)+, a0
  00a88e:  4e 90                jsr      (a0)
  00a890:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00a894:  3f 07                move.w   d7, -(a7)
  00a896:  3f 06                move.w   d6, -(a7)
  00a898:  48 78 11 84          pea.l    $1184.w
  00a89c:  61 ff ff ff c4 f4    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a8a2:  58 8f                addq.l   #$4, a7
  00a8a4:  2f 00                move.l   d0, -(a7)
  00a8a6:  20 5f                movea.l  (a7)+, a0
  00a8a8:  4e 90                jsr      (a0)
  00a8aa:  55 8f                subq.l   #$2, a7
  00a8ac:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00a8b0:  2f 0c                move.l   a4, -(a7)
  00a8b2:  a8 e3                dc.w     $a8e3  ; _EqualRgn
  00a8b4:  4a 1f                tst.b    (a7)+
  00a8b6:  66 36                bne.b    $a8ee  ; -> La8ee
  00a8b8:  4a 05                tst.b    d5
  00a8ba:  67 1a                beq.b    $a8d6  ; -> La8d6
  00a8bc:  70 01                moveq    #$1, d0
  00a8be:  2f 00                move.l   d0, -(a7)
  00a8c0:  2f 00                move.l   d0, -(a7)
  00a8c2:  48 6e 00 0c          pea.l    $c(a6)
  00a8c6:  72 10                moveq    #$10, d1
  00a8c8:  2f 01                move.l   d1, -(a7)
  00a8ca:  61 ff ff ff a0 f8    bsr.l    $49c4  ; -> EngineDispatch
  00a8d0:  4f ef 00 10          lea.l    $10(a7), a7
  00a8d4:  60 18                bra.b    $a8ee  ; -> La8ee
La8d6:
  00a8d6:  70 01                moveq    #$1, d0
  00a8d8:  2f 00                move.l   d0, -(a7)
  00a8da:  2f 00                move.l   d0, -(a7)
  00a8dc:  48 6e 00 0c          pea.l    $c(a6)
  00a8e0:  72 32                moveq    #$32, d1
  00a8e2:  2f 01                move.l   d1, -(a7)
  00a8e4:  61 ff ff ff a0 de    bsr.l    $49c4  ; -> EngineDispatch
  00a8ea:  4f ef 00 10          lea.l    $10(a7), a7
La8ee:
  00a8ee:  2f 0c                move.l   a4, -(a7)
  00a8f0:  a8 d9                dc.w     $a8d9  ; _DisposRgn
  00a8f2:  60 1a                bra.b    $a90e  ; -> La90e
La8f4:
  00a8f4:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00a8f8:  3f 07                move.w   d7, -(a7)
  00a8fa:  3f 06                move.w   d6, -(a7)
  00a8fc:  48 78 11 84          pea.l    $1184.w
  00a900:  61 ff ff ff c4 90    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a906:  58 8f                addq.l   #$4, a7
  00a908:  2f 00                move.l   d0, -(a7)
  00a90a:  20 5f                movea.l  (a7)+, a0
  00a90c:  4e 90                jsr      (a0)
La90e:
  00a90e:  4c ee 18 f0 ff e8    movem.l  -$18(a6), d4-d7/a3-a4
  00a914:  4e 5e                unlk     a6
  00a916:  4e 74 00 08          rtd      #$8
handler_51:
  00a91a:  4e 56 00 00          link.w   a6, #$0
  00a91e:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  00a922:  20 78 08 88          movea.l  $888.w, a0
  00a926:  20 50                movea.l  (a0), a0
  00a928:  20 50                movea.l  (a0), a0
  00a92a:  26 68 02 14          movea.l  $214(a0), a3
  00a92e:  20 53                movea.l  (a3), a0
  00a930:  20 2e 00 08          move.l   $8(a6), d0
  00a934:  b0 a8 01 20          cmp.l    $120(a0), d0
  00a938:  57 c0                seq.b    d0
  00a93a:  44 00                neg.b    d0
  00a93c:  49 c0                extb.l   d0
  00a93e:  1e 00                move.b   d0, d7
  00a940:  20 2e 00 08          move.l   $8(a6), d0
  00a944:  b0 a8 01 24          cmp.l    $124(a0), d0
  00a948:  57 c0                seq.b    d0
  00a94a:  44 00                neg.b    d0
  00a94c:  49 c0                extb.l   d0
  00a94e:  1c 00                move.b   d0, d6
  00a950:  4a 07                tst.b    d7
  00a952:  66 06                bne.b    $a95a  ; -> La95a
  00a954:  4a 06                tst.b    d6
  00a956:  67 00 00 88          beq.w    $a9e0  ; -> La9e0
La95a:
  00a95a:  59 8f                subq.l   #$4, a7
  00a95c:  a8 d8                dc.w     $a8d8  ; _NewRgn
  00a95e:  28 5f                movea.l  (a7)+, a4
  00a960:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00a964:  2f 0c                move.l   a4, -(a7)
  00a966:  48 78 11 70          pea.l    $1170.w
  00a96a:  61 ff ff ff c4 26    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a970:  58 8f                addq.l   #$4, a7
  00a972:  2f 00                move.l   d0, -(a7)
  00a974:  20 5f                movea.l  (a7)+, a0
  00a976:  4e 90                jsr      (a0)
  00a978:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00a97c:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00a980:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00a984:  48 78 11 90          pea.l    $1190.w
  00a988:  61 ff ff ff c4 08    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a98e:  58 8f                addq.l   #$4, a7
  00a990:  2f 00                move.l   d0, -(a7)
  00a992:  20 5f                movea.l  (a7)+, a0
  00a994:  4e 90                jsr      (a0)
  00a996:  55 8f                subq.l   #$2, a7
  00a998:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00a99c:  2f 0c                move.l   a4, -(a7)
  00a99e:  a8 e3                dc.w     $a8e3  ; _EqualRgn
  00a9a0:  4a 1f                tst.b    (a7)+
  00a9a2:  66 36                bne.b    $a9da  ; -> La9da
  00a9a4:  4a 07                tst.b    d7
  00a9a6:  67 1a                beq.b    $a9c2  ; -> La9c2
  00a9a8:  70 01                moveq    #$1, d0
  00a9aa:  2f 00                move.l   d0, -(a7)
  00a9ac:  2f 00                move.l   d0, -(a7)
  00a9ae:  48 6e 00 08          pea.l    $8(a6)
  00a9b2:  72 10                moveq    #$10, d1
  00a9b4:  2f 01                move.l   d1, -(a7)
  00a9b6:  61 ff ff ff a0 0c    bsr.l    $49c4  ; -> EngineDispatch
  00a9bc:  4f ef 00 10          lea.l    $10(a7), a7
  00a9c0:  60 18                bra.b    $a9da  ; -> La9da
La9c2:
  00a9c2:  70 01                moveq    #$1, d0
  00a9c4:  2f 00                move.l   d0, -(a7)
  00a9c6:  2f 00                move.l   d0, -(a7)
  00a9c8:  48 6e 00 08          pea.l    $8(a6)
  00a9cc:  72 32                moveq    #$32, d1
  00a9ce:  2f 01                move.l   d1, -(a7)
  00a9d0:  61 ff ff ff 9f f2    bsr.l    $49c4  ; -> EngineDispatch
  00a9d6:  4f ef 00 10          lea.l    $10(a7), a7
La9da:
  00a9da:  2f 0c                move.l   a4, -(a7)
  00a9dc:  a8 d9                dc.w     $a8d9  ; _DisposRgn
  00a9de:  60 1e                bra.b    $a9fe  ; -> La9fe
La9e0:
  00a9e0:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00a9e4:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00a9e8:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00a9ec:  48 78 11 90          pea.l    $1190.w
  00a9f0:  61 ff ff ff c3 a0    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00a9f6:  58 8f                addq.l   #$4, a7
  00a9f8:  2f 00                move.l   d0, -(a7)
  00a9fa:  20 5f                movea.l  (a7)+, a0
  00a9fc:  4e 90                jsr      (a0)
La9fe:
  00a9fe:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  00aa04:  4e 5e                unlk     a6
  00aa06:  4e 74 00 0c          rtd      #$c
handler_52:
  00aa0a:  4e 56 00 00          link.w   a6, #$0
  00aa0e:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  00aa12:  20 78 08 88          movea.l  $888.w, a0
  00aa16:  20 50                movea.l  (a0), a0
  00aa18:  20 50                movea.l  (a0), a0
  00aa1a:  26 68 02 14          movea.l  $214(a0), a3
  00aa1e:  20 53                movea.l  (a3), a0
  00aa20:  20 2e 00 08          move.l   $8(a6), d0
  00aa24:  b0 a8 01 20          cmp.l    $120(a0), d0
  00aa28:  57 c0                seq.b    d0
  00aa2a:  44 00                neg.b    d0
  00aa2c:  49 c0                extb.l   d0
  00aa2e:  1e 00                move.b   d0, d7
  00aa30:  20 2e 00 08          move.l   $8(a6), d0
  00aa34:  b0 a8 01 24          cmp.l    $124(a0), d0
  00aa38:  57 c0                seq.b    d0
  00aa3a:  44 00                neg.b    d0
  00aa3c:  49 c0                extb.l   d0
  00aa3e:  1c 00                move.b   d0, d6
  00aa40:  4a 07                tst.b    d7
  00aa42:  66 06                bne.b    $aa4a  ; -> Laa4a
  00aa44:  4a 06                tst.b    d6
  00aa46:  67 00 00 88          beq.w    $aad0  ; -> Laad0
Laa4a:
  00aa4a:  59 8f                subq.l   #$4, a7
  00aa4c:  a8 d8                dc.w     $a8d8  ; _NewRgn
  00aa4e:  28 5f                movea.l  (a7)+, a4
  00aa50:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00aa54:  2f 0c                move.l   a4, -(a7)
  00aa56:  48 78 11 70          pea.l    $1170.w
  00aa5a:  61 ff ff ff c3 36    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00aa60:  58 8f                addq.l   #$4, a7
  00aa62:  2f 00                move.l   d0, -(a7)
  00aa64:  20 5f                movea.l  (a7)+, a0
  00aa66:  4e 90                jsr      (a0)
  00aa68:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00aa6c:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00aa70:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00aa74:  48 78 11 94          pea.l    $1194.w
  00aa78:  61 ff ff ff c3 18    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00aa7e:  58 8f                addq.l   #$4, a7
  00aa80:  2f 00                move.l   d0, -(a7)
  00aa82:  20 5f                movea.l  (a7)+, a0
  00aa84:  4e 90                jsr      (a0)
  00aa86:  55 8f                subq.l   #$2, a7
  00aa88:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00aa8c:  2f 0c                move.l   a4, -(a7)
  00aa8e:  a8 e3                dc.w     $a8e3  ; _EqualRgn
  00aa90:  4a 1f                tst.b    (a7)+
  00aa92:  66 36                bne.b    $aaca  ; -> Laaca
  00aa94:  4a 07                tst.b    d7
  00aa96:  67 1a                beq.b    $aab2  ; -> Laab2
  00aa98:  70 01                moveq    #$1, d0
  00aa9a:  2f 00                move.l   d0, -(a7)
  00aa9c:  2f 00                move.l   d0, -(a7)
  00aa9e:  48 6e 00 08          pea.l    $8(a6)
  00aaa2:  72 10                moveq    #$10, d1
  00aaa4:  2f 01                move.l   d1, -(a7)
  00aaa6:  61 ff ff ff 9f 1c    bsr.l    $49c4  ; -> EngineDispatch
  00aaac:  4f ef 00 10          lea.l    $10(a7), a7
  00aab0:  60 18                bra.b    $aaca  ; -> Laaca
Laab2:
  00aab2:  70 01                moveq    #$1, d0
  00aab4:  2f 00                move.l   d0, -(a7)
  00aab6:  2f 00                move.l   d0, -(a7)
  00aab8:  48 6e 00 08          pea.l    $8(a6)
  00aabc:  72 32                moveq    #$32, d1
  00aabe:  2f 01                move.l   d1, -(a7)
  00aac0:  61 ff ff ff 9f 02    bsr.l    $49c4  ; -> EngineDispatch
  00aac6:  4f ef 00 10          lea.l    $10(a7), a7
Laaca:
  00aaca:  2f 0c                move.l   a4, -(a7)
  00aacc:  a8 d9                dc.w     $a8d9  ; _DisposRgn
  00aace:  60 1e                bra.b    $aaee  ; -> Laaee
Laad0:
  00aad0:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00aad4:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00aad8:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00aadc:  48 78 11 94          pea.l    $1194.w
  00aae0:  61 ff ff ff c2 b0    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00aae6:  58 8f                addq.l   #$4, a7
  00aae8:  2f 00                move.l   d0, -(a7)
  00aaea:  20 5f                movea.l  (a7)+, a0
  00aaec:  4e 90                jsr      (a0)
Laaee:
  00aaee:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  00aaf4:  4e 5e                unlk     a6
  00aaf6:  4e 74 00 0c          rtd      #$c
handler_53:
  00aafa:  4e 56 00 00          link.w   a6, #$0
  00aafe:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  00ab02:  20 78 08 88          movea.l  $888.w, a0
  00ab06:  20 50                movea.l  (a0), a0
  00ab08:  20 50                movea.l  (a0), a0
  00ab0a:  26 68 02 14          movea.l  $214(a0), a3
  00ab0e:  20 53                movea.l  (a3), a0
  00ab10:  20 2e 00 08          move.l   $8(a6), d0
  00ab14:  b0 a8 01 20          cmp.l    $120(a0), d0
  00ab18:  57 c0                seq.b    d0
  00ab1a:  44 00                neg.b    d0
  00ab1c:  49 c0                extb.l   d0
  00ab1e:  1e 00                move.b   d0, d7
  00ab20:  20 2e 00 08          move.l   $8(a6), d0
  00ab24:  b0 a8 01 24          cmp.l    $124(a0), d0
  00ab28:  57 c0                seq.b    d0
  00ab2a:  44 00                neg.b    d0
  00ab2c:  49 c0                extb.l   d0
  00ab2e:  1c 00                move.b   d0, d6
  00ab30:  4a 07                tst.b    d7
  00ab32:  66 06                bne.b    $ab3a  ; -> Lab3a
  00ab34:  4a 06                tst.b    d6
  00ab36:  67 00 00 88          beq.w    $abc0  ; -> Labc0
Lab3a:
  00ab3a:  59 8f                subq.l   #$4, a7
  00ab3c:  a8 d8                dc.w     $a8d8  ; _NewRgn
  00ab3e:  28 5f                movea.l  (a7)+, a4
  00ab40:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00ab44:  2f 0c                move.l   a4, -(a7)
  00ab46:  48 78 11 70          pea.l    $1170.w
  00ab4a:  61 ff ff ff c2 46    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00ab50:  58 8f                addq.l   #$4, a7
  00ab52:  2f 00                move.l   d0, -(a7)
  00ab54:  20 5f                movea.l  (a7)+, a0
  00ab56:  4e 90                jsr      (a0)
  00ab58:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00ab5c:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00ab60:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00ab64:  48 78 11 98          pea.l    $1198.w
  00ab68:  61 ff ff ff c2 28    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00ab6e:  58 8f                addq.l   #$4, a7
  00ab70:  2f 00                move.l   d0, -(a7)
  00ab72:  20 5f                movea.l  (a7)+, a0
  00ab74:  4e 90                jsr      (a0)
  00ab76:  55 8f                subq.l   #$2, a7
  00ab78:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00ab7c:  2f 0c                move.l   a4, -(a7)
  00ab7e:  a8 e3                dc.w     $a8e3  ; _EqualRgn
  00ab80:  4a 1f                tst.b    (a7)+
  00ab82:  66 36                bne.b    $abba  ; -> Labba
  00ab84:  4a 07                tst.b    d7
  00ab86:  67 1a                beq.b    $aba2  ; -> Laba2
  00ab88:  70 01                moveq    #$1, d0
  00ab8a:  2f 00                move.l   d0, -(a7)
  00ab8c:  2f 00                move.l   d0, -(a7)
  00ab8e:  48 6e 00 08          pea.l    $8(a6)
  00ab92:  72 10                moveq    #$10, d1
  00ab94:  2f 01                move.l   d1, -(a7)
  00ab96:  61 ff ff ff 9e 2c    bsr.l    $49c4  ; -> EngineDispatch
  00ab9c:  4f ef 00 10          lea.l    $10(a7), a7
  00aba0:  60 18                bra.b    $abba  ; -> Labba
Laba2:
  00aba2:  70 01                moveq    #$1, d0
  00aba4:  2f 00                move.l   d0, -(a7)
  00aba6:  2f 00                move.l   d0, -(a7)
  00aba8:  48 6e 00 08          pea.l    $8(a6)
  00abac:  72 32                moveq    #$32, d1
  00abae:  2f 01                move.l   d1, -(a7)
  00abb0:  61 ff ff ff 9e 12    bsr.l    $49c4  ; -> EngineDispatch
  00abb6:  4f ef 00 10          lea.l    $10(a7), a7
Labba:
  00abba:  2f 0c                move.l   a4, -(a7)
  00abbc:  a8 d9                dc.w     $a8d9  ; _DisposRgn
  00abbe:  60 1e                bra.b    $abde  ; -> Labde
Labc0:
  00abc0:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00abc4:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00abc8:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00abcc:  48 78 11 98          pea.l    $1198.w
  00abd0:  61 ff ff ff c1 c0    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00abd6:  58 8f                addq.l   #$4, a7
  00abd8:  2f 00                move.l   d0, -(a7)
  00abda:  20 5f                movea.l  (a7)+, a0
  00abdc:  4e 90                jsr      (a0)
Labde:
  00abde:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  00abe4:  4e 5e                unlk     a6
  00abe6:  4e 74 00 0c          rtd      #$c
handler_54:
  00abea:  4e 56 00 00          link.w   a6, #$0
  00abee:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  00abf2:  20 78 08 88          movea.l  $888.w, a0
  00abf6:  20 50                movea.l  (a0), a0
  00abf8:  20 50                movea.l  (a0), a0
  00abfa:  26 68 02 14          movea.l  $214(a0), a3
  00abfe:  20 53                movea.l  (a3), a0
  00ac00:  20 2e 00 08          move.l   $8(a6), d0
  00ac04:  b0 a8 01 20          cmp.l    $120(a0), d0
  00ac08:  57 c0                seq.b    d0
  00ac0a:  44 00                neg.b    d0
  00ac0c:  49 c0                extb.l   d0
  00ac0e:  1e 00                move.b   d0, d7
  00ac10:  20 2e 00 08          move.l   $8(a6), d0
  00ac14:  b0 a8 01 24          cmp.l    $124(a0), d0
  00ac18:  57 c0                seq.b    d0
  00ac1a:  44 00                neg.b    d0
  00ac1c:  49 c0                extb.l   d0
  00ac1e:  1c 00                move.b   d0, d6
  00ac20:  4a 07                tst.b    d7
  00ac22:  66 06                bne.b    $ac2a  ; -> Lac2a
  00ac24:  4a 06                tst.b    d6
  00ac26:  67 00 00 88          beq.w    $acb0  ; -> Lacb0
Lac2a:
  00ac2a:  59 8f                subq.l   #$4, a7
  00ac2c:  a8 d8                dc.w     $a8d8  ; _NewRgn
  00ac2e:  28 5f                movea.l  (a7)+, a4
  00ac30:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00ac34:  2f 0c                move.l   a4, -(a7)
  00ac36:  48 78 11 70          pea.l    $1170.w
  00ac3a:  61 ff ff ff c1 56    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00ac40:  58 8f                addq.l   #$4, a7
  00ac42:  2f 00                move.l   d0, -(a7)
  00ac44:  20 5f                movea.l  (a7)+, a0
  00ac46:  4e 90                jsr      (a0)
  00ac48:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00ac4c:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00ac50:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00ac54:  48 78 11 9c          pea.l    $119c.w
  00ac58:  61 ff ff ff c1 38    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00ac5e:  58 8f                addq.l   #$4, a7
  00ac60:  2f 00                move.l   d0, -(a7)
  00ac62:  20 5f                movea.l  (a7)+, a0
  00ac64:  4e 90                jsr      (a0)
  00ac66:  55 8f                subq.l   #$2, a7
  00ac68:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00ac6c:  2f 0c                move.l   a4, -(a7)
  00ac6e:  a8 e3                dc.w     $a8e3  ; _EqualRgn
  00ac70:  4a 1f                tst.b    (a7)+
  00ac72:  66 36                bne.b    $acaa  ; -> Lacaa
  00ac74:  4a 07                tst.b    d7
  00ac76:  67 1a                beq.b    $ac92  ; -> Lac92
  00ac78:  70 01                moveq    #$1, d0
  00ac7a:  2f 00                move.l   d0, -(a7)
  00ac7c:  2f 00                move.l   d0, -(a7)
  00ac7e:  48 6e 00 08          pea.l    $8(a6)
  00ac82:  72 10                moveq    #$10, d1
  00ac84:  2f 01                move.l   d1, -(a7)
  00ac86:  61 ff ff ff 9d 3c    bsr.l    $49c4  ; -> EngineDispatch
  00ac8c:  4f ef 00 10          lea.l    $10(a7), a7
  00ac90:  60 18                bra.b    $acaa  ; -> Lacaa
Lac92:
  00ac92:  70 01                moveq    #$1, d0
  00ac94:  2f 00                move.l   d0, -(a7)
  00ac96:  2f 00                move.l   d0, -(a7)
  00ac98:  48 6e 00 08          pea.l    $8(a6)
  00ac9c:  72 32                moveq    #$32, d1
  00ac9e:  2f 01                move.l   d1, -(a7)
  00aca0:  61 ff ff ff 9d 22    bsr.l    $49c4  ; -> EngineDispatch
  00aca6:  4f ef 00 10          lea.l    $10(a7), a7
Lacaa:
  00acaa:  2f 0c                move.l   a4, -(a7)
  00acac:  a8 d9                dc.w     $a8d9  ; _DisposRgn
  00acae:  60 1e                bra.b    $acce  ; -> Lacce
Lacb0:
  00acb0:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00acb4:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00acb8:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00acbc:  48 78 11 9c          pea.l    $119c.w
  00acc0:  61 ff ff ff c0 d0    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00acc6:  58 8f                addq.l   #$4, a7
  00acc8:  2f 00                move.l   d0, -(a7)
  00acca:  20 5f                movea.l  (a7)+, a0
  00accc:  4e 90                jsr      (a0)
Lacce:
  00acce:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  00acd4:  4e 5e                unlk     a6
  00acd6:  4e 74 00 0c          rtd      #$c
handler_55:
  00acda:  4e 56 ff f8          link.w   a6, #$fff8
  00acde:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  00ace2:  26 6e 00 08          movea.l  $8(a6), a3
  00ace6:  28 6e 00 0c          movea.l  $c(a6), a4
  00acea:  20 78 08 88          movea.l  $888.w, a0
  00acee:  20 50                movea.l  (a0), a0
  00acf0:  20 50                movea.l  (a0), a0
  00acf2:  2d 68 02 14 ff f8    move.l   $214(a0), -$8(a6)
  00acf8:  20 14                move.l   (a4), d0
  00acfa:  b0 93                cmp.l    (a3), d0
  00acfc:  66 0c                bne.b    $ad0a  ; -> Lad0a
  00acfe:  20 2c 00 04          move.l   $4(a4), d0
  00ad02:  b0 ab 00 04          cmp.l    $4(a3), d0
  00ad06:  67 00 00 dc          beq.w    $ade4  ; -> Lade4
Lad0a:
  00ad0a:  20 6e ff f8          movea.l  -$8(a6), a0
  00ad0e:  20 50                movea.l  (a0), a0
  00ad10:  20 2e 00 10          move.l   $10(a6), d0
  00ad14:  b0 a8 01 20          cmp.l    $120(a0), d0
  00ad18:  57 c0                seq.b    d0
  00ad1a:  44 00                neg.b    d0
  00ad1c:  49 c0                extb.l   d0
  00ad1e:  1e 00                move.b   d0, d7
  00ad20:  20 6e ff f8          movea.l  -$8(a6), a0
  00ad24:  20 50                movea.l  (a0), a0
  00ad26:  20 2e 00 10          move.l   $10(a6), d0
  00ad2a:  b0 a8 01 24          cmp.l    $124(a0), d0
  00ad2e:  57 c0                seq.b    d0
  00ad30:  44 00                neg.b    d0
  00ad32:  49 c0                extb.l   d0
  00ad34:  1c 00                move.b   d0, d6
  00ad36:  4a 07                tst.b    d7
  00ad38:  66 06                bne.b    $ad40  ; -> Lad40
  00ad3a:  4a 06                tst.b    d6
  00ad3c:  67 00 00 8c          beq.w    $adca  ; -> Ladca
Lad40:
  00ad40:  59 8f                subq.l   #$4, a7
  00ad42:  a8 d8                dc.w     $a8d8  ; _NewRgn
  00ad44:  2d 5f ff fc          move.l   (a7)+, -$4(a6)
  00ad48:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00ad4c:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  00ad50:  48 78 11 70          pea.l    $1170.w
  00ad54:  61 ff ff ff c0 3c    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00ad5a:  58 8f                addq.l   #$4, a7
  00ad5c:  2f 00                move.l   d0, -(a7)
  00ad5e:  20 5f                movea.l  (a7)+, a0
  00ad60:  4e 90                jsr      (a0)
  00ad62:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00ad66:  2f 0c                move.l   a4, -(a7)
  00ad68:  2f 0b                move.l   a3, -(a7)
  00ad6a:  48 78 11 ec          pea.l    $11ec.w
  00ad6e:  61 ff ff ff c0 22    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00ad74:  58 8f                addq.l   #$4, a7
  00ad76:  2f 00                move.l   d0, -(a7)
  00ad78:  20 5f                movea.l  (a7)+, a0
  00ad7a:  4e 90                jsr      (a0)
  00ad7c:  55 8f                subq.l   #$2, a7
  00ad7e:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00ad82:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  00ad86:  a8 e3                dc.w     $a8e3  ; _EqualRgn
  00ad88:  4a 1f                tst.b    (a7)+
  00ad8a:  66 36                bne.b    $adc2  ; -> Ladc2
  00ad8c:  4a 07                tst.b    d7
  00ad8e:  67 1a                beq.b    $adaa  ; -> Ladaa
  00ad90:  70 01                moveq    #$1, d0
  00ad92:  2f 00                move.l   d0, -(a7)
  00ad94:  2f 00                move.l   d0, -(a7)
  00ad96:  48 6e 00 10          pea.l    $10(a6)
  00ad9a:  72 10                moveq    #$10, d1
  00ad9c:  2f 01                move.l   d1, -(a7)
  00ad9e:  61 ff ff ff 9c 24    bsr.l    $49c4  ; -> EngineDispatch
  00ada4:  4f ef 00 10          lea.l    $10(a7), a7
  00ada8:  60 18                bra.b    $adc2  ; -> Ladc2
Ladaa:
  00adaa:  70 01                moveq    #$1, d0
  00adac:  2f 00                move.l   d0, -(a7)
  00adae:  2f 00                move.l   d0, -(a7)
  00adb0:  48 6e 00 10          pea.l    $10(a6)
  00adb4:  72 32                moveq    #$32, d1
  00adb6:  2f 01                move.l   d1, -(a7)
  00adb8:  61 ff ff ff 9c 0a    bsr.l    $49c4  ; -> EngineDispatch
  00adbe:  4f ef 00 10          lea.l    $10(a7), a7
Ladc2:
  00adc2:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  00adc6:  a8 d9                dc.w     $a8d9  ; _DisposRgn
  00adc8:  60 1a                bra.b    $ade4  ; -> Lade4
Ladca:
  00adca:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00adce:  2f 0c                move.l   a4, -(a7)
  00add0:  2f 0b                move.l   a3, -(a7)
  00add2:  48 78 11 ec          pea.l    $11ec.w
  00add6:  61 ff ff ff bf ba    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00addc:  58 8f                addq.l   #$4, a7
  00adde:  2f 00                move.l   d0, -(a7)
  00ade0:  20 5f                movea.l  (a7)+, a0
  00ade2:  4e 90                jsr      (a0)
Lade4:
  00ade4:  4c ee 18 c0 ff e8    movem.l  -$18(a6), d6-d7/a3-a4
  00adea:  4e 5e                unlk     a6
  00adec:  4e 74 00 0c          rtd      #$c
handler_16:
  00adf0:  4e 56 ff fc          link.w   a6, #$fffc
  00adf4:  2f 0c                move.l   a4, -(a7)
  00adf6:  70 00                moveq    #$0, d0
  00adf8:  2f 00                move.l   d0, -(a7)
  00adfa:  61 ff ff ff c1 20    bsr.l    $6f1c  ; -> sub_6f1c
  00ae00:  28 40                movea.l  d0, a4
  00ae02:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00ae06:  48 78 0f 88          pea.l    $f88.w
  00ae0a:  61 ff ff ff bf 86    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00ae10:  58 8f                addq.l   #$4, a7
  00ae12:  2f 00                move.l   d0, -(a7)
  00ae14:  20 5f                movea.l  (a7)+, a0
  00ae16:  4e 90                jsr      (a0)
  00ae18:  61 ff ff ff d1 f6    bsr.l    $8010  ; -> GetA5
  00ae1e:  20 40                movea.l  d0, a0
  00ae20:  20 50                movea.l  (a0), a0
  00ae22:  b9 d0                cmpa.l   (a0), a4
  00ae24:  58 4f                addq.w   #$4, a7
  00ae26:  66 24                bne.b    $ae4c  ; -> Lae4c
  00ae28:  4a 6c 00 06          tst.w    $6(a4)
  00ae2c:  6d 1e                blt.b    $ae4c  ; -> Lae4c
  00ae2e:  70 00                moveq    #$0, d0
  00ae30:  2d 40 ff fc          move.l   d0, -$4(a6)
  00ae34:  70 01                moveq    #$1, d0
  00ae36:  2f 00                move.l   d0, -(a7)
  00ae38:  2f 00                move.l   d0, -(a7)
  00ae3a:  48 6e ff fc          pea.l    -$4(a6)
  00ae3e:  72 36                moveq    #$36, d1
  00ae40:  2f 01                move.l   d1, -(a7)
  00ae42:  61 ff ff ff 9b 80    bsr.l    $49c4  ; -> EngineDispatch
  00ae48:  4f ef 00 10          lea.l    $10(a7), a7
Lae4c:
  00ae4c:  28 6e ff f8          movea.l  -$8(a6), a4
  00ae50:  4e 5e                unlk     a6
  00ae52:  4e 74 00 04          rtd      #$4
handler_17:
  00ae56:  4e 56 ff fc          link.w   a6, #$fffc
  00ae5a:  48 e7 13 18          movem.l  d3/d6-d7/a3-a4, -(a7)
  00ae5e:  26 6e 00 08          movea.l  $8(a6), a3
  00ae62:  70 00                moveq    #$0, d0
  00ae64:  2f 00                move.l   d0, -(a7)
  00ae66:  61 ff ff ff c0 b4    bsr.l    $6f1c  ; -> sub_6f1c
  00ae6c:  28 40                movea.l  d0, a4
  00ae6e:  61 ff ff ff d1 a0    bsr.l    $8010  ; -> GetA5
  00ae74:  20 40                movea.l  d0, a0
  00ae76:  20 50                movea.l  (a0), a0
  00ae78:  b9 d0                cmpa.l   (a0), a4
  00ae7a:  58 4f                addq.w   #$4, a7
  00ae7c:  66 62                bne.b    $aee0  ; -> Laee0
  00ae7e:  76 00                moveq    #$0, d3
  00ae80:  4a 6c 00 06          tst.w    $6(a4)
  00ae84:  6c 14                bge.b    $ae9a  ; -> Lae9a
  00ae86:  20 2c 00 24          move.l   $24(a4), d0
  00ae8a:  b0 93                cmp.l    (a3), d0
  00ae8c:  66 0a                bne.b    $ae98  ; -> Lae98
  00ae8e:  30 2c 00 28          move.w   $28(a4), d0
  00ae92:  b0 6b 00 04          cmp.w    $4(a3), d0
  00ae96:  67 02                beq.b    $ae9a  ; -> Lae9a
Lae98:
  00ae98:  76 01                moveq    #$1, d3
Lae9a:
  00ae9a:  1e 03                move.b   d3, d7
  00ae9c:  66 04                bne.b    $aea2  ; -> Laea2
  00ae9e:  2c 2c 00 50          move.l   $50(a4), d6
Laea2:
  00aea2:  2f 0b                move.l   a3, -(a7)
  00aea4:  48 78 16 50          pea.l    $1650.w
  00aea8:  61 ff ff ff be e8    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00aeae:  58 8f                addq.l   #$4, a7
  00aeb0:  2f 00                move.l   d0, -(a7)
  00aeb2:  20 5f                movea.l  (a7)+, a0
  00aeb4:  4e 90                jsr      (a0)
  00aeb6:  4a 07                tst.b    d7
  00aeb8:  66 06                bne.b    $aec0  ; -> Laec0
  00aeba:  bc ac 00 50          cmp.l    $50(a4), d6
  00aebe:  67 20                beq.b    $aee0  ; -> Laee0
Laec0:
  00aec0:  70 00                moveq    #$0, d0
  00aec2:  2d 40 ff fc          move.l   d0, -$4(a6)
  00aec6:  70 01                moveq    #$1, d0
  00aec8:  2f 00                move.l   d0, -(a7)
  00aeca:  2f 00                move.l   d0, -(a7)
  00aecc:  48 6e ff fc          pea.l    -$4(a6)
  00aed0:  72 36                moveq    #$36, d1
  00aed2:  2f 01                move.l   d1, -(a7)
  00aed4:  61 ff ff ff 9a ee    bsr.l    $49c4  ; -> EngineDispatch
  00aeda:  4f ef 00 10          lea.l    $10(a7), a7
  00aede:  60 14                bra.b    $aef4  ; -> Laef4
Laee0:
  00aee0:  2f 0b                move.l   a3, -(a7)
  00aee2:  48 78 16 50          pea.l    $1650.w
  00aee6:  61 ff ff ff be aa    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00aeec:  58 8f                addq.l   #$4, a7
  00aeee:  2f 00                move.l   d0, -(a7)
  00aef0:  20 5f                movea.l  (a7)+, a0
  00aef2:  4e 90                jsr      (a0)
Laef4:
  00aef4:  4c ee 18 c8 ff e8    movem.l  -$18(a6), d3/d6-d7/a3-a4
  00aefa:  4e 5e                unlk     a6
  00aefc:  4e 74 00 04          rtd      #$4
handler_18:
  00af00:  4e 56 ff fc          link.w   a6, #$fffc
  00af04:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  00af08:  3e 2e 00 08          move.w   $8(a6), d7
  00af0c:  70 00                moveq    #$0, d0
  00af0e:  2f 00                move.l   d0, -(a7)
  00af10:  61 ff ff ff c0 0a    bsr.l    $6f1c  ; -> sub_6f1c
  00af16:  26 40                movea.l  d0, a3
  00af18:  61 ff ff ff d0 f6    bsr.l    $8010  ; -> GetA5
  00af1e:  20 40                movea.l  d0, a0
  00af20:  20 50                movea.l  (a0), a0
  00af22:  b7 d0                cmpa.l   (a0), a3
  00af24:  58 4f                addq.w   #$4, a7
  00af26:  66 58                bne.b    $af80  ; -> Laf80
  00af28:  4a 6b 00 06          tst.w    $6(a3)
  00af2c:  6c 52                bge.b    $af80  ; -> Laf80
  00af2e:  20 6b 00 08          movea.l  $8(a3), a0
  00af32:  28 50                movea.l  (a0), a4
  00af34:  70 01                moveq    #$1, d0
  00af36:  c0 6c 00 18          and.w    $18(a4), d0
  00af3a:  67 06                beq.b    $af42  ; -> Laf42
  00af3c:  be 6c 00 10          cmp.w    $10(a4), d7
  00af40:  67 3e                beq.b    $af80  ; -> Laf80
Laf42:
  00af42:  3f 07                move.w   d7, -(a7)
  00af44:  48 78 18 5c          pea.l    $185c.w
  00af48:  61 ff ff ff be 48    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00af4e:  58 8f                addq.l   #$4, a7
  00af50:  2f 00                move.l   d0, -(a7)
  00af52:  20 5f                movea.l  (a7)+, a0
  00af54:  4e 90                jsr      (a0)
  00af56:  30 2c 00 18          move.w   $18(a4), d0
  00af5a:  08 00 00 00          btst.b   #$0, d0
  00af5e:  67 34                beq.b    $af94  ; -> Laf94
  00af60:  70 02                moveq    #$2, d0
  00af62:  2d 40 ff fc          move.l   d0, -$4(a6)
  00af66:  70 01                moveq    #$1, d0
  00af68:  2f 00                move.l   d0, -(a7)
  00af6a:  2f 00                move.l   d0, -(a7)
  00af6c:  48 6e ff fc          pea.l    -$4(a6)
  00af70:  72 36                moveq    #$36, d1
  00af72:  2f 01                move.l   d1, -(a7)
  00af74:  61 ff ff ff 9a 4e    bsr.l    $49c4  ; -> EngineDispatch
  00af7a:  4f ef 00 10          lea.l    $10(a7), a7
  00af7e:  60 14                bra.b    $af94  ; -> Laf94
Laf80:
  00af80:  3f 07                move.w   d7, -(a7)
  00af82:  48 78 18 5c          pea.l    $185c.w
  00af86:  61 ff ff ff be 0a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00af8c:  58 8f                addq.l   #$4, a7
  00af8e:  2f 00                move.l   d0, -(a7)
  00af90:  20 5f                movea.l  (a7)+, a0
  00af92:  4e 90                jsr      (a0)
Laf94:
  00af94:  4c ee 18 80 ff f0    movem.l  -$10(a6), d7/a3-a4
  00af9a:  4e 5e                unlk     a6
  00af9c:  4e 74 00 02          rtd      #$2
handler_41:
  00afa0:  4e 56 ff fc          link.w   a6, #$fffc
  00afa4:  2f 0c                move.l   a4, -(a7)
  00afa6:  70 00                moveq    #$0, d0
  00afa8:  2f 00                move.l   d0, -(a7)
  00afaa:  61 ff ff ff bf 70    bsr.l    $6f1c  ; -> sub_6f1c
  00afb0:  28 40                movea.l  d0, a4
  00afb2:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00afb6:  48 78 0f 8c          pea.l    $f8c.w
  00afba:  61 ff ff ff bd d6    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00afc0:  58 8f                addq.l   #$4, a7
  00afc2:  2f 00                move.l   d0, -(a7)
  00afc4:  20 5f                movea.l  (a7)+, a0
  00afc6:  4e 90                jsr      (a0)
  00afc8:  61 ff ff ff d0 46    bsr.l    $8010  ; -> GetA5
  00afce:  20 40                movea.l  d0, a0
  00afd0:  20 50                movea.l  (a0), a0
  00afd2:  b9 d0                cmpa.l   (a0), a4
  00afd4:  58 4f                addq.w   #$4, a7
  00afd6:  66 24                bne.b    $affc  ; -> Laffc
  00afd8:  4a 6c 00 06          tst.w    $6(a4)
  00afdc:  6d 1e                blt.b    $affc  ; -> Laffc
  00afde:  70 00                moveq    #$0, d0
  00afe0:  2d 40 ff fc          move.l   d0, -$4(a6)
  00afe4:  70 01                moveq    #$1, d0
  00afe6:  2f 00                move.l   d0, -(a7)
  00afe8:  2f 00                move.l   d0, -(a7)
  00afea:  48 6e ff fc          pea.l    -$4(a6)
  00afee:  72 37                moveq    #$37, d1
  00aff0:  2f 01                move.l   d1, -(a7)
  00aff2:  61 ff ff ff 99 d0    bsr.l    $49c4  ; -> EngineDispatch
  00aff8:  4f ef 00 10          lea.l    $10(a7), a7
Laffc:
  00affc:  28 6e ff f8          movea.l  -$8(a6), a4
  00b000:  4e 5e                unlk     a6
  00b002:  4e 74 00 04          rtd      #$4
handler_56:
  00b006:  4e 56 ff fc          link.w   a6, #$fffc
  00b00a:  48 e7 13 18          movem.l  d3/d6-d7/a3-a4, -(a7)
  00b00e:  26 6e 00 08          movea.l  $8(a6), a3
  00b012:  70 00                moveq    #$0, d0
  00b014:  2f 00                move.l   d0, -(a7)
  00b016:  61 ff ff ff bf 04    bsr.l    $6f1c  ; -> sub_6f1c
  00b01c:  28 40                movea.l  d0, a4
  00b01e:  61 ff ff ff cf f0    bsr.l    $8010  ; -> GetA5
  00b024:  20 40                movea.l  d0, a0
  00b026:  20 50                movea.l  (a0), a0
  00b028:  b9 d0                cmpa.l   (a0), a4
  00b02a:  58 4f                addq.w   #$4, a7
  00b02c:  66 62                bne.b    $b090  ; -> Lb090
  00b02e:  76 00                moveq    #$0, d3
  00b030:  4a 6c 00 06          tst.w    $6(a4)
  00b034:  6c 14                bge.b    $b04a  ; -> Lb04a
  00b036:  20 2c 00 2a          move.l   $2a(a4), d0
  00b03a:  b0 93                cmp.l    (a3), d0
  00b03c:  66 0a                bne.b    $b048  ; -> Lb048
  00b03e:  30 2c 00 2e          move.w   $2e(a4), d0
  00b042:  b0 6b 00 04          cmp.w    $4(a3), d0
  00b046:  67 02                beq.b    $b04a  ; -> Lb04a
Lb048:
  00b048:  76 01                moveq    #$1, d3
Lb04a:
  00b04a:  1e 03                move.b   d3, d7
  00b04c:  66 04                bne.b    $b052  ; -> Lb052
  00b04e:  2c 2c 00 54          move.l   $54(a4), d6
Lb052:
  00b052:  2f 0b                move.l   a3, -(a7)
  00b054:  48 78 16 54          pea.l    $1654.w
  00b058:  61 ff ff ff bd 38    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b05e:  58 8f                addq.l   #$4, a7
  00b060:  2f 00                move.l   d0, -(a7)
  00b062:  20 5f                movea.l  (a7)+, a0
  00b064:  4e 90                jsr      (a0)
  00b066:  4a 07                tst.b    d7
  00b068:  66 06                bne.b    $b070  ; -> Lb070
  00b06a:  bc ac 00 54          cmp.l    $54(a4), d6
  00b06e:  67 20                beq.b    $b090  ; -> Lb090
Lb070:
  00b070:  70 00                moveq    #$0, d0
  00b072:  2d 40 ff fc          move.l   d0, -$4(a6)
  00b076:  70 01                moveq    #$1, d0
  00b078:  2f 00                move.l   d0, -(a7)
  00b07a:  2f 00                move.l   d0, -(a7)
  00b07c:  48 6e ff fc          pea.l    -$4(a6)
  00b080:  72 37                moveq    #$37, d1
  00b082:  2f 01                move.l   d1, -(a7)
  00b084:  61 ff ff ff 99 3e    bsr.l    $49c4  ; -> EngineDispatch
  00b08a:  4f ef 00 10          lea.l    $10(a7), a7
  00b08e:  60 14                bra.b    $b0a4  ; -> Lb0a4
Lb090:
  00b090:  2f 0b                move.l   a3, -(a7)
  00b092:  48 78 16 54          pea.l    $1654.w
  00b096:  61 ff ff ff bc fa    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b09c:  58 8f                addq.l   #$4, a7
  00b09e:  2f 00                move.l   d0, -(a7)
  00b0a0:  20 5f                movea.l  (a7)+, a0
  00b0a2:  4e 90                jsr      (a0)
Lb0a4:
  00b0a4:  4c ee 18 c8 ff e8    movem.l  -$18(a6), d3/d6-d7/a3-a4
  00b0aa:  4e 5e                unlk     a6
  00b0ac:  4e 74 00 04          rtd      #$4
handler_19:
  00b0b0:  4e 56 ff fc          link.w   a6, #$fffc
  00b0b4:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  00b0b8:  3e 2e 00 08          move.w   $8(a6), d7
  00b0bc:  70 00                moveq    #$0, d0
  00b0be:  2f 00                move.l   d0, -(a7)
  00b0c0:  61 ff ff ff be 5a    bsr.l    $6f1c  ; -> sub_6f1c
  00b0c6:  26 40                movea.l  d0, a3
  00b0c8:  61 ff ff ff cf 46    bsr.l    $8010  ; -> GetA5
  00b0ce:  20 40                movea.l  d0, a0
  00b0d0:  20 50                movea.l  (a0), a0
  00b0d2:  b7 d0                cmpa.l   (a0), a3
  00b0d4:  58 4f                addq.w   #$4, a7
  00b0d6:  66 56                bne.b    $b12e  ; -> Lb12e
  00b0d8:  4a 6b 00 06          tst.w    $6(a3)
  00b0dc:  6c 50                bge.b    $b12e  ; -> Lb12e
  00b0de:  20 6b 00 08          movea.l  $8(a3), a0
  00b0e2:  28 50                movea.l  (a0), a4
  00b0e4:  70 02                moveq    #$2, d0
  00b0e6:  c0 6c 00 18          and.w    $18(a4), d0
  00b0ea:  67 06                beq.b    $b0f2  ; -> Lb0f2
  00b0ec:  be 6c 00 16          cmp.w    $16(a4), d7
  00b0f0:  67 3c                beq.b    $b12e  ; -> Lb12e
Lb0f2:
  00b0f2:  3f 07                move.w   d7, -(a7)
  00b0f4:  48 78 18 60          pea.l    $1860.w
  00b0f8:  61 ff ff ff bc 98    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b0fe:  58 8f                addq.l   #$4, a7
  00b100:  2f 00                move.l   d0, -(a7)
  00b102:  20 5f                movea.l  (a7)+, a0
  00b104:  4e 90                jsr      (a0)
  00b106:  70 02                moveq    #$2, d0
  00b108:  c0 6c 00 18          and.w    $18(a4), d0
  00b10c:  67 34                beq.b    $b142  ; -> Lb142
  00b10e:  70 04                moveq    #$4, d0
  00b110:  2d 40 ff fc          move.l   d0, -$4(a6)
  00b114:  70 01                moveq    #$1, d0
  00b116:  2f 00                move.l   d0, -(a7)
  00b118:  2f 00                move.l   d0, -(a7)
  00b11a:  48 6e ff fc          pea.l    -$4(a6)
  00b11e:  72 37                moveq    #$37, d1
  00b120:  2f 01                move.l   d1, -(a7)
  00b122:  61 ff ff ff 98 a0    bsr.l    $49c4  ; -> EngineDispatch
  00b128:  4f ef 00 10          lea.l    $10(a7), a7
  00b12c:  60 14                bra.b    $b142  ; -> Lb142
Lb12e:
  00b12e:  3f 07                move.w   d7, -(a7)
  00b130:  48 78 18 60          pea.l    $1860.w
  00b134:  61 ff ff ff bc 5c    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b13a:  58 8f                addq.l   #$4, a7
  00b13c:  2f 00                move.l   d0, -(a7)
  00b13e:  20 5f                movea.l  (a7)+, a0
  00b140:  4e 90                jsr      (a0)
Lb142:
  00b142:  4c ee 18 80 ff f0    movem.l  -$10(a6), d7/a3-a4
  00b148:  4e 5e                unlk     a6
  00b14a:  4e 74 00 02          rtd      #$2
sub_b14e:
  00b14e:  4e 56 00 00          link.w   a6, #$0
  00b152:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  00b156:  26 6e 00 0c          movea.l  $c(a6), a3
  00b15a:  28 6e 00 10          movea.l  $10(a6), a4
  00b15e:  4a 2e 00 0a          tst.b    $a(a6)
  00b162:  67 08                beq.b    $b16c  ; -> Lb16c
  00b164:  20 3c 00 00 00 ff    move.l   #$ff, d0
  00b16a:  60 02                bra.b    $b16e  ; -> Lb16e
Lb16c:
  00b16c:  70 df                moveq    #$df, d0
Lb16e:
  00b16e:  1e 00                move.b   d0, d7
  00b170:  7c 00                moveq    #$0, d6
  00b172:  1c 14                move.b   (a4), d6
  00b174:  70 00                moveq    #$0, d0
  00b176:  10 13                move.b   (a3), d0
  00b178:  b0 46                cmp.w    d6, d0
  00b17a:  67 28                beq.b    $b1a4  ; -> Lb1a4
  00b17c:  42 2e 00 14          clr.b    $14(a6)
  00b180:  60 30                bra.b    $b1b2  ; -> Lb1b2
Lb182:
  00b182:  52 4c                addq.w   #$1, a4
  00b184:  52 4b                addq.w   #$1, a3
  00b186:  70 00                moveq    #$0, d0
  00b188:  10 14                move.b   (a4), d0
  00b18a:  48 87                ext.w    d7
  00b18c:  12 07                move.b   d7, d1
  00b18e:  c2 00                and.b    d0, d1
  00b190:  70 00                moveq    #$0, d0
  00b192:  10 13                move.b   (a3), d0
  00b194:  48 87                ext.w    d7
  00b196:  14 07                move.b   d7, d2
  00b198:  c4 00                and.b    d0, d2
  00b19a:  b4 01                cmp.b    d1, d2
  00b19c:  67 06                beq.b    $b1a4  ; -> Lb1a4
  00b19e:  42 2e 00 14          clr.b    $14(a6)
  00b1a2:  60 0e                bra.b    $b1b2  ; -> Lb1b2
Lb1a4:
  00b1a4:  30 06                move.w   d6, d0
  00b1a6:  53 46                subq.w   #$1, d6
  00b1a8:  4a 40                tst.w    d0
  00b1aa:  66 d6                bne.b    $b182  ; -> Lb182
  00b1ac:  1d 7c 00 01 00 14    move.b   #$1, $14(a6)
Lb1b2:
  00b1b2:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  00b1b8:  4e 5e                unlk     a6
  00b1ba:  4e 74 00 0c          rtd      #$c
sub_b1be:
  00b1be:  4e 56 ff f0          link.w   a6, #$fff0
  00b1c2:  48 e7 10 08          movem.l  d3/a4, -(a7)
  00b1c6:  49 ee ff f8          lea.l    -$8(a6), a4
  00b1ca:  70 01                moveq    #$1, d0
  00b1cc:  2f 00                move.l   d0, -(a7)
  00b1ce:  72 00                moveq    #$0, d1
  00b1d0:  2f 01                move.l   d1, -(a7)
  00b1d2:  2f 01                move.l   d1, -(a7)
  00b1d4:  70 26                moveq    #$26, d0
  00b1d6:  2f 00                move.l   d0, -(a7)
  00b1d8:  61 ff ff ff 97 ea    bsr.l    $49c4  ; -> EngineDispatch
  00b1de:  55 8f                subq.l   #$2, a7
  00b1e0:  48 6e ff f0          pea.l    -$10(a6)
  00b1e4:  3f 3c 00 3f          move.w   #$3f, -(a7)
  00b1e8:  a8 8f                dc.w     $a88f  ; _OSDispatch
  00b1ea:  28 ae ff f0          move.l   -$10(a6), (a4)
  00b1ee:  29 6e ff f4 00 04    move.l   -$c(a6), $4(a4)
  00b1f4:  70 01                moveq    #$1, d0
  00b1f6:  2f 00                move.l   d0, -(a7)
  00b1f8:  72 02                moveq    #$2, d1
  00b1fa:  2f 01                move.l   d1, -(a7)
  00b1fc:  2f 0c                move.l   a4, -(a7)
  00b1fe:  70 3c                moveq    #$3c, d0
  00b200:  2f 00                move.l   d0, -(a7)
  00b202:  61 ff ff ff 97 c0    bsr.l    $49c4  ; -> EngineDispatch
  00b208:  55 8f                subq.l   #$2, a7
  00b20a:  48 78 09 10          pea.l    $910.w
  00b20e:  48 7a 00 22          pea.l    $b232(pc)
  00b212:  70 00                moveq    #$0, d0
  00b214:  1f 00                move.b   d0, -(a7)
  00b216:  72 01                moveq    #$1, d1
  00b218:  1f 01                move.b   d1, -(a7)
  00b21a:  61 ff ff ff ff 32    bsr.l    $b14e  ; -> sub_b14e
  00b220:  4a 1f                tst.b    (a7)+
  00b222:  57 c3                seq.b    d3
  00b224:  44 03                neg.b    d3
  00b226:  10 03                move.b   d3, d0
  00b228:  4c ee 10 08 ff e8    movem.l  -$18(a6), d3/a4
  00b22e:  4e 5e                unlk     a6
  00b230:  4e 75                rts      
  00b232:  0a 44 41 ca          eori.w   #$41ca, d4
  00b236:  48 61 6e 64 6c 65 72 00 dc.b     $48,$61,$6e,$64,$6c,$65,$72,$00  ; Handler.
handler_81:
  00b23e:  4e 56 ff f6          link.w   a6, #$fff6
  00b242:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  00b246:  38 2e 00 08          move.w   $8(a6), d4
  00b24a:  3a 2e 00 0a          move.w   $a(a6), d5
  00b24e:  61 ff ff ff cd c0    bsr.l    $8010  ; -> GetA5
  00b254:  20 40                movea.l  d0, a0
  00b256:  20 50                movea.l  (a0), a0
  00b258:  26 50                movea.l  (a0), a3
  00b25a:  4a 6b 00 06          tst.w    $6(a3)
  00b25e:  6c 00 00 ba          bge.w    $b31a  ; -> Lb31a
  00b262:  20 6b 00 02          movea.l  $2(a3), a0
  00b266:  20 50                movea.l  (a0), a0
  00b268:  20 10                move.l   (a0), d0
  00b26a:  b0 b8 08 24          cmp.l    $824.w, d0
  00b26e:  67 00 00 aa          beq.w    $b31a  ; -> Lb31a
  00b272:  70 00                moveq    #$0, d0
  00b274:  2f 00                move.l   d0, -(a7)
  00b276:  2f 2b 00 02          move.l   $2(a3), -(a7)
  00b27a:  61 ff 00 00 0b 18    bsr.l    $bd94  ; -> sub_bd94
  00b280:  2d 40 ff f6          move.l   d0, -$a(a6)
  00b284:  20 6b 00 02          movea.l  $2(a3), a0
  00b288:  28 50                movea.l  (a0), a4
  00b28a:  30 3c 3f ff          move.w   #$3fff, d0
  00b28e:  c0 6c 00 04          and.w    $4(a4), d0
  00b292:  72 00                moveq    #$0, d1
  00b294:  32 00                move.w   d0, d1
  00b296:  48 c4                ext.l    d4
  00b298:  30 2c 00 06          move.w   $6(a4), d0
  00b29c:  48 c0                ext.l    d0
  00b29e:  24 04                move.l   d4, d2
  00b2a0:  94 80                sub.l    d0, d2
  00b2a2:  4c 01 28 00          muls.l   d1, d2
  00b2a6:  d5 ae ff f6          add.l    d2, -$a(a6)
  00b2aa:  30 2c 00 20          move.w   $20(a4), d0
  00b2ae:  48 c0                ext.l    d0
  00b2b0:  2c 00                move.l   d0, d6
  00b2b2:  30 2c 00 08          move.w   $8(a4), d0
  00b2b6:  48 c0                ext.l    d0
  00b2b8:  2d 40 ff fc          move.l   d0, -$4(a6)
  00b2bc:  1d 7c 00 01 ff fb    move.b   #$1, -$5(a6)
  00b2c2:  41 ee ff fb          lea.l    -$5(a6), a0
  00b2c6:  10 10                move.b   (a0), d0
  00b2c8:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  00b2ca:  10 80                move.b   d0, (a0)
  00b2cc:  2f 06                move.l   d6, -(a7)
  00b2ce:  48 c5                ext.l    d5
  00b2d0:  20 05                move.l   d5, d0
  00b2d2:  90 ae ff fc          sub.l    -$4(a6), d0
  00b2d6:  4c 06 08 00          muls.l   d6, d0
  00b2da:  2f 00                move.l   d0, -(a7)
  00b2dc:  2f 2e ff f6          move.l   -$a(a6), -(a7)
  00b2e0:  61 ff ff ff cb 2a    bsr.l    $7e0c  ; -> BitFieldExtract
  00b2e6:  2e 00                move.l   d0, d7
  00b2e8:  41 ee ff fb          lea.l    -$5(a6), a0
  00b2ec:  10 10                move.b   (a0), d0
  00b2ee:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  00b2f0:  10 80                move.b   d0, (a0)
  00b2f2:  70 10                moveq    #$10, d0
  00b2f4:  b0 6c 00 1e          cmp.w    $1e(a4), d0
  00b2f8:  4f ef 00 14          lea.l    $14(a7), a7
  00b2fc:  66 0e                bne.b    $b30c  ; -> Lb30c
  00b2fe:  4a 87                tst.l    d7
  00b300:  57 c0                seq.b    d0
  00b302:  44 00                neg.b    d0
  00b304:  49 c0                extb.l   d0
  00b306:  1d 40 00 0c          move.b   d0, $c(a6)
  00b30a:  60 34                bra.b    $b340  ; -> Lb340
Lb30c:
  00b30c:  4a 87                tst.l    d7
  00b30e:  56 c0                sne.b    d0
  00b310:  44 00                neg.b    d0
  00b312:  49 c0                extb.l   d0
  00b314:  1d 40 00 0c          move.b   d0, $c(a6)
  00b318:  60 26                bra.b    $b340  ; -> Lb340
Lb31a:
  00b31a:  61 ff ff ff ba f8    bsr.l    $6e14  ; -> sub_6e14
  00b320:  4a 00                tst.b    d0
  00b322:  67 f6                beq.b    $b31a  ; -> Lb31a
  00b324:  55 8f                subq.l   #$2, a7
  00b326:  3f 05                move.w   d5, -(a7)
  00b328:  3f 04                move.w   d4, -(a7)
  00b32a:  48 78 0f 94          pea.l    $f94.w
  00b32e:  61 ff ff ff ba 62    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b334:  58 8f                addq.l   #$4, a7
  00b336:  2f 00                move.l   d0, -(a7)
  00b338:  20 5f                movea.l  (a7)+, a0
  00b33a:  4e 90                jsr      (a0)
  00b33c:  1d 5f 00 0c          move.b   (a7)+, $c(a6)
Lb340:
  00b340:  4c ee 18 f0 ff de    movem.l  -$22(a6), d4-d7/a3-a4
  00b346:  4e 5e                unlk     a6
  00b348:  4e 74 00 04          rtd      #$4
handler_80:
  00b34c:  4e 56 ff f6          link.w   a6, #$fff6
  00b350:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  00b354:  3a 2e 00 0c          move.w   $c(a6), d5
  00b358:  3c 2e 00 0e          move.w   $e(a6), d6
  00b35c:  61 ff ff ff cc b2    bsr.l    $8010  ; -> GetA5
  00b362:  20 40                movea.l  d0, a0
  00b364:  20 50                movea.l  (a0), a0
  00b366:  26 50                movea.l  (a0), a3
  00b368:  4a 6b 00 06          tst.w    $6(a3)
  00b36c:  6c 00 00 a0          bge.w    $b40e  ; -> Lb40e
  00b370:  20 6b 00 02          movea.l  $2(a3), a0
  00b374:  20 50                movea.l  (a0), a0
  00b376:  20 10                move.l   (a0), d0
  00b378:  b0 b8 08 24          cmp.l    $824.w, d0
  00b37c:  67 00 00 90          beq.w    $b40e  ; -> Lb40e
  00b380:  70 00                moveq    #$0, d0
  00b382:  2f 00                move.l   d0, -(a7)
  00b384:  2f 2b 00 02          move.l   $2(a3), -(a7)
  00b388:  61 ff 00 00 0a 0a    bsr.l    $bd94  ; -> sub_bd94
  00b38e:  2d 40 ff f6          move.l   d0, -$a(a6)
  00b392:  20 6b 00 02          movea.l  $2(a3), a0
  00b396:  28 50                movea.l  (a0), a4
  00b398:  30 3c 3f ff          move.w   #$3fff, d0
  00b39c:  c0 6c 00 04          and.w    $4(a4), d0
  00b3a0:  72 00                moveq    #$0, d1
  00b3a2:  32 00                move.w   d0, d1
  00b3a4:  48 c5                ext.l    d5
  00b3a6:  30 2c 00 06          move.w   $6(a4), d0
  00b3aa:  48 c0                ext.l    d0
  00b3ac:  24 05                move.l   d5, d2
  00b3ae:  94 80                sub.l    d0, d2
  00b3b0:  4c 01 28 00          muls.l   d1, d2
  00b3b4:  d5 ae ff f6          add.l    d2, -$a(a6)
  00b3b8:  30 2c 00 20          move.w   $20(a4), d0
  00b3bc:  48 c0                ext.l    d0
  00b3be:  2e 00                move.l   d0, d7
  00b3c0:  30 2c 00 08          move.w   $8(a4), d0
Lb3c4:
  00b3c4:  48 c0                ext.l    d0
  00b3c6:  28 00                move.l   d0, d4
  00b3c8:  1d 7c 00 01 ff fb    move.b   #$1, -$5(a6)
  00b3ce:  41 ee ff fb          lea.l    -$5(a6), a0
  00b3d2:  10 10                move.b   (a0), d0
  00b3d4:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  00b3d6:  10 80                move.b   d0, (a0)
  00b3d8:  2f 07                move.l   d7, -(a7)
  00b3da:  48 c6                ext.l    d6
  00b3dc:  20 06                move.l   d6, d0
  00b3de:  90 84                sub.l    d4, d0
  00b3e0:  4c 07 08 00          muls.l   d7, d0
  00b3e4:  2f 00                move.l   d0, -(a7)
  00b3e6:  2f 2e ff f6          move.l   -$a(a6), -(a7)
  00b3ea:  61 ff ff ff ca 20    bsr.l    $7e0c  ; -> BitFieldExtract
  00b3f0:  2d 40 ff fc          move.l   d0, -$4(a6)
  00b3f4:  41 ee ff fb          lea.l    -$5(a6), a0
  00b3f8:  10 10                move.b   (a0), d0
  00b3fa:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  00b3fc:  10 80                move.b   d0, (a0)
  00b3fe:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  00b402:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00b406:  aa 34                dc.w     $aa34  ; _Index2Color
  00b408:  4f ef 00 14          lea.l    $14(a7), a7
  00b40c:  60 24                bra.b    $b432  ; -> Lb432
Lb40e:
  00b40e:  61 ff ff ff ba 04    bsr.l    $6e14  ; -> sub_6e14
  00b414:  4a 00                tst.b    d0
  00b416:  67 f6                beq.b    $b40e  ; -> Lb40e
  00b418:  3f 06                move.w   d6, -(a7)
  00b41a:  3f 05                move.w   d5, -(a7)
  00b41c:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00b420:  48 78 16 5c          pea.l    $165c.w
  00b424:  61 ff ff ff b9 6c    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b42a:  58 8f                addq.l   #$4, a7
  00b42c:  2f 00                move.l   d0, -(a7)
  00b42e:  20 5f                movea.l  (a7)+, a0
  00b430:  4e 90                jsr      (a0)
Lb432:
  00b432:  4c ee 18 f0 ff de    movem.l  -$22(a6), d4-d7/a3-a4
  00b438:  4e 5e                unlk     a6
  00b43a:  4e 74 00 08          rtd      #$8
handler_67:
  00b43e:  4e 56 ff f6          link.w   a6, #$fff6
  00b442:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  00b446:  26 6e 00 08          movea.l  $8(a6), a3
  00b44a:  61 ff ff ff cb c4    bsr.l    $8010  ; -> GetA5
  00b450:  20 40                movea.l  d0, a0
  00b452:  20 50                movea.l  (a0), a0
  00b454:  28 50                movea.l  (a0), a4
  00b456:  2f 0b                move.l   a3, -(a7)
  00b458:  48 78 16 64          pea.l    $1664.w
  00b45c:  61 ff ff ff b9 34    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b462:  58 8f                addq.l   #$4, a7
  00b464:  2f 00                move.l   d0, -(a7)
  00b466:  20 5f                movea.l  (a7)+, a0
  00b468:  4e 90                jsr      (a0)
  00b46a:  4a 6c 00 06          tst.w    $6(a4)
  00b46e:  6c 4e                bge.b    $b4be  ; -> Lb4be
  00b470:  41 ee ff fa          lea.l    -$6(a6), a0
  00b474:  22 4b                movea.l  a3, a1
  00b476:  20 d9                move.l   (a1)+, (a0)+
  00b478:  30 d9                move.w   (a1)+, (a0)+
  00b47a:  59 8f                subq.l   #$4, a7
  00b47c:  48 6e ff fa          pea.l    -$6(a6)
  00b480:  aa 33                dc.w     $aa33  ; _Color2Index
  00b482:  2e 1f                move.l   (a7)+, d7
  00b484:  be ac 00 50          cmp.l    $50(a4), d7
  00b488:  67 34                beq.b    $b4be  ; -> Lb4be
  00b48a:  29 47 00 50          move.l   d7, $50(a4)
  00b48e:  70 00                moveq    #$0, d0
  00b490:  2f 00                move.l   d0, -(a7)
  00b492:  61 ff ff ff ba 88    bsr.l    $6f1c  ; -> sub_6f1c
  00b498:  26 40                movea.l  d0, a3
  00b49a:  b7 cc                cmpa.l   a4, a3
  00b49c:  58 4f                addq.w   #$4, a7
  00b49e:  66 1e                bne.b    $b4be  ; -> Lb4be
  00b4a0:  70 00                moveq    #$0, d0
  00b4a2:  2d 40 ff f6          move.l   d0, -$a(a6)
  00b4a6:  70 01                moveq    #$1, d0
  00b4a8:  2f 00                move.l   d0, -(a7)
  00b4aa:  2f 00                move.l   d0, -(a7)
  00b4ac:  48 6e ff f6          pea.l    -$a(a6)
  00b4b0:  72 36                moveq    #$36, d1
  00b4b2:  2f 01                move.l   d1, -(a7)
  00b4b4:  61 ff ff ff 95 0e    bsr.l    $49c4  ; -> EngineDispatch
  00b4ba:  4f ef 00 10          lea.l    $10(a7), a7
Lb4be:
  00b4be:  4c ee 18 80 ff ea    movem.l  -$16(a6), d7/a3-a4
  00b4c4:  4e 5e                unlk     a6
  00b4c6:  4e 74 00 04          rtd      #$4
handler_68:
  00b4ca:  4e 56 ff f6          link.w   a6, #$fff6
  00b4ce:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  00b4d2:  26 6e 00 08          movea.l  $8(a6), a3
  00b4d6:  61 ff ff ff cb 38    bsr.l    $8010  ; -> GetA5
  00b4dc:  20 40                movea.l  d0, a0
  00b4de:  20 50                movea.l  (a0), a0
  00b4e0:  28 50                movea.l  (a0), a4
  00b4e2:  2f 0b                move.l   a3, -(a7)
  00b4e4:  48 78 16 68          pea.l    $1668.w
  00b4e8:  61 ff ff ff b8 a8    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b4ee:  58 8f                addq.l   #$4, a7
  00b4f0:  2f 00                move.l   d0, -(a7)
  00b4f2:  20 5f                movea.l  (a7)+, a0
  00b4f4:  4e 90                jsr      (a0)
  00b4f6:  4a 6c 00 06          tst.w    $6(a4)
  00b4fa:  6c 4e                bge.b    $b54a  ; -> Lb54a
  00b4fc:  41 ee ff fa          lea.l    -$6(a6), a0
  00b500:  22 4b                movea.l  a3, a1
  00b502:  20 d9                move.l   (a1)+, (a0)+
  00b504:  30 d9                move.w   (a1)+, (a0)+
  00b506:  59 8f                subq.l   #$4, a7
  00b508:  48 6e ff fa          pea.l    -$6(a6)
  00b50c:  aa 33                dc.w     $aa33  ; _Color2Index
  00b50e:  2e 1f                move.l   (a7)+, d7
  00b510:  be ac 00 54          cmp.l    $54(a4), d7
  00b514:  67 34                beq.b    $b54a  ; -> Lb54a
  00b516:  29 47 00 54          move.l   d7, $54(a4)
  00b51a:  70 00                moveq    #$0, d0
  00b51c:  2f 00                move.l   d0, -(a7)
  00b51e:  61 ff ff ff b9 fc    bsr.l    $6f1c  ; -> sub_6f1c
  00b524:  26 40                movea.l  d0, a3
  00b526:  b7 cc                cmpa.l   a4, a3
  00b528:  58 4f                addq.w   #$4, a7
  00b52a:  66 1e                bne.b    $b54a  ; -> Lb54a
  00b52c:  70 00                moveq    #$0, d0
  00b52e:  2d 40 ff f6          move.l   d0, -$a(a6)
  00b532:  70 01                moveq    #$1, d0
  00b534:  2f 00                move.l   d0, -(a7)
  00b536:  2f 00                move.l   d0, -(a7)
  00b538:  48 6e ff f6          pea.l    -$a(a6)
  00b53c:  72 37                moveq    #$37, d1
  00b53e:  2f 01                move.l   d1, -(a7)
  00b540:  61 ff ff ff 94 82    bsr.l    $49c4  ; -> EngineDispatch
  00b546:  4f ef 00 10          lea.l    $10(a7), a7
Lb54a:
  00b54a:  4c ee 18 80 ff ea    movem.l  -$16(a6), d7/a3-a4
  00b550:  4e 5e                unlk     a6
  00b552:  4e 74 00 04          rtd      #$4
handler_76:
  00b556:  4e 56 00 00          link.w   a6, #$0
  00b55a:  2f 0c                move.l   a4, -(a7)
  00b55c:  59 8f                subq.l   #$4, a7
  00b55e:  48 78 16 0c          pea.l    $160c.w
  00b562:  61 ff ff ff b8 2e    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b568:  58 8f                addq.l   #$4, a7
  00b56a:  2f 00                move.l   d0, -(a7)
  00b56c:  20 5f                movea.l  (a7)+, a0
  00b56e:  4e 90                jsr      (a0)
  00b570:  28 5f                movea.l  (a7)+, a4
  00b572:  2d 4c 00 08          move.l   a4, $8(a6)
  00b576:  28 6e ff fc          movea.l  -$4(a6), a4
  00b57a:  4e 5e                unlk     a6
  00b57c:  4e 75                rts      
handler_57:
  00b57e:  4e 56 00 00          link.w   a6, #$0
  00b582:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00b586:  26 6e 00 08          movea.l  $8(a6), a3
  00b58a:  70 00                moveq    #$0, d0
  00b58c:  2f 00                move.l   d0, -(a7)
  00b58e:  61 ff ff ff b9 8c    bsr.l    $6f1c  ; -> sub_6f1c
  00b594:  28 40                movea.l  d0, a4
  00b596:  20 0c                move.l   a4, d0
  00b598:  58 4f                addq.w   #$4, a7
  00b59a:  67 24                beq.b    $b5c0  ; -> Lb5c0
  00b59c:  4a 6c 00 06          tst.w    $6(a4)
  00b5a0:  6c 1e                bge.b    $b5c0  ; -> Lb5c0
  00b5a2:  b7 ec 00 02          cmpa.l   $2(a4), a3
  00b5a6:  66 18                bne.b    $b5c0  ; -> Lb5c0
  00b5a8:  70 01                moveq    #$1, d0
  00b5aa:  2f 00                move.l   d0, -(a7)
  00b5ac:  72 00                moveq    #$0, d1
  00b5ae:  2f 01                move.l   d1, -(a7)
  00b5b0:  2f 01                move.l   d1, -(a7)
  00b5b2:  70 26                moveq    #$26, d0
  00b5b4:  2f 00                move.l   d0, -(a7)
  00b5b6:  61 ff ff ff 94 0c    bsr.l    $49c4  ; -> EngineDispatch
  00b5bc:  4f ef 00 10          lea.l    $10(a7), a7
Lb5c0:
  00b5c0:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00b5c4:  2f 0b                move.l   a3, -(a7)
  00b5c6:  48 78 16 14          pea.l    $1614.w
  00b5ca:  61 ff ff ff b7 c6    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b5d0:  58 8f                addq.l   #$4, a7
  00b5d2:  2f 00                move.l   d0, -(a7)
  00b5d4:  20 5f                movea.l  (a7)+, a0
  00b5d6:  4e 90                jsr      (a0)
  00b5d8:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  00b5de:  4e 5e                unlk     a6
  00b5e0:  4e 74 00 08          rtd      #$8
handler_58:
  00b5e4:  4e 56 ff f4          link.w   a6, #$fff4
  00b5e8:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  00b5ec:  70 00                moveq    #$0, d0
  00b5ee:  2f 00                move.l   d0, -(a7)
  00b5f0:  61 ff ff ff b9 2a    bsr.l    $6f1c  ; -> sub_6f1c
  00b5f6:  28 40                movea.l  d0, a4
  00b5f8:  20 6e 00 08          movea.l  $8(a6), a0
  00b5fc:  20 50                movea.l  (a0), a0
  00b5fe:  20 68 00 02          movea.l  $2(a0), a0
  00b602:  20 50                movea.l  (a0), a0
  00b604:  2d 68 00 2a ff fc    move.l   $2a(a0), -$4(a6)
  00b60a:  58 4f                addq.w   #$4, a7
  00b60c:  67 10                beq.b    $b61e  ; -> Lb61e
  00b60e:  20 6e ff fc          movea.l  -$4(a6), a0
  00b612:  26 50                movea.l  (a0), a3
  00b614:  4a 93                tst.l    (a3)
  00b616:  66 06                bne.b    $b61e  ; -> Lb61e
  00b618:  59 8f                subq.l   #$4, a7
  00b61a:  aa 28                dc.w     $aa28  ; _GetCTSeed
  00b61c:  26 9f                move.l   (a7)+, (a3)
Lb61e:
  00b61e:  61 ff ff ff c9 f0    bsr.l    $8010  ; -> GetA5
  00b624:  20 40                movea.l  d0, a0
  00b626:  20 50                movea.l  (a0), a0
  00b628:  b9 d0                cmpa.l   (a0), a4
  00b62a:  66 00 00 90          bne.w    $b6bc  ; -> Lb6bc
  00b62e:  4a 6c 00 06          tst.w    $6(a4)
  00b632:  5d c0                slt.b    d0
  00b634:  44 00                neg.b    d0
  00b636:  49 c0                extb.l   d0
  00b638:  1e 00                move.b   d0, d7
  00b63a:  67 1c                beq.b    $b658  ; -> Lb658
  00b63c:  70 01                moveq    #$1, d0
  00b63e:  2f 00                move.l   d0, -(a7)
  00b640:  48 6e 00 08          pea.l    $8(a6)
  00b644:  2f 00                move.l   d0, -(a7)
  00b646:  48 6c 00 3a          pea.l    $3a(a4)
  00b64a:  61 ff ff ff db 5e    bsr.l    $91aa  ; -> sub_91aa
  00b650:  4a 00                tst.b    d0
  00b652:  4f ef 00 10          lea.l    $10(a7), a7
  00b656:  67 26                beq.b    $b67e  ; -> Lb67e
Lb658:
  00b658:  4a 07                tst.b    d7
  00b65a:  66 76                bne.b    $b6d2  ; -> Lb6d2
  00b65c:  70 00                moveq    #$0, d0
  00b65e:  2f 00                move.l   d0, -(a7)
  00b660:  20 6e 00 08          movea.l  $8(a6), a0
  00b664:  20 50                movea.l  (a0), a0
  00b666:  48 68 00 14          pea.l    $14(a0)
  00b66a:  2f 00                move.l   d0, -(a7)
  00b66c:  48 6c 00 3a          pea.l    $3a(a4)
  00b670:  61 ff ff ff db 38    bsr.l    $91aa  ; -> sub_91aa
  00b676:  4a 00                tst.b    d0
  00b678:  4f ef 00 10          lea.l    $10(a7), a7
  00b67c:  66 54                bne.b    $b6d2  ; -> Lb6d2
Lb67e:
  00b67e:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00b682:  48 78 16 28          pea.l    $1628.w
  00b686:  61 ff ff ff b7 0a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b68c:  58 8f                addq.l   #$4, a7
  00b68e:  2f 00                move.l   d0, -(a7)
  00b690:  20 5f                movea.l  (a7)+, a0
  00b692:  4e 90                jsr      (a0)
  00b694:  70 00                moveq    #$0, d0
  00b696:  2d 40 ff f4          move.l   d0, -$c(a6)
  00b69a:  72 01                moveq    #$1, d1
  00b69c:  2d 41 ff f8          move.l   d1, -$8(a6)
  00b6a0:  70 01                moveq    #$1, d0
  00b6a2:  2f 00                move.l   d0, -(a7)
  00b6a4:  72 02                moveq    #$2, d1
  00b6a6:  2f 01                move.l   d1, -(a7)
  00b6a8:  48 6e ff f4          pea.l    -$c(a6)
  00b6ac:  70 2a                moveq    #$2a, d0
  00b6ae:  2f 00                move.l   d0, -(a7)
  00b6b0:  61 ff ff ff 93 12    bsr.l    $49c4  ; -> EngineDispatch
  00b6b6:  4f ef 00 10          lea.l    $10(a7), a7
  00b6ba:  60 16                bra.b    $b6d2  ; -> Lb6d2
Lb6bc:
  00b6bc:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00b6c0:  48 78 16 28          pea.l    $1628.w
  00b6c4:  61 ff ff ff b6 cc    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b6ca:  58 8f                addq.l   #$4, a7
  00b6cc:  2f 00                move.l   d0, -(a7)
  00b6ce:  20 5f                movea.l  (a7)+, a0
  00b6d0:  4e 90                jsr      (a0)
Lb6d2:
  00b6d2:  4c ee 18 80 ff e8    movem.l  -$18(a6), d7/a3-a4
  00b6d8:  4e 5e                unlk     a6
  00b6da:  4e 74 00 04          rtd      #$4
handler_59:
  00b6de:  4e 56 ff f4          link.w   a6, #$fff4
  00b6e2:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  00b6e6:  70 00                moveq    #$0, d0
  00b6e8:  2f 00                move.l   d0, -(a7)
  00b6ea:  61 ff ff ff b8 30    bsr.l    $6f1c  ; -> sub_6f1c
  00b6f0:  28 40                movea.l  d0, a4
  00b6f2:  20 6e 00 08          movea.l  $8(a6), a0
  00b6f6:  20 50                movea.l  (a0), a0
  00b6f8:  20 68 00 02          movea.l  $2(a0), a0
  00b6fc:  20 50                movea.l  (a0), a0
  00b6fe:  2d 68 00 2a ff fc    move.l   $2a(a0), -$4(a6)
  00b704:  58 4f                addq.w   #$4, a7
  00b706:  67 10                beq.b    $b718  ; -> Lb718
  00b708:  20 6e ff fc          movea.l  -$4(a6), a0
  00b70c:  26 50                movea.l  (a0), a3
  00b70e:  4a 93                tst.l    (a3)
  00b710:  66 06                bne.b    $b718  ; -> Lb718
  00b712:  59 8f                subq.l   #$4, a7
  00b714:  aa 28                dc.w     $aa28  ; _GetCTSeed
  00b716:  26 9f                move.l   (a7)+, (a3)
Lb718:
  00b718:  61 ff ff ff c8 f6    bsr.l    $8010  ; -> GetA5
  00b71e:  20 40                movea.l  d0, a0
  00b720:  20 50                movea.l  (a0), a0
  00b722:  b9 d0                cmpa.l   (a0), a4
  00b724:  66 00 00 90          bne.w    $b7b6  ; -> Lb7b6
  00b728:  4a 6c 00 06          tst.w    $6(a4)
  00b72c:  5d c0                slt.b    d0
  00b72e:  44 00                neg.b    d0
  00b730:  49 c0                extb.l   d0
  00b732:  1e 00                move.b   d0, d7
  00b734:  67 1c                beq.b    $b752  ; -> Lb752
  00b736:  70 01                moveq    #$1, d0
  00b738:  2f 00                move.l   d0, -(a7)
  00b73a:  48 6e 00 08          pea.l    $8(a6)
  00b73e:  2f 00                move.l   d0, -(a7)
  00b740:  48 6c 00 20          pea.l    $20(a4)
  00b744:  61 ff ff ff da 64    bsr.l    $91aa  ; -> sub_91aa
  00b74a:  4a 00                tst.b    d0
  00b74c:  4f ef 00 10          lea.l    $10(a7), a7
  00b750:  67 26                beq.b    $b778  ; -> Lb778
Lb752:
  00b752:  4a 07                tst.b    d7
  00b754:  66 76                bne.b    $b7cc  ; -> Lb7cc
  00b756:  70 00                moveq    #$0, d0
  00b758:  2f 00                move.l   d0, -(a7)
  00b75a:  20 6e 00 08          movea.l  $8(a6), a0
  00b75e:  20 50                movea.l  (a0), a0
  00b760:  48 68 00 14          pea.l    $14(a0)
  00b764:  2f 00                move.l   d0, -(a7)
  00b766:  48 6c 00 20          pea.l    $20(a4)
  00b76a:  61 ff ff ff da 3e    bsr.l    $91aa  ; -> sub_91aa
  00b770:  4a 00                tst.b    d0
  00b772:  4f ef 00 10          lea.l    $10(a7), a7
  00b776:  66 54                bne.b    $b7cc  ; -> Lb7cc
Lb778:
  00b778:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00b77c:  48 78 16 2c          pea.l    $162c.w
  00b780:  61 ff ff ff b6 10    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b786:  58 8f                addq.l   #$4, a7
  00b788:  2f 00                move.l   d0, -(a7)
  00b78a:  20 5f                movea.l  (a7)+, a0
  00b78c:  4e 90                jsr      (a0)
  00b78e:  70 00                moveq    #$0, d0
  00b790:  2d 40 ff f4          move.l   d0, -$c(a6)
  00b794:  72 02                moveq    #$2, d1
  00b796:  2d 41 ff f8          move.l   d1, -$8(a6)
  00b79a:  70 01                moveq    #$1, d0
  00b79c:  2f 00                move.l   d0, -(a7)
  00b79e:  72 02                moveq    #$2, d1
  00b7a0:  2f 01                move.l   d1, -(a7)
  00b7a2:  48 6e ff f4          pea.l    -$c(a6)
  00b7a6:  70 2a                moveq    #$2a, d0
  00b7a8:  2f 00                move.l   d0, -(a7)
  00b7aa:  61 ff ff ff 92 18    bsr.l    $49c4  ; -> EngineDispatch
  00b7b0:  4f ef 00 10          lea.l    $10(a7), a7
  00b7b4:  60 16                bra.b    $b7cc  ; -> Lb7cc
Lb7b6:
  00b7b6:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00b7ba:  48 78 16 2c          pea.l    $162c.w
  00b7be:  61 ff ff ff b5 d2    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b7c4:  58 8f                addq.l   #$4, a7
  00b7c6:  2f 00                move.l   d0, -(a7)
  00b7c8:  20 5f                movea.l  (a7)+, a0
  00b7ca:  4e 90                jsr      (a0)
Lb7cc:
  00b7cc:  4c ee 18 80 ff e8    movem.l  -$18(a6), d7/a3-a4
  00b7d2:  4e 5e                unlk     a6
  00b7d4:  4e 74 00 04          rtd      #$4
handler_60:
  00b7d8:  4e 56 00 00          link.w   a6, #$0
  00b7dc:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00b7e0:  26 6e 00 08          movea.l  $8(a6), a3
  00b7e4:  70 00                moveq    #$0, d0
  00b7e6:  2f 00                move.l   d0, -(a7)
  00b7e8:  61 ff ff ff b7 32    bsr.l    $6f1c  ; -> sub_6f1c
  00b7ee:  28 40                movea.l  d0, a4
  00b7f0:  61 ff ff ff c8 1e    bsr.l    $8010  ; -> GetA5
  00b7f6:  20 40                movea.l  d0, a0
  00b7f8:  20 50                movea.l  (a0), a0
  00b7fa:  b9 d0                cmpa.l   (a0), a4
  00b7fc:  58 4f                addq.w   #$4, a7
  00b7fe:  66 1e                bne.b    $b81e  ; -> Lb81e
  00b800:  b7 ec 00 02          cmpa.l   $2(a4), a3
  00b804:  67 18                beq.b    $b81e  ; -> Lb81e
  00b806:  70 01                moveq    #$1, d0
  00b808:  2f 00                move.l   d0, -(a7)
  00b80a:  72 00                moveq    #$0, d1
  00b80c:  2f 01                move.l   d1, -(a7)
  00b80e:  2f 01                move.l   d1, -(a7)
  00b810:  70 26                moveq    #$26, d0
  00b812:  2f 00                move.l   d0, -(a7)
  00b814:  61 ff ff ff 91 ae    bsr.l    $49c4  ; -> EngineDispatch
  00b81a:  4f ef 00 10          lea.l    $10(a7), a7
Lb81e:
  00b81e:  2f 0b                move.l   a3, -(a7)
  00b820:  48 78 16 18          pea.l    $1618.w
  00b824:  61 ff ff ff b5 6c    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b82a:  58 8f                addq.l   #$4, a7
  00b82c:  2f 00                move.l   d0, -(a7)
  00b82e:  20 5f                movea.l  (a7)+, a0
  00b830:  4e 90                jsr      (a0)
  00b832:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  00b838:  4e 5e                unlk     a6
  00b83a:  4e 74 00 04          rtd      #$4
handler_61:
  00b83e:  4e 56 ff fc          link.w   a6, #$fffc
  00b842:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00b846:  26 6e 00 08          movea.l  $8(a6), a3
  00b84a:  70 00                moveq    #$0, d0
  00b84c:  2f 00                move.l   d0, -(a7)
  00b84e:  61 ff ff ff b6 cc    bsr.l    $6f1c  ; -> sub_6f1c
  00b854:  28 40                movea.l  d0, a4
  00b856:  61 ff ff ff c7 b8    bsr.l    $8010  ; -> GetA5
  00b85c:  20 40                movea.l  d0, a0
  00b85e:  20 50                movea.l  (a0), a0
  00b860:  b9 d0                cmpa.l   (a0), a4
  00b862:  58 4f                addq.w   #$4, a7
  00b864:  66 38                bne.b    $b89e  ; -> Lb89e
  00b866:  4a 6c 00 06          tst.w    $6(a4)
  00b86a:  6c 32                bge.b    $b89e  ; -> Lb89e
  00b86c:  20 6c 00 08          movea.l  $8(a4), a0
  00b870:  20 50                movea.l  (a0), a0
  00b872:  2d 48 ff fc          move.l   a0, -$4(a6)
  00b876:  20 10                move.l   (a0), d0
  00b878:  b0 93                cmp.l    (a3), d0
  00b87a:  66 0a                bne.b    $b886  ; -> Lb886
  00b87c:  30 28 00 04          move.w   $4(a0), d0
  00b880:  b0 6b 00 04          cmp.w    $4(a3), d0
  00b884:  67 18                beq.b    $b89e  ; -> Lb89e
Lb886:
  00b886:  70 01                moveq    #$1, d0
  00b888:  2f 00                move.l   d0, -(a7)
  00b88a:  72 00                moveq    #$0, d1
  00b88c:  2f 01                move.l   d1, -(a7)
  00b88e:  2f 01                move.l   d1, -(a7)
  00b890:  70 26                moveq    #$26, d0
  00b892:  2f 00                move.l   d0, -(a7)
  00b894:  61 ff ff ff 91 2e    bsr.l    $49c4  ; -> EngineDispatch
  00b89a:  4f ef 00 10          lea.l    $10(a7), a7
Lb89e:
  00b89e:  2f 0b                move.l   a3, -(a7)
  00b8a0:  48 78 16 84          pea.l    $1684.w
  00b8a4:  61 ff ff ff b4 ec    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b8aa:  58 8f                addq.l   #$4, a7
  00b8ac:  2f 00                move.l   d0, -(a7)
  00b8ae:  20 5f                movea.l  (a7)+, a0
  00b8b0:  4e 90                jsr      (a0)
  00b8b2:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  00b8b8:  4e 5e                unlk     a6
  00b8ba:  4e 74 00 04          rtd      #$4
handler_62:
  00b8be:  4e 56 ff fc          link.w   a6, #$fffc
  00b8c2:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00b8c6:  26 6e 00 08          movea.l  $8(a6), a3
  00b8ca:  70 00                moveq    #$0, d0
  00b8cc:  2f 00                move.l   d0, -(a7)
  00b8ce:  61 ff ff ff b6 4c    bsr.l    $6f1c  ; -> sub_6f1c
  00b8d4:  28 40                movea.l  d0, a4
  00b8d6:  61 ff ff ff c7 38    bsr.l    $8010  ; -> GetA5
  00b8dc:  20 40                movea.l  d0, a0
  00b8de:  20 50                movea.l  (a0), a0
  00b8e0:  b9 d0                cmpa.l   (a0), a4
  00b8e2:  58 4f                addq.w   #$4, a7
  00b8e4:  66 3a                bne.b    $b920  ; -> Lb920
  00b8e6:  4a 6c 00 06          tst.w    $6(a4)
  00b8ea:  6c 34                bge.b    $b920  ; -> Lb920
  00b8ec:  20 6c 00 08          movea.l  $8(a4), a0
  00b8f0:  20 50                movea.l  (a0), a0
  00b8f2:  5c 88                addq.l   #$6, a0
  00b8f4:  2d 48 ff fc          move.l   a0, -$4(a6)
  00b8f8:  20 10                move.l   (a0), d0
  00b8fa:  b0 93                cmp.l    (a3), d0
  00b8fc:  66 0a                bne.b    $b908  ; -> Lb908
  00b8fe:  30 28 00 04          move.w   $4(a0), d0
  00b902:  b0 6b 00 04          cmp.w    $4(a3), d0
  00b906:  67 18                beq.b    $b920  ; -> Lb920
Lb908:
  00b908:  70 01                moveq    #$1, d0
  00b90a:  2f 00                move.l   d0, -(a7)
  00b90c:  72 00                moveq    #$0, d1
  00b90e:  2f 01                move.l   d1, -(a7)
  00b910:  2f 01                move.l   d1, -(a7)
  00b912:  70 26                moveq    #$26, d0
  00b914:  2f 00                move.l   d0, -(a7)
  00b916:  61 ff ff ff 90 ac    bsr.l    $49c4  ; -> EngineDispatch
  00b91c:  4f ef 00 10          lea.l    $10(a7), a7
Lb920:
  00b920:  2f 0b                move.l   a3, -(a7)
  00b922:  48 78 16 88          pea.l    $1688.w
  00b926:  61 ff ff ff b4 6a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b92c:  58 8f                addq.l   #$4, a7
  00b92e:  2f 00                move.l   d0, -(a7)
  00b930:  20 5f                movea.l  (a7)+, a0
  00b932:  4e 90                jsr      (a0)
  00b934:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  00b93a:  4e 5e                unlk     a6
  00b93c:  4e 74 00 04          rtd      #$4
Lb940:
  00b940:  4e 56 ff fc          link.w   a6, #$fffc
  00b944:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00b948:  26 6e 00 08          movea.l  $8(a6), a3
  00b94c:  28 53                movea.l  (a3), a4
  00b94e:  70 02                moveq    #$2, d0
  00b950:  b0 6c 00 0e          cmp.w    $e(a4), d0
  00b954:  67 08                beq.b    $b95e  ; -> Lb95e
  00b956:  1d 7c 00 01 00 0c    move.b   #$1, $c(a6)
  00b95c:  60 4a                bra.b    $b9a8  ; -> Lb9a8
Lb95e:
  00b95e:  20 54                movea.l  (a4), a0
  00b960:  2d 48 ff fc          move.l   a0, -$4(a6)
  00b964:  28 50                movea.l  (a0), a4
  00b966:  20 0c                move.l   a4, d0
  00b968:  66 1e                bne.b    $b988  ; -> Lb988
  00b96a:  70 01                moveq    #$1, d0
  00b96c:  2f 00                move.l   d0, -(a7)
  00b96e:  2f 00                move.l   d0, -(a7)
  00b970:  48 6e ff fc          pea.l    -$4(a6)
  00b974:  72 33                moveq    #$33, d1
  00b976:  2f 01                move.l   d1, -(a7)
  00b978:  61 ff ff ff 90 4a    bsr.l    $49c4  ; -> EngineDispatch
  00b97e:  42 2e 00 0c          clr.b    $c(a6)
  00b982:  4f ef 00 10          lea.l    $10(a7), a7
  00b986:  60 20                bra.b    $b9a8  ; -> Lb9a8
Lb988:
  00b988:  55 8f                subq.l   #$2, a7
  00b98a:  2f 0b                move.l   a3, -(a7)
  00b98c:  48 78 1a 74          pea.l    $1a74.w
  00b990:  61 ff ff ff b4 00    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b996:  58 8f                addq.l   #$4, a7
  00b998:  2f 00                move.l   d0, -(a7)
  00b99a:  20 3c 00 04 00 01    move.l   #$40001, d0
  00b9a0:  20 5f                movea.l  (a7)+, a0
  00b9a2:  4e 90                jsr      (a0)
  00b9a4:  1d 5f 00 0c          move.b   (a7)+, $c(a6)
Lb9a8:
  00b9a8:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  00b9ae:  4e 5e                unlk     a6
  00b9b0:  4e 74 00 04          rtd      #$4
Lb9b4:
  00b9b4:  4e 56 ff fc          link.w   a6, #$fffc
  00b9b8:  2f 0c                move.l   a4, -(a7)
  00b9ba:  28 6e 00 08          movea.l  $8(a6), a4
  00b9be:  2f 0c                move.l   a4, -(a7)
  00b9c0:  48 78 1a 74          pea.l    $1a74.w
  00b9c4:  61 ff ff ff b3 cc    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00b9ca:  58 8f                addq.l   #$4, a7
  00b9cc:  2f 00                move.l   d0, -(a7)
  00b9ce:  20 3c 00 04 00 02    move.l   #$40002, d0
  00b9d4:  20 5f                movea.l  (a7)+, a0
  00b9d6:  4e 90                jsr      (a0)
  00b9d8:  20 54                movea.l  (a4), a0
  00b9da:  2d 50 ff fc          move.l   (a0), -$4(a6)
  00b9de:  70 01                moveq    #$1, d0
  00b9e0:  2f 00                move.l   d0, -(a7)
  00b9e2:  2f 00                move.l   d0, -(a7)
  00b9e4:  48 6e ff fc          pea.l    -$4(a6)
  00b9e8:  72 0f                moveq    #$f, d1
  00b9ea:  2f 01                move.l   d1, -(a7)
  00b9ec:  61 ff ff ff 8f d6    bsr.l    $49c4  ; -> EngineDispatch
  00b9f2:  28 6e ff f8          movea.l  -$8(a6), a4
  00b9f6:  4e 5e                unlk     a6
  00b9f8:  4e 74 00 04          rtd      #$4
Lb9fc:
  00b9fc:  4e 56 00 00          link.w   a6, #$0
  00ba00:  48 e7 03 08          movem.l  d6-d7/a4, -(a7)
  00ba04:  2c 2e 00 08          move.l   $8(a6), d6
  00ba08:  28 6e 00 1a          movea.l  $1a(a6), a4
  00ba0c:  55 8f                subq.l   #$2, a7
  00ba0e:  2f 0c                move.l   a4, -(a7)
  00ba10:  3f 2e 00 18          move.w   $18(a6), -(a7)
  00ba14:  2f 2e 00 14          move.l   $14(a6), -(a7)
  00ba18:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00ba1c:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00ba20:  2f 06                move.l   d6, -(a7)
  00ba22:  48 78 1a 74          pea.l    $1a74.w
  00ba26:  61 ff ff ff b3 6a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00ba2c:  58 8f                addq.l   #$4, a7
  00ba2e:  2f 00                move.l   d0, -(a7)
  00ba30:  20 3c 00 16 00 00    move.l   #$160000, d0
  00ba36:  20 5f                movea.l  (a7)+, a0
  00ba38:  4e 90                jsr      (a0)
  00ba3a:  3e 1f                move.w   (a7)+, d7
  00ba3c:  66 16                bne.b    $ba54  ; -> Lba54
  00ba3e:  70 08                moveq    #$8, d0
  00ba40:  c0 86                and.l    d6, d0
  00ba42:  67 10                beq.b    $ba54  ; -> Lba54
  00ba44:  20 54                movea.l  (a4), a0
  00ba46:  20 68 00 02          movea.l  $2(a0), a0
  00ba4a:  20 50                movea.l  (a0), a0
  00ba4c:  00 a8 00 00 00 01 00 2e ori.l    #$1, $2e(a0)
Lba54:
  00ba54:  3d 47 00 1e          move.w   d7, $1e(a6)
  00ba58:  4c ee 10 c0 ff f4    movem.l  -$c(a6), d6-d7/a4
  00ba5e:  4e 5e                unlk     a6
  00ba60:  4e 74 00 16          rtd      #$16
Lba64:
  00ba64:  4e 56 ff fc          link.w   a6, #$fffc
  00ba68:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  00ba6c:  2e 2e 00 08          move.l   $8(a6), d7
  00ba70:  20 6e 00 1a          movea.l  $1a(a6), a0
  00ba74:  20 50                movea.l  (a0), a0
  00ba76:  26 68 00 02          movea.l  $2(a0), a3
  00ba7a:  28 53                movea.l  (a3), a4
  00ba7c:  30 2c 00 0e          move.w   $e(a4), d0
  00ba80:  48 c0                ext.l    d0
  00ba82:  2c 00                move.l   d0, d6
  00ba84:  2d 54 ff fc          move.l   (a4), -$4(a6)
  00ba88:  70 01                moveq    #$1, d0
  00ba8a:  b0 86                cmp.l    d6, d0
  00ba8c:  66 10                bne.b    $ba9e  ; -> Lba9e
  00ba8e:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  00ba92:  61 ff ff ff c7 9a    bsr.l    $822e  ; -> sub_822e
  00ba98:  2d 40 ff fc          move.l   d0, -$4(a6)
  00ba9c:  58 4f                addq.w   #$4, a7
Lba9e:
  00ba9e:  4a ae ff fc          tst.l    -$4(a6)
  00baa2:  67 18                beq.b    $babc  ; -> Lbabc
  00baa4:  70 01                moveq    #$1, d0
  00baa6:  2f 00                move.l   d0, -(a7)
  00baa8:  2f 00                move.l   d0, -(a7)
  00baaa:  48 6e ff fc          pea.l    -$4(a6)
  00baae:  72 19                moveq    #$19, d1
  00bab0:  2f 01                move.l   d1, -(a7)
  00bab2:  61 ff ff ff 8f 10    bsr.l    $49c4  ; -> EngineDispatch
  00bab8:  4f ef 00 10          lea.l    $10(a7), a7
Lbabc:
  00babc:  28 53                movea.l  (a3), a4
  00babe:  70 08                moveq    #$8, d0
  00bac0:  c0 87                and.l    d7, d0
  00bac2:  67 0a                beq.b    $bace  ; -> Lbace
  00bac4:  00 ac 00 00 00 01 00 2e ori.l    #$1, $2e(a4)
  00bacc:  60 06                bra.b    $bad4  ; -> Lbad4
Lbace:
  00bace:  08 ac 00 00 00 31    bclr.b   #$0, $31(a4)
Lbad4:
  00bad4:  59 8f                subq.l   #$4, a7
  00bad6:  2f 2e 00 1a          move.l   $1a(a6), -(a7)
  00bada:  3f 2e 00 18          move.w   $18(a6), -(a7)
  00bade:  2f 2e 00 14          move.l   $14(a6), -(a7)
  00bae2:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00bae6:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00baea:  2f 07                move.l   d7, -(a7)
  00baec:  48 78 1a 74          pea.l    $1a74.w
  00baf0:  61 ff ff ff b2 a0    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00baf6:  58 8f                addq.l   #$4, a7
  00baf8:  2f 00                move.l   d0, -(a7)
  00bafa:  20 3c 00 16 00 03    move.l   #$160003, d0
  00bb00:  20 5f                movea.l  (a7)+, a0
  00bb02:  4e 90                jsr      (a0)
  00bb04:  2d 5f 00 1e          move.l   (a7)+, $1e(a6)
  00bb08:  4c ee 18 c0 ff ec    movem.l  -$14(a6), d6-d7/a3-a4
  00bb0e:  4e 5e                unlk     a6
  00bb10:  4e 74 00 16          rtd      #$16
Lbb14:
  00bb14:  4e 56 ff fc          link.w   a6, #$fffc
  00bb18:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00bb1c:  26 6e 00 08          movea.l  $8(a6), a3
  00bb20:  20 6b 00 02          movea.l  $2(a3), a0
  00bb24:  28 50                movea.l  (a0), a4
  00bb26:  2d 54 ff fc          move.l   (a4), -$4(a6)
  00bb2a:  67 36                beq.b    $bb62  ; -> Lbb62
  00bb2c:  70 01                moveq    #$1, d0
  00bb2e:  b0 6c 00 0e          cmp.w    $e(a4), d0
  00bb32:  66 10                bne.b    $bb44  ; -> Lbb44
  00bb34:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  00bb38:  61 ff ff ff c6 f4    bsr.l    $822e  ; -> sub_822e
  00bb3e:  2d 40 ff fc          move.l   d0, -$4(a6)
  00bb42:  58 4f                addq.w   #$4, a7
Lbb44:
  00bb44:  4a ae ff fc          tst.l    -$4(a6)
  00bb48:  67 18                beq.b    $bb62  ; -> Lbb62
  00bb4a:  70 01                moveq    #$1, d0
  00bb4c:  2f 00                move.l   d0, -(a7)
  00bb4e:  2f 00                move.l   d0, -(a7)
  00bb50:  48 6e ff fc          pea.l    -$4(a6)
  00bb54:  72 33                moveq    #$33, d1
  00bb56:  2f 01                move.l   d1, -(a7)
  00bb58:  61 ff ff ff 8e 6a    bsr.l    $49c4  ; -> EngineDispatch
  00bb5e:  4f ef 00 10          lea.l    $10(a7), a7
Lbb62:
  00bb62:  2f 0b                move.l   a3, -(a7)
  00bb64:  48 78 1a 74          pea.l    $1a74.w
  00bb68:  61 ff ff ff b2 28    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00bb6e:  58 8f                addq.l   #$4, a7
  00bb70:  2f 00                move.l   d0, -(a7)
  00bb72:  20 3c 00 04 00 04    move.l   #$40004, d0
  00bb78:  20 5f                movea.l  (a7)+, a0
  00bb7a:  4e 90                jsr      (a0)
  00bb7c:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  00bb82:  4e 5e                unlk     a6
  00bb84:  4e 74 00 04          rtd      #$4
Lbb88:
  00bb88:  4e 56 ff fc          link.w   a6, #$fffc
  00bb8c:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  00bb90:  2e 2e 00 08          move.l   $8(a6), d7
  00bb94:  26 6e 00 0c          movea.l  $c(a6), a3
  00bb98:  28 53                movea.l  (a3), a4
  00bb9a:  30 2c 00 0e          move.w   $e(a4), d0
  00bb9e:  48 c0                ext.l    d0
  00bba0:  2c 00                move.l   d0, d6
  00bba2:  2d 54 ff fc          move.l   (a4), -$4(a6)
  00bba6:  70 01                moveq    #$1, d0
  00bba8:  b0 86                cmp.l    d6, d0
  00bbaa:  66 10                bne.b    $bbbc  ; -> Lbbbc
  00bbac:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  00bbb0:  61 ff ff ff c6 7c    bsr.l    $822e  ; -> sub_822e
  00bbb6:  2d 40 ff fc          move.l   d0, -$4(a6)
  00bbba:  58 4f                addq.w   #$4, a7
Lbbbc:
  00bbbc:  70 08                moveq    #$8, d0
  00bbbe:  c0 87                and.l    d7, d0
  00bbc0:  67 32                beq.b    $bbf4  ; -> Lbbf4
  00bbc2:  70 01                moveq    #$1, d0
  00bbc4:  c0 ac 00 2e          and.l    $2e(a4), d0
  00bbc8:  66 1e                bne.b    $bbe8  ; -> Lbbe8
  00bbca:  4a ae ff fc          tst.l    -$4(a6)
  00bbce:  67 18                beq.b    $bbe8  ; -> Lbbe8
  00bbd0:  70 01                moveq    #$1, d0
  00bbd2:  2f 00                move.l   d0, -(a7)
  00bbd4:  2f 00                move.l   d0, -(a7)
  00bbd6:  48 6e ff fc          pea.l    -$4(a6)
  00bbda:  72 19                moveq    #$19, d1
  00bbdc:  2f 01                move.l   d1, -(a7)
  00bbde:  61 ff ff ff 8d e4    bsr.l    $49c4  ; -> EngineDispatch
  00bbe4:  4f ef 00 10          lea.l    $10(a7), a7
Lbbe8:
  00bbe8:  28 53                movea.l  (a3), a4
  00bbea:  00 ac 00 00 00 01 00 2e ori.l    #$1, $2e(a4)
  00bbf2:  60 06                bra.b    $bbfa  ; -> Lbbfa
Lbbf4:
  00bbf4:  08 ac 00 00 00 31    bclr.b   #$0, $31(a4)
Lbbfa:
  00bbfa:  2f 0b                move.l   a3, -(a7)
  00bbfc:  2f 07                move.l   d7, -(a7)
  00bbfe:  48 78 1a 74          pea.l    $1a74.w
  00bc02:  61 ff ff ff b1 8e    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00bc08:  58 8f                addq.l   #$4, a7
  00bc0a:  2f 00                move.l   d0, -(a7)
  00bc0c:  20 3c 00 08 00 0e    move.l   #$8000e, d0
  00bc12:  20 5f                movea.l  (a7)+, a0
  00bc14:  4e 90                jsr      (a0)
  00bc16:  4c ee 18 c0 ff ec    movem.l  -$14(a6), d6-d7/a3-a4
  00bc1c:  4e 5e                unlk     a6
  00bc1e:  4e 74 00 08          rtd      #$8
handler_79:
  00bc22:  4e 56 00 00          link.w   a6, #$0
  00bc26:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00bc2a:  48 78 0f f4          pea.l    $ff4.w
  00bc2e:  61 ff ff ff b1 62    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00bc34:  58 8f                addq.l   #$4, a7
  00bc36:  2f 00                move.l   d0, -(a7)
  00bc38:  20 5f                movea.l  (a7)+, a0
  00bc3a:  4e 90                jsr      (a0)
  00bc3c:  4e 5e                unlk     a6
  00bc3e:  4e 74 00 04          rtd      #$4
handler_101:
  00bc42:  4e 56 00 00          link.w   a6, #$0
  00bc46:  48 e7 03 08          movem.l  d6-d7/a4, -(a7)
  00bc4a:  2e 2e 00 08          move.l   $8(a6), d7
  00bc4e:  70 00                moveq    #$0, d0
  00bc50:  2f 00                move.l   d0, -(a7)
  00bc52:  61 ff ff ff b2 c8    bsr.l    $6f1c  ; -> sub_6f1c
  00bc58:  28 40                movea.l  d0, a4
  00bc5a:  61 ff ff ff c3 b4    bsr.l    $8010  ; -> GetA5
  00bc60:  20 40                movea.l  d0, a0
  00bc62:  20 50                movea.l  (a0), a0
  00bc64:  b9 d0                cmpa.l   (a0), a4
  00bc66:  58 4f                addq.w   #$4, a7
  00bc68:  66 3e                bne.b    $bca8  ; -> Lbca8
  00bc6a:  4a 6c 00 06          tst.w    $6(a4)
  00bc6e:  6c 38                bge.b    $bca8  ; -> Lbca8
  00bc70:  3c 2c 00 0c          move.w   $c(a4), d6
  00bc74:  2f 07                move.l   d7, -(a7)
  00bc76:  48 78 16 8c          pea.l    $168c.w
  00bc7a:  61 ff ff ff b1 16    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00bc80:  58 8f                addq.l   #$4, a7
  00bc82:  2f 00                move.l   d0, -(a7)
  00bc84:  20 5f                movea.l  (a7)+, a0
  00bc86:  4e 90                jsr      (a0)
  00bc88:  bc 6c 00 0c          cmp.w    $c(a4), d6
  00bc8c:  67 2e                beq.b    $bcbc  ; -> Lbcbc
  00bc8e:  70 01                moveq    #$1, d0
  00bc90:  2f 00                move.l   d0, -(a7)
  00bc92:  72 00                moveq    #$0, d1
  00bc94:  2f 01                move.l   d1, -(a7)
  00bc96:  2f 01                move.l   d1, -(a7)
  00bc98:  70 26                moveq    #$26, d0
  00bc9a:  2f 00                move.l   d0, -(a7)
  00bc9c:  61 ff ff ff 8d 26    bsr.l    $49c4  ; -> EngineDispatch
  00bca2:  4f ef 00 10          lea.l    $10(a7), a7
  00bca6:  60 14                bra.b    $bcbc  ; -> Lbcbc
Lbca8:
  00bca8:  2f 07                move.l   d7, -(a7)
  00bcaa:  48 78 16 8c          pea.l    $168c.w
  00bcae:  61 ff ff ff b0 e2    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00bcb4:  58 8f                addq.l   #$4, a7
  00bcb6:  2f 00                move.l   d0, -(a7)
  00bcb8:  20 5f                movea.l  (a7)+, a0
  00bcba:  4e 90                jsr      (a0)
Lbcbc:
  00bcbc:  4c ee 10 c0 ff f4    movem.l  -$c(a6), d6-d7/a4
  00bcc2:  4e 5e                unlk     a6
  00bcc4:  4e 74 00 04          rtd      #$4
sub_bcc8:
  00bcc8:  4e 56 ff f8          link.w   a6, #$fff8
  00bccc:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  00bcd0:  26 6e 00 08          movea.l  $8(a6), a3
  00bcd4:  70 00                moveq    #$0, d0
  00bcd6:  2f 00                move.l   d0, -(a7)
  00bcd8:  61 ff ff ff b2 42    bsr.l    $6f1c  ; -> sub_6f1c
  00bcde:  28 40                movea.l  d0, a4
  00bce0:  7e 00                moveq    #$0, d7
  00bce2:  20 0c                move.l   a4, d0
  00bce4:  58 4f                addq.w   #$4, a7
  00bce6:  67 22                beq.b    $bd0a  ; -> Lbd0a
  00bce8:  4a 6c 00 06          tst.w    $6(a4)
  00bcec:  6c 1c                bge.b    $bd0a  ; -> Lbd0a
  00bcee:  b7 ec 00 3a          cmpa.l   $3a(a4), a3
  00bcf2:  66 04                bne.b    $bcf8  ; -> Lbcf8
  00bcf4:  7e 01                moveq    #$1, d7
  00bcf6:  60 12                bra.b    $bd0a  ; -> Lbd0a
Lbcf8:
  00bcf8:  b7 ec 00 20          cmpa.l   $20(a4), a3
  00bcfc:  66 04                bne.b    $bd02  ; -> Lbd02
  00bcfe:  7e 02                moveq    #$2, d7
  00bd00:  60 08                bra.b    $bd0a  ; -> Lbd0a
Lbd02:
  00bd02:  b7 ec 00 3e          cmpa.l   $3e(a4), a3
  00bd06:  66 02                bne.b    $bd0a  ; -> Lbd0a
  00bd08:  7e 03                moveq    #$3, d7
Lbd0a:
  00bd0a:  20 53                movea.l  (a3), a0
  00bd0c:  31 7c ff ff 00 0e    move.w   #$ffff, $e(a0)
  00bd12:  4a 87                tst.l    d7
  00bd14:  67 24                beq.b    $bd3a  ; -> Lbd3a
  00bd16:  70 00                moveq    #$0, d0
  00bd18:  2d 40 ff f8          move.l   d0, -$8(a6)
  00bd1c:  2d 47 ff fc          move.l   d7, -$4(a6)
  00bd20:  70 01                moveq    #$1, d0
  00bd22:  2f 00                move.l   d0, -(a7)
  00bd24:  72 02                moveq    #$2, d1
  00bd26:  2f 01                move.l   d1, -(a7)
  00bd28:  48 6e ff f8          pea.l    -$8(a6)
  00bd2c:  70 2a                moveq    #$2a, d0
  00bd2e:  2f 00                move.l   d0, -(a7)
  00bd30:  61 ff ff ff 8c 92    bsr.l    $49c4  ; -> EngineDispatch
  00bd36:  4f ef 00 10          lea.l    $10(a7), a7
Lbd3a:
  00bd3a:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  00bd40:  4e 5e                unlk     a6
  00bd42:  4e 74 00 04          rtd      #$4
Lbd46:
  00bd46:  4e 56 00 00          link.w   a6, #$0
  00bd4a:  70 00                moveq    #$0, d0
  00bd4c:  2f 00                move.l   d0, -(a7)
  00bd4e:  61 ff ff ff b1 cc    bsr.l    $6f1c  ; -> sub_6f1c
  00bd54:  b0 ae 00 08          cmp.l    $8(a6), d0
  00bd58:  58 4f                addq.w   #$4, a7
  00bd5a:  66 14                bne.b    $bd70  ; -> Lbd70
  00bd5c:  70 01                moveq    #$1, d0
  00bd5e:  2f 00                move.l   d0, -(a7)
  00bd60:  72 00                moveq    #$0, d1
  00bd62:  2f 01                move.l   d1, -(a7)
  00bd64:  2f 01                move.l   d1, -(a7)
  00bd66:  70 26                moveq    #$26, d0
  00bd68:  2f 00                move.l   d0, -(a7)
  00bd6a:  61 ff ff ff 8c 58    bsr.l    $49c4  ; -> EngineDispatch
Lbd70:
  00bd70:  4e 5e                unlk     a6
  00bd72:  4e 74 00 04          rtd      #$4
Lbd76:
  00bd76:  4e 56 00 00          link.w   a6, #$0
  00bd7a:  70 01                moveq    #$1, d0
  00bd7c:  2f 00                move.l   d0, -(a7)
  00bd7e:  2f 00                move.l   d0, -(a7)
  00bd80:  48 6e 00 08          pea.l    $8(a6)
  00bd84:  72 29                moveq    #$29, d1
  00bd86:  2f 01                move.l   d1, -(a7)
  00bd88:  61 ff ff ff 8c 3a    bsr.l    $49c4  ; -> EngineDispatch
  00bd8e:  4e 5e                unlk     a6
  00bd90:  4e 74 00 04          rtd      #$4
sub_bd94:
  00bd94:  4e 56 ff f8          link.w   a6, #$fff8
  00bd98:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  00bd9c:  26 6e 00 08          movea.l  $8(a6), a3
  00bda0:  59 8f                subq.l   #$4, a7
  00bda2:  2f 0b                move.l   a3, -(a7)
  00bda4:  48 78 1a 74          pea.l    $1a74.w
  00bda8:  61 ff ff ff af e8    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00bdae:  58 8f                addq.l   #$4, a7
  00bdb0:  2f 00                move.l   d0, -(a7)
  00bdb2:  20 3c 00 04 00 0f    move.l   #$4000f, d0
  00bdb8:  20 5f                movea.l  (a7)+, a0
  00bdba:  4e 90                jsr      (a0)
  00bdbc:  28 5f                movea.l  (a7)+, a4
  00bdbe:  20 0c                move.l   a4, d0
  00bdc0:  66 1a                bne.b    $bddc  ; -> Lbddc
  00bdc2:  70 01                moveq    #$1, d0
  00bdc4:  2f 00                move.l   d0, -(a7)
  00bdc6:  2f 00                move.l   d0, -(a7)
  00bdc8:  20 53                movea.l  (a3), a0
  00bdca:  2f 08                move.l   a0, -(a7)
  00bdcc:  72 33                moveq    #$33, d1
  00bdce:  2f 01                move.l   d1, -(a7)
  00bdd0:  61 ff ff ff 8b f2    bsr.l    $49c4  ; -> EngineDispatch
  00bdd6:  4f ef 00 10          lea.l    $10(a7), a7
  00bdda:  60 66                bra.b    $be42  ; -> Lbe42
Lbddc:
  00bddc:  20 53                movea.l  (a3), a0
  00bdde:  30 28 00 0e          move.w   $e(a0), d0
  00bde2:  48 c0                ext.l    d0
  00bde4:  2e 00                move.l   d0, d7
  00bde6:  70 01                moveq    #$1, d0
  00bde8:  b0 87                cmp.l    d7, d0
  00bdea:  67 06                beq.b    $bdf2  ; -> Lbdf2
  00bdec:  70 02                moveq    #$2, d0
  00bdee:  b0 87                cmp.l    d7, d0
  00bdf0:  66 50                bne.b    $be42  ; -> Lbe42
Lbdf2:
  00bdf2:  2f 0c                move.l   a4, -(a7)
  00bdf4:  61 ff ff ff c4 38    bsr.l    $822e  ; -> sub_822e
  00bdfa:  26 40                movea.l  d0, a3
  00bdfc:  20 0b                move.l   a3, d0
  00bdfe:  58 4f                addq.w   #$4, a7
  00be00:  67 36                beq.b    $be38  ; -> Lbe38
  00be02:  2d 4b ff f8          move.l   a3, -$8(a6)
  00be06:  4a 2e 00 0f          tst.b    $f(a6)
  00be0a:  67 06                beq.b    $be12  ; -> Lbe12
  00be0c:  20 4b                movea.l  a3, a0
  00be0e:  a0 69                dc.w     $a069  ; _HGetState
  00be10:  60 02                bra.b    $be14  ; -> Lbe14
Lbe12:
  00be12:  70 00                moveq    #$0, d0
Lbe14:
  00be14:  49 c0                extb.l   d0
  00be16:  2d 40 ff fc          move.l   d0, -$4(a6)
  00be1a:  70 01                moveq    #$1, d0
  00be1c:  2f 00                move.l   d0, -(a7)
  00be1e:  72 02                moveq    #$2, d1
  00be20:  2f 01                move.l   d1, -(a7)
  00be22:  48 6e ff f8          pea.l    -$8(a6)
  00be26:  70 0d                moveq    #$d, d0
  00be28:  2f 00                move.l   d0, -(a7)
  00be2a:  61 ff ff ff 8b 98    bsr.l    $49c4  ; -> EngineDispatch
  00be30:  26 40                movea.l  d0, a3
  00be32:  4f ef 00 10          lea.l    $10(a7), a7
  00be36:  60 04                bra.b    $be3c  ; -> Lbe3c
Lbe38:
  00be38:  70 00                moveq    #$0, d0
  00be3a:  26 40                movea.l  d0, a3
Lbe3c:
  00be3c:  20 0b                move.l   a3, d0
  00be3e:  67 02                beq.b    $be42  ; -> Lbe42
  00be40:  28 4b                movea.l  a3, a4
Lbe42:
  00be42:  61 ff ff ff af d0    bsr.l    $6e14  ; -> sub_6e14
  00be48:  4a 00                tst.b    d0
  00be4a:  67 f6                beq.b    $be42  ; -> Lbe42
  00be4c:  20 0c                move.l   a4, d0
  00be4e:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  00be54:  4e 5e                unlk     a6
  00be56:  4e 75                rts      
Lbe58:
  00be58:  4e 56 00 00          link.w   a6, #$0
  00be5c:  70 01                moveq    #$1, d0
  00be5e:  2f 00                move.l   d0, -(a7)
  00be60:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00be64:  61 ff ff ff ff 2e    bsr.l    $bd94  ; -> sub_bd94
  00be6a:  2d 40 00 0c          move.l   d0, $c(a6)
  00be6e:  4e 5e                unlk     a6
  00be70:  4e 74 00 04          rtd      #$4
Lbe74:
  00be74:  4e 56 00 00          link.w   a6, #$0
  00be78:  2f 0c                move.l   a4, -(a7)
  00be7a:  28 6e 00 08          movea.l  $8(a6), a4
  00be7e:  2f 0c                move.l   a4, -(a7)
  00be80:  48 78 1a 74          pea.l    $1a74.w
  00be84:  61 ff ff ff af 0c    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00be8a:  58 8f                addq.l   #$4, a7
  00be8c:  2f 00                move.l   d0, -(a7)
  00be8e:  20 3c 00 04 00 02    move.l   #$40002, d0
  00be94:  20 5f                movea.l  (a7)+, a0
  00be96:  4e 90                jsr      (a0)
  00be98:  70 01                moveq    #$1, d0
  00be9a:  2f 00                move.l   d0, -(a7)
  00be9c:  2f 00                move.l   d0, -(a7)
  00be9e:  20 54                movea.l  (a4), a0
  00bea0:  2f 08                move.l   a0, -(a7)
  00bea2:  72 33                moveq    #$33, d1
  00bea4:  2f 01                move.l   d1, -(a7)
  00bea6:  61 ff ff ff 8b 1c    bsr.l    $49c4  ; -> EngineDispatch
  00beac:  2f 0c                move.l   a4, -(a7)
  00beae:  48 78 1a 74          pea.l    $1a74.w
  00beb2:  61 ff ff ff ae de    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00beb8:  58 8f                addq.l   #$4, a7
  00beba:  2f 00                move.l   d0, -(a7)
  00bebc:  70 11                moveq    #$11, d0
  00bebe:  20 5f                movea.l  (a7)+, a0
  00bec0:  4e 90                jsr      (a0)
  00bec2:  28 6e ff fc          movea.l  -$4(a6), a4
  00bec6:  4e 5e                unlk     a6
  00bec8:  4e 74 00 04          rtd      #$4
Lbecc:
  00becc:  4e 56 00 00          link.w   a6, #$0
  00bed0:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00bed4:  28 6e 00 08          movea.l  $8(a6), a4
  00bed8:  70 00                moveq    #$0, d0
  00beda:  2f 00                move.l   d0, -(a7)
  00bedc:  61 ff ff ff b0 3e    bsr.l    $6f1c  ; -> sub_6f1c
  00bee2:  26 40                movea.l  d0, a3
  00bee4:  b7 cc                cmpa.l   a4, a3
  00bee6:  58 4f                addq.w   #$4, a7
  00bee8:  67 04                beq.b    $beee  ; -> Lbeee
  00beea:  20 0c                move.l   a4, d0
  00beec:  66 0c                bne.b    $befa  ; -> Lbefa
Lbeee:
  00beee:  61 ff ff ff af 24    bsr.l    $6e14  ; -> sub_6e14
  00bef4:  1d 40 00 0c          move.b   d0, $c(a6)
  00bef8:  60 06                bra.b    $bf00  ; -> Lbf00
Lbefa:
  00befa:  1d 7c 00 01 00 0c    move.b   #$1, $c(a6)
Lbf00:
  00bf00:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  00bf06:  4e 5e                unlk     a6
  00bf08:  4e 74 00 04          rtd      #$4
handler_100:
  00bf0c:  4e 56 ff fa          link.w   a6, #$fffa
  00bf10:  48 e7 03 08          movem.l  d6-d7/a4, -(a7)
  00bf14:  28 6e 00 08          movea.l  $8(a6), a4
  00bf18:  48 6e ff fe          pea.l    -$2(a6)
  00bf1c:  48 6e ff fa          pea.l    -$6(a6)
  00bf20:  2f 0c                move.l   a4, -(a7)
  00bf22:  61 ff ff ff c7 b2    bsr.l    $86d6  ; -> sub_86d6
  00bf28:  1c 00                move.b   d0, d6
  00bf2a:  55 8f                subq.l   #$2, a7
  00bf2c:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00bf30:  2f 0c                move.l   a4, -(a7)
  00bf32:  48 78 11 5c          pea.l    $115c.w
  00bf36:  61 ff ff ff ae 5a    bsr.l    $6d92  ; -> StoreCtxWord_AA6
  00bf3c:  58 8f                addq.l   #$4, a7
  00bf3e:  2f 00                move.l   d0, -(a7)
  00bf40:  20 5f                movea.l  (a7)+, a0
  00bf42:  4e 90                jsr      (a0)
  00bf44:  3e 1f                move.w   (a7)+, d7
  00bf46:  4a 06                tst.b    d6
  00bf48:  4f ef 00 0c          lea.l    $c(a7), a7
  00bf4c:  67 18                beq.b    $bf66  ; -> Lbf66
  00bf4e:  30 2e ff fe          move.w   -$2(a6), d0
  00bf52:  48 c0                ext.l    d0
  00bf54:  2f 00                move.l   d0, -(a7)
  00bf56:  2f 2e ff fa          move.l   -$6(a6), -(a7)
  00bf5a:  2f 0c                move.l   a4, -(a7)
  00bf5c:  61 ff ff ff c8 3c    bsr.l    $879a  ; -> sub_879a
  00bf62:  4f ef 00 0c          lea.l    $c(a7), a7
Lbf66:
  00bf66:  3d 47 00 10          move.w   d7, $10(a6)
  00bf6a:  4c ee 10 c0 ff ee    movem.l  -$12(a6), d6-d7/a4
  00bf70:  4e 5e                unlk     a6
  00bf72:  4e 74 00 08          rtd      #$8
sub_bf76:
  00bf76:  2f 2f 00 04          move.l   $4(a7), -(a7)
  00bf7a:  4e ba 00 34          jsr      $bfb0(pc)  ; -> sub_bfb0
  00bf7e:  ab ff                dc.w     $abff  ; _DebugStr
  00bf80:  2f 2f 00 04          move.l   $4(a7), -(a7)
  00bf84:  4e ba 00 06          jsr      $bf8c(pc)  ; -> sub_bf8c
  00bf88:  58 4f                addq.w   #$4, a7
  00bf8a:  4e 75                rts      
sub_bf8c:
  00bf8c:  20 2f 00 04          move.l   $4(a7), d0
  00bf90:  67 12                beq.b    $bfa4  ; -> Lbfa4
  00bf92:  20 40                movea.l  d0, a0
  00bf94:  42 41                clr.w    d1
  00bf96:  12 10                move.b   (a0), d1
  00bf98:  60 04                bra.b    $bf9e  ; -> Lbf9e
Lbf9a:
  00bf9a:  10 e8 00 01          move.b   $1(a0), (a0)+
Lbf9e:
  00bf9e:  51 c9 ff fa          dbra     d1, $bf9a  ; -> Lbf9a
  00bfa2:  42 10                clr.b    (a0)
Lbfa4:
  00bfa4:  4e 75                rts      
  00bfa6:  86 70 32 63          or.w     $63(a0, d3.w), d3
  00bfaa:  73 74 72 00 00 00    dc.b     $73,$74,$72,$00,$00,$00  ; str...
sub_bfb0:
  00bfb0:  20 2f 00 04          move.l   $4(a7), d0
  00bfb4:  67 1c                beq.b    $bfd2  ; -> Lbfd2
  00bfb6:  20 40                movea.l  d0, a0
  00bfb8:  22 40                movea.l  d0, a1
  00bfba:  34 3c 00 ff          move.w   #$ff, d2
Lbfbe:
  00bfbe:  12 10                move.b   (a0), d1
  00bfc0:  10 c0                move.b   d0, (a0)+
  00bfc2:  10 01                move.b   d1, d0
  00bfc4:  57 ca ff f8          dbeq     d2, $bfbe  ; -> Lbfbe
  00bfc8:  22 08                move.l   a0, d1
  00bfca:  20 09                move.l   a1, d0
  00bfcc:  92 80                sub.l    d0, d1
  00bfce:  53 01                subq.b   #$1, d1
  00bfd0:  12 81                move.b   d1, (a1)
Lbfd2:
  00bfd2:  4e 75                rts      
  00bfd4:  86 63                or.w     -(a3), d3
  00bfd6:  32 70 73 74 72 00 00 00 dc.b     $32,$70,$73,$74,$72,$00,$00,$00  ; 2pstr...
sub_bfde:
  00bfde:  22 5f                movea.l  (a7)+, a1
  00bfe0:  20 5f                movea.l  (a7)+, a0
  00bfe2:  a0 25                dc.w     $a025  ; _GetPtrSize
  00bfe4:  2e 80                move.l   d0, (a7)
  00bfe6:  6a 02                bpl.b    $bfea  ; -> Lbfea
  00bfe8:  42 97                clr.l    (a7)
Lbfea:
  00bfea:  4e d1                jmp      (a1)
sub_bfec:
  00bfec:  22 5f                movea.l  (a7)+, a1
  00bfee:  12 1f                move.b   (a7)+, d1
  00bff0:  30 1f                move.w   (a7)+, d0
  00bff2:  4a 01                tst.b    d1
  00bff4:  67 04                beq.b    $bffa  ; -> Lbffa
  00bff6:  a7 46                dc.w     $a746  ; _GetToolBoxTrapAddress
  00bff8:  60 02                bra.b    $bffc  ; -> Lbffc
Lbffa:
  00bffa:  a3 46                dc.w     $a346  ; _GetOSTrapAddress
Lbffc:
  00bffc:  2e 88                move.l   a0, (a7)
  00bffe:  4e d1                jmp      (a1)
sub_c000:
  00c000:  20 5f                movea.l  (a7)+, a0
  00c002:  30 1f                move.w   (a7)+, d0
  00c004:  42 97                clr.l    (a7)
  00c006:  46 40                not.w    d0
  00c008:  b0 78 01 d2          cmp.w    $1d2.w, d0
  00c00c:  64 0a                bcc.b    $c018  ; -> Lc018
  00c00e:  e5 48                lsl.w    #$2, d0
  00c010:  22 78 01 1c          movea.l  $11c.w, a1
  00c014:  2e b1 00 00          move.l   (a1, d0.w), (a7)
Lc018:
  00c018:  4e d0                jmp      (a0)
* HWPrivProbe  -  queries the hardware via _HWPriv (selector 2);
* returns 0/1.  Used during environment/capability checks.
HWPrivProbe:
  00c01a:  22 5f                movea.l  (a7)+, a1
  00c01c:  70 00                moveq    #$0, d0
  00c01e:  10 1f                move.b   (a7)+, d0
  00c020:  20 40                movea.l  d0, a0
  00c022:  30 3c 00 02          move.w   #$2, d0
  00c026:  a1 98                dc.w     $a198  ; _HWPriv
  00c028:  30 08                move.w   a0, d0
  00c02a:  4a 40                tst.w    d0
  00c02c:  67 02                beq.b    $c030  ; -> Lc030
  00c02e:  70 01                moveq    #$1, d0
Lc030:
  00c030:  1e 80                move.b   d0, (a7)
  00c032:  4e d1                jmp      (a1)
sub_c034:
  00c034:  22 5f                movea.l  (a7)+, a1
  00c036:  70 03                moveq    #$3, d0
  00c038:  a1 98                dc.w     $a198  ; _HWPriv
  00c03a:  4e d1                jmp      (a1)
sub_c03c:
  00c03c:  4e 56 00 00          link.w   a6, #$0
  00c040:  20 3c 00 00 a8 9f    move.l   #$a89f, d0
  00c046:  a7 46                dc.w     $a746  ; _GetToolBoxTrapAddress
  00c048:  2f 08                move.l   a0, -(a7)
  00c04a:  20 3c 00 00 a0 ad    move.l   #$a0ad, d0
  00c050:  a3 46                dc.w     $a346  ; _GetOSTrapAddress
  00c052:  b1 df                cmpa.l   (a7)+, a0
  00c054:  67 0e                beq.b    $c064  ; -> Lc064
  00c056:  20 2e 00 0c          move.l   $c(a6), d0
  00c05a:  a1 ad                dc.w     $a1ad  ; _Gestalt
  00c05c:  22 6e 00 08          movea.l  $8(a6), a1
  00c060:  22 88                move.l   a0, (a1)
  00c062:  60 26                bra.b    $c08a  ; -> Lc08a
Lc064:
  00c064:  41 fa 00 36          lea.l    $c09c(pc), a0
  00c068:  30 3c ea 51          move.w   #$ea51, d0
  00c06c:  22 2e 00 0c          move.l   $c(a6), d1
Lc070:
  00c070:  b2 98                cmp.l    (a0)+, d1
  00c072:  67 06                beq.b    $c07a  ; -> Lc07a
  00c074:  4a 98                tst.l    (a0)+
  00c076:  67 12                beq.b    $c08a  ; -> Lc08a
  00c078:  60 f6                bra.b    $c070  ; -> Lc070
Lc07a:
  00c07a:  43 fa 00 20          lea.l    $c09c(pc), a1
  00c07e:  d3 d0                adda.l   (a0), a1
  00c080:  4e d1                jmp      (a1)
  00c082:  22 6e 00 08          movea.l  $8(a6), a1
  00c086:  22 80                move.l   d0, (a1)
  00c088:  42 40                clr.w    d0
Lc08a:
  00c08a:  3d 40 00 10          move.w   d0, $10(a6)
  00c08e:  4e 5e                unlk     a6
  00c090:  20 5f                movea.l  (a7)+, a0
  00c092:  50 8f                addq.l   #$8, a7
  00c094:  4e d0                jmp      (a0)
  00c096:  30 3c ea 52          move.w   #$ea52, d0
  00c09a:  60 ee                bra.b    $c08a  ; -> Lc08a
* GestaltSelectorTable  -  (OSType, offset) pairs the engine probes via
* _Gestalt to vet the environment: vers/mach/sysv/proc/fpu/qd/kbd/atlk/
* mmu/dram/lram.  Gates acceleration (cf. the requirement strings).
GestaltSelectorTable:
  00c09c:  76 65 72 73 00 00 00 60 dc.l     $76657273,$00000060  ; Gestalt 'vers'
  00c0a4:  6d 61 63 68 00 00 00 64 dc.l     $6D616368,$00000064  ; Gestalt 'mach'
  00c0ac:  73 79 73 76 00 00 00 88 dc.l     $73797376,$00000088  ; Gestalt 'sysv'
  00c0b4:  70 72 6f 63 00 00 00 92 dc.l     $70726F63,$00000092  ; Gestalt 'proc'
  00c0bc:  66 70 75 20 00 00 00 9e dc.l     $66707520,$0000009E  ; Gestalt 'fpu '
  00c0c4:  71 64 20 20 00 00 00 e8 dc.l     $71642020,$000000E8  ; Gestalt 'qd  '
  00c0cc:  6b 62 64 20 00 00 01 1a dc.l     $6B626420,$0000011A  ; Gestalt 'kbd '
  00c0d4:  61 74 6c 6b 00 00 01 42 dc.l     $61746C6B,$00000142  ; Gestalt 'atlk'
  00c0dc:  6d 6d 75 20 00 00 01 64 dc.l     $6D6D7520,$00000164  ; Gestalt 'mmu '
  00c0e4:  72 61 6d 20 00 00 01 88 dc.l     $72616D20,$00000188  ; Gestalt 'ram '
  00c0ec:  6c 72 61 6d 00 00 01 88 dc.l     $6C72616D,$00000188  ; Gestalt 'lram'
  00c0f4:  00 00 00 00 00 00 00 00 dc.l     $00000000,$00000000  ; end
  00c0fc:  70 01                moveq    #$1, d0
  00c0fe:  60 82                bra.b    $c082
  00c100:  22 78 02 ae          movea.l  $2ae.w, a1
  00c104:  70 04                moveq    #$4, d0
  00c106:  0c 69 00 75 00 08    cmpi.w   #$75, $8(a1)
  00c10c:  67 12                beq.b    $c120
  00c10e:  0c 69 02 76 00 08    cmpi.w   #$276, $8(a1)
  00c114:  66 04                bne.b    $c11a
  00c116:  52 40                addq.w   #$1, d0
  00c118:  60 06                bra.b    $c120
  00c11a:  10 38 0c b3          move.b   $cb3.w, d0
  00c11e:  5c 80                addq.l   #$6, d0
  00c120:  60 00 ff 60          bra.w    $c082
  00c124:  70 00                moveq    #$0, d0
  00c126:  30 38 01 5a          move.w   $15a.w, d0
  00c12a:  60 00 ff 56          bra.w    $c082
  00c12e:  70 00                moveq    #$0, d0
  00c130:  10 38 01 2f          move.b   $12f.w, d0
  00c134:  52 40                addq.w   #$1, d0
  00c136:  60 00 ff 4a          bra.w    $c082
  00c13a:  0c 38 00 04 01 2f    cmpi.b   #$4, $12f.w
  00c140:  67 38                beq.b    $c17a
  00c142:  08 38 00 04 0b 22    btst.b   #$4, $b22.w  ; -> GlobalsAccessor
  00c148:  67 34                beq.b    $c17e
  00c14a:  20 4f                movea.l  a7, a0
  00c14c:  f2 80 00 00          fnop     
  00c150:  f3 27                fsave    -(a7)
  00c152:  30 17                move.w   (a7), d0
  00c154:  2e 48                movea.l  a0, a7
  00c156:  0c 40 1f 18          cmpi.w   #$1f18, d0
  00c15a:  67 16                beq.b    $c172
  00c15c:  0c 40 3f 18          cmpi.w   #$3f18, d0
  00c160:  67 10                beq.b    $c172
  00c162:  0c 40 3f 38          cmpi.w   #$3f38, d0
  00c166:  67 0e                beq.b    $c176
  00c168:  0c 40 1f 38          cmpi.w   #$1f38, d0
  00c16c:  67 08                beq.b    $c176
  00c16e:  70 00                moveq    #$0, d0
  00c170:  60 0e                bra.b    $c180
  00c172:  70 01                moveq    #$1, d0
  00c174:  60 0a                bra.b    $c180
  00c176:  70 02                moveq    #$2, d0
  00c178:  60 06                bra.b    $c180
  00c17a:  70 03                moveq    #$3, d0
  00c17c:  60 02                bra.b    $c180
  00c17e:  70 00                moveq    #$0, d0
  00c180:  60 00 ff 00          bra.w    $c082
  00c184:  0c 78 3f ff 02 8e    cmpi.w   #$3fff, $28e.w
  00c18a:  6e 1c                bgt.b    $c1a8
  00c18c:  30 3c a8 9f          move.w   #$a89f, d0
  00c190:  a7 46                dc.w     $a746  ; _GetToolBoxTrapAddress
  00c192:  24 08                move.l   a0, d2
  00c194:  20 3c 00 00 ab 03    move.l   #$ab03, d0
  00c19a:  a7 46                dc.w     $a746  ; _GetToolBoxTrapAddress
  00c19c:  20 3c 00 00 01 00    move.l   #$100, d0
  00c1a2:  b4 88                cmp.l    a0, d2
  00c1a4:  66 06                bne.b    $c1ac
  00c1a6:  60 0a                bra.b    $c1b2
  00c1a8:  70 00                moveq    #$0, d0
  00c1aa:  60 06                bra.b    $c1b2
  00c1ac:  20 3c 00 00 02 00    move.l   #$200, d0
  00c1b2:  60 00 fe ce          bra.w    $c082
  00c1b6:  10 38 02 1e          move.b   $21e.w, d0
  00c1ba:  41 fa 00 16          lea.l    $c1d2(pc), a0
  00c1be:  22 48                movea.l  a0, a1
  00c1c0:  12 18                move.b   (a0)+, d1
  00c1c2:  67 00 fe d2          beq.w    $c096
  00c1c6:  b2 00                cmp.b    d0, d1
  00c1c8:  66 f6                bne.b    $c1c0
  00c1ca:  91 c9                suba.l   a1, a0
  00c1cc:  20 08                move.l   a0, d0
  00c1ce:  60 00 fe b2          bra.w    $c082
  00c1d2:  03 13                btst.l   d1, (a3)
  00c1d4:  0b 02                btst.l   d5, d2
  00c1d6:  01 06                btst.l   d0, d6
  00c1d8:  07 04                btst.l   d3, d4
  00c1da:  05 08 09 00          movep.w  $900(a0), d2
  00c1de:  70 00                moveq    #$0, d0
  00c1e0:  4a 38 02 91          tst.b    $291.w
  00c1e4:  6b 16                bmi.b    $c1fc
  00c1e6:  12 38 01 fb          move.b   $1fb.w, d1
  00c1ea:  02 01 00 0f          andi.b   #$f, d1
  00c1ee:  0c 01 00 01          cmpi.b   #$1, d1
  00c1f2:  66 08                bne.b    $c1fc
  00c1f4:  20 78 02 dc          movea.l  $2dc.w, a0
  00c1f8:  10 28 00 07          move.b   $7(a0), d0
  00c1fc:  60 00 fe 84          bra.w    $c082
  00c200:  0c 38 00 02 01 2f    cmpi.b   #$2, $12f.w
  00c206:  6d 16                blt.b    $c21e
  00c208:  70 00                moveq    #$0, d0
  00c20a:  10 38 0c b1          move.b   $cb1.w, d0
  00c20e:  0c 00 00 01          cmpi.b   #$1, d0
  00c212:  67 0c                beq.b    $c220
  00c214:  0c 00 00 03          cmpi.b   #$3, d0
  00c218:  6d 04                blt.b    $c21e
  00c21a:  53 40                subq.w   #$1, d0
  00c21c:  60 02                bra.b    $c220
  00c21e:  70 00                moveq    #$0, d0
  00c220:  60 00 fe 60          bra.w    $c082
  00c224:  30 3c a8 9f          move.w   #$a89f, d0
  00c228:  a7 46                dc.w     $a746  ; _GetToolBoxTrapAddress
  00c22a:  24 08                move.l   a0, d2
  00c22c:  20 3c 00 00 a8 8f    move.l   #$a88f, d0
  00c232:  a7 46                dc.w     $a746  ; _GetToolBoxTrapAddress
  00c234:  20 38 01 08          move.l   $108.w, d0
  00c238:  b4 88                cmp.l    a0, d2
  00c23a:  67 0a                beq.b    $c246
  00c23c:  59 8f                subq.l   #$4, a7
  00c23e:  3f 3c 00 16          move.w   #$16, -(a7)
  00c242:  a8 8f                dc.w     $a88f  ; _OSDispatch
  00c244:  20 1f                move.l   (a7)+, d0
  00c246:  60 00 fe 3a          bra.w    $c082
* Strip24  -  StripAddress helper (called ~50x).  Pops one long, and if
* the machine is in 24-bit mode (low-mem $28E bit 6 clear) runs
* _StripAddress, else ANDs with the 32-bit mask $31A.  Re-pushes + returns.
Strip24:
  00c24a:  22 5f                movea.l  (a7)+, a1
  00c24c:  20 1f                move.l   (a7)+, d0
  00c24e:  08 38 00 06 02 8e    btst.b   #$6, $28e.w
  00c254:  66 06                bne.b    $c25c  ; -> Lc25c
  00c256:  a0 55                dc.w     $a055  ; _StripAddress
  00c258:  2e 80                move.l   d0, (a7)
  00c25a:  4e d1                jmp      (a1)
Lc25c:
  00c25c:  c0 b8 03 1a          and.l    $31a.w, d0
  00c260:  2e 80                move.l   d0, (a7)
  00c262:  4e d1                jmp      (a1)
sub_c264:
  00c264:  22 1f                move.l   (a7)+, d1
  00c266:  24 1f                move.l   (a7)+, d2
  00c268:  22 42                movea.l  d2, a1
  00c26a:  22 51                movea.l  (a1), a1
  00c26c:  20 5f                movea.l  (a7)+, a0
  00c26e:  70 05                moveq    #$5, d0
  00c270:  a1 5c                dc.w     $a15c  ; _MemoryDispatchA0Result
  00c272:  3e 80                move.w   d0, (a7)
  00c274:  22 42                movea.l  d2, a1
  00c276:  22 88                move.l   a0, (a1)
  00c278:  22 41                movea.l  d1, a1
  00c27a:  4e d1                jmp      (a1)
