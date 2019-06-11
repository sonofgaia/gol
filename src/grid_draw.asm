.include "grid_draw.inc"

.segment "ZPVARS" : zeropage

_grid_draw__ppu_copy_buffer_ptr:                .res 2
_grid_draw__ppu_copy_buffer_write_index:        .res 1
_grid_draw__switch_ppu_copy_buffer_func_ptr:    .res 2
_grid_draw__ppu_copy_buffers_in_use:            .res 1

.segment "DATA"

ppu_copy_buffer1: .res 120
ppu_copy_buffer2: .res 120
ppu_copy_buffer3: .res 120

.segment "CODE"

.proc _grid_draw__switch_ppu_copy_buffer
    jmp (_grid_draw__switch_ppu_copy_buffer_func_ptr)
.endproc

.macro set_ppu_copy_buffer_ptr_macro addr
    lda #<addr
    sta _grid_draw__ppu_copy_buffer_ptr
    lda #>addr
    sta _grid_draw__ppu_copy_buffer_ptr+1
.endmacro

.macro set_ppu_copy_buffer_switch_func_ptr_macro addr
    lda #<addr
    sta _grid_draw__switch_ppu_copy_buffer_func_ptr
    lda #>addr
    sta _grid_draw__switch_ppu_copy_buffer_func_ptr+1
.endmacro

.proc _grid_draw__switch_to_ppu_copy_buffer1
    set_ppu_copy_buffer_ptr_macro               ppu_copy_buffer1
    set_ppu_copy_buffer_switch_func_ptr_macro   _grid_draw__switch_to_ppu_copy_buffer2
    rts
.endproc

.proc _grid_draw__switch_to_ppu_copy_buffer2
    set_ppu_copy_buffer_ptr_macro               ppu_copy_buffer2
    set_ppu_copy_buffer_switch_func_ptr_macro   _grid_draw__switch_to_ppu_copy_buffer3
    rts
.endproc

.proc _grid_draw__switch_to_ppu_copy_buffer3
    set_ppu_copy_buffer_ptr_macro               ppu_copy_buffer3
    set_ppu_copy_buffer_switch_func_ptr_macro   _grid_draw__switch_to_ppu_copy_buffer1
    rts
.endproc
