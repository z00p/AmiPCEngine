
;	------------------------------
;	 Hu6280 CPU Emulation (Highly Optimized)
;	 By Juan Antonio Gómez Gálvez
;	------------------------------

; ---------------------------------------------------------
;	 A = D7
;	 X = D4
;	 Y = D5
;	PC = A5 (Amiga memory address)
;	SP = D6 (logic) and A6 (Amiga memory address)
;	 P = D3	(flags, uses Amiga SR/CCR flags format)
; ---------------------------------------------------------
;	D0 = Internal use
;	D1 = Internal use
;	D2 = $01xx
;	D3 = "P"
;	D4 = "X"
;	D5 = "Y"
;	D6 = "SP"
;	D7 = "A"

;	A0 = 
;	A1 = Not Used!
;	A2 = Store pointer to calculate PC logic-address of current memory-page
;	A3 = Main table with all data
;	A4 = Internal use
;	A5 = "PC" in Amiga memory
;	A6 = "SP" in Amiga memory
;	A7 = Amiga Stack!
; ---------------------------------------------------------


CPU_Init:
	BSR	CreaTablaFlags

	BCLR	#1,IOAM+$1402		; IRQ1 Interrupt Enabled? == 0
	IFEQ	NO_CSL
	ST	CpuSlow			; the HuC6280 starts at 1.79 MHz (games set CSH)
	ENDC

	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVE.L	#$0100,D2
	MOVEQ	#0,D3
	MOVEQ	#0,D4
	MOVEQ	#0,D5
	MOVE.l	#$00FF,D6
	MOVEQ	#0,D7
	RTS

CPU_Reset:
	RTS

; --------------------------------------------

	cnop	0,8
opCodeCount:	dc.l	1
	cnop	0,8
LogCPU:
	move.w	opCodeCount,D0
	LogHexWord D0
	move.w	opCodeCount+2,D0
	LogHexWord D0

	LogSpace
	LogString "sl:"
	MOVE.W	ScanLine(A3),D0
	LogHexWord D0

	LogSpace
	LogString "A:"
	LogHexByte D7

	LogSpace
	LogString "X:"
	LogHexByte D4

	LogSpace
	LogString "Y:"
	LogHexByte D5

	LogSpace
	LogString "cy:"
	IFEQ	NO_CYCREG
	MOVE.L	D2,D0
	SWAP	D0
	LogHexByte D0
	ELSE
	LogHexByte Cycles+1(A3)
	ENDC

	LogSpace
	LogString "SP:"
	LogHexByte D6

	LogSpace
	LogString "PC:"
	MOVE.L	A5,D0
	SUB.W	(A2),D0
	LogHexWord D0

	LogSpace
	LogString "["
	LogHexByte (A5)
	LogString "]"

	LogSpace
	moveq	#0,D0
	move.b	(A5),D0
	mulu	#6,D0
	lea	(opCodesStr.l,d0.l),A0
	LogText	A0

	LogEnter

	addq.l	#1,opCodeCount

	RTS


; --------------------------------------------


NextOP:	MACRO
	IFNC	"\1","0"

	IFEQ	NO_CYCREG
; cycles left in this line: upper word of D2 (the lower word is $01xx, the opcode)
	IFC	"\1","D1"
	SWAP	D2			; block transfers: D1.W cycles, D0/D1 left alone
	SUB.W	D1,D2
	BCS.S	\@ExitLoop		; line over: CPU_Loop sets D2 again
	SWAP	D2
	ELSEIF
	SUB.L	#(\1)<<16,D2		; borrow from the upper word = SUBQ.W on Cycles(A3)
	BCS.S	\@ExitLoop
	ENDC
	ELSE
	IFC	"\1","D1"
	SUB.W	D1,(A3)			; Cycles(A3)
	ELSEIF
	IFNE	\1 > 8
	SUB.W	#\1,(A3)		; Cycles(A3)
	ELSEIF
	SUBQ.W	#\1,(A3)		; Cycles(A3)
	ENDC
	ENDC
	BCS.S	\@ExitLoop
	ENDC

	ENDC

		IFNE	LogEnabled
		BSR	LogCPU
		ENDC

;	MOVE.B	(A5),D2
;	MOVE.W	(CyclesTab-$200,D2.W*2),D1
;	SUBQ.W	#4,(A3)			; Cycles(A3)
;	BCS.S	\@CheckInter
;	ADDQ	#1,A5

	MOVE.B	(A5)+,D2

	IFNE	UseDebug
	bsr	Debug_CheckTrace
	ENDC

	JMP	([A3,D2.W*4])
\@ExitLoop:
	RTS
	CNOP	0,8
	ENDM

; --------------------------------------------

UpdateFlags:	MACRO
	IFC	"NVZC","\1"
	MOVE.W	CCR,D3
	SVS	VFF(A3)
	ENDC

	IFC	"NxZx","\1"
	MOVE.W	CCR,D3
	BFINS	D2,D3{31:1}
	ENDC

	IFC	"NxZC","\1"
	MOVE.W	CCR,D3
	BCHG	#0,D3
	ENDC

	IFC	"NVZn","\1"
	MOVE.W	CCR,D3
	SVS	VFF(A3)
	BCHG	#0,D3
	ENDC
	ENDM

; --------------------------------------------

CalPag:	MACRO
	MOVE.L	\1,\2
	IFC	"D1","\1"
	LSR.W	#8,D1
	LSR.B	#5,D1
	ELSEIF
	BFEXTU	\1{16:3},D1
	ENDC
	ADD.L	PagRead(A3,D1.W*4),\2
	ENDM


CalPagE:MACRO
	MOVE.L	\1,\2
	IFC	"D1","\1"
	LSR.W	#8,D1
	LSR.B	#5,D1
	ELSEIF
	BFEXTU	\1{16:3},D1
	ENDC
	ADD.L	PagWrite(A3,D1.W*4),\2
	ENDM


CalStak:MACRO
	LEA	(IRAM.L,\1.W),\2
	ADDQ.L	#1,\2
	ENDM

; --------------------------------------------

CheckReadIO:MACRO
	BNE.S	\@NoReadIO
	BSR	ReadIO
\@NoReadIO:
	ENDM


CheckWriteIO:MACRO
	TST.B	D1
	BNE.S	\@NoWriteIO
	BSR	WriteIO
\@NoWriteIO:
	ENDM


; --------------------------------------------

;	D0.W : CPU Cycles to process in this 'loop'
;	D1.B : Interrupt Request
CPU_Loop:
	IFEQ	NO_CYCREG
	MOVE.W	D0,D2			; cycles of the line in D2's upper word
	SWAP	D2
	MOVE.W	#$0100,D2
	ELSE
	MOVE.W	D0,(A3)			; Cycles(A3)

	MOVE.L	#$0100,D2
	ENDC

	BSR.S	CheckInterrupt

	NextOP	0

; --------------------------------------------

CheckInterrupt:
	TST.B	IFF(A3)			; Interrupts Enabled? == 0
	BNE.S	NoInterrupt


	IFEQ	NO_TIMER
	BTST	#2,IRQ_Pending(A3)		; timer interrupt pending (stays until $1403 is written)
	BEQ.S	.noTimer
	BTST	#2,IOAM+$1402		; timer interrupt disabled?
	BNE.S	.noTimer
	MOVE.W	#$FFFA,IntVector		; timer has priority over IRQ1 (VDC)
	BRA.S	TakeInterrupt
.noTimer:
	ENDC
	BTST	#1,IOAM+$1402		; IRQ1 Interrupt Enabled? == 0
	BEQ.S	CheckIRQ1Interrupt
NoInterrupt:
	RTS

CheckIRQ1Interrupt:

;	MOVE.W	#$FFF,$DFF180

	BCLR	#1,IRQ_Pending(A3)	; IRQ1 Interrupt Pending? == 1
	BEQ.S	NoInterrupt
	IFEQ	NO_TIMER
	MOVE.W	#$FFF8,IntVector
TakeInterrupt:
	ENDC


	IFNE	LogEnabled
	LogString "----Interrupt----"
	LogEnter
	ENDC


	SUB.W	(A2),A5
	MOVE.W	A5,D1
	ROR.W	#8,D1
	SUBQ.B	#1,D6
	CalStak	D6,A6
	MOVE.B	D1,(A6)

	ROR.W	#8,D1
	SUBQ.B	#1,D6
	CalStak	D6,A6
	MOVE.B	D1,(A6)
;	-----------------------------------
	MOVE.B	D3,D1
	AND.W	#$000D,D1
	LEA	VFF(A3),A4
	AND.L	#$02402090,(A4)+
	OR.B	-(A4),D1
	OR.B	-(A4),D1
	OR.B	-(A4),D1
	OR.B	-(A4),D1
	SUBQ.B	#1,D6
	CalStak	D6,A6
	MOVE.B	(Flags_Push.w,PC,D1.W),(A6)
;	-----------------------------------

	ST	IFF(A3)			; ( DI ) Interrupciones OFF.
	SF	DFF(A3)

	IFEQ	NO_TIMER
	MOVE.W	IntVector,D1
	ELSE
	MOVE.W	#$FFF8,D1
	ENDC
	CalPag	D1,A4
	MOVE.W	(A4),D1
	ROR.W	#8,D1
	CalPag	D1,A5
	LEA	Restas(A3,D1.W*8),A2
	RTS

; --------------------------------------------


;	ra	Acumulador
;	id	Indirecto

;	ab	Absoluto			LDA	$C0AF
;	ax	Absoluto indexado con X		LDA	$C0AF,X
;	ay	Absoluto indexado con Y		LDA	$C0AF,Y

;	zp	ZeroPage			LDA	$AF
;	zx	ZeroPage indexado con X		LDA	$AF,X
;	zy	ZeroPage indexado con Y		LDA	$AF,Y

;	in	inmediato			LDA	#$7F
;	iy	indirectamente indexado		LDA	($70),Y
;	ix	indexado indirecto		LDA	($70,X)


; --------------------------------------------
; --------------------------------------------

