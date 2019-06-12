NMI_TASK_TYPE_NONE          = 0
NMI_TASK_TYPE_PPU_DATA_COPY = 1

.struct nmi_task_ppu_data_copy_params
    dest_addr  .word
    deprecated .byte
    data_index .byte
    data_len   .byte
.endstruct

.union nmi_task_params_u
    ppu_data_copy .tag nmi_task_ppu_data_copy_params
.endunion

.struct nmi_task
    type   .byte
    .union
        .struct
            nametable .byte
        .endstruct
        .struct 
            dest_addr .word
            deprecated .byte
            data_index .byte
            data_len  .byte
        .endstruct
    .endunion
.endstruct
