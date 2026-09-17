#!/usr/bin/env bash
# Установить обои Wall-E-Desk в ~/Pictures/wallpapers/Wall-E-Desk
# Источник: https://github.com/JoshuaThadi/Wall-E-Desk
set -euo pipefail

REPO_URL="${WALL_E_REPO:-https://github.com/JoshuaThadi/Wall-E-Desk.git}"
DEST="${WALLPAPERS_DIR:-${HOME}/Pictures/wallpapers}/Wall-E-Desk"
KEEP_GIT="${KEEP_GIT:-0}"

mkdir -p "$(dirname "$DEST")"

if [[ -d "$DEST/.git" ]]; then
  echo "→ Обновляю уже клонированный репозиторий: $DEST"
  git -C "$DEST" pull --ff-only
else
  if [[ -d "$DEST" ]]; then
    echo "→ $DEST уже есть без .git — переименовываю в ${DEST}.bak.$$"
    mv "$DEST" "${DEST}.bak.$$"
  fi
  echo "→ Клонирую Wall-E-Desk → $DEST"
  git clone --depth 1 "$REPO_URL" "$DEST"
fi

# Убрать .git, чтобы wallpaper-селектор не видел служебные файлы и экономить место
if [[ "$KEEP_GIT" != "1" && -d "$DEST/.git" ]]; then
  echo "→ Удаляю .git (KEEP_GIT=1 чтобы оставить)"
  rm -rf "$DEST/.git"
fi

# Посчитать картинки/видео
count="$(
  find "$DEST" -type f \( \
    -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \
    -o -iname '*.gif' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' \
  \) | wc -l
)"

echo "Готово: $count файлов в $DEST"
echo "Категории:"
find "$DEST" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' | sort
echo
echo "Открой селектор обоев: Ctrl+Alt+T"
echo "Папка: $DEST"
