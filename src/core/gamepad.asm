.include "lib.inc"

.export   _gamepad__save_inputs
.exportzp _gamepad__p1_cur_state, _gamepad__p2_cur_state
.exportzp _gamepad__p1_prev_state, _gamepad__p2_prev_state

;; Ports linked to gamepad usage
GAMEPAD1 = $4016
GAMEPAD2 = $4017

NB_BUTTONS_PER_GAMEPAD = 8

.segment "ZPVARS" : zeropage

;; Storage for player input
_gamepad__p1_cur_state:  .res 1
_gamepad__p2_cur_state:  .res 1
_gamepad__p1_prev_state: .res 1
_gamepad__p2_prev_state: .res 1

.segment "CODE"

.macro read_gamepad_state gamepad_port, state_store_addr
    .local read_gamepad_button

    ldx #NB_BUTTONS_PER_GAMEPAD
    read_gamepad_button:
        lda gamepad_port
        lsr                     ; Acc. Bit 0 -> Carry flag
        rol state_store_addr    ; Carry flag -> state_store_addr
        dex
        bne read_gamepad_button
.endmacro

;; Saves the gamepad inputs to memory locations '_gamepad__p1_cur_state' and '_gamepad__p2_cur_state'.
.proc _gamepad__save_inputs
    ; Save previously read values
    write _gamepad__p1_prev_state, _gamepad__p1_cur_state
    write _gamepad__p2_prev_state, _gamepad__p2_cur_state

    ; Reset the button latch
    write GAMEPAD1, #$01
    write GAMEPAD1, #$00

    read_gamepad_state GAMEPAD1, _gamepad__p1_cur_state
    read_gamepad_state GAMEPAD2, _gamepad__p2_cur_state

    rts
.endproc
