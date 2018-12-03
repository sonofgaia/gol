.include "ports.inc"

.import _main
.import _ppu_disable_sprites
.import _ppu_disable_screen
.import _ppu_disable_vblank
.import _ppu_vblank_wait
.export _reset_handler

.segment "STARTUP"

;; Run when powering on the console or resetting it.
.proc _reset_handler
    sei                     ; Disable IRQs
    cld                     ; Disable decimal mode

    jsr _ppu_disable_sprites
    jsr _ppu_disable_screen
    jsr _ppu_disable_vblank

    ldx #$40                ; Interrupt inhibit flag
    stx APU_FRAME_COUNTER   ; Disable APU frame IRQ
    ldx #$FF
    txs                     ; Set up stack
    inx                     ; Now X = 0

    stx APU_DMC_1           ; Disable DMC IRQs

    jsr _ppu_vblank_wait    ; First wait for vblank to make sure PPU is ready

@clear_memory:
    lda #$00
    sta $0000, x
    sta $0100, x
    sta $0200, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    lda #$FE
    sta $0300, x
    inx
    bne @clear_memory
   
    jsr _ppu_vblank_wait    ; Second wait for vblank, PPU is ready after this

    jmp _main
.endproc
