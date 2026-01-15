#!/bin/bash

# Переменные
DISK="/dev/nvme0n1"
OPTS="noatime,compress=zstd:3,ssd,discard=async,space_cache=v2"

echo "--- 1. Проверка Swap ---"
# Активируем, если еще не включен (ошибки скрываем)
swapon "${DISK}p2" 2>/dev/null

echo "--- 2. Создание подтомов Btrfs ---"
# Временный монтаж для создания структуры
mount "${DISK}p3" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
umount /mnt

echo "--- 3. Монтирование системы ---"
# Монтируем корень системы
mount -o "$OPTS,subvol=@" "${DISK}p3" /mnt

# Создаем точки монтирования
mkdir -p /mnt/{boot,home,.snapshots,var,var/log,var/cache}

# Монтируем загрузочный раздел (EFI)
mount "${DISK}p1" /mnt/boot

# Монтируем остальные подтома
mount -o "$OPTS,subvol=@home" "${DISK}p3" /mnt/home
mount -o "$OPTS,subvol=@snapshots" "${DISK}p3" /mnt/.snapshots
mount -o "$OPTS,subvol=@var" "${DISK}p3" /mnt/var
mount -o "$OPTS,subvol=@log" "${DISK}p3" /mnt/var/log
mount -o "$OPTS,subvol=@cache" "${DISK}p3" /mnt/var/cache

echo "--- 4. Настройка атрибутов (NoCoW) ---"
# Отключаем Copy-on-Write для логов и кэша
chattr +C /mnt/var/log
chattr +C /mnt/var/cache

echo "--- Готово! Структура диска собрана в /mnt ---"
lsblk "${DISK}"
