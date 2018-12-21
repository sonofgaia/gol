#include <stdint.h>
#include "mmc3.h"

typedef struct {
    uint16_t bank_select   :3;
    uint16_t unused        :3;
    uint16_t prg_bank_mode :1;
    uint16_t chr_bank_mode :1;
} mmc3_bank_select_t;

// Functions and data defined in 'ppu.asm'
extern mmc3_bank_select_t mmc3_bank_select;
#pragma zpsym ("mmc3_bank_select");

void __fastcall__ mmc3_set_prg_bank_mode(mmc3_prg_bank_mode_t prg_bank_mode)
{
    mmc3_bank_select.prg_bank_mode = prg_bank_mode;
}

void __fastcall__ mmc3_set_chr_bank_mode(mmc3_chr_bank_mode_t chr_bank_mode)
{
    mmc3_bank_select.chr_bank_mode = chr_bank_mode;
}

void __fastcall__ mmc3_switch_bank(mmc3_bank_reg_t bank_reg, uint8_t bank_num)
{
    mmc3_bank_select.bank_select = bank_reg;

    // Select bank register
    *((uint8_t*)0x8000) = (uint8_t)mmc3_bank_select;

    // Change bank register
    *((uint8_t*)0x8001) = bank_num;
}
