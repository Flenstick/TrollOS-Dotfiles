#!/bin/sh
# Собирает Equicord с плагином AngelosFriends (для плагинов TrollOS «friend-runner» и «panel-shooter»)
# и подключает его к Discord вместо обычной сборки Equicord.
#
#   sh extras/equicord/install.sh            — собрать и подключить
#   sh extras/equicord/install.sh --revert   — вернуть официальный Equicord
#
# Нужны: git, pnpm (или corepack), уже установленный Equicord (Equibop/Equilotl).
# Официальная сборка сохраняется в ~/.config/Equicord/equicord.asar.official.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="${EQUICORD_SRC:-$HOME/.local/share/trollos/equicord}"
EQ="$HOME/.config/Equicord/equicord.asar"

if [ "$1" = "--revert" ]; then
    [ -f "$EQ.official" ] && rm -f "$EQ" && mv "$EQ.official" "$EQ"
    echo "Вернул официальный Equicord. Перезапусти Discord."
    exit 0
fi

[ -d "$SRC/.git" ] || git clone --depth 1 https://github.com/Equicord/Equicord.git "$SRC"
mkdir -p "$SRC/src/userplugins"
rm -rf "$SRC/src/userplugins/angelosFriends"
cp -r "$HERE/angelosFriends" "$SRC/src/userplugins/"
cd "$SRC"
pnpm install --frozen-lockfile
pnpm build
[ -L "$EQ" ] || { [ -f "$EQ" ] && mv "$EQ" "$EQ.official"; }
ln -sfn "$SRC/dist/desktop.asar" "$EQ"
echo "Готово! Перезапусти Discord и включи плагин AngelosFriends в настройках Equicord."
