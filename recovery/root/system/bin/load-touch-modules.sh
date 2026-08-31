#!/sbin/sh

set +e

mod_dir="/vendor_dlkm/lib/modules"
modules=(
    "nt38771_touch_rodin.ko"
    "xiaomi_touch_rodin.ko"
)

mount /vendor_dlkm
for module in "${modules[@]}"; do
    insmod "${mod_dir}/${module}"
done
umount /vendor_dlkm
