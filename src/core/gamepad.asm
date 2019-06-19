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

;; Saves the gamepad inputs to memory locations '_gamepad_p1_state' and '_gamepad_p2_state'.
.proc _gamepad__save_inputs
    lda _gamepad__p1_cur_state
    sta _gamepad__p1_prev_state
    lda _gamepad__p2_cur_state
    sta _gamepad__p2_prev_state     ; Save previously read values

    lda #$01
    sta GAMEPAD1
    lda #$00
    sta GAMEPAD1                    ; Reset the button latch

    ldx #NB_BUTTONS_PER_GAMEPAD
    @read_gamepad1_button:
        lda GAMEPAD1
        lsr                         ; Acc. Bit 0 -> Carry flag
        rol _gamepad__p1_cur_state  ; Carry flag -> _gamepad_p1_state
        dex
        bne @read_gamepad1_button

    ldx #NB_BUTTONS_PER_GAMEPAD
    @read_gamepad2_button:
        lda GAMEPAD2
        lsr                         ; Acc. Bit 0 -> Carry flag
        rol _gamepad__p2_cur_state  ; Carry flag -> _gamepad_p2_state
        dex
        bne @read_gamepad2_button

    rts
.endproc
