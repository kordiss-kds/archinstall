#!/bin/bash
# formatdisk.sh — Arch/CachyOS BTRFS Setup (Ultimate 2026)
set -e

# --- КОНФИГУРАЦИЯ ---
DISK="/dev/nvme0n1"         # Проверь через lsblk!
EFI_SIZE="1GiB"
SWAP_FILE_SIZE="16G"
# Базовые флаги для SSD
MOUNT_OPTS="noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,autodefrag"

echo "=== ВНИМАНИЕ: ПОЛНАЯ ПОДГОТОВКА SSD ==="
read -p "УНИЧТОЖИТЬ ДАННЫЕ НА $DISK? (y/N): " confirm
[[ "$confirm" != "y" ]] && exit 1

# 1. Разметка
wipefs --all --force "$DISK"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart "EFI" fat32 1MiB "$EFI_SIZE"
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart "root" btrfs "$EFI_SIZE" 100%

EFI_PART="${DISK}p1"
ROOT_PART="${DISK}p2"
[[ "$DISK" != *"nvme"* ]] && EFI_PART="${DISK}1" && ROOT_PART="${DISK}2"

# 2. Форматирование
mkfs.fat -F32 "$EFI_PART"
mkfs.btrfs -f -L "ARCH_ROOT" "$ROOT_PART"

# 3. Создание субволюмов
mount "$ROOT_PART" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@swap
btrfs subvolume create /mnt/@var_log
btrfs subvolume create /mnt/@var_cache
btrfs subvolume create /mnt/.snapshots
umount /mnt

# 4. Монтирование системы
echo "Монтирую подтома..."
mount -o $MOUNT_OPTS,subvol=@ "$ROOT_PART" /mnt

# Создаем иерархию папок
mkdir -p /mnt/{boot/efi,home,swap,.snapshots,var/log,var/cache}

# Монтируем стандартные разделы
mount -o $MOUNT_OPTS,subvol=@home "$ROOT_PART" /mnt/home
mount -o $MOUNT_OPTS,subvol=.snapshots "$ROOT_PART" /mnt/.snapshots

# Монтируем лог и кэш с отключением CoW (nodatacow)
mount -o $MOUNT_OPTS,subvol=@var_log,nodatacow "$ROOT_PART" /mnt/var/log
mount -o $MOUNT_OPTS,subvol=@var_cache,nodatacow "$ROOT_PART" /mnt/var/cache

# Специальное монтирование для SWAP
mount -o compress=no,nodatacow,noatime,subvol=@swap "$ROOT_PART" /mnt/swap
mount "$EFI_PART" /mnt/boot/efi

# 5. Создание Swap-файла
echo "Настройка Swapfile..."
touch /mnt/swap/swapfile
chattr +C /mnt/swap/swapfile
btrfs property set /mnt/swap/swapfile compression ""
fallocate -l "$SWAP_FILE_SIZE" /mnt/swap/swapfile
chmod 600 /mnt/swap/swapfile
mkswap /mnt/swap/swapfile
swapon --priority -2 /mnt/swap/swapfile

echo "-------------------------------------------------"
echo "Диск готов! Ошибка 'No space left' больше не должна беспокоить,"
echo "так как мы подготовили /mnt/var/"
