# Lunch targets for the rodin device tree.
# twrp_rodin is the single product; -eng is the only build type needed.
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/twrp_rodin.mk

COMMON_LUNCH_CHOICES := twrp_rodin-eng
