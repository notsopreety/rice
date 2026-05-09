#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/config.json"

if [[ ! -f "$CONFIG" ]]; then
    echo "❌ Config not found: $CONFIG"
    exit 1
fi

wallpaper_path=$(jq -r '.wallpaper_path // empty' "$CONFIG")
cache_path=$(jq -r '.cache_path // empty' "$CONFIG")
cache_batch_size=$(jq -r '.cache_batch_size // 4' "$CONFIG")

if [[ -z "$wallpaper_path" || -z "$cache_path" ]]; then
    echo "❌ Invalid config: missing wallpaper_path or cache_path"
    exit 1
fi

# Thumbnail tuning (you can tweak these)
THUMB_SIZE=400        # max width/height
QUALITY=65            # lower = smaller + faster
JPEG_QUALITY=60
WEBP_QUALITY=55

mkdir -p "$cache_path"

echo "Wallpaper path: $wallpaper_path"
echo "Cache path: $cache_path"
echo "Thumbnail size: ${THUMB_SIZE}px"
echo "Quality: $QUALITY"
echo "Batch size: $cache_batch_size"

find "$wallpaper_path" -type f \( \
    -iname "*.jpg" -o \
    -iname "*.jpeg" -o \
    -iname "*.png" -o \
    -iname "*.webp" \
\) -print0 | while IFS= read -r -d '' img; do

    filename=$(basename "$img")
    ext="${filename##*.}"
    name="${filename%.*}"
    out="$cache_path/$name.webp"

    # skip if exists
    if [[ -f "$out" ]]; then
        continue
    fi

    echo "Processing: $filename"

    magick "$img" \
        -auto-orient \
        -strip \
        -resize "${THUMB_SIZE}x${THUMB_SIZE}>" \
        -quality "$QUALITY" \
        -define webp:method=6 \
        -define webp:lossless=false \
        "$out" &

    # batch limit
    if (( cache_batch_size > 0 )); then
        while (( $(jobs -rp | wc -l) >= cache_batch_size )); do
            wait -n
        done
    fi

done

wait

echo "✅ Thumbnail cache generation complete."