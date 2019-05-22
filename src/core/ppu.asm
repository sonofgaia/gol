.include "zeropage.inc"
.include "ports.inc"

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
    lda _ppu_control_reg1
    sta PPU_CTRL1
    
    rts
.endproc

.proc _ppu_write_control_reg2
    lda _ppu_control_reg2
    sta PPU_CTRL2

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
    ptr = _ppu_function_params

    ldy #0
@byte_count_loop:
    lda (ptr), y
    sta PPU_MEMORY_RW
    iny
    dex
    bne @byte_count_loop

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

    lda _ppu_x_scroll_offset 
    sta PPU_SCROLL_OFFSETS
    lda _ppu_y_scroll_offset
    sta PPU_SCROLL_OFFSETS

    rts
.endproc
