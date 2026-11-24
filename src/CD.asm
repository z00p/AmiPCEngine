; PC Engine CD-ROM unit, stage (a): data discs. The drive (SCSI phases and commands),
; the registers at $1800-$1BFF, CD RAM (banks $80-$87), Super CD RAM ($68-$7F), the BRAM
; lock and IRQ2. ADPCM and CD audio keep their state, flags and interrupts but make no
; sound yet. Behaviour as Mesen 2 (PceScsiBus, PceCdRom, PceAdpcm, PceCdAudioPlayer).
; Time is in master clocks (21.477 MHz), stepped once a line (1365 clocks) by CdLine; the
; byte handshake answers at once (the 21-clock auto ACK of $1808 is not waited for).
; The disc: a CUE sheet with BIN (2352-byte sectors) or ISO (2048) files; its data tracks
; are read into RAM in the menu (the OS is frozen in play), audio tracks only placed.

	IFND	CdLog		; test builds (with LOG_ENABLED, LogFrame): CD register writes, status changes, commands, phases on serial
CdLog=0
	ENDC
CD_MCLINE=1365
CD_MCSECT=286364		; 2048 bytes at 153,600 bytes a second
CD_MCMS=21477			; master clocks a millisecond

SC_BSY=$80			; $1800 status bits, and three of our own below them
SC_REQ=$40
SC_MSG=$20
SC_CD=$10
SC_IO=$08
SC_ACK=$04
SC_SEL=$02
SC_RST=$01

PH_FREE=0
PH_CMD=1
PH_DIN=2
PH_STAT=3
PH_MSG=4
PH_BUSY=5

UP_CMD=1
UP_REQ=2
UP_DIN=3
UP_GOOD=4

CI_ADPCM=$04			; $1802/$1803 interrupt bits
CI_STOP=$08
CI_SUB=$10
CI_STAT=$20
CI_DIN=$40

AU_PLAY=0			; CD audio status (sub-code Q byte 0)
AU_IDLE=1
AU_PAUSE=2
AU_STOP=3

AE_STOP=0
AE_LOOP=1
AE_IRQ=2

TRK_START=0			; LBA of INDEX 01
TRK_LAST=4			; last sector of the track
TRK_RAM=8			; offset in CdMem (data tracks)
TRK_TYPE=12			; 0 audio, 1 MODE1/2352, 2 MODE1/2048
TRK_FILE=13
TRK_PRE=16			; PREGAP, POSTGAP (sectors)
TRK_POST=20
TRK_IDX0=24			; INDEX 00 / 01 in the file (sectors; -1 none)
TRK_IDX1=28
TRK_ARAM=32			; CD audio in RAM: CD_ASEC bytes a sector, L and R words at 22050 Hz (0 = silent)
TRK_FOFF=36			; INDEX 01's byte offset in the file (a file may mix 2048-byte data and 2352-byte audio)
TRK_SIZE=40
CD_ASEC=294*4			; 588 pairs a sector at 44.1 kHz, kept as 294 (each two averaged)
CD_BIGSECS=256			; sectors a Read for the audio (602 KB)
CD_NOMMAX=40			; the Cartridge line's text, most (with its 0)
CD_CAPMAX=1100			; samples captured a PCE frame, most (CD audio about 368, ADPCM up to 534)
CD_MAXTRK=99
CD_MAXFILE=99

; -------------------------------------------------------------------
; Registers. D0 = offset in the I/O page ($1800-$1FFF), A4 = its byte in IOAM.

CdReadIO:
	IFEQ	NO_ARCADE
	TST.B	ArcOn
	BEQ.S	.na
	CMP.W	#$1A00,D0
	BCS.S	.na
	CMP.W	#$1B00,D0
	BCS	ArcReadIO
.na:
	ENDC
	CMP.W	#$1C00,D0
	BCC.S	.ff
	MOVEM.L	D0-D4/A0-A1,-(SP)
	AND.W	#$03FF,D0
	CMP.W	#$10,D0
	BCC.S	.hi
	IFNE	CdLog
	MOVE.W	D0,CdLogOff
	ENDC
	MOVE.W	CdRdTab(PC,D0.W*2),D1
	JSR	CdRdTab(PC,D1.W)
	MOVE.B	D0,(A4)
	IFNE	CdLog
	JSR	CdLogR
	ENDC
	MOVEM.L	(SP)+,D0-D4/A0-A1
	RTS
.hi:	MOVEQ	#-1,D1
	SUB.W	#$C0,D0
	BCS.S	.st
	CMP.W	#4,D0
	BCC.S	.st
	MOVE.B	CdSuperId(PC,D0.W),D1	; the Super System Card's ID
.st:	MOVE.B	D1,(A4)
	MOVEM.L	(SP)+,D0-D4/A0-A1
	RTS
.ff:	ST	(A4)
	RTS

CdSuperId:	DC.B	$00,$AA,$55,$03
CdRdTab:	DC.W	CdR00-CdRdTab,CdR01-CdRdTab,CdR02-CdRdTab,CdR03-CdRdTab
	DC.W	CdR04-CdRdTab,CdR05-CdRdTab,CdR05-CdRdTab,CdR07-CdRdTab
	DC.W	CdR08-CdRdTab,CdR09-CdRdTab,CdR0A-CdRdTab,CdR0B-CdRdTab
	DC.W	CdR0C-CdRdTab,CdR0D-CdRdTab,CdR0E-CdRdTab,CdR0F-CdRdTab

CdWriteIO:
	IFEQ	NO_ARCADE
	TST.B	ArcOn
	BEQ.S	.na
	CMP.W	#$1A00,D0
	BCS.S	.na
	CMP.W	#$1B00,D0
	BCS	ArcWriteIO
.na:
	ENDC
	CMP.W	#$1C00,D0
	BCC.S	.x
	MOVEM.L	D0-D4/A0-A1,-(SP)
	AND.W	#$03FF,D0
	CMP.W	#$10,D0
	BCC.S	.r
	IFNE	CdLog
	JSR	CdLogW
	ENDC
	MOVE.W	CdWrTab(PC,D0.W*2),D1
	MOVE.B	(A4),D0
	JSR	CdWrTab(PC,D1.W)
.r:	MOVEM.L	(SP)+,D0-D4/A0-A1
.x:	RTS

CdWrTab:	DC.W	CdW00-CdWrTab,CdW01-CdWrTab,CdW02-CdWrTab,CdWNo-CdWrTab
	DC.W	CdW04-CdWrTab,CdW05-CdWrTab,CdWNo-CdWrTab,CdW07-CdWrTab
	DC.W	CdW08-CdWrTab,CdW09-CdWrTab,CdW0A-CdWrTab,CdW0B-CdWrTab
	DC.W	CdWNo-CdWrTab,CdW0D-CdWrTab,CdW0E-CdWrTab,CdW0F-CdWrTab

	IFEQ	NO_ARCADE
; -------------------------------------------------------------------
; The Arcade Card. 2 MB (ArcRam) and four ports, each a 24-bit base, a 16-bit offset and
; increment and a control byte: b0 auto-increment, b1 the offset added to the address,
; b3 the offset signed ($FF0000 added), b4 the increment to the base (else to the offset),
; b5-6 when the offset is added to the base: 1 = a write of reg 5, 2 = of reg 6, 3 = of reg A.
; A port's data: banks $40-$43 (any address) or its registers 0 and 1 ($1A00 + port*$10).
; $1AE0-$1AE3 a 32-bit value (low byte first), $1AE4 shifts it, $1AE5 rotates it,
; $1AFE / $1AFF the ID ($10, $51).
ARC_SIZE=$200000
AP_BASE=0
AP_OFF=4
AP_INC=6
AP_CTRL=8

; The CPU's trap (CheckReadIO / CheckWriteIO): D1.W = slot, A4 = its byte in ArcWin. D0/D1 kept, as
; ReadIO / CdReadIO keep them: the CPU core builds the next address in D1.L (its upper word 0).
ArcRead:
	MOVEM.L	D0-D1,-(SP)
	MOVEQ	#3,D0
	AND.B	TabMap(A3,D1.W),D0
	IFNE	CdLog
	MOVE.W	D0,ArcLogOff
	ENDC
	BSR	ArcGet
	MOVE.B	D1,(A4)
	IFNE	CdLog
	MOVE.W	ArcLogOff,D0
	OR.W	#$0400,D0
	BSR	ArcLog
	ENDC
	MOVEM.L	(SP)+,D0-D1
	RTS
ArcWrite:
	MOVEM.L	D0-D1,-(SP)
	MOVEQ	#3,D0
	AND.B	TabMap(A3,D1.W),D0
	MOVE.B	(A4),D1
	IFNE	CdLog
	MOVEM.L	D0-D1,-(SP)
	OR.W	#$8400,D0
	BSR	ArcLog
	MOVEM.L	(SP)+,D0-D1
	ENDC
	BSR	ArcPut
	MOVEM.L	(SP)+,D0-D1
	RTS

; D0.W = port 0-3: D1.B = its byte, then the auto-increment. D0/D1 trashed.
ArcGet:	MOVEM.L	D2/A0-A1,-(SP)
	BSR.S	ArcAddr
	MOVE.L	ArcRam,A1
	MOVE.B	(A1,D2.L),D1
	BSR.S	ArcInc
	MOVEM.L	(SP)+,D2/A0-A1
	RTS
; D0.W = port 0-3, D1.B = the byte: into its address, then the auto-increment. D0 trashed.
ArcPut:	MOVEM.L	D2/A0-A1,-(SP)
	BSR.S	ArcAddr
	MOVE.L	ArcRam,A1
	MOVE.B	D1,(A1,D2.L)
	BSR.S	ArcInc
	MOVEM.L	(SP)+,D2/A0-A1
	RTS

; D0.W = port: A0 = its registers, D2.L = its address in ArcRam. D0 trashed.
ArcAddr:
	LSL.W	#4,D0
	LEA	ArcPorts,A0
	ADD.W	D0,A0
	MOVE.L	AP_BASE(A0),D2
	BTST	#1,AP_CTRL(A0)
	BEQ.S	.n
	MOVEQ	#0,D0
	MOVE.W	AP_OFF(A0),D0
	ADD.L	D0,D2
	BTST	#3,AP_CTRL(A0)
	BEQ.S	.n
	ADD.L	#$FF0000,D2
.n:	AND.L	#ARC_SIZE-1,D2
	RTS

; A0 = port: the auto-increment. D0 trashed.
ArcInc:	BTST	#0,AP_CTRL(A0)
	BEQ.S	.x
	MOVEQ	#0,D0
	MOVE.W	AP_INC(A0),D0
	BTST	#4,AP_CTRL(A0)
	BEQ.S	.o
	ADD.L	AP_BASE(A0),D0
	AND.L	#$FFFFFF,D0
	MOVE.L	D0,AP_BASE(A0)
	RTS
.o:	ADD.W	D0,AP_OFF(A0)
.x:	RTS

; A0 = port: base = base + offset (+ $FF0000 signed). D0 trashed.
ArcAdd:	MOVEQ	#0,D0
	MOVE.W	AP_OFF(A0),D0
	ADD.L	AP_BASE(A0),D0
	BTST	#3,AP_CTRL(A0)
	BEQ.S	.n
	ADD.L	#$FF0000,D0
.n:	AND.L	#$FFFFFF,D0
	MOVE.L	D0,AP_BASE(A0)
	RTS

; $1A00-$1AFF from CdReadIO: D0.W = the offset, A4 = its byte in IOAM. Registers kept.
ArcReadIO:
	MOVEM.L	D0-D2/A0-A1,-(SP)
	IFNE	CdLog
	MOVE.W	D0,ArcLogOff
	ENDC
	MOVEQ	#-1,D1
	BTST	#7,D0
	BNE.S	.hi
	MOVE.W	D0,D2
	AND.W	#$0F,D2			; the register
	LSR.W	#4,D0
	AND.W	#3,D0			; the port
	CMP.W	#2,D2
	BCC.S	.reg
	BSR	ArcGet
	BRA.S	.out
.reg:	LSL.W	#4,D0
	LEA	ArcPorts,A0
	ADD.W	D0,A0
	CMP.W	#$A,D2
	BHI.S	.out			; $B-$F: $FF
	BEQ.S	.zero
	LEA	ArcRdMap-2,A1
	MOVE.B	(A1,D2.W),D2
	MOVE.B	(A0,D2.W),D1
	BRA.S	.out
.zero:	MOVEQ	#0,D1
	BRA.S	.out
.hi:	SUB.W	#$1AE0,D0
	BCS.S	.out
	CMP.W	#4,D0
	BCS.S	.val
	CMP.W	#6,D0
	BCS.S	.lat
	MOVEQ	#$10,D1
	CMP.W	#$1E,D0
	BEQ.S	.out
	MOVEQ	#$51,D1
	CMP.W	#$1F,D0
	BEQ.S	.out
	MOVEQ	#-1,D1
	BRA.S	.out
.val:	LEA	ArcVal+3,A0
	SUB.W	D0,A0
	MOVE.B	(A0),D1
	BRA.S	.out
.lat:	LEA	ArcLatch-4,A0
	MOVE.B	(A0,D0.W),D1
.out:	MOVE.B	D1,(A4)
	IFNE	CdLog
	MOVE.W	ArcLogOff,D0
	BSR	ArcLog
	ENDC
	MOVEM.L	(SP)+,D0-D2/A0-A1
	RTS

; $1A00-$1AFF from CdWriteIO: D0.W = the offset, (A4) = the byte. Registers kept.
ArcWriteIO:
	MOVEM.L	D0-D2/A0-A1,-(SP)
	IFNE	CdLog
	MOVE.W	D0,ArcLogOff
	ENDC
	MOVE.B	(A4),D1
	BTST	#7,D0
	BNE.S	.hi
	MOVE.W	D0,D2
	AND.W	#$0F,D2
	LSR.W	#4,D0
	AND.W	#3,D0
	CMP.W	#2,D2
	BCC.S	.reg
	BSR	ArcPut
	BRA	.out
.reg:	LSL.W	#4,D0
	LEA	ArcPorts,A0
	ADD.W	D0,A0
	CMP.W	#$A,D2
	BHI	.out
	BEQ.S	.tr3
	CMP.W	#9,D2
	BEQ.S	.ctl
	LEA	ArcRdMap-2,A1
	MOVE.B	(A1,D2.W),D0		; D0.W = the byte in the port's registers
	MOVE.B	D1,(A0,D0.W)
	CMP.W	#5,D2
	BEQ.S	.tr1
	CMP.W	#6,D2
	BNE	.out
	MOVEQ	#2,D0
	BRA.S	.trig
.tr1:	MOVEQ	#1,D0
	BRA.S	.trig
.tr3:	MOVEQ	#3,D0
.trig:	MOVE.B	AP_CTRL(A0),D2
	LSR.B	#5,D2
	AND.B	#3,D2
	CMP.B	D0,D2
	BNE.S	.out
	BSR	ArcAdd
	BRA.S	.out
.ctl:	AND.B	#$7F,D1
	MOVE.B	D1,AP_CTRL(A0)
	BRA.S	.out
.hi:	SUB.W	#$1AE0,D0
	BCS.S	.out
	CMP.W	#4,D0
	BCC.S	.sh
	LEA	ArcVal+3,A0
	SUB.W	D0,A0
	MOVE.B	D1,(A0)
	BRA.S	.out
.sh:	CMP.W	#6,D0
	BCC.S	.out
	LEA	ArcLatch-4,A0
	MOVE.B	D1,(A0,D0.W)
	MOVE.L	ArcVal,D2
	AND.W	#$0F,D1
	BEQ.S	.out
	BCLR	#3,D1
	BNE.S	.right
	CMP.W	#4,D0
	BEQ.S	.sl
	ROL.L	D1,D2
	BRA.S	.st
.sl:	LSL.L	D1,D2
	BRA.S	.st
.right:	NEG.W	D1			; 8..F: right by 8 - (v & 7)
	ADDQ.W	#8,D1
	CMP.W	#4,D0
	BEQ.S	.sr
	ROR.L	D1,D2
	BRA.S	.st
