#!/usr/bin/env bash
# Починить анимированные обои iNiR (видео/GIF замирают на первом кадре).
# Главная причина: background.pauseAnimationOnBattery=true на ноутбуке от батареи.
set -euo pipefail

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/inir/config.json"
[[ -f "$CFG" ]] || { echo "Нет $CFG — iNiR не установлен?"; exit 1; }

cp -a "$CFG" "${CFG}.bak.$(date +%Y%m%d-%H%M%S)"

python3 - "$CFG" <<'PY'
import json, sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text())
bg = data.setdefault("background", {})

before = {
    "enableAnimation": bg.get("enableAnimation"),
    "pauseAnimationOnBattery": bg.get("pauseAnimationOnBattery"),
    "wallpaperPath": bg.get("wallpaperPath"),
}
bg["enableAnimation"] = True
bg["pauseAnimationOnBattery"] = False

# Виджеты на фоне тоже могут стопать анимацию при окнах/fullscreen — не трогаем
# pauseOnFullscreen/GameMode, только явный "всегда пауза" если вдруг включён.
ps = (bg.get("widgets") or {}).setdefault("powerSaving", {})
if ps.get("pauseWhenWindowsPresent") is True:
    ps["pauseWhenWindowsPresent"] = False

path.write_text(json.dumps(data, indent=4, ensure_ascii=False) + "\n")

wp = str(bg.get("wallpaperPath") or "")
lower = wp.lower()
is_video = lower.endswith((".mp4", ".webm", ".mkv", ".avi", ".mov", ".gif"))
print("Было:", before)
print("Стало: enableAnimation=True, pauseAnimationOnBattery=False")
print("Текущие обои:", wp or "(пусто)")
print("Это видео/GIF:" , "да" if is_video else "нет — выбери .mp4/.gif в Ctrl+Alt+T → Live Wallpapers")
PY

if command -v inir >/dev/null; then
  echo "→ restart inir"
  inir restart 2>/dev/null || systemctl --user restart inir.service
else
  systemctl --user restart inir.service 2>/dev/null || true
  echo "Перезапусти shell: systemctl --user restart inir.service"
fi

echo "Готово. Если всё ещё статично — открой Ctrl+Alt+T и кликни любой .mp4 из Live Wallpapers."
