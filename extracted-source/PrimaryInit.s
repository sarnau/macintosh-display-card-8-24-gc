* ==========================================================================
*  PrimaryInit
*  Macintosh Display Card 8*24 GC  --  NuBus declaration ROM (Apple 341-0812)
*  Reconstructed 68020 assembly (MPW-style) from ROM image 341-0812.bin.
*  Comments/labels added by static analysis; mnemonics are literal.
* ==========================================================================
*
*  Called once by the Slot Manager at boot (sPrimaryInit, sExecBlock at
*  ROM+$2098, 68020, rev 2).  Registers on entry:
*     A0 = pointer to the SEBlock (Slot Manager sExec parameter block).
*          Fields (Slots.p / Slots.h from the System 7.1 source):
*            $00 seSlot     $01 sesRsrcId  $02 seStatus  $04 seFlags
*            $08 seResult   $0C seIOFileName             $10 seDevice ...
*          seSlot (byte 0) is the slot number, used to build the slot base
*          address F<s>00'0000.  A6/A4 in the sensing loop = slot base.
*
*     A stack-allocated SpBlock ($38 bytes; suba.w #$38,a7 ; movea.l a7,a0)
*     is used for Slot Manager calls (sReadPRAMRec/sPutPRAMRec/
*     sSetSRsrcState).  While A0 points into that frame the accesses below
*     are tagged [sp*]; before that, [se*].  SpBlock fields:
*       $00 spResult    $04 spsPointer  $08 spSize      $0C spOffsetData
*       $10 spIOFileName $14 spsExecPBlk $18 spParamData $1C spMisc
*       $24 spIOReserved $26 spRefNum   $28 spCategory  $2A spCType
*       $2C spDrvrSW    $2E spDrvrHW   $30 spTBMask    $31 spSlot
*       $32 spID        $33 spExtDev   $34 spHwDev     $35 spByteLanes
*       $36 spFlags     $37 spKey
*  It initialises the card's control registers (MFB / RDNC / AC842) which
*  live in super-slot space at base + $0400'00xx, senses the attached
*  monitor via the three SENSE lines (register offsets $44/$48/$4C), and
*  leaves the board ready for the Slot Manager to install its sResources.
*
* ==================================================================
* PrimaryInit  -  sExecBlock run once by the Slot Manager at boot
* ==================================================================
* Entry: A0 = seBlock; byte 0 = slot number.  Brings the board out of
* reset, senses the attached monitor, programs the pixel clock for it,
* and enables exactly the sResources that match the monitor + depth.
*
* A1/A4 = slot base F<s>00'0000 (super-slot space).  Card registers are
* reached at base + $0400'00xx etc. after _SwapMMUMode to 32-bit mode.
PrimaryInit:
  0020a4:  31 7c 00 01 00 02    move.w   #$1, $2(a0)  ; [seStatus] 1 (assume failure until the end)
  0020aa:  72 00                moveq    #$0, d1
  0020ac:  10 10                move.b   (a0), d0  ; [seSlot] D0 = slot number (seBlock byte 0)
  0020ae:  ef c1 00 04          bfins    d0, d1{0:4}
  0020b2:  22 41                movea.l  d1, a1  ; A1 = slot base F<s>00'0000
  0020b4:  26 00                move.l   d0, d3
  0020b6:  70 01                moveq    #$1, d0
  0020b8:  a0 5d                dc.w     $a05d  ; _SwapMMUMode ->32-bit mode  enter 32-bit addressing to reach super-slot space
  0020ba:  28 49                movea.l  a1, a4
* Reset the MFB / control registers to a known state
* (clear most, set a few masks to $FFFFFFFF).
  0020bc:  28 3c 04 00 00 08    move.l   #$4000008, d4  ; MFB reg +$08
  0020c2:  74 04                moveq    #$4, d2
  0020c4:  72 0a                moveq    #$a, d1
  0020c6:  4e ba 07 b8          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0020ca:  72 0a                moveq    #$a, d1
  0020cc:  4e ba 07 b2          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0020d0:  72 0a                moveq    #$a, d1
  0020d2:  4e ba 07 ac          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0020d6:  72 0a                moveq    #$a, d1
  0020d8:  4e ba 07 a6          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0020dc:  28 3c 04 00 00 2c    move.l   #$400002c, d4  ; MFB reg +$2c
  0020e2:  42 b4 48 00          clr.l    (a4, d4.l)
  0020e6:  28 3c 04 00 00 30    move.l   #$4000030, d4  ; MFB reg +$30
  0020ec:  42 b4 48 00          clr.l    (a4, d4.l)
  0020f0:  28 3c 04 00 00 34    move.l   #$4000034, d4  ; MFB reg +$34
  0020f6:  42 b4 48 00          clr.l    (a4, d4.l)
  0020fa:  28 3c 04 00 00 38    move.l   #$4000038, d4  ; MFB reg +$38
  002100:  42 b4 48 00          clr.l    (a4, d4.l)
  002104:  28 3c 04 00 00 3c    move.l   #$400003c, d4  ; MFB reg +$3c
  00210a:  42 b4 48 00          clr.l    (a4, d4.l)
  00210e:  28 3c 04 00 00 40    move.l   #$4000040, d4  ; MFB reg +$40
  002114:  42 b4 48 00          clr.l    (a4, d4.l)
  002118:  28 3c 04 00 00 78    move.l   #$4000078, d4  ; MFB reg +$78
  00211e:  42 b4 48 00          clr.l    (a4, d4.l)
  002122:  28 3c 04 00 00 bc    move.l   #$40000bc, d4  ; MFB reg +$bc
  002128:  29 bc ff ff ff ff 48 00 move.l   #$ffffffff, (a4, d4.l)
  002130:  28 3c 04 00 00 90    move.l   #$4000090, d4  ; MFB reg +$90
  002136:  29 bc ff ff ff ff 48 00 move.l   #$ffffffff, (a4, d4.l)
  00213e:  28 3c 04 00 00 84    move.l   #$4000084, d4  ; MFB reg +$84
  002144:  29 bc ff ff ff ff 48 00 move.l   #$ffffffff, (a4, d4.l)
  00214c:  28 3c 04 00 00 1c    move.l   #$400001c, d4  ; MFB reg +$1c
  002152:  29 bc ff ff ff ff 48 00 move.l   #$ffffffff, (a4, d4.l)
  00215a:  28 3c 04 00 00 20    move.l   #$4000020, d4  ; MFB reg +$20
  002160:  29 bc ff ff ff ff 48 00 move.l   #$ffffffff, (a4, d4.l)
  002168:  28 3c 04 00 00 24    move.l   #$4000024, d4  ; MFB reg +$24
  00216e:  29 bc ff ff ff ff 48 00 move.l   #$ffffffff, (a4, d4.l)
  002176:  28 3c 04 00 00 28    move.l   #$4000028, d4  ; MFB reg +$28
  00217c:  42 b4 48 00          clr.l    (a4, d4.l)
  002180:  28 3c 04 00 00 a8    move.l   #$40000a8, d4  ; MFB reg +$a8
  002186:  42 b4 48 00          clr.l    (a4, d4.l)
  00218a:  28 3c 04 00 00 ac    move.l   #$40000ac, d4  ; MFB reg +$ac
  002190:  29 bc ff ff ff ff 48 00 move.l   #$ffffffff, (a4, d4.l)
  002198:  28 3c 04 00 00 b8    move.l   #$40000b8, d4  ; MFB reg +$b8
  00219e:  29 bc ff ff ff ff 48 00 move.l   #$ffffffff, (a4, d4.l)
  0021a6:  28 3c 04 00 00 c0    move.l   #$40000c0, d4  ; MFB reg +$c0
  0021ac:  42 b4 48 00          clr.l    (a4, d4.l)
  0021b0:  28 3c 04 00 00 c4    move.l   #$40000c4, d4  ; MFB reg +$c4
  0021b6:  42 b4 48 00          clr.l    (a4, d4.l)
  0021ba:  a0 5d                dc.w     $a05d  ; _SwapMMUMode  back to previous addressing mode
* Read this slot's saved video mode from PRAM and read the monitor
* sense lines, so the saved mode can be checked against what is plugged in.
  0021bc:  20 03                move.l   d3, d0
  0021be:  9e fc 00 38          suba.w   #$38, a7
  0021c2:  20 4f                movea.l  a7, a0
  0021c4:  11 40 00 31          move.b   d0, $31(a0)  ; [spSlot]
  0021c8:  42 28 00 33          clr.b    $33(a0)  ; [spExtDev]
  0021cc:  42 06                clr.b    d6
  0021ce:  70 08                moveq    #$8, d0
  0021d0:  a0 6e                dc.w     $a06e  ; _SlotManager selector=sVersion
  0021d2:  56 c6                sne.b    d6
  0021d4:  70 01                moveq    #$1, d0
  0021d6:  a0 5d                dc.w     $a05d  ; _SwapMMUMode ->32-bit mode
  0021d8:  2f 00                move.l   d0, -(a7)
  0021da:  28 49                movea.l  a1, a4
  0021dc:  72 00                moveq    #$0, d1
  0021de:  28 3c 04 00 00 44    move.l   #$4000044, d4  ; MFB reg +$44 (SENSE line 0)
  0021e4:  e9 f4 20 01 48 00    bfextu   (a4, d4.l){0:1}, d2
  0021ea:  e5 4a                lsl.w    #$2, d2
  0021ec:  d2 82                add.l    d2, d1
  0021ee:  28 3c 04 00 00 48    move.l   #$4000048, d4  ; MFB reg +$48 (SENSE line 1)
  0021f4:  e9 f4 20 01 48 00    bfextu   (a4, d4.l){0:1}, d2
  0021fa:  e3 4a                lsl.w    #$1, d2
  0021fc:  d2 82                add.l    d2, d1
  0021fe:  28 3c 04 00 00 4c    move.l   #$400004c, d4  ; MFB reg +$4c (SENSE line 2)
  002204:  e9 f4 20 01 48 00    bfextu   (a4, d4.l){0:1}, d2
  00220a:  d2 82                add.l    d2, d1
  00220c:  0c 01 00 07          cmpi.b   #$7, d1
  002210:  66 20                bne.b    $2232  ; -> L2232
  002212:  4e ba 06 9c          jsr      $28b0(pc)  ; -> sub_28b0
  002216:  0c 00 00 14          cmpi.b   #$14, d0
  00221a:  66 06                bne.b    $2222  ; -> L2222
  00221c:  12 3c 00 04          move.b   #$4, d1
  002220:  60 1a                bra.b    $223c  ; -> L223c
L2222:
  002222:  0c 00 00 00          cmpi.b   #$0, d0
  002226:  66 04                bne.b    $222c  ; -> L222c
  002228:  42 01                clr.b    d1
  00222a:  60 10                bra.b    $223c  ; -> L223c
L222c:
  00222c:  12 3c 00 09          move.b   #$9, d1
  002230:  60 0a                bra.b    $223c  ; -> L223c
L2232:
  002232:  0c 01 00 00          cmpi.b   #$0, d1
  002236:  66 04                bne.b    $223c  ; -> L223c
  002238:  12 3c 00 07          move.b   #$7, d1
L223c:
  00223c:  20 1f                move.l   (a7)+, d0
  00223e:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  002240:  0c 01 00 09          cmpi.b   #$9, d1
  002244:  67 00 04 76          beq.w    $26bc  ; -> L26bc
* Reconcile saved-mode vs. sensed-monitor; rewrite PRAM if they
* disagree (Slot Manager sReadPRAMRec/sPutPRAMRec).
  002248:  28 01                move.l   d1, d4
  00224a:  2a 04                move.l   d4, d5
  00224c:  16 3c 00 f0          move.b   #$f0, d3
  002250:  51 4f                subq.w   #$8, a7
  002252:  20 8f                move.l   a7, (a0)  ; [spResult]
  002254:  70 11                moveq    #$11, d0
  002256:  a0 6e                dc.w     $a06e  ; _SlotManager selector=0x11
  002258:  12 2f 00 03          move.b   $3(a7), d1
  00225c:  10 01                move.b   d1, d0
  00225e:  02 40 00 07          andi.w   #$7, d0
  002262:  51 c2                sf.b     d2
  002264:  b0 04                cmp.b    d4, d0
  002266:  67 04                beq.b    $226c  ; -> L226c
  002268:  50 c2                st.b     d2
  00226a:  60 1e                bra.b    $228a  ; -> L228a
L226c:
  00226c:  0c 04 00 04          cmpi.b   #$4, d4
  002270:  67 06                beq.b    $2278  ; -> L2278
  002272:  0c 04 00 00          cmpi.b   #$0, d4
  002276:  66 12                bne.b    $228a  ; -> L228a
L2278:
  002278:  08 01 00 03          btst.b   #$3, d1
  00227c:  67 04                beq.b    $2282  ; -> L2282
  00227e:  08 c4 00 03          bset.b   #$3, d4
L2282:
  002282:  b2 2f 00 04          cmp.b    $4(a7), d1
  002286:  67 02                beq.b    $228a  ; -> L228a
  002288:  50 c2                st.b     d2
L228a:
  00228a:  08 c4 00 05          bset.b   #$5, d4
  00228e:  08 c4 00 07          bset.b   #$7, d4
  002292:  4a 06                tst.b    d6
  002294:  67 06                beq.b    $229c  ; -> L229c
  002296:  08 c4 00 04          bset.b   #$4, d4
  00229a:  60 06                bra.b    $22a2  ; -> L22a2
L229c:
  00229c:  16 04                move.b   d4, d3
  00229e:  08 43 00 03          bchg.b   #$3, d3
L22a2:
  0022a2:  4a 02                tst.b    d2
  0022a4:  67 16                beq.b    $22bc  ; -> L22bc
  0022a6:  1f 44 00 03          move.b   d4, $3(a7)
  0022aa:  1f 44 00 04          move.b   d4, $4(a7)
  0022ae:  1f 7c 00 80 00 05    move.b   #$80, $5(a7)
  0022b4:  21 50 00 04          move.l   (a0), $4(a0)  ; [spResult]
  0022b8:  70 12                moveq    #$12, d0
  0022ba:  a0 6e                dc.w     $a06e  ; _SlotManager selector=0x12
L22bc:
  0022bc:  50 4f                addq.w   #$8, a7
  0022be:  70 01                moveq    #$1, d0
  0022c0:  a0 5d                dc.w     $a05d  ; _SwapMMUMode ->32-bit mode
  0022c2:  2f 04                move.l   d4, -(a7)
  0022c4:  08 05 00 00          btst.b   #$0, d5
  0022c8:  67 04                beq.b    $22ce  ; -> L22ce
  0022ca:  08 85 00 02          bclr.b   #$2, d5
* Program the pixel-clock synthesiser and AC842 through the serial
* port with the base coefficients, reading back the AC842 id ($06000000)
* to pick the right coefficient set.
L22ce:
  0022ce:  28 49                movea.l  a1, a4
  0022d0:  28 3c 04 80 00 00    move.l   #$4800000, d4  ; clock-synth serial port
  0022d6:  72 00                moveq    #$0, d1
  0022d8:  74 01                moveq    #$1, d2
  0022da:  4e ba 05 a4          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0022de:  22 3c 00 00 09 98    move.l   #$998, d1
  0022e4:  74 0c                moveq    #$c, d2
  0022e6:  4e ba 05 98          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0022ea:  22 3c 00 00 8b 88    move.l   #$8b88, d1
  0022f0:  74 10                moveq    #$10, d2
  0022f2:  4e ba 05 8c          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0022f6:  22 3c 00 00 aa ad    move.l   #$aaad, d1
  0022fc:  74 10                moveq    #$10, d2
  0022fe:  4e ba 05 80          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002302:  24 3c 06 00 00 00    move.l   #$6000000, d2  ; AC842 space +$0
  002308:  22 34 28 00          move.l   (a4, d2.l), d1  ; read AC842 id register
  00230c:  02 41 f0 00          andi.w   #$f000, d1
  002310:  0c 41 10 00          cmpi.w   #$1000, d1
  002314:  67 3a                beq.b    $2350  ; -> L2350  branch on AC842 revision
  002316:  22 3c 00 00 9a cc    move.l   #$9acc, d1
  00231c:  74 10                moveq    #$10, d2
  00231e:  4e ba 05 60          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002322:  22 3c 00 00 8a 9c    move.l   #$8a9c, d1
  002328:  74 10                moveq    #$10, d2
  00232a:  4e ba 05 54          jsr      $2880(pc)  ; -> SerialShiftOutReg
  00232e:  22 3c 00 88 ac ac    move.l   #$88acac, d1
  002334:  74 18                moveq    #$18, d2
  002336:  4e ba 05 48          jsr      $2880(pc)  ; -> SerialShiftOutReg
  00233a:  72 53                moveq    #$53, d1
  00233c:  74 0c                moveq    #$c, d2
  00233e:  4e ba 05 40          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002342:  22 3c 00 02 40 5b    move.l   #$2405b, d1
  002348:  74 12                moveq    #$12, d2
  00234a:  4e ba 05 34          jsr      $2880(pc)  ; -> SerialShiftOutReg
  00234e:  60 3c                bra.b    $238c  ; -> L238c
L2350:
  002350:  22 3c 00 00 9b cc    move.l   #$9bcc, d1
  002356:  74 10                moveq    #$10, d2
  002358:  4e ba 05 26          jsr      $2880(pc)  ; -> SerialShiftOutReg
  00235c:  22 3c 00 00 8a 9c    move.l   #$8a9c, d1
  002362:  74 10                moveq    #$10, d2
  002364:  4e ba 05 1a          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002368:  22 3c 00 88 ac bc    move.l   #$88acbc, d1
  00236e:  74 18                moveq    #$18, d2
  002370:  4e ba 05 0e          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002374:  22 3c 00 00 00 93    move.l   #$93, d1
  00237a:  74 0c                moveq    #$c, d2
  00237c:  4e ba 05 02          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002380:  22 3c 00 02 40 9b    move.l   #$2409b, d1
  002386:  74 12                moveq    #$12, d2
  002388:  4e ba 04 f6          jsr      $2880(pc)  ; -> SerialShiftOutReg
* Add the per-monitor pixel-clock timing (branch on monitor code D5:
* 1/2/3/6 = specific monitors, else the default 640x480 timing).
L238c:
  00238c:  0c 05 00 02          cmpi.b   #$2, d5
  002390:  67 24                beq.b    $23b6  ; -> L23b6
  002392:  0c 05 00 03          cmpi.b   #$3, d5
  002396:  67 30                beq.b    $23c8  ; -> L23c8
  002398:  0c 05 00 01          cmpi.b   #$1, d5
  00239c:  67 4a                beq.b    $23e8  ; -> L23e8
  00239e:  0c 05 00 06          cmpi.b   #$6, d5
  0023a2:  67 56                beq.b    $23fa  ; -> L23fa
  0023a4:  72 02                moveq    #$2, d1
  0023a6:  74 04                moveq    #$4, d2
  0023a8:  4e ba 04 d6          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0023ac:  72 01                moveq    #$1, d1
  0023ae:  74 02                moveq    #$2, d2
  0023b0:  4e ba 04 ce          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0023b4:  60 54                bra.b    $240a  ; -> L240a
L23b6:
  0023b6:  72 02                moveq    #$2, d1
  0023b8:  74 04                moveq    #$4, d2
  0023ba:  4e ba 04 c4          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0023be:  72 01                moveq    #$1, d1
  0023c0:  74 02                moveq    #$2, d2
  0023c2:  4e ba 04 bc          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0023c6:  60 42                bra.b    $240a  ; -> L240a
L23c8:
  0023c8:  72 01                moveq    #$1, d1
  0023ca:  74 04                moveq    #$4, d2
  0023cc:  4e ba 04 b2          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0023d0:  72 01                moveq    #$1, d1
  0023d2:  74 02                moveq    #$2, d2
  0023d4:  4e ba 04 aa          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0023d8:  28 3c 04 00 00 a8    move.l   #$40000a8, d4  ; MFB reg +$a8
  0023de:  29 bc ff ff ff ff 48 00 move.l   #$ffffffff, (a4, d4.l)
  0023e6:  60 22                bra.b    $240a  ; -> L240a
L23e8:
  0023e8:  72 02                moveq    #$2, d1
  0023ea:  74 04                moveq    #$4, d2
  0023ec:  4e ba 04 92          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0023f0:  72 01                moveq    #$1, d1
  0023f2:  74 02                moveq    #$2, d2
  0023f4:  4e ba 04 8a          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0023f8:  60 10                bra.b    $240a  ; -> L240a
L23fa:
  0023fa:  72 02                moveq    #$2, d1
  0023fc:  74 04                moveq    #$4, d2
  0023fe:  4e ba 04 80          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002402:  72 01                moveq    #$1, d1
  002404:  74 02                moveq    #$2, d2
  002406:  4e ba 04 78          jsr      $2880(pc)  ; -> SerialShiftOutReg
* Enable/disable the sResources that match this monitor + depth by
* walking the mode table at $2A2C and calling Slot Manager sSetSRsrcState
* ($31); the unmatched modes are left disabled.
L240a:
  00240a:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  00240c:  28 1f                move.l   (a7)+, d4
  00240e:  2a 04                move.l   d4, d5
  002410:  2f 05                move.l   d5, -(a7)
  002412:  08 c4 00 05          bset.b   #$5, d4
  002416:  08 c3 00 05          bset.b   #$5, d3
  00241a:  45 fa 06 10          lea.l    $2a2c(pc), a2
  00241e:  72 07                moveq    #$7, d1
L2420:
  002420:  14 1a                move.b   (a2)+, d2
  002422:  4a 06                tst.b    d6
  002424:  66 04                bne.b    $242a  ; -> L242a
  002426:  08 c2 00 04          bset.b   #$4, d2
L242a:
  00242a:  11 42 00 32          move.b   d2, $32(a0)  ; [spID]
  00242e:  70 31                moveq    #$31, d0
  002430:  a0 6e                dc.w     $a06e  ; _SlotManager selector=0x31  sSetSRsrcState: set state of one sResource
  002432:  51 c9 ff ec          dbra     d1, $2420  ; -> L2420
  002436:  42 47                clr.w    d7
  002438:  08 04 00 00          btst.b   #$0, d4
  00243c:  67 04                beq.b    $2442  ; -> L2442
  00243e:  08 84 00 02          bclr.b   #$2, d4
L2442:
  002442:  45 fa 05 e8          lea.l    $2a2c(pc), a2
  002446:  72 07                moveq    #$7, d1
L2448:
  002448:  14 1a                move.b   (a2)+, d2
  00244a:  4a 06                tst.b    d6
  00244c:  67 04                beq.b    $2452  ; -> L2452
  00244e:  08 c2 00 04          bset.b   #$4, d2
L2452:
  002452:  b4 03                cmp.b    d3, d2
  002454:  66 1a                bne.b    $2470  ; -> L2470
  002456:  11 42 00 32          move.b   d2, $32(a0)  ; [spID]
  00245a:  21 7c 00 00 00 01 00 18 move.l   #$1, $18(a0)  ; [spParamData]
  002462:  42 28 00 33          clr.b    $33(a0)  ; [spExtDev]
  002466:  70 09                moveq    #$9, d0
  002468:  a0 6e                dc.w     $a06e  ; _SlotManager selector=0x9
  00246a:  42 a8 00 18          clr.l    $18(a0)  ; [spParamData]
  00246e:  60 0e                bra.b    $247e  ; -> L247e
L2470:
  002470:  b4 04                cmp.b    d4, d2
  002472:  67 0a                beq.b    $247e  ; -> L247e
  002474:  11 42 00 32          move.b   d2, $32(a0)  ; [spID]
  002478:  70 31                moveq    #$31, d0
  00247a:  a0 6e                dc.w     $a06e  ; _SlotManager selector=0x31
  00247c:  52 47                addq.w   #$1, d7
L247e:
  00247e:  51 c9 ff c8          dbra     d1, $2448  ; -> L2448
  002482:  0c 47 00 08          cmpi.w   #$8, d7
  002486:  67 00 02 2e          beq.w    $26b6  ; -> L26b6
  00248a:  2f 04                move.l   d4, -(a7)
  00248c:  08 84 00 05          bclr.b   #$5, d4
  002490:  1a 04                move.b   d4, d5
  002492:  02 45 00 0f          andi.w   #$f, d5
  002496:  08 05 00 00          btst.b   #$0, d5
  00249a:  67 04                beq.b    $24a0  ; -> L24a0
  00249c:  08 85 00 02          bclr.b   #$2, d5
L24a0:
  0024a0:  70 01                moveq    #$1, d0
  0024a2:  a0 5d                dc.w     $a05d  ; _SwapMMUMode ->32-bit mode
  0024a4:  0c 05 00 02          cmpi.b   #$2, d5
  0024a8:  67 3c                beq.b    $24e6  ; -> L24e6
  0024aa:  0c 05 00 03          cmpi.b   #$3, d5
  0024ae:  67 3c                beq.b    $24ec  ; -> L24ec
  0024b0:  0c 05 00 01          cmpi.b   #$1, d5
  0024b4:  67 3c                beq.b    $24f2  ; -> L24f2
  0024b6:  0c 05 00 06          cmpi.b   #$6, d5
  0024ba:  67 3c                beq.b    $24f8  ; -> L24f8
  0024bc:  0c 05 00 04          cmpi.b   #$4, d5
  0024c0:  67 1e                beq.b    $24e0  ; -> L24e0
  0024c2:  0c 05 00 0c          cmpi.b   #$c, d5
  0024c6:  67 12                beq.b    $24da  ; -> L24da
  0024c8:  0c 05 00 00          cmpi.b   #$0, d5
  0024cc:  67 06                beq.b    $24d4  ; -> L24d4
  0024ce:  41 fa 08 f4          lea.l    $2dc4(pc), a0
  0024d2:  60 28                bra.b    $24fc  ; -> L24fc
L24d4:
  0024d4:  41 fa 09 86          lea.l    $2e5c(pc), a0
  0024d8:  60 22                bra.b    $24fc  ; -> L24fc
L24da:
  0024da:  41 fa 07 b8          lea.l    $2c94(pc), a0
  0024de:  60 1c                bra.b    $24fc  ; -> L24fc
L24e0:
  0024e0:  41 fa 08 4a          lea.l    $2d2c(pc), a0
  0024e4:  60 16                bra.b    $24fc  ; -> L24fc
L24e6:
  0024e6:  41 fa 07 14          lea.l    $2bfc(pc), a0
  0024ea:  60 10                bra.b    $24fc  ; -> L24fc
L24ec:
  0024ec:  41 fa 05 46          lea.l    $2a34(pc), a0
  0024f0:  60 0a                bra.b    $24fc  ; -> L24fc
L24f2:
  0024f2:  41 fa 05 d8          lea.l    $2acc(pc), a0
  0024f6:  60 04                bra.b    $24fc  ; -> L24fc
L24f8:
  0024f8:  41 fa 06 6a          lea.l    $2b64(pc), a0
L24fc:
  0024fc:  26 49                movea.l  a1, a3
  0024fe:  d7 fc 06 c0 00 08    adda.l   #$6c00008, a3  ; AC842 control port
  002504:  26 98                move.l   (a0)+, (a3)
  002506:  28 49                movea.l  a1, a4
  002508:  28 3c 04 00 00 80    move.l   #$4000080, d4  ; MFB reg +$80
  00250e:  0c 05 00 0c          cmpi.b   #$c, d5
  002512:  67 16                beq.b    $252a  ; -> L252a
  002514:  0c 05 00 04          cmpi.b   #$4, d5
  002518:  67 10                beq.b    $252a  ; -> L252a
  00251a:  0c 05 00 08          cmpi.b   #$8, d5
  00251e:  67 0a                beq.b    $252a  ; -> L252a
  002520:  0c 05 00 00          cmpi.b   #$0, d5
  002524:  67 04                beq.b    $252a  ; -> L252a
  002526:  72 01                moveq    #$1, d1
  002528:  60 02                bra.b    $252c  ; -> L252c
L252a:
  00252a:  72 00                moveq    #$0, d1
L252c:
  00252c:  ef f4 10 01 48 00    bfins    d1, (a4, d4.l){0:1}
  002532:  28 3c 04 00 00 7c    move.l   #$400007c, d4  ; MFB reg +$7c
  002538:  22 18                move.l   (a0)+, d1
  00253a:  ef f4 10 01 48 00    bfins    d1, (a4, d4.l){0:1}
  002540:  28 3c 04 00 00 04    move.l   #$4000004, d4  ; MFB reg +$04
  002546:  22 18                move.l   (a0)+, d1
  002548:  74 08                moveq    #$8, d2
  00254a:  4e ba 03 34          jsr      $2880(pc)  ; -> SerialShiftOutReg
  00254e:  28 3c 04 00 00 00    move.l   #$4000000, d4  ; MFB reg +$00
  002554:  22 18                move.l   (a0)+, d1
  002556:  74 14                moveq    #$14, d2
  002558:  4e ba 03 26          jsr      $2880(pc)  ; -> SerialShiftOutReg
  00255c:  28 3c 04 00 00 a0    move.l   #$40000a0, d4  ; MFB reg +$a0
  002562:  22 18                move.l   (a0)+, d1
  002564:  74 0c                moveq    #$c, d2
  002566:  4e ba 03 18          jsr      $2880(pc)  ; -> SerialShiftOutReg
  00256a:  26 49                movea.l  a1, a3
  00256c:  d7 fc 06 80 00 00    adda.l   #$6800000, a3  ; clock/timing coeff RAM +$0
  002572:  34 3c 00 0f          move.w   #$f, d2
L2576:
  002576:  26 98                move.l   (a0)+, (a3)
  002578:  51 ca ff fc          dbra     d2, $2576  ; -> L2576
  00257c:  34 38 0d 00          move.w   $d00.w, d2
L2580:
  002580:  51 ca ff fe          dbra     d2, $2580  ; -> L2580
  002584:  26 49                movea.l  a1, a3
  002586:  d7 fc 04 40 00 00    adda.l   #$4400000, a3  ; MFB IRQ +$0 (IRQ reg base)
  00258c:  36 3c 00 0f          move.w   #$f, d3
  002590:  28 49                movea.l  a1, a4
  002592:  28 3c 04 c0 00 00    move.l   #$4c00000, d4  ; control serial port (mode/IRQ)
L2598:
  002598:  74 0c                moveq    #$c, d2
  00259a:  22 18                move.l   (a0)+, d1
  00259c:  4e ba 02 e2          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0025a0:  42 9b                clr.l    (a3)+
  0025a2:  51 cb ff f4          dbra     d3, $2598  ; -> L2598
  0025a6:  72 03                moveq    #$3, d1
  0025a8:  4e ba 02 d6          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0025ac:  27 34 48 00          move.l   (a4, d4.l), -(a3)
  0025b0:  28 3c 04 40 00 48    move.l   #$4400048, d4  ; MFB IRQ +$48 (IRQ status/flag reg)
  0025b6:  42 b4 48 00          clr.l    (a4, d4.l)
  0025ba:  2a 1f                move.l   (a7)+, d5
  0025bc:  28 49                movea.l  a1, a4
  0025be:  22 3c 06 c0 00 04    move.l   #$6c00004, d1  ; AC842 CLUT data port (R,G,B)
  0025c4:  42 b1 18 fc          clr.l    -$4(a1, d1.l)
  0025c8:  0c 05 00 01          cmpi.b   #$1, d5
  0025cc:  67 20                beq.b    $25ee  ; -> L25ee
  0025ce:  0c 05 00 03          cmpi.b   #$3, d5
  0025d2:  67 1a                beq.b    $25ee  ; -> L25ee
  0025d4:  50 f4 18 00          st.b     (a4, d1.l)
  0025d8:  50 f4 18 00          st.b     (a4, d1.l)
  0025dc:  50 f4 18 00          st.b     (a4, d1.l)
  0025e0:  51 f4 18 00          sf.b     (a4, d1.l)
  0025e4:  51 f4 18 00          sf.b     (a4, d1.l)
  0025e8:  51 f4 18 00          sf.b     (a4, d1.l)
  0025ec:  60 18                bra.b    $2606  ; -> L2606
L25ee:
  0025ee:  50 f4 18 00          st.b     (a4, d1.l)
  0025f2:  50 f4 18 00          st.b     (a4, d1.l)
  0025f6:  50 f4 18 00          st.b     (a4, d1.l)
  0025fa:  51 f4 18 00          sf.b     (a4, d1.l)
  0025fe:  51 f4 18 00          sf.b     (a4, d1.l)
  002602:  51 f4 18 00          sf.b     (a4, d1.l)
L2606:
  002606:  28 49                movea.l  a1, a4
  002608:  d9 fc 0c 00 00 00    adda.l   #$c000000, a4  ; VRAM/framebuffer +$0
  00260e:  3f 05                move.w   d5, -(a7)
  002610:  02 05 00 0f          andi.b   #$f, d5
  002614:  02 45 00 03          andi.w   #$3, d5
  002618:  0c 05 00 00          cmpi.b   #$0, d5
  00261c:  67 08                beq.b    $2626  ; -> L2626
  00261e:  d9 fc 00 01 00 00    adda.l   #$10000, a4
  002624:  60 1e                bra.b    $2644  ; -> L2644
L2626:
  002626:  d9 fc 00 01 14 00    adda.l   #$11400, a4
  00262c:  38 3c 04 00          move.w   #$400, d4
  002630:  c8 fc 00 05          mulu.w   #$5, d4
  002634:  98 c4                suba.w   d4, a4
  002636:  e4 4c                lsr.w    #$2, d4
  002638:  53 44                subq.w   #$1, d4
L263a:
  00263a:  28 fc ff ff ff ff    move.l   #$ffffffff, (a4)+
  002640:  51 cc ff f8          dbra     d4, $263a  ; -> L263a
L2644:
  002644:  2a 3c aa aa aa aa    move.l   #$aaaaaaaa, d5
  00264a:  36 18                move.w   (a0)+, d3
L264c:
  00264c:  34 10                move.w   (a0), d2  ; [spResult]
L264e:
  00264e:  28 c5                move.l   d5, (a4)+
  002650:  51 ca ff fc          dbra     d2, $264e  ; -> L264e
  002654:  46 85                not.l    d5
  002656:  51 cb ff f4          dbra     d3, $264c  ; -> L264c
  00265a:  3a 1f                move.w   (a7)+, d5
  00265c:  14 05                move.b   d5, d2
  00265e:  02 42 00 03          andi.w   #$3, d2
  002662:  0c 02 00 00          cmpi.b   #$0, d2
  002666:  66 14                bne.b    $267c  ; -> L267c
  002668:  08 05 00 03          btst.b   #$3, d5
  00266c:  66 0e                bne.b    $267c  ; -> L267c
  00266e:  32 3c 3b ff          move.w   #$3bff, d1
L2672:
  002672:  28 fc ff ff ff ff    move.l   #$ffffffff, (a4)+
  002678:  51 c9 ff f8          dbra     d1, $2672  ; -> L2672
L267c:
  00267c:  28 49                movea.l  a1, a4
  00267e:  d9 fc 0c 00 73 18    adda.l   #$c007318, a4  ; MFB/Am29000 param block +$18
  002684:  28 bc 57 59 57 59    move.l   #$57595759, (a4)  ; 'WYWY'
  00268a:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  00268c:  28 1f                move.l   (a7)+, d4
  00268e:  2a 09                move.l   a1, d5
  002690:  e9 9d                rol.l    #$4, d5
  002692:  08 04 00 04          btst.b   #$4, d4
  002696:  67 1e                beq.b    $26b6  ; -> L26b6
  002698:  55 4f                subq.w   #$2, a7
  00269a:  20 4f                movea.l  a7, a0
  00269c:  a0 80                dc.w     $a080  ; _GetVideoDefault
  00269e:  ba 10                cmp.b    (a0), d5  ; [spResult]
  0026a0:  66 12                bne.b    $26b4  ; -> L26b4
  0026a2:  08 84 00 04          bclr.b   #$4, d4
  0026a6:  b8 28 00 01          cmp.b    $1(a0), d4
  0026aa:  66 08                bne.b    $26b4  ; -> L26b4
  0026ac:  08 e8 00 04 00 01    bset.b   #$4, $1(a0)
  0026b2:  a0 81                dc.w     $a081  ; _SetVideoDefault
L26b4:
  0026b4:  54 4f                addq.w   #$2, a7
L26b6:
  0026b6:  de fc 00 38          adda.w   #$38, a7
  0026ba:  4e 75                rts      
L26bc:
  0026bc:  49 fa 03 5e          lea.l    $2a1c(pc), a4
  0026c0:  78 0f                moveq    #$f, d4
L26c2:
  0026c2:  11 5c 00 32          move.b   (a4)+, $32(a0)
  0026c6:  70 31                moveq    #$31, d0
  0026c8:  a0 6e                dc.w     $a06e  ; _SlotManager selector=0x31
  0026ca:  51 cc ff f6          dbra     d4, $26c2  ; -> L26c2
  0026ce:  70 01                moveq    #$1, d0
  0026d0:  a0 5d                dc.w     $a05d  ; _SwapMMUMode ->32-bit mode
  0026d2:  28 49                movea.l  a1, a4
  0026d4:  28 3c 04 80 00 00    move.l   #$4800000, d4  ; clock-synth serial port
  0026da:  72 00                moveq    #$0, d1
  0026dc:  74 01                moveq    #$1, d2
  0026de:  4e ba 01 a0          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0026e2:  22 3c 00 00 09 98    move.l   #$998, d1
  0026e8:  74 0c                moveq    #$c, d2
  0026ea:  4e ba 01 94          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0026ee:  22 3c 00 00 8b 88    move.l   #$8b88, d1
  0026f4:  74 10                moveq    #$10, d2
  0026f6:  4e ba 01 88          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0026fa:  22 3c 00 00 aa ad    move.l   #$aaad, d1
  002700:  74 10                moveq    #$10, d2
  002702:  4e ba 01 7c          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002706:  24 3c 06 00 00 00    move.l   #$6000000, d2  ; AC842 space +$0
  00270c:  22 34 28 00          move.l   (a4, d2.l), d1
  002710:  02 41 f0 00          andi.w   #$f000, d1
  002714:  0c 41 10 00          cmpi.w   #$1000, d1
  002718:  67 3a                beq.b    $2754  ; -> L2754
  00271a:  22 3c 00 00 9a cc    move.l   #$9acc, d1
  002720:  74 10                moveq    #$10, d2
  002722:  4e ba 01 5c          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002726:  22 3c 00 00 8a 9c    move.l   #$8a9c, d1
  00272c:  74 10                moveq    #$10, d2
  00272e:  4e ba 01 50          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002732:  22 3c 00 88 ac ac    move.l   #$88acac, d1
  002738:  74 18                moveq    #$18, d2
  00273a:  4e ba 01 44          jsr      $2880(pc)  ; -> SerialShiftOutReg
  00273e:  72 53                moveq    #$53, d1
  002740:  74 0c                moveq    #$c, d2
  002742:  4e ba 01 3c          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002746:  22 3c 00 02 40 5b    move.l   #$2405b, d1
  00274c:  74 12                moveq    #$12, d2
  00274e:  4e ba 01 30          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002752:  60 3c                bra.b    $2790  ; -> L2790
L2754:
  002754:  22 3c 00 00 9b cc    move.l   #$9bcc, d1
  00275a:  74 10                moveq    #$10, d2
  00275c:  4e ba 01 22          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002760:  22 3c 00 00 8a 9c    move.l   #$8a9c, d1
  002766:  74 10                moveq    #$10, d2
  002768:  4e ba 01 16          jsr      $2880(pc)  ; -> SerialShiftOutReg
  00276c:  22 3c 00 88 ac bc    move.l   #$88acbc, d1
  002772:  74 18                moveq    #$18, d2
  002774:  4e ba 01 0a          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002778:  22 3c 00 00 00 93    move.l   #$93, d1
  00277e:  74 0c                moveq    #$c, d2
  002780:  4e ba 00 fe          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002784:  22 3c 00 02 40 9b    move.l   #$2409b, d1
  00278a:  74 12                moveq    #$12, d2
  00278c:  4e ba 00 f2          jsr      $2880(pc)  ; -> SerialShiftOutReg
L2790:
  002790:  72 02                moveq    #$2, d1
  002792:  74 04                moveq    #$4, d2
  002794:  4e ba 00 ea          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002798:  72 01                moveq    #$1, d1
  00279a:  74 02                moveq    #$2, d2
  00279c:  4e ba 00 e2          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0027a0:  41 fa 03 c2          lea.l    $2b64(pc), a0
  0027a4:  26 49                movea.l  a1, a3
  0027a6:  d7 fc 06 c0 00 08    adda.l   #$6c00008, a3  ; AC842 control port
  0027ac:  26 98                move.l   (a0)+, (a3)
  0027ae:  28 49                movea.l  a1, a4
  0027b0:  28 3c 04 00 00 80    move.l   #$4000080, d4  ; MFB reg +$80
  0027b6:  42 b4 48 00          clr.l    (a4, d4.l)
  0027ba:  28 3c 04 00 00 7c    move.l   #$400007c, d4  ; MFB reg +$7c
  0027c0:  22 18                move.l   (a0)+, d1
  0027c2:  ef f4 10 01 48 00    bfins    d1, (a4, d4.l){0:1}
  0027c8:  28 3c 04 00 00 04    move.l   #$4000004, d4  ; MFB reg +$04
  0027ce:  22 18                move.l   (a0)+, d1
  0027d0:  74 08                moveq    #$8, d2
  0027d2:  4e ba 00 ac          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0027d6:  28 3c 04 00 00 00    move.l   #$4000000, d4  ; MFB reg +$00
  0027dc:  22 18                move.l   (a0)+, d1
  0027de:  74 14                moveq    #$14, d2
  0027e0:  4e ba 00 9e          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0027e4:  28 3c 04 00 00 a0    move.l   #$40000a0, d4  ; MFB reg +$a0
  0027ea:  22 18                move.l   (a0)+, d1
  0027ec:  74 0c                moveq    #$c, d2
  0027ee:  4e ba 00 90          jsr      $2880(pc)  ; -> SerialShiftOutReg
  0027f2:  26 49                movea.l  a1, a3
  0027f4:  d7 fc 06 80 00 00    adda.l   #$6800000, a3  ; clock/timing coeff RAM +$0
  0027fa:  34 3c 00 0f          move.w   #$f, d2
L27fe:
  0027fe:  26 98                move.l   (a0)+, (a3)
  002800:  51 ca ff fc          dbra     d2, $27fe  ; -> L27fe
  002804:  34 38 0d 00          move.w   $d00.w, d2
L2808:
  002808:  51 ca ff fe          dbra     d2, $2808  ; -> L2808
  00280c:  26 49                movea.l  a1, a3
  00280e:  d7 fc 04 40 00 00    adda.l   #$4400000, a3  ; MFB IRQ +$0 (IRQ reg base)
  002814:  36 3c 00 0f          move.w   #$f, d3
  002818:  28 49                movea.l  a1, a4
  00281a:  28 3c 04 c0 00 00    move.l   #$4c00000, d4  ; control serial port (mode/IRQ)
L2820:
  002820:  74 0c                moveq    #$c, d2
  002822:  22 18                move.l   (a0)+, d1
  002824:  4e ba 00 5a          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002828:  42 9b                clr.l    (a3)+
  00282a:  51 cb ff f4          dbra     d3, $2820  ; -> L2820
  00282e:  72 03                moveq    #$3, d1
  002830:  4e ba 00 4e          jsr      $2880(pc)  ; -> SerialShiftOutReg
  002834:  27 34 48 00          move.l   (a4, d4.l), -(a3)
  002838:  28 3c 04 40 00 48    move.l   #$4400048, d4  ; MFB IRQ +$48 (IRQ status/flag reg)
  00283e:  42 b4 48 00          clr.l    (a4, d4.l)
  002842:  28 49                movea.l  a1, a4
  002844:  22 3c 06 c0 00 04    move.l   #$6c00004, d1  ; AC842 CLUT data port (R,G,B)
  00284a:  42 b1 18 fc          clr.l    -$4(a1, d1.l)
  00284e:  51 f4 18 00          sf.b     (a4, d1.l)
  002852:  51 f4 18 00          sf.b     (a4, d1.l)
  002856:  51 f4 18 00          sf.b     (a4, d1.l)
  00285a:  51 f4 18 00          sf.b     (a4, d1.l)
  00285e:  51 f4 18 00          sf.b     (a4, d1.l)
  002862:  51 f4 18 00          sf.b     (a4, d1.l)
  002866:  28 3c 04 40 00 3c    move.l   #$440003c, d4  ; MFB IRQ +$3c (IRQ clear reg)
  00286c:  42 b4 48 00          clr.l    (a4, d4.l)
  002870:  28 3c 04 40 00 48    move.l   #$4400048, d4  ; MFB IRQ +$48 (IRQ status/flag reg)
  002876:  42 b4 48 00          clr.l    (a4, d4.l)
  00287a:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  00287c:  60 00 fe 38          bra.w    $26b6  ; -> L26b6
* SerialShiftOutReg  -  shift D1 (top D2 bits, MSB first) out to the
* card register at (A4,D4).  Used to clock values into the pixel-clock
* synthesiser / AC842 serial port.
SerialShiftOutReg:
  002880:  48 e7 62 00          movem.l  d1-d2/d6, -(a7)
  002884:  7c 20                moveq    #$20, d6
  002886:  9c 42                sub.w    d2, d6
  002888:  ed a9                lsl.l    d6, d1
  00288a:  04 42 00 01          subi.w   #$1, d2
L288e:
  00288e:  29 81 48 00          move.l   d1, (a4, d4.l)
  002892:  e3 89                lsl.l    #$1, d1
  002894:  51 ca ff f8          dbra     d2, $288e  ; -> L288e
  002898:  4c df 00 46          movem.l  (a7)+, d1-d2/d6
  00289c:  4e 75                rts      
* RegTouchLoop  -  read-and-write a register (12-D1) times, a short
* settle / hand-shake delay for the serial device.
RegTouchLoop:
  00289e:  74 0b                moveq    #$b, d2
  0028a0:  94 81                sub.l    d1, d2
L28a2:
  0028a2:  20 34 48 00          move.l   (a4, d4.l), d0
  0028a6:  29 80 48 00          move.l   d0, (a4, d4.l)
  0028aa:  51 ca ff f6          dbra     d2, $28a2  ; -> L28a2
  0028ae:  4e 75                rts      
sub_28b0:
  0028b0:  42 40                clr.w    d0
  0028b2:  72 00                moveq    #$0, d1
  0028b4:  74 00                moveq    #$0, d2
  0028b6:  28 3c 04 00 00 2c    move.l   #$400002c, d4  ; MFB reg +$2c
  0028bc:  29 bc ff ff ff ff 48 00 move.l   #$ffffffff, (a4, d4.l)
  0028c4:  28 3c 04 00 00 30    move.l   #$4000030, d4  ; MFB reg +$30
  0028ca:  42 b4 48 00          clr.l    (a4, d4.l)
  0028ce:  28 3c 04 00 00 34    move.l   #$4000034, d4  ; MFB reg +$34
  0028d4:  42 b4 48 00          clr.l    (a4, d4.l)
  0028d8:  28 3c 04 00 00 48    move.l   #$4000048, d4  ; MFB reg +$48 (SENSE line 1)
  0028de:  e9 f4 20 01 48 00    bfextu   (a4, d4.l){0:1}, d2
  0028e4:  82 02                or.b     d2, d1
  0028e6:  e3 09                lsl.b    #$1, d1
  0028e8:  28 3c 04 00 00 4c    move.l   #$400004c, d4  ; MFB reg +$4c (SENSE line 2)
  0028ee:  e9 f4 20 01 48 00    bfextu   (a4, d4.l){0:1}, d2
  0028f4:  82 02                or.b     d2, d1
  0028f6:  e3 09                lsl.b    #$1, d1
  0028f8:  28 3c 04 00 00 2c    move.l   #$400002c, d4  ; MFB reg +$2c
  0028fe:  42 b4 48 00          clr.l    (a4, d4.l)
  002902:  28 3c 04 00 00 30    move.l   #$4000030, d4  ; MFB reg +$30
  002908:  29 bc ff ff ff ff 48 00 move.l   #$ffffffff, (a4, d4.l)
  002910:  28 3c 04 00 00 34    move.l   #$4000034, d4  ; MFB reg +$34
  002916:  42 b4 48 00          clr.l    (a4, d4.l)
  00291a:  28 3c 04 00 00 44    move.l   #$4000044, d4  ; MFB reg +$44 (SENSE line 0)
  002920:  e9 f4 20 01 48 00    bfextu   (a4, d4.l){0:1}, d2
  002926:  82 02                or.b     d2, d1
  002928:  e3 09                lsl.b    #$1, d1
  00292a:  28 3c 04 00 00 4c    move.l   #$400004c, d4  ; MFB reg +$4c (SENSE line 2)
  002930:  e9 f4 20 01 48 00    bfextu   (a4, d4.l){0:1}, d2
  002936:  82 02                or.b     d2, d1
  002938:  e3 09                lsl.b    #$1, d1
  00293a:  28 3c 04 00 00 2c    move.l   #$400002c, d4  ; MFB reg +$2c
  002940:  42 b4 48 00          clr.l    (a4, d4.l)
  002944:  28 3c 04 00 00 30    move.l   #$4000030, d4  ; MFB reg +$30
  00294a:  42 b4 48 00          clr.l    (a4, d4.l)
  00294e:  28 3c 04 00 00 34    move.l   #$4000034, d4  ; MFB reg +$34
  002954:  29 bc ff ff ff ff 48 00 move.l   #$ffffffff, (a4, d4.l)
  00295c:  28 3c 04 00 00 44    move.l   #$4000044, d4  ; MFB reg +$44 (SENSE line 0)
  002962:  e9 f4 20 01 48 00    bfextu   (a4, d4.l){0:1}, d2
  002968:  82 02                or.b     d2, d1
  00296a:  e3 09                lsl.b    #$1, d1
  00296c:  28 3c 04 00 00 48    move.l   #$4000048, d4  ; MFB reg +$48 (SENSE line 1)
  002972:  e9 f4 20 01 48 00    bfextu   (a4, d4.l){0:1}, d2
  002978:  82 02                or.b     d2, d1
  00297a:  80 01                or.b     d1, d0
  00297c:  28 3c 04 00 00 2c    move.l   #$400002c, d4  ; MFB reg +$2c
  002982:  42 b4 48 00          clr.l    (a4, d4.l)
  002986:  28 3c 04 00 00 30    move.l   #$4000030, d4  ; MFB reg +$30
  00298c:  42 b4 48 00          clr.l    (a4, d4.l)
  002990:  28 3c 04 00 00 34    move.l   #$4000034, d4  ; MFB reg +$34
  002996:  42 b4 48 00          clr.l    (a4, d4.l)
  00299a:  4e 75                rts      
* ReadExtendedSense  -  drive each sense line and read the others to
* form the extended monitor-sense code (as in the driver's sub_62F6).
ReadExtendedSense:
  00299c:  48 e7 c8 80          movem.l  d0-d1/d4/a0, -(a7)
  0029a0:  40 c0                move.w   sr, d0
  0029a2:  3f 00                move.w   d0, -(a7)
  0029a4:  00 40 07 00          ori.w    #$700, d0
  0029a8:  46 c0                move.w   d0, sr
  0029aa:  20 49                movea.l  a1, a0
  0029ac:  d1 fc 04 40 01 c0    adda.l   #$44001c0, a0  ; MFB IRQ +$1c0 (video-sync status reg)
  0029b2:  72 02                moveq    #$2, d1
  0029b4:  28 49                movea.l  a1, a4
  0029b6:  28 3c 04 c0 00 00    move.l   #$4c00000, d4  ; control serial port (mode/IRQ)
L29bc:
  0029bc:  20 10                move.l   (a0), d0  ; [seSlot]
  0029be:  4e ba fe de          jsr      $289e(pc)  ; -> RegTouchLoop
  0029c2:  08 00 00 1f          btst.b   #$1f, d0
  0029c6:  67 f4                beq.b    $29bc  ; -> L29bc
L29c8:
  0029c8:  20 10                move.l   (a0), d0  ; [seSlot]
  0029ca:  4e ba fe d2          jsr      $289e(pc)  ; -> RegTouchLoop
  0029ce:  08 00 00 1f          btst.b   #$1f, d0
  0029d2:  66 f4                bne.b    $29c8  ; -> L29c8
L29d4:
  0029d4:  20 10                move.l   (a0), d0  ; [seSlot]
  0029d6:  4e ba fe c6          jsr      $289e(pc)  ; -> RegTouchLoop
  0029da:  08 00 00 1f          btst.b   #$1f, d0
  0029de:  67 f4                beq.b    $29d4  ; -> L29d4
  0029e0:  46 df                move.w   (a7)+, sr
  0029e2:  4c df 01 13          movem.l  (a7)+, d0-d1/d4/a0
  0029e6:  4e 75                rts      
* ==================================================================
* PrimaryInit data tables
* ==================================================================
* Signed longs, offset from $29E8, mapping each internal mode number to
* its per-monitor timing table below ($FFFFF618 = -$9E8 = unsupported).
ModeTimingOffsets:
  0029e8:  00 00 04 74          dc.l     $00000474  ; mode  0 -> timing table @ $2E5C
  0029ec:  00 00 00 e4          dc.l     $000000E4  ; mode  1 -> timing table @ $2ACC
  0029f0:  00 00 02 ac          dc.l     $000002AC  ; mode  2 -> timing table @ $2C94
  0029f4:  00 00 00 4c          dc.l     $0000004C  ; mode  3 -> timing table @ $2A34
  0029f8:  00 00 03 44          dc.l     $00000344  ; mode  4 -> timing table @ $2D2C
  0029fc:  ff ff f6 18          dc.l     $FFFFF618  ; mode  5: unsupported
  002a00:  00 00 01 7c          dc.l     $0000017C  ; mode  6 -> timing table @ $2B64
  002a04:  ff ff f6 18          dc.l     $FFFFF618  ; mode  7: unsupported
  002a08:  00 00 03 dc          dc.l     $000003DC  ; mode  8 -> timing table @ $2DC4
  002a0c:  ff ff f6 18          dc.l     $FFFFF618  ; mode  9: unsupported
  002a10:  ff ff f6 18          dc.l     $FFFFF618  ; mode 10: unsupported
  002a14:  ff ff f6 18          dc.l     $FFFFF618  ; mode 11: unsupported
  002a18:  00 00 02 ac          dc.l     $000002AC  ; mode 12 -> timing table @ $2C94
MonitorSRsrcPairs:
  002a1c:  a0 b0                dc.w     $A0B0  ; monitor 0: sRsrc $A0 (A) / $B0 (B)
  002a1e:  a1 b1                dc.w     $A1B1  ; monitor 1: sRsrc $A1 (A) / $B1 (B)
  002a20:  a2 b2                dc.w     $A2B2  ; monitor 2: sRsrc $A2 (A) / $B2 (B)
  002a22:  a3 b3                dc.w     $A3B3  ; monitor 3: sRsrc $A3 (A) / $B3 (B)
  002a24:  a4 b4                dc.w     $A4B4  ; monitor 4: sRsrc $A4 (A) / $B4 (B)
  002a26:  a6 b6                dc.w     $A6B6  ; monitor 5: sRsrc $A6 (A) / $B6 (B)
  002a28:  a8 b8                dc.w     $A8B8  ; monitor 6: sRsrc $A8 (A) / $B8 (B)
  002a2a:  ac bc                dc.w     $ACBC  ; monitor 7: sRsrc $AC (A) / $BC (B)
BankAsRsrcList:
  002a2c:  a0 a1 a2 a3 a4 a6 a8 ac dc.b     $A0,$A1,$A2,$A3,$A4,$A6,$A8,$AC
* per-monitor video-timing / pixel-clock coefficients (mode 3)
TimingTable_2a34:
  002a34:  c0 00 00 00 00 00 00 00 00 00 00 f8 00 00 20 00 dc.l     $C0000000,$00000000,$000000F8,$00002000
  002a44:  00 00 00 20 00 00 00 0e 00 00 00 1b 00 00 00 20 dc.l     $00000020,$0000000E,$0000001B,$00000020
  002a54:  00 00 00 30 00 00 00 43 00 00 00 51 00 00 00 60 dc.l     $00000030,$00000043,$00000051,$00000060
  002a64:  00 00 00 70 00 00 00 80 00 00 00 91 00 00 00 ad dc.l     $00000070,$00000080,$00000091,$000000AD
  002a74:  00 00 00 b6 00 00 00 c4 00 00 00 d1 00 00 00 e0 dc.l     $000000B6,$000000C4,$000000D1,$000000E0
  002a84:  00 00 00 f0 00 00 00 03 00 00 00 00 00 00 00 90 dc.l     $000000F0,$00000003,$00000000,$00000090
  002a94:  00 00 01 1e 00 00 00 20 00 00 00 1e 00 00 00 08 dc.l     $0000011E,$00000020,$0000001E,$00000008
  002aa4:  00 00 00 03 00 00 00 00 00 00 06 cc 00 00 00 4e dc.l     $00000003,$00000000,$000006CC,$0000004E
  002ab4:  00 00 00 06 00 00 00 06 00 00 00 00 00 00 01 6c dc.l     $00000006,$00000006,$00000000,$0000016C
  002ac4:  00 00 00 02 03 65 00 3f dc.l     $00000002,$0365003F
* per-monitor video-timing / pixel-clock coefficients (mode 1)
TimingTable_2acc:
  002acc:  c0 00 00 00 00 00 00 00 00 00 00 f8 00 00 20 00 dc.l     $C0000000,$00000000,$000000F8,$00002000
  002adc:  00 00 00 10 00 00 00 0e 00 00 00 17 00 00 00 20 dc.l     $00000010,$0000000E,$00000017,$00000020
  002aec:  00 00 00 30 00 00 00 46 00 00 00 51 00 00 00 60 dc.l     $00000030,$00000046,$00000051,$00000060
  002afc:  00 00 00 70 00 00 00 80 00 00 00 91 00 00 00 ad dc.l     $00000070,$00000080,$00000091,$000000AD
  002b0c:  00 00 00 b6 00 00 00 c4 00 00 00 d1 00 00 00 e0 dc.l     $000000B6,$000000C4,$000000D1,$000000E0
  002b1c:  00 00 00 f0 00 00 00 03 00 00 00 00 00 00 00 50 dc.l     $000000F0,$00000003,$00000000,$00000050
  002b2c:  00 00 00 9e 00 00 00 10 00 00 00 12 00 00 00 08 dc.l     $0000009E,$00000010,$00000012,$00000008
  002b3c:  00 00 00 03 00 00 00 00 00 00 06 cc 00 00 00 54 dc.l     $00000003,$00000000,$000006CC,$00000054
  002b4c:  00 00 00 06 00 00 00 06 00 00 00 00 00 00 00 d0 dc.l     $00000006,$00000006,$00000000,$000000D0
  002b5c:  00 00 00 02 03 65 00 1f dc.l     $00000002,$0365001F
* per-monitor video-timing / pixel-clock coefficients (mode 6)
TimingTable_2b64:
  002b64:  80 00 00 00 00 00 00 00 00 00 00 e0 00 00 20 00 dc.l     $80000000,$00000000,$000000E0,$00002000
  002b74:  00 00 00 10 00 00 00 0f 00 00 00 17 00 00 00 20 dc.l     $00000010,$0000000F,$00000017,$00000020
  002b84:  00 00 00 30 00 00 00 45 00 00 00 51 00 00 00 60 dc.l     $00000030,$00000045,$00000051,$00000060
  002b94:  00 00 00 70 00 00 00 80 00 00 00 92 00 00 00 ad dc.l     $00000070,$00000080,$00000092,$000000AD
  002ba4:  00 00 00 b6 00 00 00 c4 00 00 00 d1 00 00 00 e0 dc.l     $000000B6,$000000C4,$000000D1,$000000E0
  002bb4:  00 00 00 f0 00 00 00 03 00 00 00 00 00 00 01 40 dc.l     $000000F0,$00000003,$00000000,$00000140
  002bc4:  00 00 02 7e 00 00 00 5e 00 00 00 3e 00 00 00 3e dc.l     $0000027E,$0000005E,$0000003E,$0000003E
  002bd4:  00 00 00 03 00 00 00 00 00 00 03 c0 00 00 00 4e dc.l     $00000003,$00000000,$000003C0,$0000004E
  002be4:  00 00 00 06 00 00 00 06 00 00 00 00 00 00 03 60 dc.l     $00000006,$00000006,$00000000,$00000360
  002bf4:  00 00 00 02 01 df 00 1f dc.l     $00000002,$01DF001F
* per-monitor video-timing / pixel-clock coefficients
TimingTable_2bfc:
  002bfc:  80 00 00 00 00 00 00 00 00 00 00 e0 00 00 20 00 dc.l     $80000000,$00000000,$000000E0,$00002000
  002c0c:  00 00 00 08 00 00 00 0e 00 00 00 15 00 00 00 20 dc.l     $00000008,$0000000E,$00000015,$00000020
  002c1c:  00 00 00 30 00 00 00 4f 00 00 00 50 00 00 00 60 dc.l     $00000030,$0000004F,$00000050,$00000060
  002c2c:  00 00 00 70 00 00 00 80 00 00 00 93 00 00 00 ad dc.l     $00000070,$00000080,$00000093,$000000AD
  002c3c:  00 00 00 b6 00 00 00 c4 00 00 00 d1 00 00 00 e0 dc.l     $000000B6,$000000C4,$000000D1,$000000E0
  002c4c:  00 00 00 f0 00 00 00 03 00 00 00 00 00 00 01 00 dc.l     $000000F0,$00000003,$00000000,$00000100
  002c5c:  00 00 01 fe 00 00 00 4e 00 00 00 1e 00 00 00 0e dc.l     $000001FE,$0000004E,$0000001E,$0000000E
  002c6c:  00 00 00 03 00 00 00 00 00 00 03 00 00 00 00 26 dc.l     $00000003,$00000000,$00000300,$00000026
  002c7c:  00 00 00 06 00 00 00 02 00 00 00 00 00 00 02 60 dc.l     $00000006,$00000002,$00000000,$00000260
  002c8c:  00 00 00 02 01 7f 00 0f dc.l     $00000002,$017F000F
* per-monitor video-timing / pixel-clock coefficients (modes 2,12)
TimingTable_2c94:
  002c94:  c1 00 00 00 00 00 00 01 00 00 00 f8 00 00 20 00 dc.l     $C1000000,$00000001,$000000F8,$00002000
  002ca4:  00 00 02 00 00 00 00 0c 00 00 00 11 00 00 00 22 dc.l     $00000200,$0000000C,$00000011,$00000022
  002cb4:  00 00 00 30 00 00 00 47 00 00 00 53 00 00 00 60 dc.l     $00000030,$00000047,$00000053,$00000060
  002cc4:  00 00 00 70 00 00 00 80 00 00 00 92 00 00 00 ad dc.l     $00000070,$00000080,$00000092,$000000AD
  002cd4:  00 00 00 b6 00 00 00 c0 00 00 00 d1 00 00 00 e0 dc.l     $000000B6,$000000C0,$000000D1,$000000E0
  002ce4:  00 00 00 f0 00 00 00 03 00 00 00 00 00 00 01 20 dc.l     $000000F0,$00000003,$00000000,$00000120
  002cf4:  00 00 02 7e 00 00 00 24 00 00 00 3a 00 00 00 28 dc.l     $0000027E,$00000024,$0000003A,$00000028
  002d04:  00 00 00 03 00 00 00 00 00 00 01 e1 00 00 00 20 dc.l     $00000003,$00000000,$000001E1,$00000020
  002d14:  00 00 00 06 00 00 00 06 00 00 00 6e 00 00 01 4a dc.l     $00000006,$00000006,$0000006E,$0000014A
  002d24:  00 00 00 02 01 df 00 ff dc.l     $00000002,$01DF00FF
* per-monitor video-timing / pixel-clock coefficients (mode 4)
TimingTable_2d2c:
  002d2c:  c1 00 00 00 00 00 00 01 00 00 00 f8 00 00 20 00 dc.l     $C1000000,$00000001,$000000F8,$00002000
  002d3c:  00 00 02 00 00 00 00 0c 00 00 00 11 00 00 00 22 dc.l     $00000200,$0000000C,$00000011,$00000022
  002d4c:  00 00 00 30 00 00 00 47 00 00 00 53 00 00 00 60 dc.l     $00000030,$00000047,$00000053,$00000060
  002d5c:  00 00 00 70 00 00 00 80 00 00 00 92 00 00 00 ad dc.l     $00000070,$00000080,$00000092,$000000AD
  002d6c:  00 00 00 b6 00 00 00 c0 00 00 00 d1 00 00 00 e0 dc.l     $000000B6,$000000C0,$000000D1,$000000E0
  002d7c:  00 00 00 f0 00 00 00 03 00 00 00 00 00 00 00 e0 dc.l     $000000F0,$00000003,$00000000,$000000E0
  002d8c:  00 00 01 fe 00 00 00 60 00 00 00 3a 00 00 00 6c dc.l     $000001FE,$00000060,$0000003A,$0000006C
  002d9c:  00 00 00 03 00 00 00 00 00 00 01 b1 00 00 00 50 dc.l     $00000003,$00000000,$000001B1,$00000050
  002dac:  00 00 00 06 00 00 00 06 00 00 00 6e 00 00 01 4a dc.l     $00000006,$00000006,$0000006E,$0000014A
  002dbc:  00 00 00 02 01 7f 00 ff dc.l     $00000002,$017F00FF
* per-monitor video-timing / pixel-clock coefficients (mode 8)
TimingTable_2dc4:
  002dc4:  c1 00 00 00 00 00 00 01 00 00 00 f8 00 00 20 00 dc.l     $C1000000,$00000001,$000000F8,$00002000
  002dd4:  00 00 02 00 00 00 00 0d 00 00 00 19 00 00 00 21 dc.l     $00000200,$0000000D,$00000019,$00000021
  002de4:  00 00 00 30 00 00 00 46 00 00 00 54 00 00 00 60 dc.l     $00000030,$00000046,$00000054,$00000060
  002df4:  00 00 00 71 00 00 00 81 00 00 00 91 00 00 00 ad dc.l     $00000071,$00000081,$00000091,$000000AD
  002e04:  00 00 00 b6 00 00 00 c0 00 00 00 d1 00 00 00 e0 dc.l     $000000B6,$000000C0,$000000D1,$000000E0
  002e14:  00 00 00 f0 00 00 00 03 00 00 00 00 00 00 01 5e dc.l     $000000F0,$00000003,$00000000,$0000015E
  002e24:  00 00 02 fe 00 00 00 33 00 00 00 43 00 00 00 34 dc.l     $000002FE,$00000033,$00000043,$00000034
  002e34:  00 00 00 03 00 00 00 00 00 00 02 40 00 00 00 27 dc.l     $00000003,$00000000,$00000240,$00000027
  002e44:  00 00 00 05 00 00 00 05 00 00 00 5e 00 00 01 93 dc.l     $00000005,$00000005,$0000005E,$00000193
  002e54:  00 00 00 02 02 3f 00 ff dc.l     $00000002,$023F00FF
* per-monitor video-timing / pixel-clock coefficients (mode 0)
TimingTable_2e5c:
  002e5c:  c1 00 00 00 00 00 00 01 00 00 00 f8 00 00 20 00 dc.l     $C1000000,$00000001,$000000F8,$00002000
  002e6c:  00 00 02 00 00 00 00 0d 00 00 00 19 00 00 00 21 dc.l     $00000200,$0000000D,$00000019,$00000021
  002e7c:  00 00 00 30 00 00 00 46 00 00 00 54 00 00 00 60 dc.l     $00000030,$00000046,$00000054,$00000060
  002e8c:  00 00 00 71 00 00 00 81 00 00 00 91 00 00 00 ad dc.l     $00000071,$00000081,$00000091,$000000AD
  002e9c:  00 00 00 b6 00 00 00 c0 00 00 00 d1 00 00 00 e0 dc.l     $000000B6,$000000C0,$000000D1,$000000E0
  002eac:  00 00 00 f0 00 00 00 03 00 00 00 00 00 00 01 20 dc.l     $000000F0,$00000003,$00000000,$00000120
  002ebc:  00 00 02 7e 00 00 00 73 00 00 00 43 00 00 00 74 dc.l     $0000027E,$00000073,$00000043,$00000074
  002ecc:  00 00 00 03 00 00 00 00 00 00 02 10 00 00 00 57 dc.l     $00000003,$00000000,$00000210,$00000057
  002edc:  00 00 00 05 00 00 00 05 00 00 00 5e 00 00 01 93 dc.l     $00000005,$00000005,$0000005E,$00000193
  002eec:  00 00 00 02 01 df 00 ff dc.l     $00000002,$01DF00FF
