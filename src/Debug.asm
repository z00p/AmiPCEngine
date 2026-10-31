

	IFND	UseDebug	; default, or set with -DUseDebug=x
UseDebug=1
	ENDC

	IFNE	UseDebug	; the whole debugger (see NO_NODEBUG in Main.asm)




Debug_Init:
	lea	opCodesTxt,A0
	lea	opCodesAdr,A1
	move.w	#256-1,D0
.loopA:
	move.l	A0,(A1)+
.loopB:
	tst.b	(A0)+
	bne.s	.loopB

	dbf	D0,.loopA
	rts




Debug_CheckTrace:

	tst.b	traceMode
	bne.s	.waitNextTrace
	rts

.waitNextTrace:
	tst.b	traceStep
	bne.s	.doTrace

	tst.b	SalirMenu(A3)
	bne.s	.exit

	tst.b	traceMode
	bne.s	.waitNextTrace

	rts
.exit:
	subq.l	#1,A5
	rts


.doTrace:
	sf	traceStep

	move.l	D0,-(sp)


	MOVE.L	A5,D0
	subq.l	#1,D0
	SUB.W	(A2),D0
	LogHexWord D0
	LogSpace

	LogString "A:"
	LogHexByte D7
	LogSpace
	LogString "X:"
	LogHexByte D4
	LogSpace
	LogString "Y:"
	LogHexByte D5
	LogSpace
	LogString "::"
	LogSpace
	move.l	(opCodesAdr-$400.L,D2.w*4),D0
	LogText D0
	LogSpace
	LogHexByte (a5)
	LogSpace
	LogHexByte 1(a5)
	LogEnter

	move.l	(sp)+,d0
	rts




Debug_OnKeyPressed:

	cmp.b	#$21,D0		; S
	bne.s	.skipS
	st	oneStep
	sf	traceMode
	sf	traceStep
	sf	isPaused
.skipS:

	cmp.b	#$14,D0		; T
	bne.s	.skip
	st	traceMode
	st	traceStep

	tst.b	isPaused
	beq.s	.skip
	sf	isPaused
.skip:

	rts


Debug_OnKeyReleased:

	cmp.b	#$19,D0		; P
	bne.s	.skipP

	tst.b	traceMode
	bne.s	.exitTrace
	not.b	isPaused
	bra.s	.skipP
.exitTrace:
	sf	traceMode
	sf	traceStep
	sf	isPaused
.skipP:

	rts



	cnop	0,8

isPaused:	dc.b	0
oneStep:	dc.b	0
traceMode:	dc.b	0
traceStep:	dc.b	0




	cnop	0,8
opCodesAdr:	ds.l	256

