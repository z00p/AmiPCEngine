


	IFEQ	NO_WIDE
SprBufWidth = (32+320+32)/8	; up to 320 px (WideGeometry shows WideMax)
	ELSE
SprBufWidth = (32+256+32)/8
	ENDC
SprBufHeight = (64+224+64)

	IFEQ	NO_WIDE
; one 64-px sprite strip per use: D3 = dirty bit of column 0 on this line,
; A0 = buffer line (pivot), A2 -> StripCol entry, A4 -> even sprite line
WStrip:	MACRO
	move.w	(A2)+,D1
	IFEQ	NO_SPRCOVER
	tst.w	6(A2)			; StripForce (StripCol + 8): strip moved
	bne.s	.wc\@
	ENDC
	move.l	D3,D2
	add.w	D1,D2
	bftst	(A5){D2:8}
	beq.s	.ws\@
.wc\@:
	lea	(A0,D1.W),A1
	movem.l	(A1),D4/D5
	movem.l	SprBufNextBpl(A1),D6/D7
	movem.l	D4-D7,(A4)
	movem.l	SprBufNextBpl*2(A1),D4/D5
	movem.l	SprBufNextBpl*3(A1),D6/D7
	movem.l	D4-D7,NextSpr/2(A4)
.ws\@:
	add.l	#NextSpr,A4
	ENDM
	ENDC

SprBufNextLine = (SprBufWidth*4)

SprBufNextBpl = (SprBufWidth)

SprBufPivotXY = (64*SprBufNextLine)+(32/8)




	CNOP	0,8
TabDirRef:
	REPT	128*64	; until 128x64 Tiles in virtual screen
	DC.L	Ceros
	ENDR




	CNOP	0,8

VDP_Init_AGA:
	BSR	CreaTabOBJ
	BSR	CleanTabRefef
	IFEQ	NO_GFXRESET
	BSR	GfxReset
	ENDC
	RTS

	IFEQ	NO_GFXRESET
; A new game: PrintGFX only draws BAT cells whose word differs from PantAnt0
; (or whose tile changed), and PantGfx has just been cleared, so a BAT word
; left over from the last game (or the same game run again) stayed blank.
; Forget the old BAT and tile pointers, and clear the sprite buffers and the
; hardware sprite data (only dirty lines are copied).
GfxReset:
	MOVEM.L	D0-D1/A0,-(SP)
	LEA	PantAnt0,A0
	MOVE.L	#$12341234,D1
	MOVE.W	#((128*64*2)/4)-1,D0
.ant:	MOVE.L	D1,(A0)+
	DBF	D0,.ant
	LEA	TabDirRef,A0
	MOVE.L	#Ceros,D1
	MOVE.W	#(128*64)-1,D0
.dir:	MOVE.L	D1,(A0)+
	DBF	D0,.dir
	IFEQ	NO_SPRBANK
	CLR.W	BgPalDimW		; count the palettes again
	ENDC
	LEA	SpriteBufer,A0
	MOVE.L	#((SprBufWidth*SprBufHeight*4)/4)-1,D0
	MOVEQ	#0,D1
.spb:	MOVE.L	D1,(A0)+
	SUBQ.L	#1,D0
	BPL.S	.spb
	LEA	SpriteDirtyArea0,A0
	MOVE.W	#(((64+320+64)*8*2)/4)-1,D0	; Area0 and Area1
.dty:	MOVE.L	D1,(A0)+
	DBF	D0,.dty
	LEA	Sprit0+16,A0		; data lines of the 8 hardware sprites, not the control words
	MOVEQ	#8-1,D0
.spr:	MOVE.W	#((8*256*2)/4)-1,D1
.spr1:	CLR.L	(A0)+
	DBF	D1,.spr1
	LEA	16+16(A0),A0		; end words, next control words
	MOVEQ	#0,D1
	DBF	D0,.spr
	MOVEM.L	(SP)+,D0-D1/A0
	RTS
	ENDC




	CNOP	0,8
PrintSprites_AGA:

; Clear Sprites Buffer in Fast-RAM

;	move.w	#$f00,$dff180



;	moveq	#0,D4
;	moveq	#0,D5
;	moveq	#0,D6
;	moveq	#0,D7
;	move.l	#16,d3
;	lea	SpriteBufer+(SprBufNextLine*64),A0
;	move.w	#((SprBufNextLine*224)/16)-1,D0
;.loop:
;	movem.l	d4-d7,(A0)
;	add.l	d3,A0
;	dbf	d0,.loop

; ---

;	move.w	#$fff,$dff180




; Clear Sprites Dirty Buffer in Fast-RAM

	IFEQ	NO_WIDE
; One line at a time: 64 dirty bits (8 px each) per line, 40 used (320 px).
; Copy them to SpriteDirtyArea1 (lines to copy to the hardware sprites),
; clear them, and clear each dirty 64-px group of the buffer line.
	lea	SpriteDirtyArea0+(64*8),A0
	lea	SpriteDirtyArea1+(64*8),A1
	lea	SpriteBufer+(SprBufNextLine*64)+4,A6	; pivot x,y
	moveq	#0,D4
	moveq	#0,D5
	move.w	#224-1,D0
.wclr:
	movem.l	(A0),D2-D3
	movem.l	D2-D3,(A1)
	movem.l	D4-D5,(A0)
	addq.l	#8,A0
	addq.l	#8,A1
	tst.l	D2
	beq.s	.wclr4
	bftst	D2{0:8}
	beq.s	.wclr1
	movem.l	D4-D5,(A6)
	movem.l	D4-D5,SprBufNextBpl(A6)
	movem.l	D4-D5,SprBufNextBpl*2(A6)
	movem.l	D4-D5,SprBufNextBpl*3(A6)
.wclr1:
	bftst	D2{8:8}
	beq.s	.wclr2
	movem.l	D4-D5,8(A6)
	movem.l	D4-D5,8+SprBufNextBpl(A6)
	movem.l	D4-D5,8+(SprBufNextBpl*2)(A6)
	movem.l	D4-D5,8+(SprBufNextBpl*3)(A6)
.wclr2:
	bftst	D2{16:8}
	beq.s	.wclr3
	movem.l	D4-D5,16(A6)
	movem.l	D4-D5,16+SprBufNextBpl(A6)
	movem.l	D4-D5,16+(SprBufNextBpl*2)(A6)
	movem.l	D4-D5,16+(SprBufNextBpl*3)(A6)
.wclr3:
	tst.b	D2
	beq.s	.wclr4
	movem.l	D4-D5,24(A6)
	movem.l	D4-D5,24+SprBufNextBpl(A6)
	movem.l	D4-D5,24+(SprBufNextBpl*2)(A6)
	movem.l	D4-D5,24+(SprBufNextBpl*3)(A6)
.wclr4:
	bftst	D3{0:8}
	beq.s	.wclr5
	movem.l	D4-D5,32(A6)
	movem.l	D4-D5,32+SprBufNextBpl(A6)
	movem.l	D4-D5,32+(SprBufNextBpl*2)(A6)
	movem.l	D4-D5,32+(SprBufNextBpl*3)(A6)
.wclr5:
	add.w	#SprBufNextLine,A6
	dbf	D0,.wclr
	bra	.wclrDone
	ENDC

	lea	SpriteDirtyArea0+(64*8),A0
	lea	SpriteDirtyArea1+(64*8),A1
	move.l	#0,A2
	move.l	#0,A3
	move.l	#0,A4
	move.l	#0,A5
	lea	SpriteBufer+(SprBufNextLine*64)+4,A6	; pivot x,y
	move.w	#16,D1
	move.w	#SprBufNextLine,D6
	move.w	#((224*8)/16)-1,D0
	bra.s	.loop2

	nop
	nop

	cnop	0,8
