#!/bin/bash
# formatdisk.sh — Arch/CachyOS BTRFS Setup (2026)
set -e

# --- КОНФИГУРАЦИЯ (Проверь перед запуском!) ---
DISK="/dev/nvme0n1"         # Твой диск (lsblk в помощь)
EFI_SIZE="1GiB"             # Рекомендуемый размер для 2026 года
SWAP_FILE_SIZE="16G"        # Размер файла подкачки (для zram+swapfile схемы)
MOUNT_OPTS="noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,autodefrag"

echo "=== ВНИМАНИЕ: ОЧИСТКА $DISK ==="
echo "Будет создано: EFI ($EFI_SIZE), BTRFS (остальное) с подтомами @, @home, @swap, .snapshots"
read -p "УНИЧТОЖИТЬ ДАННЫЕ? (y/N): " confirm
[[ "$confirm" != "y" ]] && exit 1

# 1. Разметка диска
echo "Разметка..."
wipefs --all --force "$DISK"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart "EFI" fat32 1MiB "$EFI_SIZE"
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart "root" btrfs "$EFI_SIZE" 100%

# Определение имен разделов (nvme vs sda)
if [[ "$DISK" == *"nvme"* ]]; then
    EFI_PART="${DISK}p1"
    ROOT_PART="${DISK}p2"
else
    EFI_PART="${DISK}1"
    ROOT_PART="${DISK}2"
fi

# 2. Форматирование
echo "Форматирование разделов..."
mkfs.fat -F32 "$EFI_PART"
mkfs.btrfs -f -L "ARCH_ROOT" "$ROOT_PART"

# 3. Создание подтомов
echo "Создание структуры BTRFS..."
mount "$ROOT_PART" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@swap
btrfs subvolume create /mnt/.snapshots
umount /mnt

# 4. Монтирование системы
echo "Монтирование подтомов..."
mount -o $MOUNT_OPTS,subvol=@ "$ROOT_PART" /mnt

mkdir -p /mnt/{boot/efi,home,swap,.snapshots}

mount -o $MOUNT_OPTS,subvol=@home "$ROOT_PART" /mnt/home
mount -o $MOUNT_OPTS,subvol=.snapshots "$ROOT_PART" /mnt/.snapshots

# Специальное монтирование для SWAP (без сжатия и с nodatacow)
mount -o compress=no,nodatacow,noatime,subvol=@swap "$ROOT_PART" /mnt/swap
mount "$EFI_PART" /mnt/boot/efi

# 5. Создание Swap-файла (Правильный метод для BTRFS)
echo "Настройка Swapfile ($SWAP_FILE_SIZE)..."
touch /mnt/swap/swapfile
chattr +C /mnt/swap/swapfile          # Отключаем CoW ДО записи данных
btrfs property set /mnt/swap/swapfile compression ""
fallocate -l "$SWAP_FILE_SIZE" /mnt/swap/swapfile
chmod 600 /mnt/swap/swapfile
mkswap /mnt/swap/swapfile
swapon --priority -2 /mnt/swap/swapfile # Низкий приоритет (zram будет выше)

echo "-------------------------------------------------"
echo "ГОТОВО!"
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "$DISK"
echo ""
echo "Следующие шаги:"
echo "1. pacstrap /mnt base base-devel linux-cachyos linux-cachyos-headers linux-firmware git nano networkmanager amd-ucode"
echo "2. genfstab -U /mnt >> /mnt/etc/fstab"
echo "3. arch-chroot /mnt"
