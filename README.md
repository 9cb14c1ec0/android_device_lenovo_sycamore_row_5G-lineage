# LineageOS 23.2 device tree — Lenovo Tab K11 Gen 2 5G (TB336ZA)

LineageOS 23.2 (Android 16) device tree for the **Lenovo Tab K11 Gen 2 5G**
(a.k.a. Lenovo Idea Tab 5G), model **TB336ZA**, codename **sycamore_row_5G**.

| Item | Value |
| --- | --- |
| SoC | MediaTek MT6835 (Dimensity 6300), `ro.board.platform=mt6835`, `androidboot.hardware=mt8755` |
| Kernel | GKI `5.15.197-android13-8`, built from source ([android_kernel_lenovo_mt6835](https://github.com/9cb14c1ec0/android_kernel_lenovo_mt6835), AOSP `android13-5.15-2026-03`) |
| Storage | UFS, A/B + Virtual A/B (compression) |
| Boot layout | boot header v4, `boot` + `init_boot` + `vendor_boot`, no recovery partition |
| Panel | 1600x2560 @ 90 Hz, 320 dpi |
| Stock base | Android 16, `17.5.10.354` (`BP2A.250605.031.A3`) |
| TEE | Microtrust/Beanpod, KeyMint 2.0 (AIDL) + HIDL gatekeeper@1.0 |

It follows the TB305FU (`clove_row_wifi`) playbook, except the GKI kernel is
built from source: the stock kernel is Google's unmodified GKI build
(`2d8ad9139b89`), so the stock DTB/DTBO and MediaTek modules load on it as-is.
Vendor blobs are extracted from stock; system is built from LineageOS source.

## Status

LineageOS 23.2 boots to setup/home on slot A in ~35 s, repeatably.
Lunch: `lineage_sycamore_row_5G-bp4a-userdebug` (LineageOS 23.2's release
config; `bp2a` leaves Launcher3 Overview flags off and Trebuchet crashes).

Working: display/HWC, touch + stylus, gestures, audio + vibration, both
cameras (photo, video recording and hardware playback), Wi-Fi (WPA2/WPA3) and
hotspot, Bluetooth, sensors, battery/charging, suspend, GNSS HAL, RIL/modem,
telephony services, eSIM (OpenEUICC finds the eUICC in slot 2).

IMS: MediaTek ImsService (vendor/mediatek/ims, local manifest) binds as the
MMTEL/emergency provider on both slots; VoLTE registration untested (no SIM).

Not done: some Lenovo-only HAL
domains (keyboard, display tuning, factory, ...), eSIM profile download not
yet tested with a carrier code.

### Install (slot A only)

From Lineage recovery: `tools/install-diagnostic-slot-a.sh --flash`
(`FLASH_BOOT=1` also flashes `boot_a`, needed when the release config changes
the boot header patch level). It writes the four logical images through
existing slot-A `super` metadata with SHA-256 readback, then flashes the
vbmeta chain, `init_boot_a` and `vendor_boot_a` and verifies recovery. Adb and
fastboot are pinned to `ANDROID_SERIAL` (default `HNY0HTW6`). A second
MediaTek device in preloader mode on the same host can make reboot-to-recovery
or -bootloader fall through to normal boot.

### Android 13 vendor on Android 16: compatibility layers

- VNDK 33 APEX (`PRODUCT_EXTRA_VNDK_VERSIONS`); `configs/vendor-linker.config.json`
  adds `libapexsupport` for current libbinder.
- `compat/`: shims for removed libbase, libprocessgroup (C-linkage
  `SetTaskProfiles`), sensors convert and BoringSSL (`sk_dup`) symbols;
  `compat/codec2-v33` ships the stock/VNDK 33 Codec2 framework and libui
  renamed `-v33` for the codec services (`generate.py <stock vendor dir>`).
- `extract-files.py` blob fixups (all applied at extraction): shim
  `add_needed`s, `-v33` relinks (composer resources, Codec2), stock
  keymint-V2-ndk via VNDK 33, `libutils` first for rild/atcid, Codec2 seccomp
  additions (`uname`, `sysinfo`).
- Stock MediaTek `wpa_supplicant` (`wpa_supplicant_mtk`, `configs/wifi`):
  AOSP's WPA3-SAE is rejected by the connac driver.
- Audio service fork in `audio/service` (optional sound trigger / MTK AIDL).
- `sepolicy/vendor`: dynamicdata (selects the userdata fstab; without it
  /data never mounts), KeyMint/HAL/blob labels, wakeup and battery sysfs.
- eSIM: OpenEUICC, shown as "eSIM Manager" (our fork renames the app
  label), + deps from `.repo/local_manifests/sycamore_row_5G.xml`.

Bring-up diagnostics (early root adb, log collectors in /metadata) are opt-in:
`TB336ZA_BRINGUP=true` on userdebug; see `bringup/README.md`.

### Slot B warning (2026-10-05)

Do **not** repeat the slot-B sideload or fastbootd flash sequence: slot-B
logical data ended up in physical `super` extents used by stock slot A
(`system_b` at sector 2048 overlapping `odm_dlkm_a` / `product_a`), and only a
full stock `.354` `super` restore fixed it. See
`~/tb336za/BOOTLOOP_REASSESSMENT.md`.

## Building

Install Git LFS first (`git lfs install`): the vendor tree keeps
`libarcsoft_faceid.so` (128 MB) in LFS. Then add
`.repo/local_manifests/sycamore_row_5G.xml` to a LineageOS 23.2 checkout:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
    <remote name="github-https" fetch="https://github.com/" />
    <project name="9cb14c1ec0/android_device_lenovo_sycamore_row_5G-lineage" path="device/lenovo/sycamore_row_5G" remote="github-https" revision="main" />
    <project name="9cb14c1ec0/android_device_lenovo_sycamore_row_5G-kernel" path="device/lenovo/sycamore_row_5G-kernel" remote="github-https" revision="lineage-23.2" />
    <project name="9cb14c1ec0/android_kernel_lenovo_mt6835" path="kernel/lenovo/mt6835" remote="github-https" revision="lineage-23.2" />
    <project name="9cb14c1ec0/android_vendor_lenovo_sycamore_row_5G" path="vendor/lenovo/sycamore_row_5G" remote="github-https" revision="main" />
    <project name="LineageOS/android_device_mediatek_sepolicy_vndr" path="device/mediatek/sepolicy_vndr" remote="github" revision="lineage-23.2" />
    <project name="LineageOS/android_hardware_mediatek" path="hardware/mediatek" remote="github" revision="lineage-23.2" />
    <!-- eSIM (OpenEUICC) and MediaTek IMS -->
    <project name="9cb14c1ec0/android_packages_apps_OpenEUICC" path="packages/apps/OpenEUICC" remote="github-https" revision="lineage-23.2" />
    <project name="estkme-group/lpac" path="packages/apps/OpenEUICC/libs/lpac-jni/src/main/jni/lpac" remote="github-https" revision="50cdf15ab40942b00f8819a1c2ca19997f1a6d34" />
    <project name="DaveGamble/cJSON" path="packages/apps/OpenEUICC/libs/lpac-jni/src/main/jni/cjson/cjson" remote="github-https" revision="6d9f2443ab071f86e5d9b43025a40929ec41c46c" />
    <project name="9cb14c1ec0/android_prebuilts_openeuicc-deps" path="prebuilts/openeuicc-deps" remote="github-https" revision="lineage-23.2" />
    <project name="techyminati/android_vendor_mediatek_ims" path="vendor/mediatek/ims" remote="github-https" revision="e9cab87f806ab010346dd61cab3dc4fd6051aa59" />
</manifest>
```

Then `repo sync`, `source build/envsetup.sh`, `breakfast sycamore_row_5G
userdebug`, `m`.

## Bootloader / Verified Boot

The bootloader was unlocked with a Lenovo-signed `sn.img` (see the TWRP
tree's `UNLOCK_RESEARCH.md`). On slot A, the stock LK boots Lineage recovery
and Android with the complete self-signed Lineage boot/init_boot/vendor_boot/
vbmeta chain. No bootloader patch is needed.
The build self-signs with the AVB test key.

Firmware partitions (preloader, lk, tee, gz, scp, sspm, md1img) are
not shipped; both slots must already carry the same stock `17.5.10.354`.

## Related

- TWRP recovery: `android_device_lenovo_sycamore_row_5G` (UI, touch, root ADB
  and `/data` decryption all working).
