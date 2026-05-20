# Guide: Linux Audio on the Lenovo Legion Pro 7i Gen 10 (16IAX10H)

This guide explains how to get audio working correctly on the Lenovo Legion Pro 7i Gen 10 (**16IAX10H**). Since this solution is still very new, it will take some time for all components to be properly integrated into the Linux kernel. Until that happens, you can follow the steps below, which have been rigorously tested and are confirmed to work. This guide will be updated for future kernel versions as they are released, until the fix is fully integrated into the kernel.

## WE NEED SOMEONE TO UPSTREAM THIS INTO THE KERNEL, DRIVERS AND OTHER RELEVANT PACKAGES! PLEASE VOLUNTEER TO DO THIS!

If you have time, please work on upstreaming these changes to the Linux kernel and keep us posted in your progress. [This comment on the Kernel Bugzilla](https://bugzilla.kernel.org/show_bug.cgi?id=218329#c24) has some pointers.

## Filing issues

Please don't file issues to complain about something missing. Filing issues about something being broken is fine, but if it's a request to add something, either add it yourself or just... politely don't speak.

## Confirmed to work on multiple devices!

To our surprise, this fix actually fixed audio on more laptops than just the 16IAX10H! List of confirmed compatible devices:

- Lenovo Legion Pro 7i Gen 10 (**16IAX10H**)
- Lenovo Legion Pro 7 Gen 10 (**[16AFR10H](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/30)**)
- Lenovo Legion 5i Gen 9 (**[16IRX9](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/20)**)
- Lenovo Legion Y9000P (**[IAX10H](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/42)**)

If your laptop has a similar sound architecture and you're running into similar problems, please try this fix and let us know if it works for you too!

## Ubuntu 26.04 guide

For Ubuntu 26.04 users, see the [Ubuntu 26.04 speaker fix guide](UBUNTU_26_04.md). It covers Ubuntu-specific diagnosis, `bindeb-pkg` kernel package builds, GRUB, Secure Boot, and recovery steps.

## Step 1: Install the AW88399 Firmware

Copy the `aw88399_acf.bin` file provided in this repository to `/lib/firmware/aw88399_acf.bin`:

```bash
cp -f fix/firmware/aw88399_acf.bin /lib/firmware/aw88399_acf.bin
```

If you prefer to obtain your own copy of this firmware blob, [follow these instructions](https://bugzilla.kernel.org/show_bug.cgi?id=218329#c18).

## Step 2: Download the Linux Kernel Sources

This patch is tested under the following kernel versions. Click the one you desire to download its corresponding source code:

 - [Linux 7.0](https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.0.tar.xz)
 - [Linux 6.19.11](https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.19.11.tar.xz)

## Step 3: Patch the Linux Kernel Sources

Copy the `16iax10h-audio-linux-<YOUR_KERNEL_VERSION>.patch` file from this repository's `fix/patches` folder into the root of your Linux kernel source directory. Then run:

```bash
patch -p1 < 16iax10h-audio-linux-<YOUR_KERNEL_VERSION>.patch
```

The patch should apply successfully to 10 files without any errors.

## Step 4: Configure the Kernel

For the fix to work, the following kernel configuration options must be enabled:

```
CONFIG_SND_HDA_SCODEC_AW88399=m
CONFIG_SND_HDA_SCODEC_AW88399_I2C=m
CONFIG_SND_SOC_AW88399=m
CONFIG_SND_SOC_SOF_INTEL_TOPLEVEL=y
CONFIG_SND_SOC_SOF_INTEL_COMMON=m
CONFIG_SND_SOC_SOF_INTEL_MTL=m
CONFIG_SND_SOC_SOF_INTEL_LNL=m
```

Configure the rest of the kernel as appropriate for your machine. 

<details>
<summary><h3>Using your existing system kernel configuration (optional)</h3></summary>

Often this configuration can be accomplished simply by dumping your current system kernel config into a `.config` file in the root of your Linux kernel source directory: 

```
cat /proc/config.gz | gunzip > .config
```

If configured this way, paste the kernel configuration options above into the end of the `.config`. This can be done manually or with a command:

```
cat >> .config <<EOF
CONFIG_SND_HDA_SCODEC_AW88399=m
CONFIG_SND_HDA_SCODEC_AW88399_I2C=m
CONFIG_SND_SOC_AW88399=m
CONFIG_SND_SOC_SOF_INTEL_TOPLEVEL=y
CONFIG_SND_SOC_SOF_INTEL_COMMON=m
CONFIG_SND_SOC_SOF_INTEL_MTL=m
CONFIG_SND_SOC_SOF_INTEL_LNL=m
EOF
```
</details>


## Step 5: Compile and Install the Kernel

```bash
make -j24
make -j24 modules
sudo make -j24 modules_install
sudo cp -f arch/x86/boot/bzImage /boot/vmlinuz-linux-16iax10h-audio
```

## Step 6: Install Nvidia DKMS Drivers

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

## Step 7: Generate the initramfs

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

## Step 8: Reboot into the Patched Kernel

Reboot into the patched kernel. After rebooting, run `uname -a` to verify that you're running the correct kernel.

## Step 9: Enjoy Working Audio!

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
