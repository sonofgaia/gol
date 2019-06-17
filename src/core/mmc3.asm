.include "mmc3.inc"
.include "lib.inc"
.include "zeropage.inc"

.exportzp _mmc3_bank_select
.export   _mmc3_switch_bank                  ; For 'C' environment
.export   _mmc3_clear_ram
.export   __mmc3_switch_bank                 ; For ASM environment, outside NMI
.export   __mmc3_switch_bank_mode_0          ; For ASM environment, outside NMI
.export   __mmc3_switch_bank_from_nmi        ; For ASM environment, inside NMI
.export   __mmc3_switch_bank_mode_0_from_nmi ; For ASM environment, inside NMI

.import   incsp2

.segment "ZPVARS" : zeropage

_mmc3_bank_select: .res 1

.segment "CODE"

;;-------------------------------------------------------------------------------------------------
;; Routine : _mmc3_switch_bank
;;-------------------------------------------------------------------------------------------------
;; Controls ROM bank switching with the MMC3 mapper.
;;
;; Designed to be called from C and outside the NMI.
;;
;; Params
;;     Bank register identifier, see ENUM in 'mmc3.inc'  (passed on the stack)
;;     Bank number to switch to                          (passed through Accumulator)
;;-------------------------------------------------------------------------------------------------
.proc _mmc3_switch_bank
    tax                         ; Save bank number to 'X'

    lda _mmc3_bank_select
    and #$F8
    ldy #$00
    ora (sp), y

    sta MMC3_BANK_SELECT
    stx MMC3_BANK_DATA

    jmp incsp2
.endproc

;;-------------------------------------------------------------------------------------------------
;; Routine : __mmc3_switch_bank
;;-------------------------------------------------------------------------------------------------
;; Controls ROM bank switching with the MMC3 mapper.
;;
;; Designed to be called from assembly and outside the NMI.
;;
;; Params
;;     Bank register identifier, see ENUM in 'mmc3.inc'  (passed through X register)
;;     Bank number to switch to                          (passed through Y register)
;;-------------------------------------------------------------------------------------------------
.proc __mmc3_switch_bank
    __mmc3_switch_bank_inline FALSE, FALSE  ; Defined in 'mmc3.inc'
    rts
.endproc

;;-------------------------------------------------------------------------------------------------
;; Routine : __mmc3_switch_bank_mode_0
;;-------------------------------------------------------------------------------------------------
;; Same functionality and parameters as '__mmc3_swith_bank'.
;; Is faster than __mmc3_switch_bank routine by assuming that "Mode 0" is used for both PRG and CHR banks.
;;
;; Designed to be called from assembly and outside the NMI.
;;-------------------------------------------------------------------------------------------------
.proc __mmc3_switch_bank_mode_0
    __mmc3_switch_bank_inline TRUE, FALSE  ; Defined in 'mmc3.inc'
    rts
.endproc

;;-------------------------------------------------------------------------------------------------
;; Routine : __mmc3_switch_bank_from_nmi
;;-------------------------------------------------------------------------------------------------
;; Same functionality and parameters as '__mmc3_swith_bank'.
;;
;; Designed to be called from assembly and inside the NMI.
;;-------------------------------------------------------------------------------------------------
.proc __mmc3_switch_bank_from_nmi
    __mmc3_switch_bank_inline FALSE, TRUE  ; Defined in 'mmc3.inc'
    rts
.endproc

;;-------------------------------------------------------------------------------------------------
;; Routine : __mmc3_switch_bank_mode_0_from_nmi
;;-------------------------------------------------------------------------------------------------
;; Same functionality and parameters as '__mmc3_swith_bank'.
;; Is faster than __mmc3_switch_bank routine by assuming that "Mode 0" is used for both PRG and CHR banks.
;;
;; Designed to be called from assembly and inside the NMI.
;;-------------------------------------------------------------------------------------------------
.proc __mmc3_switch_bank_mode_0_from_nmi
    __mmc3_switch_bank_inline TRUE, TRUE  ; Defined in 'mmc3.inc'
    rts
.endproc

;;-------------------------------------------------------------------------------------------------
;; Routine : _mmc3_clear_ram
;;-------------------------------------------------------------------------------------------------
;; Clears (sets to '0') the 8K of RAM provided by the MMC3 mapper.
;;-------------------------------------------------------------------------------------------------
.proc _mmc3_clear_ram
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
