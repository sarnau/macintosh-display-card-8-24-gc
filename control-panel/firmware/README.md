# Am29000 firmware -- unpacked from the ACEF resources

The `ACEF` resources in the 8*24 GC control-panel software are the on-card
**Am29000 firmware**, stored in an encrypted Am29000 **COFF** format. The
host's video driver decrypts it while loading (`DRVR.s` `ACEFLoad`), and
`../acef_unpack.py` does the same. This folder holds the decrypted firmware
of both packages (System 7 here, System 6 "8•24 GC SW 1.1" in `sw11/`) and
exact disassemblies of it.

## Status at a glance

| part | state |
|---|---|
| ACEF container, encryption, relocations, symbol table | fully decoded (`../acef_unpack.py`, `../apply_reloc.py`) |
| `Runtime` (`ACEF_1`: `Hand` kernel 2,885 words, `Boot` 512 words, data sections) | exact; `disasm/Hand.asm` (annotated), `disasm/Boot.asm`, `disasm/RuntimeData.asm` (service table, `PublicIn`/`PublicOu`, `Vec`) |
| `Antelope` (`ACEF_100`, the 243 KB accelerator) | exact; `disasm/text.asm` (all 709 functions labelled and named), `lit.asm`, `data.asm`, `Code.asm` (`../antelope_dasm.py`) |
| System 6 (`sw11/`) | exact, same layout; its `Runtime` is a different kernel build (2,781 words of `Hand`) |
| host <-> card protocol | documented and cross-checked in `../HOST_CARD_PROTOCOL.md` |

