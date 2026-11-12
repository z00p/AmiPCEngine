; AGCvars.asm: the AGA chunky mode's variables (test switch AGC), in sections of their own: AGC.asm's code
; is in the main code hunk, whose PC-relative tables must stay within reach.

	SECTION	AgcVars,DATA
AgcWant:	DC.B	0
AgcOn:		DC.B	0
AgcPend:	DC.B	0	; a drawn buffer waits for AgcFlip
AgcColNew:	DC.B	0	; colour registers to load at the flip (AgcRegNew)
AgcBit:		DC.B	0	; the back buffer's bit in AgcStale
AgcOvInv:	DC.B	0	; colours went on register 0: clear the cache at the frame end
AgcLate:	DC.B	0	; the last frame ran past the vblank (main loop)
AgcSkipped:	DC.B	0	; this frame's picture was not converted (AgcC2P)
AgcForce:	DC.B	0	; this conversion writes every group
AgcDrawn:	DC.B	0	; pictures converted since the last skip (to 2)
AgcWide:	DC.B	0	; bit b: the next conversion into plane buffer b takes the whole width (AgcClear)
AgcAll:		DC.B	0	; AgcC2P: this ring's lines all compared (AgcAllS)
AgcPendAny:	DC.B	0	; colours in AgcPendF
AgcLay:		DC.B	0	; AgcC2P: a new split since this buffer's last picture
AgcWNow:	DC.B	0	; AgcC2P: this conversion takes the whole width (AgcWide)
		EVEN
AgcBack:	DC.W	0	; the buffer AgcC2P draws (0/1); the other is shown
AgcNext:	DC.W	0	; the register last taken
AgcOvN:		DC.W	0	; colours on register 0 this frame
AgcOvAll:	DC.W	0	; ... since the start (test builds)
AgcLn:		DC.W	0
AgcSkipN:	DC.W	0	; pictures skipped (debug rows: SKIP)
AgcYb:		DC.W	AGCH	; the split: ring 1 from this picture line, AGCH = one ring (AgcScrKey)
AgcPYb:		DC.W	AGCH	; ... last frame's
AgcYbB:		DC.W	AGCH,AGCH	; ... of buffer b's picture (AgcC2P, AgcPlanePtrs)
AgcKOk:		DC.B	0,0	; ring r's key known this frame
AgcPKOk:	DC.B	0,0	; ... last frame
AgcAllS:	DC.B	0,0	; AgcC2P: ring r moved since this buffer's last picture
AgcKN:		DC.W	0,0	; AgcScrKey: ring r's longest region's lines
AgcKY:		DC.W	0,0	; ring r's key: map row of picture line 0,
AgcKX:		DC.W	0,0	; ... BXR
AgcPKY:		DC.W	0,0	; ... last frame's
AgcPKX:		DC.W	0,0
AgcQYb:		DC.W	0	; AgcPlanePtrs: the shown buffer's split,
AgcQC1:		DC.W	0	; ... ring 1's BPLCON1
AgcEv:		DS.W	8	; ... the jumps (line, modulo), -1 at the end
AgcCOff:	DC.W	0	; this conversion's groups: chunky bytes to the first in a line,
AgcCLen:	DC.W	0	; ... chunky bytes of them,
AgcGOff:	DC.W	0	; ... ring bytes to the first
		CNOP	0,4
AgcTs:		DC.L	0,0	; ring r's T: ring pixel of its first line's chunky byte 0 (AgcScrKey)
AgcTB:		DC.L	0,0,0,0	; ... of buffer b's picture (b x 8 + r x 4; AgcC2P, AgcPlanePtrs)
AgcPsz:		DC.L	0	; AgcC2P: this ring's bytes,
AgcPsz8:	DC.L	0	; ... x 8 (its shadow),
AgcPB:		DC.L	0	; ... this buffer's plane 2,
AgcSB0:		DC.L	0	; ... and its shadow
AgcQO:		DC.L	0,0	; AgcPlanePtrs: ring r's O,
AgcQP:		DC.L	0,0	; ... its bytes,
AgcQB:		DC.L	0	; ... ring 1's first byte
AgcLayN:	DC.L	0	; test count (AutoExit builds): new splits
AgcAY:		DC.L	0	; AgcC2P: this line's ring byte,
AgcP2B:		DC.L	0	; ... plane 2's ring (this ring), its end,
AgcP2E:		DC.L	0
AgcMirE:	DC.L	0	; ... and its first AGCRW bytes' end (mirrored in the slack)
AgcSB:		DC.L	0	; ... the ring's shadow
AgcGrpW:	DC.L	0	; test counts (AutoExit builds): groups written,
AgcPicN:	DC.L	0	; ... pictures drawn,
AgcGrpC:	DC.L	0	; ... groups visited (compared or written),
AgcShN:		DC.L	0	; ... ring moves,
AgcMirN:	DC.L	0	; ... groups mirrored in the slack
AgcDFlg:	DS.B	64	; AgcDumpWrite's flag bytes
AgcPLP:		DC.L	0	; RtgPLP when the cache was last valid
AgcShad:	DC.L	0	; the two shadow chunky pictures (AgcStart), 0 none
AgcLC:		DC.L	0	; AgcC2P: this line's chunky,

	SECTION	AgcBss,BSS
	CNOP	0,4
AgcCnt:		DS.L	256	; pixels of each register in the chunky buffer
AgcERg:		DS.W	512	; VCE entry -> register, -1 not known (AgcEInv)
AgcMap:		DS.W	512	; PCE colour -> register, -1 none
AgcRegCol:	DS.W	256	; register -> PCE colour, -1 none
AgcRGB:		DS.W	512	; PCE colour -> AGA 12-bit
AgcOvList:	DS.W	AGCOVMAX
AgcRegNew:	DS.B	256	; register's colour changed since the last snapshot (AgcSnap)
AgcPendF:	DS.B	256	; register's colour to load at the flip (AgcPendRGB)
AgcPendRGB:	DS.W	256
AgcStale:	DS.B	AGCH	; per line: bit b = plane buffer b not yet up to date
