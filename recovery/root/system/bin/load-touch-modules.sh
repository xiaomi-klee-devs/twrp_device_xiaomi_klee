#!/system/bin/sh

set +e

mod_dir="/vendor_dlkm/lib/modules"
modules=(
    "focaltech_touch_rodin.ko"
    "goodix_core_rodin.ko"
    "xiaomi_touch_rodin.ko"
)

mount /vendor_dlkm
for module in "${modules[@]}"; do
    insmod "${mod_dir}/${module}"
done
umount /vendor_dlkm
