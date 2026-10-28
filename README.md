# Ace 6T Discover

Enables Google Discover in the stock ColorOS launcher after each boot.

Tested on **OnePlus Ace 6T (PLR110), ColorOS 16.0.10.500(CN01)**.
Requires root, a KernelSU-compatible module manager, and the Google app.

The following secure settings must already be set:

- `assistant_screen_type=2`
- `assistant_screen_type_left_enable=1`

Build with `python3 build.py`, install the ZIP from `dist/`, then reboot.
Allow about 20–30 seconds after boot for Discover to appear.

The module changes one launcher feature record and exits. To restore
Quick Glance, disable or remove the module and reboot.

Author: **dtingley11**