opCodesTxt:
	dc.b	"BRK",0		; 0x00
	dc.b	"ORA IDX",0	; 0x01
	dc.b	"SXY",0		; 0x02
	dc.b	"ST0",0		; 0x03
	dc.b	"TSB ZPG",0	; 0x04
	dc.b	"ORA ZPG",0	; 0x05
	dc.b	"ASL ZPG",0	; 0x06
	dc.b	"RMB0",0	; 0x07
	dc.b	"PHP",0		; 0x08
	dc.b	"ORA IMM",0	; 0x09
	dc.b	"ASL A",0	; 0x0A
	dc.b	"xxx 0B",0	; 0x0B
	dc.b	"TSB ABS",0	; 0x0C
	dc.b	"ORA ABS",0	; 0x0D
	dc.b	"ASL ABS",0	; 0x0E
	dc.b	"BBR0",0	; 0x0F
	dc.b	"BPL",0		; 0x10
	dc.b	"ORA IDY",0	; 0x11
	dc.b	"ORA ZPI",0	; 0x12
	dc.b	"ST1",0		; 0x13
	dc.b	"TRB ZPG",0	; 0x14
	dc.b	"ORA ZPX",0	; 0x15
	dc.b	"ASL ZPX",0	; 0x16
	dc.b	"RMB1",0	; 0x17
	dc.b	"CLC",0		; 0x18
	dc.b	"ORA ABY",0	; 0x19
	dc.b	"INC A",0	; 0x1A
	dc.b	"xxx 1B",0	; 0x1B
	dc.b	"TRB ABS",0	; 0x1C
	dc.b	"ORA ABX",0	; 0x1D
	dc.b	"ASL ABX",0	; 0x1E
	dc.b	"BBR1",0	; 0x1F
	dc.b	"JSR",0		; 0x20
	dc.b	"AND IDX",0	; 0x21
	dc.b	"SAX",0		; 0x22
	dc.b	"ST2",0		; 0x23
	dc.b	"BIT ZPG",0	; 0x24
	dc.b	"AND ZPG",0	; 0x25
	dc.b	"ROL ZPG",0	; 0x26
	dc.b	"RMB2",0	; 0x27
	dc.b	"PLP",0		; 0x28
	dc.b	"AND IMM",0	; 0x29
	dc.b	"ROL A",0	; 0x2A
	dc.b	"xxx 2B",0	; 0x2B
	dc.b	"BIT ABS",0	; 0x2C
	dc.b	"AND ABS",0	; 0x2D
	dc.b	"ROL ABS",0	; 0x2E
	dc.b	"BBR2",0	; 0x2F
	dc.b	"BMI",0		; 0x30
	dc.b	"AND IDY",0	; 0x31
	dc.b	"AND ZPI",0	; 0x32
	dc.b	"xxx 33",0	; 0x33
	dc.b	"BIT ZPX",0	; 0x34
	dc.b	"AND ZPX",0	; 0x35
	dc.b	"ROL ZPX",0	; 0x36
	dc.b	"RMB3",0	; 0x37
	dc.b	"SEC",0		; 0x38
	dc.b	"AND ABY",0	; 0x39
	dc.b	"DEC A",0	; 0x3A
	dc.b	"xxx 3B",0	; 0x3B
	dc.b	"BIT ABX",0	; 0x3C
	dc.b	"AND ABX",0	; 0x3D
	dc.b	"ROL ABX",0	; 0x3E
	dc.b	"BBR3",0	; 0x3F
	dc.b	"RTI",0		; 0x40
	dc.b	"EOR IDX",0	; 0x41
	dc.b	"SAY",0		; 0x42
	dc.b	"TMA",0		; 0x43
	dc.b	"BSR",0		; 0x44
	dc.b	"EOR ZPG",0	; 0x45
	dc.b	"LSR ZPG",0	; 0x46
	dc.b	"RMB4",0	; 0x47
	dc.b	"PHA",0		; 0x48
	dc.b	"EOR IMM",0	; 0x49
	dc.b	"LSR A",0	; 0x4A
	dc.b	"xxx 4B",0	; 0x4B
	dc.b	"JMP ABS",0	; 0x4C
	dc.b	"EOR ABS",0	; 0x4D
	dc.b	"LSR ABS",0	; 0x4E
	dc.b	"BBR4",0	; 0x4F
	dc.b	"BVC",0		; 0x50
	dc.b	"EOR IDY",0	; 0x51
	dc.b	"EOR ZPI",0	; 0x52
	dc.b	"TAM",0		; 0x53
	dc.b	"CSL",0		; 0x54
	dc.b	"EOR ZPX",0	; 0x55
	dc.b	"LSR ZPX",0	; 0x56
	dc.b	"RMB5",0	; 0x57
	dc.b	"CLI",0		; 0x58
	dc.b	"EOR ABY",0	; 0x59
	dc.b	"PHY",0		; 0x5A
	dc.b	"xxx 5B",0	; 0x5B
	dc.b	"xxx 5C",0	; 0x5C
	dc.b	"EOR ABX",0	; 0x5D
	dc.b	"LSR ABX",0	; 0x5E
	dc.b	"BBR5",0	; 0x5F
	dc.b	"RTS",0		; 0x60
	dc.b	"ADC IDX",0	; 0x61
	dc.b	"CLA",0		; 0x62
	dc.b	"xxx 63",0	; 0x63
	dc.b	"STZ ZPG",0	; 0x64
	dc.b	"ADC ZPG",0	; 0x65
	dc.b	"ROR ZPG",0	; 0x66
	dc.b	"RMB6",0	; 0x67
	dc.b	"PLA",0		; 0x68
	dc.b	"ADC IMM",0	; 0x69
	dc.b	"ROR A",0	; 0x6A
	dc.b	"xxx 6B",0	; 0x6B
	dc.b	"JMP IND",0	; 0x6C
	dc.b	"ADC ABS",0	; 0x6D
	dc.b	"ROR ABS",0	; 0x6E
	dc.b	"BBR6",0	; 0x6F
	dc.b	"BVS",0		; 0x70
	dc.b	"ADC IDY",0	; 0x71
	dc.b	"ADC ZPI",0	; 0x72
	dc.b	"TII",0		; 0x73
	dc.b	"STZ ZPX",0	; 0x74
	dc.b	"ADC ZPX",0	; 0x75
	dc.b	"ROR ZPX",0	; 0x76
	dc.b	"RMB7",0	; 0x77
	dc.b	"SEI",0		; 0x78
	dc.b	"ADC ABY",0	; 0x79
	dc.b	"PLY",0		; 0x7A
	dc.b	"xxx 7B",0	; 0x7B
	dc.b	"JMP IAX",0	; 0x7C
	dc.b	"ADC ABX",0	; 0x7D
	dc.b	"ROR ABX",0	; 0x7E
	dc.b	"BBR7",0	; 0x7F
	dc.b	"BRA",0		; 0x80
	dc.b	"STA IDX",0	; 0x81
	dc.b	"CLX",0		; 0x82
	dc.b	"TST IMM ZPG",0	; 0x83
	dc.b	"STY ZPG",0	; 0x84
	dc.b	"STA ZPG",0	; 0x85
	dc.b	"STX ZPG",0	; 0x86
	dc.b	"SMB0",0	; 0x87
	dc.b	"DEY",0		; 0x88
	dc.b	"BIT IMM",0	; 0x89
	dc.b	"TXA",0		; 0x8A
	dc.b	"xxx 8B",0	; 0x8B
	dc.b	"STY ABS",0	; 0x8C
	dc.b	"STA ABS",0	; 0x8D
	dc.b	"STX ABS",0	; 0x8E
	dc.b	"BBS0",0	; 0x8F
	dc.b	"BCC",0		; 0x90
	dc.b	"STA IDY",0	; 0x91
	dc.b	"STA ZPI",0	; 0x92
	dc.b	"TST IMM ABS",0	; 0x93
	dc.b	"STY ZPX",0	; 0x94
	dc.b	"STA ZPX",0	; 0x95
	dc.b	"STX ZPY",0	; 0x96
	dc.b	"SMB1",0	; 0x97
	dc.b	"TYA",0		; 0x98
	dc.b	"STA ABY",0	; 0x99
	dc.b	"TXS",0		; 0x9A
	dc.b	"xxx 9B",0	; 0x9B
	dc.b	"STZ ABS",0	; 0x9C
	dc.b	"STA ABX",0	; 0x9D
	dc.b	"STZ ABX",0	; 0x9E
	dc.b	"BBS1",0	; 0x9F
	dc.b	"LDY IMM",0	; 0xA0
	dc.b	"LDA IDX",0	; 0xA1
	dc.b	"LDX IMM",0	; 0xA2
	dc.b	"TST IMM ZPX",0	; 0xA3
	dc.b	"LDY ZPG",0	; 0xA4
	dc.b	"LDA ZPG",0	; 0xA5
	dc.b	"LDX ZPG",0	; 0xA6
	dc.b	"SMB2",0	; 0xA7
	dc.b	"TAY",0		; 0xA8
	dc.b	"LDA IMM",0	; 0xA9
	dc.b	"TAX",0		; 0xAA
	dc.b	"xxx AB",0	; 0xAB
	dc.b	"LDY ABS",0	; 0xAC
	dc.b	"LDA ABS",0	; 0xAD
	dc.b	"LDX ABS",0	; 0xAE
	dc.b	"BBS2",0	; 0xAF
	dc.b	"BCS",0		; 0xB0
	dc.b	"LDA IDY",0	; 0xB1
	dc.b	"LDA ZPI",0	; 0xB2
	dc.b	"TST IMM ABX",0	; 0xB3
	dc.b	"LDY ZPX",0	; 0xB4
	dc.b	"LDA ZPX",0	; 0xB5
	dc.b	"LDX ZPY",0	; 0xB6
	dc.b	"SMB3",0	; 0xB7
	dc.b	"CLV",0		; 0xB8
	dc.b	"LDA ABY",0	; 0xB9
	dc.b	"TSX",0		; 0xBA
	dc.b	"xxx BB",0	; 0xBB
	dc.b	"LDY ABX",0	; 0xBC
	dc.b	"LDA ABX",0	; 0xBD
	dc.b	"LDX ABY",0	; 0xBE
	dc.b	"BBS3",0	; 0xBF
	dc.b	"CPY IMM",0	; 0xC0
	dc.b	"CMP IDX",0	; 0xC1
	dc.b	"CLY",0		; 0xC2
	dc.b	"TDD",0		; 0xC3
	dc.b	"CPY ZPG",0	; 0xC4
	dc.b	"CMP ZPG",0	; 0xC5
	dc.b	"DEC ZPG",0	; 0xC6
	dc.b	"SMB4",0	; 0xC7
	dc.b	"INY",0		; 0xC8
	dc.b	"CMP IMM",0	; 0xC9
	dc.b	"DEX",0		; 0xCA
	dc.b	"xxx CB",0	; 0xCB
	dc.b	"CPY ABS",0	; 0xCC
	dc.b	"CMP ABS",0	; 0xCD
	dc.b	"DEC ABS",0	; 0xCE
	dc.b	"BBS4",0	; 0xCF
	dc.b	"BNE",0		; 0xD0
	dc.b	"CMP IDY",0	; 0xD1
	dc.b	"CMP ZPI",0	; 0xD2
	dc.b	"TIN",0		; 0xD3
	dc.b	"CSH",0		; 0xD4
	dc.b	"CMP ZPX",0	; 0xD5
	dc.b	"DEC ZPX",0	; 0xD6
	dc.b	"SMB5",0	; 0xD7
	dc.b	"CLD",0		; 0xD8
	dc.b	"CMP ABY",0	; 0xD9
	dc.b	"PHX",0		; 0xDA
	dc.b	"xxx DB",0	; 0xDB
	dc.b	"xxx DC",0	; 0xDC
	dc.b	"CMP ABX",0	; 0xDD
	dc.b	"DEC ABX",0	; 0xDE
	dc.b	"BBS5",0	; 0xDF
	dc.b	"CPX IMM",0	; 0xE0
	dc.b	"SBC IDX",0	; 0xE1
	dc.b	"xxx E2",0	; 0xE2
	dc.b	"TIA",0		; 0xE3
	dc.b	"CPX ZPG",0	; 0xE4
	dc.b	"SBC ZPG",0	; 0xE5
	dc.b	"INC ZPG",0	; 0xE6
	dc.b	"SMB6",0	; 0xE7
	dc.b	"INX",0		; 0xE8
	dc.b	"SBC IMM",0	; 0xE9
	dc.b	"NOP",0		; 0xEA
	dc.b	"xxx EB",0	; 0xEB
	dc.b	"CPX ABS",0	; 0xEC
	dc.b	"SBC ABS",0	; 0xED
	dc.b	"INC ABS",0	; 0xEE
	dc.b	"BBS6",0	; 0xEF
	dc.b	"BEQ",0		; 0xF0
	dc.b	"SBC IDY",0	; 0xF1
	dc.b	"SBC ZPI",0	; 0xF2
	dc.b	"TAI",0		; 0xF3
	dc.b	"SET",0		; 0xF4
	dc.b	"SBC ZPX",0	; 0xF5
	dc.b	"INC ZPX",0	; 0xF6
	dc.b	"SMB7",0	; 0xF7
	dc.b	"SED",0		; 0xF8
	dc.b	"SBC ABY",0	; 0xF9
	dc.b	"PLX",0		; 0xFA
	dc.b	"xxx FB",0	; 0xFB
	dc.b	"xxx FC",0	; 0xFC
	dc.b	"SBC ABX",0	; 0xFD
	dc.b	"INC ABX",0	; 0xFE
	dc.b	"BBS7",0	; 0xFF
	ENDC
