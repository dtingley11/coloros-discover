# Ace 6T Discover

Enables Google Discover in the stock ColorOS launcher after each boot.

Tested on **OnePlus Ace 6T (PLR110), ColorOS 16.0.10.500(CN01)**.
Requires root, a KernelSU-compatible module manager, and the Google app.

First, turn off **Quick Glance** in Settings.

Set the required secure settings using ADB with root:

```sh
adb shell "su -c 'settings --user 0 put secure assistant_screen_type 2'"
adb shell "su -c 'settings --user 0 put secure assistant_screen_type_left_enable 1'"
```

Build with `python3 build.py`, install the ZIP from `dist/`, then reboot.
Discover is enabled once the feature provider and feed settings are ready.
The launcher refresh keeps your current app in front.

The module changes one launcher feature record and exits. To restore
Quick Glance, disable or remove the module and reboot.

Author: **dtingley11**
