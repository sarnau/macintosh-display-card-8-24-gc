  0f000:  25010118  sub      gr1, gr1, $18           
  0f004:  5e000156  asgeu    trap0, gr1, gr86        
  0f008:  158101b7  add      lr1, gr1, $b7           
  0f00c:  030061cc  const    gr97, $00cc             
  0f010:  020061d2  consth   gr97, $00d2             
  0f014:  1e00620f  store    0, 0, gr98, gr15        
  0f018:  15626088  add      gr98, gr96, $88         
  0f01c:  1e007c0e  store    0, 0, gr124, gr14       
  0f020:  0301642b  const    gr100, $012b            
  0f024:  72451cc9  asneq    trap69, gr28, lr73      
  0f028:  15837c66  add      lr3, gr124, $66         
  0f02c:  15847cf5  add      lr4, gr124, $f5         
  0f030:  01ff9e5f  constn   lr30, $ff5f             
  0f034:  16007e0c  load     0, 0, gr126, gr12       
  0f038:  15849bab  add      lr4, lr27, $ab          
  0f03c:  61617fac  cpeq     gr97, gr127, $ac        
  0f040:  a53c7fbf  jmpf     gr127, $0f2fc           
  0f044:  15829bac  add      lr2, lr27, $ac             ; [delay slot]
  0f048:  030099ac  const    lr25, $00ac             
  0f04c:  0200988c  consth   lr24, $008c             
  0f050:  1600982f  load     0, 0, lr24, gr47        
  0f054:  61609be8  cpeq     gr96, lr27, $e8         
  0f058:  ad3c7a5c  jmpt     gr122, $0f170           
  0f05c:  70401b34  aseq     trap64, gr27, gr52         ; [delay slot]
  0f060:  c8009a40  calli    lr26, gr64              
  0f064:  70401469  aseq     trap64, gr20, gr105        ; [delay slot]
  0f068:  030095af  const    lr21, $00af             
  0f06c:  0200940c  consth   lr20, $000c             
  0f070:  c8009492  calli    lr20, lr18              
  0f074:  704015ec  aseq     trap64, gr21, lr108        ; [delay slot]
  0f078:  030097cc  const    lr23, $00cc             
  0f07c:  020097ac  consth   lr23, $00ac             
  0f080:  c80096af  calli    lr22, lr47              
  0f084:  15827108  add      lr2, gr113, $08            ; [delay slot]
  0f088:  030068a7  const    gr104, $00a7            
  0f08c:  72451174  asneq    trap69, gr17, gr116     
  0f090:  a13c10c2  jmp      $0f308                  
  0f094:  704012c9  aseq     trap64, gr18, lr73         ; [delay slot]
