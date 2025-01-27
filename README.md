# trimui-brick-toggle-wifi.pak

A TrimUI Brick app that toggles wifi on or off.

> [!IMPORTANT]
> There is a known issue in MinUI where Wifi is partially toggled off on boot, though still shows the Wifi icon. If you are unable to access services on the Brick, toggle wifi off and then on again using this app first.

## Installation

1. Mount your TrimUI Brick SD card.
2. Download the latest release from Github. It will be named `Toggle.Wifi.pak.zip`.
3. Copy the zip file to `/Tools/tg3040/Toggle Wifi.pak.zip`. Please ensure the new zip file name is `Toggle Wifi.pak.zip`, without a dot (`.`) between the words `Toggle` and `Wifi`.
4. Extract the zip in place, then delete the zip file.
5. Confirm that there is a `/Tools/tg3040/Toggle Wifi.pak/launch.sh` file on your SD card.
6. Unmount your SD Card and insert it into your TrimUI Brick.

## Usage

> [!IMPORTANT]
> If the zip file was not extracted correctly, the pak may show up under `Tools > Toggle`. Rename the folder to `Toggle Wifi.pak` to fix this.

Browse to `Tools > Toggle Wifi` and press `A` to toggle wifi on/off.

### Customizing Wifi Credentials

In the root of your SD card, place a `wifi.txt` file. This file should store network credentials for accessing your wifi networks.

> [!NOTE]
> In previous versions of the pak, this file could also be located at `/Tools/tg3040/Toggle Wifi.pak/wifi.txt`. The old path is still supported - though deprecated - and users should migrate to the new path. New versions of the pak will transparently migrate the `wifi.txt` to the root of the SD card.

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
