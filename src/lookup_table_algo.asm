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
.import incaxy, decaxy
.export _lta_display_next_generation

.include "mmc3.inc"
.include "lib.inc"
.include "zeropage.inc"

.linecont + ; Allow line continuation with '\'.

.segment "ZPVARS" : zeropage

_lta_row1_ptr: .res 2
_lta_row2_ptr: .res 2
_lta_row3_ptr: .res 2
_lta_row4_ptr: .res 2

_lta_first_row_ptr: .res 2
_lta_last_row_ptr:  .res 2

_lta_work_grid_row1_ptr: .res 2
_lta_work_grid_row2_ptr: .res 2

.segment "LOOKUP_TABLE"
.incbin "build/bin/lookup_table.bin"

.segment "LTA_CODE1"
store_results_ptr = gol_ptr4

;;-------------------------------------------------------------------------------------------------
;; Routine : _lta_init
;;-------------------------------------------------------------------------------------------------
;; Initializes the pointers used to traverse the life grid.
;;-------------------------------------------------------------------------------------------------
.proc _lta_init
    ldx _current_grid+1
    lda _current_grid
    stx _lta_row2_ptr+1
    sta _lta_row2_ptr
    stx _lta_first_row_ptr+1
    sta _lta_first_row_ptr      ; _current_grid = _lta_row2_ptr = _lta_first_row_ptr

    ldy #64
    jsr decaxy
    stx _lta_row1_ptr+1
    sta _lta_row1_ptr

    ldx _current_grid+1
    lda _current_grid      ; A/X now contains a copy of _current_grid pointer

    jsr incaxy             ; Increment A/X pointer by 64 bytes
    stx _lta_row3_ptr+1
    sta _lta_row3_ptr      ; row2 pointer is now equal to _current_grid + 64 bytes (second row)

    jsr incaxy             ; Increment A/X by another 64 bytes
    stx _lta_row4_ptr+1
    sta _lta_row4_ptr      ; row3 pointer is now equal to _current_grid + 128 bytes (third row)

    ldx _work_grid+1
    lda _work_grid
    stx _lta_work_grid_row1_ptr+1
    sta _lta_work_grid_row1_ptr             ; Init work grid row1 pointer

    jsr incaxy
    stx _lta_work_grid_row2_ptr+1
    sta _lta_work_grid_row2_ptr             ; Init work grid row2 pointer

    lda #>_lta_store_lookup_table_result_00
    sta store_results_ptr+1                 ; High byte of pointer was made constant for performance.

    lda _current_grid+1
    clc
    adc #14  ; Add 14 pages (3584 bytes)
    sta _lta_last_row_ptr+1
    lda #192 ; Add 192 bytes
    sta _lta_last_row_ptr                   ; Last row ptr is now equal to _current_grid + 3776 bytes (59 rows)

    rts
.endproc

;;-------------------------------------------------------------------------------------------------
;; Routine : _lta_next_batch_row
;;-------------------------------------------------------------------------------------------------
;; Increments the row pointers so that they point to the next batch row.
;;-------------------------------------------------------------------------------------------------
.proc _lta_next_batch_row
    inc _lta_row1_ptr+1
    inc _lta_row2_ptr+1
    inc _lta_row3_ptr+1
    inc _lta_row4_ptr+1
    inc _lta_work_grid_row1_ptr+1
    inc _lta_work_grid_row2_ptr+1

    rts
.endproc

.macro set_xreg_bits_if_zero_flag_off bitmask
    beq :+
        txa
        ora #bitmask
        tax
    :
.endmacro

.macro add_tile_to_ppu_write_buffer ppu_buffer_index
    ldx _grid_draw__ppu_copy_buffer_write_index
    .if ppu_buffer_index = 0
        sta _grid_draw__ppu_copy_buffer1, x
    .elseif ppu_buffer_index = 1
        sta _grid_draw__ppu_copy_buffer2, x
    .else
        sta _grid_draw__ppu_copy_buffer3, x
    .endif
    inc _grid_draw__ppu_copy_buffer_write_index
.endmacro

.macro load_lookup_results_and_store_to_grid ppu_buffer_index
    ldx #0
    lda (lookup_table_ptr, x)               ; Acc. now contains lookup table result
    bne :+
        ; No living cells in results, we don't need to update the work grid.
        add_tile_to_ppu_write_buffer ppu_buffer_index
        dey

        rts
    :

    add_tile_to_ppu_write_buffer ppu_buffer_index

    sta store_results_ptr                   ; Result is used as low-byte of function pointer.  High-byte is constant.
    jmp (store_results_ptr)
