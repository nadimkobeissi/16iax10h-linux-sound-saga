# Persistent initramfs trace

This dracut module records enough early-boot state to diagnose a LUKS password
prompt that appears but does not accept input.  It writes to the unencrypted
`/boot` filesystem, so the trace survives a stalled boot and a hard reset.

The trace records milestones, kernel command line, input device discovery,
systemd password-agent request creation, and mapper device appearance.  It
does **not** open input event devices and never records keys or passphrases.

Install it and rebuild the custom kernel's initramfs with:

```sh
sudo ./tools/initramfs-trace/install.sh 7.1.8-legion-audio
```

After testing a boot, inspect:

```sh
sudo cat /boot/initramfs-trace-current.log
sudo cat /boot/initramfs-trace-previous.log
```

`current` is the current/most recent boot.  At the beginning of the next boot
it is renamed to `previous`, which preserves the trace from a failed boot.

After diagnosis, remove the tracer and its logs while retaining the permanent
Ubuntu `i915` initramfs fix:

```sh
sudo ./tools/initramfs-trace/uninstall.sh 7.1.8-legion-audio
```
