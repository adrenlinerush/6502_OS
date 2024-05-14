; configuration
CONFIG_2A := 1

CONFIG_SCRTCH_ORDER := 2

; zero page
;ZP_START0 = $00
ZP_START1 = $22
ZP_START2 = $2C
ZP_START3 = $82
ZP_START4 = $8D

; extra/override ZP variables
USR := GORESTART

; constants
SPACE_FOR_GOSUB := $3E
STACK_TOP := $FA
WIDTH := 80
WIDTH2 := 36
RAMSTART2 := $0400
