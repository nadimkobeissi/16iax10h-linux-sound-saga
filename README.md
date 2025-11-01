# Nadim's ~~sad~~ epic, noble, valiant quest to fix his laptop speakers

![](george.jpg)

The internal speakers don't work on my Linux laptop. Join me as I publicly fail to do anything about this.

To be more precise: the speakers sound *absolutely phenomenal* if your definition of "phenomenal" is "like listening to music through a tin can filled with angry bees from the year 1997." The audio is so tinny and muffled that I'm pretty sure only the tweeters decided to show up for work today. Want to listen to your favorite song? Great! Now imagine it being performed by chipmunks trapped inside a shoebox. That's the experience.

## Do we have a solution?

No.

## What is the problem?

The internal speakers on my Lenovo Legion Pro 7 16IAX10H (and several other Lenovo laptops with the Realtek ALC3306 codec) produce extremely low volume audio that sounds tinny and muffled - as if only the tweeters are working, not the woofers.

### What's actually happening (I think)

The laptop has a **Realtek ALC3306** codec (according to official Lenovo specs), but Linux incorrectly detects it as an **ALC287** with subsystem ID `17aa:3906`. The kernel driver applies a generic fallback fixup instead of a device-specific one, which causes the woofer/bass speakers to not be driven properly.

### Root cause

After investigation, it turns out the Legion Pro 7 16IAX10H uses **Awinic AWDZ8399 smart amplifiers** (at I2C addresses 0x34 and 0x35 on i2c-2). While a kernel driver exists (`snd_soc_aw88399`) and loads correctly, there's no integration between the codec and the amplifiers in the audio pipeline.

Specifically:
- The SOF (Sound Open Firmware) driver can be forced to load, but it falls back to a generic machine driver (`skl_hda_dsp_generic`)
- This uses a generic topology that only includes HDA codec paths - **no I2C amplifier support**
- The required topology file (something like `sof-arl-alc287-aw88399.tplg`) doesn't exist in the SOF firmware package
- No ACPI/DMI quirk exists for subsystem ID `17aa:3906` to properly configure the audio pipeline

### Affected devices

This issue affects multiple Lenovo laptop models with the ALC3306 codec:

| Model | Codec Subsystem ID | Status |
|-------|-------------------|--------|
| Legion Pro 7 16IAX10H | `17aa:3906` | ❌ Broken - extremely low volume |
| Yoga Pro 9 16IAH10 | `17aa:391f` | ❌ Broken - extremely low volume |
| Yoga Pro 9 14IRP8 | `17aa:38bf` | ❌ Broken - extremely low volume |
| Yoga Pro 7 14ASP9 | `17aa:3903` | ✅ Works normally |
| Yoga 7 14AKP10 | `17aa:391c` | ❌ Broken - extremely low volume |

### The above is somewhat speculative

Could be something else! What do I know? Since when do I know how Linux audio drivers work?!

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

## Things that seem to make some positive changes to the audio routing but end up not meaningfully impacting the problem

- [This](https://github.com/daveysyr/Ubuntu_Lenovo_Legion_audio_fix/blob/main/legion_audio_fix_detailed.txt)
- `options snd-hda-intel patch=legion-alc287.patch`

## Things that absolutely do not work

- [Completely useless](https://github.com/aenawi/lenovo-legion-linux-audio)
- [Solutions that involve Yoga-specific kernel quirks](https://discussion.fedoraproject.org/t/lenovo-yoga-pro-7-14asp10-audio-issue-no-all-speakers-firing/163480/2)
- `options snd-hda-intel model=alc287-yoga9-bass-spk-pin`
- Switching to SOF drivers

## What can be done?

I don't know,

- Learn how kernel sound drivers work?
- Adapt an existing quirk (e.g. `alc287-yoga9-bass-spk-pin`) to make it work?
- Reverse engineer the Windows driver, record the HDA verbs being sent across I2C, and port that to Linux?
- Nag?

## Offer: I will fund a kernel developer to fix this

Submit a patch that works and I'll donate to your favorite charity. I mean it. I don't know how much. Two hundred dollars? I'm not exactly drowning in money. I can help you test via my hardware.

## Are you also having this problem???

If so, please yell loudly at my general direction! Try to raise it up on kernel audio mailing lists! Respond to this [kernel.org Bugzilla discussion I'm trying to be active in](https://bugzilla.kernel.org/show_bug.cgi?id=218329)! Participate in increasing the amount in my above charity donation pledge!