.loop2:
	movem.l	(A0),D2-D5	; line-1: D2 ; line-2: D4  (D3 and D5 are outside of screen)
	movem.l	D2-D5,(A1)



	bftst	D2{0:8}
	beq.s	.skip0
	movem.l	A2-A3,(A6)
	movem.l	A2-A3,SprBufNextBpl(A6)
	movem.l	A2-A3,SprBufNextBpl*2(A6)
	movem.l	A2-A3,SprBufNextBpl*3(A6)
.skip0:


	bftst	D2{8:8}
	beq.s	.skip8
	movem.l	A2-A3,8(A6)
	movem.l	A2-A3,8+SprBufNextBpl(A6)
	movem.l	A2-A3,8+(SprBufNextBpl*2)(A6)
	movem.l	A2-A3,8+(SprBufNextBpl*3)(A6)
.skip8:


	bftst	D2{16:8}
	beq.s	.skip16
	movem.l	A2-A3,16(A6)
	movem.l	A2-A3,16+SprBufNextBpl(A6)
	movem.l	A2-A3,16+(SprBufNextBpl*2)(A6)
	movem.l	A2-A3,16+(SprBufNextBpl*3)(A6)
.skip16:


;	bftst	D2{24:8}
	tst	d2
	beq.s	.skip24
	movem.l	A2-A3,24(A6)
	movem.l	A2-A3,24+SprBufNextBpl(A6)
	movem.l	A2-A3,24+(SprBufNextBpl*2)(A6)
	movem.l	A2-A3,24+(SprBufNextBpl*3)(A6)
.skip24:


	add.w	D6,A6


	bftst	D4{0:8}
	beq.s	.skip0b
	movem.l	A2-A3,(A6)
	movem.l	A2-A3,SprBufNextBpl(A6)
	movem.l	A2-A3,SprBufNextBpl*2(A6)
	movem.l	A2-A3,SprBufNextBpl*3(A6)
.skip0b:


	bftst	D4{8:8}
	beq.s	.skip8b
	movem.l	A2-A3,8(A6)
	movem.l	A2-A3,8+SprBufNextBpl(A6)
	movem.l	A2-A3,8+(SprBufNextBpl*2)(A6)
	movem.l	A2-A3,8+(SprBufNextBpl*3)(A6)
.skip8b:


	bftst	D4{16:8}
	beq.s	.skip16b
	movem.l	A2-A3,16(A6)
	movem.l	A2-A3,16+SprBufNextBpl(A6)
	movem.l	A2-A3,16+(SprBufNextBpl*2)(A6)
	movem.l	A2-A3,16+(SprBufNextBpl*3)(A6)
.skip16b:


;	bftst	D4{24:8}
	tst	d4
	beq.s	.skip24b
	movem.l	A2-A3,24(A6)
	movem.l	A2-A3,24+SprBufNextBpl(A6)
	movem.l	A2-A3,24+(SprBufNextBpl*2)(A6)
	movem.l	A2-A3,24+(SprBufNextBpl*3)(A6)
.skip24b:


	
	add.w	D6,A6



	movem.l	A2-A5,(A0)
	add.w	D1,A0
	add.w	D1,A1
	dbf	D0,.loop2
	IFEQ	NO_WIDE
.wclrDone:
	ENDC

; ---

;	move.w	#$00F,$dff180



; Draw all Sprites in Fast-RAM

	IFEQ	NO_WIDE!NO_SPRCOVER
	clr.l	ColOcc
	clr.l	ColOcc+4
	clr.l	ColOcc+8
	clr.l	ColOcc+12
	ENDC
	lea	SpriteBufer+(SprBufNextBpl*0),A0
	lea	SpriteBufer+(SprBufNextBpl*2),A1
	lea	SpriteCoor,A4

	move.w	#64-1,D0	; 64 Sprites to proccess
.priSprBuc1:
	moveq	#0,D1
	move.w	(A4),D1		; Coor Y del Sprite
;	ror.w	#8,D1
	and.w	#SprXYMask,D1
	beq	.skipSprite
	cmp.w	#64+224,D1	; is Y outside of max-bottom?
	bcc	.skipSprite
;	bcs.s	.priSprCon1
;	move.w	#64+224,D1	; force Y to max-bottom
;.priSprCon1:

	moveq	#0,d7
	move.w	d1,d7		; Calculate SpritesDirtyArea-Y
	lsl.w	#6,d7

	mulu	#(SprBufNextLine),D1


	moveq	#0,d2
	move.w	2(A4),D2	; Coor X del Sprite
;	ror.w	#8,D2

	and.w	#SprXYMask,D2
	beq	.skipSprite
	IFEQ	NO_WIDE
	sub.w	WideC,D2	; buffer X: 32 + window pixel (WideC is a multiple of 8)
	ble	.skipSprite
	cmp.w	WideLim,D2	; right of the window?
	ELSE
	cmp.w	#32+256,D2	; is X outside of max-right?
	ENDC
	bcc	.skipSprite
;	bcs.s	.priSprCon2
;	move.w	#32+256,D2	; force X to max-right
;.priSprCon2:
	
	lsr.w	#3,D2		; Coor X (byte offset)
	add.l	D2,D1

	add.w	d2,d7		; Calculate SpritesDirtyArea-X



	moveq	#0,D2
	move.w	2(A4),D2	; Coor X offset
;	ror.w	#8,D2
	and.w	#$0007,D2
	moveq.l	#7,D5
	sub.l	D2,D5		; Coor X (bit shift)


	subq.l	#1,D1


; ----------------

	move.w	4(A4),D6	; pattern
;	ror.w	#8,D6
	and.l	#$03ff,D6
	lsl.l	#6,D6
	lea	(VRAM,D6.l),A5	; VRAM pattern pointer
	lea	(A5,128.w),A6

; ----------------

	lea	TablaOBJFlip0,A3	; Controlamos Flip X
	btst	#3,6(A4)
	beq.s	.noFlipX
	lea	TablaOBJFlip1,A3
	btst	#0,6(A4)		; 32 pixels de ancho?
	beq.s	.noFlipX
	exg.l	A5,A6			; Saltamos un frame para hacer FlipX
.noFlipX:

; ----------------

	moveq.l	#0,D2		; Height calculation
	move.b	6(A4),D2
	lsr.w	#4,D2
	and.w	#$0003,D2
	cmp.w	#$0002,D2
	bne.s	.heightCalculated
	moveq.w	#3,D2		; height = 64 pixels
.heightCalculated:

; ----------------


; --- set DIRTY start
	lea	SpriteDirtyArea0,A2
	move.l	#64,d4

	movem.l	D1-D2,-(sp)

	moveq	#3,D1
	btst	#0,6(A4)		; 32 pixels de ancho?
	beq.s	.no32pixels1
	moveq	#6,D1
.no32pixels1:
	IFEQ	NO_WIDE!NO_SPRCOVER
	IFEQ	NO_SPRDIRTY
	moveq	#63,d6		; D6 is free here; D2 is the height count of .loop below
	and.w	d7,d6		; buffer column = window column + 4
	bfset	ColOcc{d6:d1}
	ELSE
	move.w	d7,d2		; D2 is saved: buffer column = window column + 4
	and.w	#63,d2
	bfset	ColOcc{d2:d1}
	ENDC
	ENDC
	subq.w	#4,D7
	bcc.s	.cont
	moveq	#0,d7
.cont:

.loop:
	REPT	16
	bfset	(A2){D7:D1}
	add.w	d4,d7
	ENDR
	dbf	d2,.loop

	movem.l	(sp)+,D1-D2
