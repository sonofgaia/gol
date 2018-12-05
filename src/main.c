#include "gamepad.h"
#include "ppu.h"

void main(void)
{
    char message[] = "Hello world";

    // Initialize screen
    background_palettes_t background_palettes = {
        {WHITE, LIGHT|YELLOW, LIGHT|RED, MEDIUM|RED}, // Palette 0
        {WHITE, LIGHT|YELLOW, LIGHT|RED, LIGHT|BLUE}, // Palette 1
        {WHITE, LIGHT|YELLOW, LIGHT|RED, LIGHT|BLUE}, // Palette 2
        {WHITE, LIGHT|YELLOW, LIGHT|RED, LIGHT|BLUE}  // Palette 3
    };

    ppu_set_background_palettes(&background_palettes);
    ppu_set_screen_pattern_table(PATTERN_TABLE_1);     // Letters are in the second pattern table.
    ppu_clear_nametable(NAMETABLE_0);

    // Write 'Hello World' in the middle of NAMETABLE_0
    ppu_set_rw_addr_by_nametable_coordinate(NAMETABLE_0, 14, 10);
    ppu_write((uint8_t*)message, sizeof(message));

    ppu_write_scroll_offsets();
    ppu_enable_screen();

    while (1);
}
