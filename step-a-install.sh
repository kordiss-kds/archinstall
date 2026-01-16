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

echo "--- 3. Установка базовой системы (Pacstrap) ---"
# Флаг --noconfirm заставит pacman не спрашивать подтверждения (отвечать 'Y')
pacstrap -K /mnt \
  base base-devel \
  linux-cachyos linux-cachyos-headers linux-firmware \
  amd-ucode btrfs-progs \
  nano networkmanager sudo \
  snapper snap-pac grub-btrfs \
  --noconfirm

echo "--- 4. Перенос настроек параллельной загрузки в новую систему ---"
# Чтобы после установки в новой системе тоже было 5 потоков
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /mnt/etc/pacman.conf

echo "--- 5. Генерация fstab ---"
genfstab -U /mnt >> /mnt/etc/fstab

echo "--------------------------------------------------------"
echo "ШАГ А ЗАВЕРШЕН!"
echo "Теперь входи в систему командой: arch-chroot /mnt"
echo "--------------------------------------------------------"