; --- set DIRTY end


	move.l	#SprBufNextLine,d4

	btst	#7,6(A4)	; flip Y?
	beq.s	.noFlipY
	move.l	d2,d7
	addq.l	#1,d7
	mulu	#SprBufNextLine*16,d7
	add.l	d7,d1
	sub.l	d4,d1
	neg.l	d4
.noFlipY:



.loopHeight:

; ----------------


; A0 = SprBufBpl-0 (Base)
; A1 = SprBufBpl-2 (Base)
; A2 = SpriteDirtyArea
; A3 = FlipX Table
; A4 = Sprite Attr
; A5 = Pattern Gfx (VRAM Source pointer)
; A6 = A5+128 (pattern used for 32 pixel width)

; D0 = 64 Sprites loop
; D1 = SprBufOffset (TARGET offset)
; D2 = Vertical Patterns
; D3 = 
; D4 = 
; D5 = coor X bit shift
; D6 = pattern height
; D7 = used

	moveq	#(16)-1,D6	; 16 pixels de alto a copiar
.loopPattern:
	moveq	#0,D7         
	move.w	(A5),D7       
;	ror.w	#8,D7         
	move.w	(A3,D7.L*2),D7
	lsl.l	D5,D7         
	or.l	D7,(A0,D1.L)	; bpl-0

	moveq	#0,D7         
	move.w	32(A5),D7     
;	ror.w	#8,D7         
	move.w	(A3,D7.L*2),D7
	lsl.l	D5,D7         
	or.l	D7,SprBufNextBpl(A0,D1.L)	; bpl-1

	moveq	#0,D7         
	move.w	64(A5),D7     
;	ror.w	#8,D7         
	move.w	(A3,D7.L*2),D7
	lsl.l	D5,D7         
	or.l	D7,(A1,D1.L)	; bpl-2

	moveq	#0,D7         
	move.w	96(A5),D7     
;	ror.w	#8,D7         
	move.w	(A3,D7.L*2),D7	; bpl-3
	lsl.l	D5,D7         
	or.l	D7,SprBufNextBpl(A1,D1.L)  


	btst	#0,6(A4)		; 32 pixels de ancho?
	beq.s	.no32pixels


	moveq	#0,D7         
	move.w	(A6),D7       
;	ror.w	#8,D7         
	move.w	(A3,D7.L*2),D7
	lsl.l	D5,D7         
	or.l	D7,2(A0,D1.L)	; bpl-0

	moveq	#0,D7         
	move.w	32(A6),D7     
;	ror.w	#8,D7         
	move.w	(A3,D7.L*2),D7
	lsl.l	D5,D7         
	or.l	D7,SprBufNextBpl+2(A0,D1.L)	; bpl-1

	moveq	#0,D7         
	move.w	64(A6),D7     
;	ror.w	#8,D7         
	move.w	(A3,D7.L*2),D7
	lsl.l	D5,D7         
	or.l	D7,2(A1,D1.L)	; bpl-2

	moveq	#0,D7         
	move.w	96(A6),D7     
;	ror.w	#8,D7         
	move.w	(A3,D7.L*2),D7	; bpl-3
	lsl.l	D5,D7         
	or.l	D7,SprBufNextBpl+2(A1,D1.L)  
.no32pixels:


; Next Line
	addq.l	#2,A5			; Source: Siguiente linea del pattern
	addq.l	#2,A6			; Source: Siguiente linea del pattern
	add.l	D4,D1			; Target: Siguiente linea del buffer de sprites
	dbf	D6,.loopPattern


; Next Vertical
	add.l	#128-32+128,A5		; Source: VRAM: Siguiente Pattern
	add.l	#128-32+128,A6		; Source: VRAM: Siguiente Pattern

	dbf	D2,.loopHeight

.skipSprite:
	addq.l	#8,A4			; Siguiente sprite a procesar
	dbf	D0,.priSprBuc1

; ----------------
	
gem:
	
	
;	move.w	#$ff0,$dff180


	
; ---

; Clear Sprites Dirty Buffer in Fast-RAM

	lea	SpriteDirtyArea0+(64*8),A0
	lea	SpriteDirtyArea1+(64*8),A1
	move.w	#((224*8)/16)-1,D0
.loop2:
	movem.l	(A0)+,D2-D5
	or.l	D2,(A1)+
	or.l	D3,(A1)+
	or.l	D4,(A1)+
	or.l	D5,(A1)+
	dbf	d0,.loop2

; ---

;	move.w	#$0ff,$dff180




	IFEQ	NO_WIDE
; Four 64-px strips (attached pairs 0/1 .. 6/7) at the columns in StripCol.
; A strip that moved is copied whole; otherwise only its dirty lines.
	IFEQ	NO_SPRCOVER
	bsr	PlaceStrips
	ENDC
	lea	Sprit0+1,A1		; HSTART bits 8-1 in the POS word
	lea	StripCol,A2
	lea	StripColOld,A3
	moveq	#0,D6			; strips moved?
	moveq	#4-1,D0
.wpos:
	move.w	(A2)+,D1
	IFEQ	NO_SPRCOVER
	clr.w	6(A2)			; StripForce: copy this strip whole?
	cmp.w	(A3),D1
	beq.s	.wpos1
	move.w	#-1,6(A2)
	move.w	D1,(A3)
	ELSE
	cmp.w	(A3),D1
	beq.s	.wpos1
	moveq	#1,D6
	move.w	D1,(A3)
	ENDC
.wpos1:
	addq.l	#2,A3
	lsl.w	#3,D1
	add.w	WideM,D1
	add.w	#$A0,D1			; window left edge $A1 + WideM, sprite H one less
	lsr.w	#1,D1
	move.b	D1,(A1)
	move.b	D1,NextSpr/2(A1)
	add.l	#NextSpr,A1
	dbf	D0,.wpos
	tst.w	D6
	beq.s	.wcopy
	lea	SpriteDirtyArea1+(64*8),A1
	moveq	#-1,D1
	move.w	#(224*2)-1,D0
.wall:
	move.l	D1,(A1)+
	dbf	D0,.wall
.wcopy:
	lea	SpriteBufer+(SprBufPivotXY),A0
	lea	Sprit0+16,A4
	lea	SpriteDirtyArea1,A5
	move.l	#(64*64),D3
	move.w	#224-1,D0
.wline:
	lea	StripCol,A2
	WStrip
	WStrip
	WStrip
	WStrip
	sub.l	#(NextSpr*4)-16,A4
	add.w	#SprBufNextLine,A0
	add.l	#64,D3
	dbf	D0,.wline
	RTS
	ENDC

	lea	SpriteBufer+(SprBufPivotXY)+(SprBufNextBpl*0),A0
	lea	SpriteBufer+(SprBufPivotXY)+(SprBufNextBpl*1),A1
	lea	SpriteBufer+(SprBufPivotXY)+(SprBufNextBpl*2),A2
	lea	SpriteBufer+(SprBufPivotXY)+(SprBufNextBpl*3),A3
	lea	Sprit0+16,A4
	move.l	#(SprBufNextLine-32),D1
	move.l	#(NextSpr/2),D2
	move.l	#(((NextSpr/2)*7)-16),D3

	lea	SpriteDirtyArea1,A5
	move.l	#(64*64),D3

	move.w	#224-1,D0
PriSprBuc2:

	bftst	(A5){D3:8}
	beq.s	.skip0

	movem.l	(A0)+,D4/D5
	movem.l	(A1)+,D6/D7
	movem.l	D4/D5/D6/D7,(A4)	; Spr 0 (bpl-0/1) [XOOO]
	add.l	D2,A4

	movem.l	(A2)+,D4/D5
	movem.l	(A3)+,D6/D7
	movem.l	D4/D5/D6/D7,(A4)	; Spr 1 (bpl-2/3) [XOOO]
	add.l	D2,A4
	bra.s	.cont0
