#!/sbin/sh
# Loads the Novatek NT38771 touch driver and the Xiaomi touch framework.
# Both modules ship inside the recovery ramdisk (vendor_boot).

set +e

mod_dir="/lib/modules"
modules=(
    "nt38771_touch_klee.ko"
    "xiaomi_touch_klee.ko"
)

for module in "${modules[@]}"; do
    insmod "${mod_dir}/${module}" 2>/dev/null
done
