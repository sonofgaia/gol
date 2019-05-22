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
