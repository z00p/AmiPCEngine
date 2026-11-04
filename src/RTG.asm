; RTG.asm: 16-bit Picasso96 display for play (the RTG section of CHANGES.md).
; Takeover design after AmiMSX's RTG: the play screen is opened and its bitmap
; address read with the OS alive (RtgPlayOpen, before CongelaAMIGA); in play the
; whole PCE frame is composed in fast RAM (RtgFrame, after PCE_Start) and the
; changed lines are copied to the framebuffer at the next Amiga vertical blank
; (RtgCopy). No OS or P96 call in play; the colour lookup is ours.
; Only assembled with NO_RTG=0 (included at the end of Main.asm, own sections).

	IFND	RTGFORCE	; test builds: RTG without the ToolType / CLI word
RTGFORCE=0
	ENDC
	IFND	RTGSHOT		; AutoExit test builds: write the RTG frame(s) to PROGDIR:rtgshot*.raw
RTGSHOT=0
	ENDC
	IFND	RTGMENUFAIL	; test builds: RtgMenuScreen takes the native fallback at once
RTGMENUFAIL=0
	ENDC
	IFND	NO_RTGMENU	; 1 = the menu screen stays on AGA when RTG is on
NO_RTGMENU=0
	ENDC
	IFND	ScanCost	; RTGSHOT test builds: CIA-B TOD lines spent in RtgCopy, calls, lines copied -> rtgstat.txt
ScanCost=0
	ENDC
	IFND	RtgShotA	; with RTGSHOT: also keep the composed frame of these PCE frames
RtgShotA=0
	ENDC
	IFND	RtgShotB
RtgShotB=0
	ENDC
	IFND	RtgShotC
RtgShotC=0
	ENDC

RTGMW	= 512		; widest picture (pixels); compose line = RTGMW longs
RTGLINES = 240		; picture lines
RTGSPRMAX = 16
RTGPLMAX = 2048		; VCE writes kept a frame (mid-frame palette)
	IFEQ	NO_RTGFIX
RTGCRMAX = 264		; CR writes kept a frame (one per line: a write on the same line replaces it)
	ELSE
RTGCRMAX = 256		; CR writes kept a frame
	ENDC

RTGCOMPSZ = RTGMW*RTGLINES*4	; the big buffers (AllocMem in RtgStart unless NO_RTGFIX)
RTGOLDSZ = RTGMW*RTGLINES*2
RTGTCSZ = 2048*64
RTGSCSZ = 512*256
	IFEQ	ScanOff
RTGSLSZ = 65536*2		; scanline table: screen pixel -> dimmed pixel (or quarter, Blended)
RTGBIGSZ = RTGCOMPSZ+RTGOLDSZ+RTGTCSZ+RTGSCSZ+RTGSLSZ
	ELSE
RTGBIGSZ = RTGCOMPSZ+RTGOLDSZ+RTGTCSZ+RTGSCSZ
	ENDC
; RtgBuf buffer,An: the address of a big buffer
RtgBuf:	MACRO
	IFEQ	NO_RTGFIX
	MOVE.L	\1P,\2
	ELSE
	LEA	\1,\2
	ENDC
	ENDM

P96IDA_WIDTH=0
P96IDA_HEIGHT=1
P96IDA_DEPTH=2
P96IDA_RGBFORMAT=5
P96IDA_ISP96=6
RGBFB_CLUT=1

	SECTION	RtgCode,CODE

; ---------------------------------------------------------------------------
; RtgStart: program start, OS alive. A0 = WBStartup message (Workbench) or 0
; (CLI). RTG is wanted with the ToolType RTG on the icon, the word RTG on the
; command line, or a RTGFORCE build. Then the play and menu modes are looked
; for; without P96 or a play mode RTG is dropped (the AGA build exactly).
	CNOP	0,4
RtgStart:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.L	A0,A2
	MOVE.L	4.W,A6
	LEA	RtgDosNom(PC),A1
	MOVEQ	#36,D0
	JSR	-552(A6)		; OpenLibrary
	MOVE.L	D0,RtgDos
	BEQ	.x
	MOVE.B	#1,RtgStage
	IFNE	RTGFORCE
	ST	RtgWant
	ENDC
	MOVE.L	A2,D0
	BEQ.S	.cli
	BSR	RtgToolType
	BRA.S	.want
.cli:	BSR	RtgCliArg
.want:	TST.B	RtgWant
	BEQ	.x
	MOVE.B	#2,RtgStage
	MOVE.L	4.W,A6
	LEA	RtgGfxNom(PC),A1
	MOVEQ	#39,D0
	JSR	-552(A6)
	MOVE.L	D0,RtgGfx
	BEQ	.no
	LEA	RtgIntNom(PC),A1
	MOVEQ	#39,D0
	JSR	-552(A6)
	MOVE.L	D0,RtgInt
	BEQ	.no
	LEA	RtgP96Nom(PC),A1
	MOVEQ	#2,D0
	JSR	-552(A6)
	MOVE.L	D0,RtgP96
	BEQ	.no
	MOVE.B	#3,RtgStage
	MOVEQ	#0,D7			; the play mode
	BSR	RtgFind
	MOVE.L	D0,RtgModeID
	CMP.L	#-1,D0
	BEQ	.no
	MOVE.W	D1,RtgNModes
	MOVE.B	#4,RtgStage
	IFEQ	NO_RTGFIX
	MOVE.L	4.W,A6			; the big buffers, only now that RTG is wanted
	MOVE.L	#RTGBIGSZ,D0
	MOVE.L	#$10000,D1		; MEMF_CLEAR (any memory: fast RAM when there is any)
	JSR	-198(A6)		; AllocMem
	MOVE.L	D0,RtgBig
	BEQ	.no			; no memory: no RTG, as without P96
	MOVE.L	D0,RtgCompP
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
	ENDC
	IFEQ	NO_RTGMENU
	MOVEQ	#1,D7			; the menu's (8-bit, >= 640x212)
	BSR	RtgFind
	MOVE.L	D0,RtgMModeID
	CMP.L	#-1,D0
	BEQ.S	.x			; none: the menu stays on AGA
	LEA	ScreenTags,A0		; SA_DisplayID of the menu screen
.tag:	MOVE.L	(A0)+,D1
	BEQ.S	.x
	CMP.L	#$80000032,D1
	BEQ.S	.tagS
	ADDQ.L	#4,A0
	BRA.S	.tag
.tagS:	MOVE.L	D0,(A0)
	ST	RtgMenuOn
	IFEQ	TallOff
	BSR	RtgTallInit		; (a 424+ line mode: the menu at double height)
	ENDC
	ENDC
	BRA.S	.x
.no:	SF	RtgWant
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

; RtgQuit: end of the program (menu builds), OS alive.
RtgQuit:
	MOVEM.L	D0-D1/A0-A1/A6,-(SP)
	MOVE.L	4.W,A6
	IFEQ	TallOff
	LEA	RtgTallImgT,A0		; the pictures at double height
.ti:	TST.L	(A0)
	BEQ.S	.tix
	MOVE.L	4(A0),D0
	BEQ.S	.tin
	CLR.L	4(A0)
	MOVE.L	D0,A1
	MOVE.L	8(A0),D0
	MOVE.L	A0,-(SP)
	JSR	-210(A6)		; FreeMem
	MOVE.L	(SP)+,A0
.tin:	LEA	16(A0),A0
	BRA.S	.ti
.tix:
	ENDC
	IFEQ	NO_RTGFIX
	MOVE.L	RtgBig,D0
	BEQ.S	.nb
	CLR.L	RtgBig
	MOVE.L	D0,A1
	MOVE.L	#RTGBIGSZ,D0
	JSR	-210(A6)		; FreeMem
.nb:
	ENDC
	LEA	RtgDos,A0
	MOVEQ	#4-1,D1
.l:	MOVE.L	(A0),D0
	BEQ.S	.n
	CLR.L	(A0)
	MOVE.L	D0,A1
	MOVE.L	A0,-(SP)
	JSR	-414(A6)		; CloseLibrary
	MOVE.L	(SP)+,A0
.n:	ADDQ.L	#4,A0
	DBF	D1,.l
	MOVEM.L	(SP)+,D0-D1/A0-A1/A6
	RTS

; Workbench: ToolType RTG on the icon of the last WBArg (the program's own
; icon, or a project icon it was started from). A2 = WBStartup.
RtgToolType:
	MOVE.L	$1C(A2),D2		; sm_NumArgs
	BEQ	.x
	MOVE.L	$24(A2),A2		; sm_ArgList
	SUBQ.L	#1,D2
	LSL.L	#3,D2
	ADD.L	D2,A2			; last WBArg
	MOVE.L	4.W,A6
	LEA	RtgIconNom(PC),A1
	MOVEQ	#36,D0
	JSR	-552(A6)
	MOVE.L	D0,D5
	BEQ	.x
	MOVE.L	(A2),D1			; wa_Lock
	MOVE.L	RtgDos,A6
	JSR	-126(A6)		; CurrentDir
	MOVE.L	D0,D3			; the old one
	MOVE.L	4(A2),A0		; wa_Name
	MOVE.L	D5,A6
	JSR	-78(A6)			; GetDiskObject
	MOVE.L	D0,D4
	MOVE.L	D3,D1
	MOVE.L	RtgDos,A6
	JSR	-126(A6)		; CurrentDir back
	TST.L	D4
	BEQ.S	.cl
	MOVE.L	D4,A0
	MOVE.L	$36(A0),A0		; do_ToolTypes
	LEA	RtgTTNom(PC),A1
	MOVE.L	D5,A6
	JSR	-96(A6)			; FindToolType
	TST.L	D0
	BEQ.S	.fr0
	ST	RtgWant
.fr0:
	IFEQ	ScanOff
	MOVE.L	D4,A0			; SCANLINES=OFF|25|50|75|BLEND
	MOVE.L	$36(A0),A0
	LEA	RtgScanTTNom(PC),A1
	JSR	-96(A6)			; FindToolType
	TST.L	D0
	BEQ.S	.fr
	MOVE.L	D0,A0
	BSR	RtgScanVal
	ENDC
.fr:	MOVE.L	D4,A0
	MOVE.L	D5,A6
	JSR	-90(A6)			; FreeDiskObject
.cl:	MOVE.L	D5,A1
	MOVE.L	4.W,A6
	JSR	-414(A6)
.x:	RTS

; CLI: the word RTG (any case) in the arguments.
RtgCliArg:
	MOVE.L	RtgDos,A6
	JSR	-534(A6)		; GetArgStr
	TST.L	D0
	BEQ.S	.x
	MOVE.L	D0,A0
	IFEQ	ScanOff
	BSR	RtgScanCli		; SCANLINES=... (A0 kept)
	ENDC
	MOVEQ	#0,D2			; 1: the previous character was a letter
.l:	MOVE.B	(A0)+,D0
	BEQ.S	.x
	CMP.B	#10,D0
	BEQ.S	.x
	BSR.S	.up
	TST.B	D2
	BNE.S	.nx
	CMP.B	#82,D0			; R
	BNE.S	.nx
	MOVE.B	(A0),D0
	BSR.S	.up
	CMP.B	#84,D0			; T
	BNE.S	.nx0
	MOVE.B	1(A0),D0
	BSR.S	.up
	CMP.B	#71,D0			; G
	BNE.S	.nx0
	MOVE.B	2(A0),D0
	BSR.S	.up
	CMP.B	#65,D0
	BCS.S	.yes
	CMP.B	#90,D0
	BLS.S	.nx0
.yes:	ST	RtgWant
	RTS
.nx0:	MOVE.B	-1(A0),D0
	BSR.S	.up
.nx:	MOVEQ	#0,D2
	CMP.B	#65,D0			; A-Z: a letter
	BCS.S	.l
	CMP.B	#90,D0
	BHI.S	.l
	MOVEQ	#1,D2
	BRA.S	.l
.x:	RTS
.up:	CMP.B	#97,D0			; a-z -> A-Z
	BCS.S	.upx
	CMP.B	#122,D0
	BHI.S	.upx
	SUB.B	#32,D0
.upx:	RTS

