* ACEF "32-Bit Antelope" version $00110000 -- Code (the entry stub), exact
  0f000:  25010118  sub      gr1, gr1, $18
  0f004:  5e00017e  asgeu    trap64, gr1, gr126
  0f008:  15810118  add      lr1, gr1, $18
  0f00c:  03006200  const    gr98, $0000   ; lo of extern#1648+$0
  0f010:  02006200  consth   gr98, $0000   ; hi of extern#1648+$0
  0f014:  1e006062  store    0, 0, gr96, gr98
  0f018:  15626204  add      gr98, gr98, $04
  0f01c:  1e006162  store    0, 0, gr97, gr98
  0f020:  03017904  const    gr121, $0104
  0f024:  72450101  asneq    trap69, gr1, gr1
  0f028:  15836000  add      lr3, gr96, $00
  0f02c:  15846000  add      lr4, gr96, $00
  0f030:  01ff82ff  constn   lr2, $ffff
L_0f034:
  0f034:  16006184  load     0, 0, gr97, lr4
  0f038:  15848404  add      lr4, lr4, $04
  0f03c:  61616100  cpeq     gr97, gr97, $00
  0f040:  a53c610d  jmpf     gr97, $0f034   ; -> L_0f034
  0f044:  15828201  add      lr2, lr2, $01   ; [delay slot]
  0f048:  03008000  const    lr0, $0000   ; lo of extern#1706+$0
  0f04c:  02008000  consth   lr0, $0000   ; hi of extern#1706+$0
  0f050:  16008080  load     0, 0, lr0, lr0
  0f054:  61608000  cpeq     gr96, lr0, $00
  0f058:  ad3c601a  jmpt     gr96, $0f068   ; -> L_0f068
  0f05c:  70400101  nop         ; [delay slot]
  0f060:  c8008080  calli    lr0, lr0
  0f064:  70400101  nop         ; [delay slot]
L_0f068:
  0f068:  03008000  const    lr0, $0000   ; lo of .text $2d5a0
  0f06c:  02008000  consth   lr0, $0000   ; hi of .text $2d5a0
  0f070:  c8008080  calli    lr0, lr0
  0f074:  70400101  nop         ; [delay slot]
  0f078:  03008000  const    lr0, $0000   ; lo of .text $40c88 (exit)
  0f07c:  02008000  consth   lr0, $0000   ; hi of .text $40c88 (exit)
  0f080:  c8008080  calli    lr0, lr0
  0f084:  15826000  add      lr2, gr96, $00   ; [delay slot]
L_0f088:
  0f088:  03007901  const    gr121, $0001
  0f08c:  72450101  asneq    trap69, gr1, gr1
  0f090:  a13c0022  jmp      $0f088   ; -> L_0f088
  0f094:  70400101  nop         ; [delay slot]
