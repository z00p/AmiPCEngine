

	IFND	LOG_ENABLED	; default, or set with -DLOG_ENABLED=1
LOG_ENABLED=0
	ENDC
LOG_VIA_BUFFER=0
LOG_VIA_SERIAL=1	; 0:Disabled / 1:Enabled


LogString:MACRO
	IFNE	LOG_ENABLED
	MOVE.W	CCR,-(SP)
	MOVE.L	#\@.txt,LogInput
	BRA.S	\@.skip
\@.txt:
	DC.B	\1,0
	EVEN
\@.skip:
	JSR	LogStringRut
	MOVE.W	(SP)+,CCR
	ENDC
	ENDM


LogText:MACRO
	IFNE	LOG_ENABLED
	MOVE.W	CCR,-(SP)
	MOVE.L	\1,LogInput
	JSR	LogStringRut
	MOVE.W	(SP)+,CCR
	ENDC
	ENDM



LogHexByte:MACRO
	IFNE	LOG_ENABLED
	MOVE.W	CCR,-(SP)
	MOVE.B	\1,LogInput
	JSR	LogHexByteRut
	MOVE.W	(SP)+,CCR
	ENDC
	ENDM

LogHexWord:MACRO
	IFNE	LOG_ENABLED
	MOVE.W	CCR,-(SP)
	MOVE.W	\1,LogInput
	JSR	LogHexWordRut
	MOVE.W	(SP)+,CCR
	ENDC
	ENDM

LogHexLong:MACRO
	IFNE	LOG_ENABLED
	MOVE.W	CCR,-(SP)
	MOVE.L	\1,LogInput
	JSR	LogHexLongRut
	MOVE.W	(SP)+,CCR
	ENDC
	ENDM



LogEnter:MACRO
	IFNE	LOG_ENABLED
	LogString $0A
	ENDC
	ENDM

LogSpace:MACRO
	IFNE	LOG_ENABLED
	LogString $20
	ENDC
	ENDM


; ----------------------------------------------------------------------

	IFNE	LOG_ENABLED


	cnop	0,8
LogStringRut:

	movem.l	d0/a0/a1,-(sp)

	move.l	LogInput,A0

	IFNE	LOG_VIA_BUFFER
	move.l	LogIndex,A1
	cmp.l	#LogBufEnd,A1
	bcc.s	.end
	ENDC

.loop:
	move.b	(a0)+,d0
	beq.s	.zero

	IFNE	LOG_VIA_BUFFER
	move.b	d0,(a1)+
	ENDC

	IFNE	LOG_VIA_SERIAL
	bsr	SerialWriteChar
	ENDC

	bra.s	.loop
.zero:

	IFNE	LOG_VIA_BUFFER
	move.l	a1,LogIndex
	ENDC

.end:
	movem.l	(sp)+,d0/a0/a1

	rts




LogHexLongRut:

	IFNE	LOG_VIA_BUFFER
	cmp.l	#LogBufEnd,LogIndex
	bcc.s	logHexEnd
	ENDC

	movem.l	d0-d1,-(sp)

	move.l	LogInput(pc),d1
; ---
	bfextu	D1{0:4},D0
	move.b	(HexToAscConvTable.L,D0.W),D0

	IFNE	LOG_VIA_BUFFER
	move.b	d0,([LogIndex])
	addq.l	#1,LogIndex
	ENDC

	IFNE	LOG_VIA_SERIAL
	bsr	SerialWriteChar
	ENDC
; ---
	bfextu	D1{4:4},D0
	move.b	(HexToAscConvTable.L,D0.W),D0

	IFNE	LOG_VIA_BUFFER
	move.b	d0,([LogIndex])
	addq.l	#1,LogIndex
	ENDC

	IFNE	LOG_VIA_SERIAL
	bsr	SerialWriteChar
	ENDC
