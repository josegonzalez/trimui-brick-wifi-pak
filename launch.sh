#!/bin/sh
echo "$0" "$@"
progdir="$(dirname "$0")"
cd "$progdir" || exit 1
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$progdir/lib"
echo 1 >/tmp/stay_awake
trap "rm -f /tmp/stay_awake" EXIT INT TERM HUP QUIT

JQ="$progdir/bin/jq-arm"
if uname -m | grep -q '64'; then
    JQ="$progdir/bin/jq-arm64"
fi

main_screen() {
    enabled="$(cat /sys/class/net/wlan0/operstate)"
    configuration="Connected: false\nEnable"
    ip_address="N/A"
    if wifi_enabled; then
        configuration="Connected: true\nDisable\nConnect to new network"
    fi

    if [ "$enabled" = "up" ]; then
        ssid="$(iw dev wlan0 link | grep SSID: | cut -d':' -f2- | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//')"
        ip_address="$(ip addr show wlan0 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)"
        configuration="Connected: true\nSSID: $ssid\nIP: $ip_address\nDisable\nConnect to new network"
    fi

    echo -e "$configuration" | "$progdir/bin/minui-list-$PLATFORM" --file - --format text --header "Wifi Configuration"
}

networks_screen() {
    show_message "Scanning for networks..." 2
    DELAY=30
    for i in $(seq 1 "$DELAY"); do
        networks="$(iw dev wlan0 scan | grep SSID: | cut -d':' -f2- | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//' | sort)"
        if [ -n "$networks" ]; then
            break
        fi
        sleep 1
    done
    echo -e "$networks" | "$progdir/bin/minui-list-$PLATFORM" --file - --format text --header "Wifi Networks"
}

password_screen() {
    SSID="$1"

    touch "$SDCARD_PATH/wifi.txt"
    if grep -q "^$SSID:" "$SDCARD_PATH/wifi.txt" 2>/dev/null; then
        return 0
    fi

    password="$("$progdir/bin/minui-keyboard-$PLATFORM" --header "Enter Password")"
    exit_code=$?
    if [ "$exit_code" -eq 2 ]; then
        return 2
    fi
    if [ "$exit_code" -eq 3 ]; then
        return 3
    fi
    if [ "$exit_code" -ne 0 ]; then
        show_message "Error entering password" 2
        return 1
    fi

    if [ -z "$password" ]; then
        show_message "Password cannot be empty" 2
        return 1
    fi

    touch "$SDCARD_PATH/wifi.txt"
    echo "$SSID:$password" >>"$SDCARD_PATH/wifi.txt"
}

show_message() {
    message="$1"
    seconds="$2"

    if [ -z "$seconds" ]; then
        seconds="forever"
    fi

    killall sdl2imgshow
    echo "$message" 1>&2
    if [ "$seconds" = "forever" ]; then
        "$progdir/bin/sdl2imgshow" \
            -i "$progdir/res/background.png" \
            -f "$progdir/res/fonts/BPreplayBold.otf" \
            -s 27 \
            -c "220,220,220" \
            -q \
            -t "$message" >/dev/null 2>&1 &
    else
        "$progdir/bin/sdl2imgshow" \
            -i "$progdir/res/background.png" \
            -f "$progdir/res/fonts/BPreplayBold.otf" \
            -s 27 \
            -c "220,220,220" \
            -q \
            -t "$message" >/dev/null 2>&1
        sleep "$seconds"
    fi
}

write_config() {
    cp "$progdir/res/wpa_supplicant.conf.tmpl" "$progdir/res/wpa_supplicant.conf"
    echo "Generating wpa_supplicant.conf..."

    if [ ! -f "$SDCARD_PATH/wifi.txt" ] && [ -f "$progdir/wifi.txt" ]; then
        mv "$progdir/wifi.txt" "$SDCARD_PATH/wifi.txt"
    fi

    touch "$SDCARD_PATH/wifi.txt"
    sed -i '/^$/d' "$SDCARD_PATH/wifi.txt"
    # exit non-zero if no wifi.txt file or empty
    if [ ! -s "$SDCARD_PATH/wifi.txt" ]; then
        show_message "No credentials found in wifi.txt" 2
        return 1
    fi

    echo "" >>"$SDCARD_PATH/wifi.txt"
    while read -r line; do
        line="$(echo "$line" | xargs)"
        if [ -z "$line" ]; then
            continue
        fi

        # skip if line starts with a comment
        if echo "$line" | grep -q "^#"; then
            continue
        fi

        # skip if line is not in the format "ssid:psk"
        if ! echo "$line" | grep -q ":"; then
            continue
        fi

        ssid="$(echo "$line" | cut -d: -f1 | xargs)"
        psk="$(echo "$line" | cut -d: -f2- | xargs)"
        if [ -z "$ssid" ] || [ -z "$psk" ]; then
            continue
        fi

        {
            echo "network={"
            echo "    ssid=\"$ssid\""
            echo "    psk=\"$psk\""
            echo "}"
        } >>"$progdir/res/wpa_supplicant.conf"
    done <"$SDCARD_PATH/wifi.txt"

    cp "$progdir/res/wpa_supplicant.conf" /etc/wifi/wpa_supplicant.conf
}

wifi_enable() {
    SYSTEM_JSON_PATH="/mnt/UDISK/system.json"
    if [ -f "$SYSTEM_JSON_PATH" ]; then
        chmod +x "$JQ"
        "$JQ" '.wifi = 1' "$SYSTEM_JSON_PATH" >"/tmp/system.json.tmp"
        mv "/tmp/system.json.tmp" "$SYSTEM_JSON_PATH"
    fi

    echo "Unblocking wireless..."
    rfkill unblock wifi || true

    echo "Starting wpa_supplicant..."
    /etc/init.d/wpa_supplicant stop || true
    /etc/init.d/wpa_supplicant start || true
    ( (udhcpc -i wlan0 -q &) &)
}

