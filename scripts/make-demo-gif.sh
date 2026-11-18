#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/make-demo-gif.sh INPUT.mov OUTPUT.gif [options]

Options:
  --start SECONDS       Skip this much of the recording (default: 0)
  --duration SECONDS    Limit the clip; omit to use the rest of the recording
  --fps RATE            Output frame rate (default: 20)
  --width PIXELS        Output width, preserving the aspect ratio (default: 1200)
  --speed FACTOR        Playback speed (default: 1; 1.5 is 1.5x speed)
  -h, --help            Show this help

Example:
  scripts/make-demo-gif.sh demo.mov assets/ghostty-stylized-effects.gif \
    --start 5 --duration 20 --fps 20 --width 1200
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

is_number() {
  [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

if [[ $# -lt 2 ]]; then
  usage >&2
  exit 2
fi

input=$1
output=$2
shift 2

start=0
duration=
fps=20
width=1200
speed=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --start|--duration|--fps|--width|--speed)
      option=$1
      [[ $# -ge 2 ]] || fail "missing value for $option"
      value=$2
      shift 2
      case "$option" in
        --start) start=$value ;;
        --duration) duration=$value ;;
        --fps) fps=$value ;;
        --width) width=$value ;;
        --speed) speed=$value ;;
      esac
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

[[ -f "$input" ]] || fail "input file not found: $input"
command -v ffmpeg >/dev/null 2>&1 || fail "ffmpeg is required; install it from https://ffmpeg.org/"

is_number "$start" || fail "start must be a non-negative number"
is_number "$fps" && awk -v n="$fps" 'BEGIN { exit !(n > 0 && n <= 60) }' || fail "fps must be greater than 0 and at most 60"
is_number "$width" && awk -v n="$width" 'BEGIN { exit !(n >= 200 && n <= 4000 && n == int(n)) }' || fail "width must be a whole number from 200 to 4000"
is_number "$speed" && awk -v n="$speed" 'BEGIN { exit !(n > 0 && n <= 4) }' || fail "speed must be greater than 0 and at most 4"
if [[ -n "$duration" ]]; then
  is_number "$duration" && awk -v n="$duration" 'BEGIN { exit !(n > 0) }' || fail "duration must be greater than 0"
fi

mkdir -p "$(dirname "$output")"

filter="[0:v]setpts=PTS/${speed},fps=${fps},scale=${width}:-1:flags=lanczos,split[frames][palette_source];[palette_source]palettegen=stats_mode=diff[palette];[frames][palette]paletteuse=dither=bayer:bayer_scale=3"
args=(-nostdin -n -hide_banner -ss "$start")
if [[ -n "$duration" ]]; then
  args+=(-t "$duration")
fi
args+=(-i "$input" -filter_complex "$filter" -loop 0 "$output")

ffmpeg "${args[@]}"
printf 'Created %s\n' "$output"
