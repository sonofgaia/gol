; This file implements an algorithm using a lookup table to (hopefully) speed up the process of applying
; the rules for Life on our 64 x 60 array.

; The lookup table uses a 16-bit address to find the new values for 4 cells.
;
; 00 01 02 03
; 04 05 06 07
; 08 09 10 11
; 12 13 14 15
;
; Suppose we take 16 cells in the array (00-15).
; The cells we want to fetch the new values for are 05, 06, 09 and 10.

.import _current_grid, _work_grid, _grid_buffer_swap
.export _life_apply_rules

.segment "ZPVARS" : zeropage

_life_row1_ptr: .res 1
_life_row2_ptr: .res 1
_life_row3_ptr: .res 1
_life_row4_ptr: .res 1

_life_row_counter: .res 1
_life_col_counter: .res 1

.proc _life_apply_rules
    ; We traverse the array and calculate the results in batches of 2x2 cells.
    ; This gives us 32 batches horizontally and 30 batches vertically.
    lda #32
    sta _life_row_counter

@row_loop:
    lda #30
    sta _life_col_counter

    @col_loop:
        dec _life_col_counter
        bne @col_loop

    dec _life_row_counter
    bne @row_loop

    rts
.endproc
