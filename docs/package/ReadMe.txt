AmiPCEngine @VERSION@
=====================

A PC Engine / TurboGrafx-16 emulator for AGA Amigas, by Juan Antonio
Gomez Galvez and z00p, in 68020+ assembly.

AmiPCEngine takes over the machine while a game runs and drives the
Amiga's custom chips directly (or a Picasso96 screen, see RTG below).
Esc returns to the menu.

You need HuCard images (.pce files) of your own. None are included.
They have to be copies you may legally have, for example dumps of
cards you own, or homebrew games whose authors allow it.


Contents
--------
  1. Requirements
  2. Installation
  3. Running it: AGA and RTG
  4. The menu
  5. Controllers and keys
  6. Debug rows
  7. What works and what does not
  8. History
  9. Credits
 10. Trademarks, licence, reporting problems


1. Requirements
---------------
- An AGA Amiga (A1200, A4000) with a 68020 or better, running AmigaOS
  3.0 or later. On anything else the program says "MC68020+ and AGA
  required!".
- Speed: Juan's own readme asked for a 68060 at 50 MHz. In our tests:
  * A1200 with a PiStorm, RTG screen: five test games ran at full
    speed (every emulated frame in one Amiga frame, over 1500 to 2400
    frames each).
  * A1200 with a PiStorm, AGA screen: Street Fighter II' at 99% of
    full speed, Parasol Stars 96%, Soldier Blade 92%, Parodius Da!
    91%, HuZERO in play 89% (measured on 2 Nov 2026).
  * 68030 at 50 MHz: tested in WinUAE only, not on a real machine.
    There the same games ran at roughly 30% to 90% of full speed on
    the AGA screen, depending on the game (HuZERO slowest, PCE
    Invaders fastest), and at only about 10% to 35% on an RTG screen
    (how much of that is down to WinUAE's emulated graphics card is
    not known).
  * A stock 68020 A1200: only seen in WinUAE, where it ran about 13
    frames a second in a simple game (PCE Invaders, an early build,
    before the speed work). Expect slow play.
- Memory: about 630 KB of chip RAM and 1.2 MB of other RAM for the
  program (from the sizes in the executable), and the game on top. The
  RTG screen takes about 1.1 MB more, from fast RAM, when it is on.
  If memory runs short, RTG is not used and the AGA screen takes over.
- For RTG: Picasso96 and a 16-bit screen mode. The menu uses an 8-bit
  mode of at least 640x212 (640x480 is best). 960x540 is the first
  choice for play, because it is an exact 2x on a 1080p display.
- Optional: xpkmaster.library, to load XPK-packed cartridge files.
- While a game runs the program has the machine and the system is
  frozen. Leave with Esc, not with a reset.


2. Installation
---------------
Copy the AmiPCEngine drawer to your hard disk or CF/SD card, anywhere.
Keep the files together. "Save Prefs" writes S:AmiPC-Engine.prefs.

The Homebrew drawer inside is where the Insert requester opens. It is
empty. Put your .pce files in it, or browse to them anywhere else.


3. Running it: AGA and RTG
--------------------------
Double-click one of two icons:

  AmiPCEngine      the Amiga's own (AGA) video output.
  AmiPCEngine RTG  the same program with the ToolType RTG: the picture
                   goes to a Picasso96 screen (for example a PiStorm's
                   HDMI output). The menu opens there too, at double
                   height.

The RTG screen gives every one of the 16 sprite palettes, the full
width of the picture, and no flicker from drawing while the picture is
shown. If Picasso96 or a suitable mode is missing, or there is not
enough memory, the program carries on in AGA mode.

