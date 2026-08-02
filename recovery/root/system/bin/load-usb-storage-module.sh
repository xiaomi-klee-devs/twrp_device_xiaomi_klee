set +e
mod_dir="/vendor_dlkm/lib/modules"
modules=(
  usb_offload.ko
)

mount /vendor_dlkm
for module in "${modules[@]}"; do
  insmod $mod_dir/$module
done
umount /vendor_dlkm
