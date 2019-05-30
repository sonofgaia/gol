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

@copy_128_bytes:
    ; Check if bytes to copy >= 128
    txa
    rol
    tax
    bcs :+
        jmp @copy_64_bytes  ; Check if we need to copy at least 64 bytes
    :

.repeat 128
    lda (ptr), y
    sta PPU_MEMORY_RW
    iny
.endrepeat

@copy_64_bytes:
    ; Check if bytes to copy >= 64
    txa
    rol
    tax
    bcs :+
        jmp @copy_32_bytes  ; Check if we need to copy at least 32 bytes
    :

.repeat 64
    lda (ptr), y
    sta PPU_MEMORY_RW
    iny
.endrepeat

@copy_32_bytes:
    ; Check if bytes to copy >= 32
    txa
    rol
    tax
    bcs :+
        jmp @copy_16_bytes  ; Check if we need to copy at least 16 bytes
    :

.repeat 32
    lda (ptr), y
    sta PPU_MEMORY_RW
    iny
.endrepeat

@copy_16_bytes:
    ; Check if bytes to copy >= 16
    txa
    rol
    tax
    bcc @copy_8_bytes  ; Check if we need to copy at least 16 bytes

.repeat 16
    lda (ptr), y
    sta PPU_MEMORY_RW
    iny
.endrepeat

@copy_8_bytes:
    ; Check if bytes to copy >= 8
    txa
    rol
    tax
    bcc @copy_4_bytes  ; Check if we need to copy at least 16 bytes

.repeat 8
    lda (ptr), y
    sta PPU_MEMORY_RW
    iny
.endrepeat

@copy_4_bytes:
    ; Check if bytes to copy >= 4
    txa
    rol
    tax
    bcc @copy_2_bytes  ; Check if we need to copy at least 16 bytes

.repeat 4
    lda (ptr), y
    sta PPU_MEMORY_RW
    iny
.endrepeat

@copy_2_bytes:
    ; Check if bytes to copy >= 2
    txa
    rol
    tax
    bcc @copy_1_bytes  ; Check if we need to copy at least 1 byte

.repeat 2
    lda (ptr), y
    sta PPU_MEMORY_RW
    iny
.endrepeat

@copy_1_bytes:
    ; Check if bytes to copy = 1
    txa
    rol
    tax
    bcc @end            ; Check if we need to copy at least 1 byte

    lda (ptr), y
    sta PPU_MEMORY_RW

@end:
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
