#ifndef _GRID_H_
#define _GRID_H_

#include <stdint.h>

#define GRID_COLS          64
#define GRID_ROWS          60

typedef enum { CELL_FREE, CELL_OCCUPIED } cell_status_t;

void __fastcall__ grid_set_cell(uint8_t col, uint8_t row, cell_status_t cell_status);
extern void __fastcall__ grid__clear_buffer1(void);
extern void __fastcall__ grid__clear_buffer2(void);

#endif // _GRID_H_
