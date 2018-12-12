#ifndef _NMI_TASK_LIST_H_
#define _NMI_TASK_LIST_H_

#include <stdint.h>

#define TASK_LIST_LENGTH 10

#define NMI_TASK_TYPE_NONE          0
#define NMI_TASK_TYPE_PPU_DATA_COPY 1

typedef struct {
    uint8_t *dest_addr;
    uint8_t *data;
    uint8_t data_len;
} nmi_task_ppu_data_copy_params_t;

typedef union {
    nmi_task_ppu_data_copy_params_t ppu_data_copy;
} nmi_task_params_t;

typedef struct {
    uint8_t type;
    nmi_task_params_t params;
} nmi_task_t;

uint8_t __fastcall__ nmi_task_list_add_task(nmi_task_t *task);
void __fastcall__ nmi_task_list_wait(nmi_task_t *task);

#endif
