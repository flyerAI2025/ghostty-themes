#!/usr/bin/env zsh

set -euo pipefail

# Functional regression only. This script does not generate demo.gif.

readonly REPO_DIR="${0:A:h:h}"
readonly SCRIPT="$REPO_DIR/ghostty-themes"

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/ghostty-themes-test.XXXXXX")"
trap 'rm -rf "$tmp_root"' EXIT

export HOME="$tmp_root/home"
export GHOSTTY_RESOURCES_DIR=""
mkdir -p "$HOME/.local/bin" \
         "$HOME/Library/Application Support/com.mitchellh.ghostty/themes"

fakebin="$tmp_root/fakebin"
mkdir -p "$fakebin"
export PATH="$fakebin:$PATH"

cat > "$fakebin/ghostty" <<'EOF'
#!/usr/bin/env zsh
set -euo pipefail
if [[ "${1:-}" == "+list-themes" ]]; then
  cat <<'THEMES'
Aardvark Blue
Ayu
Ayu Light
Ayu Mirage
Solarized Dark Higher Contrast
THEMES
  exit 0
fi
print -u2 "unexpected ghostty invocation: $*"
exit 1
EOF
chmod +x "$fakebin/ghostty"

cat > "$fakebin/osascript" <<'EOF'
#!/usr/bin/env zsh
set -euo pipefail
print true
EOF
chmod +x "$fakebin/osascript"

cat > "$fakebin/fzf" <<'EOF'
#!/usr/bin/env zsh
set -euo pipefail

if [[ "${1:-}" == "--version" ]]; then
  print "0.44"
  exit 0
fi

filter=""
while (( $# )); do
  case "$1" in
    --filter=*)
      filter="${1#--filter=}"
      ;;
    --filter)
      shift
      filter="${1:-}"
      ;;
  esac
  shift || true
done

if [[ -z "$filter" ]]; then
  cat
  exit 0
fi

filter="${filter:l}"
while IFS= read -r line; do
  plain="$(print -r -- "$line" | perl -pe 's/\e\[[0-9;]*m//g')"
  [[ "${plain:l}" == *"$filter"* ]] && print -r -- "$line"
done
EOF
chmod +x "$fakebin/fzf"

theme_dir="$HOME/Library/Application Support/com.mitchellh.ghostty/themes"
for theme in \
  "Aardvark Blue" \
  "Ayu" \
  "Ayu Light" \
  "Ayu Mirage" \
  "Solarized Dark Higher Contrast"; do
  case "$theme" in
    "Aardvark Blue"|"Ayu Light")
      background="#f5f7fb"
      foreground="#202631"
      cursor_color="#3a7afe"
      cursor_text="#f5f7fb"
      selection_background="#d9e6ff"
      selection_foreground="#202631"
      ;;
    *)
      background="#0f1115"
      foreground="#d4d7dd"
      cursor_color="#ffd866"
      cursor_text="#0f1115"
      selection_background="#3b4252"
      selection_foreground="#eceff4"
      ;;
  esac
  cat > "$theme_dir/$theme" <<EOF
background = $background
foreground = $foreground
cursor-color = $cursor_color
cursor-text = $cursor_text
selection-background = $selection_background
selection-foreground = $selection_foreground
palette = 0=#101216
palette = 1=#ff5f56
palette = 2=#69b36d
palette = 3=#f6d365
palette = 4=#61afef
palette = 5=#c678dd
palette = 6=#56b6c2
palette = 7=#d4d7dd
palette = 8=#4b5263
palette = 9=#ff7a72
palette = 10=#8ccf7e
palette = 11=#ffe082
palette = 12=#7dcfff
palette = 13=#d2a6ff
palette = 14=#7fdbca
palette = 15=#f5f7fa
EOF
done

strip_ansi() {
  perl -pe 's/\e\[[0-9;]*m//g'
}

assert_eq() {
  local expected="$1" actual="$2" label="$3"
  if [[ "$expected" != "$actual" ]]; then
    print -u2 "FAIL: $label"
    print -u2 "expected: <$expected>"
    print -u2 "actual:   <$actual>"
    exit 1
  fi
}

assert_match() {
  local pattern="$1" actual="$2" label="$3"
  if [[ ! "$actual" =~ $pattern ]]; then
    print -u2 "FAIL: $label"
    print -u2 "pattern: <$pattern>"
    print -u2 "actual:  <$actual>"
    exit 1
  fi
}

reset_lists() {
  rm -f \
    "$HOME/Library/Application Support/com.mitchellh.ghostty/theme-favorites" \
    "$HOME/Library/Application Support/com.mitchellh.ghostty/theme-skipped" \
    "$HOME/Library/Application Support/com.mitchellh.ghostty/theme-usage"
}

