#!/usr/bin/env bash

# Check for system updates (Arch Linux)
# Shows count of available updates from pacman, yay/AUR, and flatpak

total_updates=0
pacman_updates=0
aur_updates=0
flatpak_updates=0

# Check pacman updates
if command -v checkupdates &> /dev/null; then
    pacman_updates=$(checkupdates 2>/dev/null | wc -l)
    total_updates=$((total_updates + pacman_updates))
fi

# Check yay/AUR updates
if command -v yay &> /dev/null; then
    aur_updates=$(yay -Qu 2>/dev/null | wc -l)
    total_updates=$((total_updates + aur_updates))
fi

# Check flatpak updates
if command -v flatpak &> /dev/null; then
    flatpak_updates=$(flatpak remote-ls --updates 2>/dev/null | wc -l)
    total_updates=$((total_updates + flatpak_updates))
fi

# Build tooltip with detailed breakdown
tooltip="Total updates: $total_updates\n"
tooltip+="Pacman: $pacman_updates\n"
tooltip+="AUR: $aur_updates\n"
tooltip+="Flatpak: $flatpak_updates"

if [ "$total_updates" -gt 0 ]; then
    echo "{\"text\": \"󰏔 $total_updates\", \"tooltip\": \"$tooltip\"}"
else
    echo "{\"text\": \"󰸞\", \"tooltip\": \"System up to date\"}"
fi
