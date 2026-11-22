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

`firmware_image.bin` (254 KB) + `firmware_image.map.txt` is a flattened,
relocation-patched image — see "COFF relocations" below for how it's built
and why the sections all report `vaddr` 0.

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
| `Vec` | `0x4C000000` | 1 KB table (256 longs) — **contents unexplained**, see below |
| `PublicIn` / `PublicOu` | `0x4C006400/6800` | host↔card command in/out |
| `HifComm` | `0x4C007000` | host-interface comm block |
| **`VidComm`** | **`0x4C007300`** | **video command block (= ROM's `$0C007300`)** |
| `InitMap` / `InpArgs` | `0x4C007400/7800` | init map / input args |
| `Private`,`PrivNZ`,`Apple` | `0x4C0025xx` | private state |

Sections span two address regions (`0x2000000` SRAM/cache and `0x4C000000`
register/comm space), so they are kept as separate `.bin` files rather than one
flat image.

**No relocations to apply here.** Unlike `ACEF_100_Antelope`, this file's
header carries `symptr=0`/`nsyms=0`, and every one of the 13 section headers
decodes `nrel=0` — confirmed against `ACEF_1`'s own `vaddr` fields exactly
matching the fixed hardware addresses above (e.g. `Boot` at `0x2003000`,
`VidComm` at `0x4C007300`), so the decoder is reading real data, not garbage.
This makes sense: `Runtime` is the always-resident kernel the card boots
into, pre-linked to its fixed SRAM/register map, while `Antelope` is a
loadable, relocatable accelerator module — which is exactly why *it* needed
6,613+ relocation records and this one needs none.

`Boot` and `Hand` are `Runtime`'s only actual code sections (everything else
is a comm/register block or private state); disassembled the same way as
`ACEF_100_Antelope`'s, minus any relocation pass since there isn't one:

* [`disasm/Boot.asm`](disasm/) — the Am29000 boot code (512 instructions,
  99.2% decode as valid; the gr0-write check flags 1 embedded-literal
  instruction plus a trailing 4-word data table).
* [`disasm/Hand.asm`](disasm/) — the interrupt/trap handler bank (2,885
  instructions, **100%** decode as valid; the gr0-write check flags 4
  embedded-literal instructions). Ends in an `iretinv`, consistent with a
  handler-table body.

No symbol table means no `sub_XXXXX:` function boundaries in either file —
only `L_XXXXXXX:` labels for in-section branch/call targets, same as
`Code.asm`.

### `Boot` analysed: it jumps into memory this file doesn't contain

