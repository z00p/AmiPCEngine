
;	Menu para AmiPCEngine Emulator.
;	Por: Juan Antonio Gómez Gálvez

;    DC.L    $80000093,1			; En MainMenuWIN
;    DC.L    $80080032,6,$00000000		; En MTags0

_SysBase=4


; <=-----------------------=>
	CNOP	0,8
MenuLaunch:
; <=----------------------------------=>
	MOVEQ	#0,D0
	LEA	GadNom(PC),A1
	MOVE.L	$4.W,A6
	JSR	-$228(A6)
	MOVE.L	D0,_GadToolsBase
	BEQ	LibsError
; <=----------------------------------=>
	MOVEQ	#0,D0
	LEA	IntNom(PC),A1
	MOVE.L	$4.W,A6
	JSR	-$228(A6)
	MOVE.L	D0,_IntuitionBase
	BEQ	LibsError
; <=----------------------------------=>
	MOVEQ	#0,D0
	LEA	DosNom(PC),A1
	MOVE.L	$4.W,A6
	JSR	-$228(A6)
	MOVE.L	D0,_DosBase
	BEQ	LibsError
; <=----------------------------------=>
	MOVEQ	#0,D0
	LEA	AslNom(PC),A1
	MOVE.L	4.W,A6
	JSR	-$228(A6)
	MOVE.L	D0,_AslBase
; <=----------------------------------=>
	MOVEQ	#0,D0
	LEA	XpkNom(PC),A1
	MOVE.L	4.W,A6
	JSR	-$228(A6)
	MOVE.L	D0,_XpkBase
; <=----------------------------------=>
	MOVEQ	#3,D0
	LEA	StcNom(PC),A1
	MOVE.L	4.W,A6
	JSR	-$228(A6)
	MOVE.L	D0,_StcBase
	BNE.S	YaStc20
	MOVEQ	#3,D0
	LEA	Stc2Nom(PC),A1
	MOVE.L	4.W,A6
	JSR	-$228(A6)
	MOVE.L	D0,_StcBase
YaStc20:
	IFEQ	ChoosOff
	MOVEQ	#ChooserVer,D0
	LEA	ChoLibNom(PC),A1
	MOVE.L	4.W,A6
	JSR	-$228(A6)		; OpenLibrary: none (OS 3.1) = the cycle gadgets
	MOVE.L	D0,_ChooserBase
	ENDC
; <=-----------------------=>

; <=----------------------------------=>
	CLR.L	MENSWB
	MOVE.L	$4.W,A6
	SUB.L	A1,A1
	JSR	-$126(A6)
	MOVE.L	D0,A2
	TST.L	$AC(A2)
	BNE.S	CLI
	LEA	$5C(A2),A0
	JSR	-$180(A6)
	LEA	$5C(A2),A0
	JSR	-$174(A6)
	MOVE.L	D0,MENSWB
	MOVE.L	D0,A2
	MOVE.L	$24(A2),D0
	BEQ.S	CLI
	MOVE.L	_DosBase,A6
	MOVE.L	D0,A0
	MOVE.L	(A0),D1
	JSR	-$7E(A6)
CLI:
	IFEQ	NO_MENU2
	BSR	LoadPrefs		; before RtgStart: the prefs' Display setting
	ENDC
	IFEQ	NO_RTG
	MOVE.L	MENSWB(PC),A0		; RTG: ToolType or CLI word, the P96 modes
	JSR	RtgStart
	IFNE	AGC
	JSR	AgcStart		; AGA chunky mode test builds: its buffers (no RTG wanted)
	ENDC
	ENDC
; <=----------------------------------=>

	LEA	DirInfoText(PC),A0
	BSR	Centrar

; <=-----------------------=>

	BSR	Programa

; <=-----------------------=>
	MOVE.L	BucCart(PC),D0
	BEQ.S	NoHayCart2
	MOVE.L	DirCart(PC),A1
	MOVE.L	$4.W,A6
	JSR	-$D2(A6)		; Libera memoria.
	CLR.L	BucCart
NoHayCart2:
; <=-----------------------=>
	TST.L	_AslBase(PC)
	BEQ.S	NoHayAsl2

	MOVE.L	InsReqBase,A0
	MOVE.L	_AslBase,A6
	JSR	-$36(A6)	; FreeAslRequest.
NoHayAsl2:
; <=-----------------------=>
	MOVE.L	$4.W,A6
	TST.L	MENSWB(PC)
	BEQ.S	MENSWBRET
	JSR	-$84(A6)
	MOVE.L	MENSWB(PC),A1
	JSR	-$17A(A6)
MENSWBRET:
	IFEQ	NO_RTG
	JSR	RtgQuit
	ENDC
; <=-----------------------=>

; <=-----------------------=>
LiberaLib:MACRO
	MOVE.L	\1,A1
	TST.L	A1
	BEQ.S	\@LibLib
	MOVE.L	$4.W,A6
	JSR	-$19E(A6)	; Libera Librería.
\@LibLib:
	ENDM

LibsError:
	LiberaLib _DosBase
	LiberaLib _IntuitionBase
	LiberaLib _GadToolsBase
	LiberaLib _AslBase
	LiberaLib _XpkBase
	LiberaLib _StcBase
	IFEQ	ChoosOff
	LiberaLib _ChooserBase
	ENDC
MenuRET:
	RTS
; <=-----------------------=>

; <=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=>

;*;	DC.L	$80080001,Texto Ventana
;*;	DC.L	$80080002,Screen WND donde aparece el requester.
;*;	DC.L	$80080003,Coor X
;*;	DC.L	$80080004,Coor Y
;*;	DC.L	$80080005,Size X
;*;	DC.L	$80080006,Size Y
;*;	DC.L	$80080009,Directorio
;*;	DC.L	$8008000A,PatrÓn
;*;	DC.L	$80080012,Texto Ok
;*;	DC.L	$80080013,Texto Cancel
;*;	DC.L	$80080014,Patron On=1/Off=0
;*;	DC.L	$8008002F,1	; 1=Modo Directorios.
;*;	DC.L	$8008003C,1	; 1=No muestra los "#?.info"

	CNOP	0,4
InsTags:
	DC.L	$80080002,0
	DC.L	$80080012,tInsert
	DC.L	$80080003,165
	DC.L	$80080004,11
	DC.L	$80080006,196
	DC.L	$8008003C,11		; No muestra los "#?.info"
	DC.L	$80080009,DirPrefs+$20
	DC.L	0,0

	CNOP	0,4
InsLoadTags:
	DC.L	$80080012,tInsert
	DC.L	$80080001,tInsLoad
	DC.L	$8008002C,0		; 0=Modo Load.
	DC.L	0,0


	EVEN
tInsert:DC.B	"Insert",0,0
tInsLoad:DC.B	"Select Cartridge file.",0,0

; <=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=>

; <=-----------------------=>
	CNOP	0,8
DirInfoText:
	DC.L	AboutText0,324
	DC.L	AboutText1,324
	DC.L	AboutText2,324
	DC.L	AboutText3,324
	IFEQ	NO_REL10
	DC.L	AboutTextZ,324
	ENDC
	DC.L	AboutText4,324
	DC.L	AboutText5,324
	DC.L	AboutText6,324
	DC.L	AboutText7,324
	DC.L	AboutText8,324
	DC.L	AboutText9,324
	DC.L	AboutText10,324
	DC.L	0,0,0,0
; <=-----------------------=>

; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
		CNOP	0,4
DisBase:	DC.L	0
BucFile:	DC.L	0
InsReqBase:	DC.L	0
XpkFibBase:	DC.L	0
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
DirCart:	DC.L	0
BucCart:	DC.L	0
PagCart:	DC.W	0
Comprimido:	DC.B	0
RawCartSize:	DC.B	0
EsUn060:	DC.B	0,0
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
_GadToolsBase:	DC.L	0
_IntuitionBase:	DC.L	0
_DosBase:	DC.L	0
_AslBase:	DC.L	0
_XpkBase:	DC.L	0
_StcBase:	DC.L	0
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
		CNOP	0,8
GadNom:		DC.B	"gadtools.library",0
IntNom:		DC.B	"intuition.library",0
DosNom:		DC.B	"dos.library",0
AslNom:		DC.B	"asl.library",0
XpkNom:		DC.B	"xpkmaster.library",0
StcNom:		DC.B	"stc.library",0
	IFEQ	ChoosOff
ChoLibNom:	DC.B	"gadgets/chooser.gadget",0
	EVEN
_ChooserBase:	DC.L	0
	ENDC
Stc2Nom:	DC.B	"stc020.library",0
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
		CNOP	0,8
MENSWB:		DC.L	0
ControlKeys:	DC.W	0
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
		CNOP	0,4
FileNom:	DS.B	$208
		CNOP	0,4
BuferDsk:	DS.L	8
		CNOP	0,4
Examine:	DS.B	520
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
		DS.L	25	; Seguriad

tErNoAsl:	DC.B	"      I need asl.library      ",0
tErNoStc:	DC.B	"I need stc.library for unpack!",0
tErNoCartucho:	DC.B	"   Cartridge not inserted!!   ",0
tErOpenFile:	DC.B	" I cannot open file selected! ",0
tErReadFile:	DC.B	"Error while loading Cartridge!",0
tErNoNESCart:	DC.B	"      Invalid Cartridge!      ",0
tErOutOfMem:	DC.B	"   -=>  Out of memory!  <=-   ",0
	IFNE	NO_MENU2
tErChecksum:	DC.B	" CAUTION:  Checksum is wrong! ",0
	ENDC
tErSavePrefs:	DC.B	"    Preferences not saved!    ",0
	IFEQ	NO_BRAMSAVE
tErSaveBram:	DC.B	"     Game save not written!   ",0
	ENDC
	IFNE	NO_MENU2
tErIDNoCorrecto:DC.B	"CAUTION: Bad GameBoy ID '00C3'",0
tErPila:	DC.B	"   6502's Stack Gets Crazy!   ",0
tErCodiLegal:	DC.B	"  Código ilegal $00 en $0000  ",0
	ELSE
tErPila:	DC.B	"   HuC6280 stack overflow!    ",0
	ENDC
tErNoMapSupp:	DC.B	" This mapper is not supported ",0

; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
		DS.L	10	; Seguriad
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-

	CNOP	0,8
CabFileBuf:	DS.L	4
EngineInfoBuf:	DS.L	4
*************************************************************
		DS.L	25	; Seguriad
*************************************************************
*************************************************************

; ------------------------------------------
; ******************************************
; ------------------------------------------

	CNOP	0,8
Programa:
; ------------------------------------------
	IFNE	NO_MENU2
	BSR	LoadPrefs
	ENDC
	BSR	PonPrefs
; ------------------------------------------
	IFEQ	NO_RTG|NO_RTGFIX
	JSR	RtgMenuScreen		; (P96 menu screen failed: the native one)
	ELSE
	BSR	SetupScreen
	ENDC
; ------------------------------------------

	BSR	MiraAGA
	TST.L	D0
	BEQ	Quitar

	BSR	MC68020
	TST.L	D0
	BEQ	Quitar

;;	BSR	CheckAGA

; ------------------------------------------

; ------------------------------------------
	MOVEM.L	MCeros,D0-D7/A0-A6
	BSR	OpenMainMenuWindow
; ------------------------------------------
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	move.l  Scr,a0
	move.l  40(a0),a1
	move.w  4(a1),D1
	MOVE.L	MainMenuWnd,A0
	MOVE.L	50(A0),A0
	LEA	DatsEnginePic,A1
	MOVE.L	_IntuitionBase,A6
	TallImgJsr
; ------------------------------------------
	BSR	ImpJoyType
; ------------------------------------------
	IFNE	DispTest		; test builds: as if the Display gadget had been set to DispTest-1 (0 AGA, 1 RTG)
	MOVEQ	#DispTest-1,D0
	MOVE.W	#GD_INTER,D1
	BSR	SetCycle
	BSR	DispSel
	ENDC
	IFNE	PadTest			; test builds: port 1 = CD32 pad, port 2 = joypad (both read every frame)
	MOVEQ	#2,D0
	MOVE.W	#GD_JoyPort,D1
	BSR	SetCycle
	MOVEQ	#3,D0
	MOVE.W	#GD_JoyType,D1
	BSR	SetCycle
	BSR	ImpJoyType
	ENDC
; <=-----------------------=>
	TST.L	_AslBase(PC)
	BEQ.S	NoHayAsl

	MOVEQ	#0,D0
	LEA	InsTags(PC),A0
	MOVE.L	MainMenuWnd,4(A0)
	MOVE.L	_AslBase,A6
	JSR	-$30(A6)	; AllocAslRequest.
	MOVE.L	D0,InsReqBase
NoHayAsl:
; <=-----------------------=>
BucleMenu:
; ------------------------------------------
	LEA	MainMenuPunts,A1
	BSR	Control
; ------------------------------------------
	BSR	CloseMainMenuWindow
; ------------------------------------------
Quitar:	JSR	CloseDownScreen
; ------------------------------------------=> Quit
	MOVEQ	#0,D0	; Salir Sín Errores

	MOVEQ	#0,D7
	RTS
; ------------------------------------------
; ------------------------------------------
; ------------------------------------------

; <=-----------------------=>
	CNOP	0,8
NeedASL:
	LEA	tErNoAsl(PC),A0
	JMP	ImpError
; <=-----------------------=>

; ------------------------------------------
; ******************************************
; ------------------------------------------

About:
	BSR	DisMouse
	MOVEM.L	MCeros,D0-D7/A0-A6
	BSR	OpenAboutWindow

