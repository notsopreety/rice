#!/usr/bin/env bash

# Dunst notification script for Waybar
# Checks notification status and count using dunstctl

if ! command -v dunstctl &> /dev/null; then
    echo '{"text": "", "tooltip": "Dunst not running", "alt": "none"}'
    exit 0
fi

# Check if dunst is paused
paused=$(dunstctl is-paused)

# Get waiting notification count
count=$(dunstctl count waiting)

# Get displayed notification count
displayed=$(dunstctl count displayed)

# Total notifications
total=$((count + displayed))

# Determine icon and state
if [ "$paused" = "true" ]; then
    if [ "$total" -gt 0 ]; then
        icon="dnd-notification"
        tooltip="Do Not Disturb (paused)\n$total notifications ($count waiting, $displayed displayed)"
    else
        icon="dnd-none"
        tooltip="Do Not Disturb (paused)\nNo notifications"
    fi
else
    if [ "$total" -gt 0 ]; then
        icon="notification"
        tooltip="$total notifications ($count waiting, $displayed displayed)"
    else
        icon="none"
        tooltip="No notifications"
    fi
fi

# Show count if > 0, otherwise show icon only
if [ "$total" -gt 0 ]; then
    echo "{\"text\": \"$total\", \"tooltip\": \"$tooltip\", \"alt\": \"$icon\"}"
else
    echo "{\"text\": \"\", \"tooltip\": \"$tooltip\", \"alt\": \"$icon\"}"
fi