Tracing every branch in `Boot.asm`: entry does an early config-bit test and
branch, then some early `mtsr`/`mtsrim` writes (unambiguously hardware/cache
setup, though SPRs 88/89/122/124 aren't in this project's name table so the
specific bits aren't claimed), then a long, repetitive `const`/`consth` +
`load` + rotating-accumulator `add` pattern — the shape of an unrolled copy
or checksum pass, though which one isn't established (the constants involved
don't consistently form addresses in any mapped region).

The real finding is in the branch *targets*. Classified against the memory
map above: 5 land cleanly inside `Hand` (unsurprising — calling into
interrupt-handler setup); 6 land in the small gap between `Hand`'s end
(`$2002d14`) and `Boot`'s start (`$2003000`); and **~43, densely packed from
`$2003954` to `$2003e38`, land inside what the section table calls `Cache`**
— declared `bss` in this ACEF, and confirmed genuinely empty on disk (its
`scnptr` is a leftover alias of the next section's file offset, the normal
COFF convention for empty bss, not a missed-extraction bug).

> **Superseded.** This section originally concluded that `Boot` shadows a
> second stage into `Cache`. Later work (see "Is `Boot`/`Hand` assembler output
> at all?" and "`Vec` is a keystream" below) shows the section bytes carry a
> second masking layer, so the decoded jumps -- including the ones into
> `Cache` -- are not trustworthy and no missing payload need be assumed. The
> branch-target counts above remain as a record of what the *unmasked* decode
> shows; the inline `-> UNMAPPED` flags in `disasm/Boot.asm` are likewise
> artefacts of that decode.

### Is `Boot`/`Hand` assembler output at all? (evidence says no)

Follow-up on the `Cache` question above: the thing that looks wrong is not a
missing payload but the *code itself*. An assembler leaves an instruction's
don't-care fields zero. Counting that over the raw sections:

| instruction (ignored field) | `Hand` | `Boot` |
|---|---|---|
| `iret` (all 24 operand bits) | 0 of 74 zero | - |
| `mfsr` (RB byte) | 1 of 113 zero | 0 of 1 |
| `mtsr` (RC byte) | 11 of 120 zero | 2 of 2 |

74 `iret` instructions in 2,885 words, with garbage in every one of their
ignored fields, is not hand-written handler code. The SPR numbers used by
`Hand`'s `mtsr`/`mfsr`/`mtsrim` spread over 154 distinct values across 0-255
(only SPRs 0-14 and 128-135 are architecturally defined on the Am29000), so
**SPRs 88/89/122/124 in `Boot` are not a missing name-table entry**: SPR
numbers in this code are essentially arbitrary. The ~43 `jmp` targets into
`Cache` are then just random targets of random branches, which also explains
why they land everywhere (`Hand`, the gap, `Cache`) with no structure.

Caveat found while testing this: a crude "reads a register nothing wrote"
statistic scores `Boot` 73% but also real `Antelope` code 77-86% (register
windows), so it is **not** evidence either way and was discarded. The
don't-care-field test above is the one that holds up, but it only shows the
opcode bytes were chosen and the operands filled with noise -- and the `Apple` section shows that noise is a second mask
(`Vec` as keystream, next section), so `Boot`/`Hand` are probably real code
that is still masked. They should not be labelled as handlers until unmasked.

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

## `Vec`, `PublicIn`, `PublicOu`: noise-masked data (open puzzle)

These three Runtime data sections do **not** look like what their names
suggest. All three share one pattern: 17-bit values whose high bits descend
in a regular staircase (`0x7C..`, `0x78..`, `0x74..`, … a drop of `0x400`
per step, repeating every 24 entries with a `0x1000` shift, then a second
run from `0x1BC..` down to `0x80..`) and whose low 10 bits look random.
`Vec`'s 252 entries are all 4-aligned and distinct; they match no function
symbol, no relocation site and no particular instruction class in Antelope's
`.text` (checked), so they are not code pointers in any plain sense.

What *is* solid:

* `PublicOu` word 0 is the real constant **`$32100456`** — the "card is up"
  signature `DRVR.s`'s `Init29K` waits for at `image+$400`. That fixes the
  host-side image base as the `PublicIn` section (`0x4C006400`; the host
  reaches it at slot-base `+0x0C006400`), so every handshake offset in
  `DRVR.s` (`+$18`, `+$00`, `+$08`, `+$14`, `+$40`, `+$3D4`, `+$40C`) is a
  field of `PublicIn`/`PublicOu`.
* `PublicOu+$0C` reads `0x4C007112` (inside `HifComm`), `+$10` `0x4C007AFD`,
  `+$14` `0x4C0070AF`: plausible pointers whose low bits are noise. The host
  reads `+$40C` as the mailbox address, so the static values are probably
  placeholders the card overwrites at run time.
* `PublicOu` from `+$50C` holds text-like bytes interleaved with noise
  (two ASCII-range bytes, two high bytes per word) that does not decode as
  a plain string.

**New structural facts (period and stride).** Skipping the 4 header words,
`Vec[n+24] - Vec[n]` is exactly `-0xC00` for 203 of 228 pairs (the rest are
the wrap, `+0x17400`), i.e. `Vec[n] = C - 0x80*n + j(n mod 24)`: a descending
**128-byte stride** (252 entries x 0x80 ~ 0x7E00, almost exactly the 32 KB
`0x4C000000` window) plus a 24-entry jitter pattern that is itself made of
ascending runs of 9-10 entries. `PublicIn`/`PublicOu` follow the same
`-0xC00`-per-24 rule only approximately (their jitter is additionally
perturbed by 7 low-order noise bits). So the three tables are three noisy
renderings of one 128-byte-stride address sequence; what the stride addresses
*mean* is still unknown. (Rules out: not a vector table, not plain data.)

### `Vec` is a keystream: the Runtime sections have a second mask

`Apple.bin` (77 bytes) reads, in the high 16 bits of its words 4-18: `Co ri
"t " ") " 89 Ap "e " mp er In " A" " R" ht Re rv` -- every *other* two-character
chunk of "Copyright (c) 1989, Apple Computer, Inc. All Rights Reserved". The
missing chunks are in the low 16 bits, XORed with a keystream. That keystream
is the low half of `Vec.bin`'s words with the same index:

    word  low16   Vec[k]  low16^Vec[k]
      4   0x733d  0x0344  0x7079 'py'
      5   0x1bf0  0x7c98  0x6768 'gh'
      6   0x54f3  0x7c90  0x2863 '(c'
      7   0x4dd5  0x7cec  0x3139 '19'

All 15 words from index 4 on decode to the missing chunks (`py gh (c 19 ", "
pl Co ut ", " c. ll ig "s " se ed`). So the three "noise" tables are not noise:
`Vec` is (a copy of) the keystream, i.e. an all-zero section masked with
itself. Words 0-3 of `Apple` do not decode this way (they are likely a
header). Antelope's own `Apple` section (88 bytes) holds the same text with
the same plaintext high halves but a *different* low-half keystream, so each
ACEF has its own.

**The keystream's structure (partial).** For `k >= 5`, `Vec[k]` is exactly
`J[(k-5) mod 24] - 0x80*k`, plus `0x18000` once `k >= 133`, where `J` is this
24-entry table (the values from `k = 5`):

    7f18 7f90 806c 8078 8248 8384 8508 8540 7f0c 7f88 8058 8004
    8198 8250 83ac 8478 8588 8644 7f88 8000 824c 8388 8518 8544

(`Vec[4] = 0x344` fits the same formula with `J = 0x8344`.) So the keystream
is a 128-byte-stride address ramp with a fixed 24-entry jitter; the `+0x18000`
step at `k = 133` is where the ramp passes below `0x4000`.

The same family shows up in `Hand`. If each of its 74 `iret` words (whose
operand bits must be zero in real code) is read as `key = low24(word)`, then
`(key + 0x80*k - J[(k-5) mod 24]) / 0x8000` is within about 0.06 of an integer
for all 74 -- 4, 7, 8, 11, 12, then 255/256 for the last ones -- so the mask
on `Hand` is `0x8000*n(k) - 0x80*k + jitter`, with `n` a slowly varying
step function and the 24-entry jitter close to, but not exactly, `J`. The
step function `n(k)` and the exact jitter for `Hand` are not yet determined,
so `Hand`/`Boot` still cannot be unmasked. Next step: fit `n(k)` and the
jitter from the `iret` (and `mfsr`/`mtsr` RB/RC) samples, then check that the
unmasked words disassemble with zero don't-care fields.

**Further fit on `Hand` (still unsolved).** Writing each `iret` key as
`key = 0x80*m(k) + col(k mod 24)`, the low 7 bits (`col`, a 4-aligned
column inside a 128-byte line) are a stable per-phase constant -- every
alternative value seen for a phase differs by a multiple of 0x80, never in the
low 7 bits. From the 74 samples, `col` by `k mod 24` is:

    0:00 1:60 2:64 3:40 4:68 5:5c 6:70 7:50 8:04 9:10 10:38 11:5c
    12:20 13:00 14:64 15:20 16:48 17:1c 18:10 19:70 20:04 21:30 22:58 23:1c

(phases 2 and 4 rest on one or two samples). This table is **different from
`Vec`'s** (`Vec`'s columns are 18 10 6c 78 48 04 08 40 0c 08 58 04 18 50 2c 78
08 44 08 00 4c 08 18 44 by `(k-5) mod 24`), so the column table is not shared
between `Vec` and `Hand` even though the structure is the same -- yet `Apple`
decodes with `Vec`'s. The row part `m(k)` descends by about one per word with
occasional extra steps of 0x80 and jumps of 0x18000 (seen at k ~ 648, 1160 and
1681), and the 74 samples are too sparse to reconstruct it for all 2,885
words. One sample (k = 1537) sits about 0x7e00 below the surrounding ramp and
may not be a genuine `iret`. Candidate next experiment: use `mtsr` words
(operand RC must be 0, which pins key bits 16-23) and `mfsr`/`halt` words to
add samples, then fit `m(k)` per 24-word block.

**Result: bits 0-14 of the `Hand` mask are now determined (for 79% of words).**
Adding `iretinv` words and re-fitting with period 48 for the row part (not 24;
the same `k mod 24` phase gives two different rows 24 words apart), the key is

    key(k) = 0x80*m(k) + COL[k mod 24]          bits 0-6  = COL (24 constants)
    m(k) mod 256 = (ROW[k mod 48] - k) mod 256  bits 7-14 = ROW (38 of 48 known)

`COL` and `ROW` are in [`../unmask_runtime.py`](../unmask_runtime.py). Held-out
check (not used in the fit): after unmasking, **all 86 `mfsr` words whose
phase is known have RB == 0**, as an assembler would emit; earlier, all 113
`mfsr` words had low 7 bits equal to `COL` and all 89 whose phase was known
had the predicted bit 7. Bits 15-23 of the key (the 0x8000 / 0x18000 steps
and a one-word excursion at k = 1537) and 10 of the 48 `ROW` phases (2, 4, 17,
18, 22, 34, 37, 38, 40, 43) are still unknown, so the script outputs a
`.low15.bin` plus a `.known.bin` mask and does not claim a full unmask. Each
unmasked word therefore has its RB field and the low 7 bits of RA valid, but
not RC (the register field) -- so a full disassembly is still out of reach.
`Boot` has not been checked against these constants (it has almost no
`mfsr`/`iret` words to test with).

**Bits 15-23 (partial).** Writing `key = 0x8000*N(k) + 0x80*(ROW[k mod 48] - k)
+ COL[k mod 24]` with `ROW` taken as a signed small number, the remainder is
exactly 0 for all 80 `iret`/`iretinv` samples with a known phase, so the
decomposition is exact and only `N(k)` is left. Its values, by k:

    64:1   284-365:5   400-452:4   551-643:5   648-747:8   1054-1145:9
    1160-1284:12   1302-1646:13 (1537: 12)   1681-1775:256   1802:257   2449:260

`N` is not monotone (5, 4, 5 around k = 400), jumps by 3 at k ~ 646 and
~ 1150 and by 243 at k ~ 1660, and has a one-word excursion at k = 1537. The
`mtsr` words (RC must be 0) show that `key >> 16` is a clean staircase 0, 1, 2,
3 with plateaus of about 512 words whose edges fall near k = 128, 646 and 1152,
so the mask's high bits follow a rule of the same address-ramp kind as `Vec`'s
(`+0x18000` whenever the ramp drops below a window edge); the edge for `Vec`
is `0x4000`, and for `Hand` the edges appear to be `0x14000`, `0x24000`, ...
(rising by `0x10000` per jump). I have not turned that into a generator that
reproduces all 200 high-bit samples, so bits 15-23 remain masked in
`unmask_runtime.py`.

**Smooth-ramp view and Antelope's keystream.** Removing the exactly-known
jitter, `s(k) = key - 0x80*ROW - COL = 0x8000*N(k) - 0x80*k` falls by exactly
0x80 per word inside every plateau (checked over 80 samples), and only jumps by
multiples of 0x8000. Between samples the jumps are `+0x20000` (k 64..284),
`-0x8000` (365..400), `+0x8000` (452..551), `+0x18000` (643..648), `+0x8000`
(747..1054), `+0x18000` (1145..1160), `+0x8000` (1284..1302); the `+0x18000`
steps happen where `s` falls to about `0x13e00` and `0x24000`, but the
`+0x8000` steps do not sit at one fixed `s`, so a single threshold rule does
not reproduce them. Antelope's `Apple` section, decoded the same way with the
text "32-Bit Antelope Copyright (c) 1989, Apple Computer, Inc. All Rights
Reserved", gives a keystream of 0x93, 0x3c4, 0x3e6, 0x259, 0x2bc, 0x1d70,
0x1de3, 0x1cc0, ... (not 4-aligned, no 0x80 ramp), so Antelope uses a different
generator from `Runtime` and does not help pin `Hand`'s rule.

**Independent confirmation: the SPR numbers become real.** Applying the
partial unmask to the `RA` field (bits 8-14) of every `mfsr`/`mtsr`/`mtsrim`
whose phase is known gives **217 samples in `Hand`, every one in 0..14** --
exactly the Am29000's protected special registers (0 VAB, 1 OPS, 2 CPS, 3 CFG,
4 CHA, 5 CHD, 6 CHC, 7 RBP, 8 TMC, 9 TMR, 10 PC0, 11 PC1, 12 PC2, 13 MMU,
14 LRU) -- where the masked values had been spread over 0..255. The fit never
looked at this field, so it is a held-out test of both the key and the
decomposition (bit 15 of `RA` is still masked, so an SPR >= 128 would show as
its low 7 bits; none appear). `Hand` is therefore real interrupt/trap-handler
code: 80 `iret`/`iretinv` words terminate its handlers (the first at word 64),
and the SPRs it touches are mostly CHC (38), OPS (32), CPS (19), CHA (17) and
PC0/PC1 (16 each) -- the channel and program-counter state a trap handler
saves and restores. `unmask_runtime.py --sprs` prints them.

