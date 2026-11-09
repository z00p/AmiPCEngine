; ------------------------------------> Inicializa PSG
InitPSG:
	LEA	$DFF000,A6
	BSET	#1,$BFE001		; Datos Musica.

	IFEQ	NO_PSGWAVE
	MOVE.L	#PSGSilence,$A0(A6)	; all voices on a silent word until TocaPSG gives them a wave
	MOVE.L	#PSGSilence,$B0(A6)
	MOVE.L	#PSGSilence,$C0(A6)
	MOVE.L	#PSGSilence,$D0(A6)
	ELSE
	MOVE.L	#Onda,$A0(A6)	; wave
	MOVE.L	#Onda,$B0(A6)
	MOVE.L	#Onda,$C0(A6)
	MOVE.L	#Onda,$D0(A6)
	ENDC

	MOVE.W	#1,$A4(A6)	; Size
	MOVE.W	#1,$B4(A6)
	MOVE.W	#1,$C4(A6)
	MOVE.W	#1,$D4(A6)

	MOVE.W	#0,$A8(A6)	; Volumen
	MOVE.W	#0,$B8(A6)
	MOVE.W	#0,$C8(A6)
	MOVE.W	#0,$D8(A6)
	IFEQ	NO_PSGWAVE|NO_PSGDDA|NO_DDAQUEUE
	MOVE.W	#124,$A6(A6)	; period: the 2-byte silent loop ends at once (left unset, WinUAE took 47 frames)
	MOVE.W	#124,$B6(A6)
	MOVE.W	#124,$C6(A6)
	MOVE.W	#124,$D6(A6)
	ENDC

	MOVE.W	#$800F,$96(A6)
	IFEQ	NO_PSGWAVE
	IFEQ	NO_PSGNOISE
	BSR	PSGMakeNoise
	ENDC
	IFEQ	NO_PSGDDA
	BSR	PSGDdaInit
	ENDC
	ENDC

;	CLR.L	SounVol1
;	CLR.L	SounVol3
;	CLR.W	SounVol5
;	CLR.L	SounTim1
;	CLR.L	SounTim3
;	CLR.W	SounTim5
;	CLR.L	SounEnv1
;	CLR.B	SounEnv5

	RTS
; ------------------------------------<


; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
	CNOP	0,8
TocaPSG:
	LEA	$DFF000,A6

	IFEQ	NO_PSGWAVE
	MOVEM.L	D2-D7/A0-A5,-(SP)
	BSR	PSGUpdate
	MOVEM.L	(SP)+,D2-D7/A0-A5
	RTS
	ELSE

TocaCh:	MACRO
	MOVE.W	PSGBuffer+\1+2,D1
	ROR.W	#8,D1
	AND.W	#$0FFF,D1
	LSL.W	#4,D1
	BNE.S	\@NoFreqCer0
	MOVEQ	#1,D1
\@NoFreqCer0:
	MOVE.W	D1,\2+$6(A6)	; Freq

	MOVEQ	#0,D1
	MOVE.B	PSGBuffer+\1+4,D1
	BPL.S	\@NoToca

	AND.W	#$001F,D1
	LSL.W	#1,D1
\@NoToca:
	MOVE.W	D1,\2+$8(A6)	; Vol
	ENDM

	TocaCh	00,$A0
	TocaCh	08,$B0
	TocaCh	16,$C0
	TocaCh	24,$D0

	RTS
	ENDC



PSG_Hack:
	MOVE.B	D2,(Onda0.L,D1.W)
	RTS


	IFEQ	NO_PSGWAVE
