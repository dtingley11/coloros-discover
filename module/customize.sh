#!/system/bin/sh
ui_print '- Ace 6T stock launcher Discover: script-only module'
[ "$BOOTMODE" = true ] || abort 'Install from the root manager while Android is running.'
/system/bin/sh "$MODPATH/discover.sh" check || abort 'Unsupported firmware, feature records, or feed settings.'
set_perm_recursive "$MODPATH" 0 0 0755 0644
for script in boot-completed.sh discover.sh customize.sh uninstall.sh; do
    set_perm "$MODPATH/$script" 0 0 0755
done
ui_print '- No feature changes are made during installation.'
ui_print '- The single-record change runs after boot completion.'
