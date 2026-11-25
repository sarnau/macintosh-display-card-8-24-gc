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
before drawing over it and asks the host to redraw it afterwards.

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
| the kernel's services | section 8 |
| the `PupS` resource, Control calls 17-19, the feature flags | section 9 |
| the System 6 package and its Antelope | section 10 |

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
| commands | host → card | `+$14` go, `+$1C` reply, `+$48` selector, `+$4C` sequence, `+$50` count, args after `+$44` | `EngineDispatch` (`gc24.s` `$49C4`) | dispatcher `sub_31e20`, main loop at `$31E0C` in `main` `$31DAC` |
| requests | card → host | `+$24` mailbox: `+$04` code, `+$08` reply, `+$0C` sequence, `+$14` args | `sub_6442`, called from the idle routine and from `EngineDispatch`'s wait loops | `CallBack` `$33EBC` |
| modules | host → card code | commands `$8001`-`$8004` and request 999 | `sub_1404` (gc24 entry #105) | `sub_37B58`, `sub_379A0` |

Bit 2 of packet `+$18` tells the host that a request is waiting. Packet
`+$1C0`/`+$1C4` are a host counter and the card's heartbeat (the nested wait
loop). Separate from all of this are the boot mailbox (section 4) and the
video command block (section 5).

**Commands and replies.** The host sends a selector (`$0C`-`$3C` for drawing
and caches, `$80xx` for modules). A reply of 1 means "done". 0 means "not
handled", and the host runs the original 68k QuickDraw routine. Some patches
use 2 ("run the original without drawing"). Command `$01` resets the
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
scaleBlt `$22A8C`; GetSeek `$253D4`; BitBlt `$01A50` and RgnBlt `$19DA4`
(likely); DrawText `$11AD8`; DrawArc `$075DC`, DrawLine `$08618`, QuickPolys
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
of `.text` (`$3CAD4`; see "The C library"). `antelope_dasm.py` prints these
names (from `antelope_names.py`) in `firmware/disasm/text.asm`.

**Answered by the exact listings** (formerly open): the encryption (a
running XOR key per section, see section 6); service `$C0` (returns
`PublicIn`, `$4C006400`; `InitPacket` adds `$418` to reach the packet
pointer); the pattern fills `$04110` and `$1C8A8` (called directly from
BitBlt `$02B3C` and RgnBlt `$1B090`); and the kernel services, whose table
(section 8) is exact. The ones that were unknown, read in `Hand.asm`:
`$BB` returns the flags word `gr64` (`$2001A58`); `$D1` returns
`PublicOu+$04`, the version `$00700D01` with bits 24-31 filled in by kernel
init from a register probe and from `$46000000` (`$2001A48`, `$20021C4`);
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
- DrawMultiObject: all 24 opcodes are named and their cases found; left open are details of the per-device refresh (two `.data` tables, now exact but not yet read) and why a repeated font upload refreshes only glyphs `$84`-`$9E`;
- why the status bit at `$4400007C` gates the two-colour block fill;
- the give-up reasons 4, 6 and 9 and config bit `$10` (section 9);
- the System 6 Antelope (section 10), now also exact: 620 of its 769 functions are identical to System 7's, 66 changed, 83 only in System 6 (82 only in System 7). Its `.lit` names the 16-bit arithmetic-mode stubs (`RBAverage16Half`, `RB…16`, `Stretch…16`, `Pat…Slab16`). Its 10,928-word block at `$331C4`-`$3DC84` is an Apple Video (`'rpza'`) codec behind commands `$39`-`$3B`: `$374A4` is its decoder (command `$39`) and `$33218` its encoder (`$3A`/`$3B`); the host side is a QuickTime codec at `gc24` `$9510`. The host's `$00`/`$02` pair is a probe behind the driver's Status 10: no Antelope handles `$02`, so its reply stays the 1 the dispatcher stores on taking a command, which is the answer the control panel wants. The stubs mark the 16-bit arithmetic loops that System 7 adds. The encoder's 17-way switches pick shift-based averaging by pixel count, and the `'rle '` path dithers 24-bit pixels to 16 bits with a 4×4 ordered matrix. Open: the codec routines step by step.

## 1. Bring-up (`Init29K` -> `Boot` -> kernel init)

| step | host (`DRVR.s`) | card |
|---|---|---|
| 1 | `ACEFLoad` uploads `Runtime` (sections incl. `PublicIn`, `PublicOu`, `Vec`) | runs from `Boot` ($2003000) |
| 2 | waits until `PublicOu[0]` (image+$400) reads `$32100456` -- a constant of the *uploaded file* (it is the static first word of `PublicOu`), so it only proves the upload landed | - |
| 3 | pokes `image+$18` <- unit flags (+$168), `image+$00` <- `$42005300`, `image+$08` <- card address of the top of DRAM (+$138), `image+$14` <- card address of `(+$134 - $6D1) & ~$FF` | `Boot` polls `$4C006400` (PublicIn+0) until it reads `$42005300`, then clears it (**verified**) |
| 4 | reads `image+$40C` (= `PublicOu+$0C`, `$4C007000` HifComm with the top nibble set by Boot) = mailbox address; writes `mailbox+$0C` <- ack-word address (+$140) and `mailbox+$00` <- `$73333337` ('s337') | Boot (`$2003050`) and kernel init (`$2002004`-`$200200C`) read the host flags from `PublicIn+$18` into `gr64` (**verified**) |

`PublicIn+$18` is consumed exactly as `DRVR.s` publishes it: bit 11 (`$800`,
"mailbox not enabled") gates the reports to the host from the HIF service
path (`$2001BC0`) and from the fatal-trap reporter (`$2002AAC`; with the bit
set a trap restarts the kernel unreported); bit 20 (`$100000`, set when the
DRAM top is above `$0D000000`) selects the heap-limit computation of service
`$C1` (`$20012AC`, free heap = `[PublicIn+$08] - $1000 - break` instead of
`gr127 - $3000 - break`), which uses `PublicIn+$08` as the end of memory
(**verified**); the kernel also tests
bits 0, 5, 8, 21 that `SetFeatureFlags` sets for card types `$2C`/`$7E`
(**reading**: which feature each one switches is not worked out).

