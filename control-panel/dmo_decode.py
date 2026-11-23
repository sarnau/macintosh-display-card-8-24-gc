#!/usr/bin/env python3
"""Decode a DrawMultiObject stream (the batched drawing records that gc24's
EngineDispatch writes into card memory, see HOST_CARD_PROTOCOL.md,
"DrawMultiObject: the batched drawing stream").

    python3 dmo_decode.py DUMP [--offset N] [--length N] [--regions]
    python3 dmo_decode.py --selftest

DUMP is a raw big-endian byte dump that starts with (or, with --offset,
contains) the stream, i.e. the buffer at gc24 global $AC(a4) / card address
$C4(a4). Without --length, decoding stops at the end of the file or at the
first unknown opcode. Each record is a 2-byte opcode, a word at +2, then data,
padded to a multiple of 4.
"""
import argparse
import struct
import sys


def w(b, o):
    return struct.unpack_from('>H', b, o)[0]


def sw(b, o):
    return struct.unpack_from('>h', b, o)[0]


def l(b, o):
    return struct.unpack_from('>I', b, o)[0]


def pt(b, o):                       # QuickDraw Point: v, h
    return '(%d,%d)' % (sw(b, o + 2), sw(b, o))   # printed as (h,v)


def rect(b, o):                     # top, left, bottom, right
    t, lf, bt, r = struct.unpack_from('>4h', b, o)
    return '[%d,%d,%d,%d]' % (lf, t, r, bt)     # printed as [l,t,r,b]


def fixed(b, o):
    return '%.4f' % (struct.unpack_from('>i', b, o)[0] / 65536.0)


def rgb(b, o):
    return 'rgb(%04X,%04X,%04X)' % struct.unpack_from('>3H', b, o)


def pad4(n):
    return (n + 3) & ~3


def frame(b, o):
    return 'frame' if sw(b, o + 2) == -1 else ('area' if sw(b, o + 2) == 0 else 'verb?%d' % sw(b, o + 2))


def region(b, o, show):
    size = w(b, o)
    s = 'rgnSize=%d bbox=%s' % (size, rect(b, o + 2))
    if size == 10:
        s += ' (rectangular)'
    elif show:
        rows, p, end = [], o + 10, o + size
        while p + 2 <= end:
            v = sw(b, p)
            p += 2
            if v == 0x7FFF:
                break
            hs = []
            while p + 2 <= end and sw(b, p) != 0x7FFF:
                hs.append(sw(b, p))
                p += 2
            p += 2
            rows.append('%d:%s' % (v, ','.join(map(str, hs))))
        s += '\n        ' + ' '.join(rows)
    return s, size


def polygon(b, o):
    size = w(b, o)
    pts = [pt(b, p) for p in range(o + 10, o + size - 3, 4)]
    return 'polySize=%d bbox=%s %d points %s' % (
        size, rect(b, o + 2), len(pts), ' '.join(pts)), size


# opcode -> (name, size(b, o) or fixed int, formatter(b, o, opts))
def _text(b, o, a):
    n = w(b, o + 2)
    txt = bytes(b[o + 16:o + 16 + n]).decode('mac_roman', 'replace')
    return 'n=%d spaceWidth=%s fixTxWid=%s advance=%s %r' % (
        n, fixed(b, o + 4), fixed(b, o + 8), fixed(b, o + 12), txt)


def _font(b, o, a):
    e, fh = sw(b, o + 2), l(b, o + 4)
    (bold, ital, ulo, uls, ult, shad, extra, asc, desc, widmax, lead,
     style) = struct.unpack_from('>12B', b, o + 8)
    return ('FMOutput errNum=%d fontHandle=$%08X bold=%d italic=%d ul=%d/%d/%d '
            'shadow=%d extra=%d ascent=%d descent=%d widMax=%d leading=%d '
            'style=$%02X numer=%s denom=%s widthTab=$%08X') % (
        e, fh, bold, ital, ulo, uls, ult, shad, extra, asc, desc, widmax, lead,
        style, pt(b, o + 20), pt(b, o + 24), l(b, o + 28))