.sr:	LSR.L	D1,D2
.st:	MOVE.L	D2,ArcVal
.out:
	IFNE	CdLog
	MOVE.W	ArcLogOff,D0
	OR.W	#$8000,D0
	MOVE.B	(A4),D1
	BSR	ArcLog
	ENDC
	MOVEM.L	(SP)+,D0-D2/A0-A1
	RTS

	IFNE	CdLog
; D0.W = what ($1Axx register read, $9Axx write, $040p port p bank read, $840p write), D1.B = the byte.
ArcLog:	MOVEM.L	D0-D7/A0-A6,-(SP)
	TST.W	ArcLogN
	BEQ	ArcLogX
	SUBQ.W	#1,ArcLogN
	MOVE.W	D0,D4
	MOVE.B	D1,D5
	MOVE.L	A5,D2
	SUB.W	(A2),D2
	LogString "A "
	LogHexWord D2
	LogString " "
	LogHexWord D4
	LogString "="
	LogHexByte D5
	LogEnter
ArcLogX:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
ArcLogN:	DC.W	15000
ArcPcSample:			; every 4000 lines: the PC and the MPRs
	SUBQ.W	#1,ArcPcN
	BNE	ArcPcR
	MOVE.W	#500,ArcPcN
	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.L	A5,D2
	SUB.W	(A2),D2
	LogString "S "
	LogHexWord D2
	LogString " M:"
	LEA	Regs+TabMap,A2
	MOVEQ	#7,D3
ArcPcL:	MOVE.B	(A2)+,D0
	LogHexByte D0
	DBF	D3,ArcPcL
	LogString " T:"
	LogHexLong Regs+ArcSlot
	LogHexLong Regs+ArcSlot+4
	LogEnter
	MOVEM.L	(SP)+,D0-D7/A0-A6
ArcPcR:	RTS
ArcPcN:	DC.W	500
ArcLogOff:	DC.W	0
	ENDC
ArcRam:		DC.L	0		; the card's 2 MB (AllocMem with the disc), 0 = no card
ArcVal:		DC.L	0
ArcPorts:	DS.B	4*16
ArcLatch:	DS.B	2		; the last $1AE4 / $1AE5 writes
ArcOn:		DC.B	0		; the card is in (a disc running, its RAM allocated)
ArcRdMap:	DC.B	3,2,1,5,4,7,6,8	; registers 2-9: the byte in the port's registers
	EVEN
	ENDC

; Reads: the value in D0.B.
CdR00:	MOVE.B	ScSig,D0		; BSY REQ MSG C/D I/O
	AND.B	#$F8,D0
	RTS
CdR01:	BRA	ScGetData
CdR02:	MOVE.B	CdEnaIrq,D0
	BTST	#2,ScSig		; ACK
	BEQ.S	.x
	OR.B	#$80,D0
.x:	RTS
CdR03:	TST.B	CdBramLk		; reading $1803 locks the BRAM
	BNE.S	.l
	ST	CdBramLk
	BSR	CdBramMap
.l:	MOVE.B	CdActIrq,D0
	TST.B	CdRight
	BNE.S	.x
	OR.B	#$02,D0
.x:	RTS
CdR04:	MOVE.B	CdResReg,D0
	RTS
CdR05:	MOVEQ	#0,D0			; CD audio sample latch: silent
	RTS
CdR07:	MOVEQ	#CI_SUB,D1		; sub-code byte (none kept): clears the sub-code IRQ
	BSR	CdClrIrq
	MOVEQ	#0,D0
	RTS
CdR08:	BSR	ScGetData		; data with the auto ACK
	MOVE.B	D0,-(SP)
	MOVE.B	ScSig,D1
	AND.B	#SC_REQ|SC_IO|SC_CD,D1
	CMP.B	#SC_REQ|SC_IO,D1
	BNE.S	.x
	BSR	ScAutoAck
.x:	MOVE.B	(SP)+,D0
	RTS
CdR09:	MOVEQ	#0,D0
	RTS
CdR0A:	MOVE.B	AdRBuf,-(SP)		; ADPCM read: the byte fetched last time; the next is fetched now
	MOVEQ	#0,D1
	MOVE.W	AdRead,D1
	LEA	AdRam,A0
	MOVE.B	(A0,D1.L),AdRBuf
	ADDQ.W	#1,AdRead
	BTST	#4,AdCtl
	BNE.S	.x
	TST.L	AdLen
	BEQ.S	.end
	SUBQ.L	#1,AdLen
	CMP.L	#$8000,AdLen
	BCC.S	.ho
	BSR	AdHalfOn
	BRA.S	.x
.ho:	BSR	AdHalfOff
	BRA.S	.x
.end:	BSR	AdEndOn
	BSR	AdHalfOff
.x:	MOVE.B	(SP)+,D0
	RTS
CdR0B:	MOVE.B	AdDma,D0
	RTS
CdR0C:	MOVEQ	#0,D0			; ADPCM status: end, playing (reads and writes are done at once)
	TST.B	AdEnd
	BEQ.S	.p
	MOVEQ	#1,D0
.p:	TST.B	AdPlay
	BEQ.S	.x
	OR.B	#$08,D0
.x:	RTS
CdR0D:	MOVE.B	AdCtl,D0
	RTS
CdR0E:	MOVE.B	AdRate,D0
	RTS
CdR0F:	MOVE.B	CdFader,D0
	RTS

; Writes: the value in D0.B.
CdW00:	MOVEQ	#SC_SEL,D1		; selection: a SEL pulse
	BSR	ScSetNI
	BSR	ScUpdate
	MOVEQ	#SC_SEL,D1
	BSR	ScClrNI
	BRA	ScUpdate
CdW01:	MOVE.B	D0,ScData
	BRA	ScUpdate
CdW02:	MOVE.B	D0,-(SP)		; bit 7 ACK, bits 0-6 IRQ enable
	MOVEQ	#SC_ACK,D1
	TST.B	D0
	BMI.S	.s
	BSR	ScClrNI
	BRA.S	.u
.s:	BSR	ScSetNI
.u:	BSR	ScUpdate
	MOVE.B	(SP)+,D0
	AND.B	#$7F,D0
	MOVE.B	D0,CdEnaIrq
	BRA	CdIrqUpd
CdW04:	AND.B	#$0F,D0			; bit 1: SCSI reset
	MOVE.B	D0,CdResReg
	MOVE.B	D0,-(SP)
	MOVEQ	#SC_RST,D1
	BTST	#1,D0
	BNE.S	.s
	BSR	ScClrNI
	BRA.S	.u
.s:	BSR	ScSetNI
.u:	BSR	ScUpdate
	MOVE.B	(SP)+,D0
	BTST	#1,D0
	BEQ.S	CdWNo
	AND.B	#$8F,CdEnaIrq
	BRA	CdIrqUpd
CdWNo:	RTS
CdW05:	NOT.B	CdRight			; latch the next CD audio channel
	RTS
CdW07:	TST.B	D0			; bit 7 = 1 unlocks the BRAM
	SPL	D1
	CMP.B	CdBramLk,D1
	BEQ.S	CdWNo
	MOVE.B	D1,CdBramLk
	BRA	CdBramMap
CdW08:	MOVE.B	D0,AdAddr+1
	RTS
CdW09:	MOVE.B	D0,AdAddr
	RTS
CdW0A:	BRA	AdWriteByte
CdW0B:	TST.L	ScBufLeft		; bit 0 only while a block is there
	BNE.S	.r
	AND.B	#$FE,D0
.r:	MOVE.B	D0,AdDma
	RTS
CdW0D:	MOVE.B	AdCtl,D1		; ADPCM control
	BTST	#1,D0
	BEQ.S	.nw
	BTST	#1,D1
	BNE.S	.nw
	MOVE.W	AdAddr,D2
	BTST	#0,D0
	BNE.S	.w0
	SUBQ.W	#1,D2
.w0:	MOVE.W	D2,AdWrite
.nw:	BTST	#3,D0
	BEQ.S	.nr
	BTST	#3,D1
	BNE.S	.nr
	MOVE.W	AdAddr,D2
	BTST	#2,D0
	BNE.S	.r0
	SUBQ.W	#1,D2
.r0:	MOVE.W	D2,AdRead
.nr:	TST.B	AdPlay
	BNE.S	.np
	BTST	#5,D0
	BEQ.S	.np
	ST	AdPReq
.np:	MOVE.B	D0,AdCtl
	BRA	AdFlags
CdW0E:	MOVE.B	D0,AdRate		; 32000 / (16 - n) Hz
	AND.W	#$000F,D0
	MOVEQ	#16,D1
	SUB.W	D0,D1
	MULU.W	#671,D1
	MOVE.L	D1,AdCPS
	RTS
CdW0F:	MOVE.B	D0,CdFader
	IFEQ	CdSndOff
	CLR.W	CdFadeT			; the fade starts now
	ENDC
	RTS

; -------------------------------------------------------------------
; IRQ2: the enabled and active bits, as a level.
CdSetIrq:				; D1 = bits (D0 kept)
	BTST	#1,CdResReg		; not while the drive is held in reset
	BNE.S	CdIrqX
	OR.B	D1,CdActIrq
	BRA.S	CdIrqUpd
CdClrIrq:
	NOT.B	D1
	AND.B	D1,CdActIrq
CdIrqUpd:
	MOVE.B	CdActIrq,D1
	AND.B	CdEnaIrq,D1
	BEQ.S	.off
	BSET	#0,Regs+IRQ_Pending
	RTS
.off:	BCLR	#0,Regs+IRQ_Pending
CdIrqX:	RTS

; BRAM (bank $F7): open, or locked (reads $FF, writes go nowhere).
CdBramMap:
	MOVEM.L	D0-D1/D7/A3,-(SP)
	LEA	Regs,A3
	TST.B	CdBramLk
	BEQ.S	.open
	MOVE.L	#CdOpenBus,DirMappers+($F7*8)
	MOVE.L	#EROM,DirMappers+($F7*8)+4
	BRA.S	.set
.open:	MOVE.L	#SRAM,DirMappers+($F7*8)
	MOVE.L	#SRAM,DirMappers+($F7*8)+4
.set:	MOVEQ	#8-1,D1
.l:	CMP.B	#$F7,TabMap(A3,D1.W)
	BNE.S	.n
	MOVE.L	#$F7,D7
	JSR	SetMapper
.n:	DBF	D1,.l
	MOVEM.L	(SP)+,D0-D1/D7/A3
	RTS

