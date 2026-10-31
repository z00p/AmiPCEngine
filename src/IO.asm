




;	-=-=-=-=-=-=-=-=-=-=-=-		; Inicializa Sistema de Paginación
IO_Init;
	LEA	Regs,A3


; -=-=-=-=-=-=-=-=-=-=-=> Cargamos MemoryMapper apuntando a la memoria del Amiga
; Iniciamos MemoryMapper apuntando a memoria "vacia"
	LEA	DirMappers,A1
	MOVE.W	#($100)-1,D0
InitMapBuc:
	MOVE.L	#LROM,(A1)+
	MOVE.L	#EROM,(A1)+
	DBF	D0,InitMapBuc

; Colocamos punteros de la RAM en MemoryMapper
	MOVE.L	#SRAM,DirMappers+($F7*8)
	MOVE.L	#SRAM,DirMappers+($F7*8)+4

	MOVE.L	#IRAM,DirMappers+($F8*8)
	MOVE.L	#IRAM,DirMappers+($F8*8)+4

	MOVE.L	#IRAM,DirMappers+($F9*8)
	MOVE.L	#IRAM,DirMappers+($F9*8)+4

	MOVE.L	#IRAM,DirMappers+($FA*8)
	MOVE.L	#IRAM,DirMappers+($FA*8)+4

	MOVE.L	#IRAM,DirMappers+($FB*8)
	MOVE.L	#IRAM,DirMappers+($FB*8)+4

	MOVE.L	#IOAM,DirMappers+($FF*8)
	MOVE.L	#IOAM,DirMappers+($FF*8)+4
; -=-=-=-=-=-=-=-=-=-=-=<

	MOVE.L	#$ff000000,TabMap+0(A3)
	MOVE.L	#$00000000,TabMap+4(A3)

; -=-=-=-=-=-=-=-=-=-=-=> Cargamos MemoryPages segun la paginacion actual
	MOVEQ	#8-1,D1
MemPagBuc:
	MOVEQ	#0,D7
	MOVE.B	TabMap(A3,D1.W),D7
	BSR	SetMapper
	DBF	D1,MemPagBuc
; -=-=-=-=-=-=-=-=-=-=-=<

;	-=-=-=-=-=-=-=-=-=-=-=-
	BSR	CreaTabPag
;	-=-=-=-=-=-=-=-=-=-=-=-		; Inicializa Mascaras de ROM y RAM.


;	-=-=-=-=-=-=-=-=-=-=-=-		; Borra Todas las RAMs.
	LEA	IOAM,A0
	MOVEQ.L	#$FFFFFFFF,D1
	MOVE.W	#((8*1024)/4)-1,D0
IOAM_Buc:
	MOVE.L	D1,(A0)+
	DBF	D0,IOAM_Buc

	LEA	IRAM,A0
	MOVE.W	#((8*1024)/4)-1,D0
	BSR	BorraMem

	LEA	SRAM,A0
	MOVE.W	#((8*1024)/4)-1,D0
	BSR	BorraMem
	IFEQ	NO_BRAMFMT
	MOVE.L	#$4855424D,SRAM		; 'HUBM': backup RAM formatted, as Mesen's new
	MOVE.L	#$00A01080,SRAM+4	; 8 KB BRAM (end $A000, first free $8010)
	ENDC

	LEA	VRAM,A0
	MOVE.W	#((32*1024)/4)-1,D0
	BSR	BorraMem
;	-=-=-=-=-=-=-=-=-=-=-=-

	RTS

; -------------------------------------------------------------------

;	A0.L : Cardtridge Address
;	D0.W : Number of pages (Cardtridge Size = D0 x 8Kb blocks)
IO_SetCardtridge:
	MOVE.L	A0,MapROMBase(A3)

; Colocamos punteros al Cartucho ROM en MemoryMapper
	MOVE.L	MapROMBase(A3),A0
	LEA	DirMappers,A1
	SUBQ.W	#1,D0
