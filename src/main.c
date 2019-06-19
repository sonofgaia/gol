#include <string.h>
#include <stdbool.h>
#include "init.h"
#include "gamepad.h"
#include "ppu.h"
#include "mmc3.h"
#include "oam.h"
#include "grid.h"
#include "grid_draw.h"
#include "lookup_table_algo.h"

void init_swappable_rom_banks(void);
void init_video(void);
void enable_video(void);
void write_message_to_screen(void);
void delay(void);

extern void scenario_16(void);

uint8_t paused = false;

void main(void)
{
    init_swappable_rom_banks(); // Initialize MMC3 controller.
    init_video();               // Configure display settings.

    write_message_to_screen();  // Writes a string message to the video memory.
    
    mmc3_switch_bank(BANK_REG_8K_PRG_0, 8);
    scenario_16();
    
    grid_draw__init();
    enable_video();             // Display screen and sprites.

    while (1) {
        while (!paused) {
            lta_display_next_generation();
            grid__clear_buffer1();
            lta_display_next_generation();
            grid__clear_buffer2();
        }
    }
}

// CAREFUL!  Called from NMI!  Make sure not to use the C stack!
void handle_gamepad_input(void)
{
    if (P1_BTN_START_CUR_PRESSED && !P1_BTN_START_PREV_PRESSED) {
        // Start was pressed 'now'.
        paused = !paused; // Toggle paused state.
    }
}

void init_swappable_rom_banks(void)
{
    mmc3_set_prg_bank_mode_0();
    mmc3_set_chr_bank_mode_0();
    mmc3_switch_bank(BANK_REG_2K_CHR_0, 0);
    mmc3_switch_bank(BANK_REG_2K_CHR_1, 2);
    mmc3_switch_bank(BANK_REG_1K_CHR_0, 4);
    mmc3_switch_bank(BANK_REG_1K_CHR_1, 5);
    mmc3_switch_bank(BANK_REG_1K_CHR_2, 6);
    mmc3_switch_bank(BANK_REG_1K_CHR_3, 7);
}

void init_video(void)
{
    background_palettes_t background_palettes = {
        {WHITE, PALE|BLUE, BLACK, MEDIUM|RED},  // Palette 0
        {WHITE, GRAY, BLACK, LIGHT|BLUE},       // Palette 1
        {WHITE, GRAY, BLACK, LIGHT|BLUE},       // Palette 2
        {WHITE, GRAY, BLACK, LIGHT|BLUE}        // Palette 3
    };

    ppu_set_background_palettes(&background_palettes);
    ppu_set_screen_pattern_table(PATTERN_TABLE_1);     // Letters are in the second pattern table.
    ppu_set_sprite_pattern_table(PATTERN_TABLE_1);     // Letters are in the second pattern table.
    ppu_disable_image_clipping_in_leftmost_8px();
    ppu_disable_sprite_clipping_in_leftmost_8px();
    ppu_clear_nametable(NAMETABLE_0, 0);
    ppu_clear_nametable(NAMETABLE_2, 0);
}

void enable_video(void)
{
    ppu_enable_screen();
    ppu_enable_sprites();
    ppu_enable_vblank();
}

void write_message_to_screen(void)
{
    char message[] = "Hello world!";

    // Write 'message' string in the middle of NAMETABLE_0
    ppu_set_rw_addr_by_nametable_coordinate(NAMETABLE_0, 14, 10);
    ppu_write((uint8_t*)message, strlen(message));

    ppu_write_scroll_offsets();
}

void delay(void)
{
    uint16_t i;

    for (i = 0; i < 40000; i++);
}
