; AGC.asm: test switch AGC, the AGA chunky mode (step 1).
; The RTG composer (RtgFrame) draws the picture as on RTG. Each changed line goes into a chunky buffer as AGA
; colour registers through a sticky palette: a PCE colour keeps its register while any pixel shows it, a new
; colour takes a free register (a count of 0). The changed lines then go through a C2P into 8 interleaved
; planes; there are two plane buffers, and the one just drawn is shown with its changed colours at the next
; vblank (AgcFlip, in the vertical blank interrupt).
; Hooks: AgcStart after RtgStart, AgcOpen after RtgPlayOpen, RtgTakeover, RtgCopy, RtgOutLine and the end of
; RtgFrame. With RTG wanted and present AGC stays off.
; In the main code hunk (Main.asm includes it there, no sections), so the ProfOn profiler sees it; the
; composer in RTG.asm's own section counts as 'outside'.

	IFNE	NO_RTGFIX
	FAIL	AGC needs NO_RTGFIX=0 (the big buffers)
	ENDC

AGCSW	= 352			; the composer's width (RtgScrW): R-Type's 336 fits, 256-px games centred
AGCQ	= 40			; the picture's pixel 0 at chunky byte RtgOX+AGCQ
AGCW	= 416			; chunky bytes a line: the C2P reads 384 from byte f (the fine scroll, 0-31)
AGCH	= RTGLINES		; lines
AGCRW	= 48			; ring bytes a line: 12 longs fetched (DDF $18-$C8, 32-bit fetch), modulo 0
AGCFW	= AGCRW*8		; pixels fetched a line
AGCP	= AGCRW*AGCH		; one plane's ring (bytes); a 1D ring, so a line may start anywhere in it
AGCPS	= AGCP+2*AGCRW		; plane stride: the two rings (one per scroll band, AgcYb), each followed by
				; AGCRW bytes mirroring its first AGCRW (a line that straddles a ring's end reads on into them)
AGCBUF	= AGCPS*8		; one plane buffer (planes one after the other: see AgcPlanePtrs)
AGCT	= 8*AGCP		; T's range: ring pixels
AGCVIS	= 232			; lines the display window shows (SetPicTop)
AGCWRAP	= 24*4			; the rings' copper block at the start of CopperScrolls (AgcPlanePtrs)
AGCOVMAX = 64			; colours on register 0 for a frame when every register is in use
AGCSHB	= 8*AGCPS		; one shadow: a byte for each plane pixel (rings and slacks)
AGCSHSZ	= 2*AGCSHB		; the two shadows (what each plane buffer shows)

	IFND	AgcNoShift		; test builds: 1 = no display shift (T stays 0)
AgcNoShift = 0
	ENDC
	IFND	AgcNoHx			; test builds: 1 = vertical shift only
AgcNoHx	= 0
	ENDC
	IFND	AgcNoSeg		; test builds: 1 = one ring (no split at a fixed band)
AgcNoSeg = 0
	ENDC


; AgcStart: program start, OS alive, after RtgStart. Without RTG: the big buffers, and AGC is wanted.
	CNOP	0,4
AgcStart:
	MOVEM.L	D0-D1/A0-A1/A6,-(SP)
	TST.B	RtgWant
	BNE.S	.x
	TST.L	RtgBig
	BNE.S	.ok
	MOVE.L	4.W,A6
	MOVE.L	#RTGBIGSZ,D0
	MOVE.L	#$10000,D1		; MEMF_CLEAR
	JSR	-198(A6)		; AllocMem
	MOVE.L	D0,RtgBig
	BEQ.S	.x
	MOVE.L	D0,RtgCompP		; (the chunky buffer)
	ADD.L	#RTGCOMPSZ,D0
	MOVE.L	D0,RtgOldP
	ADD.L	#RTGOLDSZ,D0
	MOVE.L	D0,RtgTCacheP
	ADD.L	#RTGTCSZ,D0
	MOVE.L	D0,RtgSCacheP
	IFEQ	ScanOff
	ADD.L	#RTGSCSZ,D0
	MOVE.L	D0,RtgScanTP
	ENDC
.ok:	TST.L	AgcShad
	BNE.S	.ok2
	MOVE.L	4.W,A6
	MOVE.L	#AGCSHSZ,D0		; no memory for them: every group written
	MOVEQ	#0,D1
	JSR	-198(A6)		; AllocMem
	MOVE.L	D0,AgcShad
.ok2:	ST	AgcWant
.x:	MOVEM.L	(SP)+,D0-D1/A0-A1/A6
	RTS

; AgcOpen: before play, OS alive, after RtgPlayOpen. The composer's geometry is the AGA window; RtgCol gives
; the PCE colour itself (in both words), so RtgPal holds each VCE entry's colour.
	CNOP	0,4
AgcOpen:
	MOVEM.L	D0-D2/A0-A1,-(SP)
	TST.B	RtgOn
	BNE.S	.x
	TST.B	AgcWant
	BEQ.S	.x
	MOVE.W	#AGCSW,RtgScrW
	MOVE.W	#AGCH,RtgScrH
	LEA	RtgCol,A0
	MOVEQ	#0,D0
.c:	MOVE.W	D0,D1
	SWAP	D1
	MOVE.W	D0,D1
	MOVE.L	D1,(A0)+
	ADDQ.W	#1,D0
	CMP.W	#512,D0
	BNE.S	.c
	LEA	AgcRGB,A0		; PCE colour (GGGRRRBBB) -> AGA 12-bit
	LEA	AgcLv(PC),A1
	MOVEQ	#0,D0
.r:	MOVE.W	D0,D1
	LSR.W	#3,D1
	AND.W	#7,D1
	MOVE.B	(A1,D1.W),D1		; R
	LSL.W	#4,D1
	MOVE.W	D0,D2
	LSR.W	#6,D2
	OR.B	(A1,D2.W),D1		; G
	LSL.W	#4,D1
	MOVE.W	D0,D2
	AND.W	#7,D2
	OR.B	(A1,D2.W),D1		; B
	MOVE.W	D1,(A0)+
	ADDQ.W	#1,D0
	CMP.W	#512,D0
	BNE.S	.r
	BSR	AgcReset
	JSR	RtgReset
	ST	AgcOn
	ST	RtgOn
.x:	MOVEM.L	(SP)+,D0-D2/A0-A1
	RTS

AgcLv:	DC.B	0,2,4,6,9,11,13,15	; 3-bit level -> 4 bits, rounded

; AgcReset: a new run. No colour known, every register free but register 0 (black, the whole chunky
; buffer), both plane buffers clear and every line to convert; the copper set for the 8 planes (rings, AgcPlanePtrs).
AgcReset:
	MOVEM.L	D0-D1/A0,-(SP)
	LEA	AgcMap,A0
	MOVE.W	#512-1,D0
.m:	MOVE.W	#-1,(A0)+
	DBF	D0,.m
	LEA	AgcRegCol,A0
	MOVE.W	#256-1,D0
.rc:	MOVE.W	#-1,(A0)+
	DBF	D0,.rc
	LEA	AgcRegNew,A0		; every colour register loaded at the first flip
	MOVE.W	#256/4-1,D0
	MOVEQ	#-1,D1
.rn:	MOVE.L	D1,(A0)+
	DBF	D0,.rn
	ST	AgcColNew
	LEA	AgcPendF,A0		; no colours waiting for a flip
	MOVEQ	#256/4-1,D0
.pf:	CLR.L	(A0)+
	DBF	D0,.pf
	SF	AgcPendAny
	CLR.W	AgcNext
	CLR.W	AgcBack
	SF	AgcPend
	CLR.W	AgcOvN
	CLR.W	AgcOvAll
	BSR	AgcClear
	LEA	PantGfx,A0		; both plane buffers (and the 8 bytes before)
	MOVE.L	#(8+2*AGCBUF)/4-1,D0
.p:	CLR.L	(A0)+
	SUBQ.L	#1,D0
	BPL.S	.p
	MOVE.W	#$3071,Copper+2		; DIWSTRT: H $71
	MOVE.W	#$18C1,Copper+6		; DIWSTOP: H $1C1, 336 wide (a stop the beam reaches: $1D1 is past the line's end);
					; SetPicTop sets the V bytes later
	MOVE.W	#$0018,Copper+10	; DDFSTRT: 12 longs (no sprites in AGC, so no slots lost), the last fetched by $D8
	MOVE.W	#$00C8,Copper+14	; DDFSTOP (DDFSTOP $D8 ran the fetch past the line's end ($E2): the copper lost its
				; slots there, and a $FFDF wait never ended)
	CLR.W	Copper+18		; BPL1MOD, BPL2MOD 0: the ring's lines follow on
	CLR.W	Copper+22
	CLR.W	ScrBits+2		; BPLCON1: the fine scroll f, 0-31 px (AgcPlanePtrs). Fetched pixel 0 at H $41 + f,
				; the window from H $71: window pixel w = fetched pixel w+48-f
	AND.W	#$00FF,CopBplcon4+2	; no bitplane XOR
	CLR.L	AgcTs			; one ring, at T 0, in both buffers; no picture position known
	CLR.L	AgcTs+4
	LEA	AgcTB,A0
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	MOVE.W	#AGCH,AgcYb
	MOVE.W	#AGCH,AgcPYb
	MOVE.W	#AGCH,AgcYbB
	MOVE.W	#AGCH,AgcYbB+2
	CLR.W	AgcPKOk
	MOVE.L	#$FFFFFFFE,CopperScrolls+AGCWRAP	; the copper list's end after the wrap block (the debug
					; panel goes there later)
	MOVE.W	#1,AgcBack		; buffer 1 (clear) shown, buffer 0 drawn first
	BSR	AgcPlanePtrs
	CLR.W	AgcBack
	MOVEM.L	(SP)+,D0-D1/A0
	RTS

