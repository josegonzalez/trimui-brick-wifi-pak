# trimui-brick-toggle-wifi.pak

A TrimUI Brick app that toggles wifi on or off.

> [!IMPORTANT]
> In some cases, the Trimui Brick may fail to connect to wifi while still displaying the wifi icon. Toggle the wifi off/on with this pak to reconnect if this is the case.

## Installation

1. Mount your TrimUI Brick SD card.
2. Download the latest release from Github. It will be named `Toggle.Wifi.pak.zip`.
3. Copy the zip file to `/Tools/tg3040/Toggle Wifi.pak.zip`.
4. Extract the zip in place, then delete the zip file.
5. Confirm that there is a `/Tools/tg3040/Toggle Wifi.pak/launch.sh` file on your SD card.
6. Unmount your SD Card and insert it into your TrimUI Brick.

## Usage

In the `/Tools/tg3040/Toggle Wifi.pak` folder, there will be a `wifi.txt` file. This file should store network credentials for accessing your wifi networks.

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
