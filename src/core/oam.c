#include "oam.h"

extern sprite_info_t oam[NUM_SPRITES];

sprite_info_t* __fastcall__ oam_get_sprite_info(uint8_t sprite_index)
{
    return oam + sprite_index;
}

void __fastcall__ oam_hide_sprite(sprite_info_t* sprite_info)
{
    sprite_info->pos_y = 0xFF; // Y values between 0xEF-0xFF hide the sprite.
}
