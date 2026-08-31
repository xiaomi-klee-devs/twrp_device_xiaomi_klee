# Omni-style product alias (kept for trees/tools that lunch omni_<device>).
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call inherit-product, vendor/twrp/config/common.mk)
$(call inherit-product, device/xiaomi/rodin/device.mk)

PRODUCT_DEVICE := rodin
PRODUCT_NAME := omni_rodin
PRODUCT_BRAND := POCO
PRODUCT_MODEL := 2412DPC0AG
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_RELEASE_NAME := POCO X7 Pro

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

# Match the stock ROM fingerprint so OTA checks / props look original.
BUILD_FINGERPRINT := POCO/rodin_eea/rodin:15/AP3A.240905.015.A2/OS3.0.300.0.WOJEUXM:user/release-keys
PRIVATE_BUILD_DESC := miodm_rodin-user 16 AP3A.240905.015.A2 OS3.0.300.0.WOJEUXM release-keys

PRODUCT_BUILD_PROP_OVERRIDES += \
    TARGET_DEVICE=rodin \
    PRODUCT_NAME=rodin \
    PRIVATE_BUILD_DESC="$(PRIVATE_BUILD_DESC)"
