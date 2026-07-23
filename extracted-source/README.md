# Macintosh Display Card 8•24 GC — NuBus ROM analysis

Reverse-engineered source for the declaration ROM of Apple's **Macintosh
Display Card 8•24 GC** (1990).

* ROM image: `341-0812.bin` — 32 KiB EPROM dump
* Apple part number (from the ROM's own VendorInfo): **341-0812-02**
* ROM revision string: **"MDC 8•24 GC 1.0"**, © Apple Computer, Inc. 1989–1990
* Declared length `$6000` (24 KiB); data lives in the top 24 KiB (`$2000‥$7FFF`),
  the low 8 KiB is blank.

## What this ROM is (and is not)

The 8•24 GC is a two-part card (see *develop* issue 3, July 1990, "8•24 GC:
The Naked Truth", by Guillermo Ortiz, included as a PDF in the parent folder):

```
        DRAM (≤8 MB)        VRAM (2 MB)
             │                   │
   ┌─────────┴───────┐   ┌───────┴────────┐
   │  Am29000 RISC   │   │  MFB frame-     │      AC842 custom chip
   │  @30 MHz, 22MIPS│───│  buffer ctrl /  │──────(3× DAC + 3× 256-entry
   │  +64K SRAM cache│   │  Am29000 MMU    │       colour tables)
   └─────────────────┘   └────────────────┘             │
             │                   │                    Video
        ┌────┴─────┐        ┌────┴─────┐             connector
        │  RDNC    │        │Config ROM│
        │ NuBus    │        │(this ROM)│      Programmable pixel clock
        │controller│        └──────────┘
        └────┬─────┘
          NuBus
```

The **Am29000 graphics-accelerator firmware ("QuickDraw GC") is *not* in this
ROM** — it is loaded from disk at boot. What this 32 KiB configuration ROM
actually contains is the **68020 host-side software**, exactly as the article
states ("the Configuration ROM… carries the initialization software (Primary
and Secondary Inits) and holds the card's driver"):

1. the NuBus **declaration structure** (Slot Manager sResources);
2. a **PrimaryInit** — brings the board's registers up and senses the monitor;
3. a **SecondaryInit** — enables the accelerator path if 32-Bit QuickDraw is present;
4. the **`.Display_Video_Apple_MDCGC` video driver** — a textbook Slot-Manager
   video driver (Open / Control / Status / Close) that drives the framebuffer
   directly (the "glorified display card" fallback the article describes).

## ROM memory map

| Range | Contents |
|-------|----------|
| `$0000‥$1FFF` | unused (blank) |
| `$2000` | top-level sResource directory |
| `$2048` | Board sResource (name, inits, vendor info, monitor table) |
| `$2098‥$2EF3` | **PrimaryInit** sExecBlock (68020, code `$20A4‥$29E6` + data) |
| `$2EF4` | VendorInfo (copyright / revision / part number) |
| `$2F44‥$30F3` | **SecondaryInit** sExecBlock (68020) |
| `$30F4` | monitor-name / sense-code table (board id `$41`) |
| `$322C‥$353F` | the sixteen functional (video) sResources |
| `$358C` | **DRVR** `.Display_Video_Apple_MDCGC` (flags `$4C00`, len `$2E5A`) |
| `$35C0‥$52ED` | driver data tables (mode timing, gamma, CLUT ramps) |
| `$52EE‥$63BF` | **driver code** (Open/Control/Status/Close + subroutines) |
| `$63E6‥$77FF` | sResource shared data (VPBlocks, mode names, gamma tables) |
| `$7FEC` | format block (directory offset, length, CRC, `$5A932BC7`, byte lanes `$E1`) |

## The card's register banks (as used by the code)

The board lives in NuBus super-slot space (base `$s000'0000`, `s` = slot).
The code switches to 32-bit addressing with `_SwapMMUMode` before every access.
The banks used by the code (all reached as `base + offset`):

| Address | Bank | Notes |
|---------|------|-------|
| `base + $0400'00xx` | MFB control registers | `$44`,`$48`,`$4C` = the three **monitor SENSE lines** (read 1 bit each via `bfextu`); `$2C`/`$30`/`$34` drive them for extended sense |
| `base + $0440'00xx` | MFB interrupt registers | `$48` IRQ flag, `$3C` IRQ clear, `$01C0` video-sync status |
| `base + $0480'0000` | clock-synth serial port | pixel-clock / AC842 coefficients shifted in bit-serially |
| `base + $04C0'0000` | control serial port | mode / interrupt strobing |
| `base + $06C0'0000/04` | **AC842** CLUT address / data (R,G,B) port | written by SetEntries / SetGamma |
| `base + $0680'0000` | clock/timing coefficient RAM | per-mode timing loaded on SetMode |
| `base + $0C00'0000` | **VRAM / framebuffer** | page base `+$10000` or `+$11400` by depth |
| `base + $0C00'7300` | **MFB / Am29000 parameter block** | 68k↔coprocessor handshake (gated by a `'WY1\`'` signature at `+$18`) |

## Monitor sensing

Both the driver's Open and PrimaryInit read the three sense lines
(`$44`/`$48`/`$4C`) and combine them into a 3-bit code. Code `7` (all high)
triggers **extended sense**, driving the sense lines actively (`sub_62F6`) to
distinguish the newer monitors. The ROM's own name/sense table:

| sense | monitor |
|:-----:|---------|
| 0 | Mac II High-Res (13", 640×480) |
| 1 | NTSC Display, 512×384 |
| 2 | NTSC Display, 640×480 |
| 3 | Mac II Portrait |
| 4 | Mac II Two-Page Mono |
| 5 | Mac II Medium-Res |
| 6 | PAL Display, 640×480 |
| 7 | PAL Display, 768×576 |

## The video driver

Standard Slot-Manager video driver. Control and Status dispatch on `csCode`
(ParamBlock `+$1A`) through word-offset jump tables at `$556A` and `$5B18`:

| csCode | Control | Status |
|:------:|---------|--------|
| 0 | Reset | — |
| 1 | KillIO | — |
| 2 | SetMode | GetMode |
| 3 | SetEntries | GetEntries |
| 4 | SetGamma | GetPages |
| 5 | GrayPage | GetBaseAddr |
| 6 | SetGray | GetGray |
| 7 | SetInterrupt | GetInterrupt |
| 8 | DirectSetEntries | GetGamma |
| 9 | SetDefaultMode | GetDefaultMode |
| 10 | — | GetCurMode |

`SetInterrupt` installs a slot VBL task (`_SIntInstall`, handler at `$62BA`);
`Open` allocates its dCtlStorage low in the system heap with the classic
`_ReserveMem` + `_NewHandle,SYS,CLEAR` idiom.

## Files

| File | Description |
|------|-------------|
| `declaration-rom.md` | complete decoded Slot-Manager declaration structure |
| `PrimaryInit.s` | commented 68020 disassembly of the PrimaryInit |
| `SecondaryInit.s` | commented 68020 disassembly of the SecondaryInit |
| `VideoDriver.s` | commented 68020 disassembly of the video driver |

Each `.s` file carries per-routine header blocks (purpose, entry registers,
structure layouts), block comments at each logical step, and inline notes
resolving traps, Slot-Manager selectors, card-register regions and the
`csCode` jump tables.

## Source correspondence (System 7.1)

This ROM's driver is `.Display_Video_Apple_MDCGC` — the **GC variant of
`.Display_Video_Apple_MDC`**, whose *actual source* is in the System 7.1
release: `Drivers/Video/JMFBDriver.a` + `JMFBDepVideoEqu.a`. The source
**confirms the reverse-engineering exactly** (identical driver flags `$4C00`,
the gray-fill patterns `$AAAAAAAA/$CCCCCCCC/$F0F0F0F0/$FF00FF00`, the GFlags bit
layout, the drive-one-read-the-others extended-sense scheme) and supplies the
**real routine names** now used in `VideoDriver.s`:

| disassembly | source name |
|-------------|-------------|
| `VideoOpen` / `VideoCtl` / `VideoStatus` / `VideoClose` | driver bottleneck routines |
| `ChkMode` / `ChkPage` | mode / page validation |
| `JMFBSetDepth` | program the frame-buffer controller + pixel clock |
| `GrayScreen` / `GrayPatterns` | 50%-gray fill + per-depth patterns |
| `XtdSense` | extended monitor sense |
| `GoIODone` | driver IODone tail |

The GC is a hardware *variant* (Am29000 + MFB + AC842 at different register
offsets than the JMFB's Endeavor/Stopwatch/CLUT), so field offsets differ, but
the driver logic and names carry over.

## Method & caveats

* Structure parsed directly from the ROM; 68020 code disassembled with Capstone
  via a recursive-descent + linear-sweep pass, then annotated (Toolbox/OS trap
  names, Slot-Manager selectors, `csCode` handlers, register offsets, jump
  tables). Byte columns are literal ROM bytes; **mnemonics are exact**, comments
  and labels are analytical.
* A-trap names come from Apple's own `CIncludes/Traps.h` (System 7.1
  interfaces), so every trap in the three listings resolves — including the two
  video-specific ones both Inits use, `$A080` `_GetVideoDefault` and `$A081`
  `_SetVideoDefault` (read/write the card's saved default mode).
* These are *reconstructions* for study — assembling them back to a
  byte-identical ROM would need the original macros, the data tables, and the
  declaration-ROM layout tooling.
