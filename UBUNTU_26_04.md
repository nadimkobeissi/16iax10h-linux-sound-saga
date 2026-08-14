# Ubuntu 26.04 encrypted-root and dracut addendum

This is a focused supplement to the Ubuntu installation guides linked from
[README.md](README.md). It does not repeat kernel compilation, firmware,
NVIDIA DKMS, or package-installation instructions.

It documents an early-boot problem observed and resolved on Ubuntu 26.04 LTS
on a Lenovo Legion Pro 7i Gen 10 (`16IAX10H`, audio SSID `17aa:3906`) with:

- a separately mounted, unencrypted `/boot`;
- a LUKS2-encrypted root partition containing LVM;
- dracut 110;
- Plymouth;
- hybrid Intel `i915` and NVIDIA graphics;
- a custom `7.1.8-legion-audio` kernel.

The same failure can affect other custom kernel versions on this hardware.

> Keep Ubuntu's stock kernel installed and available in GRUB. It is the
> recovery path if the custom kernel, NVIDIA DKMS module, or initramfs fails.

## Symptom: a visible LUKS prompt that appears not to accept input

After selecting the custom kernel in GRUB, Plymouth displayed the graphical
disk-unlock prompt. Typed characters produced no visible masks, and submitting
the correct passphrase appeared to do nothing. The stock Ubuntu kernel still
unlocked normally.

This looked like a GRUB or keyboard problem, but it was neither:

- `/boot` was unencrypted, so GRUB had no reason to unlock the root volume;
- the custom kernel and its initramfs were already running;
- `CONFIG_SERIO_I8042=y` and `CONFIG_KEYBOARD_ATKBD=y` were built in;
- an initramfs trace confirmed that the AT keyboard, USB HID keyboard, and
  systemd password request all existed before unlock.

The custom initramfs contained NVIDIA DRM but omitted `i915`, even though
`i915` drives the internal panel. Forcing `i915` into the image and loading it
early restored the functional graphical LUKS prompt.

## Permanent dracut fix

Install the repository's dracut setting and rebuild the custom kernel's image:

```sh
sudo ./tools/ubuntu-initramfs/install.sh 7.1.8-legion-audio
```

Replace the version with the custom kernel's exact release string. The script
installs:

```text
force_drivers+=" i915 "
```

It uses dracut's `force_drivers`, rather than merely adding the module, so
`i915` is tried early enough for Plymouth. The configuration remains in
`/etc/dracut.conf.d/90-legion-audio-i915.conf`, so later dracut rebuilds retain
the fix.

Verify the rebuilt image before rebooting:

```sh
sudo lsinitrd /boot/initrd.img-7.1.8-legion-audio \
  | grep -E '/i915\.ko$|20-force_drivers.conf'
```

Both entries must be present. Required Intel graphics firmware should be
included automatically as a dependency of `i915`.

## Recovery without rebuilding

If the graphical prompt fails, reboot to GRUB and either select the stock
Ubuntu kernel or edit the custom entry:

1. Press `e` on the custom entry.
2. Remove `quiet splash` from the `linux` line.
3. Boot with `Ctrl+X` or `F10`.

This bypasses Plymouth and exposes the text-mode LUKS prompt and early boot
messages. Text-mode passphrase entry normally displays no character masks.

Do not remove the stock Ubuntu kernel until the custom kernel has passed cold
boot and suspend/resume testing.

## Optional persistent initramfs tracing

If the encrypted root never opens, its persistent journal is unavailable.
The diagnostic module in `tools/initramfs-trace` instead records limited
early-boot state to the unencrypted `/boot` filesystem.

It records:

- kernel release and command line;
- keyboard/input-device discovery;
- systemd password-request creation and removal;
- device-mapper node discovery;
- successful initramfs cleanup.

It never opens input event devices and never records keys or passphrases.

Install it and rebuild the target kernel's initramfs:

```sh
sudo ./tools/initramfs-trace/install.sh 7.1.8-legion-audio
```

After the attempted boot, inspect:

```sh
sudo cat /boot/initramfs-trace-current.log
sudo cat /boot/initramfs-trace-previous.log
```

After diagnosis, remove the tracer while retaining the permanent `i915` fix:

```sh
sudo ./tools/initramfs-trace/uninstall.sh 7.1.8-legion-audio
```

## Post-boot audio verification

Confirm the running kernel and both amplifier channels:

```sh
uname -r
journalctl -b -k | grep -E \
  'AW88399 (Bound|HDA side codec registered successfully)'
```

Expected results include channels 0 and 1, two successful registrations, and
no AW88399 firmware, I2C, timeout, or protection errors.

To prove that the bass speakers—not only the main speakers—are active, compare
a short 125 Hz tone with the ALSA bass path enabled and disabled. Use a
moderate system volume:

```sh
tone() {
  timeout 3s gst-launch-1.0 -q \
    audiotestsrc wave=sine freq="$1" volume=0.15 \
    ! audioconvert ! audioresample ! pipewiresink
}

amixer -c PCH sset 'Bass Speaker' on
tone 125
amixer -c PCH sset 'Bass Speaker' off
tone 125
amixer -c PCH sset 'Bass Speaker' on
```

Always restore `Bass Speaker` to `on`. On the validated laptop, 125 Hz was
clear with the control enabled and inaudible with it disabled; 100 Hz was
present but weaker. These are small laptop bass drivers, not subwoofers, so
strong output below roughly 80–100 Hz is not expected. Avoid prolonged or
high-volume sine-wave testing.

The validated system also passed:

- graphical LUKS unlock;
- warm and cold boot;
- normal playback without kernel audio errors;
- suspend/resume with working audio afterward.

## When this workaround is unnecessary

Do not force `i915` solely because this guide exists. First inspect the target
initramfs. If it already contains `i915.ko` and graphical unlock works, no
change is needed.

This workaround concerns custom-kernel initramfs construction; it is separate
from the AW88399 audio driver itself. Once Ubuntu ships a kernel with the
upstream audio support, a distribution-generated initramfs may handle the
graphics dependency normally.
