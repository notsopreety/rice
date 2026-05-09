#!/usr/bin/env bash

# Media player script for Waybar
# Uses playerctl to control and display media info

player_status=$(playerctl status 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)
album=$(playerctl metadata album 2>/dev/null)

if [ "$player_status" = "Playing" ]; then
    icon="󰐊"
    status_text="Playing"
elif [ "$player_status" = "Paused" ]; then
    icon="󰏤"
    status_text="Paused"
else
    echo '{"text": "", "tooltip": "No media playing"}'
    exit 0
fi

# Format text for display
if [ -n "$title" ]; then
    display_text="$title"
else
    display_text="Media"
fi

# Truncate if too long
if [ ${#display_text} -gt 30 ]; then
    display_text="${display_text:0:27}..."
fi

# Create tooltip
tooltip="<b>$status_text</b>\n"
tooltip+="Artist: $artist\n"
tooltip+="Title: $title\n"
if [ -n "$album" ]; then
    tooltip+="Album: $album"
fi

echo "{\"text\": \"$icon $display_text\", \"tooltip\": \"$tooltip\"}"
