#!/bin/bash
# bump-pins.sh - move the pins block in functions/qs_setup.fish to the latest
# upstream versions, after showing what changed.
#
#   scripts/bump-pins.sh            # resolve, show the diff, ask per item, rewrite, offer the test
#   scripts/bump-pins.sh --yes      # take every update without asking or showing the diff
#   scripts/bump-pins.sh --check    # only list what's out of date; exit 1 if anything is
#
# What is reviewed:
#   - fisher and each fisher plugin: `git log` + full `git diff` from the pinned
#     commit to the new HEAD, in $PAGER. Plugins are code sourced into every
#     shell, so this is the part worth reading.
#   - mise: the release notes/compare links; the new sha256 values come from the
#     release's own SHASUMS256.txt.
#   - mise tools: old -> new versions (resolved with the host's `mise latest`).
#
# Afterwards: scripts/test-setup.sh runs qs_setup in a fresh container against
# the rewritten file. Commit, push, then bump the consumers' pin of this file
# (code-docker: ./dev-bump-qwreey-fish.sh).
set -u -o pipefail

cd "$(dirname "$0")/.." || exit 1
SETUP=functions/qs_setup.fish
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/qwreey-fish-bump"

yes=0
check=0
for arg in "$@"; do
  case $arg in
    --yes) yes=1 ;;
    --check) check=1 ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

for cmd in fish git curl mise sha256sum awk; do
  command -v "$cmd" >/dev/null || { echo "bump-pins: $cmd is required" >&2; exit 1; }
done

# Current pins, read by fish itself (sourcing the file only defines functions
# and sets these variables).
pin() { fish --no-config -c "source $SETUP; printf '%s\n' \$$1"; }
old_fisher=$(pin _qs_pin_fisher)
mapfile -t old_plugins < <(pin _qs_pin_plugins)
old_mise=$(pin _qs_pin_mise)
mapfile -t old_tools < <(pin _qs_pin_tools)

# head_of <owner/repo> - its default branch's commit; exits the script on
# failure, so an empty value can never be written as a pin (an empty @ref
# would make fisher fetch the default branch - unpinned again).
head_of() {
  local sha
  sha=$(git ls-remote "https://github.com/$1.git" HEAD | cut -f1)
  if ! printf '%s' "$sha" | grep -qE '^[0-9a-f]{40}$'; then
    echo "bump-pins: could not resolve $1 HEAD - nothing written" >&2
    exit 1
  fi
  printf '%s' "$sha"
}

# Bare, blobless mirror per repo, so diffs between any two pinned commits are
# local after the first fetch.
mirror() {
  local repo=$1 dir="$CACHE/${1//\//__}.git"
  if [ ! -d "$dir" ]; then
    git clone --quiet --bare --filter=blob:none "https://github.com/$repo.git" "$dir" || return 1
  else
    git -C "$dir" fetch --quiet origin '+refs/heads/*:refs/heads/*' || return 1
  fi
  printf '%s' "$dir"
}

report=$(mktemp)
trap 'rm -f "$report"' EXIT

# review_git <repo> <old> <new> - appends log + diff to the report.
review_git() {
  local repo=$1 old=$2 new=$3 dir
  [ $check = 1 ] && return
  {
    echo "################################################################"
    echo "# $repo  ${old:0:12} -> ${new:0:12}"
    echo "# https://github.com/$repo/compare/$old...$new"
    echo "################################################################"
  } >>"$report"
  if ! dir=$(mirror "$repo"); then
    echo "(could not fetch $repo - review the compare link above)" >>"$report"
    return
  fi
  if ! git -C "$dir" merge-base --is-ancestor "$old" "$new" 2>/dev/null; then
    echo "!! $old is not an ancestor of $new (force-pushed or rewritten history) - read the whole tree, not just this diff" >>"$report"
  fi
  git -C "$dir" log --format='%h %ad %an  %s' --date=short "$old..$new" >>"$report" 2>&1
  echo >>"$report"
  git -C "$dir" diff --stat "$old" "$new" >>"$report" 2>&1
  echo >>"$report"
  git -C "$dir" diff "$old" "$new" >>"$report" 2>&1
  echo >>"$report"
}

changes=()  # human-readable lines, also used as the commit message body

echo "resolving latest versions..."

new_fisher=$(head_of jorgebucaran/fisher) || exit 1
if [ "$new_fisher" != "$old_fisher" ]; then
  changes+=("fisher ${old_fisher:0:12} -> ${new_fisher:0:12}")
  review_git jorgebucaran/fisher "$old_fisher" "$new_fisher"
fi

