# A better and simpler solution for Arch Linux users

If you're using Arch Linux, you can actually edit the `PKGBUILD` file of the `linux` package. This solution is tested and works with the Nvidia driver seamlessly.

## Step 1: Install the AW88399 Firmware

Copy the `aw88399_acf.bin` file provided in this repository to `/lib/firmware/aw88399_acf.bin`:

```bash
cp -f fix/firmware/aw88399_acf.bin /lib/firmware/aw88399_acf.bin
```

## Step 2: Clone the `linux` package

Use `pkgctl` to clone the package:

```bash
pkgctl repo clone --protocol=https linux
```

## Step 3: Patch the Linux Kernel Sources

Copy the `16iax10h-audio-linux-<YOUR_KERNEL_VERSION>.patch` file from this repository's `fix/patches` folder into the cloned package directory (containing `PKGBUILD`) and add it to the `source` array in the `PKGBUILD` file:

```
# ...
source=(
  # ...
  16iax10h-audio-linux-7.1.2.patch
)
# ...
```

The `prepare` script will automatically apply the patch when you build the package.

## Step 4: Configure the Kernel

For the fix to work, the following kernel configuration options must be added to the `config.x86_64` file in the cloned package directory (containing `PKGBUILD`):

```
CONFIG_SND_HDA_SCODEC_AW88399=m
CONFIG_SND_HDA_SCODEC_AW88399_I2C=m
CONFIG_SND_SOC_AW88399=m
CONFIG_SND_SOC_SOF_INTEL_TOPLEVEL=y
CONFIG_SND_SOC_SOF_INTEL_COMMON=m
CONFIG_SND_SOC_SOF_INTEL_MTL=m
CONFIG_SND_SOC_SOF_INTEL_LNL=m
```

## Step 5: Compile and Install the Kernel

```bash
updpkgsums
MAKEFLAGS="-j$(nproc)" makepkg -si --skippgpcheck
```

`--skippgpcheck` is required because we're building a custom kernel and the PGP signature won't match the official one.

## Step 6: Install Nvidia DKMS Drivers

`nvidia-open` won't work with a custom kernel, so you need to install `nvidia-open-dkms` instead:

```bash
sudo pacman -S nvidia-open-dkms
```

## Step 7: Enjoy Working Audio!

That's it! Your audio should now work correctly and permanently after a reboot. This fix will persist across reboots with no additional steps required.
