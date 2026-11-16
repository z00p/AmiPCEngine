; PSGMix.asm: the six PSG channels mixed in software, once a frame in the main
; loop, for the RTG display (ToolType / CLI word SOUNDMIX). Output through
; SndOut.asm. The model is tools/mixrender.py: nearest sample from wave RAM by a
; phase accumulator, registers once a frame, DDA samples at their place in the
; frame, 1.5 dB volume steps per side, gain 0.32 of full scale for each channel,
; the sum clipped. No LFO and no per-line registers yet (ahi.md, steps 4 on).
;
; The registers used for a frame's block are those at the end of that PCE frame.
; AGA and RTG without SOUNDMIX never come here: PSGDdaFrame tests PSGMixOn, the
; RTG vblank leaves out TocaPSG, and the DDA voices and PSGAudInt stay idle.
; DDA capture (PSGWrite) runs as always; this file reads what it stored. The
; ring lies over PSGDdaRing, which nothing uses in this mode: no chip RAM added.
;
; A sample is held in a long as L * 65536 + R, both signed, at half scale, so one
; ADD.L does both sides and six full channels cannot overflow (6 x 5242 < 32768).
; MixGain has the sides' gains, MixLevel a channel's 32 levels, MixWaveT its 32
; wave steps, both rebuilt only when the gain or the wave changes.

MIXPER	= 160		; Paula period: 22168 Hz, 374 samples a 263-line frame (+7.5 colour clocks), 444 a 313-line one
MIXHAND	= 1		; blocks waiting at the end of a frame (SC_HAND)
MIXBLK	= 448		; bytes a voice a block: 444 + 2 + 2
MIXK	= 677266168	; 2^22 * 3579545 / 3546895 * MIXPER: phase step = (MIXK / F) << 5; noise (MIXK / d) << 4

	IFGT	(SND_BLOCKS*SND_VOICES*MIXBLK)-(6*8*264)
	FAIL	The ring does not fit in PSGDdaRing
	ENDC

	SECTION	MixCode,CODE

; Main loop, at the end of a PCE frame. Keeps all registers.
	CNOP	0,8
PSGMixFrame:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	IFNE	DbgRows
	JSR	DbgLapCpu
	ENDC
	TST.B	MixRun
	BNE.S	.go
	BSR	MixStart
.go:	JSR	SndFrame
	MOVE.W	D0,MixN
	MOVEQ	#0,D1
	MOVE.W	D0,D1
	SWAP	D1
	DIVU.L	#263,D1
	MOVE.L	D1,MixLineStep		; samples a PCE line, 16.16
	LEA	MixBuf,A0
	SUBQ.W	#1,D0
.c:	CLR.L	(A0)+
	DBF	D0,.c
	MOVEQ	#0,D6
	IFNE	CdPsgMute
	BRA.S	.chx			; test: the PSG left out (CD audio and ADPCM alone)
	ENDC
.ch:	BSR	MixChan
	ADDQ.W	#1,D6
	CMP.W	#6,D6
	BNE.S	.ch
.chx:
	LEA	MixBuf,A0		; L * 65536 + R at half scale -> L, R, clipped
	MOVE.W	MixN,D7
	SUBQ.W	#1,D7
.o:	MOVE.L	(A0),D0
	MOVE.W	D0,D1
	EXT.L	D1
	SUB.L	D1,D0
	SWAP	D0
	ADD.W	D0,D0
	BVS.S	.cl
.lok:	ADD.W	D1,D1
	BVS.S	.cr
.rok:	MOVE.W	D0,(A0)+
	MOVE.W	D1,(A0)+
	DBF	D7,.o
	BRA.S	.put
.cl:	SMI	D0			; overflowed negative: it was positive
	EXT.W	D0
	EOR.W	#$8000,D0
	BRA.S	.lok
.cr:	SMI	D1
	EXT.W	D1
	EOR.W	#$8000,D1
	BRA.S	.rok
.put:
	IFEQ	CdSndOff
	TST.B	CdOn
	BEQ.S	.ncd
	JSR	CdMixFrame		; a CD game: CD audio and ADPCM added
.ncd:
	ENDC
	IFNE	MixDump
	BSR	MixDumpFrame
	ENDC
	LEA	MixBuf,A0
	MOVE.W	MixN,D0
	JSR	SndPut
	IFNE	DbgRows
	JSR	DbgTod
	MOVE.W	D0,D1
	SUB.W	DbgLast,D0
	MOVE.W	D1,DbgLast
	AND.L	#$FFFF,D0
	ADD.L	D0,MixLines
	ENDC
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

