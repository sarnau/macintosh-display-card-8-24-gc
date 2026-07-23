# Am29000 firmware — unpacked from the ACEF resources

The `ACEF` resources in the 8•24 GC control-panel software are the on-card
**Am29000 firmware**, stored in an obfuscated Am29000 **COFF** format. This
folder holds the unpacked firmware, produced by [`../acef_unpack.py`](../acef_unpack.py),
which was reverse-engineered from the `ACEFLoad` loaders in `gc24` and the DRVR.

## The ACEF format (reverse-engineered)

```
file header (20 bytes, PLAINTEXT)
   +0  magic  u16   0x012A = plain COFF · 0x012B = obfuscated (both handled by the DRVR)
   +2  nscns  u16   number of sections
   +4  timdat u32   ; byte +7 doubles as the obfuscation KEY
   +8  symptr u32   +12 nsyms u32   +16 opthdr u16 (=68)   +18 flags u16
optional header (68 bytes @ 0x14)   XOR keystream  key(i) = (0x14 + KEY*i) & 0xFF
   program name (e.g. "32-Bit Antelope") @ +0x1C, text/data/bss sizes, version, date
[0x12B only] 64-byte copyright signature (plaintext) @ 0x58   (loader verifies it)
section headers (40 bytes each)     XOR keystream  key(i) = (fileOffset + KEY*i) & 0xFF
section raw data (@ s_scnptr)       XOR CONSTANT   KEY
relocations / symbols               (present; not needed to recover the code)
```

