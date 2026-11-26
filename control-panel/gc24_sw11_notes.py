HEADER = r"""* ==================================================================
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
*"""

EXTRA_SEEDS = [0x6baa, 0xa3ee, 0xa438, 0xa44c]

NOTES = {
 0x6224: ["EngineDispatch(cmd, args, n)  -  System 7 EngineDispatch $49C4.",
          "a3 = unit record ([[globals+$214]]).  Bails to $7AFE unless the unit's",
          "flags +$8 have $27 set and $600 clear; re-initialises the card through",
          "s7_sub_6f4e if unit+$1C says it is not ready."],
 0x628e: ["Selector switch: cmd - $0C indexes a 45-entry table ($0C..$38).",
          "Selectors below $0C, above $38 and the unlisted ones fall to L7748,",
          "the generic packet path (System 7: the same switch in EngineDispatch)."],
 0x7748: ["Generic packet path (default case of the switch)."],
 0x77d4: ["Packet post  -  System 7 $5F10-$5F7E.",
          "-$2a(a6) = packet (unit+$0C), a4 = unit+$18 = the argument area",
          "(System 7 $5F26 `movea.l $18(a4),a3'), -$2e(a6) = status-long pointer",
          "(unit+$10).  Status bit 3 set: unit+$1C |= $10, return -1."],
 0x781c: ["status long = 0, packet+$18 = 0, +$48 = cmd, +$4C = unit+$20 (then",
          "unit+$20 += 1), +$50 = n."],
 0x7850: ["Argument copy  -  System 7 CopyParamsToQueue $5F80-$6048: 8 longs per",
          "loop pass, move.l (args)+,(a4)+ into the area at [unit+$18], then a",
          "switch on n-1 ($78D6, System 7 $5FF6) copies the remaining 1-7."],
 0x7938: ["Go  -  System 7 $604A: packet+$14 = -1, unit+$1C |= $0C, unit+$170 =",
          "cmd, deadline = Ticks + unit+$02."],
 0x7962: ["Wait loop  -  System 7 $6074-$6116.  Loops while (status long & 3) == 0",
          "(test at $79FE).  Status bit 3/4 with s7_sub_6f4e succeeding: return 0;",
          "bit 2: acknowledge and call s7_sub_6442; past the deadline with no change",
          "in packet+$1C4: s7_sub_75fe(unit, 2, 0) and the timeout exit $7A96."],
 0x7a60: ["Reply  -  System 7 $616C: result = packet+$1C."],
 0x7a96: ["Timeout exit  -  System 7 $61B0: unit+$1C &= ~$0C, |= 2; return 0."],
 0x884a: ["Card (re)initialisation  -  System 7 sub_6f4e.  Called by",
          "EngineDispatch when the unit is not ready."],
 0x8ae8: ["Packet-pointer read-back  -  System 7 $726A-$728E.  a4 = packet.",
          "packet+$20 = unit+$14; unit+$18 = (packet & $FFF00000) |",
          "([packet+$54] & $000FFFFF): the argument area is wherever the card",
          "published it (System 6 Antelope: packet+$64C), in the packet's 1 MB",
          "window.  unit+$1C |= 1 (ready); then selector 0 through EngineDispatch."],
}

NAMES = {0x6224: 'EngineDispatch', 0x7850: 'CopyParamsToQueue', 0xa532: 'HWPrivProbe'}