CreaMapBuc:
	MOVE.L	A0,(A1)
	ADD.W	#$2000,A0
	ADDQ.W	#8,A1
	DBF	D0,CreaMapBuc

; -=-=-=-=-=-=-=-=-=-=-=> Cargamos MemoryPages segun la paginacion actual
	MOVEQ	#8-1,D1
MemPagBuc2:
	MOVEQ	#0,D7
	MOVE.B	TabMap(A3,D1.W),D7
	BSR	SetMapper
	DBF	D1,MemPagBuc2
; -=-=-=-=-=-=-=-=-=-=-=<

	RTS

; -------------------------------------------------------------------

;	D1.w : Page number (0-7)
;	D7.w : Mapper to be used
;	D0.l = Trash!
SetMapper:
	MOVE.B	D7,TabMap(A3,D1.W)

	IFEQ	NO_MAPSHIFT
	MOVEQ	#0,D0			; D1 = page 0-7: D0 = D1*$2000 as MULU gave it
	MOVE.W	D1,D0
	ROR.W	#3,D0
	ELSE
	MOVE.L	D1,D0
	MULU	#$2000,D0
	ENDC

	MOVE.L	(DirMappers+4.W,PC,D7.W*8),PagWrite(A3,D1.W*4)
	SUB.L	D0,PagWrite(A3,D1.W*4)

	MOVE.L	(DirMappers.W,PC,D7.W*8),PagRead(A3,D1.W*4)
	SUB.L	D0,PagRead(A3,D1.W*4)

	MOVE.W	(DirMappers+2.W,PC,D7.W*8),Restas(A3,D1.W*8)
	SUB.W	D0,Restas(A3,D1.W*8)
	RTS



;	D1.w : Page number (0-7)
;	D7.b = Mapper currently used
GetMapper:
	MOVE.B	TabMap(A3,D1.W),D7
	RTS


; ------------------------------------> Crea Tablas de Paginación.
	CNOP	0,4
CreaTabPag:
	LEA	PagRead(A3),A0
	LEA	Restas(A3),A1
	LEA	Desbor(A1),A2	; (CUIDADO: Según Puntero "Restas")
	MOVEQ	#0,D1
	MOVEQ	#(8-1),D0
CreaTabPagBuc:
	MOVE.L	(A0)+,D2	; Punteros de Restas.
	MOVE.W	D2,(A1)+
	ADDQ	#$6,A1

;;;	MOVE.L	(A0)+,D2	; Punteros de Desbordamiento.
	ADD.L	D1,D2
	ADDQ.L	#$1,D2
	MOVE.L	D2,(A2)+
	ADD.L	#$1FFF,D2
	MOVE.L	D2,(A2)+

	ADD.L	#$2000,D1
	DBF	D0,CreaTabPagBuc
	RTS
; ------------------------------------<


; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


; -------------------------------------------------------------------

	CNOP	0,8
ReadIO:
	MOVE.L	A4,D0
	SUB.L	#IOAM,D0
	BCS.S	ReadIO_RET
ReadIOtia:
	CMP.W	#$0400,D0
	BCS.S	readIO_0000_03FF

	CMP.W	#$0800,D0
	BCS	readIO_0400_07FF

	CMP.W	#$0C00,D0
	BCS	readIO_0800_0BFF

	CMP.W	#$1000,D0
	BCS	readIO_0C00_0FFF

	CMP.W	#$1400,D0
	BCS	readIO_1000_13FF

	CMP.W	#$1800,D0
	BCS	readIO_1400_17FF

	CMP.W	#$2000,D0
	BCS	readIO_1800_1FFF
ReadIO_RET:
	RTS

; -------------------------------------------------------------------

IRQ1_INT:	EQU $02
IRQ2_INT:	EQU $01

STATUS_RESET_ALL_INT_REQUEST:	EQU $C0
STATUS_VBLANK_INT:		EQU $20
STATUS_RASTER_INT:		EQU $04

