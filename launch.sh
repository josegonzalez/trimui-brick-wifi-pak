#!/bin/sh
echo "$0" "$@"
progdir="$(dirname "$0")"
cd "$progdir" || exit 1
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$progdir/lib"
echo 1 >/tmp/stay_awake
trap "rm -f /tmp/stay_awake" EXIT INT TERM HUP QUIT
RES_PATH="$progdir/res"

show_message() {
    message="$1"
    seconds="$2"

    if [ -z "$seconds" ]; then
        seconds="forever"
    fi

    killall sdl2imgshow
    echo "$message"
    if [ "$seconds" = "forever" ]; then
        "$progdir/bin/sdl2imgshow" \
            -i "$progdir/res/background.png" \
            -f "$progdir/res/fonts/BPreplayBold.otf" \
            -s 27 \
            -c "220,220,220" \
            -q \
            -t "$message" &
    else
        "$progdir/bin/sdl2imgshow" \
            -i "$progdir/res/background.png" \
            -f "$progdir/res/fonts/BPreplayBold.otf" \
            -s 27 \
            -c "220,220,220" \
            -q \
            -t "$message"
        sleep "$seconds"
    fi
}

wifi_off() {
    SYSTEM_JSON_PATH="/mnt/UDISK/system.json"
    echo "Preparing to toggle wifi off..."

    chmod +x "$progdir/bin/jq"
    "$progdir/bin/jq" '.wifi = 0' "$SYSTEM_JSON_PATH" >"/tmp/system.json.tmp"
    mv "/tmp/system.json.tmp" "$SYSTEM_JSON_PATH"

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
    SYSTEM_JSON_PATH="/mnt/UDISK/system.json"
    echo "Preparing to toggle wifi on..."

    chmod +x "$progdir/bin/jq"
    "$progdir/bin/jq" '.wifi = 1' "$SYSTEM_JSON_PATH" >"/tmp/system.json.tmp"
    mv "/tmp/system.json.tmp" "$SYSTEM_JSON_PATH"

    cp "$progdir/res/wpa_supplicant.conf.tmpl" "$progdir/res/wpa_supplicant.conf"
    echo "Generating wpa_supplicant.conf..."

    if [ ! -f "$SDCARD_PATH/wifi.txt" ] && [ -f "$progdir/wifi.txt" ]; then
        cp "$progdir/wifi.txt" "$SDCARD_PATH/wifi.txt"
    fi

    touch "$SDCARD_PATH/wifi.txt"
    sed -i '/^$/d' "$SDCARD_PATH/wifi.txt"

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

    echo "Unblocking wireless..."
    rfkill unblock wifi || true

    echo "Starting wpa_supplicant..."
    /etc/init.d/wpa_supplicant stop || true
    /etc/init.d/wpa_supplicant start || true
    ( (udhcpc -i wlan0 &) &)

    DELAY=30
    for i in $(seq 1 "$DELAY"); do
        STATUS=$(cat "/sys/class/net/wlan0/operstate")
        if [ "$STATUS" = "up" ]; then
            break
        fi
        sleep 1
    done
}

main() {
    echo "Toggling wifi..."
    if grep -q "up" /sys/class/net/wlan0/operstate; then
        show_message "Stopping wifi..."
        wifi_off
    else
        show_message "Starting wifi..."
        if ! wifi_on; then
            show_message "Failed to start wifi!" 2
            killall sdl2imgshow
            exit 1
        fi
    fi

    echo "Done toggling wifi!"
    show_message Done! 2
    killall sdl2imgshow
}

mkdir -p "$progdir/log"
if [ -f "$progdir/log/launch.log" ]; then
    mv "$progdir/log/launch.log" "$progdir/log/launch.log.old"
fi

main "$@" >"$progdir/log/launch.log" 2>&1
