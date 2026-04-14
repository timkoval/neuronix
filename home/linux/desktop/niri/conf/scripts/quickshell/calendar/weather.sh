#!/usr/bin/env bash

# Paths
cache_dir="$HOME/.cache/quickshell/weather"
json_file="${cache_dir}/weather.json"
view_file="${cache_dir}/view_id"
env_tracker_file="${cache_dir}/.env_tracker"
ENV_FILE="$(dirname "$0")/.env"

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

# Coordinates for Open-Meteo (set in .env as WEATHER_LAT / WEATHER_LON)
LAT="${WEATHER_LAT:-}"
LON="${WEATHER_LON:-}"

# Legacy OpenWeatherMap fallback
OWM_KEY="$OPENWEATHER_KEY"
OWM_ID="$OPENWEATHER_CITY_ID"
OWM_UNIT="${OPENWEATHER_UNIT:-metric}"

mkdir -p "${cache_dir}"

# -------------------------------------------------------------------------
# WMO Weather Code -> Icon & Description
# -------------------------------------------------------------------------
get_wmo_icon() {
    local code=$1
    local is_day=${2:-1} # 1=day, 0=night
    case $code in
        0)          echo "$([ "$is_day" -eq 1 ] && echo '' || echo '')|Clear" ;;
        1)          echo "$([ "$is_day" -eq 1 ] && echo '' || echo '')|Mostly Clear" ;;
        2)          echo "|Partly Cloudy" ;;
        3)          echo "|Overcast" ;;
        45|48)      echo "|Foggy" ;;
        51|53|55)   echo "|Drizzle" ;;
        56|57)      echo "|Freezing Drizzle" ;;
        61|63|65)   echo "|Rainy" ;;
        66|67)      echo "|Freezing Rain" ;;
        71|73|75)   echo "|Snow" ;;
        77)         echo "|Snow Grains" ;;
        80|81|82)   echo "|Showers" ;;
        85|86)      echo "|Snow Showers" ;;
        95)         echo "|Thunderstorm" ;;
        96|99)      echo "|Hail Storm" ;;
        *)          echo "|Unknown" ;;
    esac
}

get_wmo_hex() {
    local code=$1
    case $code in
        0|1)        echo "#f9e2af" ;; # Clear/Sunny - yellow
        2|3)        echo "#bac2de" ;; # Cloudy - grey
        45|48)      echo "#84afdb" ;; # Fog - light blue
        51|53|55)   echo "#89b4fa" ;; # Drizzle - blue
        56|57)      echo "#74c7ec" ;; # Freezing drizzle
        61|63|65)   echo "#74c7ec" ;; # Rain - cyan
        66|67)      echo "#89dceb" ;; # Freezing rain
        71|73|75|77) echo "#cdd6f4" ;; # Snow - white
        80|81|82)   echo "#74c7ec" ;; # Showers
        85|86)      echo "#cdd6f4" ;; # Snow showers
        95)         echo "#f9e2af" ;; # Thunderstorm - yellow
        96|99)      echo "#f38ba8" ;; # Hail - red
        *)          echo "#cdd6f4" ;; # Default
    esac
}

# -------------------------------------------------------------------------
# DUMMY DATA
# -------------------------------------------------------------------------
write_dummy_data() {
    final_json="["
    for i in {0..4}; do
        future_date=$(date -d "+$i days")
        f_day=$(date -d "$future_date" "+%a")
        f_full_day=$(date -d "$future_date" "+%A")
        f_date_num=$(date -d "$future_date" "+%d %b")

        final_json="${final_json} {
            \"id\": \"${i}\",
            \"day\": \"${f_day}\",
            \"day_full\": \"${f_full_day}\",
            \"date\": \"${f_date_num}\",
            \"max\": \"0.0\",
            \"min\": \"0.0\",
            \"feels_like\": \"0.0\",
            \"wind\": \"0\",
            \"humidity\": \"0\",
            \"pop\": \"0\",
            \"icon\": \"\",
            \"hex\": \"#cdd6f4\",
            \"desc\": \"No Location Set\",
            \"hourly\": [{\"time\": \"00:00\", \"temp\": \"0.0\", \"icon\": \"\", \"hex\": \"#cdd6f4\"}]
        },"
    done
    final_json="${final_json%,}]"
    echo "{ \"forecast\": ${final_json} }" > "${json_file}"
}

