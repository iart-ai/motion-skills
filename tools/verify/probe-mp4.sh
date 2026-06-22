#!/usr/bin/env bash
# probe-mp4.sh — print + assert an MP4's real spec (the deliverable contract).
#
# Renders lie; the file doesn't. This reads resolution / codec / fps / duration straight from the
# encoded MP4 and (optionally) asserts them, so "1080x1920 @30 h264" is verified, not assumed.
#
# Usage:
#   scripts/probe-mp4.sh out.mp4                 # just print the spec
#   scripts/probe-mp4.sh out.mp4 1080x1920 30    # assert vertical 1080x1920 @ ~30fps
# Needs: ffprobe (ships with ffmpeg).
set -euo pipefail
mp4="${1:?usage: probe-mp4.sh <file.mp4> [WxH] [fps]}"
exp_res="${2:-}"; exp_fps="${3:-}"
q(){ ffprobe -v error -select_streams v:0 -show_entries "$1" -of csv=p=0 "$mp4" | head -1; }
w=$(q stream=width); h=$(q stream=height); codec=$(q stream=codec_name)
rate=$(q stream=r_frame_rate); dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$mp4")
fps=$(awk -v r="$rate" 'BEGIN{split(r,a,"/"); printf "%.4g", (a[2]+0)?a[1]/a[2]:a[1]}')
printf '  %s: %sx%s  %s  %s fps  %.2fs\n' "$(basename "$mp4")" "$w" "$h" "$codec" "$fps" "${dur:-0}"
fail=0
if [ -n "$exp_res" ] && [ "${w}x${h}" != "$exp_res" ]; then echo "  ✗ resolution ${w}x${h} ≠ $exp_res"; fail=1; fi
if [ -n "$exp_fps" ] && ! awk -v a="$fps" -v b="$exp_fps" 'BEGIN{d=a-b; exit !(d<0.5 && d>-0.5)}'; then
  echo "  ✗ fps $fps ≠ $exp_fps"; fail=1; fi
[ "$codec" = h264 ] || echo "  ⚠ codec $codec (not h264 — confirm player/platform compatibility)"
if [ "$fail" -eq 0 ]; then echo "  ✓ spec OK"; else exit 1; fi
