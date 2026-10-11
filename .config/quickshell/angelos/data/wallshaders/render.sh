#!/bin/sh
# TrollOS: render.sh ID OUT.png [W H T] — a frame of the live wallpaper ID as a picture
cd "$(dirname "$0")" || exit 1
SHADER_DIR="$PWD" SHADER="$1" OUT="$2" W="${3:-3840}" H="${4:-2160}" T="${5:-0}" timeout 40 qs -p "$PWD/render.qml" >/dev/null 2>&1
[ -s "$2" ]
