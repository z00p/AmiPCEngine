
;	---------------------
;	AmiPC-Engine Emulator		(Diseño Basado en AmiNES Emulator)
;	---------------------

;	Diseñado y Programado por: Juan Antonio Gómez Gálvez
;	1997 © RED Soft S.L.  Barcelona, Spain
;	(Viernes 20 de Junio de 1997) => (???)

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

INISPR2=$30
FINSPR2=INISPR2

	IFND	ShowFps	; default, or set with -DShowFps=x
ShowFps=0
	ENDC
	IFND	DbgRows	; 1 = debug build: speed and section-time rows above the picture (DbgRows.asm)
DbgRows=0
	ENDC
	IFND	DbgProbe	; 1 (with DbgRows, AGA): the top row shows why the background is redrawn
DbgProbe=0
	ENDC
	IFND	StripLog	; AutoExit test builds (AGA): per frame the old sprite strips, the sprite columns and the new strips -> PROGDIR:AmiPCE.strips
StripLog=0
	ENDC
	IFND	AGC		; 1 = test: AGA chunky mode (the RTG composer, a sticky 256-colour palette, C2P into 8 planes)
AGC=0
	ENDC
	IFND	ShowPerformance	; default, or set with -DShowPerformance=x
ShowPerformance=0
	ENDC

	IFND	NO_TIMER	; 1 = Juan's alpha behaviour: no HuC6280 timer
NO_TIMER=0
	ENDC
	IFND	LogFrame	; per-frame serial probe (needs LOG_ENABLED=1)
LogFrame=0
	ENDC
	IFND	LogPCs	; with LogFrame: the PC at lines 0, 32, .. 256 and 8 bytes of the 6280 stack per frame
LogPCs=0
	ENDC
	IFND	LogSum	; with LogFrame: also checksums of RAM, VRAM, VDC regs + palette, SAT copy per frame
LogSum=0
	ENDC
	IFND	NO_HOMEDIR	; 1 = Juan's default ROM drawer "Cartridges" (relative to the current dir)
NO_HOMEDIR=0
	ENDC
	IFND	NO_SPR10	; 1 = Juan's 9-bit sprite X/Y (sprites parked at Y $2xx wrap onto the screen)
NO_SPR10=0
	ENDC
	IFEQ	NO_SPR10
SprXYMask=$03ff		; SAT X and Y are 10 bits
	ELSE
SprXYMask=$01ff
	ENDC
	IFND	NO_JOYFIX	; 1 = Juan's pad reads (joystick fire 2 = pin 5 into Right; CD32 nibbles swapped)
NO_JOYFIX=0
	ENDC
	IFND	NO_CYC455	; 1 = Juan's 340 CPU cycles per line (75% of the real 455)
NO_CYC455=0
	ENDC
	IFND	AutoPress	; AutoExit test builds: replay the pad schedule in autopress.i
AutoPress=0
	ENDC
	IFND	AutoPressHost	; with AutoPress: apply the schedule where the real pad is read (Amiga vblank), not at the PCE frame (lag tests)
AutoPressHost=0
	ENDC
	IFND	AutoFreeze	; AutoExit test builds: hold the last frame instead of exiting
AutoFreeze=0
	ENDC
	IFND	NO_COPFIX	; 1 = Juan's 8-byte CopperScrolls (overrun with many scroll changes)
NO_COPFIX=0
	ENDC
	IFND	NO_IDLESKIP	; 1 = idle loops (JMP/BRA/BBR/BBS onto themselves) run to the end of the line
NO_IDLESKIP=0
	ENDC
	IFND	NO_BGCOL0	; 1 = BG pixel 0 of palettes 1-15 shows that palette's own entry 0 (real VCE: always entry 0)
NO_BGCOL0=0
	ENDC
	IFND	NO_SPRBANK	; 1 = sprite colours always in BG palette 15's bank (a BG using palette 15 shows sprite colours)
NO_SPRBANK=0
	ENDC
	IFND	NO_WIDE	; 1 = Juan's fixed 256-px picture (wider VDC modes cut off on the right)
NO_WIDE=0
	ENDC
	IFND	NO_SPRAREA	; 1 = the one sprite palette is the one most sprites use (not the most sprite area)
NO_SPRAREA=0
	ENDC
	IFND	NO_SPRCOVER	; 1 = the 4 sprite strips stay at window px 0-255 (needs NO_WIDE=0)
NO_SPRCOVER=0
	ENDC
	IFND	NO_SPRBEST	; 1 = when 4 sprite strips can't cover every sprite column, keep them as they are unless a left-to-right plan covers all
NO_SPRBEST=0
	ENDC
	IFND	NO_SPRRACE	; 1 = AGA sprite data copied top to bottom, a moved strip's position only from the next frame (ghosts)
NO_SPRRACE=0
	ENDC
	IFND	NO_NTSCTOP	; 1 = picture on line $30 on NTSC too (centred for PAL; on NTSC too low, bottom cut off)
NO_NTSCTOP=0
	ENDC
	IFND	NO_BUILDINFO	; 1 = Juan's window title without the build date and commit
NO_BUILDINFO=0
	ENDC
	IFND	NO_PALDEF	; 1 = Juan's default screen PAL (games at 5/6 speed); 0 = NTSC, the PC Engine's own 60 Hz
NO_PALDEF=0
	ENDC
	IFND	NO_SPRDIRTY	; 1 = sprite dirty marks run (column+1)*16 lines (D2 clobbered), past the end of the Tablas hunk
NO_SPRDIRTY=0
	ENDC
	IFND	NO_NODEBUG	; 1 = Juan's debugger in (UseDebug=1: a trace check per opcode, keys P/T/S)
NO_NODEBUG=0
	ENDC
	IFND	UseDebug	; Juan's debugger (Debug.asm): on only with NO_NODEBUG=1 or -DUseDebug=1
UseDebug=NO_NODEBUG
	ENDC
	IFND	NO_POLLSKIP	; 1 = no fast-forward of LDA/CMP zp|abs + Bcc polling loops
NO_POLLSKIP=0
	ENDC
	IFND	NO_MAPSHIFT	; 1 = SetMapper (TAM) works out the page base with MULU #$2000
NO_MAPSHIFT=0
	ENDC
	IFND	NO_CYCREG	; 1 = cycle count of the line in memory (Cycles(A3)), not in D2's upper word
NO_CYCREG=0
	ENDC
	IFND	NO_GFXRESET	; 1 = BG tile cache and sprite buffers kept from the last game (stale tiles stay blank)
NO_GFXRESET=0
	ENDC
	IFND	NO_PSGWAVE	; 1 = Juan's PSG stub (one fixed square wave, channels 0-3, no wave RAM, noise or DDA)
NO_PSGWAVE=0
	ENDC
	IFND	NO_PSG6	; 1 = PSG channels 0-3 on Paula voices 0-3, channels 4/5 not played
NO_PSG6=0
	ENDC
	IFND	NO_PSGNOISE	; 1 = PSG noise (channels 4/5, $0807) not played
NO_PSGNOISE=0
	ENDC
	IFND	NO_PSGDDA	; 1 = PSG DDA (direct sample) writes not played
NO_PSGDDA=0
	ENDC
	IFND	NO_DDASTRETCH	; 1 = DDA samples at a fixed rate (gaps when the emulation is below full speed)
NO_DDASTRETCH=0
	ENDC
	IFND	DdaStat	; AutoExit test builds: DDA health (underruns, queue depth, samples, voice starts) in AmiPCE.result
DdaStat=0
	ENDC
	IFND	DdaDump	; AutoExit test builds: log every DDA buffer queued and handed to Paula -> PROGDIR:AmiPCE.dda
DdaDump=0		; (tools/pcmcmp.py renders it as Paula plays it)
	ENDC
	IFND	NO_DDAQUEUE	; 1 = DDA queue as in step 4b: a stream stops at once when the registers say so (queued samples
NO_DDAQUEUE=0		; dropped and replayed at its next start), volume from the registers each vblank, no latency cap
	ENDC
	IFND	NO_DDATICK	; 1 = DDA samples only on the scanline grid (timer-driven samples land up to a line off,
NO_DDATICK=0		; 2,2,2,3-line spacing for 2.25: noise at 1-3 kHz); 0 = one sample per timer tick when the game writes so
	ENDC
DdaTickOff=NO_DDATICK|NO_DDAQUEUE|NO_DDASTRETCH|NO_PSGDDA|NO_PSGWAVE|NO_TIMER	; tick capture needs all of these
	IFND	PSGLog	; probe builds (needs LOG_ENABLED=1): one serial line of PSG state per frame
PSGLog=0
	ENDC
	IFND	AutoMenu	; AutoExit test builds: every AutoMenu frames leave the game as Esc does (OS back),
AutoMenu=0		; load a ROM into new memory with the OS alive, wait, then Power ON as the menu does
	ENDC
	IFND	AutoMenuCont	; with AutoMenu: 1 = Continue (same game) instead of Power ON with the other ROM
AutoMenuCont=0
	ENDC
	IFND	MenuAuto	; menu test builds: Insert PCE:auto1.pce and auto2.pce in turn and Power ON without
MenuAuto=0		; the requester, leave each game after MenuAuto frames (as Esc), MenuAutoMax trips
	ENDC
	IFND	MenuAutoIns	; with MenuAuto: 1 = Insert PCE:auto1.pce only, no Power ON (the menu after Insert)
MenuAutoIns=0
	ENDC
	IFND	MenuAutoMax
MenuAutoMax=12
	ENDC
	IFND	MenuShow	; menu test builds: open one window over the main menu (after any MenuAuto trips):
MenuShow=0		; 1 About, 2 Help Page, 3 error window, 4 Insert file requester, 5 CPU error window, 6 RTG scanlines Hard 50% + Save Prefs (then About), 7 Pick mode... (AGC, RTG)
	ENDC
	IFND	StateDump	; AutoExit test builds: at exit write IRAM, VRAM, VDC regs, palette, SAT copy to PROGDIR:pcestate.bin
StateDump=0
	ENDC
	IFND	VdcLog	; StateDump test builds: VDC register writes (not R2/6/7/8) with frame, line, PC, MPRs after pcestate.bin
VdcLog=0
	ENDC
	IFND	ScrRing	; test builds (menu): the scroll log of the last 1000 frames (lines, BXR, BYR; AGA split, late, skip) -> PROGDIR:scrring.bin at each return to the menu, and at the end of an AutoExit run (tools/scrring.py)
ScrRing=0
	ENDC
	IFND	ScrDump	; AutoExit test builds: the scroll log (line, BXR, BYR) of 1000 frames from frame ScrDump -> PROGDIR:scrdump.bin
ScrDump=0
	ENDC
	IFND	ProfOn	; AutoExit test builds: sampling profiler (CIA-B timer, ~2 kHz) -> PROGDIR:AmiPCE.prof
ProfOn=0		; (tools/profmap.py; not with AutoMenu)
	ENDC
	IFND	CodeCheck	; AutoExit test builds: list the bytes of the code hunk changed since the start
CodeCheck=0
	ENDC
	IFND	AutoRestart	; AutoExit test builds: start a game again at this frame, as the menu does
AutoRestart=0		; (with -DEMBED2=1 the second ROM, src/embed2.i, like a second Insert)
	ENDC
	IFND	NO_RTG	; 1 = no RTG display (ToolType / CLI word RTG: a 16-bit P96 screen for play, src/RTG.asm)
NO_RTG=0
	ENDC
	IFND	NO_RTGFIX	; 1 = the RTG code as merged (CR log of 256 writes, sprites from line 240 dropped, palette mark, BSS buffers, failed screens ignored)
