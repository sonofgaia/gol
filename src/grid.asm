.export _grid_buffer1, _grid_buffer2
.export _grid__clear_buffer1, _grid__clear_buffer2

.segment "BSS"

_grid_buffer1: .res 4096
_grid_buffer2: .res 4096

.segment "CODE"

.macro clear_buffer buffer
    ldx #0
    lda #0
@loop:    
    .repeat 16, i
        sta buffer + (i * 256), x
    .endrepeat
    inx
    bne @loop 

    rts
.endmacro

.proc _grid__clear_buffer1
    clear_buffer _grid_buffer1
.endproc

.proc _grid__clear_buffer2
    clear_buffer _grid_buffer2
.endproc
