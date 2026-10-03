#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)

# Generic ramdisk (first-stage init, snapuserd) goes into boot.img.
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)

# Virtual A/B with compression. launch.mk (not compression.mk): the generic
# ramdisk already carries snapuserd, so it must not also go in vendor ramdisk.
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch.mk)
PRODUCT_VIRTUAL_AB_COMPRESSION := true
PRODUCT_PACKAGES += \
    snapuserd \
    snapuserd.recovery

# Inherit from sycamore_row_5G device
$(call inherit-product, device/lenovo/sycamore_row_5G/device.mk)

# Full LineageOS for a tablet with cellular (5G variant).
$(call inherit-product, vendor/lineage/config/common_full_tablet.mk)

PRODUCT_DEVICE := sycamore_row_5G
PRODUCT_NAME := lineage_sycamore_row_5G
PRODUCT_BRAND := Lenovo
PRODUCT_MODEL := TB336ZA
PRODUCT_MANUFACTURER := LENOVO

PRODUCT_GMS_CLIENTID_BASE := android-lenovo

PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Stock build fingerprint (Android 16 / BP2A.250605.031.A3). Stock ships the
# same system image for the ZA/ZU 5G SKUs, fingerprinted as TB336ZU.
BUILD_FINGERPRINT := Lenovo/TB336ZA/TB336ZA:16/BP2A.250605.031.A3/__ROW:user/release-keys
