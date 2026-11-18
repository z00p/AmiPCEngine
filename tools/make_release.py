"""Stage the AmiPCEngine release drawer from a built binary.

Usage:
  python tools/make_release.py BINARY [OUTDIR] [--version 1.0] [--draft]
         [--debug BINARY_DEBUG] [--rtg-copy] [--colour BINARY_COLOUR]
         [--colour-debug BINARY_COLOUR_DEBUG]
  python tools/make_release.py --build [--build-debug] [--build-colour] [OUTDIR] [--version 1.0] ...

BINARY    the program, "AGA" in the drawer (2.0: the colour build, `sh build.sh
          colour`, build/AmiPCEngine_Colour); the RTG icon starts it with the
          ToolType RTG. A test build (`sh build.sh`, "test build" and the
          commit in the window title) or a build with test-switch file names in
          it is refused unless --draft. With --version, the binary's $VER string
          must carry the same version.
--build   run `sh build.sh colour` first and stage build/AmiPCEngine_Colour (no BINARY).
--build-debug  also run `sh build.sh colourdebug` and stage it as the Debug pair
          (as --debug). Debug builds are not in public releases.
OUTDIR    default release/drawer (not in git). Result:
            OUTDIR/AmiPCEngine/           the drawer
            OUTDIR/AmiPCEngine.info       its icon
            OUTDIR/AmiPCEngine.readme     the Aminet readme
--version replaces @VERSION@ in the readme texts.
--draft   allow the undecided-text markers (see MARKER) and an
          unset version. Without it the script stops at the first marker, so
          a draft text cannot get into the archive.
--debug   a second build made with -DDbgRows=1: adds "AGA Debug" and
          "RTG Debug" with their icons and the legend, Debug rows.txt (for
          builds on request; public releases have no Debug builds).
--colour  a further program "AGA Colour" (not used since 2.0, where the
          colour build is the BINARY). --colour-debug adds "AGA Colour Debug".
--build-colour  run `sh build.sh colour` (and `colourdebug` with --build-debug)
          and stage them as --colour / --colour-debug.
--rtg-copy  "RTG" becomes a second copy of the program with a
          tool icon and the ToolType RTG instead of a project icon whose
          default tool is AGA. Costs one more binary in the archive.

What goes in the drawer (2.0): the program "AGA", its icon, the RTG icon, ReadMe.txt,
CHANGES.txt, the Homebrew drawer (the program's Insert requester opens
PROGDIR:Homebrew) with a short note and PadTest.pce (2.3: our own pad test HuCard,
tools/padtest_hucard.py), and the Saves drawer for backup RAM, with a note too. NO ROMs:
the script fails if anything that looks like a HuCard or disc image is staged, apart
from PadTest.pce byte for byte as the script builds it.

The LhA step is not here: it runs in WinUAE (winuae/make_lha.ps1).

The icons: the AGA tool icon is release/icons/AmiPCEngine.info (the PC Engine
picture). The RTG icon is that file with a ToolType added (and, for a project
icon, a default tool). The drawer icons are drawn here.
"""
import os, re, shutil, struct, sys, textwrap

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONS = os.path.join(BASE, "release", "icons")
ROM_EXT = {".pce", ".sgx", ".hes", ".bin", ".iso", ".cue", ".rom", ".img", ".zip", ".lha", ".lzx"}
# Names in the drawer (2.0): short, the drawer says AmiPCEngine. FFS allows
# 30 characters with ".info", so no "AmiPCEngine " prefix on the Debug names.
FAST, FAST_DBG = "AGA", "AGA Debug"
COLOUR, COLOUR_DBG = "AGA Colour", "AGA Colour Debug"
RTG, RTG_DBG = "RTG", "RTG Debug"
PROGRAMS = {FAST, FAST_DBG, COLOUR, COLOUR_DBG, RTG, RTG_DBG}
MARKER = re.compile(r"\[(John to decide|check after|end of check|OPTION)")
HOMEBREW_NOTE = ("Put your HuCard files (.pce) here, or browse to them anywhere else.\n"
                 "AmiPCEngine's Insert requester opens this drawer.\n")
