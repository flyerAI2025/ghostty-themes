#!/usr/bin/env zsh

set -euo pipefail

readonly ROOT_DIR="${0:A:h:h:h}"
readonly HS_BIN="${HS_BIN:-/opt/homebrew/bin/hs}"
readonly GHOSTTY_APP="${GHOSTTY_APP:-Ghostty.app}"
readonly WINDOW_TITLE="${DEMO_WINDOW_TITLE:-ghostty-themes demo}"
readonly SCREEN_ID="${DEMO_SCREEN_ID:-}"
readonly WINDOW_WIDTH="${DEMO_WINDOW_WIDTH:-800}"
readonly WINDOW_HEIGHT="${DEMO_WINDOW_HEIGHT:-655}"

hs_eval() {
  "$HS_BIN" -c "$1"
}

close_existing_demo_windows() {
  hs_eval "
    for _, w in ipairs(hs.window.orderedWindows()) do
      local app = w:application()
      if app and app:name() == 'Ghostty' and w:title() == '$WINDOW_TITLE' then
        w:close()
      end
    end
  " >/dev/null

  local remaining=""
  for _ in {1..40}; do
    remaining="$(
      hs_eval "
        local ids = {}
        for _, w in ipairs(hs.window.orderedWindows()) do
          local app = w:application()
          if app and app:name() == 'Ghostty' and w:title() == '$WINDOW_TITLE' then
            table.insert(ids, tostring(w:id()))
          end
        end
        print(table.concat(ids, '\n'))
      "
    )"
    [[ -z "$remaining" ]] && return 0
    sleep 0.1
  done

  print -u2 "demo window cleanup timed out"
  return 1
}

wait_for_demo_window() {
  local id=""
  for _ in {1..120}; do
    id="$(
      hs_eval "
        for _, w in ipairs(hs.window.orderedWindows()) do
          local app = w:application()
          if app and app:name() == 'Ghostty' and w:title() == '$WINDOW_TITLE' then
            print(w:id())
            return
          end
        end
      "
    )"
    [[ -n "$id" ]] && { print -r -- "$id"; return 0; }
    sleep 0.1
  done

  print -u2 "timed out waiting for demo Ghostty window"
  return 1
}

move_and_focus_window() {
  local window_id="$1"
  hs_eval "
    local w = hs.window.get($window_id)
    assert(w, 'window missing')
    local target = nil
    local wanted = [[$SCREEN_ID]]
    if wanted ~= '' then
      local wanted_id = tonumber(wanted)
      for _, s in ipairs(hs.screen.allScreens()) do
        if s:id() == wanted_id then
          target = s
          break
        end
      end
    else
      target = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
    end
    assert(target, 'screen missing')
    w:moveToScreen(target, false, true)
    local f = target:frame()
    w:setFrame({x = f.x + 40, y = f.y + 40, w = $WINDOW_WIDTH, h = $WINDOW_HEIGHT})
    w:focus()
  " >/dev/null
}

main() {
  local work_dir
  work_dir="$(DEMO_WORK_DIR="${DEMO_WORK_DIR:-$ROOT_DIR/.demo-work}" zsh "$ROOT_DIR/tools/demo/prepare-env.zsh")"

  close_existing_demo_windows

  open -na "$GHOSTTY_APP" --args --config-file="$work_dir/config" >/dev/null 2>&1

  local window_id
  window_id="$(wait_for_demo_window)"
  move_and_focus_window "$window_id"
  print -r -- "$window_id"
}

main "$@"
