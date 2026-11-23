# Host <-> card protocol (68k driver <-> Am29000 runtime)

Both sides are now readable, so the protocol can be written down from the code
instead of inferred from one end. Everything below is cross-checked against
`DRVR.s` (host), `../extracted-source/VideoDriver.s` (declaration ROM), and the
unmasked firmware `firmware/disasm/Boot.asm` / `Hand.asm` (card). Addresses are
card addresses; the host reaches `0x4Cxxxxxx` at slot base `+ 0x0Cxxxxxx` and the
card registers `0x44xxxxxx` at `+ 0x04xxxxxx`. "Verified" means both sides were
read and agree; "reading" means one side was read and the other inferred.

## Overview: what the card does, and how the host talks to it

This is a summary of the sections below. Most of it was found in
the long section "Antelope: the command dispatcher", which now has `####`
sub-headings for each topic. Later findings correct some earlier
paragraphs, and this overview gives the current state.

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
| `$03`/`$33`, `$19`, `$1A`, `$0C`, `$17`/`$2C`, `$29`/`$2B` | offscreens, colour tables, pixel patterns, GDevices changing | DisposeOffscreen, FlushOffscreen, FlushColorTable, CachePixPat, FlushPixPat, FlushGDevice: the card's caches of host objects |
| `$26`, `$38`, `$0D`, … | begin / synchronise around drawing | state and bookkeeping |
| `$20`-`$24`, `$2E`, `$2F`, `$31`, `$18` and the pen/colour/region state changes, carried by `$2D`/`$38`/`$26` | `StdLine`, `StdText`, `StdArc`, `StdRect`, `StdRRect`, `StdOval`, `StdPoly`, `StdRgn`: `EngineDispatch` does not send these one by one but appends a record to a stream in card memory | `$13770` → `DrawMultiObject`, which plays the stream back (see "The host side of DrawMultiObject") |
| `$8000`-`$8004` | module API: run, allocate, free, echo | `sub_37B58` |

