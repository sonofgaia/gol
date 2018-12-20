.export   _gamepad_save_inputs
.exportzp _gamepad_p1_state, _gamepad_p2_state

;; Ports linked to gamepad usage
GAMEPAD1 = $4016
GAMEPAD2 = $4017

NB_BUTTONS_PER_GAMEPAD = 8

.segment "ZPVARS" : zeropage

;; Storage for player input
_gamepad_p1_state: .res 1
_gamepad_p2_state: .res 1

.segment "CODE"

;; Saves the gamepad inputs to memory locations '_gamepad_p1_state' and '_gamepad_p2_state'.
.proc _gamepad_save_inputs
    lda #$01
    sta GAMEPAD1
    lda #$00
    sta GAMEPAD1            ; Reset the button latch

    ldx #NB_BUTTONS_PER_GAMEPAD
@read_gamepad1_button:
    lda GAMEPAD1
    lsr                     ; Acc. Bit 0 -> Carry flag
    rol _gamepad_p1_state   ; Carry flag -> _gamepad_p1_state
    dex
    bne @read_gamepad1_button

    ldx #NB_BUTTONS_PER_GAMEPAD
@read_gamepad2_button:
    lda GAMEPAD2
    lsr                     ; Acc. Bit 0 -> Carry flag
    rol _gamepad_p2_state   ; Carry flag -> _gamepad_p2_state
    dex
    bne @read_gamepad2_button

    rts
.endproc
