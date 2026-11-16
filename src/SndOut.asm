; SndOut.asm: stereo output on Paula for a frozen emulator, one block a frame.
;
; Source: the ring of FMX in AmiMSX 4.x (AmiMSX_FM_v4.asm: FMXInit, FMXSetN,
; FMXAud, FMXFrame; credit z00p and Juan's AmiMSX). Here it is stereo, 14-bit,
; and knows nothing about the emulator: it takes mixed samples once a frame and
; plays them.
;
; What goes in: signed 16-bit stereo, big-endian, interleaved (L, R, L, R).
; What comes out: a ring of SND_BLOCKS blocks, one block a frame. A block is
; handed to Paula by the interrupt of the last voice when the one before it
; starts. A block not written in time: the one playing repeats (SndUnder). Ring
; full: the new block is dropped (SndOver). SndFrame asks for 2 samples more or
; fewer than a frame's worth when the ring holds fewer or more blocks than
; SC_HAND, so frame rate and Paula clock agree on average. Pitch is the mixer's
; step per sample and does not change.
;
; Voices, 14 bit (NO_SND14=0): 0 left high byte, 1 right high byte, both at volume
; 64; 3 left low 6 bits, 2 right low 6 bits, both at volume 1. High byte x 64 +
; low bits x 1 = sample / 4. NO_SND14=1: voices 0 and 1 only, high byte only.
;
; Calls. D0-D1/A0-A1 scratch, the rest kept. No OS calls, no Disable. One writer
; per ring index: the main loop moves SndWrite, the interrupt SndPlay and SndQueued.
;
;   SndOpen   A0 = SndCfg -> D0.l = rate in Hz. Nothing on the hardware yet.
;   SndStart  Measures the frame (up to 2 frames), silences the ring, starts the
;             voices. Install the level 4 vector first (below). Assumes the
;             interrupt master bit and DMAEN are on.
;   SndStop   Interrupt off first, then DMA, then volumes (with an enabled audio
;             interrupt and the DMA off, Paula interrupts every sample period).
;   SndFrame  Once a frame -> D0.w = samples wanted, even.
;   SndPut    A0 = samples, D0.w = count, even. Main loop only. May read up to 3
;             samples past the end (a block is written in longs).
;   SndIrq    The audio interrupt's body. Keeps all registers, clears the request.
;   SndStats  A0 = SST_SIZE bytes, out.
;
; Frozen install:   SndHandler: JSR SndIrq / NOP / RTE, at $70(VBR), old vector
;                   saved and put back by the emulator.
; OS alive install: audio.device channels first, SetIntVector(INTB_AUDx) with the
;                   same call. Not tried.
;
; The caller owns the buffer: chip RAM, long aligned, word even, SND_BLOCKS *
; SND_VOICES * SC_BLOCK bytes. SC_BLOCK = largest count + 4.
; Assumes the PAL Paula clock (3546895 Hz), as the emulators do.
; Labels: Snd* and SND_*, SC_*, SST_*. Assemble with -devpac -nocase -m68020.

SND_API		= 1
SND_BLOCKS	= 6		; playing, queued, waiting, and the one being written
	IFEQ	NO_SND14
SND_VOICES	= 4
SND_DMA		= $000F
SND_INT		= $0400		; AUD3, the last voice to fetch in a line
	ELSE
SND_VOICES	= 2
SND_DMA		= $0003
SND_INT		= $0100		; AUD1
	ENDC

SC_RING		= 0		; .l chip buffer
SC_BLOCK	= 4		; .w bytes a voice a block
SC_PERIOD	= 6		; .w Paula period, 124 or more
SC_HAND		= 8		; .w blocks waiting to aim for when a frame is ready
SC_SIZE		= 10

SST_UNDER	= 0		; .l blocks repeated
SST_OVER	= 4		; .l blocks dropped
SST_NOMINAL	= 8		; .w samples a frame
SST_LINES	= 10		; .w lines a frame, as measured
SST_IRQS	= 12		; .l interrupts (SndStat builds, the rest too)
SST_JMIN	= 16		; .l shortest gap between interrupts against the blocks' length, colour clocks
SST_JMAX	= 20		; .l longest
SST_LINE	= 24		; .l beam line at the last interrupt
SST_FILL	= 28		; .l x SND_BLOCKS: frames by blocks waiting at SndFrame
SST_SIZE	= 28+4*SND_BLOCKS

	SECTION	SndCode,CODE

	CNOP	0,4
SndOpen:
	MOVEM.L	D2/A2,-(SP)
	MOVE.L	SC_RING(A0),A1
	MOVE.W	SC_BLOCK(A0),D0
	MOVE.W	D0,SndBlock
	MOVE.W	SC_PERIOD(A0),D2
	MOVE.W	D2,SndPer
	MOVE.W	SC_HAND(A0),SndHand
	MULU.W	#SND_VOICES,D0
	LEA	SndBlk,A2
	MOVEQ	#SND_BLOCKS-1,D1
.b:	MOVE.L	A1,(A2)+
	ADD.L	D0,A1
	DBF	D1,.b
	MOVE.L	#3546895,D0
	DIVU.W	D2,D0
	AND.L	#$FFFF,D0
	MOVE.L	D0,SndRate
	MOVEM.L	(SP)+,D2/A2
	RTS

; Beam line now.
SndBeam:
	MOVE.L	$DFF004,D0
	LSR.L	#8,D0
	AND.W	#$1FF,D0
	RTS

; D0 = lines a frame, 263 or 313, from the highest line seen between two wraps
; of the beam (FMXSetN; at WinUAE's JIT speed the top lines can be missed). Uses D1-D2.
SndMeasure:
	BSR.S	SndBeam
.w:	MOVE.W	D0,D1
	BSR.S	SndBeam
	CMP.W	D1,D0
	BCC.S	.w
	MOVEQ	#0,D2
.t:	CMP.W	D2,D0
	BLS.S	.n
	MOVE.W	D0,D2
.n:	MOVE.W	D0,D1
	BSR.S	SndBeam
	CMP.W	D1,D0
	BCC.S	.t
	MOVE.W	#263,D0
	CMP.W	#287,D2
	BLS.S	.x
	MOVE.W	#313,D0
.x:	RTS

	CNOP	0,4
SndStart:
	MOVEM.L	D2/A2,-(SP)
	LEA	$DFF000,A1
	MOVE.W	#SND_INT,$9A(A1)
	MOVE.W	#SND_DMA,$96(A1)
	MOVE.W	#SND_INT,$9C(A1)
	BSR.S	SndMeasure		; (also long enough for the voices to go idle with the DMA off)
	MOVE.W	D0,SndLines
	IFEQ	NO_NTSCRATE
	TST.B	BeamExact
	BEQ.S	.std
	MOVE.W	BeamLines,D1		; BeamSet's programmed frame: BeamCC colour clocks a line
	MOVE.W	D1,SndLines
	MULU.W	#BeamCC,D1
	BRA.S	.pal
.std:
	ENDC
	MOVE.L	#71051,D1		; colour clocks a frame: 313 x 227
	CMP.W	#287,D0
	BHI.S	.pal
	MULU.W	#455,D0			; or lines x 227.5
	LSR.L	#1,D0
	MOVE.L	D0,D1
.pal:	MOVE.L	D1,SndFrameCC
	MOVEQ	#0,D0			; samples a frame, even, nearest
	MOVE.W	SndPer,D0
	ADD.L	D0,D1
	ADD.W	D0,D0
	DIVU.W	D0,D1
	ADD.W	D1,D1
	MOVE.W	D1,SndNom
	MOVE.L	SndBlk,A0		; silence
	MOVE.W	SndBlock,D0
	MULU.W	#SND_VOICES*SND_BLOCKS/4,D0
	SUBQ.L	#1,D0
.c:	CLR.L	(A0)+
	DBF	D0,.c
	CLR.W	SndPlay			; block 0 (silence) plays and repeats until
	CLR.W	SndQueued		; SC_HAND + 1 blocks are waiting
	MOVE.W	#1,SndWrite
	SF	SndPrimed
	CLR.L	SndUnder
	CLR.L	SndOver
	IFNE	SndStat
	CLR.L	SndStIrqs
	CLR.L	SndStPrev
	CLR.L	SndStMin
	CLR.L	SndStMax
	LEA	SndStFill,A0
	MOVEQ	#SND_BLOCKS-1,D0
.f:	CLR.L	(A0)+
	DBF	D0,.f
	ENDC
	MOVE.W	SndNom,D1
	LSR.W	#1,D1
	MOVE.W	D1,SndLen		; words
	LEA	$A0(A1),A2
	MOVE.L	SndBlk,A0
	MOVEQ	#0,D2
	MOVE.W	SndBlock,D2
	LEA	SndVols(PC),A1
	MOVEQ	#SND_VOICES-1,D0
.v:	MOVE.L	A0,(A2)
	MOVE.W	D1,4(A2)
	MOVE.W	SndPer,6(A2)
	MOVE.W	(A1)+,8(A2)
	ADD.L	D2,A0
	LEA	$10(A2),A2
	DBF	D0,.v
	LEA	$DFF000,A1
	MOVE.W	#SND_INT,$9C(A1)
	MOVE.W	#$8000|SND_DMA,$96(A1)	; Paula takes block 0 and asks for the next at once
	MOVE.W	#$8000|SND_INT,$9A(A1)
	MOVEM.L	(SP)+,D2/A2
	RTS
SndVols:
	IFEQ	NO_SND14
	DC.W	64,64,1,1
	ELSE
	DC.W	64,64
	ENDC

SndStop:
	LEA	$DFF000,A1
	MOVE.W	#SND_INT,$9A(A1)
	MOVE.W	#SND_INT,$9C(A1)
	MOVE.W	#SND_DMA,$96(A1)
	LEA	$A8(A1),A0
	MOVEQ	#SND_VOICES-1,D0
.v:	CLR.W	(A0)
	LEA	$10(A0),A0
	DBF	D0,.v
	MOVE.W	#SND_INT,$9C(A1)
	RTS

; Paula has just taken the block queued last time: queue the next. Keeps all.
	CNOP	0,4
SndIrq:
	MOVEM.L	D0-D1/A0-A1,-(SP)
	LEA	$DFF000,A1
	MOVE.W	$1E(A1),D0
	AND.W	#SND_INT,D0
	BEQ	.x
	MOVE.W	#SND_INT,$9C(A1)
	MOVE.W	#SND_INT,$9C(A1)
	IFNE	SndStat
	BSR	SndStIrq
	ENDC
	MOVE.W	SndQueued,D0
	MOVE.W	D0,SndPlay
	TST.B	SndPrimed
	BNE.S	.run
	MOVE.W	SndWrite,D1		; start: wait for the blocks in hand
	SUB.W	D0,D1
	SUBQ.W	#1,D1
	BPL.S	.pw
	ADDQ.W	#SND_BLOCKS,D1
.pw:	CMP.W	SndHand,D1
	BLS.S	.same
	ST	SndPrimed
.run:	ADDQ.W	#1,D0
	CMP.W	#SND_BLOCKS,D0
	BCS.S	.nw
	MOVEQ	#0,D0
.nw:	CMP.W	SndWrite,D0
	BNE.S	.take
	ADDQ.L	#1,SndUnder
.same:	MOVE.W	SndPlay,D0
.take:	MOVE.W	D0,SndQueued
	MOVE.W	(SndLen.L,D0.W*2),D1
	MOVE.L	(SndBlk.L,D0.W*4),A0
	MOVE.L	A0,$A0(A1)
	MOVE.W	D1,$A4(A1)
	MOVEQ	#0,D0
	MOVE.W	SndBlock,D0
	ADD.L	D0,A0
	MOVE.L	A0,$B0(A1)
	MOVE.W	D1,$B4(A1)
	IFEQ	NO_SND14
	ADD.L	D0,A0
	MOVE.L	A0,$C0(A1)
	MOVE.W	D1,$C4(A1)
	ADD.L	D0,A0
	MOVE.L	A0,$D0(A1)
	MOVE.W	D1,$D4(A1)
	ENDC
.x:	MOVEM.L	(SP)+,D0-D1/A0-A1
	RTS

	CNOP	0,4
SndFrame:
	MOVE.W	SndWrite,D1
	SUB.W	SndQueued,D1
	SUBQ.W	#1,D1
	BPL.S	.w
	ADDQ.W	#SND_BLOCKS,D1
.w:					; D1 = blocks waiting for Paula
	IFNE	SndStat
	ADDQ.L	#1,(SndStFill.L,D1.W*4)
	ENDC
	MOVE.W	SndNom,D0
	CMP.W	SndHand,D1
	BEQ.S	.x
	BHI.S	.less
	ADDQ.W	#2,D0
.x:	RTS
.less:	SUBQ.W	#2,D0
	RTS

; A0 = samples, D0.w = count: split into the next block.
	CNOP	0,8
SndPut:
	MOVE.W	SndWrite,D1
	CMP.W	SndPlay,D1
	BNE.S	.room
	ADDQ.L	#1,SndOver		; ring full: this frame's block is dropped
	RTS
.room:	MOVEM.L	D2-D7/A2-A5,-(SP)
	MOVE.W	D0,D2
	LSR.W	#1,D2
	MOVE.W	D2,(SndLen.L,D1.W*2)	; length first: the interrupt reads it once SndWrite moves
	MOVE.L	(SndBlk.L,D1.W*4),A2
	MOVEQ	#0,D2
	MOVE.W	SndBlock,D2
	LEA	(A2,D2.L),A3
	IFEQ	NO_SND14
	LEA	(A3,D2.L),A4
	LEA	(A4,D2.L),A5
	MOVE.L	#$3F3F3F3F,D6
	ENDC
	ADDQ.W	#3,D0			; in longs: Paula stops at the block's length
	LSR.W	#2,D0
	SUBQ.W	#1,D0
	MOVE.W	D0,D7
SndTake:	MACRO
	MOVE.L	(A0)+,D0		; LLll RRrr
	IFEQ	NO_SND14
	LSL.L	#8,D5
	MOVE.B	D0,D5
	ENDC
	LSR.W	#8,D0
	LSL.L	#8,D3
	MOVE.B	D0,D3
	SWAP	D0
	IFEQ	NO_SND14
	LSL.L	#8,D4
	MOVE.B	D0,D4
	ENDC
	LSR.W	#8,D0
	LSL.L	#8,D2
	MOVE.B	D0,D2
	ENDM
.l:	SndTake
	SndTake
	SndTake
	SndTake
	MOVE.L	D2,(A2)+		; voice 0, left high
	MOVE.L	D3,(A3)+		; voice 1, right high
	IFEQ	NO_SND14
	LSR.L	#2,D5
	AND.L	D6,D5
	MOVE.L	D5,(A4)+		; voice 2, right low
	LSR.L	#2,D4
	AND.L	D6,D4
	MOVE.L	D4,(A5)+		; voice 3, left low
	ENDC
	DBF	D7,.l
	MOVE.W	SndWrite,D1
	ADDQ.W	#1,D1
	CMP.W	#SND_BLOCKS,D1
	BCS.S	.nw
	MOVEQ	#0,D1
.nw:	MOVE.W	D1,SndWrite		; publish after the block is written
	MOVEM.L	(SP)+,D2-D7/A2-A5
	RTS

SndStats:
	MOVE.L	SndUnder,SST_UNDER(A0)
	MOVE.L	SndOver,SST_OVER(A0)
	MOVE.W	SndNom,SST_NOMINAL(A0)
	MOVE.W	SndLines,SST_LINES(A0)
	IFNE	SndStat
	MOVE.L	SndStIrqs,SST_IRQS(A0)
	MOVE.L	SndStMin,SST_JMIN(A0)
	MOVE.L	SndStMax,SST_JMAX(A0)
	MOVE.L	SndStLine,SST_LINE(A0)
	LEA	SST_FILL(A0),A0
	LEA	SndStFill,A1
	MOVEQ	#SND_BLOCKS-1,D0
.f:	MOVE.L	(A1)+,(A0)+
	DBF	D0,.f
	ENDC
	RTS

	IFNE	SndStat
; From SndIrq (test builds): the gap since the last interrupt against the length of
; the block that played in it, in colour clocks, the frame taken off. A1 = $DFF000.
; Uses D0-D1.
SndStIrq:
	MOVE.L	$04(A1),D0
	MOVE.L	D0,D1
	LSR.L	#8,D1
	AND.L	#$1FF,D1
	MOVE.L	D1,SndStLine
	AND.L	#$FF,D0
	MULU.W	#455,D1
	LSR.L	#1,D1
	ADD.L	D1,D0			; colour clocks into the frame
	MOVE.L	D0,D1
	SUB.L	SndStPrev,D1
	MOVE.L	D0,SndStPrev
	SUB.L	SndStExp,D1
	ADDQ.L	#1,SndStIrqs
	CMP.L	#3,SndStIrqs		; the first gaps are the start
	BCS.S	.k
	MOVE.L	SndFrameCC,D0		; into +- half a frame
	LSR.L	#1,D0
.hi:	CMP.L	D0,D1
	BLE.S	.lo
	SUB.L	SndFrameCC,D1
	BRA.S	.hi
.lo:	NEG.L	D0
.lo2:	CMP.L	D0,D1
	BGE.S	.ok
	ADD.L	SndFrameCC,D1
	BRA.S	.lo2
.ok:	CMP.L	SndStMin,D1
	BGE.S	.n1
	MOVE.L	D1,SndStMin
.n1:	CMP.L	SndStMax,D1
	BLE.S	.k
	MOVE.L	D1,SndStMax
.k:	MOVE.W	SndQueued,D0		; the block starting now plays until the next interrupt
	MOVE.W	(SndLen.L,D0.W*2),D0
	MULU.W	SndPer,D0
	ADD.L	D0,D0
	MOVE.L	D0,SndStExp
	RTS
	ENDC

	SECTION	SndBss,BSS
	CNOP	0,4
SndBlk:		DS.L	SND_BLOCKS	; address of each block
SndLen:		DS.W	SND_BLOCKS	; its length, words
SndRate:	DS.L	1
SndFrameCC:	DS.L	1
SndUnder:	DS.L	1
SndOver:	DS.L	1
SndPlay:	DS.W	1		; the block playing
SndQueued:	DS.W	1		; the block Paula takes next
SndWrite:	DS.W	1		; the next block to write
SndNom:		DS.W	1		; samples a frame
SndLines:	DS.W	1
SndBlock:	DS.W	1
SndPer:		DS.W	1
SndHand:	DS.W	1
SndPrimed:	DS.B	2
	IFNE	SndStat
	CNOP	0,4
SndStIrqs:	DS.L	1
SndStPrev:	DS.L	1
SndStExp:	DS.L	1
SndStMin:	DS.L	1
SndStMax:	DS.L	1
SndStLine:	DS.L	1
SndStFill:	DS.L	SND_BLOCKS
	ENDC
