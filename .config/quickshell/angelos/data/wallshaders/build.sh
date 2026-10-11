#!/bin/sh
# TrollOS: the live wallpapers' shaders, src/<id>.frag → <id>.frag.qsb (services/ShaderWalls)
cd "$(dirname "$0")" || exit 1
QSB="${QSB:-/usr/lib/qt6/bin/qsb}"
for f in src/*.frag; do
    id="$(basename "$f" .frag)"
    "$QSB" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$id.frag.qsb" "$f" || exit 1
done
