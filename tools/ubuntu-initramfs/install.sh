#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
	printf '%s\n' "Run this installer as root (for example, with sudo)." >&2
	exit 1
fi

kver=${1:-$(uname -r)}
source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
config_dir=/etc/dracut.conf.d
config_file=$config_dir/90-legion-audio-i915.conf
initrd=/boot/initrd.img-$kver

if [ ! -r "/boot/vmlinuz-$kver" ] || [ ! -d "/lib/modules/$kver" ]; then
	printf 'Kernel files for %s were not found.\n' "$kver" >&2
	exit 1
fi

install -d -m 0755 "$config_dir"
install -m 0644 "$source_dir/i915.conf" "$config_file"
dracut --force "$initrd" "$kver"

if ! lsinitrd "$initrd" | grep -q '/i915\.ko$'; then
	printf 'ERROR: i915.ko is absent from %s\n' "$initrd" >&2
	exit 1
fi

printf 'Rebuilt %s with early i915 loading.\n' "$initrd"