.skip0:
	addq	#8,A0
	addq	#8,A1
	addq	#8,A2
	addq	#8,A3
	add.l	D2,A4
	add.l	D2,A4
.cont0:
	addq.w	#8,D3

	bftst	(A5){D3:8}
	beq.s	.skip1

	movem.l	(A0)+,D4/D5
	movem.l	(A1)+,D6/D7
	movem.l	D4/D5/D6/D7,(A4)	; Spr 2 (bpl-0/1) [OXOO]
	add.l	D2,A4

	movem.l	(A2)+,D4/D5
	movem.l	(A3)+,D6/D7
	movem.l	D4/D5/D6/D7,(A4)	; Spr 3 (bpl-2/3) [OXOO]
	add.l	D2,A4
	bra.s	.cont1
.skip1:
	addq	#8,A0
	addq	#8,A1
	addq	#8,A2
	addq	#8,A3
	add.l	D2,A4
	add.l	D2,A4
.cont1:
	addq.w	#8,D3

	bftst	(A5){D3:8}
	beq.s	.skip2

	movem.l	(A0)+,D4/D5
	movem.l	(A1)+,D6/D7
	movem.l	D4/D5/D6/D7,(A4)	; Spr 4 (bpl-0/1) [OOXO]
	add.l	D2,A4

	movem.l	(A2)+,D4/D5
	movem.l	(A3)+,D6/D7
	movem.l	D4/D5/D6/D7,(A4)	; Spr 5 (bpl-2/3) [OOXO]
	add.l	D2,A4
	bra.s	.cont2
.skip2:
	addq	#8,A0
	addq	#8,A1
	addq	#8,A2
	addq	#8,A3
	add.l	D2,A4
	add.l	D2,A4
.cont2:
	addq.w	#8,D3

	bftst	(A5){D3:8}
	beq.s	.skip3

	movem.l	(A0)+,D4/D5
	movem.l	(A1)+,D6/D7
	movem.l	D4/D5/D6/D7,(A4)	; Spr 6 (bpl-0/1) [OOOX]
	add.l	D2,A4

	movem.l	(A2)+,D4/D5
	movem.l	(A3)+,D6/D7
	movem.l	D4/D5/D6/D7,(A4)	; Spr 7 (bpl-2/3) [OOOX]
;	sub.l	D3,A4
	sub.l	#(((NextSpr/2)*7)-16),A4
	bra.s	.cont3
.skip3:
	addq	#8,A0
	addq	#8,A1
	addq	#8,A2
	addq	#8,A3
	add.l	D2,A4
;	sub.l	D3,A4
	sub.l	#(((NextSpr/2)*7)-16),A4
.cont3:
	add.w	#8+32,D3

	add.l	D1,A0
	add.l	D1,A1
	add.l	D1,A2
	add.l	D1,A3


	dbf	D0,PriSprBuc2
	

;	move.w	#$040,$dff180


	RTS




GfxBufWidth = 128	; bytes (1 byte = 8 pixels)
GfxBufHeight = 512	; lines

GfxBufNextLine = (GfxBufWidth)
GfxBufNextBpl = (GfxBufWidth*GfxBufHeight)




PILA11:	DC.l	0
PILA22:	DC.l	0


	CNOP	0,8
PrintGFXchip:
	LEA	PantGfx,A0		; bitplanes
	MOVE.L	#GfxBufNextBpl,A3
	LEA	VRAM,A4
	LEA	VRAM,A5
	LEA	PantAnt0(PC),A6

	MOVE.B	(VDP_Regs+(9*2)+1),D3
	LSR.B	#4,D3
	AND.W	#$0007,D3
	MOVE.W	(VBGHeight.W,PC,D3.W*2),D2
	MOVE.W	(VBGWidth.W,PC,D3.W*2),D3

	move.l	A7,PILA11
	LEA	TabDirRef,A7	; Puntero de Gráficos modificados.

	move.l	#128,D6		; modulo to jump for next line
	sub.w	D3,D6

;	MOVE.W	#32-1,D2	; virtual BG Height
	subq.l	#1,D2
.PrtGfxBuc1:
;	MOVE.W	#32-1,D1	; virtual BG Width
	move.l	D3,D1
	subq.l	#1,D1
.PrtGfxBuc0:
	CMP.W	(A5)+,(A6)+
	BNE.S	.PrtGfxRut
;;	BRA.S	.PrtGfxRut	; force to re-draw all tiles

	TST.B	([A7])
	BNE.S	.PrtGfxRut
	ADDQ	#4,A7

	ADDQ.W	#1,A0

	DBF	D1,.PrtGfxBuc0

	ADD.L	D6,A6
;	lea	(A7,D6.w*4),A7
	ADD.L	#(GfxBufNextLine*8),A0
	sub.l	D3,A0

	DBF	D2,.PrtGfxBuc1

	move.l	PILA11,A7
	RTS

	CNOP	0,8
.PrtGfxRut:
	MOVE.W	-2(A5),-(A6)
	MOVEQ	#0,D0
	MOVE.W	(A6)+,D0

	MOVE.W	D0,D7
	LSR.W	#8,D7
	LSR.B	#4,D7
	AND.W	#$000F,D7
	MOVE.L	(TabGfx256.W,PC,D7.W*4),D7

;	ROR.W	#8,D0
	LSL.W	#4,D0

	LEA	(A4,D0.L*2),A2


	lsr.l	#4,d0
	lea	(TabRedef,D0.L),A1
	MOVE.L	A1,(A7)+


	move.l	a4,PILA22


	MOVE.W	#8-1,D0
.PrtGfxBuc:
	MOVE.L	A0,A1

	move.l	a0,a4
	add.w	d3,a4

	move.B	(a2),(a4)
	MOVE.B	(A2)+,(A1)
	add.l	a3,a4
	ADD.L	A3,A1
	move.B	(a2),(a4)
	MOVE.B	(A2)+,(A1)
	add.l	a3,a4
	ADD.L	A3,A1
	move.B	16-2(a2),(a4)
	MOVE.B	16-2(A2),(A1)
	add.l	a3,a4
	ADD.L	A3,A1
	move.B	17-2(a2),(a4)
	MOVE.B	17-2(A2),(A1)

	add.l	a3,a4
	ADD.L	A3,A1
	move.b	d7,(a4)
	MOVE.B	D7,(A1)
	ROR.L	#8,D7
	add.l	a3,a4
	ADD.L	A3,A1
	move.b	d7,(a4)
	MOVE.B	D7,(A1)
	ROR.L	#8,D7
	add.l	a3,a4
	ADD.L	A3,A1
	move.b	d7,(a4)
	MOVE.B	D7,(A1)
	ROR.L	#8,D7
	add.l	a3,a4
	ADD.L	A3,A1
	move.b	d7,(a4)
	MOVE.B	D7,(A1)
	ROR.L	#8,D7

	ADD.L	#(GfxBufNextLine),A0

	DBF	D0,.PrtGfxBuc



	move.l	PILA22,a4



	SUB.L	#(GfxBufNextLine*8)-1,A0

	DBF	D1,.PrtGfxBuc0

	ADD.L	D6,A6
;	lea	(A7,D6.w*4),A7
	ADD.L	#(GfxBufNextLine*8),A0
	sub.l	D3,A0

	DBF	D2,.PrtGfxBuc1

	move.l	PILA11,A7
	RTS







	CNOP	0,8
