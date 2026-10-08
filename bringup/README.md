# Opt-in pre-data ADB and boot diagnostics

Normal builds do not include this. Build with `TB336ZA_BRINGUP=true` on a
userdebug variant to add `tb336za_adbd` (insecure root ADB that starts before
/data and APEX activation), the `tb336za-usb` service that binds the USB gadget
independently of the init property queue, and the `tb336za-state` /
`tb336za-logcat` collectors that sync logs to `/metadata/bootstat`. Seed and read
those files from recovery with `tools/bootstat-seed.sh` / `tools/bootstat-collect.sh`
in the TB336ZA workspace.

History of the bring-up probe follows.

# Temporary pre-data ADB probe

The userdebug product selects `tb336za_adbd`, a copy of the working Lineage
recovery daemon installed in `/system_ext/bin`. Its SHA-256 is
`52c73db7bfd1be69434c0aef9b2537bcfc5f225ea1194ea9e6e0f2a2462ace8d`.
It loaded successfully against the installed normal system libraries in
recovery (`--version` reported 1.0.41). Normal boot remains unverified.

The init service overrides the initial updatable ADB placeholder. Unlike that
placeholder, it can start before data/APEX activation. The APEX service can
override it later. USB setup is temporarily moved to `on init` in
`init.mt6835.usb.rc`.

Before a diagnostic boot, pre-create `/metadata/bootstat/tb336za-init-stage`
containing `pending` and label it `metadata_bootstat_file`. The init actions
update that existing file; read it from recovery if USB does not connect.

Remove this package selection, the extra file context, the USB bring-up
changes, and the marker once normal Android boot is stable. Refresh the
prebuilt from the corresponding recovery build if platform libraries change.

The current probe also starts `tb336za-state` and `tb336za-logcat` at
post-fs. They preserve properties, kernel messages, and logcat under
`/metadata/bootstat/tb336za-*`. These temporary services use the userdebug
permissive `su` domain; device SELinux stays enforcing. Preseed the files
`init-stage`, `post-fs-props`, `properties`, `dmesg`, `logcat`, and `dmesg-initial` with `pending`
and `metadata_bootstat_file` labels before each test. Remove both collectors
when bring-up is complete.

The state collector syncs each sample and retains an initial kernel snapshot
before ring-buffer rollover. Read the files from recovery after a failed
normal boot. The temporary linker-generator retry was removed once it
identified missing VNDK 33; the product now includes that compatibility APEX.
