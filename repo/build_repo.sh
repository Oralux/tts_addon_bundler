#!/bin/bash -e

BASE=$(dirname $(readlink -f $0))
cd "$BASE"/..

./tts_addon_bundler.sh -c

REPO_DIR=build/repo
mkdir -p "$REPO_DIR"

#tts_addon_bundler.sh -s
for i in x86_64 armv7l aarch64; do
    ./tts_addon_bundler.sh -a $i
done

cp $(find build -type f -name "script.module.*") "$REPO_DIR"

echo "repo available: $REPO_DIR"


