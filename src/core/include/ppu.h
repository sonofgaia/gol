#ifndef _PPU_H_
#define _PPU_H_

typedef enum { NAMETABLE_0, NAMETABLE_1, NAMETABLE_2, NAMETABLE_3 } nametable_t;
typedef enum { PATTERN_TABLE_0, PATTERN_TABLE_1 } pattern_table_t;
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

#endif
