

	CNOP	0,8

VDP_Init_SAGA:


	lea	SpritesBufA+iSprBufCoors,A0
	lea	SAGASpritesPtrs,A1
	moveq	#16-1,D0
.loop:
	addq	#2,a1
	move.l	(a0)+,(a1)+
	dbf	d0,.loop


	BSR	CreaTabOBJ
	BSR	CleanTabRefef




	move.l	SpritesBufNow,A5		; table with all Spr Coors pointers

; ---
	move.l	iSprBufCoors(A5),A0
	move.l	(A5)+,A1	; A1 => Spr x Coors

	move.w	#$60,d0
	move.w	#$40,d1
	move.w	#$20,d2
	move.w	#$00,d3
	bsr	PutSprite

	clr.l	(a1)+
	clr.l	(a1)+

; ---
	move.l	(A5)+,A1	; A1 => Spr x Coors
	add.l	#(16*64),A0	; A0 => Spr x Bitmap

	move.w	#$78,d0
	move.w	#$40,d1
	move.w	#$20,d2
	move.w	#$01,d3
	bsr	PutSprite

	clr.l	(a1)+
	clr.l	(a1)+

; ---
	move.l	(A5)+,A1	; A1 => Spr x Coors
	add.l	#(16*64),A0	; A0 => Spr x Bitmap

	move.w	#$90,d0
	move.w	#$40,d1
	move.w	#$20,d2
	move.w	#$02,d3
	bsr	PutSprite

	clr.l	(a1)+
	clr.l	(a1)+

; ---
	move.l	(A5)+,A1	; A1 => Spr x Coors
	add.l	#(16*64),A0	; A0 => Spr x Bitmap

	move.w	#$A8,d0
	move.w	#$40,d1
	move.w	#$20,d2
	move.w	#$03,d3
	bsr	PutSprite

	clr.l	(a1)+
	clr.l	(a1)+

; ---
	move.l	(A5)+,A1	; A1 => Spr x Coors
	add.l	#(16*64),A0	; A0 => Spr x Bitmap

	move.w	#$60,d0
	move.w	#$70,d1
	move.w	#$20,d2
	move.w	#$04,d3
	bsr	PutSprite

	clr.l	(a1)+
	clr.l	(a1)+

; ---
	move.l	(A5)+,A1	; A1 => Spr x Coors
	add.l	#(16*64),A0	; A0 => Spr x Bitmap

	move.w	#$78,d0
	move.w	#$70,d1
	move.w	#$20,d2
	move.w	#$05,d3
	bsr	PutSprite

	clr.l	(a1)+
	clr.l	(a1)+

; ---
	move.l	(A5)+,A1	; A1 => Spr x Coors
	add.l	#(16*64),A0	; A0 => Spr x Bitmap

	move.w	#$90,d0
	move.w	#$70,d1
	move.w	#$20,d2
	move.w	#$06,d3
	bsr	PutSprite

	clr.l	(a1)+
	clr.l	(a1)+

; ---
	move.l	(A5)+,A1	; A1 => Spr x Coors
	add.l	#(16*64),A0	; A0 => Spr x Bitmap

	move.w	#$a8,d0
	move.w	#$70,d1
	move.w	#$20,d2
	move.w	#$07,d3
	bsr	PutSprite

	clr.l	(a1)+
	clr.l	(a1)+




; ---
	move.l	(A5)+,A1	; A1 => Spr x Coors
	add.l	#(16*64),A0	; A0 => Spr x Bitmap

	move.w	#$60,d0
	move.w	#$A0,d1
	move.w	#$20,d2
	move.w	#$08,d3
	bsr	PutSprite

	clr.l	(a1)+
	clr.l	(a1)+

; ---
	move.l	(A5)+,A1	; A1 => Spr x Coors
	add.l	#(16*64),A0	; A0 => Spr x Bitmap

	move.w	#$78,d0
	move.w	#$A0,d1
	move.w	#$20,d2
	move.w	#$09,d3
	bsr	PutSprite

	clr.l	(a1)+
	clr.l	(a1)+

; ---
	move.l	(A5)+,A1	; A1 => Spr x Coors
	add.l	#(16*64),A0	; A0 => Spr x Bitmap

	move.w	#$90,d0
	move.w	#$A0,d1
	move.w	#$20,d2
	move.w	#$0a,d3
	bsr	PutSprite

	clr.l	(a1)+
	clr.l	(a1)+

