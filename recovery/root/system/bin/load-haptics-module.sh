#!/system/bin/sh
sleep 20

if ! grep -q '^haptic ' /proc/modules; then
    insmod /lib/modules/haptic.ko || exit 1
fi

tries=0
while [ "${tries}" -lt 50 ]; do
    if [ -e /sys/bus/i2c/drivers/awinic_haptic/0-005a/activate ]; then
        setprop vendor.haptics.ready 1
        exit 0
    fi
    tries=$((tries + 1))
    sleep 0.1
done

echo "AWINIC did not bind" >&2
exit 2