;; -------------------------------------------------------------
;;		  \1    \2      \3    \4   \5     \6	   \7
;;	MIns	Instr,Destino,Origen,Modo,Flags,Ini.Flags,Cycles
;; -------------------------------------------------------------

MIns:	MACRO

	IFC	"NxZx","\5"		; ¿Guardar Flag C?
	MOVE.B	D3,D2
	ENDC


	IFC	"in","\4"		; LDA  #$01
	IFC	"N","\6"		; Especial para EOR,ADDX,SUBX
	\1	(A5)+,\2
	ELSEIF
	MOVE.B	(A5)+,D1
	IFC	"C","\6"		; Actualiza Flag C
	LSR.B	#1,D3
	OR.B	#$04,CCR
	ENDC
	\1	D1,\2
	ENDC
;ius
	UpdateFlags	\5			; Recoge Flags.
	NextOP	\7
	ENDC


	IFC	"ab","\4"		; LDA  $2003
	MOVE.W	(A5)+,D1
;ius2
	ROR.W	#8,D1
	IFNC	"nn","\3"
	ADD.W	\3,D1
	ENDC
	CalPag	D1,A4
	CheckReadIO
	IFC	"N","\6"		; Especial para EOR,ADDX,SUBX
	\1	(A4),\2
	ELSEIF
	MOVE.B	(A4),D1
	IFC	"C","\6"		; Actualiza Flag C
	LSR.B	#1,D3
	OR.B	#$04,CCR
	ENDC
	\1	D1,\2
	ENDC
	UpdateFlags	\5			; Recoge Flags.
	NextOP	\7
	ENDC


	IFC	"zp","\4"		; LDA  $03
	MOVEQ	#0,D1
	MOVE.B	(A5)+,D1
;ius
	IFNC	"nn","\3"
	IFC	"im","\3"
	MOVE.W	(IRAM,D1.L),D1
	ROR.W	#8,D1
	CalPag	D1,A4
	ELSEIF
	ADD.B	\3,D1
	ENDC
	ENDC

	IFNC	"im","\3"
	LEA	(IRAM,D1.L),A4		; Sustituye a	'CalPag	D1,A4'
	ENDC

	IFC	"N","\6"		; Especial para EOR,ADDX,SUBX
	\1	(A4),\2
	ELSEIF
	MOVE.B	(A4),D1
	IFC	"C","\6"		; Actualiza Flag C
	LSR.B	#1,D3
	OR.B	#$04,CCR
	ENDC
	\1	D1,\2
	ENDC
	UpdateFlags	\5			; Recoge Flags.
	NextOP	\7
	ENDC


	IFC	"iy","\4"		; LDA  ($03),Y
	MOVEQ	#0,D1
	MOVE.B	(A5)+,D1
;ius
	MOVE.W	(IRAM,D1.L),D1
	ROR.W	#8,D1
	ADD.W	\3,D1
	CalPag	D1,A4
	CheckReadIO
	IFC	"N","\6"		; Especial para EOR,ADDX,SUBX
	\1	(A4),\2
	ELSEIF
	MOVE.B	(A4),D1
	IFC	"C","\6"		; Actualiza Flag C
	LSR.B	#1,D3
	OR.B	#$04,CCR
	ENDC
	\1	D1,\2
	ENDC
	UpdateFlags	\5			; Recoge Flags.
	NextOP	\7
	ENDC


	IFC	"ix","\4"		; LDA  ($03,X)
	MOVEQ	#0,D1
	MOVE.B	(A5)+,D1
;ius
	ADD.B	\3,D1
	MOVE.W	(IRAM,D1.L),D1
	ROR.W	#8,D1
	CalPag	D1,A4
	CheckReadIO
	IFC	"N","\6"		; Especial para EOR,ADDX,SUBX
	\1	(A4),\2
	ELSEIF
	MOVE.B	(A4),D1
	IFC	"C","\6"		; Actualiza Flag C
	LSR.B	#1,D3
	OR.B	#$04,CCR
	ENDC
	\1	D1,\2
	ENDC
	UpdateFlags	\5			; Recoge Flags.
	NextOP	\7
	ENDC

	ENDM

; --------------------------------------------
; --------------------------------------------

MROT:	MACRO

	IFC	"ra","\4"
	IFC	"C","\5"		; Actualiza Flag C
	LSR.B	#1,D3
	ENDC
	\1	\3,\2
	MOVE.W	CCR,D3
	NextOP	\6
	ENDC

	IFC	"ab","\4"
	MOVE.W	(A5)+,D1
;ius2
	ROR.W	#8,D1
	IFNC	"nn","\2"
	ADD.W	\2,D1
	ENDC
	CalPagE	D1,A4
	IFEQ	NO_RMWIO
	TST.B	D1			; I/O page: read and write through the I/O handlers
	BEQ	\@io
	ENDC
	MOVE.B	(A4),D2
	IFC	"C","\5"		; Actualiza Flag C
	LSR.B	#1,D3
	ENDC
	\1	\3,D2
	MOVE.W	CCR,D3
	MOVE.B	D2,(A4)
	NextOP	\6
	IFEQ	NO_RMWIO
\@io:	BSR	ReadIO
	MOVE.B	(A4),D2
	IFC	"C","\5"
	LSR.B	#1,D3
	ENDC
	\1	\3,D2
	MOVE.W	CCR,D3
	MOVE.B	D2,(A4)
	BSR	WriteIO
	NextOP	\6
	ENDC
	ENDC

	IFC	"zp","\4"
	MOVEQ	#0,D1
	MOVE.B	(A5)+,D1
;ius2
	IFNC	"nn","\2"
	ADD.B	\2,D1
	ENDC
	LEA	(IRAM,D1.L),A4
	MOVE.B	(A4),D2
	IFC	"C","\5"		; Actualiza Flag C
	LSR.B	#1,D3
	ENDC
	\1	\3,D2
	MOVE.W	CCR,D3
	MOVE.B	D2,(A4)
	NextOP	\6
	ENDC

	ENDM

; --------------------------------------------
; --------------------------------------------

MSET:	MACRO

	IFC	"ab","\4"
	MOVE.W	(A5)+,D1
;ius2
	ROR.W	#8,D1
	IFNC	"nn","\2"
	ADD.W	\2,D1
	ENDC
	CalPagE	D1,A4
	\1	\3,(A4)
	CheckWriteIO
	NextOP	\5
	ENDC


	IFC	"zp","\4"
	MOVEQ	#0,D1
	MOVE.B	(A5)+,D1
;ius2
	IFNC	"nn","\2"
	ADD.B	\2,D1
	ENDC

	\1	\3,(IRAM,D1.L)
	NextOP	\5
	ENDC


	IFC	"im","\4"
	MOVEQ	#0,D1
	MOVE.B	(A5)+,D1
;ius2
	MOVE.W	(IRAM,D1.L),D1
	ROR.W	#8,D1
	CalPagE	D1,A4
	\1	\3,(A4)
	CheckWriteIO
	NextOP	\5
	ENDC


	IFC	"iy","\4"		; STA  ($03),Y
	MOVEQ	#0,D1
	MOVE.B	(A5)+,D1
;ius
	MOVE.W	(IRAM,D1.L),D1
	ROR.W	#8,D1
	ADD.W	\2,D1
	CalPagE	D1,A4
	\1	\3,(A4)
	CheckWriteIO
	NextOP	\5
	ENDC


	IFC	"ix","\4"		; STA  ($03,X)
	MOVEQ	#0,D1
	MOVE.B	(A5)+,D1
;ius
	ADD.B	\2,D1
	MOVE.W	(IRAM,D1.L),D1
	ROR.W	#8,D1
	CalPagE	D1,A4
	\1	\3,(A4)
	CheckWriteIO
	NextOP	\5
	ENDC

	ENDM

; --------------------------------------------
; --------------------------------------------

MSuma:	MACRO

	MOVE.B	D3,D2			; Guarda Flag C

	IFC	"ab","\4"
	MOVE.W	(A5)+,D1
;ius2
	ROR.W	#8,D1
	IFNC	"nn","\2"
	ADD.W	\2,D1
	ENDC
	CalPagE	D1,A4
	IFEQ	NO_RMWIO
	TST.B	D1			; I/O page: read and write through the I/O handlers
	BEQ	\@io
	ENDC

	\1	\3,(A4)
	UpdateFlags NxZx
	NextOP	\5
	IFEQ	NO_RMWIO
\@io:	BSR	ReadIO
	\1	\3,(A4)
	UpdateFlags NxZx
	BSR	WriteIO
	NextOP	\5
	ENDC
	ENDC

	IFC	"zp","\4"
	MOVEQ	#0,D1
	MOVE.B	(A5)+,D1
;ius
	IFNC	"nn","\2"
	ADD.B	\2,D1
	ENDC

	\1	\3,(IRAM,D1.L)
	UpdateFlags NxZx
	NextOP	\5
	ENDC

	ENDM

; --------------------------------------------
; --------------------------------------------

MiBccs:	MACRO
	IFNC	"nn","\1"
	B\1.S	\@MiBccs
	ADDQ.W	#1,A5
	NextOP	\2
	ENDC
\@MiBccs:
	MOVE.B	(A5)+,D1
	IFEQ	NO_IDLESKIP
	IFNC	"\3",""
	CMP.B	#\3,D1			; branch onto itself: nothing can change before the next line
	BNE.S	\@NoIdle
	IFEQ	NO_CYCREG
	AND.L	#$0000FFFF,D2		; no cycles left: end this line now (same end state)
	ELSE
	CLR.W	(A3)			; Cycles(A3): end this line now (same end state)
	ENDC
\@NoIdle:
	ENDC
	ENDC
	IFEQ	NO_POLLSKIP
	IFNC	"\4",""
	CMP.B	#-6,D1			; back by 5 or 4 (or less): maybe a polling loop
	BHI.S	\@Poll
\@Back:
	ENDC
	ENDC
	EXT.W	D1
	ADD.W	D1,A5
	NextOP	\2
	IFEQ	NO_POLLSKIP
	IFNC	"\4",""
