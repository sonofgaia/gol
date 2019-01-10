#ifndef _GRID_H_
#define _GRID_H_

#include <stdint.h>

typedef enum { CELL_FREE, CELL_OCCUPIED } cell_status_t;

void __fastcall__ grid_set_cell(uint8_t col, uint8_t row, cell_status_t cell_status);
void __fastcall__ grid_copy_to_nametable(nametable_t nametable);

#endif // _GRID_H_
