#include "scenarios.h"

void scenarios__load(uint8_t *scenario)
{
    uint8_t row, col;
    uint8_t *p = scenario;
    int8_t bit_index = 7;
    cell_status_t cell_status;

    for (row = 0; row < GRID_ROWS; row++) {
        for (col = 0; col < GRID_COLS; col++) {
            cell_status = (*p >> bit_index--) & 0x1; 

            if (bit_index < 0) {
                bit_index = 7;
                p++;
            }

            grid_set_cell(col, row, cell_status);
        }
    }
}
