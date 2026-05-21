#!/usr/bin/env bash
# Локальная проверка репозитория без установки в ~/.config.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NIRI_CFG="${ROOT}/dotfiles/niri"
MR="${ROOT}/muslim-reminder"
ERR=0

red() { printf '\033[0;31m✗\033[0m %s\n' "$*"; }
grn() { printf '\033[0;32m✓\033[0m %s\n' "$*"; }

check() {
  if "$@"; then grn "$1"; else red "FAILED: $*"; ERR=1; fi
}

echo "Проверка niri-arch-dotfiles…"

check bash -n "${ROOT}/install-arch.sh"
check test -f "${NIRI_CFG}/config.kdl"
check test -f "${MR}/quran_reminder.py"
check sh -n "${MR}/run.sh"
check sh -n "${MR}/trigger.sh"

if command -v niri >/dev/null; then
  ( cd "$NIRI_CFG" && niri validate -c config.kdl >/dev/null 2>&1 ) && grn "niri validate (bundle)" || { red "niri validate (bundle)"; ERR=1; }
else
  red "niri не в PATH — пропуск validate"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp -a "$NIRI_CFG" "$TMP/niri"
NOCTALIA_PATH="${NOCTALIA_PATH:-${HOME}/Music/noctalia-shell-main}"
find "$TMP/niri" -name '*.kdl' -type f -exec sed -i \
  -e "s|__NOCTALIA_PATH__|${NOCTALIA_PATH}|g" \
  -e "s|__MR_DST__|${TMP}/muslim-reminder|g" \
  {} +
if command -v niri >/dev/null; then
  ( cd "$TMP/niri" && niri validate -c config.kdl >/dev/null 2>&1 ) && grn "niri validate (после подстановки HOME)" || { red "niri validate (HOME patch)"; ERR=1; }
fi

if command -v python3 >/dev/null; then
  python3 -c "import ast; ast.parse(open('${MR}/quran_reminder.py', encoding='utf-8').read())" \
    && grn "python3 ast.parse quran_reminder.py" \
    || { red "синтаксис quran_reminder.py"; ERR=1; }
fi

# Пробная установка в /tmp (не трогает ~/.config)
STAGE="/tmp/niri-arch-dotfiles-staging"
rm -rf "$STAGE"
export NIRI_DOTFILES_NIRI_DST="${STAGE}/niri"
export NIRI_DOTFILES_MR_DST="${STAGE}/muslim-reminder"
export NIRI_NONINTERACTIVE=1 NIRI_INSTALL_MR=1 NIRI_INSTALL_PKGS=0
export NOCTALIA_PATH="${NOCTALIA_PATH:-${HOME}/Music/noctalia-shell-main}"
if "${ROOT}/install-arch.sh" >/dev/null 2>&1; then
  grn "install-arch.sh (staging → ${STAGE})"
  ( cd "${STAGE}/niri" && niri validate -c config.kdl >/dev/null 2>&1 ) && grn "niri validate (после install)" || { red "niri validate после install"; ERR=1; }
else
  red "install-arch.sh staging"
  ERR=1
fi
rm -rf "$STAGE"

exit "$ERR"
