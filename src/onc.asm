; ONC (optimized neighbor counter)
.import _current_grid
.import _work_grid
.import _grid_buffer_swap
.export _onc_apply_rules

; C runtime imports
.import incaxy

.segment "ZPVARS" : zeropage

; We make use of a 3x3 grid
_onc_cell_center:         .res 1
_onc_cell_left:           .res 1
_onc_cell_right:          .res 1
_onc_cell_top:            .res 1
_onc_cell_bottom:         .res 1
_onc_cell_upper_left:     .res 1
_onc_cell_upper_right:    .res 1
_onc_cell_lower_left:     .res 1
_onc_cell_lower_right:    .res 1

_onc_bitmask1:            .res 1
_onc_bitmask2:            .res 1
_onc_row1_ptr:            .res 2
_onc_row2_ptr:            .res 2
_onc_row3_ptr:            .res 2
_onc_col1_ptr:            .res 2
_onc_col2_ptr:            .res 2
_onc_col3_ptr:            .res 2
_onc_work_grid_ptr:       .res 2
_onc_ptr_offset:          .res 2

_onc_center_ptr:          .res 2
_onc_center_bitmask:      .res 1
_onc_next_center_ptr:     .res 2
_onc_next_center_bitmask: .res 1

_onc_row_counter:         .res 1
_onc_col_counter:         .res 1

.segment "CODE"

ONC_BYTES_PER_GRID_ROW = 8

.proc _onc_init
    ; Set bitmask
    lda #$40 ; Leftmost column of array is padding
    sta _onc_bitmask1

    ; Init row and col pointers
    ldx _current_grid+1
    stx _onc_row1_ptr+1
    lda _current_grid   ; A/X now contains a copy of _current_grid pointer
    sta _onc_row1_ptr   ; row1 pointer is now equal to _current_grid

    stx _onc_col1_ptr+1
    sta _onc_col1_ptr   ; col1 pointer is a copy of row1 pointer.

    ldy #8              ; Next row has an 8 byte offset
    jsr incaxy          ; Increment A/X pointer by 8 bytes
    stx _onc_row2_ptr+1
    sta _onc_row2_ptr   ; row2 pointer is now equal to _current_grid + 8 bytes (1 row)

    stx _onc_col2_ptr+1
    sta _onc_col2_ptr   ; col2 pointer is a copy of row2 pointer.

    jsr incaxy          ; Increment A/X pointer by another 8 bytes
    stx _onc_row3_ptr+1
    sta _onc_row3_ptr   ; row3 pointer is now equal to _current_grid + 16 bytes (2 rows)

    stx _onc_col3_ptr+1
    sta _onc_col3_ptr   ; col3 pointer is a copy of row3 pointer.

    ; Load values for first column
    ldy #0
    lda (_onc_col1_ptr), y
    bit _onc_bitmask1
    beq :+
        lda #1  ; Cell is occupied
        bne :++
    :
        lda #0  ; Cell is unoccupied
    :
    sta _onc_cell_upper_left

    lda (_onc_col2_ptr), y
    bit _onc_bitmask1
    beq :+
        lda #1  ; Cell is occupied
        bne :++
    :
        lda #0  ; Cell is unoccupied
    :
    sta _onc_cell_left

    lda (_onc_col3_ptr), y
    bit _onc_bitmask1
    beq :+
        lda #1  ; Cell is occupied
        bne :++
    :
        lda #0  ; Cell is unoccupied
    :
    sta _onc_cell_lower_left

    jsr _onc_shift_bitmask

    ; Load values for second column
    lda (_onc_col1_ptr), y
    bit _onc_bitmask1
    beq :+
        lda #1  ; Cell is occupied
        bne :++
    :
        lda #0  ; Cell is unoccupied
    :
    sta _onc_cell_top

    lda (_onc_col2_ptr), y
    bit _onc_bitmask1
    beq :+
        lda #1  ; Cell is occupied
        bne :++
    :
        lda #0  ; Cell is unoccupied
    :
    sta _onc_cell_center

    lda (_onc_col3_ptr), y
    bit _onc_bitmask1
    beq :+
        lda #1  ; Cell is occupied
        bne :++
    :
        lda #0  ; Cell is unoccupied
    :
    sta _onc_cell_bottom

    ; Save center ptr and bitmask
    lda _onc_bitmask1
    sta _onc_center_bitmask
    lda _onc_col2_ptr
    sta _onc_center_ptr
    lda _onc_col2_ptr+1
    sta _onc_center_ptr+1

    jsr _onc_shift_bitmask

    rts
