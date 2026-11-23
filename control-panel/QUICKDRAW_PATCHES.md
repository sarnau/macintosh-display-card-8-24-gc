# QuickDraw routines replaced by `gc24`, and the card commands they issue

`gc24`'s dispatch table (106 entries of `$30` bytes, `gc24.s` `disp_00..disp_105`)
is the list of patches `DRVR.s`'s `InstallPatches` applies. The first long of
each entry is the **address of the entry in the 68k trap table**, which
`ClassifyTrapNum` turns into a trap number as `(v - $E00) >> 2` (Toolbox
traps; word `$A800 + n`); the 68k handler is the `bra.l` at `+$28`. The names
below come from Apple's `Traps.h`. Entries whose first long is below `$E00`
are patches of low-memory vectors or OS traps (`$800`-`$890`, `$590`, `$644`)
and the last three (`$FFFFFFFF`, `$FFFFFFFE`, `$FFFFFFFD`) are control
records, not traps.

The "card commands" column lists the command codes (`$0C`-`$38`) that the
handler (and the helpers it calls, to depth 3) passes to `EngineDispatch` as
its selector. For the drawing and drawing-state codes, that is not what the
card receives: `EngineDispatch` turns them into stream records (see the
table below this introduction). For the other codes, it is the selector the
Am29000 receives, at packet `+$48` (see `HOST_CARD_PROTOCOL.md`, "The
dispatcher prologue and packet layout"). Codes shared by many
handlers (`$0D`, `$26`, `$38` and a few more) are begin/end/synchronise
commands, not the operation itself; the operation-specific ones are in bold.
This list is extracted mechanically and is a reading of the code, not a
confirmed table.

**Most of these commands never travel as commands.** `EngineDispatch`
writes the drawing commands and the drawing-state commands as records of a
stream in card memory, which the card plays back (DrawMultiObject; see
`HOST_CARD_PROTOCOL.md`, "DrawMultiObject: the batched drawing stream"):

| command | stream record |
|---|---|
| `$20` StdLine | 1 |
| `$23` StdArc | 2 |
| `$2F` StdOval | 3 |
| `$2E` StdRRect | 4 (or 5 when the oval is zero) |
| `$24` StdRect | 5 |
| `$21` StdText | `$67` (font) and 6 |
| `$31` StdPoly | 7 |
| `$18` StdRgn | 8 |
| `$10` visible region | `$6C` |
| `$32` clip | `$6A` |
| `$35` pen size | `$6E` |
| `$36` foreground | `$66`/`$64` |
| `$37` background | `$6D`/`$6B` |

Pen location, mode, patterns, `patAlign` and Op/Hilite colour are compared
with cached copies at each drawing call and written as records when they
changed. The stream itself is carried by `$2D` (start), `$38` (more records)
and `$26` (flush/end, with a reason code). Fonts are uploaded by `$30`.

The traps `$AB11`, `$AB23`, `$AB27` and `$AB9A` are not in the public
headers. They are QuickDraw's internal traps, named in System 7.1
`QuickDraw/QDTrapInstall.a` (`QDEntry $311, OldPatToNew`, `$323 SetFillPat`,
`$327 StretchBits`, `$39A PicItem1`). The low-memory entries below `$E00`
are the cursor jump vectors from `Interfaces/AIncludes/Private.a`
(`JHideCursor` `$800` … `JCrsrObscure` `$81C`, `JSetCCrsr` `$890`,
`JCrsrTask` `$8EE`), plus `$644`, which is `_Translate24To32`'s OS trap entry.

| # | trap table addr | trap | QuickDraw / Toolbox routine | 68k handler | card commands |
|--:|---|---|---|---|---|
| 0 | $644 | $A091 (OS) | _Translate24To32 | `$7F50` | - |
| 1 | $8EE | - | JCrsrTask (vector: CrsrVBLTask) | `$801C` | - |
| 2 | $11B0 | $A8EC | _CopyBits | `$483C` | $0D **$38** |
| 3 | $1040 | $A890 | _StdLine | `$3682` | $0D **$20** $26 **$38** |
| 4 | $10F4 | $A8BD | _StdArc | `$3DDC` | $0D **$23** $26 **$38** |
| 5 | $1008 | $A882 | _StdText | `$3A9C` | $0D **$21** $26 **$38** |
| 6 | $1A9C | $AB27 | StretchBits (internal; QDTrapInstall.a `$327`; signature matches `Stretch.a`) | `$32BC` | $0D **$15** **$38** |
| 7 | $800 | - | JHideCursor (vector) | `$42B8` | - |
| 8 | $804 | - | JShowCursor (vector) | `$420C` | - |
| 9 | $808 | - | JShieldCursor (vector) | `$44C4` | - |
| 10 | $1C68 | $AB9A | PicItem1 (internal; QDTrapInstall.a `$39A`) | `$9278` | **$2A** |
| 11 | $1064 | $A899 | _SetPenState | `$9F04` | **$2A** **$35** |
| 12 | $106C | $A89B | _PenSize | `$9FD0` | **$35** |
| 13 | $1070 | $A89C | _PenMode | `$A060` | - |
| 14 | $1078 | $A89E | _PenNormal | `$A1E2` | **$2A** **$35** |
| 15 | $1A8C | $AB23 | SetFillPat (internal; `$323`) | `$7DAC` | - |
| 16 | $F88 | $A862 | _ForeColor | `$ADF0` | **$36** |
| 17 | $1650 | $AA14 | _RGBForeColor | `$AE56` | **$36** |
| 18 | $185C | $AA97 | _PmForeColor | `$AF00` | **$36** |
| 19 | $1860 | $AA98 | _PmBackColor | `$B0B0` | **$37** |
| 20 | $1080 | $A8A0 | _StdRect | `$4116` | $0D **$24** $26 **$38** |
| 21 | $10D8 | $A8B6 | _StdOval | `$4020` | $0D $26 **$2F** **$38** |
| 22 | $10BC | $A8AF | _StdRRect | `$3EFA` | $0D $26 **$2E** **$38** |
| 23 | $1114 | $A8C5 | _StdPoly | `$376C` | $0D $26 **$31** **$38** |
| 24 | $1144 | $A8D1 | _StdRgn | `$358C` | $0D **$18** $26 **$38** |
| 25 | $16E8 | $AA3A | _AddSearch | `$96B8` | $26 **$29** |
| 26 | $1730 | $AA4C | _DelSearch | `$9794` | $26 **$29** |
| 27 | $16EC | $AA3B | _AddComp | `$97E2` | $26 **$29** |
| 28 | $1734 | $AA4D | _DelComp | `$9830` | $26 **$29** |
| 29 | $1620 | $AA08 | _DisposPixPat | `$987E` | **$2C** |
| 30 | $1624 | $AA09 | _CopyPixPat | `$98B2` | **$2A** |
| 31 | $1634 | $AA0D | _MakeRGBPat | `$9948` | **$2A** |
| 32 | $1A44 | $AB11 | OldPatToNew (internal; `$311`) | `$99D6` | **$2A** |
| 33 | $FD4 | $A875 | _SetPBits | `$9BCA` | $26 |
| 34 | $FD8 | $A876 | _PortSize | `$9C62` | $26 |
| 35 | $FDC | $A877 | _MovePortTo | `$9CF2` | $26 |
| 36 | $FE0 | $A878 | _SetOrigin | `$9D4C` | $26 |
| 37 | $FE4 | $A879 | _SetClip | `$9DBE` | $32 |
| 38 | $FEC | $A87B | _ClipRect | `$9E34` | $32 |
| 39 | $1058 | $A896 | _HidePen | `$9ED0` | - |
| 40 | $105C | $A897 | _ShowPen | `$9EEA` | - |
| 41 | $F8C | $A863 | _BackColor | `$AFA0` | **$37** |
| 42 | $F90 | $A864 | _ColorBit | `$A2B8` | $26 |
| 43 | $1168 | $A8DA | _OpenRgn | `$A31E` | - |
| 44 | $11CC | $A8F3 | _OpenPicture | `$A338` | - |
| 45 | $112C | $A8CB | _OpenPoly | `$A35E` | - |
| 46 | $1170 | $A8DC | _CopyRgn | `$A472` | $10 $32 |
| 47 | $1178 | $A8DE | _SetRecRgn | `$A5AA` | $10 $32 |
| 48 | $117C | $A8DF | _RectRgn | `$A672` | $10 $32 |
| 49 | $1180 | $A8E0 | _OfsetRgn | `$A726` | $10 $32 |
| 50 | $1184 | $A8E1 | _InsetRgn | `$A820` | $10 $32 |
| 51 | $1190 | $A8E4 | _SectRgn | `$A91A` | $10 $32 |
| 52 | $1194 | $A8E5 | _UnionRgn | `$AA0A` | $10 $32 |
| 53 | $1198 | $A8E6 | _DiffRgn | `$AAFA` | $10 $32 |
| 54 | $119C | $A8E7 | _XOrRgn | `$ABEA` | $10 $32 |
| 55 | $11EC | $A8FB | _MapRgn | `$ACDA` | $10 $32 |
| 56 | $1654 | $AA15 | _RGBBackColor | `$B006` | **$37** |
| 57 | $1614 | $AA05 | _CopyPixMap | `$B57E` | $26 |
| 58 | $1628 | $AA0A | _PenPixPat | `$B5E4` | **$2A** |
| 59 | $162C | $AA0B | _BackPixPat | `$B6DE` | **$2A** |
| 60 | $1618 | $AA06 | _SetPortPix | `$B7D8` | $26 |
| 61 | $1684 | $AA21 | _OpColor | `$B83E` | $26 |
| 62 | $1688 | $AA22 | _HiliteColor | `$B8BE` | $26 |
| 63 | $1174 | $A8DD | _SetEmptyRgn | `$A506` | $10 $32 |
| 64 | $1074 | $A89D | _PenPat | `$A080` | **$2A** |
| 65 | $FF0 | $A87C | _BackPat | `$A13A` | **$2A** |
| 66 | $1A74 | $AB1D | _QDExtensions | `$8118` | - |
| 67 | $1664 | $AA19 | _GetForeColor | `$B43E` | **$36** |
| 68 | $1668 | $AA1A | _GetBackColor | `$B4CA` | **$37** |
| 69 | $814 | - | JInitCrsr (vector) | `$45D4` | - |
| 70 | $818 | - | JSetCrsr (vector) | `$433E` | - |
| 71 | $81C | - | JCrsrObscure (vector) | `$43CA` | - |
| 72 | $890 | - | JSetCCrsr (vector: set colour cursor) | `$4444` | - |
| 73 | $16B4 | $AA2D | _SetDeviceAttribute | `$9634` | $26 **$29** |
| 74 | $16C0 | $AA30 | _DisposGDevice | `$9684` | **$2B** |
| 75 | $11D8 | $A8F6 | _DrawPicture | `$472A` | $26 |
| 76 | $160C | $AA03 | _NewPixMap | `$B556` | - |
| 77 | $16FC | $AA3F | _SetEntries | `$95C2` | **$1A** **$29** |
| 78 | $10A8 | $A8AA | _SectRect | `$A37E` | $10 $32 |
| 79 | $FF4 | $A87D | _ClosePort | `$BC22` | - |
| 80 | $165C | $AA17 | _GetCPixel | `$B34C` | $0D **$29** **$33** |
| 81 | $F94 | $A865 | _GetPixel | `$B23E` | $0D **$29** **$33** |
| 82 | $1740 | $AA50 | _SeedCFill | `$4762` | - |
| 83 | $173C | $AA4F | _CalcCMask | `$47BC` | - |
| 84 | $1724 | $AA49 | _SaveEntries | `$94C6` | **$1A** |
| 85 | $1728 | $AA4A | _RestoreEntries | `$951A` | **$1A** |
| 86 | $16DC | $AA37 | _GetSubTable | `$956E` | **$1A** |
| 87 | $16A0 | $AA28 | _GetCTSeed | `$8098` | - |
| 88 | $1888 | $AAA2 | _PaletteDispatch | `$80D4` | - |
| 89 | $1850 | $AA94 | _ActivatePalette | `$93F4` | $26 |
| 90 | $1854 | $AA95 | _SetPalette | `$93B8` | $26 |
| 91 | $1880 | $AAA0 | _Palette2CTab | `$9428` | $26 |
| 92 | $16E4 | $AA39 | _MakeITable | `$9460` | **$1B** |
| 93 | $FB8 | $A86E | _InitGraf | `$4658` | $26 |
| 94 | $FB4 | $A86D | _InitPort | `$4682` | $26 |
| 95 | $FBC | $A86F | _OpenPort | `$46AC` | $26 |
| 96 | $1604 | $AA01 | _InitCPort | `$46D6` | $26 |
| 97 | $1600 | $AA00 | _OpenCPort | `$4700` | $26 |
| 98 | $1608 | $AA02 | CloseCPort (`$AA02`, per Traps.a "should never be used") | `$BC22` | - |
| 99 | $16B8 | $AA2E | _InitGDevice | `$9706` | **$12** **$13** **$14** **$16** $26 **$29** |
| 100 | $115C | $A8D7 | _BitMapRgn | `$BF0C` | $0D **$38** |
| 101 | $168C | $AA23 | _CharExtra | `$BC42` | $26 |
| 102 | $590 | $A064 (OS) | _MoveHHi | `$7DDC` | - |
| 103 | $FFFFFFFF | - | - | `$6C8A` | **$00** **$02** **$12** **$13** **$14** **$16** **$17** **$29** |
| 104 | $FFFFFFFE | - | - | `$6D1E` | **$00** **$11** $26 |
| 105 | $FFFFFFFD | - | - | `$6C70` | - |

## What this gives, and what it does not

* The accelerator replaces the QuickDraw **bottlenecks** (`StdLine`, `StdRect`,
  `StdRRect`, `StdOval`, `StdArc`, `StdPoly`, `StdRgn`, `StdText`, `CopyBits`),
  the region operations (`CopyRgn` ... `MapRgn`, `SectRect`, `BitMapRgn`), the
  Color QuickDraw state and pattern traps (`PenSize`, `PenPat`, `ForeColor`,
  `RGBForeColor`, `PmForeColor`, `PenPixPat`, `BackPixPat`, `OpColor`,
  `HiliteColor`, `GetForeColor`, ...), the colour-table / palette /
  `GDevice` traps (`GetSubTable`, `MakeITable`, `SetEntries`, `SetPalette`,
  `ActivatePalette`, `InitGDevice`, ...) and port setup (`InitGraf`, `OpenPort`,
  `InitCPort`, `SetOrigin`, `ClipRect`, ...), so the card sees the drawing state
  as well as the drawing calls.
* Operation-specific card commands identified so far: `$20` StdLine, `$21`
  StdText, `$23` StdArc, `$24` StdRect, `$2E` StdRRect, `$2F` StdOval, `$31`
  StdPoly, `$18` StdRgn, `$10` the region operations, `$32` clip / rectangle ops,
  `$35`/`$36`/`$37` pen, foreground and background colour state, `$2A` pen and
  pixel patterns, `$29` colour-table / device operations.
* **Antelope's side is now largely named** (`HOST_CARD_PROTOCOL.md`): the
  command dispatcher's table and DrawMultiObject's record tables decode
  through the recovered `.lit` key. DrawMultiObject, DrawLine, DrawArc,
  QuickPolys, DrawText, ColorMap, RSect, TrimRect, StretchBits, scaleBlt and
  the caches are identified there.


## What a patched routine does on the host (read from `GA_StdLine`, `GA_StdRect`, `GA_StdRgn`, `GA_StdOval`, `GA_StdPoly`, `GA_StdRRect`, `GA_StdArc`, `GA_CopyBits`)

All the shape bottlenecks share one skeleton; `EngineDispatch` is asked
first and the original QuickDraw routine is the fallback. (For these
commands `EngineDispatch` does not wait for the card. It appends a stream
record and replies at once; see the note above the main table.)

1. **Port state.** `GetA5 -> [A5] -> QD globals -> thePort`; the handler reads
   `thePort^.pnVis` (GrafPort offset `$42`). If the pen is hidden (negative) it
   does not ask the card to draw: it issues the synchronise command
   (`sub_4822`, `EngineDispatch(arg 8, 0, cmd $26)`) and calls the original.
2. **Ask the card.** `EngineDispatch(cmd, paramPtr, count)` (`$49C4`): the
   handler builds an array of longs on its stack and `CopyParamsToQueue` copies
   `count` of them after the command header (see the packet layout in `HOST_CARD_PROTOCOL.md`).
   Pointers are passed as **host addresses**, and bytes/words are sign- or
   zero-extended to longs. For the batched commands `EngineDispatch` then
   copies the data (rectangle, angles, polygon, region, text) into the
   stream record, so the card does not read host memory for them.
3. **Return code** (the word the card writes at `header+$1C`, or 0 when the card
   is not ready):
   * `1` -- taken by the card (for the batched commands: recorded in the
     stream); the handler returns at once;
   * `2` -- taken by the card, but the 68k still runs the original with the
     pen forced hidden (`pnVis = -1` around the call). `EngineDispatch`
     returns this when the port is recording a picture, region or polygon,
     so that the recording happens without drawing twice;
   * anything else -- not handled: the original is called normally.
   The original routine's address is fetched by `StoreCtxWord_AA6(tableAddr, ...)`
   (the trap-table address from the dispatch entry, e.g. `$1040` for `StdLine`)
   and called with the unchanged arguments. Around the fallback, `sub_86d6`
   / `sub_879a` save and restore a small piece of port state (it takes
   `&thePort^.portBits`), apparently making the bitmap safe for software drawing.

Packet parameters (longs after the header) as built by each handler:

| command | routine | count | parameters |
|---|---|--:|---|
| `$20` | StdLine | 1 | address of the argument area on the 68k stack (the `newPt` Point) |
| `$24` | StdRect | 2 | verb (`frame/paint/erase/invert/fill`, zero-extended), `Rect*` |
| `$2F` | StdOval | 2 | verb, `Rect*` |
| `$18` | StdRgn | 2 | verb, `RgnHandle` |
| `$31` | StdPoly | 2 | verb, `PolyHandle` |
| `$2E` | StdRRect | 4 | verb, `Rect*`, `ovalWidth`, `ovalHeight` (word -> long) |
| `$23` | StdArc | 4 | verb, `Rect*`, `startAngle`, `arcAngle` (word -> long) |

Port and colour state travels through the other commands (`$35`/`$36`/`$37`
pen / foreground / background colour, `$2A` patterns, `$32` clip, `$10`
regions), so the card keeps its own copy of the drawing state; the text
(`$21`) and `CopyBits` paths use a longer parameter block. These layouts are what
the Am29000 side must parse; they are exact for the handlers listed, from the
code, but the meaning of the verb values and of the replies beyond `1`/`2` is
inferred from QuickDraw's own conventions.

## Direct card calls per handler (`EngineDispatch(count, params, cmd)`)

Extracted from every handler's own code (calls made through helpers are not
included): `cmd:count` pairs in the order they appear. `$26:0` is the
synchronise / "state changed" command issued through the small wrapper
`sub_4822` (its argument is a mode value, not a parameter count). Handlers with
no direct call either do nothing on the card (they run the original routine
only) or reach it through a shared helper.

