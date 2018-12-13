; ONC (Optimized neighbor counter)
.import _current_grid

.segment "ZPVARS" : zeropage

; We make use of a 3x3 grid
_onc_grid_center:      .res 1
_onc_grid_left:        .res 1
_onc_grid_right:       .res 1
_onc_grid_up:          .res 1
_onc_grid_down:        .res 1
_onc_grid_upper_left:  .res 1
_onc_grid_upper_right: .res 1
_onc_grid_lower_left:  .res 1
_onc_grid_lower_right: .res 1

_onc_bitmask:          .res 1
_onc_row1_ptr:         .res 2
_onc_row2_ptr:         .res 2
_onc_row3_ptr:         .res 2
_onc_col1_ptr:         .res 2
_onc_col2_ptr:         .res 2
_onc_col3_ptr:         .res 2

.segment "CODE"

ONC_BYTES_PER_GRID_ROW = 8

.proc _onc_grid_init
    rts
.endproc

.proc _onc_next_row
    rts
.endproc

.proc _onc_next_col
    rts
.endproc
