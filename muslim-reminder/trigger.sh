#!/bin/sh
# Срабатывание Quran Reminder под Wayland: SIGUSR1 демону или разовый --once.
set -e
DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
PIDF="$RUNTIME/quran-reminder.pid"
if [ -f "$PIDF" ]; then
  pid="$(cat "$PIDF" 2>/dev/null || true)"
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    kill -USR1 "$pid"
    exit 0
  fi
fi
exec "$DIR/run.sh" --once