Kernel init (`$20020D0`) also stores the signature `$57593160` ('WY1`') at
`VidComm+$18` (`$4C007318`). `Boot` only reads it (`$2003560`): with the
signature present and `VidComm+$08` non-zero it takes the video parameters
from `VidComm` instead of probing the registers. `VideoDriver.s` reads that
word before talking to the Am29000 and falls back to "just retime the clock" if
it is missing (**verified**, both sides).

## 2. `LoadFirmware` (loading Antelope) fields

`ReserveEngineRegion` publishes, in `PublicIn`: `+$20` start of the loaded
region, `+$24` end (start + text + data + bss), `+$28`/`+$2C`/`+$30` text,
data, bss sizes, `+$40` the region start again. The kernel init reads exactly
`+$20/+$24/+$28/+$2C/+$30`: it copies `[+$2C]` bytes from `[+$24]` to
`[+$20] + [+$28]`, the data section's place ($20020F0-$200213C), and clears
the `[+$30]` bytes after it ($2002140-$2002160); `ReserveEngineRegion`
leaves room for that second copy of the data (it reserves `2*data`), and
`Boot` ($2003090) copies the same span the other way. It sets its stack from
`+$40` (`gr125 = [PublicIn+$40]`, `gr127 = gr125 - $10000`, `$2002414`)
(**reading**: roles inferred from the loads, addresses match).

## 3. Starting Antelope, and restart ("PostLoadPoke")

`LoadFirmware` stores Antelope's entry (ACEFLoad's out-parameter) at
`PublicIn+$04`. The kernel init `$2001FFC` ends (`$20025E8-$2002644`) by storing
its heap pointer at `PublicIn+$10`, loading `PC1 <- [PublicIn+$04]`,
`PC0 <- PC1 + 4`, and `iretinv`, i.e. it **jumps to that entry** (unless `gr64`
bit 16 asks to stop with reason `$A1`, `$2002634`) (**verified**: both ends read). Nothing on
the 68k side kicks the program directly; the kick is the restart below, which
`cs13`/`cs48` issue after `cs3`.

### Restart

`PostLoadPoke` writes the flags to `image+$18`, `$FF` to `image+$3D4`
(`$4C0067D4`) and `$FF` to register `$04000050` (card `$44000050`). On the card
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
`'s337'` (bring-up step 4 arms it, each `cs51` re-arms it): it writes the
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
report overflows `$B4`/`$B5`; for the HIF path the service number). The
host's handling of a posted report is `INIT_main.s`/`gc24.s` territory and
was not traced.

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

**The layout bit is the host's.** The clock routine (`$601A`, after
`WaitForVBlank`) writes bit 31 of MFB register `+$80` (`$04000080` from the
host, `$44000080` on the card) with `bfins`. The value is 1, except when
GFlags has `Interlaced` set and `BigScreen` clear, in which case it is 0.
`BigScreen` is set exactly when a TV mode enters 24 bpp. So:

| output | 1-8 bpp | 24 bpp |
|---|---|---|
| Apple monitors (IDs 1, 2, 3, 6) | linear (bit 1) | linear (bit 1) |
| NTSC / PAL | 4-way interleaved (bit 0) | linear (bit 1) |

The same routine writes `+$7C` from the per-depth timing table, so `+$7C`
is not simply the complement of `+$80`, although the two page conversions
wait for them in opposite states. The card waits for them *before* it
acknowledges (`$2000E5C`-`$2000E78` and `$2000F2C`-`$2000F48`, then `+$04 <- 0`),
while the host programs them only after its wait for that acknowledge
(which has a timeout) and, when `savePageCfg` is non-zero, an extra delay
(`$5F78`). Whether the card's waits depend on this host write is open.

## What this corrects

* `DRVR.s` `PostLoadPoke` is a restart request, not a generic "post-load
  poke"; the earlier "doorbell/enable register" guess for `$04000050` is
  right and the doorbell is the video driver's too.
* `Init29K`'s wait on `$32100456` does not wait for the card to boot; it
  checks the *uploaded* data. The real "card is up" handshake is the other
  direction (`Boot` waits for `$42005300`).
* The earlier statement that the Am29000-side mailbox code was not in the files
  was wrong: it is `$2002650` in `Hand`.

## 6. What Antelope uses from the kernel (and what is still unknown)

