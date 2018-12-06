#include "grid.h"
#include <stdio.h>

#define ceil_div(x, y) (x + y - 1) / y

// TV overscan 'title safe' area is 224x192 pixels.
// That gives us an area of 28x24 tiles.
// Each individual tile is used to display a 2x2 block of cells.
// This gives us an effective cell grid of 56x48.
//#define GRID_COLS 56
//#define GRID_ROWS 48
#define GRID_COLS 10 
#define GRID_ROWS 10
#define PADDING_COLS 2
#define PADDING_ROWS 2
#define BITS_IN_BYTE 8

#define GRID_ARR_BYTES_RESERVED_FOR_ROW (ceil_div(GRID_COLS + PADDING_COLS, BITS_IN_BYTE))
#define GRID_BUFFER_SIZE_BYTES (GRID_ARR_BYTES_RESERVED_FOR_ROW * (GRID_ROWS + PADDING_ROWS))

static uint8_t grid_buffer1[GRID_BUFFER_SIZE_BYTES];
static uint8_t grid_buffer2[GRID_BUFFER_SIZE_BYTES];

static uint8_t *current_grid = grid_buffer1;
static uint8_t *work_grid    = grid_buffer2;

uint8_t grid_count_cell_neighbors(uint8_t *ptr, uint8_t bitmask);

void /*__fastcall__*/ grid_buffer_swap(void)
{
    uint8_t *ptr;

    ptr          = current_grid;
    current_grid = work_grid;
    work_grid    = ptr;
}

void /*__fastcall__*/ grid_set_cell(uint8_t col, uint8_t row, cell_status_t cell_status)
{
    uint8_t *ptr = current_grid + GRID_ARR_BYTES_RESERVED_FOR_ROW; // We skip the array's first row (padding)
    uint8_t skip_row_bytes;
    uint8_t bit_to_read;
    uint8_t bitmask = 0x80;
    uint8_t arr_column;

    arr_column = col + 1; // First column of the array is skipped (padding)

    // Point to requested row
    ptr += row * (uint8_t)GRID_ARR_BYTES_RESERVED_FOR_ROW;

    skip_row_bytes = arr_column / BITS_IN_BYTE;
    bit_to_read    = arr_column % BITS_IN_BYTE;
    bitmask        = bitmask >> bit_to_read;

    ptr += skip_row_bytes;

    if (CELL_OCCUPIED == cell_status) {
        *ptr |= bitmask;
    } else {
        *ptr &= ~bitmask;
    }
}

void /*__fastcall__*/ grid_work(void)
{
    uint8_t row_count, col_count;
    uint8_t bitmask, living_cell, neighbor_count;
    uint8_t *row_ptr = current_grid + GRID_ARR_BYTES_RESERVED_FOR_ROW; // We skip the array's first row (padding)
    uint8_t *col_ptr;
    uint8_t *work_grid_ptr;

    // Traverse 'current_grid' and populate 'work_grid' with it.
    for (row_count = 0; row_count < GRID_ROWS; row_count++) {
        col_ptr = row_ptr;
        bitmask = 0x40; // First column of row is skipped (padding)

        for (col_count = 0; col_count < GRID_COLS; col_count++) {
            living_cell = *col_ptr & bitmask;
            neighbor_count = grid_count_cell_neighbors(col_ptr, bitmask);    

            if (living_cell) {
                printf("1");
            } else {
                printf(" ");
            }

            // Get equivalent position pointer in work grid.
            work_grid_ptr = work_grid + (col_ptr - current_grid);

            if (living_cell) {
                // There is a cell here
                if (neighbor_count < 2 || neighbor_count > 3) {
                    // Cell dies of overpopulation/underpopulation
                    *work_grid_ptr &= ~bitmask;
                } else {
                    // Cell remains alive
                    *work_grid_ptr |= bitmask;
                }
            } else {
                // Empty space
                if (neighbor_count == 3) {
                    // Create new cell here
                    *work_grid_ptr |= bitmask;
                } else {
                    // Space remains empty
                    *work_grid_ptr &= ~bitmask;
                }
            }
            
            bitmask = bitmask >> 1;

            if (!bitmask) {
                // Move on to next byte.
                bitmask = 0x80;
                col_ptr++;
            }
        }
        printf("\n");

        row_ptr += GRID_ARR_BYTES_RESERVED_FOR_ROW;
    }
    printf("\n");

    grid_buffer_swap(); // Work buffer now becomes our current grid.
}

uint8_t grid_count_cell_neighbors(uint8_t *ptr, uint8_t bitmask)
{
    uint8_t *ptr_copy;
    uint8_t neighbor_count = 0;
    uint8_t bitmask_copy;

    ptr_copy = ptr;
    bitmask_copy = bitmask;

    // Check cells above and below
    if (*(ptr - GRID_ARR_BYTES_RESERVED_FOR_ROW) & bitmask) {
        neighbor_count++;
    }
    if (*(ptr + GRID_ARR_BYTES_RESERVED_FOR_ROW) & bitmask) {
        neighbor_count++;
    }

    // Check cells on left side
    bitmask = bitmask << 1;

    if (!bitmask) {
        bitmask = 0x01;
        ptr--;
    }

    // Upper-left corner
    if (*(ptr - GRID_ARR_BYTES_RESERVED_FOR_ROW) & bitmask) {
        neighbor_count++;
    }
    // Left
    if (*ptr & bitmask) {
        neighbor_count++;
    }
    // Lower-left corner
    if (*(ptr + GRID_ARR_BYTES_RESERVED_FOR_ROW) & bitmask) {
        neighbor_count++;
    }

    ptr = ptr_copy;
    bitmask = bitmask_copy;

    // Check cells on the right side
    bitmask = bitmask >> 1;

    if (!bitmask) {
        bitmask = 0x80;
        ptr++;
    }

    // Upper-right corner
    if (*(ptr - GRID_ARR_BYTES_RESERVED_FOR_ROW) & bitmask) {
        neighbor_count++;
    }
    // Right
    if (*ptr & bitmask) {
        neighbor_count++;
    }
    // Lower-right corner
    if (*(ptr + GRID_ARR_BYTES_RESERVED_FOR_ROW) & bitmask) {
        neighbor_count++;
    }

    return neighbor_count;
}
