#!/bin/sh
# Assemble AmiPCEngine with vasm (Devpac-compatible mode). Output: build/AmiPCEngine
#   sh build.sh           test build: the window title says "test build", the date and the commit
#   sh build.sh release   release build: the title from the source (MainMenuWTitle, -DNO_BUILDINFO=1)
#   sh build.sh debug     release build with the debug rows (-DDbgRows=1), to build/AmiPCEngine_Debug
# OUT=path overrides the output file.
cd "$(dirname "$0")" && mkdir -p build
# window title with the build date and commit (src/buildinfo.i, not in git)
printf "	DC.B	'AmiPC-Engine Emulator v1.0  -  test build %s (%s)',0
" "$(date +%d.%m.%Y)" "$(git rev-parse --short HEAD)$(git diff --quiet HEAD -- src || echo +)" > src/buildinfo.i
case "$1" in
  release) defs="-DNO_BUILDINFO=1"; out=${OUT:-build/AmiPCEngine} ;;
  debug)   defs="-DNO_BUILDINFO=1 -DDbgRows=1"; out=${OUT:-build/AmiPCEngine_Debug} ;;
  "")      defs=""; out=${OUT:-build/AmiPCEngine} ;;
  *)       echo "usage: sh build.sh [release|debug]"; exit 1 ;;
esac
cd src && ../tools/vasmm68k_mot.exe -devpac -nocase -m68020 -Fhunkexe -nosym -maxerrors=0 \
  $defs -o "../$out" Build.asm > ../build/build.log 2>&1
rc=$?
cd ..
grep -E "^(error|fatal)" build/build.log | head -40
echo "vasm exit $rc ($out${1:+, $1}); $(grep -c '^warning' build/build.log) warnings (see build/build.log)"
exit $rc
