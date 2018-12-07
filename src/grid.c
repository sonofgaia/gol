#include "grid.h"
#include "macros.h"

// TV overscan 'title safe' area is 224x192 pixels.
// That gives us an area of 28x24 tiles.
// Each individual tile is used to display a 2x2 block of cells.
// This gives us an effective cell grid of 56x48.
#define GRID_COLS 56
#define GRID_ROWS 48
#define PADDING_COLS 3 // 2 bits on the left side, 1 bit on the right
#define PADDING_ROWS 2 // 2 entirely unused rows (one at the top and one at the bottom)
#define BITS_IN_BYTE 8

#define GRID_ARR_BYTES_RESERVED_FOR_ROW (ceil_div(GRID_COLS + PADDING_COLS, BITS_IN_BYTE))
#define GRID_BUFFER_SIZE_BYTES (GRID_ARR_BYTES_RESERVED_FOR_ROW * (GRID_ROWS + PADDING_ROWS))

static uint8_t grid_buffer1[GRID_BUFFER_SIZE_BYTES];
static uint8_t grid_buffer2[GRID_BUFFER_SIZE_BYTES];

static uint8_t *current_grid = grid_buffer1;
static uint8_t *work_grid    = grid_buffer2;

void __fastcall__ grid_buffer_swap(void)
{
    uint8_t *ptr;

    ptr          = current_grid;
    current_grid = work_grid;
    work_grid    = ptr;
}

void __fastcall__ grid_set_cell(uint8_t col, uint8_t row, cell_status_t cell_status)
{
    uint8_t *ptr = current_grid + GRID_ARR_BYTES_RESERVED_FOR_ROW; // We skip the array's first row (padding)
    uint8_t skip_row_bytes, bit_to_read, arr_column;
    uint8_t bitmask = 0x80;

    arr_column = col + 2; // First two columns of the array are skipped (padding)

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

uint8_t __fastcall__ grid_count_cell_neighbors(uint8_t *ptr, uint8_t bitmask)
{
    uint8_t *ptr_copy;
    uint8_t bitmask_copy;
    uint8_t neighbor_count = 0;

    ptr_copy = ptr;
    bitmask_copy = bitmask;

    // Check cells above and below
    if (*(ptr - GRID_ARR_BYTES_RESERVED_FOR_ROW) & bitmask) {
        neighbor_count++; // Top cell is occupied
    }
    if (*(ptr + GRID_ARR_BYTES_RESERVED_FOR_ROW) & bitmask) {
        neighbor_count++; // Bottom cell is occupied
    }

    // Check cells on left side
    bitmask = bitmask << 1;

    if (!bitmask) {
        bitmask = 0x01;
        ptr--;
    }

    if (*(ptr - GRID_ARR_BYTES_RESERVED_FOR_ROW) & bitmask) {
        neighbor_count++; // Upper-left cell is occupied
    }
    if (*ptr & bitmask) {
        neighbor_count++; // Left cell is occupied
    }
    if (*(ptr + GRID_ARR_BYTES_RESERVED_FOR_ROW) & bitmask) {
        neighbor_count++; // Lower-left cell is occupied
    }

    // Check cells on the right side
    ptr = ptr_copy;
    bitmask = bitmask_copy;
    bitmask = bitmask >> 1;

    if (!bitmask) {
        bitmask = 0x80;
        ptr++;
    }

    if (*(ptr - GRID_ARR_BYTES_RESERVED_FOR_ROW) & bitmask) {
        neighbor_count++; // Upper-right cell is occupied
    }
    if (*ptr & bitmask) {
        neighbor_count++; // Right cell is occupied
    }
    if (*(ptr + GRID_ARR_BYTES_RESERVED_FOR_ROW) & bitmask) {
        neighbor_count++; // Lower-right cell is occupied
    }

    return neighbor_count;
}

void __fastcall__ grid_apply_rules(void)
{
    uint8_t row_count, col_count;
    uint8_t bitmask, cell_is_occupied, neighbor_count;
    uint8_t *row_ptr, *col_ptr, *work_grid_ptr;

    row_ptr = current_grid + GRID_ARR_BYTES_RESERVED_FOR_ROW; // We skip the array's first row (padding)

    for (row_count = 0; row_count < GRID_ROWS; row_count++) {
        // Bitmask targets the third bit from the left since the two first columns of the row are skipped (padding).
        bitmask = 0x20;
        col_ptr = row_ptr;

        for (col_count = 0; col_count < GRID_COLS; col_count++) {
            cell_is_occupied = *col_ptr & bitmask;
            neighbor_count = grid_count_cell_neighbors(col_ptr, bitmask);    

            // Get a pointer to the same cell position in the work grid.
            work_grid_ptr = work_grid + (col_ptr - current_grid);

            // Apply the 3 basic rules of "Game Of Life"
            if (cell_is_occupied) {
                if (neighbor_count < 2 || neighbor_count > 3) {
                    *work_grid_ptr &= ~bitmask;
                } else {
                    *work_grid_ptr |= bitmask;
                }
            } else {
                if (neighbor_count == 3) {
                    *work_grid_ptr |= bitmask;
                } else {
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

        row_ptr += GRID_ARR_BYTES_RESERVED_FOR_ROW;
    }

    grid_buffer_swap(); // Work buffer now becomes our current grid.
}

#ifdef _DEBUG_
void grid_display_on_stdout(char occupied_char, char free_char)
{
    uint8_t row_count, col_count;
    uint8_t bitmask, cell_is_occupied;
    uint8_t *row_ptr, *col_ptr;

    row_ptr = current_grid + GRID_ARR_BYTES_RESERVED_FOR_ROW; // We skip the array's first row (padding)

    for (row_count = 0; row_count < GRID_ROWS; row_count++) {
        // Bitmask targets the third bit from the left since the two first columns of the row are skipped (padding).
        bitmask = 0x20;
        col_ptr = row_ptr;

        for (col_count = 0; col_count < GRID_COLS; col_count++) {
            cell_is_occupied = *col_ptr & bitmask;

            // Apply the 3 basic rules of "Game Of Life"
            if (cell_is_occupied) {
                printf("%c", occupied_char);
            } else {
                printf("%c", free_char);
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
}
#endif
