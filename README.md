# $900 Bug Bounty to Whoever Fixes the Lenovo Legion Pro 7 16IAX10H's Speakers on Linux

We are a bunch of Linux users with the Lenovo Legion Pro 7 (16IAX10H) and we are **sick and tired** of our speakers not working properly. We also suck at writing Linux kernel audio drivers, especially when weird things like "Awinic smart amplifiers" are involved. **If you help us make sure that Linux has support for audio on our laptops, we will send you a lot of money.**

## What is the problem?

The internal speakers on my Lenovo Legion Pro 7 16IAX10H (and several other Lenovo laptops with the Realtek ALC3306 codec) produce extremely low volume audio that sounds tinny and muffled - as if only the tweeters are working, not the woofers.

## Bug bounty pledges

The following individuals pledge the following amount to the bug bounty, to be paid in full to whoever fixes this bug:

- **$500 USD** pledged by @nadimkobeissi (me, organizer of this effort)
- **$200 USD** [pledged](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/1) by @Detritalgeo
- **$100 USD** [pledged](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/2) by @cerroverb
- **$30 USD** [pledged](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/4) by @atlasfoo
- **$70 USD** pledged by @robot-o 

**Want to add an amount to the pledge? Please send in a pull request!**

### What's actually happening (I think)

The laptop has a **Realtek ALC3306** codec (according to official Lenovo specs), but Linux incorrectly detects it as an **ALC287** with subsystem ID `17aa:3906`. The kernel driver applies a generic fallback fixup instead of a device-specific one, which causes the woofer/bass speakers to not be driven properly.

After investigation, it turns out the Legion Pro 7 16IAX10H uses **Awinic AWDZ8399 smart amplifiers** (at I2C addresses 0x34 and 0x35 on i2c-2). While a kernel driver exists (`snd_soc_aw88399`) and loads correctly, there's no integration between the codec and the amplifiers in the audio pipeline.

Specifically:
- The SOF (Sound Open Firmware) driver can be forced to load, but it falls back to a generic machine driver (`skl_hda_dsp_generic`)
- This uses a generic topology that only includes HDA codec paths - **no I2C amplifier support**
- The required topology file (something like `sof-arl-alc287-aw88399.tplg`) doesn't exist in the SOF firmware package
- No ACPI/DMI quirk exists for subsystem ID `17aa:3906` to properly configure the audio pipeline


**The above is somewhat speculative**. Could be something else! What do I know? Since when do I know how Linux audio drivers work?!

## Where this is being discussed

Arranged from most to least useful/likely to lead to progress.

- [Kernel.org Bugzilla discussion I'm trying to be active in](https://bugzilla.kernel.org/show_bug.cgi?id=218329)
- [Directly relevant discussion on Fedora forums](https://discussion.fedoraproject.org/t/problems-with-audio-driver-alc3306-in-a-legion-pro-7-gen-10-and-other-similar-lenovo-laptops/161992)
- [Directly relevant discussion on Lenovo forums](https://forums.lenovo.com/t5/Ubuntu/Legion-Pro-7-16IAX10H-Ubuntu-ALC3306-sound/m-p/5376602)
- [Directly relevant discussion on Garuda Linux forums](https://forum.garudalinux.org/t/audio-issues-on-lenovo-legion-pro-7-16iax10h/46291)
- [Directly relevant discussion on CachyOS forums](https://discuss.cachyos.org/t/speakers-are-tinny-and-not-playing-mids-or-lows-on-lenovo-legion-pro-7i-10th-gen-2025/15864/7)
- [Reddit](https://www.reddit.com/r/LenovoLegion/comments/1lg63ms/linux_support_on_lenovo_legion_pro_7i_gen_10/) (just some casual comments)

## Technical documents

- [Official Lenovo spec sheet](https://psref.lenovo.com/Product/Legion/Legion_Pro_7_16IAX10H?tab=spec)

## Things most likely to work

A kernel audio developer will need to create:

1. **A custom SOF topology file** (e.g., `sof-arl-alc287-aw88399.tplg`) that properly chains:
   - The HDA codec (ALC287/ALC3306)
   - The I2C smart amplifiers (AW88399 at addresses 0x34/0x35)
   - Proper routing and gain staging

2. **A DMI/ACPI quirk** in the kernel that matches your subsystem ID (`17aa:3906` and the other affected models) and tells SOF to use this topology.

3. **Possibly an amplifier initialization sequence** to properly configure the AW88399 chips.

**Why this is likely:** The [kernel bugzilla discussion](https://bugzilla.kernel.org/show_bug.cgi?id=218329) is the right venue, the infrastructure already exists (the `snd_soc_aw88399` driver is loaded), and the exact missing pieces have been identified.

## Things that are not likely to work

**HDA verb sniffing**

[This seems to have worked for 2020 models.](https://github.com/thiagotei/linux-realtek-alc287/tree/main/lenovo-legion) The idea is to use QEMU in order to sniff the HDA verbs from the Windows drivers, and then replicate those on Linux.

[A tutorial on how to use QEMU to sniff verbs is available here](https://github.com/ryanprescott/realtek-verb-tools/wiki/How-to-sniff-verbs-from-a-Windows-sound-driver), but the QEMU fork is ancient and is apparently impossible to compile anymore with modern dependency versions.

Additionally, [here are some debugging tools for testing HDA verbs on Linux](https://github.com/ryanprescott/realtek-verb-tools?tab=readme-ov-file).

**Why this is unlikely to work:**
- The issue isn't just HDA codec configuration, we need to integrate I2C amplifiers.
- The AW88399 amps need I2C initialization commands, not just HDA verbs.
- The QEMU toolchain being unmaintained is a bad sign.

## Things that absolutely do not work

- [Completely useless](https://github.com/aenawi/lenovo-legion-linux-audio)
- [Solutions that involve Yoga-specific kernel quirks](https://discussion.fedoraproject.org/t/lenovo-yoga-pro-7-14asp10-audio-issue-no-all-speakers-firing/163480/2)
- `options snd-hda-intel model=alc287-yoga9-bass-spk-pin`
- Switching to SOF drivers

## Are you also having this problem???

If so, please yell loudly at my general direction! Try to raise it up on kernel audio mailing lists! Respond to this [kernel.org Bugzilla discussion I'm trying to be active in](https://bugzilla.kernel.org/show_bug.cgi?id=218329)!

**You can also participate in the bug bounty pledge by sending a pull request to this `README.md` file adding your amount above.**
