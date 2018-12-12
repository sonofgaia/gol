.include "nes2header.inc"
.include "zeropage.inc"
.include "ports.inc"
.include "nmi_task_list.inc"
.include "lib.inc"

.import _main
.import _ppu_disable_sprites
.import _ppu_disable_screen
.import _ppu_disable_vblank
.import _ppu_vblank_wait
.import _oam_copy_to_ppu
.import _nmi_task_list
.import _nmi_task_list_worker_index
.import _nmi_task_list_load_current_task
.import _nmi_task_list_increment_worker_index
.import _nmi_ppu_write
.import _ppu_set_rw_addr
.import _ppu_write_scroll_offsets
.importzp _ppu_function_params

; Startup code for cc65/ca65
.export __STARTUP__:absolute=1
.export _init, _exit
.export _init_set_nmi_handler
.export _nmi_handler
.export _oam

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

.macro save_registers
    pha     ; Save 'A'
    txa
    pha     ; Save 'X'
    tya
    pha     ; Save 'Y'
.endmacro

.macro restore_registers
    pla
    tay     ; Restore 'Y'
    pla
    tax     ; Restore 'X'
    pla     ; Restore 'A'
.endmacro

.proc _nmi_handler
    SPRITE_0_Y_POS = _oam
    task_ptr = _ptr1

    save_registers

@run_tasks:
    jsr _nmi_task_list_load_current_task         ; Loads current task pointer into '_ptr1'.
    ldy #nmi_task::type
    lda (task_ptr), y                            ; Task 'type' -> A
    beq @tasks_done                              ; Branch to 'tasks_done' if task slot is empty.

    ; Set PPU R/W Addr
    ldy #nmi_task::dest_addr + 1
    lda (task_ptr), y                            
    tax                                          ; High byte 'dest_addr' -> X
    dey
    lda (task_ptr), y                            ; Low byte 'dest_addr' -> A
    jsr _ppu_set_rw_addr

    ; Call PPU write function
    ldy #nmi_task::data
    lda (task_ptr), y
    sta _ppu_function_params
    iny
    lda (task_ptr), y
    sta _ppu_function_params+1
    ldy #nmi_task::data_len
    lda (task_ptr), y
    tax
    jsr _nmi_ppu_write

    lda #0
    ldy #nmi_task::type
    sta (task_ptr), y                            ; Clear task slot. (Set task 'type' to '0')

    jsr _nmi_task_list_increment_worker_index    ; Go to next task.
    jmp @run_tasks

@tasks_done:

    inc SPRITE_0_Y_POS

    jsr _oam_copy_to_ppu
    jsr _ppu_write_scroll_offsets

@exit:
    restore_registers

    rti
.endproc
