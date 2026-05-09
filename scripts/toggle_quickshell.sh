#!/bin/bash

# Check if quickshell is running with the specific config
if pgrep -f "quickshell.*shell.qml" > /dev/null; then
    # Kill the process
    pkill -f "quickshell.*shell.qml"
    echo "quickshell stopped"
else
    # Start the process with environment variable
    QML2_IMPORT_PATH=$HOME/.config/quickshell/dynamic_island quickshell -p $HOME/.config/quickshell/dynamic_island/shell.qml &
    echo "quickshell started"
fi
