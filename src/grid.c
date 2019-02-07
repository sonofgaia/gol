#include "ppu.h"
#include "grid.h"
#include "macros.h"
#include "nmi_task_list.h"

#define GRID_COLS          64
#define GRID_ROWS          60
#define CELL_COLS_PER_TILE  2
#define CELL_ROWS_PER_TILE  2
#define PADDING_COLS        2
#define PADDING_ROWS        2
#define BYTES_WIDTH         (GRID_COLS + PADDING_COLS)
#define BYTES_HEIGHT        (GRID_ROWS + PADDING_ROWS)

static uint8_t grid_buffer1[BYTES_HEIGHT][BYTES_WIDTH];
static uint8_t grid_buffer2[BYTES_HEIGHT][BYTES_WIDTH];

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
    current_grid[row][col] = cell_status;
}

void __fastcall__ grid_copy_to_nametable(nametable_t nametable)
{
    uint8_t row_count, col_count;
    uint8_t tile_code, task_index;
    nmi_task_t task;
    uint8_t ppu_write_buf1[GRID_COLS / CELL_COLS_PER_TILE];
    uint8_t ppu_write_buf2[GRID_COLS / CELL_COLS_PER_TILE];
    uint8_t *p_buf, *p_buf_copy;
    uint8_t cell_row = 0;
    life_grid_row_t *row1_ptr = current_grid;
    life_grid_row_t *row2_ptr = row1_ptr + 1;
    static nametable_t current_nametable = NAMETABLE_0;
    nmi_task_t task2;


    task.type = NMI_TASK_TYPE_PPU_DATA_COPY;
    task.params.ppu_data_copy.data_len = GRID_COLS / CELL_COLS_PER_TILE;

    task2.type = NMI_TASK_TYPE_CHANGE_NAMETABLE;

    p_buf = p_buf_copy = ppu_write_buf1;

    for (row_count = 0; row_count < GRID_ROWS; row_count += CELL_ROWS_PER_TILE) {

        for (col_count = 1; col_count <= GRID_COLS; col_count += CELL_COLS_PER_TILE) {
            tile_code = (
                    ((*row1_ptr)[col_count])
                    | ((*row1_ptr)[col_count + 1] << 1)
                    | ((*row2_ptr)[col_count] << 2)
                    | ((*row2_ptr)[col_count + 1] << 3)
            );

            *p_buf_copy = tile_code;
            p_buf_copy++;
        }

        task.params.ppu_data_copy.data = p_buf;
        if (current_nametable == NAMETABLE_0) {
            // Our current nametable is 0, so we write to nametable 2
            task.params.ppu_data_copy.dest_addr = (uint8_t*)0x2863 + cell_row * 32;
        } else {
            // Our current nametable is 2, so we write to nametable 0
            task.params.ppu_data_copy.dest_addr = (uint8_t*)0x2063 + cell_row * 32;
        }

        task_index = nmi_task_list_add_task(&task);
        if (task_index % 2 == 1) {
            // Wait on every 2nd task
            nmi_task_list_wait(task_index);
        }

        row1_ptr += CELL_ROWS_PER_TILE;
        row2_ptr = row1_ptr + 1;
        cell_row++;

        // Switch buffer
        if (p_buf == ppu_write_buf1) {
            p_buf = p_buf_copy = ppu_write_buf2;
        } else {
            p_buf = p_buf_copy = ppu_write_buf1;
        }
    }

    if (current_nametable == NAMETABLE_0) {
        current_nametable = NAMETABLE_2;
        task2.params.ppu_change_nametable.nametable = NAMETABLE_2;
    } else {
        current_nametable = NAMETABLE_0;
        task2.params.ppu_change_nametable.nametable = NAMETABLE_0;
    }

    task_index = nmi_task_list_add_task(&task2);
    nmi_task_list_wait(task_index);
}
