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

.include "grid_draw.inc"

.import _current_grid, _work_grid, _grid_buffer_swap
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

.macro _lta_calculate_new_batch_value_macro optimized_read, ppu_buffer_index
    lookup_table_ptr      = gol_ptr1
    column_index          = gol_tmp2
    store_results_ptr     = gol_ptr2

.if optimized_read
    ; We optimize the reading of the lookup table address (lookup_table_bank_num + lookup_table_ptr)
    ; by reusing the values that have already been read for the last batch.
    lda lookup_table_ptr
    lsr
    lsr
    lsr
    lsr
    lsr
    sta MMC3_BANK_DATA  ; Acc. now contains lookup table bank number, switch bank on MMC3

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
    
    stx MMC3_BANK_DATA          ; X now contains lookup table bank number

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

    ldx #0
    lda (lookup_table_ptr, x)               ; Acc. now contains lookup table result

    ; Queue tile to PPU write buffer.
    ; If buffer is full (110 bytes), flush it to the PPU.
    ldx _grid_draw__ppu_copy_buffer_write_index
    .if ppu_buffer_index = 0
        sta _grid_draw__ppu_copy_buffer1, x
    .elseif ppu_buffer_index = 1
        sta _grid_draw__ppu_copy_buffer2, x
    .else
        sta _grid_draw__ppu_copy_buffer3, x
    .endif
    inx
    stx _grid_draw__ppu_copy_buffer_write_index
    cpx #160
    bne :+
        sta regs
        sty column_index                        ; Save column index
        jsr _grid_draw__flush_ppu_copy_buffer
        jsr _grid_draw__switch_ppu_copy_buffer
        ldy column_index
        lda regs

        bne :+
            ; Result set is empty, barely anything to do.
            dey
            rts
    :

    tax
    bne :+
        ; Result set is empty, barely anything to do.
        dey
        rts
    :

    dey
    dey

    lda _lta_store_call_table_lo, x
    sta store_results_ptr
    lda _lta_store_call_table_hi, x
    sta store_results_ptr+1

    jmp (store_results_ptr)
.endmacro

.define _lta_store_call_table _lta_store_lookup_table_result_00, _lta_store_lookup_table_result_01, _lta_store_lookup_table_result_02, _lta_store_lookup_table_result_03, _lta_store_lookup_table_result_04, _lta_store_lookup_table_result_05, _lta_store_lookup_table_result_06, _lta_store_lookup_table_result_07, _lta_store_lookup_table_result_08, _lta_store_lookup_table_result_09, _lta_store_lookup_table_result_10, _lta_store_lookup_table_result_11, _lta_store_lookup_table_result_12, _lta_store_lookup_table_result_13, _lta_store_lookup_table_result_14, _lta_store_lookup_table_result_15

_lta_store_call_table_lo: .lobytes _lta_store_call_table
_lta_store_call_table_hi: .hibytes _lta_store_call_table

.proc _lta_store_lookup_table_result_00
    ; 0 0
    ; 0 0
    iny

    rts
.endproc
.proc _lta_store_lookup_table_result_01
    ; 1 0
    ; 0 0
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    iny

    rts
.endproc
.proc _lta_store_lookup_table_result_02
    ; 0 0
    ; 1 0
    lda #1
    sta (_lta_work_grid_row2_ptr), y
    iny

    rts
.endproc
.proc _lta_store_lookup_table_result_03
    ; 1 0
    ; 1 0
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    sta (_lta_work_grid_row2_ptr), y
    iny

    rts
.endproc
.proc _lta_store_lookup_table_result_04
    ; 0 1
    ; 0 0
    iny
    lda #1
    sta (_lta_work_grid_row1_ptr), y

    rts
.endproc
.proc _lta_store_lookup_table_result_05
    ; 1 1
    ; 0 0
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    iny
    sta (_lta_work_grid_row1_ptr), y

    rts
.endproc
.proc _lta_store_lookup_table_result_06
    ; 0 1
    ; 1 0
    lda #1
    sta (_lta_work_grid_row2_ptr), y
    iny
    sta (_lta_work_grid_row1_ptr), y

    rts
.endproc
.proc _lta_store_lookup_table_result_07
    ; 1 1
    ; 1 0
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    sta (_lta_work_grid_row2_ptr), y
    iny
    sta (_lta_work_grid_row1_ptr), y

    rts
