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
---------------
- An AGA Amiga (A1200, A4000) with AmigaOS 3.0 or later and a fast
  CPU: an A1200 with a PiStorm, a fast 68060, or a machine of that
  class. On a 68030 or a stock 68020 the games run far below full
  speed, so they are not supported. Without a 68020 and AGA the
  program says "MC68020+ and AGA required!".
- Speed, on an A1200 with a PiStorm (12 November 2026, eight test
  games, 1500 to 2400 frames each): all eight at full speed on RTG;
  on AGA seven at full speed and HuZERO in play at 99%.
  Not tested on a real 68060 card or other fast machines.
- Memory: about 630 KB of chip RAM and 1.3 MB of other RAM for the
  program (from the sizes in the executable), and the game on top.
  The RTG screen, or the AGA picture, takes over 1 MB more from fast
  RAM. If memory runs short on AGA, the program falls back to a
  simpler picture with one set of sprite colours (as in 1.4).
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
Double-click one of the icons in the AmiPCEngine drawer:

  AGA              the Amiga's own (AGA) video output, with the PC
                   Engine's own colours: the picture is drawn in fast
                   RAM with every sprite palette and the full width,
                   and copied into an 8-plane AGA screen, scrolling by
                   hardware where the game scrolls. The screen is
                   always NTSC (60 Hz).
  RTG              the same program with the ToolType RTG: the picture
                   goes to a Picasso96 screen (for example a PiStorm's
                   HDMI output). The menu opens there too, at double
                   height, so no 15 kHz screen is needed.

Up to 1.4 the program was called AmiPCEngine and its RTG icon
AmiPCEngine RTG. If you unpack 2.0 over 1.4, delete those two icons
(and the Debug ones) by hand, and use the new name in Shell scripts
and game launchers.

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
             BLENDSTRONG. OFF is the default. The same setting is the
             menu's Scanlines gadget (ghosted on AGA); it is kept by
             Save Prefs. A SCANLINES ToolType or Shell word wins over
             the saved prefs.
  RTGMODE=AUTO|<width>x<height>|<mode ID>
             RTG only: the Picasso96 screen mode for play. AUTO (the
             default) picks one itself from the 16-bit modes: 960x540
             (an exact 2x on a 1080p display), then 640x480, then the
             smallest mode that holds the picture at 2x, then one
             that holds it at 1x. RTGMODE=800x600 takes the 16-bit
             mode of that size, RTGMODE=$50041100 the mode with that
             ID (hex). The mode has to be 16-bit and at least 352x240.
             The picture is scaled by the largest whole number that
             fits and centred. The same choice is the menu's Display
             gadget; it is kept by Save Prefs. An RTGMODE ToolType or
             Shell word wins over the saved prefs. If the mode can't
             be opened, the automatic choice is used instead.

From a Shell: AGA RTG   (the word RTG, as the ToolType)
              AGA RTG SCANLINES=50
              AGA RTG RTGMODE=800x600

On RTG the screen starts in NTSC (60 Hz), the PC Engine's own rate,
unless the menu's Screen gadget (or your saved prefs) says PAL. On PAL
(50 Hz) the games run at 5/6 speed, and text a game redraws in
mid-frame can look rough. The AGA screen is always NTSC.

The AGA picture is 336 pixels wide, so wide games such as R-Type fit,
and 232 lines high: the bottom 8 lines of a 240-line game are cut. RTG
shows all of them.


4. The menu
-----------
Insert         opens a file requester on the Homebrew drawer. Pick a
               .pce file. A 512-byte copier header is skipped. XPK
               files are unpacked if xpkmaster.library is there.
Power ON       starts the game from the beginning.
Continue       goes back into the game you left with Esc.
Exit           back to Workbench.
Help Page      a summary of the keys and pads.
Backup RAM     the game's save file: "No save file yet", "Save file
               found", "Save file loaded" or "Game saved".
Screen         NTSC (60Hz) or PAL (50Hz), RTG only, for the next
               Power ON or Continue. The AGA screen is always NTSC.
Display        AGA, or on RTG the mode the game is shown in (such as
               RTG 960x540). Pick mode... opens a screen mode
               requester with the 16-bit Picasso96 modes; Automatic
               goes back to the automatic choice (see RTGMODE in
               section 3). A new mode applies at the next Power ON or
               Continue. To switch between AGA and RTG, start the
               other icon.
Scanlines      RTG only (Off, Hard 25%, Hard 50%, Hard 75%, Blended
               light, Blended, Blended strong), see SCANLINES in
               section 3. A new setting applies at the next Power ON
               or Continue.
Joy-Control    the pad on each port, see section 5.
Project menu   About, Help Page, Save Prefs, Quit (right mouse button).
Cartridges     Insert Cartridge, Eject Cartridge.