; Best P96 mode. D7 = 0: play, a 16-bit format of RtgFmtTab: 960x540 (the
; 1080p HDMI's exact 2x), then 640x480, then the smallest that holds 352x240
; at 2x, then at 1x. D7 = 1: the menu, 8-bit CLUT of at least 640x212, 640x480
; first, else the smallest. Every mode of the list is read. D0 = ModeID or -1,
; D1 = modes seen.
RtgFind:
	MOVEQ	#-1,D6			; best key so far
	MOVEQ	#-1,D5			; its ModeID
	MOVEQ	#-1,D4			; NextDisplayInfo from INVALID_ID
	SUB.L	A4,A4			; modes seen
.next:	MOVE.L	D4,D0
	MOVE.L	RtgGfx,A6
	JSR	-732(A6)		; NextDisplayInfo
	MOVE.L	D0,D4
	CMP.L	#-1,D4
	BEQ	.done
	ADDQ.L	#1,A4
	MOVE.L	D4,D0
	MOVEQ	#P96IDA_ISP96,D1
	BSR	RtgIdAttr
	TST.L	D0
	BEQ.S	.next
	MOVE.L	D4,D0
	MOVEQ	#P96IDA_WIDTH,D1
	BSR	RtgIdAttr
	MOVE.L	D0,D2
	MOVE.L	D4,D0
	MOVEQ	#P96IDA_HEIGHT,D1
	BSR	RtgIdAttr
	MOVE.L	D0,D3
	MOVE.L	D4,D0
	MOVEQ	#P96IDA_RGBFORMAT,D1
	BSR	RtgIdAttr
	CMP.L	#2048,D2
	BHI.S	.next
	CMP.L	#2048,D3
	BHI.S	.next
	TST.W	D7
	BNE.S	.menu
	BSR	RtgFmtFind
	MOVE.L	A0,D0
	BEQ.S	.next
	MOVEQ	#0,D1			; class 0: 960x540
	CMP.W	#960,D2
	BNE.S	.c1
	CMP.W	#540,D3
	BEQ.S	.key
.c1:	MOVEQ	#1,D1			; 1: 640x480
	CMP.W	#640,D2
	BNE.S	.c2
	CMP.W	#480,D3
	BEQ.S	.key
.c2:	MOVEQ	#2,D1			; 2: 2x fits
	CMP.W	#704,D2
	BCS.S	.c3
	CMP.W	#480,D3
	BCC.S	.key
.c3:	MOVEQ	#3,D1			; 3: 1x fits
	CMP.W	#352,D2
	BCS	.next
	CMP.W	#RTGLINES,D3
	BCS	.next
	BRA.S	.key
.menu:	CMP.L	#RGBFB_CLUT,D0
	BNE	.next
	CMP.W	#640,D2
	BCS	.next
	CMP.W	#212,D3
	BCS	.next
	MOVEQ	#1,D1
	IFEQ	TallOff
	CMP.W	#TALLLINES,D3		; 1: lines for the menu at double height,
	BCC.S	.mtall
	MOVEQ	#2,D1			; 2: not
.mtall:
	ENDC
	CMP.W	#640,D2
	BNE.S	.key
	CMP.W	#480,D3
	BNE.S	.key
	MOVEQ	#0,D1
.key:	MOVE.L	D2,D0			; key = class << 24 + area
	MULU.W	D3,D0
	AND.L	#$00FFFFFF,D0
	ROR.L	#8,D1
	OR.L	D1,D0
	CMP.L	D6,D0
	BCC	.next
	MOVE.L	D0,D6
	MOVE.L	D4,D5
	BRA	.next
.done:	MOVE.L	D5,D0
	MOVE.L	A4,D1
	RTS

	IFEQ	TallOff
; The menu on RTG at double height (CHANGES.md; after AmiMSX
; 838abc6). RTG pixels are square, so the 640x212 layout came out flat in the
; top 45% of a 640x480 picture. With a menu mode of TALLLINES or more lines:
; a topaz 8 with every row doubled (amipcetall.font 16, built once with AddFont
; and left in the font list for the next run) and every y of the layout
; doubled: the screen, the windows and the file requester here; gadgets
; (TallNG), bevel boxes (TallBevel), texts (TallIText) and pictures
; (TallImage) as they are drawn. Without the memory: the layout as it was.
; OS alive (RtgStart).
TALLLINES=424
TALLFY=16		; the tall font's height
TALLWINS=(ImpErrorHeight+2-MainMenuLeft)/8	; GadToolsBox's Left/Top/Width/Height
	IFNE	(ImpErrorHeight+2-MainMenuLeft)-TALLWINS*8
	FAIL	"window table not contiguous"
	ENDC
RtgTallInit:
	MOVE.L	RtgMModeID,D0
	MOVEQ	#P96IDA_HEIGHT,D1
	BSR	RtgIdAttr
	CMP.L	#TALLLINES,D0
	BCS	.x
	MOVE.L	RtgGfx,A6
	LEA	RtgTallTA,A0
	JSR	-72(A6)			; OpenFont: still there from a run before?
	TST.L	D0
	BEQ.S	.build
	MOVE.L	D0,A1
	MOVE.L	10(A1),A0		; ln_Name
	LEA	RtgTallNom,A2
	MOVEQ	#0,D2
	CMP.W	#TALLFY,20(A1)
	BNE.S	.old
.cmp:	MOVE.B	(A0)+,D1
	CMP.B	(A2)+,D1
	BNE.S	.old
	TST.B	D1
	BNE.S	.cmp
	MOVEQ	#1,D2			; yes
.old:	JSR	-78(A6)			; CloseFont
	TST.W	D2
	BNE	.use
.build:	LEA	topaz8,A0
	JSR	-72(A6)			; OpenFont topaz 8 (ROM)
	TST.L	D0
	BEQ	.x
	MOVE.L	D0,A3
	MOVEQ	#0,D3
	MOVE.W	38(A3),D3		; tf_Modulo
	MOVE.L	D3,D0
	MULU.W	20(A3),D0		; tf_YSize rows,
	ADD.L	D0,D0			; each twice,
	ADD.L	#52+16,D0		; after the TextFont and the name.
	MOVE.L	#$10003,D1		; MEMF_PUBLIC|MEMF_CHIP|MEMF_CLEAR
	MOVE.L	4.W,A6
	JSR	-198(A6)		; AllocMem (never freed: the font stays in the list)
	MOVE.L	RtgGfx,A6
	TST.L	D0
	BEQ	.nomem
	MOVE.L	D0,A2
	MOVE.L	A3,A0
	MOVE.L	A2,A1
	MOVEQ	#52/4-1,D1
.cpy:	MOVE.L	(A0)+,(A1)+
	DBF	D1,.cpy
	LEA	RtgTallNom,A0	; (A1 = the name's place)
.nm:	MOVE.B	(A0)+,(A1)+
	BNE.S	.nm
	CLR.L	(A2)			; ln_Succ, ln_Pred
	CLR.L	4(A2)
	MOVE.W	#$0C00,8(A2)		; NT_FONT, pri 0
	LEA	52(A2),A0
	MOVE.L	A0,10(A2)		; ln_Name
	CLR.L	14(A2)			; mn_ReplyPort (a tagged font's extension)
	MOVE.W	#52,18(A2)		; mn_Length
	MOVE.W	#TALLFY,20(A2)		; tf_YSize
	AND.B	#$BF,22(A2)		; no FSF_TAGGED: no extension
	MOVE.B	23(A3),D0
	AND.B	#$FC,D0			; not ROM, not disk
	OR.B	#$40,D0			; FPF_DESIGNED
	MOVE.B	D0,23(A2)
	MOVE.W	26(A3),D0
	ADD.W	D0,D0
	ADDQ.W	#1,D0
	MOVE.W	D0,26(A2)		; tf_Baseline
	CLR.W	30(A2)			; tf_Accessors
	LEA	52+16(A2),A1
	MOVE.L	A1,34(A2)		; tf_CharData
	MOVE.L	34(A3),A0
	MOVE.W	20(A3),D2
	SUBQ.W	#1,D2
.row:	LEA	(A1,D3.W),A4		; (the copy below)
	MOVE.W	D3,D1
	SUBQ.W	#1,D1
.b:	MOVE.B	(A0,D1.W),D0
	MOVE.B	D0,(A1,D1.W)
	MOVE.B	D0,(A4,D1.W)
	DBF	D1,.b
	ADD.W	D3,A0
	ADD.W	D3,A1
	ADD.W	D3,A1
	DBF	D2,.row
	MOVE.L	A2,A1
	JSR	-480(A6)		; AddFont
	MOVE.L	A3,A1
	JSR	-78(A6)			; CloseFont
	BRA.S	.use
.nomem:	MOVE.L	A3,A1
	JSR	-78(A6)			; CloseFont
	BRA	.x
.use:	LEA	MainMenuLeft,A0		; (kept for RtgTallUndo)
	LEA	RtgTallWSv,A1
	MOVEQ	#TALLWINS*2-1,D1
.sv:	MOVE.L	(A0)+,(A1)+
	DBF	D1,.sv
	MOVE.L	topaz8,RtgTallTSv
	MOVE.L	topaz8+4,RtgTallTSv+4
	MOVE.L	InsTags+28,RtgTallASv
	MOVE.L	InsTags+36,RtgTallASv+4
	ST	RtgTall
	LEA	topaz8,A0		; every topaz 8 of the menu is the tall one,
	LEA	RtgTallNom,A1
	MOVE.L	A1,(A0)
	MOVE.W	#TALLFY,4(A0)
	MOVE.B	#$40,7(A0)
	LEA	MainMenuLeft,A0		; the windows (Top 2T-3: under the taller
	MOVEQ	#TALLWINS-1,D1		; screen title bar as T is under the short one),
.win:	MOVE.W	2(A0),D0
	ADD.W	D0,D0
	SUBQ.W	#3,D0
	MOVE.W	D0,2(A0)
	ASL.W	6(A0)
	ADDQ.L	#8,A0
	DBF	D1,.win
	BSR	RtgTallScH		; the screen,
	ASL.W	2(A0)
	LEA	InsTags,A0		; the Insert file requester (top, height),
	MOVE.L	28(A0),D0
	ADD.L	D0,D0
	SUBQ.L	#3,D0
	MOVE.L	D0,28(A0)
	MOVE.L	36(A0),D0
	ADD.L	D0,D0
	MOVE.L	D0,36(A0)
	LEA	RtgTallImgT,A2		; and the pictures (planes of rows of words).
.im:	TST.L	(A2)
	BEQ.S	.x
	MOVE.L	12(A2),A3		; (an Image of its size)
	MOVE.W	4(A3),D3
	ADD.W	#15,D3
	LSR.W	#4,D3
	ADD.W	D3,D3			; D3 = bytes a row
	MOVE.W	6(A3),D4		; D4 = rows
	MOVE.W	D3,D0
	MULU.W	D4,D0
	MULU.W	8(A3),D0		; x planes
	ADD.L	D0,D0			; x 2
	MOVE.L	D0,8(A2)
	MOVE.L	#$10002,D1		; MEMF_CHIP|MEMF_CLEAR
	MOVE.L	4.W,A6
	JSR	-198(A6)		; AllocMem (RtgQuit frees it)
	MOVE.L	D0,4(A2)
	BEQ.S	.imn			; (none: this one stays short)
	MOVE.L	D0,A1
	MOVE.L	(A2),A0
	MOVE.W	D4,D2
	MULU.W	8(A3),D2		; rows of all planes
	SUBQ.W	#1,D2
.pr:	MOVE.W	D3,D1
	SUBQ.W	#1,D1
	MOVE.L	A0,A4
.pb:	MOVE.B	(A4)+,(A1)+
	DBF	D1,.pb
	MOVE.W	D3,D1
	SUBQ.W	#1,D1
.pb2:	MOVE.B	(A0)+,(A1)+
	DBF	D1,.pb2
	DBF	D2,.pr
.imn:	LEA	16(A2),A2
	BRA.S	.im
.x:	RTS

; A0 = the value of the menu screen's SA_Height tag (its low word at 2(A0)).
RtgTallScH:
	LEA	ScreenTags,A0
.l:	MOVE.L	(A0)+,D0
	BEQ.S	.x			; (always there)
	CMP.L	#$80000024,D0		; SA_Height
	BEQ.S	.x
	ADDQ.L	#4,A0
	BRA.S	.l
.x:	RTS

; RtgMenuScreen: the P96 menu screen did not open, the native one will: the
; layout as it was (the font stays in the list, the tall pictures until RtgQuit).
RtgTallUndo:
	TST.B	RtgTall
	BEQ.S	.x
	SF	RtgTall
	MOVEM.L	D0-D1/A0-A1,-(SP)
	LEA	RtgTallWSv,A0
	LEA	MainMenuLeft,A1
	MOVEQ	#TALLWINS*2-1,D1
.l:	MOVE.L	(A0)+,(A1)+
	DBF	D1,.l
	MOVE.L	RtgTallTSv,topaz8
	MOVE.L	RtgTallTSv+4,topaz8+4
	MOVE.L	RtgTallASv,InsTags+28
	MOVE.L	RtgTallASv+4,InsTags+36
	BSR	RtgTallScH
	ASR.W	2(A0)
	MOVEM.L	(SP)+,D0-D1/A0-A1
.x:	RTS

; Drawing at double height (RtgTall), else the call as it was:
; GadToolsBox's NewGadget (A0): y and height, before the window's BorderTop is
; added to y.
TallNG:
	TST.B	RtgTall
	BEQ.S	.x
	ASL.W	2(A0)
	ASL.W	6(A0)
.x:	RTS
; DrawBevelBoxA: D1 = y + the window's BorderTop D5, D3 = height. A6 = GadTools.
TallBevel:
	TST.B	RtgTall
	BEQ.S	.x
	ADD.W	D1,D1
	SUB.W	D5,D1
	ADD.W	D3,D3
.x:	JMP	DrawBevelBoxA(A6)
; PrintIText (D1 = the window's BorderTop): the chain's TopEdges doubled for
; the call. A6 = Intuition.
TallIText:
	TST.B	RtgTall
	BEQ.S	.n
	MOVEM.L	D0-D1/A0-A1,-(SP)
	MOVE.L	A1,D0
.l1:	MOVE.L	D0,A1
	ASL.W	6(A1)
	MOVE.L	16(A1),D0
	BNE.S	.l1
	MOVEM.L	(SP),D0-D1/A0-A1
	JSR	PrintIText(A6)
	MOVE.L	12(SP),D0
.l2:	MOVE.L	D0,A1
	ASR.W	6(A1)
	MOVE.L	16(A1),D0
	BNE.S	.l2
	MOVEM.L	(SP)+,D0-D1/A0-A1
	RTS
.n:	JMP	PrintIText(A6)
; DrawImage (A0 = RastPort, A1 = Image, D0/D1 = x, y; y = a y of the AGA layout
; + the screen font's height, as Menu.asm works it out): the picture at double
; height, at 2 x its y under the window's taller title bar. A6 = Intuition.
TallImage:
	TST.B	RtgTall
	BEQ.S	.n
	MOVEM.L	D1-D2/A0-A2,-(SP)
	LEA	RtgTallImgT,A2
.f:	MOVE.L	(A2),D2
	BEQ.S	.nf
	CMP.L	10(A1),D2
	BEQ.S	.ok
	LEA	16(A2),A2
	BRA.S	.f
.ok:	LEA	RtgTallImg,A0		; a copy of the Image
	MOVEQ	#20/4-1,D2
.c:	MOVE.L	(A1)+,(A0)+
	DBF	D2,.c
	LEA	RtgTallImg,A1
	MOVE.L	4(A2),D2
	BEQ.S	.short
	MOVE.L	D2,10(A1)		; ImageData at double height
	ASL.W	6(A1)
.short:	ADD.W	2(A1),D1		; window y = 2 x (D1 + TopEdge - font - BorderTop)
	CLR.W	2(A1)			; + BorderTop, BorderTop = WBorTop + font + 1
	ADD.W	D1,D1
	MOVE.L	Scr,A0
	MOVEQ	#0,D2
	MOVE.B	35(A0),D2		; sc_WBorTop
	SUB.W	D2,D1
	SUB.W	#TALLFY+1,D1
	MOVE.L	8(SP),A0
	JSR	-114(A6)		; DrawImage
	MOVEM.L	(SP)+,D1-D2/A0-A2
	RTS
.nf:	MOVEM.L	(SP)+,D1-D2/A0-A2
.n:	JMP	-114(A6)		; DrawImage
	ENDC
; p96GetModeIDAttr(D0 = ModeID, D1 = attribute) -> D0. Keeps D2-D7/A2-A5.
RtgIdAttr:
	MOVE.L	A6,-(SP)
	MOVE.L	RtgP96,A6
	JSR	-84(A6)
	MOVE.L	(SP)+,A6
	RTS

; A0 = the RtgFmtTab entry of P96 format D0.B, or 0.
RtgFmtFind:
	LEA	RtgFmtTab(PC),A0
.l:	TST.B	(A0)
	BEQ.S	.0
	CMP.B	(A0),D0
	BEQ.S	.x
	LEA	8(A0),A0
	BRA.S	.l
.0:	SUB.L	A0,A0
.x:	RTS

; 16-bit formats: P96 RGBFB number, then bits and shift of R, G, B, and 1
; when the 16-bit word is little-endian (PC).
RtgFmtTab:
	DC.B	4, 5,11, 6,5, 5,0, 1	; R5G6B5PC (VideoCore, uaegfx)
	DC.B	10, 5,11, 6,5, 5,0, 0	; R5G6B5
	DC.B	5, 5,10, 5,5, 5,0, 1	; R5G5B5PC
	DC.B	11, 5,10, 5,5, 5,0, 0	; R5G5B5
	DC.B	12, 5,0, 6,5, 5,11, 1	; B5G6R5PC
	DC.B	13, 5,0, 5,5, 5,10, 1	; B5G5R5PC
	DC.B	0
	EVEN

	IFEQ	NO_RTGFIX
; RtgMenuScreen: the menu screen (Programa, instead of SetupScreen). When the
; P96 menu screen can't be opened, the native one (as without RTG).
RtgMenuScreen:
	IFNE	RTGMENUFAIL	; (test: the P96 menu screen fails, as if it could not open)
	MOVEQ	#1,D0
	ELSE
	JSR	SetupScreen
	ENDC
	CMP.L	#1,D0			; 1: OpenScreenTagList failed
	BNE.S	.x
	TST.B	RtgMenuOn
	BEQ.S	.x
	SF	RtgMenuOn
	MOVE.L	A0,-(SP)
	LEA	ScreenTags,A0		; SA_DisplayID back to the native mode
.tag:	MOVE.L	(A0)+,D0
	BEQ.S	.t1
	CMP.L	#$80000032,D0
	BEQ.S	.tagS
	ADDQ.L	#4,A0
	BRA.S	.tag
.tagS:	MOVE.L	#$00029000,(A0)
.t1:	MOVE.L	(SP)+,A0
	IFEQ	TallOff
	BSR	RtgTallUndo		; and the layout of the native screen
	ENDC
	JSR	SetupScreen
.x:	RTS

; RtgMenuPlay: Power ON / Continue in the menu, before EmulatorStart. Opens
; the play screen now; D0 = 1 when it failed with the menu on RTG (then the
; game is not started: on the AGA output it would run behind the menu on the
; graphics card's output). RTG is then off for this session. D0 = 0: go on.
RtgMenuPlay:
	MOVEQ	#0,D0
	TST.B	RtgWant
	BEQ.S	.x
	BSR	RtgPlayOpen
	TST.B	RtgOn
	BNE.S	.x
	TST.B	RtgMenuOn
	BEQ.S	.x
	SF	RtgWant
	MOVEQ	#1,D0
.x:	RTS

tErRtgScr:	DC.B	"Can't open the RTG screen!",0
	EVEN
	ENDC

; ---------------------------------------------------------------------------
; RtgPlayOpen: EmulatorStart, OS alive, before the takeover. Opens the play
; screen, reads its bitmap's address under a short lock (let go before the
; takeover: in play the OS is stopped and nothing else uses the board), builds
; the colour table. Any failure: this run stays on AGA.
	CNOP	0,4
RtgPlayOpen:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	IFEQ	NO_RTGFIX
	TST.B	RtgOn			; already opened by RtgMenuPlay
	BNE	.x
	ENDC
	SF	RtgOn
	TST.B	RtgWant
	BEQ	.x
	MOVE.L	RtgModeID,D0
	MOVEQ	#P96IDA_WIDTH,D1
	BSR	RtgIdAttr
	MOVE.W	D0,RtgScrW
	MOVE.L	D0,RtgSTW+4
	MOVE.L	RtgModeID,D0
	MOVEQ	#P96IDA_HEIGHT,D1
	BSR	RtgIdAttr
	MOVE.W	D0,RtgScrH
	MOVE.L	D0,RtgSTH+4
	MOVE.L	RtgModeID,D0
	MOVEQ	#P96IDA_DEPTH,D1
	BSR	RtgIdAttr
	MOVE.L	D0,RtgSTD+4
	MOVE.L	RtgModeID,RtgSTM+4
	SUB.L	A0,A0
	LEA	RtgSTags,A1
	MOVE.L	RtgInt,A6
	JSR	-612(A6)		; OpenScreenTagList
	MOVE.L	D0,RtgScr
	BEQ	.x
	MOVE.B	#5,RtgStage
	MOVE.L	RtgGfx,A6		; let the board show it first, no lock held
	JSR	-270(A6)		; WaitTOF
	JSR	-270(A6)
	MOVE.L	RtgScr,A0
	MOVE.L	$58(A0),A0		; sc_RastPort.rp_BitMap
	MOVE.L	A0,RtgBm
	LEA	RtgRI,A1
	MOVEQ	#12,D0
	MOVE.L	RtgP96,A6
	JSR	-48(A6)			; p96LockBitMap
	MOVE.L	D0,RtgLock
	BEQ	.fail
	MOVE.B	#6,RtgStage
	MOVE.L	RtgRI+8,D0		; the bitmap's real format
	MOVE.B	D0,RtgFmtSeen
	BSR	RtgFmtFind
	MOVE.L	A0,D0
	BEQ	.unl
	MOVE.B	(A0),RtgFmt
	MOVE.L	RtgRI,RtgMem
	MOVEQ	#0,D0
	MOVE.W	RtgRI+4,D0
	MOVE.L	D0,RtgBpr
	BSR	RtgMkCol
	IFEQ	ScanOff
	BSR	RtgScanPrep		; the scanline table for this format and setting
	ENDC
	MOVE.L	RtgMem,A0		; clear the screen
	MOVE.L	RtgBpr,D0
	MULU.W	RtgScrH,D0
	LSR.L	#2,D0
	BRA.S	.clE
.cl:	CLR.L	(A0)+
.clE:	SUBQ.L	#1,D0
	BPL.S	.cl
	MOVE.L	RtgBm,A0
	MOVE.L	RtgLock,D0
	MOVE.L	RtgP96,A6
	JSR	-54(A6)			; p96UnlockBitMap
	CLR.L	RtgLock
	BSR	RtgReset
	ST	RtgOn
	MOVE.B	#7,RtgStage
	BRA.S	.x
.unl:	MOVE.L	RtgBm,A0
	MOVE.L	RtgLock,D0
	MOVE.L	RtgP96,A6
	JSR	-54(A6)
	CLR.L	RtgLock
.fail:	BSR	RtgCloseScr
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

; RtgPlayClose: back from play, OS alive (after DescongelaAMIGA). With
; RTGSHOT the last frame is copied and the screen read back to a file first.
	CNOP	0,4
RtgPlayClose:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	TST.B	RtgOn
	BEQ.S	.x
	SF	RtgOn
	IFNE	RTGSHOT
	BSR	RtgShotWrite
	ENDC
.x:
	IFNE	RTGSHOT
	BSR	RtgStatWrite
	ENDC
	BSR	RtgCloseScr
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

RtgCloseScr:
	MOVE.L	RtgScr,D0
	BEQ.S	.x
	MOVE.L	D0,A0
	MOVE.L	RtgInt,A6
	JSR	-66(A6)			; CloseScreen
	CLR.L	RtgScr
.x:	RTS

; RtgTakeover: just after CongelaAMIGA. Bitplane, copper and sprite DMA off:
; nothing of the display is fetched from chip RAM. DescongelaAMIGA puts the
; saved DMACON back.
RtgTakeover:
	TST.B	RtgOn
	BEQ.S	.x
	MOVE.W	#$01A0,$DFF096		; BPLEN, COPEN, SPREN off
	MOVE.W	#$0000,$DFF180
.x:	RTS

; A new run (Power ON or Continue): the caches know nothing, every line is new.
RtgReset:
	MOVEM.L	D0-D1/A0,-(SP)
	LEA	RtgTValid,A0
	MOVE.W	#(2048+512)/4-1,D0	; RtgTValid and RtgSValid
.v:	CLR.L	(A0)+
	DBF	D0,.v
	LEA	RtgPalOld,A0
	MOVEQ	#-1,D1
	MOVE.W	#512/2-1,D0
.p:	MOVE.L	D1,(A0)+
	DBF	D0,.p
	LEA	RtgDirty,A0
	MOVE.W	#RTGLINES/4-1,D0
.d:	CLR.L	(A0)+
	DBF	D0,.d
	CLR.W	RtgCRN
	IFEQ	NO_RTGPAL
	CLR.W	RtgPLN
	SF	RtgPalNext
	ENDC
	MOVE.B	VDP_Regs+(5*2)+1,RtgCRStart
	CLR.W	RtgW			; geometry unknown: the first frame sets it
	ST	RtgFull
	ST	RtgClear
	TST.B	RtgInitd
	BNE.S	.x
	ST	RtgInitd
	BSR	RtgMkSpread
	LEA	RtgBgMap,A0		; BG palette index -> line word: colour 0 of
	MOVEQ	#0,D0			; every palette is VCE entry 0
.m:	MOVE.W	D0,D1
	AND.W	#15,D1
	BEQ.S	.m0
	MOVE.W	D0,D1
.m0:	MOVE.W	D1,(A0)+
	ADDQ.W	#1,D0
	CMP.W	#256,D0
	BNE.S	.m
.x:	MOVEM.L	(SP)+,D0-D1/A0
	RTS

; RtgSpread: plane byte -> 8 pixel bytes, plane k's bit in bit k (4 x 256 x 8).
RtgMkSpread:
	LEA	RtgSpread,A0
	MOVEQ	#0,D3			; plane
.k:	MOVEQ	#0,D2			; value
.v:	MOVEQ	#7,D1			; bit 7 = pixel 0
.b:	MOVEQ	#0,D0
	BTST	D1,D2
	BEQ.S	.b0
	MOVEQ	#1,D0
	LSL.B	D3,D0
.b0:	MOVE.B	D0,(A0)+
	DBF	D1,.b
	ADDQ.W	#1,D2
	CMP.W	#256,D2
	BNE.S	.v
	ADDQ.W	#1,D3
	CMP.W	#4,D3
	BNE.S	.k
	RTS

; RtgCol: VCE colour (9 bits, GGGRRRBBB) -> the screen's pixel, twice in a
; long. 3-bit levels as n*max/7 of the format's bits.
RtgMkCol:
	MOVEM.L	D0-D7/A0-A2,-(SP)
	LEA	RtgFmtTab(PC),A0
	MOVE.B	RtgFmt,D0
.f:	CMP.B	(A0),D0
	BEQ.S	.ff
	ADDQ.L	#8,A0
	BRA.S	.f
.ff:	LEA	RtgGun,A1		; 3 x 8 words: R, G, B levels, shifted
	ADDQ.L	#1,A0
	MOVEQ	#3-1,D7
.g:	MOVEQ	#0,D2
	MOVE.B	(A0)+,D2		; bits
	MOVEQ	#0,D3
	MOVE.B	(A0)+,D3		; shift
	MOVEQ	#1,D4
	LSL.L	D2,D4
	SUBQ.L	#1,D4			; max
	MOVEQ	#0,D6
.n:	MOVE.L	D6,D0			; level n of 7 -> 0..max, rounded
	MULU.W	D4,D0
	ADDQ.L	#3,D0
	DIVU.W	#7,D0
	AND.L	#$FFFF,D0
	LSL.L	D3,D0
	MOVE.W	D0,(A1)+
	ADDQ.W	#1,D6
	CMP.W	#8,D6
	BNE.S	.n
	DBF	D7,.g
	MOVE.B	(A0),D5			; 1: little-endian
	LEA	RtgCol,A1
	LEA	RtgGun,A2
	MOVEQ	#0,D7
.c:	MOVE.W	D7,D0			; R = bits 3-5
	LSR.W	#3,D0
	AND.W	#7,D0
	MOVE.W	(A2,D0.W*2),D1
	MOVE.W	D7,D0			; G = bits 6-8
	LSR.W	#6,D0
	AND.W	#7,D0
	OR.W	16(A2,D0.W*2),D1
	MOVE.W	D7,D0			; B = bits 0-2
	AND.W	#7,D0
	OR.W	32(A2,D0.W*2),D1
	TST.B	D5
	BEQ.S	.be
	ROL.W	#8,D1
.be:	MOVE.W	D1,D0
	SWAP	D1
	MOVE.W	D0,D1
	MOVE.L	D1,(A1)+
	ADDQ.W	#1,D7
	CMP.W	#512,D7
	BNE.S	.c
	MOVEM.L	(SP)+,D0-D7/A0-A2
	RTS

; ---------------------------------------------------------------------------
; RtgFrame: the PCE frame just ended (main loop, after PCE_Start). Composes
; the picture from VRAM, the BAT, the SAT copy and this frame's scroll list.
; Replaces WideGeometry, PrintGFX and PrintSprites_AGA; calls CleanTabRefef.
; All registers may be used (the caller saved them), A7 kept.
	CNOP	0,4
RtgFrame:
; geometry: width from the VDC, the largest integer scale that fits, centred
	MOVEQ	#0,D0
	MOVE.B	VDP_Regs+(11*2)+1,D0
	AND.W	#$7F,D0
	ADDQ.W	#1,D0
	LSL.W	#3,D0
	CMP.W	#RTGMW,D0
	BLS.S	.g1
	MOVE.W	#RTGMW,D0
.g1:	CMP.W	#64,D0
	BCC.S	.g2
	MOVEQ	#64,D0
.g2:	MOVEQ	#0,D2
	MOVE.W	RtgScrW,D2
	DIVU.W	D0,D2			; scale by width
	MOVEQ	#0,D3
	MOVE.W	RtgScrH,D3
	DIVU.W	#RTGLINES,D3		; by height
	CMP.W	D3,D2
	BLS.S	.g3
	MOVE.W	D3,D2
.g3:	CMP.W	#4,D2
	BLS.S	.g4
	MOVEQ	#4,D2
.g4:	TST.W	D2
	BNE.S	.g5
	MOVEQ	#1,D2			; does not fit at 1x: cut the width
	CMP.W	RtgScrW,D0
	BLS.S	.g5
	MOVE.W	RtgScrW,D0
	AND.W	#$FFF8,D0
.g5:	CMP.W	RtgW,D0
	BNE.S	.gnew
	CMP.W	RtgScl,D2
	BEQ.S	.gok
.gnew:	MOVE.W	D0,RtgW
	MOVE.W	D2,RtgScl
	ST	RtgFull
	ST	RtgClear
	MOVE.W	D0,D1
	MULU.W	D2,D1
	MOVE.W	RtgScrW,D3
	SUB.W	D1,D3
	LSR.W	#1,D3
	MOVE.W	D3,RtgOX
	MOVE.W	#RTGLINES,D1
	MULU.W	D2,D1
	MOVE.W	RtgScrH,D3
	SUB.W	D1,D3
	LSR.W	#1,D3
	MOVE.W	D3,RtgOY
.gok:
; palette: changed VCE entries -> RtgPal; any change redraws every line
	LEA	VDP_Pal,A0
	LEA	RtgPalOld,A1
	LEA	RtgPal,A2
	LEA	RtgCol,A3
	MOVEQ	#0,D7
	MOVE.W	#512-1,D6
.pl:	MOVE.W	(A0)+,D0
	IFEQ	NO_RTGFIX
	AND.W	#$1FF,D0		; (the game's high bits could equal the -1 'not loaded' mark)
	ENDC
	CMP.W	(A1)+,D0
	BEQ.S	.pn
	MOVE.W	D0,-2(A1)
	IFNE	NO_RTGFIX
	AND.W	#$1FF,D0
	ENDC
	MOVE.L	(A3,D0.W*4),(A2)
	MOVEQ	#1,D7
.pn:	ADDQ.L	#4,A2
	DBF	D6,.pl
	TST.W	D7
	BEQ.S	.pok
	ST	RtgFull
.pok:
; VRAM written since the last frame (TabRedef, one byte per 16 words): those
; tiles and sprite patterns are decoded again when next used
	LEA	TabRedef,A0
	LEA	RtgTValid,A1
	LEA	RtgSValid,A2
	MOVEQ	#0,D0
	MOVE.W	#2048/4-1,D6
.tr:	TST.L	(A0)+
	BNE.S	.trf
.trn:	ADDQ.W	#4,D0
	DBF	D6,.tr
	BRA.S	.trd
.trf:	CLR.L	(A1,D0.W)
	MOVE.W	D0,D1
	LSR.W	#2,D1
	SF	(A2,D1.W)
	BRA.S	.trn
.trd:	JSR	CleanTabRefef		; (uses all registers)
; BAT size (MWR bits 4-6)
	MOVE.B	VDP_Regs+(9*2)+1,D3
	LSR.B	#4,D3
	AND.W	#7,D3
	MOVE.W	(RtgBatW,PC,D3.W*2),D0	; tiles
	MOVE.W	D0,D1
	LSL.W	#3,D1
	SUBQ.W	#1,D1
	MOVE.W	D1,RtgBatXM		; pixel mask
	SUBQ.W	#1,D0
	MOVE.W	D0,RtgBatCM		; column mask
	MOVE.W	(RtgBatSh,PC,D3.W*2),RtgBatS
	MOVE.W	(RtgBatH,PC,D3.W*2),D0
	LSL.W	#3,D0
	SUBQ.W	#1,D0
	MOVE.W	D0,RtgBatYM
; display height; the enable bits per line from the CR writes (RtgCRLog)
	MOVE.W	VDP_Regs+(13*2),D0
	AND.W	#$1FF,D0
	ADDQ.W	#1,D0
	MOVE.W	D0,RtgVdw
	MOVE.W	VDP_Regs+(12*2),D0	; vertical start: VSW + VDS against the
	MOVE.W	D0,D1			; usual 2 + 15 (Mesen's picture lines)
	AND.W	#$1F,D0
	LSR.W	#8,D1
	ADD.W	D1,D0
	SUB.W	#17,D0
	CMP.W	#-32,D0
	BGE.S	.vo1
	MOVEQ	#-32,D0
.vo1:	CMP.W	#64,D0
	BLE.S	.vo2
	MOVEQ	#64,D0
.vo2:	MOVE.W	D0,RtgVoff
	MOVE.W	VDP_Regs+(10*2),D0	; horizontal start: HSW + HDS against the
	MOVE.W	D0,D1			; usual 2 + 2 (5 MHz) or 3 + 4 (7 MHz, told
	AND.W	#$1F,D0			; by the width: no record of the VCE clock)
	LSR.W	#8,D1
	AND.W	#$7F,D1
	IFEQ	NO_HSWPOS
	MOVEQ	#2,D0			; the VCE's own sync each line: as HSW 2 (5 MHz), 3 (7 MHz)
	ENDC
	ADD.W	D1,D0
	MOVE.B	VDP_Regs+(11*2)+1,D1
	AND.W	#$7F,D1
	CMP.W	#34,D1
	BCC.S	.ho7
	SUBQ.W	#4,D0
	BRA.S	.ho1
.ho7:	CMP.W	#48,D1
	BCC.S	.ho0			; 10 MHz: not known, left as it is
	IFEQ	NO_HSWPOS
	ADDQ.W	#1,D0
	ENDC
	SUBQ.W	#7,D0
	BRA.S	.ho1
.ho0:	MOVEQ	#0,D0
.ho1:	CMP.W	#-4,D0
	BGE.S	.ho2
	MOVEQ	#-4,D0
.ho2:	CMP.W	#4,D0
	BLE.S	.ho3
	MOVEQ	#4,D0
.ho3:	LSL.W	#3,D0
	MOVE.W	D0,RtgHoff		; pixels right
	MOVE.B	RtgCRStart,RtgCR
	LEA	RtgCRList,A0
	MOVE.L	A0,RtgCRP
	MOVE.W	RtgCRN,D0
	CMP.W	#RTGCRMAX,D0
	BLS.S	.crn
	MOVE.W	#RTGCRMAX,D0
.crn:	LSL.W	#2,D0
	MOVE.W	#$7FFF,(A0,D0.W)	; end mark
	IFEQ	NO_RTGPAL
	BSR	RtgPalStart
	ENDC
; sprites of this frame (SAT copy) on any picture line, in SAT order
	BSR	RtgSprList
; scroll list of this frame: entries (line, BXR, BYR), -1 at the end
	MOVE.L	Regs+ScrollChangesNext,A0
	TST.W	(A0)
	BPL.S	.sl
	LEA	RtgScrDef,A0		; (none: the registers as they are)
	CLR.W	(A0)
	MOVE.L	VDP_Regs+(7*2),2(A0)
	MOVE.W	#-1,6(A0)
.sl:	MOVE.L	A0,RtgScrP
; the lines
	MOVEQ	#0,D7
.line:	MOVE.W	D7,RtgY
	SUB.W	RtgVoff,D7		; the VDC's display line
	IFEQ	NO_RTGPAL
	TST.W	RtgPLN			; VCE writes made before this line
	BEQ.S	.plx
	BSR	RtgPalApply
.plx:	TST.W	D7			; (flags for BMI .border)
	ENDC
	BMI	.border
	CMP.W	RtgVdw,D7
	BCC	.border
	MOVE.W	D7,RtgA
	MOVE.L	RtgScrP,A0		; the last scroll entry with line <= y
.adv:	MOVE.W	6(A0),D0
	BMI.S	.adv1
	CMP.W	D7,D0
	BHI.S	.adv1
	ADDQ.L	#6,A0
	BRA.S	.adv
.adv1:	MOVE.L	A0,RtgScrP
	MOVE.L	RtgCRP,A0		; CR writes made before this line
.cr:	MOVE.W	(A0),D0
	CMP.W	D7,D0
	BGE.S	.cr1
	MOVE.B	3(A0),RtgCR
	ADDQ.L	#4,A0
	BRA.S	.cr
.cr1:	MOVE.L	A0,RtgCRP
	MOVE.L	RtgScrP,A0
	BTST	#7,RtgCR		; BG on?
	BEQ.S	.nobg
	MOVE.W	2(A0),D4		; BXR
	MOVE.W	4(A0),D5		; BYR
	MOVE.W	(A0),D0
	BEQ.S	.y0
	ADDQ.W	#1,D5			; a mid-frame BYR: +1 from the next line
.y0:	ADD.W	D7,D5
	SUB.W	D0,D5
	BSR	RtgBgLine
	BRA.S	.spr
.nobg:
	IFEQ	NO_BURST
; BG and sprites both off from the start of the frame: burst mode, the VDC gives no
; picture and the VCE shows entry $100 (Chew Man Fu between screens: colour 0 is green).
	MOVE.B	RtgCR,D0
	OR.B	RtgCRStart,D0
	AND.B	#$C0,D0
	BEQ	.border
	ENDC
	LEA	RtgLineB+32,A1
	MOVE.W	RtgW,D0
	LSR.W	#1,D0
	SUBQ.W	#1,D0
.nb:	CLR.L	(A1)+
	DBF	D0,.nb
.spr:	BTST	#6,RtgCR		; sprites on?
	BEQ.S	.out
	TST.W	RtgNSpr
	BEQ.S	.out
	BSR	RtgSprLine
	BRA.S	.out
.border:				; past the display: the border colour
	LEA	RtgLineB+32,A1
	MOVE.L	#$01000100,D1
	MOVE.W	RtgW,D0
	LSR.W	#1,D0
	SUBQ.W	#1,D0
.bd:	MOVE.L	D1,(A1)+
	DBF	D0,.bd
.out:	BSR	RtgOutLine
	MOVE.W	RtgY,D7
	ADDQ.W	#1,D7
	CMP.W	#RTGLINES,D7
	BNE	.line
	SF	RtgFull
	IFEQ	NO_RTGPAL
	TST.W	RtgPLN			; the rest of the VCE writes: RtgPal = VDP_Pal again
	BEQ.S	.ple
	MOVE.W	#$7FFF,D7
	BSR	RtgPalApply
	CLR.W	RtgPLN
.ple:	TST.B	RtgPalNext		; lines drawn with mid-frame colours: all again next frame
	BEQ.S	.pln
	ST	RtgFull
.pln:
	ENDC
	MOVE.B	VDP_Regs+(5*2)+1,RtgCRStart	; the next frame starts with this CR
	CLR.W	RtgCRN
	IFNE	RTGSHOT
	BSR	RtgShotKeep
	ENDC
	RTS

	IFEQ	NO_RTGPAL
; RtgPalLog: a VCE colour write (IO.asm, RtgOn only), D1 = entry 0-511, before
; VDP_Pal is written: line, entry, old and new value. All registers kept.
RtgPalLog:
	MOVEM.L	D0/A0,-(SP)
	MOVE.W	RtgPLN,D0
	CMP.W	#RTGPLMAX,D0
	BCC.S	.x
	ADDQ.W	#1,RtgPLN
	LEA	RtgPLog,A0
	LEA	(A0,D0.W*8),A0
	MOVE.W	Regs+ScanLine,(A0)+
	MOVE.W	D1,(A0)+
	MOVE.W	(VDP_Pal.L,D1.W*2),(A0)+
	MOVE.W	Regs+PAL_Data,(A0)
.x:	MOVEM.L	(SP)+,D0/A0
	RTS

; RtgPalStart (RtgFrame, after the palette compare left RtgPal = the frame-end
; VDP_Pal): when VCE writes fall inside the picture, RtgPal goes back to the
; colours at the start of the frame (the writes undone, last first) and every
; line is drawn (this frame and the next); RtgPalApply puts them back line by
; line. Writes only after the picture (vertical blank) change nothing here.
RtgPalStart:
	MOVE.B	RtgPalNext,D0
	SF	RtgPalNext
	TST.B	D0
	BEQ.S	.n0
	ST	RtgFull
.n0:	MOVE.W	RtgPLN,D0
	BEQ.S	.x
	MOVE.W	#RTGLINES-1,D1		; last display line on the picture
	SUB.W	RtgVoff,D1
	CMP.W	RtgPLog,D1		; first write before it?
	BGT.S	.mid
	CLR.W	RtgPLN			; all in the blank: the frame-end colours are right
	BRA.S	.x
.mid:	ST	RtgFull
	ST	RtgPalNext
	LEA	RtgPLog,A0
	LEA	(A0,D0.W*8),A0
	LEA	RtgCol,A1
	LEA	RtgPal,A2
	SUBQ.W	#1,D0
.u:	SUBQ.L	#8,A0
	MOVE.W	2(A0),D1
	MOVE.W	4(A0),D2
	AND.W	#$1FF,D2
	MOVE.L	(A1,D2.W*4),(A2,D1.W*4)
	DBF	D0,.u
	MOVE.L	A0,RtgPLP
.x:	RTS

; RtgPalApply: VCE writes made before display line D7 (signed) into RtgPal.
; All registers kept.
RtgPalApply:
	MOVEM.L	D0-D1/A0-A2,-(SP)
	MOVE.L	RtgPLP,A0
	MOVE.W	RtgPLN,D0
	LEA	RtgPLog,A1
	LEA	(A1,D0.W*8),A1		; end
	LEA	RtgPal,A2
.l:	CMP.L	A1,A0
	BCC.S	.x
	CMP.W	(A0),D7
	BLE.S	.x
	MOVE.W	6(A0),D1
	AND.W	#$1FF,D1
	MOVE.W	2(A0),D0
	MOVE.L	(RtgCol.L,D1.W*4),(A2,D0.W*4)
	ADDQ.L	#8,A0
	BRA.S	.l
.x:	MOVE.L	A0,RtgPLP
	MOVEM.L	(SP)+,D0-D1/A0-A2
	RTS
	ENDC

; RtgCRLog: a write to VDC R5 (IO.asm, any time): the line it was made on and
; the new value; it shows from the next line. All registers kept.
RtgCRLog:
	MOVEM.L	D0/A0,-(SP)
	MOVE.W	RtgCRN,D0
	IFEQ	NO_RTGFIX
	BEQ.S	.new			; a write on the same line as the last entry replaces it
	LEA	RtgCRList,A0
	LEA	-4(A0,D0.W*4),A0
	MOVE.W	(A0),D0
	CMP.W	Regs+ScanLine,D0
	BEQ.S	.same
	MOVE.W	RtgCRN,D0
.new:
	ENDC
	CMP.W	#RTGCRMAX,D0
	BCC.S	.x
	ADDQ.W	#1,RtgCRN
	LEA	RtgCRList,A0
	LEA	(A0,D0.W*4),A0
	MOVE.W	Regs+ScanLine,(A0)
.same:	MOVE.W	VDP_Regs+(5*2),2(A0)
.x:	MOVEM.L	(SP)+,D0/A0
	RTS

RtgBatW:	DC.W	32,64,128,128,32,64,128,128
RtgBatH:	DC.W	32,32,32,32,64,64,64,64
RtgBatSh:	DC.W	5,6,7,7,5,6,7,7

; RtgOutLine: line RtgY of palette indices in RtgLineB (+32 bytes) against
; the last frame's; a changed line goes to the compose buffer as screen
; pixels and is marked for RtgCopy.
RtgOutLine:
	MOVE.W	RtgHoff,D0
	BEQ.S	.sh0
	BSR	RtgShift
.sh0:	MOVE.W	RtgY,D7
	LEA	RtgLineB+32,A0
	MOVEQ	#0,D0
	MOVE.W	D7,D0
	MOVEQ	#10,D1
	LSL.L	D1,D0			; x 1024 (RTGMW words)
	RtgBuf	RtgOld,A1
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
.conv:	ADD.L	D0,D0			; x 2048 (RTGMW longs)
	RtgBuf	RtgComp,A3
	ADD.L	D0,A3
	LEA	RtgPal,A2
	SUBQ.W	#1,D6
	MOVEQ	#0,D0
.c:	MOVE.W	(A0)+,D0
	MOVE.W	D0,(A1)+
	MOVE.L	(A2,D0.W*4),(A3)+
	DBF	D6,.c
	LEA	RtgDirty,A0
	ST	(A0,D7.W)
	ST	RtgAnyD
.x:	RTS

; RtgShift: moves the line in RtgLineB D0 pixels (a multiple of 8, -32..32)
; right, the border colour coming in.
RtgShift:
	LEA	RtgLineB+32,A0
	MOVE.W	RtgW,D1
	MOVE.L	#$01000100,D2
	TST.W	D0
	BMI.S	.left
	LEA	(A0,D1.W*2),A1		; end of the line
	MOVE.L	A1,A2
	SUB.W	D0,D1
	SUB.W	D0,A2
	SUB.W	D0,A2			; source end
	LSR.W	#1,D1
	SUBQ.W	#1,D1
.r:	MOVE.L	-(A2),-(A1)
	DBF	D1,.r
	LSR.W	#1,D0
	SUBQ.W	#1,D0
.rb:	MOVE.L	D2,-(A1)
	DBF	D0,.rb
	RTS
.left:	NEG.W	D0
	LEA	(A0,D0.W*2),A2
	SUB.W	D0,D1
	MOVE.W	D1,D3
	LSR.W	#1,D3
	SUBQ.W	#1,D3
.l:	MOVE.L	(A2)+,(A0)+
	DBF	D3,.l
	LSR.W	#1,D0
	SUBQ.W	#1,D0
.lb:	MOVE.L	D2,(A0)+
	DBF	D0,.lb
	RTS

; RtgBgLine: D4 = BG X (BXR), D5 = BG Y of this line. Writes RtgW palette
; indices (words) at RtgLineB+32.
RtgBgLine:
	AND.W	RtgBatYM,D5
	MOVEQ	#0,D0
	MOVE.W	D5,D0
	LSR.W	#3,D0			; BAT row
	MOVE.W	RtgBatS,D1
	LSL.L	D1,D0
	LEA	VRAM,A2
	LEA	(A2,D0.L*2),A2		; the row's BAT words
	AND.W	#7,D5
	LSL.W	#3,D5			; row in the tile (8 bytes a row)
	AND.W	RtgBatXM,D4
	MOVE.W	D4,D3
	AND.W	#7,D3			; pixels of the first tile left of x 0
	LSR.W	#3,D4			; BAT column
	LEA	RtgLineB+32,A1
	SUB.W	D3,A1
	SUB.W	D3,A1
	MOVE.W	RtgW,D7
	ADD.W	D3,D7
	ADDQ.W	#7,D7
	LSR.W	#3,D7
	SUBQ.W	#1,D7			; tiles - 1
	RtgBuf	RtgTCache,A3
	LEA	RtgTValid,A4
	LEA	RtgBgMap,A5
	MOVE.W	RtgBatCM,D6
	MOVEQ	#0,D1
.t:	MOVE.W	(A2,D4.W*2),D0		; BAT word: palette 12-15, tile 0-11
	MOVE.W	D0,D2
	LSR.W	#8,D2
	AND.W	#$F0,D2			; palette * 16
	AND.L	#$7FF,D0		; tile (32K words of VRAM)
	TST.B	(A4,D0.W)
	BNE.S	.ok
	BSR	RtgTileDec
.ok:	LSL.L	#6,D0
	LEA	(A3,D0.L),A0
	ADD.W	D5,A0
	REPT	8
	MOVE.B	(A0)+,D1
	OR.B	D2,D1
	MOVE.W	(A5,D1.W*2),(A1)+
	ENDR
	ADDQ.W	#1,D4
	AND.W	D6,D4
	DBF	D7,.t
	RTS

; RtgTileDec: decode BG tile D0.W (VRAM word D0*16) into RtgTCache (64
; bytes, colour 0-15 a pixel) and mark it valid (A4 = RtgTValid). All
; registers kept.
RtgTileDec:
	MOVEM.L	D0-D7/A0-A3,-(SP)
	ST	(A4,D0.W)
	MOVEQ	#0,D1
	MOVE.W	D0,D1
	LSL.L	#5,D1
	LEA	VRAM,A0
	ADD.L	D1,A0			; 32 bytes: rows of planes 0/1, then 2/3
	ADD.L	D1,D1
	RtgBuf	RtgTCache,A1
	ADD.L	D1,A1
	LEA	RtgSpread,A2
	MOVEQ	#8-1,D7
	MOVEQ	#0,D0
.r:	MOVE.B	1(A0),D0		; plane 0
	LEA	(A2,D0.W*8),A3
	MOVE.L	(A3)+,D4
	MOVE.L	(A3),D5
	MOVE.B	(A0),D0			; plane 1
	LEA	2048(A2,D0.W*8),A3
	OR.L	(A3)+,D4
	OR.L	(A3),D5
	MOVE.B	17(A0),D0		; plane 2
	LEA	4096(A2,D0.W*8),A3
	OR.L	(A3)+,D4
	OR.L	(A3),D5
	MOVE.B	16(A0),D0		; plane 3
	LEA	6144(A2,D0.W*8),A3
	OR.L	(A3)+,D4
	OR.L	(A3),D5
	MOVE.L	D4,(A1)+
	MOVE.L	D5,(A1)+
	ADDQ.L	#2,A0
	DBF	D7,.r
	MOVEM.L	(SP)+,D0-D7/A0-A3
	RTS

; RtgSprDec: decode sprite pattern D0.W (VRAM word D0*64: 16 rows of each of
; 4 planes, bit 15 = left) into RtgSCache (256 bytes). All registers kept.
RtgSprDec:
	MOVEM.L	D0-D7/A0-A4,-(SP)
	LEA	RtgSValid,A0
	ST	(A0,D0.W)
	MOVEQ	#0,D1
	MOVE.W	D0,D1
	LSL.L	#7,D1
	LEA	VRAM,A0
	ADD.L	D1,A0
	ADD.L	D1,D1
	RtgBuf	RtgSCache,A1
	ADD.L	D1,A1
	LEA	RtgSpread,A2
	MOVEQ	#16-1,D7
	MOVEQ	#0,D0
.r:	MOVEQ	#2-1,D6			; the high byte (px 0-7), then the low
	MOVE.L	A0,A4
.h:	MOVE.B	(A4),D0			; plane 0
	LEA	(A2,D0.W*8),A3
	MOVE.L	(A3)+,D4
	MOVE.L	(A3),D5
	MOVE.B	32(A4),D0		; plane 1
	LEA	2048(A2,D0.W*8),A3
	OR.L	(A3)+,D4
	OR.L	(A3),D5
	MOVE.B	64(A4),D0		; plane 2
	LEA	4096(A2,D0.W*8),A3
	OR.L	(A3)+,D4
	OR.L	(A3),D5
	MOVE.B	96(A4),D0		; plane 3
	LEA	6144(A2,D0.W*8),A3
	OR.L	(A3)+,D4
	OR.L	(A3),D5
	MOVE.L	D4,(A1)+
	MOVE.L	D5,(A1)+
	ADDQ.L	#1,A4
	DBF	D6,.h
	ADDQ.L	#2,A0
	DBF	D7,.r
	MOVEM.L	(SP)+,D0-D7/A0-A4
	RTS
	IFEQ	NO_SPR2BPP
; RtgSprDec2: as RtgSprDec for sprite access mode 1: two planes as colour bits
; 0-1, planes 0-1 (D2 = $FE) or 2-3 (D2 = $FD); valid byte = D2. All registers kept.
RtgSprDec2:
	MOVEM.L	D0-D7/A0-A4,-(SP)
	LEA	RtgSValid,A0
	MOVE.B	D2,(A0,D0.W)
	MOVEQ	#0,D1
	MOVE.W	D0,D1
	LSL.L	#7,D1
	LEA	VRAM,A0
	ADD.L	D1,A0
	CMP.B	#$FD,D2
	BNE.S	.c0
	LEA	64(A0),A0		; planes 2-3
.c0:	ADD.L	D1,D1
	RtgBuf	RtgSCache,A1
	ADD.L	D1,A1
	LEA	RtgSpread,A2
	MOVEQ	#16-1,D7
	MOVEQ	#0,D0
.r:	MOVEQ	#2-1,D6
	MOVE.L	A0,A4
.h:	MOVE.B	(A4),D0
	LEA	(A2,D0.W*8),A3
	MOVE.L	(A3)+,D4
	MOVE.L	(A3),D5
	MOVE.B	32(A4),D0
	LEA	2048(A2,D0.W*8),A3
	OR.L	(A3)+,D4
	OR.L	(A3),D5
	MOVE.L	D4,(A1)+
	MOVE.L	D5,(A1)+
	ADDQ.L	#1,A4
	DBF	D6,.h
	ADDQ.L	#2,A0
	DBF	D7,.r
	MOVEM.L	(SP)+,D0-D7/A0-A4
	RTS
	ENDC

; RtgSprList: the SAT copy's sprites that reach a picture line, in SAT order,
; as RtgSprT entries (16 bytes): top, height, x, cells (1/2), pattern,
; line word ($100 + palette*16, bit 15 = over BG), flags (0 = X flip, 1 = Y flip).
RtgSprList:
	IFEQ	NO_SATLAG
	LEA	SatShown,A0
	ELSE
	LEA	SpriteCoor,A0
	ENDC
	LEA	RtgSprT,A1
	MOVEQ	#0,D7			; count
	MOVEQ	#64-1,D6
.s:	MOVE.W	6(A0),D3		; attributes
	MOVE.W	(A0),D0
	AND.W	#$3FF,D0
	SUB.W	#64,D0			; top line
	MOVEQ	#16,D1
	BTST	#13,D3
	BEQ.S	.h1
	MOVEQ	#64,D1
	BRA.S	.h2
.h1:	BTST	#12,D3
	BEQ.S	.h2
	MOVEQ	#32,D1
.h2:
	IFEQ	NO_RTGFIX
	CMP.W	#512,D0			; display lines up to 511 can be on the picture (RtgVoff < 0)
	ELSE
	CMP.W	#RTGLINES,D0
	ENDC
	BGE	.n
	MOVE.W	D0,D2
	ADD.W	D1,D2
	BLE	.n
	MOVE.W	D0,(A1)
	MOVE.W	D1,2(A1)
	MOVE.W	2(A0),D0
	AND.W	#$3FF,D0
	SUB.W	#32,D0
	MOVE.W	D0,4(A1)
	MOVE.W	4(A0),D0		; pattern
	IFEQ	NO_SPR2BPP
	MOVE.B	VDP_Regs+(9*2)+1,D2	; MWR sprite access mode 1: 2 planes,
	AND.B	#$0C,D2			; bits 10-11 = 1 (CG 0: planes 0-1) or 2 (CG 1: 2-3)
	CMP.B	#$04,D2
	BNE.S	.m4
	MOVE.W	D0,D2
	LSR.W	#1,D0
	AND.W	#$1FF,D0
	BTST	#0,D2
	BNE.S	.m3
	BSET	#10,D0
	BRA.S	.m5
.m3:	BSET	#11,D0
	BRA.S	.m5
.m4:	LSR.W	#1,D0
	AND.W	#$1FF,D0
.m5:
	ELSE
	LSR.W	#1,D0
	AND.W	#$3FF,D0
	ENDC
	MOVEQ	#1,D2
	BTST	#8,D3
	BEQ.S	.w1
	MOVEQ	#2,D2
	BCLR	#0,D0			; 32 wide: bit 0 ignored
.w1:	MOVE.W	D2,6(A1)
	CMP.W	#16,D1
	BEQ.S	.p1
	BCLR	#1,D0			; 32 or 64 high: bit 1 ignored
	CMP.W	#64,D1
	BNE.S	.p1
	BCLR	#2,D0			; 64 high: bit 2 too
.p1:	MOVE.W	D0,8(A1)
	MOVE.W	D3,D0
	AND.W	#15,D0
	LSL.W	#4,D0
	OR.W	#$100,D0
	BTST	#7,D3
	BEQ.S	.pr
	OR.W	#$8000,D0
.pr:	MOVE.W	D0,10(A1)
	MOVEQ	#0,D0
	BTST	#11,D3
	BEQ.S	.fx
	MOVEQ	#1,D0
.fx:	TST.W	D3
	BPL.S	.fy
	BSET	#1,D0
.fy:	MOVE.W	D0,12(A1)
	LEA	16(A1),A1
	ADDQ.W	#1,D7
.n:	ADDQ.L	#8,A0
	DBF	D6,.s
	MOVE.W	D7,RtgNSpr
	RTS

; RtgSprLine: the sprites of line RtgY into RtgSprLn (first opaque pixel in
; SAT order wins, at most RTGSPRMAX cells a line), then over the BG line in
; RtgLineB: a sprite pixel shows if it is over BG or the BG pixel is colour 0.
RtgSprLine:
	MOVE.W	RtgA,D7
	LEA	RtgSprT,A3
	MOVE.W	RtgNSpr,D6
	SUBQ.W	#1,D6
	MOVEQ	#0,D5			; cells on this line
	MOVE.W	#$7FFF,RtgSLo
	MOVE.W	#-$8000,RtgSHi
.s:	MOVE.W	D7,D0
	SUB.W	(A3),D0			; row in the sprite
	CMP.W	2(A3),D0
	BCC	.n			; (unsigned: above or below)
	ADD.W	6(A3),D5
	CMP.W	#RTGSPRMAX,D5
	BHI	.done
	MOVE.W	4(A3),D1		; x
	CMP.W	RtgW,D1
	BGE	.n
	MOVE.W	6(A3),D2
	LSL.W	#4,D2			; width
	MOVE.W	D1,D3
	ADD.W	D2,D3
	BLE	.n
	CMP.W	RtgSLo,D1
	BGE.S	.lo
	MOVE.W	D1,RtgSLo
.lo:	CMP.W	RtgSHi,D3
	BLE.S	.hi
	MOVE.W	D3,RtgSHi
.hi:	BTST	#1,13(A3)		; Y flip
	BEQ.S	.ny
	NEG.W	D0
	ADD.W	2(A3),D0
	SUBQ.W	#1,D0
.ny:	MOVE.W	D0,D4
	AND.W	#15,D4
	LSL.W	#4,D4			; row in the cell (16 bytes)
	LSR.W	#4,D0
	ADD.W	D0,D0			; cell row * 2
	ADD.W	8(A3),D0		; pattern of the left cell
	LEA	RtgSprLn+64,A5
	ADD.W	D1,A5
	ADD.W	D1,A5
	MOVE.W	10(A3),D3		; line word
	BTST	#0,13(A3)
	BNE.S	.xf
	BSR	RtgSprCell
	CMP.W	#1,6(A3)
	BEQ.S	.n
	ADDQ.W	#1,D0
	BSR	RtgSprCell
	BRA.S	.n
.xf:	CMP.W	#1,6(A3)		; X flip: the right cell first
	BEQ.S	.xf1
	ADDQ.W	#1,D0
	BSR	RtgSprCellF
	SUBQ.W	#1,D0
.xf1:	BSR	RtgSprCellF
.n:	LEA	16(A3),A3
	DBF	D6,.s
.done:
; merge RtgSLo..RtgSHi (clipped to the picture) over the BG line
	MOVE.W	RtgSLo,D0
	MOVE.W	RtgSHi,D1
	CMP.W	D1,D0
	BGE	.x
	MOVE.W	D0,D2			; (the whole range is cleared after)
	MOVE.W	D1,D3
	TST.W	D0
	BPL.S	.m1
	MOVEQ	#0,D0
.m1:	CMP.W	RtgW,D1
	BLE.S	.m2
	MOVE.W	RtgW,D1
.m2:	SUB.W	D0,D1
	SUBQ.W	#1,D1
	BMI.S	.clr
	LEA	RtgLineB+32,A0
	LEA	RtgSprLn+64,A1
	ADD.W	D0,A0
	ADD.W	D0,A0
	ADD.W	D0,A1
	ADD.W	D0,A1
.m:	MOVE.W	(A1)+,D4
	BEQ.S	.mn
	BMI.S	.ms			; over BG
	TST.W	(A0)
	BNE.S	.mn			; behind an opaque BG pixel
.ms:	AND.W	#$1FF,D4
	MOVE.W	D4,(A0)
.mn:	ADDQ.L	#2,A0
	DBF	D1,.m
.clr:	LEA	RtgSprLn+64,A1
	ADD.W	D2,A1
	ADD.W	D2,A1
	SUB.W	D2,D3
	SUBQ.W	#1,D3
.c:	CLR.W	(A1)+
	DBF	D3,.c
.x:	RTS

; One 16-px sprite cell: pattern D0 (masked to VRAM), row offset D4, line word
; D3, at A5 (moved on by 16 px). D0 kept. RtgSprCellF: X flipped.
RtgSprCell:
	MOVE.L	D0,-(SP)
	BSR	RtgSprSrc
	MOVEQ	#16-1,D1
.p:	MOVE.B	(A0)+,D0
	BEQ.S	.n
	TST.W	(A5)
	BNE.S	.n
	MOVE.W	D3,D2
	OR.B	D0,D2
	MOVE.W	D2,(A5)
.n:	ADDQ.L	#2,A5
	DBF	D1,.p
	MOVE.L	(SP)+,D0
	RTS
RtgSprCellF:
	MOVE.L	D0,-(SP)
	BSR	RtgSprSrc
	LEA	16(A0),A0
	MOVEQ	#16-1,D1
.p:	MOVE.B	-(A0),D0
	BEQ.S	.n
	TST.W	(A5)
	BNE.S	.n
	MOVE.W	D3,D2
	OR.B	D0,D2
	MOVE.W	D2,(A5)
.n:	ADDQ.L	#2,A5
	DBF	D1,.p
	MOVE.L	(SP)+,D0
	RTS
; A0 = the cached row (D4 = row * 16) of pattern D0 (decoded first if needed).
RtgSprSrc:
	IFEQ	NO_SPR2BPP
	CMP.W	#$200,D0
	BCC.S	.two
	LEA	RtgSValid,A0
	CMP.B	#-1,(A0,D0.W)
	BEQ.S	.ok
	BSR	RtgSprDec
	BRA.S	.ok
.two:	MOVE.W	D0,D2
	LSR.W	#8,D2
	LSR.W	#2,D2
	NOT.B	D2			; $FE or $FD
	AND.W	#$1FF,D0
	LEA	RtgSValid,A0
	CMP.B	(A0,D0.W),D2
	BEQ.S	.ok
	BSR	RtgSprDec2
	ELSE
	AND.W	#$1FF,D0
	LEA	RtgSValid,A0
	TST.B	(A0,D0.W)
	BNE.S	.ok
	BSR	RtgSprDec
	ENDC
.ok:	MOVEQ	#0,D2
	MOVE.W	D0,D2
	LSL.L	#8,D2
	RtgBuf	RtgSCache,A0
	ADD.L	D2,A0
	ADD.W	D4,A0
	MOVEQ	#0,D0
	RTS

; ---------------------------------------------------------------------------
; RtgCopy: the lines RtgFrame changed, to the framebuffer at the scale, at the
; start of an Amiga vertical blank (main loop). All registers kept.
	CNOP	0,4
RtgCopy:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	IFNE	ScanCost
	BSR	RtgCostTod
	MOVE.L	D0,RtgCostT0
	ADDQ.L	#1,RtgCostN
	ENDC
	TST.B	RtgClear
	BEQ.S	.nc
	SF	RtgClear
	IFNE	DbgRows
	ST	DbgRtgNew
	ENDC
	MOVE.L	RtgMem,A0		; geometry changed: clear the screen
	MOVE.L	RtgBpr,D0
	MULU.W	RtgScrH,D0
	LSR.L	#4,D0
	MOVEQ	#0,D1
	BRA.S	.clE
.cl:	MOVE.L	D1,(A0)+
	MOVE.L	D1,(A0)+
	MOVE.L	D1,(A0)+
	MOVE.L	D1,(A0)+
.clE:	SUBQ.L	#1,D0
	BPL.S	.cl
.nc:	IFNE	DbgRows
	MOVE.L	RtgMem,A5		; the debug panel's lines are not copied over
	MOVE.L	RtgBpr,D0
	MULU.W	#DbgRowGap+8,D0
	ADD.L	D0,A5
	ENDC
	TST.B	RtgAnyD
	BEQ	.pan
	SF	RtgAnyD
	MOVE.L	RtgBpr,D5		; bytes a row
	MOVE.W	RtgScl,D4
	MOVE.L	RtgMem,A2
	MOVE.W	RtgOY,D0
	MULU.W	D5,D0
	ADD.L	D0,A2
	MOVE.W	RtgOX,D0
	ADD.W	D0,A2
	ADD.W	D0,A2			; line 0, pixel 0
	MOVE.L	D5,D6
	MULU.W	D4,D6			; bytes a PCE line
	RtgBuf	RtgComp,A3
	LEA	RtgDirty,A4
	MOVE.W	RtgW,D3
	MOVE.W	#RTGLINES-1,D7
	IFEQ	ScanOff
	SF	RtgScanOn		; scanlines only at 2x or more
	CMP.W	#2,D4
	BCS.S	.ln
	MOVE.B	RtgScanLv,RtgScanOn
.ln:	TST.B	(A4)
	BNE.S	.lnd
	CMP.B	#4,RtgScanOn		; Blended: the line's dark row also shows the next line
	IFEQ	NO_BLENDLV
	BCS	.lnx
	ELSE
	BNE	.lnx
	ENDC
	TST.W	D7
	BEQ	.lnx
	TST.B	1(A4)
	BEQ	.lnx
.lnd:	SF	(A4)
	IFNE	ScanCost
	ADDQ.L	#1,RtgCostL
	ENDC
	ELSE
.ln:	TST.B	(A4)
	BEQ	.lnx
	SF	(A4)
	ENDC
	MOVE.L	A2,A1
	MOVE.W	D4,D2			; rows
	SUBQ.W	#1,D2
.row:
	IFNE	DbgRows
	CMP.L	A5,A1
	BCS	.rowk
	ENDC
	MOVE.L	A3,A0
	IFEQ	ScanOff
	TST.B	RtgScanOn
	BEQ.S	.sl0
	MOVE.W	D4,D0			; rows 1, 3 of the line: the scanline rows
	SUBQ.W	#1,D0
	SUB.W	D2,D0
	BTST	#0,D0
	BEQ.S	.sl0
	BSR	RtgScanRow
	BRA	.rowk
.sl0:
	ENDC
	MOVE.L	A1,-(SP)
	CMP.W	#2,D4
	BNE.S	.n2
	MOVE.W	D3,D1			; 2x: the longs as they are
	LSR.W	#3,D1
	SUBQ.W	#1,D1
.c2:	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	DBF	D1,.c2
	BRA.S	.rowx
.n2:	CMP.W	#1,D4
	BNE.S	.n1
	MOVE.W	D3,D1			; 1x: one word of each long
	SUBQ.W	#1,D1
.c1:	MOVE.L	(A0)+,D0
	MOVE.W	D0,(A1)+
	DBF	D1,.c1
	BRA.S	.rowx
.n1:	MOVE.W	D3,D1			; 3x, 4x
	SUBQ.W	#1,D1
.c3:	MOVE.L	(A0)+,D0
	MOVE.L	D0,(A1)+
	CMP.W	#3,D4
	BNE.S	.c4
	MOVE.W	D0,(A1)+
	BRA.S	.c3n
.c4:	MOVE.L	D0,(A1)+
.c3n:	DBF	D1,.c3
.rowx:	MOVE.L	(SP)+,A1
.rowk:	ADD.L	D5,A1
	DBF	D2,.row
.lnx:	ADDQ.L	#1,A4
	ADD.L	#RTGMW*4,A3
	ADD.L	D6,A2
	DBF	D7,.ln
.pan:
	IFNE	DbgRows
	TST.B	DbgRtgNew
	BEQ.S	.x
	SF	DbgRtgNew
	BSR	RtgDbgPanel
	ENDC
.x:
	IFNE	ScanCost
	BSR	RtgCostTod
	SUB.L	RtgCostT0,D0
	AND.L	#$FFFF,D0
	ADD.L	D0,RtgCostT
	ENDC
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
	IFNE	ScanCost
RtgCostTod:				; D0 = CIA-B TOD bits 15-0 (lines), as DbgTod
	MOVE.L	D1,-(SP)
.r:	MOVE.B	$BFD900,D1
	MOVE.B	$BFD800,D0
	CMP.B	$BFD900,D1
	BNE.S	.r
	LSL.W	#8,D1
	MOVE.B	D0,D1
	MOVEQ	#0,D0
	MOVE.W	D1,D0
	MOVE.L	(SP)+,D1
	RTS
RtgCostT0:	DC.L	0
RtgCostT:	DC.L	0
RtgCostN:	DC.L	0
RtgCostL:	DC.L	0
	ENDC

	IFEQ	ScanOff
; ---------------------------------------------------------------------------
; Scanlines (prefs byte $15: 0 Off, 1/2/3 = Hard 25/50/75%, 4 Blended, 5 Blended
; light, 6 Blended strong; 5 and 6 need NO_BLENDLV=0). At 2x or
; more, rows 1 (and 3) of each PCE line are drawn from the composed pixels through
; RtgScanTP (64K words, index = the 16-bit screen pixel as a signed word from the
; table's middle): Hard: the pixel with each channel x (4-n)/4; Blended: h(v) of
; each channel in the native (not byte-swapped) word, the dark row = h(this line)
; + h(next line), byte-swapped again for PC formats (ROL.W #8). h(v) = (m v + 4) / 8
; with m = 3 light, 2 Blended, 1 strong, so the row is (a + b) / 2 x 0.75, 0.50 or
; 0.25 per channel (AmiMSX and Arnold's rule); two h add with no carry out of a
; channel (NO_BLENDLV=1: one level, h(v) = v / 4).
; Off: one byte test per copied row.

; RtgScanRow: A0 = composed line, A1 = screen row, D3 = width, D4 = scale,
; D7 = 0 on the last picture line (Blended then mixes the line with itself).
RtgScanRow:
	MOVEM.L	D0-D7/A0-A2/A6,-(SP)
	MOVE.L	A0,A2
	TST.W	D7
	BEQ.S	.nx
	LEA	RTGMW*4(A0),A2		; the next line
.nx:	MOVE.L	RtgScanTP,A6
	ADD.L	#65536,A6
	MOVE.W	D3,D1
	SUBQ.W	#1,D1
	MOVEQ	#0,D7
	MOVE.B	RtgScanRol,D7
	CMP.B	#4,RtgScanOn
	IFEQ	NO_BLENDLV
	BCC.S	.bl
	ELSE
	BEQ.S	.bl
	ENDC
	CMP.W	#2,D4
	BNE.S	.h3
.h2:	MOVE.L	(A0)+,D0
	MOVE.W	(A6,D0.W*2),D0
	MOVE.W	D0,D2
	SWAP	D0
	MOVE.W	D2,D0
	MOVE.L	D0,(A1)+
	DBF	D1,.h2
	BRA.S	.x
.h3:	MOVE.L	(A0)+,D0
	MOVE.W	(A6,D0.W*2),D0
	BSR.S	.put
	DBF	D1,.h3
	BRA.S	.x
.bl:	CMP.W	#2,D4
	BNE.S	.b3
.b2:	MOVE.L	(A0)+,D0
	MOVE.L	(A2)+,D2
	MOVE.W	(A6,D0.W*2),D0
	ADD.W	(A6,D2.W*2),D0
	ROL.W	D7,D0
	MOVE.W	D0,D2
	SWAP	D0
	MOVE.W	D2,D0
	MOVE.L	D0,(A1)+
	DBF	D1,.b2
	BRA.S	.x
.b3:	MOVE.L	(A0)+,D0
	MOVE.L	(A2)+,D2
	MOVE.W	(A6,D0.W*2),D0
	ADD.W	(A6,D2.W*2),D0
	ROL.W	D7,D0
	BSR.S	.put
	DBF	D1,.b3
.x:	MOVEM.L	(SP)+,D0-D7/A0-A2/A6
	RTS
.put:	MOVE.W	D0,D2			; 3x, 4x: the pixel D4 times
	SWAP	D0
	MOVE.W	D2,D0
	MOVE.L	D0,(A1)+
	CMP.W	#3,D4
	BNE.S	.p4
	MOVE.W	D0,(A1)+
	RTS
.p4:	MOVE.L	D0,(A1)+
	RTS

; RtgScanPrep: RtgPlayOpen (OS alive), after RtgMkCol. RtgScanLv from the prefs
; byte; the table (re)built when the setting or the screen format changed.
RtgScanPrep:
	MOVEM.L	D0-D7/A0-A2,-(SP)
	MOVEQ	#0,D0
	MOVE.B	DirPrefs+$15,D0
	IFEQ	NO_BLENDLV
	CMP.B	#6,D0
	ELSE
	CMP.B	#4,D0
	ENDC
	BLS.S	.lv
	MOVEQ	#0,D0
.lv:	MOVE.B	D0,RtgScanLv
	BEQ	.x
	CMP.B	RtgScanBLv,D0
	BNE.S	.mk
	MOVE.B	RtgFmt,D1
	CMP.B	RtgScanBFmt,D1
	BEQ	.x
.mk:	MOVE.B	D0,RtgScanBLv
	MOVE.B	RtgFmt,RtgScanBFmt
	MOVE.L	D0,D6			; level
	LEA	RtgFmtTab(PC),A0
	MOVE.B	RtgFmt,D0
.f:	CMP.B	(A0),D0
	BEQ.S	.ff
	ADDQ.L	#8,A0
	BRA.S	.f
.ff:	MOVE.B	7(A0),D0		; PC: byte-swapped words
	SF	RtgScanRol
	TST.B	D0
	BEQ.S	.be
	MOVE.B	#8,RtgScanRol
.be:	MOVE.L	RtgScanTP,A1
	MOVEQ	#0,D7			; u = 0..65535
.u:	MOVE.W	D7,D1			; the pixel as a native 16-bit value
	TST.B	RtgScanRol
	BEQ.S	.u1
	ROL.W	#8,D1
.u1:	MOVEQ	#0,D2			; result
	LEA	1(A0),A2
	MOVEQ	#3-1,D5
.ch:	MOVEQ	#0,D3
	MOVE.B	(A2)+,D3		; bits
	MOVEQ	#1,D4
	LSL.L	D3,D4
	SUBQ.L	#1,D4			; max
	MOVEQ	#0,D3
	MOVE.B	(A2)+,D3		; shift
	MOVE.L	D1,D0
	AND.L	#$FFFF,D0
	LSR.L	D3,D0
	AND.L	D4,D0			; channel
	CMP.B	#4,D6
	IFEQ	NO_BLENDLV
	BCC.S	.q
	ELSE
	BEQ.S	.q
	ENDC
	MOVEQ	#4,D4
	SUB.L	D6,D4
	MULU.W	D4,D0
	LSR.L	#2,D0			; x (4 - n) / 4
	BRA.S	.c1
	IFEQ	NO_BLENDLV
.q:	MOVEQ	#2,D4			; Blended x 0.50: h = (m v + 4) / 8
	CMP.B	#4,D6
	BEQ.S	.q1
	MOVEQ	#3,D4			; light x 0.75
	CMP.B	#5,D6
	BEQ.S	.q1
	MOVEQ	#1,D4			; strong x 0.25
.q1:	MULU.W	D4,D0
	ADDQ.L	#4,D0
	LSR.L	#3,D0
	ELSE
.q:	LSR.L	#2,D0			; Blended: a quarter
	ENDC
.c1:	LSL.L	D3,D0
	OR.L	D0,D2
	DBF	D5,.ch
	CMP.B	#4,D6			; Hard: back to the screen's byte order
	IFEQ	NO_BLENDLV
	BCC.S	.st
	ELSE
	BEQ.S	.st
	ENDC
	TST.B	RtgScanRol
	BEQ.S	.st
	ROL.W	#8,D2
.st:	MOVE.W	D7,D0			; entry of u at (u EOR $8000): signed index from the middle
	EOR.W	#$8000,D0
	AND.L	#$FFFF,D0
	MOVE.W	D2,(A1,D0.L*2)
	ADDQ.L	#1,D7
	CMP.L	#65536,D7
	IFEQ	NO_BLENDLV
	BNE	.u
	ELSE
	BNE.S	.u
	ENDC
.x:	MOVEM.L	(SP)+,D0-D7/A0-A2
	RTS

; RtgScanVal: A0 = "OFF", "25", "50", "75", "BLEND", "BLENDLIGHT" or "BLENDSTRONG"
; (ToolType / CLI value; the first character decides, then the letter after BLEND) ->
; RtgScanTT and the prefs byte (embedded builds have no prefs file).
RtgScanVal:
	MOVEM.L	D0-D1,-(SP)
	MOVE.B	(A0),D0
	MOVEQ	#0,D1
	CMP.B	#48,D0			; 0
	BEQ.S	.ok
	CMP.B	#79,D0			; O
	BEQ.S	.ok
	CMP.B	#111,D0			; o
	BEQ.S	.ok
	MOVEQ	#1,D1
	CMP.B	#50,D0			; 2(5)
	BEQ.S	.ok
	MOVEQ	#2,D1
	CMP.B	#53,D0			; 5(0)
	BEQ.S	.ok
	MOVEQ	#3,D1
	CMP.B	#55,D0			; 7(5)
	BEQ.S	.ok
	MOVEQ	#4,D1
	IFEQ	NO_BLENDLV
	CMP.B	#66,D0			; B
	BEQ.S	.bl
	CMP.B	#98,D0			; b
	BNE.S	.x
.bl:	MOVEM.L	D2/A0-A1,-(SP)		; BLEND: light or strong by the letter after it
	ADDQ.L	#1,A0
	LEA	RtgScanLend(PC),A1
.bc:	MOVE.B	(A1)+,D0
	BEQ.S	.bh
	MOVE.B	(A0)+,D2
	OR.B	#32,D2
	CMP.B	D0,D2
	BEQ.S	.bc
	BRA.S	.bx
.bh:	MOVE.B	(A0),D0
	OR.B	#32,D0
	CMP.B	#108,D0			; l
	BNE.S	.b1
	MOVEQ	#5,D1
.b1:	CMP.B	#115,D0			; s
	BNE.S	.bx
	MOVEQ	#6,D1
.bx:	MOVEM.L	(SP)+,D2/A0-A1
	ELSE
	CMP.B	#66,D0			; B
	BEQ.S	.ok
	CMP.B	#98,D0			; b
	BNE.S	.x
	ENDC
.ok:	MOVE.B	D1,RtgScanTT
	MOVE.B	D1,DirPrefs+$15
.x:	MOVEM.L	(SP)+,D0-D1
	RTS

; RtgScanCli: A0 = the CLI arguments; SCANLINES=value anywhere (any case).
RtgScanCli:
	MOVEM.L	D0-D2/A0-A2,-(SP)
.s:	TST.B	(A0)
	BEQ.S	.x
	MOVE.L	A0,A1
	LEA	RtgScanCliNom(PC),A2
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
	BSR	RtgScanVal
.x:	MOVEM.L	(SP)+,D0-D2/A0-A2
	RTS

; RtgScanMenu: PonPrefs (the prefs are loaded, the menu not made yet). A
; ToolType / CLI value wins over the prefs; the sub-menu ticks follow the
; setting; the item is ghosted when RTG is not wanted.
RtgScanMenu:
	TST.B	RtgScanTT
	BMI.S	.p
	MOVE.B	RtgScanTT,DirPrefs+$15
.p:	MOVE.W	#$0010,D0		; NM_ITEMDISABLED
	TST.B	RtgWant
	BEQ.S	.g
	MOVEQ	#0,D0
.g:	MOVE.W	D0,MainMenuNewMenuSI+10
	BRA.S	RtgScanFlags

; Options > RTG scanlines: the setting for the next Power ON / Continue.
	IFEQ	NO_BLENDLV
RtgScanSet5:
	MOVEQ	#5,D0
	BRA.S	RtgScanSet
RtgScanSet6:
	MOVEQ	#6,D0
	BRA.S	RtgScanSet
	ENDC
RtgScanSet0:
	MOVEQ	#0,D0
	BRA.S	RtgScanSet
RtgScanSet1:
	MOVEQ	#1,D0
	BRA.S	RtgScanSet
RtgScanSet2:
	MOVEQ	#2,D0
	BRA.S	RtgScanSet
RtgScanSet3:
	MOVEQ	#3,D0
	BRA.S	RtgScanSet
RtgScanSet4:
	MOVEQ	#4,D0
RtgScanSet:
	MOVE.B	D0,DirPrefs+$15
; RtgScanFlags: CHECKED on the sub-item of the setting in the NewMenu table
; (menus made again later show it).
RtgScanFlags:
	IFEQ	NO_BLENDLV
	MOVEM.L	D0-D2/A0-A1,-(SP)
	MOVEQ	#0,D1
	MOVE.B	DirPrefs+$15,D1
	LEA	MainMenuNewMenuS0+10,A0
	LEA	RtgScanPos(PC),A1
	MOVEQ	#7-1,D0
.l:	MOVE.W	#$0001,(A0)		; CHECKIT
	MOVEQ	#0,D2
	MOVE.B	(A1)+,D2
	CMP.W	D2,D1
	BNE.S	.n
	MOVE.W	#$0101,(A0)		; CHECKIT | CHECKED
.n:	LEA	20(A0),A0
	DBF	D0,.l
	MOVEM.L	(SP)+,D0-D2/A0-A1
	RTS
RtgScanPos:	DC.B	0,1,2,3,5,4,6,0		; menu order -> setting
RtgScanLend:	DC.B	"lend",0
	EVEN
	ELSE
	MOVEM.L	D0-D1/A0,-(SP)
	MOVEQ	#0,D1
	MOVE.B	DirPrefs+$15,D1
	LEA	MainMenuNewMenuS0+10,A0
	MOVEQ	#0,D0
.l:	MOVE.W	#$0001,(A0)		; CHECKIT
	CMP.W	D0,D1
	BNE.S	.n
	MOVE.W	#$0101,(A0)		; CHECKIT | CHECKED
.n:	LEA	20(A0),A0
	ADDQ.W	#1,D0
	CMP.W	#5,D0
	BNE.S	.l
	MOVEM.L	(SP)+,D0-D1/A0
	RTS
	ENDC

RtgScanTTNom:	DC.B	"SCANLINES",0
RtgScanCliNom:	DC.B	"SCANLINES=",0
	EVEN
	ENDC

	IFNE	DbgRows
; RtgDbgPanel: the debug rows (DbgPanelR, 1 bit a pixel) 1:1 on the top 17
; lines of the screen, centred, dark blue and yellow as on AGA.
RtgDbgPanel:
	MOVE.L	RtgBpr,D5
	LEA	RtgCol,A0
	MOVE.W	($002*4+2)(A0),D0	; background
	MOVE.W	($1FC*4+2)(A0),D1	; digits
	MOVE.W	RtgScrW,D6
	LSR.W	#3,D6
	CMP.W	#DbgColsR,D6
	BLS.S	.c
	MOVEQ	#DbgColsR,D6
.c:	MOVE.W	RtgScrW,D2
	MOVE.W	D6,D3
	LSL.W	#3,D3
	SUB.W	D3,D2
	LSR.W	#1,D2			; left edge
	MOVE.L	RtgMem,A1
	ADD.W	D2,A1
	ADD.W	D2,A1
	LEA	DbgPanelR,A2
	MOVEQ	#DbgRowGap+8-1,D7
.r:	MOVE.L	A1,A3
	MOVE.L	A2,A4
	MOVE.W	D6,D4
	SUBQ.W	#1,D4
.b:	MOVE.B	(A4)+,D2
	MOVEQ	#8-1,D3
.p:	ADD.B	D2,D2
	BCS.S	.f
	MOVE.W	D0,(A3)+
	DBF	D3,.p
	BRA.S	.bn
.f:	MOVE.W	D1,(A3)+
	DBF	D3,.p
.bn:	DBF	D4,.b
	ADD.L	D5,A1
	LEA	DbgColsR(A2),A2
	DBF	D7,.r
	RTS
	ENDC

	IFNE	RTGSHOT
; ---------------------------------------------------------------------------
; Capture (AutoExit test builds): RtgShotKeep keeps the composed frame of PCE
; frames RtgShotA-C (1x words); RtgShotWrite, at exit with the OS alive, copies
; the last frame to the screen, reads the picture back from the framebuffer
; and writes PROGDIR:rtgshot.raw (and rtgshotA-C.raw). rtgshot.raw header:
; "RTGS", width, height (words), P96 format (long), modes seen, screen width,
; height, scale (words); rtgshotX.raw: width, height (words), then pixels.
RtgShotKeep:
	MOVE.L	AutoFrames,D0
	ADDQ.L	#1,D0			; this frame's number (as Mesen's)
	LEA	RtgShotFr(PC),A0
	LEA	RtgShotBuf,A1
	MOVEQ	#3-1,D1
.f:	CMP.L	(A0)+,D0
	BNE.S	.n
	MOVE.W	RtgW,(A1)+
	MOVE.W	#RTGLINES,(A1)+
	RtgBuf	RtgComp,A2
	MOVE.W	#RTGLINES-1,D2
.l:	MOVE.L	A2,A3
	MOVE.W	RtgW,D3
	SUBQ.W	#1,D3
.p:	MOVE.L	(A3)+,D4
	MOVE.W	D4,(A1)+
	DBF	D3,.p
	ADD.L	#RTGMW*4,A2
	DBF	D2,.l
	RTS
.n:	ADD.L	#4+RTGMW*RTGLINES*2,A1
	DBF	D1,.f
	RTS
RtgShotFr:	DC.L	RtgShotA,RtgShotB,RtgShotC

RtgShotWrite:
	MOVE.L	RtgBm,A0
	LEA	RtgRI,A1
	MOVEQ	#12,D0
	MOVE.L	RtgP96,A6
	JSR	-48(A6)			; p96LockBitMap
	MOVE.L	D0,RtgLock
	BEQ	RtgShotX
	MOVE.L	RtgRI,RtgMem2		; (P96 may have moved it with the OS back)
	MOVE.L	RtgMem,RtgMem1
	MOVE.L	RtgRI,RtgMem
	MOVEQ	#0,D0
	MOVE.W	RtgRI+4,D0
	MOVE.L	D0,RtgBpr
	BSR	RtgCopy
	BSR	RtgShotRead
	LEA	RtgShotNom2(PC),A0	; as found after the usual copy
	LEA	RtgShotHdr,A1
	BSR	RtgSave
	LEA	RtgDirty,A0		; then every line copied again
	MOVE.W	#RTGLINES-1,D0
.all:	ST	(A0)+
	DBF	D0,.all
	ST	RtgAnyD
	BSR	RtgCopy
	BSR	RtgShotRead
	BRA	RtgShotW2
RtgShotRead:
	LEA	RtgShotHdr,A0
	MOVE.L	#$52544753,(A0)+	; "RTGS"
	MOVE.W	RtgW,D0
	MULU.W	RtgScl,D0
	MOVE.W	D0,(A0)+
	MOVE.W	#RTGLINES,D1
	MULU.W	RtgScl,D1
	MOVE.W	D1,(A0)+
	MOVEQ	#0,D2
	MOVE.B	RtgFmt,D2
	MOVE.L	D2,(A0)+
	MOVE.W	RtgNModes,(A0)+
	MOVE.W	RtgScrW,(A0)+
	MOVE.W	RtgScrH,(A0)+
	MOVE.W	RtgScl,(A0)+
	LEA	RtgShotBig,A1		; the picture area from the board
	MOVE.L	RtgMem,A2
	MOVE.W	RtgOY,D3
	MULU.W	RtgBpr+2,D3
	ADD.L	D3,A2
	ADD.W	RtgOX,A2
	ADD.W	RtgOX,A2
	SUBQ.W	#1,D1
.r:	MOVE.L	A2,A3
	MOVE.W	D0,D3
	SUBQ.W	#1,D3
.c:	MOVE.W	(A3)+,(A1)+
	DBF	D3,.c
	ADD.L	RtgBpr,A2
	DBF	D1,.r
	MOVE.L	A1,D7			; end
	LEA	RtgShotHdr,A1
	SUB.L	A1,D7
	RTS
RtgShotW2:
	MOVE.L	D7,-(SP)
	MOVE.L	RtgBm,A0
	MOVE.L	RtgLock,D0
	MOVE.L	RtgP96,A6
	JSR	-54(A6)			; p96UnlockBitMap
	CLR.L	RtgLock
	MOVE.L	(SP)+,D7
	LEA	RtgShotNom(PC),A0
	LEA	RtgShotHdr,A1
	BSR	RtgSave
	LEA	RtgShotBuf,A1		; the kept frames
	MOVEQ	#65,D6			; A
.k:	TST.W	(A1)
	BEQ.S	.kn
	LEA	RtgShotNomK(PC),A0
	MOVE.B	D6,RtgShotNomL-RtgShotNomK(A0)
	MOVE.L	#4+RTGMW*RTGLINES*2,D7
	MOVE.L	A1,-(SP)
	BSR	RtgSave
	MOVE.L	(SP)+,A1
.kn:	ADD.L	#4+RTGMW*RTGLINES*2,A1
	ADDQ.B	#1,D6
	CMP.B	#68,D6			; D
	BNE.S	.k
RtgShotX:
	RTS

; RtgStatWrite: PROGDIR:rtgstat.txt, a line of hex: stage, format seen,
; play ModeID, menu ModeID, modes seen, screen width, height, bytes a row.
RtgStatWrite:
	LEA	RtgStatTxt,A1
	MOVE.L	A1,A2
	MOVEQ	#0,D0
	MOVE.B	RtgStage,D0
	BSR	.hex
	MOVEQ	#0,D0
	MOVE.B	RtgFmtSeen,D0
	BSR	.hex
	MOVE.L	RtgModeID,D0
	BSR	.hex
	MOVE.L	RtgMModeID,D0
	BSR	.hex
	MOVEQ	#0,D0
	MOVE.W	RtgNModes,D0
	BSR	.hex
	MOVE.W	RtgScrW,D0
	BSR	.hex
	MOVE.W	RtgScrH,D0
	BSR	.hex
	MOVE.L	RtgBpr,D0
	BSR	.hex
	MOVE.L	RtgMem1,D0
	BSR	.hex
	MOVE.L	RtgMem2,D0
	BSR	.hex
	IFNE	ScanCost
	MOVE.L	RtgCostT,D0
	BSR	.hex
	MOVE.L	RtgCostN,D0
	BSR	.hex
	MOVE.L	RtgCostL,D0
	BSR	.hex
	ENDC
	MOVE.B	#10,-1(A2)
	LEA	RtgStatNom(PC),A0
	MOVE.L	A2,D7
	SUB.L	A1,D7
	BRA	RtgSave
.hex:	MOVEQ	#8-1,D2
.d:	ROL.L	#4,D0
	MOVE.L	D0,D1
	AND.W	#15,D1
	MOVE.B	(RtgHexD,PC,D1.W),(A2)+
	DBF	D2,.d
	MOVE.B	#32,(A2)+
	RTS
RtgHexD:	DC.B	"0123456789ABCDEF"
RtgStatNom:	DC.B	"PROGDIR:rtgstat.txt",0
	EVEN

; RtgSave: write D7 bytes at A1 to the file named at A0. OS alive.
RtgSave:
	MOVEM.L	D2-D3/A1,-(SP)
	MOVE.L	A0,D1
	MOVE.L	#1006,D2		; MODE_NEWFILE
	MOVE.L	RtgDos,A6
	JSR	-30(A6)			; Open
	MOVEM.L	(SP)+,D2-D3/A1
	TST.L	D0
	BEQ.S	.x
	MOVE.L	D0,-(SP)
	MOVE.L	D0,D1
	MOVE.L	A1,D2
	MOVE.L	D7,D3
	JSR	-48(A6)			; Write
	MOVE.L	(SP)+,D1
	JSR	-36(A6)			; Close
.x:	RTS
	ENDC

RtgDosNom:	DC.B	"dos.library",0
RtgGfxNom:	DC.B	"graphics.library",0
RtgIntNom:	DC.B	"intuition.library",0
RtgP96Nom:	DC.B	"Picasso96API.library",0
RtgIconNom:	DC.B	"icon.library",0
RtgTTNom:	DC.B	"RTG",0
	IFNE	RTGSHOT
RtgShotNom:	DC.B	"PROGDIR:rtgshot.raw",0
RtgShotNom2:	DC.B	"PROGDIR:rtgshot0.raw",0
RtgShotNomK:	DC.B	"PROGDIR:rtgshot"
RtgShotNomL:	DC.B	"A.raw",0
	ENDC
	EVEN

; ---------------------------------------------------------------------------
	SECTION	RtgVars,DATA
RtgSTags:
RtgSTW:		DC.L	$80000023,0	; SA_Width
RtgSTH:		DC.L	$80000024,0	; SA_Height
RtgSTD:		DC.L	$80000025,0	; SA_Depth
RtgSTM:		DC.L	$80000032,0	; SA_DisplayID
		DC.L	$80000038,1	; SA_Quiet
		DC.L	$80000036,0	; SA_ShowTitle
		DC.L	$8000002D,$000F	; SA_Type: CUSTOMSCREEN
		DC.L	$8000003E,0	; SA_Draggable
		DC.L	$8000003F,1	; SA_Exclusive
		DC.L	0
RtgDos:		DC.L	0		; (RtgQuit closes these four)
RtgGfx:		DC.L	0
RtgInt:		DC.L	0
RtgP96:		DC.L	0
RtgModeID:	DC.L	-1
RtgMModeID:	DC.L	-1
RtgScr:		DC.L	0
RtgBm:		DC.L	0
RtgLock:	DC.L	0
RtgMem:		DC.L	0
RtgBpr:		DC.L	0
RtgRI:		DS.L	3		; RenderInfo: Memory, BytesPerRow, -, RGBFormat
RtgScrP:	DC.L	0
RtgScrDef:	DS.W	4		; a scroll list of one entry
RtgScrW:	DC.W	0
RtgScrH:	DC.W	0
RtgNModes:	DC.W	0
RtgW:		DC.W	0		; picture width
RtgScl:		DC.W	0		; scale
RtgOX:		DC.W	0
RtgOY:		DC.W	0
RtgY:		DC.W	0
RtgVdw:		DC.W	0
	IFNE	DbgRows
DbgRtgNew:	DC.B	0		; DbgPanelR redrawn: RtgCopy puts it on the screen
	EVEN
	ENDC
RtgHoff:	DC.W	0		; display moved right (pixels)
RtgVoff:	DC.W	0		; picture line of display line 0
RtgA:		DC.W	0		; display line of picture line RtgY
RtgNSpr:	DC.W	0
RtgSLo:		DC.W	0
RtgSHi:		DC.W	0
RtgBatXM:	DC.W	0
RtgBatYM:	DC.W	0
RtgBatCM:	DC.W	0
RtgBatS:	DC.W	0
RtgGun:		DS.W	24
	IFEQ	NO_RTGFIX
RtgBig:		DC.L	0		; AllocMem block of the big buffers (RtgStart)
RtgCompP:	DC.L	0
RtgOldP:	DC.L	0
RtgTCacheP:	DC.L	0
RtgSCacheP:	DC.L	0
	IFEQ	ScanOff
RtgScanTP:	DC.L	0		; scanline table (64K words)
	ENDC
	ENDC
	IFEQ	ScanOff
RtgScanTT:	DC.B	-1		; ToolType / CLI SCANLINES= (-1: none)
RtgScanLv:	DC.B	0		; this run's setting (RtgPlayOpen)
RtgScanOn:	DC.B	0		; this copy: the setting, 0 below 2x
RtgScanBLv:	DC.B	0		; the table holds this setting
RtgScanBFmt:	DC.B	0		; for this screen format
RtgScanRol:	DC.B	0		; 8: byte-swapped (PC) format
	EVEN
	ENDC
	IFEQ	NO_RTGPAL
RtgPLN:		DC.W	0		; VCE writes logged this frame
RtgPLP:		DC.L	0		; the next one to apply
RtgPalNext:	DC.B	0		; mid-frame colours last frame: redraw all
	EVEN
	ENDC
RtgWant:	DC.B	0		; ToolType / CLI word RTG (or RTGFORCE)
RtgOn:		DC.B	0		; this run is on RTG
RtgMenuOn:	DC.B	0		; the menu screen is on RTG
	IFEQ	TallOff
RtgTall:	DC.B	0		; the menu at double height
RtgTallNom:	DC.B	"amipcetall.font",0
	EVEN
RtgTallTA:	DC.L	RtgTallNom	; (TextAttr)
	DC.W	TALLFY
	DC.B	0,$40
RtgTallImg:	DS.B	20		; DrawImage's Image at double height
RtgTallImgT:	DC.L	GGLogo,0,0,DatsEnginePic	; picture, its copy at double height, size, an Image of its size
	DC.L	GBTeclado,0,0,DatsJoyTypePic
	DC.L	GBJoyStick,0,0,DatsJoyTypePic
	DC.L	GBJoypad,0,0,DatsJoyTypePic
	DC.L	GBCD32,0,0,DatsJoyTypePic
	DC.L	0
RtgTallWSv:	DS.L	TALLWINS*2	; the AGA layout (RtgTallUndo)
RtgTallTSv:	DS.L	2
RtgTallASv:	DS.L	2
	ENDC
RtgFmt:		DC.B	0
RtgFull:	DC.B	0		; redraw every line
RtgClear:	DC.B	0		; clear the screen at the next copy
RtgAnyD:	DC.B	0		; a line to copy
RtgInitd:	DC.B	0
RtgCR:		DC.B	0
RtgCRStart:	DC.B	0
	EVEN
RtgCRN:		DC.W	0
RtgCRP:		DC.L	0
RtgStage:	DC.B	0		; (RTGSHOT status) how far the set-up got
RtgFmtSeen:	DC.B	0
	EVEN
RtgMem1:	DC.L	0
RtgMem2:	DC.L	0
	EVEN

	SECTION	RtgBss,BSS
	CNOP	0,4
	IFNE	NO_RTGFIX
RtgComp:	DS.L	RTGMW*RTGLINES	; composed frame: screen pixels, each twice in a long
RtgOld:		DS.W	RTGMW*RTGLINES	; its palette indices (changed-line test)
RtgTCache:	DS.B	2048*64		; BG tiles, a byte a pixel
RtgSCache:	DS.B	512*256		; sprite patterns, a byte a pixel
	ENDC
RtgTValid:	DS.B	2048		; (RtgReset clears these two together)
RtgSValid:	DS.B	512
RtgSpread:	DS.B	4*256*8
RtgCol:		DS.L	512		; VCE colour -> pixel
RtgPal:		DS.L	512		; VCE entry -> pixel
RtgPalOld:	DS.W	512
RtgBgMap:	DS.W	256
RtgDirty:	DS.B	RTGLINES
	IFNE	DbgRows
DbgPanelR:	DS.B	DbgColsR*(DbgRowGap+8)	; debug rows, 1 bit a pixel
	ENDC
RtgLineB:	DS.W	16+RTGMW+16	; a line of palette indices (pixel 0 at +32)
RtgSprLn:	DS.W	32+RTGMW+64	; a line of sprite pixels (pixel 0 at +64)
RtgSprT:	DS.B	64*16
RtgCRList:	DS.L	RTGCRMAX+1	; (line, CR) of this frame's CR writes
	IFEQ	NO_RTGPAL
RtgPLog:	DS.W	4*RTGPLMAX	; (line, entry, old, new) of this frame's VCE writes
	ENDC
	IFNE	RTGSHOT
RtgStatTxt:	DS.B	128
RtgShotHdr:	DS.B	20
RtgShotBig:	DS.W	1920*1080
RtgShotBuf:	DS.B	3*(4+RTGMW*RTGLINES*2)
	ENDC
