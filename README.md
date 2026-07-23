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