;STATUS_BUSY = 0x40;
;STATUS_VRAM2VRAMDMACOMPLETIONINT = 0x10;
;STATUS_VRAM2SATDMACOMPLETTIONINT = 0x08;
;STATUS_SPRITEOVERFLOWINT = 0x02;
;STATUS_SPRITECOLLISIONINT = 0x01;

readIO_0000_03FF:
	AND.W	#$0003,D0
	BEQ.S	read_0000

	BTST	#1,D0
	BNE.S	read_0002_3

	MOVE.B	#$FF,(A4)
	RTS

read_0000:
	MOVE.B	Status(A3),(A4)
	AND.B	#$7F,(A4)
	AND.B	#STATUS_RESET_ALL_INT_REQUEST,Status(A3)
	BCLR	#1,IRQ_Pending(A3)
	RTS

read_0002_3:
;	ADD.B	#$35,(A4)
;	BCLR	#5,(A4)

	MOVEQ	#0,D1
	MOVE.B	VDP_Index(A3),D1
	AND.W	#$001F,D1

	CMP.W	#2,D1
	BEQ.s	readVDP_02
	
	LSL.W	#1,D1
	AND.W	#$0001,D0
	BCHG	#0,D0
	OR.W	D0,D1
	MOVE.B	(VDP_Regs.L,D1.W),(A4)
	RTS

readVDP_02:
	MOVE.W	VDP_Regs+(1*2),D1
	AND.L	#$7FFF,D1

	LSL.L	#1,D1
	AND.W	#$0001,D0
	BCHG	#0,D0
	OR.W	D0,D1
	MOVE.B	(VRAM,D1.L),(A4)

	BTST	#0,D0
	BNE.S	readVDP_02_RET		; it should be BEQ, but it is BNE due the previous BCHG #0,D0

	MOVE.B	(VDP_Regs+(5*2)),D0
	LSR.B	#3,D0
	AND.W	#$0003,D0

	MOVE.W	VDP_Regs+(1*2),D1
	AND.W	#$7FFF,D1
	ADD.W	(VDP_Sumas.W,PC,D0.W*2),D1
	AND.W	#$7FFF,D1
	MOVE.W	D1,VDP_Regs+(1*2)
readVDP_02_RET:
	RTS

; -------------------------------------------------------------------

readIO_0400_07FF:
	AND.W	#$0007,D0
	CMP.W	#$0004,D0
	BEQ.S	readIO_0404
	CMP.W	#$0005,D0
	BEQ.S	readIO_0405
	RTS
readIO_0404:
	MOVE.W	PAL_Index(A3),D1
	AND.W	#$01FF,D1
	MOVE.B	(VDP_Pal+1.L,D1.W*2),(A4)
	RTS
readIO_0405:
	MOVE.W	PAL_Index(A3),D1
	AND.W	#$01FF,D1
	MOVE.B	(VDP_Pal+0.L,D1.W*2),(A4)
	ADDQ.W	#1,D1
	MOVE.W	D1,PAL_Index(A3)
	RTS
; -------------------------------------------------------------------

readIO_0800_0BFF:
	RTS

; -------------------------------------------------------------------

readIO_0C00_0FFF:
	IFEQ	NO_TIMER
	MOVE.B	TimerCount,(A4)	; timer counter (7 bits)
	ENDC
	RTS

; -------------------------------------------------------------------

readIO_1000_13FF:
	MOVE.B	JoyX(A3),D1
	BTST	#0,IOAM+$1000
	BNE.S	KeyLow
	LSR.B	#4,D1
KeyLow:
	NOT.B	D1
	AND.B	#$0F,D1
	MOVE.B	D1,(A4)
	RTS

; -------------------------------------------------------------------

readIO_1400_17FF:
	IFEQ	NO_TIMER
	AND.W	#$0003,D0
	CMP.W	#$0003,D0
	BNE.S	.notStatus
	MOVE.B	IRQ_Pending(A3),D1	; $1403: bit2 timer, bit1 IRQ1, bit0 IRQ2 pending
	AND.B	#$07,D1
	MOVE.B	D1,(A4)
