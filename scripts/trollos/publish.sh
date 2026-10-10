#!/usr/bin/env bash
# TrollOS: put what runs on the author's system into this repository.
#
#   scripts/trollos/publish.sh                 bring the files over and show what changed (no commit)
#   scripts/trollos/publish.sh "что сделал"    the same, then commit with that message and push
#
# Takes ~/.config/quickshell/angelos (the shell) and what publish.list names
# (plugins from ~/.config/angelos/plugins, scripts from ~/.local/bin). Niri,
# terminal and GTK configs are templates in the repo (@HOME@ …) and are not
# copied — edit them in the repo by hand.
#
# Before committing, every added line is checked for your home path and for the
# strings in ~/.config/trollos/private.txt (one per line: Discord IDs, e-mail,
# device names…). Anything found stops the commit.
set -Eeuo pipefail
say() { printf '» %s\n' "$*"; }
die() { printf '✕ %s\n' "$*" >&2; exit 1; }

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
LIVE="$HOME/.config/quickshell/angelos"
PLUGINS="$HOME/.config/angelos/plugins"
LIST="$ROOT/scripts/trollos/publish.list"
PRIVATE="${XDG_CONFIG_HOME:-$HOME/.config}/trollos/private.txt"
MSG="${1:-}"

cd "$ROOT"
[[ -d "$LIVE" ]] || die "нет $LIVE"
[[ "$(git rev-parse --abbrev-ref HEAD)" == trollos ]] || die "нужна ветка trollos (сейчас $(git rev-parse --abbrev-ref HEAD))"
[[ -e "$(git rev-parse --git-dir)/MERGE_HEAD" ]] && die "идёт слияние — сначала закончи его (git commit) или отмени (git merge --abort)"

plugins=() bins=()
while read -r kind name _; do
  case "$kind" in
    plugin) plugins+=("$name") ;;
    bin) bins+=("$name") ;;
  esac
done < <(grep -v '^\s*\(#\|$\)' "$LIST")

skip=(--exclude='*.bak*' --exclude='__pycache__' --exclude='*.pyc' --exclude='bak-win11' --exclude='*.trollos-new')
keep=()
for p in "${plugins[@]}"; do keep+=(--exclude="/plugins/$p/"); done

say "шелл: $LIVE"
rsync -a --delete "${skip[@]}" "${keep[@]}" "$LIVE/" "$ROOT/.config/quickshell/angelos/"
for p in "${plugins[@]}"; do
  [[ -d "$PLUGINS/$p" ]] || { say "плагина $p нет в $PLUGINS — пропускаю"; continue; }
  rsync -a --delete "${skip[@]}" "$PLUGINS/$p/" "$ROOT/.config/quickshell/angelos/plugins/$p/"
done
for b in "${bins[@]}"; do
  [[ -f "$HOME/.local/bin/$b" ]] && cp -p "$HOME/.local/bin/$b" "$ROOT/.local/bin/$b"
done

git add -A
if git diff --cached --quiet; then
  say "изменений нет — в репозитории уже то же, что у тебя ♡"
  exit 0
fi

# personal data check on the lines that would be published
added="$(git diff --cached -U0 | grep '^+' | grep -v '^+++' || true)"
hits="$(
  grep -nF -- "$HOME/" <<<"$added" || true
  [[ -s "$PRIVATE" ]] && { grep -nF -f <(grep -v '^\s*\(#\|$\)' "$PRIVATE") <<<"$added" || true; }
  true
)"
if [[ -n "$hits" ]]; then
  git reset -q
  printf '%s\n' "$hits" | cut -c1-200 | head -20
  die "нашлись личные данные (путь к дому или строки из $PRIVATE) — убери их и запусти снова. Ничего не закоммичено."
fi

git diff --cached --stat | tail -25
if [[ -z "$MSG" ]]; then
  git reset -q
  say "это изменения, которые уйдут в репозиторий. Чтобы выложить: scripts/trollos/publish.sh \"что сделал\""
  exit 0
fi

git commit -q -m "$MSG"
say "коммит $(git log -1 --format='%h %s')"
git push origin trollos
say "выложено ♡ — у тех, кто поставил TrollOS, появится обновление"
