# Macintosh Display Card 8•24 GC — Reverse Engineering

A full reverse-engineering pass over Apple's **Macintosh Display Card 8•24 GC**
(1990): its NuBus declaration ROM, its System 7 control-panel software, and
the Am29000 coprocessor firmware hidden inside that software.

The 8•24 GC pairs a plain 68k-driven framebuffer card with an on-board
**AMD Am29000 RISC coprocessor** ("QuickDraw GC") that accelerates QuickDraw
drawing by 5–30×. The two halves are covered by two independent write-ups:

## [`extracted-source/`](extracted-source/) — the NuBus declaration ROM

Annotated 68020 disassembly of `341-0812.bin`, the card's 32 KB configuration
ROM: the NuBus declaration structure, `PrimaryInit`/`SecondaryInit`, and the
`.Display_Video_Apple_MDCGC` video driver. Routine and storage-field names are
cross-referenced against Apple's System 7.1 source release (`JMFBDriver.a`,
the Slot Manager `SEBlock`/`SpBlock` layouts) where available.

→ see [`extracted-source/README.md`](extracted-source/README.md)

## [`control-panel/`](control-panel/) — the software and the Am29000 firmware

Disassembly of the `8•24 GC` control panel (`cdev`) and its `gc24` QuickDraw
accelerator engine, plus a from-scratch **ACEF unpacker** (the card's
Am29000 COFF firmware container format) and a from-scratch **Am29000
disassembler** used to lift the coprocessor's own code.

→ see [`control-panel/README.md`](control-panel/README.md)

## Where things stand

A one-page summary of how the card works: [`HOW_IT_WORKS.md`](HOW_IT_WORKS.md).
A guide to the listings (where to start, label and address conventions):
[`READING_THE_LISTINGS.md`](READING_THE_LISTINGS.md).
What the latest round of work changed: [`CHANGES.md`](CHANGES.md).


* **Host side (68k): fully decoded** -- the declaration ROM, the control panel,
  the `gc24` engine, the `.GraphAccel` driver and both INITs.
* **Card firmware: fully decrypted.** The firmware's encryption is a running
  32-bit XOR key that the host's driver removes while loading it
  (`DRVR` `ACEFLoad`); `acef_unpack.py` does the same, so every section of both
  firmware programs, in both software releases, is exact plaintext. Earlier
  this was modelled for months as a "second mask"
  ([`control-panel/SECOND_MASK.md`](control-panel/SECOND_MASK.md)).
* **The kernel (`Runtime`: `Boot` + `Hand`)** is disassembled with a reading
  guide and its service table (`control-panel/firmware/`). Its host-visible
  protocol (boot handshake, flags, restart, mailbox, video command block,
  the command packet) is written down and cross-checked on both sides
  in [`control-panel/HOST_CARD_PROTOCOL.md`](control-panel/HOST_CARD_PROTOCOL.md).
* **The 243 KB QuickDraw accelerator (`Antelope`)** has an exact, labelled
  disassembly. The command dispatcher, drawing stream, caches, cursor
  handling, StretchBits, the System 6 `'rpza'` codec and a self-test are
  read. See `control-panel/HOST_CARD_PROTOCOL.md` and `control-panel/firmware/`.
* **The hardware as the software sees it:** the card's registers (display
  start, row stride, the Am29000's run control, interrupts, the timing
  generator), the RAMDAC, the DP8531 pixel-clock synthesiser and every video
  mode's timing are mapped (`HOST_CARD_PROTOCOL.md` section 10).

## Open questions

Everything else is read from exact code. These are what the software alone
does not settle (details in
[`control-panel/HOST_CARD_PROTOCOL.md`](control-panel/HOST_CARD_PROTOCOL.md)):

* **Reset to `Boot`.** After reset the Am29000 fetches address 0 in ROM
  space; nothing in the code jumps to `Boot` at `$2003000`, so the custom
  chips most likely supply the jump. Whether `$44000028` is the *RESET line
  is a strong reading, not proven (§1).
* **SRAM aliasing.** That the host's slot offsets 0 (RAM test) and
  `$02000000` (kernel) are the same 64 KB SRAM is inferred (§1).
* **The `$44800000` stream.** 137 bits PrimaryInit shifts into most likely a
  configuration chain inside the MFB; no field is decoded (§10.3).
* **RAMDAC bit 31.** Always set in the pixel bus control byte; its meaning
  is unknown (§10.8).
* **Glyphs `$84`-`$9E`.** Which host system rewrites them in non-Roman fonts
  so that the card re-reads them; KanjiTalk 6 is the best fit (DrawMultiObject).
* **The cursor copy.** Whether the card's never-refreshed copy of the screen
  under the cursor can really show stale pixels (§ "The cursor").
