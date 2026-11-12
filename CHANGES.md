# Changes from Juan's v0.5

AmiPCEngine is built from the sources of AmiPC-Engine v0.5 (June 1st,
2021) by Juan Antonio Gomez Galvez. This file lists what changed for the
user, grouped. His v0.3 preview (Aminet, 2020) had fewer features still.

## New in 2.0

- Two programs in the drawer: AGA and RTG (the same program with the
  ToolType RTG; the menu opens on the RTG screen, no 15 kHz screen is
  needed). Up to 1.4 they were AmiPCEngine and AmiPCEngine RTG.
  Unpacking over 1.4 leaves the old icons: delete them by hand, and
  use the new name in Shell scripts and game launchers. The Debug
  versions are no longer in the archive; they are available on
  request.
- AGA now shows the PC Engine's own colours. The picture is drawn as
  on RTG (every sprite palette, the full width) and copied into an
  8-plane AGA screen; only the parts that changed are copied, and
  scrolling is done by the hardware, with a fixed status bar (as in
  Parodius Da!) scrolled apart from the stage. It needs a fast
  machine: an A1200 with a PiStorm, a fast 68060 or similar. 68030
  and 68020 machines are no longer supported.
- Sound: a sampled (DDA) channel that a game switches off for a
  moment keeps its Amiga voice. Blazing Lazers' drums no longer click
  and cut into a harmony part on every beat.
- The simpler AGA picture of 1.4, still used when memory runs short:
  sprites no longer leave a ghost where they moved, fewer go missing
  (R-Type), and Street Fighter II' fights are drawn on a real A1200.
- New launcher: Screen (NTSC / PAL, on RTG) and Scanlines are gadgets
  in the window, kept by Save Prefs, and Display shows AGA or RTG.
  Each port has its own pad type (None, Joystick, CD32 Joypad, Std
  Joypad), and both ports are read. On OS 3.5 and later the settings
  open a list to pick from. The backup RAM state is shown (no save
  file yet, found, loaded, game saved). Juan's gadgets and menu items
  that did nothing are gone.

## New in 1.4

- Controls answer a frame sooner. Each emulated frame now starts at the
  PC Engine's vertical blank, so the game reads the pad first and the
  picture it draws is shown one frame (20 ms) earlier. Measured: the
  first changed picture after a press came one frame sooner in R-Type,
  Parodius Da! and Soldier Blade.
- RTG screen: each frame starts as late as is safe and the pad is read
  again just before it, a further 11 to 14 ms on an A1200 with a
  PiStorm.
- AGA screen: Parodius Da! no longer slows to about 17 frames a second
  after a bell's screen flash; tiles a game rewrites unchanged are not
  redrawn, which makes some games faster (Meteor Blaster DX, Gomola
  Speed).
- Sound: with the PAL screen setting, DDA samples keep time better, so
  they are trimmed less often (a small timing error fixed).

## New in 1.3

- More games run or look right: TaleSpin, Cyber Cross, Lode Runner:
  Lost Labyrinth, Momotarou Densetsu Gaiden and Momotarou Densetsu II,
  Power Tennis, Bikkuriman World, Benkei Gaiden and Dragon Egg! (see
  "Games that now work" below).