; TEMPORAL:
	LEA	AboutGadgets+(GD_AboutCont*4),A0
	MOVE.L	AboutWnd,A1
	MOVEQ	#1,D0
	BSR	GadsOnOff


	LEA	AboutPunts,A1
	BSR	Control

	BSR	CloseAboutWindow
	BSR	EnaMouse
	RTS

; ------------------------------------------
; ******************************************
; ------------------------------------------

HelpPage:
	BSR	DisMouse
	MOVEM.L	MCeros,D0-D7/A0-A6
	BSR	OpenHelpPageWindow

	MOVEQ	#20,D0
	MOVEQ	#16,D1
	MOVE.L	#GBTeclado,DirJoyTypePic
	BSR	ImprHelpJoy

	MOVE.L	#264,D0
	MOVEQ	#16,D1
	MOVE.L	#GBCD32,DirJoyTypePic
	BSR	ImprHelpJoy

	MOVEQ	#20,D0
	MOVE.L	#110,D1
	MOVE.L	#GBJoyStick,DirJoyTypePic
	BSR	ImprHelpJoy

	MOVE.L	#264,D0
	MOVE.L	#110,D1
	MOVE.L	#GBJoypad,DirJoyTypePic
	BSR	ImprHelpJoy

	LEA	HelpPagePunts,A1
	BSR	Control

	BSR	CloseHelpPageWindow
	BSR	EnaMouse
	RTS

ImprHelpJoy:
	move.l  Scr,a0
	move.l  40(a0),a1
	ADD.w	4(a1),D1
	MOVE.L	HelpPageWnd,A0
	MOVE.L	50(A0),A0
	LEA	DatsJoyTypePic,A1
	MOVE.L	_IntuitionBase,A6
	TallImgJmp

; ------------------------------------------
; ******************************************
; ------------------------------------------

ImpError:
	MOVE.L	A0,ImpErrorText0+$C

	BSR	DisMouse

	MOVEM.L	MCeros,D0-D7/A0-A6
	BSR	OpenImpErrorWindow

	LEA	ImpErrorPunts,A1
	BSR	Control

	BSR	CloseImpErrorWindow
	BSR	EnaMouse
	RTS

; ------------------------------------------
; ******************************************
; ------------------------------------------



; ------------------------------------------
; ******************************************
; ------------------------------------------



; ------------------------------------------
; ******************************************
; ------------------------------------------


; ------------------------------------------
; ------------------------------------------
; ------------------------------------------


; ------------------------------------------
; ******************************************
; ------------------------------------------

	CNOP	0,8
Continue:
	MOVEQ	#-1,D7
	BRA.S	ContinueCon
	CNOP	0,8
PowerON:
	MOVEQ	#1,D7
	IFEQ	NO_BRAMSAVE
	BSR	BramLoad
	ENDC