So the obfuscation is a single key byte (`timdat`'s low byte): the small
metadata gets a running keystream, the bulk section data a constant XOR. Not
encryption — just enough to stop casual dumping. **The unpacked `.text` is
verified Am29000 code** (opcode histogram: ADD/LOAD/CONST/STORE/CONSTH/JMP…).

## `ACEF_100_Antelope/` — "32-Bit Antelope" (the QuickDraw accelerator)

KEY `0x4D`. 7 sections; the main code is **`.text`, 249 KB = 62,134 Am29000
instructions**.

| section | vaddr | size | notes |
|---------|------:|-----:|-------|
| `Code` | `0xF000` | 0x98 | bootstrap / entry stub (13 relocations) |
| `.text` | 0 | 0x3CAD8 | **main accelerator code** (6613 relocations) |
| `.lit` | 0 | 0x1124 | literal pool |
| `.data` | 0 | 0x18F0 | initialised data |
| `Apple`,`.data1` | 0 | small | vendor / aux data |
| `.bss` | 0 | 0xA64 | zero-init (no file data) |

`firmware_image.bin` is the flattened load image (248 KB).

## `ACEF_1_Runtime/` — "Runtime" (the Am29000 kernel)

KEY `0xBC`. 13 sections. The section names lay out the whole coprocessor
runtime and, crucially, its **host-interface command area** — note `VidComm`
at `0x4C007300`, exactly the MFB/Am29000 parameter block the 68k video driver
pokes at `base+0x0C007300` (see `../../extracted-source/VideoDriver.s`):

| section | vaddr | role |
|---------|------:|------|
| `Boot` | `0x2003000` | Am29000 boot code |
| `Hand` | `0x2000000` | interrupt/trap handlers |
| `Cache` | `0x2003800` | (bss) instruction-cache RAM |
| `Vec` | `0x4C000000` | vector table |
| `PublicIn` / `PublicOu` | `0x4C006400/6800` | host↔card command in/out |
| `HifComm` | `0x4C007000` | host-interface comm block |
| **`VidComm`** | **`0x4C007300`** | **video command block (= ROM's `$0C007300`)** |
| `InitMap` / `InpArgs` | `0x4C007400/7800` | init map / input args |
| `Private`,`PrivNZ`,`Apple` | `0x4C0025xx` | private state |

Sections span two address regions (`0x2000000` SRAM/cache and `0x4C000000`
register/comm space), so they are kept as separate `.bin` files rather than one
flat image.

## Disassembly

These are **Am29000** (big-endian, 32-bit fixed instructions). Capstone and
stock Ghidra have no Am29000 back-end, so this folder ships a small one:

* [`../am29k_dasm.py`](../am29k_dasm.py) — an Am29000 disassembler (opcode table
  and encoding ported from MAME's `am29dasm.cpp`, cross-checked against MAME's
  execution core). Handles all six operand formats, PC-relative vs. absolute
  jump targets, special-register names, and marks the one **delay slot** after
  each branch.
* [`disasm/text.asm`](disasm/) — the full **`.text` disassembly** (62,134
  instructions) with 7,073 auto-generated `L_xxxxx` labels for in-section branch
  and call targets.
* [`disasm/Code.asm`](disasm/) — the bootstrap `Code` section, whose entry is a
  textbook Am29000 prologue: `sub gr1,gr1,$18` (allocate register-stack frame),
  `asgeu trap0,gr1,gr86` (stack-overflow check), then setup + `jmpf`.

Quality: **99.0%** of `.text` decodes to valid instructions (the ~1% `.word`
lines are literal data / relocation placeholders). Note the honest caveat on
this: syntactic validity isn't proof of *being executed code* — the Am29000
opcode space is dense enough that most random data words also decode to some
syntactically-valid instruction, and (per the "embedded data tables" finding
below) some of `.text` genuinely isn't code. The **decoder and jump-target
math itself** is checked a stronger way: gr0 is architecturally read-only, so
any decoded instruction that writes to it is *proof* of a decode/data issue,
not just a syntax fluke — and that check finds violations in only 32 of
62,134 instructions (0.05%), which is the real confidence signal.

`gr1` is the Am29000 register-stack pointer; registers 0–127 print as `grN`,
128–255 as `lrN` (local, relative to the stack).

## COFF relocations — reverse-engineered and applied

The relocation table (`relptr`/`nrel` in each section header) turned out to
be one of the few things in this format that **isn't** obfuscated — it's
stored plaintext, unlike the XOR-keystreamed headers and constant-XOR'd
section data. Each record is 8 bytes, big-endian:

```
[vaddr:u32][symndx:u16][type:u16]
```

`vaddr` is section-relative, `symndx` indexes the same 6-byte
`[scnum:s16][value:u32]` symbol table `acef_unpack.py` already decodes.
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
| 29 | raw 32-bit word replace | often lands on non-code bytes — corroborates the "embedded data tables" finding above |

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

## Function naming — what was and wasn't achievable

The 768 `.text` function boundaries (below) are real; assigning each a *role*
is not, and this was checked three ways before concluding that:

* **No embedded symbol names or strings survive** anywhere in the ACEF file
  (established when the symbol table was first decoded — see below).
* **The call graph doesn't help much**: Am29000 control flow here is
  dominated by conditional branches (`jmpt`: 5,149) and *indirect* calls
  (`calli`, register-based: 1,155) over direct/resolvable calls (`call`:
  555) — more than 2:1 indirect, so a call-graph-based naming pass surfaces
  very little without full data-flow tracing (not attempted).
* **Cross-referencing `gc24.s`'s 106 "Am29000 command code" dispatch values
  against the 768 known function-start addresses**, hoping they were direct
  `.text` offsets, found essentially no correlation (1/106 — consistent with
  random chance) — those command codes are opaque values the firmware's own
  dispatch logic interprets, not addresses into it.

What **was** found, and is real: scanning every instruction's destination
operand for an architecturally-impossible write to `gr0` (see above) surfaces
**32 violations clustered in just 15 of the 768 functions** — mechanical,
strong evidence those specific byte ranges are compiler-embedded literal/
lookup tables (gamma curves, dither patterns, or similar — plausible for a
QuickDraw accelerator) rather than executed code, even though most of each
flagged function's *other* bytes still decode as sensible instructions. Each
is flagged inline in `disasm/text.asm` at its `sub_XXXXX:` label with a
violation count. `am29k_dasm.py --syms` now runs and reports this check
automatically.

Given all three avenues came up short of real per-function names, the
`sub_XXXXX` (address-based) naming is kept as the honest baseline rather
than inventing role names without evidence.

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
*addresses* survive. That is still a real gain: `disasm/text.asm` now marks all
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
