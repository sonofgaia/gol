.include "mmc3.inc"
.include "lib.inc"
.include "zeropage.inc"

.exportzp _mmc3__bank_modes
.export   _mmc3__switch_bank
.export   _mmc3__clear_ram

.import   incsp2

.segment "ZPVARS" : zeropage

_mmc3__bank_modes: .res 1

.segment "CODE"

;;-------------------------------------------------------------------------------------------------
;; Routine : _mmc3__switch_bank
;;-------------------------------------------------------------------------------------------------
;; Controls ROM bank switching with the MMC3 mapper.
;;
;; Designed to be called from C and outside the NMI.
;;
;; Params
;;     Bank register identifier, see ENUM in 'mmc3.inc'  (passed on the stack)
;;     Bank number to switch to                          (passed through Accumulator)
;;-------------------------------------------------------------------------------------------------
.proc _mmc3__switch_bank
    tax                     ; Save bank number to 'X'

    lda _mmc3__bank_modes
    ldy #$00
    ora (sp), y             ; Acc. now contains bank modes + bank register

    sta MMC3_BANK_SELECT
    stx MMC3_BANK_DATA

    jmp incsp2
.endproc

;;-------------------------------------------------------------------------------------------------
;; Routine : _mmc3_clear_ram
;;-------------------------------------------------------------------------------------------------
;; Clears (sets to '0') the 8K of RAM provided by the MMC3 mapper.
;;-------------------------------------------------------------------------------------------------
.proc _mmc3__clear_ram
    ldx #0
    lda #0

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
