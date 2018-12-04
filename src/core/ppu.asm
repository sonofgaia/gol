.include "zeropage.inc"

.import   popptr1
.exportzp _ppu_control_reg1
.exportzp _ppu_control_reg2
.exportzp _ppu_x_scroll_offset
.exportzp _ppu_y_scroll_offset
.export   _ppu_write_control_reg1
.export   _ppu_write_control_reg2
.export   _ppu_vblank_wait
.export   _ppu_set_rw_addr
.export   _ppu_write
.export   _ppu_write_scroll_offsets

;; CPU addresses linked to PPU usage
PPU_CTRL1          = $2000
PPU_CTRL2          = $2001
PPU_STATUS         = $2002
PPU_SCROLL_OFFSETS = $2005
PPU_MEMORY_ADDR    = $2006
PPU_MEMORY_RW      = $2007

.segment "ZEROPAGE" : zeropage

_ppu_control_reg1:    .res 1
_ppu_control_reg2:    .res 1  
_ppu_x_scroll_offset: .res 1
_ppu_y_scroll_offset: .res 1

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

.proc _ppu_write_scroll_offsets
    bit PPU_STATUS

    ;lda _ppu_x_scroll_offset 
    lda #0
    sta PPU_SCROLL_OFFSETS
    ;lda _ppu_y_scroll_offset
    sta PPU_SCROLL_OFFSETS

    rts
.endproc
