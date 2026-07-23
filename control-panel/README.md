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
| `DRVR` -4048 | 18 K | 68k | **`.GraphAccel`** — low-level accelerator driver (this folder's `DRVR.s`; *not* a video driver, see below) |
| `INIT` -4048 | 3.4 K | 68k | **`'8•24 GC'`** — boot-time handshake with `.GraphAccel` (`INIT_main.s`) |
| `INIT` -4080 | 1.5 K | 68k | **`'DSInit'`** — finds/reconciles every 8•24 GC card by slot (`INIT_DSInit.s`) |
| `CODE` -4048 | 548 B | 68k | cdev main-segment stub |
| **`ACEF` 100** | **322 K** | **Am29000** | the main **"QuickDraw GC" accelerator firmware** |
| `ACEF` 1 | 18 K | Am29000 | smaller Am29000 image (bootstrap/secondary) |
| `mntr` `card` `gc70` `Gama` `PupS` | small | data | monitor/card tables, gamma, popup config |
| `cicn` `icl8` `ICN#` `STR#` `DITL` … | — | data | icons, strings, dialog items |

The `ACEF` blobs carry a plaintext "© Copyright Apple Computer, 1990" header
then a high-entropy body (7.2–7.4 bits/byte) — i.e. the Am29000 image is
**packed/encoded**, unpacked by `ACEFLoad` — a routine both `gc24.s` and
`DRVR.s` carry their own copy of (see `LoadFirmware` in `DRVR.s`) — and
downloaded into the card's DRAM. (`ACEF` ≈ the accelerator-executable
container; the string table literally names the loader "ACEFLoad".)

## How the pieces cooperate

```
   boot  ──▶  INIT -4048 ('8•24 GC')       INIT -4080 ('DSInit')
                 │ opens .GraphAccel by       │ scans every NuBus slot for
                 │ name, drives a short       │ 8•24-GC-family cards, skips
                 │ Control/Status handshake,  │ mono ones, reconciles the
                 │ posts a boot chime, closes │ non-accelerator ones as
                 │ the driver again           │ plain Color QD devices
                 ▼                            ▼
             DRVR  (.GraphAccel, the low-level accelerator driver — owns the
                    engine-globals struct, installs the QuickDraw patches
                    (InstallPatches), can itself run ACEFLoad)
                 │
                 ▼
             gc24  (68k accelerator engine)  ◀──▶  Am29000 firmware (ACEF)
                 │  patches QuickDraw bottlenecks to route drawing to the card
                 ▲
   user  ──▶  cdev (control panel)  — depth / gray / monitor / gamma UI,
                                       status + error reporting
```

Note this is **not** a video driver — the card still displays pixels through
the ROM's own `.Display_Video_Apple_MDCGC` (`../extracted-source/VideoDriver.s`),
the "glorified display card" fallback. `.GraphAccel` is a purely
QuickDraw-acceleration-side driver: it owns the private "engine globals"
struct gc24.s reaches via `[$888]`, installs the bottleneck patches, and
answers a family of custom Status calls that just read fields back out of
that struct.

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

## The .GraphAccel driver (`DRVR.s`)

18,470-byte 68020 `DRVR` resource, fully disassembled (every byte from the
Pascal name onward accounted for and verified byte-exact against the
original; every A-trap resolved bar one stray data byte). Standard classic
Device Manager driver shape — `pea handler ; bra CommonDispatch` vectors for
Open/Prime/Control/Status/Close, called with **A0 = DCE**
(`dCtlStorage`+`$14` = a Handle to this driver's own private "engine
globals" struct, `$BAA`/2986 bytes) and **A1 = ParamBlock**
(`csCode`+`$1A`, `csParam`+`$1C` — the standard `CntrlParam` offsets).

* **`DoOpen`** — allocates+locks the engine-globals struct, initialises it
  (including setting globals+`$AA6` = `$FFFF`, the *same field offset*
  `gc24.s`'s `StoreCtxWord_AA6` writes — strong evidence the two share a
  struct convention), and calls `InstallPatches`.
* **`InstallPatches`** — walks a 128-slot trap-patch table
  (globals+`$278`) and, for each active entry, swaps in the accelerator's
  replacement via `_Get/SetToolTrapAddress` / `_Get/SetOSTrapAddress` — the
  actual **QuickDraw-bottleneck patch installer**.
* **`DoStatus`** — a 53-way `csCode`-indexed dispatcher; ~18 implemented
  selectors are simple getters (`return globals+$XXX`), named
  `Sts_GetField_XXX` after the field they read since Apple's real selector
  names aren't recoverable from the binary. One (`Sts_InvokeHook3`, csCode
  54) instead calls a client-installable callback stored in the globals'
  8-slot hook table.
