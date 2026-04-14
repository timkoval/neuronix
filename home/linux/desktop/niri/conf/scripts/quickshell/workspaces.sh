#!/usr/bin/env bash

# ============================================================================
# Niri workspace monitor for QuickShell
# ============================================================================

# 1. ZOMBIE PREVENTION — kill old instances AND their children
for pid in $(pgrep -f "quickshell/workspaces.sh"); do
    if [ "$pid" != "$$" ] && [ "$pid" != "$PPID" ]; then
        pkill -P "$pid" 2>/dev/null
        kill -9 "$pid" 2>/dev/null
    fi
done

# Kill orphaned event-stream processes from previous runs
pkill -f "niri msg --json event-stream" 2>/dev/null

FIFO="/tmp/qs_workspace_fifo_$$"
mkfifo "$FIFO" 2>/dev/null

cleanup() {
    [ -n "$STREAM_PID" ] && kill "$STREAM_PID" 2>/dev/null
    pkill -P $$ 2>/dev/null
    rm -f "$FIFO"
}
trap cleanup EXIT SIGTERM SIGINT

# --- Special Cleanup for Network/Bluetooth ---
BT_PID_FILE="$HOME/.cache/bt_scan_pid"
if [ -f "$BT_PID_FILE" ]; then
    kill "$(cat "$BT_PID_FILE")" 2>/dev/null
    rm -f "$BT_PID_FILE"
fi
(timeout 2 bluetoothctl scan off > /dev/null 2>&1)
# ---------------------------------------------

SEQ_END=8

print_workspaces() {
    spaces=$(timeout 2 niri msg -j workspaces 2>/dev/null)
    if [ -z "$spaces" ]; then return; fi

    echo "$spaces" | jq --unbuffered --arg end "$SEQ_END" -c '
        (map({ (.idx|tostring): . }) | add // {}) as $s
        |
        [range(1; ($end|tonumber) + 1)] | map(
            . as $i |
            (if ($s[$i|tostring] != null and $s[$i|tostring].is_focused) then "active"
             elif ($s[$i|tostring] != null and $s[$i|tostring].active_window_id != null) then "occupied"
             else "empty" end) as $state |
            {
                id: $i,
                state: $state,
                tooltip: (if $s[$i|tostring] != null then ($s[$i|tostring].name // "Workspace \($i)") else "Empty" end)
            }
        )
    ' > /tmp/qs_workspaces.tmp

    mv /tmp/qs_workspaces.tmp /tmp/qs_workspaces.json
}

# Print initial state
print_workspaces

# ============================================================================
# 2. EVENT LISTENER — trackable PID via FIFO
# ============================================================================
niri msg --json event-stream > "$FIFO" 2>/dev/null &
STREAM_PID=$!

while read -r event; do
    event_type=$(echo "$event" | jq -r 'keys[0] // empty' 2>/dev/null)
    case "$event_type" in
        WorkspacesChanged|WorkspaceActivated|WorkspaceActiveWindowChanged)
            # Debounce: discard events within 50ms window
            while read -t 0.05 -r _extra; do
                continue
            done
            print_workspaces
            ;;
    esac
done < "$FIFO"