**`Boot` uses the same mask.** Its five SPR instructions, read with the same
key (word index counted from the start of `Boot.bin`), become `mtsrim CHA`,
`mtsrim CPS, $04f7`, `mtsr VAB`, `mtsr CFG` (one more is in an unknown phase) --
a plausible early-boot sequence, where the old reading had `spr124`, `spr122`,
`spr89`, `spr88`. This retracts "unreliable SPR numbers" for `Boot`: they were
masked values, and the earlier note that they were not in the name table is
explained. The rest of `Boot` and `Hand` (registers and immediates in bits
15-23) is still masked.

### Reading `Hand`'s structure from the SPR sequences

Cutting `Hand` after each `iret`/`iretinv` (plus its delay slot) and listing the
special registers each piece touches -- the only fields readable today --
gives routines that are recognisable even with registers masked
(word index `k`, address `0x2000000 + 4k`; `unmask_runtime.py --sprs` prints
the raw sequence):

* **k 0-64, the entry/exit stub (0x2000000).** `mfsr PC0`, `mtsrim CPS`,
  `mfsr/mtsr CFG`, `mfsr CHA`/`CHC`/`CHD`, `mtsr VAB`, `mtsr CHC`, then
  `mtsr PC1`, `PC0`, `OPS` before the `iret`: save the channel state, adjust
  CPS/CFG/VAB, restore PC and OPS -- a generic trap entry/return path.
