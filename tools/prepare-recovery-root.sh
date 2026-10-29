#!/bin/bash
# ============================================================================
# prepare-recovery-root.sh - OrangeFox BOARD_RECOVERY_IMAGE_PREPARE hook
#
# Called once (with --first-call) right after the recovery ramdisk is
# assembled. Slims the ramdisk so vendor_boot stays under 64 MiB:
#   1. refresh libminuitwrp.so from the current build output
#   2. force MiSans font in all theme XMLs, drop unused fonts
#   3. keep only the languages this build ships
#   4. debloat /system/lib64 libraries that nothing in the image references
#   5. remove lpdump/snapshot daemons superseded by lptools
#   6. strip .gnu_debugdata sections, UPX-pack selected binaries
#   7. move /sbin duplicates into /system/bin (symlinked back)
#   8. trim terminfo to ansi/linux/vt100/xterm/xterm-256color
#
# NOTE: upx_binaries below must exist or the build FAILS on purpose - keep it
# in sync with what TWRP/OFOX install into /system/bin.
# ============================================================================
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

# ---------------------------------------------------------------------------
# Debloat /system/lib64.
#
# Every entry below has been checked against a full klee recovery ramdisk:
# no executable, HAL or remaining library references it through DT_NEEDED or
# a dlopen string. The verifier below re-checks the assembled ramdisk and
# aborts the build if a package/toolchain update starts needing one of them.
#
# Do NOT add libraries that are referenced only at runtime by name (LD_PRELOAD,
# dlopen, HAL manifests) without re-checking the resulting ramdisk.
# Keep libc++_hos.so (LD_PRELOAD in init.recovery.keymint.rc), libcap.so (logd),
# libhidltransport.so (vendor compatibility), and the health/keymaster/
# gatekeeper/weaver/boot stubs that recovery or libtar still link.
# ---------------------------------------------------------------------------
debloat_lib64=(
    # Full adbd service/API stack. This image's adbd and minadbd only link
    # libadbd_auth/libadbd_fs, so the implementation libs are dead weight.
    libadbd.so
    libadbd_services.so
    libadbconnection_server.so
    libadb_protos.so
    libapp_processes_protos_lite.so
    libadb_crypto.so
    libadb_tls_connection.so
    libadb_sysdeps.so
    libcutils_sockets.so
    libmdnssd.so

    # Not pulled in by recovery, TWRP, or any retained HAL.
    libandroid_runtime_lazy.so
    libext2_profile.so
    libfs_mgr_binder.so
    libnl.so
    libnos_datagram.so
    libnos_transport.so
    libservices.so
    libsoftkeymasterdevice.so
    libutilscallstack.so
    libxml2.so

    # HIDL/AIDL stubs for HALs recovery never talks to.
    android.frameworks.stats-V1-ndk.so
    android.hardware.vibrator@1.0.so
    android.hardware.vibrator@1.1.so
    android.hardware.vibrator@1.2.so
    android.hardware.vibrator-V1-cpp.so
    android.hardware.vibrator-V1-ndk.so
    android.hardware.vibrator-V2-cpp.so
    android.hardware.vibrator-V2-ndk.so
    android.system.keystore2-V3-ndk.so
    android.system.suspend@1.0.so
    android.system.wifi.keystore@1.0.so
)

removed_lib64=()
for name in "${debloat_lib64[@]}"; do
    lib="$ramdisk/system/lib64/$name"
    if [ -f "$lib" ]; then
        rm -f "$lib"
        removed_lib64+=("$name")
    fi
done

if [ "${#removed_lib64[@]}" -gt 0 ]; then
    removed_list="$(mktemp)"
    trap 'rm -f "$removed_list"' EXIT
    printf '%s\n' "${removed_lib64[@]}" > "$removed_list"

    while IFS= read -r -d '' binary; do
        file "$binary" | grep -q ELF || continue
        if "$readelf_bin" -d "$binary" 2>/dev/null |
                grep 'Shared library:' |
                sed 's/.*\[\([^]]*\)\].*/\1/' |
                grep -Fxf "$removed_list" >/dev/null ||
                strings -a "$binary" 2>/dev/null |
                grep -Fxf "$removed_list" >/dev/null; then
            echo "debloat: $binary still references a removed library" >&2
            exit 1
        fi
    done < <(find "$ramdisk/system" "$ramdisk/sbin" "$ramdisk/vendor" -type f -print0)

    echo "-- Debloated ${#removed_lib64[@]} unused libraries from /system/lib64"
    rm -f "$removed_list"
    trap - EXIT
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
