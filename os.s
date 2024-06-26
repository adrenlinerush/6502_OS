    .include "hw_setup.s"

; Memory used by os.s $FC-$FF

    .org $8100
LOOP:
    SEI ; Set Interrupt
    LDA KBD_RPTR
    CMP KBD_WPTR
    CLI ; Clear Interrupt
    BNE KEY_PRESSED
    JMP LOOP

KEY_PRESSED:
    LDX KBD_RPTR
    INC KBD_RPTR
    LDA KBD, X
    CMP #$0A ; enter
    BEQ KEY_ENTER
    CMP #$08 ; backpace
    BEQ KEY_BKSP
    JMP CONTINUE

KEY_ENTER:
    JSR LFCR
    LDX CMD_LEN
    CPX #$00
    BEQ NO_CMD
    JSR EXECUTE_CMD
    LDX #$00
    STX CMD_LEN
NO_CMD:
    JSR PROMPT
    JMP LOOP

KEY_BKSP:
    LDX CMD_LEN
    CPX #$00
    BEQ LOOP ; Command Lenght is already 0

    DEC CMD_LEN
    JSR ECHO ; Send Backspace
    JSR SEND_ESC_SEQ ; Erase to end of screen
    LDA #$4A ; J 
    JSR ECHO
    JMP LOOP

CONTINUE:  
    LDX CMD_LEN
    STA CMD, X
    INC CMD_LEN
    JSR ECHO
    JMP LOOP


EXECUTE_CMD:
    LDX #$01

    LDA #$0F
    STA TEXT_FLAGS
    LDY #$03
    STY BIOS_SYSCALL_N
    JSR $F000            ; Test Bios Adddress 

    LDA #$33             ; BLACK
    STA FG_COLOR
    LDA #$30         
    STA FG_COLOR, X
    LDY #$01
    STY BIOS_SYSCALL_N
    JSR $F000            ; Test Bios Adddress 

    LDA #$34             ; RED
    STA BG_COLOR
    LDA #$31         
    STA BG_COLOR, X
    LDY #$02
    STY BIOS_SYSCALL_N
    JSR $F000            ; Test Bios Adddress 

    LDA #<CMD        
    STA BIOS_STR_ADDR
    LDA #>CMD
    STA BIOS_STR_ADDR, X
    LDA CMD_LEN
    STA BIOS_STR_LEN
    LDY #$04            ; Print command
    STY BIOS_SYSCALL_N
    JSR $F000
    JSR RESET_TERMINAL
    JSR LFCR

    LDA CMD
    CMP #$48 ; H
    BEQ CMD_HEX_DUMP

    LDA CMD
    CMP #$53 ; S
    BEQ CMD_STORE_HEX

    LDA CMD
    CMP #$52 ; R
    BEQ CMD_RUN

    LDA CMD
    CMP #$4D ; M
    BEQ CMD_MEMTEST

    LDA CMD
    CMP #$43 ; C
    BEQ CMD_CLS

    JMP DONE_EXECUTE

CMD_HEX_DUMP:
    JSR HEX_DUMP
    JSR LFCR
    JMP DONE_EXECUTE

CMD_STORE_HEX:
    JSR STORE_HEX
    JSR LFCR
    JMP DONE_EXECUTE

CMD_RUN:
    JMP JSR_AT_ADDR
RUN_RETURN:
    JSR LFCR
    JMP DONE_EXECUTE

CMD_MEMTEST:
    JSR MemLoopTop

CMD_CLS:
    JSR RESET_TERMINAL
    JSR CLS

DONE_EXECUTE:
    RTS

RESET_TERMINAL:
    LDA #$00
    STA TEXT_FLAGS
    LDY #$03
    STY BIOS_SYSCALL_N
    JSR $F000            ; Test Bios Adddress 

    LDA #$33             ; GREEN
    STA FG_COLOR
    LDA #$32         
    STA FG_COLOR, X
    LDY #$01
    STY BIOS_SYSCALL_N
    JSR $F000            ; Test Bios Adddress 

    LDA #$34             ; BLACK
    STA BG_COLOR
    LDA #$30         
    STA BG_COLOR, X
    LDY #$02
    STY BIOS_SYSCALL_N
    JSR $F000            ; Test Bios Adddress 


    RTS

HEX_DUMP:
    LDX #$02
    LDA CMD, X
    STA BIOS_STR_ADDR
    INX
    LDA CMD, X
    LDX #$01
    STA BIOS_STR_ADDR, X

    LDY #$07
    STY BIOS_SYSCALL_N
    JSR $F000

    LDA #$00
    STA BIOS_STR_ADDR
    LDA BIOS_HEX_CNT
    STA BIOS_STR_ADDR, X
    LDA #$FF
    STA BIOS_STR_LEN

    LDY #$05
    STY BIOS_SYSCALL_N
    JSR $F000

    LDA #$FF
    STA BIOS_STR_ADDR
    LDA #$01
    STA BIOS_STR_LEN

    JSR $F000

    RTS

GET_DEST_ADDR:
    LDX #$02
    LDA CMD, X
    STA BIOS_STR_ADDR
    INX
    LDA CMD, X
    LDX #$01
    STA BIOS_STR_ADDR, X

    LDY #$07
    STY BIOS_SYSCALL_N
    JSR $F000

    LDA BIOS_HEX_CNT
    STA $FF

    LDX #$04
    LDA CMD, X
    STA BIOS_STR_ADDR
    INX
    LDA CMD, X
    LDX #$01
    STA BIOS_STR_ADDR, X

    LDY #$07
    STY BIOS_SYSCALL_N
    JSR $F000

    LDA BIOS_HEX_CNT
    STA $FE
   
    RTS

STORE_HEX:
    JSR GET_DEST_ADDR    
    LDX #$07
    LDY #$00
    STY $FD
HEX_TO_STORE:
    LDA CMD, X
    STA BIOS_STR_ADDR
    INX
    LDA CMD, X
    STX $FC
    LDX #$01
    STA BIOS_STR_ADDR, X
    LDX $FC

    LDY #$07
    STY BIOS_SYSCALL_N
    JSR $F000

    LDA BIOS_HEX_CNT
    LDY $FD
    STA ($FE), Y

    INY
    STY $FD
    INX
    INX

    CPX CMD_LEN
    BCC HEX_TO_STORE;
  
    RTS

JSR_AT_ADDR:
    JSR GET_DEST_ADDR    
    JMP ($FE)


    .include "bios.s"
