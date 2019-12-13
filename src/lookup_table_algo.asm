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

.feature c_comments
.linecont + ; Allow line continuation with '\'.

.segment "ZPVARS" : zeropage

lookup_table_ptr: .res 2
column_index:     .res 1

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
    ldax _current_grid
    stax _lta_row2_ptr

    decax #64
    stax _lta_row1_ptr             ; _lta_row1_ptr = _current_grid - 64
    decax
    stax _lta_first_row_ptr        ; This offset might seem odd for storing 'first row'.
                                   ; This is because when we calculate the last row and make use of this pointer,
                                   ; we are using a long Y offset.

    ldax _current_grid
    incax                          ; Value to increment by is already loaded in Y (64)
    stax _lta_row3_ptr             ; _lta_row3_ptr = _current_grid + 64
    incax                          ; Value to increment by is already loaded in Y (64)
    stax _lta_row4_ptr             ; _lta_row4_ptr = _current_grid + 128

    ldax _work_grid
    stax _lta_work_grid_row1_ptr   ; _lta_work_grid_row1_ptr = _work_grid
    incax                          ; Value to increment by is already loaded in Y (64)
    stax _lta_work_grid_row2_ptr   ; _lta_work_grid_row2_ptr = _work_grid + 64

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
;; Routine : _lta_increment_pointers
;;-------------------------------------------------------------------------------------------------
;; Increments the row pointers by 256 bytes.
;; Incremental steps of 128 bytes is done with the long Y offset.
;;-------------------------------------------------------------------------------------------------
.proc _lta_increment_pointers
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
    inc _grid_draw__ppu_copy_buffer_write_index

    .if ppu_buffer_index = 0
        sta _grid_draw__ppu_copy_buffer1, x
    .elseif ppu_buffer_index = 1
        sta _grid_draw__ppu_copy_buffer2, x
    .else
        sta _grid_draw__ppu_copy_buffer3, x
    .endif
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

.macro set_xreg_low_nibble_from_row_ptrs ptr1, ptr2, ptr3, ptr4
    .ifnblank ptr1
    lda (ptr1), y
    set_xreg_bits_if_zero_flag_off $08
    .endif

    .ifnblank ptr2
    lda (ptr2), y
    set_xreg_bits_if_zero_flag_off $04
    .endif

    .ifnblank ptr3
    lda (ptr3), y
    set_xreg_bits_if_zero_flag_off $02
    .endif
    
    .ifnblank ptr4
    lda (ptr4), y
    set_xreg_bits_if_zero_flag_off $01
    .endif
.endmacro

