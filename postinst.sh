#!/bin/bash
set -e

echo "=== 1. ПРЕДВАРИТЕЛЬНЫЕ ДАННЫЕ ==="
read -p "Введите имя компьютера (hostname): " MY_HOSTNAME
read -p "Введите имя пользователя: " MY_USER

# 2. Локализация и время
TIMEZONE="Europe/Moscow"
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
echo "$MY_HOSTNAME" > /etc/hostname

# Настройка консоли (Terminus v28b + Alt+Shift)
echo "KEYMAP=ruwin_alt_sh-UTF-8
FONT=ter-v28b" > /etc/vconsole.conf

echo "=== 2. УСТАНОВКА ПАКЕТОВ (Драйверы, Звук, Утилиты) ==="
pacman -S --noconfirm --needed \
    sudo terminus-font zram-generator grub efibootmgr \
    grub-btrfs inotify-tools snapper nvidia-open-cachyos \
    nvidia-utils lib32-nvidia-utils amd-ucode pipewire \
    pipewire-pulse pipewire-alsa pipewire-jack wireplumber \
    bluez bluez-utils networkmanager udiskie udisks2 \
    mc yazi gpm xdg-user-dirs p7zip unrar zip unzip \
    lrzip lz4 mtools dosfstools squashfs-tools base-devel \
    git bash-completion pacman-contrib vim neovim micro \
    htop wget curl

echo "=== 3. НАСТРОЙКА СЕРВИСОВ И СИСТЕМЫ ==="

# ZRAM
cat <<EOF > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

# Включение служб (без --now, так как мы в chroot)
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable gpm
systemctl enable systemd-timesyncd
systemctl enable paccache.timer
systemctl enable grub-btrfsd
systemctl enable nvidia-persistenced

# GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Snapper
umount /.snapshots || true
rm -rf /.snapshots
snapper -c root create-config /
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -a

echo "=== 4. ПОЛЬЗОВАТЕЛИ И ПАРОЛИ ==="
echo "Пароль для ROOT:"
passwd root

useradd -m -G wheel,storage,power -s /bin/bash "$MY_USER"
echo "Пароль для пользователя $MY_USER:"
passwd "$MY_USER"

sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Настройка папок пользователя на английском (от имени пользователя)
echo "Настройка XDG-папок на английском..."
sudo -u "$MY_USER" LC_ALL=C xdg-user-dirs-update --force

echo "-------------------------------------------------"
echo "УСТАНОВКА ЗАВЕРШЕНА!"
echo "-------------------------------------------------"
echo "1. Введите 'exit'"
echo "2. Введите 'umount -R /mnt'"
echo "3. Введите 'reboot'"
