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
  `65` (`asleu 65,lr2,gr127`), which match the kernel's spill/fill handlers
  `$2001184`/`$20011B8` (vectors 64/65) (**verified**).
* **Externals.** 21 undefined symbols, all common (bss) variables of 4-424 bytes
  (one 152-byte block referenced 536 times); names stripped.
* Whether Antelope calls the kernel services (`asneq 69`) or touches hardware
  addresses is **unknown**: its operand fields cannot be read until the mask is
  solved. The entry stub (`Code`, 38 words) also shows an `asneq trap69` and a
  `const` with plain high byte `$01` before it (words 8-9), and a second one
  (word 35) before the exit `jmp`, consistent with a `$1xx` service call (maybe
  `$104`, the `InpArgs` pointer) and `exit`.

**Mask status.** The 293 `asgeu 64,gr1,gr126` and 454 `asleu 65,lr2,gr127` words
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
