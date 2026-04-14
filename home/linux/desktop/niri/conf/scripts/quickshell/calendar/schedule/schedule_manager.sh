#!/bin/bash

CACHE_DIR="$HOME/.cache/quickshell/schedule"
CACHE_FILE="${CACHE_DIR}/schedule.json"
CACHE_LIMIT=600 # 10 minutes

UPDATER_SCRIPT="$HOME/.config/niri/scripts/quickshell/calendar/outlook_calendar.py"
SHELL_NIX="$HOME/.config/niri/scripts/quickshell/calendar/schedule/shell.nix"

mkdir -p "$CACHE_DIR"

trigger_update() {
    if pgrep -f "python3.*outlook_calendar.py" > /dev/null; then
        return
    fi

    nix-shell "$SHELL_NIX" --run "python3 '$UPDATER_SCRIPT'" > "$CACHE_FILE" 2>/dev/null &
}

if [ -f "$CACHE_FILE" ]; then
    cat "$CACHE_FILE"

    current_time=$(date +%s)
    file_time=$(stat -c %Y "$CACHE_FILE")
    age=$((current_time - file_time))

    if [ "$age" -gt "$CACHE_LIMIT" ]; then
        trigger_update
    fi
else
    echo '{ "header": "Loading...", "lessons": [], "link": "" }'
    trigger_update
fi