.endmacro

.macro optimized_read_of_lookup_table_ptr_hi
    ; We optimize the reading of the lookup table address (lookup_table_bank_num + lookup_table_ptr)
    ; by reusing the values that have already been read for the last batch.
    ldx lookup_table_ptr
    lda lsr5_lookup_table, x
    sta MMC3_BANK_DATA

    lda and1f_or80_lookup_table, x
    sta lookup_table_ptr+1

    iny
    iny
.endmacro

.macro _lta_calc_batch_macro first_column, last_column, first_row, last_row, ppu_buffer_index, use_long_y_offset
    lookup_table_ptr = gol_ptr1
    column_index     = gol_tmp2

.if first_row
    .if first_column ; Upper-left corner
        ; Get lookup table bank number
        ldx #0

        ldy #63 
        lda (_lta_last_row_ptr), y          ; Last column of last row
        set_xreg_bits_if_zero_flag_off $04

        lda (_lta_row2_ptr), y              ; Last column of first row
        set_xreg_bits_if_zero_flag_off $02

        lda (_lta_row3_ptr), y              ; Last column of second row
        set_xreg_bits_if_zero_flag_off $01

        stx MMC3_BANK_DATA                  ; X now contains lookup table bank number

        ldx #$80                            ; Lookup table chunk is swapped in at 0x8000.

        ; Get lookup table pointer
        lda (_lta_row4_ptr), y              ; Last column of third row
        set_xreg_bits_if_zero_flag_off $10

        ldy #0 ; Next column

        lda (_lta_last_row_ptr), y
        set_xreg_bits_if_zero_flag_off $08

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $04

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $02
        
        lda (_lta_row4_ptr), y
        set_xreg_bits_if_zero_flag_off $01

        stx lookup_table_ptr+1

        iny ; Next column

        ldx #0                              ; New value for lookup_table_ptr is generated in 'X'.

        lda (_lta_last_row_ptr), y
        set_xreg_bits_if_zero_flag_off $80

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $40

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $20
        
        lda (_lta_row4_ptr), y
        set_xreg_bits_if_zero_flag_off $10

        iny ; Next column

        lda (_lta_last_row_ptr), y
        set_xreg_bits_if_zero_flag_off $08

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $04

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $02
        
        lda (_lta_row4_ptr), y
        set_xreg_bits_if_zero_flag_off $01

        stx lookup_table_ptr

        load_lookup_results_and_store_to_grid ppu_buffer_index
    .elseif last_column ; Upper-right corner
        optimized_read_of_lookup_table_ptr_hi

        ldx #0                                  ; New value for lookup_table_ptr is generated in 'X'.

        lda (_lta_last_row_ptr), y
        set_xreg_bits_if_zero_flag_off $80

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $40

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $20
        
        lda (_lta_row4_ptr), y
        set_xreg_bits_if_zero_flag_off $10

        sty column_index ; TODO : Figure out exact Y-value here so we can load it later instead of storing then loading it.
        ldy #0

        lda (_lta_last_row_ptr), y
        set_xreg_bits_if_zero_flag_off $08

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $04

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $02
        
        lda (_lta_row4_ptr), y
        set_xreg_bits_if_zero_flag_off $01

        stx lookup_table_ptr
        ldy column_index
        iny

        load_lookup_results_and_store_to_grid ppu_buffer_index
    .else ; First row (generic)
        optimized_read_of_lookup_table_ptr_hi

        ldx #0                                  ; New value for lookup_table_ptr is generated in 'X'.

        lda (_lta_last_row_ptr), y
        set_xreg_bits_if_zero_flag_off $80

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $40

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $20
        
        lda (_lta_row4_ptr), y
        set_xreg_bits_if_zero_flag_off $10

        iny ; Next column

        lda (_lta_last_row_ptr), y
        set_xreg_bits_if_zero_flag_off $08

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $04

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $02
        
        lda (_lta_row4_ptr), y
        set_xreg_bits_if_zero_flag_off $01

        stx lookup_table_ptr

        load_lookup_results_and_store_to_grid ppu_buffer_index
    .endif
