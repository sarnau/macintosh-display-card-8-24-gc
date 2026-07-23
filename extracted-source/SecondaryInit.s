* ==========================================================================
*  SecondaryInit
*  Macintosh Display Card 8*24 GC  --  NuBus declaration ROM (Apple 341-0812)
*  Reconstructed 68020 assembly (MPW-style) from ROM image 341-0812.bin.
*  Comments/labels added by static analysis; mnemonics are literal.
* ==========================================================================
*
*  Called by the Slot Manager after the system is further up (sExecBlock at
*  ROM+$2F44, 68020, rev 2, $1B0 bytes).
*
* ==================================================================
* SecondaryInit  -  sExecBlock run after the system is further up
* ==================================================================
* Entry: A0 = SEBlock (Slot Manager sExec parameter block, from Slots.p).
*  SEBlock fields:  $00 seSlot  $01 sesRsrcId  $02 seStatus  $04 seFlags
*                   $08 seResult  $0C seIOFileName  $10 seDevice ...
* Enables the QuickDraw-GC-accelerated video sResource, but only if
* 32-Bit QuickDraw is actually present; otherwise the board stays a plain
* framebuffer.  Also fixes up the driver's framebuffer base pointer.
*
* Uses a stack-allocated SpBlock (Slots.p, $38 bytes: spResult,
* spsPointer, spSize, spOffsetData, spIOFileName, spsExecPBlk, spParamData,
* spMisc, spReserved, spIOReserved, spRefNum, spCategory, spCType, spDrvrSW,
* spDrvrHW, spTBMask, spSlot, spID, spExtDev, spHwDev, spByteLanes, spFlags,
* spKey) to make Slot Manager calls.  While A0 points into that frame it
* is tagged [sp*]; before that, [se*].
SecondaryInit:
  002f50:  31 7c 00 01 00 02    move.w   #$1, $2(a0)  ; [seStatus]
  002f56:  72 00                moveq    #$0, d1
  002f58:  10 10                move.b   (a0), d0  ; [seSlot]
  002f5a:  ef c1 00 04          bfins    d0, d1{0:4}
  002f5e:  24 41                movea.l  d1, a2
  002f60:  d5 fc 0c 00 00 00    adda.l   #$c000000, a2  ; VRAM/framebuffer +$0  A2 = frame-buffer base (slot base + $0C00'0000)
  002f66:  16 00                move.b   d0, d3
  002f68:  9e fc 00 38          suba.w   #$38, a7
  002f6c:  20 4f                movea.l  a7, a0
  002f6e:  2f 08                move.l   a0, -(a7)
* Is _Gestalt implemented?  (compare trap $AD address with the
* unimplemented-trap address $9F; likewise toolbox trap $303.)
  002f70:  30 3c 00 ad          move.w   #$ad, d0
  002f74:  a3 46                dc.w     $a346  ; _GetOSTrapAddress
  002f76:  26 48                movea.l  a0, a3
  002f78:  30 3c 00 9f          move.w   #$9f, d0
  002f7c:  a3 46                dc.w     $a346  ; _GetOSTrapAddress
  002f7e:  b7 c8                cmpa.l   a0, a3
  002f80:  66 18                bne.b    $2f9a  ; -> L2f9a
  002f82:  30 3c 03 03          move.w   #$303, d0
  002f86:  a7 46                dc.w     $a746  ; _GetToolBoxTrapAddress
  002f88:  26 48                movea.l  a0, a3
  002f8a:  30 3c 00 9f          move.w   #$9f, d0
  002f8e:  a7 46                dc.w     $a746  ; _GetToolBoxTrapAddress
  002f90:  b7 c8                cmpa.l   a0, a3
  002f92:  66 1a                bne.b    $2fae  ; -> L2fae
  002f94:  20 5f                movea.l  (a7)+, a0
  002f96:  60 00 01 38          bra.w    $30d0  ; -> L30d0
L2f9a:
  002f9a:  20 3c 71 64 20 20    move.l   #$71642020, d0  ; 'qd  '  Gestalt('qd  ') -> QuickDraw version
  002fa0:  a1 ad                dc.w     $a1ad  ; _Gestalt
  002fa2:  b0 fc 02 00          cmpa.w   #$200, a0  ; need 32-Bit QuickDraw (version >= $0200); else bail to cleanup
  002fa6:  6c 06                bge.b    $2fae  ; -> L2fae
  002fa8:  20 5f                movea.l  (a7)+, a0
  002faa:  60 00 01 24          bra.w    $30d0  ; -> L30d0
