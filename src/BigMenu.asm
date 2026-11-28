; BigMenu.asm: the big RTG menu (NO_BIGMENU=0), as AmiGameBoy 2.5's and AmiMasterGear's: the
; GadToolsBox menu opened in the output-sized Picasso96 mode, 1920x1080 (then 1280x720), with the
; shared kit rtgmenu.s (MIT, rtgmenu.LICENSE): the 640x212 layout in a 4:3 area (1440x1080 /
; 960x720) at the top, straight under the title bar, positions and sizes scaled by X 9/4, Y 9/2 at
; 1080 (X 3/2, Y 3 at 720); frames, bevels and text drawn at the screen's own size in the Pixel
; font (rmfont_18x36 / rmfont_12x24, rtg-framework tools/menufont.py, z00p); the logo and the four
; Joy type pictures redrawn at that resolution (src/data/hires_*.bin: the logo by
; tools/bigmenu_art.py, the Joy type pictures are AmiGameBoy's: the same four pictures in all
; three). The menu's tick and Amiga key are drawn to the font's size. The selectors (cycle gadgets
; and their chooser.gadget lists) are trimmed to the text's height (RmnTrimCycles).
; Intuition and GadTools still draw and run everything: before SetupScreen this file makes
; the menu's numbers and font bigger (the screen tags, the window table, the NewGadget tables, the
; IntuiText chains, the Insert requester's place, the font, the pictures). The menu's drawing calls
; already go through RTG.asm's Tall* helpers: with the big menu on, TallBevel draws through
; bm_bevel (the bevel at its scaled place and size) and TallImage through bm_drawimage; TallNG and
; TallIText have nothing to do (their tables are scaled here). Only the menu: the game keeps its
; own screens (RTG.asm, the AGA display).
;
; Used where the menu would go on RTG (RtgStart, RTG wanted): instead of the tall menu (TALLLINES).
; Settings in PROGDIR:AmiPCEngine.config (plain text, lines "Key = Value", any case):
;   Menu = Classic	the menu as before (the tall menu on a 424+ line mode, else 640x212)
; No 1920x1080 or 1280x720 P96 mode, or a screen of it that cannot open, or the menu's tables not as
; expected: the menu as before, untouched.
;
; Hooks: RtgStart calls bm_init (DOS is safe there: the Workbench start-up message was taken and
; the prefs read before it); TallBevel and TallImage branch to bm_bevel and bm_drawimage when
; bm_on; Quitar calls bm_exit after CloseDownScreen.
; BigMenuDbg (test): PROGDIR:bigmenu.log rewritten at each step (step, ModeID, width, height,
; depth, X and Y scales, font height): 0 entered, 1 config read, 2 libraries, 3 mode, 4 scales,
; 5 test screen, 7 font, 8 tables scaled, $10 first picture drawn, $20 Quit.
; BigMenu720 (test): the 720 fallback straight away.

	IFND	BigMenuDbg
BigMenuDbg=0
	ENDC
	IFND	BigMenu720
BigMenu720=0
	ENDC

BMSTEP	MACRO
	IFNE	BigMenuDbg
	move.l	#\1,bm_dbg
	jsr	bm_dbgw
	ENDC
	ENDM

BM_LH		=212			; the layout's height for RmnSetup
BM_DBGN		=8			; BigMenuDbg: longs in the log line
BM_WINS		=(ImpErrorHeight+2-MainMenuLeft)/8	; window Left/Top/Width/Height, contiguous
	IFNE	(ImpErrorHeight+2-MainMenuLeft)-BM_WINS*8
	FAIL	"window table not contiguous"
	ENDC

	SECTION	BigMenuCode,CODE
