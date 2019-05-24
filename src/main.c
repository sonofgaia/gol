#include <string.h>
#include "init.h"
#include "gamepad.h"
#include "ppu.h"
#include "mmc3.h"
#include "oam.h"
#include "grid.h"
#include "lookup_table_algo.h"

void init_swappable_rom_banks(void);
void init_video(void);
void enable_video(void);
void write_message_to_screen(void);
void delay(void);

void set_grid_scenario1(void);
void set_grid_scenario2(void);

void main(void)
{
    init_swappable_rom_banks(); // Initialize MMC3 controller.
    init_video();               // Configure display settings.

    write_message_to_screen();  // Writes a string message to the video memory.
    
    set_grid_scenario1(); 
    
    enable_video();             // Display screen and sprites.

    while (1) {
        //grid_copy_to_nametable();
        lta_display_next_generation();
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

void set_grid_scenario1(void)
{
    grid_set_cell(20, 26, CELL_OCCUPIED);
    grid_set_cell(21, 26, CELL_OCCUPIED);
    grid_set_cell(24, 26, CELL_OCCUPIED);
    grid_set_cell(25, 26, CELL_OCCUPIED);
    grid_set_cell(26, 26, CELL_OCCUPIED);
    grid_set_cell(21, 24, CELL_OCCUPIED);
    grid_set_cell(23, 25, CELL_OCCUPIED);
}

void set_grid_scenario2(void)
{
    grid_set_cell(20, 10, CELL_OCCUPIED);
    grid_set_cell(21, 10, CELL_OCCUPIED);
    grid_set_cell(21, 11, CELL_OCCUPIED);
    grid_set_cell(22, 11, CELL_OCCUPIED);
    grid_set_cell(22, 12, CELL_OCCUPIED);
    grid_set_cell(23, 12, CELL_OCCUPIED);

    grid_set_cell(20, 30, CELL_OCCUPIED);
    grid_set_cell(21, 30, CELL_OCCUPIED);
    grid_set_cell(22, 30, CELL_OCCUPIED);
    grid_set_cell(23, 30, CELL_OCCUPIED);
    grid_set_cell(24, 30, CELL_OCCUPIED);
}
