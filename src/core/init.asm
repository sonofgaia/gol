.include "nes2header.inc"
.include "zeropage.inc"
.include "ports.inc"

.import _main
.import _ppu_disable_sprites
.import _ppu_disable_screen
.import _ppu_disable_vblank
.import _ppu_vblank_wait

; Startup code for cc65/ca65
.export __STARTUP__:absolute=1
.export _init, _exit

; Linker generated symbols
.import __STACK_START__, __STACKSIZE__
.import initlib, donelib, copydata

;; iNES 2.0 header
nes2mapper  0       ; NROM, no bank swapping
nes2prg     32768
nes2chr     8192
nes2mirror  'H'
nes2tv      'N'
nes2end

;; Vectors
.segment "VECTORS"
.word _nmi           ; Callback to handle NMI (non-maskable interrupt)
.word _init          ; Callback to handle power on and reset (defined in "reset_handler.inc")
.word 0              ; IRQs not used at the moment

.segment "CHARS"
.incbin "chr/Alpha.chr"

.segment "STARTUP"

;; Run when powering on the console or resetting it.
.proc _init
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

	lda #<(__STACK_START__+__STACKSIZE__)
    sta	sp
    lda	#>(__STACK_START__+__STACKSIZE__)
    sta	sp+1                ; Set the c stack pointer
	
    ;jsr	copydata            ; Initialize DATA segment
    jsr	initlib             ; Run constructors

    jsr _main               ; Call main()
    jmp _exit               ; Exited from main(), force a software break
.endproc

.proc _exit
    jsr donelib             ; Run destructors
    brk
.endproc

.proc _nmi
    rti
.endproc
