#!/usr/bin/env bash

# Weather script for Waybar with detailed tooltip and forecast
# Requires: curl, jq

API_KEY="ac67d588b22e366bba9b02476682f868"
CITY="Kathmandu"
UNITS="metric"  # metric or imperial

if [ -z "$API_KEY" ] || [ -z "$CITY" ]; then
    echo '{"text": "󰖐", "tooltip": "Weather API key or city not set"}'
    exit 0
fi

# Fetch current weather
weather=$(curl -s "http://api.openweathermap.org/data/2.5/weather?q=$CITY&units=$UNITS&appid=$API_KEY")

if [ $? -ne 0 ]; then
    echo '{"text": "󰖐", "tooltip": "Failed to fetch weather data"}'
    exit 0
fi

# Fetch 5-day forecast
forecast=$(curl -s "http://api.openweathermap.org/data/2.5/forecast?q=$CITY&units=$UNITS&appid=$API_KEY")

temp=$(echo "$weather" | jq -r '.main.temp')
feels_like=$(echo "$weather" | jq -r '.main.feels_like')
humidity=$(echo "$weather" | jq -r '.main.humidity')
wind_speed=$(echo "$weather" | jq -r '.wind.speed')
pressure=$(echo "$weather" | jq -r '.main.pressure')
description=$(echo "$weather" | jq -r '.weather[0].description')
icon_code=$(echo "$weather" | jq -r '.weather[0].icon')
sunrise=$(echo "$weather" | jq -r '.sys.sunrise')
sunset=$(echo "$weather" | jq -r '.sys.sunset')

# Map icon codes to nerd font icons
case "$icon_code" in
    01d|01n) icon="󰖙" ;;  # clear
    02d|02n) icon="󰖕" ;;  # few clouds
    03d|03n) icon="󰖐" ;;  # scattered clouds
    04d|04n) icon="󰖐" ;;  # broken clouds
    09d|09n) icon="󰖖" ;;  # shower rain
    10d|10n) icon="󰖖" ;;  # rain
    11d|11n) icon="󰖓" ;;  # thunderstorm
    13d|13n) icon="󰖘" ;;  # snow
    50d|50n) icon="󰖑" ;;  # mist
    *) icon="󰖐" ;;
esac

# Format sunrise/sunset
if [ -n "$sunrise" ] && [ "$sunrise" != "null" ]; then
    sunrise_time=$(date -d "@$sunrise" "+%H:%M")
else
    sunrise_time="N/A"
fi

if [ -n "$sunset" ] && [ "$sunset" != "null" ]; then
    sunset_time=$(date -d "@$sunset" "+%H:%M")
else
    sunset_time="N/A"
fi

# Build detailed current weather tooltip
tooltip="<span foreground='#ffead3'><b>$CITY</b></span>\n"
tooltip+="<span foreground='#ffcc66'>$description</span>\n\n"
tooltip+="<span foreground='#99ffdd'>󰔏 Temperature:</span> ${temp}°C\n"
tooltip+="<span foreground='#99ffdd'>󰄮 Feels like:</span> ${feels_like}°C\n"
tooltip+="<span foreground='#99ffdd'>󰔐 Humidity:</span> ${humidity}%\n"
tooltip+="<span foreground='#99ffdd'>󰖝 Wind:</span> ${wind_speed} m/s\n"
tooltip+="<span foreground='#99ffdd'>󰖔 Pressure:</span> ${pressure} hPa\n"
tooltip+="<span foreground='#ffcc66'>󰖛 Sunrise:</span> $sunrise_time\n"
tooltip+="<span foreground='#ffcc66'>󰖛 Sunset:</span> $sunset_time"

# Build forecast tooltip (next 3 days at noon)
forecast_tooltip="\n\n<span foreground='#ffead3'><b>3-Day Forecast</b></span>\n"

# Process forecast data - extract more detailed information
if [ -n "$forecast" ]; then
    forecast_output=$(echo "$forecast" | jq -r '.list[] | select(.dt_txt | contains("12:00:00")) | "\(.dt_txt)|\(.main.temp)|\(.main.temp_min)|\(.main.temp_max)|\(.main.humidity)|\(.wind.speed)|\(.weather[0].icon)|\(.weather[0].description)"' | head -n 3)
    
    while IFS='|' read -r f_date f_temp f_temp_min f_temp_max f_humidity f_wind f_icon f_desc; do
        if [ -n "$f_date" ]; then
            # Format date
            f_day=$(date -d "$f_date" "+%a, %b %d" 2>/dev/null || echo "$f_date")
            
            # Map forecast icon
            case "$f_icon" in
                01d|01n) f_icon_display="󰖙" ;;
                02d|02n) f_icon_display="󰖕" ;;
                03d|03n) f_icon_display="󰖐" ;;
                04d|04n) f_icon_display="󰖐" ;;
                09d|09n) f_icon_display="󰖖" ;;
                10d|10n) f_icon_display="󰖖" ;;
                11d|11n) f_icon_display="󰖓" ;;
                13d|13n) f_icon_display="󰖘" ;;
                50d|50n) f_icon_display="󰖑" ;;
                *) f_icon_display="󰖐" ;;
            esac
            
            forecast_tooltip+="<span foreground='#ffcc66'><b>$f_day</b></span> $f_icon_display $f_desc\n"
            forecast_tooltip+="  <span foreground='#99ffdd'>󰔏 Temp:</span> ${f_temp}°C (Low: ${f_temp_min}°C / High: ${f_temp_max}°C)\n"
            forecast_tooltip+="  <span foreground='#99ffdd'>󰔐 Humidity:</span> ${f_humidity}% | <span foreground='#99ffdd'>󰖝 Wind:</span> ${f_wind} m/s\n"
        fi
    done <<< "$forecast_output"
fi

# Combine tooltips
full_tooltip="$tooltip$forecast_tooltip"

echo "{\"text\": \"$icon ${temp}°\", \"tooltip\": \"$full_tooltip\"}"
