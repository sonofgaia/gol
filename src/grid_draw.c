#include <stdint.h>
#include <stddef.h>
#include "nmi_task_list.h"
#include "ppu.h"

// PPU copy buffer can accomodate up to 3 lines of tiles.
#define PPU_COPY_BUFFER_SIZE_BYTES (PPU_SCREEN_NB_HORIZONTAL_TILES * 3)
#define PPU_COPY_BUFFER_FLUSH_BYTES 80

static uint8_t ppu_copy_buffer[PPU_COPY_BUFFER_SIZE_BYTES] = {}; // Initialize so that it is stored in the "DATA" segment.
static uint8_t ppu_copy_buffer_write_index = 0;
static uint8_t *ppu_write_addr = NULL;
static nametable_t ppu_write_nametable = NAMETABLE_2;

void __fastcall__ grid_draw__flush_ppu_copy_buffer(void);

void grid_draw__init(void)
{
    ppu_write_addr = (uint8_t*)ppu_nametable_addrs[ppu_write_nametable];
}

void __fastcall__ grid_draw__tile_write_callback(uint8_t tile)
{
    ppu_copy_buffer[ppu_copy_buffer_write_index++] = tile;

    if (ppu_copy_buffer_write_index == PPU_COPY_BUFFER_FLUSH_BYTES) {
        grid_draw__flush_ppu_copy_buffer();
    }
}

void __fastcall__ grid_draw__flush_ppu_copy_buffer(void)
{
    nmi_task_t task;
    uint8_t task_index;

    if (!ppu_copy_buffer_write_index) return; // Nothing to copy.

    task.type = NMI_TASK_TYPE_PPU_DATA_COPY; 
    
    task.params.ppu_data_copy.dest_addr = ppu_write_addr;
    task.params.ppu_data_copy.data      = ppu_copy_buffer;
    task.params.ppu_data_copy.data_len  = ppu_copy_buffer_write_index;

    task_index = nmi_task_list_add_task(&task);

    nmi_task_list_wait(task_index);

    ppu_write_addr += ppu_copy_buffer_write_index;
    ppu_copy_buffer_write_index = 0;
}

void grid_draw__switch_nametable(void)
{
    nmi_task_t task;

    task.type = NMI_TASK_TYPE_CHANGE_NAMETABLE;

    if (ppu_write_nametable == NAMETABLE_0) {
        ppu_write_nametable = NAMETABLE_2;
        task.params.ppu_change_nametable.nametable = NAMETABLE_0;
    } else {
        ppu_write_nametable = NAMETABLE_0;
        task.params.ppu_change_nametable.nametable = NAMETABLE_2;
    }

    nmi_task_list_add_task(&task);

    ppu_write_addr = (uint8_t*)ppu_nametable_addrs[ppu_write_nametable];
}