* **k 66-284 (219 words) and k 296-365:** the same save/restore skeleton with
  `RBP` and `VAB` toggles (`mfsr VAB; mtsr VAB; mtsr VAB` repeated) around an
  `OPS` save: trap handlers that switch register-bank protection.
* **k 774-1054 (281 words):** only `CFG` and `CHC` touched -- a longer routine
  that works with the channel registers but does little special-register
  traffic; the shorter pieces between k 1105 and 1750 mostly touch `OPS`/`CHC`/
  `TMR` once or not at all (small handlers, possibly just a few instructions).
* **k 1804-2449 (646 words, 0x2001c10-0x2002624): the reset/initialisation
  routine.** `mtsrim CPS`, `mtsr CPS` x2, `mtsrim RBP` x3-4, `mtsrim TMR`/`TMC`,
  `mtsrim MMU` x3, `mtsrim/mtsr CFG` x5, `mtsrim CHC`, ending with `mtsr PC1/PC0`:
  program the processor status, register-bank pointer, timer, MMU and
  configuration registers, then return -- the structure of a processor reset
  routine, and `Boot`'s jump targets into `Hand` ($2001c10..$2002624 region)
  would land here.
* **k 2451-2884 (434 words, 0x2002624-0x2002d14): a full context
  save/restore.** It reads `PC0, OPS, CHC, CHA, CHD, VAB, CPS, RBP, TMR, PC2,
  MMU, CFG, LRU` (in that order, twice) and ends with a long run of `mtsr` that
  writes back `VAB, OPS, CPS, CFG, CHA, CHD, CHC, RBP, TMC, TMR, PC0, PC1,
  PC2, LRU`: saving and restoring the whole protected-SPR set, i.e. a context
  switch or a "dump and return" handler.

What this does *not* establish: registers, immediates and jump targets are
still masked (bits 15-23), so which trap number each handler serves, what it
loads or stores, and how the routines call each other is unknown. Labels in
`disasm/Hand.asm` would therefore be guesses; the routine boundaries above are
from `iret` positions, whose opcode byte is not masked.

What this does **not** solve: the same keystream applied at any offset to
`PublicIn`, `PublicOu`, `PrivNZ`, `Boot` and `Hand` does not give zeros or
valid code (best offset scores 1 hit), and `Hand`'s `iret` words have non-zero
bytes in their high halves too, so the code sections are masked differently
(or over more bits) than `Apple`. `PublicIn`/`PublicOu` after XOR with `Vec`
become small integers (mostly under 0x800) -- plausibly real data, with
residual noise in the low ~10 bits -- but `PublicOu` word 0 (`0x32100456`,
which the host matches exactly) must be left unmasked, so words 0-3 are
probably outside the mask. The generator for `Vec` beyond its 252 words
(needed for the 2,885-word `Hand`) is unknown. Until the code sections can be
unmasked, disassembly of `Boot` and `Hand` should be treated as unreliable;
`Antelope`'s `.text` is unaffected (it is real compiled code and decodes
coherently).
