# Host <-> card protocol (68k driver <-> Am29000 runtime)

Both sides are now readable, so the protocol can be written down from the code
instead of inferred from one end. Everything below is cross-checked against
`DRVR.s` (host), `../extracted-source/VideoDriver.s` (declaration ROM), and the
unmasked firmware `firmware/disasm/Boot.asm` / `Hand.asm` (card). Addresses are
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
| the encryption ("mask") of Antelope and how much of it is solved | section 6 and the "Antelope mask: …" sections, including the `.lit` key and its pins |
| the kernel's services | section 8 |
| the `PupS` resource, Control calls 17-19, the feature flags | section 9 |
| the System 6 package and its differently masked Antelope | section 10 |

**How sure is it?** The 68K side (`DRVR.s`, `gc24.s`) is plain code.
Antelope is masked:
* opcode bytes and the low 15-19 bits of each word are known;
* bits 16-23 (RC and the high immediate byte, so also branch targets) are
  estimated from neighbouring samples for 98% of the words. The key's high
  bits are a step function, and the estimate was never wrong in held-out
  tests (section 6, "bits 16-23 from the neighbours");
* `.lit` has a separate key, recovered in bits 0-11 with host-confirmed
  pins;
* `.data` is still masked.

So card-side details are readings unless the text says they are checked
against the host or against QuickDraw's sources (`System 7.1 Source Code`).

## Overview: what the card does, and how the host talks to it

This summarises the sections below and gives the current state. Where an
older paragraph further down disagrees, this overview and the
DrawMultiObject section are the reference.

**Three channels**, all in one shared block in card memory (the "packet",
`[.bss]` on the card, `$C(device record)` on the host):

| channel | direction | where | host side | card side |
|---|---|---|---|---|
| commands | host → card | `+$14` go, `+$1C` reply, `+$48` selector, `+$4C` sequence, `+$50` count, args after `+$44` | `EngineDispatch` (`gc24.s` `$49C4`) | dispatcher `sub_31e20`, main loop at `$31E0C` |
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
sequence numbers on both sides.

**What the card accelerates (this firmware, ACEF_100 "32-Bit Antelope"):**

| command | host routine | card |
|---|---|---|
| `$15` | `StretchBits` (trap `$AB27`; CopyBits ends here) | `$2D7B8` StretchBits, with `scaleBlt`, BitBlt and RgnBlt. Reaches host pixel maps through `MapVirtual` |
| `$33`, `$19`, `$1A`, `$0C`, `$17`/`$2C`, `$29`/`$2B` | offscreens, colour tables, pixel patterns, GDevices changing | DisposeOffscreen, FlushOffscreen, FlushColorTable, CachePixPat, FlushPixPat, FlushGDevice: the card's caches of host objects |
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

**Named card functions** (the evidence is in the sections below): the
dispatcher `$31E20`; DrawMultiObject `$0AD18`; StretchBits `$2D7B8`;
scaleBlt `$22A8C`; GetSeek `$253D4`; BitBlt `$01A50` and RgnBlt `$19DA4`
(likely); DrawText `$11AD8`; DrawArc `$075DC`, DrawLine `$08618`, QuickPolys
`$19270` (from DrawMultiObject's polygon opcode); RSect `$01494` and TrimRect `$01654`
(from its region opcode); ITabMatch `$06650`; ColorMap `$06F1C`; the long fills `$1701C` (block write), `$17264` (two values) and `$00348` (`storem` bursts), with the burst helpers `$00294` and `$00248`; the slot burst self-test `$37000`; the own-memory test `$13F54`; the host-object cache: find `$15D28`, find-and-stamp `$15E8C`, create `$15EE4`, find-or-create `$15FF4`; font upload `$14B64` (width table) and `$14A80` (strike); BitsToPixMap
`$06BEC`; DisposeOffscreen `$14034`; FlushOffscreen `$14168`;
FlushColorTable `$141F8`; CacheGDevice `$14F64`; CachePixPat `$151C4`;
FlushGDevice `$15808`; FlushPixPat `$158F4`; PRInit `$161F8`; PRAlloc
`$16A04`; `MapVirtual` `$3373C` and its release `$33A9C`; ShieldCursor
`$32C10` and its after-drawing counterpart `$32EF8`; `CallBack`
`$33EBC`; the request wrappers `$33BD0`-`$33E88`; the card heap
`$372D0`-`$3772C`; the `storem` fill `$37D68` and its family
`$37C10`-`$38C3C`; the reporter `$00140` and its log buffer `$00F84`; the
C library `$39118`-`$3C340` (see "The C library"). `antelope_partial_dasm.py`
prints these names in `text.partial.asm`.

**Still open:**
- DrawMultiObject: all 24 opcodes are named and their cases found; left open are details of the per-device refresh (two masked `.data` tables) and why a repeated font upload refreshes only glyphs `$84`-`$9E`;
- kernel services: `$D5` is settled (the slot burst mask); `$BB` (feature flags), `$D1` and `$D4` (address translation) have candidate stubs but are not confirmed; `$D2`, `$B8`, `$B9` and `$BF` are unknown. The service table's pointers are only approximate (section 8);
- why the status bit at `$4400007C` gates the two-colour block fill;
- `.data`, still masked: the mode and ColorMap tables, the report level, the shared fill flag `.data+$280`, and the function tables that presumably reach the pattern fills `$04110` and `$1C8A8`;
- the give-up reasons 4, 6 and 9 and config bit `$10` (section 9);
- a closed form for the `.text` key. Bits 16-23 are estimated from neighbouring samples for 98% of the words; 1,277 words stay undecoded;
- the System 6 Antelope: its key is largely recovered (opcode byte, bits 0-12, bits 16-23 by neighbours; section 10), and its functions are matched to System 7's (645 of 768 with the same code; all 83 named ones found). Its `.lit` key is known in bits 0-8 (`antelope6_lit.py`), which names 26 stubs for the 16-bit arithmetic modes. Its 10,928-word block at `$331C4`-`$3DC84` is an Apple Video (`'rpza'`) codec behind commands `$39`-`$3B` (`antelope6_tables.py`), and the stubs mark the 16-bit arithmetic loops that System 7 adds. `$374A4` is its decoder (command `$39`) and `$33218` its encoder (`$3A`/`$3B`); the host side is a QuickTime codec at `gc24` `$9510`. The host's `$00`/`$02` pair is a probe behind the driver's Status 10: no Antelope handles `$02`, so its reply stays the 1 the dispatcher stores on taking a command, which is the answer the control panel wants; and the dispatcher fits System 7 for 53 of 60 commands, the other seven explained. The codec's switch targets come from fitting key bits 11-15 (`antelope6_switches.py`): settled for the encoder's 18 switches and the `'rle '` pair, open for the decoder's four. Open: the decoder's switch targets, the `.data` key, the codec routines step by step.

## 1. Bring-up (`Init29K` -> `Boot` -> kernel init)

| step | host (`DRVR.s`) | card |
|---|---|---|
| 1 | `ACEFLoad` uploads `Runtime` (sections incl. `PublicIn`, `PublicOu`, `Vec`) | runs from `Boot` ($2003000) |
| 2 | waits until `PublicOu[0]` (image+$400) reads `$32100456` -- a constant of the *uploaded file* (it is the static first word of `PublicOu`), so it only proves the upload landed | - |
| 3 | pokes `image+$18` <- unit flags (+$168), `image+$00` <- `$42005300`, `image+$08` <- card address of the top of DRAM (+$138), `image+$14` <- card address of `(+$134 - $6D1) & ~$FF` | `Boot` polls `$4C006400` (PublicIn+0) until it reads `$42005300`, then clears it (**verified**) |
| 4 | reads `image+$40C` (= `PublicOu+$0C`) = mailbox address; writes `mailbox+$0C` <- ack-word address (+$140) and `mailbox+$00` <- `$73333337` ('s337') | kernel reads the host flags from `PublicIn+$18` into `gr64` (`$2002008`) (**verified**) |

`PublicIn+$18` is consumed exactly as `DRVR.s` publishes it: bit 11 (`$800`,
"mailbox not enabled") gates every call to the mailbox reporter (`$2001BC0`,
`$2002AAC`); bit 20 (`$100000`, set when the DRAM top is above `$0D000000`)
selects the heap-limit computation of service `$20012AC`, which uses
`PublicIn+$08` as the end of memory (**verified**); the kernel also tests
bits 0, 5, 8, 21 that `SetFeatureFlags` sets for card types `$2C`/`$7E`
(**reading**: which feature each one switches is not worked out).

`Boot` (and the video driver's present-check) also stores the signature
`$57593160` ('WY1`') at `VidComm+$18` (`$4C007318`); `VideoDriver.s` reads that
word before talking to the Am29000 and falls back to "just retime the clock" if
it is missing (**verified**, both sides).

## 2. `LoadFirmware` (loading Antelope) fields

`ReserveEngineRegion` publishes, in `PublicIn`: `+$20` start of the loaded
region, `+$24` end (start + text + data + bss), `+$28`/`+$2C`/`+$30` text,
data, bss sizes, `+$40` the region start again. The kernel init reads exactly
`+$20/+$24/+$28/+$2C/+$30` and copies the data section ($20020F0-$200213C), and
sets its stack from `+$40` (`gr127 = [PublicIn+$40] - $10000`, `$2002410`)
(**reading**: roles inferred from the loads, addresses match).

## 3. Starting Antelope, and restart ("PostLoadPoke")

`LoadFirmware` stores Antelope's entry (ACEFLoad's out-parameter) at
`PublicIn+$04`. The kernel init `$2001FFC` ends (`$20025E8-$2002644`) by storing
its heap pointer at `PublicIn+$10`, loading `PC1 <- [PublicIn+$04]`,
`PC0 <- PC1 + 4`, and `iretinv`, i.e. it **jumps to that entry** (unless `gr64`
bit 15 asks to stop with reason `$A1`) (**verified**: both ends read). Nothing on
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
then `'s337'` (`$73333337`) to `mailbox+$00`. Card (`$2002650`, the reporter
used for both traps and mailbox service): reads `mailbox+$00`; if it is
`$73333337` it takes the argument from `+$08`, writes `$80000000 | reason` to
`+$04`, and writes the posted marker `$96666669` to `mailbox+$00` and to the
host's ack address stored at `mailbox+$0C`. So the host's "ack word" becomes
`$96666669` when the card has consumed the request (**verified**; the exact
*meaning* of the payload is not known -- the card passes it back via `gr77`/the
register dump).

Fatal traps use the same mechanism in the other direction: the card posts
`reason -> +$04`, a 16-word register dump -> `+$10`, `$96666669` -> `+$00`, then
waits for the host's `'s337'` (**verified** on the card side; the host's
handling of a posted trap is `INIT_main.s`/`gc24.s` territory and was not
traced).

## 5. Video command block (`VidComm`, `$4C007300`)

`VideoDriver.s` (mode set) fills: `+$08` frame-buffer base (superslot form),
`+$0C` row bytes, `+$10` depth, `+$14` vertical resolution, `+$1C` page
configuration; writes `+$00 <- $80000000` and rings the doorbell
(`$04000050 <- $FFFFFFFF`); waits (with a timeout) for `+$04` to read 0; and
later writes `+$04 <- $FFFFFFFF` to let the card continue. The card's service
`$2000C14` (run from INTR2 when no handler is registered) reads exactly those
fields (`+$08` -> `gr74`, `+$0C` -> `gr75`, `+$14` -> `gr77`, `+$1C` -> `gr68`),
clears `+$00`, and if command bit 0 is set writes 0 to `+$04` and spins until
the host writes a non-zero value back -- i.e. the card pauses while the host
retimes the clock (**verified**). It computes the frame-buffer size with a
32-step multiply, then acts on the page configuration (`+$1C`): 1 and 2
trigger the bulk word copies ($2000DBC.. / $2000E8C..), other values skip them.
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
wait for them in opposite states. The card's waits after a conversion are
for this host write: the host programs the registers after the card has
acknowledged the command. When `savePageCfg` is
non-zero, the driver also waits an extra delay after the card acknowledges
(`$5F78`).

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

