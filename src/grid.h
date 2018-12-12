#ifndef _GRID_H_
#define _GRID_H_

#include <stdint.h>

#ifdef _DEBUG_
  // We are compiling on a GNU/Linux host
  #include <stdio.h>
  #define __fastcall__
#endif

typedef enum { CELL_FREE, CELL_OCCUPIED } cell_status_t;

void __fastcall__ grid_set_cell(uint8_t col, uint8_t row, cell_status_t cell_status);
void __fastcall__ grid_apply_rules(void);
void __fastcall__ grid_copy_to_nametable(nametable_t nametable);

#ifdef _DEBUG_
void grid_display_on_stdout(char occupied_char, char free_char);
#endif
#endif // _GRID_H_
