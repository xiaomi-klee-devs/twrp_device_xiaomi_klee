#!/system/bin/sh

logk() {
    echo "klee_fbe_prep: $*" > /dev/kmsg
}

logk "starting FINAL4 embedded-Weaver prep"

mount -o remount,rw /mnt/vendor/persist 2>/dev/null
if ! grep -q ' /mnt/vendor/persist .* rw,' /proc/mounts 2>/dev/null; then
    logk "ERROR: /mnt/vendor/persist is not rw"
    exit 20
fi
logk "persist is rw"

if [ ! -x /vendor/bin/hw/android.hardware.weaver ]; then
    logk "ERROR: embedded Xiaomi miweaver missing"
    exit 21
fi
if [ ! -f /vendor/lib64/vendor.xiaomi.hardware.cpace-V1-ndk.so ]; then
    logk "ERROR: embedded CPace library missing"
    exit 22
fi
if [ ! -f /vendor/mitee/ta/8aaaf201-2460-0010-aabbccdd00000006.ta ]; then
    logk "ERROR: embedded Weaver TA missing"
    exit 23
fi
logk "embedded Weaver components present"

i=0
while [ "$i" -lt 60 ]; do
    KM="$(getprop init.svc.vendor.keymint-mitee)"
    GK="$(getprop init.svc.vendor.gatekeeper_mitee)"
    TEE="$(getprop init.svc.tee-supplicant)"
    if grep -q ' /data ' /proc/mounts 2>/dev/null && [ "$KM" = "running" ] && [ "$GK" = "running" ] && [ "$TEE" = "running" ]; then
        break
    fi
    /system/bin/sleep 1
    i=$((i + 1))
done

if ! grep -q ' /data ' /proc/mounts 2>/dev/null; then
    logk "ERROR: /data did not mount; not starting Weaver"
    exit 24
fi
logk "crypto/data ready: tee=$TEE keymint=$KM gatekeeper=$GK"

WV="$(getprop init.svc.vendor.weaver_nxp)"
if [ "$WV" != "running" ]; then
    setprop ctl.start vendor.weaver_nxp
fi

i=0
while [ "$i" -lt 10 ]; do
    WV="$(getprop init.svc.vendor.weaver_nxp)"
    [ "$WV" = "running" ] && break
    /system/bin/sleep 1
    i=$((i + 1))
done
logk "weaver state=$WV pid=$(getprop init.svc_debug_pid.vendor.weaver_nxp)"

[ "$WV" = "running" ] || exit 25
exit 0
