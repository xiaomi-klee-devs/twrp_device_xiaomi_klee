#!/usr/bin/env bash
# ============================================================================
# build-system-compatible-vendor-boot.sh - final vendor_boot repack
#
# Usage: tools/build-system-compatible-vendor-boot.sh [product_out] [output.img]
#
# The stock platform ramdisk fragment (prebuilt/stock_vendor_ramdisk.cpio.lz4)
# is unpacked and pruned of every binary the OrangeFox recovery fragment
# already provides, then repacked together with:
#   - patched DTB (tools/patch-vendor-boot-dtb.py drops USB offload nodes)
#   - the freshly built recovery.cpio.lz4 as a RECOVERY ramdisk fragment
# The result is AVB-signed and copied out as both
#   OrangeFox-R12.0-Unofficial-rodin-system-compatible.img  (flashable via OTA tools)
#   OrangeFox-R12.0-Unofficial-rodin.img (+ .md5)           (fastboot-friendly copy)
# ============================================================================
set -euo pipefail

DEVICE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TOP_DIR="$(cd -- "${DEVICE_DIR}/../../.." && pwd -P)"
PRODUCT_OUT="${1:-${OUT_DIR:-${TOP_DIR}/out}/target/product/rodin}"

STOCK_RAMDISK="${DEVICE_DIR}/prebuilt/stock_vendor_ramdisk.cpio.lz4"
DEFAULT_OUTPUT_IMAGE="${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-rodin-system-compatible.img"
OUTPUT_IMAGE="${2:-${DEFAULT_OUTPUT_IMAGE}}"
STOCK_DTB="${DEVICE_DIR}/prebuilt/dtb/mt6899-rodin.dtb"
RECOVERY_LZ4="${PRODUCT_OUT}/obj/PACKAGING/vendor_ramdisk_fragments_intermediates/recovery.cpio.lz4"
LZ4="${PRODUCT_OUT%/target/product/rodin}/host/linux-x86/bin/lz4"
MKBOOTIMG="${PRODUCT_OUT%/target/product/rodin}/host/linux-x86/bin/mkbootimg"
MKBOOTFS="${PRODUCT_OUT%/target/product/rodin}/host/linux-x86/bin/mkbootfs"
AVBTOOL="${PRODUCT_OUT%/target/product/rodin}/host/linux-x86/bin/avbtool"
DTB_PATCHER="${DEVICE_DIR}/tools/patch-vendor-boot-dtb.py"

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/rodin-vendor-boot.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

recovery_cpio="${work_dir}/recovery.cpio"
platform_cpio="${work_dir}/platform.cpio"
platform_root="${work_dir}/platform-root"
platform_pruned_cpio="${work_dir}/platform-pruned.cpio"
platform_pruned_lz4="${work_dir}/platform-pruned.cpio.lz4"
unsigned_image="${work_dir}/vendor_boot.img"
patched_dtb="${work_dir}/mt6899-rodin-no-usb-offload.dtb"

python3 "$DTB_PATCHER" --input "$STOCK_DTB" --output "$patched_dtb"
"$LZ4" -d -f "$RECOVERY_LZ4" "$recovery_cpio" >/dev/null
"$LZ4" -d -f "$STOCK_RAMDISK" "$platform_cpio" >/dev/null

