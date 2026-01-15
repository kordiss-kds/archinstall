#!/bin/bash

DISK="/dev/nvme0n1"
OPTS="noatime,compress=zstd:3,ssd,discard=async,space_cache=v2"

echo "--- 1. Активация Swap ---"
swapon "${DISK}p2"

echo "--- 2. Монтирование корневого подтома (@) ---"
mount -o "$OPTS,subvol=@" "${DISK}p3" /mnt

echo "--- 3. Создание точек монтирования ---"
mkdir -p /mnt/{boot,home,.snapshots,var,var/log,var/cache}

echo "--- 4. Монтирование остальных разделов и подтомов ---"
# Монтируем загрузчик (EFI)
mount "${DISK}p1" /mnt/boot

# Монтируем подтома Btrfs
mount -o "$OPTS,subvol=@home" "${DISK}p3" /mnt/home
mount -o "$OPTS,subvol=@snapshots" "${DISK}p3" /mnt/.snapshots
mount -o "$OPTS,subvol=@var" "${DISK}p3" /mnt/var
mount -o "$OPTS,subvol=@log" "${DISK}p3" /mnt/var/log
mount -o "$OPTS,subvol=@cache" "${DISK}p3" /mnt/var/cache

echo "--- 5. Установка атрибутов ---"
# Отключаем Copy-on-Write для логов и кэша
chattr +C /mnt/var/log
chattr +C /mnt/var/cache

echo "--- Готово! Диск примонтирован в /mnt ---"
lsblk
