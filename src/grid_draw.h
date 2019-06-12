#ifndef _GRID_DRAW_H_
#define _GRID_DRAW_H_

extern uint8_t *grid_draw__ppu_copy_buffer_ptr;
#pragma zpsym ("grid_draw__ppu_copy_buffer_ptr");
extern uint8_t grid_draw__ppu_copy_buffer_write_index;
#pragma zpsym ("grid_draw__ppu_copy_buffer_write_index");
extern uint8_t grid_draw__ppu_copy_buffers_in_use;
#pragma zpsym ("grid_draw__ppu_copy_buffers_in_use");
extern uint8_t grid_draw__current_ppu_copy_buffer_index;
#pragma zpsym ("grid_draw__current_ppu_copy_buffer_index");

extern void grid_draw__init(void);
extern void grid_draw__switch_ppu_copy_buffer(void);

#endif
