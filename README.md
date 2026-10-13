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

LineageOS 23.2 boots to setup/home on slot A in ~35 s, repeatably, and is
in daily use on the developer's tablet. `/data` is encrypted and unlocks
automatically through the stock Beanpod TEE.

| Area | State |
| --- | --- |
| Display, touch, stylus, gestures | Working |
| Audio, vibration | Working |
| Cameras | Working: both cameras, photo, video recording, hardware playback |
| Face unlock | Working (ArcSoft HAL; needs the Settings fork below) |
| Wi-Fi (WPA2/WPA3), hotspot, Bluetooth | Working |
| Sensors, battery/charging, suspend | Working |
| Telephony | Working: VoLTE calls, SMS and mobile data (tested on US Mobile / Verizon, physical SIM in slot 2) |
| eSIM | eUICC detected by OpenEUICC ("eSIM Manager"); profile download not yet tested |
| GNSS | HAL starts; outdoor fix not yet confirmed |
| Kernel | GKI 5.15 built from source; all stock MediaTek modules load |
| Lenovo-only HALs | Not ported: keyboard cover, display tuning, factory, misc |
| Installation | Manual, slot A only (see below); flashable zip / OTA in progress |

Lunch target: `lineage_sycamore_row_5G-bp4a-userdebug`. Do **not** use
`bp2a`: Launcher3 Overview flags are off there (Trebuchet crashes), and its
2025-08 security patch level is lower than `bp4a`'s 2026-09. Installing a
lower patch level makes KeyMint reject the existing disk encryption key, so
`/data` will not mount and the tablet falls back to recovery until a `bp4a`
build is reinstalled.

### Install (slot A only, for now)

From Lineage recovery: `tools/install-diagnostic-slot-a.sh --flash`. Set
`FLASH_BOOT=1` whenever `boot.img` changed (kernel or patch level). The script
writes the four logical images into the existing slot-A extents of `super`
with SHA-256 readback, then flashes the vbmeta chain, `boot_a` (optional),
`init_boot_a` and `vendor_boot_a`, and verifies that recovery comes back. Adb
and fastboot are pinned to `ANDROID_SERIAL` (default `HNY0HTW6`). A second
MediaTek device in preloader mode on the same host can make reboot-to-recovery
or -bootloader fall through to normal boot.

Recovery runs on the `boot.img` kernel, so a kernel that does not boot also
takes recovery down; fall back to bootloader fastboot (hardware keys) and the
previous boot/init_boot/vendor_boot/vbmeta set.

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
- Mobile data: AOSP never calls MediaTek's `syncDataSettingsToMd`, so the
  modem refuses data (`VZW_DATA_NOT_ALLOWED`); `datasettings/` sends it.
- Face unlock: ArcSoft HAL with its TA, A13 `libcamera2ndk_vendor-v33`,
  the `faceimport` finish helper, and a Settings fork that hands the
  enrollment preview surface to the HAL instead of opening the camera
  (`config_face_enroll_camera_preview`, set false by
  `rro_overlays/SettingsResOverlaySycamore`).

Bring-up diagnostics (early root adb, log collectors in /metadata) are opt-in:
`TB336ZA_BRINGUP=true` on userdebug; see `bringup/README.md`.

### Slot B history (2026-10-05)

An earlier slot-B attempt failed in two separate ways:

- LK preloads `boot`, `init_boot` and `vendor_boot` at full partition size
  into a 140 MiB pool; stock `init_boot_b` was 15 MiB, which overflowed it
  ("[AVB] malloc error", then `ASSERT boot_info.c:181`). Fixed by shrinking
  `init_boot_b` to 8 MiB in the GPT (done on the developer's tablet).
- Slot B's logical partitions were placed over slot A's extents in `super`
  (`system_b` at sector 2048, over `odm_dlkm_a` / `product_a`), corrupting
  slot A; only a full stock `super` restore fixed it. The recovery sideload
  from that day used proper Virtual A/B snapshots, so the likely cause is
  the fastbootd flashing done with slot B active: fastbootd rewrites the
  `super` metadata keeping only the active slot's partitions.

Until OTA support is verified, do not flash slot B through fastbootd.

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
    <!-- Settings: face enrollment preview drawn by the face HAL -->
    <remove-project name="LineageOS/android_packages_apps_Settings" />
    <project name="9cb14c1ec0/android_packages_apps_Settings" path="packages/apps/Settings" remote="github-https" revision="lineage-23.2" groups="pdk-fs,pdk-cw-tvc,sysui-studio" />
</manifest>
```

Then:

```sh
repo sync
source build/envsetup.sh
lunch lineage_sycamore_row_5G-bp4a-userdebug
m
```

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