def _rgn_at(off):
    def size(b, o):
        return pad4(w(b, o + off) + off)
    return size


OPS = {
    0x01: ('Line', 8, lambda b, o, a: 'to %s' % pt(b, o + 4)),
    0x02: ('Arc', 16, lambda b, o, a: '%s %s start=%d arc=%d' % (
        frame(b, o), rect(b, o + 4), sw(b, o + 12), sw(b, o + 14))),
    0x03: ('Oval', 12, lambda b, o, a: '%s %s' % (frame(b, o), rect(b, o + 4))),
    0x04: ('RRect', 16, lambda b, o, a: '%s %s oval=%dx%d' % (
        frame(b, o), rect(b, o + 4), sw(b, o + 12), sw(b, o + 14))),
    0x05: ('Rect', 12, lambda b, o, a: '%s %s' % (frame(b, o), rect(b, o + 4))),
    0x06: ('Text', lambda b, o: (w(b, o + 2) + 0x13) & ~3, _text),
    0x07: ('Poly', _rgn_at(4), lambda b, o, a: '%s %s' % (
        frame(b, o), polygon(b, o + 4)[0])),
    0x08: ('Rgn', _rgn_at(4), lambda b, o, a: '%s %s' % (
        frame(b, o), region(b, o + 4, a.regions)[0])),
    0x64: ('ForeColor', 12, lambda b, o, a: '%s color=$%08X' % (
        rgb(b, o + 2), l(b, o + 8))),
    0x66: ('PmForeColor', 16, lambda b, o, a: '%s color=$%08X pmFgIndex=%d' % (
        rgb(b, o + 2), l(b, o + 8), w(b, o + 12))),
    0x67: ('Font', 32, _font),
    0x68: ('MoveTo', 8, lambda b, o, a: '%s hFrac=$%04X' % (pt(b, o + 4), w(b, o + 2))),
    0x69: ('Mode', 4, lambda b, o, a: 'mode=%d' % w(b, o + 2)),
    0x6A: ('ClipRgn', _rgn_at(2), lambda b, o, a: region(b, o + 2, a.regions)[0]),
    0x6B: ('BackColor', 12, lambda b, o, a: '%s color=$%08X' % (
        rgb(b, o + 2), l(b, o + 8))),
    0x6C: ('VisRgn', _rgn_at(2), lambda b, o, a: region(b, o + 2, a.regions)[0]),
    0x6D: ('PmBackColor', 16, lambda b, o, a: '%s color=$%08X pmBkIndex=%d' % (
        rgb(b, o + 2), l(b, o + 8), w(b, o + 12))),
    0x6E: ('PenSize', 8, lambda b, o, a: 'pnSize=%s' % pt(b, o + 4)),
    0x6F: ('Header', 4, lambda b, o, a: 'flags=$%04X' % w(b, o + 2)),
    0x70: ('HiliteOp', 16, lambda b, o, a: 'hilite=%s op=%s' % (
        rgb(b, o + 4), rgb(b, o + 10))),
    0x71: ('BitPat', 12, lambda b, o, a: 'slot=%d pat=%s' % (
        w(b, o + 2), bytes(b[o + 4:o + 12]).hex())),
    0x72: ('PixPat', 8, lambda b, o, a: 'slot=%d pixPat=$%08X' % (w(b, o + 2), l(b, o + 4))),
    0x73: ('PatSlot', 4, lambda b, o, a: 'slot=%d (%s)' % (
        w(b, o + 2), {1: 'pen', 2: 'background', 3: 'fill'}.get(w(b, o + 2), '?'))),
    0x74: ('RGBPat', 12, lambda b, o, a: 'slot=%d %s' % (w(b, o + 4), rgb(b, o + 6))),
    0x75: ('PatAlign', 8, lambda b, o, a: 'patAlign=%s' % pt(b, o + 4)),
}


