# ============================================================================
# Product configuration - POCO X8 Pro / Redmi Turbo 5 (klee) OrangeFox recovery
# Everything installed here ends up inside the vendor_boot recovery ramdisk.
# ============================================================================

# ----------------------------------------------------------------------------
# Base product fragments
# - core_64_bit_only : arm64-only recovery build
# - base/emulated_storage : standard recovery bits + /sdcard emulation
# - virtual_ab_ota/* : virtual A/B with userspace snapshots (VAB compression)
# ----------------------------------------------------------------------------
DEVICE_PATH := device/xiaomi/klee

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression.mk)

# ----------------------------------------------------------------------------
# Shipping metadata
# Shipped with Android 14 (API 34); VNDK snapshot from Android 16 (36).
# ----------------------------------------------------------------------------
PRODUCT_SHIPPING_API_LEVEL := 34
PRODUCT_TARGET_VNDK_VERSION := 36

PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_USE_VIRTUAL_AB := true
PRODUCT_VIRTUAL_AB_OTA := true
PRODUCT_VIRTUAL_AB_COMPRESSION := true

# System properties set inside recovery:
# - FUSE passthrough for fast /data access on FUSE mounts
# - marks the tree as vendor_boot-based recovery
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.fuse.passthrough.enable=true \
    ro.twrp.vendor_boot=true

# ----------------------------------------------------------------------------
# A/B OTA
# Every partition that ships slot-suffixed (_a/_b). Includes all MTK firmware
# images (preloader, modem, DSPs, TEE...) so a full OTA switches both slots.
#
# Post-install hooks run on the NEW slot after an OTA:
#   system -> mtk_plpath_utils (rebuild MTK preloader path)
#   vendor -> checkpoint_gc   (finish data checkpoint cleanup)
# ----------------------------------------------------------------------------
AB_OTA_UPDATER := true
ENABLE_VIRTUAL_AB := true
TARGET_ENFORCE_AB_OTA_PARTITION_LIST := true
AB_OTA_PARTITIONS += \
    apusys \
    audio_dsp \
    boot \
    ccu \
    dpm \
    dtbo \
    gpueb \
    gz \
    lk \
    logo \
    mcf_ota \
    mcupm \
    md1img \
    mvpu_algo \
    odm \
    odm_dlkm \
    pi_img \
    preloader_raw \
    product \
    scp \
    spmfw \
    sspm \
    system \
    system_ext \
    tee \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor \
    vcp \
    vendor \
    vendor_boot \
    vendor_dlkm \
    mi_ext

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/mtk_plpath_utils \
    FILESYSTEM_TYPE_system=erofs \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=erofs \
    POSTINSTALL_OPTIONAL_vendor=true

# OTA engine pieces required inside recovery for sideloading virtual A/B OTAs.
PRODUCT_PACKAGES += \
    checkpoint_gc \
    update_engine \
    update_engine_sideload \
    update_verifier

# ----------------------------------------------------------------------------
# Health HAL (battery percentage in the recovery UI)
# ----------------------------------------------------------------------------
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-impl.recovery \
    android.hardware.health@2.1-service \
    android.hardware.health@2.1-service.rc

# ----------------------------------------------------------------------------
# Recovery tools & device-specific binaries
# - create_pl_dev          : dm-linear mapping of raw preloader partitions
# - fastbootd              : userspace fastboot for dynamic partitions
# - fsck.erofs/fsck.f2fs/make_f2fs : filesystem repair/format tools
# - lpdump/lpunpack        : inspect/unpack super partition images
# - snapuserd(+ramdisk)    : userspace snapshot daemon for VAB merges
# - klee_omapi_bridge      : OMAPI <-> eSE bridge for SIM-toolkit decryption
# - libklee_libcxx_compat  : libc++ verbose-abort shim shared by vendor HALs
# ----------------------------------------------------------------------------
PRODUCT_PACKAGES += \
    create_pl_dev \
    create_pl_dev.recovery \
    fastbootd \
    fsck.erofs \
    fsck.f2fs \
    klee_omapi_bridge \
    libklee_libcxx_compat \
    lpdump \
    lpunpack \
    make_f2fs \
    snapuserd \
    snapuserd_ramdisk

# ----------------------------------------------------------------------------
# Exclusions & debug extras
# - drop the legacy HIDL boot HAL (AIDL boot-service.mtk is used instead)
# - keep logcat in debug builds for diagnostics
# ----------------------------------------------------------------------------
PRODUCT_PACKAGES_DEBUG += logcat
PRODUCT_PACKAGES -= \
    android.hardware.boot@1.2-service