.elseif last_row
    .if first_column ; Lower-left corner
        ; Get lookup table bank number
        ldx #0

        ldy #191
        lda (_lta_row1_ptr), y
        set_xreg_bits_if_zero_flag_off $04

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $02

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $01

        stx MMC3_BANK_DATA                  ; X now contains lookup table bank number

        ldx #$80                            ; Lookup table chunk is swapped in at 0x8000.

        ; Get lookup table pointer
        lda (_lta_first_row_ptr), y
        set_xreg_bits_if_zero_flag_off $10

        ldy #128 ; Next column

        lda (_lta_row1_ptr), y
        set_xreg_bits_if_zero_flag_off $08

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $04

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $02
        
        lda (_lta_first_row_ptr), y
        set_xreg_bits_if_zero_flag_off $01

        stx lookup_table_ptr+1

        iny ; Next column

        ldx #0                              ; New value for lookup_table_ptr is generated in 'X'.

        lda (_lta_row1_ptr), y
        set_xreg_bits_if_zero_flag_off $80

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $40

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $20
        
        lda (_lta_first_row_ptr), y
        set_xreg_bits_if_zero_flag_off $10

        iny ; Next column

        lda (_lta_row1_ptr), y
        set_xreg_bits_if_zero_flag_off $08

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $04

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $02
        
        lda (_lta_first_row_ptr), y
        set_xreg_bits_if_zero_flag_off $01

        stx lookup_table_ptr

        load_lookup_results_and_store_to_grid ppu_buffer_index
    .elseif last_column ; Lower-right corner
        optimized_read_of_lookup_table_ptr_hi

        ldx #0                                  ; New value for lookup_table_ptr is generated in 'X'.

        lda (_lta_row1_ptr), y
        set_xreg_bits_if_zero_flag_off $80

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $40

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $20
        
        lda (_lta_first_row_ptr), y
        set_xreg_bits_if_zero_flag_off $10

        sty column_index    ; TODO : Figure out exact y-value so that we don't have to store then load.
        ldy #128

        lda (_lta_row1_ptr), y
        set_xreg_bits_if_zero_flag_off $08

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $04

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $02
        
        lda (_lta_first_row_ptr), y
        set_xreg_bits_if_zero_flag_off $01

        stx lookup_table_ptr
        ldy column_index
        iny

        load_lookup_results_and_store_to_grid ppu_buffer_index
    .else ; Last row (generic)
        optimized_read_of_lookup_table_ptr_hi

        ldx #0                                  ; New value for lookup_table_ptr is generated in 'X'.

        lda (_lta_row1_ptr), y
        set_xreg_bits_if_zero_flag_off $80

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $40

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $20
        
        lda (_lta_first_row_ptr), y
        set_xreg_bits_if_zero_flag_off $10

        iny ; Next column

        lda (_lta_row1_ptr), y
        set_xreg_bits_if_zero_flag_off $08

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $04

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $02
        
        lda (_lta_first_row_ptr), y
        set_xreg_bits_if_zero_flag_off $01

        stx lookup_table_ptr

        load_lookup_results_and_store_to_grid ppu_buffer_index
    .endif
.else
    .if first_column ; Middle row, first column
        ; Get lookup table bank number
        ldx #0

        .if use_long_y_offset
            ldy #191
        .else
            ldy #63
        .endif
        lda (_lta_row1_ptr), y          ; Last column of last row
        set_xreg_bits_if_zero_flag_off $04

        lda (_lta_row2_ptr), y              ; Last column of first row
        set_xreg_bits_if_zero_flag_off $02

        lda (_lta_row3_ptr), y              ; Last column of second row
        set_xreg_bits_if_zero_flag_off $01

        stx MMC3_BANK_DATA                  ; X now contains lookup table bank number

        ldx #$80                            ; Lookup table chunk is swapped in at 0x8000.

        ; Get lookup table pointer
        lda (_lta_row4_ptr), y              ; Last column of third row
        set_xreg_bits_if_zero_flag_off $10

        .if use_long_y_offset
            ldy #128 ; Next column
        .else
            ldy #0 ; Next column
        .endif

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

        ldx #0                              ; New value for lookup_table_ptr is generated in 'X'.

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

        load_lookup_results_and_store_to_grid ppu_buffer_index
    .elseif last_column ; Middle row, last column
        optimized_read_of_lookup_table_ptr_hi

        ldx #0                                  ; New value for lookup_table_ptr is generated in 'X'.

        lda (_lta_row1_ptr), y
        set_xreg_bits_if_zero_flag_off $80

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $40

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $20
        
        lda (_lta_row4_ptr), y
        set_xreg_bits_if_zero_flag_off $10

        sty column_index    ; TODO : Figure out exact offset
        .if use_long_y_offset
            ldy #128
        .else
            ldy #0
        .endif

        lda (_lta_row1_ptr), y
        set_xreg_bits_if_zero_flag_off $08

        lda (_lta_row2_ptr), y
        set_xreg_bits_if_zero_flag_off $04

        lda (_lta_row3_ptr), y
        set_xreg_bits_if_zero_flag_off $02
        
        lda (_lta_row4_ptr), y
        set_xreg_bits_if_zero_flag_off $01

        stx lookup_table_ptr
        ldy column_index
        iny

        load_lookup_results_and_store_to_grid ppu_buffer_index
    .else ; Middle row (generic)
        optimized_read_of_lookup_table_ptr_hi

        ldx #0                                  ; New value for lookup_table_ptr is generated in 'X'.

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

        load_lookup_results_and_store_to_grid ppu_buffer_index
    .endif
