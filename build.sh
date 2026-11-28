#!/bin/sh
# Assemble AmiPCEngine with vasm (Devpac-compatible mode). Output: build/AmiPCEngine
#   sh build.sh           test build: the window title says "test build", the date and the commit
#   sh build.sh release   release build: the title from the source (MainMenuWTitle, -DNO_BUILDINFO=1)
#   sh build.sh debug     release build with the debug rows (-DDbgRows=1), to build/AmiPCEngine_Debug
#   sh build.sh colour    the program that ships since 2.0 (-DAGC=1: AGA in the PC Engine's colours, RTG with the word RTG), to build/AmiPCEngine_Colour
#   sh build.sh colourdebug  the same with the debug rows, to build/AmiPCEngine_ColourDebug
# OUT=path overrides the output file. DEFS="-DNO_PSGTWIN=0 ..." adds assembler switches (A/B test builds).
# Every build gets a build number, the commit count, in the window title ("v2.3 build 455").
# NAME="Keep Sides" names a test build: the window title gets the name, "test build", the
# number, the date and the commit, in any mode but release (A/B builds you can tell apart).
cd "$(dirname "$0")" && mkdir -p build
num=$(git rev-list --count HEAD)
# test window title: name, build number, date and commit (src/buildinfo.i, not in git)
printf "	DC.B	'AmiPC-Engine Emulator  -  %stest build %s %s (%s)',0
" "${NAME:+$NAME  -  }" "$num" "$(date +%d.%m.%Y)" "$(git rev-parse --short HEAD)$(git diff --quiet HEAD -- src || echo +)" > src/buildinfo.i
case "$1" in
  release) defs="-DNO_BUILDINFO=1"; out=${OUT:-build/AmiPCEngine} ;;
  debug)   defs="-DNO_BUILDINFO=1 -DDbgRows=1"; out=${OUT:-build/AmiPCEngine_Debug} ;;
  colour)  defs="-DNO_BUILDINFO=1 -DAGC=1"; out=${OUT:-build/AmiPCEngine_Colour} ;;
  colourdebug) defs="-DNO_BUILDINFO=1 -DAGC=1 -DDbgRows=1"; out=${OUT:-build/AmiPCEngine_ColourDebug} ;;
  "")      defs=""; out=${OUT:-build/AmiPCEngine} ;;
  *)       echo "usage: sh build.sh [release|debug|colour|colourdebug]"; exit 1 ;;
esac
if [ -n "$NAME" ]; then
  [ "$1" = release ] && { echo "NAME is for test builds, not release"; exit 1; }
  defs=$(echo "$defs" | sed 's/-DNO_BUILDINFO=1//')
fi
defs="$defs -DBUILDNUM=$num $DEFS"
cd src && ../tools/vasmm68k_mot.exe -devpac -nocase -m68020 -Fhunkexe -nosym -maxerrors=0 \
  $defs -o "../$out" Build.asm > ../build/build.log 2>&1
rc=$?
cd ..
grep -E "^(error|fatal)" build/build.log | head -40
echo "vasm exit $rc ($out${1:+, $1}); $(grep -c '^warning' build/build.log) warnings (see build/build.log)"
exit $rc
