#
# Copyright (C) 2025 The TWRP Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Device specific configs
$(call inherit-product, device/xiaomi/klee/device.mk)

# Device identifier
PRODUCT_DEVICE := klee
PRODUCT_NAME := twrp_klee
PRODUCT_BRAND := POCO
PRODUCT_MODEL := 2511FPC34G
PRODUCT_MANUFACTURER := Xiaomi
