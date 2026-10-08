#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/lineage_sycamore_row_5G.mk

# Release config: LineageOS 23.2 targets bp4a (vendor/lineage/vars/aosp_target_release);
# older releases leave Launcher3 Overview flags off that the code requires.
COMMON_LUNCH_CHOICES := \
    lineage_sycamore_row_5G-bp4a-user \
    lineage_sycamore_row_5G-bp4a-userdebug \
    lineage_sycamore_row_5G-bp4a-eng