; Polling loop: LDA/CMP zp (or abs, not in MPR slot 0) then this branch back onto it.
; If the branch would be taken again after that load/compare, every pass is the same
; (only the CPU can change memory within a line), so whole passes are dropped from the
; cycles left: R-2 -> (R-2) mod pass. The last pass(es) then run as normal, so the end
; state (PC, A, flags, D0/D1, cycles over) is the same as running them all.
\@Poll:
	MOVE.L	D0,A0			; D0 is kept as it was
	CMP.B	#-4,D1
	BNE.S	\@Abs
	MOVEQ	#0,D0
	MOVE.B	-3(A5),D0		; zp operand
	LEA	(IRAM,D0.L),A1
	MOVEQ	#4+\2,D0		; cycles per pass
	CMP.B	#$A5,-4(A5)		; LDA zp
	BEQ.S	\@Lda
	CMP.B	#$C5,-4(A5)		; CMP zp
	BEQ.S	\@Cmp
\@No:
	MOVE.L	A0,D0
	BRA	\@Back
\@Abs:
	CMP.B	#-5,D1
	BNE.S	\@No
	MOVEQ	#0,D0
	MOVE.B	-3(A5),D0
	LSL.W	#8,D0
	MOVE.B	-4(A5),D0		; abs operand
	MOVE.L	D0,A1
	BFEXTU	D0{16:3},D0		; MPR slot
	BEQ.S	\@No			; slot 0: I/O page possible
	ADD.L	PagRead(A3,D0.W*4),A1
	MOVEQ	#5+\2,D0		; cycles per pass
	CMP.B	#$AD,-5(A5)		; LDA abs
	BEQ.S	\@Lda
	CMP.B	#$CD,-5(A5)		; CMP abs
	BNE.S	\@No
\@Cmp:
	CMP.B	(A1),D7			; N,Z as CMP sets them
	B\1.S	\@Spin
	BRA.S	\@No
\@Lda:
	TST.B	(A1)			; N,Z as LDA sets them
	B\1.S	\@Spin
	BRA.S	\@No
\@Spin:
	MOVE.W	D0,-(SP)		; cycles per pass
	MOVEQ	#0,D0
	IFEQ	NO_CYCREG
	SWAP	D2
	MOVE.W	D2,D0
	ELSE
	MOVE.W	(A3),D0			; Cycles(A3)
	ENDC
	SUBQ.W	#\2,D0			; cycles left after this branch
	BCS.S	\@Over			; line ends on this branch anyway
	DIVU.W	(SP),D0
	SWAP	D0			; remainder: cycles of the last part pass
	ADDQ.W	#\2,D0
	IFEQ	NO_CYCREG
	MOVE.W	D0,D2
\@Over:
	SWAP	D2
	ELSE
	MOVE.W	D0,(A3)			; Cycles(A3)
\@Over:
	ENDC
	ADDQ.L	#2,SP
	BRA.S	\@No
	CNOP	0,8
	ENDC
	ENDC
	ENDM

; --------------------------------------------
; --------------------------------------------

BITxx:	MACRO
	MOVE.B	D3,D2			; Guarda Flag C

	IFC	"in","\3"
	MOVE.L	A5,A4
	ADDQ	#1,A5
	ENDC

	IFC	"zp","\3"
	MOVEQ	#0,D1
	MOVE.B	(A5)+,D1
	IFNC	"nn","\2"
	ADD.B	\2,D1
	ENDC
	LEA	(IRAM,D1.L),A4
	ENDC

	IFC	"ab","\3"
	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	IFNC	"nn","\2"
	ADD.W	\2,D1
	ENDC
	CalPag	D1,A4
	IFEQ	NO_RMWIO
	CheckReadIO			; BIT on the I/O page reads through the handler
	ENDC
	ENDC

	MOVE.B	D7,D1
	AND.B	\1,D1
	MOVE.W	CCR,D3
	BFINS	D2,D3{31:1}

	AND.B	#$F7,D3
	MOVE.B	\1,D1
	BPL.S	\@BITCon
	OR.B	#$08,D3
\@BITCon:
	LSL.B	#1,D1
	SMI	VFF(A3)

	NextOP	\4

	ENDM

; --------------------------------------------
; --------------------------------------------

Test:	MACRO
	IFEQ	NO_TSBTRB
; TSB/TRB/TST: N and V from the memory byte before the operation, Z from the result
; (TSB/TRB: the byte written; TST: imm AND M), as Mesen. Absolute addresses in the
; I/O page go through ReadIO (and WriteIO for TSB/TRB).
	MOVE.B	D3,D2			; Guarda Flag C
	IFC	"D0","\2"
	MOVE.B	(A5)+,D0
	ENDC
	IFC	"zp","\4"
	MOVEQ	#0,D1
	MOVE.B	(A5)+,D1
	IFNC	"nn","\3"
	ADD.B	\3,D1
	ENDC
	LEA	(IRAM,D1.L),A4
	TestOp	\1,\2,\6
	NextOP	\5
	ENDC
	IFC	"ab","\4"
	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	IFNC	"nn","\3"
	ADD.W	\3,D1
	ENDC
	CalPagE	D1,A4
	TST.B	D1
	BEQ	\@io
	TestOp	\1,\2,\6
	NextOP	\5
\@io:
	IFC	"D0","\2"
	MOVE.W	D0,-(SP)
	BSR	ReadIO
	MOVE.W	(SP)+,D0
	ELSEIF
	BSR	ReadIO
	ENDC
	TestOp	\1,\2,\6
	IFNC	"D0","\2"
	BSR	WriteIO
	ENDC
	NextOP	\5
	ENDC
	ELSE
	MOVE.B	D3,D2			; Guarda Flag C

	IFC	"D0","\2"
	MOVE.B	(A5)+,D0
	ENDC

	IFC	"zp","\4"
	MOVEQ	#0,D1
	MOVE.B	(A5)+,D1
	IFNC	"nn","\3"
	ADD.B	\3,D1
	ENDC
	LEA	(IRAM,D1.L),A4
	ENDC

	IFC	"ab","\4"
	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	IFNC	"nn","\3"
	ADD.W	\3,D1
	ENDC
	CalPagE	D1,A4
	ENDC

	IFC	"NOT","\6"
	NOT.B	D7
	ENDC

	IFC	"D0","\2"
	\1	(A4),D0
	ELSEIF
	\1	\2,(A4)
	ENDC

	IFC	"NOT","\6"
	NOT.B	D7
	ENDC

	MOVE.W	CCR,D3
	BFINS	D2,D3{31:1}
	AND.B	#$F7,D3
	MOVE.B	\2,D1
	BPL.S	\@TestCon
	OR.B	#$08,D3
\@TestCon:
	LSL.B	#1,D1
	SMI	VFF(A3)

	NextOP	\5

	ENDC
	ENDM

TestOp:	MACRO				; \1 AND/OR, \2 D7 (TSB/TRB) or D0 (TST imm), \3 NOT = TRB
	MOVE.B	(A4),D1			; M before
	IFC	"D0","\2"
	AND.B	D1,D0
	ELSEIF
	IFC	"NOT","\3"
	MOVE.B	D7,D0
	NOT.B	D0
	AND.B	D0,(A4)
	ELSEIF
	OR.B	D7,(A4)
	ENDC
	ENDC
	MOVE.W	CCR,D3
	BFINS	D2,D3{31:1}
	AND.B	#$F7,D3
	TST.B	D1
	BPL.S	\@p
	OR.B	#$08,D3
\@p:	LSL.B	#1,D1
	SMI	VFF(A3)
	ENDM

; --------------------------------------------
; --------------------------------------------

xMBi:	MACRO
	MOVEQ	#0,D1
	MOVE.B	(A5)+,D1
	\1	#\2,(IRAM,D1.L)
	NextOP	\3
	ENDM

; --------------------------------------------
; --------------------------------------------

BSSi:	MACRO
	MOVEQ	#0,D1
	MOVE.B	(A5)+,D1
	BTST	#\1,(IRAM,D1.L)
	MiBccs	\2,\3,-3
	ENDM

; --------------------------------------------
; --------------------------------------------
; --------------------------------------------



;	-=====================-
;	 Emulación de códigos
;	-=====================-

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

Bucle:	NextOP	1

JAMnn:	NextOP	2

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

CLAnn:	SF	D7
	NextOP	2
CLXnn:	SF	D4
	NextOP	2
CLYnn:	SF	D5
	NextOP	2

SAXnn:	EXG.L	D4,D7
	NextOP	3
SAYnn:	EXG.L	D5,D7
	NextOP	3
SXYnn:	EXG.L	D4,D5
	NextOP	3

CSHnn:				; Speed Hight
	IFEQ	NO_CSL
	SF	CpuSlow
	ENDC
	NextOP	1
CSLnn:				; Speed Low
	IFEQ	NO_CSL
	ST	CpuSlow
	ENDC
	NextOP	1
	IFEQ	NO_CSL
CpuSlow:	DC.B	0,0		; CSL: 1.79 MHz, a quarter of the cycles per line
	ENDC

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

ADCin:	MIns	ADDX.B,D7,vv,in,NVZC,C,2
ADCab:	MIns	ADDX.B,D7,nn,ab,NVZC,C,5
ADCax:	MIns	ADDX.B,D7,D4,ab,NVZC,C,5
ADCay:	MIns	ADDX.B,D7,D5,ab,NVZC,C,5
ADCzp:	MIns	ADDX.B,D7,nn,zp,NVZC,C,4
ADCzx:	MIns	ADDX.B,D7,D4,zp,NVZC,C,4
;ADCzy:	MIns	ADDX.B,D7,D5,zp,NVZC,C		; NO ESTA EN EL 6510
ADCix:	MIns	ADDX.B,D7,D4,ix,NVZC,C,7
ADCiy:	MIns	ADDX.B,D7,D5,iy,NVZC,C,7
ADCim:	MIns	ADDX.B,D7,im,zp,NVZC,C,7

SBCin:	NOT.B	D3
	MIns	SUBX.B,D7,vv,in,NVZn,C,2
SBCab:	NOT.B	D3
	MIns	SUBX.B,D7,nn,ab,NVZn,C,5
SBCax:	NOT.B	D3
	MIns	SUBX.B,D7,D4,ab,NVZn,C,5