.notStatus:
	ENDC
	RTS

; -------------------------------------------------------------------

readIO_1800_1FFF:
	RTS

; -------------------------------------------------------------------


; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


; -------------------------------------------------------------------

WriteIO:
	MOVE.L	A4,D0
	SUB.L	#IOAM,D0
	BCS.S	WriteIO_RET


	CMP.W	#$0400,D0
	BCS.S	writeIO_0000_03FF

	CMP.W	#$0800,D0
	BCS	writeIO_0400_07FF

;	CMP.W	#$0002,D0
;	BEQ	Escr0002
;	CMP.W	#$0003,D0
;	BEQ	Escr0003

;	CMP.W	#$0404,D0
;	BEQ	Escr0404
;	CMP.W	#$0405,D0
;	BEQ	Escr0405

	IFEQ	NO_TIMER
	CMP.W	#$0C00,D0
	BCS.S	.notTimerIrq
	CMP.W	#$1000,D0
	BCS	writeTimer
	CMP.W	#$1400,D0
	BCS.S	.notTimerIrq
	CMP.W	#$1800,D0
	BCS	writeIrqPort
.notTimerIrq:
	ENDC
	IFEQ	NO_PSGWAVE
	CMP.W	#$0C00,D0		; D0 >= $0800 here
	BCC.S	WriteIO_RET
	JMP	PSGWrite
	ELSE
	CMP.W	#$0802,D0
	BEQ	Escr080x
	CMP.W	#$0803,D0
	BEQ	Escr080x
	CMP.W	#$0804,D0
	BEQ	Escr080x
	CMP.W	#$0806,D0
	BEQ	Escr0806
	ENDC
WriteIO_RET:
	RTS

; -------------------------------------------------------------------

writeIO_0000_03FF:
	AND.W	#$0003,D0
	BEQ.S	writeIO_0000

	BTST	#1,D0
	BEQ.S	WriteIO_RET

	AND.W	#$0001,D0
	MOVEQ	#0,D1
	MOVE.B	VDP_Index(A3),D1
	AND.W	#$001F,D1
	LSL.W	#1,D1
	BCHG	#0,D0
	OR.W	D0,D1
	MOVE.B	(A4),(VDP_Regs.L,D1.W)
	BCHG	#0,D0

	MOVE.B	VDP_Index(A3),D1
	AND.W	#$001F,D1
	IFEQ	NO_RTG
	CMP.W	#$0005,D1
	BNE.S	.noCR
	JSR	RtgCRLog		; RTG: control register writes per line
.noCR:
	ENDC
	CMP.W	#$0002,D1
	BEQ.S	writeVDP_02
	CMP.W	#$0007,D1
	BEQ.S	writeVDP_07
	CMP.W	#$0008,D1
	BEQ.S	writeVDP_08
	RTS

writeIO_0000:
	MOVE.B	(A4),D0
	AND.B	#$1F,D0
	MOVE.B	D0,VDP_Index(A3)
	RTS

writeVDP_02:
	TST.W	D0
	BEQ.S	WriteIO_RET

	MOVE.W	VDP_Regs,D1
	AND.W	#$7FFF,D1

	MOVE.W	VDP_Regs+(2*2),D0
;	ROR.W	#8,D0
	MOVE.W	D0,(VRAM,D1.W*2)

	MOVE.W	D1,D0
	LSR.W	#4,D0
	ST	(TabRedef,D0.W)

	MOVE.B	(VDP_Regs+(5*2)),D0
	LSR.B	#3,D0
	AND.W	#$0003,D0

	ADD.W	(VDP_Sumas.W,PC,D0.W*2),D1

	MOVE.W	D1,VDP_Regs
	RTS


writeVDP_07:
	IFNE	NO_SCRLO
	TST.W	D0
	BEQ	WriteIO_RET
	ENDC

	bsr	logScrollXY

	RTS


writeVDP_08:
	IFNE	NO_SCRLO
	TST.W	D0
	BEQ	WriteIO_RET
	ENDC

	bsr	logScrollXY

	RTS


