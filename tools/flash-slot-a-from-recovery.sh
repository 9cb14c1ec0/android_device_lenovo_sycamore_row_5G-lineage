#!/usr/bin/env bash
# Flash the current build into existing slot-A logical partitions from root recovery.
# This leaves super metadata and all slot-B extents untouched.
set -euo pipefail
# Pin adb/fastboot to the TB336ZA; other devices may be attached.
export ANDROID_SERIAL=${ANDROID_SERIAL:-HNY0HTW6}

image_dir=${IMAGE_DIR:-/home/android/tb305fu/lineage-23.2/out/target/product/sycamore_row_5G}
mode=${1:-preflight}
allowed_parts=(odm_dlkm system_dlkm vendor_dlkm vendor product system_ext system)
parts=("${allowed_parts[@]}")

if [[ $mode != preflight && $mode != --flash ]]; then
  echo "usage: $0 [preflight|--flash] [partition ...]" >&2
  exit 2
fi
if (( $# > 1 )); then
  parts=("${@:2}")
  for part in "${parts[@]}"; do
    [[ " ${allowed_parts[*]} " == *" $part "* ]] || {
      echo "Refusing unknown partition: $part" >&2; exit 2;
    }
  done
fi

adb get-state | grep -qx recovery
[[ $(adb shell getprop ro.boot.slot_suffix | tr -d '\r') == _a ]] || {
  echo 'Refusing: active slot is not A' >&2; exit 1;
}
[[ $(adb shell getprop ro.bootmode | tr -d '\r') == recovery ]] || {
  echo 'Refusing: device is not in recovery' >&2; exit 1;
}
[[ $(adb shell id -u | tr -d '\r') == 0 ]] || {
  echo 'Refusing: recovery ADB is not root' >&2; exit 1;
}
[[ $(adb shell getprop ro.product.device | tr -d '\r') == sycamore_row_5G ]] || {
  echo 'Refusing: wrong device' >&2; exit 1;
}

# Lineage recovery does not create logical mappings until they are requested.
# dmctl reads the current slot's super metadata; it does not rewrite metadata.
created_maps=()
cleanup_maps() {
  local part
  for part in "${created_maps[@]}"; do
    adb shell "/tmp/tb336za-dmctl delete ${part}_a" >/dev/null 2>&1 || true
  done
}
trap cleanup_maps EXIT
for part in "${parts[@]}"; do
  if ! adb shell "test -b /dev/block/mapper/${part}_a"; then
    if (( ${#created_maps[@]} == 0 )); then
      [[ -s $image_dir/system/bin/dmctl ]] || {
        echo 'Missing dmctl for recovery mapping' >&2; exit 1;
      }
      adb push "$image_dir/system/bin/dmctl" /tmp/tb336za-dmctl >/dev/null
      adb shell 'chmod 755 /tmp/tb336za-dmctl'
    fi
    adb shell "/tmp/tb336za-dmctl create-from-super ${part}_a ${part}_a" >/dev/null
    created_maps+=("$part")
  fi
done

for part in "${parts[@]}"; do
  image="$image_dir/$part.img"
  target="/dev/block/mapper/${part}_a"
  [[ -f $image ]] || { echo "Missing $image" >&2; exit 1; }
  size=$(stat -c %s "$image")
  capacity=$(adb shell "blockdev --getsize64 $target" | tr -d '\r')
  (( size > 0 && size % 4096 == 0 && size <= capacity )) || {
    echo "Refusing $part: image=$size partition=$capacity" >&2; exit 1;
  }
  printf '%-12s image=%10s partition=%10s\n' "$part" "$size" "$capacity"
done

[[ $mode == --flash ]] || exit 0

# Recovery mounts this module partition. All targets must be unmounted to write.
adb shell 'umount /system_dlkm 2>/dev/null || true'
for part in "${parts[@]}"; do
  target="/dev/block/mapper/${part}_a"
  # Match device numbers rather than path aliases to reject mounted targets.
  adb shell "node=\$(basename \$(readlink -f $target)); dev=\$(cat /sys/class/block/\$node/dev) || exit 1; test -n \"\$dev\" || exit 1; grep -E -q \"^[0-9]+ [0-9]+ \$dev \" /proc/self/mountinfo; match=\$?; test \$match -eq 1" || {
    echo "Refusing to write mounted partition: $part" >&2; exit 1;
  }
done
for part in "${parts[@]}"; do
  image="$image_dir/$part.img"
  target="/dev/block/mapper/${part}_a"
  size=$(stat -c %s "$image")
  blocks=$((size / 4096))
  echo "Writing $part ($size bytes)..."
  adb exec-in "dd of=$target bs=1048576 conv=fsync 2>/dev/null" < "$image"
  expected=$(sha256sum "$image" | cut -d' ' -f1)
  actual=
  for attempt in 1 2 3 4 5; do
    actual=$(adb shell "dd if=$target bs=4096 count=$blocks 2>/dev/null | sha256sum" | cut -d' ' -f1)
    [[ $actual == "$expected" ]] && break
    sleep 1
  done
  [[ $actual == "$expected" ]] || {
    echo "Verification failed for $part: expected=$expected actual=$actual" >&2
    exit 1
  }
  echo "Verified $part: $actual"
done
echo 'All slot-A logical images verified.'
