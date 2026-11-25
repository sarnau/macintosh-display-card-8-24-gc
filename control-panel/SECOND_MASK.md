# The "second mask" on the Am29000 firmware -- solved

## The answer

The ACEF section data is not masked twice. It is encrypted once, with a
running 32-bit key, and the host's video driver removes it while it copies
the firmware to the card. The loop is in `DRVR.s`'s `ACEFLoad`:

```
$3A46-$3A64   K = KEY * $01010101          KEY = header byte +7 (low byte of timdat)
              b = s_scnptr & $FF            the low byte of the section's file offset
$3AD0-$3AE6   per word:  plain = word ^ K
(and $40FE-   K = K + b  (mod 2^32)
 $4126)       b = b ^ (K & $FF)
```

The key restarts at every section. The loader copies `size/4` words, so a
section's last 1-3 bytes are not loaded. `gc24`'s copy of `ACEFLoad` accepts
only plain (`$012A`) files; only the driver handles encrypted (`$012B`)
ones.

`acef_unpack.py` implements this (`decrypt`). Checks: `Hand` decodes to the
same 2,885 words as the earlier table-based unmask; every Antelope string is
plain text; all 555 direct calls in Antelope's `.text` land on a function
start; the eight HIF stubs equal AMD's library source word for word; the
Runtime's service table points at the handlers identified by their use.

## Why it looked like a second mask

Earlier versions of `acef_unpack.py` XORed every byte of the section data
with `KEY`, i.e. with the starting value of `K` for every word. What was
left is `K(k) ^ K(0)`, a key that changes slowly with the word index `k`:

* `b < $100`, so `K` grows by less than `$100` per word and its top byte
  stays the same for tens of thousands of words: the opcode byte looked
  plain everywhere, which is why opcode statistics always looked right;
* add-with-carry plus the XOR feedback into `b` gives every low bit a period
  that doubles bit by bit (the "T-function" signature found in Antelope), and
  a slowly falling ramp in the middle bits;
* the start value of `b` differs per section, so each section looked as if
  it had its own tables or keystream (`Hand` and `Boot` "tables", separate
  `.lit`, `.data` and `PublicOu` keys, a different key for System 6).

## How it was approached before (superseded)

From July to November 2026 the leftover was modelled from known plaintext
instead of being looked for in the loader:

1. `Apple.bin`'s copyright text showed that the data sections carry the
   same mask, and `Vec` (an all-zero section) was its keystream.
2. `Hand` was solved exactly from operand-free instructions (`iret`, `mtsr`
   RC, `mfsr` RB): a generator with a 24-entry and a 48-entry table that
   reproduces this section's keystream. `Boot`'s tables were fitted by
   maximum likelihood; they turned out wrong in 150 of 512 words.
3. Antelope's key was modelled from idioms (NOPs, `jmpi lr0`, frame words,
   relocated words): exact low bits, high bits estimated as a step function.
   `.lit`, `.data` and System 6 got their own fits from strings, tables and
   the other build.

That gave a partial disassembly good enough to map the dispatcher, the
drawing stream and most of the protocol, but with unreadable fields, uncertain
table entries and some wrong conclusions, which `HOST_CARD_PROTOCOL.md` now
corrects against the exact code. The tools (`unmask_runtime.py`,
`unmask_antelope_low.py`, the `antelope_*_key.py` family and others) are in
the repository's history before the commit that added this note's first
section.

## Lessons

* Read the loader first. The code that loads the firmware has to decrypt
  it; the key was in `DRVR.s` all along, next to the first layer that had
  already been read from it.
* The opcode byte was unmasked: statistics over opcodes prove nothing about
  the operand bytes.
* Fit on one kind of evidence, validate on another. The fitted models
  passed their checks where they were exact (`Hand`) and failed silently
  where they were not (`Boot`).

## Reproducing

```
python3 extract_resources.py "../Macintosh Control Panel/824GC.rsrc" OUT/ ACEF
python3 acef_unpack.py OUT/ACEF_1.bin   firmware/ACEF_1_Runtime
python3 acef_unpack.py OUT/ACEF_100.bin firmware/ACEF_100_Antelope
python3 runtime_dasm.py OUT/ACEF_1.bin firmware/disasm --no-hand
python3 antelope_dasm.py OUT/ACEF_100.bin firmware/disasm
```

System 6 (`"../Apple 8•24 GC Software/8•24 GC SW 1.1 (for System 6)/8•24 GC
SW/..namedfork/rsrc"`) goes to `firmware/sw11/` the same way, with
`antelope_dasm.py … --names-from OUT/ACEF_100.bin` for the names.