* Find this card's video sResource (sNextTypeSRsrc), read its info
* (sRsrcInfo) and flip the enabled/disabled state of the accelerated vs.
* plain sResource pair via sSetSRsrcState so QuickDraw GC binds to it.
L2fae:
  002fae:  20 5f                movea.l  (a7)+, a0
  002fb0:  11 43 00 31          move.b   d3, $31(a0)  ; [spSlot]
  002fb4:  42 28 00 32          clr.b    $32(a0)  ; [spID]
  002fb8:  31 7c 00 03 00 28    move.w   #$3, $28(a0)  ; [spCategory]
  002fbe:  31 7c 00 01 00 2a    move.w   #$1, $2a(a0)  ; [spCType]
  002fc4:  31 7c 00 01 00 2c    move.w   #$1, $2c(a0)  ; [spDrvrSW]
  002fca:  31 7c 00 1d 00 2e    move.w   #$1d, $2e(a0)  ; [spDrvrHW]
  002fd0:  42 38 00 30          clr.b    $30.w
  002fd4:  42 28 00 33          clr.b    $33(a0)  ; [spExtDev]
  002fd8:  70 15                moveq    #$15, d0
  002fda:  a0 6e                dc.w     $a06e  ; _SlotManager selector=sNextTypeSRsrc
  002fdc:  66 00 00 f2          bne.w    $30d0  ; -> L30d0
  002fe0:  b6 28 00 31          cmp.b    $31(a0), d3  ; [spSlot]
  002fe4:  66 00 00 ea          bne.w    $30d0  ; -> L30d0
  002fe8:  18 28 00 32          move.b   $32(a0), d4  ; [spID]
  002fec:  08 04 00 04          btst.b   #$4, d4
  002ff0:  67 00 00 de          beq.w    $30d0  ; -> L30d0
  002ff4:  14 04                move.b   d4, d2
  002ff6:  02 42 00 03          andi.w   #$3, d2
  002ffa:  70 16                moveq    #$16, d0
  002ffc:  a0 6e                dc.w     $a06e  ; _SlotManager selector=sRsrcInfo  sRsrcInfo
  002ffe:  3a 28 00 26          move.w   $26(a0), d5  ; [spRefNum]
  003002:  70 31                moveq    #$31, d0
  003004:  a0 6e                dc.w     $a06e  ; _SlotManager selector=0x31  sSetSRsrcState
  003006:  0c 02 00 00          cmpi.b   #$0, d2
  00300a:  66 10                bne.b    $301c  ; -> L301c
  00300c:  08 44 00 03          bchg.b   #$3, d4
  003010:  11 44 00 32          move.b   d4, $32(a0)  ; [spID]
  003014:  70 31                moveq    #$31, d0
  003016:  a0 6e                dc.w     $a06e  ; _SlotManager selector=0x31
  003018:  08 44 00 03          bchg.b   #$3, d4
