#!/bin/sh
echo "$0" "$@"
progdir="$(dirname "$0")"
cd "$progdir" || exit 1
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$progdir"
echo 1 >/tmp/stay_awake
trap "rm -f /tmp/stay_awake" EXIT INT TERM HUP QUIT

wifi_off() {
    echo "Preparping to toggle wifi off..."

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
        echo 0 >/sys/class/rfkill/rfkill0/state || true
    fi
}

wifi_on() {
    echo "Preparing to toggle wifi on..."

    echo "Unblocking wireless..."
    echo 1 >/sys/class/rfkill/rfkill0/state || true

    echo "Starting wpa_supplicant..."
    wpa_supplicant -B -D nl80211 -iwlan0 -c /etc/wifi/wpa_supplicant.conf -O /etc/wifi/sockets || true
    ( (udhcpc -i wlan0 &) &)
}

if pgrep wpa_supplicant; then
    wifi_off
else
    wifi_on
fi

echo "Done toggling wifi!"
echo ""
echo "Sleeping for 2 seconds."
sleep 2