Tools: `../extract_resources.py` (resource fork), `../acef_unpack.py`
(decrypt and unpack), `../apply_reloc.py` (relocations, flat image),
`../am29k_dasm.py` (Am29000 disassembler), `../runtime_dasm.py` (Runtime
listings), `../antelope_dasm.py` (Antelope listings), `../antelope_modules.py`
(object files), `../antelope_compare.py` (System 6 against System 7),
`../antelope_hif_stubs.py` (HIF stubs against AMD's source).

## The ACEF format (reverse-engineered)

```
file header (20 bytes, PLAINTEXT)
   +0  magic  u16   0x012A = plain COFF . 0x012B = obfuscated (both handled by the DRVR)
   +2  nscns  u16   number of sections
   +4  timdat u32   ; byte +7 doubles as the obfuscation KEY
   +8  symptr u32   +12 nsyms u32   +16 opthdr u16 (=68)   +18 flags u16
optional header (68 bytes @ 0x14)   XOR keystream  key(i) = (0x14 + KEY*i) & 0xFF
   program name (e.g. "32-Bit Antelope") @ +0x1C, text/data/bss sizes, version, date
[0x12B only] 64-byte copyright signature (plaintext) @ 0x58   (loader verifies it)
section headers (40 bytes each)     XOR keystream  key(i) = (fileOffset + KEY*i) & 0xFF
section raw data (@ s_scnptr)       running 32-bit key (below)
relocations / symbols               plaintext
```

The header layer uses the key byte (`timdat`'s low byte) as a running
keystream. The section data is encrypted per word with a running 32-bit key
that restarts at every section:

```
K = KEY * $01010101,  b = s_scnptr & $FF          (section start)
plain = word ^ K;  K = (K + b) mod 2^32;  b ^= K & $FF   (per word)
```

(`DRVR.s` `ACEFLoad` `$3A46`-`$3AE6`; only `size/4` words are loaded.)

## The "second mask"

Earlier versions of `acef_unpack.py` XORed the section data with `KEY`
alone, the starting value of `K`. The rest of the key looked like a second,
much harder mask, and was modelled from known plaintext for months: exact
tables for `Hand`, fitted ones for `Boot`, a partial model for Antelope.
[`../SECOND_MASK.md`](../SECOND_MASK.md) records the solution, why the
leftover looked the way it did, and what the earlier approach produced.

## `ACEF_1_Runtime/` -- "Runtime" (the Am29000 kernel)

KEY `0xBC`. 13 sections; header `symptr=0`/`nsyms=0` and every section has
`nrel=0` (pre-linked to its fixed map).

| section | vaddr | role |
|---------|------:|------|
| `Boot` | `0x2003000` | boot code (512 words) |
| `Hand` | `0x2000000` | trap/interrupt/service kernel (2,885 words) |
| `Cache` | `0x2003800` | bss (nothing is missing: the earlier "second stage" theory was a decode artefact) |
| `Vec` | `0x4C000000` | trap vector table (`VAB`); 0 in the file apart from 4 words, `Boot` fills the table |
| `PublicIn` / `PublicOu` | `0x4C006400/6800` | host -> card / card -> host fields |
| `HifComm` | `0x4C007000` | mailbox (`'s337'` / `$96666669`) |
| `VidComm` | `0x4C007300` | video command block (= ROM's `$0C007300`) |
| `InitMap` / `InpArgs` | `0x4C007400/7800` | init map / program arguments |
| `Private`, `PrivNZ`, `Apple` | `0x4C0025xx` | private state, the vector-66 service table (`PrivNZ`, 33 handlers), copyright |

### What `Boot` does

(`disasm/Boot.asm`, whose header has the details.)

1. Probes the two words at `$4400000C`/`$44000010` into a 2-bit value and
   stores it, shifted left by 28, at `$4C00682C` (`PublicOu+$2C`); sets
   `CFG = 0`, `CPS = $047F`; loads the host's flags from `PublicIn+$18` into
   `gr64`.
2. **Polls `$4C006400` (`PublicIn` word 0) until it reads `$42005300`** -- the
   value `DRVR.s`'s `Init29K` pokes to `image+$00` after uploading `Runtime` --
   then writes 0 back.
3. Copies a block described by `PublicIn+$20`-`$2C`, and puts the probed
   value into the top nibble of the four pointers at `PublicOu+$0C`-`$18`.
4. Sets `VAB = $4C000000` (the `Vec` section) and `CFG |= $10`, and **fills the
   trap vector table** with handler addresses `$0200xxxx` (`$2000000`,
   `$2000008`, `$2000908`, ... and `$2001D08` for the unused entries).
5. Reads the three hardware-ID bits at `$44000044/48/4C` (the host's
   `$0400004C/48/44`, the readiness bits `BuildUnitRecords` reads). It takes
   the board parameters from `VidComm` when that holds `'WY1`'`, or else
   probes the card registers, and stores them at `PublicOu+$1C`-`$28` (a
   configuration value `$1E0`, `$366`, `$1E6`, `$180`, `$240`, `$270` by board
   at `+$28`).
6. `jmp $2001FFC` into `Hand`'s reset/initialisation routine.

### What `Hand` contains

`disasm/Hand.asm` is the real disassembly and now carries a reading guide
(registers, vector table, reason codes, card address map) plus a banner on each
routine. In short, `Hand` is the Am29000 **runtime kernel** for the card:

* **Trap vector table.** `Boot` installs it at `VAB = $4C000000` (the `Vec`
  section): vectors 0-21 point at the handlers below, 22-63 at a default that
  reports reason `$A3`, 64/65 are the register-stack spill/fill handlers (the
  `Antelope` loader patches 293 `asgeu 64,gr1,gr126` and 454 `asleu 65,lr1,gr127`
  with exactly these vector numbers), 66 and 69 are the two **service-call**
  entry points (66 a jump table, 69 the host-interface style), 68 an
  assertion/breakpoint, 67 a default. Vectors 8/10 and 9/11 share the instruction and data **software TLB
  refill** handlers (1 KB pages, a 32-bucket hash at `$4C002818`, a region
  table at `$4C00316C`), with a pager at `$2001D10` behind them.
* **Interrupt handling.** INTR0-3 and the timer, trace and TRAP handlers
  dispatch to handler words in `$4C00617C..$4C00618C` (via `$20010A4`); the
  timer reloads `TMR` and counts ticks in `$4C006830/34`; INTR2 also runs the
  **video command service** `$2000C14`, which executes the `VidComm`
  (`$4C007300`) block. A PC trace ring lives at `$4C006A7C`.
* **Service calls.** Vector 66 dispatches `gr121 - $B6` through the table at
  `$4C002500`; vector 69 (the AMD host-interface style `asneq 69,gr1,gr1`)
  handles services such as `sbrk` (`$101`), the `InpArgs` pointer (`$104`),
  ticks and cycle time (`$111`/`$112`) and exit (`1`).
* **Fatal-trap reporter and mailbox (`$2002808`, `$2002650`).** Any
  unrecoverable trap stores a reason code (`$8F`..`$B5`, table in the file),
  dumps the register state to `$4C006748`, and calls `$2002650`, which posts
  the reason and a 16-word register dump in the `HifComm` mailbox
  (`$4C007000`: `$96666669` = posted, `$73333337` = `'s337'` = the host's
  acknowledge) and waits for the host. This is the card side of the
  `cs51`/`Init29K` mailbox in `DRVR.s`.
* **Kernel init (`$2001FFC`)**, entered from `Boot`: sets `CFG`/`CPS`, loads
  the host flags from `PublicIn+$18` into `gr64`, clears the interrupt and
  region tables and the video block, and starts the wait loop.

The video command service (`$2000C14`) is now read in detail: besides the
clock-retiming pause, page configuration 1/2 converts the 2 MB video window
between a linear and a 4-way word-interleaved layout in place, and the pager
(`$2001D10`) replaces a randomly chosen entry of a 52-entry pool, relinks the
hash chain, invalidates its TLB entries and bursts the new page in. Still only
roughly read: the services behind vector 66 and the exact layout of the
`$4C002810..$4C002E48` tables. The routine banners say "reading" where a role is
inferred from loads and compares and not confirmed against a caller.

## Disassembly

Am29000, big-endian, 32-bit instructions. `../am29k_dasm.py` (opcode table
ported from MAME's `am29dasm.cpp`) handles all six operand formats and marks
delay slots (`iret` has none); registers 0-127 print `grN`, 128-255 `lrN`.
The files (System 6: the same names in `sw11/disasm/`):

* `disasm/Hand.asm` -- the kernel, with a reading guide, the vector table,
  reason codes and routine banners; `disasm/Boot.asm`; `disasm/RuntimeData.asm`
  -- the data sections, including the service table with its handlers
  (`../runtime_dasm.py`).
* `disasm/text.asm` -- Antelope's `.text` (`../antelope_dasm.py`). Labels are
  the 768 `.text` addresses of the symbol table: 709 function entries and 59
  object-file starts, which sit on the tag word 4 bytes before a file's
  first function (see "How the firmware was built"). Functions named in
  `../HOST_CARD_PROTOCOL.md` carry their names (`../antelope_names.py`), the
  service stubs `svc_N`, and every relocated word its target.
* `disasm/lit.asm`, `data.asm` -- `.lit` (its strings, then the switch and
  command tables with their targets) and `.data`/`.data1` (object-file and
  symbol labels, ASCII, relocation targets); `disasm/Code.asm` -- the entry
  stub at `$F000`.

## COFF relocations — reverse-engineered and applied

The relocation table (`relptr`/`nrel` in each section header) turned out to
be one of the few things in this format that **isn't** obfuscated — it's
stored plaintext, unlike the XOR-keystreamed headers and constant-XOR'd
section data. Each record is 8 bytes, big-endian:

```
[vaddr:u32][symndx:u16][type:u16]
```

`vaddr` is **absolute** (confirmed against `Code`'s own records, which carry
values like `0xf00c` directly rather than a small `Code`-relative offset) —
for the sections with `vaddr=0` that happens to look the same as
section-relative, but `Code`'s live at `sec.vaddr + local_offset`. `symndx`
indexes the same 6-byte `[scnum:s16][value:u32]` symbol table `acef_unpack.py`
already decodes.
Cross-checking candidate record sizes against two hard constraints —
`vaddr` must land inside the section and increase monotonically, `symndx`
must be `< nsyms` — confirmed 8 bytes at 98.4% validity (the remaining 1.6%
are a handful of out-of-range indices, left unresolved rather than guessed
at). Five relocation `type`s show up, identified by cross-referencing each
one against the instruction it points at:

| type | meaning | applies to |
|-----:|---------|------------|
| 26 | low 16 bits | `const` |
| 27 | high 16 bits | `consth` |
| 28 | null companion of type 27 (always symbol 0) | — (no independent info; just marks the pair as matched) |
| 24 | absolute call target | `call` |
| 29 | raw 32-bit word replace (or a single **byte** replace — see below) | often lands on non-code bytes — corroborates the "embedded data tables" finding above |
| 31 | raw 32-bit word replace | only seen in `.lit`/`.data` — same idea as 29, apparently a separate type code reserved for pure-data sections |

A symbol resolves to a real address when its `scnum` is a normal section
(section base + `value`) or `-1` (`N_ABS`, `value` already absolute). `scnum`
-3 is a placeholder: the symbol is the next record (the converter wrote a
symbol that had an aux entry into the aux slot). `scnum` 0 is an undefined
symbol, here always a `.comm` variable (its `value` is the size), which the
loader allocates. The target is the symbol plus the addend in the word: the
16-bit immediate for `const`, the word itself for types 29/31, and for
`consth` the immediate (high half) with the low half in the `symndx` field of
the type-28 record that follows.

Counted for the System 7 Antelope: `Code` 13 records, `.text` 6,613 (1,935
type 26, 1,899 each of 27 and 28, 747 type 29, 133 type 24), `.lit` 662 and
`.data` 101 (type 31). All resolve except the 784 that name a `.comm`
variable. The 747 type-29 records in `.text` (and one in `Code`) sit at byte
1 of a word: they fill in the trap number (64 or 65, the absolute symbols
`V_SPILL`/`V_FILL`) of the spill/fill asserts, which the file has as 0.

This offline pass has a live counterpart: `ACEFLoad` (`../gc24.s`, and
`../DRVR.s`'s own copy) performs the same relocation job at load time,
patching branch targets in place and logging
`"Absolute/Relative Branch Target (0x%08x) Out of Range at 0x%08X"` if one
doesn't fit.

### `firmware_image.bin` — relocated flat image

`acef_unpack.py` writes `firmware_image.bin` by placing each section at its
`vaddr`, which is wrong for a relocatable file (every section but `Code`
has `vaddr` 0). `apply_reloc.py` rebuilds it with the sections laid out
**sequentially** (`Code`, `.text`, `.lit`, `.data`, `Apple`, `.data1`; offsets
in `firmware_image.map.txt`) and every resolved relocation applied as a byte
patch: 4,702 patched, 0 skipped (System 6: 4,881). This is a synthetic
layout for inspection, not the card's memory layout, which the loader
assigns.

## Symbol table → function boundaries (`symbols.txt`)

`ACEF_100`'s symbol table (`nsyms`=1858 at file offset `symptr`) is decoded by
`acef_unpack.py`. It is **not** standard 18-byte COFF: each entry is a compact
**6-byte record `[scnum:s16][value:u32]`** (1858 × 6 = exactly the bytes to
end-of-file). Negative `scnum`s are COFF debug/abs/undef markers; positive ones
are section-relative addresses:

| section | symbols | |
|---------|--------:|--|
| `.text` | **768** | 709 function entry points and 59 object-file starts (tag words) |
| `.data` | 84 | data objects |
| `.lit` | 21 | literals |
| `.bss`/`Code`/… | 40 | misc |

**The names themselves were stripped** — there is no string table anywhere in
the file (a full ASCII scan of the symbol region finds nothing), so only the
*addresses* survive. That is still a real gain: `disasm/text.asm` marks all
**768 addresses** (709 functions and 59 file starts) with `sub_XXXXX:` labels at their true entry points (vs. mere
branch targets), turning the listing into cleanly-bounded functions — e.g.

```
sub_00084:
  00084:  c6601388  mfsr  gr96, spr19      ; read special register
  00088:  9d6070ea  andn  gr96, gr112, $ea
  0008c:  936070b1  or    gr96, gr112, $b1
  00090:  ce001180  mtsr  spr17, lr0       ; write special register
  00094:  c0001308  jmpi  gr8             ; return
  00098:  704013ee  aseq  trap64, ...       ; [delay slot]
```

To recover the actual *names* one would need a build artifact this stripped
firmware no longer carries (a `.map`, an unstripped `.o`, or symbolic debug
info) — none is present in the shipped control-panel software.


## How the firmware was built (`../antelope_modules.py`)

The file headers, section flags and symbol tables keep enough of the build to
say how both programs were made. Nothing names a compiler, so that part is
inference.

### Two programs, two kinds of build

| | `Runtime` (ACEF 1) | `32-Bit Antelope` (ACEF 100) |
|---|---|---|
| source | hand-written assembly: no `sub gr1,gr1,N` prologues, no `jmpi lr0` returns, no tag words | C (25 Apple object files) plus libraries and some assembly |
| file flags | `$020F`: relocations, line numbers and local symbols stripped, executable, 32-bit big-endian (`F_AR32W`) | `$0200`: not executable, relocations and symbols kept: an `ld -r` style partial link |
| sections | 13 at fixed card addresses, all `STYP_ABS` (`$4000`), named after the memory map (`PublicOu` is `PublicOut` cut to COFF's 8 characters) | `Code` (absolute, `$F000`, the entry), then `.text`, `.lit`, `.data`, `Apple`, `.data1`, `.bss` at 0, placed by `ACEFLoad` at run time |
| version, date (optional header) | System 6: `$00110000`, 1991-01-22 11:56:36; System 7: `$00700D01`, 1992-04-22 12:59:12 | System 6: `$00110000`, 1991-01-22 12:42:27; System 7: `$00700D01`, 1992-04-22 13:27:04 |
| file `timdat` (whose low byte is the obfuscation key) | 36 s / 28 s later | 292 s / 293 s later |

`ACEFLoad` itself prints these fields ("Program '%s' version %08x date %d").
The dates are Macintosh times (seconds since 1904, local time), in both the
optional header and the file header. So at least the ACEF packer ran on a
Mac, presumably as an MPW tool. Each release was built on one day:
`Runtime`, then `Antelope` half an hour later. The gap between a program's
two dates is the same in both years for the same program (about 5 minutes for
the 243 KB `Antelope`, half a minute for `Runtime`), so it is probably the
duration of one build step after the link, such as packing and encrypting. The
System 6 version `$00110000` matches its package ("8•24 GC SW 1.1"). In System
7's `$00700D01`, the high half matches 7.0 (the package is 7.0.1); the low half
`$0D01` is unexplained, perhaps a development stage and build number. Both
`Runtime` headers keep a stale buffer after the program name, `Runtime\0` followed by
`tart.ACEF`, so the packer's files had the extension `.ACEF`. The copyright
years are 1989 (`Runtime`'s `Apple` section), 1990 (`Antelope`'s `Apple`
section and the ACEF signature block). `Antelope`'s `Apple` section repeats the version
record: `$00700D01`, a date (`$A61B1A28`), "32-Bit Antelope" and
the copyright, so the version and build date were also compiled into the program.

### The AMD 29K tool conventions

* **COFF as AMD defined it for the 29K**: `.lit` has the flags `$8020`
  (`STYP_LIT`, AMD's read-only literal section), the fixed sections `$4000`
  (`STYP_ABS`), and the file flag `F_AR32W`. ACEF (magic `$012A`/`$012B`
  instead of AMD's `$017A`/`$017B`) is this COFF repacked: 6-byte symbols
  without names, metadata XORed, section data encrypted.
* **AMD's calling convention**, in full: register-stack frames
  (`sub gr1,gr1,N` / `asgeu V_SPILL,gr1,gr126` / `add lr1,gr1,M` and the fill
  `asleu V_FILL,lr1,gr127`), a **tag word** before every function (opcode
  byte 0, never executed, the debugger's frame description), `gr121` (`tav`)
  for the service number, `gr122` (`tpc`) for transparent millicode calls.
* **Trap numbers as link-time symbols.** The table's four absolute symbols are
  `$40`, `$41`, `$42` and `$45`: `V_SPILL`, `V_FILL`, the card's own service
  trap 66, and 69, AMD's HIF system call. The 748 byte relocations of type 29
  (always `$40` or `$41`) fill these into the spill and fill asserts at load
  time, so the objects were built with the trap numbers left symbolic, as
  AMD's runtime does.
* **AMD's HIF library, verbatim.** Each HIF stub (close, exit, lseek, open,
  read, tmpnam, write, and remove at `$3C9EC`) is its own object file of 36
  bytes. That is the layout of a Unix library archive, from which the linker
  pulled only the members referenced (the first seven are in alphabetical
  order). They match AMD's source as later published in newlib
  (`libc/sys/a29khif/_close.s` etc., "Copyright 1990 Advanced Micro Devices",
  SCCS stamp 1990-10-14) on every plain bit: 1,417 bits in System 7 and 1,505
  in System 6 across the eight stubs, none different (`../antelope_hif_stubs.py`).
  Each stub is the debugger tag word `(nargs+2) << 16`, then `const tav,N` /
  `asneq V_SYSCALL,gr1,gr1` / `jmpti tav,lr0` / errno = `tav` / `jmpi lr0` /
  `constn v0,-1`. In System 6 four tag words are fully plain, and they are
  exactly the source's `$00030000` and `$00050000`.
* **A BSD-style C library** on top: `printf`/`vprintf`, `fseek`, `_doprnt`,
  20-byte `FILE`s in `_iob`, the V7/BSD `_ctype_` bits, `exit` with a handler
  table, `memchr`/`memcpy`/`memset`, plus multiply and divide millicode. It is 14,788 bytes and
  identical in size and layout in both releases. So it is a prebuilt vendor
  library, unchanged over 15 months.

* **AMD's `crt0`, trimmed.** `Code` (38 words) is AMD's `crt0.s` `start`
  routine (newlib `libc/sys/a29khif/crt0.s`, 48 words) without the two
  `HIF_setvec` calls that install its own spill and fill handlers. Apple's
  kernel provides vectors 64/65 itself, and crt0's handlers are not linked.
  The opcode bytes are identical word for word, in both releases. The four
  `Code` labels are crt0's `start`, `argcloop`, `NoLibInit` and `loop` (words 0,
  13, 26, 34). It stores `gr96`/`gr97` into `__29027Mode`, gets `argv`
  (HIF getargs), calls `__LibInit` if set, then `main`, then `exit`
  (`$3AC88`). Two of the undefined symbols are crt0's common blocks
  (`.comm`, the value is the size): `__29027Mode` (8) and `__LibInit` (4).
  Through the placeholder symbol 1048, `_main` is **`$31DAC`**, the first
  function of file 25, the dispatcher's file. `main` calls `InitPacket(1)`
  (`$3299C`). That routine takes a base from kernel service `$C0` (stub `$38FC8`),
  stores the packet pointer `[base+$418]` at `.bss+0`, and initialises the
  packet: `+$00` = `$0101xxxx`, `+$04` = the argument, the buffer pointers
  `+$10`/`+$38`/`+$54` = packet `+$6D0`/`+$610`/`+$650`, and `+$28`/`+$34`/`+$44`
  cleared. Then `main` clears the go flag `+$14` and prints "P??Mo?et: Starting
  up, comm block at %X" (probably "…Monet") through `Report` (`.lit+$D60`). It stores
  `packet+$44` (`rec`) at `.bss+4` and loops forever on
  `CommandDispatcher(-1)`.
* **Millicode.** Files 55-57 are transparent routines (return `jmpi tpc`):
  a multiply (`$3B814` etc., 55 `mulu` steps) and two divides (`$3B950`
  etc. with 31 `div` steps, and `$3BA38` with `div0`, 31 `div`, `divl`,
  `divrem`). Apple's C code calls them 89 times, always as `const`/`consth
  reg` + `calli tpc,reg`: multiply 59, `$3B950` 22, `$3BA38` 8. Files
  52-54 are C-callable `memchr` (`$3B500`), `memcpy` (`$3B600`) and `memset`
  (`$3B748`), one per file, each with a tag word for 3 arguments. newlib has no
  source for these. Its `intrinsi.h` is the floating-point package that
  Quantitative Technology Corporation wrote for AMD.

This is the AMD 29K development environment of 1989-91: AMD's COFF
assembler and linker conventions, AMD's HIF library and `crt0` (both
verbatim), and a C compiler that emits `.lit`, AMD tag words and transparent
millicode calls. **GCC is ruled out, at least as GCC 2.95 has the a29k port**
(`config/a29k/a29k.md`). It compiles `*`, `/` and `%` to the `multiply`,
`divide` and `dividu` instructions. Those trap on the Am29000 and need an
emulating OS, and Apple's kernel has no handler for them (vectors 22-63
report reason `$A3`). Apple's C code contains none of them. GCC also does
write the same tag word (argument count, frame size) and `.sect .lit` in every
file, so those two features don't tell the compilers apart. That leaves a
vendor compiler, most likely MetaWare's High C 29K, the compiler AMD offered
with these libraries (and the "HighC29K" toolkit in AMD's 1990 data book).

### The 69 object files

The symbol table keeps COFF's per-file layout: a `.file` symbol per object
file (scnum -2, its value the index of the next one; the chain is consistent),
the file's symbols, and its section symbols, with the file's start in each
section. Global symbols without aux entries follow at the end, as in COFF. A
symbol slot with scnum -3 is a placeholder: the packer wrote each symbol that
had an aux entry into the aux slot, which keeps the original symbol indices
for the relocations. Three kinds of file show:

| files (System 7) | kind | what |
|---|---|---|
| 0 | assembly | `Code`, the entry stub at `$F000` (crt0) |
| 1-3 | assembly / C | `$00000`-`$00F74`: low-level helpers (the 32×32 multiply `$00CC4` is in file 2), and file 3, the `Apple` version record |
| 4-28 | **C with debug information** | Apple's code, `$00F74`-`$37C10`. Every function has an aux entry, and every file has `.text .data .bss .lit` sections, `.lit` also when empty. Line numbers were stripped |
| 29 | C without debug information | `$37C10`-`$38F24`, 43 functions with ordinary prologues (`$37D68` is a fill routine); role not yet known |
| 30 | assembly | `$38F24`-`$39114`, the card's service-call stubs: `const gr121,N` / `asneq 66` (the card's services `$B8`-`$D6`) or `asneq 69` (HIF `$111`/`$112`), no tag words |
| 31-44, 59-66, 68 | C without debug information | the C library: `printf.o` (`$39114`), `fseek` (`$39300`), `_doprnt` (`$398B8`, with `.data1`), `_ctype_` (a `.lit`-only file at `$3AA98`), the ctype functions, `exit` (`$3AC84`), stdio (`$3B014`) |
| 45-51, 67 | assembly | AMD's HIF stubs, one per file: close, exit, lseek, open, read, tmpnam, write; remove |
| 52-57 | assembly | `memchr`, `memcpy`, `memset`, then the millicode: multiply (55), divides (56, 57) |

The 768 `.text` addresses in `symbols.txt` are **709 functions and 59 file
starts**. In C files and most assembly files a file starts 4 bytes before its
first function, on the tag word; `disasm/text.asm` labels those words as
`sub_` too (`sub_01a4c` is the file start, BitBlt is `sub_01a50`). Every
file's `.data`, `.bss` and `.lit` start is known as well. This explains the
bases of the `.lit` switch tables: each table is relocated against its own
file's `.text` start (`$31DA8` is file 25's).

**System 6 against System 7.** System 6 has 71 files, also 709 functions. Files
0-27 are the same files in the same link order, and the library is identical.
The differences:

* file 4 shrank from 29 functions to 4: System 6's 26 16-bit arithmetic
  stubs (`$01378`-`$017C4`) are gone;
* files 12, 15, 18 and 22 grew (37→45, 51→58, 38→47, 65→89 functions; file
  22, with the StretchBits helpers, from 15,952 to 24,896 bytes);
* in place of file 28 System 6 has the `'rpza'` codec (`$331C0`, 38,052
  bytes) and two assembly files after it (`$3C664`, `$3DA08`). System 7 has
  the module-support file there (`$3772C`, request 999 and the `$80xx`
  services), which loads code from the host instead;
* Apple's C code is 243,680 bytes in System 6 and 224,412 in System 7; the
  21 undefined symbols of System 7 (19 in System 6) are what `ACEFLoad` and
  the kernel supply.

### What this gives the analysis

* Function boundaries are now exact (709, not 768), and they group into 25 Apple
  source files whose sizes and order are the same in both releases. System 6
  and System 7 can be compared file by file.
* About 15 KB is vendor library code with known behaviour. It needs no
  reverse engineering and can be named from the standard library.
* Each file's `.data` start bounds its data objects.
* Earlier "module" readings based on `.lit` bases or guesses can be checked
  against real file boundaries. One correction so far: `$11AD4`-`$174FC` is
  three files, not one.

## What is open

* Some flag bits (1, 3, 10, 30, 31) are read only in outline
  (`../HOST_CARD_PROTOCOL.md` section 9, "The flags word on the card").
