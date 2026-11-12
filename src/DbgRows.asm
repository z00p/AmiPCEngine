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
; AGA chunky mode (AGC test builds): the AGA panel, with RTG (composing, colour registers, C2P) in BG's
; place and COPY (the buffer swap and colour loads) in SPR's; row 1 adds SKIP, pictures not converted
; because the frame before ran late (DLAY's place).
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
	IFNE	AGC
	TST.B	AgcOn
	BEQ.S	.ag
	BSR	DbgAgcPanel
.ag:
	ENDC
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

	IFNE	AGC
; DbgAgcPanel: AGA chunky mode (DbgInit, after SetPicTop). The panel goes under the picture, in the copper's scroll
; list (unused with RtgOn), and the one above it is turned into no-ops. With the panel above, the 352-wide picture
; showed 30 px left with wrong colours in WinUAE (cause not found); this way the frame runs as in the normal build
; up to the picture's end.
; PAL: picture to line PicTop+233 ($118), panel on lines $11B-$12B. The panel fetches DDF $28-$C8 (11 longs)
; from 4 bytes before each row with no delay, so its byte 0 is at H $81, where its window starts.
; NTSC: the picture runs past the frame's end and there is no panel.
DbgAgcPanel:
	MOVEM.L	D0-D1/A0,-(SP)
	LEA	DbgCopPt,A0
	MOVE.W	#(DbgCopEnd-DbgCopPt)/4-1,D1
.n:	MOVE.L	#$01FE0000,(A0)+	; no-op moves
	DBF	D1,.n
	MOVE.W	PicTop,D0
	ADD.W	#233-256,D0		; the picture's first line after (below line 256)
	LEA	CopperScrolls+AGCWRAP,A0	; after the ring wrap's block (AgcPlanePtrs), which ends past line 255
	MOVE.B	D0,(A0)+
	MOVE.B	#$07,(A0)+
	MOVE.W	#$FFFE,(A0)+
	MOVE.L	#$01000200,(A0)+	; no planes
	MOVE.W	#$008E,(A0)+		; DIWSTRT H $81 for the panel lines (the 4 bytes before each row hidden; V never matches)
	MOVE.W	D0,D1
	ADDQ.W	#3,D1
	LSL.W	#8,D1
	MOVE.B	#$81,D1
	MOVE.W	D1,(A0)+
	MOVE.L	#DbgPanel-4,D1
	SWAP	D1
	MOVE.W	#$00E0,(A0)+
	MOVE.W	D1,(A0)+
	SWAP	D1
	MOVE.W	#$00E2,(A0)+
	MOVE.W	D1,(A0)+
	MOVE.L	#$0108FFFC,(A0)+	; 40 bytes a row, 44 fetched
	MOVE.L	#$010AFFFC,(A0)+
	MOVE.L	#$01020000,(A0)+	; no delay
	MOVE.L	#$00920028,(A0)+	; DDFSTRT $28: 11 longs (the picture fetches 12 from $18)
	MOVE.L	#$01800113,(A0)+	; register 0 and 1 (bank 0): the panel's colours
	MOVE.L	#$01820FF8,(A0)+
	ADDQ.W	#3,D0
	MOVE.B	D0,(A0)+
	MOVE.B	#$07,(A0)+
	MOVE.W	#$FFFE,(A0)+
	MOVE.L	#$01001200,(A0)+	; 1 plane
	ADD.W	#17,D0
	MOVE.B	D0,(A0)+
	MOVE.B	#$07,(A0)+
	MOVE.W	#$FFFE,(A0)+
	MOVE.L	#$01000200,(A0)+
	MOVE.L	#$01800000,(A0)+	; register 0 black again (the colour block sets 1 and the rest at the frame's top)
	MOVE.L	#$FFFFFFFE,(A0)+
	ADDQ.W	#1,D0
	MOVE.B	D0,Copper+6		; DIWSTOP V: the window open to the panel's end (bit 8 = NOT bit 7)
	MOVEM.L	(SP)+,D0-D1/A0
	RTS
	ENDC

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
	IFEQ	NO_LATESTART|NO_RTG
DbgLapDelay:
	MOVE.L	A0,-(SP)
	LEA	DbgDelay,A0
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
	MOVE.W	DbgDelay,(A1)+
	IFNE	AGC
	TST.B	AgcOn			; AGA chunky mode: SKIP (pictures not converted) in DLAY's place
	BEQ.S	.nsk
	MOVE.W	AgcSkipN,-2(A1)
	CLR.W	AgcSkipN
.nsk:
	ENDC
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
	IFNE	AGC
	TST.B	AgcOn
	BNE.S	.aga
	ENDC
	MOVEQ	#DbgColsR,D3		; RTG: drawn on the screen by RtgCopy
	LEA	DbgOut+20,A0
	LEA	DbgPanelR,A1
	MOVEQ	#4,D1			; TOTL WRST OTHR DLAY
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
	IFNE	DbgProbe
	LEA	PrbOut,A0		; the last frame's PrbSums, and MWR/CR
	LEA	PrbSums,A1
	MOVEQ	#PrbSumsN-1,D1
.po:	MOVE.W	(A1)+,(A0)+
	DBF	D1,.po
	MOVE.W	PrbChg,(A0)+
	LEA	PrbOut,A0
	LEA	DbgPanel,A1
	MOVEQ	#8,D1
	ELSE
	LEA	DbgOut+20,A0
	LEA	DbgPanel,A1
	MOVEQ	#3,D1
	IFNE	AGC
	TST.B	AgcOn
	BEQ.S	.ag3
	MOVEQ	#4,D1			; TOTL WRST OTHR SKIP
.ag3:
	ENDC
	ENDC
	BSR	DbgRow
	IFNE	AGC
	TST.B	AgcOn			; AGA chunky mode: RTG and COPY in the BG and SPR places
	BEQ.S	.agc0
	MOVE.L	DbgOut+16,DbgOut+8
.agc0:
	ENDC
	LEA	DbgOut,A0
	LEA	DbgPanel+DbgCols*DbgRowGap,A1
	MOVEQ	#8,D1
	BSR	DbgRow
.out:
	IFNE	DbgProbe
	CLR.W	PrbBat			; counts are per PCE frame
	CLR.W	PrbTil
	CLR.W	PrbCpu
	CLR.W	PrbDma
	CLR.W	PrbChg
	ENDC
	MOVEM.L	(SP)+,D0-D3/A0-A3
	RTS

	IFNE	DbgProbe
; DbgProbeScan: before PrintGFX, the tiles written since the last frame (TabRedef):
; how many, the first and the last. Row 1 (AGA) then shows, for the frame before
; the window ended: BAT  TIL  DIRT LO   HI   CPU  DMA  CHG
;   BAT  cells redrawn because their BAT word changed
;   TIL  cells redrawn because their tile was written
;   DIRT tiles (16 VRAM words) written; LO, HI the first and last of them
;   CPU  VRAM writes by the CPU (words, or high bytes); DMA words by VRAM DMA
;   CHG  bytes of those CPU writes that changed VRAM
DbgProbeScan:
	MOVEM.L	D0-D2/A0-A1,-(SP)
	LEA	TabRedef,A0
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVE.W	#$FFFF,PrbLo
	CLR.W	PrbHi
	MOVE.W	#2048-1,D2
.s:	TST.B	(A0)+
	BEQ.S	.n
	ADDQ.W	#1,D1
	CMP.W	PrbLo,D0
	BCC.S	.h
	MOVE.W	D0,PrbLo
.h:	MOVE.W	D0,PrbHi
.n:	ADDQ.W	#1,D0
	DBF	D2,.s
	MOVE.W	D1,PrbDirt
	MOVE.L	PrbSnapNew,A0		; snapshot what PrintGFX is given, into the older buffer
	MOVE.L	PrbSnapOld,PrbSnapNew
	MOVE.L	A0,PrbSnapOld
	MOVE.L	PrbSnapNew,A0
	LEA	VRAM,A1
	MOVE.W	#65536/16-1,D2
.v:	MOVE.L	(A1)+,(A0)+
	MOVE.L	(A1)+,(A0)+
	MOVE.L	(A1)+,(A0)+
	MOVE.L	(A1)+,(A0)+
	DBF	D2,.v
	LEA	TabRedef,A1
	MOVE.W	#2048/4-1,D2
.t:	MOVE.L	(A1)+,(A0)+
	DBF	D2,.t
	LEA	VDP_Regs,A1
	MOVEQ	#64/4-1,D2
.r:	MOVE.L	(A1)+,(A0)+
	DBF	D2,.r
	LEA	VDP_Pal,A1
	MOVE.W	#1024/4-1,D2
.p:	MOVE.L	(A1)+,(A0)+
	DBF	D2,.p
	MOVEM.L	(SP)+,D0-D2/A0-A1
	RTS

; PrbDumpWrite (Esc, OS alive): PROGDIR:pcevram.bin = the newest snapshot, then
; the one before: each VRAM 64K, TabRedef 2K, VDC regs 64, palette 1K.
PrbDumpWrite:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.L	$4.W,A6
	LEA	PrbDosName,A1
	MOVEQ	#0,D0
	JSR	-$228(A6)		; OpenLibrary
	TST.L	D0
	BEQ.S	.x
	MOVE.L	D0,A6
	MOVE.L	#PrbDumpName,D1
	MOVE.L	#1006,D2		; MODE_NEWFILE
	JSR	-30(A6)			; Open
	MOVE.L	D0,D4
	BEQ.S	.cl
	MOVE.L	D4,D1
	MOVE.L	PrbSnapNew,D2
	MOVE.L	#PrbSnapLen,D3
	JSR	-48(A6)			; Write
	MOVE.L	D4,D1
	MOVE.L	PrbSnapOld,D2
	MOVE.L	#PrbSnapLen,D3
	JSR	-48(A6)			; Write
	MOVE.L	D4,D1
	JSR	-36(A6)			; Close
.cl:	MOVE.L	A6,A1
	MOVE.L	$4.W,A6
	JSR	-$19E(A6)		; CloseLibrary
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
PrbDosName:	DC.B	"dos.library",0
PrbDumpName:	DC.B	"PROGDIR:pcevram.bin",0
	CNOP	0,4
PrbSnapLen	= 65536+2048+64+1024
PrbSnapNew:	DC.L	PrbSnapA
PrbSnapOld:	DC.L	PrbSnapB

	CNOP	0,2
PrbSums:
PrbBat:		DC.W	0
PrbTil:		DC.W	0
PrbDirt:	DC.W	0
PrbLo:		DC.W	0
PrbHi:		DC.W	0
PrbCpu:		DC.W	0
PrbDma:		DC.W	0
PrbSumsN	= (*-PrbSums)/2
PrbChg:		DC.W	0
PrbOut:		DS.W	8
	ENDC

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
DbgDelay:	DC.W	0	; lines waited before the frame (LateStart, RTG)
DbgSumsN	= (*-DbgSums)/2
DbgWorst:	DC.W	0
DbgLast:	DC.W	0
DbgFrameT0:	DC.W	0
DbgWinT0:	DC.W	0
DbgVbl0:	DC.W	0
	CNOP	0,4
DbgPrevVb:	DC.L	0
DbgWinVb:	DC.L	0
DbgOut:		DS.W	14

	IFNE	AutoExit
; AutoExit + DbgRows: the windows' figures over the whole run, for AmiPCE.result (tools/a1200run.py).
DbgAutoSum:
	MOVEM.L	D0-D1/A0-A1,-(SP)
	LEA	DbgOut,A0
	LEA	DbgAuto,A1
	MOVEQ	#14-1,D1
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

DbgAuto:	DS.L	14		; DbgOut's figures
	DC.L	0		; wmax
	DC.L	$FFFF		; wmin
	DC.L	$FFFF		; fmin
	DC.L	0		; wins
DbgAutoN	= (*-DbgAuto)/4
DbgAutoTxt:
	DC.B	"frms=$00000000 vbls=$00000000 wait=$00000000 cpu_=$00000000 "
	DC.B	"bg__=$00000000 spr_=$00000000 vbli=$00000000 late=$00000000 "
	DC.B	"rtg_=$00000000 copy=$00000000 totl=$00000000 wrst=$00000000 "
	DC.B	"othr=$00000000 dlay=$00000000 wmax=$00000000 wmin=$00000000 fmin=$00000000 "
	DC.B	"wins=$00000000 scan=$00000000",10
DbgAutoTxtEnd:
	CNOP	0,4
	ENDC
