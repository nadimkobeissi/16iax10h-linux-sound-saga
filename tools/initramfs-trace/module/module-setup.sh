#!/bin/bash

check() {
    return 0
}

depends() {
    echo 'rootfs-block'
}

install() {
    local boot_source boot_uuid

    boot_source=$(findmnt -nro SOURCE "${dracutsysrootdir:-/}/boot" 2>/dev/null) || return 1
    boot_uuid=$(blkid -s UUID -o value "$boot_source" 2>/dev/null) || return 1
    [[ -n $boot_uuid ]] || return 1

    printf 'BOOT_UUID=%q\n' "$boot_uuid" > "$initdir/etc/initramfs-trace.conf"
    # pre-trigger runs before udev has created the NVMe device nodes, so the
    # trace cannot mount /boot there.  Start on the first settled initqueue
    # pass, after storage discovery but before the encrypted root is unlocked.
    inst_hook initqueue/settled 01 "$moddir/trace-start.sh"
    inst_hook cleanup 99 "$moddir/trace-stop.sh"
    inst_multiple blkid cat cut find mkdir mount mountpoint mv sed sleep sync umount uname
}