**Correction.** Antelope's sections are encrypted like the Runtime's: DRVR's
`ACEFLoad` decrypts each with a running 32-bit XOR key (see "Antelope: the
encryption (solved)"). Everything earlier in this project that read `.text`
(243 KB, 62,134 words) as plain compiled code used the encrypted bytes (it
found zero `jmpi lr0` returns and zero `sub gr1,gr1,N` prologues), and the
later partial decodes are superseded. `firmware/disasm/text.asm` is the
exact listing: 768 functions, 103 of them named.

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
  service 1 (exit).
* **Hardware.** Antelope also addresses card registers directly: `$4400007C`
  and `$44000080` in the long fills (`$17040`, `$172A4`), and the CLUT
  (`$46C00000`) and registers `$44000054`-`$440000C8` in the self-test.

(The earlier attempts to model the `.text` key from the 747 spill/fill
words and their neighbours are summarised in "Antelope: the encryption
(solved)".)
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
  `+$1C`: 1 = drawn, 2 = drawn but run the original too.
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
block's offset from `$31DA8`; the default is `$A70` → `$32818`. (Before the
loader's decryption was found, this table and the other `.lit` switch tables
were fitted from a partial decode. The exact listing replaces that fit. It
confirms the DrawMultiObject entries pinned from the host's record layout
(`.lit $0484`-`$04BC`) and ColorMap's switches (`.lit $0128`-`$01B8`).)

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
| `$1B` | `$325D0` | one long -> `$14274`: `CacheFind(1, p[0])`, then `CacheRelease(1, entry)` (the host sends `$1B` from MakeITable) |
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
GDevices (2), pixel patterns (5) and offscreens (6), plus a type 1 that
command `$1B` releases. The one-long commands keep those caches in step:
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
| `$8008` | `$378DC(argv[0..2])`: `CopyHostMemory` |
| `$8011` / `$8012` | allocate / free (`$3779C`, `$377CC`) |
| `$8013` | `$3791C(argv[0..3])`: `MapVirtual` |
| `$8014` | `UnmapAll`, then `$16BA0` |
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
through engine globals `+$14+$1A4`). Nothing else in this repo calls that
entry, so it is an API for other code (the selectors and their arguments
follow). Its state is a `$7A`-byte handle (`*&handle`, created on first use):

| offset | field |
|---|---|
| `+$00` | module table, `$1C`-byte records, `+$5E` of them (grows by 16) |
| `+$04` | task table, `$20`-byte records, `+$5A` of them (grows by 32) |
| `+$08` | module counter |
| `+$0C` / `+$0D` | request posted / reply ready (bytes) |
| `+$0E` | command (`$8001`-`$8004`) |
| `+$12` | reply |
| `+$16`, `+$1A`, `+$1E` | arguments; `+$56` = their count |
| `+$66` | a device handle (`sub_225C(slot)`); its `+$6C` points back here |
| `+$6A` | the last result |
| `+$76` | a `$5C`-byte message buffer in card memory (from `$8002`) |

The selectors (`sel - 1` first, then `$3DC` for 999):

| sel | routine | does |
|---|---|---|
| -1 | | return the last result |
| 0 | `sub_1604` | open: allocate the tables; send `$8004(0x11111111, 0x22222222, 0x33333333)` and require the reply `$66666666` (else -4); allocate the card message buffer with `$8002($5C)` (else -5) |
| 1 | `sub_1A2E`, params `{acef, size}` | load a module: `$8002(size)` allocates card memory, `ACEFLoad(acef, addr, size)` relocates and copies it there; returns module id `$53000000 \| n`. The module record keeps the card address (`+$08`) and the entry point (`+$0C`) |
| 2 | `sub_1B3C`, params `{module id}` | unload: kill the module's tasks, `$8003(addr)` frees its memory |
| 3 | `sub_1C94`, params `{module id}` | create a task of the module; returns task id `$54000000 \| n` |
| 4 | `sub_1D70`, params `{task id}` | kill a task: send it message `$FFFE`, free its handler list |
| 5 | `sub_1E12`, params `{task, sel, proc, refcon}` | register a host callback `proc` for selector `sel` of `task` (`sub_1810`, a linked list per task) |
| 6 | `sub_1E7E`, params `{msg}` | send a message and wait for the reply |
| 7 | `sub_1FD6`, params `{msg}` | send a message without waiting (sets bit 7 of `msg+8`) |
| 8 | `sub_2130`, params `{task id}` | wait for the task's reply and return it |
| 9 / 10 | | return 1 / 0 |
| 11 | `sub_22DA` | idle: pump the mailbox and the card's requests |
| 999 | `sub_18BE` | a request from the card (below) |

**Sending a message.** A message is `{+$04 task id, +$09 length in bytes,
+$0A message type, +$0C data}`. `sub_1E7E` waits until the task is idle (state 0 or
2), copies the message into the card buffer `+$76` (with `SwapMMUMode` to
32-bit), and posts `$8001(buffer, task.+$08, module entry point)`. The task
is then in state 3 (running) until the card answers. So **`$8001` is "run
this module's entry point on this message"**, and its card side is
`p[2](p[0], p[1], sub_379A0)`: `entry(message, task data, services)`
(**verified**). The uploaded code gets Antelope's service switch, and with
it the entry table that holds `DrawMultiObject`. Task creation (`sub_1BEE`)
sends message `$FFFF` and kill sends `$FFFE`, so these are the module's own
init and exit messages.

**How the mailbox reaches the card.** The `$80xx` commands do not use a
separate channel. `sub_22DA` (the idle routine, which every wait loop calls)
takes a posted request and runs `EngineDispatch(+$0E, &+$16, +$56)`, the same
path as the drawing commands. It stores the reply in `+$12` and sets
`+$0D`. It then checks the card's status word: if bit 2 is set, it clears it
and calls `sub_6442`, the handler for requests from the card.

**Requests from the card (`sub_6442`).** The card writes a code into a
mailbox at its base address `+$24` (`+$04` of it). The handler reads it, sets it to
-1, and switches on codes 3-8, 12-18, 20-22, 100 and 999. Code 999 forwards
the card's request to `sub_1404(999, …)`, which reads `{task id, selector,
count, argv}` and runs `sub_18BE`:

| selector | does |
|---|---|
| `$8002` | the task's reply: store `argv[0]` in the task (`+$18`), state 2 (done); with no task, it is the reply to a mailbox command (`+$12`, `+$0D`) |
| `$8003` | state 1 |
| `$8004` / `$8005` | get / set a module field (`+$10`) |
| `$8006` / `$8007` | get / set a task field (`+$08`) |
| `$8010` | `_Debugger` |
| `$8000`, `$8001`, `$8008`-`$800F` | nothing, or -1 |
| > 0 | call the host callback registered for this selector: `proc(count, argv, refcon)` (Pascal order) |

On the card, `$8004`-`$8007` are sent by `$37838`, `$377FC`, `$378A8` and
`$3786C` (get/set module field, get/set task field), and after a `$8003`
request `sub_37730` calls `sub_32AB8(1)`.

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
| 6 | `SetPtrSize(p[0], p[1])` | |
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
master. That is presumably how it reaches host-side pixel maps.

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
| `$37730` | 999 (module request) | 4: task, selector, count, argv | the `$80xx` service switch `sub_379A0` (unhandled selectors) and `$377FC`, `$37838`, `$3786C`, `$378A8` |
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
- uses the GDevice cache (`$14F64` CacheGDevice, `$14D78` `MakeITable`,
  `$14BD4`) and `CopyHostMemory` `$16C48` (codes 8 and 18);
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
| `+$0C` | `$01A50` | **BitBlt** (likely) | called by StretchBits, DrawLine, QuickPolys and DrawMultiObject; does *not* call `GetSeek`; switch tables by mode (`.lit $0008`-`$0068`); falls back to `$19DA4` |
| `+$10` | `$19DA4` | **RgnBlt** (likely) | calls `GetSeek`; called by BitBlt, StretchBits, text and shapes; a four-way switch picks one of four mode loops `$1B33C`, `$1BAE0`, `$1BC64`, `$1BDE8` (`$1B2A0`-`$1B2DC`) |
| `+$1C`, `+$20`, `+$28` | `$075DC`, `$08618`, `$19270` | the three shape drawers that use `GetSeek`: `$075DC` **DrawArc**, `$08618` **DrawLine**, `$19270` **QuickPolys** (settled by DrawMultiObject's polygon opcode, below) | same helpers (`$0E398`, `$1114C`, `$17500`, `$1553C`); called by DrawMultiObject |
| `+$24` | `$11AD8` | **DrawText** (see "Text and fonts") | calls StretchBits and scaleBlt (scaled text goes through StretchBits in QuickDraw) and RgnBlt, not BitBlt; uses `extern#1772+$60`-`$6C` |
| `+$18` | `$3008C` | a `GetSeek` user. Its object file (`$30088`-`$31DA4`) holds five more routines, each entering an unrolled loop through a 15-entry `.lit` jump table (`$0C30`, `$0C6C`, `$0CA8`, `$0CE4`, `$0D20`; entries are offsets from `$30088`) | |
| `+$08` | `$0AD18` | **DrawMultiObject** | its strings; calls all of the above |
| `+$04` | `$13770` | command `$2D` | calls DrawMultiObject, `MapVirtual`, the caches |
| `+$3C`, `+$40` | `$32C10`, `$32EF8` | **ShieldCursor** (before drawing) and its counterpart (after drawing): the cursor lock with the host, see "The cursor" below | |
| `+$34`, `+$38` | `$153D4`, `$1553C` | set that rectangle: `$1553C(r, origin)` stores `r` minus `origin` as four 16-bit words at `extern#1772+$78`-`$7E`; `$153D4(r1, r2, origin, flag)` stores `r1`, unioned with `r2` minus `origin` when `flag` is set, and returns whether it is non-empty | |
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
| 32×32 multiply `$00CC4` | **yes (2 refs)** | no | no |
| calls BitBlt / RgnBlt | no | yes | yes |
| own switch | none | 6-way on `lr35` (`.lit $0228`) | none |
| ShieldCursor | once each | `$32C10` twice | once each |