# -------------------------------------------------------------------------
# OPEN-METEO FETCH
# -------------------------------------------------------------------------
get_data_openmeteo() {
    if [[ -z "$LAT" || -z "$LON" ]]; then
        write_dummy_data
        return
    fi

    local url="https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&hourly=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation_probability,weather_code,wind_speed_10m,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,wind_speed_10m_max,precipitation_probability_max&timezone=auto&forecast_days=5"

    raw_api=$(curl -sf "$url")
    if [ -z "$raw_api" ]; then
        write_dummy_data
        return
    fi

    # Get the list of dates from API
    dates=$(echo "$raw_api" | jq -r '.daily.time[]')
    if [ -z "$dates" ]; then
        write_dummy_data
        return
    fi

    final_json="["
    counter=0

    for d in $dates; do
        # Shell-side date formatting (jq can't strftime on date strings)
        f_day=$(date -d "$d" "+%a")
        f_full_day=$(date -d "$d" "+%A")
        f_date_num=$(date -d "$d" "+%d %b")

        # Extract daily values for this index
        day_vals=$(echo "$raw_api" | jq --argjson i "$counter" '{
            max: (.daily.temperature_2m_max[$i] * 10 | round / 10),
            min: (.daily.temperature_2m_min[$i] * 10 | round / 10),
            feels: (.daily.apparent_temperature_max[$i] * 10 | round / 10),
            wind: (.daily.wind_speed_10m_max[$i] | round),
            pop: .daily.precipitation_probability_max[$i],
            code: .daily.weather_code[$i]
        }')

        f_max=$(echo "$day_vals" | jq -r '.max')
        f_min=$(echo "$day_vals" | jq -r '.min')
        f_feels=$(echo "$day_vals" | jq -r '.feels')
        f_wind=$(echo "$day_vals" | jq -r '.wind')
        f_pop=$(echo "$day_vals" | jq -r '.pop')
        f_code=$(echo "$day_vals" | jq -r '.code')

        f_icon_data=$(get_wmo_icon "$f_code" 1)
        f_icon=$(echo "$f_icon_data" | cut -d'|' -f1)
        f_desc=$(echo "$f_icon_data" | cut -d'|' -f2)
        f_hex=$(get_wmo_hex "$f_code")

        # Extract hourly data for this date
        hourly_json=$(echo "$raw_api" | jq -c --arg date "$d" '
            .hourly as $h |
            [$h.time | to_entries[] | select(.value | startswith($date))] |
            map(.key) |
            map(. as $idx | {
                time: ($h.time[$idx] | split("T")[1]),
                temp: (($h.temperature_2m[$idx] * 10 | round) / 10 | tostring),
                code: $h.weather_code[$idx],
                is_day: $h.is_day[$idx]
            })
        ' 2>/dev/null)

        # Map weather codes to icons/hex in shell (jq string escaping is unreliable for unicode)
        hourly_final="["
        for row in $(echo "$hourly_json" | jq -c '.[]' 2>/dev/null); do
            h_time=$(echo "$row" | jq -r '.time')
            h_temp=$(echo "$row" | jq -r '.temp')
            h_code=$(echo "$row" | jq -r '.code')
            h_is_day=$(echo "$row" | jq -r '.is_day')
            h_icon=$(get_wmo_icon "$h_code" "$h_is_day" | cut -d'|' -f1)
            h_hex=$(get_wmo_hex "$h_code")
            hourly_final="${hourly_final}{\"time\":\"${h_time}\",\"temp\":\"${h_temp}\",\"icon\":\"${h_icon}\",\"hex\":\"${h_hex}\"},"
        done
        hourly_final="${hourly_final%,}]"

        if [ "$hourly_final" = "]" ]; then
            hourly_final="[]"
        fi

        # Compute average humidity from hourly
        f_hum=$(echo "$raw_api" | jq --arg date "$d" '
            .hourly as $h |
            [$h.time | to_entries[] | select(.value | startswith($date))] |
            map(.key) | map($h.relative_humidity_2m[.]) | add / length | round
        ' 2>/dev/null || echo "0")

        final_json="${final_json} {
            \"id\": \"${counter}\",
            \"day\": \"${f_day}\",
            \"day_full\": \"${f_full_day}\",
            \"date\": \"${f_date_num}\",
            \"max\": \"${f_max}\",
            \"min\": \"${f_min}\",
            \"feels_like\": \"${f_feels}\",
            \"wind\": \"${f_wind}\",
            \"humidity\": \"${f_hum}\",
            \"pop\": \"${f_pop}\",
            \"icon\": \"${f_icon}\",
            \"hex\": \"${f_hex}\",
            \"desc\": \"${f_desc}\",
            \"hourly\": ${hourly_final}
        },"
        ((counter++))
    done
    final_json="${final_json%,}]"

    echo "{ \"forecast\": ${final_json} }" > "${json_file}"
}

# -------------------------------------------------------------------------
# LEGACY OPENWEATHERMAP FETCH (kept for backward compat)
# -------------------------------------------------------------------------
get_icon_owm() {
    case $1 in
        "50d"|"50n") echo "|Mist" ;;
        "01d") echo "|Sunny" ;;
        "01n") echo "|Clear" ;;
        "02d"|"02n"|"03d"|"03n"|"04d"|"04n") echo "|Cloudy" ;;
        "09d"|"09n"|"10d"|"10n") echo "|Rainy" ;;
        "11d"|"11n") echo "|Storm" ;;
        "13d"|"13n") echo "|Snow" ;;
        *) echo "|Unknown" ;;
    esac
}

