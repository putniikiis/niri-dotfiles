<div align="center">

# niri-arch-dotfiles

**Снимок конфигурации [niri](https://github.com/YaLTeR/niri) для Arch Linux**  
с плейсхолдерами путей, опциональным **Muslim-reminder** и идемпотентным `install-arch.sh`.

```
                                       ╭──────────────────────────────────────────╮
                                       │  Wayland · scroll tiling · KDL configs   │
                                       ╰──────────────────────────────────────────╯
```

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![niri](https://img.shields.io/badge/compositor-niri-7fc8ff?style=for-the-badge)](https://niri-wm.github.io/niri/)
[![Quickshell](https://img.shields.io/badge/shell-Quickshell-41cd52?style=for-the-badge)](https://quickshell.outfoxxed.me/)

</div>

---

## Содержание

- [Требования](#требования)
- [Состав](#состав)
- [Структура](#структура)
- [Плейсхолдеры путей](#плейсхолдеры-путей)
- [Установка](#установка)
- [Переменные окружения](#переменные-окружения)
- [Проверка без установки](#проверка-без-установки)
- [Muslim-reminder](#muslim-reminder)
- [Горячие клавиши](#горячие-клавиши)
- [После установки](#после-установки)
- [Права доступа](#права-доступа)
- [Устранение неполадок](#устранение-неполадок)

---

## Требования

| Компонент | Назначение |
|-----------|------------|
| [niri](https://niri-wm.github.io/niri/) | Композитор Wayland |
| [Quickshell](https://quickshell.outfoxxed.me/) + **Noctalia** | Панель, лаунчер, меню сессии (`qs -p`) |
| [Ghostty](https://ghostty.org/) | Терминал по умолчанию (`Mod+T`) |
| PipeWire + WirePlumber | Звук (`wpctl` в биндах) |
| `brightnessctl`, `playerctl` | Яркость и медиаклавиши |
| `python` | Muslim-reminder (опционально) |
| `rsync` | Рекомендуется: чистая синхронизация `dms/` (есть fallback без rsync) |

Пакеты можно поставить через `./install-arch.sh` (опция pacman) или вручную.

---

## Состав

| Файл / каталог | Назначение |
|----------------|------------|
| `dotfiles/niri/config.kdl` | Основной конфиг: ввод, `us,ru`, бинды, автозапуск, `include` фрагментов |
| `dotfiles/niri/monitor.kdl` | Мониторы (`nwg-displays` или вручную) |
| `dotfiles/niri/noctalia.kdl` | Цвета оформления niri (Catppuccin: фокус, тени, вкладки) |
| `dotfiles/niri/dms/alttab.kdl` | Переключатель окон (alt-tab) |
| `dotfiles/niri/dms/binds.kdl` | Доп. бинды (Quran Reminder — `Mod+Ctrl+O`) |
| `dotfiles/niri/dms/colors.kdl` | Цветовая схема DMS |
| `dotfiles/niri/dms/cursor.kdl` | Курсор |
| `dotfiles/niri/dms/layout.kdl` | Раскладка окон |
| `dotfiles/niri/dms/outputs.kdl` | Выходы / мониторы DMS |
| `dotfiles/niri/dms/windowrules.kdl` | Правила окон |
| `dotfiles/niri/dms/wpblur.kdl` | Размытие обоев |
| `muslim-reminder/` | Quran Reminder (Python, `run.sh`, `trigger.sh`, venv) |
| `install-arch.sh` | Установка на Arch: копирование, подстановка путей, venv |
| `scripts/verify.sh` | Локальная проверка и пробная установка в `/tmp` |
| `.gitignore` | Исключения для venv, кэша Python, pid-файлов |

---

## Структура

```text
niri-arch-dotfiles/
├── README.md
├── .gitignore
├── install-arch.sh
├── scripts/
│   └── verify.sh
├── dotfiles/niri/
│   ├── config.kdl          # плейсхолдеры __NOCTALIA_PATH__, __MR_DST__
│   ├── monitor.kdl
│   ├── noctalia.kdl
│   └── dms/
│       ├── alttab.kdl
│       ├── binds.kdl       # __MR_DST__/trigger.sh
│       ├── colors.kdl
│       ├── cursor.kdl
│       ├── layout.kdl
│       ├── outputs.kdl
│       ├── windowrules.kdl
│       └── wpblur.kdl
└── muslim-reminder/
    ├── quran_reminder.py
    ├── run.sh              # фоновый сервис (автозапуск niri)
    ├── trigger.sh          # один случайный аят
    ├── requirements.txt    # pynput
    ├── icon-quran.svg
    ├── install.sh
    ├── Quran-Reminder.desktop
    └── README.md
```

**После установки на машине пользователя:**

| Что | Куда |
|-----|------|
| Конфиг niri | `~/.config/niri` |
| Muslim-reminder | `~/.local/share/muslim-reminder` |
| Noctalia (вне репо) | каталог, указанный при установке (по умолчанию `~/Music/noctalia-shell-main`) |
| Резервная копия niri | `~/.config/niri.backup.ГГГГММДД-ЧЧММСС` |

---

## Плейсхолдеры путей

В репозитории **нет** жёстких путей вида `/home/имя/...`. Вместо них — маркеры, которые `install-arch.sh` заменяет **один раз** при установке:

| Плейсхолдер | Подставляется в |
|-------------|-----------------|
| `__NOCTALIA_PATH__` | Каталог Noctalia для `quickshell -p` / `qs -p` |
| `__MR_DST__` | Каталог Muslim-reminder (`~/.local/share/muslim-reminder` по умолчанию) |

Пример в `config.kdl` (до установки):

```kdl
spawn-at-startup "quickshell" "-n" "-p" "__NOCTALIA_PATH__"
spawn-at-startup "__MR_DST__/run.sh"
```

После установки с MR:

```kdl
spawn-at-startup "quickshell" "-n" "-p" "/home/user/Music/noctalia-shell-main"
spawn-at-startup "/home/user/.local/share/muslim-reminder/run.sh"
```

Если Muslim-reminder **не** выбран (`NIRI_INSTALL_MR=0`), строки с `__MR_DST__` удаляются, `dms/binds.kdl` очищается — дублирования автозапуска и хоткеев не будет.

---

## Установка

```bash
git clone <url> niri-arch-dotfiles   # или скопируйте каталог
cd niri-arch-dotfiles
chmod +x install-arch.sh scripts/verify.sh
./install-arch.sh
```

### Что делает скрипт

1. Спрашивает путь Noctalia, установку MR и пакеты pacman (или читает переменные окружения).
2. Создаёт резервную копию существующего `~/.config/niri`, если каталог уже есть.
3. **`sync_niri_tree`** — копирует `config.kdl`, `monitor.kdl`, `noctalia.kdl` и синхронизирует `dms/` (`rsync --delete` или полная перезапись `*.kdl`).
4. **`patch_kdl_tree`** — подставляет `__NOCTALIA_PATH__` и при необходимости `__MR_DST__`.
5. Устанавливает Muslim-reminder (venv + `pynput`) или отключает его в конфиге.
6. Запускает `niri validate -c config.kdl`, если `niri` в `PATH`.

Повторный запуск **идемпотентен**: не добавляет второй автозапуск MR и не дублирует `Mod+Ctrl+O`.

### Интерактивные вопросы

1. **Путь к Noctalia** — каталог для `quickshell -p` / `qs -p` (по умолчанию `~/Music/noctalia-shell-main`).
2. **Muslim-reminder** — `y`: копия в `~/.local/share/muslim-reminder`, venv, пути в niri; `n`: без автозапуска и без `Mod+Ctrl+O`.
3. **pacman** — `y`: `niri`, `quickshell`, `ghostty`, PipeWire, `python`, `brightnessctl`, `playerctl`, порталы, шрифты Noto.

### Неинтерактивный режим

```bash
NIRI_NONINTERACTIVE=1 \
NIRI_INSTALL_MR=1 \
NIRI_INSTALL_PKGS=0 \
NOCTALIA_PATH="$HOME/Music/noctalia-shell-main" \
./install-arch.sh
```

### Свои пути назначения

```bash
NIRI_DOTFILES_NIRI_DST="$HOME/.config/niri" \
NIRI_DOTFILES_MR_DST="$HOME/.local/share/muslim-reminder" \
./install-arch.sh
```

---

## Переменные окружения

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `NIRI_NONINTERACTIVE` | `0` | `1` — без вопросов в терминале |
| `NIRI_INSTALL_MR` | `0` (в неинтерактивном режиме) | `1` — установить Muslim-reminder |
| `NIRI_INSTALL_PKGS` | `0` | `1` — `pacman -S` зависимостей |
| `NOCTALIA_PATH` | `$HOME/Music/noctalia-shell-main` | Подстановка `__NOCTALIA_PATH__` |
| `NIRI_DOTFILES_NIRI_DST` | `$XDG_CONFIG_HOME/niri` | Куда положить конфиг niri |
| `NIRI_DOTFILES_MR_DST` | `$XDG_DATA_HOME/muslim-reminder` | Куда положить Muslim-reminder |

---

## Проверка без установки

```bash
./scripts/verify.sh
```

Проверяется:

- синтаксис `install-arch.sh`, `run.sh`, `trigger.sh`;
- `niri validate` на бандле в репозитории (с плейсхолдерами);
- `niri validate` после подстановки `__NOCTALIA_PATH__` и `__MR_DST__` во временной копии;
- `python3 -m ast` для `quran_reminder.py`;
- **пробная установка** в `/tmp/niri-arch-dotfiles-staging` (не трогает `~/.config`) и повторный `niri validate`.

При успехе все пункты отмечены ✓, код выхода `0`.

---

## Muslim-reminder

| | |
|--|--|
| **Каталог** | `~/.local/share/muslim-reminder` (XDG, не Рабочий стол) |
| **Зависимость** | `pynput` из `requirements.txt`, нужен `python3` |
| **Автозапуск** | `spawn-at-startup` → `__MR_DST__/run.sh` → `run.sh` в niri |
| **Разовый аят** | `trigger.sh` или `Mod+Ctrl+O` |
| **venv** | создаётся при установке в `$MR_DST/.venv` |

Ручной запуск для отладки:

```bash
~/.local/share/muslim-reminder/run.sh      # фон
~/.local/share/muslim-reminder/trigger.sh  # один аят
```

Старая копия на `~/Desktop/Muslim-reminder` репозиторием **не используется** — после миграции её можно удалить.

---

## Горячие клавиши

| Сочетание | Действие |
|-----------|----------|
| `Mod+T` | Терминал Ghostty |
| `Mod+D` | Лаунчер Noctalia |
| `Mod+L` | Блокировка экрана |
| `Mod+Ctrl+O` | Quran Reminder (случайный аят), если установлен MR |
| `Ctrl+Alt+Del` | Меню сессии Noctalia |
| `Mod+Shift+/` | Оверлей горячих клавиш niri |

Полный список — в `dotfiles/niri/config.kdl` и [документации niri](https://niri-wm.github.io/niri/Configuration:-Introduction).

---

## После установки

Проверка конфига:

```bash
cd ~/.config/niri && niri validate -c config.kdl
```

Применение без перелогина (если niri уже запущен):

```bash
niri msg action load-config-file
# или перезапуск сессии / выход из niri
```

Убедитесь, что в `config.kdl` **нет** оставшихся `__NOCTALIA_PATH__` / `__MR_DST__` — только реальные пути.

---

## Права доступа

Если `~/.config/niri` создан от **root**, установка завершится с ошибкой записи. Исправление:

```bash
sudo chown -R "$(id -un):$(id -gn)" ~/.config/niri ~/.local/share
```

Затем снова запустите `./install-arch.sh`.

---

## Устранение неполадок

| Симптом | Решение |
|---------|---------|
| `Permission denied` при установке | См. [Права доступа](#права-доступа). |
| `niri validate` падает | Запускайте из каталога конфига: `cd ~/.config/niri`. |
| Два автозапуска MR / два `Mod+Ctrl+O` | Переустановите: `./install-arch.sh` (скрипт перезаписывает конфиг целиком). |
| В конфиге остались `__MR_DST__` | Запустите `install-arch.sh` заново с `NIRI_INSTALL_MR=1`. |
| Нет панели / лаунчера | Проверьте `NOCTALIA_PATH` и пакет `quickshell`; каталог Noctalia должен существовать. |
| Нет звука / яркости | `wireplumber`, `wpctl`; `brightnessctl`. |
| MR не стартует | Запустите `~/.local/share/muslim-reminder/run.sh` в терминале; нужна сеть для API Quran. |
| Старый путь `~/Desktop/Muslim-reminder` | Удалите старую копию; актуальный путь — `~/.local/share/muslim-reminder`. |

---

<div align="center">

[Configuration: Introduction](https://niri-wm.github.io/niri/Configuration:-Introduction)

</div>
