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
        sta $6000, x
        sta $6100, x
        sta $6200, x
        sta $6300, x
        sta $6400, x
        sta $6500, x
        sta $6600, x
        sta $6700, x
        sta $6800, x
        sta $6900, x
        sta $6A00, x
        sta $6B00, x
        sta $6C00, x
        sta $6D00, x
        sta $6E00, x
        sta $6F00, x
        sta $7000, x
        sta $7100, x
        sta $7200, x
        sta $7300, x
        sta $7400, x
        sta $7500, x
        sta $7600, x
        sta $7700, x
        sta $7800, x
        sta $7900, x
        sta $7A00, x
        sta $7B00, x
        sta $7C00, x
        sta $7D00, x
        sta $7E00, x
        sta $7F00, x

        inx
        bne @loop

    rts
.endproc
