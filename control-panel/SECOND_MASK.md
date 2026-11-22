# The second mask on the Am29000 firmware -- how it was found

This note records the reasoning, the evidence and the tools, so that the result
can be checked or extended. It describes what was *established*, what is a fit
and what is still open.

## 1. The symptom

`acef_unpack.py` undoes the ACEF container's obfuscation (a constant XOR per
section). The unpacked `ACEF_1` ("Runtime") looked like Am29000 code at the
opcode level (a plausible instruction mix) but nothing above it held together:
special-register numbers ran over 0-255 (only 0-14 and 128-135 exist), 74
`iret` words had non-zero operand bytes, 351 jumps pointed all over the
address space, and the data sections (`Vec`, `PublicIn`, `PublicOu`) looked
like noise with an arithmetic staircase. The opcode byte (bits 24-31) was
always right, which is why opcode histograms and "99% valid decode" statistics
looked reassuring and misled for a long time.

## 2. First crack: known plaintext in a data section

`Apple.bin` (77 bytes) showed, in the high halves of its words, every other
two-character chunk of "Copyright (c) 1989, Apple Computer, Inc. All Rights
Reserved". The missing chunks were in the low halves, XORed with
`Vec`'s low halves at the same word index. So `Vec` was the *key stream*
(an all-zero section masked with itself), and the "noise" was the mask.

## 3. Solving `Hand` from operand-free instructions

Some Am29000 instructions have fields that an assembler leaves at zero:
`iret` (24 bits), `mtsr` (RC), `mfsr` (RB). Reading the low 24 bits of the 80
`iret` words as a key, and the RC byte of the 120 `mtsr` words, gave key values
at 200 positions of `Hand`. Findings, in order:

1. Bits 0-6 of the key are a per-phase constant, period 24 words (`COL`),
   always a multiple of 4.
2. Bits 7-14 are `(ROW[k mod 48] - k) mod 256`: a ramp of -1 per word with a
   small signed jitter per phase (period 48).
3. The bits above 14 follow the same ramp's carries, but not as plain
   arithmetic: the high field counts *up* while the low field counts down, in
   three bits, sign-extended into bits 16-22. The final form (with
   `r = 0x4000 + 0x80*(ROW-k) + COL`):

   `key = signext19(((-(r >> 16)) & 7) << 16 | ((r & 0xFFFF) ^ 0x4000)) & 0x7FFFFF`

The fit used only the `iret`/`mtsr` words. It was then tested on things it had
never seen: all 113 `mfsr` words have RB = 0, every `mtsr` SPR is in 0-14 or
128-135, every `iret` has zero operands, adjacent `const`/`consth` words share
their register in 235 of 257 pairs, and all 351 direct jumps and calls land
inside the section. Ten `ROW` entries (phases 2, 4, 17, 18, 22, 34, 37, 38,
40, 43) were not covered by `iret`/`mtsr` samples; they were fixed by three
independent constraints (register pairs, `mfsr` RB, valid SPRs; for phase 37
the `mtsrim RBP` immediates had to be contiguous masks) and each beat all of
its +-1, +-2 alternatives on every check.

## 4. `Boot`: the same generator, fitted tables

`Boot` has 5 SPR instructions, no `iret`, so its tables could not be read off.
They were found by maximum likelihood: score each decode of a word with
per-opcode field statistics learned from the unmasked `Hand` (a blind fit on
`Hand`'s own first 512 words recovers its tables), optimise `ROW`/`COL` per
phase, then add hard constraints (jump targets in range, no jump into a delay
slot, valid SPR numbers, `mfsr`/`mtsr` operands). The result is a strict local
optimum; a handful of register fields may still be wrong. It does exactly what
the host side expects (polls `PublicIn+0` for `$42005300`, builds the trap
vector table at `VAB = $4C000000`, jumps to kernel init), which was *not*
used in the fit.

## 5. Antelope: same family, not solved

`Antelope`'s `.text` (62,134 words) is masked too; its apparent regularity was
the opcode byte again. Zero `jmpi lr0` returns and zero `sub gr1,gr1,N`
prologues were the tell. Known-plaintext idioms give 3,726 full key values
(293 `asgeu 64,gr1,gr126` and 454 `asleu 65,lr1,gr127` -- the vector bytes are
patched by the loader -- the 2,064 `aseq trap64,gr1,gr1` NOP words and 915
`jmpi lr0`), saved in `firmware/ACEF_100_Antelope/mask_samples.tsv`. They show a
48-entry low-bit table, and a generator shared across Antelope's sections
(checked on ~700 `.lit` words). The "multi-level staircase" seen in the upper
bits at first was largely an artefact: the `asleu` samples had been computed
from the wrong plaintext (`lr2` instead of `lr1`). With that fixed, every key
bit `b` is an exact function of `k mod 48*2^(b-6)`, the signature of a
T-function. A table-plus-slope model `J[k mod 384] + M*k` reproduces the
samples exactly through bit 13. The top bits are still open (see
`HOST_CARD_PROTOCOL.md` section 6, "third attempt").

Lesson added: check each known-plaintext idiom against the code it is supposed
to match. One wrong register field made a structured generator look chaotic.

## 6. Lessons

* The opcode byte is unmasked: statistics over opcodes prove nothing about
  the operand bytes. Use fields an assembler leaves zero, or fixed idioms.
* A statistic needs a control. A "register read before write" test scored the
  masked kernel at 73% and real code at 77-86%; it was discarded.
* Fit on one kind of evidence, validate on another. Everything that mattered
  was confirmed by checks that had not entered the fit.

## 7. Reproducing

```
python3 extract_resources.py "../Macintosh Control Panel/824GC.rsrc" OUT/ ACEF
python3 acef_unpack.py OUT/ACEF_1.bin   firmware/ACEF_1_Runtime   # first layer
python3 unmask_runtime.py firmware/ACEF_1_Runtime/Hand.bin Hand.unmasked.bin
python3 unmask_runtime.py firmware/ACEF_1_Runtime/Hand.bin --sprs   # checks
python3 am29k_dasm.py Hand.unmasked.bin 2000000 --labels
```

Data: `firmware/ACEF_1_Runtime/{Hand,Boot}.unmasked.bin`,
`firmware/ACEF_100_Antelope/mask_samples.tsv`,
`firmware/hand_mask_samples.tsv` (the early partial samples, superseded).
Tables: `COL`, `ROW`, `COL_BOOT`, `ROW_BOOT` in `unmask_runtime.py`.