SBCay:	NOT.B	D3
	MIns	SUBX.B,D7,D5,ab,NVZn,C,5
SBCzp:	NOT.B	D3
	MIns	SUBX.B,D7,nn,zp,NVZn,C,4
SBCzx:	NOT.B	D3
	MIns	SUBX.B,D7,D4,zp,NVZn,C,4
;SBCzy:	NOT.B	D3
;	MIns	SUBX.B,D7,D5,zp,NVZn,C		; NO ESTA EN EL 6510
SBCix:	NOT.B	D3
	MIns	SUBX.B,D7,D4,ix,NVZn,C,7
SBCiy:	NOT.B	D3
	MIns	SUBX.B,D7,D5,iy,NVZn,C,7
SBCim:	NOT.B	D3
	MIns	SUBX.B,D7,im,zp,NVZn,C,7

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

ANDin:	MIns	AND.B,D7,vv,in,NxZx,N,2
ANDab:	MIns	AND.B,D7,nn,ab,NxZx,N,5
ANDax:	MIns	AND.B,D7,D4,ab,NxZx,N,5
ANDay:	MIns	AND.B,D7,D5,ab,NxZx,N,5
ANDzp:	MIns	AND.B,D7,nn,zp,NxZx,N,4
ANDzx:	MIns	AND.B,D7,D4,zp,NxZx,N,4
;ANDzy:	MIns	AND.B,D7,D5,zp,NxZx,N		; NO ESTA EN EL 6510
ANDix:	MIns	AND.B,D7,D4,ix,NxZx,N,7
ANDiy:	MIns	AND.B,D7,D5,iy,NxZx,N,7
ANDim:	MIns	AND.B,D7,im,zp,NxZx,N,7

ORAin:	MIns	OR.B,D7,vv,in,NxZx,N,2
ORAab:	MIns	OR.B,D7,nn,ab,NxZx,N,5
ORAax:	MIns	OR.B,D7,D4,ab,NxZx,N,5
ORAay:	MIns	OR.B,D7,D5,ab,NxZx,N,5
ORAzp:	MIns	OR.B,D7,nn,zp,NxZx,N,4
ORAzx:	MIns	OR.B,D7,D4,zp,NxZx,N,4
;ORAzy:	MIns	OR.B,D7,D5,zp,NxZx,N		; NO ESTA EN EL 6510
ORAix:	MIns	OR.B,D7,D4,ix,NxZx,N,7
ORAiy:	MIns	OR.B,D7,D5,iy,NxZx,N,7
ORAim:	MIns	OR.B,D7,im,zp,NxZx,N,7

EORin:	MIns	EOR.B,D7,vv,in,NxZx,E,2
EORab:	MIns	EOR.B,D7,nn,ab,NxZx,E,5
EORax:	MIns	EOR.B,D7,D4,ab,NxZx,E,5
EORay:	MIns	EOR.B,D7,D5,ab,NxZx,E,5
EORzp:	MIns	EOR.B,D7,nn,zp,NxZx,E,4
EORzx:	MIns	EOR.B,D7,D4,zp,NxZx,E,4
;EORzy:	MIns	EOR.B,D7,D5,zp,NxZx,E		; NO ESTA EN EL 6510
EORix:	MIns	EOR.B,D7,D4,ix,NxZx,E,7
EORiy:	MIns	EOR.B,D7,D5,iy,NxZx,E,7
EORim:	MIns	EOR.B,D7,im,zp,NxZx,E,7

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

ASLra:	MROT	ASL.B,D7,#1,ra,N,2
ASLab:	MROT	ASL.B,nn,#1,ab,N,7
ASLax:	MROT	ASL.B,D4,#1,ab,N,7
ASLzp:	MROT	ASL.B,nn,#1,zp,N,6
ASLzx:	MROT	ASL.B,D4,#1,zp,N,6

LSRra:	MROT	LSR.B,D7,#1,ra,N,2
LSRab:	MROT	LSR.B,nn,#1,ab,N,7
LSRax:	MROT	LSR.B,D4,#1,ab,N,7
LSRzp:	MROT	LSR.B,nn,#1,zp,N,6
LSRzx:	MROT	LSR.B,D4,#1,zp,N,6

ROLra:	MROT	ROXL.B,D7,#1,ra,C,2
ROLab:	MROT	ROXL.B,nn,#1,ab,C,7
ROLax:	MROT	ROXL.B,D4,#1,ab,C,7
ROLzp:	MROT	ROXL.B,nn,#1,zp,C,6
ROLzx:	MROT	ROXL.B,D4,#1,zp,C,6

RORra:	MROT	ROXR.B,D7,#1,ra,C,2
RORab:	MROT	ROXR.B,nn,#1,ab,C,7
RORax:	MROT	ROXR.B,D4,#1,ab,C,7
RORzp:	MROT	ROXR.B,nn,#1,zp,C,6
RORzx:	MROT	ROXR.B,D4,#1,zp,C,6

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

LDAin:	MIns	MOVE.B,D7,vv,in,NxZx,N,2
LDXin:	MIns	MOVE.B,D4,vv,in,NxZx,N,2
LDYin:	MIns	MOVE.B,D5,vv,in,NxZx,N,2

LDAab:	MIns	MOVE.B,D7,nn,ab,NxZx,N,5
LDXab:	MIns	MOVE.B,D4,nn,ab,NxZx,N,5
LDYab:	MIns	MOVE.B,D5,nn,ab,NxZx,N,5

LDAax:	MIns	MOVE.B,D7,D4,ab,NxZx,N,5
;LDXax:	MIns	MOVE.B,D4,D4,ab,NxZx,N
LDYax:	MIns	MOVE.B,D5,D4,ab,NxZx,N,5

LDAay:	MIns	MOVE.B,D7,D5,ab,NxZx,N,5
LDXay:	MIns	MOVE.B,D4,D5,ab,NxZx,N,5
;LDYay:	MIns	MOVE.B,D5,D5,ab,NxZx,N

LDAzp:	MIns	MOVE.B,D7,nn,zp,NxZx,N,4
LDXzp:	MIns	MOVE.B,D4,nn,zp,NxZx,N,4
LDYzp:	MIns	MOVE.B,D5,nn,zp,NxZx,N,4

LDAzx:	MIns	MOVE.B,D7,D4,zp,NxZx,N,4
;LDXzx:	MIns	MOVE.B,D4,D4,zp,NxZx,N
LDYzx:	MIns	MOVE.B,D5,D4,zp,NxZx,N,4

;LDAzy:	MIns	MOVE.B,D7,D5,zp,NxZx,N
LDXzy:	MIns	MOVE.B,D4,D5,zp,NxZx,N,4
;LDYzy:	MIns	MOVE.B,D5,D5,zp,NxZx,N

LDAix:	MIns	MOVE.B,D7,D4,ix,NxZx,N,7
;LDXix:	MIns	MOVE.B,D4,D4,ix,NxZx,N
;LDYix:	MIns	MOVE.B,D5,D4,ix,NxZx,N

LDAiy:	MIns	MOVE.B,D7,D5,iy,NxZx,N,7
;LDXiy:	MIns	MOVE.B,D4,D5,iy,NxZx,N
;LDYiy:	MIns	MOVE.B,D5,D5,iy,NxZx,N

LDAim:	MIns	MOVE.B,D7,im,zp,NxZx,N,7
;LDXim:	MIns	MOVE.B,D4,im,zp,NxZx,N
;LDYim:	MIns	MOVE.B,D5,im,zp,NxZx,N

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

STAab:	MSET	MOVE.B,nn,D7,ab,5
STAax:	MSET	MOVE.B,D4,D7,ab,5
STAay:	MSET	MOVE.B,D5,D7,ab,5
STAzp:	MSET	MOVE.B,nn,D7,zp,4
STAzx:	MSET	MOVE.B,D4,D7,zp,4
;STAzy:	MSET	MOVE.B,D5,D7,zp		; NO ESTA EN EL 6510
STAix:	MSET	MOVE.B,D4,D7,ix,7
STAiy:	MSET	MOVE.B,D5,D7,iy,7
STAim:	MSET	MOVE.B,im,D7,im,7

STXab:	MSET	MOVE.B,nn,D4,ab,5
STXzp:	MSET	MOVE.B,nn,D4,zp,4
STXzy:	MSET	MOVE.B,D5,D4,zp,4

STYab:	MSET	MOVE.B,nn,D5,ab,5
STYzp:	MSET	MOVE.B,nn,D5,zp,4
STYzx:	MSET	MOVE.B,D4,D5,zp,4

STZab:	MSET	MOVE.B,nn,#0,ab,5
STZax:	MSET	MOVE.B,D4,#0,ab,5
STZzp:	MSET	MOVE.B,nn,#0,zp,4
STZzx:	MSET	MOVE.B,D4,#0,zp,4

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

CMPin:	MIns	CMP.B,D7,vv,in,NxZC,N,2
CPXin:	MIns	CMP.B,D4,vv,in,NxZC,N,2
CPYin:	MIns	CMP.B,D5,vv,in,NxZC,N,2

CMPab:	MIns	CMP.B,D7,nn,ab,NxZC,N,5
CPXab:	MIns	CMP.B,D4,nn,ab,NxZC,N,5
CPYab:	MIns	CMP.B,D5,nn,ab,NxZC,N,5

CMPax:	MIns	CMP.B,D7,D4,ab,NxZC,N,5
;CPXax:	MIns	CMP.B,D4,D4,ab,NxZC,N
;CPYax:	MIns	CMP.B,D5,D4,ab,NxZC,N

CMPay:	MIns	CMP.B,D7,D5,ab,NxZC,N,5
;CPXay:	MIns	CMP.B,D4,D5,ab,NxZC,N
;CPYay:	MIns	CMP.B,D5,D5,ab,NxZC,N

CMPzp:	MIns	CMP.B,D7,nn,zp,NxZC,N,4
CPXzp:	MIns	CMP.B,D4,nn,zp,NxZC,N,4
CPYzp:	MIns	CMP.B,D5,nn,zp,NxZC,N,4

