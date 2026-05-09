#!/bin/bash

# Configuration
WIDGETS_FILE="$HOME/.config/quickshell/widgets.txt"
PID_DIR="$HOME/.cache/quickshell/pids"
mkdir -p "$PID_DIR"

usage() {
    echo "Usage: $0 [command] [widget_id|all]"
    echo "Commands:"
    echo "  load    <id|all>    Start widget(s)"
    echo "  unload  <id|all>    Stop widget(s)"
    echo "  restart <id|all>    Restart widget(s)"
    echo "  toggle  <id|all>    Toggle widget(s)"
    echo "  list                List configured widgets"
    exit 1
}

get_path() {
    grep "^$1 " "$WIDGETS_FILE" | awk '{print $2}' | sed "s|~|$HOME|g"
}

is_running() {
    local id=$1
    if [ -f "$PID_DIR/$id.pid" ]; then
        local pid=$(cat "$PID_DIR/$id.pid")
        if ps -p "$pid" > /dev/null; then
            return 0
        fi
    fi
    return 1
}

load_widget() {
    local id=$1
    local path=$(get_path "$id")
    
    if [ -z "$path" ]; then
        echo "Error: Widget '$id' not found in $WIDGETS_FILE"
        return 1
    fi

    if is_running "$id"; then
        echo "Widget '$id' is already running."
        return 0
    fi

    echo "Loading widget: $id ($path)"
    quickshell -p "$path" > /dev/null 2>&1 &
    echo $! > "$PID_DIR/$id.pid"
}

unload_widget() {
    local id=$1
    if is_running "$id"; then
        local pid=$(cat "$PID_DIR/$id.pid")
        echo "Unloading widget: $id (PID: $pid)"
        kill "$pid"
        rm "$PID_DIR/$id.pid"
    else
        echo "Widget '$id' is not running."
        # Clean up stale pid file if exists
        [ -f "$PID_DIR/$id.pid" ] && rm "$PID_DIR/$id.pid"
    fi
}

restart_widget() {
    unload_widget "$1"
    sleep 0.5
    load_widget "$1"
}

toggle_widget() {
    if is_running "$1"; then
        unload_widget "$1"
    else
        load_widget "$1"
    fi
}

# --- Main Execution ---

[ $# -lt 1 ] && usage

CMD=$1
TARGET=$2

case "$CMD" in
    "list")
        cat "$WIDGETS_FILE"
        ;;
    "load"|"unload"|"restart"|"toggle")
        [ -z "$TARGET" ] && usage
        
        if [ "$TARGET" == "all" ]; then
            ids=$(awk '{print $1}' "$WIDGETS_FILE")
            for id in $ids; do
                "${CMD}_widget" "$id"
            done
        else
            "${CMD}_widget" "$TARGET"
        fi
        ;;
    *)
        usage
        ;;
esac
