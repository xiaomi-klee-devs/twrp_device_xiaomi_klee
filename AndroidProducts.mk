# Lunch targets for the klee device tree.
# twrp_klee is the single product; -eng is the only build type needed.
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/twrp_klee.mk

COMMON_LUNCH_CHOICES := twrp_klee-eng
