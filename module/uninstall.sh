#!/system/bin/sh
MODDIR=${0%/*}
# During early-boot removal the provider is not ready. ColorOS rebuilds
# the original CN feature itself; do not start system apps during early boot.
if [ "$(/system/bin/getprop sys.boot_completed)" = 1 ]; then
    /system/bin/sh "$MODDIR/discover.sh" restore
fi
