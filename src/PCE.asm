

	IFND	LogEnabled	; default, or set with -DLogEnabled=x
LogEnabled=0
	ENDC



PCE_Init:
	LEA	Regs,A3
;	-=-=-=-=-=-=-=-=-=-=-=-		; Borra tabla base de datos.
	MOVE.L	A3,A0
	MOVE.W	#($400/4)-1,D0
	BSR	BorraMem
;	-=-=-=-=-=-=-=-=-=-=-=-

	BSR	IO_Init
	IFEQ	NO_PSGWAVE
	JSR	PSGReset	; PSG registers and wave RAM of the last game
	ENDC

	BSR	CPU_Init


	RTS


;	A0.L : Cardtridge Address
PCE_SetCardtridge:
	BSR	IO_SetCardtridge

	MOVEM.L	InitReg(PC),D0-D7/A0-A6


	MOVE.W	([PagRead+(7*4).W,A3],$FFFE.L),D1
	ROR.W	#8,D1

	MOVE.L	D1,A5
	LSR.W	#8,D1
	LSR.B	#5,D1
	ADD.L	PagRead(A3,D1.W*4),A5
	LEA	Restas(A3,D1.W*8),A2

	ST	IFF(A3)

	RTS


PCE_Start:

	MOVEQ.L	#0,D0
	MOVE.L	#263-1,D1	; Total number of vertical scan-lines (0 to 223 = Screen, 224 to end = border)

	clr.w	ScanLine(A3)
	bsr	logScrollXY

PCE_StaBuc:
	MOVEM.W	D0/D1,-(SP)

	move.w	d0,ScanLine(A3)


; RasterInt check
	BTST	#2,VDP_Regs+1+(5*2)	; (Están invertidos)
	BEQ.S	noRasterInt
	MOVE.W	VDP_Regs+(6*2),D2
	sub.W	#64,D2
	AND.W	#$03FF,D2
	CMP.W	D0,D2
	BNE.S	noRasterInt
	OR.B	#STATUS_RASTER_INT,Status(A3)
	OR.B	#IRQ1_INT,IRQ_Pending(A3)
	IFEQ	NO_VDLATE|NO_VDCDMA
	MOVE.W	D0,RrLine
	ENDC
noRasterInt:


; vBlankInt check
	IFEQ	NO_VDCDMA
	MOVE.W	VDP_Regs+($0D*2),D2	; vblank after the last display line: VDW + 1
	AND.W	#$01FF,D2
	ADDQ.W	#1,D2
	CMP.W	#128,D2			; R0D not set yet or past the frame: line 251
	BCS.S	.vdOld
	CMP.W	#263,D2
	BCS.S	.vdCmp
.vdOld:	MOVE.W	#(240+11),D2
.vdCmp:	MOVE.W	D2,VblLine
	CMP.W	D2,D0
	IFEQ	NO_VDLATE