; ---
	move.l	(A5)+,A1	; A1 => Spr x Coors
	add.l	#(16*64),A0	; A0 => Spr x Bitmap

	move.w	#$a8,d0
	move.w	#$A0,d1
	move.w	#$20,d2
	move.w	#$0b,d3
	bsr	PutSprite

	clr.l	(a1)+
	clr.l	(a1)+

; ---

	move.l	(A5)+,A1	; A1 => Spr x Coors
	add.l	#(16*64),A0	; A0 => Spr x Bitmap

	move.w	#$60,d0
	move.w	#$D0,d1
	move.w	#$20,d2
	move.w	#$0c,d3
	bsr	PutSprite

	clr.l	(a1)+
	clr.l	(a1)+

; ---
	move.l	(A5)+,A1	; A1 => Spr x Coors
	add.l	#(16*64),A0	; A0 => Spr x Bitmap

	move.w	#$78,d0
	move.w	#$D0,d1
	move.w	#$20,d2
	move.w	#$0d,d3
	bsr	PutSprite

	clr.l	(a1)+
	clr.l	(a1)+

; ---
	move.l	(A5)+,A1	; A1 => Spr x Coors
	add.l	#(16*64),A0	; A0 => Spr x Bitmap

	move.w	#$90,d0
	move.w	#$D0,d1
	move.w	#$20,d2
	move.w	#$0e,d3
	bsr	PutSprite

	clr.l	(a1)+
	clr.l	(a1)+

; ---
	move.l	(A5)+,A1	; A1 => Spr x Coors
	add.l	#(16*64),A0	; A0 => Spr x Bitmap

	move.w	#$A8,d0
	move.w	#$D0,d1
	move.w	#$20,d2
	move.w	#$0f,d3
	bsr	PutSprite

	clr.l	(a1)+
	clr.l	(a1)+


	RTS


; D0: X
; D1: Y
; D2: Height
; A0: Sprite GFX PTR
; A1: Sprites-Control PTR
PutSprite:
	move.b	D1,(a1)+	; YX--
	move.b	D0,(a1)+
	clr.w	(a1)+

	clr.w	(a1)+		; Palette Index
	clr.b	(a1)+
	lsl.b	#4,d3
	or.b	#1,d3	; enable SAGA Sprite
	move.b	D3,(A1)+

	add.w	d2,d1		; endY
	move.b	d1,(a1)+
	clr.b	(a1)+
	clr.w	(a1)+
	
	move.l	A0,(A1)+	; Spr GFX
	rts



************************************************

	cnop	0,8
SpritesBufNow:		dc.l	SpritesBufA
SpritesBufNext:		dc.l	SpritesBufB
SpritesBufToRender:	dc.l	0


SprCurrentY:	ds.w	16*2


iSprBufCoors:	EQU	0
iSprBufBitmap:	EQU	17*4

SpritesBufA:
	dc.l	SpriteBufer+(16*8*0)	; spr 0 control
	dc.l	SpriteBufer+(16*8*1)	; spr 1 control
	dc.l	SpriteBufer+(16*8*2)	; spr 2 control
	dc.l	SpriteBufer+(16*8*3)	; spr 3 control
	dc.l	SpriteBufer+(16*8*4)	; spr 4 control
	dc.l	SpriteBufer+(16*8*5)	; spr 5 control
	dc.l	SpriteBufer+(16*8*6)	; spr 6 control
	dc.l	SpriteBufer+(16*8*7)	; spr 7 control
	dc.l	SpriteBufer+(16*8*8)	; spr 8 control
	dc.l	SpriteBufer+(16*8*9)	; spr 9 control
	dc.l	SpriteBufer+(16*8*10)	; spr A control
	dc.l	SpriteBufer+(16*8*11)	; spr B control
	dc.l	SpriteBufer+(16*8*12)	; spr C control
	dc.l	SpriteBufer+(16*8*13)	; spr D control
	dc.l	SpriteBufer+(16*8*14)	; spr E control
	dc.l	SpriteBufer+(16*8*15)	; spr F control
	dc.l	0
	dc.l	SpriteBufer+(16*8*32)	; sprs bitmaps

