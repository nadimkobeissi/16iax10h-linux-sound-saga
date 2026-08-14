# Guide: Linux Audio on the Lenovo Legion Pro 7i Gen 10 (16IAX10H)

This guide explains how to get audio working correctly on the Lenovo Legion Pro 7i Gen 10 (**16IAX10H**).

## Upstream status

The AW88399 HDA side codec driver has been accepted upstream and is expected to ship with Linux kernel 7.3. Once you are running kernel 7.3 or later, the laptop's woofers will work without any custom kernel, provided the `aw88399_acf.bin` firmware is installed in `/lib/firmware` (see step 1 of the main guide below).

Until kernel 7.3 is released, this guide explains how to enable full audio support on current kernels and will continue to be updated as needed.

The only remaining step to achieve a completely zero-configuration experience is making the firmware available through the `linux-firmware` repository under a compatible license, allowing Linux distributions to install it automatically. Until then, users will need to install the firmware manually. See [#65](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/65#issuecomment-5130273339) for more information on this issue and how to help with the firmware effort.

## Filing issues

Please don't file issues to complain about something missing. Filing issues about something being broken is fine, but if it's a request to add something, either add it yourself or just... politely don't speak.

## Supported devices

- Lenovo Legion Pro 7i Gen 10 (**16IAX10H**)
- Lenovo Legion Pro 7 Gen 10 (**[16AFR10H](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/30)**)
- Lenovo Legion 5i Gen 9 (**[16IRX9](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/20)**)
- Lenovo Legion Y9000P (**[IAX10H](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/42)**)
- Lenovo Legion R9000P (**[ADR10](https://github.com/marco-giunta/legion-pro7-gen10-audio/issues/3)**)
- Lenovo Legion R9000P (**[ADR10H](https://github.com/marco-giunta/legion-pro7-gen10-audio/issues/8)**)

This patch may apply to other devices with the same sound architecture (aw88399 smart amp driving two woofers as side-codecs to a main Realtek HDA codec via I2C). To check if this holds for device x not listed above, please read [this guide](https://github.com/marco-giunta/legion-pro7-gen10-audio#will-this-patch-work-on-other-laptops).

## Patch installation overview
*At a high level*, getting audio working on the supported Legion requires you do the following:

1. **Install the AW88399 firmware**: copy `aw88399_acf.bin` from this repository to `/lib/firmware/aw88399_acf.bin` (step 1 of the main guide below).
2. **Obtain and modify the config file used to build your pre-existing kernel**: get the current kernel's configs using e.g. `cp /boot/config-$(uname -r) .config` or `cat /proc/config.gz | gunzip > .config`, and append at the end these lines:
```
CONFIG_SND_HDA_SCODEC_AW88399=m
CONFIG_SND_HDA_SCODEC_AW88399_I2C=m
```
Depending on your build method, you may be able to pass these two options directly as parameters rather than via editing a pre-existing config file.

3. **Patch, compile, and install the Linux kernel** (and also setup e.g. the NVIDIA drivers, initramfs, etc.)

There are multiple ways to perform step 3. A universal, general purpose approach is to obtain the upstream Linux source code and use their `make` utilities (see main guide below). Alternatively, distros such as Fedora, Arch Linux, CachyOS, etc., offer automation tools that make this process much simpler.
It's recommended you do your own research on "how to compile and install a custom patched kernel on distro x"; any such guide will be fine as long as you use the patch files from this repo, the extra config parameters from above, and have the firmware installed at the right location.

For example, [the Fedora documentation](https://docs.fedoraproject.org/en-US/quick-docs/kernel-build-custom/) contains both a guide specific to Fedora (to compile and install the patched kernel in RPM format via `fedpkg`), as well as a distro-independent guide based on the vanilla kernel's `make` utilies. While the result will be equivalent for both, the former method will be much better automated regarding compilation and (un)installation.

Below you'll find a step-by-step guide which is mostly meant as a general template based on the universal method; please do your own research on which tools may be available on your distro to simplify the task.

## Community forks and tools

Many forks contain adapted versions of the general guide in order to rely on certain distributions' automation tools; below is a table of the known forks (sorted alphabetically). If you want yours added, please open an issue or a PR.

Note that, apart from [`marco-giunta/legion-pro7-gen10-audio`](https://github.com/marco-giunta/legion-pro7-gen10-audio) (Fedora-specific fork), these tools and guides have *not* been verified by the maintainers of this repo; furthermore, some may be unmaintained and/or based on deprecated versions of the patch (for example, manually configuring volume scales with `amixer` is no longer necessary). Once again, please do your own research.

| Distribution | Repository | Notes |
|---|---|---|
|Arch Linux | [imitoy/linux-PKGBUILD](https://github.com/imitoy/linux-PKGBUILD) | Automated build and install `makepkg`-based approach, relying on a `PKGBUILD` that can automatically download the patch. |
| Arch Linux | [zty012/16iax10h-linux-sound-saga](https://github.com/zty012/16iax10h-linux-sound-saga/blob/main/ARCH.md) | Simplified compilation & installation method based on editing the `PKGBUILD` file of the `linux` package. |
| CachyOS | (none) | Patch series v1 has been merged in the [Cachy kernel 7.2-rc4-1](https://github.com/CachyOS/linux/releases/tag/cachyos-7.2-rc4-1) and [7.1.6-1](https://github.com/CachyOS/linux/releases/tag/cachyos-7.1.6-1); v2 in [7.2-rc6-2](https://github.com/CachyOS/linux/releases/tag/cachyos-7.2-rc6-2). Only the firmware installation is needed |
| Debian | [Levithani/#62](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/62) | Tutorial on compiling the patched kernel in installable `.deb` format and the NVIDIA drivers in `dkms` format. |
| Fedora | [blogmanix/#41](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/41) | Tutorial on compiling the kernel on Fedora closely following the README's method. |
| Fedora | [marco-giunta/legion-pro7-gen10-audio](https://github.com/marco-giunta/legion-pro7-gen10-audio) | Pre-built RPMs & automated install script (zero compilation required), easyeffects profiles, comprehensive guides & FAQ. By the co-author and current maintainer of the patch. |
| Fedora | [sebetc4/16iax10h-linux-sound-saga-fedora](https://github.com/sebetc4/16iax10h-linux-sound-saga-fedora/tree/main/patch-kernel-fedora) | Tutorial on compiling the patched kernel in RPM format via `fedpkg`, with automation build scripts. |
| Ubuntu | [jbravoMlg/16iax10h-linux-sound-saga](https://github.com/jbravoMlg/16iax10h-linux-sound-saga/blob/add-ubuntu-26-04-audio-guide/UBUNTU_26_04.md) | Tutorial on compiling and installing the kernel in `.deb` format under Ubuntu. |
| Ubuntu | [nuclearcat/aw88399-hda-dkms](https://github.com/nuclearcat/aw88399-hda-dkms) | Tutorial on installing the patched kernel as an external `dkms` module, no kernel compilation required. |
| Ubuntu | [paul-lupu/legion-16iax10h-ubuntu-audio](https://github.com/paul-lupu/legion-16iax10h-ubuntu-audio) | Tutorial on compiling the kernel under Ubuntu using `make` for the kernel and `dkms` for the NVIDIA drivers. |

For Ubuntu systems using dracut and an encrypted root, see the locally validated [Ubuntu 26.04 encrypted-root addendum](UBUNTU_26_04.md). It covers the Plymouth password-prompt failure caused by a missing `i915` module, verification, safe rollback, and optional early-boot tracing.

---

A detailed step-by-step guide for Arch Linux and Fedora (based on the general method) follows below.

## Main guide

### Step 1: Install the AW88399 Firmware

Copy the `aw88399_acf.bin` file provided in this repository to `/lib/firmware/aw88399_acf.bin`:

```bash
cp -f fix/firmware/aw88399_acf.bin /lib/firmware/aw88399_acf.bin
```

If you prefer to obtain your own copy of this firmware blob, [follow these instructions](https://bugzilla.kernel.org/show_bug.cgi?id=218329#c18).

### Step 2: Download the Linux Kernel Sources

This patch is tested under the following kernel versions. Click the one you desire to download its corresponding source code:

- [Linux 7.1.6](https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.1.6.tar.xz)
- [Linux 7.2-rc6](https://git.kernel.org/torvalds/t/linux-7.2-rc6.tar.gz)

### Step 3: Patch the Linux Kernel Sources

Copy the `16iax10h-audio-linux-<YOUR_KERNEL_VERSION>.patch` file from this repository's `fix/patches` folder into the root of your Linux kernel source directory. Then run:

```bash
patch -p1 < 16iax10h-audio-linux-<YOUR_KERNEL_VERSION>.patch
```

The patch should apply successfully to 14 files without any errors.

Notice that, if you use a `.patch` file prepared for an older version of the kernel than the one you're compiling, you may get messages like `Hunk ... succeeded at ...`; as long as these are the only such messages, you can ignore them.
Instead, if you see `... out of ... hunks FAILED ...`, the patch file at hand is no longer compatible with the kernel you're compiling. In this case, you should be able to find more up to date patches at [marco-giunta/legion-pro7-gen10-audio](https://github.com/marco-giunta/legion-pro7-gen10-audio).
Alternatively, you can also fix the conflicts manually if you know how.

### Step 4: Configure the Kernel

Start from your currently running kernel's config:

```bash
# while in your kernel source working directory, run:
cp /boot/config-$(uname -r) .config
# alternatively, on some distros you can also use:
cat /proc/config.gz | gunzip > .config
```

Then append these two lines to the resulting `.config` file:

```
CONFIG_SND_HDA_SCODEC_AW88399=m
CONFIG_SND_HDA_SCODEC_AW88399_I2C=m
```

If you are building a kernel version newer than the one your config was compiled for, you may need to run `make olddefconfig` after appending the lines above, to resolve any new configuration symbols introduced in the newer kernel (by setting the new symbols to their default values).

### Step 5: Compile and Install the Kernel

```bash
make -j$(nproc)
make -j$(nproc) modules
sudo make -j$(nproc) modules_install
sudo cp -f arch/x86/boot/bzImage /boot/vmlinuz-linux-16iax10h-audio
```

### Step 6: Install Nvidia DKMS Drivers

To ensure proper graphics integration, you'll need to install the Nvidia DKMS drivers for your custom kernel.

<details>
<summary><h3>Arch Linux (Tested)</h3></summary>

Install the Nvidia DKMS package and headers:

```bash
sudo pacman -S nvidia-open-dkms
```

The DKMS system will automatically build the Nvidia kernel modules for your custom kernel. After installation, reboot to load the new drivers.

In case you later need to recompile and reinstall the driver, use the `dkms` utility:

```bash
sudo dkms build nvidia/580.105.08 --force
sudo dkms install nvidia/580.105.08 --force
```

You may need to replace `580.105.08` with the actual Nvidia driver version.

</details>

### Step 7: Generate the initramfs

The process differs between distributions, as some use `dracut` while others use `mkinitcpio`. Instructions for common distributions are provided below.

<details>
<summary><h3>Arch Linux (Tested)</h3></summary>

First, create a new preset file for your custom kernel:

```bash
sudo cp /etc/mkinitcpio.d/linux.preset /etc/mkinitcpio.d/linux-16iax10h-audio.preset
```

Edit `/etc/mkinitcpio.d/linux-16iax10h-audio.preset` to look like this:

```bash
# mkinitcpio preset file for the 'linux-16iax10h-audio' package

ALL_kver="/boot/vmlinuz-linux-16iax10h-audio"
PRESETS=('default')
default_image="/boot/initramfs-linux-16iax10h-audio.img"
```

Then generate the initramfs:

```bash
sudo mkinitcpio -p linux-16iax10h-audio
```

Finally, update your bootloader configuration. For GRUB, run:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

For systemd-boot, create a new boot entry in `/boot/loader/entries/arch-16iax10h-audio.conf`:

```
title   Arch Linux (16IAX10H Audio)
linux   /vmlinuz-linux-16iax10h-audio
initrd  /initramfs-linux-16iax10h-audio.img
options root=PARTUUID=your-root-partition-uuid rw
```

Replace `your-root-partition-uuid` with your actual root partition UUID (find it by running `blkid`).
</details>

<details>
<summary><h3>Fedora</h3></summary>

First, generate the initramfs for your custom kernel:

```bash
sudo dracut --force /boot/initramfs-linux-16iax10h-audio.img --kver $(cat include/config/kernel.release)
```

Then update your bootloader configuration. For GRUB, run:

```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

For systemd-boot, create a new boot entry in `/boot/loader/entries/fedora-16iax10h-audio.conf`:

```
title   Fedora Linux (16IAX10H Audio)
linux   /vmlinuz-linux-16iax10h-audio
initrd  /initramfs-linux-16iax10h-audio.img
options root=UUID=your-root-partition-uuid rw
```

Replace `your-root-partition-uuid` with your actual root partition UUID (find it by running `blkid`).
</details>

### Step 8: Reboot into the Patched Kernel

Reboot into the patched kernel. After rebooting, run `uname -a` to verify that you're running the correct kernel.

### Step 9: Enjoy Working Audio!

That's it! Your audio should now work correctly and permanently. This fix will persist across reboots with no additional steps required.

## Disclaimer

I, Nadim Kobeissi, attest that all components of the fix provided here have been tested and work without any apparent harmful effects. The fix components are provided in good faith. However, I (as well as the main fix authors) disclaim all responsibility for any use of this fix and guide:

```
THE PROGRAM IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.
```

## Credits

Fixing this issue required weeks of intensive work from multiple people.

Virtually all engineering groundwork was done by [Lyapsus](https://github.com/Lyapsus). Lyapsus improved an incomplete kernel driver, wrote new kernel codecs and side-codecs, and contributed much more. I want to emphasize his incredible kindness and dedication to solving this issue. He is the primary force behind this fix, and without him, it would never have been possible.

I ([Nadim Kobeissi](https://nadim.computer)) conducted the initial investigation that identified the missing components needed for audio to work on the 16IAX10H on Linux. Building on what I learned from Lyapsus's work, I helped debug and clean up his kernel code, tested it, and made minor improvements. I also contributed the solution to the volume control issue documented in Step 8, and wrote this guide.

Gergo K. showed me how to extract the AW88399 firmware from the Windows driver package and install it on Linux, as documented in Step 1.

[Richard Garber](https://github.com/rgarber11) graciously contributed [the fix](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/19#issuecomment-3594367397) for making the internal microphone work.

[Marco Giunta's fork](https://github.com/marco-giunta/legion-pro7-gen10-audio) reworked all of the above engineering effort into a much more mature patch, and was reintegrated into this repository as of Linux 6.19.10.

Sincere thanks to everyone who [pledged](PLEDGE.md) a reward for solving this problem. The reward goes to Lyapsus.
