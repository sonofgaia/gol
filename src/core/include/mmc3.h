#ifndef _MMC3_H_
#define _MMC3_H_

#define MMC3__BANK_SELECT 0x8000
#define MMC3__BANK_DATA   0x8001

typedef enum {
    PRG_ROM_BANK_MODE_0,    // $8000-$9FFF swappable, $C000-$DFFF fixed to second-last bank
    PRG_ROM_BANK_MODE_1     // $C000-$DFFF swappable, $8000-$9FFF fixed to second-last bank
} mmc3__prg_bank_mode_t;

typedef enum {
    CHR_ROM_BANK_MODE_0,    // Two 2KB banks at $0000-$0FFF, four 1KB banks at $1000-$1FFF
    CHR_ROM_BANK_MODE_1     // Two 2KB banks at $1000-$1FFF, four 1KB banks at $0000-$0FFF
} mmc3__chr_bank_mode_t;

typedef enum {
    BANK_REG_2K_CHR_0,      // First  2K CHR bank register (PPU $0000-$07FF (or $1000-$17FF))
    BANK_REG_2K_CHR_1,      // Second 2K CHR bank register (PPU $0800-$0FFF (or $1800-$1FFF))
    BANK_REG_1K_CHR_0,      // First  1K CHR bank register (PPU $1000-$13FF (or $0000-$03FF)) 
    BANK_REG_1K_CHR_1,      // Second 1K CHR bank register (PPU $1400-$17FF (or $0400-$07FF))
    BANK_REG_1K_CHR_2,      // Third  1K CHR bank register (PPU $1800-$1BFF (or $0800-$0BFF))
    BANK_REG_1K_CHR_3,      // Fourth 1K CHR bank register (PPU $1C00-$1FFF (or $0C00-$0FFF))
    BANK_REG_8K_PRG_0,      // First  8K PRG bank register ($8000-$9FFF (or $C000-$DFFF))
    BANK_REG_8K_PRG_1,      // Second 8K PRG bank register ($A000-$BFFF)
} mmc3__bank_reg_t;

typedef struct {
    uint16_t unused        :6;
    uint16_t prg_bank_mode :1;
    uint16_t chr_bank_mode :1;
} mmc3__bank_modes_t;

void __fastcall__ mmc3__set_prg_bank_mode(mmc3__prg_bank_mode_t prg_bank_mode);
void __fastcall__ mmc3__set_chr_bank_mode(mmc3__chr_bank_mode_t chr_bank_mode);

extern void __fastcall__ mmc3__clear_ram(void);

extern mmc3__bank_modes_t mmc3__bank_modes;
#pragma zpsym("mmc3__bank_modes");

#define mmc3__switch_bank(bank_reg, bank_num) \
    __asm__ ("lda %v",  mmc3__bank_modes); \
    __asm__ ("ora #%b", bank_reg); \
    __asm__ ("sta %w",  MMC3__BANK_SELECT); \
    __asm__ ("lda #%b", bank_num); \
    __asm__ ("sta %w",  MMC3__BANK_DATA);

#endif