; D6 = channel. Uses D0-D5, D7, A0-A5.
MixChan:
	LEA	PSGBuffer,A5
	LEA	(A5,D6.W*8),A5		; A5 = channel registers
	MOVE.B	4(A5),D5
	TST.B	(PSGDdaHad.L,D6.W)
	BEQ.S	.ctl
	MOVE.B	(PSGDdaLastCtl.L,D6.W),D5	; samples this frame: the volume they were written with
.ctl:	MOVEQ	#0,D2			; D2 = gains, L << 16 | R
	TST.B	D5
	BPL.S	.gd
	MOVEQ	#$1F,D1
	AND.B	D5,D1
	BEQ.S	.gd
	NEG.W	D1
	ADD.W	#31,D1			; 31 - volume
	MOVE.B	5(A5),D3		; balance
	MOVE.B	PSGMaster,D4
	MOVEQ	#0,D0
	MOVE.B	D3,D0
	LSR.B	#4,D0
	BSR	MixSide
	SWAP	D2
	MOVEQ	#$0F,D0
	AND.B	D3,D0
	LSL.B	#4,D4
	BSR	MixSide
.gd:	LEA	MixLevel,A2
	MOVE.W	D6,D0
	LSL.W	#7,D0
	ADD.W	D0,A2			; A2 = this channel's levels
	CMP.L	(MixGainNow.L,D6.W*4),D2
	BEQ.S	.same
	MOVE.L	D2,(MixGainNow.L,D6.W*4)
	ST	(MixStale.L,D6.W)
	BSR	MixMakeLevels
.same:	TST.B	(PSGDdaHad.L,D6.W)
	BNE	MixDda
	BTST	#6,D5
	BNE	MixHold
	TST.L	D2
	BEQ	.ret
	CMP.W	#4,D6
	BCS.S	.tone
	TST.B	7(A5)
	BMI	MixNoise
.tone:	CMP.W	#1,D6
	BNE.S	.nolfo
	MOVE.B	PSGLfo+1,D0
	AND.B	#$03,D0
	BNE	.ret			; LFO on: channel 1 only modulates channel 0
.nolfo:	MOVEQ	#0,D1
	MOVE.B	3(A5),D1
	AND.B	#$0F,D1
	LSL.W	#8,D1
	MOVE.B	2(A5),D1
	TST.W	D1
	BNE.S	.f
	MOVE.W	#$1000,D1
.f:	CMP.W	#8,D1
	BCS	.ret			; above ~14 kHz
	CMP.W	(MixF.L,D6.W*2),D1
	BEQ.S	.inc
	MOVE.W	D1,(MixF.L,D6.W*2)
	MOVE.L	#MIXK,D0
	DIVU.L	D1,D0
	LSL.L	#5,D0
	MOVE.L	D0,(MixInc.L,D6.W*4)
.inc:	LEA	MixWaveT,A3
	MOVE.W	D6,D0
	LSL.W	#7,D0
	ADD.W	D0,A3			; A3 = this channel's wave steps
	TST.B	(PSGWaveDirty.L,D6.W)
	BNE.S	.make
	TST.B	(MixStale.L,D6.W)
	BEQ.S	.play
.make:	SF	(PSGWaveDirty.L,D6.W)
	SF	(MixStale.L,D6.W)
	LEA	PSGWave,A0
	MOVE.W	D6,D0
	LSL.W	#5,D0
	ADD.W	D0,A0
	MOVE.L	A3,A1
	MOVEQ	#32-1,D1
.w:	MOVEQ	#0,D0
	MOVE.B	(A0)+,D0
	MOVE.L	(A2,D0.W*4),(A1)+
	DBF	D1,.w
.play:	LEA	MixBuf,A1
	MOVE.L	(MixPhase.L,D6.W*4),D1
	MOVE.L	(MixInc.L,D6.W*4),D2
	MOVEQ	#11,D4
	MOVE.W	MixN,D7
	SUBQ.W	#1,D7
.l:	MOVE.L	D1,D0
	SWAP	D0
	LSR.W	D4,D0
	ADD.L	D2,D1
	MOVE.L	(A3,D0.W*4),D3
	ADD.L	D3,(A1)+
	DBF	D7,.l
	MOVE.L	D1,(MixPhase.L,D6.W*4)
.ret:	RTS