bm_init:
	movem.l	d0-d7/a0-a6,-(sp)
	sf	bm_on
	BMSTEP	0
	bsr	bm_config		; "Menu = Classic"?
	BMSTEP	1
	tst.b	bm_classic
	bne	.x
	bsr	bm_tagsok		; the screen and window tags as expected?
	beq	.x
	move.l	4.w,a6
	lea	bm_gfxn(pc),a1
	moveq	#39,d0
	jsr	-552(a6)		; OpenLibrary
	move.l	d0,RmnGfx
	beq	.close
	lea	bm_intn(pc),a1
	moveq	#39,d0
	jsr	-552(a6)
	move.l	d0,RmnInt
	beq	.close
	lea	bm_p96n(pc),a1
	moveq	#2,d0
	jsr	-552(a6)
	move.l	d0,RmnP96
	beq	.close
	BMSTEP	2
	IFNE	BigMenu720
	move.l	#720,d0			; test: the 720 fallback straight away
	ELSE
	move.l	#1080,d0
	ENDC
.trysz:	move.l	d0,bm_want		; 1080, then 720 when 1080 has no mode or no screen
	jsr	RmnFind			; d0 ModeID, d1/d2 size, d3 depth
	movem.l	d0-d3,bm_mode
	tst.l	d0
	beq	.nosize
	BMSTEP	3
	move.w	#640,d4
	move.w	#BM_LH,d5
	moveq	#2,d6			; the 4:3 area
	jsr	RmnSetup
	tst.l	d0
	beq	.nosize
	BMSTEP	4
	movem.l	bm_mode,d0-d3
	jsr	RmnTryOpen		; enough board memory?
	tst.l	d0
	bne	.nosize
	BMSTEP	5
	bsr	bm_font			; every topaz 8 of the menu is the Pixel font
	tst.l	d0
	beq	.close
	BMSTEP	7
; from here on the menu is big
	st	bm_on
	bsr	bm_marks		; the menu's tick and Amiga key at the font's size
	move.w	RmnFontH,d0
	move.w	d0,bm_fy		; the font's height
	addq.w	#3,d0
	move.w	d0,RmnBar1		; window tops: under the big screen title bar
	move.w	#11,RmnBar0
	move.w	DriPens+6,RmnShine	; SHINEPEN, SHADOWPEN
	move.w	DriPens+8,RmnShadow
	movem.l	bm_mode,d0-d3		; the screen
	move.l	d1,ScreenTags+20	; SA_Width
	move.l	d2,ScreenTags+28	; SA_Height
	move.l	d3,ScreenTags+36	; SA_Depth
	move.l	d0,ScreenTags+68	; SA_DisplayID
	lea	MainMenuLeft,a0		; the windows
	moveq	#BM_WINS,d0
	moveq	#8,d1
	moveq	#1,d2
	jsr	RmnRects
	lea	bm_ngads(pc),a2		; the gadgets
	moveq	#30,d1
	moveq	#0,d2
.ng:	move.l	(a2)+,d0
	beq.s	.ngx
	move.l	d0,a0
	move.l	(a2)+,d0
	jsr	RmnRects
	bra.s	.ng
.ngx:	lea	MainMenuNGads,a0	; the main window's selectors: no taller than the text needs
	lea	MainMenuGTypes,a1
	moveq	#MainMenu_CNT,d0
	moveq	#30,d1
	jsr	RmnTrimCycles
	lea	bm_itexts(pc),a0	; the texts
	jsr	RmnITexts
	lea	InsTags,a0		; the Insert requester (its tags)
	bsr	bm_asl
	lea	bm_imgs(pc),a2		; the pictures
.im:	move.l	(a2)+,d0
	beq.s	.imx
	move.l	d0,a0
	movem.w	(a2)+,d0-d2
	bsr	bm_hires		; a redrawn copy for this size?
	bne.s	.im
	jsr	RmnImage		; else the original in blocks
	bra.s	.im
.imx:	BMSTEP	8
	bra.s	.x
.nosize:
	cmp.l	#1080,bm_want
	bne.s	.close
	move.l	#720,d0
	bra	.trysz
.close:	bsr	bm_libs			; classic: nothing changed
.x:
	IFNE	BigMenuDbg
	bsr	bm_dbgw
	ENDC
	movem.l	(sp)+,d0-d7/a0-a6
	rts

