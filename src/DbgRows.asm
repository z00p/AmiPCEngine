; DbgRows.asm: debug rows for real-hardware testing (30 Oct 2026, after AmiMSX's RTGDBG).
; Build with -DDbgRows=1 (off in the normal build). Two rows of hex numbers in a 1-plane
; panel above the picture (lines $1C-$2C; the picture moves down to line $35, so on NTSC
; the bottom 15 lines are cut). Values are counted over a window of 50 Amiga vertical blanks
; and redrawn once per window, so a phone photo can read them. Times are in scan lines
; from the CIA-B TOD counter (it counts HSYNC whatever the screen mode).
;
; Row 1 (top): TOTL WRST OTHR
;   TOTL lines in the window (NTSC 50 x 262 = $332C, PAL 50 x 313 = $3D22)
;   WRST longest single frame in lines (one vertical blank = $0106 NTSC, $0139 PAL)
;   OTHR lines in the rest of the loop
; Row 2 (bottom, the main one): FRMS VBLS WAIT CPU  BG   SPR  VBLI LATE [RTG  COPY]
;   FRMS PCE frames emulated (full speed = VBLS: $0032 = 50)
;   VBLS Amiga vertical blanks in the window
;   WAIT lines spent waiting for the next vertical blank (spare time)
;   CPU  lines in the HuC6280 frame (PCE_Start, DDA capture)
;   BG   lines drawing the background (WideGeometry, PrintGFX, CleanTabRefef)
;   SPR  lines drawing the sprites (PrintSprites_AGA)
;   VBLI lines in the vertical blank interrupt (copper scroll list, pads); also
;        counted inside whichever section it interrupted
;   LATE frames that took more than one vertical blank
;   RTG  (RTG display only) lines composing the frame in fast RAM (RtgFrame:
;        background, sprites, changed-line test); BG and SPR are 0 then
;   COPY (RTG display only) lines copying the changed lines to the board
; On RTG the panel (50 characters) is drawn 1:1 on the top 17 lines of the screen
; and the picture under it is not copied (on 960x540 it sits in the border; on
; 640x480 it covers the top 8 PCE lines).

DbgCols	= 40			; panel width in bytes (320 pixels)
DbgRowGap = 9			; second row starts 9 lines below the first
DbgColsR = 50			; RTG panel width in characters (400 pixels)

; DbgInit: after the copper lists are installed (CongelaAMIGA).
DbgInit:
	MOVEM.L	D0-D1/A0,-(SP)
	MOVE.L	#DbgPanel,D0
	MOVE.W	D0,DbgCopPt+6
	SWAP	D0
	MOVE.W	D0,DbgCopPt+2
	LEA	DbgPanel,A0
	MOVE.W	#(DbgCols*(DbgRowGap+8))/4-1,D1
.cl:	CLR.L	(A0)+
	DBF	D1,.cl
	LEA	DbgSums,A0
	MOVEQ	#DbgSumsN-1,D1
.cs:	CLR.W	(A0)+
	DBF	D1,.cs
	CLR.W	DbgWorst
	BSR	DbgTod
	MOVE.W	D0,DbgLast
	MOVE.W	D0,DbgFrameT0
	MOVE.W	D0,DbgWinT0
	MOVE.L	vTimerVBlanks,D0
	MOVE.L	D0,DbgPrevVb
	MOVE.L	D0,DbgWinVb
	MOVEM.L	(SP)+,D0-D1/A0
	RTS

; DbgTod: D0.W = CIA-B TOD bits 15-0 (lines). Middle byte read twice so a carry
; between the two reads is caught; the high byte is not read (it would latch).
DbgTod:
	MOVE.L	D1,-(SP)
.r:	MOVE.B	$BFD900,D1
	MOVE.B	$BFD800,D0
	CMP.B	$BFD900,D1
	BNE.S	.r
	LSL.W	#8,D1
	MOVE.B	D0,D1
	MOVE.W	D1,D0
	MOVE.L	(SP)+,D1
	RTS

; Section laps: add the lines since the last lap to a sum. All registers kept.
DbgLapCpu:
	MOVE.L	A0,-(SP)
	LEA	DbgCpu,A0
	BRA.S	DbgLap
DbgLapBg:
	MOVE.L	A0,-(SP)
	LEA	DbgBg,A0
	BRA.S	DbgLap
DbgLapSpr:
	MOVE.L	A0,-(SP)
	LEA	DbgSpr,A0
	BRA.S	DbgLap
DbgLapWait:
	MOVE.L	A0,-(SP)
	LEA	DbgWait,A0
	BRA.S	DbgLap
	IFEQ	NO_RTG
DbgLapRtg:
	MOVE.L	A0,-(SP)
	LEA	DbgRtg,A0
	BRA.S	DbgLap
DbgLapCopy:
	MOVE.L	A0,-(SP)
	LEA	DbgCopy,A0
	BRA.S	DbgLap
	ENDC
DbgLapOther:
	MOVE.L	A0,-(SP)
	LEA	DbgOther,A0
DbgLap:				; A0 = sum, the caller's A0 on the stack above the return address
	MOVEM.L	D0-D1,-(SP)
	BSR	DbgTod
	MOVE.W	D0,D1
	SUB.W	DbgLast,D0
	MOVE.W	D1,DbgLast
	ADD.W	D0,(A0)
	MOVEM.L	(SP)+,D0-D1
	MOVE.L	(SP)+,A0
	RTS

; DbgVblIn / DbgVblOut: start and end of the vertical blank interrupt (registers saved there).
DbgVblIn:
	BSR	DbgTod
	MOVE.W	D0,DbgVbl0
	RTS
DbgVblOut:
	BSR	DbgTod
	SUB.W	DbgVbl0,D0
	ADD.W	D0,DbgVbli
	RTS

; DbgFrame: a new PCE frame starts (the vertical blank was just seen). All registers kept.
DbgFrame:
	MOVEM.L	D0-D3/A0-A3,-(SP)
	BSR	DbgLapWait		; the wait just ended
	ADDQ.W	#1,DbgFrms
	BSR	DbgTod
	MOVE.W	D0,D1
	SUB.W	DbgFrameT0,D1		; lines since the previous frame started
	MOVE.W	D0,DbgFrameT0
	CMP.W	DbgWorst,D1
	BLS.S	.nw
	MOVE.W	D1,DbgWorst
.nw:	MOVE.L	vTimerVBlanks,D1
	MOVE.L	D1,D2
	SUB.L	DbgPrevVb,D2
	MOVE.L	D1,DbgPrevVb
	CMP.L	#2,D2
	BCS.S	.nl
	ADDQ.W	#1,DbgLate
.nl:	SUB.L	DbgWinVb,D1
	CMP.L	#50,D1
	BCS	.out
; window over: latch, clear, draw
	ADD.L	D1,DbgWinVb
	LEA	DbgOut,A1
	LEA	DbgSums,A0
	MOVE.W	DbgFrms,(A1)+		; main row
	MOVE.W	D1,(A1)+
	MOVE.W	DbgWait,(A1)+
	MOVE.W	DbgCpu,(A1)+
	MOVE.W	DbgBg,(A1)+
	MOVE.W	DbgSpr,(A1)+
	MOVE.W	DbgVbli,(A1)+
	MOVE.W	DbgLate,(A1)+
	MOVE.W	DbgRtg,(A1)+
	MOVE.W	DbgCopy,(A1)+
	MOVE.W	D0,D2			; top row
	SUB.W	DbgWinT0,D2
	MOVE.W	D0,DbgWinT0
	MOVE.W	D2,(A1)+
	MOVE.W	DbgWorst,(A1)+
	MOVE.W	DbgOther,(A1)+
	IFNE	AutoExit
	BSR	DbgAutoSum
	ENDC
	MOVEQ	#DbgSumsN-1,D1
.c:	CLR.W	(A0)+
	DBF	D1,.c
	CLR.W	DbgWorst
	IFEQ	NO_RTG
	TST.B	RtgOn
	BEQ.S	.aga
	MOVEQ	#DbgColsR,D3		; RTG: drawn on the screen by RtgCopy
	LEA	DbgOut+20,A0
	LEA	DbgPanelR,A1
	MOVEQ	#3,D1
	BSR	DbgRow
	LEA	DbgOut,A0
	LEA	DbgPanelR+DbgColsR*DbgRowGap,A1
	MOVEQ	#10,D1
	BSR	DbgRow
	ST	DbgRtgNew
	BRA.S	.out
.aga:
	ENDC
	MOVEQ	#DbgCols,D3
	LEA	DbgOut+20,A0
	LEA	DbgPanel,A1
	MOVEQ	#3,D1
	BSR	DbgRow
	LEA	DbgOut,A0
	LEA	DbgPanel+DbgCols*DbgRowGap,A1
	MOVEQ	#8,D1
	BSR	DbgRow
.out:	MOVEM.L	(SP)+,D0-D3/A0-A3
	RTS

; DbgRow: D1 values from (A0)+ as 4 hex digits each, 5 characters apart, at A1;
; D3 = bytes a panel line.
DbgRow:
	SUBQ.W	#1,D1
.v:	MOVE.W	(A0)+,D0
	MOVEQ	#4-1,D2
.d:	ROL.W	#4,D0
	MOVE.W	D0,-(SP)
	AND.W	#$F,D0
	LSL.W	#3,D0
	LEA	(DbgFont,PC,D0.W),A2
	MOVE.L	A1,A3
	MOVEQ	#8-1,D0
.g:	MOVE.B	(A2)+,(A3)
	ADD.W	D3,A3
	DBF	D0,.g
	ADDQ.L	#1,A1
	MOVE.W	(SP)+,D0
	DBF	D2,.d
	ADDQ.L	#1,A1			; space
	DBF	D1,.v
	RTS

DbgFont:			; 8x8, 5x7 glyphs
	DC.B	$38,$44,$4C,$54,$64,$44,$38,$00	; 0
	DC.B	$10,$30,$10,$10,$10,$10,$38,$00	; 1
	DC.B	$38,$44,$04,$18,$20,$40,$7C,$00	; 2
	DC.B	$78,$04,$04,$38,$04,$04,$78,$00	; 3
	DC.B	$08,$18,$28,$48,$7C,$08,$08,$00	; 4
	DC.B	$7C,$40,$78,$04,$04,$44,$38,$00	; 5
	DC.B	$18,$20,$40,$78,$44,$44,$38,$00	; 6
	DC.B	$7C,$04,$08,$10,$20,$20,$20,$00	; 7
	DC.B	$38,$44,$44,$38,$44,$44,$38,$00	; 8
	DC.B	$38,$44,$44,$3C,$04,$08,$30,$00	; 9
	DC.B	$38,$44,$44,$7C,$44,$44,$44,$00	; A
	DC.B	$78,$44,$44,$78,$44,$44,$78,$00	; B
	DC.B	$38,$44,$40,$40,$40,$44,$38,$00	; C
	DC.B	$70,$48,$44,$44,$44,$48,$70,$00	; D
	DC.B	$7C,$40,$40,$78,$40,$40,$7C,$00	; E
	DC.B	$7C,$40,$40,$78,$40,$40,$40,$00	; F

	CNOP	0,2
DbgSums:
DbgFrms:	DC.W	0
DbgWait:	DC.W	0
DbgCpu:		DC.W	0
DbgBg:		DC.W	0
DbgSpr:		DC.W	0
DbgVbli:	DC.W	0
DbgLate:	DC.W	0
DbgRtg:		DC.W	0
DbgCopy:	DC.W	0
DbgOther:	DC.W	0
DbgSumsN	= (*-DbgSums)/2
DbgWorst:	DC.W	0
DbgLast:	DC.W	0
DbgFrameT0:	DC.W	0
DbgWinT0:	DC.W	0
DbgVbl0:	DC.W	0
	CNOP	0,4
DbgPrevVb:	DC.L	0
DbgWinVb:	DC.L	0
DbgOut:		DS.W	13

	IFNE	AutoExit
; AutoExit + DbgRows: the windows' figures over the whole run, for AmiPCE.result (tools/a1200run.py).
DbgAutoSum:
	MOVEM.L	D0-D1/A0-A1,-(SP)
	LEA	DbgOut,A0
	LEA	DbgAuto,A1
	MOVEQ	#13-1,D1
.a:	MOVEQ	#0,D0
	MOVE.W	(A0)+,D0
	ADD.L	D0,(A1)+
	DBF	D1,.a
	MOVE.W	DbgOut+22,D0		; longest frame of the run
	CMP.L	(A1),D0
	BLS.S	.nw
	MOVE.L	D0,(A1)
.nw:	ADDQ.L	#4,A1
	MOVE.W	DbgOut+4,D0		; least spare time in one window
	CMP.L	(A1),D0
	BCC.S	.nm
	MOVE.L	D0,(A1)
.nm:	ADDQ.L	#4,A1
	MOVE.W	DbgOut,D0		; fewest frames in one window
	CMP.L	(A1),D0
	BCC.S	.nf
	MOVE.L	D0,(A1)
.nf:	ADDQ.L	#1,4(A1)		; windows
	MOVEM.L	(SP)+,D0-D1/A0-A1
	RTS

; DbgAutoFill: the text, from AutoWriteResult.
DbgAutoFill:
	LEA	DbgAuto,A1
	LEA	DbgAutoTxt+6,A2
	MOVEQ	#DbgAutoN-1,D3
.f:	MOVE.L	(A1)+,D0
	MOVE.L	A2,A0
	JSR	AutoHex
	LEA	15(A2),A2
	DBF	D3,.f
	IFEQ	NO_RTG
	MOVEQ	#0,D0
	MOVE.B	RtgScanLv,D0
	MOVE.L	A2,A0
	JSR	AutoHex
	ENDC
	RTS

DbgAuto:	DS.L	13		; DbgOut's figures
	DC.L	0		; wmax
	DC.L	$FFFF		; wmin
	DC.L	$FFFF		; fmin
	DC.L	0		; wins
DbgAutoN	= (*-DbgAuto)/4
DbgAutoTxt:
	DC.B	"frms=$00000000 vbls=$00000000 wait=$00000000 cpu_=$00000000 "
	DC.B	"bg__=$00000000 spr_=$00000000 vbli=$00000000 late=$00000000 "
	DC.B	"rtg_=$00000000 copy=$00000000 totl=$00000000 wrst=$00000000 "
	DC.B	"othr=$00000000 wmax=$00000000 wmin=$00000000 fmin=$00000000 "
	DC.B	"wins=$00000000 scan=$00000000",10
DbgAutoTxtEnd:
	CNOP	0,4
	ENDC
