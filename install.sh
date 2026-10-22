#!/bin/zsh
# install.sh — официальный установщик Bastwick Center с GitHub.
# Открытый исходник: читайте перед запуском — установка прозрачна.
#
# Установка одной командой:
#   curl -fsSL https://raw.githubusercontent.com/Hann2807/bastwick/main/install.sh | zsh
#
# Что делает: проверяет систему, скачивает релиз с проверкой md5,
# распаковывает в /Applications, снимает кворантин (браузерный ярлык
# Gatekeeper) и открывает приложение.
set -u

INSTALL_URL="${BASTWICK_URL:-https://github.com/Hann2807/bastwick/releases/download/v1.0.0/Bastwick-release.zip}"
INSTALL_MD5="${BASTWICK_MD5:-f1951cc8e8791da52523a107ba0d2b54}"
APP_DST="/Applications/Bastwick.app"
say() { printf '%s\n' "$*" >&2; }   # сообщения видны при запуске через pipe

say "Установка Bastwick Center…"

# ── проверка системы (вежливо, с объяснением) ───────────────────────────
if [ "$(uname -s)" != "Darwin" ]; then
  say "Bastwick Center — приложение для macOS. Установка отменена."
  exit 1
fi
osv=$(sw_vers -productVersion 2>/dev/null || echo 0)
case "$osv" in
  1[3-9].*|[2-9][0-9].*) : ;;
  *) say "Требуется macOS 13.0 или новее (у вас $osv). Установка отменена."
     exit 1 ;;
esac
# Виртуальные машины: сетевые расширения (VPN-туннель) в VM нестабильны —
# честно предупреждаем вместо молчаливого отказа.
if system_profiler SPHardwareDataType 2>/dev/null | grep -qiE 'VirtualMac|VMware|QEMU|VirtualBox|Parallels.*Virtual'; then
  say "Виртуальные машины не поддерживаются: VPN-туннель работает только на реальном Mac."
  exit 1
fi

# ── скачивание релиза с проверкой md5 ───────────────────────────────────
if [ -z "$INSTALL_URL" ] || [ "$INSTALL_URL" = "@@URL@@" ]; then
  say "Ссылка не настроена. Скачайте архив вручную со страницы Releases."
  exit 1
fi
TMP=$(mktemp -d) || { say "Нет временного каталога."; exit 1; }
trap 'rm -rf "$TMP"' EXIT

if ! curl -fsSL --max-time 180 -o "$TMP/b.zip" "$INSTALL_URL"; then
  say "Не удалось скачать архив — проверьте соединение и попробуйте снова."
  exit 1
fi
if [ -n "$INSTALL_MD5" ] && [ "$INSTALL_MD5" != "@@MD5@@" ]; then
  got=$(md5 -q "$TMP/b.zip" 2>/dev/null || echo "")
  if [ "$got" != "$INSTALL_MD5" ]; then
    say "Проверка md5 не пройдена (файл повреждён при скачивании)."
    say "Скачайте архив заново со страницы Releases и повторите."
    exit 1
  fi
fi

# ── установка ───────────────────────────────────────────────────────────
if ! ditto -x -k "$TMP/b.zip" "$TMP/x" 2>/dev/null; then
  say "Не удалось распаковать архив — скачайте его заново."
  exit 1
fi
SRC=$(find "$TMP/x" -maxdepth 2 -name '*.app' 2>/dev/null | head -1)
if [ -z "$SRC" ]; then
  say "В архиве не найдено приложение — скачайте его заново."
  exit 1
fi
xattr -dr com.apple.quarantine "$SRC" 2>/dev/null || true
rm -rf "$APP_DST"
if ! cp -R "$SRC" "$APP_DST" 2>/dev/null; then
  say "Не удалось установить в /Applications (права?). Перетащите Bastwick.app в «Программы» вручную."
  exit 1
fi
chmod -R a+rX "$APP_DST"
say "Готово: установлено в $APP_DST. Открываю…"
open "$APP_DST" >/dev/null 2>&1 &
exit 0
