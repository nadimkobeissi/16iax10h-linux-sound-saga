#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
	printf '%s\n' "Run this installer as root (for example, with sudo)." >&2
	exit 1
fi

kver=${1:-$(uname -r)}
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$script_dir/../.." && pwd)
module_dir=/usr/lib/dracut/modules.d/91persistent-initramfs-trace

# Preserve the permanent graphics fix while removing only diagnostics.
install -d -m 0755 /etc/dracut.conf.d
install -m 0644 "$repo_dir/tools/ubuntu-initramfs/i915.conf" \
	/etc/dracut.conf.d/90-legion-audio-i915.conf

if [ -d "$module_dir" ]; then
	rm -r -- "$module_dir"
fi

dracut --force "/boot/initrd.img-$kver" "$kver"
rm -f -- /boot/initramfs-trace-current.log /boot/initramfs-trace-previous.log

if ! lsinitrd "/boot/initrd.img-$kver" | grep -q '/i915\.ko$'; then
	printf 'ERROR: rebuilt initramfs does not contain i915.ko\n' >&2
	exit 1
fi
if lsinitrd "/boot/initrd.img-$kver" | grep -q persistent-initramfs-trace; then
	printf 'ERROR: tracing module is still present in the initramfs\n' >&2
	exit 1
fi

printf 'Removed tracing and rebuilt the %s initramfs with i915.\n' "$kver"