; ---- the screen tags where bm_init writes them, the main window's last tag and the
; LayoutMenus tags as built -> NE: as expected
bm_tagsok:
	cmp.l	#$80000023,ScreenTags+16	; SA_Width
	bne.s	.no
	cmp.l	#$80000024,ScreenTags+24	; SA_Height
	bne.s	.no
	cmp.l	#$80000025,ScreenTags+32	; SA_Depth
	bne.s	.no
	cmp.l	#$80000032,ScreenTags+64	; SA_DisplayID
	bne.s	.no
	moveq	#1,d0
	rts
.no:	moveq	#0,d0
	rts

; ---- the menu's font (GadToolsBox's topaz8 TextAttr pointed at it) -> D0 = 1 done, 0 none (classic)
bm_font:
	movem.l	d1/a0-a2,-(sp)
	moveq	#8,d0			; the Pixel font made for this cell
	jsr	RmnScY
	lea	bm_pix24,a2
	cmp.w	#36,d0
	bcs.s	.p
	lea	bm_pix36,a2
.p:	lea	topaz8,a0
	lea	bm_pixn(pc),a1
	jsr	RmnFontBlob
	movem.l	(sp)+,d1/a0-a2
	rts

; ---- the menu's checkmark and Amiga-key images for the font's cell (RmnMarks), given to the
; main window (WA_Checkmark, WA_AmigaKey) and to LayoutMenus (GTMN_Checkmark, GTMN_AmigaKey) by a
; TAG_MORE in the two tag lists: the Sound and Tone menus' ticks. Ink BARDETAILPEN, paper
; BARBLOCKPEN (the menu's DriPens). Anything unexpected: the system's.
bm_marks:
	movem.l	d0-d2/a0-a1,-(sp)
	cmp.l	#$80080031,MTags1	; GTMN_TextAttr, the LayoutMenus tags as built
	bne	.x
	cmp.l	#$80000093,MainMenuSC+8	; WA_NewLookMenus, the main window's last tag
	bne	.x
	tst.l	MainMenuSC+16
	bne	.x
	moveq	#8,d0
	jsr	RmnScY
	lea	bm_mk24,a0
	cmp.w	#36,d0
	bcs.s	.s
	lea	bm_mk36,a0
.s:	move.w	DriPens+18,d0		; BARDETAILPEN
	move.w	DriPens+20,d1		; BARBLOCKPEN
	lea	bm_mkbuf,a1
	move.w	#BMK_BUFSZ,d2
	jsr	RmnMarks
	tst.l	d0
	beq	.x
	move.l	MTags1+4,bm_mtags+4
	move.l	#2,MTags1		; TAG_MORE
	move.l	#bm_mtags,MTags1+4
	move.l	MainMenuSC+12,bm_wtags+4
	move.l	#2,MainMenuSC+8
	move.l	#bm_wtags,MainMenuSC+12
.x:	movem.l	(sp)+,d0-d2/a0-a1
	rts

; ---- an ASL tag list of the menu's (A0): the left, top, width and height it gives, scaled as a
; window's (into the 4:3 area, the top under the big title bar)
bm_asl:	movem.l	d0-d1/a0,-(sp)
.t:	move.l	(a0)+,d1
	beq.s	.x
	move.l	(a0)+,d0
	cmp.l	#$80080003,d1		; ASLFR_InitialLeftEdge
	bne.s	.t1
	jsr	RmnScX
	add.w	RmnOX,d0
	bra.s	.put
.t1:	cmp.l	#$80080004,d1		; ASLFR_InitialTopEdge: under the bar as the windows
	bne.s	.t2
	sub.w	RmnBar0,d0
	bpl.s	.t1a
	moveq	#0,d0
.t1a:	jsr	RmnScY
	add.w	RmnBar1,d0
	add.w	RmnOY,d0
	bra.s	.put
.t2:	cmp.l	#$80080005,d1		; ASLFR_InitialWidth
	bne.s	.t3
	jsr	RmnScX
	bra.s	.put
.t3:	cmp.l	#$80080006,d1		; ASLFR_InitialHeight
	bne.s	.t
	jsr	RmnScY
.put:	move.l	d0,-4(a0)
	bra.s	.t
.x:	movem.l	(sp)+,d0-d1/a0
	rts

; ---- A0 = one of the menu's pictures (planar data) -> NE: its redrawn copy for this size is
; RmnDrawImage's (RmnImageUse); EQ: none (RmnImage then). Keeps every register.
bm_hires:
	movem.l	d0-d1/a0-a2,-(sp)
	moveq	#4,d1			; 1080: 2 x 4 blocks
	cmp.l	#$00020004,RmnBX	; RmnBX, RmnBY
	beq.s	.sz
	moveq	#8,d1			; 720: 1 x 2
	cmp.l	#$00010002,RmnBX
	bne.s	.no
.sz:	lea	bm_hrtab,a2
.f:	move.l	(a2),d0
	beq.s	.no
	cmp.l	a0,d0
	beq.s	.use
	lea	12(a2),a2
	bra.s	.f
.use:	move.l	(a2,d1.w),a1
	jsr	RmnImageUse
	tst.l	d0
	bra.s	.x
.no:	moveq	#0,d0
.x:	movem.l	(sp)+,d0-d1/a0-a2
	rts

; close the libraries (classic menu, or at the end)
bm_libs:
	movem.l	d0-d1/a0-a1/a6,-(sp)
	move.l	4.w,a6
	lea	RmnGfx,a0
	moveq	#4-1,d1			; RmnGfx, RmnInt, RmnP96, RmnDisk
.l:	move.l	(a0),d0
	beq.s	.n
	clr.l	(a0)
	move.l	a0,-(sp)
	move.l	d0,a1
	jsr	-414(a6)		; CloseLibrary
	move.l	(sp)+,a0
.n:	addq.l	#4,a0
	dbf	d1,.l
	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts

; ---- TallBevel with the big menu on: a GadToolsBox bevel (A0 = RastPort, A1 = DrawBevelBoxA's
; tags, A6 = GadToolsBase, D0/D1 = layout x, y + the window border D4/D5, D2/D3 = layout w, h)
; drawn by GadTools at its scaled place and size (thin lines, the screen's own).
bm_bevel:
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	d3,d7			; d7 = h
	move.w	d4,RmnBl		; the window's border
	move.w	d5,RmnBt
	sub.w	d4,d0			; d0 = x
	sub.w	d5,d1
	move.w	d1,d5			; d5 = y
	move.w	d2,d1
	jsr	RmnSpX
	move.w	d1,d2			; d2 = w'
	jsr	RmnScX
	add.w	RmnBl,d0
	move.w	d0,d4			; d4 = x'
	move.w	d5,d0
	move.w	d7,d1
	jsr	RmnSpY
	move.w	d1,d3			; d3 = h'
	jsr	RmnScY
	add.w	RmnBt,d0
	move.w	d0,d1			; d1 = y'
	move.w	d4,d0
	ext.l	d0
	ext.l	d1
	ext.l	d2
	ext.l	d3
	jsr	-120(a6)		; DrawBevelBoxA
	movem.l	(sp)+,d0-d7/a0-a6
	rts

; ---- TallImage with the big menu on: the menu's DrawImage calls (A6 = Intuition): A0 = RastPort,
; A1 = Image, D0 = x in the window, D1 = y in the window + the screen font's height (the menu's
; convention). The picture's redrawn (or scaled) copy at the scaled place inside the window's
; border; the 4:3 side borders drawn again (cheap); the menu strip's labels in one column
; (RmnMenuAlign).
bm_drawimage:
	movem.l	d0-d3/a0-a2,-(sp)
	move.l	MainMenuWnd,d0
	beq.s	.na
	move.l	d0,a0
	move.l	MainMenuMenus,d0
	beq.s	.na
	move.l	d0,a1
	jsr	RmnMenuAlign
.na:	movem.l	(sp),d0-d3/a0-a2	; the arguments again
	IFNE	BigMenuDbg
	cmp.l	#$10,bm_dbg
	bcc.s	.logd
	BMSTEP	$10
.logd:
	ENDC
	move.l	Scr,a0
	jsr	RmnBorders
	moveq	#0,d2
	move.b	36(a0),d2		; sc_WBorLeft = the window's BorderLeft
	moveq	#0,d3
	move.b	35(a0),d3		; sc_WBorTop
	add.w	bm_fy,d3
	addq.w	#1,d3			; the window's BorderTop (title bar)
	sub.w	d2,d0			; x inside the border
	sub.w	d3,d1			; y inside it: y + font = y + 8 at 1x, so y - 1 - WBorTop
	move.l	16(sp),a0		; the RastPort
	jsr	RmnDrawImage
	movem.l	(sp)+,d0-d3/a0-a2
	rts

; ---- after CloseDownScreen (hook in Quitar): the pictures, the font, the libraries
bm_exit:
	tst.b	bm_on
	beq.s	.x
	BMSTEP	$20
	jsr	RmnFreeAll
	bsr	bm_libs
	sf	bm_on
.x:	rts

; ---- PROGDIR:AmiPCEngine.config -> bm_classic ("Menu = Classic"). No file, no line: the big menu.
bm_config:
	movem.l	d0-d4/a0-a2/a6,-(sp)
	sf	bm_classic
	bsr	bm_cfgread		; d3 = bytes in bm_buf
	ble	.x
	lea	bm_buf,a0
	clr.b	(a0,d3.l)		; the end
.line:	move.b	(a0),d0			; a line: blanks, the key, blanks, "=", blanks, the value
	beq	.x
	cmp.b	#" ",d0
	beq.s	.sk
	cmp.b	#9,d0
	bne.s	.key
.sk:	addq.l	#1,a0
	bra.s	.line
.key:	lea	bm_kmenu(pc),a1
	bsr.s	.word
	beq.s	.next
	move.b	(a0),d0			; "Classic"
	or.b	#$20,d0
	cmp.b	#"c",d0
	bne.s	.next
	st	bm_classic
.next:	move.b	(a0)+,d0		; to the next line
	beq.s	.x
	cmp.b	#10,d0
	bne.s	.next
	bra.s	.line
.x:	movem.l	(sp)+,d0-d4/a0-a2/a6
	rts
; A0 at a line's first word, A1 = a key -> NE: it is the key, A0 after "=" and blanks
.word:	move.b	(a1)+,d1
	beq.s	.wend
	or.b	#$20,d1
	move.b	(a0),d0
	or.b	#$20,d0
	cmp.b	d1,d0
	bne.s	.wno
	addq.l	#1,a0
	bra.s	.word
.wend:	bsr.s	.blank
	cmp.b	#"=",(a0)
	bne.s	.wno
	addq.l	#1,a0
	bsr.s	.blank
	moveq	#1,d0
	rts
.wno:	moveq	#0,d0
	rts
.blank:	cmp.b	#" ",(a0)
	beq.s	.b1
	cmp.b	#9,(a0)
	bne.s	.b2
.b1:	addq.l	#1,a0
	bra.s	.blank
.b2:	rts

; the config file into bm_buf -> D3 = its bytes (0: none, empty, or unreadable; -1: too big).
; No requesters (pr_WindowPtr -1). Keeps D0-D2/A0-A6.
bm_cfgread:
	movem.l	d0-d2/d4-d5/a0-a1/a5-a6,-(sp)
	bsr	bm_noreq
	moveq	#0,d5
	move.l	_DosBase,d0
	beq.s	.x
	move.l	d0,a6
	move.l	#bm_cfgn,d1
	move.l	#1005,d2		; MODE_OLDFILE
	jsr	-30(a6)			; Open
	move.l	d0,d4
	beq.s	.x
	move.l	d4,d1
	move.l	#bm_buf,d2
	move.l	#BM_BUFSZ,d3
	jsr	-42(a6)			; Read
	move.l	d0,d5
	move.l	d4,d1
	jsr	-36(a6)			; Close
	cmp.l	#BM_BUFSZ,d5		; full: maybe more, too big
	bcs.s	.x
	moveq	#-1,d5
.x:	bsr	bm_req
	move.l	d5,d3
	movem.l	(sp)+,d0-d2/d4-d5/a0-a1/a5-a6
	rts

; no DOS requesters while the config is read (pr_WindowPtr -1), then as it was
bm_noreq:
	movem.l	d0-d1/a0-a1/a6,-(sp)
	sub.l	a1,a1
	move.l	4.w,a6
	jsr	-294(a6)		; FindTask
	move.l	d0,a0
	move.l	$b8(a0),bm_winptr	; pr_WindowPtr
	moveq	#-1,d0
	move.l	d0,$b8(a0)
	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts
bm_req:	movem.l	d0-d1/a0-a1/a6,-(sp)
	sub.l	a1,a1
	move.l	4.w,a6
	jsr	-294(a6)
	move.l	d0,a0
	move.l	bm_winptr,$b8(a0)
	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts

	IFNE	BigMenuDbg
; test: PROGDIR:bigmenu.log = step, ModeID, width, height, depth, X, Y, font height (hex)
bm_dbgw:
	movem.l	d0-d7/a0-a6,-(sp)
	movem.l	bm_mode,d0-d3
	movem.l	d0-d3,bm_dbg+4
	move.l	RmnSXn,bm_dbg+4*5	; SXn, SXd
	move.l	RmnSYn,bm_dbg+4*6	; SYn, SYd
	moveq	#0,d0
	move.w	RmnFontH,d0
	move.l	d0,bm_dbg+4*7
	lea	bm_dbg,a0
	lea	bm_dbgt,a1
	moveq	#BM_DBGN-1,d2
.l:	move.l	(a0)+,d0
	moveq	#8-1,d1
.h:	rol.l	#4,d0
	move.b	d0,d3
	and.b	#15,d3
	add.b	#"0",d3
	cmp.b	#"9",d3
	bls.s	.d
	addq.b	#7,d3
.d:	move.b	d3,(a1)+
	dbf	d1,.h
	move.b	#" ",(a1)+
	dbf	d2,.l
	move.b	#10,-1(a1)
	move.l	_DosBase,a6
	move.l	#bm_dbgname,d1
	move.l	#1006,d2		; MODE_NEWFILE
	jsr	-30(a6)
	move.l	d0,d4
	beq.s	.x
	move.l	d4,d1
	move.l	#bm_dbgt,d2
	moveq	#BM_DBGN*9,d3
	jsr	-48(a6)			; Write
	move.l	d4,d1
	jsr	-36(a6)
.x:	movem.l	(sp)+,d0-d7/a0-a6
	rts
bm_dbgname:	dc.b	"PROGDIR:bigmenu.log",0
	even
	ENDC

bm_ngads:
	dc.l	MainMenuNGads,MainMenu_CNT,HelpPageNGads,HelpPage_CNT
	dc.l	AboutNGads,About_CNT,MC68020NGads,MC68020_CNT
	dc.l	OverwriteNGads,Overwrite_CNT,QuitNGads,Quit_CNT
	dc.l	CheatNGads,Cheat_CNT,ImpErrorNGads,ImpError_CNT,0
bm_itexts:
	dc.l	MainMenuText0,HelpPageText0,AboutText0,MC68020Text0,OverwriteText0
	dc.l	QuitText0,CheatText0,ImpErrorText0,0
bm_imgs:				; planar data, width, height, depth
	dc.l	GGLogo
	dc.w	325,51,3
	dc.l	GBTeclado
	dc.w	47,16,3
	dc.l	GBJoyStick
	dc.w	47,16,3
	dc.l	GBJoypad
	dc.w	47,16,3
	dc.l	GBCD32
	dc.w	47,16,3
	dc.l	0
bm_gfxn:	dc.b	"graphics.library",0
bm_intn:	dc.b	"intuition.library",0
bm_p96n:	dc.b	"Picasso96API.library",0
bm_pixn:	dc.b	"rmpixel.font",0	; the Pixel font, made at run time (never on disk)
bm_cfgn:	dc.b	"PROGDIR:AmiPCEngine.config",0
bm_kmenu:	dc.b	"Menu",0		; the config's word
	even
	include	"rtgmenu.s"

	SECTION	BigMenuData,DATA
bm_on:		dc.b	0		; the menu is big
bm_classic:	dc.b	0		; "Menu = Classic"
bm_fy:		dc.w	8		; the menu font's height
	cnop	0,4
bm_mode:	dc.l	0,0,0,0		; ModeID, width, height, depth
bm_want:	dc.l	0		; the height asked: 1080, then 720
bm_winptr:	dc.l	0
	include	"rtgmenu_data.s"
	cnop	0,4
bm_pix36:	incbin	"data/rmfont_18x36.bin"	; rtg-framework tools/menufont.py (z00p)
	cnop	0,4
bm_pix24:	incbin	"data/rmfont_12x24.bin"
	cnop	0,4
bm_mk36:	incbin	"data/rmmark_18x36.bin"	; the menu's tick and Amiga key (menufont.py)
	cnop	0,4
bm_mk24:	incbin	"data/rmmark_12x24.bin"
bm_mtags:	dc.l	$80080031,0		; GTMN_TextAttr (the menu's)
	dc.l	$80080041,RmnChkImg	; GTMN_Checkmark
	dc.l	$80080042,RmnKeyImg	; GTMN_AmigaKey
	dc.l	0
bm_wtags:	dc.l	$80000093,0		; WA_NewLookMenus (the menu's)
	dc.l	$8000006D,RmnChkImg	; WA_Checkmark
	dc.l	$80000094,RmnKeyImg	; WA_AmigaKey
	dc.l	0
	cnop	0,4
bm_hrtab:				; the picture, its redraw at 1080, at 720
	dc.l	GGLogo,bm_hlogo1,bm_hlogo7
	dc.l	GBTeclado,bm_hkey1,bm_hkey7
	dc.l	GBJoyStick,bm_hstick1,bm_hstick7
	dc.l	GBJoypad,bm_hpad1,bm_hpad7
	dc.l	GBCD32,bm_hcd1,bm_hcd7
	dc.l	0
	cnop	0,4			; tools/bigmenu_art.py; rtg-framework tools/agbart (z00p)
bm_hlogo1:	incbin	"data/hires_pcelogo_1080.bin"
bm_hkey1:	incbin	"data/hires_teclado_1080.bin"
bm_hstick1:	incbin	"data/hires_joystick_1080.bin"
bm_hpad1:	incbin	"data/hires_joypad_1080.bin"
bm_hcd1:	incbin	"data/hires_cd32_1080.bin"
bm_hlogo7:	incbin	"data/hires_pcelogo_720.bin"
bm_hkey7:	incbin	"data/hires_teclado_720.bin"
bm_hstick7:	incbin	"data/hires_joystick_720.bin"
bm_hpad7:	incbin	"data/hires_joypad_720.bin"
bm_hcd7:	incbin	"data/hires_cd32_720.bin"
	even

	SECTION	BigMenuBss,BSS
	IFNE	BigMenuDbg
bm_dbg:		ds.l	BM_DBGN
bm_dbgt:	ds.b	BM_DBGN*9
	ENDC
BM_BUFSZ	=2048
bm_buf:		ds.b	BM_BUFSZ+2
	SECTION	BigMenuChip,BSS_C
BMK_BUFSZ	=1024			; the tick and Amiga key, 2 planes each (720 bytes at 1080)
bm_mkbuf:	ds.b	BMK_BUFSZ