ToolTypes (in the icon's Information window):
  RTG        use the Picasso96 screen
  SCANLINES=OFF|25|50|75|BLENDLIGHT|BLEND|BLENDSTRONG
             RTG only, at 2x or more: every other screen row darkened
             by 25, 50 or 75 percent, or blended: the dark row is the
             mix of the lines above and below it, at 75 percent
             brightness for BLENDLIGHT, 50 for BLEND and 25 for
             BLENDSTRONG. OFF is the default. The same setting is in
             the menu: Options > RTG scanlines (ghosted without RTG);
             it is kept by Save Prefs. A SCANLINES ToolType or Shell
             word wins over the saved prefs.

From a Shell: AmiPCEngine RTG   (the word RTG, as the ToolType)
              AmiPCEngine RTG SCANLINES=50

The screen starts in NTSC (60 Hz), the PC Engine's own rate, unless
your saved prefs say PAL. On PAL (50 Hz) the games run at 5/6 speed,
and text a game redraws in mid-frame can look rough.

The AGA picture is up to 288 pixels wide; wider games (R-Type is 320
on the title and 336 in play) lose an equal strip at each side. It is
232 lines high, so the bottom 8 lines of a 240-line game are cut. RTG
shows all of both.


4. The menu
-----------
Insert         opens a file requester on the Homebrew drawer. Pick a
               .pce file. A 512-byte copier header is skipped. XPK
               files are unpacked if xpkmaster.library is there.
Power ON       starts the game from the beginning.
Continue       goes back into the game you left with Esc.
Exit           back to Workbench.
Help Page      a summary of the keys and pads.
Screen         shows PAL (50Hz) or NTSC (60Hz). Change it under Menu
               Screen in the Project menu (right mouse button); the
               gadget itself is ghosted.
Joy-Control    the controller type, see below. The Port gadget is left
               as Juan made it; only one pad is emulated.
Project menu   About, Help Page, Menu Screen, Save Prefs, Quit.
Cartridges     Insert Cartridge, Eject Cartridge.

Options > RTG scanlines (Off, Hard 25%, Hard 50%, Hard 75%, Blended
               light, Blended, Blended strong)
               see SCANLINES in section 3. A new setting applies at
               the next Power ON or Continue.

Several entries from Juan's menu are ghosted and do nothing in this
version: Cheat mode, Save VRAM, Load/Save Frozen, the RAM-Battery
items, the rest of the Options menu, and the Read/Save RAM-Batt and
Clear RAM gadgets. The Refresh and Inter gadgets and the Emulation
Speed bar are ghosted too.

Games that save to backup RAM start with a formatted, empty one each
time. Nothing is kept between runs.


5. Controllers and keys
-----------------------
The PC Engine pad has a d-pad, buttons I and II, Select and Run. The
menu's Help Page calls II "A" and I "B".

Keyboard (always on, in every Joy-Control mode)
  Cursor keys            d-pad
  Left Shift, L Amiga    button II
  Space, Left Alt        button I
  Del                    Select
  Return, Help           Run
  Esc                    back to the menu

Joy-Control in the menu picks the pad in the Amiga's joystick port:
  Amiga JoyStick    stick = d-pad, fire 1 = II, fire 2 = I
  Keyboard Only     the keyboard only
  CD32 Joypad       d-pad, red = II, blue = I, green = Select,
                    yellow = Run, Play = Run (most CD32 adapters send
                    Start as Play), Forward = II, Rewind = I,
                    both shoulder buttons together = back to the menu
  Standard Joypad   reads like Amiga JoyStick in this version (fire 1
                    = II, fire 2 = I; a third button is not read)

Juan's built-in debugger (keys P, T and S) is not in this program.


6. Debug rows
-------------
The drawer has "AmiPCEngine Debug" and "AmiPCEngine RTG Debug". They
are the same programs with two rows of hex numbers drawn at the top of
the screen, updated every 50 Amiga frames. They show whether a game
runs at full speed on your machine: with FRMS equal to VBLS it does.
Photograph the rows if you report a speed problem. Every number is
explained in "Debug rows.txt". The normal icons show no rows.


7. What works and what does not
-------------------------------
Tested
  * Our own test set: public domain and homebrew games (PCE Invaders,
    HuZERO, Tongueman's Logic, HuCNoid, Bug Hunt, Island Adventure,
    Krunch, Flipit, UWOL and more), each run for 600 frames or more,
    and 30 commercial HuCards, run in WinUAE and checked against the
    Mesen emulator. Not every game was played through.
  * An A1200 with a PiStorm (RTG over HDMI) for RTG, speed and sound.
    AGA was tested less there.
  * A 68030/50 only in WinUAE.
  * Not tested: a real 68030, 68040 or 68060 card, ECS or OCS,
    a CD32, RTG boards other than the PiStorm's.
  Not all games work.

Not supported (there is no code for them)
  * CD-ROM, Super CD-ROM and Arcade Card games. HuCards only.
  * SuperGrafx games (no second VDC or priority chip).
  * The sprite overflow and collision flags, multitap, the 6-button
    pad. Backup RAM is not saved.
  * On AGA, sprite priority per sprite: all sprites go behind the
    background only in a frame where every one of them asks for it,
    otherwise all stay in front. Every sprite shares one set of
    colours, so some come out wrong (R-Type, the power meter in
    Parodius Da!, the Earth on HuZERO's title). RTG handles both.

Sound
  Six PSG channels play on the Amiga's four, the four loudest at each
  frame, each with the game's own waveform at its pitch, volume and
  balance. Noise (drums, explosions) and DDA samples (voices and drums
  in Soldier Blade and Parodius Da!) are played. Limits:
  * Amiga channels are hard left or right, so a centred PC Engine
    channel comes out of one side.
  * With five or six channels playing, the quietest are dropped.
  * No LFO (channel 2 is silent while it is on); no tones above about
    14 kHz.
  * DDA samples are played a frame or two late. On a PAL screen they
    play about 1/6 low, like the game. Below full speed they are
    stretched (up to 1.5x), and then break up.

Known faults
  * Parodius Da!: after PLAY SELECT the ship is picked with button I,
    not Run (as on the real console).
  * Sprites can flicker or tear on AGA: the picture is drawn while it
    is on screen (one buffer). RTG does not do this.
  * Games 256 pixels wide look narrow on an RTG screen at plain 2x.
  * Beer Girl Stadium: a few sprite colours differ from Mesen.
  * Parasol Stars on AGA: sprites use one palette, so the player's
    colours are wrong.
  * On AGA only colour 0 follows mid-frame changes: HuZERO's road and
    Tongueman's Logic's gradient do, HuZERO's striped logo does not.
    RTG shows them all.
  * Tongueman's Logic on AGA: the sprite scenery shows over the
    background during the title's transition.
  * Street Fighter II': the card takes 2.5 MB of Fast RAM.


8. History
----------
  1997   Juan Antonio Gomez Galvez starts AmiPC-Engine. The first
         "Version Alpha", about 1997, is "abandoned due the Amiga AGA
         limitations" (his words, in his later readme).
  2011   Version 0.1, on Aminet.
  2020   Version 0.3, a preview, on Aminet on 30 June, for his friend
         Carlos Peris's birthday: 4 of the 6 sound channels, one
         sprite palette, and "68060 at 50mhz" as the minimum for real
         speed.
  2021   Version 0.5 (June 1st, 2021): the version in the sources and
         in the About box. It was never released.
  2026   Juan sent his sources. This community update, released with
         his permission, is built from them. It finishes what he
         started: all
         six sound channels, DDA samples, every sprite palette on an
         RTG screen, and full speed on an A1200 with a PiStorm.
         Version 1.0 came out on 31 October, 1.1 on 2 November.

In short, the changes from v0.5: the HuC6280 timer, the right CPU
speed, many game fixes, a new sound engine, an RTG screen and a faster
CPU core. The list is in CHANGES.md.

Juan's earlier Aminet packages were misc/emu/pcengine_01.lha and
misc/emu/AmiPCEngine.lha; his v0.3, misc/emu/amipc-engine.lha,
replaced the latter in 2020 and stays on Aminet as it is.


9. Credits
----------
  AmiPC-Engine           Juan Antonio Gomez Galvez (GUS Entertainment)
  Versions 1.0 and 1.1   z00p
  Web and menu graphics  Multivac
  With thanks to         Zener and Sandman
  Built with             Devpac III (HiSoft) and GadToolsBox (Jaba
                         Development) for the menu code; this release
                         is assembled with vasm.



10. Trademarks, licence, reporting problems
-------------------------------------------
PC Engine is a trademark of NEC and Hudson Soft, and TurboGrafx-16 of
NEC. This program is not affiliated with or endorsed by them.

AmiPCEngine is freeware by Juan Antonio Gomez Galvez (GUS
Entertainment). Versions 1.0 and 1.1, by z00p, are community updates
made and published with his permission.

Please report a game that misbehaves with its name, whether you used
AmiPCEngine or AmiPCEngine RTG, your machine (CPU, accelerator or
emulator, and the RTG board or mode) and what you saw:
  https://github.com/z00p/AmiPCEngine/issues