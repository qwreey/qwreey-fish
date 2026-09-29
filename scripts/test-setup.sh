#!/bin/bash
# test-setup.sh - run this checkout's qs_setup in a throwaway Arch container
# and check that every pin actually landed.
#
#   scripts/test-setup.sh               # fresh home
#   scripts/test-setup.sh --upgrade     # first run the published qs_setup (origin/main),
#                                       # then this one on top - the path existing installs take
#   scripts/test-setup.sh --upgrade=<commit>
#
# Needs docker. Uses the working tree as-is (uncommitted changes included),
# installed as a local fisher plugin (--self /src).
set -u

cd "$(dirname "$0")/.." || exit 1

base=""
for arg in "$@"; do
  case $arg in
    --upgrade) base=$(git rev-parse origin/main) ;;
    --upgrade=*) base=${arg#--upgrade=} ;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

docker run --rm -i -v "$PWD:/src:ro" -e BASE="$base" archlinux:latest bash -s <<'EOF'
set -u
pacman -Syu --noconfirm --needed fish curl git tar gzip >/dev/null 2>&1 || { echo "pacman failed"; exit 1; }

if [ -n "$BASE" ]; then
  echo "=== published qs_setup at ${BASE:0:12} ==="
  fish -c "curl -fsSL https://raw.githubusercontent.com/qwreey/qwreey-fish/$BASE/functions/qs_setup.fish | source; and qs_setup" </dev/null >/tmp/base.log 2>&1
  echo "(exit $?, log tail:)"; tail -3 /tmp/base.log
fi

echo "=== this checkout's qs_setup ==="
fish -c 'source /src/functions/qs_setup.fish; and qs_setup --self /src' </dev/null >/tmp/setup.log 2>&1
status=$?
echo "(exit $status)"
grep -E '^(qs_setup|fisher):|mise ERROR' /tmp/setup.log | sed 's/^/  log: /'

fail=0
bad() { echo "  FAIL: $*"; fail=1; }
[ $status = 0 ] || bad "qs_setup exited $status"

# Expected values, read from the same file.
pin() { fish --no-config -c "source /src/functions/qs_setup.fish; printf '%s\n' \$$1"; }
plugins=$(fish -c 'printf "%s\n" $_fisher_plugins')

spec="jorgebucaran/fisher@$(pin _qs_pin_fisher)"
grep -qxF "$spec" <<<"$plugins" || bad "fisher plugin $spec not installed"
for spec in $(pin _qs_pin_plugins) /src; do
  grep -qxF "$spec" <<<"$plugins" || bad "fisher plugin $spec not installed"
done
extra=$(grep -vxF -e "jorgebucaran/fisher@$(pin _qs_pin_fisher)" -e /src $(for s in $(pin _qs_pin_plugins); do printf -- '-e %s ' "$s"; done) <<<"$plugins")
[ -z "$extra" ] || bad "leftover fisher plugins: $extra"
fish -c 'functions -q qs_setup; and functions -q qs_init' || bad "qwreey-fish functions not loadable"

want=$(pin _qs_pin_mise)
have=$(~/.local/bin/mise --version 2>/dev/null | head -1 | cut -d' ' -f1)
[ "$have" = "$want" ] || bad "mise is '$have', pinned $want"

for spec in $(pin _qs_pin_tools); do
  name=${spec%@*} ver=${spec#*@}
  [ "$name" = carapace ] && continue   # only with --with-carapace
  line=$(~/.local/bin/mise ls -g "$name" 2>/dev/null | head -1)
  grep -qw -- "$ver" <<<"$line" || bad "$name: want $ver, mise ls -g says '$line'"
  grep -q missing <<<"$line" && bad "$name $ver is configured but not installed"
done

echo
if [ $fail = 0 ]; then
  echo "PASS: fisher, plugins, mise and tools all at their pins"
else
  echo "--- setup log (tail) ---"
  tail -40 /tmp/setup.log
fi
exit $fail
EOF