; AgcClear: the chunky buffer all register 0 (black), the counts to match, every line to convert into both
; plane buffers.
AgcClear:
	MOVEM.L	D0-D2/A0-A1,-(SP)
	MOVE.L	RtgCompP,A0
	MOVE.W	#AGCW*AGCH/4-1,D0
.c:	CLR.L	(A0)+
	DBF	D0,.c
	LEA	AgcCnt,A0
	MOVE.W	#256-1,D0
.n:	CLR.L	(A0)+
	DBF	D0,.n
	MOVE.L	#AGCW*AGCH,AgcCnt
	LEA	AgcMap,A0		; register 0 = black
	LEA	AgcRegCol,A1
	MOVE.W	(A1),D1		; its old colour unmapped if still mapped to it
	BMI.S	.b
	TST.W	(A0,D1.W*2)
	BNE.S	.b
	MOVE.W	#-1,(A0,D1.W*2)
.b:	CLR.W	(A1)
	CLR.W	(A0)
	BSR	AgcEInv
	ST	AgcRegNew
	ST	AgcColNew
	LEA	AgcStale,A0
	MOVE.W	#AGCH-1,D0
.s:	MOVE.B	#3,(A0)+
	DBF	D0,.s
	MOVE.B	#3,AgcWide		; the margins too, once into each plane buffer
	MOVEM.L	(SP)+,D0-D2/A0-A1
	RTS

; AgcEInv: the entry -> register cache (AgcERg) emptied: after any change of RtgPal (a new frame's colours,
; mid-frame VCE writes) or of what a register holds. All registers kept.
AgcEInv:
	MOVEM.L	D0-D1/A0,-(SP)
	LEA	AgcERg,A0
	MOVEQ	#-1,D1
	MOVEQ	#512/16-1,D0
.l:	MOVE.L	D1,(A0)+
	MOVE.L	D1,(A0)+
	MOVE.L	D1,(A0)+
	MOVE.L	D1,(A0)+
	MOVE.L	D1,(A0)+
	MOVE.L	D1,(A0)+
	MOVE.L	D1,(A0)+
	MOVE.L	D1,(A0)+
	DBF	D0,.l
	MOVEM.L	(SP)+,D0-D1/A0
	RTS

