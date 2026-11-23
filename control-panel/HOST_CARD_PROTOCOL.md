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

The constraint for a future solution is clear: every relocated `.lit` word
is a code offset inside its own module (module ranges come from the symbol
table's per-module `.text`/`.lit` entries). For the dispatcher table the
targets are, in addition, among the about 37 case-block starts in
`$31E20`-`$328C8`.

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
| `$31FE8` | local calls with `[rec+$0C]`, clears a global, then a local call with `($..64, 1, 0)` | (local `call`) |
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
