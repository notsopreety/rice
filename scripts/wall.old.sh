#!/usr/bin/env bash

# SUPER LIGHTWEIGHT RICE SCRIPT
# Usage: wall.sh -i=<img|next|prev|rand> -a=<animation>

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CACHE_FILE="$HOME/.cache/awww-wal/current"
TRANSITIONS=("fade" "wipe" "grow" "center" "outer" "left" "right" "top" "bottom" "simple")

# Get all wallpapers in order
get_wallpapers() {
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | sort
}

# Get current wallpaper index
get_current_index() {
    local current_img=""
    [[ -f "$CACHE_FILE" ]] && current_img=$(cat "$CACHE_FILE")
    [[ -z "$current_img" ]] && current_img=$(get_wallpapers | head -1)
    
    local wallpapers=($(get_wallpapers))
    for i in "${!wallpapers[@]}"; do
        if [[ "${wallpapers[$i]}" == "$current_img" ]]; then
            echo "$i"
            return
        fi
    done
    echo "0"
}

# Get wallpaper by index
get_wallpaper_by_index() {
    local wallpapers=($(get_wallpapers))
    echo "${wallpapers[$1]}"
}

# Handle image argument
handle_image() {
    local arg="$1"
    
    if [[ -z "$arg" ]]; then
        # No arg, use current or random
        if [[ -f "$CACHE_FILE" ]]; then
            cat "$CACHE_FILE"
        else
            get_wallpapers | shuf -n1
        fi
    elif [[ "$arg" == "next" ]]; then
        local current=$(get_current_index)
        local total=$(get_wallpapers | wc -l)
        local next=$(( (current + 1) % total ))
        get_wallpaper_by_index "$next"
    elif [[ "$arg" == "prev" ]]; then
        local current=$(get_current_index)
        local total=$(get_wallpapers | wc -l)
        local prev=$(( (current - 1 + total) % total ))
        get_wallpaper_by_index "$prev"
    elif [[ "$arg" == "rand" || "$arg" == "random" ]]; then
        get_wallpapers | shuf -n1
    elif [[ -f "$arg" ]]; then
        echo "$arg"
    else
        echo "Error: Invalid image '$arg'" >&2
        exit 1
    fi
}

# Handle animation
handle_animation() {
    local anim="$1"
    
    if [[ -z "$anim" ]]; then
        # Random animation
        echo "${TRANSITIONS[RANDOM % ${#TRANSITIONS[@]}]}"
    else
        # Use specified animation if valid
        for t in "${TRANSITIONS[@]}"; do
            if [[ "$t" == "$anim" ]]; then
                echo "$anim"
                return
            fi
        done
        # Invalid animation, use random
        echo "${TRANSITIONS[RANDOM % ${#TRANSITIONS[@]}]}"
    fi
}

# Start daemon if needed
start_daemon() {
    pgrep -x "awww-daemon" > /dev/null || (awww-daemon > /dev/null 2>&1 & sleep 0.2)
}

# Apply wallpaper
apply_wallpaper() {
    local img="$1"
    local anim="$2"
    
    # Apply with animation
    awww img "$img" \
        --transition-type "$anim" \
        --transition-duration 1.5 \
        --transition-fps 60 \
        --transition-pos center > /dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        # Save current wallpaper
        mkdir -p "$(dirname "$CACHE_FILE")"
        echo "$img" > "$CACHE_FILE"
        
        # Copy current wallpaper to wall.jpg for Hyprlock
        cp "$img" "$(dirname "$CACHE_FILE")/wall.jpg"
        
        # Generate colorscheme
        wal -i "$img" -n -q > /dev/null 2>&1
        pkill dunst 
        cp ~/.cache/wal/dunstrc ~/.config/dunst/dunstrc
        
        # Reload Waybar to apply new colors
        pkill waybar && waybar &
        
        echo "✓ $anim: $(basename "$img")"
        return 0
    else
        echo "✗ Failed: $anim → $(basename "$img")" >&2
        return 1
    fi
}

# Show help
show_help() {
    cat << 'EOF'
Lightweight Wallpaper Changer for Hyprland

USAGE:
    wall.sh [OPTIONS]

OPTIONS:
    -i=<arg>    Image source: path/to/img.jpg | next | prev | rand
                (default: last used or random)
    
    -a=<anim>   Animation: simple | fade | wipe | grow | center | outer 
                left | right | top | bottom
                (default: random animation)

EXAMPLES:
    wall.sh                              # Last/Random wallpaper with random animation
    wall.sh -i=next                      # Next wallpaper with random animation
    wall.sh -i=prev -a=fade              # Previous wallpaper with fade
    wall.sh -i=rand -a=wipe              # Random wallpaper with wipe
    wall.sh -i=/path/to/img.jpg -a=grow  # Specific image with grow
    wall.sh -a=center                    # Last/Random image with center animation

NOTES:
    - Next/Prev based on alphabetical order in $WALLPAPER_DIR
    - Colorscheme automatically generated with pywal
    - Current wallpaper saved to $CACHE_FILE

TRANSITIONS:
    simple   - Simple fade
    fade     - Smooth fade  
    wipe     - Wipe across
    grow     - Grow from center
    center   - Expand from center
    outer    - Contract to center
    left     - Slide from left
    right    - Slide from right
    top      - Slide from top
    bottom   - Slide from bottom

EOF
}

# Main
main() {
    local img_arg=""
    local anim_arg=""
    
    # Parse arguments (supporting both -i=value and -i value)
    for arg in "$@"; do
        case "$arg" in
            -i=*) img_arg="${arg#-i=}" ;;
            -a=*) anim_arg="${arg#-a=}" ;;
            -i) shift; img_arg="$1"; shift ;;
            -a) shift; anim_arg="$1"; shift ;;
            -h|--help) show_help; exit 0 ;;
            *) 
                if [[ -z "$img_arg" ]]; then
                    img_arg="$arg"
                else
                    echo "Unknown: $arg" >&2
                    show_help
                    exit 1
                fi
                ;;
        esac
    done
    
    # Handle image and animation
    img=$(handle_image "$img_arg") || exit 1
    anim=$(handle_animation "$anim_arg")
    
    # Apply
    start_daemon
    apply_wallpaper "$img" "$anim"
}

main "$@"