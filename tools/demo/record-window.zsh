#!/usr/bin/env zsh

set -euo pipefail

if (( $# != 2 )); then
  print -u2 "usage: $0 <window-id> <output-dir>"
  exit 1
fi

readonly WINDOW_ID="$1"
readonly OUTPUT_DIR="$2"

mkdir -p "$OUTPUT_DIR"

integer i=0
while [[ ! -f "$OUTPUT_DIR/.stop" ]]; do
  frame=$(printf '%s/frame-%04d.png' "$OUTPUT_DIR" "$i")
  screencapture -x -o -l "$WINDOW_ID" "$frame"
  i=$(( i + 1 ))
  sleep 0.20
done
