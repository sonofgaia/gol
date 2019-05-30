.include "lib.inc"

.segment "ZPVARS" : zeropage

; Variables used in NMI handler.
_tmp1: .res 1
_tmp2: .res 1
_tmp3: .res 1
_tmp4: .res 1
_ptr1: .res 2
_ptr2: .res 2
_ptr3: .res 2
_ptr4: .res 2

; Variables used outside of the NMI.
gol_tmp1: .res 1
gol_tmp2: .res 1
gol_tmp3: .res 1
gol_tmp4: .res 1
gol_ptr1: .res 2
gol_ptr2: .res 2
gol_ptr3: .res 2
gol_ptr4: .res 2

; Space to save registers (before function call, etc.)
regs: .res 6
