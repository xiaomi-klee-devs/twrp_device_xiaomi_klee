#!/system/bin/sh
# Creates /dev/block/bootdevice/by-name/* symlinks expected by MTK
# firmware paths so fstab by-name lookups resolve on UFS and eMMC.

mkdir -p /dev/block/bootdevice/by-name
for p in /dev/block/by-name/*; do
    name=$(basename "$p")
    ln -sf "$p" "/dev/block/bootdevice/$name"
    ln -sf "$p" "/dev/block/bootdevice/by-name/$name"
done
