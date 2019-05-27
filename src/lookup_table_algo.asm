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
.import _grid_draw__tile_write_callback
.import _grid_draw__switch_nametable
.import _grid_draw__flush_ppu_copy_buffer
.import incaxy
.export _lta_display_next_generation

.include "mmc3.inc"
.include "lib.inc"
.include "zeropage.inc"

.segment "ZPVARS" : zeropage

_lta_row1_ptr: .res 2
_lta_row2_ptr: .res 2
_lta_row3_ptr: .res 2
_lta_row4_ptr: .res 2

_lta_work_grid_row1_ptr: .res 2
_lta_work_grid_row2_ptr: .res 2

_lta_row_counter: .res 1

.segment "LOOKUP_TABLE"
.incbin "build/bin/lookup_table.bin"

.segment "CODE"

;;-------------------------------------------------------------------------------------------------
;; Routine : _lta_init
;;-------------------------------------------------------------------------------------------------
;; Initializes the pointers used to traverse the life grid.
;;-------------------------------------------------------------------------------------------------
.proc _lta_init
    ldx _current_grid+1
    stx _lta_row1_ptr+1
    lda _current_grid      ; A/X now contains a copy of _current_grid pointer
    sta _lta_row1_ptr      ; row1 pointer is now equal to _current_grid

    ldy #66                ; Next row has a 66 byte offset
    jsr incaxy             ; Increment A/X pointer by 66 bytes
    stx _lta_row2_ptr+1
    sta _lta_row2_ptr      ; row2 pointer is now equal to _current_grid + 66 bytes (second row)

    jsr incaxy             ; Increment A/X by another 66 bytes
    stx _lta_row3_ptr+1
    sta _lta_row3_ptr      ; row3 pointer is now equal to _current_grid + 132 bytes (third row)

    jsr incaxy             ; Increment A/X by another 66 bytes
    stx _lta_row4_ptr+1
    sta _lta_row4_ptr      ; row4 pointer is now equal to _current_grid + 198 bytes (fourth row)

    ldx _work_grid+1
    lda _work_grid
    jsr incaxy
    stx _lta_work_grid_row1_ptr+1
    sta _lta_work_grid_row1_ptr    ; Init work grid row1 pointer

    jsr incaxy
    stx _lta_work_grid_row2_ptr+1
    sta _lta_work_grid_row2_ptr    ; Init work grid row2 pointer

    rts
.endproc

;;-------------------------------------------------------------------------------------------------
;; Routine : _lta_next_batch_row
;;-------------------------------------------------------------------------------------------------
;; Increments the row pointers so that they point to the next batch row.
;;-------------------------------------------------------------------------------------------------
.proc _lta_next_batch_row
    ldx _lta_row3_ptr+1
    stx _lta_row1_ptr+1
    lda _lta_row3_ptr
    sta _lta_row1_ptr      ; row1 pointer inherits row3 pointer's old value

    ldy #132
    jsr incaxy
    stx _lta_row3_ptr+1
    sta _lta_row3_ptr      ; row3 pointer's old value is incremented by two rows (132 bytes) to obtain it's new value.

    ldx _lta_row4_ptr+1
    stx _lta_row2_ptr+1
    lda _lta_row4_ptr
    sta _lta_row2_ptr      ; row2 pointer inherits row4 pointer's old value

    jsr incaxy
    stx _lta_row4_ptr+1
    sta _lta_row4_ptr      ; row4 pointer's old value is incremented by two rows (132 bytes) to obtain it's new value.

    ldx _lta_work_grid_row1_ptr+1
    lda _lta_work_grid_row1_ptr
    jsr incaxy
    stx _lta_work_grid_row1_ptr+1
    sta _lta_work_grid_row1_ptr

    ldx _lta_work_grid_row2_ptr+1
    lda _lta_work_grid_row2_ptr
    jsr incaxy
    stx _lta_work_grid_row2_ptr+1
    sta _lta_work_grid_row2_ptr

    rts
.endproc

