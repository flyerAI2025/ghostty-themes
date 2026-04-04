#!/usr/bin/env zsh

set -euo pipefail

readonly ROOT_DIR="${0:A:h:h:h}"
readonly WORK_DIR="${DEMO_WORK_DIR:-$ROOT_DIR/.demo-work}"
readonly DEMO_HOME="$WORK_DIR/home"
readonly DEMO_CONFIG="$WORK_DIR/config"
readonly GHOSTTY_DIR="$DEMO_HOME/Library/Application Support/com.mitchellh.ghostty"
readonly DEMO_ZDOTDIR="$WORK_DIR/zdotdir"

mkdir -p "$GHOSTTY_DIR"
mkdir -p "$DEMO_ZDOTDIR"
: > "$GHOSTTY_DIR/theme-favorites"
: > "$GHOSTTY_DIR/theme-skipped"

cat > "$DEMO_CONFIG" <<EOF
theme = Solarized Dark Higher Contrast
font-size = 13
window-padding-x = 8
window-padding-y = 8
window-save-state = never
working-directory = $ROOT_DIR
macos-titlebar-style = hidden
confirm-close-surface = false
title = ghostty-themes demo
shell-integration-features = cursor,no-sudo,no-ssh-env,no-ssh-terminfo,path
command = direct:env HOME=$DEMO_HOME GHOSTTY_CONFIG=$DEMO_CONFIG ZDOTDIR=$DEMO_ZDOTDIR /bin/zsh -i
EOF

cat > "$GHOSTTY_DIR/config" <<EOF
theme = Solarized Dark Higher Contrast
font-size = 13
window-padding-x = 8
window-padding-y = 8
working-directory = $ROOT_DIR
title = ghostty-themes demo
shell-integration-features = cursor,no-sudo,no-ssh-env,no-ssh-terminfo,path
EOF

cat > "$DEMO_ZDOTDIR/.zshrc" <<EOF
PROMPT='demo %% '
RPROMPT=''
precmd() { print -Pn '\\e]0;ghostty-themes demo\\a' }
preexec() { print -r -- "demo % \$1" }
print -Pn '\\e]0;ghostty-themes demo\\a'
cd '$ROOT_DIR'
clear
EOF

print -r -- "$WORK_DIR"
