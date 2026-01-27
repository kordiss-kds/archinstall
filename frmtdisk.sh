#!/bin/bash
set -e

# --- КОНФИГУРАЦИЯ ---
DISK="/dev/nvme0n1"         # ПРОВЕРЬ ЧЕРЕЗ lsblk!
EFI_SIZE="1GiB"
SWAP_FILE_SIZE="16G"        # Размер файла подкачки
HOSTNAME="cachy-wayland"

echo "=== ФОРМАТИРОВАНИЕ SSD С ПОДДЕРЖКОЙ SNAPSHOTS И SWAPFILE ==="
read -p "УНИЧТОЖИТЬ ДАННЫЕ НА $DISK? (y/N): " confirm
[[ "$confirm" != "y" ]] && exit 1

# 1. Разметка (GPT)
wipefs --all --force "$DISK"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart "EFI" fat32 1MiB "$EFI_SIZE"
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart "root" btrfs "$EFI_SIZE" 100%

# Определение имен разделов
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
btrfs subvolume create /mnt/.snapshots
umount /mnt

# 4. Правильное монтирование для установки
# Флаги для SSD: noatime, compress=zstd:3, discard=async
MOUNT_OPTS="noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,autodefrag"

mount -o $MOUNT_OPTS,subvol=@ "$ROOT_PART" /mnt

mkdir -p /mnt/{boot/efi,home,swap,.snapshots}

mount -o $MOUNT_OPTS,subvol=@home "$ROOT_PART" /mnt/home
mount -o $MOUNT_OPTS,subvol=.snapshots "$ROOT_PART" /mnt/.snapshots

# МОНТИРУЕМ СВОП БЕЗ СЖАТИЯ И COW
mount -o nocompress,nodatacow,noatime,subvol=@swap "$ROOT_PART" /mnt/swap
mount "$EFI_PART" /mnt/boot/efi

# 5. Создание Swap-файла
echo "Создаю swapfile..."
truncate -s 0 /mnt/swap/swapfile
chattr +C /mnt/swap/swapfile
btrfs property set /mnt/swap/swapfile compression none
fallocate -l "$SWAP_FILE_SIZE" /mnt/swap/swapfile
chmod 600 /mnt/swap/swapfile
mkswap /mnt/swap/swapfile
swapon --priority -2 /mnt/swap/swapfile

# 6. Генерация FSTAB
mkdir -p /mnt/etc
genfstab -U /mnt >> /mnt/etc/fstab

echo "-------------------------------------------------"
echo "Диск готов. Выполни: pacstrap /mnt base linux-cachyos base-devel"
