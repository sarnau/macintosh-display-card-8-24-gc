# Host <-> card protocol (68k driver <-> Am29000 runtime)

Both sides are now readable, so the protocol can be written down from the code
instead of inferred from one end. Everything below is cross-checked against
`DRVR.s` (host), `../extracted-source/VideoDriver.s` (declaration ROM), and the
unmasked firmware `firmware/disasm/Boot.asm` / `Hand.asm` (card). Addresses are
card addresses; the host reaches `0x4Cxxxxxx` at slot base `+ 0x0Cxxxxxx` and the
card registers `0x44xxxxxx` at `+ 0x04xxxxxx`. "Verified" means both sides were
read and agree; "reading" means one side was read and the other inferred.

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
(`$C0000080`). With the 747 spill/fill words that is 3,726 full 23-bit key values,
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
samples file and XORs bits 0-12 of every word of a section. The outputs are
`firmware/ACEF_100_Antelope/text.low13.bin` and `lit.low13.bin`. Bits 13-22
stay masked. In an Am29000 word that leaves plain the RB field or low immediate
byte, and the low 5 bits of RA. Still masked are RA's top 3 bits (local versus
global), RC's low 7 bits, and the high immediate byte. Two independent checks,
neither from data the fit used:

* **Prologues.** The word before each `asgeu 64` decodes as `sub gr1,gr1,N` in
  281 of 293 cases, with every N a multiple of 8 (frame sizes 24, 16, 32, 48,
  56, 40, 64, 8, ...).
* **`.lit` switch tables** (same generator, indexed by the word's position in
  `.lit`). All 662 relocated words decode 4-aligned. Within each run the
  targets (mod 8 KB) cluster, e.g. `0858 0878 08f8 08c8 0908 097c ...`, and
  some cases repeat a target exactly (`1378 1378`, `0128 0128`). That is the
  shape of compiled switch tables, which random bits would not give. The hit
  rate on decoded `sub gr1,gr1,N` prologues is at chance (13% vs 13%), so the
  runs point at case labels, not functions.

Lead for the upper bits: within one switch table the targets mostly share their
upper bits. So for consecutive `.lit` words `raw >> 13` is `key >> 13` XOR a
nearly constant value, which would give dense, consecutive upper-bit key
differences.

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
register-dump helpers. Since Antelope does not call the services (section 6),
none of this is exercised by the accelerator proper.

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
