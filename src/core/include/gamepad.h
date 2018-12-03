#ifndef _GAMEPAD_H_
#define _GAMEPAD_H_

#include <stdint.h>

#define GAMEPAD_BTN_A      0x80
#define GAMEPAD_BTN_B      0x40
#define GAMEPAD_BTN_SELECT 0x20
#define GAMEPAD_BTN_START  0x10
#define GAMEPAD_BTN_UP     0x08
#define GAMEPAD_BTN_DOWN   0x04
#define GAMEPAD_BTN_LEFT   0x02
#define GAMEPAD_BTN_RIGHT  0x01

#define P1_BTN_A_PRESSED      (gamepad_p1_state & GAMEPAD_BTN_A)
#define P1_BTN_B_PRESSED      (gamepad_p1_state & GAMEPAD_BTN_B)
#define P1_BTN_SELECT_PRESSED (gamepad_p1_state & GAMEPAD_BTN_SELECT)
#define P1_BTN_START_PRESSED  (gamepad_p1_state & GAMEPAD_BTN_START)
#define P1_BTN_UP_PRESSED     (gamepad_p1_state & GAMEPAD_BTN_UP)
#define P1_BTN_DOWN_PRESSED   (gamepad_p1_state & GAMEPAD_BTN_DOWN)
#define P1_BTN_LEFT_PRESSED   (gamepad_p1_state & GAMEPAD_BTN_LEFT)
#define P1_BTN_RIGHT_PRESSED  (gamepad_p1_state & GAMEPAD_BTN_RIGHT)

#define P2_BTN_A_PRESSED      (gamepad_p2_state & GAMEPAD_BTN_A)
#define P2_BTN_B_PRESSED      (gamepad_p2_state & GAMEPAD_BTN_B)
#define P2_BTN_SELECT_PRESSED (gamepad_p2_state & GAMEPAD_BTN_SELECT)
#define P2_BTN_START_PRESSED  (gamepad_p2_state & GAMEPAD_BTN_START)
#define P2_BTN_UP_PRESSED     (gamepad_p2_state & GAMEPAD_BTN_UP)
#define P2_BTN_DOWN_PRESSED   (gamepad_p2_state & GAMEPAD_BTN_DOWN)
#define P2_BTN_LEFT_PRESSED   (gamepad_p2_state & GAMEPAD_BTN_LEFT)
#define P2_BTN_RIGHT_PRESSED  (gamepad_p2_state & GAMEPAD_BTN_RIGHT)

extern uint8_t gamepad_p1_state;
extern uint8_t gamepad_p2_state;

#pragma zpsym ("gamepad_p1_state");
#pragma zpsym ("gamepad_p2_state");

extern void __fastcall__ gamepad_save_inputs(void);

#endif
