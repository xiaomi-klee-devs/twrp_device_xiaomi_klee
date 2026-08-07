#!/usr/bin/env bash
set -euo pipefail

DEVICE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TOP_DIR="$(cd -- "${DEVICE_DIR}/../../.." && pwd -P)"
PRODUCT_OUT="${1:-${OUT_DIR:-${TOP_DIR}/out}/target/product/klee}"

STOCK_RAMDISK="${DEVICE_DIR}/prebuilt/vendor_ramdisk00"
DEFAULT_OUTPUT_IMAGE="${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee-system-compatible.img"
OUTPUT_IMAGE="${2:-${DEFAULT_OUTPUT_IMAGE}}"
DEFAULT_DISABLE_AVB_OUTPUT_IMAGE="${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee-disable-avb-system-compatible.img"
DISABLE_AVB_OUTPUT_IMAGE="${3:-${DEFAULT_DISABLE_AVB_OUTPUT_IMAGE}}"
STOCK_DTB="${DEVICE_DIR}/prebuilt/dtb/mt6899-klee.dtb"
RECOVERY_LZ4="${PRODUCT_OUT}/obj/PACKAGING/vendor_ramdisk_fragments_intermediates/recovery.cpio.lz4"
LZ4="${PRODUCT_OUT%/target/product/klee}/host/linux-x86/bin/lz4"
MKBOOTIMG="${PRODUCT_OUT%/target/product/klee}/host/linux-x86/bin/mkbootimg"
MKBOOTFS="${PRODUCT_OUT%/target/product/klee}/host/linux-x86/bin/mkbootfs"
AVBTOOL="${PRODUCT_OUT%/target/product/klee}/host/linux-x86/bin/avbtool"
DTB_PATCHER="${DEVICE_DIR}/tools/patch-vendor-boot-dtb.py"

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/klee-vendor-boot.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

recovery_cpio="${work_dir}/recovery.cpio"
platform_cpio="${work_dir}/platform.cpio"
platform_root="${work_dir}/platform-root"
platform_pruned_cpio="${work_dir}/platform-pruned.cpio"
platform_pruned_lz4="${work_dir}/platform-pruned.cpio.lz4"
unsigned_image="${work_dir}/vendor_boot.img"
patched_dtb="${work_dir}/mt6899-klee-no-usb-offload.dtb"

disable_avb_platform_root="${work_dir}/disable-avb-platform-root"
disable_avb_platform_cpio="${work_dir}/disable-avb-platform.cpio"
disable_avb_platform_lz4="${work_dir}/disable-avb-platform.cpio.lz4"
disable_avb_unsigned_image="${work_dir}/vendor_boot-disable-avb.img"
disable_avb_bootconfig="${work_dir}/vendor-bootconfig-disable-avb.txt"

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

"$MKBOOTFS" -d "${PRODUCT_OUT}/system" "$platform_root" > "$platform_pruned_cpio"
"$LZ4" -l -12 --favor-decSpeed -f "$platform_pruned_cpio" "$platform_pruned_lz4" >/dev/null

strip_first_stage_avb_flags() {
    local root="$1" fstab_file
    find "$root/first_stage_ramdisk" -maxdepth 1 -type f -name 'fstab.*' -print0 |
    while IFS= read -r -d '' fstab_file; do
        awk 'BEGIN{OFS="\t"} /^[[:space:]]*#/ || NF<5 {print; next} {
            n=split($5,o,","); out="";
            for(i=1;i<=n;i++){
                if (o[i]=="avb" || o[i] ~ /^avb=/ || o[i] ~ /^avb_keys=/) continue;
                out = out (out=="" ? "" : ",") o[i];
            }
            $5=out; print
        }' "$fstab_file" > "${fstab_file}.tmp"
        mv -f "${fstab_file}.tmp" "$fstab_file"
    done
}

mkdir -p "$disable_avb_platform_root"
cp -a "$platform_root/." "$disable_avb_platform_root/"
strip_first_stage_avb_flags "$disable_avb_platform_root"

"$MKBOOTFS" -d "${PRODUCT_OUT}/system" "$disable_avb_platform_root" > "$disable_avb_platform_cpio"
"$LZ4" -l -12 --favor-decSpeed -f "$disable_avb_platform_cpio" "$disable_avb_platform_lz4" >/dev/null

VENDOR_BOOT_PARTITION_SIZE=67108864
fingerprint="$(cat "${PRODUCT_OUT}/build_fingerprint.txt")"

build_vendor_boot() {
    local image="$1" bootconfig="$2" platform_lz4="$3"
    local -a args=(
        --dtb "$patched_dtb"
        --base 0x3fff8000
        --pagesize 4096
        --vendor_cmdline "bootopt=64S3,32N2,64N2 erofs.reserved_pages=64"
        --header_version 4
        --kernel_offset 0x00008000
        --ramdisk_offset 0x26f08000
        --tags_offset 0x07c88000
        --dtb_offset 0x07c88000
        --vendor_ramdisk "$platform_lz4"
        --ramdisk_type RECOVERY
        --ramdisk_name recovery
        --vendor_ramdisk_fragment "$RECOVERY_LZ4"
    )
    [ -n "$bootconfig" ] && args+=(--vendor_bootconfig "$bootconfig")
    args+=(--vendor_boot "$image")
    "$MKBOOTIMG" "${args[@]}"
    "$AVBTOOL" add_hash_footer \
        --image "$image" \
        --partition_size "$VENDOR_BOOT_PARTITION_SIZE" \
        --partition_name vendor_boot \
        --prop "com.android.build.vendor_boot.fingerprint:${fingerprint}"
}

build_vendor_boot "$unsigned_image" "" "$platform_pruned_lz4"

cat > "$disable_avb_bootconfig" <<'EOF'
androidboot.vbmeta.device_state := "unlocked"
androidboot.verifiedbootstate := "orange"
androidboot.flash.locked := "0"
EOF
build_vendor_boot "$disable_avb_unsigned_image" "$disable_avb_bootconfig" "$disable_avb_platform_lz4"

mkdir -p "$(dirname "$OUTPUT_IMAGE")"
mv -f "$unsigned_image" "$OUTPUT_IMAGE"
mkdir -p "$(dirname "$DISABLE_AVB_OUTPUT_IMAGE")"
mv -f "$disable_avb_unsigned_image" "$DISABLE_AVB_OUTPUT_IMAGE"

cp -fp "$OUTPUT_IMAGE" "${PRODUCT_OUT}/vendor_boot.img"
cp -fp "$OUTPUT_IMAGE" "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.img"
md5sum "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.img" \
    > "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.img.md5"

cp -fp "$DISABLE_AVB_OUTPUT_IMAGE" "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee-disable-avb.img"
md5sum "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee-disable-avb.img" \
    > "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee-disable-avb.img.md5"

rm -f \
    "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.zip" \
    "${PRODUCT_OUT}/OrangeFox-R12.0-Unofficial-klee.zip.md5"
