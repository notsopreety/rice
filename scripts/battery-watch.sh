#!/usr/bin/env bash
# battery-listener.sh

BATTERY=$(upower -e | grep -E 'BAT|battery' | head -1)
NOTIFY_FILE='/tmp/battery/battery_notify_state'
CAP_FILE='/tmp/battery/battery_cap_prev'
mkdir -p /tmp/battery

emit() {
    local raw capacity status time time_raw val unit h m mins charging icon
    local PREV_STATE PREV_CAP

    raw=$(upower -i "$BATTERY" 2>/dev/null)
    capacity=$(echo "$raw" | awk '/percentage:/{gsub(/%/,"",$2); print int($2)}')
    capacity=${capacity:-0}
    status=$(echo "$raw" | awk '/state:/{print $2}')

    time="---"
    time_raw=$(echo "$raw" | awk '/time to (empty|full):/{print $4, $5}')
    if [[ -n "$time_raw" ]]; then
        val=$(echo "$time_raw" | awk '{print $1}')
        unit=$(echo "$time_raw" | awk '{print $2}')
        if [[ "$unit" == hours* ]]; then
            h=$(echo "$val" | awk '{print int($1)}')
            m=$(echo "$val" | awk '{printf "%d", ($1 - int($1)) * 60}')
            time=$(printf "%d:%02d" "$h" "$m")
        elif [[ "$unit" == minutes* ]]; then
            mins=$(echo "$val" | awk '{print int($1)}')
            time=$(printf "0:%02d" "$mins")
        fi
    fi

    charging=false
    [[ "$status" == "charging" || "$status" == "fully-charged" ]] && charging=true

    if $charging; then
        if   (( capacity >= 85 )); then icon="ABOVE85_CHG"
        elif (( capacity >= 70 )); then icon="HIGH_CHG"
        elif (( capacity >= 50 )); then icon="MED_CHG"
        elif (( capacity >= 40 )); then icon="HALF_CHG"
        elif (( capacity >= 20 )); then icon="BELOW_HALF_CHG"
        elif (( capacity >= 10 )); then icon="LOW_CHG"
        else                           icon="VERY_LOW_CHG"
        fi
    else
        if   [[ "$status" == "fully-charged" ]]; then icon="FULL"
        elif (( capacity >= 85 )); then icon="ABOVE85"
        elif (( capacity >= 70 )); then icon="HIGH"
        elif (( capacity >= 50 )); then icon="MED"
        elif (( capacity >= 40 )); then icon="HALF"
        elif (( capacity >= 20 )); then icon="BELOW_HALF"
        elif (( capacity >= 10 )); then icon="LOW"
        else                           icon="VERY_LOW"
        fi
    fi

    # Notifications
    PREV_STATE=$(cat "$NOTIFY_FILE" 2>/dev/null || echo 'NONE')
    PREV_CAP=$(cat "$CAP_FILE" 2>/dev/null || echo '0')
    echo "$capacity" > "$CAP_FILE"

    if [[ "$status" == "charging" || "$status" == "fully-charged" ]]; then
        rm -f /tmp/battery/battery_suspend_triggered
        if [[ "$capacity" -eq 100 && "$PREV_CAP" -lt 100 ]]; then
            notify-send 'Battery Full' 'Battery at 100% — Fully charged' &
            paplay ~/.config/sounds/battery-full.mp3 2>/dev/null &
            echo 'FULL' > "$NOTIFY_FILE"
        elif [[ "$capacity" -ge 80 && "$capacity" -lt 85 ]] && { [[ "$PREV_CAP" -lt 80 ]] || [[ "$PREV_STATE" != '80PCT' ]]; }; then
            notify-send 'Battery 80%' "Battery at ${capacity}% — Consider unplugging" &
            paplay ~/.config/sounds/battery-full.mp3 2>/dev/null &
            echo '80PCT' > "$NOTIFY_FILE"
        elif [[ "$PREV_STATE" != 'CHG' && "$PREV_STATE" != '80PCT' && "$PREV_STATE" != 'FULL' ]]; then
            notify-send 'Battery Charging' "Battery at ${capacity}% — Charging started" &
            paplay ~/.config/sounds/charging.mp3 2>/dev/null &
            echo 'CHG' > "$NOTIFY_FILE"
        fi
    else
        if [[ "$PREV_STATE" == 'CHG' || "$PREV_STATE" == '80PCT' || "$PREV_STATE" == 'FULL' ]]; then
            echo 'NONE' > "$NOTIFY_FILE"
        fi
        if [[ "$capacity" -ge 75 ]]; then
            :
        elif [[ "$capacity" -ge 10 && "$capacity" -lt 20 ]] && { [[ "$PREV_CAP" -ge 20 ]] || [[ "$PREV_STATE" != 'LOW' ]]; }; then
            notify-send -u critical 'Battery Low' "Battery at ${capacity}%" &
            paplay ~/.config/sounds/battery-low.mp3 2>/dev/null &
            echo 'LOW' > "$NOTIFY_FILE"
        elif [[ "$capacity" -le 9 ]]; then
            [[ ! -f /tmp/battery/battery_suspend_triggered ]] && bash ~/.config/hypr/battery-suspend.sh &
            if [[ "$PREV_CAP" -ge 10 || "$PREV_STATE" != 'CRIT' ]]; then
                notify-send -u critical 'Battery Critical' "Battery at ${capacity}% — Plug in NOW!" &
                paplay ~/.config/sounds/battery-critical.mp3 2>/dev/null &
                echo 'CRIT' > "$NOTIFY_FILE"
            fi
        fi
    fi

    printf '{"capacity":%d,"time":"%s","icon":"%s","status":"%s"}\n' \
        "$capacity" "$time" "$icon" "$status"
}

emit

while IFS= read -r line; do
    if echo "$line" | grep -q "battery"; then
        sleep 1
        emit
    fi
done < <(upower --monitor 2>/dev/null)
