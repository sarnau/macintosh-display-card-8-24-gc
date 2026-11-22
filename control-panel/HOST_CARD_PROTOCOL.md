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

## 6. What Antelope uses from the kernel (and what it does not)

Checked against the relocation table of `ACEF_100` (Antelope):

* **Register stack.** The loader patches the vector byte of 293 `asgeu` words to
  `64` (`asgeu 64,gr1,gr126`, the spill check in function prologues) and of 454
  `asleu` words to `65` (`asleu 65,lr2,gr127`, the fill check). They land in the
  kernel's spill/fill handlers `$2001184`/`$20011B8` (**verified**; these
  are vectors 64/65, not 61/62 as an earlier note said).
* **No kernel calls, no hardware addresses in `.text`.** Antelope's `.text` has no
  `asneq`/`aseq` service-call words, no `consth $0200` kernel-routine pointers and no
  `consth $4C00/$4400/$4600` constants outside relocations, so it does not call
  the service entries (vector 66/69) or touch the card registers itself.
* **Its only externals are 21 common (bss) variables** with sizes 4-424 bytes
  (one 152-byte block is referenced 536 times, a 264-byte block 44 times, a 68-byte
  one 58 times). They are allocated by the loader; names are stripped. These
  and the entry address at `PublicIn+$04` are therefore the interface; the 68k
  side must know their addresses (via `unit +$130`/`ACEFLoad`'s return), which is
  why `LoadFirmware` publishes `+$0C`.

The one exception is the small entry stub, Antelope's `Code` section (38 words
at `$F000`, the thing the kernel jumps to via `PublicIn+$04`): it is **also
masked** with the same generator (own tables; only its first three words decode
as written). Decoded with `Hand`'s or `Boot`'s tables it becomes recognisable
start-up code -- stack setup, `const`/`consth` pointer loads, `calli` calls and
`asneq trap69,..` (the host-interface service call, used for exit) -- but the
tables are not right for it, so its register fields are unreliable and it is
not decoded here. So the kernel services (`sbrk`, `InpArgs`, time) are used,
at most, by that stub; the accelerator proper does not call them; naming Antelope's functions from kernel
anchors is therefore not possible beyond the spill/fill convention.

## 7. The accelerated-QuickDraw command queue (`gc24.s` -> Antelope)

`gc24.s`'s generic issue routine (`EngineDispatch` `$49C4`, with the parameter
copy `CopyParamsToQueue` `$5FF2`) uses the same unit record as the driver
(`A4`): it picks it up through low-memory `$888` -> globals `+$214`. Read from
the code:

1. It requires the unit's state flags (`+$08`) to show "firmware loaded" and
   no `$600` bits, then calls `sub_6F4E` if a previous request is still
   outstanding (`+$1C` bits).
2. It sets `A3 = [A4+$18]` (the queue/parameter write pointer on the card),
   `header = [A4+$0C]` (the card-side command header, slot space base `+ $8C00`,
   set in `BuildUnitRecords`) and `flag = [A4+$10]` (a host-memory flag word
   per slot: `globals+$234 + slot*4`). If the flag word has bit 3 set it takes
   the "busy" path (`+$1C |= $10`); otherwise it sets `+$1C |= 4`, clears the
   flag word and writes to the header: `+$18 <- 0`, **`+$48 <- command code`**,
   `+$4C <- sequence number` (`A4+$20`, incremented), `+$50 <- parameter count`.
3. It copies the parameters with an unrolled loop (8 longwords at a time, then
   the remainder through the jump table at `$5FF6`) to `[A3]`,
   then stores `$FFFFFFFF` at `header+$14` (the "go" word), sets `+$1C |= $C`
   and `A4+$170 <- command code`, and waits on the host flag word:
   bits 0-1 = completion/status, bit 2 = "reply to fetch" (it then calls
   `sub_6442(header, A4+$24)`), looping until the flag word clears.

What is **not** verified: the card-side consumer. The kernel (`Hand`/`Boot`)
never references the header region (`$4C008C00` is not touched by it), and
Antelope's `.text` has no fixed addresses, so the consumer must find the
header through data the loader gives it (its common variables, or `PublicIn`
fields), and the writer of the host flag word `+$10` (which is in host RAM)
must be the card as a bus master or the driver's interrupt path; neither was
located. The 106 command codes (`+$48`) and parameter layouts are in
`gc24.s`'s dispatch table; matching them to Antelope's dispatcher is the next
step, and needs Antelope's `Code` stub decoded first.