.macro set_xreg_high_nibble_from_row_ptrs ptr1, ptr2, ptr3, ptr4
    .ifnblank ptr1
    lda (ptr1), y
    set_xreg_bits_if_zero_flag_off $80
    .endif

    .ifnblank ptr2
    lda (ptr2), y
    set_xreg_bits_if_zero_flag_off $40
    .endif

    .ifnblank ptr3
    lda (ptr3), y
    set_xreg_bits_if_zero_flag_off $20
    .endif
    
    .ifnblank ptr4
    lda (ptr4), y
    set_xreg_bits_if_zero_flag_off $10
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
    sta (_lta_work_grid_row1_ptr), y ; Acc. already contains a non-zero value (#1)
    iny

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_02
    ; 0 0
    ; 1 0
    dey
    dey
    sta (_lta_work_grid_row2_ptr), y ; Acc. already contains a non-zero value (#2)
    iny

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_03
    ; 1 0
    ; 1 0
    dey
    dey
    sta (_lta_work_grid_row1_ptr), y ; Acc. already contains a non-zero value (#3)
    sta (_lta_work_grid_row2_ptr), y ; Acc. already contains a non-zero value (#3)
    iny

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_04
    ; 0 1
    ; 0 0
    dey
    sta (_lta_work_grid_row1_ptr), y ; Acc. already contains a non-zero value (#4)

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_05
    ; 1 1
    ; 0 0
    dey
    dey
    sta (_lta_work_grid_row1_ptr), y ; Acc. already contains a non-zero value (#5)
    iny
    sta (_lta_work_grid_row1_ptr), y ; Acc. already contains a non-zero value (#5)

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_06
    ; 0 1
    ; 1 0
    dey
    dey
    sta (_lta_work_grid_row2_ptr), y ; Acc. already contains a non-zero value (#6)
    iny
    sta (_lta_work_grid_row1_ptr), y ; Acc. already contains a non-zero value (#6)

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_07
    ; 1 1
    ; 1 0
    dey
    dey
    sta (_lta_work_grid_row1_ptr), y ; Acc. already contains a non-zero value (#7)
    sta (_lta_work_grid_row2_ptr), y ; Acc. already contains a non-zero value (#7)
    iny
    sta (_lta_work_grid_row1_ptr), y ; Acc. already contains a non-zero value (#7)

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_08
    ; 0 0
    ; 0 1
    dey
    sta (_lta_work_grid_row2_ptr), y ; Acc. already contains a non-zero value (#8)

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_09
    ; 1 0
    ; 0 1
    dey
    dey
    sta (_lta_work_grid_row1_ptr), y ; Acc. already contains a non-zero value (#9)
    iny
    sta (_lta_work_grid_row2_ptr), y ; Acc. already contains a non-zero value (#9)

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_10
    ; 0 0
    ; 1 1
    dey
    dey
    sta (_lta_work_grid_row2_ptr), y ; Acc. already contains a non-zero value (#10)
    iny
    sta (_lta_work_grid_row2_ptr), y ; Acc. already contains a non-zero value (#10)

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_11
    ; 1 0
    ; 1 1
    dey
    dey
    sta (_lta_work_grid_row1_ptr), y ; Acc. already contains a non-zero value (#11)
    sta (_lta_work_grid_row2_ptr), y ; Acc. already contains a non-zero value (#11)
    iny
    sta (_lta_work_grid_row2_ptr), y ; Acc. already contains a non-zero value (#11)

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_12
    ; 0 1
    ; 0 1
    dey
    sta (_lta_work_grid_row1_ptr), y ; Acc. already contains a non-zero value (#12)
    sta (_lta_work_grid_row2_ptr), y ; Acc. already contains a non-zero value (#12)

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_13
    ; 1 1
    ; 0 1
    dey
    dey
    sta (_lta_work_grid_row1_ptr), y ; Acc. already contains a non-zero value (#13)
    iny
    sta (_lta_work_grid_row1_ptr), y ; Acc. already contains a non-zero value (#13)
    sta (_lta_work_grid_row2_ptr), y ; Acc. already contains a non-zero value (#13)

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_14
    ; 0 1
    ; 1 1
    dey
    dey
    sta (_lta_work_grid_row2_ptr), y ; Acc. already contains a non-zero value (#14)
    iny
    sta (_lta_work_grid_row1_ptr), y ; Acc. already contains a non-zero value (#14)
    sta (_lta_work_grid_row2_ptr), y ; Acc. already contains a non-zero value (#14)

    rts
.endproc
.align 16
.proc _lta_store_lookup_table_result_15
    ; 1 1
    ; 1 1
    dey
    dey
    sta (_lta_work_grid_row1_ptr), y ; Acc. already contains a non-zero value (#15)
    sta (_lta_work_grid_row2_ptr), y ; Acc. already contains a non-zero value (#15)
    iny
    sta (_lta_work_grid_row1_ptr), y ; Acc. already contains a non-zero value (#15)
    sta (_lta_work_grid_row2_ptr), y ; Acc. already contains a non-zero value (#15)

    rts
.endproc

.segment "LTA_CODE1"

.proc _lta_calc_batch_upper_left_corner
    ; Get lookup table bank number
    ldx #0
    ldy #63 
    set_xreg_low_nibble_from_row_ptrs /*skip*/, _lta_last_row_ptr, _lta_row2_ptr, _lta_row3_ptr
    stx MMC3_BANK_DATA

    ; Get value of lookup_table_ptr (high byte)
    ldx #$80 ; Lookup table chunk is swapped in at 0x8000.
    set_xreg_high_nibble_from_row_ptrs /*skip*/, /*skip*/, /*skip*/, _lta_row4_ptr
    ldy #0 ; Next column
    set_xreg_low_nibble_from_row_ptrs _lta_last_row_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_row4_ptr
    stx lookup_table_ptr+1

    iny

    ; Get value of lookup_table_ptr (low byte) based on bits in two last columns of this batch.
    ldx #0
    set_xreg_high_nibble_from_row_ptrs _lta_last_row_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_row4_ptr
    iny
    set_xreg_low_nibble_from_row_ptrs  _lta_last_row_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_row4_ptr
    stx lookup_table_ptr

    load_lookup_results_and_store_to_grid 0
.endproc

.proc _lta_calc_batch_upper_right_corner
    optimized_read_of_lookup_table_ptr_hi

    ldx #0                                  ; New value for lookup_table_ptr is generated in 'X'.

    set_xreg_high_nibble_from_row_ptrs _lta_last_row_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_row4_ptr

    sty column_index ; TODO : Figure out exact Y-value here so we can load it later instead of storing then loading it.
    ldy #0

    set_xreg_low_nibble_from_row_ptrs  _lta_last_row_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_row4_ptr

    stx lookup_table_ptr
    ldy column_index
    iny

    load_lookup_results_and_store_to_grid 0
.endproc

.proc _lta_calc_batch_first_row
    optimized_read_of_lookup_table_ptr_hi

    ; Get value of lookup_table_ptr (low byte) based on bits in two last columns of this batch.
    ldx #0
    set_xreg_high_nibble_from_row_ptrs _lta_last_row_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_row4_ptr
    iny
    set_xreg_low_nibble_from_row_ptrs  _lta_last_row_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_row4_ptr
    stx lookup_table_ptr

    load_lookup_results_and_store_to_grid 0
.endproc

.proc _lta_calc_batch_lower_left_corner
    ; Get lookup table bank number
    ldx #0
    ldy #191
    set_xreg_low_nibble_from_row_ptrs /*skip*/, _lta_row1_ptr, _lta_row2_ptr, _lta_row3_ptr
    stx MMC3_BANK_DATA

    ; Get lookup table pointer
    ldx #$80 ; Lookup table chunk is swapped in at 0x8000.
    set_xreg_high_nibble_from_row_ptrs /*skip*/, /*skip*/, /*skip*/, _lta_first_row_ptr
    ldy #128
    set_xreg_low_nibble_from_row_ptrs  _lta_row1_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_first_row_ptr
    stx lookup_table_ptr+1

    iny

    ; Get value of lookup_table_ptr (low byte) based on bits in two last columns of this batch.
    ldx #0
    set_xreg_high_nibble_from_row_ptrs _lta_row1_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_first_row_ptr
    iny
    set_xreg_low_nibble_from_row_ptrs  _lta_row1_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_first_row_ptr
    stx lookup_table_ptr

    load_lookup_results_and_store_to_grid 2
.endproc

.proc _lta_calc_batch_lower_right_corner
    optimized_read_of_lookup_table_ptr_hi

    ldx #0
    set_xreg_high_nibble_from_row_ptrs _lta_row1_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_first_row_ptr
    sty column_index    ; TODO : Figure out exact y-value so that we don't have to store then load.
    ldy #128
    set_xreg_low_nibble_from_row_ptrs  _lta_row1_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_first_row_ptr
    stx lookup_table_ptr

    ldy column_index
    iny

    load_lookup_results_and_store_to_grid 2
.endproc

.proc _lta_calc_batch_last_row
    optimized_read_of_lookup_table_ptr_hi

    ; Get value of lookup_table_ptr (low byte) based on bits in two last columns of this batch.
    ldx #0
    set_xreg_high_nibble_from_row_ptrs _lta_row1_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_first_row_ptr
    iny
    set_xreg_low_nibble_from_row_ptrs  _lta_row1_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_first_row_ptr
    stx lookup_table_ptr

    load_lookup_results_and_store_to_grid 2
.endproc

.macro _lta_calc_batch_first_column_macro ppu_buffer_index, use_long_y_offset
    ; Get lookup table bank number
    ldx #0
    .if use_long_y_offset
        ldy #191
    .else
        ldy #63
    .endif
    set_xreg_low_nibble_from_row_ptrs /*skip*/, _lta_row1_ptr, _lta_row2_ptr, _lta_row3_ptr
    stx MMC3_BANK_DATA

    ; Get lookup table pointer
    ldx #$80 ; Lookup table chunk is swapped in at 0x8000.
    set_xreg_high_nibble_from_row_ptrs /*skip*/, /*skip*/, /*skip*/, _lta_row4_ptr
    .if use_long_y_offset
        ldy #128 ; Next column
    .else
        ldy #0 ; Next column
    .endif
    set_xreg_low_nibble_from_row_ptrs  _lta_row1_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_row4_ptr
    stx lookup_table_ptr+1

    iny

    ; Get value of lookup_table_ptr (low byte) based on bits in two last columns of this batch.
    ldx #0
    set_xreg_high_nibble_from_row_ptrs _lta_row1_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_row4_ptr
    iny
    set_xreg_low_nibble_from_row_ptrs  _lta_row1_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_row4_ptr
    stx lookup_table_ptr

    load_lookup_results_and_store_to_grid ppu_buffer_index
.endmacro

.proc _lta_calc_batch_first_column_buf1
    _lta_calc_batch_first_column_macro 0, FALSE
.endproc

.proc _lta_calc_batch_first_column_buf2
    _lta_calc_batch_first_column_macro 1, FALSE
.endproc

.proc _lta_calc_batch_first_column_buf3
    _lta_calc_batch_first_column_macro 2, FALSE
.endproc

.proc _lta_calc_batch_first_column_buf1_long_y_offset
    _lta_calc_batch_first_column_macro 0, TRUE
.endproc

.proc _lta_calc_batch_first_column_buf2_long_y_offset
    _lta_calc_batch_first_column_macro 1, TRUE
.endproc

.proc _lta_calc_batch_first_column_buf3_long_y_offset
    _lta_calc_batch_first_column_macro 2, TRUE
.endproc

.macro _lta_calc_batch_last_column_macro ppu_buffer_index, use_long_y_offset
    optimized_read_of_lookup_table_ptr_hi

    ldx #0
    set_xreg_high_nibble_from_row_ptrs _lta_row1_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_row4_ptr

    sty column_index    ; TODO : Figure out exact offset

    .if use_long_y_offset
        ldy #128
    .else
        ldy #0
    .endif
    set_xreg_low_nibble_from_row_ptrs _lta_row1_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_row4_ptr

    stx lookup_table_ptr
    ldy column_index
    iny

    load_lookup_results_and_store_to_grid ppu_buffer_index
.endmacro

.proc _lta_calc_batch_last_column_buf1
    _lta_calc_batch_last_column_macro 0, FALSE
.endproc

.proc _lta_calc_batch_last_column_buf2
    _lta_calc_batch_last_column_macro 1, FALSE
.endproc

.proc _lta_calc_batch_last_column_buf3
    _lta_calc_batch_last_column_macro 2, FALSE
.endproc

.proc _lta_calc_batch_last_column_buf1_long_y_offset
    _lta_calc_batch_last_column_macro 0, TRUE
.endproc

.proc _lta_calc_batch_last_column_buf2_long_y_offset
    _lta_calc_batch_last_column_macro 1, TRUE
.endproc

.proc _lta_calc_batch_last_column_buf3_long_y_offset
    _lta_calc_batch_last_column_macro 2, TRUE
.endproc

.macro _lta_calc_batch_generic_macro ppu_buffer_index
    optimized_read_of_lookup_table_ptr_hi

    ; Get value of lookup_table_ptr (low byte) based on bits in two last columns of this batch.
    ldx #0
    set_xreg_high_nibble_from_row_ptrs _lta_row1_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_row4_ptr
    iny
    set_xreg_low_nibble_from_row_ptrs  _lta_row1_ptr, _lta_row2_ptr, _lta_row3_ptr, _lta_row4_ptr
    stx lookup_table_ptr

    load_lookup_results_and_store_to_grid ppu_buffer_index
.endmacro

.proc _lta_calc_batch_generic_buf1
    _lta_calc_batch_generic_macro 0
.endproc

.proc _lta_calc_batch_generic_buf2
    _lta_calc_batch_generic_macro 1
.endproc

.proc _lta_calc_batch_generic_buf3
    _lta_calc_batch_generic_macro 2
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
                                           .ident(.sprintf("_lta_calc_batch_generic_buf%d", buffer_number)), \
                                           .ident(.sprintf("_lta_calc_batch_last_column_buf%d_long_y_offset", buffer_number))
            jsr _lta_increment_pointers
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
    write MMC3_BANK_SELECT, #bank_reg::BANK_REG_8K_PRG_0

    jsr _lta_init                  ; Init life grid row pointers

    .repeat 30, row_number
        calculate_batch_row_macro (row_number+1)
    .endrepeat

    jsr _grid_buffer_swap
    jmp _grid_draw__switch_nametable
.endproc
