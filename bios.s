; Basic Input and Output Functions
;BOLD   = $0F
;ITALIC = $08
;ULINE  = $04
;BLINK  = $02
;INVERT = $01

RELEASE = %00000001
SHIFT   = %00000010

    .org $F000

BIOS_SYSCALL:
    PHA
    TXA
    PHA
    TYA
    PHA

    LDA BIOS_SYSCALL_N
    CMP #$01
    BEQ BIOS_FG

    CMP #$02
    BEQ BIOS_BG
   
    CMP #$03
    BEQ BIOS_TEXT_FLAGS

    CMP #$04 ; ASCII
    BEQ BIOS_PRINT

    CMP #$05 ; HEX
    BEQ BIOS_PRINT

    CMP #$06
    BEQ BIOS_MV_CURSOR

    CMP #$07
    BEQ BIOS_ASCII_TO_HEX

    JMP BIOS_EXIT

BIOS_FG:
    JSR SET_FG_COLOR
    JMP BIOS_EXIT
BIOS_BG:
    JSR SET_BG_COLOR
    JMP BIOS_EXIT
BIOS_TEXT_FLAGS:
    JSR SET_TEXT
    JMP BIOS_EXIT
BIOS_PRINT:
    LDY #$00
    STY BIOS_HEX_CNT
NEXT_CHAR:
    LDA (BIOS_STR_ADDR), Y
    LDX BIOS_SYSCALL_N
    CPX #$05
    BEQ PRINT_HEX
    JSR ECHO
    JMP NOT_HEX
PRINT_HEX:
    JSR ECHO_HEX
    INC BIOS_HEX_CNT
    LDX BIOS_HEX_CNT
    CPX #$10
    BEQ HEX_NL
    LDA #$20
    JSR ECHO
    JMP NOT_HEX
HEX_NL:
    LDX #$00
    STX BIOS_HEX_CNT
    JSR LFCR
NOT_HEX:
    INY
    CPY BIOS_STR_LEN
    BNE NEXT_CHAR
    JMP BIOS_EXIT
BIOS_MV_CURSOR:
    JSR MV_CURSOR
    JMP BIOS_EXIT
BIOS_ASCII_TO_HEX:
    JSR ASCII_TO_HEX

BIOS_EXIT:
    ; restore regiters before returning
    PLA
    TAY
    PLA
    TAX
    PLA

    RTS

ASCII_TO_HEX:
    LDY #$00
    STY BIOS_HEX_CNT
    LDA BIOS_STR_ADDR
    SEC
    SBC #$30
    CMP #$0A
    BCC IS_DIGIT
    SBC #$07
IS_DIGIT:
    ASL
    ASL
    ASL
    ASL
    ORA BIOS_HEX_CNT
    STA BIOS_HEX_CNT 

    LDX #$01
    LDA BIOS_STR_ADDR, X
    SEC
    SBC #$30
    CMP #$0A
    BCC IS_DIGIT2
    SBC #$07
IS_DIGIT2:
    ORA BIOS_HEX_CNT
    STA BIOS_HEX_CNT 
    
    RTS  

IRQ:
    JSR KBD_IRQ
    RTI

KBD_IRQ:
    ; push reigisters onto stack off the registers
    PHA
    TXA
    PHA
    TYA
    PHA
   

    LDX #$02; try delaying so I get correct scan code
    JSR DELAY_REG_X_CYCLES
    
    LDX PORTA
    CPX #$F0 ; Release Code
    BEQ KBD_RELEASE

    CPX #$12 
    BEQ KBD_SHIFT
    CPX #$59
    BEQ KBD_SHIFT

    LDA KBD_FLAGS
    AND #SHIFT
    BNE KBD_SHIFTED_KEY

    LDY KEYMAP, X
    JMP KBD_VALID

KBD_SHIFTED_KEY:
    LDY KEYMAP_SHIFTED, X
    
KBD_VALID:
    ; exit if invalid scancode
    CPY #$00 ; Unknown
    BEQ KBD_EXIT

    LDA KBD_FLAGS
    AND #RELEASE
    BEQ KBD_PUSHKEY ; if not releasing Push

KBD_CLR_RELEASE:
    LDA KBD_FLAGS
    EOR #RELEASE
    STA KBD_FLAGS

    JMP KBD_EXIT

KBD_PUSHKEY:
    LDX KBD_WPTR
    TYA
    STA KBD, X
    INC KBD_WPTR
    JMP KBD_EXIT

KBD_SHIFT:
    LDA KBD_FLAGS
    AND #SHIFT
    BNE KBD_SHIFT_UP

KBD_SHIFT_DOWN:
    LDA KBD_FLAGS
    ORA #SHIFT
    STA KBD_FLAGS
   
    JMP KBD_EXIT

KBD_SHIFT_UP:
    LDA KBD_FLAGS
    EOR #SHIFT
    STA KBD_FLAGS

    JMP KBD_CLR_RELEASE

    
KBD_RELEASE:
    LDA KBD_FLAGS
    ORA #RELEASE
    STA KBD_FLAGS

KBD_EXIT:
    ; restore regiters before returning
    PLA
    TAY
    PLA
    TAX
    PLA
    RTS

NMI:
    RTI

MV_CURSOR:
    JSR SEND_ESC_SEQ
    LDA CURSOR_X 
    JSR ECHO
    LDX #$01
    LDA CURSOR_X, X 
    JSR ECHO
    LDA #$3B ; ;
    JSR ECHO
    LDA CURSOR_Y 
    JSR ECHO
    LDX #$01
    LDA CURSOR_Y, X 
    JSR ECHO
    LDA #$48 ; H
    JSR ECHO

    RTS


