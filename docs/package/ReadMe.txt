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
  speed, so they are not supported.
- Without AGA (an A500 or A2000 with a PiStorm, for example) it runs
  on RTG only: Picasso96 and a 16-bit screen mode. The Display
  setting stays on RTG.
- Without a 68020, or with neither AGA nor RTG, the program says
  "Needs 68020+ and AGA or RTG!".
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
                   NTSC (60 Hz) unless Screen says PAL.
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
  CDMUSIC=<percent>
             CD games: the CD music's level in the sound mix, as a
             percentage of the disc's own level, 0 to 400. The
             default is 200. Loud tracks may clip at 200 or more.
  SOUNDMIX   start with the Sound menu on Full channel mix (see
             section 4), over the saved prefs.
  PLAINNTSC  on a PAL Amiga, the NTSC screen is the chipset's own
             NTSC frame, as in 2.1: games run 0.9% slow. Without it
             (the default) the program sets up a 262-line frame at
             the PC Engine's rate. Use it only for a display or an
             emulator that shows a black screen otherwise (WinUAE
             did, until its NTSC box was ticked).

From a Shell: AGA RTG   (the word RTG, as the ToolType)
              AGA RTG SCANLINES=50
              AGA RTG RTGMODE=800x600
              AGA CDMUSIC=150
              AGA SOUNDMIX

Starting a game straight away (from a Shell, a script or a game
launcher such as Lupa):

  AGA [HuCard] [AGA|RTG] [ONEGAME] [MENU] [PROFILE=030|FAST|AUTO]

  HuCard     the file to load: the first word that isn't one of
             these, or a "quoted" name (with spaces). It is loaded as
             Insert would and started at once.
  AGA / RTG  the display for this run, over the RTG ToolType.
  ONEGAME    leaving the game (Esc, Help, or both CD32 shoulder
             buttons, with Play in six-button games) quits the
             program, after the game is saved, so you go straight
             back to the launcher. A HuCard that can't be loaded
             shows the error, then quits.
  MENU       load the HuCard but stay in the menu.
  PROFILE=   accepted for launchers that use it; this program has
             one profile (030 still runs, with return code 5).

  For example:
    AGA "Work:PC Engine/Homebrew/HuZERO.pce" RTG ONEGAME

A HuCard project icon whose default tool is the AGA program (with its
full path) works the same way, and its ToolTypes may hold RTG, AGA,
ONEGAME and MENU.

Return codes (for scripts and launchers): 0 normal, 5 ran with a
fallback (RTG asked for but not available, or PROFILE=030), 10 the
HuCard could not be loaded (with ONEGAME), 20 this Amiga can't run
the program (no 68020, or neither AGA nor RTG).

The screen starts in NTSC (60 Hz), the PC Engine's own rate, unless
the menu's Screen gadget (or your saved prefs) says PAL. PAL (50 Hz)
is there for TVs and monitors that won't take 60 Hz: the games run at
5/6 speed, sound and music too, and on RTG text a game redraws in
mid-frame can look rough. (Up to 2.2 the AGA screen was always NTSC.)

On a PAL Amiga the NTSC screen runs a programmed frame of 262 lines
at 59.90 Hz, close to the PC Engine's 59.83 Hz. (The chipset's own
NTSC frame on a PAL Amiga is 59.28 Hz, and up to 2.1 games ran 0.9%
slow.) An NTSC Amiga uses its own NTSC frame, which is already right.

The AGA picture is 336 pixels wide, so wide games such as R-Type fit,
and 232 lines high: the bottom 8 lines of a 240-line game are cut. RTG
shows all of them.


4. The menu
-----------
Insert         opens a file requester on the Homebrew drawer. Pick a
               .pce file. A 512-byte copier header is skipped. XPK
               files are unpacked if xpkmaster.library is there.
               A .cue file loads a CD-ROM game (see CD-ROM in 7).
Power ON       starts the game from the beginning.
Continue       goes back into the game you left with Esc.
Exit           back to Workbench.
Help Page      a summary of the keys and pads.
Backup RAM     the game's save file: "No save file yet", "Save file
               found", "Save file loaded" or "Game saved".
