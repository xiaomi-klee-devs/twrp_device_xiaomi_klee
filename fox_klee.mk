# ============================================================================
# OrangeFox-specific device flags (fox_klee.mk)
# Included from BoardConfig.mk; only OrangeFox reads these.
# ============================================================================

# Maintainer shown on the OrangeFox about page
OF_MAINTAINER := kylieeXD
FOX_TARGET_DEVICES := klee

# Pack boot/vendor_boot images with magiskboot (handles MTK header quirks);
# "new" magiskboot supports the v4 header + vendor_ramdisk fragments.
OF_USE_MAGISKBOOT := 1
OF_USE_NEW_MAGISKBOOT := 1
OF_USE_LZ4_COMPRESSION := 1

# Show the ROM fingerprint from system instead of the recovery build's
OF_USE_SYSTEM_FINGERPRINT := 1

# OTA / SAR handling
OF_SUPPORT_ALL_BLOCK_OTA_UPDATES := 0
OF_NO_TREBLE_COMPATIBILITY_CHECK := 1
OF_USE_TWRP_SAR_DETECT := 1
OF_MANUAL_ROOT_VENDOR_ERROR_FIX := 1

# Bundled extras
OF_ENABLE_LPTOOLS := 1       # dynamic-partition logical-path tools
OF_FLASHLIGHT_ENABLE := 0    # no torch toggle (LED driver not wired in recovery)
OF_SCREEN_H := 2400          # safe-area height for overlay UI elements
OF_SKIP_MULTIUSER_FOLDERS_BACKUP := 1
