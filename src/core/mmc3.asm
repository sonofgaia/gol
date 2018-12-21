.export   _mmc3_enable_prg_ram, _mmc3_disable_prg_ram
.exportzp _mmc3_bank_select

.segment "ZPVARS" : zeropage
_mmc3_bank_select: .res 1       ; Used to keep track of PRG and CHR bank modes as well as switch banks.

.segment "CODE"

MMC3_PRG_RAM_PROTECT = $A001

.proc _mmc3_enable_prg_ram
    lda #$80                    ; Bit 7 'on' activates the RAM chip
    sta MMC3_PRG_RAM_PROTECT
    
    rts
.endproc

.proc _mmc3_disable_prg_ram
    lda #$00                    ; Bit 7 'off' disables the RAM chip, accesses to $6000-$7FFF will return 'open bus'.
    sta MMC3_PRG_RAM_PROTECT

    rts
.endproc
