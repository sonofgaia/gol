.include "lib.inc"

.exportzp _mmc3__bank_modes
.export   _mmc3__clear_ram

.segment "ZPVARS" : zeropage

_mmc3__bank_modes: .res 1

.segment "CODE"

;;-------------------------------------------------------------------------------------------------
;; Routine : _mmc3_clear_ram
;;-------------------------------------------------------------------------------------------------
;; Clears (sets to '0') the 8K of RAM provided by the MMC3 mapper.
;;-------------------------------------------------------------------------------------------------
.proc _mmc3__clear_ram
    ldax #0

    @loop:
        .repeat 32, i ; 32 pages of memory (0x6000-0x7fff)
            sta i * $100 + $6000, x
        .endrepeat

        inx
        bne @loop

    rts
.endproc
