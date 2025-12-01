# Guide: Linux Audio on the Lenovo Legion Pro 7i Gen 10 (16IAX10H)

This guide explains how to get audio working correctly on the Lenovo Legion Pro 7i Gen 10 (16IAX10H).

Since this solution is still very new, it will take some time for all components to be properly integrated into the Linux kernel. Until that happens, you can follow the steps below, which have been rigorously tested and are confirmed to work.

This guide will be updated for future kernel versions as they are released, until the fix is fully integrated into the kernel.

## Step 1: Install the AW88399 Firmware

Copy the `aw88399_acf.bin` file provided in this repository to `/lib/firmware/aw88399_acf.bin`:

```bash
cp -f fix/firmware/aw88399_acf.bin /lib/firmware/aw88399_acf.bin
```

If you prefer to obtain your own copy of this firmware blob, [follow these instructions](https://bugzilla.kernel.org/show_bug.cgi?id=218329#c18).

## Step 2: Download the Linux Kernel Sources

This patch is tested under the following kernel versions. Click the one you desire to download its corresponding source code:

 - [Linux 6.18](https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.18.tar.xz).
 - [Linux 6.17.9](https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.17.9.tar.xz).
 - [Linux 6.17.8](https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.17.8.tar.xz).

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

## Step 5: Compile and Install the Kernel

```bash
make -j24
make -j24 modules
sudo make -j24 modules_install
sudo cp -f arch/x86/boot/bzImage /boot/vmlinuz-linux-16iax10h-audio
```

## Step 6: Install NVidia DKMS Drivers

To ensure proper graphics integration, you'll need to install the NVidia DKMS drivers for your custom kernel.

<details>
<summary><h3>Arch Linux (Tested)</h3></summary>

Install the NVidia DKMS package and headers:

```bash
sudo pacman -S nvidia-open-dkms
```

The DKMS system will automatically build the NVidia kernel modules for your custom kernel. After installation, reboot to load the new drivers.

In case you later need to recompile and reinstall the driver, use the `dkms` utility:

```bash
sudo dkms build nvidia/580.105.08 --force
sudo dkms install nvidia/580.105.08 --force
```

You may need to replace `580.105.08` with the actual NVidia driver version.

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
options root=PARTUUID=your-root-partition-uuid rw snd_intel_dspcfg.dsp_driver=3
```

Replace `your-root-partition-uuid` with your actual root partition UUID (find it by running `blkid`).

**Note:** You must include `snd_intel_dspcfg.dsp_driver=3` in your kernel boot parameters.

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
options root=UUID=your-root-partition-uuid rw snd_intel_dspcfg.dsp_driver=3
```

Replace `your-root-partition-uuid` with your actual root partition UUID (find it by running `blkid`).

**Note:** You must include `snd_intel_dspcfg.dsp_driver=3` in your kernel boot parameters.

</details>

## Step 8: Reboot into the Patched Kernel

Reboot into the patched kernel. After rebooting, run `uname -a` to verify that you're running the correct kernel.

## Step 9: Install the Patched ALSA UCM2 Configuration

This step is necessary for proper volume control.

Copy the files from this repository's `fix/ucm2/` folder to `/usr/share/alsa/ucm2/HDA/`, overwriting the existing files:

```bash
sudo cp -f fix/ucm2/HiFi-analog.conf /usr/share/alsa/ucm2/HDA/HiFi-analog.conf
sudo cp -f fix/ucm2/HiFi-mic.conf /usr/share/alsa/ucm2/HDA/HiFi-mic.conf
```

Then, identify your sound card ID by running:

```bash
alsaucm listcards
```

You should get something like this:

```bash
0: hw:0
  LENOVO-83F5-LegionPro716IAX10H-LNVNB161216
```

Then, run the commands below, If you got `hw:1` above, change `hw:0` to `hw:1` and `-c 0` to `-c 1`:

```bash
alsaucm -c hw:0 reset
alsaucm -c hw:0 reload
systemctl --user restart pipewire pipewire-pulse wireplumber
amixer sset -c 0 Master 100%
amixer sset -c 0 Headphone 100%
amixer sset -c 0 Speaker 100%
```

**Note:** The last three commands are for speaker calibration, not for setting your volume to maximum. They must be run for the speakers to function properly, but they do not control your actual volume level.

## Step 10: Enjoy Working Audio!

That's it! Your audio should now work correctly and permanently. This fix will persist across reboots with no additional steps required.

## Disclaimer

I, Nadim Kobeissi, attest that all components of the fix provided here have been tested and work without any apparent harmful effects. The fix components are provided in good faith. However, I (as well as the main fix authors) disclaim all responsibility for any use of this fix and guide:

```
THE PROGRAM IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.
```

## Credits

Fixing this issue required weeks of intensive work from multiple people.

Approximately 95% of the engineering work was done by [Lyapsus](https://github.com/Lyapsus). Lyapsus improved an incomplete kernel driver, wrote new kernel codecs and side-codecs, and contributed much more. I want to emphasize his incredible kindness and dedication to solving this issue. He is the primary force behind this fix, and without him, it would never have been possible.

I ([Nadim Kobeissi](https://nadim.computer)) conducted the initial investigation that identified the missing components needed for audio to work on the 16IAX10H on Linux. Building on what I learned from Lyapsus's work, I helped debug and clean up his kernel code, tested it, and made minor improvements. I also contributed the solution to the volume control issue documented in Step 8, and wrote this guide.

Gergo K. showed me how to extract the AW88399 firmware from the Windows driver package and install it on Linux, as documented in Step 1.

@rgarber11 graciously contributed [the fix](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/19#issuecomment-3594367397) for making the internal microphone work.

Sincere thanks to everyone who [pledged](PLEDGE.md) a reward for solving this problem. The reward goes to Lyapsus.