; ---
	bfextu	D1{8:4},D0
	move.b	(HexToAscConvTable.L,D0.W),D0

	IFNE	LOG_VIA_BUFFER
	move.b	d0,([LogIndex])
	addq.l	#1,LogIndex
	ENDC

	IFNE	LOG_VIA_SERIAL
	bsr	SerialWriteChar
	ENDC
; ---
	bfextu	D1{12:4},D0
	move.b	(HexToAscConvTable.L,D0.W),D0

	IFNE	LOG_VIA_BUFFER
	move.b	d0,([LogIndex])
	addq.l	#1,LogIndex
	ENDC

	IFNE	LOG_VIA_SERIAL
	bsr	SerialWriteChar
	ENDC
; ---
	bra.s	continueWithWord


LogHexWordRut:

	IFNE	LOG_VIA_BUFFER
	cmp.l	#LogBufEnd,LogIndex
	bcc.s	logHexEnd
	ENDC

	movem.l	d0-d1,-(sp)

	move.w	LogInput(pc),d1

continueWithWord:

; ---
	bfextu	D1{16:4},D0
	move.b	(HexToAscConvTable.L,D0.W),D0

	IFNE	LOG_VIA_BUFFER
	move.b	d0,([LogIndex])
	addq.l	#1,LogIndex
	ENDC

	IFNE	LOG_VIA_SERIAL
	bsr	SerialWriteChar
	ENDC
; ---
	bfextu	D1{20:4},D0
	move.b	(HexToAscConvTable.L,D0.W),D0

	IFNE	LOG_VIA_BUFFER
	move.b	d0,([LogIndex])
	addq.l	#1,LogIndex
	ENDC

	IFNE	LOG_VIA_SERIAL
	bsr	SerialWriteChar
	ENDC
; ---
	bra.s	continueWithByte


LogHexByteRut:

	IFNE	LOG_VIA_BUFFER
	cmp.l	#LogBufEnd,LogIndex
	bcc.s	logHexEnd
	ENDC

	movem.l	d0-d1,-(sp)

	move.b	LogInput(pc),d1

continueWithByte:
; ---
	bfextu	D1{24:4},D0
	move.b	(HexToAscConvTable.L,D0.W),D0

	IFNE	LOG_VIA_BUFFER
	move.b	d0,([LogIndex])
	addq.l	#1,LogIndex
	ENDC

	IFNE	LOG_VIA_SERIAL
	bsr	SerialWriteChar
	ENDC
; ---
	bfextu	D1{28:4},D0
	move.b	(HexToAscConvTable.L,D0.W),D0

	IFNE	LOG_VIA_BUFFER
	move.b	d0,([LogIndex])
	addq.l	#1,LogIndex
	ENDC

	IFNE	LOG_VIA_SERIAL
	bsr	SerialWriteChar
	ENDC
; ---
	movem.l	(sp)+,d0-d1
logHexEnd:
	rts


ConvertByte2HexAsc:
	MOVE.B	D0,D1
	LSR.B	#4,D0
	AND.W	#$0F,D0
	MOVE.B	(HexToAscConvTable.L,D0.W),D0
	LSL.W	#8,D0
	AND.W	#$0F,D1
	MOVE.B	(HexToAscConvTable.L,D1.W),D0
	RTS

HexToAscConvTable:
	DC.B	"0123456789ABCDEF"



	cnop	0,8
SerialWriteChar:
	btst	#5,$dff018	; SERDATR 0x18 ; SERDATR_TBE (1 << 13) /* Tx Buffer Empty */
	beq.s	SerialWriteChar

	move.w	d0,-(sp)
	and.w	#$00ff,d0
	or.w	#$0100,d0	; SERDAT_STP8	(1 << 8)

	move.w	d0,$dff030	; SERDAT	0x30	
	move.w	(sp)+,d0
	rts


	ENDC


	cnop	0,8
		dc.l	0	; don't remove, it must be before LogInput:
LogInput:	dc.l	0
LogIndex:	dc.l	LogBufIni
LogBufIni:	ds.b	512*1024
LogBufEnd:	ds.b	256
	cnop	0,8


; -------------------------------------------

