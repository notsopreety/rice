#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Modified with auto-hide after 3 seconds of silence

#----- Optimized bars animation without much CPU usage increase --------
bar="▁▂▃▄▅▆▇█"
dict="s/;//g"

# Calculate the length of the bar outside the loop
bar_length=${#bar}

# Create dictionary to replace char with bar
for ((i = 0; i < bar_length; i++)); do
    dict+=";s/$i/${bar:$i:1}/g"
done

# Create cava config
config_file="/tmp/bar_cava_config"
cat >"$config_file" <<EOF
[general]
framerate = 30
bars = 10

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

# Kill cava if it's already running
pkill -f "cava -p $config_file"

# Auto-hide logic: hide after 3 seconds of silence
last_output=""
last_change_time=$(date +%s)
hidden=false

# Read stdout from cava and perform substitution
while IFS= read -r line; do
    current_time=$(date +%s)
    transformed=$(echo "$line" | sed -u "$dict")
    
    # Check if output changed (music is playing)
    if [ "$transformed" != "$last_output" ] && [ -n "$transformed" ]; then
        last_change_time=$current_time
        if [ "$hidden" = true ]; then
            echo "$transformed"
            hidden=false
        fi
    fi
    
    # Check if 3 seconds passed without change
    elapsed=$((current_time - last_change_time))
    if [ $elapsed -ge 3 ] && [ "$hidden" = false ]; then
        echo ""
        hidden=true
    fi
    
    # Output if not hidden
    if [ "$hidden" = false ]; then
        echo "$transformed"
    fi
    
    last_output="$transformed"
done < <(cava -p "$config_file")
