#!/bin/bash

echo "--- 1. Ускорение загрузки (5 потоков) ---"
# Включаем параллельную загрузку в конфиге pacman живой системы
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

echo "--- 2. Добавление репозиториев CachyOS в Live-ISO ---"
curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz
cd cachyos-repo

# Запускаем скрипт CachyOS.
# Флаг автоматизации обычно зависит от скрипта, но мы прогоним его установку.
# ВНИМАНИЕ: Скрипт CachyOS может сам обновить pacman.conf, 
# поэтому мы повторно включим потоки после него.
sudo ./cachyos-repo.sh
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
cd ..

echo "=== 4. УСТАНОВКА СИСТЕМЫ НА SSD (PACSTRAP) ==="
# Создаем папку кэша на SSD
mkdir -p /mnt/var/cache/pacman/pkg

# Установка базы. -K создаст новые ключи внутри системы.
# Используем --cachedir, чтобы не забить оперативку.
pacstrap -K /mnt base base-devel linux-cachyos linux-cachyos-headers linux-firmware cachyos-keyring git nano networkmanager amd-ucode --cachedir /mnt/var/cache/pacman/pkg

echo "=== 5. ГЕНЕРАЦИЯ FSTAB ==="
genfstab -U /mnt >> /mnt/etc/fstab

# Проверка swapfile
if ! grep -q "/swap/swapfile" /mnt/etc/fstab; then
    echo "/swap/swapfile  none  swap  defaults,pri=-2  0 0" >> /mnt/etc/fstab
fi

echo "-------------------------------------------------"
echo "БАЗА УСТАНОВЛЕНА! Проверь наличие команд:"
echo "Введи: arch-chroot /mnt ls /usr/bin/less"
echo "Если путь найден — всё супер, заходи в chroot!"
