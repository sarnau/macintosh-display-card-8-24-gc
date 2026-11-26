# Host <-> card protocol (68k driver <-> Am29000 runtime)

Both sides are now readable, so the protocol can be written down from the code
instead of inferred from one end. Everything below is cross-checked against
`DRVR.s` (host), `../extracted-source/VideoDriver.s` (declaration ROM), and the
decrypted firmware `firmware/disasm/Boot.asm` / `Hand.asm` / `RuntimeData.asm`
(card). Addresses are
card addresses; the host reaches `0x4Cxxxxxx` at slot base `+ 0x0Cxxxxxx` and the
card registers `0x44xxxxxx` at `+ 0x04xxxxxx`. "Verified" means both sides were
read and agree; "reading" means one side was read and the other inferred.

## Reader's guide

**The card in one paragraph.** The 8·24 GC is a NuBus video card with an
Am29000. Its driver uploads a small kernel (`Runtime`) and then the
accelerator, **Antelope** (ACEF_100). The host's QuickDraw patches (`gc24`)
send the card work in three ways:
1. **Commands**, for whole bit transfers (CopyBits/StretchBits) and for
   keeping the card's caches of host objects (GDevices, colour tables,
   pixel patterns, offscreens) up to date.
2. **A drawing stream.** The QuickDraw bottlenecks (lines, rectangles,
   ovals, round rects, arcs, polygons, regions and text) are not sent one
   by one. They are written as records into a buffer in card memory, which
   the card plays back (DrawMultiObject). The host measures text and
   uploads fonts. The card clips, maps colours (its own ColorMap), applies
   the text style and draws.
3. **Requests back to the host**, for Memory Manager calls, resources,
   colour searches and host memory.

Card and host share the cursor through a lock. The card removes the cursor
before drawing over it and asks the host to redraw it afterwards. Only the
GC in the lowest slot is brought up (section 1); the others stay plain
video cards.

**Where to read what:**

| topic | section |
|---|---|
| the three channels, what is accelerated, named functions, open questions | "Overview" (next) |
| power-up, loading the firmware, the boot mailbox and video commands | sections 1-5 |
| the frame-buffer layout (linear or interleaved) and who sets it | section 5 |
| the command dispatcher, its case blocks and the packet layout | "Antelope: the command dispatcher" and its `####` sub-sections, including "The dispatcher prologue and packet layout" and "The case blocks" |
| the module API, the card's requests, `CallBack`, `MapVirtual` | "Host: the module/task API", "Host: the card's requests", "Card: `CallBack`…", "Card: `MapVirtual`…" |
| CopyBits/StretchBits | "StretchBits (command `$15`)" |
| the cursor | "The cursor: a lock shared by host and card" |
| the drawing stream, text and fonts, the host-object cache | "DrawMultiObject: the batched drawing stream" |
| the encryption of the firmware (solved) | section 6, "Antelope: the encryption (solved)" and "`.lit` and `.data`, exact" |
| the kernel's services | section 7 |
| the `PupS` resource, Control calls 17-19, the feature flags | section 8 |
| the System 6 package and its Antelope | section 9 |
| the card's I/O registers, the RAMDAC, the DP8531 clock, the video modes, where everything sits in memory | section 10 (10.5 RAMDAC, 10.8 video modes, 10.9 memory map) |
| bugs and slips found in the shipping software | the top-level `README.md` |

**How sure is it?** The 68K side (`DRVR.s`, `gc24.s`) is plain code.
The card firmware is encrypted with a running 32-bit XOR key per section,
which DRVR's `ACEFLoad` removes while loading. The same decryption gives
exact listings of every section of both builds (`firmware/disasm/`,
`firmware/sw11/disasm/`). Earlier versions of this document worked from
partial decodes of Antelope; the card-side claims are now checked against
the exact listings. What the code *means* is still a reading unless the
text says it is checked against the host or against QuickDraw's sources
(`System 7.1 Source Code`).

## Overview: what the card does, and how the host talks to it

This summarises the sections below and gives the current state. Where an
older paragraph further down disagrees, this overview and the
DrawMultiObject section are the reference.

**Three channels**, all in one shared block in card memory (the "packet",
`[.bss]` on the card, `$C(device record)` on the host). `InitPacket`
(`$3299C`) takes its address from `PublicOu+$18` (`$4C008C00`, Boot fills in
the top nibble), reached through service `$C0` (which returns `PublicIn`,
`$4C006400`) plus `$418`:

| channel | direction | where | host side | card side |
|---|---|---|---|---|
| commands | host → card | `+$14` go, `+$18` completion, `+$1C` reply, `+$44` = `rec`: `+$48` selector, `+$4C` sequence, `+$50` count, `+$54` pointer to the argument longs (InitPacket sets it to `packet+$650`, `$32A0C`-`$32A18`; the host reads it back after command 1, `gc24.s` `$726E`-`$728E`, and copies every command's arguments there, `$5F26`/`$5F80`-`$6048`). `$15` (StretchBits) and the PQDInit command use fixed blocks at `+$58` and `+$604` instead | `EngineDispatch` (`gc24.s` `$49C4`) | dispatcher `sub_31e20`, main loop at `$31E0C` in `main` `$31DAC` |
| requests | card → host | `+$24` mailbox: `+$04` code, `+$08` reply, `+$0C` sequence, `+$14` args | `sub_6442`, called from the idle routine and from `EngineDispatch`'s wait loops | `CallBack` `$33EBC` |
| modules | host → card code | commands `$8001`-`$8004` and request 999 | `sub_1404` (gc24 entry #105) | `sub_37B58`, `sub_379A0` |

Bit 2 of packet `+$18` tells the host that a request is waiting. Packet
`+$1C0`/`+$1C4` are a host counter and the card's heartbeat (the nested wait
loop). Separate from all of this are the boot mailbox (section 4) and the
video command block (section 5).

**Commands and replies.** The host sends a selector (`$0C`-`$3C` for drawing
and caches, `$80xx` for modules). A reply of 1 means "done"; StretchBits may
post it early, once every pixmap it touches is on the card ("Early
release"), and the next command then waits for the completion. 0 means "not
handled", and the host runs the original 68k QuickDraw routine. EngineDispatch
itself returns 2 ("run the original without drawing") while a picture,
region or polygon is being recorded; the card never sends 2. Command `$01` resets the
sequence numbers on both sides; a mismatch is logged by the dispatcher
(`$31EA0`, except for command `$01`) as `MonetMain: Sequence error %d != %d,
func = %d, last func = %d`.

**What the card accelerates (this firmware, ACEF_100 "32-Bit Antelope"):**

| command | host routine | card |
|---|---|---|
| `$15` | `StretchBits` (trap `$AB27`; CopyBits ends here) | `$2D7B8` StretchBits, with `scaleBlt`, BitBlt and RgnBlt. Reaches host pixel maps through `MapVirtual` |
| `$33`, `$19`, `$1A`, `$0C`, `$2C`, `$29`/`$2B` | offscreens, colour tables, pixel patterns, GDevices changing | DisposeOffscreen, FlushOffscreen, FlushColorTable, CachePixPat, FlushPixPat, FlushGDevice: the card's caches of host objects |
| `$17` | set-up | PQDInit (`$320C8`) |
| `$26`, `$38`, `$0D`, … | begin / synchronise around drawing | state and bookkeeping |
| `$20`-`$24`, `$2E`, `$2F`, `$31`, `$18` and the pen/colour/region state changes, carried by `$2D`/`$38`/`$26` | `StdLine`, `StdText`, `StdArc`, `StdRect`, `StdRRect`, `StdOval`, `StdPoly`, `StdRgn`: `EngineDispatch` does not send these one by one but appends a record to a stream in card memory | `$13770` → `DrawMultiObject`, which plays the stream back (see "DrawMultiObject: the batched drawing stream") |
| `$8000`-`$8004` | module API: run, allocate, free, echo | `sub_37B58` |

**The Std\* drawing calls are batched, not sent.** If they reached the
card's dispatcher they would go to "Unknown Function". Instead
`EngineDispatch` turns them into stream records (an earlier version of this
document wrongly concluded that they were not accelerated). When the stream
cannot be used, for example with no current port or a TrueType font,
`EngineDispatch` returns 0 and the 68K draws.

**What the card asks the host for (request codes):** Memory Manager calls
(3-6), resources (7), block copies to and from handles (8, 18, 21),
`MakeITable` (12), the GDevice's search and complement procs (13, 14),
`Entry2Index` (17), locking host memory and its physical pages (15, 16),
`OpColor`/`HiliteColor` (20), `GetSystemClientProcess` (22), reset (100),
and module requests (999).

**Host-loaded modules.** Through gc24 entry #105 a program can load ACEF
code onto the card (`$8002` + `ACEFLoad`) and run it as tasks (`$8001` runs
the entry point on a message). Its code gets a service callback, and through
it Antelope's exported entry table: the QuickDraw core (StretchBits,
scaleBlt, BitBlt, RgnBlt, the shape drawers, text, DrawMultiObject) plus
`CallBack`, `MapVirtual` and the dispatcher.

**Named card functions** (the evidence is in the sections below): `main`
`$31DAC` (prints `PQDMonet: Starting up, commblock at %X`), `InitPacket`
`$3299C` and the dispatcher `$31E20`; DrawMultiObject `$0AD18`; StretchBits `$2D7B8`;
scaleBlt `$22A8C`; GetSeek `$253D4`; BitBlt `$01A50` and RgnBlt `$19DA4`; DrawText `$11AD8`; DrawArc `$075DC`, DrawLine `$08618`, QuickPolys
`$19270` (from DrawMultiObject's polygon opcode); RSect `$01494` and TrimRect `$01654`
(from its region opcode); ITabMatch `$06650`; ColorMap `$06F1C`; the long fills `$1701C` (block write), `$17264` (two values) and `$00348` (`storem` bursts), with the burst helpers `$00294` (two values) and `$00248` (copy); the slot burst self-test `$37000` (part of `SelfTest` `$3404C`); the own-address test `IsOnThisCard` `$13F54` (compares an address's top nibble with service `$C4`'s); the host-object cache: find `$15D28`, find-and-stamp `$15E8C`, create `$15EE4`, find-or-create `$15FF4`; font upload `$14B64` (width table) and `$14A80` (strike); BitsToPixMap
`$06BEC`; DisposeOffscreen `$14034`; FlushOffscreen `$14168`;
FlushColorTable `$141F8`; CacheGDevice `$14F64`; CachePixPat `$151C4`;
FlushGDevice `$15808`; FlushPixPat `$158F4`; PQDInit `$161F8`; PQDAlloc
`$16A04` (named by their own messages, `PQDInit: Unable to allocate mega
buffer`, `PQDAlloc: …`; earlier read as "PRInit"/"PRAlloc"); CopyHostMemory
`$16C48`; `MapVirtual` `$3373C` and its release `UnmapAll` `$33A9C`; ShieldCursor
`$32C10` and its after-drawing counterpart `$32EF8`; `CallBack`
`$33EBC`; the request wrappers `$33BD0`-`$33E88`; the card heap
`$372D0`-`$3772C`; the `storem` fill `$37D68` and its family
`$37C10`-`$38C3C`; the reporter `$00140` and its log writer `$00F84`; the kernel service
stubs `$38F24`-`$39110` (section 6); the C library from `$39114` to the end
of `.text` (`$3CAD4`; see "The C library"). All 709 functions are named in
`antelope_names.py`, and `antelope_dasm.py` prints the names, with banners
per subsystem, in `firmware/disasm/text.asm`.

**Answered by the exact listings** (formerly open): the encryption (a
running XOR key per section, see section 6); service `$C0` (returns
`PublicIn`, `$4C006400`; `InitPacket` adds `$418` to reach the packet
pointer); the pattern fills `$04110` and `$1C8A8` (called directly from
BitBlt `$02B3C` and RgnBlt `$1B090`); and the kernel services, whose table
(section 7) is exact. The ones that were unknown, read in `Hand.asm`:
`$BB` returns the flags word `gr64` (`$2001A58`); `$D1` returns
`PublicOu+$04`, the version `$00700D01` with bits 24-26 filled in by kernel
init from the board code at `$44000094/98/9C` (bit 31 each) and bits 28-31
from `$46000000` bits 12-15 (`$2001A48`, `$2002170`-`$20021F0`);
`$D4` translates an address through the memory-region table and clips a
length to the region (`$2001808` → `$2001C2C`; address in `gr96`, length in
`gr122`);
`$D2` restarts the kernel (jumps to init `$2001FFC`) when flags bit 28 is
set and otherwise returns 0 (`$2001294`); `$B8` turns the timer interrupt on
(reload `$7530`) or off and returns its previous state (`$20018E4`); `$B9`
and `$BF` set or clear the `OPS` bits SM (supervisor mode) and DI
(interrupts disabled) and return the previous state (`$20018B8`,
`$2001924`).

**Still open:**
- how the Am29000 gets from reset (address 0, ROM space) to `Boot` at `$2003000`: no code does it, so the hardware must (section 1);
- the meaning of the 137-bit stream at `$44800000`: most likely a configuration chain inside the MFB (10.3), 25 four-bit `1xxx` cells, two similar words and a 4-bit Two-Page field; board revision 1 adds 1 to four small fields, which suggests VRAM timing counts. No field is decoded;
- who rewrites glyphs `$84`-`$9E` in a non-Roman (`WidthAFID` ≥ `$4000`) strike that the card re-reads (`$147BC`); the best fit is KanjiTalk 6 using these 27 unused Shift-JIS lead-byte slots as scratch cells for 2-byte bitmap glyphs, not confirmed (DrawMultiObject, "Open points");
- the kernel's debug switches (flag bits 1, 3, 10, 30, 31; section 8) are traced, but who would write their watch window `$4C0067D8`/`$67DC` and escape address in gr121 is not known;
- bit 31 of the RAMDAC's pixel bus control byte, always set (10.8), and whether the host's slot offsets 0 (the RAM test) and `$02000000` (the kernel) are the same SRAM (section 1).

**Settled, for orientation:** the System 6 Antelope is exact too (section
10): 620 of its 769 functions are identical to System 7's; it has
placeholders for the 16-bit arithmetic modes and an Apple Video (`'rpza'`)
codec behind commands `$39`-`$3B`, with a QuickTime codec component on the
host (`gc24_sw11.s` `$9510`). The pixel clock is a DP8531 (10.8); the RAMDAC
is a Brooktree "RAMDAC 428" on data bits 31-24 (10.5); `$44000028` is the
Am29000's run control (10.1).

## 1. Bring-up (`Init29K` -> `Boot` -> kernel init)

| step | host (`DRVR.s`) | card |
|---|---|---|
| 1 | `ACEFLoad` uploads `Runtime` (sections incl. `PublicIn`, `PublicOu`, `Vec`) | held: `$44000028` is 0 (section 10) |
| 2 | waits until `PublicOu[0]` (image+$400) reads `$32100456` -- a constant of the *uploaded file* (it is the static first word of `PublicOu`), so it only proves the upload landed | - |
| 3 | pokes `image+$18` <- unit flags (+$168), `image+$00` <- `$42005300`, `image+$08` <- card address of the last byte of card RAM (+$138: `$0C1FFFFF`, the top of VRAM, without SIMMs; else the top of DRAM), `image+$14` <- card address of `(+$134 - $6D1) & ~$FF` (+$134 here is the Runtime's reservation from the same ACEFLoad; Antelope reads it as heapMax) | `Boot` polls `$4C006400` (PublicIn+0) until it reads `$42005300`, then clears it (**verified**) |
| 4 | reads `image+$40C` (= `PublicOu+$0C`, the file's static `$4C007000`, HifComm; it does not wait for Boot, which later puts the slot in the top nibble, and `PokeHardwareLong` makes a slot address of it anyway) = mailbox address; writes `mailbox+$0C` <- ack-word address (+$140) and `mailbox+$00` <- `$73333337` ('s337'), all only when feature flag `$800` is clear, which it is not by default (section 4) | Boot (`$2003050`) and kernel init (`$2002004`-`$200200C`) read the host flags from `PublicIn+$18` into `gr64` (**verified**) |
| 5 | cs3 uploads and links Antelope and fills `PublicIn+$04`/`$20`-`$2C`/`$40`; cs5 writes the flags to `image+$18` and then -1 to `$44000028` (`$1DDC`) | the Am29000 starts at `Boot`, whose poll passes at once (`$42005300` is already there) |

**How the Am29000 reaches `Boot` is still open; AMD's manuals narrow it
down.** At reset (Am29000 User's Manual, 1987, 3.8, p. 3-73; 5.5, pp.
5-31/32) CPS is `$0573` (FZ, RE, PD, PI, SM, DI, DA set), CFG's
cache-disable bit is set, and VAB and the other registers are undefined.
When *RESET goes away the CPU fetches address 0 in ROM space (IREQT = 1),
which some device must answer. Halt and Step resume where the CPU stopped;
Load Test Instruction cannot be entered from Reset (pp. 5-25 to 5-28);
absolute jumps reach only below `$40000`. The word at `$2000000` is vector
0, `jmp $2002808` (PC-relative, so fetched at 0 it lands at `$2808`): a
reset that ran it would start the fatal-trap reporter with undefined
`gr64`, then report reason `$91` or enter init `$2001FFC`, which never sets
VAB; Boot does that, and also stamps the slot into PublicOut and copies the
data section. Nothing in Runtime, the driver or the declaration ROM jumps
to `$2003000`. `Boot` is PC-relative and runs 14 instructions with RE = 1
before clearing it in place (`$2003038`, `CPS` = `$047F`) and continuing
without a jump, so ROM space and instruction space must reach the same
SRAM: the card ignores IREQT there. The redirect is therefore most likely
in the gate arrays: a few words they supply for the first fetch after reset
(`const`/`consth`/`jmpi`, or `jmp $3000` with a 64 KB decode).
`$44000028` most likely drives *RESET rather than the CNTL pins, because a
halted CPU would resume its old PC after Init29K uploads a fresh image.
That the host's
slot offsets 0 (the RAM test) and `$02000000` (where the kernel is written)
are the same SRAM is inferred: the test writes only offsets 0-`$1FF00`,
never reads `$02000000`, and would fail if offset 0 aliased every 64 KB.

`PublicIn+$18` is consumed exactly as `DRVR.s` publishes it: bit 11 (`$800`,
"mailbox not enabled") gates the reports to the host from the HIF service
path (`$2001BC0`) and from the fatal-trap reporter (`$2002AAC`; with the bit
set a trap restarts the kernel unreported); bit 20 (`$100000`, set when the
DRAM top is above `$0D000000`) selects the heap-limit computation of service
`$C1` (`$20012AC`, free heap = `[PublicIn+$08] - $1000 - break` instead of
`gr127 - $3000 - break`), which uses `PublicIn+$08` as the end of memory
(**verified**); the other bits are listed in
section 8, "The flags word on the card".

Kernel init (`$20020D0`) also stores the signature `$57593160` ('WY1`') at
`VidComm+$18` (`$4C007318`). `Boot` only reads it (`$2003560`): with the
signature present and `VidComm+$08` non-zero it takes the video parameters
from `VidComm` instead of probing the registers. `VideoDriver.s` reads that
word before talking to the Am29000 and falls back to "just retime the clock" if
it is missing (**verified**, both sides).

**Which card is brought up.** DoOpen (`$1DE`-`$278`) calls BuildUnitRecords
(`$1E4A`) for slots `$9`-`$E` in ascending order; every GC found (board
sRsrc BoardId `$2C`, or a 'Cheetah'/'Tiburon' name, type `$7E`) gets unit
record `+$214[i]`, and `$1D8E` (`$1FF8`) holds its Am29000 (`$44000028` = 0).
The name test (`$1E7C`-`$1F60`) takes the first word of sRsrc 1's name
(sReadDrvrName, cut at the first space, prefix-compared); the stock ROM's
'Macintosh Display Card 8•24 GC' never matches. Every later test treats
`$7E` exactly like `$2C`, except the RevLevel test `$1AAA`, which needs
BoardId = type, so a name-matched card would take the no-display drop and
get 0/0 from Status 19. **Tiburon is Apple's codename for the 8•24 GC**
(System 7.1 `Resources/Sys.r`: STR -16454 "8•24 GC", "name of the Tiburon
patch file", which `Boot3.a` uses to load `gc24` 32; `PatchIIROM.a` and
`PatchIIciROM.a` mention "the patch for the tiburon video card"). Cheetah is
not identified: no Apple source, ROM or codename list on hand names it
(System 7.1's sources, 329 Mac ROMs, Apple's developer and service
material searched; Mac OS X 10.0 'Cheetah' is unrelated). Presumably it
was a prototype or sibling board of the Am29000 GC family. DoOpen's check for type `$7D` (`$218`) is dead: nothing
stores `$7D`.
Every client hard-codes unit 0: InstallPatches (`$1142`), `gc24`
(`$214(a0)`), INIT_main and the control panel's restart routine `sub_A8C` (`$A9E`; the
boot-time bring-up is `gc24` 32's).
So only the lowest-slot GC gets cs2/cs3/cs5, as *develop* 3 says (p. 333);
the others stay held and work as plain video cards, and the control panel
shows STR# 1000 #10 when Status 2 (the count, globals `+$10`) is above 1.
Nothing lets the user choose another card. The driver's "no display" drop
(`+$15E` = `$FFFF` when all three sense lines are high, `$2064`-`$207C`)
depends on a RevLevel test (`$1AAA`/`$1BEC`, written for the prerelease
ROM's '100a16 …' format, 10.10) that 'MDC 8•24 GC 1.0' always
passes, so it never happens (it would also leave a disposed handle in
`$214[i]`). A card without a monitor loses only its video sResources
(PrimaryInit `$26BC`); the driver needs only the board sResource, so that
card can still be the accelerator, drawing to the host's or other cards'
frame buffers with 64-byte `storem` bursts (FillLongsStorem `$37D68`, gated
per device by the slot burst mask `$D5` and the burst test `$37000`).

## 2. `LoadFirmware` (loading Antelope) fields

`ReserveEngineRegion` publishes, in `PublicIn`: `+$20` start of the loaded
region, `+$24` end (start + text + data + bss), `+$28`/`+$2C`/`+$30` text,
data, bss sizes, `+$40` the region start again. The kernel init reads exactly
`+$20/+$24/+$28/+$2C/+$30`: it copies `[+$2C]` bytes from `[+$24]` to
`[+$20] + [+$28]`, the data section's place (`$20020F0`-`$200213C`), and clears
the `[+$30]` bytes after it (`$2002140`-`$2002160`); `ReserveEngineRegion`
leaves room for that second copy of the data (it reserves `2*data`, DRVR
`$2B8E`-`$2B9A`), and `Boot` (`$2003090`-`$20030DC`) copies the same span the
other way. It sets its stack from `+$40` (`gr125 = [PublicIn+$40]`,
`gr127 = gr125 - $10000`, `$2002414`-`$2002428`) (**verified**: the host's
stores and the kernel's loads use the same offsets).

## 3. Starting Antelope, and restart ("PostLoadPoke")

`LoadFirmware` stores Antelope's entry (ACEFLoad's out-parameter) at
`PublicIn+$04`. The kernel init `$2001FFC` ends (`$20025E8-$2002644`) by storing
its heap pointer at `PublicIn+$10`, loading `PC1 <- [PublicIn+$04]`,
`PC0 <- PC1 + 4`, and `iretinv`, i.e. it **jumps to that entry** (unless `gr64`
bit 16 asks to stop with reason `$A1`, `$2002634`) (**verified**: both ends read). Nothing on
the 68k side kicks the program directly; the kick is the restart below, which
`cs13`/`cs48` issue after `cs3`.

### Restart

`PostLoadPoke` writes the flags to `image+$18`, `$FFFFFFFF` to `image+$3D4`
(`$4C0067D4`) and `$FFFFFFFF` to register `$04000050` (card `$44000050`;
`moveq #$ff` sign-extends, DRVR `$2A88`, `$2AA6`). On the card
the `$44000050` register is acknowledged (cleared) at the start of the video
command service `$2000C14`, which then reads `$4C0067D4` and, if set, jumps to
kernel init `$2001FFC`; init clears the word again (`$20020B0`) and reloads
`gr64` from `PublicIn+$18` (**verified**). So this routine is a *restart
request*: new flags + restart flag + doorbell, which is why `cs13`/`cs48` call
it before enabling acceleration. The doorbell is the same register the video
driver writes (`$04000050 <- $FFFFFFFF`) after each command.

## 4. Mailbox (`cs51`)

Host (`cs51`): clear the ack word (+$13C), write the payload to `mailbox+$08`,
then `'s337'` (`$73333337`) to `mailbox+$00`. Card (`$2002650`, the one
reporter, used by the HIF services the kernel does not handle itself and by
fatal traps): the mailbox carries card-to-host reports, and `'s337'` is the
host's "ready"/answer. The card posts only when `mailbox+$00` reads
`'s337'` (bring-up step 4 arms it and each `cs51` re-arms it, but only when
feature flag `$800` is clear, DRVR `$26CC`; SetFeatureFlags starts from `$800`
(`$2ADE`) and clears it only for config bit `$100`, which only cs50 sets, so
by default the mailbox is never armed and `$2002650` returns at once through
`$2002770`, besides `$2001BC0`'s own bit-11 gate): it writes the
reason (`gr77`) to `+$04`, a 16-word register dump to `+$10`, and the posted
marker `$96666669` to `mailbox+$00` and to the host's ack address stored at
`mailbox+$0C`. It then waits, serving video commands meanwhile, until the
host writes `'s337'` again, writes `$80000000 | reason` to `+$04` and returns
the host's word from `+$08`. If `+$00` reads `$96666669` (a report not yet
answered) it waits first; any other value returns at once without posting.
So the host's "ack word" becomes `$96666669` when the card has posted a
report, and `cs51` answers it (**verified**). The payload is the answer: the
HIF path (`$2001BC0`) returns it in `gr96` as the service's result (service
1, exit, parks the CPU instead); after a fatal trap (`$2002AAC`) it is not
used, and the kernel restarts unless flags bit 16 is set.

The reason codes are listed in `Hand.asm`'s header (traps `$8F`-`$A6`,
report overflows `$B4`/`$B5`; for the HIF path the service number).

**No host code acts on a report.** The driver has no interrupt handler or
periodic task. Status cs15 (`$5A0`) is the only reader: it returns the
reason from `mailbox+$04` when the ack word (`unit+$13C`) holds
`$96666669`, and 0 otherwise. Status cs16 (`$5FE`) returns the superslot
address of the register dump at `mailbox+$10`. Both refuse while flag
`$800` is set. No client (the control panel, INIT_main, INIT_DSInit,
`gc24`) calls cs15, cs16, cs50 or cs51, and `gc24` never reads the mailbox
or the ack word. If the mailbox were armed, a posted report would leave
the card waiting at `$2002700` forever, serving only video commands. No program outside the package calls them either: the System 7.1
sources never mention `.GraphAccel`, and *develop* 3 (July 1990) describes
one developer interface only, an MPW library `GraphAccel.o` with a sample
FKey for turning acceleration on and off (cs13/cs14); the same article says
third parties cannot program the Am29000. Status cs15/cs16 and Control
cs50/cs51 were therefore most likely used by an Apple-internal debugging
tool, which has not been found. Other csCodes without a client in the
package: Control 6, 16, 49, 52-54; Status 6, 8, 9, 11, 13, 14, 54.

| call | does |
|---|---|
| Control 6 (`$B64`) | state `&~4`; `$1D8E` writes 0 to `$44000028` (holds the Am29000; undoes cs5) |
| Control 16 (`$880`) | `globals+$250` <- csParam+2 (default `$D3`); if patched, `$1436` then `$14B0` re-route the trap vectors. Only Status 6 reads `+$250` |
| Control 49 (`$A96`) | `$2D44`: writes argc/argv (pointer vector, strings, NULL; at most `$1000` bytes) to `InpArgs` = `[image+$410]`, which the entry stub reads through HIF `$104` (counted, then ignored by `main`) |
| Control 52 (`$872`) | `globals+$AA6` <- word (the current-trap word `gc24`'s `StoreCtxWord_AA6` sets) |
| Control 53 (`$85A`) | unbounded strcpy of csParam+2 into `globals+$AAA`; nothing reads it |
| Control 54 (`$F0A`) / Status 54 (`$6D0`) | System 7: the hook at `$A84` (gc24's ID -3 entry, the module API `sub_1404`) with `(csParam+2, csParam+6, &globals+$AA0)` and a 2000-tick timeout / with `(-1, 0, …)`, the last result; neither checks the slot. System 6 (`$F2A`/`$702`) differs: Control 54 passes four longs (csParam+2, +6, +10, +14) to its hook (the codec entry) and stores D0 in `globals+$AA0`; Status 54 only returns that long |
| Status 6 / 8 / 9 / 11 / 13 / 14 | `globals+$250` / unit `+$002` timeout / `+$000` slot / `+$162` type / `+$168` flags / `+$004` |

Status calls use the unit of the last Control call (`globals+$22E`), not
csParam+0.

## 5. Video command block (`VidComm`, `$4C007300`)

`VideoDriver.s` (mode set) fills: `+$08` frame-buffer base (superslot form),
`+$0C` row bytes, `+$10` depth, `+$14` vertical resolution, `+$1C` page
configuration; writes `+$00 <- $80000000` and rings the doorbell
(`$04000050 <- $FFFFFFFF`); waits (with a timeout) for `+$04` to read 0; and
later writes `+$04 <- $FFFFFFFF` to let the card continue. The card's service
`$2000C14` (run from INTR2 when no handler is registered, and from the
mailbox waits, when the status register `$44000064` is set) reads exactly
those fields (`+$08` -> `gr74`, `+$0C` -> `gr75`, `+$10` -> `gr76`, `+$14` ->
`gr77`, `+$1C` -> `gr68`) and clears `+$00`. If command bit 0 is set it
writes 0 to `+$04` at once and spins until the host writes a non-zero value
back. It computes the frame-buffer size with a 32-step multiply (row bytes ×
(rows + 4)), then acts on the page configuration (`+$1C`): 1 runs the bulk
word copy at $2000E8C.., 2 the one at $2000DBC..; after a copy it waits for
`$4400007C`/`$44000080` and writes 0 to `+$04` without waiting for the host
(`$2000FEC`). With any other value and bit 0 clear (the host's
`$80000000`), it writes 0 to `+$04` and spins until the host writes a
non-zero value -- i.e. the card pauses while the host retimes the clock
(**verified**). Finally it copies `+$08`/`+$0C`/`+$10`/`+$14` to
`PublicOu+$1C`/`+$24`/`+$20`/`+$28` (`$2001024`).
The copies convert the 2 MB window between a 4-way word-interleaved and a
linear layout (1: interleaved to linear, 2: the reverse; see `$1701C` under
"the rectangle case").

**Who sends which configuration** (`JMFBSetDepth`, `$5DA8`). `savePageCfg`
(`$2C(a3)`) is cleared on every depth change, and set only when GFlags
bit 11 is set and the depth really changes:
* to 1 when the new depth is 24 bpp (the driver's code for 32-bit pixels;
  it also sets GFlags bit 9);
* to 2 when the old depth was 24 bpp (and clears bit 9).

Bit 11 is `Interlaced` in Apple's JMFB equates, and it means that here too.
`VideoOpen` maps the sense lines to an ID (`$5326`-`$538E`):
* raw codes 0-6 stay as they are, except raw 0, which becomes 7;
* raw 7 (extended sense) becomes 4 for extended code `$14`, 0 for `$00`,
  and 9 otherwise.

IDs 1, 2, 3 and 6 get their own timing tables: 870, 384, 870 and 480 lines
(Apple's portrait, 12" RGB, two-page and 13" RGB monitors). Every other ID
sets bit 11 (`$53CC`) and takes a TV path that knows only two cases: ID 4
gives 480 lines (NTSC), anything else gives 576 lines with underscan
(PAL). The sResource ID's bit 3 picks a second pair of tables (convolved
or overscan variants). So the layout conversion happens only on NTSC and
PAL output: there the frame buffer is interleaved at 1-8 bpp and linear at
24 bpp. On the Apple monitors no conversion is ever requested.

**The layout bit is the host's.** The mode-programming routine (`sub_5FD4`, `$601A`, after
`WaitForVBlank`) writes bit 31 of MFB register `+$80` (`$04000080` from the
host, `$44000080` on the card) with `bfins`. The value is 1, except when
GFlags has `Interlaced` set and `BigScreen` clear, in which case it is 0.
`BigScreen` is set exactly when a TV mode enters 24 bpp. So:

| output | 1-8 bpp | 24 bpp |
|---|---|---|
| Apple monitors (IDs 1, 2, 3, 6) | linear (bit 1) | linear (bit 1) |
| NTSC / PAL | 4-way interleaved (bit 0) | linear (bit 1) |

The same routine writes `+$7C` with `bfins d1,{0:1}` (`$607C`-`$6084`),
which stores **bit 0** of the timing entry's second long into bit 31. In
the declaration ROM (`341-0812.bin`), that long is 1 in every NTSC/PAL
entry at 1-8 bpp (tables `$3EB0`, `$447C`, `$4A48`, `$5014`, at the entry
offset by depth plus `(mode − $80) × $40`). It is 0 in their 24 bpp entries
and in every entry of the Apple-monitor tables (`$35D2`, `$3728`, `$387E`,
`$3A24`). So although `+$7C` comes from the table and `+$80` from GFlags,
`+$7C` is the complement of `+$80` in every mode: 1 = interleaved, 0 =
linear. The two page conversions
wait for them in opposite states. The card waits for them *before* it
acknowledges (`$2000E5C`-`$2000E78` and `$2000F2C`-`$2000F48`, then `+$04 <- 0`),
while the host programs them only after its wait for that acknowledge
(which has a timeout) and, when `savePageCfg` is non-zero, an extra delay
(`$5F78`). No card code writes `+$7C` or `+$80`: the only writers are
PrimaryInit (`$252C`, `$253A`, `$27B6`, `$27C2`) and the VideoDriver's
`sub_5FD4` (`$6076`, `$6084`). So, as far as the code shows, the card's waits
(`$2000E5C`, `$2000F2C`) end only through the host's write, and the host's
wait for `+$04` runs into its timeout first.

## What this corrects

* `DRVR.s` `PostLoadPoke` is a restart request, not a generic "post-load
  poke"; the earlier "doorbell/enable register" guess for `$04000050` is
  right and the doorbell is the video driver's too.
* `Init29K`'s wait on `$32100456` does not wait for the card to boot; it
  checks the *uploaded* data. The real "card is up" handshake is the other
  direction (`Boot` waits for `$42005300`).
* The earlier statement that the Am29000-side mailbox code was not in the files
  was wrong: it is `$2002650` in `Hand`.

## 6. What Antelope uses from the kernel

Antelope's sections are encrypted like the Runtime's: DRVR's `ACEFLoad`
decrypts each with a running 32-bit XOR key (see "Antelope: the encryption
(solved)"). `firmware/disasm/text.asm` is the exact listing of `.text`
(243 KB, 62,134 words): 768 labels, 709 functions (all named, from
`antelope_names.py`) and 59 object-file starts.

What the loader's relocation table showed already, and the exact code
confirms:

* **Register stack.** The loader patches the vector byte of 293 `asgeu` words
  with `64` (the spill check `asgeu 64,gr1,gr126`) and of 454 `asleu` words with
  `65` (`asleu 65,lr1,gr127`), which match the kernel's spill/fill handlers
  `$2001184`/`$20011B8` (vectors 64/65) (**verified**).
* **Externals.** 21 undefined symbols, all common (bss) variables of 4-424 bytes
  (one 152-byte block referenced 536 times); names stripped.

What the exact code adds:

* **Kernel services.** Antelope calls them through 24 stubs in object file 30
  (`$38F24`-`$39110`, `const gr121,N` + `asneq 66`, labelled `svc_N`) for 23
  services: `$B8`, `$B9`, `$BB`, `$BF`, `$C0`, `$C1`, `$C4`-`$C8` and
  `$CB`-`$D6` (`$D4` has two stubs; `$C8` and `$CE` store results through
  pointer arguments). The table entries it does not call are exactly the ones
  that only return -42 (`$B6`, `$B7`, `$BA`, `$BC`-`$BE`, `$C2`, `$C3`, `$C9`,
  `$CA`). HIF services (`asneq 69`) are `$101` (sysalloc), `$111` (clock) and
  `$112` (cycles) in the same file, and the C library's eight stubs `open`,
  `close`, `read`, `write`, `lseek`, `remove`, `tmpnam`, `_exit` (`$11`-`$16`,
  `$21`, `$1`), which match AMD's HIF sources. The kernel handles none of the
  file services itself; they end in the report to the host (section 4).
* **Entry stub** (`Code`, 38 words at `$0F000`): saves `gr96`/`gr97`, calls
  HIF `$104` (the `InpArgs` pointer) and counts its words up to a zero
  (argc/argv), calls an optional hook if its pointer is non-zero, then `main`
  `$31DAC`, then `exit` `$3AC88` with `main`'s result, and loops on HIF
  service 1 (exit). The argc/argv it builds are never used: `main` takes no
  parameters (tag word `$00020000` at `$31DA8`; `lr1 = gr1+$20` after `sub
  gr1,$18`, where a two-argument function has `+$28`) and reads only
  `lr2`-`lr5`. HIF `$104` (`Hand` `$2001B40`) returns the constant
  `$4C007800`, and nothing else on the card asks for it; host-loaded modules
  are entered as `entry(buffer, task, sub_379A0)` (`$37B9C`). So the strings
  Control 49 writes into `InpArgs` are counted once at start-up and then
  ignored.
* **Hardware.** Antelope also addresses card registers directly: `$4400007C`
  and `$44000080` in the long fills (`$17040`, `$172A4`), and the CLUT
  (`$46C00000`) and registers `$44000054`-`$440000C8` in the self-test.

### Antelope: the encryption (solved)

All section data of a `$012B` ACEF is encrypted with a running 32-bit key,
and the host removes it while loading. The loop is in `DRVR.s`'s
`ACEFLoad` (`$3A46`-`$3A64` sets it up, `$3AD0`-`$3AE6` and `$40FE`-`$4126`
run it; `gc24`'s own copy of the loader accepts only plain `$012A` files):

```
at a section's start:  K = KEY * $01010101    (KEY = header byte +7, the low byte of timdat)
                       b = s_scnptr & $FF      (the low byte of the section's file offset)
per word:              plain = word ^ K;  K = K + b (mod 2^32);  b = b ^ (K & $FF)
```

Only `size/4` words are copied, so a section's last 1-3 bytes never reach
the card. `acef_unpack.py` implements this. Earlier versions of it XORed
every byte with `KEY` alone, i.e. with the starting `K`, and what that left
was the "second mask" that this document and `SECOND_MASK.md` modelled for a
long time: per-section tables for the Runtime, a "T-function" with
step-function high bits for Antelope, and separate keys fitted for `.lit`,
`.data` and System 6. Those models, and the tools and partial listings built
on them, are superseded; they are in the repository's history before
November 2026.

Checks of the exact decode:
* `Hand` comes out identical to the earlier exact unmask (2,885 words);
  `Boot`'s fitted tables were right in 362 of its 512 words;
* in Antelope's `.text` all 555 direct calls land on a function start and
  all 7,524 direct jumps inside the section, and all 662 relocated `.lit`
  words (the switch and command tables) are 4-aligned `.text` addresses;
* all strings read as plain text, and the eight HIF stubs equal AMD's
  library source word for word (`antelope_hif_stubs.py`);
* the spill/fill asserts carry trap number 0 in the file; their byte
  relocations (absolute symbols 64 and 65, `V_SPILL`/`V_FILL`) fill it in.

### Antelope: exact disassembly

`antelope_dasm.py` writes `firmware/disasm/text.asm`, `Code.asm`,
`lit.asm` and `data.asm` (System 6: `firmware/sw11/disasm/`), and
`runtime_dasm.py` the Runtime's `Boot.asm` and `RuntimeData.asm`:

* labels are the 768 `.text` entries of the ACEF symbol table: 709
  functions and 59 object-file starts on a tag word (`firmware/README.md`,
  "How the firmware was built"), so `sub_01a4c` is BitBlt's file start
  and the function is `sub_01a50`; names come from `antelope_names.py`;
* every relocated word shows its target (symbol + the addend in the word;
  for `consth` the low half of the addend is the symbol index of the
  following type-28 record);
* calls to the kernel and HIF stubs show the service (`svc_CC` …).

**Names from the QuickDraw source.** All 709 functions carry names
(`antelope_names.py`). Most of the new ones come from the mode tables, which
follow the 68k source's table order case by case: BitBlt's loops (`.lit
$0008`-`$0068`: `bArith32Tab`, the indexed arithmetic loops, `bMAIN8`-`11`,
the `XMAIN` modes, `bMAIN0`-`3`), RgnBlt's (`.lit $07F8`-`$0878`: the indexed,
32-bit and 16-bit arithmetic loops, `rMASK0`-`3`, `rMASK8`-`11`), QDUtil.a's
SlabMode `$1114C` and FastSlabMode `$11A34`, StretchBits' `stColorTab` +
`stGrayTab` + `stSearchTab` (`.lit $0AE8`, 24 entries, the defaults where QD has
Bogus) and its arithmetic tables by `dstShift` (`.lit $0B78`), GetSeek's
`gsSeekTbl`/`gsRunTbl`/`gsExpTbl` (`.lit $0A54`/`$0A3C`/`$0A28`) and file 21 =
`SeekRgn.a` (INITRGN `$272F4`, SEEKRGN `$259A8`, SEEKUP/SEEKDOWN, INVPAIR).
DrawArc calls SlopeFromAngle `$081E0` and FixMul `$00CC4` as `DrawArc.a` does;
QuickPolys sorts its edges with SortVectors `$19134`. The card adds a 50%
blend loop for indexed depths (`$0604C`, `$21BE0`) that 68k QuickDraw does not
have. Later passes named the rest from the same kind of evidence:
* **scaleBlt**: the scaleNum switch (`.lit $0958`): 1 sc32to8, 3
  sc32to8Dither, 4 scCopy16to32, 9/11 sc32to8gray, 25-29 the 1→2/4/8/16/32
  expansions, 30 scIndexToAny (`.lit $09E0` by dstShift; 1/2 report
  "unsupported dstShift"); a non-zero `lr33` selects an "Or" variant;
* **StretchBits**: `$276D4` is `Stretch.a`'s SetupStretch (the same ratio
  constants); `.lit $0B48`/`$0B60` are EXTBL's Color and plain halves
  (ONE … THRTWO), `$0C18` VMergeTable (ONEDEEP, NDEEP, Average16and32),
  `$0C00` CombineTable;
* **DrawLine**: `$0974C` is FASTSLANT; `.lit $0240`/`$0280` are
  SteepBlitXorTab/SteepBlitTab by dstShift (+10 for a negative slope; the
  card has its own 8 and 32 bpp loops and one generic loop for 1/2/4/16);
  horizontal fast lines `$09020`/`$09270`, wide-pen slabs `$0AAF4`/`$0AC0C`;
  `$0E398` is `QDUtil.a`'s DrawSlab;
* **BitBlt/RgnBlt**: the copy fast paths (bSETUP0, bLEFT0 and a shifted
  variant) and RgnBlt's srcCopy/Or/Xor/Bic loops; the slow hilite loops are
  `$1E35C`/`$22758`, the fast ones (mode `$3A` with an all-black small
  pattern) `$1D1BC`/`$1CF80`;
* **the C library**: the stdio core (ftell, fflush, fclose, `_flsbuf`, …),
  number conversion, signal/raise, the float helpers.

Also: `$36D90` writes 256 RGB triples to the RAMDAC (`$46C00000` index,
`$46C00004` data); `$36F4C` is a Park-Miller generator for the memory tests;
the packet's `+$04` holds host flags read by `$32BB4` (`$80`), `$33500`
(`$08`) and `$33520` (`$200`, 32-bit addressing). `$136C4` is DrawText.a's `CalcCharExtra`,
formula for formula, so `chExtra` is applied on the card. The last names are
weak only for a few: `$000C4`/`$000F4` poll the undocumented registers
`$444000C0` and `$44C00000` and have no callers (leftover diagnostics),
`$33BB0` reads packet `+$3C`, and five C-library hooks are named by what
they return. SelfTest's tests 0 and 3-6 are empty stubs; only 1, 2, 7, 8 and
9 test anything.

One example is `sub_00178`. It sets the funnel-shift count from an argument
(`mtsr FC, lr5`), loads 16 words into `gr96..gr111` (`mtsrim CR,$0f` +
`loadm`), runs them through a chain of 15 `extract` instructions, and
stores the result with `storem`. That is the inner loop of a bit-aligned
block copy, the core of a CopyBits-style blit.

Instruction mix:

* `add` 14,953;
* `load` 5,496 / `store` 2,722;
* `const` 5,187 / `consth` 2,202;
* `jmpt` 5,149;
* `sll` 2,873, `srl` 1,409, `sra` 714;
* `calli` 1,155 against `call` 555;
* `jmpi` 997;
* 608 `.word`: 586 tag words in front of functions, 22 floating-point
  opcodes (`$E4`-`$F7`, which the 29000 emulates by trap) and one zero word.

### Antelope: the command dispatcher (`sub_31e20`)

The function that runs the host's commands is `sub_31e20`
(`CommandDispatcher`, `$31E20`-`$328C4`). Antelope has 67 switch statements:
a `cpgtu` bound check, then `sll 2`, `const`/`consth` of a `.lit` table,
`load` and `jmpi`. Apart from the dispatcher's, the bounded ones have 4 to
30 cases. The dispatcher's has 61, at `$32850`:

    cpgtu  gr96, lr8, $3c     ; command > $3C -> default
    add    gr96, lr8, 0
    sll    gr96, gr96, 2
    const  gr122, $0080 / consth gr122   ; .lit+$0DE0
    add    gr122, gr122, gr96
    load   gr96, gr122
    jmpi   gr96

`$3C` is the largest command the host sends (PMgrExit: `GA_PMGR` → `sub_B1BE`).
The function is in object file 25, whose `.text` starts at `$31DA8` (with
`main` at `$31DAC`) and whose `.lit` starts at `$0D60`. `main` calls
`InitPacket` (which stores the packet pointer in `[.bss+0]`), clears packet
`+$14`, prints "PQDMonet: Starting up, commblock at %X", sets the sequence
counter `[.bss+8]` to 0 and `[.bss+4]` = packet `+$44` (`rec`), and then
calls `sub_31e20(-1)` forever. One call:

* It spins until packet `+$14` is nonzero. The host writes `$FFFFFFFF`
  there when it posts a request (`gc24.s` `$604A`).
* It stores 1 in packet `+$1C`. The host reads its return code from
  `+$1C` (1 = done, 0 = not handled; no card case stores 2, which is
  EngineDispatch's own answer while a picture, region or polygon is being
  recorded, see "The reply" in the DrawMultiObject section).
* It reads the command from `rec+$04` (packet `+$48`) into `lr8`. If the
  sequence number `rec+$08` differs from `[.bss+8]` and the command is not
  `$01`, it prints "MonetMain: Sequence error %d != %d, func = %d, last func
  = %d" (counter, received number, command, `[.data+$F08]`), sets bits 0-1
  of packet `+$00` and replies 0.
* Otherwise it saves the command in `[.data+$F08]` ("last func") and
  increments `[.bss+8]`.
* `sub_31e20(n, cmd1, …, cmdn)` is varargs: `n = -1` accepts every
  command; otherwise a command not among the `n` listed gets reply 0.
* It calls service `$D2` (kernel `$2001294`: restart the kernel if `gr64`
  bit 28 is set). Commands with `(cmd & $FF00) = $8000` go to `sub_37B58`
  (below); the rest go through the switch.
* Arguments are read through `rec+$10` (packet `+$54`), the pointer to the
  argument longs `p[0]`, `p[1]`, … Most cases store their reply in `+$1C`.
* The common exit (`$3287C`) calls the completion routine `sub_328C8`:
  it clears packet `+$14` and writes 3 to packet `+$18` (and to
  `*[packet+$20]` if that is set), or `$0B` if bits 0-1 of packet `+$00`
  are set. With the mapping flag `[extern#1772+$90]` set, the `+$18` write
  is bracketed by service `$D3(0)`/`$D3(1)`.

The table is `.lit` `$0DE0`-`$0ED0`, 61 relocated words. They are relocated
against the module's `.text` symbol (`$31DA8`), so each word is the case
block's offset from `$31DA8`; the default is `$A70` → `$32818`.

The table, exact (`lit.asm`, case code in `text.asm`):

| command | case block | handler / what it does |
|---|---|---|
| `$00`, `$03` | `$327D8`, `$327F8` | reply 0 ("not handled"); the two blocks are identical |
| `$01` | `$31FE8` | reset: `InitPacket(rec+$0C)`, sequence counter `[.bss+8]` = 0, then `CallBack(100, 1, 0)` (reset the host's request counter); its result is the reply |
| `$02`, `$05`, `$06`, `$07` | `$3287C` | the common exit itself: reply 1, nothing done |
| `$04` | `$32040` | stores `p[0]` at packet `+$04`; reply 0 |
| `$0C` | `$32408` | six longs -> `$151C4` **CachePixPat**; reply 0 if it returns 0 |
| `$0D` | `$32600` | `CacheFind(6, p[0])` (offscreen cache): not found, reply 0; found, entry `+$18` = `p[1] & $80` and the reply is entry `+$10` |
| `$0F` | `$32688` | `CacheFind(6, p[0])`: not found, reply 0; found, entry `+$18` = 0 (the host's UnlockPixels) |
| `$11` | `$3210C` | `sub_15D84(i)` for i = 0..10, then `sub_16BA0` (the first steps of PQDInit; start-up control record) |
| `$12` | `$326E8` | service `$CD(-1)` (clear the kernel's region table), `[extern#1772+$88]` = 0, `+$8C` = `[+$08]`, service `$D3(0)`, `+$90` = 0 |
| `$13` | `$32740` | service `$CC(p[0], p[1], p[2])` (enter a region), `[extern#1772+$88]` = 1, `+$8C` = 1 |
| `$14` | `$32080` | service `$D5(p[0])`: clears bit `p[0]` of the kernel word `$4C00643C` (mirrored to `$46000000`); reply 0 |
| `$15` | `$32148` | `$2D7B8` **StretchBits**(packet `+$58`, 0, 0, 0, 0) (host: `GA_TrapAB27`); reply 1 if it returns ≤ 0, else 0 |
| `$16` | `$3279C` | stores `p[0]`, `p[1]` in `[extern#1753+$18]`, `[extern#1753+$14]` |
| `$17` | `$320C8` | `$161F8` **PQDInit**(packet `+$604`); reply -1 if it fails (the host's reset routine `sub_6F4E` sends `$17`) |
| `$19` | `$32570` | one long -> `$14168` **FlushOffscreen** |
| `$1A` | `$325A0` | one long -> `$141F8` **FlushColorTable** (the host's SetEntries) |
| `$1B` | `$325D0` | one long -> `$14274` **FlushITable**: `CacheFind(1, p[0])`, then `CacheRelease(1, entry)` (the host sends `$1B` from MakeITable) |
| `$26`, `$38` | `$32234`, `$32284` | identical blocks. In the main loop (`n = -1`): reply 0. In a nested call: store `p[1]` at packet `+$1C0` and return without completing the request |
| `$29`, `$2B` | `$32468`, `$32498` | one long -> `$15808` **FlushGDevice** (`$29`: the host's AddSearch/…/SetDeviceAttribute) |
| `$2C` | `$324C8` | one long -> `$158F4` **FlushPixPat** (the host's DisposPixPat) |
| `$2D` | `$32188` | `$13770`(packet `+$170`), which plays the stream with DrawMultiObject. Result 0: reply 1; -1: reply -1; 7: `PQDInit(p[0])`, reply 0 if that fails; other: reply 0 |
| `$30` | `$322D4` | **font upload**: `p[0]` is a mask; bit 0 → `$14B64` UploadWidthTable(`p[1]`, `p[2]`), bits 1-4 → `$14A80` UploadFontStrike with the following longs; reply 0 on a failure (from `sub_88E6`: width table, font strikes; see "Text and fonts") |
| `$33` | `$324F8` | one long -> `$14034` **DisposeOffscreen**; the host sends it from LockPixels when the pixels were purged, DisposeGWorld and DisposeScreenBuffer (`QUICKDRAW_PATCHES.md`, `_QDExtensions` selectors) |
| `$3C` | `$32528` | copies `p[0]`, `p[1]` to the stack and calls `$140CC(&psn)`: the host's PMgrExit sends the quitting application's ProcessSerialNumber |
| all others | `$32818` | default: prints "Unknown Function: 0x%X" and sets bits 0 and 4 of packet `+$00` |

The default takes `$08`-`$0B`, `$0E`, `$10`, `$18`, `$1C`-`$25`, `$27`,
`$28`, `$2A`, `$2E`, `$2F`, `$31`, `$32`, `$34`-`$37` and `$39`-`$3B`.
Among them are the drawing and state selectors that EngineDispatch turns
into stream records instead of sending (`$18`, `$20`-`$24`, `$2E`, `$2F`,
`$31`, `$35`-`$37`; see "DrawMultiObject: the batched drawing stream").

Points that fit the host side (`QUICKDRAW_PATCHES.md`):

* `$26` and `$38` are the twin blocks. The host issues both around every
  drawing operation (`$0D ... $26 ... $38`). Their nested form is the one
  that matters: DrawMultiObject's wait `sub_33374` calls
  `sub_31e20(6, $26, $38, $30, $0C, $2A, $2C)`, and `$38`'s `p[1]` is the
  byte count it re-reads from packet `+$1C0`. DrawMultiObject completes
  the request itself (`$0AEF4` calls `sub_328C8`). `$2A` is in that list
  but has no case of its own.
* `$29` (AddSearch/DelSearch/AddComp/DelComp/SetDeviceAttribute), `$33`
  and `$2C` (DisposPixPat) are one-long commands on the host, and all go
  to one-long handlers.
* The host's `$8004(0x11111111, 0x22222222, 0x33333333)` check expects
  `$66666666`; the card's `$8004` returns `p[0] + p[1] + p[2]` (below).

#### Handlers named by their messages; the entry table

**The handlers name themselves.** Many functions pass a `.lit` string to
the reporter `sub_00140` (or `sub_00F78`). The strings and the functions
that reference them (exact):

| function | message | role |
|---|---|---|
| `$01468` | "Bogus" | |
| `$06650` ITabMatch | "ITabMatch: Inverse Table is not up-to-date" | |
| `$06BEC` BitsToPixMap | "BitsToPix: xm points to a portPixMap" | |
| `$0AD18` | "DrawMultiObject/opWhicPat: can't get a PatternCacheEntry for pattern", "DrawMultiObject/opWhichPat: can't find PixPat in cache", "… can't get a RGBPatCacheEntry for RGB Pattern", "DrawMultiObject/opSwapFont: width table is not in the cache", "… width font is not in cache", "… font is not cache", "DrawMultiObject: unknown opCode %d" | **the drawing engine**: an opcode interpreter (its jump tables are `.lit $0454`, `$046C`, `$0484`, `$0498`) |
| `$14034` | "DisposeOffscreen: NULL offscreen Handle" | command `$33` |
| `$14168` | "FlushOffscreen: NULL offscreen Handle" | command `$19` |
| `$141F8` | "FlushColorTable: NULL color table Handle" | command `$1A` |
| `$14F64` | "CacheGDevice: NULL GDevice" | |
| `$151C4` | "CachePixPat: NULL PixPatHandle" | command `$0C` |
| `$15808` | "FlushGDevice: NULL GDevice" | commands `$29`, `$2B` |
| `$158F4` | "FlushPixPat: NULL PixPatHandle" | command `$2C` |
| `$15DF8` | "Cache still busy, cacheType = %d, cache = %lx" | |
| `$161F8` | "PQDInit: Unable to allocate mega buffer" | initialisation (commands `$17`, `$2D`) |
| `$16A04` | "PQDAlloc: numBytes is not multiple of LONG", "PQDAlloc: illegal numBytes = %d", "PQDAlloc: maxed out on number of mega buffers authorized", "PQDAlloc: Unable to allocate extra mega buffer, size = 0x%x" | mega-buffer allocator |
| `$22A8C` | "ScaleBlt/scIndexToAny: unsupported dstShift = %d", "ScaleBlt: unknown scaleNum = %d" | scaleBlt |
| `$253D4` GetSeek | "GetSeek: invalid rectFlag for seekMask = %d" | |
| `$31DAC` main | "PQDMonet: Starting up, commblock at %X" | |
| `$31E20` | "MonetMain: Sequence error %d != %d, func = %d, last func = %d", "Unknown Function: 0x%X" | the command dispatcher |
| `$33680` | "malloc allocated %d bytes outside of the heap bounds, pointer = %x, heapMin = %x, heapMax = %x" | |
| `$3373C` MapVirtual | "MapVirtual: bytes == 0" | |
| `$33EBC` CallBack | "CallBack %d during inactive request" | |

This exhausts the strings. The run at `.lit $1020` is not text: it is the
C library's `_ctype_` table (257 bytes to `$1120`), whose entries for tab to
CR read `$28` (`_C|_S`) and for the other control characters, DEL and
128-255 `$20` (`_C`), as V7/BSD ctype has them.

So the card keeps caches of the host's colour tables (cache type 0),
GDevices (2), pixel patterns (5) and offscreens (6), plus inverse tables
(type 1, CacheITable `$14D78`), which command `$1B` releases. The one-long commands keep those caches in step:
flush or dispose an entry when the host's object changes. Drawing itself
is `DrawMultiObject`.

**An exported entry table.** `PQDInit` (`$161F8`) allocates 100 bytes,
stores the pointer in the external `extern#1636`, and fills it with 24
function pointers:

    +$00 $2D7B8 StretchBits  +$04 $13770  +$08 $0AD18 DrawMultiObject
    +$0C $01A50 BitBlt  +$10 $19DA4 RgnBlt  +$14 $22A8C scaleBlt  +$18 $3008C
    +$1C $075DC DrawArc  +$20 $08618 DrawLine  +$24 $11AD8 DrawText
    +$28 $19270 QuickPolys  +$2C $1701C FillLongs  +$30 $17264 Fill2Longs
    +$34 $153D4  +$38 $1553C  +$3C $32C10 ShieldCursor
    +$40 $32EF8 ShowCursorAfterDraw  +$44 $33EBC CallBack
    +$48 $3373C MapVirtual  +$4C $33A9C UnmapAll
    +$50 $31E20 CommandDispatcher  +$54 $00248 CopyLongsBurst
    +$58 $00348 FillLongsBurst  +$5C $00294 Fill2LongsBurst  +$60 0

Ten are the first function of their object file, four bytes in after the
file's tag word (`$01A50`, `$075DC`, `$08618`, `$0AD18`, `$11AD8`,
`$13770`, `$19DA4`, `$22A8C`, `$2D7B8`, `$3008C`).

**The `$80xx` commands (`sub_37B58`).** The dispatcher sends them to
`sub_37B58(cmd, rec+$0C, p)`, a switch on `cmd - $8000` (`.lit $1008`):

| command | does |
|---|---|
| `$8000` | reply 0 |
| `$8001` | `p[2](p[0], p[1], sub_379A0)` |
| `$8002` | heap-allocate `p[0]` bytes (`sub_3779C` → `sub_37658`); the reply is the address |
| `$8003` | free `p[0]` (`sub_377CC` → `HeapFree`) |
| `$8004` | reply `p[0] + p[1] + p[2]` |
| other | reply -50 |

`sub_379A0(task, selector, count, argv)` is the service callback that
`$8001` hands to the code it calls. It switches on `selector - $8008`
(18 cases, `.lit $0FC0`):

| selector | does |
|---|---|
| `$8008` | `CopyHostMemory(argv[0], argv[2], 0, 2, argv[1])`: copy `argv[2]` bytes from host address `argv[0]` into the buffer `argv[1]` (`$378E8`-`$37904`) |
| `$8011` / `$8012` | allocate / free (`$3779C`, `$377CC`) |
| `$8013` | `$3791C(argv[0..3])`: `MapVirtual(addr, len, &outLen, &outFlag)` (`$3791C`-`$37998`) |
| `$8014` | `UnmapAll`, then `$16BA0` (frees mega buffers 1-9 and rewinds buffer 0) |
| `$8015` / `$8016` | return `[extern#1772+$8C]` / `[extern#1772+$90]` |
| `$8017` | clear the mapped-range list head `[extern#1772+$00]` |
| `$8018` | return `[extern#1651]` (a 36-byte block PQDInit fills) |
| `$8019` | `$14020`: return the entry table `[extern#1636]` |
| `$8009`-`$8010`, out of range | `CallBack(999, 1, 4, task, selector, count, argv)`: the request goes to the host |

So code that the host uploads and starts with `$8001` gets a service
callback into Antelope, including the entry table with `DrawMultiObject`.

#### Host: the module/task API (`sub_1404`)

**The host side of `$80xx`: a module/task API (`gc24.s` `$1404`-`$239A`).**
`sub_1404(selector, params, &handle)` is a public entry point: gc24 exports it
as dispatch entry #105 (`$FFFFFFFD`, `GA_ControlFFFFFFFD` at `$6C70`, reached
through engine globals `+$14+$1A4`). The driver calls
it too: `DRVR` Control 54 (`$0F0A`) through slot `$A84` (entry #105's `+$28`,
filled at `$1076`-`$10A4` because the ID is -3) with `(csParam+2, csParam+6,
&globals+$AA0)`, and Status 54 (`$06D0`) with `(-1, 0, &globals+$AA0)`;
nothing in the repo sends Control/Status 54 (the selectors and their
arguments follow). Its state is a `$7A`-byte handle (`*&handle`, created on first use):

| offset | field |
|---|---|
| `+$00` | module table, `$1C`-byte records, `+$5E` of them (grows by 16) |
| `+$04` | task table, `$20`-byte records, `+$5A` of them (grows by 32) |
| `+$08` | module counter |
| `+$0C` / `+$0D` | request posted / reply ready (bytes) |
| `+$0E` | command (`$8001`-`$8004`) |
| `+$12` | reply |
| `+$16`, `+$1A`, `+$1E` | arguments; `+$56` = their count |
| `+$66` | a private `$70`-byte record (`NewHandle,SYS,CLEAR`, `$225C`-`$22B4`; `sub_1604` always passes slot 0); its `+$6C` points back here. The status word `sub_22DA` tests comes from the real unit (`[$888]` → `+$214`, `$231A`-`$2354`) |
| `+$6A` | the last result |
| `+$76` | a `$5C`-byte message buffer in card memory (from `$8002`) |

The selectors (`sel + 1` first, `addq.l #1` at `$144E`, so -1 is the first case; then `subq #1` per selector, then `$3DC` for 999):

| sel | routine | does |
|---|---|---|
| -1 | | return the last result |
| 0 | `sub_1604` | open: allocate the tables; send `$8004(0x11111111, 0x22222222, 0x33333333)` and require the reply `$66666666` (else -4); allocate the card message buffer with `$8002($5C)` (else -5) |
| 1 | `sub_1A2E`, params `{acef, size}` | load a module: `$8002(size)` allocates card memory, `ACEFLoad(acef, addr, size)` relocates and copies it there; returns module id `$53000000 \| n`. The module record keeps the card address (`+$08`) and the entry point (`+$0C`), always `addr + 4` because `ACEFLoad` overwrites the header's entry field (`$2528`/`$2534`). The result is 0 on any failure; the card block leaks when `ACEFLoad` fails |
| 2 | `sub_1B3C`, params `{module id}` | unload: kill the module's tasks, `$8003(addr)` frees its memory |
| 3 | `sub_1C94`, params `{module id}` | create a task of the module; returns task id `$54000000 \| n` |
| 4 | `sub_1D70`, params `{task id}` | kill a task: send it message `$FFFE`, free its handler list |
| 5 | `sub_1E12`, params `{task, sel, proc, refcon}` | register a host callback `proc` for selector `sel` of `task` (`sub_1810`, a linked list per task) |
| 6 | `sub_1E7E`, params `{msg}` | send a message and wait for the reply |
| 7 | `sub_1FD6`, params `{msg}` | send a message and wait until the task leaves state 3 (`$2118`), i.e. until it has sent `$8003` or `$8002`; returns the task id. Bit 7 of the caller's `msg+8` is set after the copy (`$20E8`) and never reaches the card |
| 8 | `sub_2130`, params `{task id}` | wait for the task's reply and return it |
| 9 / 10 | | return 1 / 0 |
| 11 | `sub_22DA` | idle: pump the mailbox and the card's requests |
| 999 | `sub_18BE` | a request from the card (below) |

**Sending a message.** A message is `{+$04 task id, +$09 length in bytes,
+$0A message type, +$0C data}`. `sub_1E7E` waits until the task is idle (state 0 or
2), writes `+$04` (task id), `+$0A` (type) and `length` bytes of data from
`+$0C` into the card buffer `+$76` (`$1F14`-`$1F64`, with `SwapMMUMode` to
32-bit; `+$08`/`+$09` are not written and the length is not checked against
the buffer's 80 data bytes), and posts `$8001(buffer, task.+$08, module entry point)`. The task
is then in state 3 (running) until the card answers. So **`$8001` is "run
this module's entry point on this message"**, and its card side is
`p[2](p[0], p[1], sub_379A0)`: `entry(message, task data, services)`
(**verified**). The uploaded code gets Antelope's service switch, and with
it the entry table that holds `DrawMultiObject`. Task creation (`sub_1BEE`)
sends message `$FFFF` and kill sends `$FFFE`, so these are the module's own
init and exit messages. The task then waits for state 2, which only a `$8002`
request sets; the `$8001` reply (the entry's return value) is discarded. If
the `$FFFF` answer is not 0, `sub_1C94` grows the task table and retries
until `NewPtrSys` fails (`$1D5E`), counting the task again on each try
(`$1C6C`).

**How the mailbox reaches the card.** The `$80xx` commands do not use a
separate channel. `sub_22DA` (the idle routine, which every wait loop calls)
takes a posted request and runs `EngineDispatch(+$0E, &+$16, +$56)`, the same
path as the drawing commands. It stores the reply in `+$12` and sets
`+$0D`. It then checks the card's status word: if bit 2 is set, it clears it
and calls `sub_6442`, the handler for requests from the card.

**Requests from the card (`sub_6442`).** The card writes a code into a
mailbox at its base address `+$24` (`+$04` of it). The handler reads it, sets it to
-1, and switches on codes 3-8, 12-18, 20-22, 100 and 999. Code 999 forwards
the card's request to `sub_1404(999, …)` with the handle `globals+$AA0`
(`$6594`); `argv` is copied, up to `count` longs with no bound, into a
16-long local array (`$15A8`), which reads `{task id, selector,
count, argv}` and runs `sub_18BE`:

| selector | does |
|---|---|
| `$8002` | the task's reply: store `argv[0]` in the task (`+$18`), state 2 (done); with no task, it is the reply to a mailbox command (`+$12`, `+$0D`) |
| `$8003` | state 1 |
| `$8004` / `$8005` | get / set a module field (`+$10`) |
| `$8006` / `$8007` | get / set a task field (`+$08`) |
| `$8010` | `_Debugger` |
| `$8000` | returns its `task` argument (`$192C` → `$1A22`) |
| `$8001`, `$8008`-`$800F` | -1 (`$8004`-`$8007` return -50 without a task; `$8010` returns 0; any other value ≤ 0 is -1) |
| > 0 | call the host callback registered for this selector: `proc(count, argv, refcon)` (Pascal order) |

On the card, `$37838`, `$377FC`, `$378A8` and `$3786C` would send
`$8004`-`$8007` (get/set module field, get/set task field), but nothing calls
them; a module reaches the selectors through `services` (`sub_379A0`'s
default → `sub_37730`). After a `$8003` request `sub_37730` calls
`sub_32AB8(1)`, which posts status 1 without clearing `+$14`: that ends the
host's wait while the command is still open (the asynchronous path;
nothing in the repo uses it).

`sub_6442` is also called from six wait loops inside `EngineDispatch`
(`$60B0`, `$612E`, `$62E8`, `$6362`, `$6EC8`, `$71A2`), so the card can make
a request while the host waits on any command. On the card, these requests
are made by `CallBack` (`$33EBC`, entry table `+$44`; below).

So the card runs host-loaded modules as tasks. A task gets messages through
`$8001`, answers with request `$8002`, and can call back to host routines
registered for it. This is a general extension mechanism. The ordinary
QuickDraw patches do not use it: they send selectors `$0C`-`$38` straight
through `EngineDispatch`.

#### Host: the card's requests (`sub_6442`)

**The card's requests to the host (`sub_6442`, decoded).** The mailbox is at
card address `+$24`: `+$04` request code, `+$08` reply, `+$0C` sequence
number, `+$14` argument pointer (`p`, a card address; the host forms it from
the slot base and the low 20 bits). The handler:
1. waits until the device is idle;
2. reads the code and sets it to -1;
3. checks the sequence number against its own counter. On a mismatch it
   replies -1, clears the code, takes the card's number and returns. Code
   100 skips the check and resets the counter to 0 (reply 1);
4. runs the request, writes the reply to `+$08`, counts the request and
   clears the code (`+$04` = 0, `$6C48`), which releases the card's wait.

The codes are all host services that 68k code has to perform for the card:

| code | does | reply |
|---|---|---|
| 3 | `NewHandle(p[0])` | the handle |
| 4 | `DisposHandle(p[0])` | |
| 5 | `ReallocHandle(p[0], p[1])` | |
| 6 | `SetHandleSize(p[0], p[1])` (trap `$A024`, `$6724`) | |
| 7 | `RGetResource(p[0], p[1])` (type, id) | the handle |
| 8 | copy `p[2]` longs from `p[1]` to `p[0]`, in 32-bit mode | the source address |
| 18 | the same, from the data of handle `p[1]` | the source address |
| 21 | the same, into the data of handle `p[0]` (skipped if it is purged) | |
| 12 | `MakeITable(p[0], p[1], p[2])` (colour table, inverse table, resolution) | `QDErr` |
| 13 | colour to index through the GDevice's search procs: for GDevice `p[4]` (or the current one), call each `SearchProc` on RGB `p[1..3]` | 1 and the index in `p[0]` if a proc handled it; the RGB is written back |
| 14 | the same with a list of complement procs at `p[0]` | 1 if handled |
| 17 | `Entry2Index(p[0])` (`PaletteDispatch` 0) on GDevice `p[1]` | the index, -1 on `QDErr` |
| 15 / 16 | physical addresses of a buffer (`p[0]`, or the data of handle `p[0]`) of `p[1]` bytes: `LockMemory`, then `GetPhysical` in runs of 8, the `(address, length)` pairs go to `p[3]`; then `UnlockMemory` | the number of runs, -2 if `p[2]` runs were not enough; -1 if bit 3 of the card's word `+$04` is clear |
| 20 | `OpColor` and `HiliteColor` of the device's port (`HiliteRGB` for a black-and-white port) | in `p[0..5]` |
| 22 | `GetSystemClientProcess` (`OSDispatch` `$3F`), if the Process Manager is present; otherwise `{0, 1}` | the PSN in `p[0..1]` |
| 100 | reset the sequence counter | 1 |
| 999 | a request to a host-loaded module (above) | |

Code 8 has one more fix: in 24-bit mode, a source address `$8xxxxx` gets
`$40000000` added (ROM in 32-bit space). Code 7's arguments are a type and an
id, so the card can read resources.

So the card handles its own drawing. It calls the host only for what lives
in 68k memory and code: handles and resources, user-installed colour search
and complement procs (which are 68k code), inverse tables, and the
foreground/hilite colours. Codes 15/16 are the interesting ones. Under
virtual memory they lock a host buffer and give the card its physical
pages, so the card can read or write host memory directly as a NuBus
master. That is how `MapVirtual` (below) reaches host-side pixel maps.

#### Card: `CallBack` and the request wrappers

**The card side of the requests (`sub_33EBC` "CallBack", exact).**
`CallBack(code, wait, nargs, a0, …, a7)`:
1. The mailbox is `[.bss] + $24`, the same packet base the dispatcher reads
   commands from.
2. Code 100 first zeroes the mailbox's `+$00` and the request counter
   (`.data+$F0C`).
3. If packet `+$14` is clear (no command is being serviced), it prints
   "CallBack %d during inactive request" and returns 0.
4. It stores three arguments (eight if `nargs > 3`) at `[mailbox+$14]`,
   the counter at `+$0C` (and increments it), and the code at `+$04`.
5. It sets bit 2 of packet `+$18`, and of `*[packet+$20]` if that is set:
   the status bit the host's idle routine tests.
6. If `wait` is set, it spins until the host has cleared `+$04`, then
   returns `+$08`, the reply (**verified**: the host writes 0 there last).

The calls (every `CallBack` call site in the exact listing):

| wrapper | code | args | called from |
|---|---|---|---|
| `$33BD0` | 13 (search procs) | 5: RGB, …, the current GDevice `[extern#1772+$74]` | `$0688C`, `$2BCEC`, `$2BE2C`, `$2BF80`, `$2C094`, `$2C1A8`, `$2C324` |
| `$33C6C` | 14 (complement procs) | 5 | `$06B1C` |
| `$33CFC` | 22 (`GetSystemClientProcess`) | 0, then copies the PSN out | `$1437C` |
| `$33D58` | 17 (`Entry2Index`) | 2: entry, the current GDevice | `$06844`, **`$0AD18` DrawMultiObject** (twice) |
| `$33D98` | 12 (`MakeITable`) | 3 | `$14D78` (next to CacheGDevice `$14F64`) |
| `$33DD4` | 8 (copy) | 3 | `$16C48` CopyHostMemory |
| `$33E10` | 18 (copy from a handle) | 3 | `$16C48` CopyHostMemory |
| `$33E4C` | 21 (copy into a handle) | 3 | `$14478` |
| `$33E88` | 1, no wait, no arguments | | no caller; the host's `sub_6442` ignores code 1 |
| `$3373C`, `$33A9C` | 15 (lock + physical pages) | 4 or 3 | see below |
| `$37730` | 999 (module request) | 4: task, selector, count, argv | the `$80xx` service switch `sub_379A0` (unhandled selectors) and `$377FC`, `$37838`, `$3786C`, `$378A8` (which have no callers) |
| dispatcher `$31FE8` | 100 (reset) | 0 | command `$01` |

Not used on the card: codes 3-7 (handles, resources), 16 and 20. They are
open to host-loaded modules, which get `CallBack` as entry-table `+$44`.

**`$3373C` and `$33A9C` (entry table `+$48`, `+$4C`) map host memory.** They
are the only users of code 15. `MapVirtual` is called from the entry-table
functions StretchBits `$2D7B8` (`+$00`), `$13770` (`+$04`), BitBlt
`$01A50` (`+$0C`), RgnBlt `$19DA4` (`+$10`), scaleBlt `$22A8C` (`+$14`)
and `$3008C` (`+$18`), and from service `$8013`; `UnmapAll` from
StretchBits, `$13770` and service `$8014`. So those six entry points are
the ones that read or write host memory directly: the transfer routines
for pixel maps in host RAM. `DrawMultiObject` itself only asks for
`Entry2Index`; `$13770` maps the memory before it calls it.

#### Card: `MapVirtual` and host memory

**`$3373C` is `MapVirtual` ("MapVirtual: bytes == 0").** `MapVirtual(addr,
len)`, with `extern#1772` fields `+$00`/`+$04` list head/tail, `+$08` a
flag set at init from `sub_33500`, `+$88` set by command `$13`, `+$90`
the mapping flag:
1. `len == 0`: print the message, return -1.
2. If `+$88` is set, service `$D4` translates `[addr, addr+len)`. If it
   covers all `len` bytes, return the translated address. If it covers
   part: with `+$08` clear, call `$D3(1)`, set `+$90` and return `addr`;
   with `+$08` set, return the `$D4` result unless `addr` lies inside an
   entry of the list of mapped ranges, in which case go on.
3. With `+$08` clear, return `addr` unchanged.
4. Build an entry `{+$00 addr, +$04 len, +$08 runs, +$0C run table, +$10
   next}` at the mega buffer's free pointer (`sub_169A0`; `sub_169D8`
   gives the room left, which bounds the run table at `+$14`).
   `CallBack(15, 1, 4, addr, len, max, table)` has the host lock the buffer
   and return its physical runs. No runs: return -1.
5. Call `$D3(1)` and set `+$90`.
6. For each run, and each 4 KB page in it, call service `$CC(virtual
   page, physical page, $1000)` to enter the page in the kernel's region
   table (`Hand` `$200146C` → `$2001478`). If that fails, it removes the
   pages already entered with `$CD(page)` (`$20015F8` → `$2001604`), calls
   `CallBack(15, 1, 3, addr, len, 0)` to unlock (on the host, a run count
   of 0 means `UnlockMemory`) and returns -1.
7. `PQDAlloc(8·runs + $14)` claims the entry, which is linked in at the
   tail; it returns `addr`.

`$33A9C` is the release, `UnmapAll`: only if `+$90` is set, it calls
`$D3(0)` and clears `+$90`; then, if `+$08` is set, for every entry it calls
`$CD` per page and `CallBack(15, 1, 3, addr, len, 0)` to unlock. It does
not clear the list (selector `$8017` does).

**Which commands reach host memory.** Two dispatcher cases call the
entry-table functions:

| command | case | calls | sent by the host |
|---|---|---|---|
| `$15` | `$32148` | `$2D7B8` (entry `+$00`) with packet `+$58` | `GA_TrapAB27` (`gc24.s` `$32BC`), one argument |
| `$2D` | `$32188` | `$13770` (entry `+$04`) with packet `+$170` | `$4F38`, when a stream starts (the block at packet `+$170`) |
| `$11` | `$3210C` | `$15D84`, then `$16BA0` | the control record `$FFFFFFFE` (start-up) |

`GA_TrapAB27` patches trap `$AB27`, which is `StretchBits` (below). It runs
only if the device's flags have bits `$27` set and bits `$600` clear, and
the `pat` argument is NIL.

`sub_8262` then builds a parameter block in card memory (packet `+$58`), and
the patch sends `$15` with a pointer to it; the card takes the block from
packet `+$58` directly. A reply of 1 means the card did
the transfer; the patch then sets bit 7 of `HiliteMode` (`$938`), as
QuickDraw does after a drawing call, and skips the original. On the card,
`$2D7B8` is a large routine that:
- calls `MapVirtual` three times and `UnmapAll` once;
- uses the caches (`$14F64` CacheGDevice, `$14D78` CacheITable, which has
  the host run `MakeITable`, `$14BD4` CacheColorTable) and `CopyHostMemory` `$16C48` (codes 8 and 18);
- calls `$01494` RSect and `$01654` TrimRect repeatedly (named from
  DrawMultiObject's region opcode, below) and `$3B600` `memcpy` twice;
- refers to BitBlt, RgnBlt, scaleBlt, `$3008C`, ColorMap, BitsToPixMap,
  ShieldCursor and ShowCursorAfterDraw.

So **command `$15` is the card's bit transfer between host pixel maps**: the
CopyBits path for memory the card cannot address directly. The card maps the
host pages and moves the pixels itself.
#### StretchBits (command `$15`)

**Trap `$AB27` is `StretchBits`, and command `$15` carries its parameter
block.** The argument list of `GA_TrapAB27` is exactly the one in the System
7.1 source (`QuickDraw/Stretch.a`):

```
StretchBits(srcBits, maskBits, dstBits: BitMap; srcRect, maskRect, dstRect: Rect;
            mode: INTEGER; pat: Pattern; rgnA, rgnB, rgnC: RgnHandle)
```

`pat` must be NIL for the card to take the call. `sub_8262` fills a
`$10A`-byte block in card memory (packet `+$58`, so it sits in the packet
after the command header), and `$15` passes its address:

| offset | contents |
|---|---|
| `+$000` | mode (word). `srcXor` becomes `$32` (hilite) when `HiliteMode` bit 7 is clear |
| `+$002` | dstBits: the whole PixMap (`$32` bytes), or the 14-byte BitMap |
| `+$036` | srcBits, the same way |
| `+$06A` | maskBits, the same way (`baseAddr` 0 when there is no mask) |
| `+$09C`, `+$0A0`, `+$0A4` | for dst, src, mask: 0 if `pmReserved` bit 0 is set; the handle if `pmVersion` = 2 (its `baseAddr` is dereferenced into the copy); `sub_822E(baseAddr)` if `pmVersion` = 1 |
| `+$0A8`, `+$0B0`, `+$0B8` | dstRect, srcRect, maskRect |
| `+$0C0`, `+$0C4`, `+$0C8` | rgnA, rgnB, rgnC: the region pointers (master pointers, so host addresses) |
| `+$104`, `+$106`, `+$108` | their `rgnSize` words |
| `+$0CC` | a flag (the trap's last word shifted down, ORed with low memory `$256`) |
| `+$0D0` | `TheGDevice` (`$CC8`) |
| `+$0D4` | low memory `$8A0` |
| `+$0E0`, `+$0E4` | the port's foreground and background colour indices. They are recomputed with `Color2Index` when the GDevice has search procs |
| `+$0E8`, `+$0EE` | `rgbFgColor`, `rgbBkColor` (an old port's colours come from `sub_917E`; `+$0F6` is then its `colrBit`) |
| `+$0F4` | the port is a colour port |
| `+$0F8`, `+$0FE` | for arithmetic modes (mode bit 5) at depths above 1: `OpColor` and `HiliteColor` (`HiliteRGB` for an old port) |

A PixMap's `rowBytes` bit 14 marks a port's pixmap handle, which is
dereferenced first. The destination depth comes from `TheGDevice` when
`dstBits.baseAddr` is the screen (`ScrnBase`, `$824`), else from the PixMap.

So the card gets StretchBits with everything QuickDraw would read from the
port and the device, but the pixel data and the regions stay in host memory.
The block carries host addresses: `baseAddr`, the region master pointers and
the handles. That is what `MapVirtual` is for. `$2D7B8` is then the card's
StretchBits. The dispatcher's case for `$15` (`$32148`) calls
`$2D7B8(packet+$58, 0, 0, 0, 0)` and leaves the reply at 1 when it returns
0 or less, else replies 0; `$2D7B8` reads the region pointers at block
`+$C0`/`+$C4` first (`$2D7F4`). The strings of its neighbour `$22A8C` (entry
`+$14`), "ScaleBlt/scIndexToAny: unsupported dstShift = %d" and "ScaleBlt:
unknown scaleNum = %d", name Stretch.a's `ScaleBlt` family.

**Early release.** On the command path (arg1 = 0) `$2D7B8` calls
`ReleaseHostEarly(1)` (`$32AB8`: waits for `+$18` bit 2 clear, writes status
1 to `+$18` and `*[+$20]`, leaves `+$14` and the reply 1 in `+$1C`) once no
pixmap it uses is still in host memory: after the regions are copied to the
card, sources and masks of ≤ 5000 bytes copied (`CopySmallPixMapToCard`
`$16148`), and dst, src and mask each on the card or the screen
(`BitsToPixMap` `+$24` clear or `+$20` set; `$2E2D0`-`$2E338`). It releases at
once (`$2E3DC`) when no colour translation is needed, or when the GDevice
has no search procs (indexed sources: also ctFlags bit 14 clear).
Otherwise, for an indexed source, it releases at `$2EDA4`, after
`MakeScaleTbl` has run any `Color2Index` callbacks. A direct source under
search procs, or any destination in host memory, is never released early.
So card-to-card copies (screen, cached offscreens), small host sources and
host-ROM data overlap with the 68k; copies into host memory and large host
sources do not. `EngineDispatch`'s wait (`$6074`-`$6116`) ends on status 1
and returns the reply; the next command waits in `sub_624A` (`$5EC8`) for
status bit 1, the completion. Only GetPixBaseAddr, GetPixel/GetCPixel and
the patches' own 68K fallbacks wait for the card (see "When the host waits
for the card"); a program that writes through a saved `baseAddr` gets no
protection.

#### The entry table, named

**The entry table read against System 7.1 QuickDraw.** Antelope looks like
compiled C (printf-style messages, C frames), not a port of the 68k sources, so names come from matching roles: the
strings, who calls whom, and which routines use the region seek code. The
anchors:

* `$253D4` prints "GetSeek: invalid rectFlag for seekMask = %d". In
  `QuickDraw/SeekMask.a`, `GETSEEK` combines the clip
  regions (and a mask) into a per-scanline seek routine. Its 68k callers are
  `Stretch.a`, `ScaleBlt.a`, `RgnBlt.a`, `DrawLine.a`, `DrawArc.a` and
  `QuickPolys.a`, but not `BitBlt.a`.
* `$22A8C` prints "ScaleBlt/scIndexToAny: unsupported dstShift = %d" and
  "ScaleBlt: unknown scaleNum = %d". `ScaleBlt.a`'s `scaleBlt` picks a depth-conversion loop
  (`scaleCase`) from a table and imports `GetSeek`. `$22A8C` calls
  `GetSeek` and 17 workers (`$230B4`-`$25354`, 19 call sites), and switches
  through `.lit` tables (`$0958`, 30 cases; `$09D0`; `$09E0`).
* `$2D7B8` is StretchBits (command `$15`, above). It calls `GetSeek`,
  `$22A8C`, `$01A50` and `$19DA4`, as Stretch.a calls `GetSeek`, `scaleBlt`,
  and the blitters for the unscaled cases.

| entry | function | name | evidence |
|---|---|---|---|
| `+$00` | `$2D7B8` | **StretchBits** | host trap `$AB27`, the parameter block |
| `+$14` | `$22A8C` | **scaleBlt** | strings; `GetSeek` + a family of depth loops |
| `+$0C` | `$01A50` | **BitBlt** | called by StretchBits, DrawLine, QuickPolys and DrawMultiObject; does *not* call `GetSeek`; switch tables by mode (`.lit $0008`-`$0068`); falls back to `$19DA4` |
| `+$10` | `$19DA4` | **RgnBlt** | calls `GetSeek`; called by BitBlt, StretchBits, text and shapes; a four-way switch picks one of four mode loops `$1B33C`, `$1BAE0`, `$1BC64`, `$1BDE8` (`$1B2A0`-`$1B2DC`) |
| `+$1C`, `+$20`, `+$28` | `$075DC`, `$08618`, `$19270` | the three shape drawers that use `GetSeek`: `$075DC` **DrawArc**, `$08618` **DrawLine**, `$19270` **QuickPolys** (settled by DrawMultiObject's polygon opcode, below) | same helpers (`$0E398`, `$1114C`, `$17500`, `$1553C`); called by DrawMultiObject |
| `+$24` | `$11AD8` | **DrawText** (see "Text and fonts") | calls StretchBits and scaleBlt (scaled text goes through StretchBits in QuickDraw) and RgnBlt, not BitBlt; uses `extern#1772+$60`-`$6C` |
| `+$18` | `$3008C` | **FastStretch32**: a region-clipped scaled copy of a 16- or 32-bit source into a 32 bpp destination (GetSeek, then one row loop per srcShift, `$304D8` for 5, `$3147C` otherwise, with file 2's pixel stretchers `$004FC`/`$00534`); three smoothing variants (`$308F0`, `$30E14`, `$31888`) have no callers. Its object file (`$30088`-`$31DA4`) holds five more routines, each entering an unrolled loop through a 15-entry `.lit` jump table (`$0C30`, `$0C6C`, `$0CA8`, `$0CE4`, `$0D20`; entries are offsets from `$30088`) | |
| `+$08` | `$0AD18` | **DrawMultiObject** | its strings; calls all of the above |
| `+$04` | `$13770` | **DrawStreamCommand**, command `$2D` | calls DrawMultiObject, `MapVirtual`, the caches |
| `+$3C`, `+$40` | `$32C10`, `$32EF8` | **ShieldCursor** (before drawing) and its counterpart (after drawing): the cursor lock with the host, see "The cursor" below | |
| `+$34`, `+$38` | `$153D4`, `$1553C` | **SetShieldRectUnion**, **SetShieldRect**: set that rectangle: `$1553C(r, origin)` stores `r` minus `origin` as four 16-bit words at `extern#1772+$78`-`$7E`; `$153D4(r1, r2, origin, flag)` stores `r1`, unioned with `r2` minus `origin` when `flag` is set, and returns whether it is non-empty | |
| `+$44`-`+$4C` | | `CallBack`, `MapVirtual`, `UnmapAll` | above |
| `+$50` | `$31E20` | the command dispatcher | |
| `+$2C`, `+$30`, `+$54`-`+$5C` | `$1701C`, `$17264`, `$00248`, `$00348`, `$00294` | small helpers: `$1701C` the long fill, `$00348` the `storem` burst fill (called by nearly every blitter) | |

**The three shape drawers (profile).** The listing gives each one's
instruction mix, data references and callees:

| | `$075DC` (`+$1C`) | `$08618` (`+$20`) | `$19270` (`+$28`) |
|---|---|---|---|
| words | 770 | 643 | 717 |
| stores | 19 | 16 | **57** |
| shifts (`sra`/`srl`/`sll`) | **36**/7/21 | 12/6/14 | 13/6/17 |
| FixMul `$00CC4` | **yes (2 refs)** | no | no |
| calls BitBlt / RgnBlt | no | yes | yes |
| own switch | none | 6-way on `lr35` (`.lit $0228`) | none |
| ShieldCursor | once each | `$32C10` twice | once each |

The shared helpers are runtime and support code:
- `$00CC4` is FixMul: a 32×32 multiply (31 `mul` steps, `mull`) whose
  64-bit product is shifted down 16 bits; an argument of `$10000` returns
  the other one at once;
- `$3BA38` is an unsigned divide (31 `div` steps);
- `$3B814`/`$3B950` are the multiply and divide millicode entries (called with `calli gr122`);
- `$1114C` and `$11A34` return the address of a scanline loop chosen by
  the mode (36 and 7 possible loops; `$1114C` partly through `.lit`
  tables such as `$0508`), like QuickDraw's mode-case tables;
- `$0E398` is DrawSlab and `$17500` PatExpand.

The calls settle the names:
- `$19270` sorts its edges with SortVectors `$19134` (`$1965C`), as
  `QuickPolys.a` does: **QuickPolys**.
- `$075DC` calls SlopeFromAngle `$081E0` (`$077AC`, `$077E8`) and FixMul
  (`$077D4`, `$07808`), as `DrawArc.a` does: **DrawArc**.
- `$08618` is **DrawLine** (DrawMultiObject's line record, below). Its
  6-way switch (`$08860`-`$08880`) is on the destination's `dstShift`
  (`lr35`, 0-5) and picks the vertical-line fill: `$09430`
  FillColumnMasked for 1, 2, 4 and 16 bpp, `$09578` FillColumn8, `$09660`
  FillColumn32.

Two more names come from the strings: `$06650` "ITabMatch: Inverse Table is
not up-to-date", and `$06BEC` "BitsToPix: xm points to a portPixMap" (called
from StretchBits and `$13770`).

So the table is Antelope's QuickDraw core, handed to host-loaded modules: the
blitters, the shape drawers, text, and the support routines for host memory
and callbacks.

#### The cursor: a lock shared by host and card

The host patches every cursor vector (`JHideCursor`, `JShowCursor`,
`JShieldCursor`, `JInitCrsr`, `JSetCrsr`, `JCrsrObscure`, `JSetCCrsr`,
`JCrsrTask`). The patches send no commands. Instead the host and the card
share a lock in the packet. `DRVR.s` (`$122E`-`$1312`) points the engine
globals into the packet:

| global | packet | role |
|---|---|---|
| `+$08` | `+$1D4` | host claim: the vector being run (`$800`, `$804`, …), 0 = free |
| `+$0C` | `+$1D8` | card busy: 1 while the card draws |
| `+$10` | `+$1DC` | the card's drawing rectangle (8 bytes) |
| `+$1C` | `+$130` | the union of deferred ShieldCursor rectangles (8 bytes; see "Deferred cursor calls" below) |
| `+$28`, `+$2C` | `+$1EC`, `+$1F0` | |
| `+$30` | `+$5F0` | card → host: "I removed the cursor" (the host clears `CrsrVis`) |
| `+$34` | `+$5F4` | card → host: "redraw the cursor" (the host sets `CrsrNew`) |

The driver also gives the card card-side pointers (through `$1CF6`, which
maps host memory for the card) to the host's cursor state:

| packet | host memory | size |
|---|---|---|
| `+$5F8` | `CrsrRect` (`$83C`) | 8 |
| `+$5FC` | `CrsrVis` (`$8CC`) | 1 |
| `+$600` | `CrsrDevice` (`$89C`) | 4 |
| `+$1E4` | `CrsrPtr^` (`$D62`), the colour cursor save area | `$50` = `CCSAVEREC` |
| `+$1E8` | the save area's `CCSAVE` handle's data, the bits under the cursor | `$400` |

(Names and the record layout are from `SysEqu.a` and `ColorEqu.a`.)

**Host side** (for example `GA_LowMem0800`, `$42B8`, `JHideCursor`):
1. save `*[+$08]`;
2. wait until `*[+$0C]` (card busy) is 0;
3. write the vector number to `*[+$08]`;
4. if the card has become busy meanwhile, restore and retry;
5. if `*[+$30]` is set, clear `CrsrVis` (`$8CC`) and the flag;
6. run the original cursor routine, call `sub_C034`, and restore
   `*[+$08]`.

`sub_C034` is `_HWPriv` with selector 3, **FlushDataCache**. It runs after
every cursor routine, so the card sees the screen and the cursor
variables as the 68K left them (a 68040 copyback cache would otherwise
hold them back). The cursor task patch (`GACursorTask`, `$801C`, on
`JCrsrTask` `$8EE`) does the same and more:
* it skips the cursor task entirely while the card is busy;
* it clears `CrsrVis` on `+$5F0`;
* if the cursor is not obscured (`CrsrObscure` `$8D2` = 0) and `+$5F4` is
  set, it sets `CrsrNew` (`$8CE`) = 1 and clears the flag, so the task
  draws the cursor again;
* it runs the original task, then FlushDataCache.

**Deferred cursor calls during CopyBits.** Engine global `+$18` is a nesting
count. `GA_CopyBits` (`$483C`) raises it around the original CopyBits (on
the path that does not go to the card directly) and, at the outermost level,
clears the accumulators below. While it is non-zero, the cursor patches
record instead of acting:

| call | while `+$18` ≠ 0 |
|---|---|
| ShieldCursor (`$808`, `$44C4`) | unions the rectangle into `*[+$1C]` (packet `+$130`), `+$40` += 1 |
| ShowCursor (`$804`, `$420C`) | cancels a pending shield (`+$40` −= 1); with none pending, `+$44` += 1 (kept ≤ 1) |
| HideCursor (`$800`, `$42B8`) | `+$44` −= 1 |
| InitCursor (`$814`) | clears both counts |

CopyBits ends up in StretchBits, which `GA_TrapAB27` sends to the card
(`$15`):
* **If the card does it** (reply 1), the patch just returns. The recorded
  calls are dropped, because the card handles the cursor through the lock
  (below).
* **If not**, before running the 68K StretchBits the patch replays them
  (`$33BC`-`$3484`):
  * the real ShieldCursor on the union rectangle, if a shield is pending
    and the rectangle is not empty (under the lock, with FlushDataCache);
  * the real ShowCursor while `+$44` < 0;
  * then it puts the rectangle back and clears `+$18`, so the calls that
    follow, inside CopyBits, run normally.

The replay is inverted. Swallowed HideCursor calls (`$42D4`) leave `+$44`
negative, and `$345A`-`$3474` answers them through `JShowCursor` (`$804`)
instead of `JHideCursor` (`$800`). That raises the cursor level and, on 7.1,
also cancels the ShieldCursor just replayed (`CCrsrCore.a` decrements
`ShieldDepth` first). QuickDraw itself never triggers it: CopyBits' only
cursor call before StretchBits is ShieldCursor, and its ShowCursor runs
after the replay has ended. Only a custom bitsProc calling HideCursor in
that window would. System 6's `gc24` has no `+$44` counting.

`EngineDispatch` and `sub_6442` also wait for `*[+$08]` to be 0 before they
touch the packet (`$5F04`, `$646C`). `JHideCursor`/`JShowCursor` only count
(`+$40`, `+$44`) while `+$18` is set.

**Card side.** Every drawing routine brackets its work the same way:
1. `$1553C` sets the drawing rectangle (`extern#1772+$78`-`$7E`);
2. `$32C10` runs before the drawing;
3. the drawing;
4. `$32EF8` runs after it.

For example: DrawLine `$087EC` … `$08FD4`, BitBlt `$01E9C` … `$02D04`,
DrawArc `$07CAC` … `$07DE0`, and DrawMultiObject's line case `$0BFBC`,
`$0BFCC` … `$0C070`. Both are in the entry table (`+$3C`, `+$40`).

Both start the same way:
1. if `extern#1772+$90` is set, call service `$D3` (`$390B4`, host access
   mode) with 0, and with 1 on the way out;
2. take the lock: wait until packet `+$1D4` (host claim) is 0, set `+$1D8`
   = 1; if the host claimed it meanwhile, clear `+$1D8`, wait again and set
   it (one retry, not checked again);
3. copy `CrsrRect` through the pointer at `+$5F8` (`memcpy` `$3B600`, 8 bytes);
4. look up `CrsrDevice` (`+$600`) in the card's GDevice cache with
   `CacheFind(2, gdevice)` (`$15D28`). If it is not there, skip to the end.
   Otherwise take the device's origin from the entry (`+$32`);
5. test the drawing rectangle (`extern#1772+$78`-`$7E`, global) against
   `CrsrRect`, after subtracting the device's origin (the cached entry's
   `+$32`, v then h). The four exits are `bottom < crsr.top`,
   `right <= crsr.left`, `top >= crsr.bottom` and `left >= crsr.right`,
   so a drawing whose bottom edge touches the cursor's top row still
   counts as overlapping. No overlap: skip to the end.

**`$32C10`, before drawing: remove the cursor.** It publishes the drawing
rectangle at `+$1DC` right after taking the lock (`loadm`/`storem` from
`extern#1772+$78`, `$32CB4`). If `CrsrVis`
(through `+$5FC`) is set and `+$5F0` is not already raised, it does
`UnblitCursor` from `CCrsrCore.a`:
* it reads `CCSTATEREGS` from the save area (`+$1E4` → `+$3E` ROWCNT, `+$40`
  LONGCNT, `+$44` DSTBUMP, `+$48` DSTLEFT);
* it copies the saved bits back to the screen row by row:
  `$38218(screen row, save buffer, longs)`, `ROWCNT+1` rows of
  `LONGCNT+1` longs, with the screen pointer stepped by
  `DSTBUMP + 4*(LONGCNT+1)`, exactly as `UnblitCursor`'s
  `MOVE.L (A1)+,(A2)+` / `ADD D4,A2` loop does. If `extern#1772+$88` is
  set, DSTLEFT first goes through the `$D4` stub `$39050` (address
  translation);
* the save buffer is the card's own copy at packet `+$1F0` when `+$1EC` is
  non-zero, and otherwise the host's `CCSAVE` bits (`+$1E8`);
* the 68K version ends with `CLR.B CrsrVis`. The card leaves that to the
  host and raises `+$5F0` instead.

Then it releases `+$1D8`. The rectangle at `+$1DC` stays published.

**`$32EF8`, after drawing: re-save and ask for a redraw.**
* It runs the same row loop with the two pointers swapped,
  `$38218(packet+$1F0, screen row, longs)`, so the freshly drawn pixels
  under the cursor are saved, into the card's own buffer in the packet
  (`$400` bytes, the size of the host's `CCSAVE` area), not into the
  host's. There is no `CrsrVis` or `+$5F0` test.
* It stores the number of longs minus 1, `(ROWCNT+1)*(LONGCNT+1) - 1`
  (multiply millicode `$3B814`), at `+$1EC`, which marks the card's copy as
  valid.
* Then it raises `+$5F4` ("redraw", `$33148`). On every path, overlap or
  not, it clears both the published
  rectangle (`+$1DC`-`+$1E2`) and the drawing rectangle
  (`extern#1772+$78`-`$7E`), and releases `+$1D8`.

(The old reading of `$32EF8` as "ShieldCursor with two rectangles" was
wrong: it clears the rectangle, it does not merge one.)

**The full cycle:**
1. the card takes the lock and, if its drawing overlaps a visible cursor,
   restores the bits under it (`+$5F0`: the host clears `CrsrVis`);
2. it draws;
3. it takes the lock again, copies the new pixels under the cursor into
   its own buffer at packet `+$1F0` (count at `+$1EC`), and raises `+$5F4`
   (the host sets `CrsrNew`);
4. the host's cursor task draws the cursor again.

The card's copy is used in two places. The card's next ShieldCursor restores
from it instead of the host's save area. And the host's reset routine
(`gc24` `sub_6F4E`, `$7046`) `_BlockMove`s `(n+1)*4` bytes of it into the
host's `CCSAVE` bits (engine global `+$04`, set by `DRVR.s` `$121E`) and
clears `+$1EC`. The card never writes host memory here. It reads the host's cursor state
(`CrsrRect`, `CrsrVis`, `CrsrDevice`, `CCSAVEREC`, `CCSAVE`) through the
mappings and writes only the screen and the packet (`+$5F0`, `+$5F4`,
`+$1EC`/`+$1F0`); the host applies each result itself (clears `CrsrVis`,
sets `CrsrNew`, and `sub_6F4E` `$7046`-`$7074` BlockMoves the copy into
`CCSAVE`). The code does not say why. As read, nothing but `sub_6F4E`
clears `+$1EC`, so every later `$32C10` restores from the card's copy,
although BlitCursor re-saves `CCSAVE` at each host redraw: after the cursor
moves, or after 68K drawing under it, between two card draws, that copy is
stale (*reading*; System 6 has the same logic, `$2E9C4`).

These readings are from the exact listing. `$38218` is
`(destination, source, longs)`: it `loadm`s from its second argument and
`storem`s to its first (`$383C4`/`$383D0`).
#### DrawMultiObject: the batched drawing stream

**In short.** The QuickDraw bottlenecks (StdLine, StdText, StdArc, StdRect,
StdRRect, StdOval, StdPoly, StdRgn) are not sent to the card one by one.
`EngineDispatch` in `gc24` turns each call into records of a stream in card
memory:
* first records for whatever port state changed (pen, colours, patterns,
  mode, regions, font);
* then one record for the drawing itself.

The card plays the stream back in **DrawMultiObject** (`$0AD18`), started
with command `$2D` and fed with `$38`. Fonts reach the card by a separate
upload (`$30`) into a cache of host objects.

The 68K side below is read from `gc24.s`, which is plain code. The card side
is read from the exact listings (`firmware/disasm/text.asm`, `lit.asm`,
`data.asm`); addresses, values and control flow are exact, and a role
inferred from use is marked as a reading.

##### The host side: EngineDispatch writes the stream

**Which commands are batched.** For commands `$0C`-`$38`, EngineDispatch
jumps through its own table (`$4A52`). Most cases end in the generic send
path (`L5E6C`), but the drawing commands go to `L4AAC`, which:
1. checks the current port (from the A5 world). With none, it flushes and
   returns 0, so the 68K draws;
2. when `picSave`, `rgnSave` or `polySave` (port `+$5C`/`+$60`/`+$64`) is
   set, notes the reply 2 (below);
3. emits state records for whatever changed since the last call (it caches
   the port's state in its globals);
4. emits one drawing record for the call.

**The buffer:**

| global | role |
|---|---|
| `$AC(a4)` | buffer start (host address) |
| `$C4(a4)` | buffer start (card address) |
| `$B0(a4)` | write pointer |
| `$B4(a4)` | the last record, so a repeated `$6A`/`$6C` replaces it instead of adding one |
| `$BC(a4)` | capacity |
| `$C0(a4)` | bytes used |

**Starting a stream** (`$4EBC`, when the port differs from the cached one):
1. reset the buffer;
2. write a 4-byte `$6F` header record;
3. set the length to 4 (at `+$50` of a block at packet `+$170`, whose `+$4C`
   holds the card address);
4. send `$2D` with that block. On the card, `$2D` (`$32188`) calls
   `$13770(packet+$170)`, the only caller of DrawMultiObject (PQDInit also
   stores DrawMultiObject's address at `+8` of its module descriptor). It
   runs until the first wait.

**After each drawing call** (`$38`, `L5DE0`), if the buffer holds more than
the header:
1. rewrite the header's word at `+2` with flags (`$F0(a4)`);
2. send `$38` with (card address, byte count).

On the card, the nested wait inside DrawMultiObject services `$38`. Its case
(`$32284`) stores the count (`[p[0]+4]`) at packet `+$1C0` (the `+$50`
word above); the wait copies it into DrawMultiObject's length word once it
has grown. The card's `$26` case (`$32234`) is the same code.

**Flushing and ending.**
* When a record would not fit (`$BC − size − $24 ≤ $C0`), EngineDispatch
  flushes with `sub_4822(reason)`, that is `EngineDispatch($26, reason)`.
  The reasons seen are 5, 8, 9, `$10`, `$12`, `$13`, `$14`, `$15` and `$18`.
* `$26` (`L5D84`) first sends a final `$38` if needed, then ends the batch.

**When the host waits for the card.** `$2D` returns at once
(`DrawStreamCommand` replies before DrawMultiObject runs, `$13BE8`). Inside
a stream, `$38` is completed only at the next end of the bytes (`$0AEF4`),
so it is a full drain; `$26` is released at once (`$0AF3C`) and the unread
records are drawn afterwards. Every command sent waits in `sub_624A` for
status 3. `sub_6E14` is a non-blocking poll: with a stream active it
compares the card's read pointer (packet `+$1C8`) with the host's write end
(`$B8(a4)`), otherwise it returns status bit 1.

| patch | waits? |
|---|---|
| Std* fallback when the card declines (`sub_86D6`) | drains with `$38` (or waits in `sub_624A`), then `$0D` |
| CopyBits `$483C`, BitMapRgn `$BF0C` | drain first |
| GetPixBaseAddr (`Lbe58` → `sub_BD94`), GetPixel/GetCPixel (`$B23E`/`$B34C`) | yes: a command, then spin on `sub_6E14` (no timeout) |
| UpdateGWorld `Lba64`, DisposeGWorld `Lbb14`, UnlockPixels `Lb9b4` | a command (`$19`/`$33`), i.e. `sub_624A` |
| LockPixels `Lb940`, NewGWorld `Lb9fc`, the cursor patches | no (only the cursor lock `*[+$0C]`) |
| DisposeScreenBuffer `Lbe74` | runs the original first, then tells the card (`$33`) |
| QDDone `Lbecc` (`$AB1D` selector `$13`) | one `sub_6E14` poll, only for NIL or the stream's port; any other port gets TRUE at once (`$BEE4`-`$BEFA`) |
| GetCTSeed `$8098`, DrawPicture and the port/colour state calls | `$26`: the last records may still be drawing |

Possible races, from the code (none observed on hardware): direct writes
through a saved `baseAddr` (screen, `gdPMap`, a GWorld) or after LockPixels
alone, which *develop* 3 warns about (p. 346); QDDone(port) answering TRUE
while an early-released StretchBits still draws into that port's pixels;
a `sub_624A` timeout (-1) after which the 68K draws while the card may
still run; DisposeScreenBuffer freeing memory before the card is told.

**The reply.** EngineDispatch returns 1 ("done": the 68K skips the call).
When the port is recording a picture, region or polygon, it returns 2
instead. Before that it restores `HiliteMode`, `pnLoc` and `pnLocHFrac`, so
the 68K original runs with drawing suppressed (`pnVis` = −1) and records the
call. That is the meaning of reply 2.

**Preparing a call (`$4B7E` onwards).**
* **Room.** EngineDispatch reserves `$90` bytes plus the size of any changed
  clip or visible region (each `(rgnSize + 5) & ~3`) plus the call's own
  data. If that does not fit, it flushes (reason `$10` or `$12`).
* **Per command:**
  * StdLine checks only the pen (`sub_8DA4`).
  * StdText runs the font work (`sub_88E6`, below).
  * StdRRect with a zero oval width or height is sent as StdRect (`$24`).
  * StdPoly and StdRgn reserve their record size, except that a StdRgn whose
    region has `rgnSize` = 10 is sent as StdRect (`$24`) with its `rgnBBox`
    (`$4D86`).
* **Mode and pattern** come from `sub_8E38(verb, &mode, &frame, &slot)`,
  QuickDraw's own verb table:

  | verb | mode | pattern slot |
  |---|---|---|
  | frame, paint | `pnMode \| 8` | 1, the pen pattern |
  | erase | patCopy (8) | 2, the background pattern |
  | invert | patXor (`$A`), with `black` (QuickDraw global −16) | 3 |
  | fill | patCopy | 3, the fill pattern |
  | text (5) | `txMode & ~8` | unchanged |

  If `HiliteMode` bit 7 is clear (a hilite is pending), patXor becomes `$3A`
  and srcXor becomes `$32`, and the bit is set again, as QuickDraw does.
  `frame` is −1 for the frame verb and 0 otherwise. It is the word at `+2`
  of the shape records. A change of mode against the cached one
  (`$CC(a4)`) emits `$69`, and the slot goes into `$73`.

##### The records

A record is a 2-byte opcode, a 2-byte word at `+2`, then the data, padded to
a multiple of 4. The host writes these layouts (the chain at `$555C`, and
the command names from the patch table in `QUICKDRAW_PATCHES.md`). The card
cases come from the two opcode tables in `.lit` (`$0484`, `$0498`) and the
compare chain.

| record | written for (command) | size: layout | card case |
|---|---|---|---|
| **1** line | StdLine (`$20`) | 8: `+4` the new point, which also becomes `pnLoc` | `$0BDB0`: draws from the pen with DrawLine, then moves the pen there |
| **2** arc | StdArc (`$23`) | 16: `+2` frame, `+4` rect, `+$C` startAngle, `+$E` arcAngle | `$0D9C4` (DrawArc; the case tests for opcode 2) |
| **3** oval | StdOval (`$2F`) | 12: frame, rect | `$0D9C4` (DrawArc) |
| **4** round rect | StdRRect (`$2E`) | 16: frame, rect, `+$C` ovalWidth, `+$E` ovalHeight | `$0D9C4` (DrawArc) |
| **5** rect | StdRect (`$24`) | 12: frame, rect | `$0C754` |
| **6** text | StdText (`$21`) | `(n + $13) & ~3`: `+2` count n, `+4` the space character's width (width table entry 32), `+8` `fixTxWid` (the unscaled width, Fixed), `+$0C` the width scaled by `numer.h/denom.h` (the pen advance), `+$10` the text | `$0E018`: writes `+4` into the cached width table's entry for the space (`+$80`), calls DrawText `$11AD8` per device, then advances the pen by `+$0C` |
| **7** poly | StdPoly (`$31`) | `(polySize + 7) & ~3`: frame, the Polygon | `$0C398` |
| **8** region | StdRgn (`$18`) | `(rgnSize + 7) & ~3`: frame, the Region | `$0D6E8` |
| `$64`, `$66` foreground colour | ForeColor, RGBForeColor, PmForeColor (`$36`) | `$64`, 12: `+2` the RGB colour (port `+$24`; for an old port `sub_917E(fgColor)`), `+8` `fgColor` (`+$50`). `$66`, 16, when the port's colour came from the Palette Manager (bit 2 of `$CE(a4)`): the same plus `+$C` grafVars `pmFgIndex` | `$0B230`, `$0B458` |
| `$6B`, `$6D` background colour | BackColor, PmBackColor (`$37`) | the same from `+$2A`/`+$54`; `$6D` adds `pmBkIndex` (bit 4 of `$CE(a4)`) | `$0B584` for `$6D`, `$0B340` for `$6B` (the twin of `$64`, storing to the background global) |
| `$67` font | StdText, when the font changed | 32: `+2` the 26-byte `FMOutput` (its `fontHandle` replaced by the strike actually used), `+$1C` `WidthTabHandle` | `$0DE00`: `+2` to `extern#1772+$60`, then looks up the width table (kind `$0A`) and the strikes (kind 8) in the cache |
| `$68` MoveTo | the pen location changed (`sub_8DA4`) | 8: `+2` `pnLocHFrac` (`$8000` for an old port), `+4` `pnLoc` | `$0BD7C` |
| `$69` mode | the transfer mode changed (`sub_8E38`) | 4: `+2` the mode | `$0B214`: the mode into `lr24` |
| `$6A` clip region | SetClip, ClipRect (`$32`) | `(rgnSize + 5) & ~3`: the Region at `+2` | `$0BBC4`, into `lr19` |
| `$6C` visible region | visRgn changed (`$10`, also from the port check at `$51A4`) | the same | `$0BBC4`, into `lr54` |
| `$6E` pen size | PenSize, SetPenState, PenNormal (`$35`) | 8: `+4` pnSize | `$0BD98` |
| `$6F` header | start of the stream | 4: `+2` flags, rewritten before each `$38` | `$0B228`: skipped |
| `$70` hilite/op colour | OpColor or HiliteColor changed (`sub_8DF2`) | 16: `+4` the hilite colour (`grafVars^.rgbHiliteColor`, or `HiliteRGB` `$DA0` for an old port), `+$0A` `rgbOpColor` | `$0BB7C`: the hilite colour to `extern#1772+$40`, the op colour to `+$38` |
| `$71` bit pattern | a pattern slot changed (`sub_8F04` result 1) | 12: `+2` slot, `+4` an 8-byte Pattern | `$0B6D8`: kind 0 |
| `$72` pixel pattern | `sub_8F04` result 2 or 4 | 8: `+2` slot, `+4` a long (a PixPat) | `$0B72C`: kind 1 |
| `$73` slot | the verb's pattern slot changed | 4: `+2` slot (1 pen, 2 background, 3 fill) | `$0B7D4`: skipped if the slot is current and no pattern changed; otherwise it makes the slot current (`lr20`) and fetches its pattern from the cache by kind (bit pattern kind 3, PixPat kind 5, RGB pattern kind 4) |
| `$74` RGB pattern | `sub_8F04` result 3 | 12: `+4` slot, `+6` an RGB colour | `$0B788`: kind 2, the "RGB Pattern" of the cache message |
| `$75` patAlign | `patAlign` changed (QuickDraw global −168) | 8: `+4` `patAlign` | `$0B7B8`: stored to `extern#1772+$48` |

The card handles 25 opcodes: 1-8 and `$64`-`$75` without `$65` (9 is
rejected like any other unknown opcode). The numbering does not follow PICT,
but the split into drawing records (1-8) and state records (`$64`-`$75`)
is the one a QuickDraw picture makes.

`dmo_decode.py DUMP` prints a stream from a raw dump of the buffer (for
example from an emulator's memory at `$AC(a4)`); `--selftest` builds one
record of every kind from this table and decodes it back.

After a StdText record the host advances its own pen by the measured width:
the integer part to `pnLoc.h`, the fraction to `pnLocHFrac`. It writes both
into the port, so the 68K's pen stays right although the 68K drew nothing.

##### The card side: the interpreter

**Prologue (`$0AD18`-`$0AEC4`).** It first runs a per-device set-up loop
over 44-byte device records (`lr111`, `lr76` up to `lr105`). For each
device it stores the record's `+$14` word (the pixel size) in a per-device
slot (`+$3C4`) and its log2, from the byte table at `.data+$2C8` (1, 2, 4,
8, 16, 32 → 0-5), in `+$3C0`. Then `$169A0` returns the current PQDAlloc
mark (`lr41`); the loop head resets the allocator to it (`$169BC(lr41)`)
before every record, and the drawing cases after every device, so a
case's buffers last one record. It clears:
* both region pointers (`lr54`, `lr19`);
* `lr20`;
* `lr27`, the "pattern changed" flag that the pattern records set;
* `lr28`, the chunk status;
* `lr50`, `lr70`-`lr72`, `lr75` and `lr32`-`lr34`;
* the strike pointers `extern#1772+$64` and `+$6C`.

The pen (`lr25`, `lr36`) and the pattern slots are **not** set, so a stream
has to begin with MoveTo and its patterns. The host does that, because its
cached state starts out empty.

**Loop head (`$0AEC8`).**
* **Before each record** it calls `$33304(record pointer)`. That adds 1 to
  packet `+$1C4` (the heartbeat the host watches; the wait loop also adds 1
  on every poll) and stores the pointer in packet `+$1C8`, so the host can
  see how far the card has got. If a record follows, it resets the
  PQDAlloc mark (`$169BC(lr41)`) and calls service `$D2` (Hand `$2001294`,
  which restarts the kernel when `gr64` bit 28 is set).
* **The stream** runs from `lr102` to `lr102 + [lr53]` (`lr102` is packet
  `+$1BC`, `[lr53]` starts as packet `+$1C0`). The opcode is read as a
  signed half at `lr38+0` (`$0AF90`).
* **At the end of the bytes**, if the last status was `$C9`, it leaves
  (`$0DF28`). If it was `$C8`, it first completes the pending `$38`
  (`$328C8`: clears packet `+$14`, writes the reply word `+$18`). Then it
  waits in `sub_33374`, the nested wait loop. That loop polls until the
  host's length word (packet `+$1C0`) has grown or a command arrives, and
  services only `$0C` (CachePixPat), `$26`, `$2A`, `$2C`, `$30` (the font
  upload) and `$38` (through `CommandDispatcher(6, …)`). It returns `$C8`
  after `$38`, `$C9` after `$26`, 0 when only the length grew, and −7 or
  −5 when the dispatcher returns `$17` or a command outside the list;
  DrawMultiObject leaves on a negative status and returns its negation.
  * The wait is timed: HIF service `$111` (clock, stub `$38FE8`) is called
    before and after it.
  * `$33238(t)` counts the waits (`.bss+$10`), adds up their time
    (`.bss+$0C`), and keeps the average in packet `+$1CC` and the maximum
    in `+$1D0`.
  * The prologue's call `$33238(-1)` resets these statistics.
* **After the wait** it re-reads `[lr53]` and sets the end to `lr102 +
  [lr53]` without resetting `lr38`. It goes on with the records the host
  appended. `$C8` means "more records" (a `$38` came); after `$C9` (the
  `$26`) it completes the command at once (`$32AB8(1)`), plays any records
  still unread and leaves at the next end of the bytes.

**Dispatch.** The opcode is in `lr81`. The loop head (`$0AF94`) sends
opcodes above 9 straight to `$0B204`. For the drawing opcodes (1-9) it
first checks the dirty flags (below), then also continues at `$0B204`:

| opcodes | dispatch |
|---|---|
| above `$69` | `$0B204` → `$0E2CC` |
| `$69` | `$0B204` → `$0B214` |
| 1-5 | table `.lit $0484` (`opcode − 1`); the delay slot (`$0E268`) sets the data pointer `gr96 = lr38 + 4` |
| 6 | compare chain (`$0E22C`-`$0E23C`) → `$0E018`; its delay slot sets the pointer to `lr38 + $0C` |
| 7, 8, `$64`, `$66`, `$67`, `$68` | compare chain: 7 → `$0C398`, 8 → `$0D6E8`, `$64` → `$0B230`, `$66` → `$0B458`, `$67` → `$0DE00`, `$68` → `$0BD7C` |
| `$6A`-`$75` | table `.lit $0498` (`opcode − $6A`) |
| anything else | `$0E20C`: reports "DrawMultiObject: unknown opCode %d" (`.lit $0430`) and leaves the stream |

**State is applied lazily.** The state records only store their values and
set a dirty flag:

| flag | set by |
|---|---|
| `lr71`, foreground | `$64`, `$66` |
| `lr70`, background | `$6B`, `$6D` |
| `lr72`, mode | `$69` |
| `lr75`, pattern | `$73` |

Before a drawing record, if any flag is set, the loop head runs a
per-device refresh (`$0AFC0`-`$0B1F0`) and clears them all (`$0B1F4`).

**The refresh.** For each device (`lr76` up to `lr105`):
1. it loads that device's values into the drawing-context globals,
   `extern#1772` `+$0C`, `+$10`, `+$14`, `+$18`, `+$20`, `+$24` and `+$74`.
   These are the same stores every drawing case makes before it draws;
2. it calls **`$06F1C`, ColorMap**(pixel size from slot `+$3C4`, mode
   `lr24`, …), which follows the 1990 `ColorMap` (`QDUtil.a` up to change `<20>`),
   without its alpha part (see "Open points"). It
   returns the mapped mode and leaves the replicated foreground and
   background longs in the per-device slots `+$3B8` and `+$3BC`:

   | `ColorMap` (68K) | `$06F1C` |
   |---|---|
   | split the mode into the pattern bit and the rest | `gr99 = mode & 8`, `lr17 = mode & ~8` (`lr17` mode, `lr16` depth) |
   | an arithmetic mode (bit 5) at 1 bit per pixel goes through `arithMode`, 8 bytes | the same test, and `mode & 7` indexes the 8-byte table at `.data+$2EC`: `00 03 02 01 01 03 02 01`, exactly `arithMode` |
   | old port or new (`portBits.rowBytes` sign) | tests `extern#1772+$3E` |
   | fore- and background RGB from the port | loads the RGBs at `extern#1772+$28` and `+$30`, and tests for black on white |
   | at depth ≤ 2, if fore- and background map to the same index although their RGBs differ, invert the foreground and map it again (`@goOnAndFlip`) | the same comparisons, then `$06B1C` (invert) and `$0688C` (colour → index, request 13) |
   | replicate the pixel through a long, by depth | a switch on `depth − 1` through `.lit+$128` |

   ColorMap's switch tables are `.lit+$128`, `$168` and `$1B8` (16
   entries each, indexed by depth − 1; their targets are the per-depth
   replication blocks) and `.lit+$1A8` (4 entries, by `mode & 3`).
3. it reduces the mapped mode to a **mode byte** in the per-device slot
   `+$B4`. When the mode is a pattern mode (bit 3), not arithmetic (bit 5
   clear), and the current pattern is a solid bit pattern (pattern kind
   `+$3A0` = 0 and the 8 bytes of its cache entry all ones, `lr42` = 0, or
   all zeros, `lr42` = 4), the byte is `.data+$3D8[(mode xor lr42) & 7]`,
   from `00 00 01 02 02 64 64 64`; otherwise it is −1. The values, as the
   column fill `$09578` uses them: 0 fills with the foreground long, 1
   inverts, 2 fills with the background long, `$64` leaves the
   destination unchanged. With an all-ones pattern, patCopy and patOr give
   0, patXor 1, patBic and notPatCopy 2, the other `not` modes `$64`; an
   all-zeros pattern shifts the index by 4, so patCopy gives 2 and patOr,
   patXor, patBic `$64`;
4. it sets the per-device draw flag (`+$1A4`) when the byte is not `$64`
   and the device's clipped rectangle is not empty (`+$1CC`, set by the
   region case).

So colours and mode are mapped per device once per change, not once per
drawing record. A stream that draws many shapes in one colour pays for the
mapping once.

Each case ends by advancing `lr38`, usually in the delay slot of its `jmp
$0B450` back to the loop. The sizes found that way match the host's layouts
for every case.

The two 6-entry tables `.lit $0454` and `$046C` are not opcode tables. They
are sub-switches on `lr94` (0-5) inside the rectangle case (`$0CD30`,
`$0CEE4`), right after `$1553C` and `$32C10`:

| `lr94` | `.lit $0454` | `.lit $046C` | routine called |
|---|---|---|---|
| 0, 1, 2, 4 | `$0CD58` | `$0CF10` | `$09430(row, …, lr94, …)` |
| 3 | `$0CD8C` | `$0CF44` | `$09578` |
| 5 | `$0CDB0` | `$0CF68` | `$09660` |

`$09578` fills a one-pixel-wide column:
* the x offset is `rect.left − bounds.left` and the row count is
  `rect.bottom − rect.top`;
* it stores one byte per row, stepping by `rowBytes`, unrolled by two;
* the mode byte selects the store: 1 inverts each byte (NOR), 0 stores the
  foreground long (`+$1C`), 2 the background long (`+$20`).

`$09660` does the same with long stores, and `$09430` with masked long
read-modify-writes (AND, ANDN, OR, XOR) and `lr94` as an argument. `lr94`
is the per-device slot `+$3C0`, `log2(pixel depth)` from the prologue:
* 3 is 8 bits, handled with bytes;
* 5 is 32 bits, handled with longs;
* 0, 1, 2 and 4 (1, 2, 4 and 16 bits) share the masked routine.

These draw the left and right edges of a one-pixel frame (see the
rectangle case below; DrawLine `$08618` calls the same three). The top and
bottom edges go through `$09020` and `$09270`, which mask the edge longs and
store whole longs between them, as BitBlt-style fill loops do.

**What each case calls** (every call between the case's entry and its jump
back to the loop):

| record | case | routines reached |
|---|---|---|
| 1 line | `$0BDB0` | DrawLine `$08618`, `$1553C`, ShieldCursor pair, IsOnThisCard `$13F54`, FillLongs `$1701C` |
| 2/3/4 arc, oval, round rect | `$0D9C4` | DrawArc `$075DC`, `$1553C`, ShieldCursor pair |
| 5 rect | `$0C754` | RSect, TrimRect, IsOnThisCard, FillLongs `$1701C`, FillLongsBurst `$00348`, FillLongsStorem `$37D68`, `$1553C`, ShieldCursor pair, the column fills `$09430`/`$09578`/`$09660`, the row fills `$09020`/`$09270`, `$17500`, BitBlt, RgnBlt |
| 6 text | `$0E018` | DrawText `$11AD8`, once per device |
| 7 poly | `$0C398` | `$1553C`, ShieldCursor pair, DrawLine, QuickPolys |
| 8 region | `$0D6E8` | RSect, TrimRect, `$1553C`, `$17500`, RgnBlt |
| `$64`, `$66`, `$6B`, `$6D` | `$0B230`, `$0B458`, `$0B340`, `$0B584` | `$0688C` (colour → index, CallBack request 13); `$66`/`$6D` also `$33D58` (CallBack request 17, `Entry2Index`) |
| `$67` | `$0DE00` | CacheFindStamp `$15E8C` (up to three lookups), `$15AE4` (releases the entries of the previous font) |
| `$6A`/`$6C` | `$0BBC4` | RSect, TrimRect |
| `$68`, `$69`, `$6E`, `$6F`, `$70`-`$72`, `$74`, `$75` | | none (`$70` uses `memcpy`): they only store state |
| `$73` | `$0B7D4` | the pattern cache: `$1610C` (find or create a kind-3 bit pattern), CacheFindStamp (kind 5), CacheFindOrCreate `$15FF4` (kind 4), `$15154`, `$1518C`, `$15AE4` |

`$1553C(rect, …)` stores the shield rectangle (`extern#1772+$78`-`+$7E`).
Each drawing case then either takes the ShieldCursor pair itself or
leaves it to BitBlt or RgnBlt, which call the pair; the cursor hand-off is
described in "The cursor". `$15AE4(kind, entry)` clears bit 31 of an
entry's first word and releases the entry when bit 30 is set; the exit
path (`$0DF28`, also reached from the cache errors at `$0DF18`) runs it for
the pattern, width-table and font entries the stream still holds.

**The rectangle case** (`$0C754`-`$0D6E4`), per device (`lr76`):
1. **Skip** the device if its draw flag (`+$1A4` slot) is clear.
2. **Choose the fast path** only if all of these hold:
   * the device is at 32 bits per pixel (per-device slot `+$3C0`, the log2
     of the pixel size, is 5);
   * neither the visible nor the clip region is non-rectangular (the
     per-device slots `+$17C` and `+$154` that the region case fills are 0);
   * the record's frame flag (`lr82`) is 0, so it is a paint, erase,
     invert or fill rather than a frame;
   * the per-device mode byte from the refresh (`+$B4` slot, the
     `.data+$3D8` lookup) is 0 or 2, a fill with the foreground (`+$3B8`)
     or background long (`+$3BC`).
3. **Fast path** (`$0C80C`-`$0CA50`):
   * clip the rectangle against the device's `minRect` (the `+$14` table
     the region case filled with RSect);
   * set the shield rectangle (`$1553C`) and take ShieldCursor;
   * fill row by row: if IsOnThisCard says the first address is on the
     card, with FillLongsBurst `$00348` when the end address (first row
     plus rows × `rowBytes`) has a bit of `$01200000` set and with FillLongs
     `$1701C` otherwise; off the
     card with FillLongsStorem `$37D68`. The helpers:
     * **`$13F54(addr)`**, IsOnThisCard, asks "is this address on this
       card?". It calls kernel service `$C4` (stub `$38F34`: `const gr121,
       $00C4` / `asneq trap66`), takes the result's top nibble `s`, and
       returns 1 when `addr` is `$s.......` or `$Fs......`, else 0. Those
       are the card's NuBus super-slot and standard-slot spaces, so `s` is
       the card's slot number. PrivNZ sends `$C4` to Hand's `$2001250`,
       which returns `gr96 = [$4C00682C]` (`PublicOu+$2C`), where Boot
       stores a value shifted left by 28. Pixmap base addresses arrive as
       host addresses, so this is how the card tells its own frame buffer
       from host or other-slot memory;
     * **`$1701C(dst, value, count)`**, FillLongs (`lr8`-`lr10`):
       * `count` < 8 goes to a small path (`$171D0`: 1-7 single stores
         through `.lit+$078C`);
       * `dst & 3` ≠ 0 goes straight to `$00348`;
       * otherwise it tests bit 31 of the absolute word `$44000080`
         (`consth $4400`, no relocation: a hardware status register that
         Hand also tests, see below);
       * bit 31 clear: call `$00348`;
       * bit 31 set: a **hardware block fill** (`$17078`-`$171CC`):
         1. align `dst` to 32 bytes with 1-7 single stores of the value
            (`dst>>2 & 7`, through `.lit+$0770`);
         2. store the value to two registers at `$4CC00000` and
            `$4CC00004`;
         3. set bit 22 of the destination (`gr99 = dst | $00400000`), an
            alias of the frame buffer;
         4. store `$FFFFFFFF` through two pointers 4 bytes apart (`gr99`,
            `gr98`), each stepping 32 bytes. Eight stores cover 32 longs, so
            each store fills 4 longs (16 bytes);
         5. handle the 1-3 remaining 32-byte blocks the same way (again
            stores of `$FFFFFFFF`), then clear bit 22 again (`and
            $FFBFFFFF`) and finish the tail with single stores.

         `$17264` (the two-value fill) loads the same two registers with
         *different* values, `a` to `+$00` and `b` to `+$04`. Its pointers are
         also 4 bytes apart. So register `+$00` serves the even longs of
         each 32-byte block and `+$04` the odd ones, and a single-value fill
         simply loads both with the same value. Nothing on the host side
         touches this range: the video driver and the INIT never address
         `$0CC00000` or a bit-22 alias.

         This is the shape of a VRAM block write: colour registers loaded
         once, then each store to the alias writes the colour into the
         bytes its mask enables. That explains why this path needs no
         `storem`: one store already does four longs.

       **What the bit means, from Hand.** The video command service
       (`$2000C14`) converts the 2 MB window at `$4C000000` between two
       layouts, `$1000` bytes at a time through a buffer at `$40003800`:
       * page configuration 1 reads the buffer with a 16-byte stride
         (offsets 0, 8, 4, `$C`) and writes the window linearly. So it turns
         the 4-way word-interleaved layout into the linear one. Afterwards
         it waits until `$4400007C` bit 31 is clear and then until
         `$44000080` bit 31 is set (`$2000F2C`-`$2000F48`);
       * page configuration 2 does the reverse (linear to interleaved) and
         then waits until `$4400007C` is set and `$44000080` is clear
         (`$2000E5C`-`$2000E78`).

       So `$44000080` bit 31 reads 1 while the frame buffer is in the
       linear layout and 0 while it is interleaved; `$4400007C` is its
       complement (both are written by the host, section 5). The kernel's display-start/row-bytes stub `$20012E8` also halves both of
       its values when the bit is set. For `$1701C` this means: the block
       write works only in the linear layout, and interleaved memory falls
       back to the `storem` burst. The host sets the layout (section 5):
       linear on every Apple monitor at every depth, and on TV output at
       24 bpp. So `$1701C` uses the block write almost everywhere, and
       `$00348` only for 1-8 bpp NTSC/PAL frame buffers.

       `$17264(dst, a, b, count)` (Fill2Longs, PQDInit's descriptor `+$30`)
       is the two-value version. With `a` = `b` it calls `$1701C`. Otherwise
       it tests bit 31 of `$4400007C` the same way, before its own aligned
       paths. The two fills gate on the same condition. FillLongs takes the block write
       when `$44000080` bit 31 is **set** (`$17040`-`$17048`); Fill2Longs takes it
       when `$4400007C` bit 31 is **clear** (`$172A0`-`$172AC`; set → the burst
       `$00294`). Both bits are written by the host (section 5), and in every mode
       the ROM's timing tables hold they are complements: `+$80` = 1 means the
       linear layout and `+$7C` = 1 the interleaved one. So both fills use the
       block write exactly in the linear layout. The second register is just the
       complementary flag, read from the other side; nothing about two colours
       depends on it. Boot reads `+$7C` the same way: its register probe
       (`$2003608`-`$2003634`, `$2003768`-`$2003774`) treats a set `+$7C` as the
       TV/interleaved case. The matching burst helpers are `$00294`, which loads two
       alternating values into the burst registers, and `$00248` (`+$54`),
       a copy that moves 29 longs per `loadm`/`storem` pair;
     * **`$00348(dst, value, count)`**, FillLongsBurst. It loads the value
       into 24 global registers (`gr96`-`gr119`) and writes them with
       `storem`, 96 bytes per instruction. The remainder goes through a
       computed jump (`$003D0`) into the unrolled register loads and one
       final `storem`. Nearly every blitter calls it for solid runs (18
       call sites);
     * **`$37D68(dst, value, count)`**, FillLongsStorem, a `storem` fill for
       any memory. Its calls are direct `call`s with R_IREL relocations
       (type 24; the file stores displacement 0 and the loader fills it in,
       see "Relocations name the targets"), all to kernel service stubs:
       1. `$C4` (`$38F34`): the card's slot nibble, as in `$13F54`, kept in
          `gr120`;
       2. `$D1` (`$390F4`): if the result's top nibble is 0, take the
          direct path. Otherwise `$BB` (`$38F44`): if its bit 9 (`$200`) is
          0, take the direct path too;
       3. it copies `value` into `gr96`-`gr111` (16 registers);
       4. `count` < 16 longs: the direct path;
       5. `dst` on this card: the direct path. That covers `$Fs......`,
          `$s.......`, and `$4.......` (the card's local view, which it
          first rewrites to `$s` plus the low 28 bits);
       6. otherwise (host or another slot) it saves state and sets it:
          `$B9(1)`, clears `CFG` bit 5, `$B8(0)`, `$BF(1)`, `$D3(0)`. If
          `$D3` returned non-zero, `$D4(dst, bytes)` translates `dst`; if
          the translation covers all the bytes, the result becomes the
          destination, otherwise it restores `$D3` and fills the
          untranslated address with plain `storem`s (`$38180`). A
          misaligned destination takes the same plain path. Otherwise it
          stores up to 64-byte alignment, writes 64 bytes per `storem`
          (`CR = $F`, control field `$43`) with `CPS` bit 9 (`LK`, `$200`)
          set around each one, stores the rest, and restores everything
          with the saved values (`$38114`-`$38138`);
       7. the direct path (`$381CC`) is the same 64-byte `storem` loop
          without the services, the lock or the control field.

       The services, from the PrivNZ table and Hand:

       | service | Hand | does |
       |---|---|---|
       | `$B9` | `$20018B8` | sets (1) or clears (0) `OPS` bit 4 (`SM`, supervisor mode); returns the old bit |
       | `$B8` | `$20018E4` | 0 stops the timer (`TMC` = `TMR` = 0); otherwise reloads `$7530` with `TMR` bit 24 (`IE`); returns the old `IE` |
       | `$BF` | `$2001924` | sets or clears `OPS` bit 1 (`DI`, interrupts off); returns the old bit |
       | `$D3` | `$2001820` | stores its argument at `$4C006848`; 0 sets `OPS` bit 6 (`PD`, data addresses untranslated), non-zero clears some TLB entries and `PD`; returns 1 if translation was on |
       | `$D4` | `$2001808` | translates an address through the range table at `$4C00316C` (below) |
       | `$D1` | `$2001A48` | `gr96 = [$4C006804]` (`PublicOu+$04`) |
       | `$BB` | `$2001A58` | `gr96 = gr64`, the feature flags the host wrote to `PublicIn+$18` |
       | `$D5` | `$2001260` | the slot mask (below) |

       So step 6 runs in supervisor mode with the timer and interrupts off
       and data translation off, and writes host memory at the physical
       address from `$D4`. The locked `storem` with control field `$43`
       (the address-space bit and option 3) is, as a *reading*, the cycle
       the card's bus logic turns into a NuBus block write; `$D3` is the
       service that brackets the host-memory mapping (1 on entry, 0 on
       release; see "Card: `MapVirtual` and host memory"). **`$D5`:**
       Hand's `$2001260` returns
       `[$4C00643C]` (`PublicIn+$3C`) when its argument is negative, and
       otherwise clears bit `lr2` of that word and mirrors the result to
       `$46000000`. `$37000` calls `$D5(-1)` to read the mask and
       `$D5(slot)` to drop a slot that failed. So the word is a per-slot
       "burst transfers work" mask, and bits 16-31 of `$46000000` are the
       hardware slot enable bits: vector 7 clears a slot's bit there directly
       after a fault with status bit 2 (`$20004A4`-`$200053C`), and the timer
       rewrites the master copy every 65536 ticks (`$20009CC`-`$20009E4`).
       Bits 0-4 are read as bus status and bits 12-15 as the board revision
       (section 10.4). The host's command `$14` (`$D5(p[0])`, sent from the
       InitGDevice patch) can drop a slot as well.

       `.data+$280`, read by every caller of the fills (`$03838`, `$03A28`,
       `$04110`, `$09020`, `$09270`, `$0E4CC`, `$0E804`, `$11460`-`$11918`,
       `$1C298`, `$1C8A8`), is a shared switch for the block write: those
       callers use FillLongs only when it is non-zero and the run is on the
       card with neither address bit of `$01200000` set at its end; other
       runs go to FillLongsStorem (in the row fills `$09020`/`$09270`, runs
       on the card go to single stores). PQDInit stores its *address* in the descriptor it
       builds for modules (`$16748`), so code outside Antelope can change
       it. Its initial value is 1. The pattern fills
       have no const references, but direct calls within their file reach
       them: `$04110` from BitBlt (`$02B3C`), `$1C8A8` from RgnBlt (`$1B090`),
       `$0E804` from `$1114C`. So they are BitBlt's and RgnBlt's own
       pattern paths. `$BB` returns `gr64`, the feature flags the host
       wrote to `PublicIn+$18`. In those flags, `$200` is set by
       `SetFeatureFlags` (`DRVR.s` `$2AD2`) when the unit's config word
       `+$128` has bit `$40`. The config word comes from Control call 17
       (cs50 is the same plus `$100`, "mailbox allowed"). Whether the host
       sets `$200` is described in section 8: it does, by default. So the
       host-memory `storem` path is **on by default**, provided the top
       nibble of `PublicOu+$04` (`$D1`) is not 0.

       **`$D4` and `gr122`.** Hand's `$2001808` passes the address (`lr2`)
       and a byte count (`gr96`) to the range lookup `$2001C2C`, which
       searches the table at `$4C00316C` (12-byte entries: base, length,
       target) and returns the target address plus the offset, with the
       count cut to the bytes left in that range (0 when no range holds
       the address, which then stays as it was). `$D4` returns the address
       in `gr96` and the count in `gr122`. Antelope has two `$D4` stubs:
       `$39064` takes the count in `lr3` (`gr96 = lr3` before the trap) and
       replaces `lr3` by `gr122` when that is non-zero; `$39050` takes a
       pointer to the count in `lr3`, reads it before the trap and writes
       `gr122` back. (`$2001774`, a similar 1 KB-aligned lookup in the
       table at `$4C003168`, is service `$CE`.)
       The same service sequence appears in three more entry points (the
       others with services are shared restore tails: `$38574`, `$385C8`,
       `$38C3C`). Together they are one family:

       | entry | role | callers |
       |---|---|---|
       | `$37C10` | pattern fill: a 1-, 2-, 4-, 8- or 16-long pattern (`lr19` = period) loaded into `gr96`-`gr111`, then `$37D68`'s body (`$37DF0`) | `$04110`, `$0E804` (3), `$1C8A8` |
       | `$37D68` | fill with one long | the row fills `$09020`/`$09270`, DrawMultiObject, `$11460`-`$11918` (text), `$03838`, `$03A28`, `$0E4CC`, `$1C298` |
       | `$37000` (not in the family) | **burst self-test of a slot** (`addr`): takes the slot nibble, reads the slot mask with `$D5(-1)` and returns `$100` if the slot's bit is clear. It then reserves `$200` bytes on the memory stack and checks `CopyLongsStorem` against single loads and stores: burst-read 64 and 60 longs, invert the target with single stores, and burst-write it back. On any mismatch it restores the memory, calls `$D5(slot)` to clear the slot's bit, and returns -1 | CacheGDevice `$14F64` (once per device, between `$D3` calls) |
       | `$16C48` (not in the family) | CopyHostMemory, the copy helper behind CallBack requests 8 and 18 | uses `$38218` twice |
       | `$38218` | CopyLongsStorem, forward copy (`dst`, `src`, `count`): `loadm`/`storem` 64 bytes at a time; calls `$D4` for both pointers | ShieldCursor `$32C10` and `$32EF8` (saving and restoring the pixels under the cursor), `$02DE0`, `$16C48` (2), `$1B61C`, `$37000` (4) |
       | `$388D0` | CopyLongsBackStorem, backward copy: the same with both pointers counting down, for overlapping moves | none: no relocation in Antelope points to it |

       All four rewrite a `$4.......` card address to the slot form and
       take the kernel-service path only for memory off the card;
   * release the cursor (`$32EF8`).
4. **General path** (`$0CA64`-`$0D6C8`): RSect (`$01494`), then TrimRect
   (`$01654`) for each non-rectangular region, then one of three ways:
   * **a one-pixel frame** (`$0CC94`-`$0D05C`): frame flag set, pen
     1×1, both regions rectangular and a mode byte of 0-2. It sets the
     shield rectangle, takes ShieldCursor (`$0CCA0`), and then twice runs a
     per-depth column switch (`$0CD30`, `$0CEE4`, above) and a row fill
     (`$09270`, `$09020`): the left and right edge, the top and bottom
     edge. It releases the cursor at `$0D050`;
   * **any other frame** (`$0D064`-`$0D54C`): the four edges one by one,
     each with `$17500` and then BitBlt, or RgnBlt when a region is not
     rectangular; shield rectangle and ShieldCursor as above;
   * **a filled rectangle**, or a frame whose pen covers the whole
     rectangle (`$0D550`-`$0D6C4`): shield rectangle, `$17500`, then one
     BitBlt (both regions rectangular) or RgnBlt with the visible and
     clip regions. BitBlt and RgnBlt take the cursor themselves.

**The polygon case** (`$0C398`) reads the Polygon in place:

```
gr98 = half[lr38+4]                  polySize
lr93 = (polySize - 10) / 4           number of points (size word + bbox + 4 bytes per point)
lr82 = half[lr38+2]                  the frame flag
lr92 = lr38 + $0E                    the first point (after polySize and polyBBox)
lr38 += (polySize + 7) & ~3          skip the record
if lr93 == 0: next record
```

It frames through DrawLine and fills through QuickPolys, as `FramePoly` and
the filled verbs do in QuickDraw. That case names `$08618` DrawLine and
`$19270` QuickPolys; `$075DC` is DrawArc by its calls to SlopeFromAngle and
FixMul, as in `DrawArc.a`.

**The region case and the clipping set-up.** Once both region pointers are
set, the `$6A`/`$6C` case (`$0BBFC` onwards) loops over the devices and runs
the clipping that `DrawArc.a` and `DrawLine.a` begin with:

```
68K DrawArc.a                                  card, $0BC28-$0BD20
RSect(dstRect, bounds, clipRgn^^.rgnBBox,      $01494(minRect, 3, device bounds,
      visRgn^^.rgnBBox; n = 4) -> minRect             lr19+2, lr54+2)
if region is not rectangular:                  for lr54, then lr19:
   TrimRect(rgn, minRect, trim = true)            store it in a per-device slot
                                                  if rgnSize != 10: $01654(rgn, minRect, 1)
quit if the intersection is empty              an empty result clears lr11
```

`rgnSize = 10` is a rectangular region, and `+2` in a Region is `rgnBBox`.
The per-device slot (`+$17C` for `lr54`, `+$154` for `lr19`) keeps the
region only when it is not rectangular. `lr11` goes to the per-device slot
`+$1CC`, and the draw flag `+$1A4` is set from it and the mode byte, as in
the refresh. That names two helpers every drawing routine calls:
* `$01494` is **RSect**: DrawArc, DrawLine, QuickPolys and DrawText call it
  once each, StretchBits four times;
* `$01654` is **TrimRect**: DrawArc, DrawLine, QuickPolys and DrawText call
  it twice, once per region, StretchBits three times.

##### Text and fonts

**On the host (`sub_88E6`).** For StdText the host does the font work and
sends the card only what it lacks:
1. **Measure.** It calls `_StdTxMeas(count, text, numer, denom, info)`. The
   QuickDraw global `fixTxWid` (−172) gives the Fixed width, and `FixScale`
   scales it by `numer.h/denom.h` when they differ.
2. **Leave TrueType to the 68K.** If the width table (`WidthTabHandle`,
   `$B2A`) has `WidthIsSpline` set (`+$436`), it returns −1.
3. **Find what is new**, as bits in a mask:

   | bit | meaning | arguments added |
   |---|---|---|
   | 0 | the width table is new | `WidthTabHandle` and its pointer |
   | 1 | the font strike (`WidTabFont`, `+$400`) is not yet on the card | handle, pointer, size (`sub_BFDE`) |
   | 2 | `FMOutput`'s strike differs from it and is not on the card | handle, pointer, size |
   | 3 | a script font (`WidthAFID` ≥ `$4000`) and the text has bytes `$84`-`$9E` | the strike's handle and pointer |
   | 4 | the same for the `FMOutput` strike | its handle and pointer |

   A width table is recognised by an id (`sub_7E8C`) that the host writes
   into its `WidthHint` field (`+$432`, which `fontPrivate.a` marks
   "unimplemented"). A strike counts as uploaded once bit `$800` of its
   first word is set.
4. **Upload.** If the current stream still uses the old font, it flushes it
   first (`$38`). Then it sends `$30` with (mask, arguments). On success the
   strikes get bit `$800`. On failure the `WidthHint` is restored and the
   call goes to the 68K (reason 5).
5. **Remember** the width table (`$106(a4)` the handle, `$1AC(a4)` a copy of
   its first `$434` bytes) and the `FMOutput` (`$192(a4)`). The next StdText
   in the same font then sends nothing new and no `$67`.

**On the card: the upload handlers.** The `$30` case (`$322D4`) takes the
mask's bits in turn:
* bit 0 → **`$14B64(handle, ptr)`**: find-or-create a kind-`$0A` cache
  entry, copy the width table's `$434` bytes into it with `$16C48` (the
  copy helper behind requests 8/18), and return the entry's data;
* bits 1 and 2 → **`$14A80(handle, ptr, size)`**, bits 3 and 4 → `$14A80(handle, ptr, 0)` (a successful bit 1 skips bit 3, a successful bit 2 skips bit 4, `$32350`, `$323C0`):
  * find-or-create a kind-8 entry;
  * if the entry is new or holds another handle, copy the whole `FontRec`
    in (`$16C48`, mode 3; the card pointer goes to entry `+$10`);
  * convert it with **`$14564(entry, new, hostFont)`** (below): in full
    after a fresh copy, only glyphs `$84`-`$9E` when the same handle comes
    again;
  * on success store the handle as the key (`+$0C`) and return the entry;
    if the copy or the conversion fails, clear the top bit of the entry's
    first word and release it (`$15B3C(8, entry)` unlinks it and calls
    the kind's destructor from its descriptor, `+$14`).

So the card's three `opSwapFont` messages are about this upload. The `$67`
case (`$0DE00`) looks up, in what `$30` delivered:
* the record's `WidthTabHandle` (kind `$0A`), whose data goes to
  `extern#1772+$68`, else "width table is not in the cache";
* the width table's `WidTabFont` strike (kind 8, `extern#1772+$6C`), else
  "width font is not in cache";
* the `FMOutput`'s `fontHandle` strike (kind 8, `extern#1772+$64`; the same
  entry when the two handles agree), else "font is not cache".

Each error is reported and ends the stream.

**The cache of host objects.** One cache serves fonts, GDevices and more,
organised per kind and keyed by the host handle:
* `extern#1745` is an array of 24-byte descriptors, one per kind: `+$08`
  heads a linked list, `+$0C` gives the entry size, and `+$10` the data
  size in longs.
* Each entry is: `+$00` a time stamp, `+$04`/`+$08` prev/next, `+$0C` the
  host handle (the key), `+$10` the data.
* **`$15D28(kind, key)` finds** an entry by walking the list.
* **`$15E8C`** finds and stamps a hit with the clock (HIF service `$111`)
  for LRU replacement.
* **`$15EE4` creates** an entry:
  1. `$15A7C` (CacheLock) takes the cache's two-flag spin lock;
  2. `$15958` (CacheAlloc) allocates the entry, evicting the least recently
     used one (`$15CB0`, CacheFindLRU) when there is no room;
  3. it stamps the entry, zeroes its data, sets the key and links it at the
     head;
  4. `$15ACC` (CacheUnlock) releases the lock.
* **`$15FF4(kind, key)`** is find-or-create.

The kinds:

| kind | holds |
|---|---|
| 0 | colour table (CacheColorTable `$14BD4`; FlushColorTable, command `$1A`) |
| 1 | inverse table (CacheITable `$14D78`; FlushITable, command `$1B`) |
| 2 | GDevice (CacheGDevice `$14F64`; the cursor code looks up `CrsrDevice` with `$15D28(2, …)`) |
| 3 | bit pattern (record `$73`, created by `$1610C`) |
| 4 | RGB pattern (record `$73`, keyed by the 24-bit colour) |
| 5 | PixPat (CachePixPat, command `$0C`) |
| 6 | offscreen (CacheOffscreen `$1437C`; commands `$0D`/`$0F`) |
| 7 | a host block copied in whole (CacheHostCopy `$142C4`, `CopyHostMemory` mode 3; referenced only from BitsToPixMap, `$06D60`) |
| 8 | font strike |
| `$0A` | width table |

**On the card: drawing the text.** `$11AD8`, called from the text case, is a
7 KB routine with the shape of QuickDraw's `DrawText.a`:
* the clipping set-up (RSect, TrimRect twice) and the ShieldCursor pair;
* one buffer from PQDAlloc `$16A04` at the font's depth, and a second,
  1-bit one when `lr58` is set (`$12198`-`$12258`). Each is cleared, with a
  leading zero long. The left edge is rounded down to 32 pixels, and the
  width is counted in longs plus 2. `lr58` is `DrawText.a`'s `maskFont`
  (`$11BD8`-`$11C3C`): a colour font (`fontType & $0200`) turns srcOr into
  mode `$40` (srcCopy + mask), as `DrawText.a` does; with mode bit 6 set,
  a strike deeper than 1 bit and the width table's strike
  (`extern#1772+$6C`) cached, that strike's cells (`+$14`, row bytes
  `+$40`) become the mask (`lr57`, `lr56`). A 1-bit strike clears bit 6
  instead;
* the destination row is `baseAddr + (v − bounds.top) × rowBytes`, from a
  bitmap record whose `rowBytes` is a long (`lr73`: `+0` base, `+4` rowBytes,
  `+8`/`+$A` bounds top/left);
* the transfer goes through StretchBits `$2D7B8` (twice), scaleBlt `$22A8C`
  and RgnBlt `$19DA4`, as `DrawText.a` hands its buffer to StretchBits;
* modes are tested against 2 and `$32` (srcXor and the hilite srcXor).

The style comes from the `FMOutput` of the `$67` record. One pointer
(`lr60`) is read at exactly its field offsets:

| offset | field |
|---|---|
| `+6` | `boldPixels` (byte) |
| `+7` | `italicPixels` (byte) |
| `+$A` | `ulThick` (byte) |
| `+$B` | `shadowPixels` (byte, twice) |
| `+$C` | `extra` (signed byte) |
| `+$11` | `curStyle` |
| `+$12`/`+$14` | `numer` |
| `+$16` | `denom` |

So bold, italic, underline, shadow and scaling are applied on the card.

**The glyph loop** (`$122F4`-`$123A8`). Its
inputs come from three pointers in the drawing globals:
* `lr60 = [extern#1772+$60]`, the `FMOutput` (above);
* `lr46 = [extern#1772+$68]`, the width table (256 Fixed entries indexed
  by character code). `lr70` is its entry for the space (`+$80`,
  `$1228C`), which the text case has just overwritten with the record's
  `+4`;
* `lr41 = [extern#1772+$64]`, the card's record for the cached strike. This
  is not `FontRec` but the card's own layout, with longs where `FontRec`
  has words:

| `lr41` offset | register | use in the loop |
|---|---|---|
| `+$18` | `lr50` | a long per glyph (read into `gr109`): the byte offset of its cell in the glyph buffer (`+$14`) |
| `+$1C` | `lr9` | a halfword per glyph that must be > 0 (else the glyph is skipped): its image width in pixels, from `locTable`; left + width gives the right edge |
| `+$20`, `+$24` | `lr7`, `lr40` | log2 of the font's pixel depth, and `fontType & $0200` (set-up only; `1 << lr7` is formed) |
| `+$28` | `lr49` | `firstChar` |
| `+$2C` | `lr5 = lastChar - firstChar` | |
| `+$44` | `lr44` | the offset/width table (`owTable`, a halfword per glyph, `$FFFF` = missing) |
| `+$48` | `lr48` | optional (0 = none): a halfword per glyph into `lr59`, as `FontRec`'s optional height table (first row, row count) |

Per character (`lr67` walks the text, `lr4` is the pen, Fixed):

```
ch = byte[lr67++]
if ch == ' ':  pen += lr70; next              the space is never drawn
w  = long[lr46 + 4*ch] + lr55                 width-table entry by character code, plus extra
c  = (ch - firstChar) & $FF
ow = c > lastChar-firstChar ? $FFFF : half[lr44 + 2c]
if ow == $FFFF:                               missing: the glyph after lastChar
    c = (lastChar-firstChar+1) & $FF; ow = half[lr44 + 2c]
    if ow == $FFFF: skip ($12C64)
left = (ow >> 8) + (pen >> 16)                the high byte is the kern offset
pen += w
loc   = long[lr50 + 4c]
width = half[lr9 + 2c];  if width <= 0: skip
right = left + width
if lr48: height = half[lr48 + 2c]
```

After the glyphs are built (and made bold, `$12CB8`, repeating
`x | x>>1 | carry` boldPixels (`lr60+6`) times, and italic, `$12CF8`, gated by
italicPixels `lr60+7`), `$12DC8`-`$12EB8` draws the underline, as
`CHECKUL`/`UL1`/`UL2` in `DrawText.a`, instruction for instruction. It runs only
when `ulThick` (`lr60+$0A`, the FMOutput copy) is non-zero and `descent`
(`lr41+$3C`) is at least 2. It ORs the baseline row (`ascent`·rowBytes into
the buffer) with the next one or two rows (two only when `descent` = 2) into
a one-row temp (PQDAlloc), smears that right by one pixel (`x | x>>1 |
carry`), then, right to left, smears left and ORs the complement into
baseline+1: `row |= ~(t | t<<1 | carry)`. The underline is drawn everywhere
except one pixel around descenders.

The width table is indexed by the character code (as QuickDraw's is),
`lr48` is the optional height table, and the space has a fast path. The
roles of the `+$18`/`+$1C` tables, first inferred from their use, are
confirmed by the conversion that builds them.

**The strike conversion** (`$14564(entry, new, hostFont)`,
ConvertFontStrike). It turns the uploaded `FontRec` (card copy at entry `+$10`)
into a per-glyph cache, so DrawText never extracts bits from the strike:

| entry offset | set to |
|---|---|
| `+$14` | glyph buffer: one cell per glyph with an image |
| `+$18` | cell offsets: a long per glyph (`n+1` of them, the last the end) |
| `+$1C` | image widths: a halfword per glyph, `locTable[i+1] - locTable[i]` |
| `+$20` | `(fontType >> 2) & 7`, log2 of the pixel depth |
| `+$24` | `fontType & $0200` (the font has colours other than black) |
| `+$28`/`+$2C` | `firstChar`/`lastChar` |
| `+$30` | `kernMax` |
| `+$34` | `fRectHeight` |
| `+$38`/`+$3C` | `ascent`/`descent` |
| `+$40` | cell row bytes: `((widMax << depth) + 31) >> 5` longs, times 4 |
| `+$44` | `owTable` (in the card copy): `+$10 + 2 * owTLoc`, with `nDescent` as the high word of `owTLoc` when it is > 0 |
| `+$48` | height table, if `fontType` bit 0: after `owTable`, and after the glyph-width table too if bit 1; else 0 |

with `n = lastChar - firstChar + 2` glyphs (the missing glyph included),
strike row bytes `rowWords << (depth + 1)` and `locTable` after the bit
image (`bitImage + fRectHeight * rowBytes`).

```
if new:                                       free the old buffers (`$376A0`), then
    buf  = alloc(fRectHeight * cellRow * n)   `$15958`, may evict cache entries
    offs = alloc(4 * (n+1));  wids = alloc(2 * (n+1))
    first = 0                                 any failure returns 0
else:                                         the same font handle again
    if lastChar < $9E or firstChar > $84: return 1
    first = $84 - firstChar;  n = $9E - firstChar + 1
    re-fetch those glyphs' columns of the bit image from the host
        (`$16C48` mode 2, one call per row)
    skip the cells of the glyphs before `first`
for i in first .. n-1:
    offs[i] = cell - buf
    if owTable[i] == $FFFF: next              missing glyph: no cell
    x = locTable[i];  w = locTable[i+1] - x;  wids[i] = w
    if w <= 0: next
    for each of the fRectHeight rows:         left-align the glyph:
        copy the longs holding bits x<<depth .. (x+w)<<depth,
        shifted left by (x<<depth) & 31 (a funnel shift of two longs;
        a glyph within one long takes a single shift)
        into the cell row; cell += cellRow
offs[n] = cell - buf;  return 1
```

The bits right of the glyph come along unmasked (they belong to the next
glyph in the strike), so the clipping to `width` happens in DrawText. 

**The `$84`-`$9E` refresh is a deliberate protocol between host and card,
not a bug.** It belongs to mask bits 3 and 4 of `$30`:
* **Host (`sub_88E6`).** It sets bit 3 only when the width table's
  `WidthAFID` (`+$41C`) is ≥ `$4000`, a non-Roman script font, and a byte
  of the text lies in `$84`-`$9E` (`$8A24`-`$8A4A`). It sets bit 4 only when
  bit 3 is set and the `FMOutput` strike is already on the card (bit `$800`
  set and found, `$8B70`-`$8B9E`). For bits 3 and 4 it sends only (handle,
  pointer) (`$8C4A`..), and only if bit 1 or bit 2 respectively is not
  being sent.
* **Card (`$322D4`).** The `$30` case mirrors this. A successful bit 1 skips
  bit 3 (`$32350` → `$32394`), and a successful bit 2 skips bit 4
  (`$323C0` → `$3287C`). Bits 3 and 4 call `UploadFontStrike(handle, ptr,
  0)` (`$32384`, `$323F0`). Their handle matches the cache entry's key, so
  `new` is 0 (`$14AB8`-`$14AC8`) and nothing is copied in full.
* **The `new = 0` path** (`$147BC`-`$1488C`):
  * it returns at once unless the font covers the whole range
    (`lastChar` ≥ `$9E` and `firstChar` ≤ `$84`, `$147D0`-`$147E4`);
  * for each of the `fRectHeight` rows it re-reads, from the host's
    strike (`hostFont + $1A`), just the bit-image columns from
    `locTable[$84]` to `locTable[$9F]` into the card copy
    (`CopyHostMemory` mode 2, `$14870`);
  * it then rebuilds the cells of those glyphs in place. It skips the
    cells before `$84` by adding up their sizes (`$14898`-`$148E8`).
  * `locTable`, `owTable` and the cell sizes are **not** re-read: the
    card's copies stay.

So the protocol assumes that in a script font, the glyph *images* of
`$84`-`$9E` can change in host memory while the strike handle and all
metrics stay the same. Something on the host rewrites those glyphs in
place, and the card keeps up by re-reading them whenever text uses them.
Which script system does this (and why this range, rather than for
example the Shift-JIS lead bytes `$81`-`$9F`) is in neither code and not
in the 7.1 sources (`FontMgr.a`, `Text.a`, `DrawText.a` have no such
range). That part remains a reading.

##### Open points

* **ColorMap has no alpha-channel part.** In the 7.1 source the alpha block
  sits between the mode adjustment and the colour defaults ("`<17>`
  Beginning/End of alpha channel changes"). In `QDciPatchROM.a`, the System
  7.x patch, the block uses `_StreamToMask` on grafVars `foreStream`
  (`+$20`) and `backStream` (`+$26`). In `QDUtil.a` (`<SM4>`, 1993) it uses
  `_GetForeAlphaMask`/`_GetBackAlphaMask` instead. Either way it reads
  grafVars `streamMode` (`+$2D`) once `PmNewGVBit` is set, at 16 or 32 bits
  per pixel, and leaves `alphaMode`, `alphaMask`, `alphaFore` and
  `alphaBack` in the stack frame. `$06F1C`-`$075C8` has nothing of this:
  * no grafVars access;
  * no service or CallBack call except Color2Index `$0688C`, InvertColor
    `$06B1C`, the pattern lookup `$16034` and `memcpy`;
  * its only globals are `extern#1772` `+$0C`, `$14`, `$18`, `$20`, `$24`,
    `$28`, `$2E`, `$30`, `$38`, `$3E` and `$40`.

  It goes straight from the `arithMode` step (`$06F4C`-`$06F78`) to the
  xor test (`$06F7C`). No stream record carries a stream or ratio either
  (see the record table), and no read of grafVars `+$2D` turns up in
  `gc24.s`. So ports that draw with alpha streams are drawn on the card as
  if `streamMode` were 0 (*reading*: the host does not seem to filter them).
  The card's version is the System 7.0-era `ColorMap` without the alpha
  block.
* Other differences from `QDUtil.a`, all exact:

  | `ColorMap` (68K) | `$06F1C` |
  |---|---|
  | srcXor becomes `$32` when `HiliteMode` bit 7 is clear | not done here: the host already sends `$32`/`$3A` (`sub_8E38`) |
  | `<14>`: with `multColor` set and a direct destination, the default colours are inverted (removed again by `<R21>`, 6/1992) | `$06FAC`-`$06FD0`: if the word at `+$24` of the fourth argument is non-zero and depth ≥ 16, then fg long = 0 and bk long = −1 (*reading*: that word is `multColor`) |
  | old port: `mapToColor` turns the planar `fgColor`/`bkColor` into indices | `$07160`-`$071BC`: Color2Index of the RGBs at `+$28`/`+$30`, which the host has already converted (`sub_917E`, record `$64`) |
  | `colrBit` negative → COLOROK | not tested: every non-zero `colrBit` (`+$2E`) takes the planar path at `$07294` (`1 << colrBit`, switch on `mode & 3`, `.lit+$1A8`) |
  | — | an extra result: a black-on-white flag stored at `+$2C` of the second argument (`$075B0`). It is 1 when the RGBs are 0/0/0 on `$FFxx` × 3 (`$07048`-`$07074`), or, for an old port, when `fgColor` = 33 and `bkColor` = 30 (`$07180`-`$07198`) |
* **`$17500`** is PatExpand (`Patterns.a`), called before every BitBlt and
  RgnBlt of the rectangle and region cases (and by DrawArc, DrawLine and
  QuickPolys). Its bit-pattern path `$178B8` tests patStretch -2/2 and
  indexes PatExTbl by dstShift (`.lit $07E0`); pixel patterns go through
  PatConvert `$17C60` (MakeScaleTbl `$18278`, PatDither `$188C4`).
* **The bits `$01200000` mark card DRAM.** The card's memory, at offset
  `$0C000000` of its super-slot space (`$sC......` from the host,
  `$4C......` locally):

  | offset | what | evidence |
  |---|---|---|
  | `$0C000000`-`$0C1FFFFF` | the 2 MB VRAM. The frame buffer starts at `+$10000` (`+$11400` on TV). The kernel's `Vec`, `PrivNZ`, `PublicIn`/`PublicOu`, `HifComm` and `VidComm` lie in the first `$10000`, below the frame buffer | `VideoDriver.s` `$5C3A`-`$5C5A` and `$5E74`-`$5E7E` (base = hardBase + `$0C000000` + `$10000`/`$11400`); Hand's layout conversion covers exactly this 2 MB (`$2000C14`) |
  | bit 22 (`$0C400000`..) | the VRAM's block-write alias | `$1701C`/`$17264` set bit 22 of the destination (`$17394`) and clear it again |
  | `$0CC00000`/`$0CC00004` | the block-write colour registers | `$170F0`, `$17378` |
  | bit 21: `$0C200000`-`$0C3FFFFF` | DRAM, in two 1 MB windows: the two optional SIMM sockets, empty on a stock card (Apple's kit: 2 × 1 MB; product sheet `AppleMAC-DisplayCard-8.24gc.pdf` p. 2/4) | `DRVR.s` ProbeCard `$22EA`-`$2332` (`TestRAMLong` at `$0C200000`/`$0C300000`) |
  | bit 24: `$0D000000`.. | the second DRAM bank | ProbeCard `$2336`-`$2390` (`AliasCheck` against `$0D100000`/`$0D400000`/`$0D500000`); flag bit 20 "DRAM above `$0D000000`" |

  Every caller has just checked that the address is on this card
  (IsOnThisCard, `$s.......` or `$Fs......`). So `(end & $01200000) ≠ 0`
  means the run reaches DRAM rather than VRAM. There the VRAM block write
  does not exist, so the run takes the `storem` burst (rectangle case,
  `$0C98C`-`$0C9AC`), or `FillLongsStorem`/single stores (the other 14
  callers, for example `$03880`-`$03894` and `$09194`-`$091A8`). Testing
  the end alone is enough because VRAM lies below DRAM: an end below
  `$xC200000` puts the whole run in VRAM. Bit 22 is not in the mask,
  because addresses with it set are the VRAM's own alias. So in practice
  the test sends fills of off-screen pixmaps in card DRAM to `storem`, and
  frame-buffer fills to the block write.
  * The rectangle case tests `first + rows × rowBytes`, the address after
    the last row (`$0C98C`-`$0C994`). So a run whose last row ends exactly
    at `$xC200000` would also take `storem`, which is harmless.
  * Uncertain: for a standard-slot address (`$Fs......`, which IsOnThisCard
    accepts), bit 24 is the low bit of the slot nibble. So in slots `$9`,
    `$B` and `$D` such a run always takes `storem`. This matters only if
    QuickDraw hands the card `$Fs` base addresses, which the video driver
    does on its `sRsrc32Bit` path (`$5E8C`-`$5EAA`). What the standard slot
    space decodes to is not read.
* **Who rewrites glyphs `$84`-`$9E`.** `WidthAFID` (`+$41C`) is the width
  table's actual font family ID (`ToolUtils.a`: `widthAFID EQU 1052`). The host's
  signed `≥ $4000` test selects every non-Roman script family ($4000-$7FFF,
  script = (ID−$4000)/$200+1, Script Manager `CommonMapping`), not only one script
  (`$8A28`). Its byte scan (`$8A34`-`$8A58`) does not parse 2-byte characters: a
  lead or a trail byte in `$84`-`$9E` sets mask bit 3 alike. The card's side
  (`ConvertFontStrike`, `new` = 0, `$147BC`-`$148EC`) returns at once unless the
  strike spans `$84`-`$9E` (`$147D0`-`$147E4`) and re-fetches only those
  bit-image columns (`CopyHostMemory` mode 2, `$14870`); metrics, `locTable` and
  `owTable` are not re-read.
  The 7.1 sources have no code that rewrites a strike's bit image. Their only 2-byte
  text path is the later TrueType one. Of the Mac encodings, only MacJapanese leaves
  `$84`-`$9E` without 1-byte characters (they are Shift-JIS lead bytes). In MacThai
  they are positional tone/vowel forms, and in MacArabic/MacHebrew accented Latin
  letters. All of those are fixed glyphs, picked by code substitution. The likely
  reading is that KanjiTalk 6 draws 2-byte bitmap characters by copying their images
  into 27 fixed-width scratch slots `$84`-`$9E` of the Japanese strike and drawing
  the slot codes through StdText. The card's re-read of just those columns, with
  the metrics kept, fits that, and so does Tech Q&A TX10: 2-byte bitmap fonts were
  kept in a separate `'fbit'` format, not `NFNT`, so their images had to be put
  somewhere StdText could draw them. `$84`-`$9E` is a strict subset of the
  Shift-JIS lead bytes (`$81`-`$9F`, `$E0`-`$FC`; `DoubleByteSupport.a`
  `sjisHighBytes`); why `$81`-`$83` and `$9F` are left out is not known. This is
  not confirmed (about 60%; another CJK script kit is possible): no KanjiTalk
  code or font is on hand, and the local Tech Info Library notes on KanjiTalk and
  on the 8•24 GC say nothing about drawing.
   (Test: dump a KanjiTalk 6 Osaka strike, or disassemble its text patch.)

#### The dispatcher prologue and packet layout

**What happens before the switch.** Annotated (`rec` = packet `+$44`, see
below; `main` stores it at `.bss+4` and prints "PQDMonet: Starting up,
commblock at %X" with the packet address, `$31DD8`-`$31E08`):

    $31E0C  call sub_31e20 with lr2 = -1, in an endless loop  (the main loop)
    $31E3C  wait until packet+$14 != 0;  packet+$1C = 1
    $31E64  rec = [.bss+4];  lr8 = cmd = [rec+4];  seq = [rec+8]
            if seq != [.bss+8] and cmd != 1:
                print(.lit $0D88, [.bss+8], seq, cmd, [.data+$F08])
                  "MonetMain: Sequence error %d != %d, func = %d, last func = %d"
                packet[0] |= 3; reply 0; complete; return   (sequence error)
    $31EEC  [.data+$F08] = cmd  (last command, initially -1);  [.bss+8] += 1
    $31F0C  n = first argument:  -1 -> accept;  <= 0 -> reject;
            else accept if cmd is among the next n arguments
            rejected: reply 0 ("not handled"), return without completing
    $31F7C  call service $D2 (stub $38F64: restart the kernel if gr64 bit 28 is set)
            if (cmd & $FF00) != $8000: goto switch ($32850)
            else reply = sub_37B58(cmd, [rec+$0C], [rec+$10])
    $32850  cmd > $3C (unsigned) -> default; else jmpi [.lit $0DE0 + 4*cmd]
    $3287C  common exit: complete unless lr9 = 0; return cmd

"Complete" is `sub_328C8`: it clears packet `+$14` and posts a completion
code to packet `+$18` and, if that pointer is non-zero, to `*[packet+$20]`
(with `$D3(0)`/`$D3(1)` around the store when `extern#1772+$90` is set). The
code is 3, or `$0B` when bit 0 or 1 of packet word 0 is set.

* **The packet layout matches the host exactly.** The host (`gc24.s`
  `$5F54`-`$5F78`) writes the selector to `+$48`, a running sequence number
  to `+$4C`, the argument count to `+$50`, and `$FFFFFFFF` to `+$14`. So the
  card's `rec` is packet `+$44`, and the switch index is the host's
  selector itself (`$0C`-`$38`; the table covers `$00`-`$3C`). The host rewrites two selectors to `$24`
  StdRect before writing the stream record: StdRRect with a zero oval width
  or height, and StdRgn (`$18`) when `rgnSize` = 10 (`gc24.s` `$4D86`-`$4DBE`,
  which copies `rgnBBox` to a local rect and passes it in place of the
  region). The card never rewrites a selector.
* **`sub_31e20(n, cmd1, …, cmdn)` is varargs.** The frame is 10 registers,
  so the incoming arguments start at `lr12`, and `storem lr12, gr125`
  spills them to the memory stack. The main loop passes `-1` (every command).
  A second caller, at `$33404`, passes `(6, $26, $38, $30, $0C, $2A, $2C)`.
  So while some operation is in progress, only those six commands are
  serviced. Every exit returns the command number, and that caller checks
  it for `$17`, `$38` and `$26` (see the wait loop below).
* **The constants:** `const gr96, $FF00` / `and gr97, lr8, gr96` /
  `const gr96, $8000` / `cpneq`. Commands `$80xx` go to `sub_37B58`, and
  everything else goes to the switch.

#### The Std* selectors at the card's dispatcher

(These selectors never arrive here in practice: `EngineDispatch` turns them
into DrawMultiObject records instead of sending them. See "DrawMultiObject:
the batched drawing stream". What follows is what the card's dispatcher
would do with them, and how the host reacts to each reply.)

**So the drawing selectors reach the default.** The table entries
(`.lit $0DE0` + 4·command) of `$20` StdLine, `$21` StdText, `$23` StdArc,
`$24` StdRect, `$2E`, `$2F`, `$31`, `$18`, `$2A`, `$32` and `$35`-`$37` all
name the default block `$32818`. So in this switch they would print
"Unknown Function". They are accelerated before they get here, by the host
writing them into the drawing stream.

**What the default does, and what the host does with it.** The default
block `$32818`:
1. calls the reporter `$00140` with "Unknown Function: 0x%X" and the
   command;
2. ORs `$11` into packet word 0;
3. jumps to the common exit `$3287C`. It stores no reply, so `+$1C` keeps
   the 1 stored on entry; because word 0 now has bit 0 set, the completion
   code is `$0B` instead of 3.

On the host, `$0B` first counts as an ordinary completion: both waits test
bits 0-1 before anything else (`EngineDispatch` `$610E`, `sub_624A`
`$6342`), so the unknown command returns its reply 1. The next
`EngineDispatch` call sees bit 3 before it sends (`$5F32`-`$5F40`): it
sends nothing, sets bit 4 of its flags `$1C(a4)` and returns -1, so that
call falls back to the 68K. The next command through the generic send
path (`L5E6C`) finds bit 4 and runs the reset routine `sub_6F4E`
(`$5E8E`-`$5EC2`).

The reporter is gated by a level word at `.data+$284`: 0 returns at once,
1 goes to `printf` `$39284`, anything else to the log buffer `$00F84`. It
starts at 1, so the message is sent to the host (see the C library below).

On the host, `GA_StdLine` (`$3682`) is typical. It calls
`EngineDispatch($20, …)` with one argument (a pointer to its own
parameters), then acts on the reply:

| reply | host does |
|---|---|
| 1 | nothing more: the record is in the stream, and the card draws it |
| 2 | runs the original `StdLine` with `pnVis` set to -1 (the pen moves, nothing is drawn), then restores `pnVis` |
| anything else (0) | runs the original `StdLine` |

Before the fallback, it calls `sub_86D6`, which sends `$38` (synchronise)
and works out the destination pixmap. After the fallback, it calls
`sub_879A` when `sub_86D6` asked for it. The fallback runs only when
`EngineDispatch` returns 0: no current port, no room, a TrueType font, a
failed font upload. Then the 68k QuickDraw draws into the card's frame
buffer over NuBus.

**So the card accelerates:**
- StretchBits (command `$15`, and through it CopyBits);
- the Std\* drawing calls, as stream records through `$2D`/`$38`/`$26`
  (DrawMultiObject);
- the cache commands, including the font upload `$30`;
- the `$80xx` module interface.

The card's dispatcher itself has no case for the Std\* selectors.

Reply 0 (do it yourself) comes only from the cases that store it (table
below) and from a command rejected by the accept list; an unknown command
keeps reply 1 and is flagged in word 0 instead.

The table has 31 default entries: `$08`-`$0B`, `$0E`, `$10`, `$18`,
`$1C`-`$25`, `$27`, `$28`, `$2A`, `$2E`, `$2F`, `$31`, `$32`, `$34`-`$37`
and `$39`-`$3B`.

One oddity remains. `$2A` is sent by the patches of `PicItem1` (`$AB9A`)
and `OldPatToNew` (`$AB11`), two internal QuickDraw traps (see
`QUICKDRAW_PATCHES.md`). `PicItem1` plays back one picture opcode, and
`OldPatToNew` turns an old 8x8 pattern into a pixel pattern. `$2A` is in the
accept list of the nested wait (`$33404`: `$26`, `$38`, `$30`, `$0C`, `$2A`,
`$2C`), although its case is the default, so during the wait it is reported
as an unknown function and the wait goes on. System 6's table sends `$2A`
to its default too.

#### The `$80xx` commands, the card heap, the wait loop

**The `$80xx` commands (`sub_37B58`).** The function's arguments
start at `lr8` (frame of 6 registers): `lr8` = command, `lr9` = `[rec+$0C]`
(count), `lr10` = `[rec+$10]` = `p`. It switches on `cmd - $8000` (0-4,
anything else returns `-$32`) through `.lit $1008`, the module's `.lit` base
`$0FC0` plus `$48`:

| command | case | does |
|---|---|---|
| `$8000` | `$37B94` | return 0 |
| `$8001` | `$37B9C` | return `p[2](p[0], p[1], sub_379A0)`: call code at a host-given address |
| `$8002` | `$37BC4` | return `sub_3779C(p[0])` = `sub_37658(p[0])`: allocate `p[0]` bytes from the card heap |
| `$8003` | `$37BD4` | `sub_377CC(p[0])` = `HeapFree` `$376A0(p[0])`: free a block; return 0 |
| `$8004` | `$37BE4` | return `p[0] + p[1] + p[2]` (an echo/arithmetic test) |

The allocator is the module `$372D0`-`$3772C`:

* `.data+$1388` holds a pointer to the heap (0 in the file); the header is at the start of the `sysalloc` block (`$37328`-`$37338`). The entry points are `sub_37658` (malloc, initialising on first use), `HeapFree` `$376A0`, and `sub_376EC` (free bytes, no caller); Antelope's own `malloc` users share this heap with the modules.
* It is created on first use by `sub_372D4`:
  1. call service `$C1` (stub `$38F24`);
  2. subtract `$1000`;
  3. call service `$101` (stub `$39008`, HIF `sysalloc`) with that size, retrying 1,000 bytes
     smaller until it returns non-zero;
  4. store the block and build a free list in it (`sub_373A0`).
* `sub_37470(heap, n)` and `sub_3754C(heap, ptr)` are allocate and free.

This also names two services by use. `$C1` is "free memory": its `PrivNZ`
entry is `$20012AC`, `Hand`'s "free stack/heap space" routine
`$20012AC`-`$20012E4`. `$101` is the program break (`sbrk`), as `Hand`'s
register notes say (`gr65`, service `$101`).

**The wait loop (`sub_33374`, the nested dispatcher caller).** It waits
while packet `+$1C0` is at most `*target` (its pointer argument, `lr13`),
counting spins in packet `+$1C4`, and on the way out stores the new `+$1C0`
in `*target`. The host side:

* it writes its own counter `$C0(a4)` into `+$1C0` (`gc24.s` `$5962`, right
  after sending command `$38`);
* it watches `+$1C4` change while it waits (`$60D4`, `$6306`), and calls
  `sub_75FE` when it stops.

So `+$1C4` is the card's heartbeat. While waiting, whenever the host posts a
request, the card services only commands `$0C`, `$26`, `$2A`, `$2C`, `$30`
and `$38` (through `sub_31e20(6, …)`). By the command returned:
* `$38`: return `$C8`; `$26`: return `$C9`;
* `$0C`, `$2A`, `$2C`, `$30`: go on waiting;
* `$17` (rejected by the list): return -7; any other rejected command: -5.

Inside the wait, `$26` and `$38` store `p[1]` in `+$1C0` and skip the
completion, leaving the request open for the caller; from the main loop
(`n` = -1) both reply 0.

#### Host-loaded modules, end to end

This section follows one module from the host call to the card and back.
Both sides were read in the exact listings (`gc24.s` `$1404`-`$239A`,
`$6442`, `$6C70`, `DRVR.s` `$0F0A`/`$06D0`, `text.asm` `$372D0`-`$37C0C`,
`$32AB8`, `$31F7C`, `$3299C`). The selectors are 32-bit values: the card
builds them with `constn` (`$FFFF80xx`), and the host tests them as
`sel - $FFFF8000` (`$190E`). Below they are written `$80xx`.

**The way in.** A program reaches the API through the driver, not through
the patch table. `DRVR` Control 54 (`$0F0A`) calls the hook in slot
`$A84` with `(csParam+2, csParam+6, &globals+$AA0)`, and raises the
card-response timeout (unit `+$002`) to 2000 ticks for the call. Status
54 (`$06D0`) calls it with `(-1, 0, &globals+$AA0)` and returns the result
in `csParam+2`. The slot is filled at patch time (`DRVR` `$1076`-`$10A4`):
gc24 entry #105 has ID `$FFFFFFFD` = -3, so `$A78 + 4·3` = `$A84` gets the
entry's `+$28`, `bra.l GA_ControlFFFFFFFD` (`$13D8`), which passes its
three arguments on to `sub_1404` (`$6C70`). DoOpen clears
`globals+$AA0` (`DRVR` `$00FA`). The card's request 999 uses the same
handle (`sub_6442` `$6594`: `sub_1404(999, p, globals+$AA0)`), so the
module state is the one at `globals+$AA0`. No caller of Control or Status
54 is in this repo. (Under System 6, slot `$A84` holds the codec entry
instead; see section 9.)

`sub_1404(sel, params, &h)` (C calling convention) creates `h` on first
use (`NewHandle,SYS,CLEAR($7A)`), locks it for the call, stores the result
in `+$6A` and unlocks it. An unknown selector returns -50.

**The state block (`$7A` bytes).**

| offset | field |
|---|---|
| `+$00` | module table: `$1C`-byte records, `+$5E` of them (16, grows by 16) |
| `+$04` | task table: `$20`-byte records, `+$5A` of them (32, grows by 32) |
| `+$08` | module counter (the low part of the next module id) |
| `+$0C` / `+$0D` | mailbox command posted / reply ready (bytes) |
| `+$0E` | mailbox command (`$8001`-`$8004`) |
| `+$12` | mailbox reply |
| `+$16`, `+$1A`, `+$1E` | its arguments; `+$56` = their count |
| `+$66` | a private `$70`-byte record from `sub_225C(0)` (not the driver's device record); its `+$6C` points to this block |
| `+$6A` | the last result |
| `+$76` | the card message buffer, `$5C` bytes (from `$8002`) |

| module record (`$1C`) | | task record (`$20`) | |
|---|---|---|---|
| `+$00` | id `$53000000 \| n` (0 = free) | `+$00` | its module record (0 = free) |
| `+$04` | image size | `+$04` | the host callback list |
| `+$08` | card address | `+$08` | the task word (passed to the entry; `$8006`/`$8007`) |
| `+$0C` | entry point | `+$10` | last command (`$8001`) |
| `+$10` | the module word (`$8004`/`$8005`) | `+$14` | state: 0 idle, 3 running, 1 accepted, 2 replied |
| `+$14` | task count | `+$18` | the reply |

Module ids carry a running counter (`$1B1C`), task ids the table index
(`$1C38`); both are found by masking with `$FFFF`. Task lookups check only
the `$54` prefix, not the index range or whether the slot is in use.

**The mailbox.** All `$80xx` commands go through the same path. The
caller fills `+$0E`, `+$16`-`+$1E` and `+$56`, clears `+$12`/`+$0D`, and
sets `+$0C`. The idle routine `sub_22DA` (selector 11; every wait loop
calls it) sees `+$0C`, clears it, runs `EngineDispatch(+$0E, &+$16, +$56)`,
and stores the reply in `+$12` with `+$0D` = 1 (`$22F0`-`$2310`). It then
tests the status word: bit 2 set means a card request is waiting, and
`sub_6442` serves it (`$2352`-`$2366`). `sub_21BC(n)` is `$8002(n)` and
`sub_220C(a)` is `$8003(a)`; both wait for `+$0D`.

On the card the command arrives at the dispatcher's main loop, which sends
`(cmd & $FF00) == $8000` to `sub_37B58(cmd, count, p)` and stores the
result as the reply (`$31F7C`-`$31FE0`). `p` is `[packet+$54]` (`rec+$10`),
the argument pointer every command uses: `InitPacket` sets it to
`packet+$650` (`$32A0C`-`$32A18`; System 6: `packet+$64C`, sw11 `$2E5F0`),
and the host copies the arguments there. The nested wait (`sub_31e20(6, …)`) does not list `$80xx`, so
modules run only from the main loop.

| command | card (`sub_37B58`, `.lit $1008`) | host user |
|---|---|---|
| `$8000` | 0 | none |
| `$8001` | `p[2](p[0], p[1], sub_379A0)` (`$37B9C`) | `sub_1E7E`, `sub_1FD6` (run a task) |
| `$8002` | `sub_3779C(p[0])` → `sub_37658`: card heap, the address or 0 | `sub_21BC` (open, load) |
| `$8003` | `sub_377CC(p[0])` → `HeapFree`; 0 | `sub_220C` (unload) |
| `$8004` | `p[0] + p[1] + p[2]` | open |
| other | -50 | |

(verified)

**The card heap.** `sub_37658` (malloc) creates the heap on first use
(`sub_372D4`): service `$C1` (free memory) minus `$1000`, then `sysalloc`
(`$101`), retrying 1000 bytes smaller until it succeeds. The block's
address goes to `.data+$1388`, and `sub_373A0` builds the header in it.
`sub_37470` is a next-fit allocator (size rounded up to 4, `$0C` bytes of
header per block, 0 when nothing fits); `sub_3754C` frees and merges.
`HeapFree` `$376A0` ignores calls before the heap exists. `sub_376EC`
(free bytes, heap `+$0C`) has no caller. This is Antelope's general heap:
`sub_37658` and `HeapFree` have about twenty other callers (malloc
`$33680`, PQDInit, the caches, the C library), so modules share it with
Antelope itself.

**Open (selector 0, `sub_1604`).** It sets the handle size to `$7A` (trap
`$A024`, SetHandleSize), makes the private record (`sub_225C(0)`, else -1),
allocates the two tables with `NewPtrSys` (else `MemErr`), and links the
record's `+$6C` to the block. Then the echo: `$8004($11111111, $22222222,
$33333333)`, pumped until `+$0D`; any reply other than `$66666666` frees
the tables and returns -4 (`$1758`). Finally `$8002($5C)` allocates the
message buffer into `+$76` (0: -5). It returns 0. Open does not check
whether it is already open.

**Load (selector 1, `sub_1A2E`, params `{acef, size}`).** It takes a free
module record (the table grows by 16 if none is free), allocates `size`
bytes on the card with `$8002`, and calls `ACEFLoad(acef, addr, size)`.
ACEFLoad relocates the image for `addr` and returns `addr + 4`. It reads
the header's entry field into `-$8(a6)` but then overwrites it (`$2528`,
`$2534`), so the entry is always the first word after the first tag word
of `.text`. The record gets the id `$53000000 | ++counter`. The result is
the id, or 0 on any failure. When ACEFLoad fails the card block is not
freed.

**Unload (selector 2, `sub_1B3C`, `{module id}`).** Kills every task of
the module (`sub_1D70`), frees its card block with `$8003`, and clears the
record. -1 for a bad id.

**Tasks (selectors 3 and 4).** `sub_1C94` (`{module id}`) takes a free
task slot through `sub_1BEE`, which sends the new task the message type
`$FFFF` and waits for the answer (see below). A non-zero answer frees the
slot, and `sub_1BEE` returns 0. `sub_1C94` treats that 0 as "table full",
grows the table by 32 and tries again (`$1D5E`). A module whose `$FFFF`
handler fails therefore makes it loop until `NewPtrSys` fails (returns 0),
and the module's task count (`+$14`) goes up on every attempt (`$1C6C`).
On success it returns the task id `$54000000 | index`. `sub_1D70` (`{task
id}`) sends `$FFFE` and waits (the answer is ignored), frees the callback
list, decrements the task count and frees the slot.

**Messages.** The caller's message is `{+$04 task id, +$08 flags, +$09
length in bytes, +$0A type (word), +$0C data}`. Sending (`sub_1E7E`,
selector 6) does the following:
1. Wait until the task is in state 0 or 2, pumping `sub_22DA`.
2. In 32-bit mode (`SwapMMUMode`), write the card buffer `+$76`: the task
   id at `+$04`, the type at `+$0A`, and `length` bytes of data from
   `+$0C`, copied in longs. `+$00`, `+$08` and `+$09` are not written,
   and the length is not checked against the buffer's 80 bytes of data
   room.
3. Post `$8001(buffer, task.+$08, module.+$0C)`. The task goes to state 3
   with reply 0.
4. Pump until state 2, set state 0, and return the task's `+$18`.

The `$8001` reply itself (the entry's return value, stored in `+$12`) is
never read. Only a `$8002` request from the task ends the wait, and there
is no timeout. `sub_1FD6` (selector 7) does steps 1-3 the same way, sets
bit 7 of the caller's `+$08` (host side only, after the copy), waits only
until the state leaves 3, and returns the task id. `sub_2130` (selector 8,
`{task id}`) requires state 1 or 2 (else -1), pumps until 2, sets 0 and
returns the reply.

**On the card: the entry and the services.** The module is entered as
`entry(msg, taskword, services)` (`lr2`-`lr4`), where `msg` is the card
buffer (task id at `+$04`, type at `+$0A`, data at `+$0C`) and `services`
is `sub_379A0(task, sel, count, argv)`, a C function. `sel - $8008` is
switched through `.lit $0FC0` (18 cases); `task` is only passed on:

| selector | card (`sub_379A0`) | does |
|---|---|---|
| `$8008` | `$378DC(a0, a1, a2)` → `CopyHostMemory(a0, a2, 0, 2, a1)` | copy `argv[2]` bytes of host memory at `argv[0]` into the card buffer `argv[1]` |
| `$8011` | `sub_3779C(argv[0])` | allocate on the card heap |
| `$8012` | `sub_377CC(argv[0])`; 0 | free |
| `$8013` | `$3791C(addr, len, &outLen, &outFlag)` | `MapVirtual(addr, len)`. On -1 it stores 0 in `*outLen` and returns `addr`; otherwise it stores `len` and returns the mapped address. If `outFlag` is non-zero, it gets `extern#1772+$90` (`$13FE0`) |
| `$8014` | `UnmapAll`, then `sub_16BA0`; 0 | unmap, then free mega buffers 1-9 (`extern#1750+$10`-`$90`) and rewind buffer 0 |
| `$8015` | `$13FCC` | return `extern#1772+$8C` |
| `$8016` | `$13FE0` | return `extern#1772+$90` (the mapping flag) |
| `$8017` | `$13FF4`; 0 | clear the mapped-range list head `extern#1772+$00` |
| `$8018` | `$1400C` | return `extern#1651`: the 36-byte block PQDInit allocates (`$1671C`); `+$00` = `&extern#1772`, `+$10` = `&extern#1750`, `+$1C` = the packet base, the rest pointers into `.data` and Antelope's blocks |
| `$8019` | `$14020` | return the entry table `extern#1636` |
| `$8009`-`$8010` and anything outside `$8008`-`$8019` | `sub_37730` | `CallBack(999, 1, 4, task, sel, count, argv)`; after `$8003`, also `sub_32AB8(1)` |

(verified against `.lit $0FC0`-`$1004`)

The entry table (24 functions, see "The entry table, named") gives the
module the QuickDraw core and also `CallBack` (`+$44`). With `CallBack` a
module can make any host request directly (handles, resources, memory
locking), including codes 3-7, 16 and 20, which Antelope itself never
uses. `CallBack` works only while a command is active (packet `+$14` set),
that is, while the module's `$8001` call has not returned.

**Request 999 on the host.** `sub_6442` (`$657E`) calls `sub_1404(999, p,
globals+$AA0)` and writes the result to mailbox `+$08`. `p` is the
mailbox argument block (low 20 bits of mailbox `+$14` plus the packet's
top 12 bits): `{task, sel, count, argv}`. `sub_1404` copies `count` longs
from `argv` into a 16-long local array in 32-bit mode (`$15A8`; `count` is
not checked, and `argv` is used without translation), then calls
`sub_18BE(state, task, sel, count, copy)`. A task id must have the `$54`
prefix, or be 0 (else -1).

| selector | host (`sub_18BE`, table at `$192C`) |
|---|---|
| `$8000` | returns the `task` argument |
| `$8001`, `$8008`-`$800F`, other values ≤ 0 | -1 |
| `$8002` | the reply: task `+$18` = `argv[0]`, state 2. With task 0: mailbox `+$12` = `argv[0]`, `+$0D` = 1 |
| `$8003` | state 1 ("accepted") |
| `$8004` / `$8005` | get / set the module word (`+$10`); -50 without a task |
| `$8006` / `$8007` | get / set the task word (`+$08`); -50 without a task |
| `$8010` | `_Debugger`, returns 0 (the `moveq #1` at `$19E0` is overwritten at once) |
| > 0 | the first callback registered for `sel` on this task: `proc(count, argv, refcon)` (Pascal, long result); -1 if there is none or no task |

Host callbacks are registered with selector 5 (`sub_1E12`, `{task, sel,
proc, refcon}`, `sel` > 0, else -1): a list of `{sel, proc, refcon, next}`
nodes. Registering a `sel` again replaces `proc` and keeps the old
`refcon`. A callback sees the host's copy of `argv`, so it can answer only
through its result (or by writing card memory through pointers it is
given). The card-side wrappers for `$8004`-`$8007` (`$37838`, `$377FC`,
`$378A8`, `$3786C`) exist but have no callers. A module sends these
selectors through `services`, which forwards them to 999.

**Replies, synchronous and asynchronous.** A module answers a message by
calling `services(task, $8002, 1, &value)` before it returns. To work on
after the host has stopped waiting, it calls `$8003` first. The host then
sets state 1, and `sub_37730` calls `sub_32AB8(1)`, which waits until
status bit 2 is clear and writes 1 to packet `+$18` (and
`*[packet+$20]`). `+$14` is left set. The host's `EngineDispatch` sees
bit 0 and returns the `$8001` reply that is still in `+$1C` (the 1 that
the dispatcher stored when it took the command), and `sub_1FD6` returns.
The module keeps running inside the still-open `$8001`. It can go on
making requests, which the host serves from its idle routine. A later
`$8002` sets state 2 for selector 8. When the entry returns, the
dispatcher completes normally (`+$14` = 0, status 3).

During that window `EngineDispatch`'s own wait has ended (status 1), but
the next command does not overwrite the packet: every command first passes
`sub_624A` (`$5EC8`), whose loop (`$6342`-`$634A`) waits for status bit 1,
i.e. for the completion (status 3). Nothing in this repo uses the
asynchronous path for modules.

**Card addresses on the host.** The host writes the `$8002` buffer
(`+$76`) and reads the 999 `argv` without any translation in 32-bit mode
(`$1F0C`, `$15B2`). So card addresses (slot nibble on top, filled in by
Boot) are usable as host 32-bit addresses. Only the mailbox pointer itself
is rebuilt from its low 20 bits.

**Results, all selectors.**

| sel | result |
|---|---|
| -1 | the last result |
| 0 | 0; -1 (no record); `MemErr`; -4 (echo); -5 (no card buffer) |
| 1 | module id, or 0 |
| 2 | 0; -1 |
| 3 | task id, or 0 |
| 4 | 0; -1 (bad prefix) |
| 5 | 0; -1; `MemErr` |
| 6 | the task's reply; -1 (bad prefix) |
| 7 | the task id; -1 |
| 8 | the task's reply; -1 (not state 1 or 2) |
| 9 / 10 | 1 / 0 |
| 11 | 0 (the idle routine) |
| 999 | as in the table above, also written to mailbox `+$08` |
| other | -50 |

#### The case blocks

**The case blocks.** The table has 28 distinct targets: the default
`$32818`, the common exit `$3287C` (commands `$02`, `$05`-`$07`: reply 1,
nothing done) and 26 case blocks. Most read their arguments the same way:

1. `rec = [global+4]`;
2. `p = [rec+$10]`, a pointer to the longs the host copied after the header;
3. the arguments are `p[0]`, `p[1]`, … in `lr2`, `lr3`, …;
4. the block calls a handler with `calli`.

The packet sets the reply to 1 on entry, so a block that stores nothing
answers "drawn". The blocks, by command:

The handler column comes from the relocations (next subsection). The
pointer to `rec` is at `.bss+$0004` of this module, and the packet pointer
is at `.bss+$0000`.

| command | block | what it does | handler |
|---|---|---|---|
| `$29`, `$2B` | `$32468`, `$32498` | `handler(p[0])`, no reply stored | both `$15808` FlushGDevice |
| `$2C` | `$324C8` | the same | `$158F4` FlushPixPat |
| `$33`, `$19`, `$1A`, `$1B` | `$324F8`, `$32570`, `$325A0`, `$325D0` | the same | `$14034` DisposeOffscreen, `$14168` FlushOffscreen, `$141F8` FlushColorTable, `$14274` FlushITable |
| `$3C` | `$32528` | copies `p[0]`, `p[1]` into a frame on the memory stack and calls `handler(&frame)`: a two-long command | `$140CC` ReleaseOffscreenPair |
| `$14` | `$32080` | `handler(p[0])`, then reply 0 | `$39104` (service `$D5`: clear bit `p[0]` of `[$4C00643C]`, mirrored to `$46000000`) |
| `$0C` | `$32408` | `handler(p[0..5])`: six longs; reply 0 if it returns 0 | `$151C4` CachePixPat |
| `$30` | `$322D4` | `p[0]` is a bit mask. Bit 0 takes two more longs; then bit 1 (three longs) or, if clear, bit 3 (two); then bit 2 (three) or, if clear, bit 4 (two). A zero result ends the chain with reply 0. | bit 0: `$14B64` UploadWidthTable; bits 1-4: `$14A80` UploadFontStrike |
| `$0D` | `$32600` | `e = CacheFind(6, p[0])`; none: reply 0; else `e+$18 = p[1] & $80`, reply `[e+$10]` | `$15D28` CacheFind |
| `$0F` | `$32688` | `e = CacheFind(6, p[0])`; none: reply 0; else `e+$18 = 0` | `$15D28` CacheFind |
| `$16` | `$3279C` | stores `p[0]` and `p[1]` in `extern#1753+$18` and `+$14`; no call | - |
| `$26`, `$38` | `$32234`, `$32284` | from the main loop (`n` = -1) reply 0; inside the wait, `packet+$1C0 = p[1]` without completing | - |
| `$80xx` | `$31F7C` | `reply = handler(cmd, [rec+$0C], [rec+$10])` | `$37B58` |
| `$01` | `$31FE8` | `InitPacket([rec+$0C])` (`$3299C`), sequence counter `[.bss+8]` = 0, then reply `CallBack(100, 1, 0)` | (local `call`s) |
| `$04` | `$32040` | `packet+$04 = p[0]`, reply 0 | - |
| `$11` | `$3210C` | `sub_15D84(i)` for i = 0..10, then `sub_16BA0()` | `$15D84` CacheFlushKind, `$16BA0` PQDReset |
| `$17` | `$320C8` | `PQDInit(packet+$604)`; reply 1 if it returns 0, else -1 | `$161F8` PQDInit |
| `$15` | `$32148` | `StretchBits(packet+$58, 0, 0, 0, 0)`; reply 0 if it returns more than 0 | `$2D7B8` StretchBits |
| `$2D` | `$32188` | `r = sub_13770(packet+$170)`; reply 1 if `r` = 0, -1 if `r` = -1, else 0; for `r` = 7 it first calls `PQDInit(p[0])` (reply 1 if that returns 0) | `$13770` DrawStreamCommand, `$161F8` PQDInit |
| `$12` | `$326E8` | `$CD(-1)` (clear all page entries), `extern#1772+$88` = 0, `+$8C` = `[extern#1772+$8]`, `$D3(0)`, `+$90` = 0 | `$39028` (`$CD`), `$390B4` (`$D3`) |
| `$13` | `$32740` | `$CC(p[0], p[1], p[2])` (map a range), then `extern#1772+$88` = `+$8C` = 1 | `$39018` (`$CC`) |
| `$00`, `$03` | `$327D8`, `$327F8` | only store reply 0: "not handled", so the host runs the original | - |
| others | **`$32818`** | **default**. The `cpgtu` branch lands one word in, because its delay slot holds the block's first word. Reports "Unknown Function: 0x%X" and flags word 0 (above). | `$00140` |

The `$38xxx`/`$39xxx` handlers are system-call stubs in object
file 30 (`$38F24`-`$39114`), most of them 16 bytes: `const gr121, N` / `asneq 66, gr1, gr1` /
`jmpi lr0` (the 29K OS convention: the service number goes in `gr121`).
There are 27: 24 for the vector-66 kernel services (23 numbers, `$D4`
twice), and three trap-69 HIF calls (`$101` sysalloc, `$111` clock, `$112`
cycles). The others (`$13770`-`$16BA0`) sit in two object files
next to each other, `$1376C`-`$13F50` and `$13F50`-`$174FC` (files 14 and 15
of `antelope_modules.py`). Five of them (`$14034`, `$140CC`, `$14168`, `$141F8`,
`$14274`) are consecutive functions of `$50`-`$9C` bytes, each called by one
one- or two-long block. They are cache flushes: three name themselves by
their messages, `$14274` FlushITable releases an inverse-table entry
(`CacheFind(1, p[0])`, then `CacheRelease`), and `$140CC`
ReleaseOffscreenPair releases the type-6 (offscreen) entry whose
`+$20`/`+$24` match the two longs.

On the host side (`QUICKDRAW_PATCHES.md`) the commands with one long are
`$0F` `$10` `$15` `$17` `$20` `$29` `$2C` `$32` `$33` `$35` `$36` `$37`.
Those with two longs are `$18` `$24` `$2A` `$2F` `$31` `$3C`, and those with four
are `$21` `$23` `$2E`. Against the table: `$0F`, `$29`, `$2C` and `$33` have
one-long cases and `$3C` a two-long case; `$15` and `$17` take their data
from fixed packet offsets (`+$58`, `+$604`) instead; the rest are defaults.

**Relocations name the targets.** `.text` loads every address with a
`const`/`consth` pair. The pair carries three relocation records:

* `R_ILOHALF` (type 26) on the `const`;
* `R_IHIHALF` (27) on the `consth`;
* `R_IHCONST` (28), whose symbol-index field is not a symbol: it is the low
  16 bits of the addend.

The instructions hold only the addend, and the loader adds the symbol. Two
details make this usable:

* **Symbol index + 1.** A relocation's symbol index points at a `(-3, 0)`
  entry, and the real symbol is the next entry. Checked on the dispatcher
  table: its `const` names 1135, and entry 1136 is `.lit $0D60`, which with
  the addend `$80` gives the table at `$0DE0`. With this rule the 1,899
  `consth` relocations resolve to `.text` (970, of which 969 are function entries in the
  symbol table), `.data` (254), `.bss` (175), `.lit` (116) and undefined
  externals (384).
* **The addend is in the `const`.** Every `consth` holds 0 and every
  `const` the addend's low 16 bits, because every addend is below `$10000`.

**Direct calls have relocations too.** Besides the const/consth types,
`.text` has 133 relocations of type 24 (R_IREL). Each one sits on a `call`
(opcode `$A8`) whose file displacement is 0: the loader fills in the
PC-relative distance. The symbol
is the entry itself (`.text`, value = target), or the next one when the
entry is `(-3, 0)`, as for const/consth (4 cases). 128 are `call lr0`, and
5 are transfer calls through `gr122`:
* the calls in object file 29 (`$37C10`-`$38F20`, call sites `$37C1C`-`$38C58`)
  go to kernel service stubs (`$B8` `$B9` `$BB` `$BF` `$C4` `$D1` `$D3` `$D4`): a family of `storem` fill/copy
  routines (see `$37D68` under "the rectangle case");
* the rest are in `$39130`-`$3CAB4`, calling each other and the
  HIF stubs (`exit` `$01`, `write` `$14`, `lseek` `$15` and so on). This is the C library.

**The C library (`$39118`-`$3CAD8`).** The R_IREL targets make it
readable. It is a Unix-style C library on AMD's HIF system calls:

| address | function | evidence |
|---|---|---|
| `$3B404` `$3B428` `$3B44C` `$3B470` `$3B494` `$3B4B8` `$3B4DC`, `$3C9EC` | HIF stubs from AMD's HIF library (`antelope_hif_stubs.py`): close (`$12`), exit (`$01`), lseek (`$15`), open (`$11`), read (`$13`), `$21` (tmpnam in the HIF list), write (`$14`), and remove (`$16`) at `$3C9EC` | `const gr121, N` / `asneq 69` / `jmpti gr121, lr0`; on failure store `gr121` to errno and return -1 |
| `extern#1769` | `errno` | every stub stores to it |
| `.data+$1580` | `_iob` (20-byte `FILE`s; `stdout` at `+$14`) | |
| `$39284` | `printf` | spills its varargs; if bit 15 of the flag halfword of `stdout` (`.data+$15A4`) is set, it first seeks to the end, `fseek(stdout, 0, 2)` (`$392A4`-`$392C4`: an append flag); then `$399E0($39118, stdout, fmt, ap)`, where `$39118` is the output routine handed to the formatter |
| `$39214` | `vprintf` | the same without the spill |
| `$399E0` | `_doprnt` (the formatting core) | calls memchr (4 times; `%s` with a precision), the `_ctype_` table, and the number converters `$3A5A4`-`$3A768` |
| `$39304` | `fseek` | calls lseek; `(fp, 0, 2)` is `SEEK_END` |
| `$3B500` | `memchr(s, c, n)` (earlier read as memset) | returns 0 if `n` = 0; replicates `c` into a word and scans with `cpbyte`; returns the address of the match or 0 |
| `$3B600` | `memcpy(dst, src, n)` | returns `dst`; byte, halfword or word loops by alignment, forward only; 30 call sites, 26 of them in Apple's code |
| `$3B748` | `memset(dst, c, n)` | returns `dst`; replicates `c`, stores words, masks the partial words at both ends; one caller (`$3B300`) |
| `.lit+$1021` | `_ctype_` (+1 for EOF) | |
| `$3AA9C`-`$3ABB4` | isupper, islower, isalpha, isdigit, isxdigit, isspace, ispunct, isalnum, isgraph, isprint, iscntrl | `_ctype_[c]` masked with 1, 2, 3, 4, `$44`, 8, `$10`, 7, `$17`, `$97`, `$20`: the V7/BSD bits `_U _L _N _S _P _C _X _B` |
| `$3ABD0` `$3ABE0` `$3ABEC` `$3ABF8` `$3AC24` | isascii (c ≤ `$7F`), `_toupper`, `_tolower`, toupper, tolower | `c - $20` / `c + $20`, the last two only if `_L` / `_U` |
| `$3AC88` | `exit` | stores 1 at `.data+$1578`, calls the hook at `.data+$1560` if it is non-zero, closes all 25 `_iob` entries with fclose `$3C1D4` (`$3ACD0`-`$3ACE8`), then `_exit` `$3B428` (HIF exit) |
| `$3B16C` `$3B294` `$3B300` `$3B390` | wrappers around open, close, read, write | each calls one stub |

The kernel side agrees with the HIF numbering. Hand's vector-69 handler
answers `$103` with `$400` (getpsize: the page size), `$104` with the
`InpArgs` block (getargs), `$111`/`$112` with the clock and cycle count,
and `$101` grows the heap (sysalloc). Other numbers are passed to the host
through the mailbox reporter `$2002650`. So a level-1 report (`$00140` ->
`printf`) becomes a HIF write and reaches the host as a mailbox message.
Level 2 goes to `$00F84`, a log buffer:
* globals: buffer `.data+$288`, write pointer `.data+$28C`, size
  `.data+$298`;
* on first use it allocates `size + $100` bytes through `$33680`. If that
  fails, it prints the message directly with `printf`;
* each message is `sprintf`'d (`$39864`) at the write pointer, which then
  moves to the terminating NUL;
* when the pointer reaches `buffer + size`, it `printf`s the whole buffer to
  the host and starts again at the beginning.

So at level 2 the host sees messages only in batches. Between flushes they
sit in card memory, where a debugger could read them through the buffer
pointer. The reporter level starts at 1 (`.data+$284`) and the log size at `$400` (`.data+$298`); see "`.lit` and `.data`, exact".

These are names by role: the library's own names and version are not in
the file.
### `.lit` and `.data`, exact

**`.lit`'s strings**, and the function that passes each to the reporter
(`firmware/disasm/lit.asm`):

| `.lit` | function | string |
|---|---|---|
| `$0000` | `$01468` | `Bogus` |
| `$00D0` | ITabMatch | `ITabMatch: Inverse Table is not up-to-date` |
| `$0100` | BitsToPixMap | `BitsToPix: xm points to a portPixMap` |
| `$02C0`-`$0430` | DrawMultiObject | `DrawMultiObject/opWhicPat: can't get a PatternCacheEntry for pattern` (sic), `…/opWhichPat: can't find PixPat in cache`, `…/opWhichPat: can't get a RGBPatCacheEntry for RGB Pattern`, `…/opSwapFont: width table is not in the cache`, `…/opSwapFont: width font is not in cache`, `…/opSwapFont: font is not cache`, `DrawMultiObject: unknown opCode %d` |
| `$0548`-`$061C` | DisposeOffscreen … FlushPixPat | `DisposeOffscreen: NULL offscreen Handle`, `FlushOffscreen: NULL offscreen Handle`, `FlushColorTable: NULL color table Handle`, `CacheGDevice: NULL GDevice`, `CachePixPat: NULL PixPatHandle`, `FlushGDevice: NULL GDevice`, `FlushPixPat: NULL PixPatHandle` |
| `$063C` | `$15DF8` | `Cache still busy, cacheType = %d, cache = %lx` |
| `$066C` | `$161F8` PQDInit | `PQDInit: Unable to allocate mega buffer` |
| `$0694`-`$0720` | `$16A04` PQDAlloc | `PQDAlloc: numBytes is not multiple of LONG`, `PQDAlloc: illegal numBytes = %d`, `PQDAlloc: maxed out on number of mega buffers authorized`, `PQDAlloc: Unable to allocate extra mega buffer, size = 0x%x` |
| `$0900`, `$0934` | scaleBlt | `ScaleBlt/scIndexToAny: unsupported dstShift = %d`, `ScaleBlt: unknown scaleNum = %d` |
| `$09F8` | GetSeek | `GetSeek: invalid rectFlag for seekMask = %d` |
| `$0D60` | main | `PQDMonet: Starting up, commblock at %X` |
| `$0D88`, `$0DC8` | the dispatcher `$31E20` | `MonetMain: Sequence error %d != %d, func = %d, last func = %d`, `Unknown Function: 0x%X` |
| `$0ED4` | `$33680` malloc | `malloc allocated %d bytes outside of the heap bounds, pointer = %x, heapMin = %x, heapMax = %x` |
| `$0F34` | MapVirtual | `MapVirtual: bytes == 0` |
| `$0F4C` | CallBack | `CallBack %d during inactive request` |

So the accelerator's own names are **PQD** ("PQDInit", "PQDAlloc", its
"mega buffers") and **Monet** ("PQDMonet" is `main`, "MonetMain" the command
loop). The rest of `.lit` is the switch and command tables (662 relocated
words, all 4-aligned `.text` addresses) and the C library's character-class
table at `$1020`.

**`.data`** (`firmware/disasm/data.asm`):

| address | value | meaning |
|---|---|---|
| `.data+$280` | 1 | the shared fill flag read by every caller of the fills |
| `.data+$284` | 1 | the reporter level: messages go straight to `printf` (level 1) |
| `.data+$288`, `$28C` | 0, 0 | log buffer and write pointer (allocated on first use) |
| `.data+$298` | `$400` | log buffer size |
| `.data+$2EC` | `00 03 02 01 01 03 02 01` | ColorMap's copy of 68k QuickDraw's `arithMode` table (`QDUtil.a`: srcCopy, srcBic, srcXor, srcOr, srcOr, srcBic, srcXor, srcOr) |
| `.data+$3D8` | `00 00 01 02 02 64 64 64` | the per-device blit-loop choice by `(mode xor lr42) & 7`; `$64` is the "no fast loop" value the code tests |
| `.data+$F08` | -1 | the last command (no command yet) |
| `.data+$1380`, `$1384` | 42, 123456 | the self-test's constants |
| `.data+$1560`-`$157C` | 0 | the `exit` handler table, empty |

File 20's `.data` holds pixel-expansion tables: a bit interleave at `$440`
(256 bytes; bits 0-3 of i go to bits 0, 4, 1, 5 and bits 4-7 to 2, 6, 3, 7),
1-to-2-bit (`$550`) and 1-to-4-bit (`$970`) expansions of a byte, 3 bits to
fields of 4/6/6 (`$D70`) and 6/6/4 bits (`$DD0`), and 3 bits to bytes
(`$DF0`-`$E0F`, 8 longs).

Of `.data`'s 101 relocated words, 96 are switch tables of the C library:
`_doprnt` (`$399E0`) and the number converters `$3A5A4` and `$3A90C`; the
others point into `.data1`. So the library's compiler puts switch tables in
`.data`, while Apple's code keeps them in `.lit`: one more sign of two
different compilers. `.data1` holds `"Interrupt Handler"`, two blank-padded
fields, a run of `'0'`s, and `"NAN()"`/`"INF"` for `printf`. System 6's
`.data` is the same apart from 200 bytes (`arithMode` and the pixel tables
are at the same offsets).

File 26's `.data` (the self-test file, with `TestSlotBurst` `$37000`) holds
its messages as strings: "branch failed", "add failed", "sub failed", "mul
failed", "div failed", "loop failed", "function call failed", "timertest
failed", "clocktest failed", "logic error", "timer error", "interleave
failure", "long error", "adr error". So there is a CPU, timer and memory
self-test on the card.

**The self-test (file 26).** Named by the messages each function uses:

| function | tests | messages |
|---|---|---|
| `$3404C` SelfTest(mask) | runs test i (0-9) when bit i of `mask` is set, through the switch at `.lit+$F78` | - |
| `$34304` | CPU (calls `$34774` logic, `$34828` timer) | branch/add/sub/mul/div failed, loop failed, struct assign failed, function call failed, timertest/clocktest failed, logic error, timer error |
| `$34B9C` | memory (calls `$34C34`, `$34DE4`, `$3563C`) | interleave failure; adr, long, short, byte, unaligned long error; Validation failure |
| `$359B0` | the CLUT | read clut |
| `$35BE8` | the MMU | mmu error, mapmem/unmapmem failed, get phys size, get phys adr, mmu phys access |
| `$36644` | interrupts | error setting int 2, never got int 2, error clearing vector 2, locals got trashed, foreigns got trashed |

`.data+$1380`/`$1384` (42 and 123456) are its test constants (`$36B08`,
`$36F4C`). Nothing in Antelope calls `SelfTest`: no direct call and no
relocated reference. So it is either unused in this build or reached from
outside, for example by a host-loaded module.

**Service `$C0` and the packet.** Besides `InitPacket`, three functions in
file 25 call `$C0`. They read `+$18 & $10000` (the feature flags that
`LoadFirmware` writes to `image+$18`) and copy `+$10`/`+$14`. So `$C0`
returns the comm header at `$4C006400` (`PublicIn`; handler `Hand`
`$2001408`), and `InitPacket` reads `[$4C006818]` = `PublicOut+$18`.
`PublicOut`'s header (`firmware/disasm/RuntimeData.asm`):

| offset | value | meaning |
|---|---|---|
| `+$00` | `$32100456` | |
| `+$04` | `$00700D01` | |
| `+$0C` | `$4C007000` | `HifComm`, the mailbox the host reads at `image+$40C` |
| `+$10` | `$4C007800` | `InpArgs` |
| `+$14` | `$4C007300` | `VidComm` |
| `+$18` | `$4C008C00` | the packet, `InitPacket`'s pointer |
| `+$1C` | `$00010000` | (Boot overwrites it) |

Boot replaces the top nibble of the four pointers with the slot number it
reads from `$4400000C`-`$18` (see `Boot.asm`, section 10.1). `PublicOut` also holds, at `+$510`, the
text "(c) 1989 Apple Computer, Inc. All Rights Reserved", then the credits
"Special Projects Group - SEG", "Hardware: Tony Masterson, Rob Pugh, Dean
Drako", "Software: Jean-Charles Mourey, Mark Krueger, Rekha Sh…", cut off by
the section's end (the same in System 6). **`PublicOut+$18` = `$4C008C00`** is exactly
the host's packet at slot offset `$s08C00`, so card and host agree on it.
How the host side was traced:


`InitPacket` takes the packet pointer from
`[$C0() + $418]`. On the host, `gc24` reads the packet address from its
device record `+$0C`, and `LoadFirmware` writes `image+$0C` = the card address
`ACEFLoad` returned for the program. The device record `gc24` uses is the
driver's unit record, and `BuildUnitRecords` sets its `+$0C` to
`$F0000000 | slot<<24 | slot<<20` + `$8C00` (`DRVR.s` `$1FD0`-`$1FF0`). So the
host's packet is at offset `$s08C00` of the slot space, card memory
`$4C008C00` (`PublicOut+$18`), right after `InpArgs`. No host program writes a field at
`+$418`, the kernel never touches `$4C006818` and never builds `$8C00`, and
neither host program writes into `InpArgs` (`$4C007800`, which only the
kernel's getargs uses).

## 7. The kernel's service table (vector 66)

`Hand`'s service dispatcher (`$20011E8`) takes the service number in `gr121`,
subtracts `$B6` and jumps through the word table at `$4C002500` (up to `$D6`
entries). `$4C002500` is exactly the **`PrivNZ`** section (`$84` bytes = 33
words, services `$B6`..`$D6`). Decrypted, it lists one handler per service
(`firmware/disasm/RuntimeData.asm`; an earlier version of this section had
only approximate pointers). Antelope calls the services through 16-byte stubs
`const gr121, N` / `asneq 66` / `jmpi lr0` at `$38F24`-`$39104`
(`svc_N` in `text.asm`); the HIF stubs at `$3B404`-`$3B4DC` and `$3C9EC` use
`asneq 69` and the second dispatcher `$2001AE8` (`$101` sysalloc, `$103`, `$104`
getargs = `$4C007800`, `$111` clock, `$112` cycles, `$121` set `gr92`/`gr93`).

| service | handler | what the handler does | Antelope stub, use |
|---|---|---|---|
| `$B6 $B7 $BA $BC $BD $BE $C2 $C3` | `$2001A60` | returns -42: not implemented (also `$C9` `$200145C` and `$CA` `$2001464`, the same two words) | - |
| `$B8` | `$20018E4` | timer interrupt enable (TMR.IE, bit 24): returns the old state, sets or clears it by `lr2` | `$39094` |
| `$B9` | `$20018B8` | OPS.SM (supervisor mode, `$10`): returns the old state, sets or clears it by `lr2` | `$39084` |
| `$BB` | `$2001A58` | returns `gr64`, the host's feature flags (`PublicIn+$18`) | `$38F44` |
| `$BF` | `$2001924` | OPS.DI (disable interrupts, `$02`), as `$B9` | `$390A4` |
| `$C0` | `$2001408` | returns `$4C006400` (`PublicIn`, the comm header) | `$38FC8`, `InitPacket` and the feature-flag readers |
| `$C1` | `$20012AC` | free memory: `gr127 - $3000 - gr65` (stack limit minus break) | `$38F24` |
| `$C4` | `$2001250` | returns `[$4C00682C]`, the slot number Boot read (`$4400000C`-`$18`), shifted left by 28 | `$38F34`, the own-memory test `$13F54` |
| `$C5` | `$2001224` | waits for the video interrupt: enables it at `$44000054`, polls `$44000068`, disables it | `$38F54`, `TestCLUT` |
| `$C6` | `$20012E8` | sets the display start and row bytes: if `$44000080` bit 31 is set it halves `lr2` and `lr4`; stores `lr2` at PublicOut+`$1C` and shifts it into `$44000000` (20 bits from `lr2 << 10`), stores `lr4` at PublicOut+`$24` and shifts it into `$440000A0` (12 bits from `lr4 << 18`); `lr3` is unused (`$20012E8`-`$2001368`; Boot reads both registers back into the same fields, `$20035DC`, `$2003768`) | `$38F74` (no callers) |
| `$C7` | `$2001374` | writes CLUT entry `lr2` (index to `$46C00000`) with the three data bytes `lr3`, `lr4`, `lr5` (to `$46C00004`) (`$2001374`-`$20013A8`) | `$38F84` |
| `$C8` | `$20013AC` | reads CLUT entry `lr2` (0-255, else -1) from the RAMDAC | `$38F94` |
| `$CB` | `$2001414` | adds `lr2` to `[$4C003120]` when `gr64` bit 20 is set, else returns 0 | `$38FF8` |
| `$CC` | `$200146C` | region-table add (`$2001478`): map a memory range | `$39018`; `TestMMU`, `MapVirtual`, the dispatcher |
| `$CD` | `$20015F8` | region-table remove (`$2001604`; -1 = all) | `$39028`; `TestMMU`, `MapVirtual`, `UnmapAll`, the dispatcher |
| `$CE` | `$2001774` | translates a 1 KB-aligned address through the region table (`$4C003168` count, 12-byte entries from `$4C00316C`: start, length, target): returns 0 and the target address in `gr122` (the stub stores it to `*lr3`); an unaligned or unmapped address takes the error path | `$39038` |
| `$CF` | `$2001950` | set interrupt handler `n` (0-3) to `fn` (`$4C00617C + 4n`); 0, else -1 | `$390D4`; `TestInterrupts` |
| `$D0` | `$20019BC` | return from an interrupt handler (the flag and saved registers at `$4C00618C`) | `$390E4`; the interrupt handlers |
| `$D1` | `$2001A48` | returns `[$4C006804]` (`PublicOut+$04`) | `$390F4` |
| `$D2` | `$2001294` | restarts the kernel (`jmp $2001FFC`) when `gr64` bit 28 is set, else returns 0 | `$38F64`; every accepted command |
| `$D3` | `$2001820` | host access mode: stores `lr2` at `$4C006848`, switches OPS.PD (physical data addressing), returns the old mode | `$390B4`; `TestMMU`, `CopyHostMemory`, `MapVirtual`, the dispatcher |
| `$D4` | `$2001808` | translates `lr2` through the table walker `$2001C2C`: physical address in `gr96`, length in `gr122` (the stub stores it to `*lr3`) | `$39050`, `$39064`; `TestMMU`, `CopyHostMemory` |
| `$D5` | `$2001260` | slot burst mask: `lr2 < 0` returns it, else clears bit `lr2` of `[$4C00643C]` and writes the mask to `$46000000` | `$39104`; command `$14` |
| `$D6` | `$2001888` | clears flags bit 8, sets OPS.TU (trap unaligned accesses, which vector 1 then emulates) and writes 0 to `$4400005C`: the reverse of what kernel init does when bit 8 is set (see section 8, the flags word) | `$390C4` |

The self-test's use of them agrees with the handlers: `TestMMU` reports
"mapmem failed" after `$CC`, "mmu error" after `$CD`, "get phys size" and
"mmu phys access" around `$D4`/`$D3`; `TestTimer`, `CacheFindStamp` and
`CacheCreate` read the clock (HIF `$111`).

**The interrupt test's handlers** (file 1). Interrupt 1's handler (`$00000`)
stores 42 into a global (`extern#1756`) and tail-jumps to `$D0`. Interrupt
2's handler (`$00020`) saves `gr100`-`gr127` and `lr0`-`lr127` into file 1's
`.data` (its 160 words are this save area). It calls `$36B08(1, 2, 3)`, which
`malloc`s 125 bytes and calls `$36BB0(1, 2, 3)`, expecting 6. If that holds,
it stores 42 (`.data+$1380`) into the same global, then fills and frees the
buffer. The handler restores the registers and leaves through `$D0`. So the test checks that C
calls and the heap work inside an interrupt handler; "locals/foreigns got
trashed" are its register checks. File 1 also holds `$00084` (sets a CPS
bit) and `$0009C` (sets or clears TMR's interrupt enable, `$01000000`).

**`CopyHostMemory` (`$16C48`): copy a host block into card memory.** The
arguments are `(src, bytes, isHandle, mode, buf)`. It rounds `bytes` up to
words and takes the destination from a switch on `mode` (`.lit+$760`):
0 `malloc` (`$33680`), 1 `PQDAlloc`, 2 the caller's `buf`, 3 `CacheAlloc`
(`.lit+$760`-`$76C`: `$16C88`, `$16CA0`, `$16CC8`, `$16CD0`). Without a
buffer it returns 0. Then there are three ways to copy:

* `extern#1772+$08` = 0: the card cannot read host memory itself (the
  flag is bit 3 of a host flags word, `[[.bss]+4]`, set at init). A handle
  goes through `CallBack($12, 1, 3, buf, src, n)` (`$33E10`). A plain block
  in the host ROM is read directly, the others through `CallBack(8, 1, 3,
  buf, src, n)` (`$33DD4`).
* `+$88` = 0 (no host VM mapping): a handle is dereferenced, and a source
  outside the ROM is masked with `+$94`. Init sets `+$94` to `$00FFFFFF`, or to `$FFFFFFFF`
  when the host flag `$200` (32-bit addressing) is set. Then the block is
  copied with `CopyLongsStorem`, or with `$16F5C` (a shift-and-merge copy)
  when the source is not word-aligned.
* `+$88` = 1: the handle's master pointer and the block are translated with
  `$D4`. If the range is contiguous, the copy runs with `$D3(0)` (physical).
  If not, it runs with `$D3(1)` on the logical address. The old mode is
  restored at the end.

`$33544` decides "host ROM". With the 32-bit flag it tests address bits
28-31 = 4, otherwise bits 20-23 = 8. That matches the Mac II ROM at
`$40800000` (32-bit) or `$800000` (24-bit). ROM is read at `addr |
$F0000000`, which is `$F0800000` in both cases: slot 0's NuBus space.
Mode 2 returns the (dereferenced) source instead of the buffer. The
callers are the dispatcher's case blocks `$14318`-`$14EF0`.

## 8. Configuration: `PupS` and Control calls 17-19

The control panel and `gc24` resource 32 configure the driver from the
`PupS` resource. The config word becomes the feature flags in
`PublicIn+$18` (`gr64` on the card), which Antelope may read through
kernel service `$BB` (see `$37D68` in "The case blocks").

The unit's config word `+$128` comes from Control call 17 (cs50 is the
same plus `$100`, "mailbox allowed"). Both 68k clients send cs17, in the
System 7 and the System 6 packages alike:
* the control panel (`cdev.s` `$0E02`) passes bytes 8-11 of `PupS`
  resource 0, which the driver stores at `+$128` (`csParam+2`);
* `gc24` resource 32 (`$052E`) also reads `PupS` (`$0388`), may flip
  bits `$90` of the word, and sends cs17.

All six `PupS` resources hold `00000001 000000D2 00000060 000004B0`
(System 6: last long `$3C0`). The record is four longs:

| offset | default | used by |
|---|---|---|
| `+$0` | 1 | accelerator on/off: the INIT sends Control 13 or 14 by it (`INIT_main` `$2A8`, `$340`/`$35C`); the control panel's `sub_d30` writes it, and `sub_8ca` applies it. `gc24` 32 does not read it: its `$D8DB` comes from a missing or empty `PupS` handle (`tst.l (a4)` at `$39E` tests the master pointer) |
| `+$4` | `$D2` (210) | not read by either path seen |
| `+$8` | `$60` | the config word, sent with cs17 (bits `$20`, `$40`, `$100` used by the DRVR; `$80` = never give up, in `gc24`; `$10` unused) |
| `+$C` | `$4B0` (1200); System 6 `$3C0` (960) | sent by `gc24` 32 with cs18, which stores its low word at unit `+$002`: the card-response timeout in ticks (below) |

`gc24` 32 (the startup sequence) checks Status 17, 18 and 19 against its
`vers` 1 (errors `$D8DD`-`$D8DF`; System 6 `$D8DF`-`$D8E1`), then sends
Control 17 and 18. Before Control 17 it would XOR the config with `$90`
if a local flag (`d5`) were set; in System 7 `d5` is cleared at entry and
never set, so this is dead code (System 6 sets it for the Option key,
below). So the config word is `$60` by default:
bits `$20` and `$40` are set, and `SetFeatureFlags` turns them into
feature flags `$1` and `$200`. No client sends cs50, so `$100` stays
clear and the "mailbox not enabled" bit `$800` stays set: the card's
debug messages are not delivered. (An earlier version of this paragraph
said that no client sends cs17. That came from scanning only some of
the control panel's `_Control` calls.)

**The flags word on the card.** The kernel loads `PublicIn+$18` into
`gr64` at init (`$200200C`) and tests it bit by bit (`sll gN, gr64, 31-bit`
followed by a jump); Antelope reads it through `$BB`. Set by the host
(`SetFeatureFlags`, `DRVR.s` `$2AD2`) or by the kernel:

| bit | value | set by | used by (card) |
|---|---|---|---|
| 0 | `$1` | config `$20` (default) | init: on a CPU with revision (CFG.PRL, bits 24-31) of 2 or more the flag leaves CFG.CD clear, i.e. the branch target cache on; otherwise CD is set (`$2002248`) |
| 1 | `$2` | - (no host code) | Am29027 fitted: init sets CFG.CP and writes `$0FC00820` to the coprocessor at `$1375` (`store 1,63`, `$200227C`-`$20022A0`); the register dump saves two coprocessor words at `$4C0067C8`/`$67CC` (`$2002A44`) |
| 2 | `$4` | - | vector 4 (coprocessor exception): ignored if set, else reason `$9D` |
| 3 | `$8` | - | coprocessor present, not initialised: sets CFG.CP and skips bit 1's set-up (`$2002268`). With 1 and 3 clear, coprocessor instructions trap to vector 3 (reason `$8F`) |
| 5 | `$20` | GC card types | init: clears the TLB and the pager's tables (`$4C002818`, `$4C002CA8`, free list `$4C002810`), i.e. demand paging is set up (`$2002370`) |
| 6, 7 | `$40`, `$80` | - | init: written, inverted, to `$44000090` and `$4400008C` |
| 8 | `$100` | GC card types | init: clears OPS.TU (no trap on unaligned access) and writes -1 to `$4400005C` (`$20022D8`); cleared at init when the 3-bit board code at `$44000094/98/9C` is 0 (`$20021C0`; the same code gates TestInterleave, and DRVR's ProbeCard reads `$9C`); service `$D6` undoes it; vector 7 (data access exception) reads `$44000070` when it is set |
| 9 | `$200` | config `$40` (default) | not tested by the kernel; Antelope's `storem` fills and copies (`$37C40`, `$37D98`, `$38248`, `$38900`) bracket their bursts with service `$B9` (OPS.SM, supervisor mode) when it is set |
| 10 | `$400` | - | instruction counting: init sets OPS.TE (`$20022A8`); each trace trap adds 1 to the 64-bit counter `$4C00684C`/`$6850` instead of reason `$9F` (`$2000A90`); debug commands 1/2 leave the saved OPS's TE alone (`$2002B7C`) |
| 11 | `$800` | host, until config `$100` (cs50) clears it | the mailbox: when set, the kernel does not post its reports (`$2001BC0`, `$2002AAC`) |
| 15 | `$8000` | - | vector 2 (out of range): ignored if set, else reason `$93` |
| 16 | `$10000` | - | the kernel stops after init with reason `$A1` instead of starting the program (`$2002634`); the timer vector's debug hook (`$2000978`); also read by Antelope's feature-flag readers in file 25 |
| 17 | `$20000` | - | init: OPS.DI (interrupts disabled) |
| 18 | `$40000` | - | vector 1 (unaligned access) and init: when clear, CFG.DW is set |
| 19 | `$80000` | - | init: the timer runs without its interrupt (TMR.IE clear: `$7530` instead of `$01007530`) |
| 20 | `$100000` | DRAM above `$0D000000` | init picks the heap base (`$20025CC`); services `$C1` and `$CB` |
| 21 | `$200000` | GC card types | init: OPS.SM: the program runs in supervisor mode |
| 23 | `$800000` | GC card types | not tested on the card; the host's `ACEFLoad` uses the same bit as "load into the top of card RAM" (VRAM on a stock card); a `Code` section goes to vaddr + `$0C000000` |
| 24 | `$1000000` | `globals+$254` | not tested by the kernel |
| 27 | `$8000000` | kernel | "regions registered": set by the region add (`$CC`, `$20014B4`), cleared by the remove (`$2001764`) and at init; the TLB-miss handler and the table walker `$2001C2C` test it |
| 28 | `$10000000` | - | service `$D2` restarts the kernel |
| 29 | `$20000000` | kernel init, when `[$46000000]` reports a hardware revision of 1 or more (`$2002208`) | not tested in `Hand` |
| 30 | `$40000000` | - | data watchpoint: a data TLB miss outside any region fails with reason `$A6` if it lies in `[$4C0067D8]`..`+[$4C0067DC]` (0/0, so address 0); otherwise it maps the page for one instruction (OPS.TE, `$61C8`/`$61CC`, `$2000860`), and the trace vector removes the entry again (`$2000A48`). When clear, such misses are mapped one-to-one (`$2000898`) |
| 31 | `$80000000` | - | vector 7 with a transfer pending: abandon it (CHC.CV cleared) and resume at gr121 (`$2000594`); when clear, rewind the load/store-multiple and retry (`$20005B8`) |

So the default flags (`$A00B21` on a GC card with the default config: bits 0,
5, 8, 9, 11, 21, 23) turn on paging, the `storem` interlock and the card
register set-up, run Antelope in supervisor mode without unaligned-access
traps, and leave the debug bits (2, 10, 15, 16, 30, 31) and the mailbox off.
OPS is the processor status the kernel's `iret` gives the program; the CFG,
OPS and TMR field names are AMD's (as in MAME's `am29000.h`): CD branch target
cache disable, CP coprocessor present, DW data width, PRL processor release;
SM supervisor mode, DI disable interrupts, PD/PI physical data/instruction
addressing, TU trap unaligned access, TE trace enable; TMR.IE timer interrupt
enable.

**The Control 18 word is the card-response timeout, in ticks.** The
driver never reads unit `+$002` itself, apart from returning it with
Status. It sets it to 300 (5 s) when it builds the unit record (`DRVR.s`
`$2156`), cs18 replaces it with the `PupS` value (1200 = 20 s; System 6:
960 = 16 s), and cs54 forces it to 2000 (33 s) while it calls client
hook 3 (`$0F0A`), then restores it. Its readers are `gc24`'s three wait
loops, which all compute `deadline = Ticks + unit+$002` and re-arm the
deadline when the card makes progress (it posts a request, which
`sub_6442` serves, or its heartbeat at packet `+$1C4` changes):

| loop | waits for | on timeout |
|---|---|---|
| `EngineDispatch` (`$6062`-`$610E`) | the reply to a command | `sub_75FE(unit, 2, 0)`: records reason 2 at unit `+$15C` and returns 0, so the 68K routine draws |
| `sub_624A` (`$628E`-`$6342`) | the card to finish (a sync) | reason 2 at unit `+$15C`, returns -1 |
| `sub_6F4E` (`$7130`-`$71EE`) | the reply to command `$01` (the sequence reset) | the first try waits only 5 ticks, then up to three more with the timeout. After the fourth it calls `sub_75FE(unit, 3, 1)` |

**`sub_75FE(unit, reason, disable)` is the give-up routine.** It stores
`reason` at unit `+$15C`. With `disable` > 0 it then:
1. sets state flag `$200` in unit `+$008`, the flag that makes later
   cs13/17/50/51 calls refuse;
2. clears `globals+$257` and walks the table at `globals+$278` (16 bytes
   per entry, count at `+$22C`), copying each used entry's `+4` long to
   `globals+$14+n`, which presumably switches the patches back to the
   original routines. The loop has a bug: it indexes `$14(a4,d7.l)` with
   `d7` counting by 1, not 4 (`$765E`), so each address lands one byte
   after the previous one and only entry 0 is restored correctly;
3. posts a Notification Manager alert (`_NMInstall`), "Graphics
   accelerator is having difficulty. You will need to reboot to re-enable
   it." (Pascal string at `$76CA`).

It skips all of this if the config word has bit `$80` (also tested by
`sub_7570`): a "never give up" debug setting, one of the two bits of
`gc24` 32's `eori.l #$90` (`$524`), dead in System 7. In System 6 it is live:
holding Option at boot (`$D4`-`$E2`) sets the flag, and `$508` XORs the
config word with `$90` before Control 17. The other bit, `$10`, is read by
nothing: not by DRVR (`$2AE6`-`$2B06`), `gc24`, the control panel (Status 7
at `cdev` `$05FE` tests only bit 31) or the card. The reason word is
write-only: nothing reads unit `+$15C` (the DRVR only clears it, `$1F92`;
the `gc24` stub at `$1068` jumps through globals `+$14+$15C`, the saved
address of dispatch #87, `_GetCTSeed`, not through the unit field).

| reason | where | condition | disable |
|---|---|---|---|
| 2 | `$6100`, `$631E` | command or sync timeout | no |
| 3 | `$71EE`, `$7236` | command `$01`: no reply after four tries, or reply ≠ 1 | yes |
| 4 | `$72F4` / `$730C` | `$17` (PQDInit, sent by `sub_494E` at `$72CC`) replies ≠ 1 during the reset; no disable if it timed out (unit `+$1C` bit 1) | no / yes |
| 6 | `$6FC8` | after a timeout the reset restarts the card (`sub_7570`, `gc24`'s copy of PostLoadPoke); dead, since `sub_7570` returns 0 on every path (`$7588`, `$75F4`; System 6 the same, `$88B8`) | (yes) |
| 7 | `$6DFE` | `StoreCtxWord_AA6`: trap not in the patch table at `globals+$278` | yes |
| 9 | `$734E` | no room for the DrawMultiObject record buffer (`sub_73C4` on the packet's free list at `+$10` = packet+`$6D0`); it retries with `$C8` less until the size is exactly 0, and from the default `$1000` (`DRVR` `$13A`) it wraps past 0, so in practice it spins instead of giving up | yes |

## 9. The System 6 package ("8•24 GC SW 1.1")

The System 6 package has the same resource set as the System 7 one,
with its own `ACEF` 100 (357,228 bytes against 330,316), `ACEF` 1,
driver and INIT. Its 68k clients send the same csCodes: control panel
2, 3, 4, 5, 13, 14, 17, 20, 48, 99; `gc24` 32 2, 3, 4, 5, 13, 14, 17,
18, 19, 20; INIT 13, 14, 20, 21, 99.


**The System 6 Antelope is a different build.** Unpacked with
`acef_unpack.py` it is also "32-Bit Antelope", version `$00110000`
(System 7: `$00700D01`): `.text` `$42AD8`, `.lit` `$1494`, `.data`
`$1830`, `.bss` `$AD8`; 1,838 symbols, 998 addresses. Its exact listings
are in `firmware/sw11/disasm/`. Their names come only from functions that
are identical to named System 7 ones (76 of them).

**The System 6 Runtime kernel is a different build too.** Its `ACEF` 1
(17,548 bytes against 17,968) has the same sections at the same
addresses, but `Hand` is `$2B74` bytes against `$2D14` (`Boot` is `$800`
in both). Its vector-66 service table `PrivNZ` (`sw11` `RuntimeData.asm`)
has 32 entries, services `$B6`-`$D5`, against System 7's 33 (`$B6`-`$D6`).
The handlers are in the same order, each `$140`-`$17C` bytes lower
(`$C0` at `$20012B8` against `$2001408`, `$CF` at `$20017D4` against
`$2001950`; the unused services share `$20018E4`, System 7 `$2001A60`).
System 7's extra service `$D6` (`$2001888`: clears `gr64` bit 8, sets
`OPS` bit 11, stores 0 to `$4400005C`) has one caller, PQDInit
(`$163DC`). System 6's Antelope has no stub for it. The System 6 `Hand`
and `Boot` listings are annotated with their System 7 counterparts (see
"The System 6 kernel against System 7's" below).

### The System 6 key

The System 6 ACEFs decrypt exactly with the same `ACEFLoad` scheme as
System 7's (`acef_unpack.py`). The KEY byte is `$D7` for `ACEF` 100
(System 7: `$4D`) and `$18` for `ACEF` 1 (System 7: `$BC`). (An earlier
version of this section fitted a key per word from relocation and idiom
samples with `antelope6_key.py`. That tool is removed.)

### The System 6 kernel against System 7's

`Hand` has 2,781 words in System 6 and 2,885 in System 7 (`$2B74` / `$2D14` bytes).
`Boot` is `$800` bytes in both, but System 6's code ends at `$2003764` (System 7
`$20037EC`) and the rest is zero. The two `Hand` listings were aligned on the
instruction text, with branch targets ignored. 2,725 System 6 instructions
match a System 7 one; a byte-for-byte alignment matches 2,654 words. All data
addresses are the same: `$4C00xxxx`, the `$44xxxxxx` registers, and the
PublicIn, PublicOut, HifComm and VidComm offsets. The annotated System 6
listings are `firmware/sw11/disasm/Hand.asm` and `Boot.asm`; each banner there
gives the System 7 address of its routine.

System 6 address = System 7 address − delta. The delta is `$150` for
`$2000324`-`$2001494`, `$140` to `$20015F4`, `$14C` to `$2001880`, `$17C` to
`$2002484`, and `$1A0` from `$2002518` to the end. The vector table that Boot
builds lists the same handlers in the same order. Only their addresses differ
(for example, the default vector is `$2001B8C` against `$2001D08`).

| routine | System 6 | System 7 | |
|---|---|---|---|
| vector 0 / entry (`jmp` fatal reporter, reason `$91`) | `$2000000` | `$2000000` | same |
| vector 1, unaligned access | `$2000008` | `$2000008` | **changed** (115 words against 199) |
| vector 7, data access | `$2000208` | `$2000358` | same |
| vectors 6, 8/10, 9/11 (TLB miss), 12, 13 | `$20004F4` … `$2000758` | `$2000644` … `$20008A8` | same |
| vectors 2-5, timer, trace, 68 | `$20007B8` … `$2000998` | `$2000908` … `$2000AE8` | same |
| INTR0-3 | `$20009B8`, `$20009F8`, `$2000A48`, `$2000F14` | `$2000B08`, `$2000B48`, `$2000B98`, `$2001064` | same |
| video command service (VidComm) | `$2000AC4` | `$2000C14` | same |
| interrupt dispatch | `$2000F54` | `$20010A4` | same |
| TRAP0/1, spill, fill | `$2000FF4` … `$2001068` | `$2001144` … `$20011B8` | same |
| vector 66 service dispatcher | `$2001098` | `$20011E8` | **changed** (bound) |
| service handlers | `$20010D4`-`$20018E4` | `$2001224`-`$2001A60` | see below |
| region-table insert / remove | `$2001328` / `$20014B8` | `$2001478` / `$2001604` | **changed** |
| vector 69, HIF services | `$20018F4` | `$2001A70` | same |
| range clip / table walker | `$2001AB0` | `$2001C2C` | same |
| default vector, pager | `$2001B8C`, `$2001B94` | `$2001D08`, `$2001D10` | same |
| kernel init | `$2001E80` | `$2001FFC` | **changed** (TLB count, monitor table) |
| report to host (mailbox) | `$20024B0` | `$2002650` | same |
| PC trace | `$20025F4` | `$2002794` | same |
| fatal-trap reporter | `$2002668` | `$2002808` | same |

What changed:

* **Unaligned access (vector 1).** System 6 clears CFG `$20` and CHC bit 0
  on entry. It checks each halfword separately with the walker (`$2001AB0`,
  length 2). System 7 sets CFG.DW (`$20`) and checks the whole word (length 4),
  with a fast path when the whole word passes. It also has a second path
  with no range check when OPS.PD (`$40`, physical data addressing) is set
  (`$200022C`), the bit that service `$D3` switches for host access. System 7 also
  treats a load/store-multiple count of 0 as `$200` and clears CHC on exit.
  So in System 7, unaligned accesses work in the physical host-access mode.
  In System 6 they always go through the region table (reading).
* **TLB scans.** Four routines clear the TLB entries tagged `$36`: insert
  (`$200144C`), remove (`$200159C`), `$D3` (`$2001704`) and init
  (`$200225C`). In System 6 these loops run `$3E`+2 = 64 steps of 2, which is
  exactly the Am29000's 128 TLB registers. System 7 runs `$7E`+2 = 128 steps
  (`$2001594`, `$20016E8`, `$2001850`, `$20023D8`). I can't say why; it is
  not needed for an Am29000.
* **Monitor table, in Boot and in kernel init.** Boot reads the three sense
  lines (`$44000044/48/4C`). Code 7 is an extended sense, and Boot reads it as
  `code << 4 | $0F`. The value is stored at `$4C006D08`. Boot
  (`$200365C`, System 7 `$20036BC`) turns it into PublicOut+`$28`, and kernel
  init (`$20022C8`, System 7 `$2002444`) turns it into a row size `gr81`.
  The row size times (PublicOut+`$28` + 6), plus PublicOut+`$1C`, gives
  `$4C003120` and the heap start. Both builds have codes 0-6, `$14F` (486
  lines, `$A00`) and `$0F`. System 6 gives `$0F` 560 lines (`$230`); System 7
  gives 576 (`$240`). Only System 7 has `$2DF` (624 lines `$270`, row
  `$680`) and `$30F` (576 lines, row `$A00`). Read as Apple's extended sense
  codes, `$2D` is the 16" 832×624 display (row `$680` is its 16-bpp
  rowBytes) and `$30` is PAL (alternate); code 0 gives 870 lines, the 21"
  Color's (sense 0 in the 1.1 ROM, 10.10). So System 7's kernel already
  knows the 1.1 ROM's monitors and corrects PAL to 576 lines.
* **Extended sense probe in Boot** (`$20033C8`, System 7 `$20033C8`).
  System 6 first zeroes `$44000034`-`$44000048`; System 7 zeroes only
  `$38`-`$40`. In each round one drive line (`$4400002C/30/34`) is set to −1
  and the other two sense lines are read. System 6 leaves `$44000030` alone
  in round 1 and has no settle delay. Its round 1 reads each line twice.
  System 7 waits through an 8-step loop (`$200341C`, `$2003484`, `$20034EC`)
  before every read. I read this as a timing fix.

Service table (vector 66): the handlers are the same code in the same order,
except for these:

| service | System 6 | System 7 | difference |
|---|---|---|---|
| dispatcher | `$20010A4` `cpge …, $D5` | `$20011F4` `cpge …, $D6` | the bound follows the table size. Both builds compare it with the *index* (number − `$B6`), not the number, so numbers up to `$18A` (System 6) or `$18B` (System 7) pass the check and jump through words past the table (reading) |
| `$CC` region insert | `$200131C` → `$2001328` | `$200146C` → `$2001478` | System 6 also requires `lr4` to be 1 KB-aligned (`$2001348`-`$2001354`, else −6). System 7's −6 exit (`$20015D8`) is unreachable |
| `$CD` region remove | `$20014B8`, the routine itself | `$20015F8`: `call $2001604`, `iret` | System 6 ends with `iret`, but its error exits (−9, −8, −4 at `$2001480`-`$20014A8`) are the insert routine's `jmpi gr69`, and no call has set `gr69`; its TLB loop also uses `gr69` as the counter. System 7's wrapper makes the errors return properly. Probably a System 6 bug (reading) |
| `$D3` host access mode | `$20016D4` | `$2001820` | TLB scan count only |
| `$D6` | none | `$2001888` | only in System 7 (System 6's Antelope has no stub) |

All other services (`$B8`, `$B9`, `$BB`, `$BF`, `$C0`-`$C8`, `$CB`, `$CE`-`$D2`,
`$D4`, `$D5`, and the −42 entries) are the same code, at the addresses in the
sw11 `RuntimeData.asm`.

**Effect on the host protocol: none for the fields.** The following are
instruction for instruction the same in both builds:

* the Boot handshake: poll PublicIn+0 for `$42005300` (`$2003078`), the data
  copy, the top nibble of PublicOut+`$0C`-`$18`;
* the `'WY1`'` warm-start path (VidComm+`$18`, VidComm+`$08`-`$14` →
  PublicOut+`$1C`-`$28`);
* the kernel init's use of PublicIn+`$04`/`$10`/`$18`/`$40`;
* the mailbox report (`'s337'`/`$96666669` at `$4C007000`) and the reason
  codes;
* the VidComm command service, including PublicIn+`$3D4` restart and the
  page permutation;
* the HIF services.

A host driver written for one kernel works with the other. What differs is
what the card reports: PublicOut+`$28` for a PAL monitor (560 against 576),
and the 16" and PAL-alternate monitors, which System 6's kernel does not
recognize. Those take the default 480 lines (`$1E0`) in Boot and row `$50` in
init (reading). Service `$D6` is missing too.

### System 6 against System 7, function by function (`antelope_compare.py`)

A function runs from one `.text` symbol to the next. The tool compares
each function's words with relocated words reduced to their opcode byte
and call displacements dropped, aligns the two function lists in order on
that, and pairs the leftovers of a replaced stretch in order when their
opcode sequences have a difflib ratio of at least 0.6:

| | functions | words |
|---|---|---|
| System 7 / System 6 | 768 / 769 | 62,134 / 68,278 |
| identical | 620 | |
| changed (ratio ≥ 0.6) | 66 | |
| only in System 7 | 82 | 6,298 |
| only in System 6 | 83 | 12,020 |

So the 620 identical functions are the same code, relinked. Five changed
pairs have ratio 1.00: the same opcodes with a different operand (for
example one load's option field in TrimRect, `$019B8`, and three
constants 4 higher in InitPacket). The tool does not pair code that moved
out of order, so some "only" entries have a counterpart elsewhere (below).

**Every named function has a System 6 counterpart.** Of the 103 names in
`antelope_names.py`, 76 are on identical functions. Among them are Report,
the burst fills and copies, RSect, ITabMatch, the whole cache
(`CacheFind` … `CacheRelease`, `UploadFontStrike`, `UploadWidthTable`,
`ConvertFontStrike`), PQDAlloc, FillLongs, GetSeek, CallBack, HeapFree,
SelfTest and its tests, the storem fills and the C library. 25 have
changed; by size and ratio the largest changes are:

| function | System 7 | System 6 | words 7 → 6 | ratio |
|---|---|---|---|---|
| CommandDispatcher | `$31E20` | `$2D614` | 682 → 934 | 0.77 |
| StretchBits | `$2D7B8` | `$28C14` | 2,612 → 2,798 | 0.65 |
| DrawMultiObject | `$0AD18` | `$0AF74` | 3,487 → 3,726 | 0.88 |
| PQDInit | `$161F8` | `$15B5C` | 479 → 332 | 0.78 |
| MapVirtual | `$3373C` | `$2F2D4` | 216 → 186 | 0.64 |
| UnmapAll | `$33A9C` | `$2F5BC` | 69 → 67 | 0.79 |
| CopyHostMemory | `$16C48` | `$16360` | 197 → 198 | 0.86 |

The rest (TrimRect, BitBlt, BitsToPixMap, ColorMap, DrawArc, DrawLine,
DrawText, IsOnThisCard, CacheGDevice, CachePixPat, QuickPolys, RgnBlt,
scaleBlt, main, InitPacket, ShieldCursor, ShowCursorAfterDraw,
CopyLongsStorem) have a ratio of 0.90 or more. The last two names moved,
so the tool lists them as only in System 7: FlushOffscreen (`$14168`)
matches System 6's `$13ACC` with ratio 0.93, and FillPatternStorem
(`$37C10`) has the same opcodes as System 6's `$3DC84`.
`antelope_compare.py SYS6_ACEF_100.bin SYS7_ACEF_100.bin` prints the full
map.

**Only in System 7** (by their callers):
* `$1E508`-`$200E0`, nine helpers of 186-271 words, each called once by
  RgnBlt: the nine 16-bit arithmetic loops whose System 6 counterparts are
  stubs (`RBAverage16Half` … `RBMin16`, see below). System 7's RgnBlt
  calls them directly at the places where System 6's (`$1A30C`-`$1A52C`)
  calls the stubs through a pointer, in the same order: `$1F9A0`
  (Average16Half), `$1FCA4` (Average16), `$1EB08` (AddPin), `$1E508`
  (AddOver), `$1EECC` (SubPin), `$200E0` (Transparent), `$1F290` (Max),
  `$1E804` (SubOver), `$1F618` (Min). The Pin, Over and Max/Min pairs
  have matching sizes (241/241, 191/193, 226/226);
* `$0F730`-`$10140`, eight helpers of the switch function at `$1114C`: the
  pattern-slab loops for the eight 16-bit arithmetic modes. Where System 6's
  `$10C3C` returns the addresses of the stubs `PatAverageSlab16` …
  `PatMinSlab16` (cases `$10DBC`-`$10E10`, table `.lit $06B8`), System 7's
  `$1114C` returns, in the same case order, `$0FF60`, `$0F978`, `$0F730`,
  `$0FB08`, `$10140`, `$0FC98`, `$0F850`, `$0FDFC` (`$112CC`-`$11320`,
  `.lit $0508`);
* `$37730`-`$37B58`, the module support: `$37730` sends host request 999
  (`$3E7`) through CallBack, and the `$80xx` service switch `sub_379A0` is
  called from the dispatcher through `$37B58` (see "The `$80xx`
  commands"). `sub_379A0` calls UnmapAll, `$16BA0`, `$37730` and five
  small accessors at `$13FCC`-`$14020`. System 7's dispatcher tests
  `(command & $FF00) == $8000` (`$31F8C`-`$31F9C`); System 6's has no
  `$8000` constant at all, so the host-loaded modules (`$8001`, "call code
  at a host-given address") are new in System 7;
* `$140CC`, a dispatcher case (loaded at `$32558`) that calls CacheRelease;
* `$18278` (389 words, called by `$17C60` and StretchBits) and a run of
  StretchBits helpers at `$27944`-`$2CFD4`. They include the Stretch
  16-bit arithmetic loops: where System 6's StretchBits selects the stubs
  `StretchAverage16` … `StretchMin16` with an 8-way switch (`.lit $0CF0`,
  `jmpi` at `$2A614`), System 7's has the same switch (`.lit $0BB0`,
  `$2F8A0`) over `$27EF4` (AddPin), `$27D44` (AddOver), `$28040` (SubPin),
  `$28654` (Transparent), `$28190` (Max), `$27E18` (SubOver) and `$282B0`
  (Min); its case 0 picks `$283D0` or `$284D4` after comparing a 16-bit
  value with `$7FFF` and `$8000`. (An earlier version of this section named
  `$27944`, `$27ACC`, `$27B48`, `$27BBC` as these loops. They are the
  four-way set at `$2F97C`-`$2F9A0` that System 6 has as `$25090`,
  `$25120`, `$2519C`, `$25210`; `$27ACC` and `$27B48` have the same
  opcodes as `$25120` and `$2519C`.)

**Only in System 6:**
* a block of 43 functions, 10,928 words, between HeapFree and
  FillPatternStorem (`$331C4`-`$3DC84`, object files 28-30): **a QuickTime
  codec on the card** (see below). It is led by `$33218` (4,259 words:
  mostly `add`/`sub`/shifts, few loads: 94), `$374A4` (2,579), `$3B27C`
  (1,274, called by `$33218`) and `$3CA64` (1,001 words with six inline
  divisions, 186 `div` steps, and no reference in the listing);
* 26 functions of 11 words at `$01378`-`$017C4`, each of which only
  passes a `.lit` string to `$00E88` and returns. `$00E88` is an empty
  function (`jmpi lr0`, as System 7's `$00F78`). The strings are the stubs'
  names (`.lit $0000`-`$018C`): `Bogus`, then QuickDraw's 16-bit
  arithmetic-mode loops for RgnBlt, Stretch and the pattern slab:
  `RBAverage16Half`, `RBAverage16`, `RBAddPin16`, … `RBMin16`;
  `StretchAverage16` … `StretchMin16`; `PatAverageSlab16` …
  `PatMinSlab16`. The order is that of `rArith16Tab` in the 7.1
  `RgnBlt.a` (Avg, AddPin, AddOver, SubPin, Transparent, Max, SubOver, Min;
  `rAvg16Half` is its case `$28`). So System 6's card had placeholders for
  the 16-bit arithmetic modes. RgnBlt (`$193C8`), StretchBits (`$28C14`)
  and the slab setup (`$10C3C`) load the stubs' addresses as their loop
  pointers, and `$11524` loads the `Bogus` stub `$01378`, as System 7's
  `$11A34` loads its `$01468` (which also passes `Bogus`, to `$00F78`).
  The tool pairs that one with System 6's last stub `$017C4` (same shape),
  so 25 of the 26 are listed as only in System 6.

**The block is the card side of a QuickTime codec, commands `$39`-`$3B`.**
(An earlier version of this section called the block and the stubs
unreferenced. That was wrong: a relocation whose symbol has section -3 names
the *next* symbol, and the first scan missed those.) The address loads into
the block from outside it are all in the dispatcher `$2D614`, in the case
blocks of three commands that System 7 sends to the default (its
`.lit $0EC4`-`$0ECC` all point to `$32818`). System 6's table is
`.lit $0F18` (`cpgtu $3B` at `$2D77C`), entries `$0FFC`-`$1004`:

| command | case block | loads | alternative path (`'rle '`) |
|---|---|---|---|
| `$39` | `$2DF60` | `$374A4` | `$2E024`: `$3A964` |
| `$3A` | `$2E0F0` | `$33218` | `$2E1A0`: `$3A254` |
| `$3B` | `$2E258` | `$33218` | `$2E340`: `$33218` |

Each case reads its argument record (`rec = [.bss+4]`, `[rec+$10]`) and
compares the first word with `$72707A61` (`const $7A61`, `consth $7270`):
`'rpza'`, the four-character code of Apple Video ("Road Pizza"). If it
matches, the case loads the rest of the record (`+$04`-`+$2C` for `$39`,
`+$04`-`+$28` for `$3A`, `+$04`-`+$3C` for `$3B`: the 11, 10 and 15 longs
after the type that the host sends) and calls the block. Otherwise it
compares with `$726C6520`, `'rle '`, and takes the
alternative path; any other type stores 0. The result goes to
`[.bss+0]+$1C`. System 6's
host driver (`gc24` ID -4048) holds the component name "8·24GC Road Pizza"
and five comparisons with `'rpza'`, three of them next to one with `'rle '`.
So SW 1.1 shipped a QuickTime image codec component that
ran Apple Video on the Am29000. System 7's card dropped the codec, and its
commands `$39`-`$3B` fall to the default.

**Which routine does what.** The immediates tell the two `'rpza'`
routines apart:
* `$374A4` is the **decoder**. It masks with `$E0` and compares with `$80`,
  `$A0`, `$C0`, `$E0` (skip, one colour, four colours, and `$E0`, the chunk
  header, which `$376EC` skips without counting a block; a 16-colour block
  has no opcode: a byte below `$80` with bit 15 of the second colour word
  clear, `$37764`-`$377C0`) and once with `$E1` (the chunk header byte). It is entered by command `$39`.
* `$33218` is the **encoder**. It ORs `$80`, `$A0` and `$C0` into opcode
  bytes, and it is the larger one: 4,259 words of colour arithmetic (`and
  $1F` with shifts by 5 and 10, the fields of a 16-bit pixel), dividing
  through `div_millicode`. It is entered by commands `$3A` and `$3B`.
* For `'rle '`, `$39` calls `$3A964` and `$3A` calls `$3A254`; `$3B` calls
  `$33218` for both types, so `$3B` with `'rle '` runs the `'rpza'` encoder.
  `$3A254`'s previous-frame code is unreachable, since `$3A` passes 0 in
  slot 6.

**The decoder's layout.** `$374A4` (2,579 words) first calls MapVirtual
(`$2F2D4`). It reads the first byte (byte reader `$3DA34`) and
compares it with `$E1` (`$375D4`): with `$E1` it runs `$375DC`-`$38BB0`, which uses compare
chains, otherwise `$38BB0`-`$39CF0`, which uses four 8-way jump tables on
the top bits of a word (`srl $1C`, `sub 8`, `cpgtu 7`; `.lit $1248`,
`$1268`, `$1288`, `$12A8`). Each half splits on a local holding the
destination depth (`cpneq` with `$20`, `$10` and `$08`; any other depth
exits) into a 32-bit, a 16-bit and two 8-bit copies of the block loop
(the two chosen by bit 6 of argument 5: clear, a 32 KB colour-to-byte table; set, a four-candidate table with a 4×4 ordered dither, `$37E78`-`$37EC8`). In the first half each copy
has its `and $E0`/`$80`/`$A0`/`$C0`/`$E0` tests, and the 8-bit copies add
`and 1/2/3` and `cplt 4` steps. The stream readers `$3DA5C` (16 bits at
any alignment, loaded at 7 places) and `$3DAAC` (32 bits, 11 places) are
in object file 30. Note that the host's `$9BBA` sends `$39` only for a
16-bit PixMap, so the 8- and 32-bit copies are not used through it.

**The codec's switch tables (`sw11` `lit.asm`).** All 167 entries of the
`.lit` group with base `$331C0` (`.lit $10F0`-`$1388`) are the codec's,
in 25 switches:

| `.lit` | switch at | cases | targets |
|---|---|---|---|
| `$10F0` | `$33414` (encoder) | 5 (`cpgtu 4`) | `$3339C`, `$333A4`, `$333AC`, `$333C8`, `$333D4`: all before the `jmpi`, so the switch sits at the bottom of a loop |
| `$1104` | `$34EE8` (encoder) | 17 (`cpgtu $10`), on a pixel count `n` | cases 0, 1, 2, 4, 8, 12, 14, 15, 16 at `$34EF0` (right after the `jmpi`), `$34F2C`, `$34F58`, `$34F8C`, `$34FC0`, `$34FDC`, `$35010`, `$35044`, `$35070`; the other eight at `$350AC` |
| `$1148`-`$1238` | `$35B54`-`$36DD4` (encoder) | 16 switches of 4 | case `i` at `jmpi + 8 + $3C·i`, in all 16 |
| `$1248`-`$12A8` | `$38D6C`, `$3919C`, `$39580`, `$39A74` (`'rpza'` decoder) | 4 switches of 8 | in each: case 0 right after the `jmpi`, case 4 and the shared cases 6/7 further on (`$38E20`/`$38E44`, `$39220`/`$39244`, `$39630`/`$39660`, `$39B00`/`$39B30`); cases 1, 2, 3 and 5 go to the switch's default, the same place as an index above 7. That is `$38E4C` in the first table (its `cpgtu`/`jmpt` at `$38D4C`/`$38D50`) and `$39CAC`, the decoder's exit, in the other three |
| `$12C8` | `$3ACD8` (`$3A964`, the `'rle '` path) | 16 (`cpgtu $0F`), index `(a << 2) \| (lr5 & 3)` | four targets `T0`-`T3` = `$3ABC8`, `$3AC14`, `$3AC60`, `$3B250`; case `4a+b` goes to `T[(b - a + 3) mod 4]`: a 4×4 ordered dither |
| `$1308` | `$3AF28` (the same) | 16 | the same rotation over `$3AE18`, `$3AE64`, `$3AEB0`, `$3B264` |
| `$1348` | `$3BEBC` (in `$3B27C`, called only by the encoder, `$3338C`) | 17 | the same shape as `$1104`: cases 0, 1, 2, 4, 8, 12, 14, 15, 16 at `$3BEC4` (right after the `jmpi`), `$3BF00`, `$3BF2C`, `$3BF60`, `$3BF94`, `$3BFB0`, `$3BFE4`, `$3C018`, `$3C044`; the rest at `$3C080` |

What the tables show:
* **The four-way switches are unrolled per pixel.** Case `i` lies at
  `jmpi + 8 + $3C·i`, so case 0 starts right after the delay slot and each
  case is 15 words. There is one switch per pixel of the 4×4 block. The
  indices are computed before them (`$35864`-`$35B24`, by luminance
  thresholds); each switch adds that pixel's error `|ΔR|+|ΔG|+|ΔB|` against
  palette entry `i` (`$35B5C`-`$35C48`), and the code falls back to a raw
  16-colour block when the maximum reaches `lr44` or the total `6·lr44`
  (`$35C64`, `$36EE0`).
* **The two 17-way switches split a 4×4 block's pixels into two groups and
  average each.** Before `$34EE8`, an unrolled sequence tests, for each of
  the 16 pixels, the sign of its luminance `5R + 9G + 2B` minus the
  block's mean luminance (`$34BA8`; the means are summed while loading,
  `$334D0`…). One branch adds the pixel's
  fields to one set of sums and increments `lr80`, the other adds them to
  a second set. The switch index is `lr80`, the number `n` of the 16
  pixels in the first group, so the second group has `16 - n`. The own
  cases are exactly the `n` where `n` or `16 - n` is a power of two (or
  0): there the average is a shift (`sra` by 4, 3, 2 or 1), and the other
  group's sums go through `div_millicode` (`calli` to `$41950`). The
  shared default divides both. The averages are packed as 5-5-5 colours
  (`sra 3`, `sll 10`, `sll 5`): the two colours of an `'rpza'` four-colour
  block, after both are pushed apart by an eighth of their difference
  (`$35134`-`$35190`). `n` = 0 or 16 marks the block solid. The card's
  palette is A, ¾A+¼B, ¼A+¾B, B (`$3C6B0`-`$3C6F4`, `$379B0`-`$37A0C`), not
  QuickTime's ⅓/⅔ mixtures. `$3BEBC` (in `$3B27C`) is a second copy with the same cases.
* **The `'rle '` rotation is an ordered dither.** The four targets add a
  constant to each of three 8-bit channels, saturating at `$FF`: `T0`
  (`$3ABC8`) adds 4 (`cpge $FC`), `T1` (`$3AC14`) adds 2 (`cpge $FE`), `T2`
  (`$3AC60`) adds 6 (`cpge $FA`), and `T3` (`$3B250`, where the others join)
  adds nothing. The index is `(a << 2) | (lr5 &
  3)`. `lr5` gains each line's skip count and is incremented in the delay
  slot of the per-pixel loop (`$3AD98`), but in the 32-bit path it is never
  initialised or reset per line, so `b` is the column mod 4 only up to an
  unknown offset; `a = lr27 & 3` (`$3AD50`), the line number mod 4. `T1`
  saturates green at `$FD` (`$3AC40`). The loop
  reads a byte: with bit 7 set, `(b & $7F) + 1` pixels follow in one colour,
  given as three bytes. The matrix is

      row 0:  0 4 2 6
      row 1:  6 0 4 2
      row 2:  2 6 0 4
      row 3:  4 2 6 0

  a 4×4 pattern of 0-6 added before the channels are masked with
  `$F8F8F8`. `$3A964` is the `'rle '` decoder and writes **32-bit** pixels
  (`$3AD84`), so only the precision drops. The matrix applies only when the
  absolute word `[$178]` (the host's `KeyMap+4`) is `$100`, that is, only Tab is held; with 1 the pixel is truncated, with 8
  kept unchanged, and other values select a 2-level frame-alternating dither
  (`$3AD38`-`$3AD7C`). The card's `'rle '` stream is a private line format,
  not the documented Animation format. The second
  table (`$3AF28`) is the same with its own four loops.
* **The decoder's index is the top nibble of a stream word, minus 8.** Before
  each `jmpi` the decoder loads `lr8` from `lr21` (then `lr21 += 4`),
  computes `(lr8 >> 28) - 8`, and sends anything above 7 (unsigned) to the
  default. So the word's top bit must be set, and only nibbles `$8`
  (case 0), `$C` (case 4) and `$E`/`$F` (cases 6/7, shared) have their own
  code. Case 0 of the last 8-bit copy (`$39A7C`) takes a count from bits
  16-25 (`srl $10`, `and $3FF`, plus 1), loads one byte from `lr4` plus
  the word's low 15 bits (`and $7FFF`), and stores it four times per row
  for four rows: it fills 4×4 blocks with one colour. In `'rpza'` itself,
  fill is `$A0` with a 5-bit count; this half runs only when the first
  byte is not `$E1`. It reads the aligned word format written by the
  unreferenced `$3CA64`: `$E0000000 | len` per block row (`$3CAA4`, patched
  at `$3D9C4`), fill words `$80000000 | n << 16 | colour`
  (`$3D5F8`-`$3D608`) and single 4-colour blocks (`$3D93C`-`$3D94C`); the
  decoder also accepts skips, 4-colour runs and 16-colour blocks (`$38F00`).
* **The decoder's exit.** `$39CAC` calls UnmapAll (`$2F5BC`, System 7's
  `$33A9C`) and returns 1. That is not a result: the host was released by
  `$2E69C(1)` at `$375A4`, before decoding. 23 jumps (among them the out-of-range branches
  and the unknown-depth exits) and 12 table entries land on it. In the
  first table cases 1, 2, 3 and 5 instead go to `$38E4C`, that table's
  default, which returns -1 without unmapping.

**The host side** (System 6 `gc24`, 68020 code at `$8580`-`$A1D0`). `$8580`
passes (codec type, parameter block, selector, instance) to `$9510`.
`$9510` accepts only `'rpza'` and `'rle '` (otherwise `-8939`) and switches
on selector `$10`-`$19`:

| selector | routine | does |
|---|---|---|
| `$10` | `$9BBA` Codec_Decompress | decompress: sends `$39` (12 longs) |
| `$11` | `$9BBA` | decompress estimate only: size 3·w·h, time 500/(w·h), no card call (`$9F8E`-`$9FD6`) |
| `$12` | `$9752` Codec_Compress | compress: sends `$3A` (11 longs) |
| `$13` | `$9752` | compress estimate only: maximum size and time, no card call |
| `$14` | `$9752` | compress with a previous frame (32-bit, pixelType 16): sends `$3B` (16 longs) |
| `$15` | | returns 0 |
| `$16` | `$A0B4` Codec_GetInfo | codec info: name "8·24GC Road Pizza", vendor `'appl'`, version 4, flags `$43001`/`$4009` |
| `$17` | `$A124` | returns -1 |
| `$18` | `$A110` | unimplemented: returns -8939 |
| `$19` | `$A19A` Codec_Close | close: disposes the state handle (the dither table is leaked) |

The selectors do not follow QuickTime 1.0's codec order, and of its error
codes only `$DD00` (-8960, codecErr) is a released one; `$DD02`, `$DD04`,
`$DD08` and `$DD15` look like pre-release codes. The calls arrive through
the driver's Control case at `DRVR` `$0F2A`, then GA_ControlFFFFFFFD. Names
are in `gc24_sw11.s` (no MacsBug names here; they come from what each
routine does).

Both senders lock the PixMaps (`_QDExtensions` LockPixels, GetPixBaseAddr,
GetPixelsState) and pass base addresses, row bytes (`& $3FFF`), bounds
and depth to the card, then wait for the reply.
* `$9BBA` requires a 16-bit PixMap for `'rpza'` (else `-8956`). Only selector
  `$11` returns a size and a time estimate through two output pointers. At
  8 bpp with flags bit 6 it passes a dither table built at `$A1D2`
  (Codec_BuildDitherTable: 5-5-5 colour to four error-diffused 8-bit
  indices, `$20008` bytes).
* `$9752` takes a PixMap of depth 8, 16 or 32 for `'rpza'`, and only 32 for
  `'rle '`. At depth 8 it uses the PixMap's colour table. It returns the
  card's reply (the compressed byte count) through its size pointer.

The direction comes from the card's opcode tests. The host side does not
name it.

Of System 6's 618 direct calls, none goes into the block from outside, and
`.lit`/`.data` hold no pointers into it apart from its own switch tables,
so the dispatcher's six address loads (and `calli`) are its only entries.
Inside it, `$33218` calls `$3B27C` and the output byte, long and word
stores `$331C4`, `$331D0` and `$33200` (13, 20 and 17 calls), `$374A4` calls
`$39CF0`, and `$3C668`, `$3C7C4`, `$3DA08`, `$3DA34`, `$3DA5C` and `$3DAAC`
are loaded as function pointers; `$3B27C` loads `$3DA14`, `$3DA20`, `$3DA28`
and `$3DB68`, and `$374A4` and `$3A964` load `$2E69C` (outside the block),
the early reply. Eight functions in it have no reference at all: `$39E50`,
`$39EB4`, `$3A0CC`, `$3C810`, `$3C904`, `$3C94C`, `$3CA3C` and `$3CA64` (a
second, word-aligned `'rpza'` encoder for 32-bit sources, whose output is the
format the decoder's non-`$E1` half reads); `$3DBC4` is reached by falling
through from `$3DBBC`.

There are no floating-point instructions in either version, so the block is
not a floating-point trap emulator.

#### The codec, step by step

**The arguments.** The case blocks copy the record longs after the type into
the callee's argument registers in order, with two exceptions: `$3A` puts two
zeros in slots 6 and 7, and `$3B` passes all 15. So `$3A` is `$3B` without a
previous frame.

| slot | decoder `$374A4` (`$39`) | encoder `$33218` (`$3A` / `$3B`) |
|---|---|---|
| 0 | `+$04` compressed data | `+$04` output buffer |
| 1 | `+$08` not used (register overwritten before any read) | `+$08` not used |
| 2 | `+$0C` Rect (top, left, bottom, right; mapped, 8 bytes) | `+$0C` not used |
| 3, 4 | `+$10`, `+$14` not used | `+$10` not used; `+$14` Rect |
| 5 | `+$18` flags: bit 6 = dither at 8 bpp | `+$18` quality word (see below) |
| 6 | `+$1C` not used | 0 / `+$1C` previous-frame flag (only `≠ 0` is used) |
| 7 | `+$20` destination base | 0 / `+$20` skip thresholds: `avg << 16 \| max` |
| 8 | `+$24` destination row bytes | `+$1C` / `+$24` source base |
| 9 | `+$28` destination depth | `+$20` / `+$28` source row bytes |
| 10 | `+$2C` 8-bit lookup table (mapped `$20008` bytes) | `+$24` / `+$2C` source depth |
| 11-13 | | — / `+$30`-`+$38` previous frame: base, row bytes, depth |
| 14 | | — / `+$3C` not used (`lr102` is cleared first) |

Both routines map their buffers with MapVirtual (`$2F2D4`): the Rect, the
pixels (`height × rowBytes`), the stream (`3 × width × height` bytes), and
remap the others if a later mapping moved them. Both work on
`width >> 2` by `height >> 2` blocks (`sra 2`). **Pixels past the last whole
block on the right or bottom are neither encoded nor decoded.** There is no
clipping beyond the Rect.

##### The decoder `$374A4`

**Setup.** `lr19` = `$7FFF`, or `$7BFE` if bit 0 of the word at absolute
address `$178` is set (no relocation: the Mac's `KeyMap+4`, so Shift is down; see "The absolute addresses `$178` and `4`"). The mask is used only by
the dithered 8-bit copies. After mapping, `$374A4` calls `$2E69C(1)`. That
routine (outside the block) stores the reply word unless it is 1, waits until
bit 2 of packet `+$18` is clear, stores 1 to `*[packet+$20]`, and sets packet
`+$18` = 1. So **the host is answered before the decode starts** and the card
decodes while the host runs on (likely reading; `$3A964` does the same, the
encoder does not). Then it calls InitReader `$3DA08` (stream) and peeks the
first byte with `$3DA34` without advancing.

**The byte stream (first byte `$E1`, `$375DC`-`$38BB0`).** The format is
public `'rpza'`. Each block row starts at `dst + row × 4 × rowBytes`. Per
opcode byte `b` (read without advancing; each case adds its own length), `n`
= `b & $1F`:

| `b` | case (32 bpp) | does |
|---|---|---|
| `$80`-`$9F` | `$376CC` | skip `n+1` blocks: `dst += 16(n+1)` |
| `$A0`-`$BF` | `$37638` | one colour (`ReadHalf & $7FFF`), `n+1` blocks, each `FillBlock32` `$3C7C4` |
| `$C0`-`$DF` | `$376F8` | `ReadLong` = colour A `<< 16` \| colour B; then `n+1` index longs, each block `Rpza4ColorBlockTo32` `$3C668` |
| `$E0`-`$FF` | `$376EC` | skip 4 bytes, count no block (`lr27 -= 1`): the `$E1` + 24-bit size header. The first byte is read again here, so the header is consumed by the loop. The size is never checked |
| `$00`-`$7F` | `$37764` | `ReadLong` from the opcode byte on. If bit 15 of its low word is set: one 4-colour block (indices = next long), 8 bytes. Otherwise one 16-colour block: `Rpza16ColorBlockTo32` `$39CF0` reads 16 words, 32 bytes |

The block counter `lr27` grows by `n+1` per opcode and is tested only between
opcodes, and the pointer goes on linearly. **A run is not wrapped into the next
block row**: blocks past the row's end land to the right of the Rect in the
same four lines, and the next row starts at column 0 again. (ffmpeg's decoder
wraps; the card's own encoder never makes such a run, see below.) After the
last row: `$39CAC`, UnmapAll, return 1.

**The four colours are at 0, 1/4, 3/4, 1, not 1/3, 2/3.** All copies expand A
and B to 8 bits (`<< 3`, low bits zero), take `m = (A+B)/2`, then
`c1 = (B+m)/2` and `c2 = (A+m)/2`, per channel with `sra 1`. Index 0 = B (the
second word), 1 = `c1` (¾B + ¼A), 2 = `c2` (¾A + ¼B), 3 = A; 2-bit indices
MSB first, one byte per row (`lr8 & $C0000000`, `sll 2`). The 16- and 8-bit
copies cut the mixtures back to 5-5-5 (`sra 3`).

**Per depth** (`lr27` = arg 9; anything but `$20`, `$10`, `$08` exits):

* **32 bpp:** pixel = `R<<3 << 16 | G<<3 << 8 | B<<3` (no low-bit
  replication); row skip `rowBytes - 16`. Helpers `$3C7C4` (fill, `storem`
  of four longs × 4 rows), `$3C668` (4-colour: palette in `gr100`-`gr103`, one
  `store` through `IPA` per pixel, `jmpfdec` × 4 rows), `$39CF0` (16 words via
  `$3DA5C`).
* **16 bpp** (`$37824`): halfword stores, inline. Fill and 4-colour colours
  are masked with `$7FFF`; the 16 raw words of a 16-colour block are stored
  unmasked.
* **8 bpp, two copies by arg 5 bit 6** (`sll lr23, $19`):
  * bit clear (`$385C4`): pixel = `table[colour]`, a byte per 15-bit colour
    (`lr4 + colour`, no mask).
  * bit set (`$37DE0`): a 4×4 ordered dither with a four-candidate table:
    pixel = `table[8 + 4 × (colour & lr19) + ((r' + x) & 3)]`, where `x` and
    `r` are the pixel's column and row in the block and `r'` is `r` with its
    two bits swapped (`(r&1)<<1 | (r&2)>>1`). That is the pattern

        row 0: 0 1 2 3
        row 1: 2 3 0 1
        row 2: 1 2 3 0
        row 3: 3 0 1 2

    The mapped size, `$20008` = 8 + 32768 × 4, fits this layout. What the
    8-byte head holds was not traced.

**The word stream (any other first byte, `$38BB0`-`$39CF0`).** It is the same
block code in aligned 32-bit words. **It is the format of `$3CA64`**, the
unreferenced encoder below. Per block, `w = [lr21]` (plain `load`, no byte
reader), tested on `w & $80008000`:

| `w & $80008000` | does |
|---|---|
| `0` | 16-colour block, 16 halfwords (32 bytes) |
| `$00008000` | one 4-colour block: `w` = A `<< 16` \| B\|`$8000`, next word = indices |
| `$80008000` | 4-colour run: `w` = colours, next word's low half = `n`, then `n+1` index words |
| `$80000000` | the 8-way switch on `(w >> 28) - 8` (`.lit $1248` etc.): `$8` = fill, `n` = bits 16-25 (`& $3FF`), colour = `w & $7FFF`; `$C` = skip `n+1` blocks (same `n`); `$E`/`$F` = a row header, no block; `$9`, `$A`, `$B`, `$D` = error |

The error exit is `$38E4C` in the 32-bit copy (return -1, without UnmapAll)
and `$39CAC` in the other three. The depth split and the two 8-bit copies are
the same as in the byte half (`$38FDC` `cpneq $10`, `$393BC` `cpneq $08` and
`sll lr23, $19`). (A row header whose length has bit 15 set would read as a
4-colour run. That is a latent bug.)

##### The encoder `$33218`

**Setup.** `lr9`/`lr10` = the skip thresholds (arg 7 high/low halves); `lr18` =
(arg 6 ≠ 0), the previous-frame flag. Then come the maps: the source
`height × rowBytes`, the output `3 × width × height`, and the previous frame.
InitReader `$3DA08` is called on the output (its result is unused, since the
encoder stores bytes itself). The output pointer `lr34` = `out + 4`, which leaves
room for the header. `lr95` = svc_111 (HIF clock), called once per block
(`$334A4`) and before each raw block (`$36F78`). Its result is unused; the
purpose is unknown.

**The quality word (arg 5)** gives two thresholds: `lr45`, the solid
threshold, and `lr44`, the raw threshold (`lr43 = 6 × lr44`). The high half
selects a level through `.lit $10F0` (`$333EC`, index `(q >> 16) - 1`);
anything above 5 or 0 takes the low bytes as given:

| `q >> 16` | case | `lr45` (solid if distance below) | `lr44` (raw if max error ≥; total ≥ 6×) |
|---|---|---|---|
| 1 | `$3339C` | 50 | `$FF` = never |
| 2 | `$333A4` | 20 | never |
| 3 | `$333AC` | 7 | never |
| 4 | `$333C8` | 1 | 105 (total 630) |
| 5 | `$333D4` | 1 | 50 (total 300) |
| 0, > 5 | `$333E0` | `q & $FF` | `(q >> 8) & $FF` |

`lr45 ≤ 0` disables solid blocks altogether (`cplt lr45, 1` → `$35320`).
Quality word exactly `$30000` without a previous frame calls the fast path
`$3B27C` instead (`$33370`-`$33394`).

**Source pixels.** At depth 32 (`lr33` = depth ≠ 32 is false), each of the 16
pixels is a long, split into 8-bit R, G, B. Any other depth is read as 16-bit
5-5-5 and expanded with `<< 3`. Depth 8 is not handled separately; for it,
`lr12`, the bytes per pixel, is never set. For each pixel the luminance
`Y = 5R + 9G + 2B` is computed (`sll 2`+, `sll 3`+, `sll 1`), and their sum,
`>> 4`, is the block mean `Ȳ` (`gr118`).

**Temporal skip (only with a previous frame).** The previous frame is 32- or
16-bit by arg 13. Per pixel, `d = |ΔR| + |ΔG| + |ΔB|` against the same pixel
there; the code keeps the sum `gr117` and the max `gr116`. The block is skipped
if `sum >> 4 < avg` **and** `max < max-threshold` (`$34A94`). A skip first
flushes a pending 4-colour run. The first skip writes `$80` and remembers its
position (`lr13`). Each further skip rewrites that byte as `$80 | k`. After
`$9F` (32 blocks) a new `$80` follows. A skip also ends a fill run (`lr28 = -1`).

**Two groups and their means** (`$34BA8`-`$350E8`). Pixels with `Y > Ȳ` go to
the bright group (sums `lr0`, `gr124`, `gr100`, count `n` = `lr80`), the others
to the dark group (`lr79`, `lr3`, `lr2`). The 17-way switch on `n`
(`.lit $1104`) divides the sums:

| `n` | bright | dark |
|---|---|---|
| 0, 16 | all pixels `>> 4`; the block is solid (`gr96 = 1`) | — |
| 1 / 15 | as is / `÷ 15` | `÷ 15` / as is |
| 2 / 14 | `>> 1` / `÷ 14` | `÷ 14` / `>> 1` |
| 4 / 12 | `>> 2` / `÷ 12` | `÷ 12` / `>> 2` |
| 8 | `>> 3` | `>> 3` |
| others (`$350AC`) | `÷ n` | `÷ (16 - n)` |

**The endpoints** (`$350F0`). `D = |ΔR| + |ΔG| + |ΔB|` between the two means
(`lr85`). Each endpoint is pushed out by an eighth of the difference
(`bright + Δ/8`, `dark - Δ/8`, `sra 3`). If any channel leaves 0-255 (any of
the six ORed `>> 8` ≠ 0), the unextended means are kept. Then:

* `D < lr45` (and `lr45 > 0`): solid, colour = `(bright + dark) / 2`. This is
  the plain average of the two means, not weighted by `n`.
* otherwise `lr8` = dark, `lr7` = bright as 5-5-5 (`sra 3`). If they are
  equal, the block is solid as well.

**Solid blocks become fill runs** (`$3522C`-`$3531C`). A pending 4-colour run
is flushed first. A new colour writes `$A0` + the colour word and remembers the
opcode position (`lr4`) and colour (`lr28`). The same colour as the last block
rewrites the opcode as `$A0 | k`. At `k = $1F` the run is closed (`lr28 = -1`).

**Four-colour indices** (`$3532C`, or `$357A4` when `lr44 ≠ $FF`). The code
takes `Yd` and `Yb` of the two endpoints, `mid = (Yd + Yb)/2`,
`t1 = (3Yd + mid)/4 = (7Yd + Yb)/8` and `t3 = (7Yb + Yd)/8`. Per pixel, in
raster order with the first pixel in the top bits: index 0 if `Y ≤ t1`, 1 if
`≤ mid`, 2 if `≤ t3`, else 3. These are the nearest-luminance cut points for
the decoder's 0, ¼, ¾, 1 palette.

**The 16-colour test** (`$357A4`, only when `lr44 ≠ $FF`). The two mixtures are
computed as the decoder does them: `(3·dark + bright)/4` and
`(3·bright + dark)/4`. **The 16 four-way switches** (`.lit $1148`-`$1238`,
case `i` = index `i`) add, per pixel, `|ΔR| + |ΔG| + |ΔB|` between the pixel
and its palette colour to a total `gr102`. The largest per-pixel error goes to
`gr101`. As soon as `gr101 ≥ lr44`, or at the end if the total is `≥ 6·lr44`
(`$36EE0`-`$36EEC`), the block is written raw (`$36EF4`): a pending 4-colour
run is flushed, then 16 colour words go out (5-5-5, top bit clear) with no
opcode.

**Four-colour runs are written optimistically** (`$37244`-`$3730C`, the same
at `$35668`-`$3579C`). Every 4-colour block is first written in the
single-block form: the long `bright << 16 | dark | $8000`, then the index
long (8 bytes). `lr39` = where the run's first block went, `lr16`/`lr37` = its
colours, `lr15` = blocks − 1, and the index longs are kept in `.bss+$30`. A
following block with the same two colours (`lr15 < $1F`) adds its indices.
When the run ends (another kind of block, other colours, 32 blocks, a skip, or
the end of the block row), the code rewrites it from `lr39` if it has two or
more blocks: `$C0 | lr15`, the long `lr16 << 16 | lr37` (no `$8000`), then the
`lr15 + 1` index longs. It then moves the output pointer back to the end of
that (`lr34 = lr39`). That is `5 + 4k` bytes over the `8k` already written, so
the run always fits.

**The rows.** `lr28`, `lr100` and the 4-colour run are reset or flushed per
block row (`$3347C`, `$37324`). So no run crosses a block row, and the
decoder's lack of wrapping does no harm to its own streams. Source and previous
frame advance by `4 × rowBytes` per block row.

**The end** (`$373C0`). `len = lr34 - out`, the total including the header.
The code stores `$E1000000 | len` at `out` (`$E1` + 24-bit size), also stores
`len` at absolute address 4 (no relocation: the host's low-memory `ResetPC`, presumably a debugging leftover; see below), calls UnmapAll
(`$2F5BC`) and returns `len`. The case block puts it in packet `+$1C`. The
output bytes go out through `$331C4` (byte), `$33200` (big-endian word) and
`$331D0` (big-endian long, four byte stores), so the stream needs no
alignment.

**`$3B27C`, the level-3 key-frame encoder.** Its arguments are (out + 4, source,
row bytes, width, height, depth). It does the same means, extension and
indices, with the solid threshold 7 inline (`cpge gr105, 7` at `$3C160`). It
has no skip, no raw blocks and no `$C0` runs: every 4-colour block is a single
block. Fill runs are counted and written when they end (`$A0 | k`, colour).
Output goes through the buffered writer `$3DA14`/`$3DB68`/`$3DA28`. It returns
the bytes written (0 if the depth is not 16 or 32), and `$33218` adds the
header.

##### The `'rle '` path

`'rle '` here is a private line format, not the Animation stream as
documented later. (Whether QuickTime 1.0 used it was not checked.) Each line
group is:

    long  [skipLines:8][repeat:8][lenLongs:16]
          lenLongs × 4 bytes of packets, 4-byte aligned:
            [skipPixels:8][items:8]  then items codes:
              code ≥ $80: (code & $7F)+1 pixels of one colour, 3 bytes R G B
              code < $80: code+1 pixels, 3 bytes each

**The encoder `$3A254`** (`$3A`) handles 32-bit sources only. At any other
depth it jumps straight to the line end (`$3A3C0` → `$3A848`), so every line
comes out as an empty skip line. Runs need an exact 24-bit match
(`& $FFFFFF`). Runs and literals hold at most 128 pixels (`cpneq …, $80`), a
packet at most 253 items (`cplt $FD`), and skip and repeat counts stop at 255.
An unchanged line becomes `skipLines + 1` of the next header. A line equal to
the previous one becomes `repeat + 1` of the previous header (written into its
byte 1). **The equality test compares only `lenLongs` bytes** (`$3A8BC`: the
counter `gr103` counts bytes up to `lr20`, which is in longs) and never the
lengths, so a line can be dropped as a repeat when only the first quarter of
its data matches. That looks like a bug. The temporal skip (arg 7 = the
threshold for `|ΔR|+|ΔG|+|ΔB|` against arg 11's frame) is dead code: `$3A`
passes 0 in slot 6, and `$3B` with `'rle '` calls the `'rpza'` encoder
`$33218` (`$2E3E4`). It returns the bytes written (no header).

**The decoder `$3A964`** (`$39`) increments a frame counter (`.data+$12C8`),
reads `[$178]` (the host's `KeyMap+4`, as in `$374A4`) into `lr4`, maps, and calls
`$2E69C(1)`. At depth 32 a line group is skipLines (`dst += s × rowBytes`),
then `repeat + 1` lines, each decoded from the same data. Skips advance `dst`
by 4 per pixel; one long is stored per pixel. Each colour is treated by `lr4`:

| `[$178]` | colour stored |
|---|---|
| 1 | `RGB & $F8F8F8` |
| 8 | `RGB` unchanged |
| `$100` | `.lit $12C8`/`$1308` 4×4 ordered dither: add 0/4/2/6 (matrix in the switch-table text, `a` = line & 3, `b` = `lr5` & 3), saturate, `& $F8F8F8` |
| other | 2-level dither: add 4 if `((line & 1) << 1 \| (lr5 & 1)) + frame` is odd, else 0; `& $F8F8F8` |

So the output stays 32 bits per pixel with 5 bits of precision per channel
(what a 16-bit screen would show), except in mode 8. In the 32-bit path,
`lr5` (the column for the dither) is never initialised: it only gains skips
and pixels, so the phase is arbitrary. The `+2` case saturates green to `$FD`,
not `$FF` (`$3AC40`), a typo in the source. At other depths (`$3B03C`) items
are halfwords: bit 15 set = `(w & $7FFF)+1` copies of the next long, otherwise
`w+1` literal longs (two halfwords each). Skips also count in longs, but the
loop bound is the width in pixels (`lr5 < lr21`). The `len` field is skipped,
not used. Which stream feeds this path was not traced. It returns 1.

##### The absolute addresses `$178` and `4`

**They are host addresses, not card variables.** All three accesses are
`const` with no `consth` and no relocation comment, so the address is truly
`$00000178` or `$00000004`:

| where | instruction | access |
|---|---|---|
| `$374AC`/`$374B0` (`$374A4`, `'rpza'` decoder) | `const gr97, $0178` / `load 0, 0, gr97, gr97` | reads a word, tests bit 0 (`sll $1F`) |
| `$3A988`/`$3A98C` (`$3A964`, `'rle '` decoder) | `const gr97, $0178` / `load 0, 0, lr4, gr97` | reads a word into `lr4` |
| `$373D4`/`$373D8` (`$33218`, `'rpza'` encoder end) | `const gr96, $0004` / `store 0, 0, lr89, gr96` | writes `len` |

A scan of both builds' `text.asm` and both kernels (`Hand.asm`, `Boot.asm`)
for an unrelocated `const` below `$400` used as a load/store address finds
only these three. (The two `const gr96, $0000` hits at `$14F94`/`$15B04` are
return values.) The System 7 Antelope has no such access. The kernels only
use `$4Cxxxxxx`, `$44xxxxxx` and `$46xxxxxx`. Neither Antelope's loader nor
the kernel puts anything at card address `$178` or `4`.

**How the card reaches them.** A data TLB miss on an address that lies in no
region of the table at `$4C00316C` is mapped one to one. System 6 `Hand`
`$20005C4`-`$2000748` (System 7 `$2000714`): `gr68 = CHA & $FFFFFC00`, then
`mttlb` and `iret`. The exception is flag bit 30, the debugger watch. Address
0 is in a region only if a `MapVirtual` entry covers host page 0. Both reads
come before the decoder's `MapVirtual` calls in any case. With translation off
(`$D3(0)`) the address is physical anyway. Below `$4C000000`/`$Fs000000`, the
card's data addresses are NuBus addresses: `CopyHostMemory` reads a host block
with plain loads at its host address, masked with `$00FFFFFF` in 24-bit mode
(section 7). So card address `$00000178` is the Mac's address `$178`, read
over NuBus.

**`$178` is `KeyMap+4`.** `SysEqu.a`: `KeyMap EQU $174` ("bitmap of the
keyboard [2 longs]"), `KeypadMap EQU $17C`. The long at `$178` holds key codes
32-63. Key `k` is bit `k & 7` of byte `$174 + (k >> 3)`, so in the big-endian
long, key 56 is bit 0, 59 is bit 3, 48 is bit 8 and 55 is bit 15. The
values the codec tests are exact `cpeq`s (`$3AB84` and `$3ADB4` for 1, `$3AD38`
and `$3AF88` for 8, `$3AD44`-`$3AD48` and `$3AF98` for `$100`):

| `[$178]` | key held | `'rle '` decoder `$3A964` | `'rpza'` decoder `$374A4` |
|---|---|---|---|
| `$00000001` | Shift (56) | truncate, `& $F8F8F8` | bit 0 set: `lr19` = `$7BFE` |
| `$00000008` | Control (59) | colour unchanged | bit 0 clear: `$7FFF` |
| `$00000100` | Tab (48) | 4×4 ordered dither | bit 0 clear: `$7FFF` |
| other (0 = no key; Option `$4`, Caps Lock `$2`, Command `$8000`, combinations) | — | 2-level frame-alternating dither (the default) | `$7FFF`, or `$7BFE` if Shift is among the keys |

So with no key down, `'rle '` uses the frame-alternating dither. Holding Tab,
Shift or Control while a movie plays switches the mode, frame by frame,
because `[$178]` is read at every call. That looks like a developer's switch
for comparing the dither modes, left in the shipped code. `$7BFE` clears the
low bits of red (bit 10) and blue (bit 0) of a 5-5-5 colour.

**Address 4 is the 68k reset vector `ResetPC`** (`SysEqu.a`: `ResetPC EQU
$04`). On the Mac II family the 68k reads it only at reset, from ROM, so the
RAM long is free. Storing each encoded frame's size there reads like a debug
aid, a place where MacsBug can read the last size (`DL 4`). No host code is
known to read it.

Uncertain:
* That a NuBus master access to `$00000000`-`$00FFFFFF` reaches main RAM is
  inferred from `CopyHostMemory`'s direct path, not from a hardware
  document. With host VM, low memory is mapped one to one, so logical and
  physical `$178` agree.
* The System 6 host's `gc24` (`gc24_sw11.s`) has no absolute access to
  `$178` or `4` (its one `$178(a0)`, at `$1044`, is a record offset). The key reading needs
  nothing from the host beyond the Keyboard/ADB driver's normal `KeyMap`
  updates.
* The Tab/Shift/Control assignment depends on the standard bit order of
  `KeyMap` (key `k` = bit `k & 7` of byte `k >> 3`, bit 0 = LSB, as
  `GetKeys` and the ADB keyboard driver use it).

##### The helpers

* `$3DA08`-`$3DB40` (object file 30, asm): a one-word-cached reader.
  `gr112` = the cached word's address, `gr113` = the word. `$3DA34` reads a
  byte (`exbyte` with `BP`), `$3DA5C` a big-endian halfword at any alignment
  (two bytes if odd), `$3DAAC` a long (two halfwords unless aligned). The
  caller advances the address.
* `$3DA14`/`$3DB68`/`$3DA28`/`$3DA20`: a buffered writer. `gr114` = byte
  address, `gr115` = the word being filled. `$3DB68(value, size)` inserts 1,
  2 or 4 bytes with `inbyte`/`inhw` and stores each completed word.
  `$3DA28` stores the partial word, and `$3DA20` returns the address.
* `$331C4`, `$33200`, `$331D0`: byte, word and long stores, byte by byte
  (`store 0, 1`).
* Unreferenced: `$39E50` / `$3C904` fill and `$39EB4` / `$3A0CC` 4- and
  16-colour blocks at double size (each pixel 2×2, 32 bpp); `$3C810` (=
  `$3C94C`, same code) 16 colours from aligned longs to 32 bpp; `$3CA3C` four
  `div` steps after `div0` with the dividend in both halves (operands look
  wrong; meaning unclear); `$3CA64` the word-format encoder: 32-bit source,
  per block row a header long `$E0000000 | (len - 4)` (low 16 bits, patched
  at `$3D9C4`), fill words `$80000000 | n << 16 | colour`, single 4-colour
  blocks. It writes no skips, raw blocks or runs of 4-colour blocks.

##### The codec's functions (System 6 addresses)

| address | name | evidence |
|---|---|---|
| `$331C4` | `PutByte` | `store 0, 1, lr3, lr2` (byte store); 13 calls from the encoder writing opcodes |
| `$331D0` | `PutLongBE` | four byte stores of `lr3 >> 24, >> 16, >> 8, lr3`; writes the colour and index longs |
| `$33200` | `PutWordBE` | two byte stores (`sra 8`, low); writes fill colours and raw words |
| `$33218` | `RpzaCompress` | entry of `$3A`/`$3B`; ORs `$80`/`$A0`/`$C0`; ends with `$E1000000 \| len` |
| `$374A4` | `RpzaDecompress` | entry of `$39`; `$E1` test; opcode classes `$80`-`$E0` |
| `$39CF0` | `Rpza16ColorBlockTo32` | 16 × `$3DA5C`, 555 → 888, 4 longs × 4 rows |
| `$39E50` | `FillBlock32x2` | 8 stores × 8 rows of one long (unreferenced) |
| `$39EB4` | `Rpza4ColorBlockTo32x2` | same palette as `$3C668`, each index stored 2×2 (unreferenced) |
| `$3A0CC` | `Rpza16ColorBlockTo32x2` | 16 halfwords, each stored 2×2 (unreferenced) |
| `$3A254` | `RleCompress32` | entry of `$3A` `'rle '`; `$80 \| (n-1)` + 3 bytes; line headers |
| `$3A964` | `RleDecompress` | entry of `$39` `'rle '`; reads those codes; dither switches `.lit $12C8`/`$1308` |
| `$3B27C` | `RpzaCompressKeyQ3` | called only for quality `$30000` without a previous frame; threshold 7 inline; no skips/raw/`$C0` |
| `$3C664` | (tag word of `$3C668`) | only `.word $00060000` |
| `$3C668` | `Rpza4ColorBlockTo32` | builds the 4-colour palette, `IPA` store per 2-bit index |
| `$3C740` | (`$3C668`'s row loop) | `jmpfdec gr104` target |
| `$3C7C4` | `FillBlock32` | `storem` of 4 equal longs × 4 rows |
| `$3C810` | `Rgb555BlockTo32` | aligned longs of two 555 pixels → 32 bpp, 4 rows (unreferenced) |
| `$3C904` | `FillBlock32x2Burst` | `storem` of 8 longs × 8 rows (unreferenced) |
| `$3C94C` | `Rgb555BlockTo32` (copy) | instruction-for-instruction the same as `$3C810` (unreferenced) |
| `$3CA3C` | `DivSteps4`? | `div0` + 3 `div` + `divl`, quotient from `Q` (unreferenced; uncertain) |
| `$3CA64` | `RpzaCompressWords32` | `$E0000000` row headers, `$8…` fill words, the decoder's word format (unreferenced) |
| `$3DA08` | `ReaderInit` | `gr112 = lr2`, `gr113 = [lr2]` |
| `$3DA14` | `WriterInit` | `gr114 = lr2`, `gr115 = 0` |
| `$3DA20` | `WriterPos` | returns `gr114` |
| `$3DA28` | `WriterFlush` | `store gr115` at `gr114 & ~3` |
| `$3DA34` | `ReadByte` | `BP = addr`, `exbyte` from the cached word, reload if the word changed |
| `$3DA50` | (`ReadByte` reload) | `load` + `exbyte` |
| `$3DA5C` | `ReadWord` | odd address: two `$3DB40` bytes; else `exhw` |
| `$3DA84` | (`ReadWord` even case) | `exhw` from cache |
| `$3DAAC` | `ReadLong` | unaligned: two `$3DAF4` halfwords; aligned: `$3DAD8` |
| `$3DAD8` | (`ReadLong` aligned case) | |
| `$3DAF4` | `ReadWordInner` | as `$3DA5C`, returns through `gr99` |
| `$3DB40` | `ReadByteInner` | as `$3DA34`, returns through `gr98` |
| `$3DB68` | `WriterPut` | `(value, size)`: size bit 2 → long, bit 1 → word, else `inbyte` |
| `$3DB9C` | (`WriterPut` long) | splits on `gr114 & 3` |
| `$3DBBC`, `$3DBC4`, `$3DBCC`, `$3DBF0`, `$3DC04` | (`WriterPut` long, alignment 0/0/1/2/3) | `$3DBC4` = aligned `store`, reached by fall-through |
| `$3DC1C` | (`WriterPut` word) | two bytes via `$3DC60`, or `$3DC44` at alignment 3 |
| `$3DC44` | (`WriterPut` word, alignment 3) | |
| `$3DC60` | `WriterPutByteInner` | `inbyte`, store on word boundary, returns through `gr99` |
| `$2E69C` (outside) | `ReplyEarly` | stores the reply unless it is 1, sets `*[packet+$20]` = 1 and packet `+$18` = 1 (with `$D3`); called with 1 before decoding |

### System 6 `.lit`, exact

System 6's `.lit` starts with 26 strings that System 7 does not have, the
names of its arithmetic stubs (`.lit $0000`-`$019F`). Each stub passes its
name to the empty reporter `$00E88`:

| `.lit` | stubs | names |
|---|---|---|
| `$000` | `$01378` | `Bogus` |
| `$008`-`$06C` | `$013A4`-`$01504` | `RBAverage16Half`, `RBAverage16`, `RBAddPin16`, `RBAddOver16`, `RBSubPin16`, `RBTransparent16`, `RBMax16`, `RBSubOver16`, `RBMin16` |
| `$074`-`$0F8` | `$01530`-`$01664` | `StretchAverage16`, `StretchAddPin16`, `StretchAddOver16`, `StretchSubPin16`, `StretchTransparent16`, `StretchMax16`, `StretchSubOver16`, `StretchMin16` |
| `$108`-`$18C` | `$01690`-`$017C4` | `PatAverageSlab16`, `PatAddPinSlab16`, `PatAddOverSlab16`, `PatSubPinSlab16`, `PatTransparentSlab16`, `PatMaxSlab16`, `PatSubOverSlab16`, `PatMinSlab16` |

**The dispatcher table** (`.lit $0F18`, 60 entries, commands `$00`-`$3B`;
System 7's is at `.lit $0DE0` with 61 entries, up to `$3C`). Unknown commands
go to `$2E430` ("Unknown Function", System 7 `$32818`), commands without a
case to the epilogue `$2E460` (System 7 `$3287C`). Against System 7:
* 24 commands have a case in both builds (`$00 $01 $03 $04 $0C $0D $0F
  $11`-`$15 $17 $19`-`$1B $26 $29 $2B`-`$2D $30 $33 $38`);
* `$39`-`$3B` are the codec's in System 6 (`$2DF60`, `$2E0F0`, `$2E258`) and
  unknown in System 7;
* `$00` (`$2DF20`) and `$03` (`$2DF40`) are System 7's `$327D8` and `$327F8`
  word for word: load `[.bss+0]`, store a reply at `+$1C` (0 for `$00`);
* `$16` is unknown in System 6 (System 7: `$3279C`), and `$3C` (System 7
  `$32528`) does not exist;
* `$02`, `$05`, `$06` and `$07` go to the epilogue in both; `$08`-`$0B` and
  `$10` to "Unknown Function" in both.

(Earlier versions of this section fitted System 6's `.lit` key from System
7's strings and tables; the exact table confirms what that fit concluded.)

**The probe: `$00`, then `$02`.** The host sends `$02` (System 6 here;
System 7 the same way, below), although no Antelope of either version
handles it:
* `gc24` ID -4048 begins with a table of 44-byte entries, each a long ID,
  a stub, and at `+$28` a `bra.w` to the routine. The driver (`DRVR`
  -4048, `$10B0`) walks it. A positive ID is a trap to patch. A negative
  ID `-n` stores the entry's `+$28` in the driver globals at
  `$A78 + 4n`. ID -1 is `$85AA` (slot `$A7C`), -2 is `$8638` (`$A80`),
  and -3 is `$8580` (`$A84`, the codec entry above).
* `$85AA(unit, value)` first re-initialises the card (`$884A`; it
  returns -1 if unit `+$1C` bit 1 is then set) and sends `$00`. If `value` is not 0, it sets the
  unit's timeout word (`+2`) to 500, sends `$02` with `value` as its one
  long, stores the reply at unit `+$174` and puts the timeout back. Then it
  sends `$00` again. It returns `+$174`.
* The driver calls it from Status csCode 10 with the long that Control
  csCode 4 stored at its globals `+$12C`, and returns the result. If the
  result is not 1, it sets bit `$100` in the unit's flags (`+8`). Control
  13, 17 and 50 call `$85AA(unit, 0)` after re-initialising the card.
* The control panel's `sub_C50` (System 7's, `cdev.s`: Control 4 at `$C72`,
  Status 10 at `$C9E`) sends Control 4 with `$FFFFFFFF`, then Status 10. In
  System 6, `gc24` 32 runs the same probe at boot (Control 4 at `$596`,
  Status 10 at `$5AE`; an answer other than 1 gives Control 14 and error
  `$D8EA`, `$602`). Its caller (`$128E`) accepts the answer 1. Otherwise it
  restarts the accelerator (`$0A8C`: Control 99, Status 5, Control 14 if
  flag `$20`, Control 2/3 with the two ACEFs, Control 5, Control 13; see
  below) and asks again. A non-zero answer then gives error `$D8EA`
  (reported through Control 20).

**System 7 runs the same probe, and there it is used.** Hook -1 (`gc24`
entry #103, `$1378` → `$6C8A`) is `$85AA` instruction for instruction, and
hook -2 (#104, `$13A8` → `$6D1E`) is `$8638` (`$26`, `$11`, `$00`; it
returns `d7` uninitialised if the device at `globals+$214` is NIL); the
System 7 Antelope also takes `$02` to the epilogue `$3287C`, so Status 10
again returns 1. The control panel's probe `sub_C50` is called from
`sub_FBE` (`$12FA`, and `$1346` after the restart `sub_A8C`); the
`$FFFFFFFF` it sends with Control 4 only makes `$02` go out, and the card
never reads it. Only the control panel reads flag `$100`, through Status 5
(unit `+8`), and it reads it before the probe (`$128E`/`$12D6`, tested at
`$137C`), so its error `$D8EA` reports the previous Status 10's failure.
After the restart the second probe's result is tested with `tst`/`beq`
(`$134C`-`$1350`) instead of the first one's `cmp #1` (`$1300`-`$1306`):
any non-zero answer, including the 1 every running card gives, is reported
as `$D8EA`. In both releases the probe only shows that the dispatcher
answers.

**The probe answers 1.** Both ends are now read:
* Selectors below `$0C`, and every selector the switch at `$628E`
  (`cmd - $0C`, 45 cases) does not handle, take `$6224(cmd, args, n)`'s
  generic packet path (`$77D4`-`$795E`, System 7 `$5F10`-`$604A`;
  `gc24_sw11.s`): `+$18` = 0, `+$48` = `cmd`, `+$4C` = the sequence number
  (`+$20` of the unit, incremented), `+$50` = `n`. The arguments are copied
  (`$7850`-`$7936`, System 7's CopyParamsToQueue) to the area at unit
  `+$18`, which the card re-initialisation `$884A` sets from the address
  the card publishes at `+$54`: `(packet & $FFF00000) | ([packet+$54] &
  $FFFFF)` (`$8AE8`-`$8B0C`, System 7 `$726A`-`$728E`; System 6 Antelope
  publishes `packet+$64C`). Then `+$14` = -1. (If status bit 3 is already
  set, it returns -1 without posting.) It waits until bit 0 or 1 of the
  status long (`[unit+$10]`) is set, then returns packet `+$1C` (`$7A60`).
  The deadline is Ticks plus unit `+$02`, extended while packet `+$1C4`
  changes. A timeout calls `$8E54(unit, 2, 0)`, returns 0 and sets bit 1
  of unit `+$1C` (`$7A96`). The host never writes `+$1C` on this path.
* The System 6 dispatcher, like System 7's, stores 1 in packet `+$1C`
  as soon as it takes a command (`$2D648`-`$2D650`: `const gr99, 1`,
  `add gr98, gr98, $1C`, `store`; the same words as System 7 `$31E58`).
* `$00` then overwrites the reply with 0. `$02` has no case and goes
  straight to the epilogue `$2E460`, so its reply stays 1.

So `$85AA` stores 1 at `+$174`, Status 10 returns 1, the driver leaves flag
`$100` clear, and the control panel accepts the first answer. The probe
only checks that the card's dispatcher is running: a card that hangs
before the dispatcher never sets the status bits, and the timeout returns 0.
The value sent with `$02` (`$FFFFFFFF` from the control panel) is not read.
`$8638` (slot `$A80`)
calls `$6224` with (`$26`, 0, `$0E`), then sends `$11` and `$00`, clears bit 0
of unit `+$1F`, and returns whether the `$26` call returned 0. The driver
calls it first in Status 10, and in Control 14, 17 and 50 before it
re-initialises.

**The System 6 mailbox.** The System 6 driver handles the mailbox exactly
as System 7's (section 4). SetFeatureFlags (`$2A54`, the store at `$2A5E`)
also starts from `$800` and clears it only for config bit `$100`, which only
cs50 (`$C66`) sets, and Init29K arms the mailbox only when `$800` is clear
(`$26AA`-`$26F6`). Status cs15 (`$5D0`) and cs16 (`$62E`) and Control cs51
(`$BFA`) are the same code. The kernel's reporter (`$20024B0`), its bit-11
gates (HIF `$2001A44`, fatal `$200290C`) and the bit-16 restart test are
System 7's instruction for instruction, so the mailbox is never armed by
default in either release. In both, `gr64` bit 11 also makes the fatal-trap
path skip the report, not only the HIF path.

**The System 6 driver's calls.** The System 6 driver dispatches the same
csCodes as System 7's (Status 2, 5-21, 54; Control 2-6, 10-14, 16-21, 48-54,
99), and apart from register allocation (globals in A4, unit in A3, the
other way round in System 7) every handler is the same code except three:
its failure code in `unit+$17C` is `$FFFFD8DC` (System 7 `$FFFFD8DA`),
Control 54 (`$F2A`) passes four longs to the hook at `globals+$A84` and
stores its D0 in `globals+$AA0`, and Status 54 (`$702`) only returns that
long without calling the hook. Its "patches installed" byte is
`globals+$258` (System 7 `$257`), and it returns with `jmp (a0)` instead of
`rtd`, so it runs on a 68000. Its clients send both kinds of call (each
through one wrapper: control panel `$1D30`/`$1D68`, INIT `$A54`/`$A8C`,
`gc24` 32 `$8CA`/`$902`); see "The System 6 start-up" below.

**The System 6 start-up.** The System 6 package starts the card the same
way as System 7, minus two pieces: it has no DSInit, so a second GC is not
reconciled as a plain display card, and nothing in the package runs `gc24`
32: under System 7, Boot3's `Load8Dot24GC` loads it from the file named by
STR -16454; under System 6.0.5 and later (6.0.5, 6.0.7, 6.0.8 and 6.0.8L
checked; 6.0.1 and 6.0.3 lack it, which matches the control panel's
"System 6.0.5 or later required") the System file's start-up patches
do the same (PTCH 376 for the Mac II ROM, PTCH 1660 for the IIci-class ROM:
`_GetString(-16454)`, `_OpenResFile` on that name in the System Folder,
`_Get1Resource('gc24', 32)`, `jsr` into it, `_CloseResFile`; both System
files carry STR -16454 "8•24 GC"). Unlike Boot3 they look only in that
file and test no ROM version, being installed only for the two Color
QuickDraw ROMs. `gc24` 32 does the
whole bring-up in both releases: it installs CODE -4048 as the Gestalt
`'gc24'` function, installs `DRVR` -4048 in the first free unit from 48 up
(`_DrvrInstall`, `$17C`) and opens it (`$1CC`), whose DoOpen calls
InstallPatches (`$101A`) to load `gc24` -4048 and patch QuickDraw. It then
sends Control 19 with the `Date` resource and Status 2, loads ACEF 1 for
Control 2 and ACEF 100 for Control 3 (into a temporary heap zone below
BufPtr), reads `PupS`, checks Status 17/18/19 against `vers` 1, and sends
Control 17, 18, 5, 13, Control 4 with Status 10 and Control 14. Holding
Shift skips all of it. The INIT (`$18`-`$22A`) only checks what `gc24` 32
left: Control 99, Status 21 and 5, then `PupS` 0 for Control 13 or 14,
Shift for Control 14, and a last Status 5 (Control 21 if the accelerator is
not active); it reports through Paul Mercer's ShowINIT instead of System
7's Notification Manager message. The control panel's restart routine
`$A5C` (System 7 `sub_A8C`) repeats the sequence only on request.

**When `gc24` 32 fails.** It runs no machine checks (its only Gestalt call
is `'gc24'`). Every failure goes to one exit (System 7 `$63E`, System 6
`$61C`) that calls `_Close` on the driver and returns -1. That exit removes
nothing: the Gestalt function, the DCE, the locked DRVR and, because DoClose
is a no-op (System 7 `$FD8`, System 6 `$1010`: `clr.w` the result, return),
the QuickDraw patches all stay installed. Shift is tested only
after Gestalt `'gc24'` is installed, and it exits before the driver is
opened, so `_Close` then gets an uninitialised refnum. A missing `Date`,
ACEF 1, ACEF 100 or `PupS` (or an empty `PupS` handle) is reported with
Control 20 `$D8DB` (System 6 `$D8DD`). A Status 17 or 18 version newer than
`vers` 1 (compared nibble by nibble, so 1.1 fails against 2.0), or a Status
19 reply of -1 or with a zero second long, is reported with
`$D8DD`/`$D8DE`/`$D8DF` (System 6 `$D8DF`/`$D8E0`/`$D8E1`); Status 19 is
never compared with `vers`. A Status 10 answer other than 1 gives Control 14
and `$D8EA`. A failing call itself (Status 2 count 0, Control
2/3/4/5/13/17/18/19, Status 2/10/17/18/19) closes the driver without a
Control 20, and leaves the cursor hidden when the failure is inside the
per-card loop. In System 6 a failed second Get1Resource in the temporary-zone
loader (`$6E0`) leaves BufPtr lowered by the resource's size plus 1 KB.

**The control panel's restart routine** is the same code in both releases
(System 6 `$A5C`, System 7 `sub_A8C`). It sends Control 99 and Status 5,
then Control 14 if Status 5's flag `$20` is set. With a non-zero second
argument it loads ACEF 1 for Control 2 and ACEF 100 for Control 3 (Get1Resource
from the control panel's own file into the system zone, no DetachResource),
then sends Control 5; with 0 it sends Control 48 instead. It ends with
Control 13 if flag `$20` was set. A failing step shows a numbered alert
(STR -4047, ALRT -4040) and returns `$D8DC` (System 7 `$D8DA`). The callers
are the same too: the refresh routine (`$73E`, System 7 `$760`) passes 0
when `(flags & 6) != 6`, turning acceleration on (`$934`/`$966`) passes 1
when flag `$2` is clear, and the probe (`$125E`/`$12A2`, System 7
`$12C4`/`$130E`) passes 1. After a failed second restart System 6 sends
Control 20 with `$D812` where System 7 sends `$D810`; both return `$D8EA`.

**When the System 6 host waits.** System 6's `gc24` (`gc24_sw11.s`) waits
as System 7's does in most patches: QDDone (`$433A`, one `sub_6E14` poll
for NIL or the stream's port, TRUE otherwise), GetPixBaseAddr
(`$42CE` → `$421A`, then a spin), GetPixel/GetCPixel (`$3762`/`$3868`) and
the GWorld calls send the same commands; SetPixelsState (QDExtensions
selector `$E`) is not patched. Its `sub_624A` (`$7B22`, loop
`$7BF0`-`$7BF8`) waits for status bit 1 with the same timeout; it and the
poll `$8710` do not spin on the cursor claim `*[globals+$08]`. The drain
is weaker: the Std* fallback (`$4842`) sends `$38` only after a `$0D` on a
pixmap the card holds (state 1 or 2), not up front, and BitMapRgn
(`$3E3A`) sends only `$19` for such a pixmap, so a fallback or BitMapRgn
on an ordinary port does not drain the card. The System 6 Antelope
releases the host early in StretchBits exactly as System 7's:
`ReleaseHostEarly` is `$2E69C` (identical code), called from StretchBits
`sub_28C14` at `$296A4` and `$29BBC`.

## 10. The card's registers

This map lists every access to a non-memory card address on both sides.
Sources: `Boot.asm` and `Hand.asm` (kernel), `text.asm` (Antelope), the same
files of System 6 (`firmware/sw11/disasm/`), `DRVR.s`, `gc24.s`, and the
declaration ROM (`../extracted-source/PrimaryInit.s`, `VideoDriver.s`). The
card-side accesses were found by tracking `const`/`consth` pairs (and
`add` steps in loops) up to each `load`/`store`. The host side was found
from the immediate offsets added to the slot base. System 6 touches the
same registers in the same places. The one difference is in Boot's sense
probe (section 9).

**Addresses.** Card address = host super-slot offset + `$40000000`. The
host reaches card `$4xxxxxxx` at `$s0xxxxxx` (`s` = slot). Four pairs
show the rule from both sides: the doorbell (`$44000050`/`$04000050`), the
revision nibble (`$46000000`/`$06000000`), the RAMDAC (`$46C0000x`/`$06C0000x`)
and `VidComm` (`$4C007300`/`$0C007300`). In the tables, "card" is the
Am29000 address and "host" the offset from the slot base.

**Conventions.**
* *Flag registers* use only bit 31. Writers store `$FFFFFFFF`/0, or set
  bit 31 with `bfins {0:1}`. Readers test bit 31 (`jmpt`/`jmpf`, `bfextu
  {0:1}`, `and #$80000000`).
* *Serial registers* take one bit per write, from data bit 31, MSB first
  (`SerialShiftOut` `$629C`, PrimaryInit `$2880`). A read returns the
  current MSB in bit 31. Boot reads such a register back by N cycles of
  "read, write the same word back" (`$20035EC`, `$2003788`), so writing the
  read bit back turns the register round. The read-and-write-back loops in
  the host's `sub_5D96` and PrimaryInit's `RegTouchLoop` (`$289E`) have the
  same shape.

Legend: **est.** = the code's effect is unambiguous, or both sides agree;
*reading* = what the code suggests.

### 10.1 `$44000000`-`$440000C8` (host `$04000000`-`$040000C8`)

| card | bits | written by | read by | meaning |
|---|---|---|---|---|
| `$44000000` | serial, 20 | PrimaryInit `$254E`/`$27D6` and VideoDriver `$6098` (timing-table long 3, always `$2000`); Hand `$C6` `$2001328` (20 stores of `lr2 << 10`, `lr2` halved first if `+$80` is set) | Boot `$20035EC` (20 read/write-backs) | **display start** (est.). Boot makes PublicOut+`$1C` = value `<< 2`, `<< 1` more if `+$7C` is set and `<< 1` more if `+$80` is set, then ORs in `gr66` (slot) and `$0C000000`. `$2000 << 3` = `$10000` = the VideoDriver's base offset (`$5E4A`). The host always sets exactly one of `+$7C`/`+$80` (VideoDriver `$6060`-`$6084`), so Boot's factor is ×8 in both layouts (×4 only after PrimaryInit's reset table `$2B64`, which clears both). Every host timing table has `$2000`, so Boot always gets offset `$10000`; on TV modes the driver's base is `$11400` (`$5E42`-`$5E62`), `$1400` past the display start. `$C6` writes `lr2/8` in the linear layout (it halves first, `$20012FC`) and `lr2/4` in the interleaved one: it agrees with Boot when linear and puts the start at twice the offset when interleaved. This never happens: `$C6` has no callers (Antelope's stub `$38F74` is unreferenced). It also stores its halved value at PublicOut+`$1C`, where Boot stores a full card pointer |
| `$44000004` | serial, 8 | PrimaryInit `$2540`/`$27C8`, VideoDriver `$608A` (long 2: `$F8/$FC/$FE/$FF` for 1/2/4/8 bpp on the 12" and portrait tables, `$E0/$F0/$F8/$FC/$FF` on the 13" table) | - | depth-dependent, meaning unknown (no card access) |
| `$44000008` | serial, 16 | PrimaryInit `$20BC`-`$20D8` (4 × 4 bits of `$A`, i.e. `$AAAA`), at reset only | - | unknown (*reading*: a reset/unlock pattern) |
| `$4400000C`, `$10`, `$14`, `$18` | bit 31 | Boot writes each value back | Boot `$2003010` loop (4 iterations, bit inverted) | **NuBus slot ID** (est.). Boot builds the 4-bit slot `s` and stores `gr66 = s << 28` at PublicOut+`$2C`. That value is the top nibble of the pointers PublicOut+`$0C`-`$18` and service `$C4`'s result, which IsOnThisCard `$13F54` uses as the slot |
| `$4400001C`, `$20`, `$24` | bit 31 | PrimaryInit -1 (`$214C`-`$216E`); VideoDriver sets bit 31 after each mode change (`$60D4`-`$60F8`) | - | unknown, always set |
| `$44000028` | flag | PrimaryInit 0 (`$2176`, at reset); DRVR `$1D8E` 0 (`$1DBA`; called from BuildUnitRecords `$1FF8`, Init29K start `$241A` and after the RAM tests `$25B8`, cs6 `$B76`, cs20 `$8EC`); DRVR `$1DDC` -1 (`$1E28`, right after it writes the flags to image+`$18`; cs5 `$B4E`) | - | **Am29000 run control** (*reading*, strong): 0 = CPU held, -1 = CPU runs; most likely the *RESET line rather than CNTL/Halt (section 1). The host tests and overwrites all of card SRAM/DRAM and uploads Runtime and Antelope (cs2, cs3) while it is 0. Boot (`$2003000`) is part of that upload; it reads PublicIn+`$18` (`$2003050`) and the cs3 fields PublicIn+`$20`-`$2C` (`$2003090`) right after a poll that cs2's `$42005300` has already satisfied, so it can only start at cs5's -1. cs6 and cs20 stop it again. The card never accesses it |
| `$4400002C`, `$30`, `$34` | flag | PrimaryInit 0 at reset; XtdSense (VideoDriver `$62F6`, PrimaryInit `$28B0`) and Boot `$20033C8`-`$2003548`: -1 to one line per round | - | **sense-line drive** for lines 0/1/2 (est.: each round drives one line and reads the other two) |
| `$44000038`, `$3C`, `$40` | ? | PrimaryInit 0 (`$20FA`-`$2114`); Boot 0 before its probe (`$20033D4`-`$20033EC`; System 6 also zeroes `$34`-`$48`) | - | cleared before sensing (*reading*: sense-related) |
| `$44000044`, `$48`, `$4C` | bit 31 | (System 6 Boot writes 0, without effect in the code) | VideoOpen `$532E`-`$5354`, XtdSense, PrimaryInit `$21DE`-`$2204`, Boot `$2003368`-`$20033B0`, DRVR BuildUnitRecords `$2004`-`$205E` | **monitor sense lines** 0/1/2 (est.). `$44` is the code's MSB. DRVR: code 7 with `d5` = 0 sets `+$15E` = `$FFFF` and skips the card |
| `$44000050` | flag | host -1: VideoDriver `$5F54` (after each `VidComm` command), DRVR PostLoadPoke `$2AAA`, gc24 `$75DA` (copy of PostLoadPoke); card 0: INTR2 `$2000BE0`, `$2000C30`, kernel init `$2002020` | via `$44000064` | **doorbell host → card** (est.): -1 sets it and raises INTR2, 0 acknowledges it |
| `$44000054` | flag | Hand `$C5` `$2001230` (-1) / `$2001248` (0); INTR2 ack `$2000BFC` (0); init `$200202C` (0); Antelope interrupt test `$368BC` (-1) | via `$44000068` | **video interrupt** to INTR2 (est.: the self-test arms it and waits up to `$F4240` loops for Int2Handler). -1 arms, 0 clears |
| `$44000058` | flag | INTR1 `$2000B6C` (0); Antelope interrupt test `$367A4` (-1) | - | **INTR1 source** (est.: the test writes -1 and waits for Int1Handler, and INTR1 clears it). The hardware source behind it is unknown |
| `$4400005C` | flag | kernel init -1 when flags bit 8 is set (`$20022F4`); `$D6` 0 (`$20018B0`); vector 7: 0 then -1 (`$2000348`/`$2000354`) before it emulates the access through vector 1 | - | enables the hardware handling of unaligned accesses (*reading*; it goes with OPS.TU clear). The 0/-1 pulse acknowledges a fault |
| `$44000064` | bit 31 | - | INTR2 `$2000BD0`, service `$2000C14` (`$2000C20`), mailbox waits `$2002678`, `$2002708` | doorbell pending (est.) |
| `$44000068` | bit 31 | - | INTR2 `$2000BEC`, `$C5` `$200123C` | video interrupt pending (est.) |
| `$44000070` | bit 31 | - | vector 7 `$2000440` (only with flags bit 8) | set → the fault is handled as an unaligned access (`$2000324`); *reading*: "fault from the unaligned-access logic" |
| `$44000078` | ? | PrimaryInit 0 (`$2118`) | - | unknown |
| `$4400007C` | bit 31 | host only: PrimaryInit `$253A`/`$27C2`, VideoDriver `$6084` (bit 0 of timing long 1) | Boot `$2003610`, `$2003770`; Hand `$2000E64`, `$2000F34`; Antelope Fill2Longs `$172A8`, TestInterleave `$34CA8` | **1 = interleaved layout** (est., section 5) |
| `$44000080` | bit 31 | host only: PrimaryInit `$252C` (0 for monitor codes 0/4/8/`$C`, else 1), `$27B6` (0); VideoDriver `$6076` | Boot `$2003628`, `$20037A8`; Hand `$2000E74`, `$2000F44`, `$C6` `$20012F0`; Antelope FillLongs `$17044`, `$34CB8` | **1 = linear layout** (est.) |
| `$44000084` | ? | PrimaryInit -1 (`$213E`) | - | unknown |
| `$44000088` | flag | Hand pager -1 (`$2001FA8`) / 0 (`$2001FD0`) around its 8 `loadm` of 32 words (`$2001FBC`: one 1 KB page) | - | page-fill bracket (*reading*: cache/burst fill) |
| `$4400008C` | bit 31 | kernel init `$2002308` and pager `$2001FF0`: `~(gr64 << 24)`, so bit 31 = NOT flags bit 7; pager 0 during the fill (`$2001F84`) | - | controlled by flags bit 7 (meaning unknown) |
| `$44000090` | bit 31 | PrimaryInit -1 (`$2130`); kernel init `$200231C`: `~(gr64 << 25)`, so bit 31 = NOT flags bit 6 | - | controlled by flags bit 6 (meaning unknown) |
| `$44000094`, `$98`, `$9C` | bit 31 | - | kernel init `$2002178`-`$20021A0`; TestInterleave `$34C44`-`$34C78`; DRVR ProbeCard `$21F0` (`$9C` only) | **3-bit board configuration** (est. as a code). Init ORs it into PublicOu+`$04` bits 24-26 and clears flags bit 8 when it is 0. TestInterleave skips when it is 0. DRVR: `$9C` clear means board generation 2 |
| `$440000A0` | serial, 12 | PrimaryInit `$255C`/`$27E4`, VideoDriver `$60A6` (long 4); Hand `$C6` `$2001358` (12 stores of `lr4 << 18`, halved first if `+$80` is set) | Boot `$2003788` (12 read/write-backs; only when `+$7C` is clear, else `$A00`) | **row stride**: rowBytes/8 linear, rowBytes/4 interleaved, doubled on interlaced TV modes (est.: `$10`…`$140` → 128…2560 on the Apple monitors, `$387E`; NTSC/PAL `$200` for rowBytes `$400` at 1-8 bpp and `$280` for `$A00` at 24 bpp). `$C6` uses the same units (÷8 / ÷4). Boot computes value `<< 2`, `<< 1` more if `+$80` is set, capped at `$A00`, into PublicOut+`$24` |
| `$440000A8` | ? | PrimaryInit 0 (`$2180`); -1 for monitor code 3 (`$23D8`) | - | unknown (two-page monitor only) |
| `$440000AC`, `$B8`, `$BC` | ? | PrimaryInit -1 (`$218A`, `$2198`, `$2122`) | - | unknown |
| `$440000C0` | ? | PrimaryInit 0 (`$21A6`) | - | unknown |
| `$440000C4` | bit 31 | PrimaryInit 0 (`$21B0`); VideoDriver sets it after the timing registers (`$613C`) | - | *reading*: timing loaded / video on |
| `$440000C8` | flag | Antelope TestInterleave -1 (`$34D28`) / 0 (`$34D68`), timer off | - | *reading*: **paired-word write**. While it is set, the test stores 0 to the even words only, then checks that all words are 0. It runs only with a non-zero board code and the linear layout |

No code accesses `$4400006C`, `$74`, `$B0` or `$B4`.

### 10.2 Timing generator: `$44400000`, `$44C00000` (host `$04400000`, `$04C00000`)

| card | written by | read by | meaning |
|---|---|---|---|
| `$44C00000` | host, 12-bit serial: PrimaryInit `$2598`/`$2820`; VideoDriver `$612C` (values), `$59F0`, `$5A5A`, `$5F1E`, `$5F90`, `$6100`, `$614C` (control values 0/1/3) | host read/write-back loops (`$5D96`, `$289E`); Antelope `$000DC`, `$0010C`, `$00124` | serial data register of the bank (est. as a mechanism) |
| `$44400000 + 4n`, n = 0-14 | PrimaryInit `$25A0` (`clr.l (a3)+`, 16 registers); VideoDriver `$6134` (writes the `$44C00000` word just read) | - | **timing registers** (*reading*). Each write latches the 12 bits just shifted into `$44C00000`, so the written data does not matter. Values come from timing-table longs 5-19 (VideoDriver) |
| `$4440003C` (n = 15) | `clr.l` after shifting 0, 1 or 3: VideoDriver `$5A08` (3: VBL off), `$5A72` (1: on), `$5F36` (3), `$5FA8` (1), `$6114` (0, before the timing registers), `$6160` (1); PrimaryInit `$25AC` (3), `$2866` | - | **control** (*reading*): 0 while the timing is loaded, 1 = running with the slot interrupt on, 3 = interrupt off |
| `$44400048` | PrimaryInit `$25B6`/`$283E`; VideoDriver's VBL task `$62E2` (`clr.l (a1)`; `a1` = the queue element's `sqParm`, set to base + `$04400048` at `$5A3E`) | - | **acknowledges the host's VBL slot interrupt** (est.) |
| `$444001C0` / `$444000C0` | - | host WaitForVBlank `$5D6A`-`$5D8C` (`$1C0`, then 10 read/write-backs of `$44C00000`); unused copy PrimaryInit `$299C`; Antelope `$000C4`/`$000F4` (`$0C0`, then 7 read/write-backs; no callers) | the read loads a status into the shift register. The tested bit is bit 31 of the **last `$44C00000` read**, not of this read. The host waits set → clear → set (vertical blank, *reading*) |

### 10.3 Other host-only ports

| card | host | written by | meaning |
|---|---|---|---|
| `$44800000` | `$04800000` | PrimaryInit only (`$22D0`-`$2406`, `$26D4`-`$279C`): bit 0, then `$998`, `$8B88`, `$AAAD`, then by board revision `$9ACC`/`$9BCC`, `$8A9C`, `$88ACAC`/`$88ACBC`, `$53`/`$93`, `$2405B`/`$2409B`, then 2 or 1 (4 bits) and 1 (2 bits) by monitor | a serial port, MSB first, one bit per write from data bit 31 (SerialShiftOutReg `$2880`), the same one-bit-on-D31 scheme as the MFB registers (`$44000008`, `$440000A0`) and the timing generator (`$44C00000`). Not the DP8531 (10.8), not a Xilinx configuration (no `11111111 0010` preamble; 137 bits against XC2000/3000's 12,000+), and no other part on the board can take it. *Reading*: a 137-bit configuration chain inside a custom chip, most likely the MFB (marked "©88 Apple MFB", Toshiba 343S0031-A). The first 100 bits are 25 cells of `1` plus a 3-bit count, then two similar words (`$053`, `$2405B`), a 4-bit field (1 Two-Page, 2 otherwise) and `01`. Board revision 1 adds 1 to two 3-bit cells and to bits 7-6 of both words, which suggests memory/VRAM timing counts. Nothing in the original 8•24's JMFB code is serial like this. The VideoDriver never writes it |
| `$46800000` | `$06800000` | PrimaryInit `$256C`/`$27F4` (16 longs to one address); VideoDriver `$60BC`, only when GFlags `Interlaced` is set (TV modes) | **the DP8531 clock synthesiser** (National; U016 on the board, 20.000 MHz reference): 16 writes, each `register << 4 | nibble` in bits 7-0 (that is why the values rise from `$0C` to `$F0`), then a `$D00`-loop settle delay. See 10.8 |

### 10.4 `$46000000` (host `$06000000`): bus status, revision, slot burst mask

| bits | access | evidence | meaning |
|---|---|---|---|
| 1:0 | read | vector 7 `$20003CC`: 0 or 3 → resume, 1 or 2 → `$2000474` (count in `$4C0067E0` while negative, else reason `$90`) | NuBus response of the faulting cycle (*reading*: 0 ok, 1 error, 2 timeout, 3 retry) |
| 2 | read | vector 7: set → `$20004A4` clears bit 16+`n` of `$46000000` (`$2000534`-`$200053C`), `n` = top nibble of CHA (the next nibble for `$Fn……`) | a burst to slot `n` failed (est.: the handler drops that slot from the mask) |
| 4 | read | vector 7: set → resume at once | *reading*: retry |
| 12-15 | read | kernel init `$20021E0` → PublicOu+`$04` bits 28-31, flags bit 29 if ≥ 1; PrimaryInit `$2302`/`$2706` (= 1 picks the second clock set); DRVR ProbeCard `$220A`/`$2228` (0 → generation 3, 1 → 4) | **board revision** (est., three readers agree) |
| 16-31 | write | `[$4C00643C] << 16`: kernel init `$200260C`, `$D5` `$200128C`, the timer every 65536 ticks `$20009E4` (restores the slots that vector 7 dropped); vector 7 read-modify-write `$200053C` | **per-slot burst enable** (est.). The master copy is PublicIn+`$3C`, `$0000FFFF` at load (RuntimeData) |

### 10.5 RAMDAC `$46C00000`-`$46C00008` (host `$06C00000`-`$06C00008`)

| card | written by | read by | meaning |
|---|---|---|---|
| `$46C00000` | host byte at `+0`: VideoDriver `$5604`, `$56F8`, `$58D4`, `$5974`, `$5BA6`; PrimaryInit `$25C4`/`$284A` (long 0). Card: Hand `$C7` `$2001384` and `$C8` `$20013D0` (byte store, BP 0); Antelope TestCLUT `$359D8`/`$359F4` (word `$FE`), SaveCLUT `$36CA0`, RestoreCLUT `$36D2C`, WriteCLUT `$36DC0` (word 0) | - | **CLUT address**: one index for writing and reading back (bits 31-24 = host byte `+0`) |
| `$46C00004` | three bytes per entry: host `$560C`, `$5704`-`$5710`, `$58DE`-`$58E6`, `$597E`-`$5986`; PrimaryInit (entry 0 = `$FF,$FF,$FF`, entry 1 = 0,0,0); card `$C7` (`lr3`, `lr4`, `lr5`), Antelope `$359E8`, `$36D44`, `$36DD8` (bits 31-24) | card bits 31-24: `$C8` `$20013DC`-`$20013F4` (result `$00BBGGRR`), TestCLUT `$359F8`…, SaveCLUT `$36CB0`. Host GetEntries `$5BAA`-`$5BC6` (bits 31-24 of a long read, via `rol.l #8`) | **CLUT data**: R, G, B, then the index moves to the next entry, on writes and reads (bits 31-24) |
| `$46C00008` | host only: timing-table long 0 (PrimaryInit `$2504`/`$27AC`, VideoDriver `$605C`) | Boot `$200365C` (bits 31-24) | **RAMDAC command / pixel mode** (the third register, readable). Boot: bits 26-25 ≠ 0 → 24 bpp, else bits 28-27 = log2 depth (1/2/4/8); ROM values `$C0/$C8/$D0/$D8`, `$80…/$9C` for 24 bpp, `$C1…` on TV |

Note on lanes: the RAMDAC's 8-bit bus is on bits 31-24 (the 68k's byte
offset 0); address bits 3-2 select the register, and `$46C0000C` is never
accessed. Host and card agree: the host's `$C0000000` at `+8` reads back as
`$C0` at Boot `$2003660`, and the host's GetEntries takes bits 31-24 of a
long read. There is no separate read-index or pixel-mask register, so the
part is not a Bt471/478-style one. The board photo shows a Brooktree chip
marked "RAMDAC 428", "357S0010-A", "©88 APPLE": an Apple-custom part,
the AC842 of the ROM comments and of *develop* 3's block diagram. Antelope writes the
index as a full word with the index in bits 7-0, so the RAMDAC sees index
0: TestCLUT tests entry 0, not `$FE`, and passes either way;
SaveCLUT/RestoreCLUT/WriteCLUT start at 0 and are unaffected.

How the host loads it (VideoDriver): SetEntries packs
`B<<24 | G<<16 | R<<8 | index` through the three gamma tables (`sub_5758`)
and writes the index, then R, G, B; on a monochrome monitor (GFlags bit 12)
it writes 0, 0 and the luminance (`$5704`, `$572A`), so only the blue
channel carries the picture. In direct (24-bit) mode (GFlags bit 10)
SetEntries refuses (`$5630`), and SetGamma (`$5876`) and GrayPage
(`$5916`) load entry i = gR[i], gG[i], gB[i] (`$58DE`, `$597E`): the CLUT
is then a per-channel gamma lookup. In indexed modes a new gamma table
takes effect at the next SetEntries. The default gamma (`$5852`) is the
identity (entry k = k).

### 10.6 Block-write colour registers `$4CC00000`, `$4CC00004` (host `$0CC00000`, `$0CC00004`)

Only Antelope accesses these: FillLongs `$170F4`/`$17100` and Fill2Longs
`$1737C`/`$17388`. The fill stores go to the bit-22 alias of the frame
buffer (`dst | $00400000`), and only in the linear layout. See "the
rectangle case". No host code addresses this range.

### 10.7 Order of the host's mode programming (VideoDriver `sub_5FD4`, after WaitForVBlank)

1. `$46C00008` ← long 0.
2. `+$80` bit 31 (linear, from GFlags).
3. `+$7C` bit 31 ← long 1.
4. `+$04` ← long 2 (8 bits), `+$00` ← long 3 (20 bits), `+$A0` ← long 4 (12 bits).
5. TV modes only: the DP8531 clock synthesiser (`$46800000`) ← 16 register writes, then a settle delay.
6. `+$1C`/`$20`/`$24` bit 31 set.
7. Timing control ← 0, then timing registers 0-14 ← 15 longs.
8. `+$C4` bit 31 set, timing control ← 1, WaitForVBlank.

JMFBSetDepth runs this between `control ← 3` / doorbell and the final
`VidComm+$04 ← -1`.

### 10.8 The video modes (declaration ROM `341-0812.bin`, file offset = ROM address)

Each mode table pointer (`a0`, chosen in VideoOpen `$53AE`-`$545E`) has a
22-byte header in front of it: pages−1 for 24- and 32-bit addressing
(`a0−$16`, `a0−$11`, 5 bytes each), rowBytes per depth (`a0−$C`, 5 words)
and vRes (`a0−2`). Then one record per depth: 20 longs on the progressive
monitors, 36 on TV modes (longs 0-4, the 16 clock-synthesiser writes for `$46800000`,
then the 15 timing longs). PrimaryInit has its own boot tables (`$2A34`-`$2E5C`,
`$98` bytes, chosen at `$24A4`-`$24F8`: 16 timing values, register 15 = 2,
plus two gray-fill counts; longs 5-20 are the clock-synthesiser writes).

| monitor (sRsrc) | table | resolution, depths | rowBytes 1/2/4/8/24 | base | long 0 | H active / bp / sync / fp | H total | V active / bp / sync / fp (half-lines) | lines | r13 | r14 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Two-Page (`$A3`/`$B3`) | `$35D2` | 1152×870, 1-8 | 256/512/576/1152 | `$10000` | `$C0`-`$D8` | 288/34/32/10 (×4 px) | 364 (1456 px) | 1740/78/6/6 | 915 | 0 | 364 |
| Portrait (`$A1`/`$B1`) | `$3728` | 640×870, 1-8 | 128/256/512/1024 | `$10000` | `$C0`-`$D8` | 160/18/20/10 (×4 px) | 208 (832 px) | 1740/84/6/6 | 918 | 0 | 208 |
| 13" (`$A6`/`$B6`) | `$387E` | 640×480, 1-24 | 128/256/320/640/2560 | `$10000` | `$80`-`$98`, `$9C` | 640/96/64/64 | 864 | 960/78/6/6 | 525 | 0 | 864 |
| 12" (`$A2`/`$B2`) | `$3A24` | 512×384, 1-24 | 64/128/256/512/2048 | `$10000` | `$80`-`$9C` | 512/80/32/16 | 640 | 768/38/6/2 | 407 | 0 | 608 |
| NTSC 640×480 (`$AC`/`$BC`) | `$3EB0` | 640×480, 1-24 | 1024 / 2560 | `$11400` | `$C1`-`$D9`, `$9C` | 640/38…64/60/42…16 | 780 | 481/32/6/6 | 262.5 | `$6E` | 330 |
| NTSC 512×384 (`$A4`/`$B4`) | `$447C` | 512×384, 1-24 | 1024 / 2560 | `$11400` | as NTSC | 512/98…120/60/110…88 | 780 | 433/80/6/6 | 262.5 | `$6E` | 330 |
| PAL 768×576 (`$A8`/`$B8`) | `$4A48` | 768×576, 1-8 (no 24-bit mode: its record's rowBytes 2560 is too short) | 1024 / 2560 | `$11400` | as NTSC | 768/53…81/69/54…26 | 944 | 576/39/5/5 | 312.5 | `$5E` | 403 |
| PAL 640×480 (`$A0`/`$B0`) | `$5014` | 640×480, 1-24 | 1024 / 2560 | `$11400` | as NTSC | 640/117…148/69/118…87 | 944 | 528/87/5/5 | 312.5 | `$5E` | 403 |

Measured: the horizontal registers 3-6 hold active, back porch, sync and
front porch, each minus 2; registers 9-12 the vertical ones in half-lines.
Registers 0, 1, 7, 8 are always 3, 0, 3, 0; long 3 (display start) is always
`$2000`; long 4 (row stride) is rowBytes/8 on the progressive monitors and
`$200`/`$280` on TV; long 1 (the interleaved layout) is 1 only on TV modes at
1-8 bpp. The TV tables trade back porch against front porch per depth with a
constant sum (pipeline compensation). The B banks drop 24 bpp (Two-Page B
also 8 bpp). Four more tables (`$3BCA`, `$4196`, `$4762`, `$4D2E`) are unreachable
left-overs. Each sits directly before the convolved table of the same slot
and holds an unconvolved, progressive variant: long 0 `$80`-`$9C`, long 1 =
0, constant porches, r13 = `$0E` (640×480) or `$6E` (512×384). The PAL-slot
copies `$4762` and `$4D2E` repeat the NTSC records of `$3BCA` and `$4196`
under a PAL vRes. Nothing reaches them: VideoOpen's eight `lea` are a
complete compare tree (`$53AE`-`$545E`), and no table index, sResource
entry or PrimaryInit path points there. No sResource selects "convolution
off".

Which sResource survives (PrimaryInit `$2420`-`$247E`; selector `$31` is
sDeleteSRTRec, `$09` sSetsRsrcState): one whole bank is deleted (the B bank
when sVersion succeeds, else the A bank); in the other, the sensed
monitor's sRsrc is kept, its TV sibling (id bit 3) disabled and the rest
deleted. Sense 1 → `$A1` Portrait, 2 → `$A2` 12", 3 → `$A3` Two-Page, 6 →
`$A6` 13"; sense 4 or extended `$14` → `$A4`/`$AC` NTSC, extended `$00` →
`$A0`/`$A8` PAL, bit 3 from the id saved in PRAM (`$2278`, written by the
driver's cscSetDefaultMode). Senses 0 and 5 lose bit 2 when bit 0 is set (`$2438`-`$243E`), so raw 5
(`$A5`) is kept as a colour Portrait `$A1` and raw 0 (`$A7`) as a colour
Two-Page `$A3`.
With 32-Bit QuickDraw, SecondaryInit (`$2FAE`-`$307A`) swaps a B-bank
sRsrc for its A-bank twin (sDeleteSRTRec, sInsertSRTRec, PRAM update), so
the B bank (without 24 bpp) serves only old QuickDraw.

The apparent VPBlock mismatches (mode `$83` of `$A8` and `$AC`) come from
two mode lists without an `$FF` terminator (`$70B4`, `$70F4`) running into
the B-bank lists. The Slot Manager takes the first match, so the correct
blocks `$7238` and `$71DC` are used. The driver itself never reads a
VPBlock (VideoOpen's sFindStruct reads only the gamma directory, id `$40`).

With the standard pixel clocks the totals give the expected rates (*inferred*):
30.24 MHz / (864×525) = 66.7 Hz (13"), 15.67 MHz / (640×407) = 60.15 Hz
(12"), 57.28 MHz / (832×918) = 75.0 Hz (Portrait), 100 MHz / (1456×915) =
75.06 Hz (Two-Page); NTSC 780×525 and PAL 944×625 are the square-pixel
12.27/14.75 MHz timings. The layout is that of the original 8•24's
"Stopwatch" timing chip in System 7.1's `JMFBPrimaryInit.a` (7 horizontal,
6 vertical, 2 composite values; same control `$3C`, VBL ack `$48` and status
`$C0` offsets; NTSC there `3,0,$136,$27E,$12,$3A,$3A / 3,0,$1E0,$21,6,6 /
$6E,$14A`). Register 2 is the mid-line point (hActive/2 on progressive
monitors), 14 the serration point (H − hsync on the 12", H/2 − hsync on TV,
H where there is none), 13 a composite parameter used only on TV (perhaps
the equalising-pulse width).

Long 0 is the RAMDAC's pixel bus control byte (the original 8•24's
`CLUTPBCR`, "CLUT Pixel Bus Control Register", at the same offset `+8` in
System 7.1's `JMFBDepVideoEqu.a`). Bit 24 = convolution. Bits 28-27 = log2
depth. Bits 26-25 ≠ 0 = direct 24 bpp (`$9C` here, `$9A` on the original
card); Boot `$200365C` tests both fields. Bits 30-29 = pixel multiplex,
log2 of the pixels per timing-generator clock: 0 on 13"/12" and in 24 bpp,
2 (4:1) on Two-Page, Portrait and the convolved TV modes. The original card
ran Portrait at 2:1 (`$A0`, `JMFBDriver.a` Mode57, horizontal active `$13E`
= 320−2 in 2-pixel units); the GC uses 4:1. Bit 31 is always set (meaning
unknown). Long 2 goes to the original card's "Load/Sync Register" offset
(`JMFBLSR`, `+4`): `$FF << (8 − n)` with n = 3 + log2 depth + the multiplex
field, so its 8 − n low zero bits are log2 of the timing clocks per 32-bit
VRAM load (32/depth pixels divided by the multiplex factor). The original
card's 1-bit values fit the same rule: `$E0` (12"; 13" in System 7.1's
driver and in MDC 1.2), `$F0` (Portrait), `$F8` (Two-Page). Its 13" has two
settings: the declaration ROM MDC 1.0.1 (341-0801-02) and 7.1's PrimaryInit
boot table run it 4:1 (`$C0`, LSR `$F8`, horizontal active `$9E` = 160−2 in
4-pixel units), 7.1's `JMFBDriver.a` and MDC 1.2 (341-0868) 1:1 (`$80`, LSR
`$E0`). The original card's ROMs (in `Mac_ROMs.zip`, "Trident 8-24")
confirm the 7.1 source's tables: NTSC, Portrait (PBCR `$A0`), Two-Page, the
13" 24-bit `$9A` and the National clock's 16 nibbles are in their bytes.
MDC 1.0.1 knows only the National clock chip (register 10 = `$D`) and has
no PAL modes; MDC 1.2 adds PAL, the 16" and 21" Color monitors and the
Endeavor's M/N bytes per mode (register 10 = 5). Both carry BoardId `$27`
and drHwJMFB (25).

**The clock synthesiser** is a National DP8531 (UU16 in the board photo,
`Macintosh Control Panel/ Macintosh Display Card 8•24 CG.jpg`, next to a
20.000 MHz oscillator; the RAMDAC beside it is marked "Bt RAMDAC 428 … ©88
APPLE"). It is a parallel part, programmed through `$46800000`: 16 long
writes, each `register << 4 | nibble` in bits 7-0, then a `$D00`-loop settle
delay, as System 7.1's JMFB code loads its "National" clock. PCLK = 20 MHz ×
N / R / 2^P, with N = registers 0-3, R = 4-6 and P = 9:

| table | N | R | P | PCLK |
|---|---|---|---|---|
| `$2A34` Two-Page | 190 | 19 | 1 | 100.000 MHz |
| `$2ACC` Portrait | 126 | 22 | 1 | 57.273 MHz |
| `$2B64` 13" | 127 | 21 | 2 | 30.238 MHz |
| `$2BFC` 12" | 94 | 15 | 3 | 15.667 MHz |
| `$2C94`/`$2D2C`, `$3EB0`/`$447C` NTSC | 540 | 55 | 2 | 49.091 MHz = 4 × 12.273 |
| `$2DC4`, `$4A48`/`$5014` PAL | 413 | 70 | 1 | 59.000 MHz = 4 × 14.75 |
| unreferenced `$3BCA`/`$4196`/`$4762`/`$4D2E` | 157 | 16 | 4 | 12.266 MHz |

The other registers are the same everywhere: 10 = `$D` (both TTL clock
outputs and LPF2 off), 11 = 6 (N mode, SCLK from the S counter), 12 = 4
(restart the VCO) on the progressive tables and 0 on TV, 13 = 1 (LCLK off);
S and L are 0, 1/1 on PAL. PrimaryInit loads the clock once, from the boot
table of the sensed monitor; the VideoDriver reloads it only for TV modes
(GFlags `Interlaced`), since a depth change keeps the pixel clock. Long 0's bit 30 (multiplex 4:1) thus marks the modes whose timing
generator runs at PCLK/4: on Two-Page and Portrait the RAMDAC takes 4
pixels per timing clock, hence the ×4 horizontal units; on the convolved
TV modes the pixel clock is 4× the pixel rate with unchanged horizontal
counts, which fits the four samples of the (above + 2·target + below)/4
filter that *develop* issue 3 describes (pp. 335-336; *inferred*).

The 137-bit stream PrimaryInit shifts into `$44800000` (`$22CE`-`$2406`,
`$26D4`-`$279C`; by board revision `$9ACC`/`$9BCC`, `$88ACAC`/`$88ACBC`,
`$053`/`$093`, `$2405B`/`$2409B`, then 4 bits that are 1 on Two-Page and 2
otherwise, then 2 bits = 1) is not the clock; see 10.3 (most likely an
MFB configuration chain).

### 10.9 Where everything goes: a stock card and with SIMMs

Offsets in the slot's memory (the host sees `$sCxxxxxx`, the card
`$4Cxxxxxx`). The boundaries are computed as follows:

* **Top of RAM, unit `+$138`** (Init29K `$24C6`-`$25B2`): `$0C1FFFFF`, the
  last byte of VRAM; `$0C2FFFFF` / `$0C3FFFFF` when TestRAMLong passes at
  `$0C200000` / also `$0C300000` (a pass at `$0C300000` alone is error
  `$FFFFD8E8`); the `$0D` bank tests give `$0D3FFFFF`, `$0D4FFFFF` or
  `$0D7FFFFF`.
* **A program's region** (ReserveEngineRegion `$2B5E`): `+$134` = (`+$138` −
  (bss + 2·data + round1K(text) + `$400`) + `$3FF`) & ~`$3FF`, with only a
  `$0C000000` floor; nothing compares it with the frame buffer. Antelope
  (text `$3CAD8`, data `$2AB8`, bss `$A64`) needs `$42FD4` bytes; on a stock
  card its base is `$0C1BD400`. Its absolute `Code` section goes to vaddr +
  `$0C000000` = `$0C00F000` (ACEFLoad `$3736`-`$3770`), in the kernel's
  first 64 KB.
* **Stacks** (kernel init `$2002414`): the memory stack's top is the
  program base ([PublicIn+`$40`]); gr127 = base − `$10000` (64 KB); the
  register stack lies below (gr126 = gr127 − `$200`).
* **Heap** (`$20025B0`-`$20025F0`): the break starts at the frame-buffer
  base ([PublicOut+`$1C`]) + rowBytes × (lines + 6), with rowBytes from the
  monitor, not the current depth, so the deepest mode is always reserved
  (also stored at `$4C003120`). With flag bit 20 (top of RAM above
  `$0D000000`, DRVR `$2B44`) the break is `$sD000000` instead. sbrk (`$101`)
  refuses anything above gr127 − `$3000`. HeapCreate (`$372D4`) asks for
  service `$C1`'s free value − `$1000` and retries 1000 bytes smaller until
  it succeeds. PQDInit takes a `$A000` (40 KB) PQDAlloc arena; the caches
  (CacheAlloc `$15958`: offscreens, fonts, tables) are blocks in the same
  heap. The drawing-stream buffer is in the packet area, not in the heap.

| stock card (2 MB VRAM) | contents |
|---|---|
| `$0C000000`-`$0C0083FF` | the Runtime's shared areas |
| `$0C008C00` | the command packet |
| `$0C00F000` | Antelope's `Code` stub |
| `$0C010000` (`$0C011400` on TV) | the frame buffer |
| frame-buffer end - `$0C1A9400` | the heap: about 421 KB with a 13" monitor, 651 KB with Two-Page, 177 KB with PAL (the smallest) |
| `$0C1AD400`-`$0C1BD400` | the 64 KB memory stack (register stack just below) |
| `$0C1BD400` / `$0C1FA000` / `$0C1FCAB8` | Antelope's text / data / bss |
| `$0C1FD51C`-`$0C1FFFD4` | the saved copy of `.data` |

With 2 MB of SIMMs (`+$138` = `$0C3FFFFF`) Antelope moves to `$0C3BD400`
and the stack to `$0C3AD400`; the heap still starts at the end of the frame
buffer and runs on through the DRAM to `$0C3A9400` (about 2.4 MB with a 13"
monitor). With 8 MB (`$0D7FFFFF`, flag bit 20) Antelope is at `$0D7BD400`
and the heap is `$0D000000`-`$0D7A9400` (about 7.66 MB); the VRAM above the
frame buffer then goes unused (service `$CB`, which would grow
`$4C003120`, has no callers). Service `$C1` then reports [PublicIn+`$08`] −
`$1000` − break, ignoring Antelope and the stacks at the top, so HeapCreate
retries about 340 times before its request fits. Nothing ties video modes
or acceleration to the amount of RAM, and the control panel shows none.

### 10.10 The later ROM 341-0266

`341-0266` ("MDC 8•24 GC 1.1", 16-Sep-91, in `Mac_ROMs.zip`) is a 64 KB
part, but only `$0000`-`$5141` is used (format block at `$FFEC`: directory
`$0000`, length `$10000`, CRC `$D722B053`, ByteLanes `$E1`): the larger
EPROM holds no new code (no Am29000 code, no second driver), only
rearranged and extended data.

* **Timing moves into the board sResource.** Each monitor's timing is one
  sBlock in board id `$7E`: pages, 6 rowBytes, vRes, the 16 DP8531 writes as
  bytes, then 40-byte depth records (TV blocks end with a second clock,
  *reading*: for the direct modes). PrimaryInit (`$1FEA`) and VideoOpen
  (`$2980`) both read it with sGetBlock, so the driver shrinks from `$2E5A`
  to `$12D4` bytes and the 8-`lea` compare tree is gone.
* **56 video sResources** `$80`-`$FC` encode the monitor in bits 2-0 (0 PAL
  640, 1 Portrait, 2 12", 3 Two-Page, 4 NTSC 512, 5 16" Color, 6 13", 7 21"
  Color), the other TV size in bit 3, the 24-bit bank in bit 4, 16 bpp in
  bit 5 (set when a RAMDAC probe at `$2598` finds the indexed register 1)
  and unconvolved TV in bit 6, chosen from PRAM. The formerly unreachable
  progressive TV tables (10.8) are now selectable.
* **New monitors and depths.** Sense 0 → 21" Color (the Two-Page timing),
  extended `$2D` → 16" Color, extended `$30` → PAL. Mode `$84` is 16 bpp
  (RAMDAC mode `$9E`/`$BE`, index 1 = `$C0`) on the 13", 12", 16" and TV;
  32 bpp moves to `$85`. Sense 5 and unknown extended codes program a
  fallback timing and delete every sResource. All mode lists are
  terminated; the `$44800000` stream, the old monitors' timings and the
  driver's Control/Status calls are unchanged.

| sRsrc | monitor | depths | H act/bp/sync/fp | H total | lines | clock N/R/P | PCLK | refresh |
|---|---|---|---|---|---|---|---|---|
| `$85`/`$A5` | 16" Color 832×624 | 1-8, 16 | 832/210/64/46 (2:1 multiplex, `$A0`-`$B8`) | 1152 | 667 | 126/22/1 | 57.273 MHz | 74.5 Hz |
| `$87`/`$A7` | 21" Color 1152×870 | 1-8 | as Two-Page | 1456 | 915 | 190/19/1 | 100 MHz | 75.06 Hz |
| `$CC`/`$EC`, `$C4`/`$E4` | NTSC 640×480, 512×384 unconvolved | 1-8, 16, 32 | 640/64/60/16, 512/120/60/88 | 780 | 525 interlaced | 540/55/4 | 12.273 MHz | 59.94 Hz fields |
| `$C0`/`$E0`, `$C8`/`$E8` | PAL 640×480, 768×576 unconvolved | 1-8, 16, 32 (768: 1-8, 16) | 640/145/69/90, 768/81/69/26 | 944 | 625 interlaced | 413/70/3 | 14.75 MHz | 50 Hz fields |

**What Apple said about it.** Apple's Tech Info Library calls 1.1 the
"Rev B" ROM (part number 341-0266; board 661-1642 against Rev A's
661-0606), sold to Rev A owners as upgrade kit 076-1019 and "ONLY needed
for the 16-inch display" (TIL 9913, Jan 1992; TIL 10053, Mar 1992). It also
gives the 21" display "Page-White correction" (TIL 9913); 1.0 already drove
the 21" through raw sense 0 as a colour Two-Page, which fits. 16 bpp ("up
to 32,768 colors") needs Rev B's new CLUT/DAC (the AC842A), so an upgraded
Rev A card drives the 16" without 16-bit colour (TIL 9815, TIL 9858, Feb
1992). No Apple article mentions the dropped raw sense 5.

**Sense handling.** Raw senses 1-4 and 6 are unchanged; raw 0 → code 7
(the 21"); raw 7 reads the extended code: `$14` NTSC, `$00` (the old PAL
box) and `$30` both PAL, `$2D` 16" Color, anything else (no-connect `$3F`,
VGA `$17`, the multiscans, 19") → the fallback `$21F6` with the 13" timing.
Raw 5 (RGB Full-Page) → the same fallback with the Portrait timing. The
fallback is 1.0's `$26BC`: record 0, CLUT entries 0/1 black, interrupt
off, all 56 sResources deleted, so the screen is synced but black and only
the board sResource remains (the card can still accelerate). 1.0 kept raw 5
as a colour Portrait `$A1` (bit 2 cleared at `$2438`); 1.1 drops it,
because code 5 now means the 16". The driver's extended-sense copy
(`$3A1E`, live in 1.0 at `$62F6`), PrimaryInit's WaitForVBlank and
RegTouchLoop copies (`$2528`, `$242A`, dead in 1.0 too) and the stub at
`$32C2` are unreferenced 1.0 bytes.

**16 bpp.** "RAMDAC index 1" is PCBR1, the second pixel bus control
register of the AC842A, the 16-bpp-capable version of the RAMDAC; the AC842
has PCBR0 only (System 7.1 `DAFBDriver.a`: `has16bppACDC`, "true if AC842A
is around"). The probe at `$2598` is DAFB's: `$06` into PCBR0 (indirect
mode), 0 into PCBR1, read PCBR0 back; `$06` means an AC842A, and sRsrc bit 5
is set. For mode `$84` the driver writes PCBR0 = `$9E` (`$BE` with the 2:1
multiplex), then PCBR1 = `$C0` (`$3740`); the depth record sets LSR `$FE`
(n = 7), `$4400007C` = 0 (linear, also on TV) and `$440000A0` =
rowBytes/8. The VPBlocks say RGBDirect 16/3/5 (5-5-5), rowBytes 2 × width
(2560 on PAL). ChkMode sets GFlags bit 10, so SetEntries refuses, and
SetGamma/GrayPage load 32 entries at `(k<<3)|(k>>2)` (`$3B2C`, DAFB's
Trans5to8): a sparse gamma table. Without bit 5, `$84` stays 32 bpp
(`$3B0A`). Antelope 7.0.1 draws 16 bpp fully (its 16-bit arithmetic modes,
NullReport stubs in System 6's SW 1.1, are real code here, e.g. RBAddOver16
`$1E508`), `gc24` never declines a depth, and no host program knows mode
numbers, so the 7.0.1 software works with the 1.1 ROM unchanged.

**The prerelease ROM 1.0A16** (`Dolphin_1.0A16.BIN` in `Mac_ROMs.zip`, 32 KB,
CRC `$4740028D` valid) has the shipping ROM's board sResource name
('Macintosh Display Card 8•24 GC'), BoardId `$2C`, sense map and 16 video
sResources. Its RevLevel is '100a16 2729344499': version 1.0a16 and a Mac
date in seconds, 27 June 1990 15:14:59. This is the format the driver's
RevLevel parser (`$1AAA`/`$1BEC`, section 1) was written for (1.0a16 passes
because an alpha needs a revision of at least `$10`); the shipping
'MDC 8•24 GC 1.0' passes it only by accident. PartNum is '341-0812'. No
codename appears in it: "Dolphin" is the ROM collector's folder name.
Differences from the shipping ROM: driver storage `$2A` bytes (no
saveVidParms); GetBaseAddr (`$5BFA`) lacks the `+$0C000000` VRAM offset, so
it returns the slot base (fixed in 1.0); a simpler ChkMode (no RAM512K or
underscan gate for 24 bpp); NTSC 512×384 porches shifted by 8 pixels; the
PAL 640×480 boot table is 616 pixels wide ("PAL Display 616*460") while its
driver table and VPBlocks say 640×480; mPageCnt 0 and one more unterminated
mode list; no `-1` write to `$44000024`. SecondaryInit, the `$44800000`
stream and most of the driver are byte-identical.

## Appendix: what changed since the exact decryption

For readers of copies older than commit `35a63a3` (2026-11-25), when the
firmware's encryption was solved and every section became exact. Older
statements to the left are wrong; the right column is the current reading
and where it is argued.

| older statement | now | where |
|---|---|---|
| a "second mask" on top of the XOR layer, with per-section tables or keystreams | one running 32-bit key per section, removed by DRVR's `ACEFLoad` | section 6, `SECOND_MASK.md` |
| 103 named Antelope functions, many estimated | all 709 functions named from exact code | `antelope_names.py` |
| the card can reply 2 | only `EngineDispatch` returns 2 (recording a picture, region or polygon) | Overview |
| arguments "after `+$44`" or "from `+$58`" | every command's arguments through the pointer at `packet+$54` (`packet+$650`); only `$15` and PQDInit use fixed blocks | Overview, section 9 |
| the host can overwrite a command the card still runs | the next command waits in `sub_624A` for status bit 1, the completion | "Early release", "When the host waits for the card" |
| `$C6` programs the pixel clock | `$C6` sets the display start and row stride, and nothing calls it | sections 7, 10.1 |
| `$44000028`: sense open | the Am29000's run control (most likely *RESET): 0 held, -1 runs at cs5 | sections 1, 10.1 |
| `$44800000` is the clock synthesiser; `$46800000` a TV filter curve | `$46800000` is the DP8531 clock synthesiser; `$44800000` most likely an MFB configuration chain | 10.3, 10.8 |
| the RAMDAC's byte lanes differ between host and card | both use data bits 31-24; a Bt "RAMDAC 428" | 10.5 |
| Antelope loaded "into card DRAM" | into the top of card RAM, the VRAM on a stock card (no DRAM fitted) | 10.9 |
| the boot mailbox is armed at bring-up and answered by the host | armed only when flag `$800` is clear, which it is not by default; no host code reads a report | section 4 |
| Boot starts when the host pokes `$42005300` | Boot starts when cs5 releases the CPU; the go-ahead is already there | section 1 |
| the `$12E38` text loop is a shadow or outline smear | DrawText.a's underline (`UL1`/`UL2`) | DrawMultiObject, text |
| a "32×32 multiply" at `$00CC4` | FixMul | "The entry table, named" |
| flag bits 1, 3, 10, 30, 31 "read in outline" | kernel debug switches nothing sets | section 8 |
| give-up reasons 4, 6, 9 open | settled; 6 is dead code, 9 spins | section 8 |
