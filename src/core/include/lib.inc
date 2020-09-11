.ifndef _LIB_

_LIB_ = 1 ; Prevent multiple inclusions of this file

.define FALSE 0
.define TRUE  1

; Variables used in NMI handler.
.globalzp _tmp1, _tmp2, _tmp3, _tmp4
.globalzp _ptr1, _ptr2, _ptr3, _ptr4

; Variables used outside the NMI handler.
.globalzp gol_tmp1, gol_tmp2, gol_tmp3, gol_tmp4
.globalzp gol_ptr1, gol_ptr2, gol_ptr3, gol_ptr4

; Space to save registers in user space and NMI.
.globalzp regs

.global identify_table
.global lsr5_lookup_table
.global and1f_or80_lookup_table

.macro txy
    ldy identity_table, x
.endmacro

.macro tyx
    ldx identity_table, y
.endmacro

.macro save_registers_user
    sta regs
    stx regs+1
    sty regs+2
.endmacro

.macro restore_registers_user
    lda regs
    ldx regs+1
    ldy regs+2
.endmacro

.macro save_registers_nmi
    sta regs+3
    stx regs+4
    sty regs+5
.endmacro

.macro restore_registers_nmi
    lda regs+3
    ldx regs+4
    ldy regs+5
.endmacro

.macro mov store_addr, load_addr_or_value
    lda load_addr_or_value
    sta store_addr
.endmacro

; Loads a value (immediate or address) into AX.
.macro ldax arg
    .if (.match (.left (1, {arg}), #))
        ; immediate mode
        .if (.xmatch (#<.right (.tcount ({arg})-1, {arg}), #>.right (.tcount ({arg})-1, {arg})))
            ; small memory optimization if low-byte and high-byte are the same
            lda #<(.right (.tcount ({arg})-1, {arg}))
            tax
        .else
            lda #<(.right (.tcount ({arg})-1, {arg}))
            ldx #>(.right (.tcount ({arg})-1, {arg}))
        .endif
    .else
        ; assume absolute or zero page
        lda arg
        ldx 1+(arg)
    .endif
.endmacro

; Writes the value in AX to memory.
.macro stax addr
    sta addr
    stx 1+(addr)
.endmacro

.macro decax val
    .ifnblank val
    ldy val
    .endif
    jsr decaxy
.endmacro

.macro incax val
    .ifnblank val
    ldy val
    .endif
    jsr incaxy
.endmacro

.endif
