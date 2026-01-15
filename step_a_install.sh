#!/bin/bash

echo "--- 1. Добавление репозиториев CachyOS в Live-ISO ---"
# Скачиваем скрипт добавления репозиториев
curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz
cd cachyos-repo

# Запускаем скрипт CachyOS. 
# Он сам определит твой Ryzen 3700x как x86-64-v3 и настроит pacman.conf
sudo ./cachyos-repo.sh
cd ..

echo "--- 2. Установка базовой системы (Pacstrap) ---"
# Включаем в установку ядро CachyOS, микрокод AMD и инструменты для Snapper/Btrfs
pacstrap -K /mnt \
  base base-devel \
  linux-cachyos linux-cachyos-headers linux-firmware \
  amd-ucode btrfs-progs \
  nano networkmanager sudo \
  snapper snap-pac grub-btrfs

echo "--- 3. Генерация fstab ---"
# Записываем информацию о монтировании подтомов в новую систему
genfstab -U /mnt >> /mnt/etc/fstab

echo "--------------------------------------------------------"
echo "ШАГ А ЗАВЕРШЕН!"
echo "Теперь входи в систему командой: arch-chroot /mnt"
echo "--------------------------------------------------------"
