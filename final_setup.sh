#!/bin/bash

# --- 1. Настройка репозиториев CachyOS и оптимизация pacman ---
echo "--- 1. Настройка репозиториев CachyOS и ускорение ---"
curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz && cd cachyos-repo
./cachyos-repo.sh
cd ..

# Включаем 5 потоков загрузки и "ILoveCandy"
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
sed -i 's/#Color/Color\nILoveCandy/' /etc/pacman.conf

# --- 2. Установка драйверов и ядра ---
echo "--- 2. Установка NVIDIA Open Driver (RTX 3060) и Microcode ---"
pacman -Syu --noconfirm nvidia-open-cachyos nvidia-utils lib32-nvidia-utils amd-ucode

# --- 3. Локализация и Hostname ---
echo "--- 3. Настройка локализации ---"
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

# --- 4. Настройка Snapper (Btrfs) ---
echo "--- 4. Настройка Snapper ---"
umount -l /.snapshots 2>/dev/null
rm -rf /.snapshots
snapper -c root create-config /
rm -rf /.snapshots
mkdir /.snapshots
mount -a

# --- 5. Установка загрузчика GRUB ---
echo "--- 5. Установка GRUB и поддержка снимков ---"
pacman -S --noconfirm grub efibootmgr grub-btrfs
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
systemctl enable grub-btrfsd
grub-mkconfig -o /boot/grub/grub.cfg

# --- 6. Пользователи, Sudo и Сеть ---
echo "--- 6. Настройка доступа и сети ---"
systemctl enable NetworkManager
systemctl enable systemd-timesyncd

echo "УСТАНОВКА ПАРОЛЯ ДЛЯ ROOT"
passwd

read -p "Введите имя нового пользователя: " USERNAME
useradd -m -G wheel,video,audio,storage -s /bin/bash $USERNAME
echo "УСТАНОВКА ПАРОЛЯ ДЛЯ $USERNAME"
passwd $USERNAME

sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# --- 7. Установка ПО и Английские папки пользователя ---
echo "--- 7. Установка ПО (USB, Архивы, Git, Разработка) ---"
pacman -S --noconfirm --needed \
    xdg-user-dirs udiskie udisks2 \
    p7zip unrar zip unzip lrzip lz4 mtools dosfstools squashfs-tools \
    base-devel git bash-completion pacman-contrib \
    vim neovim micro htop wget curl

# Создаем английские папки (Desktop, Downloads и т.д.)
sudo -u $USERNAME LC_ALL=C xdg-user-dirs-update --force

# --- 8. Звук и Bluetooth ---
echo "--- 8. Настройка Pipewire и Bluetooth ---"
pacman -S --noconfirm --needed \
    pipewire pipewire-pulse pipewire-alsa pipewire-jack \
    wireplumber bluez bluez-utils

systemctl enable bluetooth
systemctl enable paccache.timer

# --- 9. Финальная сборка образа ядра ---
echo "--- 9. Пересборка образов ядра (mkinitcpio) ---"
mkinitcpio -P

echo "--------------------------------------------------------"
echo "УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!"
echo "Теперь:"
echo "1. exit"
echo "2. umount -R /mnt"
echo "3. reboot"
echo "--------------------------------------------------------"
