set +e
mod_dir="/vendor_dlkm/lib/modules"
modules=(
  focaltech_touch_klee.ko
  xiaomi_touch_klee.ko
  goodix_core_klee
)

mount /vendor_dlkm
# load modules
for module in "${modules[@]}"; do
  insmod $mod_dir/$module
done
umount /vendor_dlkm