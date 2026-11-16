; CD-ROM unit buffers (CD.asm), in a BSS section of their own.
CdCueMax=16384
CdPoolMax=8192
CdChunkSecs=32
CdPathMax=512

	SECTION	CdBss,BSS
	CNOP	0,4
CdRam:		DS.B	64*1024		; banks $80-$87
CdSRam:		DS.B	192*1024	; banks $68-$7F (Super System Card); after CdRam (cleared together)
CdOpenBus:	DS.B	8*1024		; $FF: the locked BRAM bank
AdRam:		DS.B	64*1024		; ADPCM RAM
	IFEQ	CdSndOff
AuCapB:		DS.L	CD_CAPMAX+2	; CD audio captured a frame: L, R words (index 0 the frame before's last)
AdCapB:		DS.W	CD_CAPMAX+2	; ADPCM, the same
	ENDC
CdZeros:	DS.B	2048+16		; sectors outside the data tracks, status bytes
CdCueBuf:	DS.B	CdCueMax
CdNamePool:	DS.B	CdPoolMax
CdChunk:	DS.B	CdChunkSecs*2352
CdPath:		DS.B	CdPathMax
CdCueName:	DS.B	CdPathMax
	IFNE	AdDump
AdDumpBuf:	DS.B	4000000
AdDumpEnd:
	ENDC