wifi_enabled() {
    SYSTEM_JSON_PATH="/mnt/UDISK/system.json"
    if [ -f "$SYSTEM_JSON_PATH" ]; then
        chmod +x "$JQ"
        wifi_enabled="$("$JQ" '.wifi' "$SYSTEM_JSON_PATH")"
        if [ "$wifi_enabled" = "1" ]; then
            return 0
        fi

        return 0
    fi

    if pgrep wpa_supplicant; then
        return 0
    fi

    if [ "$(cat /sys/class/net/wlan0/carrier 2>/dev/null)" = "1" ]; then
        return 0
    fi

    return 1
}

wifi_off() {
    echo "Preparing to toggle wifi off..."

    SYSTEM_JSON_PATH="/mnt/UDISK/system.json"
    if [ -f "$SYSTEM_JSON_PATH" ]; then
        chmod +x "$JQ"
        "$JQ" '.wifi = 0' "$SYSTEM_JSON_PATH" >"/tmp/system.json.tmp"
        mv "/tmp/system.json.tmp" "$SYSTEM_JSON_PATH"
    fi

    if pgrep wpa_supplicant; then
        echo "Stopping wpa_supplicant..."
        /etc/init.d/wpa_supplicant stop || true
        killall -9 wpa_supplicant || true
    fi

    status="$(cat /sys/class/net/wlan0/carrier)"
    if [ "$status" = 1 ]; then
        echo "Marking wlan0 interface down..."
        ifconfig wlan0 down || true
    fi

    if [ ! -f /sys/class/rfkill/rfkill0/state ]; then
        echo "Blocking wireless..."
        rfkill block wifi || true
    fi

    cp "$progdir/res/wpa_supplicant.conf.tmpl" "$progdir/res/wpa_supplicant.conf"
}

wifi_on() {
    echo "Preparing to toggle wifi on..."

    if ! write_config; then
        return 1
    fi

    wifi_enable

    DELAY=30
    for i in $(seq 1 "$DELAY"); do
        STATUS=$(cat "/sys/class/net/wlan0/operstate")
        if [ "$STATUS" = "up" ]; then
            break
        fi
        sleep 1
    done

    if [ "$STATUS" != "up" ]; then
        show_message "Failed to start wifi!" 2
        return 1
    fi
}

network_loop() {
    show_message "Enabling wifi..." forever
    wifi_enable

    next_screen="main"
    while true; do
        SSID="$(networks_screen)"
        exit_code=$?
        # exit codes: 2 = back button (go back to main screen)
        if [ "$exit_code" -eq 2 ]; then
            break
        fi

        # exit codes: 3 = menu button (exit out of the app)
        if [ "$exit_code" -eq 3 ]; then
            next_screen="exit"
            break
        fi

        # some sort of error and then go back to main screen
        if [ "$exit_code" -ne 0 ]; then
            show_message "Error selecting a network" 2
            next_screen="main"
            break
        fi

        password_screen "$SSID"
        exit_code=$?
        # exit codes: 2 = back button (go back to networks screen)
        if [ "$exit_code" -eq 2 ]; then
            continue
        fi

        # exit codes: 3 = menu button (exit out of the app)
        if [ "$exit_code" -eq 3 ]; then
            next_screen="exit"
            break
        fi

        if [ "$exit_code" -ne 0 ]; then
            continue
        fi

        show_message "Connecting to $SSID..." forever
        if ! wifi_on; then
            show_message "Failed to start wifi!" 2
            killall sdl2imgshow
            exit 1
        fi
        break
    done

    echo "$next_screen"
}

main() {
    trap "killall sdl2imgshow" EXIT INT TERM HUP QUIT

    if [ "$PLATFORM" = "tg3040" ] && [ -z "$DEVICE" ]; then
        export DEVICE="brick"
        export PLATFORM="tg5040"
    fi

    allowed_platforms="tg5040"
    if ! echo "$allowed_platforms" | grep -q "$PLATFORM"; then
        show_message "$PLATFORM is not a supported platform" 1>&2
        exit 1
    fi

    if [ ! -f "$progdir/bin/minui-keyboard-$PLATFORM" ]; then
        show_message "$progdir/bin/minui-keyboard-$PLATFORM not found" 1>&2
        exit 1
    fi
    if [ ! -f "$progdir/bin/minui-list-$PLATFORM" ]; then
        show_message "$progdir/bin/minui-list-$PLATFORM not found" 1>&2
        exit 1
    fi

    while true; do
        selection="$(main_screen)"
        exit_code=$?
        # exit codes: 2 = back button, 3 = menu button
        if [ "$exit_code" -ne 0 ]; then
            break
        fi

        if echo "$selection" | grep -q "Connect to network"; then
            next_screen="$(network_loop)"
            if [ "$next_screen" = "exit" ]; then
                break
            fi
        elif echo "$selection" | grep -q "Enable"; then
            wifi_enable
        elif echo "$selection" | grep -q "Disable"; then
            show_message "Disconnecting from wifi..." forever
            if ! wifi_off; then
                show_message "Failed to stop wifi!" 2
                killall sdl2imgshow
                exit 1
            fi
        fi
    done
    killall sdl2imgshow
}

mkdir -p "$LOGS_PATH"
if [ -f "$LOGS_PATH/Wifi.txt" ]; then
    mv "$LOGS_PATH/Wifi.txt" "$LOGS_PATH/Wifi.txt.old"
fi

main "$@" >"$LOGS_PATH/Wifi.txt" 2>&1
