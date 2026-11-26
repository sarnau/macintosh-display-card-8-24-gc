# How the Macintosh Display Card 8·24 GC works

A summary of the whole card, as read from its software: the declaration ROM,
the Mac-side driver and QuickDraw patches, and the card's own Am29000
firmware, all of which are decoded exactly. The details and the evidence are
in [`control-panel/HOST_CARD_PROTOCOL.md`](control-panel/HOST_CARD_PROTOCOL.md)
(the protocol and the firmware), [`control-panel/firmware/`](control-panel/firmware/)
(the listings) and [`control-panel/README.md`](control-panel/README.md) (the
Mac-side programs).

## The idea

The 8·24 GC is a NuBus video card that also draws. It carries an AMD
Am29000 RISC processor running a C port of 32-Bit QuickDraw. When the card's
software is active, the Mac's QuickDraw hands it the work behind CopyBits and
the shape and text calls. The card draws into its own frame buffer, or into
pixel maps in its own memory, while the 68k goes on. When the card cannot do
a call, the Mac draws it itself, so nothing depends on the card handling
everything.

## The hardware, as the software sees it

| card address | host address | what |
|---|---|---|
| (instruction side) | slot base + 0 | 64 KB SRAM (8 × Motorola MCM6295, 16K×4): fast instruction memory for the Am29000 ("instruction cache" in Apple's papers); the host tests 128 KB there and needs 64 KB. Where the Am29000 sees it is not settled from the code |
| `$4C000000`-`$4C1FFFFF` | slot base + `$0C000000` | 2 MB video memory (16 × Toshiba TC52425x, 256K×4), also the program memory on a stock card. The first 64 KB hold the kernel's shared areas (vector table, service table, `PublicIn`/`PublicOut`, the mailbox, the video command block, the command packet at `$4C008C00`); the frame buffer starts at `+$10000` |
| `$4C200000`.., `$4D000000`.. | slot base + `$0C200000`.., `$0D000000`.. | DRAM on two optional 64-pin SIMMs (empty on a stock card; Apple's kit adds 2 × 1 MB, third-party SIMMs up to 8 MB): more room for off-screen pixel maps, caches and the heap; the host probes how much |
| `$4C400000`.. | | the video memory's block-write alias (fills with one colour per write) |
| `$44000000`.. | slot base + `$04000000` | card registers: layout, interrupts, display start and row bytes (`$44000000`, `$440000A0`), the Am29000's run control (`$44000028`) |
| `$46800000` | slot base + `$06800000` | the DP8531 clock synthesiser |
| `$46C00000` | slot base + `$06C00000` | the RAMDAC (a Brooktree part marked "RAMDAC 428", 357S0010-A, ©88 Apple; the AC842 of Apple's papers): colour-table index, data (R, G, B in turn) and pixel mode, on data bits 31-24 |
| `$02000000`.. | | the kernel's code (`Hand` at `$2000000`, `Boot` at `$2003000`) |
| low addresses | the Mac's memory | read and written over NuBus (host pixel maps, handles) |

The frame buffer has two layouts, linear and 4-way word-interleaved; the
video driver picks one per monitor and depth, and the card's fills and
copies take faster paths in the linear one.

## Video modes

The declaration ROM's video driver sets each mode up from a table: the
RAMDAC's pixel mode, the layout, the display start and row stride, and 15
values for the timing chip (horizontal active, back porch, sync and front
porch; the same four vertically, in half-lines; and a few composite-sync
values for TV). It is the same timing chip layout as the original 8•24's.

| monitor | resolution | depths | total (pixels × lines) | refresh |
|---|---|---|---|---|
| Two-Page | 1152×870 | 1-8 | 1456 × 915 | 75 Hz |
| Portrait | 640×870 | 1-8 | 832 × 918 | 75 Hz |
| 13" | 640×480 | 1-24 | 864 × 525 | 66.7 Hz |
| 12" | 512×384 | 1-24 | 640 × 407 | 60 Hz |
| NTSC | 640×480, 512×384 | 1-24 | 780 × 525, interlaced | 30 Hz frames |
| PAL | 768×576, 640×480 | 1-8 (768×576), 1-24 (640×480) | 944 × 625, interlaced | 25 Hz frames |

The refresh rates follow from the totals and the pixel clocks the ROM
programs. The pixel clock comes from a National DP8531 synthesiser (20 MHz
reference; 100, 57.27, 30.24 and 15.67 MHz for the four monitors, 4 × the
dot clock on TV): PrimaryInit loads it for the sensed monitor, and TV modes
reload it. At 1-8 bits TV modes use the interleaved layout and set the
RAMDAC mode's bit that System 7.1's source for the original 8•24 calls
convolution, its anti-flicker filter. In 24-bit modes the RAMDAC's colour
table acts as a gamma lookup per channel.

## Two programs on the card

Both are stored in the control panel's `ACEF` resources, a repacked AMD 29K
COFF format that the Mac driver decrypts while loading (a running 32-bit XOR
key per section; [`control-panel/SECOND_MASK.md`](control-panel/SECOND_MASK.md)).

* **Runtime**, the kernel (hand-written assembly, about 3,400 words). `Boot`
  waits for the host's go-ahead, sets up the vector table and the board
  parameters and starts `Hand`. `Hand` handles traps and interrupts
  (including a software-managed TLB with a pager), the timer, the video
  command block, a mailbox for fatal-error reports, and 33 services that the
  accelerator calls (memory regions and address translation, interrupt
  handlers, the RAMDAC, display start and row bytes, the host flags).
* **Antelope** ("32-Bit Antelope"; its messages call it PQD and Monet), the
  accelerator: 243 KB of C (25 of Apple's source files with debug
  information) plus AMD's C library, HIF system-call stubs and millicode,
  linked by the Mac driver at load time. All 709 of its functions are named; most are
  QuickDraw's own routines, in the same table order as the 68k source:
  BitBlt, RgnBlt, StretchBits and scaleBlt with their transfer-mode loops,
  the slab and pattern code, GetSeek and the region code, DrawLine, DrawArc,
  the polygon code, DrawText, ColorMap.

## Start-up

1. The driver (`.GraphAccel`, `DRVR` in the control panel) holds the
   Am29000 (0 to `$44000028`), tests the card's memory, uploads Runtime,
   writes its feature flags and memory limits into `PublicIn`, pokes the
   go-ahead `$42005300` and arms the mailbox with `'s337'`.
2. It uploads and links Antelope into the top of card memory (the VRAM
   above the frame buffer on a stock card) and records its entry point
   in `PublicIn`.
3. It writes -1 to `$44000028` and the Am29000 runs: Boot finds the go-ahead,
   sets up the kernel and jumps to Antelope. Its `main` finds the command
   packet through `PublicOut+$18`, the same address (`$s08C00`) the host
   uses, and enters the command loop. Turning the accelerator off writes 0
   again.

The feature flags (from the control panel's `PupS` resource and the card
type) switch processor and kernel features: paging, supervisor mode,
unaligned-access emulation, the timer, a floating-point coprocessor, and
several debug options, off by default.

## How drawing reaches the card

The QuickDraw patches (`gc24`) talk to the card through the command packet
in card memory:

* **Commands.** For CopyBits/StretchBits and for keeping the card's caches of
  host objects up to date (GDevices, colour tables, inverse tables, pixel
  patterns, offscreens, fonts), the host writes a selector and arguments and
  waits. The card replies "done" (1) or "not handled" (0, the Mac draws it).
* **The drawing stream.** Lines, rectangles, ovals, round rectangles, arcs,
  polygons, regions and text are not sent one by one. The host appends
  records to a buffer in card memory, and the card plays them back
  (DrawMultiObject, 25 opcodes): it clips, maps colours, expands patterns and
  draws. For text, the host measures and uploads the fonts; the card draws
  the glyphs.
* **Requests back to the host.** The card can ask the Mac for Memory Manager
  calls, resources, colour searches, `MakeITable`, locking host memory, and
  block copies. The host serves them from its wait loops.

The card reads host pixel maps and handles directly over NuBus where it
can, translating addresses through the host's memory map when virtual
memory is on, or asks the host to copy them. Card and host share the cursor
through a lock: the card hides it before drawing over it and asks the host
to show it again.

Programs on the Mac can also load their own code onto the card through the
patches' module interface and run it as tasks; such code gets the
accelerator's entry table (BitBlt, RgnBlt, the shape drawers, text,
DrawMultiObject, address mapping).

## Debug switches, dead code and bugs

* Five of the kernel's feature-flag bits are debug switches that nothing
  sets: a floating-point coprocessor (initialised or not), instruction
  counting by tracing, a data watchpoint on unmapped memory, and giving up
  a failed bus access instead of retrying it.
* The kernel service that moves the display start (`$C6`) has no caller;
  it would disagree with Boot by a factor of 2 in the interleaved layout.
* When the host gives up on the card it records a reason that nothing reads,
  and the loop that puts the original QuickDraw routines back advances its
  index by 1 instead of 4, so only the first one is restored correctly
  (`gc24` `$765E`). Its alert asks for a restart anyway.
* One give-up reason can never happen (its test routine always returns 0),
  and another, "no room for the drawing-stream buffer", would spin rather
  than give up, because its retry size wraps past 0.

## The two software releases

The System 6 package (8•24 GC SW 1.1, built January 1991) and the System 7
one (7.0.1, built April 1992) share most of the card code: 620 of about 770
functions are identical. System 6's kernel is a slightly older build.
System 6's accelerator has placeholders for the 16-bit arithmetic transfer
modes, which System 7 fills in, and carries a QuickTime Apple Video
(`'rpza'`) codec that runs on the card (decompression and compression of
16-bit frames, plus a private `'rle '` format), which System 7 dropped in
favour of the host-loaded modules.

## Who built it

The kernel's `PublicOut` section credits Apple's Special Projects Group
(SEG): hardware by Tony Masterson, Rob Pugh and Dean Drako, software by
Jean-Charles Mourey, Mark Krueger and Rekha Sh… (the text is cut off at the
section's end). The firmware was built with AMD's 29K tools: COFF objects,
AMD's calling convention and library, and most likely the MetaWare High C 29K
compiler.