; -------------------------------------------------------------------
; The drive. Signals: ScSet / ScClr also look at the IRQ (as Mesen's SetSignals);
; ScSetNI / ScClrNI don't. D1 = signal bits; D0 trashed.
ScSet:	MOVE.B	ScSig,D0
	OR.B	D1,D0
	BRA.S	ScSigI
ScClr:	MOVE.B	ScSig,D0
	NOT.B	D1
	AND.B	D1,D0
ScSigI:	CMP.B	ScSig,D0
	BEQ.S	CdScsiIrq
	MOVE.B	D0,ScSig
	ST	ScChg
	BRA.S	CdScsiIrq
ScSetNI:
	MOVE.B	ScSig,D0
	OR.B	D1,D0
	BRA.S	ScSigN
ScClrNI:
	MOVE.B	ScSig,D0
	NOT.B	D1
	AND.B	D1,D0
ScSigN:	CMP.B	ScSig,D0
	BEQ.S	.x
	MOVE.B	D0,ScSig
	ST	ScChg
.x:	RTS

; REQ + I/O + BSY: status/message in (C/D set) or data in.
CdScsiIrq:
	MOVE.B	ScSig,D1
	AND.B	#SC_REQ|SC_IO|SC_BSY,D1
	CMP.B	#SC_REQ|SC_IO|SC_BSY,D1
	BNE.S	.clr
	MOVEQ	#CI_DIN,D1
	BTST	#4,ScSig
	BEQ	CdSetIrq
	MOVEQ	#CI_STAT,D1
	BRA	CdSetIrq
.clr:	MOVEQ	#CI_STAT|CI_DIN,D1
	BRA	CdClrIrq

; D0.B = phase
CdSetPhase:
	CMP.B	ScPhase,D0
	BEQ.S	.x
	IFNE	CdLog
	JSR	CdLogP
	ENDC
	CLR.L	ScUpdCnt
	ST	ScChg
	MOVE.B	D0,ScPhase
	AND.B	#SC_ACK|SC_SEL|SC_RST,ScSig
	AND.W	#7,D0
	MOVE.B	CdPhSig(PC,D0.W),D1
	OR.B	D1,ScSig
	CMP.B	#PH_CMD,D0
	BNE	CdScsiIrq
	CLR.L	ScReadCnt		; a new command stops a disc read
	BRA	CdScsiIrq
.x:	RTS
CdPhSig:	DC.B	0,SC_BSY|SC_CD|SC_REQ,SC_BSY|SC_IO,SC_BSY|SC_CD|SC_IO|SC_REQ
	DC.B	SC_BSY|SC_CD|SC_IO|SC_MSG|SC_REQ,SC_BSY
	EVEN

ScGetData:
	MOVE.B	ScPhase,D1
	MOVE.B	ScRData,D0
	CMP.B	#PH_DIN,D1
	BEQ.S	.x
	CMP.B	#PH_STAT,D1
	BEQ.S	.x
	CMP.B	#PH_MSG,D1
	BEQ.S	.x
	MOVE.B	ScData,D0
.x:	RTS

; Status "good" and D1 message bytes of 0, status phase.
ScGood:	MOVE.L	#CdZeros,ScBufPtr
	MOVE.L	D1,ScBufLeft
	SF	ScMsgDone
	CLR.B	ScRData
	MOVEQ	#PH_STAT,D0
	BRA	CdSetPhase

; D0.B = what, D1.L = delay in master clocks: queued unless the same one is already waiting.
ScQueue:
	CMP.B	ScUpdTyp,D0
	BNE.S	.set
	TST.L	ScUpdCnt
	BNE.S	.x
.set:	MOVE.B	D0,ScUpdTyp
	MOVE.L	D1,ScUpdCnt
.x:	RTS

ScDoUpd:
	MOVE.B	ScUpdTyp,D0
	CMP.B	#UP_CMD,D0
	BNE.S	.n1
	MOVEQ	#PH_CMD,D0
	BRA	CdSetPhase
.n1:	CMP.B	#UP_REQ,D0
	BNE.S	.n2
	MOVEQ	#SC_REQ,D1
	BRA	ScSet
.n2:	CMP.B	#UP_DIN,D0
	BNE.S	.n3
	MOVEQ	#PH_DIN,D0
	BRA	CdSetPhase
.n3:	MOVEQ	#1,D1
	BRA	ScGood

; Next byte of the buffer to ScRData: NE if there was one.
ScPop:	TST.L	ScBufLeft
	BEQ.S	.x
	MOVE.L	ScBufPtr,A0
	MOVE.B	(A0)+,ScRData
	MOVE.L	A0,ScBufPtr
	SUBQ.L	#1,ScBufLeft
	MOVEQ	#1,D0
.x:	RTS

; The CPU (or ADPCM DMA) took a byte: ACK set, then cleared (at once).
ScAutoAck:
	MOVEQ	#SC_ACK,D1
	BSR	ScSet
	BSR	ScUpdate
	MOVEQ	#SC_ACK,D1
	BSR	ScClrNI
	BRA	ScUpdate

ScReset:
	AND.B	#SC_BSY|SC_SEL|SC_RST,ScSig
	CLR.B	ScPhase
	CLR.B	ScData
	CLR.B	ScRData
	CLR.L	ScToRead
	CLR.L	ScReadCnt
	CLR.B	ScCmdLen
	CLR.L	ScBufLeft
	MOVE.B	#AU_STOP,AuStat
	BRA	CdScsiIrq

ScUpdate:
	TST.B	ScChg
	BEQ	.x
	BTST	#0,ScSig		; RST
	BNE.S	ScReset
.l:	SF	ScChg
	BTST	#1,ScSig		; SEL
	BEQ.S	.ph
	CLR.L	ScUpdCnt
	CMP.B	#PH_DIN,ScPhase
	BEQ.S	.abort
	MOVEQ	#UP_CMD,D0
	MOVE.L	#25000*3,D1
	BSR	ScQueue
	BRA.S	.nx
.abort:	MOVEQ	#8,D1			; a transfer cut off: an 8-byte message, then the command phase
	BSR	ScGood
	MOVEQ	#UP_CMD,D0
	MOVE.L	#300000*3,D1
	BRA	ScQueue
.ph:	MOVE.B	ScPhase,D0
	CMP.B	#PH_CMD,D0
	BNE.S	.p1
	BSR	ScPhCmd
	BRA.S	.nx
.p1:	CMP.B	#PH_DIN,D0
	BNE.S	.p2
	BSR	ScPhDin
	BRA.S	.nx
.p2:	CMP.B	#PH_STAT,D0
	BNE.S	.p3
	BSR	ScPhStat
	BRA.S	.nx
.p3:	CMP.B	#PH_MSG,D0
	BNE.S	.nx
	BSR	ScPhMsg
.nx:	TST.B	ScChg
	BNE.S	.l
.x:	RTS

; D0 = REQ|ACK of the signals
ScReqAck:
	MOVE.B	ScSig,D0
	AND.B	#SC_REQ|SC_ACK,D0
	RTS

ScPhStat:
	BSR	ScReqAck
	CMP.B	#SC_REQ|SC_ACK,D0
	BNE.S	.n
	MOVEQ	#SC_REQ,D1
	BRA	ScClr
.n:	TST.B	D0
	BNE.S	.x
	BSR	ScPop
	BEQ.S	.x
	TST.L	ScBufLeft
	BNE.S	.req
	MOVEQ	#PH_MSG,D0
	BRA	CdSetPhase
.req:	MOVEQ	#SC_REQ,D1
	BRA	ScSet
.x:	RTS

ScPhMsg:
	BSR	ScReqAck
	CMP.B	#SC_REQ|SC_ACK,D0
	BNE.S	.n
	ST	ScMsgDone
	MOVEQ	#SC_REQ,D1
	BRA	ScClr
.n:	TST.B	D0
	BNE.S	.x
	TST.B	ScMsgDone
	BEQ.S	.x
	SF	ScMsgDone
	MOVEQ	#PH_FREE,D0
	BRA	CdSetPhase
.x:	RTS

ScPhDin:
	BSR	ScReqAck
	CMP.B	#SC_REQ|SC_ACK,D0
	BNE.S	.n
	MOVEQ	#SC_REQ,D1
	BRA	ScClr
.n:	TST.B	D0
	BNE.S	.x
	BSR	ScPop
	BEQ.S	.empty
	MOVEQ	#SC_REQ,D1
	BRA	ScSet
.empty:	TST.L	ScToRead		; the last sector taken: status after a while (the IRQ)
	BNE.S	.x
	MOVEQ	#UP_GOOD,D0
	MOVE.L	#1000*3,D1
	BRA	ScQueue
.x:	RTS

ScPhCmd:
	BSR	ScReqAck
	CMP.B	#SC_REQ|SC_ACK,D0
	BNE.S	.n
	MOVEQ	#0,D0
	MOVE.B	ScCmdLen,D0
	CMP.B	#16,D0
	BCC.S	.full
	LEA	ScCmd,A0
	MOVE.B	ScData,(A0,D0.W)
	ADDQ.B	#1,ScCmdLen
.full:	MOVEQ	#SC_REQ,D1
	BRA	ScClr
.n:	TST.B	D0
	BNE.S	.x
	MOVE.B	ScCmdLen,D1
	BEQ.S	.x
	MOVE.B	ScCmd,D0
	MOVEQ	#6,D2
	CMP.B	#$00,D0
	BEQ.S	.sz
	CMP.B	#$08,D0
	BEQ.S	.sz
	MOVEQ	#10,D2
	CMP.B	#$D8,D0
	BEQ.S	.sz
	CMP.B	#$D9,D0
	BEQ.S	.sz
	CMP.B	#$DA,D0
	BEQ.S	.sz
	CMP.B	#$DD,D0
	BEQ.S	.sz
	CMP.B	#$DE,D0
	BEQ.S	.sz
	CLR.B	ScCmdLen		; unknown command: status good
	MOVEQ	#1,D1
	BRA	ScGood
.sz:	CMP.B	D2,D1
	BCC.S	.exec
	MOVEQ	#UP_REQ,D0		; more bytes to come
	MOVE.L	#1000*3,D1
	BRA	ScQueue
.exec:	BSR	ScExec
	CLR.B	ScCmdLen
.x:	RTS

ScExec:
	IFNE	CdLog
	JSR	CdLogC
	ENDC
	MOVE.B	ScCmd,D0
	BEQ	ScTur
	CMP.B	#$08,D0
	BEQ	ScRead
	CMP.B	#$D8,D0
	BEQ	ScAuStart
	CMP.B	#$D9,D0
	BEQ	ScAuEnd
	CMP.B	#$DA,D0
	BEQ	ScPause
	CMP.B	#$DD,D0
	BEQ	ScSubQ
	BRA	ScToc

ScTur:	MOVEQ	#UP_GOOD,D0		; TEST UNIT READY (Mesen's shortened delay)
	MOVE.L	#150000*3,D1
	BRA	ScQueue

ScRead:	MOVEQ	#0,D0			; READ(6)
	MOVE.B	ScCmd+1,D0
	AND.B	#$1F,D0
	LSL.L	#8,D0
	MOVE.B	ScCmd+2,D0
	LSL.L	#8,D0
	MOVE.B	ScCmd+3,D0
	MOVEQ	#0,D2
	MOVE.B	ScCmd+4,D2
	BEQ.S	.good
	CMP.L	CdSecs,D0
	BCC.S	.good
	MOVE.L	D0,D3
	MOVE.L	D0,D1
	BSR	CdCurSector
	BSR	CdSeekMC
	ADD.L	#CD_MCSECT,D0
	MOVE.L	D0,ScReadCnt
	MOVE.L	D3,ScSector
	MOVE.L	D2,ScToRead
	MOVEQ	#PH_DIN,D0		; data in at once (Ys IV)
	BSR	CdSetPhase
	MOVE.B	#AU_IDLE,AuStat
	RTS
.good:	MOVEQ	#1,D1
	BRA	ScGood

ScAuStart:				; AUDIO START POS
	BSR	CdAudioLba
	CMP.L	CdSecs,D0
	BCC.S	.good
	MOVE.L	D0,D2
	BSR	CdGetTrack
	TST.L	D1
	BMI.S	.busy
	MOVE.L	TRK_LAST(A0),D0		; it plays to the end of the track: its POSTGAP is part of it
	ADD.L	TRK_POST(A0),D0		; (not in the file, so silent, as the gap on a disc)
	MOVE.L	CdSecs,D1
	SUBQ.L	#1,D1
	CMP.L	D1,D0
	BLS.S	.ie
	MOVE.L	D1,D0
.ie:	MOVE.L	D0,AuEnd
	BSR	CdCurSector
	MOVE.L	D2,D1
	BSR	CdSeekMC
	MOVE.L	D0,AuSeek
	MOVE.L	D2,AuStart
	MOVE.L	D2,AuSector
	CLR.W	AuSmp
	CLR.L	AuClk
	MOVE.B	#AE_STOP,AuEndB
	MOVE.B	#AU_PLAY,AuStat
	TST.B	ScCmd+1
	BNE.S	.busy
	MOVE.B	#AU_PAUSE,AuStat
.busy:	MOVEQ	#PH_BUSY,D0		; busy until the audio starts
	BRA	CdSetPhase
.good:	MOVEQ	#1,D1
	BRA	ScGood

ScAuEnd:				; AUDIO END POS
	BSR	CdAudioLba
	CMP.L	CdSecs,D0
	BCS.S	.in
	MOVE.L	CdSecs,D0
	SUBQ.L	#1,D0
.in:	MOVE.B	ScCmd+1,D1
	BNE.S	.m1
	MOVE.B	#AU_STOP,AuStat
	BRA.S	.good
.m1:	CMP.B	#4,D1
	BCC.S	.good
	MOVE.L	D0,AuEnd
	MOVE.B	#AU_PLAY,AuStat
	MOVE.B	#AE_LOOP,AuEndB
	CMP.B	#1,D1
	BEQ.S	.busy
	MOVE.B	#AE_IRQ,AuEndB
	CMP.B	#2,D1
	BEQ.S	.busy
	MOVE.B	#AE_STOP,AuEndB
.good:	MOVEQ	#1,D1
	BRA	ScGood
.busy:	MOVEQ	#PH_BUSY,D0
	BRA	CdSetPhase

ScPause:
	MOVE.B	#AU_PAUSE,AuStat
	MOVEQ	#1,D1
	BRA	ScGood

ScSubQ:					; READ SUB-CODE Q: 10 bytes
	LEA	ScResp,A1
	MOVE.L	A1,ScBufPtr
	MOVE.L	#10,ScBufLeft
	MOVE.B	AuStat,(A1)+
	BSR	CdCurSector
	MOVE.L	D0,D2
	BSR	CdGetTrack
	MOVEQ	#$01,D3			; ADR 1; $40: a data track
	MOVEQ	#0,D4			; sectors into the track
	TST.L	D1
	BMI.S	.nt
	TST.B	TRK_TYPE(A0)
	BEQ.S	.au
	MOVEQ	#$41,D3
.au:	MOVE.L	D2,D4
	SUB.L	TRK_START(A0),D4
	BCC.S	.nt
	MOVEQ	#0,D4
.nt:	MOVE.B	D3,(A1)+
	MOVE.L	D1,D0
	ADDQ.L	#1,D0			; track number (0 if none)
	BSR	CdBcd
	MOVE.B	D0,(A1)+
	MOVE.B	#1,(A1)+		; index
	MOVE.L	D4,D0
	BSR	CdMsf
	MOVE.L	D2,D0
	BSR	CdMsf
	MOVEQ	#UP_DIN,D0
	MOVE.L	#1000*3,D1
	BRA	ScQueue

ScToc:	LEA	ScResp,A1		; READ TOC: 4 bytes
	MOVE.L	A1,ScBufPtr
	MOVE.L	#4,ScBufLeft
	MOVE.B	ScCmd+1,D1
	BNE.S	.n0
	MOVE.B	#1,(A1)+		; first and last track
	MOVE.W	CdTracks,D0
	BSR	CdBcd
	MOVE.B	D0,(A1)+
	CLR.B	(A1)+
	CLR.B	(A1)+
	BRA.S	.q
.n0:	CMP.B	#1,D1
	BNE.S	.n1
	MOVE.L	CdSecs,D0		; disc length
	ADD.L	#150,D0
	BSR	CdMsf
	CLR.B	(A1)+
	BRA.S	.q
.n1:	CMP.B	#2,D1
	BNE.S	.x
	MOVE.B	ScCmd+2,D0		; a track's start
	BSR	CdFromBcd
	TST.L	D0
	BNE.S	.t
	MOVEQ	#1,D0
.t:	CMP.W	CdTracks,D0
	BHI.S	.end
	SUBQ.L	#1,D0
	MULU	#TRK_SIZE,D0
	LEA	CdTrk,A0
	ADD.L	D0,A0
	MOVE.L	TRK_START(A0),D0
	ADD.L	#150,D0
	BSR	CdMsf
	MOVEQ	#0,D0
	TST.B	TRK_TYPE(A0)
	BEQ.S	.ty
	MOVEQ	#4,D0
.ty:	MOVE.B	D0,(A1)+
	BRA.S	.q
.end:	MOVE.L	CdSecs,D0
	ADD.L	#150,D0
	BSR	CdMsf
	CLR.B	(A1)+
.q:	MOVEQ	#UP_DIN,D0
	MOVE.L	#3000*3,D1
	BRA	ScQueue
.x:	CLR.L	ScBufLeft		; other parameters: no answer (as Mesen)
	RTS

; A sector read is due (Mesen's ProcessDiscRead).
ScProcRead:
	TST.L	ScBufLeft
	BNE.S	.late
	MOVE.L	ScSector,D0
	BSR	CdSectorPtr
	MOVE.L	A0,ScBufPtr
	MOVE.L	#2048,ScBufLeft
	MOVE.L	ScSector,D0
	ADDQ.L	#1,D0
	AND.L	#$1FFFFF,D0
	MOVE.L	D0,ScSector
	SUBQ.L	#1,ScToRead
	ST	ScChg
	TST.L	ScToRead
	BNE.S	.more
	CLR.L	ScReadCnt
	BRA.S	.ph
.more:	ADD.L	#CD_MCSECT,ScReadCnt
.ph:	MOVEQ	#PH_DIN,D0
	BRA	CdSetPhase
.late:	MOVE.L	#290*CD_MCMS,ScReadCnt	; the last sector not taken yet: about 290 ms (Sherlock Holmes)
	RTS

; -------------------------------------------------------------------
; Disc helpers.

; D0 = the drive's sector now
CdCurSector:
	MOVE.L	ScSector,D0
	CMP.B	#AU_IDLE,AuStat
	BEQ.S	.x
	MOVE.L	AuSector,D0
.x:	RTS

; D0 = LBA: D1 = track index (-1 none), A0 its entry. A sector between tracks counts to the one before.
CdGetTrack:
	MOVEQ	#-1,D1
	MOVE.W	CdTracks,D1
	EXT.L	D1
	SUBQ.L	#1,D1
	BMI.S	.x
	MOVE.L	D1,-(SP)
	MULU	#TRK_SIZE,D1
	LEA	CdTrk,A0
	ADD.L	D1,A0
	MOVE.L	(SP)+,D1
.l:	CMP.L	TRK_START(A0),D0
	BCC.S	.x
	LEA	-TRK_SIZE(A0),A0
	SUBQ.L	#1,D1
	BPL.S	.l
.x:	RTS

; D0 = LBA: A0 = its 2048 bytes (zeros outside the data tracks)
CdSectorPtr:
	MOVEM.L	D1-D2,-(SP)
	LEA	CdTrk,A0
	MOVE.W	CdTracks,D1
	BEQ.S	.z
	SUBQ.W	#1,D1
.l:	TST.B	TRK_TYPE(A0)
	BEQ.S	.n
	MOVE.L	D0,D2
	SUB.L	TRK_START(A0),D2
	BCS.S	.n
	CMP.L	TRK_LAST(A0),D0
	BHI.S	.n
	MOVEQ	#11,D1
	LSL.L	D1,D2
	ADD.L	TRK_RAM(A0),D2
	ADD.L	CdMem,D2
	MOVE.L	D2,A0
	MOVEM.L	(SP)+,D1-D2
	RTS
.n:	LEA	TRK_SIZE(A0),A0
	DBF	D1,.l
.z:	LEA	CdZeros,A0
	MOVEM.L	(SP)+,D1-D2
	RTS

; The position in an audio command (byte 9: LBA, BCD MSF or BCD track): D0
CdAudioLba:
	MOVE.B	ScCmd+9,D1
	AND.B	#$C0,D1
	BNE.S	.n0
	MOVEQ	#0,D0
	MOVE.B	ScCmd+3,D0
	LSL.L	#8,D0
	MOVE.B	ScCmd+4,D0
	LSL.L	#8,D0
	MOVE.B	ScCmd+5,D0
	RTS
.n0:	CMP.B	#$40,D1
	BNE.S	.n1
	MOVE.L	D2,-(SP)
	MOVE.B	ScCmd+2,D0
	BSR	CdFromBcd
	MULU	#60,D0
	MOVE.L	D0,D2
	MOVE.B	ScCmd+3,D0
	BSR	CdFromBcd
	ADD.L	D0,D2
	MULU	#75,D2
	MOVE.B	ScCmd+4,D0
	BSR	CdFromBcd
	ADD.L	D2,D0
	SUB.L	#150,D0
	MOVE.L	(SP)+,D2
	RTS
.n1:	CMP.B	#$80,D1
	BNE.S	.zero
	MOVE.B	ScCmd+2,D0
	BSR	CdFromBcd
	SUBQ.L	#1,D0
	BMI.S	.zero
	CMP.W	CdTracks,D0
	BCC.S	.zero
	MULU	#TRK_SIZE,D0
	LEA	CdTrk,A0
	MOVE.L	TRK_START(A0,D0.L),D0
	RTS
.zero:	MOVEQ	#0,D0
	RTS

; D0.B BCD: D0.L binary
CdFromBcd:
	MOVE.L	D1,-(SP)
	AND.L	#$FF,D0
	MOVE.L	D0,D1
	LSR.B	#4,D1
	MULU	#10,D1
	AND.B	#$0F,D0
	ADD.L	D1,D0
	MOVE.L	(SP)+,D1
	RTS

; D0 (0-99): D0.B BCD
CdBcd:	MOVE.L	D1,-(SP)
	AND.L	#$FFFF,D0
	DIVU	#10,D0
	MOVE.L	D0,D1
	SWAP	D1
	LSL.B	#4,D0
	OR.B	D1,D0
	MOVE.L	(SP)+,D1
	RTS

; D0 = sectors: three BCD bytes (minutes, seconds, frames) to (A1)+
CdMsf:	MOVEM.L	D1-D2,-(SP)
	MOVE.L	D0,D2
	DIVU.L	#75,D2			; D2 = seconds in all
	MOVE.L	D2,D1
	MULU.L	#75,D1
	SUB.L	D1,D0			; frames
	MOVE.L	D0,-(SP)
	MOVE.L	D2,D0
	DIVU.L	#60,D0			; minutes
	MOVE.L	D0,D1
	MULU.L	#60,D1
	SUB.L	D1,D2			; seconds
	BSR	CdBcd
	MOVE.B	D0,(A1)+
	MOVE.L	D2,D0
	BSR	CdBcd
	MOVE.B	D0,(A1)+
	MOVE.L	(SP)+,D0
	BSR	CdBcd
	MOVE.B	D0,(A1)+
	MOVEM.L	(SP)+,D1-D2
	RTS

; Seek time (Mesen's PceCdSeekDelay, from the seektime.c measurements). D0 = from, D1 = to:
; D0 = master clocks. Track gaps in hundredths.
CdGroup:				; D0 = LBA: D0 = zone 0-13
	MOVEM.L	D1/A0,-(SP)
	LEA	CdSeekTab,A0
	MOVEQ	#0,D1
.l:	CMP.L	2(A0),D0
	BCS.S	.n
	CMP.L	6(A0),D0
	BLS.S	.f
.n:	LEA	12(A0),A0
	ADDQ.W	#1,D1
	CMP.W	#14,D1
	BNE.S	.l
	MOVEQ	#0,D1
.f:	MOVE.L	D1,D0
	MOVEM.L	(SP)+,D1/A0
	RTS

CdSeekMC:
	MOVEM.L	D1-D7/A0-A1,-(SP)
	MOVE.L	D0,D2			; start
	MOVE.L	D1,D3			; target
	BSR	CdGroup
	MOVE.L	D0,D4			; source zone
	MOVE.L	D3,D0
	BSR	CdGroup
	MOVE.L	D0,D5			; target zone
	LEA	CdSeekTab,A0
	MOVE.L	D4,D0
	MULU	#12,D0
	LEA	(A0,D0.L),A1		; A1 source zone
	MOVE.L	D5,D0
	MULU	#12,D0
	ADD.L	D0,A0			; A0 target zone
	MOVE.L	D3,D6			; lba gap
	SUB.L	D2,D6
	BPL.S	.g
	NEG.L	D6
.g:	CMP.L	D4,D5
	BNE.S	.diff
	MOVE.L	D6,D7			; same zone
	MOVEQ	#0,D0
	MOVE.W	(A0),D0
	DIVU.L	D0,D7
	MULU.L	#100,D7
	BRA.S	.ms
.diff:	BLS.S	.down
	MOVE.L	6(A1),D7		; outwards: to the end of the source zone, from the start of the target
	SUB.L	D2,D7
	MOVEQ	#0,D0
	MOVE.W	(A1),D0
	DIVU.L	D0,D7
	MOVE.L	D3,D1
	SUB.L	2(A0),D1
	MOVE.W	(A0),D0
	DIVU.L	D0,D1
	ADD.L	D1,D7
	MULU.L	#100,D7
	MOVE.L	D5,D0
	SUB.L	D4,D0
	BRA.S	.zones
.down:	MOVE.L	D2,D7
	SUB.L	2(A1),D7
	MOVEQ	#0,D0
	MOVE.W	(A1),D0
	DIVU.L	D0,D7
	MOVE.L	6(A0),D1
	SUB.L	D3,D1
	MOVE.W	(A0),D0
	DIVU.L	D0,D1
	ADD.L	D1,D7
	MULU.L	#100,D7
	MOVE.L	D4,D0
	SUB.L	D5,D0
.zones:	SUBQ.L	#1,D0
	MULU.L	#160648,D0
	ADD.L	D0,D7
.ms:	MOVEQ	#0,D1			; D1 = rotation / 2 (hundredths of a ms)
	MOVE.W	10(A0),D1
	LSR.L	#1,D1
	MOVE.L	#15000,D0		; 9 frames
	CMP.L	#2,D6
	BCS.S	.done
	ADD.L	D1,D0
	CMP.L	#5,D6
	BCS.S	.done
	MOVE.L	#30000,D0		; 18 frames
	ADD.L	D1,D0
	CMP.L	#8000,D7
	BLS.S	.done
	MOVE.L	#36600,D0		; 22 frames
	ADD.L	D1,D0
	CMP.L	#16000,D7
	BLS.S	.done
	CMP.L	#64400,D7
	BHI.S	.far
	MOVE.L	D7,D1
	SUB.L	#16100,D1
	BCC.S	.p
	MOVEQ	#0,D1
.p:	MULU.L	#1666,D1
	DIVU.L	#8000,D1
	ADD.L	D1,D0
	BRA.S	.done
.far:	MOVE.L	D7,D1			; 48 frames + the rest
	SUB.L	#64400,D1
	DIVU.L	#10,D1
	MULU.L	#1666,D1
	DIVU.L	#1950,D1
	MOVE.L	#80000,D0
	ADD.L	D1,D0
.done:	DIVU.L	#100,D0			; whole ms
	MULU.L	#CD_MCMS,D0
	MOVEM.L	(SP)+,D1-D7/A0-A1
	RTS

CdSeekTab:	; sectors a turn.W, first.L, last.L, turn time (hundredths of a ms).W
	DC.W	10
	DC.L	0,12572
	DC.W	13347
	DC.W	11
	DC.L	12573,30244
	DC.W	14682
	DC.W	12
	DC.L	30245,49523
	DC.W	16017
	DC.W	13
	DC.L	49524,70408
	DC.W	17351
	DC.W	14
	DC.L	70409,92900
	DC.W	18686
	DC.W	15
	DC.L	92901,116998
	DC.W	20021
	DC.W	16
	DC.L	116999,142703
	DC.W	21356
	DC.W	17
	DC.L	142704,170014
	DC.W	22690
	DC.W	18
	DC.L	170015,198932
	DC.W	24025
	DC.W	19
	DC.L	198933,229456
	DC.W	25360
	DC.W	20
	DC.L	229457,261587
	DC.W	26695
	DC.W	21
	DC.L	261588,295324
	DC.W	28029
	DC.W	22
	DC.L	295325,330668
	DC.W	29364
	DC.W	23
	DC.L	330669,333012
	DC.W	30699

; -------------------------------------------------------------------
; ADPCM (silent): the RAM, pointers, length counter, half/end flags and DMA from the drive.
AdHalfOn:
	TST.B	AdHalf
	BNE.S	AdNo
	ST	AdHalf
	MOVEQ	#CI_ADPCM,D1
	BRA	CdSetIrq
AdHalfOff:
	TST.B	AdHalf
	BEQ.S	AdNo
	SF	AdHalf
	MOVEQ	#CI_ADPCM,D1
	BRA	CdClrIrq
AdEndOn:
	TST.B	AdEnd
	BNE.S	AdNo
	ST	AdEnd
	MOVEQ	#CI_STOP,D1
	BRA	CdSetIrq
AdEndOff:
	TST.B	AdEnd
	BEQ.S	AdNo
	SF	AdEnd
	MOVEQ	#CI_STOP,D1
	BRA	CdClrIrq
AdNo:	RTS

AdReset:
	SF	AdPReq
	CLR.W	AdRead
	CLR.W	AdWrite
	CLR.W	AdAddr
	BSR	AdEndOff
	BSR	AdHalfOff
	CLR.L	AdLen
	SF	AdNib
	IFEQ	CdSndOff
	MOVE.W	#2048,AdOut		; the decoder reset with it
	CLR.W	AdMag
	ENDC
	RTS

AdFlags:				; length latch, reset
	BTST	#4,AdCtl
	BEQ.S	.nl
	MOVEQ	#0,D0
	MOVE.W	AdAddr,D0
	MOVE.L	D0,AdLen
	BSR	AdEndOff
.nl:	TST.B	AdCtl
	BMI	AdReset
	RTS

; D0.B = the byte: to ADPCM RAM at the write pointer
AdWriteByte:
	MOVEQ	#0,D1
	MOVE.W	AdWrite,D1
	LEA	AdRam,A0
	MOVE.B	D0,(A0,D1.L)
	ADDQ.W	#1,AdWrite
	TST.L	AdLen
	BNE.S	.ne
	BSR	AdEndOn
.ne:	CMP.L	#$8000,AdLen
	BCC.S	.ho
	BSR	AdHalfOn
	BRA.S	.l
.ho:	BSR	AdHalfOff
.l:	BTST	#4,AdCtl
	BNE.S	.x
	MOVE.L	AdLen,D0
	ADDQ.L	#1,D0
	AND.L	#$1FFFF,D0
	MOVE.L	D0,AdLen
.x:	RTS

; One ADPCM sample time (Mesen's PlaySample without the sound)
AdSample:
	MOVE.B	AdCtl,D0
	BPL.S	.nr
	BTST	#5,D0
	SNE	AdPlay
	SF	AdPReq
	RTS
.nr:	BTST	#6,D0
	BEQ.S	.a
	TST.L	AdLen
	IFEQ	CdSndOff|NO_ADSTART
	BEQ	.stop
	ELSE
	BEQ.S	.stop
	ENDC
.a:	BTST	#5,D0
	IFEQ	CdSndOff|NO_ADSTART
	BEQ	.stop
	ELSE
	BEQ.S	.stop
	ENDC
	TST.B	AdPlay
	BNE.S	.go
	TST.B	AdPReq
	BEQ.S	.stop
.go:	TST.B	AdPReq
	BEQ.S	.p
	SF	AdPReq
	ST	AdPlay
	IFEQ	CdSndOff|NO_ADSTART
	MOVE.W	#2048,AdOut		; a clip starts from the centre (Mesen's PlaySample)
	CLR.W	AdMag
	ENDC
.p:	NOT.B	AdNib
	IFEQ	CdSndOff
	BSR	AdDecode
	TST.B	AdNib
	ENDC
	BNE.S	.hi
	ADDQ.W	#1,AdRead		; low nibble: the next byte
	MOVE.L	AdLen,D0
	SUBQ.L	#1,D0
	AND.L	#$1FFFF,D0
	MOVE.L	D0,AdLen
.hi:	CMP.L	#$8000,AdLen
	BHI.S	.ho
	BSR	AdHalfOn
	BRA.S	.e
.ho:	BSR	AdHalfOff
.e:	TST.L	AdLen
	BNE.S	.x
	BRA	AdEndOn
.stop:	SF	AdPReq
	SF	AdPlay
.x:	RTS

; DMA from the drive to ADPCM RAM: what the drive has, at once.
AdDmaRun:
.l:	MOVE.B	ScSig,D0
	AND.B	#SC_ACK|SC_CD|SC_IO|SC_REQ,D0
	CMP.B	#SC_IO|SC_REQ,D0
	BNE.S	.x
	BSR	ScGetData
	BSR	AdWriteByte
	TST.L	ScBufLeft
	BNE.S	.r
	BCLR	#0,AdDma		; the block ends: bit 0 off, bit 1 stays
.r:	BSR	ScAutoAck
	BRA.S	.l
.x:	RTS

AdLine:
	BSR	AdFlags
	TST.B	AdPlay
	BNE.S	.run
	TST.B	AdPReq
	BNE.S	.run
	BTST	#5,AdCtl
	BEQ.S	.np
.run:	MOVE.L	AdClk,D0
	ADD.L	#CD_MCLINE,D0
.l:	CMP.L	AdCPS,D0
	BCS.S	.s
	SUB.L	AdCPS,D0
	MOVE.L	D0,-(SP)
	BSR	AdSample
	IFEQ	CdSndOff
	BSR	AdCap
	ENDC
	MOVE.L	(SP)+,D0
	BRA.S	.l
.s:	MOVE.L	D0,AdClk
	IFEQ	CdSndOff
	BRA.S	.dma
.np:	MOVE.L	AdCapClk,D0		; not playing: silence at the same rate
	ADD.L	#CD_MCLINE,D0
.il:	CMP.L	AdCPS,D0
	BCS.S	.is
	SUB.L	AdCPS,D0
	BSR	AdCap0
	BRA.S	.il
.is:	MOVE.L	D0,AdCapClk
.dma:
	ELSE
.np:
	ENDC
	MOVE.B	AdDma,D0
	AND.B	#3,D0
	BEQ.S	.nd
	BSR	AdDmaRun
.nd:	BRA	AdFlags

; -------------------------------------------------------------------
; CD audio (silent): position, end modes and their IRQ, the sub-code IRQ every 6 samples.
AuLine:
	MOVE.L	AuClk,D0
	ADD.L	#CD_MCLINE,D0
.l:	CMP.L	#487,D0
	BLS.S	.s
	SUB.L	#487,D0
	MOVE.L	D0,-(SP)
	BSR	AuTick
	MOVE.L	(SP)+,D0
	BRA.S	.l
.s:	MOVE.L	D0,AuClk
	RTS

AuTick:
	IFEQ	CdSndOff
	BSR	AuCap
	ENDC
	ADDQ.B	#1,AuIrqC
	CMP.B	#6,AuIrqC
	BCS.S	.ni
	CLR.B	AuIrqC
	MOVEQ	#CI_SUB,D1
	BSR	CdSetIrq
.ni:	MOVE.L	AuSeek,D0
	BEQ.S	.play
	CMP.L	#487,D0
	BHI.S	.dec
	CLR.L	AuSeek
	MOVEQ	#1,D1			; seek done: the audio starts, status good
	BRA	ScGood
.dec:	SUB.L	#487,AuSeek
	RTS
.play:	TST.B	AuStat
	BNE.S	.x
	ADDQ.W	#1,AuSmp
	CMP.W	#588,AuSmp
	BNE.S	.x
	CLR.W	AuSmp
	ADDQ.L	#1,AuSector
	MOVE.L	AuSector,D0
	CMP.L	AuEnd,D0
	BLS.S	.x
	CMP.L	CdSecs,D0
	BCS.S	.in
	MOVE.L	CdSecs,D0
	SUBQ.L	#1,D0
	MOVE.L	D0,AuSector
.in:	MOVE.B	AuEndB,D0
	CMP.B	#AE_LOOP,D0
	BNE.S	.nl
	MOVE.L	AuStart,AuSector
	RTS
.nl:	MOVE.B	#AU_STOP,AuStat
	CMP.B	#AE_IRQ,D0
	BNE.S	.x
	MOVEQ	#1,D1
	BRA	ScGood
.x:	RTS

	IFEQ	CdSndOff
; -------------------------------------------------------------------
; Sound. Emulated time decides what is heard: CD audio and ADPCM samples are
; captured as the emulated drive plays them (AuTick, AdLine), and once a PCE frame
; PSGMixFrame stretches them to its block (CdMixFrame). Nothing here changes the
; emulation: positions, lengths and IRQs are as in stage (a).

; Every other 44.1 kHz tick: the sample at the play position, or silence. Uses D0-D2/A0.
AuCap:	NOT.B	AuPar
	BNE	.x
	MOVEQ	#0,D1
	TST.L	AuSeek
	BNE.S	.put
	TST.B	AuStat			; AU_PLAY = 0
	BNE.S	.put
	IFNE	CdDbg
	ADDQ.L	#1,CdDbgP
	ENDC
	MOVE.L	AuSector,D0
	CMP.L	AuTFirst,D0
	BCS.S	.find
	CMP.L	AuTLast,D0
	BLS.S	.have
.find:	BSR	AuFind
.have:	MOVE.L	AuTRam,D2
	BEQ.S	.put
	SUB.L	AuTFirst,D0
	MULU.L	#CD_ASEC,D0
	ADD.L	D0,D2
	MOVEQ	#0,D0
	MOVE.W	AuSmp,D0
	LSR.W	#1,D0
	MOVE.L	D2,A0
	MOVE.L	(A0,D0.L*4),D1
	IFNE	CdDbg
	TST.L	D1
	BEQ.S	.put
	ADDQ.L	#1,CdDbgN
	ENDC
.put:	MOVE.W	AuCapN,D2
	CMP.W	#CD_CAPMAX,D2
	BCC.S	.x
	ADDQ.W	#1,AuCapN
	LEA	AuCapB+4,A0
	MOVE.L	D1,(A0,D2.W*4)
.x:	RTS

; D0 = LBA (kept): AuTFirst, AuTLast, AuTRam for the audio track around it, or
; that sector alone, silent.
AuFind:	MOVE.L	D0,-(SP)
	BSR	CdGetTrack
	MOVE.L	(SP)+,D0
	TST.L	D1
	BMI.S	.none
	TST.B	TRK_TYPE(A0)
	BNE.S	.none
	CMP.L	TRK_LAST(A0),D0
	BHI.S	.none
	MOVE.L	TRK_START(A0),AuTFirst
	MOVE.L	TRK_LAST(A0),AuTLast
	MOVE.L	TRK_ARAM(A0),AuTRam
	RTS
.none:	MOVE.L	D0,AuTFirst
	MOVE.L	D0,AuTLast
	CLR.L	AuTRam
	RTS

; The nibble AdSample just took (AdNib $FF: the high one, first) through the
; MSM5205: AdOut 0-4095 (held at the ends), AdMag 0-48. Uses D1-D4/A0.
AdDecode:
	MOVEQ	#0,D1
	MOVE.W	AdRead,D1
	LEA	AdRam,A0
	MOVE.B	(A0,D1.L),D1
	TST.B	AdNib
	BEQ.S	.lo
	LSR.B	#4,D1
.lo:	AND.W	#$000F,D1
	MOVE.W	AdMag,D2
	LEA	AdStepT(PC),A0
	MOVE.W	(A0,D2.W*2),D3		; step
	MOVE.W	D3,D4
	LSR.W	#3,D4			; step / 8
	BTST	#2,D1
	BEQ.S	.b1
	ADD.W	D3,D4
.b1:	LSR.W	#1,D3
	BTST	#1,D1
	BEQ.S	.b0
	ADD.W	D3,D4
.b0:	LSR.W	#1,D3
	BTST	#0,D1
	BEQ.S	.bs
	ADD.W	D3,D4
.bs:	BTST	#3,D1
	BEQ.S	.add
	NEG.W	D4
.add:	ADD.W	AdOut,D4
	BPL.S	.np
	MOVEQ	#0,D4
.np:	CMP.W	#4095,D4
	BLS.S	.nh
	MOVE.W	#4095,D4
.nh:	MOVE.W	D4,AdOut
	AND.W	#7,D1
	LEA	AdMagT(PC),A0
	ADD.B	(A0,D1.W),D2
	BPL.S	.mp
	MOVEQ	#0,D2
.mp:	CMP.W	#48,D2
	BLS.S	.mh
	MOVEQ	#48,D2
.mh:	MOVE.W	D2,AdMag
	RTS
AdStepT:
	DC.W	16,17,19,21,23,25,28,31,34,37,41,45,50,55,60,66,73,80,88,97,107,118,130,143,157
	DC.W	173,190,209,230,253,279,307,337,371,408,449,494,544,598,658,724,796,876,963
	DC.W	1060,1166,1282,1411,1552
AdMagT:	DC.B	-1,-1,-1,-1,2,4,6,8

; One ADPCM sample time: its output (centred), or silence. Uses D1-D2/A0.
AdCap:	MOVE.W	AdOut,D1
	SUB.W	#2048,D1
	TST.B	AdPlay
	BNE.S	AdCapPut
AdCap0:	MOVEQ	#0,D1
AdCapPut:
	IFNE	CdDbg
	TST.W	D1
	BEQ.S	.z
	ADDQ.L	#1,CdDbgD
.z:
	ENDC
	MOVE.W	AdCapN,D2
	CMP.W	#CD_CAPMAX,D2
	BCC.S	.x
	ADDQ.W	#1,AdCapN
	LEA	AdCapB+2,A0
	MOVE.W	D1,(A0,D2.W*2)
.x:	RTS

; PSGMixFrame, after its unpack (MixBuf: MixN pairs of L, R words): this frame's
; CD audio and ADPCM added, each stretched from its captured samples to the block
; (linear, from the last sample of the frame before), with the fader. CD audio at
; half scale, ADPCM's 12 bits at half scale; the sums held at 16 bits.
CdMixFrame:
	MOVEM.L	D0-D7/A0-A2,-(SP)
	IFNE	AdDump
	BSR	AdDumpFrame
	ENDC
	MOVE.W	#256,CdVolC
	MOVE.W	#256,CdVolA
	MOVE.B	CdFader,D0
	BTST	#3,D0
	BEQ.S	.vol
	MOVE.W	CdFadeT,D1		; frames since the fader write
	CMP.W	#400,D1
	BCC.S	.f0
	ADDQ.W	#1,CdFadeT
.f0:	MULU.W	#256,D1
	MOVE.W	#360,D2			; slow: 6 s
	BTST	#2,D0
	BEQ.S	.f1
	MOVE.W	#150,D2			; fast: 2.5 s
.f1:	DIVU.W	D2,D1
	MOVE.W	#256,D3
	SUB.W	D1,D3
	BPL.S	.f2
	MOVEQ	#0,D3
.f2:	BTST	#1,D0
	BNE.S	.fa
	MOVE.W	D3,CdVolC
	BRA.S	.vol
.fa:	MOVE.W	D3,CdVolA
.vol:	MOVE.W	AuCapN,D5
	BEQ.S	.ad
	LEA	AuCapB,A1
	BSR	CdMixCd
	MOVE.L	(A1,D5.W*4),(A1)	; the last one leads the next frame
	CLR.W	AuCapN
.ad:	MOVE.W	AdCapN,D5
	BEQ.S	.x
	LEA	AdCapB,A1
	BSR	CdMixAd
	MOVE.W	(A1,D5.W*2),(A1)
	CLR.W	AdCapN
.x:	MOVEM.L	(SP)+,D0-D7/A0-A2
	RTS

; D5 = samples, A1 = them (index 0 the last of the frame before): D4 = step, D3 =
; the first position, 16.16. D7 = MixN - 1, A0 = MixBuf.
CdMixStep:
	MOVEQ	#0,D0
	MOVE.W	D5,D0
	SWAP	D0
	MOVEQ	#0,D1
	MOVE.W	MixN,D1
	DIVU.L	D1,D0
	MOVE.L	D0,D4
	MOVE.L	D0,D3
	LEA	MixBuf,A0
	MOVE.W	MixN,D7
	SUBQ.W	#1,D7
	RTS

; D3 = position: D0 = sample index (0..D5-1), D1.L = fraction, 15 bits.
CdMixPos	MACRO
	MOVE.L	D3,D0
	CLR.W	D0
	SWAP	D0
	MOVEQ	#0,D1
	MOVE.W	D3,D1
	LSR.W	#1,D1
	CMP.W	D5,D0
	BCS.S	\@
	MOVE.W	D5,D0
	SUBQ.W	#1,D0
	MOVE.W	#$7FFF,D1
\@:
	ENDM

; D0.L = value to add to the word at (A0)+, held at 16 bits. Uses D2.
CdMixAdd	MACRO
	MOVE.W	(A0),D2
	EXT.L	D2
	ADD.L	D2,D0
	CMP.L	#32767,D0
	BLE.S	\@a
	MOVE.W	#32767,D0
	BRA.S	\@b
\@a:	CMP.L	#-32768,D0
	BGE.S	\@b
	MOVE.W	#-32768,D0
\@b:	MOVE.W	D0,(A0)+
	ENDM

; One side: \1 = offset of a, D1 = fraction, A2 = the pair -> D0 at the volume.
CdMixSide	MACRO
	MOVE.W	\1(A2),D0
	EXT.L	D0
	MOVE.W	\1+4(A2),D2
	EXT.L	D2
	SUB.L	D0,D2
	MULS.L	D1,D2
	ASR.L	#8,D2
	ASR.L	#7,D2
	ADD.L	D2,D0
	MULS.L	D6,D0
	ASR.L	#8,D0
	ASR.L	#1,D0
	ENDM

CdMixCd:
	BSR	CdMixStep
	MOVEQ	#0,D6
	MOVE.W	CdVolC,D6
	BEQ	CdMixCdX
	MULU.W	CdMusLvl,D6		; the CD music level (512 = the disc's own level)
	LSR.L	#8,D6
CdMixCdL:	CdMixPos
	LEA	(A1,D0.W*4),A2
	CdMixSide 0
	CdMixAdd
	CdMixSide 2
	CdMixAdd
	ADD.L	D4,D3
	DBF	D7,CdMixCdL
CdMixCdX:	RTS

CdMixAd:
	BSR	CdMixStep
	MOVEQ	#0,D6
	MOVE.W	CdVolA,D6
	BEQ	CdMixAdX
CdMixAdL:	CdMixPos
	LEA	(A1,D0.W*2),A2
	MOVE.W	(A2),D0
	EXT.L	D0
	MOVE.W	2(A2),D2
	EXT.L	D2
	SUB.L	D0,D2
	MULS.L	D1,D2
	ASR.L	#8,D2
	ASR.L	#7,D2
	ADD.L	D2,D0
	MULS.L	D6,D0
	IFEQ	AdGain-8
	ASR.L	#5,D0			; 2048 * 256 / 32 = 16384
	ELSE
	MULS.L	#AdGain,D0		; (sample - 2048) x AdGain
	ASR.L	#8,D0
	ENDC
	MOVE.L	D0,-(SP)
	CdMixAdd
	MOVE.L	(SP)+,D0
	CdMixAdd
	ADD.L	D4,D3
	DBF	D7,CdMixAdL
CdMixAdX:	RTS

	IFNE	AdDump
; Test builds: a record a PCE frame (24 bytes: AutoFrames.l, AdRead, AdOut, AdMag, AdPlay.b, AdNib.b,
; AdRate.b, AdCtl.b, AdLen.l, AuCapN, AdCapN, MixN), then the frame's AdCapN ADPCM samples.
AdDumpFrame:
	MOVE.L	AdDumpPtr,A1
	MOVEQ	#0,D0
	MOVE.W	AdCapN,D0
	MOVE.L	D0,D1
	ADD.L	D1,D1
	ADD.L	#24,D1
	ADD.L	A1,D1
	CMP.L	#AdDumpEnd,D1
	BCC.S	.x
	MOVE.L	AutoFrames,(A1)+
	MOVE.W	AdRead,(A1)+
	MOVE.W	AdOut,(A1)+
	MOVE.W	AdMag,(A1)+
	MOVE.B	AdPlay,(A1)+
	MOVE.B	AdNib,(A1)+
	MOVE.B	AdRate,(A1)+
	MOVE.B	AdCtl,(A1)+
	MOVE.L	AdLen,(A1)+
	MOVE.W	AuCapN,(A1)+
	MOVE.W	D0,(A1)+
	MOVE.W	MixN,(A1)+
	LEA	AdCapB+2,A0
	BRA.S	.c
.l:	MOVE.W	(A0)+,(A1)+
.c:	DBF	D0,.l
	MOVE.L	A1,AdDumpPtr
.x:	RTS
AdDumpWrite:				; OS alive again
	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.L	$4.W,A6
	LEA	AutoDosName,A1
	MOVEQ	#0,D0
	JSR	-$228(A6)		; OpenLibrary
	TST.L	D0
	BEQ.S	.x
	MOVE.L	D0,A6
	MOVE.L	#AdDumpName,D1
	MOVE.L	#1006,D2		; MODE_NEWFILE
	JSR	-30(A6)			; Open
	MOVE.L	D0,D4
	BEQ.S	.cl
	MOVE.L	D4,D1
	MOVE.L	#AdDumpBuf,D2
	MOVE.L	AdDumpPtr,D3
	SUB.L	D2,D3
	JSR	-48(A6)			; Write
	MOVE.L	D4,D1
	JSR	-36(A6)			; Close
.cl:	MOVE.L	A6,A1
	MOVE.L	$4.W,A6
	JSR	-$19E(A6)		; CloseLibrary
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
AdDumpName:	DC.B	"PROGDIR:AmiPCE.adp",0
	EVEN
AdDumpPtr:	DC.L	AdDumpBuf
	ENDC

	IFNE	CdDbg
CdDbgP:	DC.L	0		; AuCap calls while playing
CdDbgN:	DC.L	0		; CD samples not silent
CdDbgD:	DC.L	0		; ADPCM samples not silent
	ENDC
CdVolC:	DC.W	256
CdMusLvl:	DC.W	CdMusDef	; CD music in the mix: 512 = full scale (as on the disc), 256 = half; CDMUSIC= sets it
CdVolA:	DC.W	256

; CdMusVal: A0 = the ToolType / CLI value of CDMUSIC=, a percentage of the disc's own level (0-400) ->
; CdMusLvl. No digits: no change.
CdMusVal:
	MOVEM.L	D0-D1/A0,-(SP)
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	CMP.B	#'0',(A0)
	BCS.S	.x
	CMP.B	#'9',(A0)
	BHI.S	.x
.d:	MOVE.B	(A0)+,D1
	SUB.B	#'0',D1
	BCS.S	.e
	CMP.B	#9,D1
	BHI.S	.e
	MULU.W	#10,D0
	ADD.L	D1,D0
	CMP.L	#400,D0
	BLS.S	.d
	MOVE.L	#400,D0
.e:	MULU.W	#512,D0
	DIVU.W	#100,D0
	MOVE.W	D0,CdMusLvl
.x:	MOVEM.L	(SP)+,D0-D1/A0
	RTS

; CdMusCli: A0 = the CLI arguments; CDMUSIC=value anywhere (any case).
CdMusCli:
	MOVEM.L	D0-D1/A0-A2,-(SP)
.s:	TST.B	(A0)
	BEQ.S	.x
	MOVE.L	A0,A1
	LEA	CdMusCliNom,A2
.c:	MOVE.B	(A2)+,D1
	BEQ.S	.hit
	MOVE.B	(A1)+,D0
	CMP.B	#97,D0
	BCS.S	.c1
	CMP.B	#122,D0
	BHI.S	.c1
	SUB.B	#32,D0
.c1:	CMP.B	D1,D0
	BEQ.S	.c
	ADDQ.L	#1,A0
	BRA.S	.s
.hit:	MOVE.L	A1,A0
	BSR	CdMusVal
.x:	MOVEM.L	(SP)+,D0-D1/A0-A2
	RTS
CdMusTTNom:	DC.B	"CDMUSIC",0
CdMusCliNom:	DC.B	"CDMUSIC=",0
	EVEN

; -------------------------------------------------------------------
; The disc's CD audio into RAM (menu, OS alive), after CdLoadData: each audio track
; in its own block, two 44.1 kHz pairs averaged to one, little- to big-endian.
; What doesn't fit stays silent; no error.
; CdLoadAll: the data tracks into CdMem (2048 bytes a sector) and the CD audio into RAM (what fits;
; the tracks after the first that doesn't fit stay silent). Each file is read once from its start to
; its end, never with Seek: on a network volume a Seek can cost as much as reading up to the new place.
; EQ ok; NE with A0 = error.
CdLoadAll:
	MOVEQ	#0,D7			; data RAM needed
	CLR.W	CdProgN
	CLR.W	CdProgM
	LEA	CdTrk,A3
	MOVE.W	CdTracks,D5
	SUBQ.W	#1,D5
.sz:	CLR.L	TRK_ARAM(A3)
	TST.B	TRK_TYPE(A3)
	BEQ.S	.sza
	MOVE.L	D7,TRK_RAM(A3)
	MOVE.L	TRK_LAST(A3),D0
	SUB.L	TRK_START(A3),D0
	ADDQ.L	#1,D0
	MOVEQ	#11,D1
	LSL.L	D1,D0
	ADD.L	D0,D7
	BRA.S	.szn
.sza:	ADDQ.W	#1,CdProgM		; audio tracks, for the menu's count
.szn:	LEA	TRK_SIZE(A3),A3
	DBF	D5,.sz
	TST.L	D7
	BEQ	.nodata
	MOVE.L	D7,CdMemSize
	MOVE.L	D7,D0
	MOVEQ	#1,D1			; MEMF_PUBLIC (fast RAM first)
	MOVE.L	4.W,A6
	JSR	-$C6(A6)		; AllocMem
	MOVE.L	D0,CdMem
	BEQ	.mem
	IFEQ	NO_ARCADE
	TST.L	ArcRam			; the Arcade Card's RAM, before the CD audio takes what's left
	BNE.S	.arc
	MOVE.L	#ARC_SIZE,D0
	MOVEQ	#1,D1			; MEMF_PUBLIC (0: no card)
	JSR	-$C6(A6)		; AllocMem
	MOVE.L	D0,ArcRam
.arc:
	ENDC
	MOVE.L	#CdChunk,CdLBuf		; the read buffer: big reads (each one over a network costs)
	MOVE.L	#CdChunkSecs,CdLSecs
	MOVE.L	#CD_BIGSECS*2352,D0
	MOVEQ	#1,D1
	JSR	-$C6(A6)		; AllocMem
	TST.L	D0
	BEQ.S	.small
	MOVE.L	D0,CdLBuf
	MOVE.L	#CD_BIGSECS,CdLSecs
.small:	SF	CdANo			; set when the audio RAM runs out
	IFEQ	NO_CDMOFF
	TST.B	DirPrefs+$1E		; CD music off (Sound menu): no audio in RAM, the tracks silent
	SNE	CdANo
	ENDC
	MOVEQ	#0,D5			; D5 = file
.file:	CMP.W	CdFiles,D5
	BCC	.done
	MOVE.L	D5,D0
	BSR	CdMkPath
	MOVE.L	#CdPath,D1
	MOVE.L	#1005,D2
	JSR	OpenFile
	BEQ	.rerr
	CLR.L	CdFPos
	LEA	CdTrk,A3
	MOVE.W	CdTracks,D4
	SUBQ.W	#1,D4
.trk:	CMP.B	TRK_FILE(A3),D5		; the file's tracks, in order
	BNE	.tnext
	MOVE.L	TRK_LAST(A3),D6
	SUB.L	TRK_START(A3),D6
	ADDQ.L	#1,D6			; D6 = sectors
	TST.B	TRK_TYPE(A3)
	BNE	.dat
	TST.B	CdANo			; audio
	BNE	.tnext
	ADDQ.W	#1,CdProgN
	BSR	CdProg
	MOVE.L	D6,D0
	MULU.L	#CD_ASEC,D0
	MOVEQ	#1,D1			; MEMF_PUBLIC
	MOVE.L	4.W,A6
	JSR	-$C6(A6)		; AllocMem
	MOVE.L	D0,TRK_ARAM(A3)
	BNE.S	.aok
	ST	CdANo			; no more RAM: this track and the rest silent
	BRA	.tnext
.aok:	MOVE.L	D0,A5
	BSR	CdSkipTo
	BNE	.rclose
.ard:	MOVE.L	D6,D3
	CMP.L	CdLSecs,D3
	BLS.S	.a1
	MOVE.L	CdLSecs,D3
.a1:	SUB.L	D3,D6
	MOVE.L	D3,-(SP)
	MULU.L	#2352,D3
	ADD.L	D3,CdFPos
	MOVE.L	CdLBuf,D2
	JSR	ReadFile
	MOVEM.L	(SP)+,D3		; (flags kept)
	BNE	.rclose
	MOVE.L	CdLBuf,A0
	MULU.L	#294,D3
	SUBQ.L	#1,D3
.cv:	MOVE.W	(A0)+,D0		; L, R, L, R little-endian -> (L+L)/2, (R+R)/2
	ROL.W	#8,D0
	EXT.L	D0
	MOVE.W	(A0)+,D1
	ROL.W	#8,D1
	EXT.L	D1
	MOVE.W	(A0)+,D2
	ROL.W	#8,D2
	EXT.L	D2
	ADD.L	D2,D0
	ASR.L	#1,D0
	MOVE.W	(A0)+,D2
	ROL.W	#8,D2
	EXT.L	D2
	ADD.L	D2,D1
	ASR.L	#1,D1
	MOVE.W	D0,(A5)+
	MOVE.W	D1,(A5)+
	SUBQ.L	#1,D3
	BPL.S	.cv
	TST.L	D6
	BNE.S	.ard
	BRA	.tnext
.dat:	MOVE.L	CdMem,A5		; a data track
	ADD.L	TRK_RAM(A3),A5
	BSR	CdSkipTo
	BNE	.rclose
	CMP.B	#2,TRK_TYPE(A3)
	BNE.S	.raw
	MOVE.L	D6,D3			; 2048-byte sectors: straight in
	MOVEQ	#11,D0
	LSL.L	D0,D3
	ADD.L	D3,CdFPos
	MOVE.L	A5,D2
	JSR	ReadFile
	BNE	.rclose
	BRA.S	.tnext
.raw:	MOVE.L	D6,D3			; 2352: the 2048 user bytes at +16
	CMP.L	CdLSecs,D3
	BLS.S	.c1
	MOVE.L	CdLSecs,D3
.c1:	SUB.L	D3,D6
	MOVE.L	D3,-(SP)
	MULU.L	#2352,D3
	ADD.L	D3,CdFPos
	MOVE.L	CdLBuf,D2
	JSR	ReadFile
	MOVEM.L	(SP)+,D3		; (flags kept)
	BNE	.rclose
	MOVE.L	CdLBuf,A0
	LEA	16(A0),A0
	SUBQ.L	#1,D3
.cs:	MOVE.W	#2048/16-1,D0
	MOVE.L	A0,A1
.cw:	MOVE.L	(A1)+,(A5)+
	MOVE.L	(A1)+,(A5)+
	MOVE.L	(A1)+,(A5)+
	MOVE.L	(A1)+,(A5)+
	DBF	D0,.cw
	ADD.W	#2352,A0
	DBF	D3,.cs
	TST.L	D6
	BNE.S	.raw
.tnext:	LEA	TRK_SIZE(A3),A3
	DBF	D4,.trk
	JSR	CloseFile
	ADDQ.W	#1,D5
	BRA	.file
.done:	BSR	CdLBufFree
	MOVEQ	#0,D0
	RTS
.rclose:
	JSR	CloseFile
.rerr:	BSR	CdLBufFree
	LEA	tErCdRead,A0
	MOVEQ	#-1,D0
	RTS
.mem:	LEA	tErCdMem,A0
	MOVEQ	#-1,D0
	RTS
.nodata:
	LEA	tErCdData,A0
	MOVEQ	#-1,D0
	RTS

; CdSkipTo: the open file on to TRK_FOFF(A3) by reading (forward; a Seek only to go back). NE = error.
CdSkipTo:
	MOVEM.L	D0-D3/D6/A0-A1/A6,-(SP)
	MOVE.L	TRK_FOFF(A3),D6
	SUB.L	CdFPos,D6		; bytes to pass over
	BEQ.S	.ok
	BCS.S	.back
.lp:	MOVE.L	CdLSecs,D0
	MULU.L	#2352,D0
	MOVE.L	D6,D3
	CMP.L	D0,D3
	BLS.S	.r
	MOVE.L	D0,D3
.r:	SUB.L	D3,D6
	ADD.L	D3,CdFPos
	MOVE.L	CdLBuf,D2
	JSR	ReadFile
	BNE.S	.x
	TST.L	D6
	BNE.S	.lp
.ok:	MOVEQ	#0,D0
.x:	MOVEM.L	(SP)+,D0-D3/D6/A0-A1/A6	; (flags kept)
	RTS
.back:	MOVE.L	TRK_FOFF(A3),D2		; backwards (not in a cue's own order): Seek
	MOVE.L	D2,CdFPos
	MOVE.L	DisBase,D1
	MOVEQ	#-1,D3			; OFFSET_BEGINNING
	MOVE.L	_DosBase,A6
	JSR	-66(A6)			; Seek
	TST.L	D0
	BPL.S	.ok
	MOVEQ	#1,D0
	BRA.S	.x

; CdLBufFree: the big read buffer back (CdChunk is in the program).
CdLBufFree:
	MOVEM.L	D0-D1/A0-A1/A6,-(SP)
	MOVE.L	CdLBuf,A1
	CMP.L	#CdChunk,A1
	BEQ.S	.x
	MOVE.L	#CD_BIGSECS*2352,D0
	MOVE.L	4.W,A6
	JSR	-$D2(A6)		; FreeMem
	MOVE.L	#CdChunk,CdLBuf
.x:	MOVEM.L	(SP)+,D0-D1/A0-A1/A6
	RTS

; The menu's Backup RAM line while the audio loads: "Loading CD audio n/m"
; (BramFind puts the line back after Insert). Only with the menu window open.
CdProg:
	IFEQ	NO_MENU2
	MOVEM.L	D0-D7/A0-A6,-(SP)
	TST.L	MainMenuWnd
	BEQ.S	.x
	LEA	tCdProg+17,A0
	MOVE.W	CdProgN,D0
	BSR.S	.two
	ADDQ.L	#1,A0
	MOVE.W	CdProgM,D0
	BSR.S	.two
	MOVE.L	#tCdProg,MainMenuText11+$C
	JSR	PrintCartTexts
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	ENDC
	RTS
	IFEQ	NO_MENU2
.two:	AND.L	#$FFFF,D0		; D0 (0-99) -> two digits at (A0)+
	DIVU	#10,D0
	ADD.B	#'0',D0
	MOVE.B	D0,(A0)+
	SWAP	D0
	ADD.B	#'0',D0
	MOVE.B	D0,(A0)+
	RTS
tCdProg:	DC.B	"Loading CD audio 00/00   ",0
	EVEN
	ENDC
CdProgN:	DC.W	0
CdProgM:	DC.W	0
	CNOP	0,4
CdLBuf:		DC.L	CdChunk
CdLSecs:	DC.L	CdChunkSecs
CdFPos:		DC.L	0		; CdLoadAll: the place in the open file
CdANo:		DC.B	0		; CdLoadAll: no more RAM for audio
		DC.B	0

; A3 = track: its audio block freed. Uses D0-D1/A0-A1/A6.
CdFreeTrack:
	MOVE.L	TRK_ARAM(A3),D0
	BEQ.S	.x
	MOVE.L	D0,A1
	MOVE.L	TRK_LAST(A3),D0
	SUB.L	TRK_START(A3),D0
	ADDQ.L	#1,D0
	MULU.L	#CD_ASEC,D0
	MOVE.L	4.W,A6
	JSR	-$D2(A6)		; FreeMem
	CLR.L	TRK_ARAM(A3)
.x:	RTS

CdFreeAudio:
	MOVEM.L	D0-D2/A0-A1/A3/A6,-(SP)
	LEA	CdTrk,A3
	MOVE.W	CdTracks,D2
	BEQ.S	.x
	SUBQ.W	#1,D2
.l:	BSR	CdFreeTrack
	LEA	TRK_SIZE(A3),A3
	DBF	D2,.l
.x:	MOVEM.L	(SP)+,D0-D2/A0-A1/A3/A6
	RTS
	ENDC

; -------------------------------------------------------------------
; Once a line (PCE_Start, after TimerLine).
	IFNE	CdLog
CdLogHdr:	MACRO
	LogString \1
	LogHexWord AutoFrames+2
	LogString " "
	ENDM
CdLogW:					; D0.W = register, (A4) = value
	MOVEM.L	D0-D7/A0-A6,-(SP)
	CMP.W	#$0A,D0			; not the ADPCM data port
	BEQ	CdLogX
	MOVE.W	D0,D2
	CdLogHdr "W "
	LogHexByte D2
	LogString "="
	LogHexByte (A4)
	LogEnter
CdLogX:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
CdLogR:					; CdLogOff = register, D0.B = value: only changes of $1800/$1802/$1803
	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.W	CdLogOff,D1
	CMP.W	#4,D1
	BCC	CdLogX
	CMP.W	#1,D1
	BEQ	CdLogX
	LEA	CdLogLast,A0
	CMP.B	(A0,D1.W),D0
	BEQ	CdLogX
	MOVE.B	D0,(A0,D1.W)
	MOVE.B	D0,D2
	CdLogHdr "R "
	LogHexByte D1
	LogString "="
	LogHexByte D2
	LogEnter
	BRA	CdLogX
CdLogC:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	CdLogHdr "C "
	LEA	ScCmd,A2
	MOVEQ	#9,D2
CdLogL:	MOVE.B	(A2)+,D0
	LogHexByte D0
	DBF	D2,CdLogL
	LogEnter
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
CdLogP:					; D0.B = new phase
	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.B	D0,D2
	CdLogHdr "P "
	LogHexByte D2
	LogEnter
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
CdLogB:					; BRK at A5-1: the first 24, with the MPRs
	MOVEM.L	D0-D7/A0-A6,-(SP)
	ADDQ.W	#1,CdLogBn
	CMP.W	#24,CdLogBn
	BHI	CdLogX
	MOVE.L	A5,D2
	SUB.W	(A2),D2
	SUBQ.W	#1,D2
	CdLogHdr "B "
	LogHexWord D2
	LogString " M:"
	LEA	Regs+TabMap,A2
	MOVEQ	#7,D3
CdLogBl:	MOVE.B	(A2)+,D0
	LogHexByte D0
	DBF	D3,CdLogBl
	LogString " S:"
	MOVE.B	D6,D0
	LogHexByte D0
	LogString " A5:"
	LogHexLong A5
	LogString " @:"
	LEA	-3(A5),A0
	MOVEQ	#5,D3
CdLogBb:	MOVE.B	(A0)+,D0
	LogHexByte D0
	DBF	D3,CdLogBb
	LogString " R6:"
	LogHexLong Regs+PagRead+6*4
	LogString " D1:"
	LogHexLong DirMappers+8
	LogString " C:"
	LogHexLong Regs+MapROMBase
	LogEnter
	BRA	CdLogX
CdLogBn:	DC.W	0
CdLogOff:	DC.W	0
CdLogLast:	DC.B	-1,-1,-1,-1
	EVEN
	ENDC

CdLine:
	TST.B	CdOn
	BEQ.S	.x
	MOVEM.L	D0-D4/A0-A1,-(SP)
	IFNE	CdLog
	BSR	ArcPcSample
	ENDC
	MOVE.L	ScUpdCnt,D0
	BEQ.S	.nu
	SUB.L	#CD_MCLINE,D0
	BGT.S	.uw
	CLR.L	ScUpdCnt
	BSR	ScDoUpd
	BRA.S	.nu
.uw:	MOVE.L	D0,ScUpdCnt
.nu:	MOVE.L	ScReadCnt,D0
	BEQ.S	.nr
	SUB.L	#CD_MCLINE,D0
	MOVE.L	D0,ScReadCnt
	BGT.S	.nr
	BSR	ScProcRead
.nr:	BSR	ScUpdate
	BSR	AdLine
	BSR	AuLine
	MOVEM.L	(SP)+,D0-D4/A0-A1
.x:	RTS

; Power ON with a disc in (PCE_SetCardtridge): the CD banks, the unit reset.
CdPowerOn:
	IFEQ	NO_ARCADE
	SF	ArcOn
	ENDC
	TST.B	CdOn
	BEQ	.x
	MOVEM.L	D0-D7/A0-A3,-(SP)
	LEA	Regs,A3
	LEA	CdRam,A0
	LEA	DirMappers+($80*8),A1
	MOVEQ	#8-1,D0
.c:	MOVE.L	A0,(A1)+
	MOVE.L	A0,(A1)+
	ADD.L	#$2000,A0
	DBF	D0,.c
	LEA	CdSRam,A0
	LEA	DirMappers+($68*8),A1
	MOVEQ	#24-1,D0
.s:	MOVE.L	A0,(A1)+
	MOVE.L	A0,(A1)+
	ADD.L	#$2000,A0
	DBF	D0,.s
	IFEQ	NO_ARCADE
	MOVE.L	ArcRam,D0		; the Arcade Card: banks $40-$43 through ArcWin, its RAM and registers cleared
	BEQ.S	.na
	LEA	ArcWin,A0
	LEA	DirMappers+($40*8),A1
	MOVEQ	#4-1,D0
.am:	MOVE.L	A0,(A1)+
	MOVE.L	A0,(A1)+
	DBF	D0,.am
	MOVE.L	ArcRam,A0
	MOVEQ	#0,D1
	MOVE.L	#ARC_SIZE/16-1,D0
.ac:	MOVE.L	D1,(A0)+
	MOVE.L	D1,(A0)+
	MOVE.L	D1,(A0)+
	MOVE.L	D1,(A0)+
	SUBQ.L	#1,D0
	BPL.S	.ac
	LEA	ArcVal,A0
	MOVEQ	#4+4*16+2-1,D0
.ap:	CLR.B	(A0)+
	DBF	D0,.ap
	IFND	ArcNoOn
	ST	ArcOn
	ENDC
.na:
	ENDC
	LEA	CdOpenBus,A0
	MOVEQ	#-1,D1
	MOVE.W	#$2000/4-1,D0
.f:	MOVE.L	D1,(A0)+
	DBF	D0,.f
	LEA	CdRam,A0		; CD RAM and Super CD RAM cleared
	MOVEQ	#0,D1
	MOVE.L	#(64+192)*1024/4-1,D0
.z:	MOVE.L	D1,(A0)+
	SUBQ.L	#1,D0
	BPL.S	.z
	LEA	CdSt0,A0		; the unit's state
	MOVE.W	#CdSt1-CdSt0-1,D0
.st:	CLR.B	(A0)+
	DBF	D0,.st
	MOVE.B	#AU_IDLE,AuStat
	MOVE.L	#16*671,AdCPS
	IFEQ	CdSndOff
	MOVE.W	#2048,AdOut
	MOVE.L	#-1,AuTFirst		; no audio track looked up yet
	ENDC
	BSR	CdBramMap
	BCLR	#0,IRQ_Pending(A3)
	MOVEQ	#8-1,D1
.p:	MOVEQ	#0,D7
	MOVE.B	TabMap(A3,D1.W),D7
	JSR	SetMapper
	DBF	D1,.p
	MOVEM.L	(SP)+,D0-D7/A0-A3
.x:	RTS

; -------------------------------------------------------------------
; The disc, in the menu (OS alive).

; Free the disc in RAM.
CdFree:	MOVEM.L	D0-D1/A0-A1/A6,-(SP)
	IFEQ	NO_ARCADE
	SF	ArcOn
	MOVE.L	ArcRam,D0
	BEQ.S	.na
	MOVE.L	D0,A1
	MOVE.L	#ARC_SIZE,D0
	MOVE.L	4.W,A6
	JSR	-$D2(A6)		; FreeMem
	CLR.L	ArcRam
.na:
	ENDC
	MOVE.L	CdMem,D0
	BEQ.S	.x
	MOVE.L	D0,A1
	MOVE.L	CdMemSize,D0
	MOVE.L	4.W,A6
	JSR	-$D2(A6)		; FreeMem
	CLR.L	CdMem
.x:
	IFEQ	CdSndOff
	BSR	CdFreeAudio
	ENDC
	CLR.W	CdTracks
	CLR.L	CdSecs
	MOVEM.L	(SP)+,D0-D1/A0-A1/A6
	RTS

; InsertLoad, first thing. FileNom a .cue: the disc read into RAM and FileNom set to the
; System Card, which then loads as a HuCard (CdPend says it's the BIOS). D0 = 0, or -1 with
; A0 = the error text. Anything else: D0 = 0, nothing done.
CdInsert:
	SF	CdPend
	LEA	FileNom,A0
	MOVE.L	A0,A1
.e:	TST.B	(A1)+
	BNE.S	.e
	SUBQ.L	#1,A1
	MOVE.L	A1,D0
	SUB.L	A0,D0
	CMP.L	#5,D0
	BCS	.no
	MOVE.L	-4(A1),D0
	OR.L	#$00202020,D0
	CMP.L	#'.cue',D0
	BNE	.no
	MOVEM.L	D1-D7/A1-A6,-(SP)
	BSR	CdFree
	SF	CdOn
	LEA	FileNom,A0		; the path, and the length of its folder part
	LEA	CdCueName,A1
	MOVEQ	#0,D1
	MOVEQ	#0,D2
.cp:	MOVE.B	(A0)+,D0
	MOVE.B	D0,(A1)+
	BEQ.S	.cpx
	ADDQ.W	#1,D1
	CMP.B	#'/',D0
	BEQ.S	.dir
	CMP.B	#':',D0
	BNE.S	.cp
.dir:	MOVE.W	D1,D2
	BRA.S	.cp
.cpx:	MOVE.W	D2,CdDirLen
	BSR	CdShowName		; the menu shows the .cue's name while the disc loads
	BSR	CdReadCue
	BNE.S	.err
	BSR	CdParse
	BNE.S	.err
	BSR	CdLayout
	BNE.S	.err
	IFEQ	CdSndOff
	BSR	CdLoadAll		; the data tracks and the CD audio (what fits), each file read once
	ELSE
	BSR	CdLoadData
	ENDC
	BNE.S	.err
	BSR	CdFindBios
	BNE.S	.err
	ST	CdPend
	MOVEM.L	(SP)+,D1-D7/A1-A6
.no:	MOVEQ	#0,D0
	RTS
.err:	BSR	CdFree
	BSR	CdNameBack		; the disc failed: the Cartridge and ROM lines as they were
	MOVEM.L	(SP)+,D1-D7/A1-A6
	MOVEQ	#-1,D0
	RTS

; CdShowName: the menu's Cartridge line = the .cue's file name, the ROM line dashes, while the
; disc loads (InsertLoad shows them again after). The old lines are kept for CdNameBack.
CdShowName:
	SF	CdNomSet
	IFEQ	NO_MENU2
	MOVEM.L	D0-D7/A0-A6,-(SP)
	TST.L	MainMenuWnd
	BEQ.S	.x
	LEA	tNomFileCart,A0
	LEA	CdNomOld,A1
	MOVEQ	#CD_NOMMAX-1,D0
.s:	MOVE.B	(A0)+,(A1)+
	DBEQ	D0,.s
	MOVE.L	MainMenuText9+$C,CdNomR
	MOVE.L	MainMenuText12+$C,CdNomC
	ST	CdNomSet
	LEA	CdCueName,A0
	ADD.W	CdDirLen,A0		; the file part
	LEA	tNomFileCart,A1
	JSR	PONOM
	MOVE.L	#tNomFileCart,MainMenuText12+$C
	MOVE.L	#tTipoROM,MainMenuText9+$C
	JSR	PrintCartTexts
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	ENDC
	RTS

CdNameBack:
	IFEQ	NO_MENU2
	TST.B	CdNomSet
	BEQ.S	.x
	SF	CdNomSet
	MOVEM.L	D0-D7/A0-A6,-(SP)
	LEA	CdNomOld,A0
	LEA	tNomFileCart,A1
	MOVEQ	#CD_NOMMAX-1,D0
.s:	MOVE.B	(A0)+,(A1)+
	DBEQ	D0,.s
	MOVE.L	CdNomR,MainMenuText9+$C
	MOVE.L	CdNomC,MainMenuText12+$C
	TST.L	MainMenuWnd
	BEQ.S	.n
	JSR	PrintCartTexts
.n:	MOVEM.L	(SP)+,D0-D7/A0-A6
	ENDC
.x:	RTS

; After the card loaded (InsertLoad): the disc goes in, or out if this was a HuCard.
CdInserted:
	MOVE.B	CdPend,CdOn
	SF	CdPend
	TST.B	CdOn
	BNE	CdBiosFix
	BRA	CdFree

; A US System Card is stored bit-reversed (TurboChip): turned round if 'PC Engine' isn't found.
CdBiosFix:
	MOVEM.L	D0-D3/A0-A1,-(SP)
	CMP.W	#32,PagCart
	BCS.S	.x
	MOVE.L	DirCart,A0
	ADD.W	#$80,A0
	CMP.L	#'PC E',$3FFB6(A0)
	BEQ.S	.x
	LEA	$3FFB6(A0),A1		; reversed, is it there?
	MOVEQ	#4-1,D2
.t:	ROL.L	#8,D3
	MOVE.B	(A1)+,D0
	BSR.S	.rev
	MOVE.B	D1,D3
	DBF	D2,.t
	CMP.L	#'PC E',D3
	BNE.S	.x
	MOVE.L	#$40000-1,D2
.r:	MOVE.B	(A0),D0
	BSR.S	.rev
	MOVE.B	D1,(A0)+
	SUBQ.L	#1,D2
	BPL.S	.r
.x:	MOVEM.L	(SP)+,D0-D3/A0-A1
	RTS
.rev:	MOVE.L	D2,-(SP)		; D0.B reversed to D1.B
	MOVEQ	#8-1,D2
.b:	LSR.B	#1,D0
	ROXL.B	#1,D1
	DBF	D2,.b
	MOVE.L	(SP)+,D2
	RTS

; The .cue into CdCueBuf. EQ ok; NE with A0 = error.
CdReadCue:
	MOVE.L	#CdCueName,D1
	MOVE.L	#1005,D2
	JSR	OpenFile
	BEQ.S	.e
	MOVE.L	#CdCueBuf,D2
	MOVE.L	#CdCueMax-1,D3
	MOVE.L	_DosBase,A6
	MOVE.L	DisBase,D1
	JSR	-42(A6)			; Read
	MOVE.L	D0,-(SP)
	JSR	CloseFile
	MOVE.L	(SP)+,D0
	BLE.S	.e
	LEA	CdCueBuf,A0
	CLR.B	(A0,D0.L)
	MOVEQ	#0,D0
	RTS
.e:	LEA	tErCdCue,A0
	MOVEQ	#-1,D0
	RTS

; Lines: FILE, TRACK, INDEX, PREGAP, POSTGAP. EQ ok; NE with A0 = error.
CdParse:
	CLR.W	CdFiles
	CLR.W	CdTracks
	LEA	CdNamePool,A2
	LEA	CdCueBuf,A4
	CMP.B	#$EF,(A4)		; a UTF-8 mark at the start
	BNE.S	.line
	CMP.B	#$BB,1(A4)
	BNE.S	.line
	ADDQ.L	#3,A4
.line:	BSR	CdSkipSp
	TST.B	(A4)
	BEQ	.end
	BSR	CdWord			; the keyword, upper case, in CdWordBuf
	LEA	CdWordBuf,A0
	CMP.L	#'FILE',(A0)
	BNE	.nFile
	TST.B	4(A0)
	BNE	.skip
	MOVE.W	CdFiles,D0
	CMP.W	#CD_MAXFILE,D0
	BCC	.bad
	LSL.W	#3,D0
	LEA	CdFileTab,A1
	MOVE.L	A2,(A1,D0.W)		; its name
	ADDQ.W	#1,CdFiles
	BSR	CdSkipSp
	CMP.B	#'"',(A4)
	BNE.S	.unq
	ADDQ.L	#1,A4
.q:	MOVE.B	(A4),D0
	BEQ.S	.qe
	CMP.B	#10,D0
	BEQ.S	.qe
	ADDQ.L	#1,A4
	CMP.B	#'"',D0
	BEQ.S	.qe
	MOVE.B	D0,(A2)+
	BRA.S	.q
.unq:	MOVE.B	(A4),D0
	CMP.B	#' ',D0
	BLS.S	.qe
	MOVE.B	D0,(A2)+
	ADDQ.L	#1,A4
	BRA.S	.unq
.qe:	CLR.B	(A2)+
	CMP.L	#CdNamePool+CdPoolMax-256,A2
	BCC	.bad
	BRA	.skip
.nFile:	CMP.L	#'TRAC',(A0)
	BNE	.nTrk
	CMP.W	#'K'<<8,4(A0)
	BNE	.skip
	TST.W	CdFiles
	BEQ	.bad
	MOVE.W	CdTracks,D0
	CMP.W	#CD_MAXTRK,D0
	BCC	.bad
	MULU	#TRK_SIZE,D0
	LEA	CdTrk,A3
	ADD.L	D0,A3			; A3 = this track
	ADDQ.W	#1,CdTracks
	MOVE.L	A3,A1
	MOVEQ	#TRK_SIZE-1,D0
.ct:	CLR.B	(A1)+
	DBF	D0,.ct
	MOVEQ	#-1,D0
	MOVE.L	D0,TRK_IDX0(A3)
	MOVE.L	D0,TRK_IDX1(A3)
	MOVE.W	CdFiles,D0
	SUBQ.W	#1,D0
	MOVE.B	D0,TRK_FILE(A3)
	BSR	CdSkipSp
	BSR	CdNum			; its number (not used: tracks come in order)
	BSR	CdSkipSp
	BSR	CdWord
	LEA	CdWordBuf,A0
	CMP.L	#'AUDI',(A0)
	BEQ	.skip
	MOVE.B	#1,TRK_TYPE(A3)
	CMP.L	#'MODE',(A0)
	BNE	.bad
	CMP.L	#'1/23',4(A0)
	BEQ	.skip
	CMP.L	#'2/23',4(A0)		; (MODE2/2352: read as Mode 1)
	BEQ	.skip
	MOVE.B	#2,TRK_TYPE(A3)
	CMP.L	#'1/20',4(A0)
	BEQ	.skip
	BRA	.bad
.nTrk:	CMP.L	#'INDE',(A0)
	BNE.S	.nIdx
	CMP.W	#'X'<<8,4(A0)
	BNE	.skip
	TST.W	CdTracks
	BEQ	.bad
	BSR	CdSkipSp
	BSR	CdNum
	MOVE.L	D0,D2
	BSR	CdSkipSp
	BSR	CdMsfIn
	TST.L	D2
	BNE.S	.i1
	MOVE.L	D0,TRK_IDX0(A3)
	BRA	.skip
.i1:	CMP.L	#1,D2
	BNE	.skip
	MOVE.L	D0,TRK_IDX1(A3)
	BRA	.skip
.nIdx:	CMP.L	#'PREG',(A0)
	BNE.S	.nPre
	TST.W	CdTracks
	BEQ	.bad
	BSR	CdSkipSp
	BSR	CdMsfIn
	MOVE.L	D0,TRK_PRE(A3)
	BRA.S	.skip
.nPre:	CMP.L	#'POST',(A0)
	BNE.S	.skip
	TST.W	CdTracks
	BEQ	.bad
	BSR	CdSkipSp
	BSR	CdMsfIn
	MOVE.L	D0,TRK_POST(A3)
.skip:	MOVE.B	(A4),D0			; to the next line
	BEQ.S	.end
	ADDQ.L	#1,A4
	CMP.B	#10,D0
	BNE.S	.skip
	BRA	.line
.end:	TST.W	CdTracks
	BEQ.S	.bad
	MOVEQ	#0,D0
	RTS
.bad:	LEA	tErCdCue,A0
	MOVEQ	#-1,D0
	RTS

CdSkipSp:
	MOVE.B	(A4),D0
	CMP.B	#' ',D0
	BEQ.S	.s
	CMP.B	#9,D0
	BEQ.S	.s
	CMP.B	#13,D0
	BNE.S	.x
.s:	ADDQ.L	#1,A4
	BRA.S	CdSkipSp
.x:	RTS

CdWord:	LEA	CdWordBuf,A0		; up to 11 characters, upper case, zero filled
	CLR.L	(A0)
	CLR.L	4(A0)
	CLR.L	8(A0)
	MOVEQ	#11-1,D1
.l:	MOVE.B	(A4),D0
	CMP.B	#' ',D0
	BLS.S	.x
	ADDQ.L	#1,A4
	CMP.B	#'a',D0
	BCS.S	.u
	CMP.B	#'z',D0
	BHI.S	.u
	SUB.B	#$20,D0
.u:	MOVE.B	D0,(A0)+
	DBF	D1,.l
.k:	MOVE.B	(A4),D0			; the rest of a long word
	CMP.B	#' ',D0
	BLS.S	.x
	ADDQ.L	#1,A4
	BRA.S	.k
.x:	RTS

CdNum:	MOVEQ	#0,D0			; decimal at A4: D0
	MOVEQ	#0,D1
.l:	MOVE.B	(A4),D1
	SUB.B	#'0',D1
	BCS.S	.x
	CMP.B	#9,D1
	BHI.S	.x
	ADDQ.L	#1,A4
	MULU.L	#10,D0
	ADD.L	D1,D0
	BRA.S	.l
.x:	RTS

CdMsfIn:				; mm:ss:ff at A4: D0 = sectors
	MOVE.L	D3,-(SP)
	BSR	CdNum
	MULU.L	#60,D0
	MOVE.L	D0,D3
	CMP.B	#':',(A4)
	BNE.S	.x
	ADDQ.L	#1,A4
	BSR	CdNum
	ADD.L	D0,D3
	MULU.L	#75,D3
	CMP.B	#':',(A4)
	BNE.S	.x
	ADDQ.L	#1,A4
	BSR	CdNum
	ADD.L	D0,D3
.x:	MOVE.L	D3,D0
	MOVE.L	(SP)+,D3
	RTS

; CdPath = the folder of the .cue + file D0's name
CdMkPath:
	MOVEM.L	D0-D1/A0-A2,-(SP)
	LSL.W	#3,D0
	LEA	CdFileTab,A0
	MOVE.L	(A0,D0.W),A1		; the name
	LEA	CdCueName,A0
	LEA	CdPath,A2
	MOVE.W	CdDirLen,D1
	BRA.S	.d1
.d:	MOVE.B	(A0)+,(A2)+
.d1:	DBF	D1,.d
	MOVE.W	#CdPathMax-2,D1
	SUB.W	CdDirLen,D1
.n:	MOVE.B	(A1)+,(A2)+
	DBEQ	D1,.n
	CLR.B	(A2)
	MOVEM.L	(SP)+,D0-D1/A0-A2
	RTS

; Track positions (LBAs), as Mesen for one file; PREGAP and POSTGAP add sectors that aren't in
; the file. EQ ok; NE with A0 = error.
CdLayout:
	MOVEQ	#0,D6			; LBA where this file starts
	LEA	CdTrk,A3		; A3 = the next track
	MOVEQ	#0,D5			; D5 = file
.file:	CMP.W	CdFiles,D5
	BCC	.done
	MOVE.L	D5,D0
	BSR	CdMkPath
	MOVE.L	#CdPath,D1		; its size
	MOVEQ	#-2,D2
	MOVE.L	_DosBase,A6
	JSR	-$54(A6)		; Lock
	TST.L	D0
	BEQ	.miss
	MOVE.L	D0,-(SP)
	MOVE.L	D0,D1
	MOVE.L	#Examine,D2
	JSR	-$66(A6)		; Examine
	MOVE.L	(SP)+,D1
	JSR	-$5A(A6)		; UnLock
	MOVE.L	Examine+$7C,D7		; bytes
	MOVE.L	D7,CdFBytes
	MOVE.L	#2352,D1
	CMP.B	#2,TRK_TYPE(A3)
	BNE.S	.s
	MOVE.L	#2048,D1
.s:	DIVU.L	D1,D7			; D7 = sectors in the file
	LEA	CdFileTab,A0
	MOVE.L	D5,D0
	LSL.W	#3,D0
	MOVE.L	D1,4(A0,D0.W)		; sector size
	MOVEQ	#0,D4			; D4 = sectors added (gaps) in this file
	SUB.L	A1,A1			; A1 = the last track of the file
.trk:	MOVE.L	A3,D0			; tracks of this file
	SUB.L	#CdTrk,D0
	DIVU	#TRK_SIZE,D0
	CMP.W	CdTracks,D0
	BCC	.fend
	CMP.B	TRK_FILE(A3),D5
	BNE	.fend
	ADD.L	TRK_PRE(A3),D4
	MOVE.L	TRK_IDX1(A3),D0
	BMI	.bad
	ADD.L	D6,D0
	ADD.L	D4,D0
	MOVE.L	D0,TRK_START(A3)
	MOVE.L	#2352,D2		; this track's sector size in the file (chdman writes MODE1/2048
	CMP.B	#2,TRK_TYPE(A3)		; data and 2352-byte audio into one BIN)
	BNE.S	.z1
	MOVE.L	#2048,D2
.z1:	MOVE.L	A1,D0
	BNE.S	.fo
	MOVE.L	TRK_IDX1(A3),D0		; the file's first track
	MULU.L	D2,D0
	BRA.S	.fs
.fo:	MOVE.L	#2352,D3		; after the track before, at its sector size
	CMP.B	#2,TRK_TYPE(A1)
	BNE.S	.z2
	MOVE.L	#2048,D3
.z2:	MOVE.L	TRK_IDX1(A3),D0
	SUB.L	TRK_IDX1(A1),D0
	MULU.L	D3,D0
	ADD.L	TRK_FOFF(A1),D0
.fs:	MOVE.L	D0,TRK_FOFF(A3)
	MOVE.L	CdFBytes,D1		; its end in the file: the next track's INDEX 00 or 01, or the end
	SUB.L	D0,D1			; (the end in this track's sectors)
	BMI	.bad
	DIVU.L	D2,D1
	ADD.L	TRK_IDX1(A3),D1
	LEA	TRK_SIZE(A3),A0
	MOVE.L	A0,D0
	SUB.L	#CdTrk,D0
	DIVU	#TRK_SIZE,D0
	CMP.W	CdTracks,D0
	BCC.S	.last
	CMP.B	TRK_FILE(A0),D5
	BNE.S	.last
	MOVE.L	TRK_IDX0(A0),D1
	BPL.S	.last
	MOVE.L	TRK_IDX1(A0),D1
.last:	SUB.L	TRK_IDX1(A3),D1		; sectors
	BLE	.bad
	ADD.L	TRK_START(A3),D1
	SUBQ.L	#1,D1
	MOVE.L	D1,TRK_LAST(A3)
	ADD.L	TRK_POST(A3),D4
	MOVE.L	A3,A1
	LEA	TRK_SIZE(A3),A3
	BRA	.trk
.fend:	MOVE.L	A1,D0
	BEQ	.bad			; a FILE with no TRACK
	MOVE.L	TRK_LAST(A1),D6
	ADDQ.L	#1,D6
	ADD.L	TRK_POST(A1),D6
	ADDQ.L	#1,D5
	BRA	.file
.done:	LEA	-TRK_SIZE(A3),A3
	MOVE.L	TRK_LAST(A3),D0
	ADDQ.L	#1,D0
	MOVE.L	D0,CdSecs
	MOVEQ	#0,D0
	RTS
.miss:	LEA	tErCdFile,A0
	MOVEQ	#-1,D0
	RTS
.bad:	LEA	tErCdCue,A0
	MOVEQ	#-1,D0
	RTS

; The data tracks into RAM, 2048 bytes a sector. EQ ok; NE with A0 = error.
CdLoadData:
	MOVEQ	#0,D7			; RAM needed
	LEA	CdTrk,A3
	MOVE.W	CdTracks,D5
	SUBQ.W	#1,D5
.sz:	TST.B	TRK_TYPE(A3)
	BEQ.S	.szn
	MOVE.L	D7,TRK_RAM(A3)
	MOVE.L	TRK_LAST(A3),D0
	SUB.L	TRK_START(A3),D0
	ADDQ.L	#1,D0
	MOVEQ	#11,D1
	LSL.L	D1,D0
	ADD.L	D0,D7
.szn:	LEA	TRK_SIZE(A3),A3
	DBF	D5,.sz
	TST.L	D7
	BEQ	.nodata
	MOVE.L	D7,CdMemSize
	MOVE.L	D7,D0
	MOVEQ	#1,D1			; MEMF_PUBLIC (fast RAM first)
	MOVE.L	4.W,A6
	JSR	-$C6(A6)		; AllocMem
	MOVE.L	D0,CdMem
	BEQ	.mem
	IFEQ	NO_ARCADE
	TST.L	ArcRam			; the Arcade Card's RAM, before the CD audio takes what's left
	BNE.S	.arc
	MOVE.L	#ARC_SIZE,D0
	MOVEQ	#1,D1			; MEMF_PUBLIC (0: no card)
	JSR	-$C6(A6)		; AllocMem
	MOVE.L	D0,ArcRam
.arc:
	ENDC
	LEA	CdTrk,A3
	MOVE.W	CdTracks,D5
	SUBQ.W	#1,D5
.trk:	TST.B	TRK_TYPE(A3)
	BEQ	.next
	MOVEQ	#0,D0
	MOVE.B	TRK_FILE(A3),D0
	BSR	CdMkPath
	MOVE.L	#2352,D4		; the track's sector size in the file
	CMP.B	#2,TRK_TYPE(A3)
	BNE.S	.ss
	MOVE.L	#2048,D4
.ss:	MOVE.L	#CdPath,D1
	MOVE.L	#1005,D2
	JSR	OpenFile
	BEQ	.rerr
	MOVE.L	TRK_FOFF(A3),D2		; Seek to INDEX 01
	MOVE.L	DisBase,D1
	MOVEQ	#-1,D3			; OFFSET_BEGINNING
	MOVE.L	_DosBase,A6
	JSR	-66(A6)			; Seek
	TST.L	D0
	BMI	.rclose
	MOVE.L	TRK_LAST(A3),D6		; sectors to read
	SUB.L	TRK_START(A3),D6
	ADDQ.L	#1,D6
	MOVE.L	CdMem,A5
	ADD.L	TRK_RAM(A3),A5		; A5 = where they go
	CMP.L	#2048,D4
	BNE.S	.raw
	MOVE.L	D6,D3			; 2048-byte sectors: straight in
	MOVEQ	#11,D0
	LSL.L	D0,D3
	MOVE.L	A5,D2
	JSR	ReadFile
	BNE	.rclose
	BRA.S	.closed
.raw:	MOVE.L	D6,D3			; 2352: a chunk at a time, the 2048 user bytes at +16
	CMP.L	#CdChunkSecs,D3
	BLS.S	.c1
	MOVE.L	#CdChunkSecs,D3
.c1:	SUB.L	D3,D6
	MOVE.L	D3,-(SP)
	MULU.L	#2352,D3
	MOVE.L	#CdChunk,D2
	JSR	ReadFile
	MOVEM.L	(SP)+,D3		; (flags kept)
	BNE.S	.rclose
	LEA	CdChunk+16,A0
	SUBQ.L	#1,D3
.cs:	MOVE.W	#2048/16-1,D0
	MOVE.L	A0,A1
.cw:	MOVE.L	(A1)+,(A5)+
	MOVE.L	(A1)+,(A5)+
	MOVE.L	(A1)+,(A5)+
	MOVE.L	(A1)+,(A5)+
	DBF	D0,.cw
	ADD.W	#2352,A0
	DBF	D3,.cs
	TST.L	D6
	BNE.S	.raw
.closed:
	JSR	CloseFile
.next:	LEA	TRK_SIZE(A3),A3
	DBF	D5,.trk
	MOVEQ	#0,D0
	RTS
.rclose:
	JSR	CloseFile
.rerr:	LEA	tErCdRead,A0
	MOVEQ	#-1,D0
	RTS
.mem:	LEA	tErCdMem,A0
	MOVEQ	#-1,D0
	RTS
.nodata:
	LEA	tErCdData,A0
	MOVEQ	#-1,D0
	RTS

; The System Card: cd_bios.rom or syscard3.pce next to the .cue, else in PROGDIR:. Its path
; to FileNom. EQ ok; NE with A0 = error.
CdFindBios:
	LEA	CdBiosNames,A3
.n:	TST.B	(A3)
	BEQ.S	.none
	LEA	CdPath,A1
	CMP.B	#'@',(A3)		; '@': next to the .cue
	BNE.S	.abs
	ADDQ.L	#1,A3
	LEA	CdCueName,A0
	MOVE.W	CdDirLen,D1
	BRA.S	.d1
.d:	MOVE.B	(A0)+,(A1)+
.d1:	DBF	D1,.d
.abs:	MOVE.B	(A3)+,(A1)+
	BNE.S	.abs
	MOVE.L	#CdPath,D1
	MOVEQ	#-2,D2
	MOVE.L	_DosBase,A6
	JSR	-$54(A6)		; Lock
	TST.L	D0
	BEQ.S	.n
	MOVE.L	D0,D1
	JSR	-$5A(A6)		; UnLock
	LEA	CdPath,A0
	LEA	FileNom,A1
.cp:	MOVE.B	(A0)+,(A1)+
	BNE.S	.cp
	MOVEQ	#0,D0
	RTS
.none:	LEA	tErCdBios,A0
	MOVEQ	#-1,D0
	RTS

CdBiosNames:
	DC.B	'@cd_bios.rom',0
	DC.B	'@syscard3.pce',0
	DC.B	'PROGDIR:syscard3.pce',0
	DC.B	'PROGDIR:cd_bios.rom',0
	DC.B	0

tErCdCue:	DC.B	"  Can't read this CUE sheet!  ",0
tErCdFile:	DC.B	" A file of the CD isn't there!",0
tErCdRead:	DC.B	"  Can't read the CD image!    ",0
tErCdMem:	DC.B	"  Not enough memory for CD!   ",0
tErCdData:	DC.B	"  No data track on this CD!   ",0
tErCdBios:	DC.B	"syscard3.pce (System Card) ?? ",0
CdBramNom:	DC.B	"CD-ROM System",0
	EVEN

; -------------------------------------------------------------------
	CNOP	0,4
CdOn:		DC.B	0	; a disc is in: the CD unit is on at Power ON
CdPend:		DC.B	0	; a .cue read, its System Card loading
CdDirLen:	DC.W	0
CdFiles:	DC.W	0
CdTracks:	DC.W	0
CdSecs:		DC.L	0	; sectors on the disc
CdMem:		DC.L	0	; the data tracks (AllocMem)
CdMemSize:	DC.L	0

CdSt0:				; cleared at Power ON
ScSig:		DC.B	0
ScPhase:	DC.B	0
ScChg:		DC.B	0
ScMsgDone:	DC.B	0
ScData:		DC.B	0
ScRData:	DC.B	0
ScUpdTyp:	DC.B	0
ScCmdLen:	DC.B	0
ScCmd:		DS.B	16
ScResp:		DS.B	16
CdActIrq:	DC.B	0
CdEnaIrq:	DC.B	0
CdResReg:	DC.B	0
CdBramLk:	DC.B	0
CdRight:	DC.B	0
CdFader:	DC.B	0
AdCtl:		DC.B	0
AdDma:		DC.B	0
AdRate:		DC.B	0
AdEnd:		DC.B	0
AdHalf:		DC.B	0
AdPlay:		DC.B	0
AdPReq:		DC.B	0
AdNib:		DC.B	0
AdRBuf:		DC.B	0
AuStat:		DC.B	0
AuEndB:		DC.B	0
AuIrqC:		DC.B	0
	CNOP	0,4
ScUpdCnt:	DC.L	0
ScReadCnt:	DC.L	0
ScSector:	DC.L	0
ScToRead:	DC.L	0
ScBufPtr:	DC.L	0
ScBufLeft:	DC.L	0
AdLen:		DC.L	0
AdCPS:		DC.L	0
AdClk:		DC.L	0
AuStart:	DC.L	0
AuEnd:		DC.L	0
AuSector:	DC.L	0
AuSeek:		DC.L	0
AuClk:		DC.L	0
AdAddr:		DC.W	0
AdRead:		DC.W	0
AdWrite:	DC.W	0
AuSmp:		DC.W	0
	IFEQ	CdSndOff
AdOut:		DC.W	0		; MSM5205 output, 0-4095
AdMag:		DC.W	0		; its step index, 0-48
CdFadeT:	DC.W	0		; PCE frames since the fader write
AuCapN:		DC.W	0		; samples captured this frame
AdCapN:		DC.W	0
AuPar:		DC.B	0
		DC.B	0
AuTFirst:	DC.L	0		; the audio track the last capture found
AuTLast:	DC.L	0
AuTRam:		DC.L	0
AdCapClk:	DC.L	0
	ENDC
CdSt1:

CdWordBuf:	DS.B	12
	CNOP	0,4
CdFileTab:	DS.L	CD_MAXFILE*2	; name, sector size
CdFBytes:	DS.L	1		; CdLayout: the file's size
CdNomR:		DS.L	1		; CdShowName: the ROM and Cartridge lines before
CdNomC:		DS.L	1
CdNomOld:	DS.B	CD_NOMMAX
CdNomSet:	DS.B	1
		DS.B	1
CdTrk:		DS.B	CD_MAXTRK*TRK_SIZE