NO_RTGFIX=0
	ENDC
	IFND	NO_RTGMODE	; 1 = no RTG mode choice (ToolType / CLI RTGMODE=, prefs long $18; the colour program's Display gadget: the mode, Pick mode..., Automatic)
NO_RTGMODE=0
	ENDC
	IFND	NO_BLITREQ	; 1 = a blit ending during CongelaAMIGA's blitter wait loses its interrupt (INTREQ saved before the wait)
NO_BLITREQ=0
	ENDC
	IFND	NO_SATBWRAP	; 1 = the SAT copy adds SATB as a signed word (SATB >= $7F01 reads outside VRAM)
NO_SATBWRAP=0
	ENDC
	IFND	NO_BLKFIX	; 1 = Juan's block transfers (one MPR lookup for the whole run, TAI source from a stale D0, I/O only as TIA/TIN dest or TAI source)
NO_BLKFIX=0
	ENDC
	IFND	NO_BRAMFMT	; 1 = backup RAM (bank $F7) all zeros at power on (games see it unformatted)
NO_BRAMFMT=0
	ENDC
	IFND	NO_RTGPAL	; 1 = RTG uses the frame-end palette for the whole frame (no mid-frame VCE colour changes)
NO_RTGPAL=0
	ENDC
	IFND	NO_CSL	; 1 = CSL ignored: the CPU always runs at 7.16 MHz (Soldier Blade's 1.79 MHz delay loops run 4x fast)
NO_CSL=0
	ENDC
	IFND	NO_AGAVDW	; 1 = AGA shows 232 lines whatever the VDC's display height (R0D): junk below short pictures (UWOL)
NO_AGAVDW=0
	ENDC
	IFND	NO_TALLMENU	; 1 = the menu on a 424+ line RTG mode at AGA's 640x212 layout (flat, in the top of the picture)
NO_TALLMENU=0
	ENDC
	IFND	NO_SCRLO	; 1 = R7/R8 logged only on the high byte, and a BXR change reloads the BG row (HuZERO's per-line BXR lost)
NO_SCRLO=0
	ENDC
	IFND	NO_CRVIS	; 1 = AGA bitplane DMA and the BG-off colour from the VDC CR at the Amiga vblank (SF2' fights blank:
NO_CRVIS=0	; its CR is off below the picture); 0 = from the CR during the shown lines of the frame
	ENDC
	IFND	NO_VBLLINE	; 1 = vblank interrupt (and SAT copy) always on line 251 (Mesen: after the last display line, VDW + 1)
NO_VBLLINE=0
	ENDC
	IFND	NO_TSBTRB	; 1 = TSB/TRB/TST: N, V from A or the result (TRB: Z from A), no I/O handlers (VRAM read-modify-write lost: Parasol Stars)
NO_TSBTRB=0
	ENDC
	IFND	NO_RMWIO	; 1 = ASL/LSR/ROL/ROR/INC/DEC abs and BIT abs on the I/O page use the I/O memory copy, not the handlers
NO_RMWIO=0
	ENDC
	IFND	NO_SCANLINES	; 1 = no RTG scanlines (ToolType/CLI SCANLINES=, Options > RTG scanlines, prefs byte $15)
NO_SCANLINES=0
	ENDC
	IFND	NO_RTIIRQ	; 1 = RTI does not check for a pending interrupt (one raised during a handler waits for the next line: Parodius HUD split 1 line late)
NO_RTIIRQ=0
	ENDC
	IFND	NO_VRAMEND	; 1 = VRAM writes past word $7FFF wrap to word 0 (the VDC drops them: HuZERO road)
NO_VRAMEND=0
	ENDC
	IFND	NO_BATSIZE	; 1 = AGA: no redraw when the BAT size changes (Parasol Stars: map tiles left in the level)
NO_BATSIZE=0
	ENDC
	IFND	NO_ROMMAP	; 1 = ROM banks only as far as the file goes, no mirrors, 384 KB cards not split
NO_ROMMAP=0
	ENDC
	IFND	NO_BLENDLV	; 1 = one Blended scanline setting, quarter + quarter rounded down (no Blended light / strong)
NO_BLENDLV=0
	ENDC
	IFND	NO_SF2	; 1 = no Street Fighter II' mapper: a card over 1 MB fills DirMappers past its end
NO_SF2=0
	ENDC
	IFND	NO_POPRAM	; 1 = no 32 KB RAM at banks $40-$43 on the Populous card
NO_POPRAM=0
	ENDC
	IFND	NO_VDCDMA	; 1 = no VRAM-VRAM DMA, no DMA-end IRQs, SAT copied at the vblank only with the vblank IRQ on
NO_VDCDMA=0
	ENDC
	IFND	NO_TFLAG	; SET: the next ORA/AND/EOR/ADC works on zero page byte X (it was a NOP). Legendary Axe's map
NO_TFLAG=0
	ENDC
	IFND	NO_BCD	; decimal mode: SED makes ADC and SBC BCD (it was ignored). Score counters
NO_BCD=0
	ENDC
	IFND	NO_VDLATE	; RCR on the vblank line: VD one line after RR, two IRQs (they were one, status $24). fumobinning
NO_VDLATE=0
	ENDC
	IFND	NO_VDCREAD	; VRAM reads go through the VDC's read-ahead buffer (they read VRAM at once). ninjabutai's logo
NO_VDCREAD=0
	ENDC
	IFND	NO_BGMASK	; 1 = on AGA a BG pixel of value 0 is index 16 x palette (NO_BGCOL0 copies colour 0 to those slots); 0 = truly index 0
NO_BGMASK=0
	ENDC
	IFND	NO_BGLINE	; 1 = AGA colour 0 once a frame; 0 = line by line (HuZERO's road, Tongueman's Logic). Needs NO_BGMASK=0
NO_BGLINE=0
	ENDC
	IFND	NO_SPRBACK	; 1 = AGA sprites always over the BG; 0 = behind it in a frame where all visible sprites ask for that. Needs NO_BGMASK=0
NO_SPRBACK=0
	ENDC
	IFND	NO_IOREAD	; I/O read-backs as Mesen's: $1000 bits 4-5, $0405 bits 1-7, $0001 = 0, $1402 = 0 at reset
NO_IOREAD=0
	ENDC
	IFND	NO_VBLUNIT	; 1 = each emulated frame runs from line 0 to 262, so what a game does with a pad read in its vblank shows a frame later; 0 = from the PCE vblank line to the next, so the game reads the pad first and the frame it then draws is on the screen a frame sooner
NO_VBLUNIT=0
	ENDC
	IFND	NO_LATESTART	; 1 = on RTG each frame is emulated straight after the vblank; 0 = it waits until just enough of the frame is left for the work (the slowest of the last 16 frames and a margin), reads the pad again and then emulates, so a press reaches the game up to most of a frame later than the vblank read
NO_LATESTART=0
	ENDC
	IFND	NO_VRAMSAME	; 1 = every VRAM write marks its tile for redrawing; 0 = only a write that changes VRAM (Parodius after the bell's flash bomb rewrites the same 17 tiles every frame, and AGA redrew every cell using them: 17 fps)
NO_VRAMSAME=0
	ENDC
	IFND	NO_DDAPER	; 1 = the timer-tick DDA period on a PAL screen is 610 (worked out from 227.5 colour clocks a line, NTSC's average: 0.36% long); 0 = 609 (PAL's 227: 313 x 227 / 116.9 = 607.8, 0.2% long as meant, so the queue trims less often)
NO_DDAPER=0
	ENDC
	IFND	NO_DDAGAP	; 1 = a DDA stream whose channel the game switches off ($0804 = 0) ends once its queue has played out, and its voice goes to a tone; 0 = it keeps its voice for the 8 'live' frames as when DDA stays on (Blazing Lazers turns its drum channel off for 4 frames every beat: the voice went to a harmony channel for a frame or two each beat and the drums restarted, 94 cut notes a minute)
NO_DDAGAP=0
	ENDC
	IFND	NO_DDAFADE	; 1 = through a gap ($0804 = 0, the stream still live) the drum voice holds the last DDA level (Blazing Lazers: often near full scale for 4 frames each beat, a sub-bass thump); 0 = it fades to the mid level in 32 samples and stays there, as the chip's channel goes silent
NO_DDAFADE=0
	ENDC
	IFND	NO_DDAPRIME	; 1 = while a DDA stream primes (waits for two buffers: at its start and after a gap) Paula plays the hold buffer at the last level of the newest queued buffer, which it hasn't played yet (Blazing Lazers: often near full scale, a frame of DC at each beat); 0 = the hold buffer keeps the level Paula last played (the mid level at a stream start)
NO_DDAPRIME=0
	ENDC
	IFND	NO_SCRLONG	; 1 = SetScrollAtRender writes each copper move as two words; 0 = one long (half the chip-RAM writes per scroll change; HuZERO's road changes scroll on most lines)
NO_SCRLONG=0
	ENDC
	IFND	NO_TILEWRAP	; 1 = AGA takes a BAT tile number of $800 or more as it is; 0 = it wraps to the 32K words of VRAM as on RTG (Parodius after the bell's flash bomb fills 480 hidden cells with tiles $Exx-$Fxx: AGA read their redraw flags past the end of TabRedef, never cleared, and redrew them every frame: 17 fps)
NO_TILEWRAP=0
	ENDC
	IFND	NO_SATLAG	; 1 = sprites drawn from the SAT the VDC copies at this frame's vblank (one frame early); 0 = from the SAT the frame was shown with, as the VDC (Power Tennis's net sprite over the scrolling net)
NO_SATLAG=0
	ENDC
	IFND	NO_PSGSTICK	; 1 = a channel that has a Paula voice keeps it with a bonus of 6 (Paula volume units); 0 = 20, so channels change speaker less often
NO_PSGSTICK=0
	ENDC
	IFND	NO_PSGBASS	; 0 = a bass tone (F >= $300, under 190 Hz) outranks a louder chord note for the four Paula voices. OFF by default: the plain mix sounded better by ear
NO_PSGBASS=1
	ENDC
	IFND	NO_RCRLATE	; 1 = a scroll write early in a line counts for the line after it, however early
NO_RCRLATE=0
	ENDC
	IFND	NO_STKWRAP	; 1 = the wrap paths of the 6280 stack missed page $21 (Tricky Kick runs with SP = $01 and wraps all the time)
NO_STKWRAP=0
	ENDC
	IFND	NO_CLIDELAY	; 1 = CLI takes a pending IRQ at once; 0 = after the next instruction, as the 6280 (Order of the Griffon: CLI, then STA $1403)
NO_CLIDELAY=0
	ENDC
	IFND	NO_IOBUF	; 1 = no I/O buffer; 0 = open bits of $0800-$17FF read the last byte on the buffer (Download reads $20 back from $1403), pad CLR, SEL held apart
NO_IOBUF=0
	ENDC
	IFND	NO_BURST	; 1 = BG and sprites off show colour 0; 0 = VCE entry $100, as the VDC's burst mode (Chew Man Fu, black between screens)
NO_BURST=0
	ENDC
	IFND	NO_BRAMSAVE	; 1 = backup RAM starts blank at every Power ON and nothing is kept; 0 = kept per game in PROGDIR:Saves
NO_BRAMSAVE=0
	ENDC
	IFND	NO_TIMER7F	; 1 = the timer counter reads 0 all through its last count; 0 = $7F on the last cycles before it underflows from 0, as Mesen (Battle Royale waits for a non-zero $0C00 with reload 0)
NO_TIMER7F=0
	ENDC
	IFND	NO_BLKTIME	; 1 = a block transfer (TII/TDD/TIN/TIA/TAI) ends its line and its other cycles are lost; 0 = they take the lines after it (Energy, Cyber Cross: a 12 KB TIA is 2.5 frames)
NO_BLKTIME=0
	ENDC
	IFND	NO_SPINIT	; 1 = power on with SP $FF but A6 at $21FF (one byte low: a push before the first TXS or IRQ lands one byte off); 0 = SP 0 and A6 to match, as Mesen (Psychosis, Golf Boys, Deep Blue never set SP)
NO_SPINIT=0
	ENDC
	IFND	NO_VCELO	; 1 = a $0404 write waits for $0405 and $0405 writes the latched low byte; 0 = each byte goes into the entry at once, as the VCE (World Circuit's backdrop: $0404 alone)
NO_VCELO=0
	ENDC
	IFND	NO_HSWPOS	; 1 = RTG picture moved by HSW + HDS; 0 = by HDS only: the VCE starts every line with its own sync, so the VDC's HSW does not move it (Strip Fighter II, HSW 16)
NO_HSWPOS=0
	ENDC
	IFND	NO_STIO	; 1 = ST0/ST1/ST2 write through MPR0; 0 = always to the VDC, as the 6280 (Bikkuriman World runs with MPR0 = ROM bank 1)
NO_STIO=0
	ENDC
	IFND	NO_SPR2BPP	; 1 = RTG: sprites always 4 planes; 0 = MWR sprite mode 1 draws 2-plane sprites, the SAT CG bit picks planes 0-1 or 2-3 (Fighting Run portrait)
NO_SPR2BPP=0
	ENDC
	IFND	NO_VDRACE	; 1 = a VDC IRQ is always taken first; 0 = in a status poll (LDA $0000 / AND / BEQ back) the read wins, as when the flag rises inside the LDA (Cyber Cross polls VD with IRQ1 on)
NO_VDRACE=0
	ENDC
	IFND	NO_VDMID	; 1 = RR and VD on one line: VD a line later; 0 = VD about 190 cycles into that line, as Mesen, so the RR's IRQ is taken first (Power Tennis: RR on every line)
NO_VDMID=0
	ENDC
	IFND	NO_IOSLOT	; 1 = a slot-0 access with ROM or RAM in MPR0 is taken as I/O by its offset's low word; 0 = only the I/O page is I/O (Bikkuriman World runs code and reads tables at $0000-$1FFF with MPR0 = ROM)
NO_IOSLOT=0
	ENDC
	IFND	NO_INDRD	; 1 = LDA/ADC/CMP.. ($zp) read memory without the I/O check; 0 = into slot 0 they go through ReadIO, as ($zp),Y does (TaleSpin reads the VDC status with LDA ($78))
NO_INDRD=0
	ENDC
	IFND	NO_TSTROM	; 1 = TST #imm,abs / abs,X reads the write page (a ROM slot's write sink, not the ROM); 0 = the read page (Momotarou Densetsu Gaiden / II: TST #$FF,$48AA,X on a ROM table picks the text font)
NO_TSTROM=0
	ENDC
	IFND	DispTest	; test builds (NO_MENU2=0): 1/2 = the Display gadget set to AGA/RTG before the menu loop
DispTest=0
	ENDC
	IFND	PadTest	; test builds (NO_MENU2=0): 1 = port 1 CD32 pad, port 2 joypad
PadTest=0
	ENDC
	IFND	NO_CHOOSER	; 1 = the menu's settings stay GadTools cycle gadgets; 0 = chooser.gadget pop-up lists when it opens (OS 3.5 and up), else the cycles
NO_CHOOSER=0
	ENDC
	IFND	ChooserVer	; the chooser.gadget version asked for (test builds: 99 = the cycle fallback, as on OS 3.1)
ChooserVer=44
	ENDC
	IFND	NO_RTGBLANK	; 1 = after an RTG run the AGA display keeps the emulator's bitplanes (BPLCON0) until the menu screen is up: a stale picture flashes on Esc
NO_RTGBLANK=0
	ENDC
	IFND	RtgExitHold	; test builds: ticks to wait after the RTG play screen closes (a grab of the AGA display before the menu)
RtgExitHold=0
	ENDC
	IFND	DispAlt		; test builds with MenuAuto: Display AGA on odd trips, RTG on even ones
DispAlt=0
	ENDC
	IFND	NO_MENU2	; 1 = the 1.4 launcher window (Juan's ghosted gadgets, one pad on port 2, the Options menu); 0 = Screen / Display / Scanlines gadgets, a pad type for each port, the Backup RAM text, dead items gone
NO_MENU2=0
	ENDC
	IFND	NO_REL21	; 1 = 2.0 version texts
NO_REL21=0
	ENDC
	IFND	NO_REL20	; 1 = 1.4 version texts
NO_REL20=0
	ENDC
	IFND	NO_REL14	; 1 = 1.3 version texts
NO_REL14=0
	ENDC
	IFND	NO_REL13	; 1 = 1.2 version texts
NO_REL13=0
	ENDC
	IFND	NO_REL12	; 1 = 1.1 version texts
NO_REL12=0
	ENDC
	IFND	NO_REL11	; 1 = 1.0 version texts
NO_REL11=0
	ENDC
	IFND	NO_REL10	; 1 = v0.5 texts: $VER v0.3, About v0.5 without the 1.0 line, screen title 2021, Juan's Help Page pad lines
NO_REL10=0
	ENDC
ScanOff=NO_SCANLINES|NO_RTG|NO_RTGFIX	; the scanline code is in RTG.asm (needs the AllocMem'd buffers)
	IFND	SCANDEF	; test builds: the scanline setting before prefs / ToolType (0 Off, 1-3 = 25/50/75%, 4 Blended, 5 light, 6 strong)
SCANDEF=0
	ENDC
TallOff=NO_TALLMENU|NO_RTG|NO_RTGFIX	; the tall menu code is in RTG.asm
DispOff=NO_MENU2|NO_RTG|NO_RTGFIX	; the menu's Display gadget (AGA / RTG for each Power ON): code in RTG.asm
ChoosOff=NO_CHOOSER|NO_MENU2	; the menu's settings as chooser.gadget pop-ups (Menu.asm, GadToolsBox.asm)
RtgBlankOff=NO_RTGBLANK|NO_MENU2	; RtgTakeover: no bitplanes on the AGA side while the game plays on RTG (RTG.asm)
; Menu drawing calls: through RTG.asm's Tall* helpers (double height on RTG, else as they were)
TallBevelM:	MACRO
	IFEQ	TallOff
	JSR	TallBevel
	ELSE
	jsr     DrawBevelBoxA(a6)
	ENDC
	ENDM
TallITextM:	MACRO
	IFEQ	TallOff
	JSR	TallIText
	ELSE
	jsr     PrintIText(a6)
	ENDC
	ENDM
TallNGM:	MACRO
	IFEQ	TallOff
	JSR	TallNG
	ENDC
	ENDM
TallImgJsr:	MACRO
	IFEQ	TallOff
	JSR	TallImage
	ELSE
	JSR	-114(A6)
	ENDC
	ENDM
TallImgJmp:	MACRO
	IFEQ	TallOff
	JMP	TallImage
	ELSE
	JMP	-114(A6)
	ENDC
	ENDM
; CopperScrolls worst case: 320 entries (ScrollChangesBuf) x 2 SetScrollAtRender
; calls x 76 bytes, plus the end words. The loop stops CopScrollSlack early.
	IFEQ	NO_BGLINE|NO_BGMASK
CopScrollSlack=176+(224*12)+8	; every colour entry: WAIT + WAIT over line 255 + MOVE
	ELSE
CopScrollSlack=176
	ENDC
CopScrollMax=(320*2*76)+CopScrollSlack
	IFND	AutoExit	; test runs: exit after this many frames, write PROGDIR:AmiPCE.result
AutoExit=0
	ENDC
GuardLongs=64		; AutoExit memory check: longs per guard block
MemGuard:	MACRO		; \1 = guard name; only in AutoExit builds
	IFNE	AutoExit
	CNOP	0,4
Guard_\1:	DS.L	GuardLongs
	ENDC
	ENDM
	IFND	OnlyAGA	; default, or set with -DOnlyAGA=x
OnlyAGA=1
	ENDC


CodeHunkStart:
	lea	LogBufIni,A0
	move.l	LogIndex,A1
	nop
	IFNE	UseDebug
	jsr	Debug_Init
	ENDC
	nop
	JMP	Vamos
	MOVEM.L	Debug,D0-D7/A0-A6

	INCLUDE "Log.asm"
	INCLUDE "Debug.asm"
Vamos:

NF_Menu:
	IFND	EMBED
	JMP	MenuLaunch	; EMBED build (build_embed.sh): skip the menu, run GameCart
	ENDC
	IFEQ	NO_RTG
	SUB.L	A0,A0		; EMBED builds: RTG from the CLI word or RTGFORCE
	JSR	RtgStart
	IFNE	AGC
	JSR	AgcStart
	ENDC
	ENDC
	IFNE	AutoExit
	MOVEM.L	D0-D7/A0-A6,-(SP)
	JSR	MemCheckInit	; guard blocks + stack fill, checked by AutoWriteResult
	MOVEM.L	(SP)+,D0-D7/A0-A6
	ENDC


	move.l	#GameCart-$80,DirCart
	MOVE.l	#GameCartEnd-GameCart,D0
	divu.l	#8*1024,d0
	MOVE.W	D0,PagCart


	moveq	#0,d7
	BRA.S	EmulatorStart

	CNOP	0,8
	IFEQ	NO_REL10
	IFEQ	NO_REL11
	IFEQ	NO_REL12
	IFEQ	NO_REL13
	IFEQ	NO_REL14
	IFEQ	NO_REL20
	IFEQ	NO_REL21
	DC.B	"$VER:AmiPC-Engine Emulator v2.1 (14.11.26)",0,0
	ELSE
	DC.B	"$VER:AmiPC-Engine Emulator v2.0 (12.11.26)",0,0
	ENDC
	ELSE
	DC.B	"$VER:AmiPC-Engine Emulator v1.4 (9.11.26)",0,0
	ENDC
	ELSE
	DC.B	"$VER:AmiPC-Engine Emulator v1.3 (4.11.26)",0,0
	ENDC
	ELSE
	DC.B	"$VER:AmiPC-Engine Emulator v1.2 (3.11.26)",0,0
	ENDC
	ELSE
	DC.B	"$VER:AmiPC-Engine Emulator v1.1 (2.11.26)",0,0
	ENDC
	ELSE
	DC.B	"$VER:AmiPC-Engine Emulator v1.0 (31.10.26)",0,0
	ENDC
	ELSE
	DC.B	"$VER:AmiPC-Engine Emulator v0.3 (30.6.20)",0,0
	ENDC
	DC.B	"By: Juan Antonio Gómez Gálvez.",0,0


	CNOP	0,8
EmulatorStart:
	TST.L	D7
	SMI	isContinue

; -=-=-
	LEA	DirPrefs,A5
	IFEQ	NO_MENU2
	MOVE.B	$16(A5),D0		; port 1: 0 none, 1 joystick, 2 CD32 pad, 3 joypad
	AND.W	#$0003,D0
	MOVE.L	(PadPrg1,D0.W*4),PadRut1
	MOVE.B	$08(A5),D0		; port 2: 0 joystick, 1 none, 2 CD32 pad, 3 joypad (Juan's order)
	AND.W	#$0003,D0
	MOVE.L	(PadPrg2,D0.W*4),PadRut2
	MOVE.L	#LeePads,JoyControlRut
	ELSE
	MOVE.B	$08(A5),D0
	AND.W	#$0003,D0
	MOVE.L	(JoyControlPrg,D0.W*4),JoyControlRut
	ENDC
; -=-=-

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

; ---------------------------------------=> Clear Caches.
	MOVE.L	$4.W,A6
	JSR	-$27C(A6)	; ClearCacheU
; ---------------------------------------<=


	IFNE	ProfOn
	JSR	ProfInit		; OS still alive: a CIA-B timer from ciab.resource
	ENDC
	IFEQ	NO_RTG
	JSR	RtgPlayOpen		; OS alive: the RTG play screen (when RTG is wanted)
	IFNE	AGC
	JSR	AgcOpen
	ENDC
	ENDC
	JSR	CongelaAMIGA
	IFEQ	NO_RTG
	JSR	RtgTakeover		; RTG: bitplane, copper and sprite DMA off
	ENDC

	JSR	InitPSG


	MOVE.L	SP,PILA


	
; start emulation:



RestartGame:
	MOVEM.L	Debug,D0-D7/A0-A6
	TST.B	isContinue
	BNE	EsContinue



	LEA	PantGfx,A0
	MOVE.W	#((GfxBufNextBpl*4)/4)-1,D0
	BSR	BorraMem
	MOVE.W	#((GfxBufNextBpl*4)/4)-1,D0
	BSR	BorraMem


	IFNE	OnlyAGA
	JSR	VDP_Init_AGA
	ELSE
	JSR	VDP_Init_SAGA
	ENDC


	BSR	PCE_Init


	LEA	Regs,A3
	MOVE.L	#ScrollChangesBufA,ScrollChangesNow(A3)
	MOVE.L	#ScrollChangesBufB,ScrollChangesNext(A3)
	MOVE.L	ScrollChangesNow(A3),ScrollChangesIndex(A3)
	move.w	#-1,ScrollChangesBufA
	move.w	#-1,ScrollChangesBufB
	IFEQ	NO_VBLUNIT|NO_VDCDMA
	CLR.W	UnitStart		; a new game: its first frame starts at line 0
	ENDC
	IFEQ	NO_BGLINE|NO_BGMASK
	JSR	BgLogInit
	ENDC


	MOVE.L	DirCart,A0
	ADD.W	#$0080,A0
	MOVE.W	PagCart,D0
	BSR	PCE_SetCardtridge


EsContinue:


	clr.l	vTimerVBlanks


; ----------------------------------

	MOVE.W	#$7FFF,$DFF09C
	NOP
	NOP
	NOP
	NOP
;;	MOVE.W	#$C030,$DFF09A	; vBlank and line int enabled
	MOVE.W	#$C020,$DFF09A	; vBlank int enabled
	IFNE	ProfOn
	JSR	ProfStart
	ENDC
;;	MOVE.W	#$C010,$DFF09A	; line int enabled

; ----------------------------------


;	MOVE.W	#0,$DFF1DC	; NTSC
;	MOVE.W	#$20,$DFF1DC	; PAL



; --------------------------------> Find MAX ScanLine
	IFNE	ShowPerformance

	movem.l	d0-d1,-(sp)

	moveq	#3,d1
	clr.w	vTimerMaxScanLine
	sf	vBlankOccurred
.loop:
	move.l	$dff004,d0
	and.l	#$0001FFFF,d0
	lsr.l	#8,d0
	cmp.w	vTimerMaxScanLine,d0
	bcs.s	.skip
	move.w	d0,vTimerMaxScanLine
.skip:
	tst.b	vBlankOccurred
	beq.s	.loop;
	sf	vBlankOccurred
	dbf	d1,.loop

	movem.l	(sp)+,d0-d1

	ENDC
; --------------------------------<







	CLR.L	vBlank_Count
	CLR.L	FPS_Count
	CLR.L	FPS_Current


	SF	ExitToMenu


	SF	vBlankOccurred
	IFNE	DbgRows
DbgLoop:
	JSR	DbgLapOther
	ENDC
BUC:
	IFNE	AGC
	TST.B	vBlankOccurred		; already here: the last frame ran past the vblank (AgcC2P skips a picture)
	SNE	AgcLate
.wvb:
	ENDC
	TST.B	vBlankOccurred
	IFNE	AGC
	BEQ.S	.wvb
	ELSE
	BEQ.S	BUC
	ENDC
	SF	vBlankOccurred
	IFNE	DbgRows
	JSR	DbgFrame
	ENDC
	IFEQ	NO_RTG
	TST.B	RtgOn
	BEQ.S	.noRtgCopy
	JSR	RtgCopy			; RTG: the last frame's changed lines to the screen
	IFNE	DbgRows
	JSR	DbgLapCopy
	ENDC
	IFEQ	NO_LATESTART
	JSR	LateStart		; wait, then the pad again
	IFNE	DbgRows
	JSR	DbgLapDelay
	ENDC
	ENDC
.noRtgCopy:
	ENDC


; ---
;BUC2:
;	TST.B	vBlankOccurred
;	BEQ.S	BUC2
;	SF	vBlankOccurred
;	movem.l	d0/d1,-(sp)
;	move.w	#$34,d0
;	bsr	WaitRaster
;	movem.l	(sp)+,d0/d1
; ---

		IFNE	ShowPerformance
		bsr	TimerStart
		ENDC


	IFNE	UseDebug

	TST.b	oneStep
	beq.s	.noOneStep
	SF	oneStep
	ST	isPaused

	bra.s	.doLoop
.noOneStep:
	TST.b	isPaused
	bne.s	.noPause
.doLoop:
	ENDC

	IFNE	AutoPress
	IFEQ	AutoPressHost
	IFNE	NO_VBLUNIT|NO_VDCDMA	; (0: latched at the frame's line 0, in PCE_FrameTop)
	MOVEM.L	D0-D4/A0,-(SP)
	JSR	AutoPressBits		; pad bits for this frame, the same for the whole frame
	MOVE.B	D1,AutoPressCur
	MOVE.B	D1,Regs+JoyX
	MOVEM.L	(SP)+,D0-D4/A0
	ENDC
	ENDC
	ENDC
	BSR	PCE_Start
	IFEQ	NO_PSGWAVE
	IFEQ	NO_PSGDDA
	JSR	PSGDdaFrame	; this frame's DDA samples into the play queues
	ENDC
	ENDC
.noPause:
	IFNE	LogFrame
	BSR	LogFrameState	; one serial line per frame (probe builds only)
	ENDC
	IFNE	PSGLog
	IFEQ	NO_PSGWAVE
	JSR	PSGLogFrame	; one serial line of PSG state per frame
	ENDC
	ENDC

	MOVEM.L	D0-D7/A0-A6,-(SP)
	IFNE	DbgRows
	JSR	DbgLapCpu
	ENDC

		IFNE	ShowPerformance
		bsr	TimerStop
		add.w	d0,vTimerCPUSum

		bsr	TimerStart
		ENDC

	IFEQ	NO_RTG
	TST.B	RtgOn
	BEQ.S	.agaDraw
	JSR	RtgFrame		; RTG: the whole frame in fast RAM, no AGA drawing
	IFNE	DbgRows
	JSR	DbgLapRtg
	ENDC
	BRA	.rtgDrawn
.agaDraw:
	ENDC
	IFEQ	NO_WIDE
	JSR	WideGeometry
	ENDC
	IFNE	DbgProbe
	JSR	DbgProbeScan
	ENDC
	JSR	PrintGFX
	JSR	CleanTabRefef
	IFNE	DbgRows
	JSR	DbgLapBg
	ENDC

		IFNE	ShowPerformance
		bsr	TimerStop
		add.w	d0,vTimerGFXSum

		bsr	TimerStart
		ENDC

; ---
;	SF	vBlankOccurred
;BUC2:
;	TST.B	vBlankOccurred
;	BEQ.S	BUC2
;	SF	vBlankOccurred
;	movem.l	d0/d1,-(sp)
;	move.w	#$34,d0
;	bsr	WaitRaster
;	movem.l	(sp)+,d0/d1
; ---


	IFNE	OnlyAGA
	JSR	PrintSprites_AGA
	ELSE
	JSR	PrintSprites_SAGA
	ENDC
	IFNE	DbgRows
	JSR	DbgLapSpr
	ENDC

		IFNE	ShowPerformance
		bsr	TimerStop
		add.w	d0,vTimerSPRSum

		subq.w	#1,vTimerSumCnt
		bcc.s	.skip
		bsr	DrawAmigaLoad
		ENDC
.skip:


	IFNE	ShowFps
	JSR	ImpFps
	ENDC

	IFEQ	NO_RTG
.rtgDrawn:
	ENDC
	MOVEM.L	(SP)+,D0-D7/A0-A6

	IFEQ	NO_LATESTART|NO_RTG
	TST.B	RtgOn
	BEQ.S	.noLateEnd
	JSR	LateEnd
.noLateEnd:
	ENDC

	ADDQ.L	#1,FPS_Count
	IFNE	ScrRing
	JSR	ScrRingFrame
	ENDC

	IFNE	MenuAuto
	SUBQ.L	#1,MenuAutoCnt
	BNE.S	.noMenuAuto
	MOVE.L	#MenuAuto,MenuAutoCnt
	ST	ExitToMenu		; as Esc
.noMenuAuto:
	ENDC

	IFNE	AutoExit
	ADDQ.L	#1,AutoFrames
	IFNE	ScrDump
	JSR	ScrDumpFrame
	ENDC
	IFNE	AutoMenu
	SUBQ.L	#1,AutoMenuCnt
	BNE.S	.noMenu
	MOVE.L	#AutoMenu,AutoMenuCnt
	ST	AutoMenuGo		; leave as Esc does, see Salir
	ST	ExitToMenu
.noMenu:
	ENDC
	IFNE	AutoRestart
	CMP.L	#AutoRestart,AutoFrames
	BNE.S	.noRestart
	SF	isContinue		; a new game, like Insert in the menu (OS stays frozen)
	IFD	EMBED2
	MOVE.L	#GameCart2-$80,DirCart
	MOVE.L	#GameCart2End-GameCart2,D0
	DIVU.L	#8*1024,D0
	MOVE.W	D0,PagCart
	ENDC
	MOVE.L	PILA,SP
	JMP	RestartGame
.noRestart:
	ENDC
	CMP.L	#AutoExit,AutoFrames
	BCS.S	.noAutoExit
	IFNE	AutoFreeze
	IFEQ	NO_RTG
	TST.B	RtgOn
	BEQ.S	.autoFreeze
	JSR	RtgCopy			; the held frame on the RTG screen too
	ENDC
.autoFreeze:
	BRA.S	.autoFreeze		; picture stays for a grab; vblank interrupt still runs
	ELSE
	ST	ExitToMenu
	ENDC
.noAutoExit:
	ENDC

	TST.B	ExitToMenu
	IFNE	DbgRows
	BEQ	DbgLoop
	ELSE
	BEQ	BUC
	ENDC

	JMP	Salir

; ----------------------------------

	IFEQ	NO_LATESTART|NO_RTG
; LateStart (RTG, after RtgCopy): wait until LsFrame - (LsBusy max + margin) lines
; after the vblank, or the vblank itself, then read the pad again as the vblank
; interrupt does. LateEnd (the frame's work done): LsBusy gets the lines since
; the wait ended; a frame that ran into the next vblank stops the wait for
; LsHoldN frames. Times in lines from the CIA-B TOD counter (HSYNC).
LsHoldN = 50
LateStart:
	MOVEM.L	D0-D3/A0/A3,-(SP)
	TST.W	LsHold
	BEQ.S	.go
	SUBQ.W	#1,LsHold
	BRA.S	.read
.go:	LEA	LsBusy,A0		; D2 = the slowest of the last 16 frames
	MOVEQ	#0,D2
	MOVEQ	#16-1,D1
.mx:	CMP.W	(A0)+,D2
	BCC.S	.mx1
	MOVE.W	-2(A0),D2
.mx1:	DBF	D1,.mx
	CMP.W	#1000,D2		; (not known yet, or a frame stopped by the menu)
	BHI.S	.read
	MOVE.W	D2,D1			; margin: 24 lines + a quarter
	LSR.W	#2,D1
	ADD.W	#24,D1
	ADD.W	D1,D2
	MOVE.W	LsFrame,D3		; D3 = lines after the vblank to start at
	SUB.W	D2,D3
	BLE.S	.read
.wt:	TST.B	vBlankOccurred
	BNE.S	.read
	BSR	LsTod
	SUB.W	LsVblTod,D0
	CMP.W	D3,D0
	BLT.S	.wt
.read:	MOVE.W	#$4000,$DFF09A		; the pad as the vblank interrupt reads it
	MOVE.L	JoyControlRut,A0
	JSR	(A0)
	LEA	Regs,A3
	MOVE.B	KeyX(A3),D1
	OR.B	D1,JoyX(A3)
	IFNE	AutoPress
	MOVE.B	AutoPressCur,D1
	OR.B	D1,JoyX(A3)
	ENDC
	MOVE.W	#$C000,$DFF09A
	BSR	LsTod
	MOVE.W	D0,LsStart
	MOVEM.L	(SP)+,D0-D3/A0/A3
	RTS

LateEnd:
	MOVEM.L	D0-D1/A0,-(SP)
	BSR	LsTod
	SUB.W	LsStart,D0
	MOVE.W	LsBusyIx,D1
	LEA	LsBusy,A0
	MOVE.W	D0,(A0,D1.W*2)
	ADDQ.W	#1,D1
	AND.W	#15,D1
	MOVE.W	D1,LsBusyIx
	TST.B	vBlankOccurred		; ran into the next vblank: no wait for a while
	BEQ.S	.ok
	MOVE.W	#LsHoldN,LsHold
.ok:	MOVEM.L	(SP)+,D0-D1/A0
	RTS

; LsTod: D0.W = CIA-B TOD bits 15-0 (the high byte is not read: it would latch).
LsTod:
	MOVE.L	D1,-(SP)
.r:	MOVE.B	$BFD900,D1
	MOVE.B	$BFD800,D0
	CMP.B	$BFD900,D1
	BNE.S	.r
	LSL.W	#8,D1
	MOVE.B	D0,D1
	MOVE.W	D1,D0
	MOVE.L	(SP)+,D1
	RTS

LsVblTod:	DC.W	0	; TOD at the last vblank interrupt
LsFrame:	DC.W	0	; lines between the last two (0 until known: no wait)
LsStart:	DC.W	0	; TOD when the frame's work started
LsHold:		DC.W	LsHoldN	; frames left without the wait
LsBusyIx:	DC.W	0
LsBusy:		DCB.W	16,$7FFF	; lines of work of the last 16 frames (none known: no wait)
	ENDC

DrawAmigaLoad:
	jsr	xLogInit

	lea	sTimerCPU,a0
	jsr	xLogString
	
	moveq	#0,d0
	move.w	vTimerCPUSum,d0

	bsr	.drawLoadPercent


	lea	sTimerGFX,a0
	jsr	xLogString

	moveq	#0,d0
	move.w	vTimerGFXSum,d0

	bsr	.drawLoadPercent


	lea	sTimerSPR,a0
	jsr	xLogString

	moveq	#0,d0
	move.w	vTimerSPRSum,d0

	bsr	.drawLoadPercent



	jsr	xLogDraw

	clr.w	vTimerCPUSum
	clr.w	vTimerGFXSum
	clr.w	vTimerSPRSum
	move.w	#4-1,vTimerSumCnt

	rts

.drawLoadPercent:
	lsr.w	#2,d0

	mulu	#100,d0
	divu	vTimerMaxScanLine,d0

	and.l	#$ffff,d0
	jsr	HexToDec

	jsr	xLogString
	move.b	#"%",d0
	jsr	xLogChar

	rts



sTimerCPU:	dc.b	"CPU:",0
sTimerGFX:	dc.b	" GFX:",0
sTimerSPR:	dc.b	" SPR:",0


	cnop	0,8
WaitRaster:				;Wait for scanline d0. Trashes d1.
.lo:	move.l $dff004,d1
	lsr.l #1,d1
	lsr.w #7,d1
	cmp.w d0,d1
	bne.s .lo			;wait until it matches (eq)
	rts


TimerStart:
	move.l	$dff004,vTimerInitialScanLine
	move.l	vTimerVBlanks,vTimerInitialVBlank
	rts


TimerStop:
	move.l	$dff004,d0
	move.l	vTimerVBlanks,d3
	move.l	vTimerInitialScanLine,d1
	move.l	vTimerInitialVBlank,d2

	and.l	#$0001FFFF,d1
	lsr.l	#8,d1
	and.l	#$0001FFFF,d0
	lsr.l	#8,d0

	sub.l	d2,d3

	mulu	vTimerMaxScanLine,d3

	add.w	d3,d0

	sub.w	d1,d0

	move.w	d0,vTimerResult

	rts





FPS_Current:	DC.L	0
FPS_Count:	DC.L	0
vBlank_Count:	DC.L	0


vTimerMaxScanLine:	dc.w	0
vTimerInitialScanLine:	dc.l	0
vTimerInitialVBlank:	dc.l	0
vTimerVBlanks:		dc.l	0

vTimerResult:	dc.w	0

vTimerCPUSum:	dc.w	0
vTimerGFXSum:	dc.w	0
vTimerSPRSum:	dc.w	0

vTimerSumCnt:	dc.w	0



; -----------------------------------------------------------------
; LogFrame probe (build with -DLogFrame=1 -DLOG_ENABLED=1): after each
; emulated frame, send one line on the serial port:
; F:frame PC:pc A X Y P SP R5:VDC control IFF IRQ:pending ST:status
	IFNE	LogFrame
LogFrameState:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	TST.B	LogFrameInit
	BNE.S	.inited
	ST	LogFrameInit
	MOVE.W	#3,$DFF032		; SERPER: fastest rate (WinUAE TCP serial)
.inited:
	MOVE.L	A5,D0
	SUB.W	(A2),D0
	MOVE.W	D0,LogFramePC
	LogString "F:"
	MOVE.W	FPS_Count+2,D0
	LogHexWord D0
	LogString " PC:"
	LogHexWord LogFramePC
	LogString " A:"
	LogHexByte D7
	LogString " X:"
	LogHexByte D4
	LogString " Y:"
	LogHexByte D5
	LogString " P:"
	LogHexByte D3
	LogString " SP:"
	LogHexByte D6
	LEA	Regs,A3
	LogString " R5:"
	LogHexWord VDP_Regs+(5*2)
	LogString " IFF:"
	LogHexByte IFF(A3)
	LogString " IRQ:"
	LogHexByte IRQ_Pending(A3)
	LogString " ST:"
	LogHexByte Status(A3)
	LogString " MASK:"
	LogHexByte IOAM+$1402
	IFNE	LogPCs
	LogString " L:"
	LEA	LogPCbuf,A0
	MOVEQ	#8,D1
LogPCsLp:	MOVE.W	(A0)+,D0
	MOVEM.L	D1/A0,-(SP)
	LogHexWord D0
	LogString " "
	MOVEM.L	(SP)+,D1/A0
	DBF	D1,LogPCsLp
	LogString "S:"
	MOVEQ	#0,D1
	MOVE.B	D6,D1
	LEA	IRAM+$101,A0
	ADD.L	D1,A0
	MOVEQ	#7,D1
LogPCsLs:	MOVE.B	(A0)+,D0
	MOVEM.L	D1/A0,-(SP)
	LogHexByte D0
	MOVEM.L	(SP)+,D1/A0
	DBF	D1,LogPCsLs
	ENDC
	IFNE	LogSum
	LEA	IRAM,A0
	MOVE.W	#(8*1024/4)-1,D1
	BSR	LogSumRut
	LogString " RAM:"
	LogHexLong D0
	LEA	VRAM,A0
	MOVE.W	#(64*1024/4)-1,D1
	BSR	LogSumRut
	LogString " VRAM:"
	LogHexLong D0
	LEA	VDP_Regs,A0
	MOVE.W	#(512/4)-1,D1
	BSR	LogSumRut
	MOVE.L	D0,D2
	LEA	VDP_Pal,A0
	MOVE.W	#(1024/4)-1,D1
	BSR	LogSumRut
	ADD.L	D2,D0
	LogString " VDC:"
	LogHexLong D0
	LEA	SpriteCoor,A0
	MOVE.W	#(512/4)-1,D1
	BSR	LogSumRut
	LogString " SAT:"
	LogHexLong D0
	ENDC
	LogEnter
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
	IFNE	LogSum
LogSumRut:			; D0 = rotate-and-add sum of D1+1 longs at A0
	MOVEQ	#0,D0
.l:	ROL.L	#1,D0
	ADD.L	(A0)+,D0
	DBF	D1,.l
	RTS
	ENDC
LogFrameInit:	DC.B	0
	EVEN
LogFramePC:	DC.W	0
	IFNE	LogPCs
LogPCbuf:	DS.W	9
	ENDC
	ENDC

	IFNE	AutoExit
; AutoExit test runs: "frames=$x vblanks=$x" + stack and guard checks to PROGDIR:AmiPCE.result.
; frames = emulated PC Engine frames, vblanks = Amiga vblanks since the start.
MemCheckInit:			; fill guards and the unused stack with GuardFill
	LEA	AutoGuardTab,A1
.g:	MOVE.L	(A1)+,D0
	BEQ.S	.stack
	MOVE.L	D0,A0
	MOVE.W	#GuardLongs-1,D1
.f:	MOVE.L	#GuardFill,(A0)+
	DBF	D1,.f
	BRA.S	.g
.stack:	MOVE.L	$4.W,A6
	SUB.L	A1,A1
	JSR	-$126(A6)		; FindTask(0)
	MOVE.L	D0,A0
	MOVE.L	$3A(A0),D0		; tc_SPLower
	ADDQ.L	#3,D0
	AND.W	#$FFFC,D0
	MOVE.L	D0,AutoStackLower
	MOVE.L	$3E(A0),D1		; tc_SPUpper
	SUB.L	D0,D1
	MOVE.L	D1,AutoStackSize
	MOVE.L	D0,A0
	LEA	-512(SP),A1		; leave the live part alone
.s:	CMP.L	A1,A0
	BCC.S	.done
	MOVE.L	#GuardFill,(A0)+
	BRA.S	.s
.done:
	IFNE	CodeCheck
	BSR	CodeSnap
	ENDC
	RTS

GuardFill=$DEADBEEF

AutoWriteResult:
	IFNE	AutoMenu
	MOVE.L	AutoMenuBuf,D0
	BEQ.S	.nomb
	MOVE.L	D0,A1
	MOVE.L	AutoMenuBufLen,D0
	MOVE.L	$4.W,A6
	JSR	-$D2(A6)		; FreeMem
	CLR.L	AutoMenuBuf
.nomb:
	ENDC
	IFNE	CodeCheck
	BSR	CodeDiff
	ENDC
	IFNE	StateDump
	BSR	StateDumpWrite
	ENDC
	IFNE	ScrDump
	BSR	ScrDumpWrite
	ENDC
	IFNE	DdaDump
	JSR	DdaDumpWrite
	ENDC
	IFNE	StripLog
	JSR	StripLogWrite
	ENDC
	IFNE	ProfOn
	BSR	ProfWrite		; before the result: the rig stops once that file is there
	ENDC
	LEA	AutoHex1,A0
	MOVE.L	AutoFrames,D0
	BSR	AutoHex
	LEA	AutoHex2,A0
	MOVE.L	vTimerVBlanks,D0
	BSR	AutoHex
	MOVE.L	AutoStackLower,A0	; stack: bytes never touched at the bottom
	MOVEQ	#0,D0
.st:	CMP.L	#GuardFill,(A0)+
	BNE.S	.std
	ADDQ.L	#4,D0
	BRA.S	.st
.std:	LEA	AutoHex3,A0
	BSR	AutoHex
	LEA	AutoHex4,A0
	MOVE.L	AutoStackSize,D0
	BSR	AutoHex
	LEA	AutoGuardTab,A1		; guards: first bad long << 16 | bad longs
	LEA	AutoHex5,A2
.gn:	MOVE.L	(A1)+,D0
	BEQ.S	.gd
	MOVE.L	D0,A0
	MOVE.L	#$FFFF0000,D0
	MOVEQ	#0,D1
.gl:	CMP.L	#GuardFill,(A0)+
	BEQ.S	.gok
	TST.L	D0
	BPL.S	.gcnt
	MOVE.W	D1,D0
	SWAP	D0
	CLR.W	D0
.gcnt:	ADDQ.W	#1,D0
.gok:	ADDQ.W	#1,D1
	CMP.W	#GuardLongs,D1
	BCS.S	.gl
	MOVE.L	A2,A0
	BSR	AutoHex
	LEA	9(A2),A2
	BRA.S	.gn
.gd:
	LEA	Guard_TablB,A1		; first 16 longs of the TablB guard (after SpriteDirtyArea1)
	LEA	AutoHex6,A2
	MOVEQ	#16-1,D3
.gt:	MOVE.L	(A1)+,D0
	MOVE.L	A2,A0
	BSR	AutoHex
	LEA	9(A2),A2
	DBF	D3,.gt
	IFNE	DdaStat
	JSR	DdaStatFill
	ENDC
	IFNE	DbgRows
	JSR	DbgAutoFill
	ENDC
	MOVE.L	$4.W,A6
	LEA	AutoDosName,A1
	MOVEQ	#0,D0
	JSR	-$228(A6)		; OpenLibrary
	TST.L	D0
	BEQ.S	.done
	MOVE.L	D0,A6
	MOVE.L	#AutoFileName,D1
	MOVE.L	#1006,D2		; MODE_NEWFILE
	JSR	-30(A6)			; Open
	MOVE.L	D0,D4
	BEQ.S	.close
	MOVE.L	D4,D1
	MOVE.L	#AutoText,D2
	MOVE.L	#AutoTextEnd-AutoText,D3
	JSR	-48(A6)			; Write
	IFNE	DdaStat
	MOVE.L	D4,D1
	MOVE.L	#DdaStatTxt,D2
	MOVE.L	#DdaStatEnd-DdaStatTxt,D3
	JSR	-48(A6)			; Write
	ENDC
	IFNE	DbgRows
	MOVE.L	D4,D1
	MOVE.L	#DbgAutoTxt,D2
	MOVE.L	#DbgAutoTxtEnd-DbgAutoTxt,D3
	JSR	-48(A6)			; Write
	ENDC
	IFNE	CodeCheck
	MOVE.L	D4,D1
	MOVE.L	#CodeDiffTxt,D2
	MOVE.L	CodeDiffPtr,D3
	SUB.L	D2,D3
	JSR	-48(A6)			; Write
	ENDC
	MOVE.L	D4,D1
	JSR	-36(A6)			; Close
.close:
	MOVE.L	A6,A1
	MOVE.L	$4.W,A6
	JSR	-$19E(A6)		; CloseLibrary
.done:
	MOVEQ	#0,D0
	RTS

	IFNE	AutoPress
AutoPressBits:				; D1.b = OR of the bits whose frame range holds AutoFrames
	LEA	AutoPressTab,A0
	MOVE.L	AutoFrames,D0
	MOVEQ	#0,D1
.next:	MOVE.W	(A0)+,D2		; first frame (-1 ends the table)
	BMI.S	.done
	MOVE.W	(A0)+,D3		; last frame
	MOVE.W	(A0)+,D4		; JoyX bits
	CMP.W	D2,D0
	BCS.S	.next
	CMP.W	D3,D0
	BHI.S	.next
	OR.B	D4,D1
	BRA.S	.next
.done:	RTS
AutoPressCur:	DC.B	0		; bits for the current PCE frame
	EVEN
	ENDC

AutoHex:				; D0 -> 8 hex digits at (A0)
	MOVEQ	#7,D2
.l:	ROL.L	#4,D0
	MOVE.W	D0,D1
	AND.W	#$F,D1
	MOVE.B	(AutoDigits,PC,D1.W),(A0)+
	DBF	D2,.l
	RTS

AutoDigits:	DC.B	"0123456789ABCDEF"
	CNOP	0,4

	IFNE	AutoMenu
; OS alive between two games, as the menu: the ROM goes into new memory
; (pages * $2080 + $80, MEMF_PUBLIC|MEMF_CLEAR, the old buffer freed first,
; like Insert), then a wait so the OS runs its interrupts and tasks.
AutoMenuVisit:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	ADDQ.L	#1,AutoMenuTrips
	IFEQ	AutoMenuCont
	LEA	GameCart,A2
	MOVE.L	#GameCartEnd-GameCart,D2
	IFD	EMBED2
	NOT.B	AutoMenuWhich
	BEQ.S	.rom1
	LEA	GameCart2,A2
	MOVE.L	#GameCart2End-GameCart2,D2
.rom1:
	ENDC
	MOVE.L	D2,D0
	DIVU.L	#8*1024,D0
	MOVE.W	D0,PagCart
	MULU	#$2080,D0
	ADD.L	#$80,D0
	MOVE.L	D0,D3
	MOVE.L	$4.W,A6
	MOVE.L	AutoMenuBuf,D0
	BEQ.S	.nofree
	MOVE.L	D0,A1
	MOVE.L	AutoMenuBufLen,D0
	JSR	-$D2(A6)		; FreeMem (Insert frees the last ROM first)
	CLR.L	AutoMenuBuf
.nofree:
	MOVE.L	D3,D0
	MOVE.L	#$00010001,D1
	JSR	-$C6(A6)		; AllocMem
	TST.L	D0
	BEQ.S	.embedded
	MOVE.L	D0,AutoMenuBuf
	MOVE.L	D3,AutoMenuBufLen
	MOVE.L	D0,DirCart
	MOVE.L	A2,A0
	MOVE.L	D0,A1
	ADD.L	#$80,A1
	MOVE.L	D2,D0
	JSR	-$270(A6)		; CopyMem
	BRA.S	.loaded
.embedded:
	LEA	-$80(A2),A0
	MOVE.L	A0,DirCart
.loaded:
	ENDC
	MOVE.L	$4.W,A6
	LEA	AutoDosName,A1
	MOVEQ	#0,D0
	JSR	-$228(A6)		; OpenLibrary
	TST.L	D0
	BEQ.S	.nodos
	MOVE.L	D0,A6
	MOVE.L	#AutoMenuWait,D1
	JSR	-198(A6)		; Delay
	MOVE.L	A6,A1
	MOVE.L	$4.W,A6
	JSR	-$19E(A6)		; CloseLibrary
.nodos:
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
AutoMenuWait=50			; ticks with the OS alive
AutoMenuCnt:	DC.L	AutoMenu
AutoMenuTrips:	DC.L	0
AutoMenuBuf:	DC.L	0
AutoMenuBufLen:	DC.L	0
AutoMenuGo:	DC.B	0
AutoMenuWhich:	DC.B	0
	CNOP	0,4
	ENDC

	IFNE	CodeCheck
; Copy of the code hunk (CodeHunkStart .. Guard_CodeEnd) taken at the start;
; at exit the changed bytes are listed as "+offset length" (runs merged when
; less than 16 bytes apart; offsets from CodeHunkStart = the start of the hunk).
CodeSnap:
	MOVE.L	#Guard_CodeEnd-CodeHunkStart,D0
	MOVEQ	#1,D1			; MEMF_PUBLIC
	MOVE.L	$4.W,A6
	JSR	-$C6(A6)		; AllocMem
	MOVE.L	D0,CodeSnapBuf
	BEQ.S	.r
	LEA	CodeHunkStart,A0
	MOVE.L	D0,A1
	MOVE.L	#Guard_CodeEnd-CodeHunkStart,D0
	JSR	-$270(A6)		; CopyMem
.r:	RTS

CodeDiff:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	LEA	CodeDiffTxt,A2
	MOVE.L	CodeSnapBuf,D0
	BEQ	.out
	MOVE.L	D0,A1
	LEA	CodeHunkStart,A0
	MOVE.L	#Guard_CodeEnd-CodeHunkStart,D3
	MOVEQ	#0,D4			; offset of the next byte to compare
	MOVE.W	#CodeDiffMax-1,D5
.scan:	CMP.L	D3,D4
	BCC	.out
	CMP.L	#CodeDiffTxt-CodeHunkStart,D4	; skip the list itself
	BNE.S	.scan1
	MOVE.L	#CodeDiffEnd-CodeHunkStart,D4
	MOVE.L	CodeSnapBuf,A1
	ADD.L	D4,A1
	LEA	CodeHunkStart,A0
	ADD.L	D4,A0
	BRA.S	.scan
.scan1:	ADDQ.L	#1,D4
	CMPM.B	(A0)+,(A1)+
	BEQ.S	.scan
	MOVE.L	D4,D6
	SUBQ.L	#1,D6			; run start
	MOVE.L	D4,D7			; end of the last differing byte (exclusive)
.ext:	CMP.L	D3,D4
	BCC.S	.emit
	CMP.L	#CodeDiffTxt-CodeHunkStart,D4
	BEQ.S	.emit
	MOVE.L	D4,D0
	SUB.L	D7,D0
	CMP.L	#16,D0
	BCC.S	.emit
	ADDQ.L	#1,D4
	CMPM.B	(A0)+,(A1)+
	BEQ.S	.ext
	MOVE.L	D4,D7
	BRA.S	.ext
.emit:	MOVE.B	#'+',(A2)+
	MOVE.L	D6,D0
	MOVE.L	A2,A0
	BSR	AutoHex
	MOVE.B	#' ',8(A2)
	LEA	9(A2),A0
	MOVE.L	D7,D0
	SUB.L	D6,D0
	BSR	AutoHex
	MOVE.B	#10,17(A2)
	LEA	18(A2),A2
	MOVE.L	CodeSnapBuf,A1		; resume after the run
	ADD.L	D4,A1
	LEA	CodeHunkStart,A0
	ADD.L	D4,A0
	DBF	D5,.scan
.out:	MOVE.L	#'end ',(A2)+
	MOVE.B	#10,(A2)+
	MOVE.L	A2,CodeDiffPtr
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
CodeDiffMax=400
CodeSnapBuf:	DC.L	0
CodeDiffPtr:	DC.L	CodeDiffTxt
CodeDiffTxt:	DS.B	(CodeDiffMax+1)*(1+8+1+8+1)+8
CodeDiffEnd:
	CNOP	0,4
	ENDC
	IFNE	ProfOn
; Sampling profiler: CIA-B timer A (or B if A is taken) interrupts at level 6
; every ProfLatch E-clock ticks; the handler adds the interrupted PC to a
; histogram of the code hunk (one long per 2 bytes). ProfWrite saves
; "PROF", CodeHunkStart, hunk bytes, samples outside the hunk, then the
; histogram to PROGDIR:AmiPCE.prof (tools/profmap.py maps it to the source).
ProfLatch=355			; 709379 Hz / 355 = ~2 kHz
ProfOut=ProfHead+12
ProfInit:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	TST.L	ProfRes
	BNE.S	.done			; restarted game: keep the timer we have
	MOVE.L	$4.W,A6
	LEA	ProfCiabName,A1
	JSR	-$1F2(A6)		; OpenResource
	MOVE.L	D0,ProfRes
	BEQ.S	.done
	MOVE.L	D0,A6
	LEA	ProfIntNode,A1
	MOVEQ	#0,D0			; timer A
	JSR	-6(A6)			; AddICRVector
	TST.L	D0
	BEQ.S	.gotA
	LEA	ProfIntNode,A1
	MOVEQ	#1,D0			; timer B
	JSR	-6(A6)
	TST.L	D0
	BNE.S	.none
	MOVE.B	#1,ProfBit
	BRA.S	.done
.gotA:	CLR.B	ProfBit
	BRA.S	.done
.none:	CLR.L	ProfRes			; both taken: no profile
.done:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

ProfStart:				; OS frozen: our level 6 vector, timer running
	MOVEM.L	D0/A0,-(SP)
	TST.L	ProfRes
	BEQ	.x
	MOVE.L	VBRPun,A0
	MOVE.L	$78(A0),D0
	CMP.L	#ProfInt,D0
	BEQ.S	.vec
	MOVE.L	D0,ProfOldL6
	MOVE.L	#ProfInt,$78(A0)
.vec:	TST.B	ProfBit
	BNE.S	.tb
	AND.B	#$C0,$BFDE00		; CRA: stop, continuous, E clock
	MOVE.B	#ProfLatch&$FF,$BFD400
	MOVE.B	#ProfLatch>>8,$BFD500
	OR.B	#$11,$BFDE00		; force load, start
	MOVE.B	#$81,$BFDD00		; ICR: timer A on
	BRA.S	.on
.tb:	AND.B	#$80,$BFDF00		; CRB: stop, continuous, E clock
	MOVE.B	#ProfLatch&$FF,$BFD600
	MOVE.B	#ProfLatch>>8,$BFD700
	OR.B	#$11,$BFDF00
	MOVE.B	#$82,$BFDD00		; ICR: timer B on
.on:	MOVE.W	#$2000,$DFF09C
	MOVE.W	#$A000,$DFF09A		; EXTER on
.x:	MOVEM.L	(SP)+,D0/A0
	RTS

	CNOP	0,4
ProfInt:
	MOVEM.L	D0/A0,-(SP)
	MOVE.B	$BFDD00,D0		; CIA-B ICR: read = acknowledge
	MOVE.W	#$2000,$DFF09C
	AND.B	#$03,D0			; one of our timers
	BEQ.S	.x
	MOVE.L	8+2(SP),D0		; interrupted PC
	SUB.L	#CodeHunkStart,D0
	CMP.L	#ProfCodeEnd-CodeHunkStart,D0
	BCC.S	.out
	LSR.L	#1,D0
	LEA	ProfHist,A0
	ADDQ.L	#1,(A0,D0.L*4)
	BRA.S	.x
.out:	ADDQ.L	#1,ProfOut
.x:	MOVE.W	#$2000,$DFF09C
	MOVEM.L	(SP)+,D0/A0
	RTE

ProfStop:				; OS still frozen
	MOVEM.L	D0/A0,-(SP)
	TST.L	ProfRes
	BEQ.S	.x
	MOVE.W	#$2000,$DFF09A		; EXTER off (DescongelaAMIGA puts the OS mask back)
	AND.B	#$FE,$BFDE00
	AND.B	#$FE,$BFDF00		; both timers stopped (only ours runs: the OS is frozen)
	MOVE.L	VBRPun,A0
	MOVE.L	ProfOldL6,$78(A0)
.x:	MOVEM.L	(SP)+,D0/A0
	RTS

ProfWrite:				; OS alive again
	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.L	ProfRes,D0
	BEQ.S	.x
	MOVE.L	D0,A6
	LEA	ProfIntNode,A1
	MOVEQ	#0,D0
	MOVE.B	ProfBit,D0
	JSR	-12(A6)			; RemICRVector
	MOVE.L	$4.W,A6
	LEA	AutoDosName,A1
	MOVEQ	#0,D0
	JSR	-$228(A6)		; OpenLibrary
	TST.L	D0
	BEQ.S	.x
	MOVE.L	D0,A6
	MOVE.L	#ProfFileName,D1
	MOVE.L	#1006,D2		; MODE_NEWFILE
	JSR	-30(A6)			; Open
	MOVE.L	D0,D4
	BEQ.S	.close
	MOVE.L	#'PROF',ProfHead
	MOVE.L	#CodeHunkStart,ProfHead+4
	MOVE.L	#ProfCodeEnd-CodeHunkStart,ProfHead+8
	MOVE.L	D4,D1
	MOVE.L	#ProfHead,D2
	MOVE.L	#ProfHist+((ProfCodeEnd-CodeHunkStart+2)/2)*4-ProfHead,D3
	JSR	-48(A6)			; Write
	MOVE.L	D4,D1
	JSR	-36(A6)			; Close
.close:	MOVE.L	A6,A1
	MOVE.L	$4.W,A6
	JSR	-$19E(A6)		; CloseLibrary
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

ProfRes:	DC.L	0
ProfOldL6:	DC.L	0
ProfIntNode:	DC.L	0,0		; struct Interrupt: ln_Succ, ln_Pred
	DC.B	2,0			; ln_Type NT_INTERRUPT, ln_Pri
	DC.L	ProfCiabName,0,ProfIntCode	; ln_Name, is_Data, is_Code
ProfIntCode:	RTS			; only if the OS ever calls it (not while frozen)
ProfBit:	DC.B	0
ProfCiabName:	DC.B	"ciab.resource",0
ProfFileName:	DC.B	"PROGDIR:AmiPCE.prof",0
	CNOP	0,4
	ENDC
AutoDosName:	DC.B	"dos.library",0
	IFNE	ScrDump
ScrDumpFrame:				; 128 bytes a frame: frame (long), then (line, BXR, BYR) entries, -1
	MOVEM.L	D0/A0/A1,-(SP)
	MOVE.L	AutoFrames,D0
	SUB.L	#ScrDump,D0
	BCS.S	.x
	CMP.L	#1000,D0
	BCC.S	.x
	LSL.L	#7,D0
	LEA	(ScrDumpBuf,D0.L),A1
	MOVE.L	AutoFrames,(A1)+
	MOVE.L	Regs+ScrollChangesNext,A0
	MOVEQ	#19,D0
.c:	MOVE.W	(A0)+,(A1)+
	BMI.S	.x
	MOVE.W	(A0)+,(A1)+
	MOVE.W	(A0)+,(A1)+
	DBF	D0,.c
.x:	MOVEM.L	(SP)+,D0/A0/A1
	RTS
ScrDumpName:	DC.B	"PROGDIR:scrdump.bin",0
	EVEN
ScrDumpWrite:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.L	$4.W,A6
	LEA	AutoDosName,A1
	MOVEQ	#0,D0
	JSR	-$228(A6)		; OpenLibrary
	TST.L	D0
	BEQ.S	.x
	MOVE.L	D0,A6
	MOVE.L	#ScrDumpName,D1
	MOVE.L	#1006,D2
	JSR	-30(A6)			; Open
	MOVE.L	D0,D4
	BEQ.S	.cl
	MOVE.L	D4,D1
	MOVE.L	#ScrDumpBuf,D2
	MOVE.L	#1000*128,D3
	JSR	-48(A6)			; Write
	MOVE.L	D4,D1
	JSR	-36(A6)			; Close
.cl:	MOVE.L	A6,A1
	MOVE.L	$4.W,A6
	JSR	-$19E(A6)		; CloseLibrary
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
	ENDC
	IFNE	StateDump
StateDumpName:	DC.B	"PROGDIR:pcestate.bin",0
	EVEN
StateDumpTab:	DC.L	IRAM,8*1024, VRAM,64*1024, VDP_Regs,64, VDP_Pal,1024, SpriteCoor,512
	IFNE	VdcLog
	DC.L	VdcLogBuf,VDCLOGMAX*16
	ENDC
	DC.L	0
	IFNE	VdcLog
VDCLOGMAX=32768
VdcLogN:	DC.L	0
VdcLogLast:	DC.W	-1
; D0 = 1: high port, D1 = register. 16 bytes a write: frame, line, reg, MPR2, value, PC, MPR3, MPR4, ($EE), S
VdcLogW:
	TST.W	D0
	BEQ	.q
	CMP.W	#2,D1
	BEQ	.q
	CMP.W	#6,D1
	BCS.S	.go
	CMP.W	#8,D1
	BLS.S	.q
.go:	MOVEM.L	D0/A0,-(SP)
	MOVE.L	VdcLogN,D0
	CMP.L	#VDCLOGMAX,D0
	BCC	.x
	LSL.L	#4,D0
	LEA	(VdcLogBuf,D0.L),A0
	TST.W	D1			; (HuZERO hammers R0 with zeros)
	BNE.S	.nz
	MOVE.W	VDP_Regs,D0
	CMP.W	VdcLogLast,D0
	BEQ	.x
	MOVE.W	D0,VdcLogLast
.nz:
	ADDQ.L	#1,VdcLogN
	MOVE.W	AutoFrames+2,(A0)+
	MOVE.W	Regs+ScanLine,(A0)+
	MOVE.B	D1,(A0)+
	MOVE.B	Regs+TabMap+2,(A0)+
	MOVE.W	(VDP_Regs.L,D1.W*2),(A0)+
	MOVE.L	A5,D0
	SUB.W	(A2),D0
	MOVE.W	D0,(A0)+
	MOVE.B	Regs+TabMap+3,(A0)+
	MOVE.B	Regs+TabMap+4,(A0)+
	MOVE.B	IRAM+$EE,(A0)+
	MOVE.B	IRAM+$EF,(A0)+
	MOVE.W	D6,(A0)+
.x:	MOVEM.L	(SP)+,D0/A0
.q:	RTS
	ENDC
StateDumpWrite:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.L	$4.W,A6
	LEA	AutoDosName,A1
	MOVEQ	#0,D0
	JSR	-$228(A6)		; OpenLibrary
	TST.L	D0
	BEQ.S	.x
	MOVE.L	D0,A6
	MOVE.L	#StateDumpName,D1
	MOVE.L	#1006,D2
	JSR	-30(A6)			; Open
	MOVE.L	D0,D4
	BEQ.S	.cl
	LEA	StateDumpTab,A2
.w:	MOVE.L	(A2)+,D2
	BEQ.S	.c
	MOVE.L	(A2)+,D3
	MOVE.L	D4,D1
	JSR	-48(A6)			; Write
	BRA.S	.w
.c:	MOVE.L	D4,D1
	JSR	-36(A6)			; Close
.cl:	MOVE.L	A6,A1
	MOVE.L	$4.W,A6
	JSR	-$19E(A6)		; CloseLibrary
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
	ENDC
	IFNE	DdaDump
DdaDumpSize=4000000
DdaDumpWrite:				; OS alive again: DdaDumpBuf (PSG.asm records) to PROGDIR:AmiPCE.dda
	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.L	$4.W,A6
	LEA	AutoDosName,A1
	MOVEQ	#0,D0
	JSR	-$228(A6)		; OpenLibrary
	TST.L	D0
	BEQ.S	.x
	MOVE.L	D0,A6
	MOVE.L	#DdaDumpName,D1
	MOVE.L	#1006,D2		; MODE_NEWFILE
	JSR	-30(A6)			; Open
	MOVE.L	D0,D4
	BEQ.S	.cl
	MOVE.L	D4,D1
	MOVE.L	#DdaDumpBuf,D2
	MOVE.L	DdaDumpPtr,D3
	SUB.L	D2,D3
	JSR	-48(A6)			; Write
	MOVE.L	D4,D1
	JSR	-36(A6)			; Close
.cl:	MOVE.L	A6,A1
	MOVE.L	$4.W,A6
	JSR	-$19E(A6)		; CloseLibrary
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
DdaDumpName:	DC.B	"PROGDIR:AmiPCE.dda",0
	EVEN
	ENDC
	IFNE	DdaStat
; DDA health line of the result file (counters in PSG.asm):
; under = a running stream found its queue empty (gap); holds = hold buffers
; given (priming, gaps, stream ends); qmin/qmax = buffers waiting when one was
; taken; words = sample words handed to Paula; starts = voice starts; lost =
; streams that lost their voice; skip = buffers dropped by the latency cap;
; drop = frames dropped with the queue full; queued = buffers queued; tick =
; of those, by timer tick.
DdaStatFill:
	MOVEM.L	D0-D2/A0-A1,-(SP)
	LEA	DdaStatTab,A1
.f:	MOVE.L	(A1)+,D0		; field
	BEQ.S	.x
	MOVE.L	D0,-(SP)
	MOVE.L	(A1)+,A0		; counter
	MOVE.L	(A0),D0
	MOVE.L	(SP)+,A0
	BSR	AutoHex
	BRA.S	.f
.x:	MOVEQ	#0,D0
	MOVE.W	PSGDdaUnder,D0
	LEA	DdaStH1,A0
	BSR	AutoHex
	MOVEQ	#0,D0
	MOVE.B	DdaStQMin,D0
	LEA	DdaStH3,A0
	BSR	AutoHex
	MOVEQ	#0,D0
	MOVE.B	DdaStQMax,D0
	LEA	DdaStH4,A0
	BSR	AutoHex
	IFEQ	NO_DDAQUEUE
	MOVEQ	#0,D0
	MOVE.W	PSGDdaSkip,D0
	LEA	DdaStH8,A0
	BSR	AutoHex
	ENDC
	MOVEM.L	(SP)+,D0-D2/A0-A1
	RTS
DdaStatTab:	DC.L	DdaStH2,DdaStHolds,DdaStH5,DdaStWords,DdaStH6,DdaStStarts,DdaStH7,DdaStLost
	DC.L	DdaStH9,DdaStDrop,DdaStH10,DdaStQueued,DdaStH11,DdaStTick,DdaStH12,DdaStTrim,0
DdaStatTxt:	DC.B	"dda under=$"
DdaStH1:	DC.B	"00000000 holds=$"
DdaStH2:	DC.B	"00000000 qmin=$"
DdaStH3:	DC.B	"00000000 qmax=$"
DdaStH4:	DC.B	"00000000 words=$"
DdaStH5:	DC.B	"00000000 starts=$"
DdaStH6:	DC.B	"00000000 lost=$"
DdaStH7:	DC.B	"00000000 skip=$"
DdaStH8:	DC.B	"00000000 drop=$"
DdaStH9:	DC.B	"00000000 queued=$"
DdaStH10:	DC.B	"00000000 tick=$"
DdaStH11:	DC.B	"00000000 trim=$"
DdaStH12:	DC.B	"00000000",10
DdaStatEnd:
	EVEN
	ENDC
AutoFileName:	DC.B	"PROGDIR:AmiPCE.result",0
AutoText:	DC.B	"frames=$"
AutoHex1:	DC.B	"00000000 vblanks=$"
AutoHex2:	DC.B	"00000000 stackfree=$"
AutoHex3:	DC.B	"00000000 stacksize=$"
AutoHex4:	DC.B	"00000000",10
	DC.B	"guards CodeEnd PantA PantB GrafA GrafB TablA TablB JuegoA JuegoB (first<<16|count, FFFF0000 = clean):",10
AutoHex5:	DC.B	"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",10
	DC.B	"TablB guard:",10
AutoHex6:	DC.B	"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 "
	DC.B	"00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000",10
AutoTextEnd:
	CNOP	0,4
AutoFrames:	DC.L	0
AutoStackLower:	DC.L	0
AutoStackSize:	DC.L	0
AutoGuardTab:	DC.L	Guard_CodeEnd,Guard_PantA,Guard_PantB,Guard_GrafA,Guard_GrafB
	DC.L	Guard_TablA,Guard_TablB,Guard_JuegoA,Guard_JuegoB,0
	ENDC

	INCLUDE "PCE.asm"



	INCLUDE "VDP_AGA.asm"
	INCLUDE "VDP_SAGA.asm"



	INCLUDE "PSG.asm"
	IFNE	DbgRows
	INCLUDE "DbgRows.asm"
	ENDC
	IFNE	AGC
	IFEQ	NO_RTG
	INCLUDE	"AGC.asm"	; in the code hunk (no sections of its own)
	ENDC
	ENDC


; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	CNOP	0,8
JoyControlPrg:
	DC.L	LeeJoyStick
	DC.L	LeeTeclado
	DC.L	LeeCD32Joypad
	DC.L	LeeJoypad

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-















; <=--------------------------------------------------------------------=>
; <=--------------------------------------------------------------------=>
; <=--------------------------------------------------------------------=>
; <=--------------------------------------------------------------------=>
; <=--------------------------------------------------------------------=>
; <=--------------------------------------------------------------------=>
; <=--------------------------------------------------------------------=>



; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-






; ---------------------------------=> Calcula e imprime fps
	IFNE	ShowFps
	CNOP	0,4
ImpFps:
	MOVE.W	#$4000,$DFF09A

FpsRutCon:
	move.l	FPS_Current,D1
	cmp.l	#399,d1
	bcs.s	ShoFpsCon
	move.l	#399,d1

ShoFpsCon:
	MOVE.W	(HexDecTab.W,PC,D1.W*2),D0

	MOVE.W	D0,D1
	LSR.W	#8,D1
	AND.W	#$000F,D1
	LEA	(Font,D1.W),A0
	LEA	Panel+1,A1
	REPT	8
	MOVE.B	(A0),(A1)
	ADD.W	#10,A0
	ADD.W	#32,A1
	ENDR

	MOVE.W	D0,D1
	LSR.W	#4,D1
	AND.W	#$000F,D1
	LEA	(Font,D1.W),A0
	LEA	Panel+2,A1
	REPT	8
	MOVE.B	(A0),(A1)
	ADD.W	#10,A0
	ADD.W	#32,A1
	ENDR

	MOVE.W	D0,D1
	AND.W	#$000F,D1
	LEA	(Font,D1.W),A0
	LEA	Panel+3,A1
	REPT	8
	MOVE.B	(A0),(A1)
	ADD.W	#10,A0
	ADD.W	#32,A1
	ENDR

	MOVE.W	#$C000,$DFF09A
SkipFpsRut:

	RTS




	CNOP	0,8
HexDecTab:
	DC.W	$00,$01,$02,$03,$04,$05,$06,$07,$08,$09
	DC.W	$10,$11,$12,$13,$14,$15,$16,$17,$18,$19
	DC.W	$20,$21,$22,$23,$24,$25,$26,$27,$28,$29
	DC.W	$30,$31,$32,$33,$34,$35,$36,$37,$38,$39
	DC.W	$40,$41,$42,$43,$44,$45,$46,$47,$48,$49
	DC.W	$50,$51,$52,$53,$54,$55,$56,$57,$58,$59
	DC.W	$60,$61,$62,$63,$64,$65,$66,$67,$68,$69
	DC.W	$70,$71,$72,$73,$74,$75,$76,$77,$78,$79
	DC.W	$80,$81,$82,$83,$84,$85,$86,$87,$88,$89
	DC.W	$90,$91,$92,$93,$94,$95,$96,$97,$98,$99
	DC.W	$100,$101,$102,$103,$104,$105,$106,$107,$108,$109
	DC.W	$110,$111,$112,$113,$114,$115,$116,$117,$118,$119
	DC.W	$120,$121,$122,$123,$124,$125,$126,$127,$128,$129
	DC.W	$130,$131,$132,$133,$134,$135,$136,$137,$138,$139
	DC.W	$140,$141,$142,$143,$144,$145,$146,$147,$148,$149
	DC.W	$150,$151,$152,$153,$154,$155,$156,$157,$158,$159
	DC.W	$160,$161,$162,$163,$164,$165,$166,$167,$168,$169
	DC.W	$170,$171,$172,$173,$174,$175,$176,$177,$178,$179
	DC.W	$180,$181,$182,$183,$184,$185,$186,$187,$188,$189
	DC.W	$190,$191,$192,$193,$194,$195,$196,$197,$198,$199
	DC.W	$200,$201,$202,$203,$204,$205,$206,$207,$208,$209
	DC.W	$210,$211,$212,$213,$214,$215,$216,$217,$218,$219
	DC.W	$220,$221,$222,$223,$224,$225,$226,$227,$228,$229
	DC.W	$230,$231,$232,$233,$234,$235,$236,$237,$238,$239
	DC.W	$240,$241,$242,$243,$244,$245,$246,$247,$248,$249
	DC.W	$250,$251,$252,$253,$254,$255,$256,$257,$258,$259
	DC.W	$260,$261,$262,$263,$264,$265,$266,$267,$268,$269
	DC.W	$270,$271,$272,$273,$274,$275,$276,$277,$278,$279
	DC.W	$280,$281,$282,$283,$284,$285,$286,$287,$288,$289
	DC.W	$290,$291,$292,$293,$294,$295,$296,$297,$298,$299
	DC.W	$300,$301,$302,$303,$304,$305,$306,$307,$308,$309
	DC.W	$310,$311,$312,$313,$314,$315,$316,$317,$318,$319
	DC.W	$320,$321,$322,$323,$324,$325,$326,$327,$328,$329
	DC.W	$330,$331,$332,$333,$334,$335,$336,$337,$338,$339
	DC.W	$340,$341,$342,$343,$344,$345,$346,$347,$348,$349
	DC.W	$350,$351,$352,$353,$354,$355,$356,$357,$358,$359
	DC.W	$360,$361,$362,$363,$364,$365,$366,$367,$368,$369
	DC.W	$370,$371,$372,$373,$374,$375,$376,$377,$378,$379
	DC.W	$380,$381,$382,$383,$384,$385,$386,$387,$388,$389
	DC.W	$390,$391,$392,$393,$394,$395,$396,$397,$398,$399

	ENDC
; ---------------------------------<=






	IFEQ	NO_NTSCTOP
; -------------------------------------
; SetPicTop: first picture line for the screen mode (prefs byte $0F, 1 = NTSC).
; PAL keeps Juan's $30. NTSC's frame is only 262 lines, so the picture moves
; up 19 lines to sit in the middle. Sets the display window, the wait before
; the bitplanes go on, the sprite strips' VSTART/VSTOP and the copper scroll
; waits (PicTop, used by SetScrollAtRender). After the sprite init in
; CongelaAMIGA.
; -------------------------------------
SetPicTop:
	MOVEM.L	D0-D1/A0,-(SP)
	MOVEQ	#$2F,D0
	IFNE	DbgRows
	MOVEQ	#$34,D0			; the debug rows use lines $1C-$2C, the palette load follows
	IFNE	AGC
	TST.B	AgcOn
	BEQ.S	.dbg
	MOVEQ	#$2F,D0			; AGA chunky mode: the panel goes under the picture (DbgAgcPanel)
.dbg:
	ENDC
	ENDC
	IFEQ	ShowFps+DbgRows		; the fps rows use lines $21-$29
	TST.B	DirPrefs+$0F
	BEQ.S	.pal
	MOVEQ	#$1C,D0			; NTSC: lines $1D-$104
.pal:
	ENDC
	MOVE.W	D0,PicTop
	MOVE.B	D0,CopTopWait		; wait line before the bitplanes go on
	ADDQ.W	#1,D0
	MOVE.B	D0,Copper+2		; DIWSTRT V
	LEA	Sprit0,A0
	MOVEQ	#8-1,D1
.spr:	MOVE.B	D0,(A0)			; VSTART (bit 8 clear)
	MOVE.B	D0,8(A0)		; VSTOP = VSTART + 256 (bit 8 set in the CTL word)
	ADD.L	#NextSpr/2,A0		; NextSpr = two sprites (Sprit2-Sprit0)
	DBF	D1,.spr
	ADD.W	#232,D0
	MOVE.B	D0,Copper+6		; DIWSTOP V (bit 8 = NOT bit 7)
	MOVEM.L	(SP)+,D0-D1/A0
	RTS
PicTop:	DC.W	$2F
	ENDC

	IFNE	ScrRing
; ScrRingFrame: the main loop, each PCE frame: the frame's scroll list into ring slot ScrRingI (192 bytes: frame
; number, AgcYb, AgcLate, AgcSkipped, then up to 30 (line, BXR, BYR) entries, -1).
ScrRingFrame:
	MOVEM.L	D0/A0/A1,-(SP)
	ADDQ.L	#1,ScrRingN
	MOVE.W	ScrRingI,D0
	ADDQ.W	#1,D0
	CMP.W	#1000,D0
	BCS.S	.i
	MOVEQ	#0,D0
.i:	MOVE.W	D0,ScrRingI
	MULU.W	#192,D0
	LEA	ScrRingBuf,A1
	ADD.L	D0,A1
	MOVE.L	ScrRingN,(A1)+
	IFNE	AGC
	MOVE.W	AgcYb,(A1)+
	MOVE.B	AgcLate,(A1)+
	MOVE.B	AgcSkipped,(A1)+
	ELSE
	CLR.L	(A1)+
	ENDC
	MOVE.L	Regs+ScrollChangesNext,A0
	MOVEQ	#30-1,D0
.c:	MOVE.W	(A0)+,(A1)+
	BMI.S	.x
	MOVE.W	(A0)+,(A1)+
	MOVE.W	(A0)+,(A1)+
	DBF	D0,.c
	MOVE.W	#-1,(A1)
.x:	MOVEM.L	(SP)+,D0/A0/A1
	RTS
; ScrRingWrite: the menu, after play (OS alive): header (ScrRingN, ScrRingI) + the 1000 slots.
ScrRingWrite:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.L	$4.W,A6
	LEA	ScrRingDos(PC),A1
	MOVEQ	#0,D0
	JSR	-$228(A6)		; OpenLibrary
	TST.L	D0
	BEQ.S	.x
	MOVE.L	D0,A6
	MOVE.L	#ScrRingName,D1
	MOVE.L	#1006,D2
	JSR	-30(A6)			; Open
	MOVE.L	D0,D4
	BEQ.S	.cl
	MOVE.L	D4,D1
	MOVE.L	#ScrRingN,D2
	MOVEQ	#8,D3
	JSR	-48(A6)			; Write
	MOVE.L	D4,D1
	MOVE.L	#ScrRingBuf,D2
	MOVE.L	#1000*192,D3
	JSR	-48(A6)			; Write
	MOVE.L	D4,D1
	JSR	-36(A6)			; Close
.cl:	MOVE.L	A6,A1
	MOVE.L	$4.W,A6
	JSR	-$19E(A6)		; CloseLibrary
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
ScrRingDos:	DC.B	"dos.library",0
ScrRingName:	DC.B	"PROGDIR:scrring.bin",0
	EVEN
	ENDC
;;	-=-=-=-==-=-=-=-=-=-=-
	CNOP	0,8
DameVBR:MOVEC	VBR,A0
	MOVE.L	A0,VBRPun
	NOP
	RTE
	CNOP	0,8
CongelaAMIGA:
;;	-=-=-=-==-=-=-=-=-=-=-
	LEA	DameVBR(PC),A5
	MOVE.L	$4.W,A6
	JSR	-$1E(A6)
;;	-=-=-=-==-=-=-=-=-=-=-
	MOVE.L	$4.W,A5
	MOVE.L	$9C(A5),A5
	MOVE.L	$26(A5),WBCopp
;;	-=-=-=-==-=-=-=-=-=-=-
	LEA	DirPlanos,A0
	BSR	CreaPlanos
	LEA	DirColores,A0
	BSR	CreaColores
	LEA	DirSprites,A0
	BSR	CreaSprites
	LEA	DirSaltos,A0
	BSR	CreaSaltos

	MOVE.W	#INISPR2*$100+$50,Sprit0
	MOVE.W	#FINSPR2*$100+$02,Sprit0+8

	MOVE.W	#INISPR2*$100+$50,Sprit1
	MOVE.W	#FINSPR2*$100+$82,Sprit1+8

	MOVE.W	#INISPR2*$100+$70,Sprit2
	MOVE.W	#FINSPR2*$100+$02,Sprit2+8

	MOVE.W	#INISPR2*$100+$70,Sprit3
	MOVE.W	#FINSPR2*$100+$82,Sprit3+8

	MOVE.W	#INISPR2*$100+$90,Sprit4
	MOVE.W	#FINSPR2*$100+$02,Sprit4+8

	MOVE.W	#INISPR2*$100+$90,Sprit5
	MOVE.W	#FINSPR2*$100+$82,Sprit5+8

	MOVE.W	#INISPR2*$100+$B0,Sprit6
	MOVE.W	#FINSPR2*$100+$02,Sprit6+8

	MOVE.W	#INISPR2*$100+$B0,Sprit7
	MOVE.W	#FINSPR2*$100+$82,Sprit7+8
	IFEQ	NO_NTSCTOP
	BSR	SetPicTop
	ENDC
	IFNE	DbgRows
	JSR	DbgInit
	ENDC

;;	-=-=-=-==-=-=-=-=-=-=-
	LEA	$DFF000,A6
	MOVE.W	#$7FFF,D7
	MOVE.W	$1C(A6),Intena
	MOVE.W	D7,$9A(A6)
	MOVE.W	$1E(A6),Intreq
	MOVE.W	D7,$9C(A6)
	MOVE.W	$02(A6),DMACon
	BTST	#6,DMACon+1
	BEQ.S	NoBliOn
EspBli:	NOP
	NOP
	BTST	#6,2(A6)
	BNE.S	EspBli
	NOP
	NOP
	IFEQ	NO_BLITREQ
	MOVE.L	D0,-(SP)		; an OS blit that ended during the wait raised
	MOVE.W	$1E(A6),D0		; BLIT after the INTREQ copy: keep it, or the
	AND.W	#$0040,D0		; OS waits for it forever after the exit
	OR.W	D0,Intreq
	MOVE.L	(SP)+,D0
	ENDC
NoBliOn:MOVE.W	D7,$96(A6)
	NOP
	NOP
;;	-=-=-=-==-=-=-=-=-=-=-
	IFNE	OnlyAGA
	MOVE.L	#MasterCopper_AGA,$80(A6)
	ELSE
	MOVE.L	#MasterCopper_SAGA,$80(A6)
	ENDC
	NOP
	MOVE.L	#Copper,$84(A6)
	NOP
	MOVE.W	#0,$88(A6)
	NOP
	NOP
	MOVE.W	#$0020,$09C(A6)
EspIntV:NOP
	NOP
	NOP
	NOP
	BTST	#$05,$01F(A6)
	BEQ.S	EspIntV
	NOP
	MOVE.W	#$83A0,$096(A6)	; ---,BLTPriDMA,BPL;COP,BLT,SPR,DSK;AUD3-0
;;	-=-=-=-==-=-=-=-=-=-=-
	SF	$BFEC01
;;	-=-=-=-==-=-=-=-=-=-=-
	MOVE.L	VBRPun,A0
	MOVE.L	$6C(A0),VBlank
;;	-=-=-=-==-=-=-=-=-=-=-
	MOVE.L	#InInter,$6C(A0)
;;	-=-=-=-==-=-=-=-=-=-=-
	LEA	$BFE001,A6
	BFEXTU	(A6){6:1},D7		; Filtro.
	MOVE.B	D7,Filtro
	BSET	#1,$BFE001		; Filtro OFF
;;	-=-=-=-==-=-=-=-=-=-=-
	RTS

; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;

SPDesbor:
	ST	DesborPILA			; *\*\*  POR QUITAR  */*/*

Salir:
	MOVEM.L	D0-D7/A0-A7,Debug

	MOVE.L	PILA,SP

	IFNE	AutoExit
	IFNE	AutoMenu
	TST.B	AutoMenuGo
	BEQ.S	.salirReal
	SF	AutoMenuGo
	CMP.L	#AutoExit,AutoFrames
	BCC.S	.salirReal
	BSR	DescongelaAMIGA		; as Esc: the OS is back (the menu runs here)
	IFEQ	NO_RTG
	JSR	RtgPlayClose
	ENDC
	JSR	AutoMenuVisit		; OS alive: new ROM memory, old one freed, a wait
	IFNE	AutoMenuCont
	MOVEQ	#-1,D7			; Continue
	ELSE
	MOVEQ	#1,D7			; Power ON
	ENDC
	JMP	EmulatorStart
.salirReal:
	ENDC
	IFNE	ProfOn
	JSR	ProfStop
	ENDC
	BSR	DescongelaAMIGA
	IFNE	ScrRing
	JSR	ScrRingWrite		; (test builds) also at the end of an AutoExit run
	ENDC
	IFEQ	NO_RTG
	JSR	RtgPlayClose
	IFNE	AGC
	JSR	AgcDumpWrite		; before RtgQuit frees the chunky buffer
	ENDC
	JSR	RtgQuit			; test builds too: the big buffers and tall pictures back
	ENDC
	JMP	AutoWriteResult		; OS is back: write the counts, RTS to the caller
	ENDC

	IFEQ	NO_RTG
	BSR	DescongelaAMIGA
	IFNE	DbgProbe
	JSR	RtgPlayClose
	JMP	PrbDumpWrite		; OS alive: the last two frames' VRAM to a file
	ELSE
	JMP	RtgPlayClose		; RTG: the play screen closed, RTS to the menu
	ENDC
	ENDC

DescongelaAMIGA:
;;	-=-=-=-==-=-=-=-=-=-=-
	MOVE.B	Filtro,D7
	LEA	$BFE001,A6
	BFINS	D7,(A6){6:1}		; Filtro.
;;	-=-=-=-==-=-=-=-=-=-=-
	MOVE.L	VBRPun,A0
	MOVE.L	VBlank,$6C(A0)
	IFEQ	NO_PSGWAVE
	IFEQ	NO_PSGDDA
	MOVE.W	#$0780,$DFF09A		; PSG audio interrupts off, the OS level 4 vector back
	TST.L	PSGOldL4
	BEQ.S	.noL4
	MOVE.L	PSGOldL4,$70(A0)
.noL4:
	ENDC
	ENDC
;;	-=-=-=-==-=-=-=-=-=-=-
	LEA	$DFF000,A6
	MOVE.W	#$7FFF,D7
	MOVE.W	D7,$09A(A6)
	MOVE.W	#$8000,D6
	OR.W	D6,DMACon
	MOVE.W	D7,$096(A6)
	OR.W	D6,Intena
	OR.W	D6,Intreq
	MOVE.W	D7,$09C(A6)
	NOP
;;	-=-=-=-==-=-=-=-=-=-=-
	CLR.W	$180(A6)
	MOVE.L	WBCopp,$80(A6)
	NOP
	MOVE.L	WBCopp,$84(A6)
	NOP
	MOVE.W	#0,$88(A6)
	NOP
;;	-=-=-=-==-=-=-=-=-=-=-
	MOVE.W	#$8280,$096(A6)
	NOP
	NOP
	MOVE.W	#$0020,$09C(A6)
EspIntV0:NOP
	NOP
	NOP
	NOP
	BTST	#$05,$01F(A6)
	BEQ.S	EspIntV0
	NOP
	NOP
	NOP
	NOP
	MOVE.W	#$0020,$09C(A6)
EspIntV1:NOP
	NOP
	NOP
	NOP
	BTST	#$05,$01F(A6)
	BEQ.S	EspIntV1
	NOP
	MOVE.W	D7,$09C(A6)
	NOP
;;	-=-=-=-==-=-=-=-=-=-=-
	MOVE.W	DMACon,$096(A6)
	NOP
	NOP
	MOVE.W	Intreq,$09C(A6)
	NOP
	NOP
	MOVE.W	Intena,$09A(A6)
	NOP
	NOP
;;	-=-=-=-==-=-=-=-=-=-=-
	RTS
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;


; -------------------------------------> Interrupción de Vblank la 1ª vez.
	CNOP	0,8
InInter:
	MOVE.L	#Inter,([VBRPun],$6C.W)
	BRA.S	Inter
	NOP
; -------------------------------------<
	CNOP	0,8
Inter:
	BTST	#$05,$DFF01F
	beq.s	noVBlankInter

	ADDQ.L	#1,vTimerVBlanks

	MOVEM.L	D0-D7/A0-A6,-(SP)
	IFNE	DbgRows
	JSR	DbgVblIn
	ENDC

;	MOVE.W	#$A00,$DFF180


	LEA	vBlank_Count,A0
	SUBQ.L	#1,(A0)
	BCC.S	HaPasadoSegundo
	MOVE.L	FPS_Count,FPS_Current
	CLR.L	FPS_Count
	MOVE.L	#60-1,(A0)
HaPasadoSegundo:


	LEA	Regs,A3
	TST.B	SalirMenu(A3)
	BEQ.S	NoSalir
	
	SF	SalirMenu(A3)

	MOVEM.L	(SP)+,D0-D7/A0-A6

	ST	ExitToMenu

noVBlankInter:
	MOVE.W	#$0070,$DFF09C
	NOP
	RTE

NoSalir:

; --------------------------------------


; Update SAGA Sprites PTRs
	move.l	SpritesBufToRender,A0
	clr.l	SpritesBufToRender
	tst.l	A0
	beq.s	.skipUpdate

	lea	iSprBufCoors(A0),A0
	lea	SAGASpritesPtrs,A1
	moveq	#16-1,D0
.loop:
	addq	#2,a1
	move.l	(a0)+,(a1)+
	dbf	d0,.loop



.skipUpdate:



RunCopperScrolls:
	IFEQ	NO_RTG
	TST.B	RtgOn
	BEQ.S	.agaVbl
	CLR.L	Regs+ScrollChangesToRender	; RTG: no copper list, no copper colours
	BRA	RtgVblPal
.agaVbl:
	ENDC


;	move.w	#$8000,d0
;	btst	#7,VDP_Regs+(5*2)+1
	IFEQ	NO_CRVIS|NO_RTG
	moveq	#0,d0
	move.b	CrVis,d0		; BG / sprite bits of the shown lines
	move.w	d0,d1
	ELSE
	move.w	VDP_Regs+(5*2),d0
	move.w	VDP_Regs+(5*2),d1
	ENDC

	lsr.w	#6,d0
	lsr.w	#7,d1
	or.w	d1,d0

;	bfins	d0,CopSprites+2{0:1}
	bfins	d0,CopBitmaps+2{0:1}




;	bsr	xLogInit


	lea	CopperScrolls,a5

	moveq	#0,d6

	LEA	Regs,A3
;-----
;	clr.l	ScrollChangesToRender(A3)


	move.l	ScrollChangesToRender(A3),A6
	clr.l	ScrollChangesToRender(A3)
	tst.l	A6
	beq	gemmy
;	beq	.end
	IFEQ	NO_BGLINE|NO_BGMASK
	move.l	BgLogNext,a4		; this frame's colour 0 entries
	addq.l	#4,a4
	cmp.w	#$7FFF,(a4)
	beq.s	.noCol0
	move.w	#$0180,(a5)+		; the colour the frame started with
	move.w	-2(a4),(a5)+
.noCol0:
	ENDC
.loopA:
	tst.w	(a6)
	bmi	.end
	IFEQ	NO_COPFIX
	cmp.l	#CopperScrollsEnd-CopScrollSlack,a5	; room for one more entry?
	bcc	.end
	ENDC



;	move.w	(a6),d0		; Copper Render Y
;	bsr	xLogByte
;	move.b	#":",d0
;	bsr	xLogChar
;	move.w	4(a6),D0	; scroll Y
;	bsr	xLogWord
;	move.b	#" ",d0
;	bsr	xLogChar



	move.w	(a6),d7		; Copper Render Y
	move.w	2(a6),D1	; scroll X
	move.w	4(a6),D0	; scroll Y

	tst.w	d7
	beq.s	.skip7
	addq.w	#1,d0
.skip7:


	IFEQ	NO_BGLINE|NO_BGMASK
	bsr	SetScrollCol
	ELSE
	bsr	SetScrollAtRender
	ENDC


	move.w	6(a6),d5	; next ScanLine with Scroll Y changes
	bpl.s	.hasEntry
	move.w	#224,d5
.hasEntry:
	
	move.w	4(a6),D0	; scroll Y
	and.l	#$01FF,D0		; height 64 tiles
	btst	#6,VDP_Regs+(9*2)+1
	bne.s	.height64
	and.w	#$00FF,D0		; height 32 tiles
.height64:

	MOVE.B	(VDP_Regs+(9*2)+1),D3
	LSR.B	#4,D3
	AND.W	#$0007,D3
	IFNE	AGC
	MOVE.W	(VBGHeight.L,D3.W*2),D4	; (AGA chunky mode's code between: out of PC reach with the debug rows)
	ELSE
	MOVE.W	(VBGHeight.W,PC,D3.W*2),D4
	ENDC
	lsl.w	#3,D4

	move.w	(a6),d7
	sub.w	d0,d4
	add.w	d4,d7


;	move.l	d0,-(sp)
;	move.w	d7,D0	; reset scroll Y at
;	bsr	xLogThree
;	move.b	#"/",d0
;	bsr	xLogChar
;	move.w	d5,D0	; scroll Y
;	bsr	xLogByte
;	move.b	#" ",d0
;	bsr	xLogChar
;	move.l	(sp)+,d0


	cmp.w	d5,d7
	bcc.s	.noRepeat

	cmp.w	(a6),d7
	beq.s	.noRepeat

	move.w	2(a6),D1	; scroll X
;	move.w	4(a6),D0	; scroll Y
	moveq	#0,d0

;	add.w	#$2F,d7
;	move.l	#$FFCFFFFE,(a5)+
;	move.b	d7,-4(a5)
;	move.l	#$01800fff,(a5)+
;	move.l	#$01800020,(a5)+

	IFEQ	NO_BGLINE|NO_BGMASK
	bsr	SetScrollCol
	ELSE
	bsr	SetScrollAtRender
	ENDC

.noRepeat:

	addq	#6,a6

	bra	.loopA
.end:

	IFEQ	NO_BGLINE|NO_BGMASK
	move.w	#$7FFF,d7		; the colour entries left
	bsr	CopColFlush
	moveq	#$0010,d1		; a raster effect on colour 0: black borders, not stripes
	move.w	#$1040,d0
	suba.l	BgLogNext,a4
	cmp.w	#4+(BGBORDER*4),a4
	bcs.s	.bord
	moveq	#$0011,d1		; ECSENA, which BRDRBLNK needs
	move.w	#$1060,d0		; BRDRBLNK
.bord:	move.w	d0,BpCon3+2
	move.w	d1,CopTopWait+6
	ENDC
	move.l	#$FFFFFFFE,(a5)+
	move.l	#$FFFFFFFE,(a5)+


gemmy:


;	bsr	xLogDraw




;;	BSR	PrintGFX
;;	JSR	CleanTabRefef
;;	BSR	PrintSprites_AGA


	IFNE	OnlyAGA
	IFNE	AGC
	JSR	PonePaleta_AGA		; (AGC.asm in the hunk: out of BSR range)
	ELSE
	BSR	PonePaleta_AGA
	ENDC
	ELSE
	BSR	PonePaleta_SAGA
	ENDC
	IFEQ	NO_RTG
RtgVblPal:
	ENDC

	BSR	TocaPSG


	JSR	([JoyControlRut.w,PC])
	BSR	MiraTeclado

	LEA	Regs,A3
	MOVE.B	KeyX(A3),D1
	OR.B	D1,JoyX(A3)
	IFNE	AutoPress
	IFNE	AutoPressHost
	JSR	AutoPressBits		; the next unit's bits, sampled here as the real pad is
	MOVE.B	D1,AutoPressCur
	ENDC
	MOVE.B	AutoPressCur,D1		; scheduled pad bits, latched at the start of the PCE frame
	OR.B	D1,JoyX(A3)
	ENDC

;	MOVE.W	#$0A0,$DFF180

	IFNE	DbgRows
	JSR	DbgVblOut
	ENDC
	IFEQ	NO_LATESTART|NO_RTG
	JSR	LsTod
	MOVE.W	D0,D1
	SUB.W	LsVblTod,D1
	MOVE.W	D0,LsVblTod
	CMP.W	#200,D1			; a frame is 262 or 313 lines
	BCS.S	LsVbl1
	CMP.W	#330,D1
	BHI.S	LsVbl1
	MOVE.W	D1,LsFrame
LsVbl1:
	ENDC
	IFNE	AGC
	IFEQ	NO_RTG
	TST.B	AgcOn
	BEQ.S	AgcVblX
	JSR	AgcFlip			; the picture switched at the frame's start
AgcVblX:
	ENDC
	ENDC
	ST	vBlankOccurred

	MOVEM.L	(SP)+,D0-D7/A0-A6
	MOVE.W	#$0070,$DFF09C
	NOP
	RTE





xLogInit:
	move.l	#xLogBuffer,xLogIndex
	clr.l	xLogBuffer
	rts

xLogString:
	move.l	a1,-(sp)
	move.l	xLogIndex,a1
	cmp.l	#xLogBufferEnd,a1
	bcc.s	.end
.loop:
	move.b	(a0)+,d0
	beq.s	.zero
	move.b	d0,(a1)+
	bra.s	.loop
.zero:
	clr.l	(a1)
	move.l	a1,xLogIndex
.end:
	move.l	(sp)+,a1
	rts

xLogChar:
	move.l	a1,-(sp)
	move.l	xLogIndex,a1
	cmp.l	#xLogBufferEnd,a1
	bcc.s	.end
	move.b	d0,(a1)+
	clr.l	(a1)
	move.l	a1,xLogIndex
.end:
	move.l	(sp)+,a1
	rts

;	D0.b: Byte to log
xLogByte:
	movem.l	d0-d7/a0-a6,-(sp)
	bsr	ByteToChar
	move.l	xLogIndex,a1
	cmp.l	#xLogBufferEnd,a1
	bcc.s	.end
	move.w	(a0),(a1)+
	clr.l	(a1)
	move.l	a1,xLogIndex
.end:
	movem.l	(sp)+,d0-d7/a0-a6
	rts

;	D0.b: Byte to log
xLogWord:
	move.l	d0,-(sp)
	lsr.w	#8,d0
	bsr	xLogByte
	move.l	(sp),d0
	bsr	xLogByte
	move.l	(sp)+,d0
	rts

xLogThree:
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	xLogIndex,a1
	cmp.l	#xLogBufferEnd,a1
	bcc.s	.end
	move.l	d0,-(sp)
	lsr.w	#8,d0
	bsr	ByteToChar
	move.l	xLogIndex,a1
	move.b	1(a0),(a1)+
	clr.l	(a1)
	move.l	a1,xLogIndex
	move.l	(sp)+,d0
	bsr	xLogByte
.end:
	movem.l	(sp)+,d0-d7/a0-a6
	rts

xLogDraw:
	movem.l	d0-d7/a0-a6,-(sp)
	moveq	#9,d0
	moveq	#0,d1
	lea	xLogBuffer,A0
	bsr	DrawText
	movem.l	(sp)+,d0-d7/a0-a6
	rts

xLogIndex:	dc.l	0
xLogBuffer:	ds.b	23
xLogBufferEnd:	ds.b	20



	IFEQ	NO_BGLINE|NO_BGMASK
	cnop	0,8
; -------------------------------------
; SetScrollAtRender with the colour 0 moves merged in. Same registers, and
;	A4: next BgLog entry
;	D5: used
; A move on a scroll entry's line comes last: it lands in the left border of
; the next line, as the bitplane pointers are done and before the window opens.
; -------------------------------------
SetScrollCol:
	move.w	d7,d5
	bsr	CopColFlush
	bsr	SetScrollAtRender
	cmp.w	(a4),d5
	bne.s	.x
	move.w	#$0180,(a5)+
	move.w	2(a4),(a5)+
	addq.l	#4,a4
.x:	rts

; -------------------------------------
; A WAIT + MOVE per colour entry above line D7, right of the window, so the
; colour changes in the left border of the next line.
;	D2: used
;	D6, A4, A5: as SetScrollAtRender
; -------------------------------------
CopColFlush:
.l:	move.w	(a4),d2
	cmp.w	d7,d2
	bcc.s	.x
	IFEQ	NO_NTSCTOP
	add.w	PicTop,d2
	ELSE
	add.w	#$2F,d2
	ENDC
	cmp.w	#$ff,d2
	bcs.s	.w
	tst.l	d6
	bne.s	.w
	moveq	#-1,d6
	cmp.w	#$ff,d2
	beq.s	.w
	move.l	#$FFDFFFFE,(a5)+
.w:	move.l	#$FFE1FFFE,(a5)+
	move.b	d2,-4(a5)
	move.w	#$0180,(a5)+
	move.w	2(a4),(a5)+
	addq.l	#4,a4
	bra.s	.l
.x:	rts
	ENDC

	cnop	0,8
; -------------------------------------
;	D0: Scroll Y
;	D1: Scroll X
;	D6: used to know if Amiga Copper reached Render Y >= $100
;	D7: PCE Render Y
;	A5: CopperList Index
; -------------------------------------
SetScrollAtRender:
	IFEQ	NO_WIDE
	add.w	WideX,D1	; BG pixel for H $A1: the window starts WideM px later, WideC px cut
	ENDC
	move.w	d1,D2		; copy scroll X
	move.w	d1,D4		; copy scroll X

	IFEQ	NO_NTSCTOP
	add.w	PicTop,d7
	ELSE
	add.w	#$2F,d7
	ENDC

	cmp.w	#$ff,d7
	bcs.b	.skipOverflow
	tst.l	d6
	bne.s	.skipOverflow
	moveq	#-1,d6
	cmp.w	#$ff,d7
	beq.s	.skipOverflow
	move.l	#$FFDFFFFE,(a5)+
.skipOverflow:
	move.l	#$FFCFFFFE,(a5)+
	move.b	d7,-4(a5)



;	move.l	#$01800f00,(a5)+
;	move.l	#$01800020,(a5)+



;	tst.w	d0
;	beq.s	.skip7
;	add.w	#1,d0
;.skip7:

	and.l	#$01FF,D0		; height 64 tiles
	btst	#6,VDP_Regs+(9*2)+1
	bne.s	.height64
	and.w	#$00FF,D0		; height 32 tiles
.height64:
	mulu	#GfxBufNextLine,D0


	btst	#5,VDP_Regs+(9*2)+1
	bne.s	.longWidth
	btst	#4,VDP_Regs+(9*2)+1
	bne.s	.midWidth
	and.l	#$00FF,D1
	bra.s	.shortWidth
.midWidth:
	and.l	#$01FF,D1
	bra.s	.shortWidth
.longWidth:
	and.l	#$03FF,D1
.shortWidth:
	lsr.l	#5,D1
	lsl.l	#2,D1
	add.l	D1,D0



	neg.l	d2	; d2: CoorX

	btst	#4,D2
	beq.s	.pepe0

	and.l	#$000F,D2
	or.w	#$0c00,D2
	bra.s	.pepe1
.pepe0:
	and.l	#$000F,D2
	or.w	#$0800,D2
.pepe1:

	
	move.l	D2,D3
	lsl.w	#4,d3
	or.w	d2,d3
	IFEQ	NO_SCRLONG
	swap	d3
	move.w	#$0102,d3
	swap	d3
	move.l	d3,(a5)+
	ELSE
	move.w	#$0102,(a5)+
	move.w	d3,(a5)+
	ENDC


	neg.l	d4		; Scroll X
	and.l	#$001F,D4
	beq.s	.pepe
	addq.l	#4,d0
.pepe:


	add.l	#PantGfx-4,D0

	moveq	#8-1,D2
	IFEQ	NO_SCRLONG
	move.l	#$00E00000,d3	; the register in the upper word: one long write per copper move (32-bit chip bus)
.loop2:
	swap	D0
	move.w	D0,d3
	move.l	d3,(a5)+
	add.l	#$00020000,d3
	swap	D0
	move.w	D0,d3
	move.l	d3,(a5)+
	add.l	#$00020000,d3
	add.l	#(GfxBufNextBpl),D0
	dbf	D2,.loop2
	ELSE
	move.w	#$00E0,d3
.loop2:
	move.w	d3,(a5)+
	swap	D0
	move.w	D0,(A5)+
	addq.w	#2,d3
	move.w	d3,(a5)+
	swap	D0
	move.w	D0,(A5)+
	addq.w	#2,d3
	add.l	#(GfxBufNextBpl),D0
	dbf	D2,.loop2
	ENDC

	RTS















vBlankOccurred:	DC.B	0,0
ExitToMenu:	DC.B	0
isContinue:	DC.B	0



	CNOP	0,8
JoyControlRut:	DC.L	LeeJoyStick


; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;


; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


; ------------------------------------------------ ;
; ------------------------------------------------ ;

LeeTecla:MACRO
	CMP.B	#\2,D0
	BNE.S	Lete\@
	BCLR	#\1,\3(A3)
	RTS
Lete\@:
	ENDM

PonTecla:MACRO
	CMP.B	#\2,D0
	BNE.S	PoTe\@
	BSET	#\1,\3(A3)
	RTS
PoTe\@:
	ENDM

	CNOP	0,8
MiraTeclado:
	MOVEQ	#0,D0
	MOVE.B	$BFEC01,D0
	BNE.S	Pulsacion
	RTS
Pulsacion:
	NOP
	SF	$BFEC01
	NOP
	NOP
	MOVE.W	#4,D2
	OR.B	#$40,$BFEE01		; CIAA Libre
TRETARDO:
	MOVE.B	$DFF006,D1
TRETARDOB:
	CMP.B	$DFF006,D1
	BEQ.S	TRETARDOB
	DBF	D2,TRETARDO
	AND.B	#$BF,$BFEE01		; CIAA Libre

	LEA	Regs,A3

	NOT.B	D0
	LSR.B	#$1,D0
	BCS	TeclaSoltada

	PonTecla 1,$4E,KeyX		; Derecha
	PonTecla 3,$4F,KeyX		; Izquierda
	PonTecla 0,$4C,KeyX		; Arriba
	PonTecla 2,$4D,KeyX		; Abajo

	PonTecla 5,$66,KeyX		; Botón A	(Amiga Izq)
	PonTecla 4,$64,KeyX		; Botón B	(Alt Izq)
	PonTecla 6,$46,KeyX		; Select	(Del)
	PonTecla 7,$44,KeyX		; Start		(Enter)
	PonTecla 7,$5F,KeyX		; Start		(Help)

	PonTecla 5,$60,KeyX		; Botón A	(Shift Izq)
	PonTecla 4,$40,KeyX		; Botón B	(Space)

	CMP.B	#$45,D0			; Salir		(Esc)
	BNE.S	NoEsESC
	ST	SalirMenu(A3)
	RTS
NoEsESC:
	CMP.B	#$5F,D0			; Salir		(Help)
	BNE.S	NoEsESC2
	ST	SalirMenu(A3)
NoEsESC2:

	IFNE	UseDebug
	jsr	Debug_OnKeyPressed
	ENDC

	RTS
	CNOP	0,4
TeclaSoltada:
	LeeTecla 1,$4E,KeyX		; Derecha
	LeeTecla 3,$4F,KeyX		; Izquierda
	LeeTecla 0,$4C,KeyX		; Arriba
	LeeTecla 2,$4D,KeyX		; Abajo

	LeeTecla 5,$66,KeyX		; Botón A	(Amiga Izq)
	LeeTecla 4,$64,KeyX		; Botón B	(Alt Izq)
	LeeTecla 6,$46,KeyX		; Select	(Del)
	LeeTecla 7,$44,KeyX		; Start		(Enter)
	LeeTecla 7,$5F,KeyX		; Start		(Help)

	LeeTecla 5,$60,KeyX		; Botón A	(Shift Izq)
	LeeTecla 4,$40,KeyX		; Botón B	(Space)


	IFNE	UseDebug
	jsr	Debug_OnKeyReleased
	ENDC


	RTS

; ------------------------------------------------ ;
; ------------------------------------------------ ;

;	 ---------------------------
;	- Lee puerto 0 del JoyStick -
;	 ---------------------------

	CNOP	0,8
LeeJoyStick:
LeeJoypad:
	LEA	Regs,A3
	MOVE.W	$DFF00C,D0		; Puerto B.
	BSR	LEEJOY

	SF	D1
	BFINS	D2,D1{30:1}		; Derecha
	LSR.B	#1,D2
	BFINS	D2,D1{28:1}		; Izquierda
	LSR.B	#1,D2
	BFINS	D2,D1{31:1}		; Arriba
	LSR.B	#1,D2
	BFINS	D2,D1{29:1}		; Abajo

	BTST	#7,$BFE001		; Botón A	(Fire #1)
	BNE.S	NOB1_E
	BSET	#5,D1
NOB1_E:
	MOVE.W	#$FF00,$DFF034		; Botón B	(Fire #2)
	NOP
	NOP
	IFEQ	NO_JOYFIX
	BTST	#6,$DFF016		; DATRY: pin 9 of port 2
	BNE.S	NOB2_E
	BSET	#4,D1			; button I (bit 1 is Right)
	ELSE
	BTST	#4,$DFF016
	BNE.S	NOB2_E
	BSET	#1,D1
	ENDC
NOB2_E:

	MOVE.B	D1,JoyX(A3)
	RTS
; -------------------------------
;	Lectura del Joystick.

;	Resultado en D2.b de la siguiente forma:
;	Bit 0=Derecha.
;	Bit 1=Izquierda.
;	Bit 2=Arriba.
;	Bit 3=Abajo.

	CNOP	0,8
LEEJOY:
	MOVE.W	D0,D1
	LSR.B	#1,D1
	AND.B	#$01,D1
	MOVE.B	D1,D2		; Derecha.

	LSR.W	#8,D1
	AND.B	#$02,D1
	OR.B	D1,D2		; Izquierda.

	MOVE.W	D0,D1
	LSR.W	#1,D1
	EOR.W	D1,D0

	MOVE.W	D0,D1
	LSL.B	#3,D1
	AND.B	#$08,D1
	OR.B	D1,D2		; Abajo.

	LSR.W	#6,D0
	AND.B	#$04,D0
	OR.B	D0,D2		; Arriba.
	RTS

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

	CNOP	0,8
LeeTeclado:
	LEA	Regs,A3
	SF	JoyX(A3)
	RTS

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

;	( U D L R ) , ( R S I II )

CD32M:	MACRO
	LSR.B	#1,D0
	BCC.S	\@NoPuldat
	BSET	#\1,\2
\@NoPuldat:
	ENDM

	CNOP	0,8
LeeCD32Joypad:
	LEA	Regs,A3
	MOVE.W	$DFF00C,D0		; Puerto B.
	BSR.S	LEEJOY

	SF	D3
	IFEQ	NO_JOYFIX
	BFINS	D2,D3{30:1}		; Right
	LSR.B	#1,D2
	BFINS	D2,D3{28:1}		; Left
	LSR.B	#1,D2
	BFINS	D2,D3{31:1}		; Up
	LSR.B	#1,D2
	BFINS	D2,D3{29:1}		; Down
	ELSE
	BFINS	D2,D3{24:1}
	LSR.B	#1,D2
	BFINS	D2,D3{25:1}
	LSR.B	#1,D2
	BFINS	D2,D3{27:1}
	LSR.B	#1,D2
	BFINS	D2,D3{26:1}
	ENDC

	BSR	ReadCD32
	LSR.B	#2,D0
	IFEQ	NO_JOYFIX
	BCC.S	.noPlay
	BSET	#7,D3			; Play = Run (pads on CD32 adapters send Start as Play)
.noPlay:
	MOVE.B	D0,D1
	AND.B	#$03,D1
	CMP.B	#$03,D1			; both shoulders = back to the menu
	BNE.S	.noMenu
	ST	SalirMenu(A3)
.noMenu:
	ELSE
	SCS	SalirMenu(A3)
	ENDC

	IFEQ	NO_JOYFIX
	CD32M	4,D3	; button I	(Rewind)
	CD32M	5,D3	; button II	(Forward)
	CD32M	6,D3	; Select	(Green)
	CD32M	7,D3	; Run		(Yellow)
	CD32M	5,D3	; button II	(Red = joystick fire 1)
	CD32M	4,D3	; button I	(Blue = joystick fire 2)
	ELSE
	CD32M	1,D3	; Boton B
	CD32M	0,D3	; Boton A
	CD32M	2,D3	; Select
	CD32M	3,D3	; Start
	CD32M	1,D3	; Boton B
	CD32M	0,D3	; Boton A
	ENDC

	MOVE.B	D3,JoyX(A3)

	RTS

	IFEQ	NO_MENU2
; LeePads: the pad on each port, read as the type picked for that port in the menu (Joy-Control),
; both ORed into JoyX (the keyboard is added by the caller). D3 gathers the bits: 0 Up, 1 Right,
; 2 Down, 3 Left, 4 button I, 5 button II, 6 Select, 7 Run. Uses D0-D3/A0/A3 only (the callers
; save those).
	CNOP	0,8
LeePads:
	LEA	Regs,A3
	MOVEQ	#0,D3
	MOVE.L	PadRut1,A0
	JSR	(A0)
	MOVE.L	PadRut2,A0
	JSR	(A0)
	MOVE.B	D3,JoyX(A3)
	RTS
	CNOP	0,4
PadRut1:	DC.L	PadNone
PadRut2:	DC.L	PadJoy2
PadPrg1:	DC.L	PadNone,PadJoy1,PadCD1,PadPad1	; port 1 (prefs $16, the menu's order)
PadPrg2:	DC.L	PadJoy2,PadNone,PadCD2,PadPad2	; port 2 (prefs $08, Juan's order)

PadNone:
	RTS

; PadDirs: D0 = JOYxDAT; the directions into D3.
PadDirs:
	BSR	LEEJOY			; D2: 0 Right, 1 Left, 2 Up, 3 Down
	AND.W	#$000F,D2
	MOVE.B	PadDirT(PC,D2.W),D0
	OR.B	D0,D3
	RTS
PadDirT:	DC.B	$0,$2,$8,$A,$1,$3,$9,$B,$4,$6,$C,$E,$5,$7,$D,$F	; -> 1 Right, 3 Left, 0 Up, 2 Down

; Joystick: fire 1 (pin 6, CIA-A) = button II, fire 2 (pin 9, POTINP) = button I.
; Joypad: the same and fire 3 (pin 5, POTINP) = Run.
PadJoy2:
	MOVE.W	$DFF00C,D0		; JOY1DAT
	BSR.S	PadDirs
	BTST	#7,$BFE001		; fire 1 of port 2
	BNE.S	.f2
	BSET	#5,D3
.f2:	MOVE.W	#$FF00,$DFF034		; POTGO
	NOP
	NOP
	BTST	#6,$DFF016		; DATRY: pin 9 of port 2
	BNE.S	.x
	BSET	#4,D3
.x:	RTS
PadPad2:
	BSR.S	PadJoy2
	BTST	#4,$DFF016		; DATRX: pin 5 of port 2
	BNE.S	.x
	BSET	#7,D3
.x:	RTS
PadJoy1:
	MOVE.W	$DFF00A,D0		; JOY0DAT
	BSR.S	PadDirs
	BTST	#6,$BFE001		; fire 1 of port 1
	BNE.S	.f2
	BSET	#5,D3
.f2:	MOVE.W	#$FF00,$DFF034
	NOP
	NOP
	BTST	#2,$DFF016		; DATLY: pin 9 of port 1
	BNE.S	.x
	BSET	#4,D3
.x:	RTS
PadPad1:
	BSR.S	PadJoy1
	BTST	#0,$DFF016		; DATLX: pin 5 of port 1
	BNE.S	.x
	BSET	#7,D3
.x:	RTS

; CD32 pad, as LeeCD32Joypad and ReadCD32 for either port: \1 JOYxDAT, \2 the CIA-A PRA bit of pin 6
; (the clock), \3 the POTINP bit of pin 9 (the data), \4 POTGO (pin 5 low: shift mode).
PadCdM:	MACRO
	MOVE.W	\1,D0
	BSR	PadDirs
	BSET	#\2,$BFE201
	BCLR	#\2,$BFE001
	MOVE.W	#\4,$DFF034
	MOVEQ	#0,D0
	MOVEQ	#7,D1
	BRA.S	.c4\@
.c3\@:	TST.B	$BFE001
	TST.B	$BFE001
	TST.B	$BFE001
.c4\@:	TST.B	$BFE001
	TST.B	$BFE001
	TST.B	$BFE001
	TST.B	$BFE001
	TST.B	$BFE001
	MOVE.W	$DFF016,D2
	BSET	#\2,$BFE001
	BCLR	#\2,$BFE001
	BTST	#\3,D2
	BNE.S	.c5\@
	BSET	D1,D0
.c5\@:	DBF	D1,.c3\@
	BCLR	#\2,$BFE201
	MOVE.W	#$FFFF,$DFF034
	LSR.B	#2,D0
	BCC.S	.np\@
	BSET	#7,D3			; Play = Run
.np\@:	MOVE.B	D0,D1
	AND.B	#$03,D1
	CMP.B	#$03,D1			; both shoulders = back to the menu
	BNE.S	.nm\@
	ST	SalirMenu(A3)
.nm\@:	CD32M	4,D3	; button I	(Rewind)
	CD32M	5,D3	; button II	(Forward)
	CD32M	6,D3	; Select	(Green)
	CD32M	7,D3	; Run		(Yellow)
	CD32M	5,D3	; button II	(Red)
	CD32M	4,D3	; button I	(Blue)
	RTS
	ENDM
PadCD2:	PadCdM	$DFF00C,7,14,$6F00
PadCD1:	PadCdM	$DFF00A,6,10,$F600
	ENDC

;***********************************************************************
;Reads CD 32 Controller
;You must read joystick positions or button in normal way
;BEFORE you call this.
;One VBL MUST have elapsed before repeating this!

; D0=:
CD_PLAY	EQU 1
CD_RWD	EQU 2
CD_FFW	EQU 3
CD_G	EQU 4
CD_Y	EQU 5
CD_R	EQU 6
CD_B	EQU 7

		CNOP	0,8
ReadCD32:
		bset	#7,$bfe201
		bclr	#7,$bfe001
		move.w	#$6f00,$dff034
		moveq.l	#0,d0
		moveq.l	#7,d1
		bra.b	.gamecont4		
.gamecont3:
		tst.b	$bfe001
		tst.b	$bfe001
		tst.b	$bfe001
.gamecont4:
		tst.b	$bfe001
		tst.b	$bfe001
		tst.b	$bfe001
		tst.b	$bfe001
		tst.b	$bfe001
		move.w	$dff016,d2
		bset	#7,$bfe001
		bclr	#7,$bfe001
		btst	#14,d2
		bne.b	.gamecont5
		bset	d1,d0
.gamecont5:
		dbf	d1,.gamecont3
		
		bclr	#7,$bfe201
		move.w	#$ffff,$dff034
		rts
;***********************************************************************
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-






; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;


; -------------------------------------
; **  Rutinas Básicas de 007  v2.27  **
; -------------------------------------

	CNOP	0,4

DP0=$8000	; 00(A0): Direccion Copper.   08(A0): Bytes de 1 Plano.
DP1=$C000	; 04(A0): Direccion Pant.     0C(A0): Bit-Planos. (DP0,1)
CreaPlanos:
	MOVE.W	#$E0,D3
CRPBUC00:
	TST.L	(A0)
	BEQ	CRPRET
	MOVE.L	(A0)+,A1
	MOVEM.L	(A0)+,D0-D2
	TST.W	D2
	SUB.W	#1,D2
	BPL.S	CRPCON00
	BTST	#$E,D2
	BEQ.S	CRPCON01
	ADD.W	#4,D3
CRPCON01:
	AND.W	#$3FFF,D2
	BSR	HACEPLANOS2
	BRA.S	CreaPlanos
CRPCON00:
	BSR	HACEPLANOS
	BRA.S	CreaPlanos
HACEPLANOS:			; A1=COPPER.   D0=Direccion. D1=PLANOSIZE.
	SWAP	D0		; D2=Planos-1. D3=DIRBPLH/L
	MOVE.W	D3,(A1)+
	MOVE.W	D0,(A1)+
	ADD.W	#2,D3
	SWAP	D0
	MOVE.W	D3,(A1)+
	MOVE.W	D0,(A1)+
	ADD.W	#2,D3
	ADD.L	D1,D0
	DBF	D2,HACEPLANOS
CRPRET:	RTS
HACEPLANOS2:			; Igual que antes pero Dual Playfield.
	SWAP	D0
	MOVE.W	D3,(A1)+
	MOVE.W	D0,(A1)+
	ADD.W	#2,D3
	SWAP	D0
	MOVE.W	D3,(A1)+
	MOVE.W	D0,(A1)+
	ADD.W	#2,D3
	ADD.L	D1,D0
	ADD.W	#4,D3
	DBF	D2,HACEPLANOS2
	RTS
CREASALTO:			; A0=COPPER-List.   D0=Direccion
	MOVE.W	D0,$6(A0)
	SWAP	D0
	MOVE.W	D0,$2(A0)
	RTS
;	00(A0): Direccion de Copper.	08(A0): Numero Colores. (DP0,1)
;	04(A0): Direccion de Colores.	(Todos en x.L)
CreaColores:
	MOVE.W	#$180,D1
CRCBUC00:
	TST.L	(A0)
	BEQ	CRPRET
	MOVEM.L	(A0)+,A1-A2
	MOVE.L	(A0)+,D0
	SUB.W	#1,D0
	TST.W	D0
	BPL.S	CRCBUC01
	MOVE.W	#$190,D1
	BTST	#$E,D0
	BEQ.S	CRCBUC01A
	MOVE.W	#$1A0,D1
CRCBUC01A:
	AND.W	#$3FFF,D0
CRCBUC01:
	MOVE.W	D1,(A1)+
	MOVE.W	(A2)+,(A1)+
	ADD.W	#$02,D1
	DBF	D0,CRCBUC01
	BRA.S	CreaColores	
;	00(A0): Direccion del Copper.	08(A0): Numero Sprit (0-7)
;	04(A0): Direccion GFX Sprit.	(Todos en x.L)
CreaSprites:
	TST.L	(A0)
	BEQ	CRPRET
	MOVE.W	#$120,D2
	MOVE.L	(A0)+,A1
	MOVEM.L	(A0)+,D0-D1
	LSL.W	#2,D1
	ADD.L	D1,D2	
	MOVE.W	D2,(A1)+
	SWAP	D0
	MOVE.W	D0,(A1)+
	ADD.L	#2,D2
	MOVE.W	D2,(A1)+
	SWAP	D0
	MOVE.W	D0,(A1)+
	BRA.S	CreaSprites
;	00(A0): Direccion del Copper.	08(A0): Dir. Salto.
CreaSaltos:
	TST.L	(A0)
	BEQ	CRPRET
	MOVE.L	(A0)+,A1
	MOVE.L	(A0)+,D0
	MOVE.W	D0,$6(A1)
	SWAP	D0
	MOVE.W	D0,$2(A1)
	BRA.S	CreaSaltos	
RETARDO:			; D0=Retardo.
	MOVE.W	D0,-(SP)
	MOVE.B	$DFF006,D0
RETARDOB:
	CMP.B	$DFF006,D0
	BEQ.S	RETARDOB
	MOVE.W	(SP)+,D0
	DBF	D0,RETARDO
	RTS
; -----**************()**************-----

	CNOP	0,4
DirPlanos:
	DC.L	PLANO,PantGfx-4,(GfxBufNextBpl),8
	IFNE	ShowFps
	DC.L	PlanoFPS_AGA,Panel-4,(32*8),2
	DC.L	PlanoFPS_SAGA,Panel-4,(32*8),2
	ENDC
	DC.L	0
DirColores:
;;	DC.L	COLOR0,NESPaleta,16
	DC.L	0
DirSprites:
	DC.L	DIRSPRIT0,Sprit0,0
	DC.L	DIRSPRIT1,Sprit1,1
	DC.L	DIRSPRIT2,Sprit2,2
	DC.L	DIRSPRIT3,Sprit3,3
	DC.L	DIRSPRIT4,Sprit4,4
	DC.L	DIRSPRIT5,Sprit5,5
	DC.L	DIRSPRIT6,Sprit6,6
	DC.L	DIRSPRIT7,Sprit7,7
	DC.L	0
DirSaltos:
	DC.L	0


	CNOP	0,8
VBlank:		DC.L	0
WBCopp:		DC.L	0
VBRPun:		DC.L	0
Debug:		DS.L	16
DMACon:		DC.W	0
Intena:		DC.W	0
Intreq:		DC.W	0
Filtro:		DC.B	0,0
INTERDAT:	DC.W	0
PILA:		DC.L	0



; -------------------------------------------------------------
; -------------------------------------------------------------
; -------------------------------------------------------------
; -------------------------------------------------------------
; -------------------------------------------------------------




; A5: ScrStruct
; D0: locale-X
; D1: locale-Y
; D2: char to draw
DrawChar:
	lea	TopScrStruct,a5

	moveq	#0,d7
	move.w	iWidthB(a5),d7
	mulu.w	#8,d7
	mulu.l	d7,d1		; Calculate Y


;	moveq	#0,d7
;	move.w	iWidthB(a5),d7
;	mulu.w	iHeight(a5),d7
;	add.l	d7,a2		; Calculate offset to BitPlane X


	move.l	iBitmap(a5),a2
	add.l	d0,a2		; ADD X
	add.l	d1,a2		; ADD Y
;	add.l	d7,a2		; ADD to X Bit-plane
	move.l	a2,a3


	and.l	#$ff,d2
	sub.w	#$20,d2
	lsl.w	#3,d2


	lea	Font2,a1
	moveq	#8-1,d6
.loop:
	moveq	#0,d7
	move.b	(a1,d2),d7
	move.b	d7,(a3)



	addq	#1,a1
	add.w	iWidthB(a5),a3
	dbf	d6,.loop
	rts



; A5: ScrStruct
; A0: text to draw
; D0: locale-X
; D1: locale-Y
DrawText:
	lea	TopScrStruct,a5

DrawTask:	
	move.l	iBitmap(a5),a2

	moveq	#0,d7
	move.w	iWidthB(a5),d7
	mulu.w	#8,d7
	mulu.l	d7,d1
	
	add.l	d1,a2
	add.l	d0,a2
.loop0:
	moveq	#0,d7
	move.b	(a0)+,d7
	bne.s	.draw
	rts
.draw:
	sub.w	#$20,d7

	move.l	a2,a3
	lea	Font2,a1

	moveq	#8-1,d6
.loop:
	move.b	(a1,d7.W*8),(a3)
	addq.l	#1,a1
	add.w	iWidthB(a5),a3
	dbf	d6,.loop

	addq	#1,a2
	bra.s	.loop0


ByteToChar:
	move.b	d0,d1
	and.b	#$0f,d0
	lsr.b	#4,d1

	cmp.b	#$A,d0
	blt.s	.isNumber1
	addq.b	#7,d0
.isNumber1:
	cmp.b	#$A,d1
	blt.s	.isNumber2
	add.b	#7,d1
.isNumber2:

	add.b	#$30,d0
	add.b	#$30,d1
	lea	TxtBuf,a0
	clr.l	(a0)
	clr.l	4(a0)
	clr.l	8(a0)
	clr.l	12(a0)
	move.b	d1,(a0)
	move.b	d0,1(a0)
	rts


HexToDec:
	lea     TxtBuf,a0
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	subq	#1,a0

	moveq	#0,d5     ; Our counter for decimal digits.
.loop:
	move	d0,d1
	tst.l	d0     ; Stop when there are no more digits left to process.
	ble	.done
	divu	#10,d0
	mulu	#10,d0
	sub.W	d0,d1
	add.W	#48,d1    ; Convert the value to the corresponding character.
	move.B	d1,-(a0)   ; Store the decimal character.
	divu	#10,d0    ; Find the next decimal digit.
	add	#1,d5     ; Increment the decimal digit counter.
	bra	.loop
.done:
	rts




	cnop 0,8
TxtBuf:	dc.l	0,0,0,0
	cnop 0,8



iBitmap:	equ	0
iWidthP:	equ	4
iHeight:	equ	6
iWidthB:	equ	8
iPlanes:	equ	10

	cnop	0,8
TopScrStruct:
	dc.l	Panel		; bit-planes
	dc.w	256		; width in pixels
	dc.w	8		; height in pixels
	dc.w	(256/8)		; width in bytes (width/8)
	dc.w	1		; num.planes



	cnop	0,8
Font2:
	DC.B	 $00,$00,$00,$00,$00,$00,$00,$00	   ; U+0020 (space)
	DC.B	 $18,$3C,$3C,$18,$18,$00,$18,$00	   ; U+0021 (!)
	DC.B	 $6C,$6C,$00,$00,$00,$00,$00,$00	   ; U+0022 (")
	DC.B	 $6C,$6C,$FE,$6C,$FE,$6C,$6C,$00	   ; U+0023 (#)
	DC.B	 $30,$7C,$C0,$78,$0C,$F8,$30,$00	   ; U+0024 ($)
	DC.B	 $00,$C6,$CC,$18,$30,$66,$C6,$00	   ; U+0025 (%)
	DC.B	 $38,$6C,$38,$76,$DC,$CC,$76,$00	   ; U+0026 (&)
	DC.B	 $60,$60,$C0,$00,$00,$00,$00,$00	   ; U+0027 (')
	DC.B	 $18,$30,$60,$60,$60,$30,$18,$00	   ; U+0028 (()
	DC.B	 $60,$30,$18,$18,$18,$30,$60,$00	   ; U+0029 ())
	DC.B	 $00,$66,$3C,$FF,$3C,$66,$00,$00	   ; U+002A (*)
	DC.B	 $00,$30,$30,$FC,$30,$30,$00,$00	   ; U+002B (+)
	DC.B	 $00,$00,$00,$00,$00,$30,$30,$60	   ; U+002C (,)
	DC.B	 $00,$00,$00,$FC,$00,$00,$00,$00	   ; U+002D (-)
	DC.B	 $00,$00,$00,$00,$00,$30,$30,$00	   ; U+002E (.)
	DC.B	 $06,$0C,$18,$30,$60,$C0,$80,$00	   ; U+002F (/)
	DC.B	 $7C,$C6,$CE,$DE,$F6,$E6,$7C,$00	   ; U+0030 (0)
	DC.B	 $30,$70,$30,$30,$30,$30,$FC,$00	   ; U+0031 (1)
	DC.B	 $78,$CC,$0C,$38,$60,$CC,$FC,$00	   ; U+0032 (2)
	DC.B	 $78,$CC,$0C,$38,$0C,$CC,$78,$00	   ; U+0033 (3)
	DC.B	 $1C,$3C,$6C,$CC,$FE,$0C,$1E,$00	   ; U+0034 (4)
	DC.B	 $FC,$C0,$F8,$0C,$0C,$CC,$78,$00	   ; U+0035 (5)
	DC.B	 $38,$60,$C0,$F8,$CC,$CC,$78,$00	   ; U+0036 (6)
	DC.B	 $FC,$CC,$0C,$18,$30,$30,$30,$00	   ; U+0037 (7)
	DC.B	 $78,$CC,$CC,$78,$CC,$CC,$78,$00	   ; U+0038 (8)
	DC.B	 $78,$CC,$CC,$7C,$0C,$18,$70,$00	   ; U+0039 (9)
	DC.B	 $00,$30,$30,$00,$00,$30,$30,$00	   ; U+003A (:)
	DC.B	 $00,$30,$30,$00,$00,$30,$30,$60	   ; U+003B (;)
	DC.B	 $18,$30,$60,$C0,$60,$30,$18,$00	   ; U+003C (<)
	DC.B	 $00,$00,$FC,$00,$00,$FC,$00,$00	   ; U+003D (=)
	DC.B	 $60,$30,$18,$0C,$18,$30,$60,$00	   ; U+003E (>)
	DC.B	 $78,$CC,$0C,$18,$30,$00,$30,$00	   ; U+003F (?)
	DC.B	 $7C,$C6,$DE,$DE,$DE,$C0,$78,$00	   ; U+0040 (@)
	DC.B	 $30,$78,$CC,$CC,$FC,$CC,$CC,$00	   ; U+0041 (A)
	DC.B	 $FC,$66,$66,$7C,$66,$66,$FC,$00	   ; U+0042 (B)
	DC.B	 $3C,$66,$C0,$C0,$C0,$66,$3C,$00	   ; U+0043 (C)
	DC.B	 $F8,$6C,$66,$66,$66,$6C,$F8,$00	   ; U+0044 (D)
	DC.B	 $FE,$62,$68,$78,$68,$62,$FE,$00	   ; U+0045 (E)
	DC.B	 $FE,$62,$68,$78,$68,$60,$F0,$00	   ; U+0046 (F)
	DC.B	 $3C,$66,$C0,$C0,$CE,$66,$3E,$00	   ; U+0047 (G)
	DC.B	 $CC,$CC,$CC,$FC,$CC,$CC,$CC,$00	   ; U+0048 (H)
	DC.B	 $78,$30,$30,$30,$30,$30,$78,$00	   ; U+0049 (I)
	DC.B	 $1E,$0C,$0C,$0C,$CC,$CC,$78,$00	   ; U+004A (J)
	DC.B	 $E6,$66,$6C,$78,$6C,$66,$E6,$00	   ; U+004B (K)
	DC.B	 $F0,$60,$60,$60,$62,$66,$FE,$00	   ; U+004C (L)
	DC.B	 $C6,$EE,$FE,$FE,$D6,$C6,$C6,$00	   ; U+004D (M)
	DC.B	 $C6,$E6,$F6,$DE,$CE,$C6,$C6,$00	   ; U+004E (N)
	DC.B	 $38,$6C,$C6,$C6,$C6,$6C,$38,$00	   ; U+004F (O)
	DC.B	 $FC,$66,$66,$7C,$60,$60,$F0,$00	   ; U+0050 (P)
	DC.B	 $78,$CC,$CC,$CC,$DC,$78,$1C,$00	   ; U+0051 (Q)
	DC.B	 $FC,$66,$66,$7C,$6C,$66,$E6,$00	   ; U+0052 (R)
	DC.B	 $78,$CC,$E0,$70,$1C,$CC,$78,$00	   ; U+0053 (S)
	DC.B	 $FC,$B4,$30,$30,$30,$30,$78,$00	   ; U+0054 (T)
	DC.B	 $CC,$CC,$CC,$CC,$CC,$CC,$FC,$00	   ; U+0055 (U)
	DC.B	 $CC,$CC,$CC,$CC,$CC,$78,$30,$00	   ; U+0056 (V)
	DC.B	 $C6,$C6,$C6,$D6,$FE,$EE,$C6,$00	   ; U+0057 (W)
	DC.B	 $C6,$C6,$6C,$38,$38,$6C,$C6,$00	   ; U+0058 (X)
	DC.B	 $CC,$CC,$CC,$78,$30,$30,$78,$00	   ; U+0059 (Y)
	DC.B	 $FE,$C6,$8C,$18,$32,$66,$FE,$00	   ; U+005A (Z)
	DC.B	 $78,$60,$60,$60,$60,$60,$78,$00	   ; U+005B ([)
	DC.B	 $C0,$60,$30,$18,$0C,$06,$02,$00	   ; U+005C (\)
	DC.B	 $78,$18,$18,$18,$18,$18,$78,$00	   ; U+005D (])
	DC.B	 $10,$38,$6C,$C6,$00,$00,$00,$00	   ; U+005E (^)
	DC.B	 $00,$00,$00,$00,$00,$00,$00,$FF	   ; U+005F (_)
	DC.B	 $30,$30,$18,$00,$00,$00,$00,$00	   ; U+0060 (`)
	DC.B	 $00,$00,$78,$0C,$7C,$CC,$76,$00	   ; U+0061 (a)
	DC.B	 $E0,$60,$60,$7C,$66,$66,$DC,$00	   ; U+0062 (b)
	DC.B	 $00,$00,$78,$CC,$C0,$CC,$78,$00	   ; U+0063 (c)
	DC.B	 $1C,$0C,$0C,$7C,$CC,$CC,$76,$00	   ; U+0064 (d)
	DC.B	 $00,$00,$78,$CC,$FC,$C0,$78,$00	   ; U+0065 (e)
	DC.B	 $38,$6C,$60,$F0,$60,$60,$F0,$00	   ; U+0066 (f)
	DC.B	 $00,$00,$76,$CC,$CC,$7C,$0C,$F8	   ; U+0067 (g)
	DC.B	 $E0,$60,$6C,$76,$66,$66,$E6,$00	   ; U+0068 (h)
	DC.B	 $30,$00,$70,$30,$30,$30,$78,$00	   ; U+0069 (i)
	DC.B	 $0C,$00,$0C,$0C,$0C,$CC,$CC,$78	   ; U+006A (j)
	DC.B	 $E0,$60,$66,$6C,$78,$6C,$E6,$00	   ; U+006B (k)
	DC.B	 $70,$30,$30,$30,$30,$30,$78,$00	   ; U+006C (l)
	DC.B	 $00,$00,$CC,$FE,$FE,$D6,$C6,$00	   ; U+006D (m)
	DC.B	 $00,$00,$F8,$CC,$CC,$CC,$CC,$00	   ; U+006E (n)
	DC.B	 $00,$00,$78,$CC,$CC,$CC,$78,$00	   ; U+006F (o)
	DC.B	 $00,$00,$DC,$66,$66,$7C,$60,$F0	   ; U+0070 (p)
	DC.B	 $00,$00,$76,$CC,$CC,$7C,$0C,$1E	   ; U+0071 (q)
	DC.B	 $00,$00,$DC,$76,$66,$60,$F0,$00	   ; U+0072 (r)
	DC.B	 $00,$00,$7C,$C0,$78,$0C,$F8,$00	   ; U+0073 (s)
	DC.B	 $10,$30,$7C,$30,$30,$34,$18,$00	   ; U+0074 (t)
	DC.B	 $00,$00,$CC,$CC,$CC,$CC,$76,$00	   ; U+0075 (u)
	DC.B	 $00,$00,$CC,$CC,$CC,$78,$30,$00	   ; U+0076 (v)
	DC.B	 $00,$00,$C6,$D6,$FE,$FE,$6C,$00	   ; U+0077 (w)
	DC.B	 $00,$00,$C6,$6C,$38,$6C,$C6,$00	   ; U+0078 (x)
	DC.B	 $00,$00,$CC,$CC,$CC,$7C,$0C,$F8	   ; U+0079 (y)
	DC.B	 $00,$00,$FC,$98,$30,$64,$FC,$00	   ; U+007A (z)
	DC.B	 $1C,$30,$30,$E0,$30,$30,$1C,$00	   ; U+007B (,)
	DC.B	 $18,$18,$18,$00,$18,$18,$18,$00	   ; U+007C (|)
	DC.B	 $E0,$30,$30,$1C,$30,$30,$E0,$00	   ; U+007D (})
	DC.B	 $76,$DC,$00,$00,$00,$00,$00,$00	   ; U+007E (~)
	DC.B	 $00,$00,$00,$00,$00,$00,$00,$00	   ; U+007F
Font2End:









	INCLUDE	"Menu.asm"






; -------------------------------------------------- ;
; -------------------------------------------------- ;
; -------------************************------------- ;
; -------------------------------------------------- ;
; -------------------------------------------------- ;


;	------------------------
	IFNE	AutoExit
	IFNE	AutoPress
	CNOP	0,4
AutoPressTab:			; at the end of the code: long schedules would push branches out of range
	INCLUDE	"autopress.i"		; written by tools/autopress.py
	DC.W	-1
	ENDC
	ENDC
	MemGuard CodeEnd
ProfCodeEnd:			; end of the code hunk (profiler histogram range)
	SECTION	Pantallas,DATA_C
;	------------------------
	MemGuard PantA

	CNOP	0,8
MasterCopper_AGA:
		DC.W	$01FC,$000D
DIRSPRIT0:	DS.W	4
DIRSPRIT1:	DS.W	4
DIRSPRIT2:	DS.W	4
DIRSPRIT3:	DS.W	4
DIRSPRIT4:	DS.W	4
DIRSPRIT5:	DS.W	4
DIRSPRIT6:	DS.W	4
DIRSPRIT7:	DS.W	4

		DC.W	$0901,$FFFE

	IFNE	DbgRows			; panel for DbgRows.asm, lines $1C-$2C, 1 plane
DbgCopPt:
	DC.W	$00E0,0,$00E2,0
	DC.W	$008E,$1C81
	DC.W	$0090,$28C1
	DC.W	$0092,$0038
	DC.W	$0094,$00C8
	DC.W	$0108,0
	DC.W	$010A,0
	DC.W	$0102,0
	DC.W	$0104,0
	DC.W	$0106,0
	DC.W	$010C,0
	DC.W	$0180,$0113
	DC.W	$0182,$0FF8
	DC.W	$0096,$8100
	DC.W	$0100,$1201
	DC.W	$2D07,$FFFE
	DC.W	$0100,$0201
DbgCopEnd:
	ENDC

;	---------------------=> Muestra Fps
	IFNE	ShowFps
PlanoFPS_AGA:
	DS.W	2*4
	DC.W	$008E,$21A1
	DC.W	$0090,$FBA1

	DC.W	$0108,0-4
	DC.W	$010A,0-4

	DC.W	$2101,$FFFE
	DC.W	$0096,$8100

	DC.W	$0102,$0000
	DC.W	$0104,$007F
	DC.W	$0106,$1040
	DC.W	$010C,$0011

	DC.W	$0100,$2001
	
	DC.W	$182,$0fff,$184,0,$186,$0AAA

	DC.W	$2901,$FFFE
	DC.W	$0100,$0001
	ENDC
;	---------------------<=

;; -COLOR- ;; ------------------------------
	dc.l	$01060c40
COLOR:
	dc.l	$01800000,$01820004,$01840009,$0186000e,$01880200,$018a0204,$018c0209,$018e020e
	dc.l	$01900400,$01920404,$01940409,$0196040e,$01980600,$019a0604,$019c0609,$019e060e
	dc.l	$01a00800,$01a20804,$01a40809,$01a6080e,$01a80a00,$01aa0a04,$01ac0a09,$01ae0a0e
	dc.l	$01b00c00,$01b20c04,$01b40c09,$01b60c0e,$01b80e00,$01ba0e04,$01bc0e09,$01be0e0e

	dc.l	$01062c40
	dc.l	$01800020,$01820024,$01840029,$0186002e,$01880220,$018a0224,$018c0229,$018e022e
	dc.l	$01900420,$01920424,$01940429,$0196042e,$01980620,$019a0624,$019c0629,$019e062e
	dc.l	$01a00820,$01a20824,$01a40829,$01a6082e,$01a80a20,$01aa0a24,$01ac0a29,$01ae0a2e
	dc.l	$01b00c20,$01b20c24,$01b40c29,$01b60c2e,$01b80e20,$01ba0e24,$01bc0e29,$01be0e2e

	dc.l	$01064c40
	dc.l	$01800040,$01820044,$01840049,$0186004e,$01880240,$018a0244,$018c0249,$018e024e
	dc.l	$01900440,$01920444,$01940449,$0196044e,$01980640,$019a0644,$019c0649,$019e064e
	dc.l	$01a00840,$01a20844,$01a40849,$01a6084e,$01a80a40,$01aa0a44,$01ac0a49,$01ae0a4e
	dc.l	$01b00c40,$01b20c44,$01b40c49,$01b60c4e,$01b80e40,$01ba0e44,$01bc0e49,$01be0e4e

	dc.l	$01066c40
	dc.l	$01800060,$01820064,$01840069,$0186006e,$01880260,$018a0264,$018c0269,$018e026e
	dc.l	$01900460,$01920464,$01940469,$0196046e,$01980660,$019a0664,$019c0669,$019e066e
	dc.l	$01a00860,$01a20864,$01a40869,$01a6086e,$01a80a60,$01aa0a64,$01ac0a69,$01ae0a6e
	dc.l	$01b00c60,$01b20c64,$01b40c69,$01b60c6e,$01b80e60,$01ba0e64,$01bc0e69,$01be0e6e

	dc.l	$01068c40
	dc.l	$01800080,$01820084,$01840089,$0186008e,$01880280,$018a0284,$018c0289,$018e028e
	dc.l	$01900480,$01920484,$01940489,$0196048e,$01980680,$019a0684,$019c0689,$019e068e
	dc.l	$01a00880,$01a20884,$01a40889,$01a6088e,$01a80a80,$01aa0a84,$01ac0a89,$01ae0a8e
	dc.l	$01b00c80,$01b20c84,$01b40c89,$01b60c8e,$01b80e80,$01ba0e84,$01bc0e89,$01be0e8e

	dc.l	$0106ac40
	dc.l	$018000a0,$018200a4,$018400a9,$018600ae,$018802a0,$018a02a4,$018c02a9,$018e02ae
	dc.l	$019004a0,$019204a4,$019404a9,$019604ae,$019806a0,$019a06a4,$019c06a9,$019e06ae
	dc.l	$01a008a0,$01a208a4,$01a408a9,$01a608ae,$01a80aa0,$01aa0aa4,$01ac0aa9,$01ae0aae
	dc.l	$01b00ca0,$01b20ca4,$01b40ca9,$01b60cae,$01b80ea0,$01ba0ea4,$01bc0ea9,$01be0eae

	dc.l	$0106cc40
	dc.l	$018000c0,$018200c4,$018400c9,$018600ce,$018802c0,$018a02c4,$018c02c9,$018e02ce
	dc.l	$019004c0,$019204c4,$019404c9,$019604ce,$019806c0,$019a06c4,$019c06c9,$019e06ce
	dc.l	$01a008c0,$01a208c4,$01a408c9,$01a608ce,$01a80ac0,$01aa0ac4,$01ac0ac9,$01ae0ace
	dc.l	$01b00cc0,$01b20cc4,$01b40cc9,$01b60cce,$01b80ec0,$01ba0ec4,$01bc0ec9,$01be0ece

	dc.l	$0106ec40
	dc.l	$018000e0,$018200e4,$018400e9,$018600ee,$018802e0,$018a02e4,$018c02e9,$018e02ee
	dc.l	$019004e0,$019204e4,$019404e9,$019604ee,$019806e0,$019a06e4,$019c06e9,$019e06ee
	dc.l	$01a008e0,$01a208e4,$01a408e9,$01a608ee,$01a80ae0,$01aa0ae4,$01ac0ae9,$01ae0aee
	dc.l	$01b00ce0,$01b20ce4,$01b40ce9,$01b60cee,$01b80ee0,$01ba0ee4,$01bc0ee9,$01be0eee
	dc.l	$01060c40
;; =COLOR= ;; ------------------------------


		DC.W	$1201,$FFFE
		DC.W	$008A,$0000


	CNOP	0,8
MasterCopper_SAGA:
		DC.W	$01FC,$001D
		DC.W	$07D1,$FFFE
SAGASpritesPtrs:
		dc.w	$8120,0,0
		dc.w	$8124,0,0
		dc.w	$8128,0,0
		dc.w	$812C,0,0
		dc.w	$8130,0,0
		dc.w	$8134,0,0
		dc.w	$8138,0,0
		dc.w	$813C,0,0
		dc.w	$8320,0,0
		dc.w	$8324,0,0
		dc.w	$8328,0,0
		dc.w	$832C,0,0
		dc.w	$8330,0,0
		dc.w	$8334,0,0
		dc.w	$8338,0,0
		dc.w	$833C,0,0

		DC.W	$0901,$FFFE

;	---------------------=> Muestra Fps
	IFNE	ShowFps
PlanoFPS_SAGA:
	DS.W	2*4
	DC.W	$008E,$21A1
	DC.W	$0090,$FBA1

	DC.W	$0108,0-4
	DC.W	$010A,0-4

	DC.W	$2101,$FFFE
	DC.W	$0096,$8100

	DC.W	$0102,$0000
	DC.W	$0104,$007F
	DC.W	$0106,$1040
	DC.W	$010C,$0011

	DC.W	$0100,$2001
	
	DC.W	$182,$0fff,$184,0,$186,$0AAA

	DC.W	$2901,$FFFE
	DC.W	$0100,$0001
	ENDC
;	---------------------<=

AllRGBs:
		REPT	256
		dc.w	$8380,$0000,$0000	; Populate BitPlanes RGBs
		ENDR
		REPT	256
		dc.w	$8384,$0000,$0000	; Populate Sprites RGBs
		ENDR

		
		DC.W	$1201,$FFFE
		DC.W	$008A,$0000


	CNOP	0,4
Copper:
	DC.W	$008E,$30A1
	DC.W	$0090,$18A1

	DC.W	$0092,$0038
	DC.W	$0094,$00B8

	DC.W	$0108,GfxBufNextLine-32-4
	DC.W	$010A,GfxBufNextLine-32-4

ScrBits:DC.W	$0102,$8800
CopBplcon2:	DC.W	$0104,$007F	; sprites over or behind the BG (PonePaleta_AGA)
BpCon3:	DC.W	$0106,$1040
CopBplcon4:	DC.W	$010C,$00FF	; sprite colour bank (PonePaleta_AGA)

PLANO:	DS.W	8*4


CopBitmaps:	DC.W	$0096,$8100
;CopSprites:	DC.W	$0096,$8020




CopTopWait:
	DC.W	$2FBF,$FFFE
	DC.W	$0100,$0010	; 8 Bit-Planes



CopperScrolls:
	DC.L	$FFFFFFFE
	DC.L	$FFFFFFFE
	IFEQ	NO_COPFIX
	DS.B	CopScrollMax-8	; RunCopperScrolls builds the per-line scroll list here
CopperScrollsEnd:
	ENDC









; ------------------------------------------------ ;
	CNOP	0,8
NoSPRIT:DC.L	$FE00FF00,0,0,0,0
; ------------------------------------------------ ;
	DS.B	32*16	; Seguridad!


; ------------------------------------------------ ;
	CNOP	0,8
Panel:	INCBIN	"res/Panel.raw"
Font:	INCBIN	"res/Font.raw"
; ------------------------------------------------ ;


; <=----------------------------------------------=>
; <=----------------------------------------------=>

	CNOP	0,8
GGLogo:
	INCBIN	"res/AmiPC-Engine_Logo.raw"

	CNOP	0,8
GBTeclado:
	INCBIN	"res/Teclado.raw"

	CNOP	0,8
GBJoyStick:
	INCBIN	"res/JoyStick.raw"

	CNOP	0,8
GBJoypad:
	INCBIN	"res/Joypad.raw"

	CNOP	0,8
GBCD32:
	INCBIN	"res/CD32.raw"

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


	CNOP	0,8
Onda:	DC.B	$7F,$80

	CNOP	0,8
Onda0:	DCB.B	16,$7F
	DCB.B	16,$80
Onda1:	DCB.B	16,$7F
	DCB.B	16,$80
Onda2:	DCB.B	16,$7F
	DCB.B	16,$80
Onda3:	DCB.B	16,$7F
	DCB.B	16,$80
Onda4:	DCB.B	16,$7F
	DCB.B	16,$80
Onda5:	DCB.B	16,$7F
	DCB.B	16,$80
Onda6:	DCB.B	16,$7F
	DCB.B	16,$80
Onda7:	DCB.B	16,$7F
	DCB.B	16,$80

	DS.L	50

; <=----------------------------------------------=>
; <=----------------------------------------------=>


; <=----------------------------------------------=>
; <=----------------------------------------------=>





;	------------------------
	MemGuard PantB
	SECTION	Graficos,BSS_C
;	------------------------
	MemGuard GrafA
	IFNE	DbgRows
	CNOP	0,8
DbgPanel:	DS.B	DbgCols*(DbgRowGap+8)
	ENDC

; =----------------------------------------=> Gfx y Spr en Chip.
		CNOP	0,8
		DS.B	32*16
PantGfx:	DS.B	GfxBufNextBpl*8
		DS.B	32*16

		CNOP	0,8
Sprit0:		DS.B	16+(8*256*2)+16
Sprit1:		DS.B	16+(8*256*2)+16
Sprit2:		DS.B	16+(8*256*2)+16
Sprit3:		DS.B	16+(8*256*2)+16
Sprit4:		DS.B	16+(8*256*2)+16
Sprit5:		DS.B	16+(8*256*2)+16
Sprit6:		DS.B	16+(8*256*2)+16
Sprit7:		DS.B	16+(8*256*2)+16

NextSpr:	EQU	Sprit2-Sprit0
	IFEQ	NO_PSGWAVE
		CNOP	0,8
PSGSilence:	DS.W	2		; Paula reads this when a voice has nothing to play
PSGChip:	DS.B	6*64		; per PSG channel: the wave as 32, 16, 8, 4, 2 signed bytes
	IFEQ	NO_PSGNOISE
PSGNoise:	DS.B	8192+1024	; random +-120 bytes (PSGMakeNoise); played from a new offset each vblank
	ENDC
	IFEQ	NO_PSGDDA
PSGDdaRing:	DS.B	6*8*264		; per channel 8 queued buffers of DDA samples, one per scanline
PSGDdaHoldBuf:	DS.B	6*264		; per channel: its last DDA level, played when the queue is empty
	ENDC
	ENDC
	MemGuard GrafB


; =----------------------------------------<=



;	------------------------
	SECTION	Tablas,BSS
	IFNE	StripLog
	CNOP	0,4
StripLogBuf:	DS.B	STRIPLOGMAX*32	; (VDP_AGA.asm: in the code section it pushed the tables out of reach)
	ENDC
	IFEQ	NO_POPRAM
PopRAM:	DS.B	32*1024
	ENDC
	IFNE	VdcLog
VdcLogBuf:	DS.B	VDCLOGMAX*16
	ENDC
	IFNE	DbgProbe
PrbSnapA:	DS.B	PrbSnapLen	; DbgProbeScan's snapshots (DbgRows.asm)
PrbSnapB:	DS.B	PrbSnapLen
	ENDC
	IFNE	ScrDump
ScrDumpBuf:	DS.B	1000*128
	ENDC
	IFNE	ScrRing
	CNOP	0,4
ScrRingN:	DS.L	1		; frames logged (header long 0)
ScrRingI:	DS.W	2		; the last slot written (header word 2)
ScrRingBuf:	DS.B	1000*192
	ENDC
;	SECTION	Tablas,Data
;	------------------------
	IFNE	DdaDump
	CNOP	0,4
DdaDumpBuf:	DS.B	DdaDumpSize
DdaDumpEnd:
	ENDC
	IFNE	ProfOn
	IFNE	AutoExit
	CNOP	0,4
ProfHead:	DS.L	4		; "PROF", CodeHunkStart, hunk bytes, samples outside
ProfHist:	DS.L	(ProfCodeEnd-CodeHunkStart+2)/2
	ENDC
	ENDC
	MemGuard TablA

; =----------------------------------------=> Tablas de conversión OBJ "Flip X"
	CNOP	0,8
TablaOBJFlip0:	DS.W	$10000
TablaOBJFlip1:	DS.W	$10000



		CNOP	0,8
	IFEQ	NO_WIDE
SpriteBufer:	DS.B	SprBufWidth*SprBufHeight*4	; bytes per plane row * height * 4 planes
	ELSE
SpriteBufer:	DS.B	((32+256+32)*(64+224+64)*4)/8	; width * height * 4 planes / 8 pixels
	ENDC

		ds.b	128*1024	; EXTRA buffer for SAGA sprites


		CNOP	0,8
			ds.w	6
ScrollChangesBufA:	ds.w	320*3
ScrollChangesBufB:	ds.w	320*3


SpriteDirtyArea0:DS.B	(64+320+64)*8
SpriteDirtyArea1:DS.B	(64+320+64)*8


; =----------------------------------------<=



;	------------------------
;	SECTION	Memoria,BSS
;	------------------------



;	------------------------
;	SECTION	Juego,Data
;	------------------------

;		ds.b	1*1024
;		CNOP	0,8
	MemGuard TablB
	IFD	EMBED
	SECTION	Juego,DATA	; the ROM needs real data: GameCart was in Tablas,BSS
	MemGuard JuegoA
	CNOP	0,8
	ENDC
GameCart:
	IFD	EMBED
	INCLUDE	"embed.i"	; written by build_embed.sh: INCBIN of the test ROM
	ENDC
;		INCBIN	"Cartridges/PD_Mario.pce"
;		INCBIN	"Cartridges/PD_Scroll.pce"
;		INCBIN	"Cartridges/PD_TestScroll.pce"
;		INCBIN	"Cartridges/Gradius.pce"
;		INCBIN	"Cartridges/Salamander.pce"
;		INCBIN	"Cartridges/Parodius.pce"
;		INCBIN	"Cartridges/TwinBee.pce"
;		INCBIN	"Cartridges/Raiden.pce"
;		INCBIN	"Cartridges/1943.pce"
;		INCBIN	"Cartridges/OUTRUN.pce"
;		INCBIN	"Cartridges/Bonk III - Bonk's Big Adventure (US).pce"
GameCartEnd:
	IFD	EMBED
	MemGuard JuegoB
	ENDC
	IFD	EMBED2
	CNOP	0,8
GameCart2:
	INCLUDE	"embed2.i"	; test builds: INCBIN of a second ROM for AutoRestart
GameCart2End:
	ENDC
;		ds.b	8*1024
;		CNOP	0,8

	IFEQ	NO_RTG
	INCLUDE	"RTG.asm"	; own sections: code, data, BSS
	IFNE	AGC
	INCLUDE	"AGCvars.asm"
	ENDC
	ENDC