; RCR on the vblank line: the raster IRQ comes first, the vblank later in that line, as two IRQs
; (fumobinning's handler looks at RR and, only without it, at VD). One line on: the next PCE line.
	BEQ.S	.vdNow
	CMP.W	VdLate,D0
	BNE.S	.vdNo
	MOVE.W	#-1,VdLate
	BRA.S	.vdRun
.vdNow:	CMP.W	RrLine,D0
	BNE.S	.vdRun
	MOVE.W	#-1,RrLine
	ADDQ.W	#1,D2
	MOVE.W	D2,VdLate
	BRA.S	.vdNo
.vdRun:
	ELSE
	BNE.S	.vdNo
	ENDC
	BSR	VdcVblank
.vdNo:	TST.B	SatbWait		; the SAT DMA ends a few lines into the vblank
	BEQ.S	noVblankInt
	SUBQ.B	#1,SatbWait
	BNE.S	noVblankInt
	BTST	#0,VDP_Regs+1+($0F*2)
	BEQ.S	noVblankInt
	OR.B	#$08,Status(A3)
	OR.B	#IRQ1_INT,IRQ_Pending(A3)
	ELSE
	BTST	#3,VDP_Regs+1+(5*2)	; (Están invertidos)
	BEQ.S	noVblankInt
	IFEQ	NO_VBLLINE
	MOVE.W	VDP_Regs+($0D*2),D2	; vblank after the last display line: VDW + 1
	AND.W	#$01FF,D2		; (as Mesen: R-Type 240, HuCNoid/Atlantean 224)
	ADDQ.W	#1,D2
	CMP.W	#128,D2			; R0D not set yet or past the frame: line 251 as before
	BCS.S	.vbOld
	CMP.W	#263,D2
	BCS.S	.vbCmp
.vbOld:	MOVE.W	#(240+11),D2
.vbCmp:	CMP.W	D2,D0			; vBlank Interrupt?
	BNE	noVblankInt
	ELSE
	CMP.W	#(240+11),D0		; vBlank Interrupt?
	BNE.S	noVblankInt
	ENDC
	OR.B	#STATUS_VBLANK_INT,Status(A3)
	OR.B	#IRQ1_INT,IRQ_Pending(A3)

	IFEQ	NO_SATBWRAP
	MOVEM.L	D0/D1/A0/A1,-(SP)	; SAT from VRAM word SATB on, wrapping at
	lea	VRAM,A0			; the end of VRAM as the VDC does
	move.w	VDP_Regs+($13*2),d1
	lea	SpriteCoor,A1
	move.w	#(256)-1,D0
.loopw:
	and.w	#$7FFF,d1
	move.w	(a0,d1.w*2),(a1)+
	addq.w	#1,d1
	dbf	d0,.loopw
	MOVEM.L	(SP)+,D0/D1/A0/A1
	ELSE
	MOVEM.L	D0/A0/A1,-(SP)

	lea	VRAM,A0
	add.w	VDP_Regs+($13*2),A0
	add.w	VDP_Regs+($13*2),A0
	lea	SpriteCoor,A1
	move.w	#(64)-1,D0
.loop:
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	dbf	d0,.loop

	MOVEM.L	(SP)+,D0/A0/A1
	ENDC
	ENDC
noVblankInt:



	IFEQ	NO_CYC455
	MOVE.W	#455,D0		; 7.16 MHz / 15.73 kHz = 455 CPU cycles per scan-line
	IFEQ	NO_CSL
	TST.B	CpuSlow
	BEQ.S	.fast
	MOVE.W	#114,D0		; CSL: 1.79 MHz, 455 / 4
.fast:
	ENDC
	ELSE
	MOVE.W	#340,D0		; CPU Cycles to process in one vertial scan-line
	ENDC
	IFNE	LogPCs
	MOVE.W	2(SP),D1		; the line (MOVEM.W D0/D1 above)
	AND.W	#31,D1
	BNE.S	.nopc
	MOVE.W	2(SP),D1
	LSR.W	#5,D1
	MOVE.L	D0,-(SP)
	MOVE.L	A5,D0
	SUB.W	(A2),D0
	MOVE.W	D0,(LogPCbuf,D1.W*2)
	MOVE.L	(SP)+,D0
.nopc:
	ENDC
	BSR	CPU_Loop
	IFEQ	NO_TIMER
	BSR	TimerLine
	ENDC


	MOVEM.W	(SP)+,D0/D1

	ADDQ.W	#1,D0

	DBF	D1,PCE_StaBuc



	lea	Regs,A3
	IFEQ	NO_BGLINE|NO_BGMASK
	JSR	BgLogSwap		; before the scroll list is offered to the vblank
	ENDC
	movem.l	ScrollChangesNow(a3),d0/d1
	exg.l	d0,d1
	movem.l	d0/d1,ScrollChangesNow(a3)


	move.l	d1,ScrollChangesToRender(a3)
	move.l	d0,ScrollChangesIndex(a3)
	move.w	#-1,(d0.l)


	moveq	#0,d0
	moveq	#0,d1

	RTS



; ------------------------------------> Borra memoria. (A0=Dir.MEM) D0.w=(x/4)-1
	CNOP	0,8
BorraMem:
	CLR.L	(A0)+
	DBF	D0,BorraMem
	RTS
; ------------------------------------<



	CNOP	0,8
InitReg:
	DC.L	0,0,$0100,0,0,0,$01FF,0	; D0-D7
	DC.L	0			; A0
	DC.L	0			; A1
	DC.L	Regs+Restas+(4*8)	; A2
	DC.L	Regs			; A3
	DC.L	0			; A4
	DC.L	0			; A5
	DC.L	IRAM+$01FF		; A6




;	-=========-
;	 Variables
;	-=========-

PagRead = -$40
PagWrite = -$20
Restas = -$80
Desbor = -$C0-Restas

Status = $7
TipoIntOr = $11

DirVRAM = $4
DirSRAM = $6

VFF = $50
BFF = $51
DFF = $52
IFF = $53

LeeVROMSkip = $9

JoyCnt = $A
JoyX = $B
KeyX = $10

CoorS = $C
CoorX = $D
CoorY = $E

SalirMenu = $F

MapROMBase = $14
MaskROM = $18
MaskROM2 = $1A
MaskVROM = $1C

ScanLine = $1E

TabMap = $20

Cycles = $0;

IRQ_Enabled = $2A
IRQ_Pending = $2B

VDP_Index = $2C

PAL_Index = $2E
PAL_Data = $30

TnnCyclesCount = $32

ScrollChangesNow = $40
ScrollChangesNext = $44
ScrollChangesIndex= $48
ScrollChangesToRender = $4C



	CNOP	0,8

	DS.L	2		; -$C0(A3)	Desbor  [-$40(Restas)]
	DS.L	2		; -$B8(A3)
	DS.L	2		; -$B0(A3)
	DS.L	2		; -$A8(A3)
	DS.L	2		; -$A0(A3)
	DS.L	2		; -$98(A3)
	DS.L	2		; -$90(A3)
	DS.L	2		; -$88(A3)

	DS.L	2		; -$80(A3)	Restas
	DS.L	2		; -$78(A3)
	DS.L	2		; -$70(A3)
	DS.L	2		; -$68(A3)
	DS.L	2		; -$60(A3)
	DS.L	2		; -$58(A3)
	DS.L	2		; -$50(A3)
	DS.L	2		; -$48(A3)


	DC.L	0		; -$40(A3)	PagRead
	DC.L	0		; -$3C(A3)
	DC.L	0		; -$38(A3)
	DC.L	0		; -$34(A3)
	DC.L	0		; -$30(A3)
	DC.L	0		; -$2C(A3)
	DC.L	0		; -$28(A3)
	DC.L	0		; -$24(A3)

	DC.L	0		; -$20(A3)	PagWrite
	DC.L	0		; -$1C(A3)
	DC.L	0		; -$18(A3)
	DC.L	0		; -$14(A3)
	DC.L	0		; -$10(A3)
	DC.L	0		; -$0C(A3)
	DC.L	0		; -$08(A3)
	DC.L	0		; -$04(A3)
Regs:
	DC.W	0	;     (A3)	Cycles
	DC.B	0	;   $2(A3)
	DC.B	0	;   $3(A3)
	DC.W	0	;   $4(A3)	DirVRAM
	DC.B	0	;   $6(A3)	DirSRAM
	DC.B	0	;   $7(A3)	Status
	DC.B	0	;   $8(A3)
	DC.B	0	;   $9(A3)	LeeVROMSkip
	DC.B	0	;   $A(A3)	JoyCnt
	DC.B	0	;   $B(A3)	JoyX
	DC.B	0	;   $C(A3)	CoorS
	DC.B	0	;   $D(A3)	CoorX
	DC.B	0	;   $E(A3)	CoorY
	DC.B	0	;   $F(A3)	SalirMenu
	DC.B	0	;  $10(A3)	KeyX
	DC.B	0	;  $11(A3)	TipoIntOr
	DC.B	0	;  $12(A3)
	DC.B	0	;  $13(A3)
	DC.L	0	;  $14(A3)	MapROMBase
	DC.W	0	;  $18(A3)	MaskROM
	DC.W	0	;  $1A(A3)	MaskROM2
	DC.W	0	;  $1C(A3)	MaskVROM
	DC.W	0	;  $1E(A3)	ScanLine

	DS.B	8	;  $20(A3)	TabMap

	DC.W	0	;  $28(A3)
	DC.B	0	;  $2A(A3)	IRQ_Enabled
	DC.B	0	;  $2B(A3)	IRQ_Pending

	DC.B	0	;  $2C(A3)	VDP_Index
	DC.B	0	;  $2D(A3)

	DC.W	0	;  $2E(A3)	PAL_Index
	DC.W	0	;  $30(A3)	PAL_Data

	DC.W	0	;  $32(A3)	TnnCyclesCount
	DC.L	0	;  $34(A3)
	DC.L	0	;  $38(A3)
	DC.L	0	;  $3C(A3)

	DC.L	0	;  $40(A3)	ScrollChangesNow
	DC.L	0	;  $44(A3)	ScrollChangesNext
	DC.L	0	;  $48(A3)	ScrollChangesIndex
	DC.L	0	;  $4C(A3)	ScrollChangesToRender

	DC.B	0	;  $50(A3)	VFF
	DC.B	0	;  $51(A3)	BFF
	DC.B	0	;  $52(A3)	DFF
	DC.B	0	;  $53(A3)	IFF


FRegs:	DS.B	$400-(FRegs-Regs)
;	 -----------------------------------------------------------
;	**  Tablas de instrucciones del 6510 Simulado por MC68020  **
;	 -----------------------------------------------------------
Instr:
	DC.L	BRKnn,ORAix,SXYnn,ST0nn,TSBzp,ORAzp,ASLzp,RMB0	; 00
	DC.L	PHPnn,ORAin,ASLra,JAMnn,TSBab,ORAab,ASLab,BBR0	; 08
	DC.L	BPLnn,ORAiy,ORAim,ST1nn,TRBzp,ORAzx,ASLzx,RMB1	; 10
	DC.L	CLCnn,ORAay,INCra,JAMnn,TRBab,ORAax,ASLax,BBR1	; 18
	DC.L	JSRnn,ANDix,SAXnn,ST2nn,BITzp,ANDzp,ROLzp,RMB2	; 20
	DC.L	PLPnn,ANDin,ROLra,JAMnn,BITab,ANDab,ROLab,BBR2	; 28
	DC.L	BMInn,ANDiy,ANDim,JAMnn,BITzx,ANDzx,ROLzx,RMB3	; 30
	DC.L	SECnn,ANDay,DECra,JAMnn,BITax,ANDax,ROLax,BBR3	; 38
	DC.L	RTInn,EORix,SAYnn,TMAnn,BSRnn,EORzp,LSRzp,RMB4	; 40
	DC.L	PHAnn,EORin,LSRra,JAMnn,JMPab,EORab,LSRab,BBR4	; 48
	DC.L	BVCnn,EORiy,EORim,TAMnn,CSLnn,EORzx,LSRzx,RMB5	; 50
	DC.L	CLInn,EORay,PHYnn,JAMnn,JAMnn,EORax,LSRax,BBR5	; 58
	DC.L	RTSnn,ADCix,CLAnn,JAMnn,STZzp,ADCzp,RORzp,RMB6	; 60
	DC.L	PLAnn,ADCin,RORra,JAMnn,JMPid,ADCab,RORab,BBR6	; 68
	DC.L	BVSnn,ADCiy,ADCim,TIInn,STZzx,ADCzx,RORzx,RMB7	; 70
	DC.L	SEInn,ADCay,PLYnn,JAMnn,JMPax,ADCax,RORax,BBR7	; 78
	DC.L	BRAnn,STAix,CLXnn,TSTzp,STYzp,STAzp,STXzp,SMB0	; 80
	DC.L	DEYnn,BITin,TXAnn,JAMnn,STYab,STAab,STXab,BBS0	; 88
	DC.L	BCCnn,STAiy,STAim,TSTab,STYzx,STAzx,STXzy,SMB1	; 90
	DC.L	TYAnn,STAay,TXSnn,JAMnn,STZab,STAax,STZax,BBS1	; 98	(9C,9E)
	DC.L	LDYin,LDAix,LDXin,TSTzx,LDYzp,LDAzp,LDXzp,SMB2	; A0
	DC.L	TAYnn,LDAin,TAXnn,JAMnn,LDYab,LDAab,LDXab,BBS2	; A8
	DC.L	BCSnn,LDAiy,LDAim,TSTax,LDYzx,LDAzx,LDXzy,SMB3	; B0
	DC.L	CLVnn,LDAay,TSXnn,JAMnn,LDYax,LDAax,LDXay,BBS3	; B8
	DC.L	CPYin,CMPix,CLYnn,TDDnn,CPYzp,CMPzp,DECzp,SMB4	; C0
	DC.L	INYnn,CMPin,DEXnn,JAMnn,CPYab,CMPab,DECab,BBS4	; C8
	DC.L	BNEnn,CMPiy,CMPim,TINnn,CSHnn,CMPzx,DECzx,SMB5	; D0
	DC.L	CLDnn,CMPay,PHXnn,JAMnn,JAMnn,CMPax,DECax,BBS5	; D8
	DC.L	CPXin,SBCix,JAMnn,TIAnn,CPXzp,SBCzp,INCzp,SMB6	; E0
	DC.L	INXnn,SBCin,NOPnn,JAMnn,CPXab,SBCab,INCab,BBS6	; E8
	DC.L	BEQnn,SBCiy,SBCim,TAInn,SETnn,SBCzx,INCzx,SMB7	; F0
	DC.L	SEDnn,SBCay,PLXnn,JAMnn,JAMnn,SBCax,INCax,BBS7	; F8


;   ---------------------------------------------------------------------
	DS.L	20
;   ---------------------------------------------------------------------

	CNOP	0,8

SpriteCoor:	DS.B	(64*8)

	CNOP	0,8

	INCLUDE "CPU.asm"


	INCLUDE	"IO.asm"


	CNOP	0,8
