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
*  NOT ANNOTATED beyond the command-path points below (EngineDispatch, the
*  packet post, the argument copy, the go/wait loop, the reply, and the
*  packet-pointer read-back), each naming its System 7 (gc24.s) counterpart.
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
          "sub_884a if unit+$1C says it is not ready."],
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
          "(test at $79FE).  Status bit 3/4 with sub_884a succeeding: return 0;",
          "bit 2: acknowledge and call sub_7ce4; past the deadline with no change",
          "in packet+$1C4: sub_8e54(unit, 2, 0) and the timeout exit $7A96."],
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

NAMES = {0x6224: 'EngineDispatch', 0x7850: 'CopyParamsToQueue', 0x884a: 'sub_884a', 0xa532: 'HWPrivProbe'}
