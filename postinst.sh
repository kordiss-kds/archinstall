#!/bin/bash
set -e

echo "=== ПРЕДВАРИТЕЛЬНАЯ НАСТРОЙКА ==="

# 1. Запрос данных с клавиатуры
read -p "Введите имя компьютера (hostname): " MY_HOSTNAME
read -p "Введите имя пользователя: " MY_USER

# 2. Локализация и время
TIMEZONE="Europe/Moscow"
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Настройка локалей (два языка)
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
echo "$MY_HOSTNAME" > /etc/hostname

# Настройка консоли (Terminus v28b + Alt+Shift)
echo "KEYMAP=ruwin_alt_sh-UTF-8
FONT=ter-v28b" > /etc/vconsole.conf

echo "=== 3. УСТАНОВКА ВСЕХ ПАКЕТОВ ==="

# Добавлен terminus-font для работы шрифта ter-v28b
pacman -S --noconfirm \
    sudo \
    terminus-font \
    zram-generator \
    grub \
    efibootmgr \
    grub-btrfs \
    inotify-tools \
    networkmanager \
    bluez \
    bluez-utils \
    udisks2 \
    snapper

echo "=== 4. НАСТРОЙКА СИСТЕМЫ ==="

# Настройка ZRAM
cat <<EOF > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

# Включение служб
systemctl enable NetworkManager
systemctl enable bluetooth

# Настройка GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Настройка Snapper
umount /.snapshots || true
rm -rf /.snapshots
snapper -c root create-config /
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -a

echo "=== 5. ПОЛЬЗОВАТЕЛИ И ПАРОЛИ ==="

# Настройка пароля root
echo "Настройка пароля для ROOT:"
passwd root

# Создание пользователя и его пароля
useradd -m -G wheel,storage,power -s /bin/bash "$MY_USER"
echo "Настройка пароля для пользователя $MY_USER:"
passwd "$MY_USER"

# Разрешаем группе wheel использовать sudo
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "-------------------------------------------------"
echo "ВСЕ НАСТРОЕНО!"
echo "Шрифт консоли: ter-v28b (Terminus)"
echo "Переключение в TTY: Alt + Shift"
echo "-------------------------------------------------"
echo "Выходите из системы: exit"
