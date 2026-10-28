#!/system/bin/sh
MODDIR=${0%/*}
umask 077
# Android framework shell commands cannot receive descriptors for this
# private log file. Pass pipes to them and let cat alone open the file.
set -o pipefail
/system/bin/sh "$MODDIR/discover.sh" boot 2>&1 | /system/bin/cat >"$MODDIR/last-boot.log"
