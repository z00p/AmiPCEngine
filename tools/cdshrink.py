#!/usr/bin/env python3
"""cdshrink: a small, music-free copy of a PC Engine CD image, for AmiPCEngine.

    python cdshrink.py "Game.cue" [more .cue files or folders]

Writes "No music/Game.cue" and "No music/Game.bin" next to each cue. The source
files are only read, and an existing copy is never overwritten.

The copy keeps every data track whole and every track at its place on the disc:
an audio track becomes one silent sector, with a POSTGAP line for the rest of
its length. An audio track at the end of the disc keeps its full length in
silence, as a POSTGAP there would not count towards the length of the disc.

Input: CUE with BIN (2352-byte sectors) or ISO (2048), one file or several.
Python 3.6 or later, nothing else.
"""
import hashlib
import os
import sys

OUT_DIR = "No music"
RAW = 2352
CHUNK = 512                     # sectors at a time
CUE_MAX = 16384 - 1             # the largest cue AmiPCEngine reads
DATA_MODES = {"MODE1/2352": 2352, "MODE2/2352": 2352, "MODE1/2048": 2048}


class CueError(Exception):
    pass


class Track:
    def __init__(self, mode, image):
        self.mode = mode
        self.image = image      # index into the cue's files
        self.size = DATA_MODES.get(mode, RAW)
        self.index0 = self.index1 = None
        self.pregap = self.postgap = 0
        self.start = self.count = self.offset = 0

    @property
    def audio(self):
        return self.mode == "AUDIO"


def to_sectors(text):
    try:
        m, s, f = (int(x) for x in text.split(":"))
    except ValueError:
        raise CueError("bad time in the cue: %r" % text)
    return (m * 60 + s) * 75 + f


