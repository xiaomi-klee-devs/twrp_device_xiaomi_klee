#!/system/bin/sh
# Loads the haptic kernel modules and probes which driver (aw8697 'awinic'
# or ICS) binds; publishes vendor.haptics.ready/driver props on success.

sleep 20

if ! grep -q '^haptic ' /proc/modules; then
    insmod /lib/modules/haptic.ko 2>/dev/null
fi

if ! grep -q '^aac_haptic ' /proc/modules; then
    insmod /lib/modules/aac_haptic.ko 2>/dev/null
fi

tries=0
while [ "${tries}" -lt 50 ]; do
    if [ -e /sys/bus/i2c/devices/0-005a/activate ]; then
        setprop vendor.haptics.ready 1
        setprop vendor.haptics.driver awinic
        exit 0
    fi

    if [ -e /sys/bus/i2c/devices/0-005f/activate ]; then
        setprop vendor.haptics.ready 1
        setprop vendor.haptics.driver ics
        exit 0
    fi

    tries=$((tries + 1))
    sleep 0.1
done

echo "No haptic driver bound (tried awinic, ics)" >&2
exit 2
