#!/bin/sh
echo "$0" "$@"
progdir="$(dirname "$0")"
cd "$progdir" || exit 1
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$progdir"
echo 1 >/tmp/stay_awake
trap "rm -f /tmp/stay_awake" EXIT INT TERM HUP QUIT
RES_PATH="$progdir/res"

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

{
    echo "Toggling wifi..."
    if pgrep wpa_supplicant; then
        show.elf "$RES_PATH/disable.png" 2
        echo "Stopping wifi..."
        wifi_off
    else
        show.elf "$RES_PATH/enable.png" 2
        echo "Starting wifi..."
        wifi_on
    fi

    echo "Done toggling wifi!"
    show.elf "$RES_PATH/done.png" 2
} &> ./log.txt