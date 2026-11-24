"""Build a PC Engine pad test HuCard: one line for each PC Engine button with the CD32 pad and
joystick buttons that drive it (the ReadMe's Joy-Control table) and a box that turns green
while the game sees the button held. It reads the joypad port $1000 as a game does (SEL / CLR),
so it tests the whole path: the Amiga port read, the mapping, the emulated port. Runs until it
is left (Esc). Our own code and font, no third-party data.

Two kinds, as games come:
  two  (PadTest.pce)   reads the pad once a frame, as nearly every game does: a CD32 pad is a
                       two-button pad (green Select, yellow Run, shoulders Select / Run).
  six  (PadTest6.pce)  reads it twice a frame, as games for the six-button pad do: a CD32 pad
                       gives III-VI as well (green, yellow, the shoulders).

  python -I tools/padtest_hucard.py OUT.pce two|six
"""
import sys

FONT = {   # 5x7, top row first
    ' ': ['.....'] * 7,
    '-': ['.....', '.....', '.....', '#####', '.....', '.....', '.....'],
    ',': ['.....', '.....', '.....', '.....', '.##..', '..#..', '.#...'],
    ':': ['.....', '..#..', '..#..', '.....', '..#..', '..#..', '.....'],
    '/': ['....#', '...#.', '...#.', '..#..', '.#...', '.#...', '#....'],
    '0': ['.###.', '#...#', '#..##', '#.#.#', '##..#', '#...#', '.###.'],
    '1': ['..#..', '.##..', '..#..', '..#..', '..#..', '..#..', '.###.'],
    '2': ['.###.', '#...#', '....#', '...#.', '..#..', '.#...', '#####'],
    '3': ['####.', '....#', '....#', '.###.', '....#', '....#', '####.'],
    '6': ['.###.', '#....', '#....', '####.', '#...#', '#...#', '.###.'],
    'A': ['.###.', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
    'B': ['####.', '#...#', '#...#', '####.', '#...#', '#...#', '####.'],
    'C': ['.###.', '#...#', '#....', '#....', '#....', '#...#', '.###.'],
    'D': ['####.', '#...#', '#...#', '#...#', '#...#', '#...#', '####.'],
    'E': ['#####', '#....', '#....', '####.', '#....', '#....', '#####'],
    'F': ['#####', '#....', '#....', '####.', '#....', '#....', '#....'],
    'G': ['.###.', '#...#', '#....', '#.###', '#...#', '#...#', '.###.'],
    'H': ['#...#', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
    'I': ['.###.', '..#..', '..#..', '..#..', '..#..', '..#..', '.###.'],
    'J': ['..###', '...#.', '...#.', '...#.', '...#.', '#..#.', '.##..'],
    'K': ['#...#', '#..#.', '#.#..', '##...', '#.#..', '#..#.', '#...#'],
    'L': ['#....', '#....', '#....', '#....', '#....', '#....', '#####'],
    'M': ['#...#', '##.##', '#.#.#', '#.#.#', '#...#', '#...#', '#...#'],
    'N': ['#...#', '##..#', '#.#.#', '#..##', '#...#', '#...#', '#...#'],
    'O': ['.###.', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
    'P': ['####.', '#...#', '#...#', '####.', '#....', '#....', '#....'],
    'Q': ['.###.', '#...#', '#...#', '#...#', '#.#.#', '#..#.', '.##.#'],
    'R': ['####.', '#...#', '#...#', '####.', '#.#..', '#..#.', '#...#'],
    'S': ['.###.', '#...#', '#....', '.###.', '....#', '#...#', '.###.'],
    'T': ['#####', '..#..', '..#..', '..#..', '..#..', '..#..', '..#..'],
    'U': ['#...#', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
    'V': ['#...#', '#...#', '#...#', '#...#', '#...#', '.#.#.', '..#..'],
    'W': ['#...#', '#...#', '#...#', '#.#.#', '#.#.#', '##.##', '#...#'],
    'X': ['#...#', '#...#', '.#.#.', '..#..', '.#.#.', '#...#', '#...#'],
    'Y': ['#...#', '#...#', '.#.#.', '..#..', '..#..', '..#..', '..#..'],
    'Z': ['#####', '....#', '...#.', '..#..', '.#...', '#....', '#####'],
}

# ---- tiles: VRAM $1000 on = tile $100 on. 0 blank, 1 empty box, 2 full box, then the font.
# Colours (palette 0): 1 white (plane 0), 2 green (plane 1), 3 grey (planes 0 + 1).
TBASE = 0x100
BLANK, EMPTY, FULL = TBASE, TBASE + 1, TBASE + 2
chars = [c for c in sorted(FONT) if c != ' ']
TILE = {c: TBASE + 3 + i for i, c in enumerate(chars)}
TILE[' '] = BLANK


def tile(rows8, plane):
    """8 rows of '#'/'.' -> 32 bytes: words 0-7 planes 0/1, words 8-15 planes 2/3."""
    out = bytearray(32)
    for r, s in enumerate(rows8):
        b = int(s.replace('#', '1').replace('.', '0'), 2)
        for p in (0, 1):
            if plane & (1 << p):
                out[r * 2 + p] = b
    return out


tiles = bytearray(32)
tiles += tile(['#######.', '#.....#.', '#.....#.', '#.....#.', '#.....#.', '#.....#.', '#######.', '........'], 1)
full = bytearray(32)                            # white edge (plane 0), green inside (plane 1)
for r in range(7):
    full[r * 2] = 0xFE if r in (0, 6) else 0x82
    full[r * 2 + 1] = 0x7C if 0 < r < 6 else 0x00
tiles += full
for c in chars:
    tiles += tile(['.' + r + '..' for r in FONT[c]] + ['........'], 1)
tiles += bytes(-len(tiles) % 256)

# ---- the screen: a 32 x 32 BAT at VRAM $0000; 240 lines shown, keep to rows 3-25
bat = [BLANK] * 1024


def text(row, col, s):
    for i, ch in enumerate(s):
        bat[row * 32 + col + i] = TILE[ch]


KIND = sys.argv[2] if len(sys.argv) > 2 else 'six'
assert KIND in ('two', 'six'), KIND
SIX = KIND == 'six'
BOXCOL = 29
# (row, button, CD32 pad, joystick, register: 0 = SEL high (d-pad), 1 = SEL low (buttons),
# 2 = a six-button pad's second page (III-VI), bit)
LINES = [(7, 'UP', 'UP', 'UP', 0, 0), (8, 'DOWN', 'DOWN', 'DOWN', 0, 2),
         (9, 'LEFT', 'LEFT', 'LEFT', 0, 3), (10, 'RIGHT', 'RIGHT', 'RIGHT', 0, 1),
         (11, 'I', 'BLUE', 'FIRE 2', 1, 0), (12, 'II', 'RED', 'FIRE 1', 1, 1)]
if SIX:
    LINES += [(13, 'SELECT', 'DEL KEY', '-', 1, 2), (14, 'RUN', 'PLAY', 'FIRE 3', 1, 3),
              (15, 'III', 'GREEN', '-', 2, 0), (16, 'IV', 'YELLOW', '-', 2, 1),
              (17, 'V', 'L SHLD', '-', 2, 2), (18, 'VI', 'R SHLD', '-', 2, 3)]
else:
    LINES += [(13, 'SELECT', 'GREEN/L SHLD', '-', 1, 2), (14, 'RUN', 'YELLOW/R SHLD', 'FIRE 3', 1, 3)]
text(2, 9, 'PAD TEST ' + ('6-BUTTON' if SIX else '2-BUTTON'))
text(5, 1, 'BUTTON CD32          JOY')
for row, name, cd32, joy, reg, bit in LINES:
    text(row, 1, name)
    text(row, 8, cd32)
    text(row, 22, joy)
    bat[row * 32 + BOXCOL] = EMPTY
if SIX:
    text(20, 1, 'READS THE PAD AS A GAME FOR')
    text(21, 1, 'THE SIX-BUTTON PAD DOES')
else:
    text(16, 1, 'PLAY IS RUN TOO')
    text(20, 1, 'READS THE PAD AS NEARLY ALL')
    text(21, 1, 'GAMES DO: III-VI IN PADTEST6')
text(23, 1, 'HOLD A BUTTON: ITS BOX FILLS')
text(25, 1, 'ESC: BACK TO THE MENU')
batbytes = bytearray()
for w in bat:
    batbytes += bytes([w & 255, w >> 8])

# ---- HuC6280 code, bank 0 at $E000 (MPR7 = 0 at reset)
ORG = 0xE000
code = bytearray()
labels, fixes = {}, []   # fixes: (offset, label, kind) kind 'abs' | 'rel'


def L(name): labels[name] = ORG + len(code)
def op(*b): code.extend(b)
def absop(o, name): code.append(o); fixes.append((len(code), name, 'abs')); code.extend((0, 0))
def br(o, name): code.append(o); fixes.append((len(code), name, 'rel')); code.append(0)
def lda_i(v): op(0xA9, v)
def sta(a): op(0x8D, a & 255, a >> 8)
def stz(a): op(0x9C, a & 255, a >> 8)
def lda(a): op(0xAD, a & 255, a >> 8)


ZP_PTR, ZP_VBL, ZP_DIR, ZP_BTN = 0x00, 0x02, 0x03, 0x04   # zero page = $2000 (MPR1 = $F8)
ZP_EXT, ZP_DA, ZP_BA, ZP_DB, ZP_BB = 0x05, 0x06, 0x07, 0x08, 0x09
VDC_REG, VDC_LO, VDC_HI = 0x0000, 0x0002, 0x0003
VCE_CTL, VCE_ADL, VCE_ADH, VCE_DL, VCE_DH = 0x0400, 0x0402, 0x0403, 0x0404, 0x0405
JOY, TIMCTL, IRQMASK = 0x1000, 0x0C01, 0x1402


def vreg(r, v):
    lda_i(r); sta(VDC_REG); lda_i(v & 255); sta(VDC_LO); lda_i(v >> 8); sta(VDC_HI)


L('reset')
op(0x78, 0xD4, 0xD8)                    # sei, csh, cld
op(0xA2, 0xFF, 0x9A)                    # ldx #$FF, txs
lda_i(0xFF); op(0x53, 0x01)             # tam #0: I/O page at $0000
lda_i(0xF8); op(0x53, 0x02)             # tam #1: RAM at $2000
stz(TIMCTL)                             # timer off
lda_i(0x07); sta(IRQMASK)               # all interrupts off for now
for r, v in [(0x05, 0x0000), (0x06, 0), (0x07, 0), (0x08, 0), (0x09, 0x0000), (0x0A, 0x0202),
             (0x0B, 0x031F), (0x0C, 0x0F02), (0x0D, 0x00EF), (0x0E, 0x0004), (0x0F, 0), (0x13, 0x7F00)]:
    vreg(r, v)
stz(VCE_CTL); stz(VCE_ADL); stz(VCE_ADH)
PAL = [0x000, 0x1FF, 0x1C0, 0x0B6]      # GGGRRRBBB: black, white, green, grey
for c in PAL:
    lda_i(c & 255); sta(VCE_DL); lda_i(c >> 8); sta(VCE_DH)


def copy(dest, label, pages):
    vreg(0x00, dest)                    # MAWR
    lda_i(0x02); sta(VDC_REG)           # VWR
    code.append(0xA9); fixes.append((len(code), label, 'lo')); code.append(0)
    op(0x85, ZP_PTR)
    code.append(0xA9); fixes.append((len(code), label, 'hi')); code.append(0)
    op(0x85, ZP_PTR + 1)
    op(0xA2, pages)                     # ldx #pages
    L('cp%x' % dest); op(0xA0, 0x00)    # ldy #0
    L('cq%x' % dest)
    op(0xB1, ZP_PTR); sta(VDC_LO); op(0xC8)  # lda (ptr),y; sta lo; iny
    op(0xB1, ZP_PTR); sta(VDC_HI); op(0xC8)  # lda (ptr),y; sta hi; iny
    br(0xD0, 'cq%x' % dest)
    op(0xE6, ZP_PTR + 1, 0xCA)          # inc ptr+1; dex
    br(0xD0, 'cp%x' % dest)


copy(0x0000, 'bat', len(batbytes) // 256)
copy(0x1000, 'tiles', len(tiles) // 256)
vreg(0x05, 0x0088)                      # CR: background on, vblank interrupt
lda_i(0x05); sta(IRQMASK)               # IRQ1 (VDC) only
op(0x58)                                # cli

L('main')
op(0x64, ZP_VBL)                        # stz vbl
L('wait'); op(0xA5, ZP_VBL); br(0xF0, 'wait')


def read_pad(zdir, zbtn):
    lda_i(0x01); sta(JOY); lda_i(0x03); sta(JOY); lda_i(0x01); sta(JOY)   # SEL high, CLR pulse
    op(0xEA, 0xEA, 0xEA, 0xEA)
    lda(JOY); op(0x29, 0x0F, 0x49, 0x0F, 0x85, zdir)                    # d-pad, 1 = held
    lda_i(0x00); sta(JOY)                                                # SEL low
    op(0xEA, 0xEA, 0xEA, 0xEA)
    lda(JOY); op(0x29, 0x0F, 0x49, 0x0F, 0x85, zbtn)                    # I, II, Select, Run


# six: two reads a frame. A six-button pad turns its page at each CLR pulse: one of the two reads
# is its second page, which shows as all four directions low (0000, here $0F) with III-VI as the
# buttons. A two-button pad gives the same thing twice.
# two: one read a frame, as an ordinary game; nothing on the second page is looked for.
read_pad(ZP_DA, ZP_BA)
if not SIX:
    op(0xA5, ZP_DA, 0x85, ZP_DIR, 0xA5, ZP_BA, 0x85, ZP_BTN, 0x64, ZP_EXT)
    absop(0x4C, 'pd')
read_pad(ZP_DB, ZP_BB)
op(0xA5, ZP_DB, 0xC9, 0x0F); br(0xD0, 'pa')                         # B the second page?
op(0xA5, ZP_DA, 0x85, ZP_DIR, 0xA5, ZP_BA, 0x85, ZP_BTN, 0xA5, ZP_BB, 0x85, ZP_EXT)
br(0x80, 'pd')
L('pa'); op(0xA5, ZP_DA, 0xC9, 0x0F); br(0xD0, 'p2')                 # A the second page?
op(0xA5, ZP_DB, 0x85, ZP_DIR, 0xA5, ZP_BB, 0x85, ZP_BTN, 0xA5, ZP_BA, 0x85, ZP_EXT)
br(0x80, 'pd')
L('p2'); op(0xA5, ZP_DA, 0x85, ZP_DIR, 0xA5, ZP_BA, 0x85, ZP_BTN, 0x64, ZP_EXT)   # two buttons
L('pd')
for n, (row, name, cd32, joy, reg, bit) in enumerate(LINES):
    vreg(0x00, row * 32 + BOXCOL)
    lda_i(0x02); sta(VDC_REG)
    op(0xA5, (ZP_DIR, ZP_BTN, ZP_EXT)[reg], 0x29, 1 << bit)
    br(0xD0, 'f%d' % n); lda_i(EMPTY & 255); br(0x80, 'w%d' % n)
    L('f%d' % n); lda_i(FULL & 255)
    L('w%d' % n); sta(VDC_LO); lda_i(EMPTY >> 8); sta(VDC_HI)
absop(0x4C, 'main')                     # jmp main

L('irq1')                               # VDC: read the status (acknowledges), flag the vblank
op(0x48); lda(VDC_REG); lda_i(1); op(0x85, ZP_VBL, 0x68, 0x40)   # pha ... pla, rti
L('rti'); op(0x40)

L('bat'); code += batbytes
L('tiles'); code += tiles

for at, name, kind in fixes:
    v = labels[name]
    if kind == 'abs':
        code[at], code[at + 1] = v & 255, v >> 8
    elif kind == 'lo':
        code[at] = v & 255
    elif kind == 'hi':
        code[at] = v >> 8
    else:
        d = v - (ORG + at + 1)
        assert -128 <= d < 128, name
        code[at] = d & 255

assert len(code) <= 0x2000 - 10, len(code)
rom = bytearray(b'\xFF' * 0x8000)       # 32 KB, bank 0 holds everything
rom[0:len(code)] = code
for at, name in [(0x1FF6, 'rti'), (0x1FF8, 'irq1'), (0x1FFA, 'rti'), (0x1FFC, 'rti'), (0x1FFE, 'reset')]:
    v = labels[name]
    rom[at], rom[at + 1] = v & 255, v >> 8
open(sys.argv[1], 'wb').write(rom)
print(f'{sys.argv[1]}: {len(code)} bytes in bank 0, {len(tiles) // 32} tiles')