combined_pairs() {
  "$SCRIPT" --list-combined | strip_ansi | awk -F '\t' '{print $1 "|" $2}'
}

reset_lists
"$SCRIPT" --save "Ayu Mirage"
"$SCRIPT" --save "Aardvark Blue"
"$SCRIPT" --skip "Solarized Dark Higher Contrast"
"$SCRIPT" --skip "Ayu Light"

combined_output="$(combined_pairs)"
assert_eq $'saved|Aardvark Blue\nsaved|Ayu Mirage\nbrowse|Ayu\nskip|Ayu Light\nskip|Solarized Dark Higher Contrast' \
  "$combined_output" \
  "combined list should group and alphabetize saved/browse/skipped lanes"

save_transform="$("$SCRIPT" --toggle-mark save 3 "Ayu")"
assert_match '^reload\(.*ghostty-themes'"'"' --list-combined\)\+pos\(4\)\+refresh-preview$' \
  "$save_transform" \
  "saving from browse should advance to the next unmarked row"
config_file="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
assert_eq 'theme = Ayu Light' "$(grep '^theme *= ' "$config_file")" \
  "saving should apply the theme at the new cursor position after reorder"

reset_lists
"$SCRIPT" --save "Aardvark Blue"
"$SCRIPT" --skip "Solarized Dark Higher Contrast"
skip_transform="$("$SCRIPT" --toggle-mark skip 2 "Ayu")"
assert_match '^reload\(.*ghostty-themes'"'"' --list-combined\)\+pos\(2\)\+refresh-preview$' \
  "$skip_transform" \
  "skipping from browse should keep the cursor position stable"
assert_eq 'theme = Ayu Light' "$(grep '^theme *= ' "$config_file")" \
  "skipping should apply the next visible theme immediately after reorder"

reset_lists
query_skip_transform="$(FZF_QUERY='ayu' "$SCRIPT" --toggle-mark skip 1 "Ayu")"
assert_match '^reload\(.*ghostty-themes'"'"' --list-combined\)\+pos\(1\)\+refresh-preview$' \
  "$query_skip_transform" \
  "skipping from a filtered list should preserve the visible cursor position"
assert_eq 'theme = Ayu Light' "$(grep '^theme *= ' "$config_file")" \
  "skipping inside a filtered list should apply the next filtered theme"

"$SCRIPT" --apply "Ayu Light"
assert_eq 'theme = Ayu Light' "$(grep '^theme *= ' "$config_file")" \
  "apply should write the selected theme into config"

literal_theme='Slash\nLiteral'
"$SCRIPT" --apply "$literal_theme"
assert_eq "theme = $literal_theme" "$(grep '^theme *= ' "$config_file")" \
  "apply should preserve literal backslashes in theme names"

"$SCRIPT" --apply ""
if grep -q '^theme *=' "$config_file" 2>/dev/null; then
  print -u2 "FAIL: apply with empty theme should remove theme line"
  exit 1
fi

reset_lists
blocked_config="$tmp_root/blocked-config"
mkdir -p "$blocked_config"
if GHOSTTY_CONFIG="$blocked_config" "$SCRIPT" --apply "Ayu Light" >"$tmp_root/blocked.stdout" 2>"$tmp_root/blocked.stderr"; then
  print -u2 "FAIL: apply with an unwritable config path should exit non-zero"
  exit 1
fi
if [[ -f "$HOME/Library/Application Support/com.mitchellh.ghostty/theme-usage" ]]; then
  print -u2 "FAIL: failed apply should not create usage history"
  exit 1
fi

reset_lists
"$SCRIPT" --save "Ayu Light"
"$SCRIPT" --save "Ayu Mirage"
"$SCRIPT" --apply "Ayu Mirage"
assert_eq 'theme = Ayu Mirage' "$(grep '^theme *= ' "$config_file")" \
  "saved apply should stay explicit until both light and dark saved themes have usage history"
"$SCRIPT" --apply "Ayu Light"
assert_eq 'theme = light:Ayu Light,dark:Ayu Mirage' "$(grep '^theme *= ' "$config_file")" \
  "saved apply should automatically switch to Ghostty's native light/dark pair once both saved appearances have usage history"
usage_before_preview="$(cat "$HOME/Library/Application Support/com.mitchellh.ghostty/theme-usage")"
"$SCRIPT" --apply-preview "Ayu"
assert_eq 'theme = Ayu' "$(grep '^theme *= ' "$config_file")" \
  "apply-preview should still write the explicitly previewed theme"
