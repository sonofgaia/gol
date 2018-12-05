#include <stdint.h>
#include "ppu.h"

typedef struct {
    uint16_t nametable            :2;
    uint16_t vertical_write       :1;
    uint16_t sprite_pattern_table :1;
    uint16_t screen_pattern_table :1;
    uint16_t sprite_size          :1;
    uint16_t unused               :1; // Do not use, may damage original NES hardware
    uint16_t vblank_enable        :1;
} ppu_control_reg1_t;

typedef struct {
    uint16_t unused          :1;
    uint16_t image_clipping  :1;
    uint16_t sprite_clipping :1;
    uint16_t screen_enable   :1;
    uint16_t sprites_enable  :1;
    uint16_t color_emphasis  :3;
} ppu_control_reg2_t;

// Functions and data defined in 'ppu.asm'
extern ppu_control_reg1_t ppu_control_reg1;
extern ppu_control_reg2_t ppu_control_reg2;
extern void __fastcall__ ppu_write_control_reg1(void);
extern void __fastcall__ ppu_write_control_reg2(void);

#pragma zpsym ("ppu_control_reg1");
#pragma zpsym ("ppu_control_reg2");

#define PPU_BACKGROUND_PALETTE_ADDR (uint8_t*)0x3F00

#define SCREEN_WIDTH_PIXELS       256
#define SCREEN_HEIGHT_PIXELS      240
#define TILE_WIDTH_PIXELS         8
#define TILE_HEIGHT_PIXELS        8
#define SCREEN_WIDTH_TILES        (SCREEN_WIDTH_PIXELS / TILE_WIDTH_PIXELS)
#define SCREEN_HEIGHT_TILES       (SCREEN_HEIGHT_PIXELS / TILE_WIDTH_PIXELS)
#define BYTES_PER_NAMETABLE_ENTRY 1
#define NAMETABLE_SIZE_BYTES      (SCREEN_WIDTH_TILES * SCREEN_HEIGHT_TILES * BYTES_PER_NAMETABLE_ENTRY)

const uint8_t* const ppu_nametable_addrs[] = {
    (const uint8_t*)0x2000, // Nametable 0
    (const uint8_t*)0x2400, // Nametable 1
    (const uint8_t*)0x2800, // Nametable 2
    (const uint8_t*)0x2C00  // Nametable 3
};

void __fastcall__ ppu_set_nametable(nametable_t nametable)
{
    ppu_control_reg1.nametable = nametable;
    ppu_write_control_reg1();
}

void __fastcall__ ppu_enable_vertical_write(void)
{
    ppu_control_reg1.vertical_write = 1;
    ppu_write_control_reg1();
}

void __fastcall__ ppu_disable_vertical_write(void)
{
    ppu_control_reg1.vertical_write = 0;
    ppu_write_control_reg1();
}

void __fastcall__ ppu_set_sprite_pattern_table(pattern_table_t pattern_table)
{
    ppu_control_reg1.sprite_pattern_table = pattern_table;
    ppu_write_control_reg1();
}

void __fastcall__ ppu_set_screen_pattern_table(pattern_table_t pattern_table)
{
    ppu_control_reg1.screen_pattern_table = pattern_table;
    ppu_write_control_reg1();
}

void __fastcall__ ppu_enable_large_sprites(void)
{
    ppu_control_reg1.sprite_size = 1;
    ppu_write_control_reg1();
}

void __fastcall__ ppu_disable_large_sprites(void)
{
    ppu_control_reg1.sprite_size = 0;
    ppu_write_control_reg1();
}

void __fastcall__ ppu_enable_vblank(void)
{
    ppu_control_reg1.vblank_enable = 1;
    ppu_write_control_reg1();
}

void __fastcall__ ppu_disable_vblank(void)
{
    ppu_control_reg1.vblank_enable = 0;
    ppu_write_control_reg1();
}

void __fastcall__ ppu_enable_image_clipping_in_leftmost_8px(void)
{
    ppu_control_reg2.image_clipping = 1;
    ppu_write_control_reg2();
}

void __fastcall__ ppu_disable_image_clipping_in_leftmost_8px(void)
{
    ppu_control_reg2.image_clipping = 0;
    ppu_write_control_reg2();
}

void __fastcall__ ppu_enable_sprite_clipping_in_leftmost_8px(void)
{
    ppu_control_reg2.sprite_clipping = 1;
    ppu_write_control_reg2();
}

void __fastcall__ ppu_disable_sprite_clipping_in_leftmost_8px(void)
{
    ppu_control_reg2.sprite_clipping = 0;
    ppu_write_control_reg2();
}

void __fastcall__ ppu_enable_screen(void)
{
    ppu_control_reg2.screen_enable = 1;
    ppu_write_control_reg2();
}

void __fastcall__ ppu_disable_screen(void)
{
    ppu_control_reg2.screen_enable = 0;
    ppu_write_control_reg2();
}

void __fastcall__ ppu_enable_sprites(void)
{
    ppu_control_reg2.sprites_enable = 1;
    ppu_write_control_reg2();
}

void __fastcall__ ppu_disable_sprites(void)
{
    ppu_control_reg2.sprites_enable = 0;
    ppu_write_control_reg2();
}

void __fastcall__ ppu_emphasize_colors(color_emphasis_t colors)
{
    ppu_control_reg2.color_emphasis = colors;
    ppu_write_control_reg2();
}

void __fastcall__ ppu_set_background_palettes(background_palettes_t* palettes)
{
    ppu_set_rw_addr(PPU_BACKGROUND_PALETTE_ADDR); 
    ppu_write((uint8_t*)palettes, sizeof(background_palettes_t));
}

void __fastcall__ ppu_clear_nametable(nametable_t nametable)
{
    uint8_t* nametable_addr = (uint8_t*)ppu_nametable_addrs[nametable];
    int i;

    ppu_set_rw_addr(nametable_addr);

    // Clears all bytes for the nametable and it's corresponding attribute table.
    for (i = 0; i < 8; i++) {
        ppu_write_byte(0, 128);
    }
}

void __fastcall__ ppu_set_rw_addr_by_nametable_coordinate(nametable_t nametable, uint8_t row, uint8_t col)
{
    uint8_t* nametable_addr = (uint8_t*)ppu_nametable_addrs[nametable];
    uint8_t* addr;

    addr = nametable_addr + row * SCREEN_WIDTH_TILES + col;

    ppu_set_rw_addr(addr);
}
