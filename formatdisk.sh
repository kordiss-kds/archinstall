#!/bin/bash

# Переменные
DISK="/dev/nvme0n1"

echo "--- ВНИМАНИЕ: Очистка и разметка диска $DISK ---"
sleep 2

# 1. Полная очистка старых данных и подписей
wipefs -a "$DISK"

# 2. Создание таблицы разделов GPT
parted -s "$DISK" mklabel gpt

# 3. Создание разделов
echo "Создаю разделы..."
# EFI - 2GB
parted -s "$DISK" mkpart "ESP" fat32 1MiB 2049MiB
parted -s "$DISK" set 1 esp on

# Swap - 32GB
parted -s "$DISK" mkpart "swap" linux-swap 2049MiB 34.8GiB

# Root (Btrfs) - остальное пространство
parted -s "$DISK" mkpart "root" btrfs 34.8GiB 100%

# Информируем ядро об изменениях
partprobe "$DISK"
sleep 1

echo "--- 4. Форматирование файловых систем ---"

# EFI раздел
mkfs.fat -F 32 "${DISK}p1"

# Swap раздел
mkswap "${DISK}p2"
swapon "${DISK}p2"

# Btrfs раздел с меткой ARCH
mkfs.btrfs -L ARCH -f "${DISK}p3"

echo "-------------------------------------------------"
echo "Разметка и форматирование успешно завершены!"
lsblk "$DISK"
