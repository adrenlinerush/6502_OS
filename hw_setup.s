PORTB = $7C00
PORTA = $7C01
DDRB = $7C02
DDRA = $7C03

PCR = $7C0C
IFR = $7C0D
IER = $7C0E

KBD = $0200
KBD_WPTR = $00
KBD_RPTR = $01
KBD_FLAGS = $02

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
CMD = $0300
RETURN = $12

Pointer = $13
PointerH = $14
TestValue = $15

SD_CS   = %00001000
SD_SCK  = %00000100
SD_MOSI = %00000010
SD_MISO = %00000001

VIA2_PORTA = $7A01
VIA2_DDRA  = $7A03

  .org $8000

RESET:
    LDA #$00
    STA CMD_LEN

    LDA #<RUN_RETURN
    STA RETURN
    LDX #$01
    LDA #>RUN_RETURN
    STA RETURN, X

    LDA #$00 ; set PTR and FLAGS
    STA KBD_FLAGS
    STA KBD_WPTR
    STA KBD_RPTR

    LDA #$ff ; Set VIA Port B to output
    STA DDRB

    LDA #$00 ; Set VIA Port A to input
    STA DDRA

    LDA #$0E ; Set VIA2 Port A for SD CARD
    STA VIA2_DDRA
  
    LDA #$00
    STA TEXT_FLAGS   
 
    JSR RESET_TERMINAL
    JSR CLS 
    JSR PROMPT

    CLI


