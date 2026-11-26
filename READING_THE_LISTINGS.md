# Reading the listings

A short guide for a first visit. For what the card does, start with
[`HOW_IT_WORKS.md`](HOW_IT_WORKS.md); this page is about finding your way
in the code.

## Where to start

| you want to know | open |
|---|---|
| how a QuickDraw call reaches the card | `control-panel/gc24.s` (the patches; each patch has a `* Patch #n replaces _Trap` banner), then `EngineDispatch` (`$49C4`) |
| what the card does with a command | `control-panel/firmware/disasm/text.asm`, the dispatcher `sub_31e20` (CommandDispatcher), then the named handler |
| how the drawing stream is played | `text.asm`, `DrawMultiObject` (`$0AD18`), and the "DrawMultiObject" chapter of `control-panel/HOST_CARD_PROTOCOL.md` |
| how the card is started | `control-panel/DRVR.s` (`Init29K` `$23CC`, `ACEFLoad`), then `control-panel/firmware/disasm/Boot.asm` and `Hand.asm` |
| what a kernel service does | `control-panel/firmware/disasm/RuntimeData.asm` (the service table), then `Hand.asm` |
| how a video mode is set | `extracted-source/VideoDriver.s` (`JMFBSetDepth`, `sub_5fd4`) and section 10 of the protocol doc |
| System 6 | `control-panel/gc24_sw11.s`, `control-panel/firmware/sw11/` |

The protocol document's "Where to read what" table points into its own
sections; its overview names the important functions with addresses.

## The two kinds of listing

**68k** (`gc24.s`, `DRVR.s`, `cdev.s`, `INIT_*.s`, `extracted-source/*.s`,
`gc24_sw11.s`): one instruction per line,

```
  005f32:  70 08                moveq    #$8, d0
```

offset in the resource (or ROM), the bytes, the instruction, and a comment
after `;`. Comment blocks start with `*`. Labels are `sub_xxxx` (call
targets), `Lxxxx` (branch targets) or names (`EngineDispatch`, `GA_<trap>`
for a patch handler, `Ctl_…`/`Sts_…` for driver calls). `[name]` in a
comment tags a field of a known structure. The `.s` files are annotated by
hand; only their comments change, never the address or byte columns.

**Am29000** (`firmware/disasm/*.asm`, `firmware/sw11/disasm/*.asm`):

```
  31dac:  25010118  sub      gr1, gr1, $18
  2e3d4:  03006000  const    gr96, $0000   ; lo of .text $32ab8 (ReleaseHostEarly)
```

address, the 32-bit word, the instruction. Things to know:

* **Delay slots.** The instruction after a jump or call runs before the
  jump takes effect; the listing marks it `; [delay slot]`. `iret` has
  none.
* **Relocations.** Antelope is relocatable; a `const`/`consth` pair loading
  an address shows `0` in the word and its target as `; lo of …` /
  `; hi of …`. `extern#N` is an undefined symbol (a `.comm` variable).
* **Labels.** `sub_XXXXX` is a function from the symbol table, with its
  name after `;` (from `control-panel/antelope_names.py`); `L_XXXXX` is a
  jump target; `file_NN` the start of an object file, under a banner naming
  the subsystem. `svc_XX_Name` are the stubs that call kernel services.
* **Tag words.** A `.word` before each function (`tag word: N arguments,
  frame $F`) is AMD's calling-convention marker, never executed.
* **Calling convention.** Arguments arrive in `lr2`, `lr3`, …; results in
  `gr96`; `lr0` is the return address; `gr1` the register-stack pointer.
* `Hand.asm` and `Boot.asm` are annotated by hand; `text.asm`, `lit.asm`,
  `data.asm`, `Code.asm` and `RuntimeData.asm` are generated (see the
  README's "Rebuilding the generated files").

## Addresses

| form | means |
|---|---|
| `$4Cxxxxxx` | card memory as the Am29000 sees it (VRAM from `$4C000000`) |
| slot base + `$0Cxxxxxx`, `$sCxxxxxx` | the same memory from the Mac (`s` = slot) |
| `$44xxxxxx`, `$46xxxxxx` | card registers (host: slot base + `$04…`, `$06…`) |
| `$02000000`-`$0200FFFF` | the kernel's code in the SRAM (instruction side) |
| `$xxxxx` in `text.asm` | an offset in Antelope's `.text`; where it runs depends on the loader |
| `.lit+$xxxx`, `.data+$xxxx` | offsets in those sections |
| `packet+$xx`, `+$xx` | offsets in the command packet at `$4C008C00` |
| `unit+$xxx`, `globals+$xxx` | the driver's per-card record and its globals |
| `PublicIn+$xx`, `PublicOut+$xx` | the kernel's shared areas at `$4C006400`/`$4C006800` |

Hex is written `$1234`. "System 7" means the 7.0.1 package, "System 6"
the 8•24 GC SW 1.1 package. *reading* in the docs marks an interpretation
the code does not prove by itself; **verified** means both sides were read
and agree.
