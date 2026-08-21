#!/bin/bash

set -e

ramdisk="$1"
phase="$2"
terminfo="$ramdisk/system/etc/terminfo"

if [ "$phase" != "--first-call" ]; then
    exit 0
fi

product_out="$(dirname "$(dirname "$ramdisk")")"
minuitwrp_src="$product_out/system/lib64/libminuitwrp.so"
minuitwrp_dst="$ramdisk/system/lib64/libminuitwrp.so"
if [ -f "$minuitwrp_src" ]; then
    echo "-- Refreshing recovery libminuitwrp.so from the current build output"
    cp -fp "$minuitwrp_src" "$minuitwrp_dst"
fi

if [ -d "$ramdisk/lib/modules" ]; then
    find "$ramdisk/lib/modules" -maxdepth 1 -type f -name '*.ko' -print0 |
        while IFS= read -r -d '' module; do
            case "$(basename "$module")" in
                nt38771_touch_klee.ko|xiaomi_touch_klee.ko|nxp_i2c.ko|p73.ko|spi-mt65xx.ko|irq-dbg.ko|haptic.ko|miev.ko)
                    ;;
                *)
                    rm -f "$module"
                    ;;
            esac
        done
fi

if [ -d "$ramdisk/twres/fonts" ]; then
    find "$ramdisk/twres" -type f -name '*.xml' -print0 |
        xargs -0 sed -Ei 's/filename="[^"]+\.(ttf|otf|ttc)"/filename="MiSans.ttf"/g'
    find "$ramdisk/twres/fonts" -maxdepth 1 -type f \
        ! -iname 'MiSans.ttf' \
        ! -iname '*Noto*.ttf' \
        ! -iname '*Noto*.otf' \
        ! -iname '*Noto*.ttc' \
        -delete
fi

if [ -d "$ramdisk/twres/languages" ]; then
    find "$ramdisk/twres/languages" -maxdepth 1 -type f \
        ! -name en.xml \
        ! -name es_ES.xml \
        ! -name hu_HU.xml \
        ! -name ja_JP.xml \
        ! -name zh_CN.xml \
        ! -name zh_TW.xml \
        -delete
fi

rm -f \
    "$ramdisk/system/bin/lpdump" \
    "$ramdisk/system/bin/lpdumpd" \
    "$ramdisk/system/etc/init/lpdumpd.rc" \
    "$ramdisk/system/lib64/liblpdump.so" \
    "$ramdisk/system/lib64/liblpdump_interface-cpp.so" \
    "$ramdisk/system/lib64/libprotobuf-cpp-full.so" \
    "$ramdisk/system/lib64/libsnapshot.so"

objcopy_bin="prebuilts/clang/host/linux-x86/clang-r510928/bin/llvm-objcopy"
readelf_bin="prebuilts/clang/host/linux-x86/clang-r510928/bin/llvm-readelf"
if [ ! -x "$objcopy_bin" ] || [ ! -x "$readelf_bin" ]; then
    echo "missing LLVM ELF tools" >&2
    exit 1
fi
while IFS= read -r -d '' binary; do
    if file "$binary" | grep -q ELF && \
            "$readelf_bin" -SW "$binary" 2>/dev/null | grep -q '\.gnu_debugdata'; then
        "$objcopy_bin" --remove-section=.gnu_debugdata "$binary"
    fi
done < <(find "$ramdisk/system" -type f -print0)

upx_bin="vendor/recovery/tools/upx"
if [ ! -x "$upx_bin" ]; then
    echo "missing UPX: $upx_bin" >&2
    exit 1
fi
upx_binaries=(
    avbctl awk bc bootctl bu charger create_pl_dev dump_image e2fsck
    e2fsdroid erase_image exfat-fuse fastbootd fatlabel flash_image fsck.exfat
    fsck.f2fs fsck.fat fscryptpolicyget grep keystore2 keystore_cli_v2 logcat
    logd lptools lzma make_f2fs minadbd mke2fs mkexfatfs mkfs.fat nano
    ozip_decrypt pigz reboot recovery resetprop resize2fs klee_omapi_bridge
    sgdisk simg2img sload_f2fs tune2fs twrp update_engine_sideload vold_prepare_subdirs
    watchdogd ziptool android.hardware.boot@1.2-service
)
for name in "${upx_binaries[@]}"; do
    binary="$ramdisk/system/bin/$name"
    if [ ! -f "$binary" ]; then
        echo "missing selected UPX binary: $binary" >&2
        exit 1
    fi
    chmod 0755 "$binary"
    "$upx_bin" -q --lzma "$binary" >/dev/null
    "$upx_bin" -q -t "$binary" >/dev/null
done

while IFS= read -r -d '' source; do
    name="$(basename "$source")"
    target="$ramdisk/system/bin/$name"
    if [ "$name" = nano ] && [ -f "$target" ]; then
        rm -f "$source"
    else
        rm -f "$target"
        mv "$source" "$target"
    fi
    ln -s "/system/bin/$name" "$source"
done < <(find "$ramdisk/sbin" -maxdepth 1 -type f -print0)

if [ -d "$terminfo" ]; then
    keep_dir=$(mktemp -d)
    trap 'rm -rf "$keep_dir"' EXIT

    for entry in a/ansi l/linux v/vt100 x/xterm x/xterm-256color; do
        if [ -f "$terminfo/$entry" ]; then
            mkdir -p "$keep_dir/$(dirname "$entry")"
            cp -p "$terminfo/$entry" "$keep_dir/$entry"
        fi
    done

    rm -rf "$terminfo"
    mv "$keep_dir" "$terminfo"
    trap - EXIT
fi

rm -f "$ramdisk/ramdisk-files.txt" "$ramdisk/ramdisk-files.sha256sum"
