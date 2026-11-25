"""antelope_names.py -- names of System 7 Antelope (ACEF_100 "32-Bit Antelope") functions.

Established in HOST_CARD_PROTOCOL.md, by role where the original name is
unknown; used by antelope_dasm.py.
"""

NAMES = {
    0x00140: 'Report', 0x00248: 'CopyLongsBurst', 0x00294: 'Fill2LongsBurst',
    0x00348: 'FillLongsBurst', 0x00F84: 'ReportToLog', 0x16C48: 'CopyHostMemory',
    0x17264: 'Fill2Longs', 0x3B814: 'mul_millicode',
    0x01494: 'RSect', 0x01654: 'TrimRect', 0x01A50: 'BitBlt',
    0x06650: 'ITabMatch', 0x06BEC: 'BitsToPixMap', 0x06F1C: 'ColorMap',
    0x075DC: 'DrawArc', 0x08618: 'DrawLine', 0x0AD18: 'DrawMultiObject',
    0x11AD8: 'DrawText', 0x13F54: 'IsOnThisCard', 0x14034: 'DisposeOffscreen',
    0x14168: 'FlushOffscreen', 0x141F8: 'FlushColorTable', 0x14564: 'ConvertFontStrike', 0x14A80: 'UploadFontStrike',
    0x15958: 'CacheAlloc', 0x15B3C: 'CacheRelease', 0x376A0: 'HeapFree',
    0x14B64: 'UploadWidthTable', 0x14F64: 'CacheGDevice', 0x151C4: 'CachePixPat',
    0x15808: 'FlushGDevice', 0x158F4: 'FlushPixPat', 0x15D28: 'CacheFind',
    0x15E8C: 'CacheFindStamp', 0x15EE4: 'CacheCreate', 0x15FF4: 'CacheFindOrCreate',
    0x161F8: 'PQDInit', 0x16A04: 'PQDAlloc', 0x1701C: 'FillLongs',
    0x19270: 'QuickPolys', 0x19DA4: 'RgnBlt', 0x22A8C: 'scaleBlt',
    0x253D4: 'GetSeek', 0x2D7B8: 'StretchBits', 0x31E20: 'CommandDispatcher',
    0x32C10: 'ShieldCursor', 0x32EF8: 'ShowCursorAfterDraw', 0x3373C: 'MapVirtual',
    0x33A9C: 'UnmapAll', 0x33EBC: 'CallBack', 0x37000: 'TestSlotBurst', 0x37C10: 'FillPatternStorem',
    0x37D68: 'FillLongsStorem', 0x38218: 'CopyLongsStorem', 0x388D0: 'CopyLongsBackStorem',
    # C library (HIF)
    0x39214: 'vprintf', 0x39284: 'printf', 0x39304: 'fseek', 0x39864: 'sprintf',
    0x399E0: '_doprnt', 0x3AA9C: 'isupper', 0x3AAB8: 'islower', 0x3AAD4: 'isalpha',
    0x3AAF0: 'isdigit', 0x3AB0C: 'isxdigit', 0x3AB28: 'isspace', 0x3AB44: 'ispunct',
    0x3AB60: 'isalnum', 0x3AB7C: 'isgraph', 0x3AB98: 'isprint', 0x3ABB4: 'iscntrl',
    0x3ABD0: 'isascii', 0x3ABF8: 'toupper', 0x3AC24: 'tolower', 0x3AC88: 'exit',
    # AMD's HIF stubs (antelope_hif_stubs.py), by their C names
    0x3B404: 'close', 0x3B428: '_exit', 0x3B44C: 'lseek', 0x3B470: 'open',
    0x3B494: 'read', 0x3B4B8: 'tmpnam', 0x3B4DC: 'write', 0x3C9EC: 'remove',
    0x3B500: 'memchr', 0x3B600: 'memcpy', 0x3B748: 'memset',
    # main (crt0 calls it) and its set-up; millicode (transparent, return via tpc)
    0x31DAC: 'main', 0x3299C: 'InitPacket',
    0x00000: 'Int1Handler', 0x00020: 'Int2Handler',
    # the self-test (file 26), named by its messages in .data
    0x3404C: 'SelfTest', 0x34304: 'TestCPU', 0x34774: 'TestLogic', 0x34828: 'TestTimer',
    0x34B9C: 'TestMemory', 0x34C34: 'TestInterleave', 0x34DE4: 'TestMemoryAccess',
    0x3563C: 'TestValidate', 0x359B0: 'TestCLUT', 0x35BE8: 'TestMMU', 0x36644: 'TestInterrupts',
    0x3B950: 'div_millicode', 0x3BA38: 'udiv_millicode',
}
