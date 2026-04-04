#!/usr/bin/env zsh

set -euo pipefail

if (( $# != 3 )); then
  print -u2 "usage: $0 <frames-dir> <start-number> <frame-count>"
  exit 1
fi

readonly FRAMES_DIR="$1"
readonly START_NUMBER="$2"
readonly FRAME_COUNT="$3"
readonly ROOT_DIR="${0:A:h:h:h}"

ffmpeg -y \
  -framerate 3 \
  -start_number "$START_NUMBER" \
  -i "$FRAMES_DIR/frame-%04d.png" \
  -vframes "$FRAME_COUNT" \
  -vf "scale=800:655:flags=lanczos,split[s0][s1];[s0]palettegen=stats_mode=full[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3" \
  "$ROOT_DIR/demo.gif" >/dev/null 2>&1

gifsicle -O3 --colors 256 "$ROOT_DIR/demo.gif" -o "$ROOT_DIR/demo.gif"
