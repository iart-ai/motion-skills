#!/usr/bin/env bash
# contact-sheet.sh — tile frames side-by-side into one image for one-glance inspection.
#
# The verify loop wants start | mid | end seen together (does the hook read? does the loop seam
# match? any clipped text?). One image beats flipping between three.
#
# Usage:
#   scripts/contact-sheet.sh sheet.png frame-0.png frame-1.5.png frame-3.png
# All inputs must share the same height (frames from the same render do). Needs: ffmpeg.
set -euo pipefail
out="${1:?usage: contact-sheet.sh <out.png> <frame.png> [frame.png ...]}"; shift
[ "$#" -ge 1 ] || { echo "need at least one frame"; exit 1; }
inputs=(); for f in "$@"; do inputs+=(-i "$f"); done
if [ "$#" -eq 1 ]; then cp "$1" "$out"; else
  ffmpeg -y "${inputs[@]}" -filter_complex "hstack=inputs=$#" "$out" -loglevel error
fi
echo "  ✓ contact sheet ($# frame(s)) → $out"
