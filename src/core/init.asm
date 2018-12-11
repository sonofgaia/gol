.include "nes2header.inc"
.include "zeropage.inc"
.include "ports.inc"

.import _main
.import _ppu_disable_sprites
.import _ppu_disable_screen
.import _ppu_disable_vblank
.import _ppu_vblank_wait
.import _oam_copy_to_ppu
.export _oam

; Startup code for cc65/ca65
.export __STARTUP__:absolute=1
.export _init, _exit
.export _init_set_nmi_handler
.export _nmi_handler

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
.addr _nmi_handler           ; Callback to handle NMI (non-maskable interrupt)
.addr _init          ; Callback to handle power on and reset (defined in "reset_handler.inc")
.word 0              ; IRQs not used at the moment

;; OAM
.segment "OAM"
_oam: .res 256

.segment "CHARS"
.incbin "chr/Alpha.chr"

.segment "STARTUP"

;; Run when powering on the console or resetting it.
.proc _init
    sei                     ; Disable IRQs
    cld                     ; Disable decimal mode

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
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x

    lda #$EF
    sta $0200, x            ; OAM is not initialized with #$00, that would create a bunch of garbage sprites at the top of the screen.

    inx
    bne @clear_memory
   
    jsr _ppu_vblank_wait    ; Second wait for vblank, PPU is ready after this

    jsr _ppu_disable_sprites
    jsr _ppu_disable_screen
    jsr _ppu_disable_vblank

	lda #<(__STACK_START__+__STACKSIZE__)
    sta	sp
    lda	#>(__STACK_START__+__STACKSIZE__)
    sta	sp+1                ; Set the c stack pointer
	
    jsr	copydata            ; Initialize DATA segment
    jsr	initlib             ; Run constructors

    jsr _main               ; Call main()
    jmp _exit               ; Exited from main(), force a software break
.endproc

.proc _exit
    jsr donelib             ; Run destructors
    brk
.endproc

.segment "BSS"

_nmi: .res 3 ; Will store the JMP instruction to our NMI handler.

.segment "CODE"

RTI_OPCODE = $40
JMP_OPCODE = $4C

; Set the NMI handler
; If an NMI occurs during this process, it will be ignored (RTI).
.proc _init_set_nmi_handler
    ldy #RTI_OPCODE
    sty _nmi
    sta _nmi+1      ; A contains low-byte of the addr
    stx _nmi+2      ; X contains the high-byte of the addr
    ldy #JMP_OPCODE
    sty _nmi

    rts
.endproc

.proc _nmi_handler
    SPRITE_0_Y_POS = _oam

    pha
    ;txa
    ;pha ; Save registers A and X

    inc SPRITE_0_Y_POS

    ; Test, move sprite #0 around a bit
    jsr _oam_copy_to_ppu

    pla
    ;tax
    ;pla ; Restore registers

    rti
.endproc
