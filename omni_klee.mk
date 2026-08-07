$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call inherit-product, vendor/twrp/config/common.mk)
$(call inherit-product, device/xiaomi/klee/device.mk)

PRODUCT_DEVICE := klee
PRODUCT_NAME := omni_klee
PRODUCT_BRAND := POCO
PRODUCT_MODEL := 2511FPC34G
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_RELEASE_NAME := POCO X8 Pro

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

BUILD_FINGERPRINT := POCO/klee_global/klee:16/BP2A.250605.031.A3/OS3.0.306.0.WPJMIXM:user/release-keys
PRIVATE_BUILD_DESC := miodm_klee-user 16 BP2A.250605.031.A3 OS3.0.306.0.WPJMIXM release-keys

PRODUCT_BUILD_PROP_OVERRIDES += \
    TARGET_DEVICE=klee \
    PRODUCT_NAME=klee \
    PRIVATE_BUILD_DESC="$(PRIVATE_BUILD_DESC)"
