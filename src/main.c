#include "init.h"
#include "gamepad.h"
#include "ppu.h"
#include "oam.h"

void main(void)
{
    sprite_info_t *sprite1, *sprite2;
    char message[] = "Je t'aime Nico";

    // Initialize screen
    background_palettes_t background_palettes = {
        {WHITE, MEDIUM|GRAY, LIGHT|RED, MEDIUM|RED}, // Palette 0
        {WHITE, BLACK, LIGHT|RED, LIGHT|BLUE}, // Palette 1
        {WHITE, BLACK, LIGHT|RED, LIGHT|BLUE}, // Palette 2
        {WHITE, BLACK, LIGHT|RED, LIGHT|BLUE}  // Palette 3
    };

    ppu_set_background_palettes(&background_palettes);
    ppu_set_screen_pattern_table(PATTERN_TABLE_1);     // Letters are in the second pattern table.
    ppu_set_sprite_pattern_table(PATTERN_TABLE_1);     // Letters are in the second pattern table.
    ppu_clear_nametable(NAMETABLE_0);

    // Write 'Hello World' in the middle of NAMETABLE_0
    ppu_set_rw_addr_by_nametable_coordinate(NAMETABLE_0, 14, 10);
    ppu_write((uint8_t*)message, sizeof(message));

    sprite1 = oam_get_sprite_info(0);

    sprite1->pos_x = 100;
    sprite1->pos_y = 100;
    sprite1->tile_number = 'T';
    sprite1->attrs.vertical_flip = 0;
    sprite1->attrs.horizontal_flip = 0;

    sprite2 = oam_get_sprite_info(1);

    sprite2->pos_x = 200;
    sprite2->pos_y = 200;
    sprite2->tile_number = 'R';
    sprite2->attrs.vertical_flip = 0;
    sprite2->attrs.horizontal_flip = 0;

    ppu_write_scroll_offsets();

    // Enable PPU
    // Enable NMI for handling vblanks.
    //init_set_nmi_handler(&nmi_handler);
    ppu_enable_vblank();
    ppu_enable_screen();
    ppu_enable_sprites();

    while (1);
}
