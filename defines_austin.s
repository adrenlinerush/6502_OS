; configuration
CONFIG_2A := 1

CONFIG_SCRTCH_ORDER := 2

; zero page
ZP_START1 = $20
ZP_START2 = $2A
ZP_START3 = $80
ZP_START4 = $8B

; extra/override ZP variables
USR := GORESTART

; constants
SPACE_FOR_GOSUB := $3E
STACK_TOP := $FA
WIDTH := 40
WIDTH2 := 30
RAMSTART2 := $0400