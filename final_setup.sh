#!/bin/bash

# --- 1. Оптимизация Pacman ---
sudo sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
sudo sed -i 's/#Color/Color\nILoveCandy/' /etc/pacman.conf

# --- 2. Установка основного ПО, Драйверов и Файловых менеджеров ---
echo "--- Установка пакетов ---"
sudo pacman -Syu --noconfirm --needed \
    nvidia-open-cachyos nvidia-utils lib32-nvidia-utils amd-ucode \
    mc yazi gpm \
    xdg-user-dirs udiskie udisks2 \
    p7zip unrar zip unzip lrzip lz4 mtools dosfstools squashfs-tools \
    base-devel git bash-completion pacman-contrib \
    vim neovim micro htop wget curl \
    pipewire pipewire-pulse pipewire-alsa pipewire-jack \
    wireplumber bluez bluez-utils

# --- 3. Настройка сервисов ---
echo "--- Включение служб ---"
sudo systemctl enable --now gpm          # Мышь в консоли
sudo systemctl enable --now bluetooth    # Блютуз
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now systemd-timesyncd
sudo systemctl enable --now paccache.timer
sudo systemctl enable --now grub-btrfsd

# --- 4. Настройка папок пользователя (English) ---
echo "--- Настройка каталогов XDG ---"
LC_ALL=C xdg-user-dirs-update --force

# --- 5. Локализация консоли и время ---
echo "--- Настройка локализации ---"
sudo ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
sudo hwclock --systohc
# Предполагаем, что locale.gen уже настроен в chroot, просто обновляем:
sudo locale-gen

# Настройка переключения Alt+Shift в консоли
echo "KEYMAP=ruwin_alt_sh-UTF-8" | sudo tee /etc/vconsole.conf
echo "FONT=cyr-sun16" | sudo tee -a /etc/vconsole.conf

# --- 6. Финальная сборка ---
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "--------------------------------------------------------"
echo "СИСТЕМА ПОЛНОСТЬЮ ГОТОВА!"
echo "Попробуй запустить команду 'mc'. Там будет работать мышь!"
echo "--------------------------------------------------------"