SET_FG_COLOR:
    JSR SEND_ESC_SEQ

    LDA FG_COLOR 
    JSR ECHO
    LDX #$01
    LDA FG_COLOR, X 
    JSR ECHO

    LDA #$6D
    JSR ECHO
  
    RTS

SET_BG_COLOR:
    JSR SEND_ESC_SEQ
     
    LDA BG_COLOR 
    JSR ECHO
    LDX #$01
    LDA BG_COLOR, X 
    JSR ECHO

    LDA #$6D ; m
    JSR ECHO
  
    RTS

SET_TEXT:
    LDA TEXT_FLAGS
    CMP #$0F
    BCC UNSET_BOLD

    SBC #$0F
    STA TEXT_FLAGS
   
    LDX #$31
    JSR SET_TEXT_OPTION
    JMP ST_ITALIC

UNSET_BOLD:
    LDX #$32
    JSR UNSET_TEXT_OPTION

ST_ITALIC:
    LDX #$33
    LDA TEXT_FLAGS
    CMP #$08
    BCC UNSET_ITALIC
   
    SBC #$08
    STA TEXT_FLAGS
        
    JSR SET_TEXT_OPTION

    JMP ST_ULINE

UNSET_ITALIC:
    JSR UNSET_TEXT_OPTION

ST_ULINE:
    LDX #$34
    LDA TEXT_FLAGS
    CMP #$04
    BCC UNSET_ULINE

    SBC #$04
    STA TEXT_FLAGS
   
    JSR SET_TEXT_OPTION
        
    JMP ST_BLINK

UNSET_ULINE:
    JSR UNSET_TEXT_OPTION

ST_BLINK:
    LDX #$35
    LDA TEXT_FLAGS
    CMP #$02
    BCC UNSET_BLINK
   
    SBC #$02
    STA TEXT_FLAGS
        
    JSR SET_TEXT_OPTION

    JMP ST_INVERT

UNSET_BLINK:
    JSR UNSET_TEXT_OPTION

ST_INVERT:
    LDX #$37
    LDA TEXT_FLAGS
    CMP #$01
    BCC UNSET_INVERT

    SBC #$01
    STA TEXT_FLAGS
   
    JSR SET_TEXT_OPTION
        
    JMP ST_RETURN

UNSET_INVERT:
    JSR UNSET_TEXT_OPTION
    
ST_RETURN:
    RTS

SET_TEXT_OPTION:
    JSR SEND_ESC_SEQ
    TXA
    JSR ECHO
    LDA #$6D ; m
    JSR ECHO
  
    RTS

UNSET_TEXT_OPTION:
    JSR SEND_ESC_SEQ
    LDA #$32 ; 2
    JSR ECHO
    TXA
    JSR ECHO
    LDA #$6D ; m
    JSR ECHO

    RTS

SEND_ESC_SEQ:
    LDA #$1B ; Escape
    JSR ECHO
    LDA #$5B ; [
    JSR ECHO
  
ECHO_HEX:
    PHA 
    ROR
    ROR
    ROR
    ROR
    JSR ECHO_NIBBLE
    PLA
ECHO_NIBBLE:
    AND #15
    CMP #10
    BMI SKIPLETTER
    ADC #6
SKIPLETTER:
    ADC #48
    JSR ECHO
    RTS 

ECHO:
    STA PORTB
    LDA #$00
    STA PORTB
    RTS

LFCR:
    LDA #$0A ; New Line
    JSR ECHO
    LDA #$0D ; Cairrage Return
    JSR ECHO
   
    RTS

CLS:
    JSR SEND_ESC_SEQ
    LDA #$32 ; 2
    JSR ECHO
    LDA #$4A ; J
    JSR ECHO

    JSR SEND_ESC_SEQ
    LDA #$48 ; H
    JSR ECHO

    RTS

PROMPT:
    LDA #$3E ; >
    JSR ECHO
 
    LDA #$20
    JSR ECHO

    RTS

DELAY_REG_X_CYCLES:
    DEX
    BNE DELAY_REG_X_CYCLES
    RTS

  .org $fd00
KEYMAP:
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$09,"`",$00
  .byte $00,$00,$00,$00,$00,"q1",$00,$00,$00,"zsaw2",$00
  .byte $00,"cxde43",$00,$00," vftr5",$00
  .byte $00,"nbhgy6",$00,$00,$00,"mju78",$00
  .byte $00,",kio09",$00,$00,"./l;p-",$00
  .byte $00,$00,"'",$00,"[=",$00,$00,$00,$00,$0A,"]",$00,$5C,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$08,$00,$00,"1",$00,"47",$00,$00,$00 ; Number Pad + BSP Fix Special Keys
  .byte "0.2568",$1b,$00,$00,"+3-*9",$00,$00                         ; Number Pad
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
KEYMAP_SHIFTED:
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$09,"~",$00
  .byte $00,$00,$00,$00,$00,"Q!",$00,$00,$00,"ZSAW@",$00
  .byte $00,"CXDE$#",$00,$00," VFTR%",$00
  .byte $00,"NBHGY^",$00,$00,$00,"MJU&*",$00
  .byte $00,"<KIO)(",$00,$00,">?L:P_",$00
  .byte $00,$00,'"',$00,"{+",$00,$00,$00,$00,$0A,"}",$00,"?",$00,$00
  .byte $00,$00,$00,$00,$00,$00,$08,$00,$00,"1",$00,"47",$00,$00,$00 ; Nubmer Pad + BSP Fix Special Keys
  .byte "0.2568",$1b,$00,$00,"+3-*9",$00,$00                         ; Number Pad
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

  .org $fffa
  .word NMI
  .word RESET
  .word IRQ