The shared helpers are runtime and support code:
- `$00CC4` is a 32×32 multiply (31 `mul` steps);
- `$3BA38` is an unsigned divide (31 `div` steps);
- `$3B814`/`$3B950` are the multiply and divide millicode entries (called with `calli gr122`);
- `$1114C` and `$11A34` return the address of a scanline loop chosen by
  the mode (36 and 7 possible loops; `$1114C` partly through `.lit`
  tables such as `$0508`), like QuickDraw's mode-case tables;
- `$0E398` is a short arithmetic helper, and `$17500` an allocator.

Readings:
- `$19270`, with three times the stores, fits **QuickPolys**, which builds
  and sorts an edge list.
- `$075DC` is the only one that multiplies, and the most shift-heavy.
  It is arcs or lines: in the 68k sources both `DrawArc.a` (`SlopeFromAngle`,
  `_FixMul`) and `DrawLine.a` (`FixMul`, `MULS`) multiply, and
  `QuickPolys.a` divides (`FixRatio`).
- `$08618` is then the other of the two. Its 6-way switch matches the
  6-way sub-switches in DrawMultiObject (`lr94`), so both probably select
  by the same kind of value.

So only QuickPolys = `$19270` was a likely name here. DrawMultiObject's
polygon and line records settled the rest later: `$08618` is DrawLine and
`$075DC` DrawArc (see "DrawMultiObject: the batched drawing stream").

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

