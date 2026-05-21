#!/usr/bin/env bash
# Установка dotfiles niri для Arch Linux + опционально Muslim-reminder.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIRI_SRC="${ROOT}/dotfiles/niri"
NIRI_DST="${NIRI_DOTFILES_NIRI_DST:-${XDG_CONFIG_HOME:-$HOME/.config}/niri}"
MR_BUNDLE="${ROOT}/muslim-reminder"
MR_DST="${NIRI_DOTFILES_MR_DST:-${XDG_DATA_HOME:-$HOME/.local/share}/muslim-reminder}"
# Плейсхолдеры в *.kdl (см. dotfiles/niri/) — подставляются при установке, без дублирования строк.
PLACEHOLDER_NOCTALIA="__NOCTALIA_PATH__"
PLACEHOLDER_MR="__MR_DST__"
DEFAULT_NOCTALIA="${HOME}/Music/noctalia-shell-main"

# Неинтерактивный режим (для автопроверки / CI):
#   NIRI_NONINTERACTIVE=1 NIRI_INSTALL_MR=1|0 NIRI_INSTALL_PKGS=1|0 NOCTALIA_PATH=...
NIRI_NONINTERACTIVE="${NIRI_NONINTERACTIVE:-0}"
NIRI_INSTALL_MR="${NIRI_INSTALL_MR:-}"
NIRI_INSTALL_PKGS="${NIRI_INSTALL_PKGS:-}"

RED=$'\033[0;31m'
GRN=$'\033[0;32m'
YLW=$'\033[0;33m'
BLU=$'\033[0;34m'
BOLD=$'\033[1m'
RST=$'\033[0m'

die() { echo "${RED}Ошибка:${RST} $*" >&2; exit 1; }
info() { echo "${GRN}→${RST} $*"; }
warn() { echo "${YLW}!${RST} $*"; }

prompt_yn() {
  local def="$1" msg="$2" r
  while true; do
    read -r -p "${BOLD}${msg}${RST} [y/N]: " r || true
    r="${r:-$def}"
    case "${r,,}" in
      y|yes|д|да) return 0 ;;
      n|no|н|нет|'') return 1 ;;
      *) echo "Введите y или n." ;;
    esac
  done
}

# Безопасная подстановка в sed (разделитель |)
sed_replace() {
  local file="$1" pattern="$2" replacement="$3"
  local esc_pat esc_rep
  esc_pat="$(printf '%s' "$pattern" | sed 's/[&|]/\\&/g')"
  esc_rep="$(printf '%s' "$replacement" | sed 's/[&|]/\\&/g')"
  sed -i "s|${esc_pat}|${esc_rep}|g" "$file"
}

patch_kdl_tree() {
  local dir="$1"
  local f
  while IFS= read -r -d '' f; do
    sed_replace "$f" "$PLACEHOLDER_NOCTALIA" "$NOCTALIA_PATH"
    if (( INSTALL_MR )); then
      sed_replace "$f" "$PLACEHOLDER_MR" "$MR_DST"
    else
      sed -i "/${PLACEHOLDER_MR//\//\\/}/d" "$f"
    fi
  done < <(find "$dir" -name '*.kdl' -type f -print0)
}

sync_niri_tree() {
  mkdir -p "$NIRI_DST/dms"
  cp -a "${NIRI_SRC}/config.kdl" "${NIRI_SRC}/monitor.kdl" "${NIRI_SRC}/noctalia.kdl" "$NIRI_DST/"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "${NIRI_SRC}/dms/" "$NIRI_DST/dms/"
  else
    rm -f "$NIRI_DST/dms/"*.kdl
    cp -a "${NIRI_SRC}/dms/"*.kdl "$NIRI_DST/dms/"
  fi
}

banner() {
  echo ""
  echo "${BLU}${BOLD}╔══════════════════════════════════════════════════════════╗${RST}"
  echo "${BLU}${BOLD}║${RST}  ${BOLD}niri-arch-dotfiles${RST} — установка на Arch Linux        ${BLU}${BOLD}║${RST}"
  echo "${BLU}${BOLD}╚══════════════════════════════════════════════════════════╝${RST}"
  echo ""
}

install_muslim_reminder() {
  command -v python3 >/dev/null || die "нужен python3 (пакет python)"
  [[ -f "${MR_BUNDLE}/quran_reminder.py" ]] || die "не найден ${MR_BUNDLE}/quran_reminder.py"

  mkdir -p "$MR_DST"
  cp -a "${MR_BUNDLE}/quran_reminder.py" "${MR_BUNDLE}/run.sh" "${MR_BUNDLE}/trigger.sh" \
    "${MR_BUNDLE}/requirements.txt" "$MR_DST/"
  [[ -f "${MR_BUNDLE}/icon-quran.svg" ]] && cp -a "${MR_BUNDLE}/icon-quran.svg" "$MR_DST/"
  chmod +x "$MR_DST/run.sh" "$MR_DST/trigger.sh"

  if [[ ! -x "$MR_DST/.venv/bin/python" ]]; then
    info "Создание venv и установка зависимостей…"
    ( cd "$MR_DST" && python3 -m venv .venv && .venv/bin/pip install -q -U pip && .venv/bin/pip install -q -r requirements.txt )
  else
    ( cd "$MR_DST" && .venv/bin/pip install -q -r requirements.txt )
  fi

  python3 -c "import ast; ast.parse(open('${MR_DST}/quran_reminder.py', encoding='utf-8').read())" \
    || die "ошибка синтаксиса quran_reminder.py"
  info "Muslim-reminder → ${MR_DST}"
}

