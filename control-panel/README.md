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
`DRVR.s` carry their own copy of (see `LoadFirmware` in `DRVR.s`). (`ACEF` ≈
the accelerator-executable container; the string table literally names the
loader "ACEFLoad".)

`ACEFLoad`'s own embedded debug strings spell out the load mechanism
directly: for each section it logs an "Address" and either `BlockMove`s the
raw bytes there or zero-fills it (`.bss`), validating/patching branch
targets as it goes — the live counterpart of this project's offline COFF-
relocation work (see `firmware/README.md`), able to resolve external
symbols the offline analysis couldn't since it has the real load address.
The destination pointer is `Strip24`'d (`StripAddress`) first, the same
hygiene classic Mac OS applies to any hardware pointer — meaning the
Am29000's program/data memory is directly memory-mapped into the card's
NuBus slot space, and firmware is written there with plain
`BlockMove`/`move.l`, not shuttled through the separate command-queue
mechanism `gc24` uses for ordinary QuickDraw commands at runtime.

**What happens around the load, traced in `DRVR.s`** (`MakeSuperslotAddr` is
the NuBus super-slot address builder and `PokeHardwareLong` a
`_SwapMMUMode`-bracketed aligned longword write — both confirmed by decoding
their bodies). There are two loaders, not one:

* **`Init29K` (`$23CC`, DoControl cs2)** brings the card up from scratch.
  Only card types `$2C`/`$7E` (the GC) are touched. It writes 0 to hardware
  register `$04000028`, pattern-tests the card's 128 KB SRAM, probes the DRAM
  banks at `$0C000000`/`$0D000000` in 1 MB steps (top of RAM → unit `+$138`),
  then runs `ACEFLoad` on the **Runtime** ACEF. `ACEFLoad` special-cases the
  section named `PublicIn`: the out-parameter it returns (unit `+$130`) is
  that section's host-visible address. `Init29K` then reads **image+$400**
  and checks for `$32100456` — a constant that is the first word of the
  *uploaded* Runtime's **`PublicOu`** section (so it proves the upload landed, not that
  the card booted; the real card-ready handshake is `Boot` waiting for `$42005300`) (`PublicIn`+`$400`), so the "image" the
  host pokes is the `PublicIn`/`PublicOu` pair at card `0x4C006400/0x4C006800`.
  It writes `+$18` (feature flags), `+$00` (`$42005300`), `+$08` (top of
  DRAM) and `+$14` (engine region), then reads the card's **mailbox address**
  from `+$40C`, stores the host ack-word address at mailbox`+$0C` and the
  `'s337'` signature at mailbox`+$00` to open it (cs51 later sends payloads
  through it: payload at `+$08`, then `'s337'`).
* **`LoadFirmware` (`$2926`, cs3)** loads the second ACEF (**Antelope**) with
  the same `ACEFLoad`, then writes four longwords into the same header
  (`+$18` flags, `+$0C` ACEFLoad's return value as a card address, `+$04` its
  out-parameter, `+$40` the engine RAM region) and sets the software
  "firmware loaded" bit. The kick-off is not on the 68k side:
  the card's kernel init jumps to the entry stored at `+$04` (it ends with
  `PC1 <- [PublicIn+4]; iretinv`), and init is re-run by `PostLoadPoke` (restart
  word `+$3D4` plus the `$04000050` doorbell) -- see
  [`HOST_CARD_PROTOCOL.md`](HOST_CARD_PROTOCOL.md).

ACEFLoad's own message strings (now correctly decoded as data) confirm the
ACEF layout: `Program '%s' version %08x date %d` (optional header `+$1C`
name, `+$14` version, `+$18` date), the 32-text-section limit, "multiple
.BSS not allowed", and the relocation range errors. `DRVR.s` documents the
whole 1 KB-per-slot **unit record** (`BuildUnitRecords`, `$1E4A`) field by
field. An earlier version of this README said `+$0C` was "built from the ACEF
magic byte's low nibble"; that was a misreading.

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
(via a `'scrn'` calibration-resource lookup and two standard video-driver
`_Control` calls — `$A204`, confirmed identical to `_Control`/`$A004` by
tracing Apple's own live trap dispatcher — `cscSetGamma` (csCode 4) then
`cscSetEntries` (csCode 3), sent to the slot's ROM video driver; the record
layouts match `extracted-source/VideoDriver.s` exactly, see `INIT_DSInit.s`).
An earlier revision of this README called them private selectors of
`.GraphAccel`; that was wrong — `DoControl`'s csCode 3/4 there are
`LoadFirmware` and a field setter.

`.GraphAccel`'s own `DoControl` csCode map (InitAccel, LoadFirmware,
Enable/DisableAccel, a mailbox-send to the Am29000, …) is documented at the
cascade in `DRVR.s`, and `INIT_main.s`'s boot handshake is decoded against it.

## Reproducing the inputs

`../Macintosh Control Panel/824GC.rsrc` is the original resource fork.
`python3 extract_resources.py "../Macintosh Control Panel/824GC.rsrc" OUT/`
dumps `ACEF_100.bin`, `ACEF_1.bin`, `DRVR_-4048.bin`, the INITs and the cdev;
`acef_unpack.py` then unpacks the ACEFs and `apply_reloc.py` applies the
relocations (see `firmware/README.md`).

## Status / what's next

Delivered: the resource map, the 68k/Am29000 split, the commented **`cdev`**,
the fully-disassembled **`gc24`** engine, the unpacked **`ACEF`** Am29000
firmware, the fully-disassembled **`.GraphAccel`** (`DRVR`), and both
boot-time **`INIT`**s. Remaining, on request:

* **Am29000 disassembly depth** — `am29k_dasm.py` lifts `ACEF_100`'s `.text`
  cleanly (see [`firmware/`](firmware/)); COFF relocations are now decoded
  and applied where resolvable (35.7% — see `firmware/README.md`), but
  individual functions still aren't named/commented (no evidence survives
  to do so honestly — see the same file for why).
* A few smaller helpers in `INIT_main.s` (the icon/alert plumbing under
  `ShowIconOrAlert`) aren't traced further — turns out they don't need to
  be: an embedded credit block right after the function (previously
  misdecoded as garbage instructions, same artifact class as the DRVR.s
  fix below) reads `"ShowINIT by Paul Mercer / Copyright 1987-1988"` —
  this is third-party code (Paul Mercer's well-known ShowINIT utility),
  not custom Apple/vendor logic. The `$A204` trap in `INIT_DSInit.s`,
  previously flagged "unidentified" (absent even from the full internal
  System 7.1 `Traps.h`, not just the public copy), turned out not to need
  a `Traps.h` entry at all: tracing Apple's own live A-line dispatcher
  (`OS/TrapDispatcher/Dispatch.a`) shows it indexes its handler table by
  the trap word's low byte only — `$A204` and `$A004` (`_Control`)
  dispatch to the byte-identical routine, so `$A204` *is* `_Control`; the
  higher bits only matter to `GetTrapAddress`/`SetTrapAddress`'s own,
  unrelated numbering convention.
