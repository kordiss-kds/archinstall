#!/bin/bash
# Ultimate Hybrid Disk Setup (Btrfs + Subvolumes + Optimization)
set -e

# --- 1. КОНФИГУРАЦИЯ ---
DISK="/dev/nvme0n1"
EFI_SIZE="1024MiB"  # 1GB хватит для любых ядер
SWAP_SIZE="16G"     # Оптимально для большинства задач
HOSTNAME="arch-machine"

echo "=== ВНИМАНИЕ: ПОДГОТОВКА ДИСКА $DISK ==="
lsblk "$DISK"
read -p "УНИЧТОЖИТЬ ВСЕ ДАННЫЕ? (y/N): " confirm
[[ "$confirm" != "y" ]] && exit 1

# --- 2. РАЗМЕТКА ---
echo "Очистка и создание разделов..."
wipefs -a "$DISK"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart "ESP" fat32 1MiB "$EFI_SIZE"
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart "root" btrfs "$EFI_SIZE" 100%

# Определяем имена разделов (для NVMe это p1/p2, для SATA — 1/2)
EFI_PART="${DISK}p1"
ROOT_PART="${DISK}p2"
[[ "$DISK" != *"nvme"* ]] && EFI_PART="${DISK}1" && ROOT_PART="${DISK}2"

# --- 3. ФОРМАТИРОВАНИЕ ---
mkfs.fat -F 32 -n EFI "$EFI_PART"
mkfs.btrfs -f -L "$HOSTNAME" "$ROOT_PART"

# --- 4. СОЗДАНИЕ СТРУКТУРЫ СУБВОЛЮМОВ ---
mount "$ROOT_PART" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
btrfs subvolume create /mnt/@swap
umount /mnt

# --- 5. МОНТИРОВАНИЕ С ОПТИМИЗАЦИЕЙ ---
# Флаги: zstd (сжатие), noatime (меньше записей), discard=async (жизнь SSD)
OPTS="noatime,compress=zstd:3,ssd,discard=async,space_cache=v2"

echo "Монтирование подтомов..."
mount -o $OPTS,subvol=@ "$ROOT_PART" /mnt

# Создаем точки монтирования
mkdir -p /mnt/{boot/efi,home,.snapshots,var/log,swap}

mount -o $OPTS,subvol=@home "$ROOT_PART" /mnt/home
mount -o $OPTS,subvol=@snapshots "$ROOT_PART" /mnt/.snapshots
mount -o $OPTS,subvol=@var_log,nodatacow "$ROOT_PART" /mnt/var/log
mount -o $OPTS,subvol=@swap,nodatacow "$ROOT_PART" /mnt/swap
mount "$EFI_PART" /mnt/boot/efi

# --- 6. НАСТРОЙКА SWAP-ФАЙЛА (Btrfs-way) ---
echo "Создание Swap-файла на $SWAP_SIZE..."
truncate -s 0 /mnt/swap/swapfile
chattr +C /mnt/swap/swapfile      # Отключаем CoW для файла подкачки
btrfs property set /mnt/swap/swapfile compression ""
fallocate -l "$SWAP_SIZE" /mnt/swap/swapfile
chmod 600 /mnt/swap/swapfile
mkswap /mnt/swap/swapfile
swapon /mnt/swap/swapfile

echo "-------------------------------------------------"
echo "ГОТОВО! Диск размечен, субволюмы созданы и смонтированы в /mnt."
echo "Теперь можешь запускать pacstrap или установку системы."
lsblk "$DISK"