SpritesBufB:
	dc.l	SpriteBufer+(16*8*16)	; spr 0 control
	dc.l	SpriteBufer+(16*8*17)	; spr 1 control
	dc.l	SpriteBufer+(16*8*18)	; spr 2 control
	dc.l	SpriteBufer+(16*8*19)	; spr 3 control
	dc.l	SpriteBufer+(16*8*20)	; spr 4 control
	dc.l	SpriteBufer+(16*8*21)	; spr 5 control
	dc.l	SpriteBufer+(16*8*22)	; spr 6 control
	dc.l	SpriteBufer+(16*8*23)	; spr 7 control
	dc.l	SpriteBufer+(16*8*24)	; spr 8 control
	dc.l	SpriteBufer+(16*8*25)	; spr 9 control
	dc.l	SpriteBufer+(16*8*26)	; spr A control
	dc.l	SpriteBufer+(16*8*27)	; spr B control
	dc.l	SpriteBufer+(16*8*28)	; spr C control
	dc.l	SpriteBufer+(16*8*29)	; spr D control
	dc.l	SpriteBufer+(16*8*30)	; spr E control
	dc.l	SpriteBufer+(16*8*31)	; spr F control
	dc.l	0
	dc.l	SpriteBufer+(16*8*32)+(64*16*64)	; sprs bitmaps



pepi:	dc.l	0


	CNOP	0,8

PrintSprites_SAGA:

;	lea	pepi,A0
;	subq.l	#1,(a0)
;	bcs.s	.doAll
;	rts
;.doAll:
;	move.l	#4,pepi


; order sprites from MIN-Y to MAX-Y

	lea	SpriteCoor,A0
	move.w	#64-2,D0	; 64 Sprites to process
	move.w	D0,D1
.loop1:
	move.w	D1,D2
.loop2:
	lea	(A0,D2.w*8),A1

	move.w	(A1),D7		; current SPR
	and.w	#SprXYMask,D7

	move.w	8(A1),D6	; next SPR
	and.w	#SprXYMask,D6

	cmp.w	D7,D6
	bcc.s	.next

	move.l	(A1)+,D4
	move.l	(A1)+,D5

	move.l	(A1)+,D6
	move.l	(A1)+,D7

	move.l	D5,-(A1)
	move.l	D4,-(A1)

	move.l	D7,-(A1)
	move.l	D6,-(A1)
.next:
	dbf	D2,.loop2

	subq.w	#1,D1
	addq	#8,A0

	dbf	D0,.loop1





;	moveq	#0,d1
;	moveq	#0,d2
;	moveq	#0,d3
;	moveq	#0,d4
;	move.l	d1,a1
;	move.l	d2,a2
;	move.l	d3,a3
;	move.l	d4,a4
;
;	lea	SpriteBufer+(16*8*32),A0
;	move.w	#((16*64*16)/32)-1,D0
;.loop:
;	movem.l	d1-d4/a1-a4,(a0)
;	add.w	#32,a0
;	dbf	d0,.loop



; reset current Y position to attatch more Sprites
	lea	SprCurrentY,A0
	clr.l	(a0)+		; spr 0 & 1
	clr.l	(a0)+		; spr 2 & 3
	clr.l	(a0)+		; spr 4 & 5
	clr.l	(a0)+		; spr 6 & 7
	clr.l	(a0)+		; spr 8 & 9
	clr.l	(a0)+		; spr A & B
	clr.l	(a0)+		; spr C & D
	clr.l	(a0)+		; spr E & F
	clr.l	(a0)+		; spr 0 & 1
	clr.l	(a0)+		; spr 2 & 3
	clr.l	(a0)+		; spr 4 & 5
	clr.l	(a0)+		; spr 6 & 7
	clr.l	(a0)+		; spr 8 & 9
	clr.l	(a0)+		; spr A & B
	clr.l	(a0)+		; spr C & D
	clr.l	(a0)+		; spr E & F



	move.l	SpritesBufNext,A2		; table with all Spr Coors pointers
	lea	iSprBufCoors(A2),A2
	move.l	#$ff000000,d1
	moveq	#0,d2
	moveq	#16-1,D0