L301c:
  00301c:  08 84 00 04          bclr.b   #$4, d4
  003020:  1c 04                move.b   d4, d6
  003022:  11 44 00 32          move.b   d4, $32(a0)  ; [spID]
  003026:  42 28 00 33          clr.b    $33(a0)  ; [spExtDev]
  00302a:  42 a8 00 04          clr.l    $4(a0)  ; [spsPointer]
  00302e:  31 45 00 26          move.w   d5, $26(a0)  ; [spRefNum]
  003032:  42 a8 00 18          clr.l    $18(a0)  ; [spParamData]
  003036:  70 0a                moveq    #$a, d0
  003038:  a0 6e                dc.w     $a06e  ; _SlotManager selector=0xa
  00303a:  51 4f                subq.w   #$8, a7
  00303c:  20 8f                move.l   a7, (a0)  ; [spResult]
  00303e:  70 11                moveq    #$11, d0
  003040:  a0 6e                dc.w     $a06e  ; _SlotManager selector=0x11
  003042:  1f 44 00 03          move.b   d4, $3(a7)
  003046:  21 4f 00 04          move.l   a7, $4(a0)  ; [spsPointer]
  00304a:  70 12                moveq    #$12, d0
  00304c:  a0 6e                dc.w     $a06e  ; _SlotManager selector=0x12
  00304e:  50 4f                addq.w   #$8, a7
  003050:  0c 02 00 00          cmpi.b   #$0, d2
  003054:  66 28                bne.b    $307e  ; -> L307e
  003056:  08 44 00 03          bchg.b   #$3, d4
  00305a:  11 44 00 32          move.b   d4, $32(a0)  ; [spID]
  00305e:  42 28 00 33          clr.b    $33(a0)  ; [spExtDev]
  003062:  42 a8 00 04          clr.l    $4(a0)  ; [spsPointer]
  003066:  42 68 00 26          clr.w    $26(a0)  ; [spRefNum]
  00306a:  21 7c 00 00 00 01 00 18 move.l   #$1, $18(a0)  ; [spParamData]
  003072:  70 0a                moveq    #$a, d0
  003074:  a0 6e                dc.w     $a06e  ; _SlotManager selector=0xa
  003076:  42 a8 00 18          clr.l    $18(a0)  ; [spParamData]
  00307a:  08 44 00 03          bchg.b   #$3, d4
* Patch the driver's dCtlStorage: set the framebuffer base
* ($4/$8 of storage) for the newly-selected mode.
L307e:
  00307e:  0c 45 00 00          cmpi.w   #$0, d5
  003082:  67 4c                beq.b    $30d0  ; -> L30d0
  003084:  20 78 08 a8          movea.l  $8a8.w, a0
  003088:  20 50                movea.l  (a0), a0  ; [spResult]
  00308a:  20 68 00 16          movea.l  $16(a0), a0
  00308e:  20 50                movea.l  (a0), a0  ; [spResult]
  003090:  02 44 00 03          andi.w   #$3, d4
  003094:  0c 04 00 00          cmpi.b   #$0, d4
  003098:  67 02                beq.b    $309c  ; -> L309c
  00309a:  60 08                bra.b    $30a4  ; -> L30a4
L309c:
  00309c:  d5 fc 00 01 14 00    adda.l   #$11400, a2  ; 8-bit page: base + $11400
  0030a2:  60 06                bra.b    $30aa  ; -> L30aa
L30a4:
  0030a4:  d5 fc 00 01 00 00    adda.l   #$10000, a2  ; shallow page: base + $10000
L30aa:
  0030aa:  20 8a                move.l   a2, (a0)  ; [spResult]
  0030ac:  52 45                addq.w   #$1, d5
  0030ae:  44 45                neg.w    d5
  0030b0:  e5 45                asl.w    #$2, d5
  0030b2:  26 78 01 1c          movea.l  $11c.w, a3
  0030b6:  26 73 50 00          movea.l  (a3, d5.w), a3
  0030ba:  26 53                movea.l  (a3), a3
  0030bc:  26 6b 00 14          movea.l  $14(a3), a3
  0030c0:  26 53                movea.l  (a3), a3
  0030c2:  08 ab 00 08 00 1c    bclr.b   #$8, $1c(a3)
  0030c8:  27 4a 00 04          move.l   a2, $4(a3)
  0030cc:  27 4a 00 08          move.l   a2, $8(a3)
* Cleanup / exit: seStatus handshake with the Slot Manager.
L30d0:
  0030d0:  55 4f                subq.w   #$2, a7
  0030d2:  20 4f                movea.l  a7, a0
  0030d4:  a0 80                dc.w     $a080  ; _GetVideoDefault
  0030d6:  b6 10                cmp.b    (a0), d3  ; [spResult]
  0030d8:  66 12                bne.b    $30ec  ; -> L30ec
  0030da:  08 c6 00 04          bset.b   #$4, d6
  0030de:  bc 28 00 01          cmp.b    $1(a0), d6
  0030e2:  66 08                bne.b    $30ec  ; -> L30ec
  0030e4:  08 a8 00 04 00 01    bclr.b   #$4, $1(a0)
  0030ea:  a0 81                dc.w     $a081  ; _SetVideoDefault
L30ec:
  0030ec:  54 4f                addq.w   #$2, a7
  0030ee:  de fc 00 38          adda.w   #$38, a7
  0030f2:  4e 75                rts      