; AgcTakeover: just after CongelaAMIGA (in RtgTakeover's place). Bitplanes and copper stay on; no sprites.
AgcTakeover:
	MOVE.W	#$0020,$DFF096		; SPREN off
	MOVEM.L	D0/A0,-(SP)
	LEA	$DFF140,A0		; every sprite disarmed, no data
	MOVEQ	#8-1,D0
.s:	CLR.L	(A0)+
	CLR.L	(A0)+
	DBF	D0,.s
	MOVEM.L	(SP)+,D0/A0
	RTS

; AgcOutLine: from RtgOutLine (after RtgShift), line RtgY of VCE entries in RtgLineB (+32 bytes) against the
; last frame's. A changed line goes to the chunky buffer as registers; a line whose registers changed is
; marked to convert into both plane buffers. Registers as RtgOutLine (D0-D1/D6-D7/A0-A3 used).
	CNOP	0,4
AgcOutLine:
	MOVEM.L	D2-D5/A4-A6,-(SP)
	MOVE.W	RtgY,D7
	BNE.S	.l1
	TST.B	RtgClear		; geometry changed: the margins black again
	BEQ.S	.l0
	SF	RtgClear
	BSR	AgcClear
.l0:	TST.B	RtgFull			; colours changed this frame: entry -> register anew
	BEQ.S	.l0k
	BSR	AgcEInv
.l0k:	MOVE.L	RtgPLP,AgcPLP
	BRA.S	.nc
.l1:	MOVE.L	RtgPLP,D0		; VCE writes applied before this line: anew
	CMP.L	AgcPLP,D0
	BEQ.S	.nc
	MOVE.L	D0,AgcPLP
	BSR	AgcEInv
.nc:	LEA	RtgLineB+32,A0
	MOVEQ	#0,D0
	MOVE.W	D7,D0
	MOVEQ	#10,D1
	LSL.L	D1,D0			; x 1024 (RTGMW words)
	MOVE.L	RtgOldP,A1		; (RtgBuf: RTG.asm comes later)
	ADD.L	D0,A1
	MOVE.W	RtgW,D6
	TST.B	RtgFull
	BNE.S	.conv
	LSR.W	#1,D6
	SUBQ.W	#1,D6
	MOVE.L	A0,A2
	MOVE.L	A1,A3
.cmp:	CMPM.L	(A2)+,(A3)+
	DBNE	D6,.cmp
	BEQ.S	.x			; same as before
	MOVE.W	RtgW,D6
.conv:	MOVE.L	RtgCompP,A3
	MOVE.W	D7,D0
	MULU.W	#AGCW,D0
	ADD.L	D0,A3
	MOVE.W	RtgOX,D0
	ADD.W	#AGCQ,D0
	ADD.W	D0,A3
	LEA	RtgPal,A2
	LEA	AgcERg,A4
	LEA	AgcCnt,A5
	LEA	AgcMap,A6
	MOVEQ	#0,D5			; registers changed on the line
	SUBQ.W	#1,D6
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVEQ	#0,D2
.c:	MOVE.W	(A0)+,D0
	MOVE.W	D0,(A1)+
	MOVE.W	(A4,D0.W*2),D1		; the entry's register (cache)
	BMI.S	.miss
.h:	CMP.B	(A3)+,D1
	BNE.S	.chg
	DBF	D6,.c
	BRA.S	.done
.chg:	MOVE.B	-1(A3),D2
	SUBQ.L	#1,(A5,D2.W*4)
	ADDQ.L	#1,(A5,D1.W*4)
	MOVE.B	D1,-1(A3)
	MOVEQ	#1,D5
	DBF	D6,.c
.done:	TST.W	D5
	BEQ.S	.x
	LEA	AgcStale,A0
	MOVE.B	#3,(A0,D7.W)
.x:	MOVEM.L	(SP)+,D2-D5/A4-A6
	RTS
.miss:	MOVE.W	D0,D2			; entry -> colour -> register, then cached
	MOVE.W	(A2,D0.W*4),D0
	MOVE.W	(A6,D0.W*2),D1
	BPL.S	.m1
	BSR.S	AgcAlloc		; (may clear the cache: stored after)
.m1:	MOVE.W	D1,(A4,D2.W*2)
	MOVEQ	#0,D2
	BRA.S	.h

; AgcAlloc: D0.W = a colour with no register -> D1.W = its register. The next free register (count 0) from
; the last one taken, its old colour unmapped. None free: register 0 for the rest of the frame (AgcOvN).
AgcAlloc:
	MOVEM.L	D0/D2-D3/A0-A1,-(SP)
	LEA	AgcCnt,A0
	MOVE.W	AgcNext,D1
	MOVE.W	#256-1,D3
.f:	ADDQ.W	#1,D1
	AND.W	#255,D1
	TST.L	(A0,D1.W*4)
	BEQ.S	.got
	DBF	D3,.f
	MOVEQ	#0,D1			; none: register 0, undone at the end of the frame
	MOVE.W	AgcOvN,D2
	CMP.W	#AGCOVMAX,D2
	BCC.S	.x
	ADDQ.W	#1,AgcOvN
	ADDQ.W	#1,AgcOvAll
	LEA	AgcOvList,A0
	MOVE.W	D0,(A0,D2.W*2)
	LEA	AgcMap,A1
	MOVE.W	D1,(A1,D0.W*2)
	ST	AgcOvInv		; the cache cleared again when this is undone
	BRA.S	.x
.got:	MOVE.W	D1,AgcNext
	LEA	AgcRegCol,A0
	LEA	AgcMap,A1
	MOVE.W	(A0,D1.W*2),D2		; the register's old colour, if it is still mapped to it
	BMI.S	.g1
	CMP.W	(A1,D2.W*2),D1
	BNE.S	.g1
	MOVE.W	#-1,(A1,D2.W*2)
	BSR	AgcEInv			; entries cached on this register had the old colour
.g1:	MOVE.W	D0,(A0,D1.W*2)
	MOVE.W	D1,(A1,D0.W*2)
	LEA	AgcRegNew,A0
	ST	(A0,D1.W)
	ST	AgcColNew
.x:	MOVEM.L	(SP)+,D0/D2-D3/A0-A1
	RTS

; AgcC2P: the end of RtgFrame (all registers free). Lines not yet in the back plane buffer go through the
; C2P; AgcFlip shows that buffer at the next vblank. Display shift: plane memory holds two 1D rings, ring 0
; for picture lines 0 .. AgcYb-1 and ring 1 for the rest (AgcScrKey splits off a band that scrolls apart from
; the main region, such as a fixed status bar; AgcYb = AGCH: one ring). A ring of n lines is n x AGCRW bytes
; and has its own T: chunky byte c of the ring's line y' goes to its ring pixel T + y'*AGCFW + c (mod 8 x its
; bytes), and T moves with the band's scroll, so each band keeps its place in its ring and the group compare
; finds only exposed edges, sprites and what really changed. Line y' starts at ring byte O + y'*AGCRW (mod the
; ring), O = (T+f)/8, f = -T & 31 (the fine scroll, BPLCON1), and its 12 groups are chunky bytes f .. f+383
; (AgcSeg). Only the groups the picture covers (RtgOX+AGCQ, RtgW) are converted: AgcOutLine writes nothing
; outside them, and the margins change only in AgcClear (AgcWide: the next conversion into each buffer takes the
; whole width) or when a ring moved since the buffer's last picture (AgcAll: its lines all compared, whole width).
; Group compare: a shadow picture per plane buffer (AgcShad, a byte per plane pixel) holds what the buffer
; shows; a group equal to it is not written (chip writes are most of the cost on the PiStorm). AgcWide
; conversions write every group and fill the shadow. Picture skip: when the last frame ran past the vblank
; (AgcLate, main loop), this frame's picture is not converted, at most one in three; its lines stay stale for
; the next one, and AgcFlip shows nothing new (colours with it), so the core keeps the PCE's speed.
	CNOP	0,4
AgcC2P:
	MOVE.W	AgcOvN,D0		; colours put on register 0 for this frame only
	BEQ.S	.ov
	CLR.W	AgcOvN
	LEA	AgcOvList,A0
	LEA	AgcMap,A1
	SUBQ.W	#1,D0
.o:	MOVE.W	(A0)+,D1
	MOVE.W	#-1,(A1,D1.W*2)
	DBF	D0,.o
.ov:	TST.B	AgcOvInv
	BEQ.S	.ov2
	SF	AgcOvInv
	BSR	AgcEInv
.ov2:	TST.B	AgcLate
	BEQ.S	.dr
	CMP.B	#2,AgcDrawn		; at most one picture in three: games that show half their sprites each frame
	BCS.S	.dr			; (flicker past the per-line limit) would lose the same half every time
	CLR.B	AgcDrawn
	ST	AgcSkipped
	ADDQ.W	#1,AgcSkipN
	RTS
.dr:	SF	AgcPend			; first: no flip while this buffer is drawn (a picture still waiting is
					; drawn over by this one; its colours stay in AgcPendF)
	SF	AgcSkipped
	CMP.B	#2,AgcDrawn
	BCC.S	.dr1
	ADDQ.B	#1,AgcDrawn
