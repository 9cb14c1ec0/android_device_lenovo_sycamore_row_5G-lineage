#!/usr/bin/env bash
#
# Pull the stock read-only partition images from a device booted into TWRP.
#
# WHY adb AND NOT lpunpack(super.bin):
#   This device uses Virtual A/B snapshots. A plain lpunpack of a super dump
#   returns the pre-snapshot BASE image; every inode living in a COW-updated
#   region reads back as zero. Symptom: fsck.erofs aborts with
#   "bogus i_mode (0) @ nid ..." and /vendor/etc + /vendor/firmware are
#   unreadable ("Structure needs cleaning"). Both slots fail identically.
#   The live /dev/block/mapper/<part>_<slot> node presents the MERGED
#   base+COW view, which is the real filesystem.
#
# This is a strictly READ-ONLY operation. It does not mount /data, touch the
# TEE/teei_daemon, reboot, or write to the device.
#
set -euo pipefail

SLOT="${SLOT:-$(adb shell getprop ro.boot.slot_suffix | tr -d '\r')}"
SLOT="${SLOT:-_a}"
OUT="${1:-stock_images}"
PARTS="${PARTS:-vendor vendor_dlkm odm_dlkm system_dlkm}"

state=$(adb get-state 2>/dev/null || true)
if [ "$state" != "recovery" ] && [ "$state" != "device" ]; then
    echo "error: no adb device (state='$state'). Boot into TWRP first." >&2
    exit 1
fi

mkdir -p "$OUT"
echo "slot${SLOT}  ->  $OUT/"

for p in $PARTS; do
    node="/dev/block/mapper/${p}${SLOT}"
    size=$(adb shell "blockdev --getsize64 $node 2>/dev/null" | tr -d '\r')
    if [ -z "$size" ]; then
        echo "  SKIP $p (no $node)"
        continue
    fi
    echo "  pull $p ($size bytes)"
    adb exec-out "dd if=$node bs=1M 2>/dev/null" > "$OUT/${p}${SLOT}.img"

    got=$(stat -c %s "$OUT/${p}${SLOT}.img")
    [ "$got" = "$size" ] || { echo "    SIZE MISMATCH: got $got want $size" >&2; exit 1; }

    want=$(adb shell "sha256sum $node 2>/dev/null" | awk '{print $1}' | tr -d '\r')
    have=$(sha256sum "$OUT/${p}${SLOT}.img" | awk '{print $1}')
    if [ -n "$want" ] && [ "$want" != "$have" ]; then
        echo "    SHA MISMATCH: $have != $want" >&2; exit 1
    fi
    echo "    ok sha256=$have"
done

echo
echo "Extract with:"
echo "  for p in $PARTS; do fsck.erofs --extract=extracted/\$p $OUT/\${p}${SLOT}.img; done"
