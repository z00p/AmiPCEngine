; Lupa.asm - a game named at start (launchers such as Lupa, the Shell, a HuCard project icon).
;   AmiPCEngine [ROM] [AGA|RTG] [ONEGAME] [MENU] [PROFILE=030|FAST|AUTO] [RTGMODE=..] [SCANLINES=..]
;   [SOUNDMIX] [PLAINNTSC] (read by RtgCliArg; here they are only kept from being the ROM)
; ROM: the first word that is not a keyword (or any "quoted" word); from Workbench, a project
; icon whose default tool is the program (sm_ArgList[1]). It is loaded as Insert would and
; powered on at once; MENU: loaded, the menu stays. ONEGAME: leaving the game (Esc, Help,
; both CD32 shoulders) quits the program after the backup RAM save, and a ROM that can't be
; loaded quits it with 10 once the error is shown. AGA / RTG: the display for this run, over
; the RTG ToolType. A project icon's ToolTypes may hold AGA, ONEGAME, MENU, PROFILE= too.
; Return codes: 0 the user quit, 5 ran with a fallback (RTG asked for but not available,
; PROFILE=030: this program has one profile), 10 the ROM could not be loaded (ONEGAME),
; 20 this Amiga can't run it (no AGA, no 68020).
; Keywords take KEY=value; KEY value works too (the value is passed over here).

	CNOP	0,4
; LupaArgs: before LoadPrefs / RtgStart. MENSWB = the Workbench message or 0 (Shell).
LupaArgs:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	ST	LupaParsed		; RtgCliArg leaves the RTG word to this parser
	MOVE.L	MENSWB,D0
	BNE	LupaWB
	MOVE.L	_DosBase,A6
	JSR	-534(A6)		; GetArgStr
	TST.L	D0
	BEQ	.x
	MOVE.L	D0,A2
.next:	BSR	LupaWord		; -> LupaW, D0 = -1 at the end, D2 = 1 if "quoted"
	TST.L	D0
	BMI	.x
	TST.B	D2
	BNE	.rom			; "quoted": a file name
	BSR	LupaKey			; D0 = keyword number or -1, A1 = the value after = (or 0)
	TST.L	D0
	BMI	.word
	ADD.W	D0,D0
	MOVE.W	.tab(PC,D0.W),D0
	JMP	.tab(PC,D0.W)
.tab:	DC.W	.aga-.tab,.rtg-.tab,.one-.tab,.menu-.tab,.prof-.tab
	DC.W	.val-.tab,.val-.tab,.val-.tab,.val-.tab
	DC.W	.next-.tab,.next-.tab	; SOUNDMIX, PLAINNTSC: RtgCliArg's words, not a file name
.aga:	MOVE.B	#1,LupaDisp
	BRA	.next
.rtg:	MOVE.B	#2,LupaDisp
	BRA	.next
.one:	ST	LupaOne
	BRA	.next
.menu:	ST	LupaMenu
	BRA	.next
.prof:	MOVE.L	A1,D0
	BNE	.pv
	BSR	LupaWord		; PROFILE 030
	TST.L	D0
	BMI	.x
	LEA	LupaW,A1
.pv:	BSR	LupaProfile
	BRA	.next
.val:	MOVE.L	A1,D0			; PREFS / P / RTGMODE / SCANLINES: KEY value passes the value
	BNE	.next
	BSR	LupaWord
	TST.L	D0
	BMI	.x
	BRA	.next
.word:	LEA	LupaW,A0		; KEY=value of another kind: not a file name
.eq:	MOVE.B	(A0)+,D0
	BEQ	.rom
	CMP.B	#'=',D0
	BEQ	.next
	BRA	.eq
.rom:	TST.B	LupaRom			; the first one only
	BNE	.next
	LEA	LupaW,A0
	LEA	LupaRom,A1
.cp:	MOVE.B	(A0)+,(A1)+
	BNE	.cp
	BRA	.next
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