**The Std\* drawing calls are batched, not sent.** `StdLine` (`$20`),
`StdText` (`$21`), `StdArc` (`$23`), `StdRect` (`$24`) and the other drawing
selectors would go to "Unknown Function" if they reached the card's
dispatcher. They do not reach it: `EngineDispatch` turns them into records
of a DrawMultiObject stream (opcodes 1-8 plus state records), which it
appends to a buffer in card memory and hands over with `$2D`, `$38` and `$26`.
(An earlier version of this document concluded that they were not
accelerated at all. That was wrong.) When the stream cannot be used, for
example with no current port, `EngineDispatch` returns 0 and the 68K draws.

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
(likely); text `$11AD8` (DrawMultiObject's text opcode reaches it); DrawArc `$075DC`, DrawLine `$08618`, QuickPolys
`$19270` (from DrawMultiObject's polygon opcode); RSect `$01494` and TrimRect `$01654`
(from its region opcode); ITabMatch `$06650`; BitsToPixMap
`$06BEC`; DisposeOffscreen `$14034`; FlushOffscreen `$14168`;
FlushColorTable `$141F8`; CacheGDevice `$14F64`; CachePixPat `$151C4`;
FlushGDevice `$15808`; FlushPixPat `$158F4`; PRInit `$161F8`; PRAlloc
`$16A04`; `MapVirtual` `$3373C` and its release `$33A9C`; ShieldCursor
`$32C10` and its after-drawing counterpart `$32EF8`; `CallBack`
`$33EBC`; the request wrappers `$33BD0`-`$33E88`; the card heap
`$372D0`-`$3772C`.

**Still open:**
- DrawMultiObject's opcodes are named from the host writer; still open are the two longs at `+4`/`+8` of the text record and the font id in `$67`, and why two `.lit` table values (opcodes 1 and `$72`) decode to the wrong targets;
- the card's cursor overlap test (`$32C10`/`$32EF8`), read only in outline;
- kernel service `$D2`'s exact role;
- `.text` key bits 19-23, and so the masked fields of most instructions.

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
trigger the bulk word copies ($2000DBC.. / $2000E8C..), other values skip them
(**reading**: what the copies do to the frame buffer is not worked out).

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
| `$2D7B4` | 86 | 78 | 15% |
| `$3772C` | 23 | 21 | 19% |
| `$25350` | 27 | 22 | 12% |
| `$0AD14` | 29 | 23 | 11% |
| `$01A4C` | 50 | 40 | 17% |
| `$19DA0` | 66 | 53 | 25% |
| `$13F50` | 32 | 21 | 15% |
| `$27674` | 16 | 13 | 20% |

So the `.lit` key model (bits 0-7 from the strings, bits 8-11 by class)
holds across all of `.lit`. Two groups are not case-block tables and are
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
| `$03`, `$33` | `$324F8` | one long -> `$14034` **DisposeOffscreen** |
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
| `$30` | `$322D4` | the bit-mask chain (`$14B64`, `$14A80`) |
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
| `$14034` | "DisposeOffscreen: NULL offscreen Handle" | command `$03`/`$33` |
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
| `+$2C`, `+$30`, `+$54`-`+$5C` | `$1701C`, `$17264`, `$00248`, `$00348`, `$00294` | small helpers (`$00348` is called by nearly every blitter) | |

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

So only QuickPolys = `$19270` is a likely name. Which of `$075DC`/`$08618`
draws lines needs their DrawMultiObject opcodes, which are not mapped yet.

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
5. test the drawing rectangle against the cursor rectangle, side by side
   (`$78`/`$7A`/`$7C`/`$7E` against the device-relative `CrsrRect`). No
   overlap: skip to the end.

**`$32C10`, before drawing: remove the cursor.** It publishes the drawing
rectangle at `+$1DC` (`loadm`/`storem` from `extern#1772+$78`). If `CrsrVis`
(through `+$5FC`) is set and `+$5F0` is not already raised, it does
`UnblitCursor` from `CCrsrCore.a`:
* it reads `CCSTATEREGS` from the save area (`+$1E4` → `+$3E` ROWCNT, `+$40`
  LONGCNT, `+$44` DSTBUMP, `+$48` DSTLEFT);
* it copies the saved bits back to the screen row by row:
  `$38218(screen row, save buffer, longs)`, with the screen pointer stepped
  by DSTBUMP;
* the 68K version ends with `CLR.B CrsrVis`. The card leaves that to the
  host and raises `+$5F0` instead.

Then it releases `+$1D8`. The rectangle at `+$1DC` stays published.

**`$32EF8`, after drawing: re-save and ask for a redraw.**
* It runs the same row loop with the two pointers swapped,
  `$38218(save buffer, screen row, longs)`, so the freshly drawn pixels
  under the cursor become the new save-under bits. There is no `CrsrVis`
  test.
* It stores a size computed with the multiply millicode `$3B814` (rows ×
  longs) at `+$1EC`.
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
   the save buffer, and raises `+$5F4` (the host sets `CrsrNew`);
4. the host's cursor task draws the cursor again.

Re-saving means a 68K hide that runs before the host has seen `+$5F0` restores
the new pixels, not stale ones. That would explain why the card bothers, but
it is a reading.

The high bytes of the flag offsets are masked (`$??F0`, `$??F4`), so `$5F0`
and `$5F4` come from matching them with the host side. The argument order of
`$38218` (destination first) is inferred from the two calls being mirror
images. What `+$1EC` is used for later is not found.

#### DrawMultiObject

**DrawMultiObject's opcodes (partial).** `$0AD18` runs a loop over an opcode
stream. The opcode is in `lr81`, the operands are read through `lr38`
(`[lr38+2]`, `+4`, `+6`, …: halfword fields), and the dispatch sits at the
loop's end (`$0E22C`-`$0E2EC`):

| opcodes | dispatch |
|---|---|
| 1-5 | table `.lit $0484` (`opcode - 1`, 5 entries) |
| 6, 7, 8, `$64`, `$66`, `$67`, `$68` | compare chain |
| `$6A`-`$75` | table `.lit $0498` (`opcode - $6A`, 12 entries) |
| anything else | "DrawMultiObject: unknown opCode %d" (`.lit $0430`) |

That is 24 opcodes; `$65` and `$69` are not used. The values do not follow
the PICT opcode numbering.

The two 6-entry tables (`.lit $0454`, `$046C`) are not opcode tables. They
are sub-switches on `lr94` (0-5), inside the drawing code at `$0CD30` and
`$0CEE4`. Cases 0-2 call `$09430`, case 3 calls `$09578`, and cases 4-5 go
elsewhere. Both switches come right after `$1553C` and `$32C10`, and
DrawMultiObject's own messages are about pattern, "thickPat", RGB-pattern
and font cache entries. So `lr94` is probably the fill kind (old pattern,
pixel pattern, RGB pattern …), and `$09020`-`$09660` are the fill loops.
That reading is not checked.

**The opcode → block mapping from the table alone (superseded below).** The table words give
only the low 12 bits of each target, and the module is `$3680` bytes long.
For every entry, exactly one block start (a word after a jump) matches, but
several of the picks are clearly wrong: `$0B8C4` (opcodes 2 and `$6A`) tests
`lr6`, not the opcode, and `$0D9C4` (opcodes 3, 4) tests for opcode 2. The
"word after a jump" test is too loose inside this function, where cases fall
into shared code. Naming the opcodes needs the high bits from somewhere
else, for example by estimating bits 16-23 of the case blocks'
`jmp` words (`antelope_estimate_words.py`).

**DrawMultiObject's opcodes, mapped through the estimated words.**
`antelope_estimate_words.py` decodes 3,256 of DrawMultiObject's 3,488 words
(491 samples, 2,765 estimates from neighbouring samples; 232 are left). That gives most
jump targets in full:

* The compare chain resolves directly: opcode 7 → `$0C398`, 8 → `$0D6E8`,
  `$64` → `$0B230`, `$66` → `$0B458`, `$67` → `$0DE00`, `$68` → `$0BD7C`.
  Anything unmatched goes to `$0E20C` (the "unknown opCode" message).
* For the table entries, the candidate after a `jmp` and its delay slot is
  taken, as before.
* For opcode 6 (its jump is not estimated), only one of the possible targets
  follows a `jmp`: `$0E018`.
* `$6F` → `$0B228` is `jmp $0B450` with `lr38 += 4` in the delay slot,
  so `$6F` skips its record. `$72`'s entry resolves to `$0E22C`, the
  start of the compare chain, which is probably wrong (see the compare
  chain below).

A trace from each case through the estimated words, following both branches
and stopping at the dispatch, gives the first drawing routine each one
reaches:

| opcodes | first drawing call | reading |
|---|---|---|
| 3, 4 | `$075DC` (drawer A) | **arc** (and probably oval / round rect) |
| 5 | BitBlt / RgnBlt, then the fill loops `$09020`/`$09270` | rectangle or region fill |
| **6** | **`$11AD8` (text)** | **text**; this is the only path to the text call at `$0E1B0` |
| 7 | `$08618` (drawer B), then `$19270` (polygons) | **polygon** (inline `Polygon` record) |
| 8 | RgnBlt | region |
| `$73` | `$08618` (drawer B) | **line** |
| 2, `$6A`, `$71`, `$74`, `$75` | none; they reach the pattern-cache routines `$1610C`, `$15E8C`, `$15154`, `$15FF4`, `$1518C` | set a pattern |
| `$64`, `$66`, `$6D` | none; they reach request 13 (`$0688C`, colour → index through the search procs) | set an RGB colour |
| `$68`, `$6C`, `$6E` | none; they reach `Entry2Index` | set a palette-entry colour |
| `$67`, `$70` | none | other state |
| `$6F`, `$72` | none | skip |

(The traces for the state opcodes run on through the loop head into the
next dispatch, so their "reach" column is weaker than the drawing rows. The
record layouts below are read from the case code directly.)
| 1 | not resolved | |

So the stream mixes drawing opcodes (3-8, `$73`) with state opcodes
(pattern, colour). That is the same split as a QuickDraw picture, though
with its own numbering. Its text opcode confirms `$11AD8` as the text
routine. Opcode 7's operands then settle lines versus arcs (next paragraph).

**Opcode 7 is a polygon, and that settles lines vs arcs.** Its case
(`$0C398`, estimated words, the operand pointer `gr96 = lr38 + 4` set in
the jump's delay slot at `$0E274`) reads:

```
gr98 = half[lr38+4]                  polySize
lr93 = (polySize - 10) / 4           number of points (size word + bbox + 4 bytes per point)
lr82 = half[lr38+2]                  a flag/verb word
lr92 = lr38 + $0E                    the first point (after polySize and polyBBox)
lr38 += (polySize + 7) & ~3          skip the inline polygon, long-aligned
if lr93 == 0: next opcode
```

So the stream carries a QuickDraw `Polygon` record inline. The case calls
drawer B (`$08618`) first and then `$19270`. In QuickDraw, `FramePoly`
draws the outline as lines between the points, and the filled verbs go
through `QuickPolys`. So:

* **`$08618` is DrawLine**, the line drawer, used here to frame the polygon,
  and by opcode `$73` on its own (the line opcode);
* **`$19270` is QuickPolys**, which fits its store-heavy profile;
* **`$075DC` is DrawArc** by elimination (opcodes 3 and 4: arcs, and
  probably ovals or round rects, which QuickDraw also draws through
  DrawArc). It is also the one that multiplies (`SlopeFromAngle`, `FixMul`
  in `DrawArc.a`).

Opcodes 3/4's case (`$0D9C4`) is not estimated (no samples nearby), so its
operands are not read.

**The record format.** Each case ends by advancing `lr38`, usually in the
delay slot of its `jmp $0B450` back to the loop. That gives every record's
size, and the case's loads give the fields. The loop head reads the opcode as
a signed half at `lr38+0` (`$0AF90`) and runs while `lr38 < lr37`, the end of
the stream. The table dispatch's delay slot (`$0E268`) sets `gr96 = lr38+4`,
the payload. So a record is a 2-byte opcode, a 2-byte word at `+2`, then the
payload, padded to a multiple of 4:

| opcode | case | size | fields (offsets from the record start) |
|---|---|---|---|
| 5 | `$0C754` | 12 | `+2` verb (`lr82`), `+4` Rect |
| 6 | `$0E018` | `(n + $13) & ~3` | `+2` n, a byte count; `+4` a long, stored to a global; `+8` and `+$0C` longs; `+$10` the n text bytes. `$11AD8` gets the count, a pointer to the bytes, and the longs at `+8` and `+$0C`. (The compare chain's delay slot at `$0E23C` sets the operand pointer to `lr38+$0C`, not `+4`.) |
| 7 | `$0C398` | `(polySize + 7) & ~3` | `+2` verb, `+4` Polygon |
| 8 | `$0D6E8` | `(rgnSize + 7) & ~3` | `+4` Region (`rgnSize` first) |
| line | `$0BDB0` | 8 | `+4` v, `+6` h of the end point. It draws through DrawLine (`$08618` at `$0C284`), with ShieldCursor `$32C10`/`$32EF8` around it, then sets the pen (`lr25`, `lr36`) to the end point (`$0C388`): **LineTo** |
| `$68` | `$0BD7C` | 8 | `+2` a word (`lr103`), `+4` v, `+6` h into `lr25`/`lr36`, the pen position the line case draws from: **MoveTo**. Opcode 7 also sets them, from the first point, when its verb is non-zero |
| `$6E` | `$0BD98` | 8 | `+4` v, `+6` h into `lr49`/`lr48`, a second point (pen size, perhaps) |
| `$71` | `$0B6D8` | 12 | `+2` slot 1, 2 or 3; `+4` an 8-byte bit Pattern; the slot's kind is set to 0 |
| (none found) | `$0B72C` | 8 | `+2` slot 1-3; `+4` a long (a PixPat, perhaps); kind 1 |
| `$74` | `$0B788` | 12 | `+4` slot 1-3; `+6` an RGBColor; kind 2 (the "RGB Pattern" of the cache message) |
| `$75` | `$0B7B8` | 8 | `+4` a long, stored to a global |
| `$70` | `$0BB7C` | 16 | `+4` long and `+8` half, stored to a global; `+$0A` an RGBColor, passed to a call |
| `$6C` | `$0BBC4` | `(rgnSize + 5) & ~3` | a Region at `+2`. `$6C` keeps a pointer to it in `lr54`; another opcode sharing the code (not identified) keeps its region in `lr19`. These are the clip and visible regions (below) |
| `$64` | `$0B230` | 12 | `+2` onwards handed to a call with a global address: an RGBColor at `+4`, probably |
| `$66`, `$6D` | `$0B458`, `$0B584` | 16 | colour records; `$66` reads `+8` and `+$0C` |
| `$67` | `$0DE00` | 32 | compares the long at `+$1C` with a cached value before calling out (a font or width table selection, perhaps; the "not in cache" messages are about fonts and width tables) |
| `$6F` | `$0B228` | 4 | nothing |

So the three pattern slots each come in three kinds: an old 8-byte pattern
(`$71`), a long (`$0B72C`), or an RGB colour (`$74`). These fit pen, fill and
background patterns, though the order of the slots is not known.

**The region opcodes, and RSect / TrimRect.** Once both region pointers are
set, the `$6C` case (`$0BBFC` onwards) loops over the devices (`lr76` up to
`lr105`) and runs the clipping set-up that `DrawArc.a` and `DrawLine.a`
begin with:

```
68K DrawArc.a                                  card, $0BC28-$0BD20
RSect(dstRect, bounds, clipRgn^^.rgnBBox,      $01494(minRect, 3, device bounds,
      visRgn^^.rgnBBox; n = 4) -> minRect             lr19+2, lr54+2)
if region is not rectangular:                  for lr54, then lr19:
   TrimRect(rgn, minRect, trim = true)            store it in a per-device slot
                                                  if rgnSize != 10: $01654(rgn, minRect, 1)
quit if the intersection is empty              an empty result clears lr11
```

`rgnSize = 10` is a rectangular region (size word plus bounding box). `+2`
in a Region is `rgnBBox`. That names two helpers that every drawing routine
calls:

* **`$01494` is RSect**, intersecting n rectangles: here 3, without the
  68K's separate destination rectangle. It is called by DrawArc, DrawLine,
  QuickPolys, the text routine and StretchBits (four times);
* **`$01654` is TrimRect**, called twice by each drawer (once per region).

It also confirms that the two pointers are QuickDraw's clip and visible
regions. Which of `lr54` and `lr19` is which is not decided.

**The compare chain, read from the known low bits.** The words at `$0E21C`
to `$0E250` are not estimated, but their low 16 bits are known:

```
$0E22C  cpgt  ?, lr81, 6      $0E238  jmpt  -> $0E018 (fits the known low bits)
$0E230  jmpt  -> $0E26C       $0E23C  add   ?, lr38, $0C   (delay slot)
$0E234  cpeq  ?, lr81, 6      $0E240  sub   ?, lr81, 1;  cpgtu ?, 4  -> table .lit $0484
```

So opcode 6 does go to `$0E018`. Its operand pointer is `lr38+$0C`, not
`+4`.

`$0E22C` is the start of this chain, and the table entry for `$72` resolves
to it. Jumping there with `lr81 = $72` would fall through every compare to
"unknown opCode". So that resolution is probably wrong too. The candidate
`$0B22C` (the delay slot of `$6F`'s `jmp`, which adds 4 to `lr38` and runs
on into the `$64` case) would make `$72` a `$64` with 4 extra bytes in
front. That fits the code, but nothing confirms it.

**Two open points in the table dispatch.**
* The `.lit` value for `$73` gives `$0C1D4`, which lies inside the line
  case's body, not at its entry `$0BDB0`. The line case is entered at
  `$0BDB0` cleanly (after a `jmp` and its delay slot), but none of the
  table values gives that address.
* The values for opcode 1 (`$xBB0`) and `$6B` (`$xB440`) give no clean
  entry in any 4-KB page.

So either the estimates near those targets are off, or these entries point
into shared code. Which opcode is LineTo is therefore not certain: `$73` is
the best candidate.

This mapping rests on estimated words ("=" in the tool's output, not
samples). The estimates have been right wherever they could be checked (the
dispatcher), but each row here is a reading, not a proof.

**Who reaches DrawMultiObject.** Inside Antelope only `$13770` calls it, and
`$13770` is reached only by command `$2D` (and the entry table). `$2D` is
sent by `EngineDispatch` itself (`gc24.s` `$4F38`) when it starts a new
stream. See the next section.

#### The host side of DrawMultiObject: EngineDispatch batches the Std\* calls

**EngineDispatch is the stream writer.** For commands `$0C`-`$38` it jumps
through its own table (`$4A52`). Most cases end in the generic send path
(`L5E6C`), but the drawing commands go to `L4AAC`. That code:
1. checks the current port (from the A5 world). With none, it flushes and
   returns 0;
2. when `picSave`, `rgnSave` or `polySave` (port `+$5C`/`+$60`/`+$64`) is
   set, notes the reply 2 (below);
3. emits state records for whatever changed since the last call (it
   caches the port's state in its globals);
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

When a record would not fit (`$BC − size − $24 ≤ $C0`), it flushes with
`sub_4822(reason)`, that is `EngineDispatch($26, reason)`. The reasons seen
are 8, 9, `$12`, `$13`, `$14` and `$18`.

**Starting a stream** (`$4EBC`, when the port differs from the cached one):
1. reset the buffer;
2. write a 4-byte `$6F` record at its start;
3. set the length to 4 (at `+$50` of a block at packet `+$170`, whose
   `+$4C` holds the card address);
4. send `$2D` with that block. The card enters DrawMultiObject and runs
   until the first wait.

**After each drawing call** (`$38`, `L5DE0`), if the buffer holds more than
the header:
1. rewrite the `$6F` header's word at `+2` with flags (`$F0(a4)`);
2. send `$38` with (card address, byte count).

On the card, the nested wait inside DrawMultiObject services `$38`. Its case
stores the count (`[p[0]+4]`) in the length word that DrawMultiObject
re-reads, so the card carries on with the new records. `$26` (`L5D84`)
first sends a final `$38` if needed and then ends the batch. The card's
wait returns `$C8`/`$C9` after `$26`/`$30`.

**The reply.** EngineDispatch returns 1 ("done", the 68K skips the call).
When the port is recording a picture, region or polygon, it returns 2. It
also restores `HiliteMode`, `pnLoc` and `pnLocHFrac` first, so the 68K
original runs with drawing suppressed and records the call. That is the
meaning of reply 2.

**Commands → records** (from the chain at `$555C` and the patch table in
`QUICKDRAW_PATCHES.md`):

| command (patch) | record | layout written by the host |
|---|---|---|
| `$20` (StdLine) | **1** | 8: `+4` the new point (also stored as the port's `pnLoc`) |
| `$23` (StdArc) | **2** | 16: `+2` verb, `+4` rect, `+$C` startAngle, `+$E` arcAngle |
| `$2F` (StdOval) | **3** | 12: verb, rect |
| `$2E` (StdRRect) | **4** | 16: verb, rect, `+$C` ovalWidth, `+$E` ovalHeight |
| `$24` (StdRect) | **5** | 12: verb, rect |
| `$21` (StdText) | `$67` if the font changed, then **6** | `$67`: 32 bytes, `+2` the 26-byte `FMOutput` record, `+$1C` a long from `$106(a4)` (a font id set by `sub_88E6`). 6: `+2` count, `+4` and `+8` two longs from `sub_88E6`, `+$0C` the text's width (Fixed, from `StdTxMeas`), `+$10` the text |
| `$31` (StdPoly) | **7** | verb, the Polygon (`BlockMove`, `(polySize + 7) & ~3`) |
| `$18` (StdRgn) | **8** | verb, the Region |
| `$10` (visRgn changed; also sent from the port check at `$51A4`) | `$6C` | the Region at `+2`, `(rgnSize + 5) & ~3` |
| `$32` (SetClip, ClipRect) | `$6A` | the clip Region at `+2`, same size rule |
| `$35` (PenSize, SetPenState, PenNormal) | `$6E` | 8: `+4` pnSize |
| `$36` (ForeColor, RGBForeColor, PmForeColor) | `$66` or `$64` | `+4` the RGB colour (port `+$24`), `+8` the index (`+$50`); `$64` when `sub_917e` gives an index |
| `$37` (BackColor, PmBackColor) | `$6D` or `$6B` | the same from `+$2A`/`+$54` |
| (pen location changed, `sub_8DA4`) | `$68` | 8: `+2` `pnLocHFrac` (`$8000` for an old port), `+4` `pnLoc` |
| (OpColor or HiliteColor changed, `sub_8DF2`) | `$70` | 16: `+4` the hilite colour (`grafVars^.rgbHiliteColor`, or `HiliteRGB` `$DA0` for an old port), `+$0A` `rgbOpColor` |
| (a pattern slot changed, `sub_8F04` result 1-4) | `$71` / `$72` / `$74` / `$72` | `$71`: `+2` slot, `+4` 8-byte pattern; `$72`: `+2` slot, `+4` a long (a PixPat); `$74`: `+4` slot, `+6` RGB colour |
| (pattern slot changed, from `sub_8E38`) | `$73` | 4: `+2` slot: 1 pen, 2 background, 3 fill |
| (`patAlign` changed; the QuickDraw global at −168) | `$75` | 8: `+4` `patAlign` |
| (transfer mode changed, from `sub_8E38`) | `$69` | 4: `+2` the mode |
| (stream header) | `$6F` | 4: `+2` flags, rewritten before each `$38` |

**How a drawing call is prepared (`$4B7E` onwards).** Before any record is
written, EngineDispatch reserves room: `$90` bytes plus the size of any
changed clip or visible region (each `(rgnSize + 5) & ~3`) plus the call's
own data. If that does not fit, it flushes (reason `$10` or `$12`). Then,
per command:
* **StdLine** checks only the pen.
* **StdText** also calls `sub_88E6`. That measures the text with
  `_StdTxMeas`, scales it (`FixScale`) and compares the font output with
  the cached `FMOutput` (`EqualFontOutput`). A change means a `$67` record,
  and possibly a `$38` flush first. A failure flushes with reason 5 and
  leaves the call to the 68K.
* **StdRRect** with a zero oval width or height is sent as StdRect (`$24`).
* **StdPoly** and **StdRgn** reserve their record size.

The mode and pattern come from `sub_8E38(verb, &mode, &frame, &slot)`,
which is QuickDraw's own verb table:

| verb | mode | pattern slot |
|---|---|---|
| frame, paint | `pnMode \| 8` | 1, the pen pattern |
| erase | patCopy (8) | 2, the background pattern |
| invert | patXor (`$A`), with `black` (QuickDraw global −16) | 3 |
| fill | patCopy | 3, the fill pattern |
| text (5) | `txMode & ~8` | unchanged |

If `HiliteMode` bit 7 is clear (a hilite is pending), patXor becomes `$3A`
and srcXor becomes `$32` (the hilite modes), and the bit is set again, as
QuickDraw does. `frame` is −1 for the frame verb and 0 otherwise. It is the
word at `+2` of the shape records, so the card's "verb" word (`lr82`) is a
"frame" flag. The mode is compared with the cached one (`$CC(a4)`): a change
emits `$69`. The slot goes into `$73` and into `$F2(a4)`.

**After a StdText record** the host advances its own pen by the measured
width: integer part to `pnLoc.h`, fraction to `pnLocHFrac`. It writes both
into the port, so the 68K's idea of the pen stays right although the 68K
drew nothing.

**What this settles on the card side:**
* **Opcode 1 is the line**, the `$0BDB0` case (end point at `+4`; the pen
  moves there). Its `.lit` value decoded to `$xBB0` (the case needs `$xDB0`), so that entry's decoding is wrong. **`$73`
  is not a line**: it selects a pattern slot, which fits the card's `$0C1D4`
  code storing into one of three slots by `lr4`.
* **2 = Arc, 3 = Oval, 4 = RoundRect, 5 = Rect.** QuickDraw draws ovals and
  round rects through DrawArc, which fits 3/4 sharing `$0D9C4`. 2 is the
  arc with angles, at `$0B8C4`.
* **`$72` is the "long" pattern kind** (the `$0B72C` case); its `.lit` value
  `$518` was decoded wrongly as well (the case needs `$A18`).
* **`$6B`/`$6D` are background colours** and `$64`/`$66` foreground colours.
  `$6B`'s `.lit` value `$xB440` lands in the `$64` code, which handles the
  same layout.
* **`$6C` is the visible region (`lr54`) and `$6A` the clip region
  (`lr19`).**
* **`$68` is MoveTo** with `pnLocHFrac` at `+2`. **`$6E` is the pen size.**

The "first drawing call" table and the record table above were read from
the card alone. Where they differ from this, this section is the reference.


**DrawMultiObject's prologue and loop head (`$0AD18`-`$0AF90`).**

*Initial state.* Before the first record the prologue:
* runs a per-device set-up loop over 44-byte device records (`lr111`, `lr76`
  up to `lr105`);
* calls `$169A0`;
* clears the interpreter state.

Cleared to 0:
* both region pointers (`lr54`, `lr19`), so the RSect/TrimRect clipping
  in the `$6C` case runs only once the stream has supplied both regions;
* `lr20`, which the `$0B7D4` case compares a word against;
* `lr27`, the "pattern changed" flag that the pattern opcodes set to 1;
* `lr28`, the chunk status (below);
* `lr50`, `lr70`-`lr72` (`lr72` is set to 1 by the `$0B214` record),
  `lr75` and `lr32`-`lr34`.

The pen (`lr25`, `lr36`) and the three pattern slots are **not** set. A
stream has to start with MoveTo (`$68`) and its patterns, as a picture
does.

*The stream buffer.* The stream starts at `lr102` and ends at `lr102 +
[lr53]`, a byte count in memory. The loop head (`$0AEC8`) calls `$33304`
with the record pointer before every record. `$33304` adds 1 to packet
`+$1C4` (the card heartbeat the host watches) and stores the pointer in
packet `+$1C8`, so the host can see how far the card has got.

*At the end of the bytes* (`lr38 ≥ lr37`):
* **If the last status was `$C9`**, it leaves (`$0DF28`).
* **Otherwise it waits in `sub_33374`**, the nested wait loop. That loop
  services only `$0C` CachePixPat, `$26`, `$2A`, `$2C`, `$30` and `$38`
  meanwhile, and returns `$C8` or `$C9` after `$26`/`$30`.
  * The wait is timed: service `$11` (stub `$38FE8`) is called before and
    after it.
  * The difference goes to `$3328C`, which counts the waits (`.bss+$10`),
    adds up their time (`.bss+$0C`) and keeps a maximum in packet
    `+$1CC`/`+$1D0`.
  * The prologue's call `$33238(-1)` resets these statistics.
* After the wait it re-reads `[lr53]` and sets `lr37 = lr102 + [lr53]`,
  without resetting `lr38`. So the host appears to append records to the
  same buffer and publish the new length. `$C8` would then mean "more
  records" and `$C9` "that was the last batch", but this reading rests on
  estimated words.

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

#### The Std* selectors are not handled on the card

(These selectors never arrive here in practice: `EngineDispatch` turns them
into DrawMultiObject records instead of sending them. See "The host side of
DrawMultiObject". What follows is what the card's dispatcher would do with
them.)

**So the drawing selectors reach the default.** `$20` StdLine, `$21`
StdText, `$23` StdArc, `$24` StdRect, `$2E`, `$2F`, `$31`, `$18`, `$2A`,
`$32` and `$35`-`$37` decode to low byte `$70`. Inside `sub_31e20`
(`$31E20`-`$328C8`), the only block starting at an offset `$x70` is the
default `$32818`. The low byte comes from the strings and is exact. So in
this switch they print "Unknown Function". If Antelope accelerates them at
all, it does so before the switch. The only call there is system call
`$??D2`, made for every accepted command, without arguments, and before the
`$8000` test. Its service in the runtime (`Hand`) is the next thing to name.

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

On the host, `GA_StdLine` (`$3682`) is typical. It sends `$20` with one
argument (a pointer to its own parameters), then acts on the reply:

| reply | host does |
|---|---|
| 1 | nothing more: the card drew it |
| 2 | runs the original `StdLine` with `pnVis` set to -1 (the pen moves, nothing is drawn), then restores `pnVis` |
| anything else (0) | runs the original `StdLine` |

Before the fallback, it calls `sub_86D6`, which sends `$38` (synchronise)
and works out the destination pixmap. After the fallback, it calls
`sub_879A` when `sub_86D6` asked for it. So with this Antelope, every
`StdLine`, `StdText`, `StdArc` and `StdRect` costs a round trip to the card,
gets reply 0, and is drawn by the 68k QuickDraw. That is a working design:
the screen is in card memory, which the host can write over NuBus.

**So the open question closes** (the condition below is checked in the next paragraph). The card accelerates:
- StretchBits (command `$15`, and through it CopyBits);
- the cache commands;
- the `$80xx` module interface;
- `DrawMultiObject` through `$2D`.

It does not handle the Std* drawing selectors itself. The condition is the
dispatcher table: all 61 entries are fitted in bits 0-11, and the Std*
entries come out at the default's low byte `$70`. Bits 0-7 of those
entries are exact; bits 8-11 come from the joint fit, which is checked but
not certain for every class, as the six uncertain entries show. The pre-switch service `$D2` runs for every
accepted command, but takes no arguments and does not touch `rec`, so it
cannot draw a line from the packet.

That fits the gc24 being more general than this firmware. Its patches are
written for a card that might accelerate every selector, and the reply
protocol (0 = do it yourself) lets one gc24 work with firmware that handles
fewer.

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
selectors are not handled on the card at all (see "What the default does"
above).

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