; D0 = balance of this side, D1 = 31 - volume, D4 = master balance in its high
; nibble -> D2.w = gain (0 when either is 0). Keeps D1, D3, D4.
MixSide:
	TST.B	D0
	BEQ.S	.z
	MOVE.W	D4,-(SP)
	LSR.B	#4,D4
	BEQ.S	.z0
	AND.W	#$000F,D4
	ADD.W	D4,D0
	ADD.W	D0,D0
	NEG.W	D0
	ADD.W	#60,D0
	ADD.W	D1,D0			; attenuation, 1.5 dB steps
	MOVE.W	(SP)+,D4
	MOVE.W	(MixGain.L,D0.W*2),D2
	RTS
.z0:	MOVE.W	(SP)+,D4
.z:	CLR.W	D2
	RTS

; D2 = gains, A2 = the channel's 32 levels: (2 * level - 31) * gain / 256, each side.
MixMakeLevels:
	MOVEM.L	D1-D5/A0,-(SP)
	MOVE.L	D2,D4
	MOVEQ	#0,D5
	MOVE.W	D4,D5			; right gain
	CLR.W	D4
	SWAP	D4			; left gain
	MOVE.L	D4,D0
	MULU.W	#31,D0
	NEG.L	D0
	MOVE.L	D5,D1
	MULU.W	#31,D1
	NEG.L	D1
	ADD.L	D4,D4
	ADD.L	D5,D5
	MOVE.L	A2,A0
	MOVEQ	#32-1,D3
.l:	MOVE.L	D0,D2
	ASR.L	#8,D2
	SWAP	D2
	CLR.W	D2
	MOVE.L	D1,-(SP)
	ASR.L	#8,D1
	ADD.L	D1,D2
	MOVE.L	(SP)+,D1
	MOVE.L	D2,(A0)+
	ADD.L	D4,D0
	ADD.L	D5,D1
	DBF	D3,.l
	MOVEM.L	(SP)+,D1-D5/A0
	RTS

; DDA on, no samples this frame: the channel holds its last level.
MixHold:
	MOVEQ	#$1F,D0
	AND.B	6(A5),D0
	MOVE.L	(A2,D0.W*4),D3
	BEQ.S	.x
	LEA	MixBuf,A1
	MOVE.W	MixN,D7
	SUBQ.W	#1,D7
.l:	ADD.L	D3,(A1)+
	DBF	D7,.l
.x:	RTS

; Noise on channels 4 and 5: a new random level whenever the phase wraps, every
; sample when the noise is faster than the output.
MixNoise:
	MOVEQ	#$1F,D0
	AND.B	7(A5),D0
	EOR.B	#$1F,D0			; d: the LFSR steps every d * 64 clocks (0: 32)
	MOVEQ	#-1,D2
	CMP.W	#3,D0
	BCS.S	.fast
	MOVE.L	#MIXK,D2
	DIVU.L	D0,D2
	LSL.L	#4,D2
.fast:	MOVE.L	124(A2),A3		; level 31
	MOVE.L	(A2),A4			; level 0
	MOVE.L	#$80200003,D4
	MOVE.L	MixLfsr,D5
	MOVE.L	(MixPhase.L,D6.W*4),D1
	MOVE.L	(MixNCur.L,D6.W*4),D3
	LEA	MixBuf,A1
	MOVE.W	MixN,D7
	SUBQ.W	#1,D7
.l:	ADD.L	D2,D1
	BCC.S	.h
	LSR.L	#1,D5
	BCC.S	.z
	EOR.L	D4,D5
	MOVE.L	A3,D3
	BRA.S	.h
.z:	MOVE.L	A4,D3
.h:	ADD.L	D3,(A1)+
	DBF	D7,.l
	MOVE.L	D1,(MixPhase.L,D6.W*4)
	MOVE.L	D3,(MixNCur.L,D6.W*4)
	MOVE.L	D5,MixLfsr
	RTS

; This frame's DDA samples, each from its place in the frame to the next, the
; level held. Timer-driven (PSGTickCheck): by tick, from the first write's line,
; the game's own spacing. Otherwise the line grid. A2 = levels.
MixDda:
	SF	(PSGDdaHad.L,D6.W)
	MOVE.W	D6,D0
	MULU.W	#264,D0
	LEA	PSGDdaLine,A3
	ADD.L	D0,A3
	MOVEQ	#0,D2
	MOVE.B	(PSGDdaHold.L,D6.W),D2	; level before the first write
	MOVE.L	(A2,D2.W*4),D3		; D3 = its value
	LEA	MixBuf,A1		; A1, D4: where the output has got to
	MOVEQ	#0,D4
	MOVE.L	MixLineStep,A4
	JSR	PSGTickCheck
	BNE.S	.tick
	MOVEQ	#0,D5
	MOVE.W	#263-1,D7
