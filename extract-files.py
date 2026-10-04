#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Extracts proprietary blobs for sycamore_row_5G into vendor/lenovo/sycamore_row_5G.
#
# Source: a directory holding the extracted stock partitions, e.g.
#   <dump>/vendor/...
# made with fsck.erofs --extract=<dump>/vendor vendor.img from a stock
# firmware image, or pulled from a device running stock with
# ./pull-stock-images.sh (see there for why lpunpack of a live super dump
# does not work on this Virtual A/B device). Then:
#   ./extract-files.py <dump>
#

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

namespace_imports = [
    'hardware/mediatek',
]


def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}_{partition}' if partition == 'vendor' else None


lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
}

blob_fixups: blob_fixups_user_type = {
    # Beanpod KeyMint 2.0 links the stock (Android 13) keymaster / keymint
    # support libraries, whose names collide with AOSP modules built from
    # source. Ship the stock copies renamed with a -beanpod suffix and point
    # the HAL (and the libraries' links among themselves) at them, so the
    # KeyMint stack keeps the exact ABI proven in recovery.
    (
        'vendor/lib64/libkeymint-beanpod.so',
        'vendor/lib64/libkeymaster_messages-beanpod.so',
        'vendor/lib64/libkeymaster_portable-beanpod.so',
        'vendor/lib64/libsoft_attestation_cert-beanpod.so',
        'vendor/lib64/libcppbor_external-beanpod.so',
        'vendor/lib64/libcppcose_rkp-beanpod.so',
        'vendor/lib64/libpuresoftkeymasterdevice-beanpod.so',
        'vendor/lib64/lib_android_keymaster_keymint_utils-beanpod.so',
    ): blob_fixup()
        .fix_soname()
        .replace_needed('libkeymint.so', 'libkeymint-beanpod.so')
        .replace_needed('libkeymaster_messages.so', 'libkeymaster_messages-beanpod.so')
        .replace_needed('libkeymaster_portable.so', 'libkeymaster_portable-beanpod.so')
        .replace_needed('libsoft_attestation_cert.so', 'libsoft_attestation_cert-beanpod.so')
        .replace_needed('libcppbor_external.so', 'libcppbor_external-beanpod.so')
        .replace_needed('libcppcose_rkp.so', 'libcppcose_rkp-beanpod.so')
        .replace_needed('libpuresoftkeymasterdevice.so', 'libpuresoftkeymasterdevice-beanpod.so')
        .replace_needed('lib_android_keymaster_keymint_utils.so', 'lib_android_keymaster_keymint_utils-beanpod.so'),
    (
        'vendor/bin/hw/android.hardware.security.keymint@2.0-service.beanpod',
    ): blob_fixup()
        .replace_needed('libkeymint.so', 'libkeymint-beanpod.so')
        .replace_needed('libkeymaster_messages.so', 'libkeymaster_messages-beanpod.so')
        .replace_needed('libkeymaster_portable.so', 'libkeymaster_portable-beanpod.so')
        .replace_needed('libsoft_attestation_cert.so', 'libsoft_attestation_cert-beanpod.so')
        .replace_needed('libcppbor_external.so', 'libcppbor_external-beanpod.so')
        .replace_needed('libcppcose_rkp.so', 'libcppcose_rkp-beanpod.so')
        .replace_needed('libpuresoftkeymasterdevice.so', 'libpuresoftkeymasterdevice-beanpod.so')
        .replace_needed('lib_android_keymaster_keymint_utils.so', 'lib_android_keymaster_keymint_utils-beanpod.so'),
    # graphics.common is AIDL (backward-compatible NDK): these blobs link V3,
    # while source-built composer3 / libui pull in V7, and Soong refuses to
    # mix versions of one interface in a dependency graph.
    (
        'vendor/lib/vendor.mediatek.hardware.pq_aidl-V1-ndk.so',
        'vendor/lib64/vendor.mediatek.hardware.pq_aidl-V1-ndk.so',
    ): blob_fixup()
        .replace_needed('android.hardware.graphics.common-V3-ndk.so', 'android.hardware.graphics.common-V7-ndk.so'),
    (
        'vendor/lib64/libcodec2_vpp_AIMEMC_plugin.so',
        'vendor/lib64/libcodec2_vpp_AISR_plugin.so',
    ): blob_fixup()
        .replace_needed('android.hardware.graphics.common-V3-ndk.so', 'android.hardware.graphics.common-V7-ndk.so')
        .replace_needed('android.hardware.graphics.allocator-V1-ndk.so', 'android.hardware.graphics.allocator-V2-ndk.so'),
    'vendor/bin/factory': blob_fixup()
        .replace_needed('android.hardware.light-V1-ndk.so', 'android.hardware.light-V2-ndk.so'),
    'vendor/bin/hw/vendor.mediatek.hardware.mtkpower-service.mediatek': blob_fixup()
        .replace_needed('android.hardware.power-service-mediatek.so', 'android.hardware.power-service-mediatek_vendor.so'),
    'vendor/lib64/libmtkcam_hal_aidl_common.so': blob_fixup()
        .replace_needed('android.hardware.camera.common-V2-ndk.so', 'android.hardware.camera.common-V2-ndk_vendor.so'),
    (
        'vendor/bin/hw/android.hardware.graphics.allocator-V2-service-mediatek',
        'vendor/lib64/egl/libGLES_mali.so',
        'vendor/lib64/hw/android.hardware.graphics.allocator-V2-mediatek.so',
        'vendor/lib64/hw/mapper.mediatek.so',
        'vendor/lib64/libaimemc.so',
        'vendor/lib64/libcodec2_fsr.so',
        'vendor/lib64/libgpud.so',
        'vendor/lib64/libmtkcam_grallocutils.so',
        'vendor/lib64/vendor.mediatek.hardware.camera.isphal-V1-ndk.so',
        'vendor/lib64/vendor.mediatek.hardware.pq_aidl-V2-ndk.so',
        'vendor/lib64/vendor.mediatek.hardware.pq_aidl-V4-ndk.so',
        'vendor/lib64/vendor.mediatek.hardware.pq_aidl-V7-ndk.so',
        'vendor/lib/egl/libGLES_mali.so',
        'vendor/lib/hw/android.hardware.graphics.allocator-V2-mediatek.so',
        'vendor/lib/hw/mapper.mediatek.so',
        'vendor/lib/libcodec2_fsr.so',
        'vendor/lib/libgpud.so',
        'vendor/lib/vendor.mediatek.hardware.pq_aidl-V2-ndk.so',
        'vendor/lib/vendor.mediatek.hardware.pq_aidl-V7-ndk.so',
    ): blob_fixup()
        .replace_needed('android.hardware.graphics.common-V4-ndk.so', 'android.hardware.graphics.common-V7-ndk.so')
        .replace_needed('android.hardware.graphics.common-V5-ndk.so', 'android.hardware.graphics.common-V7-ndk.so'),
    (
        'vendor/bin/hw/android.hardware.audio.service-aidl.mediatek',
        'vendor/lib/hw/android.hardware.soundtrigger3-impl.so',
        'vendor/lib/soundfx/libbundleaidl.so',
        'vendor/lib/soundfx/libswdapaidl.so',
        'vendor/lib/soundfx/libswgamedapaidl.so',
        'vendor/lib64/hw/android.hardware.soundtrigger3-impl.so',
        'vendor/lib64/soundfx/libbundleaidl.so',
        'vendor/lib64/soundfx/libswdapaidl.so',
        'vendor/lib64/soundfx/libswgamedapaidl.so',
    ): blob_fixup()
        .replace_needed('libaudio_aidl_conversion_common_ndk.so', 'libaudio_aidl_conversion_common_ndk_prebuilt.so'),
    (
        'vendor/lib/android.hardware.audio.core-impl-mediatek.so',
        'vendor/lib64/android.hardware.audio.core-impl-mediatek.so',
    ): blob_fixup()
        .add_needed('libaudioutils_shim.so')
        .replace_needed('libaudio_aidl_conversion_common_ndk.so', 'libaudio_aidl_conversion_common_ndk_prebuilt.so'),
    (
        'vendor/bin/mnld',
        'vendor/lib/libaalservice.so',
        'vendor/lib64/libaalservice.so',
        'vendor/lib64/libcam.utils.sensorprovider.so',
    ): blob_fixup()
        .replace_needed('android.hardware.sensors-V2-ndk.so', 'android.hardware.sensors-V3-ndk.so'),
    (
        'vendor/lib/hw/audio.primary.mt6835.so',
        'vendor/lib/hw/vendor.mediatek.hardware.pq_aidl-impl.so',
        'vendor/lib/lib_power_applist.so',
        'vendor/lib/libpowerhal.so',
        'vendor/lib/libpqxmlparser.so',
        'vendor/lib/librt_extamp_intf.so',
        'vendor/lib64/hw/android.hardware.audio.effect.aidl-impl-mediatek.so',
        'vendor/lib64/hw/audio.primary.mt6835.so',
        'vendor/lib64/hw/hwcomposer.mt6835.so',
        'vendor/lib64/hw/vendor.mediatek.hardware.pq_aidl-impl.so',
        'vendor/lib64/lib_power_applist.so',
        'vendor/lib64/libpowerhal.so',
        'vendor/lib64/libpqxmlparser.so',
        'vendor/lib64/librt_extamp_intf.so',
        'vendor/lib64/libsilkybrightnesscore.so',
    ): blob_fixup()
        .replace_needed('libtinyxml2.so', 'libtinyxml2-v34.so'),
    # These services declare MediaTek HIDL interfaces that are not built from
    # source, which host_init_verifier rejects. They are started by class, so
    # the interface lines (only used for lazy start) can go.
    (
        'vendor/etc/init/atcid.rc',
        'vendor/etc/init/dmc_core.rc',
        'vendor/etc/init/vendor.mediatek.hardware.mmagent@1.1-service.rc',
        'vendor/etc/init/vendor.mediatek.hardware.mms@1.7-service.rc',
    ): blob_fixup()
        .regex_replace(r'(?m)^\s*interface\s+vendor\.mediatek\.hardware\.[^\n]*\n', ''),
}  # fmt: skip

module = ExtractUtilsModule(
    'sycamore_row_5G',
    'lenovo',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
