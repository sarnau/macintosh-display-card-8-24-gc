* ==================================================================
*  gc24_sw11.s  -  System 6 QuickDraw GC engine ('gc24' id -4048, "GCQD")
*                  from 8*24 GC SW 1.1 (for System 6), 42444 bytes, 68020.
* ==================================================================
*  The System 6 counterpart of gc24.s (System 7, 48 KB): the host-side
*  QuickDraw patches and the command path to the Am29000.
*
*  Layout:
*    $0000..$120B  dispatch table - 105 entries x $2C (44) bytes (System 7:
*                  106 x $30).  Each entry: +$00 dc.l trap-table slot or
*                  low-mem vector (-1/-2/-3 = the driver's control entries
*                  $85AA, $8638, $8580), +$04 GlobalsAccessor stub, +$28
*                  bra.w to the handler.  The dc.l is shown as data.
*    $120C..       handler + engine code.
*
*  How it was made: resource extracted with control-panel/extract_resources.py,
*  then a recursive descent with capstone 5 (CS_MODE_M68K_020) from the
*  table stubs and handlers, following pc-relative branches/calls and
*  `move.w (pc,dn) / jmp (pc,dn.w)' switch tables, plus every `link a6' in the
*  remaining gaps.  Bytes not reached are shown as dc.b with ASCII (strings,
*  the compiler's plain-text MacsBug names after rts, padding, and a few
*  unreached code fragments).  A-line traps print as dc.w $Axxx.  Labels are
*  sub_<addr> for call targets and L<addr> for branch targets; switch-table
*  words are listed as [index] -> target.
*  Rebuild: extract_resources.py RSRC OUT/ gc24, then
*    gc24_sw11_dasm.py OUT/gc24_-4048.bin gc24_sw11_notes.py gc24_sw11.s
*
*  Annotated at the command-path points below (EngineDispatch, the packet
*  post, the argument copy, the go/wait loop, the reply, and the
*  packet-pointer read-back), each naming its System 7 (gc24.s) counterpart.
*  164 of the 200 functions carry their System 7 name and address (a
*  "System 7 $xxxx" line, plus the first line of the S7 banner as "S7:");
*  unnamed S7 routines are s7_sub_<S7 address>.  Not in System 7: the
*  QuickTime 'rpza' codec and its helpers ($87C6-$87F2, $94E4-$A1D2) and the
*  Toolbox trap glue at $A3FC-$A59E (System 7 issues the A-traps inline).
*  Only in System 7: ACEFLoad and its helpers, GA_MoveHHi, Strip24 (inlined
*  here) and GestaltSelectorTable.
*  The code is the same compiler output as System 7's with the offsets
*  shifted; Strip24 is inlined here as `and.l #$ffffff' and HWPrivProbe is
*  $A532 (System 7 $C01A).
*
*  Unit record (a3 in EngineDispatch, [[globals+$214]]): +$0C packet,
*  +$10 status-long pointer, +$18 argument-area pointer, +$1C flags,
*  +$20 sequence.  Packet: +$14 go, +$18, +$1C reply, +$48 cmd, +$4C seq,
*  +$50 n, +$54 argument-area address published by the card.
*
  000000:  00 00 06 44          dc.l     $00000644  ; dispatch #0
L4:
  000004:  2f 08                move.l   a0, -(a7)
  000006:  20 78 08 88          movea.l  $888.w, a0
  00000a:  20 50                movea.l  (a0), a0
  00000c:  2f 00                move.l   d0, -(a7)
  00000e:  20 10                move.l   (a0), d0
  000010:  e1 88                lsl.l    #$8, d0
  000012:  e0 88                lsr.l    #$8, d0
  000014:  20 40                movea.l  d0, a0
  000016:  20 1f                move.l   (a7)+, d0
  000018:  d0 fc 00 14          adda.w   #$14, a0
  00001c:  2f 10                move.l   (a0), -(a7)
  00001e:  20 6f 00 04          movea.l  $4(a7), a0
  000022:  2e 9f                move.l   (a7)+, (a7)
  000024:  4e 75                rts
  000026:  4e 71                dc.b     $4E, $71  ; Nq
  000028:  60 00 50 5e          bra.w    $5088  ; -> GA_Translate24To32
  00002c:  00 00 08 ee          dc.l     $000008EE  ; dispatch #1
L30:
  000030:  2f 08                move.l   a0, -(a7)
  000032:  20 78 08 88          movea.l  $888.w, a0
  000036:  20 50                movea.l  (a0), a0
  000038:  2f 00                move.l   d0, -(a7)
  00003a:  20 10                move.l   (a0), d0
  00003c:  e1 88                lsl.l    #$8, d0
  00003e:  e0 88                lsr.l    #$8, d0
  000040:  20 40                movea.l  d0, a0
  000042:  20 1f                move.l   (a7)+, d0
  000044:  d0 fc 00 14          adda.w   #$14, a0
  000048:  2f 28 00 04          move.l   $4(a0), -(a7)
  00004c:  20 6f 00 04          movea.l  $4(a7), a0
  000050:  2e 9f                move.l   (a7)+, (a7)
  000052:  4e 75                rts
  000054:  60 00 11 e6          bra.w    $123c  ; -> GACursorTask
  000058:  00 00 11 b0          dc.l     $000011B0  ; dispatch #2
L5c:
  00005c:  2f 08                move.l   a0, -(a7)
  00005e:  20 78 08 88          movea.l  $888.w, a0
  000062:  20 50                movea.l  (a0), a0
  000064:  2f 00                move.l   d0, -(a7)
  000066:  20 10                move.l   (a0), d0
  000068:  e1 88                lsl.l    #$8, d0
  00006a:  e0 88                lsr.l    #$8, d0
  00006c:  20 40                movea.l  d0, a0
  00006e:  20 1f                move.l   (a7)+, d0
  000070:  d0 fc 00 14          adda.w   #$14, a0
  000074:  2f 28 00 08          move.l   $8(a0), -(a7)
  000078:  20 6f 00 04          movea.l  $4(a7), a0
  00007c:  2e 9f                move.l   (a7)+, (a7)
  00007e:  4e 75                rts
  000080:  60 00 60 2a          bra.w    $60ac  ; -> GA_CopyBits
  000084:  00 00 10 40          dc.l     $00001040  ; dispatch #3
L88:
  000088:  2f 08                move.l   a0, -(a7)
  00008a:  20 78 08 88          movea.l  $888.w, a0
  00008e:  20 50                movea.l  (a0), a0
  000090:  2f 00                move.l   d0, -(a7)
  000092:  20 10                move.l   (a0), d0
  000094:  e1 88                lsl.l    #$8, d0
  000096:  e0 88                lsr.l    #$8, d0
  000098:  20 40                movea.l  d0, a0
  00009a:  20 1f                move.l   (a7)+, d0
  00009c:  d0 fc 00 14          adda.w   #$14, a0
  0000a0:  2f 28 00 0c          move.l   $c(a0), -(a7)
  0000a4:  20 6f 00 04          movea.l  $4(a7), a0
  0000a8:  2e 9f                move.l   (a7)+, (a7)
  0000aa:  4e 75                rts
  0000ac:  60 00 53 96          bra.w    $5444  ; -> GA_StdLine
  0000b0:  00 00 10 f4          dc.l     $000010F4  ; dispatch #4
Lb4:
  0000b4:  2f 08                move.l   a0, -(a7)
  0000b6:  20 78 08 88          movea.l  $888.w, a0
  0000ba:  20 50                movea.l  (a0), a0
  0000bc:  2f 00                move.l   d0, -(a7)
  0000be:  20 10                move.l   (a0), d0
  0000c0:  e1 88                lsl.l    #$8, d0
  0000c2:  e0 88                lsr.l    #$8, d0
  0000c4:  20 40                movea.l  d0, a0
  0000c6:  20 1f                move.l   (a7)+, d0
  0000c8:  d0 fc 00 14          adda.w   #$14, a0
  0000cc:  2f 28 00 10          move.l   $10(a0), -(a7)
  0000d0:  20 6f 00 04          movea.l  $4(a7), a0
  0000d4:  2e 9f                move.l   (a7)+, (a7)
  0000d6:  4e 75                rts
  0000d8:  60 00 56 36          bra.w    $5710  ; -> GA_StdArc
  0000dc:  00 00 10 08          dc.l     $00001008  ; dispatch #5
Le0:
  0000e0:  2f 08                move.l   a0, -(a7)
  0000e2:  20 78 08 88          movea.l  $888.w, a0
  0000e6:  20 50                movea.l  (a0), a0
  0000e8:  2f 00                move.l   d0, -(a7)
  0000ea:  20 10                move.l   (a0), d0
  0000ec:  e1 88                lsl.l    #$8, d0
  0000ee:  e0 88                lsr.l    #$8, d0
  0000f0:  20 40                movea.l  d0, a0
  0000f2:  20 1f                move.l   (a7)+, d0
  0000f4:  d0 fc 00 14          adda.w   #$14, a0
  0000f8:  2f 28 00 14          move.l   $14(a0), -(a7)
  0000fc:  20 6f 00 04          movea.l  $4(a7), a0
  000100:  2e 9f                move.l   (a7)+, (a7)
  000102:  4e 75                rts
  000104:  60 00 54 fc          bra.w    $5602  ; -> GA_StdText
  000108:  00 00 1a 9c          dc.l     $00001A9C  ; dispatch #6
L10c:
  00010c:  2f 08                move.l   a0, -(a7)
  00010e:  20 78 08 88          movea.l  $888.w, a0
  000112:  20 50                movea.l  (a0), a0
  000114:  2f 00                move.l   d0, -(a7)
  000116:  20 10                move.l   (a0), d0
  000118:  e1 88                lsl.l    #$8, d0
  00011a:  e0 88                lsr.l    #$8, d0
  00011c:  20 40                movea.l  d0, a0
  00011e:  20 1f                move.l   (a7)+, d0
  000120:  d0 fc 00 14          adda.w   #$14, a0
  000124:  2f 28 00 18          move.l   $18(a0), -(a7)
  000128:  20 6f 00 04          movea.l  $4(a7), a0
  00012c:  2e 9f                move.l   (a7)+, (a7)
  00012e:  4e 75                rts
  000130:  60 00 50 16          bra.w    $5148  ; -> GA_TrapAB27
  000134:  00 00 08 00          dc.l     $00000800  ; dispatch #7
L138:
  000138:  2f 08                move.l   a0, -(a7)
  00013a:  20 78 08 88          movea.l  $888.w, a0
  00013e:  20 50                movea.l  (a0), a0
  000140:  2f 00                move.l   d0, -(a7)
  000142:  20 10                move.l   (a0), d0
  000144:  e1 88                lsl.l    #$8, d0
  000146:  e0 88                lsr.l    #$8, d0
  000148:  20 40                movea.l  d0, a0
  00014a:  20 1f                move.l   (a7)+, d0
  00014c:  d0 fc 00 14          adda.w   #$14, a0
  000150:  2f 28 00 1c          move.l   $1c(a0), -(a7)
  000154:  20 6f 00 04          movea.l  $4(a7), a0
  000158:  2e 9f                move.l   (a7)+, (a7)
  00015a:  4e 75                rts
  00015c:  60 00 59 fe          bra.w    $5b5c  ; -> GA_LowMem0800
  000160:  00 00 08 04          dc.l     $00000804  ; dispatch #8
L164:
  000164:  2f 08                move.l   a0, -(a7)
  000166:  20 78 08 88          movea.l  $888.w, a0
  00016a:  20 50                movea.l  (a0), a0
  00016c:  2f 00                move.l   d0, -(a7)
  00016e:  20 10                move.l   (a0), d0
  000170:  e1 88                lsl.l    #$8, d0
  000172:  e0 88                lsr.l    #$8, d0
  000174:  20 40                movea.l  d0, a0
  000176:  20 1f                move.l   (a7)+, d0
  000178:  d0 fc 00 14          adda.w   #$14, a0
  00017c:  2f 28 00 20          move.l   $20(a0), -(a7)
  000180:  20 6f 00 04          movea.l  $4(a7), a0
  000184:  2e 9f                move.l   (a7)+, (a7)
  000186:  4e 75                rts
  000188:  60 00 59 64          bra.w    $5aee  ; -> GA_LowMem0804
  00018c:  00 00 08 08          dc.l     $00000808  ; dispatch #9
L190:
  000190:  2f 08                move.l   a0, -(a7)
  000192:  20 78 08 88          movea.l  $888.w, a0
  000196:  20 50                movea.l  (a0), a0
  000198:  2f 00                move.l   d0, -(a7)
  00019a:  20 10                move.l   (a0), d0
  00019c:  e1 88                lsl.l    #$8, d0
  00019e:  e0 88                lsr.l    #$8, d0
  0001a0:  20 40                movea.l  d0, a0
  0001a2:  20 1f                move.l   (a7)+, d0
  0001a4:  d0 fc 00 14          adda.w   #$14, a0
  0001a8:  2f 28 00 24          move.l   $24(a0), -(a7)
  0001ac:  20 6f 00 04          movea.l  $4(a7), a0
  0001b0:  2e 9f                move.l   (a7)+, (a7)
  0001b2:  4e 75                rts
  0001b4:  60 00 5b 6a          bra.w    $5d20  ; -> GA_LowMem0808
  0001b8:  00 00 1c 68          dc.l     $00001C68  ; dispatch #10
L1bc:
  0001bc:  2f 08                move.l   a0, -(a7)
  0001be:  20 78 08 88          movea.l  $888.w, a0
  0001c2:  20 50                movea.l  (a0), a0
  0001c4:  2f 00                move.l   d0, -(a7)
  0001c6:  20 10                move.l   (a0), d0
  0001c8:  e1 88                lsl.l    #$8, d0
  0001ca:  e0 88                lsr.l    #$8, d0
  0001cc:  20 40                movea.l  d0, a0
  0001ce:  20 1f                move.l   (a7)+, d0
  0001d0:  d0 fc 00 14          adda.w   #$14, a0
  0001d4:  2f 28 00 28          move.l   $28(a0), -(a7)
  0001d8:  20 6f 00 04          movea.l  $4(a7), a0
  0001dc:  2e 9f                move.l   (a7)+, (a7)
  0001de:  4e 75                rts
  0001e0:  60 00 17 06          bra.w    $18e8  ; -> GA_TrapAB9A
  0001e4:  00 00 10 64          dc.l     $00001064  ; dispatch #11
L1e8:
  0001e8:  2f 08                move.l   a0, -(a7)
  0001ea:  20 78 08 88          movea.l  $888.w, a0
  0001ee:  20 50                movea.l  (a0), a0
  0001f0:  2f 00                move.l   d0, -(a7)
  0001f2:  20 10                move.l   (a0), d0
  0001f4:  e1 88                lsl.l    #$8, d0
  0001f6:  e0 88                lsr.l    #$8, d0
  0001f8:  20 40                movea.l  d0, a0
  0001fa:  20 1f                move.l   (a7)+, d0
  0001fc:  d0 fc 00 14          adda.w   #$14, a0
  000200:  2f 28 00 2c          move.l   $2c(a0), -(a7)
  000204:  20 6f 00 04          movea.l  $4(a7), a0
  000208:  2e 9f                move.l   (a7)+, (a7)
  00020a:  4e 75                rts
  00020c:  60 00 23 40          bra.w    $254e  ; -> GA_SetPenState
  000210:  00 00 10 6c          dc.l     $0000106C  ; dispatch #12
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
  000228:  d0 fc 00 14          adda.w   #$14, a0
  00022c:  2f 28 00 30          move.l   $30(a0), -(a7)
  000230:  20 6f 00 04          movea.l  $4(a7), a0
  000234:  2e 9f                move.l   (a7)+, (a7)
  000236:  4e 75                rts
  000238:  60 00 23 da          bra.w    $2614  ; -> GA_PenSize
  00023c:  00 00 10 70          dc.l     $00001070  ; dispatch #13
L240:
  000240:  2f 08                move.l   a0, -(a7)
  000242:  20 78 08 88          movea.l  $888.w, a0
  000246:  20 50                movea.l  (a0), a0
  000248:  2f 00                move.l   d0, -(a7)
  00024a:  20 10                move.l   (a0), d0
  00024c:  e1 88                lsl.l    #$8, d0
  00024e:  e0 88                lsr.l    #$8, d0
  000250:  20 40                movea.l  d0, a0
  000252:  20 1f                move.l   (a7)+, d0
  000254:  d0 fc 00 14          adda.w   #$14, a0
  000258:  2f 28 00 34          move.l   $34(a0), -(a7)
  00025c:  20 6f 00 04          movea.l  $4(a7), a0
  000260:  2e 9f                move.l   (a7)+, (a7)
  000262:  4e 75                rts
  000264:  60 00 24 34          bra.w    $269a  ; -> GA_PenMode
  000268:  00 00 10 78          dc.l     $00001078  ; dispatch #14
L26c:
  00026c:  2f 08                move.l   a0, -(a7)
  00026e:  20 78 08 88          movea.l  $888.w, a0
  000272:  20 50                movea.l  (a0), a0
  000274:  2f 00                move.l   d0, -(a7)
  000276:  20 10                move.l   (a0), d0
  000278:  e1 88                lsl.l    #$8, d0
  00027a:  e0 88                lsr.l    #$8, d0
  00027c:  20 40                movea.l  d0, a0
  00027e:  20 1f                move.l   (a7)+, d0
  000280:  d0 fc 00 14          adda.w   #$14, a0
  000284:  2f 28 00 38          move.l   $38(a0), -(a7)
  000288:  20 6f 00 04          movea.l  $4(a7), a0
  00028c:  2e 9f                move.l   (a7)+, (a7)
  00028e:  4e 75                rts
  000290:  60 00 25 70          bra.w    $2802  ; -> GA_PenNormal
  000294:  00 00 1a 8c          dc.l     $00001A8C  ; dispatch #15
L298:
  000298:  2f 08                move.l   a0, -(a7)
  00029a:  20 78 08 88          movea.l  $888.w, a0
  00029e:  20 50                movea.l  (a0), a0
  0002a0:  2f 00                move.l   d0, -(a7)
  0002a2:  20 10                move.l   (a0), d0
  0002a4:  e1 88                lsl.l    #$8, d0
  0002a6:  e0 88                lsr.l    #$8, d0
  0002a8:  20 40                movea.l  d0, a0
  0002aa:  20 1f                move.l   (a7)+, d0
  0002ac:  d0 fc 00 14          adda.w   #$14, a0
  0002b0:  2f 28 00 3c          move.l   $3c(a0), -(a7)
  0002b4:  20 6f 00 04          movea.l  $4(a7), a0
  0002b8:  2e 9f                move.l   (a7)+, (a7)
  0002ba:  4e 75                rts
  0002bc:  60 00 4c 56          bra.w    $4f14  ; -> GA_TrapAB23
  0002c0:  00 00 0f 88          dc.l     $00000F88  ; dispatch #16
L2c4:
  0002c4:  2f 08                move.l   a0, -(a7)
  0002c6:  20 78 08 88          movea.l  $888.w, a0
  0002ca:  20 50                movea.l  (a0), a0
  0002cc:  2f 00                move.l   d0, -(a7)
  0002ce:  20 10                move.l   (a0), d0
  0002d0:  e1 88                lsl.l    #$8, d0
  0002d2:  e0 88                lsr.l    #$8, d0
  0002d4:  20 40                movea.l  d0, a0
  0002d6:  20 1f                move.l   (a7)+, d0
  0002d8:  d0 fc 00 14          adda.w   #$14, a0
  0002dc:  2f 28 00 40          move.l   $40(a0), -(a7)
  0002e0:  20 6f 00 04          movea.l  $4(a7), a0
  0002e4:  2e 9f                move.l   (a7)+, (a7)
  0002e6:  4e 75                rts
  0002e8:  60 00 30 b2          bra.w    $339c  ; -> GA_ForeColor
  0002ec:  00 00 16 50          dc.l     $00001650  ; dispatch #17
L2f0:
  0002f0:  2f 08                move.l   a0, -(a7)
  0002f2:  20 78 08 88          movea.l  $888.w, a0
  0002f6:  20 50                movea.l  (a0), a0
  0002f8:  2f 00                move.l   d0, -(a7)
  0002fa:  20 10                move.l   (a0), d0
  0002fc:  e1 88                lsl.l    #$8, d0
  0002fe:  e0 88                lsr.l    #$8, d0
  000300:  20 40                movea.l  d0, a0
  000302:  20 1f                move.l   (a7)+, d0
  000304:  d0 fc 00 14          adda.w   #$14, a0
  000308:  2f 28 00 44          move.l   $44(a0), -(a7)
  00030c:  20 6f 00 04          movea.l  $4(a7), a0
  000310:  2e 9f                move.l   (a7)+, (a7)
  000312:  4e 75                rts
  000314:  60 00 30 e6          bra.w    $33fc  ; -> GA_RGBForeColor
  000318:  00 00 18 5c          dc.l     $0000185C  ; dispatch #18
L31c:
  00031c:  2f 08                move.l   a0, -(a7)
  00031e:  20 78 08 88          movea.l  $888.w, a0
  000322:  20 50                movea.l  (a0), a0
  000324:  2f 00                move.l   d0, -(a7)
  000326:  20 10                move.l   (a0), d0
  000328:  e1 88                lsl.l    #$8, d0
  00032a:  e0 88                lsr.l    #$8, d0
  00032c:  20 40                movea.l  d0, a0
  00032e:  20 1f                move.l   (a7)+, d0
  000330:  d0 fc 00 14          adda.w   #$14, a0
  000334:  2f 28 00 48          move.l   $48(a0), -(a7)
  000338:  20 6f 00 04          movea.l  $4(a7), a0
  00033c:  2e 9f                move.l   (a7)+, (a7)
  00033e:  4e 75                rts
  000340:  60 00 31 4c          bra.w    $348e  ; -> GA_PmForeColor
  000344:  00 00 18 60          dc.l     $00001860  ; dispatch #19
L348:
  000348:  2f 08                move.l   a0, -(a7)
  00034a:  20 78 08 88          movea.l  $888.w, a0
  00034e:  20 50                movea.l  (a0), a0
  000350:  2f 00                move.l   d0, -(a7)
  000352:  20 10                move.l   (a0), d0
  000354:  e1 88                lsl.l    #$8, d0
  000356:  e0 88                lsr.l    #$8, d0
  000358:  20 40                movea.l  d0, a0
  00035a:  20 1f                move.l   (a7)+, d0
  00035c:  d0 fc 00 14          adda.w   #$14, a0
  000360:  2f 28 00 4c          move.l   $4c(a0), -(a7)
  000364:  20 6f 00 04          movea.l  $4(a7), a0
  000368:  2e 9f                move.l   (a7)+, (a7)
  00036a:  4e 75                rts
  00036c:  60 00 32 b0          bra.w    $361e  ; -> GA_PmBackColor
  000370:  00 00 10 80          dc.l     $00001080  ; dispatch #20
L374:
  000374:  2f 08                move.l   a0, -(a7)
  000376:  20 78 08 88          movea.l  $888.w, a0
  00037a:  20 50                movea.l  (a0), a0
  00037c:  2f 00                move.l   d0, -(a7)
  00037e:  20 10                move.l   (a0), d0
  000380:  e1 88                lsl.l    #$8, d0
  000382:  e0 88                lsr.l    #$8, d0
  000384:  20 40                movea.l  d0, a0
  000386:  20 1f                move.l   (a7)+, d0
  000388:  d0 fc 00 14          adda.w   #$14, a0
  00038c:  2f 28 00 50          move.l   $50(a0), -(a7)
  000390:  20 6f 00 04          movea.l  $4(a7), a0
  000394:  2e 9f                move.l   (a7)+, (a7)
  000396:  4e 75                rts
  000398:  60 00 56 74          bra.w    $5a0e  ; -> GA_StdRect
  00039c:  00 00 10 d8          dc.l     $000010D8  ; dispatch #21
L3a0:
  0003a0:  2f 08                move.l   a0, -(a7)
  0003a2:  20 78 08 88          movea.l  $888.w, a0
  0003a6:  20 50                movea.l  (a0), a0
  0003a8:  2f 00                move.l   d0, -(a7)
  0003aa:  20 10                move.l   (a0), d0
  0003ac:  e1 88                lsl.l    #$8, d0
  0003ae:  e0 88                lsr.l    #$8, d0
  0003b0:  20 40                movea.l  d0, a0
  0003b2:  20 1f                move.l   (a7)+, d0
  0003b4:  d0 fc 00 14          adda.w   #$14, a0
  0003b8:  2f 28 00 54          move.l   $54(a0), -(a7)
  0003bc:  20 6f 00 04          movea.l  $4(a7), a0
  0003c0:  2e 9f                move.l   (a7)+, (a7)
  0003c2:  4e 75                rts
  0003c4:  60 00 55 68          bra.w    $592e  ; -> GA_StdOval
  0003c8:  00 00 10 bc          dc.l     $000010BC  ; dispatch #22
L3cc:
  0003cc:  2f 08                move.l   a0, -(a7)
  0003ce:  20 78 08 88          movea.l  $888.w, a0
  0003d2:  20 50                movea.l  (a0), a0
  0003d4:  2f 00                move.l   d0, -(a7)
  0003d6:  20 10                move.l   (a0), d0
  0003d8:  e1 88                lsl.l    #$8, d0
  0003da:  e0 88                lsr.l    #$8, d0
  0003dc:  20 40                movea.l  d0, a0
  0003de:  20 1f                move.l   (a7)+, d0
  0003e0:  d0 fc 00 14          adda.w   #$14, a0
  0003e4:  2f 28 00 58          move.l   $58(a0), -(a7)
  0003e8:  20 6f 00 04          movea.l  $4(a7), a0
  0003ec:  2e 9f                move.l   (a7)+, (a7)
  0003ee:  4e 75                rts
  0003f0:  60 00 54 28          bra.w    $581a  ; -> GA_StdRRect
  0003f4:  00 00 11 14          dc.l     $00001114  ; dispatch #23
L3f8:
  0003f8:  2f 08                move.l   a0, -(a7)
  0003fa:  20 78 08 88          movea.l  $888.w, a0
  0003fe:  20 50                movea.l  (a0), a0
  000400:  2f 00                move.l   d0, -(a7)
  000402:  20 10                move.l   (a0), d0
  000404:  e1 88                lsl.l    #$8, d0
  000406:  e0 88                lsr.l    #$8, d0
  000408:  20 40                movea.l  d0, a0
  00040a:  20 1f                move.l   (a7)+, d0
  00040c:  d0 fc 00 14          adda.w   #$14, a0
  000410:  2f 28 00 5c          move.l   $5c(a0), -(a7)
  000414:  20 6f 00 04          movea.l  $4(a7), a0
  000418:  2e 9f                move.l   (a7)+, (a7)
  00041a:  4e 75                rts
  00041c:  60 00 50 fa          bra.w    $5518  ; -> GA_StdPoly
  000420:  00 00 11 44          dc.l     $00001144  ; dispatch #24
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
  000438:  d0 fc 00 14          adda.w   #$14, a0
  00043c:  2f 28 00 60          move.l   $60(a0), -(a7)
  000440:  20 6f 00 04          movea.l  $4(a7), a0
  000444:  2e 9f                move.l   (a7)+, (a7)
  000446:  4e 75                rts
  000448:  60 00 4f 1a          bra.w    $5364  ; -> GA_StdRgn
  00044c:  00 00 16 e8          dc.l     $000016E8  ; dispatch #25
L450:
  000450:  2f 08                move.l   a0, -(a7)
  000452:  20 78 08 88          movea.l  $888.w, a0
  000456:  20 50                movea.l  (a0), a0
  000458:  2f 00                move.l   d0, -(a7)
  00045a:  20 10                move.l   (a0), d0
  00045c:  e1 88                lsl.l    #$8, d0
  00045e:  e0 88                lsr.l    #$8, d0
  000460:  20 40                movea.l  d0, a0
  000462:  20 1f                move.l   (a7)+, d0
  000464:  d0 fc 00 14          adda.w   #$14, a0
  000468:  2f 28 00 64          move.l   $64(a0), -(a7)
  00046c:  20 6f 00 04          movea.l  $4(a7), a0
  000470:  2e 9f                move.l   (a7)+, (a7)
  000472:  4e 75                rts
  000474:  60 00 18 da          bra.w    $1d50  ; -> GA_AddSearch
  000478:  00 00 17 30          dc.l     $00001730  ; dispatch #26
L47c:
  00047c:  2f 08                move.l   a0, -(a7)
  00047e:  20 78 08 88          movea.l  $888.w, a0
  000482:  20 50                movea.l  (a0), a0
  000484:  2f 00                move.l   d0, -(a7)
  000486:  20 10                move.l   (a0), d0
  000488:  e1 88                lsl.l    #$8, d0
  00048a:  e0 88                lsr.l    #$8, d0
  00048c:  20 40                movea.l  d0, a0
  00048e:  20 1f                move.l   (a7)+, d0
  000490:  d0 fc 00 14          adda.w   #$14, a0
  000494:  2f 28 00 68          move.l   $68(a0), -(a7)
  000498:  20 6f 00 04          movea.l  $4(a7), a0
  00049c:  2e 9f                move.l   (a7)+, (a7)
  00049e:  4e 75                rts
  0004a0:  60 00 19 7e          bra.w    $1e20  ; -> GA_DelSearch
  0004a4:  00 00 16 ec          dc.l     $000016EC  ; dispatch #27
L4a8:
  0004a8:  2f 08                move.l   a0, -(a7)
  0004aa:  20 78 08 88          movea.l  $888.w, a0
  0004ae:  20 50                movea.l  (a0), a0
  0004b0:  2f 00                move.l   d0, -(a7)
  0004b2:  20 10                move.l   (a0), d0
  0004b4:  e1 88                lsl.l    #$8, d0
  0004b6:  e0 88                lsr.l    #$8, d0
  0004b8:  20 40                movea.l  d0, a0
  0004ba:  20 1f                move.l   (a7)+, d0
  0004bc:  d0 fc 00 14          adda.w   #$14, a0
  0004c0:  2f 28 00 6c          move.l   $6c(a0), -(a7)
  0004c4:  20 6f 00 04          movea.l  $4(a7), a0
  0004c8:  2e 9f                move.l   (a7)+, (a7)
  0004ca:  4e 75                rts
  0004cc:  60 00 19 a2          bra.w    $1e70  ; -> GA_AddComp
  0004d0:  00 00 17 34          dc.l     $00001734  ; dispatch #28
L4d4:
  0004d4:  2f 08                move.l   a0, -(a7)
  0004d6:  20 78 08 88          movea.l  $888.w, a0
  0004da:  20 50                movea.l  (a0), a0
  0004dc:  2f 00                move.l   d0, -(a7)
  0004de:  20 10                move.l   (a0), d0
  0004e0:  e1 88                lsl.l    #$8, d0
  0004e2:  e0 88                lsr.l    #$8, d0
  0004e4:  20 40                movea.l  d0, a0
  0004e6:  20 1f                move.l   (a7)+, d0
  0004e8:  d0 fc 00 14          adda.w   #$14, a0
  0004ec:  2f 28 00 70          move.l   $70(a0), -(a7)
  0004f0:  20 6f 00 04          movea.l  $4(a7), a0
  0004f4:  2e 9f                move.l   (a7)+, (a7)
  0004f6:  4e 75                rts
  0004f8:  60 00 19 c6          bra.w    $1ec0  ; -> GA_DelComp
  0004fc:  00 00 16 20          dc.l     $00001620  ; dispatch #29
L500:
  000500:  2f 08                move.l   a0, -(a7)
  000502:  20 78 08 88          movea.l  $888.w, a0
  000506:  20 50                movea.l  (a0), a0
  000508:  2f 00                move.l   d0, -(a7)
  00050a:  20 10                move.l   (a0), d0
  00050c:  e1 88                lsl.l    #$8, d0
  00050e:  e0 88                lsr.l    #$8, d0
  000510:  20 40                movea.l  d0, a0
  000512:  20 1f                move.l   (a7)+, d0
  000514:  d0 fc 00 14          adda.w   #$14, a0
  000518:  2f 28 00 74          move.l   $74(a0), -(a7)
  00051c:  20 6f 00 04          movea.l  $4(a7), a0
  000520:  2e 9f                move.l   (a7)+, (a7)
  000522:  4e 75                rts
  000524:  60 00 19 ea          bra.w    $1f10  ; -> GA_DisposPixPat
  000528:  00 00 16 24          dc.l     $00001624  ; dispatch #30
L52c:
  00052c:  2f 08                move.l   a0, -(a7)
  00052e:  20 78 08 88          movea.l  $888.w, a0
  000532:  20 50                movea.l  (a0), a0
  000534:  2f 00                move.l   d0, -(a7)
  000536:  20 10                move.l   (a0), d0
  000538:  e1 88                lsl.l    #$8, d0
  00053a:  e0 88                lsr.l    #$8, d0
  00053c:  20 40                movea.l  d0, a0
  00053e:  20 1f                move.l   (a7)+, d0
  000540:  d0 fc 00 14          adda.w   #$14, a0
  000544:  2f 28 00 78          move.l   $78(a0), -(a7)
  000548:  20 6f 00 04          movea.l  $4(a7), a0
  00054c:  2e 9f                move.l   (a7)+, (a7)
  00054e:  4e 75                rts
  000550:  60 00 19 ee          bra.w    $1f40  ; -> GA_CopyPixPat
  000554:  00 00 16 34          dc.l     $00001634  ; dispatch #31
L558:
  000558:  2f 08                move.l   a0, -(a7)
  00055a:  20 78 08 88          movea.l  $888.w, a0
  00055e:  20 50                movea.l  (a0), a0
  000560:  2f 00                move.l   d0, -(a7)
  000562:  20 10                move.l   (a0), d0
  000564:  e1 88                lsl.l    #$8, d0
  000566:  e0 88                lsr.l    #$8, d0
  000568:  20 40                movea.l  d0, a0
  00056a:  20 1f                move.l   (a7)+, d0
  00056c:  d0 fc 00 14          adda.w   #$14, a0
  000570:  2f 28 00 7c          move.l   $7c(a0), -(a7)
  000574:  20 6f 00 04          movea.l  $4(a7), a0
  000578:  2e 9f                move.l   (a7)+, (a7)
  00057a:  4e 75                rts
  00057c:  60 00 1a 54          bra.w    $1fd2  ; -> GA_MakeRGBPat
  000580:  00 00 1a 44          dc.l     $00001A44  ; dispatch #32
L584:
  000584:  2f 08                move.l   a0, -(a7)
  000586:  20 78 08 88          movea.l  $888.w, a0
  00058a:  20 50                movea.l  (a0), a0
  00058c:  2f 00                move.l   d0, -(a7)
  00058e:  20 10                move.l   (a0), d0
  000590:  e1 88                lsl.l    #$8, d0
  000592:  e0 88                lsr.l    #$8, d0
  000594:  20 40                movea.l  d0, a0
  000596:  20 1f                move.l   (a7)+, d0
  000598:  d0 fc 00 14          adda.w   #$14, a0
  00059c:  2f 28 00 80          move.l   $80(a0), -(a7)
  0005a0:  20 6f 00 04          movea.l  $4(a7), a0
  0005a4:  2e 9f                move.l   (a7)+, (a7)
  0005a6:  4e 75                rts
  0005a8:  60 00 1a b2          bra.w    $205c  ; -> GA_TrapAB11
  0005ac:  00 00 0f d4          dc.l     $00000FD4  ; dispatch #33
L5b0:
  0005b0:  2f 08                move.l   a0, -(a7)
  0005b2:  20 78 08 88          movea.l  $888.w, a0
  0005b6:  20 50                movea.l  (a0), a0
  0005b8:  2f 00                move.l   d0, -(a7)
  0005ba:  20 10                move.l   (a0), d0
  0005bc:  e1 88                lsl.l    #$8, d0
  0005be:  e0 88                lsr.l    #$8, d0
  0005c0:  20 40                movea.l  d0, a0
  0005c2:  20 1f                move.l   (a7)+, d0
  0005c4:  d0 fc 00 14          adda.w   #$14, a0
  0005c8:  2f 28 00 84          move.l   $84(a0), -(a7)
  0005cc:  20 6f 00 04          movea.l  $4(a7), a0
  0005d0:  2e 9f                move.l   (a7)+, (a7)
  0005d2:  4e 75                rts
  0005d4:  60 00 1c 68          bra.w    $223e  ; -> GA_SetPBits
  0005d8:  00 00 0f d8          dc.l     $00000FD8  ; dispatch #34
L5dc:
  0005dc:  2f 08                move.l   a0, -(a7)
  0005de:  20 78 08 88          movea.l  $888.w, a0
  0005e2:  20 50                movea.l  (a0), a0
  0005e4:  2f 00                move.l   d0, -(a7)
  0005e6:  20 10                move.l   (a0), d0
  0005e8:  e1 88                lsl.l    #$8, d0
  0005ea:  e0 88                lsr.l    #$8, d0
  0005ec:  20 40                movea.l  d0, a0
  0005ee:  20 1f                move.l   (a7)+, d0
  0005f0:  d0 fc 00 14          adda.w   #$14, a0
  0005f4:  2f 28 00 88          move.l   $88(a0), -(a7)
  0005f8:  20 6f 00 04          movea.l  $4(a7), a0
  0005fc:  2e 9f                move.l   (a7)+, (a7)
  0005fe:  4e 75                rts
  000600:  60 00 1c d8          bra.w    $22da  ; -> GA_PortSize
  000604:  00 00 0f dc          dc.l     $00000FDC  ; dispatch #35
L608:
  000608:  2f 08                move.l   a0, -(a7)
  00060a:  20 78 08 88          movea.l  $888.w, a0
  00060e:  20 50                movea.l  (a0), a0
  000610:  2f 00                move.l   d0, -(a7)
  000612:  20 10                move.l   (a0), d0
  000614:  e1 88                lsl.l    #$8, d0
  000616:  e0 88                lsr.l    #$8, d0
  000618:  20 40                movea.l  d0, a0
  00061a:  20 1f                move.l   (a7)+, d0
  00061c:  d0 fc 00 14          adda.w   #$14, a0
  000620:  2f 28 00 8c          move.l   $8c(a0), -(a7)
  000624:  20 6f 00 04          movea.l  $4(a7), a0
  000628:  2e 9f                move.l   (a7)+, (a7)
  00062a:  4e 75                rts
  00062c:  60 00 1d 2c          bra.w    $235a  ; -> GA_MovePortTo
  000630:  00 00 0f e0          dc.l     $00000FE0  ; dispatch #36
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
  000648:  d0 fc 00 14          adda.w   #$14, a0
  00064c:  2f 28 00 90          move.l   $90(a0), -(a7)
  000650:  20 6f 00 04          movea.l  $4(a7), a0
  000654:  2e 9f                move.l   (a7)+, (a7)
  000656:  4e 75                rts
  000658:  60 00 1d 52          bra.w    $23ac  ; -> GA_SetOrigin
  00065c:  00 00 0f e4          dc.l     $00000FE4  ; dispatch #37
L660:
  000660:  2f 08                move.l   a0, -(a7)
  000662:  20 78 08 88          movea.l  $888.w, a0
  000666:  20 50                movea.l  (a0), a0
  000668:  2f 00                move.l   d0, -(a7)
  00066a:  20 10                move.l   (a0), d0
  00066c:  e1 88                lsl.l    #$8, d0
  00066e:  e0 88                lsr.l    #$8, d0
  000670:  20 40                movea.l  d0, a0
  000672:  20 1f                move.l   (a7)+, d0
  000674:  d0 fc 00 14          adda.w   #$14, a0
  000678:  2f 28 00 94          move.l   $94(a0), -(a7)
  00067c:  20 6f 00 04          movea.l  $4(a7), a0
  000680:  2e 9f                move.l   (a7)+, (a7)
  000682:  4e 75                rts
  000684:  60 00 1d 94          bra.w    $241a  ; -> GA_SetClip
  000688:  00 00 0f ec          dc.l     $00000FEC  ; dispatch #38
L68c:
  00068c:  2f 08                move.l   a0, -(a7)
  00068e:  20 78 08 88          movea.l  $888.w, a0
  000692:  20 50                movea.l  (a0), a0
  000694:  2f 00                move.l   d0, -(a7)
  000696:  20 10                move.l   (a0), d0
  000698:  e1 88                lsl.l    #$8, d0
  00069a:  e0 88                lsr.l    #$8, d0
  00069c:  20 40                movea.l  d0, a0
  00069e:  20 1f                move.l   (a7)+, d0
  0006a0:  d0 fc 00 14          adda.w   #$14, a0
  0006a4:  2f 28 00 98          move.l   $98(a0), -(a7)
  0006a8:  20 6f 00 04          movea.l  $4(a7), a0
  0006ac:  2e 9f                move.l   (a7)+, (a7)
  0006ae:  4e 75                rts
  0006b0:  60 00 1d d8          bra.w    $248a  ; -> GA_ClipRect
  0006b4:  00 00 10 58          dc.l     $00001058  ; dispatch #39
L6b8:
  0006b8:  2f 08                move.l   a0, -(a7)
  0006ba:  20 78 08 88          movea.l  $888.w, a0
  0006be:  20 50                movea.l  (a0), a0
  0006c0:  2f 00                move.l   d0, -(a7)
  0006c2:  20 10                move.l   (a0), d0
  0006c4:  e1 88                lsl.l    #$8, d0
  0006c6:  e0 88                lsr.l    #$8, d0
  0006c8:  20 40                movea.l  d0, a0
  0006ca:  20 1f                move.l   (a7)+, d0
  0006cc:  d0 fc 00 14          adda.w   #$14, a0
  0006d0:  2f 28 00 9c          move.l   $9c(a0), -(a7)
  0006d4:  20 6f 00 04          movea.l  $4(a7), a0
  0006d8:  2e 9f                move.l   (a7)+, (a7)
  0006da:  4e 75                rts
  0006dc:  60 00 1e 4c          bra.w    $252a  ; -> GA_HidePen
  0006e0:  00 00 10 5c          dc.l     $0000105C  ; dispatch #40
L6e4:
  0006e4:  2f 08                move.l   a0, -(a7)
  0006e6:  20 78 08 88          movea.l  $888.w, a0
  0006ea:  20 50                movea.l  (a0), a0
  0006ec:  2f 00                move.l   d0, -(a7)
  0006ee:  20 10                move.l   (a0), d0
  0006f0:  e1 88                lsl.l    #$8, d0
  0006f2:  e0 88                lsr.l    #$8, d0
  0006f4:  20 40                movea.l  d0, a0
  0006f6:  20 1f                move.l   (a7)+, d0
  0006f8:  d0 fc 00 14          adda.w   #$14, a0
  0006fc:  2f 28 00 a0          move.l   $a0(a0), -(a7)
  000700:  20 6f 00 04          movea.l  $4(a7), a0
  000704:  2e 9f                move.l   (a7)+, (a7)
  000706:  4e 75                rts
  000708:  60 00 1e 32          bra.w    $253c  ; -> GA_ShowPen
  00070c:  00 00 0f 8c          dc.l     $00000F8C  ; dispatch #41
L710:
  000710:  2f 08                move.l   a0, -(a7)
  000712:  20 78 08 88          movea.l  $888.w, a0
  000716:  20 50                movea.l  (a0), a0
  000718:  2f 00                move.l   d0, -(a7)
  00071a:  20 10                move.l   (a0), d0
  00071c:  e1 88                lsl.l    #$8, d0
  00071e:  e0 88                lsr.l    #$8, d0
  000720:  20 40                movea.l  d0, a0
  000722:  20 1f                move.l   (a7)+, d0
  000724:  d0 fc 00 14          adda.w   #$14, a0
  000728:  2f 28 00 a4          move.l   $a4(a0), -(a7)
  00072c:  20 6f 00 04          movea.l  $4(a7), a0
  000730:  2e 9f                move.l   (a7)+, (a7)
  000732:  4e 75                rts
  000734:  60 00 2d f6          bra.w    $352c  ; -> GA_BackColor
  000738:  00 00 0f 90          dc.l     $00000F90  ; dispatch #42
L73c:
  00073c:  2f 08                move.l   a0, -(a7)
  00073e:  20 78 08 88          movea.l  $888.w, a0
  000742:  20 50                movea.l  (a0), a0
  000744:  2f 00                move.l   d0, -(a7)
  000746:  20 10                move.l   (a0), d0
  000748:  e1 88                lsl.l    #$8, d0
  00074a:  e0 88                lsr.l    #$8, d0
  00074c:  20 40                movea.l  d0, a0
  00074e:  20 1f                move.l   (a7)+, d0
  000750:  d0 fc 00 14          adda.w   #$14, a0
  000754:  2f 28 00 a8          move.l   $a8(a0), -(a7)
  000758:  20 6f 00 04          movea.l  $4(a7), a0
  00075c:  2e 9f                move.l   (a7)+, (a7)
  00075e:  4e 75                rts
  000760:  60 00 21 6c          bra.w    $28ce  ; -> GA_ColorBit
  000764:  00 00 11 68          dc.l     $00001168  ; dispatch #43
L768:
  000768:  2f 08                move.l   a0, -(a7)
  00076a:  20 78 08 88          movea.l  $888.w, a0
  00076e:  20 50                movea.l  (a0), a0
  000770:  2f 00                move.l   d0, -(a7)
  000772:  20 10                move.l   (a0), d0
  000774:  e1 88                lsl.l    #$8, d0
  000776:  e0 88                lsr.l    #$8, d0
  000778:  20 40                movea.l  d0, a0
  00077a:  20 1f                move.l   (a7)+, d0
  00077c:  d0 fc 00 14          adda.w   #$14, a0
  000780:  2f 28 00 ac          move.l   $ac(a0), -(a7)
  000784:  20 6f 00 04          movea.l  $4(a7), a0
  000788:  2e 9f                move.l   (a7)+, (a7)
  00078a:  4e 75                rts
  00078c:  60 00 21 9c          bra.w    $292a  ; -> GA_OpenRgn
  000790:  00 00 11 cc          dc.l     $000011CC  ; dispatch #44
L794:
  000794:  2f 08                move.l   a0, -(a7)
  000796:  20 78 08 88          movea.l  $888.w, a0
  00079a:  20 50                movea.l  (a0), a0
  00079c:  2f 00                move.l   d0, -(a7)
  00079e:  20 10                move.l   (a0), d0
  0007a0:  e1 88                lsl.l    #$8, d0
  0007a2:  e0 88                lsr.l    #$8, d0
  0007a4:  20 40                movea.l  d0, a0
  0007a6:  20 1f                move.l   (a7)+, d0
  0007a8:  d0 fc 00 14          adda.w   #$14, a0
  0007ac:  2f 28 00 b0          move.l   $b0(a0), -(a7)
  0007b0:  20 6f 00 04          movea.l  $4(a7), a0
  0007b4:  2e 9f                move.l   (a7)+, (a7)
  0007b6:  4e 75                rts
  0007b8:  60 00 21 82          bra.w    $293c  ; -> GA_OpenPicture
  0007bc:  00 00 11 2c          dc.l     $0000112C  ; dispatch #45
L7c0:
  0007c0:  2f 08                move.l   a0, -(a7)
  0007c2:  20 78 08 88          movea.l  $888.w, a0
  0007c6:  20 50                movea.l  (a0), a0
  0007c8:  2f 00                move.l   d0, -(a7)
  0007ca:  20 10                move.l   (a0), d0
  0007cc:  e1 88                lsl.l    #$8, d0
  0007ce:  e0 88                lsr.l    #$8, d0
  0007d0:  20 40                movea.l  d0, a0
  0007d2:  20 1f                move.l   (a7)+, d0
  0007d4:  d0 fc 00 14          adda.w   #$14, a0
  0007d8:  2f 28 00 b4          move.l   $b4(a0), -(a7)
  0007dc:  20 6f 00 04          movea.l  $4(a7), a0
  0007e0:  2e 9f                move.l   (a7)+, (a7)
  0007e2:  4e 75                rts
  0007e4:  60 00 21 82          bra.w    $2968  ; -> GA_OpenPoly
  0007e8:  00 00 11 70          dc.l     $00001170  ; dispatch #46
L7ec:
  0007ec:  2f 08                move.l   a0, -(a7)
  0007ee:  20 78 08 88          movea.l  $888.w, a0
  0007f2:  20 50                movea.l  (a0), a0
  0007f4:  2f 00                move.l   d0, -(a7)
  0007f6:  20 10                move.l   (a0), d0
  0007f8:  e1 88                lsl.l    #$8, d0
  0007fa:  e0 88                lsr.l    #$8, d0
  0007fc:  20 40                movea.l  d0, a0
  0007fe:  20 1f                move.l   (a7)+, d0
  000800:  d0 fc 00 14          adda.w   #$14, a0
  000804:  2f 28 00 b8          move.l   $b8(a0), -(a7)
  000808:  20 6f 00 04          movea.l  $4(a7), a0
  00080c:  2e 9f                move.l   (a7)+, (a7)
  00080e:  4e 75                rts
  000810:  60 00 22 58          bra.w    $2a6a  ; -> GA_CopyRgn
  000814:  00 00 11 78          dc.l     $00001178  ; dispatch #47
L818:
  000818:  2f 08                move.l   a0, -(a7)
  00081a:  20 78 08 88          movea.l  $888.w, a0
  00081e:  20 50                movea.l  (a0), a0
  000820:  2f 00                move.l   d0, -(a7)
  000822:  20 10                move.l   (a0), d0
  000824:  e1 88                lsl.l    #$8, d0
  000826:  e0 88                lsr.l    #$8, d0
  000828:  20 40                movea.l  d0, a0
  00082a:  20 1f                move.l   (a7)+, d0
  00082c:  d0 fc 00 14          adda.w   #$14, a0
  000830:  2f 28 00 bc          move.l   $bc(a0), -(a7)
  000834:  20 6f 00 04          movea.l  $4(a7), a0
  000838:  2e 9f                move.l   (a7)+, (a7)
  00083a:  4e 75                rts
  00083c:  60 00 23 5e          bra.w    $2b9c  ; -> GA_SetRecRgn
  000840:  00 00 11 7c          dc.l     $0000117C  ; dispatch #48
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
  000858:  d0 fc 00 14          adda.w   #$14, a0
  00085c:  2f 28 00 c0          move.l   $c0(a0), -(a7)
  000860:  20 6f 00 04          movea.l  $4(a7), a0
  000864:  2e 9f                move.l   (a7)+, (a7)
  000866:  4e 75                rts
  000868:  60 00 24 10          bra.w    $2c7a  ; -> GA_RectRgn
  00086c:  00 00 11 80          dc.l     $00001180  ; dispatch #49
L870:
  000870:  2f 08                move.l   a0, -(a7)
  000872:  20 78 08 88          movea.l  $888.w, a0
  000876:  20 50                movea.l  (a0), a0
  000878:  2f 00                move.l   d0, -(a7)
  00087a:  20 10                move.l   (a0), d0
  00087c:  e1 88                lsl.l    #$8, d0
  00087e:  e0 88                lsr.l    #$8, d0
  000880:  20 40                movea.l  d0, a0
  000882:  20 1f                move.l   (a7)+, d0
  000884:  d0 fc 00 14          adda.w   #$14, a0
  000888:  2f 28 00 c4          move.l   $c4(a0), -(a7)
  00088c:  20 6f 00 04          movea.l  $4(a7), a0
  000890:  2e 9f                move.l   (a7)+, (a7)
  000892:  4e 75                rts
  000894:  60 00 24 9c          bra.w    $2d32  ; -> GA_OffsetRgn
  000898:  00 00 11 84          dc.l     $00001184  ; dispatch #50
L89c:
  00089c:  2f 08                move.l   a0, -(a7)
  00089e:  20 78 08 88          movea.l  $888.w, a0
  0008a2:  20 50                movea.l  (a0), a0
  0008a4:  2f 00                move.l   d0, -(a7)
  0008a6:  20 10                move.l   (a0), d0
  0008a8:  e1 88                lsl.l    #$8, d0
  0008aa:  e0 88                lsr.l    #$8, d0
  0008ac:  20 40                movea.l  d0, a0
  0008ae:  20 1f                move.l   (a7)+, d0
  0008b0:  d0 fc 00 14          adda.w   #$14, a0
  0008b4:  2f 28 00 c8          move.l   $c8(a0), -(a7)
  0008b8:  20 6f 00 04          movea.l  $4(a7), a0
  0008bc:  2e 9f                move.l   (a7)+, (a7)
  0008be:  4e 75                rts
  0008c0:  60 00 25 5e          bra.w    $2e20  ; -> GA_InsetRgn
  0008c4:  00 00 11 90          dc.l     $00001190  ; dispatch #51
L8c8:
  0008c8:  2f 08                move.l   a0, -(a7)
  0008ca:  20 78 08 88          movea.l  $888.w, a0
  0008ce:  20 50                movea.l  (a0), a0
  0008d0:  2f 00                move.l   d0, -(a7)
  0008d2:  20 10                move.l   (a0), d0
  0008d4:  e1 88                lsl.l    #$8, d0
  0008d6:  e0 88                lsr.l    #$8, d0
  0008d8:  20 40                movea.l  d0, a0
  0008da:  20 1f                move.l   (a7)+, d0
  0008dc:  d0 fc 00 14          adda.w   #$14, a0
  0008e0:  2f 28 00 cc          move.l   $cc(a0), -(a7)
  0008e4:  20 6f 00 04          movea.l  $4(a7), a0
  0008e8:  2e 9f                move.l   (a7)+, (a7)
  0008ea:  4e 75                rts
  0008ec:  60 00 26 20          bra.w    $2f0e  ; -> GA_SectRgn
  0008f0:  00 00 11 94          dc.l     $00001194  ; dispatch #52
L8f4:
  0008f4:  2f 08                move.l   a0, -(a7)
  0008f6:  20 78 08 88          movea.l  $888.w, a0
  0008fa:  20 50                movea.l  (a0), a0
  0008fc:  2f 00                move.l   d0, -(a7)
  0008fe:  20 10                move.l   (a0), d0
  000900:  e1 88                lsl.l    #$8, d0
  000902:  e0 88                lsr.l    #$8, d0
  000904:  20 40                movea.l  d0, a0
  000906:  20 1f                move.l   (a7)+, d0
  000908:  d0 fc 00 14          adda.w   #$14, a0
  00090c:  2f 28 00 d0          move.l   $d0(a0), -(a7)
  000910:  20 6f 00 04          movea.l  $4(a7), a0
  000914:  2e 9f                move.l   (a7)+, (a7)
  000916:  4e 75                rts
  000918:  60 00 26 d6          bra.w    $2ff0  ; -> GA_UnionRgn
  00091c:  00 00 11 98          dc.l     $00001198  ; dispatch #53
L920:
  000920:  2f 08                move.l   a0, -(a7)
  000922:  20 78 08 88          movea.l  $888.w, a0
  000926:  20 50                movea.l  (a0), a0
  000928:  2f 00                move.l   d0, -(a7)
  00092a:  20 10                move.l   (a0), d0
  00092c:  e1 88                lsl.l    #$8, d0
  00092e:  e0 88                lsr.l    #$8, d0
  000930:  20 40                movea.l  d0, a0
  000932:  20 1f                move.l   (a7)+, d0
  000934:  d0 fc 00 14          adda.w   #$14, a0
  000938:  2f 28 00 d4          move.l   $d4(a0), -(a7)
  00093c:  20 6f 00 04          movea.l  $4(a7), a0
  000940:  2e 9f                move.l   (a7)+, (a7)
  000942:  4e 75                rts
  000944:  60 00 27 8c          bra.w    $30d2  ; -> GA_DiffRgn
  000948:  00 00 11 9c          dc.l     $0000119C  ; dispatch #54
L94c:
  00094c:  2f 08                move.l   a0, -(a7)
  00094e:  20 78 08 88          movea.l  $888.w, a0
  000952:  20 50                movea.l  (a0), a0
  000954:  2f 00                move.l   d0, -(a7)
  000956:  20 10                move.l   (a0), d0
  000958:  e1 88                lsl.l    #$8, d0
  00095a:  e0 88                lsr.l    #$8, d0
  00095c:  20 40                movea.l  d0, a0
  00095e:  20 1f                move.l   (a7)+, d0
  000960:  d0 fc 00 14          adda.w   #$14, a0
  000964:  2f 28 00 d8          move.l   $d8(a0), -(a7)
  000968:  20 6f 00 04          movea.l  $4(a7), a0
  00096c:  2e 9f                move.l   (a7)+, (a7)
  00096e:  4e 75                rts
  000970:  60 00 28 42          bra.w    $31b4  ; -> GA_XOrRgn
  000974:  00 00 11 ec          dc.l     $000011EC  ; dispatch #55
L978:
  000978:  2f 08                move.l   a0, -(a7)
  00097a:  20 78 08 88          movea.l  $888.w, a0
  00097e:  20 50                movea.l  (a0), a0
  000980:  2f 00                move.l   d0, -(a7)
  000982:  20 10                move.l   (a0), d0
  000984:  e1 88                lsl.l    #$8, d0
  000986:  e0 88                lsr.l    #$8, d0
  000988:  20 40                movea.l  d0, a0
  00098a:  20 1f                move.l   (a7)+, d0
  00098c:  d0 fc 00 14          adda.w   #$14, a0
  000990:  2f 28 00 dc          move.l   $dc(a0), -(a7)
  000994:  20 6f 00 04          movea.l  $4(a7), a0
  000998:  2e 9f                move.l   (a7)+, (a7)
  00099a:  4e 75                rts
  00099c:  60 00 28 f8          bra.w    $3296  ; -> GA_MapRgn
  0009a0:  00 00 16 54          dc.l     $00001654  ; dispatch #56
L9a4:
  0009a4:  2f 08                move.l   a0, -(a7)
  0009a6:  20 78 08 88          movea.l  $888.w, a0
  0009aa:  20 50                movea.l  (a0), a0
  0009ac:  2f 00                move.l   d0, -(a7)
  0009ae:  20 10                move.l   (a0), d0
  0009b0:  e1 88                lsl.l    #$8, d0
  0009b2:  e0 88                lsr.l    #$8, d0
  0009b4:  20 40                movea.l  d0, a0
  0009b6:  20 1f                move.l   (a7)+, d0
  0009b8:  d0 fc 00 14          adda.w   #$14, a0
  0009bc:  2f 28 00 e0          move.l   $e0(a0), -(a7)
  0009c0:  20 6f 00 04          movea.l  $4(a7), a0
  0009c4:  2e 9f                move.l   (a7)+, (a7)
  0009c6:  4e 75                rts
  0009c8:  60 00 2b c2          bra.w    $358c  ; -> GA_RGBBackColor
  0009cc:  00 00 16 14          dc.l     $00001614  ; dispatch #57
L9d0:
  0009d0:  2f 08                move.l   a0, -(a7)
  0009d2:  20 78 08 88          movea.l  $888.w, a0
  0009d6:  20 50                movea.l  (a0), a0
  0009d8:  2f 00                move.l   d0, -(a7)
  0009da:  20 10                move.l   (a0), d0
  0009dc:  e1 88                lsl.l    #$8, d0
  0009de:  e0 88                lsr.l    #$8, d0
  0009e0:  20 40                movea.l  d0, a0
  0009e2:  20 1f                move.l   (a7)+, d0
  0009e4:  d0 fc 00 14          adda.w   #$14, a0
  0009e8:  2f 28 00 e4          move.l   $e4(a0), -(a7)
  0009ec:  20 6f 00 04          movea.l  $4(a7), a0
  0009f0:  2e 9f                move.l   (a7)+, (a7)
  0009f2:  4e 75                rts
  0009f4:  60 00 30 b2          bra.w    $3aa8  ; -> GA_CopyPixMap
  0009f8:  00 00 16 28          dc.l     $00001628  ; dispatch #58
L9fc:
  0009fc:  2f 08                move.l   a0, -(a7)
  0009fe:  20 78 08 88          movea.l  $888.w, a0
  000a02:  20 50                movea.l  (a0), a0
  000a04:  2f 00                move.l   d0, -(a7)
  000a06:  20 10                move.l   (a0), d0
  000a08:  e1 88                lsl.l    #$8, d0
  000a0a:  e0 88                lsr.l    #$8, d0
  000a0c:  20 40                movea.l  d0, a0
  000a0e:  20 1f                move.l   (a7)+, d0
  000a10:  d0 fc 00 14          adda.w   #$14, a0
  000a14:  2f 28 00 e8          move.l   $e8(a0), -(a7)
  000a18:  20 6f 00 04          movea.l  $4(a7), a0
  000a1c:  2e 9f                move.l   (a7)+, (a7)
  000a1e:  4e 75                rts
  000a20:  60 00 30 e8          bra.w    $3b0a  ; -> GA_PenPixPat
  000a24:  00 00 16 2c          dc.l     $0000162C  ; dispatch #59
La28:
  000a28:  2f 08                move.l   a0, -(a7)
  000a2a:  20 78 08 88          movea.l  $888.w, a0
  000a2e:  20 50                movea.l  (a0), a0
  000a30:  2f 00                move.l   d0, -(a7)
  000a32:  20 10                move.l   (a0), d0
  000a34:  e1 88                lsl.l    #$8, d0
  000a36:  e0 88                lsr.l    #$8, d0
  000a38:  20 40                movea.l  d0, a0
  000a3a:  20 1f                move.l   (a7)+, d0
  000a3c:  d0 fc 00 14          adda.w   #$14, a0
  000a40:  2f 28 00 ec          move.l   $ec(a0), -(a7)
  000a44:  20 6f 00 04          movea.l  $4(a7), a0
  000a48:  2e 9f                move.l   (a7)+, (a7)
  000a4a:  4e 75                rts
  000a4c:  60 00 31 a4          bra.w    $3bf2  ; -> GA_BackPixPat
  000a50:  00 00 16 18          dc.l     $00001618  ; dispatch #60
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
  000a68:  d0 fc 00 14          adda.w   #$14, a0
  000a6c:  2f 28 00 f0          move.l   $f0(a0), -(a7)
  000a70:  20 6f 00 04          movea.l  $4(a7), a0
  000a74:  2e 9f                move.l   (a7)+, (a7)
  000a76:  4e 75                rts
  000a78:  60 00 32 60          bra.w    $3cda  ; -> GA_SetPortPix
  000a7c:  00 00 16 84          dc.l     $00001684  ; dispatch #61
La80:
  000a80:  2f 08                move.l   a0, -(a7)
  000a82:  20 78 08 88          movea.l  $888.w, a0
  000a86:  20 50                movea.l  (a0), a0
  000a88:  2f 00                move.l   d0, -(a7)
  000a8a:  20 10                move.l   (a0), d0
  000a8c:  e1 88                lsl.l    #$8, d0
  000a8e:  e0 88                lsr.l    #$8, d0
  000a90:  20 40                movea.l  d0, a0
  000a92:  20 1f                move.l   (a7)+, d0
  000a94:  d0 fc 00 14          adda.w   #$14, a0
  000a98:  2f 28 00 f4          move.l   $f4(a0), -(a7)
  000a9c:  20 6f 00 04          movea.l  $4(a7), a0
  000aa0:  2e 9f                move.l   (a7)+, (a7)
  000aa2:  4e 75                rts
  000aa4:  60 00 32 8a          bra.w    $3d30  ; -> GA_OpColor
  000aa8:  00 00 16 88          dc.l     $00001688  ; dispatch #62
Laac:
  000aac:  2f 08                move.l   a0, -(a7)
  000aae:  20 78 08 88          movea.l  $888.w, a0
  000ab2:  20 50                movea.l  (a0), a0
  000ab4:  2f 00                move.l   d0, -(a7)
  000ab6:  20 10                move.l   (a0), d0
  000ab8:  e1 88                lsl.l    #$8, d0
  000aba:  e0 88                lsr.l    #$8, d0
  000abc:  20 40                movea.l  d0, a0
  000abe:  20 1f                move.l   (a7)+, d0
  000ac0:  d0 fc 00 14          adda.w   #$14, a0
  000ac4:  2f 28 00 f8          move.l   $f8(a0), -(a7)
  000ac8:  20 6f 00 04          movea.l  $4(a7), a0
  000acc:  2e 9f                move.l   (a7)+, (a7)
  000ace:  4e 75                rts
  000ad0:  60 00 32 e2          bra.w    $3db4  ; -> GA_HiliteColor
  000ad4:  00 00 11 74          dc.l     $00001174  ; dispatch #63
Lad8:
  000ad8:  2f 08                move.l   a0, -(a7)
  000ada:  20 78 08 88          movea.l  $888.w, a0
  000ade:  20 50                movea.l  (a0), a0
  000ae0:  2f 00                move.l   d0, -(a7)
  000ae2:  20 10                move.l   (a0), d0
  000ae4:  e1 88                lsl.l    #$8, d0
  000ae6:  e0 88                lsr.l    #$8, d0
  000ae8:  20 40                movea.l  d0, a0
  000aea:  20 1f                move.l   (a7)+, d0
  000aec:  d0 fc 00 14          adda.w   #$14, a0
  000af0:  2f 28 00 fc          move.l   $fc(a0), -(a7)
  000af4:  20 6f 00 04          movea.l  $4(a7), a0
  000af8:  2e 9f                move.l   (a7)+, (a7)
  000afa:  4e 75                rts
  000afc:  60 00 1f fc          bra.w    $2afa  ; -> GA_SetEmptyRgn
  000b00:  00 00 10 74          dc.l     $00001074  ; dispatch #64
Lb04:
  000b04:  2f 08                move.l   a0, -(a7)
  000b06:  20 78 08 88          movea.l  $888.w, a0
  000b0a:  20 50                movea.l  (a0), a0
  000b0c:  2f 00                move.l   d0, -(a7)
  000b0e:  20 10                move.l   (a0), d0
  000b10:  e1 88                lsl.l    #$8, d0
  000b12:  e0 88                lsr.l    #$8, d0
  000b14:  20 40                movea.l  d0, a0
  000b16:  20 1f                move.l   (a7)+, d0
  000b18:  d0 fc 00 14          adda.w   #$14, a0
  000b1c:  2f 28 01 00          move.l   $100(a0), -(a7)
  000b20:  20 6f 00 04          movea.l  $4(a7), a0
  000b24:  2e 9f                move.l   (a7)+, (a7)
  000b26:  4e 75                rts
  000b28:  60 00 1b 8e          bra.w    $26b8  ; -> GA_PenPat
  000b2c:  00 00 0f f0          dc.l     $00000FF0  ; dispatch #65
Lb30:
  000b30:  2f 08                move.l   a0, -(a7)
  000b32:  20 78 08 88          movea.l  $888.w, a0
  000b36:  20 50                movea.l  (a0), a0
  000b38:  2f 00                move.l   d0, -(a7)
  000b3a:  20 10                move.l   (a0), d0
  000b3c:  e1 88                lsl.l    #$8, d0
  000b3e:  e0 88                lsr.l    #$8, d0
  000b40:  20 40                movea.l  d0, a0
  000b42:  20 1f                move.l   (a7)+, d0
  000b44:  d0 fc 00 14          adda.w   #$14, a0
  000b48:  2f 28 01 04          move.l   $104(a0), -(a7)
  000b4c:  20 6f 00 04          movea.l  $4(a7), a0
  000b50:  2e 9f                move.l   (a7)+, (a7)
  000b52:  4e 75                rts
  000b54:  60 00 1c 0e          bra.w    $2764  ; -> GA_BackPat
  000b58:  00 00 1a 74          dc.l     $00001A74  ; dispatch #66
Lb5c:
  000b5c:  2f 08                move.l   a0, -(a7)
  000b5e:  20 78 08 88          movea.l  $888.w, a0
  000b62:  20 50                movea.l  (a0), a0
  000b64:  2f 00                move.l   d0, -(a7)
  000b66:  20 10                move.l   (a0), d0
  000b68:  e1 88                lsl.l    #$8, d0
  000b6a:  e0 88                lsr.l    #$8, d0
  000b6c:  20 40                movea.l  d0, a0
  000b6e:  20 1f                move.l   (a7)+, d0
  000b70:  d0 fc 00 14          adda.w   #$14, a0
  000b74:  2f 28 01 08          move.l   $108(a0), -(a7)
  000b78:  20 6f 00 04          movea.l  $4(a7), a0
  000b7c:  2e 9f                move.l   (a7)+, (a7)
  000b7e:  4e 75                rts
  000b80:  60 00 07 b2          bra.w    $1334  ; -> GA_QDExtensions
  000b84:  00 00 16 64          dc.l     $00001664  ; dispatch #67
Lb88:
  000b88:  2f 08                move.l   a0, -(a7)
  000b8a:  20 78 08 88          movea.l  $888.w, a0
  000b8e:  20 50                movea.l  (a0), a0
  000b90:  2f 00                move.l   d0, -(a7)
  000b92:  20 10                move.l   (a0), d0
  000b94:  e1 88                lsl.l    #$8, d0
  000b96:  e0 88                lsr.l    #$8, d0
  000b98:  20 40                movea.l  d0, a0
  000b9a:  20 1f                move.l   (a7)+, d0
  000b9c:  d0 fc 00 14          adda.w   #$14, a0
  000ba0:  2f 28 01 0c          move.l   $10c(a0), -(a7)
  000ba4:  20 6f 00 04          movea.l  $4(a7), a0
  000ba8:  2e 9f                move.l   (a7)+, (a7)
  000baa:  4e 75                rts
  000bac:  60 00 2d a4          bra.w    $3952  ; -> GA_GetForeColor
  000bb0:  00 00 16 68          dc.l     $00001668  ; dispatch #68
Lbb4:
  000bb4:  2f 08                move.l   a0, -(a7)
  000bb6:  20 78 08 88          movea.l  $888.w, a0
  000bba:  20 50                movea.l  (a0), a0
  000bbc:  2f 00                move.l   d0, -(a7)
  000bbe:  20 10                move.l   (a0), d0
  000bc0:  e1 88                lsl.l    #$8, d0
  000bc2:  e0 88                lsr.l    #$8, d0
  000bc4:  20 40                movea.l  d0, a0
  000bc6:  20 1f                move.l   (a7)+, d0
  000bc8:  d0 fc 00 14          adda.w   #$14, a0
  000bcc:  2f 28 01 10          move.l   $110(a0), -(a7)
  000bd0:  20 6f 00 04          movea.l  $4(a7), a0
  000bd4:  2e 9f                move.l   (a7)+, (a7)
  000bd6:  4e 75                rts
  000bd8:  60 00 2e 10          bra.w    $39ea  ; -> GA_GetBackColor
  000bdc:  00 00 08 14          dc.l     $00000814  ; dispatch #69
Lbe0:
  000be0:  2f 08                move.l   a0, -(a7)
  000be2:  20 78 08 88          movea.l  $888.w, a0
  000be6:  20 50                movea.l  (a0), a0
  000be8:  2f 00                move.l   d0, -(a7)
  000bea:  20 10                move.l   (a0), d0
  000bec:  e1 88                lsl.l    #$8, d0
  000bee:  e0 88                lsr.l    #$8, d0
  000bf0:  20 40                movea.l  d0, a0
  000bf2:  20 1f                move.l   (a7)+, d0
  000bf4:  d0 fc 00 14          adda.w   #$14, a0
  000bf8:  2f 28 01 14          move.l   $114(a0), -(a7)
  000bfc:  20 6f 00 04          movea.l  $4(a7), a0
  000c00:  2e 9f                move.l   (a7)+, (a7)
  000c02:  4e 75                rts
  000c04:  60 00 52 60          bra.w    $5e66  ; -> GA_LowMem0814
  000c08:  00 00 08 18          dc.l     $00000818  ; dispatch #70
Lc0c:
  000c0c:  2f 08                move.l   a0, -(a7)
  000c0e:  20 78 08 88          movea.l  $888.w, a0
  000c12:  20 50                movea.l  (a0), a0
  000c14:  2f 00                move.l   d0, -(a7)
  000c16:  20 10                move.l   (a0), d0
  000c18:  e1 88                lsl.l    #$8, d0
  000c1a:  e0 88                lsr.l    #$8, d0
  000c1c:  20 40                movea.l  d0, a0
  000c1e:  20 1f                move.l   (a7)+, d0
  000c20:  d0 fc 00 14          adda.w   #$14, a0
  000c24:  2f 28 01 18          move.l   $118(a0), -(a7)
  000c28:  20 6f 00 04          movea.l  $4(a7), a0
  000c2c:  2e 9f                move.l   (a7)+, (a7)
  000c2e:  4e 75                rts
  000c30:  60 00 4f 92          bra.w    $5bc4  ; -> GA_LowMem0818
  000c34:  00 00 08 1c          dc.l     $0000081C  ; dispatch #71
Lc38:
  000c38:  2f 08                move.l   a0, -(a7)
  000c3a:  20 78 08 88          movea.l  $888.w, a0
  000c3e:  20 50                movea.l  (a0), a0
  000c40:  2f 00                move.l   d0, -(a7)
  000c42:  20 10                move.l   (a0), d0
  000c44:  e1 88                lsl.l    #$8, d0
  000c46:  e0 88                lsr.l    #$8, d0
  000c48:  20 40                movea.l  d0, a0
  000c4a:  20 1f                move.l   (a7)+, d0
  000c4c:  d0 fc 00 14          adda.w   #$14, a0
  000c50:  2f 28 01 1c          move.l   $11c(a0), -(a7)
  000c54:  20 6f 00 04          movea.l  $4(a7), a0
  000c58:  2e 9f                move.l   (a7)+, (a7)
  000c5a:  4e 75                rts
  000c5c:  60 00 4f ea          bra.w    $5c48  ; -> GA_LowMem081C
  000c60:  00 00 08 90          dc.l     $00000890  ; dispatch #72
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
  000c78:  d0 fc 00 14          adda.w   #$14, a0
  000c7c:  2f 28 01 20          move.l   $120(a0), -(a7)
  000c80:  20 6f 00 04          movea.l  $4(a7), a0
  000c84:  2e 9f                move.l   (a7)+, (a7)
  000c86:  4e 75                rts
  000c88:  60 00 50 26          bra.w    $5cb0  ; -> GA_LowMem0890
  000c8c:  00 00 16 b4          dc.l     $000016B4  ; dispatch #73
Lc90:
  000c90:  2f 08                move.l   a0, -(a7)
  000c92:  20 78 08 88          movea.l  $888.w, a0
  000c96:  20 50                movea.l  (a0), a0
  000c98:  2f 00                move.l   d0, -(a7)
  000c9a:  20 10                move.l   (a0), d0
  000c9c:  e1 88                lsl.l    #$8, d0
  000c9e:  e0 88                lsr.l    #$8, d0
  000ca0:  20 40                movea.l  d0, a0
  000ca2:  20 1f                move.l   (a7)+, d0
  000ca4:  d0 fc 00 14          adda.w   #$14, a0
  000ca8:  2f 28 01 24          move.l   $124(a0), -(a7)
  000cac:  20 6f 00 04          movea.l  $4(a7), a0
  000cb0:  2e 9f                move.l   (a7)+, (a7)
  000cb2:  4e 75                rts
  000cb4:  60 00 10 20          bra.w    $1cd6  ; -> GA_SetDeviceAttribute
  000cb8:  00 00 16 c0          dc.l     $000016C0  ; dispatch #74
Lcbc:
  000cbc:  2f 08                move.l   a0, -(a7)
  000cbe:  20 78 08 88          movea.l  $888.w, a0
  000cc2:  20 50                movea.l  (a0), a0
  000cc4:  2f 00                move.l   d0, -(a7)
  000cc6:  20 10                move.l   (a0), d0
  000cc8:  e1 88                lsl.l    #$8, d0
  000cca:  e0 88                lsr.l    #$8, d0
  000ccc:  20 40                movea.l  d0, a0
  000cce:  20 1f                move.l   (a7)+, d0
  000cd0:  d0 fc 00 14          adda.w   #$14, a0
  000cd4:  2f 28 01 28          move.l   $128(a0), -(a7)
  000cd8:  20 6f 00 04          movea.l  $4(a7), a0
  000cdc:  2e 9f                move.l   (a7)+, (a7)
  000cde:  4e 75                rts
  000ce0:  60 00 10 3e          bra.w    $1d20  ; -> GA_DisposGDevice
  000ce4:  00 00 11 d8          dc.l     $000011D8  ; dispatch #75
Lce8:
  000ce8:  2f 08                move.l   a0, -(a7)
  000cea:  20 78 08 88          movea.l  $888.w, a0
  000cee:  20 50                movea.l  (a0), a0
  000cf0:  2f 00                move.l   d0, -(a7)
  000cf2:  20 10                move.l   (a0), d0
  000cf4:  e1 88                lsl.l    #$8, d0
  000cf6:  e0 88                lsr.l    #$8, d0
  000cf8:  20 40                movea.l  d0, a0
  000cfa:  20 1f                move.l   (a7)+, d0
  000cfc:  d0 fc 00 14          adda.w   #$14, a0
  000d00:  2f 28 01 2c          move.l   $12c(a0), -(a7)
  000d04:  20 6f 00 04          movea.l  $4(a7), a0
  000d08:  2e 9f                move.l   (a7)+, (a7)
  000d0a:  4e 75                rts
  000d0c:  60 00 52 88          bra.w    $5f96  ; -> GA_DrawPicture
  000d10:  00 00 16 0c          dc.l     $0000160C  ; dispatch #76
Ld14:
  000d14:  2f 08                move.l   a0, -(a7)
  000d16:  20 78 08 88          movea.l  $888.w, a0
  000d1a:  20 50                movea.l  (a0), a0
  000d1c:  2f 00                move.l   d0, -(a7)
  000d1e:  20 10                move.l   (a0), d0
  000d20:  e1 88                lsl.l    #$8, d0
  000d22:  e0 88                lsr.l    #$8, d0
  000d24:  20 40                movea.l  d0, a0
  000d26:  20 1f                move.l   (a7)+, d0
  000d28:  d0 fc 00 14          adda.w   #$14, a0
  000d2c:  2f 28 01 30          move.l   $130(a0), -(a7)
  000d30:  20 6f 00 04          movea.l  $4(a7), a0
  000d34:  2e 9f                move.l   (a7)+, (a7)
  000d36:  4e 75                rts
  000d38:  60 00 2d 48          bra.w    $3a82  ; -> GA_NewPixMap
  000d3c:  00 00 16 fc          dc.l     $000016FC  ; dispatch #77
Ld40:
  000d40:  2f 08                move.l   a0, -(a7)
  000d42:  20 78 08 88          movea.l  $888.w, a0
  000d46:  20 50                movea.l  (a0), a0
  000d48:  2f 00                move.l   d0, -(a7)
  000d4a:  20 10                move.l   (a0), d0
  000d4c:  e1 88                lsl.l    #$8, d0
  000d4e:  e0 88                lsr.l    #$8, d0
  000d50:  20 40                movea.l  d0, a0
  000d52:  20 1f                move.l   (a7)+, d0
  000d54:  d0 fc 00 14          adda.w   #$14, a0
  000d58:  2f 28 01 34          move.l   $134(a0), -(a7)
  000d5c:  20 6f 00 04          movea.l  $4(a7), a0
  000d60:  2e 9f                move.l   (a7)+, (a7)
  000d62:  4e 75                rts
  000d64:  60 00 0e f8          bra.w    $1c5e  ; -> GA_SetEntries
  000d68:  00 00 10 a8          dc.l     $000010A8  ; dispatch #78
Ld6c:
  000d6c:  2f 08                move.l   a0, -(a7)
  000d6e:  20 78 08 88          movea.l  $888.w, a0
  000d72:  20 50                movea.l  (a0), a0
  000d74:  2f 00                move.l   d0, -(a7)
  000d76:  20 10                move.l   (a0), d0
  000d78:  e1 88                lsl.l    #$8, d0
  000d7a:  e0 88                lsr.l    #$8, d0
  000d7c:  20 40                movea.l  d0, a0
  000d7e:  20 1f                move.l   (a7)+, d0
  000d80:  d0 fc 00 14          adda.w   #$14, a0
  000d84:  2f 28 01 38          move.l   $138(a0), -(a7)
  000d88:  20 6f 00 04          movea.l  $4(a7), a0
  000d8c:  2e 9f                move.l   (a7)+, (a7)
  000d8e:  4e 75                rts
  000d90:  60 00 1b f4          bra.w    $2986  ; -> GA_SectRect
  000d94:  00 00 0f f4          dc.l     $00000FF4  ; dispatch #79
Ld98:
  000d98:  2f 08                move.l   a0, -(a7)
  000d9a:  20 78 08 88          movea.l  $888.w, a0
  000d9e:  20 50                movea.l  (a0), a0
  000da0:  2f 00                move.l   d0, -(a7)
  000da2:  20 10                move.l   (a0), d0
  000da4:  e1 88                lsl.l    #$8, d0
  000da6:  e0 88                lsr.l    #$8, d0
  000da8:  20 40                movea.l  d0, a0
  000daa:  20 1f                move.l   (a7)+, d0
  000dac:  d0 fc 00 14          adda.w   #$14, a0
  000db0:  2f 28 01 3c          move.l   $13c(a0), -(a7)
  000db4:  20 6f 00 04          movea.l  $4(a7), a0
  000db8:  2e 9f                move.l   (a7)+, (a7)
  000dba:  4e 75                rts
  000dbc:  60 00 32 fa          bra.w    $40b8  ; -> GA_CloseCPort
  000dc0:  00 00 16 5c          dc.l     $0000165C  ; dispatch #80
Ldc4:
  000dc4:  2f 08                move.l   a0, -(a7)
  000dc6:  20 78 08 88          movea.l  $888.w, a0
  000dca:  20 50                movea.l  (a0), a0
  000dcc:  2f 00                move.l   d0, -(a7)
  000dce:  20 10                move.l   (a0), d0
  000dd0:  e1 88                lsl.l    #$8, d0
  000dd2:  e0 88                lsr.l    #$8, d0
  000dd4:  20 40                movea.l  d0, a0
  000dd6:  20 1f                move.l   (a7)+, d0
  000dd8:  d0 fc 00 14          adda.w   #$14, a0
  000ddc:  2f 28 01 40          move.l   $140(a0), -(a7)
  000de0:  20 6f 00 04          movea.l  $4(a7), a0
  000de4:  2e 9f                move.l   (a7)+, (a7)
  000de6:  4e 75                rts
  000de8:  60 00 2a 7e          bra.w    $3868  ; -> GA_GetCPixel
  000dec:  00 00 0f 94          dc.l     $00000F94  ; dispatch #81
Ldf0:
  000df0:  2f 08                move.l   a0, -(a7)
  000df2:  20 78 08 88          movea.l  $888.w, a0
  000df6:  20 50                movea.l  (a0), a0
  000df8:  2f 00                move.l   d0, -(a7)
  000dfa:  20 10                move.l   (a0), d0
  000dfc:  e1 88                lsl.l    #$8, d0
  000dfe:  e0 88                lsr.l    #$8, d0
  000e00:  20 40                movea.l  d0, a0
  000e02:  20 1f                move.l   (a7)+, d0
  000e04:  d0 fc 00 14          adda.w   #$14, a0
  000e08:  2f 28 01 44          move.l   $144(a0), -(a7)
  000e0c:  20 6f 00 04          movea.l  $4(a7), a0
  000e10:  2e 9f                move.l   (a7)+, (a7)
  000e12:  4e 75                rts
  000e14:  60 00 29 4c          bra.w    $3762  ; -> GA_GetPixel
  000e18:  00 00 17 40          dc.l     $00001740  ; dispatch #82
Le1c:
  000e1c:  2f 08                move.l   a0, -(a7)
  000e1e:  20 78 08 88          movea.l  $888.w, a0
  000e22:  20 50                movea.l  (a0), a0
  000e24:  2f 00                move.l   d0, -(a7)
  000e26:  20 10                move.l   (a0), d0
  000e28:  e1 88                lsl.l    #$8, d0
  000e2a:  e0 88                lsr.l    #$8, d0
  000e2c:  20 40                movea.l  d0, a0
  000e2e:  20 1f                move.l   (a7)+, d0
  000e30:  d0 fc 00 14          adda.w   #$14, a0
  000e34:  2f 28 01 48          move.l   $148(a0), -(a7)
  000e38:  20 6f 00 04          movea.l  $4(a7), a0
  000e3c:  2e 9f                move.l   (a7)+, (a7)
  000e3e:  4e 75                rts
  000e40:  60 00 51 8e          bra.w    $5fd0  ; -> GA_SeedCFill
  000e44:  00 00 17 3c          dc.l     $0000173C  ; dispatch #83
Le48:
  000e48:  2f 08                move.l   a0, -(a7)
  000e4a:  20 78 08 88          movea.l  $888.w, a0
  000e4e:  20 50                movea.l  (a0), a0
  000e50:  2f 00                move.l   d0, -(a7)
  000e52:  20 10                move.l   (a0), d0
  000e54:  e1 88                lsl.l    #$8, d0
  000e56:  e0 88                lsr.l    #$8, d0
  000e58:  20 40                movea.l  d0, a0
  000e5a:  20 1f                move.l   (a7)+, d0
  000e5c:  d0 fc 00 14          adda.w   #$14, a0
  000e60:  2f 28 01 4c          move.l   $14c(a0), -(a7)
  000e64:  20 6f 00 04          movea.l  $4(a7), a0
  000e68:  2e 9f                move.l   (a7)+, (a7)
  000e6a:  4e 75                rts
  000e6c:  60 00 51 be          bra.w    $602c  ; -> GA_CalcCMask
  000e70:  00 00 17 24          dc.l     $00001724  ; dispatch #84
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
  000e88:  d0 fc 00 14          adda.w   #$14, a0
  000e8c:  2f 28 01 50          move.l   $150(a0), -(a7)
  000e90:  20 6f 00 04          movea.l  $4(a7), a0
  000e94:  2e 9f                move.l   (a7)+, (a7)
  000e96:  4e 75                rts
  000e98:  60 00 0c b0          bra.w    $1b4a  ; -> GA_SaveEntries
  000e9c:  00 00 17 28          dc.l     $00001728  ; dispatch #85
Lea0:
  000ea0:  2f 08                move.l   a0, -(a7)
  000ea2:  20 78 08 88          movea.l  $888.w, a0
  000ea6:  20 50                movea.l  (a0), a0
  000ea8:  2f 00                move.l   d0, -(a7)
  000eaa:  20 10                move.l   (a0), d0
  000eac:  e1 88                lsl.l    #$8, d0
  000eae:  e0 88                lsr.l    #$8, d0
  000eb0:  20 40                movea.l  d0, a0
  000eb2:  20 1f                move.l   (a7)+, d0
  000eb4:  d0 fc 00 14          adda.w   #$14, a0
  000eb8:  2f 28 01 54          move.l   $154(a0), -(a7)
  000ebc:  20 6f 00 04          movea.l  $4(a7), a0
  000ec0:  2e 9f                move.l   (a7)+, (a7)
  000ec2:  4e 75                rts
  000ec4:  60 00 0c e2          bra.w    $1ba8  ; -> GA_RestoreEntries
  000ec8:  00 00 16 dc          dc.l     $000016DC  ; dispatch #86
Lecc:
  000ecc:  2f 08                move.l   a0, -(a7)
  000ece:  20 78 08 88          movea.l  $888.w, a0
  000ed2:  20 50                movea.l  (a0), a0
  000ed4:  2f 00                move.l   d0, -(a7)
  000ed6:  20 10                move.l   (a0), d0
  000ed8:  e1 88                lsl.l    #$8, d0
  000eda:  e0 88                lsr.l    #$8, d0
  000edc:  20 40                movea.l  d0, a0
  000ede:  20 1f                move.l   (a7)+, d0
  000ee0:  d0 fc 00 14          adda.w   #$14, a0
  000ee4:  2f 28 01 58          move.l   $158(a0), -(a7)
  000ee8:  20 6f 00 04          movea.l  $4(a7), a0
  000eec:  2e 9f                move.l   (a7)+, (a7)
  000eee:  4e 75                rts
  000ef0:  60 00 0d 14          bra.w    $1c06  ; -> GA_GetSubTable
  000ef4:  00 00 16 a0          dc.l     $000016A0  ; dispatch #87
Lef8:
  000ef8:  2f 08                move.l   a0, -(a7)
  000efa:  20 78 08 88          movea.l  $888.w, a0
  000efe:  20 50                movea.l  (a0), a0
  000f00:  2f 00                move.l   d0, -(a7)
  000f02:  20 10                move.l   (a0), d0
  000f04:  e1 88                lsl.l    #$8, d0
  000f06:  e0 88                lsr.l    #$8, d0
  000f08:  20 40                movea.l  d0, a0
  000f0a:  20 1f                move.l   (a7)+, d0
  000f0c:  d0 fc 00 14          adda.w   #$14, a0
  000f10:  2f 28 01 5c          move.l   $15c(a0), -(a7)
  000f14:  20 6f 00 04          movea.l  $4(a7), a0
  000f18:  2e 9f                move.l   (a7)+, (a7)
  000f1a:  4e 75                rts
  000f1c:  60 00 03 96          bra.w    $12b4  ; -> GA_GETCTSEED
  000f20:  00 00 18 88          dc.l     $00001888  ; dispatch #88
Lf24:
  000f24:  2f 08                move.l   a0, -(a7)
  000f26:  20 78 08 88          movea.l  $888.w, a0
  000f2a:  20 50                movea.l  (a0), a0
  000f2c:  2f 00                move.l   d0, -(a7)
  000f2e:  20 10                move.l   (a0), d0
  000f30:  e1 88                lsl.l    #$8, d0
  000f32:  e0 88                lsr.l    #$8, d0
  000f34:  20 40                movea.l  d0, a0
  000f36:  20 1f                move.l   (a7)+, d0
  000f38:  d0 fc 00 14          adda.w   #$14, a0
  000f3c:  2f 28 01 60          move.l   $160(a0), -(a7)
  000f40:  20 6f 00 04          movea.l  $4(a7), a0
  000f44:  2e 9f                move.l   (a7)+, (a7)
  000f46:  4e 75                rts
  000f48:  60 00 03 a6          bra.w    $12f0  ; -> GA_PMGR
  000f4c:  00 00 18 50          dc.l     $00001850  ; dispatch #89
Lf50:
  000f50:  2f 08                move.l   a0, -(a7)
  000f52:  20 78 08 88          movea.l  $888.w, a0
  000f56:  20 50                movea.l  (a0), a0
  000f58:  2f 00                move.l   d0, -(a7)
  000f5a:  20 10                move.l   (a0), d0
  000f5c:  e1 88                lsl.l    #$8, d0
  000f5e:  e0 88                lsr.l    #$8, d0
  000f60:  20 40                movea.l  d0, a0
  000f62:  20 1f                move.l   (a7)+, d0
  000f64:  d0 fc 00 14          adda.w   #$14, a0
  000f68:  2f 28 01 64          move.l   $164(a0), -(a7)
  000f6c:  20 6f 00 04          movea.l  $4(a7), a0
  000f70:  2e 9f                move.l   (a7)+, (a7)
  000f72:  4e 75                rts
  000f74:  60 00 0a fa          bra.w    $1a70  ; -> GA_ActivatePalette
  000f78:  00 00 18 54          dc.l     $00001854  ; dispatch #90
Lf7c:
  000f7c:  2f 08                move.l   a0, -(a7)
  000f7e:  20 78 08 88          movea.l  $888.w, a0
  000f82:  20 50                movea.l  (a0), a0
  000f84:  2f 00                move.l   d0, -(a7)
  000f86:  20 10                move.l   (a0), d0
  000f88:  e1 88                lsl.l    #$8, d0
  000f8a:  e0 88                lsr.l    #$8, d0
  000f8c:  20 40                movea.l  d0, a0
  000f8e:  20 1f                move.l   (a7)+, d0
  000f90:  d0 fc 00 14          adda.w   #$14, a0
  000f94:  2f 28 01 68          move.l   $168(a0), -(a7)
  000f98:  20 6f 00 04          movea.l  $4(a7), a0
  000f9c:  2e 9f                move.l   (a7)+, (a7)
  000f9e:  4e 75                rts
  000fa0:  60 00 0a 88          bra.w    $1a2a  ; -> GA_SetPalette
  000fa4:  00 00 18 80          dc.l     $00001880  ; dispatch #91
Lfa8:
  000fa8:  2f 08                move.l   a0, -(a7)
  000faa:  20 78 08 88          movea.l  $888.w, a0
  000fae:  20 50                movea.l  (a0), a0
  000fb0:  2f 00                move.l   d0, -(a7)
  000fb2:  20 10                move.l   (a0), d0
  000fb4:  e1 88                lsl.l    #$8, d0
  000fb6:  e0 88                lsr.l    #$8, d0
  000fb8:  20 40                movea.l  d0, a0
  000fba:  20 1f                move.l   (a7)+, d0
  000fbc:  d0 fc 00 14          adda.w   #$14, a0
  000fc0:  2f 28 01 6c          move.l   $16c(a0), -(a7)
  000fc4:  20 6f 00 04          movea.l  $4(a7), a0
  000fc8:  2e 9f                move.l   (a7)+, (a7)
  000fca:  4e 75                rts
  000fcc:  60 00 0a d6          bra.w    $1aa4  ; -> GA_Palette2CTab
  000fd0:  00 00 16 e4          dc.l     $000016E4  ; dispatch #92
Lfd4:
  000fd4:  2f 08                move.l   a0, -(a7)
  000fd6:  20 78 08 88          movea.l  $888.w, a0
  000fda:  20 50                movea.l  (a0), a0
  000fdc:  2f 00                move.l   d0, -(a7)
  000fde:  20 10                move.l   (a0), d0
  000fe0:  e1 88                lsl.l    #$8, d0
  000fe2:  e0 88                lsr.l    #$8, d0
  000fe4:  20 40                movea.l  d0, a0
  000fe6:  20 1f                move.l   (a7)+, d0
  000fe8:  d0 fc 00 14          adda.w   #$14, a0
  000fec:  2f 28 01 70          move.l   $170(a0), -(a7)
  000ff0:  20 6f 00 04          movea.l  $4(a7), a0
  000ff4:  2e 9f                move.l   (a7)+, (a7)
  000ff6:  4e 75                rts
  000ff8:  60 00 0a e8          bra.w    $1ae2  ; -> GA_MakeITable
  000ffc:  00 00 0f b8          dc.l     $00000FB8  ; dispatch #93
L1000:
  001000:  2f 08                move.l   a0, -(a7)
  001002:  20 78 08 88          movea.l  $888.w, a0
  001006:  20 50                movea.l  (a0), a0
  001008:  2f 00                move.l   d0, -(a7)
  00100a:  20 10                move.l   (a0), d0
  00100c:  e1 88                lsl.l    #$8, d0
  00100e:  e0 88                lsr.l    #$8, d0
  001010:  20 40                movea.l  d0, a0
  001012:  20 1f                move.l   (a7)+, d0
  001014:  d0 fc 00 14          adda.w   #$14, a0
  001018:  2f 28 01 74          move.l   $174(a0), -(a7)
  00101c:  20 6f 00 04          movea.l  $4(a7), a0
  001020:  2e 9f                move.l   (a7)+, (a7)
  001022:  4e 75                rts
  001024:  60 00 4e a8          bra.w    $5ece  ; -> GA_InitGraf
  001028:  00 00 0f b4          dc.l     $00000FB4  ; dispatch #94
L102c:
  00102c:  2f 08                move.l   a0, -(a7)
  00102e:  20 78 08 88          movea.l  $888.w, a0
  001032:  20 50                movea.l  (a0), a0
  001034:  2f 00                move.l   d0, -(a7)
  001036:  20 10                move.l   (a0), d0
  001038:  e1 88                lsl.l    #$8, d0
  00103a:  e0 88                lsr.l    #$8, d0
  00103c:  20 40                movea.l  d0, a0
  00103e:  20 1f                move.l   (a7)+, d0
  001040:  d0 fc 00 14          adda.w   #$14, a0
  001044:  2f 28 01 78          move.l   $178(a0), -(a7)
  001048:  20 6f 00 04          movea.l  $4(a7), a0
  00104c:  2e 9f                move.l   (a7)+, (a7)
  00104e:  4e 75                rts
  001050:  60 00 4e a4          bra.w    $5ef6  ; -> GA_InitPort
  001054:  00 00 0f bc          dc.l     $00000FBC  ; dispatch #95
L1058:
  001058:  2f 08                move.l   a0, -(a7)
  00105a:  20 78 08 88          movea.l  $888.w, a0
  00105e:  20 50                movea.l  (a0), a0
  001060:  2f 00                move.l   d0, -(a7)
  001062:  20 10                move.l   (a0), d0
  001064:  e1 88                lsl.l    #$8, d0
  001066:  e0 88                lsr.l    #$8, d0
  001068:  20 40                movea.l  d0, a0
  00106a:  20 1f                move.l   (a7)+, d0
  00106c:  d0 fc 00 14          adda.w   #$14, a0
  001070:  2f 28 01 7c          move.l   $17c(a0), -(a7)
  001074:  20 6f 00 04          movea.l  $4(a7), a0
  001078:  2e 9f                move.l   (a7)+, (a7)
  00107a:  4e 75                rts
  00107c:  60 00 4e a0          bra.w    $5f1e  ; -> GA_OpenPort
  001080:  00 00 16 04          dc.l     $00001604  ; dispatch #96
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
  001098:  d0 fc 00 14          adda.w   #$14, a0
  00109c:  2f 28 01 80          move.l   $180(a0), -(a7)
  0010a0:  20 6f 00 04          movea.l  $4(a7), a0
  0010a4:  2e 9f                move.l   (a7)+, (a7)
  0010a6:  4e 75                rts
  0010a8:  60 00 4e 9c          bra.w    $5f46  ; -> GA_InitCPort
  0010ac:  00 00 16 00          dc.l     $00001600  ; dispatch #97
L10b0:
  0010b0:  2f 08                move.l   a0, -(a7)
  0010b2:  20 78 08 88          movea.l  $888.w, a0
  0010b6:  20 50                movea.l  (a0), a0
  0010b8:  2f 00                move.l   d0, -(a7)
  0010ba:  20 10                move.l   (a0), d0
  0010bc:  e1 88                lsl.l    #$8, d0
  0010be:  e0 88                lsr.l    #$8, d0
  0010c0:  20 40                movea.l  d0, a0
  0010c2:  20 1f                move.l   (a7)+, d0
  0010c4:  d0 fc 00 14          adda.w   #$14, a0
  0010c8:  2f 28 01 84          move.l   $184(a0), -(a7)
  0010cc:  20 6f 00 04          movea.l  $4(a7), a0
  0010d0:  2e 9f                move.l   (a7)+, (a7)
  0010d2:  4e 75                rts
  0010d4:  60 00 4e 98          bra.w    $5f6e  ; -> GA_OpenCPort
  0010d8:  00 00 16 08          dc.l     $00001608  ; dispatch #98
L10dc:
  0010dc:  2f 08                move.l   a0, -(a7)
  0010de:  20 78 08 88          movea.l  $888.w, a0
  0010e2:  20 50                movea.l  (a0), a0
  0010e4:  2f 00                move.l   d0, -(a7)
  0010e6:  20 10                move.l   (a0), d0
  0010e8:  e1 88                lsl.l    #$8, d0
  0010ea:  e0 88                lsr.l    #$8, d0
  0010ec:  20 40                movea.l  d0, a0
  0010ee:  20 1f                move.l   (a7)+, d0
  0010f0:  d0 fc 00 14          adda.w   #$14, a0
  0010f4:  2f 28 01 88          move.l   $188(a0), -(a7)
  0010f8:  20 6f 00 04          movea.l  $4(a7), a0
  0010fc:  2e 9f                move.l   (a7)+, (a7)
  0010fe:  4e 75                rts
  001100:  60 00 2f b6          bra.w    $40b8  ; -> GA_CloseCPort
  001104:  00 00 16 b8          dc.l     $000016B8  ; dispatch #99
L1108:
  001108:  2f 08                move.l   a0, -(a7)
  00110a:  20 78 08 88          movea.l  $888.w, a0
  00110e:  20 50                movea.l  (a0), a0
  001110:  2f 00                move.l   d0, -(a7)
  001112:  20 10                move.l   (a0), d0
  001114:  e1 88                lsl.l    #$8, d0
  001116:  e0 88                lsr.l    #$8, d0
  001118:  20 40                movea.l  d0, a0
  00111a:  20 1f                move.l   (a7)+, d0
  00111c:  d0 fc 00 14          adda.w   #$14, a0
  001120:  2f 28 01 8c          move.l   $18c(a0), -(a7)
  001124:  20 6f 00 04          movea.l  $4(a7), a0
  001128:  2e 9f                move.l   (a7)+, (a7)
  00112a:  4e 75                rts
  00112c:  60 00 0c 72          bra.w    $1da0  ; -> GA_InitGDevice
  001130:  00 00 11 5c          dc.l     $0000115C  ; dispatch #100
L1134:
  001134:  2f 08                move.l   a0, -(a7)
  001136:  20 78 08 88          movea.l  $888.w, a0
  00113a:  20 50                movea.l  (a0), a0
  00113c:  2f 00                move.l   d0, -(a7)
  00113e:  20 10                move.l   (a0), d0
  001140:  e1 88                lsl.l    #$8, d0
  001142:  e0 88                lsr.l    #$8, d0
  001144:  20 40                movea.l  d0, a0
  001146:  20 1f                move.l   (a7)+, d0
  001148:  d0 fc 00 14          adda.w   #$14, a0
  00114c:  2f 28 01 90          move.l   $190(a0), -(a7)
  001150:  20 6f 00 04          movea.l  $4(a7), a0
  001154:  2e 9f                move.l   (a7)+, (a7)
  001156:  4e 75                rts
  001158:  60 00 2c e0          bra.w    $3e3a  ; -> GA_BitMapRgn
  00115c:  00 00 16 8c          dc.l     $0000168C  ; dispatch #101
L1160:
  001160:  2f 08                move.l   a0, -(a7)
  001162:  20 78 08 88          movea.l  $888.w, a0
  001166:  20 50                movea.l  (a0), a0
  001168:  2f 00                move.l   d0, -(a7)
  00116a:  20 10                move.l   (a0), d0
  00116c:  e1 88                lsl.l    #$8, d0
  00116e:  e0 88                lsr.l    #$8, d0
  001170:  20 40                movea.l  d0, a0
  001172:  20 1f                move.l   (a7)+, d0
  001174:  d0 fc 00 14          adda.w   #$14, a0
  001178:  2f 28 01 94          move.l   $194(a0), -(a7)
  00117c:  20 6f 00 04          movea.l  $4(a7), a0
  001180:  2e 9f                move.l   (a7)+, (a7)
  001182:  4e 75                rts
  001184:  60 00 2f 50          bra.w    $40d6  ; -> GA_CharExtra
  001188:  ff ff ff ff          dc.l     $FFFFFFFF  ; dispatch #102
L118c:
  00118c:  2f 08                move.l   a0, -(a7)
  00118e:  20 78 08 88          movea.l  $888.w, a0
  001192:  20 50                movea.l  (a0), a0
  001194:  2f 00                move.l   d0, -(a7)
  001196:  20 10                move.l   (a0), d0
  001198:  e1 88                lsl.l    #$8, d0
  00119a:  e0 88                lsr.l    #$8, d0
  00119c:  20 40                movea.l  d0, a0
  00119e:  20 1f                move.l   (a7)+, d0
  0011a0:  d0 fc 00 14          adda.w   #$14, a0
  0011a4:  2f 28 01 98          move.l   $198(a0), -(a7)
  0011a8:  20 6f 00 04          movea.l  $4(a7), a0
  0011ac:  2e 9f                move.l   (a7)+, (a7)
  0011ae:  4e 75                rts
  0011b0:  60 00 73 f8          bra.w    $85aa  ; -> GA_ControlFFFFFFFF
  0011b4:  ff ff ff fe          dc.l     $FFFFFFFE  ; dispatch #103
L11b8:
  0011b8:  2f 08                move.l   a0, -(a7)
  0011ba:  20 78 08 88          movea.l  $888.w, a0
  0011be:  20 50                movea.l  (a0), a0
  0011c0:  2f 00                move.l   d0, -(a7)
  0011c2:  20 10                move.l   (a0), d0
  0011c4:  e1 88                lsl.l    #$8, d0
  0011c6:  e0 88                lsr.l    #$8, d0
  0011c8:  20 40                movea.l  d0, a0
  0011ca:  20 1f                move.l   (a7)+, d0
  0011cc:  d0 fc 00 14          adda.w   #$14, a0
  0011d0:  2f 28 01 9c          move.l   $19c(a0), -(a7)
  0011d4:  20 6f 00 04          movea.l  $4(a7), a0
  0011d8:  2e 9f                move.l   (a7)+, (a7)
  0011da:  4e 75                rts
  0011dc:  60 00 74 5a          bra.w    $8638  ; -> GA_ControlFFFFFFFE
  0011e0:  ff ff ff fd          dc.l     $FFFFFFFD  ; dispatch #104
L11e4:
  0011e4:  2f 08                move.l   a0, -(a7)
  0011e6:  20 78 08 88          movea.l  $888.w, a0
  0011ea:  20 50                movea.l  (a0), a0
  0011ec:  2f 00                move.l   d0, -(a7)
  0011ee:  20 10                move.l   (a0), d0
  0011f0:  e1 88                lsl.l    #$8, d0
  0011f2:  e0 88                lsr.l    #$8, d0
  0011f4:  20 40                movea.l  d0, a0
  0011f6:  20 1f                move.l   (a7)+, d0
  0011f8:  d0 fc 00 14          adda.w   #$14, a0
  0011fc:  2f 28 01 a0          move.l   $1a0(a0), -(a7)
  001200:  20 6f 00 04          movea.l  $4(a7), a0
  001204:  2e 9f                move.l   (a7)+, (a7)
  001206:  4e 75                rts
  001208:  60 00 73 76          bra.w    $8580  ; -> GA_ControlFFFFFFFD
  00120c:  00 00 00 00 00 00 00 00 dc.b     $00, $00, $00, $00, $00, $00, $00, $00  ; ........
  001214:  00 00 00 00 00 00 00 00 dc.b     $00, $00, $00, $00, $00, $00, $00, $00  ; ........
  00121c:  00 00 00 00 00 00 00 00 dc.b     $00, $00, $00, $00, $00, $00, $00, $00  ; ........
  001224:  00 00 00 00 00 00 00 00 dc.b     $00, $00, $00, $00, $00, $00, $00, $00  ; ........
  00122c:  00 00 00 00          dc.b     $00, $00, $00, $00  ; ....
* GetA5  -  System 7 $8010 (identical bytes, S6 MacsBug name).
* S7: GetA5  -  returns A5 (the QuickDraw/app globals world) in D0.
GetA5:
  001230:  20 0d                move.l   a5, d0
  001232:  4e 75                rts
  001234:  47 65 74 41 35 00 00 00 dc.b     $47, $65, $74, $41, $35, $00, $00, $00  ; GetA5...
* GACursorTask  -  System 7 $801C (same trap slot $8EE, code r=0.97).
GACursorTask:
  00123c:  48 e7 ff f8          movem.l  d0-d7/a0-a4, -(a7)
  001240:  20 38 08 88          move.l   $888.w, d0
  001244:  67 5c                beq.b    $12a2  ; -> L12a2
  001246:  22 40                movea.l  d0, a1
  001248:  0c a9 07 5b cd 15 00 20 cmpi.l   #$75bcd15, $20(a1)
  001250:  66 50                bne.b    $12a2  ; -> L12a2
  001252:  20 69 00 08          movea.l  $8(a1), a0
  001256:  22 10                move.l   (a0), d1
  001258:  24 69 00 0c          movea.l  $c(a1), a2
  00125c:  4a 92                tst.l    (a2)
  00125e:  66 42                bne.b    $12a2  ; -> L12a2
  001260:  20 3c 00 00 08 ee    move.l   #$8ee, d0
  001266:  20 80                move.l   d0, (a0)
  001268:  24 69 00 30          movea.l  $30(a1), a2
  00126c:  4a 92                tst.l    (a2)
  00126e:  67 06                beq.b    $1276  ; -> L1276
  001270:  42 38 08 cc          clr.b    $8cc.w
  001274:  42 92                clr.l    (a2)
L1276:
  001276:  4a 38 08 d2          tst.b    $8d2.w
  00127a:  66 10                bne.b    $128c  ; -> L128c
  00127c:  24 69 00 34          movea.l  $34(a1), a2
  001280:  4a 92                tst.l    (a2)
  001282:  67 08                beq.b    $128c  ; -> L128c
  001284:  11 fc 00 01 08 ce    move.b   #$1, $8ce.w
  00128a:  42 92                clr.l    (a2)
L128c:
  00128c:  48 e7 40 80          movem.l  d1/a0, -(a7)
  001290:  2f 00                move.l   d0, -(a7)
  001292:  4e ba 74 08          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001296:  58 8f                addq.l   #$4, a7
  001298:  20 40                movea.l  d0, a0
  00129a:  4e 90                jsr      (a0)
  00129c:  4c df 01 02          movem.l  (a7)+, d1/a0
  0012a0:  20 81                move.l   d1, (a0)
L12a2:
  0012a2:  4c df 1f ff          movem.l  (a7)+, d0-d7/a0-a4
  0012a6:  4e 75                rts
  0012a8:  47 41 43 75 72 73 6f 72 dc.b     $47, $41, $43, $75, $72, $73, $6F, $72  ; GACursor
  0012b0:  54 61 73 6b          dc.b     $54, $61, $73, $6B  ; Task
* GA_GETCTSEED  -  System 7 $8098 (identical code).
GA_GETCTSEED:
  0012b4:  2f 08                move.l   a0, -(a7)
  0012b6:  48 e7 e0 60          movem.l  d0-d2/a1-a2, -(a7)
  0012ba:  42 a7                clr.l    -(a7)
  0012bc:  4e ba 4d d6          jsr      $6094(pc)  ; -> s7_sub_4822
  0012c0:  58 8f                addq.l   #$4, a7
  0012c2:  2f 3c 00 00 16 a0    move.l   #$16a0, -(a7)
  0012c8:  4e ba 73 d2          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0012cc:  58 8f                addq.l   #$4, a7
  0012ce:  20 40                movea.l  d0, a0
  0012d0:  4c df 06 07          movem.l  (a7)+, d0-d2/a1-a2
  0012d4:  2f 08                move.l   a0, -(a7)
  0012d6:  20 6f 00 04          movea.l  $4(a7), a0
  0012da:  2f 57 00 04          move.l   (a7), $4(a7)
  0012de:  58 8f                addq.l   #$4, a7
  0012e0:  4e 75                rts
  0012e2:  47 41 5f 47 45 54 43 54 dc.b     $47, $41, $5F, $47, $45, $54, $43, $54  ; GA_GETCT
  0012ea:  53 45 45 44 00 00    dc.b     $53, $45, $45, $44, $00, $00  ; SEED..
* GA_PMGR  -  System 7 $80D4 (identical code).
GA_PMGR:
  0012f0:  2f 08                move.l   a0, -(a7)
  0012f2:  48 e7 e0 60          movem.l  d0-d2/a1-a2, -(a7)
  0012f6:  0c 40 00 0c          cmpi.w   #$c, d0
  0012fa:  66 10                bne.b    $130c  ; -> L130c
  0012fc:  4e ba 23 be          jsr      $36bc(pc)  ; -> s7_sub_b1be
  001300:  4a 80                tst.l    d0
  001302:  66 08                bne.b    $130c  ; -> L130c
  001304:  4c df 06 07          movem.l  (a7)+, d0-d2/a1-a2
  001308:  20 5f                movea.l  (a7)+, a0
  00130a:  4e 75                rts
L130c:
  00130c:  2f 3c 00 00 18 88    move.l   #$1888, -(a7)
  001312:  4e ba 73 88          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001316:  58 8f                addq.l   #$4, a7
  001318:  20 40                movea.l  d0, a0
  00131a:  4c df 06 07          movem.l  (a7)+, d0-d2/a1-a2
  00131e:  2f 08                move.l   a0, -(a7)
  001320:  20 6f 00 04          movea.l  $4(a7), a0
  001324:  2f 57 00 04          move.l   (a7), $4(a7)
  001328:  58 8f                addq.l   #$4, a7
  00132a:  4e 75                rts
  00132c:  47 41 5f 50 4d 47 52 00 dc.b     $47, $41, $5F, $50, $4D, $47, $52, $00  ; GA_PMGR.
* GA_QDExtensions  -  System 7 $8118 (same trap slot $1A74, code r=0.89).
* S7: Patch #66 replaces _QDExtensions ($AB1D); no EngineDispatch command found
GA_QDExtensions:
  001334:  0c 40 00 08          cmpi.w   #$8, d0
  001338:  67 68                beq.b    $13a2  ; -> L13a2
  00133a:  0c 40 00 01          cmpi.w   #$1, d0
  00133e:  67 3a                beq.b    $137a  ; -> L137a
  001340:  0c 40 00 04          cmpi.w   #$4, d0
  001344:  67 38                beq.b    $137e  ; -> L137e
  001346:  0c 40 00 0a          cmpi.w   #$a, d0
  00134a:  67 36                beq.b    $1382  ; -> L1382
  00134c:  0c 40 00 0f          cmpi.w   #$f, d0
  001350:  67 34                beq.b    $1386  ; -> L1386
  001352:  0c 40 00 11          cmpi.w   #$11, d0
  001356:  67 32                beq.b    $138a  ; -> L138a
  001358:  0c 40 00 13          cmpi.w   #$13, d0
  00135c:  67 30                beq.b    $138e  ; -> L138e
  00135e:  0c 40 00 02          cmpi.w   #$2, d0
  001362:  67 2e                beq.b    $1392  ; -> L1392
  001364:  0c 40 00 03          cmpi.w   #$3, d0
  001368:  67 2c                beq.b    $1396  ; -> L1396
  00136a:  0c 40 00 00          cmpi.w   #$0, d0
  00136e:  67 2a                beq.b    $139a  ; -> L139a
  001370:  0c 40 00 09          cmpi.w   #$9, d0
  001374:  67 28                beq.b    $139e  ; -> L139e
  001376:  2f 00                move.l   d0, -(a7)
  001378:  60 32                bra.b    $13ac  ; -> L13ac
L137a:
  00137a:  4e fa 2b 36          jmp      $3eb2(pc)  ; -> s7_Lb940
L137e:
  00137e:  4e fa 2c d0          jmp      $4050(pc)  ; -> s7_Lbb14
L1382:
  001382:  4e fa 2e 7a          jmp      $41fe(pc)  ; -> s7_Lbd76
L1386:
  001386:  4e fa 2f 46          jmp      $42ce(pc)  ; -> s7_Lbe74
L138a:
  00138a:  4e fa 2f 64          jmp      $42f0(pc)  ; -> L42f0
L138e:
  00138e:  4e fa 2f aa          jmp      $433a(pc)  ; -> s7_Lbecc
L1392:
  001392:  4e fa 2b 90          jmp      $3f24(pc)  ; -> s7_Lb9b4
L1396:
  001396:  4e fa 2c 34          jmp      $3fcc(pc)  ; -> s7_Lba64
L139a:
  00139a:  4e fa 2b c8          jmp      $3f64(pc)  ; -> s7_Lb9fc
L139e:
  00139e:  4e fa 2e 2e          jmp      $41ce(pc)  ; -> L41ce
L13a2:
  0013a2:  2f 00                move.l   d0, -(a7)
  0013a4:  2f 2f 00 08          move.l   $8(a7), -(a7)
  0013a8:  4e ba 2d a8          jsr      $4152(pc)  ; -> s7_sub_bcc8
L13ac:
  0013ac:  2f 3c 00 00 1a 74    move.l   #$1a74, -(a7)
  0013b2:  4e ba 72 e8          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0013b6:  58 8f                addq.l   #$4, a7
  0013b8:  20 40                movea.l  d0, a0
  0013ba:  20 1f                move.l   (a7)+, d0
  0013bc:  4e d0                jmp      (a0)
  0013be:  47 41 5f 51 44 4f 46 46 dc.b     $47, $41, $5F, $51, $44, $4F, $46, $46  ; GA_QDOFF
  0013c6:  53 43 52 45 45 4e    dc.b     $53, $43, $52, $45, $45, $4E  ; SCREEN
* s7_sub_8da4  -  System 7 $8DA4 (similar code, r=0.80).
s7_sub_8da4:
  0013cc:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  0013d0:  28 6f 00 18          movea.l  $18(a7), a4
  0013d4:  26 6f 00 14          movea.l  $14(a7), a3
  0013d8:  2c 2b 00 30          move.l   $30(a3), d6
  0013dc:  30 2b 00 06          move.w   $6(a3), d0
  0013e0:  48 c0                ext.l    d0
  0013e2:  6c 08                bge.b    $13ec  ; -> L13ec
  0013e4:  30 2b 00 0e          move.w   $e(a3), d0
  0013e8:  48 c0                ext.l    d0
  0013ea:  60 06                bra.b    $13f2  ; -> L13f2
L13ec:
  0013ec:  20 3c 00 00 80 00    move.l   #$8000, d0
L13f2:
  0013f2:  3e 00                move.w   d0, d7
  0013f4:  bc 94                cmp.l    (a4), d6
  0013f6:  66 10                bne.b    $1408  ; -> L1408
  0013f8:  70 00                moveq    #$0, d0
  0013fa:  30 07                move.w   d7, d0
  0013fc:  20 6f 00 1c          movea.l  $1c(a7), a0
  001400:  72 00                moveq    #$0, d1
  001402:  32 10                move.w   (a0), d1
  001404:  b2 80                cmp.l    d0, d1
  001406:  67 0c                beq.b    $1414  ; -> L1414
L1408:
  001408:  28 86                move.l   d6, (a4)
  00140a:  20 6f 00 1c          movea.l  $1c(a7), a0
  00140e:  30 87                move.w   d7, (a0)
  001410:  70 01                moveq    #$1, d0
  001412:  60 02                bra.b    $1416  ; -> L1416
L1414:
  001414:  70 00                moveq    #$0, d0
L1416:
  001416:  4c df 18 c0          movem.l  (a7)+, d6-d7/a3-a4
  00141a:  4e 75                rts
* s7_sub_8df2  -  System 7 $8DF2 (similar code, r=0.89).
s7_sub_8df2:
  00141c:  48 e7 00 18          movem.l  a3-a4, -(a7)
  001420:  28 6f 00 0c          movea.l  $c(a7), a4
  001424:  30 2c 00 06          move.w   $6(a4), d0
  001428:  48 c0                ext.l    d0
  00142a:  6c 1e                bge.b    $144a  ; -> L144a
  00142c:  20 6c 00 08          movea.l  $8(a4), a0
  001430:  26 50                movea.l  (a0), a3
  001432:  20 6f 00 14          movea.l  $14(a7), a0
  001436:  22 4b                movea.l  a3, a1
  001438:  20 d9                move.l   (a1)+, (a0)+
  00143a:  30 d9                move.w   (a1)+, (a0)+
  00143c:  20 6f 00 10          movea.l  $10(a7), a0
  001440:  22 4b                movea.l  a3, a1
  001442:  5c 89                addq.l   #$6, a1
  001444:  20 d9                move.l   (a1)+, (a0)+
  001446:  30 d9                move.w   (a1)+, (a0)+
  001448:  60 0c                bra.b    $1456  ; -> L1456
L144a:
  00144a:  20 6f 00 10          movea.l  $10(a7), a0
  00144e:  43 f8 0d a0          lea.l    $da0.w, a1
  001452:  20 d9                move.l   (a1)+, (a0)+
  001454:  30 d9                move.w   (a1)+, (a0)+
L1456:
  001456:  4c df 18 00          movem.l  (a7)+, a3-a4
  00145a:  4e 75                rts
* s7_sub_8e38  -  System 7 $8E38 (similar code, r=0.71).
s7_sub_8e38:
  00145c:  4e 56 00 00          link.w   a6, #$0
  001460:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  001464:  28 6e 00 0c          movea.l  $c(a6), a4
  001468:  3c 2e 00 0a          move.w   $a(a6), d6
  00146c:  26 6e 00 14          movea.l  $14(a6), a3
  001470:  48 c6                ext.l    d6
  001472:  4a 86                tst.l    d6
  001474:  57 c0                seq.b    d0
  001476:  02 40 00 01          andi.w   #$1, d0
  00147a:  20 6e 00 10          movea.l  $10(a6), a0
  00147e:  30 80                move.w   d0, (a0)
  001480:  30 06                move.w   d6, d0
  001482:  6b 7e                bmi.b    $1502  ; -> L1502
  001484:  0c 40 00 05          cmpi.w   #$5, d0
  001488:  6e 78                bgt.b    $1502  ; -> L1502
  00148a:  d0 40                add.w    d0, d0
  00148c:  30 3b 00 06          move.w   $1494(pc, d0.w), d0
  001490:  4e fb 00 00          jmp      $1492(pc,d0.w)
  001494:  00 0e                dc.w     $000E    ; [0] -> L14a0
  001496:  00 0e                dc.w     $000E    ; [1] -> L14a0
  001498:  00 28                dc.w     $0028    ; [2] -> L14ba
  00149a:  00 30                dc.w     $0030    ; [3] -> L14c2
  00149c:  00 54                dc.w     $0054    ; [4] -> L14e6
  00149e:  00 5c                dc.w     $005C    ; [5] -> L14ee
L14a0:
  0014a0:  4e ba fd 8e          jsr      $1230(pc)  ; -> GetA5
  0014a4:  20 40                movea.l  d0, a0
  0014a6:  20 50                movea.l  (a0), a0
  0014a8:  20 50                movea.l  (a0), a0
  0014aa:  30 28 00 38          move.w   $38(a0), d0
  0014ae:  48 c0                ext.l    d0
  0014b0:  7e 08                moveq    #$8, d7
  0014b2:  8e 80                or.l     d0, d7
  0014b4:  36 bc 00 01          move.w   #$1, (a3)
  0014b8:  60 48                bra.b    $1502  ; -> L1502
L14ba:
  0014ba:  7e 08                moveq    #$8, d7
  0014bc:  36 bc 00 02          move.w   #$2, (a3)
  0014c0:  60 40                bra.b    $1502  ; -> L1502
L14c2:
  0014c2:  7e 0a                moveq    #$a, d7
  0014c4:  4e ba fd 6a          jsr      $1230(pc)  ; -> GetA5
  0014c8:  20 40                movea.l  d0, a0
  0014ca:  20 10                move.l   (a0), d0
  0014cc:  90 bc 00 00 00 ca    sub.l    #$ca, d0
  0014d2:  20 40                movea.l  d0, a0
  0014d4:  48 68 00 ba          pea.l    $ba(a0)
  0014d8:  70 00                moveq    #$0, d0
  0014da:  3f 00                move.w   d0, -(a7)
  0014dc:  4e ba 0c 2c          jsr      $210a(pc)  ; -> s7_sub_9a88
  0014e0:  36 bc 00 03          move.w   #$3, (a3)
  0014e4:  60 1c                bra.b    $1502  ; -> L1502
L14e6:
  0014e6:  7e 08                moveq    #$8, d7
  0014e8:  36 bc 00 03          move.w   #$3, (a3)
  0014ec:  60 14                bra.b    $1502  ; -> L1502
L14ee:
  0014ee:  4e ba fd 40          jsr      $1230(pc)  ; -> GetA5
  0014f2:  20 40                movea.l  d0, a0
  0014f4:  20 50                movea.l  (a0), a0
  0014f6:  20 50                movea.l  (a0), a0
  0014f8:  30 28 00 48          move.w   $48(a0), d0
  0014fc:  48 c0                ext.l    d0
  0014fe:  7e f7                moveq    #$f7, d7
  001500:  ce 80                and.l    d0, d7
L1502:
  001502:  10 38 09 38          move.b   $938.w, d0
  001506:  49 c0                extb.l   d0
  001508:  6d 1a                blt.b    $1524  ; -> L1524
  00150a:  48 c7                ext.l    d7
  00150c:  70 0a                moveq    #$a, d0
  00150e:  b0 87                cmp.l    d7, d0
  001510:  66 02                bne.b    $1514  ; -> L1514
  001512:  7e 3a                moveq    #$3a, d7
L1514:
  001514:  48 c7                ext.l    d7
  001516:  70 02                moveq    #$2, d0
  001518:  b0 87                cmp.l    d7, d0
  00151a:  66 02                bne.b    $151e  ; -> L151e
  00151c:  7e 32                moveq    #$32, d7
L151e:
  00151e:  00 38 00 80 09 38    ori.b    #$80, $938.w
L1524:
  001524:  38 87                move.w   d7, (a4)
  001526:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  00152c:  4e 5e                unlk     a6
  00152e:  4e 75                rts
* s7_sub_8f04  -  System 7 $8F04 (similar code, r=0.82).
s7_sub_8f04:
  001530:  4e 56 ff c4          link.w   a6, #$ffc4
  001534:  48 e7 07 18          movem.l  d5-d7/a3-a4, -(a7)
  001538:  2c 2e 00 0c          move.l   $c(a6), d6
  00153c:  47 ee ff c8          lea.l    -$38(a6), a3
  001540:  4a 86                tst.l    d6
  001542:  66 06                bne.b    $154a  ; -> L154a
  001544:  70 00                moveq    #$0, d0
  001546:  60 00 01 f4          bra.w    $173c  ; -> L173c
L154a:
  00154a:  20 6e 00 08          movea.l  $8(a6), a0
  00154e:  30 28 00 06          move.w   $6(a0), d0
  001552:  48 c0                ext.l    d0
  001554:  6c 00 01 a0          bge.w    $16f6  ; -> L16f6
  001558:  20 06                move.l   d6, d0
  00155a:  53 80                subq.l   #$1, d0
  00155c:  6b 34                bmi.b    $1592  ; -> L1592
  00155e:  0c 80 00 00 00 02    cmpi.l   #$2, d0
  001564:  6e 2c                bgt.b    $1592  ; -> L1592
  001566:  d0 80                add.l    d0, d0
  001568:  30 3b 08 06          move.w   $1570(pc, d0.l), d0
  00156c:  4e fb 00 00          jmp      $156e(pc,d0.w)
  001570:  00 08                dc.w     $0008    ; [0] -> L1576
  001572:  00 12                dc.w     $0012    ; [1] -> L1580
  001574:  00 1c                dc.w     $001C    ; [2] -> L158a
L1576:
  001576:  20 6e 00 08          movea.l  $8(a6), a0
  00157a:  28 68 00 3a          movea.l  $3a(a0), a4
  00157e:  60 12                bra.b    $1592  ; -> L1592
L1580:
  001580:  20 6e 00 08          movea.l  $8(a6), a0
  001584:  28 68 00 20          movea.l  $20(a0), a4
  001588:  60 08                bra.b    $1592  ; -> L1592
L158a:
  00158a:  20 6e 00 08          movea.l  $8(a6), a0
  00158e:  28 68 00 3e          movea.l  $3e(a0), a4
L1592:
  001592:  2d 54 ff c4          move.l   (a4), -$3c(a6)
  001596:  20 6e ff c4          movea.l  -$3c(a6), a0
  00159a:  30 10                move.w   (a0), d0
  00159c:  48 c0                ext.l    d0
  00159e:  2e 00                move.l   d0, d7
  0015a0:  66 12                bne.b    $15b4  ; -> L15b4
  0015a2:  20 6e ff c4          movea.l  -$3c(a6), a0
  0015a6:  20 68 00 06          movea.l  $6(a0), a0
  0015aa:  22 6e 00 10          movea.l  $10(a6), a1
  0015ae:  22 90                move.l   (a0), (a1)
  0015b0:  60 00 01 86          bra.w    $1738  ; -> L1738
L15b4:
  0015b4:  70 02                moveq    #$2, d0
  0015b6:  b0 87                cmp.l    d7, d0
  0015b8:  66 1e                bne.b    $15d8  ; -> L15d8
  0015ba:  20 6e ff c4          movea.l  -$3c(a6), a0
  0015be:  20 68 00 02          movea.l  $2(a0), a0
  0015c2:  20 50                movea.l  (a0), a0
  0015c4:  20 68 00 2a          movea.l  $2a(a0), a0
  0015c8:  20 50                movea.l  (a0), a0
  0015ca:  41 e8 00 2a          lea.l    $2a(a0), a0
  0015ce:  22 6e 00 10          movea.l  $10(a6), a1
  0015d2:  22 88                move.l   a0, (a1)
  0015d4:  60 00 01 62          bra.w    $1738  ; -> L1738
L15d8:
  0015d8:  20 78 08 88          movea.l  $888.w, a0
  0015dc:  20 50                movea.l  (a0), a0
  0015de:  20 50                movea.l  (a0), a0
  0015e0:  20 68 02 14          movea.l  $214(a0), a0
  0015e4:  2d 50 ff fc          move.l   (a0), -$4(a6)
  0015e8:  20 6e ff fc          movea.l  -$4(a6), a0
  0015ec:  30 28 01 80          move.w   $180(a0), d0
  0015f0:  48 c0                ext.l    d0
  0015f2:  2a 00                move.l   d0, d5
  0015f4:  46 85                not.l    d5
  0015f6:  20 6e ff c4          movea.l  -$3c(a6), a0
  0015fa:  20 68 00 02          movea.l  $2(a0), a0
  0015fe:  2d 50 ff f0          move.l   (a0), -$10(a6)
  001602:  20 6e ff f0          movea.l  -$10(a6), a0
  001606:  2d 68 00 2a ff f4    move.l   $2a(a0), -$c(a6)
  00160c:  20 6e ff c4          movea.l  -$3c(a6), a0
  001610:  48 c5                ext.l    d5
  001612:  30 28 00 0e          move.w   $e(a0), d0
  001616:  48 c0                ext.l    d0
  001618:  ba 80                cmp.l    d0, d5
  00161a:  66 1c                bne.b    $1638  ; -> L1638
  00161c:  2f 0c                move.l   a4, -(a7)
  00161e:  20 6e ff fc          movea.l  -$4(a6), a0
  001622:  20 68 01 82          movea.l  $182(a0), a0
  001626:  48 68 00 78          pea.l    $78(a0)
  00162a:  4e ba 33 02          jsr      $492e(pc)  ; -> s7_sub_87cc
  00162e:  72 00                moveq    #$0, d1
  001630:  12 00                move.b   d0, d1
  001632:  50 8f                addq.l   #$8, a7
  001634:  66 00 00 8c          bne.w    $16c2  ; -> L16c2
L1638:
  001638:  20 6e 00 10          movea.l  $10(a6), a0
  00163c:  b9 d0                cmpa.l   (a0), a4
  00163e:  66 16                bne.b    $1656  ; -> L1656
  001640:  70 01                moveq    #$1, d0
  001642:  2f 00                move.l   d0, -(a7)
  001644:  72 00                moveq    #$0, d1
  001646:  2f 01                move.l   d1, -(a7)
  001648:  2f 01                move.l   d1, -(a7)
  00164a:  70 38                moveq    #$38, d0
  00164c:  2f 00                move.l   d0, -(a7)
  00164e:  4e ba 4b d4          jsr      $6224(pc)  ; -> EngineDispatch
  001652:  4f ef 00 10          lea.l    $10(a7), a7
L1656:
  001656:  26 8c                move.l   a4, (a3)
  001658:  27 47 00 04          move.l   d7, $4(a3)
  00165c:  27 6e ff f0 00 08    move.l   -$10(a6), $8(a3)
  001662:  20 6e ff c4          movea.l  -$3c(a6), a0
  001666:  20 68 00 06          movea.l  $6(a0), a0
  00166a:  27 50 00 0c          move.l   (a0), $c(a3)
  00166e:  4a ae ff f4          tst.l    -$c(a6)
  001672:  66 0c                bne.b    $1680  ; -> L1680
  001674:  70 00                moveq    #$0, d0
  001676:  27 40 00 10          move.l   d0, $10(a3)
  00167a:  27 40 00 14          move.l   d0, $14(a3)
  00167e:  60 1c                bra.b    $169c  ; -> L169c
L1680:
  001680:  20 6e ff f4          movea.l  -$c(a6), a0
  001684:  2d 50 ff f8          move.l   (a0), -$8(a6)
  001688:  27 6e ff f8 00 10    move.l   -$8(a6), $10(a3)
  00168e:  20 6e ff f8          movea.l  -$8(a6), a0
  001692:  30 28 00 06          move.w   $6(a0), d0
  001696:  48 c0                ext.l    d0
  001698:  27 40 00 14          move.l   d0, $14(a3)
L169c:
  00169c:  70 01                moveq    #$1, d0
  00169e:  2f 00                move.l   d0, -(a7)
  0016a0:  72 06                moveq    #$6, d1
  0016a2:  2f 01                move.l   d1, -(a7)
  0016a4:  2f 0b                move.l   a3, -(a7)
  0016a6:  70 0c                moveq    #$c, d0
  0016a8:  2f 00                move.l   d0, -(a7)
  0016aa:  4e ba 4b 78          jsr      $6224(pc)  ; -> EngineDispatch
  0016ae:  4a 80                tst.l    d0
  0016b0:  4f ef 00 10          lea.l    $10(a7), a7
  0016b4:  66 06                bne.b    $16bc  ; -> L16bc
  0016b6:  70 ff                moveq    #$ff, d0
  0016b8:  60 00 00 82          bra.w    $173c  ; -> L173c
L16bc:
  0016bc:  20 54                movea.l  (a4), a0
  0016be:  31 45 00 0e          move.w   d5, $e(a0)
L16c2:
  0016c2:  70 00                moveq    #$0, d0
  0016c4:  4a ae ff f4          tst.l    -$c(a6)
  0016c8:  67 18                beq.b    $16e2  ; -> L16e2
  0016ca:  20 6e ff f4          movea.l  -$c(a6), a0
  0016ce:  20 50                movea.l  (a0), a0
  0016d0:  32 28 00 04          move.w   $4(a0), d1
  0016d4:  48 c1                ext.l    d1
  0016d6:  24 3c 00 00 40 00    move.l   #$4000, d2
  0016dc:  c4 81                and.l    d1, d2
  0016de:  67 02                beq.b    $16e2  ; -> L16e2
  0016e0:  70 01                moveq    #$1, d0
L16e2:
  0016e2:  4a 80                tst.l    d0
  0016e4:  67 04                beq.b    $16ea  ; -> L16ea
  0016e6:  70 03                moveq    #$3, d0
  0016e8:  60 02                bra.b    $16ec  ; -> L16ec
L16ea:
  0016ea:  70 01                moveq    #$1, d0
L16ec:
  0016ec:  2e 00                move.l   d0, d7
  0016ee:  20 6e 00 10          movea.l  $10(a6), a0
  0016f2:  20 8c                move.l   a4, (a0)
  0016f4:  60 42                bra.b    $1738  ; -> L1738
L16f6:
  0016f6:  20 06                move.l   d6, d0
  0016f8:  53 80                subq.l   #$1, d0
  0016fa:  6b 34                bmi.b    $1730  ; -> L1730
  0016fc:  0c 80 00 00 00 02    cmpi.l   #$2, d0
  001702:  6e 2c                bgt.b    $1730  ; -> L1730
  001704:  d0 80                add.l    d0, d0
  001706:  30 3b 08 06          move.w   $170e(pc, d0.l), d0
  00170a:  4e fb 00 00          jmp      $170c(pc,d0.w)
  00170e:  00 08                dc.w     $0008    ; [0] -> L1714
  001710:  00 12                dc.w     $0012    ; [1] -> L171e
  001712:  00 1c                dc.w     $001C    ; [2] -> L1728
L1714:
  001714:  20 6e 00 08          movea.l  $8(a6), a0
  001718:  47 e8 00 3a          lea.l    $3a(a0), a3
  00171c:  60 12                bra.b    $1730  ; -> L1730
L171e:
  00171e:  20 6e 00 08          movea.l  $8(a6), a0
  001722:  47 e8 00 20          lea.l    $20(a0), a3
  001726:  60 08                bra.b    $1730  ; -> L1730
L1728:
  001728:  20 6e 00 08          movea.l  $8(a6), a0
  00172c:  47 e8 00 28          lea.l    $28(a0), a3
L1730:
  001730:  7e 00                moveq    #$0, d7
  001732:  20 6e 00 10          movea.l  $10(a6), a0
  001736:  20 8b                move.l   a3, (a0)
L1738:
  001738:  20 07                move.l   d7, d0
  00173a:  52 80                addq.l   #$1, d0
L173c:
  00173c:  4c ee 18 e0 ff b0    movem.l  -$50(a6), d5-d7/a3-a4
  001742:  4e 5e                unlk     a6
  001744:  4e 75                rts
* s7_sub_90ee  -  System 7 $90EE (checked by hand, r=0.67).
s7_sub_90ee:
  001746:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00174a:  28 6f 00 0c          movea.l  $c(a7), a4
  00174e:  20 2f 00 10          move.l   $10(a7), d0
  001752:  53 80                subq.l   #$1, d0
  001754:  6b 30                bmi.b    $1786  ; -> L1786
  001756:  0c 80 00 00 00 02    cmpi.l   #$2, d0
  00175c:  6e 28                bgt.b    $1786  ; -> L1786
  00175e:  d0 80                add.l    d0, d0
  001760:  30 3b 08 06          move.w   $1768(pc, d0.l), d0
  001764:  4e fb 00 00          jmp      $1766(pc,d0.w)
  001768:  00 08                dc.w     $0008    ; [0] -> L176e
  00176a:  00 10                dc.w     $0010    ; [1] -> L1776
  00176c:  00 18                dc.w     $0018    ; [2] -> L177e
L176e:
  00176e:  20 6c 00 3a          movea.l  $3a(a4), a0
  001772:  26 50                movea.l  (a0), a3
  001774:  60 14                bra.b    $178a  ; -> L178a
L1776:
  001776:  20 6c 00 20          movea.l  $20(a4), a0
  00177a:  26 50                movea.l  (a0), a3
  00177c:  60 0c                bra.b    $178a  ; -> L178a
L177e:
  00177e:  20 6c 00 3e          movea.l  $3e(a4), a0
  001782:  26 50                movea.l  (a0), a3
  001784:  60 04                bra.b    $178a  ; -> L178a
L1786:
  001786:  70 01                moveq    #$1, d0
  001788:  60 1a                bra.b    $17a4  ; -> L17a4
L178a:
  00178a:  70 01                moveq    #$1, d0
  00178c:  32 13                move.w   (a3), d1
  00178e:  48 c1                ext.l    d1
  001790:  74 01                moveq    #$1, d2
  001792:  c4 81                and.l    d1, d2
  001794:  67 0e                beq.b    $17a4  ; -> L17a4
  001796:  32 2b 00 0e          move.w   $e(a3), d1
  00179a:  48 c1                ext.l    d1
  00179c:  74 ff                moveq    #$ff, d2
  00179e:  b4 81                cmp.l    d1, d2
  0017a0:  66 02                bne.b    $17a4  ; -> L17a4
  0017a2:  70 00                moveq    #$0, d0
L17a4:
  0017a4:  4c df 18 00          movem.l  (a7)+, a3-a4
  0017a8:  4e 75                rts
* s7_sub_9146  -  System 7 $9146 (identical code).
s7_sub_9146:
  0017aa:  4e 56 00 00          link.w   a6, #$0
  0017ae:  48 e7 00 18          movem.l  a3-a4, -(a7)
  0017b2:  28 6e 00 08          movea.l  $8(a6), a4
  0017b6:  59 8f                subq.l   #$4, a7
  0017b8:  a8 d8                dc.w     $a8d8
  0017ba:  26 5f                movea.l  (a7)+, a3
  0017bc:  2f 0c                move.l   a4, -(a7)
  0017be:  2f 0b                move.l   a3, -(a7)
  0017c0:  a8 dc                dc.w     $a8dc
  0017c2:  2f 0b                move.l   a3, -(a7)
  0017c4:  3f 2e 00 0e          move.w   $e(a6), -(a7)
  0017c8:  3f 2e 00 12          move.w   $12(a6), -(a7)
  0017cc:  a8 e1                dc.w     $a8e1
  0017ce:  2f 0c                move.l   a4, -(a7)
  0017d0:  2f 0b                move.l   a3, -(a7)
  0017d2:  2f 0b                move.l   a3, -(a7)
  0017d4:  a8 e6                dc.w     $a8e6
  0017d6:  20 0b                move.l   a3, d0
  0017d8:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  0017de:  4e 5e                unlk     a6
  0017e0:  4e 75                rts
* s7_sub_917e  -  System 7 $917E (similar code, r=0.83).
s7_sub_917e:
  0017e2:  2f 07                move.l   d7, -(a7)
  0017e4:  2e 2f 00 08          move.l   $8(a7), d7
  0017e8:  70 01                moveq    #$1, d0
  0017ea:  c0 87                and.l    d7, d0
  0017ec:  66 06                bne.b    $17f4  ; -> L17f4
  0017ee:  00 87 00 00 01 c0    ori.l    #$1c0, d7
L17f4:
  0017f4:  20 78 08 b0          movea.l  $8b0.w, a0
  0017f8:  20 07                move.l   d7, d0
  0017fa:  ec 80                asr.l    #$6, d0
  0017fc:  e7 80                asl.l    #$3, d0
  0017fe:  41 f0 08 02          lea.l    $2(a0, d0.l), a0
  001802:  20 08                move.l   a0, d0
  001804:  2e 1f                move.l   (a7)+, d7
  001806:  4e 75                rts
* s7_sub_91aa  -  System 7 $91AA (similar code, r=0.88).
s7_sub_91aa:
  001808:  4e 56 ff ec          link.w   a6, #$ffec
  00180c:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  001810:  1c 2e 00 17          move.b   $17(a6), d6
  001814:  1e 2e 00 0f          move.b   $f(a6), d7
  001818:  28 6e 00 10          movea.l  $10(a6), a4
  00181c:  26 6e 00 08          movea.l  $8(a6), a3
  001820:  70 00                moveq    #$0, d0
  001822:  10 07                move.b   d7, d0
  001824:  66 22                bne.b    $1848  ; -> L1848
  001826:  70 00                moveq    #$0, d0
  001828:  10 06                move.b   d6, d0
  00182a:  66 1c                bne.b    $1848  ; -> L1848
  00182c:  70 00                moveq    #$0, d0
  00182e:  22 13                move.l   (a3), d1
  001830:  b2 94                cmp.l    (a4), d1
  001832:  66 00 00 aa          bne.w    $18de  ; -> L18de
  001836:  22 2b 00 04          move.l   $4(a3), d1
  00183a:  b2 ac 00 04          cmp.l    $4(a4), d1
  00183e:  66 00 00 9e          bne.w    $18de  ; -> L18de
  001842:  70 01                moveq    #$1, d0
  001844:  60 00 00 98          bra.w    $18de  ; -> L18de
L1848:
  001848:  4a 07                tst.b    d7
  00184a:  67 1a                beq.b    $1866  ; -> L1866
  00184c:  4a 06                tst.b    d6
  00184e:  67 16                beq.b    $1866  ; -> L1866
  001850:  2d 53 ff f8          move.l   (a3), -$8(a6)
  001854:  2d 54 ff fc          move.l   (a4), -$4(a6)
  001858:  20 2e ff f8          move.l   -$8(a6), d0
  00185c:  b0 ae ff fc          cmp.l    -$4(a6), d0
  001860:  57 c0                seq.b    d0
  001862:  44 00                neg.b    d0
  001864:  60 78                bra.b    $18de  ; -> L18de
L1866:
  001866:  4a 07                tst.b    d7
  001868:  67 24                beq.b    $188e  ; -> L188e
  00186a:  2d 53 ff f8          move.l   (a3), -$8(a6)
  00186e:  66 04                bne.b    $1874  ; -> L1874
  001870:  70 00                moveq    #$0, d0
  001872:  60 6a                bra.b    $18de  ; -> L18de
L1874:
  001874:  20 6e ff f8          movea.l  -$8(a6), a0
  001878:  2d 50 ff ec          move.l   (a0), -$14(a6)
  00187c:  20 6e ff ec          movea.l  -$14(a6), a0
  001880:  20 68 00 06          movea.l  $6(a0), a0
  001884:  2d 50 ff f4          move.l   (a0), -$c(a6)
  001888:  2d 4c ff f0          move.l   a4, -$10(a6)
  00188c:  60 22                bra.b    $18b0  ; -> L18b0
L188e:
  00188e:  2d 54 ff fc          move.l   (a4), -$4(a6)
  001892:  66 04                bne.b    $1898  ; -> L1898
  001894:  70 00                moveq    #$0, d0
  001896:  60 46                bra.b    $18de  ; -> L18de
L1898:
  001898:  20 6e ff fc          movea.l  -$4(a6), a0
  00189c:  2d 50 ff ec          move.l   (a0), -$14(a6)
  0018a0:  20 6e ff ec          movea.l  -$14(a6), a0
  0018a4:  20 68 00 06          movea.l  $6(a0), a0
  0018a8:  2d 50 ff f4          move.l   (a0), -$c(a6)
  0018ac:  2d 4b ff f0          move.l   a3, -$10(a6)
L18b0:
  0018b0:  70 00                moveq    #$0, d0
  0018b2:  20 6e ff ec          movea.l  -$14(a6), a0
  0018b6:  32 10                move.w   (a0), d1
  0018b8:  48 c1                ext.l    d1
  0018ba:  66 22                bne.b    $18de  ; -> L18de
  0018bc:  20 6e ff f0          movea.l  -$10(a6), a0
  0018c0:  22 6e ff f4          movea.l  -$c(a6), a1
  0018c4:  22 10                move.l   (a0), d1
  0018c6:  b2 91                cmp.l    (a1), d1
  0018c8:  66 14                bne.b    $18de  ; -> L18de
  0018ca:  20 6e ff f0          movea.l  -$10(a6), a0
  0018ce:  22 6e ff f4          movea.l  -$c(a6), a1
  0018d2:  22 28 00 04          move.l   $4(a0), d1
  0018d6:  b2 a9 00 04          cmp.l    $4(a1), d1
  0018da:  66 02                bne.b    $18de  ; -> L18de
  0018dc:  70 01                moveq    #$1, d0
L18de:
  0018de:  4c ee 18 c0 ff dc    movem.l  -$24(a6), d6-d7/a3-a4
  0018e4:  4e 5e                unlk     a6
  0018e6:  4e 75                rts
* GA_TrapAB9A  -  System 7 $9278 (same trap slot $1C68, code r=0.94).
* S7: Patch #10 replaces trap $AB9A; card commands: $2A
GA_TrapAB9A:
  0018e8:  4e 56 ff e0          link.w   a6, #$ffe0
  0018ec:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  0018f0:  70 00                moveq    #$0, d0
  0018f2:  2f 00                move.l   d0, -(a7)
  0018f4:  4e ba 6f 2c          jsr      $8822(pc)  ; -> s7_sub_6f1c
  0018f8:  26 40                movea.l  d0, a3
  0018fa:  4e ba f9 34          jsr      $1230(pc)  ; -> GetA5
  0018fe:  20 40                movea.l  d0, a0
  001900:  20 50                movea.l  (a0), a0
  001902:  b7 d0                cmpa.l   (a0), a3
  001904:  58 8f                addq.l   #$4, a7
  001906:  66 00 00 fc          bne.w    $1a04  ; -> L1a04
  00190a:  7e 00                moveq    #$0, d7
  00190c:  30 2b 00 06          move.w   $6(a3), d0
  001910:  48 c0                ext.l    d0
  001912:  6d 00 00 a0          blt.w    $19b4  ; -> L19b4
  001916:  41 eb 00 3a          lea.l    $3a(a3), a0
  00191a:  2d 48 ff e0          move.l   a0, -$20(a6)
  00191e:  2d 50 ff e8          move.l   (a0), -$18(a6)
  001922:  20 6e ff e0          movea.l  -$20(a6), a0
  001926:  2d 68 00 04 ff ec    move.l   $4(a0), -$14(a6)
  00192c:  41 eb 00 20          lea.l    $20(a3), a0
  001930:  2d 48 ff e4          move.l   a0, -$1c(a6)
  001934:  2d 50 ff f0          move.l   (a0), -$10(a6)
  001938:  20 6e ff e4          movea.l  -$1c(a6), a0
  00193c:  2d 68 00 04 ff f4    move.l   $4(a0), -$c(a6)
  001942:  49 eb 00 28          lea.l    $28(a3), a4
  001946:  28 14                move.l   (a4), d4
  001948:  2a 2c 00 04          move.l   $4(a4), d5
  00194c:  55 8f                subq.l   #$2, a7
  00194e:  2f 2e 00 08          move.l   $8(a6), -(a7)
  001952:  48 78 1c 68          pea.l    $1c68.w
  001956:  4e ba 6d 44          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00195a:  58 8f                addq.l   #$4, a7
  00195c:  2f 00                move.l   d0, -(a7)
  00195e:  20 5f                movea.l  (a7)+, a0
  001960:  4e 90                jsr      (a0)
  001962:  1c 1f                move.b   (a7)+, d6
  001964:  20 2e ff e0          move.l   -$20(a6), d0
  001968:  58 ae ff e0          addq.l   #$4, -$20(a6)
  00196c:  20 40                movea.l  d0, a0
  00196e:  20 10                move.l   (a0), d0
  001970:  b0 ae ff e8          cmp.l    -$18(a6), d0
  001974:  66 0c                bne.b    $1982  ; -> L1982
  001976:  20 6e ff e0          movea.l  -$20(a6), a0
  00197a:  20 10                move.l   (a0), d0
  00197c:  b0 ae ff ec          cmp.l    -$14(a6), d0
  001980:  67 04                beq.b    $1986  ; -> L1986
L1982:
  001982:  7e 01                moveq    #$1, d7
  001984:  60 52                bra.b    $19d8  ; -> L19d8
L1986:
  001986:  20 2e ff e4          move.l   -$1c(a6), d0
  00198a:  58 ae ff e4          addq.l   #$4, -$1c(a6)
  00198e:  20 40                movea.l  d0, a0
  001990:  20 10                move.l   (a0), d0
  001992:  b0 ae ff f0          cmp.l    -$10(a6), d0
  001996:  66 0c                bne.b    $19a4  ; -> L19a4
  001998:  20 6e ff e4          movea.l  -$1c(a6), a0
  00199c:  20 10                move.l   (a0), d0
  00199e:  b0 ae ff f4          cmp.l    -$c(a6), d0
  0019a2:  67 04                beq.b    $19a8  ; -> L19a8
L19a4:
  0019a4:  7e 02                moveq    #$2, d7
  0019a6:  60 30                bra.b    $19d8  ; -> L19d8
L19a8:
  0019a8:  b8 9c                cmp.l    (a4)+, d4
  0019aa:  66 04                bne.b    $19b0  ; -> L19b0
  0019ac:  ba 94                cmp.l    (a4), d5
  0019ae:  67 28                beq.b    $19d8  ; -> L19d8
L19b0:
  0019b0:  7e 03                moveq    #$3, d7
  0019b2:  60 24                bra.b    $19d8  ; -> L19d8
L19b4:
  0019b4:  28 6b 00 3e          movea.l  $3e(a3), a4
  0019b8:  55 8f                subq.l   #$2, a7
  0019ba:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0019be:  48 78 1c 68          pea.l    $1c68.w
  0019c2:  4e ba 6c d8          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0019c6:  58 8f                addq.l   #$4, a7
  0019c8:  2f 00                move.l   d0, -(a7)
  0019ca:  20 5f                movea.l  (a7)+, a0
  0019cc:  4e 90                jsr      (a0)
  0019ce:  1c 1f                move.b   (a7)+, d6
  0019d0:  b9 eb 00 3e          cmpa.l   $3e(a3), a4
  0019d4:  67 02                beq.b    $19d8  ; -> L19d8
  0019d6:  7e 03                moveq    #$3, d7
L19d8:
  0019d8:  4a 87                tst.l    d7
  0019da:  67 22                beq.b    $19fe  ; -> L19fe
  0019dc:  70 00                moveq    #$0, d0
  0019de:  2d 40 ff f8          move.l   d0, -$8(a6)
  0019e2:  2d 47 ff fc          move.l   d7, -$4(a6)
  0019e6:  72 01                moveq    #$1, d1
  0019e8:  2f 01                move.l   d1, -(a7)
  0019ea:  70 02                moveq    #$2, d0
  0019ec:  2f 00                move.l   d0, -(a7)
  0019ee:  48 6e ff f8          pea.l    -$8(a6)
  0019f2:  70 2a                moveq    #$2a, d0
  0019f4:  2f 00                move.l   d0, -(a7)
  0019f6:  4e ba 48 2c          jsr      $6224(pc)  ; -> EngineDispatch
  0019fa:  4f ef 00 10          lea.l    $10(a7), a7
L19fe:
  0019fe:  1d 46 00 0c          move.b   d6, $c(a6)
  001a02:  60 1a                bra.b    $1a1e  ; -> L1a1e
L1a04:
  001a04:  55 8f                subq.l   #$2, a7
  001a06:  2f 2e 00 08          move.l   $8(a6), -(a7)
  001a0a:  48 78 1c 68          pea.l    $1c68.w
  001a0e:  4e ba 6c 8c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001a12:  58 8f                addq.l   #$4, a7
  001a14:  2f 00                move.l   d0, -(a7)
  001a16:  20 5f                movea.l  (a7)+, a0
  001a18:  4e 90                jsr      (a0)
  001a1a:  1d 5f 00 0c          move.b   (a7)+, $c(a6)
L1a1e:
  001a1e:  4c ee 18 f0 ff c8    movem.l  -$38(a6), d4-d7/a3-a4
  001a24:  4e 5e                unlk     a6
  001a26:  4e 74 00 04          rtd      #$4
* GA_SetPalette  -  System 7 $93B8 (same trap slot $1854, code r=0.91).
* S7: Patch #90 replaces _SetPalette ($AA95); card commands: $26
GA_SetPalette:
  001a2a:  4e 56 00 00          link.w   a6, #$0
  001a2e:  48 e7 00 18          movem.l  a3-a4, -(a7)
  001a32:  28 6e 00 0a          movea.l  $a(a6), a4
  001a36:  26 6e 00 0e          movea.l  $e(a6), a3
  001a3a:  70 01                moveq    #$1, d0
  001a3c:  2f 00                move.l   d0, -(a7)
  001a3e:  72 00                moveq    #$0, d1
  001a40:  2f 01                move.l   d1, -(a7)
  001a42:  2f 01                move.l   d1, -(a7)
  001a44:  70 26                moveq    #$26, d0
  001a46:  2f 00                move.l   d0, -(a7)
  001a48:  4e ba 47 da          jsr      $6224(pc)  ; -> EngineDispatch
  001a4c:  2f 0b                move.l   a3, -(a7)
  001a4e:  2f 0c                move.l   a4, -(a7)
  001a50:  3f 2e 00 08          move.w   $8(a6), -(a7)
  001a54:  48 78 18 54          pea.l    $1854.w
  001a58:  4e ba 6c 42          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001a5c:  58 8f                addq.l   #$4, a7
  001a5e:  2f 00                move.l   d0, -(a7)
  001a60:  20 5f                movea.l  (a7)+, a0
  001a62:  4e 90                jsr      (a0)
  001a64:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  001a6a:  4e 5e                unlk     a6
  001a6c:  4e 74 00 0a          rtd      #$a
* GA_ActivatePalette  -  System 7 $93F4 (same trap slot $1850, code r=0.84).
* S7: Patch #89 replaces _ActivatePalette ($AA94); card commands: $26
GA_ActivatePalette:
  001a70:  2f 0b                move.l   a3, -(a7)
  001a72:  26 6f 00 08          movea.l  $8(a7), a3
  001a76:  70 01                moveq    #$1, d0
  001a78:  2f 00                move.l   d0, -(a7)
  001a7a:  72 00                moveq    #$0, d1
  001a7c:  2f 01                move.l   d1, -(a7)
  001a7e:  2f 01                move.l   d1, -(a7)
  001a80:  70 26                moveq    #$26, d0
  001a82:  2f 00                move.l   d0, -(a7)
  001a84:  4e ba 47 9e          jsr      $6224(pc)  ; -> EngineDispatch
  001a88:  2f 0b                move.l   a3, -(a7)
  001a8a:  48 78 18 50          pea.l    $1850.w
  001a8e:  4e ba 6c 0c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001a92:  58 8f                addq.l   #$4, a7
  001a94:  2f 00                move.l   d0, -(a7)
  001a96:  20 5f                movea.l  (a7)+, a0
  001a98:  4e 90                jsr      (a0)
  001a9a:  4f ef 00 10          lea.l    $10(a7), a7
  001a9e:  26 5f                movea.l  (a7)+, a3
  001aa0:  4e 74 00 04          rtd      #$4
* GA_Palette2CTab  -  System 7 $9428 (same trap slot $1880, code r=0.83).
* S7: Patch #91 replaces _Palette2CTab ($AAA0); card commands: $26
GA_Palette2CTab:
  001aa4:  48 e7 00 18          movem.l  a3-a4, -(a7)
  001aa8:  28 6f 00 0c          movea.l  $c(a7), a4
  001aac:  26 6f 00 10          movea.l  $10(a7), a3
  001ab0:  70 01                moveq    #$1, d0
  001ab2:  2f 00                move.l   d0, -(a7)
  001ab4:  72 00                moveq    #$0, d1
  001ab6:  2f 01                move.l   d1, -(a7)
  001ab8:  2f 01                move.l   d1, -(a7)
  001aba:  70 26                moveq    #$26, d0
  001abc:  2f 00                move.l   d0, -(a7)
  001abe:  4e ba 47 64          jsr      $6224(pc)  ; -> EngineDispatch
  001ac2:  2f 0b                move.l   a3, -(a7)
  001ac4:  2f 0c                move.l   a4, -(a7)
  001ac6:  48 78 18 80          pea.l    $1880.w
  001aca:  4e ba 6b d0          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001ace:  58 8f                addq.l   #$4, a7
  001ad0:  2f 00                move.l   d0, -(a7)
  001ad2:  20 5f                movea.l  (a7)+, a0
  001ad4:  4e 90                jsr      (a0)
  001ad6:  4f ef 00 10          lea.l    $10(a7), a7
  001ada:  4c df 18 00          movem.l  (a7)+, a3-a4
  001ade:  4e 74 00 08          rtd      #$8
* GA_MakeITable  -  System 7 $9460 (same trap slot $16E4, code r=0.93).
* S7: Patch #92 replaces _MakeITable ($AA39); card commands: $1B
GA_MakeITable:
  001ae2:  4e 56 ff fc          link.w   a6, #$fffc
  001ae6:  48 e7 00 18          movem.l  a3-a4, -(a7)
  001aea:  28 6e 00 0e          movea.l  $e(a6), a4
  001aee:  26 6e 00 0a          movea.l  $a(a6), a3
  001af2:  2f 0c                move.l   a4, -(a7)
  001af4:  2f 0b                move.l   a3, -(a7)
  001af6:  3f 2e 00 08          move.w   $8(a6), -(a7)
  001afa:  48 78 16 e4          pea.l    $16e4.w
  001afe:  4e ba 6b 9c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001b02:  58 8f                addq.l   #$4, a7
  001b04:  2f 00                move.l   d0, -(a7)
  001b06:  20 5f                movea.l  (a7)+, a0
  001b08:  4e 90                jsr      (a0)
  001b0a:  20 78 08 88          movea.l  $888.w, a0
  001b0e:  4a a8 00 3c          tst.l    $3c(a0)
  001b12:  66 2a                bne.b    $1b3e  ; -> L1b3e
  001b14:  20 0b                move.l   a3, d0
  001b16:  66 0a                bne.b    $1b22  ; -> L1b22
  001b18:  20 78 0c c8          movea.l  $cc8.w, a0
  001b1c:  20 50                movea.l  (a0), a0
  001b1e:  26 68 00 06          movea.l  $6(a0), a3
L1b22:
  001b22:  20 53                movea.l  (a3), a0
  001b24:  2d 50 ff fc          move.l   (a0), -$4(a6)
  001b28:  70 01                moveq    #$1, d0
  001b2a:  2f 00                move.l   d0, -(a7)
  001b2c:  2f 00                move.l   d0, -(a7)
  001b2e:  48 6e ff fc          pea.l    -$4(a6)
  001b32:  72 1b                moveq    #$1b, d1
  001b34:  2f 01                move.l   d1, -(a7)
  001b36:  4e ba 46 ec          jsr      $6224(pc)  ; -> EngineDispatch
  001b3a:  4f ef 00 10          lea.l    $10(a7), a7
L1b3e:
  001b3e:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  001b44:  4e 5e                unlk     a6
  001b46:  4e 74 00 0a          rtd      #$a
* GA_SaveEntries  -  System 7 $94C6 (same trap slot $1724, code r=0.93).
* S7: Patch #84 replaces _SaveEntries ($AA49); card commands: $1A
GA_SaveEntries:
  001b4a:  4e 56 00 00          link.w   a6, #$0
  001b4e:  48 e7 00 18          movem.l  a3-a4, -(a7)
  001b52:  28 6e 00 08          movea.l  $8(a6), a4
  001b56:  26 6e 00 10          movea.l  $10(a6), a3
  001b5a:  2f 0b                move.l   a3, -(a7)
  001b5c:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  001b60:  2f 0c                move.l   a4, -(a7)
  001b62:  48 78 17 24          pea.l    $1724.w
  001b66:  4e ba 6b 34          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001b6a:  58 8f                addq.l   #$4, a7
  001b6c:  2f 00                move.l   d0, -(a7)
  001b6e:  20 5f                movea.l  (a7)+, a0
  001b70:  4e 90                jsr      (a0)
  001b72:  4a ae 00 0c          tst.l    $c(a6)
  001b76:  66 12                bne.b    $1b8a  ; -> L1b8a
  001b78:  20 78 0c c8          movea.l  $cc8.w, a0
  001b7c:  20 50                movea.l  (a0), a0
  001b7e:  20 68 00 16          movea.l  $16(a0), a0
  001b82:  20 50                movea.l  (a0), a0
  001b84:  2d 68 00 2a 00 0c    move.l   $2a(a0), $c(a6)
L1b8a:
  001b8a:  70 01                moveq    #$1, d0
  001b8c:  2f 00                move.l   d0, -(a7)
  001b8e:  2f 00                move.l   d0, -(a7)
  001b90:  48 6e 00 0c          pea.l    $c(a6)
  001b94:  72 1a                moveq    #$1a, d1
  001b96:  2f 01                move.l   d1, -(a7)
  001b98:  4e ba 46 8a          jsr      $6224(pc)  ; -> EngineDispatch
  001b9c:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  001ba2:  4e 5e                unlk     a6
  001ba4:  4e 74 00 0c          rtd      #$c
* GA_RestoreEntries  -  System 7 $951A (same trap slot $1728, code r=0.93).
* S7: Patch #85 replaces _RestoreEntries ($AA4A); card commands: $1A
GA_RestoreEntries:
  001ba8:  4e 56 00 00          link.w   a6, #$0
  001bac:  48 e7 00 18          movem.l  a3-a4, -(a7)
  001bb0:  28 6e 00 08          movea.l  $8(a6), a4
  001bb4:  26 6e 00 10          movea.l  $10(a6), a3
  001bb8:  2f 0b                move.l   a3, -(a7)
  001bba:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  001bbe:  2f 0c                move.l   a4, -(a7)
  001bc0:  48 78 17 28          pea.l    $1728.w
  001bc4:  4e ba 6a d6          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001bc8:  58 8f                addq.l   #$4, a7
  001bca:  2f 00                move.l   d0, -(a7)
  001bcc:  20 5f                movea.l  (a7)+, a0
  001bce:  4e 90                jsr      (a0)
  001bd0:  4a ae 00 0c          tst.l    $c(a6)
  001bd4:  66 12                bne.b    $1be8  ; -> L1be8
  001bd6:  20 78 0c c8          movea.l  $cc8.w, a0
  001bda:  20 50                movea.l  (a0), a0
  001bdc:  20 68 00 16          movea.l  $16(a0), a0
  001be0:  20 50                movea.l  (a0), a0
  001be2:  2d 68 00 2a 00 0c    move.l   $2a(a0), $c(a6)
L1be8:
  001be8:  70 01                moveq    #$1, d0
  001bea:  2f 00                move.l   d0, -(a7)
  001bec:  2f 00                move.l   d0, -(a7)
  001bee:  48 6e 00 0c          pea.l    $c(a6)
  001bf2:  72 1a                moveq    #$1a, d1
  001bf4:  2f 01                move.l   d1, -(a7)
  001bf6:  4e ba 46 2c          jsr      $6224(pc)  ; -> EngineDispatch
  001bfa:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  001c00:  4e 5e                unlk     a6
  001c02:  4e 74 00 0c          rtd      #$c
* GA_GetSubTable  -  System 7 $956E (same trap slot $16DC, code r=0.95).
* S7: Patch #86 replaces _GetSubTable ($AA37); card commands: $1A
GA_GetSubTable:
  001c06:  4e 56 00 00          link.w   a6, #$0
  001c0a:  2f 0b                move.l   a3, -(a7)
  001c0c:  26 6e 00 0e          movea.l  $e(a6), a3
  001c10:  2f 0b                move.l   a3, -(a7)
  001c12:  3f 2e 00 0c          move.w   $c(a6), -(a7)
  001c16:  2f 2e 00 08          move.l   $8(a6), -(a7)
  001c1a:  48 78 16 dc          pea.l    $16dc.w
  001c1e:  4e ba 6a 7c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001c22:  58 8f                addq.l   #$4, a7
  001c24:  2f 00                move.l   d0, -(a7)
  001c26:  20 5f                movea.l  (a7)+, a0
  001c28:  4e 90                jsr      (a0)
  001c2a:  4a ae 00 08          tst.l    $8(a6)
  001c2e:  66 12                bne.b    $1c42  ; -> L1c42
  001c30:  20 78 0c c8          movea.l  $cc8.w, a0
  001c34:  20 50                movea.l  (a0), a0
  001c36:  20 68 00 16          movea.l  $16(a0), a0
  001c3a:  20 50                movea.l  (a0), a0
  001c3c:  2d 68 00 2a 00 08    move.l   $2a(a0), $8(a6)
L1c42:
  001c42:  70 01                moveq    #$1, d0
  001c44:  2f 00                move.l   d0, -(a7)
  001c46:  2f 00                move.l   d0, -(a7)
  001c48:  48 6e 00 08          pea.l    $8(a6)
  001c4c:  72 1a                moveq    #$1a, d1
  001c4e:  2f 01                move.l   d1, -(a7)
  001c50:  4e ba 45 d2          jsr      $6224(pc)  ; -> EngineDispatch
  001c54:  26 6e ff fc          movea.l  -$4(a6), a3
  001c58:  4e 5e                unlk     a6
  001c5a:  4e 74 00 0a          rtd      #$a
* GA_SetEntries  -  System 7 $95C2 (same trap slot $16FC, code r=0.95).
* S7: Patch #77 replaces _SetEntries ($AA3F); card commands: $1A $29
GA_SetEntries:
  001c5e:  4e 56 ff fc          link.w   a6, #$fffc
  001c62:  2f 0b                move.l   a3, -(a7)
  001c64:  26 6e 00 08          movea.l  $8(a6), a3
  001c68:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  001c6c:  2f 0b                move.l   a3, -(a7)
  001c6e:  48 78 16 fc          pea.l    $16fc.w
  001c72:  4e ba 6a 28          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001c76:  58 8f                addq.l   #$4, a7
  001c78:  2f 00                move.l   d0, -(a7)
  001c7a:  20 5f                movea.l  (a7)+, a0
  001c7c:  4e 90                jsr      (a0)
  001c7e:  20 78 08 88          movea.l  $888.w, a0
  001c82:  20 50                movea.l  (a0), a0
  001c84:  20 50                movea.l  (a0), a0
  001c86:  20 68 02 14          movea.l  $214(a0), a0
  001c8a:  20 50                movea.l  (a0), a0
  001c8c:  2d 68 01 8e ff fc    move.l   $18e(a0), -$4(a6)
  001c92:  67 16                beq.b    $1caa  ; -> L1caa
  001c94:  70 01                moveq    #$1, d0
  001c96:  2f 00                move.l   d0, -(a7)
  001c98:  2f 00                move.l   d0, -(a7)
  001c9a:  48 6e ff fc          pea.l    -$4(a6)
  001c9e:  72 29                moveq    #$29, d1
  001ca0:  2f 01                move.l   d1, -(a7)
  001ca2:  4e ba 45 80          jsr      $6224(pc)  ; -> EngineDispatch
  001ca6:  4f ef 00 10          lea.l    $10(a7), a7
L1caa:
  001caa:  70 01                moveq    #$1, d0
  001cac:  2f 00                move.l   d0, -(a7)
  001cae:  2f 00                move.l   d0, -(a7)
  001cb0:  20 78 0c c8          movea.l  $cc8.w, a0
  001cb4:  20 50                movea.l  (a0), a0
  001cb6:  20 68 00 16          movea.l  $16(a0), a0
  001cba:  20 50                movea.l  (a0), a0
  001cbc:  48 68 00 2a          pea.l    $2a(a0)
  001cc0:  72 1a                moveq    #$1a, d1
  001cc2:  2f 01                move.l   d1, -(a7)
  001cc4:  4e ba 45 5e          jsr      $6224(pc)  ; -> EngineDispatch
  001cc8:  4f ef 00 10          lea.l    $10(a7), a7
  001ccc:  26 6e ff f8          movea.l  -$8(a6), a3
  001cd0:  4e 5e                unlk     a6
  001cd2:  4e 74 00 08          rtd      #$8
* GA_SetDeviceAttribute  -  System 7 $9634 (identical code).
* S7: Patch #73 replaces _SetDeviceAttribute ($AA2D); card commands: $26 $29
GA_SetDeviceAttribute:
  001cd6:  4e 56 00 00          link.w   a6, #$0
  001cda:  70 01                moveq    #$1, d0
  001cdc:  2f 00                move.l   d0, -(a7)
  001cde:  72 00                moveq    #$0, d1
  001ce0:  2f 01                move.l   d1, -(a7)
  001ce2:  2f 01                move.l   d1, -(a7)
  001ce4:  70 26                moveq    #$26, d0
  001ce6:  2f 00                move.l   d0, -(a7)
  001ce8:  4e ba 45 3a          jsr      $6224(pc)  ; -> EngineDispatch
  001cec:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  001cf0:  3f 2e 00 0a          move.w   $a(a6), -(a7)
  001cf4:  1f 2e 00 08          move.b   $8(a6), -(a7)
  001cf8:  48 78 16 b4          pea.l    $16b4.w
  001cfc:  4e ba 69 9e          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001d00:  58 8f                addq.l   #$4, a7
  001d02:  2f 00                move.l   d0, -(a7)
  001d04:  20 5f                movea.l  (a7)+, a0
  001d06:  4e 90                jsr      (a0)
  001d08:  70 01                moveq    #$1, d0
  001d0a:  2f 00                move.l   d0, -(a7)
  001d0c:  2f 00                move.l   d0, -(a7)
  001d0e:  48 6e 00 0c          pea.l    $c(a6)
  001d12:  72 29                moveq    #$29, d1
  001d14:  2f 01                move.l   d1, -(a7)
  001d16:  4e ba 45 0c          jsr      $6224(pc)  ; -> EngineDispatch
  001d1a:  4e 5e                unlk     a6
  001d1c:  4e 74 00 08          rtd      #$8
* GA_DisposGDevice  -  System 7 $9684 (identical code).
* S7: Patch #74 replaces _DisposGDevice ($AA30); card commands: $2B
GA_DisposGDevice:
  001d20:  4e 56 00 00          link.w   a6, #$0
  001d24:  70 01                moveq    #$1, d0
  001d26:  2f 00                move.l   d0, -(a7)
  001d28:  2f 00                move.l   d0, -(a7)
  001d2a:  48 6e 00 08          pea.l    $8(a6)
  001d2e:  72 2b                moveq    #$2b, d1
  001d30:  2f 01                move.l   d1, -(a7)
  001d32:  4e ba 44 f0          jsr      $6224(pc)  ; -> EngineDispatch
  001d36:  2f 2e 00 08          move.l   $8(a6), -(a7)
  001d3a:  48 78 16 c0          pea.l    $16c0.w
  001d3e:  4e ba 69 5c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001d42:  58 8f                addq.l   #$4, a7
  001d44:  2f 00                move.l   d0, -(a7)
  001d46:  20 5f                movea.l  (a7)+, a0
  001d48:  4e 90                jsr      (a0)
  001d4a:  4e 5e                unlk     a6
  001d4c:  4e 74 00 04          rtd      #$4
* GA_AddSearch  -  System 7 $96B8 (same trap slot $16E8, code r=0.95).
* S7: Patch #25 replaces _AddSearch ($AA3A); card commands: $26 $29
GA_AddSearch:
  001d50:  4e 56 ff fc          link.w   a6, #$fffc
  001d54:  2f 0b                move.l   a3, -(a7)
  001d56:  26 6e 00 08          movea.l  $8(a6), a3
  001d5a:  2d 78 0c c8 ff fc    move.l   $cc8.w, -$4(a6)
  001d60:  70 01                moveq    #$1, d0
  001d62:  2f 00                move.l   d0, -(a7)
  001d64:  72 00                moveq    #$0, d1
  001d66:  2f 01                move.l   d1, -(a7)
  001d68:  2f 01                move.l   d1, -(a7)
  001d6a:  70 26                moveq    #$26, d0
  001d6c:  2f 00                move.l   d0, -(a7)
  001d6e:  4e ba 44 b4          jsr      $6224(pc)  ; -> EngineDispatch
  001d72:  2f 0b                move.l   a3, -(a7)
  001d74:  48 78 16 e8          pea.l    $16e8.w
  001d78:  4e ba 69 22          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001d7c:  58 8f                addq.l   #$4, a7
  001d7e:  2f 00                move.l   d0, -(a7)
  001d80:  20 5f                movea.l  (a7)+, a0
  001d82:  4e 90                jsr      (a0)
  001d84:  70 01                moveq    #$1, d0
  001d86:  2f 00                move.l   d0, -(a7)
  001d88:  2f 00                move.l   d0, -(a7)
  001d8a:  48 6e ff fc          pea.l    -$4(a6)
  001d8e:  72 29                moveq    #$29, d1
  001d90:  2f 01                move.l   d1, -(a7)
  001d92:  4e ba 44 90          jsr      $6224(pc)  ; -> EngineDispatch
  001d96:  26 6e ff f8          movea.l  -$8(a6), a3
  001d9a:  4e 5e                unlk     a6
  001d9c:  4e 74 00 04          rtd      #$4
* GA_InitGDevice  -  System 7 $9706 (same trap slot $16B8, code r=0.98).
* S7: Patch #99 replaces _InitGDevice ($AA2E); card commands: $12 $13 $14 $16 $26 $29
GA_InitGDevice:
  001da0:  4e 56 00 00          link.w   a6, #$0
  001da4:  2f 0b                move.l   a3, -(a7)
  001da6:  20 78 08 88          movea.l  $888.w, a0
  001daa:  20 50                movea.l  (a0), a0
  001dac:  20 50                movea.l  (a0), a0
  001dae:  20 68 02 14          movea.l  $214(a0), a0
  001db2:  26 50                movea.l  (a0), a3
  001db4:  27 6e 00 08 01 8e    move.l   $8(a6), $18e(a3)
  001dba:  70 01                moveq    #$1, d0
  001dbc:  2f 00                move.l   d0, -(a7)
  001dbe:  72 00                moveq    #$0, d1
  001dc0:  2f 01                move.l   d1, -(a7)
  001dc2:  2f 01                move.l   d1, -(a7)
  001dc4:  70 26                moveq    #$26, d0
  001dc6:  2f 00                move.l   d0, -(a7)
  001dc8:  4e ba 44 5a          jsr      $6224(pc)  ; -> EngineDispatch
  001dcc:  70 01                moveq    #$1, d0
  001dce:  2f 00                move.l   d0, -(a7)
  001dd0:  2f 00                move.l   d0, -(a7)
  001dd2:  48 6e 00 08          pea.l    $8(a6)
  001dd6:  72 29                moveq    #$29, d1
  001dd8:  2f 01                move.l   d1, -(a7)
  001dda:  4e ba 44 48          jsr      $6224(pc)  ; -> EngineDispatch
  001dde:  3f 2e 00 10          move.w   $10(a6), -(a7)
  001de2:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  001de6:  2f 2e 00 08          move.l   $8(a6), -(a7)
  001dea:  48 78 16 b8          pea.l    $16b8.w
  001dee:  4e ba 68 ac          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001df2:  58 8f                addq.l   #$4, a7
  001df4:  2f 00                move.l   d0, -(a7)
  001df6:  20 5f                movea.l  (a7)+, a0
  001df8:  4e 90                jsr      (a0)
  001dfa:  4e ba 71 dc          jsr      $8fd8(pc)  ; -> s7_sub_77a6
  001dfe:  70 01                moveq    #$1, d0
  001e00:  2f 00                move.l   d0, -(a7)
  001e02:  2f 00                move.l   d0, -(a7)
  001e04:  48 6e 00 08          pea.l    $8(a6)
  001e08:  72 29                moveq    #$29, d1
  001e0a:  2f 01                move.l   d1, -(a7)
  001e0c:  4e ba 44 16          jsr      $6224(pc)  ; -> EngineDispatch
  001e10:  70 00                moveq    #$0, d0
  001e12:  27 40 01 8e          move.l   d0, $18e(a3)
  001e16:  26 6e ff fc          movea.l  -$4(a6), a3
  001e1a:  4e 5e                unlk     a6
  001e1c:  4e 74 00 0a          rtd      #$a
* GA_DelSearch  -  System 7 $9794 (same trap slot $1730, code r=0.95).
* S7: Patch #26 replaces _DelSearch ($AA4C); card commands: $26 $29
GA_DelSearch:
  001e20:  4e 56 ff fc          link.w   a6, #$fffc
  001e24:  2f 0b                move.l   a3, -(a7)
  001e26:  26 6e 00 08          movea.l  $8(a6), a3
  001e2a:  2d 78 0c c8 ff fc    move.l   $cc8.w, -$4(a6)
  001e30:  70 01                moveq    #$1, d0
  001e32:  2f 00                move.l   d0, -(a7)
  001e34:  72 00                moveq    #$0, d1
  001e36:  2f 01                move.l   d1, -(a7)
  001e38:  2f 01                move.l   d1, -(a7)
  001e3a:  70 26                moveq    #$26, d0
  001e3c:  2f 00                move.l   d0, -(a7)
  001e3e:  4e ba 43 e4          jsr      $6224(pc)  ; -> EngineDispatch
  001e42:  2f 0b                move.l   a3, -(a7)
  001e44:  48 78 17 30          pea.l    $1730.w
  001e48:  4e ba 68 52          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001e4c:  58 8f                addq.l   #$4, a7
  001e4e:  2f 00                move.l   d0, -(a7)
  001e50:  20 5f                movea.l  (a7)+, a0
  001e52:  4e 90                jsr      (a0)
  001e54:  70 01                moveq    #$1, d0
  001e56:  2f 00                move.l   d0, -(a7)
  001e58:  2f 00                move.l   d0, -(a7)
  001e5a:  48 6e ff fc          pea.l    -$4(a6)
  001e5e:  72 29                moveq    #$29, d1
  001e60:  2f 01                move.l   d1, -(a7)
  001e62:  4e ba 43 c0          jsr      $6224(pc)  ; -> EngineDispatch
  001e66:  26 6e ff f8          movea.l  -$8(a6), a3
  001e6a:  4e 5e                unlk     a6
  001e6c:  4e 74 00 04          rtd      #$4
* GA_AddComp  -  System 7 $97E2 (same trap slot $16EC, code r=0.95).
* S7: Patch #27 replaces _AddComp ($AA3B); card commands: $26 $29
GA_AddComp:
  001e70:  4e 56 ff fc          link.w   a6, #$fffc
  001e74:  2f 0b                move.l   a3, -(a7)
  001e76:  26 6e 00 08          movea.l  $8(a6), a3
  001e7a:  2d 78 0c c8 ff fc    move.l   $cc8.w, -$4(a6)
  001e80:  70 01                moveq    #$1, d0
  001e82:  2f 00                move.l   d0, -(a7)
  001e84:  72 00                moveq    #$0, d1
  001e86:  2f 01                move.l   d1, -(a7)
  001e88:  2f 01                move.l   d1, -(a7)
  001e8a:  70 26                moveq    #$26, d0
  001e8c:  2f 00                move.l   d0, -(a7)
  001e8e:  4e ba 43 94          jsr      $6224(pc)  ; -> EngineDispatch
  001e92:  2f 0b                move.l   a3, -(a7)
  001e94:  48 78 16 ec          pea.l    $16ec.w
  001e98:  4e ba 68 02          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001e9c:  58 8f                addq.l   #$4, a7
  001e9e:  2f 00                move.l   d0, -(a7)
  001ea0:  20 5f                movea.l  (a7)+, a0
  001ea2:  4e 90                jsr      (a0)
  001ea4:  70 01                moveq    #$1, d0
  001ea6:  2f 00                move.l   d0, -(a7)
  001ea8:  2f 00                move.l   d0, -(a7)
  001eaa:  48 6e ff fc          pea.l    -$4(a6)
  001eae:  72 29                moveq    #$29, d1
  001eb0:  2f 01                move.l   d1, -(a7)
  001eb2:  4e ba 43 70          jsr      $6224(pc)  ; -> EngineDispatch
  001eb6:  26 6e ff f8          movea.l  -$8(a6), a3
  001eba:  4e 5e                unlk     a6
  001ebc:  4e 74 00 04          rtd      #$4
* GA_DelComp  -  System 7 $9830 (same trap slot $1734, code r=0.95).
* S7: Patch #28 replaces _DelComp ($AA4D); card commands: $26 $29
GA_DelComp:
  001ec0:  4e 56 ff fc          link.w   a6, #$fffc
  001ec4:  2f 0b                move.l   a3, -(a7)
  001ec6:  26 6e 00 08          movea.l  $8(a6), a3
  001eca:  2d 78 0c c8 ff fc    move.l   $cc8.w, -$4(a6)
  001ed0:  70 01                moveq    #$1, d0
  001ed2:  2f 00                move.l   d0, -(a7)
  001ed4:  72 00                moveq    #$0, d1
  001ed6:  2f 01                move.l   d1, -(a7)
  001ed8:  2f 01                move.l   d1, -(a7)
  001eda:  70 26                moveq    #$26, d0
  001edc:  2f 00                move.l   d0, -(a7)
  001ede:  4e ba 43 44          jsr      $6224(pc)  ; -> EngineDispatch
  001ee2:  2f 0b                move.l   a3, -(a7)
  001ee4:  48 78 17 34          pea.l    $1734.w
  001ee8:  4e ba 67 b2          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001eec:  58 8f                addq.l   #$4, a7
  001eee:  2f 00                move.l   d0, -(a7)
  001ef0:  20 5f                movea.l  (a7)+, a0
  001ef2:  4e 90                jsr      (a0)
  001ef4:  70 01                moveq    #$1, d0
  001ef6:  2f 00                move.l   d0, -(a7)
  001ef8:  2f 00                move.l   d0, -(a7)
  001efa:  48 6e ff fc          pea.l    -$4(a6)
  001efe:  72 29                moveq    #$29, d1
  001f00:  2f 01                move.l   d1, -(a7)
  001f02:  4e ba 43 20          jsr      $6224(pc)  ; -> EngineDispatch
  001f06:  26 6e ff f8          movea.l  -$8(a6), a3
  001f0a:  4e 5e                unlk     a6
  001f0c:  4e 74 00 04          rtd      #$4
* GA_DisposPixPat  -  System 7 $987E (identical code).
* S7: Patch #29 replaces _DisposPixPat ($AA08); card commands: $2C
GA_DisposPixPat:
  001f10:  4e 56 00 00          link.w   a6, #$0
  001f14:  70 01                moveq    #$1, d0
  001f16:  2f 00                move.l   d0, -(a7)
  001f18:  2f 00                move.l   d0, -(a7)
  001f1a:  48 6e 00 08          pea.l    $8(a6)
  001f1e:  72 2c                moveq    #$2c, d1
  001f20:  2f 01                move.l   d1, -(a7)
  001f22:  4e ba 43 00          jsr      $6224(pc)  ; -> EngineDispatch
  001f26:  2f 2e 00 08          move.l   $8(a6), -(a7)
  001f2a:  48 78 16 20          pea.l    $1620.w
  001f2e:  4e ba 67 6c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001f32:  58 8f                addq.l   #$4, a7
  001f34:  2f 00                move.l   d0, -(a7)
  001f36:  20 5f                movea.l  (a7)+, a0
  001f38:  4e 90                jsr      (a0)
  001f3a:  4e 5e                unlk     a6
  001f3c:  4e 74 00 04          rtd      #$4
* GA_CopyPixPat  -  System 7 $98B2 (same trap slot $1624, code r=0.95).
* S7: Patch #30 replaces _CopyPixPat ($AA09); card commands: $2A
GA_CopyPixPat:
  001f40:  4e 56 ff f8          link.w   a6, #$fff8
  001f44:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  001f48:  28 6e 00 08          movea.l  $8(a6), a4
  001f4c:  70 00                moveq    #$0, d0
  001f4e:  2f 00                move.l   d0, -(a7)
  001f50:  4e ba 68 d0          jsr      $8822(pc)  ; -> s7_sub_6f1c
  001f54:  26 40                movea.l  d0, a3
  001f56:  7e 00                moveq    #$0, d7
  001f58:  20 0b                move.l   a3, d0
  001f5a:  58 8f                addq.l   #$4, a7
  001f5c:  67 24                beq.b    $1f82  ; -> L1f82
  001f5e:  30 2b 00 06          move.w   $6(a3), d0
  001f62:  48 c0                ext.l    d0
  001f64:  6c 1c                bge.b    $1f82  ; -> L1f82
  001f66:  b9 eb 00 3a          cmpa.l   $3a(a3), a4
  001f6a:  66 04                bne.b    $1f70  ; -> L1f70
  001f6c:  7e 01                moveq    #$1, d7
  001f6e:  60 12                bra.b    $1f82  ; -> L1f82
L1f70:
  001f70:  b9 eb 00 20          cmpa.l   $20(a3), a4
  001f74:  66 04                bne.b    $1f7a  ; -> L1f7a
  001f76:  7e 02                moveq    #$2, d7
  001f78:  60 08                bra.b    $1f82  ; -> L1f82
L1f7a:
  001f7a:  b9 eb 00 3e          cmpa.l   $3e(a3), a4
  001f7e:  66 02                bne.b    $1f82  ; -> L1f82
  001f80:  7e 03                moveq    #$3, d7
L1f82:
  001f82:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  001f86:  2f 0c                move.l   a4, -(a7)
  001f88:  48 78 16 24          pea.l    $1624.w
  001f8c:  4e ba 67 0e          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  001f90:  58 8f                addq.l   #$4, a7
  001f92:  2f 00                move.l   d0, -(a7)
  001f94:  20 5f                movea.l  (a7)+, a0
  001f96:  4e 90                jsr      (a0)
  001f98:  20 54                movea.l  (a4), a0
  001f9a:  31 7c ff ff 00 0e    move.w   #$ffff, $e(a0)
  001fa0:  4a 87                tst.l    d7
  001fa2:  67 22                beq.b    $1fc6  ; -> L1fc6
  001fa4:  70 00                moveq    #$0, d0
  001fa6:  2d 40 ff f8          move.l   d0, -$8(a6)
  001faa:  2d 47 ff fc          move.l   d7, -$4(a6)
  001fae:  72 01                moveq    #$1, d1
  001fb0:  2f 01                move.l   d1, -(a7)
  001fb2:  70 02                moveq    #$2, d0
  001fb4:  2f 00                move.l   d0, -(a7)
  001fb6:  48 6e ff f8          pea.l    -$8(a6)
  001fba:  70 2a                moveq    #$2a, d0
  001fbc:  2f 00                move.l   d0, -(a7)
  001fbe:  4e ba 42 64          jsr      $6224(pc)  ; -> EngineDispatch
  001fc2:  4f ef 00 10          lea.l    $10(a7), a7
L1fc6:
  001fc6:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  001fcc:  4e 5e                unlk     a6
  001fce:  4e 74 00 08          rtd      #$8
* GA_MakeRGBPat  -  System 7 $9948 (same trap slot $1634, code r=0.95).
* S7: Patch #31 replaces _MakeRGBPat ($AA0D); card commands: $2A
GA_MakeRGBPat:
  001fd2:  4e 56 ff f8          link.w   a6, #$fff8
  001fd6:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  001fda:  28 6e 00 0c          movea.l  $c(a6), a4
  001fde:  70 00                moveq    #$0, d0
  001fe0:  2f 00                move.l   d0, -(a7)
  001fe2:  4e ba 68 3e          jsr      $8822(pc)  ; -> s7_sub_6f1c
  001fe6:  26 40                movea.l  d0, a3
  001fe8:  7e 00                moveq    #$0, d7
  001fea:  20 0b                move.l   a3, d0
  001fec:  58 8f                addq.l   #$4, a7
  001fee:  67 24                beq.b    $2014  ; -> L2014
  001ff0:  30 2b 00 06          move.w   $6(a3), d0
  001ff4:  48 c0                ext.l    d0
  001ff6:  6c 1c                bge.b    $2014  ; -> L2014
  001ff8:  b9 eb 00 3a          cmpa.l   $3a(a3), a4
  001ffc:  66 04                bne.b    $2002  ; -> L2002
  001ffe:  7e 01                moveq    #$1, d7
  002000:  60 12                bra.b    $2014  ; -> L2014
L2002:
  002002:  b9 eb 00 20          cmpa.l   $20(a3), a4
  002006:  66 04                bne.b    $200c  ; -> L200c
  002008:  7e 02                moveq    #$2, d7
  00200a:  60 08                bra.b    $2014  ; -> L2014
L200c:
  00200c:  b9 eb 00 3e          cmpa.l   $3e(a3), a4
  002010:  66 02                bne.b    $2014  ; -> L2014
  002012:  7e 03                moveq    #$3, d7
L2014:
  002014:  2f 0c                move.l   a4, -(a7)
  002016:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00201a:  48 78 16 34          pea.l    $1634.w
  00201e:  4e ba 66 7c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002022:  58 8f                addq.l   #$4, a7
  002024:  2f 00                move.l   d0, -(a7)
  002026:  20 5f                movea.l  (a7)+, a0
  002028:  4e 90                jsr      (a0)
  00202a:  4a 87                tst.l    d7
  00202c:  67 22                beq.b    $2050  ; -> L2050
  00202e:  70 00                moveq    #$0, d0
  002030:  2d 40 ff f8          move.l   d0, -$8(a6)
  002034:  2d 47 ff fc          move.l   d7, -$4(a6)
  002038:  72 01                moveq    #$1, d1
  00203a:  2f 01                move.l   d1, -(a7)
  00203c:  70 02                moveq    #$2, d0
  00203e:  2f 00                move.l   d0, -(a7)
  002040:  48 6e ff f8          pea.l    -$8(a6)
  002044:  70 2a                moveq    #$2a, d0
  002046:  2f 00                move.l   d0, -(a7)
  002048:  4e ba 41 da          jsr      $6224(pc)  ; -> EngineDispatch
  00204c:  4f ef 00 10          lea.l    $10(a7), a7
L2050:
  002050:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  002056:  4e 5e                unlk     a6
  002058:  4e 74 00 08          rtd      #$8
* GA_TrapAB11  -  System 7 $99D6 (same trap slot $1A44, code r=0.96).
* S7: Patch #32 replaces trap $AB11; card commands: $2A
GA_TrapAB11:
  00205c:  4e 56 ff f8          link.w   a6, #$fff8
  002060:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  002064:  70 00                moveq    #$0, d0
  002066:  2f 00                move.l   d0, -(a7)
  002068:  4e ba 67 b8          jsr      $8822(pc)  ; -> s7_sub_6f1c
  00206c:  26 40                movea.l  d0, a3
  00206e:  7e 00                moveq    #$0, d7
  002070:  20 6e 00 08          movea.l  $8(a6), a0
  002074:  28 50                movea.l  (a0), a4
  002076:  20 0c                move.l   a4, d0
  002078:  58 8f                addq.l   #$4, a7
  00207a:  67 44                beq.b    $20c0  ; -> L20c0
  00207c:  70 01                moveq    #$1, d0
  00207e:  2f 00                move.l   d0, -(a7)
  002080:  2f 2e 00 08          move.l   $8(a6), -(a7)
  002084:  72 00                moveq    #$0, d1
  002086:  2f 01                move.l   d1, -(a7)
  002088:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00208c:  4e ba f7 7a          jsr      $1808(pc)  ; -> s7_sub_91aa
  002090:  4a 00                tst.b    d0
  002092:  4f ef 00 10          lea.l    $10(a7), a7
  002096:  66 66                bne.b    $20fe  ; -> L20fe
  002098:  20 0b                move.l   a3, d0
  00209a:  67 24                beq.b    $20c0  ; -> L20c0
  00209c:  30 2b 00 06          move.w   $6(a3), d0
  0020a0:  48 c0                ext.l    d0
  0020a2:  6c 1c                bge.b    $20c0  ; -> L20c0
  0020a4:  b9 eb 00 3a          cmpa.l   $3a(a3), a4
  0020a8:  66 04                bne.b    $20ae  ; -> L20ae
  0020aa:  7e 01                moveq    #$1, d7
  0020ac:  60 12                bra.b    $20c0  ; -> L20c0
L20ae:
  0020ae:  b9 eb 00 20          cmpa.l   $20(a3), a4
  0020b2:  66 04                bne.b    $20b8  ; -> L20b8
  0020b4:  7e 02                moveq    #$2, d7
  0020b6:  60 08                bra.b    $20c0  ; -> L20c0
L20b8:
  0020b8:  b9 eb 00 3e          cmpa.l   $3e(a3), a4
  0020bc:  66 02                bne.b    $20c0  ; -> L20c0
  0020be:  7e 03                moveq    #$3, d7
L20c0:
  0020c0:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  0020c4:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0020c8:  48 78 1a 44          pea.l    $1a44.w
  0020cc:  4e ba 65 ce          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0020d0:  58 8f                addq.l   #$4, a7
  0020d2:  2f 00                move.l   d0, -(a7)
  0020d4:  20 5f                movea.l  (a7)+, a0
  0020d6:  4e 90                jsr      (a0)
  0020d8:  4a 87                tst.l    d7
  0020da:  67 22                beq.b    $20fe  ; -> L20fe
  0020dc:  70 00                moveq    #$0, d0
  0020de:  2d 40 ff f8          move.l   d0, -$8(a6)
  0020e2:  2d 47 ff fc          move.l   d7, -$4(a6)
  0020e6:  72 01                moveq    #$1, d1
  0020e8:  2f 01                move.l   d1, -(a7)
  0020ea:  70 02                moveq    #$2, d0
  0020ec:  2f 00                move.l   d0, -(a7)
  0020ee:  48 6e ff f8          pea.l    -$8(a6)
  0020f2:  70 2a                moveq    #$2a, d0
  0020f4:  2f 00                move.l   d0, -(a7)
  0020f6:  4e ba 41 2c          jsr      $6224(pc)  ; -> EngineDispatch
  0020fa:  4f ef 00 10          lea.l    $10(a7), a7
L20fe:
  0020fe:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  002104:  4e 5e                unlk     a6
  002106:  4e 74 00 08          rtd      #$8
* s7_sub_9a88  -  System 7 $9A88 (similar code, r=0.90).
s7_sub_9a88:
  00210a:  4e 56 ff f8          link.w   a6, #$fff8
  00210e:  48 e7 07 18          movem.l  d5-d7/a3-a4, -(a7)
  002112:  3a 2e 00 08          move.w   $8(a6), d5
  002116:  70 00                moveq    #$0, d0
  002118:  2f 00                move.l   d0, -(a7)
  00211a:  4e ba 67 06          jsr      $8822(pc)  ; -> s7_sub_6f1c
  00211e:  26 40                movea.l  d0, a3
  002120:  4a ae 00 0a          tst.l    $a(a6)
  002124:  58 8f                addq.l   #$4, a7
  002126:  67 00 01 0a          beq.w    $2232  ; -> L2232
  00212a:  4a 45                tst.w    d5
  00212c:  67 1c                beq.b    $214a  ; -> L214a
  00212e:  20 6e 00 0a          movea.l  $a(a6), a0
  002132:  20 50                movea.l  (a0), a0
  002134:  20 68 00 02          movea.l  $2(a0), a0
  002138:  20 50                movea.l  (a0), a0
  00213a:  20 68 00 2a          movea.l  $2a(a0), a0
  00213e:  28 50                movea.l  (a0), a4
  002140:  4a 94                tst.l    (a4)
  002142:  66 06                bne.b    $214a  ; -> L214a
  002144:  59 8f                subq.l   #$4, a7
  002146:  aa 28                dc.w     $aa28
  002148:  28 9f                move.l   (a7)+, (a4)
L214a:
  00214a:  4e ba f0 e4          jsr      $1230(pc)  ; -> GetA5
  00214e:  20 40                movea.l  d0, a0
  002150:  20 50                movea.l  (a0), a0
  002152:  b7 d0                cmpa.l   (a0), a3
  002154:  66 00 00 c4          bne.w    $221a  ; -> L221a
  002158:  30 2b 00 06          move.w   $6(a3), d0
  00215c:  48 c0                ext.l    d0
  00215e:  5d c7                slt.b    d7
  002160:  44 07                neg.b    d7
  002162:  4a 07                tst.b    d7
  002164:  67 08                beq.b    $216e  ; -> L216e
  002166:  41 eb 00 3e          lea.l    $3e(a3), a0
  00216a:  20 08                move.l   a0, d0
  00216c:  60 06                bra.b    $2174  ; -> L2174
L216e:
  00216e:  41 eb 00 28          lea.l    $28(a3), a0
  002172:  20 08                move.l   a0, d0
L2174:
  002174:  28 40                movea.l  d0, a4
  002176:  70 00                moveq    #$0, d0
  002178:  4a 45                tst.w    d5
  00217a:  67 08                beq.b    $2184  ; -> L2184
  00217c:  72 00                moveq    #$0, d1
  00217e:  12 07                move.b   d7, d1
  002180:  66 02                bne.b    $2184  ; -> L2184
  002182:  70 01                moveq    #$1, d0
L2184:
  002184:  1c 00                move.b   d0, d6
  002186:  67 20                beq.b    $21a8  ; -> L21a8
  002188:  70 00                moveq    #$0, d0
  00218a:  2f 00                move.l   d0, -(a7)
  00218c:  20 6e 00 0a          movea.l  $a(a6), a0
  002190:  20 50                movea.l  (a0), a0
  002192:  48 68 00 14          pea.l    $14(a0)
  002196:  2f 00                move.l   d0, -(a7)
  002198:  2f 0c                move.l   a4, -(a7)
  00219a:  4e ba f6 6c          jsr      $1808(pc)  ; -> s7_sub_91aa
  00219e:  72 00                moveq    #$0, d1
  0021a0:  12 00                move.b   d0, d1
  0021a2:  4f ef 00 10          lea.l    $10(a7), a7
  0021a6:  67 34                beq.b    $21dc  ; -> L21dc
L21a8:
  0021a8:  70 00                moveq    #$0, d0
  0021aa:  10 06                move.b   d6, d0
  0021ac:  66 00 00 84          bne.w    $2232  ; -> L2232
  0021b0:  48 c5                ext.l    d5
  0021b2:  2f 05                move.l   d5, -(a7)
  0021b4:  4a 45                tst.w    d5
  0021b6:  67 08                beq.b    $21c0  ; -> L21c0
  0021b8:  41 ee 00 0a          lea.l    $a(a6), a0
  0021bc:  20 08                move.l   a0, d0
  0021be:  60 04                bra.b    $21c4  ; -> L21c4
L21c0:
  0021c0:  20 2e 00 0a          move.l   $a(a6), d0
L21c4:
  0021c4:  2f 00                move.l   d0, -(a7)
  0021c6:  70 00                moveq    #$0, d0
  0021c8:  10 07                move.b   d7, d0
  0021ca:  2f 00                move.l   d0, -(a7)
  0021cc:  2f 0c                move.l   a4, -(a7)
  0021ce:  4e ba f6 38          jsr      $1808(pc)  ; -> s7_sub_91aa
  0021d2:  72 00                moveq    #$0, d1
  0021d4:  12 00                move.b   d0, d1
  0021d6:  4f ef 00 10          lea.l    $10(a7), a7
  0021da:  66 56                bne.b    $2232  ; -> L2232
L21dc:
  0021dc:  2f 2e 00 0a          move.l   $a(a6), -(a7)
  0021e0:  48 78 1a 8c          pea.l    $1a8c.w
  0021e4:  4e ba 64 b6          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0021e8:  58 8f                addq.l   #$4, a7
  0021ea:  2f 00                move.l   d0, -(a7)
  0021ec:  3f 05                move.w   d5, -(a7)
  0021ee:  30 1f                move.w   (a7)+, d0
  0021f0:  20 5f                movea.l  (a7)+, a0
  0021f2:  4e 90                jsr      (a0)
  0021f4:  70 00                moveq    #$0, d0
  0021f6:  2d 40 ff f8          move.l   d0, -$8(a6)
  0021fa:  72 03                moveq    #$3, d1
  0021fc:  2d 41 ff fc          move.l   d1, -$4(a6)
  002200:  70 01                moveq    #$1, d0
  002202:  2f 00                move.l   d0, -(a7)
  002204:  70 02                moveq    #$2, d0
  002206:  2f 00                move.l   d0, -(a7)
  002208:  48 6e ff f8          pea.l    -$8(a6)
  00220c:  70 2a                moveq    #$2a, d0
  00220e:  2f 00                move.l   d0, -(a7)
  002210:  4e ba 40 12          jsr      $6224(pc)  ; -> EngineDispatch
  002214:  4f ef 00 10          lea.l    $10(a7), a7
  002218:  60 18                bra.b    $2232  ; -> L2232
L221a:
  00221a:  2f 2e 00 0a          move.l   $a(a6), -(a7)
  00221e:  48 78 1a 8c          pea.l    $1a8c.w
  002222:  4e ba 64 78          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002226:  58 8f                addq.l   #$4, a7
  002228:  2f 00                move.l   d0, -(a7)
  00222a:  3f 05                move.w   d5, -(a7)
  00222c:  30 1f                move.w   (a7)+, d0
  00222e:  20 5f                movea.l  (a7)+, a0
  002230:  4e 90                jsr      (a0)
L2232:
  002232:  4c ee 18 e0 ff e4    movem.l  -$1c(a6), d5-d7/a3-a4
  002238:  4e 5e                unlk     a6
  00223a:  4e 74 00 06          rtd      #$6
* GA_SetPBits  -  System 7 $9BCA (same trap slot $FD4, code r=0.89).
* S7: Patch #33 replaces _SetPBits ($A875); card commands: $26
GA_SetPBits:
  00223e:  4e 56 ff fc          link.w   a6, #$fffc
  002242:  48 e7 00 18          movem.l  a3-a4, -(a7)
  002246:  28 6e 00 08          movea.l  $8(a6), a4
  00224a:  70 00                moveq    #$0, d0
  00224c:  2f 00                move.l   d0, -(a7)
  00224e:  4e ba 65 d2          jsr      $8822(pc)  ; -> s7_sub_6f1c
  002252:  2d 40 ff fc          move.l   d0, -$4(a6)
  002256:  4e ba ef d8          jsr      $1230(pc)  ; -> GetA5
  00225a:  20 40                movea.l  d0, a0
  00225c:  20 50                movea.l  (a0), a0
  00225e:  20 2e ff fc          move.l   -$4(a6), d0
  002262:  b0 90                cmp.l    (a0), d0
  002264:  58 8f                addq.l   #$4, a7
  002266:  66 54                bne.b    $22bc  ; -> L22bc
  002268:  20 6e ff fc          movea.l  -$4(a6), a0
  00226c:  30 28 00 06          move.w   $6(a0), d0
  002270:  48 c0                ext.l    d0
  002272:  6d 48                blt.b    $22bc  ; -> L22bc
  002274:  20 6e ff fc          movea.l  -$4(a6), a0
  002278:  47 e8 00 02          lea.l    $2(a0), a3
  00227c:  20 13                move.l   (a3), d0
  00227e:  b0 94                cmp.l    (a4), d0
  002280:  66 24                bne.b    $22a6  ; -> L22a6
  002282:  30 2c 00 04          move.w   $4(a4), d0
  002286:  48 c0                ext.l    d0
  002288:  32 2b 00 04          move.w   $4(a3), d1
  00228c:  48 c1                ext.l    d1
  00228e:  b0 81                cmp.l    d1, d0
  002290:  66 14                bne.b    $22a6  ; -> L22a6
  002292:  20 2b 00 06          move.l   $6(a3), d0
  002296:  b0 ac 00 06          cmp.l    $6(a4), d0
  00229a:  66 0a                bne.b    $22a6  ; -> L22a6
  00229c:  20 2b 00 0a          move.l   $a(a3), d0
  0022a0:  b0 ac 00 0a          cmp.l    $a(a4), d0
  0022a4:  67 16                beq.b    $22bc  ; -> L22bc
L22a6:
  0022a6:  70 01                moveq    #$1, d0
  0022a8:  2f 00                move.l   d0, -(a7)
  0022aa:  72 00                moveq    #$0, d1
  0022ac:  2f 01                move.l   d1, -(a7)
  0022ae:  2f 01                move.l   d1, -(a7)
  0022b0:  70 26                moveq    #$26, d0
  0022b2:  2f 00                move.l   d0, -(a7)
  0022b4:  4e ba 3f 6e          jsr      $6224(pc)  ; -> EngineDispatch
  0022b8:  4f ef 00 10          lea.l    $10(a7), a7
L22bc:
  0022bc:  2f 0c                move.l   a4, -(a7)
  0022be:  48 78 0f d4          pea.l    $fd4.w
  0022c2:  4e ba 63 d8          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0022c6:  58 8f                addq.l   #$4, a7
  0022c8:  2f 00                move.l   d0, -(a7)
  0022ca:  20 5f                movea.l  (a7)+, a0
  0022cc:  4e 90                jsr      (a0)
  0022ce:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  0022d4:  4e 5e                unlk     a6
  0022d6:  4e 74 00 04          rtd      #$4
* GA_PortSize  -  System 7 $9C62 (same trap slot $FD8, code r=0.96).
* S7: Patch #34 replaces _PortSize ($A876); card commands: $26
GA_PortSize:
  0022da:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  0022de:  3c 2f 00 14          move.w   $14(a7), d6
  0022e2:  3e 2f 00 16          move.w   $16(a7), d7
  0022e6:  70 00                moveq    #$0, d0
  0022e8:  2f 00                move.l   d0, -(a7)
  0022ea:  4e ba 65 36          jsr      $8822(pc)  ; -> s7_sub_6f1c
  0022ee:  28 40                movea.l  d0, a4
  0022f0:  4e ba ef 3e          jsr      $1230(pc)  ; -> GetA5
  0022f4:  20 40                movea.l  d0, a0
  0022f6:  20 50                movea.l  (a0), a0
  0022f8:  b9 d0                cmpa.l   (a0), a4
  0022fa:  58 8f                addq.l   #$4, a7
  0022fc:  66 40                bne.b    $233e  ; -> L233e
  0022fe:  47 ec 00 10          lea.l    $10(a4), a3
  002302:  30 2b 00 06          move.w   $6(a3), d0
  002306:  48 c0                ext.l    d0
  002308:  32 2b 00 02          move.w   $2(a3), d1
  00230c:  48 c1                ext.l    d1
  00230e:  90 81                sub.l    d1, d0
  002310:  48 c7                ext.l    d7
  002312:  be 80                cmp.l    d0, d7
  002314:  66 12                bne.b    $2328  ; -> L2328
  002316:  30 2b 00 04          move.w   $4(a3), d0
  00231a:  48 c0                ext.l    d0
  00231c:  32 13                move.w   (a3), d1
  00231e:  48 c1                ext.l    d1
  002320:  90 81                sub.l    d1, d0
  002322:  48 c6                ext.l    d6
  002324:  bc 80                cmp.l    d0, d6
  002326:  67 16                beq.b    $233e  ; -> L233e
L2328:
  002328:  70 01                moveq    #$1, d0
  00232a:  2f 00                move.l   d0, -(a7)
  00232c:  72 00                moveq    #$0, d1
  00232e:  2f 01                move.l   d1, -(a7)
  002330:  2f 01                move.l   d1, -(a7)
  002332:  70 26                moveq    #$26, d0
  002334:  2f 00                move.l   d0, -(a7)
  002336:  4e ba 3e ec          jsr      $6224(pc)  ; -> EngineDispatch
  00233a:  4f ef 00 10          lea.l    $10(a7), a7
L233e:
  00233e:  3f 07                move.w   d7, -(a7)
  002340:  3f 06                move.w   d6, -(a7)
  002342:  48 78 0f d8          pea.l    $fd8.w
  002346:  4e ba 63 54          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00234a:  58 8f                addq.l   #$4, a7
  00234c:  2f 00                move.l   d0, -(a7)
  00234e:  20 5f                movea.l  (a7)+, a0
  002350:  4e 90                jsr      (a0)
  002352:  4c df 18 c0          movem.l  (a7)+, d6-d7/a3-a4
  002356:  4e 74 00 04          rtd      #$4
* GA_MovePortTo  -  System 7 $9CF2 (same trap slot $FDC, code r=0.97).
* S7: Patch #35 replaces _MovePortTo ($A877); card commands: $26
GA_MovePortTo:
  00235a:  4e 56 00 00          link.w   a6, #$0
  00235e:  2f 0b                move.l   a3, -(a7)
  002360:  70 00                moveq    #$0, d0
  002362:  2f 00                move.l   d0, -(a7)
  002364:  4e ba 64 bc          jsr      $8822(pc)  ; -> s7_sub_6f1c
  002368:  26 40                movea.l  d0, a3
  00236a:  4e ba ee c4          jsr      $1230(pc)  ; -> GetA5
  00236e:  20 40                movea.l  d0, a0
  002370:  20 50                movea.l  (a0), a0
  002372:  b7 d0                cmpa.l   (a0), a3
  002374:  58 8f                addq.l   #$4, a7
  002376:  66 16                bne.b    $238e  ; -> L238e
  002378:  70 01                moveq    #$1, d0
  00237a:  2f 00                move.l   d0, -(a7)
  00237c:  72 00                moveq    #$0, d1
  00237e:  2f 01                move.l   d1, -(a7)
  002380:  2f 01                move.l   d1, -(a7)
  002382:  70 26                moveq    #$26, d0
  002384:  2f 00                move.l   d0, -(a7)
  002386:  4e ba 3e 9c          jsr      $6224(pc)  ; -> EngineDispatch
  00238a:  4f ef 00 10          lea.l    $10(a7), a7
L238e:
  00238e:  2f 2e 00 08          move.l   $8(a6), -(a7)
  002392:  48 78 0f dc          pea.l    $fdc.w
  002396:  4e ba 63 04          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00239a:  58 8f                addq.l   #$4, a7
  00239c:  2f 00                move.l   d0, -(a7)
  00239e:  20 5f                movea.l  (a7)+, a0
  0023a0:  4e 90                jsr      (a0)
  0023a2:  26 6e ff fc          movea.l  -$4(a6), a3
  0023a6:  4e 5e                unlk     a6
  0023a8:  4e 74 00 04          rtd      #$4
* GA_SetOrigin  -  System 7 $9D4C (same trap slot $FE0, code r=0.82).
* S7: Patch #36 replaces _SetOrigin ($A878); card commands: $26
GA_SetOrigin:
  0023ac:  48 e7 03 10          movem.l  d6-d7/a3, -(a7)
  0023b0:  3c 2f 00 10          move.w   $10(a7), d6
  0023b4:  3e 2f 00 12          move.w   $12(a7), d7
  0023b8:  70 00                moveq    #$0, d0
  0023ba:  2f 00                move.l   d0, -(a7)
  0023bc:  4e ba 64 64          jsr      $8822(pc)  ; -> s7_sub_6f1c
  0023c0:  26 40                movea.l  d0, a3
  0023c2:  4e ba ee 6c          jsr      $1230(pc)  ; -> GetA5
  0023c6:  20 40                movea.l  d0, a0
  0023c8:  20 50                movea.l  (a0), a0
  0023ca:  b7 d0                cmpa.l   (a0), a3
  0023cc:  58 8f                addq.l   #$4, a7
  0023ce:  66 2e                bne.b    $23fe  ; -> L23fe
  0023d0:  48 c6                ext.l    d6
  0023d2:  30 2b 00 10          move.w   $10(a3), d0
  0023d6:  48 c0                ext.l    d0
  0023d8:  bc 80                cmp.l    d0, d6
  0023da:  66 0c                bne.b    $23e8  ; -> L23e8
  0023dc:  48 c7                ext.l    d7
  0023de:  30 2b 00 12          move.w   $12(a3), d0
  0023e2:  48 c0                ext.l    d0
  0023e4:  be 80                cmp.l    d0, d7
  0023e6:  67 2a                beq.b    $2412  ; -> L2412
L23e8:
  0023e8:  70 01                moveq    #$1, d0
  0023ea:  2f 00                move.l   d0, -(a7)
  0023ec:  72 00                moveq    #$0, d1
  0023ee:  2f 01                move.l   d1, -(a7)
  0023f0:  2f 01                move.l   d1, -(a7)
  0023f2:  70 26                moveq    #$26, d0
  0023f4:  2f 00                move.l   d0, -(a7)
  0023f6:  4e ba 3e 2c          jsr      $6224(pc)  ; -> EngineDispatch
  0023fa:  4f ef 00 10          lea.l    $10(a7), a7
L23fe:
  0023fe:  3f 07                move.w   d7, -(a7)
  002400:  3f 06                move.w   d6, -(a7)
  002402:  48 78 0f e0          pea.l    $fe0.w
  002406:  4e ba 62 94          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00240a:  58 8f                addq.l   #$4, a7
  00240c:  2f 00                move.l   d0, -(a7)
  00240e:  20 5f                movea.l  (a7)+, a0
  002410:  4e 90                jsr      (a0)
L2412:
  002412:  4c df 08 c0          movem.l  (a7)+, d6-d7/a3
  002416:  4e 74 00 04          rtd      #$4
* GA_SetClip  -  System 7 $9DBE (same trap slot $FE4, code r=0.94).
* S7: Patch #37 replaces _SetClip ($A879); card commands: $32
GA_SetClip:
  00241a:  4e 56 00 00          link.w   a6, #$0
  00241e:  2f 0b                move.l   a3, -(a7)
  002420:  70 00                moveq    #$0, d0
  002422:  2f 00                move.l   d0, -(a7)
  002424:  4e ba 63 fc          jsr      $8822(pc)  ; -> s7_sub_6f1c
  002428:  26 40                movea.l  d0, a3
  00242a:  20 0b                move.l   a3, d0
  00242c:  58 8f                addq.l   #$4, a7
  00242e:  67 3c                beq.b    $246c  ; -> L246c
  002430:  4e ba ed fe          jsr      $1230(pc)  ; -> GetA5
  002434:  20 40                movea.l  d0, a0
  002436:  20 50                movea.l  (a0), a0
  002438:  20 50                movea.l  (a0), a0
  00243a:  20 2b 00 1c          move.l   $1c(a3), d0
  00243e:  b0 a8 00 1c          cmp.l    $1c(a0), d0
  002442:  66 28                bne.b    $246c  ; -> L246c
  002444:  55 8f                subq.l   #$2, a7
  002446:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00244a:  2f 2b 00 1c          move.l   $1c(a3), -(a7)
  00244e:  a8 e3                dc.w     $a8e3
  002450:  70 00                moveq    #$0, d0
  002452:  10 1f                move.b   (a7)+, d0
  002454:  66 16                bne.b    $246c  ; -> L246c
  002456:  70 01                moveq    #$1, d0
  002458:  2f 00                move.l   d0, -(a7)
  00245a:  2f 00                move.l   d0, -(a7)
  00245c:  48 6e 00 08          pea.l    $8(a6)
  002460:  72 32                moveq    #$32, d1
  002462:  2f 01                move.l   d1, -(a7)
  002464:  4e ba 3d be          jsr      $6224(pc)  ; -> EngineDispatch
  002468:  4f ef 00 10          lea.l    $10(a7), a7
L246c:
  00246c:  2f 2e 00 08          move.l   $8(a6), -(a7)
  002470:  48 78 0f e4          pea.l    $fe4.w
  002474:  4e ba 62 26          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002478:  58 8f                addq.l   #$4, a7
  00247a:  2f 00                move.l   d0, -(a7)
  00247c:  20 5f                movea.l  (a7)+, a0
  00247e:  4e 90                jsr      (a0)
  002480:  26 6e ff fc          movea.l  -$4(a6), a3
  002484:  4e 5e                unlk     a6
  002486:  4e 74 00 04          rtd      #$4
* GA_ClipRect  -  System 7 $9E34 (same trap slot $FEC, code r=0.92).
* S7: Patch #38 replaces _ClipRect ($A87B); card commands: $32
GA_ClipRect:
  00248a:  4e 56 ff f8          link.w   a6, #$fff8
  00248e:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  002492:  28 6e 00 08          movea.l  $8(a6), a4
  002496:  70 00                moveq    #$0, d0
  002498:  2f 00                move.l   d0, -(a7)
  00249a:  4e ba 63 86          jsr      $8822(pc)  ; -> s7_sub_6f1c
  00249e:  26 40                movea.l  d0, a3
  0024a0:  42 07                clr.b    d7
  0024a2:  20 0b                move.l   a3, d0
  0024a4:  58 8f                addq.l   #$4, a7
  0024a6:  67 4a                beq.b    $24f2  ; -> L24f2
  0024a8:  4e ba ed 86          jsr      $1230(pc)  ; -> GetA5
  0024ac:  20 40                movea.l  d0, a0
  0024ae:  20 50                movea.l  (a0), a0
  0024b0:  20 50                movea.l  (a0), a0
  0024b2:  20 2b 00 1c          move.l   $1c(a3), d0
  0024b6:  b0 a8 00 1c          cmp.l    $1c(a0), d0
  0024ba:  66 36                bne.b    $24f2  ; -> L24f2
  0024bc:  2d 6b 00 1c ff f8    move.l   $1c(a3), -$8(a6)
  0024c2:  20 6e ff f8          movea.l  -$8(a6), a0
  0024c6:  2d 50 ff fc          move.l   (a0), -$4(a6)
  0024ca:  20 6e ff fc          movea.l  -$4(a6), a0
  0024ce:  47 e8 00 02          lea.l    $2(a0), a3
  0024d2:  20 6e ff fc          movea.l  -$4(a6), a0
  0024d6:  30 10                move.w   (a0), d0
  0024d8:  48 c0                ext.l    d0
  0024da:  72 0a                moveq    #$a, d1
  0024dc:  b2 80                cmp.l    d0, d1
  0024de:  66 10                bne.b    $24f0  ; -> L24f0
  0024e0:  20 13                move.l   (a3), d0
  0024e2:  b0 94                cmp.l    (a4), d0
  0024e4:  66 0a                bne.b    $24f0  ; -> L24f0
  0024e6:  20 2b 00 04          move.l   $4(a3), d0
  0024ea:  b0 ac 00 04          cmp.l    $4(a4), d0
  0024ee:  67 02                beq.b    $24f2  ; -> L24f2
L24f0:
  0024f0:  7e 01                moveq    #$1, d7
L24f2:
  0024f2:  2f 0c                move.l   a4, -(a7)
  0024f4:  48 78 0f ec          pea.l    $fec.w
  0024f8:  4e ba 61 a2          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0024fc:  58 8f                addq.l   #$4, a7
  0024fe:  2f 00                move.l   d0, -(a7)
  002500:  20 5f                movea.l  (a7)+, a0
  002502:  4e 90                jsr      (a0)
  002504:  4a 07                tst.b    d7
  002506:  67 16                beq.b    $251e  ; -> L251e
  002508:  70 01                moveq    #$1, d0
  00250a:  2f 00                move.l   d0, -(a7)
  00250c:  2f 00                move.l   d0, -(a7)
  00250e:  48 6e ff f8          pea.l    -$8(a6)
  002512:  72 32                moveq    #$32, d1
  002514:  2f 01                move.l   d1, -(a7)
  002516:  4e ba 3d 0c          jsr      $6224(pc)  ; -> EngineDispatch
  00251a:  4f ef 00 10          lea.l    $10(a7), a7
L251e:
  00251e:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  002524:  4e 5e                unlk     a6
  002526:  4e 74 00 04          rtd      #$4
* GA_HidePen  -  System 7 $9ED0 (same trap slot $1058, code r=0.88).
* S7: Patch #39 replaces _HidePen ($A896); no EngineDispatch command found
GA_HidePen:
  00252a:  48 78 10 58          pea.l    $1058.w
  00252e:  4e ba 61 6c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002532:  58 8f                addq.l   #$4, a7
  002534:  2f 00                move.l   d0, -(a7)
  002536:  20 5f                movea.l  (a7)+, a0
  002538:  4e 90                jsr      (a0)
  00253a:  4e 75                rts
* GA_ShowPen  -  System 7 $9EEA (same trap slot $105C, code r=0.88).
* S7: Patch #40 replaces _ShowPen ($A897); no EngineDispatch command found
GA_ShowPen:
  00253c:  48 78 10 5c          pea.l    $105c.w
  002540:  4e ba 61 5a          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002544:  58 8f                addq.l   #$4, a7
  002546:  2f 00                move.l   d0, -(a7)
  002548:  20 5f                movea.l  (a7)+, a0
  00254a:  4e 90                jsr      (a0)
  00254c:  4e 75                rts
* GA_SetPenState  -  System 7 $9F04 (same trap slot $1064, code r=0.92).
* S7: Patch #11 replaces _SetPenState ($A899); card commands: $2A $35
GA_SetPenState:
  00254e:  4e 56 ff f4          link.w   a6, #$fff4
  002552:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  002556:  28 6e 00 08          movea.l  $8(a6), a4
  00255a:  70 00                moveq    #$0, d0
  00255c:  2f 00                move.l   d0, -(a7)
  00255e:  4e ba 62 c2          jsr      $8822(pc)  ; -> s7_sub_6f1c
  002562:  26 40                movea.l  d0, a3
  002564:  7e 00                moveq    #$0, d7
  002566:  4e ba ec c8          jsr      $1230(pc)  ; -> GetA5
  00256a:  20 40                movea.l  d0, a0
  00256c:  20 50                movea.l  (a0), a0
  00256e:  b7 d0                cmpa.l   (a0), a3
  002570:  58 8f                addq.l   #$4, a7
  002572:  66 5c                bne.b    $25d0  ; -> L25d0
  002574:  30 2c 00 08          move.w   $8(a4), d0
  002578:  48 c0                ext.l    d0
  00257a:  5d c0                slt.b    d0
  00257c:  44 00                neg.b    d0
  00257e:  49 c0                extb.l   d0
  002580:  2f 00                move.l   d0, -(a7)
  002582:  48 6c 00 0a          pea.l    $a(a4)
  002586:  30 2b 00 06          move.w   $6(a3), d0
  00258a:  48 c0                ext.l    d0
  00258c:  5d c0                slt.b    d0
  00258e:  44 00                neg.b    d0
  002590:  49 c0                extb.l   d0
  002592:  2f 00                move.l   d0, -(a7)
  002594:  48 6b 00 3a          pea.l    $3a(a3)
  002598:  4e ba f2 6e          jsr      $1808(pc)  ; -> s7_sub_91aa
  00259c:  72 00                moveq    #$0, d1
  00259e:  12 00                move.b   d0, d1
  0025a0:  4f ef 00 10          lea.l    $10(a7), a7
  0025a4:  66 04                bne.b    $25aa  ; -> L25aa
  0025a6:  7e 01                moveq    #$1, d7
  0025a8:  60 26                bra.b    $25d0  ; -> L25d0
L25aa:
  0025aa:  2d 6c 00 04 ff f4    move.l   $4(a4), -$c(a6)
  0025b0:  20 2b 00 34          move.l   $34(a3), d0
  0025b4:  b0 ae ff f4          cmp.l    -$c(a6), d0
  0025b8:  67 16                beq.b    $25d0  ; -> L25d0
  0025ba:  70 01                moveq    #$1, d0
  0025bc:  2f 00                move.l   d0, -(a7)
  0025be:  2f 00                move.l   d0, -(a7)
  0025c0:  48 6e ff f4          pea.l    -$c(a6)
  0025c4:  72 35                moveq    #$35, d1
  0025c6:  2f 01                move.l   d1, -(a7)
  0025c8:  4e ba 3c 5a          jsr      $6224(pc)  ; -> EngineDispatch
  0025cc:  4f ef 00 10          lea.l    $10(a7), a7
L25d0:
  0025d0:  2f 0c                move.l   a4, -(a7)
  0025d2:  48 78 10 64          pea.l    $1064.w
  0025d6:  4e ba 60 c4          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0025da:  58 8f                addq.l   #$4, a7
  0025dc:  2f 00                move.l   d0, -(a7)
  0025de:  20 5f                movea.l  (a7)+, a0
  0025e0:  4e 90                jsr      (a0)
  0025e2:  4a 87                tst.l    d7
  0025e4:  67 22                beq.b    $2608  ; -> L2608
  0025e6:  70 00                moveq    #$0, d0
  0025e8:  2d 40 ff f8          move.l   d0, -$8(a6)
  0025ec:  2d 47 ff fc          move.l   d7, -$4(a6)
  0025f0:  72 01                moveq    #$1, d1
  0025f2:  2f 01                move.l   d1, -(a7)
  0025f4:  70 02                moveq    #$2, d0
  0025f6:  2f 00                move.l   d0, -(a7)
  0025f8:  48 6e ff f8          pea.l    -$8(a6)
  0025fc:  70 2a                moveq    #$2a, d0
  0025fe:  2f 00                move.l   d0, -(a7)
  002600:  4e ba 3c 22          jsr      $6224(pc)  ; -> EngineDispatch
  002604:  4f ef 00 10          lea.l    $10(a7), a7
L2608:
  002608:  4c ee 18 80 ff e8    movem.l  -$18(a6), d7/a3-a4
  00260e:  4e 5e                unlk     a6
  002610:  4e 74 00 04          rtd      #$4
* GA_PenSize  -  System 7 $9FD0 (same trap slot $106C, code r=0.98).
* S7: Patch #12 replaces _PenSize ($A89B); card commands: $35
GA_PenSize:
  002614:  4e 56 ff fc          link.w   a6, #$fffc
  002618:  48 e7 03 10          movem.l  d6-d7/a3, -(a7)
  00261c:  3c 2e 00 08          move.w   $8(a6), d6
  002620:  3e 2e 00 0a          move.w   $a(a6), d7
  002624:  70 00                moveq    #$0, d0
  002626:  2f 00                move.l   d0, -(a7)
  002628:  4e ba 61 f8          jsr      $8822(pc)  ; -> s7_sub_6f1c
  00262c:  26 40                movea.l  d0, a3
  00262e:  4e ba ec 00          jsr      $1230(pc)  ; -> GetA5
  002632:  20 40                movea.l  d0, a0
  002634:  20 50                movea.l  (a0), a0
  002636:  b7 d0                cmpa.l   (a0), a3
  002638:  58 8f                addq.l   #$4, a7
  00263a:  66 3e                bne.b    $267a  ; -> L267a
  00263c:  3d 46 ff fc          move.w   d6, -$4(a6)
  002640:  3d 47 ff fe          move.w   d7, -$2(a6)
  002644:  20 2b 00 34          move.l   $34(a3), d0
  002648:  b0 ae ff fc          cmp.l    -$4(a6), d0
  00264c:  67 40                beq.b    $268e  ; -> L268e
  00264e:  70 01                moveq    #$1, d0
  002650:  2f 00                move.l   d0, -(a7)
  002652:  2f 00                move.l   d0, -(a7)
  002654:  48 6e ff fc          pea.l    -$4(a6)
  002658:  72 35                moveq    #$35, d1
  00265a:  2f 01                move.l   d1, -(a7)
  00265c:  4e ba 3b c6          jsr      $6224(pc)  ; -> EngineDispatch
  002660:  3f 07                move.w   d7, -(a7)
  002662:  3f 06                move.w   d6, -(a7)
  002664:  48 78 10 6c          pea.l    $106c.w
  002668:  4e ba 60 32          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00266c:  58 8f                addq.l   #$4, a7
  00266e:  2f 00                move.l   d0, -(a7)
  002670:  20 5f                movea.l  (a7)+, a0
  002672:  4e 90                jsr      (a0)
  002674:  4f ef 00 10          lea.l    $10(a7), a7
  002678:  60 14                bra.b    $268e  ; -> L268e
L267a:
  00267a:  3f 07                move.w   d7, -(a7)
  00267c:  3f 06                move.w   d6, -(a7)
  00267e:  48 78 10 6c          pea.l    $106c.w
  002682:  4e ba 60 18          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002686:  58 8f                addq.l   #$4, a7
  002688:  2f 00                move.l   d0, -(a7)
  00268a:  20 5f                movea.l  (a7)+, a0
  00268c:  4e 90                jsr      (a0)
L268e:
  00268e:  4c ee 08 c0 ff f0    movem.l  -$10(a6), d6-d7/a3
  002694:  4e 5e                unlk     a6
  002696:  4e 74 00 04          rtd      #$4
* GA_PenMode  -  System 7 $A060 (identical code).
* S7: Patch #13 replaces _PenMode ($A89C); no EngineDispatch command found
GA_PenMode:
  00269a:  4e 56 00 00          link.w   a6, #$0
  00269e:  3f 2e 00 08          move.w   $8(a6), -(a7)
  0026a2:  48 78 10 70          pea.l    $1070.w
  0026a6:  4e ba 5f f4          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0026aa:  58 8f                addq.l   #$4, a7
  0026ac:  2f 00                move.l   d0, -(a7)
  0026ae:  20 5f                movea.l  (a7)+, a0
  0026b0:  4e 90                jsr      (a0)
  0026b2:  4e 5e                unlk     a6
  0026b4:  4e 74 00 02          rtd      #$2
* GA_PenPat  -  System 7 $A080 (same trap slot $1074, code r=0.91).
* S7: Patch #64 replaces _PenPat ($A89D); card commands: $2A
GA_PenPat:
  0026b8:  4e 56 ff f8          link.w   a6, #$fff8
  0026bc:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  0026c0:  28 6e 00 08          movea.l  $8(a6), a4
  0026c4:  4e ba 28 66          jsr      $4f2c(pc)  ; -> GetD2
  0026c8:  2e 00                move.l   d0, d7
  0026ca:  70 00                moveq    #$0, d0
  0026cc:  2f 00                move.l   d0, -(a7)
  0026ce:  4e ba 61 52          jsr      $8822(pc)  ; -> s7_sub_6f1c
  0026d2:  26 40                movea.l  d0, a3
  0026d4:  4e ba eb 5a          jsr      $1230(pc)  ; -> GetA5
  0026d8:  20 40                movea.l  d0, a0
  0026da:  20 50                movea.l  (a0), a0
  0026dc:  b7 d0                cmpa.l   (a0), a3
  0026de:  58 8f                addq.l   #$4, a7
  0026e0:  66 5c                bne.b    $273e  ; -> L273e
  0026e2:  70 00                moveq    #$0, d0
  0026e4:  2f 00                move.l   d0, -(a7)
  0026e6:  2f 0c                move.l   a4, -(a7)
  0026e8:  32 2b 00 06          move.w   $6(a3), d1
  0026ec:  48 c1                ext.l    d1
  0026ee:  5d c1                slt.b    d1
  0026f0:  44 01                neg.b    d1
  0026f2:  49 c1                extb.l   d1
  0026f4:  2f 01                move.l   d1, -(a7)
  0026f6:  48 6b 00 3a          pea.l    $3a(a3)
  0026fa:  4e ba f1 0c          jsr      $1808(pc)  ; -> s7_sub_91aa
  0026fe:  72 00                moveq    #$0, d1
  002700:  12 00                move.b   d0, d1
  002702:  4f ef 00 10          lea.l    $10(a7), a7
  002706:  66 48                bne.b    $2750  ; -> L2750
  002708:  2f 0c                move.l   a4, -(a7)
  00270a:  48 78 10 74          pea.l    $1074.w
  00270e:  4e ba 5f 8c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002712:  58 8f                addq.l   #$4, a7
  002714:  2f 00                move.l   d0, -(a7)
  002716:  20 5f                movea.l  (a7)+, a0
  002718:  4e 90                jsr      (a0)
  00271a:  70 00                moveq    #$0, d0
  00271c:  2d 40 ff f8          move.l   d0, -$8(a6)
  002720:  72 01                moveq    #$1, d1
  002722:  2d 41 ff fc          move.l   d1, -$4(a6)
  002726:  2f 01                move.l   d1, -(a7)
  002728:  70 02                moveq    #$2, d0
  00272a:  2f 00                move.l   d0, -(a7)
  00272c:  48 6e ff f8          pea.l    -$8(a6)
  002730:  70 2a                moveq    #$2a, d0
  002732:  2f 00                move.l   d0, -(a7)
  002734:  4e ba 3a ee          jsr      $6224(pc)  ; -> EngineDispatch
  002738:  4f ef 00 10          lea.l    $10(a7), a7
  00273c:  60 12                bra.b    $2750  ; -> L2750
L273e:
  00273e:  2f 0c                move.l   a4, -(a7)
  002740:  48 78 10 74          pea.l    $1074.w
  002744:  4e ba 5f 56          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002748:  58 8f                addq.l   #$4, a7
  00274a:  2f 00                move.l   d0, -(a7)
  00274c:  20 5f                movea.l  (a7)+, a0
  00274e:  4e 90                jsr      (a0)
L2750:
  002750:  2f 07                move.l   d7, -(a7)
  002752:  4e ba 27 e4          jsr      $4f38(pc)  ; -> SetD2
  002756:  58 8f                addq.l   #$4, a7
  002758:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  00275e:  4e 5e                unlk     a6
  002760:  4e 74 00 04          rtd      #$4
* GA_BackPat  -  System 7 $A13A (same trap slot $FF0, code r=0.92).
* S7: Patch #65 replaces _BackPat ($A87C); card commands: $2A
GA_BackPat:
  002764:  4e 56 ff f8          link.w   a6, #$fff8
  002768:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00276c:  28 6e 00 08          movea.l  $8(a6), a4
  002770:  70 00                moveq    #$0, d0
  002772:  2f 00                move.l   d0, -(a7)
  002774:  4e ba 60 ac          jsr      $8822(pc)  ; -> s7_sub_6f1c
  002778:  26 40                movea.l  d0, a3
  00277a:  4e ba ea b4          jsr      $1230(pc)  ; -> GetA5
  00277e:  20 40                movea.l  d0, a0
  002780:  20 50                movea.l  (a0), a0
  002782:  b7 d0                cmpa.l   (a0), a3
  002784:  58 8f                addq.l   #$4, a7
  002786:  66 5c                bne.b    $27e4  ; -> L27e4
  002788:  70 00                moveq    #$0, d0
  00278a:  2f 00                move.l   d0, -(a7)
  00278c:  2f 0c                move.l   a4, -(a7)
  00278e:  32 2b 00 06          move.w   $6(a3), d1
  002792:  48 c1                ext.l    d1
  002794:  5d c1                slt.b    d1
  002796:  44 01                neg.b    d1
  002798:  49 c1                extb.l   d1
  00279a:  2f 01                move.l   d1, -(a7)
  00279c:  48 6b 00 20          pea.l    $20(a3)
  0027a0:  4e ba f0 66          jsr      $1808(pc)  ; -> s7_sub_91aa
  0027a4:  72 00                moveq    #$0, d1
  0027a6:  12 00                move.b   d0, d1
  0027a8:  4f ef 00 10          lea.l    $10(a7), a7
  0027ac:  66 48                bne.b    $27f6  ; -> L27f6
  0027ae:  2f 0c                move.l   a4, -(a7)
  0027b0:  48 78 0f f0          pea.l    $ff0.w
  0027b4:  4e ba 5e e6          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0027b8:  58 8f                addq.l   #$4, a7
  0027ba:  2f 00                move.l   d0, -(a7)
  0027bc:  20 5f                movea.l  (a7)+, a0
  0027be:  4e 90                jsr      (a0)
  0027c0:  70 00                moveq    #$0, d0
  0027c2:  2d 40 ff f8          move.l   d0, -$8(a6)
  0027c6:  72 02                moveq    #$2, d1
  0027c8:  2d 41 ff fc          move.l   d1, -$4(a6)
  0027cc:  70 01                moveq    #$1, d0
  0027ce:  2f 00                move.l   d0, -(a7)
  0027d0:  2f 01                move.l   d1, -(a7)
  0027d2:  48 6e ff f8          pea.l    -$8(a6)
  0027d6:  70 2a                moveq    #$2a, d0
  0027d8:  2f 00                move.l   d0, -(a7)
  0027da:  4e ba 3a 48          jsr      $6224(pc)  ; -> EngineDispatch
  0027de:  4f ef 00 10          lea.l    $10(a7), a7
  0027e2:  60 12                bra.b    $27f6  ; -> L27f6
L27e4:
  0027e4:  2f 0c                move.l   a4, -(a7)
  0027e6:  48 78 0f f0          pea.l    $ff0.w
  0027ea:  4e ba 5e b0          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0027ee:  58 8f                addq.l   #$4, a7
  0027f0:  2f 00                move.l   d0, -(a7)
  0027f2:  20 5f                movea.l  (a7)+, a0
  0027f4:  4e 90                jsr      (a0)
L27f6:
  0027f6:  4c ee 18 00 ff f0    movem.l  -$10(a6), a3-a4
  0027fc:  4e 5e                unlk     a6
  0027fe:  4e 74 00 04          rtd      #$4
* GA_PenNormal  -  System 7 $A1E2 (same trap slot $1078, code r=0.94).
* S7: Patch #14 replaces _PenNormal ($A89E); card commands: $2A $35
GA_PenNormal:
  002802:  4e 56 ff f4          link.w   a6, #$fff4
  002806:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  00280a:  49 ee ff f8          lea.l    -$8(a6), a4
  00280e:  70 00                moveq    #$0, d0
  002810:  2f 00                move.l   d0, -(a7)
  002812:  4e ba 60 0e          jsr      $8822(pc)  ; -> s7_sub_6f1c
  002816:  26 40                movea.l  d0, a3
  002818:  7e 00                moveq    #$0, d7
  00281a:  20 0b                move.l   a3, d0
  00281c:  58 8f                addq.l   #$4, a7
  00281e:  67 72                beq.b    $2892  ; -> L2892
  002820:  4e ba ea 0e          jsr      $1230(pc)  ; -> GetA5
  002824:  20 40                movea.l  d0, a0
  002826:  20 50                movea.l  (a0), a0
  002828:  b7 d0                cmpa.l   (a0), a3
  00282a:  66 66                bne.b    $2892  ; -> L2892
  00282c:  3d 7c 00 01 ff f6    move.w   #$1, -$a(a6)
  002832:  3d 7c 00 01 ff f4    move.w   #$1, -$c(a6)
  002838:  20 2b 00 34          move.l   $34(a3), d0
  00283c:  b0 ae ff f4          cmp.l    -$c(a6), d0
  002840:  67 16                beq.b    $2858  ; -> L2858
  002842:  70 01                moveq    #$1, d0
  002844:  2f 00                move.l   d0, -(a7)
  002846:  2f 00                move.l   d0, -(a7)
  002848:  48 6e ff f4          pea.l    -$c(a6)
  00284c:  72 35                moveq    #$35, d1
  00284e:  2f 01                move.l   d1, -(a7)
  002850:  4e ba 39 d2          jsr      $6224(pc)  ; -> EngineDispatch
  002854:  4f ef 00 10          lea.l    $10(a7), a7
L2858:
  002858:  70 00                moveq    #$0, d0
  00285a:  2f 00                move.l   d0, -(a7)
  00285c:  4e ba e9 d2          jsr      $1230(pc)  ; -> GetA5
  002860:  20 40                movea.l  d0, a0
  002862:  20 10                move.l   (a0), d0
  002864:  90 bc 00 00 00 ca    sub.l    #$ca, d0
  00286a:  20 40                movea.l  d0, a0
  00286c:  48 68 00 ba          pea.l    $ba(a0)
  002870:  30 2b 00 06          move.w   $6(a3), d0
  002874:  48 c0                ext.l    d0
  002876:  5d c0                slt.b    d0
  002878:  44 00                neg.b    d0
  00287a:  49 c0                extb.l   d0
  00287c:  2f 00                move.l   d0, -(a7)
  00287e:  48 6b 00 3a          pea.l    $3a(a3)
  002882:  4e ba ef 84          jsr      $1808(pc)  ; -> s7_sub_91aa
  002886:  72 00                moveq    #$0, d1
  002888:  12 00                move.b   d0, d1
  00288a:  4f ef 00 10          lea.l    $10(a7), a7
  00288e:  66 02                bne.b    $2892  ; -> L2892
  002890:  7e 01                moveq    #$1, d7
L2892:
  002892:  48 78 10 78          pea.l    $1078.w
  002896:  4e ba 5e 04          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00289a:  58 8f                addq.l   #$4, a7
  00289c:  2f 00                move.l   d0, -(a7)
  00289e:  20 5f                movea.l  (a7)+, a0
  0028a0:  4e 90                jsr      (a0)
  0028a2:  4a 87                tst.l    d7
  0028a4:  67 1e                beq.b    $28c4  ; -> L28c4
  0028a6:  70 00                moveq    #$0, d0
  0028a8:  28 80                move.l   d0, (a4)
  0028aa:  29 47 00 04          move.l   d7, $4(a4)
  0028ae:  72 01                moveq    #$1, d1
  0028b0:  2f 01                move.l   d1, -(a7)
  0028b2:  70 02                moveq    #$2, d0
  0028b4:  2f 00                move.l   d0, -(a7)
  0028b6:  2f 0c                move.l   a4, -(a7)
  0028b8:  70 2a                moveq    #$2a, d0
  0028ba:  2f 00                move.l   d0, -(a7)
  0028bc:  4e ba 39 66          jsr      $6224(pc)  ; -> EngineDispatch
  0028c0:  4f ef 00 10          lea.l    $10(a7), a7
L28c4:
  0028c4:  4c ee 18 80 ff e8    movem.l  -$18(a6), d7/a3-a4
  0028ca:  4e 5e                unlk     a6
  0028cc:  4e 75                rts
* GA_ColorBit  -  System 7 $A2B8 (same trap slot $F90, code r=0.87).
* S7: Patch #42 replaces _ColorBit ($A864); card commands: $26
GA_ColorBit:
  0028ce:  48 e7 01 10          movem.l  d7/a3, -(a7)
  0028d2:  3e 2f 00 0c          move.w   $c(a7), d7
  0028d6:  70 00                moveq    #$0, d0
  0028d8:  2f 00                move.l   d0, -(a7)
  0028da:  4e ba 5f 46          jsr      $8822(pc)  ; -> s7_sub_6f1c
  0028de:  26 40                movea.l  d0, a3
  0028e0:  4e ba e9 4e          jsr      $1230(pc)  ; -> GetA5
  0028e4:  20 40                movea.l  d0, a0
  0028e6:  20 50                movea.l  (a0), a0
  0028e8:  b7 d0                cmpa.l   (a0), a3
  0028ea:  58 8f                addq.l   #$4, a7
  0028ec:  66 22                bne.b    $2910  ; -> L2910
  0028ee:  48 c7                ext.l    d7
  0028f0:  30 2b 00 58          move.w   $58(a3), d0
  0028f4:  48 c0                ext.l    d0
  0028f6:  be 80                cmp.l    d0, d7
  0028f8:  67 16                beq.b    $2910  ; -> L2910
  0028fa:  70 01                moveq    #$1, d0
  0028fc:  2f 00                move.l   d0, -(a7)
  0028fe:  72 00                moveq    #$0, d1
  002900:  2f 01                move.l   d1, -(a7)
  002902:  2f 01                move.l   d1, -(a7)
  002904:  70 26                moveq    #$26, d0
  002906:  2f 00                move.l   d0, -(a7)
  002908:  4e ba 39 1a          jsr      $6224(pc)  ; -> EngineDispatch
  00290c:  4f ef 00 10          lea.l    $10(a7), a7
L2910:
  002910:  3f 07                move.w   d7, -(a7)
  002912:  48 78 0f 90          pea.l    $f90.w
  002916:  4e ba 5d 84          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00291a:  58 8f                addq.l   #$4, a7
  00291c:  2f 00                move.l   d0, -(a7)
  00291e:  20 5f                movea.l  (a7)+, a0
  002920:  4e 90                jsr      (a0)
  002922:  4c df 08 80          movem.l  (a7)+, d7/a3
  002926:  4e 74 00 02          rtd      #$2
* GA_OpenRgn  -  System 7 $A31E (same trap slot $1168, code r=0.88).
* S7: Patch #43 replaces _OpenRgn ($A8DA); no EngineDispatch command found
GA_OpenRgn:
  00292a:  48 78 11 68          pea.l    $1168.w
  00292e:  4e ba 5d 6c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002932:  58 8f                addq.l   #$4, a7
  002934:  2f 00                move.l   d0, -(a7)
  002936:  20 5f                movea.l  (a7)+, a0
  002938:  4e 90                jsr      (a0)
  00293a:  4e 75                rts
* GA_OpenPicture  -  System 7 $A338 (same trap slot $11CC, code r=0.89).
* S7: Patch #44 replaces _OpenPicture ($A8F3); no EngineDispatch command found
GA_OpenPicture:
  00293c:  4e 56 00 00          link.w   a6, #$0
  002940:  2f 0b                move.l   a3, -(a7)
  002942:  26 6e 00 08          movea.l  $8(a6), a3
  002946:  59 8f                subq.l   #$4, a7
  002948:  2f 0b                move.l   a3, -(a7)
  00294a:  48 78 11 cc          pea.l    $11cc.w
  00294e:  4e ba 5d 4c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002952:  58 8f                addq.l   #$4, a7
  002954:  2f 00                move.l   d0, -(a7)
  002956:  20 5f                movea.l  (a7)+, a0
  002958:  4e 90                jsr      (a0)
  00295a:  2d 5f 00 0c          move.l   (a7)+, $c(a6)
  00295e:  26 6e ff fc          movea.l  -$4(a6), a3
  002962:  4e 5e                unlk     a6
  002964:  4e 74 00 04          rtd      #$4
* GA_OpenPoly  -  System 7 $A35E (identical code).
* S7: Patch #45 replaces _OpenPoly ($A8CB); no EngineDispatch command found
GA_OpenPoly:
  002968:  4e 56 00 00          link.w   a6, #$0
  00296c:  59 8f                subq.l   #$4, a7
  00296e:  48 78 11 2c          pea.l    $112c.w
  002972:  4e ba 5d 28          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002976:  58 8f                addq.l   #$4, a7
  002978:  2f 00                move.l   d0, -(a7)
  00297a:  20 5f                movea.l  (a7)+, a0
  00297c:  4e 90                jsr      (a0)
  00297e:  2d 5f 00 08          move.l   (a7)+, $8(a6)
  002982:  4e 5e                unlk     a6
  002984:  4e 75                rts
* GA_SectRect  -  System 7 $A37E (same trap slot $10A8, code r=0.98).
* S7: Patch #78 replaces _SectRect ($A8AA); card commands: $10 $32
GA_SectRect:
  002986:  4e 56 ff f8          link.w   a6, #$fff8
  00298a:  48 e7 07 18          movem.l  d5-d7/a3-a4, -(a7)
  00298e:  26 6e 00 08          movea.l  $8(a6), a3
  002992:  20 78 08 88          movea.l  $888.w, a0
  002996:  20 50                movea.l  (a0), a0
  002998:  20 50                movea.l  (a0), a0
  00299a:  20 68 02 14          movea.l  $214(a0), a0
  00299e:  28 50                movea.l  (a0), a4
  0029a0:  4a ac 00 c8          tst.l    $c8(a4)
  0029a4:  67 00 00 98          beq.w    $2a3e  ; -> L2a3e
  0029a8:  20 6c 01 20          movea.l  $120(a4), a0
  0029ac:  20 50                movea.l  (a0), a0
  0029ae:  54 88                addq.l   #$2, a0
  0029b0:  b1 cb                cmpa.l   a3, a0
  0029b2:  57 c7                seq.b    d7
  0029b4:  44 07                neg.b    d7
  0029b6:  20 6c 01 24          movea.l  $124(a4), a0
  0029ba:  20 50                movea.l  (a0), a0
  0029bc:  54 88                addq.l   #$2, a0
  0029be:  b1 cb                cmpa.l   a3, a0
  0029c0:  57 c5                seq.b    d5
  0029c2:  44 05                neg.b    d5
  0029c4:  4a 07                tst.b    d7
  0029c6:  66 04                bne.b    $29cc  ; -> L29cc
  0029c8:  4a 05                tst.b    d5
  0029ca:  67 72                beq.b    $2a3e  ; -> L2a3e
L29cc:
  0029cc:  41 ee ff f8          lea.l    -$8(a6), a0
  0029d0:  22 4b                movea.l  a3, a1
  0029d2:  20 d9                move.l   (a1)+, (a0)+
  0029d4:  20 d9                move.l   (a1)+, (a0)+
  0029d6:  55 8f                subq.l   #$2, a7
  0029d8:  2f 2e 00 10          move.l   $10(a6), -(a7)
  0029dc:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  0029e0:  2f 0b                move.l   a3, -(a7)
  0029e2:  48 78 10 a8          pea.l    $10a8.w
  0029e6:  4e ba 5c b4          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0029ea:  58 8f                addq.l   #$4, a7
  0029ec:  2f 00                move.l   d0, -(a7)
  0029ee:  20 5f                movea.l  (a7)+, a0
  0029f0:  4e 90                jsr      (a0)
  0029f2:  1c 1f                move.b   (a7)+, d6
  0029f4:  20 2e ff f8          move.l   -$8(a6), d0
  0029f8:  b0 93                cmp.l    (a3), d0
  0029fa:  66 0a                bne.b    $2a06  ; -> L2a06
  0029fc:  20 2e ff fc          move.l   -$4(a6), d0
  002a00:  b0 ab 00 04          cmp.l    $4(a3), d0
  002a04:  67 32                beq.b    $2a38  ; -> L2a38
L2a06:
  002a06:  4a 07                tst.b    d7
  002a08:  67 18                beq.b    $2a22  ; -> L2a22
  002a0a:  70 01                moveq    #$1, d0
  002a0c:  2f 00                move.l   d0, -(a7)
  002a0e:  2f 00                move.l   d0, -(a7)
  002a10:  48 6c 01 20          pea.l    $120(a4)
  002a14:  72 10                moveq    #$10, d1
  002a16:  2f 01                move.l   d1, -(a7)
  002a18:  4e ba 38 0a          jsr      $6224(pc)  ; -> EngineDispatch
  002a1c:  4f ef 00 10          lea.l    $10(a7), a7
  002a20:  60 16                bra.b    $2a38  ; -> L2a38
L2a22:
  002a22:  70 01                moveq    #$1, d0
  002a24:  2f 00                move.l   d0, -(a7)
  002a26:  2f 00                move.l   d0, -(a7)
  002a28:  48 6c 01 24          pea.l    $124(a4)
  002a2c:  72 32                moveq    #$32, d1
  002a2e:  2f 01                move.l   d1, -(a7)
  002a30:  4e ba 37 f2          jsr      $6224(pc)  ; -> EngineDispatch
  002a34:  4f ef 00 10          lea.l    $10(a7), a7
L2a38:
  002a38:  1d 46 00 14          move.b   d6, $14(a6)
  002a3c:  60 20                bra.b    $2a5e  ; -> L2a5e
L2a3e:
  002a3e:  55 8f                subq.l   #$2, a7
  002a40:  2f 2e 00 10          move.l   $10(a6), -(a7)
  002a44:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  002a48:  2f 0b                move.l   a3, -(a7)
  002a4a:  48 78 10 a8          pea.l    $10a8.w
  002a4e:  4e ba 5c 4c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002a52:  58 8f                addq.l   #$4, a7
  002a54:  2f 00                move.l   d0, -(a7)
  002a56:  20 5f                movea.l  (a7)+, a0
  002a58:  4e 90                jsr      (a0)
  002a5a:  1d 5f 00 14          move.b   (a7)+, $14(a6)
L2a5e:
  002a5e:  4c ee 18 e0 ff e4    movem.l  -$1c(a6), d5-d7/a3-a4
  002a64:  4e 5e                unlk     a6
  002a66:  4e 74 00 0c          rtd      #$c
* GA_CopyRgn  -  System 7 $A472 (same trap slot $1170, code r=0.97).
* S7: Patch #46 replaces _CopyRgn ($A8DC); card commands: $10 $32
GA_CopyRgn:
  002a6a:  4e 56 00 00          link.w   a6, #$0
  002a6e:  48 e7 00 18          movem.l  a3-a4, -(a7)
  002a72:  28 6e 00 0c          movea.l  $c(a6), a4
  002a76:  20 78 08 88          movea.l  $888.w, a0
  002a7a:  20 50                movea.l  (a0), a0
  002a7c:  20 50                movea.l  (a0), a0
  002a7e:  26 68 02 14          movea.l  $214(a0), a3
  002a82:  55 8f                subq.l   #$2, a7
  002a84:  2f 0c                move.l   a4, -(a7)
  002a86:  2f 2e 00 08          move.l   $8(a6), -(a7)
  002a8a:  a8 e3                dc.w     $a8e3
  002a8c:  70 00                moveq    #$0, d0
  002a8e:  10 1f                move.b   (a7)+, d0
  002a90:  66 5c                bne.b    $2aee  ; -> L2aee
  002a92:  2f 0c                move.l   a4, -(a7)
  002a94:  2f 2e 00 08          move.l   $8(a6), -(a7)
  002a98:  48 78 11 70          pea.l    $1170.w
  002a9c:  4e ba 5b fe          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002aa0:  58 8f                addq.l   #$4, a7
  002aa2:  2f 00                move.l   d0, -(a7)
  002aa4:  20 5f                movea.l  (a7)+, a0
  002aa6:  4e 90                jsr      (a0)
  002aa8:  20 53                movea.l  (a3), a0
  002aaa:  20 2e 00 08          move.l   $8(a6), d0
  002aae:  b0 a8 01 20          cmp.l    $120(a0), d0
  002ab2:  66 18                bne.b    $2acc  ; -> L2acc
  002ab4:  70 01                moveq    #$1, d0
  002ab6:  2f 00                move.l   d0, -(a7)
  002ab8:  2f 00                move.l   d0, -(a7)
  002aba:  48 6e 00 08          pea.l    $8(a6)
  002abe:  72 10                moveq    #$10, d1
  002ac0:  2f 01                move.l   d1, -(a7)
  002ac2:  4e ba 37 60          jsr      $6224(pc)  ; -> EngineDispatch
  002ac6:  4f ef 00 10          lea.l    $10(a7), a7
  002aca:  60 22                bra.b    $2aee  ; -> L2aee
L2acc:
  002acc:  20 53                movea.l  (a3), a0
  002ace:  20 2e 00 08          move.l   $8(a6), d0
  002ad2:  b0 a8 01 24          cmp.l    $124(a0), d0
  002ad6:  66 16                bne.b    $2aee  ; -> L2aee
  002ad8:  70 01                moveq    #$1, d0
  002ada:  2f 00                move.l   d0, -(a7)
  002adc:  2f 00                move.l   d0, -(a7)
  002ade:  48 6e 00 08          pea.l    $8(a6)
  002ae2:  72 32                moveq    #$32, d1
  002ae4:  2f 01                move.l   d1, -(a7)
  002ae6:  4e ba 37 3c          jsr      $6224(pc)  ; -> EngineDispatch
  002aea:  4f ef 00 10          lea.l    $10(a7), a7
L2aee:
  002aee:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  002af4:  4e 5e                unlk     a6
  002af6:  4e 74 00 08          rtd      #$8
* GA_SetEmptyRgn  -  System 7 $A506 (same trap slot $1174, code r=0.96).
* S7: Patch #63 replaces _SetEmptyRgn ($A8DD); card commands: $10 $32
GA_SetEmptyRgn:
  002afa:  4e 56 ff fc          link.w   a6, #$fffc
  002afe:  48 e7 00 18          movem.l  a3-a4, -(a7)
  002b02:  20 78 08 88          movea.l  $888.w, a0
  002b06:  20 50                movea.l  (a0), a0
  002b08:  20 50                movea.l  (a0), a0
  002b0a:  2d 68 02 14 ff fc    move.l   $214(a0), -$4(a6)
  002b10:  20 6e 00 08          movea.l  $8(a6), a0
  002b14:  28 50                movea.l  (a0), a4
  002b16:  47 ec 00 02          lea.l    $2(a4), a3
  002b1a:  30 14                move.w   (a4), d0
  002b1c:  48 c0                ext.l    d0
  002b1e:  72 0a                moveq    #$a, d1
  002b20:  b2 80                cmp.l    d0, d1
  002b22:  66 0a                bne.b    $2b2e  ; -> L2b2e
  002b24:  4a 93                tst.l    (a3)
  002b26:  66 06                bne.b    $2b2e  ; -> L2b2e
  002b28:  4a ab 00 04          tst.l    $4(a3)
  002b2c:  67 62                beq.b    $2b90  ; -> L2b90
L2b2e:
  002b2e:  2f 2e 00 08          move.l   $8(a6), -(a7)
  002b32:  48 78 11 74          pea.l    $1174.w
  002b36:  4e ba 5b 64          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002b3a:  58 8f                addq.l   #$4, a7
  002b3c:  2f 00                move.l   d0, -(a7)
  002b3e:  20 5f                movea.l  (a7)+, a0
  002b40:  4e 90                jsr      (a0)
  002b42:  20 6e ff fc          movea.l  -$4(a6), a0
  002b46:  20 50                movea.l  (a0), a0
  002b48:  20 2e 00 08          move.l   $8(a6), d0
  002b4c:  b0 a8 01 20          cmp.l    $120(a0), d0
  002b50:  66 18                bne.b    $2b6a  ; -> L2b6a
  002b52:  70 01                moveq    #$1, d0
  002b54:  2f 00                move.l   d0, -(a7)
  002b56:  2f 00                move.l   d0, -(a7)
  002b58:  48 6e 00 08          pea.l    $8(a6)
  002b5c:  72 10                moveq    #$10, d1
  002b5e:  2f 01                move.l   d1, -(a7)
  002b60:  4e ba 36 c2          jsr      $6224(pc)  ; -> EngineDispatch
  002b64:  4f ef 00 10          lea.l    $10(a7), a7
  002b68:  60 26                bra.b    $2b90  ; -> L2b90
L2b6a:
  002b6a:  20 6e ff fc          movea.l  -$4(a6), a0
  002b6e:  20 50                movea.l  (a0), a0
  002b70:  20 2e 00 08          move.l   $8(a6), d0
  002b74:  b0 a8 01 24          cmp.l    $124(a0), d0
  002b78:  66 16                bne.b    $2b90  ; -> L2b90
  002b7a:  70 01                moveq    #$1, d0
  002b7c:  2f 00                move.l   d0, -(a7)
  002b7e:  2f 00                move.l   d0, -(a7)
  002b80:  48 6e 00 08          pea.l    $8(a6)
  002b84:  72 32                moveq    #$32, d1
  002b86:  2f 01                move.l   d1, -(a7)
  002b88:  4e ba 36 9a          jsr      $6224(pc)  ; -> EngineDispatch
  002b8c:  4f ef 00 10          lea.l    $10(a7), a7
L2b90:
  002b90:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  002b96:  4e 5e                unlk     a6
  002b98:  4e 74 00 04          rtd      #$4
* GA_SetRecRgn  -  System 7 $A5AA (same trap slot $1178, code r=0.83).
* S7: Patch #47 replaces _SetRecRgn ($A8DE); card commands: $10 $32
GA_SetRecRgn:
  002b9c:  4e 56 ff fc          link.w   a6, #$fffc
  002ba0:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  002ba4:  38 2e 00 08          move.w   $8(a6), d4
  002ba8:  3a 2e 00 0a          move.w   $a(a6), d5
  002bac:  3c 2e 00 0c          move.w   $c(a6), d6
  002bb0:  3e 2e 00 0e          move.w   $e(a6), d7
  002bb4:  20 78 08 88          movea.l  $888.w, a0
  002bb8:  20 50                movea.l  (a0), a0
  002bba:  20 50                movea.l  (a0), a0
  002bbc:  2d 68 02 14 ff fc    move.l   $214(a0), -$4(a6)
  002bc2:  20 6e 00 10          movea.l  $10(a6), a0
  002bc6:  28 50                movea.l  (a0), a4
  002bc8:  47 ec 00 02          lea.l    $2(a4), a3
  002bcc:  30 14                move.w   (a4), d0
  002bce:  48 c0                ext.l    d0
  002bd0:  72 0a                moveq    #$a, d1
  002bd2:  b2 80                cmp.l    d0, d1
  002bd4:  66 2e                bne.b    $2c04  ; -> L2c04
  002bd6:  48 c7                ext.l    d7
  002bd8:  30 2b 00 02          move.w   $2(a3), d0
  002bdc:  48 c0                ext.l    d0
  002bde:  be 80                cmp.l    d0, d7
  002be0:  66 22                bne.b    $2c04  ; -> L2c04
  002be2:  48 c6                ext.l    d6
  002be4:  30 13                move.w   (a3), d0
  002be6:  48 c0                ext.l    d0
  002be8:  bc 80                cmp.l    d0, d6
  002bea:  66 18                bne.b    $2c04  ; -> L2c04
  002bec:  48 c5                ext.l    d5
  002bee:  30 2b 00 06          move.w   $6(a3), d0
  002bf2:  48 c0                ext.l    d0
  002bf4:  ba 80                cmp.l    d0, d5
  002bf6:  66 0c                bne.b    $2c04  ; -> L2c04
  002bf8:  48 c4                ext.l    d4
  002bfa:  30 2b 00 04          move.w   $4(a3), d0
  002bfe:  48 c0                ext.l    d0
  002c00:  b8 80                cmp.l    d0, d4
  002c02:  67 6a                beq.b    $2c6e  ; -> L2c6e
L2c04:
  002c04:  2f 2e 00 10          move.l   $10(a6), -(a7)
  002c08:  3f 07                move.w   d7, -(a7)
  002c0a:  3f 06                move.w   d6, -(a7)
  002c0c:  3f 05                move.w   d5, -(a7)
  002c0e:  3f 04                move.w   d4, -(a7)
  002c10:  48 78 11 78          pea.l    $1178.w
  002c14:  4e ba 5a 86          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002c18:  58 8f                addq.l   #$4, a7
  002c1a:  2f 00                move.l   d0, -(a7)
  002c1c:  20 5f                movea.l  (a7)+, a0
  002c1e:  4e 90                jsr      (a0)
  002c20:  20 6e ff fc          movea.l  -$4(a6), a0
  002c24:  20 50                movea.l  (a0), a0
  002c26:  20 2e 00 10          move.l   $10(a6), d0
  002c2a:  b0 a8 01 20          cmp.l    $120(a0), d0
  002c2e:  66 18                bne.b    $2c48  ; -> L2c48
  002c30:  70 01                moveq    #$1, d0
  002c32:  2f 00                move.l   d0, -(a7)
  002c34:  2f 00                move.l   d0, -(a7)
  002c36:  48 6e 00 10          pea.l    $10(a6)
  002c3a:  72 10                moveq    #$10, d1
  002c3c:  2f 01                move.l   d1, -(a7)
  002c3e:  4e ba 35 e4          jsr      $6224(pc)  ; -> EngineDispatch
  002c42:  4f ef 00 10          lea.l    $10(a7), a7
  002c46:  60 26                bra.b    $2c6e  ; -> L2c6e
L2c48:
  002c48:  20 6e ff fc          movea.l  -$4(a6), a0
  002c4c:  20 50                movea.l  (a0), a0
  002c4e:  20 2e 00 10          move.l   $10(a6), d0
  002c52:  b0 a8 01 24          cmp.l    $124(a0), d0
  002c56:  66 16                bne.b    $2c6e  ; -> L2c6e
  002c58:  70 01                moveq    #$1, d0
  002c5a:  2f 00                move.l   d0, -(a7)
  002c5c:  2f 00                move.l   d0, -(a7)
  002c5e:  48 6e 00 10          pea.l    $10(a6)
  002c62:  72 32                moveq    #$32, d1
  002c64:  2f 01                move.l   d1, -(a7)
  002c66:  4e ba 35 bc          jsr      $6224(pc)  ; -> EngineDispatch
  002c6a:  4f ef 00 10          lea.l    $10(a7), a7
L2c6e:
  002c6e:  4c ee 18 f0 ff e4    movem.l  -$1c(a6), d4-d7/a3-a4
  002c74:  4e 5e                unlk     a6
  002c76:  4e 74 00 0c          rtd      #$c
* GA_RectRgn  -  System 7 $A672 (same trap slot $117C, code r=0.94).
* S7: Patch #48 replaces _RectRgn ($A8DF); card commands: $10 $32
GA_RectRgn:
  002c7a:  4e 56 ff f8          link.w   a6, #$fff8
  002c7e:  48 e7 00 18          movem.l  a3-a4, -(a7)
  002c82:  26 6e 00 08          movea.l  $8(a6), a3
  002c86:  20 78 08 88          movea.l  $888.w, a0
  002c8a:  20 50                movea.l  (a0), a0
  002c8c:  20 50                movea.l  (a0), a0
  002c8e:  2d 68 02 14 ff f8    move.l   $214(a0), -$8(a6)
  002c94:  20 6e 00 0c          movea.l  $c(a6), a0
  002c98:  2d 50 ff fc          move.l   (a0), -$4(a6)
  002c9c:  20 6e ff fc          movea.l  -$4(a6), a0
  002ca0:  49 e8 00 02          lea.l    $2(a0), a4
  002ca4:  20 6e ff fc          movea.l  -$4(a6), a0
  002ca8:  30 10                move.w   (a0), d0
  002caa:  48 c0                ext.l    d0
  002cac:  72 0a                moveq    #$a, d1
  002cae:  b2 80                cmp.l    d0, d1
  002cb0:  66 10                bne.b    $2cc2  ; -> L2cc2
  002cb2:  20 14                move.l   (a4), d0
  002cb4:  b0 93                cmp.l    (a3), d0
  002cb6:  66 0a                bne.b    $2cc2  ; -> L2cc2
  002cb8:  20 2c 00 04          move.l   $4(a4), d0
  002cbc:  b0 ab 00 04          cmp.l    $4(a3), d0
  002cc0:  67 64                beq.b    $2d26  ; -> L2d26
L2cc2:
  002cc2:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  002cc6:  2f 0b                move.l   a3, -(a7)
  002cc8:  48 78 11 7c          pea.l    $117c.w
  002ccc:  4e ba 59 ce          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002cd0:  58 8f                addq.l   #$4, a7
  002cd2:  2f 00                move.l   d0, -(a7)
  002cd4:  20 5f                movea.l  (a7)+, a0
  002cd6:  4e 90                jsr      (a0)
  002cd8:  20 6e ff f8          movea.l  -$8(a6), a0
  002cdc:  20 50                movea.l  (a0), a0
  002cde:  20 2e 00 0c          move.l   $c(a6), d0
  002ce2:  b0 a8 01 20          cmp.l    $120(a0), d0
  002ce6:  66 18                bne.b    $2d00  ; -> L2d00
  002ce8:  70 01                moveq    #$1, d0
  002cea:  2f 00                move.l   d0, -(a7)
  002cec:  2f 00                move.l   d0, -(a7)
  002cee:  48 6e 00 0c          pea.l    $c(a6)
  002cf2:  72 10                moveq    #$10, d1
  002cf4:  2f 01                move.l   d1, -(a7)
  002cf6:  4e ba 35 2c          jsr      $6224(pc)  ; -> EngineDispatch
  002cfa:  4f ef 00 10          lea.l    $10(a7), a7
  002cfe:  60 26                bra.b    $2d26  ; -> L2d26
L2d00:
  002d00:  20 6e ff f8          movea.l  -$8(a6), a0
  002d04:  20 50                movea.l  (a0), a0
  002d06:  20 2e 00 0c          move.l   $c(a6), d0
  002d0a:  b0 a8 01 24          cmp.l    $124(a0), d0
  002d0e:  66 16                bne.b    $2d26  ; -> L2d26
  002d10:  70 01                moveq    #$1, d0
  002d12:  2f 00                move.l   d0, -(a7)
  002d14:  2f 00                move.l   d0, -(a7)
  002d16:  48 6e 00 0c          pea.l    $c(a6)
  002d1a:  72 32                moveq    #$32, d1
  002d1c:  2f 01                move.l   d1, -(a7)
  002d1e:  4e ba 35 04          jsr      $6224(pc)  ; -> EngineDispatch
  002d22:  4f ef 00 10          lea.l    $10(a7), a7
L2d26:
  002d26:  4c ee 18 00 ff f0    movem.l  -$10(a6), a3-a4
  002d2c:  4e 5e                unlk     a6
  002d2e:  4e 74 00 08          rtd      #$8
* GA_OffsetRgn  -  System 7 $A726 (same trap slot $1180, code r=0.92).
* S7: Patch #49 replaces _OfsetRgn ($A8E0); card commands: $10 $32
GA_OffsetRgn:
  002d32:  4e 56 00 00          link.w   a6, #$0
  002d36:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  002d3a:  3c 2e 00 08          move.w   $8(a6), d6
  002d3e:  3e 2e 00 0a          move.w   $a(a6), d7
  002d42:  20 78 08 88          movea.l  $888.w, a0
  002d46:  20 50                movea.l  (a0), a0
  002d48:  20 50                movea.l  (a0), a0
  002d4a:  28 68 02 14          movea.l  $214(a0), a4
  002d4e:  48 c7                ext.l    d7
  002d50:  4a 87                tst.l    d7
  002d52:  66 08                bne.b    $2d5c  ; -> L2d5c
  002d54:  48 c6                ext.l    d6
  002d56:  4a 86                tst.l    d6
  002d58:  67 00 00 ba          beq.w    $2e14  ; -> L2e14
L2d5c:
  002d5c:  20 54                movea.l  (a4), a0
  002d5e:  20 2e 00 0c          move.l   $c(a6), d0
  002d62:  b0 a8 01 20          cmp.l    $120(a0), d0
  002d66:  57 c5                seq.b    d5
  002d68:  44 05                neg.b    d5
  002d6a:  20 54                movea.l  (a4), a0
  002d6c:  20 2e 00 0c          move.l   $c(a6), d0
  002d70:  b0 a8 01 24          cmp.l    $124(a0), d0
  002d74:  57 c4                seq.b    d4
  002d76:  44 04                neg.b    d4
  002d78:  4a 05                tst.b    d5
  002d7a:  66 04                bne.b    $2d80  ; -> L2d80
  002d7c:  4a 04                tst.b    d4
  002d7e:  67 7c                beq.b    $2dfc  ; -> L2dfc
L2d80:
  002d80:  59 8f                subq.l   #$4, a7
  002d82:  a8 d8                dc.w     $a8d8
  002d84:  26 5f                movea.l  (a7)+, a3
  002d86:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  002d8a:  2f 0b                move.l   a3, -(a7)
  002d8c:  48 78 11 70          pea.l    $1170.w
  002d90:  4e ba 59 0a          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002d94:  58 8f                addq.l   #$4, a7
  002d96:  2f 00                move.l   d0, -(a7)
  002d98:  20 5f                movea.l  (a7)+, a0
  002d9a:  4e 90                jsr      (a0)
  002d9c:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  002da0:  3f 07                move.w   d7, -(a7)
  002da2:  3f 06                move.w   d6, -(a7)
  002da4:  48 78 11 80          pea.l    $1180.w
  002da8:  4e ba 58 f2          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002dac:  58 8f                addq.l   #$4, a7
  002dae:  2f 00                move.l   d0, -(a7)
  002db0:  20 5f                movea.l  (a7)+, a0
  002db2:  4e 90                jsr      (a0)
  002db4:  55 8f                subq.l   #$2, a7
  002db6:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  002dba:  2f 0b                move.l   a3, -(a7)
  002dbc:  a8 e3                dc.w     $a8e3
  002dbe:  70 00                moveq    #$0, d0
  002dc0:  10 1f                move.b   (a7)+, d0
  002dc2:  66 32                bne.b    $2df6  ; -> L2df6
  002dc4:  4a 05                tst.b    d5
  002dc6:  67 18                beq.b    $2de0  ; -> L2de0
  002dc8:  70 01                moveq    #$1, d0
  002dca:  2f 00                move.l   d0, -(a7)
  002dcc:  2f 00                move.l   d0, -(a7)
  002dce:  48 6e 00 0c          pea.l    $c(a6)
  002dd2:  72 10                moveq    #$10, d1
  002dd4:  2f 01                move.l   d1, -(a7)
  002dd6:  4e ba 34 4c          jsr      $6224(pc)  ; -> EngineDispatch
  002dda:  4f ef 00 10          lea.l    $10(a7), a7
  002dde:  60 16                bra.b    $2df6  ; -> L2df6
L2de0:
  002de0:  70 01                moveq    #$1, d0
  002de2:  2f 00                move.l   d0, -(a7)
  002de4:  2f 00                move.l   d0, -(a7)
  002de6:  48 6e 00 0c          pea.l    $c(a6)
  002dea:  72 32                moveq    #$32, d1
  002dec:  2f 01                move.l   d1, -(a7)
  002dee:  4e ba 34 34          jsr      $6224(pc)  ; -> EngineDispatch
  002df2:  4f ef 00 10          lea.l    $10(a7), a7
L2df6:
  002df6:  2f 0b                move.l   a3, -(a7)
  002df8:  a8 d9                dc.w     $a8d9
  002dfa:  60 18                bra.b    $2e14  ; -> L2e14
L2dfc:
  002dfc:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  002e00:  3f 07                move.w   d7, -(a7)
  002e02:  3f 06                move.w   d6, -(a7)
  002e04:  48 78 11 80          pea.l    $1180.w
  002e08:  4e ba 58 92          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002e0c:  58 8f                addq.l   #$4, a7
  002e0e:  2f 00                move.l   d0, -(a7)
  002e10:  20 5f                movea.l  (a7)+, a0
  002e12:  4e 90                jsr      (a0)
L2e14:
  002e14:  4c ee 18 f0 ff e8    movem.l  -$18(a6), d4-d7/a3-a4
  002e1a:  4e 5e                unlk     a6
  002e1c:  4e 74 00 08          rtd      #$8
* GA_InsetRgn  -  System 7 $A820 (same trap slot $1184, code r=0.92).
* S7: Patch #50 replaces _InsetRgn ($A8E1); card commands: $10 $32
GA_InsetRgn:
  002e20:  4e 56 00 00          link.w   a6, #$0
  002e24:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  002e28:  3c 2e 00 08          move.w   $8(a6), d6
  002e2c:  3e 2e 00 0a          move.w   $a(a6), d7
  002e30:  20 78 08 88          movea.l  $888.w, a0
  002e34:  20 50                movea.l  (a0), a0
  002e36:  20 50                movea.l  (a0), a0
  002e38:  28 68 02 14          movea.l  $214(a0), a4
  002e3c:  48 c7                ext.l    d7
  002e3e:  4a 87                tst.l    d7
  002e40:  66 08                bne.b    $2e4a  ; -> L2e4a
  002e42:  48 c6                ext.l    d6
  002e44:  4a 86                tst.l    d6
  002e46:  67 00 00 ba          beq.w    $2f02  ; -> L2f02
L2e4a:
  002e4a:  20 54                movea.l  (a4), a0
  002e4c:  20 2e 00 0c          move.l   $c(a6), d0
  002e50:  b0 a8 01 20          cmp.l    $120(a0), d0
  002e54:  57 c5                seq.b    d5
  002e56:  44 05                neg.b    d5
  002e58:  20 54                movea.l  (a4), a0
  002e5a:  20 2e 00 0c          move.l   $c(a6), d0
  002e5e:  b0 a8 01 24          cmp.l    $124(a0), d0
  002e62:  57 c4                seq.b    d4
  002e64:  44 04                neg.b    d4
  002e66:  4a 05                tst.b    d5
  002e68:  66 04                bne.b    $2e6e  ; -> L2e6e
  002e6a:  4a 04                tst.b    d4
  002e6c:  67 7c                beq.b    $2eea  ; -> L2eea
L2e6e:
  002e6e:  59 8f                subq.l   #$4, a7
  002e70:  a8 d8                dc.w     $a8d8
  002e72:  26 5f                movea.l  (a7)+, a3
  002e74:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  002e78:  2f 0b                move.l   a3, -(a7)
  002e7a:  48 78 11 70          pea.l    $1170.w
  002e7e:  4e ba 58 1c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002e82:  58 8f                addq.l   #$4, a7
  002e84:  2f 00                move.l   d0, -(a7)
  002e86:  20 5f                movea.l  (a7)+, a0
  002e88:  4e 90                jsr      (a0)
  002e8a:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  002e8e:  3f 07                move.w   d7, -(a7)
  002e90:  3f 06                move.w   d6, -(a7)
  002e92:  48 78 11 84          pea.l    $1184.w
  002e96:  4e ba 58 04          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002e9a:  58 8f                addq.l   #$4, a7
  002e9c:  2f 00                move.l   d0, -(a7)
  002e9e:  20 5f                movea.l  (a7)+, a0
  002ea0:  4e 90                jsr      (a0)
  002ea2:  55 8f                subq.l   #$2, a7
  002ea4:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  002ea8:  2f 0b                move.l   a3, -(a7)
  002eaa:  a8 e3                dc.w     $a8e3
  002eac:  70 00                moveq    #$0, d0
  002eae:  10 1f                move.b   (a7)+, d0
  002eb0:  66 32                bne.b    $2ee4  ; -> L2ee4
  002eb2:  4a 05                tst.b    d5
  002eb4:  67 18                beq.b    $2ece  ; -> L2ece
  002eb6:  70 01                moveq    #$1, d0
  002eb8:  2f 00                move.l   d0, -(a7)
  002eba:  2f 00                move.l   d0, -(a7)
  002ebc:  48 6e 00 0c          pea.l    $c(a6)
  002ec0:  72 10                moveq    #$10, d1
  002ec2:  2f 01                move.l   d1, -(a7)
  002ec4:  4e ba 33 5e          jsr      $6224(pc)  ; -> EngineDispatch
  002ec8:  4f ef 00 10          lea.l    $10(a7), a7
  002ecc:  60 16                bra.b    $2ee4  ; -> L2ee4
L2ece:
  002ece:  70 01                moveq    #$1, d0
  002ed0:  2f 00                move.l   d0, -(a7)
  002ed2:  2f 00                move.l   d0, -(a7)
  002ed4:  48 6e 00 0c          pea.l    $c(a6)
  002ed8:  72 32                moveq    #$32, d1
  002eda:  2f 01                move.l   d1, -(a7)
  002edc:  4e ba 33 46          jsr      $6224(pc)  ; -> EngineDispatch
  002ee0:  4f ef 00 10          lea.l    $10(a7), a7
L2ee4:
  002ee4:  2f 0b                move.l   a3, -(a7)
  002ee6:  a8 d9                dc.w     $a8d9
  002ee8:  60 18                bra.b    $2f02  ; -> L2f02
L2eea:
  002eea:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  002eee:  3f 07                move.w   d7, -(a7)
  002ef0:  3f 06                move.w   d6, -(a7)
  002ef2:  48 78 11 84          pea.l    $1184.w
  002ef6:  4e ba 57 a4          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002efa:  58 8f                addq.l   #$4, a7
  002efc:  2f 00                move.l   d0, -(a7)
  002efe:  20 5f                movea.l  (a7)+, a0
  002f00:  4e 90                jsr      (a0)
L2f02:
  002f02:  4c ee 18 f0 ff e8    movem.l  -$18(a6), d4-d7/a3-a4
  002f08:  4e 5e                unlk     a6
  002f0a:  4e 74 00 08          rtd      #$8
* GA_SectRgn  -  System 7 $A91A (same trap slot $1190, code r=0.95).
* S7: Patch #51 replaces _SectRgn ($A8E4); card commands: $10 $32
GA_SectRgn:
  002f0e:  4e 56 00 00          link.w   a6, #$0
  002f12:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  002f16:  20 78 08 88          movea.l  $888.w, a0
  002f1a:  20 50                movea.l  (a0), a0
  002f1c:  20 50                movea.l  (a0), a0
  002f1e:  28 68 02 14          movea.l  $214(a0), a4
  002f22:  20 54                movea.l  (a4), a0
  002f24:  20 2e 00 08          move.l   $8(a6), d0
  002f28:  b0 a8 01 20          cmp.l    $120(a0), d0
  002f2c:  57 c7                seq.b    d7
  002f2e:  44 07                neg.b    d7
  002f30:  20 54                movea.l  (a4), a0
  002f32:  20 2e 00 08          move.l   $8(a6), d0
  002f36:  b0 a8 01 24          cmp.l    $124(a0), d0
  002f3a:  57 c6                seq.b    d6
  002f3c:  44 06                neg.b    d6
  002f3e:  4a 07                tst.b    d7
  002f40:  66 06                bne.b    $2f48  ; -> L2f48
  002f42:  4a 06                tst.b    d6
  002f44:  67 00 00 82          beq.w    $2fc8  ; -> L2fc8
L2f48:
  002f48:  59 8f                subq.l   #$4, a7
  002f4a:  a8 d8                dc.w     $a8d8
  002f4c:  26 5f                movea.l  (a7)+, a3
  002f4e:  2f 2e 00 08          move.l   $8(a6), -(a7)
  002f52:  2f 0b                move.l   a3, -(a7)
  002f54:  48 78 11 70          pea.l    $1170.w
  002f58:  4e ba 57 42          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002f5c:  58 8f                addq.l   #$4, a7
  002f5e:  2f 00                move.l   d0, -(a7)
  002f60:  20 5f                movea.l  (a7)+, a0
  002f62:  4e 90                jsr      (a0)
  002f64:  2f 2e 00 10          move.l   $10(a6), -(a7)
  002f68:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  002f6c:  2f 2e 00 08          move.l   $8(a6), -(a7)
  002f70:  48 78 11 90          pea.l    $1190.w
  002f74:  4e ba 57 26          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002f78:  58 8f                addq.l   #$4, a7
  002f7a:  2f 00                move.l   d0, -(a7)
  002f7c:  20 5f                movea.l  (a7)+, a0
  002f7e:  4e 90                jsr      (a0)
  002f80:  55 8f                subq.l   #$2, a7
  002f82:  2f 2e 00 08          move.l   $8(a6), -(a7)
  002f86:  2f 0b                move.l   a3, -(a7)
  002f88:  a8 e3                dc.w     $a8e3
  002f8a:  70 00                moveq    #$0, d0
  002f8c:  10 1f                move.b   (a7)+, d0
  002f8e:  66 32                bne.b    $2fc2  ; -> L2fc2
  002f90:  4a 07                tst.b    d7
  002f92:  67 18                beq.b    $2fac  ; -> L2fac
  002f94:  70 01                moveq    #$1, d0
  002f96:  2f 00                move.l   d0, -(a7)
  002f98:  2f 00                move.l   d0, -(a7)
  002f9a:  48 6e 00 08          pea.l    $8(a6)
  002f9e:  72 10                moveq    #$10, d1
  002fa0:  2f 01                move.l   d1, -(a7)
  002fa2:  4e ba 32 80          jsr      $6224(pc)  ; -> EngineDispatch
  002fa6:  4f ef 00 10          lea.l    $10(a7), a7
  002faa:  60 16                bra.b    $2fc2  ; -> L2fc2
L2fac:
  002fac:  70 01                moveq    #$1, d0
  002fae:  2f 00                move.l   d0, -(a7)
  002fb0:  2f 00                move.l   d0, -(a7)
  002fb2:  48 6e 00 08          pea.l    $8(a6)
  002fb6:  72 32                moveq    #$32, d1
  002fb8:  2f 01                move.l   d1, -(a7)
  002fba:  4e ba 32 68          jsr      $6224(pc)  ; -> EngineDispatch
  002fbe:  4f ef 00 10          lea.l    $10(a7), a7
L2fc2:
  002fc2:  2f 0b                move.l   a3, -(a7)
  002fc4:  a8 d9                dc.w     $a8d9
  002fc6:  60 1c                bra.b    $2fe4  ; -> L2fe4
L2fc8:
  002fc8:  2f 2e 00 10          move.l   $10(a6), -(a7)
  002fcc:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  002fd0:  2f 2e 00 08          move.l   $8(a6), -(a7)
  002fd4:  48 78 11 90          pea.l    $1190.w
  002fd8:  4e ba 56 c2          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  002fdc:  58 8f                addq.l   #$4, a7
  002fde:  2f 00                move.l   d0, -(a7)
  002fe0:  20 5f                movea.l  (a7)+, a0
  002fe2:  4e 90                jsr      (a0)
L2fe4:
  002fe4:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  002fea:  4e 5e                unlk     a6
  002fec:  4e 74 00 0c          rtd      #$c
* GA_UnionRgn  -  System 7 $AA0A (same trap slot $1194, code r=0.95).
* S7: Patch #52 replaces _UnionRgn ($A8E5); card commands: $10 $32
GA_UnionRgn:
  002ff0:  4e 56 00 00          link.w   a6, #$0
  002ff4:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  002ff8:  20 78 08 88          movea.l  $888.w, a0
  002ffc:  20 50                movea.l  (a0), a0
  002ffe:  20 50                movea.l  (a0), a0
  003000:  28 68 02 14          movea.l  $214(a0), a4
  003004:  20 54                movea.l  (a4), a0
  003006:  20 2e 00 08          move.l   $8(a6), d0
  00300a:  b0 a8 01 20          cmp.l    $120(a0), d0
  00300e:  57 c7                seq.b    d7
  003010:  44 07                neg.b    d7
  003012:  20 54                movea.l  (a4), a0
  003014:  20 2e 00 08          move.l   $8(a6), d0
  003018:  b0 a8 01 24          cmp.l    $124(a0), d0
  00301c:  57 c6                seq.b    d6
  00301e:  44 06                neg.b    d6
  003020:  4a 07                tst.b    d7
  003022:  66 06                bne.b    $302a  ; -> L302a
  003024:  4a 06                tst.b    d6
  003026:  67 00 00 82          beq.w    $30aa  ; -> L30aa
L302a:
  00302a:  59 8f                subq.l   #$4, a7
  00302c:  a8 d8                dc.w     $a8d8
  00302e:  26 5f                movea.l  (a7)+, a3
  003030:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003034:  2f 0b                move.l   a3, -(a7)
  003036:  48 78 11 70          pea.l    $1170.w
  00303a:  4e ba 56 60          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00303e:  58 8f                addq.l   #$4, a7
  003040:  2f 00                move.l   d0, -(a7)
  003042:  20 5f                movea.l  (a7)+, a0
  003044:  4e 90                jsr      (a0)
  003046:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00304a:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00304e:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003052:  48 78 11 94          pea.l    $1194.w
  003056:  4e ba 56 44          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00305a:  58 8f                addq.l   #$4, a7
  00305c:  2f 00                move.l   d0, -(a7)
  00305e:  20 5f                movea.l  (a7)+, a0
  003060:  4e 90                jsr      (a0)
  003062:  55 8f                subq.l   #$2, a7
  003064:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003068:  2f 0b                move.l   a3, -(a7)
  00306a:  a8 e3                dc.w     $a8e3
  00306c:  70 00                moveq    #$0, d0
  00306e:  10 1f                move.b   (a7)+, d0
  003070:  66 32                bne.b    $30a4  ; -> L30a4
  003072:  4a 07                tst.b    d7
  003074:  67 18                beq.b    $308e  ; -> L308e
  003076:  70 01                moveq    #$1, d0
  003078:  2f 00                move.l   d0, -(a7)
  00307a:  2f 00                move.l   d0, -(a7)
  00307c:  48 6e 00 08          pea.l    $8(a6)
  003080:  72 10                moveq    #$10, d1
  003082:  2f 01                move.l   d1, -(a7)
  003084:  4e ba 31 9e          jsr      $6224(pc)  ; -> EngineDispatch
  003088:  4f ef 00 10          lea.l    $10(a7), a7
  00308c:  60 16                bra.b    $30a4  ; -> L30a4
L308e:
  00308e:  70 01                moveq    #$1, d0
  003090:  2f 00                move.l   d0, -(a7)
  003092:  2f 00                move.l   d0, -(a7)
  003094:  48 6e 00 08          pea.l    $8(a6)
  003098:  72 32                moveq    #$32, d1
  00309a:  2f 01                move.l   d1, -(a7)
  00309c:  4e ba 31 86          jsr      $6224(pc)  ; -> EngineDispatch
  0030a0:  4f ef 00 10          lea.l    $10(a7), a7
L30a4:
  0030a4:  2f 0b                move.l   a3, -(a7)
  0030a6:  a8 d9                dc.w     $a8d9
  0030a8:  60 1c                bra.b    $30c6  ; -> L30c6
L30aa:
  0030aa:  2f 2e 00 10          move.l   $10(a6), -(a7)
  0030ae:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  0030b2:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0030b6:  48 78 11 94          pea.l    $1194.w
  0030ba:  4e ba 55 e0          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0030be:  58 8f                addq.l   #$4, a7
  0030c0:  2f 00                move.l   d0, -(a7)
  0030c2:  20 5f                movea.l  (a7)+, a0
  0030c4:  4e 90                jsr      (a0)
L30c6:
  0030c6:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  0030cc:  4e 5e                unlk     a6
  0030ce:  4e 74 00 0c          rtd      #$c
* GA_DiffRgn  -  System 7 $AAFA (same trap slot $1198, code r=0.95).
* S7: Patch #53 replaces _DiffRgn ($A8E6); card commands: $10 $32
GA_DiffRgn:
  0030d2:  4e 56 00 00          link.w   a6, #$0
  0030d6:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  0030da:  20 78 08 88          movea.l  $888.w, a0
  0030de:  20 50                movea.l  (a0), a0
  0030e0:  20 50                movea.l  (a0), a0
  0030e2:  28 68 02 14          movea.l  $214(a0), a4
  0030e6:  20 54                movea.l  (a4), a0
  0030e8:  20 2e 00 08          move.l   $8(a6), d0
  0030ec:  b0 a8 01 20          cmp.l    $120(a0), d0
  0030f0:  57 c7                seq.b    d7
  0030f2:  44 07                neg.b    d7
  0030f4:  20 54                movea.l  (a4), a0
  0030f6:  20 2e 00 08          move.l   $8(a6), d0
  0030fa:  b0 a8 01 24          cmp.l    $124(a0), d0
  0030fe:  57 c6                seq.b    d6
  003100:  44 06                neg.b    d6
  003102:  4a 07                tst.b    d7
  003104:  66 06                bne.b    $310c  ; -> L310c
  003106:  4a 06                tst.b    d6
  003108:  67 00 00 82          beq.w    $318c  ; -> L318c
L310c:
  00310c:  59 8f                subq.l   #$4, a7
  00310e:  a8 d8                dc.w     $a8d8
  003110:  26 5f                movea.l  (a7)+, a3
  003112:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003116:  2f 0b                move.l   a3, -(a7)
  003118:  48 78 11 70          pea.l    $1170.w
  00311c:  4e ba 55 7e          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003120:  58 8f                addq.l   #$4, a7
  003122:  2f 00                move.l   d0, -(a7)
  003124:  20 5f                movea.l  (a7)+, a0
  003126:  4e 90                jsr      (a0)
  003128:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00312c:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003130:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003134:  48 78 11 98          pea.l    $1198.w
  003138:  4e ba 55 62          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00313c:  58 8f                addq.l   #$4, a7
  00313e:  2f 00                move.l   d0, -(a7)
  003140:  20 5f                movea.l  (a7)+, a0
  003142:  4e 90                jsr      (a0)
  003144:  55 8f                subq.l   #$2, a7
  003146:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00314a:  2f 0b                move.l   a3, -(a7)
  00314c:  a8 e3                dc.w     $a8e3
  00314e:  70 00                moveq    #$0, d0
  003150:  10 1f                move.b   (a7)+, d0
  003152:  66 32                bne.b    $3186  ; -> L3186
  003154:  4a 07                tst.b    d7
  003156:  67 18                beq.b    $3170  ; -> L3170
  003158:  70 01                moveq    #$1, d0
  00315a:  2f 00                move.l   d0, -(a7)
  00315c:  2f 00                move.l   d0, -(a7)
  00315e:  48 6e 00 08          pea.l    $8(a6)
  003162:  72 10                moveq    #$10, d1
  003164:  2f 01                move.l   d1, -(a7)
  003166:  4e ba 30 bc          jsr      $6224(pc)  ; -> EngineDispatch
  00316a:  4f ef 00 10          lea.l    $10(a7), a7
  00316e:  60 16                bra.b    $3186  ; -> L3186
L3170:
  003170:  70 01                moveq    #$1, d0
  003172:  2f 00                move.l   d0, -(a7)
  003174:  2f 00                move.l   d0, -(a7)
  003176:  48 6e 00 08          pea.l    $8(a6)
  00317a:  72 32                moveq    #$32, d1
  00317c:  2f 01                move.l   d1, -(a7)
  00317e:  4e ba 30 a4          jsr      $6224(pc)  ; -> EngineDispatch
  003182:  4f ef 00 10          lea.l    $10(a7), a7
L3186:
  003186:  2f 0b                move.l   a3, -(a7)
  003188:  a8 d9                dc.w     $a8d9
  00318a:  60 1c                bra.b    $31a8  ; -> L31a8
L318c:
  00318c:  2f 2e 00 10          move.l   $10(a6), -(a7)
  003190:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003194:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003198:  48 78 11 98          pea.l    $1198.w
  00319c:  4e ba 54 fe          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0031a0:  58 8f                addq.l   #$4, a7
  0031a2:  2f 00                move.l   d0, -(a7)
  0031a4:  20 5f                movea.l  (a7)+, a0
  0031a6:  4e 90                jsr      (a0)
L31a8:
  0031a8:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  0031ae:  4e 5e                unlk     a6
  0031b0:  4e 74 00 0c          rtd      #$c
* GA_XOrRgn  -  System 7 $ABEA (same trap slot $119C, code r=0.95).
* S7: Patch #54 replaces _XOrRgn ($A8E7); card commands: $10 $32
GA_XOrRgn:
  0031b4:  4e 56 00 00          link.w   a6, #$0
  0031b8:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  0031bc:  20 78 08 88          movea.l  $888.w, a0
  0031c0:  20 50                movea.l  (a0), a0
  0031c2:  20 50                movea.l  (a0), a0
  0031c4:  28 68 02 14          movea.l  $214(a0), a4
  0031c8:  20 54                movea.l  (a4), a0
  0031ca:  20 2e 00 08          move.l   $8(a6), d0
  0031ce:  b0 a8 01 20          cmp.l    $120(a0), d0
  0031d2:  57 c7                seq.b    d7
  0031d4:  44 07                neg.b    d7
  0031d6:  20 54                movea.l  (a4), a0
  0031d8:  20 2e 00 08          move.l   $8(a6), d0
  0031dc:  b0 a8 01 24          cmp.l    $124(a0), d0
  0031e0:  57 c6                seq.b    d6
  0031e2:  44 06                neg.b    d6
  0031e4:  4a 07                tst.b    d7
  0031e6:  66 06                bne.b    $31ee  ; -> L31ee
  0031e8:  4a 06                tst.b    d6
  0031ea:  67 00 00 82          beq.w    $326e  ; -> L326e
L31ee:
  0031ee:  59 8f                subq.l   #$4, a7
  0031f0:  a8 d8                dc.w     $a8d8
  0031f2:  26 5f                movea.l  (a7)+, a3
  0031f4:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0031f8:  2f 0b                move.l   a3, -(a7)
  0031fa:  48 78 11 70          pea.l    $1170.w
  0031fe:  4e ba 54 9c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003202:  58 8f                addq.l   #$4, a7
  003204:  2f 00                move.l   d0, -(a7)
  003206:  20 5f                movea.l  (a7)+, a0
  003208:  4e 90                jsr      (a0)
  00320a:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00320e:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003212:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003216:  48 78 11 9c          pea.l    $119c.w
  00321a:  4e ba 54 80          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00321e:  58 8f                addq.l   #$4, a7
  003220:  2f 00                move.l   d0, -(a7)
  003222:  20 5f                movea.l  (a7)+, a0
  003224:  4e 90                jsr      (a0)
  003226:  55 8f                subq.l   #$2, a7
  003228:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00322c:  2f 0b                move.l   a3, -(a7)
  00322e:  a8 e3                dc.w     $a8e3
  003230:  70 00                moveq    #$0, d0
  003232:  10 1f                move.b   (a7)+, d0
  003234:  66 32                bne.b    $3268  ; -> L3268
  003236:  4a 07                tst.b    d7
  003238:  67 18                beq.b    $3252  ; -> L3252
  00323a:  70 01                moveq    #$1, d0
  00323c:  2f 00                move.l   d0, -(a7)
  00323e:  2f 00                move.l   d0, -(a7)
  003240:  48 6e 00 08          pea.l    $8(a6)
  003244:  72 10                moveq    #$10, d1
  003246:  2f 01                move.l   d1, -(a7)
  003248:  4e ba 2f da          jsr      $6224(pc)  ; -> EngineDispatch
  00324c:  4f ef 00 10          lea.l    $10(a7), a7
  003250:  60 16                bra.b    $3268  ; -> L3268
L3252:
  003252:  70 01                moveq    #$1, d0
  003254:  2f 00                move.l   d0, -(a7)
  003256:  2f 00                move.l   d0, -(a7)
  003258:  48 6e 00 08          pea.l    $8(a6)
  00325c:  72 32                moveq    #$32, d1
  00325e:  2f 01                move.l   d1, -(a7)
  003260:  4e ba 2f c2          jsr      $6224(pc)  ; -> EngineDispatch
  003264:  4f ef 00 10          lea.l    $10(a7), a7
L3268:
  003268:  2f 0b                move.l   a3, -(a7)
  00326a:  a8 d9                dc.w     $a8d9
  00326c:  60 1c                bra.b    $328a  ; -> L328a
L326e:
  00326e:  2f 2e 00 10          move.l   $10(a6), -(a7)
  003272:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003276:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00327a:  48 78 11 9c          pea.l    $119c.w
  00327e:  4e ba 54 1c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003282:  58 8f                addq.l   #$4, a7
  003284:  2f 00                move.l   d0, -(a7)
  003286:  20 5f                movea.l  (a7)+, a0
  003288:  4e 90                jsr      (a0)
L328a:
  00328a:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  003290:  4e 5e                unlk     a6
  003292:  4e 74 00 0c          rtd      #$c
* GA_MapRgn  -  System 7 $ACDA (same trap slot $11EC, code r=0.96).
* S7: Patch #55 replaces _MapRgn ($A8FB); card commands: $10 $32
GA_MapRgn:
  003296:  4e 56 ff f8          link.w   a6, #$fff8
  00329a:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  00329e:  28 6e 00 08          movea.l  $8(a6), a4
  0032a2:  26 6e 00 0c          movea.l  $c(a6), a3
  0032a6:  20 78 08 88          movea.l  $888.w, a0
  0032aa:  20 50                movea.l  (a0), a0
  0032ac:  20 50                movea.l  (a0), a0
  0032ae:  2d 68 02 14 ff f8    move.l   $214(a0), -$8(a6)
  0032b4:  20 13                move.l   (a3), d0
  0032b6:  b0 94                cmp.l    (a4), d0
  0032b8:  66 0c                bne.b    $32c6  ; -> L32c6
  0032ba:  20 2b 00 04          move.l   $4(a3), d0
  0032be:  b0 ac 00 04          cmp.l    $4(a4), d0
  0032c2:  67 00 00 cc          beq.w    $3390  ; -> L3390
L32c6:
  0032c6:  20 6e ff f8          movea.l  -$8(a6), a0
  0032ca:  20 50                movea.l  (a0), a0
  0032cc:  20 2e 00 10          move.l   $10(a6), d0
  0032d0:  b0 a8 01 20          cmp.l    $120(a0), d0
  0032d4:  57 c7                seq.b    d7
  0032d6:  44 07                neg.b    d7
  0032d8:  20 6e ff f8          movea.l  -$8(a6), a0
  0032dc:  20 50                movea.l  (a0), a0
  0032de:  20 2e 00 10          move.l   $10(a6), d0
  0032e2:  b0 a8 01 24          cmp.l    $124(a0), d0
  0032e6:  57 c6                seq.b    d6
  0032e8:  44 06                neg.b    d6
  0032ea:  4a 07                tst.b    d7
  0032ec:  66 06                bne.b    $32f4  ; -> L32f4
  0032ee:  4a 06                tst.b    d6
  0032f0:  67 00 00 86          beq.w    $3378  ; -> L3378
L32f4:
  0032f4:  59 8f                subq.l   #$4, a7
  0032f6:  a8 d8                dc.w     $a8d8
  0032f8:  2d 5f ff fc          move.l   (a7)+, -$4(a6)
  0032fc:  2f 2e 00 10          move.l   $10(a6), -(a7)
  003300:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  003304:  48 78 11 70          pea.l    $1170.w
  003308:  4e ba 53 92          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00330c:  58 8f                addq.l   #$4, a7
  00330e:  2f 00                move.l   d0, -(a7)
  003310:  20 5f                movea.l  (a7)+, a0
  003312:  4e 90                jsr      (a0)
  003314:  2f 2e 00 10          move.l   $10(a6), -(a7)
  003318:  2f 0b                move.l   a3, -(a7)
  00331a:  2f 0c                move.l   a4, -(a7)
  00331c:  48 78 11 ec          pea.l    $11ec.w
  003320:  4e ba 53 7a          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003324:  58 8f                addq.l   #$4, a7
  003326:  2f 00                move.l   d0, -(a7)
  003328:  20 5f                movea.l  (a7)+, a0
  00332a:  4e 90                jsr      (a0)
  00332c:  55 8f                subq.l   #$2, a7
  00332e:  2f 2e 00 10          move.l   $10(a6), -(a7)
  003332:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  003336:  a8 e3                dc.w     $a8e3
  003338:  70 00                moveq    #$0, d0
  00333a:  10 1f                move.b   (a7)+, d0
  00333c:  66 32                bne.b    $3370  ; -> L3370
  00333e:  4a 07                tst.b    d7
  003340:  67 18                beq.b    $335a  ; -> L335a
  003342:  70 01                moveq    #$1, d0
  003344:  2f 00                move.l   d0, -(a7)
  003346:  2f 00                move.l   d0, -(a7)
  003348:  48 6e 00 10          pea.l    $10(a6)
  00334c:  72 10                moveq    #$10, d1
  00334e:  2f 01                move.l   d1, -(a7)
  003350:  4e ba 2e d2          jsr      $6224(pc)  ; -> EngineDispatch
  003354:  4f ef 00 10          lea.l    $10(a7), a7
  003358:  60 16                bra.b    $3370  ; -> L3370
L335a:
  00335a:  70 01                moveq    #$1, d0
  00335c:  2f 00                move.l   d0, -(a7)
  00335e:  2f 00                move.l   d0, -(a7)
  003360:  48 6e 00 10          pea.l    $10(a6)
  003364:  72 32                moveq    #$32, d1
  003366:  2f 01                move.l   d1, -(a7)
  003368:  4e ba 2e ba          jsr      $6224(pc)  ; -> EngineDispatch
  00336c:  4f ef 00 10          lea.l    $10(a7), a7
L3370:
  003370:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  003374:  a8 d9                dc.w     $a8d9
  003376:  60 18                bra.b    $3390  ; -> L3390
L3378:
  003378:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00337c:  2f 0b                move.l   a3, -(a7)
  00337e:  2f 0c                move.l   a4, -(a7)
  003380:  48 78 11 ec          pea.l    $11ec.w
  003384:  4e ba 53 16          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003388:  58 8f                addq.l   #$4, a7
  00338a:  2f 00                move.l   d0, -(a7)
  00338c:  20 5f                movea.l  (a7)+, a0
  00338e:  4e 90                jsr      (a0)
L3390:
  003390:  4c ee 18 c0 ff e8    movem.l  -$18(a6), d6-d7/a3-a4
  003396:  4e 5e                unlk     a6
  003398:  4e 74 00 0c          rtd      #$c
* GA_ForeColor  -  System 7 $ADF0 (same trap slot $F88, code r=0.93).
* S7: Patch #16 replaces _ForeColor ($A862); card commands: $36
GA_ForeColor:
  00339c:  4e 56 ff fc          link.w   a6, #$fffc
  0033a0:  2f 0b                move.l   a3, -(a7)
  0033a2:  70 00                moveq    #$0, d0
  0033a4:  2f 00                move.l   d0, -(a7)
  0033a6:  4e ba 54 7a          jsr      $8822(pc)  ; -> s7_sub_6f1c
  0033aa:  26 40                movea.l  d0, a3
  0033ac:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0033b0:  48 78 0f 88          pea.l    $f88.w
  0033b4:  4e ba 52 e6          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0033b8:  58 8f                addq.l   #$4, a7
  0033ba:  2f 00                move.l   d0, -(a7)
  0033bc:  20 5f                movea.l  (a7)+, a0
  0033be:  4e 90                jsr      (a0)
  0033c0:  4e ba de 6e          jsr      $1230(pc)  ; -> GetA5
  0033c4:  20 40                movea.l  d0, a0
  0033c6:  20 50                movea.l  (a0), a0
  0033c8:  b7 d0                cmpa.l   (a0), a3
  0033ca:  58 8f                addq.l   #$4, a7
  0033cc:  66 24                bne.b    $33f2  ; -> L33f2
  0033ce:  30 2b 00 06          move.w   $6(a3), d0
  0033d2:  48 c0                ext.l    d0
  0033d4:  6d 1c                blt.b    $33f2  ; -> L33f2
  0033d6:  70 00                moveq    #$0, d0
  0033d8:  2d 40 ff fc          move.l   d0, -$4(a6)
  0033dc:  72 01                moveq    #$1, d1
  0033de:  2f 01                move.l   d1, -(a7)
  0033e0:  2f 01                move.l   d1, -(a7)
  0033e2:  48 6e ff fc          pea.l    -$4(a6)
  0033e6:  70 36                moveq    #$36, d0
  0033e8:  2f 00                move.l   d0, -(a7)
  0033ea:  4e ba 2e 38          jsr      $6224(pc)  ; -> EngineDispatch
  0033ee:  4f ef 00 10          lea.l    $10(a7), a7
L33f2:
  0033f2:  26 6e ff f8          movea.l  -$8(a6), a3
  0033f6:  4e 5e                unlk     a6
  0033f8:  4e 74 00 04          rtd      #$4
* GA_RGBForeColor  -  System 7 $AE56 (same trap slot $1650, code r=0.83).
* S7: Patch #17 replaces _RGBForeColor ($AA14); card commands: $36
GA_RGBForeColor:
  0033fc:  4e 56 ff fc          link.w   a6, #$fffc
  003400:  48 e7 00 18          movem.l  a3-a4, -(a7)
  003404:  28 6e 00 08          movea.l  $8(a6), a4
  003408:  70 00                moveq    #$0, d0
  00340a:  2f 00                move.l   d0, -(a7)
  00340c:  4e ba 54 14          jsr      $8822(pc)  ; -> s7_sub_6f1c
  003410:  26 40                movea.l  d0, a3
  003412:  4e ba de 1c          jsr      $1230(pc)  ; -> GetA5
  003416:  20 40                movea.l  d0, a0
  003418:  20 50                movea.l  (a0), a0
  00341a:  b7 d0                cmpa.l   (a0), a3
  00341c:  58 8f                addq.l   #$4, a7
  00341e:  66 50                bne.b    $3470  ; -> L3470
  003420:  30 2b 00 06          move.w   $6(a3), d0
  003424:  48 c0                ext.l    d0
  003426:  6c 18                bge.b    $3440  ; -> L3440
  003428:  20 2b 00 24          move.l   $24(a3), d0
  00342c:  b0 94                cmp.l    (a4), d0
  00342e:  66 10                bne.b    $3440  ; -> L3440
  003430:  70 00                moveq    #$0, d0
  003432:  30 2b 00 28          move.w   $28(a3), d0
  003436:  72 00                moveq    #$0, d1
  003438:  32 2c 00 04          move.w   $4(a4), d1
  00343c:  b2 80                cmp.l    d0, d1
  00343e:  67 30                beq.b    $3470  ; -> L3470
L3440:
  003440:  2f 0c                move.l   a4, -(a7)
  003442:  48 78 16 50          pea.l    $1650.w
  003446:  4e ba 52 54          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00344a:  58 8f                addq.l   #$4, a7
  00344c:  2f 00                move.l   d0, -(a7)
  00344e:  20 5f                movea.l  (a7)+, a0
  003450:  4e 90                jsr      (a0)
  003452:  70 00                moveq    #$0, d0
  003454:  2d 40 ff fc          move.l   d0, -$4(a6)
  003458:  72 01                moveq    #$1, d1
  00345a:  2f 01                move.l   d1, -(a7)
  00345c:  2f 01                move.l   d1, -(a7)
  00345e:  48 6e ff fc          pea.l    -$4(a6)
  003462:  70 36                moveq    #$36, d0
  003464:  2f 00                move.l   d0, -(a7)
  003466:  4e ba 2d bc          jsr      $6224(pc)  ; -> EngineDispatch
  00346a:  4f ef 00 10          lea.l    $10(a7), a7
  00346e:  60 12                bra.b    $3482  ; -> L3482
L3470:
  003470:  2f 0c                move.l   a4, -(a7)
  003472:  48 78 16 50          pea.l    $1650.w
  003476:  4e ba 52 24          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00347a:  58 8f                addq.l   #$4, a7
  00347c:  2f 00                move.l   d0, -(a7)
  00347e:  20 5f                movea.l  (a7)+, a0
  003480:  4e 90                jsr      (a0)
L3482:
  003482:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  003488:  4e 5e                unlk     a6
  00348a:  4e 74 00 04          rtd      #$4
* GA_PmForeColor  -  System 7 $AF00 (same trap slot $185C, code r=0.81).
* S7: Patch #18 replaces _PmForeColor ($AA97); card commands: $36
GA_PmForeColor:
  00348e:  4e 56 ff fc          link.w   a6, #$fffc
  003492:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  003496:  3e 2e 00 08          move.w   $8(a6), d7
  00349a:  70 00                moveq    #$0, d0
  00349c:  2f 00                move.l   d0, -(a7)
  00349e:  4e ba 53 82          jsr      $8822(pc)  ; -> s7_sub_6f1c
  0034a2:  28 40                movea.l  d0, a4
  0034a4:  4e ba dd 8a          jsr      $1230(pc)  ; -> GetA5
  0034a8:  20 40                movea.l  d0, a0
  0034aa:  20 50                movea.l  (a0), a0
  0034ac:  b9 d0                cmpa.l   (a0), a4
  0034ae:  58 8f                addq.l   #$4, a7
  0034b0:  66 5c                bne.b    $350e  ; -> L350e
  0034b2:  30 2c 00 06          move.w   $6(a4), d0
  0034b6:  48 c0                ext.l    d0
  0034b8:  6c 54                bge.b    $350e  ; -> L350e
  0034ba:  20 6c 00 08          movea.l  $8(a4), a0
  0034be:  26 50                movea.l  (a0), a3
  0034c0:  4a ab 00 0c          tst.l    $c(a3)
  0034c4:  67 18                beq.b    $34de  ; -> L34de
  0034c6:  30 2b 00 18          move.w   $18(a3), d0
  0034ca:  48 c0                ext.l    d0
  0034cc:  72 01                moveq    #$1, d1
  0034ce:  c2 80                and.l    d0, d1
  0034d0:  67 0c                beq.b    $34de  ; -> L34de
  0034d2:  48 c7                ext.l    d7
  0034d4:  30 2b 00 10          move.w   $10(a3), d0
  0034d8:  48 c0                ext.l    d0
  0034da:  be 80                cmp.l    d0, d7
  0034dc:  67 30                beq.b    $350e  ; -> L350e
L34de:
  0034de:  3f 07                move.w   d7, -(a7)
  0034e0:  48 78 18 5c          pea.l    $185c.w
  0034e4:  4e ba 51 b6          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0034e8:  58 8f                addq.l   #$4, a7
  0034ea:  2f 00                move.l   d0, -(a7)
  0034ec:  20 5f                movea.l  (a7)+, a0
  0034ee:  4e 90                jsr      (a0)
  0034f0:  70 02                moveq    #$2, d0
  0034f2:  2d 40 ff fc          move.l   d0, -$4(a6)
  0034f6:  72 01                moveq    #$1, d1
  0034f8:  2f 01                move.l   d1, -(a7)
  0034fa:  2f 01                move.l   d1, -(a7)
  0034fc:  48 6e ff fc          pea.l    -$4(a6)
  003500:  70 36                moveq    #$36, d0
  003502:  2f 00                move.l   d0, -(a7)
  003504:  4e ba 2d 1e          jsr      $6224(pc)  ; -> EngineDispatch
  003508:  4f ef 00 10          lea.l    $10(a7), a7
  00350c:  60 12                bra.b    $3520  ; -> L3520
L350e:
  00350e:  3f 07                move.w   d7, -(a7)
  003510:  48 78 18 5c          pea.l    $185c.w
  003514:  4e ba 51 86          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003518:  58 8f                addq.l   #$4, a7
  00351a:  2f 00                move.l   d0, -(a7)
  00351c:  20 5f                movea.l  (a7)+, a0
  00351e:  4e 90                jsr      (a0)
L3520:
  003520:  4c ee 18 80 ff f0    movem.l  -$10(a6), d7/a3-a4
  003526:  4e 5e                unlk     a6
  003528:  4e 74 00 02          rtd      #$2
* GA_BackColor  -  System 7 $AFA0 (same trap slot $F8C, code r=0.93).
* S7: Patch #41 replaces _BackColor ($A863); card commands: $37
GA_BackColor:
  00352c:  4e 56 ff fc          link.w   a6, #$fffc
  003530:  2f 0b                move.l   a3, -(a7)
  003532:  70 00                moveq    #$0, d0
  003534:  2f 00                move.l   d0, -(a7)
  003536:  4e ba 52 ea          jsr      $8822(pc)  ; -> s7_sub_6f1c
  00353a:  26 40                movea.l  d0, a3
  00353c:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003540:  48 78 0f 8c          pea.l    $f8c.w
  003544:  4e ba 51 56          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003548:  58 8f                addq.l   #$4, a7
  00354a:  2f 00                move.l   d0, -(a7)
  00354c:  20 5f                movea.l  (a7)+, a0
  00354e:  4e 90                jsr      (a0)
  003550:  4e ba dc de          jsr      $1230(pc)  ; -> GetA5
  003554:  20 40                movea.l  d0, a0
  003556:  20 50                movea.l  (a0), a0
  003558:  b7 d0                cmpa.l   (a0), a3
  00355a:  58 8f                addq.l   #$4, a7
  00355c:  66 24                bne.b    $3582  ; -> L3582
  00355e:  30 2b 00 06          move.w   $6(a3), d0
  003562:  48 c0                ext.l    d0
  003564:  6d 1c                blt.b    $3582  ; -> L3582
  003566:  70 00                moveq    #$0, d0
  003568:  2d 40 ff fc          move.l   d0, -$4(a6)
  00356c:  72 01                moveq    #$1, d1
  00356e:  2f 01                move.l   d1, -(a7)
  003570:  2f 01                move.l   d1, -(a7)
  003572:  48 6e ff fc          pea.l    -$4(a6)
  003576:  70 37                moveq    #$37, d0
  003578:  2f 00                move.l   d0, -(a7)
  00357a:  4e ba 2c a8          jsr      $6224(pc)  ; -> EngineDispatch
  00357e:  4f ef 00 10          lea.l    $10(a7), a7
L3582:
  003582:  26 6e ff f8          movea.l  -$8(a6), a3
  003586:  4e 5e                unlk     a6
  003588:  4e 74 00 04          rtd      #$4
* GA_RGBBackColor  -  System 7 $B006 (same trap slot $1654, code r=0.83).
* S7: Patch #56 replaces _RGBBackColor ($AA15); card commands: $37
GA_RGBBackColor:
  00358c:  4e 56 ff fc          link.w   a6, #$fffc
  003590:  48 e7 00 18          movem.l  a3-a4, -(a7)
  003594:  28 6e 00 08          movea.l  $8(a6), a4
  003598:  70 00                moveq    #$0, d0
  00359a:  2f 00                move.l   d0, -(a7)
  00359c:  4e ba 52 84          jsr      $8822(pc)  ; -> s7_sub_6f1c
  0035a0:  26 40                movea.l  d0, a3
  0035a2:  4e ba dc 8c          jsr      $1230(pc)  ; -> GetA5
  0035a6:  20 40                movea.l  d0, a0
  0035a8:  20 50                movea.l  (a0), a0
  0035aa:  b7 d0                cmpa.l   (a0), a3
  0035ac:  58 8f                addq.l   #$4, a7
  0035ae:  66 50                bne.b    $3600  ; -> L3600
  0035b0:  30 2b 00 06          move.w   $6(a3), d0
  0035b4:  48 c0                ext.l    d0
  0035b6:  6c 18                bge.b    $35d0  ; -> L35d0
  0035b8:  20 2b 00 2a          move.l   $2a(a3), d0
  0035bc:  b0 94                cmp.l    (a4), d0
  0035be:  66 10                bne.b    $35d0  ; -> L35d0
  0035c0:  70 00                moveq    #$0, d0
  0035c2:  30 2b 00 2e          move.w   $2e(a3), d0
  0035c6:  72 00                moveq    #$0, d1
  0035c8:  32 2c 00 04          move.w   $4(a4), d1
  0035cc:  b2 80                cmp.l    d0, d1
  0035ce:  67 30                beq.b    $3600  ; -> L3600
L35d0:
  0035d0:  2f 0c                move.l   a4, -(a7)
  0035d2:  48 78 16 54          pea.l    $1654.w
  0035d6:  4e ba 50 c4          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0035da:  58 8f                addq.l   #$4, a7
  0035dc:  2f 00                move.l   d0, -(a7)
  0035de:  20 5f                movea.l  (a7)+, a0
  0035e0:  4e 90                jsr      (a0)
  0035e2:  70 00                moveq    #$0, d0
  0035e4:  2d 40 ff fc          move.l   d0, -$4(a6)
  0035e8:  72 01                moveq    #$1, d1
  0035ea:  2f 01                move.l   d1, -(a7)
  0035ec:  2f 01                move.l   d1, -(a7)
  0035ee:  48 6e ff fc          pea.l    -$4(a6)
  0035f2:  70 37                moveq    #$37, d0
  0035f4:  2f 00                move.l   d0, -(a7)
  0035f6:  4e ba 2c 2c          jsr      $6224(pc)  ; -> EngineDispatch
  0035fa:  4f ef 00 10          lea.l    $10(a7), a7
  0035fe:  60 12                bra.b    $3612  ; -> L3612
L3600:
  003600:  2f 0c                move.l   a4, -(a7)
  003602:  48 78 16 54          pea.l    $1654.w
  003606:  4e ba 50 94          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00360a:  58 8f                addq.l   #$4, a7
  00360c:  2f 00                move.l   d0, -(a7)
  00360e:  20 5f                movea.l  (a7)+, a0
  003610:  4e 90                jsr      (a0)
L3612:
  003612:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  003618:  4e 5e                unlk     a6
  00361a:  4e 74 00 04          rtd      #$4
* GA_PmBackColor  -  System 7 $B0B0 (same trap slot $1860, code r=0.81).
* S7: Patch #19 replaces _PmBackColor ($AA98); card commands: $37
GA_PmBackColor:
  00361e:  4e 56 ff fc          link.w   a6, #$fffc
  003622:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  003626:  3e 2e 00 08          move.w   $8(a6), d7
  00362a:  70 00                moveq    #$0, d0
  00362c:  2f 00                move.l   d0, -(a7)
  00362e:  4e ba 51 f2          jsr      $8822(pc)  ; -> s7_sub_6f1c
  003632:  28 40                movea.l  d0, a4
  003634:  4e ba db fa          jsr      $1230(pc)  ; -> GetA5
  003638:  20 40                movea.l  d0, a0
  00363a:  20 50                movea.l  (a0), a0
  00363c:  b9 d0                cmpa.l   (a0), a4
  00363e:  58 8f                addq.l   #$4, a7
  003640:  66 5c                bne.b    $369e  ; -> L369e
  003642:  30 2c 00 06          move.w   $6(a4), d0
  003646:  48 c0                ext.l    d0
  003648:  6c 54                bge.b    $369e  ; -> L369e
  00364a:  20 6c 00 08          movea.l  $8(a4), a0
  00364e:  26 50                movea.l  (a0), a3
  003650:  4a ab 00 12          tst.l    $12(a3)
  003654:  67 18                beq.b    $366e  ; -> L366e
  003656:  30 2b 00 18          move.w   $18(a3), d0
  00365a:  48 c0                ext.l    d0
  00365c:  72 02                moveq    #$2, d1
  00365e:  c2 80                and.l    d0, d1
  003660:  67 0c                beq.b    $366e  ; -> L366e
  003662:  48 c7                ext.l    d7
  003664:  30 2b 00 16          move.w   $16(a3), d0
  003668:  48 c0                ext.l    d0
  00366a:  be 80                cmp.l    d0, d7
  00366c:  67 30                beq.b    $369e  ; -> L369e
L366e:
  00366e:  3f 07                move.w   d7, -(a7)
  003670:  48 78 18 60          pea.l    $1860.w
  003674:  4e ba 50 26          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003678:  58 8f                addq.l   #$4, a7
  00367a:  2f 00                move.l   d0, -(a7)
  00367c:  20 5f                movea.l  (a7)+, a0
  00367e:  4e 90                jsr      (a0)
  003680:  70 04                moveq    #$4, d0
  003682:  2d 40 ff fc          move.l   d0, -$4(a6)
  003686:  72 01                moveq    #$1, d1
  003688:  2f 01                move.l   d1, -(a7)
  00368a:  2f 01                move.l   d1, -(a7)
  00368c:  48 6e ff fc          pea.l    -$4(a6)
  003690:  70 37                moveq    #$37, d0
  003692:  2f 00                move.l   d0, -(a7)
  003694:  4e ba 2b 8e          jsr      $6224(pc)  ; -> EngineDispatch
  003698:  4f ef 00 10          lea.l    $10(a7), a7
  00369c:  60 12                bra.b    $36b0  ; -> L36b0
L369e:
  00369e:  3f 07                move.w   d7, -(a7)
  0036a0:  48 78 18 60          pea.l    $1860.w
  0036a4:  4e ba 4f f6          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0036a8:  58 8f                addq.l   #$4, a7
  0036aa:  2f 00                move.l   d0, -(a7)
  0036ac:  20 5f                movea.l  (a7)+, a0
  0036ae:  4e 90                jsr      (a0)
L36b0:
  0036b0:  4c ee 18 80 ff f0    movem.l  -$10(a6), d7/a3-a4
  0036b6:  4e 5e                unlk     a6
  0036b8:  4e 74 00 02          rtd      #$2
* s7_sub_b1be  -  System 7 $B1BE (checked by hand, r=0.57).
s7_sub_b1be:
  0036bc:  4e 56 ff f8          link.w   a6, #$fff8
  0036c0:  48 e7 11 18          movem.l  d3/d7/a3-a4, -(a7)
  0036c4:  70 01                moveq    #$1, d0
  0036c6:  2f 00                move.l   d0, -(a7)
  0036c8:  72 00                moveq    #$0, d1
  0036ca:  2f 01                move.l   d1, -(a7)
  0036cc:  2f 01                move.l   d1, -(a7)
  0036ce:  70 26                moveq    #$26, d0
  0036d0:  2f 00                move.l   d0, -(a7)
  0036d2:  4e ba 2b 50          jsr      $6224(pc)  ; -> EngineDispatch
  0036d6:  2d 78 02 aa ff f8    move.l   $2aa.w, -$8(a6)
  0036dc:  2d 78 01 14 ff fc    move.l   $114.w, -$4(a6)
  0036e2:  20 78 0d 66          movea.l  $d66.w, a0
  0036e6:  28 50                movea.l  (a0), a4
  0036e8:  30 1c                move.w   (a4)+, d0
  0036ea:  48 c0                ext.l    d0
  0036ec:  2e 00                move.l   d0, d7
  0036ee:  4f ef 00 10          lea.l    $10(a7), a7
  0036f2:  60 2e                bra.b    $3722  ; -> L3722
L36f4:
  0036f4:  26 5c                movea.l  (a4)+, a3
  0036f6:  30 2b 00 06          move.w   $6(a3), d0
  0036fa:  48 c0                ext.l    d0
  0036fc:  22 3c 00 00 c0 01    move.l   #$c001, d1
  003702:  c2 80                and.l    d0, d1
  003704:  0c 81 00 00 c0 01    cmpi.l   #$c001, d1
  00370a:  66 12                bne.b    $371e  ; -> L371e
  00370c:  b7 ee ff f8          cmpa.l   -$8(a6), a3
  003710:  65 0c                bcs.b    $371e  ; -> L371e
  003712:  b7 ee ff fc          cmpa.l   -$4(a6), a3
  003716:  62 06                bhi.b    $371e  ; -> L371e
  003718:  2f 0b                move.l   a3, -(a7)
  00371a:  70 04                moveq    #$4, d0
  00371c:  ab 1d                dc.w     $ab1d
L371e:
  00371e:  20 07                move.l   d7, d0
  003720:  53 87                subq.l   #$1, d7
L3722:
  003722:  4a 87                tst.l    d7
  003724:  6e ce                bgt.b    $36f4  ; -> L36f4
  003726:  70 00                moveq    #$0, d0
  003728:  2f 00                move.l   d0, -(a7)
  00372a:  55 8f                subq.l   #$2, a7
  00372c:  48 78 09 10          pea.l    $910.w
  003730:  48 7a 00 24          pea.l    $3756(pc)
  003734:  72 00                moveq    #$0, d1
  003736:  1f 01                move.b   d1, -(a7)
  003738:  74 01                moveq    #$1, d2
  00373a:  1f 02                move.b   d2, -(a7)
  00373c:  4e ba 6d 90          jsr      $a4ce(pc)  ; -> s7_sub_b14e
  003740:  12 1f                move.b   (a7)+, d1
  003742:  20 1f                move.l   (a7)+, d0
  003744:  74 00                moveq    #$0, d2
  003746:  14 01                move.b   d1, d2
  003748:  57 c0                seq.b    d0
  00374a:  44 00                neg.b    d0
  00374c:  4c ee 18 88 ff e8    movem.l  -$18(a6), d3/d7/a3-a4
  003752:  4e 5e                unlk     a6
  003754:  4e 75                rts
  003756:  0a 44 41 ca 48 61 6e 64 dc.b     $0A, $44, $41, $CA, $48, $61, $6E, $64  ; .DA.Hand
  00375e:  6c 65 72 00          dc.b     $6C, $65, $72, $00  ; ler.
* GA_GetPixel  -  System 7 $B23E (same trap slot $F94, code r=0.83).
* S7: Patch #81 replaces _GetPixel ($A865); card commands: $0D $29 $33
GA_GetPixel:
  003762:  4e 56 ff f6          link.w   a6, #$fff6
  003766:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  00376a:  38 2e 00 08          move.w   $8(a6), d4
  00376e:  3a 2e 00 0a          move.w   $a(a6), d5
  003772:  4e ba da bc          jsr      $1230(pc)  ; -> GetA5
  003776:  20 40                movea.l  d0, a0
  003778:  20 50                movea.l  (a0), a0
  00377a:  28 50                movea.l  (a0), a4
  00377c:  30 2c 00 06          move.w   $6(a4), d0
  003780:  48 c0                ext.l    d0
  003782:  6c 00 00 b4          bge.w    $3838  ; -> L3838
  003786:  20 6c 00 02          movea.l  $2(a4), a0
  00378a:  20 50                movea.l  (a0), a0
  00378c:  20 10                move.l   (a0), d0
  00378e:  b0 b8 08 24          cmp.l    $824.w, d0
  003792:  67 00 00 a4          beq.w    $3838  ; -> L3838
  003796:  70 00                moveq    #$0, d0
  003798:  2f 00                move.l   d0, -(a7)
  00379a:  2f 2c 00 02          move.l   $2(a4), -(a7)
  00379e:  4e ba 0a 7a          jsr      $421a(pc)  ; -> s7_sub_bd94
  0037a2:  2d 40 ff f6          move.l   d0, -$a(a6)
  0037a6:  20 6c 00 02          movea.l  $2(a4), a0
  0037aa:  26 50                movea.l  (a0), a3
  0037ac:  30 2b 00 04          move.w   $4(a3), d0
  0037b0:  48 c0                ext.l    d0
  0037b2:  22 3c 00 00 3f ff    move.l   #$3fff, d1
  0037b8:  c2 80                and.l    d0, d1
  0037ba:  48 c4                ext.l    d4
  0037bc:  30 2b 00 06          move.w   $6(a3), d0
  0037c0:  48 c0                ext.l    d0
  0037c2:  24 04                move.l   d4, d2
  0037c4:  94 80                sub.l    d0, d2
  0037c6:  4c 01 28 00          muls.l   d1, d2
  0037ca:  d5 ae ff f6          add.l    d2, -$a(a6)
  0037ce:  30 2b 00 20          move.w   $20(a3), d0
  0037d2:  48 c0                ext.l    d0
  0037d4:  2c 00                move.l   d0, d6
  0037d6:  30 2b 00 08          move.w   $8(a3), d0
  0037da:  48 c0                ext.l    d0
  0037dc:  2d 40 ff fc          move.l   d0, -$4(a6)
  0037e0:  1d 7c 00 01 ff fb    move.b   #$1, -$5(a6)
  0037e6:  48 6e ff fb          pea.l    -$5(a6)
  0037ea:  4e ba 6d 32          jsr      $a51e(pc)  ; -> sub_a51e
  0037ee:  2f 06                move.l   d6, -(a7)
  0037f0:  48 c5                ext.l    d5
  0037f2:  20 05                move.l   d5, d0
  0037f4:  90 ae ff fc          sub.l    -$4(a6), d0
  0037f8:  4c 06 08 00          muls.l   d6, d0
  0037fc:  2f 00                move.l   d0, -(a7)
  0037fe:  2f 2e ff f6          move.l   -$a(a6), -(a7)
  003802:  4e ba 17 40          jsr      $4f44(pc)  ; -> BitFieldExtract
  003806:  2e 00                move.l   d0, d7
  003808:  48 6e ff fb          pea.l    -$5(a6)
  00380c:  4e ba 6d 10          jsr      $a51e(pc)  ; -> sub_a51e
  003810:  30 2b 00 1e          move.w   $1e(a3), d0
  003814:  48 c0                ext.l    d0
  003816:  72 10                moveq    #$10, d1
  003818:  b2 80                cmp.l    d0, d1
  00381a:  4f ef 00 14          lea.l    $14(a7), a7
  00381e:  66 0c                bne.b    $382c  ; -> L382c
  003820:  4a 87                tst.l    d7
  003822:  57 c0                seq.b    d0
  003824:  44 00                neg.b    d0
  003826:  1d 40 00 0c          move.b   d0, $c(a6)
  00382a:  60 30                bra.b    $385c  ; -> L385c
L382c:
  00382c:  4a 87                tst.l    d7
  00382e:  56 c0                sne.b    d0
  003830:  44 00                neg.b    d0
  003832:  1d 40 00 0c          move.b   d0, $c(a6)
  003836:  60 24                bra.b    $385c  ; -> L385c
L3838:
  003838:  4e ba 4e d6          jsr      $8710(pc)  ; -> s7_sub_6e14
  00383c:  72 00                moveq    #$0, d1
  00383e:  12 00                move.b   d0, d1
  003840:  67 f6                beq.b    $3838  ; -> L3838
  003842:  55 8f                subq.l   #$2, a7
  003844:  3f 05                move.w   d5, -(a7)
  003846:  3f 04                move.w   d4, -(a7)
  003848:  48 78 0f 94          pea.l    $f94.w
  00384c:  4e ba 4e 4e          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003850:  58 8f                addq.l   #$4, a7
  003852:  2f 00                move.l   d0, -(a7)
  003854:  20 5f                movea.l  (a7)+, a0
  003856:  4e 90                jsr      (a0)
  003858:  1d 5f 00 0c          move.b   (a7)+, $c(a6)
L385c:
  00385c:  4c ee 18 f0 ff de    movem.l  -$22(a6), d4-d7/a3-a4
  003862:  4e 5e                unlk     a6
  003864:  4e 74 00 04          rtd      #$4
* GA_GetCPixel  -  System 7 $B34C (same trap slot $165C, code r=0.84).
* S7: Patch #80 replaces _GetCPixel ($AA17); card commands: $0D $29 $33
GA_GetCPixel:
  003868:  4e 56 ff f6          link.w   a6, #$fff6
  00386c:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  003870:  3a 2e 00 0c          move.w   $c(a6), d5
  003874:  3c 2e 00 0e          move.w   $e(a6), d6
  003878:  4e ba d9 b6          jsr      $1230(pc)  ; -> GetA5
  00387c:  20 40                movea.l  d0, a0
  00387e:  20 50                movea.l  (a0), a0
  003880:  28 50                movea.l  (a0), a4
  003882:  30 2c 00 06          move.w   $6(a4), d0
  003886:  48 c0                ext.l    d0
  003888:  6c 00 00 9a          bge.w    $3924  ; -> L3924
  00388c:  20 6c 00 02          movea.l  $2(a4), a0
  003890:  20 50                movea.l  (a0), a0
  003892:  20 10                move.l   (a0), d0
  003894:  b0 b8 08 24          cmp.l    $824.w, d0
  003898:  67 00 00 8a          beq.w    $3924  ; -> L3924
  00389c:  70 00                moveq    #$0, d0
  00389e:  2f 00                move.l   d0, -(a7)
  0038a0:  2f 2c 00 02          move.l   $2(a4), -(a7)
  0038a4:  4e ba 09 74          jsr      $421a(pc)  ; -> s7_sub_bd94
  0038a8:  2d 40 ff f6          move.l   d0, -$a(a6)
  0038ac:  20 6c 00 02          movea.l  $2(a4), a0
  0038b0:  26 50                movea.l  (a0), a3
  0038b2:  30 2b 00 04          move.w   $4(a3), d0
  0038b6:  48 c0                ext.l    d0
  0038b8:  22 3c 00 00 3f ff    move.l   #$3fff, d1
  0038be:  c2 80                and.l    d0, d1
  0038c0:  48 c5                ext.l    d5
  0038c2:  30 2b 00 06          move.w   $6(a3), d0
  0038c6:  48 c0                ext.l    d0
  0038c8:  24 05                move.l   d5, d2
  0038ca:  94 80                sub.l    d0, d2
  0038cc:  4c 01 28 00          muls.l   d1, d2
  0038d0:  d5 ae ff f6          add.l    d2, -$a(a6)
  0038d4:  30 2b 00 20          move.w   $20(a3), d0
  0038d8:  48 c0                ext.l    d0
  0038da:  2e 00                move.l   d0, d7
  0038dc:  30 2b 00 08          move.w   $8(a3), d0
  0038e0:  48 c0                ext.l    d0
  0038e2:  28 00                move.l   d0, d4
  0038e4:  1d 7c 00 01 ff fb    move.b   #$1, -$5(a6)
  0038ea:  48 6e ff fb          pea.l    -$5(a6)
  0038ee:  4e ba 6c 2e          jsr      $a51e(pc)  ; -> sub_a51e
  0038f2:  2f 07                move.l   d7, -(a7)
  0038f4:  48 c6                ext.l    d6
  0038f6:  20 06                move.l   d6, d0
  0038f8:  90 84                sub.l    d4, d0
  0038fa:  4c 07 08 00          muls.l   d7, d0
  0038fe:  2f 00                move.l   d0, -(a7)
  003900:  2f 2e ff f6          move.l   -$a(a6), -(a7)
  003904:  4e ba 16 3e          jsr      $4f44(pc)  ; -> BitFieldExtract
  003908:  2d 40 ff fc          move.l   d0, -$4(a6)
  00390c:  48 6e ff fb          pea.l    -$5(a6)
  003910:  4e ba 6c 0c          jsr      $a51e(pc)  ; -> sub_a51e
  003914:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  003918:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00391c:  aa 34                dc.w     $aa34
  00391e:  4f ef 00 14          lea.l    $14(a7), a7
  003922:  60 22                bra.b    $3946  ; -> L3946
L3924:
  003924:  4e ba 4d ea          jsr      $8710(pc)  ; -> s7_sub_6e14
  003928:  72 00                moveq    #$0, d1
  00392a:  12 00                move.b   d0, d1
  00392c:  67 f6                beq.b    $3924  ; -> L3924
  00392e:  3f 06                move.w   d6, -(a7)
  003930:  3f 05                move.w   d5, -(a7)
  003932:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003936:  48 78 16 5c          pea.l    $165c.w
  00393a:  4e ba 4d 60          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00393e:  58 8f                addq.l   #$4, a7
  003940:  2f 00                move.l   d0, -(a7)
  003942:  20 5f                movea.l  (a7)+, a0
  003944:  4e 90                jsr      (a0)
L3946:
  003946:  4c ee 18 f0 ff de    movem.l  -$22(a6), d4-d7/a3-a4
  00394c:  4e 5e                unlk     a6
  00394e:  4e 74 00 08          rtd      #$8
* GA_GetForeColor  -  System 7 $B43E (same trap slot $1664, code r=0.90).
* S7: Patch #67 replaces _GetForeColor ($AA19); card commands: $36
GA_GetForeColor:
  003952:  4e 56 ff f2          link.w   a6, #$fff2
  003956:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  00395a:  28 6e 00 08          movea.l  $8(a6), a4
  00395e:  4e ba d8 d0          jsr      $1230(pc)  ; -> GetA5
  003962:  20 40                movea.l  d0, a0
  003964:  20 50                movea.l  (a0), a0
  003966:  26 50                movea.l  (a0), a3
  003968:  2f 0c                move.l   a4, -(a7)
  00396a:  48 78 16 64          pea.l    $1664.w
  00396e:  4e ba 4d 2c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003972:  58 8f                addq.l   #$4, a7
  003974:  2f 00                move.l   d0, -(a7)
  003976:  20 5f                movea.l  (a7)+, a0
  003978:  4e 90                jsr      (a0)
  00397a:  30 2b 00 06          move.w   $6(a3), d0
  00397e:  48 c0                ext.l    d0
  003980:  6c 5c                bge.b    $39de  ; -> L39de
  003982:  2d 78 0c c8 ff f6    move.l   $cc8.w, -$a(a6)
  003988:  21 f8 08 a4 0c c8    move.l   $8a4.w, $cc8.w
  00398e:  41 ee ff fa          lea.l    -$6(a6), a0
  003992:  22 4c                movea.l  a4, a1
  003994:  20 d9                move.l   (a1)+, (a0)+
  003996:  30 d9                move.w   (a1)+, (a0)+
  003998:  59 8f                subq.l   #$4, a7
  00399a:  48 6e ff fa          pea.l    -$6(a6)
  00399e:  aa 33                dc.w     $aa33
  0039a0:  2e 1f                move.l   (a7)+, d7
  0039a2:  21 ee ff f6 0c c8    move.l   -$a(a6), $cc8.w
  0039a8:  be ab 00 50          cmp.l    $50(a3), d7
  0039ac:  67 30                beq.b    $39de  ; -> L39de
  0039ae:  27 47 00 50          move.l   d7, $50(a3)
  0039b2:  70 00                moveq    #$0, d0
  0039b4:  2f 00                move.l   d0, -(a7)
  0039b6:  4e ba 4e 6a          jsr      $8822(pc)  ; -> s7_sub_6f1c
  0039ba:  28 40                movea.l  d0, a4
  0039bc:  b9 cb                cmpa.l   a3, a4
  0039be:  58 8f                addq.l   #$4, a7
  0039c0:  66 1c                bne.b    $39de  ; -> L39de
  0039c2:  70 00                moveq    #$0, d0
  0039c4:  2d 40 ff f2          move.l   d0, -$e(a6)
  0039c8:  72 01                moveq    #$1, d1
  0039ca:  2f 01                move.l   d1, -(a7)
  0039cc:  2f 01                move.l   d1, -(a7)
  0039ce:  48 6e ff f2          pea.l    -$e(a6)
  0039d2:  70 36                moveq    #$36, d0
  0039d4:  2f 00                move.l   d0, -(a7)
  0039d6:  4e ba 28 4c          jsr      $6224(pc)  ; -> EngineDispatch
  0039da:  4f ef 00 10          lea.l    $10(a7), a7
L39de:
  0039de:  4c ee 18 80 ff e6    movem.l  -$1a(a6), d7/a3-a4
  0039e4:  4e 5e                unlk     a6
  0039e6:  4e 74 00 04          rtd      #$4
* GA_GetBackColor  -  System 7 $B4CA (same trap slot $1668, code r=0.90).
* S7: Patch #68 replaces _GetBackColor ($AA1A); card commands: $37
GA_GetBackColor:
  0039ea:  4e 56 ff f2          link.w   a6, #$fff2
  0039ee:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  0039f2:  28 6e 00 08          movea.l  $8(a6), a4
  0039f6:  4e ba d8 38          jsr      $1230(pc)  ; -> GetA5
  0039fa:  20 40                movea.l  d0, a0
  0039fc:  20 50                movea.l  (a0), a0
  0039fe:  26 50                movea.l  (a0), a3
  003a00:  2f 0c                move.l   a4, -(a7)
  003a02:  48 78 16 68          pea.l    $1668.w
  003a06:  4e ba 4c 94          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003a0a:  58 8f                addq.l   #$4, a7
  003a0c:  2f 00                move.l   d0, -(a7)
  003a0e:  20 5f                movea.l  (a7)+, a0
  003a10:  4e 90                jsr      (a0)
  003a12:  30 2b 00 06          move.w   $6(a3), d0
  003a16:  48 c0                ext.l    d0
  003a18:  6c 5c                bge.b    $3a76  ; -> L3a76
  003a1a:  2d 78 0c c8 ff f6    move.l   $cc8.w, -$a(a6)
  003a20:  21 f8 08 a4 0c c8    move.l   $8a4.w, $cc8.w
  003a26:  41 ee ff fa          lea.l    -$6(a6), a0
  003a2a:  22 4c                movea.l  a4, a1
  003a2c:  20 d9                move.l   (a1)+, (a0)+
  003a2e:  30 d9                move.w   (a1)+, (a0)+
  003a30:  59 8f                subq.l   #$4, a7
  003a32:  48 6e ff fa          pea.l    -$6(a6)
  003a36:  aa 33                dc.w     $aa33
  003a38:  2e 1f                move.l   (a7)+, d7
  003a3a:  21 ee ff f6 0c c8    move.l   -$a(a6), $cc8.w
  003a40:  be ab 00 54          cmp.l    $54(a3), d7
  003a44:  67 30                beq.b    $3a76  ; -> L3a76
  003a46:  27 47 00 54          move.l   d7, $54(a3)
  003a4a:  70 00                moveq    #$0, d0
  003a4c:  2f 00                move.l   d0, -(a7)
  003a4e:  4e ba 4d d2          jsr      $8822(pc)  ; -> s7_sub_6f1c
  003a52:  28 40                movea.l  d0, a4
  003a54:  b9 cb                cmpa.l   a3, a4
  003a56:  58 8f                addq.l   #$4, a7
  003a58:  66 1c                bne.b    $3a76  ; -> L3a76
  003a5a:  70 00                moveq    #$0, d0
  003a5c:  2d 40 ff f2          move.l   d0, -$e(a6)
  003a60:  72 01                moveq    #$1, d1
  003a62:  2f 01                move.l   d1, -(a7)
  003a64:  2f 01                move.l   d1, -(a7)
  003a66:  48 6e ff f2          pea.l    -$e(a6)
  003a6a:  70 37                moveq    #$37, d0
  003a6c:  2f 00                move.l   d0, -(a7)
  003a6e:  4e ba 27 b4          jsr      $6224(pc)  ; -> EngineDispatch
  003a72:  4f ef 00 10          lea.l    $10(a7), a7
L3a76:
  003a76:  4c ee 18 80 ff e6    movem.l  -$1a(a6), d7/a3-a4
  003a7c:  4e 5e                unlk     a6
  003a7e:  4e 74 00 04          rtd      #$4
* GA_NewPixMap  -  System 7 $B556 (identical code).
* S7: Patch #76 replaces _NewPixMap ($AA03); no EngineDispatch command found
GA_NewPixMap:
  003a82:  4e 56 00 00          link.w   a6, #$0
  003a86:  2f 0b                move.l   a3, -(a7)
  003a88:  59 8f                subq.l   #$4, a7
  003a8a:  48 78 16 0c          pea.l    $160c.w
  003a8e:  4e ba 4c 0c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003a92:  58 8f                addq.l   #$4, a7
  003a94:  2f 00                move.l   d0, -(a7)
  003a96:  20 5f                movea.l  (a7)+, a0
  003a98:  4e 90                jsr      (a0)
  003a9a:  26 5f                movea.l  (a7)+, a3
  003a9c:  2d 4b 00 08          move.l   a3, $8(a6)
  003aa0:  26 6e ff fc          movea.l  -$4(a6), a3
  003aa4:  4e 5e                unlk     a6
  003aa6:  4e 75                rts
* GA_CopyPixMap  -  System 7 $B57E (same trap slot $1614, code r=0.93).
* S7: Patch #57 replaces _CopyPixMap ($AA05); card commands: $26
GA_CopyPixMap:
  003aa8:  4e 56 00 00          link.w   a6, #$0
  003aac:  48 e7 00 18          movem.l  a3-a4, -(a7)
  003ab0:  28 6e 00 08          movea.l  $8(a6), a4
  003ab4:  70 00                moveq    #$0, d0
  003ab6:  2f 00                move.l   d0, -(a7)
  003ab8:  4e ba 4d 68          jsr      $8822(pc)  ; -> s7_sub_6f1c
  003abc:  26 40                movea.l  d0, a3
  003abe:  20 0b                move.l   a3, d0
  003ac0:  58 8f                addq.l   #$4, a7
  003ac2:  67 24                beq.b    $3ae8  ; -> L3ae8
  003ac4:  30 2b 00 06          move.w   $6(a3), d0
  003ac8:  48 c0                ext.l    d0
  003aca:  6c 1c                bge.b    $3ae8  ; -> L3ae8
  003acc:  b9 eb 00 02          cmpa.l   $2(a3), a4
  003ad0:  66 16                bne.b    $3ae8  ; -> L3ae8
  003ad2:  70 01                moveq    #$1, d0
  003ad4:  2f 00                move.l   d0, -(a7)
  003ad6:  72 00                moveq    #$0, d1
  003ad8:  2f 01                move.l   d1, -(a7)
  003ada:  2f 01                move.l   d1, -(a7)
  003adc:  70 26                moveq    #$26, d0
  003ade:  2f 00                move.l   d0, -(a7)
  003ae0:  4e ba 27 42          jsr      $6224(pc)  ; -> EngineDispatch
  003ae4:  4f ef 00 10          lea.l    $10(a7), a7
L3ae8:
  003ae8:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003aec:  2f 0c                move.l   a4, -(a7)
  003aee:  48 78 16 14          pea.l    $1614.w
  003af2:  4e ba 4b a8          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003af6:  58 8f                addq.l   #$4, a7
  003af8:  2f 00                move.l   d0, -(a7)
  003afa:  20 5f                movea.l  (a7)+, a0
  003afc:  4e 90                jsr      (a0)
  003afe:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  003b04:  4e 5e                unlk     a6
  003b06:  4e 74 00 08          rtd      #$8
* GA_PenPixPat  -  System 7 $B5E4 (same trap slot $1628, code r=0.87).
* S7: Patch #58 replaces _PenPixPat ($AA0A); card commands: $2A
GA_PenPixPat:
  003b0a:  4e 56 ff f8          link.w   a6, #$fff8
  003b0e:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  003b12:  70 00                moveq    #$0, d0
  003b14:  2f 00                move.l   d0, -(a7)
  003b16:  4e ba 4d 0a          jsr      $8822(pc)  ; -> s7_sub_6f1c
  003b1a:  26 40                movea.l  d0, a3
  003b1c:  20 6e 00 08          movea.l  $8(a6), a0
  003b20:  20 50                movea.l  (a0), a0
  003b22:  20 68 00 02          movea.l  $2(a0), a0
  003b26:  20 50                movea.l  (a0), a0
  003b28:  20 68 00 2a          movea.l  $2a(a0), a0
  003b2c:  28 50                movea.l  (a0), a4
  003b2e:  4a 94                tst.l    (a4)
  003b30:  58 8f                addq.l   #$4, a7
  003b32:  66 06                bne.b    $3b3a  ; -> L3b3a
  003b34:  59 8f                subq.l   #$4, a7
  003b36:  aa 28                dc.w     $aa28
  003b38:  28 9f                move.l   (a7)+, (a4)
L3b3a:
  003b3a:  4e ba d6 f4          jsr      $1230(pc)  ; -> GetA5
  003b3e:  20 40                movea.l  d0, a0
  003b40:  20 50                movea.l  (a0), a0
  003b42:  b7 d0                cmpa.l   (a0), a3
  003b44:  66 00 00 8c          bne.w    $3bd2  ; -> L3bd2
  003b48:  30 2b 00 06          move.w   $6(a3), d0
  003b4c:  48 c0                ext.l    d0
  003b4e:  5d c7                slt.b    d7
  003b50:  44 07                neg.b    d7
  003b52:  4a 07                tst.b    d7
  003b54:  67 1c                beq.b    $3b72  ; -> L3b72
  003b56:  70 01                moveq    #$1, d0
  003b58:  2f 00                move.l   d0, -(a7)
  003b5a:  48 6e 00 08          pea.l    $8(a6)
  003b5e:  2f 00                move.l   d0, -(a7)
  003b60:  48 6b 00 3a          pea.l    $3a(a3)
  003b64:  4e ba dc a2          jsr      $1808(pc)  ; -> s7_sub_91aa
  003b68:  72 00                moveq    #$0, d1
  003b6a:  12 00                move.b   d0, d1
  003b6c:  4f ef 00 10          lea.l    $10(a7), a7
  003b70:  67 28                beq.b    $3b9a  ; -> L3b9a
L3b72:
  003b72:  70 00                moveq    #$0, d0
  003b74:  10 07                move.b   d7, d0
  003b76:  66 6e                bne.b    $3be6  ; -> L3be6
  003b78:  70 00                moveq    #$0, d0
  003b7a:  2f 00                move.l   d0, -(a7)
  003b7c:  20 6e 00 08          movea.l  $8(a6), a0
  003b80:  20 50                movea.l  (a0), a0
  003b82:  48 68 00 14          pea.l    $14(a0)
  003b86:  2f 00                move.l   d0, -(a7)
  003b88:  48 6b 00 3a          pea.l    $3a(a3)
  003b8c:  4e ba dc 7a          jsr      $1808(pc)  ; -> s7_sub_91aa
  003b90:  72 00                moveq    #$0, d1
  003b92:  12 00                move.b   d0, d1
  003b94:  4f ef 00 10          lea.l    $10(a7), a7
  003b98:  66 4c                bne.b    $3be6  ; -> L3be6
L3b9a:
  003b9a:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003b9e:  48 78 16 28          pea.l    $1628.w
  003ba2:  4e ba 4a f8          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003ba6:  58 8f                addq.l   #$4, a7
  003ba8:  2f 00                move.l   d0, -(a7)
  003baa:  20 5f                movea.l  (a7)+, a0
  003bac:  4e 90                jsr      (a0)
  003bae:  70 00                moveq    #$0, d0
  003bb0:  2d 40 ff f8          move.l   d0, -$8(a6)
  003bb4:  72 01                moveq    #$1, d1
  003bb6:  2d 41 ff fc          move.l   d1, -$4(a6)
  003bba:  2f 01                move.l   d1, -(a7)
  003bbc:  70 02                moveq    #$2, d0
  003bbe:  2f 00                move.l   d0, -(a7)
  003bc0:  48 6e ff f8          pea.l    -$8(a6)
  003bc4:  70 2a                moveq    #$2a, d0
  003bc6:  2f 00                move.l   d0, -(a7)
  003bc8:  4e ba 26 5a          jsr      $6224(pc)  ; -> EngineDispatch
  003bcc:  4f ef 00 10          lea.l    $10(a7), a7
  003bd0:  60 14                bra.b    $3be6  ; -> L3be6
L3bd2:
  003bd2:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003bd6:  48 78 16 28          pea.l    $1628.w
  003bda:  4e ba 4a c0          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003bde:  58 8f                addq.l   #$4, a7
  003be0:  2f 00                move.l   d0, -(a7)
  003be2:  20 5f                movea.l  (a7)+, a0
  003be4:  4e 90                jsr      (a0)
L3be6:
  003be6:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  003bec:  4e 5e                unlk     a6
  003bee:  4e 74 00 04          rtd      #$4
* GA_BackPixPat  -  System 7 $B6DE (same trap slot $162C, code r=0.87).
* S7: Patch #59 replaces _BackPixPat ($AA0B); card commands: $2A
GA_BackPixPat:
  003bf2:  4e 56 ff f8          link.w   a6, #$fff8
  003bf6:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  003bfa:  70 00                moveq    #$0, d0
  003bfc:  2f 00                move.l   d0, -(a7)
  003bfe:  4e ba 4c 22          jsr      $8822(pc)  ; -> s7_sub_6f1c
  003c02:  26 40                movea.l  d0, a3
  003c04:  20 6e 00 08          movea.l  $8(a6), a0
  003c08:  20 50                movea.l  (a0), a0
  003c0a:  20 68 00 02          movea.l  $2(a0), a0
  003c0e:  20 50                movea.l  (a0), a0
  003c10:  20 68 00 2a          movea.l  $2a(a0), a0
  003c14:  28 50                movea.l  (a0), a4
  003c16:  4a 94                tst.l    (a4)
  003c18:  58 8f                addq.l   #$4, a7
  003c1a:  66 06                bne.b    $3c22  ; -> L3c22
  003c1c:  59 8f                subq.l   #$4, a7
  003c1e:  aa 28                dc.w     $aa28
  003c20:  28 9f                move.l   (a7)+, (a4)
L3c22:
  003c22:  4e ba d6 0c          jsr      $1230(pc)  ; -> GetA5
  003c26:  20 40                movea.l  d0, a0
  003c28:  20 50                movea.l  (a0), a0
  003c2a:  b7 d0                cmpa.l   (a0), a3
  003c2c:  66 00 00 8c          bne.w    $3cba  ; -> L3cba
  003c30:  30 2b 00 06          move.w   $6(a3), d0
  003c34:  48 c0                ext.l    d0
  003c36:  5d c7                slt.b    d7
  003c38:  44 07                neg.b    d7
  003c3a:  4a 07                tst.b    d7
  003c3c:  67 1c                beq.b    $3c5a  ; -> L3c5a
  003c3e:  70 01                moveq    #$1, d0
  003c40:  2f 00                move.l   d0, -(a7)
  003c42:  48 6e 00 08          pea.l    $8(a6)
  003c46:  2f 00                move.l   d0, -(a7)
  003c48:  48 6b 00 20          pea.l    $20(a3)
  003c4c:  4e ba db ba          jsr      $1808(pc)  ; -> s7_sub_91aa
  003c50:  72 00                moveq    #$0, d1
  003c52:  12 00                move.b   d0, d1
  003c54:  4f ef 00 10          lea.l    $10(a7), a7
  003c58:  67 28                beq.b    $3c82  ; -> L3c82
L3c5a:
  003c5a:  70 00                moveq    #$0, d0
  003c5c:  10 07                move.b   d7, d0
  003c5e:  66 6e                bne.b    $3cce  ; -> L3cce
  003c60:  70 00                moveq    #$0, d0
  003c62:  2f 00                move.l   d0, -(a7)
  003c64:  20 6e 00 08          movea.l  $8(a6), a0
  003c68:  20 50                movea.l  (a0), a0
  003c6a:  48 68 00 14          pea.l    $14(a0)
  003c6e:  2f 00                move.l   d0, -(a7)
  003c70:  48 6b 00 20          pea.l    $20(a3)
  003c74:  4e ba db 92          jsr      $1808(pc)  ; -> s7_sub_91aa
  003c78:  72 00                moveq    #$0, d1
  003c7a:  12 00                move.b   d0, d1
  003c7c:  4f ef 00 10          lea.l    $10(a7), a7
  003c80:  66 4c                bne.b    $3cce  ; -> L3cce
L3c82:
  003c82:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003c86:  48 78 16 2c          pea.l    $162c.w
  003c8a:  4e ba 4a 10          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003c8e:  58 8f                addq.l   #$4, a7
  003c90:  2f 00                move.l   d0, -(a7)
  003c92:  20 5f                movea.l  (a7)+, a0
  003c94:  4e 90                jsr      (a0)
  003c96:  70 00                moveq    #$0, d0
  003c98:  2d 40 ff f8          move.l   d0, -$8(a6)
  003c9c:  72 02                moveq    #$2, d1
  003c9e:  2d 41 ff fc          move.l   d1, -$4(a6)
  003ca2:  70 01                moveq    #$1, d0
  003ca4:  2f 00                move.l   d0, -(a7)
  003ca6:  2f 01                move.l   d1, -(a7)
  003ca8:  48 6e ff f8          pea.l    -$8(a6)
  003cac:  70 2a                moveq    #$2a, d0
  003cae:  2f 00                move.l   d0, -(a7)
  003cb0:  4e ba 25 72          jsr      $6224(pc)  ; -> EngineDispatch
  003cb4:  4f ef 00 10          lea.l    $10(a7), a7
  003cb8:  60 14                bra.b    $3cce  ; -> L3cce
L3cba:
  003cba:  2f 2e 00 08          move.l   $8(a6), -(a7)
  003cbe:  48 78 16 2c          pea.l    $162c.w
  003cc2:  4e ba 49 d8          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003cc6:  58 8f                addq.l   #$4, a7
  003cc8:  2f 00                move.l   d0, -(a7)
  003cca:  20 5f                movea.l  (a7)+, a0
  003ccc:  4e 90                jsr      (a0)
L3cce:
  003cce:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  003cd4:  4e 5e                unlk     a6
  003cd6:  4e 74 00 04          rtd      #$4
* GA_SetPortPix  -  System 7 $B7D8 (same trap slot $1618, code r=0.94).
* S7: Patch #60 replaces _SetPortPix ($AA06); card commands: $26
GA_SetPortPix:
  003cda:  48 e7 00 18          movem.l  a3-a4, -(a7)
  003cde:  28 6f 00 0c          movea.l  $c(a7), a4
  003ce2:  70 00                moveq    #$0, d0
  003ce4:  2f 00                move.l   d0, -(a7)
  003ce6:  4e ba 4b 3a          jsr      $8822(pc)  ; -> s7_sub_6f1c
  003cea:  26 40                movea.l  d0, a3
  003cec:  4e ba d5 42          jsr      $1230(pc)  ; -> GetA5
  003cf0:  20 40                movea.l  d0, a0
  003cf2:  20 50                movea.l  (a0), a0
  003cf4:  b7 d0                cmpa.l   (a0), a3
  003cf6:  58 8f                addq.l   #$4, a7
  003cf8:  66 1c                bne.b    $3d16  ; -> L3d16
  003cfa:  b9 eb 00 02          cmpa.l   $2(a3), a4
  003cfe:  67 16                beq.b    $3d16  ; -> L3d16
  003d00:  70 01                moveq    #$1, d0
  003d02:  2f 00                move.l   d0, -(a7)
  003d04:  72 00                moveq    #$0, d1
  003d06:  2f 01                move.l   d1, -(a7)
  003d08:  2f 01                move.l   d1, -(a7)
  003d0a:  70 26                moveq    #$26, d0
  003d0c:  2f 00                move.l   d0, -(a7)
  003d0e:  4e ba 25 14          jsr      $6224(pc)  ; -> EngineDispatch
  003d12:  4f ef 00 10          lea.l    $10(a7), a7
L3d16:
  003d16:  2f 0c                move.l   a4, -(a7)
  003d18:  48 78 16 18          pea.l    $1618.w
  003d1c:  4e ba 49 7e          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003d20:  58 8f                addq.l   #$4, a7
  003d22:  2f 00                move.l   d0, -(a7)
  003d24:  20 5f                movea.l  (a7)+, a0
  003d26:  4e 90                jsr      (a0)
  003d28:  4c df 18 00          movem.l  (a7)+, a3-a4
  003d2c:  4e 74 00 04          rtd      #$4
* GA_OpColor  -  System 7 $B83E (same trap slot $1684, code r=0.88).
* S7: Patch #61 replaces _OpColor ($AA21); card commands: $26
GA_OpColor:
  003d30:  4e 56 ff fc          link.w   a6, #$fffc
  003d34:  48 e7 00 18          movem.l  a3-a4, -(a7)
  003d38:  28 6e 00 08          movea.l  $8(a6), a4
  003d3c:  70 00                moveq    #$0, d0
  003d3e:  2f 00                move.l   d0, -(a7)
  003d40:  4e ba 4a e0          jsr      $8822(pc)  ; -> s7_sub_6f1c
  003d44:  26 40                movea.l  d0, a3
  003d46:  4e ba d4 e8          jsr      $1230(pc)  ; -> GetA5
  003d4a:  20 40                movea.l  d0, a0
  003d4c:  20 50                movea.l  (a0), a0
  003d4e:  b7 d0                cmpa.l   (a0), a3
  003d50:  58 8f                addq.l   #$4, a7
  003d52:  66 42                bne.b    $3d96  ; -> L3d96
  003d54:  30 2b 00 06          move.w   $6(a3), d0
  003d58:  48 c0                ext.l    d0
  003d5a:  6c 3a                bge.b    $3d96  ; -> L3d96
  003d5c:  20 6b 00 08          movea.l  $8(a3), a0
  003d60:  20 50                movea.l  (a0), a0
  003d62:  2d 48 ff fc          move.l   a0, -$4(a6)
  003d66:  20 10                move.l   (a0), d0
  003d68:  b0 94                cmp.l    (a4), d0
  003d6a:  66 14                bne.b    $3d80  ; -> L3d80
  003d6c:  20 6e ff fc          movea.l  -$4(a6), a0
  003d70:  70 00                moveq    #$0, d0
  003d72:  30 28 00 04          move.w   $4(a0), d0
  003d76:  72 00                moveq    #$0, d1
  003d78:  32 2c 00 04          move.w   $4(a4), d1
  003d7c:  b2 80                cmp.l    d0, d1
  003d7e:  67 16                beq.b    $3d96  ; -> L3d96
L3d80:
  003d80:  70 01                moveq    #$1, d0
  003d82:  2f 00                move.l   d0, -(a7)
  003d84:  72 00                moveq    #$0, d1
  003d86:  2f 01                move.l   d1, -(a7)
  003d88:  2f 01                move.l   d1, -(a7)
  003d8a:  70 26                moveq    #$26, d0
  003d8c:  2f 00                move.l   d0, -(a7)
  003d8e:  4e ba 24 94          jsr      $6224(pc)  ; -> EngineDispatch
  003d92:  4f ef 00 10          lea.l    $10(a7), a7
L3d96:
  003d96:  2f 0c                move.l   a4, -(a7)
  003d98:  48 78 16 84          pea.l    $1684.w
  003d9c:  4e ba 48 fe          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003da0:  58 8f                addq.l   #$4, a7
  003da2:  2f 00                move.l   d0, -(a7)
  003da4:  20 5f                movea.l  (a7)+, a0
  003da6:  4e 90                jsr      (a0)
  003da8:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  003dae:  4e 5e                unlk     a6
  003db0:  4e 74 00 04          rtd      #$4
* GA_HiliteColor  -  System 7 $B8BE (same trap slot $1688, code r=0.88).
* S7: Patch #62 replaces _HiliteColor ($AA22); card commands: $26
GA_HiliteColor:
  003db4:  4e 56 ff fc          link.w   a6, #$fffc
  003db8:  48 e7 00 18          movem.l  a3-a4, -(a7)
  003dbc:  28 6e 00 08          movea.l  $8(a6), a4
  003dc0:  70 00                moveq    #$0, d0
  003dc2:  2f 00                move.l   d0, -(a7)
  003dc4:  4e ba 4a 5c          jsr      $8822(pc)  ; -> s7_sub_6f1c
  003dc8:  26 40                movea.l  d0, a3
  003dca:  4e ba d4 64          jsr      $1230(pc)  ; -> GetA5
  003dce:  20 40                movea.l  d0, a0
  003dd0:  20 50                movea.l  (a0), a0
  003dd2:  b7 d0                cmpa.l   (a0), a3
  003dd4:  58 8f                addq.l   #$4, a7
  003dd6:  66 44                bne.b    $3e1c  ; -> L3e1c
  003dd8:  30 2b 00 06          move.w   $6(a3), d0
  003ddc:  48 c0                ext.l    d0
  003dde:  6c 3c                bge.b    $3e1c  ; -> L3e1c
  003de0:  20 6b 00 08          movea.l  $8(a3), a0
  003de4:  20 50                movea.l  (a0), a0
  003de6:  5c 88                addq.l   #$6, a0
  003de8:  2d 48 ff fc          move.l   a0, -$4(a6)
  003dec:  20 10                move.l   (a0), d0
  003dee:  b0 94                cmp.l    (a4), d0
  003df0:  66 14                bne.b    $3e06  ; -> L3e06
  003df2:  20 6e ff fc          movea.l  -$4(a6), a0
  003df6:  70 00                moveq    #$0, d0
  003df8:  30 28 00 04          move.w   $4(a0), d0
  003dfc:  72 00                moveq    #$0, d1
  003dfe:  32 2c 00 04          move.w   $4(a4), d1
  003e02:  b2 80                cmp.l    d0, d1
  003e04:  67 16                beq.b    $3e1c  ; -> L3e1c
L3e06:
  003e06:  70 01                moveq    #$1, d0
  003e08:  2f 00                move.l   d0, -(a7)
  003e0a:  72 00                moveq    #$0, d1
  003e0c:  2f 01                move.l   d1, -(a7)
  003e0e:  2f 01                move.l   d1, -(a7)
  003e10:  70 26                moveq    #$26, d0
  003e12:  2f 00                move.l   d0, -(a7)
  003e14:  4e ba 24 0e          jsr      $6224(pc)  ; -> EngineDispatch
  003e18:  4f ef 00 10          lea.l    $10(a7), a7
L3e1c:
  003e1c:  2f 0c                move.l   a4, -(a7)
  003e1e:  48 78 16 88          pea.l    $1688.w
  003e22:  4e ba 48 78          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003e26:  58 8f                addq.l   #$4, a7
  003e28:  2f 00                move.l   d0, -(a7)
  003e2a:  20 5f                movea.l  (a7)+, a0
  003e2c:  4e 90                jsr      (a0)
  003e2e:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  003e34:  4e 5e                unlk     a6
  003e36:  4e 74 00 04          rtd      #$4
* GA_BitMapRgn  -  System 7 $BF0C (same trap slot $115C, code r=0.46).
* S7: Patch #100 replaces _BitMapRgn ($A8D7); card commands: $0D $38
GA_BitMapRgn:
  003e3a:  4e 56 ff fc          link.w   a6, #$fffc
  003e3e:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  003e42:  28 6e 00 0c          movea.l  $c(a6), a4
  003e46:  26 6e 00 08          movea.l  $8(a6), a3
  003e4a:  30 2b 00 0e          move.w   $e(a3), d0
  003e4e:  48 c0                ext.l    d0
  003e50:  2e 00                move.l   d0, d7
  003e52:  70 01                moveq    #$1, d0
  003e54:  b0 87                cmp.l    d7, d0
  003e56:  67 06                beq.b    $3e5e  ; -> L3e5e
  003e58:  70 02                moveq    #$2, d0
  003e5a:  b0 87                cmp.l    d7, d0
  003e5c:  66 2e                bne.b    $3e8c  ; -> L3e8c
L3e5e:
  003e5e:  2d 53 ff fc          move.l   (a3), -$4(a6)
  003e62:  70 01                moveq    #$1, d0
  003e64:  b0 87                cmp.l    d7, d0
  003e66:  66 0e                bne.b    $3e76  ; -> L3e76
  003e68:  59 8f                subq.l   #$4, a7
  003e6a:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  003e6e:  4e ba 66 22          jsr      $a492(pc)  ; -> sub_a492
  003e72:  2d 5f ff fc          move.l   (a7)+, -$4(a6)
L3e76:
  003e76:  70 01                moveq    #$1, d0
  003e78:  2f 00                move.l   d0, -(a7)
  003e7a:  2f 00                move.l   d0, -(a7)
  003e7c:  48 6e ff fc          pea.l    -$4(a6)
  003e80:  72 19                moveq    #$19, d1
  003e82:  2f 01                move.l   d1, -(a7)
  003e84:  4e ba 23 9e          jsr      $6224(pc)  ; -> EngineDispatch
  003e88:  4f ef 00 10          lea.l    $10(a7), a7
L3e8c:
  003e8c:  55 8f                subq.l   #$2, a7
  003e8e:  2f 0c                move.l   a4, -(a7)
  003e90:  2f 0b                move.l   a3, -(a7)
  003e92:  48 78 11 5c          pea.l    $115c.w
  003e96:  4e ba 48 04          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003e9a:  58 8f                addq.l   #$4, a7
  003e9c:  2f 00                move.l   d0, -(a7)
  003e9e:  20 5f                movea.l  (a7)+, a0
  003ea0:  4e 90                jsr      (a0)
  003ea2:  3d 5f 00 10          move.w   (a7)+, $10(a6)
  003ea6:  4c ee 18 80 ff f0    movem.l  -$10(a6), d7/a3-a4
  003eac:  4e 5e                unlk     a6
  003eae:  4e 74 00 08          rtd      #$8
* s7_Lb940  -  System 7 $B940 (similar code, r=0.89).
s7_Lb940:
  003eb2:  4e 56 ff fc          link.w   a6, #$fffc
  003eb6:  48 e7 00 18          movem.l  a3-a4, -(a7)
  003eba:  28 6e 00 08          movea.l  $8(a6), a4
  003ebe:  26 54                movea.l  (a4), a3
  003ec0:  30 2b 00 0e          move.w   $e(a3), d0
  003ec4:  48 c0                ext.l    d0
  003ec6:  72 02                moveq    #$2, d1
  003ec8:  b2 80                cmp.l    d0, d1
  003eca:  67 08                beq.b    $3ed4  ; -> L3ed4
  003ecc:  1d 7c 00 01 00 0c    move.b   #$1, $c(a6)
  003ed2:  60 44                bra.b    $3f18  ; -> L3f18
L3ed4:
  003ed4:  2d 53 ff fc          move.l   (a3), -$4(a6)
  003ed8:  20 6e ff fc          movea.l  -$4(a6), a0
  003edc:  26 50                movea.l  (a0), a3
  003ede:  20 0b                move.l   a3, d0
  003ee0:  66 1c                bne.b    $3efe  ; -> L3efe
  003ee2:  70 01                moveq    #$1, d0
  003ee4:  2f 00                move.l   d0, -(a7)
  003ee6:  2f 00                move.l   d0, -(a7)
  003ee8:  48 6e ff fc          pea.l    -$4(a6)
  003eec:  72 33                moveq    #$33, d1
  003eee:  2f 01                move.l   d1, -(a7)
  003ef0:  4e ba 23 32          jsr      $6224(pc)  ; -> EngineDispatch
  003ef4:  42 2e 00 0c          clr.b    $c(a6)
  003ef8:  4f ef 00 10          lea.l    $10(a7), a7
  003efc:  60 1a                bra.b    $3f18  ; -> L3f18
L3efe:
  003efe:  55 8f                subq.l   #$2, a7
  003f00:  2f 0c                move.l   a4, -(a7)
  003f02:  48 78 1a 74          pea.l    $1a74.w
  003f06:  4e ba 47 94          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003f0a:  58 8f                addq.l   #$4, a7
  003f0c:  2f 00                move.l   d0, -(a7)
  003f0e:  70 01                moveq    #$1, d0
  003f10:  20 5f                movea.l  (a7)+, a0
  003f12:  4e 90                jsr      (a0)
  003f14:  1d 5f 00 0c          move.b   (a7)+, $c(a6)
L3f18:
  003f18:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  003f1e:  4e 5e                unlk     a6
  003f20:  4e 74 00 04          rtd      #$4
* s7_Lb9b4  -  System 7 $B9B4 (similar code, r=0.96).
s7_Lb9b4:
  003f24:  4e 56 ff fc          link.w   a6, #$fffc
  003f28:  2f 0b                move.l   a3, -(a7)
  003f2a:  26 6e 00 08          movea.l  $8(a6), a3
  003f2e:  2f 0b                move.l   a3, -(a7)
  003f30:  48 78 1a 74          pea.l    $1a74.w
  003f34:  4e ba 47 66          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003f38:  58 8f                addq.l   #$4, a7
  003f3a:  2f 00                move.l   d0, -(a7)
  003f3c:  70 02                moveq    #$2, d0
  003f3e:  20 5f                movea.l  (a7)+, a0
  003f40:  4e 90                jsr      (a0)
  003f42:  20 53                movea.l  (a3), a0
  003f44:  2d 50 ff fc          move.l   (a0), -$4(a6)
  003f48:  70 01                moveq    #$1, d0
  003f4a:  2f 00                move.l   d0, -(a7)
  003f4c:  2f 00                move.l   d0, -(a7)
  003f4e:  48 6e ff fc          pea.l    -$4(a6)
  003f52:  72 0f                moveq    #$f, d1
  003f54:  2f 01                move.l   d1, -(a7)
  003f56:  4e ba 22 cc          jsr      $6224(pc)  ; -> EngineDispatch
  003f5a:  26 6e ff f8          movea.l  -$8(a6), a3
  003f5e:  4e 5e                unlk     a6
  003f60:  4e 74 00 04          rtd      #$4
* s7_Lb9fc  -  System 7 $B9FC (similar code, r=0.92).
s7_Lb9fc:
  003f64:  4e 56 00 00          link.w   a6, #$0
  003f68:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  003f6c:  28 6e 00 14          movea.l  $14(a6), a4
  003f70:  2c 2e 00 08          move.l   $8(a6), d6
  003f74:  26 6e 00 1a          movea.l  $1a(a6), a3
  003f78:  55 8f                subq.l   #$2, a7
  003f7a:  2f 0b                move.l   a3, -(a7)
  003f7c:  3f 2e 00 18          move.w   $18(a6), -(a7)
  003f80:  2f 0c                move.l   a4, -(a7)
  003f82:  2f 2e 00 10          move.l   $10(a6), -(a7)
  003f86:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  003f8a:  2f 06                move.l   d6, -(a7)
  003f8c:  48 78 1a 74          pea.l    $1a74.w
  003f90:  4e ba 47 0a          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  003f94:  58 8f                addq.l   #$4, a7
  003f96:  2f 00                move.l   d0, -(a7)
  003f98:  70 00                moveq    #$0, d0
  003f9a:  20 5f                movea.l  (a7)+, a0
  003f9c:  4e 90                jsr      (a0)
  003f9e:  3e 1f                move.w   (a7)+, d7
  003fa0:  48 c7                ext.l    d7
  003fa2:  4a 87                tst.l    d7
  003fa4:  66 16                bne.b    $3fbc  ; -> L3fbc
  003fa6:  70 08                moveq    #$8, d0
  003fa8:  c0 86                and.l    d6, d0
  003faa:  67 10                beq.b    $3fbc  ; -> L3fbc
  003fac:  20 53                movea.l  (a3), a0
  003fae:  20 68 00 02          movea.l  $2(a0), a0
  003fb2:  20 50                movea.l  (a0), a0
  003fb4:  00 a8 00 00 00 01 00 2e ori.l    #$1, $2e(a0)
L3fbc:
  003fbc:  3d 47 00 1e          move.w   d7, $1e(a6)
  003fc0:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  003fc6:  4e 5e                unlk     a6
  003fc8:  4e 74 00 16          rtd      #$16
* s7_Lba64  -  System 7 $BA64 (similar code, r=0.83).
s7_Lba64:
  003fcc:  4e 56 ff fc          link.w   a6, #$fffc
  003fd0:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  003fd4:  28 6e 00 1a          movea.l  $1a(a6), a4
  003fd8:  20 54                movea.l  (a4), a0
  003fda:  20 68 00 02          movea.l  $2(a0), a0
  003fde:  26 50                movea.l  (a0), a3
  003fe0:  30 2b 00 0e          move.w   $e(a3), d0
  003fe4:  48 c0                ext.l    d0
  003fe6:  2e 00                move.l   d0, d7
  003fe8:  2d 53 ff fc          move.l   (a3), -$4(a6)
  003fec:  70 01                moveq    #$1, d0
  003fee:  b0 87                cmp.l    d7, d0
  003ff0:  66 0e                bne.b    $4000  ; -> L4000
  003ff2:  59 8f                subq.l   #$4, a7
  003ff4:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  003ff8:  4e ba 64 98          jsr      $a492(pc)  ; -> sub_a492
  003ffc:  2d 5f ff fc          move.l   (a7)+, -$4(a6)
L4000:
  004000:  70 01                moveq    #$1, d0
  004002:  2f 00                move.l   d0, -(a7)
  004004:  2f 00                move.l   d0, -(a7)
  004006:  48 6e ff fc          pea.l    -$4(a6)
  00400a:  72 19                moveq    #$19, d1
  00400c:  2f 01                move.l   d1, -(a7)
  00400e:  4e ba 22 14          jsr      $6224(pc)  ; -> EngineDispatch
  004012:  59 8f                subq.l   #$4, a7
  004014:  2f 0c                move.l   a4, -(a7)
  004016:  3f 2e 00 18          move.w   $18(a6), -(a7)
  00401a:  2f 2e 00 14          move.l   $14(a6), -(a7)
  00401e:  2f 2e 00 10          move.l   $10(a6), -(a7)
  004022:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  004026:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00402a:  48 78 1a 74          pea.l    $1a74.w
  00402e:  4e ba 46 6c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  004032:  58 8f                addq.l   #$4, a7
  004034:  2f 00                move.l   d0, -(a7)
  004036:  70 03                moveq    #$3, d0
  004038:  20 5f                movea.l  (a7)+, a0
  00403a:  4e 90                jsr      (a0)
  00403c:  2d 5f 00 1e          move.l   (a7)+, $1e(a6)
  004040:  4f ef 00 10          lea.l    $10(a7), a7
  004044:  4c ee 18 80 ff f0    movem.l  -$10(a6), d7/a3-a4
  00404a:  4e 5e                unlk     a6
  00404c:  4e 74 00 16          rtd      #$16
* s7_Lbb14  -  System 7 $BB14 (similar code, r=0.86).
s7_Lbb14:
  004050:  4e 56 ff fc          link.w   a6, #$fffc
  004054:  48 e7 00 18          movem.l  a3-a4, -(a7)
  004058:  28 6e 00 08          movea.l  $8(a6), a4
  00405c:  20 6c 00 02          movea.l  $2(a4), a0
  004060:  26 50                movea.l  (a0), a3
  004062:  2d 53 ff fc          move.l   (a3), -$4(a6)
  004066:  67 30                beq.b    $4098  ; -> L4098
  004068:  30 2b 00 0e          move.w   $e(a3), d0
  00406c:  48 c0                ext.l    d0
  00406e:  72 01                moveq    #$1, d1
  004070:  b2 80                cmp.l    d0, d1
  004072:  66 0e                bne.b    $4082  ; -> L4082
  004074:  59 8f                subq.l   #$4, a7
  004076:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  00407a:  4e ba 64 16          jsr      $a492(pc)  ; -> sub_a492
  00407e:  2d 5f ff fc          move.l   (a7)+, -$4(a6)
L4082:
  004082:  70 01                moveq    #$1, d0
  004084:  2f 00                move.l   d0, -(a7)
  004086:  2f 00                move.l   d0, -(a7)
  004088:  48 6e ff fc          pea.l    -$4(a6)
  00408c:  72 33                moveq    #$33, d1
  00408e:  2f 01                move.l   d1, -(a7)
  004090:  4e ba 21 92          jsr      $6224(pc)  ; -> EngineDispatch
  004094:  4f ef 00 10          lea.l    $10(a7), a7
L4098:
  004098:  2f 0c                move.l   a4, -(a7)
  00409a:  48 78 1a 74          pea.l    $1a74.w
  00409e:  4e ba 45 fc          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0040a2:  58 8f                addq.l   #$4, a7
  0040a4:  2f 00                move.l   d0, -(a7)
  0040a6:  70 04                moveq    #$4, d0
  0040a8:  20 5f                movea.l  (a7)+, a0
  0040aa:  4e 90                jsr      (a0)
  0040ac:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  0040b2:  4e 5e                unlk     a6
  0040b4:  4e 74 00 04          rtd      #$4
* GA_CloseCPort  -  System 7 $BC22 (same trap slot $1608, code r=0.76).
* S7: Patch #79 replaces _ClosePort ($A87D); no EngineDispatch command found
GA_CloseCPort:
  0040b8:  2f 0b                move.l   a3, -(a7)
  0040ba:  26 6f 00 08          movea.l  $8(a7), a3
  0040be:  2f 0b                move.l   a3, -(a7)
  0040c0:  48 78 0f f4          pea.l    $ff4.w
  0040c4:  4e ba 45 d6          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0040c8:  58 8f                addq.l   #$4, a7
  0040ca:  2f 00                move.l   d0, -(a7)
  0040cc:  20 5f                movea.l  (a7)+, a0
  0040ce:  4e 90                jsr      (a0)
  0040d0:  26 5f                movea.l  (a7)+, a3
  0040d2:  4e 74 00 04          rtd      #$4
* GA_CharExtra  -  System 7 $BC42 (same trap slot $168C, code r=0.87).
* S7: Patch #101 replaces _CharExtra ($AA23); card commands: $26
GA_CharExtra:
  0040d6:  48 e7 03 10          movem.l  d6-d7/a3, -(a7)
  0040da:  2e 2f 00 10          move.l   $10(a7), d7
  0040de:  70 00                moveq    #$0, d0
  0040e0:  2f 00                move.l   d0, -(a7)
  0040e2:  4e ba 47 3e          jsr      $8822(pc)  ; -> s7_sub_6f1c
  0040e6:  26 40                movea.l  d0, a3
  0040e8:  4e ba d1 46          jsr      $1230(pc)  ; -> GetA5
  0040ec:  20 40                movea.l  d0, a0
  0040ee:  20 50                movea.l  (a0), a0
  0040f0:  b7 d0                cmpa.l   (a0), a3
  0040f2:  58 8f                addq.l   #$4, a7
  0040f4:  66 42                bne.b    $4138  ; -> L4138
  0040f6:  30 2b 00 06          move.w   $6(a3), d0
  0040fa:  48 c0                ext.l    d0
  0040fc:  6c 3a                bge.b    $4138  ; -> L4138
  0040fe:  3c 2b 00 0c          move.w   $c(a3), d6
  004102:  2f 07                move.l   d7, -(a7)
  004104:  48 78 16 8c          pea.l    $168c.w
  004108:  4e ba 45 92          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00410c:  58 8f                addq.l   #$4, a7
  00410e:  2f 00                move.l   d0, -(a7)
  004110:  20 5f                movea.l  (a7)+, a0
  004112:  4e 90                jsr      (a0)
  004114:  48 c6                ext.l    d6
  004116:  30 2b 00 0c          move.w   $c(a3), d0
  00411a:  48 c0                ext.l    d0
  00411c:  b0 86                cmp.l    d6, d0
  00411e:  67 2a                beq.b    $414a  ; -> L414a
  004120:  70 01                moveq    #$1, d0
  004122:  2f 00                move.l   d0, -(a7)
  004124:  72 00                moveq    #$0, d1
  004126:  2f 01                move.l   d1, -(a7)
  004128:  2f 01                move.l   d1, -(a7)
  00412a:  70 26                moveq    #$26, d0
  00412c:  2f 00                move.l   d0, -(a7)
  00412e:  4e ba 20 f4          jsr      $6224(pc)  ; -> EngineDispatch
  004132:  4f ef 00 10          lea.l    $10(a7), a7
  004136:  60 12                bra.b    $414a  ; -> L414a
L4138:
  004138:  2f 07                move.l   d7, -(a7)
  00413a:  48 78 16 8c          pea.l    $168c.w
  00413e:  4e ba 45 5c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  004142:  58 8f                addq.l   #$4, a7
  004144:  2f 00                move.l   d0, -(a7)
  004146:  20 5f                movea.l  (a7)+, a0
  004148:  4e 90                jsr      (a0)
L414a:
  00414a:  4c df 08 c0          movem.l  (a7)+, d6-d7/a3
  00414e:  4e 74 00 04          rtd      #$4
* s7_sub_bcc8  -  System 7 $BCC8 (similar code, r=0.77).
s7_sub_bcc8:
  004152:  4e 56 ff f8          link.w   a6, #$fff8
  004156:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  00415a:  28 6e 00 08          movea.l  $8(a6), a4
  00415e:  70 00                moveq    #$0, d0
  004160:  2f 00                move.l   d0, -(a7)
  004162:  4e ba 46 be          jsr      $8822(pc)  ; -> s7_sub_6f1c
  004166:  26 40                movea.l  d0, a3
  004168:  7e 00                moveq    #$0, d7
  00416a:  20 0b                move.l   a3, d0
  00416c:  58 8f                addq.l   #$4, a7
  00416e:  67 24                beq.b    $4194  ; -> L4194
  004170:  30 2b 00 06          move.w   $6(a3), d0
  004174:  48 c0                ext.l    d0
  004176:  6c 1c                bge.b    $4194  ; -> L4194
  004178:  b9 eb 00 3a          cmpa.l   $3a(a3), a4
  00417c:  66 04                bne.b    $4182  ; -> L4182
  00417e:  7e 01                moveq    #$1, d7
  004180:  60 12                bra.b    $4194  ; -> L4194
L4182:
  004182:  b9 eb 00 20          cmpa.l   $20(a3), a4
  004186:  66 04                bne.b    $418c  ; -> L418c
  004188:  7e 02                moveq    #$2, d7
  00418a:  60 08                bra.b    $4194  ; -> L4194
L418c:
  00418c:  b9 eb 00 3e          cmpa.l   $3e(a3), a4
  004190:  66 02                bne.b    $4194  ; -> L4194
  004192:  7e 03                moveq    #$3, d7
L4194:
  004194:  20 54                movea.l  (a4), a0
  004196:  31 7c ff ff 00 0e    move.w   #$ffff, $e(a0)
  00419c:  4a 87                tst.l    d7
  00419e:  67 22                beq.b    $41c2  ; -> L41c2
  0041a0:  70 00                moveq    #$0, d0
  0041a2:  2d 40 ff f8          move.l   d0, -$8(a6)
  0041a6:  2d 47 ff fc          move.l   d7, -$4(a6)
  0041aa:  72 01                moveq    #$1, d1
  0041ac:  2f 01                move.l   d1, -(a7)
  0041ae:  70 02                moveq    #$2, d0
  0041b0:  2f 00                move.l   d0, -(a7)
  0041b2:  48 6e ff f8          pea.l    -$8(a6)
  0041b6:  70 2a                moveq    #$2a, d0
  0041b8:  2f 00                move.l   d0, -(a7)
  0041ba:  4e ba 20 68          jsr      $6224(pc)  ; -> EngineDispatch
  0041be:  4f ef 00 10          lea.l    $10(a7), a7
L41c2:
  0041c2:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  0041c8:  4e 5e                unlk     a6
  0041ca:  4e 74 00 04          rtd      #$4
L41ce:
  0041ce:  2f 0b                move.l   a3, -(a7)
  0041d0:  26 6f 00 08          movea.l  $8(a7), a3
  0041d4:  70 00                moveq    #$0, d0
  0041d6:  2f 00                move.l   d0, -(a7)
  0041d8:  4e ba 46 48          jsr      $8822(pc)  ; -> s7_sub_6f1c
  0041dc:  b0 8b                cmp.l    a3, d0
  0041de:  58 8f                addq.l   #$4, a7
  0041e0:  66 16                bne.b    $41f8  ; -> L41f8
  0041e2:  70 01                moveq    #$1, d0
  0041e4:  2f 00                move.l   d0, -(a7)
  0041e6:  72 00                moveq    #$0, d1
  0041e8:  2f 01                move.l   d1, -(a7)
  0041ea:  2f 01                move.l   d1, -(a7)
  0041ec:  70 26                moveq    #$26, d0
  0041ee:  2f 00                move.l   d0, -(a7)
  0041f0:  4e ba 20 32          jsr      $6224(pc)  ; -> EngineDispatch
  0041f4:  4f ef 00 10          lea.l    $10(a7), a7
L41f8:
  0041f8:  26 5f                movea.l  (a7)+, a3
  0041fa:  4e 74 00 04          rtd      #$4
* s7_Lbd76  -  System 7 $BD76 (identical code).
s7_Lbd76:
  0041fe:  4e 56 00 00          link.w   a6, #$0
  004202:  70 01                moveq    #$1, d0
  004204:  2f 00                move.l   d0, -(a7)
  004206:  2f 00                move.l   d0, -(a7)
  004208:  48 6e 00 08          pea.l    $8(a6)
  00420c:  72 29                moveq    #$29, d1
  00420e:  2f 01                move.l   d1, -(a7)
  004210:  4e ba 20 12          jsr      $6224(pc)  ; -> EngineDispatch
  004214:  4e 5e                unlk     a6
  004216:  4e 74 00 04          rtd      #$4
* s7_sub_bd94  -  System 7 $BD94 (similar code, r=0.85).
s7_sub_bd94:
  00421a:  4e 56 ff f8          link.w   a6, #$fff8
  00421e:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  004222:  28 6e 00 08          movea.l  $8(a6), a4
  004226:  59 8f                subq.l   #$4, a7
  004228:  2f 0c                move.l   a4, -(a7)
  00422a:  48 78 1a 74          pea.l    $1a74.w
  00422e:  4e ba 44 6c          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  004232:  58 8f                addq.l   #$4, a7
  004234:  2f 00                move.l   d0, -(a7)
  004236:  70 0f                moveq    #$f, d0
  004238:  20 5f                movea.l  (a7)+, a0
  00423a:  4e 90                jsr      (a0)
  00423c:  26 5f                movea.l  (a7)+, a3
  00423e:  20 0b                move.l   a3, d0
  004240:  66 18                bne.b    $425a  ; -> L425a
  004242:  70 01                moveq    #$1, d0
  004244:  2f 00                move.l   d0, -(a7)
  004246:  2f 00                move.l   d0, -(a7)
  004248:  20 54                movea.l  (a4), a0
  00424a:  2f 08                move.l   a0, -(a7)
  00424c:  72 33                moveq    #$33, d1
  00424e:  2f 01                move.l   d1, -(a7)
  004250:  4e ba 1f d2          jsr      $6224(pc)  ; -> EngineDispatch
  004254:  4f ef 00 10          lea.l    $10(a7), a7
  004258:  60 5e                bra.b    $42b8  ; -> L42b8
L425a:
  00425a:  20 54                movea.l  (a4), a0
  00425c:  30 28 00 0e          move.w   $e(a0), d0
  004260:  48 c0                ext.l    d0
  004262:  2e 00                move.l   d0, d7
  004264:  70 01                moveq    #$1, d0
  004266:  b0 87                cmp.l    d7, d0
  004268:  67 06                beq.b    $4270  ; -> L4270
  00426a:  70 02                moveq    #$2, d0
  00426c:  b0 87                cmp.l    d7, d0
  00426e:  66 48                bne.b    $42b8  ; -> L42b8
L4270:
  004270:  59 8f                subq.l   #$4, a7
  004272:  2f 0b                move.l   a3, -(a7)
  004274:  4e ba 62 1c          jsr      $a492(pc)  ; -> sub_a492
  004278:  28 5f                movea.l  (a7)+, a4
  00427a:  2d 4c ff f8          move.l   a4, -$8(a6)
  00427e:  4a 2e 00 0f          tst.b    $f(a6)
  004282:  67 0e                beq.b    $4292  ; -> L4292
  004284:  55 8f                subq.l   #$2, a7
  004286:  2f 0c                move.l   a4, -(a7)
  004288:  4e ba 62 8a          jsr      $a514(pc)  ; -> sub_a514
  00428c:  10 1f                move.b   (a7)+, d0
  00428e:  49 c0                extb.l   d0
  004290:  60 02                bra.b    $4294  ; -> L4294
L4292:
  004292:  70 00                moveq    #$0, d0
L4294:
  004294:  2d 40 ff fc          move.l   d0, -$4(a6)
  004298:  70 01                moveq    #$1, d0
  00429a:  2f 00                move.l   d0, -(a7)
  00429c:  72 02                moveq    #$2, d1
  00429e:  2f 01                move.l   d1, -(a7)
  0042a0:  48 6e ff f8          pea.l    -$8(a6)
  0042a4:  70 0d                moveq    #$d, d0
  0042a6:  2f 00                move.l   d0, -(a7)
  0042a8:  4e ba 1f 7a          jsr      $6224(pc)  ; -> EngineDispatch
  0042ac:  28 40                movea.l  d0, a4
  0042ae:  20 0c                move.l   a4, d0
  0042b0:  4f ef 00 10          lea.l    $10(a7), a7
  0042b4:  67 02                beq.b    $42b8  ; -> L42b8
  0042b6:  26 4c                movea.l  a4, a3
L42b8:
  0042b8:  4e ba 44 56          jsr      $8710(pc)  ; -> s7_sub_6e14
  0042bc:  72 00                moveq    #$0, d1
  0042be:  12 00                move.b   d0, d1
  0042c0:  67 f6                beq.b    $42b8  ; -> L42b8
  0042c2:  20 0b                move.l   a3, d0
  0042c4:  4c ee 18 80 ff ec    movem.l  -$14(a6), d7/a3-a4
  0042ca:  4e 5e                unlk     a6
  0042cc:  4e 75                rts
* s7_Lbe74  -  System 7 $BE74 (similar code, r=0.80).
s7_Lbe74:
  0042ce:  4e 56 00 00          link.w   a6, #$0
  0042d2:  2f 0b                move.l   a3, -(a7)
  0042d4:  26 6e 00 08          movea.l  $8(a6), a3
  0042d8:  70 01                moveq    #$1, d0
  0042da:  2f 00                move.l   d0, -(a7)
  0042dc:  2f 0b                move.l   a3, -(a7)
  0042de:  4e ba ff 3a          jsr      $421a(pc)  ; -> s7_sub_bd94
  0042e2:  2d 40 00 0c          move.l   d0, $c(a6)
  0042e6:  26 6e ff fc          movea.l  -$4(a6), a3
  0042ea:  4e 5e                unlk     a6
  0042ec:  4e 74 00 04          rtd      #$4
L42f0:
  0042f0:  2f 0b                move.l   a3, -(a7)
  0042f2:  26 6f 00 08          movea.l  $8(a7), a3
  0042f6:  2f 0b                move.l   a3, -(a7)
  0042f8:  48 78 1a 74          pea.l    $1a74.w
  0042fc:  4e ba 43 9e          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  004300:  58 8f                addq.l   #$4, a7
  004302:  2f 00                move.l   d0, -(a7)
  004304:  70 02                moveq    #$2, d0
  004306:  20 5f                movea.l  (a7)+, a0
  004308:  4e 90                jsr      (a0)
  00430a:  70 01                moveq    #$1, d0
  00430c:  2f 00                move.l   d0, -(a7)
  00430e:  2f 00                move.l   d0, -(a7)
  004310:  20 53                movea.l  (a3), a0
  004312:  2f 08                move.l   a0, -(a7)
  004314:  72 33                moveq    #$33, d1
  004316:  2f 01                move.l   d1, -(a7)
  004318:  4e ba 1f 0a          jsr      $6224(pc)  ; -> EngineDispatch
  00431c:  2f 0b                move.l   a3, -(a7)
  00431e:  48 78 1a 74          pea.l    $1a74.w
  004322:  4e ba 43 78          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  004326:  58 8f                addq.l   #$4, a7
  004328:  2f 00                move.l   d0, -(a7)
  00432a:  70 11                moveq    #$11, d0
  00432c:  20 5f                movea.l  (a7)+, a0
  00432e:  4e 90                jsr      (a0)
  004330:  4f ef 00 10          lea.l    $10(a7), a7
  004334:  26 5f                movea.l  (a7)+, a3
  004336:  4e 74 00 04          rtd      #$4
* s7_Lbecc  -  System 7 $BECC (similar code, r=0.95).
s7_Lbecc:
  00433a:  4e 56 00 00          link.w   a6, #$0
  00433e:  48 e7 00 18          movem.l  a3-a4, -(a7)
  004342:  26 6e 00 08          movea.l  $8(a6), a3
  004346:  70 00                moveq    #$0, d0
  004348:  2f 00                move.l   d0, -(a7)
  00434a:  4e ba 44 d6          jsr      $8822(pc)  ; -> s7_sub_6f1c
  00434e:  28 40                movea.l  d0, a4
  004350:  b9 cb                cmpa.l   a3, a4
  004352:  58 8f                addq.l   #$4, a7
  004354:  67 04                beq.b    $435a  ; -> L435a
  004356:  20 0b                move.l   a3, d0
  004358:  66 0a                bne.b    $4364  ; -> L4364
L435a:
  00435a:  4e ba 43 b4          jsr      $8710(pc)  ; -> s7_sub_6e14
  00435e:  1d 40 00 0c          move.b   d0, $c(a6)
  004362:  60 06                bra.b    $436a  ; -> L436a
L4364:
  004364:  1d 7c 00 01 00 0c    move.b   #$1, $c(a6)
L436a:
  00436a:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  004370:  4e 5e                unlk     a6
  004372:  4e 74 00 04          rtd      #$4
* s7_sub_81bc  -  System 7 $81BC (similar code, r=0.77).
s7_sub_81bc:
  004376:  2f 0b                move.l   a3, -(a7)
  004378:  26 6f 00 08          movea.l  $8(a7), a3
  00437c:  26 b8 08 24          move.l   $824.w, (a3)
  004380:  26 5f                movea.l  (a7)+, a3
  004382:  4e 75                rts
* s7_sub_8262  -  System 7 $8262 (similar code, r=0.85).
s7_sub_8262:
  004384:  4e 56 ff e4          link.w   a6, #$ffe4
  004388:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  00438c:  2a 2e 00 24          move.l   $24(a6), d5
  004390:  28 6e 00 14          movea.l  $14(a6), a4
  004394:  26 6e 00 08          movea.l  $8(a6), a3
  004398:  3c 2c 00 04          move.w   $4(a4), d6
  00439c:  48 c6                ext.l    d6
  00439e:  4a 86                tst.l    d6
  0043a0:  5d c0                slt.b    d0
  0043a2:  44 00                neg.b    d0
  0043a4:  49 c0                extb.l   d0
  0043a6:  2d 40 ff e4          move.l   d0, -$1c(a6)
  0043aa:  67 70                beq.b    $441c  ; -> L441c
  0043ac:  48 c6                ext.l    d6
  0043ae:  20 3c 00 00 40 00    move.l   #$4000, d0
  0043b4:  c0 86                and.l    d6, d0
  0043b6:  67 04                beq.b    $43bc  ; -> L43bc
  0043b8:  20 54                movea.l  (a4), a0
  0043ba:  28 50                movea.l  (a0), a4
L43bc:
  0043bc:  20 4b                movea.l  a3, a0
  0043be:  54 88                addq.l   #$2, a0
  0043c0:  22 4c                movea.l  a4, a1
  0043c2:  70 0b                moveq    #$b, d0
L43c4:
  0043c4:  20 d9                move.l   (a1)+, (a0)+
  0043c6:  51 c8 ff fc          dbra     d0, $43c4  ; -> L43c4
  0043ca:  30 d9                move.w   (a1)+, (a0)+
  0043cc:  3e 2c 00 0e          move.w   $e(a4), d7
  0043d0:  48 c7                ext.l    d7
  0043d2:  70 01                moveq    #$1, d0
  0043d4:  b0 87                cmp.l    d7, d0
  0043d6:  67 08                beq.b    $43e0  ; -> L43e0
  0043d8:  48 c7                ext.l    d7
  0043da:  70 02                moveq    #$2, d0
  0043dc:  b0 87                cmp.l    d7, d0
  0043de:  66 4a                bne.b    $442a  ; -> L442a
L43e0:
  0043e0:  48 c7                ext.l    d7
  0043e2:  70 02                moveq    #$2, d0
  0043e4:  b0 87                cmp.l    d7, d0
  0043e6:  66 06                bne.b    $43ee  ; -> L43ee
  0043e8:  20 54                movea.l  (a4), a0
  0043ea:  27 50 00 02          move.l   (a0), $2(a3)
L43ee:
  0043ee:  20 2c 00 2e          move.l   $2e(a4), d0
  0043f2:  08 00 00 00          btst.b   #$0, d0
  0043f6:  67 08                beq.b    $4400  ; -> L4400
  0043f8:  70 00                moveq    #$0, d0
  0043fa:  27 40 00 9c          move.l   d0, $9c(a3)
  0043fe:  60 2a                bra.b    $442a  ; -> L442a
L4400:
  004400:  48 c7                ext.l    d7
  004402:  70 02                moveq    #$2, d0
  004404:  b0 87                cmp.l    d7, d0
  004406:  66 04                bne.b    $440c  ; -> L440c
  004408:  20 14                move.l   (a4), d0
  00440a:  60 0a                bra.b    $4416  ; -> L4416
L440c:
  00440c:  59 8f                subq.l   #$4, a7
  00440e:  2f 14                move.l   (a4), -(a7)
  004410:  4e ba 60 80          jsr      $a492(pc)  ; -> sub_a492
  004414:  20 1f                move.l   (a7)+, d0
L4416:
  004416:  27 40 00 9c          move.l   d0, $9c(a3)
  00441a:  60 0e                bra.b    $442a  ; -> L442a
L441c:
  00441c:  20 4b                movea.l  a3, a0
  00441e:  54 88                addq.l   #$2, a0
  004420:  22 4c                movea.l  a4, a1
  004422:  20 d9                move.l   (a1)+, (a0)+
  004424:  20 d9                move.l   (a1)+, (a0)+
  004426:  20 d9                move.l   (a1)+, (a0)+
  004428:  30 d9                move.w   (a1)+, (a0)+
L442a:
  00442a:  20 6e 00 20          movea.l  $20(a6), a0
  00442e:  43 eb 00 a8          lea.l    $a8(a3), a1
  004432:  22 d8                move.l   (a0)+, (a1)+
  004434:  22 d8                move.l   (a0)+, (a1)+
  004436:  2d 78 08 24 ff f6    move.l   $824.w, -$a(a6)
  00443c:  4a ae 00 10          tst.l    $10(a6)
  004440:  67 00 00 bc          beq.w    $44fe  ; -> L44fe
  004444:  20 6e 00 10          movea.l  $10(a6), a0
  004448:  3c 28 00 04          move.w   $4(a0), d6
  00444c:  48 c6                ext.l    d6
  00444e:  4a 86                tst.l    d6
  004450:  6c 00 00 8e          bge.w    $44e0  ; -> L44e0
  004454:  48 c6                ext.l    d6
  004456:  20 3c 00 00 40 00    move.l   #$4000, d0
  00445c:  c0 86                and.l    d6, d0
  00445e:  67 0a                beq.b    $446a  ; -> L446a
  004460:  20 6e 00 10          movea.l  $10(a6), a0
  004464:  20 50                movea.l  (a0), a0
  004466:  2d 50 00 10          move.l   (a0), $10(a6)
L446a:
  00446a:  20 6e 00 10          movea.l  $10(a6), a0
  00446e:  43 eb 00 6a          lea.l    $6a(a3), a1
  004472:  70 0b                moveq    #$b, d0
L4474:
  004474:  22 d8                move.l   (a0)+, (a1)+
  004476:  51 c8 ff fc          dbra     d0, $4474  ; -> L4474
  00447a:  32 d8                move.w   (a0)+, (a1)+
  00447c:  20 6e 00 10          movea.l  $10(a6), a0
  004480:  3e 28 00 0e          move.w   $e(a0), d7
  004484:  48 c7                ext.l    d7
  004486:  70 01                moveq    #$1, d0
  004488:  b0 87                cmp.l    d7, d0
  00448a:  67 08                beq.b    $4494  ; -> L4494
  00448c:  48 c7                ext.l    d7
  00448e:  70 02                moveq    #$2, d0
  004490:  b0 87                cmp.l    d7, d0
  004492:  66 5c                bne.b    $44f0  ; -> L44f0
L4494:
  004494:  48 c7                ext.l    d7
  004496:  70 02                moveq    #$2, d0
  004498:  b0 87                cmp.l    d7, d0
  00449a:  66 0a                bne.b    $44a6  ; -> L44a6
  00449c:  20 6e 00 10          movea.l  $10(a6), a0
  0044a0:  20 50                movea.l  (a0), a0
  0044a2:  27 50 00 6a          move.l   (a0), $6a(a3)
L44a6:
  0044a6:  20 6e 00 10          movea.l  $10(a6), a0
  0044aa:  20 28 00 2e          move.l   $2e(a0), d0
  0044ae:  08 00 00 00          btst.b   #$0, d0
  0044b2:  67 08                beq.b    $44bc  ; -> L44bc
  0044b4:  70 00                moveq    #$0, d0
  0044b6:  27 40 00 a4          move.l   d0, $a4(a3)
  0044ba:  60 34                bra.b    $44f0  ; -> L44f0
L44bc:
  0044bc:  48 c7                ext.l    d7
  0044be:  70 02                moveq    #$2, d0
  0044c0:  b0 87                cmp.l    d7, d0
  0044c2:  66 08                bne.b    $44cc  ; -> L44cc
  0044c4:  20 6e 00 10          movea.l  $10(a6), a0
  0044c8:  20 50                movea.l  (a0), a0
  0044ca:  60 0e                bra.b    $44da  ; -> L44da
L44cc:
  0044cc:  59 8f                subq.l   #$4, a7
  0044ce:  20 6e 00 10          movea.l  $10(a6), a0
  0044d2:  2f 10                move.l   (a0), -(a7)
  0044d4:  4e ba 5f bc          jsr      $a492(pc)  ; -> sub_a492
  0044d8:  20 5f                movea.l  (a7)+, a0
L44da:
  0044da:  27 48 00 a4          move.l   a0, $a4(a3)
  0044de:  60 10                bra.b    $44f0  ; -> L44f0
L44e0:
  0044e0:  20 6e 00 10          movea.l  $10(a6), a0
  0044e4:  43 eb 00 6a          lea.l    $6a(a3), a1
  0044e8:  22 d8                move.l   (a0)+, (a1)+
  0044ea:  22 d8                move.l   (a0)+, (a1)+
  0044ec:  22 d8                move.l   (a0)+, (a1)+
  0044ee:  32 d8                move.w   (a0)+, (a1)+
L44f0:
  0044f0:  20 6e 00 1c          movea.l  $1c(a6), a0
  0044f4:  43 eb 00 b8          lea.l    $b8(a3), a1
  0044f8:  22 d8                move.l   (a0)+, (a1)+
  0044fa:  22 d8                move.l   (a0)+, (a1)+
  0044fc:  60 06                bra.b    $4504  ; -> L4504
L44fe:
  0044fe:  70 00                moveq    #$0, d0
  004500:  27 40 00 6a          move.l   d0, $6a(a3)
L4504:
  004504:  2d 78 0c c8 ff f2    move.l   $cc8.w, -$e(a6)
  00450a:  27 78 0c c8 00 d0    move.l   $cc8.w, $d0(a3)
  004510:  4e ba cd 1e          jsr      $1230(pc)  ; -> GetA5
  004514:  20 40                movea.l  d0, a0
  004516:  20 50                movea.l  (a0), a0
  004518:  2d 50 ff e8          move.l   (a0), -$18(a6)
  00451c:  20 6e ff e8          movea.l  -$18(a6), a0
  004520:  30 28 00 06          move.w   $6(a0), d0
  004524:  48 c0                ext.l    d0
  004526:  5d c0                slt.b    d0
  004528:  02 40 00 01          andi.w   #$1, d0
  00452c:  3d 40 ff ec          move.w   d0, -$14(a6)
  004530:  37 40 00 f4          move.w   d0, $f4(a3)
  004534:  20 6e ff e8          movea.l  -$18(a6), a0
  004538:  27 68 00 50 00 e0    move.l   $50(a0), $e0(a3)
  00453e:  20 6e ff e8          movea.l  -$18(a6), a0
  004542:  27 68 00 54 00 e4    move.l   $54(a0), $e4(a3)
  004548:  4a 6e ff ec          tst.w    -$14(a6)
  00454c:  67 66                beq.b    $45b4  ; -> L45b4
  00454e:  20 6e ff e8          movea.l  -$18(a6), a0
  004552:  43 eb 00 e8          lea.l    $e8(a3), a1
  004556:  41 e8 00 24          lea.l    $24(a0), a0
  00455a:  22 d8                move.l   (a0)+, (a1)+
  00455c:  32 d8                move.w   (a0)+, (a1)+
  00455e:  20 6e ff e8          movea.l  -$18(a6), a0
  004562:  43 eb 00 ee          lea.l    $ee(a3), a1
  004566:  41 e8 00 2a          lea.l    $2a(a0), a0
  00456a:  22 d8                move.l   (a0)+, (a1)+
  00456c:  32 d8                move.w   (a0)+, (a1)+
  00456e:  20 6e ff f2          movea.l  -$e(a6), a0
  004572:  20 50                movea.l  (a0), a0
  004574:  4a a8 00 0c          tst.l    $c(a0)
  004578:  67 72                beq.b    $45ec  ; -> L45ec
  00457a:  20 6e ff e8          movea.l  -$18(a6), a0
  00457e:  43 ee ff fa          lea.l    -$6(a6), a1
  004582:  41 e8 00 24          lea.l    $24(a0), a0
  004586:  22 d8                move.l   (a0)+, (a1)+
  004588:  32 d8                move.w   (a0)+, (a1)+
  00458a:  59 8f                subq.l   #$4, a7
  00458c:  48 6e ff fa          pea.l    -$6(a6)
  004590:  aa 33                dc.w     $aa33
  004592:  27 5f 00 e0          move.l   (a7)+, $e0(a3)
  004596:  20 6e ff e8          movea.l  -$18(a6), a0
  00459a:  43 ee ff fa          lea.l    -$6(a6), a1
  00459e:  41 e8 00 2a          lea.l    $2a(a0), a0
  0045a2:  22 d8                move.l   (a0)+, (a1)+
  0045a4:  32 d8                move.w   (a0)+, (a1)+
  0045a6:  59 8f                subq.l   #$4, a7
  0045a8:  48 6e ff fa          pea.l    -$6(a6)
  0045ac:  aa 33                dc.w     $aa33
  0045ae:  27 5f 00 e4          move.l   (a7)+, $e4(a3)
  0045b2:  60 38                bra.b    $45ec  ; -> L45ec
L45b4:
  0045b4:  20 6e ff e8          movea.l  -$18(a6), a0
  0045b8:  2f 28 00 50          move.l   $50(a0), -(a7)
  0045bc:  4e ba d2 24          jsr      $17e2(pc)  ; -> s7_sub_917e
  0045c0:  20 40                movea.l  d0, a0
  0045c2:  43 eb 00 e8          lea.l    $e8(a3), a1
  0045c6:  22 d8                move.l   (a0)+, (a1)+
  0045c8:  32 d8                move.w   (a0)+, (a1)+
  0045ca:  20 6e ff e8          movea.l  -$18(a6), a0
  0045ce:  2f 28 00 54          move.l   $54(a0), -(a7)
  0045d2:  4e ba d2 0e          jsr      $17e2(pc)  ; -> s7_sub_917e
  0045d6:  20 40                movea.l  d0, a0
  0045d8:  43 eb 00 ee          lea.l    $ee(a3), a1
  0045dc:  22 d8                move.l   (a0)+, (a1)+
  0045de:  32 d8                move.w   (a0)+, (a1)+
  0045e0:  20 6e ff e8          movea.l  -$18(a6), a0
  0045e4:  37 68 00 58 00 f6    move.w   $58(a0), $f6(a3)
  0045ea:  50 8f                addq.l   #$8, a7
L45ec:
  0045ec:  20 6e 00 0c          movea.l  $c(a6), a0
  0045f0:  3c 28 00 04          move.w   $4(a0), d6
  0045f4:  48 c6                ext.l    d6
  0045f6:  4a 86                tst.l    d6
  0045f8:  6c 00 00 8e          bge.w    $4688  ; -> L4688
  0045fc:  48 c6                ext.l    d6
  0045fe:  20 3c 00 00 40 00    move.l   #$4000, d0
  004604:  c0 86                and.l    d6, d0
  004606:  67 0a                beq.b    $4612  ; -> L4612
  004608:  20 6e 00 0c          movea.l  $c(a6), a0
  00460c:  20 50                movea.l  (a0), a0
  00460e:  2d 50 00 0c          move.l   (a0), $c(a6)
L4612:
  004612:  20 6e 00 0c          movea.l  $c(a6), a0
  004616:  43 eb 00 36          lea.l    $36(a3), a1
  00461a:  70 0b                moveq    #$b, d0
L461c:
  00461c:  22 d8                move.l   (a0)+, (a1)+
  00461e:  51 c8 ff fc          dbra     d0, $461c  ; -> L461c
  004622:  32 d8                move.w   (a0)+, (a1)+
  004624:  20 6e 00 0c          movea.l  $c(a6), a0
  004628:  3e 28 00 0e          move.w   $e(a0), d7
  00462c:  48 c7                ext.l    d7
  00462e:  70 01                moveq    #$1, d0
  004630:  b0 87                cmp.l    d7, d0
  004632:  67 08                beq.b    $463c  ; -> L463c
  004634:  48 c7                ext.l    d7
  004636:  70 02                moveq    #$2, d0
  004638:  b0 87                cmp.l    d7, d0
  00463a:  66 5c                bne.b    $4698  ; -> L4698
L463c:
  00463c:  48 c7                ext.l    d7
  00463e:  70 02                moveq    #$2, d0
  004640:  b0 87                cmp.l    d7, d0
  004642:  66 0a                bne.b    $464e  ; -> L464e
  004644:  20 6e 00 0c          movea.l  $c(a6), a0
  004648:  20 50                movea.l  (a0), a0
  00464a:  27 50 00 36          move.l   (a0), $36(a3)
L464e:
  00464e:  20 6e 00 0c          movea.l  $c(a6), a0
  004652:  20 28 00 2e          move.l   $2e(a0), d0
  004656:  08 00 00 00          btst.b   #$0, d0
  00465a:  67 08                beq.b    $4664  ; -> L4664
  00465c:  70 00                moveq    #$0, d0
  00465e:  27 40 00 a0          move.l   d0, $a0(a3)
  004662:  60 34                bra.b    $4698  ; -> L4698
L4664:
  004664:  48 c7                ext.l    d7
  004666:  70 02                moveq    #$2, d0
  004668:  b0 87                cmp.l    d7, d0
  00466a:  66 08                bne.b    $4674  ; -> L4674
  00466c:  20 6e 00 0c          movea.l  $c(a6), a0
  004670:  20 50                movea.l  (a0), a0
  004672:  60 0e                bra.b    $4682  ; -> L4682
L4674:
  004674:  59 8f                subq.l   #$4, a7
  004676:  20 6e 00 0c          movea.l  $c(a6), a0
  00467a:  2f 10                move.l   (a0), -(a7)
  00467c:  4e ba 5e 14          jsr      $a492(pc)  ; -> sub_a492
  004680:  20 5f                movea.l  (a7)+, a0
L4682:
  004682:  27 48 00 a0          move.l   a0, $a0(a3)
  004686:  60 10                bra.b    $4698  ; -> L4698
L4688:
  004688:  20 6e 00 0c          movea.l  $c(a6), a0
  00468c:  43 eb 00 36          lea.l    $36(a3), a1
  004690:  22 d8                move.l   (a0)+, (a1)+
  004692:  22 d8                move.l   (a0)+, (a1)+
  004694:  22 d8                move.l   (a0)+, (a1)+
  004696:  32 d8                move.w   (a0)+, (a1)+
L4698:
  004698:  20 6e 00 18          movea.l  $18(a6), a0
  00469c:  43 eb 00 b0          lea.l    $b0(a3), a1
  0046a0:  22 d8                move.l   (a0)+, (a1)+
  0046a2:  22 d8                move.l   (a0)+, (a1)+
  0046a4:  70 02                moveq    #$2, d0
  0046a6:  b0 85                cmp.l    d5, d0
  0046a8:  66 0a                bne.b    $46b4  ; -> L46b4
  0046aa:  10 38 09 38          move.b   $938.w, d0
  0046ae:  49 c0                extb.l   d0
  0046b0:  6d 02                blt.b    $46b4  ; -> L46b4
  0046b2:  7a 32                moveq    #$32, d5
L46b4:
  0046b4:  27 78 08 a0 00 d4    move.l   $8a0.w, $d4(a3)
  0046ba:  20 14                move.l   (a4), d0
  0046bc:  b0 ae ff f6          cmp.l    -$a(a6), d0
  0046c0:  66 16                bne.b    $46d8  ; -> L46d8
  0046c2:  20 6e ff f2          movea.l  -$e(a6), a0
  0046c6:  20 50                movea.l  (a0), a0
  0046c8:  20 68 00 16          movea.l  $16(a0), a0
  0046cc:  20 50                movea.l  (a0), a0
  0046ce:  30 28 00 20          move.w   $20(a0), d0
  0046d2:  48 c0                ext.l    d0
  0046d4:  28 00                move.l   d0, d4
  0046d6:  60 12                bra.b    $46ea  ; -> L46ea
L46d8:
  0046d8:  4a ae ff e4          tst.l    -$1c(a6)
  0046dc:  67 0a                beq.b    $46e8  ; -> L46e8
  0046de:  30 2c 00 20          move.w   $20(a4), d0
  0046e2:  48 c0                ext.l    d0
  0046e4:  28 00                move.l   d0, d4
  0046e6:  60 02                bra.b    $46ea  ; -> L46ea
L46e8:
  0046e8:  78 01                moveq    #$1, d4
L46ea:
  0046ea:  70 20                moveq    #$20, d0
  0046ec:  c0 85                and.l    d5, d0
  0046ee:  67 40                beq.b    $4730  ; -> L4730
  0046f0:  70 01                moveq    #$1, d0
  0046f2:  b0 84                cmp.l    d4, d0
  0046f4:  6c 3a                bge.b    $4730  ; -> L4730
  0046f6:  4a 6e ff ec          tst.w    -$14(a6)
  0046fa:  67 28                beq.b    $4724  ; -> L4724
  0046fc:  20 6e ff e8          movea.l  -$18(a6), a0
  004700:  20 68 00 08          movea.l  $8(a0), a0
  004704:  2d 50 ff ee          move.l   (a0), -$12(a6)
  004708:  20 6e ff ee          movea.l  -$12(a6), a0
  00470c:  43 eb 00 f8          lea.l    $f8(a3), a1
  004710:  22 d8                move.l   (a0)+, (a1)+
  004712:  32 d8                move.w   (a0)+, (a1)+
  004714:  20 6e ff ee          movea.l  -$12(a6), a0
  004718:  43 eb 00 fe          lea.l    $fe(a3), a1
  00471c:  5c 88                addq.l   #$6, a0
  00471e:  22 d8                move.l   (a0)+, (a1)+
  004720:  32 d8                move.w   (a0)+, (a1)+
  004722:  60 0c                bra.b    $4730  ; -> L4730
L4724:
  004724:  41 eb 00 fe          lea.l    $fe(a3), a0
  004728:  43 f8 0d a0          lea.l    $da0.w, a1
  00472c:  20 d9                move.l   (a1)+, (a0)+
  00472e:  30 d9                move.w   (a1)+, (a0)+
L4730:
  004730:  36 85                move.w   d5, (a3)
  004732:  4a ae 00 34          tst.l    $34(a6)
  004736:  56 c0                sne.b    d0
  004738:  44 00                neg.b    d0
  00473a:  49 c0                extb.l   d0
  00473c:  27 40 00 cc          move.l   d0, $cc(a3)
  004740:  20 6e 00 28          movea.l  $28(a6), a0
  004744:  28 50                movea.l  (a0), a4
  004746:  27 4c 00 c0          move.l   a4, $c0(a3)
  00474a:  37 54 01 04          move.w   (a4), $104(a3)
  00474e:  20 6e 00 2c          movea.l  $2c(a6), a0
  004752:  28 50                movea.l  (a0), a4
  004754:  27 4c 00 c4          move.l   a4, $c4(a3)
  004758:  37 54 01 06          move.w   (a4), $106(a3)
  00475c:  20 6e 00 30          movea.l  $30(a6), a0
  004760:  28 50                movea.l  (a0), a4
  004762:  27 4c 00 c8          move.l   a4, $c8(a3)
  004766:  37 54 01 08          move.w   (a4), $108(a3)
  00476a:  4c ee 18 f0 ff cc    movem.l  -$34(a6), d4-d7/a3-a4
  004770:  4e 5e                unlk     a6
  004772:  4e 75                rts
* s7_sub_860e  -  System 7 $860E (similar code, r=0.80).
s7_sub_860e:
  004774:  4e 56 ff fc          link.w   a6, #$fffc
  004778:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  00477c:  28 6e 00 08          movea.l  $8(a6), a4
  004780:  4e ba ca ae          jsr      $1230(pc)  ; -> GetA5
  004784:  20 40                movea.l  d0, a0
  004786:  20 50                movea.l  (a0), a0
  004788:  2d 50 ff fc          move.l   (a0), -$4(a6)
  00478c:  28 ae ff fc          move.l   -$4(a6), (a4)
  004790:  20 6e ff fc          movea.l  -$4(a6), a0
  004794:  47 e8 00 02          lea.l    $2(a0), a3
  004798:  30 2b 00 04          move.w   $4(a3), d0
  00479c:  48 c0                ext.l    d0
  00479e:  5d c6                slt.b    d6
  0047a0:  44 06                neg.b    d6
  0047a2:  4a 06                tst.b    d6
  0047a4:  67 64                beq.b    $480a  ; -> L480a
  0047a6:  20 53                movea.l  (a3), a0
  0047a8:  26 50                movea.l  (a0), a3
  0047aa:  41 ec 00 0e          lea.l    $e(a4), a0
  0047ae:  22 4b                movea.l  a3, a1
  0047b0:  70 0b                moveq    #$b, d0
L47b2:
  0047b2:  20 d9                move.l   (a1)+, (a0)+
  0047b4:  51 c8 ff fc          dbra     d0, $47b2  ; -> L47b2
  0047b8:  30 d9                move.w   (a1)+, (a0)+
  0047ba:  3e 2b 00 0e          move.w   $e(a3), d7
  0047be:  48 c7                ext.l    d7
  0047c0:  70 01                moveq    #$1, d0
  0047c2:  b0 87                cmp.l    d7, d0
  0047c4:  67 08                beq.b    $47ce  ; -> L47ce
  0047c6:  48 c7                ext.l    d7
  0047c8:  70 02                moveq    #$2, d0
  0047ca:  b0 87                cmp.l    d7, d0
  0047cc:  66 48                bne.b    $4816  ; -> L4816
L47ce:
  0047ce:  48 c7                ext.l    d7
  0047d0:  70 02                moveq    #$2, d0
  0047d2:  b0 87                cmp.l    d7, d0
  0047d4:  66 06                bne.b    $47dc  ; -> L47dc
  0047d6:  20 53                movea.l  (a3), a0
  0047d8:  29 50 00 0e          move.l   (a0), $e(a4)
L47dc:
  0047dc:  20 2b 00 2e          move.l   $2e(a3), d0
  0047e0:  08 00 00 00          btst.b   #$0, d0
  0047e4:  67 08                beq.b    $47ee  ; -> L47ee
  0047e6:  70 00                moveq    #$0, d0
  0047e8:  29 40 00 04          move.l   d0, $4(a4)
  0047ec:  60 28                bra.b    $4816  ; -> L4816
L47ee:
  0047ee:  48 c7                ext.l    d7
  0047f0:  70 02                moveq    #$2, d0
  0047f2:  b0 87                cmp.l    d7, d0
  0047f4:  66 04                bne.b    $47fa  ; -> L47fa
  0047f6:  20 13                move.l   (a3), d0
  0047f8:  60 0a                bra.b    $4804  ; -> L4804
L47fa:
  0047fa:  59 8f                subq.l   #$4, a7
  0047fc:  2f 13                move.l   (a3), -(a7)
  0047fe:  4e ba 5c 92          jsr      $a492(pc)  ; -> sub_a492
  004802:  20 1f                move.l   (a7)+, d0
L4804:
  004804:  29 40 00 04          move.l   d0, $4(a4)
  004808:  60 0c                bra.b    $4816  ; -> L4816
L480a:
  00480a:  41 ec 00 14          lea.l    $14(a4), a0
  00480e:  22 4b                movea.l  a3, a1
  004810:  5c 89                addq.l   #$6, a1
  004812:  20 d9                move.l   (a1)+, (a0)+
  004814:  20 d9                move.l   (a1)+, (a0)+
L4816:
  004816:  4e ba ca 18          jsr      $1230(pc)  ; -> GetA5
  00481a:  20 40                movea.l  d0, a0
  00481c:  20 10                move.l   (a0), d0
  00481e:  90 bc 00 00 00 ca    sub.l    #$ca, d0
  004824:  20 40                movea.l  d0, a0
  004826:  29 68 00 22 00 40    move.l   $22(a0), $40(a4)
  00482c:  29 78 0c c8 00 48    move.l   $cc8.w, $48(a4)
  004832:  29 78 08 a8 00 44    move.l   $8a8.w, $44(a4)
  004838:  4c ee 18 c0 ff ec    movem.l  -$14(a6), d6-d7/a3-a4
  00483e:  4e 5e                unlk     a6
  004840:  4e 75                rts
* s7_sub_86d6  -  System 7 $86D6 (similar code, r=0.76).
s7_sub_86d6:
  004842:  4e 56 ff f8          link.w   a6, #$fff8
  004846:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  00484a:  28 6e 00 08          movea.l  $8(a6), a4
  00484e:  3c 2c 00 04          move.w   $4(a4), d6
  004852:  48 c6                ext.l    d6
  004854:  4a 86                tst.l    d6
  004856:  6d 06                blt.b    $485e  ; -> L485e
  004858:  70 00                moveq    #$0, d0
  00485a:  60 00 00 98          bra.w    $48f4  ; -> L48f4
L485e:
  00485e:  48 c6                ext.l    d6
  004860:  20 3c 00 00 40 00    move.l   #$4000, d0
  004866:  c0 86                and.l    d6, d0
  004868:  67 06                beq.b    $4870  ; -> L4870
  00486a:  20 54                movea.l  (a4), a0
  00486c:  26 50                movea.l  (a0), a3
  00486e:  60 02                bra.b    $4872  ; -> L4872
L4870:
  004870:  26 4c                movea.l  a4, a3
L4872:
  004872:  30 2b 00 0e          move.w   $e(a3), d0
  004876:  48 c0                ext.l    d0
  004878:  2e 00                move.l   d0, d7
  00487a:  70 01                moveq    #$1, d0
  00487c:  b0 87                cmp.l    d7, d0
  00487e:  66 0c                bne.b    $488c  ; -> L488c
  004880:  59 8f                subq.l   #$4, a7
  004882:  2f 13                move.l   (a3), -(a7)
  004884:  4e ba 5c 0c          jsr      $a492(pc)  ; -> sub_a492
  004888:  28 5f                movea.l  (a7)+, a4
  00488a:  60 0e                bra.b    $489a  ; -> L489a
L488c:
  00488c:  70 02                moveq    #$2, d0
  00488e:  b0 87                cmp.l    d7, d0
  004890:  66 04                bne.b    $4896  ; -> L4896
  004892:  28 53                movea.l  (a3), a4
  004894:  60 04                bra.b    $489a  ; -> L489a
L4896:
  004896:  70 00                moveq    #$0, d0
  004898:  60 5a                bra.b    $48f4  ; -> L48f4
L489a:
  00489a:  2d 4c ff f8          move.l   a4, -$8(a6)
  00489e:  70 00                moveq    #$0, d0
  0048a0:  2d 40 ff fc          move.l   d0, -$4(a6)
  0048a4:  72 01                moveq    #$1, d1
  0048a6:  2f 01                move.l   d1, -(a7)
  0048a8:  70 02                moveq    #$2, d0
  0048aa:  2f 00                move.l   d0, -(a7)
  0048ac:  48 6e ff f8          pea.l    -$8(a6)
  0048b0:  70 0d                moveq    #$d, d0
  0048b2:  2f 00                move.l   d0, -(a7)
  0048b4:  4e ba 19 6e          jsr      $6224(pc)  ; -> EngineDispatch
  0048b8:  28 40                movea.l  d0, a4
  0048ba:  20 0c                move.l   a4, d0
  0048bc:  4f ef 00 10          lea.l    $10(a7), a7
  0048c0:  66 04                bne.b    $48c6  ; -> L48c6
  0048c2:  70 00                moveq    #$0, d0
  0048c4:  60 2e                bra.b    $48f4  ; -> L48f4
L48c6:
  0048c6:  20 6e 00 0c          movea.l  $c(a6), a0
  0048ca:  20 93                move.l   (a3), (a0)
  0048cc:  20 6e 00 10          movea.l  $10(a6), a0
  0048d0:  30 ab 00 0e          move.w   $e(a3), (a0)
  0048d4:  26 8c                move.l   a4, (a3)
  0048d6:  37 7c 00 04 00 0e    move.w   #$4, $e(a3)
  0048dc:  70 01                moveq    #$1, d0
  0048de:  2f 00                move.l   d0, -(a7)
  0048e0:  72 00                moveq    #$0, d1
  0048e2:  2f 01                move.l   d1, -(a7)
  0048e4:  2f 01                move.l   d1, -(a7)
  0048e6:  70 38                moveq    #$38, d0
  0048e8:  2f 00                move.l   d0, -(a7)
  0048ea:  4e ba 19 38          jsr      $6224(pc)  ; -> EngineDispatch
  0048ee:  70 01                moveq    #$1, d0
  0048f0:  4f ef 00 10          lea.l    $10(a7), a7
L48f4:
  0048f4:  4c ee 18 c0 ff e8    movem.l  -$18(a6), d6-d7/a3-a4
  0048fa:  4e 5e                unlk     a6
  0048fc:  4e 75                rts
* s7_sub_879a  -  System 7 $879A (similar code, r=0.73).
s7_sub_879a:
  0048fe:  48 e7 00 18          movem.l  a3-a4, -(a7)
  004902:  28 6f 00 0c          movea.l  $c(a7), a4
  004906:  30 2c 00 04          move.w   $4(a4), d0
  00490a:  48 c0                ext.l    d0
  00490c:  22 3c 00 00 40 00    move.l   #$4000, d1
  004912:  c2 80                and.l    d0, d1
  004914:  67 06                beq.b    $491c  ; -> L491c
  004916:  20 54                movea.l  (a4), a0
  004918:  26 50                movea.l  (a0), a3
  00491a:  60 02                bra.b    $491e  ; -> L491e
L491c:
  00491c:  26 4c                movea.l  a4, a3
L491e:
  00491e:  26 af 00 10          move.l   $10(a7), (a3)
  004922:  37 6f 00 16 00 0e    move.w   $16(a7), $e(a3)
  004928:  4c df 18 00          movem.l  (a7)+, a3-a4
  00492c:  4e 75                rts
* s7_sub_87cc  -  System 7 $87CC (similar code, r=0.84).
s7_sub_87cc:
  00492e:  4e 56 ff fe          link.w   a6, #$fffe
  004932:  48 e7 13 18          movem.l  d3/d6-d7/a3-a4, -(a7)
  004936:  2c 2e 00 0c          move.l   $c(a6), d6
  00493a:  28 6e 00 08          movea.l  $8(a6), a4
  00493e:  1d 7c 00 01 ff ff    move.b   #$1, -$1(a6)
  004944:  48 6e ff ff          pea.l    -$1(a6)
  004948:  4e ba 5b d4          jsr      $a51e(pc)  ; -> sub_a51e
L494c:
  00494c:  4a ac 00 04          tst.l    $4(a4)
  004950:  66 fa                bne.b    $494c  ; -> L494c
  004952:  70 01                moveq    #$1, d0
  004954:  28 80                move.l   d0, (a4)
  004956:  4a ac 00 04          tst.l    $4(a4)
  00495a:  67 0e                beq.b    $496a  ; -> L496a
  00495c:  70 00                moveq    #$0, d0
  00495e:  28 80                move.l   d0, (a4)
L4960:
  004960:  4a ac 00 04          tst.l    $4(a4)
  004964:  66 fa                bne.b    $4960  ; -> L4960
  004966:  70 01                moveq    #$1, d0
  004968:  28 80                move.l   d0, (a4)
L496a:
  00496a:  42 07                clr.b    d7
  00496c:  26 6c 00 08          movea.l  $8(a4), a3
  004970:  76 00                moveq    #$0, d3
  004972:  60 1e                bra.b    $4992  ; -> L4992
L4974:
  004974:  bc ab 00 0c          cmp.l    $c(a3), d6
  004978:  66 14                bne.b    $498e  ; -> L498e
  00497a:  20 3c 40 00 00 00    move.l   #$40000000, d0
  004980:  c0 93                and.l    (a3), d0
  004982:  66 0a                bne.b    $498e  ; -> L498e
  004984:  7e 01                moveq    #$1, d7
  004986:  00 93 80 00 00 00    ori.l    #$80000000, (a3)
  00498c:  60 08                bra.b    $4996  ; -> L4996
L498e:
  00498e:  26 6b 00 08          movea.l  $8(a3), a3
L4992:
  004992:  b6 8b                cmp.l    a3, d3
  004994:  66 de                bne.b    $4974  ; -> L4974
L4996:
  004996:  70 00                moveq    #$0, d0
  004998:  28 80                move.l   d0, (a4)
  00499a:  48 6e ff ff          pea.l    -$1(a6)
  00499e:  4e ba 5b 7e          jsr      $a51e(pc)  ; -> sub_a51e
  0049a2:  10 07                move.b   d7, d0
  0049a4:  4c ee 18 c8 ff ea    movem.l  -$16(a6), d3/d6-d7/a3-a4
  0049aa:  4e 5e                unlk     a6
  0049ac:  4e 75                rts
* s7_sub_884e  -  System 7 $884E (similar code, r=0.86).
s7_sub_884e:
  0049ae:  4e 56 ff fa          link.w   a6, #$fffa
  0049b2:  48 e7 17 18          movem.l  d3/d5-d7/a3-a4, -(a7)
  0049b6:  2a 2e 00 10          move.l   $10(a6), d5
  0049ba:  2c 2e 00 0c          move.l   $c(a6), d6
  0049be:  28 6e 00 08          movea.l  $8(a6), a4
  0049c2:  1d 7c 00 01 ff fb    move.b   #$1, -$5(a6)
  0049c8:  48 6e ff fb          pea.l    -$5(a6)
  0049cc:  4e ba 5b 50          jsr      $a51e(pc)  ; -> sub_a51e
L49d0:
  0049d0:  4a ac 00 04          tst.l    $4(a4)
  0049d4:  66 fa                bne.b    $49d0  ; -> L49d0
  0049d6:  70 01                moveq    #$1, d0
  0049d8:  28 80                move.l   d0, (a4)
  0049da:  4a ac 00 04          tst.l    $4(a4)
  0049de:  67 0e                beq.b    $49ee  ; -> L49ee
  0049e0:  70 00                moveq    #$0, d0
  0049e2:  28 80                move.l   d0, (a4)
L49e4:
  0049e4:  4a ac 00 04          tst.l    $4(a4)
  0049e8:  66 fa                bne.b    $49e4  ; -> L49e4
  0049ea:  70 01                moveq    #$1, d0
  0049ec:  28 80                move.l   d0, (a4)
L49ee:
  0049ee:  42 07                clr.b    d7
  0049f0:  26 6c 00 08          movea.l  $8(a4), a3
  0049f4:  76 00                moveq    #$0, d3
  0049f6:  60 30                bra.b    $4a28  ; -> L4a28
L49f8:
  0049f8:  bc ab 00 0c          cmp.l    $c(a3), d6
  0049fc:  66 26                bne.b    $4a24  ; -> L4a24
  0049fe:  20 3c 40 00 00 00    move.l   #$40000000, d0
  004a04:  c0 93                and.l    (a3), d0
  004a06:  66 1c                bne.b    $4a24  ; -> L4a24
  004a08:  41 eb 00 10          lea.l    $10(a3), a0
  004a0c:  2d 48 ff fc          move.l   a0, -$4(a6)
  004a10:  30 28 04 32          move.w   $432(a0), d0
  004a14:  48 c0                ext.l    d0
  004a16:  ba 80                cmp.l    d0, d5
  004a18:  66 0a                bne.b    $4a24  ; -> L4a24
  004a1a:  7e 01                moveq    #$1, d7
  004a1c:  00 93 80 00 00 00    ori.l    #$80000000, (a3)
  004a22:  60 08                bra.b    $4a2c  ; -> L4a2c
L4a24:
  004a24:  26 6b 00 08          movea.l  $8(a3), a3
L4a28:
  004a28:  b6 8b                cmp.l    a3, d3
  004a2a:  66 cc                bne.b    $49f8  ; -> L49f8
L4a2c:
  004a2c:  70 00                moveq    #$0, d0
  004a2e:  28 80                move.l   d0, (a4)
  004a30:  48 6e ff fb          pea.l    -$5(a6)
  004a34:  4e ba 5a e8          jsr      $a51e(pc)  ; -> sub_a51e
  004a38:  10 07                move.b   d7, d0
  004a3a:  4c ee 18 e8 ff e2    movem.l  -$1e(a6), d3/d5-d7/a3-a4
  004a40:  4e 5e                unlk     a6
  004a42:  4e 75                rts
* s7_sub_88e6  -  System 7 $88E6 (similar code, r=0.72).
s7_sub_88e6:
  004a44:  4e 56 ff 96          link.w   a6, #$ff96
  004a48:  48 e7 1f 18          movem.l  d3-d7/a3-a4, -(a7)
  004a4c:  49 ee ff c2          lea.l    -$3e(a6), a4
  004a50:  2a 2e 00 0c          move.l   $c(a6), d5
  004a54:  4e ba c7 da          jsr      $1230(pc)  ; -> GetA5
  004a58:  20 40                movea.l  d0, a0
  004a5a:  20 10                move.l   (a0), d0
  004a5c:  90 bc 00 00 00 ca    sub.l    #$ca, d0
  004a62:  2d 40 ff 96          move.l   d0, -$6a(a6)
  004a66:  70 00                moveq    #$0, d0
  004a68:  2d 40 ff b2          move.l   d0, -$4e(a6)
  004a6c:  7e 00                moveq    #$0, d7
  004a6e:  42 04                clr.b    d4
  004a70:  42 2e ff fe          clr.b    -$2(a6)
  004a74:  42 2e ff ff          clr.b    -$1(a6)
  004a78:  55 8f                subq.l   #$2, a7
  004a7a:  3f 05                move.w   d5, -(a7)
  004a7c:  2f 2e 00 08          move.l   $8(a6), -(a7)
  004a80:  48 6e 00 10          pea.l    $10(a6)
  004a84:  48 6e 00 14          pea.l    $14(a6)
  004a88:  48 6e ff 9a          pea.l    -$66(a6)
  004a8c:  a8 ed                dc.w     $a8ed
  004a8e:  20 6e ff 96          movea.l  -$6a(a6), a0
  004a92:  2c 28 00 1e          move.l   $1e(a0), d6
  004a96:  20 6e 00 18          movea.l  $18(a6), a0
  004a9a:  20 86                move.l   d6, (a0)
  004a9c:  3d 6e 00 12 ff ae    move.w   $12(a6), -$52(a6)
  004aa2:  3d 6e 00 16 ff b0    move.w   $16(a6), -$50(a6)
  004aa8:  30 2e ff b0          move.w   -$50(a6), d0
  004aac:  48 c0                ext.l    d0
  004aae:  32 2e ff ae          move.w   -$52(a6), d1
  004ab2:  48 c1                ext.l    d1
  004ab4:  b0 81                cmp.l    d1, d0
  004ab6:  54 8f                addq.l   #$2, a7
  004ab8:  66 08                bne.b    $4ac2  ; -> L4ac2
  004aba:  20 6e 00 1c          movea.l  $1c(a6), a0
  004abe:  20 86                move.l   d6, (a0)
  004ac0:  60 20                bra.b    $4ae2  ; -> L4ae2
L4ac2:
  004ac2:  30 2e ff b0          move.w   -$50(a6), d0
  004ac6:  48 c0                ext.l    d0
  004ac8:  2f 00                move.l   d0, -(a7)
  004aca:  30 2e ff ae          move.w   -$52(a6), d0
  004ace:  48 c0                ext.l    d0
  004ad0:  2f 00                move.l   d0, -(a7)
  004ad2:  2f 06                move.l   d6, -(a7)
  004ad4:  4e ba 04 92          jsr      $4f68(pc)  ; -> FixScale
  004ad8:  20 6e 00 1c          movea.l  $1c(a6), a0
  004adc:  20 80                move.l   d0, (a0)
  004ade:  4f ef 00 0c          lea.l    $c(a7), a7
L4ae2:
  004ae2:  20 6e 00 28          movea.l  $28(a6), a0
  004ae6:  26 50                movea.l  (a0), a3
  004ae8:  2d 78 0b 2a ff a6    move.l   $b2a.w, -$5a(a6)
  004aee:  20 6e ff a6          movea.l  -$5a(a6), a0
  004af2:  2d 50 ff aa          move.l   (a0), -$56(a6)
  004af6:  20 6e ff aa          movea.l  -$56(a6), a0
  004afa:  22 6e 00 20          movea.l  $20(a6), a1
  004afe:  22 a8 00 80          move.l   $80(a0), (a1)
  004b02:  2f 2e ff aa          move.l   -$56(a6), -(a7)
  004b06:  4e ba 04 bc          jsr      $4fc4(pc)  ; -> s7_sub_7e8c
  004b0a:  3d 40 ff b6          move.w   d0, -$4a(a6)
  004b0e:  b7 ee ff a6          cmpa.l   -$5a(a6), a3
  004b12:  58 8f                addq.l   #$4, a7
  004b14:  66 14                bne.b    $4b2a  ; -> L4b2a
  004b16:  20 6e 00 2c          movea.l  $2c(a6), a0
  004b1a:  30 28 04 32          move.w   $432(a0), d0
  004b1e:  48 c0                ext.l    d0
  004b20:  32 2e ff b6          move.w   -$4a(a6), d1
  004b24:  48 c1                ext.l    d1
  004b26:  b0 81                cmp.l    d1, d0
  004b28:  67 0c                beq.b    $4b36  ; -> L4b36
L4b2a:
  004b2a:  70 01                moveq    #$1, d0
  004b2c:  2d 40 ff b2          move.l   d0, -$4e(a6)
  004b30:  1d 7c 00 01 ff fe    move.b   #$1, -$2(a6)
L4b36:
  004b36:  20 6e ff aa          movea.l  -$56(a6), a0
  004b3a:  30 28 04 32          move.w   $432(a0), d0
  004b3e:  48 c0                ext.l    d0
  004b40:  32 2e ff b6          move.w   -$4a(a6), d1
  004b44:  48 c1                ext.l    d1
  004b46:  b0 81                cmp.l    d1, d0
  004b48:  66 22                bne.b    $4b6c  ; -> L4b6c
  004b4a:  30 2e ff b6          move.w   -$4a(a6), d0
  004b4e:  48 c0                ext.l    d0
  004b50:  2f 00                move.l   d0, -(a7)
  004b52:  2f 2e ff a6          move.l   -$5a(a6), -(a7)
  004b56:  20 6e 00 30          movea.l  $30(a6), a0
  004b5a:  48 68 00 f0          pea.l    $f0(a0)
  004b5e:  4e ba fe 4e          jsr      $49ae(pc)  ; -> s7_sub_884e
  004b62:  72 00                moveq    #$0, d1
  004b64:  12 00                move.b   d0, d1
  004b66:  4f ef 00 0c          lea.l    $c(a7), a7
  004b6a:  66 1a                bne.b    $4b86  ; -> L4b86
L4b6c:
  004b6c:  00 87 00 00 00 01    ori.l    #$1, d7
  004b72:  70 01                moveq    #$1, d0
  004b74:  2d 40 ff b2          move.l   d0, -$4e(a6)
  004b78:  1d 7c 00 01 ff fe    move.b   #$1, -$2(a6)
  004b7e:  b7 ee ff a6          cmpa.l   -$5a(a6), a3
  004b82:  66 02                bne.b    $4b86  ; -> L4b86
  004b84:  78 01                moveq    #$1, d4
L4b86:
  004b86:  20 6e ff aa          movea.l  -$56(a6), a0
  004b8a:  30 28 04 1c          move.w   $41c(a0), d0
  004b8e:  48 c0                ext.l    d0
  004b90:  0c 80 00 00 40 00    cmpi.l   #$4000, d0
  004b96:  6d 38                blt.b    $4bd0  ; -> L4bd0
  004b98:  76 00                moveq    #$0, d3
  004b9a:  60 30                bra.b    $4bcc  ; -> L4bcc
L4b9c:
  004b9c:  20 2e 00 08          move.l   $8(a6), d0
  004ba0:  52 ae 00 08          addq.l   #$1, $8(a6)
  004ba4:  20 40                movea.l  d0, a0
  004ba6:  1c 10                move.b   (a0), d6
  004ba8:  70 00                moveq    #$0, d0
  004baa:  10 06                move.b   d6, d0
  004bac:  0c 80 00 00 00 84    cmpi.l   #$84, d0
  004bb2:  6d 14                blt.b    $4bc8  ; -> L4bc8
  004bb4:  70 00                moveq    #$0, d0
  004bb6:  10 06                move.b   d6, d0
  004bb8:  0c 80 00 00 00 9e    cmpi.l   #$9e, d0
  004bbe:  6e 08                bgt.b    $4bc8  ; -> L4bc8
  004bc0:  00 87 00 00 00 08    ori.l    #$8, d7
  004bc6:  60 08                bra.b    $4bd0  ; -> L4bd0
L4bc8:
  004bc8:  20 05                move.l   d5, d0
  004bca:  53 85                subq.l   #$1, d5
L4bcc:
  004bcc:  b6 85                cmp.l    d5, d3
  004bce:  6d cc                blt.b    $4b9c  ; -> L4b9c
L4bd0:
  004bd0:  20 6e ff aa          movea.l  -$56(a6), a0
  004bd4:  2d 68 04 00 ff be    move.l   $400(a0), -$42(a6)
  004bda:  20 6e ff be          movea.l  -$42(a6), a0
  004bde:  70 14                moveq    #$14, d0
  004be0:  22 10                move.l   (a0), d1
  004be2:  e0 a9                lsr.l    d0, d1
  004be4:  70 0f                moveq    #$f, d0
  004be6:  c0 81                and.l    d1, d0
  004be8:  72 08                moveq    #$8, d1
  004bea:  b2 80                cmp.l    d0, d1
  004bec:  57 c6                seq.b    d6
  004bee:  44 06                neg.b    d6
  004bf0:  4a 06                tst.b    d6
  004bf2:  67 20                beq.b    $4c14  ; -> L4c14
  004bf4:  2f 2e ff be          move.l   -$42(a6), -(a7)
  004bf8:  20 6e 00 30          movea.l  $30(a6), a0
  004bfc:  48 68 00 c0          pea.l    $c0(a0)
  004c00:  4e ba fd 2c          jsr      $492e(pc)  ; -> s7_sub_87cc
  004c04:  72 00                moveq    #$0, d1
  004c06:  12 00                move.b   d0, d1
  004c08:  50 8f                addq.l   #$8, a7
  004c0a:  66 3a                bne.b    $4c46  ; -> L4c46
  004c0c:  00 87 00 00 00 02    ori.l    #$2, d7
  004c12:  60 32                bra.b    $4c46  ; -> L4c46
L4c14:
  004c14:  20 6e ff be          movea.l  -$42(a6), a0
  004c18:  20 50                movea.l  (a0), a0
  004c1a:  30 10                move.w   (a0), d0
  004c1c:  48 c0                ext.l    d0
  004c1e:  22 3c 00 00 08 00    move.l   #$800, d1
  004c24:  c2 80                and.l    d0, d1
  004c26:  67 18                beq.b    $4c40  ; -> L4c40
  004c28:  2f 2e ff be          move.l   -$42(a6), -(a7)
  004c2c:  20 6e 00 30          movea.l  $30(a6), a0
  004c30:  48 68 00 c0          pea.l    $c0(a0)
  004c34:  4e ba fc f8          jsr      $492e(pc)  ; -> s7_sub_87cc
  004c38:  72 00                moveq    #$0, d1
  004c3a:  12 00                move.b   d0, d1
  004c3c:  50 8f                addq.l   #$8, a7
  004c3e:  66 06                bne.b    $4c46  ; -> L4c46
L4c40:
  004c40:  00 87 00 00 00 02    ori.l    #$2, d7
L4c46:
  004c46:  70 0a                moveq    #$a, d0
  004c48:  c0 87                and.l    d7, d0
  004c4a:  67 10                beq.b    $4c5c  ; -> L4c5c
  004c4c:  20 6e 00 2c          movea.l  $2c(a6), a0
  004c50:  20 2e ff be          move.l   -$42(a6), d0
  004c54:  b0 a8 04 00          cmp.l    $400(a0), d0
  004c58:  66 02                bne.b    $4c5c  ; -> L4c5c
  004c5a:  78 01                moveq    #$1, d4
L4c5c:
  004c5c:  20 6e ff 96          movea.l  -$6a(a6), a0
  004c60:  2d 68 00 1a ff a2    move.l   $1a(a0), -$5e(a6)
  004c66:  20 6e ff a2          movea.l  -$5e(a6), a0
  004c6a:  26 68 00 02          movea.l  $2(a0), a3
  004c6e:  20 6e 00 24          movea.l  $24(a6), a0
  004c72:  2d 68 00 02 ff ba    move.l   $2(a0), -$46(a6)
  004c78:  20 53                movea.l  (a3), a0
  004c7a:  30 10                move.w   (a0), d0
  004c7c:  48 c0                ext.l    d0
  004c7e:  22 3c 00 00 01 00    move.l   #$100, d1
  004c84:  c2 80                and.l    d0, d1
  004c86:  67 04                beq.b    $4c8c  ; -> L4c8c
  004c88:  26 6e ff be          movea.l  -$42(a6), a3
L4c8c:
  004c8c:  b7 ee ff ba          cmpa.l   -$46(a6), a3
  004c90:  66 40                bne.b    $4cd2  ; -> L4cd2
  004c92:  2f 2e 00 24          move.l   $24(a6), -(a7)
  004c96:  2f 2e ff a2          move.l   -$5e(a6), -(a7)
  004c9a:  4e ba 02 f4          jsr      $4f90(pc)  ; -> EqualFontOutput
  004c9e:  72 00                moveq    #$0, d1
  004ca0:  12 00                move.b   d0, d1
  004ca2:  50 8f                addq.l   #$8, a7
  004ca4:  67 2c                beq.b    $4cd2  ; -> L4cd2
  004ca6:  41 ee 00 10          lea.l    $10(a6), a0
  004caa:  22 6e 00 24          movea.l  $24(a6), a1
  004cae:  43 e9 00 12          lea.l    $12(a1), a1
  004cb2:  70 00                moveq    #$0, d0
L4cb4:
  004cb4:  b1 89                cmpm.l   (a1)+, (a0)+
  004cb6:  56 c8 ff fc          dbne     d0, $4cb4  ; -> L4cb4
  004cba:  66 16                bne.b    $4cd2  ; -> L4cd2
  004cbc:  41 ee 00 14          lea.l    $14(a6), a0
  004cc0:  22 6e 00 24          movea.l  $24(a6), a1
  004cc4:  43 e9 00 16          lea.l    $16(a1), a1
  004cc8:  70 00                moveq    #$0, d0
L4cca:
  004cca:  b1 89                cmpm.l   (a1)+, (a0)+
  004ccc:  56 c8 ff fc          dbne     d0, $4cca  ; -> L4cca
  004cd0:  67 0c                beq.b    $4cde  ; -> L4cde
L4cd2:
  004cd2:  70 01                moveq    #$1, d0
  004cd4:  2d 40 ff b2          move.l   d0, -$4e(a6)
  004cd8:  1d 7c 00 01 ff ff    move.b   #$1, -$1(a6)
L4cde:
  004cde:  b7 ee ff be          cmpa.l   -$42(a6), a3
  004ce2:  67 6e                beq.b    $4d52  ; -> L4d52
  004ce4:  70 14                moveq    #$14, d0
  004ce6:  22 13                move.l   (a3), d1
  004ce8:  e0 a9                lsr.l    d0, d1
  004cea:  70 0f                moveq    #$f, d0
  004cec:  c0 81                and.l    d1, d0
  004cee:  72 08                moveq    #$8, d1
  004cf0:  b2 80                cmp.l    d0, d1
  004cf2:  57 c5                seq.b    d5
  004cf4:  44 05                neg.b    d5
  004cf6:  4a 05                tst.b    d5
  004cf8:  67 1e                beq.b    $4d18  ; -> L4d18
  004cfa:  2f 0b                move.l   a3, -(a7)
  004cfc:  20 6e 00 30          movea.l  $30(a6), a0
  004d00:  48 68 00 c0          pea.l    $c0(a0)
  004d04:  4e ba fc 28          jsr      $492e(pc)  ; -> s7_sub_87cc
  004d08:  72 00                moveq    #$0, d1
  004d0a:  12 00                move.b   d0, d1
  004d0c:  50 8f                addq.l   #$8, a7
  004d0e:  66 42                bne.b    $4d52  ; -> L4d52
  004d10:  00 87 00 00 00 04    ori.l    #$4, d7
  004d16:  60 3a                bra.b    $4d52  ; -> L4d52
L4d18:
  004d18:  20 53                movea.l  (a3), a0
  004d1a:  30 10                move.w   (a0), d0
  004d1c:  48 c0                ext.l    d0
  004d1e:  22 3c 00 00 08 00    move.l   #$800, d1
  004d24:  c2 80                and.l    d0, d1
  004d26:  67 16                beq.b    $4d3e  ; -> L4d3e
  004d28:  2f 0b                move.l   a3, -(a7)
  004d2a:  20 6e 00 30          movea.l  $30(a6), a0
  004d2e:  48 68 00 c0          pea.l    $c0(a0)
  004d32:  4e ba fb fa          jsr      $492e(pc)  ; -> s7_sub_87cc
  004d36:  72 00                moveq    #$0, d1
  004d38:  12 00                move.b   d0, d1
  004d3a:  50 8f                addq.l   #$8, a7
  004d3c:  66 08                bne.b    $4d46  ; -> L4d46
L4d3e:
  004d3e:  00 87 00 00 00 04    ori.l    #$4, d7
  004d44:  60 0c                bra.b    $4d52  ; -> L4d52
L4d46:
  004d46:  70 08                moveq    #$8, d0
  004d48:  c0 87                and.l    d7, d0
  004d4a:  67 06                beq.b    $4d52  ; -> L4d52
  004d4c:  00 87 00 00 00 10    ori.l    #$10, d7
L4d52:
  004d52:  70 14                moveq    #$14, d0
  004d54:  c0 87                and.l    d7, d0
  004d56:  67 08                beq.b    $4d60  ; -> L4d60
  004d58:  b7 ee ff ba          cmpa.l   -$46(a6), a3
  004d5c:  66 02                bne.b    $4d60  ; -> L4d60
  004d5e:  78 01                moveq    #$1, d4
L4d60:
  004d60:  4a 87                tst.l    d7
  004d62:  67 00 01 4e          beq.w    $4eb2  ; -> L4eb2
  004d66:  4a 04                tst.b    d4
  004d68:  67 16                beq.b    $4d80  ; -> L4d80
  004d6a:  70 01                moveq    #$1, d0
  004d6c:  2f 00                move.l   d0, -(a7)
  004d6e:  72 00                moveq    #$0, d1
  004d70:  2f 01                move.l   d1, -(a7)
  004d72:  2f 01                move.l   d1, -(a7)
  004d74:  70 38                moveq    #$38, d0
  004d76:  2f 00                move.l   d0, -(a7)
  004d78:  4e ba 14 aa          jsr      $6224(pc)  ; -> EngineDispatch
  004d7c:  4f ef 00 10          lea.l    $10(a7), a7
L4d80:
  004d80:  78 00                moveq    #$0, d4
  004d82:  20 04                move.l   d4, d0
  004d84:  52 84                addq.l   #$1, d4
  004d86:  e5 40                asl.w    #$2, d0
  004d88:  29 87 00 00          move.l   d7, (a4, d0.w)
  004d8c:  08 07 00 00          btst.b   #$0, d7
  004d90:  67 2c                beq.b    $4dbe  ; -> L4dbe
  004d92:  20 6e ff aa          movea.l  -$56(a6), a0
  004d96:  3d 68 04 32 ff b8    move.w   $432(a0), -$48(a6)
  004d9c:  20 6e ff aa          movea.l  -$56(a6), a0
  004da0:  31 6e ff b6 04 32    move.w   -$4a(a6), $432(a0)
  004da6:  20 04                move.l   d4, d0
  004da8:  52 84                addq.l   #$1, d4
  004daa:  e5 40                asl.w    #$2, d0
  004dac:  29 ae ff a6 00 00    move.l   -$5a(a6), (a4, d0.w)
  004db2:  20 04                move.l   d4, d0
  004db4:  52 84                addq.l   #$1, d4
  004db6:  e5 40                asl.w    #$2, d0
  004db8:  29 ae ff aa 00 00    move.l   -$56(a6), (a4, d0.w)
L4dbe:
  004dbe:  70 02                moveq    #$2, d0
  004dc0:  c0 87                and.l    d7, d0
  004dc2:  67 30                beq.b    $4df4  ; -> L4df4
  004dc4:  20 04                move.l   d4, d0
  004dc6:  52 84                addq.l   #$1, d4
  004dc8:  e5 40                asl.w    #$2, d0
  004dca:  29 ae ff be 00 00    move.l   -$42(a6), (a4, d0.w)
  004dd0:  20 6e ff be          movea.l  -$42(a6), a0
  004dd4:  20 04                move.l   d4, d0
  004dd6:  52 84                addq.l   #$1, d4
  004dd8:  e5 40                asl.w    #$2, d0
  004dda:  29 90 00 00          move.l   (a0), (a4, d0.w)
  004dde:  59 8f                subq.l   #$4, a7
  004de0:  2f 2e ff be          move.l   -$42(a6), -(a7)
  004de4:  4e ba 56 8c          jsr      $a472(pc)  ; -> s7_sub_bfde
  004de8:  20 04                move.l   d4, d0
  004dea:  52 84                addq.l   #$1, d4
  004dec:  e5 40                asl.w    #$2, d0
  004dee:  29 9f 00 00          move.l   (a7)+, (a4, d0.w)
  004df2:  60 20                bra.b    $4e14  ; -> L4e14
L4df4:
  004df4:  70 08                moveq    #$8, d0
  004df6:  c0 87                and.l    d7, d0
  004df8:  67 1a                beq.b    $4e14  ; -> L4e14
  004dfa:  20 04                move.l   d4, d0
  004dfc:  52 84                addq.l   #$1, d4
  004dfe:  e5 40                asl.w    #$2, d0
  004e00:  29 ae ff be 00 00    move.l   -$42(a6), (a4, d0.w)
  004e06:  20 6e ff be          movea.l  -$42(a6), a0
  004e0a:  20 04                move.l   d4, d0
  004e0c:  52 84                addq.l   #$1, d4
  004e0e:  e5 40                asl.w    #$2, d0
  004e10:  29 90 00 00          move.l   (a0), (a4, d0.w)
L4e14:
  004e14:  70 04                moveq    #$4, d0
  004e16:  c0 87                and.l    d7, d0
  004e18:  67 28                beq.b    $4e42  ; -> L4e42
  004e1a:  20 04                move.l   d4, d0
  004e1c:  52 84                addq.l   #$1, d4
  004e1e:  e5 40                asl.w    #$2, d0
  004e20:  29 8b 00 00          move.l   a3, (a4, d0.w)
  004e24:  20 04                move.l   d4, d0
  004e26:  52 84                addq.l   #$1, d4
  004e28:  e5 40                asl.w    #$2, d0
  004e2a:  29 93 00 00          move.l   (a3), (a4, d0.w)
  004e2e:  59 8f                subq.l   #$4, a7
  004e30:  2f 0b                move.l   a3, -(a7)
  004e32:  4e ba 56 3e          jsr      $a472(pc)  ; -> s7_sub_bfde
  004e36:  20 04                move.l   d4, d0
  004e38:  52 84                addq.l   #$1, d4
  004e3a:  e5 40                asl.w    #$2, d0
  004e3c:  29 9f 00 00          move.l   (a7)+, (a4, d0.w)
  004e40:  60 1a                bra.b    $4e5c  ; -> L4e5c
L4e42:
  004e42:  70 10                moveq    #$10, d0
  004e44:  c0 87                and.l    d7, d0
  004e46:  67 14                beq.b    $4e5c  ; -> L4e5c
  004e48:  20 04                move.l   d4, d0
  004e4a:  52 84                addq.l   #$1, d4
  004e4c:  e5 40                asl.w    #$2, d0
  004e4e:  29 8b 00 00          move.l   a3, (a4, d0.w)
  004e52:  20 04                move.l   d4, d0
  004e54:  52 84                addq.l   #$1, d4
  004e56:  e5 40                asl.w    #$2, d0
  004e58:  29 93 00 00          move.l   (a3), (a4, d0.w)
L4e5c:
  004e5c:  70 01                moveq    #$1, d0
  004e5e:  2f 00                move.l   d0, -(a7)
  004e60:  2f 04                move.l   d4, -(a7)
  004e62:  2f 0c                move.l   a4, -(a7)
  004e64:  72 30                moveq    #$30, d1
  004e66:  2f 01                move.l   d1, -(a7)
  004e68:  4e ba 13 ba          jsr      $6224(pc)  ; -> EngineDispatch
  004e6c:  4a 80                tst.l    d0
  004e6e:  4f ef 00 10          lea.l    $10(a7), a7
  004e72:  66 16                bne.b    $4e8a  ; -> L4e8a
  004e74:  08 07 00 00          btst.b   #$0, d7
  004e78:  67 0a                beq.b    $4e84  ; -> L4e84
  004e7a:  20 6e ff aa          movea.l  -$56(a6), a0
  004e7e:  31 6e ff b8 04 32    move.w   -$48(a6), $432(a0)
L4e84:
  004e84:  70 ff                moveq    #$ff, d0
  004e86:  60 00 00 82          bra.w    $4f0a  ; -> L4f0a
L4e8a:
  004e8a:  70 02                moveq    #$2, d0
  004e8c:  c0 87                and.l    d7, d0
  004e8e:  67 10                beq.b    $4ea0  ; -> L4ea0
  004e90:  70 00                moveq    #$0, d0
  004e92:  10 06                move.b   d6, d0
  004e94:  66 0a                bne.b    $4ea0  ; -> L4ea0
  004e96:  20 6e ff be          movea.l  -$42(a6), a0
  004e9a:  20 50                movea.l  (a0), a0
  004e9c:  00 50 08 00          ori.w    #$800, (a0)
L4ea0:
  004ea0:  70 04                moveq    #$4, d0
  004ea2:  c0 87                and.l    d7, d0
  004ea4:  67 0c                beq.b    $4eb2  ; -> L4eb2
  004ea6:  70 00                moveq    #$0, d0
  004ea8:  10 05                move.b   d5, d0
  004eaa:  66 06                bne.b    $4eb2  ; -> L4eb2
  004eac:  20 53                movea.l  (a3), a0
  004eae:  00 50 08 00          ori.w    #$800, (a0)
L4eb2:
  004eb2:  4a 2e ff fe          tst.b    -$2(a6)
  004eb6:  67 1a                beq.b    $4ed2  ; -> L4ed2
  004eb8:  20 6e 00 28          movea.l  $28(a6), a0
  004ebc:  20 ae ff a6          move.l   -$5a(a6), (a0)
  004ec0:  20 6e ff aa          movea.l  -$56(a6), a0
  004ec4:  22 6e 00 2c          movea.l  $2c(a6), a1
  004ec8:  30 3c 01 0c          move.w   #$10c, d0
L4ecc:
  004ecc:  22 d8                move.l   (a0)+, (a1)+
  004ece:  51 c8 ff fc          dbra     d0, $4ecc  ; -> L4ecc
L4ed2:
  004ed2:  4a 2e ff ff          tst.b    -$1(a6)
  004ed6:  67 2e                beq.b    $4f06  ; -> L4f06
  004ed8:  20 6e ff a2          movea.l  -$5e(a6), a0
  004edc:  22 6e 00 24          movea.l  $24(a6), a1
  004ee0:  70 05                moveq    #$5, d0
L4ee2:
  004ee2:  22 d8                move.l   (a0)+, (a1)+
  004ee4:  51 c8 ff fc          dbra     d0, $4ee2  ; -> L4ee2
  004ee8:  32 d8                move.w   (a0)+, (a1)+
  004eea:  20 6e 00 24          movea.l  $24(a6), a0
  004eee:  21 4b 00 02          move.l   a3, $2(a0)
  004ef2:  20 6e 00 24          movea.l  $24(a6), a0
  004ef6:  21 6e 00 10 00 12    move.l   $10(a6), $12(a0)
  004efc:  20 6e 00 24          movea.l  $24(a6), a0
  004f00:  21 6e 00 14 00 16    move.l   $14(a6), $16(a0)
L4f06:
  004f06:  20 2e ff b2          move.l   -$4e(a6), d0
L4f0a:
  004f0a:  4c ee 18 f8 ff 7a    movem.l  -$86(a6), d3-d7/a3-a4
  004f10:  4e 5e                unlk     a6
  004f12:  4e 75                rts
* GA_TrapAB23  -  System 7 $7DAC (identical code).
* S7: Patch #15 replaces trap $AB23; no EngineDispatch command found
GA_TrapAB23:
  004f14:  20 5f                movea.l  (a7)+, a0
  004f16:  3f 00                move.w   d0, -(a7)
  004f18:  2f 08                move.l   a0, -(a7)
  004f1a:  4e fa d1 ee          jmp      $210a(pc)  ; -> s7_sub_9a88
  004f1e:  47 41 5f 53 65 74 46 69 dc.b     $47, $41, $5F, $53, $65, $74, $46, $69  ; GA_SetFi
  004f26:  6c 6c 50 61 74 00    dc.b     $6C, $6C, $50, $61, $74, $00  ; llPat.
* GetD2  -  System 7 $7DC4 (identical bytes, S6 MacsBug name).
* S7: embedded MacsBug symbols that follow each one) --
GetD2:
  004f2c:  20 02                move.l   d2, d0
  004f2e:  4e 75                rts
  004f30:  47 65 74 44 32 00 00 00 dc.b     $47, $65, $74, $44, $32, $00, $00, $00  ; GetD2...
* SetD2  -  System 7 $7DD0 (identical code).
SetD2:
  004f38:  24 2f 00 04          move.l   $4(a7), d2
  004f3c:  4e 75                rts
  004f3e:  53 65 74 44 32 00    dc.b     $53, $65, $74, $44, $32, $00  ; SetD2.
* BitFieldExtract  -  System 7 $7E0C (identical bytes, S6 MacsBug name).
BitFieldExtract:
  004f44:  20 6f 00 04          movea.l  $4(a7), a0
  004f48:  20 2f 00 08          move.l   $8(a7), d0
  004f4c:  22 2f 00 0c          move.l   $c(a7), d1
  004f50:  e9 d0 08 21          bfextu   (a0){0:1}, d0
  004f54:  4e 75                rts
  004f56:  42 69 74 46 69 65 6c 64 dc.b     $42, $69, $74, $46, $69, $65, $6C, $64  ; BitField
  004f5e:  45 78 74 72 61 63 74 00 dc.b     $45, $78, $74, $72, $61, $63, $74, $00  ; Extract.
  004f66:  00 00                dc.b     $00, $00  ; ..
* FixScale  -  System 7 $7E30 (identical bytes, S6 MacsBug name).
FixScale:
  004f68:  22 2f 00 08          move.l   $8(a7), d1
  004f6c:  48 41                swap     d1
  004f6e:  42 41                clr.w    d1
  004f70:  20 2f 00 04          move.l   $4(a7), d0
  004f74:  4c 01 04 01          mulu.l   d1, d1:d0
  004f78:  24 2f 00 0c          move.l   $c(a7), d2
  004f7c:  48 42                swap     d2
  004f7e:  42 42                clr.w    d2
  004f80:  4c 42 04 01          divu.l   d2, d1:d0
  004f84:  4e 75                rts
  004f86:  46 69 78 53 63 61 6c 65 dc.b     $46, $69, $78, $53, $63, $61, $6C, $65  ; FixScale
  004f8e:  00 00                dc.b     $00, $00  ; ..
* EqualFontOutput  -  System 7 $7E58 (identical bytes, S6 MacsBug name).
EqualFontOutput:
  004f90:  20 6f 00 04          movea.l  $4(a7), a0
  004f94:  5c 88                addq.l   #$6, a0
  004f96:  22 6f 00 08          movea.l  $8(a7), a1
  004f9a:  5c 89                addq.l   #$6, a1
  004f9c:  70 00                moveq    #$0, d0
  004f9e:  b3 48                cmpm.w   (a0)+, (a1)+
  004fa0:  66 0e                bne.b    $4fb0  ; -> L4fb0
  004fa2:  b3 88                cmpm.l   (a0)+, (a1)+
  004fa4:  66 0a                bne.b    $4fb0  ; -> L4fb0
  004fa6:  b3 88                cmpm.l   (a0)+, (a1)+
  004fa8:  66 06                bne.b    $4fb0  ; -> L4fb0
  004faa:  b3 48                cmpm.w   (a0)+, (a1)+
  004fac:  66 02                bne.b    $4fb0  ; -> L4fb0
  004fae:  70 01                moveq    #$1, d0
L4fb0:
  004fb0:  4e 75                rts
  004fb2:  45 71 75 61 6c 46 6f 6e dc.b     $45, $71, $75, $61, $6C, $46, $6F, $6E  ; EqualFon
  004fba:  74 4f 75 74 70 75 74 00 dc.b     $74, $4F, $75, $74, $70, $75, $74, $00  ; tOutput.
  004fc2:  00 00                dc.b     $00, $00  ; ..
* s7_sub_7e8c  -  System 7 $7E8C (identical bytes).
s7_sub_7e8c:
  004fc4:  20 6f 00 04          movea.l  $4(a7), a0
  004fc8:  30 28 04 0e          move.w   $40e(a0), d0
  004fcc:  48 c0                ext.l    d0
  004fce:  e2 98                ror.l    #$1, d0
  004fd0:  d0 a8 04 14          add.l    $414(a0), d0
  004fd4:  e2 98                ror.l    #$1, d0
  004fd6:  d0 a8 04 18          add.l    $418(a0), d0
  004fda:  e2 98                ror.l    #$1, d0
  004fdc:  72 01                moveq    #$1, d1
  004fde:  61 50                bsr.b    $5030  ; -> WidthTableCheckSum
  004fe0:  58 88                addq.l   #$4, a0
  004fe2:  32 3c 00 0c          move.w   #$c, d1
  004fe6:  61 48                bsr.b    $5030  ; -> WidthTableCheckSum
  004fe8:  d0 98                add.l    (a0)+, d0
  004fea:  e2 98                ror.l    #$1, d0
  004fec:  d0 98                add.l    (a0)+, d0
  004fee:  e2 98                ror.l    #$1, d0
  004ff0:  d0 98                add.l    (a0)+, d0
  004ff2:  e2 98                ror.l    #$1, d0
  004ff4:  d0 98                add.l    (a0)+, d0
  004ff6:  e2 98                ror.l    #$1, d0
  004ff8:  d0 98                add.l    (a0)+, d0
  004ffa:  e2 98                ror.l    #$1, d0
  004ffc:  d0 98                add.l    (a0)+, d0
  004ffe:  e2 98                ror.l    #$1, d0
  005000:  d0 98                add.l    (a0)+, d0
  005002:  e2 98                ror.l    #$1, d0
  005004:  d0 98                add.l    (a0)+, d0
  005006:  e2 98                ror.l    #$1, d0
  005008:  d0 98                add.l    (a0)+, d0
  00500a:  e2 98                ror.l    #$1, d0
  00500c:  d0 98                add.l    (a0)+, d0
  00500e:  e2 98                ror.l    #$1, d0
  005010:  d0 98                add.l    (a0)+, d0
  005012:  e2 98                ror.l    #$1, d0
  005014:  d0 98                add.l    (a0)+, d0
  005016:  e2 98                ror.l    #$1, d0
  005018:  d0 98                add.l    (a0)+, d0
  00501a:  e2 98                ror.l    #$1, d0
  00501c:  d0 98                add.l    (a0)+, d0
  00501e:  e2 98                ror.l    #$1, d0
  005020:  d0 98                add.l    (a0)+, d0
  005022:  e2 98                ror.l    #$1, d0
  005024:  48 40                swap     d0
  005026:  32 00                move.w   d0, d1
  005028:  48 40                swap     d0
  00502a:  d0 41                add.w    d1, d0
  00502c:  48 c0                ext.l    d0
  00502e:  4e 75                rts
* WidthTableCheckSum  -  System 7 $7EF8 (identical bytes, S6 MacsBug name).
WidthTableCheckSum:
  005030:  d0 98                add.l    (a0)+, d0
  005032:  e2 98                ror.l    #$1, d0
  005034:  d0 98                add.l    (a0)+, d0
  005036:  e2 98                ror.l    #$1, d0
  005038:  d0 98                add.l    (a0)+, d0
  00503a:  e2 98                ror.l    #$1, d0
  00503c:  d0 98                add.l    (a0)+, d0
  00503e:  e2 98                ror.l    #$1, d0
  005040:  d0 98                add.l    (a0)+, d0
  005042:  e2 98                ror.l    #$1, d0
  005044:  d0 98                add.l    (a0)+, d0
  005046:  e2 98                ror.l    #$1, d0
  005048:  d0 98                add.l    (a0)+, d0
  00504a:  e2 98                ror.l    #$1, d0
  00504c:  d0 98                add.l    (a0)+, d0
  00504e:  e2 98                ror.l    #$1, d0
  005050:  d0 98                add.l    (a0)+, d0
  005052:  e2 98                ror.l    #$1, d0
  005054:  d0 98                add.l    (a0)+, d0
  005056:  e2 98                ror.l    #$1, d0
  005058:  d0 98                add.l    (a0)+, d0
  00505a:  e2 98                ror.l    #$1, d0
  00505c:  d0 98                add.l    (a0)+, d0
  00505e:  e2 98                ror.l    #$1, d0
  005060:  d0 98                add.l    (a0)+, d0
  005062:  e2 98                ror.l    #$1, d0
  005064:  d0 98                add.l    (a0)+, d0
  005066:  e2 98                ror.l    #$1, d0
  005068:  d0 98                add.l    (a0)+, d0
  00506a:  e2 98                ror.l    #$1, d0
  00506c:  d0 98                add.l    (a0)+, d0
  00506e:  e2 98                ror.l    #$1, d0
  005070:  51 c9 ff be          dbra     d1, $5030  ; -> WidthTableCheckSum
  005074:  4e 75                rts
  005076:  57 69 64 74 68 54 61 62 dc.b     $57, $69, $64, $74, $68, $54, $61, $62  ; WidthTab
  00507e:  6c 65 43 68 65 63 6b 53 dc.b     $6C, $65, $43, $68, $65, $63, $6B, $53  ; leCheckS
  005086:  75 6d                dc.b     $75, $6D  ; um
* GA_Translate24To32  -  System 7 $7F50 (same trap slot $644, code r=0.00).
* S7: Patch #0 replaces _Translate24To32 ($A091); no EngineDispatch command found
GA_Translate24To32:
  005088:  2f 08                move.l   a0, -(a7)
  00508a:  2f 00                move.l   d0, -(a7)
  00508c:  20 78 0d 62          movea.l  $d62.w, a0
  005090:  20 10                move.l   (a0), d0
  005092:  a0 55                dc.w     $a055
  005094:  20 40                movea.l  d0, a0
  005096:  20 68 00 12          movea.l  $12(a0), a0
  00509a:  20 50                movea.l  (a0), a0
  00509c:  20 1f                move.l   (a7)+, d0
  00509e:  b0 88                cmp.l    a0, d0
  0050a0:  67 10                beq.b    $50b2  ; -> L50b2
L50a2:
  0050a2:  20 78 08 88          movea.l  $888.w, a0
  0050a6:  2f 28 00 14          move.l   $14(a0), -(a7)
  0050aa:  20 6f 00 04          movea.l  $4(a7), a0
  0050ae:  2e 9f                move.l   (a7)+, (a7)
  0050b0:  4e 75                rts
L50b2:
  0050b2:  48 e7 80 70          movem.l  d0/a1-a3, -(a7)
  0050b6:  20 78 08 88          movea.l  $888.w, a0
  0050ba:  22 6f 00 14          movea.l  $14(a7), a1
  0050be:  0c 51 22 40          cmpi.w   #$2240, (a1)
  0050c2:  67 54                beq.b    $5118  ; -> L5118
  0050c4:  0c 51 28 40          cmpi.w   #$2840, (a1)
  0050c8:  66 64                bne.b    $512e  ; -> L512e
  0050ca:  22 68 00 10          movea.l  $10(a0), a1
  0050ce:  45 f8 08 3c          lea.l    $83c.w, a2
  0050d2:  26 78 08 9c          movea.l  $89c.w, a3
  0050d6:  26 53                movea.l  (a3), a3
  0050d8:  d6 fc 00 22          adda.w   #$22, a3
  0050dc:  30 29 00 04          move.w   $4(a1), d0
  0050e0:  90 53                sub.w    (a3), d0
  0050e2:  b0 5a                cmp.w    (a2)+, d0
  0050e4:  6d 2a                blt.b    $5110  ; -> L5110
  0050e6:  30 29 00 06          move.w   $6(a1), d0
  0050ea:  90 6b 00 02          sub.w    $2(a3), d0
  0050ee:  b0 5a                cmp.w    (a2)+, d0
  0050f0:  6f 1e                ble.b    $5110  ; -> L5110
  0050f2:  30 11                move.w   (a1), d0
  0050f4:  90 53                sub.w    (a3), d0
  0050f6:  b0 5a                cmp.w    (a2)+, d0
  0050f8:  6c 16                bge.b    $5110  ; -> L5110
  0050fa:  30 29 00 02          move.w   $2(a1), d0
  0050fe:  90 6b 00 02          sub.w    $2(a3), d0
  005102:  b0 52                cmp.w    (a2), d0
  005104:  6c 0a                bge.b    $5110  ; -> L5110
  005106:  de fc 00 18          adda.w   #$18, a7
  00510a:  4c df 7f ff          movem.l  (a7)+, d0-d7/a0-a6
  00510e:  4e 75                rts
L5110:
  005110:  22 68 00 28          movea.l  $28(a0), a1
  005114:  42 91                clr.l    (a1)
  005116:  60 16                bra.b    $512e  ; -> L512e
L5118:
  005118:  24 40                movea.l  d0, a2
  00511a:  22 68 00 28          movea.l  $28(a0), a1
  00511e:  20 11                move.l   (a1), d0
  005120:  67 0c                beq.b    $512e  ; -> L512e
  005122:  26 68 00 2c          movea.l  $2c(a0), a3
L5126:
  005126:  24 db                move.l   (a3)+, (a2)+
  005128:  51 c8 ff fc          dbra     d0, $5126  ; -> L5126
  00512c:  42 91                clr.l    (a1)
L512e:
  00512e:  4c df 0e 01          movem.l  (a7)+, d0/a1-a3
  005132:  60 00 ff 6e          bra.w    $50a2  ; -> L50a2
  005136:  47 41 5f 54 72 61 6e 73 dc.b     $47, $41, $5F, $54, $72, $61, $6E, $73  ; GA_Trans
  00513e:  6c 61 74 65 32 34 54 6f dc.b     $6C, $61, $74, $65, $32, $34, $54, $6F  ; late24To
  005146:  33 32                dc.b     $33, $32  ; 32
* GA_TrapAB27  -  System 7 $32BC (same trap slot $1A9C, code r=0.71).
* S7: Patch #6 replaces trap $AB27; card commands: $0D $15 $38
GA_TrapAB27:
  005148:  4e 56 ff dc          link.w   a6, #$ffdc
  00514c:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  005150:  3c 2e 00 08          move.w   $8(a6), d6
  005154:  3e 2e 00 1a          move.w   $1a(a6), d7
  005158:  42 6e ff ee          clr.w    -$12(a6)
  00515c:  42 6e ff ec          clr.w    -$14(a6)
  005160:  42 6e ff ea          clr.w    -$16(a6)
  005164:  42 6e ff e8          clr.w    -$18(a6)
  005168:  20 38 08 88          move.l   $888.w, d0
  00516c:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  005172:  20 40                movea.l  d0, a0
  005174:  20 50                movea.l  (a0), a0
  005176:  2d 50 ff fc          move.l   (a0), -$4(a6)
  00517a:  20 38 08 88          move.l   $888.w, d0
  00517e:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  005184:  20 40                movea.l  d0, a0
  005186:  20 50                movea.l  (a0), a0
  005188:  20 50                movea.l  (a0), a0
  00518a:  26 68 02 14          movea.l  $214(a0), a3
  00518e:  20 0b                move.l   a3, d0
  005190:  67 00 01 2a          beq.w    $52bc  ; -> L52bc
  005194:  4a ae 00 16          tst.l    $16(a6)
  005198:  66 00 01 22          bne.w    $52bc  ; -> L52bc
  00519c:  20 53                movea.l  (a3), a0
  00519e:  2d 68 00 08 ff e4    move.l   $8(a0), -$1c(a6)
  0051a4:  70 27                moveq    #$27, d0
  0051a6:  c0 a8 00 08          and.l    $8(a0), d0
  0051aa:  72 27                moveq    #$27, d1
  0051ac:  b2 80                cmp.l    d0, d1
  0051ae:  66 00 01 0c          bne.w    $52bc  ; -> L52bc
  0051b2:  20 3c 00 00 06 00    move.l   #$600, d0
  0051b8:  c0 ae ff e4          and.l    -$1c(a6), d0
  0051bc:  66 00 00 fe          bne.w    $52bc  ; -> L52bc
  0051c0:  20 53                movea.l  (a3), a0
  0051c2:  20 68 00 0c          movea.l  $c(a0), a0
  0051c6:  41 e8 00 58          lea.l    $58(a0), a0
  0051ca:  2d 48 ff e0          move.l   a0, -$20(a6)
  0051ce:  48 c6                ext.l    d6
  0051d0:  20 06                move.l   d6, d0
  0051d2:  e0 80                asr.l    #$8, d0
  0051d4:  20 6e ff fc          movea.l  -$4(a6), a0
  0051d8:  72 00                moveq    #$0, d1
  0051da:  12 28 02 57          move.b   $257(a0), d1
  0051de:  82 80                or.l     d0, d1
  0051e0:  2f 01                move.l   d1, -(a7)
  0051e2:  2f 2e 00 0a          move.l   $a(a6), -(a7)
  0051e6:  2f 2e 00 0e          move.l   $e(a6), -(a7)
  0051ea:  2f 2e 00 12          move.l   $12(a6), -(a7)
  0051ee:  48 c7                ext.l    d7
  0051f0:  2f 07                move.l   d7, -(a7)
  0051f2:  2f 2e 00 1c          move.l   $1c(a6), -(a7)
  0051f6:  2f 2e 00 20          move.l   $20(a6), -(a7)
  0051fa:  2f 2e 00 24          move.l   $24(a6), -(a7)
  0051fe:  2f 2e 00 28          move.l   $28(a6), -(a7)
  005202:  2f 2e 00 2c          move.l   $2c(a6), -(a7)
  005206:  2f 2e 00 30          move.l   $30(a6), -(a7)
  00520a:  2f 2e ff e0          move.l   -$20(a6), -(a7)
  00520e:  4e ba f1 74          jsr      $4384(pc)  ; -> s7_sub_8262
  005212:  2d 6e ff e0 ff dc    move.l   -$20(a6), -$24(a6)
  005218:  70 01                moveq    #$1, d0
  00521a:  2f 00                move.l   d0, -(a7)
  00521c:  48 6e ff dc          pea.l    -$24(a6)
  005220:  72 15                moveq    #$15, d1
  005222:  2f 01                move.l   d1, -(a7)
  005224:  4e ba 0f fe          jsr      $6224(pc)  ; -> EngineDispatch
  005228:  72 01                moveq    #$1, d1
  00522a:  b2 80                cmp.l    d0, d1
  00522c:  4f ef 00 3c          lea.l    $3c(a7), a7
  005230:  66 0a                bne.b    $523c  ; -> L523c
  005232:  00 38 00 80 09 38    ori.b    #$80, $938.w
  005238:  60 00 01 1e          bra.w    $5358  ; -> L5358
L523c:
  00523c:  20 38 08 88          move.l   $888.w, d0
  005240:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  005246:  28 40                movea.l  d0, a4
  005248:  4a ac 00 18          tst.l    $18(a4)
  00524c:  67 6e                beq.b    $52bc  ; -> L52bc
  00524e:  20 6c 00 1c          movea.l  $1c(a4), a0
  005252:  30 10                move.w   (a0), d0
  005254:  48 c0                ext.l    d0
  005256:  66 24                bne.b    $527c  ; -> L527c
  005258:  20 6c 00 1c          movea.l  $1c(a4), a0
  00525c:  30 28 00 02          move.w   $2(a0), d0
  005260:  48 c0                ext.l    d0
  005262:  66 18                bne.b    $527c  ; -> L527c
  005264:  20 6c 00 1c          movea.l  $1c(a4), a0
  005268:  30 28 00 04          move.w   $4(a0), d0
  00526c:  48 c0                ext.l    d0
  00526e:  66 0c                bne.b    $527c  ; -> L527c
  005270:  20 6c 00 1c          movea.l  $1c(a4), a0
  005274:  30 28 00 06          move.w   $6(a0), d0
  005278:  48 c0                ext.l    d0
  00527a:  67 2e                beq.b    $52aa  ; -> L52aa
L527c:
  00527c:  20 6c 00 1c          movea.l  $1c(a4), a0
  005280:  3f 28 00 02          move.w   $2(a0), -(a7)
  005284:  20 6c 00 1c          movea.l  $1c(a4), a0
  005288:  3f 10                move.w   (a0), -(a7)
  00528a:  20 6c 00 1c          movea.l  $1c(a4), a0
  00528e:  3f 28 00 06          move.w   $6(a0), -(a7)
  005292:  20 6c 00 1c          movea.l  $1c(a4), a0
  005296:  3f 28 00 04          move.w   $4(a0), -(a7)
  00529a:  48 78 08 08          pea.l    $808.w
  00529e:  4e ba 33 fc          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0052a2:  58 8f                addq.l   #$4, a7
  0052a4:  2f 00                move.l   d0, -(a7)
  0052a6:  20 5f                movea.l  (a7)+, a0
  0052a8:  4e 90                jsr      (a0)
L52aa:
  0052aa:  20 6c 00 1c          movea.l  $1c(a4), a0
  0052ae:  43 ee ff e8          lea.l    -$18(a6), a1
  0052b2:  20 d9                move.l   (a1)+, (a0)+
  0052b4:  20 d9                move.l   (a1)+, (a0)+
  0052b6:  70 00                moveq    #$0, d0
  0052b8:  29 40 00 18          move.l   d0, $18(a4)
L52bc:
  0052bc:  48 6e ff f8          pea.l    -$8(a6)
  0052c0:  48 6e ff f0          pea.l    -$10(a6)
  0052c4:  2f 2e 00 30          move.l   $30(a6), -(a7)
  0052c8:  4e ba f5 78          jsr      $4842(pc)  ; -> s7_sub_86d6
  0052cc:  18 00                move.b   d0, d4
  0052ce:  48 6e ff fa          pea.l    -$6(a6)
  0052d2:  48 6e ff f4          pea.l    -$c(a6)
  0052d6:  2f 2e 00 28          move.l   $28(a6), -(a7)
  0052da:  4e ba f5 66          jsr      $4842(pc)  ; -> s7_sub_86d6
  0052de:  1a 00                move.b   d0, d5
  0052e0:  2f 2e 00 30          move.l   $30(a6), -(a7)
  0052e4:  2f 2e 00 2c          move.l   $2c(a6), -(a7)
  0052e8:  2f 2e 00 28          move.l   $28(a6), -(a7)
  0052ec:  2f 2e 00 24          move.l   $24(a6), -(a7)
  0052f0:  2f 2e 00 20          move.l   $20(a6), -(a7)
  0052f4:  2f 2e 00 1c          move.l   $1c(a6), -(a7)
  0052f8:  3f 07                move.w   d7, -(a7)
  0052fa:  2f 2e 00 16          move.l   $16(a6), -(a7)
  0052fe:  2f 2e 00 12          move.l   $12(a6), -(a7)
  005302:  2f 2e 00 0e          move.l   $e(a6), -(a7)
  005306:  2f 2e 00 0a          move.l   $a(a6), -(a7)
  00530a:  3f 06                move.w   d6, -(a7)
  00530c:  48 78 1a 9c          pea.l    $1a9c.w
  005310:  4e ba 33 8a          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005314:  58 8f                addq.l   #$4, a7
  005316:  2f 00                move.l   d0, -(a7)
  005318:  20 5f                movea.l  (a7)+, a0
  00531a:  4e 90                jsr      (a0)
  00531c:  4a 04                tst.b    d4
  00531e:  4f ef 00 18          lea.l    $18(a7), a7
  005322:  67 18                beq.b    $533c  ; -> L533c
  005324:  30 2e ff f8          move.w   -$8(a6), d0
  005328:  48 c0                ext.l    d0
  00532a:  2f 00                move.l   d0, -(a7)
  00532c:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  005330:  2f 2e 00 30          move.l   $30(a6), -(a7)
  005334:  4e ba f5 c8          jsr      $48fe(pc)  ; -> s7_sub_879a
  005338:  4f ef 00 0c          lea.l    $c(a7), a7
L533c:
  00533c:  4a 05                tst.b    d5
  00533e:  67 18                beq.b    $5358  ; -> L5358
  005340:  30 2e ff fa          move.w   -$6(a6), d0
  005344:  48 c0                ext.l    d0
  005346:  2f 00                move.l   d0, -(a7)
  005348:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  00534c:  2f 2e 00 28          move.l   $28(a6), -(a7)
  005350:  4e ba f5 ac          jsr      $48fe(pc)  ; -> s7_sub_879a
  005354:  4f ef 00 0c          lea.l    $c(a7), a7
L5358:
  005358:  4c ee 18 f0 ff c4    movem.l  -$3c(a6), d4-d7/a3-a4
  00535e:  4e 5e                unlk     a6
  005360:  4e 74 00 2c          rtd      #$2c
* GA_StdRgn  -  System 7 $358C (same trap slot $1144, code r=0.96).
* S7: Patch #24 replaces _StdRgn ($A8D1); card commands: $0D $18 $26 $38
GA_StdRgn:
  005364:  4e 56 ff f2          link.w   a6, #$fff2
  005368:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  00536c:  28 6e 00 08          movea.l  $8(a6), a4
  005370:  1e 2e 00 0c          move.b   $c(a6), d7
  005374:  4e ba be ba          jsr      $1230(pc)  ; -> GetA5
  005378:  20 40                movea.l  d0, a0
  00537a:  20 50                movea.l  (a0), a0
  00537c:  26 50                movea.l  (a0), a3
  00537e:  42 06                clr.b    d6
  005380:  3a 2b 00 42          move.w   $42(a3), d5
  005384:  30 05                move.w   d5, d0
  005386:  48 c0                ext.l    d0
  005388:  6d 00 00 9a          blt.w    $5424  ; -> L5424
  00538c:  70 00                moveq    #$0, d0
  00538e:  10 07                move.b   d7, d0
  005390:  2d 40 ff f2          move.l   d0, -$e(a6)
  005394:  2d 4c ff f6          move.l   a4, -$a(a6)
  005398:  70 02                moveq    #$2, d0
  00539a:  2f 00                move.l   d0, -(a7)
  00539c:  48 6e ff f2          pea.l    -$e(a6)
  0053a0:  72 18                moveq    #$18, d1
  0053a2:  2f 01                move.l   d1, -(a7)
  0053a4:  4e ba 0e 7e          jsr      $6224(pc)  ; -> EngineDispatch
  0053a8:  28 00                move.l   d0, d4
  0053aa:  70 01                moveq    #$1, d0
  0053ac:  b0 84                cmp.l    d4, d0
  0053ae:  4f ef 00 0c          lea.l    $c(a7), a7
  0053b2:  67 00 00 84          beq.w    $5438  ; -> L5438
  0053b6:  48 6e ff fe          pea.l    -$2(a6)
  0053ba:  48 6e ff fa          pea.l    -$6(a6)
  0053be:  48 6b 00 02          pea.l    $2(a3)
  0053c2:  4e ba f4 7e          jsr      $4842(pc)  ; -> s7_sub_86d6
  0053c6:  1c 00                move.b   d0, d6
  0053c8:  70 02                moveq    #$2, d0
  0053ca:  b0 84                cmp.l    d4, d0
  0053cc:  4f ef 00 0c          lea.l    $c(a7), a7
  0053d0:  66 20                bne.b    $53f2  ; -> L53f2
  0053d2:  37 7c ff ff 00 42    move.w   #$ffff, $42(a3)
  0053d8:  1f 07                move.b   d7, -(a7)
  0053da:  2f 0c                move.l   a4, -(a7)
  0053dc:  48 78 11 44          pea.l    $1144.w
  0053e0:  4e ba 32 ba          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0053e4:  58 8f                addq.l   #$4, a7
  0053e6:  2f 00                move.l   d0, -(a7)
  0053e8:  20 5f                movea.l  (a7)+, a0
  0053ea:  4e 90                jsr      (a0)
  0053ec:  37 45 00 42          move.w   d5, $42(a3)
  0053f0:  60 14                bra.b    $5406  ; -> L5406
L53f2:
  0053f2:  1f 07                move.b   d7, -(a7)
  0053f4:  2f 0c                move.l   a4, -(a7)
  0053f6:  48 78 11 44          pea.l    $1144.w
  0053fa:  4e ba 32 a0          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0053fe:  58 8f                addq.l   #$4, a7
  005400:  2f 00                move.l   d0, -(a7)
  005402:  20 5f                movea.l  (a7)+, a0
  005404:  4e 90                jsr      (a0)
L5406:
  005406:  4a 06                tst.b    d6
  005408:  67 2e                beq.b    $5438  ; -> L5438
  00540a:  30 2e ff fe          move.w   -$2(a6), d0
  00540e:  48 c0                ext.l    d0
  005410:  2f 00                move.l   d0, -(a7)
  005412:  2f 2e ff fa          move.l   -$6(a6), -(a7)
  005416:  48 6b 00 02          pea.l    $2(a3)
  00541a:  4e ba f4 e2          jsr      $48fe(pc)  ; -> s7_sub_879a
  00541e:  4f ef 00 0c          lea.l    $c(a7), a7
  005422:  60 14                bra.b    $5438  ; -> L5438
L5424:
  005424:  1f 07                move.b   d7, -(a7)
  005426:  2f 0c                move.l   a4, -(a7)
  005428:  48 78 11 44          pea.l    $1144.w
  00542c:  4e ba 32 6e          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005430:  58 8f                addq.l   #$4, a7
  005432:  2f 00                move.l   d0, -(a7)
  005434:  20 5f                movea.l  (a7)+, a0
  005436:  4e 90                jsr      (a0)
L5438:
  005438:  4c ee 18 f0 ff da    movem.l  -$26(a6), d4-d7/a3-a4
  00543e:  4e 5e                unlk     a6
  005440:  4e 74 00 06          rtd      #$6
* GA_StdLine  -  System 7 $3682 (same trap slot $1040, code r=0.96).
* S7: Patch #3 replaces _StdLine ($A890); card commands: $0D $20 $26 $38
GA_StdLine:
  005444:  4e 56 ff f6          link.w   a6, #$fff6
  005448:  48 e7 07 10          movem.l  d5-d7/a3, -(a7)
  00544c:  4e ba bd e2          jsr      $1230(pc)  ; -> GetA5
  005450:  20 40                movea.l  d0, a0
  005452:  20 50                movea.l  (a0), a0
  005454:  26 50                movea.l  (a0), a3
  005456:  42 07                clr.b    d7
  005458:  3c 2b 00 42          move.w   $42(a3), d6
  00545c:  30 06                move.w   d6, d0
  00545e:  48 c0                ext.l    d0
  005460:  6d 00 00 96          blt.w    $54f8  ; -> L54f8
  005464:  41 ee 00 08          lea.l    $8(a6), a0
  005468:  2d 48 ff f6          move.l   a0, -$a(a6)
  00546c:  70 01                moveq    #$1, d0
  00546e:  2f 00                move.l   d0, -(a7)
  005470:  48 6e ff f6          pea.l    -$a(a6)
  005474:  72 20                moveq    #$20, d1
  005476:  2f 01                move.l   d1, -(a7)
  005478:  4e ba 0d aa          jsr      $6224(pc)  ; -> EngineDispatch
  00547c:  2a 00                move.l   d0, d5
  00547e:  70 01                moveq    #$1, d0
  005480:  b0 85                cmp.l    d5, d0
  005482:  4f ef 00 0c          lea.l    $c(a7), a7
  005486:  67 00 00 84          beq.w    $550c  ; -> L550c
  00548a:  48 6e ff fe          pea.l    -$2(a6)
  00548e:  48 6e ff fa          pea.l    -$6(a6)
  005492:  48 6b 00 02          pea.l    $2(a3)
  005496:  4e ba f3 aa          jsr      $4842(pc)  ; -> s7_sub_86d6
  00549a:  1e 00                move.b   d0, d7
  00549c:  70 02                moveq    #$2, d0
  00549e:  b0 85                cmp.l    d5, d0
  0054a0:  4f ef 00 0c          lea.l    $c(a7), a7
  0054a4:  66 20                bne.b    $54c6  ; -> L54c6
  0054a6:  37 7c ff ff 00 42    move.w   #$ffff, $42(a3)
  0054ac:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0054b0:  48 78 10 40          pea.l    $1040.w
  0054b4:  4e ba 31 e6          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0054b8:  58 8f                addq.l   #$4, a7
  0054ba:  2f 00                move.l   d0, -(a7)
  0054bc:  20 5f                movea.l  (a7)+, a0
  0054be:  4e 90                jsr      (a0)
  0054c0:  37 46 00 42          move.w   d6, $42(a3)
  0054c4:  60 14                bra.b    $54da  ; -> L54da
L54c6:
  0054c6:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0054ca:  48 78 10 40          pea.l    $1040.w
  0054ce:  4e ba 31 cc          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0054d2:  58 8f                addq.l   #$4, a7
  0054d4:  2f 00                move.l   d0, -(a7)
  0054d6:  20 5f                movea.l  (a7)+, a0
  0054d8:  4e 90                jsr      (a0)
L54da:
  0054da:  4a 07                tst.b    d7
  0054dc:  67 2e                beq.b    $550c  ; -> L550c
  0054de:  30 2e ff fe          move.w   -$2(a6), d0
  0054e2:  48 c0                ext.l    d0
  0054e4:  2f 00                move.l   d0, -(a7)
  0054e6:  2f 2e ff fa          move.l   -$6(a6), -(a7)
  0054ea:  48 6b 00 02          pea.l    $2(a3)
  0054ee:  4e ba f4 0e          jsr      $48fe(pc)  ; -> s7_sub_879a
  0054f2:  4f ef 00 0c          lea.l    $c(a7), a7
  0054f6:  60 14                bra.b    $550c  ; -> L550c
L54f8:
  0054f8:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0054fc:  48 78 10 40          pea.l    $1040.w
  005500:  4e ba 31 9a          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005504:  58 8f                addq.l   #$4, a7
  005506:  2f 00                move.l   d0, -(a7)
  005508:  20 5f                movea.l  (a7)+, a0
  00550a:  4e 90                jsr      (a0)
L550c:
  00550c:  4c ee 08 e0 ff e6    movem.l  -$1a(a6), d5-d7/a3
  005512:  4e 5e                unlk     a6
  005514:  4e 74 00 04          rtd      #$4
* GA_StdPoly  -  System 7 $376C (same trap slot $1114, code r=0.95).
* S7: Patch #23 replaces _StdPoly ($A8C5); card commands: $0D $26 $31 $38
GA_StdPoly:
  005518:  4e 56 ff f2          link.w   a6, #$fff2
  00551c:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  005520:  28 6e 00 08          movea.l  $8(a6), a4
  005524:  1e 2e 00 0c          move.b   $c(a6), d7
  005528:  4e ba bd 06          jsr      $1230(pc)  ; -> GetA5
  00552c:  20 40                movea.l  d0, a0
  00552e:  20 50                movea.l  (a0), a0
  005530:  26 50                movea.l  (a0), a3
  005532:  42 05                clr.b    d5
  005534:  3c 2b 00 42          move.w   $42(a3), d6
  005538:  30 06                move.w   d6, d0
  00553a:  48 c0                ext.l    d0
  00553c:  6d 00 00 a4          blt.w    $55e2  ; -> L55e2
  005540:  70 00                moveq    #$0, d0
  005542:  10 07                move.b   d7, d0
  005544:  2d 40 ff f2          move.l   d0, -$e(a6)
  005548:  2d 4c ff f6          move.l   a4, -$a(a6)
  00554c:  70 02                moveq    #$2, d0
  00554e:  2f 00                move.l   d0, -(a7)
  005550:  48 6e ff f2          pea.l    -$e(a6)
  005554:  72 31                moveq    #$31, d1
  005556:  2f 01                move.l   d1, -(a7)
  005558:  4e ba 0c ca          jsr      $6224(pc)  ; -> EngineDispatch
  00555c:  28 00                move.l   d0, d4
  00555e:  70 01                moveq    #$1, d0
  005560:  b0 84                cmp.l    d4, d0
  005562:  4f ef 00 0c          lea.l    $c(a7), a7
  005566:  67 00 00 8e          beq.w    $55f6  ; -> L55f6
  00556a:  3c 2b 00 42          move.w   $42(a3), d6
  00556e:  30 06                move.w   d6, d0
  005570:  48 c0                ext.l    d0
  005572:  6d 16                blt.b    $558a  ; -> L558a
  005574:  48 6e ff fe          pea.l    -$2(a6)
  005578:  48 6e ff fa          pea.l    -$6(a6)
  00557c:  48 6b 00 02          pea.l    $2(a3)
  005580:  4e ba f2 c0          jsr      $4842(pc)  ; -> s7_sub_86d6
  005584:  1a 00                move.b   d0, d5
  005586:  4f ef 00 0c          lea.l    $c(a7), a7
L558a:
  00558a:  70 02                moveq    #$2, d0
  00558c:  b0 84                cmp.l    d4, d0
  00558e:  66 20                bne.b    $55b0  ; -> L55b0
  005590:  37 7c ff ff 00 42    move.w   #$ffff, $42(a3)
  005596:  1f 07                move.b   d7, -(a7)
  005598:  2f 0c                move.l   a4, -(a7)
  00559a:  48 78 11 14          pea.l    $1114.w
  00559e:  4e ba 30 fc          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0055a2:  58 8f                addq.l   #$4, a7
  0055a4:  2f 00                move.l   d0, -(a7)
  0055a6:  20 5f                movea.l  (a7)+, a0
  0055a8:  4e 90                jsr      (a0)
  0055aa:  37 46 00 42          move.w   d6, $42(a3)
  0055ae:  60 14                bra.b    $55c4  ; -> L55c4
L55b0:
  0055b0:  1f 07                move.b   d7, -(a7)
  0055b2:  2f 0c                move.l   a4, -(a7)
  0055b4:  48 78 11 14          pea.l    $1114.w
  0055b8:  4e ba 30 e2          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0055bc:  58 8f                addq.l   #$4, a7
  0055be:  2f 00                move.l   d0, -(a7)
  0055c0:  20 5f                movea.l  (a7)+, a0
  0055c2:  4e 90                jsr      (a0)
L55c4:
  0055c4:  4a 05                tst.b    d5
  0055c6:  67 2e                beq.b    $55f6  ; -> L55f6
  0055c8:  30 2e ff fe          move.w   -$2(a6), d0
  0055cc:  48 c0                ext.l    d0
  0055ce:  2f 00                move.l   d0, -(a7)
  0055d0:  2f 2e ff fa          move.l   -$6(a6), -(a7)
  0055d4:  48 6b 00 02          pea.l    $2(a3)
  0055d8:  4e ba f3 24          jsr      $48fe(pc)  ; -> s7_sub_879a
  0055dc:  4f ef 00 0c          lea.l    $c(a7), a7
  0055e0:  60 14                bra.b    $55f6  ; -> L55f6
L55e2:
  0055e2:  1f 07                move.b   d7, -(a7)
  0055e4:  2f 0c                move.l   a4, -(a7)
  0055e6:  48 78 11 14          pea.l    $1114.w
  0055ea:  4e ba 30 b0          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0055ee:  58 8f                addq.l   #$4, a7
  0055f0:  2f 00                move.l   d0, -(a7)
  0055f2:  20 5f                movea.l  (a7)+, a0
  0055f4:  4e 90                jsr      (a0)
L55f6:
  0055f6:  4c ee 18 f0 ff da    movem.l  -$26(a6), d4-d7/a3-a4
  0055fc:  4e 5e                unlk     a6
  0055fe:  4e 74 00 06          rtd      #$6
* GA_StdText  -  System 7 $3A9C (same trap slot $1008, code r=0.50).
* S7: Patch #5 replaces _StdText ($A882); card commands: $0D $21 $26 $38
GA_StdText:
  005602:  4e 56 ff ea          link.w   a6, #$ffea
  005606:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  00560a:  3e 2e 00 14          move.w   $14(a6), d7
  00560e:  47 ee ff ea          lea.l    -$16(a6), a3
  005612:  4e ba bc 1c          jsr      $1230(pc)  ; -> GetA5
  005616:  20 40                movea.l  d0, a0
  005618:  20 50                movea.l  (a0), a0
  00561a:  28 50                movea.l  (a0), a4
  00561c:  42 06                clr.b    d6
  00561e:  48 c7                ext.l    d7
  005620:  4a 87                tst.l    d7
  005622:  6f 00 00 e0          ble.w    $5704  ; -> L5704
  005626:  3a 2c 00 42          move.w   $42(a4), d5
  00562a:  30 05                move.w   d5, d0
  00562c:  48 c0                ext.l    d0
  00562e:  6d 00 00 b6          blt.w    $56e6  ; -> L56e6
  005632:  48 c7                ext.l    d7
  005634:  26 c7                move.l   d7, (a3)+
  005636:  26 ee 00 10          move.l   $10(a6), (a3)+
  00563a:  41 ee 00 0c          lea.l    $c(a6), a0
  00563e:  26 c8                move.l   a0, (a3)+
  005640:  41 ee 00 08          lea.l    $8(a6), a0
  005644:  26 88                move.l   a0, (a3)
  005646:  70 04                moveq    #$4, d0
  005648:  2f 00                move.l   d0, -(a7)
  00564a:  48 6e ff ea          pea.l    -$16(a6)
  00564e:  72 21                moveq    #$21, d1
  005650:  2f 01                move.l   d1, -(a7)
  005652:  4e ba 0b d0          jsr      $6224(pc)  ; -> EngineDispatch
  005656:  28 00                move.l   d0, d4
  005658:  70 01                moveq    #$1, d0
  00565a:  b0 84                cmp.l    d4, d0
  00565c:  4f ef 00 0c          lea.l    $c(a7), a7
  005660:  67 00 00 a2          beq.w    $5704  ; -> L5704
  005664:  48 6e ff fe          pea.l    -$2(a6)
  005668:  48 6e ff fa          pea.l    -$6(a6)
  00566c:  48 6c 00 02          pea.l    $2(a4)
  005670:  4e ba f1 d0          jsr      $4842(pc)  ; -> s7_sub_86d6
  005674:  1c 00                move.b   d0, d6
  005676:  70 02                moveq    #$2, d0
  005678:  b0 84                cmp.l    d4, d0
  00567a:  4f ef 00 0c          lea.l    $c(a7), a7
  00567e:  66 2a                bne.b    $56aa  ; -> L56aa
  005680:  39 7c ff ff 00 42    move.w   #$ffff, $42(a4)
  005686:  3f 07                move.w   d7, -(a7)
  005688:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00568c:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  005690:  2f 2e 00 08          move.l   $8(a6), -(a7)
  005694:  48 78 10 08          pea.l    $1008.w
  005698:  4e ba 30 02          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00569c:  58 8f                addq.l   #$4, a7
  00569e:  2f 00                move.l   d0, -(a7)
  0056a0:  20 5f                movea.l  (a7)+, a0
  0056a2:  4e 90                jsr      (a0)
  0056a4:  39 45 00 42          move.w   d5, $42(a4)
  0056a8:  60 1e                bra.b    $56c8  ; -> L56c8
L56aa:
  0056aa:  3f 07                move.w   d7, -(a7)
  0056ac:  2f 2e 00 10          move.l   $10(a6), -(a7)
  0056b0:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  0056b4:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0056b8:  48 78 10 08          pea.l    $1008.w
  0056bc:  4e ba 2f de          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0056c0:  58 8f                addq.l   #$4, a7
  0056c2:  2f 00                move.l   d0, -(a7)
  0056c4:  20 5f                movea.l  (a7)+, a0
  0056c6:  4e 90                jsr      (a0)
L56c8:
  0056c8:  4a 06                tst.b    d6
  0056ca:  67 38                beq.b    $5704  ; -> L5704
  0056cc:  30 2e ff fe          move.w   -$2(a6), d0
  0056d0:  48 c0                ext.l    d0
  0056d2:  2f 00                move.l   d0, -(a7)
  0056d4:  2f 2e ff fa          move.l   -$6(a6), -(a7)
  0056d8:  48 6c 00 02          pea.l    $2(a4)
  0056dc:  4e ba f2 20          jsr      $48fe(pc)  ; -> s7_sub_879a
  0056e0:  4f ef 00 0c          lea.l    $c(a7), a7
  0056e4:  60 1e                bra.b    $5704  ; -> L5704
L56e6:
  0056e6:  3f 07                move.w   d7, -(a7)
  0056e8:  2f 2e 00 10          move.l   $10(a6), -(a7)
  0056ec:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  0056f0:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0056f4:  48 78 10 08          pea.l    $1008.w
  0056f8:  4e ba 2f a2          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0056fc:  58 8f                addq.l   #$4, a7
  0056fe:  2f 00                move.l   d0, -(a7)
  005700:  20 5f                movea.l  (a7)+, a0
  005702:  4e 90                jsr      (a0)
L5704:
  005704:  4c ee 18 f0 ff d2    movem.l  -$2e(a6), d4-d7/a3-a4
  00570a:  4e 5e                unlk     a6
  00570c:  4e 74 00 0e          rtd      #$e
* GA_StdArc  -  System 7 $3DDC (same trap slot $10F4, code r=0.97).
* S7: Patch #4 replaces _StdArc ($A8BD); card commands: $0D $23 $26 $38
GA_StdArc:
  005710:  4e 56 ff e4          link.w   a6, #$ffe4
  005714:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  005718:  3a 2e 00 08          move.w   $8(a6), d5
  00571c:  3c 2e 00 0a          move.w   $a(a6), d6
  005720:  1e 2e 00 10          move.b   $10(a6), d7
  005724:  47 ee ff e4          lea.l    -$1c(a6), a3
  005728:  4e ba bb 06          jsr      $1230(pc)  ; -> GetA5
  00572c:  20 40                movea.l  d0, a0
  00572e:  20 50                movea.l  (a0), a0
  005730:  28 50                movea.l  (a0), a4
  005732:  42 04                clr.b    d4
  005734:  3d 6c 00 42 ff fe    move.w   $42(a4), -$2(a6)
  00573a:  30 2c 00 42          move.w   $42(a4), d0
  00573e:  48 c0                ext.l    d0
  005740:  6d 00 00 b2          blt.w    $57f4  ; -> L57f4
  005744:  70 00                moveq    #$0, d0
  005746:  10 07                move.b   d7, d0
  005748:  26 c0                move.l   d0, (a3)+
  00574a:  26 ee 00 0c          move.l   $c(a6), (a3)+
  00574e:  48 c6                ext.l    d6
  005750:  26 c6                move.l   d6, (a3)+
  005752:  48 c5                ext.l    d5
  005754:  26 85                move.l   d5, (a3)
  005756:  70 04                moveq    #$4, d0
  005758:  2f 00                move.l   d0, -(a7)
  00575a:  48 6e ff e4          pea.l    -$1c(a6)
  00575e:  72 23                moveq    #$23, d1
  005760:  2f 01                move.l   d1, -(a7)
  005762:  4e ba 0a c0          jsr      $6224(pc)  ; -> EngineDispatch
  005766:  2d 40 ff fa          move.l   d0, -$6(a6)
  00576a:  72 01                moveq    #$1, d1
  00576c:  b2 80                cmp.l    d0, d1
  00576e:  4f ef 00 0c          lea.l    $c(a7), a7
  005772:  67 00 00 9a          beq.w    $580e  ; -> L580e
  005776:  48 6e ff f8          pea.l    -$8(a6)
  00577a:  48 6e ff f4          pea.l    -$c(a6)
  00577e:  48 6c 00 02          pea.l    $2(a4)
  005782:  4e ba f0 be          jsr      $4842(pc)  ; -> s7_sub_86d6
  005786:  18 00                move.b   d0, d4
  005788:  70 02                moveq    #$2, d0
  00578a:  b0 ae ff fa          cmp.l    -$6(a6), d0
  00578e:  4f ef 00 0c          lea.l    $c(a7), a7
  005792:  66 28                bne.b    $57bc  ; -> L57bc
  005794:  39 7c ff ff 00 42    move.w   #$ffff, $42(a4)
  00579a:  1f 07                move.b   d7, -(a7)
  00579c:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  0057a0:  3f 06                move.w   d6, -(a7)
  0057a2:  3f 05                move.w   d5, -(a7)
  0057a4:  48 78 10 f4          pea.l    $10f4.w
  0057a8:  4e ba 2e f2          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0057ac:  58 8f                addq.l   #$4, a7
  0057ae:  2f 00                move.l   d0, -(a7)
  0057b0:  20 5f                movea.l  (a7)+, a0
  0057b2:  4e 90                jsr      (a0)
  0057b4:  39 6e ff fe 00 42    move.w   -$2(a6), $42(a4)
  0057ba:  60 1a                bra.b    $57d6  ; -> L57d6
L57bc:
  0057bc:  1f 07                move.b   d7, -(a7)
  0057be:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  0057c2:  3f 06                move.w   d6, -(a7)
  0057c4:  3f 05                move.w   d5, -(a7)
  0057c6:  48 78 10 f4          pea.l    $10f4.w
  0057ca:  4e ba 2e d0          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0057ce:  58 8f                addq.l   #$4, a7
  0057d0:  2f 00                move.l   d0, -(a7)
  0057d2:  20 5f                movea.l  (a7)+, a0
  0057d4:  4e 90                jsr      (a0)
L57d6:
  0057d6:  4a 04                tst.b    d4
  0057d8:  67 34                beq.b    $580e  ; -> L580e
  0057da:  30 2e ff f8          move.w   -$8(a6), d0
  0057de:  48 c0                ext.l    d0
  0057e0:  2f 00                move.l   d0, -(a7)
  0057e2:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  0057e6:  48 6c 00 02          pea.l    $2(a4)
  0057ea:  4e ba f1 12          jsr      $48fe(pc)  ; -> s7_sub_879a
  0057ee:  4f ef 00 0c          lea.l    $c(a7), a7
  0057f2:  60 1a                bra.b    $580e  ; -> L580e
L57f4:
  0057f4:  1f 07                move.b   d7, -(a7)
  0057f6:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  0057fa:  3f 06                move.w   d6, -(a7)
  0057fc:  3f 05                move.w   d5, -(a7)
  0057fe:  48 78 10 f4          pea.l    $10f4.w
  005802:  4e ba 2e 98          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005806:  58 8f                addq.l   #$4, a7
  005808:  2f 00                move.l   d0, -(a7)
  00580a:  20 5f                movea.l  (a7)+, a0
  00580c:  4e 90                jsr      (a0)
L580e:
  00580e:  4c ee 18 f0 ff cc    movem.l  -$34(a6), d4-d7/a3-a4
  005814:  4e 5e                unlk     a6
  005816:  4e 74 00 0a          rtd      #$a
* GA_StdRRect  -  System 7 $3EFA (same trap slot $10BC, code r=0.96).
* S7: Patch #22 replaces _StdRRect ($A8AF); card commands: $0D $26 $2E $38
GA_StdRRect:
  00581a:  4e 56 ff e4          link.w   a6, #$ffe4
  00581e:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  005822:  3a 2e 00 08          move.w   $8(a6), d5
  005826:  3c 2e 00 0a          move.w   $a(a6), d6
  00582a:  1e 2e 00 10          move.b   $10(a6), d7
  00582e:  47 ee ff e4          lea.l    -$1c(a6), a3
  005832:  4e ba b9 fc          jsr      $1230(pc)  ; -> GetA5
  005836:  20 40                movea.l  d0, a0
  005838:  20 50                movea.l  (a0), a0
  00583a:  28 50                movea.l  (a0), a4
  00583c:  42 2e ff f5          clr.b    -$b(a6)
  005840:  38 2c 00 42          move.w   $42(a4), d4
  005844:  30 04                move.w   d4, d0
  005846:  48 c0                ext.l    d0
  005848:  6d 00 00 be          blt.w    $5908  ; -> L5908
  00584c:  70 00                moveq    #$0, d0
  00584e:  10 07                move.b   d7, d0
  005850:  26 c0                move.l   d0, (a3)+
  005852:  26 ee 00 0c          move.l   $c(a6), (a3)+
  005856:  48 c6                ext.l    d6
  005858:  26 c6                move.l   d6, (a3)+
  00585a:  48 c5                ext.l    d5
  00585c:  26 85                move.l   d5, (a3)
  00585e:  70 04                moveq    #$4, d0
  005860:  2f 00                move.l   d0, -(a7)
  005862:  48 6e ff e4          pea.l    -$1c(a6)
  005866:  72 2e                moveq    #$2e, d1
  005868:  2f 01                move.l   d1, -(a7)
  00586a:  4e ba 09 b8          jsr      $6224(pc)  ; -> EngineDispatch
  00586e:  2d 40 ff fc          move.l   d0, -$4(a6)
  005872:  72 01                moveq    #$1, d1
  005874:  b2 80                cmp.l    d0, d1
  005876:  4f ef 00 0c          lea.l    $c(a7), a7
  00587a:  67 00 00 a6          beq.w    $5922  ; -> L5922
  00587e:  38 2c 00 42          move.w   $42(a4), d4
  005882:  30 04                move.w   d4, d0
  005884:  48 c0                ext.l    d0
  005886:  6d 18                blt.b    $58a0  ; -> L58a0
  005888:  48 6e ff fa          pea.l    -$6(a6)
  00588c:  48 6e ff f6          pea.l    -$a(a6)
  005890:  48 6c 00 02          pea.l    $2(a4)
  005894:  4e ba ef ac          jsr      $4842(pc)  ; -> s7_sub_86d6
  005898:  1d 40 ff f5          move.b   d0, -$b(a6)
  00589c:  4f ef 00 0c          lea.l    $c(a7), a7
L58a0:
  0058a0:  70 02                moveq    #$2, d0
  0058a2:  b0 ae ff fc          cmp.l    -$4(a6), d0
  0058a6:  66 26                bne.b    $58ce  ; -> L58ce
  0058a8:  39 7c ff ff 00 42    move.w   #$ffff, $42(a4)
  0058ae:  1f 07                move.b   d7, -(a7)
  0058b0:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  0058b4:  3f 06                move.w   d6, -(a7)
  0058b6:  3f 05                move.w   d5, -(a7)
  0058b8:  48 78 10 bc          pea.l    $10bc.w
  0058bc:  4e ba 2d de          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0058c0:  58 8f                addq.l   #$4, a7
  0058c2:  2f 00                move.l   d0, -(a7)
  0058c4:  20 5f                movea.l  (a7)+, a0
  0058c6:  4e 90                jsr      (a0)
  0058c8:  39 44 00 42          move.w   d4, $42(a4)
  0058cc:  60 1a                bra.b    $58e8  ; -> L58e8
L58ce:
  0058ce:  1f 07                move.b   d7, -(a7)
  0058d0:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  0058d4:  3f 06                move.w   d6, -(a7)
  0058d6:  3f 05                move.w   d5, -(a7)
  0058d8:  48 78 10 bc          pea.l    $10bc.w
  0058dc:  4e ba 2d be          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0058e0:  58 8f                addq.l   #$4, a7
  0058e2:  2f 00                move.l   d0, -(a7)
  0058e4:  20 5f                movea.l  (a7)+, a0
  0058e6:  4e 90                jsr      (a0)
L58e8:
  0058e8:  4a 2e ff f5          tst.b    -$b(a6)
  0058ec:  67 34                beq.b    $5922  ; -> L5922
  0058ee:  30 2e ff fa          move.w   -$6(a6), d0
  0058f2:  48 c0                ext.l    d0
  0058f4:  2f 00                move.l   d0, -(a7)
  0058f6:  2f 2e ff f6          move.l   -$a(a6), -(a7)
  0058fa:  48 6c 00 02          pea.l    $2(a4)
  0058fe:  4e ba ef fe          jsr      $48fe(pc)  ; -> s7_sub_879a
  005902:  4f ef 00 0c          lea.l    $c(a7), a7
  005906:  60 1a                bra.b    $5922  ; -> L5922
L5908:
  005908:  1f 07                move.b   d7, -(a7)
  00590a:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  00590e:  3f 06                move.w   d6, -(a7)
  005910:  3f 05                move.w   d5, -(a7)
  005912:  48 78 10 bc          pea.l    $10bc.w
  005916:  4e ba 2d 84          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00591a:  58 8f                addq.l   #$4, a7
  00591c:  2f 00                move.l   d0, -(a7)
  00591e:  20 5f                movea.l  (a7)+, a0
  005920:  4e 90                jsr      (a0)
L5922:
  005922:  4c ee 18 f0 ff cc    movem.l  -$34(a6), d4-d7/a3-a4
  005928:  4e 5e                unlk     a6
  00592a:  4e 74 00 0a          rtd      #$a
* GA_StdOval  -  System 7 $4020 (same trap slot $10D8, code r=0.96).
* S7: Patch #21 replaces _StdOval ($A8B6); card commands: $0D $26 $2F $38
GA_StdOval:
  00592e:  4e 56 ff f2          link.w   a6, #$fff2
  005932:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  005936:  28 6e 00 08          movea.l  $8(a6), a4
  00593a:  1e 2e 00 0c          move.b   $c(a6), d7
  00593e:  4e ba b8 f0          jsr      $1230(pc)  ; -> GetA5
  005942:  20 40                movea.l  d0, a0
  005944:  20 50                movea.l  (a0), a0
  005946:  26 50                movea.l  (a0), a3
  005948:  42 06                clr.b    d6
  00594a:  3a 2b 00 42          move.w   $42(a3), d5
  00594e:  30 05                move.w   d5, d0
  005950:  48 c0                ext.l    d0
  005952:  6d 00 00 9a          blt.w    $59ee  ; -> L59ee
  005956:  70 00                moveq    #$0, d0
  005958:  10 07                move.b   d7, d0
  00595a:  2d 40 ff f2          move.l   d0, -$e(a6)
  00595e:  2d 4c ff f6          move.l   a4, -$a(a6)
  005962:  70 02                moveq    #$2, d0
  005964:  2f 00                move.l   d0, -(a7)
  005966:  48 6e ff f2          pea.l    -$e(a6)
  00596a:  72 2f                moveq    #$2f, d1
  00596c:  2f 01                move.l   d1, -(a7)
  00596e:  4e ba 08 b4          jsr      $6224(pc)  ; -> EngineDispatch
  005972:  28 00                move.l   d0, d4
  005974:  70 01                moveq    #$1, d0
  005976:  b0 84                cmp.l    d4, d0
  005978:  4f ef 00 0c          lea.l    $c(a7), a7
  00597c:  67 00 00 84          beq.w    $5a02  ; -> L5a02
  005980:  48 6e ff fe          pea.l    -$2(a6)
  005984:  48 6e ff fa          pea.l    -$6(a6)
  005988:  48 6b 00 02          pea.l    $2(a3)
  00598c:  4e ba ee b4          jsr      $4842(pc)  ; -> s7_sub_86d6
  005990:  1c 00                move.b   d0, d6
  005992:  70 02                moveq    #$2, d0
  005994:  b0 84                cmp.l    d4, d0
  005996:  4f ef 00 0c          lea.l    $c(a7), a7
  00599a:  66 20                bne.b    $59bc  ; -> L59bc
  00599c:  37 7c ff ff 00 42    move.w   #$ffff, $42(a3)
  0059a2:  1f 07                move.b   d7, -(a7)
  0059a4:  2f 0c                move.l   a4, -(a7)
  0059a6:  48 78 10 d8          pea.l    $10d8.w
  0059aa:  4e ba 2c f0          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0059ae:  58 8f                addq.l   #$4, a7
  0059b0:  2f 00                move.l   d0, -(a7)
  0059b2:  20 5f                movea.l  (a7)+, a0
  0059b4:  4e 90                jsr      (a0)
  0059b6:  37 45 00 42          move.w   d5, $42(a3)
  0059ba:  60 14                bra.b    $59d0  ; -> L59d0
L59bc:
  0059bc:  1f 07                move.b   d7, -(a7)
  0059be:  2f 0c                move.l   a4, -(a7)
  0059c0:  48 78 10 d8          pea.l    $10d8.w
  0059c4:  4e ba 2c d6          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0059c8:  58 8f                addq.l   #$4, a7
  0059ca:  2f 00                move.l   d0, -(a7)
  0059cc:  20 5f                movea.l  (a7)+, a0
  0059ce:  4e 90                jsr      (a0)
L59d0:
  0059d0:  4a 06                tst.b    d6
  0059d2:  67 2e                beq.b    $5a02  ; -> L5a02
  0059d4:  30 2e ff fe          move.w   -$2(a6), d0
  0059d8:  48 c0                ext.l    d0
  0059da:  2f 00                move.l   d0, -(a7)
  0059dc:  2f 2e ff fa          move.l   -$6(a6), -(a7)
  0059e0:  48 6b 00 02          pea.l    $2(a3)
  0059e4:  4e ba ef 18          jsr      $48fe(pc)  ; -> s7_sub_879a
  0059e8:  4f ef 00 0c          lea.l    $c(a7), a7
  0059ec:  60 14                bra.b    $5a02  ; -> L5a02
L59ee:
  0059ee:  1f 07                move.b   d7, -(a7)
  0059f0:  2f 0c                move.l   a4, -(a7)
  0059f2:  48 78 10 d8          pea.l    $10d8.w
  0059f6:  4e ba 2c a4          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  0059fa:  58 8f                addq.l   #$4, a7
  0059fc:  2f 00                move.l   d0, -(a7)
  0059fe:  20 5f                movea.l  (a7)+, a0
  005a00:  4e 90                jsr      (a0)
L5a02:
  005a02:  4c ee 18 f0 ff da    movem.l  -$26(a6), d4-d7/a3-a4
  005a08:  4e 5e                unlk     a6
  005a0a:  4e 74 00 06          rtd      #$6
* GA_StdRect  -  System 7 $4116 (same trap slot $1080, code r=0.96).
* S7: Patch #20 replaces _StdRect ($A8A0); card commands: $0D $24 $26 $38
GA_StdRect:
  005a0e:  4e 56 ff f2          link.w   a6, #$fff2
  005a12:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  005a16:  28 6e 00 08          movea.l  $8(a6), a4
  005a1a:  1e 2e 00 0c          move.b   $c(a6), d7
  005a1e:  4e ba b8 10          jsr      $1230(pc)  ; -> GetA5
  005a22:  20 40                movea.l  d0, a0
  005a24:  20 50                movea.l  (a0), a0
  005a26:  26 50                movea.l  (a0), a3
  005a28:  42 06                clr.b    d6
  005a2a:  3a 2b 00 42          move.w   $42(a3), d5
  005a2e:  30 05                move.w   d5, d0
  005a30:  48 c0                ext.l    d0
  005a32:  6d 00 00 9a          blt.w    $5ace  ; -> L5ace
  005a36:  70 00                moveq    #$0, d0
  005a38:  10 07                move.b   d7, d0
  005a3a:  2d 40 ff f2          move.l   d0, -$e(a6)
  005a3e:  2d 4c ff f6          move.l   a4, -$a(a6)
  005a42:  70 02                moveq    #$2, d0
  005a44:  2f 00                move.l   d0, -(a7)
  005a46:  48 6e ff f2          pea.l    -$e(a6)
  005a4a:  72 24                moveq    #$24, d1
  005a4c:  2f 01                move.l   d1, -(a7)
  005a4e:  4e ba 07 d4          jsr      $6224(pc)  ; -> EngineDispatch
  005a52:  28 00                move.l   d0, d4
  005a54:  70 01                moveq    #$1, d0
  005a56:  b0 84                cmp.l    d4, d0
  005a58:  4f ef 00 0c          lea.l    $c(a7), a7
  005a5c:  67 00 00 84          beq.w    $5ae2  ; -> L5ae2
  005a60:  48 6e ff fe          pea.l    -$2(a6)
  005a64:  48 6e ff fa          pea.l    -$6(a6)
  005a68:  48 6b 00 02          pea.l    $2(a3)
  005a6c:  4e ba ed d4          jsr      $4842(pc)  ; -> s7_sub_86d6
  005a70:  1c 00                move.b   d0, d6
  005a72:  70 02                moveq    #$2, d0
  005a74:  b0 84                cmp.l    d4, d0
  005a76:  4f ef 00 0c          lea.l    $c(a7), a7
  005a7a:  66 20                bne.b    $5a9c  ; -> L5a9c
  005a7c:  37 7c ff ff 00 42    move.w   #$ffff, $42(a3)
  005a82:  1f 07                move.b   d7, -(a7)
  005a84:  2f 0c                move.l   a4, -(a7)
  005a86:  48 78 10 80          pea.l    $1080.w
  005a8a:  4e ba 2c 10          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005a8e:  58 8f                addq.l   #$4, a7
  005a90:  2f 00                move.l   d0, -(a7)
  005a92:  20 5f                movea.l  (a7)+, a0
  005a94:  4e 90                jsr      (a0)
  005a96:  37 45 00 42          move.w   d5, $42(a3)
  005a9a:  60 14                bra.b    $5ab0  ; -> L5ab0
L5a9c:
  005a9c:  1f 07                move.b   d7, -(a7)
  005a9e:  2f 0c                move.l   a4, -(a7)
  005aa0:  48 78 10 80          pea.l    $1080.w
  005aa4:  4e ba 2b f6          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005aa8:  58 8f                addq.l   #$4, a7
  005aaa:  2f 00                move.l   d0, -(a7)
  005aac:  20 5f                movea.l  (a7)+, a0
  005aae:  4e 90                jsr      (a0)
L5ab0:
  005ab0:  4a 06                tst.b    d6
  005ab2:  67 2e                beq.b    $5ae2  ; -> L5ae2
  005ab4:  30 2e ff fe          move.w   -$2(a6), d0
  005ab8:  48 c0                ext.l    d0
  005aba:  2f 00                move.l   d0, -(a7)
  005abc:  2f 2e ff fa          move.l   -$6(a6), -(a7)
  005ac0:  48 6b 00 02          pea.l    $2(a3)
  005ac4:  4e ba ee 38          jsr      $48fe(pc)  ; -> s7_sub_879a
  005ac8:  4f ef 00 0c          lea.l    $c(a7), a7
  005acc:  60 14                bra.b    $5ae2  ; -> L5ae2
L5ace:
  005ace:  1f 07                move.b   d7, -(a7)
  005ad0:  2f 0c                move.l   a4, -(a7)
  005ad2:  48 78 10 80          pea.l    $1080.w
  005ad6:  4e ba 2b c4          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005ada:  58 8f                addq.l   #$4, a7
  005adc:  2f 00                move.l   d0, -(a7)
  005ade:  20 5f                movea.l  (a7)+, a0
  005ae0:  4e 90                jsr      (a0)
L5ae2:
  005ae2:  4c ee 18 f0 ff da    movem.l  -$26(a6), d4-d7/a3-a4
  005ae8:  4e 5e                unlk     a6
  005aea:  4e 74 00 06          rtd      #$6
* GA_LowMem0804  -  System 7 $420C (same trap slot $804, code r=0.77).
* S7: Patch #8 replaces special; no EngineDispatch command found
GA_LowMem0804:
  005aee:  48 e7 01 10          movem.l  d7/a3, -(a7)
  005af2:  20 38 08 88          move.l   $888.w, d0
  005af6:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  005afc:  26 40                movea.l  d0, a3
  005afe:  4a ab 00 18          tst.l    $18(a3)
  005b02:  66 52                bne.b    $5b56  ; -> L5b56
  005b04:  20 6b 00 08          movea.l  $8(a3), a0
  005b08:  2e 10                move.l   (a0), d7
L5b0a:
  005b0a:  20 6b 00 0c          movea.l  $c(a3), a0
  005b0e:  4a 90                tst.l    (a0)
  005b10:  66 f8                bne.b    $5b0a  ; -> L5b0a
  005b12:  20 6b 00 08          movea.l  $8(a3), a0
  005b16:  20 bc 00 00 08 04    move.l   #$804, (a0)
  005b1c:  20 6b 00 0c          movea.l  $c(a3), a0
  005b20:  4a 90                tst.l    (a0)
  005b22:  67 08                beq.b    $5b2c  ; -> L5b2c
  005b24:  20 6b 00 08          movea.l  $8(a3), a0
  005b28:  20 87                move.l   d7, (a0)
  005b2a:  60 de                bra.b    $5b0a  ; -> L5b0a
L5b2c:
  005b2c:  20 6b 00 30          movea.l  $30(a3), a0
  005b30:  4a 90                tst.l    (a0)
  005b32:  67 0c                beq.b    $5b40  ; -> L5b40
  005b34:  42 38 08 cc          clr.b    $8cc.w
  005b38:  20 6b 00 30          movea.l  $30(a3), a0
  005b3c:  70 00                moveq    #$0, d0
  005b3e:  20 80                move.l   d0, (a0)
L5b40:
  005b40:  48 78 08 04          pea.l    $804.w
  005b44:  4e ba 2b 56          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005b48:  58 8f                addq.l   #$4, a7
  005b4a:  2f 00                move.l   d0, -(a7)
  005b4c:  20 5f                movea.l  (a7)+, a0
  005b4e:  4e 90                jsr      (a0)
  005b50:  20 6b 00 08          movea.l  $8(a3), a0
  005b54:  20 87                move.l   d7, (a0)
L5b56:
  005b56:  4c df 08 80          movem.l  (a7)+, d7/a3
  005b5a:  4e 75                rts
* GA_LowMem0800  -  System 7 $42B8 (same trap slot $800, code r=0.87).
* S7: Patch #7 replaces special; no EngineDispatch command found
GA_LowMem0800:
  005b5c:  48 e7 01 10          movem.l  d7/a3, -(a7)
  005b60:  20 38 08 88          move.l   $888.w, d0
  005b64:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  005b6a:  26 40                movea.l  d0, a3
  005b6c:  20 6b 00 08          movea.l  $8(a3), a0
  005b70:  2e 10                move.l   (a0), d7
L5b72:
  005b72:  20 6b 00 0c          movea.l  $c(a3), a0
  005b76:  4a 90                tst.l    (a0)
  005b78:  66 f8                bne.b    $5b72  ; -> L5b72
  005b7a:  20 6b 00 08          movea.l  $8(a3), a0
  005b7e:  20 bc 00 00 08 00    move.l   #$800, (a0)
  005b84:  20 6b 00 0c          movea.l  $c(a3), a0
  005b88:  4a 90                tst.l    (a0)
  005b8a:  67 08                beq.b    $5b94  ; -> L5b94
  005b8c:  20 6b 00 08          movea.l  $8(a3), a0
  005b90:  20 87                move.l   d7, (a0)
  005b92:  60 de                bra.b    $5b72  ; -> L5b72
L5b94:
  005b94:  20 6b 00 30          movea.l  $30(a3), a0
  005b98:  4a 90                tst.l    (a0)
  005b9a:  67 0c                beq.b    $5ba8  ; -> L5ba8
  005b9c:  42 38 08 cc          clr.b    $8cc.w
  005ba0:  20 6b 00 30          movea.l  $30(a3), a0
  005ba4:  70 00                moveq    #$0, d0
  005ba6:  20 80                move.l   d0, (a0)
L5ba8:
  005ba8:  48 78 08 00          pea.l    $800.w
  005bac:  4e ba 2a ee          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005bb0:  58 8f                addq.l   #$4, a7
  005bb2:  2f 00                move.l   d0, -(a7)
  005bb4:  20 5f                movea.l  (a7)+, a0
  005bb6:  4e 90                jsr      (a0)
  005bb8:  20 6b 00 08          movea.l  $8(a3), a0
  005bbc:  20 87                move.l   d7, (a0)
  005bbe:  4c df 08 80          movem.l  (a7)+, d7/a3
  005bc2:  4e 75                rts
* GA_LowMem0818  -  System 7 $433E (same trap slot $818, code r=0.94).
* S7: Patch #70 replaces special; no EngineDispatch command found
GA_LowMem0818:
  005bc4:  4e 56 00 00          link.w   a6, #$0
  005bc8:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  005bcc:  28 6e 00 0c          movea.l  $c(a6), a4
  005bd0:  20 38 08 88          move.l   $888.w, d0
  005bd4:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  005bda:  26 40                movea.l  d0, a3
  005bdc:  20 6b 00 08          movea.l  $8(a3), a0
  005be0:  2e 10                move.l   (a0), d7
L5be2:
  005be2:  20 6b 00 0c          movea.l  $c(a3), a0
  005be6:  4a 90                tst.l    (a0)
  005be8:  66 f8                bne.b    $5be2  ; -> L5be2
  005bea:  20 6b 00 08          movea.l  $8(a3), a0
  005bee:  20 bc 00 00 08 18    move.l   #$818, (a0)
  005bf4:  20 6b 00 0c          movea.l  $c(a3), a0
  005bf8:  4a 90                tst.l    (a0)
  005bfa:  67 08                beq.b    $5c04  ; -> L5c04
  005bfc:  20 6b 00 08          movea.l  $8(a3), a0
  005c00:  20 87                move.l   d7, (a0)
  005c02:  60 de                bra.b    $5be2  ; -> L5be2
L5c04:
  005c04:  20 6b 00 30          movea.l  $30(a3), a0
  005c08:  4a 90                tst.l    (a0)
  005c0a:  67 0c                beq.b    $5c18  ; -> L5c18
  005c0c:  42 38 08 cc          clr.b    $8cc.w
  005c10:  20 6b 00 30          movea.l  $30(a3), a0
  005c14:  70 00                moveq    #$0, d0
  005c16:  20 80                move.l   d0, (a0)
L5c18:
  005c18:  2f 2e 00 12          move.l   $12(a6), -(a7)
  005c1c:  3f 2e 00 10          move.w   $10(a6), -(a7)
  005c20:  2f 0c                move.l   a4, -(a7)
  005c22:  2f 2e 00 08          move.l   $8(a6), -(a7)
  005c26:  48 78 08 18          pea.l    $818.w
  005c2a:  4e ba 2a 70          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005c2e:  58 8f                addq.l   #$4, a7
  005c30:  2f 00                move.l   d0, -(a7)
  005c32:  20 5f                movea.l  (a7)+, a0
  005c34:  4e 90                jsr      (a0)
  005c36:  20 6b 00 08          movea.l  $8(a3), a0
  005c3a:  20 87                move.l   d7, (a0)
  005c3c:  4c ee 18 80 ff f4    movem.l  -$c(a6), d7/a3-a4
  005c42:  4e 5e                unlk     a6
  005c44:  4e 74 00 0e          rtd      #$e
* GA_LowMem081C  -  System 7 $43CA (same trap slot $81C, code r=0.92).
* S7: Patch #71 replaces special; no EngineDispatch command found
GA_LowMem081C:
  005c48:  48 e7 01 10          movem.l  d7/a3, -(a7)
  005c4c:  20 38 08 88          move.l   $888.w, d0
  005c50:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  005c56:  26 40                movea.l  d0, a3
  005c58:  20 6b 00 08          movea.l  $8(a3), a0
  005c5c:  2e 10                move.l   (a0), d7
L5c5e:
  005c5e:  20 6b 00 0c          movea.l  $c(a3), a0
  005c62:  4a 90                tst.l    (a0)
  005c64:  66 f8                bne.b    $5c5e  ; -> L5c5e
  005c66:  20 6b 00 08          movea.l  $8(a3), a0
  005c6a:  20 bc 00 00 08 1c    move.l   #$81c, (a0)
  005c70:  20 6b 00 0c          movea.l  $c(a3), a0
  005c74:  4a 90                tst.l    (a0)
  005c76:  67 08                beq.b    $5c80  ; -> L5c80
  005c78:  20 6b 00 08          movea.l  $8(a3), a0
  005c7c:  20 87                move.l   d7, (a0)
  005c7e:  60 de                bra.b    $5c5e  ; -> L5c5e
L5c80:
  005c80:  20 6b 00 30          movea.l  $30(a3), a0
  005c84:  4a 90                tst.l    (a0)
  005c86:  67 0c                beq.b    $5c94  ; -> L5c94
  005c88:  42 38 08 cc          clr.b    $8cc.w
  005c8c:  20 6b 00 30          movea.l  $30(a3), a0
  005c90:  70 00                moveq    #$0, d0
  005c92:  20 80                move.l   d0, (a0)
L5c94:
  005c94:  48 78 08 1c          pea.l    $81c.w
  005c98:  4e ba 2a 02          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005c9c:  58 8f                addq.l   #$4, a7
  005c9e:  2f 00                move.l   d0, -(a7)
  005ca0:  20 5f                movea.l  (a7)+, a0
  005ca2:  4e 90                jsr      (a0)
  005ca4:  20 6b 00 08          movea.l  $8(a3), a0
  005ca8:  20 87                move.l   d7, (a0)
  005caa:  4c df 08 80          movem.l  (a7)+, d7/a3
  005cae:  4e 75                rts
* GA_LowMem0890  -  System 7 $4444 (same trap slot $890, code r=0.91).
* S7: Patch #72 replaces special; no EngineDispatch command found
GA_LowMem0890:
  005cb0:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  005cb4:  28 6f 00 10          movea.l  $10(a7), a4
  005cb8:  20 38 08 88          move.l   $888.w, d0
  005cbc:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  005cc2:  26 40                movea.l  d0, a3
  005cc4:  20 6b 00 08          movea.l  $8(a3), a0
  005cc8:  2e 10                move.l   (a0), d7
L5cca:
  005cca:  20 6b 00 0c          movea.l  $c(a3), a0
  005cce:  4a 90                tst.l    (a0)
  005cd0:  66 f8                bne.b    $5cca  ; -> L5cca
  005cd2:  20 6b 00 08          movea.l  $8(a3), a0
  005cd6:  20 bc 00 00 08 90    move.l   #$890, (a0)
  005cdc:  20 6b 00 0c          movea.l  $c(a3), a0
  005ce0:  4a 90                tst.l    (a0)
  005ce2:  67 08                beq.b    $5cec  ; -> L5cec
  005ce4:  20 6b 00 08          movea.l  $8(a3), a0
  005ce8:  20 87                move.l   d7, (a0)
  005cea:  60 de                bra.b    $5cca  ; -> L5cca
L5cec:
  005cec:  20 6b 00 30          movea.l  $30(a3), a0
  005cf0:  4a 90                tst.l    (a0)
  005cf2:  67 0c                beq.b    $5d00  ; -> L5d00
  005cf4:  42 38 08 cc          clr.b    $8cc.w
  005cf8:  20 6b 00 30          movea.l  $30(a3), a0
  005cfc:  70 00                moveq    #$0, d0
  005cfe:  20 80                move.l   d0, (a0)
L5d00:
  005d00:  2f 0c                move.l   a4, -(a7)
  005d02:  48 78 08 90          pea.l    $890.w
  005d06:  4e ba 29 94          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005d0a:  58 8f                addq.l   #$4, a7
  005d0c:  2f 00                move.l   d0, -(a7)
  005d0e:  20 5f                movea.l  (a7)+, a0
  005d10:  4e 90                jsr      (a0)
  005d12:  20 6b 00 08          movea.l  $8(a3), a0
  005d16:  20 87                move.l   d7, (a0)
  005d18:  4c df 18 80          movem.l  (a7)+, d7/a3-a4
  005d1c:  4e 74 00 04          rtd      #$4
* GA_LowMem0808  -  System 7 $44C4 (same trap slot $808, code r=0.68).
* S7: Patch #9 replaces special; no EngineDispatch command found
GA_LowMem0808:
  005d20:  4e 56 ff fc          link.w   a6, #$fffc
  005d24:  48 e7 0f 10          movem.l  d4-d7/a3, -(a7)
  005d28:  38 2e 00 08          move.w   $8(a6), d4
  005d2c:  3a 2e 00 0a          move.w   $a(a6), d5
  005d30:  3c 2e 00 0c          move.w   $c(a6), d6
  005d34:  3e 2e 00 0e          move.w   $e(a6), d7
  005d38:  20 38 08 88          move.l   $888.w, d0
  005d3c:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  005d42:  26 40                movea.l  d0, a3
  005d44:  4a ab 00 18          tst.l    $18(a3)
  005d48:  67 00 00 b0          beq.w    $5dfa  ; -> L5dfa
  005d4c:  20 6b 00 1c          movea.l  $1c(a3), a0
  005d50:  30 10                move.w   (a0), d0
  005d52:  48 c0                ext.l    d0
  005d54:  66 46                bne.b    $5d9c  ; -> L5d9c
  005d56:  20 6b 00 1c          movea.l  $1c(a3), a0
  005d5a:  30 28 00 02          move.w   $2(a0), d0
  005d5e:  48 c0                ext.l    d0
  005d60:  66 3a                bne.b    $5d9c  ; -> L5d9c
  005d62:  20 6b 00 1c          movea.l  $1c(a3), a0
  005d66:  30 28 00 06          move.w   $6(a0), d0
  005d6a:  48 c0                ext.l    d0
  005d6c:  66 2e                bne.b    $5d9c  ; -> L5d9c
  005d6e:  20 6b 00 1c          movea.l  $1c(a3), a0
  005d72:  30 28 00 04          move.w   $4(a0), d0
  005d76:  48 c0                ext.l    d0
  005d78:  66 22                bne.b    $5d9c  ; -> L5d9c
  005d7a:  20 6b 00 1c          movea.l  $1c(a3), a0
  005d7e:  30 86                move.w   d6, (a0)
  005d80:  20 6b 00 1c          movea.l  $1c(a3), a0
  005d84:  31 47 00 02          move.w   d7, $2(a0)
  005d88:  20 6b 00 1c          movea.l  $1c(a3), a0
  005d8c:  31 45 00 06          move.w   d5, $6(a0)
  005d90:  20 6b 00 1c          movea.l  $1c(a3), a0
  005d94:  31 44 00 04          move.w   d4, $4(a0)
  005d98:  60 00 00 c0          bra.w    $5e5a  ; -> L5e5a
L5d9c:
  005d9c:  48 c6                ext.l    d6
  005d9e:  20 6b 00 1c          movea.l  $1c(a3), a0
  005da2:  30 10                move.w   (a0), d0
  005da4:  48 c0                ext.l    d0
  005da6:  b0 86                cmp.l    d6, d0
  005da8:  6f 06                ble.b    $5db0  ; -> L5db0
  005daa:  20 6b 00 1c          movea.l  $1c(a3), a0
  005dae:  30 86                move.w   d6, (a0)
L5db0:
  005db0:  48 c7                ext.l    d7
  005db2:  20 6b 00 1c          movea.l  $1c(a3), a0
  005db6:  30 28 00 02          move.w   $2(a0), d0
  005dba:  48 c0                ext.l    d0
  005dbc:  b0 87                cmp.l    d7, d0
  005dbe:  6f 08                ble.b    $5dc8  ; -> L5dc8
  005dc0:  20 6b 00 1c          movea.l  $1c(a3), a0
  005dc4:  31 47 00 02          move.w   d7, $2(a0)
L5dc8:
  005dc8:  48 c5                ext.l    d5
  005dca:  20 6b 00 1c          movea.l  $1c(a3), a0
  005dce:  30 28 00 06          move.w   $6(a0), d0
  005dd2:  48 c0                ext.l    d0
  005dd4:  b0 85                cmp.l    d5, d0
  005dd6:  6c 08                bge.b    $5de0  ; -> L5de0
  005dd8:  20 6b 00 1c          movea.l  $1c(a3), a0
  005ddc:  31 45 00 06          move.w   d5, $6(a0)
L5de0:
  005de0:  48 c4                ext.l    d4
  005de2:  20 6b 00 1c          movea.l  $1c(a3), a0
  005de6:  30 28 00 04          move.w   $4(a0), d0
  005dea:  48 c0                ext.l    d0
  005dec:  b0 84                cmp.l    d4, d0
  005dee:  6c 6a                bge.b    $5e5a  ; -> L5e5a
  005df0:  20 6b 00 1c          movea.l  $1c(a3), a0
  005df4:  31 44 00 04          move.w   d4, $4(a0)
  005df8:  60 60                bra.b    $5e5a  ; -> L5e5a
L5dfa:
  005dfa:  20 6b 00 08          movea.l  $8(a3), a0
  005dfe:  2d 50 ff fc          move.l   (a0), -$4(a6)
L5e02:
  005e02:  20 6b 00 0c          movea.l  $c(a3), a0
  005e06:  4a 90                tst.l    (a0)
  005e08:  66 f8                bne.b    $5e02  ; -> L5e02
  005e0a:  20 6b 00 08          movea.l  $8(a3), a0
  005e0e:  20 bc 00 00 08 08    move.l   #$808, (a0)
  005e14:  20 6b 00 0c          movea.l  $c(a3), a0
  005e18:  4a 90                tst.l    (a0)
  005e1a:  67 0a                beq.b    $5e26  ; -> L5e26
  005e1c:  20 6b 00 08          movea.l  $8(a3), a0
  005e20:  20 ae ff fc          move.l   -$4(a6), (a0)
  005e24:  60 dc                bra.b    $5e02  ; -> L5e02
L5e26:
  005e26:  20 6b 00 30          movea.l  $30(a3), a0
  005e2a:  4a 90                tst.l    (a0)
  005e2c:  67 0c                beq.b    $5e3a  ; -> L5e3a
  005e2e:  42 38 08 cc          clr.b    $8cc.w
  005e32:  20 6b 00 30          movea.l  $30(a3), a0
  005e36:  70 00                moveq    #$0, d0
  005e38:  20 80                move.l   d0, (a0)
L5e3a:
  005e3a:  3f 07                move.w   d7, -(a7)
  005e3c:  3f 06                move.w   d6, -(a7)
  005e3e:  3f 05                move.w   d5, -(a7)
  005e40:  3f 04                move.w   d4, -(a7)
  005e42:  48 78 08 08          pea.l    $808.w
  005e46:  4e ba 28 54          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005e4a:  58 8f                addq.l   #$4, a7
  005e4c:  2f 00                move.l   d0, -(a7)
  005e4e:  20 5f                movea.l  (a7)+, a0
  005e50:  4e 90                jsr      (a0)
  005e52:  20 6b 00 08          movea.l  $8(a3), a0
  005e56:  20 ae ff fc          move.l   -$4(a6), (a0)
L5e5a:
  005e5a:  4c ee 08 f0 ff e8    movem.l  -$18(a6), d4-d7/a3
  005e60:  4e 5e                unlk     a6
  005e62:  4e 74 00 08          rtd      #$8
* GA_LowMem0814  -  System 7 $45D4 (same trap slot $814, code r=0.88).
* S7: Patch #69 replaces special; no EngineDispatch command found
GA_LowMem0814:
  005e66:  48 e7 01 10          movem.l  d7/a3, -(a7)
  005e6a:  20 38 08 88          move.l   $888.w, d0
  005e6e:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  005e74:  26 40                movea.l  d0, a3
  005e76:  20 6b 00 08          movea.l  $8(a3), a0
  005e7a:  2e 10                move.l   (a0), d7
L5e7c:
  005e7c:  20 6b 00 0c          movea.l  $c(a3), a0
  005e80:  4a 90                tst.l    (a0)
  005e82:  66 f8                bne.b    $5e7c  ; -> L5e7c
  005e84:  20 6b 00 08          movea.l  $8(a3), a0
  005e88:  20 bc 00 00 08 14    move.l   #$814, (a0)
  005e8e:  20 6b 00 0c          movea.l  $c(a3), a0
  005e92:  4a 90                tst.l    (a0)
  005e94:  67 08                beq.b    $5e9e  ; -> L5e9e
  005e96:  20 6b 00 08          movea.l  $8(a3), a0
  005e9a:  20 87                move.l   d7, (a0)
  005e9c:  60 de                bra.b    $5e7c  ; -> L5e7c
L5e9e:
  005e9e:  20 6b 00 30          movea.l  $30(a3), a0
  005ea2:  4a 90                tst.l    (a0)
  005ea4:  67 0c                beq.b    $5eb2  ; -> L5eb2
  005ea6:  42 38 08 cc          clr.b    $8cc.w
  005eaa:  20 6b 00 30          movea.l  $30(a3), a0
  005eae:  70 00                moveq    #$0, d0
  005eb0:  20 80                move.l   d0, (a0)
L5eb2:
  005eb2:  48 78 08 14          pea.l    $814.w
  005eb6:  4e ba 27 e4          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005eba:  58 8f                addq.l   #$4, a7
  005ebc:  2f 00                move.l   d0, -(a7)
  005ebe:  20 5f                movea.l  (a7)+, a0
  005ec0:  4e 90                jsr      (a0)
  005ec2:  20 6b 00 08          movea.l  $8(a3), a0
  005ec6:  20 87                move.l   d7, (a0)
  005ec8:  4c df 08 80          movem.l  (a7)+, d7/a3
  005ecc:  4e 75                rts
* GA_InitGraf  -  System 7 $4658 (same trap slot $FB8, code r=0.79).
* S7: Patch #93 replaces _InitGraf ($A86E); card commands: $26
GA_InitGraf:
  005ece:  2f 0b                move.l   a3, -(a7)
  005ed0:  26 6f 00 08          movea.l  $8(a7), a3
  005ed4:  70 1f                moveq    #$1f, d0
  005ed6:  2f 00                move.l   d0, -(a7)
  005ed8:  4e ba 01 ba          jsr      $6094(pc)  ; -> s7_sub_4822
  005edc:  2f 0b                move.l   a3, -(a7)
  005ede:  48 78 0f b8          pea.l    $fb8.w
  005ee2:  4e ba 27 b8          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005ee6:  58 8f                addq.l   #$4, a7
  005ee8:  2f 00                move.l   d0, -(a7)
  005eea:  20 5f                movea.l  (a7)+, a0
  005eec:  4e 90                jsr      (a0)
  005eee:  58 8f                addq.l   #$4, a7
  005ef0:  26 5f                movea.l  (a7)+, a3
  005ef2:  4e 74 00 04          rtd      #$4
* GA_InitPort  -  System 7 $4682 (same trap slot $FB4, code r=0.79).
* S7: Patch #94 replaces _InitPort ($A86D); card commands: $26
GA_InitPort:
  005ef6:  2f 0b                move.l   a3, -(a7)
  005ef8:  26 6f 00 08          movea.l  $8(a7), a3
  005efc:  70 1e                moveq    #$1e, d0
  005efe:  2f 00                move.l   d0, -(a7)
  005f00:  4e ba 01 92          jsr      $6094(pc)  ; -> s7_sub_4822
  005f04:  2f 0b                move.l   a3, -(a7)
  005f06:  48 78 0f b4          pea.l    $fb4.w
  005f0a:  4e ba 27 90          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005f0e:  58 8f                addq.l   #$4, a7
  005f10:  2f 00                move.l   d0, -(a7)
  005f12:  20 5f                movea.l  (a7)+, a0
  005f14:  4e 90                jsr      (a0)
  005f16:  58 8f                addq.l   #$4, a7
  005f18:  26 5f                movea.l  (a7)+, a3
  005f1a:  4e 74 00 04          rtd      #$4
* GA_OpenPort  -  System 7 $46AC (same trap slot $FBC, code r=0.79).
* S7: Patch #95 replaces _OpenPort ($A86F); card commands: $26
GA_OpenPort:
  005f1e:  2f 0b                move.l   a3, -(a7)
  005f20:  26 6f 00 08          movea.l  $8(a7), a3
  005f24:  70 1e                moveq    #$1e, d0
  005f26:  2f 00                move.l   d0, -(a7)
  005f28:  4e ba 01 6a          jsr      $6094(pc)  ; -> s7_sub_4822
  005f2c:  2f 0b                move.l   a3, -(a7)
  005f2e:  48 78 0f bc          pea.l    $fbc.w
  005f32:  4e ba 27 68          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005f36:  58 8f                addq.l   #$4, a7
  005f38:  2f 00                move.l   d0, -(a7)
  005f3a:  20 5f                movea.l  (a7)+, a0
  005f3c:  4e 90                jsr      (a0)
  005f3e:  58 8f                addq.l   #$4, a7
  005f40:  26 5f                movea.l  (a7)+, a3
  005f42:  4e 74 00 04          rtd      #$4
* GA_InitCPort  -  System 7 $46D6 (same trap slot $1604, code r=0.79).
* S7: Patch #96 replaces _InitCPort ($AA01); card commands: $26
GA_InitCPort:
  005f46:  2f 0b                move.l   a3, -(a7)
  005f48:  26 6f 00 08          movea.l  $8(a7), a3
  005f4c:  70 1e                moveq    #$1e, d0
  005f4e:  2f 00                move.l   d0, -(a7)
  005f50:  4e ba 01 42          jsr      $6094(pc)  ; -> s7_sub_4822
  005f54:  2f 0b                move.l   a3, -(a7)
  005f56:  48 78 16 04          pea.l    $1604.w
  005f5a:  4e ba 27 40          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005f5e:  58 8f                addq.l   #$4, a7
  005f60:  2f 00                move.l   d0, -(a7)
  005f62:  20 5f                movea.l  (a7)+, a0
  005f64:  4e 90                jsr      (a0)
  005f66:  58 8f                addq.l   #$4, a7
  005f68:  26 5f                movea.l  (a7)+, a3
  005f6a:  4e 74 00 04          rtd      #$4
* GA_OpenCPort  -  System 7 $4700 (same trap slot $1600, code r=0.79).
* S7: Patch #97 replaces _OpenCPort ($AA00); card commands: $26
GA_OpenCPort:
  005f6e:  2f 0b                move.l   a3, -(a7)
  005f70:  26 6f 00 08          movea.l  $8(a7), a3
  005f74:  70 1e                moveq    #$1e, d0
  005f76:  2f 00                move.l   d0, -(a7)
  005f78:  4e ba 01 1a          jsr      $6094(pc)  ; -> s7_sub_4822
  005f7c:  2f 0b                move.l   a3, -(a7)
  005f7e:  48 78 16 00          pea.l    $1600.w
  005f82:  4e ba 27 18          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005f86:  58 8f                addq.l   #$4, a7
  005f88:  2f 00                move.l   d0, -(a7)
  005f8a:  20 5f                movea.l  (a7)+, a0
  005f8c:  4e 90                jsr      (a0)
  005f8e:  58 8f                addq.l   #$4, a7
  005f90:  26 5f                movea.l  (a7)+, a3
  005f92:  4e 74 00 04          rtd      #$4
* GA_DrawPicture  -  System 7 $472A (same trap slot $11D8, code r=0.81).
* S7: Patch #75 replaces _DrawPicture ($A8F6); card commands: $26
GA_DrawPicture:
  005f96:  48 e7 00 18          movem.l  a3-a4, -(a7)
  005f9a:  28 6f 00 0c          movea.l  $c(a7), a4
  005f9e:  26 6f 00 10          movea.l  $10(a7), a3
  005fa2:  70 1a                moveq    #$1a, d0
  005fa4:  2f 00                move.l   d0, -(a7)
  005fa6:  4e ba 00 ec          jsr      $6094(pc)  ; -> s7_sub_4822
  005faa:  2f 0b                move.l   a3, -(a7)
  005fac:  2f 0c                move.l   a4, -(a7)
  005fae:  48 78 11 d8          pea.l    $11d8.w
  005fb2:  4e ba 26 e8          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  005fb6:  58 8f                addq.l   #$4, a7
  005fb8:  2f 00                move.l   d0, -(a7)
  005fba:  20 5f                movea.l  (a7)+, a0
  005fbc:  4e 90                jsr      (a0)
  005fbe:  70 1a                moveq    #$1a, d0
  005fc0:  2f 00                move.l   d0, -(a7)
  005fc2:  4e ba 00 d0          jsr      $6094(pc)  ; -> s7_sub_4822
  005fc6:  50 8f                addq.l   #$8, a7
  005fc8:  4c df 18 00          movem.l  (a7)+, a3-a4
  005fcc:  4e 74 00 08          rtd      #$8
* GA_SeedCFill  -  System 7 $4762 (same trap slot $1740, code r=0.85).
* S7: Patch #82 replaces _SeedCFill ($AA50); no EngineDispatch command found
GA_SeedCFill:
  005fd0:  4e 56 00 00          link.w   a6, #$0
  005fd4:  48 e7 00 18          movem.l  a3-a4, -(a7)
  005fd8:  28 6e 00 20          movea.l  $20(a6), a4
  005fdc:  20 38 08 88          move.l   $888.w, d0
  005fe0:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  005fe6:  20 40                movea.l  d0, a0
  005fe8:  20 50                movea.l  (a0), a0
  005fea:  26 50                movea.l  (a0), a3
  005fec:  17 7c 00 01 02 57    move.b   #$1, $257(a3)
  005ff2:  2f 0c                move.l   a4, -(a7)
  005ff4:  2f 2e 00 1c          move.l   $1c(a6), -(a7)
  005ff8:  2f 2e 00 18          move.l   $18(a6), -(a7)
  005ffc:  2f 2e 00 14          move.l   $14(a6), -(a7)
  006000:  2f 2e 00 10          move.l   $10(a6), -(a7)
  006004:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  006008:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00600c:  48 78 17 40          pea.l    $1740.w
  006010:  4e ba 26 8a          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  006014:  58 8f                addq.l   #$4, a7
  006016:  2f 00                move.l   d0, -(a7)
  006018:  20 5f                movea.l  (a7)+, a0
  00601a:  4e 90                jsr      (a0)
  00601c:  42 2b 02 57          clr.b    $257(a3)
  006020:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  006026:  4e 5e                unlk     a6
  006028:  4e 74 00 1c          rtd      #$1c
* GA_CalcCMask  -  System 7 $47BC (same trap slot $173C, code r=0.87).
* S7: Patch #83 replaces _CalcCMask ($AA4F); no EngineDispatch command found
GA_CalcCMask:
  00602c:  4e 56 ff fa          link.w   a6, #$fffa
  006030:  48 e7 00 18          movem.l  a3-a4, -(a7)
  006034:  28 6e 00 20          movea.l  $20(a6), a4
  006038:  20 6e 00 10          movea.l  $10(a6), a0
  00603c:  43 ee ff fa          lea.l    -$6(a6), a1
  006040:  22 d8                move.l   (a0)+, (a1)+
  006042:  32 d8                move.w   (a0)+, (a1)+
  006044:  20 38 08 88          move.l   $888.w, d0
  006048:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  00604e:  20 40                movea.l  d0, a0
  006050:  20 50                movea.l  (a0), a0
  006052:  26 50                movea.l  (a0), a3
  006054:  17 7c 00 01 02 57    move.b   #$1, $257(a3)
  00605a:  2f 0c                move.l   a4, -(a7)
  00605c:  2f 2e 00 1c          move.l   $1c(a6), -(a7)
  006060:  2f 2e 00 18          move.l   $18(a6), -(a7)
  006064:  2f 2e 00 14          move.l   $14(a6), -(a7)
  006068:  48 6e ff fa          pea.l    -$6(a6)
  00606c:  2f 2e 00 0c          move.l   $c(a6), -(a7)
  006070:  2f 2e 00 08          move.l   $8(a6), -(a7)
  006074:  48 78 17 3c          pea.l    $173c.w
  006078:  4e ba 26 22          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  00607c:  58 8f                addq.l   #$4, a7
  00607e:  2f 00                move.l   d0, -(a7)
  006080:  20 5f                movea.l  (a7)+, a0
  006082:  4e 90                jsr      (a0)
  006084:  42 2b 02 57          clr.b    $257(a3)
  006088:  4c ee 18 00 ff f2    movem.l  -$e(a6), a3-a4
  00608e:  4e 5e                unlk     a6
  006090:  4e 74 00 1c          rtd      #$1c
* s7_sub_4822  -  System 7 $4822 (identical code).
* S7: sub_4822(reason) = EngineDispatch($26, NULL, reason): flush / end the
s7_sub_4822:
  006094:  4e 56 00 00          link.w   a6, #$0
  006098:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00609c:  70 00                moveq    #$0, d0
  00609e:  2f 00                move.l   d0, -(a7)
  0060a0:  72 26                moveq    #$26, d1
  0060a2:  2f 01                move.l   d1, -(a7)
  0060a4:  4e ba 01 7e          jsr      $6224(pc)  ; -> EngineDispatch
  0060a8:  4e 5e                unlk     a6
  0060aa:  4e 75                rts
* GA_CopyBits  -  System 7 $483C (same trap slot $11B0, code r=0.93).
* S7: Patch #2 replaces _CopyBits ($A8EC); card commands: $0D $38
GA_CopyBits:
  0060ac:  4e 56 ff ee          link.w   a6, #$ffee
  0060b0:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  0060b4:  3e 2e 00 0c          move.w   $c(a6), d7
  0060b8:  28 6e 00 1a          movea.l  $1a(a6), a4
  0060bc:  42 6e ff fe          clr.w    -$2(a6)
  0060c0:  42 6e ff fc          clr.w    -$4(a6)
  0060c4:  42 6e ff fa          clr.w    -$6(a6)
  0060c8:  42 6e ff f8          clr.w    -$8(a6)
  0060cc:  20 38 08 88          move.l   $888.w, d0
  0060d0:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  0060d6:  26 40                movea.l  d0, a3
  0060d8:  4a ab 00 18          tst.l    $18(a3)
  0060dc:  66 0c                bne.b    $60ea  ; -> L60ea
  0060de:  20 6b 00 1c          movea.l  $1c(a3), a0
  0060e2:  43 ee ff f8          lea.l    -$8(a6), a1
  0060e6:  20 d9                move.l   (a1)+, (a0)+
  0060e8:  20 d9                move.l   (a1)+, (a0)+
L60ea:
  0060ea:  4e ba b1 44          jsr      $1230(pc)  ; -> GetA5
  0060ee:  20 40                movea.l  d0, a0
  0060f0:  20 50                movea.l  (a0), a0
  0060f2:  20 50                movea.l  (a0), a0
  0060f4:  4a a8 00 5c          tst.l    $5c(a0)
  0060f8:  67 54                beq.b    $614e  ; -> L614e
  0060fa:  48 6e ff f2          pea.l    -$e(a6)
  0060fe:  48 6e ff ee          pea.l    -$12(a6)
  006102:  2f 0c                move.l   a4, -(a7)
  006104:  4e ba e7 3c          jsr      $4842(pc)  ; -> s7_sub_86d6
  006108:  1c 00                move.b   d0, d6
  00610a:  2f 0c                move.l   a4, -(a7)
  00610c:  2f 2e 00 16          move.l   $16(a6), -(a7)
  006110:  2f 2e 00 12          move.l   $12(a6), -(a7)
  006114:  2f 2e 00 0e          move.l   $e(a6), -(a7)
  006118:  3f 07                move.w   d7, -(a7)
  00611a:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00611e:  48 78 11 b0          pea.l    $11b0.w
  006122:  4e ba 25 78          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  006126:  58 8f                addq.l   #$4, a7
  006128:  2f 00                move.l   d0, -(a7)
  00612a:  20 5f                movea.l  (a7)+, a0
  00612c:  4e 90                jsr      (a0)
  00612e:  4a 06                tst.b    d6
  006130:  4f ef 00 0c          lea.l    $c(a7), a7
  006134:  67 5c                beq.b    $6192  ; -> L6192
  006136:  30 2e ff f2          move.w   -$e(a6), d0
  00613a:  48 c0                ext.l    d0
  00613c:  2f 00                move.l   d0, -(a7)
  00613e:  2f 2e ff ee          move.l   -$12(a6), -(a7)
  006142:  2f 0c                move.l   a4, -(a7)
  006144:  4e ba e7 b8          jsr      $48fe(pc)  ; -> s7_sub_879a
  006148:  4f ef 00 0c          lea.l    $c(a7), a7
  00614c:  60 44                bra.b    $6192  ; -> L6192
L614e:
  00614e:  20 53                movea.l  (a3), a0
  006150:  20 50                movea.l  (a0), a0
  006152:  2d 68 02 14 ff f4    move.l   $214(a0), -$c(a6)
  006158:  52 ab 00 18          addq.l   #$1, $18(a3)
  00615c:  2f 0c                move.l   a4, -(a7)
  00615e:  2f 2e 00 16          move.l   $16(a6), -(a7)
  006162:  2f 2e 00 12          move.l   $12(a6), -(a7)
  006166:  2f 2e 00 0e          move.l   $e(a6), -(a7)
  00616a:  3f 07                move.w   d7, -(a7)
  00616c:  2f 2e 00 08          move.l   $8(a6), -(a7)
  006170:  48 78 11 b0          pea.l    $11b0.w
  006174:  4e ba 25 26          jsr      $869c(pc)  ; -> StoreCtxWord_AA6
  006178:  58 8f                addq.l   #$4, a7
  00617a:  2f 00                move.l   d0, -(a7)
  00617c:  20 5f                movea.l  (a7)+, a0
  00617e:  4e 90                jsr      (a0)
  006180:  20 2b 00 18          move.l   $18(a3), d0
  006184:  53 ab 00 18          subq.l   #$1, $18(a3)
  006188:  4a 80                tst.l    d0
  00618a:  6e 06                bgt.b    $6192  ; -> L6192
  00618c:  70 00                moveq    #$0, d0
  00618e:  27 40 00 18          move.l   d0, $18(a3)
L6192:
  006192:  4a ab 00 18          tst.l    $18(a3)
  006196:  66 0c                bne.b    $61a4  ; -> L61a4
  006198:  20 6b 00 1c          movea.l  $1c(a3), a0
  00619c:  43 ee ff f8          lea.l    -$8(a6), a1
  0061a0:  20 d9                move.l   (a1)+, (a0)+
  0061a2:  20 d9                move.l   (a1)+, (a0)+
L61a4:
  0061a4:  4c ee 18 c0 ff de    movem.l  -$22(a6), d6-d7/a3-a4
  0061aa:  4e 5e                unlk     a6
  0061ac:  4e 74 00 16          rtd      #$16
* s7_sub_494e  -  System 7 $494E (similar code, r=0.99).
s7_sub_494e:
  0061b0:  4e 56 ff fc          link.w   a6, #$fffc
  0061b4:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  0061b8:  28 6e 00 08          movea.l  $8(a6), a4
  0061bc:  20 54                movea.l  (a4), a0
  0061be:  20 3c 00 00 02 00    move.l   #$200, d0
  0061c4:  c0 a8 00 08          and.l    $8(a0), d0
  0061c8:  67 04                beq.b    $61ce  ; -> L61ce
  0061ca:  70 00                moveq    #$0, d0
  0061cc:  60 4c                bra.b    $621a  ; -> L621a
L61ce:
  0061ce:  70 00                moveq    #$0, d0
  0061d0:  20 54                movea.l  (a4), a0
  0061d2:  4a a8 00 1c          tst.l    $1c(a0)
  0061d6:  57 c0                seq.b    d0
  0061d8:  44 00                neg.b    d0
  0061da:  08 00 00 00          btst.b   #$0, d0
  0061de:  67 04                beq.b    $61e4  ; -> L61e4
  0061e0:  70 00                moveq    #$0, d0
  0061e2:  60 36                bra.b    $621a  ; -> L621a
L61e4:
  0061e4:  20 54                movea.l  (a4), a0
  0061e6:  20 68 00 0c          movea.l  $c(a0), a0
  0061ea:  47 e8 06 04          lea.l    $604(a0), a3
  0061ee:  2f 0b                move.l   a3, -(a7)
  0061f0:  4e ba e1 84          jsr      $4376(pc)  ; -> s7_sub_81bc
  0061f4:  2d 4b ff fc          move.l   a3, -$4(a6)
  0061f8:  70 01                moveq    #$1, d0
  0061fa:  2f 00                move.l   d0, -(a7)
  0061fc:  48 6e ff fc          pea.l    -$4(a6)
  006200:  72 17                moveq    #$17, d1
  006202:  2f 01                move.l   d1, -(a7)
  006204:  4e ba 00 1e          jsr      $6224(pc)  ; -> EngineDispatch
  006208:  2e 00                move.l   d0, d7
  00620a:  70 01                moveq    #$1, d0
  00620c:  b0 87                cmp.l    d7, d0
  00620e:  66 08                bne.b    $6218  ; -> L6218
  006210:  20 54                movea.l  (a4), a0
  006212:  21 6b 00 04 01 82    move.l   $4(a3), $182(a0)
L6218:
  006218:  20 07                move.l   d7, d0
L621a:
  00621a:  4c ee 18 80 ff f0    movem.l  -$10(a6), d7/a3-a4
  006220:  4e 5e                unlk     a6
  006222:  4e 75                rts
* EngineDispatch(cmd, args, n)  -  System 7 EngineDispatch $49C4.
* a3 = unit record ([[globals+$214]]).  Bails to $7AFE unless the unit's
* flags +$8 have $27 set and $600 clear; re-initialises the card through
* s7_sub_6f4e if unit+$1C says it is not ready.
EngineDispatch:
  006224:  4e 56 ff 98          link.w   a6, #$ff98
  006228:  48 e7 1f 38          movem.l  d3-d7/a2-a4, -(a7)
  00622c:  70 01                moveq    #$1, d0
  00622e:  2d 40 ff f8          move.l   d0, -$8(a6)
  006232:  22 38 08 88          move.l   $888.w, d1
  006236:  c2 bc 00 ff ff ff    and.l    #$ffffff, d1
  00623c:  20 41                movea.l  d1, a0
  00623e:  20 50                movea.l  (a0), a0
  006240:  20 50                movea.l  (a0), a0
  006242:  2d 68 02 14 ff fc    move.l   $214(a0), -$4(a6)
  006248:  20 6e ff fc          movea.l  -$4(a6), a0
  00624c:  26 50                movea.l  (a0), a3
  00624e:  72 27                moveq    #$27, d1
  006250:  c2 ab 00 08          and.l    $8(a3), d1
  006254:  74 27                moveq    #$27, d2
  006256:  b4 81                cmp.l    d1, d2
  006258:  66 00 18 a4          bne.w    $7afe  ; -> L7afe
  00625c:  20 3c 00 00 06 00    move.l   #$600, d0
  006262:  c0 ab 00 08          and.l    $8(a3), d0
  006266:  66 00 18 96          bne.w    $7afe  ; -> L7afe
  00626a:  70 01                moveq    #$1, d0
  00626c:  c0 ab 00 1c          and.l    $1c(a3), d0
  006270:  67 08                beq.b    $627a  ; -> L627a
  006272:  70 12                moveq    #$12, d0
  006274:  c0 ab 00 1c          and.l    $1c(a3), d0
  006278:  67 10                beq.b    $628a  ; -> L628a
L627a:
  00627a:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  00627e:  4e ba 25 ca          jsr      $884a(pc)  ; -> s7_sub_6f4e
  006282:  4a 80                tst.l    d0
  006284:  58 8f                addq.l   #$4, a7
  006286:  66 00 18 76          bne.w    $7afe  ; -> L7afe
L628a:
  00628a:  52 ab 01 14          addq.l   #$1, $114(a3)
* Selector switch: cmd - $0C indexes a 45-entry table ($0C..$38).
* Selectors below $0C, above $38 and the unlisted ones fall to L7748,
* the generic packet path (System 7: the same switch in EngineDispatch).
  00628e:  20 2e 00 08          move.l   $8(a6), d0
  006292:  04 80 00 00 00 0c    subi.l   #$c, d0
  006298:  6b 00 14 ae          bmi.w    $7748  ; -> L7748
  00629c:  0c 80 00 00 00 2c    cmpi.l   #$2c, d0
  0062a2:  6e 00 14 a4          bgt.w    $7748  ; -> L7748
  0062a6:  d0 80                add.l    d0, d0
  0062a8:  30 3b 08 06          move.w   $62b0(pc, d0.l), d0
  0062ac:  4e fb 00 00          jmp      $62ae(pc,d0.w)
  0062b0:  14 b4                dc.w     $14B4    ; [0] -> L7762
  0062b2:  14 9a                dc.w     $149A    ; [1] -> L7748
  0062b4:  14 9a                dc.w     $149A    ; [2] -> L7748
  0062b6:  14 9a                dc.w     $149A    ; [3] -> L7748
  0062b8:  10 64                dc.w     $1064    ; [4] -> L7312
  0062ba:  14 9a                dc.w     $149A    ; [5] -> L7748
  0062bc:  14 9a                dc.w     $149A    ; [6] -> L7748
  0062be:  14 9a                dc.w     $149A    ; [7] -> L7748
  0062c0:  14 9a                dc.w     $149A    ; [8] -> L7748
  0062c2:  14 9a                dc.w     $149A    ; [9] -> L7748
  0062c4:  14 9a                dc.w     $149A    ; [10] -> L7748
  0062c6:  14 9a                dc.w     $149A    ; [11] -> L7748
  0062c8:  00 5c                dc.w     $005C    ; [12] -> L630a
  0062ca:  14 9a                dc.w     $149A    ; [13] -> L7748
  0062cc:  14 9a                dc.w     $149A    ; [14] -> L7748
  0062ce:  14 9a                dc.w     $149A    ; [15] -> L7748
  0062d0:  14 9a                dc.w     $149A    ; [16] -> L7748
  0062d2:  14 9a                dc.w     $149A    ; [17] -> L7748
  0062d4:  14 9a                dc.w     $149A    ; [18] -> L7748
  0062d6:  14 9a                dc.w     $149A    ; [19] -> L7748
  0062d8:  00 5c                dc.w     $005C    ; [20] -> L630a
  0062da:  00 5c                dc.w     $005C    ; [21] -> L630a
  0062dc:  00 5c                dc.w     $005C    ; [22] -> L630a
  0062de:  00 5c                dc.w     $005C    ; [23] -> L630a
  0062e0:  00 5c                dc.w     $005C    ; [24] -> L630a
  0062e2:  14 9a                dc.w     $149A    ; [25] -> L7748
  0062e4:  13 cc                dc.w     $13CC    ; [26] -> L767a
  0062e6:  14 9a                dc.w     $149A    ; [27] -> L7748
  0062e8:  14 9a                dc.w     $149A    ; [28] -> L7748
  0062ea:  14 9a                dc.w     $149A    ; [29] -> L7748
  0062ec:  14 6c                dc.w     $146C    ; [30] -> L771a
  0062ee:  14 9a                dc.w     $149A    ; [31] -> L7748
  0062f0:  14 b4                dc.w     $14B4    ; [32] -> L7762
  0062f2:  14 b4                dc.w     $14B4    ; [33] -> L7762
  0062f4:  00 5c                dc.w     $005C    ; [34] -> L630a
  0062f6:  00 5c                dc.w     $005C    ; [35] -> L630a
  0062f8:  14 b4                dc.w     $14B4    ; [36] -> L7762
  0062fa:  00 5c                dc.w     $005C    ; [37] -> L630a
  0062fc:  0f ac                dc.w     $0FAC    ; [38] -> L725a
  0062fe:  14 9a                dc.w     $149A    ; [39] -> L7748
  006300:  18 18                dc.w     $1818    ; [40] -> L7ac6
  006302:  13 7e                dc.w     $137E    ; [41] -> L762c
  006304:  12 4a                dc.w     $124A    ; [42] -> L74f8
  006306:  11 16                dc.w     $1116    ; [43] -> L73c4
  006308:  14 28                dc.w     $1428    ; [44] -> L76d6
L630a:
  00630a:  42 05                clr.b    d5
  00630c:  42 6e ff ae          clr.w    -$52(a6)
  006310:  42 07                clr.b    d7
  006312:  42 06                clr.b    d6
  006314:  42 2e ff a8          clr.b    -$58(a6)
  006318:  42 2e ff a9          clr.b    -$57(a6)
  00631c:  42 6e ff aa          clr.w    -$56(a6)
  006320:  4e ba af 0e          jsr      $1230(pc)  ; -> GetA5
  006324:  20 40                movea.l  d0, a0
  006326:  20 50                movea.l  (a0), a0
  006328:  2d 50 ff da          move.l   (a0), -$26(a6)
  00632c:  66 0e                bne.b    $633c  ; -> L633c
  00632e:  70 14                moveq    #$14, d0
  006330:  2f 00                move.l   d0, -(a7)
  006332:  4e ba fd 60          jsr      $6094(pc)  ; -> s7_sub_4822
  006336:  58 8f                addq.l   #$4, a7
  006338:  60 00 17 c4          bra.w    $7afe  ; -> L7afe
L633c:
  00633c:  20 6e ff da          movea.l  -$26(a6), a0
  006340:  4a a8 00 5c          tst.l    $5c(a0)
  006344:  66 14                bne.b    $635a  ; -> L635a
  006346:  20 6e ff da          movea.l  -$26(a6), a0
  00634a:  4a a8 00 60          tst.l    $60(a0)
  00634e:  66 0a                bne.b    $635a  ; -> L635a
  006350:  20 6e ff da          movea.l  -$26(a6), a0
  006354:  4a a8 00 64          tst.l    $64(a0)
  006358:  67 24                beq.b    $637e  ; -> L637e
L635a:
  00635a:  70 02                moveq    #$2, d0
  00635c:  2d 40 ff f8          move.l   d0, -$8(a6)
  006360:  1d 78 09 38 ff ef    move.b   $938.w, -$11(a6)
  006366:  20 6e ff da          movea.l  -$26(a6), a0
  00636a:  2d 68 00 30 ff f0    move.l   $30(a0), -$10(a6)
  006370:  20 6e ff da          movea.l  -$26(a6), a0
  006374:  32 28 00 0e          move.w   $e(a0), d1
  006378:  48 c1                ext.l    d1
  00637a:  2d 41 ff f4          move.l   d1, -$c(a6)
L637e:
  00637e:  70 00                moveq    #$0, d0
  006380:  2d 40 ff c0          move.l   d0, -$40(a6)
  006384:  20 6e ff da          movea.l  -$26(a6), a0
  006388:  22 2b 01 24          move.l   $124(a3), d1
  00638c:  b2 a8 00 1c          cmp.l    $1c(a0), d1
  006390:  67 18                beq.b    $63aa  ; -> L63aa
  006392:  20 6e ff da          movea.l  -$26(a6), a0
  006396:  20 68 00 1c          movea.l  $1c(a0), a0
  00639a:  20 50                movea.l  (a0), a0
  00639c:  30 10                move.w   (a0), d0
  00639e:  48 c0                ext.l    d0
  0063a0:  5a 80                addq.l   #$5, d0
  0063a2:  72 fc                moveq    #$fc, d1
  0063a4:  c2 80                and.l    d0, d1
  0063a6:  d3 ae ff c0          add.l    d1, -$40(a6)
L63aa:
  0063aa:  20 6e ff da          movea.l  -$26(a6), a0
  0063ae:  20 2b 01 20          move.l   $120(a3), d0
  0063b2:  b0 a8 00 18          cmp.l    $18(a0), d0
  0063b6:  67 18                beq.b    $63d0  ; -> L63d0
  0063b8:  20 6e ff da          movea.l  -$26(a6), a0
  0063bc:  20 68 00 18          movea.l  $18(a0), a0
  0063c0:  20 50                movea.l  (a0), a0
  0063c2:  30 10                move.w   (a0), d0
  0063c4:  48 c0                ext.l    d0
  0063c6:  5a 80                addq.l   #$5, d0
  0063c8:  72 fc                moveq    #$fc, d1
  0063ca:  c2 80                and.l    d0, d1
  0063cc:  d3 ae ff c0          add.l    d1, -$40(a6)
L63d0:
  0063d0:  20 2b 00 bc          move.l   $bc(a3), d0
  0063d4:  90 bc 00 00 00 90    sub.l    #$90, d0
  0063da:  b0 ae ff c0          cmp.l    -$40(a6), d0
  0063de:  6c 0e                bge.b    $63ee  ; -> L63ee
  0063e0:  70 12                moveq    #$12, d0
  0063e2:  2f 00                move.l   d0, -(a7)
  0063e4:  4e ba fc ae          jsr      $6094(pc)  ; -> s7_sub_4822
  0063e8:  58 8f                addq.l   #$4, a7
  0063ea:  60 00 17 12          bra.w    $7afe  ; -> L7afe
L63ee:
  0063ee:  20 2e 00 08          move.l   $8(a6), d0
  0063f2:  04 80 00 00 00 18    subi.l   #$18, d0
  0063f8:  67 00 01 68          beq.w    $6562  ; -> L6562
  0063fc:  51 80                subq.l   #$8, d0
  0063fe:  67 00 00 be          beq.w    $64be  ; -> L64be
  006402:  53 80                subq.l   #$1, d0
  006404:  67 1a                beq.b    $6420  ; -> L6420
  006406:  53 80                subq.l   #$1, d0
  006408:  67 00 02 02          beq.w    $660c  ; -> L660c
  00640c:  04 80 00 00 00 0c    subi.l   #$c, d0
  006412:  67 00 00 c4          beq.w    $64d8  ; -> L64d8
  006416:  57 80                subq.l   #$3, d0
  006418:  67 00 00 de          beq.w    $64f8  ; -> L64f8
  00641c:  60 00 02 22          bra.w    $6640  ; -> L6640
L6420:
  006420:  48 6b 01 0e          pea.l    $10e(a3)
  006424:  48 6b 01 0a          pea.l    $10a(a3)
  006428:  2f 2e ff da          move.l   -$26(a6), -(a7)
  00642c:  4e ba af 9e          jsr      $13cc(pc)  ; -> s7_sub_8da4
  006430:  1e 00                move.b   d0, d7
  006432:  48 6e ff ae          pea.l    -$52(a6)
  006436:  48 6e ff aa          pea.l    -$56(a6)
  00643a:  48 6e ff ac          pea.l    -$54(a6)
  00643e:  70 05                moveq    #$5, d0
  006440:  2f 00                move.l   d0, -(a7)
  006442:  4e ba b0 18          jsr      $145c(pc)  ; -> s7_sub_8e38
  006446:  70 00                moveq    #$0, d0
  006448:  30 2b 00 cc          move.w   $cc(a3), d0
  00644c:  32 2e ff ac          move.w   -$54(a6), d1
  006450:  48 c1                ext.l    d1
  006452:  b0 81                cmp.l    d1, d0
  006454:  4f ef 00 1c          lea.l    $1c(a7), a7
  006458:  67 02                beq.b    $645c  ; -> L645c
  00645a:  7c 01                moveq    #$1, d6
L645c:
  00645c:  20 6e 00 0c          movea.l  $c(a6), a0
  006460:  2d 50 ff bc          move.l   (a0), -$44(a6)
  006464:  20 2e ff c0          move.l   -$40(a6), d0
  006468:  d0 bc 00 00 00 90    add.l    #$90, d0
  00646e:  22 2e ff bc          move.l   -$44(a6), d1
  006472:  74 13                moveq    #$13, d2
  006474:  d2 82                add.l    d2, d1
  006476:  76 fc                moveq    #$fc, d3
  006478:  c6 81                and.l    d1, d3
  00647a:  d6 80                add.l    d0, d3
  00647c:  20 2b 00 bc          move.l   $bc(a3), d0
  006480:  90 83                sub.l    d3, d0
  006482:  b0 ab 00 c0          cmp.l    $c0(a3), d0
  006486:  6e 00 01 b8          bgt.w    $6640  ; -> L6640
  00648a:  70 10                moveq    #$10, d0
  00648c:  2f 00                move.l   d0, -(a7)
  00648e:  4e ba fc 04          jsr      $6094(pc)  ; -> s7_sub_4822
  006492:  20 2e ff c0          move.l   -$40(a6), d0
  006496:  d0 bc 00 00 00 90    add.l    #$90, d0
  00649c:  22 2e ff bc          move.l   -$44(a6), d1
  0064a0:  74 13                moveq    #$13, d2
  0064a2:  d2 82                add.l    d2, d1
  0064a4:  76 fc                moveq    #$fc, d3
  0064a6:  c6 81                and.l    d1, d3
  0064a8:  d6 80                add.l    d0, d3
  0064aa:  20 2b 00 bc          move.l   $bc(a3), d0
  0064ae:  90 83                sub.l    d3, d0
  0064b0:  b0 ab 00 c0          cmp.l    $c0(a3), d0
  0064b4:  58 8f                addq.l   #$4, a7
  0064b6:  6f 00 16 46          ble.w    $7afe  ; -> L7afe
  0064ba:  60 00 01 84          bra.w    $6640  ; -> L6640
L64be:
  0064be:  48 6b 01 0e          pea.l    $10e(a3)
  0064c2:  48 6b 01 0a          pea.l    $10a(a3)
  0064c6:  2f 2e ff da          move.l   -$26(a6), -(a7)
  0064ca:  4e ba af 00          jsr      $13cc(pc)  ; -> s7_sub_8da4
  0064ce:  1e 00                move.b   d0, d7
  0064d0:  4f ef 00 0c          lea.l    $c(a7), a7
  0064d4:  60 00 01 6a          bra.w    $6640  ; -> L6640
L64d8:
  0064d8:  20 6e 00 0c          movea.l  $c(a6), a0
  0064dc:  4a a8 00 08          tst.l    $8(a0)
  0064e0:  67 0c                beq.b    $64ee  ; -> L64ee
  0064e2:  20 6e 00 0c          movea.l  $c(a6), a0
  0064e6:  4a a8 00 0c          tst.l    $c(a0)
  0064ea:  66 00 01 54          bne.w    $6640  ; -> L6640
L64ee:
  0064ee:  70 24                moveq    #$24, d0
  0064f0:  2d 40 00 08          move.l   d0, $8(a6)
  0064f4:  60 00 01 4a          bra.w    $6640  ; -> L6640
L64f8:
  0064f8:  20 2e ff c0          move.l   -$40(a6), d0
  0064fc:  d0 bc 00 00 00 90    add.l    #$90, d0
  006502:  20 6e 00 0c          movea.l  $c(a6), a0
  006506:  20 68 00 04          movea.l  $4(a0), a0
  00650a:  20 50                movea.l  (a0), a0
  00650c:  32 10                move.w   (a0), d1
  00650e:  48 c1                ext.l    d1
  006510:  5e 81                addq.l   #$7, d1
  006512:  74 fc                moveq    #$fc, d2
  006514:  c4 81                and.l    d1, d2
  006516:  d4 80                add.l    d0, d2
  006518:  20 2b 00 bc          move.l   $bc(a3), d0
  00651c:  90 82                sub.l    d2, d0
  00651e:  b0 ab 00 c0          cmp.l    $c0(a3), d0
  006522:  6e 00 01 1c          bgt.w    $6640  ; -> L6640
  006526:  70 06                moveq    #$6, d0
  006528:  2f 00                move.l   d0, -(a7)
  00652a:  4e ba fb 68          jsr      $6094(pc)  ; -> s7_sub_4822
  00652e:  20 2e ff c0          move.l   -$40(a6), d0
  006532:  d0 bc 00 00 00 90    add.l    #$90, d0
  006538:  20 6e 00 0c          movea.l  $c(a6), a0
  00653c:  20 68 00 04          movea.l  $4(a0), a0
  006540:  20 50                movea.l  (a0), a0
  006542:  32 10                move.w   (a0), d1
  006544:  48 c1                ext.l    d1
  006546:  5e 81                addq.l   #$7, d1
  006548:  74 fc                moveq    #$fc, d2
  00654a:  c4 81                and.l    d1, d2
  00654c:  d4 80                add.l    d0, d2
  00654e:  20 2b 00 bc          move.l   $bc(a3), d0
  006552:  90 82                sub.l    d2, d0
  006554:  b0 ab 00 c0          cmp.l    $c0(a3), d0
  006558:  58 8f                addq.l   #$4, a7
  00655a:  6f 00 15 a2          ble.w    $7afe  ; -> L7afe
  00655e:  60 00 00 e0          bra.w    $6640  ; -> L6640
L6562:
  006562:  20 6e 00 0c          movea.l  $c(a6), a0
  006566:  20 68 00 04          movea.l  $4(a0), a0
  00656a:  20 50                movea.l  (a0), a0
  00656c:  30 10                move.w   (a0), d0
  00656e:  48 c0                ext.l    d0
  006570:  72 0a                moveq    #$a, d1
  006572:  b2 80                cmp.l    d0, d1
  006574:  66 30                bne.b    $65a6  ; -> L65a6
  006576:  70 24                moveq    #$24, d0
  006578:  2d 40 00 08          move.l   d0, $8(a6)
  00657c:  20 6e 00 0c          movea.l  $c(a6), a0
  006580:  20 68 00 04          movea.l  $4(a0), a0
  006584:  22 10                move.l   (a0), d1
  006586:  54 81                addq.l   #$2, d1
  006588:  2f 01                move.l   d1, -(a7)
  00658a:  48 6e ff e6          pea.l    -$1a(a6)
  00658e:  72 08                moveq    #$8, d1
  006590:  2f 01                move.l   d1, -(a7)
  006592:  4e ba 3f 2a          jsr      $a4be(pc)  ; -> sub_a4be
  006596:  41 ee ff e6          lea.l    -$1a(a6), a0
  00659a:  22 6e 00 0c          movea.l  $c(a6), a1
  00659e:  23 48 00 04          move.l   a0, $4(a1)
  0065a2:  60 00 00 9c          bra.w    $6640  ; -> L6640
L65a6:
  0065a6:  20 2e ff c0          move.l   -$40(a6), d0
  0065aa:  d0 bc 00 00 00 90    add.l    #$90, d0
  0065b0:  20 6e 00 0c          movea.l  $c(a6), a0
  0065b4:  20 68 00 04          movea.l  $4(a0), a0
  0065b8:  20 50                movea.l  (a0), a0
  0065ba:  32 10                move.w   (a0), d1
  0065bc:  48 c1                ext.l    d1
  0065be:  5e 81                addq.l   #$7, d1
  0065c0:  74 fc                moveq    #$fc, d2
  0065c2:  c4 81                and.l    d1, d2
  0065c4:  d4 80                add.l    d0, d2
  0065c6:  20 2b 00 bc          move.l   $bc(a3), d0
  0065ca:  90 82                sub.l    d2, d0
  0065cc:  b0 ab 00 c0          cmp.l    $c0(a3), d0
  0065d0:  6e 6e                bgt.b    $6640  ; -> L6640
  0065d2:  70 15                moveq    #$15, d0
  0065d4:  2f 00                move.l   d0, -(a7)
  0065d6:  4e ba fa bc          jsr      $6094(pc)  ; -> s7_sub_4822
  0065da:  20 2e ff c0          move.l   -$40(a6), d0
  0065de:  d0 bc 00 00 00 90    add.l    #$90, d0
  0065e4:  20 6e 00 0c          movea.l  $c(a6), a0
  0065e8:  20 68 00 04          movea.l  $4(a0), a0
  0065ec:  20 50                movea.l  (a0), a0
  0065ee:  32 10                move.w   (a0), d1
  0065f0:  48 c1                ext.l    d1
  0065f2:  5e 81                addq.l   #$7, d1
  0065f4:  74 fc                moveq    #$fc, d2
  0065f6:  c4 81                and.l    d1, d2
  0065f8:  d4 80                add.l    d0, d2
  0065fa:  20 2b 00 bc          move.l   $bc(a3), d0
  0065fe:  90 82                sub.l    d2, d0
  006600:  b0 ab 00 c0          cmp.l    $c0(a3), d0
  006604:  58 8f                addq.l   #$4, a7
  006606:  6f 00 14 f6          ble.w    $7afe  ; -> L7afe
  00660a:  60 34                bra.b    $6640  ; -> L6640
L660c:
  00660c:  20 2e ff c0          move.l   -$40(a6), d0
  006610:  d0 bc 00 00 00 d8    add.l    #$d8, d0
  006616:  20 6e 00 0c          movea.l  $c(a6), a0
  00661a:  22 10                move.l   (a0), d1
  00661c:  74 27                moveq    #$27, d2
  00661e:  d2 82                add.l    d2, d1
  006620:  76 fc                moveq    #$fc, d3
  006622:  c6 81                and.l    d1, d3
  006624:  d6 80                add.l    d0, d3
  006626:  20 2b 00 bc          move.l   $bc(a3), d0
  00662a:  90 83                sub.l    d3, d0
  00662c:  b0 ab 00 c0          cmp.l    $c0(a3), d0
  006630:  6e 0e                bgt.b    $6640  ; -> L6640
  006632:  70 1b                moveq    #$1b, d0
  006634:  2f 00                move.l   d0, -(a7)
  006636:  4e ba fa 5c          jsr      $6094(pc)  ; -> s7_sub_4822
  00663a:  58 8f                addq.l   #$4, a7
  00663c:  60 00 14 c0          bra.w    $7afe  ; -> L7afe
L6640:
  006640:  70 04                moveq    #$4, d0
  006642:  b0 ab 00 c0          cmp.l    $c0(a3), d0
  006646:  6c 3c                bge.b    $6684  ; -> L6684
  006648:  20 2e ff da          move.l   -$26(a6), d0
  00664c:  b0 ab 00 c8          cmp.l    $c8(a3), d0
  006650:  67 12                beq.b    $6664  ; -> L6664
  006652:  4a ab 00 c8          tst.l    $c8(a3)
  006656:  67 0c                beq.b    $6664  ; -> L6664
  006658:  70 08                moveq    #$8, d0
  00665a:  2f 00                move.l   d0, -(a7)
  00665c:  4e ba fa 36          jsr      $6094(pc)  ; -> s7_sub_4822
  006660:  58 8f                addq.l   #$4, a7
  006662:  60 20                bra.b    $6684  ; -> L6684
L6664:
  006664:  20 2e ff c0          move.l   -$40(a6), d0
  006668:  d0 bc 00 00 00 90    add.l    #$90, d0
  00666e:  22 2b 00 bc          move.l   $bc(a3), d1
  006672:  92 80                sub.l    d0, d1
  006674:  b2 ab 00 c0          cmp.l    $c0(a3), d1
  006678:  6e 0a                bgt.b    $6684  ; -> L6684
  00667a:  70 09                moveq    #$9, d0
  00667c:  2f 00                move.l   d0, -(a7)
  00667e:  4e ba fa 14          jsr      $6094(pc)  ; -> s7_sub_4822
  006682:  58 8f                addq.l   #$4, a7
L6684:
  006684:  20 2e ff da          move.l   -$26(a6), d0
  006688:  b0 ab 00 c8          cmp.l    $c8(a3), d0
  00668c:  67 00 01 48          beq.w    $67d6  ; -> L67d6
  006690:  20 6b 00 0c          movea.l  $c(a3), a0
  006694:  41 e8 01 70          lea.l    $170(a0), a0
  006698:  2d 48 ff a4          move.l   a0, -$5c(a6)
  00669c:  70 00                moveq    #$0, d0
  00669e:  2f 00                move.l   d0, -(a7)
  0066a0:  2f 00                move.l   d0, -(a7)
  0066a2:  2f 00                move.l   d0, -(a7)
  0066a4:  4e ba fb 7e          jsr      $6224(pc)  ; -> EngineDispatch
  0066a8:  2f 2e ff a4          move.l   -$5c(a6), -(a7)
  0066ac:  4e ba e0 c6          jsr      $4774(pc)  ; -> s7_sub_860e
  0066b0:  20 6e ff a4          movea.l  -$5c(a6), a0
  0066b4:  43 eb 01 18          lea.l    $118(a3), a1
  0066b8:  41 e8 00 14          lea.l    $14(a0), a0
  0066bc:  22 d8                move.l   (a0)+, (a1)+
  0066be:  22 d8                move.l   (a0)+, (a1)+
  0066c0:  2d 6e ff a4 ff de    move.l   -$5c(a6), -$22(a6)
  0066c6:  27 6b 00 ac 00 b4    move.l   $ac(a3), $b4(a3)
  0066cc:  20 2b 00 ac          move.l   $ac(a3), d0
  0066d0:  58 80                addq.l   #$4, d0
  0066d2:  27 40 00 b0          move.l   d0, $b0(a3)
  0066d6:  20 6b 00 ac          movea.l  $ac(a3), a0
  0066da:  30 bc 00 6f          move.w   #$6f, (a0)
  0066de:  70 04                moveq    #$4, d0
  0066e0:  27 40 00 c0          move.l   d0, $c0(a3)
  0066e4:  20 6e ff a4          movea.l  -$5c(a6), a0
  0066e8:  21 40 00 50          move.l   d0, $50(a0)
  0066ec:  20 6e ff a4          movea.l  -$5c(a6), a0
  0066f0:  21 6b 00 c4 00 4c    move.l   $c4(a3), $4c(a0)
  0066f6:  72 00                moveq    #$0, d1
  0066f8:  2f 01                move.l   d1, -(a7)
  0066fa:  48 6e ff de          pea.l    -$22(a6)
  0066fe:  70 2d                moveq    #$2d, d0
  006700:  2f 00                move.l   d0, -(a7)
  006702:  4e ba fb 20          jsr      $6224(pc)  ; -> EngineDispatch
  006706:  37 40 00 ce          move.w   d0, $ce(a3)
  00670a:  70 00                moveq    #$0, d0
  00670c:  30 2b 00 ce          move.w   $ce(a3), d0
  006710:  08 00 00 00          btst.b   #$0, d0
  006714:  4f ef 00 1c          lea.l    $1c(a7), a7
  006718:  67 3a                beq.b    $6754  ; -> L6754
  00671a:  70 00                moveq    #$0, d0
  00671c:  30 2b 00 ce          move.w   $ce(a3), d0
  006720:  72 06                moveq    #$6, d1
  006722:  c2 80                and.l    d0, d1
  006724:  2d 41 ff de          move.l   d1, -$22(a6)
  006728:  27 6e ff da 00 c8    move.l   -$26(a6), $c8(a3)
  00672e:  70 01                moveq    #$1, d0
  006730:  2f 00                move.l   d0, -(a7)
  006732:  48 6e ff de          pea.l    -$22(a6)
  006736:  72 36                moveq    #$36, d1
  006738:  2f 01                move.l   d1, -(a7)
  00673a:  4e ba fa e8          jsr      $6224(pc)  ; -> EngineDispatch
  00673e:  70 01                moveq    #$1, d0
  006740:  2f 00                move.l   d0, -(a7)
  006742:  48 6e ff de          pea.l    -$22(a6)
  006746:  72 37                moveq    #$37, d1
  006748:  2f 01                move.l   d1, -(a7)
  00674a:  4e ba fa d8          jsr      $6224(pc)  ; -> EngineDispatch
  00674e:  4f ef 00 18          lea.l    $18(a7), a7
  006752:  60 0e                bra.b    $6762  ; -> L6762
L6754:
  006754:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  006758:  4e ba 14 fc          jsr      $7c56(pc)  ; -> s7_sub_63b0
  00675c:  58 8f                addq.l   #$4, a7
  00675e:  60 00 13 9e          bra.w    $7afe  ; -> L7afe
L6762:
  006762:  7c 01                moveq    #$1, d6
  006764:  1d 7c 00 01 ff a8    move.b   #$1, -$58(a6)
  00676a:  20 6e ff da          movea.l  -$26(a6), a0
  00676e:  27 68 00 30 01 0a    move.l   $30(a0), $10a(a3)
  006774:  20 6e ff da          movea.l  -$26(a6), a0
  006778:  30 28 00 06          move.w   $6(a0), d0
  00677c:  48 c0                ext.l    d0
  00677e:  6c 0c                bge.b    $678c  ; -> L678c
  006780:  20 6e ff da          movea.l  -$26(a6), a0
  006784:  30 28 00 0e          move.w   $e(a0), d0
  006788:  48 c0                ext.l    d0
  00678a:  60 06                bra.b    $6792  ; -> L6792
L678c:
  00678c:  20 3c 00 00 80 00    move.l   #$8000, d0
L6792:
  006792:  37 40 01 0e          move.w   d0, $10e(a3)
  006796:  7e 01                moveq    #$1, d7
  006798:  48 6b 00 e2          pea.l    $e2(a3)
  00679c:  48 6b 00 dc          pea.l    $dc(a3)
  0067a0:  2f 2b 00 c8          move.l   $c8(a3), -(a7)
  0067a4:  4e ba ac 76          jsr      $141c(pc)  ; -> s7_sub_8df2
  0067a8:  53 6b 00 dc          subq.w   #$1, $dc(a3)
  0067ac:  53 6b 00 e2          subq.w   #$1, $e2(a3)
  0067b0:  02 6b ff f0 00 f2    andi.w   #$fff0, $f2(a3)
  0067b6:  00 6b 00 0f 00 f2    ori.w    #$f, $f2(a3)
  0067bc:  4e ba aa 72          jsr      $1230(pc)  ; -> GetA5
  0067c0:  20 40                movea.l  d0, a0
  0067c2:  20 10                move.l   (a0), d0
  0067c4:  90 bc 00 00 00 ca    sub.l    #$ca, d0
  0067ca:  20 40                movea.l  d0, a0
  0067cc:  27 68 00 22 00 e8    move.l   $22(a0), $e8(a3)
  0067d2:  4f ef 00 0c          lea.l    $c(a7), a7
L67d6:
  0067d6:  70 21                moveq    #$21, d0
  0067d8:  b0 ae 00 08          cmp.l    $8(a6), d0
  0067dc:  66 00 00 a8          bne.w    $6886  ; -> L6886
  0067e0:  2f 2b 01 82          move.l   $182(a3), -(a7)
  0067e4:  48 6b 01 ac          pea.l    $1ac(a3)
  0067e8:  48 6b 01 06          pea.l    $106(a3)
  0067ec:  48 6b 01 92          pea.l    $192(a3)
  0067f0:  48 6e ff b0          pea.l    -$50(a6)
  0067f4:  48 6e ff b8          pea.l    -$48(a6)
  0067f8:  48 6e ff b4          pea.l    -$4c(a6)
  0067fc:  20 6e 00 0c          movea.l  $c(a6), a0
  006800:  20 68 00 0c          movea.l  $c(a0), a0
  006804:  2f 10                move.l   (a0), -(a7)
  006806:  20 6e 00 0c          movea.l  $c(a6), a0
  00680a:  20 68 00 08          movea.l  $8(a0), a0
  00680e:  2f 10                move.l   (a0), -(a7)
  006810:  2f 2e ff bc          move.l   -$44(a6), -(a7)
  006814:  20 6e 00 0c          movea.l  $c(a6), a0
  006818:  2f 28 00 04          move.l   $4(a0), -(a7)
  00681c:  4e ba e2 26          jsr      $4a44(pc)  ; -> s7_sub_88e6
  006820:  2d 40 ff a4          move.l   d0, -$5c(a6)
  006824:  72 ff                moveq    #$ff, d1
  006826:  b2 80                cmp.l    d0, d1
  006828:  4f ef 00 2c          lea.l    $2c(a7), a7
  00682c:  66 0e                bne.b    $683c  ; -> L683c
  00682e:  70 05                moveq    #$5, d0
  006830:  2f 00                move.l   d0, -(a7)
  006832:  4e ba f8 60          jsr      $6094(pc)  ; -> s7_sub_4822
  006836:  58 8f                addq.l   #$4, a7
  006838:  60 00 12 c4          bra.w    $7afe  ; -> L7afe
L683c:
  00683c:  70 01                moveq    #$1, d0
  00683e:  b0 ae ff a4          cmp.l    -$5c(a6), d0
  006842:  66 06                bne.b    $684a  ; -> L684a
  006844:  1d 7c 00 01 ff a9    move.b   #$1, -$57(a6)
L684a:
  00684a:  20 2e ff bc          move.l   -$44(a6), d0
  00684e:  72 13                moveq    #$13, d1
  006850:  d0 81                add.l    d1, d0
  006852:  74 fc                moveq    #$fc, d2
  006854:  c4 80                and.l    d0, d2
  006856:  d4 bc 00 00 00 90    add.l    #$90, d2
  00685c:  4a 2e ff a9          tst.b    -$57(a6)
  006860:  67 04                beq.b    $6866  ; -> L6866
  006862:  70 20                moveq    #$20, d0
  006864:  60 02                bra.b    $6868  ; -> L6868
L6866:
  006866:  70 00                moveq    #$0, d0
L6868:
  006868:  d0 82                add.l    d2, d0
  00686a:  22 2b 00 bc          move.l   $bc(a3), d1
  00686e:  92 80                sub.l    d0, d1
  006870:  b2 ab 00 c0          cmp.l    $c0(a3), d1
  006874:  6e 00 00 8e          bgt.w    $6904  ; -> L6904
  006878:  70 10                moveq    #$10, d0
  00687a:  2f 00                move.l   d0, -(a7)
  00687c:  4e ba f8 16          jsr      $6094(pc)  ; -> s7_sub_4822
  006880:  58 8f                addq.l   #$4, a7
  006882:  60 00 12 7a          bra.w    $7afe  ; -> L7afe
L6886:
  006886:  70 22                moveq    #$22, d0
  006888:  b0 ae 00 08          cmp.l    $8(a6), d0
  00688c:  67 76                beq.b    $6904  ; -> L6904
  00688e:  48 6e ff ae          pea.l    -$52(a6)
  006892:  48 6e ff aa          pea.l    -$56(a6)
  006896:  48 6e ff ac          pea.l    -$54(a6)
  00689a:  70 20                moveq    #$20, d0
  00689c:  b0 ae 00 08          cmp.l    $8(a6), d0
  0068a0:  66 04                bne.b    $68a6  ; -> L68a6
  0068a2:  70 00                moveq    #$0, d0
  0068a4:  60 06                bra.b    $68ac  ; -> L68ac
L68a6:
  0068a6:  20 6e 00 0c          movea.l  $c(a6), a0
  0068aa:  20 10                move.l   (a0), d0
L68ac:
  0068ac:  2f 00                move.l   d0, -(a7)
  0068ae:  4e ba ab ac          jsr      $145c(pc)  ; -> s7_sub_8e38
  0068b2:  70 00                moveq    #$0, d0
  0068b4:  30 2b 00 cc          move.w   $cc(a3), d0
  0068b8:  32 2e ff ac          move.w   -$54(a6), d1
  0068bc:  48 c1                ext.l    d1
  0068be:  b0 81                cmp.l    d1, d0
  0068c0:  4f ef 00 10          lea.l    $10(a7), a7
  0068c4:  67 02                beq.b    $68c8  ; -> L68c8
  0068c6:  7c 01                moveq    #$1, d6
L68c8:
  0068c8:  30 2b 00 f2          move.w   $f2(a3), d0
  0068cc:  48 c0                ext.l    d0
  0068ce:  c0 bc 00 00 00 0f    and.l    #$f, d0
  0068d4:  32 2e ff ae          move.w   -$52(a6), d1
  0068d8:  48 c1                ext.l    d1
  0068da:  b0 81                cmp.l    d1, d0
  0068dc:  67 06                beq.b    $68e4  ; -> L68e4
  0068de:  1d 7c 00 01 ff a8    move.b   #$1, -$58(a6)
L68e4:
  0068e4:  4a 6e ff aa          tst.w    -$56(a6)
  0068e8:  67 1a                beq.b    $6904  ; -> L6904
  0068ea:  30 2e ff ac          move.w   -$54(a6), d0
  0068ee:  48 c0                ext.l    d0
  0068f0:  72 0a                moveq    #$a, d1
  0068f2:  b2 80                cmp.l    d0, d1
  0068f4:  67 0c                beq.b    $6902  ; -> L6902
  0068f6:  30 2e ff ac          move.w   -$54(a6), d0
  0068fa:  48 c0                ext.l    d0
  0068fc:  72 0e                moveq    #$e, d1
  0068fe:  b2 80                cmp.l    d0, d1
  006900:  66 02                bne.b    $6904  ; -> L6904
L6902:
  006902:  7a 01                moveq    #$1, d5
L6904:
  006904:  41 eb 00 ec          lea.l    $ec(a3), a0
  006908:  22 6e ff da          movea.l  -$26(a6), a1
  00690c:  43 e9 00 34          lea.l    $34(a1), a1
  006910:  70 00                moveq    #$0, d0
L6912:
  006912:  b1 89                cmpm.l   (a1)+, (a0)+
  006914:  56 c8 ff fc          dbne     d0, $6912  ; -> L6912
  006918:  67 1e                beq.b    $6938  ; -> L6938
  00691a:  20 6e ff da          movea.l  -$26(a6), a0
  00691e:  2d 68 00 34 ff de    move.l   $34(a0), -$22(a6)
  006924:  70 01                moveq    #$1, d0
  006926:  2f 00                move.l   d0, -(a7)
  006928:  48 6e ff de          pea.l    -$22(a6)
  00692c:  72 35                moveq    #$35, d1
  00692e:  2f 01                move.l   d1, -(a7)
  006930:  4e ba f8 f2          jsr      $6224(pc)  ; -> EngineDispatch
  006934:  4f ef 00 0c          lea.l    $c(a7), a7
L6938:
  006938:  20 6e ff da          movea.l  -$26(a6), a0
  00693c:  20 2b 01 24          move.l   $124(a3), d0
  006940:  b0 a8 00 1c          cmp.l    $1c(a0), d0
  006944:  67 1e                beq.b    $6964  ; -> L6964
  006946:  20 6e ff da          movea.l  -$26(a6), a0
  00694a:  2d 68 00 1c ff de    move.l   $1c(a0), -$22(a6)
  006950:  70 01                moveq    #$1, d0
  006952:  2f 00                move.l   d0, -(a7)
  006954:  48 6e ff de          pea.l    -$22(a6)
  006958:  72 32                moveq    #$32, d1
  00695a:  2f 01                move.l   d1, -(a7)
  00695c:  4e ba f8 c6          jsr      $6224(pc)  ; -> EngineDispatch
  006960:  4f ef 00 0c          lea.l    $c(a7), a7
L6964:
  006964:  20 6e ff da          movea.l  -$26(a6), a0
  006968:  20 2b 01 20          move.l   $120(a3), d0
  00696c:  b0 a8 00 18          cmp.l    $18(a0), d0
  006970:  67 1e                beq.b    $6990  ; -> L6990
  006972:  20 6e ff da          movea.l  -$26(a6), a0
  006976:  2d 68 00 18 ff de    move.l   $18(a0), -$22(a6)
  00697c:  70 01                moveq    #$1, d0
  00697e:  2f 00                move.l   d0, -(a7)
  006980:  48 6e ff de          pea.l    -$22(a6)
  006984:  72 10                moveq    #$10, d1
  006986:  2f 01                move.l   d1, -(a7)
  006988:  4e ba f8 9a          jsr      $6224(pc)  ; -> EngineDispatch
  00698c:  4f ef 00 0c          lea.l    $c(a7), a7
L6990:
  006990:  4a 06                tst.b    d6
  006992:  67 2e                beq.b    $69c2  ; -> L69c2
  006994:  20 6b 00 b0          movea.l  $b0(a3), a0
  006998:  30 bc 00 69          move.w   #$69, (a0)
  00699c:  20 6b 00 b0          movea.l  $b0(a3), a0
  0069a0:  31 6e ff ac 00 02    move.w   -$54(a6), $2(a0)
  0069a6:  37 6e ff ac 00 cc    move.w   -$54(a6), $cc(a3)
  0069ac:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  0069b2:  78 04                moveq    #$4, d4
  0069b4:  20 04                move.l   d4, d0
  0069b6:  d0 ab 00 b0          add.l    $b0(a3), d0
  0069ba:  27 40 00 b0          move.l   d0, $b0(a3)
  0069be:  d9 ab 00 c0          add.l    d4, $c0(a3)
L69c2:
  0069c2:  30 2e ff ac          move.w   -$54(a6), d0
  0069c6:  48 c0                ext.l    d0
  0069c8:  72 20                moveq    #$20, d1
  0069ca:  c2 80                and.l    d0, d1
  0069cc:  67 00 00 8e          beq.w    $6a5c  ; -> L6a5c
  0069d0:  48 6e ff a2          pea.l    -$5e(a6)
  0069d4:  48 6e ff 9c          pea.l    -$64(a6)
  0069d8:  2f 2b 00 c8          move.l   $c8(a3), -(a7)
  0069dc:  4e ba aa 3e          jsr      $141c(pc)  ; -> s7_sub_8df2
  0069e0:  41 eb 00 dc          lea.l    $dc(a3), a0
  0069e4:  43 ee ff 9c          lea.l    -$64(a6), a1
  0069e8:  70 02                moveq    #$2, d0
L69ea:
  0069ea:  b1 49                cmpm.w   (a1)+, (a0)+
  0069ec:  56 c8 ff fc          dbne     d0, $69ea  ; -> L69ea
  0069f0:  4f ef 00 0c          lea.l    $c(a7), a7
  0069f4:  66 12                bne.b    $6a08  ; -> L6a08
  0069f6:  41 eb 00 e2          lea.l    $e2(a3), a0
  0069fa:  43 ee ff a2          lea.l    -$5e(a6), a1
  0069fe:  70 02                moveq    #$2, d0
L6a00:
  006a00:  b1 49                cmpm.w   (a1)+, (a0)+
  006a02:  56 c8 ff fc          dbne     d0, $6a00  ; -> L6a00
  006a06:  67 54                beq.b    $6a5c  ; -> L6a5c
L6a08:
  006a08:  20 6b 00 b0          movea.l  $b0(a3), a0
  006a0c:  30 bc 00 70          move.w   #$70, (a0)
  006a10:  20 6b 00 b0          movea.l  $b0(a3), a0
  006a14:  43 ee ff 9c          lea.l    -$64(a6), a1
  006a18:  45 e8 00 04          lea.l    $4(a0), a2
  006a1c:  24 d9                move.l   (a1)+, (a2)+
  006a1e:  34 d9                move.w   (a1)+, (a2)+
  006a20:  43 eb 00 dc          lea.l    $dc(a3), a1
  006a24:  58 88                addq.l   #$4, a0
  006a26:  22 d8                move.l   (a0)+, (a1)+
  006a28:  32 d8                move.w   (a0)+, (a1)+
  006a2a:  20 6b 00 b0          movea.l  $b0(a3), a0
  006a2e:  43 ee ff a2          lea.l    -$5e(a6), a1
  006a32:  45 e8 00 0a          lea.l    $a(a0), a2
  006a36:  24 d9                move.l   (a1)+, (a2)+
  006a38:  34 d9                move.w   (a1)+, (a2)+
  006a3a:  43 eb 00 e2          lea.l    $e2(a3), a1
  006a3e:  41 e8 00 0a          lea.l    $a(a0), a0
  006a42:  22 d8                move.l   (a0)+, (a1)+
  006a44:  32 d8                move.w   (a0)+, (a1)+
  006a46:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  006a4c:  78 10                moveq    #$10, d4
  006a4e:  20 04                move.l   d4, d0
  006a50:  d0 ab 00 b0          add.l    $b0(a3), d0
  006a54:  27 40 00 b0          move.l   d0, $b0(a3)
  006a58:  d9 ab 00 c0          add.l    d4, $c0(a3)
L6a5c:
  006a5c:  4a 07                tst.b    d7
  006a5e:  67 52                beq.b    $6ab2  ; -> L6ab2
  006a60:  20 6e ff da          movea.l  -$26(a6), a0
  006a64:  21 6b 01 0a 00 30    move.l   $10a(a3), $30(a0)
  006a6a:  20 6e ff da          movea.l  -$26(a6), a0
  006a6e:  30 28 00 06          move.w   $6(a0), d0
  006a72:  48 c0                ext.l    d0
  006a74:  6c 0a                bge.b    $6a80  ; -> L6a80
  006a76:  20 6e ff da          movea.l  -$26(a6), a0
  006a7a:  31 6b 01 0e 00 0e    move.w   $10e(a3), $e(a0)
L6a80:
  006a80:  20 6b 00 b0          movea.l  $b0(a3), a0
  006a84:  30 bc 00 68          move.w   #$68, (a0)
  006a88:  20 6b 00 b0          movea.l  $b0(a3), a0
  006a8c:  21 6b 01 0a 00 04    move.l   $10a(a3), $4(a0)
  006a92:  20 6b 00 b0          movea.l  $b0(a3), a0
  006a96:  31 6b 01 0e 00 02    move.w   $10e(a3), $2(a0)
  006a9c:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  006aa2:  78 08                moveq    #$8, d4
  006aa4:  20 04                move.l   d4, d0
  006aa6:  d0 ab 00 b0          add.l    $b0(a3), d0
  006aaa:  27 40 00 b0          move.l   d0, $b0(a3)
  006aae:  d9 ab 00 c0          add.l    d4, $c0(a3)
L6ab2:
  006ab2:  4e ba a7 7c          jsr      $1230(pc)  ; -> GetA5
  006ab6:  20 40                movea.l  d0, a0
  006ab8:  20 10                move.l   (a0), d0
  006aba:  90 bc 00 00 00 ca    sub.l    #$ca, d0
  006ac0:  20 40                movea.l  d0, a0
  006ac2:  20 2b 00 e8          move.l   $e8(a3), d0
  006ac6:  b0 a8 00 22          cmp.l    $22(a0), d0
  006aca:  67 3e                beq.b    $6b0a  ; -> L6b0a
  006acc:  4e ba a7 62          jsr      $1230(pc)  ; -> GetA5
  006ad0:  20 40                movea.l  d0, a0
  006ad2:  20 10                move.l   (a0), d0
  006ad4:  90 bc 00 00 00 ca    sub.l    #$ca, d0
  006ada:  20 40                movea.l  d0, a0
  006adc:  27 68 00 22 00 e8    move.l   $22(a0), $e8(a3)
  006ae2:  20 6b 00 b0          movea.l  $b0(a3), a0
  006ae6:  30 bc 00 75          move.w   #$75, (a0)
  006aea:  20 6b 00 b0          movea.l  $b0(a3), a0
  006aee:  21 6b 00 e8 00 04    move.l   $e8(a3), $4(a0)
  006af4:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  006afa:  78 08                moveq    #$8, d4
  006afc:  20 04                move.l   d4, d0
  006afe:  d0 ab 00 b0          add.l    $b0(a3), d0
  006b02:  27 40 00 b0          move.l   d0, $b0(a3)
  006b06:  d9 ab 00 c0          add.l    d4, $c0(a3)
L6b0a:
  006b0a:  70 00                moveq    #$0, d0
  006b0c:  10 2e ff a8          move.b   -$58(a6), d0
  006b10:  66 40                bne.b    $6b52  ; -> L6b52
  006b12:  20 6b 00 c8          movea.l  $c8(a3), a0
  006b16:  30 28 00 06          move.w   $6(a0), d0
  006b1a:  48 c0                ext.l    d0
  006b1c:  6c 34                bge.b    $6b52  ; -> L6b52
  006b1e:  70 00                moveq    #$0, d0
  006b20:  2f 00                move.l   d0, -(a7)
  006b22:  32 2e ff ae          move.w   -$52(a6), d1
  006b26:  48 c1                ext.l    d1
  006b28:  2f 01                move.l   d1, -(a7)
  006b2a:  2f 2b 00 c8          move.l   $c8(a3), -(a7)
  006b2e:  4e ba ac 16          jsr      $1746(pc)  ; -> s7_sub_90ee
  006b32:  50 8f                addq.l   #$8, a7
  006b34:  22 00                move.l   d0, d1
  006b36:  20 1f                move.l   (a7)+, d0
  006b38:  74 00                moveq    #$0, d2
  006b3a:  14 01                move.b   d1, d2
  006b3c:  57 c0                seq.b    d0
  006b3e:  44 00                neg.b    d0
  006b40:  1d 40 ff a8          move.b   d0, -$58(a6)
  006b44:  67 0c                beq.b    $6b52  ; -> L6b52
  006b46:  30 2e ff ae          move.w   -$52(a6), d0
  006b4a:  72 10                moveq    #$10, d1
  006b4c:  e1 a9                lsl.l    d0, d1
  006b4e:  83 6b 00 f2          or.w     d1, $f2(a3)
L6b52:
  006b52:  4a 2e ff a8          tst.b    -$58(a6)
  006b56:  67 00 01 e2          beq.w    $6d3a  ; -> L6d3a
  006b5a:  30 2e ff ae          move.w   -$52(a6), d0
  006b5e:  72 10                moveq    #$10, d1
  006b60:  e1 a9                lsl.l    d0, d1
  006b62:  30 2b 00 f2          move.w   $f2(a3), d0
  006b66:  48 c0                ext.l    d0
  006b68:  c0 81                and.l    d1, d0
  006b6a:  67 00 01 76          beq.w    $6ce2  ; -> L6ce2
  006b6e:  48 6b 01 8a          pea.l    $18a(a3)
  006b72:  30 2e ff ae          move.w   -$52(a6), d0
  006b76:  48 c0                ext.l    d0
  006b78:  2f 00                move.l   d0, -(a7)
  006b7a:  2f 2b 00 c8          move.l   $c8(a3), -(a7)
  006b7e:  4e ba a9 b0          jsr      $1530(pc)  ; -> s7_sub_8f04
  006b82:  4a 80                tst.l    d0
  006b84:  4f ef 00 0c          lea.l    $c(a7), a7
  006b88:  6b 00 01 4a          bmi.w    $6cd4  ; -> L6cd4
  006b8c:  0c 80 00 00 00 04    cmpi.l   #$4, d0
  006b92:  6e 00 01 40          bgt.w    $6cd4  ; -> L6cd4
  006b96:  d0 80                add.l    d0, d0
  006b98:  30 3b 08 06          move.w   $6ba0(pc, d0.l), d0
  006b9c:  4e fb 00 00          jmp      $6b9e(pc,d0.w)
  006ba0:  01 44                dc.w     $0144    ; [0] -> L6ce2
  006ba2:  00 10                dc.w     $0010    ; [1] -> L6bae
  006ba4:  00 64                dc.w     $0064    ; [2] -> L6c02
  006ba6:  00 a8                dc.w     $00A8    ; [3] -> L6c46
  006ba8:  00 ee                dc.w     $00EE    ; [4] -> L6c8c
L6baa:
  006baa:  60 00 01 36          bra.w    $6ce2  ; -> L6ce2
L6bae:
  006bae:  20 6b 00 b0          movea.l  $b0(a3), a0
  006bb2:  30 bc 00 71          move.w   #$71, (a0)
  006bb6:  20 6b 00 b0          movea.l  $b0(a3), a0
  006bba:  31 6e ff ae 00 02    move.w   -$52(a6), $2(a0)
  006bc0:  20 6b 01 8a          movea.l  $18a(a3), a0
  006bc4:  22 6b 00 b0          movea.l  $b0(a3), a1
  006bc8:  23 50 00 04          move.l   (a0), $4(a1)
  006bcc:  20 6b 01 8a          movea.l  $18a(a3), a0
  006bd0:  22 6b 00 b0          movea.l  $b0(a3), a1
  006bd4:  23 68 00 04 00 08    move.l   $4(a0), $8(a1)
  006bda:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  006be0:  78 0c                moveq    #$c, d4
  006be2:  20 04                move.l   d4, d0
  006be4:  d0 ab 00 b0          add.l    $b0(a3), d0
  006be8:  27 40 00 b0          move.l   d0, $b0(a3)
  006bec:  d9 ab 00 c0          add.l    d4, $c0(a3)
  006bf0:  30 2e ff ae          move.w   -$52(a6), d0
  006bf4:  72 10                moveq    #$10, d1
  006bf6:  e1 a9                lsl.l    d0, d1
  006bf8:  46 81                not.l    d1
  006bfa:  c3 6b 00 f2          and.w    d1, $f2(a3)
  006bfe:  60 00 00 e2          bra.w    $6ce2  ; -> L6ce2
L6c02:
  006c02:  20 6b 00 b0          movea.l  $b0(a3), a0
  006c06:  30 bc 00 72          move.w   #$72, (a0)
  006c0a:  20 6b 00 b0          movea.l  $b0(a3), a0
  006c0e:  31 6e ff ae 00 02    move.w   -$52(a6), $2(a0)
  006c14:  20 6b 00 b0          movea.l  $b0(a3), a0
  006c18:  21 6b 01 8a 00 04    move.l   $18a(a3), $4(a0)
  006c1e:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  006c24:  78 08                moveq    #$8, d4
  006c26:  20 04                move.l   d4, d0
  006c28:  d0 ab 00 b0          add.l    $b0(a3), d0
  006c2c:  27 40 00 b0          move.l   d0, $b0(a3)
  006c30:  d9 ab 00 c0          add.l    d4, $c0(a3)
  006c34:  30 2e ff ae          move.w   -$52(a6), d0
  006c38:  72 10                moveq    #$10, d1
  006c3a:  e1 a9                lsl.l    d0, d1
  006c3c:  46 81                not.l    d1
  006c3e:  c3 6b 00 f2          and.w    d1, $f2(a3)
  006c42:  60 00 00 9e          bra.w    $6ce2  ; -> L6ce2
L6c46:
  006c46:  20 6b 00 b0          movea.l  $b0(a3), a0
  006c4a:  30 bc 00 74          move.w   #$74, (a0)
  006c4e:  20 6b 00 b0          movea.l  $b0(a3), a0
  006c52:  31 6e ff ae 00 04    move.w   -$52(a6), $4(a0)
  006c58:  20 6b 01 8a          movea.l  $18a(a3), a0
  006c5c:  22 6b 00 b0          movea.l  $b0(a3), a1
  006c60:  5c 89                addq.l   #$6, a1
  006c62:  22 d8                move.l   (a0)+, (a1)+
  006c64:  32 d8                move.w   (a0)+, (a1)+
  006c66:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  006c6c:  78 0c                moveq    #$c, d4
  006c6e:  20 04                move.l   d4, d0
  006c70:  d0 ab 00 b0          add.l    $b0(a3), d0
  006c74:  27 40 00 b0          move.l   d0, $b0(a3)
  006c78:  d9 ab 00 c0          add.l    d4, $c0(a3)
  006c7c:  30 2e ff ae          move.w   -$52(a6), d0
  006c80:  72 10                moveq    #$10, d1
  006c82:  e1 a9                lsl.l    d0, d1
  006c84:  46 81                not.l    d1
  006c86:  c3 6b 00 f2          and.w    d1, $f2(a3)
  006c8a:  60 56                bra.b    $6ce2  ; -> L6ce2
L6c8c:
  006c8c:  20 6b 00 b0          movea.l  $b0(a3), a0
  006c90:  30 bc 00 72          move.w   #$72, (a0)
  006c94:  20 6b 00 b0          movea.l  $b0(a3), a0
  006c98:  31 6e ff ae 00 02    move.w   -$52(a6), $2(a0)
  006c9e:  20 6b 00 b0          movea.l  $b0(a3), a0
  006ca2:  21 6b 01 8a 00 04    move.l   $18a(a3), $4(a0)
  006ca8:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  006cae:  78 08                moveq    #$8, d4
  006cb0:  20 04                move.l   d4, d0
  006cb2:  d0 ab 00 b0          add.l    $b0(a3), d0
  006cb6:  27 40 00 b0          move.l   d0, $b0(a3)
  006cba:  d9 ab 00 c0          add.l    d4, $c0(a3)
  006cbe:  30 2e ff ae          move.w   -$52(a6), d0
  006cc2:  72 10                moveq    #$10, d1
  006cc4:  e1 a9                lsl.l    d0, d1
  006cc6:  46 81                not.l    d1
  006cc8:  c3 6b 00 f2          and.w    d1, $f2(a3)
  006ccc:  00 6b 00 02 00 ce    ori.w    #$2, $ce(a3)
  006cd2:  60 0e                bra.b    $6ce2  ; -> L6ce2
L6cd4:
  006cd4:  70 00                moveq    #$0, d0
  006cd6:  2f 00                move.l   d0, -(a7)
  006cd8:  4e ba f3 ba          jsr      $6094(pc)  ; -> s7_sub_4822
  006cdc:  58 8f                addq.l   #$4, a7
  006cde:  60 00 0e 1e          bra.w    $7afe  ; -> L7afe
L6ce2:
  006ce2:  30 2e ff ae          move.w   -$52(a6), d0
  006ce6:  48 c0                ext.l    d0
  006ce8:  67 50                beq.b    $6d3a  ; -> L6d3a
  006cea:  30 2b 00 f2          move.w   $f2(a3), d0
  006cee:  48 c0                ext.l    d0
  006cf0:  72 0f                moveq    #$f, d1
  006cf2:  c2 80                and.l    d0, d1
  006cf4:  30 2e ff ae          move.w   -$52(a6), d0
  006cf8:  48 c0                ext.l    d0
  006cfa:  b2 80                cmp.l    d0, d1
  006cfc:  67 3c                beq.b    $6d3a  ; -> L6d3a
  006cfe:  20 6b 00 b0          movea.l  $b0(a3), a0
  006d02:  30 bc 00 73          move.w   #$73, (a0)
  006d06:  20 6b 00 b0          movea.l  $b0(a3), a0
  006d0a:  31 6e ff ae 00 02    move.w   -$52(a6), $2(a0)
  006d10:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  006d16:  78 04                moveq    #$4, d4
  006d18:  20 04                move.l   d4, d0
  006d1a:  d0 ab 00 b0          add.l    $b0(a3), d0
  006d1e:  27 40 00 b0          move.l   d0, $b0(a3)
  006d22:  d9 ab 00 c0          add.l    d4, $c0(a3)
  006d26:  02 6b ff f0 00 f2    andi.w   #$fff0, $f2(a3)
  006d2c:  30 2e ff ae          move.w   -$52(a6), d0
  006d30:  48 c0                ext.l    d0
  006d32:  72 0f                moveq    #$f, d1
  006d34:  c2 80                and.l    d0, d1
  006d36:  83 6b 00 f2          or.w     d1, $f2(a3)
L6d3a:
  006d3a:  20 2e 00 08          move.l   $8(a6), d0
  006d3e:  04 80 00 00 00 18    subi.l   #$18, d0
  006d44:  67 00 02 f2          beq.w    $7038  ; -> L7038
  006d48:  51 80                subq.l   #$8, d0
  006d4a:  67 30                beq.b    $6d7c  ; -> L6d7c
  006d4c:  53 80                subq.l   #$1, d0
  006d4e:  67 00 03 de          beq.w    $712e  ; -> L712e
  006d52:  53 80                subq.l   #$1, d0
  006d54:  67 00 01 f8          beq.w    $6f4e  ; -> L6f4e
  006d58:  53 80                subq.l   #$1, d0
  006d5a:  67 00 00 fa          beq.w    $6e56  ; -> L6e56
  006d5e:  53 80                subq.l   #$1, d0
  006d60:  67 00 01 bc          beq.w    $6f1e  ; -> L6f1e
  006d64:  04 80 00 00 00 0a    subi.l   #$a, d0
  006d6a:  67 00 01 66          beq.w    $6ed2  ; -> L6ed2
  006d6e:  53 80                subq.l   #$1, d0
  006d70:  67 00 01 30          beq.w    $6ea2  ; -> L6ea2
  006d74:  55 80                subq.l   #$2, d0
  006d76:  67 54                beq.b    $6dcc  ; -> L6dcc
  006d78:  60 00 0d 84          bra.w    $7afe  ; -> L7afe
L6d7c:
  006d7c:  20 6b 00 b0          movea.l  $b0(a3), a0
  006d80:  30 bc 00 01          move.w   #$1, (a0)
  006d84:  20 6e 00 0c          movea.l  $c(a6), a0
  006d88:  20 50                movea.l  (a0), a0
  006d8a:  22 6b 00 b0          movea.l  $b0(a3), a1
  006d8e:  23 50 00 04          move.l   (a0), $4(a1)
  006d92:  20 6e 00 0c          movea.l  $c(a6), a0
  006d96:  20 50                movea.l  (a0), a0
  006d98:  22 6e ff da          movea.l  -$26(a6), a1
  006d9c:  23 50 00 30          move.l   (a0), $30(a1)
  006da0:  20 6e ff da          movea.l  -$26(a6), a0
  006da4:  30 28 00 06          move.w   $6(a0), d0
  006da8:  48 c0                ext.l    d0
  006daa:  6c 0a                bge.b    $6db6  ; -> L6db6
  006dac:  20 6e ff da          movea.l  -$26(a6), a0
  006db0:  31 7c 80 00 00 0e    move.w   #$8000, $e(a0)
L6db6:
  006db6:  20 6e 00 0c          movea.l  $c(a6), a0
  006dba:  20 50                movea.l  (a0), a0
  006dbc:  27 50 01 0a          move.l   (a0), $10a(a3)
  006dc0:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  006dc6:  78 08                moveq    #$8, d4
  006dc8:  60 00 04 3a          bra.w    $7204  ; -> L7204
L6dcc:
  006dcc:  20 6b 00 b0          movea.l  $b0(a3), a0
  006dd0:  30 bc 00 07          move.w   #$7, (a0)
  006dd4:  20 6b 00 b0          movea.l  $b0(a3), a0
  006dd8:  31 6e ff aa 00 02    move.w   -$56(a6), $2(a0)
  006dde:  20 6e 00 0c          movea.l  $c(a6), a0
  006de2:  20 68 00 04          movea.l  $4(a0), a0
  006de6:  2f 10                move.l   (a0), -(a7)
  006de8:  20 6b 00 b0          movea.l  $b0(a3), a0
  006dec:  48 68 00 04          pea.l    $4(a0)
  006df0:  20 6e 00 0c          movea.l  $c(a6), a0
  006df4:  20 68 00 04          movea.l  $4(a0), a0
  006df8:  20 50                movea.l  (a0), a0
  006dfa:  30 10                move.w   (a0), d0
  006dfc:  48 c0                ext.l    d0
  006dfe:  2f 00                move.l   d0, -(a7)
  006e00:  4e ba 36 bc          jsr      $a4be(pc)  ; -> sub_a4be
  006e04:  4a 6e ff aa          tst.w    -$56(a6)
  006e08:  67 2e                beq.b    $6e38  ; -> L6e38
  006e0a:  20 6e 00 0c          movea.l  $c(a6), a0
  006e0e:  20 50                movea.l  (a0), a0
  006e10:  22 6e ff da          movea.l  -$26(a6), a1
  006e14:  23 50 00 30          move.l   (a0), $30(a1)
  006e18:  20 6e 00 0c          movea.l  $c(a6), a0
  006e1c:  20 50                movea.l  (a0), a0
  006e1e:  27 50 01 0a          move.l   (a0), $10a(a3)
  006e22:  20 6e ff da          movea.l  -$26(a6), a0
  006e26:  30 28 00 06          move.w   $6(a0), d0
  006e2a:  48 c0                ext.l    d0
  006e2c:  6c 0a                bge.b    $6e38  ; -> L6e38
  006e2e:  20 6e ff da          movea.l  -$26(a6), a0
  006e32:  31 7c 80 00 00 0e    move.w   #$8000, $e(a0)
L6e38:
  006e38:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  006e3e:  20 6e 00 0c          movea.l  $c(a6), a0
  006e42:  20 68 00 04          movea.l  $4(a0), a0
  006e46:  20 50                movea.l  (a0), a0
  006e48:  30 10                move.w   (a0), d0
  006e4a:  48 c0                ext.l    d0
  006e4c:  5e 80                addq.l   #$7, d0
  006e4e:  78 fc                moveq    #$fc, d4
  006e50:  c8 80                and.l    d0, d4
  006e52:  60 00 03 b0          bra.w    $7204  ; -> L7204
L6e56:
  006e56:  20 6b 00 b0          movea.l  $b0(a3), a0
  006e5a:  30 bc 00 02          move.w   #$2, (a0)
  006e5e:  20 6b 00 b0          movea.l  $b0(a3), a0
  006e62:  31 6e ff aa 00 02    move.w   -$56(a6), $2(a0)
  006e68:  20 6e 00 0c          movea.l  $c(a6), a0
  006e6c:  20 68 00 04          movea.l  $4(a0), a0
  006e70:  22 6b 00 b0          movea.l  $b0(a3), a1
  006e74:  58 89                addq.l   #$4, a1
  006e76:  22 d8                move.l   (a0)+, (a1)+
  006e78:  22 d8                move.l   (a0)+, (a1)+
  006e7a:  20 6e 00 0c          movea.l  $c(a6), a0
  006e7e:  22 6b 00 b0          movea.l  $b0(a3), a1
  006e82:  33 68 00 0a 00 0c    move.w   $a(a0), $c(a1)
  006e88:  20 6e 00 0c          movea.l  $c(a6), a0
  006e8c:  22 6b 00 b0          movea.l  $b0(a3), a1
  006e90:  33 68 00 0e 00 0e    move.w   $e(a0), $e(a1)
  006e96:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  006e9c:  78 10                moveq    #$10, d4
  006e9e:  60 00 03 64          bra.w    $7204  ; -> L7204
L6ea2:
  006ea2:  20 6b 00 b0          movea.l  $b0(a3), a0
  006ea6:  30 bc 00 03          move.w   #$3, (a0)
  006eaa:  20 6b 00 b0          movea.l  $b0(a3), a0
  006eae:  31 6e ff aa 00 02    move.w   -$56(a6), $2(a0)
  006eb4:  20 6e 00 0c          movea.l  $c(a6), a0
  006eb8:  20 68 00 04          movea.l  $4(a0), a0
  006ebc:  22 6b 00 b0          movea.l  $b0(a3), a1
  006ec0:  58 89                addq.l   #$4, a1
  006ec2:  22 d8                move.l   (a0)+, (a1)+
  006ec4:  22 d8                move.l   (a0)+, (a1)+
  006ec6:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  006ecc:  78 0c                moveq    #$c, d4
  006ece:  60 00 03 34          bra.w    $7204  ; -> L7204
L6ed2:
  006ed2:  20 6b 00 b0          movea.l  $b0(a3), a0
  006ed6:  30 bc 00 04          move.w   #$4, (a0)
  006eda:  20 6b 00 b0          movea.l  $b0(a3), a0
  006ede:  31 6e ff aa 00 02    move.w   -$56(a6), $2(a0)
  006ee4:  20 6e 00 0c          movea.l  $c(a6), a0
  006ee8:  20 68 00 04          movea.l  $4(a0), a0
  006eec:  22 6b 00 b0          movea.l  $b0(a3), a1
  006ef0:  58 89                addq.l   #$4, a1
  006ef2:  22 d8                move.l   (a0)+, (a1)+
  006ef4:  22 d8                move.l   (a0)+, (a1)+
  006ef6:  20 6e 00 0c          movea.l  $c(a6), a0
  006efa:  22 6b 00 b0          movea.l  $b0(a3), a1
  006efe:  33 68 00 0a 00 0c    move.w   $a(a0), $c(a1)
  006f04:  20 6e 00 0c          movea.l  $c(a6), a0
  006f08:  22 6b 00 b0          movea.l  $b0(a3), a1
  006f0c:  33 68 00 0e 00 0e    move.w   $e(a0), $e(a1)
  006f12:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  006f18:  78 10                moveq    #$10, d4
  006f1a:  60 00 02 e8          bra.w    $7204  ; -> L7204
L6f1e:
  006f1e:  20 6b 00 b0          movea.l  $b0(a3), a0
  006f22:  30 bc 00 05          move.w   #$5, (a0)
  006f26:  20 6b 00 b0          movea.l  $b0(a3), a0
  006f2a:  31 6e ff aa 00 02    move.w   -$56(a6), $2(a0)
  006f30:  20 6e 00 0c          movea.l  $c(a6), a0
  006f34:  20 68 00 04          movea.l  $4(a0), a0
  006f38:  22 6b 00 b0          movea.l  $b0(a3), a1
  006f3c:  58 89                addq.l   #$4, a1
  006f3e:  22 d8                move.l   (a0)+, (a1)+
  006f40:  22 d8                move.l   (a0)+, (a1)+
  006f42:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  006f48:  78 0c                moveq    #$c, d4
  006f4a:  60 00 02 b8          bra.w    $7204  ; -> L7204
L6f4e:
  006f4e:  70 00                moveq    #$0, d0
  006f50:  30 2b 00 cc          move.w   $cc(a3), d0
  006f54:  20 6e 00 0c          movea.l  $c(a6), a0
  006f58:  b0 a8 00 10          cmp.l    $10(a0), d0
  006f5c:  67 3c                beq.b    $6f9a  ; -> L6f9a
  006f5e:  20 6b 00 b0          movea.l  $b0(a3), a0
  006f62:  30 bc 00 69          move.w   #$69, (a0)
  006f66:  20 6e 00 0c          movea.l  $c(a6), a0
  006f6a:  22 6b 00 b0          movea.l  $b0(a3), a1
  006f6e:  33 68 00 12 00 02    move.w   $12(a0), $2(a1)
  006f74:  37 6e ff ac 00 cc    move.w   -$54(a6), $cc(a3)
  006f7a:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  006f80:  78 04                moveq    #$4, d4
  006f82:  20 04                move.l   d4, d0
  006f84:  d0 ab 00 b0          add.l    $b0(a3), d0
  006f88:  27 40 00 b0          move.l   d0, $b0(a3)
  006f8c:  d9 ab 00 c0          add.l    d4, $c0(a3)
  006f90:  20 6e 00 0c          movea.l  $c(a6), a0
  006f94:  37 68 00 12 00 cc    move.w   $12(a0), $cc(a3)
L6f9a:
  006f9a:  20 6b 00 b0          movea.l  $b0(a3), a0
  006f9e:  30 bc 00 09          move.w   #$9, (a0)
  006fa2:  20 6e 00 0c          movea.l  $c(a6), a0
  006fa6:  22 6b 00 b0          movea.l  $b0(a3), a1
  006faa:  23 50 00 20          move.l   (a0), $20(a1)
  006fae:  20 6e 00 0c          movea.l  $c(a6), a0
  006fb2:  20 68 00 04          movea.l  $4(a0), a0
  006fb6:  22 6b 00 b0          movea.l  $b0(a3), a1
  006fba:  54 89                addq.l   #$2, a1
  006fbc:  22 d8                move.l   (a0)+, (a1)+
  006fbe:  22 d8                move.l   (a0)+, (a1)+
  006fc0:  22 d8                move.l   (a0)+, (a1)+
  006fc2:  32 d8                move.w   (a0)+, (a1)+
  006fc4:  20 6e 00 0c          movea.l  $c(a6), a0
  006fc8:  20 68 00 08          movea.l  $8(a0), a0
  006fcc:  22 6b 00 b0          movea.l  $b0(a3), a1
  006fd0:  43 e9 00 10          lea.l    $10(a1), a1
  006fd4:  22 d8                move.l   (a0)+, (a1)+
  006fd6:  22 d8                move.l   (a0)+, (a1)+
  006fd8:  20 6e 00 0c          movea.l  $c(a6), a0
  006fdc:  20 68 00 0c          movea.l  $c(a0), a0
  006fe0:  22 6b 00 b0          movea.l  $b0(a3), a1
  006fe4:  43 e9 00 18          lea.l    $18(a1), a1
  006fe8:  22 d8                move.l   (a0)+, (a1)+
  006fea:  22 d8                move.l   (a0)+, (a1)+
  006fec:  20 6e 00 0c          movea.l  $c(a6), a0
  006ff0:  4a 90                tst.l    (a0)
  006ff2:  67 2c                beq.b    $7020  ; -> L7020
  006ff4:  20 6e 00 0c          movea.l  $c(a6), a0
  006ff8:  20 68 00 04          movea.l  $4(a0), a0
  006ffc:  2f 10                move.l   (a0), -(a7)
  006ffe:  20 6b 00 b0          movea.l  $b0(a3), a0
  007002:  48 68 00 24          pea.l    $24(a0)
  007006:  20 6e 00 0c          movea.l  $c(a6), a0
  00700a:  2f 10                move.l   (a0), -(a7)
  00700c:  4e ba 34 b0          jsr      $a4be(pc)  ; -> sub_a4be
  007010:  20 6b 00 b0          movea.l  $b0(a3), a0
  007014:  41 e8 00 24          lea.l    $24(a0), a0
  007018:  22 6b 00 b0          movea.l  $b0(a3), a1
  00701c:  23 48 00 02          move.l   a0, $2(a1)
L7020:
  007020:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  007026:  20 6e 00 0c          movea.l  $c(a6), a0
  00702a:  20 10                move.l   (a0), d0
  00702c:  72 27                moveq    #$27, d1
  00702e:  d0 81                add.l    d1, d0
  007030:  78 fc                moveq    #$fc, d4
  007032:  c8 80                and.l    d0, d4
  007034:  60 00 01 ce          bra.w    $7204  ; -> L7204
L7038:
  007038:  20 6b 00 b0          movea.l  $b0(a3), a0
  00703c:  30 bc 00 08          move.w   #$8, (a0)
  007040:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  007046:  20 6b 00 b0          movea.l  $b0(a3), a0
  00704a:  31 6e ff aa 00 02    move.w   -$56(a6), $2(a0)
  007050:  67 00 00 9e          beq.w    $70f0  ; -> L70f0
  007054:  30 2b 00 ec          move.w   $ec(a3), d0
  007058:  48 c0                ext.l    d0
  00705a:  2f 00                move.l   d0, -(a7)
  00705c:  30 2b 00 ee          move.w   $ee(a3), d0
  007060:  48 c0                ext.l    d0
  007062:  2f 00                move.l   d0, -(a7)
  007064:  20 6e 00 0c          movea.l  $c(a6), a0
  007068:  2f 28 00 04          move.l   $4(a0), -(a7)
  00706c:  4e ba a7 3c          jsr      $17aa(pc)  ; -> s7_sub_9146
  007070:  2d 40 ff 98          move.l   d0, -$68(a6)
  007074:  4f ef 00 0c          lea.l    $c(a7), a7
  007078:  67 68                beq.b    $70e2  ; -> L70e2
  00707a:  20 6e ff 98          movea.l  -$68(a6), a0
  00707e:  20 50                movea.l  (a0), a0
  007080:  30 10                move.w   (a0), d0
  007082:  48 c0                ext.l    d0
  007084:  5e 80                addq.l   #$7, d0
  007086:  78 fc                moveq    #$fc, d4
  007088:  c8 80                and.l    d0, d4
  00708a:  20 04                move.l   d4, d0
  00708c:  d0 bc 00 00 00 90    add.l    #$90, d0
  007092:  22 2b 00 bc          move.l   $bc(a3), d1
  007096:  92 80                sub.l    d0, d1
  007098:  b2 ab 00 c0          cmp.l    $c0(a3), d1
  00709c:  6e 14                bgt.b    $70b2  ; -> L70b2
  00709e:  2f 2e ff 98          move.l   -$68(a6), -(a7)
  0070a2:  a8 d9                dc.w     $a8d9
  0070a4:  70 15                moveq    #$15, d0
  0070a6:  2f 00                move.l   d0, -(a7)
  0070a8:  4e ba ef ea          jsr      $6094(pc)  ; -> s7_sub_4822
  0070ac:  58 8f                addq.l   #$4, a7
  0070ae:  60 00 0a 4e          bra.w    $7afe  ; -> L7afe
L70b2:
  0070b2:  20 6b 00 b0          movea.l  $b0(a3), a0
  0070b6:  42 68 00 02          clr.w    $2(a0)
  0070ba:  20 6e ff 98          movea.l  -$68(a6), a0
  0070be:  2f 10                move.l   (a0), -(a7)
  0070c0:  20 6b 00 b0          movea.l  $b0(a3), a0
  0070c4:  48 68 00 04          pea.l    $4(a0)
  0070c8:  20 6e ff 98          movea.l  -$68(a6), a0
  0070cc:  20 50                movea.l  (a0), a0
  0070ce:  30 10                move.w   (a0), d0
  0070d0:  48 c0                ext.l    d0
  0070d2:  2f 00                move.l   d0, -(a7)
  0070d4:  4e ba 33 e8          jsr      $a4be(pc)  ; -> sub_a4be
  0070d8:  2f 2e ff 98          move.l   -$68(a6), -(a7)
  0070dc:  a8 d9                dc.w     $a8d9
  0070de:  60 00 01 24          bra.w    $7204  ; -> L7204
L70e2:
  0070e2:  70 15                moveq    #$15, d0
  0070e4:  2f 00                move.l   d0, -(a7)
  0070e6:  4e ba ef ac          jsr      $6094(pc)  ; -> s7_sub_4822
  0070ea:  58 8f                addq.l   #$4, a7
  0070ec:  60 00 0a 10          bra.w    $7afe  ; -> L7afe
L70f0:
  0070f0:  20 6e 00 0c          movea.l  $c(a6), a0
  0070f4:  20 68 00 04          movea.l  $4(a0), a0
  0070f8:  2f 10                move.l   (a0), -(a7)
  0070fa:  20 6b 00 b0          movea.l  $b0(a3), a0
  0070fe:  48 68 00 04          pea.l    $4(a0)
  007102:  20 6e 00 0c          movea.l  $c(a6), a0
  007106:  20 68 00 04          movea.l  $4(a0), a0
  00710a:  20 50                movea.l  (a0), a0
  00710c:  30 10                move.w   (a0), d0
  00710e:  48 c0                ext.l    d0
  007110:  2f 00                move.l   d0, -(a7)
  007112:  4e ba 33 aa          jsr      $a4be(pc)  ; -> sub_a4be
  007116:  20 6e 00 0c          movea.l  $c(a6), a0
  00711a:  20 68 00 04          movea.l  $4(a0), a0
  00711e:  20 50                movea.l  (a0), a0
  007120:  30 10                move.w   (a0), d0
  007122:  48 c0                ext.l    d0
  007124:  5e 80                addq.l   #$7, d0
  007126:  78 fc                moveq    #$fc, d4
  007128:  c8 80                and.l    d0, d4
  00712a:  60 00 00 d8          bra.w    $7204  ; -> L7204
L712e:
  00712e:  4a 2e ff a9          tst.b    -$57(a6)
  007132:  67 3c                beq.b    $7170  ; -> L7170
  007134:  20 6b 00 b0          movea.l  $b0(a3), a0
  007138:  30 bc 00 67          move.w   #$67, (a0)
  00713c:  48 6b 01 92          pea.l    $192(a3)
  007140:  20 6b 00 b0          movea.l  $b0(a3), a0
  007144:  48 68 00 02          pea.l    $2(a0)
  007148:  70 1a                moveq    #$1a, d0
  00714a:  2f 00                move.l   d0, -(a7)
  00714c:  4e ba 33 70          jsr      $a4be(pc)  ; -> sub_a4be
  007150:  20 6b 00 b0          movea.l  $b0(a3), a0
  007154:  21 6b 01 06 00 1c    move.l   $106(a3), $1c(a0)
  00715a:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  007160:  78 20                moveq    #$20, d4
  007162:  20 04                move.l   d4, d0
  007164:  d0 ab 00 b0          add.l    $b0(a3), d0
  007168:  27 40 00 b0          move.l   d0, $b0(a3)
  00716c:  d9 ab 00 c0          add.l    d4, $c0(a3)
L7170:
  007170:  70 10                moveq    #$10, d0
  007172:  22 2e ff b8          move.l   -$48(a6), d1
  007176:  e0 a1                asr.l    d0, d1
  007178:  d3 6b 01 0c          add.w    d1, $10c(a3)
  00717c:  20 3c 00 00 ff ff    move.l   #$ffff, d0
  007182:  c0 ae ff b8          and.l    -$48(a6), d0
  007186:  d1 6b 01 0e          add.w    d0, $10e(a3)
  00718a:  20 6e ff da          movea.l  -$26(a6), a0
  00718e:  21 6b 01 0a 00 30    move.l   $10a(a3), $30(a0)
  007194:  20 6e ff da          movea.l  -$26(a6), a0
  007198:  30 28 00 06          move.w   $6(a0), d0
  00719c:  48 c0                ext.l    d0
  00719e:  6c 0a                bge.b    $71aa  ; -> L71aa
  0071a0:  20 6e ff da          movea.l  -$26(a6), a0
  0071a4:  31 6b 01 0e 00 0e    move.w   $10e(a3), $e(a0)
L71aa:
  0071aa:  20 6b 00 b0          movea.l  $b0(a3), a0
  0071ae:  30 bc 00 06          move.w   #$6, (a0)
  0071b2:  20 6b 00 b0          movea.l  $b0(a3), a0
  0071b6:  21 6e ff b0 00 04    move.l   -$50(a6), $4(a0)
  0071bc:  20 6b 00 b0          movea.l  $b0(a3), a0
  0071c0:  21 6e ff b4 00 08    move.l   -$4c(a6), $8(a0)
  0071c6:  20 6b 00 b0          movea.l  $b0(a3), a0
  0071ca:  21 6e ff b8 00 0c    move.l   -$48(a6), $c(a0)
  0071d0:  20 6b 00 b0          movea.l  $b0(a3), a0
  0071d4:  31 6e ff be 00 02    move.w   -$42(a6), $2(a0)
  0071da:  20 6e 00 0c          movea.l  $c(a6), a0
  0071de:  2f 28 00 04          move.l   $4(a0), -(a7)
  0071e2:  20 6b 00 b0          movea.l  $b0(a3), a0
  0071e6:  48 68 00 10          pea.l    $10(a0)
  0071ea:  2f 2e ff bc          move.l   -$44(a6), -(a7)
  0071ee:  4e ba 32 ce          jsr      $a4be(pc)  ; -> sub_a4be
  0071f2:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  0071f8:  20 2e ff bc          move.l   -$44(a6), d0
  0071fc:  72 13                moveq    #$13, d1
  0071fe:  d0 81                add.l    d1, d0
  007200:  78 fc                moveq    #$fc, d4
  007202:  c8 80                and.l    d0, d4
L7204:
  007204:  20 04                move.l   d4, d0
  007206:  d0 ab 00 b0          add.l    $b0(a3), d0
  00720a:  27 40 00 b0          move.l   d0, $b0(a3)
  00720e:  d9 ab 00 c0          add.l    d4, $c0(a3)
  007212:  27 6b 00 b0 00 b8    move.l   $b0(a3), $b8(a3)
  007218:  4a 05                tst.b    d5
  00721a:  67 12                beq.b    $722e  ; -> L722e
  00721c:  70 00                moveq    #$0, d0
  00721e:  2f 00                move.l   d0, -(a7)
  007220:  2f 00                move.l   d0, -(a7)
  007222:  72 38                moveq    #$38, d1
  007224:  2f 01                move.l   d1, -(a7)
  007226:  4e ba ef fc          jsr      $6224(pc)  ; -> EngineDispatch
  00722a:  4f ef 00 0c          lea.l    $c(a7), a7
L722e:
  00722e:  70 00                moveq    #$0, d0
  007230:  30 2b 00 ce          move.w   $ce(a3), d0
  007234:  72 0e                moveq    #$e, d1
  007236:  c2 80                and.l    d0, d1
  007238:  67 12                beq.b    $724c  ; -> L724c
  00723a:  70 00                moveq    #$0, d0
  00723c:  2f 00                move.l   d0, -(a7)
  00723e:  2f 00                move.l   d0, -(a7)
  007240:  72 38                moveq    #$38, d1
  007242:  2f 01                move.l   d1, -(a7)
  007244:  4e ba ef de          jsr      $6224(pc)  ; -> EngineDispatch
  007248:  4f ef 00 0c          lea.l    $c(a7), a7
L724c:
  00724c:  20 6b 00 0c          movea.l  $c(a3), a0
  007250:  21 6b 00 c0 01 c0    move.l   $c0(a3), $1c0(a0)
  007256:  60 00 08 6e          bra.w    $7ac6  ; -> L7ac6
L725a:
  00725a:  20 6e 00 0c          movea.l  $c(a6), a0
  00725e:  2d 50 ff c0          move.l   (a0), -$40(a6)
  007262:  4a ab 00 c8          tst.l    $c8(a3)
  007266:  67 00 08 5e          beq.w    $7ac6  ; -> L7ac6
  00726a:  4a ae ff c0          tst.l    -$40(a6)
  00726e:  67 00 08 56          beq.w    $7ac6  ; -> L7ac6
  007272:  20 6e ff c0          movea.l  -$40(a6), a0
  007276:  20 50                movea.l  (a0), a0
  007278:  30 10                move.w   (a0), d0
  00727a:  48 c0                ext.l    d0
  00727c:  5a 80                addq.l   #$5, d0
  00727e:  78 fc                moveq    #$fc, d4
  007280:  c8 80                and.l    d0, d4
  007282:  4a 84                tst.l    d4
  007284:  6f 00 04 dc          ble.w    $7762  ; -> L7762
  007288:  20 04                move.l   d4, d0
  00728a:  72 24                moveq    #$24, d1
  00728c:  d0 81                add.l    d1, d0
  00728e:  24 2b 00 bc          move.l   $bc(a3), d2
  007292:  94 80                sub.l    d0, d2
  007294:  b4 ab 00 c0          cmp.l    $c0(a3), d2
  007298:  6e 0e                bgt.b    $72a8  ; -> L72a8
  00729a:  70 12                moveq    #$12, d0
  00729c:  2f 00                move.l   d0, -(a7)
  00729e:  4e ba ed f4          jsr      $6094(pc)  ; -> s7_sub_4822
  0072a2:  58 8f                addq.l   #$4, a7
  0072a4:  60 00 08 20          bra.w    $7ac6  ; -> L7ac6
L72a8:
  0072a8:  4a ab 00 b4          tst.l    $b4(a3)
  0072ac:  67 20                beq.b    $72ce  ; -> L72ce
  0072ae:  20 6b 00 b4          movea.l  $b4(a3), a0
  0072b2:  30 10                move.w   (a0), d0
  0072b4:  48 c0                ext.l    d0
  0072b6:  72 6a                moveq    #$6a, d1
  0072b8:  b2 80                cmp.l    d0, d1
  0072ba:  66 12                bne.b    $72ce  ; -> L72ce
  0072bc:  20 2b 00 b0          move.l   $b0(a3), d0
  0072c0:  90 ab 00 b4          sub.l    $b4(a3), d0
  0072c4:  91 ab 00 c0          sub.l    d0, $c0(a3)
  0072c8:  27 6b 00 b4 00 b0    move.l   $b4(a3), $b0(a3)
L72ce:
  0072ce:  20 6b 00 b0          movea.l  $b0(a3), a0
  0072d2:  30 bc 00 6a          move.w   #$6a, (a0)
  0072d6:  20 6e ff c0          movea.l  -$40(a6), a0
  0072da:  2f 10                move.l   (a0), -(a7)
  0072dc:  20 6b 00 b0          movea.l  $b0(a3), a0
  0072e0:  48 68 00 02          pea.l    $2(a0)
  0072e4:  20 6e ff c0          movea.l  -$40(a6), a0
  0072e8:  20 50                movea.l  (a0), a0
  0072ea:  30 10                move.w   (a0), d0
  0072ec:  48 c0                ext.l    d0
  0072ee:  2f 00                move.l   d0, -(a7)
  0072f0:  4e ba 31 cc          jsr      $a4be(pc)  ; -> sub_a4be
  0072f4:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  0072fa:  20 04                move.l   d4, d0
  0072fc:  d0 ab 00 b0          add.l    $b0(a3), d0
  007300:  27 40 00 b0          move.l   d0, $b0(a3)
  007304:  d9 ab 00 c0          add.l    d4, $c0(a3)
  007308:  27 6e ff c0 01 24    move.l   -$40(a6), $124(a3)
  00730e:  60 00 07 b6          bra.w    $7ac6  ; -> L7ac6
L7312:
  007312:  20 6e 00 0c          movea.l  $c(a6), a0
  007316:  2d 50 ff c0          move.l   (a0), -$40(a6)
  00731a:  4a ab 00 c8          tst.l    $c8(a3)
  00731e:  67 00 07 a6          beq.w    $7ac6  ; -> L7ac6
  007322:  4a ae ff c0          tst.l    -$40(a6)
  007326:  67 00 07 9e          beq.w    $7ac6  ; -> L7ac6
  00732a:  20 6e ff c0          movea.l  -$40(a6), a0
  00732e:  20 50                movea.l  (a0), a0
  007330:  30 10                move.w   (a0), d0
  007332:  48 c0                ext.l    d0
  007334:  5a 80                addq.l   #$5, d0
  007336:  78 fc                moveq    #$fc, d4
  007338:  c8 80                and.l    d0, d4
  00733a:  20 04                move.l   d4, d0
  00733c:  72 24                moveq    #$24, d1
  00733e:  d0 81                add.l    d1, d0
  007340:  24 2b 00 bc          move.l   $bc(a3), d2
  007344:  94 80                sub.l    d0, d2
  007346:  b4 ab 00 c0          cmp.l    $c0(a3), d2
  00734a:  6e 0e                bgt.b    $735a  ; -> L735a
  00734c:  70 18                moveq    #$18, d0
  00734e:  2f 00                move.l   d0, -(a7)
  007350:  4e ba ed 42          jsr      $6094(pc)  ; -> s7_sub_4822
  007354:  58 8f                addq.l   #$4, a7
  007356:  60 00 07 6e          bra.w    $7ac6  ; -> L7ac6
L735a:
  00735a:  4a ab 00 b4          tst.l    $b4(a3)
  00735e:  67 20                beq.b    $7380  ; -> L7380
  007360:  20 6b 00 b4          movea.l  $b4(a3), a0
  007364:  30 10                move.w   (a0), d0
  007366:  48 c0                ext.l    d0
  007368:  72 6c                moveq    #$6c, d1
  00736a:  b2 80                cmp.l    d0, d1
  00736c:  66 12                bne.b    $7380  ; -> L7380
  00736e:  20 2b 00 b0          move.l   $b0(a3), d0
  007372:  90 ab 00 b4          sub.l    $b4(a3), d0
  007376:  91 ab 00 c0          sub.l    d0, $c0(a3)
  00737a:  27 6b 00 b4 00 b0    move.l   $b4(a3), $b0(a3)
L7380:
  007380:  20 6b 00 b0          movea.l  $b0(a3), a0
  007384:  30 bc 00 6c          move.w   #$6c, (a0)
  007388:  20 6e ff c0          movea.l  -$40(a6), a0
  00738c:  2f 10                move.l   (a0), -(a7)
  00738e:  20 6b 00 b0          movea.l  $b0(a3), a0
  007392:  48 68 00 02          pea.l    $2(a0)
  007396:  20 6e ff c0          movea.l  -$40(a6), a0
  00739a:  20 50                movea.l  (a0), a0
  00739c:  30 10                move.w   (a0), d0
  00739e:  48 c0                ext.l    d0
  0073a0:  2f 00                move.l   d0, -(a7)
  0073a2:  4e ba 31 1a          jsr      $a4be(pc)  ; -> sub_a4be
  0073a6:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  0073ac:  20 04                move.l   d4, d0
  0073ae:  d0 ab 00 b0          add.l    $b0(a3), d0
  0073b2:  27 40 00 b0          move.l   d0, $b0(a3)
  0073b6:  d9 ab 00 c0          add.l    d4, $c0(a3)
  0073ba:  27 6e ff c0 01 20    move.l   -$40(a6), $120(a3)
  0073c0:  60 00 07 04          bra.w    $7ac6  ; -> L7ac6
L73c4:
  0073c4:  4a ab 00 c8          tst.l    $c8(a3)
  0073c8:  67 00 01 0a          beq.w    $74d4  ; -> L74d4
  0073cc:  20 2b 00 bc          move.l   $bc(a3), d0
  0073d0:  90 bc 00 00 00 90    sub.l    #$90, d0
  0073d6:  b0 ab 00 c0          cmp.l    $c0(a3), d0
  0073da:  6e 0e                bgt.b    $73ea  ; -> L73ea
  0073dc:  70 09                moveq    #$9, d0
  0073de:  2f 00                move.l   d0, -(a7)
  0073e0:  4e ba ec b2          jsr      $6094(pc)  ; -> s7_sub_4822
  0073e4:  58 8f                addq.l   #$4, a7
  0073e6:  60 00 06 de          bra.w    $7ac6  ; -> L7ac6
L73ea:
  0073ea:  02 6b ff fb 00 ce    andi.w   #$fffb, $ce(a3)
  0073f0:  20 6e 00 0c          movea.l  $c(a6), a0
  0073f4:  20 10                move.l   (a0), d0
  0073f6:  c0 bc 00 00 00 04    and.l    #$4, d0
  0073fc:  81 6b 00 ce          or.w     d0, $ce(a3)
  007400:  70 00                moveq    #$0, d0
  007402:  30 2b 00 ce          move.w   $ce(a3), d0
  007406:  72 04                moveq    #$4, d1
  007408:  c2 80                and.l    d0, d1
  00740a:  67 54                beq.b    $7460  ; -> L7460
  00740c:  20 6b 00 b0          movea.l  $b0(a3), a0
  007410:  30 bc 00 6d          move.w   #$6d, (a0)
  007414:  20 6b 00 c8          movea.l  $c8(a3), a0
  007418:  20 68 00 08          movea.l  $8(a0), a0
  00741c:  20 50                movea.l  (a0), a0
  00741e:  22 6b 00 b0          movea.l  $b0(a3), a1
  007422:  33 68 00 16 00 0c    move.w   $16(a0), $c(a1)
  007428:  20 6b 00 c8          movea.l  $c8(a3), a0
  00742c:  22 6b 00 b0          movea.l  $b0(a3), a1
  007430:  54 89                addq.l   #$2, a1
  007432:  41 e8 00 2a          lea.l    $2a(a0), a0
  007436:  22 d8                move.l   (a0)+, (a1)+
  007438:  32 d8                move.w   (a0)+, (a1)+
  00743a:  20 6b 00 c8          movea.l  $c8(a3), a0
  00743e:  22 6b 00 b0          movea.l  $b0(a3), a1
  007442:  23 68 00 54 00 08    move.l   $54(a0), $8(a1)
  007448:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  00744e:  78 10                moveq    #$10, d4
  007450:  20 04                move.l   d4, d0
  007452:  d0 ab 00 b0          add.l    $b0(a3), d0
  007456:  27 40 00 b0          move.l   d0, $b0(a3)
  00745a:  d9 ab 00 c0          add.l    d4, $c0(a3)
  00745e:  60 74                bra.b    $74d4  ; -> L74d4
L7460:
  007460:  20 6b 00 b0          movea.l  $b0(a3), a0
  007464:  30 bc 00 6b          move.w   #$6b, (a0)
  007468:  20 6b 00 c8          movea.l  $c8(a3), a0
  00746c:  30 28 00 06          move.w   $6(a0), d0
  007470:  48 c0                ext.l    d0
  007472:  6c 22                bge.b    $7496  ; -> L7496
  007474:  20 6b 00 c8          movea.l  $c8(a3), a0
  007478:  22 6b 00 b0          movea.l  $b0(a3), a1
  00747c:  23 68 00 54 00 08    move.l   $54(a0), $8(a1)
  007482:  20 6b 00 c8          movea.l  $c8(a3), a0
  007486:  22 6b 00 b0          movea.l  $b0(a3), a1
  00748a:  54 89                addq.l   #$2, a1
  00748c:  41 e8 00 2a          lea.l    $2a(a0), a0
  007490:  22 d8                move.l   (a0)+, (a1)+
  007492:  32 d8                move.w   (a0)+, (a1)+
  007494:  60 28                bra.b    $74be  ; -> L74be
L7496:
  007496:  20 6b 00 c8          movea.l  $c8(a3), a0
  00749a:  22 6b 00 b0          movea.l  $b0(a3), a1
  00749e:  23 68 00 54 00 08    move.l   $54(a0), $8(a1)
  0074a4:  20 6b 00 c8          movea.l  $c8(a3), a0
  0074a8:  2f 28 00 54          move.l   $54(a0), -(a7)
  0074ac:  4e ba a3 34          jsr      $17e2(pc)  ; -> s7_sub_917e
  0074b0:  20 40                movea.l  d0, a0
  0074b2:  22 6b 00 b0          movea.l  $b0(a3), a1
  0074b6:  54 89                addq.l   #$2, a1
  0074b8:  22 d8                move.l   (a0)+, (a1)+
  0074ba:  32 d8                move.w   (a0)+, (a1)+
  0074bc:  58 8f                addq.l   #$4, a7
L74be:
  0074be:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  0074c4:  78 0c                moveq    #$c, d4
  0074c6:  20 04                move.l   d4, d0
  0074c8:  d0 ab 00 b0          add.l    $b0(a3), d0
  0074cc:  27 40 00 b0          move.l   d0, $b0(a3)
  0074d0:  d9 ab 00 c0          add.l    d4, $c0(a3)
L74d4:
  0074d4:  70 00                moveq    #$0, d0
  0074d6:  30 2b 00 ce          move.w   $ce(a3), d0
  0074da:  72 0e                moveq    #$e, d1
  0074dc:  c2 80                and.l    d0, d1
  0074de:  67 00 05 e6          beq.w    $7ac6  ; -> L7ac6
  0074e2:  70 00                moveq    #$0, d0
  0074e4:  2f 00                move.l   d0, -(a7)
  0074e6:  2f 00                move.l   d0, -(a7)
  0074e8:  72 38                moveq    #$38, d1
  0074ea:  2f 01                move.l   d1, -(a7)
  0074ec:  4e ba ed 36          jsr      $6224(pc)  ; -> EngineDispatch
  0074f0:  4f ef 00 0c          lea.l    $c(a7), a7
  0074f4:  60 00 05 d0          bra.w    $7ac6  ; -> L7ac6
L74f8:
  0074f8:  4a ab 00 c8          tst.l    $c8(a3)
  0074fc:  67 00 01 0a          beq.w    $7608  ; -> L7608
  007500:  20 2b 00 bc          move.l   $bc(a3), d0
  007504:  90 bc 00 00 00 90    sub.l    #$90, d0
  00750a:  b0 ab 00 c0          cmp.l    $c0(a3), d0
  00750e:  6e 0e                bgt.b    $751e  ; -> L751e
  007510:  70 09                moveq    #$9, d0
  007512:  2f 00                move.l   d0, -(a7)
  007514:  4e ba eb 7e          jsr      $6094(pc)  ; -> s7_sub_4822
  007518:  58 8f                addq.l   #$4, a7
  00751a:  60 00 05 aa          bra.w    $7ac6  ; -> L7ac6
L751e:
  00751e:  02 6b ff fd 00 ce    andi.w   #$fffd, $ce(a3)
  007524:  20 6e 00 0c          movea.l  $c(a6), a0
  007528:  20 10                move.l   (a0), d0
  00752a:  c0 bc 00 00 00 02    and.l    #$2, d0
  007530:  81 6b 00 ce          or.w     d0, $ce(a3)
  007534:  70 00                moveq    #$0, d0
  007536:  30 2b 00 ce          move.w   $ce(a3), d0
  00753a:  72 02                moveq    #$2, d1
  00753c:  c2 80                and.l    d0, d1
  00753e:  67 54                beq.b    $7594  ; -> L7594
  007540:  20 6b 00 b0          movea.l  $b0(a3), a0
  007544:  30 bc 00 66          move.w   #$66, (a0)
  007548:  20 6b 00 c8          movea.l  $c8(a3), a0
  00754c:  20 68 00 08          movea.l  $8(a0), a0
  007550:  20 50                movea.l  (a0), a0
  007552:  22 6b 00 b0          movea.l  $b0(a3), a1
  007556:  33 68 00 10 00 0c    move.w   $10(a0), $c(a1)
  00755c:  20 6b 00 c8          movea.l  $c8(a3), a0
  007560:  22 6b 00 b0          movea.l  $b0(a3), a1
  007564:  54 89                addq.l   #$2, a1
  007566:  41 e8 00 24          lea.l    $24(a0), a0
  00756a:  22 d8                move.l   (a0)+, (a1)+
  00756c:  32 d8                move.w   (a0)+, (a1)+
  00756e:  20 6b 00 c8          movea.l  $c8(a3), a0
  007572:  22 6b 00 b0          movea.l  $b0(a3), a1
  007576:  23 68 00 50 00 08    move.l   $50(a0), $8(a1)
  00757c:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  007582:  78 10                moveq    #$10, d4
  007584:  20 04                move.l   d4, d0
  007586:  d0 ab 00 b0          add.l    $b0(a3), d0
  00758a:  27 40 00 b0          move.l   d0, $b0(a3)
  00758e:  d9 ab 00 c0          add.l    d4, $c0(a3)
  007592:  60 74                bra.b    $7608  ; -> L7608
L7594:
  007594:  20 6b 00 b0          movea.l  $b0(a3), a0
  007598:  30 bc 00 64          move.w   #$64, (a0)
  00759c:  20 6b 00 c8          movea.l  $c8(a3), a0
  0075a0:  30 28 00 06          move.w   $6(a0), d0
  0075a4:  48 c0                ext.l    d0
  0075a6:  6c 22                bge.b    $75ca  ; -> L75ca
  0075a8:  20 6b 00 c8          movea.l  $c8(a3), a0
  0075ac:  22 6b 00 b0          movea.l  $b0(a3), a1
  0075b0:  23 68 00 50 00 08    move.l   $50(a0), $8(a1)
  0075b6:  20 6b 00 c8          movea.l  $c8(a3), a0
  0075ba:  22 6b 00 b0          movea.l  $b0(a3), a1
  0075be:  54 89                addq.l   #$2, a1
  0075c0:  41 e8 00 24          lea.l    $24(a0), a0
  0075c4:  22 d8                move.l   (a0)+, (a1)+
  0075c6:  32 d8                move.w   (a0)+, (a1)+
  0075c8:  60 28                bra.b    $75f2  ; -> L75f2
L75ca:
  0075ca:  20 6b 00 c8          movea.l  $c8(a3), a0
  0075ce:  22 6b 00 b0          movea.l  $b0(a3), a1
  0075d2:  23 68 00 50 00 08    move.l   $50(a0), $8(a1)
  0075d8:  20 6b 00 c8          movea.l  $c8(a3), a0
  0075dc:  2f 28 00 50          move.l   $50(a0), -(a7)
  0075e0:  4e ba a2 00          jsr      $17e2(pc)  ; -> s7_sub_917e
  0075e4:  20 40                movea.l  d0, a0
  0075e6:  22 6b 00 b0          movea.l  $b0(a3), a1
  0075ea:  54 89                addq.l   #$2, a1
  0075ec:  22 d8                move.l   (a0)+, (a1)+
  0075ee:  32 d8                move.w   (a0)+, (a1)+
  0075f0:  58 8f                addq.l   #$4, a7
L75f2:
  0075f2:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  0075f8:  78 0c                moveq    #$c, d4
  0075fa:  20 04                move.l   d4, d0
  0075fc:  d0 ab 00 b0          add.l    $b0(a3), d0
  007600:  27 40 00 b0          move.l   d0, $b0(a3)
  007604:  d9 ab 00 c0          add.l    d4, $c0(a3)
L7608:
  007608:  70 00                moveq    #$0, d0
  00760a:  30 2b 00 ce          move.w   $ce(a3), d0
  00760e:  72 0e                moveq    #$e, d1
  007610:  c2 80                and.l    d0, d1
  007612:  67 00 04 b2          beq.w    $7ac6  ; -> L7ac6
  007616:  70 00                moveq    #$0, d0
  007618:  2f 00                move.l   d0, -(a7)
  00761a:  2f 00                move.l   d0, -(a7)
  00761c:  72 38                moveq    #$38, d1
  00761e:  2f 01                move.l   d1, -(a7)
  007620:  4e ba ec 02          jsr      $6224(pc)  ; -> EngineDispatch
  007624:  4f ef 00 0c          lea.l    $c(a7), a7
  007628:  60 00 04 9c          bra.w    $7ac6  ; -> L7ac6
L762c:
  00762c:  20 2b 00 bc          move.l   $bc(a3), d0
  007630:  90 bc 00 00 00 90    sub.l    #$90, d0
  007636:  b0 ab 00 c0          cmp.l    $c0(a3), d0
  00763a:  6e 0a                bgt.b    $7646  ; -> L7646
  00763c:  70 09                moveq    #$9, d0
  00763e:  2f 00                move.l   d0, -(a7)
  007640:  4e ba ea 52          jsr      $6094(pc)  ; -> s7_sub_4822
  007644:  58 8f                addq.l   #$4, a7
L7646:
  007646:  20 6e 00 0c          movea.l  $c(a6), a0
  00764a:  27 50 00 ec          move.l   (a0), $ec(a3)
  00764e:  20 6b 00 b0          movea.l  $b0(a3), a0
  007652:  30 bc 00 6e          move.w   #$6e, (a0)
  007656:  20 6b 00 b0          movea.l  $b0(a3), a0
  00765a:  21 6b 00 ec 00 04    move.l   $ec(a3), $4(a0)
  007660:  27 6b 00 b0 00 b4    move.l   $b0(a3), $b4(a3)
  007666:  78 08                moveq    #$8, d4
  007668:  20 04                move.l   d4, d0
  00766a:  d0 ab 00 b0          add.l    $b0(a3), d0
  00766e:  27 40 00 b0          move.l   d0, $b0(a3)
  007672:  d9 ab 00 c0          add.l    d4, $c0(a3)
  007676:  60 00 04 4e          bra.w    $7ac6  ; -> L7ac6
L767a:
  00767a:  70 04                moveq    #$4, d0
  00767c:  b0 ab 00 c0          cmp.l    $c0(a3), d0
  007680:  6c 1e                bge.b    $76a0  ; -> L76a0
  007682:  70 00                moveq    #$0, d0
  007684:  30 2b 00 ce          move.w   $ce(a3), d0
  007688:  72 0e                moveq    #$e, d1
  00768a:  c2 80                and.l    d0, d1
  00768c:  67 12                beq.b    $76a0  ; -> L76a0
  00768e:  70 00                moveq    #$0, d0
  007690:  2f 00                move.l   d0, -(a7)
  007692:  2f 00                move.l   d0, -(a7)
  007694:  72 38                moveq    #$38, d1
  007696:  2f 01                move.l   d1, -(a7)
  007698:  4e ba eb 8a          jsr      $6224(pc)  ; -> EngineDispatch
  00769c:  4f ef 00 0c          lea.l    $c(a7), a7
L76a0:
  0076a0:  20 6b 00 ac          movea.l  $ac(a3), a0
  0076a4:  30 bc 00 6f          move.w   #$6f, (a0)
  0076a8:  41 ee ff de          lea.l    -$22(a6), a0
  0076ac:  2d 48 00 0c          move.l   a0, $c(a6)
  0076b0:  70 02                moveq    #$2, d0
  0076b2:  2d 40 00 10          move.l   d0, $10(a6)
  0076b6:  20 6e 00 0c          movea.l  $c(a6), a0
  0076ba:  20 ab 00 c4          move.l   $c4(a3), (a0)
  0076be:  20 6e 00 0c          movea.l  $c(a6), a0
  0076c2:  21 6b 00 c0 00 04    move.l   $c0(a3), $4(a0)
  0076c8:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  0076cc:  4e ba 05 88          jsr      $7c56(pc)  ; -> s7_sub_63b0
  0076d0:  58 8f                addq.l   #$4, a7
  0076d2:  60 00 00 8e          bra.w    $7762  ; -> L7762
L76d6:
  0076d6:  70 04                moveq    #$4, d0
  0076d8:  b0 ab 00 c0          cmp.l    $c0(a3), d0
  0076dc:  6c 00 00 84          bge.w    $7762  ; -> L7762
  0076e0:  27 6b 00 b0 00 b8    move.l   $b0(a3), $b8(a3)
  0076e6:  20 6b 00 ac          movea.l  $ac(a3), a0
  0076ea:  30 bc 00 6f          move.w   #$6f, (a0)
  0076ee:  20 6b 00 ac          movea.l  $ac(a3), a0
  0076f2:  31 6b 00 f0 00 02    move.w   $f0(a3), $2(a0)
  0076f8:  41 ee ff de          lea.l    -$22(a6), a0
  0076fc:  2d 48 00 0c          move.l   a0, $c(a6)
  007700:  70 02                moveq    #$2, d0
  007702:  2d 40 00 10          move.l   d0, $10(a6)
  007706:  20 6e 00 0c          movea.l  $c(a6), a0
  00770a:  20 ab 00 c4          move.l   $c4(a3), (a0)
  00770e:  20 6e 00 0c          movea.l  $c(a6), a0
  007712:  21 6b 00 c0 00 04    move.l   $c0(a3), $4(a0)
  007718:  60 48                bra.b    $7762  ; -> L7762
L771a:
  00771a:  20 6e 00 0c          movea.l  $c(a6), a0
  00771e:  4a 90                tst.l    (a0)
  007720:  67 0c                beq.b    $772e  ; -> L772e
  007722:  70 13                moveq    #$13, d0
  007724:  2f 00                move.l   d0, -(a7)
  007726:  4e ba e9 6c          jsr      $6094(pc)  ; -> s7_sub_4822
  00772a:  58 8f                addq.l   #$4, a7
  00772c:  60 34                bra.b    $7762  ; -> L7762
L772e:
  00772e:  20 6e 00 0c          movea.l  $c(a6), a0
  007732:  20 28 00 04          move.l   $4(a0), d0
  007736:  72 10                moveq    #$10, d1
  007738:  e1 a9                lsl.l    d0, d1
  00773a:  83 6b 00 f2          or.w     d1, $f2(a3)
  00773e:  02 6b ff f0 00 f2    andi.w   #$fff0, $f2(a3)
  007744:  60 00 03 80          bra.w    $7ac6  ; -> L7ac6
* Generic packet path (default case of the switch).
L7748:
  007748:  70 04                moveq    #$4, d0
  00774a:  b0 ab 00 c0          cmp.l    $c0(a3), d0
  00774e:  6c 12                bge.b    $7762  ; -> L7762
  007750:  20 2e 00 08          move.l   $8(a6), d0
  007754:  d0 bc 00 00 01 00    add.l    #$100, d0
  00775a:  2f 00                move.l   d0, -(a7)
  00775c:  4e ba e9 36          jsr      $6094(pc)  ; -> s7_sub_4822
  007760:  58 8f                addq.l   #$4, a7
L7762:
  007762:  70 01                moveq    #$1, d0
  007764:  c0 ab 00 1c          and.l    $1c(a3), d0
  007768:  67 08                beq.b    $7772  ; -> L7772
  00776a:  70 12                moveq    #$12, d0
  00776c:  c0 ab 00 1c          and.l    $1c(a3), d0
  007770:  67 10                beq.b    $7782  ; -> L7782
L7772:
  007772:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  007776:  4e ba 10 d2          jsr      $884a(pc)  ; -> s7_sub_6f4e
  00777a:  4a 80                tst.l    d0
  00777c:  58 8f                addq.l   #$4, a7
  00777e:  66 00 03 7e          bne.w    $7afe  ; -> L7afe
L7782:
  007782:  70 10                moveq    #$10, d0
  007784:  c0 ab 00 1c          and.l    $1c(a3), d0
  007788:  67 28                beq.b    $77b2  ; -> L77b2
  00778a:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  00778e:  4e ba 10 ba          jsr      $884a(pc)  ; -> s7_sub_6f4e
  007792:  4a 80                tst.l    d0
  007794:  58 8f                addq.l   #$4, a7
  007796:  67 1a                beq.b    $77b2  ; -> L77b2
  007798:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  00779c:  4e ba 16 2e          jsr      $8dcc(pc)  ; -> s7_sub_7570
  0077a0:  4a 80                tst.l    d0
  0077a2:  58 8f                addq.l   #$4, a7
  0077a4:  66 00 03 58          bne.w    $7afe  ; -> L7afe
  0077a8:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  0077ac:  4e ba 10 9c          jsr      $884a(pc)  ; -> s7_sub_6f4e
  0077b0:  58 8f                addq.l   #$4, a7
L77b2:
  0077b2:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  0077b6:  4e ba 03 6a          jsr      $7b22(pc)  ; -> s7_sub_624a
  0077ba:  72 01                moveq    #$1, d1
  0077bc:  b2 80                cmp.l    d0, d1
  0077be:  58 8f                addq.l   #$4, a7
  0077c0:  66 00 03 3c          bne.w    $7afe  ; -> L7afe
  0077c4:  70 2d                moveq    #$2d, d0
  0077c6:  b0 ae 00 08          cmp.l    $8(a6), d0
  0077ca:  66 08                bne.b    $77d4  ; -> L77d4
  0077cc:  00 ab 00 00 00 40 00 1c ori.l    #$40, $1c(a3)
* Packet post  -  System 7 $5F10-$5F7E.
* -$2a(a6) = packet (unit+$0C), a4 = unit+$18 = the argument area
* (System 7 $5F26 `movea.l $18(a4),a3'), -$2e(a6) = status-long pointer
* (unit+$10).  Status bit 3 set: unit+$1C |= $10, return -1.
L77d4:
  0077d4:  70 00                moveq    #$0, d0
  0077d6:  2d 40 ff c4          move.l   d0, -$3c(a6)
  0077da:  72 ff                moveq    #$ff, d1
  0077dc:  2d 41 ff cc          move.l   d1, -$34(a6)
  0077e0:  55 8f                subq.l   #$2, a7
  0077e2:  70 00                moveq    #$0, d0
  0077e4:  1f 00                move.b   d0, -(a7)
  0077e6:  4e ba 2d 4a          jsr      $a532(pc)  ; -> HWPrivProbe
  0077ea:  1d 5f ff d1          move.b   (a7)+, -$2f(a6)
  0077ee:  2d 6b 00 0c ff d6    move.l   $c(a3), -$2a(a6)
  0077f4:  28 6b 00 18          movea.l  $18(a3), a4
  0077f8:  2d 6b 00 10 ff d2    move.l   $10(a3), -$2e(a6)
  0077fe:  20 6e ff d2          movea.l  -$2e(a6), a0
  007802:  70 08                moveq    #$8, d0
  007804:  c0 90                and.l    (a0), d0
  007806:  67 0c                beq.b    $7814  ; -> L7814
  007808:  00 ab 00 00 00 10 00 1c ori.l    #$10, $1c(a3)
  007810:  60 00 02 58          bra.w    $7a6a  ; -> L7a6a
L7814:
  007814:  00 ab 00 00 00 04 00 1c ori.l    #$4, $1c(a3)
* status long = 0, packet+$18 = 0, +$48 = cmd, +$4C = unit+$20 (then
* unit+$20 += 1), +$50 = n.
  00781c:  20 6e ff d2          movea.l  -$2e(a6), a0
  007820:  70 00                moveq    #$0, d0
  007822:  20 80                move.l   d0, (a0)
  007824:  20 6e ff d6          movea.l  -$2a(a6), a0
  007828:  21 40 00 18          move.l   d0, $18(a0)
  00782c:  20 6e ff d6          movea.l  -$2a(a6), a0
  007830:  21 6e 00 08 00 48    move.l   $8(a6), $48(a0)
  007836:  20 6e ff d6          movea.l  -$2a(a6), a0
  00783a:  21 6b 00 20 00 4c    move.l   $20(a3), $4c(a0)
  007840:  52 ab 00 20          addq.l   #$1, $20(a3)
  007844:  20 6e ff d6          movea.l  -$2a(a6), a0
  007848:  21 6e 00 10 00 50    move.l   $10(a6), $50(a0)
  00784e:  60 64                bra.b    $78b4  ; -> L78b4
* Argument copy  -  System 7 CopyParamsToQueue $5F80-$6048: 8 longs per
* loop pass, move.l (args)+,(a4)+ into the area at [unit+$18], then a
* switch on n-1 ($78D6, System 7 $5FF6) copies the remaining 1-7.
CopyParamsToQueue:
  007850:  20 2e 00 0c          move.l   $c(a6), d0
  007854:  58 ae 00 0c          addq.l   #$4, $c(a6)
  007858:  20 40                movea.l  d0, a0
  00785a:  28 d0                move.l   (a0), (a4)+
  00785c:  20 2e 00 0c          move.l   $c(a6), d0
  007860:  58 ae 00 0c          addq.l   #$4, $c(a6)
  007864:  20 40                movea.l  d0, a0
  007866:  28 d0                move.l   (a0), (a4)+
  007868:  20 2e 00 0c          move.l   $c(a6), d0
  00786c:  58 ae 00 0c          addq.l   #$4, $c(a6)
  007870:  20 40                movea.l  d0, a0
  007872:  28 d0                move.l   (a0), (a4)+
  007874:  20 2e 00 0c          move.l   $c(a6), d0
  007878:  58 ae 00 0c          addq.l   #$4, $c(a6)
  00787c:  20 40                movea.l  d0, a0
  00787e:  28 d0                move.l   (a0), (a4)+
  007880:  20 2e 00 0c          move.l   $c(a6), d0
  007884:  58 ae 00 0c          addq.l   #$4, $c(a6)
  007888:  20 40                movea.l  d0, a0
  00788a:  28 d0                move.l   (a0), (a4)+
  00788c:  20 2e 00 0c          move.l   $c(a6), d0
  007890:  58 ae 00 0c          addq.l   #$4, $c(a6)
  007894:  20 40                movea.l  d0, a0
  007896:  28 d0                move.l   (a0), (a4)+
  007898:  20 2e 00 0c          move.l   $c(a6), d0
  00789c:  58 ae 00 0c          addq.l   #$4, $c(a6)
  0078a0:  20 40                movea.l  d0, a0
  0078a2:  28 d0                move.l   (a0), (a4)+
  0078a4:  20 2e 00 0c          move.l   $c(a6), d0
  0078a8:  58 ae 00 0c          addq.l   #$4, $c(a6)
  0078ac:  20 40                movea.l  d0, a0
  0078ae:  28 d0                move.l   (a0), (a4)+
  0078b0:  51 ae 00 10          subq.l   #$8, $10(a6)
L78b4:
  0078b4:  70 08                moveq    #$8, d0
  0078b6:  b0 ae 00 10          cmp.l    $10(a6), d0
  0078ba:  6f 94                ble.b    $7850  ; -> CopyParamsToQueue
  0078bc:  20 2e 00 10          move.l   $10(a6), d0
  0078c0:  53 80                subq.l   #$1, d0
  0078c2:  6b 74                bmi.b    $7938  ; -> L7938
  0078c4:  0c 80 00 00 00 06    cmpi.l   #$6, d0
  0078ca:  6e 6c                bgt.b    $7938  ; -> L7938
  0078cc:  d0 80                add.l    d0, d0
  0078ce:  30 3b 08 06          move.w   $78d6(pc, d0.l), d0
  0078d2:  4e fb 00 00          jmp      $78d4(pc,d0.w)
  0078d6:  00 58                dc.w     $0058    ; [0] -> L792c
  0078d8:  00 4c                dc.w     $004C    ; [1] -> L7920
  0078da:  00 40                dc.w     $0040    ; [2] -> L7914
  0078dc:  00 34                dc.w     $0034    ; [3] -> L7908
  0078de:  00 28                dc.w     $0028    ; [4] -> L78fc
  0078e0:  00 1c                dc.w     $001C    ; [5] -> L78f0
  0078e2:  00 10                dc.w     $0010    ; [6] -> L78e4
L78e4:
  0078e4:  20 2e 00 0c          move.l   $c(a6), d0
  0078e8:  58 ae 00 0c          addq.l   #$4, $c(a6)
  0078ec:  20 40                movea.l  d0, a0
  0078ee:  28 d0                move.l   (a0), (a4)+
L78f0:
  0078f0:  20 2e 00 0c          move.l   $c(a6), d0
  0078f4:  58 ae 00 0c          addq.l   #$4, $c(a6)
  0078f8:  20 40                movea.l  d0, a0
  0078fa:  28 d0                move.l   (a0), (a4)+
L78fc:
  0078fc:  20 2e 00 0c          move.l   $c(a6), d0
  007900:  58 ae 00 0c          addq.l   #$4, $c(a6)
  007904:  20 40                movea.l  d0, a0
  007906:  28 d0                move.l   (a0), (a4)+
L7908:
  007908:  20 2e 00 0c          move.l   $c(a6), d0
  00790c:  58 ae 00 0c          addq.l   #$4, $c(a6)
  007910:  20 40                movea.l  d0, a0
  007912:  28 d0                move.l   (a0), (a4)+
L7914:
  007914:  20 2e 00 0c          move.l   $c(a6), d0
  007918:  58 ae 00 0c          addq.l   #$4, $c(a6)
  00791c:  20 40                movea.l  d0, a0
  00791e:  28 d0                move.l   (a0), (a4)+
L7920:
  007920:  20 2e 00 0c          move.l   $c(a6), d0
  007924:  58 ae 00 0c          addq.l   #$4, $c(a6)
  007928:  20 40                movea.l  d0, a0
  00792a:  28 d0                move.l   (a0), (a4)+
L792c:
  00792c:  20 2e 00 0c          move.l   $c(a6), d0
  007930:  58 ae 00 0c          addq.l   #$4, $c(a6)
  007934:  20 40                movea.l  d0, a0
  007936:  28 d0                move.l   (a0), (a4)+
* Go  -  System 7 $604A: packet+$14 = -1, unit+$1C |= $0C, unit+$170 =
* cmd, deadline = Ticks + unit+$02.
L7938:
  007938:  20 6e ff d6          movea.l  -$2a(a6), a0
  00793c:  70 ff                moveq    #$ff, d0
  00793e:  21 40 00 14          move.l   d0, $14(a0)
  007942:  00 ab 00 00 00 0c 00 1c ori.l    #$c, $1c(a3)
  00794a:  27 6e 00 08 01 70    move.l   $8(a6), $170(a3)
  007950:  72 00                moveq    #$0, d1
  007952:  32 2b 00 02          move.w   $2(a3), d1
  007956:  d2 b8 01 6a          add.l    $16a.w, d1
  00795a:  2d 41 ff c8          move.l   d1, -$38(a6)
  00795e:  60 00 00 9e          bra.w    $79fe  ; -> L79fe
* Wait loop  -  System 7 $6074-$6116.  Loops while (status long & 3) == 0
* (test at $79FE).  Status bit 3/4 with s7_sub_6f4e succeeding: return 0;
* bit 2: acknowledge and call s7_sub_6442; past the deadline with no change
* in packet+$1C4: s7_sub_75fe(unit, 2, 0) and the timeout exit $7A96.
L7962:
  007962:  20 6e ff d2          movea.l  -$2e(a6), a0
  007966:  70 18                moveq    #$18, d0
  007968:  c0 90                and.l    (a0), d0
  00796a:  67 18                beq.b    $7984  ; -> L7984
  00796c:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  007970:  4e ba 0e d8          jsr      $884a(pc)  ; -> s7_sub_6f4e
  007974:  4a 80                tst.l    d0
  007976:  58 8f                addq.l   #$4, a7
  007978:  67 0a                beq.b    $7984  ; -> L7984
  00797a:  70 00                moveq    #$0, d0
  00797c:  2d 40 ff cc          move.l   d0, -$34(a6)
  007980:  60 00 00 e8          bra.w    $7a6a  ; -> L7a6a
L7984:
  007984:  20 6e ff d2          movea.l  -$2e(a6), a0
  007988:  70 04                moveq    #$4, d0
  00798a:  c0 90                and.l    (a0), d0
  00798c:  67 26                beq.b    $79b4  ; -> L79b4
  00798e:  20 6e ff d2          movea.l  -$2e(a6), a0
  007992:  02 90 ff ff ff fb    andi.l   #$fffffffb, (a0)
  007998:  48 6b 00 24          pea.l    $24(a3)
  00799c:  2f 2e ff d6          move.l   -$2a(a6), -(a7)
  0079a0:  4e ba 03 42          jsr      $7ce4(pc)  ; -> s7_sub_6442
  0079a4:  70 00                moveq    #$0, d0
  0079a6:  30 2b 00 02          move.w   $2(a3), d0
  0079aa:  d0 b8 01 6a          add.l    $16a.w, d0
  0079ae:  2d 40 ff c8          move.l   d0, -$38(a6)
  0079b2:  50 8f                addq.l   #$8, a7
L79b4:
  0079b4:  20 38 01 6a          move.l   $16a.w, d0
  0079b8:  b0 ae ff c8          cmp.l    -$38(a6), d0
  0079bc:  6f 40                ble.b    $79fe  ; -> L79fe
  0079be:  20 6b 00 0c          movea.l  $c(a3), a0
  0079c2:  20 28 01 c4          move.l   $1c4(a0), d0
  0079c6:  b0 ae ff c4          cmp.l    -$3c(a6), d0
  0079ca:  67 1a                beq.b    $79e6  ; -> L79e6
  0079cc:  20 6b 00 0c          movea.l  $c(a3), a0
  0079d0:  2d 68 01 c4 ff c4    move.l   $1c4(a0), -$3c(a6)
  0079d6:  70 00                moveq    #$0, d0
  0079d8:  30 2b 00 02          move.w   $2(a3), d0
  0079dc:  d0 b8 01 6a          add.l    $16a.w, d0
  0079e0:  2d 40 ff c8          move.l   d0, -$38(a6)
  0079e4:  60 18                bra.b    $79fe  ; -> L79fe
L79e6:
  0079e6:  70 00                moveq    #$0, d0
  0079e8:  2f 00                move.l   d0, -(a7)
  0079ea:  72 02                moveq    #$2, d1
  0079ec:  2f 01                move.l   d1, -(a7)
  0079ee:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  0079f2:  4e ba 14 60          jsr      $8e54(pc)  ; -> s7_sub_75fe
  0079f6:  4f ef 00 0c          lea.l    $c(a7), a7
  0079fa:  60 00 00 9a          bra.w    $7a96  ; -> L7a96
L79fe:
  0079fe:  20 6e ff d2          movea.l  -$2e(a6), a0
  007a02:  70 03                moveq    #$3, d0
  007a04:  c0 90                and.l    (a0), d0
  007a06:  67 00 ff 5a          beq.w    $7962  ; -> L7962
  007a0a:  20 6e ff d2          movea.l  -$2e(a6), a0
  007a0e:  70 04                moveq    #$4, d0
  007a10:  c0 90                and.l    (a0), d0
  007a12:  67 18                beq.b    $7a2c  ; -> L7a2c
  007a14:  20 6e ff d2          movea.l  -$2e(a6), a0
  007a18:  02 90 ff ff ff fb    andi.l   #$fffffffb, (a0)
  007a1e:  48 6b 00 24          pea.l    $24(a3)
  007a22:  2f 2e ff d6          move.l   -$2a(a6), -(a7)
  007a26:  4e ba 02 bc          jsr      $7ce4(pc)  ; -> s7_sub_6442
  007a2a:  50 8f                addq.l   #$8, a7
L7a2c:
  007a2c:  70 26                moveq    #$26, d0
  007a2e:  b0 ae 00 08          cmp.l    $8(a6), d0
  007a32:  66 12                bne.b    $7a46  ; -> L7a46
  007a34:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  007a38:  4e ba 02 1c          jsr      $7c56(pc)  ; -> s7_sub_63b0
  007a3c:  02 ab ff ff ff bf 00 1c andi.l   #$ffffffbf, $1c(a3)
  007a44:  58 8f                addq.l   #$4, a7
L7a46:
  007a46:  02 ab ff ff ff f7 00 1c andi.l   #$fffffff7, $1c(a3)
  007a4e:  20 6e ff d2          movea.l  -$2e(a6), a0
  007a52:  70 02                moveq    #$2, d0
  007a54:  c0 90                and.l    (a0), d0
  007a56:  67 08                beq.b    $7a60  ; -> L7a60
  007a58:  02 ab ff ff ff fb 00 1c andi.l   #$fffffffb, $1c(a3)
* Reply  -  System 7 $616C: result = packet+$1C.
L7a60:
  007a60:  20 6e ff d6          movea.l  -$2a(a6), a0
  007a64:  2d 68 00 1c ff cc    move.l   $1c(a0), -$34(a6)
L7a6a:
  007a6a:  55 8f                subq.l   #$2, a7
  007a6c:  1f 2e ff d1          move.b   -$2f(a6), -(a7)
  007a70:  4e ba 2a c0          jsr      $a532(pc)  ; -> HWPrivProbe
  007a74:  53 ab 01 14          subq.l   #$1, $114(a3)
  007a78:  4a ab 01 14          tst.l    $114(a3)
  007a7c:  54 8f                addq.l   #$2, a7
  007a7e:  6e 06                bgt.b    $7a86  ; -> L7a86
  007a80:  70 00                moveq    #$0, d0
  007a82:  27 40 01 14          move.l   d0, $114(a3)
L7a86:
  007a86:  02 ab ff ff ff f7 00 1c andi.l   #$fffffff7, $1c(a3)
  007a8e:  20 2e ff cc          move.l   -$34(a6), d0
  007a92:  60 00 00 84          bra.w    $7b18  ; -> L7b18
* Timeout exit  -  System 7 $61B0: unit+$1C &= ~$0C, |= 2; return 0.
L7a96:
  007a96:  55 8f                subq.l   #$2, a7
  007a98:  1f 2e ff d1          move.b   -$2f(a6), -(a7)
  007a9c:  4e ba 2a 94          jsr      $a532(pc)  ; -> HWPrivProbe
  007aa0:  53 ab 01 14          subq.l   #$1, $114(a3)
  007aa4:  4a ab 01 14          tst.l    $114(a3)
  007aa8:  54 8f                addq.l   #$2, a7
  007aaa:  6e 06                bgt.b    $7ab2  ; -> L7ab2
  007aac:  70 00                moveq    #$0, d0
  007aae:  27 40 01 14          move.l   d0, $114(a3)
L7ab2:
  007ab2:  02 ab ff ff ff f3 00 1c andi.l   #$fffffff3, $1c(a3)
  007aba:  00 ab 00 00 00 02 00 1c ori.l    #$2, $1c(a3)
  007ac2:  70 00                moveq    #$0, d0
  007ac4:  60 52                bra.b    $7b18  ; -> L7b18
L7ac6:
  007ac6:  53 ab 01 14          subq.l   #$1, $114(a3)
  007aca:  4a ab 01 14          tst.l    $114(a3)
  007ace:  6e 06                bgt.b    $7ad6  ; -> L7ad6
  007ad0:  70 00                moveq    #$0, d0
  007ad2:  27 40 01 14          move.l   d0, $114(a3)
L7ad6:
  007ad6:  70 02                moveq    #$2, d0
  007ad8:  b0 ae ff f8          cmp.l    -$8(a6), d0
  007adc:  66 1a                bne.b    $7af8  ; -> L7af8
  007ade:  11 ee ff ef 09 38    move.b   -$11(a6), $938.w
  007ae4:  20 6e ff da          movea.l  -$26(a6), a0
  007ae8:  21 6e ff f0 00 30    move.l   -$10(a6), $30(a0)
  007aee:  20 6e ff da          movea.l  -$26(a6), a0
  007af2:  31 6e ff f6 00 0e    move.w   -$a(a6), $e(a0)
L7af8:
  007af8:  20 2e ff f8          move.l   -$8(a6), d0
  007afc:  60 1a                bra.b    $7b18  ; -> L7b18
L7afe:
  007afe:  53 ab 01 14          subq.l   #$1, $114(a3)
  007b02:  4a ab 01 14          tst.l    $114(a3)
  007b06:  6e 06                bgt.b    $7b0e  ; -> L7b0e
  007b08:  70 00                moveq    #$0, d0
  007b0a:  27 40 01 14          move.l   d0, $114(a3)
L7b0e:
  007b0e:  02 ab ff ff ff f7 00 1c andi.l   #$fffffff7, $1c(a3)
  007b16:  70 00                moveq    #$0, d0
L7b18:
  007b18:  4c ee 1c f8 ff 78    movem.l  -$88(a6), d3-d7/a2-a4
  007b1e:  4e 5e                unlk     a6
  007b20:  4e 75                rts
* s7_sub_624a  -  System 7 $624A (similar code, r=0.83).
s7_sub_624a:
  007b22:  4e 56 ff f8          link.w   a6, #$fff8
  007b26:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  007b2a:  28 6e 00 08          movea.l  $8(a6), a4
  007b2e:  7a 00                moveq    #$0, d5
  007b30:  78 ff                moveq    #$ff, d4
  007b32:  55 8f                subq.l   #$2, a7
  007b34:  70 00                moveq    #$0, d0
  007b36:  1f 00                move.b   d0, -(a7)
  007b38:  4e ba 29 f8          jsr      $a532(pc)  ; -> HWPrivProbe
  007b3c:  1c 1f                move.b   (a7)+, d6
  007b3e:  26 54                movea.l  (a4), a3
  007b40:  2d 6b 00 0c ff fc    move.l   $c(a3), -$4(a6)
  007b46:  2d 6b 00 10 ff f8    move.l   $10(a3), -$8(a6)
  007b4c:  70 00                moveq    #$0, d0
  007b4e:  30 2b 00 02          move.w   $2(a3), d0
  007b52:  2e 00                move.l   d0, d7
  007b54:  de b8 01 6a          add.l    $16a.w, d7
  007b58:  60 00 00 96          bra.w    $7bf0  ; -> L7bf0
L7b5c:
  007b5c:  20 6e ff f8          movea.l  -$8(a6), a0
  007b60:  70 18                moveq    #$18, d0
  007b62:  c0 90                and.l    (a0), d0
  007b64:  67 1c                beq.b    $7b82  ; -> L7b82
  007b66:  2f 0c                move.l   a4, -(a7)
  007b68:  4e ba 0c e0          jsr      $884a(pc)  ; -> s7_sub_6f4e
  007b6c:  4a 80                tst.l    d0
  007b6e:  58 8f                addq.l   #$4, a7
  007b70:  67 10                beq.b    $7b82  ; -> L7b82
  007b72:  55 8f                subq.l   #$2, a7
  007b74:  1f 06                move.b   d6, -(a7)
  007b76:  4e ba 29 ba          jsr      $a532(pc)  ; -> HWPrivProbe
  007b7a:  70 00                moveq    #$0, d0
  007b7c:  54 8f                addq.l   #$2, a7
  007b7e:  60 00 00 cc          bra.w    $7c4c  ; -> L7c4c
L7b82:
  007b82:  20 6e ff f8          movea.l  -$8(a6), a0
  007b86:  70 04                moveq    #$4, d0
  007b88:  c0 90                and.l    (a0), d0
  007b8a:  67 24                beq.b    $7bb0  ; -> L7bb0
  007b8c:  20 6e ff f8          movea.l  -$8(a6), a0
  007b90:  02 90 ff ff ff fb    andi.l   #$fffffffb, (a0)
  007b96:  48 6b 00 24          pea.l    $24(a3)
  007b9a:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  007b9e:  4e ba 01 44          jsr      $7ce4(pc)  ; -> s7_sub_6442
  007ba2:  70 00                moveq    #$0, d0
  007ba4:  30 2b 00 02          move.w   $2(a3), d0
  007ba8:  2e 00                move.l   d0, d7
  007baa:  de b8 01 6a          add.l    $16a.w, d7
  007bae:  50 8f                addq.l   #$8, a7
L7bb0:
  007bb0:  be b8 01 6a          cmp.l    $16a.w, d7
  007bb4:  6c 3a                bge.b    $7bf0  ; -> L7bf0
  007bb6:  20 6b 00 0c          movea.l  $c(a3), a0
  007bba:  ba a8 01 c4          cmp.l    $1c4(a0), d5
  007bbe:  67 16                beq.b    $7bd6  ; -> L7bd6
  007bc0:  20 6b 00 0c          movea.l  $c(a3), a0
  007bc4:  2a 28 01 c4          move.l   $1c4(a0), d5
  007bc8:  70 00                moveq    #$0, d0
  007bca:  30 2b 00 02          move.w   $2(a3), d0
  007bce:  2e 00                move.l   d0, d7
  007bd0:  de b8 01 6a          add.l    $16a.w, d7
  007bd4:  60 1a                bra.b    $7bf0  ; -> L7bf0
L7bd6:
  007bd6:  37 7c 00 02 01 5c    move.w   #$2, $15c(a3)
  007bdc:  55 8f                subq.l   #$2, a7
  007bde:  1f 06                move.b   d6, -(a7)
  007be0:  4e ba 29 50          jsr      $a532(pc)  ; -> HWPrivProbe
  007be4:  70 00                moveq    #$0, d0
  007be6:  27 40 05 e0          move.l   d0, $5e0(a3)
  007bea:  70 ff                moveq    #$ff, d0
  007bec:  54 8f                addq.l   #$2, a7
  007bee:  60 5c                bra.b    $7c4c  ; -> L7c4c
L7bf0:
  007bf0:  20 6e ff f8          movea.l  -$8(a6), a0
  007bf4:  70 02                moveq    #$2, d0
  007bf6:  c0 90                and.l    (a0), d0
  007bf8:  67 00 ff 62          beq.w    $7b5c  ; -> L7b5c
  007bfc:  20 6e ff f8          movea.l  -$8(a6), a0
  007c00:  70 04                moveq    #$4, d0
  007c02:  c0 90                and.l    (a0), d0
  007c04:  67 18                beq.b    $7c1e  ; -> L7c1e
  007c06:  20 6e ff f8          movea.l  -$8(a6), a0
  007c0a:  02 90 ff ff ff fb    andi.l   #$fffffffb, (a0)
  007c10:  48 6b 00 24          pea.l    $24(a3)
  007c14:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  007c18:  4e ba 00 ca          jsr      $7ce4(pc)  ; -> s7_sub_6442
  007c1c:  50 8f                addq.l   #$8, a7
L7c1e:
  007c1e:  02 ab ff ff ff fb 00 1c andi.l   #$fffffffb, $1c(a3)
  007c26:  55 8f                subq.l   #$2, a7
  007c28:  1f 06                move.b   d6, -(a7)
  007c2a:  4e ba 29 06          jsr      $a532(pc)  ; -> HWPrivProbe
  007c2e:  4a ab 05 e0          tst.l    $5e0(a3)
  007c32:  54 8f                addq.l   #$2, a7
  007c34:  67 14                beq.b    $7c4a  ; -> L7c4a
  007c36:  20 54                movea.l  (a4), a0
  007c38:  20 68 00 0c          movea.l  $c(a0), a0
  007c3c:  22 6b 05 e0          movea.l  $5e0(a3), a1
  007c40:  22 a8 00 1c          move.l   $1c(a0), (a1)
  007c44:  70 00                moveq    #$0, d0
  007c46:  27 40 05 e0          move.l   d0, $5e0(a3)
L7c4a:
  007c4a:  70 01                moveq    #$1, d0
L7c4c:
  007c4c:  4c ee 18 f0 ff e0    movem.l  -$20(a6), d4-d7/a3-a4
  007c52:  4e 5e                unlk     a6
  007c54:  4e 75                rts
* s7_sub_63b0  -  System 7 $63B0 (similar code, r=0.92).
s7_sub_63b0:
  007c56:  48 e7 00 18          movem.l  a3-a4, -(a7)
  007c5a:  28 6f 00 0c          movea.l  $c(a7), a4
  007c5e:  26 54                movea.l  (a4), a3
  007c60:  4a ab 00 ac          tst.l    $ac(a3)
  007c64:  67 78                beq.b    $7cde  ; -> L7cde
  007c66:  27 6b 00 c0 01 86    move.l   $c0(a3), $186(a3)
  007c6c:  70 00                moveq    #$0, d0
  007c6e:  27 40 00 b4          move.l   d0, $b4(a3)
  007c72:  27 6b 00 ac 00 b0    move.l   $ac(a3), $b0(a3)
  007c78:  27 6b 00 b0 00 b8    move.l   $b0(a3), $b8(a3)
  007c7e:  27 40 00 c0          move.l   d0, $c0(a3)
  007c82:  27 40 00 c8          move.l   d0, $c8(a3)
  007c86:  37 7c ff ff 00 cc    move.w   #$ffff, $cc(a3)
  007c8c:  37 7c ff ff 00 ee    move.w   #$ffff, $ee(a3)
  007c92:  37 7c ff ff 00 ec    move.w   #$ffff, $ec(a3)
  007c98:  27 40 01 02          move.l   d0, $102(a3)
  007c9c:  27 40 01 06          move.l   d0, $106(a3)
  007ca0:  72 ff                moveq    #$ff, d1
  007ca2:  27 41 01 94          move.l   d1, $194(a3)
  007ca6:  27 41 01 ac          move.l   d1, $1ac(a3)
  007caa:  27 40 01 20          move.l   d0, $120(a3)
  007cae:  27 40 01 24          move.l   d0, $124(a3)
  007cb2:  20 6b 00 ac          movea.l  $ac(a3), a0
  007cb6:  30 bc 00 6f          move.w   #$6f, (a0)
  007cba:  70 04                moveq    #$4, d0
  007cbc:  27 40 00 c0          move.l   d0, $c0(a3)
  007cc0:  24 2b 00 ac          move.l   $ac(a3), d2
  007cc4:  58 82                addq.l   #$4, d2
  007cc6:  27 42 00 b0          move.l   d2, $b0(a3)
  007cca:  70 00                moveq    #$0, d0
  007ccc:  27 40 01 70          move.l   d0, $170(a3)
  007cd0:  37 7c ff ff 00 f2    move.w   #$ffff, $f2(a3)
  007cd6:  27 40 01 10          move.l   d0, $110(a3)
  007cda:  42 6b 00 f0          clr.w    $f0(a3)
L7cde:
  007cde:  4c df 18 00          movem.l  (a7)+, a3-a4
  007ce2:  4e 75                rts
* s7_sub_6442  -  System 7 $6442 (by call graph, r=0.70).
s7_sub_6442:
  007ce4:  4e 56 ff 6e          link.w   a6, #$ff6e
  007ce8:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  007cec:  1d 7c 00 01 ff 8d    move.b   #$1, -$73(a6)
  007cf2:  20 6e 00 08          movea.l  $8(a6), a0
  007cf6:  41 e8 00 24          lea.l    $24(a0), a0
  007cfa:  2d 48 ff 8e          move.l   a0, -$72(a6)
  007cfe:  55 8f                subq.l   #$2, a7
  007d00:  70 00                moveq    #$0, d0
  007d02:  1f 00                move.b   d0, -(a7)
  007d04:  4e ba 28 2c          jsr      $a532(pc)  ; -> HWPrivProbe
  007d08:  1d 5f ff 93          move.b   (a7)+, -$6d(a6)
  007d0c:  20 6e ff 8e          movea.l  -$72(a6), a0
  007d10:  20 3c 00 0f ff ff    move.l   #$fffff, d0
  007d16:  c0 a8 00 14          and.l    $14(a0), d0
  007d1a:  22 3c ff f0 00 00    move.l   #$fff00000, d1
  007d20:  c2 ae 00 08          and.l    $8(a6), d1
  007d24:  82 80                or.l     d0, d1
  007d26:  2d 41 ff 88          move.l   d1, -$78(a6)
  007d2a:  20 6e ff 8e          movea.l  -$72(a6), a0
  007d2e:  70 00                moveq    #$0, d0
  007d30:  21 40 00 08          move.l   d0, $8(a0)
  007d34:  20 6e 00 08          movea.l  $8(a6), a0
  007d38:  02 a8 ff ff ff fb 00 18 andi.l   #$fffffffb, $18(a0)
  007d40:  20 6e ff 8e          movea.l  -$72(a6), a0
  007d44:  2d 68 00 04 ff f8    move.l   $4(a0), -$8(a6)
  007d4a:  20 6e ff 8e          movea.l  -$72(a6), a0
  007d4e:  72 ff                moveq    #$ff, d1
  007d50:  21 41 00 04          move.l   d1, $4(a0)
  007d54:  74 64                moveq    #$64, d2
  007d56:  b4 ae ff f8          cmp.l    -$8(a6), d2
  007d5a:  67 34                beq.b    $7d90  ; -> L7d90
  007d5c:  20 6e 00 0c          movea.l  $c(a6), a0
  007d60:  22 6e ff 8e          movea.l  -$72(a6), a1
  007d64:  20 10                move.l   (a0), d0
  007d66:  b0 a9 00 0c          cmp.l    $c(a1), d0
  007d6a:  67 24                beq.b    $7d90  ; -> L7d90
  007d6c:  20 6e ff 8e          movea.l  -$72(a6), a0
  007d70:  70 ff                moveq    #$ff, d0
  007d72:  21 40 00 08          move.l   d0, $8(a0)
  007d76:  20 6e ff 8e          movea.l  -$72(a6), a0
  007d7a:  72 00                moveq    #$0, d1
  007d7c:  21 41 00 04          move.l   d1, $4(a0)
  007d80:  20 6e ff 8e          movea.l  -$72(a6), a0
  007d84:  22 6e 00 0c          movea.l  $c(a6), a1
  007d88:  22 a8 00 0c          move.l   $c(a0), (a1)
  007d8c:  60 00 07 dc          bra.w    $856a  ; -> L856a
L7d90:
  007d90:  20 2e ff f8          move.l   -$8(a6), d0
  007d94:  67 00 07 d4          beq.w    $856a  ; -> L856a
  007d98:  57 80                subq.l   #$3, d0
  007d9a:  67 00 02 28          beq.w    $7fc4  ; -> L7fc4
  007d9e:  53 80                subq.l   #$1, d0
  007da0:  67 00 02 3a          beq.w    $7fdc  ; -> L7fdc
  007da4:  53 80                subq.l   #$1, d0
  007da6:  67 00 02 42          beq.w    $7fea  ; -> L7fea
  007daa:  53 80                subq.l   #$1, d0
  007dac:  67 00 02 52          beq.w    $8000  ; -> L8000
  007db0:  53 80                subq.l   #$1, d0
  007db2:  67 00 02 62          beq.w    $8016  ; -> L8016
  007db6:  53 80                subq.l   #$1, d0
  007db8:  67 66                beq.b    $7e20  ; -> L7e20
  007dba:  53 80                subq.l   #$1, d0
  007dbc:  67 00 00 98          beq.w    $7e56  ; -> L7e56
  007dc0:  57 80                subq.l   #$3, d0
  007dc2:  67 00 01 b4          beq.w    $7f78  ; -> L7f78
  007dc6:  53 80                subq.l   #$1, d0
  007dc8:  67 00 02 c2          beq.w    $808c  ; -> L808c
  007dcc:  53 80                subq.l   #$1, d0
  007dce:  67 00 03 a8          beq.w    $8178  ; -> L8178
  007dd2:  53 80                subq.l   #$1, d0
  007dd4:  67 00 04 66          beq.w    $823c  ; -> L823c
  007dd8:  53 80                subq.l   #$1, d0
  007dda:  67 00 04 56          beq.w    $8232  ; -> L8232
  007dde:  53 80                subq.l   #$1, d0
  007de0:  67 00 02 52          beq.w    $8034  ; -> L8034
  007de4:  53 80                subq.l   #$1, d0
  007de6:  67 2c                beq.b    $7e14  ; -> L7e14
  007de8:  55 80                subq.l   #$2, d0
  007dea:  67 00 06 d4          beq.w    $84c0  ; -> L84c0
  007dee:  53 80                subq.l   #$1, d0
  007df0:  67 00 00 fa          beq.w    $7eec  ; -> L7eec
  007df4:  04 80 00 00 00 4f    subi.l   #$4f, d0
  007dfa:  66 00 07 6e          bne.w    $856a  ; -> L856a
  007dfe:  20 6e 00 0c          movea.l  $c(a6), a0
  007e02:  70 00                moveq    #$0, d0
  007e04:  20 80                move.l   d0, (a0)
  007e06:  20 6e ff 8e          movea.l  -$72(a6), a0
  007e0a:  72 01                moveq    #$1, d1
  007e0c:  21 41 00 08          move.l   d1, $8(a0)
  007e10:  60 00 07 48          bra.w    $855a  ; -> L855a
L7e14:
  007e14:  20 6e ff 88          movea.l  -$78(a6), a0
  007e18:  20 68 00 04          movea.l  $4(a0), a0
  007e1c:  26 50                movea.l  (a0), a3
  007e1e:  60 08                bra.b    $7e28  ; -> L7e28
L7e20:
  007e20:  20 6e ff 88          movea.l  -$78(a6), a0
  007e24:  26 68 00 04          movea.l  $4(a0), a3
L7e28:
  007e28:  20 0b                move.l   a3, d0
  007e2a:  22 3c 00 f0 00 00    move.l   #$f00000, d1
  007e30:  c2 80                and.l    d0, d1
  007e32:  0c 81 00 80 00 00    cmpi.l   #$800000, d1
  007e38:  67 12                beq.b    $7e4c  ; -> L7e4c
  007e3a:  59 8f                subq.l   #$4, a7
  007e3c:  2f 0b                move.l   a3, -(a7)
  007e3e:  4e ba 27 5e          jsr      $a59e(pc)  ; -> sub_a59e
  007e42:  26 5f                movea.l  (a7)+, a3
  007e44:  20 6e ff 8e          movea.l  -$72(a6), a0
  007e48:  21 4b 00 08          move.l   a3, $8(a0)
L7e4c:
  007e4c:  20 6e ff 88          movea.l  -$78(a6), a0
  007e50:  28 50                movea.l  (a0), a4
  007e52:  60 00 00 b8          bra.w    $7f0c  ; -> L7f0c
L7e56:
  007e56:  20 6e ff 88          movea.l  -$78(a6), a0
  007e5a:  20 3c 00 0f ff ff    move.l   #$fffff, d0
  007e60:  c0 90                and.l    (a0), d0
  007e62:  22 3c ff f0 00 00    move.l   #$fff00000, d1
  007e68:  c2 ae 00 08          and.l    $8(a6), d1
  007e6c:  82 80                or.l     d0, d1
  007e6e:  2d 41 ff 88          move.l   d1, -$78(a6)
  007e72:  1d 7c 00 01 ff 8d    move.b   #$1, -$73(a6)
  007e78:  48 6e ff 8d          pea.l    -$73(a6)
  007e7c:  20 57                movea.l  (a7), a0
  007e7e:  10 10                move.b   (a0), d0
  007e80:  a0 5d                dc.w     $a05d
  007e82:  20 57                movea.l  (a7), a0
  007e84:  10 80                move.b   d0, (a0)
  007e86:  58 8f                addq.l   #$4, a7
L7e88:
  007e88:  20 2e ff 88          move.l   -$78(a6), d0
  007e8c:  58 ae ff 88          addq.l   #$4, -$78(a6)
  007e90:  20 40                movea.l  d0, a0
  007e92:  28 50                movea.l  (a0), a4
  007e94:  20 2e ff 88          move.l   -$78(a6), d0
  007e98:  58 ae ff 88          addq.l   #$4, -$78(a6)
  007e9c:  20 40                movea.l  d0, a0
  007e9e:  26 50                movea.l  (a0), a3
  007ea0:  20 0b                move.l   a3, d0
  007ea2:  22 3c 00 f0 00 00    move.l   #$f00000, d1
  007ea8:  c2 80                and.l    d0, d1
  007eaa:  0c 81 00 80 00 00    cmpi.l   #$800000, d1
  007eb0:  67 0a                beq.b    $7ebc  ; -> L7ebc
  007eb2:  59 8f                subq.l   #$4, a7
  007eb4:  2f 0b                move.l   a3, -(a7)
  007eb6:  4e ba 26 e6          jsr      $a59e(pc)  ; -> sub_a59e
  007eba:  26 5f                movea.l  (a7)+, a3
L7ebc:
  007ebc:  20 2e ff 88          move.l   -$78(a6), d0
  007ec0:  58 ae ff 88          addq.l   #$4, -$78(a6)
  007ec4:  20 40                movea.l  d0, a0
  007ec6:  2e 10                move.l   (a0), d7
  007ec8:  67 0e                beq.b    $7ed8  ; -> L7ed8
  007eca:  60 02                bra.b    $7ece  ; -> L7ece
L7ecc:
  007ecc:  28 db                move.l   (a3)+, (a4)+
L7ece:
  007ece:  20 07                move.l   d7, d0
  007ed0:  53 87                subq.l   #$1, d7
  007ed2:  4a 80                tst.l    d0
  007ed4:  66 f6                bne.b    $7ecc  ; -> L7ecc
  007ed6:  60 b0                bra.b    $7e88  ; -> L7e88
L7ed8:
  007ed8:  48 6e ff 8d          pea.l    -$73(a6)
  007edc:  20 57                movea.l  (a7), a0
  007ede:  10 10                move.b   (a0), d0
  007ee0:  a0 5d                dc.w     $a05d
  007ee2:  20 57                movea.l  (a7), a0
  007ee4:  10 80                move.b   d0, (a0)
  007ee6:  58 8f                addq.l   #$4, a7
  007ee8:  60 00 06 70          bra.w    $855a  ; -> L855a
L7eec:
  007eec:  20 6e ff 88          movea.l  -$78(a6), a0
  007ef0:  20 50                movea.l  (a0), a0
  007ef2:  28 50                movea.l  (a0), a4
  007ef4:  20 0c                move.l   a4, d0
  007ef6:  67 00 06 62          beq.w    $855a  ; -> L855a
  007efa:  59 8f                subq.l   #$4, a7
  007efc:  2f 0c                move.l   a4, -(a7)
  007efe:  4e ba 26 9e          jsr      $a59e(pc)  ; -> sub_a59e
  007f02:  28 5f                movea.l  (a7)+, a4
  007f04:  20 6e ff 88          movea.l  -$78(a6), a0
  007f08:  26 68 00 04          movea.l  $4(a0), a3
L7f0c:
  007f0c:  20 6e ff 88          movea.l  -$78(a6), a0
  007f10:  2e 28 00 08          move.l   $8(a0), d7
  007f14:  1d 7c 00 01 ff 8d    move.b   #$1, -$73(a6)
  007f1a:  48 6e ff 8d          pea.l    -$73(a6)
  007f1e:  20 57                movea.l  (a7), a0
  007f20:  10 10                move.b   (a0), d0
  007f22:  a0 5d                dc.w     $a05d
  007f24:  20 57                movea.l  (a7), a0
  007f26:  10 80                move.b   d0, (a0)
  007f28:  58 8f                addq.l   #$4, a7
  007f2a:  60 26                bra.b    $7f52  ; -> L7f52
L7f2c:
  007f2c:  28 db                move.l   (a3)+, (a4)+
  007f2e:  28 db                move.l   (a3)+, (a4)+
  007f30:  28 db                move.l   (a3)+, (a4)+
  007f32:  28 db                move.l   (a3)+, (a4)+
  007f34:  28 db                move.l   (a3)+, (a4)+
  007f36:  28 db                move.l   (a3)+, (a4)+
  007f38:  28 db                move.l   (a3)+, (a4)+
  007f3a:  28 db                move.l   (a3)+, (a4)+
  007f3c:  28 db                move.l   (a3)+, (a4)+
  007f3e:  28 db                move.l   (a3)+, (a4)+
  007f40:  28 db                move.l   (a3)+, (a4)+
  007f42:  28 db                move.l   (a3)+, (a4)+
  007f44:  28 db                move.l   (a3)+, (a4)+
  007f46:  28 db                move.l   (a3)+, (a4)+
  007f48:  28 db                move.l   (a3)+, (a4)+
  007f4a:  28 db                move.l   (a3)+, (a4)+
  007f4c:  04 87 00 00 00 10    subi.l   #$10, d7
L7f52:
  007f52:  70 10                moveq    #$10, d0
  007f54:  b0 87                cmp.l    d7, d0
  007f56:  6f d4                ble.b    $7f2c  ; -> L7f2c
  007f58:  60 02                bra.b    $7f5c  ; -> L7f5c
L7f5a:
  007f5a:  28 db                move.l   (a3)+, (a4)+
L7f5c:
  007f5c:  20 07                move.l   d7, d0
  007f5e:  53 87                subq.l   #$1, d7
  007f60:  4a 80                tst.l    d0
  007f62:  6e f6                bgt.b    $7f5a  ; -> L7f5a
  007f64:  48 6e ff 8d          pea.l    -$73(a6)
  007f68:  20 57                movea.l  (a7), a0
  007f6a:  10 10                move.b   (a0), d0
  007f6c:  a0 5d                dc.w     $a05d
  007f6e:  20 57                movea.l  (a7), a0
  007f70:  10 80                move.b   d0, (a0)
  007f72:  58 8f                addq.l   #$4, a7
  007f74:  60 00 05 e4          bra.w    $855a  ; -> L855a
L7f78:
  007f78:  20 38 08 88          move.l   $888.w, d0
  007f7c:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  007f82:  2d 40 ff fc          move.l   d0, -$4(a6)
  007f86:  20 6e ff fc          movea.l  -$4(a6), a0
  007f8a:  70 01                moveq    #$1, d0
  007f8c:  21 40 00 3c          move.l   d0, $3c(a0)
  007f90:  20 6e ff 88          movea.l  -$78(a6), a0
  007f94:  2f 10                move.l   (a0), -(a7)
  007f96:  20 6e ff 88          movea.l  -$78(a6), a0
  007f9a:  2f 28 00 04          move.l   $4(a0), -(a7)
  007f9e:  20 6e ff 88          movea.l  -$78(a6), a0
  007fa2:  3f 28 00 0a          move.w   $a(a0), -(a7)
  007fa6:  aa 39                dc.w     $aa39
  007fa8:  20 6e ff fc          movea.l  -$4(a6), a0
  007fac:  70 00                moveq    #$0, d0
  007fae:  21 40 00 3c          move.l   d0, $3c(a0)
  007fb2:  32 38 0d 6e          move.w   $d6e.w, d1
  007fb6:  48 c1                ext.l    d1
  007fb8:  20 6e ff 8e          movea.l  -$72(a6), a0
  007fbc:  21 41 00 08          move.l   d1, $8(a0)
  007fc0:  60 00 05 98          bra.w    $855a  ; -> L855a
L7fc4:
  007fc4:  59 8f                subq.l   #$4, a7
  007fc6:  20 6e ff 88          movea.l  -$78(a6), a0
  007fca:  2f 10                move.l   (a0), -(a7)
  007fcc:  4e ba 24 8e          jsr      $a45c(pc)  ; -> sub_a45c
  007fd0:  20 6e ff 8e          movea.l  -$72(a6), a0
  007fd4:  21 5f 00 08          move.l   (a7)+, $8(a0)
  007fd8:  60 00 05 80          bra.w    $855a  ; -> L855a
L7fdc:
  007fdc:  20 6e ff 88          movea.l  -$78(a6), a0
  007fe0:  2f 10                move.l   (a0), -(a7)
  007fe2:  4e ba 24 84          jsr      $a468(pc)  ; -> sub_a468
  007fe6:  60 00 05 72          bra.w    $855a  ; -> L855a
L7fea:
  007fea:  20 6e ff 88          movea.l  -$78(a6), a0
  007fee:  2f 10                move.l   (a0), -(a7)
  007ff0:  20 6e ff 88          movea.l  -$78(a6), a0
  007ff4:  2f 28 00 04          move.l   $4(a0), -(a7)
  007ff8:  4e ba 24 a4          jsr      $a49e(pc)  ; -> sub_a49e
  007ffc:  60 00 05 5c          bra.w    $855a  ; -> L855a
L8000:
  008000:  20 6e ff 88          movea.l  -$78(a6), a0
  008004:  2f 10                move.l   (a0), -(a7)
  008006:  20 6e ff 88          movea.l  -$78(a6), a0
  00800a:  2f 28 00 04          move.l   $4(a0), -(a7)
  00800e:  4e ba 24 76          jsr      $a486(pc)  ; -> sub_a486
  008012:  60 00 05 46          bra.w    $855a  ; -> L855a
L8016:
  008016:  59 8f                subq.l   #$4, a7
  008018:  20 6e ff 88          movea.l  -$78(a6), a0
  00801c:  2f 10                move.l   (a0), -(a7)
  00801e:  20 6e ff 88          movea.l  -$78(a6), a0
  008022:  3f 28 00 06          move.w   $6(a0), -(a7)
  008026:  a8 0c                dc.w     $a80c
  008028:  20 6e ff 8e          movea.l  -$72(a6), a0
  00802c:  21 5f 00 08          move.l   (a7)+, $8(a0)
  008030:  60 00 05 28          bra.w    $855a  ; -> L855a
L8034:
  008034:  20 6e ff 88          movea.l  -$78(a6), a0
  008038:  2d 68 00 04 ff f0    move.l   $4(a0), -$10(a6)
  00803e:  67 0e                beq.b    $804e  ; -> L804e
  008040:  59 8f                subq.l   #$4, a7
  008042:  aa 32                dc.w     $aa32
  008044:  2d 5f ff f4          move.l   (a7)+, -$c(a6)
  008048:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00804c:  aa 31                dc.w     $aa31
L804e:
  00804e:  59 8f                subq.l   #$4, a7
  008050:  20 6e ff 88          movea.l  -$78(a6), a0
  008054:  3f 28 00 02          move.w   $2(a0), -(a7)
  008058:  70 00                moveq    #$0, d0
  00805a:  aa a2                dc.w     $aaa2
  00805c:  2e 1f                move.l   (a7)+, d7
  00805e:  30 38 0d 6e          move.w   $d6e.w, d0
  008062:  48 c0                ext.l    d0
  008064:  66 0a                bne.b    $8070  ; -> L8070
  008066:  20 6e ff 8e          movea.l  -$72(a6), a0
  00806a:  21 47 00 08          move.l   d7, $8(a0)
  00806e:  60 0a                bra.b    $807a  ; -> L807a
L8070:
  008070:  20 6e ff 8e          movea.l  -$72(a6), a0
  008074:  70 ff                moveq    #$ff, d0
  008076:  21 40 00 08          move.l   d0, $8(a0)
L807a:
  00807a:  4a ae ff f0          tst.l    -$10(a6)
  00807e:  67 00 04 da          beq.w    $855a  ; -> L855a
  008082:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  008086:  aa 31                dc.w     $aa31
  008088:  60 00 04 d0          bra.w    $855a  ; -> L855a
L808c:
  00808c:  20 6e ff 88          movea.l  -$78(a6), a0
  008090:  3d 68 00 06 ff 82    move.w   $6(a0), -$7e(a6)
  008096:  20 6e ff 88          movea.l  -$78(a6), a0
  00809a:  3d 68 00 0a ff 84    move.w   $a(a0), -$7c(a6)
  0080a0:  20 6e ff 88          movea.l  -$78(a6), a0
  0080a4:  3d 68 00 0e ff 86    move.w   $e(a0), -$7a(a6)
  0080aa:  20 6e ff 88          movea.l  -$78(a6), a0
  0080ae:  2d 68 00 10 ff f0    move.l   $10(a0), -$10(a6)
  0080b4:  70 00                moveq    #$0, d0
  0080b6:  2d 40 ff f4          move.l   d0, -$c(a6)
  0080ba:  20 6e ff 8e          movea.l  -$72(a6), a0
  0080be:  21 40 00 08          move.l   d0, $8(a0)
  0080c2:  4a ae ff f0          tst.l    -$10(a6)
  0080c6:  67 1c                beq.b    $80e4  ; -> L80e4
  0080c8:  59 8f                subq.l   #$4, a7
  0080ca:  aa 32                dc.w     $aa32
  0080cc:  2d 5f ff f4          move.l   (a7)+, -$c(a6)
  0080d0:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  0080d4:  aa 31                dc.w     $aa31
  0080d6:  20 6e ff f0          movea.l  -$10(a6), a0
  0080da:  20 50                movea.l  (a0), a0
  0080dc:  2d 68 00 0c ff 94    move.l   $c(a0), -$6c(a6)
  0080e2:  60 14                bra.b    $80f8  ; -> L80f8
L80e4:
  0080e4:  59 8f                subq.l   #$4, a7
  0080e6:  aa 32                dc.w     $aa32
  0080e8:  2d 5f ff f0          move.l   (a7)+, -$10(a6)
  0080ec:  20 6e ff f0          movea.l  -$10(a6), a0
  0080f0:  20 50                movea.l  (a0), a0
  0080f2:  2d 68 00 0c ff 94    move.l   $c(a0), -$6c(a6)
L80f8:
  0080f8:  4a ae ff 94          tst.l    -$6c(a6)
  0080fc:  66 62                bne.b    $8160  ; -> L8160
  0080fe:  70 01                moveq    #$1, d0
  008100:  2f 00                move.l   d0, -(a7)
  008102:  48 6e ff f0          pea.l    -$10(a6)
  008106:  72 29                moveq    #$29, d1
  008108:  2f 01                move.l   d1, -(a7)
  00810a:  4e ba e1 18          jsr      $6224(pc)  ; -> EngineDispatch
  00810e:  4f ef 00 0c          lea.l    $c(a7), a7
  008112:  60 4c                bra.b    $8160  ; -> L8160
L8114:
  008114:  20 6e ff 94          movea.l  -$6c(a6), a0
  008118:  4a 90                tst.l    (a0)
  00811a:  67 3a                beq.b    $8156  ; -> L8156
  00811c:  20 6e ff 94          movea.l  -$6c(a6), a0
  008120:  20 50                movea.l  (a0), a0
  008122:  4a a8 00 04          tst.l    $4(a0)
  008126:  67 2e                beq.b    $8156  ; -> L8156
  008128:  55 8f                subq.l   #$2, a7
  00812a:  48 6e ff 82          pea.l    -$7e(a6)
  00812e:  48 6e ff 7e          pea.l    -$82(a6)
  008132:  20 6e ff 94          movea.l  -$6c(a6), a0
  008136:  20 50                movea.l  (a0), a0
  008138:  20 68 00 04          movea.l  $4(a0), a0
  00813c:  4e 90                jsr      (a0)
  00813e:  4a 1f                tst.b    (a7)+
  008140:  67 14                beq.b    $8156  ; -> L8156
  008142:  20 6e ff 88          movea.l  -$78(a6), a0
  008146:  20 ae ff 7e          move.l   -$82(a6), (a0)
  00814a:  20 6e ff 8e          movea.l  -$72(a6), a0
  00814e:  70 01                moveq    #$1, d0
  008150:  21 40 00 08          move.l   d0, $8(a0)
  008154:  60 10                bra.b    $8166  ; -> L8166
L8156:
  008156:  20 6e ff 94          movea.l  -$6c(a6), a0
  00815a:  20 50                movea.l  (a0), a0
  00815c:  2d 50 ff 94          move.l   (a0), -$6c(a6)
L8160:
  008160:  4a ae ff 94          tst.l    -$6c(a6)
  008164:  66 ae                bne.b    $8114  ; -> L8114
L8166:
  008166:  4a ae ff f4          tst.l    -$c(a6)
  00816a:  67 00 03 ee          beq.w    $855a  ; -> L855a
  00816e:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  008172:  aa 31                dc.w     $aa31
  008174:  60 00 03 e4          bra.w    $855a  ; -> L855a
L8178:
  008178:  20 6e ff 88          movea.l  -$78(a6), a0
  00817c:  3d 68 00 06 ff 82    move.w   $6(a0), -$7e(a6)
  008182:  20 6e ff 88          movea.l  -$78(a6), a0
  008186:  3d 68 00 0a ff 84    move.w   $a(a0), -$7c(a6)
  00818c:  20 6e ff 88          movea.l  -$78(a6), a0
  008190:  3d 68 00 0e ff 86    move.w   $e(a0), -$7a(a6)
  008196:  20 6e ff 8e          movea.l  -$72(a6), a0
  00819a:  70 00                moveq    #$0, d0
  00819c:  21 40 00 08          move.l   d0, $8(a0)
  0081a0:  20 6e ff 88          movea.l  -$78(a6), a0
  0081a4:  2d 68 00 10 ff f0    move.l   $10(a0), -$10(a6)
  0081aa:  67 0e                beq.b    $81ba  ; -> L81ba
  0081ac:  59 8f                subq.l   #$4, a7
  0081ae:  aa 32                dc.w     $aa32
  0081b0:  2d 5f ff f4          move.l   (a7)+, -$c(a6)
  0081b4:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  0081b8:  aa 31                dc.w     $aa31
L81ba:
  0081ba:  20 6e ff 88          movea.l  -$78(a6), a0
  0081be:  2d 50 ff 98          move.l   (a0), -$68(a6)
  0081c2:  60 56                bra.b    $821a  ; -> L821a
L81c4:
  0081c4:  55 8f                subq.l   #$2, a7
  0081c6:  48 6e ff 82          pea.l    -$7e(a6)
  0081ca:  20 6e ff 98          movea.l  -$68(a6), a0
  0081ce:  20 50                movea.l  (a0), a0
  0081d0:  20 68 00 04          movea.l  $4(a0), a0
  0081d4:  4e 90                jsr      (a0)
  0081d6:  4a 1f                tst.b    (a7)+
  0081d8:  67 36                beq.b    $8210  ; -> L8210
  0081da:  70 00                moveq    #$0, d0
  0081dc:  30 2e ff 82          move.w   -$7e(a6), d0
  0081e0:  20 6e ff 88          movea.l  -$78(a6), a0
  0081e4:  21 40 00 04          move.l   d0, $4(a0)
  0081e8:  70 00                moveq    #$0, d0
  0081ea:  30 2e ff 84          move.w   -$7c(a6), d0
  0081ee:  20 6e ff 88          movea.l  -$78(a6), a0
  0081f2:  21 40 00 08          move.l   d0, $8(a0)
  0081f6:  70 00                moveq    #$0, d0
  0081f8:  30 2e ff 86          move.w   -$7a(a6), d0
  0081fc:  20 6e ff 88          movea.l  -$78(a6), a0
  008200:  21 40 00 0c          move.l   d0, $c(a0)
  008204:  20 6e ff 8e          movea.l  -$72(a6), a0
  008208:  70 01                moveq    #$1, d0
  00820a:  21 40 00 08          move.l   d0, $8(a0)
  00820e:  60 10                bra.b    $8220  ; -> L8220
L8210:
  008210:  20 6e ff 98          movea.l  -$68(a6), a0
  008214:  20 50                movea.l  (a0), a0
  008216:  2d 50 ff 98          move.l   (a0), -$68(a6)
L821a:
  00821a:  4a ae ff 98          tst.l    -$68(a6)
  00821e:  66 a4                bne.b    $81c4  ; -> L81c4
L8220:
  008220:  4a ae ff f0          tst.l    -$10(a6)
  008224:  67 00 03 34          beq.w    $855a  ; -> L855a
  008228:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  00822c:  aa 31                dc.w     $aa31
  00822e:  60 00 03 2a          bra.w    $855a  ; -> L855a
L8232:
  008232:  20 6e ff 88          movea.l  -$78(a6), a0
  008236:  20 50                movea.l  (a0), a0
  008238:  2c 10                move.l   (a0), d6
  00823a:  60 06                bra.b    $8242  ; -> L8242
L823c:
  00823c:  20 6e ff 88          movea.l  -$78(a6), a0
  008240:  2c 10                move.l   (a0), d6
L8242:
  008242:  20 6e ff 88          movea.l  -$78(a6), a0
  008246:  2a 28 00 04          move.l   $4(a0), d5
  00824a:  20 6e ff 88          movea.l  -$78(a6), a0
  00824e:  2d 68 00 08 ff e4    move.l   $8(a0), -$1c(a6)
  008254:  20 6e ff 88          movea.l  -$78(a6), a0
  008258:  2d 68 00 0c ff e8    move.l   $c(a0), -$18(a6)
  00825e:  20 6e 00 08          movea.l  $8(a6), a0
  008262:  70 08                moveq    #$8, d0
  008264:  c0 a8 00 04          and.l    $4(a0), d0
  008268:  66 0e                bne.b    $8278  ; -> L8278
  00826a:  20 6e ff 8e          movea.l  -$72(a6), a0
  00826e:  70 ff                moveq    #$ff, d0
  008270:  21 40 00 08          move.l   d0, $8(a0)
  008274:  60 00 02 e4          bra.w    $855a  ; -> L855a
L8278:
  008278:  4a ae ff e4          tst.l    -$1c(a6)
  00827c:  66 3c                bne.b    $82ba  ; -> L82ba
  00827e:  55 8f                subq.l   #$2, a7
  008280:  2f 06                move.l   d6, -(a7)
  008282:  2f 05                move.l   d5, -(a7)
  008284:  4e ba 21 82          jsr      $a408(pc)  ; -> sub_a408
  008288:  30 1f                move.w   (a7)+, d0
  00828a:  48 c0                ext.l    d0
  00828c:  20 6e ff 8e          movea.l  -$72(a6), a0
  008290:  21 40 00 08          move.l   d0, $8(a0)
  008294:  20 6e ff 8e          movea.l  -$72(a6), a0
  008298:  4a a8 00 08          tst.l    $8(a0)
  00829c:  66 00 02 bc          bne.w    $855a  ; -> L855a
  0082a0:  55 8f                subq.l   #$2, a7
  0082a2:  2f 06                move.l   d6, -(a7)
  0082a4:  2f 05                move.l   d5, -(a7)
  0082a6:  4e ba 21 58          jsr      $a400(pc)  ; -> sub_a400
  0082aa:  30 1f                move.w   (a7)+, d0
  0082ac:  48 c0                ext.l    d0
  0082ae:  20 6e ff 8e          movea.l  -$72(a6), a0
  0082b2:  21 40 00 08          move.l   d0, $8(a0)
  0082b6:  60 00 02 a2          bra.w    $855a  ; -> L855a
L82ba:
  0082ba:  2d 46 ff 9c          move.l   d6, -$64(a6)
  0082be:  2d 45 ff a0          move.l   d5, -$60(a6)
  0082c2:  55 8f                subq.l   #$2, a7
  0082c4:  2f 2e ff 9c          move.l   -$64(a6), -(a7)
  0082c8:  2f 2e ff a0          move.l   -$60(a6), -(a7)
  0082cc:  4e ba 21 2e          jsr      $a3fc(pc)  ; -> sub_a3fc
  0082d0:  30 1f                move.w   (a7)+, d0
  0082d2:  48 c0                ext.l    d0
  0082d4:  28 00                move.l   d0, d4
  0082d6:  67 0c                beq.b    $82e4  ; -> L82e4
  0082d8:  20 6e ff 8e          movea.l  -$72(a6), a0
  0082dc:  21 44 00 08          move.l   d4, $8(a0)
  0082e0:  60 00 02 78          bra.w    $855a  ; -> L855a
L82e4:
  0082e4:  55 8f                subq.l   #$2, a7
  0082e6:  2f 2e ff 9c          move.l   -$64(a6), -(a7)
  0082ea:  2f 2e ff a0          move.l   -$60(a6), -(a7)
  0082ee:  4e ba 21 14          jsr      $a404(pc)  ; -> sub_a404
  0082f2:  30 1f                move.w   (a7)+, d0
  0082f4:  48 c0                ext.l    d0
  0082f6:  28 00                move.l   d0, d4
  0082f8:  67 18                beq.b    $8312  ; -> L8312
  0082fa:  55 8f                subq.l   #$2, a7
  0082fc:  2f 06                move.l   d6, -(a7)
  0082fe:  2f 05                move.l   d5, -(a7)
  008300:  4e ba 20 fe          jsr      $a400(pc)  ; -> sub_a400
  008304:  20 6e ff 8e          movea.l  -$72(a6), a0
  008308:  21 44 00 08          move.l   d4, $8(a0)
  00830c:  54 8f                addq.l   #$2, a7
  00830e:  60 00 02 4a          bra.w    $855a  ; -> L855a
L8312:
  008312:  70 00                moveq    #$0, d0
  008314:  2d 40 ff 7e          move.l   d0, -$82(a6)
  008318:  70 08                moveq    #$8, d0
  00831a:  2d 40 ff 6e          move.l   d0, -$92(a6)
  00831e:  55 8f                subq.l   #$2, a7
  008320:  48 6e ff 9c          pea.l    -$64(a6)
  008324:  48 6e ff 6e          pea.l    -$92(a6)
  008328:  4e ba 20 e2          jsr      $a40c(pc)  ; -> s7_sub_c264
  00832c:  30 1f                move.w   (a7)+, d0
  00832e:  48 c0                ext.l    d0
  008330:  28 00                move.l   d0, d4
  008332:  67 22                beq.b    $8356  ; -> L8356
  008334:  55 8f                subq.l   #$2, a7
  008336:  2f 06                move.l   d6, -(a7)
  008338:  2f 05                move.l   d5, -(a7)
  00833a:  4e ba 20 cc          jsr      $a408(pc)  ; -> sub_a408
  00833e:  55 8f                subq.l   #$2, a7
  008340:  2f 06                move.l   d6, -(a7)
  008342:  2f 05                move.l   d5, -(a7)
  008344:  4e ba 20 ba          jsr      $a400(pc)  ; -> sub_a400
  008348:  20 6e ff 8e          movea.l  -$72(a6), a0
  00834c:  21 44 00 08          move.l   d4, $8(a0)
  008350:  58 8f                addq.l   #$4, a7
  008352:  60 00 02 06          bra.w    $855a  ; -> L855a
L8356:
  008356:  20 2e ff 6e          move.l   -$92(a6), d0
  00835a:  d1 ae ff 7e          add.l    d0, -$82(a6)
  00835e:  1d 7c 00 01 ff 8d    move.b   #$1, -$73(a6)
  008364:  48 6e ff 8d          pea.l    -$73(a6)
  008368:  20 57                movea.l  (a7), a0
  00836a:  10 10                move.b   (a0), d0
  00836c:  a0 5d                dc.w     $a05d
  00836e:  20 57                movea.l  (a7), a0
  008370:  10 80                move.b   d0, (a0)
  008372:  7e 00                moveq    #$0, d7
  008374:  58 8f                addq.l   #$4, a7
  008376:  60 28                bra.b    $83a0  ; -> L83a0
L8378:
  008378:  20 07                move.l   d7, d0
  00837a:  e7 80                asl.l    #$3, d0
  00837c:  22 2e ff e8          move.l   -$18(a6), d1
  008380:  58 ae ff e8          addq.l   #$4, -$18(a6)
  008384:  20 41                movea.l  d1, a0
  008386:  20 b6 08 a4          move.l   -$5c(a6, d0.l), (a0)
  00838a:  20 07                move.l   d7, d0
  00838c:  e7 80                asl.l    #$3, d0
  00838e:  22 2e ff e8          move.l   -$18(a6), d1
  008392:  58 ae ff e8          addq.l   #$4, -$18(a6)
  008396:  20 41                movea.l  d1, a0
  008398:  20 b6 08 a8          move.l   -$58(a6, d0.l), (a0)
  00839c:  20 07                move.l   d7, d0
  00839e:  52 87                addq.l   #$1, d7
L83a0:
  0083a0:  be ae ff 7e          cmp.l    -$82(a6), d7
  0083a4:  6d d2                blt.b    $8378  ; -> L8378
  0083a6:  48 6e ff 8d          pea.l    -$73(a6)
  0083aa:  20 57                movea.l  (a7), a0
  0083ac:  10 10                move.b   (a0), d0
  0083ae:  a0 5d                dc.w     $a05d
  0083b0:  20 57                movea.l  (a7), a0
  0083b2:  10 80                move.b   d0, (a0)
  0083b4:  4a ae ff a0          tst.l    -$60(a6)
  0083b8:  58 8f                addq.l   #$4, a7
  0083ba:  67 00 00 ee          beq.w    $84aa  ; -> L84aa
  0083be:  20 2e ff 6e          move.l   -$92(a6), d0
  0083c2:  91 ae ff e4          sub.l    d0, -$1c(a6)
  0083c6:  70 08                moveq    #$8, d0
  0083c8:  b0 ae ff e4          cmp.l    -$1c(a6), d0
  0083cc:  63 00 01 8c          bls.w    $855a  ; -> L855a
  0083d0:  2d 6e ff e4 ff 6e    move.l   -$1c(a6), -$92(a6)
  0083d6:  55 8f                subq.l   #$2, a7
  0083d8:  48 6e ff 9c          pea.l    -$64(a6)
  0083dc:  48 6e ff 6e          pea.l    -$92(a6)
  0083e0:  4e ba 20 2a          jsr      $a40c(pc)  ; -> s7_sub_c264
  0083e4:  30 1f                move.w   (a7)+, d0
  0083e6:  48 c0                ext.l    d0
  0083e8:  28 00                move.l   d0, d4
  0083ea:  67 22                beq.b    $840e  ; -> L840e
  0083ec:  55 8f                subq.l   #$2, a7
  0083ee:  2f 06                move.l   d6, -(a7)
  0083f0:  2f 05                move.l   d5, -(a7)
  0083f2:  4e ba 20 14          jsr      $a408(pc)  ; -> sub_a408
  0083f6:  55 8f                subq.l   #$2, a7
  0083f8:  2f 06                move.l   d6, -(a7)
  0083fa:  2f 05                move.l   d5, -(a7)
  0083fc:  4e ba 20 02          jsr      $a400(pc)  ; -> sub_a400
  008400:  20 6e ff 8e          movea.l  -$72(a6), a0
  008404:  21 44 00 08          move.l   d4, $8(a0)
  008408:  58 8f                addq.l   #$4, a7
  00840a:  60 00 01 4e          bra.w    $855a  ; -> L855a
L840e:
  00840e:  20 2e ff 6e          move.l   -$92(a6), d0
  008412:  d1 ae ff 7e          add.l    d0, -$82(a6)
  008416:  1d 7c 00 01 ff 8d    move.b   #$1, -$73(a6)
  00841c:  48 6e ff 8d          pea.l    -$73(a6)
  008420:  20 57                movea.l  (a7), a0
  008422:  10 10                move.b   (a0), d0
  008424:  a0 5d                dc.w     $a05d
  008426:  20 57                movea.l  (a7), a0
  008428:  10 80                move.b   d0, (a0)
  00842a:  7e 00                moveq    #$0, d7
  00842c:  58 8f                addq.l   #$4, a7
  00842e:  60 28                bra.b    $8458  ; -> L8458
L8430:
  008430:  20 07                move.l   d7, d0
  008432:  e7 80                asl.l    #$3, d0
  008434:  22 2e ff e8          move.l   -$18(a6), d1
  008438:  58 ae ff e8          addq.l   #$4, -$18(a6)
  00843c:  20 41                movea.l  d1, a0
  00843e:  20 b6 08 a4          move.l   -$5c(a6, d0.l), (a0)
  008442:  20 07                move.l   d7, d0
  008444:  e7 80                asl.l    #$3, d0
  008446:  22 2e ff e8          move.l   -$18(a6), d1
  00844a:  58 ae ff e8          addq.l   #$4, -$18(a6)
  00844e:  20 41                movea.l  d1, a0
  008450:  20 b6 08 a8          move.l   -$58(a6, d0.l), (a0)
  008454:  20 07                move.l   d7, d0
  008456:  52 87                addq.l   #$1, d7
L8458:
  008458:  be ae ff 6e          cmp.l    -$92(a6), d7
  00845c:  65 d2                bcs.b    $8430  ; -> L8430
  00845e:  48 6e ff 8d          pea.l    -$73(a6)
  008462:  20 57                movea.l  (a7), a0
  008464:  10 10                move.b   (a0), d0
  008466:  a0 5d                dc.w     $a05d
  008468:  20 57                movea.l  (a7), a0
  00846a:  10 80                move.b   d0, (a0)
  00846c:  58 8f                addq.l   #$4, a7
  00846e:  4a ae ff a0          tst.l    -$60(a6)
  008472:  67 20                beq.b    $8494  ; -> L8494
  008474:  20 6e ff 88          movea.l  -$78(a6), a0
  008478:  20 ae ff 9c          move.l   -$64(a6), (a0)
  00847c:  20 6e ff 88          movea.l  -$78(a6), a0
  008480:  21 6e ff a0 00 04    move.l   -$60(a6), $4(a0)
  008486:  20 6e ff 8e          movea.l  -$72(a6), a0
  00848a:  70 fe                moveq    #$fe, d0
  00848c:  21 40 00 08          move.l   d0, $8(a0)
  008490:  60 00 00 c8          bra.w    $855a  ; -> L855a
L8494:
  008494:  20 6e ff 88          movea.l  -$78(a6), a0
  008498:  20 ae ff 9c          move.l   -$64(a6), (a0)
  00849c:  20 6e ff 8e          movea.l  -$72(a6), a0
  0084a0:  21 6e ff 7e 00 08    move.l   -$82(a6), $8(a0)
  0084a6:  60 00 00 b2          bra.w    $855a  ; -> L855a
L84aa:
  0084aa:  20 6e ff 88          movea.l  -$78(a6), a0
  0084ae:  20 ae ff 9c          move.l   -$64(a6), (a0)
  0084b2:  20 6e ff 8e          movea.l  -$72(a6), a0
  0084b6:  21 6e ff 7e 00 08    move.l   -$82(a6), $8(a0)
  0084bc:  60 00 00 9c          bra.w    $855a  ; -> L855a
L84c0:
  0084c0:  20 38 08 88          move.l   $888.w, d0
  0084c4:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  0084ca:  20 40                movea.l  d0, a0
  0084cc:  20 50                movea.l  (a0), a0
  0084ce:  20 50                movea.l  (a0), a0
  0084d0:  2d 68 02 14 ff ec    move.l   $214(a0), -$14(a6)
  0084d6:  66 0c                bne.b    $84e4  ; -> L84e4
  0084d8:  20 6e ff 8e          movea.l  -$72(a6), a0
  0084dc:  70 ff                moveq    #$ff, d0
  0084de:  21 40 00 08          move.l   d0, $8(a0)
  0084e2:  60 76                bra.b    $855a  ; -> L855a
L84e4:
  0084e4:  48 6e ff 78          pea.l    -$88(a6)
  0084e8:  48 6e ff 72          pea.l    -$8e(a6)
  0084ec:  20 6e ff ec          movea.l  -$14(a6), a0
  0084f0:  20 50                movea.l  (a0), a0
  0084f2:  2f 28 00 c8          move.l   $c8(a0), -(a7)
  0084f6:  4e ba 8f 24          jsr      $141c(pc)  ; -> s7_sub_8df2
  0084fa:  70 00                moveq    #$0, d0
  0084fc:  30 2e ff 72          move.w   -$8e(a6), d0
  008500:  20 6e ff 88          movea.l  -$78(a6), a0
  008504:  20 80                move.l   d0, (a0)
  008506:  70 00                moveq    #$0, d0
  008508:  30 2e ff 74          move.w   -$8c(a6), d0
  00850c:  20 6e ff 88          movea.l  -$78(a6), a0
  008510:  21 40 00 04          move.l   d0, $4(a0)
  008514:  70 00                moveq    #$0, d0
  008516:  30 2e ff 76          move.w   -$8a(a6), d0
  00851a:  20 6e ff 88          movea.l  -$78(a6), a0
  00851e:  21 40 00 08          move.l   d0, $8(a0)
  008522:  70 00                moveq    #$0, d0
  008524:  30 2e ff 78          move.w   -$88(a6), d0
  008528:  20 6e ff 88          movea.l  -$78(a6), a0
  00852c:  21 40 00 0c          move.l   d0, $c(a0)
  008530:  70 00                moveq    #$0, d0
  008532:  30 2e ff 7a          move.w   -$86(a6), d0
  008536:  20 6e ff 88          movea.l  -$78(a6), a0
  00853a:  21 40 00 10          move.l   d0, $10(a0)
  00853e:  70 00                moveq    #$0, d0
  008540:  30 2e ff 7c          move.w   -$84(a6), d0
  008544:  20 6e ff 88          movea.l  -$78(a6), a0
  008548:  21 40 00 14          move.l   d0, $14(a0)
  00854c:  20 6e ff 8e          movea.l  -$72(a6), a0
  008550:  70 00                moveq    #$0, d0
  008552:  21 40 00 08          move.l   d0, $8(a0)
  008556:  4f ef 00 0c          lea.l    $c(a7), a7
L855a:
  00855a:  20 6e 00 0c          movea.l  $c(a6), a0
  00855e:  52 90                addq.l   #$1, (a0)
  008560:  20 6e ff 8e          movea.l  -$72(a6), a0
  008564:  70 00                moveq    #$0, d0
  008566:  21 40 00 04          move.l   d0, $4(a0)
L856a:
  00856a:  55 8f                subq.l   #$2, a7
  00856c:  1f 2e ff 93          move.b   -$6d(a6), -(a7)
  008570:  4e ba 1f c0          jsr      $a532(pc)  ; -> HWPrivProbe
  008574:  54 8f                addq.l   #$2, a7
  008576:  4c ee 18 f0 ff 56    movem.l  -$aa(a6), d4-d7/a3-a4
  00857c:  4e 5e                unlk     a6
  00857e:  4e 75                rts
* GA_ControlFFFFFFFD  -  System 7 $6C70 (same trap slot $FFFFFFFD, code r=0.74).
* S7: Patch #105 replaces special; no EngineDispatch command in its own body:
GA_ControlFFFFFFFD:
  008580:  4e 56 00 00          link.w   a6, #$0
  008584:  48 e7 00 18          movem.l  a3-a4, -(a7)
  008588:  28 6e 00 14          movea.l  $14(a6), a4
  00858c:  26 6e 00 0c          movea.l  $c(a6), a3
  008590:  2f 0c                move.l   a4, -(a7)
  008592:  2f 2e 00 10          move.l   $10(a6), -(a7)
  008596:  2f 0b                move.l   a3, -(a7)
  008598:  2f 2e 00 08          move.l   $8(a6), -(a7)
  00859c:  4e ba 0f 72          jsr      $9510(pc)  ; -> sub_9510
  0085a0:  4c ee 18 00 ff f8    movem.l  -$8(a6), a3-a4
  0085a6:  4e 5e                unlk     a6
  0085a8:  4e 75                rts
* GA_ControlFFFFFFFF  -  System 7 $6C8A (same trap slot $FFFFFFFF, code r=0.97).
* S7: Patch #103 replaces special; card commands: $00 $02 $12 $13 $14 $16 $17 $29
GA_ControlFFFFFFFF:
  0085aa:  4e 56 00 00          link.w   a6, #$0
  0085ae:  48 e7 01 10          movem.l  d7/a3, -(a7)
  0085b2:  26 6e 00 08          movea.l  $8(a6), a3
  0085b6:  20 53                movea.l  (a3), a0
  0085b8:  70 00                moveq    #$0, d0
  0085ba:  30 28 00 02          move.w   $2(a0), d0
  0085be:  2e 00                move.l   d0, d7
  0085c0:  2f 0b                move.l   a3, -(a7)
  0085c2:  4e ba 02 86          jsr      $884a(pc)  ; -> s7_sub_6f4e
  0085c6:  20 53                movea.l  (a3), a0
  0085c8:  70 02                moveq    #$2, d0
  0085ca:  c0 a8 00 1c          and.l    $1c(a0), d0
  0085ce:  58 8f                addq.l   #$4, a7
  0085d0:  67 04                beq.b    $85d6  ; -> L85d6
  0085d2:  70 ff                moveq    #$ff, d0
  0085d4:  60 58                bra.b    $862e  ; -> L862e
L85d6:
  0085d6:  70 00                moveq    #$0, d0
  0085d8:  2f 00                move.l   d0, -(a7)
  0085da:  2f 00                move.l   d0, -(a7)
  0085dc:  2f 00                move.l   d0, -(a7)
  0085de:  4e ba dc 44          jsr      $6224(pc)  ; -> EngineDispatch
  0085e2:  4a ae 00 0c          tst.l    $c(a6)
  0085e6:  4f ef 00 0c          lea.l    $c(a7), a7
  0085ea:  67 3c                beq.b    $8628  ; -> L8628
  0085ec:  20 53                movea.l  (a3), a0
  0085ee:  31 7c 00 05 00 02    move.w   #$5, $2(a0)
  0085f4:  20 53                movea.l  (a3), a0
  0085f6:  31 7c 01 f4 00 02    move.w   #$1f4, $2(a0)
  0085fc:  70 01                moveq    #$1, d0
  0085fe:  2f 00                move.l   d0, -(a7)
  008600:  48 6e 00 0c          pea.l    $c(a6)
  008604:  72 02                moveq    #$2, d1
  008606:  2f 01                move.l   d1, -(a7)
  008608:  4e ba dc 1a          jsr      $6224(pc)  ; -> EngineDispatch
  00860c:  20 53                movea.l  (a3), a0
  00860e:  21 40 01 74          move.l   d0, $174(a0)
  008612:  20 53                movea.l  (a3), a0
  008614:  31 47 00 02          move.w   d7, $2(a0)
  008618:  70 00                moveq    #$0, d0
  00861a:  2f 00                move.l   d0, -(a7)
  00861c:  2f 00                move.l   d0, -(a7)
  00861e:  2f 00                move.l   d0, -(a7)
  008620:  4e ba dc 02          jsr      $6224(pc)  ; -> EngineDispatch
  008624:  4f ef 00 18          lea.l    $18(a7), a7
L8628:
  008628:  20 53                movea.l  (a3), a0
  00862a:  20 28 01 74          move.l   $174(a0), d0
L862e:
  00862e:  4c ee 08 80 ff f8    movem.l  -$8(a6), d7/a3
  008634:  4e 5e                unlk     a6
  008636:  4e 75                rts
* GA_ControlFFFFFFFE  -  System 7 $6D1E (same trap slot $FFFFFFFE, code r=0.91).
* S7: Patch #104 replaces special; card commands: $00 $11 $26
GA_ControlFFFFFFFE:
  008638:  48 e7 01 10          movem.l  d7/a3, -(a7)
  00863c:  20 38 08 88          move.l   $888.w, d0
  008640:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  008646:  20 40                movea.l  d0, a0
  008648:  20 50                movea.l  (a0), a0
  00864a:  20 50                movea.l  (a0), a0
  00864c:  26 68 02 14          movea.l  $214(a0), a3
  008650:  20 0b                move.l   a3, d0
  008652:  67 40                beq.b    $8694  ; -> L8694
  008654:  70 0e                moveq    #$e, d0
  008656:  2f 00                move.l   d0, -(a7)
  008658:  72 00                moveq    #$0, d1
  00865a:  2f 01                move.l   d1, -(a7)
  00865c:  70 26                moveq    #$26, d0
  00865e:  2f 00                move.l   d0, -(a7)
  008660:  4e ba db c2          jsr      $6224(pc)  ; -> EngineDispatch
  008664:  72 00                moveq    #$0, d1
  008666:  4a 80                tst.l    d0
  008668:  57 c1                seq.b    d1
  00866a:  44 01                neg.b    d1
  00866c:  2e 01                move.l   d1, d7
  00866e:  70 00                moveq    #$0, d0
  008670:  2f 00                move.l   d0, -(a7)
  008672:  2f 00                move.l   d0, -(a7)
  008674:  72 11                moveq    #$11, d1
  008676:  2f 01                move.l   d1, -(a7)
  008678:  4e ba db aa          jsr      $6224(pc)  ; -> EngineDispatch
  00867c:  70 00                moveq    #$0, d0
  00867e:  2f 00                move.l   d0, -(a7)
  008680:  2f 00                move.l   d0, -(a7)
  008682:  2f 00                move.l   d0, -(a7)
  008684:  4e ba db 9e          jsr      $6224(pc)  ; -> EngineDispatch
  008688:  20 53                movea.l  (a3), a0
  00868a:  08 a8 00 00 00 1f    bclr.b   #$0, $1f(a0)
  008690:  4f ef 00 24          lea.l    $24(a7), a7
L8694:
  008694:  20 07                move.l   d7, d0
  008696:  4c df 08 80          movem.l  (a7)+, d7/a3
  00869a:  4e 75                rts
* StoreCtxWord_AA6  -  System 7 $6D92 (similar code, r=0.88).
* S7: StoreCtxWord_AA6  -  the single most-called helper (~159x).  Fetches the
StoreCtxWord_AA6:
  00869c:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  0086a0:  2c 2f 00 14          move.l   $14(a7), d6
  0086a4:  20 38 08 88          move.l   $888.w, d0
  0086a8:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  0086ae:  20 40                movea.l  d0, a0
  0086b0:  20 50                movea.l  (a0), a0
  0086b2:  28 50                movea.l  (a0), a4
  0086b4:  20 0c                move.l   a4, d0
  0086b6:  66 04                bne.b    $86bc  ; -> L86bc
  0086b8:  70 00                moveq    #$0, d0
  0086ba:  60 4e                bra.b    $870a  ; -> L870a
L86bc:
  0086bc:  39 46 0a a6          move.w   d6, $aa6(a4)
  0086c0:  7e 00                moveq    #$0, d7
  0086c2:  47 ec 02 78          lea.l    $278(a4), a3
  0086c6:  60 12                bra.b    $86da  ; -> L86da
L86c8:
  0086c8:  bc 93                cmp.l    (a3), d6
  0086ca:  66 06                bne.b    $86d2  ; -> L86d2
  0086cc:  20 2b 00 04          move.l   $4(a3), d0
  0086d0:  60 38                bra.b    $870a  ; -> L870a
L86d2:
  0086d2:  20 07                move.l   d7, d0
  0086d4:  52 87                addq.l   #$1, d7
  0086d6:  d6 fc 00 10          adda.w   #$10, a3
L86da:
  0086da:  30 2c 02 2c          move.w   $22c(a4), d0
  0086de:  48 c0                ext.l    d0
  0086e0:  b0 87                cmp.l    d7, d0
  0086e2:  6e e4                bgt.b    $86c8  ; -> L86c8
  0086e4:  70 01                moveq    #$1, d0
  0086e6:  2f 00                move.l   d0, -(a7)
  0086e8:  72 07                moveq    #$7, d1
  0086ea:  2f 01                move.l   d1, -(a7)
  0086ec:  24 38 08 88          move.l   $888.w, d2
  0086f0:  c4 bc 00 ff ff ff    and.l    #$ffffff, d2
  0086f6:  20 42                movea.l  d2, a0
  0086f8:  20 50                movea.l  (a0), a0
  0086fa:  20 50                movea.l  (a0), a0
  0086fc:  2f 28 02 14          move.l   $214(a0), -(a7)
  008700:  4e ba 07 52          jsr      $8e54(pc)  ; -> s7_sub_75fe
  008704:  70 ff                moveq    #$ff, d0
  008706:  4f ef 00 0c          lea.l    $c(a7), a7
L870a:
  00870a:  4c df 18 c0          movem.l  (a7)+, d6-d7/a3-a4
  00870e:  4e 75                rts
* s7_sub_6e14  -  System 7 $6E14 (similar code, r=0.83).
s7_sub_6e14:
  008710:  48 e7 07 18          movem.l  d5-d7/a3-a4, -(a7)
  008714:  20 38 08 88          move.l   $888.w, d0
  008718:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  00871e:  20 40                movea.l  d0, a0
  008720:  20 50                movea.l  (a0), a0
  008722:  20 50                movea.l  (a0), a0
  008724:  28 68 02 14          movea.l  $214(a0), a4
  008728:  20 0c                move.l   a4, d0
  00872a:  66 06                bne.b    $8732  ; -> L8732
  00872c:  70 01                moveq    #$1, d0
  00872e:  60 00 00 90          bra.w    $87c0  ; -> L87c0
L8732:
  008732:  26 54                movea.l  (a4), a3
  008734:  70 27                moveq    #$27, d0
  008736:  c0 ab 00 08          and.l    $8(a3), d0
  00873a:  72 27                moveq    #$27, d1
  00873c:  b2 80                cmp.l    d0, d1
  00873e:  67 04                beq.b    $8744  ; -> L8744
  008740:  70 01                moveq    #$1, d0
  008742:  60 7c                bra.b    $87c0  ; -> L87c0
L8744:
  008744:  20 3c 00 00 06 00    move.l   #$600, d0
  00874a:  c0 ab 00 08          and.l    $8(a3), d0
  00874e:  67 04                beq.b    $8754  ; -> L8754
  008750:  70 01                moveq    #$1, d0
  008752:  60 6c                bra.b    $87c0  ; -> L87c0
L8754:
  008754:  55 8f                subq.l   #$2, a7
  008756:  70 00                moveq    #$0, d0
  008758:  1f 00                move.b   d0, -(a7)
  00875a:  4e ba 1d d6          jsr      $a532(pc)  ; -> HWPrivProbe
  00875e:  1a 1f                move.b   (a7)+, d5
  008760:  20 6b 00 10          movea.l  $10(a3), a0
  008764:  2c 10                move.l   (a0), d6
  008766:  2e 2b 00 1c          move.l   $1c(a3), d7
  00876a:  55 8f                subq.l   #$2, a7
  00876c:  1f 05                move.b   d5, -(a7)
  00876e:  4e ba 1d c2          jsr      $a532(pc)  ; -> HWPrivProbe
  008772:  70 18                moveq    #$18, d0
  008774:  c0 86                and.l    d6, d0
  008776:  54 8f                addq.l   #$2, a7
  008778:  67 04                beq.b    $877e  ; -> L877e
  00877a:  70 01                moveq    #$1, d0
  00877c:  60 42                bra.b    $87c0  ; -> L87c0
L877e:
  00877e:  70 40                moveq    #$40, d0
  008780:  c0 87                and.l    d7, d0
  008782:  67 12                beq.b    $8796  ; -> L8796
  008784:  20 6b 00 0c          movea.l  $c(a3), a0
  008788:  20 28 01 c8          move.l   $1c8(a0), d0
  00878c:  b0 ab 00 b8          cmp.l    $b8(a3), d0
  008790:  54 c0                scc.b    d0
  008792:  44 00                neg.b    d0
  008794:  60 2a                bra.b    $87c0  ; -> L87c0
L8796:
  008796:  70 04                moveq    #$4, d0
  008798:  c0 87                and.l    d7, d0
  00879a:  67 22                beq.b    $87be  ; -> L87be
  00879c:  4a ab 05 e0          tst.l    $5e0(a3)
  0087a0:  67 12                beq.b    $87b4  ; -> L87b4
  0087a2:  20 6b 00 0c          movea.l  $c(a3), a0
  0087a6:  22 6b 05 e0          movea.l  $5e0(a3), a1
  0087aa:  22 a8 00 1c          move.l   $1c(a0), (a1)
  0087ae:  70 00                moveq    #$0, d0
  0087b0:  27 40 05 e0          move.l   d0, $5e0(a3)
L87b4:
  0087b4:  70 02                moveq    #$2, d0
  0087b6:  c0 86                and.l    d6, d0
  0087b8:  56 c0                sne.b    d0
  0087ba:  44 00                neg.b    d0
  0087bc:  60 02                bra.b    $87c0  ; -> L87c0
L87be:
  0087be:  70 01                moveq    #$1, d0
L87c0:
  0087c0:  4c df 18 e0          movem.l  (a7)+, d5-d7/a3-a4
  0087c4:  4e 75                rts
sub_87c6:
  0087c6:  2f 0b                move.l   a3, -(a7)
  0087c8:  20 38 08 88          move.l   $888.w, d0
  0087cc:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  0087d2:  20 40                movea.l  d0, a0
  0087d4:  20 50                movea.l  (a0), a0
  0087d6:  20 50                movea.l  (a0), a0
  0087d8:  26 68 02 14          movea.l  $214(a0), a3
  0087dc:  20 0b                move.l   a3, d0
  0087de:  66 04                bne.b    $87e4  ; -> L87e4
  0087e0:  70 ff                moveq    #$ff, d0
  0087e2:  60 0a                bra.b    $87ee  ; -> L87ee
L87e4:
  0087e4:  20 53                movea.l  (a3), a0
  0087e6:  20 68 00 0c          movea.l  $c(a0), a0
  0087ea:  20 28 00 1c          move.l   $1c(a0), d0
L87ee:
  0087ee:  26 5f                movea.l  (a7)+, a3
  0087f0:  4e 75                rts
sub_87f2:
  0087f2:  48 e7 00 18          movem.l  a3-a4, -(a7)
  0087f6:  28 6f 00 0c          movea.l  $c(a7), a4
  0087fa:  20 38 08 88          move.l   $888.w, d0
  0087fe:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  008804:  20 40                movea.l  d0, a0
  008806:  20 50                movea.l  (a0), a0
  008808:  20 50                movea.l  (a0), a0
  00880a:  26 68 02 14          movea.l  $214(a0), a3
  00880e:  20 0b                move.l   a3, d0
  008810:  66 04                bne.b    $8816  ; -> L8816
  008812:  70 ff                moveq    #$ff, d0
  008814:  60 06                bra.b    $881c  ; -> L881c
L8816:
  008816:  20 53                movea.l  (a3), a0
  008818:  21 4c 05 e0          move.l   a4, $5e0(a0)
L881c:
  00881c:  4c df 18 00          movem.l  (a7)+, a3-a4
  008820:  4e 75                rts
* s7_sub_6f1c  -  System 7 $6F1C (similar code, r=0.85).
s7_sub_6f1c:
  008822:  2f 0b                move.l   a3, -(a7)
  008824:  20 38 08 88          move.l   $888.w, d0
  008828:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  00882e:  20 40                movea.l  d0, a0
  008830:  20 50                movea.l  (a0), a0
  008832:  20 50                movea.l  (a0), a0
  008834:  26 68 02 14          movea.l  $214(a0), a3
  008838:  20 0b                move.l   a3, d0
  00883a:  67 08                beq.b    $8844  ; -> L8844
  00883c:  20 53                movea.l  (a3), a0
  00883e:  20 28 00 c8          move.l   $c8(a0), d0
  008842:  60 02                bra.b    $8846  ; -> L8846
L8844:
  008844:  70 00                moveq    #$0, d0
L8846:
  008846:  26 5f                movea.l  (a7)+, a3
  008848:  4e 75                rts
* Card (re)initialisation  -  System 7 sub_6f4e.  Called by
* EngineDispatch when the unit is not ready.
s7_sub_6f4e:
  00884a:  4e 56 ff ec          link.w   a6, #$ffec
  00884e:  48 e7 17 18          movem.l  d3/d5-d7/a3-a4, -(a7)
  008852:  42 6e ff fa          clr.w    -$6(a6)
  008856:  42 6e ff f8          clr.w    -$8(a6)
  00885a:  42 6e ff f6          clr.w    -$a(a6)
  00885e:  42 6e ff f4          clr.w    -$c(a6)
  008862:  20 6e 00 08          movea.l  $8(a6), a0
  008866:  2d 50 ff fc          move.l   (a0), -$4(a6)
  00886a:  20 6e ff fc          movea.l  -$4(a6), a0
  00886e:  20 3c 00 00 06 00    move.l   #$600, d0
  008874:  c0 a8 00 08          and.l    $8(a0), d0
  008878:  67 06                beq.b    $8880  ; -> L8880
  00887a:  70 00                moveq    #$0, d0
  00887c:  60 00 03 9e          bra.w    $8c1c  ; -> L8c1c
L8880:
  008880:  20 38 08 88          move.l   $888.w, d0
  008884:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  00888a:  20 40                movea.l  d0, a0
  00888c:  20 50                movea.l  (a0), a0
  00888e:  26 50                movea.l  (a0), a3
  008890:  20 0b                move.l   a3, d0
  008892:  66 06                bne.b    $889a  ; -> L889a
  008894:  70 00                moveq    #$0, d0
  008896:  60 00 03 84          bra.w    $8c1c  ; -> L8c1c
L889a:
  00889a:  20 6e ff fc          movea.l  -$4(a6), a0
  00889e:  70 02                moveq    #$2, d0
  0088a0:  c0 a8 00 1c          and.l    $1c(a0), d0
  0088a4:  67 2c                beq.b    $88d2  ; -> L88d2
  0088a6:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0088aa:  4e ba 05 20          jsr      $8dcc(pc)  ; -> s7_sub_7570
  0088ae:  4a 80                tst.l    d0
  0088b0:  58 8f                addq.l   #$4, a7
  0088b2:  67 1e                beq.b    $88d2  ; -> L88d2
  0088b4:  20 6e ff fc          movea.l  -$4(a6), a0
  0088b8:  31 7c 00 06 01 5c    move.w   #$6, $15c(a0)
  0088be:  70 01                moveq    #$1, d0
  0088c0:  2f 00                move.l   d0, -(a7)
  0088c2:  72 06                moveq    #$6, d1
  0088c4:  2f 01                move.l   d1, -(a7)
  0088c6:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0088ca:  4e ba 05 88          jsr      $8e54(pc)  ; -> s7_sub_75fe
  0088ce:  4f ef 00 0c          lea.l    $c(a7), a7
L88d2:
  0088d2:  55 8f                subq.l   #$2, a7
  0088d4:  70 00                moveq    #$0, d0
  0088d6:  1f 00                move.b   d0, -(a7)
  0088d8:  4e ba 1c 58          jsr      $a532(pc)  ; -> HWPrivProbe
  0088dc:  1a 1f                move.b   (a7)+, d5
  0088de:  20 6e ff fc          movea.l  -$4(a6), a0
  0088e2:  28 68 00 0c          movea.l  $c(a0), a4
  0088e6:  20 38 08 88          move.l   $888.w, d0
  0088ea:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  0088f0:  2d 40 ff f0          move.l   d0, -$10(a6)
  0088f4:  67 00 00 9a          beq.w    $8990  ; -> L8990
  0088f8:  20 6e ff f0          movea.l  -$10(a6), a0
  0088fc:  0c a8 07 5b cd 15 00 20 cmpi.l   #$75bcd15, $20(a0)
  008904:  66 00 00 8a          bne.w    $8990  ; -> L8990
  008908:  20 6e ff f0          movea.l  -$10(a6), a0
  00890c:  20 68 00 0c          movea.l  $c(a0), a0
  008910:  70 00                moveq    #$0, d0
  008912:  20 80                move.l   d0, (a0)
  008914:  20 6e ff f0          movea.l  -$10(a6), a0
  008918:  20 68 00 08          movea.l  $8(a0), a0
  00891c:  20 80                move.l   d0, (a0)
  00891e:  20 6e ff f0          movea.l  -$10(a6), a0
  008922:  20 68 00 10          movea.l  $10(a0), a0
  008926:  43 ee ff f4          lea.l    -$c(a6), a1
  00892a:  20 d9                move.l   (a1)+, (a0)+
  00892c:  20 d9                move.l   (a1)+, (a0)+
  00892e:  20 6e ff f0          movea.l  -$10(a6), a0
  008932:  20 68 00 28          movea.l  $28(a0), a0
  008936:  2c 10                move.l   (a0), d6
  008938:  67 1c                beq.b    $8956  ; -> L8956
  00893a:  20 6e ff f0          movea.l  -$10(a6), a0
  00893e:  2f 28 00 2c          move.l   $2c(a0), -(a7)
  008942:  20 6e ff f0          movea.l  -$10(a6), a0
  008946:  2f 28 00 04          move.l   $4(a0), -(a7)
  00894a:  20 06                move.l   d6, d0
  00894c:  52 80                addq.l   #$1, d0
  00894e:  e5 88                lsl.l    #$2, d0
  008950:  2f 00                move.l   d0, -(a7)
  008952:  4e ba 1b 6a          jsr      $a4be(pc)  ; -> sub_a4be
L8956:
  008956:  20 6e ff f0          movea.l  -$10(a6), a0
  00895a:  20 68 00 28          movea.l  $28(a0), a0
  00895e:  70 00                moveq    #$0, d0
  008960:  20 80                move.l   d0, (a0)
  008962:  20 6e ff f0          movea.l  -$10(a6), a0
  008966:  21 40 00 38          move.l   d0, $38(a0)
  00896a:  20 6e ff f0          movea.l  -$10(a6), a0
  00896e:  21 40 00 18          move.l   d0, $18(a0)
  008972:  20 6e ff f0          movea.l  -$10(a6), a0
  008976:  21 40 00 3c          move.l   d0, $3c(a0)
  00897a:  20 6e ff f0          movea.l  -$10(a6), a0
  00897e:  20 68 00 1c          movea.l  $1c(a0), a0
  008982:  43 ee ff f4          lea.l    -$c(a6), a1
  008986:  20 d9                move.l   (a1)+, (a0)+
  008988:  20 d9                move.l   (a1)+, (a0)+
  00898a:  72 04                moveq    #$4, d1
  00898c:  29 41 01 c0          move.l   d1, $1c0(a4)
L8990:
  008990:  20 6e ff fc          movea.l  -$4(a6), a0
  008994:  02 a8 ff ff ff a0 00 1c andi.l   #$ffffffa0, $1c(a0)
  00899c:  20 6e ff fc          movea.l  -$4(a6), a0
  0089a0:  70 00                moveq    #$0, d0
  0089a2:  21 40 00 18          move.l   d0, $18(a0)
  0089a6:  20 6e ff fc          movea.l  -$4(a6), a0
  0089aa:  21 40 00 b0          move.l   d0, $b0(a0)
  0089ae:  20 6e ff fc          movea.l  -$4(a6), a0
  0089b2:  21 40 00 c0          move.l   d0, $c0(a0)
  0089b6:  20 6e ff fc          movea.l  -$4(a6), a0
  0089ba:  21 40 01 14          move.l   d0, $114(a0)
  0089be:  20 6e ff fc          movea.l  -$4(a6), a0
  0089c2:  21 40 00 c8          move.l   d0, $c8(a0)
  0089c6:  20 6e ff fc          movea.l  -$4(a6), a0
  0089ca:  21 40 05 e0          move.l   d0, $5e0(a0)
  0089ce:  20 6e ff fc          movea.l  -$4(a6), a0
  0089d2:  52 68 01 80          addq.w   #$1, $180(a0)
  0089d6:  2f 2e 00 08          move.l   $8(a6), -(a7)
  0089da:  4e ba f2 7a          jsr      $7c56(pc)  ; -> s7_sub_63b0
  0089de:  7c 00                moveq    #$0, d6
  0089e0:  58 8f                addq.l   #$4, a7
L89e2:
  0089e2:  20 6e ff fc          movea.l  -$4(a6), a0
  0089e6:  2d 68 00 10 ff ec    move.l   $10(a0), -$14(a6)
  0089ec:  20 6e ff ec          movea.l  -$14(a6), a0
  0089f0:  70 02                moveq    #$2, d0
  0089f2:  20 80                move.l   d0, (a0)
  0089f4:  72 00                moveq    #$0, d1
  0089f6:  29 41 00 18          move.l   d1, $18(a4)
  0089fa:  29 41 00 20          move.l   d1, $20(a4)
  0089fe:  70 01                moveq    #$1, d0
  008a00:  29 40 00 48          move.l   d0, $48(a4)
  008a04:  20 6e ff fc          movea.l  -$4(a6), a0
  008a08:  21 41 00 20          move.l   d1, $20(a0)
  008a0c:  29 41 00 4c          move.l   d1, $4c(a4)
  008a10:  20 6e ff fc          movea.l  -$4(a6), a0
  008a14:  29 68 00 04 00 50    move.l   $4(a0), $50(a4)
  008a1a:  29 41 00 28          move.l   d1, $28(a4)
  008a1e:  4a 86                tst.l    d6
  008a20:  66 04                bne.b    $8a26  ; -> L8a26
  008a22:  74 02                moveq    #$2, d2
  008a24:  60 0c                bra.b    $8a32  ; -> L8a32
L8a26:
  008a26:  20 6e ff fc          movea.l  -$4(a6), a0
  008a2a:  70 00                moveq    #$0, d0
  008a2c:  30 28 00 02          move.w   $2(a0), d0
  008a30:  24 00                move.l   d0, d2
L8a32:
  008a32:  2e 02                move.l   d2, d7
  008a34:  de b8 01 6a          add.l    $16a.w, d7
  008a38:  70 ff                moveq    #$ff, d0
  008a3a:  29 40 00 14          move.l   d0, $14(a4)
  008a3e:  60 22                bra.b    $8a62  ; -> L8a62
L8a40:
  008a40:  4a ac 00 28          tst.l    $28(a4)
  008a44:  67 10                beq.b    $8a56  ; -> L8a56
  008a46:  20 6e ff fc          movea.l  -$4(a6), a0
  008a4a:  48 68 00 24          pea.l    $24(a0)
  008a4e:  2f 0c                move.l   a4, -(a7)
  008a50:  4e ba f2 92          jsr      $7ce4(pc)  ; -> s7_sub_6442
  008a54:  50 8f                addq.l   #$8, a7
L8a56:
  008a56:  4a ac 00 18          tst.l    $18(a4)
  008a5a:  67 06                beq.b    $8a62  ; -> L8a62
  008a5c:  4a ac 00 28          tst.l    $28(a4)
  008a60:  67 06                beq.b    $8a68  ; -> L8a68
L8a62:
  008a62:  be b8 01 6a          cmp.l    $16a.w, d7
  008a66:  6c d8                bge.b    $8a40  ; -> L8a40
L8a68:
  008a68:  4a 86                tst.l    d6
  008a6a:  67 06                beq.b    $8a72  ; -> L8a72
  008a6c:  be b8 01 6a          cmp.l    $16a.w, d7
  008a70:  6e 0c                bgt.b    $8a7e  ; -> L8a7e
L8a72:
  008a72:  20 06                move.l   d6, d0
  008a74:  52 86                addq.l   #$1, d6
  008a76:  70 04                moveq    #$4, d0
  008a78:  b0 86                cmp.l    d6, d0
  008a7a:  6e 00 ff 66          bgt.w    $89e2  ; -> L89e2
L8a7e:
  008a7e:  70 04                moveq    #$4, d0
  008a80:  b0 86                cmp.l    d6, d0
  008a82:  66 2e                bne.b    $8ab2  ; -> L8ab2
  008a84:  70 01                moveq    #$1, d0
  008a86:  2f 00                move.l   d0, -(a7)
  008a88:  72 03                moveq    #$3, d1
  008a8a:  2f 01                move.l   d1, -(a7)
  008a8c:  2f 2e 00 08          move.l   $8(a6), -(a7)
  008a90:  4e ba 03 c2          jsr      $8e54(pc)  ; -> s7_sub_75fe
  008a94:  20 6e ff fc          movea.l  -$4(a6), a0
  008a98:  00 a8 00 00 00 10 00 1c ori.l    #$10, $1c(a0)
  008aa0:  55 8f                subq.l   #$2, a7
  008aa2:  1f 05                move.b   d5, -(a7)
  008aa4:  4e ba 1a 8c          jsr      $a532(pc)  ; -> HWPrivProbe
  008aa8:  70 ff                moveq    #$ff, d0
  008aaa:  4f ef 00 0e          lea.l    $e(a7), a7
  008aae:  60 00 01 6c          bra.w    $8c1c  ; -> L8c1c
L8ab2:
  008ab2:  70 01                moveq    #$1, d0
  008ab4:  b0 ac 00 1c          cmp.l    $1c(a4), d0
  008ab8:  67 2e                beq.b    $8ae8  ; -> L8ae8
  008aba:  70 01                moveq    #$1, d0
  008abc:  2f 00                move.l   d0, -(a7)
  008abe:  72 03                moveq    #$3, d1
  008ac0:  2f 01                move.l   d1, -(a7)
  008ac2:  2f 2e 00 08          move.l   $8(a6), -(a7)
  008ac6:  4e ba 03 8c          jsr      $8e54(pc)  ; -> s7_sub_75fe
  008aca:  20 6e ff fc          movea.l  -$4(a6), a0
  008ace:  00 a8 00 00 00 10 00 1c ori.l    #$10, $1c(a0)
  008ad6:  55 8f                subq.l   #$2, a7
  008ad8:  1f 05                move.b   d5, -(a7)
  008ada:  4e ba 1a 56          jsr      $a532(pc)  ; -> HWPrivProbe
  008ade:  70 ff                moveq    #$ff, d0
  008ae0:  4f ef 00 0e          lea.l    $e(a7), a7
  008ae4:  60 00 01 36          bra.w    $8c1c  ; -> L8c1c
* Packet-pointer read-back  -  System 7 $726A-$728E.  a4 = packet.
* packet+$20 = unit+$14; unit+$18 = (packet & $FFF00000) |
* ([packet+$54] & $000FFFFF): the argument area is wherever the card
* published it (System 6 Antelope: packet+$64C), in the packet's 1 MB
* window.  unit+$1C |= 1 (ready); then selector 0 through EngineDispatch.
L8ae8:
  008ae8:  20 6e ff fc          movea.l  -$4(a6), a0
  008aec:  29 68 00 14 00 20    move.l   $14(a0), $20(a4)
  008af2:  20 3c 00 0f ff ff    move.l   #$fffff, d0
  008af8:  c0 ac 00 54          and.l    $54(a4), d0
  008afc:  22 0c                move.l   a4, d1
  008afe:  24 3c ff f0 00 00    move.l   #$fff00000, d2
  008b04:  c4 81                and.l    d1, d2
  008b06:  84 80                or.l     d0, d2
  008b08:  20 6e ff fc          movea.l  -$4(a6), a0
  008b0c:  21 42 00 18          move.l   d2, $18(a0)
  008b10:  20 6e ff fc          movea.l  -$4(a6), a0
  008b14:  00 a8 00 00 00 01 00 1c ori.l    #$1, $1c(a0)
  008b1c:  55 8f                subq.l   #$2, a7
  008b1e:  1f 05                move.b   d5, -(a7)
  008b20:  4e ba 1a 10          jsr      $a532(pc)  ; -> HWPrivProbe
  008b24:  70 00                moveq    #$0, d0
  008b26:  2f 00                move.l   d0, -(a7)
  008b28:  2f 00                move.l   d0, -(a7)
  008b2a:  2f 00                move.l   d0, -(a7)
  008b2c:  4e ba d6 f6          jsr      $6224(pc)  ; -> EngineDispatch
  008b30:  4e ba 04 a6          jsr      $8fd8(pc)  ; -> s7_sub_77a6
  008b34:  2f 2e 00 08          move.l   $8(a6), -(a7)
  008b38:  4e ba d6 76          jsr      $61b0(pc)  ; -> s7_sub_494e
  008b3c:  72 01                moveq    #$1, d1
  008b3e:  b2 80                cmp.l    d0, d1
  008b40:  4f ef 00 12          lea.l    $12(a7), a7
  008b44:  67 46                beq.b    $8b8c  ; -> L8b8c
  008b46:  20 6e ff fc          movea.l  -$4(a6), a0
  008b4a:  70 02                moveq    #$2, d0
  008b4c:  c0 a8 00 1c          and.l    $1c(a0), d0
  008b50:  67 16                beq.b    $8b68  ; -> L8b68
  008b52:  70 00                moveq    #$0, d0
  008b54:  2f 00                move.l   d0, -(a7)
  008b56:  72 04                moveq    #$4, d1
  008b58:  2f 01                move.l   d1, -(a7)
  008b5a:  2f 2e 00 08          move.l   $8(a6), -(a7)
  008b5e:  4e ba 02 f4          jsr      $8e54(pc)  ; -> s7_sub_75fe
  008b62:  4f ef 00 0c          lea.l    $c(a7), a7
  008b66:  60 14                bra.b    $8b7c  ; -> L8b7c
L8b68:
  008b68:  70 01                moveq    #$1, d0
  008b6a:  2f 00                move.l   d0, -(a7)
  008b6c:  72 04                moveq    #$4, d1
  008b6e:  2f 01                move.l   d1, -(a7)
  008b70:  2f 2e 00 08          move.l   $8(a6), -(a7)
  008b74:  4e ba 02 de          jsr      $8e54(pc)  ; -> s7_sub_75fe
  008b78:  4f ef 00 0c          lea.l    $c(a7), a7
L8b7c:
  008b7c:  20 6e ff fc          movea.l  -$4(a6), a0
  008b80:  08 a8 00 00 00 1f    bclr.b   #$0, $1f(a0)
  008b86:  70 ff                moveq    #$ff, d0
  008b88:  60 00 00 92          bra.w    $8c1c  ; -> L8c1c
L8b8c:
  008b8c:  20 6e ff fc          movea.l  -$4(a6), a0
  008b90:  4a a8 00 c4          tst.l    $c4(a0)
  008b94:  66 00 00 84          bne.w    $8c1a  ; -> L8c1a
  008b98:  60 26                bra.b    $8bc0  ; -> L8bc0
L8b9a:
  008b9a:  04 ab 00 00 00 c8 02 68 subi.l   #$c8, $268(a3)
  008ba2:  4a ab 02 68          tst.l    $268(a3)
  008ba6:  62 18                bhi.b    $8bc0  ; -> L8bc0
  008ba8:  70 01                moveq    #$1, d0
  008baa:  2f 00                move.l   d0, -(a7)
  008bac:  72 09                moveq    #$9, d1
  008bae:  2f 01                move.l   d1, -(a7)
  008bb0:  2f 2e 00 08          move.l   $8(a6), -(a7)
  008bb4:  4e ba 02 9e          jsr      $8e54(pc)  ; -> s7_sub_75fe
  008bb8:  70 ff                moveq    #$ff, d0
  008bba:  4f ef 00 0c          lea.l    $c(a7), a7
  008bbe:  60 5c                bra.b    $8c1c  ; -> L8c1c
L8bc0:
  008bc0:  2f 2b 02 68          move.l   $268(a3), -(a7)
  008bc4:  20 6e ff fc          movea.l  -$4(a6), a0
  008bc8:  2f 28 00 0c          move.l   $c(a0), -(a7)
  008bcc:  4e ba 00 58          jsr      $8c26(pc)  ; -> s7_sub_73c4
  008bd0:  28 40                movea.l  d0, a4
  008bd2:  20 0c                move.l   a4, d0
  008bd4:  50 8f                addq.l   #$8, a7
  008bd6:  67 c2                beq.b    $8b9a  ; -> L8b9a
  008bd8:  20 2b 02 68          move.l   $268(a3), d0
  008bdc:  72 64                moveq    #$64, d1
  008bde:  90 81                sub.l    d1, d0
  008be0:  20 6e ff fc          movea.l  -$4(a6), a0
  008be4:  21 40 00 bc          move.l   d0, $bc(a0)
  008be8:  20 6e ff fc          movea.l  -$4(a6), a0
  008bec:  21 4c 00 c4          move.l   a4, $c4(a0)
  008bf0:  20 6e ff fc          movea.l  -$4(a6), a0
  008bf4:  21 4c 00 ac          move.l   a4, $ac(a0)
  008bf8:  20 6e ff fc          movea.l  -$4(a6), a0
  008bfc:  22 6e ff fc          movea.l  -$4(a6), a1
  008c00:  23 68 00 ac 00 b0    move.l   $ac(a0), $b0(a1)
  008c06:  20 6e ff fc          movea.l  -$4(a6), a0
  008c0a:  70 00                moveq    #$0, d0
  008c0c:  21 40 00 b4          move.l   d0, $b4(a0)
  008c10:  2f 2e 00 08          move.l   $8(a6), -(a7)
  008c14:  4e ba f0 40          jsr      $7c56(pc)  ; -> s7_sub_63b0
  008c18:  58 8f                addq.l   #$4, a7
L8c1a:
  008c1a:  70 00                moveq    #$0, d0
L8c1c:
  008c1c:  4c ee 18 e8 ff d4    movem.l  -$2c(a6), d3/d5-d7/a3-a4
  008c22:  4e 5e                unlk     a6
  008c24:  4e 75                rts
* s7_sub_73c4  -  System 7 $73C4 (similar code, r=0.99).
s7_sub_73c4:
  008c26:  4e 56 ff fc          link.w   a6, #$fffc
  008c2a:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  008c2e:  2e 2e 00 0c          move.l   $c(a6), d7
  008c32:  20 6e 00 08          movea.l  $8(a6), a0
  008c36:  28 68 00 10          movea.l  $10(a0), a4
  008c3a:  20 0c                move.l   a4, d0
  008c3c:  66 06                bne.b    $8c44  ; -> L8c44
  008c3e:  70 00                moveq    #$0, d0
  008c40:  60 00 00 d4          bra.w    $8d16  ; -> L8d16
L8c44:
  008c44:  20 0c                move.l   a4, d0
  008c46:  22 3c 00 0f ff ff    move.l   #$fffff, d1
  008c4c:  c2 80                and.l    d0, d1
  008c4e:  20 3c ff f0 00 00    move.l   #$fff00000, d0
  008c54:  c0 ae 00 08          and.l    $8(a6), d0
  008c58:  80 81                or.l     d1, d0
  008c5a:  26 40                movea.l  d0, a3
  008c5c:  0c 93 00 01 00 00    cmpi.l   #$10000, (a3)
  008c62:  63 18                bls.b    $8c7c  ; -> L8c7c
  008c64:  20 6e 00 08          movea.l  $8(a6), a0
  008c68:  20 3c 00 00 ff fc    move.l   #$fffc, d0
  008c6e:  c0 a8 00 10          and.l    $10(a0), d0
  008c72:  22 3c 00 00 ff f0    move.l   #$fff0, d1
  008c78:  92 80                sub.l    d0, d1
  008c7a:  26 81                move.l   d1, (a3)
L8c7c:
  008c7c:  20 07                move.l   d7, d0
  008c7e:  56 80                addq.l   #$3, d0
  008c80:  7e fc                moveq    #$fc, d7
  008c82:  ce 80                and.l    d0, d7
  008c84:  20 0c                move.l   a4, d0
  008c86:  22 3c 00 0f ff ff    move.l   #$fffff, d1
  008c8c:  c2 80                and.l    d0, d1
  008c8e:  20 3c ff f0 00 00    move.l   #$fff00000, d0
  008c94:  c0 ae 00 08          and.l    $8(a6), d0
  008c98:  80 81                or.l     d1, d0
  008c9a:  26 40                movea.l  d0, a3
  008c9c:  60 1c                bra.b    $8cba  ; -> L8cba
L8c9e:
  008c9e:  28 6b 00 04          movea.l  $4(a3), a4
  008ca2:  20 3c 00 0f ff ff    move.l   #$fffff, d0
  008ca8:  c0 ab 00 04          and.l    $4(a3), d0
  008cac:  22 3c ff f0 00 00    move.l   #$fff00000, d1
  008cb2:  c2 ae 00 08          and.l    $8(a6), d1
  008cb6:  82 80                or.l     d0, d1
  008cb8:  26 41                movea.l  d1, a3
L8cba:
  008cba:  4a ab 00 04          tst.l    $4(a3)
  008cbe:  66 de                bne.b    $8c9e  ; -> L8c9e
  008cc0:  be 93                cmp.l    (a3), d7
  008cc2:  63 04                bls.b    $8cc8  ; -> L8cc8
  008cc4:  70 00                moveq    #$0, d0
  008cc6:  60 4e                bra.b    $8d16  ; -> L8d16
L8cc8:
  008cc8:  20 0c                move.l   a4, d0
  008cca:  d0 87                add.l    d7, d0
  008ccc:  50 80                addq.l   #$8, d0
  008cce:  27 40 00 04          move.l   d0, $4(a3)
  008cd2:  28 40                movea.l  d0, a4
  008cd4:  20 0c                move.l   a4, d0
  008cd6:  22 3c 00 0f ff ff    move.l   #$fffff, d1
  008cdc:  c2 80                and.l    d0, d1
  008cde:  20 3c ff f0 00 00    move.l   #$fff00000, d0
  008ce4:  c0 ae 00 08          and.l    $8(a6), d0
  008ce8:  80 81                or.l     d1, d0
  008cea:  2d 40 ff fc          move.l   d0, -$4(a6)
  008cee:  20 6e ff fc          movea.l  -$4(a6), a0
  008cf2:  70 00                moveq    #$0, d0
  008cf4:  21 40 00 04          move.l   d0, $4(a0)
  008cf8:  22 07                move.l   d7, d1
  008cfa:  50 81                addq.l   #$8, d1
  008cfc:  24 13                move.l   (a3), d2
  008cfe:  94 81                sub.l    d1, d2
  008d00:  20 6e ff fc          movea.l  -$4(a6), a0
  008d04:  20 82                move.l   d2, (a0)
  008d06:  20 6e 00 08          movea.l  $8(a6), a0
  008d0a:  21 4c 00 40          move.l   a4, $40(a0)
  008d0e:  26 87                move.l   d7, (a3)
  008d10:  22 0b                move.l   a3, d1
  008d12:  50 81                addq.l   #$8, d1
  008d14:  20 01                move.l   d1, d0
L8d16:
  008d16:  4c ee 18 80 ff f0    movem.l  -$10(a6), d7/a3-a4
  008d1c:  4e 5e                unlk     a6
  008d1e:  4e 75                rts
* s7_sub_74be  -  System 7 $74BE (checked by hand, r=0.53).
s7_sub_74be:
  008d20:  48 e7 03 10          movem.l  d6-d7/a3, -(a7)
  008d24:  2c 2f 00 10          move.l   $10(a7), d6
  008d28:  59 8f                subq.l   #$4, a7
  008d2a:  4e ba 16 f8          jsr      $a424(pc)  ; -> sub_a424
  008d2e:  26 5f                movea.l  (a7)+, a3
  008d30:  59 8f                subq.l   #$4, a7
  008d32:  2e b8 02 a6          move.l   $2a6.w, (a7)
  008d36:  4e ba 16 f6          jsr      $a42e(pc)  ; -> sub_a42e
  008d3a:  4a 86                tst.l    d6
  008d3c:  67 14                beq.b    $8d52  ; -> L8d52
  008d3e:  59 8f                subq.l   #$4, a7
  008d40:  2f 06                move.l   d6, -(a7)
  008d42:  4e ba 17 0c          jsr      $a450(pc)  ; -> sub_a450
  008d46:  2e 1f                move.l   (a7)+, d7
  008d48:  2f 0b                move.l   a3, -(a7)
  008d4a:  4e ba 16 e2          jsr      $a42e(pc)  ; -> sub_a42e
  008d4e:  20 07                move.l   d7, d0
  008d50:  60 08                bra.b    $8d5a  ; -> L8d5a
L8d52:
  008d52:  2f 0b                move.l   a3, -(a7)
  008d54:  4e ba 16 d8          jsr      $a42e(pc)  ; -> sub_a42e
  008d58:  70 00                moveq    #$0, d0
L8d5a:
  008d5a:  4c df 08 c0          movem.l  (a7)+, d6-d7/a3
  008d5e:  4e 75                rts
* s7_sub_74f6  -  System 7 $74F6 (similar code, r=0.95).
s7_sub_74f6:
  008d60:  2f 0b                move.l   a3, -(a7)
  008d62:  26 6f 00 08          movea.l  $8(a7), a3
  008d66:  20 0b                move.l   a3, d0
  008d68:  22 3c f0 00 00 00    move.l   #$f0000000, d1
  008d6e:  c2 80                and.l    d0, d1
  008d70:  0c 81 f0 00 00 00    cmpi.l   #$f0000000, d1
  008d76:  66 04                bne.b    $8d7c  ; -> L8d7c
  008d78:  20 0b                move.l   a3, d0
  008d7a:  60 16                bra.b    $8d92  ; -> L8d92
L8d7c:
  008d7c:  20 0b                move.l   a3, d0
  008d7e:  22 3c 0f ff ff ff    move.l   #$fffffff, d1
  008d84:  c2 80                and.l    d0, d1
  008d86:  70 1c                moveq    #$1c, d0
  008d88:  24 2f 00 0c          move.l   $c(a7), d2
  008d8c:  e1 aa                lsl.l    d0, d2
  008d8e:  d4 81                add.l    d1, d2
  008d90:  20 02                move.l   d2, d0
L8d92:
  008d92:  26 5f                movea.l  (a7)+, a3
  008d94:  4e 75                rts
* s7_sub_7534  -  System 7 $7534 (by call graph, r=0.65).
s7_sub_7534:
  008d96:  4e 56 ff fe          link.w   a6, #$fffe
  008d9a:  2f 0b                move.l   a3, -(a7)
  008d9c:  1d 7c 00 01 ff ff    move.b   #$1, -$1(a6)
  008da2:  2f 2e 00 10          move.l   $10(a6), -(a7)
  008da6:  2f 2e 00 08          move.l   $8(a6), -(a7)
  008daa:  4e ba ff b4          jsr      $8d60(pc)  ; -> s7_sub_74f6
  008dae:  26 40                movea.l  d0, a3
  008db0:  48 6e ff ff          pea.l    -$1(a6)
  008db4:  4e ba 17 68          jsr      $a51e(pc)  ; -> sub_a51e
  008db8:  26 ae 00 0c          move.l   $c(a6), (a3)
  008dbc:  48 6e ff ff          pea.l    -$1(a6)
  008dc0:  4e ba 17 5c          jsr      $a51e(pc)  ; -> sub_a51e
  008dc4:  26 6e ff fa          movea.l  -$6(a6), a3
  008dc8:  4e 5e                unlk     a6
  008dca:  4e 75                rts
* s7_sub_7570  -  System 7 $7570 (similar code, r=0.94).
s7_sub_7570:
  008dcc:  2f 0b                move.l   a3, -(a7)
  008dce:  26 6f 00 08          movea.l  $8(a7), a3
  008dd2:  20 53                movea.l  (a3), a0
  008dd4:  20 3c 00 00 00 80    move.l   #$80, d0
  008dda:  c0 a8 01 28          and.l    $128(a0), d0
  008dde:  67 04                beq.b    $8de4  ; -> L8de4
  008de0:  70 00                moveq    #$0, d0
  008de2:  60 6c                bra.b    $8e50  ; -> L8e50
L8de4:
  008de4:  20 53                movea.l  (a3), a0
  008de6:  70 02                moveq    #$2, d0
  008de8:  c0 a8 00 08          and.l    $8(a0), d0
  008dec:  67 60                beq.b    $8e4e  ; -> L8e4e
  008dee:  20 53                movea.l  (a3), a0
  008df0:  70 00                moveq    #$0, d0
  008df2:  30 10                move.w   (a0), d0
  008df4:  2f 00                move.l   d0, -(a7)
  008df6:  20 53                movea.l  (a3), a0
  008df8:  2f 28 01 68          move.l   $168(a0), -(a7)
  008dfc:  20 53                movea.l  (a3), a0
  008dfe:  20 28 01 30          move.l   $130(a0), d0
  008e02:  72 18                moveq    #$18, d1
  008e04:  d0 81                add.l    d1, d0
  008e06:  2f 00                move.l   d0, -(a7)
  008e08:  4e ba ff 8c          jsr      $8d96(pc)  ; -> s7_sub_7534
  008e0c:  20 53                movea.l  (a3), a0
  008e0e:  70 00                moveq    #$0, d0
  008e10:  30 10                move.w   (a0), d0
  008e12:  2f 00                move.l   d0, -(a7)
  008e14:  70 ff                moveq    #$ff, d0
  008e16:  2f 00                move.l   d0, -(a7)
  008e18:  20 53                movea.l  (a3), a0
  008e1a:  22 28 01 30          move.l   $130(a0), d1
  008e1e:  d2 bc 00 00 03 d4    add.l    #$3d4, d1
  008e24:  2f 01                move.l   d1, -(a7)
  008e26:  4e ba ff 6e          jsr      $8d96(pc)  ; -> s7_sub_7534
  008e2a:  20 53                movea.l  (a3), a0
  008e2c:  70 00                moveq    #$0, d0
  008e2e:  30 10                move.w   (a0), d0
  008e30:  2f 00                move.l   d0, -(a7)
  008e32:  70 ff                moveq    #$ff, d0
  008e34:  2f 00                move.l   d0, -(a7)
  008e36:  2f 3c 04 00 00 50    move.l   #$4000050, -(a7)
  008e3c:  4e ba ff 58          jsr      $8d96(pc)  ; -> s7_sub_7534
  008e40:  20 53                movea.l  (a3), a0
  008e42:  00 a8 00 00 00 04 00 08 ori.l    #$4, $8(a0)
  008e4a:  4f ef 00 24          lea.l    $24(a7), a7
L8e4e:
  008e4e:  70 00                moveq    #$0, d0
L8e50:
  008e50:  26 5f                movea.l  (a7)+, a3
  008e52:  4e 75                rts
* s7_sub_75fe  -  System 7 $75FE (by call graph, r=0.66).
s7_sub_75fe:
  008e54:  4e 56 00 00          link.w   a6, #$0
  008e58:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  008e5c:  20 38 08 88          move.l   $888.w, d0
  008e60:  c0 bc 00 ff ff ff    and.l    #$ffffff, d0
  008e66:  20 40                movea.l  d0, a0
  008e68:  20 50                movea.l  (a0), a0
  008e6a:  26 50                movea.l  (a0), a3
  008e6c:  20 6e 00 08          movea.l  $8(a6), a0
  008e70:  28 50                movea.l  (a0), a4
  008e72:  39 6e 00 0e 01 5c    move.w   $e(a6), $15c(a4)
  008e78:  20 3c 00 00 00 80    move.l   #$80, d0
  008e7e:  c0 ac 01 28          and.l    $128(a4), d0
  008e82:  66 00 00 8a          bne.w    $8f0e  ; -> L8f0e
  008e86:  4a ae 00 10          tst.l    $10(a6)
  008e8a:  6f 00 00 82          ble.w    $8f0e  ; -> L8f0e
  008e8e:  20 3c 00 00 02 00    move.l   #$200, d0
  008e94:  c0 ac 00 08          and.l    $8(a4), d0
  008e98:  66 74                bne.b    $8f0e  ; -> L8f0e
  008e9a:  42 2b 02 58          clr.b    $258(a3)
  008e9e:  00 ac 00 00 02 00 00 08 ori.l    #$200, $8(a4)
  008ea6:  7e 00                moveq    #$0, d7
  008ea8:  49 eb 02 78          lea.l    $278(a3), a4
  008eac:  60 16                bra.b    $8ec4  ; -> L8ec4
L8eae:
  008eae:  4a 94                tst.l    (a4)
  008eb0:  67 0a                beq.b    $8ebc  ; -> L8ebc
  008eb2:  20 07                move.l   d7, d0
  008eb4:  e5 80                asl.l    #$2, d0
  008eb6:  27 ac 00 04 08 14    move.l   $4(a4), $14(a3, d0.l)
L8ebc:
  008ebc:  20 07                move.l   d7, d0
  008ebe:  52 87                addq.l   #$1, d7
  008ec0:  d8 fc 00 10          adda.w   #$10, a4
L8ec4:
  008ec4:  30 2b 02 2c          move.w   $22c(a3), d0
  008ec8:  48 c0                ext.l    d0
  008eca:  b0 87                cmp.l    d7, d0
  008ecc:  6e e0                bgt.b    $8eae  ; -> L8eae
  008ece:  70 24                moveq    #$24, d0
  008ed0:  2f 00                move.l   d0, -(a7)
  008ed2:  4e ba fe 4c          jsr      $8d20(pc)  ; -> s7_sub_74be
  008ed6:  26 40                movea.l  d0, a3
  008ed8:  20 0b                move.l   a3, d0
  008eda:  58 8f                addq.l   #$4, a7
  008edc:  67 30                beq.b    $8f0e  ; -> L8f0e
  008ede:  37 7c 00 08 00 04    move.w   #$8, $4(a3)
  008ee4:  42 6b 00 0e          clr.w    $e(a3)
  008ee8:  70 00                moveq    #$0, d0
  008eea:  27 40 00 10          move.l   d0, $10(a3)
  008eee:  27 40 00 14          move.l   d0, $14(a3)
  008ef2:  41 fa 00 24          lea.l    $8f18(pc), a0
  008ef6:  27 48 00 18          move.l   a0, $18(a3)
  008efa:  27 40 00 1c          move.l   d0, $1c(a3)
  008efe:  27 40 00 20          move.l   d0, $20(a3)
  008f02:  55 8f                subq.l   #$2, a7
  008f04:  2f 0b                move.l   a3, -(a7)
  008f06:  20 5f                movea.l  (a7)+, a0
  008f08:  a0 5e                dc.w     $a05e
  008f0a:  3e 80                move.w   d0, (a7)
  008f0c:  54 8f                addq.l   #$2, a7
L8f0e:
  008f0e:  4c ee 18 80 ff f4    movem.l  -$c(a6), d7/a3-a4
  008f14:  4e 5e                unlk     a6
  008f16:  4e 75                rts
  008f18:  53 47 72 61 70 68 69 63 dc.b     $53, $47, $72, $61, $70, $68, $69, $63  ; SGraphic
  008f20:  73 20 61 63 63 65 6c 65 dc.b     $73, $20, $61, $63, $63, $65, $6C, $65  ; s accele
  008f28:  72 61 74 6f 72 20 69 73 dc.b     $72, $61, $74, $6F, $72, $20, $69, $73  ; rator is
  008f30:  20 68 61 76 69 6e 67 20 dc.b     $20, $68, $61, $76, $69, $6E, $67, $20  ;  having 
  008f38:  64 69 66 66 69 63 75 6c dc.b     $64, $69, $66, $66, $69, $63, $75, $6C  ; difficul
  008f40:  74 79 2e 20 59 6f 75 20 dc.b     $74, $79, $2E, $20, $59, $6F, $75, $20  ; ty. You 
  008f48:  77 69 6c 6c 20 6e 65 65 dc.b     $77, $69, $6C, $6C, $20, $6E, $65, $65  ; will nee
  008f50:  64 20 74 6f 20 72 65 62 dc.b     $64, $20, $74, $6F, $20, $72, $65, $62  ; d to reb
  008f58:  6f 6f 74 20 74 6f 20 72 dc.b     $6F, $6F, $74, $20, $74, $6F, $20, $72  ; oot to r
  008f60:  65 2d 65 6e 61 62 6c 65 dc.b     $65, $2D, $65, $6E, $61, $62, $6C, $65  ; e-enable
  008f68:  20 69 74 2e 00 00    dc.b     $20, $69, $74, $2E, $00, $00  ;  it...
* s7_sub_7742  -  System 7 $7742 (similar code, r=0.90).
s7_sub_7742:
  008f6e:  48 e7 01 10          movem.l  d7/a3, -(a7)
  008f72:  2e 2f 00 0c          move.l   $c(a7), d7
  008f76:  59 8f                subq.l   #$4, a7
  008f78:  aa 29                dc.w     $aa29
  008f7a:  26 5f                movea.l  (a7)+, a3
  008f7c:  60 16                bra.b    $8f94  ; -> L8f94
L8f7e:
  008f7e:  2f 0b                move.l   a3, -(a7)
  008f80:  4e ba 00 1e          jsr      $8fa0(pc)  ; -> s7_sub_81d8
  008f84:  be 80                cmp.l    d0, d7
  008f86:  58 8f                addq.l   #$4, a7
  008f88:  66 04                bne.b    $8f8e  ; -> L8f8e
  008f8a:  20 0b                move.l   a3, d0
  008f8c:  60 0c                bra.b    $8f9a  ; -> L8f9a
L8f8e:
  008f8e:  20 53                movea.l  (a3), a0
  008f90:  26 68 00 1e          movea.l  $1e(a0), a3
L8f94:
  008f94:  20 0b                move.l   a3, d0
  008f96:  66 e6                bne.b    $8f7e  ; -> L8f7e
  008f98:  70 00                moveq    #$0, d0
L8f9a:
  008f9a:  4c df 08 80          movem.l  (a7)+, d7/a3
  008f9e:  4e 75                rts
* s7_sub_81d8  -  System 7 $81D8 (checked by hand, r=0.56).
s7_sub_81d8:
  008fa0:  48 e7 01 18          movem.l  d7/a3-a4, -(a7)
  008fa4:  28 6f 00 10          movea.l  $10(a7), a4
  008fa8:  20 54                movea.l  (a4), a0
  008faa:  20 68 00 16          movea.l  $16(a0), a0
  008fae:  26 50                movea.l  (a0), a3
  008fb0:  2e 13                move.l   (a3), d7
  008fb2:  70 1c                moveq    #$1c, d0
  008fb4:  22 07                move.l   d7, d1
  008fb6:  e0 a9                lsr.l    d0, d1
  008fb8:  70 0f                moveq    #$f, d0
  008fba:  b0 81                cmp.l    d1, d0
  008fbc:  66 0c                bne.b    $8fca  ; -> L8fca
  008fbe:  70 18                moveq    #$18, d0
  008fc0:  22 07                move.l   d7, d1
  008fc2:  e0 a9                lsr.l    d0, d1
  008fc4:  70 0f                moveq    #$f, d0
  008fc6:  c0 81                and.l    d1, d0
  008fc8:  60 08                bra.b    $8fd2  ; -> L8fd2
L8fca:
  008fca:  70 1c                moveq    #$1c, d0
  008fcc:  22 07                move.l   d7, d1
  008fce:  e0 a9                lsr.l    d0, d1
  008fd0:  20 01                move.l   d1, d0
L8fd2:
  008fd2:  4c df 18 80          movem.l  (a7)+, d7/a3-a4
  008fd6:  4e 75                rts
* s7_sub_77a6  -  System 7 $77A6 (checked by hand, r=0.51).
s7_sub_77a6:
  008fd8:  4e 56 ff 42          link.w   a6, #$ff42
  008fdc:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  008fe0:  47 ee ff f4          lea.l    -$c(a6), a3
  008fe4:  78 00                moveq    #$0, d4
  008fe6:  7a 00                moveq    #$0, d5
  008fe8:  70 00                moveq    #$0, d0
  008fea:  2f 00                move.l   d0, -(a7)
  008fec:  2f 00                move.l   d0, -(a7)
  008fee:  72 12                moveq    #$12, d1
  008ff0:  2f 01                move.l   d1, -(a7)
  008ff2:  4e ba d2 30          jsr      $6224(pc)  ; -> EngineDispatch
  008ff6:  70 00                moveq    #$0, d0
  008ff8:  2d 40 ff e4          move.l   d0, -$1c(a6)
  008ffc:  55 8f                subq.l   #$2, a7
  008ffe:  2f 3c 68 64 77 72    move.l   #$68647772, -(a7)
  009004:  48 6e ff e4          pea.l    -$1c(a6)
  009008:  4e ba 15 42          jsr      $a54c(pc)  ; -> sub_a54c
  00900c:  30 1f                move.w   (a7)+, d0
  00900e:  48 c0                ext.l    d0
  009010:  4f ef 00 0c          lea.l    $c(a7), a7
  009014:  66 00 02 8a          bne.w    $92a0  ; -> L92a0
  009018:  70 04                moveq    #$4, d0
  00901a:  c0 ae ff e4          and.l    -$1c(a6), d0
  00901e:  67 00 02 80          beq.w    $92a0  ; -> L92a0
  009022:  70 00                moveq    #$0, d0
  009024:  2d 40 ff f0          move.l   d0, -$10(a6)
  009028:  55 8f                subq.l   #$2, a7
  00902a:  2f 3c 70 67 73 7a    move.l   #$7067737a, -(a7)
  009030:  48 6e ff f0          pea.l    -$10(a6)
  009034:  4e ba 15 16          jsr      $a54c(pc)  ; -> sub_a54c
  009038:  70 00                moveq    #$0, d0
  00903a:  2d 40 ff e0          move.l   d0, -$20(a6)
  00903e:  55 8f                subq.l   #$2, a7
  009040:  2f 3c 72 61 6d 20    move.l   #$72616d20, -(a7)
  009046:  48 6e ff e0          pea.l    -$20(a6)
  00904a:  4e ba 15 00          jsr      $a54c(pc)  ; -> sub_a54c
  00904e:  70 00                moveq    #$0, d0
  009050:  2d 40 ff 94          move.l   d0, -$6c(a6)
  009054:  2d 6e ff e0 ff 98    move.l   -$20(a6), -$68(a6)
  00905a:  58 8f                addq.l   #$4, a7
L905c:
  00905c:  70 08                moveq    #$8, d0
  00905e:  2d 40 ff dc          move.l   d0, -$24(a6)
  009062:  28 6e ff 94          movea.l  -$6c(a6), a4
  009066:  55 8f                subq.l   #$2, a7
  009068:  48 6e ff 94          pea.l    -$6c(a6)
  00906c:  48 6e ff dc          pea.l    -$24(a6)
  009070:  4e ba 13 9a          jsr      $a40c(pc)  ; -> s7_sub_c264
  009074:  30 1f                move.w   (a7)+, d0
  009076:  48 c0                ext.l    d0
  009078:  2d 40 ff e4          move.l   d0, -$1c(a6)
  00907c:  66 68                bne.b    $90e6  ; -> L90e6
  00907e:  4a ae ff dc          tst.l    -$24(a6)
  009082:  67 78                beq.b    $90fc  ; -> L90fc
  009084:  70 00                moveq    #$0, d0
  009086:  2d 40 ff e4          move.l   d0, -$1c(a6)
  00908a:  60 4e                bra.b    $90da  ; -> L90da
L908c:
  00908c:  26 8c                move.l   a4, (a3)
  00908e:  20 2e ff e4          move.l   -$1c(a6), d0
  009092:  e7 80                asl.l    #$3, d0
  009094:  27 76 08 9c 00 04    move.l   -$64(a6, d0.l), $4(a3)
  00909a:  20 2e ff e4          move.l   -$1c(a6), d0
  00909e:  e7 80                asl.l    #$3, d0
  0090a0:  27 76 08 a0 00 08    move.l   -$60(a6, d0.l), $8(a3)
  0090a6:  20 2e ff dc          move.l   -$24(a6), d0
  0090aa:  53 80                subq.l   #$1, d0
  0090ac:  b0 ae ff e4          cmp.l    -$1c(a6), d0
  0090b0:  66 04                bne.b    $90b6  ; -> L90b6
  0090b2:  db ab 00 08          add.l    d5, $8(a3)
L90b6:
  0090b6:  70 03                moveq    #$3, d0
  0090b8:  2f 00                move.l   d0, -(a7)
  0090ba:  2f 0b                move.l   a3, -(a7)
  0090bc:  72 13                moveq    #$13, d1
  0090be:  2f 01                move.l   d1, -(a7)
  0090c0:  4e ba d1 62          jsr      $6224(pc)  ; -> EngineDispatch
  0090c4:  20 2e ff e4          move.l   -$1c(a6), d0
  0090c8:  e7 80                asl.l    #$3, d0
  0090ca:  d9 f6 08 a0          adda.l   -$60(a6, d0.l), a4
  0090ce:  4f ef 00 0c          lea.l    $c(a7), a7
  0090d2:  20 2e ff e4          move.l   -$1c(a6), d0
  0090d6:  52 ae ff e4          addq.l   #$1, -$1c(a6)
L90da:
  0090da:  20 2e ff e4          move.l   -$1c(a6), d0
  0090de:  b0 ae ff dc          cmp.l    -$24(a6), d0
  0090e2:  65 a8                bcs.b    $908c  ; -> L908c
  0090e4:  60 0e                bra.b    $90f4  ; -> L90f4
L90e6:
  0090e6:  06 85 00 00 01 00    addi.l   #$100, d5
  0090ec:  04 ae 00 00 01 00 ff 98 subi.l   #$100, -$68(a6)
L90f4:
  0090f4:  4a ae ff 98          tst.l    -$68(a6)
  0090f8:  66 00 ff 62          bne.w    $905c  ; -> L905c
L90fc:
  0090fc:  70 0b                moveq    #$b, d0
  0090fe:  2f 00                move.l   d0, -(a7)
  009100:  4e ba fe 6c          jsr      $8f6e(pc)  ; -> s7_sub_7742
  009104:  2d 40 ff e8          move.l   d0, -$18(a6)
  009108:  58 8f                addq.l   #$4, a7
  00910a:  67 00 00 b4          beq.w    $91c0  ; -> L91c0
  00910e:  20 6e ff e8          movea.l  -$18(a6), a0
  009112:  20 50                movea.l  (a0), a0
  009114:  20 68 00 16          movea.l  $16(a0), a0
  009118:  2d 50 ff ec          move.l   (a0), -$14(a6)
  00911c:  20 6e ff ec          movea.l  -$14(a6), a0
  009120:  30 28 00 0a          move.w   $a(a0), d0
  009124:  48 c0                ext.l    d0
  009126:  20 6e ff ec          movea.l  -$14(a6), a0
  00912a:  32 28 00 06          move.w   $6(a0), d1
  00912e:  48 c1                ext.l    d1
  009130:  90 81                sub.l    d1, d0
  009132:  2d 40 ff 50          move.l   d0, -$b0(a6)
  009136:  20 6e ff ec          movea.l  -$14(a6), a0
  00913a:  30 28 00 04          move.w   $4(a0), d0
  00913e:  48 c0                ext.l    d0
  009140:  22 3c 00 00 3f ff    move.l   #$3fff, d1
  009146:  c2 80                and.l    d0, d1
  009148:  20 6e ff ec          movea.l  -$14(a6), a0
  00914c:  30 28 00 0a          move.w   $a(a0), d0
  009150:  48 c0                ext.l    d0
  009152:  20 6e ff ec          movea.l  -$14(a6), a0
  009156:  34 28 00 06          move.w   $6(a0), d2
  00915a:  48 c2                ext.l    d2
  00915c:  90 82                sub.l    d2, d0
  00915e:  4c 01 08 00          muls.l   d1, d0
  009162:  28 00                move.l   d0, d4
  009164:  0c ae 00 00 01 f4 ff 50 cmpi.l   #$1f4, -$b0(a6)
  00916c:  6f 04                ble.b    $9172  ; -> L9172
  00916e:  e5 84                asl.l    #$2, d4
  009170:  60 02                bra.b    $9174  ; -> L9174
L9172:
  009172:  e7 84                asl.l    #$3, d4
L9174:
  009174:  20 6e ff ec          movea.l  -$14(a6), a0
  009178:  30 28 00 20          move.w   $20(a0), d0
  00917c:  48 c0                ext.l    d0
  00917e:  22 04                move.l   d4, d1
  009180:  4c 40 18 01          divs.l   d0, d1
  009184:  28 01                move.l   d1, d4
  009186:  20 04                move.l   d4, d0
  009188:  e6 80                asr.l    #$3, d0
  00918a:  d8 80                add.l    d0, d4
  00918c:  20 2e ff f0          move.l   -$10(a6), d0
  009190:  53 80                subq.l   #$1, d0
  009192:  d8 80                add.l    d0, d4
  009194:  20 2e ff f0          move.l   -$10(a6), d0
  009198:  53 80                subq.l   #$1, d0
  00919a:  46 80                not.l    d0
  00919c:  c8 80                and.l    d0, d4
  00919e:  26 bc fb b0 80 00    move.l   #$fbb08000, (a3)
  0091a4:  70 00                moveq    #$0, d0
  0091a6:  27 40 00 04          move.l   d0, $4(a3)
  0091aa:  27 44 00 08          move.l   d4, $8(a3)
  0091ae:  72 03                moveq    #$3, d1
  0091b0:  2f 01                move.l   d1, -(a7)
  0091b2:  2f 0b                move.l   a3, -(a7)
  0091b4:  70 13                moveq    #$13, d0
  0091b6:  2f 00                move.l   d0, -(a7)
  0091b8:  4e ba d0 6a          jsr      $6224(pc)  ; -> EngineDispatch
  0091bc:  4f ef 00 0c          lea.l    $c(a7), a7
L91c0:
  0091c0:  55 8f                subq.l   #$2, a7
  0091c2:  2f 3c 6d 61 63 68    move.l   #$6d616368, -(a7)
  0091c8:  48 6e ff e4          pea.l    -$1c(a6)
  0091cc:  4e ba 13 7e          jsr      $a54c(pc)  ; -> sub_a54c
  0091d0:  70 0b                moveq    #$b, d0
  0091d2:  b0 ae ff e4          cmp.l    -$1c(a6), d0
  0091d6:  54 8f                addq.l   #$2, a7
  0091d8:  67 00 00 c6          beq.w    $92a0  ; -> L92a0
  0091dc:  70 0e                moveq    #$e, d0
  0091de:  2f 00                move.l   d0, -(a7)
  0091e0:  4e ba fd 8c          jsr      $8f6e(pc)  ; -> s7_sub_7742
  0091e4:  2d 40 ff e8          move.l   d0, -$18(a6)
  0091e8:  58 8f                addq.l   #$4, a7
  0091ea:  67 00 00 b4          beq.w    $92a0  ; -> L92a0
  0091ee:  20 6e ff e8          movea.l  -$18(a6), a0
  0091f2:  20 50                movea.l  (a0), a0
  0091f4:  20 68 00 16          movea.l  $16(a0), a0
  0091f8:  2d 50 ff ec          move.l   (a0), -$14(a6)
  0091fc:  20 6e ff ec          movea.l  -$14(a6), a0
  009200:  30 28 00 0a          move.w   $a(a0), d0
  009204:  48 c0                ext.l    d0
  009206:  20 6e ff ec          movea.l  -$14(a6), a0
  00920a:  32 28 00 06          move.w   $6(a0), d1
  00920e:  48 c1                ext.l    d1
  009210:  90 81                sub.l    d1, d0
  009212:  2d 40 ff 4c          move.l   d0, -$b4(a6)
  009216:  20 6e ff ec          movea.l  -$14(a6), a0
  00921a:  30 28 00 04          move.w   $4(a0), d0
  00921e:  48 c0                ext.l    d0
  009220:  22 3c 00 00 3f ff    move.l   #$3fff, d1
  009226:  c2 80                and.l    d0, d1
  009228:  20 6e ff ec          movea.l  -$14(a6), a0
  00922c:  30 28 00 0a          move.w   $a(a0), d0
  009230:  48 c0                ext.l    d0
  009232:  20 6e ff ec          movea.l  -$14(a6), a0
  009236:  34 28 00 06          move.w   $6(a0), d2
  00923a:  48 c2                ext.l    d2
  00923c:  90 82                sub.l    d2, d0
  00923e:  4c 01 08 00          muls.l   d1, d0
  009242:  28 00                move.l   d0, d4
  009244:  0c ae 00 00 01 f4 ff 4c cmpi.l   #$1f4, -$b4(a6)
  00924c:  6f 04                ble.b    $9252  ; -> L9252
  00924e:  e5 84                asl.l    #$2, d4
  009250:  60 02                bra.b    $9254  ; -> L9254
L9252:
  009252:  e7 84                asl.l    #$3, d4
L9254:
  009254:  20 6e ff ec          movea.l  -$14(a6), a0
  009258:  30 28 00 20          move.w   $20(a0), d0
  00925c:  48 c0                ext.l    d0
  00925e:  22 04                move.l   d4, d1
  009260:  4c 40 18 01          divs.l   d0, d1
  009264:  28 01                move.l   d1, d4
  009266:  20 04                move.l   d4, d0
  009268:  e6 80                asr.l    #$3, d0
  00926a:  d8 80                add.l    d0, d4
  00926c:  20 2e ff f0          move.l   -$10(a6), d0
  009270:  53 80                subq.l   #$1, d0
  009272:  d8 80                add.l    d0, d4
  009274:  20 2e ff f0          move.l   -$10(a6), d0
  009278:  53 80                subq.l   #$1, d0
  00927a:  46 80                not.l    d0
  00927c:  c8 80                and.l    d0, d4
  00927e:  26 bc fe e0 80 00    move.l   #$fee08000, (a3)
  009284:  70 00                moveq    #$0, d0
  009286:  27 40 00 04          move.l   d0, $4(a3)
  00928a:  27 44 00 08          move.l   d4, $8(a3)
  00928e:  72 03                moveq    #$3, d1
  009290:  2f 01                move.l   d1, -(a7)
  009292:  2f 0b                move.l   a3, -(a7)
  009294:  70 13                moveq    #$13, d0
  009296:  2f 00                move.l   d0, -(a7)
  009298:  4e ba cf 8a          jsr      $6224(pc)  ; -> EngineDispatch
  00929c:  4f ef 00 0c          lea.l    $c(a7), a7
L92a0:
  0092a0:  70 00                moveq    #$0, d0
  0092a2:  2d 40 ff 8c          move.l   d0, -$74(a6)
  0092a6:  22 38 08 88          move.l   $888.w, d1
  0092aa:  c2 bc 00 ff ff ff    and.l    #$ffffff, d1
  0092b0:  20 41                movea.l  d1, a0
  0092b2:  20 50                movea.l  (a0), a0
  0092b4:  20 50                movea.l  (a0), a0
  0092b6:  2d 68 02 14 ff 90    move.l   $214(a0), -$70(a6)
  0092bc:  7e 09                moveq    #$9, d7
L92be:
  0092be:  42 06                clr.b    d6
  0092c0:  2f 07                move.l   d7, -(a7)
  0092c2:  4e ba fc aa          jsr      $8f6e(pc)  ; -> s7_sub_7742
  0092c6:  2d 40 ff e8          move.l   d0, -$18(a6)
  0092ca:  58 8f                addq.l   #$4, a7
  0092cc:  66 06                bne.b    $92d4  ; -> L92d4
  0092ce:  7c 01                moveq    #$1, d6
  0092d0:  60 00 01 d8          bra.w    $94aa  ; -> L94aa
L92d4:
  0092d4:  1d 47 ff 85          move.b   d7, -$7b(a6)
  0092d8:  42 2e ff 86          clr.b    -$7a(a6)
  0092dc:  3d 7c 00 01 ff 7c    move.w   #$1, -$84(a6)
  0092e2:  42 6e ff 7e          clr.w    -$82(a6)
  0092e6:  1d 7c 00 03 ff 84    move.b   #$3, -$7c(a6)
  0092ec:  55 8f                subq.l   #$2, a7
  0092ee:  48 6e ff 54          pea.l    -$ac(a6)
  0092f2:  4e ba 12 9e          jsr      $a592(pc)  ; -> sub_a592
  0092f6:  30 1f                move.w   (a7)+, d0
  0092f8:  48 c0                ext.l    d0
  0092fa:  66 00 01 ae          bne.w    $94aa  ; -> L94aa
  0092fe:  10 2e ff 85          move.b   -$7b(a6), d0
  009302:  49 c0                extb.l   d0
  009304:  be 80                cmp.l    d0, d7
  009306:  67 06                beq.b    $930e  ; -> L930e
  009308:  7c 01                moveq    #$1, d6
  00930a:  60 00 01 9e          bra.w    $94aa  ; -> L94aa
L930e:
  00930e:  1d 7c 00 20 ff 86    move.b   #$20, -$7a(a6)
  009314:  55 8f                subq.l   #$2, a7
  009316:  48 6e ff 54          pea.l    -$ac(a6)
  00931a:  4e ba 12 46          jsr      $a562(pc)  ; -> sub_a562
  00931e:  30 1f                move.w   (a7)+, d0
  009320:  48 c0                ext.l    d0
  009322:  66 00 01 86          bne.w    $94aa  ; -> L94aa
  009326:  30 2e ff 56          move.w   -$aa(a6), d0
  00932a:  48 c0                ext.l    d0
  00932c:  72 27                moveq    #$27, d1
  00932e:  b2 80                cmp.l    d0, d1
  009330:  66 00 00 88          bne.w    $93ba  ; -> L93ba
  009334:  1d 7c 00 24 ff 86    move.b   #$24, -$7a(a6)
  00933a:  55 8f                subq.l   #$2, a7
  00933c:  48 6e ff 54          pea.l    -$ac(a6)
  009340:  4e ba 12 44          jsr      $a586(pc)  ; -> sub_a586
  009344:  30 1f                move.w   (a7)+, d0
  009346:  48 c0                ext.l    d0
  009348:  66 00 01 60          bne.w    $94aa  ; -> L94aa
  00934c:  1d 47 ff 85          move.b   d7, -$7b(a6)
  009350:  1d 7c 00 03 ff 86    move.b   #$3, -$7a(a6)
  009356:  55 8f                subq.l   #$2, a7
  009358:  48 6e ff 54          pea.l    -$ac(a6)
  00935c:  4e ba 12 1c          jsr      $a57a(pc)  ; -> sub_a57a
  009360:  30 1f                move.w   (a7)+, d0
  009362:  48 c0                ext.l    d0
  009364:  66 00 01 44          bne.w    $94aa  ; -> L94aa
  009368:  48 7a 01 70          pea.l    $94da(pc)
  00936c:  2f 2e ff 54          move.l   -$ac(a6), -(a7)
  009370:  4e ba 01 72          jsr      $94e4(pc)  ; -> sub_94e4
  009374:  4a 80                tst.l    d0
  009376:  50 8f                addq.l   #$8, a7
  009378:  66 40                bne.b    $93ba  ; -> L93ba
  00937a:  1d 7c 00 01 ff 43    move.b   #$1, -$bd(a6)
  009380:  70 18                moveq    #$18, d0
  009382:  22 07                move.l   d7, d1
  009384:  e1 a9                lsl.l    d0, d1
  009386:  82 bc f0 20 02 08    or.l     #$f0200208, d1
  00938c:  2d 41 ff 48          move.l   d1, -$b8(a6)
  009390:  48 6e ff 43          pea.l    -$bd(a6)
  009394:  4e ba 11 88          jsr      $a51e(pc)  ; -> sub_a51e
  009398:  20 6e ff 48          movea.l  -$b8(a6), a0
  00939c:  2d 50 ff 44          move.l   (a0), -$bc(a6)
  0093a0:  48 6e ff 43          pea.l    -$bd(a6)
  0093a4:  4e ba 11 78          jsr      $a51e(pc)  ; -> sub_a51e
  0093a8:  70 00                moveq    #$0, d0
  0093aa:  72 01                moveq    #$1, d1
  0093ac:  c2 ae ff 44          and.l    -$bc(a6), d1
  0093b0:  57 c0                seq.b    d0
  0093b2:  44 00                neg.b    d0
  0093b4:  1c 00                move.b   d0, d6
  0093b6:  60 00 00 f2          bra.w    $94aa  ; -> L94aa
L93ba:
  0093ba:  1d 47 ff 85          move.b   d7, -$7b(a6)
  0093be:  42 2e ff 86          clr.b    -$7a(a6)
  0093c2:  3d 7c 00 01 ff 7c    move.w   #$1, -$84(a6)
  0093c8:  42 6e ff 7e          clr.w    -$82(a6)
  0093cc:  1d 7c 00 03 ff 84    move.b   #$3, -$7c(a6)
  0093d2:  55 8f                subq.l   #$2, a7
  0093d4:  48 6e ff 54          pea.l    -$ac(a6)
  0093d8:  4e ba 11 b8          jsr      $a592(pc)  ; -> sub_a592
  0093dc:  30 1f                move.w   (a7)+, d0
  0093de:  48 c0                ext.l    d0
  0093e0:  66 00 00 c8          bne.w    $94aa  ; -> L94aa
  0093e4:  10 2e ff 85          move.b   -$7b(a6), d0
  0093e8:  49 c0                extb.l   d0
  0093ea:  be 80                cmp.l    d0, d7
  0093ec:  67 06                beq.b    $93f4  ; -> L93f4
  0093ee:  7c 01                moveq    #$1, d6
  0093f0:  60 00 00 b8          bra.w    $94aa  ; -> L94aa
L93f4:
  0093f4:  1d 7c 00 14 ff 86    move.b   #$14, -$7a(a6)
  0093fa:  55 8f                subq.l   #$2, a7
  0093fc:  48 6e ff 54          pea.l    -$ac(a6)
  009400:  4e ba 11 6c          jsr      $a56e(pc)  ; -> sub_a56e
  009404:  30 1f                move.w   (a7)+, d0
  009406:  48 c0                ext.l    d0
  009408:  67 00 00 8c          beq.w    $9496  ; -> L9496
  00940c:  3d 7c 00 03 ff 7c    move.w   #$3, -$84(a6)
  009412:  3d 7c 00 01 ff 7e    move.w   #$1, -$82(a6)
  009418:  3d 7c 00 01 ff 80    move.w   #$1, -$80(a6)
  00941e:  1d 7c 00 01 ff 84    move.b   #$1, -$7c(a6)
  009424:  42 2e ff 86          clr.b    -$7a(a6)
  009428:  1d 47 ff 85          move.b   d7, -$7b(a6)
  00942c:  55 8f                subq.l   #$2, a7
  00942e:  48 6e ff 54          pea.l    -$ac(a6)
  009432:  4e ba 11 5e          jsr      $a592(pc)  ; -> sub_a592
  009436:  30 1f                move.w   (a7)+, d0
  009438:  48 c0                ext.l    d0
  00943a:  66 6e                bne.b    $94aa  ; -> L94aa
  00943c:  10 2e ff 85          move.b   -$7b(a6), d0
  009440:  49 c0                extb.l   d0
  009442:  be 80                cmp.l    d0, d7
  009444:  67 04                beq.b    $944a  ; -> L944a
  009446:  7c 01                moveq    #$1, d6
  009448:  60 60                bra.b    $94aa  ; -> L94aa
L944a:
  00944a:  20 6e ff e8          movea.l  -$18(a6), a0
  00944e:  20 50                movea.l  (a0), a0
  009450:  1d 68 00 2d ff 86    move.b   $2d(a0), -$7a(a6)
  009456:  55 8f                subq.l   #$2, a7
  009458:  48 6e ff 54          pea.l    -$ac(a6)
  00945c:  4e ba 11 28          jsr      $a586(pc)  ; -> sub_a586
  009460:  30 1f                move.w   (a7)+, d0
  009462:  48 c0                ext.l    d0
  009464:  66 44                bne.b    $94aa  ; -> L94aa
  009466:  1d 7c 00 05 ff 86    move.b   #$5, -$7a(a6)
  00946c:  55 8f                subq.l   #$2, a7
  00946e:  48 6e ff 54          pea.l    -$ac(a6)
  009472:  4e ba 10 fa          jsr      $a56e(pc)  ; -> sub_a56e
  009476:  30 1f                move.w   (a7)+, d0
  009478:  48 c0                ext.l    d0
  00947a:  67 04                beq.b    $9480  ; -> L9480
  00947c:  7c 01                moveq    #$1, d6
  00947e:  60 2a                bra.b    $94aa  ; -> L94aa
L9480:
  009480:  20 3c 00 00 80 0e    move.l   #$800e, d0
  009486:  c0 ae ff 54          and.l    -$ac(a6), d0
  00948a:  0c 80 00 00 80 0e    cmpi.l   #$800e, d0
  009490:  57 c6                seq.b    d6
  009492:  44 06                neg.b    d6
  009494:  60 14                bra.b    $94aa  ; -> L94aa
L9496:
  009496:  20 3c 00 00 80 0e    move.l   #$800e, d0
  00949c:  c0 ae ff 54          and.l    -$ac(a6), d0
  0094a0:  0c 80 00 00 80 0e    cmpi.l   #$800e, d0
  0094a6:  57 c6                seq.b    d6
  0094a8:  44 06                neg.b    d6
L94aa:
  0094aa:  70 00                moveq    #$0, d0
  0094ac:  10 06                move.b   d6, d0
  0094ae:  66 14                bne.b    $94c4  ; -> L94c4
  0094b0:  26 87                move.l   d7, (a3)
  0094b2:  70 01                moveq    #$1, d0
  0094b4:  2f 00                move.l   d0, -(a7)
  0094b6:  2f 0b                move.l   a3, -(a7)
  0094b8:  72 14                moveq    #$14, d1
  0094ba:  2f 01                move.l   d1, -(a7)
  0094bc:  4e ba cd 66          jsr      $6224(pc)  ; -> EngineDispatch
  0094c0:  4f ef 00 0c          lea.l    $c(a7), a7
L94c4:
  0094c4:  20 07                move.l   d7, d0
  0094c6:  52 87                addq.l   #$1, d7
  0094c8:  70 0f                moveq    #$f, d0
  0094ca:  b0 87                cmp.l    d7, d0
  0094cc:  6e 00 fd f0          bgt.w    $92be  ; -> L92be
  0094d0:  4c ee 18 f0 ff 2a    movem.l  -$d6(a6), d4-d7/a3-a4
  0094d6:  4e 5e                unlk     a6
  0094d8:  4e 75                rts
  0094da:  4d 44 43 20 31 2e 30 2e dc.b     $4D, $44, $43, $20, $31, $2E, $30, $2E  ; MDC 1.0.
  0094e2:  31 00                dc.b     $31, $00  ; 1.
sub_94e4:
  0094e4:  48 e7 00 18          movem.l  a3-a4, -(a7)
  0094e8:  28 6f 00 10          movea.l  $10(a7), a4
  0094ec:  26 6f 00 0c          movea.l  $c(a7), a3
L94f0:
  0094f0:  4a 13                tst.b    (a3)
  0094f2:  67 0c                beq.b    $9500  ; -> L9500
  0094f4:  10 1b                move.b   (a3)+, d0
  0094f6:  49 c0                extb.l   d0
  0094f8:  12 1c                move.b   (a4)+, d1
  0094fa:  49 c1                extb.l   d1
  0094fc:  b2 80                cmp.l    d0, d1
  0094fe:  67 f0                beq.b    $94f0  ; -> L94f0
L9500:
  009500:  10 23                move.b   -(a3), d0
  009502:  49 c0                extb.l   d0
  009504:  12 24                move.b   -(a4), d1
  009506:  49 c1                extb.l   d1
  009508:  90 81                sub.l    d1, d0
  00950a:  4c df 18 00          movem.l  (a7)+, a3-a4
  00950e:  4e 75                rts
sub_9510:
  009510:  4e 56 00 00          link.w   a6, #$0
  009514:  48 e7 03 18          movem.l  d6-d7/a3-a4, -(a7)
  009518:  2c 2e 00 08          move.l   $8(a6), d6
  00951c:  28 6e 00 14          movea.l  $14(a6), a4
  009520:  26 6e 00 0c          movea.l  $c(a6), a3
  009524:  0c 86 72 70 7a 61    cmpi.l   #$72707a61, d6
  00952a:  67 10                beq.b    $953c  ; -> L953c
  00952c:  0c 86 72 6c 65 20    cmpi.l   #$726c6520, d6
  009532:  67 08                beq.b    $953c  ; -> L953c
  009534:  30 3c dd 15          move.w   #$dd15, d0
  009538:  60 00 02 0e          bra.w    $9748  ; -> L9748
L953c:
  00953c:  20 2e 00 10          move.l   $10(a6), d0
  009540:  04 80 00 00 00 10    subi.l   #$10, d0
  009546:  6b 00 01 fa          bmi.w    $9742  ; -> L9742
  00954a:  0c 80 00 00 00 09    cmpi.l   #$9, d0
  009550:  6e 00 01 f0          bgt.w    $9742  ; -> L9742
  009554:  d0 80                add.l    d0, d0
  009556:  30 3b 08 06          move.w   $955e(pc, d0.l), d0
  00955a:  4e fb 00 00          jmp      $955c(pc,d0.w)
  00955e:  00 16                dc.w     $0016    ; [0] -> L9572
  009560:  00 5e                dc.w     $005E    ; [1] -> L95ba
  009562:  00 aa                dc.w     $00AA    ; [2] -> L9606
  009564:  00 f0                dc.w     $00F0    ; [3] -> L964c
  009566:  01 40                dc.w     $0140    ; [4] -> L969c
  009568:  01 8a                dc.w     $018A    ; [5] -> L96e6
  00956a:  01 8e                dc.w     $018E    ; [6] -> L96ea
  00956c:  01 a0                dc.w     $01A0    ; [7] -> L96fc
  00956e:  01 bc                dc.w     $01BC    ; [8] -> L9718
  009570:  01 d8                dc.w     $01D8    ; [9] -> L9734
L9572:
  009572:  2f 06                move.l   d6, -(a7)
  009574:  2f 0c                move.l   a4, -(a7)
  009576:  70 00                moveq    #$0, d0
  009578:  2f 00                move.l   d0, -(a7)
  00957a:  2f 00                move.l   d0, -(a7)
  00957c:  2f 2b 00 08          move.l   $8(a3), -(a7)
  009580:  2f 00                move.l   d0, -(a7)
  009582:  32 2b 00 0c          move.w   $c(a3), d1
  009586:  48 c1                ext.l    d1
  009588:  2f 01                move.l   d1, -(a7)
  00958a:  2f 2b 00 12          move.l   $12(a3), -(a7)
  00958e:  32 2b 00 16          move.w   $16(a3), d1
  009592:  48 c1                ext.l    d1
  009594:  2f 01                move.l   d1, -(a7)
  009596:  2f 2b 00 0e          move.l   $e(a3), -(a7)
  00959a:  2f 2b 00 18          move.l   $18(a3), -(a7)
  00959e:  2f 2b 00 20          move.l   $20(a3), -(a7)
  0095a2:  2f 2b 00 1c          move.l   $1c(a3), -(a7)
  0095a6:  2f 2b 00 24          move.l   $24(a3), -(a7)
  0095aa:  4e ba 06 0e          jsr      $9bba(pc)  ; -> sub_9bba
  0095ae:  48 c0                ext.l    d0
  0095b0:  2e 00                move.l   d0, d7
  0095b2:  4f ef 00 38          lea.l    $38(a7), a7
  0095b6:  60 00 01 8e          bra.w    $9746  ; -> L9746
L95ba:
  0095ba:  2f 06                move.l   d6, -(a7)
  0095bc:  2f 0c                move.l   a4, -(a7)
  0095be:  2f 2b 00 08          move.l   $8(a3), -(a7)
  0095c2:  2f 2b 00 0c          move.l   $c(a3), -(a7)
  0095c6:  2f 2b 00 10          move.l   $10(a3), -(a7)
  0095ca:  70 01                moveq    #$1, d0
  0095cc:  2f 00                move.l   d0, -(a7)
  0095ce:  32 2b 00 14          move.w   $14(a3), d1
  0095d2:  48 c1                ext.l    d1
  0095d4:  2f 01                move.l   d1, -(a7)
  0095d6:  2f 2b 00 1a          move.l   $1a(a3), -(a7)
  0095da:  32 2b 00 1e          move.w   $1e(a3), d1
  0095de:  48 c1                ext.l    d1
  0095e0:  2f 01                move.l   d1, -(a7)
  0095e2:  2f 2b 00 16          move.l   $16(a3), -(a7)
  0095e6:  2f 2b 00 20          move.l   $20(a3), -(a7)
  0095ea:  2f 2b 00 28          move.l   $28(a3), -(a7)
  0095ee:  2f 2b 00 24          move.l   $24(a3), -(a7)
  0095f2:  2f 2b 00 2c          move.l   $2c(a3), -(a7)
  0095f6:  4e ba 05 c2          jsr      $9bba(pc)  ; -> sub_9bba
  0095fa:  48 c0                ext.l    d0
  0095fc:  2e 00                move.l   d0, d7
  0095fe:  4f ef 00 38          lea.l    $38(a7), a7
  009602:  60 00 01 42          bra.w    $9746  ; -> L9746
L9606:
  009606:  2f 06                move.l   d6, -(a7)
  009608:  2f 0c                move.l   a4, -(a7)
  00960a:  70 00                moveq    #$0, d0
  00960c:  2f 00                move.l   d0, -(a7)
  00960e:  2f 00                move.l   d0, -(a7)
  009610:  2f 00                move.l   d0, -(a7)
  009612:  2f 2b 00 08          move.l   $8(a3), -(a7)
  009616:  2f 00                move.l   d0, -(a7)
  009618:  32 2b 00 0c          move.w   $c(a3), d1
  00961c:  48 c1                ext.l    d1
  00961e:  2f 01                move.l   d1, -(a7)
  009620:  2f 00                move.l   d0, -(a7)
  009622:  2f 2b 00 0e          move.l   $e(a3), -(a7)
  009626:  2f 2b 00 12          move.l   $12(a3), -(a7)
  00962a:  2f 2b 00 1c          move.l   $1c(a3), -(a7)
  00962e:  2f 2b 00 24          move.l   $24(a3), -(a7)
  009632:  2f 00                move.l   d0, -(a7)
  009634:  2f 2b 00 20          move.l   $20(a3), -(a7)
  009638:  2f 2b 00 28          move.l   $28(a3), -(a7)
  00963c:  4e ba 01 14          jsr      $9752(pc)  ; -> sub_9752
  009640:  48 c0                ext.l    d0
  009642:  2e 00                move.l   d0, d7
  009644:  4f ef 00 40          lea.l    $40(a7), a7
  009648:  60 00 00 fc          bra.w    $9746  ; -> L9746
L964c:
  00964c:  2f 06                move.l   d6, -(a7)
  00964e:  2f 0c                move.l   a4, -(a7)
  009650:  2f 2b 00 08          move.l   $8(a3), -(a7)
  009654:  2f 2b 00 0c          move.l   $c(a3), -(a7)
  009658:  2f 2b 00 10          move.l   $10(a3), -(a7)
  00965c:  2f 2b 00 14          move.l   $14(a3), -(a7)
  009660:  70 01                moveq    #$1, d0
  009662:  2f 00                move.l   d0, -(a7)
  009664:  32 2b 00 18          move.w   $18(a3), d1
  009668:  48 c1                ext.l    d1
  00966a:  2f 01                move.l   d1, -(a7)
  00966c:  2f 2b 00 1a          move.l   $1a(a3), -(a7)
  009670:  2f 2b 00 1e          move.l   $1e(a3), -(a7)
  009674:  72 00                moveq    #$0, d1
  009676:  2f 01                move.l   d1, -(a7)
  009678:  2f 2b 00 2c          move.l   $2c(a3), -(a7)
  00967c:  2f 2b 00 34          move.l   $34(a3), -(a7)
  009680:  2f 2b 00 22          move.l   $22(a3), -(a7)
  009684:  2f 2b 00 30          move.l   $30(a3), -(a7)
  009688:  2f 2b 00 38          move.l   $38(a3), -(a7)
  00968c:  4e ba 00 c4          jsr      $9752(pc)  ; -> sub_9752
  009690:  48 c0                ext.l    d0
  009692:  2e 00                move.l   d0, d7
  009694:  4f ef 00 40          lea.l    $40(a7), a7
  009698:  60 00 00 ac          bra.w    $9746  ; -> L9746
L969c:
  00969c:  2f 06                move.l   d6, -(a7)
  00969e:  2f 0c                move.l   a4, -(a7)
  0096a0:  2f 2b 00 08          move.l   $8(a3), -(a7)
  0096a4:  70 00                moveq    #$0, d0
  0096a6:  2f 00                move.l   d0, -(a7)
  0096a8:  2f 00                move.l   d0, -(a7)
  0096aa:  2f 2b 00 0c          move.l   $c(a3), -(a7)
  0096ae:  2f 00                move.l   d0, -(a7)
  0096b0:  32 2b 00 10          move.w   $10(a3), d1
  0096b4:  48 c1                ext.l    d1
  0096b6:  2f 01                move.l   d1, -(a7)
  0096b8:  2f 2b 00 12          move.l   $12(a3), -(a7)
  0096bc:  2f 2b 00 16          move.l   $16(a3), -(a7)
  0096c0:  2f 2b 00 1a          move.l   $1a(a3), -(a7)
  0096c4:  2f 2b 00 28          move.l   $28(a3), -(a7)
  0096c8:  2f 2b 00 30          move.l   $30(a3), -(a7)
  0096cc:  2f 2b 00 1e          move.l   $1e(a3), -(a7)
  0096d0:  2f 2b 00 2c          move.l   $2c(a3), -(a7)
  0096d4:  2f 2b 00 34          move.l   $34(a3), -(a7)
  0096d8:  4e ba 00 78          jsr      $9752(pc)  ; -> sub_9752
  0096dc:  48 c0                ext.l    d0
  0096de:  2e 00                move.l   d0, d7
  0096e0:  4f ef 00 40          lea.l    $40(a7), a7
  0096e4:  60 60                bra.b    $9746  ; -> L9746
L96e6:
  0096e6:  7e 00                moveq    #$0, d7
  0096e8:  60 5c                bra.b    $9746  ; -> L9746
L96ea:
  0096ea:  2f 0c                move.l   a4, -(a7)
  0096ec:  2f 2b 00 08          move.l   $8(a3), -(a7)
  0096f0:  4e ba 09 c2          jsr      $a0b4(pc)  ; -> sub_a0b4
  0096f4:  48 c0                ext.l    d0
  0096f6:  2e 00                move.l   d0, d7
  0096f8:  50 8f                addq.l   #$8, a7
  0096fa:  60 4a                bra.b    $9746  ; -> L9746
L96fc:
  0096fc:  2f 0c                move.l   a4, -(a7)
  0096fe:  2f 2b 00 08          move.l   $8(a3), -(a7)
  009702:  2f 2b 00 0c          move.l   $c(a3), -(a7)
  009706:  2f 2b 00 10          move.l   $10(a3), -(a7)
  00970a:  4e ba 0a 18          jsr      $a124(pc)  ; -> sub_a124
  00970e:  48 c0                ext.l    d0
  009710:  2e 00                move.l   d0, d7
  009712:  4f ef 00 10          lea.l    $10(a7), a7
  009716:  60 2e                bra.b    $9746  ; -> L9746
L9718:
  009718:  2f 0c                move.l   a4, -(a7)
  00971a:  2f 2b 00 08          move.l   $8(a3), -(a7)
  00971e:  2f 2b 00 0c          move.l   $c(a3), -(a7)
  009722:  2f 2b 00 10          move.l   $10(a3), -(a7)
  009726:  4e ba 09 e8          jsr      $a110(pc)  ; -> sub_a110
  00972a:  48 c0                ext.l    d0
  00972c:  2e 00                move.l   d0, d7
  00972e:  4f ef 00 10          lea.l    $10(a7), a7
  009732:  60 12                bra.b    $9746  ; -> L9746
L9734:
  009734:  2f 0c                move.l   a4, -(a7)
  009736:  4e ba 0a 62          jsr      $a19a(pc)  ; -> sub_a19a
  00973a:  48 c0                ext.l    d0
  00973c:  2e 00                move.l   d0, d7
  00973e:  58 8f                addq.l   #$4, a7
  009740:  60 04                bra.b    $9746  ; -> L9746
L9742:
  009742:  70 ce                moveq    #$ce, d0
  009744:  60 02                bra.b    $9748  ; -> L9748
L9746:
  009746:  30 07                move.w   d7, d0
L9748:
  009748:  4c ee 18 c0 ff f0    movem.l  -$10(a6), d6-d7/a3-a4
  00974e:  4e 5e                unlk     a6
  009750:  4e 75                rts
sub_9752:
  009752:  4e 56 ff 76          link.w   a6, #$ff76
  009756:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  00975a:  2c 2e 00 44          move.l   $44(a6), d6
  00975e:  28 6e 00 08          movea.l  $8(a6), a4
  009762:  47 ee ff b0          lea.l    -$50(a6), a3
  009766:  70 00                moveq    #$0, d0
  009768:  2d 40 ff 7a          move.l   d0, -$86(a6)
  00976c:  1d 7c 00 01 ff 9f    move.b   #$1, -$61(a6)
  009772:  2d 40 ff a0          move.l   d0, -$60(a6)
  009776:  22 0c                move.l   a4, d1
  009778:  67 06                beq.b    $9780  ; -> L9780
  00977a:  4a ae 00 14          tst.l    $14(a6)
  00977e:  66 06                bne.b    $9786  ; -> L9786
L9780:
  009780:  70 ff                moveq    #$ff, d0
  009782:  60 00 04 2c          bra.w    $9bb0  ; -> L9bb0
L9786:
  009786:  0c 86 72 70 7a 61    cmpi.l   #$72707a61, d6
  00978c:  66 18                bne.b    $97a6  ; -> L97a6
  00978e:  20 6e 00 14          movea.l  $14(a6), a0
  009792:  20 50                movea.l  (a0), a0
  009794:  30 28 00 20          move.w   $20(a0), d0
  009798:  48 c0                ext.l    d0
  00979a:  72 10                moveq    #$10, d1
  00979c:  b2 80                cmp.l    d0, d1
  00979e:  67 06                beq.b    $97a6  ; -> L97a6
  0097a0:  70 f7                moveq    #$f7, d0
  0097a2:  60 00 04 0c          bra.w    $9bb0  ; -> L9bb0
L97a6:
  0097a6:  20 54                movea.l  (a4), a0
  0097a8:  30 28 00 20          move.w   $20(a0), d0
  0097ac:  48 c0                ext.l    d0
  0097ae:  2e 00                move.l   d0, d7
  0097b0:  20 6e 00 0c          movea.l  $c(a6), a0
  0097b4:  30 28 00 06          move.w   $6(a0), d0
  0097b8:  48 c0                ext.l    d0
  0097ba:  20 6e 00 0c          movea.l  $c(a6), a0
  0097be:  32 28 00 02          move.w   $2(a0), d1
  0097c2:  48 c1                ext.l    d1
  0097c4:  90 81                sub.l    d1, d0
  0097c6:  2d 40 ff 92          move.l   d0, -$6e(a6)
  0097ca:  20 6e 00 0c          movea.l  $c(a6), a0
  0097ce:  30 28 00 04          move.w   $4(a0), d0
  0097d2:  48 c0                ext.l    d0
  0097d4:  20 6e 00 0c          movea.l  $c(a6), a0
  0097d8:  32 10                move.w   (a0), d1
  0097da:  48 c1                ext.l    d1
  0097dc:  28 00                move.l   d0, d4
  0097de:  98 81                sub.l    d1, d4
  0097e0:  20 6e 00 18          movea.l  $18(a6), a0
  0097e4:  30 28 00 06          move.w   $6(a0), d0
  0097e8:  48 c0                ext.l    d0
  0097ea:  20 6e 00 18          movea.l  $18(a6), a0
  0097ee:  32 28 00 02          move.w   $2(a0), d1
  0097f2:  48 c1                ext.l    d1
  0097f4:  90 81                sub.l    d1, d0
  0097f6:  2d 40 ff 96          move.l   d0, -$6a(a6)
  0097fa:  20 6e 00 18          movea.l  $18(a6), a0
  0097fe:  30 28 00 04          move.w   $4(a0), d0
  009802:  48 c0                ext.l    d0
  009804:  20 6e 00 18          movea.l  $18(a6), a0
  009808:  32 10                move.w   (a0), d1
  00980a:  48 c1                ext.l    d1
  00980c:  2a 00                move.l   d0, d5
  00980e:  9a 81                sub.l    d1, d5
  009810:  20 2e ff 92          move.l   -$6e(a6), d0
  009814:  b0 ae ff 96          cmp.l    -$6a(a6), d0
  009818:  67 06                beq.b    $9820  ; -> L9820
  00981a:  70 fa                moveq    #$fa, d0
  00981c:  60 00 03 92          bra.w    $9bb0  ; -> L9bb0
L9820:
  009820:  ba 84                cmp.l    d4, d5
  009822:  6c 06                bge.b    $982a  ; -> L982a
  009824:  70 f9                moveq    #$f9, d0
  009826:  60 00 03 88          bra.w    $9bb0  ; -> L9bb0
L982a:
  00982a:  4a ae 00 10          tst.l    $10(a6)
  00982e:  56 c0                sne.b    d0
  009830:  44 00                neg.b    d0
  009832:  49 c0                extb.l   d0
  009834:  2d 40 ff 86          move.l   d0, -$7a(a6)
  009838:  4a 2e 00 2b          tst.b    $2b(a6)
  00983c:  67 0c                beq.b    $984a  ; -> L984a
  00983e:  4a ae 00 30          tst.l    $30(a6)
  009842:  66 06                bne.b    $984a  ; -> L984a
  009844:  70 ce                moveq    #$ce, d0
  009846:  60 00 03 68          bra.w    $9bb0  ; -> L9bb0
L984a:
  00984a:  4a 2e 00 2f          tst.b    $2f(a6)
  00984e:  67 00 00 a2          beq.w    $98f2  ; -> L98f2
  009852:  70 0a                moveq    #$a, d0
  009854:  2d 40 ff 76          move.l   d0, -$8a(a6)
  009858:  0c 86 72 6c 65 20    cmpi.l   #$726c6520, d6
  00985e:  66 0e                bne.b    $986e  ; -> L986e
  009860:  20 04                move.l   d4, d0
  009862:  4c 2e 08 00 ff 92    muls.l   -$6e(a6), d0
  009868:  e5 80                asl.l    #$2, d0
  00986a:  2a 00                move.l   d0, d5
  00986c:  60 4a                bra.b    $98b8  ; -> L98b8
L986e:
  00986e:  70 10                moveq    #$10, d0
  009870:  22 2e 00 20          move.l   $20(a6), d1
  009874:  e0 a1                asr.l    d0, d1
  009876:  70 03                moveq    #$3, d0
  009878:  b0 81                cmp.l    d1, d0
  00987a:  6d 1e                blt.b    $989a  ; -> L989a
  00987c:  70 10                moveq    #$10, d0
  00987e:  22 2e 00 20          move.l   $20(a6), d1
  009882:  e0 a1                asr.l    d0, d1
  009884:  67 14                beq.b    $989a  ; -> L989a
  009886:  20 2e ff 92          move.l   -$6e(a6), d0
  00988a:  58 80                addq.l   #$4, d0
  00988c:  22 04                move.l   d4, d1
  00988e:  58 81                addq.l   #$4, d1
  009890:  4c 00 18 00          muls.l   d0, d1
  009894:  2a 01                move.l   d1, d5
  009896:  e2 85                asr.l    #$1, d5
  009898:  60 12                bra.b    $98ac  ; -> L98ac
L989a:
  00989a:  20 2e ff 92          move.l   -$6e(a6), d0
  00989e:  58 80                addq.l   #$4, d0
  0098a0:  22 04                move.l   d4, d1
  0098a2:  58 81                addq.l   #$4, d1
  0098a4:  4c 00 18 00          muls.l   d0, d1
  0098a8:  e3 81                asl.l    #$1, d1
  0098aa:  2a 01                move.l   d1, d5
L98ac:
  0098ac:  20 04                move.l   d4, d0
  0098ae:  e5 88                lsl.l    #$2, d0
  0098b0:  da 80                add.l    d0, d5
  0098b2:  06 85 00 00 00 40    addi.l   #$40, d5
L98b8:
  0098b8:  4a ae 00 30          tst.l    $30(a6)
  0098bc:  67 06                beq.b    $98c4  ; -> L98c4
  0098be:  20 6e 00 30          movea.l  $30(a6), a0
  0098c2:  20 85                move.l   d5, (a0)
L98c4:
  0098c4:  4a ae 00 34          tst.l    $34(a6)
  0098c8:  67 22                beq.b    $98ec  ; -> L98ec
  0098ca:  70 02                moveq    #$2, d0
  0098cc:  b0 ae 00 20          cmp.l    $20(a6), d0
  0098d0:  6d 0a                blt.b    $98dc  ; -> L98dc
  0098d2:  20 2e ff 76          move.l   -$8a(a6), d0
  0098d6:  e4 80                asr.l    #$2, d0
  0098d8:  d1 ae ff 76          add.l    d0, -$8a(a6)
L98dc:
  0098dc:  4a ae 00 10          tst.l    $10(a6)
  0098e0:  67 0a                beq.b    $98ec  ; -> L98ec
  0098e2:  20 2e ff 76          move.l   -$8a(a6), d0
  0098e6:  e4 80                asr.l    #$2, d0
  0098e8:  91 ae ff 76          sub.l    d0, -$8a(a6)
L98ec:
  0098ec:  70 00                moveq    #$0, d0
  0098ee:  60 00 02 c0          bra.w    $9bb0  ; -> L9bb0
L98f2:
  0098f2:  0c 86 72 6c 65 20    cmpi.l   #$726c6520, d6
  0098f8:  66 0e                bne.b    $9908  ; -> L9908
  0098fa:  70 20                moveq    #$20, d0
  0098fc:  b0 87                cmp.l    d7, d0
  0098fe:  67 08                beq.b    $9908  ; -> L9908
  009900:  30 3c dd 04          move.w   #$dd04, d0
  009904:  60 00 02 aa          bra.w    $9bb0  ; -> L9bb0
L9908:
  009908:  0c 86 72 70 7a 61    cmpi.l   #$72707a61, d6
  00990e:  66 0e                bne.b    $991e  ; -> L991e
  009910:  70 08                moveq    #$8, d0
  009912:  b0 87                cmp.l    d7, d0
  009914:  6f 08                ble.b    $991e  ; -> L991e
  009916:  30 3c dd 04          move.w   #$dd04, d0
  00991a:  60 00 02 94          bra.w    $9bb0  ; -> L9bb0
L991e:
  00991e:  70 08                moveq    #$8, d0
  009920:  b0 87                cmp.l    d7, d0
  009922:  66 16                bne.b    $993a  ; -> L993a
  009924:  59 8f                subq.l   #$4, a7
  009926:  20 54                movea.l  (a4), a0
  009928:  20 68 00 2a          movea.l  $2a(a0), a0
  00992c:  20 50                movea.l  (a0), a0
  00992e:  48 68 00 08          pea.l    $8(a0)
  009932:  4e ba 0c 6a          jsr      $a59e(pc)  ; -> sub_a59e
  009936:  2d 5f ff fc          move.l   (a7)+, -$4(a6)
L993a:
  00993a:  59 8f                subq.l   #$4, a7
  00993c:  2f 0c                move.l   a4, -(a7)
  00993e:  70 0d                moveq    #$d, d0
  009940:  ab 1d                dc.w     $ab1d
  009942:  2d 5f ff f4          move.l   (a7)+, -$c(a6)
  009946:  55 8f                subq.l   #$2, a7
  009948:  2f 0c                move.l   a4, -(a7)
  00994a:  70 01                moveq    #$1, d0
  00994c:  ab 1d                dc.w     $ab1d
  00994e:  59 8f                subq.l   #$4, a7
  009950:  2f 0c                move.l   a4, -(a7)
  009952:  70 0f                moveq    #$f, d0
  009954:  ab 1d                dc.w     $ab1d
  009956:  2d 5f ff a4          move.l   (a7)+, -$5c(a6)
  00995a:  20 54                movea.l  (a4), a0
  00995c:  30 28 00 04          move.w   $4(a0), d0
  009960:  48 c0                ext.l    d0
  009962:  28 3c 00 00 3f ff    move.l   #$3fff, d4
  009968:  c8 80                and.l    d0, d4
  00996a:  20 04                move.l   d4, d0
  00996c:  e4 80                asr.l    #$2, d0
  00996e:  2d 40 ff 8e          move.l   d0, -$72(a6)
  009972:  59 8f                subq.l   #$4, a7
  009974:  2f 2e 00 1c          move.l   $1c(a6), -(a7)
  009978:  4e ba 0c 24          jsr      $a59e(pc)  ; -> sub_a59e
  00997c:  2d 5f ff 9a          move.l   (a7)+, -$66(a6)
  009980:  20 6e 00 0c          movea.l  $c(a6), a0
  009984:  30 28 00 02          move.w   $2(a0), d0
  009988:  48 c0                ext.l    d0
  00998a:  20 54                movea.l  (a4), a0
  00998c:  32 28 00 08          move.w   $8(a0), d1
  009990:  48 c1                ext.l    d1
  009992:  2a 00                move.l   d0, d5
  009994:  9a 81                sub.l    d1, d5
  009996:  70 20                moveq    #$20, d0
  009998:  b0 87                cmp.l    d7, d0
  00999a:  54 8f                addq.l   #$2, a7
  00999c:  66 04                bne.b    $99a2  ; -> L99a2
  00999e:  e5 8d                lsl.l    #$2, d5
  0099a0:  60 08                bra.b    $99aa  ; -> L99aa
L99a2:
  0099a2:  70 10                moveq    #$10, d0
  0099a4:  b0 87                cmp.l    d7, d0
  0099a6:  66 02                bne.b    $99aa  ; -> L99aa
  0099a8:  e3 8d                lsl.l    #$1, d5
L99aa:
  0099aa:  20 6e 00 0c          movea.l  $c(a6), a0
  0099ae:  30 10                move.w   (a0), d0
  0099b0:  48 c0                ext.l    d0
  0099b2:  20 54                movea.l  (a4), a0
  0099b4:  32 28 00 06          move.w   $6(a0), d1
  0099b8:  48 c1                ext.l    d1
  0099ba:  90 81                sub.l    d1, d0
  0099bc:  4c 04 08 00          muls.l   d4, d0
  0099c0:  2d 40 ff a8          move.l   d0, -$58(a6)
  0099c4:  4a ae ff 86          tst.l    -$7a(a6)
  0099c8:  67 00 00 8c          beq.w    $9a56  ; -> L9a56
  0099cc:  20 6e 00 10          movea.l  $10(a6), a0
  0099d0:  20 50                movea.l  (a0), a0
  0099d2:  30 28 00 20          move.w   $20(a0), d0
  0099d6:  48 c0                ext.l    d0
  0099d8:  2d 40 ff ac          move.l   d0, -$54(a6)
  0099dc:  70 20                moveq    #$20, d0
  0099de:  b0 ae ff ac          cmp.l    -$54(a6), d0
  0099e2:  67 10                beq.b    $99f4  ; -> L99f4
  0099e4:  2f 0c                move.l   a4, -(a7)
  0099e6:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  0099ea:  70 0e                moveq    #$e, d0
  0099ec:  ab 1d                dc.w     $ab1d
  0099ee:  70 ef                moveq    #$ef, d0
  0099f0:  60 00 01 be          bra.w    $9bb0  ; -> L9bb0
L99f4:
  0099f4:  20 6e 00 10          movea.l  $10(a6), a0
  0099f8:  20 50                movea.l  (a0), a0
  0099fa:  30 28 00 1e          move.w   $1e(a0), d0
  0099fe:  48 c0                ext.l    d0
  009a00:  72 10                moveq    #$10, d1
  009a02:  b2 80                cmp.l    d0, d1
  009a04:  67 10                beq.b    $9a16  ; -> L9a16
  009a06:  2f 0c                move.l   a4, -(a7)
  009a08:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  009a0c:  70 0e                moveq    #$e, d0
  009a0e:  ab 1d                dc.w     $ab1d
  009a10:  70 ee                moveq    #$ee, d0
  009a12:  60 00 01 9c          bra.w    $9bb0  ; -> L9bb0
L9a16:
  009a16:  59 8f                subq.l   #$4, a7
  009a18:  2f 2e 00 10          move.l   $10(a6), -(a7)
  009a1c:  70 0d                moveq    #$d, d0
  009a1e:  ab 1d                dc.w     $ab1d
  009a20:  2d 5f ff f8          move.l   (a7)+, -$8(a6)
  009a24:  55 8f                subq.l   #$2, a7
  009a26:  2f 2e 00 10          move.l   $10(a6), -(a7)
  009a2a:  70 01                moveq    #$1, d0
  009a2c:  ab 1d                dc.w     $ab1d
  009a2e:  59 8f                subq.l   #$4, a7
  009a30:  2f 2e 00 10          move.l   $10(a6), -(a7)
  009a34:  70 0f                moveq    #$f, d0
  009a36:  ab 1d                dc.w     $ab1d
  009a38:  2d 5f ff 7e          move.l   (a7)+, -$82(a6)
  009a3c:  20 6e 00 10          movea.l  $10(a6), a0
  009a40:  20 50                movea.l  (a0), a0
  009a42:  30 28 00 04          move.w   $4(a0), d0
  009a46:  48 c0                ext.l    d0
  009a48:  22 3c 00 00 3f ff    move.l   #$3fff, d1
  009a4e:  c2 80                and.l    d0, d1
  009a50:  2d 41 ff 82          move.l   d1, -$7e(a6)
  009a54:  54 8f                addq.l   #$2, a7
L9a56:
  009a56:  4e ba ec b8          jsr      $8710(pc)  ; -> s7_sub_6e14
  009a5a:  72 00                moveq    #$0, d1
  009a5c:  12 00                move.b   d0, d1
  009a5e:  67 f6                beq.b    $9a56  ; -> L9a56
  009a60:  42 2e 00 2b          clr.b    $2b(a6)
  009a64:  4a 2e 00 2b          tst.b    $2b(a6)
  009a68:  67 08                beq.b    $9a72  ; -> L9a72
  009a6a:  20 6e 00 30          movea.l  $30(a6), a0
  009a6e:  70 00                moveq    #$0, d0
  009a70:  20 80                move.l   d0, (a0)
L9a72:
  009a72:  20 05                move.l   d5, d0
  009a74:  d0 ae ff a4          add.l    -$5c(a6), d0
  009a78:  22 2e ff a8          move.l   -$58(a6), d1
  009a7c:  d2 80                add.l    d0, d1
  009a7e:  2d 41 ff 8a          move.l   d1, -$76(a6)
  009a82:  4a ae ff 86          tst.l    -$7a(a6)
  009a86:  67 7c                beq.b    $9b04  ; -> L9b04
  009a88:  26 86                move.l   d6, (a3)
  009a8a:  27 6e ff 9a 00 04    move.l   -$66(a6), $4(a3)
  009a90:  27 54 00 08          move.l   (a4), $8(a3)
  009a94:  27 6e 00 0c 00 0c    move.l   $c(a6), $c(a3)
  009a9a:  20 6e 00 14          movea.l  $14(a6), a0
  009a9e:  27 50 00 10          move.l   (a0), $10(a3)
  009aa2:  27 6e 00 18 00 14    move.l   $18(a6), $14(a3)
  009aa8:  27 6e 00 20 00 18    move.l   $20(a6), $18(a3)
  009aae:  20 6e 00 10          movea.l  $10(a6), a0
  009ab2:  27 50 00 1c          move.l   (a0), $1c(a3)
  009ab6:  27 6e 00 24 00 20    move.l   $24(a6), $20(a3)
  009abc:  20 05                move.l   d5, d0
  009abe:  d0 ae ff a4          add.l    -$5c(a6), d0
  009ac2:  22 2e ff a8          move.l   -$58(a6), d1
  009ac6:  d2 80                add.l    d0, d1
  009ac8:  27 41 00 24          move.l   d1, $24(a3)
  009acc:  27 44 00 28          move.l   d4, $28(a3)
  009ad0:  27 47 00 2c          move.l   d7, $2c(a3)
  009ad4:  27 6e ff 7e 00 30    move.l   -$82(a6), $30(a3)
  009ada:  27 6e ff 82 00 34    move.l   -$7e(a6), $34(a3)
  009ae0:  27 6e ff ac 00 38    move.l   -$54(a6), $38(a3)
  009ae6:  27 6e ff fc 00 3c    move.l   -$4(a6), $3c(a3)
  009aec:  70 10                moveq    #$10, d0
  009aee:  2f 00                move.l   d0, -(a7)
  009af0:  2f 0b                move.l   a3, -(a7)
  009af2:  72 3b                moveq    #$3b, d1
  009af4:  2f 01                move.l   d1, -(a7)
  009af6:  4e ba c7 2c          jsr      $6224(pc)  ; -> EngineDispatch
  009afa:  2d 40 ff f0          move.l   d0, -$10(a6)
  009afe:  4f ef 00 0c          lea.l    $c(a7), a7
  009b02:  60 5a                bra.b    $9b5e  ; -> L9b5e
L9b04:
  009b04:  26 86                move.l   d6, (a3)
  009b06:  27 6e ff 9a 00 04    move.l   -$66(a6), $4(a3)
  009b0c:  27 54 00 08          move.l   (a4), $8(a3)
  009b10:  27 6e 00 0c 00 0c    move.l   $c(a6), $c(a3)
  009b16:  20 6e 00 14          movea.l  $14(a6), a0
  009b1a:  27 50 00 10          move.l   (a0), $10(a3)
  009b1e:  27 6e 00 18 00 14    move.l   $18(a6), $14(a3)
  009b24:  27 6e 00 20 00 18    move.l   $20(a6), $18(a3)
  009b2a:  20 05                move.l   d5, d0
  009b2c:  d0 ae ff a4          add.l    -$5c(a6), d0
  009b30:  22 2e ff a8          move.l   -$58(a6), d1
  009b34:  d2 80                add.l    d0, d1
  009b36:  27 41 00 1c          move.l   d1, $1c(a3)
  009b3a:  27 44 00 20          move.l   d4, $20(a3)
  009b3e:  27 47 00 24          move.l   d7, $24(a3)
  009b42:  27 6e ff fc 00 28    move.l   -$4(a6), $28(a3)
  009b48:  70 0b                moveq    #$b, d0
  009b4a:  2f 00                move.l   d0, -(a7)
  009b4c:  2f 0b                move.l   a3, -(a7)
  009b4e:  72 3a                moveq    #$3a, d1
  009b50:  2f 01                move.l   d1, -(a7)
  009b52:  4e ba c6 d0          jsr      $6224(pc)  ; -> EngineDispatch
  009b56:  2d 40 ff f0          move.l   d0, -$10(a6)
  009b5a:  4f ef 00 0c          lea.l    $c(a7), a7
L9b5e:
  009b5e:  70 00                moveq    #$0, d0
  009b60:  10 2e 00 2b          move.b   $2b(a6), d0
  009b64:  66 22                bne.b    $9b88  ; -> L9b88
L9b66:
  009b66:  4e ba eb a8          jsr      $8710(pc)  ; -> s7_sub_6e14
  009b6a:  72 00                moveq    #$0, d1
  009b6c:  12 00                move.b   d0, d1
  009b6e:  67 f6                beq.b    $9b66  ; -> L9b66
  009b70:  4e ba ec 54          jsr      $87c6(pc)  ; -> sub_87c6
  009b74:  2d 40 ff f0          move.l   d0, -$10(a6)
  009b78:  4a ae 00 30          tst.l    $30(a6)
  009b7c:  67 14                beq.b    $9b92  ; -> L9b92
  009b7e:  20 6e 00 30          movea.l  $30(a6), a0
  009b82:  20 ae ff f0          move.l   -$10(a6), (a0)
  009b86:  60 0a                bra.b    $9b92  ; -> L9b92
L9b88:
  009b88:  2f 2e 00 30          move.l   $30(a6), -(a7)
  009b8c:  4e ba ec 64          jsr      $87f2(pc)  ; -> sub_87f2
  009b90:  58 8f                addq.l   #$4, a7
L9b92:
  009b92:  2f 0c                move.l   a4, -(a7)
  009b94:  2f 2e ff f4          move.l   -$c(a6), -(a7)
  009b98:  70 0e                moveq    #$e, d0
  009b9a:  ab 1d                dc.w     $ab1d
  009b9c:  4a ae 00 10          tst.l    $10(a6)
  009ba0:  67 0c                beq.b    $9bae  ; -> L9bae
  009ba2:  2f 2e 00 10          move.l   $10(a6), -(a7)
  009ba6:  2f 2e ff f8          move.l   -$8(a6), -(a7)
  009baa:  70 0e                moveq    #$e, d0
  009bac:  ab 1d                dc.w     $ab1d
L9bae:
  009bae:  70 00                moveq    #$0, d0
L9bb0:
  009bb0:  4c ee 18 f0 ff 5e    movem.l  -$a2(a6), d4-d7/a3-a4
  009bb6:  4e 5e                unlk     a6
  009bb8:  4e 75                rts
sub_9bba:
  009bba:  4e 56 ff 80          link.w   a6, #$ff80
  009bbe:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  009bc2:  28 2e 00 3c          move.l   $3c(a6), d4
  009bc6:  47 ee ff a8          lea.l    -$58(a6), a3
  009bca:  70 00                moveq    #$0, d0
  009bcc:  2d 40 ff fc          move.l   d0, -$4(a6)
  009bd0:  2f 2e 00 38          move.l   $38(a6), -(a7)
  009bd4:  4e ba 05 52          jsr      $a128(pc)  ; -> sub_a128
  009bd8:  28 40                movea.l  d0, a4
  009bda:  20 0c                move.l   a4, d0
  009bdc:  58 8f                addq.l   #$4, a7
  009bde:  66 06                bne.b    $9be6  ; -> L9be6
  009be0:  70 94                moveq    #$94, d0
  009be2:  60 00 04 c6          bra.w    $a0aa  ; -> La0aa
L9be6:
  009be6:  30 2e 00 1e          move.w   $1e(a6), d0
  009bea:  48 c0                ext.l    d0
  009bec:  72 0f                moveq    #$f, d1
  009bee:  c2 80                and.l    d0, d1
  009bf0:  67 08                beq.b    $9bfa  ; -> L9bfa
  009bf2:  30 3c dd 02          move.w   #$dd02, d0
  009bf6:  60 00 04 b2          bra.w    $a0aa  ; -> La0aa
L9bfa:
  009bfa:  4a ae 00 08          tst.l    $8(a6)
  009bfe:  67 06                beq.b    $9c06  ; -> L9c06
  009c00:  4a ae 00 10          tst.l    $10(a6)
  009c04:  66 06                bne.b    $9c0c  ; -> L9c0c
L9c06:
  009c06:  70 ce                moveq    #$ce, d0
  009c08:  60 00 04 a0          bra.w    $a0aa  ; -> La0aa
L9c0c:
  009c0c:  0c 84 72 70 7a 61    cmpi.l   #$72707a61, d4
  009c12:  66 1a                bne.b    $9c2e  ; -> L9c2e
  009c14:  20 6e 00 08          movea.l  $8(a6), a0
  009c18:  20 50                movea.l  (a0), a0
  009c1a:  30 28 00 20          move.w   $20(a0), d0
  009c1e:  48 c0                ext.l    d0
  009c20:  72 10                moveq    #$10, d1
  009c22:  b2 80                cmp.l    d0, d1
  009c24:  67 08                beq.b    $9c2e  ; -> L9c2e
  009c26:  30 3c dd 04          move.w   #$dd04, d0
  009c2a:  60 00 04 7e          bra.w    $a0aa  ; -> La0aa
L9c2e:
  009c2e:  20 6e 00 10          movea.l  $10(a6), a0
  009c32:  20 50                movea.l  (a0), a0
  009c34:  30 28 00 20          move.w   $20(a0), d0
  009c38:  48 c0                ext.l    d0
  009c3a:  2e 00                move.l   d0, d7
  009c3c:  20 6e 00 08          movea.l  $8(a6), a0
  009c40:  20 50                movea.l  (a0), a0
  009c42:  30 28 00 0c          move.w   $c(a0), d0
  009c46:  48 c0                ext.l    d0
  009c48:  20 6e 00 08          movea.l  $8(a6), a0
  009c4c:  20 50                movea.l  (a0), a0
  009c4e:  32 28 00 08          move.w   $8(a0), d1
  009c52:  48 c1                ext.l    d1
  009c54:  2a 00                move.l   d0, d5
  009c56:  9a 81                sub.l    d1, d5
  009c58:  20 6e 00 08          movea.l  $8(a6), a0
  009c5c:  20 50                movea.l  (a0), a0
  009c5e:  30 28 00 0a          move.w   $a(a0), d0
  009c62:  48 c0                ext.l    d0
  009c64:  20 6e 00 08          movea.l  $8(a6), a0
  009c68:  20 50                movea.l  (a0), a0
  009c6a:  32 28 00 06          move.w   $6(a0), d1
  009c6e:  48 c1                ext.l    d1
  009c70:  2c 00                move.l   d0, d6
  009c72:  9c 81                sub.l    d1, d6
  009c74:  20 6e 00 0c          movea.l  $c(a6), a0
  009c78:  30 28 00 06          move.w   $6(a0), d0
  009c7c:  48 c0                ext.l    d0
  009c7e:  20 6e 00 0c          movea.l  $c(a6), a0
  009c82:  32 28 00 02          move.w   $2(a0), d1
  009c86:  48 c1                ext.l    d1
  009c88:  90 81                sub.l    d1, d0
  009c8a:  2d 40 ff 8c          move.l   d0, -$74(a6)
  009c8e:  20 6e 00 0c          movea.l  $c(a6), a0
  009c92:  30 28 00 04          move.w   $4(a0), d0
  009c96:  48 c0                ext.l    d0
  009c98:  20 6e 00 0c          movea.l  $c(a6), a0
  009c9c:  32 10                move.w   (a0), d1
  009c9e:  48 c1                ext.l    d1
  009ca0:  90 81                sub.l    d1, d0
  009ca2:  2d 40 ff 90          move.l   d0, -$70(a6)
  009ca6:  ba ae ff 8c          cmp.l    -$74(a6), d5
  009caa:  66 06                bne.b    $9cb2  ; -> L9cb2
  009cac:  bc ae ff 90          cmp.l    -$70(a6), d6
  009cb0:  67 08                beq.b    $9cba  ; -> L9cba
L9cb2:
  009cb2:  30 3c dd 00          move.w   #$dd00, d0
  009cb6:  60 00 03 f2          bra.w    $a0aa  ; -> La0aa
L9cba:
  009cba:  20 6e 00 14          movea.l  $14(a6), a0
  009cbe:  30 28 00 06          move.w   $6(a0), d0
  009cc2:  48 c0                ext.l    d0
  009cc4:  20 6e 00 14          movea.l  $14(a6), a0
  009cc8:  32 28 00 02          move.w   $2(a0), d1
  009ccc:  48 c1                ext.l    d1
  009cce:  90 81                sub.l    d1, d0
  009cd0:  2d 40 ff 94          move.l   d0, -$6c(a6)
  009cd4:  20 6e 00 14          movea.l  $14(a6), a0
  009cd8:  30 28 00 04          move.w   $4(a0), d0
  009cdc:  48 c0                ext.l    d0
  009cde:  20 6e 00 14          movea.l  $14(a6), a0
  009ce2:  32 10                move.w   (a0), d1
  009ce4:  48 c1                ext.l    d1
  009ce6:  90 81                sub.l    d1, d0
  009ce8:  2d 40 ff 98          move.l   d0, -$68(a6)
  009cec:  ba ae ff 94          cmp.l    -$6c(a6), d5
  009cf0:  67 08                beq.b    $9cfa  ; -> L9cfa
  009cf2:  30 3c dd 00          move.w   #$dd00, d0
  009cf6:  60 00 03 b2          bra.w    $a0aa  ; -> La0aa
L9cfa:
  009cfa:  bc ae ff 98          cmp.l    -$68(a6), d6
  009cfe:  6f 08                ble.b    $9d08  ; -> L9d08
  009d00:  30 3c dd 00          move.w   #$dd00, d0
  009d04:  60 00 03 a4          bra.w    $a0aa  ; -> La0aa
L9d08:
  009d08:  59 8f                subq.l   #$4, a7
  009d0a:  2f 2e 00 18          move.l   $18(a6), -(a7)
  009d0e:  4e ba 08 8e          jsr      $a59e(pc)  ; -> sub_a59e
  009d12:  2d 5f ff 88          move.l   (a7)+, -$78(a6)
  009d16:  4a ae 00 20          tst.l    $20(a6)
  009d1a:  67 3c                beq.b    $9d58  ; -> L9d58
  009d1c:  20 54                movea.l  (a4), a0
  009d1e:  2f 28 00 0c          move.l   $c(a0), -(a7)
  009d22:  2f 2e 00 14          move.l   $14(a6), -(a7)
  009d26:  a8 df                dc.w     $a8df
  009d28:  20 54                movea.l  (a4), a0
  009d2a:  2f 28 00 0c          move.l   $c(a0), -(a7)
  009d2e:  2f 2e 00 20          move.l   $20(a6), -(a7)
  009d32:  20 54                movea.l  (a4), a0
  009d34:  2f 28 00 10          move.l   $10(a0), -(a7)
  009d38:  a8 e4                dc.w     $a8e4
  009d3a:  55 8f                subq.l   #$2, a7
  009d3c:  20 54                movea.l  (a4), a0
  009d3e:  2f 28 00 0c          move.l   $c(a0), -(a7)
  009d42:  20 54                movea.l  (a4), a0
  009d44:  2f 28 00 10          move.l   $10(a0), -(a7)
  009d48:  a8 e3                dc.w     $a8e3
  009d4a:  70 00                moveq    #$0, d0
  009d4c:  10 1f                move.b   (a7)+, d0
  009d4e:  66 08                bne.b    $9d58  ; -> L9d58
  009d50:  30 3c dd 00          move.w   #$dd00, d0
  009d54:  60 00 03 54          bra.w    $a0aa  ; -> La0aa
L9d58:
  009d58:  0c 84 72 6c 65 20    cmpi.l   #$726c6520, d4
  009d5e:  66 0e                bne.b    $9d6e  ; -> L9d6e
  009d60:  70 20                moveq    #$20, d0
  009d62:  b0 87                cmp.l    d7, d0
  009d64:  67 08                beq.b    $9d6e  ; -> L9d6e
  009d66:  30 3c dd 08          move.w   #$dd08, d0
  009d6a:  60 00 03 3e          bra.w    $a0aa  ; -> La0aa
L9d6e:
  009d6e:  0c 84 72 70 7a 61    cmpi.l   #$72707a61, d4
  009d74:  66 0e                bne.b    $9d84  ; -> L9d84
  009d76:  70 08                moveq    #$8, d0
  009d78:  b0 87                cmp.l    d7, d0
  009d7a:  6f 08                ble.b    $9d84  ; -> L9d84
  009d7c:  30 3c dd 08          move.w   #$dd08, d0
  009d80:  60 00 03 28          bra.w    $a0aa  ; -> La0aa
L9d84:
  009d84:  70 08                moveq    #$8, d0
  009d86:  b0 87                cmp.l    d7, d0
  009d88:  66 00 01 84          bne.w    $9f0e  ; -> L9f0e
  009d8c:  42 2e ff 87          clr.b    -$79(a6)
  009d90:  2d 78 0c c8 ff f4    move.l   $cc8.w, -$c(a6)
  009d96:  30 2e 00 1e          move.w   $1e(a6), d0
  009d9a:  48 c0                ext.l    d0
  009d9c:  72 40                moveq    #$40, d1
  009d9e:  c2 80                and.l    d0, d1
  009da0:  67 00 00 da          beq.w    $9e7c  ; -> L9e7c
  009da4:  20 54                movea.l  (a4), a0
  009da6:  4a a8 00 04          tst.l    $4(a0)
  009daa:  66 52                bne.b    $9dfe  ; -> L9dfe
  009dac:  59 8f                subq.l   #$4, a7
  009dae:  4e ba 06 74          jsr      $a424(pc)  ; -> sub_a424
  009db2:  2d 5f ff 80          move.l   (a7)+, -$80(a6)
  009db6:  59 8f                subq.l   #$4, a7
  009db8:  2e b8 02 a6          move.l   $2a6.w, (a7)
  009dbc:  4e ba 06 70          jsr      $a42e(pc)  ; -> sub_a42e
  009dc0:  59 8f                subq.l   #$4, a7
  009dc2:  2f 3c 00 02 00 08    move.l   #$20008, -(a7)
  009dc8:  4e ba 06 92          jsr      $a45c(pc)  ; -> sub_a45c
  009dcc:  20 54                movea.l  (a4), a0
  009dce:  21 5f 00 04          move.l   (a7)+, $4(a0)
  009dd2:  66 1a                bne.b    $9dee  ; -> L9dee
  009dd4:  2f 2e ff 80          move.l   -$80(a6), -(a7)
  009dd8:  4e ba 06 54          jsr      $a42e(pc)  ; -> sub_a42e
  009ddc:  2f 2e 00 10          move.l   $10(a6), -(a7)
  009de0:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  009de4:  70 0e                moveq    #$e, d0
  009de6:  ab 1d                dc.w     $ab1d
  009de8:  70 94                moveq    #$94, d0
  009dea:  60 00 02 be          bra.w    $a0aa  ; -> La0aa
L9dee:
  009dee:  2f 2e ff 80          move.l   -$80(a6), -(a7)
  009df2:  4e ba 06 3a          jsr      $a42e(pc)  ; -> sub_a42e
  009df6:  1d 7c 00 01 ff 87    move.b   #$1, -$79(a6)
  009dfc:  60 26                bra.b    $9e24  ; -> L9e24
L9dfe:
  009dfe:  20 6e ff f4          movea.l  -$c(a6), a0
  009e02:  20 50                movea.l  (a0), a0
  009e04:  20 68 00 16          movea.l  $16(a0), a0
  009e08:  20 50                movea.l  (a0), a0
  009e0a:  20 68 00 2a          movea.l  $2a(a0), a0
  009e0e:  20 50                movea.l  (a0), a0
  009e10:  22 54                movea.l  (a4), a1
  009e12:  22 69 00 04          movea.l  $4(a1), a1
  009e16:  22 51                movea.l  (a1), a1
  009e18:  20 10                move.l   (a0), d0
  009e1a:  b0 91                cmp.l    (a1), d0
  009e1c:  67 06                beq.b    $9e24  ; -> L9e24
  009e1e:  1d 7c 00 01 ff 87    move.b   #$1, -$79(a6)
L9e24:
  009e24:  4a 2e ff 87          tst.b    -$79(a6)
  009e28:  67 2c                beq.b    $9e56  ; -> L9e56
  009e2a:  70 05                moveq    #$5, d0
  009e2c:  2f 00                move.l   d0, -(a7)
  009e2e:  20 54                movea.l  (a4), a0
  009e30:  2f 28 00 04          move.l   $4(a0), -(a7)
  009e34:  20 6e ff f4          movea.l  -$c(a6), a0
  009e38:  20 50                movea.l  (a0), a0
  009e3a:  20 68 00 16          movea.l  $16(a0), a0
  009e3e:  20 50                movea.l  (a0), a0
  009e40:  2f 28 00 2a          move.l   $2a(a0), -(a7)
  009e44:  20 6e ff f4          movea.l  -$c(a6), a0
  009e48:  20 50                movea.l  (a0), a0
  009e4a:  2f 28 00 06          move.l   $6(a0), -(a7)
  009e4e:  4e ba 03 82          jsr      $a1d2(pc)  ; -> sub_a1d2
  009e52:  4f ef 00 10          lea.l    $10(a7), a7
L9e56:
  009e56:  20 54                movea.l  (a4), a0
  009e58:  2d 68 00 04 ff fc    move.l   $4(a0), -$4(a6)
  009e5e:  2f 28 00 04          move.l   $4(a0), -(a7)
  009e62:  4e ba 06 46          jsr      $a4aa(pc)  ; -> sub_a4aa
  009e66:  59 8f                subq.l   #$4, a7
  009e68:  20 54                movea.l  (a4), a0
  009e6a:  20 68 00 04          movea.l  $4(a0), a0
  009e6e:  2f 10                move.l   (a0), -(a7)
  009e70:  4e ba 07 2c          jsr      $a59e(pc)  ; -> sub_a59e
  009e74:  2d 5f ff f8          move.l   (a7)+, -$8(a6)
  009e78:  60 00 00 94          bra.w    $9f0e  ; -> L9f0e
L9e7c:
  009e7c:  20 6e ff f4          movea.l  -$c(a6), a0
  009e80:  20 50                movea.l  (a0), a0
  009e82:  20 68 00 06          movea.l  $6(a0), a0
  009e86:  20 50                movea.l  (a0), a0
  009e88:  30 28 00 04          move.w   $4(a0), d0
  009e8c:  48 c0                ext.l    d0
  009e8e:  72 05                moveq    #$5, d1
  009e90:  b2 80                cmp.l    d0, d1
  009e92:  66 24                bne.b    $9eb8  ; -> L9eb8
  009e94:  20 6e ff f4          movea.l  -$c(a6), a0
  009e98:  20 50                movea.l  (a0), a0
  009e9a:  20 68 00 06          movea.l  $6(a0), a0
  009e9e:  20 50                movea.l  (a0), a0
  009ea0:  22 6e ff f4          movea.l  -$c(a6), a1
  009ea4:  22 51                movea.l  (a1), a1
  009ea6:  22 69 00 16          movea.l  $16(a1), a1
  009eaa:  22 51                movea.l  (a1), a1
  009eac:  22 69 00 2a          movea.l  $2a(a1), a1
  009eb0:  22 51                movea.l  (a1), a1
  009eb2:  20 10                move.l   (a0), d0
  009eb4:  b0 91                cmp.l    (a1), d0
  009eb6:  67 28                beq.b    $9ee0  ; -> L9ee0
L9eb8:
  009eb8:  70 00                moveq    #$0, d0
  009eba:  2f 00                move.l   d0, -(a7)
  009ebc:  2f 00                move.l   d0, -(a7)
  009ebe:  72 05                moveq    #$5, d1
  009ec0:  3f 01                move.w   d1, -(a7)
  009ec2:  aa 39                dc.w     $aa39
  009ec4:  55 8f                subq.l   #$2, a7
  009ec6:  aa 40                dc.w     $aa40
  009ec8:  4a 5f                tst.w    (a7)+
  009eca:  67 14                beq.b    $9ee0  ; -> L9ee0
  009ecc:  2f 2e 00 10          move.l   $10(a6), -(a7)
  009ed0:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  009ed4:  70 0e                moveq    #$e, d0
  009ed6:  ab 1d                dc.w     $ab1d
  009ed8:  30 3c dd 02          move.w   #$dd02, d0
  009edc:  60 00 01 cc          bra.w    $a0aa  ; -> La0aa
L9ee0:
  009ee0:  20 6e ff f4          movea.l  -$c(a6), a0
  009ee4:  20 50                movea.l  (a0), a0
  009ee6:  2d 68 00 06 ff fc    move.l   $6(a0), -$4(a6)
  009eec:  2f 28 00 06          move.l   $6(a0), -(a7)
  009ef0:  4e ba 05 b8          jsr      $a4aa(pc)  ; -> sub_a4aa
  009ef4:  59 8f                subq.l   #$4, a7
  009ef6:  20 6e ff f4          movea.l  -$c(a6), a0
  009efa:  20 50                movea.l  (a0), a0
  009efc:  20 68 00 06          movea.l  $6(a0), a0
  009f00:  20 50                movea.l  (a0), a0
  009f02:  48 68 00 06          pea.l    $6(a0)
  009f06:  4e ba 06 96          jsr      $a59e(pc)  ; -> sub_a59e
  009f0a:  2d 5f ff f8          move.l   (a7)+, -$8(a6)
L9f0e:
  009f0e:  20 6e 00 10          movea.l  $10(a6), a0
  009f12:  20 50                movea.l  (a0), a0
  009f14:  30 28 00 04          move.w   $4(a0), d0
  009f18:  48 c0                ext.l    d0
  009f1a:  22 3c 00 00 3f ff    move.l   #$3fff, d1
  009f20:  c2 80                and.l    d0, d1
  009f22:  2d 41 ff a4          move.l   d1, -$5c(a6)
  009f26:  20 6e 00 10          movea.l  $10(a6), a0
  009f2a:  20 50                movea.l  (a0), a0
  009f2c:  43 ee ff e8          lea.l    -$18(a6), a1
  009f30:  5c 88                addq.l   #$6, a0
  009f32:  22 d8                move.l   (a0)+, (a1)+
  009f34:  22 d8                move.l   (a0)+, (a1)+
  009f36:  20 6e 00 14          movea.l  $14(a6), a0
  009f3a:  30 28 00 02          move.w   $2(a0), d0
  009f3e:  48 c0                ext.l    d0
  009f40:  32 2e ff ea          move.w   -$16(a6), d1
  009f44:  48 c1                ext.l    d1
  009f46:  90 81                sub.l    d1, d0
  009f48:  2d 40 ff 9c          move.l   d0, -$64(a6)
  009f4c:  70 20                moveq    #$20, d0
  009f4e:  b0 87                cmp.l    d7, d0
  009f50:  66 0c                bne.b    $9f5e  ; -> L9f5e
  009f52:  20 2e ff 9c          move.l   -$64(a6), d0
  009f56:  e5 88                lsl.l    #$2, d0
  009f58:  2d 40 ff 9c          move.l   d0, -$64(a6)
  009f5c:  60 10                bra.b    $9f6e  ; -> L9f6e
L9f5e:
  009f5e:  70 10                moveq    #$10, d0
  009f60:  b0 87                cmp.l    d7, d0
  009f62:  66 0a                bne.b    $9f6e  ; -> L9f6e
  009f64:  20 2e ff 9c          move.l   -$64(a6), d0
  009f68:  e3 88                lsl.l    #$1, d0
  009f6a:  2d 40 ff 9c          move.l   d0, -$64(a6)
L9f6e:
  009f6e:  20 6e 00 14          movea.l  $14(a6), a0
  009f72:  30 10                move.w   (a0), d0
  009f74:  48 c0                ext.l    d0
  009f76:  32 2e ff e8          move.w   -$18(a6), d1
  009f7a:  48 c1                ext.l    d1
  009f7c:  90 81                sub.l    d1, d0
  009f7e:  4c 2e 08 00 ff a4    muls.l   -$5c(a6), d0
  009f84:  2d 40 ff a0          move.l   d0, -$60(a6)
  009f88:  4a 2e 00 2b          tst.b    $2b(a6)
  009f8c:  67 50                beq.b    $9fde  ; -> L9fde
  009f8e:  70 0a                moveq    #$a, d0
  009f90:  2d 40 ff 84          move.l   d0, -$7c(a6)
  009f94:  4a ae 00 2c          tst.l    $2c(a6)
  009f98:  67 12                beq.b    $9fac  ; -> L9fac
  009f9a:  20 06                move.l   d6, d0
  009f9c:  4c 05 08 00          muls.l   d5, d0
  009fa0:  22 00                move.l   d0, d1
  009fa2:  d0 80                add.l    d0, d0
  009fa4:  d0 81                add.l    d1, d0
  009fa6:  20 6e 00 2c          movea.l  $2c(a6), a0
  009faa:  20 80                move.l   d0, (a0)
L9fac:
  009fac:  4a ae 00 30          tst.l    $30(a6)
  009fb0:  67 26                beq.b    $9fd8  ; -> L9fd8
  009fb2:  22 2e ff 84          move.l   -$7c(a6), d1
  009fb6:  20 01                move.l   d1, d0
  009fb8:  c2 fc 00 32          mulu.w   #$32, d1
  009fbc:  48 40                swap     d0
  009fbe:  c0 fc 00 32          mulu.w   #$32, d0
  009fc2:  48 40                swap     d0
  009fc4:  42 40                clr.w    d0
  009fc6:  d2 80                add.l    d0, d1
  009fc8:  20 06                move.l   d6, d0
  009fca:  4c 05 08 00          muls.l   d5, d0
  009fce:  4c 40 18 01          divs.l   d0, d1
  009fd2:  20 6e 00 30          movea.l  $30(a6), a0
  009fd6:  20 81                move.l   d1, (a0)
L9fd8:
  009fd8:  70 00                moveq    #$0, d0
  009fda:  60 00 00 ce          bra.w    $a0aa  ; -> La0aa
L9fde:
  009fde:  59 8f                subq.l   #$4, a7
  009fe0:  2f 2e 00 10          move.l   $10(a6), -(a7)
  009fe4:  70 0d                moveq    #$d, d0
  009fe6:  ab 1d                dc.w     $ab1d
  009fe8:  2d 5f ff f0          move.l   (a7)+, -$10(a6)
  009fec:  55 8f                subq.l   #$2, a7
  009fee:  2f 2e 00 10          move.l   $10(a6), -(a7)
  009ff2:  70 01                moveq    #$1, d0
  009ff4:  ab 1d                dc.w     $ab1d
  009ff6:  59 8f                subq.l   #$4, a7
  009ff8:  2f 2e 00 10          move.l   $10(a6), -(a7)
  009ffc:  70 0f                moveq    #$f, d0
  009ffe:  ab 1d                dc.w     $ab1d
  00a000:  28 5f                movea.l  (a7)+, a4
  00a002:  26 84                move.l   d4, (a3)
  00a004:  27 6e ff 88 00 04    move.l   -$78(a6), $4(a3)
  00a00a:  20 6e 00 08          movea.l  $8(a6), a0
  00a00e:  27 50 00 08          move.l   (a0), $8(a3)
  00a012:  27 6e 00 0c 00 0c    move.l   $c(a6), $c(a3)
  00a018:  20 6e 00 10          movea.l  $10(a6), a0
  00a01c:  27 50 00 10          move.l   (a0), $10(a3)
  00a020:  27 6e 00 14 00 14    move.l   $14(a6), $14(a3)
  00a026:  30 2e 00 1e          move.w   $1e(a6), d0
  00a02a:  48 c0                ext.l    d0
  00a02c:  27 40 00 18          move.l   d0, $18(a3)
  00a030:  27 6e 00 20 00 1c    move.l   $20(a6), $1c(a3)
  00a036:  20 2e ff 9c          move.l   -$64(a6), d0
  00a03a:  d0 8c                add.l    a4, d0
  00a03c:  22 2e ff a0          move.l   -$60(a6), d1
  00a040:  d2 80                add.l    d0, d1
  00a042:  27 41 00 20          move.l   d1, $20(a3)
  00a046:  27 6e ff a4 00 24    move.l   -$5c(a6), $24(a3)
  00a04c:  27 47 00 28          move.l   d7, $28(a3)
  00a050:  27 6e ff f8 00 2c    move.l   -$8(a6), $2c(a3)
  00a056:  70 0c                moveq    #$c, d0
  00a058:  2f 00                move.l   d0, -(a7)
  00a05a:  2f 0b                move.l   a3, -(a7)
  00a05c:  72 39                moveq    #$39, d1
  00a05e:  2f 01                move.l   d1, -(a7)
  00a060:  4e ba c1 c2          jsr      $6224(pc)  ; -> EngineDispatch
  00a064:  70 00                moveq    #$0, d0
  00a066:  10 2e 00 27          move.b   $27(a6), d0
  00a06a:  4f ef 00 0e          lea.l    $e(a7), a7
  00a06e:  66 0a                bne.b    $a07a  ; -> La07a
La070:
  00a070:  4e ba e6 9e          jsr      $8710(pc)  ; -> s7_sub_6e14
  00a074:  72 00                moveq    #$0, d1
  00a076:  12 00                move.b   d0, d1
  00a078:  67 f6                beq.b    $a070  ; -> La070
La07a:
  00a07a:  4a ae ff fc          tst.l    -$4(a6)
  00a07e:  67 08                beq.b    $a088  ; -> La088
  00a080:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  00a084:  4e ba 04 2e          jsr      $a4b4(pc)  ; -> sub_a4b4
La088:
  00a088:  2f 2e 00 10          move.l   $10(a6), -(a7)
  00a08c:  2f 2e ff f0          move.l   -$10(a6), -(a7)
  00a090:  70 0e                moveq    #$e, d0
  00a092:  ab 1d                dc.w     $ab1d
  00a094:  4a ae 00 2c          tst.l    $2c(a6)
  00a098:  67 0e                beq.b    $a0a8  ; -> La0a8
  00a09a:  20 2e 00 18          move.l   $18(a6), d0
  00a09e:  90 ae ff 88          sub.l    -$78(a6), d0
  00a0a2:  20 6e 00 2c          movea.l  $2c(a6), a0
  00a0a6:  20 80                move.l   d0, (a0)
La0a8:
  00a0a8:  70 00                moveq    #$0, d0
La0aa:
  00a0aa:  4c ee 18 f0 ff 68    movem.l  -$98(a6), d4-d7/a3-a4
  00a0b0:  4e 5e                unlk     a6
  00a0b2:  4e 75                rts
sub_a0b4:
  00a0b4:  4e 56 00 00          link.w   a6, #$0
  00a0b8:  2f 0b                move.l   a3, -(a7)
  00a0ba:  26 6e 00 08          movea.l  $8(a6), a3
  00a0be:  20 0b                move.l   a3, d0
  00a0c0:  66 04                bne.b    $a0c6  ; -> La0c6
  00a0c2:  70 ce                moveq    #$ce, d0
  00a0c4:  60 2e                bra.b    $a0f4  ; -> La0f4
La0c6:
  00a0c6:  48 7a 00 34          pea.l    $a0fc(pc)
  00a0ca:  2f 0b                move.l   a3, -(a7)
  00a0cc:  70 13                moveq    #$13, d0
  00a0ce:  2f 00                move.l   d0, -(a7)
  00a0d0:  4e ba 03 ec          jsr      $a4be(pc)  ; -> sub_a4be
  00a0d4:  27 7c 61 70 70 6c 00 a4 move.l   #$6170706c, $a4(a3)
  00a0dc:  70 04                moveq    #$4, d0
  00a0de:  27 40 00 a0          move.l   d0, $a0(a3)
  00a0e2:  27 7c 00 04 30 01 00 a8 move.l   #$43001, $a8(a3)
  00a0ea:  27 7c 00 00 40 09 00 ac move.l   #$4009, $ac(a3)
  00a0f2:  70 00                moveq    #$0, d0
La0f4:
  00a0f4:  26 6e ff fc          movea.l  -$4(a6), a3
  00a0f8:  4e 5e                unlk     a6
  00a0fa:  4e 75                rts
  00a0fc:  11 38 a5 32 34 47 43 20 dc.b     $11, $38, $A5, $32, $34, $47, $43, $20  ; .8.24GC 
  00a104:  52 6f 61 64 20 50 69 7a dc.b     $52, $6F, $61, $64, $20, $50, $69, $7A  ; Road Piz
  00a10c:  7a 61 00 00          dc.b     $7A, $61, $00, $00  ; za..
sub_a110:
  00a110:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00a114:  26 6f 00 10          movea.l  $10(a7), a3
  00a118:  28 4b                movea.l  a3, a4
  00a11a:  30 3c dd 15          move.w   #$dd15, d0
  00a11e:  4c df 18 00          movem.l  (a7)+, a3-a4
  00a122:  4e 75                rts
sub_a124:
  00a124:  70 ff                moveq    #$ff, d0
  00a126:  4e 75                rts
sub_a128:
  00a128:  4e 56 ff fc          link.w   a6, #$fffc
  00a12c:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00a130:  28 6e 00 08          movea.l  $8(a6), a4
  00a134:  4a 94                tst.l    (a4)
  00a136:  66 56                bne.b    $a18e  ; -> La18e
  00a138:  59 8f                subq.l   #$4, a7
  00a13a:  4e ba 02 e8          jsr      $a424(pc)  ; -> sub_a424
  00a13e:  2d 5f ff fc          move.l   (a7)+, -$4(a6)
  00a142:  59 8f                subq.l   #$4, a7
  00a144:  2e b8 02 a6          move.l   $2a6.w, (a7)
  00a148:  4e ba 02 e4          jsr      $a42e(pc)  ; -> sub_a42e
  00a14c:  59 8f                subq.l   #$4, a7
  00a14e:  70 14                moveq    #$14, d0
  00a150:  2f 00                move.l   d0, -(a7)
  00a152:  4e ba 03 08          jsr      $a45c(pc)  ; -> sub_a45c
  00a156:  28 9f                move.l   (a7)+, (a4)
  00a158:  26 54                movea.l  (a4), a3
  00a15a:  59 8f                subq.l   #$4, a7
  00a15c:  a8 d8                dc.w     $a8d8
  00a15e:  20 53                movea.l  (a3), a0
  00a160:  21 5f 00 0c          move.l   (a7)+, $c(a0)
  00a164:  59 8f                subq.l   #$4, a7
  00a166:  a8 d8                dc.w     $a8d8
  00a168:  20 53                movea.l  (a3), a0
  00a16a:  21 5f 00 10          move.l   (a7)+, $10(a0)
  00a16e:  20 53                movea.l  (a3), a0
  00a170:  70 00                moveq    #$0, d0
  00a172:  20 80                move.l   d0, (a0)
  00a174:  20 53                movea.l  (a3), a0
  00a176:  21 40 00 04          move.l   d0, $4(a0)
  00a17a:  20 53                movea.l  (a3), a0
  00a17c:  42 28 00 08          clr.b    $8(a0)
  00a180:  20 53                movea.l  (a3), a0
  00a182:  42 68 00 0a          clr.w    $a(a0)
  00a186:  2f 2e ff fc          move.l   -$4(a6), -(a7)
  00a18a:  4e ba 02 a2          jsr      $a42e(pc)  ; -> sub_a42e
La18e:
  00a18e:  20 14                move.l   (a4), d0
  00a190:  4c ee 18 00 ff f4    movem.l  -$c(a6), a3-a4
  00a196:  4e 5e                unlk     a6
  00a198:  4e 75                rts
sub_a19a:
  00a19a:  48 e7 00 18          movem.l  a3-a4, -(a7)
  00a19e:  28 6f 00 0c          movea.l  $c(a7), a4
  00a1a2:  2f 0c                move.l   a4, -(a7)
  00a1a4:  4e ba ff 82          jsr      $a128(pc)  ; -> sub_a128
  00a1a8:  26 40                movea.l  d0, a3
  00a1aa:  20 0b                move.l   a3, d0
  00a1ac:  58 8f                addq.l   #$4, a7
  00a1ae:  67 16                beq.b    $a1c6  ; -> La1c6
  00a1b0:  20 53                movea.l  (a3), a0
  00a1b2:  2f 28 00 10          move.l   $10(a0), -(a7)
  00a1b6:  a8 d9                dc.w     $a8d9
  00a1b8:  20 53                movea.l  (a3), a0
  00a1ba:  2f 28 00 0c          move.l   $c(a0), -(a7)
  00a1be:  a8 d9                dc.w     $a8d9
  00a1c0:  2f 0b                move.l   a3, -(a7)
  00a1c2:  4e ba 02 a4          jsr      $a468(pc)  ; -> sub_a468
La1c6:
  00a1c6:  70 00                moveq    #$0, d0
  00a1c8:  28 80                move.l   d0, (a4)
  00a1ca:  70 00                moveq    #$0, d0
  00a1cc:  4c df 18 00          movem.l  (a7)+, a3-a4
  00a1d0:  4e 75                rts
sub_a1d2:
  00a1d2:  4e 56 ff e2          link.w   a6, #$ffe2
  00a1d6:  48 e7 0f 18          movem.l  d4-d7/a3-a4, -(a7)
  00a1da:  42 6e ff ec          clr.w    -$14(a6)
  00a1de:  42 6e ff ee          clr.w    -$12(a6)
  00a1e2:  42 6e ff f0          clr.w    -$10(a6)
  00a1e6:  70 08                moveq    #$8, d0
  00a1e8:  90 ae 00 14          sub.l    $14(a6), d0
  00a1ec:  72 01                moveq    #$1, d1
  00a1ee:  e1 a9                lsl.l    d0, d1
  00a1f0:  3d 41 ff f8          move.w   d1, -$8(a6)
  00a1f4:  20 6e 00 10          movea.l  $10(a6), a0
  00a1f8:  2d 50 ff e2          move.l   (a0), -$1e(a6)
  00a1fc:  20 6e 00 0c          movea.l  $c(a6), a0
  00a200:  20 50                movea.l  (a0), a0
  00a202:  49 e8 00 08          lea.l    $8(a0), a4
  00a206:  20 6e 00 08          movea.l  $8(a6), a0
  00a20a:  20 50                movea.l  (a0), a0
  00a20c:  3d 68 00 04 ff f2    move.w   $4(a0), -$e(a6)
  00a212:  30 2e ff f2          move.w   -$e(a6), d0
  00a216:  48 c0                ext.l    d0
  00a218:  72 08                moveq    #$8, d1
  00a21a:  92 80                sub.l    d0, d1
  00a21c:  3d 41 ff fa          move.w   d1, -$6(a6)
  00a220:  20 6e 00 08          movea.l  $8(a6), a0
  00a224:  20 50                movea.l  (a0), a0
  00a226:  5c 88                addq.l   #$6, a0
  00a228:  2d 48 ff e6          move.l   a0, -$1a(a6)
  00a22c:  20 6e 00 08          movea.l  $8(a6), a0
  00a230:  20 50                movea.l  (a0), a0
  00a232:  20 2e ff e2          move.l   -$1e(a6), d0
  00a236:  58 ae ff e2          addq.l   #$4, -$1e(a6)
  00a23a:  22 40                movea.l  d0, a1
  00a23c:  22 90                move.l   (a0), (a1)
  00a23e:  20 2e ff e2          move.l   -$1e(a6), d0
  00a242:  58 ae ff e2          addq.l   #$4, -$1e(a6)
  00a246:  20 40                movea.l  d0, a0
  00a248:  70 00                moveq    #$0, d0
  00a24a:  20 80                move.l   d0, (a0)
La24c:
  00a24c:  42 44                clr.w    d4
  00a24e:  42 45                clr.w    d5
  00a250:  42 46                clr.w    d6
  00a252:  70 00                moveq    #$0, d0
  00a254:  2d 40 ff fc          move.l   d0, -$4(a6)
  00a258:  2d 40 ff f4          move.l   d0, -$c(a6)
  00a25c:  60 00 00 d4          bra.w    $a332  ; -> La332
La260:
  00a260:  d8 6e ff ec          add.w    -$14(a6), d4
  00a264:  da 6e ff f0          add.w    -$10(a6), d5
  00a268:  dc 6e ff ee          add.w    -$12(a6), d6
  00a26c:  4a ae ff f4          tst.l    -$c(a6)
  00a270:  67 48                beq.b    $a2ba  ; -> La2ba
  00a272:  48 c4                ext.l    d4
  00a274:  4a 84                tst.l    d4
  00a276:  6c 04                bge.b    $a27c  ; -> La27c
  00a278:  42 44                clr.w    d4
  00a27a:  60 0e                bra.b    $a28a  ; -> La28a
La27c:
  00a27c:  48 c4                ext.l    d4
  00a27e:  0c 84 00 00 00 ff    cmpi.l   #$ff, d4
  00a284:  6f 04                ble.b    $a28a  ; -> La28a
  00a286:  38 3c 00 ff          move.w   #$ff, d4
La28a:
  00a28a:  48 c6                ext.l    d6
  00a28c:  4a 86                tst.l    d6
  00a28e:  6c 04                bge.b    $a294  ; -> La294
  00a290:  42 46                clr.w    d6
  00a292:  60 0e                bra.b    $a2a2  ; -> La2a2
La294:
  00a294:  48 c6                ext.l    d6
  00a296:  0c 86 00 00 00 ff    cmpi.l   #$ff, d6
  00a29c:  6f 04                ble.b    $a2a2  ; -> La2a2
  00a29e:  3c 3c 00 ff          move.w   #$ff, d6
La2a2:
  00a2a2:  48 c5                ext.l    d5
  00a2a4:  4a 85                tst.l    d5
  00a2a6:  6c 04                bge.b    $a2ac  ; -> La2ac
  00a2a8:  42 45                clr.w    d5
  00a2aa:  60 0e                bra.b    $a2ba  ; -> La2ba
La2ac:
  00a2ac:  48 c5                ext.l    d5
  00a2ae:  0c 85 00 00 00 ff    cmpi.l   #$ff, d5
  00a2b4:  6f 04                ble.b    $a2ba  ; -> La2ba
  00a2b6:  3a 3c 00 ff          move.w   #$ff, d5
La2ba:
  00a2ba:  48 c4                ext.l    d4
  00a2bc:  30 2e ff f2          move.w   -$e(a6), d0
  00a2c0:  2e 04                move.l   d4, d7
  00a2c2:  e1 af                lsl.l    d0, d7
  00a2c4:  02 87 ff ff ff 00    andi.l   #$ffffff00, d7
  00a2ca:  48 c5                ext.l    d5
  00a2cc:  8e 85                or.l     d5, d7
  00a2ce:  30 2e ff f2          move.w   -$e(a6), d0
  00a2d2:  e1 af                lsl.l    d0, d7
  00a2d4:  02 87 ff ff ff 00    andi.l   #$ffffff00, d7
  00a2da:  48 c6                ext.l    d6
  00a2dc:  8e 86                or.l     d6, d7
  00a2de:  30 2e ff fa          move.w   -$6(a6), d0
  00a2e2:  e0 af                lsr.l    d0, d7
  00a2e4:  20 6e ff e6          movea.l  -$1a(a6), a0
  00a2e8:  1d 70 78 00 ff eb    move.b   (a0, d7.l), -$15(a6)
  00a2ee:  20 2e ff fc          move.l   -$4(a6), d0
  00a2f2:  e1 88                lsl.l    #$8, d0
  00a2f4:  72 00                moveq    #$0, d1
  00a2f6:  12 2e ff eb          move.b   -$15(a6), d1
  00a2fa:  82 80                or.l     d0, d1
  00a2fc:  2d 41 ff fc          move.l   d1, -$4(a6)
  00a300:  70 00                moveq    #$0, d0
  00a302:  10 2e ff eb          move.b   -$15(a6), d0
  00a306:  e7 80                asl.l    #$3, d0
  00a308:  47 f4 08 00          lea.l    (a4, d0.l), a3
  00a30c:  70 00                moveq    #$0, d0
  00a30e:  30 2b 00 02          move.w   $2(a3), d0
  00a312:  e0 88                lsr.l    #$8, d0
  00a314:  98 40                sub.w    d0, d4
  00a316:  70 00                moveq    #$0, d0
  00a318:  30 2b 00 04          move.w   $4(a3), d0
  00a31c:  e0 88                lsr.l    #$8, d0
  00a31e:  9a 40                sub.w    d0, d5
  00a320:  70 00                moveq    #$0, d0
  00a322:  30 2b 00 06          move.w   $6(a3), d0
  00a326:  e0 88                lsr.l    #$8, d0
  00a328:  9c 40                sub.w    d0, d6
  00a32a:  20 2e ff f4          move.l   -$c(a6), d0
  00a32e:  52 ae ff f4          addq.l   #$1, -$c(a6)
La332:
  00a332:  70 04                moveq    #$4, d0
  00a334:  b0 ae ff f4          cmp.l    -$c(a6), d0
  00a338:  62 00 ff 26          bhi.w    $a260  ; -> La260
  00a33c:  20 2e ff e2          move.l   -$1e(a6), d0
  00a340:  58 ae ff e2          addq.l   #$4, -$1e(a6)
  00a344:  20 40                movea.l  d0, a0
  00a346:  20 ae ff fc          move.l   -$4(a6), (a0)
  00a34a:  30 2e ff f8          move.w   -$8(a6), d0
  00a34e:  d1 6e ff ee          add.w    d0, -$12(a6)
  00a352:  30 2e ff ee          move.w   -$12(a6), d0
  00a356:  48 c0                ext.l    d0
  00a358:  72 18                moveq    #$18, d1
  00a35a:  c2 80                and.l    d0, d1
  00a35c:  66 08                bne.b    $a366  ; -> La366
  00a35e:  30 2e ff ee          move.w   -$12(a6), d0
  00a362:  52 6e ff ee          addq.w   #$1, -$12(a6)
La366:
  00a366:  30 2e ff ee          move.w   -$12(a6), d0
  00a36a:  48 c0                ext.l    d0
  00a36c:  0c 80 00 00 00 ff    cmpi.l   #$ff, d0
  00a372:  6f 00 fe d8          ble.w    $a24c  ; -> La24c
  00a376:  42 6e ff ee          clr.w    -$12(a6)
  00a37a:  30 2e ff f8          move.w   -$8(a6), d0
  00a37e:  d1 6e ff f0          add.w    d0, -$10(a6)
  00a382:  30 2e ff f0          move.w   -$10(a6), d0
  00a386:  48 c0                ext.l    d0
  00a388:  72 18                moveq    #$18, d1
  00a38a:  c2 80                and.l    d0, d1
  00a38c:  66 08                bne.b    $a396  ; -> La396
  00a38e:  30 2e ff f0          move.w   -$10(a6), d0
  00a392:  52 6e ff f0          addq.w   #$1, -$10(a6)
La396:
  00a396:  30 2e ff f0          move.w   -$10(a6), d0
  00a39a:  48 c0                ext.l    d0
  00a39c:  0c 80 00 00 00 ff    cmpi.l   #$ff, d0
  00a3a2:  6f 00 fe a8          ble.w    $a24c  ; -> La24c
  00a3a6:  42 6e ff f0          clr.w    -$10(a6)
  00a3aa:  30 2e ff f8          move.w   -$8(a6), d0
  00a3ae:  d1 6e ff ec          add.w    d0, -$14(a6)
  00a3b2:  30 2e ff ec          move.w   -$14(a6), d0
  00a3b6:  48 c0                ext.l    d0
  00a3b8:  72 18                moveq    #$18, d1
  00a3ba:  c2 80                and.l    d0, d1
  00a3bc:  66 08                bne.b    $a3c6  ; -> La3c6
  00a3be:  30 2e ff ec          move.w   -$14(a6), d0
  00a3c2:  52 6e ff ec          addq.w   #$1, -$14(a6)
La3c6:
  00a3c6:  30 2e ff ec          move.w   -$14(a6), d0
  00a3ca:  48 c0                ext.l    d0
  00a3cc:  0c 80 00 00 00 ff    cmpi.l   #$ff, d0
  00a3d2:  6f 00 fe 78          ble.w    $a24c  ; -> La24c
  00a3d6:  4c ee 18 f0 ff ca    movem.l  -$36(a6), d4-d7/a3-a4
  00a3dc:  4e 5e                unlk     a6
  00a3de:  4e 75                rts
La3e0:
  00a3e0:  22 1f                move.l   (a7)+, d1
  00a3e2:  22 5f                movea.l  (a7)+, a1
  00a3e4:  20 5f                movea.l  (a7)+, a0
  00a3e6:  a0 5c                dc.w     $a05c
  00a3e8:  3e 80                move.w   d0, (a7)
  00a3ea:  22 41                movea.l  d1, a1
  00a3ec:  4e d1                jmp      (a1)
La3ee:
  00a3ee:  22 1f                move.l   (a7)+, d1
  00a3f0:  22 5f                movea.l  (a7)+, a1
  00a3f2:  20 5f                movea.l  (a7)+, a0
  00a3f4:  a0 8d                dc.w     $a08d
  00a3f6:  3e 80                move.w   d0, (a7)
  00a3f8:  22 41                movea.l  d1, a1
  00a3fa:  4e d1                jmp      (a1)
sub_a3fc:
  00a3fc:  70 00                moveq    #$0, d0
  00a3fe:  60 e0                bra.b    $a3e0  ; -> La3e0
sub_a400:
  00a400:  70 01                moveq    #$1, d0
  00a402:  60 dc                bra.b    $a3e0  ; -> La3e0
sub_a404:
  00a404:  70 02                moveq    #$2, d0
  00a406:  60 d8                bra.b    $a3e0  ; -> La3e0
sub_a408:
  00a408:  70 03                moveq    #$3, d0
  00a40a:  60 d4                bra.b    $a3e0  ; -> La3e0
* s7_sub_c264  -  System 7 $C264 (identical code).
s7_sub_c264:
  00a40c:  22 1f                move.l   (a7)+, d1
  00a40e:  24 1f                move.l   (a7)+, d2
  00a410:  22 42                movea.l  d2, a1
  00a412:  22 51                movea.l  (a1), a1
  00a414:  20 5f                movea.l  (a7)+, a0
  00a416:  70 05                moveq    #$5, d0
  00a418:  a1 5c                dc.w     $a15c
  00a41a:  3e 80                move.w   d0, (a7)
  00a41c:  22 42                movea.l  d2, a1
  00a41e:  22 88                move.l   a0, (a1)
  00a420:  22 41                movea.l  d1, a1
  00a422:  4e d1                jmp      (a1)
sub_a424:
  00a424:  a1 1a                dc.w     $a11a
  00a426:  2f 48 00 04          move.l   a0, $4(a7)
  00a42a:  4e fa 00 1a          jmp      $a446(pc)  ; -> La446
sub_a42e:
  00a42e:  22 5f                movea.l  (a7)+, a1
  00a430:  20 5f                movea.l  (a7)+, a0
  00a432:  a0 1b                dc.w     $a01b
  00a434:  4e fa 00 0e          jmp      $a444(pc)  ; -> La444
La438:
  00a438:  22 5f                movea.l  (a7)+, a1
  00a43a:  20 1f                move.l   (a7)+, d0
  00a43c:  a0 4c                dc.w     $a04c
  00a43e:  2e 80                move.l   d0, (a7)
  00a440:  4e 71                nop
La442:
  00a442:  70 00                moveq    #$0, d0
La444:
  00a444:  2f 09                move.l   a1, -(a7)
La446:
  00a446:  31 c0 02 20          move.w   d0, $220.w
  00a44a:  4e 75                rts
La44c:
  00a44c:  70 00                moveq    #$0, d0
  00a44e:  60 f6                bra.b    $a446  ; -> La446
sub_a450:
  00a450:  22 5f                movea.l  (a7)+, a1
  00a452:  20 1f                move.l   (a7)+, d0
  00a454:  a1 1e                dc.w     $a11e
  00a456:  2e 88                move.l   a0, (a7)
  00a458:  4e fa ff ea          jmp      $a444(pc)  ; -> La444
sub_a45c:
  00a45c:  22 5f                movea.l  (a7)+, a1
  00a45e:  20 1f                move.l   (a7)+, d0
  00a460:  a1 22                dc.w     $a122
  00a462:  2e 88                move.l   a0, (a7)
  00a464:  4e fa ff de          jmp      $a444(pc)  ; -> La444
sub_a468:
  00a468:  22 5f                movea.l  (a7)+, a1
  00a46a:  20 5f                movea.l  (a7)+, a0
  00a46c:  a0 23                dc.w     $a023
  00a46e:  4e fa ff d4          jmp      $a444(pc)  ; -> La444
* s7_sub_bfde  -  System 7 $BFDE (similar code, r=0.80).
s7_sub_bfde:
  00a472:  22 5f                movea.l  (a7)+, a1
  00a474:  20 5f                movea.l  (a7)+, a0
  00a476:  a0 25                dc.w     $a025
  00a478:  2e 80                move.l   d0, (a7)
  00a47a:  6a 06                bpl.b    $a482  ; -> La482
  00a47c:  42 97                clr.l    (a7)
  00a47e:  4e fa ff c4          jmp      $a444(pc)  ; -> La444
La482:
  00a482:  4e fa ff be          jmp      $a442(pc)  ; -> La442
sub_a486:
  00a486:  22 5f                movea.l  (a7)+, a1
  00a488:  20 1f                move.l   (a7)+, d0
  00a48a:  20 5f                movea.l  (a7)+, a0
  00a48c:  a0 24                dc.w     $a024
  00a48e:  4e fa ff b4          jmp      $a444(pc)  ; -> La444
sub_a492:
  00a492:  22 5f                movea.l  (a7)+, a1
  00a494:  20 5f                movea.l  (a7)+, a0
  00a496:  a1 28                dc.w     $a128
  00a498:  2e 88                move.l   a0, (a7)
  00a49a:  4e fa ff a6          jmp      $a442(pc)  ; -> La442
sub_a49e:
  00a49e:  22 5f                movea.l  (a7)+, a1
  00a4a0:  20 1f                move.l   (a7)+, d0
  00a4a2:  20 5f                movea.l  (a7)+, a0
  00a4a4:  a0 27                dc.w     $a027
  00a4a6:  4e fa ff 9c          jmp      $a444(pc)  ; -> La444
sub_a4aa:
  00a4aa:  22 5f                movea.l  (a7)+, a1
  00a4ac:  20 5f                movea.l  (a7)+, a0
  00a4ae:  a0 29                dc.w     $a029
  00a4b0:  4e fa ff 92          jmp      $a444(pc)  ; -> La444
sub_a4b4:
  00a4b4:  22 5f                movea.l  (a7)+, a1
  00a4b6:  20 5f                movea.l  (a7)+, a0
  00a4b8:  a0 2a                dc.w     $a02a
  00a4ba:  4e fa ff 88          jmp      $a444(pc)  ; -> La444
sub_a4be:
  00a4be:  22 1f                move.l   (a7)+, d1
  00a4c0:  20 1f                move.l   (a7)+, d0
  00a4c2:  22 5f                movea.l  (a7)+, a1
  00a4c4:  20 5f                movea.l  (a7)+, a0
  00a4c6:  a0 2e                dc.w     $a02e
  00a4c8:  22 41                movea.l  d1, a1
  00a4ca:  4e fa ff 78          jmp      $a444(pc)  ; -> La444
* s7_sub_b14e  -  System 7 $B14E (checked by hand, r=0.29).
s7_sub_b14e:
  00a4ce:  4e 56 00 00          link.w   a6, #$0
  00a4d2:  20 6e 00 10          movea.l  $10(a6), a0
  00a4d6:  22 6e 00 0c          movea.l  $c(a6), a1
  00a4da:  70 00                moveq    #$0, d0
  00a4dc:  10 18                move.b   (a0)+, d0
  00a4de:  48 40                swap     d0
  00a4e0:  10 19                move.b   (a1)+, d0
  00a4e2:  4a 2e 00 08          tst.b    $8(a6)
  00a4e6:  67 0e                beq.b    $a4f6  ; -> La4f6
  00a4e8:  4a 2e 00 0a          tst.b    $a(a6)
  00a4ec:  67 04                beq.b    $a4f2  ; -> La4f2
  00a4ee:  a4 3c                dc.w     $a43c
  00a4f0:  60 10                bra.b    $a502  ; -> La502
La4f2:
  00a4f2:  a0 3c                dc.w     $a03c
  00a4f4:  60 0c                bra.b    $a502  ; -> La502
La4f6:
  00a4f6:  4a 2e 00 0a          tst.b    $a(a6)
  00a4fa:  67 04                beq.b    $a500  ; -> La500
  00a4fc:  a6 3c                dc.w     $a63c
  00a4fe:  60 02                bra.b    $a502  ; -> La502
La500:
  00a500:  a2 3c                dc.w     $a23c
La502:
  00a502:  0a 00 00 01          eori.b   #$1, d0
  00a506:  1d 40 00 14          move.b   d0, $14(a6)
  00a50a:  4e 5e                unlk     a6
  00a50c:  20 5f                movea.l  (a7)+, a0
  00a50e:  de fc 00 0c          adda.w   #$c, a7
  00a512:  4e d0                jmp      (a0)
sub_a514:
  00a514:  22 5f                movea.l  (a7)+, a1
  00a516:  20 5f                movea.l  (a7)+, a0
  00a518:  a0 69                dc.w     $a069
  00a51a:  1e 80                move.b   d0, (a7)
  00a51c:  4e d1                jmp      (a1)
sub_a51e:
  00a51e:  20 6f 00 04          movea.l  $4(a7), a0
  00a522:  10 10                move.b   (a0), d0
  00a524:  a0 5d                dc.w     $a05d
  00a526:  20 6f 00 04          movea.l  $4(a7), a0
  00a52a:  10 80                move.b   d0, (a0)
  00a52c:  20 5f                movea.l  (a7)+, a0
  00a52e:  58 4f                addq.w   #$4, a7
  00a530:  4e d0                jmp      (a0)
* HWPrivProbe  -  System 7 $C01A (identical code).
* S7: HWPrivProbe(enable)  -  _HWPriv selector 2 = SwapDataCache: turns the
HWPrivProbe:
  00a532:  22 5f                movea.l  (a7)+, a1
  00a534:  70 00                moveq    #$0, d0
  00a536:  10 1f                move.b   (a7)+, d0
  00a538:  20 40                movea.l  d0, a0
  00a53a:  30 3c 00 02          move.w   #$2, d0
  00a53e:  a1 98                dc.w     $a198
  00a540:  30 08                move.w   a0, d0
  00a542:  4a 40                tst.w    d0
  00a544:  67 02                beq.b    $a548  ; -> La548
  00a546:  70 01                moveq    #$1, d0
La548:
  00a548:  1e 80                move.b   d0, (a7)
  00a54a:  4e d1                jmp      (a1)
sub_a54c:
  00a54c:  20 2f 00 08          move.l   $8(a7), d0
  00a550:  a1 ad                dc.w     $a1ad
  00a552:  22 6f 00 04          movea.l  $4(a7), a1
  00a556:  22 88                move.l   a0, (a1)
  00a558:  3f 40 00 0c          move.w   d0, $c(a7)
  00a55c:  20 5f                movea.l  (a7)+, a0
  00a55e:  50 8f                addq.l   #$8, a7
  00a560:  4e d0                jmp      (a0)
sub_a562:
  00a562:  22 5f                movea.l  (a7)+, a1
  00a564:  20 5f                movea.l  (a7)+, a0
  00a566:  70 01                moveq    #$1, d0
  00a568:  a0 6e                dc.w     $a06e
  00a56a:  3e 80                move.w   d0, (a7)
  00a56c:  4e d1                jmp      (a1)
sub_a56e:
  00a56e:  22 5f                movea.l  (a7)+, a1
  00a570:  20 5f                movea.l  (a7)+, a0
  00a572:  70 02                moveq    #$2, d0
  00a574:  a0 6e                dc.w     $a06e
  00a576:  3e 80                move.w   d0, (a7)
  00a578:  4e d1                jmp      (a1)
sub_a57a:
  00a57a:  22 5f                movea.l  (a7)+, a1
  00a57c:  20 5f                movea.l  (a7)+, a0
  00a57e:  70 03                moveq    #$3, d0
  00a580:  a0 6e                dc.w     $a06e
  00a582:  3e 80                move.w   d0, (a7)
  00a584:  4e d1                jmp      (a1)
sub_a586:
  00a586:  22 5f                movea.l  (a7)+, a1
  00a588:  20 5f                movea.l  (a7)+, a0
  00a58a:  70 06                moveq    #$6, d0
  00a58c:  a0 6e                dc.w     $a06e
  00a58e:  3e 80                move.w   d0, (a7)
  00a590:  4e d1                jmp      (a1)
sub_a592:
  00a592:  22 5f                movea.l  (a7)+, a1
  00a594:  20 5f                movea.l  (a7)+, a0
  00a596:  70 15                moveq    #$15, d0
  00a598:  a0 6e                dc.w     $a06e
  00a59a:  3e 80                move.w   d0, (a7)
  00a59c:  4e d1                jmp      (a1)
sub_a59e:
  00a59e:  4a 78 02 8e          tst.w    $28e.w
  00a5a2:  6b 1c                bmi.b    $a5c0  ; -> La5c0
  00a5a4:  30 3c a8 9f          move.w   #$a89f, d0
  00a5a8:  a3 46                dc.w     $a346
  00a5aa:  22 48                movea.l  a0, a1
  00a5ac:  30 3c a0 55          move.w   #$a055, d0
  00a5b0:  a3 46                dc.w     $a346
  00a5b2:  b3 c8                cmpa.l   a0, a1
  00a5b4:  67 0a                beq.b    $a5c0  ; -> La5c0
  00a5b6:  22 5f                movea.l  (a7)+, a1
  00a5b8:  20 1f                move.l   (a7)+, d0
  00a5ba:  a0 55                dc.w     $a055
  00a5bc:  2e 80                move.l   d0, (a7)
  00a5be:  4e d1                jmp      (a1)
La5c0:
  00a5c0:  22 5f                movea.l  (a7)+, a1
  00a5c2:  20 1f                move.l   (a7)+, d0
  00a5c4:  c0 b8 03 1a          and.l    $31a.w, d0
  00a5c8:  2e 80                move.l   d0, (a7)
  00a5ca:  4e d1                jmp      (a1)