new_plugins=()
for spec in "${old_plugins[@]}"; do
  repo=${spec%@*} old=${spec#*@}
  new=$(head_of "$repo") || exit 1
  new_plugins+=("$repo@$new")
  if [ "$new" != "$old" ]; then
    changes+=("$repo ${old:0:12} -> ${new:0:12}")
    review_git "$repo" "$old" "$new"
  fi
done

new_mise=$(curl -fsSL https://api.github.com/repos/jdx/mise/releases/latest | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -1)
if [ -z "$new_mise" ]; then
  echo "bump-pins: could not resolve the latest mise release" >&2
  exit 1
fi
if [ "$new_mise" != "$old_mise" ]; then
  changes+=("mise $old_mise -> $new_mise")
  {
    echo "################################################################"
    echo "# mise $old_mise -> $new_mise (binary release - read the notes)"
    echo "# https://github.com/jdx/mise/releases/tag/v$new_mise"
    echo "# https://github.com/jdx/mise/compare/v$old_mise...v$new_mise"
    echo "################################################################"
    echo
  } >>"$report"
fi

new_tools=()
for spec in "${old_tools[@]}"; do
  name=${spec%@*} old=${spec#*@}
  new=$(mise latest "$name" 2>/dev/null | tail -1)
  if [ -z "$new" ]; then
    echo "  ! mise latest $name failed - keeping $old"
    new=$old
  fi
  new_tools+=("$name@$new")
  [ "$new" != "$old" ] && changes+=("$name $old -> $new")
done

if [ ${#changes[@]} -eq 0 ]; then
  echo "all pins are current"
  exit 0
fi

echo
echo "out of date:"
printf '  %s\n' "${changes[@]}"
if [ $check = 1 ]; then
  exit 1
fi

if [ -s "$report" ] && [ $yes = 0 ]; then
  echo
  read -r -p "open the upstream diff for review? [Y/n] " a </dev/tty
  case $a in [nN]*) ;; *) ${PAGER:-less -R} "$report" ;; esac
fi

# accept <description> - asks unless --yes.
accept() {
  [ $yes = 1 ] && return 0
  local a
  read -r -p "  take $1? [y/N] " a </dev/tty
  case $a in [yY]*) return 0 ;; *) return 1 ;; esac
}

echo
fisher_sha=$old_fisher
if [ "$new_fisher" != "$old_fisher" ] && accept "fisher ${new_fisher:0:12}"; then
  fisher_sha=$new_fisher
fi
fisher_sha256=$(pin _qs_pin_fisher_sha256)
if [ "$fisher_sha" != "$old_fisher" ]; then
  if ! fisher_sha256=$(curl -fsSL "https://raw.githubusercontent.com/jorgebucaran/fisher/$fisher_sha/functions/fisher.fish" | sha256sum | cut -d' ' -f1); then
    echo "bump-pins: could not fetch fisher.fish at $fisher_sha - nothing written" >&2
    exit 1
  fi
fi

plugins=()
for i in "${!old_plugins[@]}"; do
  if [ "${new_plugins[$i]}" != "${old_plugins[$i]}" ] && accept "${new_plugins[$i]%@*} ${new_plugins[$i]#*@}"; then
    plugins+=("${new_plugins[$i]}")
  else
    plugins+=("${old_plugins[$i]}")
  fi
done

mise_version=$old_mise
if [ "$new_mise" != "$old_mise" ] && accept "mise $new_mise"; then
  mise_version=$new_mise
fi
mapfile -t mise_sha256 < <(pin _qs_pin_mise_sha256)
if [ "$mise_version" != "$old_mise" ]; then
  sums=$(curl -fsSL "https://github.com/jdx/mise/releases/download/v$mise_version/SHASUMS256.txt") || {
    echo "bump-pins: could not fetch SHASUMS256.txt for mise $mise_version" >&2
    exit 1
  }
  mise_sha256=()
  for plat in linux-x64 linux-arm64 macos-x64 macos-arm64; do
    h=$(printf '%s\n' "$sums" | awk -v f="mise-v$mise_version-$plat" '{ n = $2; sub(/^\.\//, "", n) } n == f { print $1 }')
    if [ -z "$h" ]; then
      echo "bump-pins: SHASUMS256.txt has no mise-v$mise_version-$plat" >&2
      exit 1
    fi
    mise_sha256+=("$plat:$h")
  done
fi

tools=()
for i in "${!old_tools[@]}"; do
  if [ "${new_tools[$i]}" != "${old_tools[$i]}" ] && accept "${new_tools[$i]}"; then
    tools+=("${new_tools[$i]}")
  else
    tools+=("${old_tools[$i]}")
  fi
done

# list <var> <items...> - a `set -g` with one item per continuation line.
list() {
  local var=$1
  shift
  printf 'set -g %s \\\n' "$var"
  local last=$(( $# ))
  local i=0
  for item in "$@"; do
    i=$((i + 1))
    if [ $i -lt $last ]; then printf '\t%s \\\n' "$item"; else printf '\t%s\n' "$item"; fi
  done
}

block=$(
  echo "# --- pins: generated by scripts/bump-pins.sh ---"
  echo "set -g _qs_pin_fisher $fisher_sha"
  echo "set -g _qs_pin_fisher_sha256 $fisher_sha256"
  list _qs_pin_plugins "${plugins[@]}"
  echo "set -g _qs_pin_mise $mise_version"
  list _qs_pin_mise_sha256 "${mise_sha256[@]}"
  list _qs_pin_tools "${tools[@]}"
  echo "# --- end pins ---"
)

tmp=$(mktemp)
# Through the environment, not awk -v: -v processes backslash escapes, which
# would eat the line-continuation backslashes in the block.
BLOCK=$block awk '
  /^# --- pins: generated by scripts\/bump-pins.sh ---$/ { print ENVIRON["BLOCK"]; skip = 1; next }
  /^# --- end pins ---$/ { skip = 0; next }
  !skip { print }
' "$SETUP" >"$tmp" && cat "$tmp" >"$SETUP"
rm -f "$tmp"

echo
if git diff --quiet -- "$SETUP"; then
  echo "nothing taken - $SETUP unchanged"
  exit 0
fi
git --no-pager diff --stat -- "$SETUP"
echo
echo "next:"
echo "  scripts/test-setup.sh             # fresh container"
echo "  scripts/test-setup.sh --upgrade   # on top of the currently published setup"
echo "  git commit -am 'chore(pins): bump' ..."
