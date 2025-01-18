#!/bin/sh
echo "$0" "$@"
progdir="$(dirname "$0")"
cd "$progdir" || exit 1
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$progdir/lib"
echo 1 >/tmp/stay_awake
trap "rm -f /tmp/stay_awake" EXIT INT TERM HUP QUIT
RES_PATH="$progdir/res"

wifi_off() {
    SYSTEM_JSON_PATH="/mnt/UDISK/system.json"
    echo "Preparing to toggle wifi off..."

    chmod +x "$progdir/bin/jq"
    "$progdir/bin/jq" '.wifi = 0' "$SYSTEM_JSON_PATH" >"/tmp/system.json.tmp"
    mv "/tmp/system.json.tmp" "$SYSTEM_JSON_PATH"

    if pgrep wpa_supplicant; then
        echo "Stopping wpa_supplicant..."
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

    echo "" >>"$progdir/wifi.txt"
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
    done <"$progdir/wifi.txt"

    cp "$progdir/res/wpa_supplicant.conf" /etc/wifi/wpa_supplicant.conf

    echo "Unblocking wireless..."
    rfkill unblock wifi || true

    echo "Starting wpa_supplicant..."
    wpa_supplicant -B -D nl80211 -iwlan0 -c /etc/wifi/wpa_supplicant.conf -O /etc/wifi/sockets || true
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
    if pgrep wpa_supplicant; then
        show.elf "$RES_PATH/stopping.png" 2
        echo "Stopping wifi..."
        wifi_off
    else
        show.elf "$RES_PATH/starting.png" 2
        echo "Starting wifi..."
        wifi_on
    fi

    echo "Done toggling wifi!"
    show.elf "$RES_PATH/done.png" 2
}

mkdir -p "$progdir/log"
if [ -f "$progdir/log/launch.log" ]; then
    mv "$progdir/log/launch.log" "$progdir/log/launch.log.old"
fi

main "$@" >"$progdir/log/launch.log" 2>&1
