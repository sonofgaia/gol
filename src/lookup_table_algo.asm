; This file implements an algorithm using a lookup table to speed up the process of applying
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
.import _ppu_copy_buffer, _ppu_copy_buffer_write_index
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

.macro set_xreg_bits_if_zero_flag_off bitmask
    beq :+
        txa
        ora #bitmask
        tax
    :
.endmacro

.macro _lta_calculate_new_batch_value_macro optimized_read
    lookup_table_bank_num = gol_tmp1
    lookup_table_ptr      = gol_ptr1
    column_index          = gol_tmp2

.if optimized_read
    ; We optimize the reading of the lookup table address (lookup_table_bank_num + lookup_table_ptr)
    ; by reusing the values that have already been read for the last batch.
    lda lookup_table_ptr
    ror
    ror
    ror
    ror
    ror
    sta lookup_table_bank_num

    lda lookup_table_ptr
    and #$1F
    ora #$80
    sta lookup_table_ptr+1

    iny
    iny
.else
    ldx #0

    ; Get lookup table bank number
    lda (_lta_row1_ptr), y
    set_xreg_bits_if_zero_flag_off $04

    lda (_lta_row2_ptr), y
    set_xreg_bits_if_zero_flag_off $02
    
    lda (_lta_row3_ptr), y
    set_xreg_bits_if_zero_flag_off $01
    
    stx lookup_table_bank_num

    ldx #$80                    ; Lookup table chunk is swapped in at 0x8000.

    ; Get lookup table pointer
    lda (_lta_row4_ptr), y
    set_xreg_bits_if_zero_flag_off $10

    iny ; Next column

    lda (_lta_row1_ptr), y
    set_xreg_bits_if_zero_flag_off $08

    lda (_lta_row2_ptr), y
    set_xreg_bits_if_zero_flag_off $04

    lda (_lta_row3_ptr), y
    set_xreg_bits_if_zero_flag_off $02
    
    lda (_lta_row4_ptr), y
    set_xreg_bits_if_zero_flag_off $01

    stx lookup_table_ptr+1

    iny ; Next column
.endif

    ldx #0                  ; New value for lookup_table_ptr is generated in 'X'.

    lda (_lta_row1_ptr), y
    set_xreg_bits_if_zero_flag_off $80

    lda (_lta_row2_ptr), y
    set_xreg_bits_if_zero_flag_off $40

    lda (_lta_row3_ptr), y
    set_xreg_bits_if_zero_flag_off $20
    
    lda (_lta_row4_ptr), y
    set_xreg_bits_if_zero_flag_off $10

    iny ; Next column

    lda (_lta_row1_ptr), y
    set_xreg_bits_if_zero_flag_off $08

    lda (_lta_row2_ptr), y
    set_xreg_bits_if_zero_flag_off $04

    lda (_lta_row3_ptr), y
    set_xreg_bits_if_zero_flag_off $02
    
    lda (_lta_row4_ptr), y
    set_xreg_bits_if_zero_flag_off $01

    stx lookup_table_ptr

    sty column_index                        ; Save column index

    ; Switch bank on MMC3
    ldx #bank_reg::BANK_REG_8K_PRG_0
    ldy lookup_table_bank_num 
    __mmc3_switch_bank_inline TRUE, FALSE   ; Mode '0', not called from interrupt
    
    ldy #0
    lda (lookup_table_ptr), y               ; Acc. now contains lookup table result

    ; Queue tile to PPU write buffer.
    ; If buffer is full (64 bytes), flush it to the PPU.
    ldx _ppu_copy_buffer_write_index
    sta _ppu_copy_buffer, x
    inx
    stx _ppu_copy_buffer_write_index
    cpx #80
    bne :+
        sta regs
        jsr _grid_draw__flush_ppu_copy_buffer
        lda regs
    :

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
.endmacro

;;-------------------------------------------------------------------------------------------------
;; Routine : _lta_calculate_new_batch_value
;;-------------------------------------------------------------------------------------------------
;; Calculates the new batch value using the lookup table.
;;
;; Params
;;      Current column index (passed in the Y register)
;;-------------------------------------------------------------------------------------------------
.proc _lta_calculate_new_batch_value
    _lta_calculate_new_batch_value_macro FALSE
.endproc

;;-------------------------------------------------------------------------------------------------
;; Routine : _lta_calculate_new_batch_value_optimized_read
;;-------------------------------------------------------------------------------------------------
;; Calculates the new batch value using the lookup table.
;;
;; Params
;;      Current column index (passed in the Y register)
;;-------------------------------------------------------------------------------------------------
.proc _lta_calculate_new_batch_value_optimized_read
    _lta_calculate_new_batch_value_macro TRUE
.endproc

.proc _lta_display_next_generation
    ; We traverse the array and calculate the results in batches of 2x2 cells.
    ; This gives us 32 batches horizontally and 30 batches vertically.
    lda #30
    sta _lta_row_counter

    jsr _lta_init              ; Init life grid row pointers

@row_loop:
    ldy #0                     ; Set column index

    jsr _lta_calculate_new_batch_value
.repeat 31
    jsr _lta_calculate_new_batch_value_optimized_read
.endrepeat

    jsr _lta_next_batch_row    ; Increment row pointers for next batch row

    dec _lta_row_counter
    bne @row_loop

    jsr _grid_buffer_swap
    jsr _grid_draw__flush_ppu_copy_buffer
    jsr _grid_draw__switch_nametable

    rts
.endproc