Replaying net hides as ShowCursor calls looks inverted. Since ShowCursor
stops at level 0, the extra calls may simply be harmless. The code is as
read, but the intent is not settled.

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
clears `+$1EC`. Why the card keeps its own copy rather than writing the
host's save area directly is not stated anywhere. Its save area is host
memory reached through a mapping, the packet is local, and a reset is the
point where the host takes over the cursor again; those may be the reasons.

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
  * StdPoly and StdRgn reserve their record size.
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
   `lr24`, …), which follows `ColorMap` in `QDUtil.a` step for step. It
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
       complement (but see section 5: the host writes `+$7C` from its timing
       table). The kernel's pixel-clock stub `$20012E8` also halves both of
       its values when the bit is set. For `$1701C` this means: the block
       write works only in the linear layout, and interleaved memory falls
       back to the `storem` burst. The host sets the layout (section 5):
       linear on every Apple monitor at every depth, and on TV output at
       24 bpp. So `$1701C` uses the block write almost everywhere, and
       `$00348` only for 1-8 bpp NTSC/PAL frame buffers.

       `$17264(dst, a, b, count)` (Fill2Longs, PQDInit's descriptor `+$30`)
       is the two-value version. With `a` = `b` it calls `$1701C`. Otherwise
       it tests bit 31 of `$4400007C` the same way, before its own aligned
       paths. So the second status register gates the two-colour
       case. The matching burst helpers are `$00294`, which loads two
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
       (the address-space bit and option 3) is presumably the cycle the
       card's bus logic turns into a NuBus block write; `$D3` is the
       service that brackets the host-memory mapping (1 on entry, 0 on
       release; see "Card: `MapVirtual` and host memory"). **`$D5`:**
       Hand's `$2001260` returns
       `[$4C00643C]` (`PublicIn+$3C`) when its argument is negative, and
       otherwise clears bit `lr2` of that word and mirrors the result to
       `$46000000`. `$37000` calls `$D5(-1)` to read the mask and
       `$D5(slot)` to drop a slot that failed. So the word is a per-slot
       "burst transfers work" mask, and `$46000000` presumably the hardware
       copy of it. The host's command `$14` (`$D5(p[0])`, sent from the
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
       sets `$200` is described in section 9: it does, by default. So the
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
the filled verbs do in QuickDraw. That case named `$08618` DrawLine and
`$19270` QuickPolys, and `$075DC` DrawArc by elimination (it is also the one
that multiplies: `SlopeFromAngle` and `FixMul` in `DrawArc.a`).

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
* bits 1-4 → **`$14A80(handle, ptr, size)`**:
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
  1. `$15A7C` makes room, evicting if needed;
  2. `$15958` allocates the entry;
  3. it stamps the entry, zeroes its data, sets the key and links it at the
     head;
  4. `$15ACC` counts it.
* **`$15FF4(kind, key)`** is find-or-create.

The kinds seen so far:

| kind | holds |
|---|---|
| 2 | GDevice (the cursor code looks up `CrsrDevice` with `$15D28(2, …)`) |
| 3 | bit pattern (record `$73`, created by `$1610C`) |
| 4 | RGB pattern (record `$73`, keyed by the 24-bit colour) |
| 5 | PixPat (CachePixPat, command `$0C`) |
| 6 | used by commands `$0D`/`$0F` |
| 8 | font strike |
| `$0A` | width table |

**On the card: drawing the text.** `$11AD8`, called from the text case, is a
7 KB routine with the shape of QuickDraw's `DrawText.a`:
* the clipping set-up (RSect, TrimRect twice) and the ShieldCursor pair;
* one buffer from PQDAlloc `$16A04`, or two when a flag (`lr58`) is set,
  presumably for a shadow mask. Each is cleared, with a leading zero long.
  The left edge is rounded down to 32 pixels, and the width is counted in
  longs plus 2;
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

After the glyphs are built into the buffer, a row loop (`$12E8C`-`$12EB8`)
walks a row from right to left, forms each long OR'd with itself shifted
left by one, plus the top bit carried from the long to its right, and ORs
the complement of that into a second buffer (pointer in `lr70` there):
`dst |= ~(x | x<<1 | carry)`. That is a one-pixel smear of the glyph image, as bold, outline
and shadow use it in `DrawText.a`; which style takes this loop is not read.

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
glyph in the strike), so the clipping to `width` happens in DrawText. Why a
repeated upload refreshes exactly `$84`-`$9E` (Mac Roman `Ñ` to `û`) is not
known; the only caller takes that path when the cache entry already holds
the handle and its `FontRec` copy.

##### Open points

* **ColorMap's alpha-channel part** (`$06F1C`) is not checked against
  `QDUtil.a`.
* **`$17500`**, called before every BitBlt and RgnBlt of the rectangle and
  region cases (and by DrawArc, DrawLine and QuickPolys), is not read.
* **The address bits `$01200000`** that send a run to FillLongsBurst
  instead of the block write: what they select in the card's memory map is
  not read.
* **Why a repeated font upload re-converts only glyphs `$84`-`$9E`** (`$14564`, the `new = 0` path).

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
  selector itself (`$0C`-`$38`; the table covers `$00`-`$3C`). The host rewrites some selectors only to
  `$24` StdRect: a rounded rectangle with zero radius, or a rectangular
  region.
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
   code is `$0B` instead of 3. How the host handles `$0B` is not traced here.

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
and `$39`-`$3B`. (Before the `.lit` key was known, this was argued from the
low byte `$70` of these entries and the block layout; the exact table
agrees.)

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

