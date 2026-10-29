#!/usr/bin/env bash
# Repacks vendor_boot with the patched DTB and the built recovery fragment.
set -euo pipefail

DEVICE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TOP_DIR="$(cd -- "${DEVICE_DIR}/../../.." && pwd -P)"
PRODUCT_OUT="${1:-${OUT_DIR:-${TOP_DIR}/out}/target/product/klee}"
OUTPUT_IMAGE="${2:-${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee-system-compatible.img}"

HOST_BIN="${PRODUCT_OUT%/target/product/klee}/host/linux-x86/bin"
MKBOOTIMG="${HOST_BIN}/mkbootimg"
AVBTOOL="${HOST_BIN}/avbtool"

STOCK_DTB="${DEVICE_DIR}/prebuilt/dtb/mt6899-klee.dtb"
DTB_PATCHER="${DEVICE_DIR}/tools/patch-vendor-boot-dtb.py"
PLATFORM_LZ4="${DEVICE_DIR}/prebuilt/stock_vendor_ramdisk.cpio.lz4"
RECOVERY_LZ4="${PRODUCT_OUT}/obj/PACKAGING/vendor_ramdisk_fragments_intermediates/recovery.cpio.lz4"

VENDOR_BOOT_PARTITION_SIZE=67108864

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/klee-vendor-boot.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

unsigned_image="${work_dir}/vendor_boot.img"
patched_dtb="${work_dir}/mt6899-klee-no-usb-offload.dtb"

python3 "$DTB_PATCHER" --input "$STOCK_DTB" --output "$patched_dtb"

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
    --vendor_ramdisk "$PLATFORM_LZ4" \
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

rm -f \
    "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.zip" \
    "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.zip.md5"