.endproc

.proc _onc_shift_bitmask
    lsr _onc_bitmask1
    bcc @exit
    ; Bitmask has reached the next byte, increment col pointers and reset bitmask
    inc _onc_col1_ptr
    bne :+
        inc _onc_col1_ptr+1
    :
    inc _onc_col2_ptr
    bne :+
        inc _onc_col2_ptr+1
    :
    inc _onc_col3_ptr
    bne :+
        inc _onc_col3_ptr+1
    :
    lda #$80
    sta _onc_bitmask1
@exit:
    rts
.endproc

.proc _onc_load_new_cells
    ldy #0

    ; Load values for third column
    lda (_onc_col1_ptr), y
    bit _onc_bitmask1
    beq :+
        lda #1  ; Cell is occupied
        bne :++
    :
        lda #0  ; Cell is unoccupied
    :
    sta _onc_cell_upper_right

    lda (_onc_col2_ptr), y
    bit _onc_bitmask1
    beq :+
        lda #1  ; Cell is occupied
        bne :++
    :
        lda #0  ; Cell is unoccupied
    :
    sta _onc_cell_right

    lda (_onc_col3_ptr), y
    bit _onc_bitmask1
    beq :+
        lda #1  ; Cell is occupied
        bne :++
    :
        lda #0  ; Cell is unoccupied
    :
    sta _onc_cell_lower_right

    ; Save next center ptr and bitmask
    lda _onc_bitmask1
    sta _onc_next_center_bitmask
    lda _onc_col2_ptr
    sta _onc_next_center_ptr
    lda _onc_col2_ptr+1
    sta _onc_next_center_ptr+1

    jsr _onc_shift_bitmask

    rts
.endproc

.proc _onc_get_neighbor_count
    lda #0
    clc
    adc _onc_cell_upper_left
    adc _onc_cell_left
    adc _onc_cell_lower_left
    adc _onc_cell_top
    adc _onc_cell_bottom
    adc _onc_cell_upper_right
    adc _onc_cell_right
    adc _onc_cell_lower_right
   
    rts
.endproc

.proc _onc_next_row
    ; Set bitmask
    lda #$40            ; Leftmost column of array is padding
    sta _onc_bitmask1

    lda _onc_row2_ptr
    sta _onc_row1_ptr
    sta _onc_col1_ptr
    lda _onc_row2_ptr+1
    sta _onc_row1_ptr+1
    sta _onc_col1_ptr+1 ; row1 and col1 pointer values are set to the previous value of row2 pointer

    lda _onc_row3_ptr
    sta _onc_row2_ptr
    sta _onc_col2_ptr
    ldx _onc_row3_ptr+1
    stx _onc_row2_ptr+1 ; A/X now contains a copy of _onc_row2_ptr
    stx _onc_col2_ptr+1 ; row2 and col2 pointer values are set to the previous value of row3 pointer

    ldy #8
    jsr incaxy          ; Increment A/X pointer by 8 bytes
    stx _onc_row3_ptr+1
    sta _onc_row3_ptr
    stx _onc_col3_ptr+1
    sta _onc_col3_ptr   ; Set new values for row3 and col3 pointers

    ; Load values for first column
    ldy #0
    lda (_onc_col1_ptr), y
    bit _onc_bitmask1
    beq :+
        lda #1  ; Cell is occupied
        bne :++
    :
        lda #0  ; Cell is unoccupied
    :
    sta _onc_cell_upper_left

    lda (_onc_col2_ptr), y
    bit _onc_bitmask1
    beq :+
        lda #1  ; Cell is occupied
        bne :++
    :
        lda #0  ; Cell is unoccupied
    :
    sta _onc_cell_left

    lda (_onc_col3_ptr), y
    bit _onc_bitmask1
    beq :+
        lda #1  ; Cell is occupied
        bne :++
    :
        lda #0  ; Cell is unoccupied
    :
    sta _onc_cell_lower_left

    jsr _onc_shift_bitmask

    ; Load values for second column
    lda (_onc_col1_ptr), y
    bit _onc_bitmask1
    beq :+
        lda #1  ; Cell is occupied
        bne :++
    :
        lda #0  ; Cell is unoccupied
    :
    sta _onc_cell_top

    lda (_onc_col2_ptr), y
    bit _onc_bitmask1
    beq :+
        lda #1  ; Cell is occupied
        bne :++
    :
        lda #0  ; Cell is unoccupied
    :
    sta _onc_cell_center

    lda (_onc_col3_ptr), y
    bit _onc_bitmask1
    beq :+
        lda #1  ; Cell is occupied
        bne :++
    :
        lda #0  ; Cell is unoccupied
    :
    sta _onc_cell_bottom

    ; Save center ptr and bitmask
    lda _onc_bitmask1
    sta _onc_center_bitmask
    lda _onc_col2_ptr
    sta _onc_center_ptr
    lda _onc_col2_ptr+1
    sta _onc_center_ptr+1
    jsr _onc_shift_bitmask

    rts
