#!/usr/bin/env bash
# angelOS: update the dotfiles this system was installed from (Settings → Updates).
#
#   dotfiles-update.sh --find                 print the repository path, if any
#   dotfiles-update.sh --check REPO           fetch; print BRANCH/UPSTREAM/BEHIND/AHEAD/DIRTY/REMOTE and IN <commit> lines
#   dotfiles-update.sh --clone DEST [URL]     first-time download of the official repository
#   dotfiles-update.sh REPO                   git pull --ff-only, snapshot configs, run the installer non-interactively
#
# Nothing is updated without a click. The installer keeps replaced files as
# *.bak.<date>; the current keyboard layouts are passed through so they survive.
set -Eeuo pipefail
say() { printf '» %s\n' "$*"; }
# TrollOS: updates come from the TrollOS fork, not from upstream angelOS
OFFICIAL="https://github.com/Flenstick/TrollOS-Dotfiles"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/angelos"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"

is_repo() { [[ -d "$1/.git" && -f "$1/install.sh" ]]; }

# updates run the repository's installer, so only pull from where this system
# came from: the official repository or the remote recorded at install time
norm_url() { local u="${1%/}"; printf '%s' "${u%.git}"; }
trusted_remote() {
  local url rec=""
  url="$(git remote get-url origin 2>/dev/null || true)"
  [[ -f "$CONF/angelos/dotfiles-source" ]] && rec="$(sed -n 's/^remote=//p' "$CONF/angelos/dotfiles-source" | head -1)"
  [[ -n "$url" ]] || return 1
  [[ "$(norm_url "$url")" == "$(norm_url "$OFFICIAL")" ]] && return 0
  [[ -n "$rec" && "$(norm_url "$url")" == "$(norm_url "$rec")" ]]
}

find_repo() {
  local marker="$CONF/angelos/dotfiles-source" r
  if [[ -f "$marker" ]]; then
    r="$(sed -n 's/^repo=//p' "$marker" | head -1)"
    is_repo "$r" && { printf '%s\n' "$r"; return 0; }
  fi
  for r in "$HOME/TrollOS-Dotfiles" "$HOME/Projects/TrollOS-Dotfiles" "$HOME/PixelStreetArt_Dotfiles_Niri" "${XDG_DATA_HOME:-$HOME/.local/share}/angelos/dotfiles" \
           "$HOME/Projects/PixelStreetArt_Dotfiles_Niri" "$HOME/.dotfiles/PixelStreetArt_Dotfiles_Niri"; do
    is_repo "$r" && { printf '%s\n' "$r"; return 0; }
  done
  return 1
}

case "${1:-}" in
  --find)
    find_repo || exit 1
    exit 0 ;;
  --check)
    cd "${2:?repo}"
    is_repo . || { echo "ERR not a dotfiles repository"; exit 2; }
    git fetch --quiet 2>&1 || { echo "ERR fetch"; exit 1; }
    echo "BRANCH $(git rev-parse --abbrev-ref HEAD)"
    echo "UPSTREAM $(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo none)"
    echo "BEHIND $(git rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)"
    echo "AHEAD $(git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)"
    echo "DIRTY $(git status --porcelain | wc -l)"
    echo "REMOTE $(git remote get-url origin 2>/dev/null || echo none)"
    trusted_remote && echo "TRUSTED 1" || echo "TRUSTED 0"
    git log --format='IN %h %s' 'HEAD..@{u}' 2>/dev/null | head -40 || true
    exit 0 ;;
  --clone)
    DEST="${2:?destination}"
    URL="${3:-$OFFICIAL}"
    [[ "$URL" =~ ^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(\.git)?$ ]] || { say "адрес должен быть https://github.com/…"; exit 2; }
    [[ -e "$DEST" ]] && { say "папка уже существует: $DEST"; exit 2; }
    mkdir -p -- "$(dirname -- "$DEST")"
    say "git clone $URL"
    git clone --depth 50 -- "$URL" "$DEST" 2>&1
    mkdir -p -- "$CONF/angelos"
    printf 'repo=%s\nremote=%s\n' "$DEST" "$URL" >"$CONF/angelos/dotfiles-source"
    say "готово ♡"
    exit 0 ;;
esac

REPO="${1:?repo}"
cd "$REPO"
is_repo . || { say "это не репозиторий dotfiles: $REPO"; exit 2; }
if ! trusted_remote; then
  say "origin = $(git remote get-url origin 2>/dev/null || echo '?') — это не официальный репозиторий и не тот, из которого ставилась система; обновление отменено"
  exit 4
fi
if [[ -n "$(git status --porcelain)" ]]; then
  say "в репозитории есть свои изменения — обнови вручную (git stash; git pull) или откати их:"
  git status --short | head -20
  exit 3
fi

say "git pull ($(git rev-parse --abbrev-ref HEAD))"
git pull --ff-only 2>&1

# snapshot the configs into a fresh folder before the installer touches them
B="$STATE/backups/$(date +%Y%m%d-%H%M%S)-update"
mkdir -p "$B"
for d in .config/niri .config/quickshell/angelos .config/angelos .config/kitty .config/foot .config/alacritty \
         .config/gtk-3.0 .config/gtk-4.0 .config/fish .local/bin; do
  if [[ -e "$HOME/$d" ]]; then
    mkdir -p "$B/$(dirname "$d")"
    cp -rn "$HOME/$d" "$B/$d"
  fi
done
say "снимок конфигов: $B"

# keep the keyboard as it is now
input="$CONF/niri/cfg/input.kdl"
kb_env=()
if [[ -f "$input" ]]; then
  layouts="$(sed -n 's/^[[:space:]]*layout[[:space:]]*"\([^"]*\)".*/\1/p' "$input" | head -1)"
  options="$(sed -n 's/^[[:space:]]*options[[:space:]]*"\([^"]*\)".*/\1/p' "$input" | head -1)"
  [[ "$layouts" =~ ^[a-z,]+$ ]] && kb_env+=("KB_LAYOUTS=$layouts")
  [[ -n "$options" && "$options" =~ ^[a-z0-9_:,]+$ ]] && kb_env+=("KB_TOGGLE=$options")
fi

say "запускаю установщик (без пакетов, SDDM и служб)"
env DOTFILES_MODE=full DESKTOP_SHELL=angelos SKIP_PACKAGES=1 INSTALL_SDDM=0 INSTALL_VOXTYPE=0 \
    DOWNLOAD_VOXTYPE_MODEL=0 INSTALL_WALLPAPERS=0 INSTALL_FLATPAK=0 ENABLE_SERVICES=0 "${kb_env[@]}" \
    bash ./install.sh </dev/null 2>&1

if [[ -f "$CONF/angelos/active" ]]; then
  say "angelOS активен — перепроверяю интеграцию с niri"
  python3 "$CONF/quickshell/angelos/scripts/switch.py" angelos --no-restart 2>&1 || say "switch.py вернул ошибку"
fi
if command -v niri >/dev/null; then
  if niri validate >/dev/null 2>&1; then say "niri: конфиг валиден"; else say "niri: validate НЕ прошёл — смотри niri validate"; fi
fi
say "готово ♡"