mkdir -p "$platform_root"
(
    cd "$platform_root"
    cpio -idm --quiet --no-absolute-filenames < "$platform_cpio"
)
rm -rf "$platform_root/res"
rm -f \
    "$platform_root/miui.factoryreset.rc" \
    "$platform_root/system/bin/adbd" \
    "$platform_root/system/bin/fastbootd" \
    "$platform_root/system/bin/logcat" \
    "$platform_root/system/bin/logd" \
    "$platform_root/system/bin/recovery" \
    "$platform_root/system/bin/servicemanager" \
    "$platform_root/system/bin/sh" \
    "$platform_root/system/bin/toolbox" \
    "$platform_root/system/bin/toybox" \
    "$platform_root/system/bin/update_engine_sideload" \
    "$platform_root/system/bin/hw/android.hardware.boot-service.mtk_recovery" \
    "$platform_root/system/bin/hw/android.hardware.health-service.example_recovery" \
    "$platform_root/system/etc/init/android.hardware.boot-service.mtk_recovery.rc" \
    "$platform_root/system/etc/init/android.hardware.health-service.example_recovery.rc" \
    "$platform_root/system/etc/init/recovery-persist.rc" \
    "$platform_root/system/etc/init/recovery-refresh.rc" \
    "$platform_root/system/etc/init/servicemanager.recovery.rc" \
    "$platform_root/system/etc/recovery.fstab" \
    "$platform_root/system/etc/security/otacerts.zip" \
    "$platform_root/system/etc/vintf/manifest/android.hardware.boot-service.mtk.xml" \
    "$platform_root/system/etc/vintf/manifest/android.hardware.health-service.example.xml" \
    "$platform_root/system/lib64/librecovery_ui.so"

# curl -L https://raw.githubusercontent.com/xiaomi-mt6899-dev/android_device_xiaomi_rodin-kernel/refs/heads/lineage-23.2/vendor_ramdisk/mtk_battery_manager.ko \
#     -o "$platform_root/lib/modules/mtk_battery_manager.ko"

# curl -L https://raw.githubusercontent.com/xiaomi-mt6899-dev/android_device_xiaomi_rodin-kernel/refs/heads/lineage-23.2/vendor_ramdisk/panel-o10-36-02-0b-dsc-vdo.ko \
#     -o "$platform_root/lib/modules/panel-o10-36-02-0b-dsc-vdo.ko"

# curl -L https://raw.githubusercontent.com/xiaomi-mt6899-dev/android_device_xiaomi_rodin-kernel/refs/heads/lineage-23.2/vendor_ramdisk/panel-o10-42-02-0a-dsc-vdo.ko \
#     -o "$platform_root/lib/modules/panel-o10-42-02-0a-dsc-vdo.ko"

"$MKBOOTFS" -d "${PRODUCT_OUT}/system" "$platform_root" > "$platform_pruned_cpio"
"$LZ4" -l -12 --favor-decSpeed -f "$platform_pruned_cpio" "$platform_pruned_lz4" >/dev/null

VENDOR_BOOT_PARTITION_SIZE=67108864

"$MKBOOTIMG" \
    --dtb "$patched_dtb" \
    --base 0x3fff8000 \
    --pagesize 4096 \
    --vendor_cmdline "bootopt=64S3,32N2,64N2 erofs.reserved_pages=64" \
    --header_version 4 \
    --kernel_offset 0x00008000 \
    --ramdisk_offset 0x26f08000 \
    --tags_offset 0x07c88000 \
    --dtb_offset 0x07c88000 \
    --vendor_ramdisk "$platform_pruned_lz4" \
    --ramdisk_type RECOVERY \
    --ramdisk_name recovery \
    --vendor_ramdisk_fragment "$RECOVERY_LZ4" \
    --vendor_boot "$unsigned_image"

fingerprint="$(cat "${PRODUCT_OUT}/build_fingerprint.txt")"
"$AVBTOOL" add_hash_footer \
    --image "$unsigned_image" \
    --partition_size "$VENDOR_BOOT_PARTITION_SIZE" \
    --partition_name vendor_boot \
    --prop "com.android.build.vendor_boot.fingerprint:${fingerprint}"

mkdir -p "$(dirname "$OUTPUT_IMAGE")"
mv -f "$unsigned_image" "$OUTPUT_IMAGE"

cp -fp "$OUTPUT_IMAGE" "${PRODUCT_OUT}/vendor_boot.img"
cp -fp "$OUTPUT_IMAGE" "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-rodin.img"
md5sum "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-rodin.img" \
    > "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-rodin.img.md5"
rm -f \
    "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-rodin.zip" \
    "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-rodin.zip.md5"