;;-------------------------------------------------------------------------------------------------
;; Routine : _lta_calculate_new_batch_value
;;-------------------------------------------------------------------------------------------------
;; Calculates the new batch value using the lookup table.
;;
;; Params
;;      Current column index (passed in the Y register)
;;-------------------------------------------------------------------------------------------------
.proc _lta_calculate_new_batch_value
    lookup_table_bank_num = tmp1
    lookup_table_ptr      = ptr1
    column_index          = tmp2

    lda #0
    sta lookup_table_bank_num
    sta lookup_table_ptr
    sta lookup_table_ptr+1

    ; Get lookup table number
    lda (_lta_row1_ptr), y
    lsr
    rol lookup_table_bank_num

    lda (_lta_row2_ptr), y
    lsr
    rol lookup_table_bank_num
    
    lda (_lta_row3_ptr), y
    lsr
    rol lookup_table_bank_num

    ; Get lookup table pointer
    lda (_lta_row4_ptr), y
    lsr
    rol lookup_table_ptr+1

    iny ; Next column

    lda (_lta_row1_ptr), y
    lsr
    rol lookup_table_ptr+1

    lda (_lta_row2_ptr), y
    lsr
    rol lookup_table_ptr+1

    lda (_lta_row3_ptr), y
    lsr
    rol lookup_table_ptr+1
    
    lda (_lta_row4_ptr), y
    lsr
    rol lookup_table_ptr+1

    ; Lookup table is swapped in at 0x8000, add this to the pointer value
    lda lookup_table_ptr+1
    ora #$80
    sta lookup_table_ptr+1

    iny ; Next column

    lda (_lta_row1_ptr), y
    lsr
    rol lookup_table_ptr

    lda (_lta_row2_ptr), y
    lsr
    rol lookup_table_ptr

    lda (_lta_row3_ptr), y
    lsr
    rol lookup_table_ptr
    
    lda (_lta_row4_ptr), y
    lsr
    rol lookup_table_ptr

    iny ; Next column

    lda (_lta_row1_ptr), y
    lsr
    rol lookup_table_ptr

    lda (_lta_row2_ptr), y
    lsr
    rol lookup_table_ptr

    lda (_lta_row3_ptr), y
    lsr
    rol lookup_table_ptr
    
    lda (_lta_row4_ptr), y
    lsr
    rol lookup_table_ptr

    sty column_index                        ; Save column index

    ; Switch bank on MMC3
    ldx #bank_reg::BANK_REG_8K_PRG_0
    ldy lookup_table_bank_num 
    __mmc3_switch_bank_inline TRUE, FALSE   ; Mode '0', not called from interrupt
    
    ldy #0
    lda (lookup_table_ptr), y               ; Acc. now contains lookup table result

    save_registers_user
    jsr _grid_draw__tile_write_callback
    restore_registers_user

    ; Store new first cell value
    lsr
    tax                                     ; Save Acc to X
    lda #0
    adc #0                                  ; Add carry to Acc
    ldy column_index
    dey
    dey
    sta (_lta_work_grid_row1_ptr), y
    
    ; Store new second cell value
    txa                                     ; Restore Acc from X
    lsr
    tax                                     ; Save Acc to X
    lda #0
    adc #0                                  ; Add carry to Acc
    sta (_lta_work_grid_row2_ptr), y

    ; Store new third cell value
    txa                                     ; Restore Acc from X
    lsr
    tax                                     ; Save Acc to X
    lda #0
    adc #0                                  ; Add carry to Acc
    iny
    sta (_lta_work_grid_row1_ptr), y

    ; Store new fourth cell value
    txa                                     ; Restore Acc from X
    lsr
    tax                                     ; Save Acc to X
    lda #0
    adc #0                                  ; Add carry to Acc
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc

.proc _lta_display_next_generation
    ; We traverse the array and calculate the results in batches of 2x2 cells.
    ; This gives us 32 batches horizontally and 30 batches vertically.
    lda #30
    sta _lta_row_counter

    jsr _lta_init              ; Init life grid row pointers

@row_loop:
    ldy #0                     ; Set column index

    .repeat 32
        jsr _lta_calculate_new_batch_value
    .endrepeat

    jsr _lta_next_batch_row    ; Increment row pointers for next batch row

    dec _lta_row_counter
    bne @row_loop

    jsr _grid_buffer_swap
    jsr _grid_draw__flush_ppu_copy_buffer
    jsr _grid_draw__switch_nametable

    rts
.endproc
