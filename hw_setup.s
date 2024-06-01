KBD_WPTR = $00
KBD_RPTR = $01
KBD_FLAGS = $02
R_CTRL_C = $17
R_BIOS_1 = $18
R_OS_1 = $19
R_OS_2 = $1A
R_OS_3 = $1B
R_OS_4 = $1C


CURSOR_X = $03
CURSOR_Y = $05
FG_COLOR = $07
BG_COLOR = $09
TEXT_FLAGS = $11

CMD_LEN = $0B
BIOS_SYSCALL_N = $0C
BIOS_STR_ADDR = $0D
BIOS_STR_LEN = $0F
BIOS_HEX_CNT = $10
CMD_RUN_RETURN = $12

Pointer = $14
PointerH = $15
TestValue = $16

SD_CS   = %00001000
SD_SCK  = %00000100
SD_MOSI = %00000010
SD_MISO = %00000001

VIA2_PORTA_OUTPUTPINS = SD_CS | SD_SCK | SD_MOSI

zp_sd_address = $40         ; 2 bytes
zp_sd_currentsector = $42   ; 4 bytes
zp_fat32_variables = $46    ; 24 bytes

fat32_workspace = $400      ; two pages

buffer = $600

.segment "BUFFERS"
KBD_BUFFER: .res $100
CMD: .res $100

.segment "HWSETUP"

PORTB = $7C00
PORTA = $7C01
DDRB = $7C02
DDRA = $7C03

PCR = $7C0C                                                                                                                                                      
IFR = $7C0D
IER = $7C0E

VIA2_PORTA = $7A01
VIA2_DDRA  = $7A03

RESET:
    LDA #<RUN_RETURN
    STA CMD_RUN_RETURN
    LDX #$01
    LDA #>RUN_RETURN
    STA CMD_RUN_RETURN, X

    LDA #$00 ; set PTR and FLAGS
    STA KBD_FLAGS
    STA KBD_WPTR
    STA KBD_RPTR
    STA R_CTRL_C
    STA CMD_LEN

    LDA #$ff ; Set VIA Port B to output
    STA DDRB

    LDA #$00 ; Set VIA Port A to input
    STA DDRA

    LDA #$00
    STA PCR
    LDA #$81
    STA IER


    ;LDA #$0E ; Set VIA2 Port A for SD CARD
    ;STA VIA2_DDRA

    ;LDA #$08 ; Set PCR to Handsake
    ;STA PCR
  
    LDA #$00
    STA TEXT_FLAGS   
 
    JSR RESET_TERMINAL
    JSR CLS 
    JSR PROMPT

    CLI

    JSR LOOP