- Sprites are shown one frame after the game sets them, as on the
  console, so they keep in step with a scrolling background (Power
  Tennis's net no longer shows a black block when the camera moves).
- Sound: a channel keeps its Amiga voice longer, so a sound jumps
  between the left and right speakers less often.

## New in 1.2

- Backup RAM saves: a game's saves (high scores, progress) are kept in
  a Saves drawer next to the emulator, one 8 KB file per game, written
  when you go back to the menu and only if the game changed something.
- More games run or look right, from a test of every HuCard in a full
  library against Mesen: Order of the Griffon, Coryoon, Cyber Core,
  Download, Tricky Kick, Chew Man Fu, Battle Royale, Maniac Puroresu,
  Night Creatures, Psychosis, Energy, Deep Blue Kaitei Shinwa, Ganbare
  Golf Boys, Rock-On, World Circuit, Andre Panza Kick Boxing and
  Fighting Run (see "Games that now work" below).

## New in 1.1

- Street Fighter II' Champion Edition runs (its 2.5 MB mapper), and
  Populous (the 32 KB of RAM on its card).
- The Legendary Axe, Magical Chase, The Great Fumo Binning, Special
  Ninja Squad, Dungeon Explorer's panel and Parasol Stars run or look
  right, after CPU and VDC fixes (see "Games that now work" below).
- AGA: colour 0 follows the raster (HuZERO's road, Tongueman's Logic's
  gradient), and sprites go behind the background on frames where they
  all ask for it (Parasol Stars' title). No loss of speed on an A1200
  with a PiStorm.
- RTG: scanlines Blended light and Blended strong.

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
- Colour 0 changes line by line where a game changes it (HuZERO's road,
  Tongueman's Logic's gradient). The borders go black on those frames.
- Sprites go behind the background in a frame where every visible
  sprite asks for that (Parasol Stars' clouds on the title). All
  sprites share one priority for the frame, so a mix stays in front.
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
  or 75%, or blended from the lines above and below at three strengths
  (light, normal, strong). ToolType or Shell word
  `SCANLINES=OFF|25|50|75|BLENDLIGHT|BLEND|BLENDSTRONG`, or Options > RTG
  scanlines in the menu; kept by Save Prefs.
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

- 1.3: a game that polls the vblank flag with its interrupt on sees it
  (Cyber Cross's title, Lode Runner: Lost Labyrinth's fade-in); LDA
  (zp) through a pointer into the I/O page reads the I/O port (TaleSpin);
  TST reads a ROM table, not the bank's write side (Momotarou Densetsu
  Gaiden and II's menu text); the vblank comes part way into a line that
  also has a raster interrupt (Power Tennis, Benkei Gaiden, Dragon Egg!);
  ROM mapped into the first 8 KB slot is read as ROM, not as I/O
  (Bikkuriman World).
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
- Video memory writes past the last word are lost, as on the console,
  and no longer wrap round to the start: HuZERO's road is no longer
  scrambled in play.
- 384 KB cards are mapped as the console maps them (the last 128 KB at
  banks $40-$7F): Parasol Stars runs on RTG and its enemies show on AGA.
  Other cards mirror across all the banks.
- AGA: a game changing its map size no longer leaves stale tiles on
  screen (Parasol Stars' levels).
- Street Fighter II' Champion Edition: the 2.5 MB mapper. The card needs
  2.5 MB of Fast RAM.
- Populous: the 32 KB of RAM on its card.
- The VDC's VRAM-to-VRAM DMA, its end interrupt and the end-of-SAT
  interrupt: The Legendary Axe and Magical Chase start.
- The CPU's T flag (SET): The Legendary Axe's map was missing every
  other column.
- The CPU's decimal mode, used for scores and timers.
- A raster interrupt on the vblank line and the vblank are two
  interrupts, not one: The Great Fumo Binning gets past its title.
- VRAM reads go through the VDC's read-ahead buffer: Special Ninja
  Squad's logo unpacks properly.
- Scroll writes just after a line starts count for the line before:
  Dungeon Explorer's status panel sits where it should.
- The stack wraps inside its page, as on the CPU: Tricky Kick and
  Coryoon start.
- An interrupt waiting when the game clears the I flag is taken one
  instruction later, as on the CPU: Order of the Griffon starts.
- The I/O page's data buffer: the unused bits of the I/O ports read
  back the last byte written there, as on the console. Download and
  Cyber Core start.
- With background and sprites both off, the screen shows the colour the
  console shows: Chew Man Fu's green screen is gone.
- The stack pointer at power on is set as the console sets it, so games
  that never set it themselves no longer crash at the first interrupt:
  Psychosis (Paranoia), Energy, Night Creatures, Deep Blue Kaitei
  Shinwa, Ganbare Golf Boys.
- The timer counter reads $7F just before it runs out from 0: Battle
  Royale gets past its title.
- Long block transfers take their real time, up to several frames,
  instead of one line: Maniac Puroresu starts.
- A palette colour written one byte at a time changes at once: World
  Circuit's backdrop.
- RTG: the picture is placed by the display start alone, not moved by
  the sync width, so it no longer sits off to one side in some games.
- The video chip's ports are reached whatever memory bank the game has
  paged in.
- RTG: sprites in the video chip's 2-plane mode are drawn (Fighting
  Run's portraits).

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
- The version is right in the window title, the About box (which now
  also credits z00p's versions) and the `$VER` string, which still said
  v0.3. The Help Page lists the CD32 pad and joystick buttons as they
  work now.
- A PC Engine icon, an AGA and an RTG icon, a ReadMe with the keys and
  limits, and a legend for the optional debug rows.

## Build

- Assembles with vasm (Devpac-compatible mode), no code change needed.
  Debug and test code sits behind assembly switches, off by default.