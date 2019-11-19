.include "zeropage.inc"
.include "ports.inc"
.include "grid_draw.inc"
.include "lib.inc"

.import   popptr1
.import   popa
.exportzp _ppu_control_reg1
.exportzp _ppu_control_reg2
.exportzp _ppu_x_scroll_offset
.exportzp _ppu_y_scroll_offset
.exportzp _ppu_function_params
.export   _ppu_write_control_reg1
.export   _ppu_write_control_reg2
.export   _ppu_vblank_wait
.export   _ppu_set_rw_addr
.export   _ppu_write
.export   _ppu_write_byte
.export   _ppu_write_scroll_offsets
.export   _nmi_ppu_write
.export   _nmi_ppu_write_byte

.segment "ZPVARS" : zeropage

_ppu_control_reg1:    .res 1
_ppu_control_reg2:    .res 1  
_ppu_x_scroll_offset: .res 1
_ppu_y_scroll_offset: .res 1
_ppu_function_params: .res 2 ; Pass function params through this memory space.

.segment "CODE"

.proc _ppu_write_control_reg1
    write PPU_CTRL1, _ppu_control_reg1
    rts
.endproc

.proc _ppu_write_control_reg2
    write PPU_CTRL2, _ppu_control_reg2
    rts
.endproc

.proc _ppu_vblank_wait
@loop:
    bit PPU_STATUS ; Bit 7 of status register is set when in vblank state
    bpl @loop

    rts
.endproc

.proc _ppu_set_rw_addr
    bit PPU_STATUS

    stx PPU_MEMORY_ADDR
    sta PPU_MEMORY_ADDR

    rts
.endproc

;; This function makes use of the "C" runtime.  Should not be called from the NMI handler.
.proc _ppu_write
    tax                     ; X now contains number of bytes to write
    jsr popptr1             ; Pop 2 bytes from stack to ptr1

    ldy #0
@byte_count_loop:
    lda (ptr1), y
    sta PPU_MEMORY_RW
    iny
    dex
    bne @byte_count_loop

    rts
.endproc

;; This function makes use of the "C" runtime.  Should not be called from the NMI handler.
.proc _ppu_write_byte
    tax         ; X now contains number of bytes to write
    jsr popa    ; A now contains the byte to write

@byte_count_loop:
    sta PPU_MEMORY_RW
    dex
    bne @byte_count_loop

    rts
.endproc

;;
;; Routine : _nmi_ppu_write
;;-------------------------------------------
;; Writes a series of bytes to the PPU's address space.
;; This function is made to be used within the NMI handler.
;; Params
;;     Buffer ponter (passed through _ppu_function_params)
;;     Byte count    (passed through X register)
;;
.proc _nmi_ppu_write
    data_index = _ppu_function_params

    lda data_index

    cmp #1
    bne :+
        ; Use buffer 2    
        jmp nmi_ppu_write__read_from_buffer2
    :
    cmp #2
    bne :+
        ; Use buffer 3
        jmp nmi_ppu_write__read_from_buffer3
    :
    ; Use buffer 1

nmi_ppu_write__read_from_buffer1:
    .repeat 160, i
        lda _grid_draw__ppu_copy_buffer1+i
        sta PPU_MEMORY_RW
    .endrepeat
    rts
nmi_ppu_write__read_from_buffer2:
    .repeat 160, i
        lda _grid_draw__ppu_copy_buffer2+i
        sta PPU_MEMORY_RW
    .endrepeat
    rts
nmi_ppu_write__read_from_buffer3:
    .repeat 160, i
        lda _grid_draw__ppu_copy_buffer3+i
        sta PPU_MEMORY_RW
    .endrepeat
    rts
.endproc

;;
;; Routine : _nmi_ppu_write_byte
;;-------------------------------------------
;; Writes a single byte to the PPU's address space.
;; This function is made to be used within the NMI handler.
;; Params
;;     Byte to copy (passed through Accumulator)
;;     Repeat count (passed through X register)
;;
.proc _nmi_ppu_write_byte
@byte_count_loop:
    sta PPU_MEMORY_RW
    dex
    bne @byte_count_loop

    rts
.endproc

.proc _ppu_write_scroll_offsets
    bit PPU_STATUS

    write PPU_SCROLL_OFFSETS, _ppu_x_scroll_offset
    write PPU_SCROLL_OFFSETS, _ppu_y_scroll_offset

    rts
.endproc
