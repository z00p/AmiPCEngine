# Changes from Juan's v0.5

AmiPCEngine is built from the sources of AmiPC-Engine v0.5 (June 1st,
2021) by Juan Antonio Gomez Galvez. This file lists what changed for the
user, grouped. His v0.3 preview (Aminet, 2020) had fewer features still.

## Sound

- All six PSG channels are played, on the Amiga's four voices: the four
  loudest at each frame. v0.5 gave one fixed square wave to channels
  0-3 with frequency and volume only.
- Each channel plays the game's own 32-step waveform at its real pitch,
  with its volume and left/right balance (the Amiga's voices are hard
  left or right, so a centred channel comes out of one side).
- Noise on channels 5 and 6 (drums, explosions), at the game's noise
  rate.
- DDA samples (voices and drums in Soldier Blade, Parodius Da!, Bonk's
  Revenge, Air Zonk, Blazing Lazers and others) are captured as the game
  writes them and played a frame or two later. Games that write one
  sample per timer tick are captured by tick, which is much cleaner. A
  sample stream keeps its voice until it has played out, so music no
  longer cuts it short.
- Below full speed DDA samples are stretched (up to 1.5x) instead of
  breaking up.
- Limits: no LFO, no tones above about 14 kHz, quietest channels
  dropped when five or six play.

## Picture on the Amiga's own (AGA) output

- Games wider than 256 pixels (R-Type: 320 on the title, 336 in play)
  get up to 288 pixels, with the rest cut evenly from both sides.
- Sprite colours no longer overwrite background palette 15 (R-Type's
  status bar was solid blue and orange). Colour 0 shows in every
  palette.
- Sprites a game parks off-screen (Y beyond line 512) are no longer
  wrapped onto the screen (copies and garbled columns in Beer Girl
  Stadium and Bug Hunt).
- UWOL: the junk along the bottom is gone (the picture height follows
  the VDC).
- NTSC picture centred: it sat 19 lines low and the bottom rows (score
  and lives) fell off the screen.
- The screen starts in NTSC (60 Hz) unless saved prefs say PAL.

## RTG display (new)

- A Picasso96 screen, on with the ToolType RTG (the "AmiPCEngine RTG"
  icon) or the CLI word RTG. The frame is built in fast RAM and only
  the changed lines are copied to the screen at each Amiga vertical
  blank, so there is no drawing to chip RAM and no bitplane, copper or
  sprite DMA while a game runs.
- All 16 sprite palettes, the full width of the picture, sprite
  priority, mid-frame palette changes (striped logos).
- 960x540 is chosen first (an exact 2x of 1080p), then 640x480. 8-bit
  menu screen at double height so the menu fills the screen.
- Optional scanlines at 2x or more: every other row darkened by 25, 50
  or 75%, or blended from the lines above and below. ToolType or Shell
  word `SCANLINES=OFF|25|50|75|BLEND`, or Options > RTG scanlines in the
  menu; kept by Save Prefs.
- Without Picasso96, a suitable mode or the memory, it falls back to the
  AGA screen.

## Speed

- The HuC6280 now gets its real 455 cycles per scan line (v0.5 gave it
  340, 75% of real speed), so games written in HuC, such as HuCNoid,
  no longer run at about half speed.
- Juan's debugger is no longer built in (it checked every emulated
  instruction), loops where a game polls or waits are fast-forwarded
  with the same result, and a few inner loops are cheaper. About 75%
  faster overall on a 68030/50 in WinUAE, up to 2-3 times in R-Type,
  Soldier Blade and PCE Invaders.
- On an A1200 with a PiStorm, with the RTG screen, all five test games
  ran at full speed.

## Games that now work or work better

- HuC6280 timer and its interrupt (v0.5 had none).
- Block transfers (TII, TDD, TIN, TIA, TAI) cross memory pages and
  reach the I/O page correctly. This fixed the text colours in
  Nantettatte Engine and Reflectron, the leftovers over Meteor Blaster
  DX's title, and Atlantean's black screen.
- Backup RAM is formatted at power on, so Atlantean gets past "failed to
  create high score file".
- CSL (slow clock) is honoured, so Soldier Blade's intro and attract
  mode run.
- Games that set the sprite and background enable bits at raster splits
  (R-Type) show their sprites.
- Parodius Da! plays on an NTSC screen at the right speed (on PAL every
  game runs at 5/6 speed).
- The vertical blank interrupt comes right after the last picture line,
  as on the console, not at a fixed line: Atlantean's raster effects no
  longer miss every other frame (the bottom of the screen jittered).
- An interrupt raised while another one is being handled is taken when
  that handler returns, not at the next line: Parodius Da!'s power meter
  no longer bounces by a line.
- Background rows follow a game that changes only the low byte of the
  horizontal scroll on every line: HuZERO's track curves as it should.
- TSB, TRB, TST and the read-modify-write instructions reach the VDC and
  the other I/O ports, with the flags the CPU really sets: Parasol
  Stars' title graphics are no longer scrambled.

## Controllers

- Joystick mode: fire 2 was read from the wrong pin and held Right
  down, so the bat drifted right in HuCNoid. Fixed.
- CD32 pad: the d-pad and buttons were swapped. Fixed. Play is now Run
  (most CD32 adapters send Start as Play); both shoulder buttons
  together go back to the menu.

## Stability

- Games with many scroll changes in a frame (HuZERO) overran the copper
  list and corrupted memory (Software Failure 8100 0005). Fixed.
- A sprite in the bottom-right corner of the wider picture wrote past
  the emulator's tables, which could crash the Amiga later (8000 0004
  after R-Type). Fixed.
- Cleaner failures: if the RTG menu screen or the play screen cannot be
  opened the program falls back or says so in the menu.

## Menu and package

- The Insert requester opens on the Homebrew drawer next to the program
  (v0.5 used a "Cartridges" drawer).
- The version is 1.0 in the window title, the About box (which now
  also credits version 1.0) and the `$VER` string, which still said
  v0.3. The Help Page lists the CD32 pad and joystick buttons as they
  work now.
- A PC Engine icon, an AGA and an RTG icon, a ReadMe with the keys and
  limits, and a legend for the optional debug rows.

## Build

- Assembles with vasm (Devpac-compatible mode), no code change needed.
  Debug and test code sits behind assembly switches, off by default.