assert_eq "$usage_before_preview" "$(cat "$HOME/Library/Application Support/com.mitchellh.ghostty/theme-usage")" \
  "apply-preview should not record usage or auto-enable system appearance switching"
"$SCRIPT" --apply "Ayu"
assert_eq 'theme = Ayu' "$(grep '^theme *= ' "$config_file")" \
  "unsaved apply should remain explicit even when auto-switch candidates exist"

reset_lists
"$SCRIPT" --save "Ayu Mirage"
"$SCRIPT" --save "Solarized Dark Higher Contrast"
"$SCRIPT" --apply "Ayu Mirage"
assert_eq 'theme = Ayu Mirage' "$(grep '^theme *= ' "$config_file")" \
  "all-dark saved themes should not auto-enable system appearance switching"
"$SCRIPT" --apply "Solarized Dark Higher Contrast"
assert_eq 'theme = Solarized Dark Higher Contrast' "$(grep '^theme *= ' "$config_file")" \
  "saved apply should stay explicit when there is still no saved light candidate"

reset_lists
"$SCRIPT" --save "Aardvark Blue"
"$SCRIPT" --save "Ayu Light"
"$SCRIPT" --save "Ayu Mirage"
"$SCRIPT" --save "Solarized Dark Higher Contrast"
"$SCRIPT" --apply "Ayu Light"
"$SCRIPT" --apply "Aardvark Blue"
"$SCRIPT" --apply "Aardvark Blue"
"$SCRIPT" --apply "Solarized Dark Higher Contrast"
"$SCRIPT" --apply "Ayu Mirage"
"$SCRIPT" --apply "Ayu Mirage"
"$SCRIPT" --apply "Ayu Mirage"
"$SCRIPT" --apply-auto
assert_eq 'theme = light:Aardvark Blue,dark:Ayu Mirage' "$(grep '^theme *= ' "$config_file")" \
  "apply-auto should write Ghostty's native light/dark pair from the top saved usage picks"

reset_lists
"$SCRIPT" --save "Ayu Mirage"
"$SCRIPT" --save "Solarized Dark Higher Contrast"
"$SCRIPT" --apply "Ayu Mirage"
"$SCRIPT" --apply "Ayu Mirage"
auto_stdout="$tmp_root/auto-theme.stdout"
auto_stderr="$tmp_root/auto-theme.stderr"
if "$SCRIPT" --apply-auto >"$auto_stdout" 2>"$auto_stderr"; then
  print -u2 "FAIL: apply-auto without a saved light theme should exit non-zero"
  exit 1
fi
assert_eq 'theme = Ayu Mirage' "$(grep '^theme *= ' "$config_file")" \
  "apply-auto should leave config unchanged when the saved auto-switch conditions are incomplete"
assert_eq 'Auto theme unavailable: no saved light theme with usage history' "$(cat "$auto_stderr")" \
  "apply-auto should explain why it skipped the config update"
assert_eq '' "$(cat "$auto_stdout")" \
  "apply-auto should stay quiet on stdout when it cannot update config"

preview_output="$(NO_COLOR=1 "$SCRIPT" --preview "Ayu")"
assert_match $'\033\\[(38|48);2;' "$preview_output" \
  "preview should still emit truecolor ANSI when NO_COLOR=1"

preview_text="$(print -r -- "$preview_output" | strip_ansi)"
assert_match 'ghostty • main \[\+\] • v0\.13 • impure • 10:36 →' "$preview_text" \
  "preview should keep the compact one-line prompt"
assert_match '↑/↓ browse  •  type filter' "$preview_text" \
  "preview should show arrow-key guidance in the footer"

missing_stdout="$tmp_root/missing-preview.stdout"
missing_stderr="$tmp_root/missing-preview.stderr"
if "$SCRIPT" --preview "Does Not Exist" >"$missing_stdout" 2>"$missing_stderr"; then
  print -u2 "FAIL: preview for missing theme should exit non-zero"
  exit 1
fi
assert_eq '' "$(cat "$missing_stdout")" \
  "missing theme preview should not write to stdout"
assert_eq 'Theme not found: Does Not Exist' "$(cat "$missing_stderr")" \
  "missing theme preview should write the error to stderr"

demo_work="$(DEMO_WORK_DIR="$tmp_root/demo-work" zsh "$REPO_DIR/tools/demo/prepare-env.zsh")"
demo_config="$demo_work/home/Library/Application Support/com.mitchellh.ghostty/config"
assert_eq "working-directory = $REPO_DIR" "$(grep '^working-directory *= ' "$demo_config")" \
  "prepare-env should expand ROOT_DIR in the demo Ghostty config"

print "smoke ok"
