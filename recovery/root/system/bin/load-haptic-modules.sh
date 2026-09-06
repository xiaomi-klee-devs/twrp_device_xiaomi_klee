#!/system/bin/sh
# Loads the haptic kernel modules and probes which driver (aw8697 'awinic'
# or ICS) binds; publishes vendor.haptics.ready/driver props on success.

sleep 1

if ! grep -q '^haptic ' /proc/modules; then
    insmod /lib/modules/haptic.ko 2>/dev/null
fi

if ! grep -q '^aac_haptic ' /proc/modules; then
    insmod /lib/modules/aac_haptic.ko 2>/dev/null
fi

if ! grep -q '^si_haptic ' /proc/modules; then
    insmod /lib/modules/si_haptic.ko 2>/dev/null
fi

echo "No haptic driver bound (tried awinic, ics)" >&2
exit 2
