#!/bin/bash

DISK="/dev/nvme0n1"
OPTS="noatime,compress=zstd:3,ssd,discard=async,space_cache=v2"

echo "--- 1. Подготовка (Swap и корень диска) ---"
swapon "${DISK}p2" 2>/dev/null
mount "${DISK}p3" /mnt

# Создаем подтома, если они еще не созданы (ошибки игнорируем, если уже есть)
btrfs subvolume create /mnt/@ 2>/dev/null
btrfs subvolume create /mnt/@home 2>/dev/null
btrfs subvolume create /mnt/@snapshots 2>/dev/null
btrfs subvolume create /mnt/@var 2>/dev/null
btrfs subvolume create /mnt/@log 2>/dev/null
btrfs subvolume create /mnt/@cache 2>/dev/null

# Размонтируем корень диска, чтобы начать чистое монтирование подтомов
umount /mnt

echo "--- 2. Чистое монтирование структуры ---"

# Сначала основной подтом системы
mount -o "$OPTS,subvol=@" "${DISK}p3" /mnt

# Создаем точки монтирования (папки)
mkdir -p /mnt/{boot,home,.snapshots,var}

# Монтируем EFI и Home
mount "${DISK}p1" /mnt/boot
mount -o "$OPTS,subvol=@home" "${DISK}p3" /mnt/home
mount -o "$OPTS,subvol=@snapshots" "${DISK}p3" /mnt/.snapshots

# ВАЖНО: Сначала монтируем @var
mount -o "$OPTS,subvol=@var" "${DISK}p3" /mnt/var

# ТЕПЕРЬ создаем папки внутри примонтированного @var
mkdir -p /mnt/var/{log,cache}

# И монтируем в них соответствующие подтома
mount -o "$OPTS,subvol=@log" "${DISK}p3" /mnt/var/log
mount -o "$OPTS,subvol=@cache" "${DISK}p3" /mnt/var/cache

echo "--- 3. Установка атрибутов ---"
chattr +C /mnt/var/log
chattr +C /mnt/var/cache

echo "--- Готово! Проверяй дерево монтирования: ---"
lsblk "${DISK}"