* **`DoControl`** — validates a `csParam` index against the engine globals,
  and (via `LoadFirmware`) can itself run **`ACEFLoad`** — this driver
  carries its *own* copy of the Am29000-COFF loader (checking the same
  `0x12A`/`0x12B` magic as `gc24.s`'s copy), so firmware loading isn't
  gc24-exclusive.
* **`DoClose`** — a no-op stub (the driver expects to stay resident).
* Two smaller 35-case dispatch tables (index×6 into 6-byte records) are
  identified and rendered structurally but not deep-dived case-by-case.

## The two boot-time INITs

### `INIT_main.s` — the `'8•24 GC'` INIT (id `-4048`)

A one-shot boot-time handshake, *not* a resident client — it never touches
hardware directly (no `_SlotManager`/`_HWPriv`/`Set*TrapAddress` calls
anywhere in the file, unlike `DRVR.s`/`gc24.s`). Fully traced control flow:

1. `_GetKeys`, then a boot-icon/identity check (`ShowIconOrAlert`) that must
   return a fixed sentinel (`$D8EF`) to continue.
2. Probes whether Toolbox trap `$A8B5` (`_ScriptUtil` per Apple's `Traps.h`)
   is implemented; two more calls to it most plausibly fetch the current
   script/language code, used as `1000+code` to pick a **localised `STR#`
   resource** — the same `STR#1000..` family inventoried above.
3. Loads that `STR#` list plus a `STR` resource holding the product's
   display name, builds `productName + separator + pickedMessage` via two
   recovered utility routines (`PLStrCpy`/`PLStrCat`, Pascal string
   copy/concat with the classic 255-byte cap), and posts it as a
   **Notification Manager alert** (`NMInstall`) — the boot-time "product
   ready" chime. The picked-message index is clamped to 0 or 1, plausibly
   *monitor attached* vs. *not attached* (the develop article notes the
   8•24 GC, unlike its plain 8•24 sibling, stays active with no monitor).
4. **`OpenDriverByName('.GraphAccel', &refNum)`** — opens the very driver
   disassembled above, by name, via a hand-rolled `_Open` call (same
   pattern for `_Control`/`_Status`/`_Close`: `ControlDriverSync`,
   `StatusDriverSync`, `CloseDriverSync` — minimal inline
   `PBControlSync`/`PBStatusSync`/`PBCloseSync` equivalents).
5. Drives a short, hard-coded `Control`/`Status` handshake against it,
   branching on the results, then shows the success or error alert variant
   and **closes the driver again** — confirming this INIT only performs a
   one-time boot-time check/handshake.

Also recovers two more embedded MacsBug symbols beyond `p2cstr`/`c2pstr`
(shared with other 68k modules in this project): `PLStrCat`, `PLStrCpy`.

### `INIT_DSInit.s` — `'DSInit'` (id `-4080`)

Much smaller (1552 bytes; the first `$446` bytes are unreached constant
data — an unconditional `bra` at the very start jumps straight past them).
Unlike the main INIT, this one talks to the **Slot Manager directly**: after
gating on Color QuickDraw + System 7-class environment checks, it walks
**every NuBus slot** with a stack-allocated `SpBlock` (the exact same
`spCategory`/`spCType`/`spDrvrSW`/`spDrvrHW=$1D` identity used throughout
this project's ROM and `DRVR.s`) looking for **every 8•24 GC-family card**,
not just the accelerator — skipping any whose driver reports
`GFlags.MonoFlag` set (the exact bit position documented in
`../extracted-source/VideoDriver.s`) and cross-checking a driver-name
literal. This lines up precisely with the develop article's description of
multi-card behaviour: *"you can have as many 8•24 GC boards as you want...
only one will function as a graphics accelerator; any other becomes a
glorified display card"* — `DSInit` is very plausibly the code that finds
and reconciles those "other" cards as ordinary Color QuickDraw devices
(via a `'scrn'` calibration-resource lookup and an unidentified OS trap,
`$A204`, not present in Apple's published `Traps.h`).

## Status / what's next

Delivered: the resource map, the 68k/Am29000 split, the commented **`cdev`**,
the fully-disassembled **`gc24`** engine, the unpacked **`ACEF`** Am29000
firmware, the fully-disassembled **`.GraphAccel`** (`DRVR`), and both
boot-time **`INIT`**s. Remaining, on request:

* **Am29000 disassembly depth** — `am29k_dasm.py` lifts `ACEF_100`'s `.text`
  cleanly (see [`firmware/`](firmware/)), but individual functions aren't
  named/commented yet (COFF relocations aren't applied either).
* A few smaller helpers in `INIT_main.s` (the icon/alert plumbing under
  `ShowIconOrAlert`) and the unidentified `$A204` trap in `INIT_DSInit.s`
  aren't traced further — flagged honestly in each file rather than guessed.
