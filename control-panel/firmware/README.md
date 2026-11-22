# Am29000 firmware -- unpacked from the ACEF resources

The `ACEF` resources in the 8*24 GC control-panel software are the on-card
**Am29000 firmware**, stored in an obfuscated Am29000 **COFF** format, with a
**second, much harder mask** on the code and data bytes. This folder holds the
unpacked firmware (`../acef_unpack.py`, from the `ACEFLoad` loaders in `gc24`
and the DRVR) and what could be recovered from it.

## Status at a glance

| part | state |
|---|---|
| ACEF container, relocations, symbol table | fully decoded (`../acef_unpack.py`, `../apply_reloc.py`) |
| `Runtime` / `Hand` (the kernel, 2,885 words) | **fully unmasked and disassembled** (`disasm/Hand.asm`) |
| `Runtime` / `Boot` (512 words) | unmasked with *fitted* tables (`disasm/Boot.asm`); a few register fields may be wrong |
| `Runtime` data sections | their "noise" is the mask applied to zero/constant data; `Apple`, `PublicIn`, parts of `PublicOu` decoded |
| `Antelope` (the 243 KB accelerator) | **still masked**; only the loader/relocation facts are reliable; `disasm/text.asm` is *not* real code (opcode byte only) |
| host <-> card protocol | documented and cross-checked in `../HOST_CARD_PROTOCOL.md` |