.endif
.endmacro

.segment "LTA_CODE2"

.align 16
.proc _lta_store_lookup_table_result_00
    ; 0 0
    ; 0 0
    dey

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_01
    ; 1 0
    ; 0 0
    dey
    dey
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    iny

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_02
    ; 0 0
    ; 1 0
    dey
    dey
    lda #1
    sta (_lta_work_grid_row2_ptr), y
    iny

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_03
    ; 1 0
    ; 1 0
    dey
    dey
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    sta (_lta_work_grid_row2_ptr), y
    iny

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_04
    ; 0 1
    ; 0 0
    dey
    lda #1
    sta (_lta_work_grid_row1_ptr), y

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_05
    ; 1 1
    ; 0 0
    dey
    dey
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    iny
    sta (_lta_work_grid_row1_ptr), y

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_06
    ; 0 1
    ; 1 0
    dey
    dey
    lda #1
    sta (_lta_work_grid_row2_ptr), y
    iny
    sta (_lta_work_grid_row1_ptr), y

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_07
    ; 1 1
    ; 1 0
    dey
    dey
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    sta (_lta_work_grid_row2_ptr), y
    iny
    sta (_lta_work_grid_row1_ptr), y

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_08
    ; 0 0
    ; 0 1
    dey
    lda #1
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_09
    ; 1 0
    ; 0 1
    dey
    dey
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    iny
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_10
    ; 0 0
    ; 1 1
    dey
    dey
    lda #1
    sta (_lta_work_grid_row2_ptr), y
    iny
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_11
    ; 1 0
    ; 1 1
    dey
    dey
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    sta (_lta_work_grid_row2_ptr), y
    iny
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_12
    ; 0 1
    ; 0 1
    dey
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_13
    ; 1 1
    ; 0 1
    dey
    dey
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    iny
    sta (_lta_work_grid_row1_ptr), y
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_14
    ; 0 1
    ; 1 1
    dey
    dey
    lda #1
    sta (_lta_work_grid_row2_ptr), y
    iny
    sta (_lta_work_grid_row1_ptr), y
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_15
    ; 1 1
    ; 1 1
    dey
    dey
    lda #1
    sta (_lta_work_grid_row1_ptr), y
    sta (_lta_work_grid_row2_ptr), y
    iny
    sta (_lta_work_grid_row1_ptr), y
    sta (_lta_work_grid_row2_ptr), y

    rts
.endproc

.segment "LTA_CODE1"

.proc _lta_calc_batch_upper_left_corner
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro TRUE, FALSE, TRUE, FALSE, 0, FALSE
.endproc

.proc _lta_calc_batch_upper_right_corner
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro FALSE, TRUE, TRUE, FALSE, 0, FALSE
.endproc

.proc _lta_calc_batch_first_row
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro FALSE, FALSE, TRUE, FALSE, 0, FALSE
.endproc

.proc _lta_calc_batch_lower_left_corner
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro TRUE, FALSE, FALSE, TRUE, 2, FALSE
.endproc

.proc _lta_calc_batch_lower_right_corner
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro FALSE, TRUE, FALSE, TRUE, 2, FALSE
.endproc

.proc _lta_calc_batch_last_row
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro FALSE, FALSE, FALSE, TRUE, 2, FALSE
.endproc

.proc _lta_calc_batch_first_column_buf1
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro TRUE, FALSE, FALSE, FALSE, 0, FALSE
.endproc

.proc _lta_calc_batch_first_column_buf2
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro TRUE, FALSE, FALSE, FALSE, 1, FALSE
.endproc

.proc _lta_calc_batch_first_column_buf3
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro TRUE, FALSE, FALSE, FALSE, 2, FALSE
.endproc

.proc _lta_calc_batch_last_column_buf1
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro FALSE, TRUE, FALSE, FALSE, 0, FALSE
.endproc

.proc _lta_calc_batch_last_column_buf2
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro FALSE, TRUE, FALSE, FALSE, 1, FALSE
.endproc

