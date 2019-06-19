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

#define P1_BTN_A_CUR_PRESSED      (gamepad__p1_cur_state & GAMEPAD_BTN_A)
#define P1_BTN_B_CUR_PRESSED      (gamepad__p1_cur_state & GAMEPAD_BTN_B)
#define P1_BTN_SELECT_CUR_PRESSED (gamepad__p1_cur_state & GAMEPAD_BTN_SELECT)
#define P1_BTN_START_CUR_PRESSED  (gamepad__p1_cur_state & GAMEPAD_BTN_START)
#define P1_BTN_UP_CUR_PRESSED     (gamepad__p1_cur_state & GAMEPAD_BTN_UP)
#define P1_BTN_DOWN_CUR_PRESSED   (gamepad__p1_cur_state & GAMEPAD_BTN_DOWN)
#define P1_BTN_LEFT_CUR_PRESSED   (gamepad__p1_cur_state & GAMEPAD_BTN_LEFT)
#define P1_BTN_RIGHT_CUR_PRESSED  (gamepad__p1_cur_state & GAMEPAD_BTN_RIGHT)

#define P1_BTN_A_PREV_PRESSED      (gamepad__p1_prev_state & GAMEPAD_BTN_A)
#define P1_BTN_B_PREV_PRESSED      (gamepad__p1_prev_state & GAMEPAD_BTN_B)
#define P1_BTN_SELECT_PREV_PRESSED (gamepad__p1_prev_state & GAMEPAD_BTN_SELECT)
#define P1_BTN_START_PREV_PRESSED  (gamepad__p1_prev_state & GAMEPAD_BTN_START)
#define P1_BTN_UP_PREV_PRESSED     (gamepad__p1_prev_state & GAMEPAD_BTN_UP)
#define P1_BTN_DOWN_PREV_PRESSED   (gamepad__p1_prev_state & GAMEPAD_BTN_DOWN)
#define P1_BTN_LEFT_PREV_PRESSED   (gamepad__p1_prev_state & GAMEPAD_BTN_LEFT)
#define P1_BTN_RIGHT_PREV_PRESSED  (gamepad__p1_prev_state & GAMEPAD_BTN_RIGHT)

#define P2_BTN_A_CUR_PRESSED      (gamepad__p2_cur_state & GAMEPAD_BTN_A)
#define P2_BTN_B_CUR_PRESSED      (gamepad__p2_cur_state & GAMEPAD_BTN_B)
#define P2_BTN_SELECT_CUR_PRESSED (gamepad__p2_cur_state & GAMEPAD_BTN_SELECT)
#define P2_BTN_START_CUR_PRESSED  (gamepad__p2_cur_state & GAMEPAD_BTN_START)
#define P2_BTN_UP_CUR_PRESSED     (gamepad__p2_cur_state & GAMEPAD_BTN_UP)
#define P2_BTN_DOWN_CUR_PRESSED   (gamepad__p2_cur_state & GAMEPAD_BTN_DOWN)
#define P2_BTN_LEFT_CUR_PRESSED   (gamepad__p2_cur_state & GAMEPAD_BTN_LEFT)
#define P2_BTN_RIGHT_CUR_PRESSED  (gamepad__p2_cur_state & GAMEPAD_BTN_RIGHT)

#define P2_BTN_A_PREV_PRESSED      (gamepad__p2_prev_state & GAMEPAD_BTN_A)
#define P2_BTN_B_PREV_PRESSED      (gamepad__p2_prev_state & GAMEPAD_BTN_B)
#define P2_BTN_SELECT_PREV_PRESSED (gamepad__p2_prev_state & GAMEPAD_BTN_SELECT)
#define P2_BTN_START_PREV_PRESSED  (gamepad__p2_prev_state & GAMEPAD_BTN_START)
#define P2_BTN_UP_PREV_PRESSED     (gamepad__p2_prev_state & GAMEPAD_BTN_UP)
#define P2_BTN_DOWN_PREV_PRESSED   (gamepad__p2_prev_state & GAMEPAD_BTN_DOWN)
#define P2_BTN_LEFT_PREV_PRESSED   (gamepad__p2_prev_state & GAMEPAD_BTN_LEFT)
#define P2_BTN_RIGHT_PREV_PRESSED  (gamepad__p2_prev_state & GAMEPAD_BTN_RIGHT)

extern uint8_t gamepad__p1_cur_state;
extern uint8_t gamepad__p2_cur_state;
extern uint8_t gamepad__p1_prev_state;
extern uint8_t gamepad__p2_prev_state;

#pragma zpsym ("gamepad__p1_cur_state");
#pragma zpsym ("gamepad__p2_cur_state");
#pragma zpsym ("gamepad__p1_prev_state");
#pragma zpsym ("gamepad__p2_prev_state");

extern void __fastcall__ gamepad__save_inputs(void);

#endif