.l:	MOVE.B	(A3)+,D1
	BMI.S	.n			; $FF: no write on this line
	ST	-1(A3)
	MOVE.L	D5,D0
	SWAP	D0
	BSR	MixFillTo
	MOVEQ	#0,D2
	MOVE.B	D1,D2
	MOVE.L	(A2,D2.W*4),D3
.n:	ADD.L	A4,D5
	DBF	D7,.l
	BRA.S	.end
.tick:	SF	PSGTkMode
	MOVEQ	#0,D5			; line pass: only the first write's line, and clear
	MOVEQ	#-1,D1
	MOVE.W	#263-1,D7
.t0:	TST.B	(A3)+
	BMI.S	.t1
	ST	-1(A3)
	TST.L	D1
	BPL.S	.t1
	MOVE.L	D5,D1
.t1:	ADD.L	A4,D5
	DBF	D7,.t0
	TST.L	D1
	BPL.S	.t2
	MOVEQ	#0,D1			; (line 263, not in the pass)
.t2:	MOVE.L	D1,D5			; 16.16 position of the first sample
	MOVEQ	#0,D1
	MOVE.B	TimerReload,D1
	ADDQ.W	#1,D1
	MULU.W	#561,D1			; 3072 / 358995 of a frame, 16.16
	MOVEQ	#0,D0
	MOVE.W	MixN,D0
	MULU.L	D0,D1
	MOVE.L	D1,A4			; samples a tick
	LEA	PSGTkBuf,A3
	MOVE.W	D6,D0
	LSL.W	#8,D0
	ADD.W	D0,A3
	MOVE.W	(PSGTkLast.L,D6.W*2),D7
.t:	MOVE.B	(A3)+,D1
	BMI.S	.tn			; no write on this tick
	MOVE.L	D5,D0
	SWAP	D0
	BSR	MixFillTo
	MOVEQ	#0,D2
	MOVE.B	D1,D2
	MOVE.L	(A2,D2.W*4),D3
.tn:	ADD.L	A4,D5
	DBF	D7,.t
.end:	MOVE.W	MixN,D0
	BSR	MixFillTo
	MOVE.B	D2,(PSGDdaHold.L,D6.W)
	JMP	PSGTickClear

; D0.w = sample to fill up to (cut to the block), D3 = value, A1, D4 = where the
; output has got to. Uses D0.
MixFillTo:
	CMP.W	MixN,D0
	BLS.S	.c
	MOVE.W	MixN,D0
.c:	SUB.W	D4,D0
	BLS.S	.x
	ADD.W	D0,D4
	SUBQ.W	#1,D0
.f:	ADD.L	D3,(A1)+
	DBF	D0,.f
.x:	RTS

; First frame of a run: from the main loop, the OS frozen.
MixStart:
	LEA	MixCfg,A0
	MOVE.L	#PSGDdaRing,SC_RING(A0)
	MOVE.W	#MIXBLK,SC_BLOCK(A0)
	MOVE.W	#MIXPER,SC_PERIOD(A0)
	MOVE.W	#MIXHAND,SC_HAND(A0)
	JSR	SndOpen
	MOVE.L	VBRPun,A0		; PSGDdaInit saved the OS vector, DescongelaAMIGA puts it back
	MOVE.L	#MixAudInt,$70(A0)
	LEA	MixGainNow,A0
	MOVEQ	#6-1,D0
.g:	MOVE.L	#-1,(A0)+
	DBF	D0,.g
	LEA	MixF,A0
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	MOVE.L	#-1,MixStale
	MOVE.L	#-1,MixStale+4
	TST.L	MixLfsr
	BNE.S	.lf
	MOVE.L	#$ACE1ACE1,MixLfsr
.lf:	JSR	SndStart
	ST	MixRun
	RTS

; Leaving play: DescongelaAMIGA, frozen. Paula silent, the chip waves rebuilt if
; the next run plays on the voices. Keeps all registers.
MixStop:
	MOVEM.L	D0-D1/A0-A1,-(SP)
	SF	PSGMixOn
	TST.B	MixRun
	BEQ.S	.x
	SF	MixRun
	JSR	SndStop
	MOVE.L	#-1,PSGWaveDirty
	MOVE.L	#-1,PSGWaveDirty+4