**Correction.** Antelope's `.text` (243 KB) is **itself masked** with the same
kind of generator as `Hand`/`Boot`; everything earlier in this project that read
it as plain compiled code (`disasm/text.asm`, opcode statistics, "no service
calls", function boundaries by prologue) used the masked bytes and is
unreliable. Tell-tales: zero `jmpi lr0` returns and zero `sub gr1,gr1,N`
prologues in 62,134 words (compiled code would have thousands), and register
fields that are uniformly random. Only the opcode byte is intact (and the RC byte
in the first ~100 words).

What survives from the loader's own view of it, because it lives in the
relocation table and not in the instruction bytes:

* **Register stack.** The loader patches the vector byte of 293 `asgeu` words
  with `64` (the spill check `asgeu 64,gr1,gr126`) and of 454 `asleu` words with
  `65` (`asleu 65,lr1,gr127`), which match the kernel's spill/fill handlers
  `$2001184`/`$20011B8` (vectors 64/65) (**verified**).
* **Externals.** 21 undefined symbols, all common (bss) variables of 4-424 bytes
  (one 152-byte block referenced 536 times); names stripped.
* Whether Antelope calls the kernel services (`asneq 69`) or touches hardware
  addresses is **unknown**: its operand fields cannot be read until the mask is
  solved. The entry stub (`Code`, 38 words) also shows an `asneq trap69` and a
  `const` with plain high byte `$01` before it (words 8-9), and a second one
  (word 35) before the exit `jmp`, consistent with a `$1xx` service call (maybe
  `$104`, the `InpArgs` pointer) and `exit`.

**Mask status.** The 293 `asgeu 64,gr1,gr126` and 454 `asleu 65,lr1,gr127` words
are known plaintext spread over the whole section, so key values at 747 positions
are recoverable (`firmware/ACEF_100_Antelope/mask_samples.tsv`, key =
file word XOR the known word, with a zero RC placeholder). They show: key bits
0-6 are a clean table with period 48 (all 48 phases covered, no conflicts);
bits 7 and up do **not** follow `Hand`'s `0x80*(ROW-k)` ramp with a per-phase
table (the jitter amplitude is several hundred rows, with plateau jumps), so
Antelope's generator has additional structure that is not yet modelled and
`text.bin` cannot be unmasked yet.

Further attempt (not solved). The plaintext of the neighbours extends the
samples: the word before every `asleu 65` is `jmpi lr0` (`$C0000080`, 454 of 454;
its delay slot holds the assert), the word before an `asgeu 64` is
`sub gr1,gr1,N` (281 of 293) and the word after it `add lr1,gr1,N` (214), so
`mask_samples.tsv` now holds 1,201 full 23-bit keys (`asgeu`, `asleu`,
`jmpi lr0`). Findings: adjacent keys (`jmpi`/`asleu` pairs) differ by about
+-1000 with no per-phase regularity (only the low 7 bits are per-phase);
`(key>>7) + k` mod 256 is not periodic in `k mod P` for any P up to 260, and
shows sawtooth runs (slope about +1.5 rows per word, reset every ~80 words,
amplitude ~200 rows) in dense stretches, i.e. a multi-level counter rather
than `Hand`'s single ramp. A closed form was not found.

### Antelope mask: second attempt (more plaintext, still unsolved)

Counting idioms through the (unmasked) opcode byte gives far more known
plaintext than the spill/fill words alone: **all 2,064 words with opcode `$70`
are the NOP `aseq trap64,gr1,gr1` (`$70400101`)** -- each agrees with the
48-entry low-bit table -- and 915 of the 997 `$C0` words are `jmpi lr0`
(`$C0000080`). With the 747 spill/fill words that is 3,726 full key values,
about one per 17 words, in `firmware/ACEF_100_Antelope/mask_samples.tsv`.

What the denser data show (no closed form yet):

* Within a 100-200 word stretch the row part (`key >> 7`, plus the word index)
  is a staircase: it rises by about **64 rows** every 20-35 words, four times,
  then drops by about 192 (= 3 x 64); occasional jumps of +320 (5 x 64) and
  +1336 appear at larger scale. That is a mixed-radix counter with a base-4
  digit of weight 64 rows, not `Hand`'s single ramp.
* Small jitter (+-6 rows) rides on top, but it is **not** a fixed function of
  `k mod 48`: two samples in adjacent phases of the same 48-word block differ by
  values that scatter over about +-10 rows from block to block, so the
  jitter/staircase is indexed by something other than the word index mod 48.
* The jump positions do not follow a fixed period (best-fit periods explain
  under 40% of them), and `key >> 7` is not additive in a per-phase table plus a
  per-block table.

Conclusion: Antelope's 243 KB stays masked; a solution would need the real
generator (probably the same structure as `Hand`'s, with several more levels)
rather than more fitting of samples, or a larger known-plaintext set such as the
`.data`/`.lit` sections' repeating constants.

### Antelope mask: what else was tried (negative results)

* The key's two lowest bits are **not** zero as in `Hand`/`Boot`: with period 6
  in the word index they read `00 00 11 00 00 01` (phases 2, 8, 14, ... give
  `$6F` in the low 7 bits, phases 5, 11, 17, 23 give `01` in the low two bits),
  so the table `C48` (all 48 phases, no conflicts, in the samples file) has
  entries that are not multiples of 4. Antelope's generator therefore differs
  from `Hand`'s in the lowest bits too.
* A regression of the 23-bit key on the bits of `k` (with or without a mod-3
  term) leaves a residual of about half the key's spread, so the key is not a
  weighted sum of the bits of the word index; the +64-row jump positions are
  not periodic in `k` and are not aligned to multiples of 8, 16, 24, 32 or 48.
* The mixed-radix look (weights 1, 8, 64, 320 rows) is reminiscent of a DRAM
  row/column address multiplex, and the three code images sit at different
  physical places (`Hand`/`Boot` in on-card SRAM at `$2000000`, Antelope in DRAM
  at an address `ReserveEngineRegion` chooses), so one hypothesis is that each
  generator is a function of the load region's address mapping; no test of it
  was possible without a way to obtain more plaintext.

### Antelope mask: third attempt (a T-function, partly modelled)

**Correction.** The fill-check plaintext used for the 454 `asleu` samples was
wrong: it was taken as `asleu 65,lr2,gr127` (`$5600827F`), but the kernel's fill
idiom is `asleu 65,lr1,gr127` (`$5600817F`). All 454 of those keys were off in
bits 8-9, which is where the "plateau jumps" and "jitter not a function of
`k mod 48`" in the attempts above came from. `mask_samples.tsv` now holds the
corrected keys. The other 3,272 samples are unchanged.

With the corrected samples the generator has a clean structure:

* **Each key bit `b` is an exact function of `k mod 48*2^(b-6)`** (period 48
  for bits 0-6, then 96, 192, 384, ... doubling per bit). There are no conflicts
  for any bit 0-16. Through bit 12 almost every residue class holds several
  samples, so this is a strong result there. From bit 13 up most classes hold one
  sample, so the test says little. A period that doubles with each higher bit is
  the signature of a **T-function**: bit `b` depends only on bit `b` and lower
  bits of a counter. An example is an adder `R = J(k) + M*k`, whose carries
  propagate upward only.
* Bits 7-9 within each phase `p = k mod 48`, across 48-word blocks
  `j = k div 48`, follow `a_p + j + c_p*(j & 1) (mod 8)`. The jitter part
  therefore has period 96, not 48.
* A linear model `R = J[k mod P] + M*k` with a free table `J` reproduces the
  samples exactly:
  * through bit 10 with `P = 96` (`M mod 32 = $18`);
  * through bit 11 with `P = 192`;
  * through bit **12** with `P = 384`, i.e.
    `key mod 2^13 = J[k mod 384] + $400*(k div 384)` (`$400 = 384*$18 mod
    2^13`). An exhaustive search over the block step confirms this. All 384
    phases are covered. A fit on 3,000 random samples predicts the other 726
    exactly. (An earlier note here said "through bit 13". That was one bit too
    many: bit 13 has 378 conflicts at the best step.)

  Each extra level seems to double the table period, so the jitter term is
  itself a deeper counter (like `Hand`'s `ROW`/`COL` pair, but with more
  levels).
* Bit 13 and up resist every simple extension tried:
  * adding quadratic or cubic terms in `k div 384` (a Hensel lift finds none
    exact at bit 13);
  * a separable sum or XOR `A[k mod P] + B[k div P]` for P = 48..768;
  * removing a carry out of the 13-bit field, with or without negating the
    upper field (Hand-style), at any carry offset.

  All leave 1,200-1,600 conflicts. Bit 13 therefore comes from a different
  mechanism than bits 0-12.
* A constant second difference (`R` quadratic in `k`) does not fit for any
  spacing of 48 to 480 words.

**Partial unmask: `unmask_antelope_low.py`.** It rebuilds `J` from the
samples file and XORs bits 0-12 of every word of a section. (It now goes
further; see "deeper levels" below. Its outputs are
`firmware/ACEF_100_Antelope/text.partial.bin` and `lit.partial.bin`.) Bits 13-22
stay masked, and so does bit 23 (Antelope's key is 24 bits wide; see the idiom
section below). In an Am29000 word that leaves plain the RB field or low
immediate byte, and the low 5 bits of RA. Still masked are RA's top 3 bits
(local versus global), all of RC, and the high immediate byte. Two independent checks,
neither from data the fit used:

* **Prologues.** The word before each `asgeu 64` decodes as `sub gr1,gr1,N` in
  281 of 293 cases, with every N a multiple of 8 (frame sizes 24, 16, 32, 48,
  56, 40, 64, 8, ...).
* **`.lit` switch tables** (same generator, indexed by the word's position in
  `.lit`). **Withdrawn as a check of bits 2-12**; see "the command dispatcher"
  below: `.lit` has its own key above bit 1. All 662 relocated words decode 4-aligned. Within each run the
  targets (mod 8 KB) cluster, e.g. `0858 0878 08f8 08c8 0908 097c ...`, and
  some cases repeat a target exactly (`1378 1378`, `0128 0128`). That is the
  shape of compiled switch tables, which random bits would not give. The hit
  rate on decoded `sub gr1,gr1,N` prologues is at chance (13% vs 13%), so the
  runs point at case labels, not functions.

### Antelope mask: function-frame idioms (894 more full keys)

With bits 0-12 plain, the neighbourhood of the known spill and fill asserts
decodes to the standard Am29000 frame:

| idiom | position | count | plaintext |
|---|---|---|---|
| `sub gr1,gr1,N` | word before `asgeu 64` | 281 | `$250101NN` |
| `add lr1,gr1,N` | word after `asgeu 64` | 163 | `$158101NN` |
| `add gr1,gr1,N` | 3 words before `asleu 65` (epilogue) | 450 | `$150101NN` |
| tag word | word before the `sub` | 277 | `$00......`: zero only in bits 0-15 |

N is read from the plain low byte. Test of the guessed upper fields: the
implied keys' bits 13-16 were compared with existing samples in the same
`k mod 48*2^(b-6)` class. They agree in every case (e.g. epilogue
`add`: 177/177, 88/88, 39/39, 12/12), against 50% for a wrong guess. The tag
word agrees through bit 15 but only 7/12 at bit 16, so its upper byte is
not zero, and it was left out. RC's bit 23 (`lr1` vs `gr1`) cannot be tested
this way, so those two idioms rely on the standard calling convention for
that one bit.

`mask_samples.tsv` now holds **4,620 keys, as 24-bit values** (column
`key24`). The old column was named `key23` but already held bit 23. Two
findings follow:

* **The key is 24 bits.** In every idiom, raw bit 23 differs from the
  plaintext in about half the words. The key's bit 23 is 0 at low indices,
  like bit 22. Unlike `Hand`, Antelope masks the RC field's top bit too.
* **The bit-period rule is now well tested through bit 16.** Every key bit
  `b` from 13 to 23 is consistent with depending only on `k mod 48*2^(b-6)`.
  The idioms land in classes already holding independent samples: 3,353
  classes at bit 13 and 4,514 at bit 16, out of 4,620 samples. From bit 17 up
  every class holds one sample, so those bits are untested.
  Equivalently: bit `b` depends only on `k mod 3` and bits `0..b-3` of `k`,
  the dependence `J[k mod 48] + 8*k` would give, but the update is not linear
  (see above).

What the high bits look like: `key >> 16` runs `00 02 1c 1e 19 1b 15 17 16 10
12 2d 2f 2b 24 27 21 23 22 3d 39 ...` as `k` grows. The high nibble steps
`0 1 2 3 c d e f` over the section, and the low nibble falls with small jitter
inside each step, like `Hand`'s negated `-(r>>16)` field.

### Antelope mask: deeper levels (bits 13-17)

The same shape repeats at every level, with a longer table. Each line is
exact on all 4,620 full samples. Each is also tested by fitting the table on
about 3,700 random full samples and predicting the rest:

| bits | model | held-out |
|---|---|---|
| 0-12 | `J13[k mod 384] + $00400*(k div 384)` | 920/920 |
| 0-14 | `J15[k mod 1536] + $07000*(k div 1536)` | 851/851 |
| 0-15 | `J16[k mod 6144] + $04000*(k div 6144)` | 397/397 |
| 0-16 | `J17[k mod 12288] + $18000*(k div 12288)` | 218/218 |
| 0-17 | `J18[k mod 24576] + $10000*(k div 24576)` | 98/98 |

Each step is fixed by the level below up to one new bit, and only one of the
two choices fits. The steps also agree with a slope of `$18` (24) per word
mod 32. Only the per-class tables are unknown, and they grow with each bit
(tried and failed: a 48-entry table plus linear or XOR-combined counters, and
affine functions of the bits of `k div 48`). A closed form for the tables is
not found, so each level is filled only where the samples reach. From bit 16
up the period is a fifth of the section or more, so a sample there fixes only
the two to four words at `k + n*P`.

**Partial samples from register patterns.** Many instructions are fixed by
their opcode and low 13 bits: for example `$16`/`$0060` has RA's top bits = 3
(RA in `gr96..gr127`) in 432 of 433 words where they are plain. I took the
121 (opcode, low 13) patterns with at least 20 such words, of which at least
99% agree. Then I predicted bits 13-15 for the pattern's other words.

* Held out: on words where bits 13-14 were already plain, the prediction was
  right in 4,369 of 4,383 cases (99.7%).
* That gives 5,043 **partial samples** (`pattern16` in `mask_samples.tsv`, 4th
  column `bits` = 16; I dropped 7 that conflicted within a class). They feed
  only the levels up to bit 15, after two rounds.
* Result: `J13` and `J15` are complete, and `J16` covers 5,916 of 6,144
  classes.

`unmask_antelope_low.py` unmasks each word as far as its class is covered.
For the 62,134 `.text` words:

* bits 0-14 for all;
* bits 0-15 for 59,697 (96%);
* bits 0-16 for 20,060;
* bits 0-17 for 11,315.

It writes `text.partial.bin` / `lit.partial.bin` plus a `.known` sidecar (one
byte per word: the number of plain low bits). Bits 13-15 are RA's top three
bits, so **RA is complete for 96% of instructions**. Bits 16-17 are RC's low
two bits.

Independent checks, on words that are not samples of any kind:

* **No impossible registers.** The Am29000 has no `gr2..gr63`. Of 34,502
  decoded RA fields of ALU-class instructions (opcodes `$10..$9F`), **none**
  falls in that range. Random bits would put 24% there.
* **Plausible registers.** For `add` with an immediate, RA is `gr125` (817;
  `msp`, the memory stack pointer in the AMD calling convention), `gr96`
  (633), then `lr8`, `lr2`, `lr10`, `lr3`, `lr11`, `gr97`, `gr98`, `lr4`, ...:
  the return, temporary, argument and local registers compiled 29K code uses.

### Antelope mask: bits 16-23 from the neighbours (a step function)

No closed form for the tables above was found, but bits 16-23 do not need
one. **`key >> 16` is a monotone step function of the word index.**
* Leave-one-out on the 8,508 full samples: where the samples on both sides
  of a sample have the same bits 16-23, the middle one has them too, in
  8,268 of 8,268 cases. Where they differ (240 cases), its value is always
  one of the two. Bits 19-23 alone have only 16 plateaus of about 4,180
  words. Their values 00, 03, 02, 05, 04, 07, 06, 19, 18, 1B, 1A, 1D, 1C, 1F,
  1E, 11 follow `v ^ ((v & 8) << 1)` with `v = i + 2*(i & 1)` for plateau
  `i`, the same kind of sign-folded count as `Hand`'s high field.
* So between two samples with equal bits 16-23 every word has them. Between
  two that differ, the value switches once. `high_key()` in
  `unmask_antelope_low.py` tries every switch point, scores the decoded
  bits 16-23 against how often each opcode carries each value in the sample
  words, and keeps the words whose value is the same for every switch point
  within a likelihood margin. Held out at transitions, with the statistics
  fitted on the other half of the samples, it was right for 703 of 703
  words. Those are idiom words, which are easier than average code.

Result for `.text`: bits 16-23 for 60,857 of 62,134 words (8,508 samples,
48,826 with agreeing neighbours, 3,523 inside a step). The other 1,277 are
ambiguous steps or words whose bit 15 is unknown.

**Independent check: the branch targets.** None of this used jump or call
displacements, whose high byte is in bits 16-23. Of the 7,773 direct
relative jumps and calls among the estimated words (relocated calls left
out):
* all 415 calls land exactly on a function start of the symbol table;
* 7,251 jumps stay inside their own function, and 106 go to a function
  start (tail jumps);
* one does not: `$34F34`, a word inside a step.

`antelope_partial_dasm.py` decodes these words in full (marked `~`, or `!`
inside a step), with branch targets and names. `antelope_estimate_words.py`
uses the same estimate. The earlier readings that rested on estimated words
hold: the block-write registers `$4CC00000`/`$4CC00004` and the alias
`$00400000` in `$1701C`, the status word `$4400007C` in `$17264`, and the
`$200` test after service `$BB` in `$37D68`.

One more negative result for a closed form: a constant XOR in front of a
linear count, `(key ^ C) - M*k` depending only on `k mod 48` (Hand's shape),
has no solution beyond bit 7.

### Antelope: partial disassembly

`antelope_partial_dasm.py` writes `firmware/disasm/text.partial.asm`. Every
`.text` word is decoded with what is plain:

* opcode, RA (or `?rN` where its top bit is not known), RB and the low
  immediate byte are shown;
* RC (the destination of ALU ops), the high byte of 16-bit immediates and so
  all jump and call targets print as `?`;
* words whose whole plaintext is known (the frame and padding idioms) are
  decoded in full;
* labels are the 768 `.text` entries of the ACEF symbol table.

On loads the destination is RA, so loads read completely apart from their
control fields.

The listing reads as real compiled 29K code. One example is `sub_00178`. It
sets the funnel-shift count from an argument (`mtsr FC, lr5`), loads 16 words
into `gr96..gr111` (`mtsrim CR,$0f` + `loadm`), runs them through a chain of
15 `extract` instructions, and stores the result with `storem`. That is the
inner loop of a bit-aligned block copy, the core of a CopyBits-style blit.

Instruction mix:

* `add` 14,953;
* `load` 5,496 / `store` 2,722;
* `const` 5,187 / `consth` 2,202;
* `jmpt` 5,149;
* `sll` 2,873, `srl` 1,409, `sra` 714;
* `calli` 1,155 against `call` 555;
* `jmpi` 997;
* 608 `.word` (invalid opcodes: data embedded in `.text`).

### Antelope: the command dispatcher (`sub_31e20`)

The partial listing finds the function that runs the host's QuickDraw
commands. There are about 65 switch statements: a `cpgtu` bound check, then
`sll 2`, `const`/`consth` of a table address, `load` and `jmpi`. Their bounds
are plain, because they are low immediates. All but one are 4 to 30 cases. One
is 61 cases, at `$32850`:

    cpgtu  ?, lr8, $3c        ; command > $3C -> default
    sll    ?, gr96, 2
    const  gr122, $??80 / consth gr122   ; table (reloc. symbol 1135)
    add    ?, gr122, gr96
    load   ?, ?, gr96, gr122
    jmpi   gr96

`$3C` is the largest command the host sends (`GA_PmBackColor`). The function
is `sub_31e20` (`$31E20`-`$328C8`), in the module whose `.text` starts at
`$31DA8` and whose `.lit` starts at `$0D60`. What it does, from the plain
fields:

* It loads a packet pointer from a global and tests packet `+$14`. The host
  writes `$FFFFFFFF` there when it posts a request (`gc24.s` `$604A`).
* It stores 1 in packet `+$1C`. The host reads its return code from
  `+$1C`: 1 = drawn, 2 = drawn but run the original too.
* It loads the command number into `lr8` from `+$04` of a second record,
  which is also reached through a global.
* About 37 case blocks end in `jmp` to a common exit. Most store the reply
  (`lr12`) through `+$1C` again. Many call a handler with `calli`. The
  `calli` target is masked in the code, but the relocations name it (see
  "Relocations name the targets" below).

The table is `.lit` `$0DE0`. That is the module's `.lit` base `$0D60` plus
the plain `$80`, and it is exactly one of the ten relocated `.lit` runs (61
words, `$0DE0`-`$0ED0`). So command -> case block is fixed by 61 words. They
are still masked, and the next point is why they cannot be read yet.

**`.lit` does not use the `.text` key (correction).** Decoded with the
`.text` key at the same word index, the 61 entries hit the dispatcher's case
blocks once in 61 (chance is about 3). Across all ten runs, 175 relocated words
sit in modules smaller than 8 KB. Decoded the same way, 109 fall inside their
module's code range mod 8 KB, against 123 expected by chance. So only
bits 0-1 of the `.text` key (700 of 700 aligned) are shown to hold for `.lit`.
The earlier "31 of 31 targets inside `.text`" check was weak: every decoded
target was below `$5948`, including those in tables owned by modules near
the end of `.text`. `lit.partial.bin` is therefore right only in bits 0-1.

**Rechecked with the entries read as module offsets.** A relocated `.lit`
word names the module's `.text` section symbol (for this table, symbol
1129+1 = `.text $31DA8`). So it holds the target's *offset* from the module
start, not the absolute address. The default case is then the known offset
`$32818 - $31DA8 = $A70`.

(A "case blocks start right after a `jmp`" test used in the previous round is
**withdrawn**: its 19-of-19 score on the dispatcher blocks was circular,
because those blocks had been found by splitting after `jmp`. The negative
results below do not depend on it.)

What holds:

* **The `.lit` key is its own, but related.** Raw bits above the offset's
  width are key bits. They equal the `.text` key at the same index in 431 of
  492 words (bits 14 and up, small modules; most misses are borrows, the
  `.lit` key one lower). Fitting per run, seven of the ten runs prefer lag 0.
  Three prefer a lag: run `$0958` about 10 words, the dispatcher table
  `$0DE0` 19 (the `.text` key's high bits jump at word 889, the table's at
  908), run `$0F78` about 12.
* **The dispatcher table repeats a plaintext.** Raw entries 24 apart agree in
  bits 0-6 in 16 of 50 pairs, and 48 apart in 4 of 13 (chance 1.6 and 0.4).
  At distance 12 the excess is only what the 24- and 48-pairs bring in. So
  the `.lit` key's bits 0-6 repeat every 24 words (in `.text`, bit 6 needs
  48), and many entries share one value, presumably the default `$A70`.
  Rows 9-11 agree across all three of their entries (for example entries
  9, 33 and 57 all end in `$C8`). Over all of `.lit` the distance-24 excess
  is 29 of 300 against 9.4, most of it from this table.
* **For comparison, the `.text` key's own periods**, measured on the bit
  0-12 model: bit 0 repeats every 3 words, bits 0-1 every 6, bits 0-4 every
  12, bit 5 every 24, bit 6 every 48, and each higher bit doubles it
  (bit 12: 3,072). So the key is three interleaved streams (k mod 3), each
  with T-function periods.

What was ruled out, scored by how many dispatcher entries decode to exactly
`$A70` (and how many small-module entries land in range):

* every index shift `.lit` k -> `.text` k+δ, δ = 0..3,071 (all distinct
  shifts of bits 0-12): at most 2 entries hit `$A70`;
* a constant added to or XORed onto the `.text` key's bits 0-12: at most 2;
* affine maps k -> a·k+b, a in {-2, -1, 1, 2, 3, 4}: assuming the 23 entries
  in the repeating rows are all `$A70`, at most 1 of 23 keys reproduced;
* a per-run unknown base for the decoded offsets: no run better than chance.

Under the 19-word lag, the keys implied by the 23 presumed defaults match the
`.text` key in bits 8-15 over long stretches. The low byte differs by an
amount that follows no visible pattern (the lag itself drifts by a word or so).
So the next model to try is the `.text` generator's structure with `.lit`'s
own low tables, fitted to the repeating entries.

**Fitting the dispatcher table directly (not solved).** Working assumptions:
the table is indexed by the command itself (`cpgtu lr8, $3C`, then
`add ?, lr8, 0`), the `.lit` key's bits 0-6 repeat every 24 words, and bits
9-13 follow the `.text` key 19 words earlier. That lag predicts bits 9-13 for
18 of the 23 entries in the repeating rows, but only bits 9 and up. The
candidate decode it gives is not usable:

* **The repeated value is not the unused-command default.** It sits at
  entries 3, 8-11, 16, 28-35, 40, 52-55 and 57-59. Those include
  commands the host does send: `$10`, `$20` StdLine, `$21` StdText, `$23`
  StdArc, and `$35`-`$37` (pen size, colours). So the repeated value is a
  shared path for several commands, not `$A70`.
* **Its identity stays open.** The lag fixes only its bits 9-13. Every
  block start from `$A30` to `$B1C` (`$327D8`-`$328C4`, the "reply 0"
  blocks, the default, and the code right after the `jmpi`) scores the same,
  18 of 23. Its low 7 bits are circular, because the key's low bits were
  derived from it.
* **The low-7-bit clustering is unreliable.** Two entries can agree in bits
  0-6 and still differ above them: in row 3, entries 3 and 51 share bits
  0-6 but decode to different values.

**`.lit` strings: a better source of known plaintext.** The mask covers only
bits 0-23, so the top byte of each `.lit` word is plain. Read as one
character per word, `.lit` holds several ASCII messages, every fourth
character visible:

* `.lit $0500`-`$0760`, `$0900`-`$0A20`, `$0D60`-`$0DE0` and `$0F00`-`$0F70`
  hold readable runs, for example `Dofr:Lfr dFhseN ...` and `Po:anpol %Mtnener
  %f daf d`.
* The default reporter's argument, `.lit $0DC8` (words 882-887), reads
  `U o F t : %`, one character per word. That fits a format string like
  "Unknown Function: 0x%x" (a guess).

Each guessed string gives the full 24-bit key at each word. Two checks come
for free: bits 0-1 must match the `.text` key at the same index, and bits
0-6 must repeat 24 words apart. The words sit just before the dispatcher
table (words 888-948), in the same 24-word classes, so a confirmed string
would also fix the table's low key bits.

**Solved: `.lit` key bits 0-7, and the command table.**
`antelope_lit_key.py` does this from the strings alone, with no assumption
about the table:

* **Bits 0-6.** They repeat every 24 words, and bits 0-1 equal the `.text`
  key's. So each class k mod 24 has 32 candidates. For every class, one
  candidate makes the fourth character of its 15-18 string words read as
  English. It wins by 10-30 log units, except one close call (class 8),
  which the table confirms.
* **Bit 7** is the raw bit 7, since ASCII bit 7 is 0. It repeats every 48
  words, with 0 conflicts in 348 repeats. The pattern continues upward:
  `.lit`'s key bit b repeats every 24·2^(b-6) words, half of `.text`'s.
* **Result.** The fourth character of every string word is now plain, and
  the strings read:
  * `.lit $0DC8`: `U..no.. F..ct..n:..x%` ("Unknown Function: 0x%x", the
    default case's message);
  * `.lit $02C0`: a series of `DrawM..ti..je../o..` messages
    ("DrawMultiObject/..."?);
  * `.lit $0548`: `PAlloc: ...`, `Flush`, `Cache` messages.
* **Check on data the fit never used.** With these bits, all 61 dispatcher
  entries decode to the low byte of a case-block start. Chance is about 47%
  per entry, so 61 of 61 is about 10^-20.

**Bits 8-11, and the exact table.** `.lit`'s key bit b repeats every
24·2^(b-6) words (96, 192, 384 and 768 for bits 8-11). Bit 15 is plain in
string words (ASCII bit 7 of the third character). For each bit and class,
`antelope_lit_key.py` picks the value from two sources:

* the class's string words, scored by an English two-letter model of their
  middle characters (counted over this repository's `.md` prose);
* the class's dispatcher entries, by whether they still match a case-block
  start.

With every other bit fixed, the two sources decide independently and agree:
bit 8 in 46 of 46 classes, bit 9 in 46 of 47. Bits 10-11 come mostly from
the table: the strings reach only 5 of its classes there. Still, all 61
entries find a block in bits 0-11, which a wrong bit 0-9 would make fail
about 85% of the time. All case-block offsets are below `$1000`, so bits
0-11 fix the block.

That holds for 55 of the 61 entries. Six are uncertain, and both
candidates are listed in the table below:

* `$0D`, `$17` and `$2C` have two blocks that match their bits 0-9. (`$17`/`$2C` is settled by the handler's name; see below.)
* `$01`/`$12` (swapped; settled by the reset in `$31FE8`, see `CallBack` below) and `$1B` come out differently when the fit also
  uses the other `.lit` tables (`antelope_lit_key.py ACEF_100.bin`). Their
  bit-9/10/11 classes hold no string words, so the choice rests on weak
  evidence either way. This replaces the earlier lag-19 estimate, which had
bits 8-11 wrong for `$01`, `$03`, `$12`, `$17`, `$1B` and `$2C`. The strings
also read further, for example "FlushOffscreen: NULL offscreen Handle",
"CacheDevice: NULL GDevice", "PAlloc: numBytes is not multiple of FOUR",
"PAlloc: Unable to allocate frame buffer size = 0x%x", "malloc: allocated
… bytes outside of the heap bounds".

**All `.lit` tables.** Given the ACEF file, `antelope_lit_key.py` groups
every relocated `.lit` word by its relocation base, the symbol after the
relocation's index. These bases are often a function, not the module start
(`$01A4C`, `$13F50`, `$19DA0`, `$27674`). Each word is fitted against the
case-block starts of that base's module. 16 of the 18 groups then match far
above chance in bits 0-11:

| base | words | matching a block start in bits 0-11 | chance |
|---|---|---|---|
| `$075D8` | 11 | 11 | 4% |
| `$08614` | 38 | 38 | 11% |
| `$0E394` | 32 | 32 | 16% |
| `$22A88` | 40 | 40 | 7% |
| `$34048` | 14 | 14 | 14% |
| `$174FC` | 6 | 6 | 6% |
| `$372D0` | 4 | 4 | 2% |
| `$31DA8` (dispatcher) | 61 | 61 | 4% |
| `$2D7B4` | 86 | 82 | 15% |
| `$3772C` | 23 | 21 | 19% |
| `$25350` | 27 | 19 (partly a stride table) | 12% |
| `$0AD14` | 29 | 29 (17 pinned, below) | 11% |
| `$01A4C` | 50 | 42 | 17% |
| `$19DA0` | 66 | 53 | 25% |
| `$13F50` | 32 | 13 (a stride table; see below) | 15% |
| `$27674` | 16 | 16 | 20% |

So the `.lit` key model (bits 0-7 from the strings, bits 8-11 by class)
holds across all of `.lit`.

**Three known plaintexts from the host.** The stream writer in `gc24`'s
`EngineDispatch` (see "DrawMultiObject: the batched drawing stream") gives the true
targets of three DrawMultiObject table entries that the fit had decoded
wrongly:

| entry | opcode | fit alone | true target | error |
|---|---|---|---|---|
| `.lit $0484` | 1 (line) | `$69C` | `$09C` → `$0BDB0` | bits 9-10 |
| `.lit $0498` | `$6A` (clip region) | `$BB0` → `$0B8C4` | `$EB0` → `$0BBC4`, the `$6C` case | bits 8, 10 |
| `.lit $04B8` | `$72` (long pattern) | `$518` → `$0E22C` | `$A18` → `$0B72C` | bits 8-11 |
| `.lit $0488` | 2 (arc) | `$BB0` → `$0B8C4`, inside the `$73` case | `$CB0` → `$0D9C4`, which tests for opcode 2 | bits 8-10 |
| `.lit $049C` | `$6B` (background colour) | `$72C`, no case | `$62C` → `$0B340`, the twin of `$64` | bit 8 |
| `.lit $04BC` | `$73` (pattern slot) | `$4C0` → `$0C1D4`, inside the line case | `$AC0` → `$0B7D4`, which reads the slot | bits 9-10 |

`antelope_lit_key.py` takes these targets as constraints (`PINS`): every
entry of DrawMultiObject's two opcode tables (1-5 and `$6A`-`$75`), each
from the host's record layout and the case code read on the card.
* Opcodes 2-4 share `$0D9C4`, as QuickDraw draws arcs, ovals and round
  rects through DrawArc.
* Pinning only the first three entries was not enough: that moved shared
  key classes and broke opcodes 3 and `$6E` instead.

The refit leaves the dispatcher table at 61 of 61. Against the unpinned
fit:

| table | unpinned | pinned |
|---|---|---|
| `$2D7B4` | 78 | 81 |
| `$27674` | 13 | 16 |
| `$01A4C` | 40 | 41 |
| `$25350` | 22 | 23 |
| `$13F50` | 21 | 18 |

`$13F50` loses three words, `.lit $0788`, `$079C` and `$07BC`. Each shares
its bit-9 class (period 192) with one of the last three pins (2, `$6B`,
`$73`). Those matches were chance, because `$13F50` is mostly not a
case-block table:
* Its decoded values run in strides of 8: `$D5C`, `$D64`, … `$D7C`; then
  `$ADC`, `$AD4`, `$ACC`, `$AC4`; then `$3DC`, `$3E4`, `$3EC`, … `$40C`.
  These are offsets into unrolled code, like the excluded `$30088` group.
* With the pins, `$0788` becomes `$D84` (after `$D7C`) and `$07BC` becomes
  `$404` (between `$3FC` and `$40C`). Under the old key they broke their
  runs (`$A84`, `$A04`).
* Counting neighbouring words that differ by exactly ±8 over all tables
  gives 23 pairs under the pinned key against 20 before. All three new pairs
  are in `$13F50`.

So the lost "matches" were chance hits on case-block starts, and the pinned
key fits this table's real structure better. Its match count in the table
above (18 of 32) means little: it is a stride table, not a case-block one. Bits 8-11 are weakest where a class
holds few constraints, which is the case for these words.

**A stride prior does not help.** Under the pinned key many tables step
regularly between neighbouring words:

| table | regular step | pairs |
|---|---|---|
| `$2D7B4` | +12 | 45 |
| `$30088` | −16 | 24 |
| `$19DA0` | −16 | 13 |
| `$13F50` | ±8 | 11 |
| `$0E394` | +12 | 18 |

Many of the remaining steps are that step ± 512, 1024, 1536 or 2048, which
looks like single wrong key classes in bits 9-11. A score that rewards
neighbours differing by at most 64 was tried in the fit:
* at all of bits 8-11, it wrecked the fit (dispatcher 22 of 61);
* at bits 10-11 only, at weight 1, it kept the dispatcher (61 of 61) and the
  DrawMultiObject pins, but lost case-block matches elsewhere (`$01A4C` 41
  → 31, `$19DA0` 53 → 46, `$2D7B4` 81 → 79). Losing 10 matches at 17%
  chance each is not luck. So the tables mix stride runs with ordinary case
  jumps, and a general small-step rule is wrong for those classes.

The script keeps the case-block evidence only.

**`.data` has a key of its own, and it does not fall to the same method.**
`.data` (1,596 words) holds strings from `$0F20` on: 305 words have a
printable top byte. The tests:
* **Another section's key.** Decoding them with `.lit`'s low key byte, at
  any offset up to two `.lit` lengths, gives no text (mean letter
  log-probability −5.8, against −6.1 for raw bytes). Neither does the
  `.text` key: no offset up to 400,000 words agrees with even 80% of the
  string words on bit 7, which is the raw bit for ASCII.
* **A fresh fit.** Fitting a fresh low byte per class `k mod P` gives no
  English for P = 12, 24, 48 or 96. The longer periods only overfit.
* **Periodicity alone.** For ASCII, raw bit 7 of the fourth character is
  key bit 7. In `.lit` that bit repeats every 48 words with no conflicts,
  and the second character's bit 23 nearly so. In `.data` no period below
  400 is consistent for either bit.

So `.data`'s key is not periodic at the scale of `.lit`'s. 305 string words
and 101 relocations are not enough to model a long-period key like
`.text`'s, so `.data` stays masked. That includes the mode table at
`.data+$3D8` and the reporter level at `.data+$284`.

**ColorMap's switch tables as known plaintext.** The `$06BAC` group, left
out of the fit as "not a case-block table", is ColorMap's four switches. Three
of them, on `depth − 1` (16 entries each), enter an unrolled chain that
doubles the pixel through a long: `x |= x << 1; x |= x << 2; … << 16`, 16
bytes per step. Depth d enters at the step for d, and every other entry is
the default:

| table | chain | entries for depth 1, 2, 4, 8, 16 | default |
|---|---|---|---|
| `.lit $0128` | `$0710C` (`lr4`/`lr3`) | `$0710C` … `$0714C` | `$0735C` |
| `.lit $0168` | `$071EC` | `$071EC` … `$0722C` | `$0735C` |
| `.lit $01B8` | `$0754C` (`gr96`/`lr7`) | `$0754C` … `$0758C` | `$0759C`, the store after the chain |

The fourth switch (`.lit $01A8`, on `mode & 3`) sends srcXor to `$0735C`.
That makes 49 more pins. Under the unpinned key the default `$7B0` had
decoded as `$BB0`, `$DB0`, `$FB0` and `$CB0`, which is the same bits 8-11
trouble.

With them, the refit gives:
* **DrawMultiObject's table: 29 of 29.** The four sub-switch entries,
  unpinned, now decode to case blocks: `.lit $0464` → `$0CD58`, `$0468` →
  `$0CDB0` (or `$0BDB0`), `$047C` → `$0CF10`, `$0480` → `$0CF68`.
* **The other tables:** `$01A4C` 41 → 42, `$2D7B4` 81 → 82, and the
  dispatcher table stays 61 of 61.
* **The stride tables become cleaner.**
  * `$13F50` shows six +8 steps in a row (`$95C`, `$964`, … `$984`), then
    `$ABC` continuing a −8 run, and `$578`, `$570`, `$568`.
  * `$25350`'s new `$3FC`, `$408` is its usual +12 step.
  * Over all tables, neighbouring words differing by ±8, ±12 or ±16 go
    from 122 to 136 pairs.

  The case-block "matches" those two tables lose (`$13F50` 18 → 13,
  `$25350` 23 → 19) were chance hits in what are stride tables.

Still unresolved: no `.lit` table entry is known to decode wrongly now; the
weakest are those in tables that are neither case-block nor stride tables.
(Earlier: four entries of the 6-way sub-switch tables (`.lit $0464`,
`$0468`, `$047C`, `$0480`) matched no clean case entry.) Two groups are not case-block tables and are
left out of the fit:

* base `$06BAC`: one repeated value ending in `$B0`, which follows no jump;
* base `$30088`: offsets stepping down by `$10` per entry, restarting
  several times, which looks like computed jumps into unrolled code.

Part of the `$01A4C` table (from `.lit $0094`) steps by `-$10` the same
way, and `$075D8`'s steps by `+$8`. Their bits 8-11 rest on weak evidence,
so only the high-scoring groups should be read entry by entry.

With the handlers from the case-block table above:

| command | case block | handler / what it does |
|---|---|---|
| `$00` | `$327D8` | reply 0 ("not handled") |
| `$01` | `$31FE8` | reset: sequence counter to 0, request 100 to the host (settled by `CallBack`, below) |
| `$02`, `$05`, `$06`, `$07` | `$3287C` | the code right after the switch's `jmpi` |
| `$03` | `$327F8` | reply `$??00`, the twin of `$00`'s block (an earlier fit gave `$324F8`; System 6 decodes `$03` and `$33` to different blocks, `$03` to the twin, see section 10) |
| `$33` | `$324F8` | one long -> `$14034` **DisposeOffscreen** |
| `$04` | `$32040` | |
| `$0C` | `$32408` | six longs -> `$151C4` **CachePixPat** |
| `$0D` | `$32600` (or `$32200`) | `handler(6, p[0])` -> `$15D28` |
| `$0F` | `$32688` | `handler(6, p[0])` -> `$15D28` |
| `$11` | `$3210C` | -> `$15D84`, `$16BA0` (start-up control record) |
| `$12` | `$326E8` | system call `$??CD` |
| `$13` | `$32740` | system call `$??CC` |
| `$14` | `$32080` | `handler(p[0])` -> system call `$??D5` |
| `$15` | `$32148` | -> `$2D7B8`: **StretchBits** (host: `GA_TrapAB27`), host memory via `MapVirtual` |
| `$16` | `$3279C` | stores `p[0]`, `p[1]` in two globals |
| `$17`, `$2C` | `$324C8` | one long -> `$158F4` **FlushPixPat** (`$2C` is the host's DisposPixPat, which settles the earlier `$320C8` alternative) |
| `$19` | `$32570` | one long -> `$14168` **FlushOffscreen** |
| `$1A` | `$325A0` | one long -> `$141F8` **FlushColorTable** (the host's SetEntries) |
| `$1B` | `$323D0` (or `$325D0` -> `$14274`) | the bit-mask chain entered at its last step (bit 4 -> `$14A80`) |
| `$26` | `$32234` | stores `[p[0]+4]` at `$..C0` |
| `$29` | `$32468` | one long -> `$15808` **FlushGDevice** (the host's AddSearch/…/SetDeviceAttribute) |
| `$2B` | `$32498` | one long -> `$15808` **FlushGDevice** |
| `$2D` | `$32188` | -> `$13770` (not sent by `gc24`) |
| `$30` | `$322D4` | the bit-mask chain (`$14B64`, `$14A80`): **font upload** from `sub_88E6` (width table, font strikes; see "Text and fonts") |
| `$38` | `$32284` | stores `[p[0]+4]` at `$..C0` (twin of `$26`) |
| `$3C` | `$32528` | two longs in a frame -> `$140CC` |
| all others | `$32818` | default: prints "Unknown Function: 0x%x" |

Points that fit the host side (`QUICKDRAW_PATCHES.md`):

* `$26` and `$38` are the twin "store `[p[0]+4]`" blocks. The host issues
  both around every drawing operation (`$0D ... $26 ... $38`).
* `$29` (AddSearch/DelSearch/AddComp/DelComp/SetDeviceAttribute), `$33`,
  `$17` and `$2C` (DisposPixPat) are one-long commands on the host, and all
  go to one-long handlers.

#### Handlers named by their messages; the entry table

**The handlers name themselves.** Many functions pass a `.lit` string to
the reporter `sub_00140`. Each string's address is in the relocation comments
of `text.partial.asm`, and with bits 0-11 of the `.lit` key the strings
read. The functions:

| function | message (decoded, a few characters still wrong) | role |
|---|---|---|
| `$0AD18` | "DrawMultiObject/…: can't get a RGBPatCacheEntry for RGB Pattern", "… font is not in cache", "DrawMultiObject: unknown opCode %d" | **the drawing engine**: an opcode interpreter (its jump table is `.lit $0454`) |
| `$14034` | "DisposeOffscreen: NULL offscreen Handle" | command `$33` |
| `$14168` | "FlushOffscreen: NULL offscreen Handle" | command `$19` |
| `$141F8` | "FlushColorTable: NULL color table handle" | command `$1A` |
| `$14F64` | "CacheGDevice: NULL GDevice" | |
| `$151C4` | "CachePixPat: NULL pixPatHandle" | command `$0C` |
| `$15808` | "FlushGDevice: NULL GDevice" | commands `$29`, `$2B` |
| `$158F4` | "FlushPixPat: NULL pixPatHandle" | commands `$17`, `$2C` |
| `$15DF8` | "Cache still busy, cacheType = %d, cache = %lx" | |
| `$161F8` | "PRInit: Unable to allocate mega buff" | initialisation |
| `$16A04` | "PRAlloc: numBytes is not multiple of FOUR", "PRAlloc: Unable to allocate frame buffer size = 0x%x" | frame-buffer allocator |
| `$22A8C` | "ScaleC?t/s IndexTo???: unsupported … = %d", "ScaleC?t: unknown scale… = %d" (reading uncertain) | |
| `$31E20` | the sequence-error message, "Unknown Function: 0x%x" | the command dispatcher |
| `$33680` | "malloc: allocated … bytes outside of the heap bounds …" | |
| `$33EBC` | "CallBack … during interrupt …" | |

This exhausts the strings. Every `.lit` string run belongs to one of
these functions or to MapVirtual/CallBack, apart from two that name nothing
readable: `$01468` (a short "Bogus…" message) and `$31DAC` (a partly
readable "P?Mo?t: …" message). The run at `.lit $1020` is not text: it is
the C library's `_ctype_` table, whose entries for tab to CR read `$28`
(`_C|_S`) and for the other control characters `$20` (`_C`), as V7/BSD
ctype has them.

So the card keeps caches of the host's pixel patterns, colour tables,
GDevices and offscreens. The one-long commands keep those caches in step:
flush or dispose an entry when the host's object changes. Drawing itself
is `DrawMultiObject`.

**An exported entry table.** `PRInit` (`$161F8`) allocates 100 bytes,
stores the pointer in the external `extern#1636`, and fills it with 24
function pointers:

    +$00 $2D7B8   +$04 $13770   +$08 $0AD18 DrawMultiObject   +$0C $01A50
    +$10 $19DA4   +$14 $22A8C   +$18 $3008C   +$1C $075DC   +$20 $08618
    +$24 $11AD8   +$28 $19270   +$2C $1701C   +$30 $17264   +$34 $153D4
    +$38 $1553C   +$3C $32C10   +$40 $32EF8   +$44 $33EBC   +$48 $3373C
    +$4C $33A9C   +$50 $31E20 (the dispatcher)  +$54 $00248  +$58 $00348
    +$5C $00294   +$60 an argument of PRInit

Many are module entry points (`$075DC`, `$08618`, `$11AD8`, `$3008C` are
four bytes into their modules). `$14020` returns the table pointer, and it
is one case of a second service switch, `sub_379A0`. That switch handles
`$8008`-`$8019` (18 cases, `.lit $0FC0`): allocate and free (`$3779C`,
`$377CC`), getters (`$13FCC`, `$13FE0`, `$13FF4`, `$1400C`, `$14020`),
`$16BA0`, `$33A9C`, `$378DC(p0..p2)` and `$3791C(p0..p3)`. Command `$8001`
passes exactly `sub_379A0` to the code it calls: `p[2](p[0], p[1],
sub_379A0)` (the `$274` there is `$379A0` relative to the module base).
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
`p[2](p[0], p[1], sub_379A0)`: `entry(message, task data, services)`. The
uploaded code gets Antelope's service switch, and with it the entry table
that holds `DrawMultiObject`. Task creation (`sub_1BEE`) sends message
`$FFFF` and kill sends `$FFFE`, so these are the module's own init and exit
messages.

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

`sub_6442` is also called from six wait loops inside `EngineDispatch`
(`$60B0`, `$612E`, `$62E8`, `$6362`, `$6EC8`, `$71A2`), so the card can make
a request while the host waits on any command. On the card, these requests
are made by `CallBack` (`$33EBC`, entry table `+$44`; decoded below).

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
   replies -1, takes the card's number and returns. Code 100 skips the check
   and resets the counter to 0 (reply 1);
4. runs the request, writes the reply to `+$08`, and counts the request.

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

**The card side of the requests (`sub_33EBC` "CallBack", decoded).**
`CallBack(code, wait, nargs, a0, …, a7)`:
1. The mailbox is `[.bss] + $24`, the same packet base the dispatcher reads
   commands from.
2. Code 100 first zeroes the request counter (`.data+$F0C`).
3. If the host's packet `+$14` is set (a command is being serviced), it
   prints the `.lit $0F4C` message ("CallBack … during interrupt") and
   returns.
4. It stores three arguments (eight if `nargs > 3`) at `[mailbox+$14]`,
   the counter at `+$0C` (and increments it), and the code at `+$04`.
5. It sets bit 2 of packet `+$18`, and of `*[packet+$20]` if that is set:
   the status bit the host's idle routine tests.
6. If `wait` is set, it spins until the host has set `+$04` back, then
   returns `+$08`, the reply.

The calls, found by relocation (const/consth) and by call displacement (the
low byte is exact, and the candidates are near):

| wrapper | code | args | called from |
|---|---|---|---|
| `$33BD0` | 13 (search procs) | 5: RGB, …, the current GDevice `[extern#1772+$74]` | `$0688C`, `$2BCEC`, `$2BE2C`, `$2BF80`, `$2C094`, `$2C1A8`, `$2C324` |
| `$33C6C` | 14 (complement procs) | 5 | `$06B1C` |
| `$33CFC` | 22 (`GetSystemClientProcess`) | 0, then copies the PSN out | `$1437C` |
| `$33D58` | 17 (`Entry2Index`) | 2: entry, the current GDevice | `$06844`, **`$0AD18` DrawMultiObject** (twice) |
| `$33D98` | 12 (`MakeITable`) | 3 | `$14D78` (next to CacheGDevice `$14F64`) |
| `$33DD4` | 8 (copy) | 3 | `$16C48` |
| `$33E10` | 18 (copy from a handle) | 3 | `$16C48` |
| `$33E4C` | 21 (copy into a handle) | 3 | `$14478` |
| `$33E88` | 1, no wait, no arguments | | no caller found; the host's `sub_6442` ignores code 1 |
| `$3373C`, `$33A9C` | 15 (lock + physical pages) | 4 or 3 | see below |
| `$37730` | 999 (module request) | 4: task, selector, count, argv | the `$80xx` service switch `sub_379A0` (out-of-range cases) and `$377FC`, `$37838`, `$3786C`, `$378A8` |
| dispatcher `$31FE8` | 100 (reset) | 0 | command `$01` |

Not found on the card: codes 3-7 (handles, resources), 16 and 20. They are
open to host-loaded modules, which get `CallBack` as entry-table `+$44`.

**`$3373C` and `$33A9C` (entry table `+$48`, `+$4C`) map host memory.** They
are the only users of code 15, and they are called from the first entry-table
functions: `$2D7B8` (`+$00`), `$13770` (`+$04`), `$01A50` (`+$0C`),
`$19DA4` (`+$10`), `$22A8C` (`+$14`), `$3008C` (`+$18`), and from `PRInit`.
So those six entry points are the ones that read or write host memory
directly: they are presumably the transfer routines (CopyBits-like) for
pixel maps in host RAM. `DrawMultiObject` itself only asks for
`Entry2Index`.

**This settles dispatcher entry `$01`.** The case at `$31FE8` sets the
command sequence counter `[.bss+8]` to 0 and sends request 100 (reset the
host's request counter). Command `$01` is the one command the sequence check
lets through, so it is the reset command and its case is `$31FE8`. That makes
`$12` the `$326E8` case.

#### Card: `MapVirtual` and host memory

**`$3373C` is `MapVirtual` (its `.lit $0F34` message reads roughly
"MapVirtual: bytes == 0").** `MapVirtual(addr, len)`:
1. `len == 0`: print the message, return -1.
2. Look `[addr, addr+len)` up in a list of mapped ranges
   (`extern#1772+$00` head, `+$04` tail). The entries are
   `{+$00 addr, +$04 len, +$08 runs, +$0C run table, +$10 next}`. A covered
   range is reused.
3. Otherwise build an entry. `CallBack(15, wait, 4, addr, len, max, table)`
   has the host lock the buffer and return its physical runs.
4. For each run, call services `$CC` (`$39018`) and `$CD` (`$39028`, once
   per page). `$CD`'s decoded pointer lies in the kernel's region-table
   insert/remove code, so this presumably enters the host pages into the
   card's address map.
5. If that fails, `CallBack(15, …, 0)` unlocks again (on the host, a run
   count of 0 means `UnlockMemory`), and it returns -1.
6. The entry is allocated with `PRAlloc` and linked in.

A flag at `extern#1772+$90` brackets this with service `$D3` (`$390B4`, 1 on
entry, 0 on release).

`$33A9C` is the release, `UnmapAll`: if the `+$90` flag is set it calls
`$D3(0)`; then for every entry it calls `$CD` per page and
`CallBack(15, 1, 3, addr, len, 0)` to unlock.

**Which commands reach host memory.** Two dispatcher cases call the
entry-table functions:

| command | case | calls | sent by the host |
|---|---|---|---|
| `$15` | `$32148` | `$2D7B8` (entry `+$00`) | `GA_TrapAB27` (`gc24.s` `$32BC`), one argument |
| `$2D` | `$32188` | `$13770` (entry `+$04`) | no `gc24` code sends `$2D` |
| `$11` | `$3210C` | `$15D84`, then `$16BA0` | the control record `$FFFFFFFE` (start-up) |

`GA_TrapAB27` patches trap `$AB27`, which is `StretchBits` (below). It runs
only if the device's flags have bits `$27` set and bits `$600` clear, and
the `pat` argument is NIL.

`sub_8262` then builds a parameter block in card memory (packet `+$58`), and
the patch sends `$15` with a pointer to it. A reply of 1 means the card did
the transfer; the patch then sets bit 7 of `HiliteMode` (`$938`), as
QuickDraw does after a drawing call, and skips the original. On the card,
`$2D7B8` is a large routine that:
- calls `MapVirtual` three times;
- uses the GDevice cache (`$14F64`, `$14D78` `MakeITable`, `$14BD4`) and
  the copy helper `$16C48` (codes 8 and 18);
- calls `$01494` RSect and `$01654` TrimRect repeatedly (named from
  DrawMultiObject's region opcode, below) and `$3B600` twice.

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
StretchBits: the strings of its neighbour `$22A8C` (entry `+$14`), "ScaleC…
IndexTo…: unsupported dstDepth" and "unknown scaleNum", match Stretch.a's
`ScaleBlt` and `Scale…toIndexed` families.

#### The entry table, named

**The entry table read against System 7.1 QuickDraw.** Antelope looks like
compiled C (printf-style messages, C frames), not a port of the 68k sources, so names come from matching roles: the
strings, who calls whom, and which routines use the region seek code. The
anchors:

* `$253D4` prints a message that reads roughly "GetSeek(): invalid
  rectType for maskmode = %d" (the string is partly masked). In `QuickDraw/SeekMask.a`, `GETSEEK` combines the clip
  regions (and a mask) into a per-scanline seek routine. Its 68k callers are
  `Stretch.a`, `ScaleBlt.a`, `RgnBlt.a`, `DrawLine.a`, `DrawArc.a` and
  `QuickPolys.a`, but not `BitBlt.a`.
* `$22A8C` prints "ScaleC…/…IndexTo…: unsupported dstDepth" and "…: unknown
  scaleNum". `ScaleBlt.a`'s `scaleBlt` picks a depth-conversion loop
  (`scaleCase`) from a table and imports `GetSeek`. `$22A8C` calls
  `GetSeek` and 19 workers (`$230B4`-`$25354`).
* `$2D7B8` is StretchBits (command `$15`, above). It calls `GetSeek`,
  `$22A8C`, `$01A50` and `$19DA4`, as Stretch.a calls `GetSeek`, `scaleBlt`,
  and the blitters for the unscaled cases.

| entry | function | name | evidence |
|---|---|---|---|
| `+$00` | `$2D7B8` | **StretchBits** | host trap `$AB27`, the parameter block |
| `+$14` | `$22A8C` | **scaleBlt** | strings; `GetSeek` + a family of depth loops |
| `+$0C` | `$01A50` | **BitBlt** (likely) | called by StretchBits and the shape drawers; does *not* call `GetSeek`; switch tables by mode (`.lit $0008`-`$0068`); falls back to `$19DA4` |
| `+$10` | `$19DA4` | **RgnBlt** (likely) | calls `GetSeek`; called by BitBlt, StretchBits, text and shapes; four mode loops `$1B33C`-`$1BDE8` |
| `+$1C`, `+$20`, `+$28` | `$075DC`, `$08618`, `$19270` | the three shape drawers that use `GetSeek`: `$075DC` **DrawArc**, `$08618` **DrawLine**, `$19270` **QuickPolys** (settled by DrawMultiObject's polygon opcode, below) | same helpers (`$0E398`, `$1114C`, `$17500`, `$1553C`); called by DrawMultiObject |
| `+$24` | `$11AD8` | **text** (likely) | calls StretchBits and scaleBlt (scaled text goes through StretchBits in QuickDraw), RgnBlt, BitBlt; uses `extern#1772+$60`-`$6C` |
| `+$18` | `$3008C` | a `GetSeek` user with the `.lit` table of computed jumps into unrolled code (base `$30088`) | |
| `+$08` | `$0AD18` | **DrawMultiObject** | its strings; calls all of the above |
| `+$04` | `$13770` | command `$2D` | calls DrawMultiObject, `MapVirtual`, the caches |
| `+$3C`, `+$40` | `$32C10`, `$32EF8` | **ShieldCursor** (before drawing) and its counterpart (after drawing): the cursor lock with the host, see "The cursor" below | |
| `+$34`, `+$38` | `$153D4`, `$1553C` | set that rectangle (`$1553C` stores four words at `+$78`-`$7E`) | |
| `+$44`-`+$4C` | | `CallBack`, `MapVirtual`, `UnmapAll` | above |
| `+$50` | `$31E20` | the command dispatcher | |
| `+$2C`, `+$30`, `+$54`-`+$5C` | `$1701C`, `$17264`, `$00248`, `$00348`, `$00294` | small helpers: `$1701C` the long fill, `$00348` the `storem` burst fill (called by nearly every blitter) | |

**The three shape drawers (profile, not settled).** The partial disassembly
gives each one's instruction mix, data references and callees:

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
- `$3BA38` is a divide (31 `div` steps, `divl`, `divrem`);
- `$3B814`/`$3B950` are small millicode helpers (called with `calli gr122`);
- `$1114C` and `$11A34` pick a scanline loop from a table of 18 and 7
  targets, like QuickDraw's mode-case tables;
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
not up to date", and `$06BEC` "BitsToPixMap: bounds …" (called from
StretchBits).

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
1. if `extern#1772+$90` is set, call service `$D3` (`$390B4`) with 0, and
   with 1 on the way out;
2. take the lock: wait until packet `+$1D4` (host claim) is 0, set `+$1D8`
   = 1, and back off and retry if the host claimed it meanwhile;
3. copy `CrsrRect` through the pointer at `+$5F8` (`$3B600`, 8 bytes);
4. look up `CrsrDevice` (`+$600`) with `$15D28(2, gdevice)`. If the cursor
   is not on a device this card drives, skip to the end. Otherwise take
   the device's offset from the result (`+$32`);
5. test the drawing rectangle (`extern#1772+$78`-`$7E`, global) against
   `CrsrRect`, after subtracting the device's origin (the cached entry's
   `+$32`, v then h). The four exits are `bottom < crsr.top`,
   `right <= crsr.left`, `top >= crsr.bottom` and `left >= crsr.right`,
   so a drawing whose bottom edge touches the cursor's top row still
   counts as overlapping. No overlap: skip to the end.

**`$32C10`, before drawing: remove the cursor.** It publishes the drawing
rectangle at `+$1DC` (`loadm`/`storem` from `extern#1772+$78`). If `CrsrVis`
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
* Then it raises `+$5F4` ("redraw", `$33148`). It clears both the published
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

These readings now rest on fully decoded words (key bits 16-23 estimated
from the neighbours, see section 6): the offsets `$5F0`/`$5F4`/`$1EC`/`$1F0`
and the branch structure are no longer matched from the host side only.
Still inferred: the argument order of `$38218` (destination first), from
the two calls being mirror images.

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
rests on estimated words (`antelope_estimate_words.py`, "=" in its output)
and on the `.lit` key with host-confirmed pins. Treat each card-side detail
as a reading.

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
4. send `$2D` with that block. On the card, `$2D` is handled by `$13770`,
   the only caller of DrawMultiObject. It runs until the first wait.

**After each drawing call** (`$38`, `L5DE0`), if the buffer holds more than
the header:
1. rewrite the header's word at `+2` with flags (`$F0(a4)`);
2. send `$38` with (card address, byte count).

On the card, the nested wait inside DrawMultiObject services `$38`. Its case
stores the count (`[p[0]+4]`) in the length word that DrawMultiObject
re-reads.

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
cases are the pinned `.lit` entries (see "Three known plaintexts from the
host") and the compare chain.

| record | written for (command) | size: layout | card case |
|---|---|---|---|
| **1** line | StdLine (`$20`) | 8: `+4` the new point, which also becomes `pnLoc` | `$0BDB0`: draws from the pen with DrawLine, then moves the pen there |
| **2** arc | StdArc (`$23`) | 16: `+2` frame, `+4` rect, `+$C` startAngle, `+$E` arcAngle | `$0D9C4` (DrawArc; the case tests for opcode 2) |
| **3** oval | StdOval (`$2F`) | 12: frame, rect | `$0D9C4` (DrawArc) |
| **4** round rect | StdRRect (`$2E`) | 16: frame, rect, `+$C` ovalWidth, `+$E` ovalHeight | `$0D9C4` (DrawArc) |
| **5** rect | StdRect (`$24`) | 12: frame, rect | `$0C754` |
| **6** text | StdText (`$21`) | `(n + $13) & ~3`: `+2` count n, `+4` the space character's width (width table entry 32), `+8` `fixTxWid` (the unscaled width, Fixed), `+$0C` the width scaled by `numer.h/denom.h` (the pen advance), `+$10` the text | `$0E018`, then DrawText `$11AD8` |
| **7** poly | StdPoly (`$31`) | `(polySize + 7) & ~3`: frame, the Polygon | `$0C398` |
| **8** region | StdRgn (`$18`) | `(rgnSize + 7) & ~3`: frame, the Region | `$0D6E8` |
| `$64`, `$66` foreground colour | ForeColor, RGBForeColor, PmForeColor (`$36`) | `$64`, 12: `+2` the RGB colour (port `+$24`; for an old port `sub_917E(fgColor)`), `+8` `fgColor` (`+$50`). `$66`, 16, when the port's colour came from the Palette Manager (bit 2 of `$CE(a4)`): the same plus `+$C` grafVars `pmFgIndex` | `$0B230`, `$0B458` |
| `$6B`, `$6D` background colour | BackColor, PmBackColor (`$37`) | the same from `+$2A`/`+$54`; `$6D` adds `pmBkIndex` (bit 4 of `$CE(a4)`) | `$0B584` for `$6D`, `$0B340` for `$6B` (the twin of `$64`, storing to the background global) |
| `$67` font | StdText, when the font changed | 32: `+2` the 26-byte `FMOutput` (its `fontHandle` replaced by the strike actually used), `+$1C` `WidthTabHandle` | `$0DE00` |
| `$68` MoveTo | the pen location changed (`sub_8DA4`) | 8: `+2` `pnLocHFrac` (`$8000` for an old port), `+4` `pnLoc` | `$0BD7C` |
| `$69` mode | the transfer mode changed (`sub_8E38`) | 4: `+2` the mode | `$0B214`: the mode into `lr24` |
| `$6A` clip region | SetClip, ClipRect (`$32`) | `(rgnSize + 5) & ~3`: the Region at `+2` | `$0BBC4`, into `lr19` |
| `$6C` visible region | visRgn changed (`$10`, also from the port check at `$51A4`) | the same | `$0BBC4`, into `lr54` |
| `$6E` pen size | PenSize, SetPenState, PenNormal (`$35`) | 8: `+4` pnSize | `$0BD98` |
| `$6F` header | start of the stream | 4: `+2` flags, rewritten before each `$38` | `$0B228`: skipped |
| `$70` hilite/op colour | OpColor or HiliteColor changed (`sub_8DF2`) | 16: `+4` the hilite colour (`grafVars^.rgbHiliteColor`, or `HiliteRGB` `$DA0` for an old port), `+$0A` `rgbOpColor` | `$0BB7C` |
| `$71` bit pattern | a pattern slot changed (`sub_8F04` result 1) | 12: `+2` slot, `+4` an 8-byte Pattern | `$0B6D8`: kind 0 |
| `$72` pixel pattern | `sub_8F04` result 2 or 4 | 8: `+2` slot, `+4` a long (a PixPat) | `$0B72C`: kind 1 |
| `$73` slot | the verb's pattern slot changed | 4: `+2` slot (1 pen, 2 background, 3 fill) | `$0B7D4`: skipped if the slot is current and no pattern changed; otherwise it makes the slot current (`lr20`) and builds its pattern by kind |
| `$74` RGB pattern | `sub_8F04` result 3 | 12: `+4` slot, `+6` an RGB colour | `$0B788`: kind 2, the "RGB Pattern" of the cache message |
| `$75` patAlign | `patAlign` changed (QuickDraw global −168) | 8: `+4` `patAlign` | `$0B7B8`: stored to a global |

The card handles 24 opcodes (`$65` is the only gap in `$64`-`$75`). The
numbering does not follow PICT,
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
over 44-byte device records (`lr111`, `lr76` up to `lr105`), then calls
`$169A0`. It clears:
* both region pointers (`lr54`, `lr19`);
* `lr20`;
* `lr27`, the "pattern changed" flag that the pattern records set;
* `lr28`, the chunk status;
* `lr50`, `lr70`-`lr72`, `lr75` and `lr32`-`lr34`.

The pen (`lr25`, `lr36`) and the pattern slots are **not** set, so a stream
has to begin with MoveTo and its patterns. The host does that, because its
cached state starts out empty.

**Loop head (`$0AEC8`).**
* **Before each record** it calls `$33304(record pointer)`. That adds 1 to
  packet `+$1C4` (the heartbeat the host watches) and stores the pointer in
  packet `+$1C8`, so the host can see how far the card has got.
* **The stream** runs from `lr102` to `lr102 + [lr53]`. The opcode is read
  as a signed half at `lr38+0` (`$0AF90`).
* **At the end of the bytes**, if the last status was `$C9`, it leaves
  (`$0DF28`). Otherwise it waits in `sub_33374`, the nested wait loop. That
  loop services only `$0C` (CachePixPat), `$26`, `$2A`, `$2C`, `$30` (the
  font upload) and `$38`, and returns `$C8` or `$C9` after `$26`/`$30`.
  * The wait is timed: service `$11` (stub `$38FE8`) is called before and
    after it.
  * `$3328C` counts the waits (`.bss+$10`), adds up their time
    (`.bss+$0C`) and keeps a maximum in packet `+$1CC`/`+$1D0`.
  * The prologue's call `$33238(-1)` resets these statistics.
* **After the wait** it re-reads `[lr53]` and sets the end to `lr102 +
  [lr53]` without resetting `lr38`. It goes on with the records the host
  appended. Most likely `$C8` means "more records" and `$C9` "last batch".

**Dispatch.** The opcode is in `lr81`. The loop head (`$0AF94`) sends
opcodes above 9 straight to `$0B204`. For the drawing opcodes (1-9) it
first checks the dirty flags (below), then also continues at `$0B204`:

| opcodes | dispatch |
|---|---|
| above `$69` | `$0B204` → `$0E2CC` |
| `$69` | `$0B204` → `$0B214` |
| 1-5 | table `.lit $0484` (`opcode − 1`); the delay slot (`$0E268`) sets the data pointer `gr96 = lr38 + 4` |
| 6 | compare chain (`$0E22C`-`$0E23C`, read from the known low bits); its delay slot sets the pointer to `lr38 + $0C` |
| 7, 8, `$64`, `$66`, `$67`, `$68` | compare chain: 7 → `$0C398`, 8 → `$0D6E8`, `$64` → `$0B230`, `$66` → `$0B458`, `$67` → `$0DE00`, `$68` → `$0BD7C` |
| `$6A`-`$75` | table `.lit $0498` (`opcode − $6A`) |
| anything else | `$0E20C`: "DrawMultiObject: unknown opCode %d" (`.lit $0430`) |

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

**The refresh**, read in outline (about a third of its words are not
estimated). For each device (`lr76` up to `lr105`):
1. it loads that device's values into the drawing-context globals,
   `extern#1772` `+$0C`, `+$10`, `+$14`, `+$18`, `+$20`, `+$24` and `+$74`.
   These are the same stores every drawing case makes before it draws;
2. it calls **`$06F1C`, ColorMap**, which follows `ColorMap` in
   `QDUtil.a` step for step (estimated words):

   | `ColorMap` (68K) | `$06F1C` |
   |---|---|
   | split the mode into the pattern bit and the rest | `gr99 = mode & 8`, `lr17 = mode & ~8` (`lr17` mode, `lr16` depth) |
   | an arithmetic mode (bit 5) at 1 bit per pixel goes through `arithMode`, 8 bytes | the same test, and `mode & 7` indexes an 8-byte table at `.data+$2EC` |
   | old port or new (`portBits.rowBytes` sign) | tests `extern#1772+$3E` |
   | fore- and background RGB from the port | loads the RGBs at `extern#1772+$28` and `+$30`, and tests for black on white |
   | at depth ≤ 2, if fore- and background map to the same index although their RGBs differ, invert the foreground and map it again (`@goOnAndFlip`) | the same comparisons, then `$06B1C` (invert) and `$0688C` (colour → index, request 13) |
   | replicate the pixel through a long, by depth | a switch on `depth − 1` through `.lit+$128` |

   The `.lit` group at base `$06BAC`, which the key fit leaves out as "not
   a case-block table", is ColorMap's switch tables (`.lit+$128`, `$168`,
   `$1A8`, `$1B8`). Their targets are the per-depth replication blocks.
3. it looks up a byte in an 8-entry table at `.data+$3D8`, indexed by
   `(mode xor lr42) & 7`, or takes −1, and stores it in a per-device slot
   (`+$B4`). That is a per-device choice of blit loop by mode, as
   QuickDraw's mode tables do. `.data` is masked, so the table's values
   are not known;
4. it sets a per-device flag (`+$1CC` slot) unless the byte is `$64`.

So colours and mode are mapped per device once per change, not once per
drawing record. A stream that draws many shapes in one colour pays for the
mapping once.

Each case ends by advancing `lr38`, usually in the delay slot of its `jmp
$0B450` back to the loop. The sizes found that way match the host's layouts
for every case that has been read.

The two 6-entry tables `.lit $0454` and `$046C` are not opcode tables. They
are sub-switches on `lr94` (0-5) inside the rectangle case (`$0CD30`,
`$0CEE4`), right after `$1553C` and `$32C10`. With the pinned key all twelve
entries decode:

| `lr94` | `.lit $0454` | `.lit $046C` | routine called |
|---|---|---|---|
| 0, 1, 2, 4 | `$0CD58` | `$0CF10` | `$09430(row, …, lr94, …)` |
| 3 | `$0CD8C` | `$0CF44` | `$09578` |
| 5 | `$0CDB0` | `$0CF68` | `$09660` |

`$09578` (estimated words) fills a one-pixel-wide column:
* the x offset is `rect.left − bounds.left` and the row count is
  `rect.bottom − rect.top`;
* it stores one byte per row, stepping by `rowBytes`, unrolled by two;
* mode 1 inverts each byte (NOR); otherwise it stores the foreground or
  background long (`+$1C`/`+$20`).

`$09660` does the same with long stores, and `$09430` with masked long
read-modify-writes (AND, ANDN, OR, XOR) and `lr94` as an argument. So `lr94`
is `log2(pixel depth)`:
* 3 is 8 bits, handled with bytes;
* 5 is 32 bits, handled with longs;
* 0, 1, 2 and 4 (1, 2, 4 and 16 bits) share the masked routine.

These are the narrow-rectangle (vertical strip) fast paths. The general
rows go through `$09020` and `$09270`, which mask the edge longs and store
whole longs between them, as BitBlt-style fill loops do.

**What each case calls.** A trace from each case through the estimated words
follows both branches and stops at the jump back to the loop:

| record | case | words traced (not estimated) | routines reached |
|---|---|---|---|
| 1 line | `$0BDB0` | 395 (8) | DrawLine `$08618`, ShieldCursor pair, `$13F54`, `$1701C` |
| 2/3/4 arc, oval, round rect | `$0D9C4` | 271 (79) | DrawArc `$075DC`, ShieldCursor pair |
| 5 rect | `$0C754` | 908 (55) | RSect, TrimRect, `$13F54`, alloc, `$37D68` (`storem` fill), ShieldCursor pair, `$1701C`, BitBlt |
| 6 text | `$0E018` | 98 (0) | none before its unestimated jump; DrawText `$11AD8` follows at `$0E1B0` |
| 7 poly | `$0C398` | 239 (0) | ShieldCursor pair, DrawLine, QuickPolys |
| 8 region | `$0D6E8` | 183 (0) | RSect, TrimRect, alloc (then RgnBlt) |
| `$64`, `$66`, `$6B`, `$6D` | `$0B230`, `$0B458`, `$0B340`, `$0B584` | 68-76 | request 13 (colour → index); `$66`/`$6D` also `Entry2Index` |
| `$67` | `$0DE00` | 134 | `$15E8C`, the cache lookup with time stamp |
| `$6A`/`$6C` | `$0BBC4` | 110 | RSect, TrimRect |
| `$68`, `$69`, `$6E`, `$6F`, `$70`-`$72`, `$74`, `$75` | | 2-23 | none: they only store state |
| `$73` | `$0B7D4` | 295 (23) | the pattern cache (`$1610C`, `$15E8C`, `$15FF4`, `$15154`, `$1518C`) |

Every drawing case brackets its drawing with the cursor hand-off described
in "The cursor".

**The rectangle case** (`$0C754`-`$0D050`), per device (`lr76`):
1. **Skip** the device if its per-device flag (`+$1A4` slot) is clear.
2. **Choose the fast path** only if all of these hold:
   * the device's type word (`+$3C0` in its 44-byte record) is 5;
   * neither the visible nor the clip region is non-rectangular (the
     per-device slots `+$17C` and `+$154` that the region case fills are 0);
   * the record's frame flag (`lr82`) is 0, so it is a paint, erase,
     invert or fill rather than a frame;
   * the per-device mode byte from the refresh (`+$B4` slot, the
     `.data+$3D8` lookup) is 0 or 2.
3. **Fast path** (`$0C80C`-`$0CA50`):
   * clip the rectangle against the device's `minRect` (the `+$14` table
     the region case filled with RSect);
   * set the shield rectangle (`$1553C`) and take ShieldCursor;
   * fill through the long-fill helpers (estimated words):
     * **`$13F54(addr)`** asks "is this address on this card?". It calls
       kernel service `$C4` (stub `$38F34`: `const gr121, $??C4` /
       `asneq`; the high byte and the trap number are masked, and `$C4`
       lies in the vector-66 range), takes the result's top nibble `s`, and returns 1 when
       `addr` is `$s.......` or `$Fs......`, else 0. Those are the card's
       NuBus super-slot and standard-slot spaces, so `s` is the card's slot
       number. The kernel has a matching stub. Boot stores a value shifted
       left by 28 at `$4C00682C` (`PublicOu+$2C`), and Hand's stub
       `$2001250` returns that word (`gr96 = [$4C00682C]`). The service
       table's pointers are too approximate to prove that `$C4` lands on
       `$2001250` (section 8), but no other stub returns such a value.
       Pixmap base addresses arrive as host addresses, so this is how the
       card tells its own frame buffer from host or other-slot memory;
     * **`$1701C(dst, value, count)`**, a long fill (`lr8`-`lr10`). The
       branches below are plain bits:
       * `count` < 8 goes to a small path (`$171D0`);
       * `dst & 3` ≠ 0 goes straight to `$00348`;
       * otherwise it tests bit 31 of the absolute word `$??000080`. There
         is no relocation on the pair, so this is a hardware register, not
         a variable. The key estimate gives `$44000080`, a status register
         that Hand also tests (see below);
       * bit 31 clear: call `$00348`;
       * bit 31 set: a **hardware block fill** (estimated words,
         `$17078`-`$171CC`):
         1. align `dst` to 32 bytes with 1-7 single stores of the value
            (`dst>>2 & 7`, through `.lit+$548`);
         2. store the value to two registers at `$??C00000` and
            `$??C00004` (the masked byte estimates as `$4C`, so
            `$4CC00000`/`$4CC00004`);
         3. set bit 22 of the destination (`gr99 = dst | $00400000`), an
            alias of the frame buffer;
         4. store `$FFFFFFFF` through two pointers 4 bytes apart (`gr99`,
            `gr98`), each stepping 32 bytes. Eight stores cover 32 longs, so
            each store fills 4 longs (16 bytes);
         5. handle the 1-3 remaining blocks the same way, with a store
            value derived from the remaining count (presumably a partial
            mask), then clear bit 22 again (`and $FFBFFFFF`) and finish the
            tail with single stores.

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
         `storem`: one store already does four longs. The register and
         alias addresses rest on estimated high bytes; the low bytes
         (`$00`, `$04`, `$40` in `consth`) and the structure are plain or
         estimated consistently.

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

       `$17264(dst, a, b, count)` (entry-table `+$30`) is the two-value
       version. With `a` = `b` it calls `$1701C`. Otherwise it tests bit 31
       of `$??00007C` (estimated `$4400007C`) the same way, before its own
       aligned paths. So the second status register gates the two-colour
       case. The matching burst helpers are `$00294`, which loads two
       alternating values into the burst registers, and `$00248` (`+$54`),
       a copy that moves 29 longs per `loadm`/`storem` pair;
     * **`$00348(dst, value, count)`**, a burst fill. It loads the value
       into 24 global registers (`gr96`-`gr119`) and writes them with
       `storem`, 96 bytes per instruction. The remainder goes through a
       `.lit` jump into the unrolled register loads and one final `storem`.
       Nearly every blitter calls it for solid runs;
     * **`$37D68(dst, value, count)`**, a `storem` fill for any memory.
       The "call to the next instruction" at its start is a direct `call`
       with an R_IREL relocation (type 24): the file stores displacement 0
       and the loader fills it in (see "Relocations name the targets"). Its
       calls all go to kernel service stubs:
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
          `$D3` returned non-zero, `$D4(dst, bytes)` translates `dst` and the
          result becomes the destination. When `count * 4` overflows, it
          instead restores `$D3` and fills untranslated. A misaligned
          destination skips the alignment step. Otherwise it stores up to
          64-byte alignment, writes 64 bytes per
          `storem` (`CR = $F`), stores the rest, and restores everything
          with the saved values (`$38114`-`$38138`);
       7. the direct path (`$381CC`) is the same 64-byte `storem` loop
          without the services.

       `$D3` is the service that brackets the host-memory mapping (1 on
       entry, 0 on release; see "Card: `MapVirtual` and host memory"). So step 6 is a
       fill into host memory through the kernel's mapping, presumably
       with NuBus block transfers set up by `$B8`/`$B9`/`$BF`. What
       `$D1`, `$BB`, `$B8`, `$B9`, `$BF` and `$D4` do in the kernel is not
       shown, because the service table's pointers are approximate. **`$D5`
       is settled by its use:** Hand's stub `$2001260` returns
       `[$4C00643C]` (`PublicIn+$3C`) when its argument is negative, and
       otherwise clears bit `lr2` of that word and mirrors the result to
       `$46000000`. `$37000` calls `$D5(-1)` to read the mask and
       `$D5(slot)` to drop a slot that failed. So the word is a per-slot
       "burst transfers work" mask, and `$46000000` presumably the hardware
       copy of it. The host's command `$14` (`$D5(p[0])`, sent from the
       InitGDevice patch) can drop a slot as well.

       `.data+$280`, read by every caller of the fills (`$03838`, `$03A28`,
       `$04110`, `$09020`, `$09270`, `$0E4CC`, `$0E804`, `$11460`-`$11918`,
       `$1C298`, `$1C8A8`), is a shared flag. PRInit stores its *address*
       in the descriptor it builds for modules (`$16748`), so code outside
       Antelope can change it. Its meaning and initial value are in masked
       `.data`. `$04110`, `$0E804` and `$1C8A8` (pattern fills) have no
       const references; only `$0E804` has a known caller (`$1114C`). They
       are left unnamed. One candidate for `$BB`: Hand has a stub (`$2001A58`) that returns
       `gr64`, the feature flags the host wrote to `PublicIn+$18`. In those
       flags, `$200` is set by `SetFeatureFlags` (`DRVR.s` `$2AD2`) when the
       unit's config word `+$128` has bit `$40`. The config word comes from
       Control call 17 (cs50 is the same plus `$100`, "mailbox allowed").
       Whether the host sets `$200` is described in section 9: it does,
       by default. If `$BB` is the flags stub, the host-memory `storem`
       path is **on by default**. That `$BB` is the flags stub is not
       confirmed.

       A neighbouring stub `$2001A48` returns `[$4C006804]`
       (`PublicOu+$04`), a candidate for `$D1`.

       **`$D4` and `gr122`.** Antelope has two `$D4` stubs, and both use
       `gr122` as a second result. `$39064` sets `gr96 = lr3` before the
       trap and returns at once if `gr122` is 0. `$39050` loads `gr96` from
       `*lr3` and stores `gr122` back there. Hand has a region-table
       translator of that shape: `$2001774` requires a 1 KB-aligned
       `lr2`, looks it up in the table at `$4C003168`, and returns
       `gr96 = 0` and `gr122 = aux + (lr2 - base)`. `$2001808` is a second
       stub that returns its input in `gr96` and a computed value in
       `gr122`. These fit `$D4` as "translate a host address through the
       mapping table", but the service table cannot say which stub is
       `$D4`, and the estimated stub words are not exact enough to settle
       how the two results are combined.
       The same service sequence appears in three more entry points (the
       others with services are shared restore tails: `$38574`, `$385C8`,
       `$38C3C`). Together they are one family:

       | entry | role | callers |
       |---|---|---|
       | `$37C10` | pattern fill: a 1-, 2-, 4-, 8- or 16-long pattern (`lr19` = period) loaded into `gr96`-`gr111`, then `$37D68`'s body (`$37DF0`) | `$04110`, `$0E804` (3), `$1C8A8` |
       | `$37D68` | fill with one long | the row fills `$09020`/`$09270`, DrawMultiObject, `$11460`-`$11918` (text), `$03838`, `$03A28`, `$0E4CC`, `$1C298` |
       | `$37000` (not in the family) | **burst self-test of a slot** (`addr`): takes the slot nibble, reads the slot mask with `$D5(-1)` and returns `$100` if the slot's bit is clear. It then reserves `$200` bytes on the memory stack and checks `CopyLongsStorem` against single loads and stores: burst-read 64 and 60 longs, invert the target with single stores, and burst-write it back. On any mismatch it restores the memory, calls `$D5(slot)` to clear the slot's bit, and returns -1 | CacheGDevice `$14F64` (once per device, between `$D3` calls) |
       | `$16C48` (not in the family) | the copy helper behind CallBack requests 8 and 18 | uses `$38218` twice |
       | `$38218` | forward copy (`dst`, `src`, `count`): `loadm`/`storem` 64 bytes at a time; calls `$D4` for both pointers | ShieldCursor `$32C10` and `$32EF8` (saving and restoring the pixels under the cursor), `$02DE0`, `$16C48` (2), `$1B61C`, `$37000` (4) |
       | `$388D0` | backward copy: the same with both pointers counting down, for overlapping moves | through the jump table at `.lit $0FFC` (base `$3772C`) |

       All four rewrite a `$4.......` card address to the slot form and
       take the kernel-service path only for memory off the card;
   * release the cursor (`$32EF8`).
4. **General path** (`$0CA64`-`$0D050`):
   * RSect (`$01494`), then TrimRect (`$01654`) for each region;
   * set the shield rectangle and take ShieldCursor (`$0CCA0`);
   * then twice, a per-depth column switch (`$0CD30`, `$0CEE4`, below)
     and a row-fill pair (`$09270`, `$09020`);
   * release the cursor at `$0D050`.

Two columns and two rows is the shape of a framed rectangle (left and right
edge, top and bottom edge). That fits frames being sent this way, but it is
a reading. How this path handles a non-rectangular clip is not read; no
direct call to RgnBlt appears in the case.

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
That names two helpers every drawing routine calls:
* `$01494` is **RSect**: DrawArc, DrawLine, QuickPolys and DrawText call it
  once each, StretchBits four times;
* `$01654` is **TrimRect**: each drawer calls it twice, once per region.

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

So the card's "font is not in cache" and "width table is not in the cache"
messages are about this upload: DrawMultiObject looks up the `$67` record's
`WidthTabHandle` and the `FMOutput` strike in what `$30` delivered.

**The cache of host objects.** One cache serves fonts, GDevices and more,
organised per kind and keyed by the host handle:
* `extern#1745` is an array of 24-byte descriptors, one per kind: `+$08`
  heads a linked list, `+$0C` gives the entry size, and `+$10` the data
  size in longs.
* Each entry is: `+$00` a time stamp, `+$04`/`+$08` prev/next, `+$0C` the
  host handle (the key), `+$10` the data.
* **`$15D28(kind, key)` finds** an entry by walking the list.
* **`$15E8C`** finds and stamps a hit with the clock (service `$11`) for
  LRU replacement.
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
| 6 | used by commands `$0D`/`$0F` |
| 8 | font strike |
| `$0A` | width table |

**On the card: drawing the text.** `$11AD8`, called from the text case, is a
7 KB routine with the shape of QuickDraw's `DrawText.a`:
* the clipping set-up (RSect, TrimRect twice) and the ShieldCursor pair;
* one buffer from PRAlloc `$16A04`, or two when a flag (`lr58`) is set,
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

**The glyph loop** (`$122F4`-`$123A8`, read from fully decoded words). Its
inputs come from three pointers in the drawing globals:
* `lr60 = [extern#1772+$60]`, the `FMOutput` (above);
* `lr46 = [extern#1772+$68]`, the width table (256 Fixed entries indexed
  by character code). `lr70` is its entry for the space (`+$80`), which the
  text record also carries;
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
ORs each long with itself shifted left by one, with a NOR term on the
carried-out bit. That is the smear that bold (and, with the NOR, outline)
applies in `DrawText.a`.

An earlier reading of this loop, made from estimated words, had the width
table indexed by `c` and `lr48` as the location table. The full decode
shows the width table indexed by the character code (as QuickDraw's is),
`lr48` as the optional height table, and the space fast path. The roles of
the `+$18`/`+$1C` tables, first inferred from their use, are confirmed by
the conversion that builds them.

**The strike conversion** (`$14564(entry, new, hostFont)`, read from fully
decoded words). It turns the uploaded `FontRec` (card copy at entry `+$10`)
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

* **The per-device state refresh** is read only in outline: the mode table
  at `.data+$3D8` and ColorMap's `arithMode` copy at `.data+$2EC` are
  masked, and ColorMap's alpha-channel part is not checked.
* **Why a repeated font upload re-converts only glyphs `$84`-`$9E`** (`$14564`, the `new = 0` path).

#### The dispatcher prologue and packet layout

**What happens before the switch (decoded).** The prologue of
`sub_31e20` can be read in full: `antelope_estimate_words.py` takes key bits
16-23 from the full samples on both sides of a word where they agree. It
checks out: every compare writes the register its conditional jump tests,
the wait loop jumps back to its own start, and the exits land on the common
epilogue. Annotated (`rec` = packet `+$44`, see below):

    $31E0C  call sub_31e20 with lr2 = -1, in an endless loop  (the main loop)
    $31E3C  wait until packet+$14 != 0;  packet+$1C = 1
    $31E64  rec = [.bss+4];  lr8 = cmd = [rec+4];  seq = [rec+8]
            if seq != [.bss+8] and cmd != 1:
                print(.lit $0D88, [.data+$F08], cmd)   "M..et..in..Se..en.. e..or..d .. %.. f..c ..%d"
                packet[0] |= 3; reply 0; return          (sequence error)
    $31EEC  [.data+$F08] = cmd  (last command);  [.bss+8] += 1
    $31F0C  n = first argument:  -1 -> accept;  <= 0 -> reject;
            else accept if cmd is among the next n arguments
            rejected: reply 0 ("not handled"), return
    $31F7C  call system-call stub $38F64 (service $??D2)
            if (cmd & $FF00) != $8000: goto switch ($32850)
            else reply = sub_37B58(cmd, [rec+$0C], [rec+$10])

* **The packet layout matches the host exactly.** The host (`gc24.s`
  `$5F54`-`$5F78`) writes the selector to `+$48`, a running sequence number
  to `+$4C`, the argument count to `+$50`, and `$FFFFFFFF` to `+$14`. So the
  card's `rec` is packet `+$44`, and the switch index is the host's
  selector itself (`$0C`-`$38`). The host rewrites some selectors only to
  `$24` StdRect: a rounded rectangle with zero radius, or a rectangular
  region.
* **`sub_31e20(n, cmd1, …, cmdn)` is varargs.** The frame is 10 registers,
  so the incoming arguments start at `lr12`, and `storem lr12, gr125`
  spills them to the memory stack. The main loop passes `-1` (every command).
  A second caller, at `$33404`, passes `(6, $26, $38, $30, $0C, $2A, $2C)`.
  So while some operation is in progress, only those six commands are
  serviced, and the caller then checks the result for `$17` and `$38`.
* **The constants:** `const gr96, $FF00` / `and gr97, lr8, gr96` /
  `const gr96, $8000` / `cpneq`. Commands `$80xx` go to `sub_37B58`, and
  everything else goes to the switch.

#### The Std* selectors at the card's dispatcher

(These selectors never arrive here in practice: `EngineDispatch` turns them
into DrawMultiObject records instead of sending them. See "DrawMultiObject:
the batched drawing stream". What follows is what the card's dispatcher
would do with them, and how the host reacts to each reply.)

**So the drawing selectors reach the default.** `$20` StdLine, `$21`
StdText, `$23` StdArc, `$24` StdRect, `$2E`, `$2F`, `$31`, `$18`, `$2A`,
`$32` and `$35`-`$37` decode to low byte `$70`. Inside `sub_31e20`
(`$31E20`-`$328C8`), the only block starting at an offset `$x70` is the
default `$32818`. The low byte comes from the strings and is exact. So in
this switch they would print "Unknown Function". They are accelerated
before they get here, by the host writing them into the drawing stream.

**What the default does, and what the host does with it.** The default
block `$32818`:
1. calls the reporter `$00140` with "Unknown Function: 0x%x" and the
   command;
2. ORs `$11` into packet word 0;
3. jumps to the common exit at `$328A4`, which stores reply 0 at packet
   `+$1C`.

The reporter is gated by a level word at `.data+$284`: 0 returns at once,
1 goes to `$39284`, anything else to `$00F84`. Its initial value cannot be
read, because `.data` is masked too. So the message is probably silent in
normal use.

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

The card's dispatcher itself has no case for the Std\* selectors. That
holds without the uncertain key bits: the next paragraph checks it.

The reply protocol (0 = do it yourself) also lets one `gc24` work with a
firmware that handles fewer calls.

**The condition checked without bits 8-11.** The low byte `$70` of the
Std* entries is exact. All case blocks lie below module offset `$1000`, so
the only possible targets are the sixteen words at module offset `$x70`.
None of them except the default can start a case:

| offset | word | the word before | can it start a case? |
|---|---|---|---|
| `$070` | `$31E18` | a `jmp` (this is its delay slot) | no: outside the dispatcher (the main loop) |
| `$170` | `$31F18` | `cpeq` on the `load` just before | no |
| `$270` | `$32018` | `const lr3` after `const lr2` (argument set-up) | no |
| `$370` | `$32118` | `calli` right after its `const`/`consth` | no |
| `$470` | `$32218` | `jmp` after a `store` | no |
| `$570` | `$32318` | `jmpf` on the `cpneq` just before | no |
| `$670` | `$32418` | `load` through the address just computed | no |
| `$770` | `$32518` | `calli` right after its `const`/`consth` | no |
| `$870` | `$32618` | `load` after its address `const` | no |
| `$970` | `$32718` | the `consth` half of a `const`/`consth` pair | no |
| **`$A70`** | **`$32818`** | **`jmp` + delay slot** | **yes: the default** |
| `$B70`-`$F70` | `$32918`-`$32D18` | | no: past the end of `sub_31e20` (`$328C8`) |

Every alternative is the middle of an instruction sequence: it uses a
register or a condition that the word before it sets. So whatever bits 8-11
are, the selectors whose entry has low byte `$70` (`$18`, `$20`-`$25`, `$27`, `$28`, `$2A`, `$2E`,
`$2F`, `$31`, `$32`, `$34`-`$37`, `$39`-`$3B`) go to the default. The
conclusion no longer depends on the fit, only on the exact low byte and on
the block layout.

One oddity remains. `$2A` is sent by the patches of `PicItem1` (`$AB9A`)
and `OldPatToNew` (`$AB11`), two internal QuickDraw traps (see
`QUICKDRAW_PATCHES.md`). `PicItem1` plays back one picture opcode, and
`OldPatToNew` turns an old 8x8 pattern into a pixel pattern. `$2A` is in the
accept list of the nested wait (`$33404`: `$26`, `$38`, `$30`, `$0C`, `$2A`,
`$2C`), although its case is the default. An unhandled command gets reply 0
whether it is accepted or rejected, so this changes nothing visible. It is
probably left over from a version that handled `$2A`.

#### The `$80xx` commands, the card heap, the wait loop

**The `$80xx` commands (`sub_37B58`, decoded).** The function's arguments
start at `lr8` (frame of 6 registers): `lr8` = command, `lr9` = `[rec+$0C]`
(count), `lr10` = `[rec+$10]` = `p`. It switches on `cmd - $8000` (0-4,
anything else returns `-$32`) through `.lit $1008`, the module's `.lit` base
`$0FC0` plus `$48`. The five case blocks have different low bytes, and the
string-derived `.lit` key decodes all five entries to exactly one of them:

| command | case | does |
|---|---|---|
| `$8000` | `$37B94` | return 0 |
| `$8001` | `$37B9C` | return `p[2](p[0], p[1], $274)`: call code at a host-given address |
| `$8002` | `$37BC4` | return `sub_37658(p[0])`: allocate `p[0]` bytes from the card heap |
| `$8003` | `$37BD4` | `sub_376A0(p[0])`: free a block |
| `$8004` | `$37BE4` | return `p[0] + p[1] + p[2]` (an echo/arithmetic test) |

The allocator is the module `$372D0`-`$3772C`:

* Its heap descriptor sits at `.data+$1388`.
* It is created on first use by `sub_372D4`:
  1. call service `$C1` (stub `$38F24`);
  2. subtract `$1000`;
  3. call service `$01` (stub `$39008`) with that size, retrying 1,000 bytes
     smaller until it returns non-zero;
  4. store the block and build a free list in it (`sub_373A0`).
* `sub_37470(heap, n)` and `sub_3754C(heap, ptr)` are allocate and free.

This also names two services by use. `$C1` is "free memory": its `PrivNZ`
pointer `$20012E0` lies inside `Hand`'s "free stack/heap space" routine
`$20012AC`-`$20012E4`. `$01` (masked high byte, so probably `$101`) is the
program break (`sbrk`), as `Hand`'s register notes say (`gr65`, service
`$101`).

**The wait loop (`sub_33374`, the nested dispatcher caller).** It waits
until packet `+$1C0` reaches `*target` (argument `lr13`), counting spins
in packet `+$1C4`. The host side:

* it writes its own counter `$C0(a4)` into `+$1C0` (`gc24.s` `$5962`, right
  after sending command `$38`);
* it watches `+$1C4` change while it waits (`$60D4`, `$6306`), and calls
  `sub_75FE` when it stops.

So `+$1C4` is the card's heartbeat. While waiting, whenever the host posts a
request, the card services only commands `$0C`, `$26`, `$2A`, `$2C`, `$30`
and `$38` (through `sub_31e20(6, …)`). Depending on the result, it either
goes on waiting or returns early: -7 after `$17`, -5 otherwise, `$C8`/`$C9`
after `$26`/`$30`. The exact branch structure is less certain than the rest,
because several of these words are estimates.

The constraint for a future solution is clear: every relocated `.lit` word
is a code offset inside its own module (module ranges come from the symbol
table's per-module `.text`/`.lit` entries). For the dispatcher table the
targets are, in addition, among the about 37 case-block starts in
`$31E20`-`$328C8`.

#### The case blocks

**The case blocks.** I split `$31E20`-`$328C8` at the word after each
unconditional `jmp` and its delay slot. This gives 37 blocks. Most read
their arguments the same way:

1. `rec = [global+4]`;
2. `p = [rec+$10]`, a pointer to the longs the host copied after the header;
3. the arguments are `p[0]`, `p[1]`, … in `lr2`, `lr3`, …;
4. the block calls a handler with `calli`.

The packet sets the reply to 1 on entry, so a block that stores nothing
answers "drawn". The blocks, by shape:

The handler column comes from the relocations (next subsection), so it is
exact. The pointer to `rec` is at `.bss+$0004` of this module, and the
packet pointer is at `.bss+$0000`.

| block(s) | what it does | handler |
|---|---|---|
| `$32468`, `$32498` | `handler(p[0])`, no reply stored | both `$15808` |
| `$324C8` | the same | `$158F4` |
| `$324F8`, `$32570`, `$325A0`, `$325D0` | the same | `$14034`, `$14168`, `$141F8`, `$14274` |
| `$32528` | copies `p[0]`, `p[1]` into a frame on the memory stack and calls `handler(&frame)`: a two-long command | `$140CC` |
| `$32080` | `handler(p[0])`, then reply `lr12` (`$??00`, probably 0) | `$39104` (system call `$??D5`) |
| `$32408` | `handler(p[0..5])`: six longs | `$151C4` |
| `$322D4`-`$323D0` | `p[0]` is a bit mask. Bits 0, 1, 3, 2 and 4, tested in that order, each take two or three more longs and call their own handler. A zero result ends the chain. | bit 0: `$14B64`; bits 1, 3, 2, 4: all `$14A80` |
| `$32600`, `$32688` | `handler(6, p[0])`, and the reply depends on the result | both `$15D28` |
| `$3279C` | stores `p[0]` and `p[1]` in two globals; no call | - |
| `$32234`, `$32284` | unless `[msp+8] = -1`, stores `[p[0]+4]` at offset `$..C0` of a global block (two near-identical cases) | - |
| `$31F7C` | after a mask test on the command: `reply = handler(cmd, [rec+$0C], [rec+$10])`, a generic forwarder | `$38F64` (system call `$??D2`) |
| `$31FE8` | command `$01`: a local call with `[rec+$0C]`, sequence counter `[.bss+8]` = 0, then `CallBack(100, 1, 0)` | (local `call`) |
| `$320A8`-`$32230` | blocks not split out above | `$161F8` (twice), `$15D84`, `$16BA0`, `$2D7B8`, `$13770` |
| `$326BC`-`$32798` | blocks that go through system calls and an external data block (`extern#1772+$88`..`$90`) | `$39028` (`$??CD`), `$390B4` (`$??D3`), `$39018` (`$??CC`) |
| `$327D8`, `$327F8` | only store reply `lr12` (`$??00`): "not handled", so the host runs the original | - |
| **`$32818`** | **default**. The `cpgtu` branch lands one word in, because its delay slot holds the block's first word. It calls a reporter with `(.lit $0DC8, cmd)`, so it is probably a "bad command" message with its format string in `.lit`. | `$00140` |

The `$38xxx`/`$39xxx` handlers are 16-byte system-call stubs:
`const gr121, N` / `asneq trap, gr1, gr1` / `jmpi lr0` (the 29K OS
convention: the service number goes in `gr121`). Only N's low byte is plain.
35 such stubs exist. The others (`$13770`-`$16BA0`) all sit in one module,
`$11AD4`-`$174FC`. Five of them (`$14034`, `$140CC`, `$14168`, `$141F8`,
`$14274`) are consecutive functions of `$50`-`$9C` bytes, each called by one
one- or two-long block. That fits small state setters (pen, colours,
patterns) better than drawing routines.

On the host side (`QUICKDRAW_PATCHES.md`) the commands with one long are
`$0F` `$10` `$15` `$17` `$20` `$29` `$2C` `$32` `$33` `$35` `$36` `$37` `$3C`.
Those with two longs are `$18` `$24` `$2A` `$2F` `$31`, and those with four
are `$21` `$23` `$2E`. So the block shapes fit the host's commands in
number: many one-long handlers, a few two-long ones. But the shapes alone do
not say which block is which command. That still needs the 61 table words.

The default label should be the known plaintext for every unused entry. But
with `.text`'s key, `$32818` appears in none of the 61 entries, not even in
bits 0-6 (2 hits, both chance). With the same key, raw `.lit` words 48
apart agree in bits 2-6 at chance rate (10 of 402). So `.lit` does not
repeat `.text`'s period-48 low table above bit 1 either.

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
* **The plaintext is known.** The `const`'s plain low byte equals the
  addend's low byte in 1,889 of 1,898 pairs. So `const` holds the addend's
  low 16 bits and `consth` holds 0, because every addend is below `$10000`.

The masked high byte of each of these words is RC, which is key bits 16-23.
So each relocated word gives those bits exactly. Where the low key level
knows bits 16-17, the derived bits agree in all 972 cases.
`antelope_reloc_samples.py ACEF_100.bin` writes 3,755 such words to
`mask_samples.tsv` as `ihconst` rows. It takes bit 15 from the pair's other
word where only that one knows it: both words name the same register. The
levels stay exact, and their coverage grows:

| bits | table | classes covered |
|---|---|---|
| 0-15 | `J16[k mod 6144]` | 96% -> 98% |
| 0-16 | `J17[k mod 12288]` | 32% -> 52% |
| 0-17 | `J18[k mod 24576]` | 18% -> 30% |
| 0-18 | **new:** `J19[k mod 49152] + $60000 * (k div 49152)` | 16% |

The bit-18 level holds for all 328 sample pairs 49,152 words apart. Bits
19-23 change with periods longer than `.text` (62,134 words), so no table of
this kind predicts them. They need the generator's closed form, as for
`Hand` (`SECOND_MASK.md` section 3). The new samples show bits 20-23
behaving like Hand's high field: a slow 3-bit count, sign-extended
(`$0x`, `$1x`, `$2x`, `$3x`, then `$Cx`, `$Dx`, `$Ex`, `$Fx` from word
about 27,000). `text.partial.asm` now decodes these words in full and
comments each pair with its target.

**Direct calls have relocations too.** Besides the const/consth types,
`.text` has 133 relocations of type 24 (R_IREL). Each one sits on a `call`
(opcode `$A8`) whose displacement low byte is 0: the file holds
displacement 0, and the loader fills in the PC-relative distance. The symbol
is the entry itself (`.text`, value = target), or the next one when the
entry is `(-3, 0)`, as for const/consth (4 cases). So these 133 calls have
known targets although their displacement's high byte is masked:
* the calls in `$37C10`-`$38C3C` go to kernel service stubs (`$B8` `$B9`
  `$BB` `$BF` `$C4` `$D1` `$D3` `$D4`): a family of `storem` fill/copy
  routines (see `$37D68` under "the rectangle case");
* the rest are in `$39118`-`$3C340`, calling each other and the
  low-numbered services `$01`, `$14` and `$15` (HIF-style exit, write and
  so on). This looks like the C library.

`antelope_partial_dasm.py` now prints these targets
(`call lr0, $38f34   ; R_IREL call -> .text $38f34 (service $??c4)`).
The displacement's masked high byte is plaintext 0 in all 133 words, so
they are also full key samples. `antelope_reloc_samples.py` now adds them
to `mask_samples.tsv` as `irel` rows. 128 calls are `call lr0`, and 5 are
transfer calls through `gr122` (RA read from the known low key bits). The
32 words whose key was already known above bit 15 all agree. The gain is
modest: 406 words gain key bits (words with 19 known bits: 11,801 to
12,043; 18: 7,667 to 7,770; 17: 13,062 to 13,123).

**The C library (`$39118`-`$3C340`).** The R_IREL targets make it
readable. It is a Unix-style C library on AMD's HIF system calls:

| address | function | evidence |
|---|---|---|
| `$3B404` `$3B428` `$3B44C` `$3B470` `$3B494` `$3B4B8` `$3B4DC` | HIF stubs: close (`$12`), exit (`$01`), lseek (`$15`), open (`$11`), read (`$13`), `$21` (tmpnam in the HIF list), write (`$14`) | `const gr121, N` / `asneq 69` / `jmpti gr121, lr0`; on failure store `gr121` to errno and return -1 |
| `extern#1769` | `errno` | every stub stores to it |
| `.data+$1580` | `_iob` (20-byte `FILE`s; `stdout` at `+$14`) | |
| `$39284` | `printf` | spills its varargs; if bit 15 of a flag halfword of `stdout` is set (presumably append mode), `$39304(stdout, 0, 2)`; then `$399E0(x, stdout, fmt, ap)`, where `x` is a relocated address not read here |
| `$39214` | `vprintf` | the same without the spill |
| `$399E0` | `_doprnt` (the formatting core) | calls memset, the `_ctype_` table, and the number converters `$3A5A4`-`$3AC24` |
| `$39304` | `fseek` | calls lseek; `(fp, 0, 2)` is `SEEK_END` |
| `$3B500` | `memset` | returns if `n` = 0; replicates the byte to a word |
| `.lit+$1021` | `_ctype_` (+1 for EOF) | |
| `$3AA9C`-`$3ABB4` | isupper, islower, isalpha, isdigit, isxdigit, isspace, ispunct, isalnum, isgraph, isprint, iscntrl | `_ctype_[c]` masked with 1, 2, 3, 4, `$44`, 8, `$10`, 7, `$17`, `$97`, `$20`: the V7/BSD bits `_U _L _N _S _P _C _X _B` (the masks are bits 0-7, plain) |
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
pointer. The levels' initial values are in masked `.data`.

These are names by role: the library's own names and version are not in
the file.

**First attempt at `.lit`'s own key (not solved).** Test set: 236 relocated
`.lit` words whose target range is under 8 KB (175 in small modules, plus
the 61 dispatcher entries, whose range is the dispatcher function). A
decode "hits" when the target lands in its range, mod 8 KB. Chance is
143 hits.

* **Index shift** (`.lit` word k uses the `.text` key at k+δ): every
  δ that keeps bits 0-1 aligned (multiples of 48, 64 distinct values mod
  3072) scores 150-170, which is noise. Unaligned shifts do no better and
  break the 662/662 alignment.
* **Constant offset**, added or XORed onto the `.text` key: the best is
  143-149 of 236. On the dispatcher table alone the best is 31 of 61
  (chance about 20).
* **Per 384-word block** with the plain `.text` key: block 0 scores 3 of 63
  where 22 are expected. That is far *below* chance, so the `.text` key is
  systematically wrong there and not merely noisy. Blocks 1 and 2 sit in
  modules close to 8 KB, so they say little.
* The symbol table's module ranges are not tight enough for some groups:
  `.lit` words 74-125 never fit all together for any constant. So either
  those tables belong to more than one module, or the range heuristic
  needs the function-level ranges that the dispatcher test used.

So `.lit`'s key shares bits 0-1 with `.text` (and the `asgeu`/`asleu`
vector patching shows it is the same family), but bits 2-12 follow a
different table. Recovering it needs known plaintext inside `.lit`, for
example a switch whose case labels are all identifiable in `.text`.

### Antelope mask: `.lit` bits 11-23 (`antelope_lit_high.py`)

* **Bits 18-23 of `.lit`'s key are 0.** Every relocated `.lit` word has raw
  bits 18-23 = 0, and its plaintext is a `.text` offset below `$40000`. All
  1,097 `.lit` words lie inside the key's first plateau, as the first 1,389
  words of `.text` do.
* **Bits 11-17 step like `.text`'s high bits.** In the dispatcher table,
  whose offsets are all below `$1000`, raw bits 12-17 are the key: `$3B` ×20,
  `$24` ×34, `$25` ×7. Over the other tables, each entry's bits 0-10 select
  the case-block candidates with the same low 11 bits, and each candidate
  implies a key value. The entries with one implied value step the same way
  (`$0C`→`$0D`→`$0E`, `$3C`→`$3D`→`$3E`→`$3F`→`$38`, `$3B`→`$24`→`$25`→`$26`→`$27`).
  Bit 11 is part of the step: within each plateau of bits 12-17 it is 1
  first and then 0. `antelope_lit_key.py` models bit 11 as periodic (every
  768 words), and that was the cause of most of the misfits.
* **Bits 0-10 stay periodic** (bit *b* every 24, 48, 96, 192, 384 words for
  *b* ≤ 6, 7, 8, 9, 10). That holds without a conflict at every resolved
  entry. Some classes are pinned by no resolved entry, and there the fitted
  value can be wrong.

`antelope_lit_high.py` resolves an entry in four ways, in this order:
1. **agree:** one candidate, whose value is that of the nearest sample on one
   side or the other;
2. **resolved:** several candidates, exactly one with such a value;
3. **joint:** the unpinned class bits are left free; an entry with exactly
   one candidate under them pins them, repeated until nothing changes;
4. **function:** several candidates left, exactly one in the function of
   the nearest resolved entry.

Of the 535 table entries, 350 agree, 88 are resolved, 12 are joint, 1 is
resolved by function, and 84 stay open: 451 targets, against 398 with bit 11
taken as periodic. Eight entries that "agreed" under the old rule now get
another target. Each change is in bit 11, and in each the new target is the
better one. For example, `.lit $0BB4`-`$0BC8` move from `$3002C`… to
`$2F82C`, `$2F85C`, `$2F868`, which continue their table's run of blocks
`$C` apart (`$2F7A0`, …, `$2F838`, `$2F844`, `$2F850`, …, `$2F874`). And
`.lit $0008`/`$0010`/`$0FD4`-`$0FE0` move back into their switch function.

Independent check (not used in the fit): 442 of the 451 targets lie in the
same function as a neighbouring target. The 9 exceptions are isolated:
`.lit $0098`/`$00A4`/`$00CC`, `$0770`/`$0774`/`$07DC` and `$1004`-`$100C`.
They and the open entries are concentrated in the tail of base `$01A4C`
(after `.lit $0094`), the `$13F50` stride table and parts of `$19DA0`. In
those places no candidate fits at all, even under free bits. For about 30
of the open entries every key bit is pinned, so their targets are fully
determined. Either the words are not case-block offsets (most direct decodes
of the `$01A4C` tail land outside its switch function), or the blocks are
fall-through labels that the "word after an unconditional jump" rule misses.

The command table itself needed none of this: bits 0-11 already pick each
of its 61 blocks uniquely.

### Antelope mask: the `.lit` switch tables as an upper-bit source

**Withdrawn.** The first bullet below is wrong; see "the command dispatcher"
below. The 31 decoded targets fall inside `.text` only because they are all
small (below `$5948`), including those in tables owned by modules near the
end of `.text`. Only bits 0-1 of the `.text` key are shown to hold for `.lit`.

* **`.lit` uses the full `.text` key at the same word index**, all 23 bits, not
  just the low ones. 31 relocated `.lit` words have a `.text` sample at the same
  index. `raw XOR key` gives a full target for each, and all 31 land inside
  `.text` (`$0F0`..`$5948`, versus 1 in 33 by chance each). Adjacent entries
  agree with the decoded low 13 bits of their neighbours.
* **Extending this to whole tables works only partly.** I fixed one table entry
  from a sample and walked outward, choosing for each word the value that
  matches its low 13 bits and is nearest its neighbour's target. This
  reproduces 21 of 23 other anchors. Four tables drift into negative targets
  (their case labels jump more than 4 KB). Three tables (`.lit` words 2-51,
  138-175, 990-1030) are clean and give about 129 consecutive full keys. Their
  bits 13 and up change only slowly: `key >> 13` is `0` for words 2-38, then
  `1`; around `6`/`7` near word 140; `$13` near word 1000.
* Against the existing samples in the same `k mod 6144` class, those
  reconstructions agree on bit 13 in 35 of 44 cases (chance: about 22). The 9
  misses cluster where a table's targets cross an 8 KB boundary, which the
  nearest-neighbour rule cannot resolve. So the reconstructed keys are right
  inside an 8 KB block and unreliable at crossings. They are not added to
  `mask_samples.tsv`.
* **`.data`, `.data1`, `Apple` and `Code` do not share this keystream.** None
  matches the `.text` key at the same index. No offset from 0 to 70,000 words
  makes even 5% of `.data`'s low 13 bits decode to zero, although 919 of its
  1,596 words have a zero top byte.

## 8. The kernel's service table (vector 66)

`Hand`'s service dispatcher (`$20011E8`) takes the service number in `gr121`,
subtracts `$B6` and jumps through the word table at `$4C002500` (up to `$D6`
entries). `$4C002500` is exactly the **`PrivNZ`** section (`$84` bytes = 33
words, services `$B6`..`$D6`); the rest of the range is uninitialised. The
section's words use `PublicIn`'s keystream (the all-zero section's own contents)
as their mask: unmasking with it gives 33 pointers `$0200xxxx`, **31 of which are
valid 4-aligned addresses inside `Hand`** in the stub area `$20010FC..$2001B9C`
(a chance rate of about 0.7% each); two entries (services `$BC`, `$C5`) come out
invalid. The pointers are only reliable up to the key's low bits (a few look
like the middle of a stub, e.g. services `$C1` and `$D2` -> `$20012E0` where
`$20012AC` is the stub start), so the table gives the *set* and rough placement
of the services, not exact entry points. Stubs recognisable from the code at those
addresses: an `iret` no-op, "free memory" (`gr96 = heap end - break`), a 10-bit
serial shift-out of `lr4` to `$440000A0` (the pixel-clock chip, same shape as the
video driver's `SerialShiftOut`), writing three bytes from `lr3..lr5` to a port
at `$460004C0`, region-table add (`$200147C`) and remove (`$2001604`), and
register-dump helpers.

**Correction: Antelope does call the services.** The partial disassembly
shows 35 stubs of the form `const gr121, N` / `asneq 69` / `jmpi lr0` at
`$38F24`-`$39104`, `$3B404`-`$3B4DC` and `$3C9EC`. The low bytes of N are
plain:

* `$B8 $B9 $BB $BF $C0 $C1 $C4 $C5 $C6 $C7 $C8 $CB $CC $CD $CE $CF $D0 $D1 $D2
  $D3 $D5 $D6`: the vector-66 table range above;
* `$01 $11 $12 $13 $14 $15 $16 $21`: low numbers, probably the `$1`/`$1xx`
  services that the second dispatcher at `$2001B74` handles (`$111`/`$112`
  time, `$121` set globals, `$1` exit). Their high byte is masked.

The rectangle fast path's own-memory test `$13F54` uses `$C4` through stub
`$38F34`. It needs a value whose top nibble is the card's slot. That matches
the stub `$2001250` (`gr96 = [$4C00682C]`, a word Boot fills with a value
shifted left by 28). See "the rectangle case".

The command dispatcher uses `$D2` (for every accepted command, before the
`$8000` test), `$D5` (command `$14`, with `p[0]`), and `$CC`, `$CD`, `$D3`
(the `$326BC`-`$32798` blocks).

**Naming them from the `PrivNZ` table failed.** The `PublicIn`-unmasked
pointers are only approximate:

* `$B7`, `$B8`, `$BA` and `$CC` all decode to `$2001B94`-`$2001B9C`, which
  is inside the second dispatcher.
* No other keystream or offset gives more than 3 exact stub starts out of 33:
  `PublicIn`, `PublicOu`, `Vec`, `Apple`, or the `Hand`/`Boot` generator at
  any of 20,000 offsets.
* `PublicIn`'s low 7 bits repeat every 48 words (1 conflict in 201), so a
  `PrivNZ` table of the same kind has no repeats among its 33 words to fit.

What the approximate pointers allow, for the dispatcher's services:

| service | decoded pointer | nearby stubs (role) | fits Antelope's use? |
|---|---|---|---|
| `$D2` | `$20012E0` | `$20012AC`/`$20012C8` free stack/heap space; `$20012E8` pixel-clock serial write (`lr2`, `lr4`); `$2001294` restart if `gr64` bit 28 | called with no arguments, result discarded: the restart check fits best, not shown |
| `$D5` | `$200123C` | `$2001224` wait/clear INTR2; `$2001250` read `[$4C00682C]`; `$2001260` clear bit `lr2` of `[$4C00643C]`, mirror to `$46000000` | called with one argument (`p[0]` of command `$14`): `$2001260` fits |
| `$CC` | `$2001B98` | inside the second dispatcher | - |
| `$CD` | `$2001504` | inside the region-table code `$2001478`-`$2001604` (insert/remove a range) | - |
| `$D3` | `$20019CC` | `$20019B4` (returns -1), `$20019BC` | - |

So `$D2` is not where drawing happens: it is not one of the stubs near its
pointer, which all return at once and touch no command data. The drawing
selectors have no case in the dispatcher; they reach the card as stream
records instead (see "DrawMultiObject: the batched drawing stream").

### Antelope mask: the `.lit` jump/command tables (partial result)

The relocation table lists ten runs of consecutive word relocations in `.lit`
(50, 63, 38, 61, 104, 40, 27, 177, 61, 41 words: switch tables and, among them,
the card's command table). All of them point at one placeholder symbol, so the
targets are the *masked* word contents. Their plaintext is a 4-aligned `.text`
offset, which predicts that the key's two low bits equal the word's. Checked
against the 48-entry low-bit table `C48` recovered from `.text`
(`mask_samples.tsv`), indexing the table by the word's position in `.lit`:

* **all 700-odd words of all ten runs agree on bits 0-1** (50/50, 63/63, 38/38,
  61/61, 104/104, 40/40, 27/27, 177/177, 61/61, 41/41), against a 1-in-4 chance
  each. So `.lit` and `.text` share one generator (per ACEF, indexed by the word
  index within each section), and `.lit`'s runs really are tables of aligned
  code offsets.
* The words' high bits cluster in short stretches (for example `0x34xxx` for 28
  entries, then `0x37`, `0x30`, `0x31`, `0x33`), i.e. the entries are grouped by
  target region but the mixture of key ramp and target addresses could not be
  separated without the key's high-bit structure, so no command -> function
  mapping was recovered.

So the command table cannot be read yet, but the two data points that matter for
a future solution are now fixed: the generator is shared across Antelope's
sections, and about 700 further words carry known constraints (bits 0-1, and
bits 18-22 zero when the target is below `$3CAD8`).

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
with its own `ACEF` 100 (357,228 bytes against 323 KB), `ACEF` 1,
driver and INIT. Its 68k clients send the same csCodes: control panel
2, 3, 4, 5, 13, 14, 17, 20, 48, 99; `gc24` 32 2, 3, 4, 5, 13, 14, 17,
18, 19, 20; INIT 13, 14, 20, 21, 99.

**The System 6 Antelope is masked differently.** Unpacked with
`acef_unpack.py` it is also "32-Bit Antelope" (`.text` `$42AD8`,
`.lit` `$1494`, `.data` `$1830`; 1,838 symbols, 998 addresses).
* Its words share almost nothing with the System 7 file at the same
  index (1 equal word in 62,134), and the System 7 low key decodes
  only 2 of 80 System 6 entries that could be `sub gr1, gr1, N`
  (System 7 on itself: 291 of 307).
* Its **opcode byte is masked too**. (An earlier version of this section
  read the top-byte field off assumed function prologues and got values
  `$26`, `$30`, `$60`; that assumption was wrong, see below.)
* Its `.lit` strings are not plain either. Its `.data` matches the
  System 7 `.data` in 22% of bytes at the same offset, but that comes
  from the mostly zero top bytes. The low 24 bits differ randomly,
  which gives no handle on the `.data` key.

### The System 6 key (`antelope6_key.py`)

The relocations give the key directly, because in System 6 the opcode is
masked too:
* a relocated `const` is `$03 | addend<15:8> | RA | addend<7:0>`, and its
  `consth` is `$02 | 00 | RA | 00`. With the `R_IHCONST` addend, each gives
  key bits 0-7 and 16-31 (3,850 words, pairs matched by symbol and
  proximity);
* a direct call with an `R_IREL` relocation is `call lr0` with
  displacement 0, `$A8008000`: all 32 bits (133 words).

From these samples:

| key bits | structure | coverage of the 68,278 `.text` words |
|---|---|---|
| 24-31 | **two values**: `$00` up to word 20,557, `$0F` from about 20,558 on. The switch point is fixed to within 4 words by counting invalid opcodes; the other value would make 27% of the opcodes invalid | all |
| 16-23 | a step function of the word index, like System 7's bits 16-23: neighbouring samples that agree were right in 3,738 of 3,741 leave-one-out tests | where the neighbours agree |
| 0-7 | period 24 (9 of the 3,983 samples disagree and are dropped: bad pairings) | all |
| 8-15 | bit `b` has period 24 for `b` ≤ 9 and `24 * 2^(b-9)` above, with **no drift term** (zero conflicts at every level; bit 15: 294 repeats). Sampled from 1,086 frame idioms (`asgeu`, `asleu`, `jmpi lr0`), which can be found once the opcode is plain | bits 0-12 all, 13: 96%, 14: 78%, 15: 52% |

So the System 6 key is the same kind of generator as System 7's with a
simpler low part (pure tables, no step per block) and a wider output (an
opcode field). With the opcode plain, System 6's instruction mix matches
System 7's line by line: `add` 18.0% against 18.6%, `load` 8.1/8.9,
`const` 7.9/8.4, `jmpt` 7.8/8.3, and 0.86% invalid opcodes against 0.98%.

Independent check: the word before each `asgeu` frame check, where its low
16 bits are known, decodes as `sub gr1, gr1, N` in 110 of 119 cases. Every
N is a multiple of 8, with the frame sizes System 7 uses (16, 24, 48, 40,
32, 64, …).

`antelope6_key.py SYS6_ACEF_100.bin OUTDIR` unpacks the file and writes
`text.partial.bin` with a `.known` sidecar. The full 24 low bits are known
for 20,858 words, bits 0-15 for 14,377 more, bits 0-12 for the rest. Not
done: more idiom samples for bits 13-15 (System 7's register-pattern
samples), the `.lit` and `.data` keys, and a disassembly.

### System 6 against System 7, function by function (`antelope6_compare.py`)

Neither symbol table names its functions, but in both versions the opcode
byte of every word is now plain. So every function (from one `.text`
symbol to the next) has a known opcode sequence in both. The tool aligns
the two function lists in order (a pair matches with a difflib ratio
of at least 0.6 over the opcode bytes) and then pairs the leftovers in any
order (moved code):

| | functions | words |
|---|---|---|
| System 7 / System 6 | 768 / 769 | 62,134 / 68,278 |
| same opcode sequence | 645 | |
| changed (ratio ≥ 0.6) | 51 | |
| moved | 7 | |
| only in System 7 | 65 | 5,909 |
| only in System 6 | 66 | 11,647 |

In the functions with the same opcodes, 8,810 words are known in full in
both. Of these, 8,749 are bit-identical, 23 are pc-relative jumps or calls
whose targets moved, and 38 differ otherwise (33 of them `const`). So
those 645 functions are the same code, relinked.

**Every named function has a System 6 counterpart.** 60 of the 83 names in
`antelope_partial_dasm.py` match with the same opcodes. Among them are
Report, the burst fills and copies, RSect, TrimRect, ITabMatch, the whole
cache (`CacheFind` … `CacheRelease`, `UploadFontStrike`,
`UploadWidthTable`), PRAlloc, FillLongs, GetSeek, CallBack, TestSlotBurst,
the storem fills and the C library. 23 have changed; by size and ratio the
largest changes are:

| function | System 7 | System 6 | words 7 → 6 | ratio |
|---|---|---|---|---|
| CommandDispatcher | `$31E20` | `$2D614` | 682 → 934 | 0.77 |
| StretchBits | `$2D7B8` | `$28C14` | 2,612 → 2,798 | 0.64 |
| DrawMultiObject | `$0AD18` | `$0AF74` | 3,487 → 3,726 | 0.88 |
| PRInit | `$161F8` | `$15B5C` | 479 → 332 | 0.78 |
| MapVirtual | `$3373C` | `$2F2D4` | 216 → 186 | 0.64 |
| UnmapAll | `$33A9C` | `$2F5BC` | 69 → 67 | 0.78 |
| CopyHostMemory | `$16C48` | `$16360` | 197 → 198 | 0.86 |

The rest (BitBlt, BitsToPixMap, ColorMap, DrawArc, DrawLine, DrawText,
FlushOffscreen, ConvertFontStrike, CacheGDevice, CachePixPat, QuickPolys,
RgnBlt, scaleBlt, ShieldCursor, ShowCursorAfterDraw, CopyLongsStorem) have
a ratio of 0.90 or more. `antelope6_compare.py` prints the full map.

**Only in System 7** (by their callers in the System 7 decode):
* `$1E508`-`$200E0`, nine helpers of about 200 words, all called only by
  RgnBlt: by their number, the nine 16-bit arithmetic loops whose System 6
  counterparts are stubs (`RBAverage16Half` … `RBMin16`, see below);
* `$0F730`-`$10140`, eight helpers of the switch function at `$1114C`: the
  pattern-slab loops for the eight 16-bit arithmetic modes. Where System 6's
  `$10C3C` loads the addresses of the stubs `PatAverageSlab16` …
  `PatMinSlab16`, System 7's `$1114C` loads `$0FF60`, `$0F978`, `$0F730`,
  `$0FB08`, `$10140`, `$0FC98`, `$0F850`, `$0FDFC` (`antelope6_tables.py`);
* `$37730`-`$37B58`, the module support: request 999 (`$37730`) and the
  `$80xx` service switch `sub_379A0`, called from the dispatcher through
  `$37B58` (see "The `$80xx` commands"). It calls UnmapAll, CallBack and
  five 5-word functions at `$13FCC`-`$14020`. System 6 has no word
  `const …, $8000` in or near its dispatcher, so the host-loaded modules
  (`$8001`, "call code at a host-given address") are new in System 7;
* `$140CC`, a dispatcher case that calls CacheRelease;
* `$18278` (389 words, called by `$17C60` and StretchBits) and a run of
  StretchBits helpers at `$27944`-`$2CFD4`. They include the Stretch
  16-bit arithmetic loops: where System 6's StretchBits loads the stubs
  `StretchAverage16` …, System 7's loads `$27944`, `$27ACC`, `$27B48`,
  `$27BBC` (the other four sites do not map).

**Only in System 6:**
* a block of 43 functions, 10,928 words, between HeapFree and the storem
  functions (`$331C4`-`$3DC84`): **a QuickTime codec on the card** (see
  below). It is led by `$33218` (4,259 words: mostly
  `add`/`sub`/shifts, 315 `aseq`, few loads), `$374A4` (2,579), `$3B27C`
  (1,274, called by `$33218`) and `$3CA64` (1,001 words with six inline
  divisions, 186 `div` steps);
* 26 functions of 11 words at `$01378`-`$017C4`, each of which only
  passes a `.lit` string to `$00E88` and returns. `$00E88` is an empty
  function (`jmpi lr0`, as System 7's `$00F78`). The strings are the stubs'
  names (see the next subsection): `Bogus`, then QuickDraw's 16-bit
  arithmetic-mode loops for RgnBlt, Stretch and the pattern slab:
  `RBAverage16Half`, `RBAverage16`, `RBAddPin16`, … `RBMin16`;
  `StretchAverage16` … `StretchMin16`; `PatAverageSlab16` …
  `PatMinSlab16`. The order is that of `rArith16Tab` in the 7.1
  `RgnBlt.a` (Avg, AddPin, AddOver, SubPin, Transparent, Max, SubOver, Min;
  `rAvg16Half` is its case `$28`). So System 6's card had placeholders for
  the 16-bit arithmetic modes. RgnBlt (`$193C8`), StretchBits (`$28C14`)
  and the slab setup (`$10C3C`) load the stubs' addresses as their loop
  pointers, and `$11524` loads `Bogus` where System 7 loads `$01468` (the
  "Bogus…" message). Six of the stubs match, by opcodes, System 7's
  11-16-word functions at `$3779C`-`$3814C` (the "moved" pairs); those are
  module-support code, so the match is only the common frame idiom.

**The block is the card side of a QuickTime codec, commands `$39`-`$3B`.**
(An earlier version of this section called the block and the stubs
unreferenced. That was wrong: a relocation whose symbol has section -3 names
the *next* symbol, and the first scan missed those.) The address loads into
the block from outside it are all in the dispatcher `$2D614`, in the case
blocks of three commands that System 7 sends to the default:

| command | case block | loads | alternative path |
|---|---|---|---|
| `$39` | `$2DF60` | `$374A4` | `$2E024`: `$3A964` |
| `$3A` | `$2E0F0` | `$33218` | `$2E1A0`: `$3A254` |
| `$3B` | `$2E258` | `$33218` | `$2E340`: `$33218` |

Each case reads its argument record (`rec = [.bss+4]`, `[rec+$10]`), loads
eight fields of it (`+$04`-`+$2C`) and compares the first word with
`$72707A61`. The `const` half reads `$xx61`, and its masked high byte `$9E`
with the plateau key `$E4` gives `$7A`. So the word is `'rpza'`, the
four-character code of Apple Video ("Road Pizza"). If the word matches,
the case calls the block, otherwise it takes the alternative path. System 6's
host driver (`gc24` ID -4048) holds the component name "8·24GC Road Pizza"
and five comparisons with `'rpza'`, three of them next to one with `'rle '`
(Animation). So SW 1.1 shipped a QuickTime image codec component that
ran Apple Video on the Am29000. System 7's card dropped the codec, and its
commands `$39`-`$3B` fall to the default.

**Which routine does what.** The immediates (bits 0-7, plain in every System
6 word) tell the two `'rpza'` routines apart:
* `$374A4` is the **decoder**. It masks with `$E0` and compares with `$80`,
  `$A0`, `$C0`, `$E0` (the four opcode classes of an `'rpza'` block
  stream: skip, one colour, four colours, sixteen colours) and once with
  `$E1` (the chunk header byte). It is entered by command `$39`.
* `$33218` is the **encoder**. It ORs `$80`, `$A0` and `$C0` into opcode
  bytes, and it is the larger one: 4,259 words of colour arithmetic (`and
  $1F` with shifts by 5 and 10, the fields of a 16-bit pixel), with
  `$3CA64`'s divisions. It is entered by commands `$3A` and `$3B`.
* For other types, `$39` calls `$3A964` and `$3A254` is the encoder path of
  `$3A`.

**The decoder's layout.** `$374A4` (2,579 words) checks the `$E1` header
and then splits on a local holding the destination depth (`cpneq` with
`$20`, `$10` and `$08`) into one copy of the block loop per depth, each
with its `and $E0`/`$80`/`$A0`/`$C0`/`$E0` tests. The 8-bit copy adds `and
1/2/3` and `cplt 4` steps. This happens twice: `$375DC`-`$38BB0` uses
compare chains, and `$38BB0`-`$39CF0` uses four 8-way jump tables on the
top bits of a word (`srl $1C`, `cpgtu 7`; `.lit $1248`, `$1268`, `$1288`,
`$12A8`). Helpers `$3DA5C` (7 calls, after the one-colour test) and
`$3DAAC` (8 calls) are next to the block's end. Note that the host's
`$9BBA` sends `$39` only for a 16-bit PixMap, so the 8- and 32-bit copies
are not used through it.

**The codec's switch tables (`antelope6_switches.py`).** All 167 entries
of the `.lit` group with base `$331C0` are the codec's, in 25 switches.
Their low bits decode with the periodic key (bits 0-8 from the strings,
bits 9-10 from the table samples where their class is sampled). Bits 16-23
follow from the targets: all lie in the block, so the offset is below
`$10000`. Bits 11-15 are not sampled this late in `.lit` (the last table
sample is at `.lit $10EC`), so the script fits them per switch: it keeps
the value that puts the most targets on a case-block start (the word two
back is a jump) in the `jmpi`'s function.

| `.lit` | switch at | cases | targets |
|---|---|---|---|
| `$10F0` | `$33414` (encoder) | 5 (`cpgtu 4`) | `$3339C`, `$333A4`, `$333AC`, `$333C8`, `$333D4`: all before the `jmpi`, so the switch sits at the bottom of a loop |
| `$1104` | `$34EE8` (encoder) | 17 (`cpgtu $10`) | cases 0, 1, 2, 4, 8, 12, 14, 15, 16 at `$34EF0` (right after the `jmpi`), `$34F2C`, `$34F58`, `$34F8C`, `$34FC0`, `$34FDC`, `$35010`, `$35044`, `$35070`; the other eight at `$350AC` |
| `$1148`-`$1238` | `$35B54`-`$36DD4` (encoder) | 16 switches of 4 | case `i` at `jmpi + 8 + $3C·i`, in all 16 |
| `$1248`-`$12A8` | `$38D6C`, `$3919C`, `$39580`, `$39A74` (`'rpza'` decoder) | 4 switches of 8 | only partly placed (below): case 0 right after the `jmpi`; 6 and 7 share a target; 1, 2, 3 and 5 share one that is not found |
| `$12C8` | `$3ACD8` (`$3A964`, the `'rle '` decoder) | 16 (`cpgtu $0F`) | four targets `T0`-`T3` = `$3ABC8`, `$3AC14`, `$3AC60`, `$3B250`; case `4a+b` goes to `T[(b - a + 3) mod 4]` |
| `$1308` | `$3AF28` (the same) | 16 | the same rotation over `$3AE18`, `$3AE64`, `$3AEB0`, `$3B264` |
| `$1348` | `$3BEBC` (in `$3B27C`, called only by the encoder, `$3338C`) | 17 | the same shape as `$1104`: cases 0, 1, 2, 4, 8, 12, 14, 15, 16 at `$3BEC4` (right after the `jmpi`), `$3C500`, `$3C52C`, `$3BF60`, `$3BF94`, `$3BFB0`, `$3BFE4`, `$3C018`, `$3C044`; the rest at `$3C080` |

How far this can be trusted:
* **The four-way switches are settled by their shape.** Case `i` lies at
  `jmpi + 8 + $3C·i`, so case 0 starts right after the delay slot and each
  case is 15 words. Where the open key bits allow two places, one of them is
  this one. There is one switch per pixel of the 4×4 block, each writing one
  of the four 2-bit colour indices, unrolled.
* **The two 17-way switches agree with each other.** Both have case 0 right
  after the `jmpi`, the same nine cases of their own, and one shared default
  for the other eight. The set (0, 1, 2, 4, 8, 12, 14, 15, 16) is its own
  mirror image (`x` ↔ `16 - x`), so the index is not simply a depth. What it
  selects is still open.
* **The `'rle '` rotation** fits four copy loops chosen by two 2-bit
  values, for example the source's and the destination's byte alignment
  (`4a+b` → loop `(b - a + 3) mod 4`). This reading is a guess.
* **Bits 11-15 are not constant inside a table.** In `$1104` cases 0-6 need
  `$1A` and cases 7-16 need `$1B`. In `$12C8` cases 0-2 need `$1D`, not
  `$12`, and in `$1348` cases 0-5 need `$13`, not `$10`. So the script lists
  every entry its table's value does not place, with each value that does.
  For the entries in the table above, the value chosen is the one that
  continues the table's pattern (a neighbouring value, or the `'rle '`
  rotation where two places remain).
* **The decoder's tables do not fit.** Of their 32 entries, 14 are placed.
  For 12 entries no value of bits 11-15 gives a block start, although bits
  0-10 are all "known". So either bits 9-10 are wrong there (they come from
  one or two table samples per class), or these cases do not start after
  a jump (fall-through). Their targets remain open.

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

Of System 6's 618 direct calls, none goes into the block from outside, so
the dispatcher's address loads (and `calli`) are its only entries. Inside
it, `$33218` calls `$3B27C`, `$374A4` calls `$39CF0`, and `$3C668`,
`$3C7C4` and `$3DA08`-`$3DB68` are passed around as callbacks.

There are no floating-point instructions in either version, so the block is
not a floating-point trap emulator.

### System 6 `.lit`: the low key bits from System 7 (`antelope6_lit.py`)

System 6's `.lit` has its own key (not System 6's `.text` key, and not
System 7's `.lit` key at either index). Its top byte is plain, as in System
7, and most strings are the same, so the two sections line up by their top
bytes. There are five runs, at shifts of +77 to +220 words, and 394 string
words lie in them. For such a pair the plaintexts are equal, so
`key6 = W6 ^ W7 ^ key7` wherever System 7's key is known (bits 0-11 from
`antelope_lit_key.py`). Without a single conflict:

| key6 bits | period (words) | classes sampled |
|---|---|---|
| 0-4 | 24 | all |
| 5-6 | 48 | all |
| 7 | 96 | all |
| 8 | 192 | 136 of 192 |

Bit 9 fits period 384 with 11 conflicts; bits 10-11 fit no period, but
System 7's own bits 9-11 are weak in string words. Bits 12-19 of
`key6 ^ key7` are a step function of the index, as in System 7. The jump
tables give the rest (below): bit 9 repeats every 384 words and bit 10
every 768, and bits 12-19 are a slowly falling step function. At the
start of `.lit`, bits 16-19 of key6 are 0, so the second character there is
plain. Bits 0-8 decode every fourth character.

The 26 name strings come before the first shared string
(`.lit $0000`-`$019F`). With characters 1, 2 and 4 plain and the third
supplied, each name also fits the gap to the next stub's string exactly:

| `.lit` | stubs | names |
|---|---|---|
| `$000` | `$01378` | `Bogus` |
| `$008`-`$06C` | `$013A4`-`$01504` | `RBAverage16Half`, `RBAverage16`, `RBAddPin16`, `RBAddOver16`, `RBSubPin16`, `RBTransparent16`, `RBMax16`, `RBSubOver16`, `RBMin16` |
| `$074`-`$0F8` | `$01530`-`$01664` | `StretchAverage16`, `StretchAddPin16`, `StretchAddOver16`, `StretchSubPin16`, `StretchTransparent16`, `StretchMax16`, `StretchSubOver16`, `StretchMin16` |
| `$108`-`$18C` | `$01690`-`$017C4` | `PatAverageSlab16`, `PatAddPinSlab16`, `PatAddOverSlab16`, `PatSubPinSlab16`, `PatTransparentSlab16`, `PatMaxSlab16`, `PatSubOverSlab16`, `PatMinSlab16` |

The `.lit` tables of System 6 follow (base `$01DA8` at `.lit $01A0` is
System 7's `$01A4C` at `.lit $0008`). The added group, base `$331C0`, `.lit
$10F0`-`$1388`, 167 entries, is not one switch but all of the codec's (see
"The codec's switch tables" above).

**The tables from System 7's targets (`antelope6_tables.py`).** The
function map gives a System 7 → System 6 address map for 54,077 words: word
by word in identical functions, and along the matching opcode runs in
changed ones. System 7's tables are paired with System 6's by mapped
relocation base and entry index. Fifteen pair up, and System 7's `$27674`
and `$3772C` (module support) have none. For each System 7 entry with a
resolved target, the mapped target minus the System 6 base is the System 6
plaintext, so `W6 ^ plaintext` is a full key sample. Where the string key
covers bits 0-8, 153 samples agree and 15 differ: 11 in StretchBits (86
entries against 72, so the index pairing breaks), 3 in the dispatcher and 1
in `$01DA8`. With the 343 samples that are not contradicted, bits 8-10 are
periodic (192/384/768; at 768 no conflict), bits 17-19 are a plateau
function, and bits 11-16 are a step function with some noise.

**The dispatcher table** (base `$2D59C`, 60 entries, commands `$00`-`$3B`)
decodes from bits 0-10 (offsets below `$1000`). Bit 11 is not sampled
there, so each entry fixes its block only modulo `$800`. A System 7
handler's mapped block "fits" if it agrees with the sampled bits. It fits
for 53 commands. The other seven are all explained:
* `$39`-`$3B` have their own cases in System 6 (the codec above);
* `$00` decodes to `$2DF20` and `$03` to `$2DF40`, two blocks of eight
  words that load `[.bss+0]` and store a reply at `+$1C`: `lr3 = 0` in
  `$2DF20` (all 24 bits known), `$??00` in `$2DF40`. They are System 7's
  `$327D8` and `$327F8` (`$00` and `$03` there too) word for word. The map
  places those two blocks wrongly, at `$2E0D0` and `$2E410`, because the
  codec's cases `$39`-`$3B` follow them in System 6 and the default follows
  them in System 7. It also pairs System 7's `$3279C` (command `$16`) with
  `$2DF20` for three words, and that pairing is wrong too;
* `$16` decodes to `$2DC30` (FlushGDevice, the `$29` block) or `$2E430`
  (the default, "Unknown Function"); bit 8 is open there. System 6 has no
  block for System 7's `$3279C`: its `$13` block (`$2DEC4`, `$5C` bytes as
  in System 7) runs straight into `$2DF20`. The System 6 host never sends
  `$16`, so it is the default, as `$10` is;
* `$19` decodes to `$2DCF0` (or `$2E0F0`, `$800` higher, the `$3A` case).
  `$2DCF0` is a one-long block that calls `$13ACC`, System 7's
  FlushOffscreen `$14168` mapped. System 7 has the two-long `$3C` block
  (`$32528`) before its FlushOffscreen block; System 6 has no `$3C`, so
  the map runs one block off there.

**The bit-8 errors.** Before this, `$04`, `$06` and `$10` looked
unsampled or different. Their key bit 8 (period 192) has no string sample,
and the value came from one table sample each in the table at `$0AF70`.
Those samples disagree with the string key in bits 0-7, so their pairing
with System 7 is wrong. The script now rejects a table sample whose known
string bits disagree, also when bit 8's class has no string sample (it used
to skip the check then). That leaves 318 samples instead of 343. Bit 8 then
has no conflict at period 192 (8 before), and bit 9 has 1 at period 384
(8 before). With the corrected bit 8, `$04` is `$2D7FC`, and `$06` and
`$10` are the epilogue `$2E460` and the default `$2E430`, as in System 7.

`$02`, `$05` and `$07` (and in System 7 `$06`) go to `$2E460`, the code
right after the switch's `jmpi` (System 7's `$3287C`). These commands have
no case, and the card stores no reply. An earlier version of the script
only accepted blocks that follow a jump, which excluded `$2E460` and made
these three look different.

System 7's table has one more entry (61, up to `$3C`).

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
  `add gr98, gr98, $1C`, `store`; all 24 bits known, the same words as
  System 7 `$31E58`).
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

