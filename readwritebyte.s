    .include "hw_setup.s"

; Let the SD card boot up, by pumping the clock with SD CS disabled

  lda #'I'
  jsr ECHO
  jsr LFCR

  ; We need to apply around 80 clock pulses with CS and MOSI high.
  ; Normally MOSI doesn't matter when CS is high, but the card is
  ; not yet is SPI mode, and in this non-SPI state it does care.

  lda #SD_CS | SD_MOSI
  ldx #160               ; toggle the clock 160 times, so 80 low-high transitions
.preinitloop:
  eor #SD_SCK
  sta VIA2_PORTA
  dex
  bne .preinitloop
  
  ; Read a byte from the card, expecting $ff as no commands have been sent
  jsr sd_readbyte
  jsr ECHO_HEX
  jsr LFCR

.cmd0
  ; GO_IDLE_STATE - resets card to idle state
  ; This also puts the card in SPI mode.
  ; Unlike most commands, the CRC is checked.

  lda #'c'
  jsr ECHO
  jsr LFCR
  lda #$00
  jsr ECHO_HEX
  jsr LFCR

  lda #SD_MOSI           ; pull CS low to begin command
  sta VIA2_PORTA

  ; CMD0, data 00000000, crc 95
  lda #$40
  jsr sd_writebyte
  lda #$00
  jsr sd_writebyte
  lda #$00
  jsr sd_writebyte
  lda #$00
  jsr sd_writebyte
  lda #$00
  jsr sd_writebyte
  lda #$95
  jsr sd_writebyte

  ; Read response and print it - should be $01 (not initialized)
  jsr sd_waitresult
  pha
  jsr ECHO_HEX
  jsr LFCR

  lda #SD_CS | SD_MOSI   ; set CS high again
  sta VIA2_PORTA

  ; Expect status response $01 (not initialized)
  pla
  cmp #$01
  bne .initfailed


  lda #'Y'
  jsr ECHO
  jsr LFCR

  ; loop forever
.loop:
  jmp .loop


.initfailed
  lda #'X'
  jsr ECHO
  jsr LFCR
  jmp .loop



sd_readbyte:
  ; Enable the card and tick the clock 8 times with MOSI high, 
  ; capturing bits from MISO and returning them

  ldx #8                      ; we'll read 8 bits
.loop:

  lda #SD_MOSI                ; enable card (CS low), set MOSI (resting state), SCK low
  sta VIA2_PORTA

  lda #SD_MOSI | SD_SCK       ; toggle the clock high
  sta VIA2_PORTA

  lda VIA2_PORTA                   ; read next bit
  and #SD_MISO

  clc                         ; default to clearing the bottom bit
  beq .bitnotset              ; unless MISO was set
  sec                         ; in which case get ready to set the bottom bit
.bitnotset:

  tya                         ; transfer partial result from Y
  rol                         ; rotate carry bit into read result
  tay                         ; save partial result back to Y

  dex                         ; decrement counter
  bne .loop                   ; loop if we need to read more bits

  rts


sd_writebyte:
  ; Tick the clock 8 times with descending bits on MOSI
  ; SD communication is mostly half-duplex so we ignore anything it sends back here

  ldx #8                      ; send 8 bits

.loop:
  asl                         ; shift next bit into carry
  tay                         ; save remaining bits for later

  lda #0
  bcc .sendbit                ; if carry clear, don't set MOSI for this bit
  ora #SD_MOSI

.sendbit:
  sta VIA2_PORTA                   ; set MOSI (or not) first with SCK low
  eor #SD_SCK
  sta VIA2_PORTA                   ; raise SCK keeping MOSI the same, to send the bit

  tya                         ; restore remaining bits to send

  dex
  bne .loop                   ; loop if there are more bits to send

  rts


sd_waitresult:
  ; Wait for the SD card to return something other than $ff
  jsr sd_readbyte
  cmp #$ff
  beq sd_waitresult
  rts

    .include "bios.s"