* Its heap descriptor sits at `.data+$1388` (0 in the file).
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
| `$33`, `$19`, `$1A`, `$1B` | `$324F8`, `$32570`, `$325A0`, `$325D0` | the same | `$14034` DisposeOffscreen, `$14168` FlushOffscreen, `$141F8` FlushColorTable, `$14274` |
| `$3C` | `$32528` | copies `p[0]`, `p[1]` into a frame on the memory stack and calls `handler(&frame)`: a two-long command | `$140CC` |
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
| `$11` | `$3210C` | `sub_15D84(i)` for i = 0..10, then `sub_16BA0()` | `$15D84`, `$16BA0` |
| `$17` | `$320C8` | `PQDInit(packet+$604)`; reply 1 if it returns 0, else -1 | `$161F8` |
| `$15` | `$32148` | `StretchBits(packet+$58, 0, 0, 0, 0)`; reply 0 if it returns more than 0 | `$2D7B8` |
| `$2D` | `$32188` | `r = sub_13770(packet+$170)`; reply 1 if `r` = 0, -1 if `r` = -1, else 0; for `r` = 7 it first calls `PQDInit(p[0])` (reply 1 if that returns 0) | `$13770`, `$161F8` |
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
of `antelope_modules.py`; an earlier reading took `$11AD4`-`$174FC` for one
module). Five of them (`$14034`, `$140CC`, `$14168`, `$141F8`,
`$14274`) are consecutive functions of `$50`-`$9C` bytes, each called by one
one- or two-long block. They are cache flushes: three name themselves by
their messages, `$14274` releases a type-1 cache entry (`CacheFind(1,
p[0])`, then `CacheRelease`), and `$140CC` releases the type-6 (offscreen)
entry whose `+$20`/`+$24` match the two longs.

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
| `$39284` | `printf` | spills its varargs; if bit 15 of the flag halfword of `stdout` (`.data+$15A4`) is set (presumably append mode), `$39304(stdout, 0, 2)`; then `$399E0($39118, stdout, fmt, ap)`, where `$39118` is the output routine handed to the formatter |
| `$39214` | `vprintf` | the same without the spill |
| `$399E0` | `_doprnt` (the formatting core) | calls memchr (4 times; `%s` with a precision), the `_ctype_` table, and the number converters `$3A5A4`-`$3A768` |
| `$39304` | `fseek` | calls lseek; `(fp, 0, 2)` is `SEEK_END` |
| `$3B500` | `memchr(s, c, n)` (earlier read as memset) | returns 0 if `n` = 0; replicates `c` into a word and scans with `cpbyte`; returns the address of the match or 0 |
| `$3B600` | `memcpy(dst, src, n)` | returns `dst`; byte, halfword or word loops by alignment, forward only; 30 call sites, 26 of them in Apple's code |
| `$3B748` | `memset(dst, c, n)` | returns `dst`; replicates `c`, stores words, masks the partial words at both ends; one caller (`$3B300`) |
| `.lit+$1021` | `_ctype_` (+1 for EOF) | |
| `$3AA9C`-`$3ABB4` | isupper, islower, isalpha, isdigit, isxdigit, isspace, ispunct, isalnum, isgraph, isprint, iscntrl | `_ctype_[c]` masked with 1, 2, 3, 4, `$44`, 8, `$10`, 7, `$17`, `$97`, `$20`: the V7/BSD bits `_U _L _N _S _P _C _X _B` |
| `$3ABD0` `$3ABE0` `$3ABEC` `$3ABF8` `$3AC24` | isascii (c ≤ `$7F`), `_toupper`, `_tolower`, toupper, tolower | `c - $20` / `c + $20`, the last two only if `_L` / `_U` |
| `$3AC88` | `exit` | walks a handler table (`.data+$1560`-`$1580`), calls `$3C1D4` (presumably the stdio cleanup), then HIF exit |
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
pointer. The reporter level starts at 1 (`.data+$284`) and the log size at `$400` (`.data+$298`); see "`.data` decoded".

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

