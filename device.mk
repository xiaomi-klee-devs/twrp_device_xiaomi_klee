DEVICE_PATH := device/xiaomi/klee

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)

# Enable project quotas and casefolding for emulated storage without sdcardfs
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Enable Virtual A/B OTA
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression.mk)

# API
PRODUCT_SHIPPING_API_LEVEL := 34
PRODUCT_TARGET_VNDK_VERSION := 36

# Enable Fuse Passthrough
PRODUCT_PROPERTY_OVERRIDES += persist.sys.fuse.passthrough.enable=true

# TWRP in Vendor Boot
PRODUCT_PROPERTY_OVERRIDES += ro.twrp.vendor_boot=true

# A/B
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

PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier \
    checkpoint_gc

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

# Dynamic
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_USE_VIRTUAL_AB := true
PRODUCT_VIRTUAL_AB_OTA := true
PRODUCT_VIRTUAL_AB_COMPRESSION := true

# Boot control HAL
PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-mtkimpl \
    android.hardware.boot@1.0-impl-1.2-mtkimpl \
    android.hardware.boot@1.2-mtkimpl.recovery

PRODUCT_PACKAGES_DEBUG += \
    bootctrl \
    bootctl \
    logcat

# Health HAL
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service \
    android.hardware.health@2.1-impl.recovery \
    android.hardware.health@2.1-service.rc

# Idk
PRODUCT_PACKAGES += \
    android.hardware.boot@1.0-impl-1.2-mtkimpl \
    android.hardware.boot@1.2-mtkimpl \
    android.hardware.boot@1.2-mtkimpl.recovery \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-impl.recovery \
    android.hardware.health@2.1-service \
    android.hardware.health@2.1-service.rc \
    create_pl_dev \
    create_pl_dev.recovery \
    fastbootd \
    fsck.erofs \
    fsck.f2fs \
    lpdump \
    lpunpack \
    make_f2fs \
    klee_omapi_bridge \
    snapuserd \
    snapuserd_ramdisk \
    libklee_libcxx_compat