| # | routine | direct calls |
|--:|---|---|
| 0 | `GA_Translate24To32` | - |
| 1 | `GACursorTask` | - |
| 2 | `GA_CopyBits` | $17:1 |
| 3 | `GA_StdLine` | $20:1 |
| 4 | `GA_StdArc` | $23:4 |
| 5 | `GA_StdText` | $21:4 $21:4 |
| 6 | `GA_TrapAB27` | $15:1 |
| 7 | `GA_LowMem0800` | - |
| 8 | `GA_LowMem0804` | - |
| 9 | `GA_LowMem0808` | - |
| 10 | `GA_TrapAB9A` | $2A:2 |
| 11 | `GA_SetPenState` | $35:1 $2A:2 |
| 12 | `GA_PenSize` | $35:1 |
| 13 | `GA_PenMode` | - |
| 14 | `GA_PenNormal` | $35:1 $2A:1 |
| 15 | `GA_TrapAB23` | - |
| 16 | `GA_ForeColor` | $36:1 |
| 17 | `GA_RGBForeColor` | $36:1 |
| 18 | `GA_PmForeColor` | $36:1 |
| 19 | `GA_PmBackColor` | $37:1 $26:0 $3C:1 |
| 20 | `GA_StdRect` | $24:2 |
| 21 | `GA_StdOval` | $2F:2 |
| 22 | `GA_StdRRect` | $2E:4 |
| 23 | `GA_StdPoly` | $31:2 $21:4 $21:4 |
| 24 | `GA_StdRgn` | $18:2 |
| 25 | `GA_AddSearch` | $26:0 $29:1 |
| 26 | `GA_DelSearch` | $26:0 $29:1 |
| 27 | `GA_AddComp` | $26:0 $29:1 |
| 28 | `GA_DelComp` | $26:0 $29:1 |
| 29 | `GA_DisposPixPat` | $2C:1 |
| 30 | `GA_CopyPixPat` | $2A:2 |
| 31 | `GA_MakeRGBPat` | $2A:2 |
| 32 | `GA_TrapAB11` | $2A:2 $2A:2 |
| 33 | `GA_SetPBits` | $26:0 |
| 34 | `GA_PortSize` | $26:0 |
| 35 | `GA_MovePortTo` | $26:0 |
| 36 | `GA_SetOrigin` | $26:0 |
| 37 | `GA_SetClip` | $32:1 |
| 38 | `GA_ClipRect` | $32:1 |
| 39 | `GA_HidePen` | - |
| 40 | `GA_ShowPen` | - |
| 41 | `GA_BackColor` | $37:1 |
| 42 | `GA_ColorBit` | $26:0 |
| 43 | `GA_OpenRgn` | - |
| 44 | `GA_OpenPicture` | - |
| 45 | `GA_OpenPoly` | - |
| 46 | `GA_CopyRgn` | $10:1 $32:1 |
| 47 | `GA_SetRecRgn` | $10:1 $32:1 |
| 48 | `GA_RectRgn` | $10:1 $32:1 |
| 49 | `GA_OffsetRgn` | $10:1 $32:1 |
| 50 | `GA_InsetRgn` | $10:1 $32:1 |
| 51 | `GA_SectRgn` | $10:1 $32:1 |
| 52 | `GA_UnionRgn` | $10:1 $32:1 |
| 53 | `GA_DiffRgn` | $10:1 $32:1 |
| 54 | `GA_XOrRgn` | $10:1 $32:1 |
| 55 | `GA_MapRgn` | $10:1 $32:1 |
| 56 | `GA_RGBBackColor` | $37:1 |
| 57 | `GA_CopyPixMap` | $26:0 |
| 58 | `GA_PenPixPat` | $2A:2 |
| 59 | `GA_BackPixPat` | $2A:2 |
| 60 | `GA_SetPortPix` | $26:0 |
| 61 | `GA_OpColor` | $26:0 |
| 62 | `GA_HiliteColor` | $26:0 $33:1 $0F:1 |
| 63 | `GA_SetEmptyRgn` | $10:1 $32:1 |
| 64 | `GA_PenPat` | $2A:2 |
| 65 | `GA_BackPat` | $2A:2 |
| 66 | `GA_QDExtensions` | - |
| 67 | `GA_GetForeColor` | $36:1 |
| 68 | `GA_GetBackColor` | $37:1 |
| 69 | `GA_LowMem0814` | - |
| 70 | `GA_LowMem0818` | - |
| 71 | `GA_LowMem081C` | - |
| 72 | `GA_LowMem0890` | - |
| 73 | `GA_SetDeviceAttribute` | $26:0 $29:1 |
| 74 | `GA_DisposGDevice` | $2B:1 |
| 75 | `GA_DrawPicture` | - |
| 76 | `GA_NewPixMap` | - |
| 77 | `GA_SetEntries` | $29:1 $1A:1 |
| 78 | `GA_SectRect` | $10:1 $32:1 |
| 79 | `GA_CloseCPort` | - |
| 80 | `GA_GetCPixel` | - |
| 81 | `GA_GetPixel` | - |
| 82 | `GA_SeedCFill` | - |
| 83 | `GA_CalcCMask` | - |
| 84 | `GA_SaveEntries` | $1A:1 |
| 85 | `GA_RestoreEntries` | $1A:1 |
| 86 | `GA_GetSubTable` | $1A:1 |
| 87 | `GA_GETCTSEED` | - |
| 88 | `GA_PMGR` | - |
| 89 | `GA_ActivatePalette` | $26:0 |
| 90 | `GA_SetPalette` | $26:0 |
| 91 | `GA_Palette2CTab` | $26:0 |
| 92 | `GA_MakeITable` | $1B:1 |
| 93 | `GA_InitGraf` | - |
| 94 | `GA_InitPort` | - |
| 95 | `GA_OpenPort` | - |
| 96 | `GA_InitCPort` | - |
| 97 | `GA_OpenCPort` | - |
| 98 | `GA_CloseCPort` | - |
| 99 | `GA_InitGDevice` | $26:0 $29:1 $29:1 |
| 100 | `GA_BitMapRgn` | - |
| 101 | `GA_CharExtra` | $26:0 $2A:2 $26:0 |
| 102 | `GA_MoveHHi` | - |
| 103 | `GA_ControlFFFFFFFF` | $00:0 $02:1 $00:0 |
| 104 | `GA_ControlFFFFFFFE` | $26:14 $11:0 $00:0 |
| 105 | `GA_ControlFFFFFFFD` | - |

