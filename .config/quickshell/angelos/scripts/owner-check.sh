#!/bin/sh
# angelOS owner check: is the GitHub account logged in here (gh) an admin of the
# dotfiles repository? Owner features (services/Owner) and the owner's publish
# script switch on only then — the owner/ folder and the marker file alone are not
# enough, anyone could copy those.
#
#   owner-check.sh <repo url>   prints one line:
#     admin <login>    gh says this account administers the repo (remembered)
#     cached <login>   gh could not ask (offline, no gh), but it did within 14 days
#     denied <login>   gh answered: no admin rights / no such repo for this account
#     unknown          no gh login and nothing remembered
# The answer is GitHub's: nothing here can be edited to say yes.
url="${1:-}"
repo=$(printf '%s' "$url" | sed -E 's#^(https://github\.com/|git@github\.com:|ssh://git@github\.com/)##; s#\.git$##; s#/+$##')
cache="${XDG_CACHE_HOME:-$HOME/.cache}/angelos/owner-check"
[ -n "$repo" ] || { echo unknown; exit 0; }

if command -v gh >/dev/null 2>&1; then
  login=$(gh api user --jq .login 2>/dev/null)
  if [ -n "$login" ]; then
    out=$(gh api "repos/$repo" --jq '.permissions.admin' 2>&1)
    code=$?
    if [ $code -eq 0 ] && [ "$out" = true ]; then
      mkdir -p "$(dirname "$cache")"
      printf '%s %s %s\n' "$(date +%s)" "$repo" "$login" > "$cache"
      echo "admin $login"
      exit 0
    fi
    # an answer from GitHub (no rights, or the repo is invisible to this account)
    if [ $code -eq 0 ] || printf '%s' "$out" | grep -qE 'Not Found|HTTP 40[34]'; then
      # forget a remembered yes for this repo (not for another one)
      [ -f "$cache" ] && [ "$(cut -d' ' -f2 "$cache")" = "$repo" ] && rm -f "$cache"
      echo "denied $login"
      exit 0
    fi
  fi
fi
# no answer (offline, gh missing or logged out): a recent yes still counts
if [ -f "$cache" ]; then
  read -r ts crepo clogin < "$cache"
  now=$(date +%s)
  if [ "$crepo" = "$repo" ] && [ $((now - ts)) -lt 1209600 ]; then
    echo "cached $clogin"
    exit 0
  fi
fi
echo unknown
