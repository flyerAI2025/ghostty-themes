#!/usr/bin/env zsh

set -euo pipefail

if (( $# != 1 )); then
  print -u2 "usage: $0 <window-id>"
  exit 1
fi

readonly WINDOW_ID="$1"
readonly HS_BIN="${HS_BIN:-/opt/homebrew/bin/hs}"

hs_eval() {
  "$HS_BIN" -c "$1" >/dev/null
}

focus_window() {
  hs_eval "local w=hs.window.get($WINDOW_ID); assert(w,'window missing'); w:focus()"
  sleep 0.6
}

type_text() {
  local text="$1"
  local char
  for char in ${(s::)text}; do
    hs_eval "hs.eventtap.keyStrokes([[$char]])"
    sleep 0.08
  done
}

press_key() {
  local mods_lua="$1" key="$2"
  hs_eval "hs.eventtap.keyStroke($mods_lua, '$key')"
}

pause() {
  sleep "$1"
}

focus_window

type_text "./ghostty-themes"
pause 2.4
press_key "{}" "return"
pause 1.5

type_text "git"
pause 1.7

press_key "{}" "down"
pause 1.1
press_key "{}" "down"
pause 1.1
press_key "{}" "down"
pause 1.4
press_key '{"ctrl"}' "f"
pause 1.9

press_key "{}" "down"
pause 1.1
press_key "{}" "down"
pause 1.1
press_key "{}" "down"
pause 1.4
press_key '{"ctrl"}' "f"
pause 1.9

press_key '{"ctrl"}' "d"
pause 1.9

for _ in {1..8}; do
  press_key "{}" "up"
  pause 0.95
done

pause 1.2
press_key "{}" "down"
pause 1.7
press_key "{}" "up"
pause 1.7
press_key "{}" "down"
pause 1.7
press_key "{}" "return"
pause 2.0
