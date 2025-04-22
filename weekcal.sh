#!/usr/bin/env bash
set -euo pipefail
shopt -s extglob

DATA_FILE="${WEEKCAL_DATA:-$HOME/.weekcal/events.csv}"
mkdir -p "$(dirname "$DATA_FILE")"
[[ -f "$DATA_FILE" ]] || touch "$DATA_FILE"

WIDTH=18
SEP="|"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--add DATE TIME "TITLE"] [--week DATE]
  --add   Add new event (DATE=YYYY-MM-DD, TIME=HH:MM 24‑hour)
  --week  Show week containing DATE (defaults to today)
  --list  Dump raw events
  --help  Show this help
Environment:
  WEEKCAL_DATA  Override default data file ($DATA_FILE)
EOF
  exit 0
}

error() { echo "Error: $*" >&2; exit 1; }

add_event() {
  local d="$1" t="$2" title="$3"
  date -d "$d $t" >/dev/null 2>&1 || error "Invalid date/time"
  echo "$d,$t,$title" >>"$DATA_FILE"
}

declare -A EVENTS
load_events() {
  while IFS="," read -r d t title; do
    [[ -z "$d" || -z "$t" ]] && continue
    local h=${t%%:*}
    EVENTS["${d}_${h}"]="$title"
  done <"$DATA_FILE"
}

week_start() {
  local d="$1"; date -d "$d -$(( $(date -d "$d" +%u) - 1 )) days" +%F
}

print_line() {
  printf "%${#1}s" "" | tr ' ' "$1"; printf "\n"
}

show_week() {
  local refdate="$1"
  local start=$(week_start "$refdate")
  local -a days
  for i in {0..6}; do days[$i]=$(date -d "$start +$i day" +%F); done

  printf "%${WIDTH}s" ""
  for d in "${days[@]}"; do printf "%s% -${WIDTH}s" "$SEP" "$(date -d "$d" +%a\ %d)"; done
  printf "\n"; print_line "-" $(( (WIDTH+1)*8 ))

  for h in {0..23}; do
    printf "%02d:00" "$h" | awk -v w=$WIDTH '{printf "% -"w"s", $0}'
    for d in "${days[@]}"; do
      key="${d}_${h}"
      cell="${EVENTS[$key]:-}"
      [[ ${#cell} -gt $WIDTH ]] && cell="${cell:0:WIDTH-1}…"
      printf "%s% -${WIDTH}s" "$SEP" "$cell"
    done
    printf "\n"
  done
}

[[ $# -eq 0 ]] && set -- --week "today"

case "$1" in
  --add)
    [[ $# -lt 4 ]] && error "--add requires DATE TIME \"TITLE\""
    add_event "$2" "$3" "$4"; exit 0;;
  --week)
    REFDATE="${2:-today}";
    load_events; show_week "$REFDATE"; exit 0;;
  --list)
    cat "$DATA_FILE"; exit 0;;
  --help|-h)
    usage;;
  *)
    error "Unknown opti
    on $1";;
esac