CMPzx:	MIns	CMP.B,D7,D4,zp,NxZC,N,4
;CPXzx:	MIns	CMP.B,D4,D4,zp,NxZC,N
;CPYzx:	MIns	CMP.B,D5,D4,zp,NxZC,N

;CMPzy:	MIns	CMP.B,D7,D5,zp,NxZC,N
;CPXzy:	MIns	CMP.B,D4,D5,zp,NxZC,N
;CPYzy:	MIns	CMP.B,D5,D5,zp,NxZC,N

CMPix:	MIns	CMP.B,D7,D4,ix,NxZC,N,7
;CPXix:	MIns	CMP.B,D4,D4,ix,NxZC,N
;CPYix:	MIns	CMP.B,D5,D4,ix,NxZC,N

CMPiy:	MIns	CMP.B,D7,D5,iy,NxZC,N,7
;CPXiy:	MIns	CMP.B,D4,D5,iy,NxZC,N
;CPYiy:	MIns	CMP.B,D5,D5,iy,NxZC,N

CMPim:	MIns	CMP.B,D7,im,zp,NxZC,N,7
;CPXim:	MIns	CMP.B,D4,im,zp,NxZC,N
;CPYim:	MIns	CMP.B,D5,im,zp,NxZC,N

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

BITin:	BITxx	(A4),nn,in,2
BITab:	BITxx	(A4),nn,ab,5
BITax:	BITxx	(A4),D4,ab,5
BITzp:	BITxx	(A4),nn,zp,4
BITzx:	BITxx	(A4),D4,zp,4

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

BRAnn:	MiBccs	nn,4,-2
BEQnn:	MOVE.W	D3,CCR
	MiBccs	EQ,2,,P
BNEnn:	MOVE.W	D3,CCR
	MiBccs	NE,2,,P
BPLnn:	MOVE.W	D3,CCR
	MiBccs	PL,2,,P
BMInn:	MOVE.W	D3,CCR
	MiBccs	MI,2,,P
BCSnn:	MOVE.W	D3,CCR
	MiBccs	CS,2
BCCnn:	MOVE.W	D3,CCR
	MiBccs	CC,2
BVSnn:	TST.B	VFF(A3)
	MiBccs	NE,2
BVCnn:	TST.B	VFF(A3)
	MiBccs	EQ,2

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


NOPnn:
	NextOP	2


BRKnn:
	MOVE.W	#$FFF6,D1
	ST	BFF(A3)
BRK_Interrupt:
	CalPag	D1,A4
	MOVE.W	(A4),D1
	ROR.W	#8,D1
	MOVE.L	A5,A4
	SUB.W	(A2),A4
	CalPag	D1,A5
	LEA	Restas(A3,D1.W*8),A2

	MOVE.W	A4,D1
	ROR.W	#8,D1
	SUBQ.B	#1,D6
	CalStak	D6,A6
	MOVE.B	D1,(A6)

	ROR.W	#8,D1
	SUBQ.B	#1,D6
	CalStak	D6,A6
	MOVE.B	D1,(A6)
;	-----------------------------------
	MOVE.B	D3,D1
	AND.W	#$000D,D1
	LEA	VFF(A3),A4
	AND.L	#$02402090,(A4)+
	OR.B	-(A4),D1
	OR.B	-(A4),D1
	OR.B	-(A4),D1
	OR.B	-(A4),D1
	SUBQ.B	#1,D6
	CalStak	D6,A6
	MOVE.B	(Flags_Push.w,PC,D1.W),(A6)
;	-----------------------------------
	NextOP	8


JMPab:	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	IFEQ	NO_IDLESKIP
	MOVE.L	A5,D0
	SUBQ.L	#3,D0
	SUB.W	(A2),D0			; logical address of this JMP
	CMP.W	D1,D0
	BNE.S	.notIdle
	IFEQ	NO_CYCREG
	AND.L	#$0000FFFF,D2		; JMP onto itself: end this line now (same end state)
	ELSE
	CLR.W	(A3)			; JMP onto itself: end this line now (same end state)
	ENDC
.notIdle:
	ENDC
	CalPag	D1,A5
	LEA	Restas(A3,D1.W*8),A2
	NextOP	4


JMPax:	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	ADD.W	D4,D1
	CalPag	D1,A4
	MOVE.W	(A4),D1
	ROR.W	#8,D1
	CalPag	D1,A5
	LEA	Restas(A3,D1.W*8),A2
	NextOP	7


JMPid:	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	CalPag	D1,A4
	MOVE.W	(A4),D1
	ROR.W	#8,D1
	CalPag	D1,A5
	LEA	Restas(A3,D1.W*8),A2
	NextOP	7


JSRnn:	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	MOVE.L	A5,A4
	SUB.W	(A2),A4
	CalPag	D1,A5
	LEA	Restas(A3,D1.W*8),A2
	SUBQ.B	#2,D6
	BCS.S	JSRDesbor
	MOVE.W	A4,D1
	SUBQ.W	#1,D1
	ROR.W	#8,D1
	MOVE.W	D1,-(A6)
	NextOP	7
JSRDesbor:
	MOVE.W	D6,D1
	ADDQ.W	#1,D1
	CalStak	D1,A6
	MOVE.W	A4,D1
	SUBQ.W	#1,D1
	MOVE.B	D1,D2
	LSR.W	#8,D1
	MOVE.B	D1,(A6)
	CalStak	D6,A6
	MOVE.B	D2,(A6)
	NextOP	7


BSRnn:	MOVE.B	(A5)+,D1
	EXT.W	D1
	MOVE.L	A5,A4
	SUB.W	(A2),A4
	ADD.W	D1,A5
	SUBQ.B	#2,D6
	BCS.S	JSRDesbor
	MOVE.W	A4,D1
	SUBQ.W	#1,D1
	ROR.W	#8,D1
	MOVE.W	D1,-(A6)
	NextOP	8


RTSnn:
	MOVE.W	(A6)+,D1

	ADDQ.B	#2,D6
	BCS.S	RTSDesbor

	ROR.W	#8,D1
	ADDQ.W	#1,D1
	CalPag	D1,A5
	LEA	Restas(A3,D1.W*8),A2
	NextOP	7
RTSDesbor:
	CalStak	D6,A6
	MOVE.B	-1(A6),D1
	ROR.W	#8,D1
	ADDQ.W	#1,D1
	CalPag	D1,A5
	LEA	Restas(A3,D1.W*8),A2
	NextOP	7


RTInn:
	MOVE.B	(A6)+,D3
;	-----------------------------------
;;;	MOVE.L	(FlagVBDI.w,PC,D3.W*4),VFF(A3)

;	AND.B	#$C0,D3

	MOVE.B	D3,D2
	LSR.B	#3,D2
	SCS	IFF(A3)
	LSR.B	#1,D2
	SCS	DFF(A3)
	LSR.B	#1,D2
	SCS	BFF(A3)
	BFINS	D2,DFF(A3){0:1}
	LSR.B	#2,D2
	SCS	VFF(A3)

	MOVE.B	(Flags_Pop.w,PC,D3.W),D3
;	AND.B	#$0D,D3
;	-----------------------------------

	ADDQ.B	#3,D6
	BCS.S	RTISiDesb

	MOVE.W	(A6)+,D1
	ROR.W	#8,D1

	CalPag	D1,A5
	LEA	Restas(A3,D1.W*8),A2

;	BSR	CheckInterrupt
	IFEQ	NO_RTIIRQ
	BSR	CheckInterrupt		; I clear again: a pending IRQ is taken now, as on the 6280
	ENDC
	NextOP	7

RTISiDesb:
	CalStak	D6,A6

	SUBQ.B	#2,D6
	CalStak	D6,A4
	ADDQ.B	#2,D6

	MOVE.W	-1(A6),D1
	MOVE.B	(A4),D1

	CalPag	D1,A5
	LEA	Restas(A3,D1.W*8),A2

;	BSR	CheckInterrupt
	IFEQ	NO_RTIIRQ
	BSR	CheckInterrupt		; I clear again: a pending IRQ is taken now, as on the 6280
	ENDC
	NextOP	7

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

TXAnn:
	MOVE.B	D3,D2			; Guarda Flag C
	MOVE.B	D4,D7
	UpdateFlags NxZx
	NextOP	2

TAXnn:
	MOVE.B	D3,D2			; Guarda Flag C
	MOVE.B	D7,D4
	UpdateFlags NxZx
	NextOP	2

TYAnn:
	MOVE.B	D3,D2			; Guarda Flag C
	MOVE.B	D5,D7
	UpdateFlags NxZx
	NextOP	2

TAYnn:
	MOVE.B	D3,D2			; Guarda Flag C
	MOVE.B	D7,D5
	UpdateFlags NxZx
	NextOP	2

TSXnn:
	MOVE.B	D3,D2			; Guarda Flag C
	MOVE.B	D6,D4
	UpdateFlags NxZx
	NextOP	2

TXSnn:
	MOVE.B	D4,D6
	CalStak	D6,A6
	NextOP	2

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

PHPnn:
	MOVE.B	D3,D1
	AND.W	#$000D,D1
	LEA	VFF(A3),A4
	AND.L	#$02402090,(A4)+
	OR.B	-(A4),D1
	OR.B	-(A4),D1
	OR.B	-(A4),D1
	OR.B	-(A4),D1
	SUBQ.B	#1,D6
	BCS.S	PHPDesbor
	MOVE.B	(Flags_Push.w,PC,D1.W),-(A6)
	NextOP	3

PHPDesbor:
	CalStak	D6,A6
	MOVE.B	(Flags_Push.w,PC,D1.W),(A6)
	NextOP	3

Flags_Push:	DS.B	256


PHAnn:
	SUBQ.B	#1,D6
	BCS.S	PHADesbor
	MOVE.B	D7,-(A6)
	NextOP	3
PHADesbor:
	CalStak	D6,A6
	MOVE.B	D7,(A6)
	NextOP	3

PHXnn:
	SUBQ.B	#1,D6
	BCS.S	PHXDesbor
	MOVE.B	D4,-(A6)
	NextOP	3
PHXDesbor:
	CalStak	D6,A6
	MOVE.B	D4,(A6)
	NextOP	3

