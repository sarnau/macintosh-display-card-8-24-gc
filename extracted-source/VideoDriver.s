* ==========================================================================
*  .Display_Video_Apple_MDCGC
*  Macintosh Display Card 8*24 GC  --  NuBus declaration ROM (Apple 341-0812)
*  Reconstructed 68020 assembly (MPW-style) from ROM image 341-0812.bin.
*  Comments/labels added by static analysis; mnemonics are literal.
* ==========================================================================
*
*  The Mac video driver held in the declaration ROM (DRVR record at
*  ROM+$358C, driver name '.Display_Video_Apple_MDCGC', flags $4C00 =
*  dNeedLock+dStatEnable+dCtlEnable).  Standard Slot-Manager video driver:
*  Open/Control/Status/Close.  Control and Status dispatch on csCode
*  ($1A of the ParamBlock) through the word-offset jump tables at $556A
*  and $5B18.
*
*  Register banks (base = card super-slot space, held in A4/$24(A3)):
*     base + $0400'00xx   MFB / control registers
*                         $44,$48,$4C = the three monitor SENSE lines
*     base + $04C0'0000   AC842 CLUT / colour-table port
*
*  Control csCodes : 0 Reset  1 KillIO  2 SetMode  3 SetEntries  4 SetGamma
*                    5 GrayPage  6 SetGray  7 SetInterrupt
*                    8 DirectSetEntries  9 SetDefaultMode
*  Status  csCodes : 2 GetMode  3 GetEntries  4 GetPages  5 GetBaseAddr
*                    6 GetGray  7 GetInterrupt  8 GetGamma
*                    9 GetDefaultMode  10 GetCurMode
*
* ==================================================================
* VideoOpen  -  driver Open routine  (JMFBDriver.a: "VideoOpen")
* ==================================================================
* Names below are recovered from the System 7.1 source: this ROM is the
* GC variant (.Display_Video_Apple_MDCGC) of .Display_Video_Apple_MDC,
* whose source is Drivers/Video/JMFBDriver.a + JMFBDepVideoEqu.a.
*
* Entry: A1 = DCE (Device Control Entry).  Allocates and initialises
* the private storage block, senses the monitor, selects the boot mode,
* installs the default colour table and returns.
*
* Private storage (A3 = deref'd DCE.dCtlStorage, $2E bytes).  Field names are
* the JMFB source's, mapped by role onto the GC layout ((a3) accesses below
* are tagged [fieldName]; the GC inserted rowBytes/vRes/modeTbl/depth so the
* offsets differ from the plain JMFB equates):
*    $00 saveMode       current mode index        $02 savePage    current page
*    $04 saveBaseAddr   current page base         $08 saveVidBase base ret'd to QD
*    $0C saveRowBytes   rowBytes (GC)             $0E saveVRes    active scanlines
*    $10 saveSQElPtr    slot-int queue element    $14 saveVidParms sResource params
*    $18 saveGammaPtr   ColorTable/GammaTbl       $1C GFlags      flag word
*    $1E moreGFlags     flag word 2               $20 saveModeTbl per-mon timing
*    $24 saveHardBase   card slot base            $28 saveID      sense/monitor id
*    $2A saveDepth      pixel depth (GC)          $2C savePageCfg page config
* GFlags bits: 15 GrayFlag 14 IntDisFlag 13 RAM512KFlag 12 MonoFlag
*              11 Interlaced 10 DirectModeFlag 9 BigScreen 8 sRsrc32Bit
* moreGFlags:  15 UnderScan 14 ConvOn 13 PAL 12 National
*
* Flag word GFlags ($1C here) bits (JMFBDepVideoEqu.a):
*    15 GrayFlag (luminance-mapped)   14 IntDisFlag (IRQs off)
*    13 RAM512KFlag                   12 MonoFlag (mono monitor)
*    11 Interlaced                    10 DirectModeFlag (24bpp direct)
*     9 BigScreen (Kong/Portrait)      8 sRsrc32Bit
* Flag word moreGFlags ($1E here): 15 UnderScan 14 ConvOn 13 PAL 12 National
VideoOpen:
  0052ee:  70 2e                moveq    #$2e, d0  ; reserve 46 bytes low in the system heap...
  0052f0:  a4 40                dc.w     $a440  ; _ReserveMem,SYS
  0052f2:  70 2e                moveq    #$2e, d0
  0052f4:  a7 22                dc.w     $a722  ; _NewHandle,SYS,CLEAR  ...then allocate them (dCtlStorage), cleared
  0052f6:  66 00 02 40          bne.w    $5538  ; -> L5538  alloc failed -> openErr
  0052fa:  23 48 00 14          move.l   a0, $14(a1)  ; DCE.dCtlStorage = handle
  0052fe:  a0 29                dc.w     $a029  ; _HLock
  005300:  20 10                move.l   (a0), d0
  005302:  a0 55                dc.w     $a055  ; _StripAddress
  005304:  26 40                movea.l  d0, a3  ; A3 = locked, stripped storage ptr
  005306:  72 00                moveq    #$0, d1
  005308:  10 29 00 28          move.b   $28(a1), d0  ; D0 = DCE.dCtlSlot (slot #)
  00530c:  ef c1 00 04          bfins    d0, d1{0:4}  ; build slot base F<s>00'0000 in D1
  005310:  20 41                movea.l  d1, a0
  005312:  27 48 00 24          move.l   a0, $24(a3)  ; [saveHardBase] slot base
  005316:  18 29 00 29          move.b   $29(a1), d4  ; D4 = DCE.dCtlSlotId (sResource id)
  00531a:  08 04 00 04          btst.b   #$4, d4
  00531e:  67 06                beq.b    $5326  ; -> L5326
  005320:  08 eb 00 08 00 1c    bset.b   #$8, $1c(a3)  ; [GFlags.sRsrc32Bit]
* Read the 3 primary SENSE lines -> 3-bit code in D1
L5326:
  005326:  70 01                moveq    #$1, d0
  005328:  a0 5d                dc.w     $a05d  ; _SwapMMUMode ->32-bit mode
  00532a:  3f 00                move.w   d0, -(a7)
  00532c:  72 00                moveq    #$0, d1
  00532e:  28 3c 04 00 00 44    move.l   #$4000044, d4  ; MFB reg +$44 (SENSE line 0)
  005334:  e9 f0 20 01 48 00    bfextu   (a0, d4.l){0:1}, d2
  00533a:  e5 4a                lsl.w    #$2, d2
  00533c:  d2 82                add.l    d2, d1
  00533e:  28 3c 04 00 00 48    move.l   #$4000048, d4  ; MFB reg +$48 (SENSE line 1)
  005344:  e9 f0 20 01 48 00    bfextu   (a0, d4.l){0:1}, d2
  00534a:  e3 4a                lsl.w    #$1, d2
  00534c:  d2 82                add.l    d2, d1
  00534e:  28 3c 04 00 00 4c    move.l   #$400004c, d4  ; MFB reg +$4c (SENSE line 2)
  005354:  e9 f0 20 01 48 00    bfextu   (a0, d4.l){0:1}, d2
  00535a:  d2 82                add.l    d2, d1
  00535c:  0c 01 00 07          cmpi.b   #$7, d1
  005360:  66 22                bne.b    $5384  ; -> L5384  sense 7 = extended-sense monitor, probe further
  005362:  28 48                movea.l  a0, a4
  005364:  61 00 0f 90          bsr.w    $62f6  ; -> XtdSense
  005368:  0c 00 00 14          cmpi.b   #$14, d0
  00536c:  66 06                bne.b    $5374  ; -> L5374
  00536e:  12 3c 00 04          move.b   #$4, d1
  005372:  60 1a                bra.b    $538e  ; -> L538e
L5374:
  005374:  0c 00 00 00          cmpi.b   #$0, d0
  005378:  66 04                bne.b    $537e  ; -> L537e
  00537a:  42 01                clr.b    d1
  00537c:  60 10                bra.b    $538e  ; -> L538e
L537e:
  00537e:  12 3c 00 09          move.b   #$9, d1
  005382:  60 0a                bra.b    $538e  ; -> L538e
* Map raw sense code to a boot mode / sResource selector in D1
L5384:
  005384:  0c 01 00 00          cmpi.b   #$0, d1
  005388:  66 04                bne.b    $538e  ; -> L538e
  00538a:  12 3c 00 07          move.b   #$7, d1
L538e:
  00538e:  30 1f                move.w   (a7)+, d0
  005390:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  005392:  37 41 00 28          move.w   d1, $28(a3)  ; [saveID] selected mode
  005396:  08 01 00 00          btst.b   #$0, d1
  00539a:  67 12                beq.b    $53ae  ; -> L53ae
  00539c:  08 81 00 02          bclr.b   #$2, d1
  0053a0:  66 0c                bne.b    $53ae  ; -> L53ae
  0053a2:  08 eb 00 0c 00 1c    bset.b   #$c, $1c(a3)  ; [GFlags.MonoFlag]
  0053a8:  08 eb 00 0f 00 1c    bset.b   #$f, $1c(a3)  ; [GFlags.GrayFlag]
* Select the per-monitor timing table and scan-line count by mode.
* lea targets point into the ROM data area ($35C0..$52ED).
L53ae:
  0053ae:  0c 01 00 02          cmpi.b   #$2, d1
  0053b2:  67 7c                beq.b    $5430  ; -> L5430
  0053b4:  0c 01 00 03          cmpi.b   #$3, d1
  0053b8:  67 00 00 82          beq.w    $543c  ; -> L543c
  0053bc:  0c 01 00 01          cmpi.b   #$1, d1
  0053c0:  67 00 00 86          beq.w    $5448  ; -> L5448
  0053c4:  0c 01 00 06          cmpi.b   #$6, d1
  0053c8:  67 00 00 8a          beq.w    $5454  ; -> L5454
  0053cc:  08 eb 00 0b 00 1c    bset.b   #$b, $1c(a3)  ; [GFlags.Interlaced]
  0053d2:  18 29 00 29          move.b   $29(a1), d4
  0053d6:  08 04 00 03          btst.b   #$3, d4
  0053da:  67 02                beq.b    $53de  ; -> L53de
  0053dc:  60 2a                bra.b    $5408  ; -> L5408
L53de:
  0053de:  08 eb 00 0d 00 1c    bset.b   #$d, $1c(a3)  ; [GFlags.RAM512KFlag]
  0053e4:  0c 01 00 04          cmpi.b   #$4, d1
  0053e8:  66 0c                bne.b    $53f6  ; -> L53f6
  0053ea:  37 7c 01 e0 00 0e    move.w   #$1e0, $e(a3)  ; [saveVRes]
  0053f0:  41 fa f0 8a          lea.l    $447c(pc), a0
  0053f4:  60 68                bra.b    $545e  ; -> L545e
L53f6:
  0053f6:  08 eb 00 0f 00 1e    bset.b   #$f, $1e(a3)  ; [moreGFlags.UnderScan]
  0053fc:  37 7c 02 40 00 0e    move.w   #$240, $e(a3)  ; [saveVRes]
  005402:  41 fa fc 10          lea.l    $5014(pc), a0
  005406:  60 56                bra.b    $545e  ; -> L545e
L5408:
  005408:  08 c1 00 03          bset.b   #$3, d1
  00540c:  0c 01 00 0c          cmpi.b   #$c, d1
  005410:  66 0c                bne.b    $541e  ; -> L541e
  005412:  37 7c 01 e0 00 0e    move.w   #$1e0, $e(a3)  ; [saveVRes]
  005418:  41 fa ea 96          lea.l    $3eb0(pc), a0
  00541c:  60 40                bra.b    $545e  ; -> L545e
L541e:
  00541e:  08 eb 00 0f 00 1e    bset.b   #$f, $1e(a3)  ; [moreGFlags.UnderScan]
  005424:  37 7c 02 40 00 0e    move.w   #$240, $e(a3)  ; [saveVRes]
  00542a:  41 fa f6 1c          lea.l    $4a48(pc), a0
  00542e:  60 2e                bra.b    $545e  ; -> L545e
L5430:
  005430:  37 7c 01 80 00 0e    move.w   #$180, $e(a3)  ; [saveVRes]
  005436:  41 fa e5 ec          lea.l    $3a24(pc), a0
  00543a:  60 22                bra.b    $545e  ; -> L545e
L543c:
  00543c:  37 7c 03 66 00 0e    move.w   #$366, $e(a3)  ; [saveVRes]
  005442:  41 fa e1 8e          lea.l    $35d2(pc), a0
  005446:  60 16                bra.b    $545e  ; -> L545e
L5448:
  005448:  37 7c 03 66 00 0e    move.w   #$366, $e(a3)  ; [saveVRes]
  00544e:  41 fa e2 d8          lea.l    $3728(pc), a0
  005452:  60 0a                bra.b    $545e  ; -> L545e
L5454:
  005454:  37 7c 01 e0 00 0e    move.w   #$1e0, $e(a3)  ; [saveVRes]
  00545a:  41 fa e4 22          lea.l    $387e(pc), a0
L545e:
  00545e:  27 48 00 20          move.l   a0, $20(a3)  ; [saveModeTbl] timing table ptr
  005462:  42 6b 00 2c          clr.w    $2c(a3)  ; [savePageCfg]
  005466:  37 7c 00 01 00 2a    move.w   #$1, $2a(a3)  ; [saveDepth]
  00546c:  70 10                moveq    #$10, d0
  00546e:  a7 1e                dc.w     $a71e  ; _NewPtrSysClear  alloc 16-byte slot-int queue element
  005470:  66 00 00 bc          bne.w    $552e  ; -> L552e
  005474:  27 48 00 10          move.l   a0, $10(a3)  ; [saveSQElPtr]
  005478:  61 00 05 a4          bsr.w    $5a1e  ; -> sub_5a1e  sub_5a1e: install the VBL slot interrupt
  00547c:  66 00 00 b0          bne.w    $552e  ; -> L552e
* Ask the Slot Manager for this sResource's video-parameter block
* (sNextTypeSRsrc/sFindStruct/sGetBlock).  On success point storage.$14/$18
* at it; on failure build a default 256-entry colour table instead.
  005480:  9e fc 00 38          suba.w   #$38, a7
  005484:  20 4f                movea.l  a7, a0
  005486:  11 69 00 28 00 31    move.b   $28(a1), $31(a0)
  00548c:  42 68 00 32          clr.w    $32(a0)
  005490:  42 28 00 30          clr.b    $30(a0)
  005494:  42 28 00 34          clr.b    $34(a0)
  005498:  31 7c 00 03 00 28    move.w   #$3, $28(a0)
  00549e:  31 7c 00 01 00 2a    move.w   #$1, $2a(a0)
  0054a4:  31 7c 00 01 00 2c    move.w   #$1, $2c(a0)
  0054aa:  31 7c 00 1d 00 2e    move.w   #$1d, $2e(a0)
  0054b0:  70 15                moveq    #$15, d0
  0054b2:  a0 6e                dc.w     $a06e  ; _SlotManager selector=sNextTypeSRsrc
  0054b4:  11 7c 00 40 00 32    move.b   #$40, $32(a0)
  0054ba:  70 06                moveq    #$6, d0
  0054bc:  a0 6e                dc.w     $a06e  ; _SlotManager selector=sFindStruct
  0054be:  11 7c 00 80 00 32    move.b   #$80, $32(a0)
  0054c4:  70 05                moveq    #$5, d0
  0054c6:  a0 6e                dc.w     $a06e  ; _SlotManager selector=sGetBlock
  0054c8:  66 20                bne.b    $54ea  ; -> L54ea
  0054ca:  20 50                movea.l  (a0), a0
  0054cc:  27 48 00 14          move.l   a0, $14(a3)  ; [saveVidParms]
  0054d0:  54 48                addq.w   #$2, a0
L54d2:
  0054d2:  4a 18                tst.b    (a0)+
  0054d4:  66 fc                bne.b    $54d2  ; -> L54d2
  0054d6:  52 48                addq.w   #$1, a0
  0054d8:  20 08                move.l   a0, d0
  0054da:  02 80 ff ff ff fe    andi.l   #$fffffffe, d0
  0054e0:  27 40 00 18          move.l   d0, $18(a3)  ; [saveGammaPtr]
  0054e4:  de fc 00 38          adda.w   #$38, a7
  0054e8:  60 40                bra.b    $552a  ; -> L552a
L54ea:
  0054ea:  de fc 00 38          adda.w   #$38, a7  ; no sResource block: build a default ColorTable
  0054ee:  70 0c                moveq    #$c, d0
  0054f0:  06 40 01 00          addi.w   #$100, d0
  0054f4:  a7 1e                dc.w     $a71e  ; _NewPtrSysClear
  0054f6:  66 36                bne.b    $552e  ; -> L552e
  0054f8:  27 48 00 18          move.l   a0, $18(a3)  ; [saveGammaPtr]
  0054fc:  27 48 00 14          move.l   a0, $14(a3)  ; [saveVidParms]
  005500:  31 7c 00 1d 00 02    move.w   #$1d, $2(a0)
  005506:  31 7c 00 01 00 06    move.w   #$1, $6(a0)
  00550c:  31 7c 01 00 00 08    move.w   #$100, $8(a0)
  005512:  31 7c 00 08 00 0a    move.w   #$8, $a(a0)
  005518:  d0 fc 00 0c          adda.w   #$c, a0
  00551c:  30 3c 00 ff          move.w   #$ff, d0
  005520:  72 00                moveq    #$0, d1
L5522:
  005522:  10 c1                move.b   d1, (a0)+  ; ...fill 256 identity entries
  005524:  52 41                addq.w   #$1, d1
  005526:  51 c8 ff fa          dbra     d0, $5522  ; -> L5522
L552a:
  00552a:  70 00                moveq    #$0, d0
L552c:
  00552c:  4e 75                rts
L552e:
  00552e:  20 69 00 14          movea.l  $14(a1), a0  ; error path: dispose handle, return error
  005532:  a0 23                dc.w     $a023  ; _DisposHandle
  005534:  70 94                moveq    #$94, d0
  005536:  60 f4                bra.b    $552c  ; -> L552c
L5538:
  005538:  70 e9                moveq    #$e9, d0  ; NewHandle failed -> openErr ($E9=-23)
  00553a:  60 f0                bra.b    $552c  ; -> L552c
* ==================================================================
* VideoCtl  -  driver Control routine
* ==================================================================
* Entry: A0 = ParamBlock (CntrlParam), A1 = DCE.
* A3 = storage, A2 = csParam ptr, D0 = csCode ($1A of the PB).
* Dispatch csCode 0..9 through ControlJumpTable.
VideoCtl:
  00553c:  2f 08                move.l   a0, -(a7)
  00553e:  20 09                move.l   a1, d0
  005540:  a0 55                dc.w     $a055  ; _StripAddress  A1 = stripped DCE
  005542:  22 40                movea.l  d0, a1
  005544:  26 69 00 14          movea.l  $14(a1), a3
  005548:  20 13                move.l   (a3), d0  ; [saveMode]
  00554a:  a0 55                dc.w     $a055  ; _StripAddress
  00554c:  26 40                movea.l  d0, a3  ; A3 = stripped storage
  00554e:  24 68 00 1c          movea.l  $1c(a0), a2
  005552:  20 0a                move.l   a2, d0
  005554:  a0 55                dc.w     $a055  ; _StripAddress
  005556:  24 40                movea.l  d0, a2  ; A2 = stripped csParam
  005558:  30 28 00 1a          move.w   $1a(a0), d0  ; D0 = csCode
  00555c:  0c 40 00 09          cmpi.w   #$9, d0  ; range-check 0..9
  005560:  62 1c                bhi.b    $557e  ; -> L557e
  005562:  30 3b 02 06          move.w   $556a(pc, d0.w), d0
  005566:  4e fb 00 02          jmp      $556a(pc, d0.w)  ; -> ControlJumpTable
ControlJumpTable:
* jump table (word offsets relative to $556A, indexed by selector*2):
  00556a:  00 20                dc.w     $0020    ; csCode 0 Reset -> Ctl_Reset
  00556c:  00 18                dc.w     $0018    ; csCode 1 KillIO -> Ctl_KillIO
  00556e:  00 42                dc.w     $0042    ; csCode 2 SetMode -> Ctl_SetMode
  005570:  00 c0                dc.w     $00C0    ; csCode 3 SetEntries -> Ctl_SetEntries
  005572:  02 40                dc.w     $0240    ; csCode 4 SetGamma -> Ctl_SetGamma
  005574:  03 90                dc.w     $0390    ; csCode 5 GrayPage -> Ctl_GrayPage
  005576:  04 30                dc.w     $0430    ; csCode 6 SetGray -> Ctl_SetGray
  005578:  04 4e                dc.w     $044E    ; csCode 7 SetInterrupt -> Ctl_SetInterrupt
  00557a:  05 1e                dc.w     $051E    ; csCode 8 DirectSetEntries -> Ctl_DirectSetEntries
  00557c:  05 32                dc.w     $0532    ; csCode 9 SetDefaultMode -> Ctl_SetDefaultMode
* Common exits: L557e=controlErr (-17, $EF), Ctl_KillIO=noErr
L557e:
  00557e:  70 ef                moveq    #$ef, d0
  005580:  60 02                bra.b    $5584  ; -> L5584
* return D0 as result and fall into IODone (GoIODone)
Ctl_KillIO:
  005582:  70 00                moveq    #$0, d0
L5584:
  005584:  20 5f                movea.l  (a7)+, a0
  005586:  60 00 07 28          bra.w    $5cb0  ; -> GoIODone
* csCode 0  cscReset  -  reset CLUT to gray and re-assert the mode
Ctl_Reset:
  00558a:  72 01                moveq    #$1, d1
  00558c:  34 bc 00 80          move.w   #$80, (a2)
  005590:  36 bc 00 80          move.w   #$80, (a3)  ; [saveMode]
  005594:  32 12                move.w   (a2), d1
  005596:  61 00 07 28          bsr.w    $5cc0  ; -> ChkMode
  00559a:  66 e2                bne.b    $557e  ; -> L557e
  00559c:  61 00 08 0a          bsr.w    $5da8  ; -> JMFBSetDepth
  0055a0:  25 6b 00 08 00 08    move.l   $8(a3), $8(a2)  ; [saveVidBase]
  0055a6:  61 00 0b ce          bsr.w    $6176  ; -> GrayScreen
  0055aa:  60 d6                bra.b    $5582  ; -> Ctl_KillIO
* csCode 2  cscSetMode  -  set video mode (depth) for a page.
* (A2)=new mode, $6(A2)=page.  Validate, program the AC842 + MFB, and
* if the mode actually changed clear the CLUT to a solid value.
Ctl_SetMode:
  0055ac:  32 12                move.w   (a2), d1
  0055ae:  61 00 07 10          bsr.w    $5cc0  ; -> ChkMode
  0055b2:  66 ca                bne.b    $557e  ; -> L557e
  0055b4:  30 2a 00 06          move.w   $6(a2), d0
  0055b8:  61 00 07 80          bsr.w    $5d3a  ; -> ChkPage  validate page -> ChkPage
  0055bc:  66 c0                bne.b    $557e  ; -> L557e
  0055be:  34 12                move.w   (a2), d2
  0055c0:  b4 53                cmp.w    (a3), d2  ; [saveMode] same mode already active? skip reprogram
  0055c2:  67 5c                beq.b    $5620  ; -> L5620
  0055c4:  36 92                move.w   (a2), (a3)  ; [saveMode]
  0055c6:  20 6b 00 18          movea.l  $18(a3), a0  ; [saveGammaPtr]
  0055ca:  36 28 00 04          move.w   $4(a0), d3
  0055ce:  34 28 00 08          move.w   $8(a0), d2
  0055d2:  e2 4a                lsr.w    #$1, d2
  0055d4:  41 e8 00 0c          lea.l    $c(a0), a0
  0055d8:  d0 c3                adda.w   d3, a0
  0055da:  16 30 20 00          move.b   (a0, d2.w), d3
  0055de:  20 6b 00 24          movea.l  $24(a3), a0  ; [saveHardBase]
  0055e2:  d1 fc 06 c0 00 04    adda.l   #$6c00004, a0  ; AC842 CLUT data port (R,G,B)  A0 = AC842 CLUT data port
  0055e8:  70 01                moveq    #$1, d0
  0055ea:  a0 5d                dc.w     $a05d  ; _SwapMMUMode ->32-bit mode
  0055ec:  3f 00                move.w   d0, -(a7)
  0055ee:  40 e7                move.w   sr, -(a7)
  0055f0:  70 07                moveq    #$7, d0
  0055f2:  c0 17                and.b    (a7), d0
  0055f4:  55 40                subq.w   #$2, d0
  0055f6:  6c 08                bge.b    $5600  ; -> L5600
  0055f8:  00 7c 02 00          ori.w    #$200, sr
  0055fc:  02 7c fa ff          andi.w   #$faff, sr
L5600:
  005600:  61 00 07 3c          bsr.w    $5d3e  ; -> WaitForVBlank
  005604:  42 28 ff fc          clr.b    -$4(a0)
  005608:  34 3c 00 ff          move.w   #$ff, d2
L560c:
  00560c:  10 83                move.b   d3, (a0)  ; clear all 256 CLUT entries to colour D3
  00560e:  10 83                move.b   d3, (a0)
  005610:  10 83                move.b   d3, (a0)
  005612:  51 ca ff f8          dbra     d2, $560c  ; -> L560c
  005616:  46 df                move.w   (a7)+, sr
  005618:  30 1f                move.w   (a7)+, d0
  00561a:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  00561c:  61 00 07 8a          bsr.w    $5da8  ; -> JMFBSetDepth  JMFBSetDepth: program MFB / pixel clock for the mode
L5620:
  005620:  25 6b 00 08 00 08    move.l   $8(a3), $8(a2)  ; [saveVidBase]
  005626:  60 00 ff 5a          bra.w    $5582  ; -> Ctl_KillIO
* csCode 3  cscSetEntries  -  load colour table entries into the CLUT.
* (A2)=ColorSpec array ptr, $4(A2)=start index (-1 = use .value fields),
* $6(A2)=count-1.  Gamma-corrects each entry (sub_5758) and, for mono
* monitors, converts RGB to luminance first.
Ctl_SetEntries:
  00562a:  20 12                move.l   (a2), d0
  00562c:  67 00 ff 50          beq.w    $557e  ; -> L557e
  005630:  08 2b 00 0a 00 1c    btst.b   #$a, $1c(a3)  ; [GFlags.DirectModeFlag] reject if CLUT not valid (direct mode)
  005636:  66 00 ff 46          bne.w    $557e  ; -> L557e
L563a:
  00563a:  48 e7 0f 0e          movem.l  d4-d7/a4-a6, -(a7)  ; (shared entry: also used by DirectSetEntries)
  00563e:  3a 2b 00 1c          move.w   $1c(a3), d5  ; [GFlags]
  005642:  20 6b 00 18          movea.l  $18(a3), a0  ; [saveGammaPtr]
  005646:  49 e8 00 0c          lea.l    $c(a0), a4
  00564a:  d8 e8 00 04          adda.w   $4(a0), a4
  00564e:  2a 4c                movea.l  a4, a5
  005650:  2c 4c                movea.l  a4, a6
  005652:  3e 28 00 0a          move.w   $a(a0), d7
  005656:  0c 68 00 01 00 06    cmpi.w   #$1, $6(a0)
  00565c:  67 12                beq.b    $5670  ; -> L5670
  00565e:  30 28 00 08          move.w   $8(a0), d0
  005662:  32 07                move.w   d7, d1
  005664:  5e 41                addq.w   #$7, d1
  005666:  e6 49                lsr.w    #$3, d1
  005668:  c0 c1                mulu.w   d1, d0
  00566a:  da c0                adda.w   d0, a5
  00566c:  dc c0                adda.w   d0, a6
  00566e:  dc c0                adda.w   d0, a6
L5670:
  005670:  32 13                move.w   (a3), d1  ; [saveMode]
  005672:  04 41 00 80          subi.w   #$80, d1
  005676:  47 fa fc 6c          lea.l    $52e4(pc), a3  ; $52E4 = per-mode max-index table
  00567a:  42 46                clr.w    d6
  00567c:  1c 33 10 00          move.b   (a3, d1.w), d6
  005680:  36 2a 00 06          move.w   $6(a2), d3
  005684:  0c 43 00 00          cmpi.w   #$0, d3
  005688:  6b 00 00 c6          bmi.w    $5750  ; -> L5750
  00568c:  b6 46                cmp.w    d6, d3
  00568e:  62 00 00 c0          bhi.w    $5750  ; -> L5750
  005692:  22 0f                move.l   a7, d1
  005694:  20 01                move.l   d1, d0
  005696:  44 40                neg.w    d0
  005698:  02 40 00 03          andi.w   #$3, d0
  00569c:  67 02                beq.b    $56a0  ; -> L56a0
  00569e:  9e c0                suba.w   d0, a7
L56a0:
  0056a0:  2f 01                move.l   d1, -(a7)
  0056a2:  28 03                move.l   d3, d4
  0056a4:  52 44                addq.w   #$1, d4
  0056a6:  e5 44                asl.w    #$2, d4
  0056a8:  9e c4                suba.w   d4, a7
  0056aa:  20 4f                movea.l  a7, a0
  0056ac:  20 12                move.l   (a2), d0
  0056ae:  a0 55                dc.w     $a055  ; _StripAddress
  0056b0:  26 40                movea.l  d0, a3
* Pass 1: build gamma-corrected/luminance ColorSpecs on the stack
L56b2:
  0056b2:  61 00 00 a4          bsr.w    $5758  ; -> sub_5758
  0056b6:  20 c2                move.l   d2, (a0)+
  0056b8:  51 cb ff f8          dbra     d3, $56b2  ; -> L56b2
  0056bc:  36 2a 00 06          move.w   $6(a2), d3
  0056c0:  26 69 00 14          movea.l  $14(a1), a3
  0056c4:  20 13                move.l   (a3), d0  ; [saveMode]
  0056c6:  a0 55                dc.w     $a055  ; _StripAddress
  0056c8:  26 40                movea.l  d0, a3
  0056ca:  70 01                moveq    #$1, d0
  0056cc:  a0 5d                dc.w     $a05d  ; _SwapMMUMode ->32-bit mode
  0056ce:  22 00                move.l   d0, d1
  0056d0:  40 c6                move.w   sr, d6
  0056d2:  e9 c6 05 c3          bfextu   d6{23:3}, d0
  0056d6:  55 40                subq.w   #$2, d0
  0056d8:  6c 08                bge.b    $56e2  ; -> L56e2
  0056da:  00 7c 02 00          ori.w    #$200, sr
  0056de:  02 7c fa ff          andi.w   #$faff, sr
L56e2:
  0056e2:  61 00 06 5a          bsr.w    $5d3e  ; -> WaitForVBlank
  0056e6:  26 6b 00 24          movea.l  $24(a3), a3  ; [saveHardBase]
  0056ea:  d7 fc 06 c0 00 04    adda.l   #$6c00004, a3  ; AC842 CLUT data port (R,G,B)
  0056f0:  3e 2a 00 04          move.w   $4(a2), d7
  0056f4:  6a 26                bpl.b    $571c  ; -> L571c
* Pass 2: write them to the AC842 CLUT under interrupts-off + VBL sync.
* bit C of flags -> pad the two unused DAC bytes with 0 (mono/8-bit path).
L56f6:
  0056f6:  24 1f                move.l   (a7)+, d2
  0056f8:  17 42 ff fc          move.b   d2, -$4(a3)  ; [saveBaseAddr]
  0056fc:  e0 8a                lsr.l    #$8, d2
  0056fe:  08 05 00 0c          btst.b   #$c, d5
  005702:  67 08                beq.b    $570c  ; -> L570c
  005704:  42 13                clr.b    (a3)  ; [saveMode]
  005706:  42 13                clr.b    (a3)  ; [saveMode]
  005708:  16 82                move.b   d2, (a3)  ; [saveMode]
  00570a:  60 0a                bra.b    $5716  ; -> L5716
L570c:
  00570c:  16 82                move.b   d2, (a3)  ; [saveMode]
  00570e:  e0 8a                lsr.l    #$8, d2
  005710:  16 82                move.b   d2, (a3)  ; [saveMode]
  005712:  e0 8a                lsr.l    #$8, d2
  005714:  16 82                move.b   d2, (a3)  ; [saveMode]
L5716:
  005716:  51 cb ff de          dbra     d3, $56f6  ; -> L56f6
  00571a:  60 24                bra.b    $5740  ; -> L5740
L571c:
  00571c:  17 47 ff fc          move.b   d7, -$4(a3)  ; [saveBaseAddr]
L5720:
  005720:  24 1f                move.l   (a7)+, d2
  005722:  e0 8a                lsr.l    #$8, d2
  005724:  08 05 00 0c          btst.b   #$c, d5
  005728:  67 08                beq.b    $5732  ; -> L5732
  00572a:  42 13                clr.b    (a3)  ; [saveMode]
  00572c:  42 13                clr.b    (a3)  ; [saveMode]
  00572e:  16 82                move.b   d2, (a3)  ; [saveMode]
  005730:  60 0a                bra.b    $573c  ; -> L573c
L5732:
  005732:  16 82                move.b   d2, (a3)  ; [saveMode]
  005734:  e0 8a                lsr.l    #$8, d2
  005736:  16 82                move.b   d2, (a3)  ; [saveMode]
  005738:  e0 8a                lsr.l    #$8, d2
  00573a:  16 82                move.b   d2, (a3)  ; [saveMode]
L573c:
  00573c:  51 cb ff e2          dbra     d3, $5720  ; -> L5720
L5740:
  005740:  20 01                move.l   d1, d0
  005742:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  005744:  46 c6                move.w   d6, sr
  005746:  2e 5f                movea.l  (a7)+, a7
  005748:  4c df 70 f0          movem.l  (a7)+, d4-d7/a4-a6
  00574c:  60 00 fe 34          bra.w    $5582  ; -> Ctl_KillIO
L5750:
  005750:  4c df 70 f0          movem.l  (a7)+, d4-d7/a4-a6
  005754:  60 00 fe 28          bra.w    $557e  ; -> L557e
* sub_5758  -  produce one gamma-corrected CLUT triple.
* Reads value+R,G,B from (A3); if mono (D5 flags) folds RGB to luminance
* using the NTSC weights $4CCC/$970A/$1C29 (0.30/0.59/0.11); indexes the
* per-channel gamma tables A4/A5/A6; returns packed value|R|G|B in D2.
sub_5758:
  005758:  2f 03                move.l   d3, -(a7)
  00575a:  36 1b                move.w   (a3)+, d3  ; [saveMode]
  00575c:  30 1b                move.w   (a3)+, d0  ; [saveMode]
  00575e:  32 1b                move.w   (a3)+, d1  ; [saveMode]
  005760:  34 1b                move.w   (a3)+, d2  ; [saveMode]
  005762:  4a 45                tst.w    d5
  005764:  6a 20                bpl.b    $5786  ; -> L5786
  005766:  08 05 00 0a          btst.b   #$a, d5
  00576a:  66 1a                bne.b    $5786  ; -> L5786
  00576c:  c0 fc 4c cc          mulu.w   #$4ccc, d0  ; R * 0.299
  005770:  c2 fc 97 0a          mulu.w   #$970a, d1  ; G * 0.587
  005774:  c4 fc 1c 29          mulu.w   #$1c29, d2  ; B * 0.114
  005778:  d0 81                add.l    d1, d0
  00577a:  d0 82                add.l    d2, d0
  00577c:  e9 c0 10 27          bfextu   d0{0:7}, d1
  005780:  30 01                move.w   d1, d0
  005782:  34 01                move.w   d1, d2
  005784:  60 0c                bra.b    $5792  ; -> L5792
L5786:
  005786:  e9 c0 04 27          bfextu   d0{16:7}, d0
  00578a:  e9 c1 14 27          bfextu   d1{16:7}, d1
  00578e:  e9 c2 24 27          bfextu   d2{16:7}, d2
L5792:
  005792:  14 36 20 00          move.b   (a6, d2.w), d2
  005796:  e1 8a                lsl.l    #$8, d2
  005798:  14 35 10 00          move.b   (a5, d1.w), d2
  00579c:  e1 8a                lsl.l    #$8, d2
  00579e:  14 34 00 00          move.b   (a4, d0.w), d2
  0057a2:  e1 8a                lsl.l    #$8, d2
  0057a4:  14 03                move.b   d3, d2
  0057a6:  26 1f                move.l   (a7)+, d3
  0057a8:  4e 75                rts
* csCode 4  cscSetGamma  -  install a new gamma table.
* (A2)=GammaTbl ptr (0 = restore default linear gamma).  Validates the
* table, copies it into a freshly-allocated buffer (storage.$18) and, if
* the CLUT is live, re-applies the gamma to the AC842.
Ctl_SetGamma:
  0057aa:  20 12                move.l   (a2), d0
  0057ac:  67 00 00 a4          beq.w    $5852  ; -> L5852
  0057b0:  24 40                movea.l  d0, a2
  0057b2:  4a 52                tst.w    (a2)
  0057b4:  66 00 fd c8          bne.w    $557e  ; -> L557e
  0057b8:  0c 6b 00 06 00 28    cmpi.w   #$6, $28(a3)  ; [saveID]
  0057be:  66 06                bne.b    $57c6  ; -> L57c6
  0057c0:  4a 6a 00 02          tst.w    $2(a2)
  0057c4:  67 20                beq.b    $57e6  ; -> L57e6
L57c6:
  0057c6:  0c 6a 00 1d 00 02    cmpi.w   #$1d, $2(a2)
  0057cc:  66 00 fd b0          bne.w    $557e  ; -> L557e
  0057d0:  4a 6a 00 04          tst.w    $4(a2)
  0057d4:  67 10                beq.b    $57e6  ; -> L57e6
  0057d6:  30 2a 00 0c          move.w   $c(a2), d0
  0057da:  b0 6b 00 28          cmp.w    $28(a3), d0  ; [saveID]
  0057de:  67 06                beq.b    $57e6  ; -> L57e6
  0057e0:  52 40                addq.w   #$1, d0
  0057e2:  66 00 fd 9a          bne.w    $557e  ; -> L557e
L57e6:
  0057e6:  20 6b 00 18          movea.l  $18(a3), a0  ; [saveGammaPtr]
  0057ea:  30 2a 00 04          move.w   $4(a2), d0
  0057ee:  b0 68 00 04          cmp.w    $4(a0), d0
  0057f2:  66 12                bne.b    $5806  ; -> L5806
  0057f4:  30 2a 00 06          move.w   $6(a2), d0
  0057f8:  b0 68 00 06          cmp.w    $6(a0), d0
  0057fc:  67 32                beq.b    $5830  ; -> L5830
  0057fe:  6e 06                bgt.b    $5806  ; -> L5806
  005800:  a0 1f                dc.w     $a01f  ; _DisposePtr
  005802:  42 ab 00 18          clr.l    $18(a3)  ; [saveGammaPtr]
L5806:
  005806:  30 2a 00 08          move.w   $8(a2), d0
  00580a:  c0 ea 00 06          mulu.w   $6(a2), d0
  00580e:  d0 6a 00 04          add.w    $4(a2), d0
  005812:  06 40 00 0c          addi.w   #$c, d0
  005816:  a5 1e                dc.w     $a51e  ; _NewPtrSys
  005818:  66 00 fd 64          bne.w    $557e  ; -> L557e
  00581c:  20 2b 00 18          move.l   $18(a3), d0  ; [saveGammaPtr]
  005820:  27 48 00 18          move.l   a0, $18(a3)  ; [saveGammaPtr]
  005824:  4a 80                tst.l    d0
  005826:  67 08                beq.b    $5830  ; -> L5830
  005828:  20 40                movea.l  d0, a0
  00582a:  a0 1f                dc.w     $a01f  ; _DisposePtr
  00582c:  20 6b 00 18          movea.l  $18(a3), a0  ; [saveGammaPtr]
L5830:
  005830:  30 2a 00 06          move.w   $6(a2), d0
  005834:  32 2a 00 04          move.w   $4(a2), d1
  005838:  34 2a 00 08          move.w   $8(a2), d2
  00583c:  20 da                move.l   (a2)+, (a0)+
  00583e:  20 da                move.l   (a2)+, (a0)+
  005840:  20 da                move.l   (a2)+, (a0)+
  005842:  c4 c0                mulu.w   d0, d2
  005844:  d4 41                add.w    d1, d2
  005846:  53 42                subq.w   #$1, d2
L5848:
  005848:  10 1a                move.b   (a2)+, d0
  00584a:  10 c0                move.b   d0, (a0)+
  00584c:  51 ca ff fa          dbra     d2, $5848  ; -> L5848
  005850:  60 24                bra.b    $5876  ; -> L5876
L5852:
  005852:  20 6b 00 18          movea.l  $18(a3), a0  ; [saveGammaPtr] csParam=0: rebuild the default (inverting) gamma ramp
  005856:  30 28 00 04          move.w   $4(a0), d0
  00585a:  34 28 00 06          move.w   $6(a0), d2
  00585e:  53 42                subq.w   #$1, d2
  005860:  d0 fc 00 0c          adda.w   #$c, a0
  005864:  d0 c0                adda.w   d0, a0
L5866:
  005866:  30 3c 00 ff          move.w   #$ff, d0
L586a:
  00586a:  10 80                move.b   d0, (a0)
  00586c:  46 18                not.b    (a0)+
  00586e:  51 c8 ff fa          dbra     d0, $586a  ; -> L586a
  005872:  51 ca ff f2          dbra     d2, $5866  ; -> L5866
* If CLUT is valid, push the new gamma through all 256 AC842 entries
L5876:
  005876:  08 2b 00 0a 00 1c    btst.b   #$a, $1c(a3)  ; [GFlags.DirectModeFlag]
  00587c:  67 00 fd 04          beq.w    $5582  ; -> Ctl_KillIO
  005880:  20 6b 00 18          movea.l  $18(a3), a0  ; [saveGammaPtr]
  005884:  49 e8 00 0c          lea.l    $c(a0), a4
  005888:  d8 e8 00 04          adda.w   $4(a0), a4
  00588c:  2a 4c                movea.l  a4, a5
  00588e:  2c 4c                movea.l  a4, a6
  005890:  3e 28 00 0a          move.w   $a(a0), d7
  005894:  0c 68 00 01 00 06    cmpi.w   #$1, $6(a0)
  00589a:  67 12                beq.b    $58ae  ; -> L58ae
  00589c:  30 28 00 08          move.w   $8(a0), d0
  0058a0:  32 07                move.w   d7, d1
  0058a2:  5e 41                addq.w   #$7, d1
  0058a4:  e6 49                lsr.w    #$3, d1
  0058a6:  c0 c1                mulu.w   d1, d0
  0058a8:  da c0                adda.w   d0, a5
  0058aa:  dc c0                adda.w   d0, a6
  0058ac:  dc c0                adda.w   d0, a6
L58ae:
  0058ae:  20 6b 00 24          movea.l  $24(a3), a0  ; [saveHardBase]
  0058b2:  d1 fc 06 c0 00 04    adda.l   #$6c00004, a0  ; AC842 CLUT data port (R,G,B)
  0058b8:  70 01                moveq    #$1, d0
  0058ba:  a0 5d                dc.w     $a05d  ; _SwapMMUMode ->32-bit mode
  0058bc:  2f 00                move.l   d0, -(a7)
  0058be:  40 e7                move.w   sr, -(a7)
  0058c0:  70 07                moveq    #$7, d0
  0058c2:  c0 17                and.b    (a7), d0
  0058c4:  55 40                subq.w   #$2, d0
  0058c6:  6c 08                bge.b    $58d0  ; -> L58d0
  0058c8:  00 7c 02 00          ori.w    #$200, sr
  0058cc:  02 7c fa ff          andi.w   #$faff, sr
L58d0:
  0058d0:  61 00 04 6c          bsr.w    $5d3e  ; -> WaitForVBlank
  0058d4:  42 28 ff fc          clr.b    -$4(a0)
  0058d8:  30 3c 00 ff          move.w   #$ff, d0
  0058dc:  72 00                moveq    #$0, d1
L58de:
  0058de:  10 b4 10 00          move.b   (a4, d1.w), (a0)
  0058e2:  10 b5 10 00          move.b   (a5, d1.w), (a0)
  0058e6:  10 b6 10 00          move.b   (a6, d1.w), (a0)
  0058ea:  52 41                addq.w   #$1, d1
  0058ec:  51 c8 ff f0          dbra     d0, $58de  ; -> L58de
  0058f0:  46 df                move.w   (a7)+, sr
  0058f2:  20 1f                move.l   (a7)+, d0
  0058f4:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  0058f6:  60 00 fc 8a          bra.w    $5582  ; -> Ctl_KillIO
* csCode 5  cscGrayPage  -  fill a page with 50% gray.
* (A2)=page.  Programs the mode, gray-fills the framebuffer (GrayScreen)
* and reloads the CLUT/gamma.
Ctl_GrayPage:
  0058fa:  32 13                move.w   (a3), d1  ; [saveMode]
  0058fc:  34 81                move.w   d1, (a2)
  0058fe:  61 00 03 c0          bsr.w    $5cc0  ; -> ChkMode
  005902:  66 00 fc 7a          bne.w    $557e  ; -> L557e
  005906:  30 2a 00 06          move.w   $6(a2), d0
  00590a:  61 00 04 2e          bsr.w    $5d3a  ; -> ChkPage
  00590e:  66 00 fc 6e          bne.w    $557e  ; -> L557e
  005912:  61 00 08 62          bsr.w    $6176  ; -> GrayScreen
  005916:  08 2b 00 0a 00 1c    btst.b   #$a, $1c(a3)  ; [GFlags.DirectModeFlag]
  00591c:  67 00 fc 64          beq.w    $5582  ; -> Ctl_KillIO
  005920:  20 6b 00 18          movea.l  $18(a3), a0  ; [saveGammaPtr]
  005924:  49 e8 00 0c          lea.l    $c(a0), a4
  005928:  d8 e8 00 04          adda.w   $4(a0), a4
  00592c:  2a 4c                movea.l  a4, a5
  00592e:  2c 4c                movea.l  a4, a6
  005930:  3e 28 00 0a          move.w   $a(a0), d7
  005934:  0c 68 00 01 00 06    cmpi.w   #$1, $6(a0)
  00593a:  67 12                beq.b    $594e  ; -> L594e
  00593c:  30 28 00 08          move.w   $8(a0), d0
  005940:  32 07                move.w   d7, d1
  005942:  5e 41                addq.w   #$7, d1
  005944:  e6 49                lsr.w    #$3, d1
  005946:  c0 c1                mulu.w   d1, d0
  005948:  da c0                adda.w   d0, a5
  00594a:  dc c0                adda.w   d0, a6
  00594c:  dc c0                adda.w   d0, a6
L594e:
  00594e:  70 01                moveq    #$1, d0
  005950:  a0 5d                dc.w     $a05d  ; _SwapMMUMode ->32-bit mode
  005952:  2f 00                move.l   d0, -(a7)
  005954:  40 e7                move.w   sr, -(a7)
  005956:  70 07                moveq    #$7, d0
  005958:  c0 17                and.b    (a7), d0
  00595a:  55 40                subq.w   #$2, d0
  00595c:  6c 08                bge.b    $5966  ; -> L5966
  00595e:  00 7c 02 00          ori.w    #$200, sr
  005962:  02 7c fa ff          andi.w   #$faff, sr
L5966:
  005966:  61 00 03 d6          bsr.w    $5d3e  ; -> WaitForVBlank
  00596a:  20 6b 00 24          movea.l  $24(a3), a0  ; [saveHardBase]
  00596e:  d1 fc 06 c0 00 04    adda.l   #$6c00004, a0  ; AC842 CLUT data port (R,G,B)
  005974:  42 28 ff fc          clr.b    -$4(a0)
  005978:  30 3c 00 ff          move.w   #$ff, d0
  00597c:  72 00                moveq    #$0, d1
L597e:
  00597e:  10 b4 10 00          move.b   (a4, d1.w), (a0)
  005982:  10 b5 10 00          move.b   (a5, d1.w), (a0)
  005986:  10 b6 10 00          move.b   (a6, d1.w), (a0)
  00598a:  52 41                addq.w   #$1, d1
  00598c:  51 c8 ff f0          dbra     d0, $597e  ; -> L597e
  005990:  46 df                move.w   (a7)+, sr
  005992:  20 1f                move.l   (a7)+, d0
  005994:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  005996:  60 00 fb ea          bra.w    $5582  ; -> Ctl_KillIO
* csCode 6  cscSetGray  -  select colour vs. luminance (gray) CLUT.
* (A2).b = 0 colour / 1 luminance.  Stored in flag bit 0 via sub_59ae.
Ctl_SetGray:
  00599a:  08 2b 00 0c 00 1c    btst.b   #$c, $1c(a3)  ; [GFlags.MonoFlag]
  0059a0:  67 04                beq.b    $59a6  ; -> L59a6
  0059a2:  14 bc 00 01          move.b   #$1, (a2)
L59a6:
  0059a6:  72 00                moveq    #$0, d1
  0059a8:  61 04                bsr.b    $59ae  ; -> sub_59ae
  0059aa:  60 00 fb d6          bra.w    $5582  ; -> Ctl_KillIO
* sub_59ae  -  store one bit of (A2) into storage flag bit D1
* (D1=0 -> luminance flag, D1=1 -> interrupt-enable flag).
sub_59ae:
  0059ae:  10 12                move.b   (a2), d0
  0059b0:  ef eb 08 41 00 1c    bfins    d0, $1c(a3){1:1}  ; [GFlags]
  0059b6:  4e 75                rts
* csCode 7  cscSetInterrupt  -  enable/disable VBL interrupts.
* (A2).b = 0 enable / 1 disable.  Installs (sub_5a1e) or removes
* (sub_59ce) the slot VBL interrupt handler accordingly.
Ctl_SetInterrupt:
  0059b8:  72 01                moveq    #$1, d1
  0059ba:  61 f2                bsr.b    $59ae  ; -> sub_59ae
  0059bc:  66 0a                bne.b    $59c8  ; -> L59c8
  0059be:  61 5e                bsr.b    $5a1e  ; -> sub_5a1e
  0059c0:  66 00 fb bc          bne.w    $557e  ; -> L557e
  0059c4:  60 00 fb bc          bra.w    $5582  ; -> Ctl_KillIO
L59c8:
  0059c8:  61 04                bsr.b    $59ce  ; -> sub_59ce
  0059ca:  60 00 fb b6          bra.w    $5582  ; -> Ctl_KillIO
* sub_59ce  -  disable and remove the card VBL interrupt.
* Turns the IRQ off in the serial-ctl port, clears the IRQ reg, and
* _SIntRemove's the slot queue element (storage.$10).
sub_59ce:
  0059ce:  48 e7 f8 88          movem.l  d0-d4/a0/a4, -(a7)
  0059d2:  70 01                moveq    #$1, d0
  0059d4:  a0 5d                dc.w     $a05d  ; _SwapMMUMode ->32-bit mode
  0059d6:  26 00                move.l   d0, d3
  0059d8:  40 e7                move.w   sr, -(a7)
  0059da:  70 07                moveq    #$7, d0
  0059dc:  c0 17                and.b    (a7), d0
  0059de:  55 40                subq.w   #$2, d0
  0059e0:  6c 04                bge.b    $59e6  ; -> L59e6
  0059e2:  02 7c fa ff          andi.w   #$faff, sr
L59e6:
  0059e6:  42 40                clr.w    d0
  0059e8:  10 29 00 28          move.b   $28(a1), d0
  0059ec:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  0059f0:  28 3c 04 c0 00 00    move.l   #$4c00000, d4  ; control serial port (mode/IRQ)
  0059f6:  72 03                moveq    #$3, d1
  0059f8:  74 0c                moveq    #$c, d2
  0059fa:  4e ba 08 a0          jsr      $629c(pc)  ; -> SerialShiftOut
  0059fe:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005a02:  28 3c 04 40 00 3c    move.l   #$440003c, d4  ; MFB IRQ +$3c (IRQ clear reg)
  005a08:  42 b4 48 00          clr.l    (a4, d4.l)
  005a0c:  20 03                move.l   d3, d0
  005a0e:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  005a10:  20 6b 00 10          movea.l  $10(a3), a0  ; [saveSQElPtr]
  005a14:  a0 76                dc.w     $a076  ; _SIntRemove
  005a16:  46 df                move.w   (a7)+, sr
  005a18:  4c df 11 1f          movem.l  (a7)+, d0-d4/a0/a4
  005a1c:  4e 75                rts
* sub_5a1e  -  install the slot VBL interrupt handler.
* Fills the SlotIntQElement (storage.$10): siInterval=6,
* siIntHandler=VBLInterruptTask, and points it at the card IRQ reg;
* _SIntInstall's it, then enables the card IRQ.  Returns D0 status.
sub_5a1e:
  005a1e:  48 e7 c8 a8          movem.l  d0-d1/d4/a0/a2/a4, -(a7)
  005a22:  45 fa 08 96          lea.l    $62ba(pc), a2
  005a26:  20 0a                move.l   a2, d0
  005a28:  a0 55                dc.w     $a055  ; _StripAddress
  005a2a:  24 40                movea.l  d0, a2
  005a2c:  20 6b 00 10          movea.l  $10(a3), a0  ; [saveSQElPtr]
  005a30:  31 7c 00 06 00 04    move.w   #$6, $4(a0)
  005a36:  21 4a 00 08          move.l   a2, $8(a0)
  005a3a:  24 6b 00 24          movea.l  $24(a3), a2  ; [saveHardBase]
  005a3e:  d5 fc 04 40 00 48    adda.l   #$4400048, a2  ; MFB IRQ +$48 (IRQ status/flag reg)
  005a44:  21 4a 00 0c          move.l   a2, $c(a0)
  005a48:  70 00                moveq    #$0, d0
  005a4a:  10 29 00 28          move.b   $28(a1), d0
  005a4e:  a0 75                dc.w     $a075  ; _SIntInstall
  005a50:  66 2e                bne.b    $5a80  ; -> L5a80
  005a52:  70 01                moveq    #$1, d0
  005a54:  a0 5d                dc.w     $a05d  ; _SwapMMUMode ->32-bit mode
  005a56:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005a5a:  28 3c 04 c0 00 00    move.l   #$4c00000, d4  ; control serial port (mode/IRQ)
  005a60:  72 01                moveq    #$1, d1
  005a62:  74 0c                moveq    #$c, d2
  005a64:  4e ba 08 36          jsr      $629c(pc)  ; -> SerialShiftOut
  005a68:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005a6c:  28 3c 04 40 00 3c    move.l   #$440003c, d4  ; MFB IRQ +$3c (IRQ clear reg)
  005a72:  42 b4 48 00          clr.l    (a4, d4.l)
  005a76:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  005a78:  b2 41                cmp.w    d1, d1
  005a7a:  4c df 15 13          movem.l  (a7)+, d0-d1/d4/a0/a2/a4
  005a7e:  4e 75                rts
L5a80:
  005a80:  4c df 15 13          movem.l  (a7)+, d0-d1/d4/a0/a2/a4
  005a84:  70 01                moveq    #$1, d0
  005a86:  4e 75                rts
* csCode 8  cscDirectSetEntries  -  set entries in direct (16/32-bit)
* colour mode.  Requires the CLUT-valid flag; shares SetEntries code (L563a).
Ctl_DirectSetEntries:
  005a88:  20 12                move.l   (a2), d0
  005a8a:  67 00 fa f2          beq.w    $557e  ; -> L557e
  005a8e:  08 2b 00 0a 00 1c    btst.b   #$a, $1c(a3)  ; [GFlags.DirectModeFlag]
  005a94:  67 00 fa e8          beq.w    $557e  ; -> L557e
  005a98:  60 00 fb a0          bra.w    $563a  ; -> L563a
* csCode 9  cscSetDefaultMode  -  save (A2).b as the power-on mode
* in this slot's PRAM (Slot Manager sReadPRAMRec/sPutPRAMRec).
Ctl_SetDefaultMode:
  005a9c:  9e fc 00 38          suba.w   #$38, a7
  005aa0:  20 4f                movea.l  a7, a0
  005aa2:  11 69 00 28 00 31    move.b   $28(a1), $31(a0)
  005aa8:  42 28 00 33          clr.b    $33(a0)
  005aac:  51 4f                subq.w   #$8, a7
  005aae:  20 8f                move.l   a7, (a0)
  005ab0:  70 11                moveq    #$11, d0
  005ab2:  a0 6e                dc.w     $a06e  ; _SlotManager selector=0x11
  005ab4:  1f 52 00 03          move.b   (a2), $3(a7)
  005ab8:  21 4f 00 04          move.l   a7, $4(a0)
  005abc:  70 12                moveq    #$12, d0
  005abe:  a0 6e                dc.w     $a06e  ; _SlotManager selector=0x12
  005ac0:  de fc 00 40          adda.w   #$40, a7
  005ac4:  60 00 fa bc          bra.w    $5582  ; -> Ctl_KillIO
  005ac8:  60 00 fa b8          bra.w    $5582  ; -> Ctl_KillIO
* ==================================================================
* VideoClose  -  driver Close routine
* ==================================================================
* Removes the VBL interrupt and frees the queue element, the parameter
* block and the storage handle.
VideoClose:
  005acc:  20 09                move.l   a1, d0
  005ace:  a0 55                dc.w     $a055  ; _StripAddress
  005ad0:  22 40                movea.l  d0, a1
  005ad2:  26 69 00 14          movea.l  $14(a1), a3
  005ad6:  20 13                move.l   (a3), d0  ; [saveMode]
  005ad8:  a0 55                dc.w     $a055  ; _StripAddress
  005ada:  26 40                movea.l  d0, a3
  005adc:  61 00 fe f0          bsr.w    $59ce  ; -> sub_59ce
  005ae0:  20 6b 00 10          movea.l  $10(a3), a0  ; [saveSQElPtr]
  005ae4:  a0 1f                dc.w     $a01f  ; _DisposePtr
  005ae6:  20 6b 00 14          movea.l  $14(a3), a0  ; [saveVidParms]
  005aea:  a0 1f                dc.w     $a01f  ; _DisposePtr
  005aec:  20 69 00 14          movea.l  $14(a1), a0
  005af0:  a0 23                dc.w     $a023  ; _DisposHandle
  005af2:  70 00                moveq    #$0, d0
  005af4:  4e 75                rts
* ==================================================================
* VideoStatus  -  driver Status routine
* ==================================================================
* Entry as Control.  Dispatch csCode 0..10 through StatusJumpTable.
* Most calls just read back the value the matching Control call set.
VideoStatus:
  005af6:  2f 08                move.l   a0, -(a7)
  005af8:  26 69 00 14          movea.l  $14(a1), a3
  005afc:  20 13                move.l   (a3), d0  ; [saveMode]
  005afe:  a0 55                dc.w     $a055  ; _StripAddress
  005b00:  26 40                movea.l  d0, a3
  005b02:  30 28 00 1a          move.w   $1a(a0), d0
  005b06:  24 68 00 1c          movea.l  $1c(a0), a2
  005b0a:  0c 40 00 0a          cmpi.w   #$a, d0
  005b0e:  62 1e                bhi.b    $5b2e  ; -> Sts_DefaultErr
  005b10:  30 3b 02 06          move.w   $5b18(pc, d0.w), d0
  005b14:  4e fb 00 02          jmp      $5b18(pc, d0.w)  ; -> StatusJumpTable
StatusJumpTable:
* jump table (word offsets relative to $5B18, indexed by selector*2):
  005b18:  00 16                dc.w     $0016    ; csCode 0 (->default) -> Sts_DefaultErr
  005b1a:  00 16                dc.w     $0016    ; csCode 1 (->default) -> Sts_DefaultErr
  005b1c:  00 22                dc.w     $0022    ; csCode 2 GetMode -> Sts_GetMode
  005b1e:  00 30                dc.w     $0030    ; csCode 3 GetEntries -> Sts_GetEntries
  005b20:  00 c4                dc.w     $00C4    ; csCode 4 GetPages -> Sts_GetPages
  005b22:  00 f4                dc.w     $00F4    ; csCode 5 GetBaseAddr -> Sts_GetBaseAddr
  005b24:  01 50                dc.w     $0150    ; csCode 6 GetGray -> Sts_GetGray
  005b26:  01 5e                dc.w     $015E    ; csCode 7 GetInterrupt -> Sts_GetInterrupt
  005b28:  01 62                dc.w     $0162    ; csCode 8 GetGamma -> Sts_GetGamma
  005b2a:  01 6e                dc.w     $016E    ; csCode 9 GetDefaultMode -> Sts_GetDefaultMode
  005b2c:  01 94                dc.w     $0194    ; csCode 10 GetCurMode -> Sts_GetCurMode
* csCode 0/1: unsupported -> statusErr (-18, $EE)
Sts_DefaultErr:
  005b2e:  70 ee                moveq    #$ee, d0
  005b30:  60 02                bra.b    $5b34  ; -> L5b34
L5b32:
  005b32:  70 00                moveq    #$0, d0
L5b34:
  005b34:  20 5f                movea.l  (a7)+, a0
  005b36:  60 00 01 78          bra.w    $5cb0  ; -> GoIODone
* csCode 2  cscGetMode  -  return current mode, page 0 and base addr
Sts_GetMode:
  005b3a:  34 93                move.w   (a3), (a2)  ; [saveMode]
  005b3c:  42 aa 00 06          clr.l    $6(a2)
  005b40:  25 6b 00 08 00 08    move.l   $8(a3), $8(a2)  ; [saveVidBase]
  005b46:  60 ea                bra.b    $5b32  ; -> L5b32
* csCode 3  cscGetEntries  -  read CLUT entries back into the ColorTable
Sts_GetEntries:
  005b48:  20 12                move.l   (a2), d0
  005b4a:  67 e2                beq.b    $5b2e  ; -> Sts_DefaultErr
  005b4c:  a0 55                dc.w     $a055  ; _StripAddress
  005b4e:  20 40                movea.l  d0, a0
  005b50:  32 13                move.w   (a3), d1  ; [saveMode]
  005b52:  04 41 00 80          subi.w   #$80, d1
  005b56:  47 fa f7 8c          lea.l    $52e4(pc), a3
  005b5a:  16 33 10 00          move.b   (a3, d1.w), d3
  005b5e:  38 2a 00 06          move.w   $6(a2), d4
  005b62:  0c 44 00 00          cmpi.w   #$0, d4
  005b66:  6b c6                bmi.b    $5b2e  ; -> Sts_DefaultErr
  005b68:  b8 43                cmp.w    d3, d4
  005b6a:  62 c2                bhi.b    $5b2e  ; -> Sts_DefaultErr
  005b6c:  34 04                move.w   d4, d2
  005b6e:  0c 6a ff ff 00 04    cmpi.w   #$ffff, $4(a2)
  005b74:  67 10                beq.b    $5b86  ; -> L5b86
  005b76:  32 04                move.w   d4, d1
  005b78:  d4 6a 00 04          add.w    $4(a2), d2
L5b7c:
  005b7c:  31 82 16 00          move.w   d2, (a0, d1.w * 8)
  005b80:  53 42                subq.w   #$1, d2
  005b82:  51 c9 ff f8          dbra     d1, $5b7c  ; -> L5b7c
L5b86:
  005b86:  26 69 00 14          movea.l  $14(a1), a3
  005b8a:  20 13                move.l   (a3), d0  ; [saveMode]
  005b8c:  a0 55                dc.w     $a055  ; _StripAddress
  005b8e:  26 40                movea.l  d0, a3
  005b90:  70 01                moveq    #$1, d0
  005b92:  a0 5d                dc.w     $a05d  ; _SwapMMUMode ->32-bit mode
  005b94:  2f 00                move.l   d0, -(a7)
  005b96:  26 6b 00 24          movea.l  $24(a3), a3  ; [saveHardBase]
  005b9a:  d7 fc 06 c0 00 04    adda.l   #$6c00004, a3  ; AC842 CLUT data port (R,G,B)
L5ba0:
  005ba0:  32 10                move.w   (a0), d1
  005ba2:  b2 03                cmp.b    d3, d1
  005ba4:  62 28                bhi.b    $5bce  ; -> L5bce
  005ba6:  17 41 ff fc          move.b   d1, -$4(a3)  ; [saveBaseAddr]
  005baa:  22 13                move.l   (a3), d1  ; [saveMode]
  005bac:  e1 99                rol.l    #$8, d1
  005bae:  11 41 00 02          move.b   d1, $2(a0)
  005bb2:  11 41 00 03          move.b   d1, $3(a0)
  005bb6:  22 13                move.l   (a3), d1  ; [saveMode]
  005bb8:  e1 99                rol.l    #$8, d1
  005bba:  11 41 00 04          move.b   d1, $4(a0)
  005bbe:  11 41 00 05          move.b   d1, $5(a0)
  005bc2:  22 13                move.l   (a3), d1  ; [saveMode]
  005bc4:  e1 99                rol.l    #$8, d1
  005bc6:  11 41 00 06          move.b   d1, $6(a0)
  005bca:  11 41 00 07          move.b   d1, $7(a0)
L5bce:
  005bce:  50 88                addq.l   #$8, a0
  005bd0:  51 cc ff ce          dbra     d4, $5ba0  ; -> L5ba0
  005bd4:  20 1f                move.l   (a7)+, d0
  005bd6:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  005bd8:  60 00 ff 58          bra.w    $5b32  ; -> L5b32
* csCode 4  cscGetPages  -  return the number of pages for a mode/depth
Sts_GetPages:
  005bdc:  32 12                move.w   (a2), d1
  005bde:  61 00 00 e0          bsr.w    $5cc0  ; -> ChkMode
  005be2:  6e 00 ff 4a          bgt.w    $5b2e  ; -> Sts_DefaultErr
  005be6:  34 12                move.w   (a2), d2
  005be8:  04 42 00 80          subi.w   #$80, d2
  005bec:  20 6b 00 20          movea.l  $20(a3), a0  ; [saveModeTbl]
  005bf0:  08 2b 00 08 00 1c    btst.b   #$8, $1c(a3)  ; [GFlags.sRsrc32Bit]
  005bf6:  67 06                beq.b    $5bfe  ; -> L5bfe
  005bf8:  12 30 20 ef          move.b   -$11(a0, d2.w), d1
  005bfc:  60 04                bra.b    $5c02  ; -> L5c02
L5bfe:
  005bfe:  12 30 20 ea          move.b   -$16(a0, d2.w), d1
L5c02:
  005c02:  52 41                addq.w   #$1, d1
  005c04:  35 41 00 06          move.w   d1, $6(a2)
  005c08:  60 00 ff 28          bra.w    $5b32  ; -> L5b32
* csCode 5  cscGetBaseAddr  -  return the framebuffer base for a page.
* base = storage.base + $0C00'0000 + page*pageSize (+$10000 or +$11400).
Sts_GetBaseAddr:
  005c0c:  32 13                move.w   (a3), d1  ; [saveMode]
  005c0e:  34 81                move.w   d1, (a2)
  005c10:  61 00 00 ae          bsr.w    $5cc0  ; -> ChkMode
  005c14:  30 2a 00 06          move.w   $6(a2), d0
  005c18:  61 00 01 20          bsr.w    $5d3a  ; -> ChkPage
  005c1c:  66 00 ff 10          bne.w    $5b2e  ; -> Sts_DefaultErr
  005c20:  32 13                move.w   (a3), d1  ; [saveMode]
  005c22:  04 41 00 80          subi.w   #$80, d1
  005c26:  20 6b 00 20          movea.l  $20(a3), a0  ; [saveModeTbl]
  005c2a:  c0 f0 12 f4          mulu.w   -$c(a0, d1.w), d0
  005c2e:  c0 e8 ff fe          mulu.w   -$2(a0), d0
  005c32:  08 2b 00 0b 00 1c    btst.b   #$b, $1c(a3)  ; [GFlags.Interlaced]
  005c38:  66 08                bne.b    $5c42  ; -> L5c42
  005c3a:  06 80 00 01 00 00    addi.l   #$10000, d0
  005c40:  60 14                bra.b    $5c56  ; -> L5c56
L5c42:
  005c42:  0c 53 00 83          cmpi.w   #$83, (a3)  ; [saveMode]
  005c46:  6e 08                bgt.b    $5c50  ; -> L5c50
  005c48:  20 3c 00 01 14 00    move.l   #$11400, d0
  005c4e:  60 06                bra.b    $5c56  ; -> L5c56
L5c50:
  005c50:  20 3c 00 01 14 00    move.l   #$11400, d0
L5c56:
  005c56:  d0 ab 00 24          add.l    $24(a3), d0  ; [saveHardBase]
  005c5a:  06 80 0c 00 00 00    addi.l   #$c000000, d0  ; VRAM/framebuffer +$0
  005c60:  25 40 00 08          move.l   d0, $8(a2)
  005c64:  60 00 fe cc          bra.w    $5b32  ; -> L5b32
* csCode 6  cscGetGray  -  return the luminance flag (bit 0)
Sts_GetGray:
  005c68:  72 00                moveq    #$0, d1
* shared: return storage flag bit D1 (0=gray, 1=interrupt) in (A2)
L5c6a:
  005c6a:  e9 eb 08 41 00 1c    bfextu   $1c(a3){1:1}, d0  ; [GFlags]
  005c70:  14 80                move.b   d0, (a2)
  005c72:  60 00 fe be          bra.w    $5b32  ; -> L5b32
* csCode 7  cscGetInterrupt  -  return the IRQ-enable flag (bit 1)
Sts_GetInterrupt:
  005c76:  72 01                moveq    #$1, d1
  005c78:  60 f0                bra.b    $5c6a  ; -> L5c6a
* csCode 8  cscGetGamma  -  return the current GammaTbl ptr (storage.$18)
Sts_GetGamma:
  005c7a:  24 ab 00 18          move.l   $18(a3), (a2)  ; [saveGammaPtr]
  005c7e:  60 00 fe b2          bra.w    $5b32  ; -> L5b32
  005c82:  72 01                moveq    #$1, d1
  005c84:  60 e4                bra.b    $5c6a  ; -> L5c6a
* csCode 9  cscGetDefaultMode  -  read the power-on mode from slot PRAM
Sts_GetDefaultMode:
  005c86:  9e fc 00 38          suba.w   #$38, a7
  005c8a:  20 4f                movea.l  a7, a0
  005c8c:  10 29 00 28          move.b   $28(a1), d0
  005c90:  11 40 00 31          move.b   d0, $31(a0)
  005c94:  42 28 00 33          clr.b    $33(a0)
  005c98:  51 4f                subq.w   #$8, a7
  005c9a:  20 8f                move.l   a7, (a0)
  005c9c:  70 11                moveq    #$11, d0
  005c9e:  a0 6e                dc.w     $a06e  ; _SlotManager selector=0x11
  005ca0:  14 af 00 03          move.b   $3(a7), (a2)
  005ca4:  de fc 00 40          adda.w   #$40, a7
  005ca8:  60 00 fe 88          bra.w    $5b32  ; -> L5b32
* csCode 10 cscGetCurMode  -  (nothing extra to fill in) return noErr
Sts_GetCurMode:
  005cac:  60 00 fe 84          bra.w    $5b32  ; -> L5b32
* IODone: if noQueueBit set just rts, else jump through JIODone ($8FC)
GoIODone:
  005cb0:  08 28 00 09 00 06    btst.b   #$9, $6(a0)
  005cb6:  67 02                beq.b    $5cba  ; -> L5cba
  005cb8:  4e 75                rts
L5cba:
  005cba:  20 78 08 fc          movea.l  $8fc.w, a0
  005cbe:  4e d0                jmp      (a0)
* ChkMode  -  validate a mode/depth request in D1 (mode = $80+depthIdx).
* Applies the card's depth rules (which depths a given monitor allows,
* interlace/1-bit restrictions) and sets/clears the CLUT-valid flag.
* Returns D1<0 (mi) if the mode is legal, else D1=+1 (illegal).
ChkMode:
  005cc0:  04 41 00 80          subi.w   #$80, d1
  005cc4:  6b 6e                bmi.b    $5d34  ; -> L5d34
  005cc6:  34 2b 00 28          move.w   $28(a3), d2  ; [saveID]
  005cca:  0c 41 00 04          cmpi.w   #$4, d1
  005cce:  6e 64                bgt.b    $5d34  ; -> L5d34
  005cd0:  08 ab 00 0a 00 1c    bclr.b   #$a, $1c(a3)  ; [GFlags.DirectModeFlag]
  005cd6:  70 01                moveq    #$1, d0
  005cd8:  e3 68                lsl.w    d1, d0
  005cda:  32 00                move.w   d0, d1
  005cdc:  0c 41 00 10          cmpi.w   #$10, d1
  005ce0:  66 02                bne.b    $5ce4  ; -> L5ce4
  005ce2:  50 41                addq.w   #$8, d1