SAVES_NOTE = ("AmiPCEngine keeps each game's backup RAM here, one .bup file per game.\n"
              "Delete a game's file to start it afresh.\n")


# ---- text for the Amiga -----------------------------------------------------

def amiga_text(src, dst, version, draft, wrap=0):
    """LF line ends, Latin-1 (ASCII here), @VERSION@ filled in. Fails on a
    marker unless draft, and on a line over 79 columns after wrapping."""
    t = open(src, "rb").read().decode("utf-8")
    for a, b in {"\u2018": "'", "\u2019": "'", "\u201c": '"', "\u201d": '"',
                 "\u2013": "-", "\u2014": "-", "\u2026": "...", "\u2192": "->"}.items():
        t = t.replace(a, b)
    t = t.replace("\r\n", "\n").replace("\r", "\n")
    if "@VERSION@" in t:
        if version:
            t = t.replace("@VERSION@", version)
        elif not draft:
            sys.exit("%s: @VERSION@ and no --version" % src)
    if not draft:
        m = MARKER.search(t)
        if m:
            line = t[:m.start()].count("\n") + 1
            sys.exit("%s:%d: undecided marker '%s' (use --draft to stage a draft)" % (src, line, m.group(0)))
    if wrap:   # Markdown: wrap long lines, keep the list indent
        out = []
        for line in t.split("\n"):
            ind = " " * len(re.match(r"\s*(?:[-*] |\d+\. )?", line).group(0))
            out += textwrap.wrap(line, wrap, subsequent_indent=ind, break_long_words=False,
                                 break_on_hyphens=False) or [""]
        t = "\n".join(out)
    bad = [c for c in t if ord(c) > 126 or (ord(c) < 32 and c != "\n")]
    if bad:
        sys.exit("%s: non-ASCII or control character %r" % (src, bad[0]))
    for n, line in enumerate(t.split("\n"), 1):
        if len(line) > 79:
            sys.exit("%s:%d: %d columns (Aminet: 80 at most)" % (src, n, len(line)))
    open(dst, "wb").write(t.encode("latin-1"))


# ---- icons ------------------------------------------------------------------

def lstr(s):
    s = s.encode("latin-1") + b"\0"
    return struct.pack(">I", len(s)) + s


