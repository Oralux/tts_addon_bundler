
ESPEAK_NG_NAME="eSpeak NG"
ESPEAK_NG_DESCRIPTION="eSpeak NG bundle for LibreELEC"
ESPEAK_NG_URL=http://ftp.debian.org/debian/pool/main
ESPEAK_NG_LIST="\
e/espeak-ng/espeak-ng_1.50+dfsg-7+deb11u1 \
e/espeak-ng/espeak-ng-data_1.50+dfsg-7+deb11u1 \
e/espeak-ng/libespeak-ng1_1.50+dfsg-7+deb11u1 \
p/pcaudiolib/libpcaudio0_1.1-6 \
s/sonic/libsonic0_0.2.0-10 \
"

ESPEAK_NG_SOURCE="\
e/espeak-ng/espeak-ng_1.50+dfsg-7+deb11u1 \
p/pcaudiolib/pcaudiolib_1.1-6 \
s/sonic/sonic_0.2.0-10 \
"

ESPEAK_NG_LICENSE="Apache-2.0, BSD-2-Clause, GPL-3.0-only, IEEE, UCD"

printf -v ESPEAK_NG_USAGE '
- eSpeak NG (the binaries will be downloaded from Debian repositories)
  Pre-requisite: script launched from a Debian based distro (with
  wget, dpkg and devscripts packages installed)
'

espeak_init() {
    local p

    which wget || p="wget"
    which dget || p="$p devscripts"
    which dpkg || p="$p dpkg"

    [ -n "$p" ] && { echo "Dependencies missing. Install please the following Debian packages: $p"; exit 1; }

    NAME="$ESPEAK_NG_NAME"
    DESCRIPTION="$ESPEAK_NG_DESCRIPTION"
    LICENSE="$ESPEAK_NG_LICENSE"
}

espeak_get_source() {
    local i
    local dir="$PWD"

    cd "$SOURCE_DIR"
    set +e
    for i in $ESPEAK_NG_SOURCE; do
	dget -d $ESPEAK_NG_URL/$i.dsc
    done
    set -e
    echo "sources: $SOURCE_DIR"
    cd "$dir"
}

_espeak_download_packages() {
    local i

    for i in $ESPEAK_NG_LIST; do
	local url="$ESPEAK_NG_URL"/${i}_"$ARCH_DEBIAN".deb
	wget "$url"
    done
}

_espeak_extract_packages() {
    local i

    for i in $ESPEAK_NG_LIST; do
	local url="$ESPEAK_NG_URL"/${i}_"$ARCH_DEBIAN".deb
	dpkg -x "${url##*/}" "$TARGET_DIR"
    done
}

espeak_build_addon() {
    local sha512file="$1"
    local dir="$PWD"

    [ ! -d "$TARGET_DIR"/resources ] && exit 1
    [ ! -f "$sha512file" ] && exit 1

    cd "$DOWNLOAD_DIR"
    sha512sum -c --ignore-missing "$sha512file" || { _espeak_download_packages; sha512sum -c --ignore-missing "$sha512file"; }

    _espeak_extract_packages "$TARGET_DIR"

    cd "$TARGET_DIR"
    mv usr/bin .
    mkdir lib
    mv usr/lib/*/* lib/    
    mv usr/share/doc lib/
    rm -rf usr

    cd "$dir"
}
