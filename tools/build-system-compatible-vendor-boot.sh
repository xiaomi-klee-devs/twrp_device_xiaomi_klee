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
DTB_PATCHER="${DEVICE_DIR}/tools/patch-vendor-boot-dtb.py"

for file in "$STOCK_RAMDISK" "$STOCK_DTB" "$RECOVERY_LZ4" "$LZ4" "$MKBOOTIMG" "$MKBOOTFS" "$AVBTOOL"; do
    if [ ! -f "$file" ]; then
        echo "missing required build input: $file" >&2
        exit 1
    fi
done

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/klee-vendor-boot.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

recovery_cpio="${work_dir}/recovery.cpio"
platform_cpio="${work_dir}/platform.cpio"
platform_root="${work_dir}/platform-root"
platform_pruned_cpio="${work_dir}/platform-pruned.cpio"
platform_pruned_lz4="${work_dir}/platform-pruned.cpio.lz4"
unsigned_image="${work_dir}/vendor_boot.img"
patched_dtb="${work_dir}/mt6899-klee-no-usb-offload.dtb"

python3 "$DTB_PATCHER" --input "$STOCK_DTB" --output "$patched_dtb"
"$LZ4" -d -f "$RECOVERY_LZ4" "$recovery_cpio" >/dev/null
"$LZ4" -d -f "$STOCK_RAMDISK" "$platform_cpio" >/dev/null

verify_recovery_elf() {
    local cpio_file="$1" archive_path="$2" extracted_file

    extracted_file="${work_dir}/$(basename "$archive_path")"
    if ! cpio -it --quiet < "$cpio_file" | grep -E "^(\./)?${archive_path}$" >/dev/null; then
        echo "recovery ramdisk is missing required ELF: $archive_path" >&2
        exit 1
    fi
    cpio -i --quiet --to-stdout "$archive_path" < "$cpio_file" > "$extracted_file"
    python3 - "$extracted_file" "$archive_path" <<'PY'
import pathlib
import sys

library = pathlib.Path(sys.argv[1])
archive_path = sys.argv[2]
if library.read_bytes()[:4] != b"\x7fELF":
    raise SystemExit(f"recovery ramdisk has invalid ELF: {archive_path}")
PY
}

verify_recovery_elf "$recovery_cpio" system/lib64/libprocessgroup_setup.so

verify_otg_platform_stack() {
    local root="$1" module

    for module in \
        charger_class.ko \
        extcon-mtk-usb.ko \
        mt6375-charger.ko \
        mtk_charger_framework.ko \
        mtu3.ko \
        tcpc_class.ko \
        tcpc_mt6375.ko \
        xhci-mtk-hcd-v2.ko; do
        if [ ! -f "$root/lib/modules/$module" ]; then
            echo "${FIRMWARE_VARIANT} platform ramdisk is missing OTG module: $module" >&2
            exit 1
        fi
    done

    if ! strings -a "$root/lib/modules/extcon-mtk-usb.ko" | grep -qx 'vbus_switch'; then
        echo "${FIRMWARE_VARIANT} extcon-mtk-usb lacks the vbus_switch control" >&2
        exit 1
    fi
}

module_count="$(cpio -it --quiet < "$recovery_cpio" | awk '/^lib\/modules\/.*\.ko$/ { count++ } END { print count + 0 }')"
if [ "$module_count" -gt 7 ]; then
    echo "recovery fragment still contains $module_count modules; expected at most 7" >&2
    exit 1
fi

# The stock platform fragment also contains a complete stock-recovery
# userspace. Normal Android boot never uses these files after /system is
# mounted, and the OrangeFox recovery fragment supplies its own copies. Drop
# only that recovery-only payload while retaining stock first-stage init,
# linker/runtime, SELinux policy, fstab, firmware, and every kernel module.
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

if find "$platform_root/system/etc/vintf/manifest" -maxdepth 1 -type f \
        -exec grep -l 'type="device"' {} + 2>/dev/null | grep -q .; then
    echo "pruned platform still contains a device VINTF fragment under /system" >&2
    exit 1
fi

for essential in \
    system/bin/init \
    system/bin/linker64 \
    system/lib64/libc.so \
    first_stage_ramdisk/fstab.mt6899 \
    lib/modules/modules.load; do
    if [ ! -f "$platform_root/$essential" ]; then
        echo "pruned platform is missing normal-boot file: $essential" >&2
        exit 1
    fi
done

platform_module_count="$(find "$platform_root/lib/modules" -maxdepth 1 -type f -name '*.ko' | wc -l)"
if [ "$platform_module_count" -ne 243 ]; then
    echo "pruned platform contains $platform_module_count modules; expected 243" >&2
    exit 1
fi

"$MKBOOTFS" -d "${PRODUCT_OUT}/system" "$platform_root" > "$platform_pruned_cpio"
"$LZ4" -l -12 --favor-decSpeed -f "$platform_pruned_cpio" "$platform_pruned_lz4" >/dev/null

VENDOR_BOOT_PARTITION_SIZE=67108864
HEADER_AND_FOOTER_OVERHEAD=1048576

max_ramdisk_size=$(( VENDOR_BOOT_PARTITION_SIZE - $(stat -c %s "$STOCK_DTB") - HEADER_AND_FOOTER_OVERHEAD ))
total_ramdisk_size=$(( $(stat -c %s "$platform_pruned_lz4") + $(stat -c %s "$RECOVERY_LZ4") ))
if [ "$total_ramdisk_size" -ge "$max_ramdisk_size" ]; then
    echo "combined vendor ramdisk is $total_ramdisk_size bytes; expected less than $max_ramdisk_size" >&2
    exit 1
fi

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

# OrangeFox creates these names before this post-build step. Replace both
# whole-image outputs so an ordinary vendorbootimage build cannot leave a
# recovery-only image that breaks Android boot. The installer ZIP still embeds
# the earlier recovery-only whole image, so withhold it until the installer is
# rebuilt after this system-compatible post-processing step.
cp -fp "$OUTPUT_IMAGE" "${PRODUCT_OUT}/vendor_boot.img"
cp -fp "$OUTPUT_IMAGE" "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.img"
md5sum "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.img" \
    > "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.img.md5"
rm -f \
    "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.zip" \
    "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.zip.md5"
