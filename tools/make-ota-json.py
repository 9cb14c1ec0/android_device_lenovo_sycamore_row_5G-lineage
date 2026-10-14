#!/usr/bin/env python3
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
"""Write the Updater JSON (lineage.updater.uri) for a built OTA zip.

usage: make-ota-json.py <lineage-*.zip> <download url> [<output json>]

The Updater fetches a JSON list of builds and offers those newer than the
running one whose type matches ro.lineage.releasetype. Fields follow
packages/apps/Updater's NetworkUpdate.
"""

import hashlib
import json
import os
import re
import sys
import zipfile


def ota_metadata(zip_path):
    with zipfile.ZipFile(zip_path) as z:
        text = z.read("META-INF/com/android/metadata").decode()
    return dict(line.split("=", 1) for line in text.splitlines() if "=" in line)


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    if len(sys.argv) not in (3, 4):
        sys.exit(__doc__)
    zip_path, url = sys.argv[1], sys.argv[2]
    filename = os.path.basename(zip_path)
    # lineage-23.2-20261013-UNOFFICIAL-sycamore_row_5G.zip
    m = re.match(r"lineage-([0-9.]+)-\d{8}-([A-Za-z]+)-", filename)
    if not m:
        sys.exit(f"unexpected zip name: {filename}")
    version, release_type = m.group(1), m.group(2).lower()

    meta = ota_metadata(zip_path)
    build = {
        "datetime": int(meta["post-timestamp"]),
        "type": release_type,
        "version": version,
        "files": [{
            "filename": filename,
            "os_patch_level": meta["post-security-patch-level"],
            "os_sdk_level": int(meta["post-sdk-level"]),
            "ota_property_files": meta["ota-property-files"].strip(),
            "sha256": sha256(zip_path),
            "size": os.path.getsize(zip_path),
            "url": url,
        }],
    }
    out = json.dumps([build], indent=2) + "\n"
    if len(sys.argv) == 4:
        with open(sys.argv[3], "w") as f:
            f.write(out)
    else:
        sys.stdout.write(out)


if __name__ == "__main__":
    main()
