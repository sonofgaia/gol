#include "ppu.h"
#include "grid.h"
#include "macros.h"
#include "nmi_task_list.h"

#define CELL_COLS_PER_TILE  2
#define CELL_ROWS_PER_TILE  2
#define PADDING_COLS        2
#define PADDING_ROWS        2
#define BYTES_WIDTH         (GRID_COLS + PADDING_COLS)
#define BYTES_HEIGHT        (GRID_ROWS + PADDING_ROWS)

extern uint8_t grid_buffer1[BYTES_HEIGHT][BYTES_WIDTH];
extern uint8_t grid_buffer2[BYTES_HEIGHT][BYTES_WIDTH];

typedef uint8_t life_grid_row_t[BYTES_WIDTH];

life_grid_row_t *current_grid = grid_buffer1;
life_grid_row_t *work_grid    = grid_buffer2;

void __fastcall__ grid_buffer_swap(void)
{
    life_grid_row_t *ptr;

    ptr          = current_grid;
    current_grid = work_grid;
    work_grid    = ptr;
}

void __fastcall__ grid_set_cell(uint8_t col, uint8_t row, cell_status_t cell_status)
{
    current_grid[row+1][col+1] = cell_status;
}
