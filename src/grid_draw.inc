.ifndef _GRID_DRAW_

_GRID_DRAW_ = 1 ; Prevent multiple inclusions of this file

.globalzp _grid_draw__ppu_copy_buffer_ptr
.globalzp _grid_draw__ppu_copy_buffer_write_index
.global   _grid_draw__switch_ppu_copy_buffer
.globalzp _grid_draw__ppu_copy_buffers_in_use
.global   _grid_draw__switch_to_ppu_copy_buffer1

.endif
