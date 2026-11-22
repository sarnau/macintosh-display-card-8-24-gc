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
its selector -- the value stored at `header+$48` of the command block the
Am29000 receives (see `HOST_CARD_PROTOCOL.md` section 7). Codes shared by many
handlers (`$0D`, `$26`, `$38` and a few more) are begin/end/synchronise
commands, not the operation itself; the operation-specific ones are in bold.
This list is extracted mechanically and is a reading of the code, not a
confirmed table.

| # | trap table addr | trap | QuickDraw / Toolbox routine | 68k handler | card commands |
|--:|---|---|---|---|---|
| 0 | $644 | $A091 (OS) | _Translate24To32 | `$7F50` | - |
| 1 | $8EE | - | - | `$801C` | - |
| 2 | $11B0 | $A8EC | _CopyBits | `$483C` | $0D **$38** |
| 3 | $1040 | $A890 | _StdLine | `$3682` | $0D **$20** $26 **$38** |
| 4 | $10F4 | $A8BD | _StdArc | `$3DDC` | $0D **$23** $26 **$38** |
| 5 | $1008 | $A882 | _StdText | `$3A9C` | $0D **$21** $26 **$38** |
| 6 | $1A9C | $AB27 | (not in Traps.h) | `$32BC` | $0D **$15** **$38** |
| 7 | $800 | - | - | `$42B8` | - |
| 8 | $804 | - | - | `$420C` | - |
| 9 | $808 | - | - | `$44C4` | - |
| 10 | $1C68 | $AB9A | (not in Traps.h) | `$9278` | **$2A** |
| 11 | $1064 | $A899 | _SetPenState | `$9F04` | **$2A** **$35** |
| 12 | $106C | $A89B | _PenSize | `$9FD0` | **$35** |
| 13 | $1070 | $A89C | _PenMode | `$A060` | - |
| 14 | $1078 | $A89E | _PenNormal | `$A1E2` | **$2A** **$35** |
| 15 | $1A8C | $AB23 | (not in Traps.h) | `$7DAC` | - |
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
| 32 | $1A44 | $AB11 | (not in Traps.h) | `$99D6` | **$2A** |
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
| 69 | $814 | - | - | `$45D4` | - |
| 70 | $818 | - | - | `$433E` | - |
| 71 | $81C | - | - | `$43CA` | - |
| 72 | $890 | - | - | `$4444` | - |
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
| 98 | $1608 | $AA02 | (not in Traps.h) | `$BC22` | - |
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
* **Naming Antelope's functions from this is not yet possible.** The card-side
  command table lives in `.lit`/`.data`, whose relocation records all point at a
  single placeholder symbol and whose target offsets are in the *masked* word
  contents; `.text` itself is masked as well. Once Antelope's mask is solved,
  the command table gives command -> function entry directly, and the
  names above carry over (a command is the unit of naming; many functions
  below it are shared helpers).

