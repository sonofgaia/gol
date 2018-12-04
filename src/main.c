#include "gamepad.h"
#include "ppu.h"

void setup_ppu(void);
void enable_ppu(void);
void disable_ppu(void);

void main(void)
{
    char message[] = "Hello world";

    background_palette_t background_palette = {
        {0x20,0x28,0x26,0xFF},
        {0x20,0x28,0x26,0x21},
        {0x20,0x28,0x26,0x21},
        {0x20,0x28,0x26,0x21}
    };

    sprite_palette_t sprite_palette = {
        {0x20,0x0F,0x00,0x10},
        {0x20,0x20,0x00,0x10},
        {0x20,0x28,0x28,0x28},
        {0x20,0x28,0x28,0x28}
    };

    setup_ppu();

    ppu_set_background_palette(&background_palette);
    ppu_clear_nametable(NAMETABLE_0);

    // Write 'Hello World' in the middle of NAMETABLE_0
    ppu_set_rw_addr((uint8_t*)0x21CA);
    ppu_write((uint8_t*)message, sizeof(message));

    enable_ppu();

    ppu_write_scroll_offsets();

    while (1);
}

void setup_ppu(void)
{
    ppu_disable_large_sprites();
    ppu_disable_image_clipping_in_leftmost_8px();
    ppu_disable_sprite_clipping_in_leftmost_8px();
    ppu_set_nametable(NAMETABLE_0);
    ppu_set_screen_pattern_table(PATTERN_TABLE_1);
    ppu_set_sprite_pattern_table(PATTERN_TABLE_1);
    ppu_emphasize_colors(COLOR_EMPHASIS_CLEAR);
}

void enable_ppu(void)
{
    ppu_enable_screen();
    ppu_enable_sprites();
    ppu_enable_vblank();
}

void disable_ppu(void)
{
    ppu_disable_screen();
    ppu_disable_sprites();
    ppu_disable_vblank();
}
