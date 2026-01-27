#!/bin/bash
# install_base.sh — Установка базы с кэшированием на SSD (2026)
set -e

# --- КОНФИГУРАЦИЯ ---
UCODE="amd-ucode" # Замени на intel-ucode, если процессор Intel

echo "=== ШАГ 2: ПОДГОТОВКА И УСТАНОВКА БАЗЫ ==="

# 1. Ускорение pacman в Live-ISO
echo "Ускоряем загрузку (5 потоков)..."
sudo sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

# 2. Подготовка кэша на SSD
# Это критически важный момент, чтобы не забить оперативную память
echo "Создаю директорию кэша на SSD..."
mkdir -p /mnt/var/cache/pacman/pkg

# 3. Установка базы через pacstrap
# Используем флаг --cachedir, чтобы все пакеты качались сразу на диск
echo "Запускаю pacstrap (кэширование на SSD)..."
pacstrap /mnt base base-devel linux-cachyos linux-cachyos-headers linux-firmware git nano networkmanager $UCODE --cachedir /mnt/var/cache/pacman/pkg

echo "=== ШАГ 3: ГЕНЕРАЦИЯ FSTAB ==="

# 4. Генерация fstab
echo "Генерирую /etc/fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# 5. Проверка записи swapfile в fstab
if ! grep -q "/swap/swapfile" /mnt/etc/fstab; then
    echo "/swap/swapfile  none  swap  defaults,pri=-2  0 0" >> /mnt/etc/fstab
fi

echo "-------------------------------------------------"
echo "ГОТОВО! Система установлена на SSD."
echo "Проверь точки монтирования: cat /mnt/etc/fstab"
echo ""
echo "Теперь входи в систему для финальной настройки:"
echo "arch-chroot /mnt"
