.include "nmi_task_list.inc"
.include "lib.inc"

.exportzp _nmi_task_list
.exportzp _nmi_task_list_worker_index
.exportzp _nmi_task_list_manager_index
.export   _nmi_task_list_load_current_task
.export   _nmi_task_list_increment_worker_index

TASK_LIST_LENGTH = 10

.segment "ZPVARS" : zeropage

_nmi_task_list_worker_index:  .res 1
_nmi_task_list_manager_index: .res 1

_nmi_task_list: 
.repeat TASK_LIST_LENGTH
    .tag nmi_task
.endrepeat

.segment "CODE"

.proc _nmi_task_list_increment_worker_index
    lda _nmi_task_list_worker_index
    clc
    adc #1
    cmp #TASK_LIST_LENGTH
    bne :+
    lda #0                  ; Index was = TASK_LIST_LENGTH, reset to 0.
:
    sta _nmi_task_list_worker_index
    rts
.endproc

;;
;; Routine : _nmi_task_list_load_current_task
;;-------------------------------------------
;; Loads the addr of the current task slot into '_ptr1'.
;;
.proc _nmi_task_list_load_current_task
    ; Get the number of offset bytes from _nmi_task_task to our current task.
    ; Task data type size is currently 6 bytes.
    lda _nmi_task_list_worker_index   
    asl
    sta _tmp1                       ; _tmp1 = 'nmi_task_list_worker_index' * 2
    asl                             ; A = '_nmi_task_list_worker_index' * 4
    clc
    adc _tmp1                       
    sta _tmp1                       ; _tmp1 = '_nmi_task_list_worker_index' * 6 

    ; Save '_nmi_task_list' + offset bytes to '_ptr1'.
    lda #>_nmi_task_list
    sta _ptr1+1                     ; Store high byte of '_ptr1'.
    lda #<_nmi_task_list
    adc _tmp1
    sta _ptr1                       ; Store low byte of '_ptr1'.
    bcc @exit
    inc _ptr1+1                     ; Increment high byte of '_ptr1' if needed.

@exit:
    rts
.endproc