PHYnn:
	SUBQ.B	#1,D6
	BCS.S	PHYDesbor
	MOVE.B	D5,-(A6)
	NextOP	3
PHYDesbor:
	CalStak	D6,A6
	MOVE.B	D5,(A6)
	NextOP	3

PLPnn:
	MOVE.B	(A6)+,D3
;;;	MOVE.L	(FlagVBDI.w,PC,D3.W*4),VFF(A3)

	MOVE.B	D3,D2
	LSR.B	#3,D2
	SCS	IFF(A3)
	LSR.B	#1,D2
	SCS	DFF(A3)
	LSR.B	#1,D2
	SCS	BFF(A3)
	BFINS	D2,DFF(A3){0:1}
	LSR.B	#2,D2
	SCS	VFF(A3)

	MOVE.B	(Flags_Pop.w,PC,D3.W),D3
	AND.B	#$0D,D3

	ADDQ.B	#1,D6
	BCS.S	PLPDesbor
	NextOP	3
PLPDesbor:
	CalStak	D6,A6
	NextOP	3

Flags_Pop:	DS.B	256
Flags_VBDI:	DS.L	256

PLAnn:
	MOVE.B	D3,D2			; Guarda Flag C
	ADDQ.B	#1,D6
	BCS.S	PLADesbor
	MOVE.B	(A6)+,D7
	UpdateFlags NxZx
	NextOP	3
PLADesbor:
	MOVE.L	A6,A4
	CalStak	D6,A6
	MOVE.B	(A4),D7
	UpdateFlags NxZx
	NextOP	3

PLXnn:
	MOVE.B	D3,D2			; Guarda Flag C
	ADDQ.B	#1,D6
	BCS.S	PLXDesbor
	MOVE.B	(A6)+,D4
	UpdateFlags NxZx
	NextOP	3
PLXDesbor:
	MOVE.L	A6,A4
	CalStak	D6,A6
	MOVE.B	(A4),D4
	UpdateFlags NxZx
	NextOP	3

PLYnn:
	MOVE.B	D3,D2			; Guarda Flag C
	ADDQ.B	#1,D6
	BCS.S	PLYDesbor
	MOVE.B	(A6)+,D5
	UpdateFlags NxZx
	NextOP	3
PLYDesbor:
	MOVE.L	A6,A4
	CalStak	D6,A6
	MOVE.B	(A4),D5
	UpdateFlags NxZx
	NextOP	3

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

CLCnn:
	BCLR	#0,D3
	NextOP	2
SECnn:
	BSET	#0,D3
	NextOP	2
CLInn:
	SF	IFF(A3)
	BSR	CheckInterrupt
	NextOP	2
SEInn:
	ST	IFF(A3)
	NextOP	2
CLVnn:
	SF	VFF(A3)
	NextOP	2
CLDnn:
	AND.B	#$7F,DFF(A3)
	NextOP	2
SEDnn:
	OR.B	#$7F,DFF(A3)
	NextOP	2

SETnn:
	NextOP	2

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

INCab:	MSuma	ADDQ.B,nn,#1,ab,7
INCax:	MSuma	ADDQ.B,D4,#1,ab,7
INCzp:	MSuma	ADDQ.B,nn,#1,zp,6
INCzx:	MSuma	ADDQ.B,D4,#1,zp,6

DECab:	MSuma	SUBQ.B,nn,#1,ab,7
DECax:	MSuma	SUBQ.B,D4,#1,ab,7
DECzp:	MSuma	SUBQ.B,nn,#1,zp,6
DECzx:	MSuma	SUBQ.B,D4,#1,zp,6

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

DECra:
	MOVE.B	D3,D2			; Guarda Flag C
	SUBQ.B	#1,D7
	UpdateFlags NxZx
	NextOP	2

INCra:
	MOVE.B	D3,D2			; Guarda Flag C
	ADDQ.B	#1,D7
	UpdateFlags NxZx
	NextOP	2

DEYnn:
	MOVE.B	D3,D2			; Guarda Flag C
	SUBQ.B	#1,D5
	UpdateFlags NxZx
	NextOP	2

INYnn:
	MOVE.B	D3,D2			; Guarda Flag C
	ADDQ.B	#1,D5
	UpdateFlags NxZx
	NextOP	2

DEXnn:
	MOVE.B	D3,D2			; Guarda Flag C
	SUBQ.B	#1,D4
	UpdateFlags NxZx
	NextOP	2

INXnn:
	MOVE.B	D3,D2			; Guarda Flag C
	ADDQ.B	#1,D4
	UpdateFlags NxZx
	NextOP	2

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

TRBzp:	Test	AND.B,D7,nn,zp,6,NOT
TRBab:	Test	AND.B,D7,nn,ab,7,NOT
TSBzp:	Test	OR.B,D7,nn,zp,6,OK
TSBab:	Test	OR.B,D7,nn,ab,7,OK
TSTzp:	Test	AND.B,D0,nn,zp,7,OK
TSTzx:	Test	AND.B,D0,D4,zp,7,OK
TSTab:	Test	AND.B,D0,nn,ab,8,OK
TSTax:	Test	AND.B,D0,D4,ab,8,OK

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

RMB0:	xMBi	BCLR,0,7
RMB1:	xMBi	BCLR,1,7
RMB2:	xMBi	BCLR,2,7
RMB3:	xMBi	BCLR,3,7
RMB4:	xMBi	BCLR,4,7
RMB5:	xMBi	BCLR,5,7
RMB6:	xMBi	BCLR,6,7
RMB7:	xMBi	BCLR,7,7

SMB0:	xMBi	BSET,0,7
SMB1:	xMBi	BSET,1,7
SMB2:	xMBi	BSET,2,7
SMB3:	xMBi	BSET,3,7
SMB4:	xMBi	BSET,4,7
SMB5:	xMBi	BSET,5,7
SMB6:	xMBi	BSET,6,7
SMB7:	xMBi	BSET,7,7

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

BBR0:	BSSi	0,EQ,6
BBR1:	BSSi	1,EQ,6
BBR2:	BSSi	2,EQ,6
BBR3:	BSSi	3,EQ,6
BBR4:	BSSi	4,EQ,6
BBR5:	BSSi	5,EQ,6
BBR6:	BSSi	6,EQ,6
BBR7:	BSSi	7,EQ,6

BBS0:	BSSi	0,NE,6
BBS1:	BSSi	1,NE,6
BBS2:	BSSi	2,NE,6
BBS3:	BSSi	3,NE,6
BBS4:	BSSi	4,NE,6
BBS5:	BSSi	5,NE,6
BBS6:	BSSi	6,NE,6
BBS7:	BSSi	7,NE,6

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

ST0nn:
	MOVEQ	#0,D1
	CalPagE	D1,A4
	MOVE.B	(A5)+,(A4)
	CheckWriteIO
	NextOP	4
ST1nn:
	MOVEQ	#2,D1
	CalPagE	D1,A4
	MOVE.B	(A5)+,(A4)
	CheckWriteIO
	NextOP	4
ST2nn:
	MOVEQ	#3,D1
	CalPagE	D1,A4
	MOVE.B	(A5)+,(A4)
	CheckWriteIO
	NextOP	4

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

TAMnn:				; Escribe en mapper.
	MOVE.B	(A5)+,D2
	SUB.W	(A2),A5

	MOVEQ	#0,D1
	LSR.B	#1,D2
	BCC.S	TAMCon0
	BSR	SetMapper
TAMCon0:
	MOVEQ	#1,D1
	LSR.B	#1,D2
	BCC.S	TAMCon1
	BSR	SetMapper
TAMCon1:
	MOVEQ	#2,D1
	LSR.B	#1,D2
	BCC.S	TAMCon2
	BSR	SetMapper
TAMCon2:
	MOVEQ	#3,D1
	LSR.B	#1,D2
	BCC.S	TAMCon3
	BSR	SetMapper
TAMCon3:
	MOVEQ	#4,D1
	LSR.B	#1,D2
	BCC.S	TAMCon4
	BSR	SetMapper
TAMCon4:
	MOVEQ	#5,D1
	LSR.B	#1,D2
	BCC.S	TAMCon5
	BSR	SetMapper
TAMCon5:
	MOVEQ	#6,D1
	LSR.B	#1,D2
	BCC.S	TAMCon6
	BSR	SetMapper
TAMCon6:
	MOVEQ	#7,D1
	LSR.B	#1,D2
	BCC.S	TAMCon7
	BSR	SetMapper
TAMCon7:

	MOVEQ	#0,D1
	MOVE.W	A5,D1
	CalPag	D1,A5
	LEA	Restas(A3,D1.W*8),A2

	NextOP	5

TMAnn:				; Lee de mapper.
	MOVE.B	(A5)+,D2
	MOVEQ	#0,D1
	LSR.B	#1,D2
	BCS.S	TMACon
	MOVEQ	#1,D1
	LSR.B	#1,D2
	BCS.S	TMACon
	MOVEQ	#2,D1
	LSR.B	#1,D2
	BCS.S	TMACon
	MOVEQ	#3,D1
	LSR.B	#1,D2
	BCS.S	TMACon
	MOVEQ	#4,D1
	LSR.B	#1,D2
	BCS.S	TMACon
	MOVEQ	#5,D1
	LSR.B	#1,D2
	BCS.S	TMACon
	MOVEQ	#6,D1
	LSR.B	#1,D2
	BCS.S	TMACon
	MOVEQ	#7,D1
TMACon:
	BSR	GetMapper
	NextOP	4

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


TransIni:MACRO
	MOVE.W	D1,TnnCyclesCount(A3)
	ENDM

TransEnd:MACRO
	MOVEQ.L	#0,D1
	MOVE.W	TnnCyclesCount(A3),D1
	MULU	#6,D1
	ADD.L	#17,D1
	SWAP	D1
	TST.W	D1
	BEQ.S	\@NoDesbord
	IFEQ	NO_CYCREG
	AND.L	#$0000FFFF,D2		; no cycles left in this line
	ELSE
	CLR.W	(A3)			; Cycles(A3)
	ENDC
	MOVE.W	#17,D1
	SWAP	D1
