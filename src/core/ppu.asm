.exportzp _ppu_control_reg1
.exportzp _ppu_control_reg2
.exportzp _ppu_x_scroll_offset
.exportzp _ppu_y_scroll_offset
.export   _ppu_write_control_reg1
.export   _ppu_write_control_reg2
.export   _ppu_vblank_wait

;; Ports linked to PPU usage
CTRL_1_REG = $2000
CTRL_2_REG = $2001
STATUS_REG = $2002

.segment "ZEROPAGE" : zeropage

_ppu_control_reg1:    .res 1
_ppu_control_reg2:    .res 1  
_ppu_x_scroll_offset: .res 1
_ppu_y_scroll_offset: .res 1

.segment "CODE"

.proc _ppu_write_control_reg1
    lda _ppu_control_reg1
    sta CTRL_1_REG
    rts
.endproc

.proc _ppu_write_control_reg2
    lda _ppu_control_reg2
    sta CTRL_2_REG
    rts
.endproc

.proc _ppu_vblank_wait
@loop:
    bit STATUS_REG ; Bit 7 of status register is set when in vblank state
    bpl @loop

    rts
.endproc
