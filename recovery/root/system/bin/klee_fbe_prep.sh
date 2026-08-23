#!/system/bin/sh
# Embedded-Weaver bring-up: waits until /data + TEE/keymint/gatekeeper are
# up, then starts the country-appropriate Weaver backend
# (CN -> Xiaomi weaver, Global -> NXP weaver + authsecret chain).
# Exit codes 20-25 signal which stage failed.

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

COUNTRY="$(getprop ro.boot.ptcountrycode)"
if [ "$COUNTRY" = "cn" ] || [ "$COUNTRY" = "CN" ]; then
    logk "weaver selector: country=$COUNTRY backend=xiaomi"
    WV="$(getprop init.svc.vendor.weaver_xiaomi)"
    if [ "$WV" != "running" ]; then
        setprop ctl.start vendor.weaver_xiaomi
    fi

    i=0
    while [ "$i" -lt 10 ]; do
        WV="$(getprop init.svc.vendor.weaver_xiaomi)"
        [ "$WV" = "running" ] && break
        /system/bin/sleep 1
        i=$((i + 1))
    done
    logk "CN Xiaomi Weaver state=$WV pid=$(getprop init.svc_debug_pid.vendor.weaver_xiaomi)"
    [ "$WV" = "running" ] || exit 25
else
    logk "weaver selector: country=${COUNTRY:-unknown} backend=nxp"
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
    logk "weaver pre-authsecret state=$WV pid=$(getprop init.svc_debug_pid.vendor.weaver_nxp)"
    [ "$WV" = "running" ] || exit 25

    /system/bin/sleep 1

    AS="$(getprop init.svc.miweaver_hal_service)"
    if [ "$AS" != "running" ]; then
        setprop ctl.start miweaver_hal_service
    fi
    i=0
    while [ "$i" -lt 10 ]; do
        AS="$(getprop init.svc.miweaver_hal_service)"
        [ "$AS" = "running" ] && break
        /system/bin/sleep 1
        i=$((i + 1))
    done
    logk "authsecret post-weaver state=$AS pid=$(getprop init.svc_debug_pid.miweaver_hal_service)"
fi
exit 0