.proc _lta_calc_batch_last_column_buf3
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro FALSE, TRUE, FALSE, FALSE, 2, FALSE
.endproc

.proc _lta_calc_batch_generic_buf1
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro FALSE, FALSE, FALSE, FALSE, 0, FALSE
.endproc

.proc _lta_calc_batch_generic_buf2
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro FALSE, FALSE, FALSE, FALSE, 1, FALSE
.endproc

.proc _lta_calc_batch_generic_buf3
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro FALSE, FALSE, FALSE, FALSE, 2, FALSE
.endproc

.proc _lta_calc_batch_first_column_buf1_long_y_offset
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro TRUE, FALSE, FALSE, FALSE, 0, TRUE
.endproc

.proc _lta_calc_batch_first_column_buf2_long_y_offset
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro TRUE, FALSE, FALSE, FALSE, 1, TRUE
.endproc

.proc _lta_calc_batch_first_column_buf3_long_y_offset
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro TRUE, FALSE, FALSE, FALSE, 2, TRUE
.endproc

.proc _lta_calc_batch_last_column_buf1_long_y_offset
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro FALSE, TRUE, FALSE, FALSE, 0, TRUE
.endproc

.proc _lta_calc_batch_last_column_buf2_long_y_offset
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro FALSE, TRUE, FALSE, FALSE, 1, TRUE
.endproc

.proc _lta_calc_batch_last_column_buf3_long_y_offset
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro FALSE, TRUE, FALSE, FALSE, 2, TRUE
.endproc

.proc _lta_calc_batch_generic_buf1_long_y_offset
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro FALSE, FALSE, FALSE, FALSE, 0, TRUE
.endproc

.proc _lta_calc_batch_generic_buf2_long_y_offset
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro FALSE, FALSE, FALSE, FALSE, 1, TRUE
.endproc

.proc _lta_calc_batch_generic_buf3_long_y_offset
    ; Params : first_column, last_column, first_row, last_row, ppu_buffer_index
    _lta_calc_batch_macro FALSE, FALSE, FALSE, FALSE, 2, TRUE
.endproc

.macro calculate_batch_row_func_calls func1, func2, func3
    jsr func1
    .repeat 30
        jsr func2
    .endrepeat
    jsr func3
.endmacro

.macro calculate_batch_row_macro row_number
    .if row_number = 1
        calculate_batch_row_func_calls _lta_calc_batch_upper_left_corner, \
                                       _lta_calc_batch_first_row, \
                                       _lta_calc_batch_upper_right_corner
    .elseif row_number = 30
        calculate_batch_row_func_calls _lta_calc_batch_lower_left_corner, \
                                       _lta_calc_batch_last_row, \
                                       _lta_calc_batch_lower_right_corner

        jsr _grid_draw__flush_ppu_copy_buffer
        jsr _grid_draw__switch_ppu_copy_buffer
    .else
        use_long_y_offset .set ((row_number .mod 2) = 0)        ; Use long Y offset every second row.
        flush_buffer      .set ((row_number .mod 5) = 0)        ; Flush buffer every 5 rows.
        buffer_number     .set (((row_number - 1) / 5) .mod 3) + 1

        .if use_long_y_offset
            calculate_batch_row_func_calls .ident(.sprintf("_lta_calc_batch_first_column_buf%d_long_y_offset", buffer_number)), \
                                           .ident(.sprintf("_lta_calc_batch_generic_buf%d_long_y_offset", buffer_number)), \
                                           .ident(.sprintf("_lta_calc_batch_last_column_buf%d_long_y_offset", buffer_number))
            jsr _lta_next_batch_row
        .else
            calculate_batch_row_func_calls .ident(.sprintf("_lta_calc_batch_first_column_buf%d", buffer_number)), \
                                           .ident(.sprintf("_lta_calc_batch_generic_buf%d", buffer_number)), \
                                           .ident(.sprintf("_lta_calc_batch_last_column_buf%d", buffer_number))
        .endif

        .if flush_buffer
            jsr _grid_draw__flush_ppu_copy_buffer
            jsr _grid_draw__switch_ppu_copy_buffer
        .endif
    .endif
.endmacro

.proc _lta_display_next_generation
    ; Select the bank we will be switching on MMC3
    lda #bank_reg::BANK_REG_8K_PRG_0
    sta MMC3_BANK_SELECT

    jsr _lta_init                  ; Init life grid row pointers

    .repeat 30, row_number
        calculate_batch_row_macro (row_number+1)
    .endrepeat

    jsr _grid_buffer_swap
    jsr _grid_draw__switch_nametable

    rts
.endproc
