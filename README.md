# Guide: Linux Audio on the Lenovo Legion Pro 7i Gen 10 (16IAX10H)

This guide explains how to get audio working correctly on the Lenovo Legion Pro 7i Gen 10 (**16IAX10H**).

## Upstream status

### Driver status

The AW88399 HDA side codec driver has been merged into the Linux kernel and is now included in 7.3+.
Once you are running kernel 7.3 or later, the laptop's woofers will work *without any custom kernel*, **provided the firmware is installed at the correct location and the AW88399 HDA modules are loaded correctly** (see the troubleshooting section below).

> [!NOTE]
> The Legion R9000P AFR10 codec IDs were confirmed after the 7.3 merge window closed; hence, official upstream support for this model will be included starting with kernel 7.4.
> Owners of this model currently need to switch to 7.4-rc1+ kernels, or patch kernels 7.3.x using [this small backport patch](fix/patches/afr10-audio-linux-7.3.patch).
> Note that unfortunately it's not enough to use the `model=` alc269 module parameter, as that will only work on 7.4.x+ kernels ([see here for more info](https://lore.kernel.org/linux-sound/SN6PR19MB230304C2E75499FE23B53885FC8F2@SN6PR19MB2303.namprd19.prod.outlook.com/T/#t)).

### Firmware status

