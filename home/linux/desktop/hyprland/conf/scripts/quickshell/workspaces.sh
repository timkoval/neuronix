#!/usr/bin/env bash

# ============================================================================
# Hyprland workspace monitor for QuickShell
# ============================================================================

# 1. ZOMBIE PREVENTION — kill old instances AND their children
for pid in $(pgrep -f "quickshell/workspaces.sh"); do
    if [ "$pid" != "$$" ] && [ "$pid" != "$PPID" ]; then
        pkill -P "$pid" 2>/dev/null
        kill -9 "$pid" 2>/dev/null
    fi
done

# Kill orphaned socat processes from previous runs
pkill -f "socat -u UNIX-CONNECT.*hypr.*socket2" 2>/dev/null

FIFO="/tmp/qs_workspace_fifo_$$"
mkfifo "$FIFO" 2>/dev/null

cleanup() {
    [ -n "$SOCAT_PID" ] && kill "$SOCAT_PID" 2>/dev/null
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
    spaces=$(timeout 2 hyprctl workspaces -j 2>/dev/null)
    active=$(timeout 2 hyprctl activeworkspace -j 2>/dev/null | jq '.id')
    if [ -z "$spaces" ] || [ -z "$active" ]; then return; fi

    echo "$spaces" | jq --unbuffered --argjson a "$active" --arg end "$SEQ_END" -c '
        (map( { (.id|tostring): . } ) | add) as $s
        |
        [range(1; ($end|tonumber) + 1)] | map(
            . as $i |
            (if $i == $a then "active"
             elif ($s[$i|tostring] != null and $s[$i|tostring].windows > 0) then "occupied"
             else "empty" end) as $state |
            (if $s[$i|tostring] != null then $s[$i|tostring].lastwindowtitle else "Empty" end) as $win |
            { id: $i, state: $state, tooltip: $win }
        )
    ' > /tmp/qs_workspaces.tmp

    mv /tmp/qs_workspaces.tmp /tmp/qs_workspaces.json
}

# Print initial state
print_workspaces

# ============================================================================
# 2. EVENT LISTENER — trackable PID via FIFO
# ============================================================================
while true; do
    socat -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - > "$FIFO" 2>/dev/null &
    SOCAT_PID=$!

    while read -r line; do
        case "$line" in
            workspace*|focusedmon*|activewindow*|createwindow*|closewindow*|movewindow*|destroyworkspace*)
                while read -t 0.05 -r _extra; do
                    continue
                done
                print_workspaces
                ;;
        esac
    done < "$FIFO"

    # socat died (Hyprland restart?), clean up and retry
    kill "$SOCAT_PID" 2>/dev/null
    sleep 1
done