# Every S6 function matched to its System 7 counterpart in gc24.s: opcode
# signatures (mnemonics + immediates, branch/call targets and registers
# masked), dispatch handlers by their trap-table slot, the rest by exact
# signature, difflib ratio >= 0.7 or the call graph of matched pairs, a few
# checked by hand.  Names are S7's labels; an unnamed S7 sub_xxxx / Lxxxx
# becomes s7_sub_xxxx / s7_Lxxxx (the S7 address, not this file's).  Hand
# NAMES/NOTES above take precedence.
# --- System 7 counterparts (matched by opcode signature against gc24.s) ---
S7_FUNCS = {
 0x1230: ('GetA5', ['GetA5  -  System 7 $8010 (identical bytes, S6 MacsBug name).', 'S7: GetA5  -  returns A5 (the QuickDraw/app globals world) in D0.']),
 0x123c: ('GACursorTask', ['GACursorTask  -  System 7 $801C (same trap slot $8EE, code r=0.97).']),
 0x12b4: ('GA_GETCTSEED', ['GA_GETCTSEED  -  System 7 $8098 (identical code).']),
 0x12f0: ('GA_PMGR', ['GA_PMGR  -  System 7 $80D4 (identical code).']),
 0x1334: ('GA_QDExtensions', ['GA_QDExtensions  -  System 7 $8118 (same trap slot $1A74, code r=0.89).', 'S7: Patch #66 replaces _QDExtensions ($AB1D); no EngineDispatch command found']),
 0x13cc: ('s7_sub_8da4', ['s7_sub_8da4  -  System 7 $8DA4 (similar code, r=0.80).']),
 0x141c: ('s7_sub_8df2', ['s7_sub_8df2  -  System 7 $8DF2 (similar code, r=0.89).']),
 0x145c: ('s7_sub_8e38', ['s7_sub_8e38  -  System 7 $8E38 (similar code, r=0.71).']),
 0x1530: ('s7_sub_8f04', ['s7_sub_8f04  -  System 7 $8F04 (similar code, r=0.82).']),
 0x1746: ('s7_sub_90ee', ['s7_sub_90ee  -  System 7 $90EE (checked by hand, r=0.67).']),
 0x17aa: ('s7_sub_9146', ['s7_sub_9146  -  System 7 $9146 (identical code).']),
 0x17e2: ('s7_sub_917e', ['s7_sub_917e  -  System 7 $917E (similar code, r=0.83).']),
 0x1808: ('s7_sub_91aa', ['s7_sub_91aa  -  System 7 $91AA (similar code, r=0.88).']),
 0x18e8: ('GA_TrapAB9A', ['GA_TrapAB9A  -  System 7 $9278 (same trap slot $1C68, code r=0.94).', 'S7: Patch #10 replaces trap $AB9A; card commands: $2A']),
 0x1a2a: ('GA_SetPalette', ['GA_SetPalette  -  System 7 $93B8 (same trap slot $1854, code r=0.91).', 'S7: Patch #90 replaces _SetPalette ($AA95); card commands: $26']),
 0x1a70: ('GA_ActivatePalette', ['GA_ActivatePalette  -  System 7 $93F4 (same trap slot $1850, code r=0.84).', 'S7: Patch #89 replaces _ActivatePalette ($AA94); card commands: $26']),
 0x1aa4: ('GA_Palette2CTab', ['GA_Palette2CTab  -  System 7 $9428 (same trap slot $1880, code r=0.83).', 'S7: Patch #91 replaces _Palette2CTab ($AAA0); card commands: $26']),
 0x1ae2: ('GA_MakeITable', ['GA_MakeITable  -  System 7 $9460 (same trap slot $16E4, code r=0.93).', 'S7: Patch #92 replaces _MakeITable ($AA39); card commands: $1B']),
 0x1b4a: ('GA_SaveEntries', ['GA_SaveEntries  -  System 7 $94C6 (same trap slot $1724, code r=0.93).', 'S7: Patch #84 replaces _SaveEntries ($AA49); card commands: $1A']),
 0x1ba8: ('GA_RestoreEntries', ['GA_RestoreEntries  -  System 7 $951A (same trap slot $1728, code r=0.93).', 'S7: Patch #85 replaces _RestoreEntries ($AA4A); card commands: $1A']),
 0x1c06: ('GA_GetSubTable', ['GA_GetSubTable  -  System 7 $956E (same trap slot $16DC, code r=0.95).', 'S7: Patch #86 replaces _GetSubTable ($AA37); card commands: $1A']),
 0x1c5e: ('GA_SetEntries', ['GA_SetEntries  -  System 7 $95C2 (same trap slot $16FC, code r=0.95).', 'S7: Patch #77 replaces _SetEntries ($AA3F); card commands: $1A $29']),
 0x1cd6: ('GA_SetDeviceAttribute', ['GA_SetDeviceAttribute  -  System 7 $9634 (identical code).', 'S7: Patch #73 replaces _SetDeviceAttribute ($AA2D); card commands: $26 $29']),
 0x1d20: ('GA_DisposGDevice', ['GA_DisposGDevice  -  System 7 $9684 (identical code).', 'S7: Patch #74 replaces _DisposGDevice ($AA30); card commands: $2B']),
 0x1d50: ('GA_AddSearch', ['GA_AddSearch  -  System 7 $96B8 (same trap slot $16E8, code r=0.95).', 'S7: Patch #25 replaces _AddSearch ($AA3A); card commands: $26 $29']),
 0x1da0: ('GA_InitGDevice', ['GA_InitGDevice  -  System 7 $9706 (same trap slot $16B8, code r=0.98).', 'S7: Patch #99 replaces _InitGDevice ($AA2E); card commands: $12 $13 $14 $16 $26 $29']),
 0x1e20: ('GA_DelSearch', ['GA_DelSearch  -  System 7 $9794 (same trap slot $1730, code r=0.95).', 'S7: Patch #26 replaces _DelSearch ($AA4C); card commands: $26 $29']),
 0x1e70: ('GA_AddComp', ['GA_AddComp  -  System 7 $97E2 (same trap slot $16EC, code r=0.95).', 'S7: Patch #27 replaces _AddComp ($AA3B); card commands: $26 $29']),
 0x1ec0: ('GA_DelComp', ['GA_DelComp  -  System 7 $9830 (same trap slot $1734, code r=0.95).', 'S7: Patch #28 replaces _DelComp ($AA4D); card commands: $26 $29']),
 0x1f10: ('GA_DisposPixPat', ['GA_DisposPixPat  -  System 7 $987E (identical code).', 'S7: Patch #29 replaces _DisposPixPat ($AA08); card commands: $2C']),
 0x1f40: ('GA_CopyPixPat', ['GA_CopyPixPat  -  System 7 $98B2 (same trap slot $1624, code r=0.95).', 'S7: Patch #30 replaces _CopyPixPat ($AA09); card commands: $2A']),
 0x1fd2: ('GA_MakeRGBPat', ['GA_MakeRGBPat  -  System 7 $9948 (same trap slot $1634, code r=0.95).', 'S7: Patch #31 replaces _MakeRGBPat ($AA0D); card commands: $2A']),
 0x205c: ('GA_TrapAB11', ['GA_TrapAB11  -  System 7 $99D6 (same trap slot $1A44, code r=0.96).', 'S7: Patch #32 replaces trap $AB11; card commands: $2A']),
 0x210a: ('s7_sub_9a88', ['s7_sub_9a88  -  System 7 $9A88 (similar code, r=0.90).']),
 0x223e: ('GA_SetPBits', ['GA_SetPBits  -  System 7 $9BCA (same trap slot $FD4, code r=0.89).', 'S7: Patch #33 replaces _SetPBits ($A875); card commands: $26']),
 0x22da: ('GA_PortSize', ['GA_PortSize  -  System 7 $9C62 (same trap slot $FD8, code r=0.96).', 'S7: Patch #34 replaces _PortSize ($A876); card commands: $26']),
 0x235a: ('GA_MovePortTo', ['GA_MovePortTo  -  System 7 $9CF2 (same trap slot $FDC, code r=0.97).', 'S7: Patch #35 replaces _MovePortTo ($A877); card commands: $26']),
 0x23ac: ('GA_SetOrigin', ['GA_SetOrigin  -  System 7 $9D4C (same trap slot $FE0, code r=0.82).', 'S7: Patch #36 replaces _SetOrigin ($A878); card commands: $26']),
 0x241a: ('GA_SetClip', ['GA_SetClip  -  System 7 $9DBE (same trap slot $FE4, code r=0.94).', 'S7: Patch #37 replaces _SetClip ($A879); card commands: $32']),
 0x248a: ('GA_ClipRect', ['GA_ClipRect  -  System 7 $9E34 (same trap slot $FEC, code r=0.92).', 'S7: Patch #38 replaces _ClipRect ($A87B); card commands: $32']),
 0x252a: ('GA_HidePen', ['GA_HidePen  -  System 7 $9ED0 (same trap slot $1058, code r=0.88).', 'S7: Patch #39 replaces _HidePen ($A896); no EngineDispatch command found']),
 0x253c: ('GA_ShowPen', ['GA_ShowPen  -  System 7 $9EEA (same trap slot $105C, code r=0.88).', 'S7: Patch #40 replaces _ShowPen ($A897); no EngineDispatch command found']),
 0x254e: ('GA_SetPenState', ['GA_SetPenState  -  System 7 $9F04 (same trap slot $1064, code r=0.92).', 'S7: Patch #11 replaces _SetPenState ($A899); card commands: $2A $35']),
 0x2614: ('GA_PenSize', ['GA_PenSize  -  System 7 $9FD0 (same trap slot $106C, code r=0.98).', 'S7: Patch #12 replaces _PenSize ($A89B); card commands: $35']),
 0x269a: ('GA_PenMode', ['GA_PenMode  -  System 7 $A060 (identical code).', 'S7: Patch #13 replaces _PenMode ($A89C); no EngineDispatch command found']),
 0x26b8: ('GA_PenPat', ['GA_PenPat  -  System 7 $A080 (same trap slot $1074, code r=0.91).', 'S7: Patch #64 replaces _PenPat ($A89D); card commands: $2A']),
 0x2764: ('GA_BackPat', ['GA_BackPat  -  System 7 $A13A (same trap slot $FF0, code r=0.92).', 'S7: Patch #65 replaces _BackPat ($A87C); card commands: $2A']),
 0x2802: ('GA_PenNormal', ['GA_PenNormal  -  System 7 $A1E2 (same trap slot $1078, code r=0.94).', 'S7: Patch #14 replaces _PenNormal ($A89E); card commands: $2A $35']),
 0x28ce: ('GA_ColorBit', ['GA_ColorBit  -  System 7 $A2B8 (same trap slot $F90, code r=0.87).', 'S7: Patch #42 replaces _ColorBit ($A864); card commands: $26']),
 0x292a: ('GA_OpenRgn', ['GA_OpenRgn  -  System 7 $A31E (same trap slot $1168, code r=0.88).', 'S7: Patch #43 replaces _OpenRgn ($A8DA); no EngineDispatch command found']),
 0x293c: ('GA_OpenPicture', ['GA_OpenPicture  -  System 7 $A338 (same trap slot $11CC, code r=0.89).', 'S7: Patch #44 replaces _OpenPicture ($A8F3); no EngineDispatch command found']),
 0x2968: ('GA_OpenPoly', ['GA_OpenPoly  -  System 7 $A35E (identical code).', 'S7: Patch #45 replaces _OpenPoly ($A8CB); no EngineDispatch command found']),
 0x2986: ('GA_SectRect', ['GA_SectRect  -  System 7 $A37E (same trap slot $10A8, code r=0.98).', 'S7: Patch #78 replaces _SectRect ($A8AA); card commands: $10 $32']),
 0x2a6a: ('GA_CopyRgn', ['GA_CopyRgn  -  System 7 $A472 (same trap slot $1170, code r=0.97).', 'S7: Patch #46 replaces _CopyRgn ($A8DC); card commands: $10 $32']),
 0x2afa: ('GA_SetEmptyRgn', ['GA_SetEmptyRgn  -  System 7 $A506 (same trap slot $1174, code r=0.96).', 'S7: Patch #63 replaces _SetEmptyRgn ($A8DD); card commands: $10 $32']),
 0x2b9c: ('GA_SetRecRgn', ['GA_SetRecRgn  -  System 7 $A5AA (same trap slot $1178, code r=0.83).', 'S7: Patch #47 replaces _SetRecRgn ($A8DE); card commands: $10 $32']),
 0x2c7a: ('GA_RectRgn', ['GA_RectRgn  -  System 7 $A672 (same trap slot $117C, code r=0.94).', 'S7: Patch #48 replaces _RectRgn ($A8DF); card commands: $10 $32']),
 0x2d32: ('GA_OffsetRgn', ['GA_OffsetRgn  -  System 7 $A726 (same trap slot $1180, code r=0.92).', 'S7: Patch #49 replaces _OfsetRgn ($A8E0); card commands: $10 $32']),
 0x2e20: ('GA_InsetRgn', ['GA_InsetRgn  -  System 7 $A820 (same trap slot $1184, code r=0.92).', 'S7: Patch #50 replaces _InsetRgn ($A8E1); card commands: $10 $32']),
 0x2f0e: ('GA_SectRgn', ['GA_SectRgn  -  System 7 $A91A (same trap slot $1190, code r=0.95).', 'S7: Patch #51 replaces _SectRgn ($A8E4); card commands: $10 $32']),
 0x2ff0: ('GA_UnionRgn', ['GA_UnionRgn  -  System 7 $AA0A (same trap slot $1194, code r=0.95).', 'S7: Patch #52 replaces _UnionRgn ($A8E5); card commands: $10 $32']),
 0x30d2: ('GA_DiffRgn', ['GA_DiffRgn  -  System 7 $AAFA (same trap slot $1198, code r=0.95).', 'S7: Patch #53 replaces _DiffRgn ($A8E6); card commands: $10 $32']),
 0x31b4: ('GA_XOrRgn', ['GA_XOrRgn  -  System 7 $ABEA (same trap slot $119C, code r=0.95).', 'S7: Patch #54 replaces _XOrRgn ($A8E7); card commands: $10 $32']),
 0x3296: ('GA_MapRgn', ['GA_MapRgn  -  System 7 $ACDA (same trap slot $11EC, code r=0.96).', 'S7: Patch #55 replaces _MapRgn ($A8FB); card commands: $10 $32']),
 0x339c: ('GA_ForeColor', ['GA_ForeColor  -  System 7 $ADF0 (same trap slot $F88, code r=0.93).', 'S7: Patch #16 replaces _ForeColor ($A862); card commands: $36']),
 0x33fc: ('GA_RGBForeColor', ['GA_RGBForeColor  -  System 7 $AE56 (same trap slot $1650, code r=0.83).', 'S7: Patch #17 replaces _RGBForeColor ($AA14); card commands: $36']),
 0x348e: ('GA_PmForeColor', ['GA_PmForeColor  -  System 7 $AF00 (same trap slot $185C, code r=0.81).', 'S7: Patch #18 replaces _PmForeColor ($AA97); card commands: $36']),
 0x352c: ('GA_BackColor', ['GA_BackColor  -  System 7 $AFA0 (same trap slot $F8C, code r=0.93).', 'S7: Patch #41 replaces _BackColor ($A863); card commands: $37']),
 0x358c: ('GA_RGBBackColor', ['GA_RGBBackColor  -  System 7 $B006 (same trap slot $1654, code r=0.83).', 'S7: Patch #56 replaces _RGBBackColor ($AA15); card commands: $37']),
 0x361e: ('GA_PmBackColor', ['GA_PmBackColor  -  System 7 $B0B0 (same trap slot $1860, code r=0.81).', 'S7: Patch #19 replaces _PmBackColor ($AA98); card commands: $37']),
 0x36bc: ('s7_sub_b1be', ['s7_sub_b1be  -  System 7 $B1BE (checked by hand, r=0.57).']),
 0x3762: ('GA_GetPixel', ['GA_GetPixel  -  System 7 $B23E (same trap slot $F94, code r=0.83).', 'S7: Patch #81 replaces _GetPixel ($A865); card commands: $0D $29 $33']),
 0x3868: ('GA_GetCPixel', ['GA_GetCPixel  -  System 7 $B34C (same trap slot $165C, code r=0.84).', 'S7: Patch #80 replaces _GetCPixel ($AA17); card commands: $0D $29 $33']),
 0x3952: ('GA_GetForeColor', ['GA_GetForeColor  -  System 7 $B43E (same trap slot $1664, code r=0.90).', 'S7: Patch #67 replaces _GetForeColor ($AA19); card commands: $36']),
 0x39ea: ('GA_GetBackColor', ['GA_GetBackColor  -  System 7 $B4CA (same trap slot $1668, code r=0.90).', 'S7: Patch #68 replaces _GetBackColor ($AA1A); card commands: $37']),
 0x3a82: ('GA_NewPixMap', ['GA_NewPixMap  -  System 7 $B556 (identical code).', 'S7: Patch #76 replaces _NewPixMap ($AA03); no EngineDispatch command found']),
 0x3aa8: ('GA_CopyPixMap', ['GA_CopyPixMap  -  System 7 $B57E (same trap slot $1614, code r=0.93).', 'S7: Patch #57 replaces _CopyPixMap ($AA05); card commands: $26']),
 0x3b0a: ('GA_PenPixPat', ['GA_PenPixPat  -  System 7 $B5E4 (same trap slot $1628, code r=0.87).', 'S7: Patch #58 replaces _PenPixPat ($AA0A); card commands: $2A']),
 0x3bf2: ('GA_BackPixPat', ['GA_BackPixPat  -  System 7 $B6DE (same trap slot $162C, code r=0.87).', 'S7: Patch #59 replaces _BackPixPat ($AA0B); card commands: $2A']),
 0x3cda: ('GA_SetPortPix', ['GA_SetPortPix  -  System 7 $B7D8 (same trap slot $1618, code r=0.94).', 'S7: Patch #60 replaces _SetPortPix ($AA06); card commands: $26']),
 0x3d30: ('GA_OpColor', ['GA_OpColor  -  System 7 $B83E (same trap slot $1684, code r=0.88).', 'S7: Patch #61 replaces _OpColor ($AA21); card commands: $26']),
 0x3db4: ('GA_HiliteColor', ['GA_HiliteColor  -  System 7 $B8BE (same trap slot $1688, code r=0.88).', 'S7: Patch #62 replaces _HiliteColor ($AA22); card commands: $26']),
 0x3e3a: ('GA_BitMapRgn', ['GA_BitMapRgn  -  System 7 $BF0C (same trap slot $115C, code r=0.46).', 'S7: Patch #100 replaces _BitMapRgn ($A8D7); card commands: $0D $38']),
 0x3eb2: ('s7_Lb940', ['s7_Lb940  -  System 7 $B940 (similar code, r=0.89).']),
 0x3f24: ('s7_Lb9b4', ['s7_Lb9b4  -  System 7 $B9B4 (similar code, r=0.96).']),
 0x3f64: ('s7_Lb9fc', ['s7_Lb9fc  -  System 7 $B9FC (similar code, r=0.92).']),
 0x3fcc: ('s7_Lba64', ['s7_Lba64  -  System 7 $BA64 (similar code, r=0.83).']),
 0x4050: ('s7_Lbb14', ['s7_Lbb14  -  System 7 $BB14 (similar code, r=0.86).']),
 0x40b8: ('GA_CloseCPort', ['GA_CloseCPort  -  System 7 $BC22 (same trap slot $1608, code r=0.76).', 'S7: Patch #79 replaces _ClosePort ($A87D); no EngineDispatch command found']),
 0x40d6: ('GA_CharExtra', ['GA_CharExtra  -  System 7 $BC42 (same trap slot $168C, code r=0.87).', 'S7: Patch #101 replaces _CharExtra ($AA23); card commands: $26']),
 0x4152: ('s7_sub_bcc8', ['s7_sub_bcc8  -  System 7 $BCC8 (similar code, r=0.77).']),
 0x41fe: ('s7_Lbd76', ['s7_Lbd76  -  System 7 $BD76 (identical code).']),
 0x421a: ('s7_sub_bd94', ['s7_sub_bd94  -  System 7 $BD94 (similar code, r=0.85).']),
 0x42ce: ('s7_Lbe74', ['s7_Lbe74  -  System 7 $BE74 (similar code, r=0.80).']),
 0x433a: ('s7_Lbecc', ['s7_Lbecc  -  System 7 $BECC (similar code, r=0.95).']),
 0x4376: ('s7_sub_81bc', ['s7_sub_81bc  -  System 7 $81BC (similar code, r=0.77).']),
 0x4384: ('s7_sub_8262', ['s7_sub_8262  -  System 7 $8262 (similar code, r=0.85).']),
 0x4774: ('s7_sub_860e', ['s7_sub_860e  -  System 7 $860E (similar code, r=0.80).']),
 0x4842: ('s7_sub_86d6', ['s7_sub_86d6  -  System 7 $86D6 (similar code, r=0.76).']),
 0x48fe: ('s7_sub_879a', ['s7_sub_879a  -  System 7 $879A (similar code, r=0.73).']),
 0x492e: ('s7_sub_87cc', ['s7_sub_87cc  -  System 7 $87CC (similar code, r=0.84).']),
 0x49ae: ('s7_sub_884e', ['s7_sub_884e  -  System 7 $884E (similar code, r=0.86).']),
 0x4a44: ('s7_sub_88e6', ['s7_sub_88e6  -  System 7 $88E6 (similar code, r=0.72).']),
 0x4f14: ('GA_TrapAB23', ['GA_TrapAB23  -  System 7 $7DAC (identical code).', 'S7: Patch #15 replaces trap $AB23; no EngineDispatch command found']),
 0x4f2c: ('GetD2', ['GetD2  -  System 7 $7DC4 (identical bytes, S6 MacsBug name).', 'S7: embedded MacsBug symbols that follow each one) --']),
 0x4f38: ('SetD2', ['SetD2  -  System 7 $7DD0 (identical code).']),
 0x4f44: ('BitFieldExtract', ['BitFieldExtract  -  System 7 $7E0C (identical bytes, S6 MacsBug name).']),
 0x4f68: ('FixScale', ['FixScale  -  System 7 $7E30 (identical bytes, S6 MacsBug name).']),
 0x4f90: ('EqualFontOutput', ['EqualFontOutput  -  System 7 $7E58 (identical bytes, S6 MacsBug name).']),
 0x4fc4: ('s7_sub_7e8c', ['s7_sub_7e8c  -  System 7 $7E8C (identical bytes).']),
 0x5030: ('WidthTableCheckSum', ['WidthTableCheckSum  -  System 7 $7EF8 (identical bytes, S6 MacsBug name).']),
 0x5088: ('GA_Translate24To32', ['GA_Translate24To32  -  System 7 $7F50 (same trap slot $644, code r=0.00).', 'S7: Patch #0 replaces _Translate24To32 ($A091); no EngineDispatch command found']),
 0x5148: ('GA_TrapAB27', ['GA_TrapAB27  -  System 7 $32BC (same trap slot $1A9C, code r=0.71).', 'S7: Patch #6 replaces trap $AB27; card commands: $0D $15 $38']),
 0x5364: ('GA_StdRgn', ['GA_StdRgn  -  System 7 $358C (same trap slot $1144, code r=0.96).', 'S7: Patch #24 replaces _StdRgn ($A8D1); card commands: $0D $18 $26 $38']),
 0x5444: ('GA_StdLine', ['GA_StdLine  -  System 7 $3682 (same trap slot $1040, code r=0.96).', 'S7: Patch #3 replaces _StdLine ($A890); card commands: $0D $20 $26 $38']),
 0x5518: ('GA_StdPoly', ['GA_StdPoly  -  System 7 $376C (same trap slot $1114, code r=0.95).', 'S7: Patch #23 replaces _StdPoly ($A8C5); card commands: $0D $26 $31 $38']),
 0x5602: ('GA_StdText', ['GA_StdText  -  System 7 $3A9C (same trap slot $1008, code r=0.50).', 'S7: Patch #5 replaces _StdText ($A882); card commands: $0D $21 $26 $38']),
 0x5710: ('GA_StdArc', ['GA_StdArc  -  System 7 $3DDC (same trap slot $10F4, code r=0.97).', 'S7: Patch #4 replaces _StdArc ($A8BD); card commands: $0D $23 $26 $38']),
 0x581a: ('GA_StdRRect', ['GA_StdRRect  -  System 7 $3EFA (same trap slot $10BC, code r=0.96).', 'S7: Patch #22 replaces _StdRRect ($A8AF); card commands: $0D $26 $2E $38']),
 0x592e: ('GA_StdOval', ['GA_StdOval  -  System 7 $4020 (same trap slot $10D8, code r=0.96).', 'S7: Patch #21 replaces _StdOval ($A8B6); card commands: $0D $26 $2F $38']),
 0x5a0e: ('GA_StdRect', ['GA_StdRect  -  System 7 $4116 (same trap slot $1080, code r=0.96).', 'S7: Patch #20 replaces _StdRect ($A8A0); card commands: $0D $24 $26 $38']),
 0x5aee: ('GA_LowMem0804', ['GA_LowMem0804  -  System 7 $420C (same trap slot $804, code r=0.77).', 'S7: Patch #8 replaces special; no EngineDispatch command found']),
 0x5b5c: ('GA_LowMem0800', ['GA_LowMem0800  -  System 7 $42B8 (same trap slot $800, code r=0.87).', 'S7: Patch #7 replaces special; no EngineDispatch command found']),
 0x5bc4: ('GA_LowMem0818', ['GA_LowMem0818  -  System 7 $433E (same trap slot $818, code r=0.94).', 'S7: Patch #70 replaces special; no EngineDispatch command found']),
 0x5c48: ('GA_LowMem081C', ['GA_LowMem081C  -  System 7 $43CA (same trap slot $81C, code r=0.92).', 'S7: Patch #71 replaces special; no EngineDispatch command found']),
 0x5cb0: ('GA_LowMem0890', ['GA_LowMem0890  -  System 7 $4444 (same trap slot $890, code r=0.91).', 'S7: Patch #72 replaces special; no EngineDispatch command found']),
 0x5d20: ('GA_LowMem0808', ['GA_LowMem0808  -  System 7 $44C4 (same trap slot $808, code r=0.68).', 'S7: Patch #9 replaces special; no EngineDispatch command found']),
 0x5e66: ('GA_LowMem0814', ['GA_LowMem0814  -  System 7 $45D4 (same trap slot $814, code r=0.88).', 'S7: Patch #69 replaces special; no EngineDispatch command found']),
 0x5ece: ('GA_InitGraf', ['GA_InitGraf  -  System 7 $4658 (same trap slot $FB8, code r=0.79).', 'S7: Patch #93 replaces _InitGraf ($A86E); card commands: $26']),
 0x5ef6: ('GA_InitPort', ['GA_InitPort  -  System 7 $4682 (same trap slot $FB4, code r=0.79).', 'S7: Patch #94 replaces _InitPort ($A86D); card commands: $26']),
 0x5f1e: ('GA_OpenPort', ['GA_OpenPort  -  System 7 $46AC (same trap slot $FBC, code r=0.79).', 'S7: Patch #95 replaces _OpenPort ($A86F); card commands: $26']),
 0x5f46: ('GA_InitCPort', ['GA_InitCPort  -  System 7 $46D6 (same trap slot $1604, code r=0.79).', 'S7: Patch #96 replaces _InitCPort ($AA01); card commands: $26']),
 0x5f6e: ('GA_OpenCPort', ['GA_OpenCPort  -  System 7 $4700 (same trap slot $1600, code r=0.79).', 'S7: Patch #97 replaces _OpenCPort ($AA00); card commands: $26']),
 0x5f96: ('GA_DrawPicture', ['GA_DrawPicture  -  System 7 $472A (same trap slot $11D8, code r=0.81).', 'S7: Patch #75 replaces _DrawPicture ($A8F6); card commands: $26']),
 0x5fd0: ('GA_SeedCFill', ['GA_SeedCFill  -  System 7 $4762 (same trap slot $1740, code r=0.85).', 'S7: Patch #82 replaces _SeedCFill ($AA50); no EngineDispatch command found']),
 0x602c: ('GA_CalcCMask', ['GA_CalcCMask  -  System 7 $47BC (same trap slot $173C, code r=0.87).', 'S7: Patch #83 replaces _CalcCMask ($AA4F); no EngineDispatch command found']),
 0x6094: ('s7_sub_4822', ['s7_sub_4822  -  System 7 $4822 (identical code).', 'S7: sub_4822(reason) = EngineDispatch($26, NULL, reason): flush / end the']),
 0x60ac: ('GA_CopyBits', ['GA_CopyBits  -  System 7 $483C (same trap slot $11B0, code r=0.93).', 'S7: Patch #2 replaces _CopyBits ($A8EC); card commands: $0D $38']),
 0x61b0: ('s7_sub_494e', ['s7_sub_494e  -  System 7 $494E (similar code, r=0.99).']),
 0x6224: ('EngineDispatch', ['EngineDispatch  -  System 7 $49C4 (similar code, r=0.84).', 'S7: EngineDispatch  -  the generic accelerator-command dispatcher (called']),
 0x7850: ('CopyParamsToQueue', ['CopyParamsToQueue  -  System 7 $5FF2 (similar code, r=0.74).', "S7: CopyParamsToQueue  -  a Duff's-device unrolled copy: a switch on the"]),
 0x7b22: ('s7_sub_624a', ['s7_sub_624a  -  System 7 $624A (similar code, r=0.83).']),
 0x7c56: ('s7_sub_63b0', ['s7_sub_63b0  -  System 7 $63B0 (similar code, r=0.92).']),
 0x7ce4: ('s7_sub_6442', ['s7_sub_6442  -  System 7 $6442 (by call graph, r=0.70).']),
 0x8580: ('GA_ControlFFFFFFFD', ['GA_ControlFFFFFFFD  -  System 7 $6C70 (same trap slot $FFFFFFFD, code r=0.74).', 'S7: Patch #105 replaces special; no EngineDispatch command in its own body:']),
 0x85aa: ('GA_ControlFFFFFFFF', ['GA_ControlFFFFFFFF  -  System 7 $6C8A (same trap slot $FFFFFFFF, code r=0.97).', 'S7: Patch #103 replaces special; card commands: $00 $02 $12 $13 $14 $16 $17 $29']),
 0x8638: ('GA_ControlFFFFFFFE', ['GA_ControlFFFFFFFE  -  System 7 $6D1E (same trap slot $FFFFFFFE, code r=0.91).', 'S7: Patch #104 replaces special; card commands: $00 $11 $26']),
 0x869c: ('StoreCtxWord_AA6', ['StoreCtxWord_AA6  -  System 7 $6D92 (similar code, r=0.88).', 'S7: StoreCtxWord_AA6  -  the single most-called helper (~159x).  Fetches the']),
 0x8710: ('s7_sub_6e14', ['s7_sub_6e14  -  System 7 $6E14 (similar code, r=0.83).']),
 0x8822: ('s7_sub_6f1c', ['s7_sub_6f1c  -  System 7 $6F1C (similar code, r=0.85).']),
 0x884a: ('s7_sub_6f4e', ['s7_sub_6f4e  -  System 7 $6F4E (similar code, r=0.87).']),
 0x8c26: ('s7_sub_73c4', ['s7_sub_73c4  -  System 7 $73C4 (similar code, r=0.99).']),
 0x8d20: ('s7_sub_74be', ['s7_sub_74be  -  System 7 $74BE (checked by hand, r=0.53).']),
 0x8d60: ('s7_sub_74f6', ['s7_sub_74f6  -  System 7 $74F6 (similar code, r=0.95).']),
 0x8d96: ('s7_sub_7534', ['s7_sub_7534  -  System 7 $7534 (by call graph, r=0.65).']),
 0x8dcc: ('s7_sub_7570', ['s7_sub_7570  -  System 7 $7570 (similar code, r=0.94).']),
 0x8e54: ('s7_sub_75fe', ['s7_sub_75fe  -  System 7 $75FE (by call graph, r=0.66).']),
 0x8f6e: ('s7_sub_7742', ['s7_sub_7742  -  System 7 $7742 (similar code, r=0.90).']),
 0x8fa0: ('s7_sub_81d8', ['s7_sub_81d8  -  System 7 $81D8 (checked by hand, r=0.56).']),
 0x8fd8: ('s7_sub_77a6', ['s7_sub_77a6  -  System 7 $77A6 (checked by hand, r=0.51).']),
 0xa40c: ('s7_sub_c264', ['s7_sub_c264  -  System 7 $C264 (identical code).']),
 0xa472: ('s7_sub_bfde', ['s7_sub_bfde  -  System 7 $BFDE (similar code, r=0.80).']),
 0xa4ce: ('s7_sub_b14e', ['s7_sub_b14e  -  System 7 $B14E (checked by hand, r=0.29).']),
 0xa532: ('HWPrivProbe', ['HWPrivProbe  -  System 7 $C01A (identical code).', 'S7: HWPrivProbe(enable)  -  _HWPriv selector 2 = SwapDataCache: turns the']),
}

for _a, (_n, _l) in S7_FUNCS.items():
    NAMES.setdefault(_a, _n)
    if _a not in NOTES:
        NOTES[_a] = _l
