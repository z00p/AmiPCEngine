; PadCheck - shows the pads in the two joystick ports as AmiPCEngine reads them in a game.
;
; In a game the emulator stops the OS and reads the two joystick ports itself, so a pad the OS
; can use (a USB pad through Poseidon, lowlevel.library's extra ports) does nothing there. This
; tool reads the ports the same way, with the OS still running: the plain joystick read (stick,
; fire 1 on pin 6, fire 2 on pin 9, fire 3 on pin 5) and the CD32 read with the emulator's own
; reader (CD32Read.asm, included below), on the normal clock and the low clock in turn, one read
; a frame (two reads in one frame upset some adapters). From how steadily the pad answers it says
; which Joy-Control setting to use. Workbench or Shell; Return, Ctrl-C or the close gadget quit.
;
;   vasmm68k_mot -devpac -nocase -m68000 -Fhunkexe -nosym -I../../src -o PadCheck PadCheck.asm

_LVODisable	EQU	-120
_LVOEnable	EQU	-126
_LVOForbid	EQU	-132
_LVOPermit	EQU	-138
_LVOFindName	EQU	-276
_LVOFindTask	EQU	-294
_LVOSetSignal	EQU	-306
_LVOGetMsg	EQU	-372
_LVOReplyMsg	EQU	-378
_LVOWaitPort	EQU	-384
_LVOCloseLibrary EQU	-414
_LVOOpenLibrary	EQU	-552
_LVOOpen	EQU	-30
_LVOClose	EQU	-36
_LVORead	EQU	-42
_LVOWrite	EQU	-48
_LVOInput	EQU	-54
_LVOOutput	EQU	-60
_LVODelay	EQU	-198
_LVOSetMode	EQU	-426
_LVOWaitForChar	EQU	-204
_LVOWaitTOF	EQU	-270
pr_MsgPort	EQU	92
pr_CLI		EQU	172
LibList		EQU	378
CSI		EQU	$9B
HIST		EQU	32		; reads of each clock looked at (a read every other frame)
LINEW		EQU	62		; each line of the live part padded to this

; a port's state
p_title		EQU	0		; L: its heading
p_joy		EQU	4		; W: JOYxDAT
p_f1		EQU	6		; B: fire 1 (pin 6)
p_f2		EQU	7		; B: fire 2 (pin 9)
p_f3		EQU	8		; B: fire 3 (pin 5)
p_resN		EQU	10		; W: the last CD32 read on the normal clock (CD32Read: 1 = pressed)
p_resL		EQU	12		; W: ... on the low clock
p_histN		EQU	14		; L: one bit per read, 1 = answered as a CD32 pad
p_histL		EQU	18		; L
p_cntN		EQU	22		; B: reads so far, up to HIST
p_cntL		EQU	23		; B
p_size		EQU	24

	SECTION	code,CODE
start:
	movem.l	d2-d7/a2-a6,-(sp)
	move.l	4.w,a6
	move.l	a6,SysBase
	sub.l	a1,a1
	jsr	_LVOFindTask(a6)
	move.l	d0,a4
	tst.l	pr_CLI(a4)
	bne.s	.cli
	lea	pr_MsgPort(a4),a0	; started from Workbench: its message first
	jsr	_LVOWaitPort(a6)
	lea	pr_MsgPort(a4),a0
	jsr	_LVOGetMsg(a6)
	move.l	d0,WBMsg
.cli:	lea	DosName(pc),a1
	moveq	#33,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,DosBase
	beq	exit
	lea	GfxName(pc),a1
	moveq	#33,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,GfxBase
	beq	exitdos
	move.l	DosBase,a6
	tst.l	WBMsg
	beq.s	.shell
	move.l	#ConName,d1		; Workbench: a window of our own
	move.l	#1006,d2		; MODE_NEWFILE
	jsr	_LVOOpen(a6)
	move.l	d0,OutFH
	beq	exitgfx
	move.l	d0,InFH
	st	OwnCon
	move.l	d0,d1			; raw mode: a key is seen at once, without Return ...
	moveq	#1,d2
	jsr	_LVOSetMode(a6)
	lea	CloseEv(pc),a0		; ... and the close gadget comes in as a key-like report
	bsr	Puts			; (in the usual mode WaitForChar never sees the gadget)
	bra.s	.go
.shell:	jsr	_LVOOutput(a6)
	move.l	d0,OutFH
	beq	exitgfx
	jsr	_LVOInput(a6)
	move.l	d0,InFH
.go:	move.l	SysBase,a6		; Poseidon (a USB stack) loaded?
	jsr	_LVOForbid(a6)
	lea	LibList(a6),a0
	lea	PsdName(pc),a1
	jsr	_LVOFindName(a6)
	move.l	d0,d7
	jsr	_LVOPermit(a6)
	lea	Head(pc),a0
	bsr	Puts
	tst.l	d7
	beq.s	.nopsd
	lea	UsbLine(pc),a0
	bsr	Puts
.nopsd:	move.l	#Port2Title,Port2+p_title
	move.l	#Port1Title,Port1+p_title

loop:	move.l	GfxBase,a6
	jsr	_LVOWaitTOF(a6)
	move.l	SysBase,a6
	jsr	_LVODisable(a6)		; (the OS's mouse and pad reads must not come in between)
	move.w	$dff00c,Port2+p_joy	; the plain read first, a frame after the last CD32 read:
	move.w	$dff00a,Port1+p_joy	; straight after one, a CD32 pad may still hold pin 9 low
	move.b	$bfe001,d2		; CIA-A PRA: fire 1 of port 2 (bit 7), port 1 (bit 6)
	move.w	$dff016,d3		; POTINP (POTGO is $FF00 between CD32 reads)
	moveq	#3,d0			; both ports
	moveq	#0,d1			; the normal clock ...
	tst.b	Phase
	beq.s	.clk
	moveq	#3,d1			; ... or the low clock, every other frame
.clk:	bsr	cd32read		; (keeps D2-D6)
	move.l	d0,d4			; port 2
	move.l	d1,d5			; port 1
	jsr	_LVOEnable(a6)
	btst	#7,d2
	seq	Port2+p_f1
	btst	#6,d2
	seq	Port1+p_f1
	btst	#14,d3
	seq	Port2+p_f2
	btst	#10,d3
	seq	Port1+p_f2
	btst	#12,d3
	seq	Port2+p_f3
	btst	#8,d3
	seq	Port1+p_f3
	lea	Port2,a0
	move.l	d4,d0
	bsr.s	Track
	lea	Port1,a0
	move.l	d5,d0
	bsr.s	Track
	not.b	Phase
	bsr	Draw
	move.l	SysBase,a6		; Ctrl-C?
	moveq	#0,d0
	moveq	#0,d1
	jsr	_LVOSetSignal(a6)
	btst	#12,d0
	bne	quit
	move.l	DosBase,a6		; a key (Return), or the close gadget (end of file)?
	move.l	InFH,d1
	beq	loop
	moveq	#0,d2
	jsr	_LVOWaitForChar(a6)
	tst.l	d0
	beq	loop
	move.l	InFH,d1
	move.l	#KeyBuf,d2
	moveq	#1,d3
	jsr	_LVORead(a6)
	bra	quit

; Track: A0 = a port, D0 = its CD32 read this frame, on the clock Phase says.
Track:	moveq	#0,d1			; d1 = 1: it answered as a CD32 pad (ID bits 7 = 0, 8 = 1)
	move.w	d0,d2
	and.w	#$180,d2
	cmp.w	#$100,d2
	bne.s	.no
	move.w	d0,d2
	and.w	#$7f,d2
	cmp.w	#$7f,d2			; all seven at once: a plain joystick, not an answer
	beq.s	.no
	moveq	#1,d1
.no:	tst.b	Phase
	bne.s	.low
	move.w	d0,p_resN(a0)
	move.l	p_histN(a0),d2
	add.l	d2,d2
	or.l	d1,d2
	move.l	d2,p_histN(a0)
	cmp.b	#HIST,p_cntN(a0)
	bcc.s	.x
	addq.b	#1,p_cntN(a0)
.x:	rts
.low:	move.w	d0,p_resL(a0)
	move.l	p_histL(a0),d2
	add.l	d2,d2
	or.l	d1,d2
	move.l	d2,p_histL(a0)
	cmp.b	#HIST,p_cntL(a0)
	bcc.s	.x
	addq.b	#1,p_cntL(a0)
	rts

; Draw: the live part into Buf, written out only when it changed.
Draw:	lea	Buf,a2
	move.b	#CSI,(a2)+		; the cursor to line 7, column 1
	move.b	#'7',(a2)+
	move.b	#';',(a2)+
	move.b	#'1',(a2)+
	move.b	#'H',(a2)+
	lea	Port2,a4
	bsr	PortText
	bsr	EmptyLine
	lea	Port1,a4
	bsr	PortText
	bsr	EmptyLine
	lea	Foot(pc),a0
	bsr	Line
	bsr	EmptyLine
	lea	Note1(pc),a0		; a second reader of the same pad (another tester, the OS)
	bsr	Line
	lea	Note2(pc),a0
	bsr	Line
	lea	Note3(pc),a0
	bsr	Line
	subq.l	#1,a2			; no line feed after the last line: the window must not scroll
	move.l	a2,d3
	lea	Buf,a0
	sub.l	a0,d3			; the length
	lea	Last,a1
	move.l	d3,d0
	subq.l	#1,d0
.cmp:	cmpm.b	(a0)+,(a1)+
	bne.s	.diff
	subq.l	#1,d0
	bpl.s	.cmp
	rts
.diff:	lea	Buf,a0			; keep it, then write it
	lea	Last,a1
	move.l	d3,d0
	subq.l	#1,d0
.cp:	move.b	(a0)+,(a1)+
	subq.l	#1,d0
	bpl.s	.cp
	move.l	DosBase,a6
	move.l	OutFH,d1
	move.l	#Buf,d2
	jmp	_LVOWrite(a6)

; PortText: A4 = a port; four lines at A2.
PortText:
	move.l	a2,a3
	move.l	p_title(a4),a0
	bsr	Str
	bsr	EndLine
	move.l	a2,a3			; the plain read
	lea	TStick(pc),a0
	bsr	Str
	move.w	p_joy(a4),d0
	move.w	d0,d1
	lsr.w	#1,d1
	eor.w	d0,d1
	lsr.w	#8,d1			; up = bit 9 ^ bit 8
	lea	NUp(pc),a0
	bsr	Flag
	move.w	d0,d1
	lsr.w	#1,d1
	eor.w	d0,d1			; down = bit 1 ^ bit 0
	lea	NDown(pc),a0
	bsr	Flag
	move.w	d0,d1
	lsr.w	#8,d1
	lsr.w	#1,d1			; left = bit 9
	lea	NLeft(pc),a0
	bsr	Flag
	move.w	d0,d1
	lsr.w	#1,d1			; right = bit 1
	lea	NRight(pc),a0
	bsr	Flag
	lea	TFire(pc),a0
	bsr	Str
	move.b	p_f1(a4),d1
	lea	N1(pc),a0
	bsr	Flag
	move.b	p_f2(a4),d1
	lea	N2(pc),a0
	bsr	Flag
	move.b	p_f3(a4),d1
	lea	N3(pc),a0
	bsr	Flag
	bsr	EndLine
	move.l	a2,a3			; the CD32 read, normal clock
	lea	TCd(pc),a0
	bsr	Str
	move.w	p_resN(a4),d0
	move.l	p_histN(a4),d4
	move.b	p_cntN(a4),d5
	bsr	CdText
	bsr	EndLine
	move.l	a2,a3			; ... low clock
	lea	TKl(pc),a0
	bsr	Str
	move.w	p_resL(a4),d0
	move.l	p_histL(a4),d4
	move.b	p_cntL(a4),d5
	bsr	CdText
	bsr	EndLine
	move.l	a2,a3			; the setting to use
	lea	TSet(pc),a0
	bsr	Str
	lea	VCheck(pc),a0
	cmp.b	#HIST,p_cntN(a4)
	bcs.s	.v
	cmp.b	#HIST,p_cntL(a4)
	bcs.s	.v
	lea	VCd(pc),a0
	moveq	#-1,d0
	cmp.l	p_histN(a4),d0
	beq.s	.v
	lea	VKl(pc),a0
	cmp.l	p_histL(a4),d0
	beq.s	.v
	lea	VFlaky(pc),a0
	move.l	p_histN(a4),d0
	or.l	p_histL(a4),d0
	bne.s	.v
	lea	VJoy(pc),a0
.v:	bsr	Str
	bra	EndLine

; CdText: D0 = a CD32 read, D4 its history, D5 the count: the buttons and how it answers.
CdText:	move.l	d4,d1
	and.l	#1,d1
	beq.s	.none			; no answer to the last read: no buttons
	lea	CdNames(pc),a1
	moveq	#7-1,d2
.b:	move.l	a1,a0
	moveq	#0,d1
	btst	#0,d0
	sne	d1
	bsr	Flag
	addq.l	#4,a1
	lsr.w	#1,d0
	dbf	d2,.b
	bra.s	.st
.none:	lea	NoBtn(pc),a0
	bsr	Str
.st:	lea	SCheck(pc),a0
	cmp.b	#HIST,d5
	bcs	Str
	lea	SSteady(pc),a0
	moveq	#-1,d1
	cmp.l	d4,d1
	beq	Str
	lea	SNone(pc),a0
	tst.l	d4
	beq	Str
	lea	SFlaky(pc),a0
	bra	Str

; Flag: D1 bit 0 (or a byte $FF) = on: the name at A0 (three characters) or "-- ", at A2.
Flag:	btst	#0,d1
	bne	Str
	move.l	a0,-(sp)
	lea	Off(pc),a0
	bsr.s	Str
	move.l	(sp)+,a0
	rts
Str:	move.b	(a0)+,d1
	beq.s	.x
	move.b	d1,(a2)+
	bra.s	Str
.x:	rts
EmptyLine:
	move.l	a2,a3
EndLine:			; pad the line from A3 to LINEW, then a line feed
	move.l	a2,d1
	sub.l	a3,d1
.p:	cmp.w	#LINEW,d1
	bcc.s	.lf
	move.b	#' ',(a2)+
	addq.w	#1,d1
	bra.s	.p
.lf:	move.b	#10,(a2)+
	rts
Line:	move.l	a2,a3
	bsr.s	Str
	bra.s	EndLine

; Puts: the string at A0 to the output.
Puts:	move.l	a0,d2
	moveq	#-1,d3
.l:	addq.l	#1,d3
	tst.b	(a0)+
	bne.s	.l
	move.l	DosBase,a6
	move.l	OutFH,d1
	jmp	_LVOWrite(a6)

quit:	lea	Bye(pc),a0		; the cursor back on
	bsr	Puts
	tst.b	OwnCon
	beq.s	exitgfx
	move.l	DosBase,a6
	move.l	OutFH,d1
	jsr	_LVOClose(a6)
exitgfx:
	move.l	SysBase,a6
	move.l	GfxBase,a1
	jsr	_LVOCloseLibrary(a6)
exitdos:
	move.l	SysBase,a6
	move.l	DosBase,a1
	jsr	_LVOCloseLibrary(a6)
exit:	move.l	SysBase,a6
	move.l	WBMsg,d0
	beq.s	.r
	jsr	_LVOForbid(a6)
	move.l	d0,a1
	jsr	_LVOReplyMsg(a6)
.r:	movem.l	(sp)+,d2-d7/a2-a6
	moveq	#0,d0
	rts

NO_LATCH200	EQU	0
	INCLUDE	"CD32Read.asm"

DosName:	DC.B	'dos.library',0
GfxName:	DC.B	'graphics.library',0
PsdName:	DC.B	'poseidon.library',0
ConName:	DC.B	'CON:20/20/540/230/PadCheck/CLOSE',0
		DC.B	'$VER: PadCheck 1.0 (23.11.2026)',0
Head:		DC.B	12,CSI,'0 p'
		DC.B	'PadCheck: the joystick ports as AmiPCEngine reads them',10
		DC.B	'In a game the OS is stopped and only pads in the two',10
		DC.B	'joystick ports are read; USB pads and the OS',39,'s own pad',10
		DC.B	'settings do nothing there.',10,0
UsbLine:	DC.B	'Poseidon (USB) is running: its pads are not seen in play.',0
Bye:		DC.B	CSI,' p',10,0
CloseEv:	DC.B	CSI,'11{',0
Port2Title:	DC.B	'Port 2 (the joystick port)',0
Port1Title:	DC.B	'Port 1 (the mouse port: a mouse shows as stick and fires)',0
TStick:		DC.B	'  Stick ',0
TFire:		DC.B	' Fire ',0
TCd:		DC.B	'  CD32 read         ',0
TKl:		DC.B	'  CD32 read, KTRL+  ',0
TSet:		DC.B	'  Joy-Control: ',0
NUp:		DC.B	'Up ',0
NDown:		DC.B	'Dn ',0
NLeft:		DC.B	'Lt ',0
NRight:		DC.B	'Rt ',0
N1:		DC.B	'1  ',0
N2:		DC.B	'2  ',0
N3:		DC.B	'3  ',0
Off:		DC.B	'-- ',0
CdNames:	DC.B	'Bl ',0,'Rd ',0,'Ye ',0,'Gr ',0,'RS ',0,'LS ',0,'Pl ',0
NoBtn:		DC.B	'                     ',0
SCheck:		DC.B	' checking',0
SSteady:	DC.B	' steady',0
SNone:		DC.B	' no answer',0
SFlaky:		DC.B	' unsteady',0
VCheck:		DC.B	'checking...',0
VCd:		DC.B	'CD32 pad',0
VKl:		DC.B	'CD32 (KTRL+)',0
VFlaky:		DC.B	'CD32 pad, unsteady: close other pad testers',0
VJoy:		DC.B	'Joystick',0
Foot:		DC.B	'Hold each button in turn. Return or the close gadget quits.',0
Note1:		DC.B	'Close other pad testers first: two reads of a CD32 pad in',0
Note2:		DC.B	'one frame upset it. OS-based testers can also show this pad',0
Note3:		DC.B	'a second time, as a third or fourth port, like a USB pad.',0
	EVEN

	SECTION	vars,BSS
SysBase:	DS.L	1
DosBase:	DS.L	1
GfxBase:	DS.L	1
WBMsg:		DS.L	1
OutFH:		DS.L	1
InFH:		DS.L	1
Port2:		DS.B	p_size
Port1:		DS.B	p_size
OwnCon:		DS.B	1
Phase:		DS.B	1
KeyBuf:		DS.B	4
Buf:		DS.B	2048
Last:		DS.B	2048
