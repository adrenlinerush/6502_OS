StartAddressH = $04
EndAddressH   = $6F
	.org $FB00

MemLoopTop:
        LDA #$00
	STA Pointer
	LDA #StartAddressH
	STA PointerH
	LDY #0
	LDA TestValue
MemWriteLoop:
	STA (Pointer),y
        JSR DisplayCurAddr
	INY
	BNE MemWriteLoop
	INC PointerH
	LDX PointerH
	CPX #EndAddressH
	BNE MemWriteLoop
	;Add an error to test the test.
	; LDA #1
	; STA $477
	LDA #StartAddressH
	STA PointerH
MemCheckLoop:
        JSR DisplayCurAddr
	LDA (Pointer),y
	CMP TestValue
	BNE ErrorMsg
ErrorReturn:
	INY
	BNE MemCheckLoop
	INC PointerH
	LDX PointerH
	CPX #EndAddressH
	BNE MemCheckLoop
	;INC TestValue
	;JMP MemLoopTop
        JSR LFCR
        JSR WaitAnyKey
        RTS 
ErrorMsg:
	JSR LFCR
	LDA #'$'
	JSR ECHO
	LDA PointerH
	JSR ECHO_HEX
	TYA
	JSR ECHO_HEX
	JSR LFCR
        JSR WaitError
	JMP ErrorReturn

DisplayCurAddr:
        PHA
        TXA
        PHA
        TYA
        PHA
       
        JSR CLS 

        LDA PointerH
        JSR ECHO_HEX

        PLA
        PHA
        JSR ECHO_HEX
        
        PLA
	TAY
	PLA
	TAX
	PLA
	RTS

WaitError:
        JSR LFCR
        LDA #<ErrorMsgString
        STA BIOS_STR_ADDR
        LDX #$01
        LDA #>ErrorMsgString
        STA BIOS_STR_ADDR, X
        LDX #$04
        STX BIOS_SYSCALL_N
        LDX #$37
        STX BIOS_STR_LEN
        JSR $F000
        JMP Waiting

WaitAnyKey:
        LDA #<AnyKeyMsg
        STA BIOS_STR_ADDR
        LDX #$01
        LDA #>AnyKeyMsg
        STA BIOS_STR_ADDR, X
        LDX #$04
        STX BIOS_SYSCALL_N
        LDX #$24
        STX BIOS_STR_LEN
        JSR $F000
Waiting:
        SEI
        LDA KBD_RPTR
        CMP KBD_WPTR
        CLI
        BEQ Waiting
	JMP ExitMemTest
 
ExitMemTest:
        JSR LFCR
        INC KBD_RPTR
        RTS

AnyKeyMsg:
	.byte "Press any key to return to AusMON..."

ErrorMsgString:
        .byte "Error Ocurred.  Press any key to contiue testing RAM..."