* **Debug tools.** Who used the mailbox calls (Status cs15/16, Control
  cs50/51) and the kernel's debug flag bits; no such tool has been found (§4, §8).
* **Cheetah.** The second board name the driver accepts; unidentified (§1).
* **Board markings.** The MFB's exact part number, the VRAM's last digit,
  the PAL, the ECL parts and the third oscillator are illegible in the photo.

## Bugs and slips in the shipping software

Found while reading the code; each is explained, with its evidence, in
[`control-panel/HOST_CARD_PROTOCOL.md`](control-panel/HOST_CARD_PROTOCOL.md)
(section in brackets). None of them shows in normal use as far as the code
tells.

| where | what | effect |
|---|---|---|
| `gc24` `$765E` (System 7) | when the host gives up on the card, the loop that restores the original trap addresses indexes `$14(a4,d7.l)` with `d7` counting by 1, not 4 (§8) | only the first patch is restored; the alert asks for a restart anyway |
| `gc24` `$734E` | the retry for the DrawMultiObject buffer subtracts `$C8` until the size is exactly 0; from the default `$1000` it wraps past 0 (§8) | would spin instead of giving up |
| `gc24` `$6FC8` | give-up reason 6 depends on `sub_7570`, which returns 0 on every path (§8) | dead code |
| `gc24` | the give-up reason at unit `+$15C` is written but never read (§8) | none |
| `Hand` service dispatcher (both builds) | the bound check compares the service *index* with the table size, so numbers up to `$18A`/`$18B` jump through words past the table (§9, reading) | only a wrong service number would hit it |
| `Hand` `$CD` (System 6) | the error exits of "region remove" jump through `gr69`, which nothing set (§9, reading) | System 7 fixes it with a wrapper |
| `Hand` `$C6` | display start: ÷8 linear but ÷4 interleaved, where Boot scales ×8 in both; stores a halved value where Boot stores a pointer (§10.1) | no caller, so harmless |
| Antelope `rpza` decoder | a row header whose length has bit 15 set reads as a 4-colour run (§9) | latent; the card's own encoder never writes one |
| Antelope `'rle '` encoder `$3A8BC` (System 6) | the repeat-line test compares `lenLongs` *bytes*, a quarter of the line (§9) | a line can be dropped as a repeat when only its first quarter matches |
| `gc24` codec `$A19A` (System 6) | Close disposes the state handle but not the dither table (§9) | leaks `$20008` bytes per 8-bit codec instance |
| Antelope TestCLUT | writes the RAMDAC index as a word, so the RAMDAC sees 0, not `$FE` (§10.5) | tests entry 0; passes either way |
| Hand service `$C1` with 8 MB of SIMMs | the free-memory value ignores Antelope and the stacks at the top of RAM (§10.9) | HeapCreate retries about 340 times, 1000 bytes smaller each time, before its request fits |
| `gc24` QDDone `$BECC` | answers TRUE at once for any port other than the one being streamed, without asking the card (§ DrawMultiObject, "When the host waits for the card") | a program that waits with QDDone before touching pixels can still race an early-released CopyBits into that port |
| `gc24` (System 6) `$4842`, `$3E3A` | the Std* fallback and BitMapRgn drain the card's drawing stream only for a pixmap the card holds, not for an ordinary port (§9) | the 68K can draw into a port while earlier stream records for it are still being drawn; System 7 drains first |
| `gc24` `$345A`-`$3474` | replays hidden-cursor calls swallowed during a card command with ShowCursor (`$804`) instead of HideCursor (`$800`) (§ "The cursor") | dormant: QuickDraw never hides the cursor in that window; a custom bitsProc would leave it shown and its shield cancelled |
| Antelope `$32C10` | restores the screen under the cursor from the card's own copy for as long as `+$1EC` is set, which only the reset path clears (§ "The cursor", *reading*) | after the cursor moves or 68K drawing under it between card draws, stale pixels could reappear |
| control panel `$134C` (System 7) | after restarting the card, the second probe treats any non-zero answer as failure (`tst`/`beq`), where the first treats 1 as success (`cmp #1`) (§9) | a card that comes back after the restart still gets error `$D8EA` |
| `gc24` `$6D1E` | hook -2 returns `d7` uninitialised when no device record exists (§9) | the driver ignores this result |
| `gc24` 32 exit `$63E` (System 6 `$61C`) | any start-up failure only closes the driver: the Gestalt function, the driver entry and the QuickDraw patches stay installed; failures inside the per-card loop leave the cursor hidden; exits before the driver is open pass an uninitialised refnum to `_Close` (§9) | a card that fails to start leaves the patches in place (they fall back to the 68K) and possibly a hidden cursor |
| `gc24` 32 (System 6) `$6E0` | the temporary-zone loader leaves BufPtr lowered if the second resource is missing (§9) | the space below BufPtr is lost until restart |
| `gc24` 32 version check | Status 17/18 versions are compared nibble by nibble, and Status 19 is never compared with `vers` (§9) | a newer card firmware such as 1.1 against 2.0 would be refused |
| `DRVR` Control 53 `$85A` | copies the caller's C string into `globals+$AAA` without a length check; 256 bytes are left before the end of the block (§4) | dormant: no program calls it |
| `DRVR` BuildUnitRecords `$1EA8` | cuts sRsrc 1's name at the first space with strchr and clears the byte it returns, without checking for NULL (§1) | a name without a space would write a 0 to address 0; the shipping name has spaces |
| `DRVR` DoOpen `$22C`/`$248` | a card record dropped there is disposed but its handle stays in `globals+$214[i]` while `i` still advances (§1) | never happens: the drop for "no display" depends on a revision test the shipping card always passes |
| declaration ROM `$70B4`, `$70F4` | two mode lists lack the `$FF` terminator and run into the B-bank lists (§10.8) | harmless: the Slot Manager takes the first match |
| declaration ROM | four unreachable TV timing tables (`$3BCA`, `$4196`, `$4762`, `$4D2E`) and two unreferenced mode lists (§10.8) | left-overs |

