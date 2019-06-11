#include <stdint.h>
#include <stddef.h>
#include "grid_draw.h"
#include "nmi_task_list.h"
#include "ppu.h"

static uint8_t *ppu_write_addr = NULL;
static nametable_t ppu_write_nametable = NAMETABLE_2;

extern void grid_draw__switch_to_ppu_copy_buffer1(void);

void __fastcall__ grid_draw__flush_ppu_copy_buffer(void);

void grid_draw__init(void)
{
    ppu_write_addr = (uint8_t*)ppu_nametable_addrs[ppu_write_nametable];
    grid_draw__switch_to_ppu_copy_buffer1();
}

void __fastcall__ grid_draw__flush_ppu_copy_buffer(void)
{
    nmi_task_t task;
    uint8_t task_index;

    if (!grid_draw__ppu_copy_buffer_write_index) return; // Nothing to copy.

    task.type = NMI_TASK_TYPE_PPU_DATA_COPY; 
    
    task.params.ppu_data_copy.dest_addr = ppu_write_addr;
    task.params.ppu_data_copy.data      = grid_draw__ppu_copy_buffer_ptr;
    task.params.ppu_data_copy.data_len  = grid_draw__ppu_copy_buffer_write_index;

    ++grid_draw__ppu_copy_buffers_in_use;
    task_index = nmi_task_list_add_task(&task);

    while (grid_draw__ppu_copy_buffers_in_use == 3); // Wait until there is at least one buffer free.

    //nmi_task_list_wait(task_index);

    ppu_write_addr += grid_draw__ppu_copy_buffer_write_index;
    grid_draw__ppu_copy_buffer_write_index = 0;
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