.endproc
.proc _lta_store_lookup_table_result_08
    ; 0 0
    ; 0 1
    iny
    lda #1
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc
.proc _lta_store_lookup_table_result_09
    ; 1 0
    ; 0 1
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    iny
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc
.proc _lta_store_lookup_table_result_10
    ; 0 0
    ; 1 1
    lda #1
    sta (_lta_work_grid_row2_ptr), y
    iny
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc
.proc _lta_store_lookup_table_result_11
    ; 1 0
    ; 1 1
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    sta (_lta_work_grid_row2_ptr), y
    iny
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc
.proc _lta_store_lookup_table_result_12
    ; 0 1
    ; 0 1
    iny
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc
.proc _lta_store_lookup_table_result_13
    ; 1 1
    ; 0 1
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    iny
    sta (_lta_work_grid_row1_ptr), y
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc
.proc _lta_store_lookup_table_result_14
    ; 0 1
    ; 1 1
    lda #1
    sta (_lta_work_grid_row2_ptr), y
    iny
    sta (_lta_work_grid_row1_ptr), y
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc
.proc _lta_store_lookup_table_result_15
    ; 1 1
    ; 1 1
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    sta (_lta_work_grid_row2_ptr), y
    iny
    sta (_lta_work_grid_row1_ptr), y
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc

.proc _lta_calculate_new_batch_value_buf1
    _lta_calculate_new_batch_value_macro FALSE, 0
.endproc

.proc _lta_calculate_new_batch_value_optimized_read_buf1
    _lta_calculate_new_batch_value_macro TRUE, 0
.endproc

.proc _lta_calculate_new_batch_value_buf2
    _lta_calculate_new_batch_value_macro FALSE, 1
.endproc

.proc _lta_calculate_new_batch_value_optimized_read_buf2
    _lta_calculate_new_batch_value_macro TRUE, 1
.endproc

.proc _lta_calculate_new_batch_value_buf3
    _lta_calculate_new_batch_value_macro FALSE, 2
.endproc

.proc _lta_calculate_new_batch_value_optimized_read_buf3
    _lta_calculate_new_batch_value_macro TRUE, 2
.endproc

.proc _lta_display_next_generation
    ; Switch bank on MMC3
    lda #bank_reg::BANK_REG_8K_PRG_0
    sta MMC3_BANK_SELECT ; TODO : Probably don't need to do this every batch..

    jsr _lta_init                  ; Init life grid row pointers

.repeat 5
    ldy #0                     ; Set column index

    jsr _lta_calculate_new_batch_value_buf1
    .repeat 31
        jsr _lta_calculate_new_batch_value_optimized_read_buf1
    .endrepeat

    jsr _lta_next_batch_row    ; Increment row pointers for next batch row
.endrepeat
.repeat 5
    ldy #0                     ; Set column index

    jsr _lta_calculate_new_batch_value_buf2
    .repeat 31
        jsr _lta_calculate_new_batch_value_optimized_read_buf2
    .endrepeat

    jsr _lta_next_batch_row    ; Increment row pointers for next batch row
.endrepeat
.repeat 5
    ldy #0                     ; Set column index

    jsr _lta_calculate_new_batch_value_buf3
    .repeat 31
        jsr _lta_calculate_new_batch_value_optimized_read_buf3
    .endrepeat

    jsr _lta_next_batch_row    ; Increment row pointers for next batch row
.endrepeat
.repeat 5
    ldy #0                     ; Set column index

    jsr _lta_calculate_new_batch_value_buf1
    .repeat 31
        jsr _lta_calculate_new_batch_value_optimized_read_buf1
    .endrepeat

    jsr _lta_next_batch_row    ; Increment row pointers for next batch row
.endrepeat
.repeat 5
    ldy #0                     ; Set column index

    jsr _lta_calculate_new_batch_value_buf2
    .repeat 31
        jsr _lta_calculate_new_batch_value_optimized_read_buf2
    .endrepeat

    jsr _lta_next_batch_row    ; Increment row pointers for next batch row
.endrepeat
.repeat 5
    ldy #0                     ; Set column index

    jsr _lta_calculate_new_batch_value_buf3
    .repeat 31
        jsr _lta_calculate_new_batch_value_optimized_read_buf3
    .endrepeat

    jsr _lta_next_batch_row    ; Increment row pointers for next batch row
.endrepeat

    jsr _grid_buffer_swap
    jsr _grid_draw__flush_ppu_copy_buffer
    jsr _grid_draw__switch_nametable

    rts
.endproc