PrintGFX:
	LEA	PantGfx,A0		; bitplanes
	MOVE.L	#GfxBufNextBpl,A3
	LEA	VRAM,A4
	LEA	VRAM,A5
	LEA	PantAnt0(PC),A6

	MOVE.B	(VDP_Regs+(9*2)+1),D3
	LSR.B	#4,D3
	AND.W	#$0007,D3
	MOVE.W	(VBGHeight.W,PC,D3.W*2),D2
	MOVE.W	(VBGWidth.W,PC,D3.W*2),D3
	IFEQ	NO_BATSIZE
	CMP.W	BatDimW,D3		; BAT size changed: draw every cell (TabDirRef is
	BNE.S	.batNew			; filled in scan order, so its entries now belong
	CMP.W	BatDimH,D2		; to other cells, and the copies at +width are stale)
	BEQ.S	.batOld
.batNew:
	BSR	BatForce
.batOld:
	ENDC

	IFEQ	NO_SPRBANK
	CMP.W	BgPalDimW,D3		; BAT size changed: count the palettes again
	BNE.S	.recount
	CMP.W	BgPalDimH,D2
	BEQ.S	.counted
.recount:
	BSR	BgPalRecount
.counted:
	ENDC

	move.l	A7,PILA11
	LEA	TabDirRef,A7	; Puntero de Gráficos modificados.

	move.l	#128,D6		; modulo to jump for next line
	sub.w	D3,D6

;	MOVE.W	#32-1,D2	; virtual BG Height
	subq.l	#1,D2
.PrtGfxBuc1:
;	MOVE.W	#32-1,D1	; virtual BG Width
	move.l	D3,D1
	subq.l	#1,D1
.PrtGfxBuc0:
	CMP.W	(A5)+,(A6)+
	BNE.S	.PrtGfxRut
;;	BRA.S	.PrtGfxRut	; force to re-draw all tiles

	TST.B	([A7])
	BNE.S	.PrtGfxRut
	ADDQ	#4,A7

	ADDQ.W	#1,A0

	DBF	D1,.PrtGfxBuc0

	ADD.L	D6,A6
;	lea	(A7,D6.w*4),A7
	ADD.L	#(GfxBufNextLine*8),A0
	sub.l	D3,A0

	DBF	D2,.PrtGfxBuc1

	move.l	PILA11,A7
	RTS

	CNOP	0,8
.PrtGfxRut:
	IFEQ	NO_SPRBANK
	MOVE.W	-2(A6),D0		; old BAT word: one tile less for its palette
	ROL.W	#4,D0
	AND.W	#$000F,D0
	SUBQ.W	#1,(BgPalCnt,D0.W*2)
	MOVE.W	-2(A5),D0		; new BAT word
	ROL.W	#4,D0
	AND.W	#$000F,D0
	ADDQ.W	#1,(BgPalCnt,D0.W*2)
	ENDC
	MOVE.W	-2(A5),-(A6)
	MOVEQ	#0,D0
	MOVE.W	(A6)+,D0

	MOVE.W	D0,D7
	ROL.W	#4,D7
	AND.W	#$000F,D7
	MOVE.L	(TabGfx256.W,PC,D7.W*4),D7

	AND.W	#$0FFF,D0
	LSL.W	#4,D0

	LEA	(A4,D0.L*2),A2


	lsr.l	#4,d0
	lea	(TabRedef,D0.L),A1
	MOVE.L	A1,(A7)+


	move.l	a4,PILA22


	MOVE.W	#8-1,D0
.PrtGfxBuc:
	IFEQ	NO_BGMASK
; A pixel of value 0 is index 0 in every palette: the palette planes (D4) only
; where this row has a pixel.
	MOVE.W	(A2),D4
	OR.W	16(A2),D4
	MOVE.B	D4,D5
	LSR.W	#8,D4
	OR.B	D4,D5
	MOVE.B	D5,D4
	LSL.W	#8,D4
	MOVE.B	D5,D4
	MOVE.W	D4,D5
	SWAP	D4
	MOVE.W	D5,D4
	AND.L	D7,D4
	ENDC
	MOVE.L	A0,A1

	move.l	a0,a4
	add.w	d3,a4

	move.B	1(a2),(a4)
	MOVE.B	1(A2),(A1)
	add.l	a3,a4
	ADD.L	A3,A1
	move.B	(a2),(a4)
	MOVE.B	(A2),(A1)
	add.l	a3,a4
	ADD.L	A3,A1
	move.B	17(a2),(a4)
	MOVE.B	17(A2),(A1)
	add.l	a3,a4
	ADD.L	A3,A1
	move.B	16(a2),(a4)
	MOVE.B	16(A2),(A1)

	addq	#2,A2

	IFEQ	NO_BGMASK
	add.l	a3,a4
	ADD.L	A3,A1
	move.b	d4,(a4)
	MOVE.B	D4,(A1)
	ROR.L	#8,D4
	add.l	a3,a4
	ADD.L	A3,A1
	move.b	d4,(a4)
	MOVE.B	D4,(A1)
	ROR.L	#8,D4
	add.l	a3,a4
	ADD.L	A3,A1
	move.b	d4,(a4)
	MOVE.B	D4,(A1)
	ROR.L	#8,D4
	add.l	a3,a4
	ADD.L	A3,A1
	move.b	d4,(a4)
	MOVE.B	D4,(A1)
	ELSE
	add.l	a3,a4
	ADD.L	A3,A1
	move.b	d7,(a4)
	MOVE.B	D7,(A1)
	ROR.L	#8,D7
	add.l	a3,a4
	ADD.L	A3,A1
	move.b	d7,(a4)
	MOVE.B	D7,(A1)
	ROR.L	#8,D7
	add.l	a3,a4
	ADD.L	A3,A1
	move.b	d7,(a4)
	MOVE.B	D7,(A1)
	ROR.L	#8,D7
	add.l	a3,a4
	ADD.L	A3,A1
	move.b	d7,(a4)
	MOVE.B	D7,(A1)
	ROR.L	#8,D7
	ENDC

	ADD.L	#(GfxBufNextLine),A0

	DBF	D0,.PrtGfxBuc

	IFEQ	NO_WIDE
	CMP.W	#32,D3			; 32-tile BAT: a third copy, so a 320-px window
	BNE.S	.noThird		; scrolled up to 255 px still has data
	LEA	-(GfxBufNextLine*8)(A0),A1
	MOVEQ	#8-1,D0
.third:
	MOVE.L	A1,A4
	REPT	8
	MOVE.B	(A4),64(A4)
	ADD.L	A3,A4
	ENDR
	ADD.L	#GfxBufNextLine,A1
	DBF	D0,.third
.noThird:
	ENDC

	move.l	PILA22,a4



	SUB.L	#(GfxBufNextLine*8)-1,A0

	DBF	D1,.PrtGfxBuc0

	ADD.L	D6,A6
;	lea	(A7,D6.w*4),A7
	ADD.L	#(GfxBufNextLine*8),A0
	sub.l	D3,A0

	DBF	D2,.PrtGfxBuc1

	move.l	PILA11,A7
	RTS











	IFEQ	NO_BATSIZE
BatDimW:	DC.W	0
BatDimH:	DC.W	0
BatForceB:	DC.B	1
	EVEN
; D3, D2 = BAT width, height in tiles. Keeps all registers.
BatForce:
	MOVE.W	D3,BatDimW
	MOVE.W	D2,BatDimH
	MOVEM.L	D0-D1/A0,-(SP)
	LEA	TabDirRef,A0
	MOVE.L	#BatForceB,D1
	MOVE.W	#(128*64)-1,D0
.f:	MOVE.L	D1,(A0)+
	DBF	D0,.f
	MOVEM.L	(SP)+,D0-D1/A0
	RTS
	ENDC

	IFEQ	NO_SPRBANK
; BgPalCnt: BAT entries per BG palette over the BAT area PrintGFX scans
; (PantAnt0, BgPalDimW x BgPalDimH tiles, 128 words per row). PrintGFX keeps
; it up to date per changed tile; PonePaleta_AGA puts the sprite colours in
; the bank of the least used palette.
BgPalCnt:	DS.W	16
BgPalDimW:	DC.W	0
BgPalDimH:	DC.W	0