L5ce4:
  005ce4:  0c 41 00 04          cmpi.w   #$4, d1
  005ce8:  6f 40                ble.b    $5d2a  ; -> L5d2a
  005cea:  0c 41 00 08          cmpi.w   #$8, d1
  005cee:  67 02                beq.b    $5cf2  ; -> L5cf2
  005cf0:  60 14                bra.b    $5d06  ; -> L5d06
L5cf2:
  005cf2:  08 2b 00 08 00 1c    btst.b   #$8, $1c(a3)  ; [GFlags.sRsrc32Bit]
  005cf8:  66 02                bne.b    $5cfc  ; -> L5cfc
  005cfa:  60 2e                bra.b    $5d2a  ; -> L5d2a
L5cfc:
  005cfc:  0c 6b 00 03 00 28    cmpi.w   #$3, $28(a3)  ; [saveID]
  005d02:  67 30                beq.b    $5d34  ; -> L5d34
  005d04:  60 24                bra.b    $5d2a  ; -> L5d2a
L5d06:
  005d06:  08 2b 00 0d 00 1c    btst.b   #$d, $1c(a3)  ; [GFlags.RAM512KFlag]
  005d0c:  66 0e                bne.b    $5d1c  ; -> L5d1c
  005d0e:  08 2b 00 0f 00 1e    btst.b   #$f, $1e(a3)  ; [moreGFlags.UnderScan]
  005d14:  66 1e                bne.b    $5d34  ; -> L5d34
  005d16:  08 02 00 00          btst.b   #$0, d2
  005d1a:  66 18                bne.b    $5d34  ; -> L5d34