.loopA:
	move.l	(A2)+,A0
	move.l	d1,(A0)+
	move.l	d2,(A0)+
	move.l	d1,(A0)+
	move.l	d2,(A0)+
	move.l	d1,(A0)+
	move.l	d2,(A0)+
	move.l	d1,(A0)+
	move.l	d2,(A0)+
	dbf	d0,.loopA





; Draw all Sprites in Fast-RAM

	move.l	SpritesBufNext,A0		; table with all Spr Coors pointers
	move.l	iSprBufBitmap(A0),A0


	lea	SpriteCoor,A4

	move.w	#64-1,D0	; 64 Sprites to proccess
.loopSprite:
	moveq	#0,D1
	move.w	(A4),D1		; Coor Y del Sprite
	and.w	#SprXYMask,D1
	beq	.skipSprite
	cmp.w	#64+224,D1	; is Y outside of max-bottom?
	bcc	.skipSprite
;	bcs.s	.priSprCon1
;	move.w	#64+224,D1	; force Y to max-bottom
;.priSprCon1:


	sub.w	#$10,D1		; TEMPORAL
	bcs	.skipSprite	; TEMPORAL


	moveq	#0,d3
	move.w	2(A4),D3	; Coor X del Sprite
	and.w	#SprXYMask,D3
	beq	.skipSprite
	cmp.w	#32+256,D3	; is X outside of max-right?
	bcc	.skipSprite
;	bcs.s	.priSprCon2
;	move.w	#32+256,D3	; force X to max-right
;.priSprCon2:
	



	moveq.l	#0,D2		; Height calculation
	move.b	6(A4),D2
	lsr.w	#4,D2
	and.w	#$0003,D2
	cmp.w	#$0002,D2
	bne.s	.heightCalculated
	moveq.w	#3,D2		; height = 64 pixels
.heightCalculated:




	move.l	SpritesBufNext,A2
	lea	iSprBufCoors(A2),A2	; Tab pointers to Sprites Coors

	lea	SprCurrentY,A1
	moveq	#16-1,D6		; 16 sprites channels
.loopF:
	cmp.w	(A1),D1
	bcc.s	.contF

	ADDQ	#4,A1
	ADDQ	#4,A2
	dbf	D6,.loopF
	bra	.skipSprite

.contF:
	add.w	d1,(A1)
	move.w	d2,d6
	addq.w	#1,d6
	lsl.w	#4,d6
	addq.w	#1,d6		; skip "empty" line between two sprites
	add.w	d6,(A1)+

	move.w	(A1),d6
	addq.w	#1,(A1)

	move.l	(A2),A1
	lsl.w	#4,D6
	add.w	d6,A1

; ----------------


	moveq	#0,D6

;	add.w	#$10,d1
	move.b	d1,(A1)		; Y

	cmp.w	#$100,d1
	bcs.s	.skip0
	or.b	#$04,d6
.skip0:
	add.w	#$10,d1
	move.w	#$10,d4
	mulu	d2,d4
	add.w	d4,d1
	move.b	d1,8(A1)	; End-Y

	cmp.w	#$100,d1
	bcs.s	.skip1
	or.b	#$02,d6
.skip1:

	lsr.w	#1,d3
	bcc.s	.skip2
	or.b	#$01,d6
.skip2:
	add.w	#$40,d3
	move.b	d3,1(A1)	; X

	move.b	d6,9(A1)	; X (low bit 0)

	move.l	A0,12(A1)	; Spr Bitmap



	move.w	6(A4),D6	; Palete Index
	and.w	#$000f,D6
	lsl.w	#4,d6
	or.b	#1,d6
	move.b	d6,7(A1)	; Palete Index





; ----------------

	move.w	4(A4),D6	; pattern
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


	move.l	A0,A1
	move.l	#16,d4

	btst	#7,6(A4)	; flip Y?
	beq.s	.noFlipY
	move.l	d2,d7
	addq.l	#1,d7
	lsl.l	#8,d7
	add.l	d7,A0
	sub.l	d4,A0
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
; D5 = 
; D6 = pattern height
; D7 = used

	moveq	#(16)-1,D6	; 16 pixels de alto a copiar