Save Prefs keeps the Screen, Display (the RTG mode), Scanlines and
Joy-Control settings and the drawer the requester was last in.

On OS 3.5 and later (chooser.gadget) the Screen, Display, Scanlines
and port settings open a list to pick from. Without chooser.gadget,
as on OS 3.1, each click steps to the next setting.

Games that save to backup RAM keep their saves: one 8 KB file per
game in a Saves drawer next to the emulator, named after the ROM.
It's written when you go back to the menu with Esc or Help, and
only if the game changed something, so go back to the menu before
you switch off. The emulator's drawer has to be writable. Delete a
game's file to start it from scratch.


5. Controllers and keys
-----------------------
The PC Engine pad has a d-pad, buttons I and II, Select and Run. The
menu's Help Page calls II "A" and I "B".

Keyboard (always on, whatever the ports are set to)
  Cursor keys            d-pad
  Left Shift, L Amiga    button II
  Space, Left Alt        button I
  Del                    Select
  Return, Help           Run
  Esc                    back to the menu

Joy-Control in the menu sets what is plugged into each port. Port 2
is the joystick port, port 1 the mouse port (unplug the mouse, or
leave port 1 on None). Both ports work the one PC Engine pad, so
either can be used, or both at once.
  None              nothing read on that port
  Joystick          stick = d-pad, fire 1 = II, fire 2 = I
  CD32 Joypad       d-pad, red = II, blue = I, green = Select,
                    yellow = Run, Play = Run (most CD32 adapters send
                    Start as Play), Forward = II, Rewind = I,
                    both shoulder buttons together = back to the menu
  Std Joypad        as Joystick, and fire 3 (pin 5) = Run
The first start has port 1 on None and port 2 on Joystick.

Juan's built-in debugger (keys P, T and S) is not in this program.


6. Speed problems
-----------------
If a game runs slowly on your machine, please report it (section 10).
Builds that draw timing rows on the screen are available on request.


7. What works and what does not
-------------------------------
Tested
  * Our own test set: public domain and homebrew games (PCE Invaders,
    HuZERO, Tongueman's Logic, HuCNoid, Bug Hunt, Island Adventure,
    Krunch, Flipit, UWOL and more), each run for 600 frames or more,
    and 30 commercial HuCards, run in WinUAE and checked against the
    Mesen emulator. Not every game was played through.
  * An A1200 with a PiStorm (RTG over HDMI, and AGA) for speed,
    picture and sound.
  * Not tested: a real 68060 card or other fast machines, ECS or OCS,
    a CD32, RTG boards other than the PiStorm's.
  Not all games work.

Not supported (there is no code for them)
  * CD-ROM, Super CD-ROM and Arcade Card games. HuCards only.
  * SuperGrafx games (no second VDC or priority chip).
  * The sprite overflow and collision flags, multitap, the 6-button
    pad.

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
  * Games 256 pixels wide look narrow on an RTG screen at plain 2x.
  * Beer Girl Stadium: a few sprite colours differ from Mesen.
  * Street Fighter II': the card takes 2.5 MB of Fast RAM.
  * R-Type on AGA: thin dark streaks under some enemies in places.
    They don't affect play.


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
         Version 1.0 came out on 31 October, 1.1 on 2 November,
         1.2 on 3 November, 1.3 on 4 November, 1.4 on 9 November,
         2.0 on 12 November and 2.1 on 14 November.

In short, the changes from v0.5: the HuC6280 timer, the right CPU
speed, many game fixes, a new sound engine, an RTG screen and a faster
CPU core. The list is in CHANGES.md.

Juan's earlier Aminet packages were misc/emu/pcengine_01.lha and
misc/emu/AmiPCEngine.lha; his v0.3, misc/emu/amipc-engine.lha,
replaced the latter in 2020 and stays on Aminet as it is.


9. Credits
----------
  AmiPC-Engine           Juan Antonio Gomez Galvez (GUS Entertainment)
  Versions 1.0 to 2.1    z00p
  Web and menu graphics  Multivac
  With thanks to         Zener and Sandman, and reassembler for his
                         guidance and direction
  Built with             Devpac III (HiSoft) and GadToolsBox (Jaba
                         Development) for the menu code; this release
                         is assembled with vasm.



10. Trademarks, licence, reporting problems
-------------------------------------------
PC Engine is a trademark of NEC and Hudson Soft, and TurboGrafx-16 of
NEC. This program is not affiliated with or endorsed by them.

AmiPCEngine is freeware by Juan Antonio Gomez Galvez (GUS
Entertainment). Versions 1.0 to 2.1, by z00p, are community updates
made and published with his permission.

Please report a game that misbehaves with its name, whether you used
AGA or RTG, your machine (CPU, accelerator or
emulator, and the RTG board or mode) and what you saw:
  https://github.com/z00p/AmiPCEngine/issues