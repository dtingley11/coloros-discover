#!/system/bin/sh
# This device-specific fix only renames one existing feature record.
MODDIR=${0%/*}
EXPECTED_BUILD='PLR110_16.0.10.500(CN01)'
URI='content://com.oplus.customize.coreapp.configmanager.configprovider.AppFeatureProvider/app_feature'
CN='com.android.launcher.CN_VERSION'
GOOGLE='com.android.launcher.OVERLAY_GOOGLE_DISCOVER'
CN_ROW="Row: 0 _id=245, featurename=$CN, parameters=NULL, lists=NULL"
GOOGLE_ROW="Row: 0 _id=245, featurename=$GOOGLE, parameters=NULL, lists=NULL"

log() { printf '%s %s\n' "$(/system/bin/date -u +%FT%TZ)" "$*"; }
fail() { log "ERROR: $*"; return 1; }
enabled() { [ -f "$MODDIR/module.prop" ] && [ ! -e "$MODDIR/disable" ] && [ ! -e "$MODDIR/remove" ]; }
read_state() {
    # Fetch both names and the guarded row in one provider call. Extra or
    # altered records still fail the exact comparison below.
    feature_row=$(/system/bin/timeout 10 /system/bin/content query --user 0 --uri "$URI" \
        --where "_id=245 OR featurename='$CN' OR featurename='$GOOGLE'") || return 1
    if [ "$feature_row" = "$CN_ROW" ]; then
        state=stock
    elif [ "$feature_row" = "$GOOGLE_ROW" ]; then
        state=discover
    else
        state=unexpected
        return 1
    fi
}
guard() {
    [ "$(/system/bin/id -u)" = 0 ] || { fail 'Root is required'; return 1; }
    [ "$(/system/bin/getprop ro.build.display.id)" = "$EXPECTED_BUILD" ] || {
        fail 'Firmware changed; leave configuration untouched'; return 1;
    }
    [ "$(/system/bin/getprop sys.boot_completed)" = 1 ] || {
        fail 'Android has not finished booting'; return 1;
    }
}
feed_settings_ok() {
    # Deliberately read only: these two settings already survive reboot.
    [ "$(/system/bin/timeout 10 /system/bin/settings --user 0 get secure assistant_screen_type)" = 2 ] &&
    [ "$(/system/bin/timeout 10 /system/bin/settings --user 0 get secure assistant_screen_type_left_enable)" = 1 ]
}
rename() {
    /system/bin/timeout 10 /system/bin/content update --user 0 --uri "$URI" \
        --bind "featurename:s:$2" \
        --where "_id=245 AND featurename='$1' AND parameters IS NULL AND lists IS NULL"
}
restart_launcher() {
    foreground=$(/system/bin/timeout 10 /system/bin/dumpsys activity activities) || return 1
    foreground=$(printf '%s\n' "$foreground" | /system/bin/grep 'topResumedActivity=')
    relaunch_home=0
    case "$foreground" in
        *'
'*) ;; # Multiple resumed displays: do not choose a foreground app for the user.
        *' u0 com.android.launcher/'*) relaunch_home=1 ;;
    esac
    /system/bin/timeout 10 /system/bin/am force-stop --user 0 com.android.launcher || return 1
    if [ "$relaunch_home" = 1 ]; then
        /system/bin/timeout 10 /system/bin/am start --user 0 \
            -a android.intent.action.MAIN -c android.intent.category.HOME -p com.android.launcher
    else
        log 'Launcher stopped in background; keeping the current app in front'
    fi
}
restore_feature() {
    guard || return 1
    read_state || { fail 'Unexpected feature records; refusing restoration'; return 1; }
    if [ "$state" = stock ]; then log 'Original feature is already present'; return 0; fi
    rename "$GOOGLE" "$CN" || return 1
    read_state && [ "$state" = stock ] || { fail 'Could not verify restored feature'; return 1; }
    log 'Restored original CN_VERSION feature; feed settings were not changed'
    restart_launcher
}
apply_feature() {
    guard && enabled || return 1
    feed_settings_ok || { fail 'Feed settings changed; leave them untouched'; return 1; }
    read_state || { fail 'Unexpected feature records; leave them untouched'; return 1; }
    if [ "$state" = discover ]; then log 'Discover feature already present; no restart needed'; return 0; fi
    log 'Renaming only feature row 245 from CN_VERSION to OVERLAY_GOOGLE_DISCOVER'
    rename "$CN" "$GOOGLE" || return 1
    if ! read_state || [ "$state" != discover ]; then
        # Attempt only the inverse of our exact guarded operation.
        rename "$GOOGLE" "$CN"
        fail 'Feature verification failed; attempted inverse rename'
        return 1
    fi
    if ! restart_launcher; then
        rename "$GOOGLE" "$CN"
        fail 'Launcher restart failed; attempted inverse rename'
        return 1
    fi
    log 'Discover feature verified; launcher refreshed'
}
boot_apply() {
    guard && enabled || return 1
    log 'Waiting for feature/settings initialization after boot'
    # Check readiness immediately, then require three matching samples.
    # Polling is bounded to 30 samples rather than a daemon.
    previous=''
    stable=0
    sample=0
    while [ "$sample" -lt 30 ]; do
        enabled || return 0
        if read_state; then
            if [ "$state" = "$previous" ]; then stable=$((stable + 1)); else stable=0; fi
            previous=$state
            if [ "$stable" -ge 2 ] && feed_settings_ok; then break; fi
        else
            stable=0
            previous=''
        fi
        sample=$((sample + 1))
        /system/bin/sleep 1
    done
    [ "$sample" -lt 30 ] || { fail 'Feature provider/settings did not settle; no change made'; return 1; }
    apply_feature || return 1
    # Brief verification during this boot only. No launcher/process watcher.
    for delay in 2 8; do
        /system/bin/sleep "$delay"
        enabled || return 0
        read_state && [ "$state" = discover ] || {
            fail 'ColorOS reset the feature again; stop rather than repeatedly restart launcher'; return 1;
        }
    done
    log 'Boot-time change verified; exiting'
}

case "${1:-check}" in
    check)
        guard && read_state || exit 1
        log "Feature state: $state"
        feed_settings_ok || { fail 'Expected feed settings 2/1 are absent'; exit 1; }
        ;;
    apply) apply_feature || exit 1 ;;
    boot) boot_apply || exit 1 ;;
    restore) restore_feature || exit 1 ;;
    *) printf 'Usage: %s check|apply|boot|restore\n' "$0"; exit 2 ;;
esac
