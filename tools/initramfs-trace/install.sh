#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
	printf '%s\n' "Run this installer as root (for example, with sudo)." >&2
	exit 1
fi

kver=${1:-7.1.8-legion-audio}
source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/module
target_dir=/usr/lib/dracut/modules.d/91persistent-initramfs-trace

if [ ! -r "/boot/vmlinuz-$kver" ]; then
	printf 'Kernel /boot/vmlinuz-%s was not found.\n' "$kver" >&2
	exit 1
fi

install -d -m 0755 "$target_dir"
install -m 0755 "$source_dir/module-setup.sh" "$target_dir/module-setup.sh"
install -m 0755 "$source_dir/trace-start.sh" "$target_dir/trace-start.sh"
install -m 0755 "$source_dir/trace-stop.sh" "$target_dir/trace-stop.sh"

# The internal panel is driven by i915.  Host-only detection while building an
# initramfs for a non-running kernel can omit it, leaving Plymouth on the EFI
# framebuffer while NVIDIA DRM is present.  Force i915 into the image and load
# it early so the LUKS password UI has a stable renderer and keyboard source.
dracut --force --add persistent-initramfs-trace --force-drivers i915 \
	"/boot/initrd.img-$kver" "$kver"

printf 'Installed persistent initramfs tracing in /boot/initrd.img-%s\n' "$kver"
printf '%s\n' 'Trace files: /boot/initramfs-trace-{current,previous}.log'