def decode(b, start, end, opts, out):
    o, n = start, 0
    while o + 4 <= end:
        op = w(b, o)
        if op not in OPS:
            out.write('%06X  ???? opcode $%04X: stop\n' % (o - start, op))
            return False
        name, size, fmt = OPS[op]
        size = size if isinstance(size, int) else size(b, o)
        if size < 4 or o + size > end:
            out.write('%06X  %-11s size %d runs past the end: stop\n' % (o - start, name, size))
            return False
        out.write('%06X  $%02X %-11s %s\n' % (o - start, op, name, fmt(b, o, opts)))
        o += size
        n += 1
    out.write('-- %d records, %d bytes\n' % (n, o - start))
    return True


def _selftest():
    import io

    def rec(op, word, data=b''):
        r = struct.pack('>Hh', op, word) + data
        return r + b'\0' * (pad4(len(r)) - len(r))

    R = struct.pack('>4h', 10, 20, 110, 220)
    rgn = struct.pack('>H4h', 28, 0, 0, 2, 4) + struct.pack('>hhhh', 0, 0, 4, 0x7FFF) \
        + struct.pack('>hhhh', 2, 0, 4, 0x7FFF) + struct.pack('>h', 0x7FFF)
    assert len(rgn) == 28
    poly = struct.pack('>H4h', 22, 0, 0, 5, 5) + struct.pack('>4h', 0, 0, 5, 5) \
        + struct.pack('>2h', 0, 5)
    fm = struct.pack('>hI12B2h2h', 0, 0x00123456, 0, 0, 1, 1, 1, 0, 0, 9, 3, 12, 2, 0,
                     1, 1, 1, 1)
    s = b''.join([
        rec(0x6F, 0),
        rec(0x69, 8),
        struct.pack('>H', 0x64) + struct.pack('>3H', 0xFFFF, 0, 0) + struct.pack('>I', 205),
        struct.pack('>H', 0x66) + struct.pack('>3H', 0, 0, 0xFFFF) + struct.pack('>IH', 3, 7) + b'\0\0',
        rec(0x68, 0, struct.pack('>2h', 30, 40)),
        rec(0x01, 0, struct.pack('>2h', 50, 60)),
        rec(0x05, -1, R),
        rec(0x02, 0, R + struct.pack('>2h', 45, 90)),
        rec(0x04, 0, R + struct.pack('>2h', 16, 16)),
        struct.pack('>H', 0x67) + fm + struct.pack('>I', 0x00ABCDEF),
        struct.pack('>HH', 0x06, 5) + struct.pack('>3I', 6 << 16, 30 << 16, 30 << 16) + b'Hello' + b'\0' * 3,
        struct.pack('>H', 0x6A) + rgn + b'\0\0',
        rec(0x08, 0, rgn),
        rec(0x07, -1, poly),
        rec(0x71, 1, b'\xAA\x55' * 4),
        rec(0x73, 3),
        rec(0x75, 0, struct.pack('>2h', 0, 0)),
    ])
    out = io.StringIO()

    class A:
        regions = True
    ok = decode(s, 0, len(s), A, out)
    txt = out.getvalue()
    print(txt, end='')
    assert ok and '-- 17 records, %d bytes' % len(s) in txt, 'round trip failed'
    assert "'Hello'" in txt and 'pmFgIndex=7' in txt and 'rgnSize=28' in txt
    print('selftest ok')


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('dump', nargs='?')
    ap.add_argument('--offset', type=lambda x: int(x, 0), default=0)
    ap.add_argument('--length', type=lambda x: int(x, 0))
    ap.add_argument('--regions', action='store_true', help='print region inversion rows')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        return _selftest()
    if not a.dump:
        ap.error('DUMP or --selftest required')
    b = open(a.dump, 'rb').read()
    end = len(b) if a.length is None else min(len(b), a.offset + a.length)
    sys.exit(0 if decode(b, a.offset, end, a, sys.stdout) else 1)


if __name__ == '__main__':
    main()
