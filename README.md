# LineageOS 23.2 device tree — Lenovo Tab K11 Gen 2 5G (TB336ZA)

LineageOS 23.2 (Android 16) device tree for the **Lenovo Tab K11 Gen 2 5G**
(a.k.a. Lenovo Idea Tab 5G), model **TB336ZA**, codename **sycamore_row_5G**.

| Item | Value |
| --- | --- |
| SoC | MediaTek MT6835 (Dimensity 6300), `ro.board.platform=mt6835`, `androidboot.hardware=mt8755` |
| Kernel | GKI `5.15.197-android13`, prebuilt (no source from Lenovo) |
| Storage | UFS, A/B + Virtual A/B (compression) |
| Boot layout | boot header v4, `boot` + `init_boot` + `vendor_boot`, no recovery partition |
| Panel | 1600x2560 @ 90 Hz, 320 dpi |
| Stock base | Android 16, `17.5.10.354` (`BP2A.250605.031.A3`) |
| TEE | Microtrust/Beanpod, KeyMint 2.0 (AIDL) + HIDL gatekeeper@1.0 |

It follows the TB305FU (`clove_row_wifi`) playbook: prebuilt GKI kernel, stock
DTB/DTBO and modules, vendor blobs extracted from stock, system built from
LineageOS source.

## Status

**Foundation / scaffolding — not yet building or booting.** The static
device-tree structure is in place; vendor blob extraction and the iterative
build + boot bring-up are the next phase.

Done:
- `BoardConfig.mk`, product makefiles (`lineage_sycamore_row_5G.mk`,
  `AndroidProducts.mk`), `device.mk` (adapted from the TB305FU tree).
- `../sycamore_row_5G-kernel/` prebuilts: stock GKI `Image`, DTB, DTBO,
  `vendor_dlkm` + `vendor_ramdisk` modules.
- `rootdir/etc/`: stock fstabs, `init.*.rc`, `ueventd`, `init.insmod`.
- `proprietary-files.txt`: ~2000 blobs, seeded from the TB305FU list adapted
  to MT6835 and filtered to this device's stock dump, plus device-specific
  HAL binaries (incl. the Beanpod KeyMint/gatekeeper HALs).
- `configs/vintf/manifest.xml`: assembled from the stock vendor manifest +
  fragments (92 HAL entries).
- `extract-files.py` / `setup-makefiles.py`, `configs/permissions/`, props.

Bring-up TODO (roughly in order):
1. Dump stock partitions and run `./extract-files.py <dump>` to populate
   `vendor/lenovo/sycamore_row_5G`.
2. First build (`lineage_sycamore_row_5G-bp2a-userdebug`); iterate on missing
   blobs and ELF `blob_fixup`s (ABI version mismatches between the A13-era
   vendor blobs and the A16 system).
3. SELinux: `device/mediatek/sepolicy_vndr` + `sepolicy/vendor` denials.
4. Boot bring-up: first-stage mount / fstab, display, touch, Wi-Fi/BT,
   sensors, audio, telephony (5G).
5. The crypto/decryption stack is already solved in the TWRP tree
   (`android_device_lenovo_sycamore_row_5G`); reuse its findings.

## Bootloader / Verified Boot

The bootloader is unlockable only with a Lenovo-signed `sn.img` (see the TWRP
tree's `UNLOCK_RESEARCH.md`). The stock LK rejects any `vbmeta` not signed by
Lenovo even when unlocked, so booting a self-signed LineageOS build will need a
patched LK, as on the TB305FU. The build self-signs with the AVB test key.

Firmware partitions (preloader, lk, tee, gz, scp, sspm, md1img) are
not shipped; both slots must already carry the same stock `17.5.10.354`.

## Related

- TWRP recovery: `android_device_lenovo_sycamore_row_5G` (UI, touch, root ADB
  and `/data` decryption all working).
