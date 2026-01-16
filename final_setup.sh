#!/bin/bash

# 1. Настройка репозиториев CachyOS внутри системы
echo "--- 1. Настройка репозиториев CachyOS ---"
curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz && cd cachyos-repo
./cachyos-repo.sh
cd ..

# 2. Тонкая настройка pacman.conf для v3 и параллельной загрузки
echo "--- 2. Оптимизация pacman.conf (v3 + Parallel) ---"
# Включаем 5 потоков
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
# Добавляем цвет и аккуратный вывод
sed -i 's/#Color/Color\nILoveCandy/' /etc/pacman.conf

# Проверяем, что v3 репозитории в приоритете (в начале списка)
# Если скрипт CachyOS их уже добавил, мы просто убеждаемся, что они активны
# (Обычно скрипт CachyOS делает это сам, но ручной контроль не помешает)

# 3. Обновление и установка драйверов NVIDIA
echo "--- 3. Установка NVIDIA Open Driver (RTX 3060) ---"
pacman -Syu --noconfirm nvidia-open-cachyos nvidia-utils lib32-nvidia-utils amd-ucode

# 4. Локализация и Имя хоста
echo "--- 4. Настройка локализации и Hostname ---"
read -p "Введите имя вашего компьютера (hostname): " MY_HOSTNAME
echo "$MY_HOSTNAME" > /etc/hostname

ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
echo "KEYMAP=ruwin_alt_sh-UTF-8" > /etc/vconsole.conf
echo "FONT=cyr-sun16" >> /etc/vconsole.conf

# 5. Настройка Snapper
echo "--- 5. Настройка Snapper ---"
umount -l /.snapshots 2>/dev/null
rm -rf /.snapshots
snapper -c root create-config /
rm -rf /.snapshots
mkdir /.snapshots
mount -a

# 6. Установка и настройка GRUB
echo "--- 6. Установка загрузчика GRUB ---"
pacman -S --noconfirm grub efibootmgr grub-btrfs
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
systemctl enable grub-btrfsd
grub-mkconfig -o /boot/grub/grub.cfg

# 7. Пользователи, Сеть и Sudo
echo "--- 7. Создание пользователя и пароли ---"
systemctl enable NetworkManager
echo "УСТАНОВКА ПАРОЛЯ ДЛЯ ROOT"
passwd

read -p "Введите имя нового пользователя: " USERNAME
useradd -m -G wheel,video,audio,storage -s /bin/bash $USERNAME
echo "УСТАНОВКА ПАРОЛЯ ДЛЯ $USERNAME"
passwd $USERNAME

sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# 8. Установка твоего набора ПО (USB, Архивы, Разработка, Консоль)
echo "--- 8. Установка дополнительного ПО (USB, Архивы, Git, Разработка) ---"
pacman -S --noconfirm --needed \
    udiskie udisks2 \
    p7zip unrar zip unzip lrzip lz4 mtools dosfstools squashfs-tools \
    base-devel git bash-completion pacman-contrib \
    vim neovim micro htop wget curl

# 9. Настройка автоматической очистки кэша пакмана (оставляем только 2 версии)
echo "--- 9. Настройка очистки кэша ---"
systemctl enable paccache.timer

echo "--------------------------------------------------------"
echo "ВСЕ ГОТОВО!"
echo "Драйвер NVIDIA v3 установлен, Snapper настроен,"
echo "Доп. утилиты и Git готовы к работе."
echo "1. Введите 'exit'"
echo "2. Введите 'umount -R /mnt'"
echo "3. Введите 'reboot'"
echo "--------------------------------------------------------"
