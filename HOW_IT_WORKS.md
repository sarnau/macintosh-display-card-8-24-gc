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
| `$4C000000`-`$4C1FFFFF` | slot base + `$0C000000` | 2 MB video memory. The first 64 KB hold the kernel's shared areas (vector table, service table, `PublicIn`/`PublicOut`, the mailbox, the video command block, the command packet at `$4C008C00`); the frame buffer starts at `+$10000` |
| `$4C200000`.., `$4D000000`.. | slot base + `$0C200000`.., `$0D000000`.. | DRAM (off-screen pixel maps, caches, the heap); the host probes how much |
| `$4C400000`.. | | the video memory's block-write alias (fills with one colour per write) |
| `$44000000`.. | slot base + `$04000000` | card registers: layout, interrupts, the pixel-clock chip (`$440000A0`) |
| `$46C00000` | | the RAMDAC (colour table) |
| `$02000000`.. | | the kernel's code (`Hand` at `$2000000`, `Boot` at `$2003000`) |
| low addresses | the Mac's memory | read and written over NuBus (host pixel maps, handles) |

The frame buffer has two layouts, linear and 4-way word-interleaved; the
video driver picks one per monitor and depth, and the card's fills and
copies take faster paths in the linear one.

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
  handlers, the RAMDAC and pixel clock, the host flags).
* **Antelope** ("32-Bit Antelope"; its messages call it PQD and Monet), the
  accelerator: 243 KB of C (25 of Apple's source files with debug
  information) plus AMD's C library, HIF system-call stubs and millicode,
  linked by the Mac driver at load time. All 709 of its functions are named; most are
  QuickDraw's own routines, in the same table order as the 68k source:
  BitBlt, RgnBlt, StretchBits and scaleBlt with their transfer-mode loops,
  the slab and pattern code, GetSeek and the region code, DrawLine, DrawArc,
  the polygon code, DrawText, ColorMap.

## Start-up

1. The driver (`.GraphAccel`, `DRVR` in the control panel) probes the card,
   uploads Runtime, writes its feature flags and memory limits into
   `PublicIn`, and pokes `$42005300`. Boot sees it and starts the kernel.
2. The host reads the mailbox address back from `PublicOut` and answers it
   with `'s337'`.
3. The driver uploads and links Antelope into card DRAM and starts it. Its
   `main` finds the command packet through `PublicOut+$18`, the same address
   (`$s08C00`) the host uses, and enters the command loop.

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
  waits. The reply says "done" (1), "not handled" (0, the Mac draws it), or
  "run the original without drawing" (2).
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
