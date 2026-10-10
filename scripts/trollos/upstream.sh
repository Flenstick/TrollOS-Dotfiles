#!/usr/bin/env bash
# TrollOS: bring in what MixaDoDs added to angelOS (AngelOS-Dotfiles).
#
#   scripts/trollos/upstream.sh          how many new angelOS commits there are, and the latest of them
#   scripts/trollos/upstream.sh merge    merge them into the trollos branch (conflicts are solved by hand)
#
# After a merge check the TrollOS parts first: widgets/AngelLogo.qml (the splat),
# config/Config.qml (startLabel, wallpaper.fallback), scripts/dotfiles-update.sh
# (OFFICIAL, the smart update), install.sh (UPDATE_FROM), README.md.
set -Eeuo pipefail
say() { printf '» %s\n' "$*"; }
die() { printf '✕ %s\n' "$*" >&2; exit 1; }

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
URL="https://github.com/MixaDoDs/AngelOS-Dotfiles.git"
cd "$ROOT"
git remote get-url upstream >/dev/null 2>&1 || git remote add upstream "$URL"
say "git fetch upstream"
git fetch -q upstream main
n="$(git rev-list --count HEAD..upstream/main)"

case "${1:-status}" in
  status)
    if [[ "$n" == 0 ]]; then say "в angelOS ничего нового ♡"; exit 0; fi
    say "в angelOS новых коммитов: $n (последние):"
    git log --format='  %h %cs %s' HEAD..upstream/main | cut -c1-110 | head -15
    say "влить: scripts/trollos/upstream.sh merge"
    ;;
  merge)
    [[ "$n" == 0 ]] && { say "нечего вливать ♡"; exit 0; }
    [[ "$(git rev-parse --abbrev-ref HEAD)" == trollos ]] || die "нужна ветка trollos"
    [[ -z "$(git status --porcelain)" ]] || die "в репозитории есть незакоммиченные правки — сначала закоммить их"
    if git merge --no-ff -m "Merge angelOS ($n commits from MixaDoDs/AngelOS-Dotfiles)" upstream/main; then
      say "влито без конфликтов. Проверь логотип, Config.qml, обновлятор и README, потом: git push origin trollos"
    else
      say "конфликты в файлах:"
      git diff --name-only --diff-filter=U | sed 's/^/  /'
      say "реши их (оставь части TrollOS), затем: git add <файлы> && git commit && git push origin trollos"
      say "передумал — git merge --abort"
      exit 1
    fi
    ;;
  *) die "команды: status | merge" ;;
esac
