ISCNTC:
        ; check flag set by bios
        LDA $16
        CMP #$01
        BEQ is_cntc
not_cntc:
        RTS
is_cntc:
        ; clear flag
        LDA #$00
        STA $16
