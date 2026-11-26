# What changed, 25-26 November 2026

A summary of the work from the exact decryption of the firmware
(`35a63a3`) onwards, grouped by topic. The commit log has the details; the
appendix of [`control-panel/HOST_CARD_PROTOCOL.md`](control-panel/HOST_CARD_PROTOCOL.md)
lists the earlier statements this work corrected.

## The firmware, exact

* The "second mask" was a running 32-bit XOR key per section, removed by the
  driver's `ACEFLoad` (`35a63a3`). Every section of both programs in both
  releases is now plaintext, and every generated listing can be rebuilt byte
  for byte from the resource forks (README, "Rebuilding the generated
  files").
* All 709 Antelope functions are named, with subsystem banners in
  `text.asm`; the System 6 kernel and Antelope are compared with System 7's
  (620 of about 770 functions identical).
* System 6's `gc24` is disassembled (`gc24_sw11.s`) and all 200 of its
  functions named, 164 after their System 7 counterparts.

## The protocol

* Command arguments always go through the pointer at `packet+$54`; only the
  host returns reply 2.
* StretchBits releases the Mac early once every pixmap it touches is on the
  card, and the next command waits for completion. The patches wait for the
  card only where 68K code is about to touch pixels; QDDone never waits.
* The error-report mailbox stays unarmed by default and nothing on the Mac
  reads it; the calls that would are used by no program found.
* Only the GC in the lowest slot is brought up; a card without a monitor can
  still accelerate.
* `gc24` 32 does the whole boot-time bring-up in both releases. System 7's
  Boot3 and the start-up patches of System 6.0.5 and later load it. The control
  panel's restart routine and the probe behind Status 10 are the same code
  in both.
* The driver's Control and Status calls, including the ones no program
  uses, are traced in both releases.

## The hardware

* The card's registers are mapped (section 10): `$44000028` is the
  Am29000's run control, `$46800000` a National DP8531 pixel-clock
  synthesiser (identified from the board photo; every mode's clock decoded),
  `$44800000` most likely a configuration chain inside the MFB, and the
  RAMDAC a Brooktree "RAMDAC 428" on data bits 31-24.
* Every video mode's timing is decoded from the declaration ROM, and the
  RAMDAC's pixel-multiplex bits explained from the original 8•24's source.
* The board's parts: 64 KB SRAM (the kernel's instruction memory, filled
  exactly), 2 MB VRAM (also the program memory on a stock card), two empty
  DRAM SIMM sockets. Where everything sits in memory is mapped for a stock
  card and with SIMMs.
* How the Am29000 gets from reset to `Boot` is narrowed with AMD's manuals
  but not settled.

## Bugs, documentation

* 26 entries of bugs and slips in the shipping software are listed in the
  README with addresses and effects, among them the give-up routine's unscaled
  restore loop, the inverted cursor replay, QDDone's answer for other
  ports, and the control panel's retry that rejects a working card.
* About 200 lines of wrong or stale comments in the 68k listings and the
  declaration-ROM sources were rewritten (only comments changed), and the protocol document's
  older sections were checked against the exact listings and renumbered.
* New: [`HOW_IT_WORKS.md`](HOW_IT_WORKS.md), a one-page overview;
  [`READING_THE_LISTINGS.md`](READING_THE_LISTINGS.md), a guide to the
  listings; the README's open questions and bug table.