def icon_parts(d):
    """Split a classic+colour tool icon into (head, image data, colour part).
    Only the shape our own icon has: no default tool, no tooltypes, no drawer
    data, a gadget image and no select image, then the FORM ICON chunk."""
    assert struct.unpack(">H", d[:2])[0] == 0xE310, "not an icon"
    typ = d[48]
    deftool, tt, drawer = struct.unpack(">III", d[50:54] + d[54:58] + d[66:70])
    assert (typ, deftool, tt, drawer) == (3, 0, 0, 0), "template is not a plain tool icon"
    assert struct.unpack(">I", d[26:30])[0] == 0, "template has a select image"
    w, h, depth = struct.unpack(">hhh", d[82:88])
    end = 78 + 20 + ((w + 15) // 16) * 2 * h * depth
    assert d[end:end + 4] == b"FORM", "colour icon not where expected"
    return d[:78], d[78:end], d[end:]


def tool_icon_with(d, tooltypes, default_tool=None):
    """The template with ToolTypes (and, if default_tool, as a project icon)."""
    head, image, colour = icon_parts(d)
    head = bytearray(head)
    mid = b""
    if default_tool:
        head[48] = 4                                  # WBPROJECT
        struct.pack_into(">I", head, 50, 1)           # default tool present
        mid += lstr(default_tool)
    struct.pack_into(">I", head, 54, 1)               # tooltypes present
    mid += struct.pack(">I", (len(tooltypes) + 1) * 4) + b"".join(lstr(t) for t in tooltypes)
    return bytes(head) + image + mid + colour


W = H = 46
PENS = [(170, 170, 170), (0, 0, 0), (255, 255, 255), (102, 136, 187)]   # Workbench 1.x/2.x pens


def draw_drawer():
    """An Amiga-style drawer in the shape of the Workbench 3.x ones: a lid that
    slopes out to the front panel, both dithered blue, a white handle, a dark
    outline and a drop shadow (same drawing as AmiMSX's)."""
    from PIL import Image, ImageDraw
    im = Image.new("RGB", (W, H), (255, 0, 255))
    d = ImageDraw.Draw(im)
    out, base, lite, dark, shade = (24, 32, 56), (66, 106, 172), (104, 144, 206), (40, 66, 124), (60, 60, 70)
    top, mid, bot = 11, 25, 39

    def lid_x(y):
        t = (y - top) / (mid - top)
        return round(10 - 4 * t), round(36 + 4 * t)
    for y in range(top, mid):
        a, b = lid_x(y)
        for x in range(a, b + 1):
            d.point((x, y), fill=lite if (x + y) % 2 == 0 and y < mid - 3 else base)
        d.point((a, y), fill=out); d.point((b, y), fill=out)
        d.point((b + 1, y + 1), fill=shade)
    d.line([12, top, 34, top], fill=out)
    d.point((11, top + 1), fill=out); d.point((35, top + 1), fill=out)
    d.line([7, mid - 1, 39, mid - 1], fill=(150, 180, 226))
    d.rectangle([6, mid, 40, bot], fill=base, outline=out)
    for y in range(mid + 1, mid + 5):
        for x in range(7, 40):
            if (x + y) % 2 == 0:
                d.point((x, y), fill=lite)
    d.line([39, mid + 1, 39, bot - 1], fill=dark)
    d.line([7, bot - 1, 39, bot - 1], fill=dark)
    d.line([41, mid + 1, 41, bot + 1], fill=shade); d.line([7, bot + 1, 41, bot + 1], fill=shade)
    d.rounded_rectangle([15, bot - 7, 31, bot - 3], radius=2, fill=(240, 240, 240), outline=out)
    d.line([17, bot - 4, 29, bot - 4], fill=(150, 150, 160))
    return im


def draw_page():
    """A sheet of paper with a folded corner, grey text lines, a dark outline and a
    drop shadow, for ReadMe.txt and CHANGES.txt (the same size as the drawers)."""
    from PIL import Image, ImageDraw
    im = Image.new("RGB", (W, H), (255, 0, 255))
    d = ImageDraw.Draw(im)
    out, paper, fold, line, shade = (24, 32, 56), (250, 250, 250), (200, 206, 218), (150, 150, 160), (60, 60, 70)
    l, t, r, b, c = 11, 5, 34, 40, 7                 # sheet edges, folded corner size
    d.polygon([(l, t), (r - c, t), (r, t + c), (r, b), (l, b)], fill=paper, outline=out)
    d.polygon([(r - c, t), (r - c, t + c), (r, t + c)], fill=fold, outline=out)
    for y in range(t + 10, b - 3, 4):
        d.line([l + 4, y, r - 4 - (7 if y % 12 == 3 else 0), y], fill=line)
    d.line([r + 1, t + c + 1, r + 1, b + 1], fill=shade); d.line([l + 1, b + 1, r + 1, b + 1], fill=shade)
    return im


def planar(im):
    """2-bitplane Image for the classic icon (nearest Workbench pen)."""
    rows = (W + 15) // 16 * 2
    planes = [bytearray(rows * H) for _ in range(2)]
    px = im.load()
    for y in range(H):
        for x in range(W):
            c = px[x, y]
            pen = 0 if c == (255, 0, 255) else min(range(4), key=lambda k: sum((a - b) ** 2 for a, b in zip(c, PENS[k])))
            for p in range(2):
                if pen >> p & 1:
                    planes[p][y * rows + x // 8] |= 0x80 >> (x & 7)
    return struct.pack(">hhhhhIBBI", 0, 0, W, H, 2, 1, 3, 0, 0) + bytes(planes[0]) + bytes(planes[1])


def glow(im):
    """ColorIcon FORM ICON (FACE + one uncompressed IMAG), magenta transparent."""
    from PIL import Image
    q = im.convert("P", palette=Image.ADAPTIVE, colors=63)
    pal = q.getpalette()[:63 * 3]
    src, qp = im.load(), q.load()
    pixels = bytearray()
    for y in range(H):
        for x in range(W):
            pixels.append(0 if src[x, y] == (255, 0, 255) else qp[x, y] + 1)
    palette = bytes([0, 0, 0]) + bytes(pal)
    ncol = len(palette) // 3

    def chunk(tag, data):
        return tag + struct.pack(">I", len(data)) + data + (b"\0" if len(data) & 1 else b"")
    face = struct.pack(">BBBBH", W - 1, H - 1, 1, 0x11, len(palette) - 1)
    imag = struct.pack(">BBBBBBHH", 0, ncol - 1, 3, 0, 0, 8, len(pixels) - 1, len(palette) - 1)
    form = b"ICON" + chunk(b"FACE", face) + chunk(b"IMAG", imag + bytes(pixels) + palette)
    return b"FORM" + struct.pack(">I", len(form)) + form


def project_icon(im, default_tool, x, y):
    gadget = struct.pack(">IhhhhHHHIIIIIHI", 0, 0, 0, W, H + 1, 4, 3, 1, 1, 0, 0, 0, 0, 0, 1)
    head = struct.pack(">HH", 0xE310, 1) + gadget + struct.pack(
        ">BBIIiiIII", 4, 0, 1, 0, x, y, 0, 0, 4096)   # WBPROJECT, a default tool, no tooltypes
    assert len(head) == 78, len(head)
    return head + planar(im) + lstr(default_tool) + glow(im)


def at(icon, x, y):
    """The icon snapshotted at (x, y) in its drawer window."""
    icon = bytearray(icon)
    struct.pack_into(">ii", icon, 58, x, y)
    return bytes(icon)


# The main drawer's snapshotted layout (window-relative, icon top left): two columns, the
# programs, then the drawers, then the text files; the window opens just big enough.
COL = (60, 190)                                       # column centres
ROW = (6, 100, 172)                                   # tops: programs (70 high), drawers, texts
WIN = (300, 290)


def col(c, w):
    return COL[c] - w // 2


def drawer_icon(im, w=420, h=200):
    gadget = struct.pack(">IhhhhHHHIIIIIHI", 0, 0, 0, W, H + 1, 4, 3, 1, 1, 0, 0, 0, 0, 0, 1)
    head = struct.pack(">HH", 0xE310, 1) + gadget + struct.pack(
        ">BBIIiiIII", 2, 0, 0, 0, -0x80000000, -0x80000000, 1, 0, 4096)   # WBDRAWER, DrawerData present
    assert len(head) == 78, len(head)
    nw = struct.pack(">hhhhBBIIIIIIIhhHHH", 60, 40, w, h, 255, 255, 0, 0, 0, 0, 0, 0, 0, 90, 40, 0xFFFF, 0xFFFF, 1)
    dd = nw + struct.pack(">ii", 0, 0)
    assert len(dd) == 56, len(dd)
    return head + dd + planar(im) + struct.pack(">IH", 0, 0) + glow(im)


# ---- staging ----------------------------------------------------------------

TEST_STRINGS = [b"test build", b"AmiPCE.result", b"AmiPCE.dda", b"AmiPCE.prof", b"rtgshot",
                b"pcestate.bin", b"scrdump.bin", b"rtgstat.txt", b"Debug_Init"]


def check_binary(path, version=None, draft=False):
    d = open(path, "rb").read()
    if struct.unpack(">I", d[:4])[0] != 0x3F3:
        sys.exit("%s is not an Amiga executable (no HUNK_HEADER)" % path)
    if not 400000 < len(d) < 3000000:
        sys.exit("%s: odd size %d" % (path, len(d)))
    if not draft:
        for t in TEST_STRINGS:
            if t in d:
                sys.exit("%s: has '%s' in it: not a release build (sh build.sh release), or use --draft"
                         % (path, t.decode()))
        if version and (b"$VER:AmiPC-Engine Emulator v%s " % version.encode()) not in d:
            sys.exit("%s: its $VER string is not v%s" % (path, version))
    return len(d)


def build(mode):
    import subprocess
    r = subprocess.run(["sh", "build.sh", mode], cwd=BASE)
    if r.returncode:
        sys.exit("sh build.sh %s failed" % mode)
    return os.path.join(BASE, "build", {"release": "AmiPCEngine", "debug": "AmiPCEngine_Debug",
                                        "colour": "AmiPCEngine_Colour",
                                        "colourdebug": "AmiPCEngine_ColourDebug"}[mode])


def padtest_rom():
    """PadTest.pce as tools/padtest_hucard.py builds it now (our own HuCard, no game data)."""
    import subprocess, tempfile
    with tempfile.TemporaryDirectory() as t:
        p = os.path.join(t, "PadTest.pce")
        subprocess.run([sys.executable, "-I", os.path.join(BASE, "tools", "padtest_hucard.py"), p],
                       check=True, capture_output=True)
        return open(p, "rb").read()


def check_no_roms(out):
    """No HuCard, disc image or archive may be staged; nothing big except the programs. The one
    exception: Homebrew/PadTest.pce, and only byte for byte as the script builds it."""
    pad = padtest_rom()
    for root, _, files in os.walk(out):
        for f in files:
            p = os.path.join(root, f)
            ext = os.path.splitext(f)[1].lower()
            if f == "PadTest.pce" and os.path.basename(root) == "Homebrew" and open(p, "rb").read() == pad:
                continue
            if ext in ROM_EXT:
                sys.exit("ROM-like file staged: %s" % p)
            if f not in PROGRAMS and os.path.getsize(p) > 100000:
                sys.exit("unexpected large file staged: %s (%d bytes)" % (p, os.path.getsize(p)))


def stage(binary, out, version, draft, debug=None, rtg_copy=False, colour=None, colour_debug=None):
    for b in (binary, debug, colour, colour_debug):
        if b:
            check_binary(b, version, draft)
    if os.path.exists(out):
        shutil.rmtree(out)
    d = os.path.join(out, "AmiPCEngine")
    os.makedirs(os.path.join(d, "Homebrew"))
    tpl = open(os.path.join(ICONS, "AmiPCEngine.info"), "rb").read()

    def put(name, data):
        open(os.path.join(d, name), "wb").write(data)

    shutil.copy(binary, os.path.join(d, FAST))
    tw = struct.unpack(">h", tpl[82:84])[0]                            # the program icons' width
    put(FAST + ".info", at(tpl, col(0, tw), ROW[0]))                   # AGA: the template, snapshotted
    variants = [(RTG, FAST, binary)]
    if debug:
        shutil.copy(debug, os.path.join(d, FAST_DBG))
        put(FAST_DBG + ".info", tpl)
        variants.append((RTG_DBG, FAST_DBG, debug))
    for name, tool, prog in variants:
        if rtg_copy:                                                   # a second binary, a tool icon
            shutil.copy(prog, os.path.join(d, name))
            put(name + ".info", tool_icon_with(tpl, ["RTG"]))
        else:                                                          # a project icon for the program
            icon = tool_icon_with(tpl, ["RTG"], default_tool=tool)
            put(name + ".info", at(icon, col(1, tw), ROW[0]) if name == RTG else icon)
    for name, prog in ((COLOUR, colour), (COLOUR_DBG, colour_debug)):
        if prog:                                                       # the AGA colour program
            shutil.copy(prog, os.path.join(d, name))
            put(name + ".info", tpl)
    amiga_text(os.path.join(BASE, "docs", "package", "ReadMe.txt"), os.path.join(d, "ReadMe.txt"), version, draft)
    if debug or colour_debug:                                          # the legend only with Debug builds
        amiga_text(os.path.join(BASE, "docs", "package", "Debug rows.txt"), os.path.join(d, "Debug rows.txt"), version, draft)
    amiga_text(os.path.join(BASE, "CHANGES.md"), os.path.join(d, "CHANGES.txt"), version, draft, wrap=76)
    amiga_text(os.path.join(BASE, "release", "AmiPCEngine.readme"), os.path.join(out, "AmiPCEngine.readme"), version, draft)
    open(os.path.join(d, "Homebrew", "Put HuCards here.txt"), "wb").write(HOMEBREW_NOTE.encode("ascii"))
    open(os.path.join(d, "Homebrew", "PadTest.pce"), "wb").write(padtest_rom())   # the pad test (ReadMe)
    im = draw_drawer()
    di = drawer_icon(im)
    put("Homebrew.info", at(di, col(1, W), ROW[1]))                    # the ROM drawer's icon
    os.makedirs(os.path.join(d, "Saves"))                              # backup RAM (the program makes it too)
    open(os.path.join(d, "Saves", "Saves go here.txt"), "wb").write(SAVES_NOTE.encode("ascii"))
    put("Saves.info", at(di, col(0, W), ROW[1]))
    page = draw_page()
    put("ReadMe.txt.info", project_icon(page, "SYS:Utilities/MultiView", col(0, W), ROW[2]))
    put("CHANGES.txt.info", project_icon(page, "SYS:Utilities/MultiView", col(1, W), ROW[2]))
    open(os.path.join(out, "AmiPCEngine.info"), "wb").write(drawer_icon(im, *WIN))   # the drawer's own icon
    check_no_roms(out)
    n = 0
    for root, _, files in os.walk(out):
        for f in sorted(files):
            p = os.path.join(root, f)
            print("%9d  %s" % (os.path.getsize(p), os.path.relpath(p, out).replace(os.sep, "/")))
            n += 1
    print("%d files in %s" % (n, out))


def main():
    a = sys.argv[1:]
    opts = {"--version": None, "--debug": None, "--colour": None, "--colour-debug": None}
    flags = {"--draft": False, "--rtg-copy": False, "--build": False, "--build-debug": False,
             "--build-colour": False}
    pos = []
    i = 0
    while i < len(a):
        if a[i] in opts:
            opts[a[i]] = a[i + 1]
            i += 2
        elif a[i] in flags:
            flags[a[i]] = True
            i += 1
        else:
            pos.append(a[i])
            i += 1
    if flags["--build"] or flags["--build-debug"]:
        pos.insert(0, build("colour"))                 # 2.0: the AGA program is the colour build
        if flags["--build-debug"]:
            opts["--debug"] = build("colourdebug")
    if flags["--build-colour"]:
        opts["--colour"] = build("colour")
        if flags["--build-debug"]:
            opts["--colour-debug"] = build("colourdebug")
    if not pos or len(pos) > 2:
        sys.exit(__doc__)
    out = pos[1] if len(pos) > 1 else os.path.join(BASE, "release", "drawer")
    stage(pos[0], out, opts["--version"], flags["--draft"], opts["--debug"], flags["--rtg-copy"],
          opts["--colour"], opts["--colour-debug"])


if __name__ == "__main__":
    main()