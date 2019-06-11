#ifndef _GRID_DRAW_H_
#define _GRID_DRAW_H_

extern uint8_t *grid_draw__ppu_copy_buffer_ptr;
#pragma zpsym ("grid_draw__ppu_copy_buffer_ptr");
extern uint8_t grid_draw__ppu_copy_buffer_write_index;
#pragma zpsym ("grid_draw__ppu_copy_buffer_write_index");

extern void grid_draw__init(void);
extern void grid_draw__switch_ppu_copy_buffer(void);

#endif