.dr1:
	IFNE	AutoExit
	ADDQ.L	#1,AgcPicN
	ENDC
	MOVEQ	#1,D0
	MOVE.W	AgcBack,D1
	LSL.B	D1,D0
	MOVE.B	D0,AgcBit
	MOVE.W	AgcYb,D3		; this picture's split against the buffer's last
	SF	AgcLay
	CMP.W	(AgcYbB.L,D1.W*2),D3
	BEQ.S	.y0
	MOVE.W	D3,(AgcYbB.L,D1.W*2)
	ST	AgcLay			; a new split: every line compared
	IFNE	AutoExit
	ADDQ.L	#1,AgcLayN
	ENDC
.y0:	LEA	AgcTB,A0		; each ring's place in this buffer: T (AgcScrKey)
	LEA	(A0,D1.W*8),A0
	MOVEQ	#0,D2
.ys:	MOVE.L	(AgcTs.L,D2.W*4),D3
	MOVE.B	AgcLay,D5
	CMP.L	(A0,D2.W*4),D3
	BEQ.S	.ys1
	MOVE.L	D3,(A0,D2.W*4)
	ST	D5			; moved since this buffer's last picture: the ring's lines all compared
	IFNE	AutoExit
	ADDQ.L	#1,AgcShN
	ENDC
.ys1:	MOVE.B	D5,(AgcAllS.L,D2.W)
	ADDQ.W	#1,D2
	CMP.W	#2,D2
	BNE.S	.ys
	MOVE.L	#PantGfx+8+2*AGCPS,D3	; plane 2
	MOVE.L	AgcShad,D2
	ST	AgcForce		; (no shadows: every group written)
	TST.L	D2
	BEQ.S	.sh
	SF	AgcForce
.sh:	TST.W	D1
	BEQ.S	.b0
	ADD.L	#AGCBUF,D3
	ADD.L	#AGCSHB,D2
.b0:	MOVE.L	D3,AgcPB
	MOVE.L	D2,AgcSB0
	SF	AgcWNow
	AND.B	AgcWide,D0
	BEQ.S	.lp
	EOR.B	D0,AgcWide
	ST	AgcForce		; every group written, the whole width
	ST	AgcWNow
.lp:	MOVE.L	RtgCompP,AgcLC
	LEA	AgcStale,A6
	CLR.W	AgcLn
	MOVEQ	#0,D0
	BSR	AgcSeg			; ring 0
.line:	MOVE.W	AgcLn,D0
	CMP.W	AgcYb,D0
	BNE.S	.l0
	MOVEQ	#1,D0
	BSR	AgcSeg			; ring 1 from the split
.l0:	MOVE.B	AgcBit,D0
	AND.B	(A6),D0
	BNE.S	.st
	TST.B	AgcAll			; the ring moved: every line against what the buffer shows
	BEQ	.next
	BRA.S	.go
.st:	EOR.B	D0,(A6)
.go:	MOVE.L	AgcLC,A0
	ADD.W	AgcCOff,A0
	MOVE.L	A0,A4
	ADD.W	AgcCLen,A4
	MOVE.L	AgcAY,D0
	ADD.W	AgcGOff,D0
	MOVE.L	AgcP2B,A3		; planes 0-3 around A3 (plane 2), 4-7 around A2 (plane 6)
	ADD.L	D0,A3
	MOVE.L	A3,A2
	ADD.L	#4*AGCPS,A2
	LSL.L	#3,D0
	MOVE.L	AgcSB,A1		; (0 + offset without shadows: not read then)
	ADD.L	D0,A1
.grp:	CMP.L	AgcP2E,A3		; past the ring's end: on from its start
	BCS.S	.g1
	SUB.L	AgcPsz,A3
	SUB.L	AgcPsz,A2
	SUB.L	AgcPsz8,A1
.g1:
	IFNE	AutoExit
	ADDQ.L	#1,AgcGrpC
	ENDC
	TST.B	AgcForce
	BNE.S	.wr
	MOVEM.L	(A0),D0-D7		; the group against what the buffer shows
	CMP.L	(A1),D0
	BNE.S	.cp
	CMP.L	4(A1),D1
	BNE.S	.cp
	CMP.L	8(A1),D2
	BNE.S	.cp
	CMP.L	12(A1),D3
	BNE.S	.cp
	CMP.L	16(A1),D4
	BNE.S	.cp
	CMP.L	20(A1),D5
	BNE.S	.cp
	CMP.L	24(A1),D6
	BNE.S	.cp
	CMP.L	28(A1),D7
	BNE.S	.cp
	CMP.L	AgcMirE,A3		; the ring's first line: its copy in the slack too
	BCS	.ms
.sm:	LEA	32(A0),A0		; the same: not written
	LEA	32(A1),A1
	ADDQ.L	#4,A3
	ADDQ.L	#4,A2
	CMP.L	A4,A0
	BNE.S	.grp
	BRA	.next
.wr:	TST.L	AgcShad
	BEQ.S	.cv
	MOVEM.L	(A0),D0-D7
.cp:	MOVEM.L	D0-D7,(A1)		; the shadow follows the buffer
.cv:	LEA	32(A1),A1
	IFNE	AutoExit
	ADDQ.L	#1,AgcGrpW
	ENDC
	INCLUDE	"AgcC2P.i"
	MOVE.L	A5,-2*AGCPS(A3)		; P0=A5 P1=D5 P2=D3 P3=D1 P4=D6 P5=D4 P6=D2 P7=D0
	MOVE.L	D5,-AGCPS(A3)
	MOVE.L	D3,(A3)
	MOVE.L	D1,AGCPS(A3)
	MOVE.L	D6,-2*AGCPS(A2)
	MOVE.L	D4,-AGCPS(A2)
	MOVE.L	D2,(A2)
	MOVE.L	D0,AGCPS(A2)
	CMP.L	AgcMirE,A3		; the ring's first AGCRW bytes: again in the slack after its end
	BCC	.nm
	ADD.L	AgcPsz,A3
	ADD.L	AgcPsz,A2
	MOVE.L	A5,-2*AGCPS(A3)
	MOVE.L	D5,-AGCPS(A3)
	MOVE.L	D3,(A3)
	MOVE.L	D1,AGCPS(A3)
	MOVE.L	D6,-2*AGCPS(A2)
	MOVE.L	D4,-AGCPS(A2)
	MOVE.L	D2,(A2)
	MOVE.L	D0,AGCPS(A2)
	SUB.L	AgcPsz,A3
	SUB.L	AgcPsz,A2
	TST.L	AgcShad
	BEQ.S	.nm0
	MOVEM.L	-32(A1),D0-D7		; and in its shadow
	ADD.L	AgcPsz8,A1
	MOVEM.L	D0-D7,-32(A1)
	SUB.L	AgcPsz8,A1
.nm0:
	IFNE	AutoExit
	ADDQ.L	#1,AgcMirN
	ENDC
.nm:	ADDQ.L	#4,A3
	ADDQ.L	#4,A2
	CMP.L	A4,A0
	BNE	.grp
.next:	ADD.L	#AGCW,AgcLC
	ADDQ.L	#1,A6
	MOVE.L	AgcAY,D0		; the next line's ring byte
	ADD.L	#AGCRW,D0
	CMP.L	AgcPsz,D0
	BCS.S	.n1
	SUB.L	AgcPsz,D0
