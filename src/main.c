#include "init.h"
#include "gamepad.h"
#include "ppu.h"
#include "oam.h"
#include "grid.h"

extern void onc_apply_rules(void);

void scenario1(void); // Defined at the end of this file
void scenario2(void); // Defined at the end of this file

void main(void)
{
    char message[] = "Je t'aime Nico";
    sprite_info_t *sprite1, *sprite2;
    int i;

    // Initialize screen
    background_palettes_t background_palettes = {
        {WHITE, PALE|BLUE, BLACK, MEDIUM|RED}, // Palette 0
        {WHITE, GRAY, BLACK, LIGHT|BLUE}, // Palette 1
        {WHITE, GRAY, BLACK, LIGHT|BLUE}, // Palette 2
        {WHITE, GRAY, BLACK, LIGHT|BLUE}  // Palette 3
    };

    ppu_set_background_palettes(&background_palettes);
    ppu_set_screen_pattern_table(PATTERN_TABLE_1);     // Letters are in the second pattern table.
    ppu_set_sprite_pattern_table(PATTERN_TABLE_1);     // Letters are in the second pattern table.
    ppu_clear_nametable(NAMETABLE_0, 0);
    ppu_clear_nametable(NAMETABLE_2, 0);

    // Write 'Hello World' in the middle of NAMETABLE_0
    ppu_set_rw_addr_by_nametable_coordinate(NAMETABLE_0, 14, 10);
    ppu_write((uint8_t*)message, sizeof(message));

    ppu_write_scroll_offsets();

    //init_set_nmi_handler(&nmi_handler);
    scenario1(); 

    ppu_enable_vblank();
    ppu_enable_screen();
    ppu_enable_sprites();
    ppu_disable_image_clipping_in_leftmost_8px();
    ppu_disable_sprite_clipping_in_leftmost_8px();

    while (1) {
        grid_copy_to_nametable(NAMETABLE_0);
        onc_apply_rules();
        //grid_apply_rules(); // Old algo
    }
}

void scenario1(void)
{
    grid_set_cell(20, 26, CELL_OCCUPIED);
    grid_set_cell(21, 26, CELL_OCCUPIED);
    grid_set_cell(24, 26, CELL_OCCUPIED);
    grid_set_cell(25, 26, CELL_OCCUPIED);
    grid_set_cell(26, 26, CELL_OCCUPIED);
    grid_set_cell(21, 24, CELL_OCCUPIED);
    grid_set_cell(23, 25, CELL_OCCUPIED);
}

void scenario2(void)
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
