; This file implements an algorithm using a lookup table to (hopefully) speed up the process of applying
; the rules for Life on our 64 x 60 array.

; The lookup table uses an 18-bit address to find the new values for 4 cells.
;
; 12 | 00 01 02 03 | 15
; 13 | 04 05 06 07 | 16
; 14 | 08 09 10 11 | 17
;
; Suppose we take 18 cells in the array (00-17).
; The cells we want to fetch the new values for are 04-07.

.segment "ZPVARS" : zeropage

_life_row1_ptr: .res 1
_life_row2_ptr: .res 1
_life_row3_ptr: .res 1

_life_cell_01_value: .res 1
_life_cell_02_value: .res 1
_life_cell_03_value: .res 1
_life_cell_04_value: .res 1