.endproc

.proc _onc_next_col
    ; Shift cell window to the right
    lda _onc_cell_top
    sta _onc_cell_upper_left
    lda _onc_cell_center
    sta _onc_cell_left
    lda _onc_cell_bottom
    sta _onc_cell_lower_left
    lda _onc_cell_upper_right
    sta _onc_cell_top
    lda _onc_cell_right
    sta _onc_cell_center
    lda _onc_cell_lower_right
    sta _onc_cell_bottom

    ; Set current center cell ptr and bitmask
    lda _onc_next_center_bitmask
    sta _onc_center_bitmask
    lda _onc_next_center_ptr
    sta _onc_center_ptr
    lda _onc_next_center_ptr+1
    sta _onc_center_ptr+1

    rts
.endproc

.proc _onc_update_work_grid_cell
    tay ; Y now contains the number of neighbors

    ; Calculate the offset from _current_grid to the current center cell's byte.
    lda _onc_center_ptr
    sec
    sbc _current_grid
    sta _onc_ptr_offset
    lda _onc_center_ptr+1
    sbc _current_grid+1
    sta _onc_ptr_offset+1

    ; Add offset to _work_grid addr to obtain the addr we need to update.
    lda _work_grid
    clc
    adc _onc_ptr_offset
    sta _onc_work_grid_ptr
    lda _work_grid+1
    adc _onc_ptr_offset+1
    sta _onc_work_grid_ptr+1

    lda _onc_cell_center
    beq @center_cell_is_unoccupied
    @center_cell_is_occupied:
        ; Center cell is currently occupied
        cpy #2
        beq @cell_survives
        cpy #3
        beq @cell_survives
        @cell_dies:
            ; Cell dies (over or under population)
            lda _onc_center_bitmask
            eor #$FF
            sta _onc_bitmask2
            ldy #0
            lda (_onc_work_grid_ptr), y
            and _onc_bitmask2
            sta (_onc_work_grid_ptr), y
            rts
        @cell_survives:        
            ; Cell survives (2 or 3 neighbors)
            ldy #0
            lda (_onc_work_grid_ptr), y
            ora _onc_center_bitmask
            sta (_onc_work_grid_ptr), y
            rts
    @center_cell_is_unoccupied:
        ; Center cell is currently free
        cpy #3
        bne @stays_unoccupied
        @new_cell_is_born:
            ; New cell is created
            ldy #0
            lda (_onc_work_grid_ptr), y
            ora _onc_center_bitmask
            sta (_onc_work_grid_ptr), y
            rts
        @stays_unoccupied:
            ; Cell remains unoccupied
            lda _onc_center_bitmask
            eor #$FF
            sta _onc_bitmask2
            ldy #0
            lda (_onc_work_grid_ptr), y
            and _onc_bitmask2
            sta (_onc_work_grid_ptr), y
            rts
    rts ; Just in case, should not be run
.endproc

.proc _onc_apply_rules
    jsr _onc_init

    lda #48                 ; Num rows
    sta _onc_row_counter
@row_loop:
    ; Row loop code
    lda #55                 ; Num cols-1
    sta _onc_col_counter 

    @col_loop:
        ; Column loop code
        jsr _onc_load_new_cells
        jsr _onc_get_neighbor_count     ; 'A' now contains the neighbor count
        jsr _onc_update_work_grid_cell
        jsr _onc_next_col
        
        dec _onc_col_counter
        bne @col_loop

    ; For last column of the row
    jsr _onc_load_new_cells
    jsr _onc_get_neighbor_count
    jsr _onc_update_work_grid_cell
    jsr _onc_next_row

    dec _onc_row_counter
    bne @row_loop

    jsr _grid_buffer_swap

    rts
.endproc