## How the card firmware was built

Read from the file headers, symbol tables and code (details in
[`control-panel/firmware/README.md`](control-panel/firmware/README.md),
"How the firmware was built"):

* **Tools: AMD's 29K environment.** The objects are AMD 29K COFF (`.lit`
  sections, AMD section flags), repacked by Apple into the encrypted ACEF
  container. The code follows AMD's calling convention (register stack, tag
  words, transparent millicode). AMD's HIF library and `crt0` are linked in
  verbatim; they match AMD's source as later published in newlib word for
  word. The C compiler is not GCC (GCC's a29k port emits trapping
  `multiply`/`divide` instructions that this code never uses). It is most
  likely MetaWare High C 29K, the compiler AMD offered then; no copy of it
  is known to be available.
* **Two programs.** `Runtime` (the kernel) is hand-written assembly, fully
  linked to fixed card addresses. `32-Bit Antelope` (GC QuickDraw, a C
  rewrite of 32-Bit QuickDraw) is a partially linked object of 69 object
  files (25 of Apple's C files with debug information, then the C library,
  the HIF stubs and millicode). The Mac driver links it at load time.
* **Builds.** The ACEF dates are Mac times: the System 6 package (1.1) was
  built on 1991-01-22, the System 7 package (7.0.1) on 1992-04-22, Runtime
  first and Antelope half an hour later. Both releases link the same 29
  Apple files in the same order and the same library. The System 6 build has
  an Apple Video (`'rpza'`) codec where System 7 has a module loader.