\@NoDesbord:
	SWAP	D1
	NextOP	D1
	ENDM


	IFNE	NO_BLKFIX
TAInn:
	MOVE.W	(A5)+,D0
	ROR.W	#8,D0
	CalPag	D0,A4
	BNE.S	TAInnnoIO
	
	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	CalPagE	D1,A4

	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	TransIni
	SUBQ.W	#1,D1
TAIBuc2:
	MOVEM.W	D0-D1,-(SP)
	BSR	ReadIOtia
	MOVEM.W	(SP)+,D0-D1
	BCHG	#0,D0
	ADDQ.L	#1,A4
	DBF	D1,TAIBuc2
	TransEnd
	NextOP	17

	cnop	0,8
TAInnnoIO:	
	MOVE.B	(A4)+,D0
	SWAP	D0
	MOVE.B	(A4),D0
	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	CalPagE	D1,A4
	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	TransIni
	SUBQ.W	#1,D1
TAIBuc:
	SWAP	D0
	MOVE.B	D0,(A4)+
	DBF	D1,TAIBuc
	TransEnd
	NextOP	17


TIAnn:
	MOVEM.L	A0/D0/D4,-(SP)

	MOVEQ	#0,D0
	MOVE.W	(A5)+,D0
	ROR.W	#8,D0

	MOVEQ	#0,D4
	MOVE.W	(A5)+,D4
	ROR.W	#8,D4

	MOVE.W	(A5)+,D1
	ROR.W	#8,D1

	TransIni
	SUBQ.W	#1,D1
TIABuc:
	MOVE.W	D1,-(SP)
	CalPag	D0,A0
	CalPagE	D4,A4
	MOVE.B	(A0),(A4)
	MOVEM.L	A0/A4/D0/D1/D4,-(SP)
	BSR	WriteIO
	MOVEM.L	(SP)+,A0/A4/D0/D1/D4
	ADDQ.L	#1,D0
	BCHG	#0,D4
	MOVE.W	(SP)+,D1
	DBF	D1,TIABuc
	MOVEM.L	(SP)+,A0/D0/D4
	TransEnd
	NextOP	17



TIInn:
	MOVE.L	A0,D0
	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	CalPag	D1,A0
	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	CalPagE	D1,A4
	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	TransIni
	SUBQ.W	#1,D1
TIIBuc:
	MOVE.B	(A0)+,(A4)+
	DBF	D1,TIIBuc
	MOVE.L	D0,A0
	TransEnd
	NextOP	17


TDDnn:
	MOVE.L	A0,D0
	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	CalPag	D1,A0
	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	CalPagE	D1,A4
	MOVE.W	(A5)+,D1
	ROR.W	#8,D1
	TransIni
	SUBQ.W	#1,D1
	ADDQ.W	#1,A0
	ADDQ.W	#1,A4
TDDBuc:
	MOVE.B	-(A0),-(A4)
	DBF	D1,TDDBuc
	MOVE.L	D0,A0
	TransEnd
	NextOP	17


TINnn:
	MOVEM.L	A0/D0/D4,-(SP)

	MOVEQ	#0,D0
	MOVE.W	(A5)+,D0
	ROR.W	#8,D0

	MOVEQ	#0,D4
	MOVE.W	(A5)+,D4
	ROR.W	#8,D4

	MOVE.W	(A5)+,D1
	ROR.W	#8,D1

	TransIni
	SUBQ.W	#1,D1
TINBuc:
	MOVE.W	D1,-(SP)
	CalPag	D0,A0
	CalPagE	D4,A4
	MOVE.B	(A0),(A4)
	MOVEM.L	A0/A4/D0/D1/D4,-(SP)
	BSR	WriteIO
	MOVEM.L	(SP)+,A0/A4/D0/D1/D4
	ADDQ.L	#1,D0
	MOVE.W	(SP)+,D1
	DBF	D1,TINBuc
	MOVEM.L	(SP)+,A0/D0/D4
	TransEnd
	NextOP	17
	ELSE
; Block transfers as on the HuC6280: every byte through the MPR of its own
; logical address (16 bits, wrapping), source and destination in any page,
; the I/O page ($FF) read and written through ReadIO / WriteIO.
; TII, TDD between ordinary pages go page piece by page piece.
TIInn:	MOVEM.L	D3-D7/A0,-(SP)
	MOVEQ	#0,D7
	BRA.S	BlkGo
TDDnn:	MOVEM.L	D3-D7/A0,-(SP)
	MOVEQ	#1,D7
	BRA.S	BlkGo
TINnn:	MOVEM.L	D3-D7/A0,-(SP)
	MOVEQ	#2,D7
	BRA.S	BlkGo
TIAnn:	MOVEM.L	D3-D7/A0,-(SP)
	MOVEQ	#3,D7
	BRA.S	BlkGo
TAInn:	MOVEM.L	D3-D7/A0,-(SP)
	MOVEQ	#4,D7
BlkGo:	MOVEQ	#0,D3
	MOVE.W	(A5)+,D3
	ROR.W	#8,D3			; source
	MOVEQ	#0,D4
	MOVE.W	(A5)+,D4
	ROR.W	#8,D4			; destination
	MOVEQ	#0,D5
	MOVE.W	(A5)+,D5
	ROR.W	#8,D5			; length (0 = 65536)
	MOVE.W	D5,TnnCyclesCount(A3)
	BNE.S	.len
	MOVE.L	#$10000,D5
.len:	MOVEQ	#0,D6			; bit 0: second byte of an alternating pair
.loop:	CMP.B	#1,D7			; TII / TDD: a piece inside one page each
	BHI	.byte
	MOVE.W	D3,D0
	LSR.W	#8,D0
	LSR.W	#5,D0
	CMP.B	#$FF,TabMap(A3,D0.W)
	BEQ	.byte
	MOVE.L	PagRead(A3,D0.W*4),A0
	ADD.L	D3,A0
	MOVE.W	D4,D1
	LSR.W	#8,D1
	LSR.W	#5,D1
	CMP.B	#$FF,TabMap(A3,D1.W)
	BEQ	.byte
	MOVE.L	PagWrite(A3,D1.W*4),A4
	ADD.L	D4,A4
	MOVE.W	D3,D0
	MOVE.W	D4,D1
	AND.L	#$1FFF,D0
	AND.L	#$1FFF,D1
	TST.B	D7
	BNE.S	.dd
	NEG.L	D0			; bytes to the end of each page
	ADD.L	#$2000,D0
	NEG.L	D1
	ADD.L	#$2000,D1
	CMP.L	D1,D0
	BLS.S	.i1
	MOVE.L	D1,D0
.i1:	CMP.L	D5,D0
	BLS.S	.i2
	MOVE.L	D5,D0
.i2:	SUB.L	D0,D5
	ADD.W	D0,D3
	ADD.W	D0,D4
	SUBQ.W	#1,D0
.ii:	MOVE.B	(A0)+,(A4)+
	DBF	D0,.ii
	TST.L	D5
	BNE.S	.loop
	BRA	.done
.dd:	ADDQ.L	#1,D0			; bytes to the start of each page
	ADDQ.L	#1,D1
	CMP.L	D1,D0
	BLS.S	.d1
	MOVE.L	D1,D0
.d1:	CMP.L	D5,D0
	BLS.S	.d2
	MOVE.L	D5,D0
.d2:	SUB.L	D0,D5
	SUB.W	D0,D3
	SUB.W	D0,D4
	ADDQ.L	#1,A0
	ADDQ.L	#1,A4
	SUBQ.W	#1,D0
.ddl:	MOVE.B	-(A0),-(A4)
	DBF	D0,.ddl
	TST.L	D5
	BNE	.loop
	BRA	.done
; one byte, any mode
.byte:	MOVE.W	D3,D0
	CMP.B	#4,D7			; TAI: source, source+1, ...
	BNE.S	.bs
	ADD.W	D6,D0
.bs:	AND.L	#$FFFF,D0
	MOVE.W	D0,D1
	LSR.W	#8,D1
	LSR.W	#5,D1
	CMP.B	#$FF,TabMap(A3,D1.W)
	BEQ.S	.rio
	MOVE.L	PagRead(A3,D1.W*4),A4
	MOVE.B	(A4,D0.L),BlkByte
	BRA.S	.wr
.rio:	AND.W	#$1FFF,D0
	LEA	BlkByte,A4
	BSR	ReadIOtia		; (the value into (A4))
.wr:	MOVE.W	D4,D0
	CMP.B	#3,D7			; TIA: destination, destination+1, ...
	BNE.S	.bd
	ADD.W	D6,D0
.bd:	AND.L	#$FFFF,D0
	MOVE.W	D0,D1
	LSR.W	#8,D1
	LSR.W	#5,D1
	CMP.B	#$FF,TabMap(A3,D1.W)
	BEQ.S	.wio
	MOVE.L	PagWrite(A3,D1.W*4),A4
	MOVE.B	BlkByte,(A4,D0.L)
	BRA.S	.adv
.wio:	AND.W	#$1FFF,D0
	LEA	IOAM,A4
	ADD.L	D0,A4
	MOVE.B	BlkByte,(A4)
	BSR	WriteIO
.adv:	EOR.W	#1,D6
	MOVE.W	(BlkStep,PC,D7.W*4),D0
	ADD.W	D0,D3
	MOVE.W	(BlkStep+2,PC,D7.W*4),D0
	ADD.W	D0,D4
	SUBQ.L	#1,D5
	BNE	.loop
.done:	MOVEM.L	(SP)+,D3-D7/A0
	MOVEQ	#0,D1			; 17 + 6 cycles a byte; D1's upper word left 0
	MOVE.W	TnnCyclesCount(A3),D1
	BEQ.S	.big			; (0 = 65536 bytes)
	MULU.W	#6,D1
	ADD.L	#17,D1
	CMP.L	#$FFFF,D1
	BLS.S	.cyc
.big:
	IFEQ	NO_CYCREG
	AND.L	#$0000FFFF,D2		; no cycles left in this line
	ELSE
	CLR.W	(A3)			; Cycles(A3)
	ENDC
	MOVEQ	#17,D1
