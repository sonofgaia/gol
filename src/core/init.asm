.include "nes2header.inc"
.include "zeropage.inc"
.include "ports.inc"
.include "nmi_task_list.inc"
.include "grid_draw.inc"
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
.import _ppu_write_control_reg1
.import _mmc3__enable_prg_ram
.import _mmc3__clear_ram
.import _gamepad__save_inputs
.import _handle_gamepad_input
.importzp _ppu_control_reg1
.importzp _ppu_function_params

; Startup code for cc65/ca65
.export __STARTUP__:absolute=1
.export _init, _exit
.export _nmi_handler
.export _oam

; Linker generated symbols
.import __STACK_START__, __STACKSIZE__
.import initlib, donelib, copydata

;; iNES 2.0 header
nes2mapper  4       ; MMC3
nes2prg     131072
nes2chr     8192
nes2wram    8192
nes2mirror  'H'
nes2tv      'N'
nes2end

;; Vectors
.segment "VECTORS"
.addr _nmi_handler   ; Callback to handle NMI (non-maskable interrupt)
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
    sei                         ; Disable IRQs
    cld                         ; Disable decimal mode

    ldx #$40                    ; Interrupt inhibit flag
    stx APU_FRAME_COUNTER       ; Disable APU frame IRQ
    ldx #$FF
    txs                         ; Set up stack
    inx                         ; Now X = 0

    stx APU_DMC_1               ; Disable DMC IRQs

    jsr _ppu_vblank_wait        ; First wait for vblank to make sure PPU is ready

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
    sta $0200, x                ; OAM is not initialized with #$00, that would create a bunch of garbage sprites at the top of the screen.

    inx
    bne @clear_memory
   
    jsr _ppu_vblank_wait        ; Second wait for vblank, PPU is ready after this

    jsr _mmc3__enable_prg_ram   ; Enable the MMC3's onboard RAM (8K, $6000-$7FFF)
    jsr _mmc3__clear_ram

    jsr _ppu_disable_sprites
    jsr _ppu_disable_screen
    jsr _ppu_disable_vblank

    lda #<(__STACK_START__+__STACKSIZE__)
    sta	sp
    lda	#>(__STACK_START__+__STACKSIZE__)
    sta	sp+1                    ; Set the c stack pointer
	
    jsr	copydata                ; Initialize DATA segment
    jsr	initlib                 ; Run constructors

    jsr _main                   ; Call main()
    jmp _exit                   ; Exited from main(), force a software break
.endproc

.proc _exit
    jsr donelib             ; Run destructors
    brk
.endproc

.segment "CODE"

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

    cmp #2 ; Nametable change
    beq @change_nametable

@ppu_copy:
    ; Set PPU R/W Addr
    ldy #nmi_task::dest_addr + 1
    lda (task_ptr), y                            
    tax                                          ; High byte 'dest_addr' -> X
    dey
    lda (task_ptr), y                            ; Low byte 'dest_addr' -> A
    jsr _ppu_set_rw_addr

    ; Call PPU write function
    ldy #nmi_task::data_index
    lda (task_ptr), y
    sta _ppu_function_params
    ;iny
    ;lda (task_ptr), y
    ;sta _ppu_function_params+1
    ldy #nmi_task::data_len
    lda (task_ptr), y
    tax
    jsr _nmi_ppu_write

    lda #0
    ldy #nmi_task::type
    sta (task_ptr), y                            ; Clear task slot. (Set task 'type' to '0')

    jsr _ppu_write_control_reg1

    jsr _nmi_task_list_increment_worker_index    ; Go to next task.
    dec _grid_draw__ppu_copy_buffers_in_use
    jmp @tasks_done

@change_nametable:
    lda _ppu_control_reg1
    and #$FC ; Clear first two bits
    sta _ppu_control_reg1
    ldy #nmi_task::nametable
    lda (task_ptr), y
    ora _ppu_control_reg1
    sta _ppu_control_reg1

    lda #0
    ldy #nmi_task::type
    sta (task_ptr), y                            ; Clear task slot. (Set task 'type' to '0')

    jsr _nmi_task_list_increment_worker_index    ; Go to next task.
    jmp @run_tasks

@tasks_done:
    jsr _oam_copy_to_ppu
    jsr _ppu_write_scroll_offsets

@exit:
    jsr _gamepad__save_inputs ; Read gamepads on every NMI
    jsr _handle_gamepad_input

    restore_registers

    rti
.endproc
