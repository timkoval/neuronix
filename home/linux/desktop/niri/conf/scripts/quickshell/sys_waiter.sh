#!/usr/bin/env bash

# Debounce
sleep 0.1

# Track all spawned PIDs
CHILD_PIDS=()

cleanup() {
    for pid in "${CHILD_PIDS[@]}"; do
        # Kill entire process group started by setsid
        kill -- -"$pid" 2>/dev/null
        kill "$pid" 2>/dev/null
    done
}
trap cleanup EXIT SIGTERM SIGINT

# Helper: spawn a listener in its own process group via setsid
spawn() {
    setsid "$@" &
    CHILD_PIDS+=($!)
}

# 1. Pipewire Volume Waiter
if command -v pw-mon &>/dev/null; then
    spawn bash -c 'exec pw-mon 2>/dev/null | grep --line-buffered -E "changed|added|removed" | head -n 1'
else
    spawn bash -c 'exec pactl subscribe 2>/dev/null | grep --line-buffered -E "Event '\''change'\'' on sink" | head -n 1'
fi

# 2. D-Bus Music Waiter
spawn bash -c 'exec dbus-monitor --session "type='\''signal'\'',interface='\''org.freedesktop.DBus.Properties'\'',path_namespace='\''/org/mpris/MediaPlayer2'\''" 2>/dev/null | grep --line-buffered "string" | head -n 1'

# 3. Network
spawn bash -c 'exec nmcli monitor 2>/dev/null | grep --line-buffered -E "connected|disconnected|unavailable|enabled|disabled" | head -n 1'

# 4. Bluetooth
spawn bash -c 'exec dbus-monitor --system "type='\''signal'\'',interface='\''org.freedesktop.DBus.Properties'\'',member='\''PropertiesChanged'\'',arg0='\''org.bluez.Device1'\''" 2>/dev/null | grep --line-buffered "interface" | head -n 1'

# 5. Battery
spawn bash -c 'exec udevadm monitor --subsystem-match=power_supply 2>/dev/null | grep --line-buffered "change" | head -n 1'

# 6. Keyboard layout changes via Niri event stream
spawn bash -c 'exec niri msg --json event-stream 2>/dev/null | grep --line-buffered "KeyboardLayoutsChanged" | head -n 1'

# Failsafe: 60 second timeout
sleep 60 &
CHILD_PIDS+=($!)

# Wait for the first to complete
wait -n

echo "trigger"
