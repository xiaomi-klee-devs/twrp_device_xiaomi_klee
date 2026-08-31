# ============================================================================
# OrangeFox Recovery device tree - Xiaomi POCO X7 Pro / Redmi Turbo 4 (rodin)
# Platform: MediaTek Dimensity 8400-Ultra (MT6899), Android 16, A/B, virtual AB
# ============================================================================
DEVICE_PATH := device/xiaomi/rodin

# ----------------------------------------------------------------------------
# SELinux
# Device-specific policy: UFS bootctl access rules + block device labels.
# ----------------------------------------------------------------------------
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy

# ----------------------------------------------------------------------------
# CPU architecture
# MT6899: big.LITTLE Cortex-A725/A55 class cores; 64-bit primary,
# 32-bit ARMv8 secondary ABI kept for vendor blobs compatibility.
# ----------------------------------------------------------------------------
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a55
TARGET_CPU_VARIANT_RUNTIME := cortex-a55

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55

# ----------------------------------------------------------------------------
# SoC / bootloader identity
# - TARGET_OTA_ASSERT_DEVICE : refuse to flash builds meant for other devices
# - TARGET_NO_BOOTLOADER     : we never build/flash the bootloader
# - BOARD_USES_MTK_HARDWARE  : enable MediaTek-specific HAL handling in TWRP
# ----------------------------------------------------------------------------
TARGET_BOARD_PLATFORM := mt6899
TARGET_BOOTLOADER_BOARD_NAME := mt6899
TARGET_OTA_ASSERT_DEVICE := rodin
TARGET_NO_BOOTLOADER := true
TARGET_NO_KERNEL := true
TARGET_NO_RECOVERY := true
BOARD_USES_MTK_HARDWARE := true

# ----------------------------------------------------------------------------
# Kernel / DTB (prebuilt only - no kernel source is compiled)
# Recovery lives entirely inside vendor_boot (GKI layout):
#   - BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE / MOVE_RECOVERY_RESOURCES...
#     tell the build that kernel+recovery are delivered via vendor_boot.
#   - BOARD_RAMDISK_USE_LZ4 : vendor_boot ramdisks must be LZ4-compressed.
# ----------------------------------------------------------------------------
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb/mt6899-rodin.dtb
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
BOARD_RAMDISK_USE_LZ4 := true
BOARD_KERNEL_SEPARATED_DTBO := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true

# Touch controller kernel modules loaded from vendor_boot at boot time
# (Novatek NT38771 panel touch + Xiaomi touch framework).
TW_LOAD_VENDOR_BOOT_MODULES := true
TW_LOAD_VENDOR_MODULES := "nt38771_touch_rodin.ko xiaomi_touch_rodin.ko"
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true

# ----------------------------------------------------------------------------
# Boot image header (boot/vendor_boot header v4, MTK packing offsets)
# BOARD_MKBOOTIMG_ARGS feeds mkbootimg when repacking vendor_boot.
# ----------------------------------------------------------------------------
BOARD_VENDOR_CMDLINE := bootopt=64S3,32N2,64N2 erofs.reserved_pages=64
BOARD_KERNEL_BASE := 0x3fff8000
BOARD_PAGE_SIZE := 4096
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x26f08000
BOARD_TAGS_OFFSET := 0x07c88000
BOARD_BOOT_HEADER_VERSION := 4
BOARD_HEADER_SIZE := 2128
BOARD_DTB_OFFSET := 0x07c88000

BOARD_MKBOOTIMG_ARGS += --dtb $(TARGET_PREBUILT_DTB)
BOARD_MKBOOTIMG_ARGS += --vendor_cmdline "$(BOARD_VENDOR_CMDLINE)"
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_PAGE_SIZE) --board ""
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)

# ----------------------------------------------------------------------------
# Partition sizes
# vendor_boot = 64 MiB; super holds every dynamic partition (~8.5 GiB).
# ----------------------------------------------------------------------------
BOARD_FLASH_BLOCK_SIZE := 262144
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864

BOARD_SUPER_PARTITION_SIZE := 12884901888
BOARD_MAIN_PARTITION_LIST := \
    odm \
    odm_dlkm \
    product \
    system \
    system_ext \
    vendor

# ----------------------------------------------------------------------------
# Dynamic partition filesystem types & output mapping
# Stock ROM: erofs for vendor-side images, ext4 for system-side images.
# The recovery must read AND write both, hence both fs tools are enabled below.
# ----------------------------------------------------------------------------
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs

BOARD_USES_SYSTEM_DLKMIMAGE := true
BOARD_USES_VENDOR_DLKMIMAGE := true

TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_ODM_DLKM := odm_dlkm
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USERIMAGES_USE_EROFS := true

# ----------------------------------------------------------------------------
# Recovery image
# - fstab            : mount table used inside recovery
# - PIXEL_FORMAT     : panel framebuffer format (1268x2756 AMOLED)
# - IMAGE_PREPARE    : post-build hook that slims/prunes/UPX-packs the ramdisk
# ----------------------------------------------------------------------------
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/system/etc/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := "RGB_565"
TARGET_USES_LOGD := true
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_HAS_NO_SELECT_BUTTON := true
BOARD_SUPPRESS_SECURE_ERASE := true

# ----------------------------------------------------------------------------
# Build workarounds
# Recovery-only tree: missing deps tolerated, duplicate module names allowed,
# vendor ELF prebuilts copied as-is without product-copy checks.
# ----------------------------------------------------------------------------
ALLOW_MISSING_DEPENDENCIES := true
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# ----------------------------------------------------------------------------
# AVB / signing
# BOARD_RECOVERY_IMAGE_PREPARE runs tools/prepare-recovery-root.sh after the ramdisk
# is assembled (prune modules/fonts/languages, UPX binaries, strip debugdata).
# ----------------------------------------------------------------------------
BOARD_AVB_ENABLE := true
BOARD_RECOVERY_IMAGE_PREPARE = bash $(DEVICE_PATH)/tools/prepare-recovery-root.sh $(TARGET_RECOVERY_ROOT_OUT) --first-call

# ----------------------------------------------------------------------------
# A/B (seamless) OTA
# OF_USE_AIDL_BOOT_CONTROL : use the AIDL bootctl HAL instead of HIDL.
# Full list of slot-suffixed partitions updated by an OTA package.
# ----------------------------------------------------------------------------
AB_OTA_UPDATER := true
OF_USE_AIDL_BOOT_CONTROL := 1
AB_OTA_PARTITIONS += \
    boot \
    init_boot \
    vendor_boot \
    dtbo \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor \
    system \
    system_ext \
    system_dlkm \
    vendor \
    vendor_dlkm \
    product \
    odm \
    odm_dlkm \
    mi_ext

# ----------------------------------------------------------------------------
# TWRP / OrangeFox runtime configuration
#
# Display & theme:
#   portrait_hdpi theme, status-bar indents for the punch-hole cutout.
# Brightness:
#   MTK panel range 0..2047, default 1000 (~half).
# Languages:
#   en-US default, loaded before decryption so menus render pre-unlock.
# Tools bundled into the ramdisk:
#   fastbootd, lptools, lpdump, repack tools, resetprop, erofs tools.
# USB / storage:
#   MTP only (no USB mass storage), data-backed sdcard, no default usb init.
# Decryption:
#   FBE + metadata decrypt with fscrypt v2 policies; dm ctl for dynamic
#   partitions; logcat enabled for debugging.
# ----------------------------------------------------------------------------
TW_THEME := portrait_hdpi
OF_STATUS_INDENT_LEFT := 90
OF_STATUS_INDENT_RIGHT := 90
TARGET_SCREEN_WIDTH := 1268
TARGET_SCREEN_HEIGHT := 2756
TW_MAX_BRIGHTNESS := 2047
TW_DEFAULT_BRIGHTNESS := 1000
TW_USE_LEGACY_BATTERY_SERVICES := true
TW_DEFAULT_LANGUAGE := en_US
OF_LOAD_DEFAULT_LANGUAGE_BEFORE_DECRYPT := 1
OF_SKIP_POST_DECRYPT_THEME_RELOAD := 1
OF_USE_DMCTL := 1

TW_INCLUDE_FASTBOOTD := true
TW_INCLUDE_LPTOOLS := true
TW_INCLUDE_LPDUMP := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_EROFS := true
TW_HAS_MTP := true
TW_MTP_DEVICE := /dev/mtp_usb
TW_NO_USB_STORAGE := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_INPUT_BLACKLIST := "hbtp_vm"

RECOVERY_SDCARD_ON_DATA := true
TWRP_INCLUDE_LOGCAT := true
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
TW_USE_FSCRYPT_POLICY := 2

# Extra libraries relinked into the recovery ramdisk:
#   libtrusty               - Trusty TEE IPC (Keymaster/Weaver path)
#   librodin_libcxx_compat   - local shim for libc++ verbose abort symbols
TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES = \
    $(TARGET_OUT_SHARED_LIBRARIES)/libtrusty.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/librodin_libcxx_compat.so

# OrangeFox device flags (magiskboot, screen size, maintainer info)
-include $(DEVICE_PATH)/fox_rodin.mk
