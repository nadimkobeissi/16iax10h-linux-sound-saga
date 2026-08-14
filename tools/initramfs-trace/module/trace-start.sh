#!/bin/sh

# This file runs inside the initramfs.  Do not inspect /dev/input/event*: doing
# so could consume password keystrokes.  Metadata in sysfs and proc is enough
# to establish whether the keyboard driver and password agent became ready.

. /etc/initramfs-trace.conf

trace_mount=/run/initramfs-trace-boot
trace_file=$trace_mount/initramfs-trace-current.log
trace_pid=/run/initramfs-trace.pid

# initqueue/settled hooks can run more than once.
[ ! -e "$trace_pid" ] || return 0

mkdir -p "$trace_mount"

trace_device=
for candidate in "/dev/disk/by-uuid/$BOOT_UUID" /dev/nvme*n*p* /dev/sd*[0-9]; do
    [ -b "$candidate" ] || continue
    [ "$(blkid -s UUID -o value "$candidate" 2>/dev/null)" = "$BOOT_UUID" ] || continue
    trace_device=$candidate
    break
done

if [ -z "$trace_device" ] || ! mount -o rw "$trace_device" "$trace_mount"; then
    warn "persistent-initramfs-trace: cannot mount boot UUID=$BOOT_UUID"
    return 0
fi

[ ! -e "$trace_file" ] || mv -f "$trace_file" "$trace_mount/initramfs-trace-previous.log"

trace() {
    trace_uptime=$(cut -d' ' -f1 /proc/uptime 2>/dev/null)
    printf '[%s] %s\n' "${trace_uptime:-unknown}" "$*" >> "$trace_file"
    printf '<6>initramfs-trace [%s] %s\n' "${trace_uptime:-unknown}" "$*" > /dev/kmsg 2>/dev/null || :
}

trace 'trace started'
trace "kernel=$(uname -r)"
trace "cmdline=$(cat /proc/cmdline)"
trace "boot_device=$trace_device"
trace "modules: i8042=$(test -d /sys/module/i8042 && echo yes || echo no) atkbd=$(test -d /sys/module/atkbd && echo yes || echo no) usbhid=$(test -d /sys/module/usbhid && echo yes || echo no) hid_generic=$(test -d /sys/module/hid_generic && echo yes || echo no)"
if [ -r /proc/bus/input/devices ]; then
    trace 'input devices at trace start:'
    sed -n '/^N: Name=/p; /^H: Handlers=/p' /proc/bus/input/devices >> "$trace_file"
fi
sync -f "$trace_file" 2>/dev/null || sync

(
    old_input=
    old_asks=
    old_mapper=
    tick=0
    while :; do
        changed=0
        input=$(find /sys/class/input -maxdepth 1 -name 'event*' -printf '%f ' 2>/dev/null)
        asks=$(find /run/systemd/ask-password -maxdepth 1 -type f -printf '%f ' 2>/dev/null)
        mapper=$(find /dev/mapper -maxdepth 1 -type l -printf '%f ' 2>/dev/null)

        if [ "$input" != "$old_input" ]; then
            trace "input event nodes changed: ${input:-none}"
            sed -n '/^N: Name=/p; /^H: Handlers=/p' /proc/bus/input/devices >> "$trace_file" 2>/dev/null
            old_input=$input
            changed=1
        fi
        if [ "$asks" != "$old_asks" ]; then
            trace "password requests changed: ${asks:-none}"
            old_asks=$asks
            changed=1
        fi
        if [ "$mapper" != "$old_mapper" ]; then
            trace "mapper devices changed: ${mapper:-none}"
            old_mapper=$mapper
            changed=1
        fi

        tick=$((tick + 1))
        if [ "$changed" -eq 1 ] || [ $((tick % 10)) -eq 0 ]; then
            [ "$changed" -eq 1 ] || trace 'heartbeat'
            sync -f "$trace_file" 2>/dev/null || sync
        fi
        sleep 1
    done
) &
echo "$!" > "$trace_pid"