ContinueCon:
	LEA	tErNoCartucho(PC),A0
	TST.L	BucCart(PC)
	BEQ	ImpError


	SF	DesborPILA			; *\*\*  POR QUITAR  */*/*


	MOVEM.L	D0-D7/A0-A6,-(SP)
	BSR	ActuPrefs
	MOVEM.L	(SP)+,D0-D7/A0-A6
; -=-=-
	LEA	DirPrefs(PC),A5
; -=-=-
	IFNE	NO_MENU2
	IFNE	AGC&DbgRows
	TST.B	AgcWant			; AGA chunky mode with the debug rows: a PAL screen (the screen gadget is
	BEQ.S	.agcntsc		; ghosted): only PAL has room for the rows under the picture
	CLR.B	$0F(A5)
.agcntsc:
	ENDC
	MOVEQ	#0,D1
	ELSE
	MOVEQ	#0,D1
	IFNE	AGC
	TST.B	AgcWant			; AGA colour mode: NTSC (the screen gadget is ghosted); with the debug
	BEQ.S	.agcntsc		; rows PAL: only PAL has room for the rows under the picture
	IFNE	DbgRows
	MOVE.W	#$20,D1
	ENDC
	BRA.S	NoEsNTSC
.agcntsc:
	ENDC
	ENDC
	TST.B	$0F(A5)			; Frecuencia pantalla.
	BNE.S	NoEsNTSC
	MOVE.W	#$20,D1
NoEsNTSC:MOVE.W	D1,$DFF1DC
; -=-=-
	IFD	NF_Menu
	IFEQ	NO_RTG|NO_RTGFIX
	JSR	RtgMenuPlay		; RTG play screen failed with the menu on RTG: no start
	TST.L	D0
	BEQ.S	.rtgok
	IFEQ	DispOff
	BSR	DispSync		; RTG is off now: the gadget says AGA
	ENDC
	LEA	tErRtgScr,A0
	BRA	ImpError
.rtgok:
	ENDC
	JSR	EmulatorStart
	IFEQ	DispOff
	JSR	RtgCurtainOff		; (AGA play with the menu on RTG)
	ENDC
	ENDC
; -=-=-
	BSR	RefrescaReloj
; -=-=-
	IFEQ	NO_BRAMSAVE
	BSR	BramSave
	IFEQ	NO_MENU2
	BSR	BramAfter		; the Backup RAM text
	ENDC
	ENDC

	TST.B	DesborPILA			; *\*\*  POR QUITAR  */*/*
	BEQ.S	NoDerPila
	LEA	tErPila(PC),A0
	BSR	ImpError
NoDerPila:					; *\*\*  POR QUITAR  */*/*



	LEA	MainMenuGadgets+(GD_Continue*4),A0
	MOVE.L	MainMenuWnd,A1
	MOVEQ	#0,D0
	BSR	GadsOnOff
; -=-=-
	RTS


DesborPILA:	DC.B	0			; *\*\*  POR QUITAR  */*/*
		DC.B	0

; ------------------------------------------
; ******************************************
; ------------------------------------------

	CNOP	0,8
Eject:
	TST.L	BucCart(PC)
	BEQ	EjNoHayCart

	MOVE.L	BucCart(PC),D0
	MOVE.L	DirCart(PC),A1
	MOVE.L	$4.W,A6
	JSR	-$D2(A6)		; Libera memoria.
	CLR.L	BucCart
	CLR.L	DirCart


	MOVE.L	#tTipoROM,MainMenuText9+$C		; 'ROM:' ----
	MOVE.L	#MainMenuIText12,MainMenuText12+$C		; No Cart Inserted.
	IFEQ	NO_MENU2|NO_BRAMSAVE
	MOVE.L	#tBramDash,MainMenuText11+$C
	ENDC


	MOVE.L	InsReqBase,A2
	MOVE.L	4(A2),A0
	LEA	tNomFileCart,A1
	BSR	PONOM
	move.l  _IntuitionBase,a6
	move.l  MainMenuWnd,a0
	move.b  54(a0),d0
	ext.w   d0
	move.b  55(a0),d1
	ext.w   d1
	move.l  50(a0),a0
	lea	MainMenuText9,a1
	TallITextM
EjNoHayCart:

	LEA	MainMenuGadgets+(GD_Continue*4),A0
	MOVE.L	MainMenuWnd,A1
	MOVEQ	#1,D0
	BSR	GadsOnOff

	RTS

; ------------------------------------------

	CNOP	0,8
Insert:
	TST.L	_AslBase(PC)
	BEQ	NeedASL

	BSR	DisMouse

	MOVE.L	InsReqBase,A0
	LEA	InsLoadTags,A1
	MOVE.L	_AslBase,A6
	JSR	-$3C(A6)	; RequestFile.

	TST.L	D0
	BEQ	ReqCancel


	MOVE.L	InsReqBase,A2
	BSR	ArreglaNom
InsertLoad:			; FileNom set: load it (MenuAuto test builds come in here)


;	--------------------
	TST.L	_XpkBase(PC)		; Mira si es un xpk.
	BEQ.S	NoXpkFile

	LEA	XpkFibBase,A0		; ¿Fichero xpk?
	LEA	xpkTags0(PC),A1
	MOVE.L	_XpkBase,A6
	JSR	-54(A6)		; xpkOpen
	BNE.S	NoXpkFile

	MOVE.L	XpkFibBase,A0		; ¿Comprimido con xpk?
	CMP.L	#1,(A0)
	BNE.S	NoXpkFile

	MOVE.L	4(A0),-(SP)

	MOVE.L	XpkFibBase,A0
	MOVE.L	_XpkBase,A6
	JSR	-78(A6)		; xpkClose

	MOVE.L	(SP)+,D0
	MOVE.L	D0,BucFile
	BSR	MiraCartSize
	BEQ.S	NoXpkFile

	MOVE.B	#$7F,Comprimido
	BRA.S	EsXpkFile
NoXpkFile:

;	--------------------
	MOVE.L	#FileNom,D1		; Open File
	MOVE.L	#$3ED,D2
	BSR	OpenFile
	BEQ	OpenError

	BSR	LongFile		; Mira Size.
	MOVE.L	D0,BucFile
	BEQ	ReadError

	MOVE.L	#(4*4),D3
	MOVE.L	#CabFileBuf,D2
	BSR	ReadFile
	BNE	ReadError

	CMP.W	#"S4",CabFileBuf
	BNE.S	NoStcComp
	MOVE.L	CabFileBuf+$08(PC),D0
	BSR	MiraCartSize
	BEQ.S	NoStcComp

	TST.L	_StcBase(PC)
	BEQ	ErNoStc

	ST	Comprimido
	BRA.S	SiStcComp
NoStcComp:

;	--------------------
	MOVE.L	BucFile(PC),D0
	BSR	MiraCartSize
	BEQ	NoNESCart
	SF	Comprimido
SiStcComp:
EsXpkFile:
	MOVE.W	D0,PagCart
	MULU	#$2080,D0		; 8Kb x page
	ADD.L	#$0080,D0
	MOVE.L	D0,-(SP)

	MOVE.L	BucCart(PC),D0
	BEQ.S	NoHayCart
	MOVE.L	DirCart(PC),A1
	MOVE.L	$4.W,A6
	JSR	-$D2(A6)		; Libera memoria.
	CLR.L	BucCart
NoHayCart:
	MOVE.L	(SP)+,BucCart

	MOVE.L	#$00010001,D1
	MOVE.L	BucCart,D0
	MOVE.L	4.W,A6
	JSR	-$C6(A6)		; Requiere memoria.
	MOVE.L	D0,DirCart
	BEQ	OutOfMem

;	--------------------

	CMP.B	#$7F,Comprimido
	BNE.S	NoDescomXpk

	LEA	xpkTags1(PC),A0
	MOVE.L	DirCart(PC),$0C(A0)
	ADD.L	#$80,$0C(A0)
	MOVE.L	BucCart(PC),$14(A0)	; tendria que ser BucFile
	MOVE.L	_XpkBase,A6
	JSR	-48(A6)		; xpkUnPack
;;	B??  error

	BRA.S	NoCompri0
NoDescomXpk:

;	--------------------
	LEA	CabFileBuf(PC),A1
	MOVE.L	DirCart,A0
	TST.B	Comprimido(PC)
	BNE.S	SiCompri0
	ADD.W	#$80,A0
SiCompri0:
	MOVE.L	(A1)+,(A0)+
	MOVE.L	(A1)+,(A0)+
	MOVE.L	(A1)+,(A0)+
	MOVE.L	(A1)+,(A0)+
	MOVE.L	A0,D2
	MOVE.L	BucFile(PC),D3
	SUB.L	#(4*4),D3
	BSR	ReadFile
	BNE	ReadError

	BSR	CloseFile
; -=-=-

	TST.B	Comprimido(PC)
	BEQ.S	NoCompri0

;	--------------------
	MOVE.L	DirCart,A1
	LEA	$80(A1),A0
	MOVE.L	_StcBase,A6
	JSR	-$24(A6)
	MOVE.L	DirCart,A0
	MOVE.W	#($80/4)-1,D0
DesStcBuc:
	CLR.L	(A0)+
	DBF	D0,DesStcBuc
	MOVE.L	CabFileBuf+$08,BucFile
NoCompri0:
; -=-=-
	TST.B	RawCartSize(PC)		; Para soportar el skip 512 bytes.
	BEQ.S	SiRawCartSize
	MOVE.L	DirCart,A0
	ADD.W	#$80,A0
	MOVE.L	BucFile,D0
	SUB.L	#$200,D0
BucRawCartSize:
	MOVE.B	$200(A0),(A0)+
	SUBQ.L	#1,D0
	BNE.S	BucRawCartSize
SiRawCartSize:
; -=-=-

; -=-=-
;	MOVE.L	DirCart,A0
;	ADD.W	#$80,A0
;	MOVE.W	PagCart,D0
;	MOVE.W	D0,D1
;	MULU	#$4080,D1
;	LEA	(A0,D1.L),A1
;	MOVE.W	D0,D1
;	MULU	#$4000,D1
;	LEA	(A0,D1.L),A0
;	SUBQ.W	#1,D0
;ArrROMPagBuc0:
;	MOVEQ	#($80/4)-1,D1
;ArrROMPagBuc1:
;	CLR.L	-(A1)
;	DBF	D1,ArrROMPagBuc1
;	MOVE.W	#($4000/4)-1,D1
;ArrROMPagBuc2:
;	MOVE.L	-(A0),-(A1)
;	DBF	D1,ArrROMPagBuc2
;	DBF	D0,ArrROMPagBuc0

; -=-=-=-

	MOVE.L	#tNomFileCart,MainMenuText12+$C

	MOVEQ	#-1,D1
	MOVE.W	PagCart,D0
;;	AND.W	#$FF,D0
	BEQ.S	InCalRom1
InCalRom:
	ADDQ.W	#1,D1
	LSR.W	#1,D0
	BCC.S	InCalRom
	MOVE.L	(TipoROM.W,PC,D1.W*4),MainMenuText9+$C
InCalRom1:


; -=-=-=-


	MOVE.L	InsReqBase,A2
	MOVE.L	4(A2),A0
	LEA	tNomFileCart,A1
	BSR	PONOM
	IFEQ	NO_MENU2|NO_BRAMSAVE
	BSR	BramFind		; the Backup RAM text: is there a save for this game?
	ENDC

	move.l  _IntuitionBase,a6
	move.l  MainMenuWnd,a0
	move.b  54(a0),d0
	ext.w   d0
	move.b  55(a0),d1
	ext.w   d1
	move.l  50(a0),a0
	lea	MainMenuText9,a1
	TallITextM

	LEA	MainMenuGadgets+(GD_Continue*4),A0
	MOVE.L	MainMenuWnd,A1
	MOVEQ	#1,D0
	BSR	GadsOnOff

;;;	BSR	MiraTipoCart

	MOVE.B	EngineInfoBuf+6,D0
	LSR.B	#4,D0
	BEQ.S	EspeMapSi
	CMP.B	#2,D0
	BEQ.S	EspeMapSi
	LEA	tErNoMapSupp(PC),A0
	BSR	ImpError
EspeMapSi:


	BSR	EnaMouse
	RTS

; ------------------------------------------

MiraTipoCart:
	RTS
;	LEA	tNomFileCart,A0
;	BSR	BuscaExt
;	TST.L	D0
;	BMI.S	NoCanviEmul
;; ---
;	MOVEQ	#0,D1			; Nuevo valor!!!
;	MOVE.W	D0,D1
;	LEA	MainMenuPunts,A0
;	MOVE.L	#GD_EmuType,D2
;	MOVE.L	#$8008000F,D0
;	BSR	CanviTAGS
;; ---
;NoCanviEmul:
;	RTS


; -----------------------------------

BuscaExt:
	LEA	MiTiNom+8(PC),A1
	MOVEQ	#0,D0
MiTiBuc0:
	TST.B	(A0)+
	BEQ.S	MiTiCon0
	ADDQ.W	#1,D0
	BRA.S	MiTiBuc0
MiTiCon0:
	LEA	(A1,D0.W),A1
MiTiBuc1:
	MOVE.B	-(A0),-(A1)
	CMP.B	#".",(A1)
	BEQ.S	MiTiPunto
	CMP.B	#$60,(A1)
	BCS.S	MiTiCon1
	SUB.B	#$20,(A1)
MiTiCon1:
	DBF	D0,MiTiBuc1
	MOVEQ	#-1,D0
	RTS
MiTiPunto:
	MOVE.L	(A1),D1
	MOVEQ	#0,D0
	CMP.L	#".SMS",D1		; Sega Master System
	BEQ.S	MiTiFin
	MOVEQ	#1,D0
	CMP.L	#".SGG",D1		; Sega Game Gear
	AND.L	#$FFFFFF00,D1
	MOVEQ	#0,D0
	CMP.L	#".MS"*256,D1		; Master System
	BEQ.S	MiTiFin
	MOVEQ	#1,D0
	CMP.L	#".GG"*256,D1		; Game Gear
	BEQ.S	MiTiFin
	MOVEQ	#-1,D0
MiTiFin:
	RTS

	CNOP	0,4
MiTiNom:DS.B	8+64
	CNOP	0,4

; -----------------------------------

MiraCartSize:
	MOVE.L	D0,D1
	AND.L	#$0200,D1
	SNE	RawCartSize

;	BFTST	D0{17:15}		; mira mínimo 32Kb
;	BEQ.S	NoOkCartCon
;	SUB.L	#$200,D0
;	ST	RawCartSize
;	BFTST	D0{17:15}		; mira mínimo 32Kb
;	BNE.S	NoOkCartCon
;SiGBCartCon:
	LSR.L	#8,D0
	LSR.L	#5,D0
;	CMP.L	#$40,D0			; mira máximo 4Mb
;	BGT.S	NoOkCartCon
	MOVEQ	#-1,D1
	RTS
NoOkCartCon:
	MOVEQ	#0,D1
	RTS

ReqCancel:
	BSR	EnaMouse
	RTS

	IFNE	MenuAuto
; Test builds: Insert PCE:auto1.pce / auto2.pce in turn through Insert's own
; loading code (no requester) and Power ON; each game is left after MenuAuto
; frames like Esc. PROGDIR:menuauto.txt holds the number of the trip started.
MenuAutoRun:
	TST.B	MenuAutoDone
	BNE.S	.ret
	ST	MenuAutoDone
.trip:
	ADDQ.B	#1,MenuAutoTxt+5
	CMP.B	#'9'+1,MenuAutoTxt+5
	BNE.S	.dig
	MOVE.B	#'0',MenuAutoTxt+5
	ADDQ.B	#1,MenuAutoTxt+4
.dig:	BSR	MenuAutoNote
	LEA	MenuAutoName1(PC),A0
	NOT.B	MenuAutoWhich
	BNE.S	.n1
	LEA	MenuAutoName2(PC),A0
.n1:	LEA	FileNom(PC),A1
.cp:	MOVE.B	(A0)+,(A1)+
	BNE.S	.cp
	BSR	DisMouse
	BSR	InsertLoad
	IFNE	MenuAutoIns		; test builds: stop after the first Insert (the menu as it is then)
	BRA.S	.end
	ENDC
	IFNE	DispAlt			; test builds: Display AGA, RTG, AGA ...
	MOVEQ	#1,D0
	AND.W	MenuAutoTrips,D0
	MOVE.W	#GD_INTER,D1
	BSR	SetCycle
	BSR	DispSel
	ENDC
	BSR	PowerON
	ADDQ.W	#1,MenuAutoTrips
	CMP.W	#MenuAutoMax,MenuAutoTrips
	BCS.S	.trip
.end:	MOVE.L	#"end ",MenuAutoTxt+7
	BSR	MenuAutoNote
.ret:	RTS

MenuAutoNote:
	MOVEM.L	D0-D4/A0-A1/A6,-(SP)
	MOVE.L	_DosBase,A6
	MOVE.L	#MenuAutoFile,D1
	MOVE.L	#1006,D2
	JSR	-30(A6)			; Open
	MOVE.L	D0,D4
	BEQ.S	.no
	MOVE.L	D4,D1
	MOVE.L	#MenuAutoTxt,D2
	MOVEQ	#12,D3
	JSR	-48(A6)			; Write
	MOVE.L	D4,D1
	JSR	-36(A6)			; Close
.no:	MOVEM.L	(SP)+,D0-D4/A0-A1/A6
	RTS
MenuAutoName1:	DC.B	"PCE:auto1.pce",0
MenuAutoName2:	DC.B	"PCE:auto2.pce",0
MenuAutoFile:	DC.B	"PROGDIR:menuauto.txt",0
MenuAutoTxt:	DC.B	"trip00 ok  ",10
MenuAutoTrips:	DC.W	0
MenuAutoCnt:	DC.L	MenuAuto	; frames left in this game (main loop)
MenuAutoDone:	DC.B	0
MenuAutoWhich:	DC.B	0
	CNOP	0,4
	ENDC

ErNoStc:
	BSR	CloseFile
	LEA	tErNoStc,A0
	BRA	ImpError
OpenError:
	LEA	tErOpenFile,A0
	BRA	ImpError
ReadError:
	BSR	CloseFile
	LEA	tErReadFile,A0
	BRA	ImpError
NoNESCart:
	BSR	CloseFile
	LEA	tErNoNESCart,A0
	BRA	ImpError
OutOfMem:
	CLR.L	BucCart
	BSR	CloseFile
	LEA	tErOutOfMem,A0
	BRA	ImpError


	CNOP	0,8
xpkTags0:
	DC.L	$80005851,FileNom	; Nombre del Fichero a abrir.
	DC.L	0

xpkTags1:
	DC.L	$80005851,FileNom	; Nombre del Fichero a abrir.
	DC.L	$80005862,0
	DC.L	$80005871,0
	DC.L	0

;	DC.L	$80005851,Nombre del Fichero a abrir.
;	DC.L	$80005852,FileHandle (retorno del dosOpen) lectura.
;	DC.L	$80005853,Bloque de memoría donde leer.
;	DC.L	$80005860,Nombre del Fichero a crear/reescribir.
;	DC.L	$80005861,FileHandle (retorno del dosOpen) escritura.
;	DC.L	$80005862,Bloque de memoría donde escribir.
;	DC.L	$80005870,Size del bufer donde leer.
;	DC.L	$80005871,Size del bufer donde escribir.
;	DC.L	$80005877,=1 Soportar leer ficheros no xpkeados!

; ------------------------------------------

	CNOP	0,8
TipoROM:
	DC.L	tTipoROM0
	DC.L	tTipoROM1
	DC.L	tTipoROM2
	DC.L	tTipoROM3
	DC.L	tTipoROM4
	DC.L	tTipoROM5
	DC.L	tTipoROM6
	DC.L	tTipoROM7

tTipoROM:	DC.B	"------",0
tTipoROM0:	DC.B	"  16Kb",0
tTipoROM1:	DC.B	"  32Kb",0
tTipoROM2:	DC.B	"  64Kb",0
tTipoROM3:	DC.B	" 128Kb",0
tTipoROM4:	DC.B	" 256Kb",0
tTipoROM5:	DC.B	" 512Kb",0
tTipoROM6:	DC.B	"1024Kb",0
tTipoROM7:	DC.B	"2048Kb",0

tNomCart:	DC.B	"----------------",0
tManufNoID:	DC.B	"---------------",0
	IFEQ	NO_MENU2
tNomFileCart:	DC.B    'No Cartridge Inserted!   ',0,0,0	; 25 = the field
	ELSE
tNomFileCart:	DC.B    'No Cartridge Inserted!           ',0,0,0
	ENDC

	CNOP	0,4

; ------------------------------------------
; ******************************************
; ------------------------------------------






; ------------------------------------------
; ******************************************
; ------------------------------------------


; ------------------------------------------

	CNOP	0,8
	IFNE	NO_MENU2
ImpJoyType:
	MOVE.B	([MainMenuGadgets+(GD_JoyType*4)],$57.w),D0	; JoyType
	AND.W	#$0003,D0
	MOVE.L	(TabGfxJoyType.w,PC,D0.w*4),DirJoyTypePic

	MOVE.L	#552,D0
	MOVE.L	#143,D1
	move.l  Scr,a0
	move.l  40(a0),a1
	ADD.w  4(a1),D1
	MOVE.L	MainMenuWnd,A0
	MOVE.L	50(A0),A0
	LEA	DatsJoyTypePic,A1
	MOVE.L	_IntuitionBase,A6
	TallImgJmp
	CNOP	0,4
TabGfxJoyType:
	DC.L	GBJoyStick
	DC.L	GBTeclado
	DC.L	GBCD32
	DC.L	GBJoypad
	ELSE
; ImpJoyType: the pictures of both ports' pad types (and again when one is changed).
ImpJoyType:
	LEA	MainMenuPunts,A0
	MOVE.W	#GD_JoyPort,D1		; port 1
	MOVEQ	#0,D0
	BSR	GetGadgetValue
	MOVE.L	#252,D2
	BSR.S	.one
	LEA	MainMenuPunts,A0
	MOVE.W	#GD_JoyType,D1		; port 2
	MOVEQ	#1,D0
	BSR	GetGadgetValue
	MOVE.L	#534,D2
.one:	AND.W	#$0003,D0
	MOVE.L	(TabGfxPort.w,PC,D0.w*4),DirJoyTypePic
	MOVE.L	D2,D0
	MOVE.L	#143,D1
	move.l  Scr,a0
	move.l  40(a0),a1
	ADD.w  4(a1),D1
	MOVE.L	MainMenuWnd,A0
	MOVE.L	50(A0),A0
	LEA	DatsJoyTypePic,A1
	MOVE.L	_IntuitionBase,A6
	TallImgJmp
	CNOP	0,4
TabGfxPort:				; the menu's order: none (the keyboard), joystick, CD32 pad, joypad
	DC.L	GBTeclado
	DC.L	GBJoyStick
	DC.L	GBCD32
	DC.L	GBJoypad
	ENDC

; ------------------------------------------
; ******************************************
; ------------------------------------------

; -----------------------------------
; -----------------------------------

; -----------------------------------

	CNOP	0,4
	IFNE	NO_MENU2
ActuPrefs:
	LEA	DirPrefs(PC),A5

	LEA	MainMenuPunts,A0

	MOVE.W	#GD_JoyType,D1
	MOVEQ	#0,D0
	BSR	GetGadgetValue
	MOVE.B	D0,$08(A5)	; JoyType

	MOVE.W	#GD_ScrMode,D1
	MOVEQ	#0,D0
	BSR	GetGadgetValue
	MOVE.B	D0,$0F(A5)	; Screen



	MOVE.L	InsReqBase(PC),A0
	MOVE.L	8(A0),A0
	LEA	$20(A5),A1
	MOVE.W	#($100/8)-1,D0
ActPreBuc0:
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	DBF	D0,ActPreBuc0

	MOVEQ	#2,D1		; Nº menu.
	MOVEQ	#0,D0		; Nº Línea.
	BSR	CogeCheck
	SNE	$09(A5)				; Black Border

	RTS

; -----------------------------------

CogeCheck:
	MOVE.L	MainMenuMenus,A0
	MOVE.L	_IntuitionBase(PC),A6
	LSL.W	#5,D0	
	OR.W	D1,D0
	JSR	-$90(A6)		; ItemAdress (A0,d0)
	MOVE.L	D0,A0
	BTST	#0,$C(A0)
	RTS

; -----------------------------------

PonPrefs:
	LEA	DirPrefs(PC),A5

	LEA	MainMenuPunts,A0
	LEA	MainMenuGTags,A1
	MOVE.W	#GD_JoyType,D0
	MOVE.L	#$8008000F,D1
	MOVEQ	#0,D2
	MOVE.B	$08(A5),D2
	BSR	OverrideTag

;	LEA	MainMenuPunts,A0
;	LEA	MainMenuGTags,A1
;	MOVE.W	#GD_LCDFade,D0
;	MOVE.L	#$8008000F,D1
;	MOVEQ	#0,D2
;	MOVE.B	$11(A5),D2
;	BSR	OverrideTag

	LEA	MainMenuPunts,A0
	LEA	MainMenuGTags,A1
	MOVE.W	#GD_ScrMode,D0
	MOVE.L	#$8008000F,D1
	MOVEQ	#0,D2
	MOVE.B	$0F(A5),D2
	BSR	OverrideTag

	MOVE.B	$09(A5),D0
	BFINS	D0,MainMenuNewMenu26+10{7:1}	; Black Border.
	IFEQ	ScanOff
	JSR	RtgScanMenu		; ToolType SCANLINES= over the prefs; menu ticks, ghosted without RTG
	ENDC

	RTS

	ELSE
; ActuPrefs: the gadgets into the prefs (Power ON, Continue, Save Prefs).
ActuPrefs:
	LEA	DirPrefs(PC),A5
	LEA	MainMenuPunts,A0
	MOVE.W	#GD_JoyType,D1		; port 2 (prefs $08 in Juan's order: 0 joystick, 1 none)
	MOVEQ	#1,D0
	BSR	GetGadgetValue
	BSR	PortSwap
	MOVE.B	D0,$08(A5)
	MOVE.W	#GD_JoyPort,D1		; port 1 (prefs $16 in the menu's order: 0 none, 1 joystick)
	MOVEQ	#0,D0
	BSR	GetGadgetValue
	MOVE.B	D0,$16(A5)
	MOVE.W	#GD_ScrMode,D1
	MOVEQ	#0,D0
	BSR	GetGadgetValue
	IFNE	AGC
	TST.B	AgcWant			; the colour program: Screen and Display are fixed, the saved ones stay
	BNE.S	.agc
	ENDC
	MOVE.B	D0,$0F(A5)		; Screen
	IFEQ	DispOff
	IFEQ	AGC
	MOVE.B	RtgWant,$17(A5)		; Display (0 AGA, else RTG)
	ENDC
	ENDC
.agc:
	MOVE.L	InsReqBase(PC),D0	; the requester's drawer
	BEQ.S	.nd
	MOVE.L	D0,A0
	MOVE.L	8(A0),A0
	LEA	$20(A5),A1
	MOVE.W	#($100/8)-1,D0
.c:	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	DBF	D0,.c
.nd:	RTS

; PortSwap: D0 = a pad type, the menu's order <-> prefs $08's (0 and 1 swapped).
PortSwap:
	CMP.B	#2,D0
	BHS.S	.x
	EOR.B	#1,D0
.x:	RTS

; PonPrefs: the prefs into the gadgets' tags (the window is not open yet).
PonPrefs:
	LEA	DirPrefs(PC),A5
	IFEQ	ScanOff
	JSR	RtgScanMenu		; ToolType / CLI SCANLINES= over the prefs
	ENDC
	MOVEQ	#0,D0
	MOVE.B	$08(A5),D0		; port 2
	AND.W	#3,D0
	BSR	PortSwap
	MOVE.L	D0,D2
	MOVE.W	#GD_JoyType,D0
	BSR	PonCycle
	MOVEQ	#0,D2
	MOVE.B	$16(A5),D2		; port 1
	AND.W	#3,D2
	MOVE.W	#GD_JoyPort,D0
	BSR	PonCycle
	MOVEQ	#0,D2
	MOVE.B	$0F(A5),D2		; Screen
	AND.W	#1,D2
	IFNE	AGC
	TST.B	AgcWant			; AGA colour mode: ghosted, NTSC (with the debug rows PAL: ContinueCon)
	BEQ.S	.scr
	MOVEQ	#1,D2
	MOVE.W	#GD_ScrMode,D0
	MOVE.L	#$8003000E,D1		; GA_Disabled
	BSR	PonTag
	MOVEQ	#1-DbgRows,D2
.scr:
	ENDC
	MOVE.W	#GD_ScrMode,D0
	BSR	PonCycle
	IFEQ	DispOff
	MOVEQ	#0,D2
	TST.B	RtgWant			; Display: RtgStart decided (prefs, ToolType / CLI word RTG, P96 there)
	BEQ.S	.d
	MOVEQ	#1,D2
.d:	MOVE.W	#GD_INTER,D0
	BSR	PonCycle
	MOVEQ	#0,D2
	TST.B	RtgAvail
	SEQ	D2			; ghosted without P96
	IFNE	AGC
	ST	D2			; the colour program: AGA colour or RTG as started (RTG word), ghosted
	ENDC
	MOVE.W	#GD_INTER,D0
	MOVE.L	#$8003000E,D1
	BSR	PonTag
	IFEQ	ScanOff
	MOVEQ	#0,D2
	MOVE.B	$15(A5),D2		; Scanlines
	AND.W	#7,D2
	LEA	ScanMap(PC),A0
	MOVE.B	(A0,D2.W),D2
	MOVE.W	#GD_Refresh,D0
	BSR	PonCycle
	MOVEQ	#0,D2
	TST.B	RtgWant
	SEQ	D2			; ghosted on AGA
	MOVE.W	#GD_Refresh,D0
	MOVE.L	#$8003000E,D1
	BSR	PonTag
	ENDC
	ENDC
	RTS
PonCycle:
	MOVE.L	#$8008000F,D1		; GTCY_Active
PonTag:
	LEA	MainMenuPunts,A0
	LEA	MainMenuGTags,A1
	BRA	OverrideTag

ScanMap:				; Scanlines gadget position <-> prefs $15 (the same both ways)
	IFEQ	NO_BLENDLV
	DC.B	0,1,2,3,5,4,6,0
	ELSE
	DC.B	0,1,2,3,4,0,0,0
	ENDC

; SetCycle: D1 = gadget, D0 = its setting (MainMenuValues and the gadget on screen).
	CNOP	0,4
SetCycle:
	MOVEM.L	D0-D1/A2-A3/A6,-(SP)
	LEA	MainMenuPunts,A0
	BSR	SetGadgetValue
	MOVEM.L	(SP),D0-D1
	MOVE.L	D0,.tg+4
	LEA	MainMenuGadgets,A0
	MOVE.L	(A0,D1.W*4),A0
	MOVE.L	MainMenuWnd,A1
	IFEQ	ChoosOff
	BSR	ChooserIs
	BNE.S	.gt
	MOVE.L	#$85001005,D1		; CHOOSER_Selected
	BSR	ChooserSet
	BRA.S	.cs
.gt:
	ENDC
	SUB.L	A2,A2
	LEA	.tg(PC),A3
	MOVE.L	_GadToolsBase(PC),A6
	JSR	-$2A(A6)		; GT_SetGadgetAttrsA
.cs:	MOVEM.L	(SP)+,D0-D1/A2-A3/A6
	RTS
	CNOP	0,4
.tg:	DC.L	$8008000F,0,0,0

	IFEQ	DispOff
; DispSel: the Display gadget (AGA / RTG for the next Power ON).
DispSel:
	LEA	MainMenuPunts,A0
	MOVE.W	#GD_INTER,D1
	MOVEQ	#0,D0
	BSR	GetGadgetValue
	IFEQ	ChoosOff
	MOVEQ	#0,D1
	TST.B	RtgWant
	BEQ.S	.w
	MOVEQ	#1,D1
.w:	CMP.W	D1,D0
	BEQ.S	.same			; the same setting picked again: Continue stays
	ENDC
	JSR	RtgSelect		; D0 = what is in effect
	BSR.S	DispShow
	LEA	MainMenuGadgets+(GD_Continue*4),A0	; a game started on the other display: Power ON again
	MOVE.L	MainMenuWnd,A1
	MOVEQ	#1,D0
	BRA	GadsOnOff
	IFEQ	ChoosOff
.same:	RTS
	ENDC
; DispSync: the gadget after RTG was turned off (the RTG play screen did not open).
DispSync:
	MOVEQ	#0,D0
	TST.B	RtgWant
	BEQ.S	DispShow
	MOVEQ	#1,D0
; DispShow: D0 = 0 AGA / 1 RTG on the Display gadget; Scanlines only with RTG.
DispShow:
	MOVE.L	D0,-(SP)
	MOVE.W	#GD_INTER,D1
	BSR	SetCycle
	IFEQ	ScanOff
	MOVE.L	(SP),D0
	SEQ	D0
	AND.L	#1,D0			; 1 = ghosted
	LEA	MainMenuGadgets+(GD_Refresh*4),A0
	MOVE.L	MainMenuWnd,A1
	BSR	GadsOnOff
	ENDC
	ADDQ.L	#4,SP
	RTS
	ENDC

	IFEQ	ScanOff
; ScanSel: the Scanlines gadget (the next Power ON / Continue on RTG).
ScanSel:
	LEA	MainMenuPunts,A0
	MOVE.W	#GD_Refresh,D1
	MOVEQ	#0,D0
	BSR	GetGadgetValue
	AND.W	#7,D0
	LEA	ScanMap(PC),A0
	MOVE.B	(A0,D0.W),DirPrefs+$15
	RTS
	ENDC
	ENDC

	IFEQ	ChoosOff
; The menu's settings as chooser.gadget pop-up lists (OS 3.5 and up). When the window is made
; (GadToolsBox.asm) a cycle gadget's box, labels, setting and ghosting go to a chooser instead
; (ChooserPre), and the GadTools gadget left behind is a text gadget one pixel wide that only
; draws the label. MainMenuGadgets holds the chooser, so the handlers stay as they were.
; Without chooser.gadget everything is as before.

; ChooserPre: D0 = the gadget's kind, D3 = its number, A4 = its tags, BufNewGad = its box.
; Returns D0 = the kind to make with GadTools (TEXT_KIND when a chooser was made).
ChooserPre:
	IFD	ChooDbg
	ADDQ.L	#1,ChooDbgV+4
	MOVE.L	_ChooserBase,ChooDbgV
	ENDC
	CMP.W	#7,D0			; CYCLE_KIND
	BNE	.r
	IFD	ChooDbg
	ADDQ.L	#1,ChooDbgV+8
	ENDC
	TST.L	_ChooserBase
	BEQ	.r
	MOVEM.L	D1-D4/A0-A2/A6,-(SP)
	MOVEQ	#0,D2			; setting
	MOVEQ	#0,D4			; ghosted
	SUB.L	A2,A2			; labels
	MOVE.L	A4,A0
.t:	MOVE.L	(A0)+,D1
	BEQ.S	.td
	MOVE.L	(A0)+,D0
	CMP.L	#$8008000F,D1		; GTCY_Active
	BNE.S	.t1
	MOVE.L	D0,D2
	BRA.S	.t
.t1:	CMP.L	#$8003000E,D1		; GA_Disabled
	BNE.S	.t2
	MOVE.L	D0,D4
	BRA.S	.t
.t2:	CMP.L	#$8008000E,D1		; GTCY_Labels
	BNE.S	.t
	MOVE.L	D0,A2
	BRA.S	.t
.td:	MOVE.L	A2,D0
	BEQ	.no
	LEA	ChooserLists,A0		; this gadget's list of chooser nodes
	MOVE.L	D3,D1
	MULU	#12,D1
	ADD.L	D1,A0
	LEA	4(A0),A1		; NewList
	MOVE.L	A1,(A0)
	CLR.L	4(A0)
	MOVE.L	A0,8(A0)
	MOVE.L	A0,ChoTags+44
	MOVE.L	A0,-(SP)
.n:	MOVE.L	(A2)+,D0
	BEQ.S	.nd
	MOVE.L	D0,CnaTags+4
	LEA	CnaTags(PC),A0
	MOVE.L	_ChooserBase,A6
	JSR	-36(A6)			; AllocChooserNodeA
	TST.L	D0
	BEQ.S	.nd
	MOVE.L	(SP),A0
	MOVE.L	D0,A1
	MOVE.L	4.W,A6
	JSR	-246(A6)		; AddTail
	BRA.S	.n
.nd:	ADDQ.L	#4,SP
	LEA	BufNewGad,A1
	MOVE.W	(A1),D0
	EXT.L	D0
	MOVE.L	D0,ChoTags+4		; GA_Left
	MOVE.W	2(A1),D0
	EXT.L	D0
	MOVE.L	D0,ChoTags+12		; GA_Top
	MOVE.W	4(A1),D0
	EXT.L	D0
	MOVE.L	D0,ChoTags+20		; GA_Width
	MOVE.W	6(A1),D0
	EXT.L	D0
	MOVE.L	D0,ChoTags+28		; GA_Height
	MOVEQ	#0,D0
	MOVE.W	16(A1),D0
	MOVE.L	D0,ChoTags+36		; GA_ID
	MOVE.L	D2,ChoTags+52		; CHOOSER_Selected
	MOVE.L	D4,ChoTags+60		; GA_Disabled
	MOVE.L	_ChooserBase,A6
	JSR	-30(A6)			; CHOOSER_GetClass
	MOVE.L	D0,A0
	SUB.L	A1,A1
	LEA	ChoTags(PC),A2
	MOVE.L	_IntuitionBase,A6
	JSR	-636(A6)		; NewObjectA
	IFD	ChooDbg
	MOVE.L	D0,ChooDbgV+12
	ENDC
	LEA	ChooserObjs,A0
	MOVE.L	D0,(A0,D3.W*4)
	BEQ.S	.no			; no chooser: the cycle gadget
	MOVE.W	#1,BufNewGad+4		; the GadTools gadget: the label only
	MOVEM.L	(SP)+,D1-D4/A0-A2/A6
	MOVEQ	#13,D0			; TEXT_KIND
	RTS
.no:	MOVEM.L	(SP)+,D1-D4/A0-A2/A6
	MOVEQ	#7,D0
.r:	RTS

; ChooserPost: A0 = MainMenuGadgets' entry for gadget D3: the chooser when there is one.
ChooserPost:
	MOVE.L	A1,-(SP)
	LEA	ChooserObjs,A1
	MOVE.L	(A1,D3.W*4),D0
	BEQ.S	.x
	MOVE.L	D0,(A0)
.x:	MOVE.L	(SP)+,A1
	RTS

; ChooserAdd: the choosers into the open window (MainMenuWnd), drawn.
ChooserAdd:
	MOVEM.L	D0-D2/A0-A2/A6,-(SP)
	IFD	ChooDbg
	MOVEM.L	D0-D4/A0-A1/A6,-(SP)
	MOVE.L	_DosBase,A6
	MOVE.L	#.dn,D1
	MOVE.L	#1006,D2
	JSR	-30(A6)
	MOVE.L	D0,D4
	BEQ.S	.dx
	MOVE.L	D4,D1
	MOVE.L	#ChooDbgV,D2
	MOVEQ	#16,D3
	JSR	-48(A6)
	MOVE.L	D4,D1
	JSR	-36(A6)
.dx:	MOVEM.L	(SP)+,D0-D4/A0-A1/A6
	BRA.S	.dgo
.dn:	DC.B	"PROGDIR:chooser.bin",0
	EVEN
.dgo:
	ENDC
	MOVE.L	_IntuitionBase,A6
	MOVEQ	#MainMenu_CNT-1,D2
	LEA	ChooserObjs,A2
.l:	MOVE.L	(A2)+,D0
	BEQ.S	.n
	MOVE.L	MainMenuWnd,A0
	MOVE.L	D0,A1
	MOVEQ	#-1,D0
	JSR	-42(A6)			; AddGadget
	MOVE.L	-4(A2),A0
	MOVE.L	MainMenuWnd,A1
	MOVE.L	A2,-(SP)
	SUB.L	A2,A2
	MOVEQ	#1,D0
	JSR	-432(A6)		; RefreshGList
	MOVE.L	(SP)+,A2
.n:	DBF	D2,.l
	MOVEM.L	(SP)+,D0-D2/A0-A2/A6
	RTS

; ChooserRem: the choosers out of the window before it closes.
ChooserRem:
	MOVEM.L	D0-D2/A0-A2/A6,-(SP)
	MOVE.L	_IntuitionBase,A6
	MOVEQ	#MainMenu_CNT-1,D2
	LEA	ChooserObjs,A2
.l:	MOVE.L	(A2)+,D0
	BEQ.S	.n
	MOVE.L	MainMenuWnd,A0
	MOVE.L	D0,A1
	JSR	-228(A6)		; RemoveGadget
.n:	DBF	D2,.l
	MOVEM.L	(SP)+,D0-D2/A0-A2/A6
	RTS

; ChooserFree: the choosers and their lists (after the window and the GadTools gadgets).
ChooserFree:
	MOVEM.L	D0-D2/A0-A2/A6,-(SP)
	MOVEQ	#MainMenu_CNT-1,D2
	LEA	ChooserObjs,A2
.l:	MOVE.L	(A2),D0
	BEQ.S	.n
	CLR.L	(A2)
	MOVE.L	D0,A0
	MOVE.L	_IntuitionBase,A6
	JSR	-642(A6)		; DisposeObject
.n:	ADDQ.L	#4,A2
	DBF	D2,.l
	MOVEQ	#MainMenu_CNT-1,D2
	LEA	ChooserLists,A2
.ll:	TST.L	(A2)			; never made: nothing in it
	BEQ.S	.ln
.f:	MOVE.L	A2,A0
	MOVE.L	4.W,A6
	JSR	-258(A6)		; RemHead
	TST.L	D0
	BEQ.S	.ln
	MOVE.L	D0,A0
	MOVE.L	_ChooserBase,A6
	JSR	-42(A6)			; FreeChooserNode
	BRA.S	.f
.ln:	LEA	12(A2),A2
	DBF	D2,.ll
	MOVEM.L	(SP)+,D0-D2/A0-A2/A6
	RTS

; ChooserIs: A0 = a gadget. Z set when it is one of the choosers.
ChooserIs:
	MOVEM.L	D0/A1,-(SP)
	LEA	ChooserObjs,A1
	MOVEQ	#MainMenu_CNT-1,D0
.l:	CMPA.L	(A1)+,A0
	DBEQ	D0,.l
	MOVEM.L	(SP)+,D0/A1		; (the flags stay)
	RTS

; ChooserSet: A0 = a chooser, A1 = its window, D1 = a tag, D0 = its data. Set and drawn.
ChooserSet:
	MOVEM.L	D0-D1/A0-A3/A6,-(SP)
	LEA	.tg(PC),A3
	MOVE.L	D1,(A3)
	MOVE.L	D0,4(A3)
	SUB.L	A2,A2
	MOVE.L	_IntuitionBase,A6
	JSR	-660(A6)		; SetGadgetAttrsA
	MOVEM.L	8(SP),A0-A1
	SUB.L	A2,A2
	MOVEQ	#1,D0
	JSR	-432(A6)		; RefreshGList
	MOVEM.L	(SP)+,D0-D1/A0-A3/A6
	RTS
	CNOP	0,4
.tg:	DC.L	0,0,0

; ChooserCode: IDCMP_GADGETUP, D1 = the gadget, D3 = its number in the window: when it is a
; chooser, D2 = its setting (CHOOSER_Selected).
ChooserCode:
	CMP.W	#MainMenu_CNT,D3
	BCC.S	.r
	MOVEM.L	D0-D1/A0-A1/A6,-(SP)
	LEA	ChooserObjs,A0
	MOVE.L	(A0,D3.W*4),D0
	BEQ.S	.x
	CMP.L	D1,D0
	BNE.S	.x
	MOVE.L	D0,A0
	LEA	.v(PC),A1
	MOVE.L	#$85001005,D0		; CHOOSER_Selected
	MOVE.L	_IntuitionBase,A6
	JSR	-654(A6)		; GetAttr
	MOVE.L	.v(PC),D2
.x:	MOVEM.L	(SP)+,D0-D1/A0-A1/A6
.r:	RTS
	CNOP	0,4
.v:	DC.L	0

	CNOP	0,4
ChoTags:
	DC.L	$80030001,0		; GA_Left
	DC.L	$80030003,0		; GA_Top
	DC.L	$80030005,0		; GA_Width
	DC.L	$80030007,0		; GA_Height
	DC.L	$80030010,0		; GA_ID
	DC.L	$85001004,0		; CHOOSER_Labels
	DC.L	$85001005,0		; CHOOSER_Selected
	DC.L	$8003000E,0		; GA_Disabled
	DC.L	$80030016,1		; GA_RelVerify
	DC.L	$80030028,topaz8	; GA_TextAttr
	DC.L	$85001001,1		; CHOOSER_PopUp
	DC.L	$8500100D,1		; CHOOSER_Justification: centred (as the cycle gadgets)
	DC.L	0
CnaTags:
	DC.L	$85001501,0,0		; CNA_Text
ChooserObjs:	DCB.L	MainMenu_CNT,0
	IFD	ChooDbg
ChooDbgV:	DC.L	0,0,0,0
	ENDC
ChooserLists:	DCB.B	MainMenu_CNT*12,0
	ENDC

; -----------------------------------

LoadPrefs:
	MOVE.L	#NOMPREFS,D1
	MOVE.L	#1005,D2
	BSR	OpenFile
	BEQ.S	PREFSRET

	MOVE.L	#BufPrefs,D2
	MOVE.L	#BucPrefs,D3
	BSR	ReadFile
	BNE	CloseFile

	BSR	CloseFile
	LEA	BufPrefs,A0
	CMP.L	#"AmiN",(A0)
	BNE.S	PREFSRET
	CMP.L	#"Fv01",4(A0)		; Versión
	BEQ.S	PREFSOK
PREFSRET:
	RTS

	CNOP	0,4
PREFSOK:
	MOVE.L	#"Fv01",4(A0)		; Versión
	LEA	DirPrefs,A1
	MOVE.W	#BucPrefs-1,D0
COPIPREFS:
	MOVE.B	(A0)+,(A1)+
	DBF	D0,COPIPREFS
	RTS


; ------------------------------------------

	IFEQ	NO_BRAMSAVE
; Backup RAM, one 8 KB file per game: PROGDIR:Saves/<ROM name>.bup. Read before Power ON, written
; when a game returns to the menu and has changed it (the OS is frozen during play). A game that
; never changes it gets no file. Embedded test builds have no FileNom, so no saves.
	CNOP	0,4
BramLoad:
	SF	BramGot
	BSR	BramMkName
	TST.B	BramName
	BEQ.S	.ret
	MOVE.L	#BramName,D1
	MOVE.L	#1005,D2
	BSR	OpenFile
	BEQ.S	.ret
	MOVE.L	#BramDisk,D2
	MOVE.L	#8*1024,D3
	BSR	ReadFile
	SEQ	BramGot			; a short file counts as no save
	BSR	CloseFile
.ret:	RTS

	CNOP	0,4
BramSave:
	IFEQ	NO_MENU2
	SF	BramWrote
	ENDC
	TST.B	BramName
	BEQ.S	.ret
	LEA	SRAM,A0
	LEA	BramDisk,A1
	MOVE.W	#((8*1024)/4)-1,D0
.cmp:	CMPM.L	(A0)+,(A1)+
	DBNE	D0,.cmp
	BEQ.S	.ret
	MOVE.L	#BramDir,D1
	MOVE.L	_DosBase,A6
	JSR	-$78(A6)		; CreateDir (fails if it's there, that's fine)
	MOVE.L	D0,D1
	BEQ.S	.noDir
	JSR	-$5A(A6)		; UnLock
.noDir:	MOVE.L	#BramName,D1
	MOVE.L	#1006,D2
	BSR	OpenFile
	BEQ.S	.err
	MOVE.L	#SRAM,D2
	MOVE.L	#8*1024,D3
	BSR	WriteFile
	BNE.S	.err
	BSR	CloseFile
	IFEQ	NO_MENU2
	ST	BramWrote
	ENDC
	LEA	SRAM,A0
	LEA	BramDisk,A1
	MOVE.W	#((8*1024)/4)-1,D0
.copy:	MOVE.L	(A0)+,(A1)+
	DBF	D0,.copy
.ret:	RTS
.err:	BSR	CloseFile
	LEA	tErSaveBram(PC),A0
	BRA	ImpError

; BramName from FileNom without its path and extension. A name over BramMax (FFS allows 30 with
; ".bup") keeps its first 21 characters and gets a 4-digit hash, so similar long names stay apart.
BramMax=26
	CNOP	0,4
BramMkName:
	CLR.B	BramName
	LEA	FileNom(PC),A0
	MOVE.L	A0,A1			; A1 base name
	SUB.L	A2,A2			; A2 its last dot
.scan:	MOVE.B	(A0)+,D0
	BEQ.S	.end
	CMP.B	#"/",D0
	BEQ.S	.sep
	CMP.B	#":",D0
	BEQ.S	.sep
	CMP.B	#".",D0
	BNE.S	.scan
	LEA	-1(A0),A2
	BRA.S	.scan
.sep:	MOVE.L	A0,A1
	SUB.L	A2,A2
	BRA.S	.scan
.end:	SUBQ.L	#1,A0
	MOVE.L	A2,D0
	BEQ.S	.noExt
	MOVE.L	A2,A0
.noExt:	MOVE.L	A0,D1
	SUB.L	A1,D1			; D1 length
	BEQ.S	.ret
	LEA	BramName,A2
	LEA	BramDir(PC),A0
.dir:	MOVE.B	(A0)+,(A2)+
	BNE.S	.dir
	MOVE.B	#"/",-1(A2)
	CMP.L	#BramMax,D1
	BHI.S	.long
	SUBQ.W	#1,D1
.short:	MOVE.B	(A1)+,(A2)+
	DBF	D1,.short
	BRA.S	.ext
.long:	MOVEQ	#0,D2
	MOVE.L	A1,A0
	SUBQ.W	#1,D1
.hash:	MULU	#31,D2
	MOVEQ	#0,D0
	MOVE.B	(A0)+,D0
	ADD.W	D0,D2
	DBF	D1,.hash
	MOVEQ	#21-1,D1
.head:	MOVE.B	(A1)+,(A2)+
	DBF	D1,.head
	MOVE.B	#"_",(A2)+
	MOVEQ	#4-1,D1
.hex:	ROL.W	#4,D2
	MOVE.W	D2,D0
	AND.W	#15,D0
	MOVE.B	.digits(PC,D0.W),(A2)+
	DBF	D1,.hex
.ext:	MOVE.L	#".bup",(A2)+
	CLR.B	(A2)
.ret:	RTS
.digits:	DC.B	"0123456789abcdef"

	IFEQ	NO_MENU2
; The Backup RAM text in the menu: BramFind after Insert, BramAfter back from play, the ROM
; size, this text and the file name printed again (MainMenuText9's chain).
BramFind:
	BSR	BramMkName
	LEA	tBramNone(PC),A0
	TST.B	BramName
	BEQ.S	.set
	MOVE.L	#BramName,D1
	MOVEQ	#-2,D2			; ACCESS_READ
	MOVE.L	_DosBase,A6
	JSR	-84(A6)			; Lock (A0 is not kept: the text is picked after it)
	MOVE.L	D0,D1
	BEQ.S	.none
	JSR	-90(A6)			; UnLock
	LEA	tBramFound(PC),A0
	BRA.S	.set
.none:	LEA	tBramNone(PC),A0
.set:	MOVE.L	A0,MainMenuText11+$C
	RTS
BramAfter:
	LEA	tBramSaved(PC),A0
	TST.B	BramWrote
	BNE.S	.set
	LEA	tBramLoaded(PC),A0
	TST.B	BramGot
	BNE.S	.set
	LEA	tBramNone(PC),A0
.set:	MOVE.L	A0,MainMenuText11+$C
PrintCartTexts:
	move.l  _IntuitionBase,a6
	move.l  MainMenuWnd,a0
	move.b  54(a0),d0
	ext.w   d0
	move.b  55(a0),d1
	ext.w   d1
	move.l  50(a0),a0
	lea	MainMenuText9,a1
	TallITextM
	RTS
tBramDash:	DC.B	"-                        ",0
tBramNone:	DC.B	"No save file yet         ",0
tBramFound:	DC.B	"Save file found          ",0
tBramLoaded:	DC.B	"Save file loaded         ",0
tBramSaved:	DC.B	"Game saved (Saves drawer)",0
BramWrote:	DC.B	0
	EVEN
	ENDC
BramDir:	DC.B	"PROGDIR:Saves",0
BramGot:	DC.B	0
	EVEN
BramName:	DS.B	50
	CNOP	0,4
	ENDC

SavePrefs:
	BSR	ActuPrefs

	MOVE.L	#NOMPREFS,D1
	MOVE.L	#1006,D2
	BSR	OpenFile
	BEQ.S	ERDEVICE2

	MOVE.L	#DirPrefs,D2
	MOVE.L	#BucPrefs,D3
	BSR	WriteFile
	BNE.S	ERDEVICE2

	BSR	CloseFile
	RTS

	CNOP	0,4
ERDEVICE2:
	BSR	CloseFile
	LEA	tErSavePrefs(PC),A0
	BRA	ImpError
	RTS

	CNOP	0,8
NOMPREFS:
	DC.B	"S:AmiPC-Engine.prefs",0,0,0,0

; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
	CNOP	0,8
DirPrefs:
	DC.B	"AmiNFv01"	; $00 - ID
	IFEQ	NO_MENU2
	DC.B	$00		; $08 - port 2's pad (0 joystick, 1 none, 2 CD32 pad, 3 joypad)
	ELSE
	DC.B	$01		; $08 - JoyType
	ENDC
	DC.B	$FF		; $09 - Black Border
	DC.B	$00		; $0A - Ask for Reset
	DC.B	$00		; $0B - Auto-load Battery
	DC.B	$00		; $0C - Auto-save Battery
	DC.B	$00		; $0D - Overwrite
	DC.B	$00		; $0E - Use UnPack.library
	IFEQ	NO_PALDEF
	DC.B	$01		; $0F - Screen mode (1 = NTSC 60 Hz)
	ELSE
	DC.B	$00		; $0F - Screen mode
	ENDC
	DC.B	$00		; $10 - Inter
	DC.B	$00		; $11 - Refresh
	DC.W	$00		; $12 - Emulation Speed
	DC.B	$00		; $14 - No illogical moves
	IFEQ	ScanOff
	DC.B	SCANDEF		; $15 - RTG scanlines: 0 Off, 1/2/3 = 25/50/75%, 4 Blended, 5 Blended light, 6 Blended strong
	ELSE
	DC.B	$00		; $15 -
	ENDC
	DC.B	$00		; $16 - port 1's pad (NO_MENU2=0: 0 none, 1 joystick, 2 CD32 pad, 3 joypad)

	DC.B	$00		; $17 - Display (NO_MENU2=0: 0 AGA, else RTG)
	DC.L	$00		; $18
	DC.L	$00		; $1C

	IFEQ	NO_HOMEDIR
	DC.B	"PROGDIR:Homebrew"	; $20 - the ROM drawer that comes with the emulator
	DS.B	$100-16
	ELSE
	DC.B	"Cartridges"	; $20
	DS.B	$100-10
	ENDC

;;;	DC.B	$00		; $120

	CNOP	0,4
	DC.B	" -> AmiPC-Engine preferences file <- ",0
	CNOP	0,4
FinPrefs:
BucPrefs=FinPrefs-DirPrefs
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
	DS.L	6
	CNOP	0,8
BufPrefs:
	DS.B	BucPrefs
	DS.L	6
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-


; ------------------------------------------
; ******************************************
; ------------------------------------------



; ------------------------------------------
; ******************************************
; ------------------------------------------


; ------------------------------------------
; ******************************************
; ------------------------------------------
; ------------------------------------------
; ------------------------------------------
; ------------------------------------------


; -----------------------------------
; -----------------------------------
	CNOP	0,4
SETPAL:
	MOVE.W	#$20,$DFF1DC
	RTS
; -----------------------------------
	CNOP	0,4
SETNTSC:
	MOVE.W	#0,$DFF1DC
	RTS
; -----------------------------------
	CNOP	0,4
MC68020:
	MOVE.L	$4.w,A0
	MOVE.B	$129(A0),D0
	SMI	EsUn060

	AND.B	#$8E,D0
	BNE.S	MC68020RET

NoAGA2:
	MOVEM.L	MCeros(PC),D0-D7/A0-A6
	JSR	OpenMC68020Window
	LEA	MC68020PUNTS,A1
	BSR	Control
	JSR	CloseMC68020Window
MC68020RET:
	MOVEQ	#-1,D0
	RTS
MC68020SALIR:
	ADD.W	#16+4,SP
	JSR	CloseMC68020Window
	MOVEQ	#0,D0
	RTS

; -----------------------------------
	CNOP	0,4
MiraAGA:
	LEA	$DFF000,A6
	MOVE.W	$7C(A6),D1
	MOVE.W	#30-1,D3
BucAGA2:
	MOVE.W	$7C(A6),D2
	CMP.B	D2,D1
	BNE	NoAGA2
	DBF	D3,BucAGA2
	ORI.B	#$F0,D1
	CMPI.B	#$F8,D1
	BNE	NoAGA2
	MOVEQ	#-1,D0
	RTS

; ------------------------------------------
; ******************************************
; ------------------------------------------

;	--------------------------
;	Refresca el Relog interno.
;	--------------------------

	CNOP	0,8
RefrescaReloj:
	LEA	battclockreso(PC),A1
	MOVE.L	$4.w,A6
	JSR	-$1F2(A6)		; Open Resource.
	MOVE.L	D0,A2
	MOVE.L	A2,D0
	BEQ.S	RefRelFin

	LEA	TimeBuffer(PC),A1
	LEA	timerdevice(PC),A0
	MOVEQ	#0,D0
	MOVE.L	D0,D1
	JSR	-$1BC(A6)		; Open Device.
	MOVE.L	D0,D6
	BNE.S	RefRelFin


	MOVEQ	#0,D7
	MOVEQ	#0,D0
	LEA	TimeBuffer(PC),A0
	MOVE.W	D0,$8(A0)
	SUB.L	A1,A1
	MOVE.L	A1,$A(A0)
	MOVE.L	A1,$E(A0)
	CLR.L	$24(A0)

	MOVE.L	A2,A6
	JSR	-$C(A6)
	LEA	TimeBuffer(PC),A0
	MOVE.L	D0,$20(A0)
	MOVE.W	#$B,$1C(A0)
	MOVE.L	A0,A1
	MOVE.L	$4.w,A6
	JSR	-$1C8(A6)		; DoIO.

	LEA	TimeBuffer(PC),A1
;	MOVE.L	$4.w,A6
	JSR	-$1C2(A6)		; Close Device.
RefRelFin:
	RTS

	CNOP	0,8
battclockreso:	DC.B	'battclock.resource',0,0
timerdevice:	DC.B	'timer.device',0,0

	CNOP	0,8
TimeBuffer:	DS.B	$30
	CNOP	0,4

; ------------------------------------------
; ******************************************
; ------------------------------------------

LongFile:
	MOVE.L	#FileNom,D1
	MOVEQ	#-2,D2
	MOVE.L	_DosBase,A6
	JSR	-$54(A6)		; Lock
	TST.L	D0
	BEQ.S	LONGFILER
	MOVE.L	D0,-(SP)

	MOVE.L	D0,D1
	move.L	#Examine,d2
	MOVE.L	_DosBase,A6
	JSR	-$66(A6)		; Examine

	MOVE.L	(SP)+,D1
	JSR	-$5A(A6)		; UnLock

	MOVE.L	Examine+$7C,D0
LONGFILER:
	RTS

; -----------------------------------

OpenFile:
	MOVE.L	_DosBase,A6
	JSR	-30(A6)			; OPEN
	MOVE.L	D0,DisBase
	RTS
CloseFile:
	MOVE.L	_DosBase,A6
	MOVE.L	DisBase,D1
	BEQ.S	NoCloseFile
	JSR	-36(A6)			; CLOSE
	CLR.L	DisBase
NoCloseFile:
	RTS
WriteFile:
	MOVE.L	_DosBase,A6
	MOVE.L	DisBase,D1
	MOVE.L	D3,-(SP)
	JSR	-48(A6)			; WRITE
	MOVE.L	(SP)+,D3
	CMP.L	D0,D3
	RTS
ReadFile:
	MOVE.L	_DosBase,A6
	MOVE.L	DisBase,D1
	MOVE.L	D3,-(SP)
	JSR	-42(A6)			; READ
	MOVE.L	(SP)+,D3
	CMP.L	D0,D3
	RTS

; -----------------------------------
	CNOP	0,4
PONOM:
	MOVE.L	A1,A2
NTXTYA0:
	TST.B	(A2)
	BEQ.S	COPYNOM2
	MOVE.B	#" ",(A2)+
	BRA.S	NTXTYA0
	CNOP	0,4
COPYNOM2:
	MOVE.B	(A0)+,D0
	BEQ.S	PONOMS
	TST.B	(A1)
	BEQ.S	PONOMS
	MOVE.B	D0,(A1)+
	BRA.S	COPYNOM2
PONOMS:	RTS
; -----------------------------------
	CNOP	0,4
CopyNom:
	MOVE.B	(A0)+,(A1)+
	DBEQ	D0,CopyNom
	RTS
; -----------------------------------
	CNOP	0,4
ArreglaNom:
	LEA	FileNom(PC),A1
	MOVE.W	#$100-1,D0
	MOVE.L	8(A2),A0
	TST.B	(A0)
	BEQ.S	ArrglNom
	BSR	CopyNom
	SUBQ	#1,A1
	CMP.B	#":",-1(A1)
	BEQ.S	ArrglNom
	MOVE.B	#"/",(A1)+
ArrglNom:
	MOVE.W	#$100-1,D0
	MOVE.L	4(A2),A0
	BSR	CopyNom
	RTS
; -----------------------------------



; -----------------------------------
;	Pasa Decimal  &  Pasa Hexa v1.0
;	(PD)  Juan Antonio Gomez Galvez
;	(Codigo texto para DEVPAC II),(3-X-92)

;	- D0=Numero que se va a pasar a decimal.
;	- Resultado: D0 y A0 tienen el puntero del buffer
;	  de los numeros en ASCII en decimal.  (10 bytes)

PASDEC:
	LEA	DSUMA(PC),A0
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.W	(A0)+

	MOVE.W	#$08-1,D1
	LEA	DATOSSUMA(PC),A0
SUMBUC01:
	MOVEM.L	D0-D1/A0,-(SP)
	AND.L	#$000F,D0
	TST.B	D0
	BEQ	SUMCON00
SUMBUC02:
	MOVEM.L	D0/A0,-(SP)
	LEA	DSUMA(PC),A1
	BSR	SUMDEC
	MOVEM.L	(SP)+,D0/A0
	SUBQ.B	#$01,D0
	BNE.S	SUMBUC02
SUMCON00:
	MOVEM.L	(SP)+,D0-D1/A0
	LSR.L	#$04,D0
	ADD.L	#$0A,A0
	DBF	D1,SUMBUC01

	LEA	DSUMA(PC),A0
	ADD.L	#$30303030,(A0)+
	ADD.L	#$30303030,(A0)+
	ADD.W	#$3030,(A0)+

	LEA	DSUMA(PC),A0
SUMBUC03:
	TST.B	(A0)
	BEQ	SUMCON01
	MOVE.B	(A0),D0
	CMP.B	#$30,D0
	BNE.S	FINRET
	MOVE.B	#$20,(A0)+
	BRA	SUMBUC03
SUMCON01:
	MOVE.B	#"0",-(A0)
	BRA.S	FINRET
SUMDEC:
	MOVEQ.L	#$0A-1,D1
	ADD.L	#$0A,A0
	ADD.L	#$0A,A1
SUMBUC00:
	MOVE.B	-(A0),D3
	ADD.B	D3,-(A1)
	MOVE.B	(A1),D0
	SUB.B	#$0A,D0
	BCS.S	SUMBIEN00
	MOVE.B	D0,(A1)
	ADD.B	#$01,-1(A1)
	DBF	D1,SUMBUC00
	RTS
SUMBIEN00:
	CLR.L	D0
	DBF	D1,SUMBUC00
	RTS
FINRET:
	LEA	DSUMA(PC),A0
	MOVE.L	A0,D0
	RTS


;	- A0 el puntero del buffer de los
;	  numeros en ASCII en decimal. (10 bytes)
;	- Resultado: D0=Numero en hexadecimal.

PASHEX:
	CLR.L	D5
	LEA	PUNTERO(PC),A1
	MOVE.L	A0,(A1)
	MOVEQ.L	#$0A-1,D0
PASBUC02:
	SUB.B	#$30,(A0)+
	BCC.S	PASCON00
	CLR.B	-$01(A0)
PASCON00:
	CMP.B	#$0A,-$01(A0)
	BLT.S	PASCON01
	CLR.B	-$01(A0)
PASCON01:
	DBF	D0,PASBUC02
	MOVE.L	PUNTERO(PC),A0
	LEA	FDATOSSUMA(PC),A1
	MOVEQ.L	#$08-1,D4
	MOVE.L	#$10000000,D3
PHEBUC01:
	MOVEQ.L	#-1,D7
PHEBUC00:
	ADD.L	#$01,D7
	BSR	COPY1
	BSR	RESTAD
	CMP.B	#$09,D0
	BNE.S	PHEBUC00
	BSR	COPY2
	CLR.L	D6
	TST.L	D7
	BEQ.S	PHECON00
PHEBUC02:
	ADD.L	D3,D6
	SUB.L	#$01,D7
	BNE.S	PHEBUC02
	ADD.L	D6,D5
PHECON00:
	LSR.L	#$04,D3
	SUB.L	#$0A,A1
	DBF	D4,PHEBUC01
	MOVE.L	D5,D0
	RTS
COPY1:
	MOVE.L	PUNTERO(PC),A6
	LEA	DSUMA2(PC),A5
COPCON00:
	MOVE.L	(A6)+,(A5)+
	MOVE.L	(A6)+,(A5)+
	MOVE.W	(A6)+,(A5)+
	RTS
COPY2:
	MOVE.L	PUNTERO(PC),A5
	LEA	DSUMA2(PC),A6
	BRA.S	COPCON00
RESTAD:
	MOVEM.L	A0-A1,-(SP)
	ADD.L	#$0A,A0
	ADD.L	#$0A,A1
	CLR.L	D0
	ROXR.L	#$1,D0		; FLAG X=0
	MOVE.L	#$0A-1,D0
RESBUC00:
	SBCD.B	-(A1),-(A0)
	AND.B	#$0F,(A0)
	DBF	D0,RESBUC00
	MOVE.B	(A0),D0
	MOVEM.L	(SP)+,A0-A1
	RTS

	DC.L	0
DSUMA:
	DS.B	$0A
	DC.L	0
DSUMA2:
	DS.B	$0A
	DC.L	0
DATOSSUMA:
	DC.B	0,0,0,0,0,0,0,0,0,1
	DC.B	0,0,0,0,0,0,0,0,1,6
	DC.B	0,0,0,0,0,0,0,2,5,6
	DC.B	0,0,0,0,0,0,4,0,9,6
	DC.B	0,0,0,0,0,6,5,5,3,6
	DC.B	0,0,0,1,0,4,8,5,7,6
	DC.B	0,0,1,6,7,7,7,2,1,6
FDATOSSUMA:
	DC.B	0,2,6,8,4,3,5,4,5,6
	DC.L	0
PUNTERO:
	DC.L	0

;	Fin del codigo texto.

; -----------------------------------

DisMouse:
	TST.L	MainMenuWnd(PC)
	BEQ.S	NoDisMouse
	TST.L	WREQBASE
	BEQ.S	SiDisMouse
NoDisMouse:
	RTS
SiDisMouse:
	MOVEQ	#$70,D0
	MOVE.L	#$10001,D1
	MOVE.L	$4.W,A6
	JSR	-$2AC(A6)		; AllocVec
	MOVE.L	D0,VECBASE
	BEQ.S	ERVEC
	MOVE.L	D0,A0
	MOVE.L	MainMenuWnd(PC),A1
	MOVE.L	_IntuitionBase(PC),A6
	JSR	-$F0(A6)		; Request
ERVEC:
	MOVE.L	D0,WREQBASE
PBUSY:
	MOVE.L	MainMenuWnd(PC),A0
	LEA	BUSYGFX,A1
	MOVE.L	#16,D0
	MOVE.L	#16,D1
	MOVEQ	#0,D2
	MOVEQ	#0,D3
	MOVE.L	_IntuitionBase,A6
	JMP	-$10E(A6)
; --------------------------------------------------------
EnaMouse:
	TST.L	WREQBASE
	BEQ.S	ERVEC3
	MOVE.L	VECBASE(PC),A0
	MOVE.L	MainMenuWnd(PC),A1
	MOVE.L	_IntuitionBase,A6
	JSR	-$78(A6)		; EndRequest
ERVEC3:
	MOVE.L	VECBASE(PC),D0
	BEQ.S	ERVEC2
	MOVE.L	D0,A1
	MOVE.L	$4.W,A6
	JSR	-$2B2(A6)		; FreeVec
ERVEC2:
	CLR.L	VECBASE
	CLR.L	WREQBASE
PNORM:
	MOVE.L	MainMenuWnd(PC),A0
	MOVE.L	_IntuitionBase,A6
	JMP	-$3C(A6)

	CNOP	0,4
VECBASE:DC.L	0
WREQBASE:DC.L	0
; -----------------------------------

; -----------------------------------


; -----------------------------------
TxtPrint:
	move.b  54(a0),d0
	ext.w   d0
	move.b  55(a0),d1
	ext.w   d1
	move.l  50(a0),a0
	move.l  _IntuitionBase,a6
	TallITextM
	RTS
; -----------------------------------	; D0.l = 0 On
	CNOP	0,4			; D0.l = 1 Off
GadsOnOff:
	MOVE.L	D0,OnOffTAGS+4
	MOVE.L	(A0),A0
	IFEQ	ChoosOff
	BSR	ChooserIs
	BNE.S	.gt
	MOVE.L	#$8003000E,D1		; GA_Disabled
	BRA	ChooserSet
.gt:
	ENDC
	SUB.L	A2,A2
	LEA	OnOffTAGS(PC),A3
	MOVE.L	_GadToolsBase(PC),A6
	JSR	-$2A(A6)
	RTS
	CNOP	0,4
OnOffTAGS:
	DC.L    $8003000E,1
	DC.L	0,0
; -----------------------------------
UpdateTag:
	MOVEM.L	D0-D1/A0,-(SP)
	MOVE.W	D1,D0
	MOVE.W	D2,D1
	BSR	SetGadgetValue
	MOVEM.L	(SP)+,D0-D1/A0

	MOVE.L	([iWnd.w,A0]),A1
	LEA	([iGadgets.w,A0],D2.w*4),A0

	MOVE.L	D0,.tagData
	MOVE.L	D1,.tagData+4
	MOVE.L	(A0),A0
	SUB.L	A2,A2
	LEA	.tagData(PC),A3
	MOVE.L	_GadToolsBase,A6
	JSR	-$2A(A6)
	RTS
	CNOP	0,4
.tagData:
	DC.L    0,0
	DC.L	0,0
; -----------------------------------

; <=-----------------------=>

; A0:xxxPunts
; A1:Dir TagListBase
; D0=Número de gadget
; D1=Número de Tag a modificar
; D2=Dato a modificar.
	CNOP	0,4
OverrideTag:
	CMP.L	#$8008000F,D1
	BNE.S	.noGadgetValue

	MOVEM.L	D0/D1,-(SP)
	MOVE.W	D0,D1
	MOVE.W	D2,D0
	BSR	SetGadgetValue
	MOVEM.L	(SP)+,D0/D1
.noGadgetValue:
.loop1:
	TST.W	D0
	BEQ.S	.skip
.loop2:
	TST.L	(A1)+
	DBNE	D0,.loop1
	ADDQ	#4,A1
	BRA.S	.loop2
.skip:
	TST.L	(A1)
	BEQ.S	.ret
	CMP.L	(A1)+,D1
	BEQ.S	.over
	ADDQ	#4,A1
	BRA.S	.skip
.over:
	MOVE.L	D2,(A1)+
.ret:
	RTS

; <=-----------------------=>
	CNOP	0,4
Centrar:
	TST.L	(A0)
	BNE.S	MIRACERO
	RTS
MIRACERO:
	MOVE.L	(A0)+,A2
	MOVE.L	(A0)+,D1
	MOVE.L	$C(A2),A1
	MOVEQ	#0,D0
MIRACEROB:
	ADDQ.W	#1,D0
	TST.B	(A1)+
	BNE.S	MIRACEROB
	SUBQ.W	#1,D0
	LSL.W	#3,D0
	SUB.W	D0,D1
	LSR.W	#1,D1
	MOVE.W	D1,4(A2)
	BRA.S	Centrar
; <=-----------------------=>

; <=-------------------------------------------------------=>
;	 Rutina de control de lectura de Gadgets.
;	<= -------------------------------------=>
;	    A1 = SaltosGadgets.	; Para salir hacer:  ADD.L  #16+4,SP
;	-12(A1)= Window Handle.
;	 -8(A1)= Punteros Gadgets.
;	 -4(A1)= Nº de Gadgets-1
	CNOP	0,8
Control:
	IFNE	MenuAuto
	CMP.L	#MainMenuPunts,A1
	BNE.S	.noAuto
	MOVEM.L	D0-D7/A0-A6,-(SP)
	JSR	MenuAutoRun		; test builds: the Insert/Power ON trips, then the menu as usual
	MOVEM.L	(SP)+,D0-D7/A0-A6
.noAuto:
	ENDC
	IFNE	MenuShow
	CMP.L	#MainMenuPunts,A1
	BNE.S	.noShow
	TST.B	.shown
	BNE.S	.noShow
	ST	.shown
	MOVEM.L	D0-D7/A0-A6,-(SP)
	IFEQ	MenuShow-1
	BSR	About
	ENDC
	IFEQ	MenuShow-2
	BSR	HelpPage
	ENDC
	IFEQ	MenuShow-3
	LEA	tErNoCartucho(PC),A0
	BSR	ImpError
	ENDC
	IFEQ	MenuShow-4
	BSR	Insert
	ENDC
	IFEQ	MenuShow-5
	BSR	NoAGA2
	ENDC
	IFEQ	MenuShow-6
	IFEQ	ScanOff
	JSR	RtgScanSet2		; as Options > RTG scanlines > Hard 50%
	ENDC
	BSR	SavePrefs		; as Project > Save Prefs
	BSR	About
	ENDC
	MOVEM.L	(SP)+,D0-D7/A0-A6
	BRA.S	.noShow
.shown:	DC.B	0
	EVEN
.noShow:
	ENDC
	CLR.W	ControlKeys
	MOVE.L	-8(A1),-(SP)
	MOVE.L	A1,-(SP)
	MOVE.L	-12(A1),A0
	MOVE.L	(A0),-(SP)
ControlLoop:
	MOVE.L	(SP),A0
	MOVE.L	$56(A0),A0
	MOVE.L	$4,A6
	JSR	-$180(A6)	; Wait Port. (iport)(A0)

	MOVE.L	(SP),A0
	MOVE.L	$56(A0),A0
	MOVE.L	_GadToolsBase,A6
	JSR	-$48(A6)	; (D0)IntuiMessage = GT_GetIMsg(iport)(A0)
	TST.L	D0
	BEQ.S	ControlLoop

	MOVE.L	D0,A1
	MOVE.L	A1,-(SP)	; STRUCTURE IntuiMessage
	MOVE.L	$1C(A1),-(SP)	; APTR im_IAddress (the pointer to the Gadget or the Screen)
	MOVE.L	$14(A1),-(SP)	; LONG im_Class (the Class bits correspond directly with the IDCMP Flags)
	MOVE.W	$18(A1),-(SP)	; WORD im_Code (the Code field is for special values like MENU number)

	MOVE.L	_GadToolsBase,A6
	JSR	-$4E(A6)	; GT_ReplyIMsg(imsg)(A1)

	MOVE.W	(SP)+,D2
	MOVEM.L	(SP)+,D0-D1/A1

	CMP.W	#$200,D0	; IDCMP_CLOSEWINDOW
	BEQ	ControlCloseWindow

	CMP.W	#$100,D0	; IDCMP_MENUPICK
	BEQ	ControlMenuPick

;	CMP.W	#$010,D0	; IDCMP_MOUSEMOVE
;	BEQ	ControlMouseMove

	CMP.W	#$020,D0	; IDCMP_GADGETDOWN
	BEQ	ControlGadgetDown

	CMP.W	#$040,D0	; IDCMP_GADGETUP
	BEQ	ControlGadgetUp

	CMP.W	#$400,D0	; IDCMP_RAWKEY
	BEQ.S	ControlRawKey

	BRA.S	ControlLoop

; -----------------------------------=> Vuelta al Control.
ControlRET:
	RTS
; -----------------------------------=> Salir del Control.
ControlSalir:
	ADD.W	#16,SP
	RTS
; -----------------------------------=> Usado por Subrutina Control-Gadgets
ControlCloseWindow:
	ADD.W	#12,SP
	RTS
; -----------------------------------

ControlRawKey:
	MOVEQ	#0,D1
	MOVE.W	ControlKeys,D1
	MOVE.B	$19(A1),D1	; Tecla.
	MOVE.L	4(SP),A1
	MOVE.L	-16(A1),D0
	BEQ	ControlLoop	

	CMP.B	#$60,D1		; Shift Izquierdo Pulsado.
	BEQ.S	ShiftPul
	CMP.B	#$61,D1		; Shift Derecho Pulsado.
	BEQ.S	ShiftPul
	CMP.B	#$E0,D1		; Shift Izquierdo Soltado.
	BEQ.S	ShiftSol
	CMP.B	#$E1,D1		; Shift Derecho Soltado.
	BEQ.S	ShiftSol

	MOVE.L	D0,A1
EsTeclaBuc:
	CMP.L	#$100,(A1)
	BEQ.S	EsFullTecla
	TST.L	(A1)
	BMI	ControlLoop
	CMP.L	(A1)+,D1
	ADDQ	#4,A1
	BNE.S	EsTeclaBuc

	MOVE.L	-4(A1),A1
	JSR	(A1)
	BRA	ControlLoop

EsFullTecla:
	MOVE.L	4(A1),A1
	JSR	(A1)
	BRA	ControlLoop

ShiftPul:
	BSET	#0,ControlKeys
	BRA	ControlLoop

ShiftSol:
	BCLR	#0,ControlKeys
	BRA	ControlLoop

; -----------------------------------

ControlGadgetDown:
	MOVE.L	4(SP),A1	; ***Punts
	MOVE.L	8(SP),A0	; ***Wnd

	SUBQ.L	#4,A1
	MOVE.L	(A1),D0
	BMI	ControlCloseWindow

	MOVE.L	#$FFFF,D3
.loop1:
	ADDQ.W	#1,D3
	CMP.L	(A0)+,D1
	DBEQ	D0,.loop1
	TST.W	D0
	BMI	ControlLoop

	CMP.W	#GD_JoyPort,D3
	BEQ.S	ControlGadgetUp

	BRA	ControlLoop

ControlGadgetUp:
	MOVE.L	4(SP),A1	; ***Punts
	MOVE.L	8(SP),A0	; ***Wnd

	SUBQ.L	#4,A1
	MOVE.L	(A1),D0
	BMI	ControlCloseWindow

	MOVE.L	#$FFFF,D3
.loop1:
	ADDQ.W	#1,D3
	CMP.L	(A0)+,D1
	DBEQ	D0,.loop1
	TST.W	D0
	BMI	ControlLoop


	IFEQ	ChoosOff
	BSR	ChooserCode	; a chooser: D2 = its setting
	ENDC
	MOVE.L	4(SP),A0	; ***Punts
	MOVE.W	D2,D0
	MOVE.W	D3,D1
	BSR	SetGadgetValue


	MOVE.L	(A1),D0
.loop2:
	ADDQ.L	#4,A1
	TST.L	4(A1)
	BEQ	ControlLoop
	CMP.L	(A1)+,D3
	DBEQ	D0,.loop2
	TST.W	D0
	BMI	ControlLoop

	MOVE.L	(A1),A1
	JSR	(A1)
	BRA	ControlLoop

; -----------------------------------

ControlMenuPick:
	MOVE.L	$14(A1),D0
	MOVE.W	$18(A1),D1
	MOVE.L	$1C(A1),A0

	BFEXTU	D1{27:5},D2
	BFEXTU	D1{21:6},D3
	BFEXTU	D1{16:5},D4

	CMP.W	#$1F,D2
	BEQ	ControlLoop
	MOVE.L	(PunterosMenu.W,PC,D2.W*4),A0
	CMP.W	#$2F,D3
	BEQ	ControlLoop
	CMP.W	#$1F,D4
	BEQ.S	EJECMENU
	MOVE.L	(A0,D3.W*4),A0
	MOVE.W	D4,D3
EJECMENU:
	JSR	([A0,D3.W*4])
	BRA	ControlLoop

; -----------------------------------

; A0:WindowPunts
; D0:Value
; D1:GadgetKey
SetGadgetValue:
	MOVE.L	iValues(A0),A0
	TST.L	A0
	BEQ.S	.ret
.loop:
	TST.W	(A0)
	BMI.S	.ret

	ADDQ	#4,A0

	CMP.W	-4(A0),D1
	BNE.S	.loop

	MOVE.W	D0,-(A0)
.ret:
	RTS

; A0:WindowPunts
; D0:DefaultValue
; D1:GadgetKey
; D0=Value
GetGadgetValue:
	MOVE.L	A0,-(SP)
	MOVE.L	iValues(A0),A0
	TST.L	A0
	BEQ.S	.ret
.loop:
	TST.W	(A0)
	BMI.S	.ret

	ADDQ	#4,A0

	CMP.W	-4(A0),D1
	BNE.S	.loop

	MOVEQ	#0,D0
	MOVE.W	-(A0),D0
.ret:
	MOVE.L	(SP)+,A0
	RTS





; <=-------------------------------------------------------=>
; <=-------------------------------------------------------=>
; <=-------------------------------------------------------=>


	CNOP	0,4
	IFEQ	NO_MENU2
PunterosMenu:
	DC.L	MenuProject
	DC.L	MenuCartridges
	DC.L	0,0
MenuProject:
	DC.L	About			; About
	DC.L	HelpPage		; Help Page
	DC.L	ControlRET		; -----
	DC.L	SavePrefs		; Save Prefs
	DC.L	ControlRET		; -----
	DC.L	ControlSalir		; Quit
MenuCartridges:
	DC.L	Insert			; Insert Cartridge
	DC.L	Eject			; Eject  Cartridge
	ELSE
PunterosMenu:
	DC.L	MenuProject
	DC.L	MenuCartridges
	DC.L	MenuOptions
	DC.L	0,0

MenuProject:
	DC.L	About			; About
	DC.L	HelpPage		; Help Page
	DC.L	ControlRET		; -----
	DC.L	SubMenuScreen		; Menu Screen
	DC.L	ControlRET		; Cheat Mode
	DC.L	ControlRET		; -----
	DC.L	SubMenuVRAM		; Save VRAM
	DC.L	ControlRET		; -----
	DC.L	SavePrefs		; Save Prefs
	DC.L	ControlRET		; -----
	DC.L	ControlSalir		; Quit
	DC.L	ControlRET		; -----
SubMenuVRAM:
	DC.L	ControlRET		; Screen
	DC.L	ControlRET		; Strites
	DC.L	ControlRET		; -----
SubMenuScreen:
	DC.L	SETPAL			; Set PAL
	DC.L	SETNTSC			; Set NTSC
	DC.L	ControlRET
MenuCartridges:
	DC.L	Insert			; Insert Cartridge
	DC.L	Eject			; Eject  Cartridge
	DC.L	ControlRET		; -----
	DC.L	ControlRET		; Load Freezed
	DC.L	ControlRET		; Save Freezed
	DC.L	ControlRET		; -----
	DC.L	ControlRET		; Load RAM-Battery
	DC.L	ControlRET		; Save RAM-Battery
	DC.L	ControlRET		; -----
	DC.L	ControlRET		; Clear RAM-Battery
	DC.L	ControlRET		; -----
MenuOptions:
	DC.L	ControlRET		; JoyStick 2 ON
	DC.L	ControlRET		; Swap JoyPorts
	DC.L	ControlRET		; -----
	DC.L	ControlRET		; Black Border
	DC.L	ControlRET		; No illogical moves
	DC.L	ControlRET		; -----
	DC.L	ControlRET		; Auto-Load Battery
	DC.L	ControlRET		; Auto-Save Battery
	DC.L	ControlRET		; -----
	DC.L	ControlRET		; Ask for Reset
	DC.L	ControlRET		; Overwrite
	DC.L	ControlRET		; -----
	IFEQ	ScanOff
	DC.L	SubMenuScan		; RTG scanlines (sub-items: each needs its entry)
SubMenuScan:
	DC.L	RtgScanSet0		; Off
	DC.L	RtgScanSet1		; Hard 25%
	DC.L	RtgScanSet2		; Hard 50%
	DC.L	RtgScanSet3		; Hard 75%
	IFEQ	NO_BLENDLV
	DC.L	RtgScanSet5		; Blended light
	ENDC
	DC.L	RtgScanSet4		; Blended
	IFEQ	NO_BLENDLV
	DC.L	RtgScanSet6		; Blended strong
	ENDC
	DC.L	ControlRET
	ENDC


; <=-------------------------------------------------------=>
; <=-------------------------------------------------------=>
; <=-------------------------------------------------------=>

	ENDC

	CNOP	0,8
MCeros:	DS.L	16

; <=-------------------------------------------------------=>

; =------------------------------------------=> Datos de Ventanas:

	CNOP	0,4

iValues=-20
iKeys=-16
iWnd=-12
iGadgets=-8
iCNT=-4

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	MainMenuValues
	DC.L	0
	DC.L	MainMenuWnd
	DC.L	MainMenuGadgets
	DC.L	MainMenu_CNT-1
MainMenuPunts:
	DC.L	GD_Insert,Insert
	DC.L	GD_PowerON,PowerON
	DC.L	GD_Continue,Continue
	DC.L	GD_Exit,ControlSalir
	DC.L	GD_JoyType,ImpJoyType
	DC.L	GD_HelpPage,HelpPage
	IFEQ	NO_MENU2
	DC.L	GD_JoyPort,ImpJoyType
	IFEQ	DispOff
	DC.L	GD_INTER,DispSel
	IFEQ	ScanOff
	DC.L	GD_Refresh,ScanSel
	ENDC
	ENDC
	ENDC
	DC.L	0,0
MainMenuValues:
	DC.W	GD_JoyType,0
	DC.W	GD_JoyPort,0
	DC.W	GD_ScrMode,0
	IFEQ	NO_MENU2
	DC.W	GD_INTER,0
	DC.W	GD_Refresh,0
	ENDC
	DC.W	-1,-1


; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	0
	DC.L	QuitKeys
	DC.L	QuitWnd
	DC.L	QuitGadgets
	DC.L	Quit_CNT-1
QuitPunts:
;	DC.L	GD_QuitYes,ControlSalir
;	DC.L	GD_QuitNo,NoQuit
	DC.L	0,0
QuitKeys:
	DC.L	$40,ControlSalir
	DC.L	-1,-1

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	0
	DC.L	ImpErrorKeys
	DC.L	ImpErrorWnd
	DC.L	ImpErrorGadgets
	DC.L	ImpError_CNT-1
ImpErrorPunts:
	DC.L	GD_Econtinue,ControlSalir
	DC.L	0,0
ImpErrorKeys:
	DC.L	$40,ControlSalir
	DC.L	-1,-1

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	0
	DC.L	HelpPageKeys
	DC.L	HelpPageWnd
	DC.L	HelpPageGadgets
	DC.L	HelpPage_CNT-1
HelpPagePunts:
	DC.L	GD_HPcontinue,ControlSalir
	DC.L	0,0
HelpPageKeys:
	DC.L	$40,ControlSalir
	DC.L	-1,-1

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	0
	DC.L	CheatKeys
	DC.L	CheatWnd
	DC.L	CheatGadgets
	DC.L	Cheat_CNT-1
CheatPunts:
	DC.L	GD_PokeAddress,ControlRET
	DC.L	GD_PokeValue,ControlRET
;	DC.L	GD_Poke,DoPoke
;	DC.L	GD_CheatSeaVal,CheatSearch
;	DC.L	GD_CheatComVal,CheatCompare
;	DC.L	GD_CheatMore,CheatMore
	DC.L	GD_PokeExit,ControlSalir
	DC.L	0,0
CheatKeys:
	DC.L	-1,-1

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	0
	DC.L	AboutKeys
	DC.L	AboutWnd
	DC.L	AboutGadgets
	DC.L	About_CNT-1
AboutPunts:
	DC.L	GD_AboutCont,ControlSalir
	DC.L	GD_AboutExit,ControlSalir
	DC.L	0,0
AboutKeys:
	DC.L	$40,ControlSalir
	DC.L	-1,-1

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	0
	DC.L	0
	DC.L	MC68020Wnd
	DC.L	MC68020Gadgets
	DC.L	MC68020_CNT-1
MC68020PUNTS:
	DC.L	GD_magacontinue,ControlSalir
	DC.L	GD_magaExitWB,MC68020SALIR
	DC.L	0,0

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

; =------------------------------------------<=

	CNOP	0,8
DatsEnginePic:
	DC.W	28,09
	DC.W	325,51
	DC.W	3
	DC.L	GGLogo
	DC.B	7,0
	DC.L	0

	CNOP	0,8
DatsJoyTypePic:
	DC.W	0,0
	DC.W	47,16
	DC.W	3
DirJoyTypePic:	DC.L	GBTeclado
	DC.B	7,0
	DC.L	0

; -----------------------------------

; =------------------------------------------=> Include de GadToolsBox
	CNOP	0,8
	INCLUDE	"GadToolsBox.asm"
; =------------------------------------------<=


; =------------------------------------------=> Sección gráfica de prueba.
	IFND	NF_Menu
	SECTION	Gfx,data_c

	CNOP	0,8
GGLogo: INCBIN	"res/AmiPC-Engine_Logo.raw"
	CNOP	0,8
GBTeclado:INCBIN "res/Teclado.raw"
	CNOP	0,8
GBJoyStick:INCBIN "res/JoyStick.raw"
	CNOP	0,8
GBJoypad:INCBIN	"res/Joypad.raw"
	CNOP	0,8
GBCD32:	INCBIN	"res/CD32.raw"

	CNOP	0,8
BUSYGFX:
	dc.w	$0000,$0000
	dc.w	$0400,$07C0
	dc.w	$0000,$07C0
	dc.w	$0100,$0380
	dc.w	$0000,$07E0
	dc.w	$07C0,$1FF8
	dc.w	$1FF0,$3FEC
	dc.w	$3FF8,$7FDE
	dc.w	$3FF8,$7FBE
	dc.w	$7FFC,$FF7F
	dc.w	$7EFC,$FFFF
	dc.w	$7FFC,$FFFF
	dc.w	$3FF8,$7FFE
	dc.w	$3FF8,$7FFE
	dc.w	$1FF0,$3FFC
	dc.w	$07C0,$1FF8
	dc.w	$0000,$07E0
	dc.w	$0000,$0000
	dc.w	$0000,$0000
	dc.w	$0000,$0000

	ENDC
; =------------------------------------------<=
