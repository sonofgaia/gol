#include "gamepad.h"

void main(void)
{
    int i;

    if (P1_BTN_A_PRESSED) {
        i = 2;
    } else if (P1_BTN_START_PRESSED) {
        i = 5;
    }
}
