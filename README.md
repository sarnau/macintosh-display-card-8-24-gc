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
  accelerated-command queue) is written down and cross-checked on both sides
  in [`control-panel/HOST_CARD_PROTOCOL.md`](control-panel/HOST_CARD_PROTOCOL.md).
* **The 243 KB QuickDraw accelerator (`Antelope`)** has an exact, labelled
  disassembly. The command dispatcher, drawing stream, caches, cursor
  handling, StretchBits, the System 6 `'rpza'` codec and a self-test are
  read. See `control-panel/HOST_CARD_PROTOCOL.md` and `control-panel/firmware/`.

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

## Source material

| File | What it is |
|------|------------|
| `341-0812.bin` | the NuBus declaration ROM dump (subject of `extracted-source/`) |
| `Apple 8•24 GC Software/`, `Apple 8•24 GC Software.img` | the original control-panel software (subject of `control-panel/`) |
| `AppleMAC-DisplayCard-8.24gc.pdf` | Apple's product documentation for the card |
| `develop-03_9007_July_1990.pdf` | *develop* magazine issue 3 (July 1990), containing "8•24 GC: The Naked Truth," Apple's own technical writeup of the card |

## Method

Disassembly was done with Capstone (M68K) for the 68k side and a hand-written
Am29000 disassembler (opcode table ported from MAME's `am29dasm.cpp`) for the
coprocessor side. Names and structure come from three kinds of evidence,
called out inline wherever used: mechanical decoding (traps, jump tables,
struct layouts), embedded debug symbols left in the shipped binaries, and
cross-reference against Apple's own published System 7.1 source and technical
documentation.