; =====================================================================
; PC Engine PSG (HuC6280) on Paula. Not in Juan's alpha (NO_PSGWAVE=1).
;
; Register state, written by PSGWrite (IO.asm calls it for $0800-$0BFF):
;   PSGBuffer + ch*8 + reg (Juan's layout): +2/+3 frequency (12 bits),
;   +4 control (bit 7 on, bit 6 DDA, bits 0-4 volume), +5 balance (L<<4|R),
;   +6 last DDA sample, +7 noise ($0807, channels 4/5).
;   PSGWave + ch*32: the channel's 32 5-bit wave samples, PSGWaveIdx its
;   write index, PSGWaveDirty set when the chip copy must be rebuilt.
; Once per Amiga vblank (TocaPSG, from the vblank interrupt) the state is
; turned into Paula settings; nothing runs per sample.
;
; Tone: the PSG steps through its 32 samples at 3.58 MHz / F (F = 12-bit
; frequency, 0 = 4096), so the Paula period for the 32-byte loop is
; F * 3546895 / 3579545 (PAL Paula clock). Below Paula's minimum period
; (124) the loop steps through a 16/8/4/2-sample copy of the wave (pairs
; averaged) at 2/4/8/16 x the period; tones above ~14 kHz are muted.
; Volume: attenuation in 1.5 dB steps = (31 - volume) + 2*(15 - balance)
; + 2*(15 - master balance), the louder side counts, then PSGVolTab maps
; it to Paula's linear 0-64.
; =====================================================================

; New game (PCE_Init): forget the last game's PSG state.
PSGReset:
	LEA	PSGBuffer,A0
	MOVEQ	#(8*8)/4-1,D0
.c1:	CLR.L	(A0)+
	DBF	D0,.c1
	LEA	PSGWave,A0
	MOVEQ	#(6*32)/4-1,D0
.c2:	MOVE.L	#$10101010,(A0)+	; mid level
	DBF	D0,.c2
	CLR.L	PSGWaveIdx
	CLR.L	PSGWaveIdx+4
	MOVE.L	#-1,PSGWaveDirty
	MOVE.L	#-1,PSGWaveDirty+4
	CLR.B	PSGSel
	CLR.B	PSGMaster
	CLR.W	PSGLfo
	IFEQ	NO_PSG6
	MOVE.L	#-1,PSGVoiceOwner
	ENDC
	IFEQ	NO_PSGDDA
	BSR	PSGDdaReset
	ENDC
	RTS

; I/O write to $0800-$0BFF (mirrored every 16 bytes).
; D0.w = offset in the I/O page, (A4) = the byte written. Uses D0/D1 only
; (D2/A0 saved where needed), like Juan's I/O handlers.
PSGWrite:
	AND.W	#$000F,D0
	BNE.S	.notSel
	MOVE.B	(A4),D1
	AND.B	#$07,D1
	MOVE.B	D1,PSGSel
	RTS
.notSel:
	CMP.W	#1,D0
	BEQ.S	.master
	CMP.W	#8,D0
	BCC.S	.lfo
	MOVEQ	#0,D1
	MOVE.B	PSGSel,D1
	CMP.B	#6,D1
	BCC.S	.ret			; channels 6 and 7 do not exist
	LSL.W	#3,D1
	ADD.W	D0,D1			; D1 = ch*8 + reg
	CMP.W	#6,D0
	BEQ.S	.wave
	MOVE.B	(A4),(PSGBuffer.L,D1.W)
	CMP.W	#4,D0
	BNE.S	.ret
	MOVE.B	(A4),D0			; $0804 with DDA on and the channel off: wave index back to 0
	AND.B	#$C0,D0
	CMP.B	#$40,D0
	BNE.S	.ret
	LSR.W	#3,D1
	CLR.B	(PSGWaveIdx.L,D1.W)
.ret:	RTS
.master:
	MOVE.B	(A4),PSGMaster
	RTS
.lfo:
	CMP.W	#10,D0
	BCC.S	.ret
	SUBQ.W	#8,D0
	MOVE.B	(A4),(PSGLfo.L,D0.W)
	RTS
.wave:
	MOVE.B	(A4),D0
	AND.B	#$1F,D0
	BTST	#6,(PSGBuffer-2.L,D1.W)	; DDA on: the byte is the channel's output
	BEQ.S	.notDDA
	MOVE.B	D0,(PSGBuffer.L,D1.W)	; +6 = last DDA sample
	IFEQ	NO_PSGDDA
	MOVE.L	D2,-(SP)		; and into this frame's line buffer
	MOVE.W	D1,D2
	LSR.W	#3,D2
	ST	(PSGDdaHad.L,D2.W)
	IFEQ	NO_DDAQUEUE
	MOVE.B	(PSGBuffer+4.L,D2.W*8),(PSGDdaLastCtl.L,D2.W)	; its volume goes with the buffer
	ENDC
	IFEQ	DdaTickOff
	BSR	PSGTickPut		; and by timer tick
	ENDC
	MULU.W	#264,D2
	IFEQ	NO_VBLUNIT|NO_VDCDMA
	ADD.W	UnitLine,D2		; the line of the emulated frame (it starts at the vblank line)
	ELSE
	ADD.W	ScanLine(A3),D2
	ENDC
	MOVE.B	D0,(PSGDdaLine.L,D2.L)
	MOVE.L	(SP)+,D2
	IFEQ	PSGLog
	RTS				; a DDA sample is not wave data (Mesen: wave RAM unchanged)
	ENDC
	ENDC
	IFNE	PSGLog
	LSR.W	#3,D1
	ADDQ.B	#1,(PSGDdaCnt.L,D1.W)
	LSL.W	#3,D1
	ADDQ.W	#6,D1
	IFEQ	NO_PSGDDA
	RTS				; a DDA sample is not wave data (Mesen: wave RAM unchanged)
	ENDC
	ENDC
.notDDA:
	TST.B	(PSGBuffer-2.L,D1.W)	; channel on: wave RAM is not written
	IFNE	PSGLog
	BMI	.ret
	ELSE
	BMI.S	.ret
	ENDC
	MOVE.L	D2,-(SP)
	LSR.W	#3,D1			; ch
	MOVEQ	#0,D2
	MOVE.B	(PSGWaveIdx.L,D1.W),D2
	ST	(PSGWaveDirty.L,D1.W)
	ADDQ.B	#1,(PSGWaveIdx.L,D1.W)
	AND.B	#$1F,(PSGWaveIdx.L,D1.W)
	LSL.W	#5,D1
	ADD.W	D2,D1
	MOVE.B	D0,(PSGWave.L,D1.W)
	MOVE.L	(SP)+,D2
	RTS

; Vblank: rebuild changed waves, then set the 4 Paula voices. A6 = $DFF000.
PSGUpdate:
	MOVEQ	#0,D7
.dirty:	LEA	PSGWaveDirty,A0
	TST.B	(A0,D7.W)
	BEQ.S	.clean
	SF	(A0,D7.W)
	BSR	PSGBuildWave
.clean:	ADDQ.W	#1,D7
	CMP.W	#6,D7
	BNE.S	.dirty

	IFEQ	NO_PSG6
	BSR	PSGAllocate		; which 4 of the 6 channels get a Paula voice
	MOVEQ	#0,D7
.voice:	MOVEQ	#0,D6
	MOVE.B	(PSGVoiceOwner.L,D7.W),D6
	IFEQ	NO_PSGDDA
	BSR	PSGDdaCheckStop
	TST.B	D6
	ENDC
	BMI.S	.free
	BSR	PSGVoiceTone
	BRA.S	.next
.free:	MOVE.W	D7,D0
	LSL.W	#4,D0
	CLR.W	$A8(A6,D0.W)		; AUDxVOL
	IFNE	PSGLog
	MOVEQ	#0,D1
	BSR	PSGShadowVol
	ENDC
.next:	ADDQ.W	#1,D7
	CMP.W	#4,D7
	BNE.S	.voice
	RTS
	ELSE
	MOVEQ	#0,D7			; Paula voice = PSG channel 0-3
.voice:	MOVE.W	D7,D6
	BSR	PSGVoiceTone
	ADDQ.W	#1,D7
	CMP.W	#4,D7
	BNE.S	.voice
	RTS
	ENDC

	IFEQ	NO_PSG6
; Six PSG channels, four Paula voices. Each vblank every channel gets a
; score = its Paula volume (0 when off, muted or not playable), plus 6 when
; it already has a voice (so near-equal channels do not swap voices every
; frame). The 4 best channels with a score keep or get a voice; a new one
; takes a free voice on its side (Paula voices 0/3 left, 1/2 right) when
; its balance leans one way. Uses D0-D6/A0-A2.
PSGAllocate:
	MOVEQ	#0,D6
.score:	BSR	PSGChScore
	IFEQ	NO_PSGBASS
	BSR	PSGBassUp
	ENDC
	MOVE.W	D1,(PSGScore.L,D6.W*2)
	MOVE.B	D2,(PSGPan.L,D6.W)
	ADDQ.W	#1,D6
	CMP.W	#6,D6
	BNE.S	.score
	MOVEQ	#3,D0			; voice owners get the bonus
.bonus:	MOVEQ	#0,D1
	MOVE.B	(PSGVoiceOwner.L,D0.W),D1
	BMI.S	.nob
	TST.W	(PSGScore.L,D1.W*2)
	BEQ.S	.nob
	IFEQ	NO_PSGSTICK
	ADD.W	#20,(PSGScore.L,D1.W*2)	; sticky: fewer speaker changes
	ELSE
	ADDQ.W	#6,(PSGScore.L,D1.W*2)
	ENDC
.nob:	DBF	D0,.bonus
	MOVEQ	#0,D6			; rank: channels ahead of this one
.rank:	MOVE.W	(PSGScore.L,D6.W*2),D1
	SF	(PSGPick.L,D6.W)
	TST.W	D1
	BEQ.S	.nextr
	MOVEQ	#0,D2			; count
	MOVEQ	#0,D3			; j
.cmp:	MOVE.W	(PSGScore.L,D3.W*2),D4
	CMP.W	D1,D4
	BHI.S	.ahead
	BNE.S	.notah
	CMP.W	D6,D3
	BCC.S	.notah
.ahead:	ADDQ.W	#1,D2
.notah:	ADDQ.W	#1,D3
	CMP.W	#6,D3
	BNE.S	.cmp
	CMP.W	#4,D2
	SCS	(PSGPick.L,D6.W)
.nextr:	ADDQ.W	#1,D6
	CMP.W	#6,D6
	BNE.S	.rank
	MOVEQ	#3,D0			; voices whose channel lost its place are freed
.drop:	MOVEQ	#0,D1
	MOVE.B	(PSGVoiceOwner.L,D0.W),D1
	BMI.S	.nod
	TST.B	(PSGPick.L,D1.W)
	BNE.S	.keep
	ST	(PSGVoiceOwner.L,D0.W)
	BRA.S	.nod
.keep:	SF	(PSGPick.L,D1.W)	; placed already
.nod:	DBF	D0,.drop
	MOVEQ	#0,D6			; new channels into free voices
.place:	TST.B	(PSGPick.L,D6.W)
	BEQ.S	.nextp
	LEA	PSGSideC(PC),A0
	MOVE.B	(PSGPan.L,D6.W),D0
	BEQ.S	.try
	LEA	PSGSideL(PC),A0
	BMI.S	.try
	LEA	PSGSideR(PC),A0
.try:	MOVEQ	#4-1,D2
.tryv:	MOVEQ	#0,D1
	MOVE.B	(A0)+,D1
	TST.B	(PSGVoiceOwner.L,D1.W)
	BPL.S	.used
	MOVE.B	D6,(PSGVoiceOwner.L,D1.W)
	BRA.S	.nextp
.used:	DBF	D2,.tryv
.nextp:	ADDQ.W	#1,D6
	CMP.W	#6,D6
	BNE.S	.place
	RTS

	IFEQ	NO_PSGBASS
; A0 = channel registers, D6 = channel, D1.w = score: a tone at F >= $300 goes up 20.
PSGBassUp:
	TST.W	D1
	BEQ.S	.x
	BTST	#6,4(A0)		; not DDA
	BNE.S	.x
	CMP.W	#4,D6
	BCS.S	.t
	TST.B	7(A0)			; not noise
	BMI.S	.x
.t:	MOVE.B	3(A0),D0
	AND.B	#$0F,D0
	CMP.B	#3,D0
	BCS.S	.x
	ADD.W	#20,D1
.x:	RTS
	ENDC

; D6 = channel -> D1.w = score (Paula volume, 0 = nothing to play),
; D2.b = balance lean (-1 left, 0 centre, 1 right). A0 = channel registers.
PSGChScore:
	LEA	PSGBuffer,A0
	MOVE.W	D6,D0
	LSL.W	#3,D0
	ADD.W	D0,A0
	MOVEQ	#0,D1
	MOVEQ	#0,D2
	IFEQ	NO_PSGDDA|NO_DDAQUEUE
	BSR	PSGDdaBusy
	BEQ.S	.nobusy
	MOVEQ	#100,D1			; a DDA stream with samples to play: above any tone
	BRA.S	.lean
.nobusy:
	ENDC
	MOVE.B	4(A0),D0
	BPL.S	.done			; off
	BTST	#6,D0
	IFEQ	NO_PSGDDA
	BEQ.S	.notdda
	TST.B	(PSGDdaLive.L,D6.W)
	BNE.S	.freq			; streaming DDA: volume and balance as a tone
	BRA.S	.done
.notdda:
	ELSE
	BNE.S	.done			; DDA (not played yet)
	ENDC
	CMP.W	#4,D6
	BCS.S	.tone
	TST.B	7(A0)
	IFEQ	NO_PSGNOISE
	BMI.S	.freq			; noise: any frequency
	ELSE
	BMI.S	.done			; noise (not played yet)
	ENDC
.tone:	CMP.W	#1,D6
	BNE.S	.nolfo
	MOVE.B	PSGLfo+1,D0
	AND.B	#$03,D0
	BNE.S	.done			; LFO on: channel 1 only modulates channel 0
.nolfo:	MOVE.B	3(A0),D0
	AND.B	#$0F,D0
	BNE.S	.freq
	MOVE.B	2(A0),D0
	BEQ.S	.freq			; 0 = 4096
	CMP.B	#8,D0
	BCS.S	.done			; above ~14 kHz
.freq:	MOVEM.L	D3-D5,-(SP)
	BSR	PSGAtten
	MOVEM.L	(SP)+,D3-D5
	IFEQ	NO_PSGDDA|NO_DDAQUEUE
.lean:
	ENDC
	MOVEQ	#0,D2
	MOVE.B	5(A0),D0
	MOVE.B	D0,D3
	LSR.B	#4,D3			; left
	AND.B	#$0F,D0			; right
	CMP.B	D0,D3
	BEQ.S	.done
	SHI	D2			; left louder: -1
	BHI.S	.done
	MOVEQ	#1,D2
.done:	RTS

PSGSideC:	DC.B	0,1,2,3
PSGSideL:	DC.B	0,3,1,2
PSGSideR:	DC.B	1,2,0,3
PSGVoiceOwner:	DC.B	-1,-1,-1,-1	; PSG channel per Paula voice, -1 = free
PSGScore:	DS.W	6
PSGPan:		DS.B	6
PSGPick:	DS.B	6
	EVEN
	ENDC

; D7 = channel: PSGWave (5-bit) -> PSGChip + ch*64: 32 signed bytes, then
; 16, 8, 4 and 2 (each pair averaged) at offsets 32, 48, 56, 60.
PSGBuildWave:
	LEA	PSGWave,A1
	MOVE.W	D7,D0
	LSL.W	#5,D0
	ADD.W	D0,A1
	LEA	PSGChip,A2
	MOVE.W	D7,D0
	LSL.W	#6,D0
	ADD.W	D0,A2
	MOVE.L	A2,A0
	MOVEQ	#32-1,D0
.l0:	MOVE.B	(A1)+,D1
	SUB.B	#16,D1
	LSL.B	#3,D1			; (v - 16) * 8: -128..120
	MOVE.B	D1,(A0)+
	DBF	D0,.l0
	MOVEQ	#16,D2			; A2 = previous level, A0 = next level
.lev:	MOVE.W	D2,D0
	SUBQ.W	#1,D0
.l1:	MOVE.B	(A2)+,D1
	EXT.W	D1
	MOVE.B	(A2)+,D3
	EXT.W	D3
	ADD.W	D3,D1
	ASR.W	#1,D1
	MOVE.B	D1,(A0)+
	DBF	D0,.l1
	LSR.W	#1,D2
	CMP.W	#2,D2
	BCC.S	.lev
	RTS

; A0 = channel registers (PSGBuffer + ch*8) -> D1.w = Paula volume 0-64.
; Uses D0-D5.
PSGAtten:
	MOVEQ	#31,D0
	MOVE.B	4(A0),D1
	AND.W	#$001F,D1
	SUB.W	D1,D0			; 31 - volume
	MOVE.B	5(A0),D1		; balance L<<4 | R
	MOVE.B	PSGMaster,D2		; master L<<4 | R
	MOVEQ	#0,D3
	MOVE.B	D1,D3
	LSR.B	#4,D3
	MOVEQ	#0,D4
	MOVE.B	D2,D4
	LSR.B	#4,D4
	ADD.W	D4,D3			; left: balance + master
	MOVEQ	#$0F,D4
	AND.B	D1,D4
	MOVEQ	#$0F,D5
	AND.B	D2,D5
	ADD.W	D5,D4			; right
	CMP.W	D3,D4
	BLS.S	.max
	MOVE.W	D4,D3
.max:	ADD.W	D3,D3
	NEG.W	D3
	ADD.W	#60,D3			; 2*(15-b) + 2*(15-m)
	ADD.W	D0,D3
	MOVEQ	#0,D1
	CMP.W	#32,D3
	BCC.S	.zero
	MOVE.B	(PSGVolTab.W,PC,D3.W),D1
.zero:	RTS

; D6 = PSG channel, D7 = Paula voice: tone from the channel's wave.
PSGVoiceTone:
	LEA	$A0(A6),A1
	MOVE.W	D7,D0
	LSL.W	#4,D0
	ADD.W	D0,A1			; A1 = AUDx registers
	LEA	PSGBuffer,A0
	MOVE.W	D6,D0
	LSL.W	#3,D0
	ADD.W	D0,A0			; A0 = channel registers
	IFEQ	NO_PSGDDA|NO_DDAQUEUE
	BSR	PSGDdaBusy
	BNE	PSGVoiceDda		; volume and period come with each buffer
	ENDC
	MOVE.B	4(A0),D0
	BPL	.mute			; channel off
	BTST	#6,D0
	IFEQ	NO_PSGDDA
	BEQ.S	.notdda
	IFEQ	NO_DDAQUEUE
	BRA	.mute			; DDA with nothing to play
	ELSE
	BSR	PSGAtten
	BRA	PSGVoiceDda
	ENDC
.notdda:
	ELSE
	BNE	.mute			; DDA (not played yet)
	ENDC
	BSR	PSGAtten
	TST.W	D1
	BEQ	.mute
	IFEQ	NO_PSGNOISE
	CMP.W	#4,D6
	BCS.S	.tonech
	TST.B	7(A0)
	BMI	PSGVoiceNoise
.tonech:
	ENDC
	MOVEQ	#0,D2
	MOVE.B	3(A0),D2
	AND.B	#$0F,D2
	LSL.W	#8,D2
	MOVE.B	2(A0),D2
	TST.W	D2
	BNE.S	.f
	MOVE.W	#$1000,D2
.f:	MOVEQ	#0,D3			; D3 = wave level (samples 32 >> D3)
	CMP.W	#126,D2
	BCC.S	.lv
	MOVEQ	#1,D3
	CMP.W	#63,D2
	BCC.S	.lv
	MOVEQ	#2,D3
	CMP.W	#32,D2
	BCC.S	.lv
	MOVEQ	#3,D3
	CMP.W	#16,D2
	BCC.S	.lv
	MOVEQ	#4,D3
	CMP.W	#8,D2
	BCS.S	.mute			; above ~14 kHz
.lv:	LSL.W	D3,D2
	MULU.W	#64935,D2		; * 3546895 / 3579545 (65536ths)
	SWAP	D2
	CMP.W	#124,D2
	BCC.S	.p
	MOVE.W	#124,D2
.p:	LEA	PSGChip,A2
	MOVE.W	D6,D0
	LSL.W	#6,D0
	ADD.W	(PSGLevOff.W,PC,D3.W*2),D0
	ADD.W	D0,A2
	MOVE.L	A2,(A1)			; AUDxLC (taken at the end of the current loop)
	MOVE.W	(PSGLevLen.W,PC,D3.W*2),4(A1)	; AUDxLEN
	MOVE.W	D2,6(A1)		; AUDxPER
	MOVE.W	D1,8(A1)		; AUDxVOL
	IFNE	PSGLog
	MOVE.W	(PSGLevLen.W,PC,D3.W*2),D4
	BSR	PSGShadowSet
	ENDC
	RTS
.mute:	CLR.W	8(A1)
	IFNE	PSGLog
	MOVEQ	#0,D1
	BSR	PSGShadowVol
	ENDC
	RTS

	IFEQ	NO_PSGNOISE
; Noise ($0807 bit 7, channels 4/5): the PSG steps its LFSR every
; (31 - NF) * 64 clocks at 3.58 MHz (NF = 31: 32 clocks), Mesen's rate.
; Paula plays PSGNoise at that rate (minimum period 124 = 28.6 kHz, so
; NF 30/31 sound alike), one vblank's worth of samples from a new offset
; each vblank: no short loop to hear, and the voice is free again within
; a frame. A0 = channel registers, A1 = AUDx, D1 = volume.
PSGVoiceNoise:
	MOVEQ	#$1F,D2
	AND.B	7(A0),D2
	EOR.B	#$1F,D2
	LSL.W	#6,D2
	BNE.S	.per
	MOVEQ	#32,D2
.per:	MULU.W	#64935,D2
	SWAP	D2
	CMP.W	#124,D2
	BCC.S	.p
	MOVE.W	#124,D2
.p:	MOVE.L	#35526,D3		; words for one PAL frame (71051 colour clocks / 2)
	DIVU.W	D2,D3
	ADDQ.W	#1,D3
	MOVE.W	PSGNoiseOfs,D0
	ADD.W	#4422,D0
	AND.W	#$1FFE,D0
	MOVE.W	D0,PSGNoiseOfs
	LEA	PSGNoise,A2
	ADD.W	D0,A2
	MOVE.L	A2,(A1)
	MOVE.W	D3,4(A1)
	MOVE.W	D2,6(A1)
	MOVE.W	D1,8(A1)
	IFNE	PSGLog
	MOVE.W	D3,D4
	BSR	PSGShadowSet
	ENDC
	RTS

; Fill PSGNoise with +120/-128 from a 32-bit Galois LFSR.
PSGMakeNoise:
	LEA	PSGNoise,A0
	MOVE.W	#8192+1024-1,D0
	MOVE.L	#$ACE1ACE1,D1
.l:	LSR.L	#1,D1
	BCC.S	.z
	EOR.L	#$80200003,D1
	MOVE.B	#$78,(A0)+
	DBF	D0,.l
	RTS
.z:	MOVE.B	#$80,(A0)+
	DBF	D0,.l
	RTS
PSGNoiseOfs:	DC.W	0
	ENDC

	IFEQ	NO_PSGDDA
; DDA: with $0804 bit 6 on, each $0806 write is the channel's output
; (5 bits); games stream samples that way, mostly from the timer IRQ
; (Parodius: ~58 writes a frame on channel 3). PSGWrite stores each
; sample at its scanline in PSGDdaLine; PSGDdaFrame turns the frame into
; one buffer of 264 (or 262) signed bytes, one per scanline, holding the
; last value between writes, and queues it (8 per channel). The Paula
; voice plays the queue at PSGDdaPer: 270 on a PAL screen (264 x 270 =
; one 50 Hz frame, so the stream keeps up with the emulation, which is at
; most one PCE frame per Amiga frame; the samples sound 5/6 low, like the
; tempo), 227 on an NTSC screen (the PCE rate within 1%). Paula's audio
; interrupt (level 4, PSGAudInt) fires when a voice starts a buffer and
; queues the next; with no buffer waiting it queues the channel's hold
; buffer (its last level, silent) and waits for 2 before starting again.
; A queue 3 deep gets a 262-sample buffer, so it drains at the same rate
; it fills. Latency 1-3 frames. Below full speed (NO_DDASTRETCH=0) each
; buffer is played up to 1.5x slower, by the smoothed number of Amiga
; frames per PCE frame, so the stream stays continuous (lower, like the
; tempo) instead of breaking up; slower than that it has gaps.
; Per sample on the 68k: one store in
; PSGWrite and one pass of the frame loop.

; InitPSG (OS frozen, after CongelaAMIGA): level 4 vector, period.
PSGDdaInit:
	MOVE.W	#$0780,$9A(A6)		; audio interrupts off until a voice streams
	MOVE.W	#$0780,$9C(A6)
	MOVE.L	VBRPun,A0
	MOVE.L	$70(A0),PSGOldL4
	MOVE.L	#PSGAudInt,$70(A0)
	MOVE.L	#-1,PSGVoiceDdaCh
	IFEQ	DdaTickOff
	IFEQ	NO_DDAPER
	MOVE.W	#609,PSGTkPer		; PAL screen: 313 x 227 / 116.9 ticks = 607.8; 0.2% long
	ELSE
	MOVE.W	#610,PSGTkPer		; PAL screen: 313 x 227.5 / 116.9 ticks = 609.3
	ENDC
	ENDC
	MOVE.W	#270,PSGDdaPer		; PAL screen: 264 x 270 = 71280, 262 x 270 = 70740 (frame 71051)
	TST.B	DirPrefs+$0F
	BEQ.S	.pal
	MOVE.W	#227,PSGDdaPer		; NTSC screen: 59928 / 59474 (frame ~59605)
	IFEQ	DdaTickOff
	MOVE.W	#513,PSGTkPer		; 512 per tick = a 263-line frame per 116.9 ticks; 0.2% long
	ENDC
.pal:	RTS

; New game: empty queues, no lines written, hold level = mid.
PSGDdaReset:
	LEA	PSGDdaLine,A0
	MOVE.W	#6*264/4-1,D0
.l:	MOVE.L	#-1,(A0)+
	DBF	D0,.l
	IFEQ	DdaTickOff
	LEA	PSGTkBuf,A0
	MOVE.W	#6*256/4-1,D0
.t:	MOVE.L	#-1,(A0)+
	DBF	D0,.t
	LEA	PSGTkLast,A0
	MOVEQ	#6-1,D0
.t2:	MOVE.W	#-1,(A0)+
	DBF	D0,.t2
	CLR.L	PSGTkN
	CLR.L	PSGTkN+4
	CLR.L	PSGTkN+8
	CLR.L	PSGTkDup
	CLR.L	PSGTkDup+4
	CLR.L	PSGTkHasC
	CLR.L	PSGTkHasC+4
	MOVE.L	#$10101010,PSGTkPrev
	MOVE.L	#$10101010,PSGTkPrev+4
	ENDC
	LEA	PSGDdaHoldBuf,A0
	MOVE.W	#6*264/4-1,D0
.h:	CLR.L	(A0)+
	DBF	D0,.h
	MOVE.L	#$10101010,PSGDdaHold
	MOVE.L	#$10101010,PSGDdaHold+4
	CLR.L	PSGDdaHad
	CLR.L	PSGDdaHad+4
	CLR.L	PSGDdaLive
	CLR.L	PSGDdaLive+4
	CLR.L	PSGRingRd
	CLR.L	PSGRingRd+4
	CLR.L	PSGRingWr
	CLR.L	PSGRingWr+4
	CLR.L	PSGPrimed
	CLR.L	PSGPrimed+4
	RTS

; PSGUpdate voice loop: D7 = voice, D6 = its owner channel ($FF = none).
; A voice that streamed DDA and no longer does (owner changed, DDA off,
; samples stopped) gets its audio interrupt switched off. Uses D0/A0.
PSGDdaCheckStop:
	IFEQ	NO_DDAQUEUE
	MOVEQ	#0,D0
	MOVE.B	(PSGVoiceDdaCh.L,D7.W),D0
	BMI	.ret
	CMP.B	D0,D6
	BNE.S	.lost
	BSR	PSGDdaBusy		; streams until its queue has played out
	BNE	.ret
	BRA.S	.stop
.lost:
	IFNE	DdaStat
	MOVE.L	D1,-(SP)
	MOVE.B	(PSGRingWr.L,D0.W),D1
	CMP.B	(PSGRingRd.L,D0.W),D1
	BNE.S	.stl
	TST.B	(PSGPrimed.L,D0.W)
	BEQ.S	.stn
.stl:	ADDQ.L	#1,DdaStLost		; only if it still had samples to play
.stn:	MOVE.L	(SP)+,D1
	ENDC
	MOVE.B	(PSGRingWr.L,D0.W),(PSGRingRd.L,D0.W)	; lost its voice: drop its queue (no stale start later)
	SF	(PSGPrimed.L,D0.W)
	BRA.S	.stop
	ENDC
	MOVE.B	(PSGVoiceDdaCh.L,D7.W),D0
	BMI.S	.ret
	CMP.B	D0,D6
	BNE.S	.stop
	LEA	PSGBuffer,A0
	MOVE.W	D6,D0
	LSL.W	#3,D0
	BTST	#6,4(A0,D0.W)
	BEQ.S	.stop
	TST.B	(PSGDdaLive.L,D6.W)
	BNE.S	.ret
.stop:
	IFNE	DdaDump
	MOVEM.L	D6,-(SP)
	MOVE.B	(PSGVoiceDdaCh.L,D7.W),D6
	MOVE.L	#'X'<<24,D0
	BSR	DdaDumpVC
	MOVEM.L	(SP)+,D6
	ENDC
	MOVE.W	(PSGAudBit.W,PC,D7.W*2),D0
	MOVE.W	D0,$9A(A6)
	MOVE.W	D0,$9C(A6)
	ST	(PSGVoiceDdaCh.L,D7.W)
.ret:	RTS

; A0 = channel registers, A1 = AUDx, D1 = volume, D6 = channel, D7 = voice.
PSGVoiceDda:
	IFNE	NO_DDASTRETCH
	MOVE.W	PSGDdaPer,6(A1)
	ENDC
	IFEQ	NO_DDAQUEUE
	MOVEQ	#0,D1
	MOVE.B	(PSGVoiceDdaCh.L,D7.W),D0
	CMP.B	D0,D6
	BNE.S	.vnew
	MOVE.W	(PSGVoiceCurVol.L,D7.W*2),D1	; for the log: the volume Paula has now
	BRA.S	.vok
.vnew:	CLR.W	8(A1)			; start: silent hold buffer, the first sample buffer brings its volume
	CLR.W	(PSGVoiceNextVol.L,D7.W*2)
	CLR.W	(PSGVoiceCurVol.L,D7.W*2)
	MOVE.B	(PSGRingWr.L,D6.W),D0	; more than 2 waiting (no voice for a while): keep the newest 2
	MOVE.B	D0,D1
	SUB.B	(PSGRingRd.L,D6.W),D1
	AND.B	#7,D1
	CMP.B	#2,D1
	BLS.S	.vfew
	SUBQ.B	#2,D0
	AND.B	#7,D0
	MOVE.B	D0,(PSGRingRd.L,D6.W)
.vfew:	MOVEQ	#0,D1
.vok:
	ELSE
	MOVE.W	D1,8(A1)
	ENDC
	IFNE	DdaDump
	CMP.B	(DdaDumpVol.L,D7.W),D1
	BEQ.S	.dvs
	MOVE.B	D1,(DdaDumpVol.L,D7.W)
	MOVE.L	#'V'<<24,D0
	MOVE.B	D1,D0
	BSR	DdaDumpVC
.dvs:
	ENDC
	IFNE	PSGLog
	MOVE.W	D6,D0
	MULU.W	#8*264,D0
	ADD.L	#PSGDdaRing,D0
	MOVE.L	D0,A2
	MOVEQ	#0,D4
	MOVE.W	PSGDdaPer,D2
	BSR	PSGShadowSet
	ENDC
	CMP.B	(PSGVoiceDdaCh.L,D7.W),D6
	BEQ.S	.on
	IFNE	DdaDump
	MOVE.L	#'A'<<24,D0
	BSR	DdaDumpVC
	ENDC
	IFNE	DdaStat
	ADDQ.L	#1,DdaStStarts
	ENDC
	MOVE.B	D6,(PSGVoiceDdaCh.L,D7.W)	; start: hold buffer next, then the queue
	IFEQ	NO_DDASTRETCH
	MOVE.W	PSGDdaPer,6(A1)
	MOVE.W	PSGDdaPer,(PSGVoiceNextPer.L,D7.W*2)
	ENDC
	SF	(PSGPrimed.L,D6.W)
	MOVE.W	D6,D0
	MULU.W	#264,D0
	ADD.L	#PSGDdaHoldBuf,D0
	MOVE.L	D0,(A1)
	MOVE.W	#264/2,4(A1)
	MOVE.W	(PSGAudBit.W,PC,D7.W*2),D0
	MOVE.W	D0,$9C(A6)
	OR.W	#$8000,D0
	MOVE.W	D0,$9A(A6)
.on:	RTS

PSGAudBit:	DC.W	$0080,$0100,$0200,$0400

; Level 4: Paula has started the buffer queued last time on a streaming
; voice; queue the next one. No OS calls.
	CNOP	0,4
PSGAudInt:
	MOVEM.L	D0-D4/A0-A1,-(SP)
	LEA	$DFF000,A0
	MOVE.W	$1E(A0),D0		; INTREQR
	AND.W	$1C(A0),D0		; INTENAR
	AND.W	#$0780,D0
	MOVE.W	D0,$9C(A0)
	MOVE.W	D0,$9C(A0)
	LSR.W	#7,D0
	MOVEQ	#0,D1
.v:	LSR.W	#1,D0
	BCC.S	.n
	BSR.S	PSGServe
.n:	ADDQ.W	#1,D1
	TST.W	D0
	BNE.S	.v
	MOVEM.L	(SP)+,D0-D4/A0-A1
	RTE

PSGServeLong	SET	DdaDump|DdaStat	; long branches in PSGServe when it grew
	IFEQ	NO_DDAQUEUE
PSGServeLong	SET	1
	ENDC
; D1 = voice, A0 = $DFF000. Uses D2-D4/A1.
PSGServe:
	MOVEQ	#0,D2
	MOVE.B	(PSGVoiceDdaCh.L,D1.W),D2
	IFEQ	NO_DDASTRETCH&NO_DDAQUEUE
	BMI	.ret
	ELSE
	BMI.S	.ret
	ENDC
	LEA	$A0(A0),A1
	MOVE.W	D1,D3
	LSL.W	#4,D3
	ADD.W	D3,A1
	IFEQ	NO_DDASTRETCH
	MOVE.W	(PSGVoiceNextPer.L,D1.W*2),6(A1)	; the buffer starting now
	ENDC
	IFEQ	NO_DDAQUEUE
	MOVE.W	(PSGVoiceNextVol.L,D1.W*2),D3
	MOVE.W	D3,8(A1)
	MOVE.W	D3,(PSGVoiceCurVol.L,D1.W*2)
	ENDC
	MOVE.B	(PSGRingWr.L,D2.W),D3
	SUB.B	(PSGRingRd.L,D2.W),D3
	AND.W	#7,D3			; buffers waiting
	IFNE	PSGServeLong
	BEQ	.under
	ELSE
	BEQ.S	.under
	ENDC
	TST.B	(PSGPrimed.L,D2.W)
	BNE.S	.take
	CMP.W	#2,D3
	IFNE	PSGServeLong
	BCS	.hold
	ELSE
	BCS.S	.hold
	ENDC
	ST	(PSGPrimed.L,D2.W)
.take:
	IFNE	DdaStat
	CMP.B	DdaStQMin,D3
	BCC.S	.st1
	MOVE.B	D3,DdaStQMin
.st1:	CMP.B	DdaStQMax,D3
	BLS.S	.st2
	MOVE.B	D3,DdaStQMax
.st2:
	ENDC
	IFEQ	NO_DDAQUEUE
	CMP.W	#4,D3
	BCS.S	.tk
	ADDQ.B	#1,(PSGRingRd.L,D2.W)	; 4 or more waiting: drop the oldest (latency at most ~4 frames)
	AND.B	#7,(PSGRingRd.L,D2.W)
	ADDQ.W	#1,PSGDdaSkip
.tk:
	ENDC
	MOVEQ	#0,D3
	MOVE.B	(PSGRingRd.L,D2.W),D3
	MOVE.W	D2,D4
	LSL.W	#3,D4
	ADD.W	D3,D4
	MOVE.W	(PSGRingLen.L,D4.W*2),4(A1)
	IFNE	DdaStat
	MOVE.L	D0,-(SP)
	MOVEQ	#0,D0
	MOVE.W	(PSGRingLen.L,D4.W*2),D0
	ADD.L	D0,DdaStWords
	MOVE.L	(SP)+,D0
	ENDC
	IFEQ	NO_DDASTRETCH
	MOVE.W	(PSGRingPer.L,D4.W*2),(PSGVoiceNextPer.L,D1.W*2)
	ENDC
	IFEQ	NO_DDAQUEUE
	MOVE.W	(PSGRingVol.L,D4.W*2),(PSGVoiceNextVol.L,D1.W*2)
	ENDC
	MULU.W	#264,D4
	ADD.L	#PSGDdaRing,D4
	MOVE.L	D4,(A1)
	IFNE	DdaDump
	MOVEM.L	D0-D2/A0,-(SP)
	SUB.L	A0,A0
	MOVE.L	#'S'<<8,D0
	MOVE.B	D1,D0
	SWAP	D0
	MOVE.B	D2,D0
	LSL.W	#8,D0
	MOVE.B	D3,D0
	IFEQ	NO_DDASTRETCH
	MOVE.W	(PSGVoiceNextPer.L,D1.W*2),D1
	ELSE
	MOVE.W	PSGDdaPer,D1
	ENDC
	MOVEQ	#0,D2
	BSR	DdaDumpRec
	MOVEM.L	(SP)+,D0-D2/A0
	ENDC
	ADDQ.B	#1,D3
	AND.B	#7,D3
	MOVE.B	D3,(PSGRingRd.L,D2.W)
.ret:	RTS
.under:	TST.B	(PSGPrimed.L,D2.W)
	BEQ.S	.hold
	SF	(PSGPrimed.L,D2.W)
	ADDQ.W	#1,PSGDdaUnder		; a gap in a running stream
	IFNE	DdaDump
	MOVEM.L	D0-D2/A0,-(SP)
	SUB.L	A0,A0
	MOVE.L	#'U'<<8,D0
	MOVE.B	D1,D0
	SWAP	D0
	MOVE.B	D2,D0
	LSL.W	#8,D0
	MOVEQ	#0,D1
	MOVEQ	#0,D2
	BSR	DdaDumpRec
	MOVEM.L	(SP)+,D0-D2/A0
	ENDC
.hold:
	IFNE	DdaStat
	ADDQ.L	#1,DdaStHolds
	ENDC
	IFNE	DdaDump
	MOVEM.L	D0-D2/A0,-(SP)
	SUB.L	A0,A0
	MOVE.L	#'H'<<8,D0
	MOVE.B	D1,D0
	SWAP	D0
	MOVE.B	D2,D0
	LSL.W	#8,D0
	MOVE.B	(PSGDdaHold.L,D2.W),D0
	MOVE.W	PSGDdaPer,D1
	MOVEQ	#0,D2
	BSR	DdaDumpRec
	MOVEM.L	(SP)+,D0-D2/A0
	ENDC
	IFEQ	NO_DDASTRETCH
	MOVE.W	PSGDdaPer,(PSGVoiceNextPer.L,D1.W*2)
	ENDC
	MULU.W	#264,D2
	ADD.L	#PSGDdaHoldBuf,D2
	MOVE.L	D2,(A1)
	MOVE.W	#264/2,4(A1)
	RTS

; Once per PCE frame (main loop, after PCE_Start; keeps all registers).
PSGDdaFrame:
	MOVEM.L	D0-D6/A0-A1,-(SP)
	IFEQ	NO_DDASTRETCH
	MOVE.L	vTimerVBlanks,D0	; Amiga frames since the last PCE frame (1 at full rate)
	MOVE.L	D0,D1
	SUB.L	PSGLastVbl,D1
	MOVE.L	D0,PSGLastVbl
	CMP.L	#4,D1
	BLS.S	.d4
	MOVEQ	#4,D1
.d4:	TST.L	D1
	BNE.S	.d1
	MOVEQ	#1,D1
.d1:	LSL.W	#8,D1
	MOVE.W	PSGDdaRate,D0		; rate += (frames*256 - rate) / 4
	SUB.W	D0,D1
	ASR.W	#2,D1
	ADD.W	D1,D0
	MOVE.W	D0,PSGDdaRate
	CMP.W	#256,D0
	BCC.S	.rmin
	MOVE.W	#256,D0
.rmin:	CMP.W	#384,D0			; at most 1.5x longer, then gaps
	BLS.S	.rmax
	MOVE.W	#384,D0
.rmax:
	IFEQ	DdaTickOff
	MOVE.W	D0,PSGDdaRateNow
	ENDC
	MULU.W	PSGDdaPer,D0
	LSR.L	#8,D0
	MOVE.W	D0,PSGDdaPerNow
	ENDC
	MOVEQ	#0,D6
.ch:	TST.B	(PSGDdaHad.L,D6.W)
	BNE.S	.had
	IFEQ	DdaTickOff
	SF	(PSGTkHasC.L,D6.W)
	ENDC
	TST.B	(PSGDdaLive.L,D6.W)
	BEQ	.next
	SUBQ.B	#1,(PSGDdaLive.L,D6.W)	; no samples: still "streaming" for 8 frames
	BRA	.next
.had:	SF	(PSGDdaHad.L,D6.W)
	MOVE.B	#8,(PSGDdaLive.L,D6.W)
	LEA	PSGDdaScratch,A1
	MOVEQ	#0,D5
	MOVE.B	(PSGRingWr.L,D6.W),D0
	MOVE.B	D0,D2
	SUB.B	(PSGRingRd.L,D6.W),D2
	AND.W	#7,D2			; buffers waiting
	CMP.W	#6,D2
	BCC.S	.fill			; full (Paula reads slots rd-1/rd-2): drop the frame
	AND.W	#7,D0
	MOVE.W	D6,D1
	LSL.W	#3,D1
	ADD.W	D0,D1			; ch*8 + slot
	MOVE.W	#264/2,D3
	CMP.W	#2,D2
	BCS.S	.len
	MOVE.W	#262/2,D3		; 3 or more waiting with this one: shorter, to drain
.len:	MOVE.W	D3,(PSGRingLen.L,D1.W*2)
	IFEQ	NO_DDAQUEUE
	BSR	PSGDdaVol
	MOVE.W	PSGDdaVolNow,(PSGRingVol.L,D1.W*2)
	ENDC
	IFEQ	NO_DDASTRETCH
	MOVE.W	PSGDdaPerNow,(PSGRingPer.L,D1.W*2)
	ENDC
	MULU.W	#264,D1
	LEA	PSGDdaRing,A1
	ADD.L	D1,A1
	MOVEQ	#1,D5
	IFEQ	DdaTickOff
	BSR	PSGTickCheck
	BEQ.S	.fill
	LEA	PSGDdaScratch,A1	; by tick: the line pass only clears and holds (no chip RAM)
	ENDC
.fill:	MOVE.W	D6,D1
	MULU.W	#264,D1
	LEA	PSGDdaLine,A0
	ADD.L	D1,A0
	MOVE.B	(PSGDdaHold.L,D6.W),D2	; level before the first write
	MOVE.W	#263-1,D1
.l:	MOVE.B	(A0),D4
	BMI.S	.keep			; $FF: no write on this line
	MOVE.B	D4,D2
	ST	(A0)
.keep:	ADDQ.L	#1,A0
	MOVE.B	D2,D4
	SUB.B	#16,D4
	LSL.B	#3,D4
	MOVE.B	D4,(A1)+
	DBF	D1,.l
	MOVE.B	D4,(A1)			; sample 264 = sample 263
	CMP.B	(PSGDdaHold.L,D6.W),D2
	BEQ.S	.same
	MOVE.B	D2,(PSGDdaHold.L,D6.W)
	BSR	PSGDdaHoldFill
.same:
	IFNE	DdaStat
	ADDQ.L	#1,DdaStQueued
	TST.W	D5
	BNE.S	.stq
	SUBQ.L	#1,DdaStQueued
	ADDQ.L	#1,DdaStDrop
.stq:
	ENDC
	IFEQ	DdaTickOff
	TST.W	D5
	BEQ.S	.tkc
	BSR	PSGTickFill		; one write per timer tick: the buffer by tick instead
.tkc:	BSR	PSGTickClear
	ENDC
	IFNE	DdaDump
	BSR	DdaDumpQ
	ENDC
	TST.W	D5
	BEQ.S	.next
	ADDQ.B	#1,D0
	AND.B	#7,D0
	MOVE.B	D0,(PSGRingWr.L,D6.W)	; publish after the buffer is written
.next:	ADDQ.W	#1,D6
	CMP.W	#6,D6
	BNE	.ch
	MOVEM.L	(SP)+,D0-D6/A0-A1
	RTS

	IFEQ	NO_DDAQUEUE
; D6 = channel -> NE if it has DDA samples to play: buffers waiting, its last
; buffer playing, or DDA on with samples in the last 8 frames. Uses D0.
PSGDdaBusy:
	MOVE.B	(PSGRingWr.L,D6.W),D0
	CMP.B	(PSGRingRd.L,D6.W),D0
	BNE.S	.yes
	TST.B	(PSGPrimed.L,D6.W)
	BNE.S	.yes
	TST.B	(PSGDdaLive.L,D6.W)
	BEQ.S	.no
	BTST	#6,(PSGBuffer+4.L,D6.W*8)
	BEQ.S	.no
.yes:	MOVEQ	#1,D0
	RTS
.no:	MOVEQ	#0,D0
	RTS

; D6 = channel -> PSGDdaVolNow = Paula volume of this frame's samples: the
; control byte at the last DDA write (0 if the channel was off), balances now.
PSGDdaVol:
	MOVEM.L	D0-D5/A0,-(SP)
	MOVEQ	#0,D1
	MOVE.B	(PSGDdaLastCtl.L,D6.W),D0
	BPL.S	.off
	MOVE.B	D0,PSGDdaTmp+4
	MOVE.B	(PSGBuffer+5.L,D6.W*8),PSGDdaTmp+5
	LEA	PSGDdaTmp,A0
	BSR	PSGAtten
.off:	MOVE.W	D1,PSGDdaVolNow
	MOVEM.L	(SP)+,D0-D5/A0
	RTS
PSGDdaTmp:	DS.B	8
PSGDdaLastCtl:	DS.B	8
PSGDdaVolNow:	DC.W	0
PSGDdaSkip:	DC.W	0
PSGRingVol:	DS.W	6*8		; Paula volume per queued buffer
PSGVoiceNextVol:	DS.W	4	; volume of the buffer each voice starts next
PSGVoiceCurVol:	DS.W	4
	ENDC

	IFEQ	DdaTickOff
; Timer-driven DDA (Parodius, Soldier Blade, SF2', Bonk, ...: one $0806 write
; per timer interrupt): PSGWrite also files each sample by timer tick (PSGTickPut). When
; every tick of the frame's span but at most 1/8 has a write and no tick has
; two, the queued buffer is the samples by tick (holding over a missed tick),
; played at PSGTkPer x (reload+1): the game's own sample spacing, instead of
; the scanline grid (where the IRQ, taken at a line end, lands up to a line
; off). An odd sample count leaves the last sample to start the next buffer.
; With 3 or more buffers waiting, 2 samples are left off (the queue drains).
; PSGTickCheck decides before the line pass (which then goes to the scratch
; buffer), PSGTickFill writes the slot. D6 = channel, D0 = ring slot. Keeps all.
PSGTickCheck:				; D6 = channel -> NE and PSGTkMode set if tick-driven. Keeps all.
	MOVEM.L	D1/D3/D4,-(SP)
	SF	PSGTkMode
	TST.B	TimerOn
	BEQ.S	.no
	TST.B	(PSGTkDup.L,D6.W)
	BNE.S	.no
	MOVE.W	(PSGTkLast.L,D6.W*2),D3
	BMI.S	.no
	ADDQ.W	#1,D3			; ticks spanned
	CMP.W	#2,D3
	BCS.S	.no
	MOVE.W	(PSGTkN.L,D6.W*2),D1
	LSL.W	#3,D1
	MOVE.W	D3,D4
	MULU.W	#7,D4
	CMP.W	D4,D1
	BCS.S	.no			; under 7/8 of the ticks written: not tick-driven
	ST	PSGTkMode
.no:	MOVEM.L	(SP)+,D1/D3/D4
	TST.B	PSGTkMode
	RTS

PSGTickFill:
	MOVEM.L	D0-D5/A0-A1,-(SP)
	TST.B	PSGTkMode
	BEQ	.no
	SF	PSGTkMode
	MOVE.W	(PSGTkLast.L,D6.W*2),D3
	ADDQ.W	#1,D3
	AND.W	#7,D0
	MOVE.W	D6,D5
	LSL.W	#3,D5
	ADD.W	D0,D5			; ch*8 + slot
	MOVE.W	D5,D1
	MULU.W	#264,D1
	LEA	PSGDdaRing,A1
	ADD.L	D1,A1
	MOVE.W	D6,D1
	LSL.W	#8,D1
	LEA	PSGTkBuf,A0
	ADD.W	D1,A0
	MOVEQ	#0,D4			; samples
	TST.B	(PSGTkHasC.L,D6.W)
	BEQ.S	.nc
	MOVE.B	(PSGTkCarry.L,D6.W),(A1)+
	MOVEQ	#1,D4
.nc:	MOVE.B	(PSGTkPrev.L,D6.W),D2	; level before the first write
	SUBQ.W	#1,D3
.l:	MOVE.B	(A0)+,D1
	BMI.S	.k			; no write on this tick
	MOVE.B	D1,D2
.k:	MOVE.B	D2,D1
	SUB.B	#16,D1
	LSL.B	#3,D1
	MOVE.B	D1,(A1)+
	ADDQ.W	#1,D4
	DBF	D3,.l
	SF	(PSGTkHasC.L,D6.W)
	BTST	#0,D4
	BEQ.S	.even
	SUBQ.W	#1,D4
	MOVE.B	-1(A1),(PSGTkCarry.L,D6.W)	; odd: the last sample starts the next buffer
	ST	(PSGTkHasC.L,D6.W)
.even:	MOVE.B	(PSGRingWr.L,D6.W),D1
	SUB.B	(PSGRingRd.L,D6.W),D1
	AND.B	#7,D1
	CMP.B	#2,D1
	BCS.S	.nt
	CMP.W	#6,D4
	BCS.S	.nt
	SUBQ.W	#2,D4			; 3 or more waiting with this one: 2 samples less
	IFNE	DdaStat
	ADDQ.L	#1,DdaStTrim
	ENDC
.nt:	LSR.W	#1,D4
	MOVE.W	D4,(PSGRingLen.L,D5.W*2)
	MOVEQ	#0,D1
	MOVE.B	TimerReload,D1
	ADDQ.W	#1,D1
	MULU.W	PSGTkPer,D1
	CMP.L	#$FFFF,D1
	BHI.S	.pmax
	MULU.W	PSGDdaRateNow,D1	; below full speed: longer, as the line buffers
	LSR.L	#8,D1
	CMP.L	#$FFFF,D1
	BLS.S	.p
.pmax:	MOVE.W	#$FFFF,D1
.p:	MOVE.W	D1,(PSGRingPer.L,D5.W*2)
	IFNE	DdaStat
	ADDQ.L	#1,DdaStTick
	ENDC
.no:	MOVE.B	(PSGDdaHold.L,D6.W),(PSGTkPrev.L,D6.W)	; this frame's last level
	MOVEM.L	(SP)+,D0-D5/A0-A1
	RTS

; PSGWrite, DDA sample: D0.b = level, D2.w = channel. File it at PSGTkBuf +
; ch*256 + timer ticks since the channel's first write this frame. Keeps all.
PSGTickPut:
	MOVE.L	D1,-(SP)
	MOVE.W	TimerTicks,D1
	TST.W	(PSGTkN.L,D2.W*2)
	BNE.S	.tp1
	MOVE.W	D1,(PSGTkFirst.L,D2.W*2)
.tp1:	SUB.W	(PSGTkFirst.L,D2.W*2),D1
	CMP.W	#256,D1
	BCC.S	.d
	CMP.W	(PSGTkLast.L,D2.W*2),D1
	BEQ.S	.d
	MOVE.W	D1,(PSGTkLast.L,D2.W*2)
	ADDQ.W	#1,(PSGTkN.L,D2.W*2)
	ROR.W	#8,D1
	MOVE.B	D2,D1
	ROR.W	#8,D1			; ch<<8 | tick
	MOVE.B	D0,(PSGTkBuf.L,D1.W)
	MOVE.L	(SP)+,D1
	RTS
.d:	ST	(PSGTkDup.L,D2.W)	; two writes in a tick (or 256+ ticks): this frame stays on the line grid
	MOVE.L	(SP)+,D1
	RTS

; D6 = channel: forget this frame's tick samples. Keeps all.
PSGTickClear:
	MOVEM.L	D1/A0,-(SP)
	MOVE.W	(PSGTkLast.L,D6.W*2),D1
	BMI.S	.z
	MOVE.W	D6,-(SP)
	LSL.W	#8,D6
	LEA	PSGTkBuf,A0
	ADD.W	D6,A0
	MOVE.W	(SP)+,D6
.c:	ST	(A0)+
	DBF	D1,.c
.z:	MOVE.W	#-1,(PSGTkLast.L,D6.W*2)
	CLR.W	(PSGTkN.L,D6.W*2)
	SF	(PSGTkDup.L,D6.W)
	MOVEM.L	(SP)+,D1/A0
	RTS
PSGTkPer:	DC.W	513
PSGTkMode:	DC.B	0,0
PSGDdaRateNow:	DC.W	256
PSGTkFirst:	DS.W	6
PSGTkLast:	DS.W	6
PSGTkN:		DS.W	6
PSGTkDup:	DS.B	8
PSGTkHasC:	DS.B	8
PSGTkCarry:	DS.B	8
PSGTkPrev:	DS.B	8
PSGTkBuf:	DS.B	6*256		; this frame's samples by timer tick, $FF = none
	EVEN
	ENDC

; D6 = channel, D4.b = signed level: fill its hold buffer. Uses D1/A0.
PSGDdaHoldFill:
	MOVE.W	D6,D1
	MULU.W	#264,D1
	LEA	PSGDdaHoldBuf,A0
	ADD.L	D1,A0
	MOVE.W	#264-1,D1
.f:	MOVE.B	D4,(A0)+
	DBF	D1,.f
	RTS

	IFNE	DdaDump
; Test builds: a record per DDA event into DdaDumpBuf (Main.asm, BSS), saved at
; AutoExit as PROGDIR:AmiPCE.dda. Record: type.b a.b b.b c.b, word, word 0,
; vblanks.l, VPOSR/VHPOSR.l, PCE frames.l (20 bytes), then 264 bytes for Q.
;   Q ch slot lenwords, period: a buffer queued (payload = its samples)
;   D ch: frame dropped (queue full), payload = its samples
;   A voice ch: voice starts streaming (hold buffer queued); V voice ch vol
;   X voice ch: voice stops streaming
;   S voice ch slot, period: interrupt queued ring slot (the previous one started)
;   H voice ch level, period: interrupt queued the hold buffer; U voice ch: underrun
; D0.l = type<<24|a<<16|b<<8|c, D1.w = word, D2.w = second word, A0 = payload or 0.
; Keeps all registers. Q: second word = the buffer's Paula volume (NO_DDAQUEUE=0) or -1.
DdaDumpRec:
	MOVEM.L	D0-D3/A0-A1,-(SP)
	MOVE.W	$DFF01C,D3		; INTENAR
	MOVE.W	#$4000,$DFF09A		; no interrupt between the pointer read and write
	MOVE.L	DdaDumpPtr,A1
	CMP.L	#DdaDumpEnd-20-264,A1
	BCC.S	.full
	MOVE.L	D0,(A1)+
	MOVE.W	D1,(A1)+
	MOVE.W	D2,(A1)+
	MOVE.L	vTimerVBlanks,(A1)+
	MOVE.L	$DFF004,(A1)+
	IFNE	AutoExit
	MOVE.L	AutoFrames,(A1)+
	ELSE
	CLR.L	(A1)+
	ENDC
	MOVE.L	A0,D0
	BEQ.S	.np
	MOVEQ	#264/4-1,D0
.cp:	MOVE.L	(A0)+,(A1)+
	DBF	D0,.cp
.np:	MOVE.L	A1,DdaDumpPtr
.full:	BTST	#14,D3
	BEQ.S	.x
	MOVE.W	#$C000,$DFF09A
.x:	MOVEM.L	(SP)+,D0-D3/A0-A1
	RTS
; D0 = type<<24 | c, D7 = voice, D6 = channel: record without payload.
DdaDumpVC:
	MOVEM.L	D0-D2/A0,-(SP)
	MOVE.L	D0,D1
	AND.L	#$FF0000FF,D1
	MOVEQ	#0,D0
	MOVE.B	D7,D0
	LSL.W	#8,D0
	MOVE.B	D6,D0
	LSL.L	#8,D0
	OR.L	D1,D0
	SUB.L	A0,A0
	MOVEQ	#0,D1
	MOVEQ	#0,D2
	BSR	DdaDumpRec
	MOVEM.L	(SP)+,D0-D2/A0
	RTS
; PSGDdaFrame, after the fill: D6 = channel, D5 = 1 queued (D0 = slot) or 0 dropped (scratch).
DdaDumpQ:
	MOVEM.L	D0-D2/A0,-(SP)
	AND.W	#7,D0
	LEA	PSGDdaScratch,A0
	TST.W	D5
	BEQ.S	.drop
	MOVE.W	D6,D1
	LSL.W	#3,D1
	ADD.W	D0,D1
	MOVE.W	(PSGRingLen.L,D1.W*2),D2
	IFEQ	NO_DDASTRETCH
	MOVE.W	(PSGRingPer.L,D1.W*2),DdaDumpPerT
	ENDC
	MULU.W	#264,D1
	LEA	PSGDdaRing,A0
	ADD.L	D1,A0
	MOVEQ	#0,D1
	MOVE.B	#'Q',D1
	LSL.W	#8,D1
	MOVE.B	D6,D1
	SWAP	D1
	MOVE.B	D0,D1
	LSL.W	#8,D1
	MOVE.B	D2,D1
	MOVE.L	D1,D0
	IFEQ	NO_DDASTRETCH
	MOVE.W	DdaDumpPerT,D1
	ELSE
	MOVE.W	PSGDdaPer,D1
	ENDC
	IFEQ	NO_DDAQUEUE
	MOVE.W	PSGDdaVolNow,D2
	ELSE
	MOVEQ	#-1,D2
	ENDC
	BRA.S	.rec
.drop:	MOVEQ	#-1,D2
	MOVEQ	#0,D0
	MOVE.B	#'D',D0
	LSL.W	#8,D0
	MOVE.B	D6,D0
	SWAP	D0
	MOVEQ	#0,D1
.rec:	BSR	DdaDumpRec
	MOVEM.L	(SP)+,D0-D2/A0
	RTS
DdaDumpPerT:	DC.W	0
DdaDumpPtr:	DC.L	DdaDumpBuf
DdaDumpVol:	DC.B	-1,-1,-1,-1
	ENDC
	IFNE	DdaStat
DdaStHolds:	DC.L	0
DdaStWords:	DC.L	0
DdaStStarts:	DC.L	0
DdaStLost:	DC.L	0
DdaStDrop:	DC.L	0
DdaStQueued:	DC.L	0
DdaStTick:	DC.L	0
DdaStTrim:	DC.L	0		; buffers trimmed by 2 samples (queue of 3 or more)
DdaStQMin:	DC.B	$FF
DdaStQMax:	DC.B	0
	EVEN
	ENDC
PSGOldL4:	DC.L	0
PSGDdaPer:	DC.W	270
PSGDdaUnder:	DC.W	0
PSGVoiceDdaCh:	DC.B	-1,-1,-1,-1	; channel a voice streams, -1 = none
PSGDdaHad:	DS.B	8		; DDA writes this frame
PSGDdaLive:	DS.B	8		; frames left counting as streaming
PSGDdaHold:	DS.B	8		; last 5-bit level
PSGRingRd:	DS.B	8
PSGRingWr:	DS.B	8
PSGPrimed:	DS.B	8
PSGRingLen:	DS.W	6*8
	IFEQ	NO_DDASTRETCH
PSGRingPer:	DS.W	6*8		; period per queued buffer
PSGVoiceNextPer:	DS.W	4		; period of the buffer each voice starts next
PSGLastVbl:	DC.L	0
PSGDdaRate:	DC.W	256		; Amiga frames per PCE frame, x256, smoothed
PSGDdaPerNow:	DC.W	270
	ENDC
PSGDdaLine:	DS.B	6*264		; this frame's samples by scanline, $FF = none
PSGDdaScratch:	DS.B	264
	EVEN
	ENDC

PSGLevOff:	DC.W	0,32,48,56,60
PSGLevLen:	DC.W	16,8,4,2,1
; Paula volume for 0-31 steps of 1.5 dB: round(64 * 10^(-1.5*i/20))
PSGVolTab:	DC.B	64,54,45,38,32,27,23,19,16,14,11,10,8,7,6,5
		DC.B	4,3,3,2,2,2,1,1,1,1,1,1,1,0,0,0

	IFNE	PSGLog
; One serial line per PCE frame, same format as tools/mesen_psg.lua:
; P:frame m:master l:lfo-ctl c<i>:ctl freq bal noise wavesum dda-writes
PSGLogFrame:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	TST.B	PSGLogInit
	BNE.S	PSGLog_inited
	ST	PSGLogInit
	MOVE.W	#3,$DFF032		; SERPER: fastest rate (WinUAE TCP serial)
PSGLog_inited:
	LogString "P:"
	IFNE	AutoExit
	MOVE.L	AutoFrames,D0
	ADDQ.L	#1,D0
	ELSE
	MOVE.L	FPS_Count,D0
	ENDC
	LogHexWord D0
	LogString " m:"
	LogHexByte PSGMaster
	LogString " l:"
	LogHexByte PSGLfo+1
	MOVEQ	#0,D7
PSGLog_ch:	LogString " c"
	MOVE.B	D7,D0
	ADD.B	#'0',D0
	MOVE.B	D0,PSGLogTxt
	LogText	#PSGLogTxt
	LEA	PSGBuffer,A0
	MOVE.W	D7,D0
	LSL.W	#3,D0
	ADD.W	D0,A0
	LogHexByte 4(A0)
	LogString " "
	MOVE.B	3(A0),D0
	AND.W	#$000F,D0
	LSL.W	#8,D0
	MOVE.B	2(A0),D0
	LogHexWord D0
	LogString " "
	LogHexByte 5(A0)
	LogString " "
	MOVEQ	#0,D0
	CMP.W	#4,D7
	BCS.S	PSGLog_nn
	MOVE.B	7(A0),D0
PSGLog_nn:	LogHexByte D0
	LogString " "
	LEA	PSGWave,A1
	MOVE.W	D7,D0
	LSL.W	#5,D0
	ADD.W	D0,A1
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVEQ	#32-1,D2
PSGLog_sum:	MOVE.B	(A1)+,D1
	ADD.W	D1,D0
	DBF	D2,PSGLog_sum
	LogHexWord D0
	LogString " "
	LEA	PSGDdaCnt,A1
	LogHexByte (A1,D7.W)
	CLR.B	(A1,D7.W)
	ADDQ.W	#1,D7
	CMP.W	#6,D7
	BNE	PSGLog_ch
	MOVEQ	#0,D7			; Paula voices: a<v>:owner LC-PSGChip LEN PER VOL
PSGLog_v:
	LogString " a"
	MOVE.B	D7,D0
	ADD.B	#'0',D0
	MOVE.B	D0,PSGLogTxt
	LogText	#PSGLogTxt
	MOVE.W	D7,D0
	LSL.W	#4,D0
	LEA	PSGShadow,A1
	ADD.W	D0,A1
	IFEQ	NO_PSG6
	LEA	PSGVoiceOwner,A0
	LogHexByte (A0,D7.W)
	ELSE
	LogHexByte D7
	ENDC
	LogString " "
	MOVE.L	(A1),D0
	SUB.L	#PSGChip,D0
	LogHexWord D0
	LogString " "
	LogHexWord 4(A1)
	LogString " "
	LogHexWord 6(A1)
	LogString " "
	LogHexByte 9(A1)
	ADDQ.W	#1,D7
	CMP.W	#4,D7
	BNE	PSGLog_v
	IFEQ	NO_PSGDDA
	LogString " u:"
	LogHexWord PSGDdaUnder
	LogString " d:"
	LogHexLong PSGVoiceDdaCh
	LogString " q:"
	MOVEQ	#0,D7
PSGLog_q:
	MOVE.B	(PSGRingWr.L,D7.W),D0
	SUB.B	(PSGRingRd.L,D7.W),D0
	AND.B	#7,D0
	ADD.B	#'0',D0
	MOVE.B	D0,PSGLogTxt
	CLR.B	PSGLogTxt+1
	LogText	#PSGLogTxt
	MOVE.B	#':',PSGLogTxt+1
	ADDQ.W	#1,D7
	CMP.W	#6,D7
	BNE	PSGLog_q
	ENDC
	LogString " t:"
	LogHexLong vTimerVBlanks
	IFEQ	NO_PSGDDA
	IFEQ	NO_DDASTRETCH
	LogString " r:"
	LogHexWord PSGDdaRate
	ENDC
	ENDC
	LogEnter
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
; Shadow of what was written to AUDx (D7 = voice, A1 = AUDx: LC from A2,
; LEN and PER read back from the registers we just wrote is not possible,
; so the callers' values are copied).
PSGShadowSet:
	MOVE.L	D0,-(SP)
	MOVE.W	D7,D0
	LSL.W	#4,D0
	MOVE.L	A2,(PSGShadow.L,D0.W)
	MOVE.W	D4,(PSGShadow+4.L,D0.W)
	MOVE.W	D2,(PSGShadow+6.L,D0.W)
	MOVE.W	D1,(PSGShadow+8.L,D0.W)
	MOVE.L	(SP)+,D0
	RTS
PSGShadowVol:
	MOVE.L	D0,-(SP)
	MOVE.W	D7,D0
	LSL.W	#4,D0
	MOVE.W	D1,(PSGShadow+8.L,D0.W)
	MOVE.L	(SP)+,D0
	RTS
PSGShadow:	DS.B	4*16
PSGLogTxt:	DC.B	"0:",0
PSGLogInit:	DC.B	0
	EVEN
PSGDdaCnt:	DS.B	8
	ENDC

PSGSel:		DC.B	0		; $0800 channel select
PSGMaster:	DC.B	0		; $0801 master balance
PSGLfo:		DC.B	0,0		; $0808 LFO frequency, $0809 LFO control
PSGWaveIdx:	DS.B	8
PSGWaveDirty:	DS.B	8
PSGWave:	DS.B	6*32
	EVEN
	ENDC


; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
