#!/bin/bash
set -e

echo "=== 1. ОЧИСТКА RAM И ПОДГОТОВКА КЛЮЧЕЙ ==="
# Очищаем кэш в оперативной памяти Live-ISO
sudo pacman -Scc --noconfirm

# Ускоряем загрузку
sudo sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

# Добавляем репозиторий CachyOS в Live-систему
curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz
cd cachyos-repo
sudo ./cachyos-repo.sh
cd ..

echo "=== 2. ПОДГОТОВКА КЭША НА SSD ==="
# Создаем директорию на SSD, чтобы пакеты НЕ качались в оперативку
mkdir -p /mnt/var/cache/pacman/pkg

echo "=== 3. УСТАНОВКА БАЗОВОЙ СИСТЕМЫ (PACSTRAP) ==="
# -K инициализирует новые ключи в системе
# --cachedir перенаправляет загрузку на SSD
pacstrap -K /mnt base base-devel linux-cachyos linux-cachyos-headers linux-firmware cachyos-keyring git nano networkmanager amd-ucode --cachedir /mnt/var/cache/pacman/pkg

echo "=== 4. ГЕНЕРАЦИЯ FSTAB ==="
genfstab -U /mnt >> /mnt/etc/fstab

# Проверка записи swapfile в fstab
if ! grep -q "/swap/swapfile" /mnt/etc/fstab; then
    echo "/swap/swapfile  none  swap  defaults,pri=-2  0 0" >> /mnt/etc/fstab
fi

echo "-------------------------------------------------"
echo "БАЗА УСПЕШНО УСТАНОВЛЕНА!"
echo "Теперь можно входить: arch-chroot /mnt"