## Command groups

| command | used by | params (longs) | meaning (inferred) |
|---|---|--:|---|
| `$10` or `$32` | `CopyRgn`, `SetRecRgn`, `RectRgn`, `OffsetRgn`, `InsetRgn`, `SectRgn`, `UnionRgn`, `DiffRgn`, `XOrRgn`, `MapRgn`, `SetEmptyRgn`, `SectRect` | 1 | the patch runs the original, then sends `$10` if the destination is the region the engine caches as the visible region (`$120` of its globals), or `$32` if it is the cached clip region (`$124`). Other regions send nothing (`GA_CopyRgn` `$A472`; it also skips equal regions with `_EqualRgn`). Stream record `$6C` or `$6A` |
| `$32` | `SetClip`, `ClipRect` | 1 | clip region changed: stream record `$6A` |
| `$35` | `PenSize`, `SetPenState`, `PenNormal` | 1 | pen size: stream record `$6E` |
| `$36` | `ForeColor`, `RGBForeColor`, `PmForeColor`, `GetForeColor` | 1 | foreground colour: stream record `$66` or `$64` |
| `$37` | `BackColor`, `RGBBackColor`, `PmBackColor`, `GetBackColor` | 1 | background colour: stream record `$6D` or `$6B` |
| `$2A` | `PenPat`, `BackPat`, `PenPixPat`, `BackPixPat`, `CopyPixPat`, `MakeRGBPat`, `SetPenState`, `CharExtra` | 2 | pattern / pixel-pattern (pointer plus a second long) |
| `$2C` | `DisposPixPat` | 1 | pixel pattern disposed (release the card's copy) |
| `$29` | `AddSearch`, `DelSearch`, `AddComp`, `DelComp`, `SetDeviceAttribute`, `SetEntries`, `InitGDevice` | 1 | search/complement procs and device attributes |
| `$1A` | `SetEntries`, `SaveEntries`, `RestoreEntries`, `GetSubTable` | 1 | colour-table / palette entries |
| `$1B` | `MakeITable` | 1 | inverse colour table |
| `$2B` | `DisposGDevice` | 1 | graphics device released |
| `$33`, `$0F` | `HiliteColor` | 1 | highlight colour state |
| `$26` | `ColorBit`, `CopyPixMap`, `SetPortPix`, `OpColor`, `ActivatePalette`, `SetPalette`, `Palette2CTab`, `InitGDevice`, `CharExtra`, ... | 0 | synchronise / flush before software handles the call |
| `$00`, `$02`, `$11`, `$26:14` | the three control records (`$FFFFFFFF`, `$FFFFFFFE`) | 0-1 | engine start-up / shut-down and mode handshakes (not QuickDraw traps) |

Every command above is a *state-mirroring* call except the shape and text
commands in the previous table. `$10`, `$32`, `$35`, `$36` and `$37` become
stream records (see the note at the top). The others (`$29`, `$1A`, `$1B`,
`$2B`, `$2C`, `$33`/`$0F`) are sent as commands, and keep the card's caches
of host objects (GDevices, colour tables, pixel patterns) up to date.


## `GA_StdText` and `GA_CopyBits`

**StdText** (`GA_StdText`, command `$21`). The patch takes the four StdText
arguments (`count`, `textAddr`, `numer`, `denom`), returns immediately if
`count <= 0`, and, if the pen is visible and the port's text mode is plain,
builds a small record on its stack: `+0 count (word)`, `+2 textAddr (long)`,
`+6 numer (Point)`, `+10 denom (Point)` followed by port state (font, face,
size, pen mode, colours). The helper at `$3868` (the code just before
`GA_StdText`) sets up the foreground colour via `_PaletteDispatch` and
`_RGBForeColor`, then sends **four longs**: the count sign-extended, the text
address, a pointer to `numer` and a pointer to `denom`
(`EngineDispatch(4, &block, $21)`). `EngineDispatch` then measures the text,
uploads the font if the card lacks it (`$30`), and writes a `$67` font
record (when the font changed) and a text record 6. Reply `1` means drawn; `2` runs the original
with the pen hidden, as for the shapes; otherwise the original is called. Before
that the handler measures the text itself (`_StdTxMeas`, `_GetFontInfo`) and
builds a region (`_NewRgn`, `_RectRgn`) so that it can restore the port's pen
and clip afterwards.

**CopyBits** (`GA_CopyBits`) does **not** call the card itself. It is a
bracketing patch: it keeps a nesting counter at `globals+$18`, clears a pair of
saved longs at `globals+$40/$44` when the counter is zero (these are the
deferred-cursor counters: while the counter is raised, the cursor patches
only record ShieldCursor/ShowCursor/HideCursor), calls
`sub_86d6`/`sub_879a` around the original (the same port-state save/restore as
the shape handlers) when the destination device record has `+$5C` set, and
calls the original `CopyBits` with all six stack arguments through
`StoreCtxWord_AA6($11B0)`. The one accelerated query associated with it is
`sub_494E`, which sends **command `$17`** with one long (a pointer to a record at
`*(unit+$0C) + $604`) after a readiness check; reply `1` stores the record's
second long in `globals+$182`. `CopyBits` reaches the card through its own call to
StretchBits: the internal trap `$AB27` is patched (`GA_TrapAB27`) and sends
command `$15` with a parameter block. If the card does the transfer, the
recorded cursor calls are dropped; otherwise they are replayed and the 68K
StretchBits runs (`HOST_CARD_PROTOCOL.md`, "StretchBits" and "Deferred
cursor calls during CopyBits"). `$17` looks like a status/handshake query,
not a blit.