logScrollXY:
	IFEQ	NO_SCRLO
; Either byte of R7/R8 counts (HuZERO writes only BXR's low byte, every line).
; D1.W = 7: a BXR write; the entry's BYR is set so the BG row runs on from the
; entry before (only a BYR write reloads the row counter). Else BXR and BYR as
; they are (R8 write, frame start).
	movem.l	d0/d2/a0,-(sp)
	move.l	ScrollChangesIndex(A3),a0
	move.w	ScanLine(A3),d0
	bne.s	.sl1
	cmp.l	ScrollChangesNow(A3),a0	; line 0: first entry of the frame?
	beq.s	.full
	bra.s	.upd			; no: entries on line 0 replace each other
.sl1:	cmp.w	#(224),d0
	IFEQ	NO_RTG|NO_RTGFIX
	bcc.s	.late
.inPic:
	ELSE
	bcc.s	.skip
	ENDC
	addq.w	#1,d0
	cmp.w	-6(a0),d0
	beq.s	.upd
	cmp.w	#7,d1
	bne.s	.full
	move.w	-6(a0),d2		; BXR only: row = B0 + y - L0 (+1 if L0 > 0)
	bne.s	.bx1			; = B' + 1 + y - L  ->  B' = B0 + L - max(L0,1)
	moveq	#1,d2
.bx1:	neg.w	d2
	add.w	d0,d2
	add.w	-2(a0),d2
	move.w	d0,(a0)+
	move.w	VDP_Regs+(7*2),(a0)+
	move.w	d2,(a0)+
	bra.s	.done
.full:	move.w	d0,(a0)+
	move.l	VDP_Regs+(7*2),(a0)+	; regs 7 + 8
.done:	move.l	a0,ScrollChangesIndex(A3)
	move.w	#-1,(a0)
.skip:	movem.l	(sp)+,d0/d2/a0
	rts
.upd:	cmp.w	#7,d1
	bne.s	.updf
	move.w	VDP_Regs+(7*2),-4(a0)	; BXR only: the entry's row stays
	bra.s	.skip
.updf:	move.l	VDP_Regs+(7*2),-4(a0)
	bra.s	.skip
	IFEQ	NO_RTG|NO_RTGFIX
.late:	tst.b	RtgOn			; RTG shows 240 lines: keep changes up to line 239
	beq.s	.skip
	cmp.w	#(240),d0
	bcs.s	.inPic
	bra.s	.skip
	ENDC
	ELSE

	movem.l	d0/a0,-(sp)

	move.l	ScrollChangesIndex(A3),a0

	move.w	ScanLine(A3),d0
	beq.s	.insertScrollChange

	cmp.w	#(224),d0
	IFEQ	NO_RTG|NO_RTGFIX
	bcc.s	.late
.inPic:
	ELSE
	bcc.s	.skipScrollChange
	ENDC

	addq.w	#1,d0

	cmp.w	-6(a0),d0
	beq.s	.updateScrollChange

.insertScrollChange:
	move.w	d0,(a0)+
.update:
	move.l	VDP_Regs+(7*2),(a0)+	; store regs 7 + 8

	move.l	a0,ScrollChangesIndex(A3)

	move.w	#-1,(a0)
.skipScrollChange:
	movem.l	(sp)+,d0/a0
	rts

.updateScrollChange:
	move.l	VDP_Regs+(7*2),-4(a0)	; store regs 7 + 8
	bra.s	.skipScrollChange
	IFEQ	NO_RTG|NO_RTGFIX
.late:	tst.b	RtgOn			; RTG shows 240 lines: keep changes up to line 239
	beq.s	.skipScrollChange	; (AGA: its copper list covers 224)
	cmp.w	#(240),d0
	bcs.s	.inPic
	bra.s	.skipScrollChange
	ENDC
	ENDC	; NO_SCRLO





; -------------------------------------------------------------------

writeIO_0400_07FF:
	AND.W	#$0007,D0
	CMP.W	#$0002,D0
	BEQ.S	writeIO_0402
	CMP.W	#$0003,D0
	BEQ.S	writeIO_0403
	CMP.W	#$0004,D0
	BEQ.S	writeIO_0404
	CMP.W	#$0005,D0
	BEQ.S	writeIO_0405
	RTS
writeIO_0402:
	MOVE.B	(A4),PAL_Index+1(A3)
	RTS
writeIO_0403:
	MOVE.B	(A4),PAL_Index+0(A3)
	RTS
writeIO_0404:
	MOVE.B	(A4),PAL_Data+1(A3)
	RTS
writeIO_0405:
	MOVE.B	(A4),PAL_Data+0(A3)

	MOVE.W	PAL_Index(A3),D1
	AND.W	#$01FF,D1
	IFEQ	NO_RTG|NO_RTGPAL
	TST.B	RtgOn			; RTG: colour writes per line (mid-frame palette)
	BEQ.S	.npl
	JSR	RtgPalLog
.npl:
	ENDC
	MOVE.W	PAL_Data(A3),(VDP_Pal.L,D1.W*2)
	ADDQ.W	#1,D1
	MOVE.W	D1,PAL_Index(A3)
	RTS

; -------------------------------------------------------------------

writeIO_0800_0BFF:
	RTS

; -------------------------------------------------------------------

writeIO_0C00_0FFF:
	RTS

; -------------------------------------------------------------------

writeIO_1000_13FF:
	RTS

; -------------------------------------------------------------------

writeIO_1400_17FF:
	RTS

; -------------------------------------------------------------------

writeIO_1800_1FFF:
	RTS

; -------------------------------------------------------------------





Escr080x:
	MOVE.B	IOAM+$800,D1
	AND.W	#$0007,D1
	LSL.W	#3,D1
	AND.W	#$0007,D0
	ADD.B	D0,D1
	MOVE.B	(A4),(PSGBuffer,D1.W)
	RTS

Escr0806:
	RTS

	MOVE.B	IOAM+$800,D1
	AND.W	#$0007,D1
	MOVE.W	(PSGWaveCnt.L,D1.W*2),D0
	ADDQ.B	#1,D0
	AND.W	#$001F,D0
	MOVE.W	D0,(PSGWaveCnt.L,D1.W*2)

	LSL.W	#5,D1
	ADD.W	D0,D1
	MOVE.B	(A4),D2
	LSL.B	#3,D2
;juan;	MOVE.B	D2,(Onda0.L,D1.W)
	RTS

; -------------------------------------------------------------------
; HuC6280 timer (not in Juan's alpha; NO_TIMER=1 removes it).
; $0C00 write: reload value (7 bits). $0C01 write bit0: start/stop.
; Reads of $0C00-$0FFF give the counter. The counter steps every 1024
; CPU cycles at 7.16 MHz; a line is 455 such cycles. On underflow it
; reloads and sets the timer interrupt (bit 2), which stays pending
; until a write to $1403.
	IFEQ	NO_TIMER
writeTimer:
	BTST	#0,D0
	BNE.S	.control
	MOVE.B	(A4),D1
	AND.B	#$7F,D1
	MOVE.B	D1,TimerReload
	RTS
.control:
	BTST	#0,(A4)
	BEQ.S	.stop
	TST.B	TimerOn
	BNE.S	.done
	ST	TimerOn
	MOVE.B	TimerReload,TimerCount
	CLR.W	TimerAcc
	RTS
.stop:
	SF	TimerOn
.done:
	RTS

writeIrqPort:
	AND.W	#$0003,D0
	CMP.W	#$0003,D0		; $1403 write: acknowledge the timer interrupt
	BNE.S	.done
	BCLR	#2,IRQ_Pending(A3)
.done:
	RTS

; Called once per emulated line (PCE_Start). Uses D0/D1 only.
TimerLine:
	TST.B	TimerOn
	BEQ.S	.done
	MOVE.W	TimerAcc,D0
	ADD.W	#455,D0
	CMP.W	#1024,D0
	BCS.S	.store
	SUB.W	#1024,D0
	SUBQ.B	#1,TimerCount
	BPL.S	.store
	MOVE.B	TimerReload,TimerCount
	OR.B	#$04,IRQ_Pending(A3)
	IFEQ	DdaTickOff
	ADDQ.W	#1,TimerTicks		; DDA capture: samples by timer tick (PSG.asm)
	ENDC
.store:
	MOVE.W	D0,TimerAcc
.done:
	RTS

TimerReload:	DC.B	0
TimerCount:	DC.B	0
TimerOn:	DC.B	0
	EVEN
TimerAcc:	DC.W	0
	IFEQ	DdaTickOff
TimerTicks:	DC.W	0
	ENDC
IntVector:	DC.W	$FFF8
	ENDC

PSGWaveCnt:	DS.W	8
PSGBuffer:	DS.B	8*8


Escr0002:
	MOVEQ	#0,D1
	MOVE.B	VDP_Index(A3),D1
	MOVE.B	(A4),(VDP_Regs+1.L,D1.W*2)

	CMP.B	#2,D1
	BEQ.S	EscribeVRAM2

	RTS

Escr0003:
	MOVEQ	#0,D1
	MOVE.B	VDP_Index(A3),D1
	MOVE.B	(A4),(VDP_Regs.L,D1.W*2)

	CMP.B	#2,D1
	BEQ.S	EscribeVRAM3

	RTS

EscribeVRAM2:
	MOVE.W	VDP_Regs,D1
	AND.W	#$7FFF,D1
	MOVE.B	(A4),(VRAM+1,D1.W*2)

	LSR.W	#4,D1
	ST	(TabRedef,D1.W)

	RTS

EscribeVRAM3:
	MOVE.W	VDP_Regs,D1
	AND.W	#$7FFF,D1
	MOVE.B	(A4),(VRAM,D1.W*2)

	MOVE.W	D1,D0
	LSR.W	#4,D0
	ST	(TabRedef,D0.W)

	MOVE.B	(VDP_Regs+(5*2)),D0
	LSR.B	#3,D0
	AND.W	#$0003,D0

	ADD.W	(VDP_Sumas.W,PC,D0.W*2),D1

	MOVE.W	D1,VDP_Regs
	RTS

VDP_Sumas:DC.W	1,32,64,128


Escr0404:
	MOVEQ	#0,D1
	MOVE.W	IOAM+$402,D1
	ROR.W	#8,D1
	AND.W	#$01FF,D1
	MOVE.B	(A4),(VDP_Pal+0.L,D1.W*2)
	RTS

Escr0405:
	MOVEQ	#0,D1
	MOVE.W	IOAM+$402,D1
	ROR.W	#8,D1
	AND.W	#$01FF,D1
	MOVE.B	(A4),(VDP_Pal+1.L,D1.W*2)
	ADDQ.W	#1,D1
	ROR.W	#8,D1
	MOVE.W	D1,IOAM+$402
	RTS


	CNOP	0,8
VDP_Regs:	DS.W	256

	CNOP	0,8
VDP_Pal:	DS.W	512


; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


; -------------------------------------------------------------------

	CNOP	0,8
DirMappers:	DS.L	256*2	; 00-FF

IOAM:	DS.B	8*1024
IRAM:	DS.B	8*1024
SRAM:	DS.B	8*1024

EROM:	DS.B	8*1024
LROM:	DS.B	8*1024

VRAM:	DS.B	64*1024		; - VRAM

;CRAM:	DS.B	8*1024		; - VRAM
;DRAM:	DS.B	8*1024		; - VRAM
;ERAM:	DS.B	8*1024		; - VRAM

		CNOP	0,8
TabRedef:	DS.B	2048	; 64Kb = 2048 Tiles GFX (32 bytes each tile)


	CNOP	0,8

; -------------------------------------------------------------------
; -------------------------------------------------------------------