Boot replaces the top nibble of the four pointers with the value it probes
at `$4400000C` (see `Boot.asm`). `PublicOut` also holds, at `+$510`, the
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
host's packet is at offset `$s08C00` of the slot space, card SRAM
`$4C008C00` (`PublicOut+$18`), right after `InpArgs`. No host program writes a field at
`+$418`, the kernel never touches `$4C006818` and never builds `$8C00`, and
neither host program writes into `InpArgs` (`$4C007800`, which only the
kernel's getargs uses).

## 8. The kernel's service table (vector 66)

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
| `$B8` | `$20018E4` | timer interrupt enable (TMR bit 24): returns the old state, sets or clears it by `lr2` | `$39094` |
| `$B9` | `$20018B8` | OPS bit 4 (`$10`): returns the old state, sets or clears it by `lr2` | `$39084` |
| `$BB` | `$2001A58` | returns `gr64`, the host's feature flags (`PublicIn+$18`) | `$38F44` |
| `$BF` | `$2001924` | OPS bit 1 (`$02`), as `$B9` | `$390A4` |
| `$C0` | `$2001408` | returns `$4C006400` (`PublicIn`, the comm header) | `$38FC8`, `InitPacket` and the feature-flag readers |
| `$C1` | `$20012AC` | free memory: `gr127 - $3000 - gr65` (stack limit minus break) | `$38F24` |
| `$C4` | `$2001250` | returns `[$4C00682C]`, the value Boot probed, shifted left by 28 | `$38F34`, the own-memory test `$13F54` |
| `$C5` | `$2001224` | waits for the video interrupt: enables it at `$44000054`, polls `$44000068`, disables it | `$38F54`, `TestCLUT` |
| `$C6` | `$20012E8` | serial write to the pixel-clock chip (`$44000080`/`$440000A0`) | `$38F74` |
| `$C7` | `$2001374` | writes three bytes (`lr2`-`lr4`) to the RAMDAC at `$46C00000` | `$38F84` |
| `$C8` | `$20013AC` | reads CLUT entry `lr2` (0-255, else -1) from the RAMDAC | `$38F94` |
| `$CB` | `$2001414` | adds `lr2` to `[$4C003120]` when `gr64` bit 20 is set, else returns 0 | `$38FF8` |
| `$CC` | `$200146C` | region-table add (`$2001478`): map a memory range | `$39018`; `TestMMU`, `MapVirtual`, the dispatcher |
| `$CD` | `$20015F8` | region-table remove (`$2001604`; -1 = all) | `$39028`; `TestMMU`, `MapVirtual`, `UnmapAll`, the dispatcher |
| `$CE` | `$2001774` | checks that `lr2` is 1 KB-aligned, then works on the region table at `$4C003168` (not read further) | `$39038` |
| `$CF` | `$2001950` | set interrupt handler `n` (0-3) to `fn` (`$4C00617C + 4n`); 0, else -1 | `$390D4`; `TestInterrupts` |
| `$D0` | `$20019BC` | return from an interrupt handler (the flag and saved registers at `$4C00618C`) | `$390E4`; the interrupt handlers |
| `$D1` | `$2001A48` | returns `[$4C006804]` (`PublicOut+$04`) | `$390F4` |
| `$D2` | `$2001294` | restarts the kernel (`jmp $2001FFC`) when `gr64` bit 28 is set, else returns 0 | `$38F64`; every accepted command |
| `$D3` | `$2001820` | host access mode: stores `lr2` at `$4C006848`, switches OPS bit 6, returns the old mode | `$390B4`; `TestMMU`, `CopyHostMemory`, `MapVirtual`, the dispatcher |
| `$D4` | `$2001808` | translates `lr2` through the table walker `$2001C2C`: physical address in `gr96`, length in `gr122` (the stub stores it to `*lr3`) | `$39050`, `$39064`; `TestMMU`, `CopyHostMemory` |
| `$D5` | `$2001260` | slot burst mask: `lr2 < 0` returns it, else clears bit `lr2` of `[$4C00643C]` and writes the mask to `$46000000` | `$39104`; command `$14` |
| `$D6` | `$2001888` | clears `gr64` bit 8 and sets OPS bit 11 (not read further) | `$390C4` |

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

## 9. Configuration: `PupS` and Control calls 17-19

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
| `+$0` | 1 | accelerator on/off: `gc24` 32 stops with error `$D8DB` (reported through cs20) if it is 0; the control panel's `sub_d30` writes it, and `sub_8ca` applies it |
| `+$4` | `$D2` (210) | not read by either path seen |
| `+$8` | `$60` | the config word, sent with cs17 |
| `+$C` | `$4B0` (1200); System 6 `$3C0` (960) | sent by `gc24` 32 with cs18, which stores its low word at unit `+$002`: the card-response timeout in ticks (below) |

`gc24` 32 (the startup sequence) sends cs17, cs18 and cs19 in turn,
each followed by a check that maps a failure to errors
`$D8DB`-`$D8DF`. Before its cs17 it would XOR the config with `$90`
if a local flag (`d5`) were set, but `d5` is cleared at entry and
never set, so this is dead code. So the config word is `$60` by default:
bits `$20` and `$40` are set, and `SetFeatureFlags` turns them into
feature flags `$1` and `$200`. No client sends cs50, so `$100` stays
clear and the "mailbox not enabled" bit `$800` stays set: the card's
debug messages are not delivered. (An earlier version of this paragraph
said that no client sends cs17. That came from scanning only some of
the control panel's `_Control` calls.)

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
   `globals+$14+n`. This presumably switches the patches back to the
   original routines; the installer side was not checked;
3. posts a Notification Manager alert (`_NMInstall`), "Graphics
   accelerator is having difficulty. You will need to reboot to re-enable
   it." (Pascal string at `$76CA`).

It skips all of this if the config word has bit `$80`. That is one of the
two bits `gc24` 32's dead `eori #$90` would have flipped, so `$80` looks
like a "never give up" debug setting. The other callers pass reasons 4,
6 and 9 (`$6FC8`, `$72F4`, `$730C`, `$734E`), not traced. A gc24 entry at
`$1068` returns unit `+$15C`, the last reason.

## 10. The System 6 package ("8•24 GC SW 1.1")

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
and `Boot` listings are plain generated ones, not annotated.

### The System 6 key

The System 6 ACEFs decrypt exactly with the same `ACEFLoad` scheme as
System 7's (`acef_unpack.py`). The KEY byte is `$D7` for `ACEF` 100
(System 7: `$4D`) and `$18` for `ACEF` 1 (System 7: `$BC`). (An earlier
version of this section fitted a key per word from relocation and idiom
samples with `antelope6_key.py`. That tool is removed.)

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
compares with `$726C6520`, `'rle '` (Animation), and takes the
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
  `$A0`, `$C0`, `$E0` (the four opcode classes of an `'rpza'` block
  stream: skip, one colour, four colours, sixteen colours) and once with
  `$E1` (the chunk header byte). It is entered by command `$39`.
* `$33218` is the **encoder**. It ORs `$80`, `$A0` and `$C0` into opcode
  bytes, and it is the larger one: 4,259 words of colour arithmetic (`and
  $1F` with shifts by 5 and 10, the fields of a 16-bit pixel), dividing
  through `div_millicode`. It is entered by commands `$3A` and `$3B`.
* For `'rle '`, `$39` calls `$3A964` and `$3A` calls `$3A254`; `$3B` calls
  `$33218` for both types.

**The decoder's layout.** `$374A4` (2,579 words) first calls MapVirtual
(`$2F2D4`). It reads the first byte (byte reader `$3DA34`) and
compares it with `$E1` (`$375D4`): with `$E1` it runs `$375DC`-`$38BB0`, which uses compare
chains, otherwise `$38BB0`-`$39CF0`, which uses four 8-way jump tables on
the top bits of a word (`srl $1C`, `sub 8`, `cpgtu 7`; `.lit $1248`,
`$1268`, `$1288`, `$12A8`). Each half splits on a local holding the
destination depth (`cpneq` with `$20`, `$10` and `$08`; any other depth
exits) into a 32-bit, a 16-bit and two 8-bit copies of the block loop
(the two chosen by a flag bit, `sll …, $19`). In the first half each copy
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
  case is 15 words. There is one switch per pixel of the 4×4 block, each
  writing one of the four 2-bit colour indices.
* **The two 17-way switches split a 4×4 block's pixels into two groups and
  average each.** Before `$34EE8`, an unrolled sequence tests, for each of
  the 16 pixels, the sign of a difference (`sub`, then `cpgt …, 0`;
  presumably the pixel against a threshold). One branch adds the pixel's
  fields to one set of sums and increments `lr80`, the other adds them to
  a second set. The switch index is `lr80`, the number `n` of the 16
  pixels in the first group, so the second group has `16 - n`. The own
  cases are exactly the `n` where `n` or `16 - n` is a power of two (or
  0): there the average is a shift (`sra` by 4, 3, 2 or 1), and the other
  group's sums go through `div_millicode` (`calli` to `$41950`). The
  shared default divides both. The averages are packed as 5-5-5 colours
  (`sra 3`, `sll 10`, `sll 5`): the two colours of an `'rpza'` four-colour
  block. `$3BEBC` (in `$3B27C`) is a second copy with the same cases.
* **The `'rle '` rotation is an ordered dither.** The four targets add a
  constant to each of three 8-bit channels, saturating at `$FF`: `T0`
  (`$3ABC8`) adds 4 (`cpge $FC`), `T1` (`$3AC14`) adds 2 (`cpge $FE`), `T2`
  (`$3AC60`) adds 6 (`cpge $FA`), and `T3` (`$3B250`, where the others join)
  adds nothing. The index is `(a << 2) | (lr5 &
  3)`. `lr5` is the pixel's x: it gains each line's skip count and is
  incremented in the delay slot of the per-pixel loop (`$3AD98`). So `b` is
  the column mod 4, and `a` (not traced) presumably the row mod 4. The loop
  reads a byte: with bit 7 set, `(b & $7F) + 1` pixels follow in one colour,
  given as three bytes. The matrix is

      row 0:  0 4 2 6
      row 1:  6 0 4 2
      row 2:  2 6 0 4
      row 3:  4 2 6 0

  a 4×4 pattern of 0-6 added before the channels are cut to 5 bits. So
  `$3A964` converts 24-bit pixels to 16 bits with dithering. The second
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
  byte is not `$E1`, so it reads another format, not traced.
* **The decoder's exit.** `$39CAC` calls UnmapAll (`$2F5BC`, System 7's
  `$33A9C`) and returns 1. 23 jumps (among them the out-of-range branches
  and the unknown-depth exits) and 12 table entries land on it. In the
  first table cases 1, 2, 3 and 5 instead go to `$38E4C`, that table's
  default, which returns -1 without unmapping.

**The host side** (System 6 `gc24`, 68020 code at `$8580`-`$A1D0`). `$8580`
passes (codec type, parameter block, selector, instance) to `$9510`.
`$9510` accepts only `'rpza'` and `'rle '` (otherwise `-8939`) and switches
on selector `$10`-`$19`:

| selector | routine | does |
|---|---|---|
| `$10`, `$11` | `$9BBA` | sends `$39` (12 longs): decompress |
| `$12`, `$13`, `$14` | `$9752` | sends `$3A` (11 longs), or `$3B` (16 longs) with an extra 32-bit PixMap: compress |
| `$15` | | returns 0 |
| `$16` | `$A0B4` | codec info: name "8·24GC Road Pizza", vendor `'appl'`, version 4, flags `$43001`/`$4009` |
| `$17` | `$A124` | returns -1 |
| `$18`, `$19` | `$A110`, `$A19A` | |

Both senders lock the PixMaps (`_QDExtensions` LockPixels, GetPixBaseAddr,
GetPixelsState) and pass base addresses, row bytes (`& $3FFF`), bounds
and depth to the card, then wait for the reply.
* `$9BBA` requires a 16-bit PixMap for `'rpza'` (else `-8956`). It returns
  a byte count and a time estimate (`× 50 / (width × height)`) through
  two output pointers.
* `$9752` takes a PixMap of depth 8, 16 or 32 for `'rpza'`, and only 32 for
  `'rle '`. At depth 8 it uses the PixMap's colour table.

The direction comes from the card's opcode tests. The host side does not
name it.

Of System 6's 618 direct calls, none goes into the block from outside, and
`.lit`/`.data` hold no pointers into it apart from its own switch tables,
so the dispatcher's six address loads (and `calli`) are its only entries.
Inside it, `$33218` calls `$3B27C`, `$374A4` calls `$39CF0`, and `$3C668`,
`$3C7C4`, `$3DA08`, `$3DA34`, `$3DA5C` and `$3DAAC` are loaded as function
pointers. Nine functions in it have no reference at all: `$39E50`,
`$39EB4`, `$3A0CC`, `$3C810`, `$3C904`, `$3C94C`, `$3CA3C`, `$3CA64` and
`$3DBC4`.

There are no floating-point instructions in either version, so the block is
not a floating-point trap emulator.

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

**The System 6-only probe: `$00`, then `$02`.** System 6's host does send
`$02`, although no Antelope of either version handles it:
* `gc24` ID -4048 begins with a table of 44-byte entries, each a long ID,
  a stub, and at `+$28` a `bra.w` to the routine. The driver (`DRVR`
  -4048, `$10B0`) walks it. A positive ID is a trap to patch. A negative
  ID `-n` stores the entry's `+$28` in the driver globals at
  `$A78 + 4n`. ID -1 is `$85AA` (slot `$A7C`), -2 is `$8638` (`$A80`),
  and -3 is `$8580` (`$A84`, the codec entry above).
* `$85AA(unit, value)` sends `$00`. If `value` is not 0, it sets the
  unit's timeout word (`+2`) to 500, sends `$02` with `value` as its one
  long, stores the reply at unit `+$174` and puts the timeout back. Then it
  sends `$00` again. It returns `+$174`.
* The driver calls it from Status csCode 10 with the long that Control
  csCode 4 stored at its globals `+$12C`, and returns the result. If the
  result is not 1, it sets bit `$100` in the unit's flags (`+8`). Control
  13, 17 and 50 call `$85AA(unit, 0)` after re-initialising the card.
* The control panel's `$0C08` sends Control 4 with `$FFFFFFFF`, then
  Status 10. Its caller (`$128E`) accepts the answer 1. Otherwise it
  restarts the accelerator (`$0A5C`: Control 99, Status 5, Control 14,
  Control 2) and asks again. A non-zero answer then gives error `$D8EA`
  (reported through Control 20).

**The probe answers 1.** Both ends are now read:
* For selectors below `$0C`, `$6224(cmd, args, n)` writes the packet
  directly (`$77D4`-`$795E`): `+$18` = 0, `+$48` = `cmd`, `+$4C` = the
  sequence number (`+$20` of the unit, incremented), `+$50` = `n`, the
  arguments from `+$58` on, and `+$14` = -1. It waits until bit 0 or 1 of
  the status long (`[unit+$10]`) is set. Then it returns packet `+$1C`
  (`$7A60`). A timeout returns 0 and sets bit 1 of unit `+$1C`
  (`$7A96`). The host never writes `+$1C` itself.
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

