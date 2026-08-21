#!/usr/bin/env bash
set -euo pipefail

DEVICE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TOP_DIR="$(cd -- "${DEVICE_DIR}/../../.." && pwd -P)"
PRODUCT_OUT="${1:-${OUT_DIR:-${TOP_DIR}/out}/target/product/klee}"

STOCK_RAMDISK="${DEVICE_DIR}/prebuilt/vendor_ramdisk00"
DEFAULT_OUTPUT_IMAGE="${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee-system-compatible.img"
OUTPUT_IMAGE="${2:-${DEFAULT_OUTPUT_IMAGE}}"
STOCK_DTB="${DEVICE_DIR}/prebuilt/dtb/mt6899-klee.dtb"
RECOVERY_LZ4="${PRODUCT_OUT}/obj/PACKAGING/vendor_ramdisk_fragments_intermediates/recovery.cpio.lz4"
LZ4="${PRODUCT_OUT%/target/product/klee}/host/linux-x86/bin/lz4"
MKBOOTIMG="${PRODUCT_OUT%/target/product/klee}/host/linux-x86/bin/mkbootimg"
MKBOOTFS="${PRODUCT_OUT%/target/product/klee}/host/linux-x86/bin/mkbootfs"
AVBTOOL="${PRODUCT_OUT%/target/product/klee}/host/linux-x86/bin/avbtool"

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/klee-vendor-boot.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

recovery_cpio="${work_dir}/recovery.cpio"
platform_cpio="${work_dir}/platform.cpio"
platform_root="${work_dir}/platform-root"
platform_pruned_cpio="${work_dir}/platform-pruned.cpio"
platform_pruned_lz4="${work_dir}/platform-pruned.cpio.lz4"
unsigned_image="${work_dir}/vendor_boot.img"

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

"$MKBOOTFS" -d "${PRODUCT_OUT}/system" "$platform_root" > "$platform_pruned_cpio"
"$LZ4" -l -12 --favor-decSpeed -f "$platform_pruned_cpio" "$platform_pruned_lz4" >/dev/null

VENDOR_BOOT_PARTITION_SIZE=67108864

"$MKBOOTIMG" \
    --dtb "$STOCK_DTB" \
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
cp -fp "$OUTPUT_IMAGE" "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.img"
md5sum "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.img" \
    > "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.img.md5"
rm -f \
    "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.zip" \
    "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.zip.md5"
