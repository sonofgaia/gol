#include <stdint.h>
#include "mmc3.h"

#define MMC3_PRG_RAM_PROTECT *((uint8_t*)0xA001)

typedef struct {
    uint16_t bank_select   :3;
    uint16_t unused        :3;
    uint16_t prg_bank_mode :1;
    uint16_t chr_bank_mode :1;
} mmc3_bank_select_t;

extern mmc3_bank_select_t mmc3_bank_select;
#pragma zpsym("mmc3_bank_select");

void __fastcall__ mmc3_set_prg_bank_mode_0(void)
{
    mmc3_bank_select.prg_bank_mode = PRG_ROM_BANK_MODE_0;
}

void __fastcall__ mmc3_set_prg_bank_mode_1(void)
{
    mmc3_bank_select.prg_bank_mode = PRG_ROM_BANK_MODE_1;
}

void __fastcall__ mmc3_set_chr_bank_mode_0(void)
{
    mmc3_bank_select.chr_bank_mode = CHR_ROM_BANK_MODE_0;
}

void __fastcall__ mmc3_set_chr_bank_mode_1(void)
{
    mmc3_bank_select.chr_bank_mode = CHR_ROM_BANK_MODE_1;
}

void __fastcall__ mmc3_enable_prg_ram(void)
{
    // Bit 7 'on' activates the RAM chip
    MMC3_PRG_RAM_PROTECT = 0x80;
}

void __fastcall__ mmc3_disable_prg_ram(void)
{
    // Bit 7 'off' disables the RAM chip, accesses to $6000-$7FFFF will return 'open bus'.
    MMC3_PRG_RAM_PROTECT = 0x00;
}
