#!/system/bin/sh
MODDIR=${0%/*}
umask 077
exec /system/bin/sh "$MODDIR/discover.sh" boot >"$MODDIR/last-boot.log" 2>&1
