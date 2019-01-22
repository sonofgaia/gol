.ifndef _MMC3_

_MMC3_ = 1 ; Prevent multiple inclusions of this file

;; Ports used by the MMC3
MMC3_BANK_SELECT = $8000
MMC3_BANK_DATA   = $8001

.enum bank_reg
    BANK_REG_2K_CHR_0  ;; First  2K CHR bank register (PPU $0000-$07FF (or $1000-$17FF))
    BANK_REG_2K_CHR_1  ;; Second 2K CHR bank register (PPU $0800-$0FFF (or $1800-$1FFF))
    BANK_REG_1K_CHR_0  ;; First  1K CHR bank register (PPU $1000-$13FF (or $0000-$03FF)) 
    BANK_REG_1K_CHR_1  ;; Second 1K CHR bank register (PPU $1400-$17FF (or $0400-$07FF))
    BANK_REG_1K_CHR_2  ;; Third  1K CHR bank register (PPU $1800-$1BFF (or $0800-$0BFF))
    BANK_REG_1K_CHR_3  ;; Fourth 1K CHR bank register (PPU $1C00-$1FFF (or $0C00-$0FFF))
    BANK_REG_8K_PRG_0  ;; First  8K PRG bank register ($8000-$9FFF (or $C000-$DFFF))
    BANK_REG_8K_PRG_1  ;; Second 8K PRG bank register ($A000-$BFFF)
.endenum

;;-----------------------------------------------------------------------------------------------------------
;; macro : __mmc3_switch_bank_inline
;;-----------------------------------------------------------------------------------------------------------
;; Runs the same code as the __mmc3_switch_bank routine but saves a bit of time by not calling a subroutine.
;;
;; Params
;;     Bank register identifier, see ENUM in 'mmc3.inc'  (passed through X register)
;;     Bank number to switch to                          (passed through Y register)
;;-----------------------------------------------------------------------------------------------------------
.macro __mmc3_switch_bank_inline use_mode_0, called_from_interrupt
    .if called_from_interrupt
        tmp_var1 = _tmp1
    .else
        tmp_var1 = tmp1
    .endif

    .if use_mode_0
        ; If we are using 'mode 0' for both PRG and CHR banks, we can directly use the value
        ; passed in the X register as the bank select byte.
        stx MMC3_BANK_SELECT
    .else
        lda _mmc3_bank_select
        and $F8
        stx tmp_var1
        ora tmp_var1             ; Accumulator now contains the bank select byte

        sta MMC3_BANK_SELECT
    .endif

    sty MMC3_BANK_DATA
.endmacro

.endif
