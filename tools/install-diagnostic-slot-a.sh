#!/usr/bin/env bash
# Install the early-ADB diagnostic build on the existing slot-A layout.
# Run only while TB336ZA is connected in Lineage or TWRP recovery.
set -euo pipefail
# Pin adb/fastboot to the TB336ZA; other devices may be attached.
export ANDROID_SERIAL=${ANDROID_SERIAL:-HNY0HTW6}

device_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
image_dir=${IMAGE_DIR:-/home/android/tb305fu/lineage-23.2/out/target/product/sycamore_row_5G}
avbtool=${AVBTOOL:-/home/android/tb305fu/lineage-23.2/external/avb/avbtool.py}
mode=${1:-preflight}

if [[ $mode != preflight && $mode != --flash ]]; then
  echo "usage: $0 [preflight|--flash]" >&2
  exit 2
fi

for image in system system_ext product vendor vbmeta_system vbmeta_vendor vendor_boot init_boot; do
  [[ -s $image_dir/$image.img ]] || { echo "Missing $image_dir/$image.img" >&2; exit 1; }
done
"$avbtool" verify_image --image "$image_dir/vbmeta.img" --follow_chain_partitions >/dev/null

adb get-state | grep -qx recovery
[[ $(adb shell getprop ro.boot.slot_suffix | tr -d '\r') == _a ]] || {
  echo 'Refusing: device is not booted from slot A' >&2; exit 1;
}
[[ $(adb shell getprop ro.product.device | tr -d '\r') == sycamore_row_5G ]] || {
  echo 'Refusing: wrong device' >&2; exit 1;
}
[[ $(adb shell id -u | tr -d '\r') == 0 ]] || {
  echo 'Refusing: recovery ADB is not root' >&2; exit 1;
}

wait_fastboot() {
  local i
  for i in {1..60}; do
    if fastboot devices | grep -q "^$ANDROID_SERIAL[[:space:]]"; then return 0; fi
    sleep 1
  done
  echo 'Timed out waiting for bootloader fastboot' >&2
  return 1
}

wait_recovery() {
  timeout 120 adb wait-for-recovery
  [[ $(adb shell getprop ro.boot.slot_suffix | tr -d '\r') == _a ]] || {
    echo 'Recovery came back on the wrong slot' >&2; return 1;
  }
}

is_twrp() {
  adb shell 'command -v twrp >/dev/null 2>&1'
}

if [[ $mode == preflight ]]; then
  echo 'Device: sycamore_row_5G, slot A, recovery connected'
  sha256sum "$image_dir"/{system,system_ext,product,vendor,vbmeta_system,vbmeta_vendor,vendor_boot,init_boot}.img
  echo 'Preflight passed. Run with --flash to install.'
  exit 0
fi

IMAGE_DIR="$image_dir" "$device_dir/tools/flash-slot-a-from-recovery.sh" --flash vendor product system_ext system
adb shell 'sync; reboot bootloader' || true
wait_fastboot
fastboot flash vbmeta_system_a "$image_dir/vbmeta_system.img"
fastboot flash vbmeta_vendor_a "$image_dir/vbmeta_vendor.img"
# boot.img only changes when the header patch level does (release config).
if [[ ${FLASH_BOOT:-0} == 1 ]]; then
  fastboot flash boot_a "$image_dir/boot.img"
fi
fastboot flash init_boot_a "$image_dir/init_boot.img"
fastboot flash vendor_boot_a "$image_dir/vendor_boot.img"
fastboot flash vbmeta_a "$image_dir/vbmeta.img"
fastboot reboot recovery
wait_recovery
if is_twrp; then
  echo 'Lineage recovery did not boot; Android boot has not been attempted' >&2; exit 1;
fi
[[ -n $(adb shell getprop ro.lineage.version | tr -d '\r') ]] || {
  echo 'Recovery does not identify as Lineage; stopping before Android boot' >&2; exit 1;
}
echo 'Diagnostic images installed and Lineage recovery verified. Android has not been booted.'