; Workbench: a project (sm_ArgList[1]) is the ROM; ToolTypes of the last WBArg (the project's
; icon, or the program's own).
LupaWB:
	MOVE.L	D0,A2
	MOVE.L	$24(A2),A3		; sm_ArgList
	CMP.L	#2,$1C(A2)		; sm_NumArgs: the tool and a project
	BCS.S	.tt
	MOVE.L	8(A3),D1		; wa_Lock of the project
	BEQ.S	.tt
	MOVE.L	_DosBase,A6
	MOVE.L	#LupaRom,D2
	MOVE.L	#LupaMax,D3
	JSR	-402(A6)		; NameFromLock
	TST.L	D0
	BEQ.S	.bad
	MOVE.L	#LupaRom,D1
	MOVE.L	12(A3),D2		; wa_Name
	MOVE.L	#LupaMax,D3
	JSR	-882(A6)		; AddPart
	TST.L	D0
	BEQ.S	.bad
	MOVE.L	#LupaRom,D1		; only a file that is there: the drawer's RTG icon is a project
	MOVEQ	#-2,D2			; icon (default tool AGA) with no file of its own
	JSR	-84(A6)			; Lock (SHARED_LOCK)
	MOVE.L	D0,D1
	BEQ.S	.bad
	JSR	-90(A6)			; UnLock
	BRA.S	.tt
.bad:	CLR.B	LupaRom
.tt:	MOVE.L	$1C(A2),D2
	BEQ	.x
	SUBQ.L	#1,D2
	LSL.L	#3,D2
	ADD.L	D2,A3			; the last WBArg
	MOVE.L	4.W,A6
	LEA	LupaIconNom(PC),A1
	MOVEQ	#36,D0
	JSR	-552(A6)		; OpenLibrary
	MOVE.L	D0,D5
	BEQ	.x
	MOVE.L	(A3),D1			; wa_Lock
	MOVE.L	_DosBase,A6
	JSR	-126(A6)		; CurrentDir
	MOVE.L	D0,D3
	MOVE.L	4(A3),A0		; wa_Name
	MOVE.L	D5,A6
	JSR	-78(A6)			; GetDiskObject
	MOVE.L	D0,D4
	MOVE.L	D3,D1
	MOVE.L	_DosBase,A6
	JSR	-126(A6)		; CurrentDir back
	TST.L	D4
	BEQ.S	.cl
	MOVE.L	D5,A6
	LEA	LupaKAga(PC),A1
	BSR.S	.find
	BEQ.S	.t1
	MOVE.B	#1,LupaDisp
.t1:	LEA	LupaKOne(PC),A1
	BSR.S	.find
	SNE	LupaOne
	LEA	LupaKMenu(PC),A1
	BSR.S	.find
	SNE	LupaMenu
	LEA	LupaKProf(PC),A1
	BSR.S	.find
	BEQ.S	.t2
	MOVE.L	D0,A1
	BSR	LupaProfile
.t2:	MOVE.L	D4,A0
	JSR	-90(A6)			; FreeDiskObject
.cl:	MOVE.L	D5,A1
	MOVE.L	4.W,A6
	JSR	-414(A6)		; CloseLibrary
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
.find:	MOVE.L	D4,A0			; A1 = the name -> D0 = its value or 0 (Z)
	MOVE.L	$36(A0),A0		; do_ToolTypes
	JSR	-96(A6)			; FindToolType
	TST.L	D0
	RTS

; LupaWord: A2 = the arguments -> the next word in LupaW (at most LupaMax-1 characters),
; A2 past it. D0 = its length, -1 at the end of the line; D2 = 1 if it was "quoted".
LupaWord:
	LEA	LupaW,A1
	MOVEQ	#0,D2
	MOVE.W	#LupaMax-1,D1
.sp:	MOVE.B	(A2)+,D0
	BEQ.S	.end
	CMP.B	#10,D0
	BEQ.S	.end
	CMP.B	#' ',D0
	BLS.S	.sp
	CMP.B	#'"',D0
	BNE.S	.put
	MOVEQ	#1,D2
.q:	MOVE.B	(A2)+,D0
	BEQ.S	.qe
	CMP.B	#10,D0
	BEQ.S	.qe
	CMP.B	#'"',D0
	BEQ.S	.done
	SUBQ.W	#1,D1
	BMI.S	.q
	MOVE.B	D0,(A1)+
	BRA.S	.q
.qe:	SUBQ.L	#1,A2			; the line ends inside the quotes
	BRA.S	.done
.put:	SUBQ.W	#1,D1
	BMI.S	.w
	MOVE.B	D0,(A1)+
.w:	MOVE.B	(A2)+,D0
	BEQ.S	.we
	CMP.B	#10,D0
	BEQ.S	.we
	CMP.B	#' ',D0
	BHI.S	.put
	BRA.S	.done
.we:	SUBQ.L	#1,A2
.done:	CLR.B	(A1)
	MOVE.L	A1,D0
	SUB.L	#LupaW,D0
	RTS
.end:	SUBQ.L	#1,A2
	MOVEQ	#-1,D0
	RTS

; LupaKey: LupaW against LupaKeys (any case, up to '=') -> D0 = its number or -1,
; A1 = the value after '=' or 0.
LupaKey:
	LEA	LupaKeys(PC),A1
	MOVEQ	#0,D0
.k:	TST.B	(A1)
	BEQ.S	.no
	LEA	LupaW,A0
.c:	MOVE.B	(A0)+,D1
	CMP.B	#'a',D1
	BCS.S	.u
	CMP.B	#'z',D1
	BHI.S	.u
	SUB.B	#32,D1
.u:	MOVE.B	(A1)+,D2
	BEQ.S	.ke			; the key ends: the word must end or go on with '='
	CMP.B	D2,D1
	BEQ.S	.c
.sk:	TST.B	(A1)+			; next key
	BNE.S	.sk
	ADDQ.L	#1,D0
	BRA.S	.k
.ke:	TST.B	D1			; (A1 is at the next key now)
	BEQ.S	.y0
	CMP.B	#'=',D1
	BNE.S	.nx
	MOVE.L	A0,A1			; KEY=value
	RTS
.y0:	SUB.L	A1,A1
	RTS
.nx:	ADDQ.L	#1,D0
	BRA.S	.k
.no:	MOVEQ	#-1,D0
	RTS

; LupaProfile: A1 = the value: 030 -> return code 5 (one profile here: it runs as FAST).
LupaProfile:
	CMP.B	#'0',(A1)
	BNE.S	.x
	CMP.B	#'3',1(A1)
	BNE.S	.x
	CMP.B	#'0',2(A1)
	BNE.S	.x
	MOVEQ	#5,D0
	MOVE.L	D0,LupaRC
.x:	RTS

; LupaDispApply (RtgStart, after the RTG word / ToolType): AGA or RTG from the arguments.
LupaDispApply:
	MOVE.B	LupaDisp,D0
	BEQ.S	.x
	SUBQ.B	#1,D0
	SNE	RtgWant			; 1 AGA, 2 RTG
.x:	MOVE.B	RtgWant,LupaAskRtg
	RTS

; LupaRtgCheck (after RtgStart): RTG asked for but not there -> return code 5.
LupaNoRun:			; (Programa: no AGA or no 68020)
	MOVEQ	#20,D0
	MOVE.L	D0,LupaRC
	BRA	Quitar

	IFEQ	OcsRtgOff
; LupaNoAga (RtgStart, no AGA chipset): AGA asked for, RTG instead -> return code 5.
LupaNoAga:
	CMP.B	#1,LupaDisp
	BNE.S	.x
	MOVEQ	#5,D0
	MOVE.L	D0,LupaRC
.x:	RTS
	ENDC

LupaRtgCheck:
	TST.B	LupaAskRtg
	BEQ.S	.x
	TST.B	RtgWant
	BNE.S	.x
	MOVEQ	#5,D0
	MOVE.L	D0,LupaRC
.x:	RTS

; LupaAuto (Control, the main menu's first pass): the ROM, Power ON; ONEGAME: quit after it.
LupaAuto:
	TST.B	LupaDone
	BNE.S	.x
	ST	LupaDone
	TST.B	LupaRom
	BEQ.S	.x
	LEA	LupaRom,A0
	LEA	FileNom,A1
.cp:	MOVE.B	(A0)+,(A1)+
	BNE.S	.cp
	SF	LupaErr
	JSR	DisMouse
	JSR	InsertLoad		; as Insert after the requester (errors in the error window)
	TST.B	LupaErr
	BNE.S	.err
	TST.L	BucCart
	BEQ.S	.err
	TST.B	LupaMenu
	BNE.S	.x
	JSR	PowerON
	TST.B	LupaOne
	BEQ.S	.x
	ST	LupaQuit		; ONEGAME: the game is left, the program quits
.x:	RTS
.err:	TST.B	LupaOne
	BEQ.S	.x
	MOVEQ	#10,D0
	MOVE.L	D0,LupaRC
	ST	LupaQuit
	RTS

	IFNE	LupaTest
LupaTestCnt:	DC.L	LupaTest	; (test builds) frames left in the game
	ENDC
LupaMax=256
LupaKeys:	DC.B	"AGA",0,"RTG",0,"ONEGAME",0,"MENU",0,"PROFILE",0
		DC.B	"PREFS",0,"P",0,"RTGMODE",0,"SCANLINES",0
		DC.B	"SOUNDMIX",0,"PLAINNTSC",0,0
LupaKAga:	DC.B	"AGA",0
LupaKOne:	DC.B	"ONEGAME",0
LupaKMenu:	DC.B	"MENU",0
LupaKProf:	DC.B	"PROFILE",0
LupaIconNom:	DC.B	"icon.library",0
LupaDisp:	DC.B	0		; 0 as the icon / prefs say, 1 AGA, 2 RTG
LupaAskRtg:	DC.B	0		; RTG wanted when RtgStart looked
LupaOne:	DC.B	0		; ONEGAME
LupaMenu:	DC.B	0		; MENU
LupaDone:	DC.B	0
LupaParsed:	DC.B	0		; LupaArgs ran (the menu program, not an EMBED build)
LupaErr:	DC.B	0		; Insert's loading code met an error
LupaQuit:	DC.B	0		; the menu quits (ONEGAME)
	CNOP	0,4
LupaRC:		DC.L	0		; the program's return code
LupaRom:	DS.B	LupaMax
LupaW:		DS.B	LupaMax
	CNOP	0,4
