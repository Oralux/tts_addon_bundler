#!/bin/bash -e
# This file is under the GPL-v3 license
# 2022, Gilles Casse <gcasse@oralux.org>
#

BASE=$(dirname $(readlink -f $0))

ADDON_VERSION=0.1.0
LE_VERSION=10.0
KODI_VERSION=v19
NEWS="- Initial release: compatibility LibreELEC $LE_VERSION"

cd "$BASE"
. ./espeak-ng/tts.inc

usage () {
    printf "
Usage: tts_addon_bundler.sh [options]

This script builds text-to-speech addons for LibreELEC $LE_VERSION (x86_64 or ARM).

Text-to-speech supported:
$ESPEAK_NG_USAGE

EXAMPLES
- build the eSpeak NG addon for x86_64 (default)
  ./tts_addon_bundler.sh

- for Raspberry PI
  ./tts_addon_bundler.sh --arch=armv7l

OPTIONS
     -a, --arch       set the target architecture (x86_64, armv7l or aarch64)
     -b, --build      build addon (default option)
     -c, --clean      clean the build and download directories
     -h, --help       display this help
     -s, --source     download source packages
"
}

[ "$UID" = 0 ] && { echo "run this script as non root user"; exit 1; }

cd "$BASE"

TEMP=`getopt -o a:bchs --long arch:,build,clean,help,source -- "$@"`
eval set -- "$TEMP"

ARCH=x86_64
BUILD=0
TTS=espeak-ng
unset CLEAN
unset SOURCE
while true ; do   
    case "$1" in
	-a|--arch) ARCH="$2"; shift 2;;
	-b|--build) BUILD=1; shift;;
	-c|--clean) CLEAN=1; shift;;
	-s|--source) SOURCE=1; shift;;
	--) shift ; break;;
	*) usage; exit 1;;
    esac
done

case "$ARCH" in
    x86_64) ARCH_DEBIAN=amd64;;
    armv7l) ARCH_DEBIAN=armhf;;
    aarch64) ARCH_DEBIAN=arm64;;
    *) usage; exit 1;;
esac

if [ -n "$CLEAN" ]; then
    rm -rf build download
    [ "$BUILD" = 0 ] && exit 0
fi

BUILD_DIR="$BASE"/build/"$TTS"/"$ARCH"
DOWNLOAD_DIR="$BASE"/download/"$TTS"/"$ARCH"
mkdir -p "$DOWNLOAD_DIR"
SOURCE_DIR="$BASE"/download/"$TTS"/src
mkdir -p "$SOURCE_DIR"

TARGET=script.module.$TTS
TARGET_DIR="$BUILD_DIR"/"$TARGET"

cd "$BASE"
rm -rf build/"$TTS"/"$ARCH"
mkdir -p "$TARGET_DIR"/resources

DATE=$(date +%Y-%m-%d)

tts_init=espeak_init
tts_get_source=espeak_get_source
tts_build_addon=espeak_build_addon

$tts_init

sed -e "s/%ARCH%/$ARCH/g" \
    -e "s/%ADDON_VERSION%/$ADDON_VERSION/g" \
    -e "s/%DATE%/$DATE/g" \
    -e "s/%DESCRIPTION%/$DESCRIPTION/g" \
    -e "s/%LE_VERSION%/$LE_VERSION/g" \
    -e "s/%LICENSE%/$LICENSE/g" \
    -e "s/%NAME%/$NAME/g" \
    -e "s/%NEWS%/$NEWS/g" \
    -e "s/%TTS%/$TTS/g" \
    common/addon.xml.skel \
    > "$TARGET_DIR"/addon.xml
cp common/default.py "$TARGET_DIR"
cp common/icon.png "$TARGET_DIR"/resources 
cp "$TTS"/LICENSE.txt "$TARGET_DIR"

if [ -n "$SOURCE" ]; then
    $tts_get_source
    [ "$BUILD" = 0 ] && exit 0
fi

$tts_build_addon "$BASE"/"$TTS"/SHA512SUM

cd "$BUILD_DIR"
ZIPNAME="$TARGET"_"$ADDON_VERSION"_"$ARCH"
ZIPFILE="$ZIPNAME".zip
#ZIPFILE="$BUILD_DIR"/"$ZIPNAME".zip
zip -qr "$ZIPFILE" "$TARGET"
sha512sum "$ZIPFILE" > "$ZIPNAME".sha512
echo "Addon available: $BUILD_DIR/$ZIPFILE"

