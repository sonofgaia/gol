#include <string.h>
#include "nmi_task_list.h"

extern uint8_t nmi_task_list_worker_index;
extern uint8_t nmi_task_list_manager_index;

extern nmi_task_t nmi_task_list[TASK_LIST_LENGTH];

#pragma zpsym ("nmi_task_list");
#pragma zpsym ("nmi_task_list_worker_index");
#pragma zpsym ("nmi_task_list_manager_index");

uint8_t __fastcall__ nmi_task_list_add_task(nmi_task_t *task)
{
    uint8_t task_index = nmi_task_list_manager_index;
    nmi_task_t *task_ptr = nmi_task_list + nmi_task_list_manager_index;

    // If task slot is still occupied, wait until NMI handler processes it.
    nmi_task_list_wait(task_ptr);

    // Set task type and params (finish with 'type' - this is the field the NMI handler checks to see if a task was submitted.)
    memcpy(&task_ptr->params, &task->params, sizeof(nmi_task_params_t));
    task_ptr->type = task->type;

    nmi_task_list_manager_index = (nmi_task_list_manager_index + 1) % TASK_LIST_LENGTH;

    return task_index;
}

// Waits for a given task to complete.
void __fastcall__ nmi_task_list_wait(nmi_task_t *task)
{
    while (task->type != NMI_TASK_TYPE_NONE);
}
