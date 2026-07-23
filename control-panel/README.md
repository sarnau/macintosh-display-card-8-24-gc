# Macintosh Display Card 8•24 GC — control-panel software (v7.0.1)

Analysis of the **`8•24 GC` control panel** and its companion resources, from
`8•24 GC SW 7.0.1 (for System 7)`. This is the disk-side software that pairs
with the NuBus declaration ROM analysed in `../extracted-source/` — and it
contains the piece the ROM does **not**: the Am29000 accelerator firmware.

## Resource inventory (`824GC.rsrc`, 452 KB)

Two worlds — 68k host code and Am29000 coprocessor code:

| Resource | Size | CPU | Role |
|----------|------|-----|------|
| `cdev` -4064 | 7.7 K | 68k | the control-panel UI (this folder's `cdev.s`) |
| `gc24` -4048 | 48 K | 68k | host-side **QuickDraw GC accelerator engine** (this folder's `gc24.s`) |
| `gc24` 32 | 2.7 K | 68k | secondary engine code |
| `DRVR` -4048 | 18 K | 68k | disk-based `.Display_Video` driver (supersedes the ROM's) |
| `INIT` -4048 / -4080 | 5 K | 68k | boot-time loaders (`ACEFLoad` — download firmware to the card) |
| `CODE` -4048 | 548 B | 68k | cdev main-segment stub |
| **`ACEF` 100** | **322 K** | **Am29000** | the main **"QuickDraw GC" accelerator firmware** |
| `ACEF` 1 | 18 K | Am29000 | smaller Am29000 image (bootstrap/secondary) |
| `mntr` `card` `gc70` `Gama` `PupS` | small | data | monitor/card tables, gamma, popup config |
| `cicn` `icl8` `ICN#` `STR#` `DITL` … | — | data | icons, strings, dialog items |

The `ACEF` blobs carry a plaintext "© Copyright Apple Computer, 1990" header
then a high-entropy body (7.2–7.4 bits/byte) — i.e. the Am29000 image is
**packed/encoded**, unpacked by `ACEFLoad` in the 68k `INIT`/`gc24` code and
downloaded into the card's DRAM. (`ACEF` ≈ the accelerator-executable container;
the string table literally names the loader "ACEFLoad".)

## How the pieces cooperate

```
   boot  ──▶  INIT (-4048/-4080)
                 │ checks environment, then ACEFLoad:
                 │  unpack ACEF 100/1  ──▶  download to card DRAM  ──▶  Am29000 runs
                 ▼
             gc24  (68k accelerator engine)  ◀──▶  Am29000 firmware (ACEF)
                 │  patches QuickDraw bottlenecks to route drawing to the card
                 ▼
             DRVR  (.Display_Video, the on-disk video driver)
                 ▲
   user  ──▶  cdev (control panel)  — depth / gray / monitor / gamma UI,
                                       status + error reporting
```

The ROM's own video driver (`../extracted-source/VideoDriver.s`) is the
"glorified display card" fallback; this software layers the Am29000
acceleration on top of it.

## The cdev (`cdev.s`)

A standard System-7 Control Panel device, compiled from C, dispatched on the
message word:

| message | handler | does |
|--------:|---------|------|
| 8 macDev | (inline) | returns 1 = "cdev can run on this machine" |
| 0 initDev | `msg_initDev` | allocate ~106-byte state, read card status, fill dialog items |
| 1 hitDev | `msg_hitDev` | handle clicks — depth radios, gray checkbox, monitor/gamma popups |
| 2 closeDev | `msg_closeDev` | dispose state |
| 4 updateDev | `msg_updateDev` | draw the monitor preview + colour swatches |
| 3,5,6,7 | `msg_nulDev` | no-op |

`cdev.s` is fully disassembled (2619 instructions, 99.7 % covered), with every
A-trap resolved from Apple's `Traps.h`, the message jump table decoded, and
routine headers on each handler.

## Diagnostic string table (`STR#` 1000) — what the software checks/does

These read like a spec of the whole stack (`^3` = "Macintosh Display Card 8•24 GC"):

```
 2  System 7.0 or later required.
 3  32-Bit QuickDraw is not installed.
 4  No display is connected to the card.
 5  At least three megabytes of memory are required.
 6  The ^3 card is not installed.
 7  A hardware error has been detected on the ^3 card.
 9  There is a problem with the DRAM expansion memory on the ^3 card.
10  Only one of the ^3 cards in your system will be used.
11  Please restart your Macintosh to install the ^3 software.
12  Graphics Accelerator is having difficulty.  You will need to reboot …
13  The acceleration software is not recommended on 68040 systems.
14  Your CPU may need to be upgraded to work with this board.
15  The video config ROM on your board needs to be updated.
16  Board does not yet work with Macintosh Virtual Memory turned on.
18  The video config ROM is out of date.
19  Runtime kernel is out of date.
20  Graphics software is out of date.
21  ACEFLoad failed.
```

Note lines 15/18 — the "video config ROM" they refer to is exactly the
`341-0812` declaration ROM disassembled in `../extracted-source/`.

## The gc24 accelerator engine (`gc24.s`)

48 KB of 68020, fully disassembled (15 872 instructions, 100 % of bytes
accounted for, every A-trap resolved, all 7 compiler switch-tables and the
data tables decoded). Structure:

* **`$0000..$13E3` — dispatch table**, 106 entries × `$30` bytes. Each entry is
  a self-contained patch stub:
  * `+$00  dc.l` — the **Am29000 command code / firmware offset** for this op
  * `+$04` — a stub that fetches the engine's globals through low-memory
    `[$888]` and tail-jumps through them (`GlobalsAccessor`)
  * `+$28  bra.l handler_NN` — the 68k handler
  These are the patched QuickDraw/CQD bottlenecks and related entry points; the
  106 command codes are the host→coprocessor opcodes.
* **`$13E4..$C27C` — handler + engine code.** Each handler marshals its
  arguments into a command packet and appends it to the card's command queue.
  The parameter copy is a classic **Duff's-device unrolled loop** — a `switch`
  on the argument count jumps into a chain of `move.l (params)+,(queue)+`.
* **`$C09C` — `GestaltSelectorTable`**: the engine probes the environment via
  Gestalt (`vers mach sysv proc fpu qd kbd atlk mmu dram lram`) to decide
  whether/how to accelerate (matching the "requires 32-Bit QuickDraw / 3 MB /
  68040 caveat" strings above).

* **`ACEFLoad` (`$23B6`)** — gc24 *contains the relocating loader* for the
  Am29000 firmware. Its embedded log strings spell out the **ACEF object
  format**: a magic number, sections (incl. `.BSS`), a symbol table, and
  absolute/relative branch-target relocations ("Loading %d sections", "Not in
  ACEF format!", "…Branch Target … Out of Range…", "Load Complete."). So the
  high-entropy `ACEF` resources are *relocatable Am29000 object code*, not
  encrypted — and the code that parses them is right here.

### Labels

`gc24.s` names its infrastructure by inspection (GlobalsAccessor, Strip24,
EngineDispatch, StoreCtxWord_AA6, CopyParamsToQueue, HWPrivProbe,
GestaltSelectorTable, ACEFLoad) and recovers a dozen leaf-routine names from
the **MacsBug symbols the compiler embedded after each function** (`GA_MoveHHi`,
`FixScale`, `GetD2`, `SetD2`, `GetA5`, `GACursorTask`, `GA_PMGR`,
`GA_GETCTSEED`, `BitFieldExtract`, `EqualFontOutput`, `WidthTableCheckSum`).
The 106 op-handlers stay `handler_NN` (their Am29000 command code is shown in
the dispatch table). The dispatch table, switch jump-tables, Gestalt table and
embedded strings/symbols render as structured data; everything else is code.

## Status / what's next

Delivered: the resource map, the 68k/Am29000 split, the commented **`cdev`**,
and the fully-disassembled **`gc24`** engine. **Not yet done** (on request):

* **`ACEF` Am29000 firmware — DONE.** Reversed the `ACEFLoad` loaders and
  unpacked both resources; see [`firmware/`](firmware/) and
  [`acef_unpack.py`](acef_unpack.py). ACEF is obfuscated Am29000 COFF (one XOR
  key byte); the unpacked `.text` is verified Am29000 code (62,134
  instructions). `ACEF_100` = "32-Bit Antelope" accelerator, `ACEF_1` =
  "Runtime" kernel (whose `VidComm` section sits at `0x4C007300` — the same
  command block the ROM's video driver pokes). Remaining: an Am29000
  disassembler to lift the code (no stock Capstone/Ghidra support).
* **`DRVR` -4048 (18 K)** — the on-disk `.Display_Video` driver; same toolchain.
  (Contains the dual-magic `ACEFLoad` used above.)
