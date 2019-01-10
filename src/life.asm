; This file implements an algorithm using a lookup table to (hopefully) speed up the process of applying
; the rules for Life on our 64 x 60 array.

; The lookup table uses an 18-bit address to find the new values for 4 cells.
;
; b12 | b00 b01 b02 b03 | b15
; b13 | b04 b05 b06 b07 | b16
; b14 | b08 b09 b10 b11 | b17
;
; Suppose we take 18 cells in the array (b00-b17).
; The cells we want to fetch the new values for are b04-b07.
;
; In order to optimize things a bit, we do this lookup twice for each byte in the array (each byte contains 8 cells).
; So it looks something like this :
;
; b24 | b00 b01 b02 b03 b12 b13 b14 b15 | b27
; b25 | b04 b05 b06 b07 b16 b17 b18 b19 | b28
; b26 | b08 b09 b10 b11 b20 b21 b22 b23 | b29
;
; We would be considering 30 cells when doing the two lookups. b00-b23 is aligned accross 3 bytes in our array.
; b24-b26 is bit 0 of the previous bytes and b27-b29 is bit 7 of the next byte.
; The two lookups would give us the new values for b04-b07 and b16-b19.

.segment "ZPVARS" : zeropage

_life_row1_ptr: .res 1
_life_row2_ptr: .res 1
_life_row3_ptr: .res 1

_life_cell_01_value: .res 1
_life_cell_02_value: .res 1
_life_cell_03_value: .res 1
_life_cell_04_value: .res 1