get_hex_owm() {
    case $1 in
        "50d"|"50n") echo "#84afdb" ;;
        "01d") echo "#f9e2af" ;;
        "01n") echo "#cba6f7" ;;
        "02d"|"02n"|"03d"|"03n"|"04d"|"04n") echo "#bac2de" ;;
        "09d"|"09n"|"10d"|"10n") echo "#74c7ec" ;;
        "11d"|"11n") echo "#f9e2af" ;;
        "13d"|"13n") echo "#cdd6f4" ;;
        *) echo "#cdd6f4" ;;
    esac
}

get_data_owm() {
    if [[ -z "$OWM_KEY" || "$OWM_KEY" == "Skipped" || "$OWM_KEY" == "OPENWEATHER_KEY" ]]; then
        write_dummy_data
        return
    fi

    forecast_url="http://api.openweathermap.org/data/2.5/forecast?APPID=${OWM_KEY}&id=${OWM_ID}&units=${OWM_UNIT}"
    raw_api=$(curl -sf "$forecast_url")
    api_cod=$(echo "$raw_api" | jq -r '.cod' 2>/dev/null)

    if [ -z "$raw_api" ] || [[ "$api_cod" != "200" ]]; then
        write_dummy_data
        return
    fi

    dates=$(echo "$raw_api" | jq -r '.list[].dt_txt | split(" ")[0]' | uniq | head -n 5)

    final_json="["
    counter=0

    for d in $dates; do
        day_data=$(echo "$raw_api" | jq "[.list[] | select(.dt_txt | startswith(\"$d\"))]")

        f_max_temp=$(printf "%.1f" "$(echo "$day_data" | jq '[.[].main.temp_max] | max')")
        f_min_temp=$(printf "%.1f" "$(echo "$day_data" | jq '[.[].main.temp_min] | min')")
        f_feels_like=$(printf "%.1f" "$(echo "$day_data" | jq '[.[].main.feels_like] | max')")
        f_pop_pct=$(echo "$(echo "$day_data" | jq '[.[].pop] | max') * 100" | bc | cut -d. -f1)
        f_wind=$(echo "$day_data" | jq '[.[].wind.speed] | max | round')
        f_hum=$(echo "$day_data" | jq '[.[].main.humidity] | add / length | round')

        f_code=$(echo "$day_data" | jq -r '.[length/2 | floor].weather[0].icon')
        f_desc=$(echo "$day_data" | jq -r '.[length/2 | floor].weather[0].description' | sed -e "s/\b\(.\)/\u\1/g")
        f_icon=$(get_icon_owm "$f_code" | cut -d'|' -f1)
        f_hex=$(get_hex_owm "$f_code")

        f_day=$(date -d "$d" "+%a")
        f_full_day=$(date -d "$d" "+%A")
        f_date_num=$(date -d "$d" "+%d %b")

        hourly_json="["
        count_slots=$(($(echo "$day_data" | jq '. | length') - 1))
        for i in $(seq 0 1 $count_slots); do
            slot_item=$(echo "$day_data" | jq ".[$i]")
            s_temp=$(printf "%.1f" "$(echo "$slot_item" | jq ".main.temp")")
            s_dt=$(echo "$slot_item" | jq ".dt")
            s_time=$(date -d @$s_dt "+%H:%M")
            s_code=$(echo "$slot_item" | jq -r ".weather[0].icon")
            s_hex=$(get_hex_owm "$s_code")
            s_icon=$(get_icon_owm "$s_code" | cut -d'|' -f1)
            hourly_json="${hourly_json} {\"time\": \"${s_time}\", \"temp\": \"${s_temp}\", \"icon\": \"${s_icon}\", \"hex\": \"${s_hex}\"},"
        done
        hourly_json="${hourly_json%,}]"

        final_json="${final_json} {
            \"id\": \"${counter}\",
            \"day\": \"${f_day}\",
            \"day_full\": \"${f_full_day}\",
            \"date\": \"${f_date_num}\",
            \"max\": \"${f_max_temp}\",
            \"min\": \"${f_min_temp}\",
            \"feels_like\": \"${f_feels_like}\",
            \"wind\": \"${f_wind}\",
            \"humidity\": \"${f_hum}\",
            \"pop\": \"${f_pop_pct}\",
            \"icon\": \"${f_icon}\",
            \"hex\": \"${f_hex}\",
            \"desc\": \"${f_desc}\",
            \"hourly\": ${hourly_json}
        },"
        ((counter++))
    done
    final_json="${final_json%,}]"
    echo "{ \"forecast\": ${final_json} }" > "${json_file}"
}