L5d1c:
  005d1c:  08 2b 00 08 00 1c    btst.b   #$8, $1c(a3)  ; [GFlags.sRsrc32Bit]
  005d22:  66 10                bne.b    $5d34  ; -> L5d34
  005d24:  08 eb 00 0a 00 1c    bset.b   #$a, $1c(a3)  ; [GFlags.DirectModeFlag]
L5d2a:
  005d2a:  b2 41                cmp.w    d1, d1
  005d2c:  60 0a                bra.b    $5d38  ; -> L5d38
  005d2e:  08 ab 00 0a 00 1c    bclr.b   #$a, $1c(a3)  ; [GFlags.DirectModeFlag]
L5d34:
  005d34:  50 c1                st.b     d1
  005d36:  4a 41                tst.w    d1
L5d38:
  005d38:  4e 75                rts
* ChkPage  -  validate a page number in D0 (returns Z if page 0)
ChkPage:
  005d3a:  4a 40                tst.w    d0
  005d3c:  4e 75                rts
* WaitForVBlank  -  wait for vertical blanking.
* Polls the video-sync status (via sub_5d96 on the serial-ctl port /
* sync reg at base+$0440'01C0) across a full blank so CLUT writes do not
* tear.  Saves/forces the interrupt mask while spinning.
WaitForVBlank:
  005d3e:  48 e7 c8 88          movem.l  d0-d1/d4/a0/a4, -(a7)
  005d42:  40 e7                move.w   sr, -(a7)
  005d44:  70 07                moveq    #$7, d0
  005d46:  c0 17                and.b    (a7), d0
  005d48:  55 40                subq.w   #$2, d0
  005d4a:  6c 08                bge.b    $5d54  ; -> L5d54
  005d4c:  00 7c 02 00          ori.w    #$200, sr
  005d50:  02 7c fa ff          andi.w   #$faff, sr
L5d54:
  005d54:  20 6b 00 24          movea.l  $24(a3), a0  ; [saveHardBase]
  005d58:  d1 fc 04 40 01 c0    adda.l   #$44001c0, a0  ; MFB IRQ +$1c0 (video-sync status reg)
  005d5e:  72 02                moveq    #$2, d1
  005d60:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005d64:  28 3c 04 c0 00 00    move.l   #$4c00000, d4  ; control serial port (mode/IRQ)
L5d6a:
  005d6a:  20 10                move.l   (a0), d0
  005d6c:  4e ba 00 28          jsr      $5d96(pc)  ; -> sub_5d96
  005d70:  08 00 00 1f          btst.b   #$1f, d0
  005d74:  67 f4                beq.b    $5d6a  ; -> L5d6a
L5d76:
  005d76:  20 10                move.l   (a0), d0
  005d78:  4e ba 00 1c          jsr      $5d96(pc)  ; -> sub_5d96
  005d7c:  08 00 00 1f          btst.b   #$1f, d0
  005d80:  66 f4                bne.b    $5d76  ; -> L5d76
L5d82:
  005d82:  20 10                move.l   (a0), d0
  005d84:  4e ba 00 10          jsr      $5d96(pc)  ; -> sub_5d96
  005d88:  08 00 00 1f          btst.b   #$1f, d0
  005d8c:  67 f4                beq.b    $5d82  ; -> L5d82
  005d8e:  46 df                move.w   (a7)+, sr
  005d90:  4c df 11 13          movem.l  (a7)+, d0-d1/d4/a0/a4
  005d94:  4e 75                rts
* sub_5d96  -  read the serial-ctl/sync register (D1 = pre-shift count),
* returning the sampled long in D0 (bit 31 = blanking state).
sub_5d96:
  005d96:  74 0b                moveq    #$b, d2
  005d98:  94 81                sub.l    d1, d2
L5d9a:
  005d9a:  20 34 48 00          move.l   (a4, d4.l), d0
  005d9e:  29 80 48 00          move.l   d0, (a4, d4.l)
  005da2:  51 ca ff f6          dbra     d2, $5d9a  ; -> L5d9a
  005da6:  4e 75                rts
* JMFBSetDepth  -  program the MFB and pixel clock for the current mode.
* Derives rowBytes/scanlines/depth/page from the timing table, then hands
* them to the MFB (and, if the "WY1`" signature is present at
* base+$0C00'7318, to the on-card Am29000) through the parameter block at
* base+$0C00'7300, and re-times the pixel clock via sub_5fd4.
JMFBSetDepth:
  005da8:  48 e7 e8 88          movem.l  d0-d2/d4/a0/a4, -(a7)
  005dac:  70 01                moveq    #$1, d0
  005dae:  a0 5d                dc.w     $a05d  ; _SwapMMUMode ->32-bit mode
  005db0:  2f 00                move.l   d0, -(a7)
  005db2:  42 6b 00 02          clr.w    $2(a3)  ; [savePage]
  005db6:  32 13                move.w   (a3), d1  ; [saveMode]
  005db8:  04 41 00 80          subi.w   #$80, d1
  005dbc:  20 6b 00 20          movea.l  $20(a3), a0  ; [saveModeTbl]
  005dc0:  34 28 ff fe          move.w   -$2(a0), d2
  005dc4:  08 2b 00 0b 00 1c    btst.b   #$b, $1c(a3)  ; [GFlags.Interlaced]
  005dca:  67 0e                beq.b    $5dda  ; -> L5dda
  005dcc:  5a 42                addq.w   #$5, d2
  005dce:  08 2b 00 0d 00 1c    btst.b   #$d, $1c(a3)  ; [GFlags.RAM512KFlag]
  005dd4:  67 04                beq.b    $5dda  ; -> L5dda
  005dd6:  06 42 00 3c          addi.w   #$3c, d2
L5dda:
  005dda:  37 42 00 0e          move.w   d2, $e(a3)  ; [saveVRes]
  005dde:  34 30 12 f4          move.w   -$c(a0, d1.w), d2
  005de2:  37 42 00 0c          move.w   d2, $c(a3)  ; [saveRowBytes]
  005de6:  70 01                moveq    #$1, d0
  005de8:  e3 68                lsl.w    d1, d0
  005dea:  32 00                move.w   d0, d1
  005dec:  0c 41 00 10          cmpi.w   #$10, d1
  005df0:  66 02                bne.b    $5df4  ; -> L5df4
  005df2:  50 41                addq.w   #$8, d1
L5df4:
  005df4:  42 6b 00 2c          clr.w    $2c(a3)  ; [savePageCfg]
  005df8:  08 2b 00 0b 00 1c    btst.b   #$b, $1c(a3)  ; [GFlags.Interlaced]
  005dfe:  67 30                beq.b    $5e30  ; -> L5e30
  005e00:  b2 6b 00 2a          cmp.w    $2a(a3), d1  ; [saveDepth]
  005e04:  67 2a                beq.b    $5e30  ; -> L5e30
  005e06:  0c 41 00 18          cmpi.w   #$18, d1
  005e0a:  67 0a                beq.b    $5e16  ; -> L5e16
  005e0c:  0c 6b 00 18 00 2a    cmpi.w   #$18, $2a(a3)  ; [saveDepth]
  005e12:  67 10                beq.b    $5e24  ; -> L5e24
  005e14:  60 1a                bra.b    $5e30  ; -> L5e30
L5e16:
  005e16:  08 eb 00 09 00 1c    bset.b   #$9, $1c(a3)  ; [GFlags.BigScreen]
  005e1c:  37 7c 00 01 00 2c    move.w   #$1, $2c(a3)  ; [savePageCfg]
  005e22:  60 0c                bra.b    $5e30  ; -> L5e30
L5e24:
  005e24:  08 ab 00 09 00 1c    bclr.b   #$9, $1c(a3)  ; [GFlags.BigScreen]
  005e2a:  37 7c 00 02 00 2c    move.w   #$2, $2c(a3)  ; [savePageCfg]
L5e30:
  005e30:  37 41 00 2a          move.w   d1, $2a(a3)  ; [saveDepth]
  005e34:  08 2b 00 0b 00 1c    btst.b   #$b, $1c(a3)  ; [GFlags.Interlaced]
  005e3a:  67 0e                beq.b    $5e4a  ; -> L5e4a
  005e3c:  0c 01 00 08          cmpi.b   #$8, d1
  005e40:  6e 10                bgt.b    $5e52  ; -> L5e52
  005e42:  28 3c 00 01 14 00    move.l   #$11400, d4
  005e48:  60 1e                bra.b    $5e68  ; -> L5e68
L5e4a:
  005e4a:  28 3c 00 01 00 00    move.l   #$10000, d4
  005e50:  60 16                bra.b    $5e68  ; -> L5e68
L5e52:
  005e52:  08 2b 00 0d 00 1c    btst.b   #$d, $1c(a3)  ; [GFlags.RAM512KFlag]
  005e58:  67 08                beq.b    $5e62  ; -> L5e62
  005e5a:  28 3c 00 01 14 00    move.l   #$11400, d4
  005e60:  60 06                bra.b    $5e68  ; -> L5e68
L5e62:
  005e62:  28 3c 00 01 14 00    move.l   #$11400, d4
L5e68:
  005e68:  32 2b 00 1c          move.w   $1c(a3), d1  ; [GFlags]
  005e6c:  e0 59                ror.w    #$8, d1
  005e6e:  08 01 00 00          btst.b   #$0, d1
  005e72:  66 18                bne.b    $5e8c  ; -> L5e8c
  005e74:  22 2b 00 24          move.l   $24(a3), d1  ; [saveHardBase]
  005e78:  06 81 0c 00 00 00    addi.l   #$c000000, d1  ; VRAM/framebuffer +$0
  005e7e:  d2 84                add.l    d4, d1
  005e80:  27 41 00 04          move.l   d1, $4(a3)  ; [saveBaseAddr]
  005e84:  27 6b 00 04 00 08    move.l   $4(a3), $8(a3)  ; [saveBaseAddr]
  005e8a:  60 22                bra.b    $5eae  ; -> L5eae
L5e8c:
  005e8c:  22 2b 00 24          move.l   $24(a3), d1  ; [saveHardBase]
  005e90:  e9 99                rol.l    #$4, d1
  005e92:  d2 ab 00 24          add.l    $24(a3), d1  ; [saveHardBase]
  005e96:  e0 99                ror.l    #$8, d1
  005e98:  06 81 f0 00 00 00    addi.l   #$f0000000, d1
  005e9e:  d2 84                add.l    d4, d1
  005ea0:  27 41 00 04          move.l   d1, $4(a3)  ; [saveBaseAddr]
  005ea4:  02 81 ff 0f ff ff    andi.l   #$ff0fffff, d1
  005eaa:  27 41 00 08          move.l   d1, $8(a3)  ; [saveVidBase]
L5eae:
  005eae:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005eb2:  d9 fc 0c 00 73 18    adda.l   #$c007318, a4  ; MFB/Am29000 param block +$18
  005eb8:  28 14                move.l   (a4), d4
  005eba:  0c 84 57 59 31 60    cmpi.l   #$57593160, d4  ; 'WY1`'  MFB/Am29000 present? ('WY1`' signature)
  005ec0:  66 00 01 02          bne.w    $5fc4  ; -> L5fc4  not present: just retime the clock (sub_5fd4)
* Hand mode parameters to the MFB/Am29000 param block
  005ec4:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005ec8:  d9 fc 0c 00 73 08    adda.l   #$c007308, a4  ; MFB/Am29000 param block +$8
  005ece:  28 ab 00 08          move.l   $8(a3), (a4)  ; [saveVidBase]
  005ed2:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005ed6:  d9 fc 0c 00 73 0c    adda.l   #$c00730c, a4  ; MFB/Am29000 param block +$c
  005edc:  38 2b 00 0c          move.w   $c(a3), d4  ; [saveRowBytes]
  005ee0:  48 c4                ext.l    d4
  005ee2:  28 84                move.l   d4, (a4)
  005ee4:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005ee8:  d9 fc 0c 00 73 10    adda.l   #$c007310, a4  ; MFB/Am29000 param block +$10
  005eee:  38 2b 00 2a          move.w   $2a(a3), d4  ; [saveDepth]
  005ef2:  48 c4                ext.l    d4
  005ef4:  28 84                move.l   d4, (a4)
  005ef6:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005efa:  d9 fc 0c 00 73 14    adda.l   #$c007314, a4  ; MFB/Am29000 param block +$14
  005f00:  38 2b 00 0e          move.w   $e(a3), d4  ; [saveVRes]
  005f04:  48 c4                ext.l    d4
  005f06:  28 84                move.l   d4, (a4)
  005f08:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005f0c:  d9 fc 0c 00 73 1c    adda.l   #$c00731c, a4  ; MFB/Am29000 param block +$1c
  005f12:  38 2b 00 2c          move.w   $2c(a3), d4  ; [savePageCfg]
  005f16:  48 c4                ext.l    d4
  005f18:  28 84                move.l   d4, (a4)
  005f1a:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005f1e:  28 3c 04 c0 00 00    move.l   #$4c00000, d4  ; control serial port (mode/IRQ)
  005f24:  72 03                moveq    #$3, d1
  005f26:  74 0c                moveq    #$c, d2
  005f28:  4e ba 03 72          jsr      $629c(pc)  ; -> SerialShiftOut
  005f2c:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005f30:  28 3c 04 40 00 3c    move.l   #$440003c, d4  ; MFB IRQ +$3c (IRQ clear reg)
  005f36:  42 b4 48 00          clr.l    (a4, d4.l)
  005f3a:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005f3e:  d9 fc 0c 00 73 00    adda.l   #$c007300, a4  ; MFB/Am29000 param block +$0
  005f44:  28 bc 80 00 00 00    move.l   #$80000000, (a4)
  005f4a:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005f4e:  28 3c 04 00 00 50    move.l   #$4000050, d4  ; MFB reg +$50
  005f54:  29 bc ff ff ff ff 48 00 move.l   #$ffffffff, (a4, d4.l)
  005f5c:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005f60:  d9 fc 0c 00 73 04    adda.l   #$c007304, a4  ; MFB/Am29000 param block +$4
  005f66:  74 00                moveq    #$0, d2
  005f68:  34 38 0d 00          move.w   $d00.w, d2
  005f6c:  e1 8a                lsl.l    #$8, d2
L5f6e:
  005f6e:  0c 14 00 00          cmpi.b   #$0, (a4)
  005f72:  67 04                beq.b    $5f78  ; -> L5f78
  005f74:  53 82                subq.l   #$1, d2
  005f76:  66 f6                bne.b    $5f6e  ; -> L5f6e
L5f78:
  005f78:  4a 6b 00 2c          tst.w    $2c(a3)  ; [savePageCfg]
  005f7c:  67 0e                beq.b    $5f8c  ; -> L5f8c
  005f7e:  74 00                moveq    #$0, d2
  005f80:  34 38 0d 00          move.w   $d00.w, d2
  005f84:  e1 8a                lsl.l    #$8, d2
  005f86:  e5 8a                lsl.l    #$2, d2
L5f88:
  005f88:  53 82                subq.l   #$1, d2
  005f8a:  66 fc                bne.b    $5f88  ; -> L5f88
L5f8c:
  005f8c:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005f90:  28 3c 04 c0 00 00    move.l   #$4c00000, d4  ; control serial port (mode/IRQ)
  005f96:  72 01                moveq    #$1, d1
  005f98:  74 0c                moveq    #$c, d2
  005f9a:  4e ba 03 00          jsr      $629c(pc)  ; -> SerialShiftOut
  005f9e:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005fa2:  28 3c 04 40 00 3c    move.l   #$440003c, d4  ; MFB IRQ +$3c (IRQ clear reg)
  005fa8:  42 b4 48 00          clr.l    (a4, d4.l)
  005fac:  32 2b 00 2a          move.w   $2a(a3), d1  ; [saveDepth]
  005fb0:  61 22                bsr.b    $5fd4  ; -> sub_5fd4
  005fb2:  28 6b 00 24          movea.l  $24(a3), a4  ; [saveHardBase]
  005fb6:  d9 fc 0c 00 73 04    adda.l   #$c007304, a4  ; MFB/Am29000 param block +$4
  005fbc:  28 bc ff ff ff ff    move.l   #$ffffffff, (a4)
  005fc2:  60 06                bra.b    $5fca  ; -> L5fca
L5fc4:
  005fc4:  32 2b 00 2a          move.w   $2a(a3), d1  ; [saveDepth]
  005fc8:  61 0a                bsr.b    $5fd4  ; -> sub_5fd4
L5fca:
  005fca:  20 1f                move.l   (a7)+, d0
  005fcc:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  005fce:  4c df 11 17          movem.l  (a7)+, d0-d2/d4/a0/a4
  005fd2:  4e 75                rts
* sub_5fd4  -  load the pixel-clock / MFB timing coefficients for the
* depth in D1 (1/2/4/8/24 bpp select table offset $00/$50/$A0/$F0/$140).
* Shifts the coefficients into the card registers via SerialShiftOut.
sub_5fd4:
  005fd4:  48 e7 fc d8          movem.l  d0-d5/a0-a1/a3-a4, -(a7)
  005fd8:  36 92                move.w   (a2), (a3)  ; [saveMode]
  005fda:  20 6b 00 20          movea.l  $20(a3), a0  ; [saveModeTbl]
  005fde:  0c 41 00 01          cmpi.w   #$1, d1
  005fe2:  67 32                beq.b    $6016  ; -> L6016
  005fe4:  0c 41 00 02          cmpi.w   #$2, d1
  005fe8:  67 26                beq.b    $6010  ; -> L6010
  005fea:  0c 41 00 04          cmpi.w   #$4, d1
  005fee:  67 1a                beq.b    $600a  ; -> L600a
  005ff0:  0c 41 00 08          cmpi.w   #$8, d1
  005ff4:  67 0e                beq.b    $6004  ; -> L6004
  005ff6:  0c 41 00 18          cmpi.w   #$18, d1
  005ffa:  66 00 01 74          bne.w    $6170  ; -> L6170
  005ffe:  d0 fc 01 40          adda.w   #$140, a0
  006002:  60 16                bra.b    $601a  ; -> L601a
L6004:
  006004:  d0 fc 00 f0          adda.w   #$f0, a0
  006008:  60 10                bra.b    $601a  ; -> L601a
L600a:
  00600a:  d0 fc 00 a0          adda.w   #$a0, a0
  00600e:  60 0a                bra.b    $601a  ; -> L601a
L6010:
  006010:  d0 fc 00 50          adda.w   #$50, a0
  006014:  60 04                bra.b    $601a  ; -> L601a
L6016:
  006016:  d0 fc 00 00          adda.w   #$0, a0
L601a:
  00601a:  70 01                moveq    #$1, d0
  00601c:  a0 5d                dc.w     $a05d  ; _SwapMMUMode ->32-bit mode
  00601e:  2f 00                move.l   d0, -(a7)
  006020:  40 e7                move.w   sr, -(a7)
  006022:  70 07                moveq    #$7, d0
  006024:  c0 17                and.b    (a7), d0
  006026:  55 40                subq.w   #$2, d0
  006028:  6c 08                bge.b    $6032  ; -> L6032
  00602a:  00 7c 02 00          ori.w    #$200, sr
  00602e:  02 7c fa ff          andi.w   #$faff, sr
L6032:
  006032:  61 00 fd 0a          bsr.w    $5d3e  ; -> WaitForVBlank
  006036:  08 2b 00 0b 00 1c    btst.b   #$b, $1c(a3)  ; [GFlags.Interlaced]
  00603c:  67 0c                beq.b    $604a  ; -> L604a
  00603e:  34 13                move.w   (a3), d2  ; [saveMode]
  006040:  04 42 00 80          subi.w   #$80, d2
  006044:  c4 fc 00 40          mulu.w   #$40, d2
  006048:  d1 c2                adda.l   d2, a0
L604a:
  00604a:  22 6b 00 24          movea.l  $24(a3), a1  ; [saveHardBase]
  00604e:  3a 2b 00 1c          move.w   $1c(a3), d5  ; [GFlags]
  006052:  2f 0b                move.l   a3, -(a7)
  006054:  26 49                movea.l  a1, a3
  006056:  d7 fc 06 c0 00 08    adda.l   #$6c00008, a3  ; AC842 control port
  00605c:  26 98                move.l   (a0)+, (a3)  ; [saveMode]
  00605e:  28 49                movea.l  a1, a4
  006060:  28 3c 04 00 00 80    move.l   #$4000080, d4  ; MFB reg +$80
  006066:  72 01                moveq    #$1, d1
  006068:  08 05 00 0b          btst.b   #$b, d5
  00606c:  67 08                beq.b    $6076  ; -> L6076
  00606e:  08 05 00 09          btst.b   #$9, d5
  006072:  66 02                bne.b    $6076  ; -> L6076
  006074:  72 00                moveq    #$0, d1
L6076:
  006076:  ef f4 10 01 48 00    bfins    d1, (a4, d4.l){0:1}
  00607c:  28 3c 04 00 00 7c    move.l   #$400007c, d4  ; MFB reg +$7c
  006082:  22 18                move.l   (a0)+, d1
  006084:  ef f4 10 01 48 00    bfins    d1, (a4, d4.l){0:1}
  00608a:  28 3c 04 00 00 04    move.l   #$4000004, d4  ; MFB reg +$04
  006090:  22 18                move.l   (a0)+, d1
  006092:  74 08                moveq    #$8, d2
  006094:  4e ba 02 06          jsr      $629c(pc)  ; -> SerialShiftOut
  006098:  28 3c 04 00 00 00    move.l   #$4000000, d4  ; MFB reg +$00
  00609e:  22 18                move.l   (a0)+, d1
  0060a0:  74 14                moveq    #$14, d2
  0060a2:  4e ba 01 f8          jsr      $629c(pc)  ; -> SerialShiftOut
  0060a6:  28 3c 04 00 00 a0    move.l   #$40000a0, d4  ; MFB reg +$a0
  0060ac:  22 18                move.l   (a0)+, d1
  0060ae:  74 0c                moveq    #$c, d2
  0060b0:  4e ba 01 ea          jsr      $629c(pc)  ; -> SerialShiftOut
  0060b4:  08 05 00 0b          btst.b   #$b, d5
  0060b8:  67 1a                beq.b    $60d4  ; -> L60d4
  0060ba:  26 49                movea.l  a1, a3
  0060bc:  d7 fc 06 80 00 00    adda.l   #$6800000, a3  ; clock/timing coeff RAM +$0
  0060c2:  34 3c 00 0f          move.w   #$f, d2
L60c6:
  0060c6:  26 98                move.l   (a0)+, (a3)  ; [saveMode]
  0060c8:  51 ca ff fc          dbra     d2, $60c6  ; -> L60c6
  0060cc:  34 38 0d 00          move.w   $d00.w, d2
L60d0:
  0060d0:  51 ca ff fe          dbra     d2, $60d0  ; -> L60d0
L60d4:
  0060d4:  28 3c 04 00 00 1c    move.l   #$400001c, d4  ; MFB reg +$1c
  0060da:  72 01                moveq    #$1, d1
  0060dc:  ef f4 10 01 48 00    bfins    d1, (a4, d4.l){0:1}
  0060e2:  28 3c 04 00 00 20    move.l   #$4000020, d4  ; MFB reg +$20
  0060e8:  72 01                moveq    #$1, d1
  0060ea:  ef f4 10 01 48 00    bfins    d1, (a4, d4.l){0:1}
  0060f0:  28 3c 04 00 00 24    move.l   #$4000024, d4  ; MFB reg +$24
  0060f6:  72 01                moveq    #$1, d1
  0060f8:  ef f4 10 01 48 00    bfins    d1, (a4, d4.l){0:1}
  0060fe:  28 49                movea.l  a1, a4
  006100:  28 3c 04 c0 00 00    move.l   #$4c00000, d4  ; control serial port (mode/IRQ)
  006106:  72 00                moveq    #$0, d1
  006108:  74 0c                moveq    #$c, d2
  00610a:  4e ba 01 90          jsr      $629c(pc)  ; -> SerialShiftOut
  00610e:  28 3c 04 40 00 3c    move.l   #$440003c, d4  ; MFB IRQ +$3c (IRQ clear reg)
  006114:  42 b4 48 00          clr.l    (a4, d4.l)
  006118:  26 49                movea.l  a1, a3
  00611a:  d7 fc 04 40 00 00    adda.l   #$4400000, a3  ; MFB IRQ +$0 (IRQ reg base)
  006120:  36 3c 00 0e          move.w   #$e, d3
  006124:  28 49                movea.l  a1, a4
  006126:  28 3c 04 c0 00 00    move.l   #$4c00000, d4  ; control serial port (mode/IRQ)
L612c:
  00612c:  74 0c                moveq    #$c, d2
  00612e:  22 18                move.l   (a0)+, d1
  006130:  4e ba 01 6a          jsr      $629c(pc)  ; -> SerialShiftOut
  006134:  26 f4 48 00          move.l   (a4, d4.l), (a3)+  ; [saveMode]
  006138:  51 cb ff f2          dbra     d3, $612c  ; -> L612c
  00613c:  28 3c 04 00 00 c4    move.l   #$40000c4, d4  ; MFB reg +$c4
  006142:  72 01                moveq    #$1, d1
  006144:  ef f4 10 01 48 00    bfins    d1, (a4, d4.l){0:1}
  00614a:  28 49                movea.l  a1, a4
  00614c:  28 3c 04 c0 00 00    move.l   #$4c00000, d4  ; control serial port (mode/IRQ)
  006152:  72 01                moveq    #$1, d1
  006154:  74 0c                moveq    #$c, d2
  006156:  4e ba 01 44          jsr      $629c(pc)  ; -> SerialShiftOut
  00615a:  28 3c 04 40 00 3c    move.l   #$440003c, d4  ; MFB IRQ +$3c (IRQ clear reg)
  006160:  42 b4 48 00          clr.l    (a4, d4.l)
  006164:  26 5f                movea.l  (a7)+, a3
  006166:  61 00 fb d6          bsr.w    $5d3e  ; -> WaitForVBlank
  00616a:  46 df                move.w   (a7)+, sr
  00616c:  20 1f                move.l   (a7)+, d0
  00616e:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
L6170:
  006170:  4c df 1b 3f          movem.l  (a7)+, d0-d5/a0-a1/a3-a4
  006174:  4e 75                rts
* GrayScreen  -  gray-fill / clear the current framebuffer page.
* Uses the 50%-gray pattern for the current depth from GrayPatterns
* (1bpp=$AAAAAAAA, 2bpp=$CCCCCCCC, 4bpp=$F0F0F0F0, 8bpp=$FF00FF00).
GrayScreen:
  006176:  48 e7 ff 88          movem.l  d0-d7/a0/a4, -(a7)
  00617a:  32 13                move.w   (a3), d1  ; [saveMode]
  00617c:  04 41 00 80          subi.w   #$80, d1
  006180:  36 01                move.w   d1, d3
  006182:  49 fa 01 04          lea.l    $6288(pc), a4
  006186:  2a 34 34 00          move.l   (a4, d3.w * 4), d5
  00618a:  28 6b 00 20          movea.l  $20(a3), a4  ; [saveModeTbl]
  00618e:  38 34 12 f4          move.w   -$c(a4, d1.w), d4
  006192:  36 2c ff fe          move.w   -$2(a4), d3
  006196:  53 43                subq.w   #$1, d3
  006198:  70 01                moveq    #$1, d0
  00619a:  a0 5d                dc.w     $a05d  ; _SwapMMUMode ->32-bit mode
  00619c:  2f 00                move.l   d0, -(a7)
  00619e:  0c 01 00 04          cmpi.b   #$4, d1
  0061a2:  67 74                beq.b    $6218  ; -> L6218
  0061a4:  28 6b 00 08          movea.l  $8(a3), a4  ; [saveVidBase]
  0061a8:  08 2b 00 0b 00 1c    btst.b   #$b, $1c(a3)  ; [GFlags.Interlaced]
  0061ae:  66 02                bne.b    $61b2  ; -> L61b2
  0061b0:  60 18                bra.b    $61ca  ; -> L61ca
L61b2:
  0061b2:  42 40                clr.w    d0
  0061b4:  30 04                move.w   d4, d0
  0061b6:  c0 fc 00 05          mulu.w   #$5, d0
  0061ba:  98 c0                suba.w   d0, a4
  0061bc:  e4 48                lsr.w    #$2, d0
  0061be:  53 40                subq.w   #$1, d0
L61c0:
  0061c0:  28 fc ff ff ff ff    move.l   #$ffffffff, (a4)+
  0061c6:  51 c8 ff f8          dbra     d0, $61c0  ; -> L61c0
L61ca:
  0061ca:  20 4c                movea.l  a4, a0
  0061cc:  34 04                move.w   d4, d2
  0061ce:  e2 4a                lsr.w    #$1, d2
  0061d0:  53 42                subq.w   #$1, d2
L61d2:
  0061d2:  20 c5                move.l   d5, (a0)+
  0061d4:  51 ca ff fc          dbra     d2, $61d2  ; -> L61d2
  0061d8:  46 85                not.l    d5
  0061da:  d8 c4                adda.w   d4, a4
  0061dc:  51 cb ff ec          dbra     d3, $61ca  ; -> L61ca
  0061e0:  08 2b 00 0b 00 1c    btst.b   #$b, $1c(a3)  ; [GFlags.Interlaced]
  0061e6:  67 00 00 96          beq.w    $627e  ; -> L627e
  0061ea:  08 2b 00 0d 00 1c    btst.b   #$d, $1c(a3)  ; [GFlags.RAM512KFlag]
  0061f0:  67 00 00 8c          beq.w    $627e  ; -> L627e
  0061f4:  32 04                move.w   d4, d1
  0061f6:  e4 49                lsr.w    #$2, d1
  0061f8:  08 2b 00 0f 00 1e    btst.b   #$f, $1e(a3)  ; [moreGFlags.UnderScan]
  0061fe:  67 06                beq.b    $6206  ; -> L6206
  006200:  c2 fc 00 3c          mulu.w   #$3c, d1
  006204:  60 04                bra.b    $620a  ; -> L620a
L6206:
  006206:  c2 fc 00 32          mulu.w   #$32, d1
L620a:
  00620a:  53 41                subq.w   #$1, d1
L620c:
  00620c:  28 fc ff ff ff ff    move.l   #$ffffffff, (a4)+
  006212:  51 c9 ff f8          dbra     d1, $620c  ; -> L620c
  006216:  60 66                bra.b    $627e  ; -> L627e
L6218:
  006218:  28 6b 00 08          movea.l  $8(a3), a4  ; [saveVidBase]
  00621c:  08 2b 00 0b 00 1c    btst.b   #$b, $1c(a3)  ; [GFlags.Interlaced]
  006222:  66 02                bne.b    $6226  ; -> L6226
  006224:  60 12                bra.b    $6238  ; -> L6238
L6226:
  006226:  30 04                move.w   d4, d0
  006228:  c0 fc 00 02          mulu.w   #$2, d0
  00622c:  98 c0                suba.w   d0, a4
  00622e:  e4 48                lsr.w    #$2, d0
  006230:  53 40                subq.w   #$1, d0
L6232:
  006232:  42 9c                clr.l    (a4)+
  006234:  51 c8 ff fc          dbra     d0, $6232  ; -> L6232
L6238:
  006238:  20 4c                movea.l  a4, a0
  00623a:  34 04                move.w   d4, d2
  00623c:  e4 4a                lsr.w    #$2, d2
  00623e:  3e 02                move.w   d2, d7
  006240:  53 42                subq.w   #$1, d2
L6242:
  006242:  20 c5                move.l   d5, (a0)+
  006244:  46 85                not.l    d5
  006246:  51 ca ff fa          dbra     d2, $6242  ; -> L6242
  00624a:  46 85                not.l    d5
  00624c:  d8 c4                adda.w   d4, a4
  00624e:  51 cb ff e8          dbra     d3, $6238  ; -> L6238
  006252:  08 2b 00 0b 00 1c    btst.b   #$b, $1c(a3)  ; [GFlags.Interlaced]
  006258:  67 24                beq.b    $627e  ; -> L627e
  00625a:  08 2b 00 0d 00 1c    btst.b   #$d, $1c(a3)  ; [GFlags.RAM512KFlag]
  006260:  67 1c                beq.b    $627e  ; -> L627e
  006262:  34 07                move.w   d7, d2
  006264:  08 2b 00 0f 00 1e    btst.b   #$f, $1e(a3)  ; [moreGFlags.UnderScan]
  00626a:  c4 fc 00 3c          mulu.w   #$3c, d2
  00626e:  67 02                beq.b    $6272  ; -> L6272
  006270:  60 04                bra.b    $6276  ; -> L6276
L6272:
  006272:  c4 fc 00 32          mulu.w   #$32, d2
L6276:
  006276:  53 42                subq.w   #$1, d2
L6278:
  006278:  42 98                clr.l    (a0)+
  00627a:  51 ca ff fc          dbra     d2, $6278  ; -> L6278
L627e:
  00627e:  20 1f                move.l   (a7)+, d0
  006280:  a0 5d                dc.w     $a05d  ; _SwapMMUMode
  006282:  4c df 11 ff          movem.l  (a7)+, d0-d7/a0/a4
  006286:  4e 75                rts
* GrayPatterns  -  50%-gray fill longs, indexed by depth (see GrayScreen)
GrayPatterns:
  006288:  aa aa aa aa cc cc cc cc f0 f0 f0 f0 ff 00 ff 00 dc.b     $aa,$aa,$aa,$aa,$cc,$cc,$cc,$cc,$f0,$f0,$f0,$f0,$ff,$00,$ff,$00  ; ................
  006298:  00 00 00 00          dc.b     $00,$00,$00,$00  ; ....
* SerialShiftOut  -  shift D1 (top D2 bits, MSB first) serially into the card
* register at (A4,D4).  Used to program the pixel clock and control ports.
SerialShiftOut:
  00629c:  48 e7 62 00          movem.l  d1-d2/d6, -(a7)
  0062a0:  7c 20                moveq    #$20, d6
  0062a2:  9c 42                sub.w    d2, d6
  0062a4:  ed a9                lsl.l    d6, d1
  0062a6:  04 42 00 01          subi.w   #$1, d2
L62aa:
  0062aa:  29 81 48 00          move.l   d1, (a4, d4.l)
  0062ae:  e3 89                lsl.l    #$1, d1
  0062b0:  51 ca ff f8          dbra     d2, $62aa  ; -> L62aa
  0062b4:  4c df 00 46          movem.l  (a7)+, d1-d2/d6
  0062b8:  4e 75                rts
* VBLInterruptTask  -  slot VBL interrupt handler (installed by sub_5a1e).
* Runs the slot's VBL task queue via the low-memory VBL vectors ($D28/$DBC),
* acknowledges the card interrupt and returns D0=1 (serviced).
VBLInterruptTask:
  0062ba:  48 e7 00 c0          movem.l  a0-a1, -(a7)
  0062be:  20 09                move.l   a1, d0
  0062c0:  e9 98                rol.l    #$4, d0
  0062c2:  02 80 00 00 00 0f    andi.l   #$f, d0
  0062c8:  20 78 0d 28          movea.l  $d28.w, a0
  0062cc:  4e 90                jsr      (a0)
  0062ce:  4c df 03 00          movem.l  (a7)+, a0-a1
  0062d2:  48 e7 60 c0          movem.l  d1-d2/a0-a1, -(a7)
  0062d6:  70 01                moveq    #$1, d0
  0062d8:  20 78 0d bc          movea.l  $dbc.w, a0
  0062dc:  4e 90                jsr      (a0)
  0062de:  4c df 03 06          movem.l  (a7)+, d1-d2/a0-a1
  0062e2:  42 91                clr.l    (a1)
  0062e4:  48 e7 60 c0          movem.l  d1-d2/a0-a1, -(a7)
  0062e8:  20 78 0d bc          movea.l  $dbc.w, a0
  0062ec:  4e 90                jsr      (a0)
  0062ee:  4c df 03 06          movem.l  (a7)+, d1-d2/a0-a1
  0062f2:  70 01                moveq    #$1, d0
  0062f4:  4e 75                rts
* XtdSense  -  extended monitor sense.
* Drives each SENSE line low in turn (tri-state regs +$2C/$30/$34) and
* reads the response on the others (+$44/$48/$4C), assembling a 6-bit
* extended-sense code in D0 to tell apart monitors that share a 3-bit code.
XtdSense:
  0062f6:  42 40                clr.w    d0
  0062f8:  72 00                moveq    #$0, d1
  0062fa:  74 00                moveq    #$0, d2
  0062fc:  28 3c 04 00 00 2c    move.l   #$400002c, d4  ; MFB reg +$2c
  006302:  29 bc ff ff ff ff 48 00 move.l   #$ffffffff, (a4, d4.l)
  00630a:  28 3c 04 00 00 30    move.l   #$4000030, d4  ; MFB reg +$30
  006310:  42 b4 48 00          clr.l    (a4, d4.l)
  006314:  28 3c 04 00 00 34    move.l   #$4000034, d4  ; MFB reg +$34
  00631a:  42 b4 48 00          clr.l    (a4, d4.l)
  00631e:  28 3c 04 00 00 48    move.l   #$4000048, d4  ; MFB reg +$48 (SENSE line 1)
  006324:  e9 f4 20 01 48 00    bfextu   (a4, d4.l){0:1}, d2
  00632a:  82 02                or.b     d2, d1
  00632c:  e3 09                lsl.b    #$1, d1
  00632e:  28 3c 04 00 00 4c    move.l   #$400004c, d4  ; MFB reg +$4c (SENSE line 2)
  006334:  e9 f4 20 01 48 00    bfextu   (a4, d4.l){0:1}, d2
  00633a:  82 02                or.b     d2, d1
  00633c:  e3 09                lsl.b    #$1, d1
  00633e:  28 3c 04 00 00 2c    move.l   #$400002c, d4  ; MFB reg +$2c
  006344:  42 b4 48 00          clr.l    (a4, d4.l)
  006348:  28 3c 04 00 00 30    move.l   #$4000030, d4  ; MFB reg +$30
  00634e:  29 bc ff ff ff ff 48 00 move.l   #$ffffffff, (a4, d4.l)
  006356:  28 3c 04 00 00 34    move.l   #$4000034, d4  ; MFB reg +$34
  00635c:  42 b4 48 00          clr.l    (a4, d4.l)
  006360:  28 3c 04 00 00 44    move.l   #$4000044, d4  ; MFB reg +$44 (SENSE line 0)
  006366:  e9 f4 20 01 48 00    bfextu   (a4, d4.l){0:1}, d2
  00636c:  82 02                or.b     d2, d1
  00636e:  e3 09                lsl.b    #$1, d1
  006370:  28 3c 04 00 00 4c    move.l   #$400004c, d4  ; MFB reg +$4c (SENSE line 2)
  006376:  e9 f4 20 01 48 00    bfextu   (a4, d4.l){0:1}, d2
  00637c:  82 02                or.b     d2, d1
  00637e:  e3 09                lsl.b    #$1, d1
  006380:  28 3c 04 00 00 2c    move.l   #$400002c, d4  ; MFB reg +$2c
  006386:  42 b4 48 00          clr.l    (a4, d4.l)
  00638a:  28 3c 04 00 00 30    move.l   #$4000030, d4  ; MFB reg +$30
  006390:  42 b4 48 00          clr.l    (a4, d4.l)
  006394:  28 3c 04 00 00 34    move.l   #$4000034, d4  ; MFB reg +$34
  00639a:  29 bc ff ff ff ff 48 00 move.l   #$ffffffff, (a4, d4.l)
  0063a2:  28 3c 04 00 00 44    move.l   #$4000044, d4  ; MFB reg +$44 (SENSE line 0)
  0063a8:  e9 f4 20 01 48 00    bfextu   (a4, d4.l){0:1}, d2
  0063ae:  82 02                or.b     d2, d1
  0063b0:  e3 09                lsl.b    #$1, d1
  0063b2:  28 3c 04 00 00 48    move.l   #$4000048, d4  ; MFB reg +$48 (SENSE line 1)
  0063b8:  e9 f4 20 01 48 00    bfextu   (a4, d4.l){0:1}, d2
  0063be:  82 02                or.b     d2, d1
  0063c0:  80 01                or.b     d1, d0
  0063c2:  28 3c 04 00 00 2c    move.l   #$400002c, d4  ; MFB reg +$2c
  0063c8:  42 b4 48 00          clr.l    (a4, d4.l)
  0063cc:  28 3c 04 00 00 30    move.l   #$4000030, d4  ; MFB reg +$30
  0063d2:  42 b4 48 00          clr.l    (a4, d4.l)
  0063d6:  28 3c 04 00 00 34    move.l   #$4000034, d4  ; MFB reg +$34
  0063dc:  42 b4 48 00          clr.l    (a4, d4.l)
  0063e0:  4e 75                rts
  0063e2:  00 00 00 00          dc.b     $00,$00,$00,$00  ; ....
