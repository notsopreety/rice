#!/usr/bin/env bash

# Power menu script for Waybar
# Shows options when clicked

case "$1" in
    "lock")
        /home/sawmer/.config/scripts/lockscreen.sh
        ;;
    "logout")
        hyprctl dispatch exit
        ;;
    "reboot")
        reboot
        ;;
    "shutdown")
        poweroff
        ;;
    *)
        echo "󰐥"
        ;;
esac