.cyc:	NextOP	D1
BlkStep:	DC.W	1,1, -1,-1, 1,0, 1,0, 0,1	; source, destination steps: TII TDD TIN TIA TAI
BlkByte:	DC.W	0
	ENDC




	CNOP	0,8
CyclesTab:
	DC.W	8,7,3,4,6,4,6,7,3,2,2,2,7,5,7,6
	DC.W	2,7,7,4,6,4,6,7,2,5,2,2,7,5,7,6
	DC.W	7,7,3,4,4,4,6,7,3,2,2,2,5,5,7,6
	DC.W	2,7,7,2,4,4,6,7,2,5,2,2,5,5,7,6
	DC.W	7,7,3,4,8,4,6,7,3,2,2,2,4,5,7,6
	DC.W	2,7,7,5,0,4,6,7,2,5,3,2,2,5,7,6
	DC.W	7,7,2,2,4,4,6,7,3,2,2,2,7,5,7,6
	DC.W	2,7,7,17,4,4,6,7,2,5,3,2,7,5,7,6
	DC.W	4,7,2,7,4,4,4,7,2,2,2,2,5,5,5,6
	DC.W	2,7,7,8,4,4,4,7,2,5,2,2,5,5,5,6
	DC.W	2,7,2,7,4,4,4,7,2,2,2,2,5,5,5,6
	DC.W	2,7,7,8,4,4,4,7,2,5,2,2,5,5,5,6
	DC.W	2,7,2,17,4,4,6,7,2,2,2,2,5,5,7,6
	DC.W	2,7,7,17,0,4,6,7,2,5,3,2,2,5,7,6
	DC.W	2,7,2,17,4,4,6,7,2,2,2,2,5,5,7,6
	DC.W	2,7,7,17,2,4,6,7,2,5,3,2,2,5,7,6




; ------------------------------------> Crea Tablas para Flags.
CreaTablaFlags:
	LEA	Flags_Push,A0
	LEA	Flags_Pop,A1
	MOVE.W	#256-1,D6
	MOVEQ	#0,D0
FLAGSBUC:
	MOVE.B	D0,D1
	MOVEQ	#0,D2
	BFINS	D1,D2{31:1}	; C	(M68k-b0 => M6502-b0)
	LSR.B	#1,D1
	BFINS	D1,D2{25:1}	; V	(M68k-b1 => M6502-b6)
	LSR.B	#1,D1
	BFINS	D1,D2{30:1}	; Z	(M68k-b2 => M6502-b1)
	LSR.B	#1,D1
	BFINS	D1,D2{24:1}	; N	(M68k-b3 => M6502-b7)
;	---
	LSR.B	#1,D1
	BFINS	D1,D2{26:1}	; 1	(M68k-b4 => M6502-b5)
	LSR.B	#1,D1
	BFINS	D1,D2{27:1}	; B	(M68k-b5 => M6502-b4)
	LSR.B	#1,D1
	BFINS	D1,D2{28:1}	; D	(M68k-b6 => M6502-b3)
	LSR.B	#1,D1
	BFINS	D1,D2{29:1}	; I	(M68k-b7 => M6502-b2)
;	---
	MOVE.B	D2,(A0)+
;	----
	MOVE.B	D0,D1
	MOVEQ	#0,D2
	BFEXTU	D1{24:1},D3	; N	(M6502-b7 => M68k-b3)
	BFINS	D3,D2{28:1}
	BFEXTU	D1{25:1},D3	; V	(M6502-b6 => M68k-b1)
	BFINS	D3,D2{30:1}
	BFEXTU	D1{26:1},D3	; 1	(M6502-b5 => M68k-b4)
	BFINS	D3,D2{27:1}
	BFEXTU	D1{27:1},D3	; B	(M6502-b4 => M68k-b5)
	BFINS	D3,D2{26:1}
;	---
	BFEXTU	D1{28:1},D3	; D	(M6502-b3 => M68k-b6)
	BFINS	D3,D2{25:1}
	BFEXTU	D1{29:1},D3	; I	(M6502-b2 => M68k-b7)
	BFINS	D3,D2{24:1}
	BFEXTU	D1{30:1},D3	; Z	(M6502-b1 => M68k-b2)
	BFINS	D3,D2{29:1}
	BFINS	D1,D2{31:1}	; C	(M6502-b0 => M68k-b0)
;	---
	MOVE.B	D2,(A1)+
;	----
	ADDQ.B	#1,D0
	DBF	D6,FLAGSBUC
	RTS
; ------------------------------------<




	CNOP	0,8
opCodesStr:
	DC.B	"BRKnn",0,"ORAix",0,"SXYnn",0,"ST0nn",0,"TSBzp",0,"ORAzp",0,"ASLzp",0,"RMB_0",0,"PHPnn",0,"ORAin",0,"ASLra",0,"JAMnn",0,"TSBab",0,"ORAab",0,"ASLab",0,"BBR_0",0
	DC.B	"BPLnn",0,"ORAiy",0,"ORAim",0,"ST1nn",0,"TRBzp",0,"ORAzx",0,"ASLzx",0,"RMB_1",0,"CLCnn",0,"ORAay",0,"INCra",0,"JAMnn",0,"TRBab",0,"ORAax",0,"ASLax",0,"BBR_1",0
	DC.B	"JSRnn",0,"ANDix",0,"SAXnn",0,"ST2nn",0,"BITzp",0,"ANDzp",0,"ROLzp",0,"RMB_2",0,"PLPnn",0,"ANDin",0,"ROLra",0,"JAMnn",0,"BITab",0,"ANDab",0,"ROLab",0,"BBR_2",0
	DC.B	"BMInn",0,"ANDiy",0,"ANDim",0,"JAMnn",0,"BITzx",0,"ANDzx",0,"ROLzx",0,"RMB_3",0,"SECnn",0,"ANDay",0,"DECra",0,"JAMnn",0,"BITax",0,"ANDax",0,"ROLax",0,"BBR_3",0
	DC.B	"RTInn",0,"EORix",0,"SAYnn",0,"TMAnn",0,"BSRnn",0,"EORzp",0,"LSRzp",0,"RMB_4",0,"PHAnn",0,"EORin",0,"LSRra",0,"JAMnn",0,"JMPab",0,"EORab",0,"LSRab",0,"BBR_4",0
	DC.B	"BVCnn",0,"EORiy",0,"EORim",0,"TAMnn",0,"CSLnn",0,"EORzx",0,"LSRzx",0,"RMB_5",0,"CLInn",0,"EORay",0,"PHYnn",0,"JAMnn",0,"JAMnn",0,"EORax",0,"LSRax",0,"BBR_5",0
	DC.B	"RTSnn",0,"ADCix",0,"CLAnn",0,"JAMnn",0,"STZzp",0,"ADCzp",0,"RORzp",0,"RMB_6",0,"PLAnn",0,"ADCin",0,"RORra",0,"JAMnn",0,"JMPid",0,"ADCab",0,"RORab",0,"BBR_6",0
	DC.B	"BVSnn",0,"ADCiy",0,"ADCim",0,"TIInn",0,"STZzx",0,"ADCzx",0,"RORzx",0,"RMB_7",0,"SEInn",0,"ADCay",0,"PLYnn",0,"JAMnn",0,"JMPax",0,"ADCax",0,"RORax",0,"BBR_7",0
	DC.B	"BRAnn",0,"STAix",0,"CLXnn",0,"TSTzp",0,"STYzp",0,"STAzp",0,"STXzp",0,"SMB_0",0,"DEYnn",0,"BITin",0,"TXAnn",0,"JAMnn",0,"STYab",0,"STAab",0,"STXab",0,"BBS_0",0
	DC.B	"BCCnn",0,"STAiy",0,"STAim",0,"TSTab",0,"STYzx",0,"STAzx",0,"STXzy",0,"SMB_1",0,"TYAnn",0,"STAay",0,"TXSnn",0,"JAMnn",0,"STZab",0,"STAax",0,"STZax",0,"BBS_1",0
	DC.B	"LDYin",0,"LDAix",0,"LDXin",0,"TSTzx",0,"LDYzp",0,"LDAzp",0,"LDXzp",0,"SMB_2",0,"TAYnn",0,"LDAin",0,"TAXnn",0,"JAMnn",0,"LDYab",0,"LDAab",0,"LDXab",0,"BBS_2",0
	DC.B	"BCSnn",0,"LDAiy",0,"LDAim",0,"TSTax",0,"LDYzx",0,"LDAzx",0,"LDXzy",0,"SMB_3",0,"CLVnn",0,"LDAay",0,"TSXnn",0,"JAMnn",0,"LDYax",0,"LDAax",0,"LDXay",0,"BBS_3",0
	DC.B	"CPYin",0,"CMPix",0,"CLYnn",0,"TDDnn",0,"CPYzp",0,"CMPzp",0,"DECzp",0,"SMB_4",0,"INYnn",0,"CMPin",0,"DEXnn",0,"JAMnn",0,"CPYab",0,"CMPab",0,"DECab",0,"BBS_4",0
	DC.B	"BNEnn",0,"CMPiy",0,"CMPim",0,"TINnn",0,"CSHnn",0,"CMPzx",0,"DECzx",0,"SMB_5",0,"CLDnn",0,"CMPay",0,"PHXnn",0,"JAMnn",0,"JAMnn",0,"CMPax",0,"DECax",0,"BBS_5",0
	DC.B	"CPXin",0,"SBCix",0,"JAMnn",0,"TIAnn",0,"CPXzp",0,"SBCzp",0,"INCzp",0,"SMB_6",0,"INXnn",0,"SBCin",0,"NOPnn",0,"JAMnn",0,"CPXab",0,"SBCab",0,"INCab",0,"BBS_6",0
	DC.B	"BEQnn",0,"SBCiy",0,"SBCim",0,"TAInn",0,"SETnn",0,"SBCzx",0,"INCzx",0,"SMB_7",0,"SEDnn",0,"SBCay",0,"PLXnn",0,"JAMnn",0,"JAMnn",0,"SBCax",0,"INCax",0,"BBS_7",0
	CNOP	0,8