Screen         NTSC (60Hz, the default) or PAL (50Hz, 5/6 speed), for
               the next Power ON or Continue (see section 3).
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
Sound menu     how the PC Engine's six sound channels are played (see
               Sound in section 7), from the next Power ON or
               Continue.
               Original stereo   the channels share Paula's four
                                 voices (the default).
               Full channel mix  all six through a software mix.
               CD music          ticked (the default): a CD game's
                                 music is loaded with the disc. Not
                                 ticked: the CD music is left out,
                                 silent, and needs no Fast RAM;
                                 sound effects and ADPCM speech stay.
                                 From the next Insert of a .cue.
Tone menu      Bright (unfiltered), Soft (4.5 kHz), Warm (A1200
               filter): Soft, the default, cuts the treble of the
               Full channel mix a little; Warm turns on the Amiga's
               own audio filter (the one tied to the power light)
               while a game plays, in either mode. On Original
               Stereo, Soft sounds as Bright.

Save Prefs keeps the Screen, Display (the RTG mode), Scanlines,
Joy-Control, Sound (with CD music) and Tone settings and the drawer
the requester was last in.

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
leave port 1 on None). With port 1 on None, port 2 and the keyboard
work the one PC Engine pad. With a pad set on both ports, the game
sees a multitap with two pads: port 2 is player 1 (with the
keyboard), port 1 is player 2. Two-player games such as Bomberman
'94 and the VS modes of fighting games then have a pad each.
  None              nothing read on that port
  Joystick          stick = d-pad, fire 1 = II, fire 2 = I, and a
                    third fire button (pin 5), where there is one,
                    = Run
  CD32 pad          a CD32 pad or adapter, see below
  CD32 (KTRL+)      the same, with the pad clocked the other way
                    round. The KTRL CD32+ and the Mega Multi adapter
                    in CD32 mode want it; the first KTRL CD32 and
                    most adapters want CD32 pad. Try the other one
                    when a pad misses or mixes up buttons.
The first start has port 1 on None and port 2 on Joystick.

A CD32 pad works as a PC Engine pad with two or six buttons, picked
by the game: the emulator watches how the game reads the pad. Nearly
every game reads it as a two-button pad:
  red = II, blue = I, green = Select, yellow = Run, Play = Run (most
  CD32 adapters send Start as Play), left shoulder = Select, right
  shoulder = Run; both shoulders together = back to the menu.
Games made for the six-button pad (Avenue Pad 6), such as Street
Fighter II' and Art of Fighting, get one, a fraction of a second after
they start reading it that way:
  red = II, blue = I, green = III, yellow = IV, left shoulder = V,
  right shoulder = VI, Play = Run, Del on the keyboard = Select; both
  shoulders and Play together = back to the menu.
The real pad has a 2/6 switch, as games not made for it misread it
in six-button mode; here that choice is made for you.

PadCheck, in the AmiPCEngine drawer, is a small Amiga program that
reads the two joystick ports as the emulator does in a game, with the
Workbench still running: the stick and fire buttons, and the CD32 read
both ways. Hold the buttons one by one and it shows what arrives, and
it says which Joy-Control setting suits the pad. Other pad testers go
through the OS (lowlevel.library, Poseidon), so they show pads that
the emulator can't read in a game, USB pads above all. On some
systems they also show a pad in a joystick port a second time, as a
third or fourth port, as if it were a USB pad, with no USB pad
plugged in. Close them while PadCheck runs: two programs reading a
CD32 pad in one frame make it unsteady.

Pad test: PadTest.pce and PadTest6.pce in the Homebrew drawer are
small HuCards of our own. Each lists the PC Engine buttons with the
CD32 pad and joystick buttons that drive them, and a box that turns
green while the game sees the button held. PadTest reads the pad as
nearly all games do (two buttons), PadTest6 as games made for the
six-button pad do (III to VI as well). If a button flickers or does
nothing in a game, run them, try the other CD32 setting (CD32 pad or
CD32 (KTRL+)), and send a photo of the screen with the name of your
pad or adapter.

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

