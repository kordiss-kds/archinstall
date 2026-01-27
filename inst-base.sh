#!/bin/bash
set -e

# --- КОНФИГУРАЦИЯ ---
UCODE="amd-ucode" # Замени на intel-ucode, если нужно

echo "--- 1. Ускорение загрузки (5 потоков) ---"
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

echo "--- 2. Добавление репозиториев CachyOS в Live-ISO ---"
# Это позволит pacstrap скачивать уже оптимизированные пакеты CachyOS
curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz
cd cachyos-repo
sudo ./cachyos-repo.sh
cd ..

# Повторно включаем потоки, если скрипт cachyos сбросил конфиг
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

echo "--- 3. Установка базы через pacstrap ---"
# Добавляем cachyos-keyring для безопасности репозиториев
pacstrap /mnt base base-devel linux-cachyos linux-cachyos-headers linux-firmware cachyos-keyring git nano networkmanager $UCODE

echo "--- 4. Генерация fstab ---"
genfstab -U /mnt >> /mnt/etc/fstab

# Проверка записи swapfile
if ! grep -q "/swap/swapfile" /mnt/etc/fstab; then
    echo "/swap/swapfile  none  swap  defaults,pri=-2  0 0" >> /mnt/etc/fstab
fi

echo "-------------------------------------------------"
echo "ГОТОВО! База установлена."
echo "Проверь fstab: cat /mnt/etc/fstab"
echo "Теперь заходи в систему: arch-chroot /mnt"