.x:	MOVEM.L	(SP)+,D0-D1/A0-A1
	RTS

; Level 4, the OS frozen.
	CNOP	0,4
MixAudInt:
	JSR	SndIrq
	NOP
	RTE

	IFNE	SndStat
; AutoWriteResult: the sound line of the result file.
MixStatFill:
	MOVEM.L	D0-D3/A0-A2,-(SP)
	LEA	MixStatOut,A0
	JSR	SndStats
	LEA	MixStatOut,A1
	LEA	MixStatT,A2
.f:	MOVE.L	(A2)+,D1
	BEQ.S	.d
	MOVE.L	D1,A0
	MOVE.L	(A2)+,D1
	MOVE.L	(A1,D1.L),D0
	JSR	AutoHex
	BRA.S	.f
.d:	MOVEQ	#0,D0
	MOVE.W	MixStatOut+SST_NOMINAL,D0
	LEA	MixStN,A0
	JSR	AutoHex
	MOVEQ	#0,D0
	MOVE.W	MixStatOut+SST_LINES,D0
	IFEQ	NO_NTSCRATE
	MOVE.B	BeamCalls+1,D0		; (test builds) BeamSet calls << 24 | highest H count << 16 | highest line
	LSL.W	#8,D0
	MOVE.B	BeamHMax,D0
	SWAP	D0
	MOVE.W	BeamTop,D0
	ENDC
	LEA	MixStL,A0
	JSR	AutoHex
	IFNE	DbgRows
	MOVE.L	MixLines,D0
	LEA	MixStM,A0
	JSR	AutoHex
	ENDC
	IFNE	CdDbg
	MOVE.L	CdDbgP,D0		; CD test: dmac = play captures, aint = non-silent CD, vec4 = tracks loaded << 24 | non-silent ADPCM
	LEA	MixStD,A0
	JSR	AutoHex
	MOVE.L	CdDbgN,D0
	LEA	MixStE,A0
	JSR	AutoHex
	MOVEQ	#0,D1
	LEA	CdTrk,A1
	MOVE.W	CdTracks,D2
	BEQ.S	.cn
	SUBQ.W	#1,D2
.cl:	TST.L	TRK_ARAM(A1)
	BEQ.S	.cz
	ADDQ.L	#1,D1
.cz:	LEA	TRK_SIZE(A1),A1
	DBF	D2,.cl
.cn:	ROR.L	#8,D1
	MOVE.L	CdDbgD,D0
	AND.L	#$FFFFFF,D0
	OR.L	D1,D0
	LEA	MixStV,A0
	JSR	AutoHex
	MOVEM.L	(SP)+,D0-D3/A0-A2
	RTS
	ENDC
	MOVEQ	#0,D0			; on the way out: audio DMA, audio interrupts, level 4 vector still ours?
	MOVE.W	$DFF002,D0
	AND.W	#$000F,D0
	LEA	MixStD,A0
	JSR	AutoHex
	MOVEQ	#0,D0
	MOVE.W	$DFF01C,D0
	AND.W	#$0780,D0
	LEA	MixStE,A0
	JSR	AutoHex
	MOVE.L	VBRPun,A0
	MOVE.L	$70(A0),D0
	CMP.L	#MixAudInt,D0
	SEQ	D0
	AND.L	#1,D0
	LEA	MixStV,A0
	JSR	AutoHex
	MOVEM.L	(SP)+,D0-D3/A0-A2
	RTS
MixStatT:
	DC.L	MixStU,SST_UNDER,MixStO,SST_OVER,MixStI,SST_IRQS
	DC.L	MixStJ0,SST_JMIN,MixStJ1,SST_JMAX,MixStB,SST_LINE
	DC.L	MixStF0,SST_FILL,MixStF1,SST_FILL+4,MixStF2,SST_FILL+8,MixStF3,SST_FILL+12
	DC.L	MixStF4,SST_FILL+16,0
	ENDC

	IFNE	MixDump
; Test builds: every block as handed to SndOut, to PROGDIR:AmiPCE.mix at exit.
MixDumpFrame:
	MOVE.L	MixDumpPtr,A1
	MOVEQ	#0,D0
	MOVE.W	MixN,D0
	MOVE.L	D0,D1
	LSL.L	#2,D1
	ADD.L	A1,D1
	CMP.L	#MixDumpEnd,D1
	BCC.S	.x
	LEA	MixBuf,A0
	SUBQ.W	#1,D0
.l:	MOVE.L	(A0)+,(A1)+
	DBF	D0,.l
	MOVE.L	A1,MixDumpPtr