The required firmware binaries for the supported Lenovo Legion models have been [merged in the `linux-firmware` repo on 2026/11/14](https://gitlab.com/kernel-firmware/linux-firmware/-/commit/1cafb17a3ead182e37ab572964bee2a692a554c5); until these files start being packaged by distributions, users will need to install firmware manually regardless of kernel version.

> [!IMPORTANT]
> The driver included in kernel 7.3 requests firmware under a different path and will not find the officially packaged files; therefore, on versions 7.3.x, manual firmware installation will be needed regardless.
>
> Kernel 7.4 includes [breaking changes regarding firmware loading](https://lore.kernel.org/linux-sound/87wlrdin6q.wl-tiwai@suse.de/T/#t) that allow the driver to make use of these files; therefore, users upgrading from 7.3 to 7.4 will need to manually reinstall firmware to a different location (`/lib/firmware/awinic/aw88399_acf_<SSID>.bin` instead of `/lib/firmware/aw88399_acf.bin`), but only until the official firmware packages ship.
>
> For either case, see [step 1 of the main guide below](#step-1-install-the-aw88399-firmware) for instructions.

> [!IMPORTANT]
> The AFR10 model's IDs (17aa3934/5) were reported after the original firmware submission, and as such its firmware binaries were not merged together with the others. Therefore, AFR10 owners will still have to install firmware manually for now (see above).

## Audio still broken even on kernel 7.3+

If you are on kernel 7.3 or later and audio is still broken, please perform these checks before opening an issue:

1. Is the firmware installed?

```bash
# on kernels <7.4-rc1:
ls /lib/firmware/aw88399_acf.bin
# on kernels >=7.4-rc1:
ls /lib/firmware/awinic/aw88399_acf_*.bin
```

If this returns "No such file or directory", the firmware is missing. Install the firmware by following the instruction at [step 1 of the main guide below](#step-1-install-the-aw88399-firmware). *This step is required regardless of kernel version until firmware binaries are accepted into the `linux-firmware` repository and start being shipped by distributions.*

2. Are the kernel modules loaded?

```bash
lsmod | grep snd_hda_scodec_aw88399
```

You need to have the `snd_hda_scodec_aw88399` and `snd_hda_scodec_aw88399_i2c` modules loaded for the driver to be enabled. If they are missing from `lsmod`, check the config parameters that were used to build the current kernel:

```bash
cat /boot/config-$(uname -r) | grep CONFIG_SND_HDA_SCODEC_AW88399
# or on some distros:
zcat /proc/config.gz | grep CONFIG_SND_HDA_SCODEC_AW88399
```

`CONFIG_SND_HDA_SCODEC_AW88399_I2C=m` needs to be there for the driver to work. If instead you see `# CONFIG_SND_HDA_SCODEC_AW88399_I2C is not set`, your distribution has not enabled the driver; contact your kernel maintainers and ask them to enable this config parameter.

3. Did you blacklist the `i915` module?

Add `snd_hda_core.gpu_bind=0` to the boot parameters; see [#69](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/69) for more info.

## Filing issues

Please don't file issues to complain about something missing. Filing issues about something being broken is fine, but if it's a request to add something, either add it yourself or just... politely don't speak.

## Supported devices

| Model                         | DMI  | ACPI/codec SSIDs        | Issue thread | Upstream support introduced in |
|-------------------------------|------|-------------------------|--------------|--------------------------------|
| Legion Pro 7i Gen 10 16IAX10H | 83F5 | `0x17aa3906/0x17aa3907` | --           | 7.3-rc1                        |
| Legion Pro 7 Gen 10 16AFR10H  | 83RU | `0x17aa3938/0x17aa3939` | [nadimkobeissi/#30](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/30) | 7.3-rc1 |
| Legion Y9000P IAX10           | 83F5 | `0x17aa3906/0x17aa3907` | [nadimkobeissi/#42](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/42) | 7.3-rc1 |
| Legion R9000P ADR10           | 83LV | `0x17aa3927/0x17aa3928` | [marco-giunta/#3](https://github.com/marco-giunta/legion-pro7-gen10-audio/issues/3) | 7.3-rc1 |
| Legion R9000P ADR10H          | 83RV | `0x17aa3936/0x17aa3937` | [marco-giunta/#8](https://github.com/marco-giunta/legion-pro7-gen10-audio/issues/8) | 7.3-rc1 |
| Legion R9000P AFR10           | 83F6 | `0x17aa3934/0x17aa3935` | [marco-giunta/#9](https://github.com/marco-giunta/legion-pro7-gen10-audio/issues/9) | 7.4-rc1 |

The driver may apply to other devices with the same sound architecture (legacy HDA, AW88399 smart amp driving two woofers as side-codecs to a main Realtek HDA codec via I2C). To check if this holds for a device not listed above, please read [this guide](https://github.com/marco-giunta/legion-pro7-gen10-audio#will-this-patch-work-on-other-laptops).

If you own a 16ADR10H, IAX10H or AFR10H, please [read this](https://github.com/marco-giunta/legion-pro7-gen10-audio#models-potentially-supported).

## Note on outdated workarounds

Older versions of this patch required adding `snd_intel_dspcfg.dsp_driver=3` as a kernel boot parameter to force SOF mode, manually configuring volume scales with `amixer`, or manually selecting the "Analog Stereo Duplex" profile in the OS sound settings. **These are no longer necessary with the current patch:**

- The `dsp_driver=3` parameter is now actively harmful unless your `alsa-ucm-conf` package is [fully up to date](https://github.com/alsa-project/alsa-ucm-conf/commit/c17dfb63aeff72efb37996049c5dda525c33cd31), as it disables the internal microphone on older versions.
- Volume controls are now fixed at the kernel level, so no userspace workarounds are needed.
- Stereo 2.0 profiles are now the only available ones because the current patch suppresses the spurious 4.0 surround profiles that previously appeared alongside it.

If you are following a guide that mentions any of these steps, that guide is based on an outdated version of the patch, and some care is needed (see the note in the "community forks and tools" section below).

## Patch installation overview (kernels <7.3 or 7.3+ codec IDs backports)
*At a high level*, getting audio working on the supported Legion requires you do the following:

1. **Install the AW88399 firmware**: copy `aw88399_acf.bin` from this repository to the correct location depending on your kernel version ([step 1 of the main guide below](#step-1-install-the-aw88399-firmware)).
2. **Obtain and modify the config file used to build your pre-existing kernel**: get the current kernel's configs using e.g. `cp /boot/config-$(uname -r) .config` or `cat /proc/config.gz | gunzip > .config`, and append this line at the end:
```
CONFIG_SND_HDA_SCODEC_AW88399_I2C=m
```
Depending on your build method, you may be able to pass this Kconfig directly as a parameter rather than via editing a pre-existing config file.

3. **Patch, compile, and install the Linux kernel** (and also setup e.g. the NVIDIA drivers, initramfs, etc.)

There are multiple ways to perform step 3. A universal, general purpose approach is to obtain the upstream Linux source code and use their `make` utilities (see main guide below). Alternatively, distros such as Fedora, Arch Linux, CachyOS, etc., offer automation tools that make this process much simpler.
It's recommended you do your own research on "how to compile and install a custom patched kernel on distro x"; any such guide will be fine as long as you use the patch files from this repo, the extra config parameters from above, and have the firmware installed at the right location.

For example, [the Fedora documentation](https://docs.fedoraproject.org/en-US/quick-docs/kernel-build-custom/) contains both a guide specific to Fedora (to compile and install the patched kernel in RPM format via `fedpkg`), as well as a distro-independent guide based on the vanilla kernel's `make` utilies. While the result will be equivalent for both, the former method will be much better automated regarding compilation and (un)installation.

Below you'll find a step-by-step guide which is mostly meant as a general template based on the universal method; please do your own research on which tools may be available on your distro to simplify the task.

## Community forks and tools

Many forks contain adapted versions of the general guide in order to rely on certain distributions' automation tools; below is a table of the known forks (sorted alphabetically). If you want yours added, please open an issue or a PR.

Note that, apart from [`marco-giunta/legion-pro7-gen10-audio`](https://github.com/marco-giunta/legion-pro7-gen10-audio) (Fedora-specific fork), these tools and guides have *not* been verified by the maintainers of this repo; furthermore, some may be unmaintained and/or contain extra steps based on deprecated versions of the patch (see "note on outdated workarounds" above). Once again, please do your own research.

As a general rule of thumb, if you use the most recent patch from this repository and ensure `CONFIG_SND_HDA_SCODEC_AW88399_I2C=m` is enabled, any guide's compilation steps will work regardless of the kernel version shown (provided the firmware is installed correctly); any other audio-specific step contradicting the above note on outdated workarounds should be ignored (instead things relating to e.g. NVIDIA drivers, initramfs, secure boot, etc. are part of the kernel building process, and as such are still required).

In other words, the kernel compilation guides below should still be relevant regardless of when they were written (with the caveats mentioned above).

| Distribution | Repository | Notes |
|--------------|------------|-------|
| Arch Linux | [imitoy/linux-legion-audio-fix](https://github.com/imitoy/linux-legion-audio-fix) | Pre-built pacman repository with patched kernel and firmware packages: add the repo to `/etc/pacman.conf` and install, zero compilation required. |
| Arch Linux | [imitoy/linux-PKGBUILD](https://github.com/imitoy/linux-PKGBUILD) | Automated build and install via `makepkg`, with a `PKGBUILD` that automatically downloads the patch. Companion [firmware package](https://github.com/imitoy/aw88399_acf-PKGBUILD) also available. |
| Arch Linux | [zty012/16iax10h-linux-sound-saga](https://github.com/zty012/16iax10h-linux-sound-saga/blob/main/ARCH.md) | Simplified compilation & installation method based on editing the `PKGBUILD` file of the `linux` package. |
| CachyOS | (none) | Patch series v1 has been merged in the [Cachy kernel 7.2-rc4-1](https://github.com/CachyOS/linux/releases/tag/cachyos-7.2-rc4-1) and [7.1.6-1](https://github.com/CachyOS/linux/releases/tag/cachyos-7.1.6-1); v2 in [7.2-rc6-2](https://github.com/CachyOS/linux/releases/tag/cachyos-7.2-rc6-2). Only the firmware installation is needed |
| Debian | [Levithani/#62](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/62) | Tutorial on compiling the patched kernel in installable `.deb` format and the NVIDIA drivers in `dkms` format. |
| Fedora | [blogmanix/#41](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/41) | Tutorial on compiling the kernel on Fedora closely following the README's method. |
| Fedora | [marco-giunta/legion-pro7-gen10-audio](https://github.com/marco-giunta/legion-pro7-gen10-audio) | Pre-built RPMs & automated install script (zero compilation required), easyeffects profiles, comprehensive guides & FAQ. By the co-author and current maintainer of the patch. |
| Fedora | [sebetc4/16iax10h-linux-sound-saga-fedora](https://github.com/sebetc4/16iax10h-linux-sound-saga-fedora/tree/main/patch-kernel-fedora) | Tutorial on compiling the patched kernel in RPM format via `fedpkg`, with automation build scripts. |
| Ubuntu | [jbravoMlg/16iax10h-linux-sound-saga](https://github.com/jbravoMlg/16iax10h-linux-sound-saga/blob/add-ubuntu-26-04-audio-guide/UBUNTU_26_04.md) | Tutorial on compiling and installing the kernel in `.deb` format under Ubuntu. |
| Ubuntu | [nuclearcat/aw88399-hda-dkms](https://github.com/nuclearcat/aw88399-hda-dkms) | Tutorial on installing the patched kernel as an external `dkms` module, no kernel compilation required. |
| Ubuntu | [paul-lupu/legion-16iax10h-ubuntu-audio](https://github.com/paul-lupu/legion-16iax10h-ubuntu-audio) | Tutorial on compiling the kernel under Ubuntu using `make` for the kernel and `dkms` for the NVIDIA drivers. |
| Ubuntu | [sergeych/legion-ubuntu-audio](https://github.com/sergeych/legion-ubuntu-audio) | Guide and automated build script for Ubuntu 26.04; includes a `setup-kernel.sh` helper that downloads, patches, and packages the kernel as `.deb` files. Also covers a specific failure mode where the graphical LUKS password prompt becomes unresponsive on encrypted drives because `i915` is absent from the custom kernel's initramfs, leaving users unable to unlock their disk at boot (along with more Ubuntu-specific documentation, covering e.g. Secure Boot). |

---

A detailed step-by-step guide for Arch Linux and Fedora (based on the general method) follows below.

## Main guide

### Step 1: Install the AW88399 Firmware

#### Kernels <7.4-rc1 (any stock 7.3 or <=7.2 patched with the patch from this repo)
Copy the `aw88399_acf.bin` file provided in this repository to `/lib/firmware/aw88399_acf.bin`:

```bash
sudo cp fix/firmware/aw88399_acf.bin /lib/firmware/aw88399_acf.bin
```

#### Kernels >=7.4-rc1
Starting with kernel 7.4, the firmware path changes from `/lib/firmware/aw88399_acf.bin` to `/lib/firmware/awinic/aw88399_acf_<SSID>.bin`, where `<SSID>` is the ACPI SSID for your device.

Once the firmware binaries are officially accepted and start shipping with distributions, you will only need to update your firmware packages. Until then, you will need to install them manually to the new location:

1. Identify the two ACPI/codec SSIDs of your device from the ["supported devices" table above](#supported-devices). For example, the Legion Pro 7i 16IAX10H has as its two IDs `17aa3906` and `17aa3907` (ignore the `0x` part in front).
2. Copy the same `/lib/firmware/aw88399_acf.bin` file you already have to both `/lib/firmware/awinic/aw88399_acf_<SSID-1>.bin` and `/lib/firmware/awinic/aw88399_acf_<SSID-2>.bin` (**ensure the SSID part is lowercase and without `0x` in front**). For example, on the 16IAX10H:
```sh
sudo mkdir -p /lib/firmware/awinic
sudo cp /lib/firmware/aw88399_acf.bin /lib/firmware/awinic/aw88399_acf_17aa3906.bin
sudo cp /lib/firmware/aw88399_acf.bin /lib/firmware/awinic/aw88399_acf_17aa3907.bin
```

If you prefer to obtain your own copy of this firmware blob, [follow these instructions](https://bugzilla.kernel.org/show_bug.cgi?id=218329#c18).

### Step 2: Download the Linux Kernel Sources

This patch is tested under the following kernel versions. Click the one you desire to download its corresponding source code:

- [Linux 7.2.9](https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.2.9.tar.xz)

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

Then append this line to the resulting `.config` file:

```
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

## Known limitations

### Echo on the headphone jack

When using a headset over the jack, audio output bleeds into the microphone input due to hardware crosstalk on the codec. This is not a Linux-specific bug; Windows fixes it through a proprietary software pipeline that cannot be replicated at the kernel level. A partial software workaround in the form of an easyeffects profile is available [here](https://github.com/marco-giunta/legion-pro7-gen10-audio/tree/legion_audio/easyeffects). For the full technical investigation, see [issue #34](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/34).

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