;	D2 = BAT height (tiles), D3 = BAT width (tiles); all registers kept
BgPalRecount:
	MOVEM.L	D0-D3/A0-A1,-(SP)
	MOVE.W	D3,BgPalDimW
	MOVE.W	D2,BgPalDimH
	LEA	BgPalCnt,A1
	MOVEQ	#8-1,D0
.clr:	CLR.L	(A1)+
	DBF	D0,.clr
	LEA	BgPalCnt,A1
	LEA	PantAnt0,A0
	MOVE.L	#128,D1
	SUB.W	D3,D1
	ADD.L	D1,D1			; bytes to the next row
	SUBQ.W	#1,D2
.row:	MOVE.W	D3,D0
	SUBQ.W	#1,D0
.col:	MOVE.W	(A0)+,D1
	ROL.W	#4,D1
	AND.W	#$000F,D1
	ADDQ.W	#1,(A1,D1.W*2)
	DBF	D0,.col
	MOVE.L	#128,D1
	SUB.W	D3,D1
	LEA	(A0,D1.L*2),A0
	DBF	D2,.row
	MOVEM.L	(SP)+,D0-D3/A0-A1
	RTS
	ENDC

	IFEQ	NO_WIDE
; Picture width from the VDC (R0B HDW). The BG needs a 32-px fetch ahead of
; the window (BPLCON1 scrolls 0-31 px in 32-bit fetch mode) and DDFSTRT stays
; at $38 so all 8 sprites keep their DMA slots, so the window starts at H $A1
; (narrower modes centred in Juan's 256 px) and runs right up to $1C1, the
; right edge of a normal 320-px screen (WinUAE shows up to ~$1C3): at most
; WideMax px. Wider modes lose (W-WideMax)/2 px each side, rounded down to
; 8. A 256-px mode gives Juan's copper values. Once per PCE frame: copper
; DIW, DDFSTOP and modulos, BG X origin.
WideMax = 288
WideGeometry:
	MOVEM.L	D0-D3/A0,-(SP)
	MOVEQ	#0,D0
	MOVE.B	VDP_Regs+(11*2)+1,D0
	AND.W	#$7F,D0
	ADDQ.W	#1,D0
	LSL.W	#3,D0			; PCE width
	MOVE.W	D0,D1
	CMP.W	#WideMax,D1
	BLS.S	.w1
	MOVE.W	#WideMax,D1
.w1:	CMP.W	#96,D1
	BCC.S	.w2
	MOVE.W	#96,D1
.w2:	MOVE.W	D0,D2			; D1 = shown width
	SUB.W	D1,D2
	BCC.S	.w3
	MOVEQ	#0,D2
.w3:	LSR.W	#1,D2
	AND.W	#$FFF8,D2
	MOVE.W	D2,WideC		; cut on the left
	MOVE.W	D1,WideW
	MOVE.W	D1,D3
	ADD.W	#32,D3
	MOVE.W	D3,WideLim
	MOVEQ	#0,D3			; narrower than 256: centred (even margin)
	CMP.W	#256,D1
	BCC.S	.w4
	MOVE.W	#256,D3
	SUB.W	D1,D3
	LSR.W	#2,D3
	ADD.W	D3,D3
.w4:	MOVE.W	D3,WideM
	SUB.W	D3,D2
	MOVE.W	D2,WideX		; BG pixel at H $A1 = scroll X + cut - margin
	MOVE.W	D3,D2
	ADD.W	#$A1,D3
	MOVE.B	D3,Copper+3		; DIWSTRT H
	ADD.W	D1,D3
	MOVE.B	D3,Copper+7		; DIWSTOP H ($1xx)
	ADD.W	D1,D2
	ADD.W	#32+31,D2
	LSR.W	#5,D2			; longs: (margin + width + 32) / 32, rounded up
	MOVE.W	D2,D3
	SUBQ.W	#1,D3
	LSL.W	#4,D3
	ADD.W	#$38,D3
	MOVE.W	D3,Copper+14		; DDFSTOP (32-bit fetch: 16 per long)
	LSL.W	#2,D2
	NEG.W	D2
	ADD.W	#GfxBufNextLine,D2
	MOVE.W	D2,Copper+18		; BPL1MOD
	MOVE.W	D2,Copper+22		; BPL2MOD
	IFEQ	NO_AGAVDW|NO_NTSCTOP
	MOVE.W	VDP_Regs+(13*2),D0	; picture height: the VDC's (R0D + 1 lines), at most 232;
	AND.W	#$1FF,D0		; lines past it are not shown (UWOL keeps junk there)
	ADDQ.W	#1,D0
	CMP.W	#232,D0
	BLS.S	.vh1
	MOVE.W	#232,D0
.vh1:	CMP.W	#128,D0			; (not set yet, or odd: the full 232)
	BCC.S	.vh2
	MOVE.W	#232,D0
.vh2:	ADD.W	PicTop,D0
	ADDQ.W	#1,D0
	MOVE.B	D0,Copper+6		; DIWSTOP V (bit 8 = NOT bit 7)
	ENDC
	MOVEM.L	(SP)+,D0-D3/A0
	RTS

WideC:		DC.W	0	; PCE pixels cut on the left (multiple of 8)
WideW:		DC.W	256	; pixels shown
WideLim:	DC.W	32+256	; sprite buffer X limit (32 + WideW)
WideM:		DC.W	0	; window start - $A1
WideX:		DC.W	0	; added to the BG scroll X
StripCol:	DC.W	0,8,16,24	; sprite strip start columns (8 px) in the window
	IFEQ	NO_SPRCOVER
StripForce:	DC.W	0,0,0,0		; must follow StripCol (WStrip)
	ENDC
StripColOld:	DC.W	-1,-1,-1,-1
	IFEQ	NO_SPRCOVER
ColOcc:		DS.B	16	; columns with sprite pixels this frame, bit 4 = window column 0
ColNeed:	DS.B	16
StripTmp:	DS.W	4

; Put the 4 strips (64 px = 8 columns each) where the sprites are. Strips
; that cover sprite columns stay; uncovered columns get the unused strips,
; left to right. If that is not enough, a fresh left-to-right plan is used
; when it covers everything. Strips never start past WideW/8 - 8.
PlaceStrips:
	MOVEM.L	D0-D7/A0-A2,-(SP)
	LEA	ColOcc,A0
	LEA	ColNeed,A1
	LEA	StripCol,A2
	MOVE.W	WideW,D5
	LSR.W	#3,D5			; window columns
	MOVE.W	D5,D7
	SUBQ.W	#8,D7			; last strip start
	BCC.S	.ps0
	MOVEQ	#0,D7
.ps0:
	BSR	.need			; ColNeed = ColOcc
	MOVEQ	#0,D6			; strips in use (bit k)
	MOVEQ	#0,D0
.used:
	MOVEQ	#4,D2			; bitfield offsets are longs
	ADD.W	(A2,D0.W*2),D2
	BFTST	(A0){D2:8}
	BEQ.S	.used1
	BSET	D0,D6
	BFCLR	(A1){D2:8}
.used1:
	ADDQ.W	#1,D0
	CMP.W	#4,D0
	BNE.S	.used
	MOVEQ	#0,D0
.place:
	BSR	.first			; D1 = first needed column, or >= D5
	CMP.W	D5,D1
	BCC.S	.done
.find:
	CMP.W	#4,D0
	BCC.S	.full
	BTST	D0,D6
	BEQ.S	.take
	ADDQ.W	#1,D0
	BRA.S	.find
.take:
	CMP.W	D7,D1
	BLS.S	.take1
	MOVE.W	D7,D1
.take1:
	MOVE.W	D1,(A2,D0.W*2)
	BSET	D0,D6
	MOVEQ	#4,D2
	ADD.W	D1,D2
	BFCLR	(A1){D2:8}
	BRA.S	.place
.full:					; not enough: try a fresh plan
	BSR	.need
	MOVEQ	#0,D0
.plan:
	BSR	.first
	CMP.W	D5,D1
	BCC.S	.planOk
	CMP.W	#4,D0
	BCC.S	.done			; still not enough: keep what we have
	CMP.W	D7,D1
	BLS.S	.plan1
	MOVE.W	D7,D1
.plan1:
	MOVE.W	D1,(StripTmp,D0.W*2)
	MOVEQ	#4,D2
	ADD.W	D1,D2
	BFCLR	(A1){D2:8}
	ADDQ.W	#1,D0
	BRA.S	.plan
.planOk:
	SUBQ.W	#1,D0
	BMI.S	.done
.plan2:
	MOVE.W	(StripTmp,D0.W*2),(A2,D0.W*2)
	DBF	D0,.plan2
.done:
	MOVEM.L	(SP)+,D0-D7/A0-A2
	RTS
.need:
	MOVE.L	(A0),(A1)
	MOVE.L	4(A0),4(A1)
	MOVE.L	8(A0),8(A1)
	MOVE.L	12(A0),12(A1)
	RTS
.first:					; D1 = first set column of ColNeed (64 if none); D2 used
	BFFFO	(A1){4:32},D1
	CMP.W	#4+32,D1
	BCS.S	.first1
	MOVEQ	#36,D2
	BFFFO	(A1){D2:32},D1
.first1:
	SUBQ.W	#4,D1
	RTS
	ENDC
	ENDC

	CNOP	0,8
CleanTabRefef:
	MOVEM.L	Ceros(PC),D0-D7/A0-A5

	LEA	TabRedef+2048,A6
	REPT	36
	MOVEM.L	D0-D7/A0-A5,-(A6)	; clean 56 bytes
	ENDR
	MOVEM.L	D0-D7,-(A6)		; clean 32 bytes
	RTS








; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-



	CNOP	0,8
PonePaleta_AGA:
	LEA	VDP_Pal,A0
	LEA	COLOR+2,A1
	MOVE.W	#(8)-1,D4
PonPalBuc0:
	MOVE.W	#(32)-1,D0
PonPalBuc:
	MOVE.W	(A0)+,D1
;	ROR.W	#8,D1

	MOVE.W	D1,D2
	MOVE.W	D1,D3

	LSR.W	#1,D3		; G
	AND.W	#$00E0,D3

	LSL.W	#6,D2		; R
	AND.W	#$0E00,D2

	LSL.W	#1,D1		; B
	AND.W	#$000E,D1

	OR.W	D2,D1
	OR.W	D3,D1
	MOVE.W	D1,(A1)+
	ADDQ.W	#2,A1
	DBF	D0,PonPalBuc
	ADD.W	#4,A1
	DBF	D4,PonPalBuc0

; ---

	lea	PaletaSprUsage,A5
	clr.l	(A5)
	clr.l	4(A5)
	clr.l	8(A5)
	clr.l	12(A5)

	lea	SpriteCoor,A4

	IFEQ	NO_SPRBACK|NO_BGMASK
	moveq	#0,D7		; bit 0: a sprite in the window, bit 1: one over the BG
	ENDC
	move.w	#64-1,D0	; 64 Sprites
PonPalBuc1:
	move.w	(A4),D1		; Coor Y del Sprite
;	ror.w	#8,D1
	and.w	#SprXYMask,D1
	beq.s	skipSpr	
	cmp.w	#64+224,D1
	bcc.s	skipSpr
	move.w	2(A4),D1	; Coor X del Sprite
;	ror.w	#8,D1
	and.w	#SprXYMask,D1
	beq.s	skipSpr
	IFEQ	NO_WIDE
	sub.w	WideC,D1	; count only sprites in the window (on the strips: px 0-255)
	ble.s	skipSpr
	IFEQ	NO_SPRCOVER
	cmp.w	WideLim,D1
	ELSE
	cmp.w	#32+256,D1
	ENDC
	ELSE
	cmp.w	#32+256,D1
	ENDC
	bcc.s	skipSpr

	IFEQ	NO_SPRBACK|NO_BGMASK
	bset	#0,D7
	tst.b	7(A4)		; SPBG: 1 = over the BG
	bpl.s	.back
	bset	#1,D7
.back:
	ENDC
	move.w	6(A4),D1	; Palete Index
;	ror.w	#8,D1
	IFEQ	NO_SPRAREA
; weight by area in 16x16 units: x2 for 32 wide, x2/x4 for 32/64 high (saturating)
	moveq	#1,D2
	btst	#8,D1
	beq.s	.area1
	moveq	#2,D2
.area1:
	btst	#13,D1		; CGY 2/3: 64 high
	beq.s	.area2
	lsl.b	#2,D2
	bra.s	.area3
.area2:
	btst	#12,D1		; CGY 1: 32 high
	beq.s	.area3
	add.b	D2,D2
.area3:
	and.w	#$000f,D1
	add.b	D2,(A5,D1.W)
	bcc.s	skipSpr
	st	(A5,D1.W)
	ELSE
	and.w	#$000f,D1
	addq.b	#1,(A5,D1.W)
	ENDC
skipSpr:
	addq.l	#8,A4
	dbf	d0,PonPalBuc1

	IFEQ	NO_SPRBACK|NO_BGMASK
; Hardware sprites have one priority for the frame, so behind the BG only when
; every visible sprite asks for it (title screens); a mixed frame stays over it.
	move.w	#$007F,D1
	cmp.b	#1,D7
	bne.s	.prio
	move.w	#$0040,D1	; PF2P 0: the BG over all sprites
.prio:	move.w	D1,CopBplcon2+2
	ENDC

	move.w	#16-1,D0	; 16 Paletas
	moveq.l	#0,D1
	moveq.l	#0,D2
	moveq.l	#0,D3
PonPalBuc3:
	cmp.b	(A5)+,D1
	bcc.s	noEsMayor
	move.b	-1(A5),D1
	move.b	d2,d3
noEsMayor:
	addq.l	#1,d2
	dbf	d0,PonPalBuc3

	mulu	#32,D3

	IFEQ	NO_SPRBANK
; Sprite colours go to the bank of the least used BG palette (15 on a tie or
; when it is free, as before), and BPLCON4 points the sprites at it.
	MOVEQ	#15,D4			; bank
	MOVE.W	BgPalCnt+30,D5		; its BAT count
	BEQ.S	.sprBank
	MOVEQ	#14,D6
.sprScan:
	MOVE.W	(BgPalCnt,D6.W*2),D2
	CMP.W	D5,D2
	BCC.S	.sprNext
	MOVE.W	D2,D5
	MOVE.W	D6,D4
	TST.W	D5
	BEQ.S	.sprBank
.sprNext:
	DBF	D6,.sprScan
.sprBank:
	MOVE.W	D4,D5			; colour 16*bank: bank/2 copper banks of 32 moves + 1 BPLCON3 move
	LSR.W	#1,D5
	MULU	#(32*4)+4,D5
	BTST	#0,D4
	BEQ.S	.sprEven
	ADD.W	#16*4,D5
.sprEven:
	LEA	(COLOR+2,D5.L),A1
	MOVE.W	D4,D5
	LSL.W	#4,D5
	OR.W	D4,D5
	MOVE.W	D5,CopBplcon4+2		; ESPRM = OSPRM = bank
	ELSE
	SUB.W	#4+(16*4),A1
	ENDC
	IFEQ	NO_BGMASK
	MOVE.W	COLOR+2,D6	; sprites in bank 0 must not take colour 0
	ENDC
	LEA	VDP_Pal+$200,A0
	ADD.L	D3,A0
	MOVE.W	#(16)-1,D0
PonPalBuc2:
	MOVE.W	(A0)+,D1
;	ROR.W	#8,D1

	MOVE.W	D1,D2
	MOVE.W	D1,D3

	LSR.W	#1,D3		; G
	AND.W	#$00E0,D3

	LSL.W	#6,D2		; R
	AND.W	#$0E00,D2

	LSL.W	#1,D1		; B
	AND.W	#$000E,D1

	OR.W	D2,D1
	OR.W	D3,D1
	MOVE.W	D1,(A1)+
	ADDQ.W	#2,A1
	DBF	D0,PonPalBuc2

	IFEQ	NO_BGMASK
	MOVE.W	D6,COLOR+2
	ENDC
	IFNE	NO_BGMASK
	IFEQ	NO_BGCOL0
; The VCE shows BG pixel value 0 in colour 0 for every BG palette. Copy the
; converted colour 0 to entries 16, 32, ... 240 (240 is also sprite colour 0,
; which is transparent, so its value never shows on a sprite).
	MOVE.W	COLOR+2,D1
	LEA	COLOR+2+(32*4)+4,A1	; bank 1 slot 0 (each bank: 32 moves + 1 BPLCON3 move)
	MOVE.W	D1,-(16*4)-4(A1)	; bank 0 slot 16
	MOVEQ	#7-1,D0			; banks 1-7
PonPalBuc4:
	MOVE.W	D1,(A1)			; slot 0
	MOVE.W	D1,16*4(A1)		; slot 16
	LEA	(32*4)+4(A1),A1
	DBF	D0,PonPalBuc4
	ENDC
	ENDC

	IFEQ	NO_BURST
	MOVE.B	VDP_Regs+(5*2)+1,D0	; BG and sprites off: VCE entry $100 (see RtgFrame)
	AND.B	#$C0,D0
	BNE.S	.nburst
	MOVE.W	VDP_Pal+$200,D1
	MOVE.W	D1,D2
	MOVE.W	D1,D3
	LSR.W	#1,D3		; G
	AND.W	#$00E0,D3
	LSL.W	#6,D2		; R
	AND.W	#$0E00,D2
	LSL.W	#1,D1		; B
	AND.W	#$000E,D1
	OR.W	D2,D1
	OR.W	D3,D1
	MOVE.W	D1,COLOR+2
.nburst:
	ENDC

	RTS

	IFEQ	NO_BGLINE|NO_BGMASK
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Colour 0 line by line. All BG palettes share index 0 (NO_BGMASK), so one
; COLOR00 move follows a raster effect on the backdrop. Each frame has a table:
; a head entry (row -1, the colour at the start of the frame), then (row,
; colour) entries, rows rising, row $7FFF at the end. A write on ScanLine N
; shows from row N+1, as a scroll write does. Colours are copper values.
BGLOGMAX = 224
BGBORDER = 16		; entries in a frame that make it a raster effect (fades write a few)

BgLogNow:	DC.L	BgLogA	; being written
BgLogNext:	DC.L	BgLogB	; last finished frame
BgLogIdx:	DC.L	BgLogA+4
BgLogA:		DS.L	1+BGLOGMAX+1
BgLogB:		DS.L	1+BGLOGMAX+1

BgLogInit:
	MOVE.L	#BgLogA,BgLogNow
	MOVE.L	#BgLogB,BgLogNext
	MOVE.L	#BgLogA+4,BgLogIdx
	MOVE.L	#$FFFF0000,BgLogA
	MOVE.L	#$FFFF0000,BgLogB
	MOVE.W	#$7FFF,BgLogA+4
	MOVE.W	#$7FFF,BgLogB+4
	RTS

; D0.W = VCE colour -> copper value (as PonePaleta_AGA); D1-D2 used
BgColRgb:
	MOVE.W	D0,D1
	MOVE.W	D0,D2
	LSR.W	#1,D2		; G
	AND.W	#$00E0,D2
	LSL.W	#6,D1		; R
	AND.W	#$0E00,D1
	LSL.W	#1,D0		; B
	AND.W	#$000E,D0
	OR.W	D1,D0
	OR.W	D2,D0
	RTS

; A write to VCE entry 0 (IO.asm), PAL_Data = the colour. All registers kept.
BgColLog:
	IFEQ	NO_RTG
	TST.B	RtgOn		; RTG has its own log
	BNE.S	.r
	ENDC
	MOVEM.L	D0-D2/A0,-(SP)
	MOVE.W	ScanLine(A3),D1
	CMP.W	#BGLOGMAX,D1
	BCC.S	.x
	ADDQ.W	#1,D1
	MOVE.L	BgLogIdx,A0
	CMP.W	-4(A0),D1	; same row: the last write counts
	BEQ.S	.upd
	MOVE.W	D1,(A0)
	ADDQ.L	#4,A0
	MOVE.L	A0,BgLogIdx
.upd:	MOVE.W	PAL_Data(A3),D0
	BSR	BgColRgb
	MOVE.W	D0,-2(A0)
.x:	MOVEM.L	(SP)+,D0-D2/A0
.r:	RTS

; End of a PCE frame: this table goes to the vblank, the other one starts with
; entry 0 as the next frame begins. All registers kept.
BgLogSwap:
	MOVEM.L	D0-D2/A0-A1,-(SP)
	MOVE.L	BgLogIdx,A0
	MOVE.W	#$7FFF,(A0)
	MOVE.L	BgLogNow,A0
	MOVE.L	BgLogNext,A1
	MOVE.L	A1,BgLogNow
	MOVE.L	A0,BgLogNext
	MOVE.W	#-1,(A1)
	MOVE.W	VDP_Pal,D0
	BSR	BgColRgb
	MOVE.W	D0,2(A1)
	ADDQ.L	#4,A1
	MOVE.L	A1,BgLogIdx
	MOVEM.L	(SP)+,D0-D2/A0-A1
	RTS
	ENDC

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	CNOP	0,8
CreaTabOBJ:
	LEA	TablaOBJFlip0,A0
	LEA	TablaOBJFlip1,A1

	MOVEQ	#0,D1
	MOVEQ	#0,D3
	MOVE.W	#($10000)-1,D0
CrTaOBJBuc:
	MOVE.W	D1,D2
	MOVE.W	D2,(A0)+
	REPT	16
	LSR.W	#1,D2
	ADDX.W	D3,D3
	ENDR
	MOVE.W	D3,(A1)+
	ADDQ.W	#1,D1
	DBF	D0,CrTaOBJBuc
	RTS

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-





PaletaSprUsage:	DS.B	16



	CNOP	0,8
TabGfx256:
	DC.L	$00000000
	DC.L	$000000FF
	DC.L	$0000FF00
	DC.L	$0000FFFF
	DC.L	$00FF0000
	DC.L	$00FF00FF
	DC.L	$00FFFF00
	DC.L	$00FFFFFF
	DC.L	$FF000000
	DC.L	$FF0000FF
	DC.L	$FF00FF00
	DC.L	$FF00FFFF
	DC.L	$FFFF0000
	DC.L	$FFFF00FF
	DC.L	$FFFFFF00
	DC.L	$FFFFFFFF


	CNOP	0,8
VBGWidth:DC.W	32,64,128,128,32,64,128,128
VBGHeight:DC.W	32,32,32,32,64,64,64,64




	CNOP	0,8
Ceros:	DS.L	16


	CNOP	0,8
PantAnt0:	DCB.W	128*64,$1234