.n1:	MOVE.L	D0,AgcAY
	ADDQ.W	#1,AgcLn
	CMP.W	#AGCH,AgcLn
	BNE	.line
.end:	BSR	AgcSnap
	ST	AgcPend
	RTS
.ms:	ADD.L	AgcPsz8,A1		; the group equal: its slack copy too (a new split leaves old pictures there)
	CMP.L	(A1),D0
	BNE.S	.ms1
	CMP.L	4(A1),D1
	BNE.S	.ms1
	CMP.L	8(A1),D2
	BNE.S	.ms1
	CMP.L	12(A1),D3
	BNE.S	.ms1
	CMP.L	16(A1),D4
	BNE.S	.ms1
	CMP.L	20(A1),D5
	BNE.S	.ms1
	CMP.L	24(A1),D6
	BNE.S	.ms1
	CMP.L	28(A1),D7
	BNE.S	.ms1
	SUB.L	AgcPsz8,A1
	BRA	.sm
.ms1:	SUB.L	AgcPsz8,A1
	BRA	.cp

; AgcSeg: AgcC2P at the first line of ring D0.W (0, or 1 at AgcYb): the ring's bytes, its place in plane memory
; (ring 0 first, ring 1 after ring 0's slack), its line's ring byte (O, from T), shadow, AgcAll and the groups to
; convert (the fine scroll is the ring's own).
AgcSeg:
	MOVEM.L	D0-D5,-(SP)
	MOVEQ	#0,D2			; the ring's first byte in a plane
	MOVE.W	AgcYb,D3		; its lines
	TST.W	D0
	BEQ.S	.s0
	MOVE.W	D3,D2
	MULU.W	#AGCRW,D2
	ADD.L	#AGCRW,D2
	NEG.W	D3
	ADD.W	#AGCH,D3
.s0:	MULU.W	#AGCRW,D3
	MOVE.L	D3,AgcPsz
	LSL.L	#3,D3
	MOVE.L	D3,AgcPsz8
	MOVE.B	(AgcAllS.L,D0.W),AgcAll
	MOVE.L	(AgcTs.L,D0.W*4),D3	; T (the buffer's, just set)
	MOVE.L	D3,D4
	NEG.L	D4
	MOVEQ	#31,D5
	AND.L	D5,D4			; f
	ADD.L	D4,D3
	LSR.L	#3,D3
	CMP.L	AgcPsz,D3
	BCS.S	.s1
	SUB.L	AgcPsz,D3
.s1:	MOVE.L	D3,AgcAY		; the ring's first line's ring byte
	MOVE.L	AgcPB,D3
	ADD.L	D2,D3
	MOVE.L	D3,AgcP2B		; plane 2's ring,
	ADD.L	AgcPsz,D3
	MOVE.L	D3,AgcP2E		; ... its end,
	SUB.L	AgcPsz,D3
	ADD.L	#AGCRW,D3
	MOVE.L	D3,AgcMirE		; ... and its first AGCRW bytes' end
	LSL.L	#3,D2
	ADD.L	AgcSB0,D2
	MOVE.L	D2,AgcSB		; the shadow
	MOVEQ	#0,D1			; the groups to convert: all 12 ...
	MOVEQ	#AGCFW/32,D2
	TST.B	AgcWNow
	BNE.S	.w
	TST.B	AgcAll			; (moved: the margins too)
	BNE.S	.w
	MOVE.W	RtgW,D5
	BEQ.S	.w			; (no picture yet)
	MOVE.W	RtgOX,D1		; ... or the picture's: fetched pixels RtgOX+AGCQ-f, RtgW of them, to 32 px
	ADD.W	#AGCQ,D1
	SUB.W	D4,D1
	MOVE.W	D1,D2
	ADD.W	D5,D2
	LSR.W	#5,D1
	ADD.W	#31,D2
	LSR.W	#5,D2
	CMP.W	#AGCFW/32,D2
	BLS.S	.w
	MOVEQ	#AGCFW/32,D2
.w:	MOVE.W	D1,D3
	LSL.W	#2,D3
	MOVE.W	D3,AgcGOff		; ring bytes to the first group
	LSL.W	#3,D3
	ADD.W	D4,D3
	MOVE.W	D3,AgcCOff		; chunky bytes to it: f + 32 g
	SUB.W	D1,D2
	LSL.W	#5,D2
	MOVE.W	D2,AgcCLen
	MOVEM.L	(SP)+,D0-D5
	RTS

; AgcScrKey: RtgFrame (every composed frame), A0 = this frame's scroll list (line, BXR, BYR; 6 bytes an entry).
; The split (AgcYb): the region covering the most lines is the main one; when it is not the first, ring 1 starts
; at its first picture line, otherwise at the line after it (when another region follows within the display),
; so a band that scrolls on its own (a fixed status bar above or below) has a ring of its own. Each ring's key
; is that of its longest region: the map row of picture line 0 (BYR - line, +1 below the top, as RtgFrame
; draws) and BXR. The ring's T moves with it: down a map row = a ring line on (AGCFW px), right a pixel = a ring
; pixel on; each wrapped within the map's size, so -h/2 .. h/2; T modulo the ring. A new split puts both rings at
; T 0. AgcNoShift: one ring, T stays 0; AgcNoHx: rows only; AgcNoSeg: one ring.
AgcScrKey:
	MOVEM.L	D0-D7/A0-A1,-(SP)
	MOVE.L	A0,A1
	MOVE.W	RtgVdw,D4
	MOVEQ	#0,D5			; the longest region's lines,
	MOVEQ	#0,D6			; ... its first VDC line,
	MOVEQ	#0,D7			; ... and the line after it
.e:	MOVE.W	(A0),D0
	BMI.S	.ex
	CMP.W	D4,D0
	BGE.S	.ex
	MOVE.W	6(A0),D1		; the next entry's line, or the display's end
	BMI.S	.e1
	CMP.W	D4,D1
	BLE.S	.e2
.e1:	MOVE.W	D4,D1
.e2:	MOVE.W	D1,D2
	SUB.W	D0,D1
	CMP.W	D5,D1
	BLE.S	.e3
	MOVE.W	D1,D5
	MOVE.W	D0,D6
	MOVE.W	D2,D7
.e3:	TST.W	6(A0)
	BMI.S	.ex
	ADDQ.L	#6,A0
	BRA.S	.e
.ex:	MOVE.W	#AGCH,D3		; the split: ring 1 from picture line D3 (AGCH: one ring)
	IFEQ	AgcNoSeg|AgcNoShift
	TST.W	D5
	BEQ.S	.ys
	MOVE.W	D6,D0			; the main region below another: ring 1 from its start,
	BNE.S	.y1
	MOVE.W	D7,D0			; ... else from its end, when a region follows
	CMP.W	D4,D0
	BGE.S	.ys
.y1:	ADD.W	RtgVoff,D0
	BLE.S	.ys
	CMP.W	#AGCH,D0
	BGE.S	.ys
	MOVE.W	D0,D3
	ENDC
.ys:	MOVE.W	D3,AgcYb
	CLR.W	AgcKOk			; each ring's key: its longest region's
	CLR.L	AgcKN
	MOVE.L	A1,A0
	LEA	AgcKN,A1
.f:	MOVE.W	(A0),D0
	BMI.S	.fx
	CMP.W	D4,D0
	BGE.S	.fx
	MOVE.W	6(A0),D1
	BMI.S	.f1
	CMP.W	D4,D1
	BLE.S	.f2
.f1:	MOVE.W	D4,D1
.f2:	SUB.W	D0,D1			; the region's lines
	MOVEQ	#0,D7			; its ring: 1 from the split
	MOVE.W	D0,D2
	ADD.W	RtgVoff,D2
	CMP.W	D3,D2
	BLT.S	.f3
	MOVEQ	#1,D7
.f3:	CMP.W	(A1,D7.W*2),D1
	BLE.S	.f4
	MOVE.W	D1,(A1,D7.W*2)
	MOVE.W	4(A0),D2
	SUB.W	D0,D2
	TST.W	D0
	BEQ.S	.f5
	ADDQ.W	#1,D2
.f5:	MOVE.W	D2,(AgcKY.L,D7.W*2)
	MOVE.W	2(A0),(AgcKX.L,D7.W*2)
	ST	(AgcKOk.L,D7.W)
.f4:	TST.W	6(A0)
	BMI.S	.fx
	ADDQ.L	#6,A0
	BRA.S	.f
.fx:
	IFEQ	AgcNoShift
	CMP.W	AgcPYb,D3
	BEQ.S	.t0
	CLR.L	AgcTs			; a new split: both rings from 0
	CLR.L	AgcTs+4
	BRA	.tx
.t0:	MOVEQ	#0,D7
.ts:	MOVE.W	D3,D2			; the ring's pixels: AGCFW x its lines
	TST.W	D7
	BEQ.S	.t1
	NEG.W	D2
	ADD.W	#AGCH,D2
.t1:	TST.W	D2
	BEQ	.tn			; (no ring 1)
	MULU.W	#AGCFW,D2
	TST.B	(AgcKOk.L,D7.W)
	BEQ	.tn
	TST.B	(AgcPKOk.L,D7.W)
	BEQ	.tn
	MOVE.W	(AgcKY.L,D7.W*2),D0	; map rows moved since the last frame
	SUB.W	(AgcPKY.L,D7.W*2),D0
	MOVE.W	RtgBatYM,D1
	AND.W	D1,D0
	LSR.W	#1,D1
	CMP.W	D1,D0
	BLS.S	.d1
	SUB.W	RtgBatYM,D0
	SUBQ.W	#1,D0
.d1:	MULS.W	#AGCFW,D0
	IFEQ	AgcNoHx
	MOVE.W	(AgcKX.L,D7.W*2),D1	; map pixels moved
	SUB.W	(AgcPKX.L,D7.W*2),D1
	MOVE.W	RtgBatXM,D5
	AND.W	D5,D1
	LSR.W	#1,D5
	CMP.W	D5,D1
	BLS.S	.d2
	SUB.W	RtgBatXM,D1
	SUBQ.W	#1,D1
.d2:	EXT.L	D1
	ADD.L	D1,D0
	ENDC
	ADD.L	(AgcTs.L,D7.W*4),D0
	DIVSL.L	D2,D1:D0		; D1 = D0 mod the ring (the sign of D0)
	TST.L	D1
	BPL.S	.d3
	ADD.L	D2,D1
.d3:	MOVE.L	D1,(AgcTs.L,D7.W*4)
.tn:	ADDQ.W	#1,D7
	CMP.W	#2,D7
	BNE	.ts
.tx:
	ENDC
	MOVE.W	D3,AgcPYb
	MOVE.W	AgcKOk,AgcPKOk
	MOVE.L	AgcKY,AgcPKY
	MOVE.L	AgcKX,AgcPKX
	MOVEM.L	(SP)+,D0-D7/A0-A1
	RTS

; AgcFlip: the vertical blank interrupt (Main.asm), so the buffer AgcC2P drew is shown from the start of a
; frame, with its colours (AgcSnap). Done from the main loop, a late frame flipped mid-frame: plane pointers,
; the ring's wrap block and the buffer then drawn did not match what the beam was showing (garbage on the
; PiStorm when frames ran late). Here the buffer AgcC2P draws next is never on screen.
	CNOP	0,4
AgcFlip:
	TST.B	AgcPend
	BEQ.S	.x
	MOVEM.L	D0-D3/A0-A3,-(SP)
	TST.B	AgcPendAny
	BEQ.S	.p
	SF	AgcPendAny
	LEA	AgcPendF,A0
	LEA	AgcPendRGB,A2
	LEA	COLOR+2,A3		; bank k at k x 132 (32 moves + a BPLCON3 move)
	MOVEQ	#0,D0
.c:	TST.B	(A0,D0.W)
	BEQ.S	.cn
	SF	(A0,D0.W)
	MOVE.W	(A2,D0.W*2),D1
	MOVE.W	D0,D2
	LSR.W	#5,D2
	MULU.W	#132,D2
	MOVE.W	D0,D3
	AND.W	#31,D3
	LSL.W	#2,D3
	ADD.W	D3,D2
	MOVE.W	D1,(A3,D2.W)
.cn:	ADDQ.W	#1,D0
	CMP.W	#256,D0
	BNE.S	.c
.p:	BSR	AgcPlanePtrs
	EOR.W	#1,AgcBack
	SF	AgcPend
	MOVEM.L	(SP)+,D0-D3/A0-A3
.x:	RTS

; AgcSnap: the end of a conversion, before AgcPend. The colours of the registers that changed for this picture
; go to AgcPendRGB for the flip (AgcFlip may come in the middle of the next frame's composing, which changes
; registers again).
AgcSnap:
	TST.B	AgcColNew
	BEQ.S	.x
	SF	AgcColNew
	LEA	AgcRegNew,A0
	LEA	AgcRegCol,A1
	LEA	AgcRGB,A2
	LEA	AgcPendF,A3
	LEA	AgcPendRGB,A4
	MOVEQ	#0,D0
.c:	TST.B	(A0,D0.W)
	BEQ.S	.cn
	SF	(A0,D0.W)
	MOVE.W	(A1,D0.W*2),D1
	BPL.S	.c1
	MOVEQ	#0,D1
.c1:	MOVE.W	(A2,D1.W*2),(A4,D0.W*2)
	ST	(A3,D0.W)
.cn:	ADDQ.W	#1,D0
	CMP.W	#256,D0
	BNE.S	.c
	ST	AgcPendAny
.x:	RTS

; AgcPlanePtrs: the copper's plane pointers to buffer AgcBack, ring 0 at its byte O, and BPLCON1 = ring 0's f,
; from the buffer's split and Ts (AgcYbB, AgcTB). The planes lie one after the other, ring 1 after ring 0's
; slack, so where the next line does not follow on in plane memory (a ring's end, reached by the line that
; straddles it or ends on it; the split) the modulo on that line jumps there, and on the next line it is put
; back. (Pointer moves, 16 of them, do not fit in the gap between a line's fetch and the next's.) Ring 1's
; BPLCON1 goes in at its first line. The block at the start of CopperScrolls (AGCWRAP bytes, no-ops after the
; moves) passes line 255 once, for what follows.
AgcPlanePtrs:
	MOVEM.L	D0-D7/A0-A1,-(SP)
	MOVE.W	AgcBack,D7
	MOVE.W	(AgcYbB.L,D7.W*2),D6	; the split
	MOVE.W	D6,AgcQYb
	LEA	AgcTB,A1
	LEA	(A1,D7.W*8),A1
	MOVE.W	D6,D2			; ring 0: its bytes, O and f
	MULU.W	#AGCRW,D2
	MOVE.L	D2,AgcQP
	MOVE.L	(A1),D0
	BSR	.fo
	MOVE.L	D0,AgcQO
	BSR	.con
	MOVE.W	D1,ScrBits+2		; BPLCON1 from the frame's start
	MOVE.W	#AGCH,D2		; ring 1
	SUB.W	D6,D2
	MULU.W	#AGCRW,D2
	MOVE.L	D2,AgcQP+4
	MOVE.L	4(A1),D0
	BSR	.fo
	MOVE.L	D0,AgcQO+4
	BSR	.con
	MOVE.W	D1,AgcQC1
	MOVE.W	D6,D0
	MULU.W	#AGCRW,D0
	ADD.L	#AGCRW,D0
	MOVE.L	D0,AgcQB		; ring 1's first byte: after ring 0 and its slack
	MOVE.L	#PantGfx+8,D0
	TST.W	D7
	BEQ.S	.b0
	ADD.L	#AGCBUF,D0
.b0:	ADD.L	AgcQO,D0
	LEA	PLANO+2,A0
	MOVEQ	#8-1,D1
.l:	SWAP	D0
	MOVE.W	D0,(A0)
	SWAP	D0
	MOVE.W	D0,4(A0)
	ADDQ.L	#8,A0
	ADD.L	#AGCPS,D0
	DBF	D1,.l
	LEA	AgcEv,A1		; the jumps (line, modulo), in line order
	MOVE.L	AgcQO,D1		; ring 0's end
	BEQ.S	.e1
	MOVE.L	AgcQP,D0
	ADD.L	#AGCRW-1,D0
	SUB.L	D1,D0
	DIVU.W	#AGCRW,D0		; the first line starting past it
	CMP.W	D6,D0
	BCC.S	.e1			; (at the split: the split's own jump)
	SUBQ.W	#1,D0
	BSR	.ev
.e1:	CMP.W	#AGCH,D6		; the split
	BCC.S	.e2
	MOVE.W	D6,D0
	SUBQ.W	#1,D0
	BSR	.ev
	MOVE.L	AgcQO+4,D1		; ring 1's end
	BEQ.S	.e2
	MOVE.L	AgcQP+4,D0
	ADD.L	#AGCRW-1,D0
	SUB.L	D1,D0
	DIVU.W	#AGCRW,D0
	MOVE.W	#AGCH,D1
	SUB.W	D6,D1
	CMP.W	D1,D0
	BCC.S	.e2
	ADD.W	D6,D0
	SUBQ.W	#1,D0
	BSR	.ev
.e2:	MOVE.W	#-1,(A1)
	LEA	CopperScrolls,A0	; the copper: each jump's modulo, 0 again on the next line
	LEA	AgcEv,A1
	MOVEQ	#0,D5			; past line 255 yet
	MOVE.W	PicTop,D4
	ADDQ.W	#1,D4			; the beam line of picture line 0 (the window starts at PicTop+1)
.c:	MOVE.W	(A1)+,D0
	BMI.S	.cx
	MOVE.W	(A1)+,D1
	BSR	.rec
	ADDQ.W	#1,D0
	CMP.W	(A1),D0
	BEQ.S	.c			; (the next jump on the next line)
	MOVEQ	#0,D1
	BSR	.rec
	BRA.S	.c
.cx:	TST.B	D5
	BNE.S	.cp
	MOVE.L	#$FFDFFFFE,(A0)+	; past line 255 for what follows (the debug panel)
.cp:	LEA	CopperScrolls+AGCWRAP,A1
.pd:	CMP.L	A1,A0
	BCC.S	.x
	MOVE.L	#$01FE0000,(A0)+	; (no-ops)
	BRA.S	.pd
.x:	MOVEM.L	(SP)+,D0-D7/A0-A1
	RTS
.fo:	MOVE.L	D0,D1			; T, the ring's bytes D2 -> O (D0), f (D1)
	NEG.L	D1
	AND.L	#31,D1
	ADD.L	D1,D0
	LSR.L	#3,D0
	CMP.L	D2,D0
	BCS.S	.fo1
	SUB.L	D2,D0
.fo1:	RTS
.con:	MOVE.W	D1,D3			; f -> BPLCON1: f px on both playfields (PFxH2-5 in bits 0-3 and 4-7,
	AND.W	#15,D1			; PFxH6 in 10 and 14)
	MULU.W	#$11,D1
	BTST	#4,D3
	BEQ.S	.cn
	OR.W	#$4400,D1
.cn:	RTS
.ad:	AND.L	#$FFFF,D0		; picture line D0 -> its first byte in a plane
	CMP.W	AgcQYb,D0
	BCC.S	.a1
	MULU.W	#AGCRW,D0
	ADD.L	AgcQO,D0
	CMP.L	AgcQP,D0
	BCS.S	.a0
	SUB.L	AgcQP,D0
.a0:	RTS
.a1:	SUB.W	AgcQYb,D0
	MULU.W	#AGCRW,D0
	ADD.L	AgcQO+4,D0
	CMP.L	AgcQP+4,D0
	BCS.S	.a2
	SUB.L	AgcQP+4,D0
.a2:	ADD.L	AgcQB,D0
	RTS
.ev:	CMP.W	#AGCVIS-1,D0		; line D0: its jump to (A1)+, if its next line is shown and does not follow on
	BCC.S	.v1
	MOVEM.L	D0-D3,-(SP)
	MOVE.W	D0,D2
	ADDQ.W	#1,D0
	BSR.S	.ad
	MOVE.L	D0,D3
	MOVE.W	D2,D0
	BSR.S	.ad
	SUB.L	D0,D3
	SUB.L	#AGCRW,D3
	BEQ.S	.v0
	MOVE.W	D2,(A1)+
	MOVE.W	D3,(A1)+
.v0:	MOVEM.L	(SP)+,D0-D3
.v1:	RTS
.rec:	MOVE.W	D0,D2			; line D0: modulo D1 (and ring 1's BPLCON1 at the split)
	ADD.W	D4,D2
	CMP.W	#$100,D2
	BCS.S	.r1
	TST.B	D5
	BNE.S	.r1
	ST	D5
	MOVE.L	#$FFDFFFFE,(A0)+
.r1:	MOVE.B	D2,(A0)+		; wait for the line, H 7 (before its fetch)
	MOVE.B	#$07,(A0)+
	MOVE.W	#$FFFE,(A0)+
	MOVE.W	#$0108,(A0)+
	MOVE.W	D1,(A0)+
	MOVE.W	#$010A,(A0)+
	MOVE.W	D1,(A0)+
	CMP.W	D6,D0
	BNE.S	.r2
	MOVE.W	#$0102,(A0)+
	MOVE.W	AgcQC1,(A0)+
.r2:	RTS

	IFNE	AutoExit
; AgcDumpWrite: AutoExit test builds (back from play, OS alive), for tools/agccheck.py: PROGDIR:AmiPCE.agc = header (AGC1, RtgW, RtgOX,
; buffer, pending, overflow count, AGCW), the chunky buffer, the planes of the last buffer drawn, AgcRegCol, VDP_Pal
; and RtgOld (each line's VCE entries, AGCW words), then the copper's COLOR block and AgcRegNew, the other plane
; buffer, PLANO, the copper lists from MasterCopper_AGA to a long past the rings' block, AgcStale, 64 flag bytes
; (AgcLate, AgcSkipped, shadows there, 3 = a ring per band; longs: buffer 0's T of rings 0 and 1, buffer 1's,
; groups written, pictures drawn, groups compared, ring moves, groups mirrored, T of rings 0 and 1, plane buffer
; 0's address; words: the splits of buffers 0 and 1, this frame's split, 0; long: new splits) and the two shadows
; when there. Planes one after the other (AGCPS each: ring 0, its AGCRW-byte slack, ring 1, its slack), shadows
; by plane pixel.
AgcDumpWrite:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	TST.B	AgcWant			; (play has closed by now: AgcOn is off, the buffers are as they were)
	BEQ	.x
	MOVE.W	RtgW,AgcDHdr+4
	MOVE.W	RtgOX,AgcDHdr+6
	MOVE.W	AgcBack,D0
	TST.B	AgcPend
	BNE.S	.d1
	EOR.W	#1,D0			; flipped: the shown buffer is the last drawn
.d1:	MOVE.W	D0,AgcDHdr+8
	MOVE.B	AgcPend,AgcDHdr+11
	MOVE.W	AgcOvAll,AgcDHdr+12
	MOVE.W	#AGCW,AgcDHdr+14
	MOVE.B	#3,AgcDHdr+10		; layout 3: a ring per scroll band
	MOVE.L	#PantGfx+8,A5
	TST.W	D0
	BEQ.S	.d2
	ADD.L	#AGCBUF,A5
.d2:	MOVE.L	$4.W,A6
	LEA	AutoDosName,A1
	MOVEQ	#0,D0
	JSR	-$228(A6)		; OpenLibrary
	TST.L	D0
	BEQ	.x
	MOVE.L	D0,A6
	MOVE.L	#AgcDName,D1
	MOVE.L	#1006,D2
	JSR	-30(A6)			; Open
	MOVE.L	D0,D4
	BEQ	.cl
	MOVE.L	#AgcDHdr,D2
	MOVEQ	#16,D3
	BSR	.w
	MOVE.L	RtgCompP,D2
	MOVE.L	#AGCW*AGCH,D3
	BSR	.w
	MOVE.L	A5,D2
	MOVE.L	#AGCBUF,D3
	BSR	.w
	MOVE.L	#AgcRegCol,D2
	MOVE.L	#512,D3
	BSR	.w
	MOVE.L	#VDP_Pal,D2
	MOVE.L	#1024,D3
	BSR	.w
	MOVE.L	RtgOldP,D5
	MOVE.W	#AGCH-1,D6
.o:	MOVE.L	D5,D2
	MOVE.L	#AGCW*2,D3
	BSR	.w
	ADD.L	#RTGMW*2,D5
	DBF	D6,.o
	MOVE.L	#COLOR,D2		; the copper's colour block (8 banks of 33 moves) and AgcRegNew
	MOVE.L	#8*132,D3
	BSR	.w
	LEA	AgcPendF,A0		; (colours not yet in the copper: waiting for the flip or for the next
	LEA	AgcRegNew,A1		; picture's snapshot; play is over, so merged here)
	MOVEQ	#256/4-1,D0
.rn:	MOVE.L	(A1)+,D1
	OR.L	D1,(A0)+
	DBF	D0,.rn
	MOVE.L	#AgcPendF,D2
	MOVE.L	#256,D3
	BSR	.w
	MOVE.L	#PantGfx+8,D2		; the other plane buffer (the one shown before the pending flip)
	CMP.L	A5,D2
	BNE.S	.d3
	ADD.L	#AGCBUF,D2
.d3:	MOVE.L	#AGCBUF,D3
	BSR	.w
	MOVE.L	#PLANO,D2		; the copper's plane pointers
	MOVEQ	#64,D3
	BSR	.w
	MOVE.L	#MasterCopper_AGA,D2	; the copper lists as they stand (to the rings' block and a long after it)
	MOVE.L	#CopperScrolls+AGCWRAP+4-MasterCopper_AGA,D3
	BSR	.w
	MOVE.L	#AgcStale,D2		; tail: AgcStale, the flag bytes, the shadows
	MOVE.L	#AGCH,D3
	BSR	.w
	MOVE.B	AgcLate,AgcDFlg
	MOVE.B	AgcSkipped,AgcDFlg+1
	TST.L	AgcShad
	SNE	AgcDFlg+2
	MOVE.B	#3,AgcDFlg+3		; a ring per scroll band
	MOVE.L	AgcTB,AgcDFlg+4
	MOVE.L	AgcTB+4,AgcDFlg+8
	MOVE.L	AgcTB+8,AgcDFlg+12
	MOVE.L	AgcTB+12,AgcDFlg+16
	MOVE.L	AgcGrpW,AgcDFlg+20
	MOVE.L	AgcPicN,AgcDFlg+24
	MOVE.L	AgcGrpC,AgcDFlg+28
	MOVE.L	AgcShN,AgcDFlg+32
	MOVE.L	AgcMirN,AgcDFlg+36
	MOVE.L	AgcTs,AgcDFlg+40
	MOVE.L	AgcTs+4,AgcDFlg+44
	MOVE.L	#PantGfx+8,AgcDFlg+48	; (plane buffer 0's address: the copper's pointers against it)
	MOVE.L	AgcYbB,AgcDFlg+52	; (both buffers' splits)
	MOVE.W	AgcYb,AgcDFlg+56
	CLR.W	AgcDFlg+58
	MOVE.L	AgcLayN,AgcDFlg+60
	MOVE.L	#AgcDFlg,D2
	MOVEQ	#64,D3
	BSR	.w
	MOVE.L	AgcShad,D2
	BEQ.S	.d4
	MOVE.L	#AGCSHSZ,D3
	BSR	.w
.d4:	MOVE.L	D4,D1
	JSR	-36(A6)			; Close
.cl:	MOVE.L	A6,A1
	MOVE.L	$4.W,A6
	JSR	-$19E(A6)		; CloseLibrary
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
.w:	MOVE.L	D4,D1
	JMP	-48(A6)			; Write

AgcDName:	DC.B	"PROGDIR:AmiPCE.agc",0
	EVEN
AgcDHdr:	DC.B	"AGC1"
		DS.W	6
	ENDC

; the variables: AGCvars.asm (own sections, after RTG.asm)