CD-ROM (beta)
  CD-ROM and Super CD-ROM games load from a CUE sheet with BIN (2352-
  byte sectors) or ISO (2048) files: pick the .cue with Insert, or
  give it on the command line. A CHD image has to be converted first,
  on a PC with MAME's chdman:
    chdman extractcd -i game.chd -o game.cue -ob game.bin
  * The System Card is needed: cd_bios.rom or syscard3.pce next to the
    .cue, or syscard3.pce or cd_bios.rom in the AmiPCEngine drawer.
    Use System Card 3.0 (it also runs Super CD-ROM games). A US card
    dump is turned round on loading.
  * The disc is read into RAM before the game starts, each file once
    from start to end: the data tracks (a few MB up to about 30 MB)
    and the CD music, at about half its size in the BIN file. Gradius
    II (a 520 MB BIN) takes about 40 seconds over a network share on
    a PiStorm A1200. Use a machine with plenty of Fast RAM: when it
    runs out, the rest of the music stays silent.
  * A small copy without the CD music loads in seconds and needs much
    less Fast RAM: cdshrink makes one on a PC, keeping the sound
    effects and ADPCM speech (Gate of Thunder: 533 MB to 26 MB). It is
    in the PC Tools drawer, with cdshrink.txt on how to use it.
  * CD music and ADPCM speech play. A CD game sends all its sound,
    the PSG too, through the software mix, on AGA and RTG. The music
    level is the CDMUSIC ToolType.
  * Each CD game has its own save file in the Saves drawer, named
    after its .cue. A disc without one starts from the shared
    "CD-ROM System" file that 2.2 used for all CD games, so 2.2
    saves carry over.
  * Gradius II, Star Parodier, Gate of Thunder and Rainbow Islands
    play with music and speech on a PiStorm A1200; Castlevania -
    Rondo of Blood, Valis II and Fighting Street in WinUAE.
  * ADPCM speech matches the Mesen emulator's sample for sample in
    Gate of Thunder.
  * Arcade Card (beta): CD games get an Arcade Card with its 2 MB, so
    the games that need one run, with System Card 3.0 as above. Art of
    Fighting (Ryuuko no Ken) and Strider Hiryuu play on a PiStorm
    A1200. It needs 2 MB more Fast RAM while a CD game runs.

Not supported (there is no code for them)
  * SuperGrafx games (no second VDC or priority chip).
  * The sprite overflow and collision flags.
  * USB pads and keyboards (Poseidon or other USB stacks). The emulator
    stops the OS while a game runs and reads the two joystick ports
    directly, so a USB stack can't run during play. Use a pad in a
    joystick port: a CD32 pad, or a joystick-port adapter for other
    pads (Joy-Control, Joystick setting). PadCheck shows what the
    emulator sees (section 5).

Sound
  Original stereo (the default): six PSG channels play on the Amiga's
  four, each with the game's own waveform at its pitch, volume and
  balance. Noise (drums, explosions) and DDA samples (voices and drums
  in Soldier Blade and Parodius Da!) are played. Limits:
  * Amiga channels are hard left or right, so a centred PC Engine
    channel comes out of one side.
  * With five or six channels playing, the loudest three keep a voice
    each and the others are mixed in software onto the fourth, so no
    note goes missing.
  Full channel mix (Sound menu, or SOUNDMIX): all six channels mixed
  in software at 22 kHz and played in 14 bits, centred channels in
  the middle, as CD games always play. The level is set
  automatically, with a soft limiter on the loudest peaks. It costs
  some speed, so try Original stereo on a slow Amiga.
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
  * Art of Fighting: the zoom between the near and far views is jerky.


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
         2.0 on 12 November, 2.1 on 14 November, 2.2 on 16
         November, 2.3 on 18 November, 2.4 on 21 November, 2.5
         on 23 November and 2.5.1 on 26 November.

In short, the changes from v0.5: the HuC6280 timer, the right CPU
speed, many game fixes, a new sound engine, an RTG screen and a faster
CPU core. The list is in CHANGES.md.

Juan's earlier Aminet packages were misc/emu/pcengine_01.lha and
misc/emu/AmiPCEngine.lha; his v0.3, misc/emu/amipc-engine.lha,
replaced the latter in 2020 and stays on Aminet as it is.


9. Credits
----------
  AmiPC-Engine           Juan Antonio Gomez Galvez (GUS Entertainment)
  Versions 1.0 to 2.5.1  z00p
  Web and menu graphics  Multivac
  CD32 pad reading       Afrotechmods / FAmiga
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
Entertainment). Versions 1.0 to 2.5.1, by z00p, are community updates
made and published with his permission.

Please report a game that misbehaves with its name, whether you used
AGA or RTG, your machine (CPU, accelerator or
emulator, and the RTG board or mode) and what you saw:
  https://github.com/z00p/AmiPCEngine/issues