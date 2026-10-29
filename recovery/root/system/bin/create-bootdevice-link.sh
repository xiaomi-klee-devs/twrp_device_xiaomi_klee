#!/system/bin/sh
# Creates /dev/block/bootdevice/by-name/* symlinks for MTK firmware paths.

mkdir -p /dev/block/bootdevice/by-name
for p in /dev/block/by-name/*; do
    name=$(basename "$p")
    ln -sf "$p" "/dev/block/bootdevice/$name"
    ln -sf "$p" "/dev/block/bootdevice/by-name/$name"
done
