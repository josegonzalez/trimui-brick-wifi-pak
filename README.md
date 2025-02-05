# trimui-brick-wifi.pak

A TrimUI Brick app that manages wifi connections.

> [!IMPORTANT]
> There is a known issue in MinUI prior to MinUI-20250126-0 where Wifi is partially toggled off on boot, though still shows the Wifi icon. Update to the latest version of MinUI to fix this.

## Installation

1. Mount your TrimUI Brick SD card.
2. Download the latest release from Github. It will be named `Wifi.pak.zip`.
3. Copy the zip file to `/Tools/tg5040/Wifi.pak.zip`.
4. Extract the zip in place, then delete the zip file.
5. Confirm that there is a `/Tools/tg5040/Wifi.pak/launch.sh` file on your SD card.
6. Unmount your SD Card and insert it into your TrimUI Brick.

> [!NOTE]
> The device directory changed from `/Tools/tg3040` to `/Tools/tg5040` in `MinUI-20250126-0` - released 2025-01-26. If you are using an older version of MinUI, use `/Tools/tg3040` instead.

## Usage

Browse to `Tools > Wifi` and press `A` to enter the wifi management screen. It will display your current wifi connection status, and allow you to scan for available networks as well as connect to them (with password entry).

### Customizing Wifi Credentials

> [!IMPORTANT]
> The Wifi pak exposes a UI for managing wifi networks, so this is only relevant for prepopulating the wifi credentials file.

In the root of your SD card, place a `wifi.txt` file. This file should store network credentials for accessing your wifi networks.

> [!NOTE]
> In previous versions of the pak, this file could also be located at `/Tools/tg5040/Wifi.pak/wifi.txt`. The old path is still supported - though deprecated - and users should migrate to the new path. New versions of the pak will transparently migrate the `wifi.txt` to the root of the SD card.

Format:

- colon (`:`) delimited key/value pair, where the key is the network name, and the value is the credential for the network.
- Empty lines and lines beginning with hashes (`#`) are ignored
- Whitespace is stripped from network names and credentials

The following is an example:

```shell
# awesome wifi for home
Minui Rules:shauninman-too

# the previous newline is ignored
madison:CatmillaNumber1
```

## Screenshots

<img src="screenshots/main-screen-disconnected.png" alt="Main screen (disconnected)" width="240"> <img src="screenshots/main-screen-connected.png" alt="Main screen (connected)" width="240"> <img src="screenshots/network-scanning.png" alt="Scanning for networks" width="240"> <img src="screenshots/network-list.png" alt="Network list" width="240"> <img src="screenshots/network-connecting.png" alt="Connecting to network" width="240"> <img src="screenshots/network-password.png" alt="Network password entry" width="240"> <img src="screenshots/network-enabling.png" alt="Enabling wifi" width="240">