# -------------------------------------------------------------------------
# MAIN DISPATCHER — Open-Meteo preferred, OWM as fallback
# -------------------------------------------------------------------------
get_data() {
    if [[ -n "$LAT" && -n "$LON" ]]; then
        get_data_openmeteo
    elif [[ -n "$OWM_KEY" && "$OWM_KEY" != "Skipped" ]]; then
        get_data_owm
    else
        write_dummy_data
    fi
}

# --- MODE HANDLING ---
if [[ "$1" == "--getdata" ]]; then
    get_data

elif [[ "$1" == "--json" ]]; then
    CACHE_LIMIT=900
    PENDING_RETRY_LIMIT=3600

    env_changed=0
    if [ -f "$ENV_FILE" ]; then
        env_mtime=$(stat -c %Y "$ENV_FILE")
        last_env_mtime=$(cat "$env_tracker_file" 2>/dev/null || echo "0")
        if [ "$env_mtime" -gt "$last_env_mtime" ]; then
            env_changed=1
            echo "$env_mtime" > "$env_tracker_file"
        fi
    fi

    if [ -f "$json_file" ]; then
        file_time=$(stat -c %Y "$json_file")
        current_time=$(date +%s)
        diff=$((current_time - file_time))

        if [ "$env_changed" -eq 1 ]; then
            touch "$json_file"
            get_data &
        elif grep -q '"desc": "No Location Set"\|"desc": "No API Key"' "$json_file"; then
            if [ $diff -gt $PENDING_RETRY_LIMIT ]; then
                touch "$json_file"
                get_data &
            fi
        else
            if [ $diff -gt $CACHE_LIMIT ]; then
                touch "$json_file"
                get_data &
            fi
        fi
        cat "$json_file"
    else
        get_data
        cat "$json_file"
    fi

elif [[ "$1" == "--view-listener" ]]; then
    if [ ! -f "$view_file" ]; then echo "0" > "$view_file"; fi
    tail -F "$view_file"

elif [[ "$1" == "--nav" ]]; then
    if [ ! -f "$view_file" ]; then echo "0" > "$view_file"; fi
    current=$(cat "$view_file")
    direction=$2
    max_idx=4
    if [[ "$direction" == "next" ]]; then
        if [ "$current" -lt "$max_idx" ]; then echo $((current + 1)) > "$view_file"; fi
    elif [[ "$direction" == "prev" ]]; then
        if [ "$current" -gt 0 ]; then echo $((current - 1)) > "$view_file"; fi
    fi

elif [[ "$1" == "--icon" ]]; then
    jq -r '.forecast[0].icon' "$json_file"

elif [[ "$1" == "--temp" ]]; then
    t=$(jq -r '.forecast[0].max' "$json_file")
    echo "${t}°C"

elif [[ "$1" == "--hex" ]]; then
    jq -r '.forecast[0].hex' "$json_file"

elif [[ "$1" == "--current-icon" ]]; then
    curr_time=$(date +%H:%M)
    jq -r --arg ct "$curr_time" '(.forecast[0].hourly | map(select(.time <= $ct)) | last) // .forecast[0].hourly[0] | .icon' "$json_file"

elif [[ "$1" == "--current-temp" ]]; then
    curr_time=$(date +%H:%M)
    t=$(jq -r --arg ct "$curr_time" '(.forecast[0].hourly | map(select(.time <= $ct)) | last) // .forecast[0].hourly[0] | .temp' "$json_file")
    echo "${t}°C"

elif [[ "$1" == "--current-hex" ]]; then
    curr_time=$(date +%H:%M)
    jq -r --arg ct "$curr_time" '(.forecast[0].hourly | map(select(.time <= $ct)) | last) // .forecast[0].hourly[0] | .hex' "$json_file"
fi