Tools: `../acef_unpack.py` (unpack), `../apply_reloc.py` (relocations),
`../am29k_dasm.py` (Am29000 disassembler), `../unmask_runtime.py` (second mask,
`Hand`/`Boot`), `../extract_resources.py` (resource fork).

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
section raw data (@ s_scnptr)       XOR CONSTANT   KEY
relocations / symbols               plaintext
```

The first layer is a single key byte (`timdat`'s low byte): the metadata gets a
running keystream, the section data a constant XOR. That layer is undone by
`acef_unpack.py`. **It is not the whole story**: the unpacked code and data
words of both ACEFs carry a *second* mask (below), which is why the unpacked
bytes look plausible at the opcode level but not above it.

## The second mask

(A narrative of how it was found and how to reproduce it: [`../SECOND_MASK.md`](../SECOND_MASK.md).)

The low 23 bits of every 32-bit word of the code sections are XORed with a key
that depends on the word index `k` (counted from the start of the section):

```
r   = 0x4000 + 0x80*(ROW[k mod 48] - k) + COL[k mod 24]
key = signext19( ((-(r >> 16)) & 7) << 16  |  ((r & 0xFFFF) ^ 0x4000) ) & 0x7FFFFF
```

(`ROW`, `COL` tables per section; `../unmask_runtime.py`.) It was found by
solving for the key at words whose plaintext is known: operand-free `iret`
words, `mtsr` words (RC = 0), `mfsr` (RB = 0), and later `Apple`'s copyright
text. The opcode byte (bits 24-31) is never masked, which is why opcode
histograms looked right. For small `k` the key has no bits above 14, so the
RC byte is plain at the start of a section.

* **`Hand`**: tables solved exactly (80 `iret` + 120 `mtsr` words fixed them; ten
  `ROW` entries came from weaker signals). Checks not used in the fit all pass:
  every `mfsr` has RB = 0, every `mtsr` RC = 0 and an architectural SPR number
  (0-14, 128-135), every `iret` has zero operands, and **all 351 direct jumps and
  calls land inside the section**.
* **`Boot`**: only 5 SPR instructions to anchor on, so `COL`/`ROW` were *fitted*
  (maximum likelihood against field statistics of the unmasked `Hand`, plus
  constraints). 58 of 58 direct jumps land in the code and 89 of 99
  `const`/`consth` pairs share a register; some fields are probably still wrong.
* **Data sections** carry the same mask on *constant* data, which is why they
  look like noise: `Vec` is the keystream itself (an all-zero section),
  `PublicIn` too; `Apple` decodes with `Vec`'s keystream to the copyright string
  "Copyright (c) 1989, Apple Computer, Inc. All Rights Reserved" (every other
  two-character chunk lives in the masked low half); `PublicOu` has a plain
  header (`3210 0070 0 4C00x4 0001`: handshake constant, four `0x4C00....`
  pointers) and another copy of the copyright text in its high halves.
* **`Antelope`** is masked the same way (`.text`, `.lit`, `.data`, the `Code`
  stub), with its own tables. Its 3,726 known-plaintext key values (spill/fill
  asserts `asgeu 64`/`asleu 65`, the NOP `aseq 64,gr1,gr1` = 2,064 words,
  `jmpi lr0`) show a mixed-radix structure (a base-4 digit of weight 64 rows) that
  is **not solved**; see `ACEF_100_Antelope/mask_samples.tsv` and
  `../HOST_CARD_PROTOCOL.md` section 6. Everything earlier that treated
  Antelope's `.text` as plain code (`disasm/text.asm`, prologue/`gr0` statistics,
  the "function naming" analysis) used masked bytes and is unreliable beyond the
  opcode byte.

## `ACEF_1_Runtime/` -- "Runtime" (the Am29000 kernel)

KEY `0xBC`. 13 sections; header `symptr=0`/`nsyms=0` and every section has
`nrel=0` (pre-linked to its fixed map).

| section | vaddr | role |
|---------|------:|------|
| `Boot` | `0x2003000` | boot code (512 words) |
| `Hand` | `0x2000000` | trap/interrupt/service kernel (2,885 words) |
| `Cache` | `0x2003800` | bss (nothing is missing: the earlier "second stage" theory was a decode artefact) |
| `Vec` | `0x4C000000` | trap vector table (`VAB`); the file holds the keystream, `Boot` fills the table |
| `PublicIn` / `PublicOu` | `0x4C006400/6800` | host -> card / card -> host fields |
| `HifComm` | `0x4C007000` | mailbox (`'s337'` / `$96666669`) |
| `VidComm` | `0x4C007300` | video command block (= ROM's `$0C007300`) |
| `InitMap` / `InpArgs` | `0x4C007400/7800` | init map / program arguments |
| `Private`, `PrivNZ`, `Apple` | `0x4C0025xx` | service jump table, private state, copyright |

### What `Boot` does

1. Touches a block of card registers from `$4400000C` and sets `CPS` to
   `$0000` then `$047F` (the same `CPS` constants `Hand` uses).
2. **Polls `$4C006400` (`PublicIn` word 0) until it reads `$42005300`** -- the
   value `DRVR.s`'s `Init29K` pokes to `image+$00` after uploading `Runtime` --
   then writes 0 back.
3. Copies a parameter block from `PublicIn` (the flags and sizes `DRVR.s`
   publishes at `+$18`, `+$20`...`+$2C`).
4. Sets `VAB = $4C000000` (the `Vec` section) and `CFG |= $10`, and **fills the
   trap vector table** with handler addresses `$0200xxxx` (`$2000000`,
   `$2000008`, `$2000908`, ... and `$2001D08` for the unused entries). So the
   "noise" the host sees in `Vec` and the pointer-looking `PrivNZ` words are
   this table's initial image.
5. Reads the three hardware-ID bits at `$44000044/48/4C` (the host's
   `$0400004C/48/44`, the readiness bits `BuildUnitRecords` reads), picks a
   board configuration value (`$1E0`, `$366`, `$1E6`, `$180`, `$240`, `$270`)
   and stores it to `$4C006828` (`PublicOu+$28`).
6. `jmp $2001FFC` into `Hand`'s reset/initialisation routine.

### What `Hand` contains

`disasm/Hand.asm` is the real disassembly and now carries a reading guide
(registers, vector table, reason codes, card address map) plus a banner on each
routine. In short, `Hand` is the Am29000 **runtime kernel** for the card:

* **Trap vector table.** `Boot` installs it at `VAB = $4C000000` (the `Vec`
  section): vectors 0-21 point at the handlers below, 22-63 at a default that
  reports reason `$A3`, 64/65 are the register-stack spill/fill handlers (the
  `Antelope` loader patches 293 `asgeu 64,gr1,gr126` and 454 `asleu 65,lr2,gr127`
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
delay slots; registers 0-127 print `grN`, 128-255 `lrN`. The files:

* `disasm/Hand.asm`, `disasm/Boot.asm` -- the **real** kernel and boot code
  (from `ACEF_1_Runtime/*.unmasked.bin`), with a reading guide, the vector table,
  reason codes and routine banners in `Hand.asm`.
* `disasm/text.asm`, `Code.asm`, `lit.asm`, `data.asm` -- Antelope, made from the
  **masked** bytes: only the opcode byte and the relocation annotations are
  meaningful. The 768 function entry addresses (from the symbol table) are real.

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
(section base + `value`) or `-1` (`N_ABS`, `value` already absolute);
`scnum` 0/-2/-3 mean the symbol is external to this ACEF image (most likely
defined in the separate `ACEF_1_Runtime` firmware, or patched in by the
on-card loader at boot) and can't be resolved from this file alone.

Applied to [`disasm/text.asm`](disasm/) and [`disasm/Code.asm`](disasm/) as
inline `; RELOC ...` comments (original placeholder bytes/immediates left
untouched — byte-exact verification still passes 0 missing/0 mismatched):
**1,684 of 4,714 symbol-bearing `.text` relocations resolve (35.7%)**; the
rest are marked "unresolved external" rather than guessed at.

This offline pass has a live counterpart: `ACEFLoad` (`../gc24.s`, and
`../DRVR.s`'s own copy) performs this exact same relocation job at load
time, patching branch targets in place and logging
`"Absolute/Relative Branch Target (0x%08x) Out of Range at 0x%08X"` if one
doesn't fit — and it can resolve the *external* symbols this static
analysis can't, since it runs with the real, current load address rather
than a symbol table with no string names.

`.lit` (literal pool, 662 relocations) and `.data` (initialised data, 101
relocations) aren't Am29000 code, so there's nothing to disassemble — instead
[`disasm/lit.asm`](disasm/) and [`disasm/data.asm`](disasm/) are plain word
dumps (`obj_XXXXX:` labels from the symbol table, an ASCII-hint column, and
the same `; RELOC ...` annotations). Notably **0 of the 662+101 relocations
in these two sections resolve** — every one references an external symbol,
unlike `.text` where over a third do. The ASCII column also shows `.lit`
isn't pure numeric literals: e.g. offset `$0` reads `"Bogu"`/`"s\x00\x03\x60"`
— a literal string constant sitting right next to the pointer-table entries.

**Not every type-29 hit is a whole word.** 748 of them (747 in `.text`, 1 in
`Code`) land at `offset % 4 == 1` — one byte into a word, not the start of
one. Every one of those resolves to a value ≤ 255 (only 0x40/0x41 show up
across the whole table), which is the tell: these are single-**byte**
constant patches (e.g. a small flag/enum byte living mid-word next to an
unrelated instruction), not misaligned 32-bit fixups. Treating them as a
naive 4-byte overwrite was tried first and quietly corrupted the start of
the *next* word — caught by re-diffing the patched output against the
original bytes outside every touched relocation site and finding 725
unexplained differences, all one byte past a type-29 hit. `apply_reloc.py`
now special-cases `offset % 4 != 0` as a single-byte patch.

### `firmware_image.bin` — relocated flat image

The original `firmware_image.bin` (built by `acef_unpack.py`, which sums
each section at its raw `vaddr` field) was silently **corrupt**: `Code` is
the only section with a distinct `vaddr` (`0xF000`) — `.text`, `.lit`,
`.data`, `Apple`, and `.data1` all report `vaddr=0`, because this is a
*relocatable* object file and real load addresses are assigned by the
on-card loader at boot, not baked into the section header. Summing them at
face value made every zero-`vaddr` section after `.text` overwrite `.text`'s
first few KB.

`apply_reloc.py` now builds a corrected image instead: sections laid out
**sequentially** (`Code`, `.text`, `.lit`, `.data`, `Apple`, `.data1` — `.bss`
has no file data) at the offsets recorded in the companion
`firmware_image.map.txt`. This is a synthetic, documented concatenation for
inspection purposes — **not** a claim about the real runtime memory layout,
which the relocation evidence says is loader-assigned. Every *resolved*
relocation is applied as a genuine byte-level patch (a raw binary has no
comment channel): **1,687 of 4,723 total relocations patched** (`Code` 3,
`.text` 1,684; `.lit`/`.data`/`Apple`/`.data1` 0, matching their 0%
resolution rate above), **0 skipped**. Verified by re-diffing every patched
section against its original bytes outside the touched relocation sites (0
unexplained differences) and by round-tripping a sample of patched
`const`/`consth` pairs back through `am29k_dasm.py` to confirm they decode
to the intended resolved address.

## Symbol table → function boundaries (`symbols.txt`)

`ACEF_100`'s symbol table (`nsyms`=1858 at file offset `symptr`) is decoded by
`acef_unpack.py`. It is **not** standard 18-byte COFF: each entry is a compact
**6-byte record `[scnum:s16][value:u32]`** (1858 × 6 = exactly the bytes to
end-of-file). Negative `scnum`s are COFF debug/abs/undef markers; positive ones
are section-relative addresses:

| section | symbols | |
|---------|--------:|--|
| `.text` | **768** | accelerator function entry points |
| `.data` | 84 | data objects |
| `.lit` | 21 | literals |
| `.bss`/`Code`/… | 40 | misc |

**The names themselves were stripped** — there is no string table anywhere in
the file (a full ASCII scan of the symbol region finds nothing), so only the
*addresses* survive. That is still a real gain: `disasm/text.asm` marks all
**768 functions** with `sub_XXXXX:` labels at their true entry points (vs. mere
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


## What is open

* The mask generator for `Antelope` (all of the accelerator code).
* `Boot`'s fitted tables and `Hand`'s ten indirectly derived `ROW` entries.
* In `Hand`: the services behind vector 66 and which feature each host-flag bit
  switches.