.x:	RTS
MixDumpWrite:				; OS alive again
	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.L	$4.W,A6
	LEA	AutoDosName,A1
	MOVEQ	#0,D0
	JSR	-$228(A6)		; OpenLibrary
	TST.L	D0
	BEQ.S	.x
	MOVE.L	D0,A6
	MOVE.L	#MixDumpName,D1
	MOVE.L	#1006,D2		; MODE_NEWFILE
	JSR	-30(A6)			; Open
	MOVE.L	D0,D4
	BEQ.S	.cl
	MOVE.L	D4,D1
	MOVE.L	#MixDumpBuf,D2
	MOVE.L	MixDumpPtr,D3
	SUB.L	D2,D3
	JSR	-48(A6)			; Write
	MOVE.L	D4,D1
	JSR	-36(A6)			; Close
.cl:	MOVE.L	A6,A1
	MOVE.L	$4.W,A6
	JSR	-$19E(A6)		; CloseLibrary
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
	ENDC

; round(0.32 * 32767 / 2 / 31 * 256 * 10^(-1.5 * a / 20)), a = attenuation in steps
MixGain:
	DC.W	43295,36428,30650,25789,21699,18257,15362,12925,10875,9150,7699,6478
	DC.W	5450,4586,3859,3247,2732,2298,1934,1627,1369,1152,969,816
	DC.W	686,577,486,409,344,289,243,205,172,145,122,103
	DC.W	86,73,61,51,43,36,31,26,22,18,15,13
	DC.W	11,9,8,6,5,5,4,3,3,2,2,2
	DC.W	1,1,1,1,1,1,0,0,0,0,0,0
	DC.W	0,0,0,0,0,0,0,0,0,0,0,0
	DC.W	0,0,0

	IFNE	SndStat
	SECTION	MixVars,DATA
MixStatTxt:	DC.B	"snd under=$"
MixStU:		DC.B	"00000000 over=$"
MixStO:		DC.B	"00000000 sirq=$"
MixStI:		DC.B	"00000000 jmin=$"
MixStJ0:	DC.B	"00000000 jmax=$"
MixStJ1:	DC.B	"00000000 bline=$"
MixStB:		DC.B	"00000000 nom_=$"
MixStN:		DC.B	"00000000 lns_=$"
MixStL:		DC.B	"00000000 fil0=$"
MixStF0:	DC.B	"00000000 fil1=$"
MixStF1:	DC.B	"00000000 fil2=$"
MixStF2:	DC.B	"00000000 fil3=$"
MixStF3:	DC.B	"00000000 fil4=$"
MixStF4:	DC.B	"00000000 mixl=$"
MixStM:		DC.B	"00000000 dmac=$"
MixStD:		DC.B	"00000000 aint=$"
MixStE:		DC.B	"00000000 vec4=$"
MixStV:		DC.B	"00000000",10
MixStatEnd:
	EVEN
	ENDC
	IFNE	MixDump
MixDumpName:	DC.B	"PROGDIR:AmiPCE.mix",0
	EVEN
MixDumpPtr:	DC.L	MixDumpBuf
	ENDC

	SECTION	MixBss,BSS
	CNOP	0,4
MixBuf:		DS.L	446+4		; a block, L * 65536 + R, then L, R
MixLevel:	DS.L	6*32		; per channel: value of each of the 32 levels
MixWaveT:	DS.L	6*32		; per channel: value of each wave step
MixGainNow:	DS.L	6		; the gains MixLevel was made for
MixPhase:	DS.L	6
MixInc:		DS.L	6
MixNCur:	DS.L	6
MixLineStep:	DS.L	1
MixLfsr:	DS.L	1
MixLines:	DS.L	1		; DbgRows: scan lines in the mix
MixF:		DS.W	6		; the frequency MixInc was made for
MixN:		DS.W	1		; samples this frame
MixCfg:		DS.B	SC_SIZE
MixStale:	DS.B	8		; the wave steps need rebuilding
MixRun:		DS.B	1		; SndOut started in this run
PSGMixOn:	DS.B	1		; this run mixes: SOUNDMIX and RTG
SndMixWant:	DS.B	2		; ToolType or CLI word
	IFNE	SndStat
	CNOP	0,4
MixStatOut:	DS.B	SST_SIZE
	ENDC
	IFNE	MixDump
	SECTION	MixDumpB,BSS
MixDumpBuf:	DS.B	8000000
MixDumpEnd:
	ENDC
