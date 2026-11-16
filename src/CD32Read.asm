; CD32Read.asm - the CD32 pad reader: FAmiga 1.02's cd32read (Afrotechmods / FAmiga), instruction
; for instruction. Two ways to clock the pad, picked
; per port by D1:
;   D1 bit clear - "CD32 Joypad": pin 6 idles HIGH, each clock pulse goes low, then high again.
;   D1 bit set   - "KTRL CD32+":  pin 6 idles LOW,  each clock pulse goes high, then low again.
; The image clock (pin 6 written from a copy of CIA-A PRA, never EOR on the port), a 35-read
; latch wait and 3-read clock waits (each a CIA access, ~1.4 us on any CPU).
;   in:  D0.b = the ports to read: bit 1 = port 2, bit 0 = port 1 (a port left out is never driven)
;        D1.b = those among them read with the low clock
;   out: D0.l = port 2's answer, D1.l = port 1's: nine bits, 1 = pressed: 0 blue, 1 red, 2 yellow,
;        3 green, 4 right shoulder, 5 left shoulder, 6 play, 7-8 the pad's ID bits (a CD32 pad
;        answers 7 = 0, 8 = 1). 0 for a port not read. All seven at once = a plain joystick.
;   Everything else preserved. Interrupts must not write POTGO while it runs (the OS is off).

	CNOP	0,4
cd32read:
	movem.l	d2-d6,-(sp)
	moveq	#0,d3			; d3 = the CIA-A PRA bits to clock (pin 6 of each port read)
	moveq	#0,d6			; d6 = those among them on the low clock
	move.w	#$ff00,d4		; d4 = POTGO: pin 5 low on each port read
	btst	#1,d0
	beq.s	.no2
	move.b	#$80,d3			; port 2's clock: PRA bit 7
	and.w	#$6fff,d4		; port 2: DATRX = 0 (pin 5 low), OUTRY = 0 (pin 9 an input)
	btst	#1,d1
	beq.s	.no2
	move.b	#$80,d6
.no2:	btst	#0,d0
	beq.s	.no1
	or.b	#$40,d3			; port 1's clock: PRA bit 6
	and.w	#$f6ff,d4		; port 1: DATLX = 0, OUTLY = 0
	btst	#0,d1
	beq.s	.no1
	or.b	#$40,d6
.no1:	moveq	#0,d0
	moveq	#0,d1
	tst.b	d3
	beq	.done			; no port asked: nothing is driven
	move.b	$bfe001,d2		; the port's byte as it is: the image
	or.b	d3,d2			; every clocked pin 6 high ...
	eor.b	d6,d2			; ... and the low clock's back to low
	move.b	d2,$bfe001		; pin 6 at its idle level, then an output, held there
	or.b	d3,$bfe201		; while pin 5 falls (no clock edge)
	move.b	d2,$bfe001		; once more now the pin is an output (UAE takes its first level from it)
	move.w	d4,$dff034		; pin 5 low: the pad latches its buttons
	move.b	d2,d4			; d4 = the image from here on
	move.w	cd32_latch,d2		; the latch wait
	subq.w	#1,d2
.latch:	tst.b	$bfe001
	dbf	d2,.latch
	moveq	#9-1,d2			; nine bits: seven buttons, two ID bits
.bit:	lsr.w	#1,d0
	btst	#6,$dff016		; port 2's pin 9 (DATRY): 1 = released
	beq.s	.lo2
	bset	#8,d0
.lo2:	lsr.w	#1,d1
	btst	#2,$dff016		; port 1's pin 9 (DATLY)
	beq.s	.lo1
	bset	#8,d1
.lo1:	eor.b	d3,d4			; the pulse's first half, written from the image
	move.b	d4,$bfe001
	move.w	cd32_clock,d5
	subq.w	#1,d5
.wlo:	tst.b	$bfe001
	dbf	d5,.wlo
	eor.b	d3,d4			; ... and back to idle: the next bit
	move.b	d4,$bfe001
	move.w	cd32_clock,d5
	subq.w	#1,d5
.whi:	tst.b	$bfe001
	dbf	d5,.whi
	dbf	d2,.bit
	move.w	#$ff00,$dff034		; pin 5 high: plain joystick mode again
	not.b	d3
	and.b	d3,$bfe201		; pin 6 an input again
	not.w	d0			; 1 = pressed
	and.l	#$1ff,d0
	not.w	d1
	and.l	#$1ff,d1
	not.b	d3			; ports not asked for: 0
	btst	#7,d3
	bne.s	.r2
	moveq	#0,d0
.r2:	btst	#6,d3
	bne.s	.done
	moveq	#0,d1
.done:	movem.l	(sp)+,d2-d6
	rts

cd32_latch:	dc.w	35		; CIA reads
cd32_clock:	dc.w	3
	CNOP	0,4
