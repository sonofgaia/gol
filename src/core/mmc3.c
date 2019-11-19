#include <stdint.h>
#include "mmc3.h"

#define MMC3_PRG_RAM_PROTECT *((uint8_t*)0xA001)

typedef struct {
    uint16_t unused        :6;
    uint16_t prg_bank_mode :1;
    uint16_t chr_bank_mode :1;
} mmc3__bank_modes_t;

extern mmc3__bank_modes_t mmc3__bank_modes;
#pragma zpsym("mmc3__bank_modes");

void __fastcall__ mmc3__set_prg_bank_mode(mmc3__prg_bank_mode_t prg_bank_mode)
{
    mmc3__bank_modes.prg_bank_mode = prg_bank_mode;
}

void __fastcall__ mmc3__set_chr_bank_mode(mmc3__chr_bank_mode_t chr_bank_mode)
{
    mmc3__bank_modes.chr_bank_mode = chr_bank_mode;
}

void __fastcall__ mmc3__enable_prg_ram(void)
{
    // Bit 7 'on' activates the RAM chip
    MMC3_PRG_RAM_PROTECT = 0x80;
}

void __fastcall__ mmc3__disable_prg_ram(void)
{
    // Bit 7 'off' disables the RAM chip, accesses to $6000-$7FFFF will return 'open bus'.
    MMC3_PRG_RAM_PROTECT = 0x00;
}
