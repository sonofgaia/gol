.include "zeropage.inc"

.export _oam_copy_to_ppu

;; CPU addresses linked to PPU usage
PPU_SPRITE_ADDR = $2003
PPU_SPRITE_DMA  = $4014

;.segment "ZEROPAGE" : zeropage

;_ppu_control_reg1:    .res 1

.segment "CODE"

.proc _oam_copy_to_ppu
    lda #$00
    sta PPU_SPRITE_ADDR
    lda #2
    sta PPU_SPRITE_DMA

    rts
.endproc
