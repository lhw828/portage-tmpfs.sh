#!/bin/bash

# portage-tmpfs.sh - Enable in-memory compilation for Gentoo Portage
# Usage:
#   sudo ./portage-tmpfs.sh start [size]   # e.g., start 12G
#   sudo ./portage-tmpfs.sh stop
#   sudo ./portage-tmpfs.sh status

set -e

PORTAGE_TMP="/var/tmp/portage"
MOUNT_POINT="$PORTAGE_TMP"
BACKUP_DIR="/var/tmp/portage.disk"

get_free_mem_mb() {
    awk '/^MemAvailable:/ {print int($2/1024)}' /proc/meminfo
}

human_to_bytes() {
    local input="$1"
    if [[ "$input" =~ ^([0-9]+)([kKmMgG])?$ ]]; then
        local num="${BASH_REMATCH[1]}"
        local unit="${BASH_REMATCH[2],,}"
        case "$unit" in
            g) echo $((num * 1024**3)) ;;
            m) echo $((num * 1024**2)) ;;
            k) echo $((num * 1024)) ;;
            '') echo $((num * 1024**2)) ;;
        esac
    else
        echo "error" >&2
        return 1
    fi
}

bytes_to_human() {
    local bytes=$1
    if (( bytes >= 1024**3 )); then
        echo "$((bytes / 1024**3))G"
    elif (( bytes >= 1024**2 )); then
        echo "$((bytes / 1024**2))M"
    else
        echo "$((bytes / 1024))K"
    fi
}

is_mounted() {
    mountpoint -q "$MOUNT_POINT"
}

start_tmpfs() {
    local size_human="${1:-8G}"
    local size_bytes
    size_bytes=$(human_to_bytes "$size_human") || {
        echo "❌ Invalid size format: $size_human (e.g., 4G, 8192M)"
        exit 1
    }

    echo "🧠 Available memory: $(get_free_mem_mb) MB"
    echo "📁 Mounting $MOUNT_POINT to tmpfs, size: $size_human"

    if is_mounted; then
        echo "⚠️  Already mounted. Run 'stop' first."
        exit 1
    fi

    # Backup existing non-empty directory
    if [ -d "$MOUNT_POINT" ] && [ -n "$(ls -A "$MOUNT_POINT" 2>/dev/null)" ]; then
        echo "📦 Backing up existing $MOUNT_POINT to $BACKUP_DIR"
        mv "$MOUNT_POINT" "$BACKUP_DIR"
    fi

    mkdir -p "$MOUNT_POINT"

    # 🔥 CRITICAL: DO NOT use 'noexec' or 'nosuid' if Portage needs to run binaries!
    # Only 'mode=1777' is needed for permissions.
    mount -t tmpfs -o size="$size_human",mode=1777 tmpfs "$MOUNT_POINT"
    chmod 1777 "$MOUNT_POINT"

    echo "✅ tmpfs enabled! Portage can now compile in memory."
    echo "💡 After emerge, run './portage-tmpfs.sh stop' to restore disk."
}

stop_tmpfs() {
    if ! is_mounted; then
        echo "⚠️  $MOUNT_POINT is not mounted on tmpfs"
        if [ -d "$BACKUP_DIR" ]; then
            echo "🔄 Restoring backup..."
            rmdir "$MOUNT_POINT" 2>/dev/null || true
            mv "$BACKUP_DIR" "$MOUNT_POINT"
        fi
        exit 0
    fi

    echo "🧹 Unmounting tmpfs..."
    umount "$MOUNT_POINT"
    rmdir "$MOUNT_POINT"

    if [ -d "$BACKUP_DIR" ]; then
        echo "🔄 Restoring original $PORTAGE_TMP"
        mv "$BACKUP_DIR" "$MOUNT_POINT"
    fi

    echo "✅ tmpfs disabled. Back to disk-based compilation."
}

show_status() {
    if is_mounted; then
        echo "🟢 Status: tmpfs active"
        df -h "$MOUNT_POINT"
    else
        echo "🔴 Status: using disk"
        if [ -d "$BACKUP_DIR" ]; then
            echo "📦 Backup exists: $BACKUP_DIR"
        fi
    fi
}

case "${1:-status}" in
    start)
        start_tmpfs "$2"
        ;;
    stop)
        stop_tmpfs
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {start [size]|stop|status}"
        echo "Example: $0 start 12G"
        exit 1
        ;;
esac

