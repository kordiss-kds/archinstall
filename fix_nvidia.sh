#!/bin/bash

echo "--- 1. Исправление ключей и обновление баз ---"
sudo pacman-key --recv-keys F3B607488DB359F5
sudo pacman-key --lsign-key F3B607488DB359F5
sudo pacman -Syy

echo "--- 2. Установка новых пакетов драйвера (CachyOS RTX 3060+) ---"
# Мы устанавливаем специфичный для ядра cachyos пакет и утилиты
sudo pacman -S --needed \
    linux-cachyos-nvidia-open \
    nvidia-utils \
    lib32-nvidia-utils \
    nvidia-settings

echo "--- 3. Настройка ранней загрузки модулей (KMS) ---"
# Добавляем модули nvidia в mkinitcpio.conf, если их там еще нет
if ! grep -q "nvidia nvidia_modeset" /etc/mkinitcpio.conf; then
    sudo sed -i 's/MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
    echo "Модули добавлены в mkinitcpio.conf"
fi

# Включаем DRM Modeset для GRUB
if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
    echo "Параметр modeset добавлен в GRUB"
fi

echo "--- 4. Пересборка образа ядра и GRUB ---"
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "----------------------------------------------------"
echo "УСТАНОВКА ЗАВЕРШЕНА!"
echo "Теперь введи: reboot"
echo "После перезагрузки проверь работу: nvidia-smi"
echo "----------------------------------------------------"