.loopPattern:
	moveq	#0,D7         
	move.w	(A5),D7       
	move.w	(A3,D7.L*2),D7
	move.w	D7,(A0)	; bpl-0
	clr.w	2(a0)

	moveq	#0,D7         
	move.w	32(A5),D7     
	move.w	(A3,D7.L*2),D7
	move.w	D7,4(A0)	; bpl-1
	clr.w	6(a0)

	moveq	#0,D7         
	move.w	64(A5),D7     
	move.w	(A3,D7.L*2),D7
	move.w	D7,8(A0)	; bpl-2
	clr.w	10(a0)

	moveq	#0,D7         
	move.w	96(A5),D7     
	move.w	(A3,D7.L*2),D7	; bpl-3
	move.w	D7,12(A0)  
	clr.w	14(a0)


	btst	#0,6(A4)		; 32 pixels de ancho?
	beq.s	.no32pixels


	moveq	#0,D7         
	move.w	(A6),D7       
	move.w	(A3,D7.L*2),D7
	move.w	D7,2(A0)	; bpl-0

	moveq	#0,D7         
	move.w	32(A6),D7     
	move.w	(A3,D7.L*2),D7
	move.w	D7,6(A0)	; bpl-1

	moveq	#0,D7         
	move.w	64(A6),D7     
	move.w	(A3,D7.L*2),D7
	move.w	D7,10(A0)	; bpl-2

	moveq	#0,D7         
	move.w	96(A6),D7     
	move.w	(A3,D7.L*2),D7
	move.w	D7,14(A0)	; bpl-3
.no32pixels:


; Next Line
	addq.l	#2,A5			; Source: Siguiente linea del pattern
	addq.l	#2,A6			; Source: Siguiente linea del pattern
	add.l	D4,A0			; Target: Siguiente linea del buffer de sprites
	dbf	D6,.loopPattern


; Next Vertical
	add.l	#128-32+128,A5		; Source: VRAM: Siguiente Pattern
	add.l	#128-32+128,A6		; Source: VRAM: Siguiente Pattern

	dbf	D2,.loopHeight

	move.l	A1,A0
	add.l	#16*64,A0

.skipSprite:
	addq.l	#8,A4			; Siguiente sprite a procesar

	dbf	D0,.loopSprite

.noMoreSpritesLeft:


; ----------------

	move.l	SpritesBufNext,A2		; table with all Spr Coors pointers
	lea	iSprBufCoors(A2),A2

	lea	SprCurrentY+2,A1

	
	move.l	#$fe000000,d1
	moveq	#0,d2
	moveq	#16-1,D0
.loopB:
	move.w	(A1)+,D6
	addq	#2,A1
	lsl.w	#4,D6

	move.l	(A2)+,A0
	add.w	D6,A0

	move.l	d1,(A0)+
	move.l	d2,(A0)+
	move.l	d2,(A0)+
	move.l	d2,(A0)+
	dbf	d0,.loopB






	move.l	SpritesBufNext,SpritesBufToRender

	movem.l	SpritesBufNow,d0/d1
	exg.l	d0,d1
	movem.l	d0/d1,SpritesBufNow



	RTS




************************************************





	CNOP	0,8
PonePaleta_SAGA:

	LEA	VDP_Pal,A0
	LEA	AllRGBs+2,A1
	MOVEq.W	#0,D4
	MOVE.W	#(512)-1,D0
.ponPalBuc2:
	MOVE.W	(A0)+,D1

	MOVE.L	D1,D2
	MOVE.L	D1,D3

;	LSL.L	#7,D3		; G
;	AND.L	#$0000E000,D3

;	LSL.L	#8,D2		; R
;	LSL.L	#5,D2		; R
;	AND.L	#$00E00000,D2

;	LSL.W	#5,D1		; B
;	AND.L	#$000000E0,D1


	LSL.L	#6,D2		; R
	AND.L	#$000E00,D2
	LSL.L	#6,D2
	LSL.L	#6,D2

	LSR.L	#1,D3		; G
	AND.L	#$0000E0,D3
	LSL.L	#8,D3

	LSL.L	#1,D1		; B
	AND.L	#$00000E,D1
	LSL.L	#4,D1


	OR.L	D2,D1
	OR.L	D3,D1
	OR.L	D4,D1

	MOVE.L	D1,(A1)+

	ADDQ.W	#2,A1
	add.l	#$01000000,D4
	
	DBF	D0,.ponPalBuc2

	rts



; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-




