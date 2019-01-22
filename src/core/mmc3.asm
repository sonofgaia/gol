.include "mmc3.inc"
.include "lib.inc"
.include "zeropage.inc"

.exportzp _mmc3_bank_select
.export   _mmc3_switch_bank

.import incsp2

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
    bank_number         = tmp1
    bank_select_bitmask = tmp2

    sta bank_number

    lda _mmc3_bank_select
    and #$F8
    sta bank_select_bitmask
    
    ldy #$00
    lda (sp), y
    ora bank_select_bitmask     ; 'A' now contains bank select byte

    sta MMC3_BANK_SELECT
    lda bank_number
    sta MMC3_BANK_DATA

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
