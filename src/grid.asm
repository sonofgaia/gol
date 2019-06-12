.export _grid_buffer1, _grid_buffer2
.export _grid__clear_buffer1, _grid__clear_buffer2

.segment "BSS"

_grid_buffer1: .res 4096
_grid_buffer2: .res 4096

.segment "CODE"

.proc _grid__clear_buffer1
    ldx #0
    lda #0
@loop:    
    .repeat 16, i
        sta _grid_buffer1 + (i * 256), x
    .endrepeat
    inx
    bne @loop 

    rts
.endproc

.proc _grid__clear_buffer2
    ldx #0
    lda #0
@loop:    
    .repeat 16, i
        sta _grid_buffer2 + (i * 256), x
    .endrepeat
    inx
    bne @loop 

    rts
.endproc
