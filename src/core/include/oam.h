#ifndef _OAM_H_
#define _OAM_H_

#include <stdint.h>

#define NUM_SPRITES 64

struct sprite_attrs {
    uint16_t palette         :2;
    uint16_t unused          :3;
    uint16_t behing_bg       :1; 
    uint16_t horizontal_flip :1;
    uint16_t vertical_flip   :1;
};

struct sprite_info_struct {
    uint8_t             pos_y;
    uint8_t             tile_number;
    struct sprite_attrs attrs;
    uint8_t             pos_x;
};

typedef struct sprite_info_struct sprite_info_t;

sprite_info_t* __fastcall__ oam_get_sprite_info(uint8_t sprite_index);

extern void __fastcall__ oam_copy_to_ppu(void);

#endif
