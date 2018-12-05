#ifndef _PPU_H_
#define _PPU_H_

#include <stdint.h>
#include "ppu_colors.h"

typedef enum { 
    NAMETABLE_0,
    NAMETABLE_1, 
    NAMETABLE_2, 
    NAMETABLE_3 
} nametable_t;

typedef enum { 
    PATTERN_TABLE_0, 
    PATTERN_TABLE_1 
} pattern_table_t;

typedef enum {
    COLOR_EMPHASIS_CLEAR,
    COLOR_EMPHASIS_RED,
    COLOR_EMPHASIS_GREEN,
    COLOR_EMPHASIS_RED_GREEN,
    COLOR_EMPHASIS_BLUE,
    COLOR_EMPHASIS_RED_BLUE,
    COLOR_EMPHASIS_GREEN_BLUE,
    COLOR_EMPHASIS_RED_GREEN_BLUE
} color_emphasis_t;

typedef struct {
    uint8_t color_0;
    uint8_t color_1;
    uint8_t color_2;
    uint8_t color_3;
} palette_t;

struct grouped_palette_struct {
    palette_t palette_0;
    palette_t palette_1;
    palette_t palette_2;
    palette_t palette_3;
};

typedef struct grouped_palette_struct background_palettes_t;
typedef struct grouped_palette_struct sprite_palettes_t;

void __fastcall__ ppu_set_nametable(nametable_t nametable);
void __fastcall__ ppu_enable_vertical_write(void);
void __fastcall__ ppu_disable_vertical_write(void);
void __fastcall__ ppu_set_sprite_pattern_table(pattern_table_t pattern_table);
void __fastcall__ ppu_set_screen_pattern_table(pattern_table_t pattern_table);
void __fastcall__ ppu_enable_large_sprites(void);
void __fastcall__ ppu_disable_large_sprites(void);
void __fastcall__ ppu_enable_vblank(void);
void __fastcall__ ppu_disable_vblank(void);
void __fastcall__ ppu_enable_image_clipping_in_leftmost_8px(void);
void __fastcall__ ppu_disable_image_clipping_in_leftmost_8px(void);
void __fastcall__ ppu_enable_sprite_clipping_in_leftmost_8px(void);
void __fastcall__ ppu_disable_sprite_clipping_in_leftmost_8px(void);
void __fastcall__ ppu_enable_screen(void);
void __fastcall__ ppu_disable_screen(void);
void __fastcall__ ppu_enable_sprites(void);
void __fastcall__ ppu_disable_sprites(void);
void __fastcall__ ppu_emphasize_colors(color_emphasis_t colors);
void __fastcall__ ppu_vblank_wait(void);
void __fastcall__ ppu_set_background_palettes(background_palettes_t* palettes);
void __fastcall__ ppu_clear_nametable(nametable_t nametable);

extern void __fastcall__ ppu_set_rw_addr(uint8_t* addr);
extern void __fastcall__ ppu_write(uint8_t* addr, uint8_t nb_bytes);
extern void __fastcall__ ppu_write_byte(uint8_t byte, uint8_t count);
extern void __fastcall__ ppu_write_scroll_offsets(void);

#endif