* **Names.** The program calls itself "PQDMonet" at start ("PQDMonet:
  Starting up, commblock at %X"), its command loop "MonetMain", and its
  buffer allocator "PQDAlloc". The Runtime's `PublicOut` section carries the
  credits "Special Projects Group - SEG / Hardware: Tony Masterson, Rob Pugh,
  Dean Drako / Software: Jean-Charles Mourey, Mark Krueger, Rekha Sh…" (cut
  off by the section's end).

## Rebuilding the generated files

Everything below is regenerated byte for byte from the original resource
forks (checked: the outputs equal the committed files). Run it from
`control-panel/` with Python 3 (capstone 5 is needed only for the last
step; it may live in the user site-packages, hence `-E -P` there).

```bash
S7="../Macintosh Control Panel/824GC.rsrc"
S6="../Apple 8•24 GC Software/8•24 GC SW 1.1 (for System 6)/8•24 GC SW/..namedfork/rsrc"
OUT=/tmp/gc-build; mkdir -p $OUT/r7 $OUT/r6 $OUT/boot7 $OUT/boot6 $OUT/scratch
python3 -s -E extract_resources.py "$S7" $OUT/r7 ACEF gc24
python3 -s -E extract_resources.py "$S6" $OUT/r6 ACEF gc24
# decrypt and unpack both programs of both releases
python3 -s -E acef_unpack.py $OUT/r7/ACEF_1.bin   firmware/ACEF_1_Runtime
python3 -s -E acef_unpack.py $OUT/r7/ACEF_100.bin firmware/ACEF_100_Antelope
python3 -s -E acef_unpack.py $OUT/r6/ACEF_1.bin   firmware/sw11/ACEF_1_Runtime
python3 -s -E acef_unpack.py $OUT/r6/ACEF_100.bin firmware/sw11/ACEF_100_Antelope
# listings: Antelope (text/lit/data/Code.asm) and the kernel's data (RuntimeData.asm)
python3 -s -E antelope_dasm.py $OUT/r7/ACEF_100.bin firmware/disasm
python3 -s -E antelope_dasm.py $OUT/r6/ACEF_100.bin firmware/sw11/disasm --names-from $OUT/r7/ACEF_100.bin
python3 -s -E runtime_dasm.py  $OUT/r7/ACEF_1.bin $OUT/boot7 --no-hand
python3 -s -E runtime_dasm.py  $OUT/r6/ACEF_1.bin $OUT/boot6 --no-hand
cp $OUT/boot7/RuntimeData.asm firmware/disasm/; cp $OUT/boot6/RuntimeData.asm firmware/sw11/disasm/
# relocated flat images (apply_reloc.py also rewrites the .asm files it is given: pass copies)
for v in "r7 firmware firmware/disasm" "r6 firmware/sw11 firmware/sw11/disasm"; do set -- $v
  cp $3/text.asm $3/Code.asm $3/lit.asm $3/data.asm $OUT/scratch/
  python3 -s -E apply_reloc.py $OUT/$1/ACEF_100.bin $OUT/scratch/text.asm $OUT/scratch/Code.asm \
    $OUT/scratch/lit.asm $OUT/scratch/data.asm $2/ACEF_100_Antelope/symbols.txt \
    $2/ACEF_100_Antelope/firmware_image.bin $2/ACEF_100_Antelope/firmware_image.map.txt
done
# the System 6 host patches
python3 -E -P gc24_sw11_dasm.py $OUT/r6/gc24_-4048.bin gc24_sw11_notes.py gc24_sw11.s
```

`Hand.asm` and `Boot.asm` (both releases) and the 68k listings (`gc24.s`,
`DRVR.s`, `cdev.s`, the INITs, `extracted-source/*.s`) carry hand-written
annotations and are not regenerated; `runtime_dasm.py` writes a plain
`Boot.asm` (to `$OUT/boot7` above) whose code lines equal the committed
one's. The System 6 resource fork exists only on a Mac file system (git
keeps the data fork); on a fresh clone, take it from
`Apple 8•24 GC Software.img`.

## Source material

| File | What it is |
|------|------------|
| `341-0812.bin` | the NuBus declaration ROM dump (subject of `extracted-source/`) |
| `Apple 8•24 GC Software/`, `Apple 8•24 GC Software.img` | the original control-panel software (subject of `control-panel/`) |
| `AppleMAC-DisplayCard-8.24gc.pdf` | Apple's product documentation for the card |
| `develop-03_9007_July_1990.pdf` | *develop* magazine issue 3 (July 1990), containing "8•24 GC: The Naked Truth," Apple's own technical writeup of the card |
| `Macintosh Control Panel/824GC.rsrc` | the System 7 package's resource fork (the same resources as `8•24 GC.app`'s) |
| `Macintosh Control Panel/ Macintosh Display Card 8•24 CG.jpg` | a photo of the board, used to identify the chips (DP8531, Bt RAMDAC 428, MFB, RDNC, the memories) |

Outside the repo, read for comparison (not redistributed here):

| Source | Used for |
|------|------------|
| Apple's System 7.1 source code | QuickDraw's routines (names and table order in Antelope), `JMFB*.a` for the original 8•24's timing chip and RAMDAC register names, Boot3.a's `Load8Dot24GC`, `Sys.r` (the "Tiburon" codename), the Slot Manager selectors |
| System 6.0.1-6.0.8 System files | from 6.0.5 on, their start-up patches PTCH 376 (Mac II ROM) and PTCH 1660 (IIci-class ROM) load `gc24` 32 from the file named by STR -16454 ("8•24 GC"), the System 6 counterpart of Boot3's loader |
| AMD Am29000 User's Manual (1987) and Memory Design Handbook (1992), bitsavers | the reset state and ROM/instruction spaces (section 1) |
| National DP8531 data sheet (1990), Motorola and Toshiba memory data books, bitsavers | the clock synthesiser's registers, the SRAM and VRAM parts |

## Method

Disassembly was done with Capstone (M68K) for the 68k side and a hand-written
Am29000 disassembler (opcode table ported from MAME's `am29dasm.cpp`) for the
coprocessor side. Names and structure come from three kinds of evidence,
called out inline wherever used: mechanical decoding (traps, jump tables,
struct layouts), embedded debug symbols left in the shipped binaries, and
cross-reference against Apple's own published System 7.1 source and technical
documentation.
