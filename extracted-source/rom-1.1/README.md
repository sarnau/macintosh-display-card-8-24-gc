# Declaration ROM 341-0266 ("MDC 8•24 GC 1.1")

The later 8•24 GC declaration ROM (VendorInfo: '341-0266', 16-Sep-91): a 64 KB
part with data in `$0000`-`$5141` only (format block at `$FFEC`, CRC `$D722B053`,
ByteLanes `$E1`). No new code beyond PrimaryInit, SecondaryInit and the
`.Display_Video_Apple_MDCGC` driver (DRVR sBlock `$2868`, `$12D4` bytes).

| File | Contents |
|------|----------|
| `PrimaryInit.s`, `SecondaryInit.s`, `VideoDriver.s` | recursive-descent 68020 listings (capstone 5), data as `dc.b`/`dc.w`; labels, trap names and "1.0: name $addr" matches to `../VideoDriver.s` etc., not otherwise annotated |
| `sResources.txt` | format block, sRsrc directory, board sRsrc (VendorInfo, `$41` names, `$7E` timing), the 56 video sRsrcs with mode lists and VPBlocks, and each `$7E` timing sBlock (pages, rowBytes, vRes, DP8531 N/R/P/PCLK, the 40-byte depth records) |

Regenerate (and check that every listed byte matches the ROM):
`python3 -E -P control-panel/rom11_dasm.py <ROM> extracted-source/rom-1.1`.
The ROM image is not in the repo. It is `Misc/Video cards/Apple Macintosh Display Card 8-24/Dolphin 8-24GC/341-0266_1.1.BIN` in `Mac_ROMs.zip`.

Main differences from 1.0 (`HOST_CARD_PROTOCOL.md` section 10.10):
* The per-monitor timing moves out of the code into board sRsrc id `$7E` (one sBlock per monitor). PrimaryInit and VideoOpen read it with sGetBlock, so the driver shrinks from `$2E5A` to `$12D4` bytes.
* There are 56 video sRsrcs `$80`-`$FC`. Bits 2-0 give the monitor, bit 3 the other TV size, bit 4 the 24-bit bank, bit 5 16 bpp and bit 6 unconvolved TV, so the progressive TV timings can now be selected.
* New: the 21" Color (sense 0) and the 16" Color (extended `$2D`), with extended `$30` for PAL. Mode `$84` is 16 bpp when the AC842A probe at `$2598` succeeds, and 32 bpp moves to `$85`.
* Unchanged: the `$44800000` stream, the old monitors' timings and the driver's Control/Status calls.