def to_msf(n):
    return "%02d:%02d:%02d" % (n // 4500, n // 75 % 60, n % 75)


def find_file(folder, name):
    path = os.path.join(folder, name)
    if os.path.isfile(path):
        return path
    parent, base = os.path.split(path)      # Amiga and Windows names ignore case
    if os.path.isdir(parent):
        for entry in os.listdir(parent):
            if entry.lower() == base.lower():
                return os.path.join(parent, entry)
    raise CueError("the cue names a file that is not there: %s" % name)


def read_cue(cue):
    with open(cue, "rb") as f:
        raw = f.read()
    if raw.startswith(b"\xef\xbb\xbf"):
        raw = raw[3:]
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        text = raw.decode("latin-1")

    folder = os.path.dirname(os.path.abspath(cue))
    files, tracks = [], []
    for line in text.splitlines():
        words = line.split()
        if not words:
            continue
        key = words[0].upper()
        try:
            if key == "FILE":
                rest = line.strip()[4:].strip()
                if rest.startswith('"'):
                    name, _, kind = rest[1:].partition('"')
                else:
                    name, _, kind = rest.partition(" ")
                if kind.strip().upper() not in ("", "BINARY"):
                    raise CueError("%s files are not supported, only BIN and ISO" % kind.strip())
                files.append(find_file(folder, name))
            elif key == "TRACK":
                mode = words[2].upper()
                if not files:
                    raise CueError("a TRACK before any FILE")
                if mode != "AUDIO" and mode not in DATA_MODES:
                    raise CueError("track type %s is not supported" % mode)
                tracks.append(Track(mode, len(files) - 1))
            elif key == "INDEX":
                number = int(words[1])
                if number == 0:
                    tracks[-1].index0 = to_sectors(words[2])
                elif number == 1:
                    tracks[-1].index1 = to_sectors(words[2])
            elif key == "PREGAP":
                tracks[-1].pregap = to_sectors(words[1])
            elif key == "POSTGAP":
                tracks[-1].postgap = to_sectors(words[1])
        except (IndexError, ValueError):
            raise CueError("bad line in the cue: %s" % line.strip())
    if not tracks:
        raise CueError("no tracks in the cue")
    return files, tracks


def lay_out(files, tracks):
    """Each track's disc position, length and place in its file. Returns the disc's length."""
    base = 0                    # disc position where the file starts
    for number, path in enumerate(files):
        group = [t for t in tracks if t.image == number]
        if not group:
            raise CueError("a FILE with no TRACK")
        bytes_in_file = os.path.getsize(path)
        gaps = 0
        before = None
        for i, t in enumerate(group):
            if t.index1 is None:
                raise CueError("a track with no INDEX 01")
            gaps += t.pregap
            t.start = base + gaps + t.index1
            if before is None:
                t.offset = t.index1 * t.size
            else:
                t.offset = before.offset + (t.index1 - before.index1) * before.size
            if i + 1 < len(group):
                after = group[i + 1]
                end = after.index1 if after.index0 is None else after.index0
                if end is None:
                    raise CueError("a track with no INDEX 01")
                t.count = end - t.index1
            else:
                t.count = (bytes_in_file - t.offset) // t.size
            if t.count <= 0 or t.offset + t.count * t.size > bytes_in_file:
                raise CueError("the cue does not fit %s (cut short?)" % os.path.basename(path))
            gaps += t.postgap
            before = t
        base = before.start + before.count + before.postgap
    return tracks[-1].start + tracks[-1].count


def data_md5(files, t):
    md5 = hashlib.md5()
    with open(files[t.image], "rb") as f:
        f.seek(t.offset)
        left = t.count
        while left:
            n = min(left, CHUNK)
            md5.update(f.read(n * t.size))
            left -= n
    return md5.hexdigest()


def write_small(files, tracks, out, bin_name):
    """The small BIN. Returns the cue's lines and the MD5 of each data track."""
    lines = ['FILE "%s" BINARY' % bin_name]
    sums = []
    pos = 0                     # sectors in the small file
    silence = bytes(RAW * CHUNK)
    for i, t in enumerate(tracks):
        following = tracks[i + 1] if i + 1 < len(tracks) else None
        keep = 1 if t.audio and following else t.count
        left = keep
        if t.audio:
            while left:
                n = min(left, CHUNK)
                out.write(silence[:n * RAW])
                left -= n
        else:
            md5 = hashlib.md5()
            with open(files[t.image], "rb") as source:
                source.seek(t.offset)
                while left:
                    n = min(left, CHUNK)
                    block = source.read(n * t.size)
                    if len(block) != n * t.size:
                        raise CueError("could not read all of %s" % files[t.image])
                    out.write(block)
                    md5.update(block)
                    left -= n
            sums.append(md5.hexdigest())
        lines.append("  TRACK %02d %s" % (i + 1, t.mode))
        if i == 0 and t.start:
            lines.append("    PREGAP %s" % to_msf(t.start))
        lines.append("    INDEX 01 %s" % to_msf(pos))
        if following:
            gap = following.start - t.start - keep
            if gap < 0:
                raise CueError("tracks %d and %d overlap" % (i + 1, i + 2))
            if gap:
                lines.append("    POSTGAP %s" % to_msf(gap))
        pos += keep
    return lines, sums


def shrink(cue):
    cue = os.path.abspath(cue)
    files, tracks = read_cue(cue)
    length = lay_out(files, tracks)
    if all(t.audio for t in tracks):
        raise CueError("no data track: not a game disc")

    folder = os.path.join(os.path.dirname(cue), OUT_DIR)
    stem = os.path.splitext(os.path.basename(cue))[0]   # the same name keeps the game's save file
    new_cue = os.path.join(folder, stem + ".cue")
    new_bin = os.path.join(folder, stem + ".bin")
    for path in (new_cue, new_bin):
        if os.path.exists(path):
            raise CueError("already there, left alone: %s" % path)

    os.makedirs(folder, exist_ok=True)
    made = []
    try:
        with open(new_bin, "xb") as out:
            made.append(new_bin)
            lines, sums = write_small(files, tracks, out, stem + ".bin")
        text = "\n".join(lines) + "\n"
        try:
            encoded = text.encode("latin-1")    # the Amiga's character set
        except UnicodeEncodeError:
            raise CueError("rename the cue using Latin characters only")
        if len(encoded) > CUE_MAX:
            raise CueError("the cue would be too long for AmiPCEngine")
        with open(new_cue, "xb") as out:
            made.append(new_cue)
            out.write(encoded)

        # read the copy back: same layout, same data
        small_files, small = read_cue(new_cue)
        same = lay_out(small_files, small) == length
        same = same and [(t.mode, t.start) for t in small] == [(t.mode, t.start) for t in tracks]
        same = same and [data_md5(small_files, t) for t in small if not t.audio] == sums
        if not same:
            raise CueError("the copy did not check out, so it was not kept")
    except BaseException:
        for path in made:       # only what this run wrote
            os.remove(path)
        raise
    return new_cue, sum(os.path.getsize(p) for p in set(files)), os.path.getsize(new_bin)


def cues_in(arguments):
    for arg in arguments:
        if not os.path.isdir(arg):
            yield arg
            continue
        for folder, subfolders, names in os.walk(arg):
            subfolders[:] = sorted(d for d in subfolders if d != OUT_DIR)
            for name in sorted(names):
                if name.lower().endswith(".cue"):
                    yield os.path.join(folder, name)


def main(arguments):
    if not arguments or arguments[0] in ("-h", "--help", "/?"):
        print(__doc__.strip())
        return 2
    done = failed = 0
    for cue in cues_in(arguments):
        print(os.path.basename(cue))
        try:
            if not cue.lower().endswith(".cue"):
                raise CueError("give the .cue, not the .bin or .chd")
            new_cue, before, after = shrink(cue)
            print("  %.1f MB -> %.1f MB, checked: %s" % (before / 1e6, after / 1e6, new_cue))
            done += 1
        except (CueError, OSError) as error:
            print("  not converted: %s" % error)
            failed += 1
    if not done and not failed:
        print("No .cue files found.")
        return 1
    print("%d converted, %d not converted." % (done, failed))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
