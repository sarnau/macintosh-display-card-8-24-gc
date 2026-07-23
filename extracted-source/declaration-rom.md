# Declaration ROM structure — Macintosh Display Card 8•24 GC

Apple part **341-0812-02**, ROM image `341-0812.bin` (32 KiB EPROM; the
declaration data occupies the top 24 KiB, `$2000‥$7FFF`).

## Format block (`$7FEC`, the last 20 bytes)
```
DirectoryOffset  = -0x5fec  -> sResource directory at $2000
Length           = 0x6000  (24576 bytes)
CRC              = 0x9e9857e8
RevisionLevel    = 0x1
Format           = 0x1
TestPattern      = 0x5a932bc7   (must be $5A932BC7)
ByteLanes        = 0xe1   (lane 0 only; ROM appears at every 4th NuBus byte)
```

## Top-level sResource directory (`$2000`)

| id | offset | sResource |
|----|--------|-----------|
| `0x01` | `+0x48` | Board sResource @ `$2048` |
| `0xa0` | `+0x14f4` | Functional (video) — group A: PAL Display 640*480 @ `$34F8` |
| `0xa1` | `+0x1288` | Functional (video) — group A: Mac II Portrait Monitor @ `$3290` |
| `0xa2` | `+0x1358` | Functional (video) — group A: Mac II Medium-Res Monitor @ `$3364` |
| `0xa3` | `+0x121c` | Functional (video) — group A: Mac II Two-Page Mono Monitor @ `$322C` |
| `0xa4` | `+0x1420` | Functional (video) — group A: NTSC Display, 512*384 @ `$3434` |
| `0xa6` | `+0x12e0` | Functional (video) — group A: Mac II High-Res Monitor @ `$32F8` |
| `0xa8` | `+0x147c` | Functional (video) — group A: PAL Display 768*576 @ `$3498` |
| `0xac` | `+0x13b0` | Functional (video) — group A: NTSC Display, 640*480 @ `$33D0` |
| `0xb0` | `+0x150c` | Functional (video) — group B: PAL Display 640*480 @ `$3530` |
| `0xb1` | `+0x12a0` | Functional (video) — group B: Mac II Portrait Monitor @ `$32C8` |
| `0xb2` | `+0x1374` | Functional (video) — group B: Mac II Medium-Res Monitor @ `$33A0` |
| `0xb3` | `+0x1234` | Functional (video) — group B: Mac II Two-Page Mono Monitor @ `$3264` |
| `0xb4` | `+0x1438` | Functional (video) — group B: NTSC Display, 512*384 @ `$346C` |
| `0xb6` | `+0x12fc` | Functional (video) — group B: Mac II High-Res Monitor @ `$3334` |
| `0xb8` | `+0x1490` | Functional (video) — group B: PAL Display 768*576 @ `$34CC` |
| `0xbc` | `+0x13c8` | Functional (video) — group B: NTSC Display, 640*480 @ `$3408` |

The sixteen functional sResources are two parallel banks (`$A0‥$AC` and
`$B0‥$BC`) of the same eight monitor types; every one points at the single
shared video driver.  The active bank is chosen at run time by the sense code.

## Board sResource (`$2048`, id `$01`)

| id | meaning | value |
|----|---------|-------|
| `0x01` | | sRsrcType: Board — cat 1, typ 0, DrSW 0, DrHW 0 |
| `0x02` | | sRsrcName: 'Macintosh Display Card 8•24 GC' |
| `0x14` | | (vendor-specific) -> $3224 |
| `0x15` | | (vendor-specific) -> $3228 |
| `0x20` | | BoardId / minor-space size -> $2084 |
| `0x22` | | **PrimaryInit** sExecBlock @ $2098 (68020, 0xe5c bytes) |
| `0x24` | | VendorInfo directory @ $2EF4 |
| `0x26` | | **SecondaryInit** sExecBlock @ $2F44 (68020, 0x1b0 bytes) |
| `0x41` | | Monitor/mode name+sense table @ $30F4 |

### VendorInfo (`$2EF4`)
- **VendorId** = '© Apple Computer, Inc. 1989-1990'
- **RevLevel** = 'MDC 8•24 GC 1.0'
- **PartNum** = '341-0812-02'

### Monitor / sense-code table (board id `$41`, `$30F4`)

Each functional sResource maps to a record giving the monitor name and the
value read from the three SENSE lines (extended-sense code 0‥7):

| sResource | sense | monitor |
|-----------|:-----:|---------|
| `0xa0` (+`0xb0`) | 6 | PAL Display 640*480 |
| `0xa1` (+`0xb1`) | 3 | Mac II Portrait Monitor |
| `0xa2` (+`0xb2`) | 5 | Mac II Medium-Res Monitor |
| `0xa3` (+`0xb3`) | 4 | Mac II Two-Page Mono Monitor |
| `0xa4` (+`0xb4`) | 1 | NTSC Display, 512*384 |
| `0xa6` (+`0xb6`) | 0 | Mac II High-Res Monitor |
| `0xa8` (+`0xb8`) | 7 | PAL Display 768*576 |
| `0xac` (+`0xbc`) | 2 | NTSC Display, 640*480 |

## Functional (video) sResource — shared layout

All sixteen share this structure (shown for `$A6`, Mac II High-Res):

| id | meaning | value |
|----|---------|-------|
| `0x01` | | sRsrcType: cat 3 (Display), typ 1 (Video), DrSW 1 (Apple), DrHW $1D |
| `0x02` | | sRsrcName: 'Display_Video_Apple_MDCGC' |
| `0x04` | | sRsrcDrvrDir @ $3580 → 68020 DRVR at $358C |
| `0x07` | | sRsrcFlags = 0x6 |
| `0x08` | | sRsrcHWDevId = 0x1 |
| `0x0b` | | MinorLength -> $63EA |
| `0x0c` | | MajorBaseOS -> $63EE |
| `0x0d` | | MajorLength -> $63F6 |
| `0x40` | | sVidParams -> $6412 |
| `0x80` | | sVidParmDir (per-depth VPBlocks) @ $6924 |
| `0x81` | | video mode data @ $6B94 |
| `0x82` | | video mode data @ $6E04 |
| `0x83` | | video mode data @ $7074 |
| `0x84` | | sGammaDir @ $7294 |

### Driver directory (`$3580`)
```
id $02  (sMacOS68020)  ->  DRVR record @ $3588
        length $2E5A, DRVR '.Display_Video_Apple_MDCGC', flags $4C00
        (dNeedLock+dStatEnable+dCtlEnable)
```

### Example video-parameter block (`sVidParmDir` spID 1, 640×480×1)
```
vpBaseOffset = 0x11400
vpRowBytes   = 1024
vpBounds     = (0,0,480,640)  => 640 x 480
vpHRes/vpVRes= 72 dpi
vpPixelSize  = 1  (bits/pixel)
```