strip_muslim_from_niri() {
  sed -i \
    -e '/spawn-at-startup.*[Mm]uslim-reminder/d' \
    -e "/spawn-at-startup.*${MR_DST//\//\\/}/d" \
    -e "/${PLACEHOLDER_MR//\//\\/}/d" \
    "$NIRI_DST/config.kdl" 2>/dev/null || true
  cat >"$NIRI_DST/dms/binds.kdl" <<'EOF'
binds {
}
EOF
  warn "Muslim-reminder отключён: убран автозапуск и хоткей Mod+Ctrl+O."
}

main() {
  banner
  [[ -d "$NIRI_SRC" ]] || die "Не найден каталог ${NIRI_SRC}"

  if [[ "$NIRI_NONINTERACTIVE" == "1" ]]; then
    NOCTALIA_PATH="${NOCTALIA_PATH:-$DEFAULT_NOCTALIA}"
    NIRI_INSTALL_MR="${NIRI_INSTALL_MR:-0}"
    NIRI_INSTALL_PKGS="${NIRI_INSTALL_PKGS:-0}"
    info "Неинтерактивный режим (MR=${NIRI_INSTALL_MR}, pacman=${NIRI_INSTALL_PKGS})"
  else
    read -r -p "${BOLD}Путь к Noctalia (quickshell -p)${RST} [${DEFAULT_NOCTALIA}]: " NOCTALIA_PATH
    NOCTALIA_PATH="${NOCTALIA_PATH:-$DEFAULT_NOCTALIA}"
    if prompt_yn "n" "Установить ${BOLD}Muslim-reminder${RST} (Quran reminder) и прописать пути в niri?"; then
      NIRI_INSTALL_MR=1
    else
      NIRI_INSTALL_MR=0
    fi
    if prompt_yn "n" "Установить пакеты через ${BOLD}pacman${RST} (niri, quickshell, ghostty, …)?"; then
      NIRI_INSTALL_PKGS=1
    else
      NIRI_INSTALL_PKGS=0
    fi
  fi

  if [[ ! -d "$NOCTALIA_PATH" ]]; then
    warn "Каталог Noctalia не найден: ${NOCTALIA_PATH} (панель/лаунчер могут не работать)"
  fi

  if (( NIRI_INSTALL_PKGS )); then
    command -v sudo >/dev/null || die "нужен sudo для pacman"
    info "pacman -S (нужен пароль root)…"
    sudo pacman -S --needed --noconfirm \
      niri quickshell ghostty wireplumber pipewire pipewire-pulse pipewire-audio \
      python brightnessctl playerctl \
      xdg-desktop-portal xdg-desktop-portal-gnome \
      noto-fonts noto-fonts-cjk noto-fonts-emoji \
      || die "pacman завершился с ошибкой"
  fi

  if [[ -d "$NIRI_DST" ]] && [[ ! -w "$NIRI_DST" ]]; then
    die "${NIRI_DST} недоступен для записи (часто из‑за root). Выполните: sudo chown -R \"\$(id -un):\$(id -gn)\" \"${NIRI_DST}\""
  fi

  BACKUP="${NIRI_DST}.backup.$(date +%Y%m%d-%H%M%S)"
  if [[ -d "$NIRI_DST" ]]; then
    info "Резервная копия: ${BACKUP}"
    cp -a "$NIRI_DST" "$BACKUP"
  fi

  INSTALL_MR=$(( NIRI_INSTALL_MR ))
  sync_niri_tree
  patch_kdl_tree "$NIRI_DST"

  if (( INSTALL_MR )); then
    install_muslim_reminder
  else
    strip_muslim_from_niri
  fi

  if command -v niri >/dev/null; then
    if ( cd "$NIRI_DST" && niri validate -c config.kdl >/dev/null 2>&1 ); then
      info "niri validate: конфиг корректен"
    else
      warn "niri validate сообщил об ошибке — проверьте вручную:"
      ( cd "$NIRI_DST" && niri validate -c config.kdl ) || true
    fi
  else
    warn "niri не установлен — пропущена проверка validate"
  fi

  echo ""
  echo "${GRN}${BOLD}Готово.${RST}"
  echo "  Конфиг niri:     ${NIRI_DST}"
  echo "  Noctalia:        ${NOCTALIA_PATH}"
  (( INSTALL_MR )) && echo "  Muslim-reminder: ${MR_DST}  (Mod+Ctrl+O — случайный аят)"
  echo "  Проверка:        cd \"${NIRI_DST}\" && niri validate -c config.kdl"
  echo ""
}

main "$@"
