#!/usr/bin/env bash
# Установить обои Wall-E-Desk в ~/Pictures/wallpapers/Wall-E-Desk
# Источник: https://github.com/JoshuaThadi/Wall-E-Desk
set -euo pipefail

REPO_URL="${WALL_E_REPO:-https://github.com/JoshuaThadi/Wall-E-Desk.git}"
DEST="${WALLPAPERS_DIR:-${HOME}/Pictures/wallpapers}/Wall-E-Desk"
KEEP_GIT="${KEEP_GIT:-0}"
FORCE="${FORCE:-0}"

mkdir -p "$(dirname "$DEST")"

count_media() {
  local root="$1"
  find "$root" -type f \( \
    -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \
    -o -iname '*.gif' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' \
  \) 2>/dev/null | wc -l
}

# Пустая / битая папка → переустановить
existing=0
if [[ -d "$DEST" ]]; then
  existing="$(count_media "$DEST")"
fi

if (( existing > 0 )) && [[ "$FORCE" != "1" ]]; then
  if [[ -d "$DEST/.git" ]]; then
    echo "→ Уже есть $existing файлов, обновляю git pull…"
    git -C "$DEST" pull --ff-only || true
  else
    echo "→ Уже установлено: $existing файлов в $DEST"
    echo "  Переустановка: FORCE=1 $0"
    exit 0
  fi
else
  if [[ -e "$DEST" ]]; then
    bak="${DEST}.bak.$(date +%Y%m%d-%H%M%S)"
    echo "→ $DEST пустая/старая ($existing media) — бэкап в $bak"
    mv "$DEST" "$bak"
  fi
  echo "→ Клонирую Wall-E-Desk → $DEST (~2.8 GiB, подожди)…"
  git clone --depth 1 --progress "$REPO_URL" "$DEST"
fi

if [[ "$KEEP_GIT" != "1" && -d "$DEST/.git" ]]; then
  echo "→ Удаляю .git (KEEP_GIT=1 чтобы оставить)"
  rm -rf "$DEST/.git"
fi

count="$(count_media "$DEST")"
if (( count < 10 )); then
  echo "Ошибка: после установки почти нет картинок ($count)." >&2
  echo "Проверь сеть и повтори: FORCE=1 $0" >&2
  exit 1
fi

echo "Готово: $count файлов в $DEST"
echo "Размер: $(du -sh "$DEST" | cut -f1)"
echo "Категории:"
find "$DEST" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' | sort
echo
echo "Открой селектор: Ctrl+Alt+T → $DEST"
