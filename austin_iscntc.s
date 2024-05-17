ISCNTC:
        ; check flag set by bios
        PHA
        LDA $17
        CMP #$01
        BEQ is_cntc
not_cntc:
        PLA
        RTS
is_cntc:
        ; clear flag
        LDA #$00
        STA $17
        LDA #3
        SEC
        PLA