# Proprietary
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/recovery/root/init.recovery.bootctl.rc:recovery/root/init.recovery.bootctl.rc \
    $(DEVICE_PATH)/recovery/root/init.recovery.hardware.rc:recovery/root/init.recovery.hardware.rc \
    $(DEVICE_PATH)/recovery/root/init.recovery.keymint.rc:recovery/root/init.recovery.keymint.rc \
    $(DEVICE_PATH)/recovery/root/init.recovery.mt6899.rc:recovery/root/init.recovery.mt6899.rc \
    $(DEVICE_PATH)/recovery/root/init.recovery.project.rc:recovery/root/init.recovery.project.rc \
    $(DEVICE_PATH)/recovery/root/system/bin/load-touch-modules.sh:recovery/root/system/bin/load-touch-modules.sh \
    $(DEVICE_PATH)/proprietary/odm/bin/hw/vendor.xiaomi.hw.touchfeature-service-recovery:recovery/root/system/bin/vendor.xiaomi.hw.touchfeature-service-recovery \
    $(DEVICE_PATH)/proprietary/fonts/MiSans.ttf:recovery/root/twres/fonts/MiSans.ttf \
    $(DEVICE_PATH)/proprietary/touch/lib64/android.frameworks.sensorservice-V1-ndk.so:recovery/root/system/lib64/klee-touch/android.frameworks.sensorservice-V1-ndk.so \
    $(DEVICE_PATH)/proprietary/touch/lib64/android.hardware.common-V2-ndk.so:recovery/root/system/lib64/klee-touch/android.hardware.common-V2-ndk.so \
    $(DEVICE_PATH)/proprietary/touch/lib64/android.hardware.common.fmq-V1-ndk.so:recovery/root/system/lib64/klee-touch/android.hardware.common.fmq-V1-ndk.so \
    $(DEVICE_PATH)/proprietary/touch/lib64/android.hardware.sensors-V2-ndk.so:recovery/root/system/lib64/klee-touch/android.hardware.sensors-V2-ndk.so \
    $(DEVICE_PATH)/proprietary/touch/lib64/libc++.so:recovery/root/system/lib64/klee-touch/libc++.so \
    $(DEVICE_PATH)/proprietary/touch/lib64/libmisight.so:recovery/root/system/lib64/klee-touch/libmisight.so \
    $(DEVICE_PATH)/proprietary/touch/lib64/libmisight.so:recovery/root/vendor/lib64/libmisight.so \
    $(DEVICE_PATH)/proprietary/odm/lib64/vendor.xiaomi.hardware.miauthsecretd-V1-ndk.so:recovery/root/vendor/lib64/vendor.xiaomi.hardware.miauthsecretd-V1-ndk.so \
    $(DEVICE_PATH)/proprietary/touch/lib64/vendor.xiaomi.hw.touchfeature-V1-ndk.so:recovery/root/system/lib64/klee-touch/vendor.xiaomi.hw.touchfeature-V1-ndk.so \
    $(DEVICE_PATH)/proprietary/vendor/bin/tee-supplicant:recovery/root/vendor/bin/tee-supplicant \
    $(DEVICE_PATH)/proprietary/vendor/bin/hw/android.hardware.gatekeeper-service.mitee:recovery/root/vendor/bin/hw/android.hardware.gatekeeper-service.mitee \
    $(DEVICE_PATH)/proprietary/vendor/bin/hw/android.hardware.security.keymint@3.0-service.mitee:recovery/root/vendor/bin/hw/android.hardware.security.keymint@3.0-service.mitee \
    $(DEVICE_PATH)/proprietary/vendor/bin/hw/android.hardware.weaver-service.nxp:recovery/root/vendor/bin/hw/android.hardware.weaver-service.nxp \
    $(DEVICE_PATH)/proprietary/vendor/bin/hw/vendor.xiaomi.hardware.secure_element-service:recovery/root/vendor/bin/hw/vendor.xiaomi.hardware.secure_element-service \
    $(DEVICE_PATH)/proprietary/vendor/mitee/ta/2e8fade5-0c7a-46cc-810e6468baee66b9.ta:recovery/root/vendor/mitee/ta/2e8fade5-0c7a-46cc-810e6468baee66b9.ta \
    $(DEVICE_PATH)/proprietary/vendor/mitee/ta/4d573443-6a56-4272-ac6f2425af9ef9bb.ta:recovery/root/vendor/mitee/ta/4d573443-6a56-4272-ac6f2425af9ef9bb.ta \
    $(DEVICE_PATH)/proprietary/vendor/mitee/ta/dba51a17-0563-11e7-93b16fa7b0071a51.ta:recovery/root/vendor/mitee/ta/dba51a17-0563-11e7-93b16fa7b0071a51.ta \
    $(DEVICE_PATH)/proprietary/vendor/lib64/android.hardware.secure_element@1.0.so:recovery/root/vendor/lib64/android.hardware.secure_element@1.0.so \
    $(DEVICE_PATH)/proprietary/vendor/lib64/android.hardware.secure_element@1.1.so:recovery/root/vendor/lib64/android.hardware.secure_element@1.1.so \
    $(DEVICE_PATH)/proprietary/vendor/lib64/android.hardware.secure_element@1.2.so:recovery/root/vendor/lib64/android.hardware.secure_element@1.2.so \
    $(DEVICE_PATH)/proprietary/vendor/lib64/libclang_rt.ubsan_standalone-aarch64-android.so:recovery/root/vendor/lib64/libclang_rt.ubsan_standalone-aarch64-android.so \
    $(DEVICE_PATH)/proprietary/vendor/lib64/android.hardware.secure_element-V1-ndk.so:recovery/root/vendor/lib64/android.hardware.secure_element-V1-ndk.so \
    $(DEVICE_PATH)/proprietary/vendor/lib64/android.hardware.weaver-V2-ndk.so:recovery/root/vendor/lib64/android.hardware.weaver-V2-ndk.so \
    $(DEVICE_PATH)/proprietary/vendor/lib64/android.se.omapi-V1-ndk.so:recovery/root/vendor/lib64/android.se.omapi-V1-ndk.so \
    $(DEVICE_PATH)/proprietary/vendor/lib64/ese_weaver.nxp.so:recovery/root/system/lib64/ese_weaver.nxp.so \
    $(DEVICE_PATH)/proprietary/vendor/lib64/ese_weaver.nxp.so:recovery/root/vendor/lib64/ese_weaver.nxp.so \
    $(DEVICE_PATH)/proprietary/vendor/lib64/libjc_keymint_transport.nxp.so:recovery/root/system/lib64/libjc_keymint_transport.nxp.so \
    $(DEVICE_PATH)/proprietary/vendor/lib64/libmemunreachable.so:recovery/root/system/lib64/libmemunreachable.so \
    $(DEVICE_PATH)/proprietary/vendor/lib64/libmigpese@2.0.so:recovery/root/system/lib64/libmigpese@2.0.so \
    $(DEVICE_PATH)/proprietary/vendor/lib64/libteecli.so:recovery/root/system/lib64/libteecli.so \
    $(DEVICE_PATH)/proprietary/vendor/lib64/vendor.xiaomi.hardware.aidl.mtdservice-V1-ndk.so:recovery/root/system/lib64/vendor.xiaomi.hardware.aidl.mtdservice-V1-ndk.so \
    $(DEVICE_PATH)/proprietary/vendor/etc/vintf/manifest/android.hardware.gatekeeper-service.mitee.xml:recovery/root/vendor/etc/vintf/manifest/android.hardware.gatekeeper-service.mitee.xml \
    $(DEVICE_PATH)/proprietary/vendor/etc/vintf/manifest/android.hardware.security.keymint-service.mitee.xml:recovery/root/vendor/etc/vintf/manifest/android.hardware.security.keymint-service.mitee.xml \
    $(DEVICE_PATH)/proprietary/vendor/etc/vintf/manifest/android.hardware.security.secureclock-service.mitee.xml:recovery/root/vendor/etc/vintf/manifest/android.hardware.security.secureclock-service.mitee.xml \
    $(DEVICE_PATH)/proprietary/vendor/etc/vintf/manifest/android.hardware.security.sharedsecret-service.mitee.xml:recovery/root/vendor/etc/vintf/manifest/android.hardware.security.sharedsecret-service.mitee.xml \
    $(DEVICE_PATH)/proprietary/vendor/etc/vintf/manifest/android.hardware.weaver-service.nxp.xml:recovery/root/vendor/odm/etc/vintf/manifest/android.hardware.weaver-service.nxp.xml \
    $(DEVICE_PATH)/proprietary/odm/bin/hw/android.hardware.weaver:recovery/root/vendor/odm/bin/hw/android.hardware.weaver \
    $(DEVICE_PATH)/proprietary/odm/lib64/vendor.xiaomi.hardware.cpace-V1-ndk.so:recovery/root/vendor/odm/lib64/vendor.xiaomi.hardware.cpace-V1-ndk.so \
    $(DEVICE_PATH)/proprietary/odm/bin/hw/vendor.xiaomi.hardware.authsecretd:recovery/root/vendor/odm/bin/hw/vendor.xiaomi.hardware.authsecretd \
    $(DEVICE_PATH)/proprietary/odm/etc/vintf/manifest/vendor.xiaomi.hardware.authsecretd.xml:recovery/root/vendor/odm/etc/vintf/manifest/vendor.xiaomi.hardware.authsecretd.xml \
    $(DEVICE_PATH)/proprietary/vendor/lib64/libc++.so:recovery/root/vendor/lib64/libc++.so
