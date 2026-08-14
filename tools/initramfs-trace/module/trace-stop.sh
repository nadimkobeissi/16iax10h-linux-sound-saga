#!/bin/sh

trace_mount=/run/initramfs-trace-boot
trace_file=$trace_mount/initramfs-trace-current.log

if [ -r /run/initramfs-trace.pid ]; then
    kill "$(cat /run/initramfs-trace.pid)" 2>/dev/null || :
fi

if mountpoint -q "$trace_mount" 2>/dev/null; then
    trace_uptime=$(cut -d' ' -f1 /proc/uptime 2>/dev/null)
    printf '[%s] initramfs cleanup reached; encrypted root is available\n' \
        "${trace_uptime:-unknown}" >> "$trace_file"
    sync -f "$trace_file" 2>/dev/null || sync
    umount "$trace_mount" 2>/dev/null || :
fi
