#!/usr/bin/env python3
"""runtime_publicout.py -- decode the header of Runtime's PublicOu section.

PublicOu ($4C006800, card -> host fields) is masked like the other Runtime
sections, with its own keystream; PublicIn's or Vec's keystream does not
fit it.  Most of the section is zero, so its raw words are the keystream
itself, and that keystream has the same shape as the others:

    key(k) bits 0-10  ==  key(k + 192) + $100   (mod $800)

(bits 0-4 repeat every 24 words, bit 5 every 48, ... bit 8 every 384; the
-$80 per word and -$100 per 192 words fall out of the subtraction).  The
script checks this on every pair of words that are both zero (high half 0)
and then takes bits 0-10 of the header words (k < 8) from k + 192.

Bits 11-14 are not periodic.  Near a section start the key is small: bits
15-31 are plain, and bits 11-14 are 0 until the key's falling counter
crosses zero (here between +$1C and +$20, where they turn to $F).  With 0,
the four pointers decode to $4C007000 (HifComm), $4C007800 (InpArgs),
$4C007300 (VidComm) and $4C008C00 (the host's packet); with $F or $E to
none of the known addresses.  The script prints all three readings.

Usage:  runtime_publicout.py firmware/ACEF_1_Runtime
"""
import os, struct, sys


def words(path):
    b = open(path, 'rb').read()
    return struct.unpack('>%dI' % (len(b) // 4), b[:len(b) // 4 * 4])


NAMES = {0x0C: 'mailbox (the host reads it at image+$40C)', 0x18: 'packet (InitPacket)',
         0x10: '', 0x14: '', 0x28: 'Boot stores here', 0x2C: 'Boot stores here'}
KNOWN = {0x4C007000: 'HifComm', 0x4C007300: 'VidComm', 0x4C007400: 'InitMap',
         0x4C007800: 'InpArgs', 0x4C008C00: 'host packet ($s08C00)'}


def main(d):
    w = words(os.path.join(d, 'PublicOu.bin'))
    zero = [k for k in range(len(w)) if w[k] >> 23 == 0]   # bits 23-31 are never masked
    zs = set(zero)
    pairs = [k for k in zero if k + 192 in zs]
    good = [k for k in pairs if (w[k] - w[k + 192]) & 0x7FF == 0x100]
    print('PublicOu: %d words; %d pairs (k, k+192) with bits 23-31 zero in both, '
          '%d fit key(k) = key(k+192) + $100 in bits 0-10' % (len(w), len(pairs), len(good)))
    print('(the rest are words whose plaintext is not 0)\n')
    print('key bits 11-14 =     0                  $F        $E')
    print('  off   raw')
    for k in range(12):
        lo = (w[k + 192] + 0x100) & 0x7FF
        r = [w[k] ^ (h << 11 | lo) for h in (0, 0xF, 0xE)]
        tag = KNOWN.get(r[0], '')
        print('  +$%02X  %08x  %08x %-8s %08x  %08x  %s' % (
            4 * k, w[k], r[0], tag[:8] if tag else '', r[1], r[2], NAMES.get(4 * k, '')))


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
