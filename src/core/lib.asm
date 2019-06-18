.include "lib.inc"

.segment "ZPVARS" : zeropage

; Variables used in NMI handler.
_tmp1: .res 1
_tmp2: .res 1
_tmp3: .res 1
_tmp4: .res 1
_ptr1: .res 2
_ptr2: .res 2
_ptr3: .res 2
_ptr4: .res 2

; Variables used outside of the NMI.
gol_tmp1: .res 1
gol_tmp2: .res 1
gol_tmp3: .res 1
gol_tmp4: .res 1
gol_ptr1: .res 2
gol_ptr2: .res 2
gol_ptr3: .res 2
gol_ptr4: .res 2

; Space to save registers (before function call, etc.)
regs: .res 6

.segment "IDENTITY_TABLE"

identity_table:
    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F
    .byte $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1A, $1B, $1C, $1D, $1E, $1F
    .byte $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2A, $2B, $2C, $2D, $2E, $2F
    .byte $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F
    .byte $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4A, $4B, $4C, $4D, $4E, $4F
    .byte $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5A, $5B, $5C, $5D, $5E, $5F
    .byte $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $6A, $6B, $6C, $6D, $6E, $6F
    .byte $70, $71, $72, $73, $74, $75, $76, $77, $78, $79, $7A, $7B, $7C, $7D, $7E, $7F
    .byte $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $8A, $8B, $8C, $8D, $8E, $8F
    .byte $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9A, $9B, $9C, $9D, $9E, $9F
    .byte $A0, $A1, $A2, $A3, $A4, $A5, $A6, $A7, $A8, $A9, $AA, $AB, $AC, $AD, $AE, $AF
    .byte $B0, $B1, $B2, $B3, $B4, $B5, $B6, $B7, $B8, $B9, $BA, $BB, $BC, $BD, $BE, $BF
    .byte $C0, $C1, $C2, $C3, $C4, $C5, $C6, $C7, $C8, $C9, $CA, $CB, $CC, $CD, $CE, $CF
    .byte $D0, $D1, $D2, $D3, $D4, $D5, $D6, $D7, $D8, $D9, $DA, $DB, $DC, $DD, $DE, $DF
    .byte $E0, $E1, $E2, $E3, $E4, $E5, $E6, $E7, $E8, $E9, $EA, $EB, $EC, $ED, $EE, $EF
    .byte $F0, $F1, $F2, $F3, $F4, $F5, $F6, $F7, $F8, $F9, $FA, $FB, $FC, $FD, $FE, $FF

.segment "LIB_LOOKUP_TABLES"

.align 256
lsr5_lookup_table:
    .byte $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
    .byte $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
    .byte $1, $1, $1, $1, $1, $1, $1, $1, $1, $1, $1, $1, $1, $1, $1, $1
    .byte $1, $1, $1, $1, $1, $1, $1, $1, $1, $1, $1, $1, $1, $1, $1, $1
    .byte $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2
    .byte $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2
    .byte $3, $3, $3, $3, $3, $3, $3, $3, $3, $3, $3, $3, $3, $3, $3, $3
    .byte $3, $3, $3, $3, $3, $3, $3, $3, $3, $3, $3, $3, $3, $3, $3, $3
    .byte $4, $4, $4, $4, $4, $4, $4, $4, $4, $4, $4, $4, $4, $4, $4, $4
    .byte $4, $4, $4, $4, $4, $4, $4, $4, $4, $4, $4, $4, $4, $4, $4, $4
    .byte $5, $5, $5, $5, $5, $5, $5, $5, $5, $5, $5, $5, $5, $5, $5, $5
    .byte $5, $5, $5, $5, $5, $5, $5, $5, $5, $5, $5, $5, $5, $5, $5, $5
    .byte $6, $6, $6, $6, $6, $6, $6, $6, $6, $6, $6, $6, $6, $6, $6, $6
    .byte $6, $6, $6, $6, $6, $6, $6, $6, $6, $6, $6, $6, $6, $6, $6, $6
    .byte $7, $7, $7, $7, $7, $7, $7, $7, $7, $7, $7, $7, $7, $7, $7, $7
    .byte $7, $7, $7, $7, $7, $7, $7, $7, $7, $7, $7, $7, $7, $7, $7, $7

.align 256
and1f_or80_lookup_table:
    .byte $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $8a, $8b, $8c, $8d, $8e, $8f
    .byte $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9a, $9b, $9c, $9d, $9e, $9f
    .byte $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $8a, $8b, $8c, $8d, $8e, $8f
    .byte $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9a, $9b, $9c, $9d, $9e, $9f
    .byte $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $8a, $8b, $8c, $8d, $8e, $8f
    .byte $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9a, $9b, $9c, $9d, $9e, $9f
    .byte $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $8a, $8b, $8c, $8d, $8e, $8f
    .byte $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9a, $9b, $9c, $9d, $9e, $9f
    .byte $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $8a, $8b, $8c, $8d, $8e, $8f
    .byte $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9a, $9b, $9c, $9d, $9e, $9f
    .byte $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $8a, $8b, $8c, $8d, $8e, $8f
    .byte $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9a, $9b, $9c, $9d, $9e, $9f
    .byte $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $8a, $8b, $8c, $8d, $8e, $8f
    .byte $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9a, $9b, $9c, $9d, $9e, $9f
    .byte $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $8a, $8b, $8c, $8d, $8e, $8f
    .byte $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9a, $9b, $9c, $9d, $9e, $9f
