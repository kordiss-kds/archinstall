#!/bin/bash

# Остановить скрипт при любой ошибке
set -e

echo "--- Начинаю установку окружения Hyprland ---"

# Список пакетов
PACKAGES=(
    # Основа
    hyprland
    hyprpolkitagent
    xdg-desktop-portal-hyprland
    xorg-xwayland
    qt5-wayland
    qt6-wayland
    
    # Интерфейс
    waybar
    rofi-wayland
    swww
    dunst
    nwg-look
    
    # Утилиты
    kitty
    thunar
    gvfs
    grim
    slurp
    wl-clipboard
    brightnessctl         
    network-manager-applet 
    
    # Звук
    pipewire
    wireplumber
    pipewire-audio
    pipewire-pulse
    pavucontrol             
    
    # Шрифты и иконки
    ttf-jetbrains-mono-nerd
    noto-fonts-emoji
    papirus-icon-theme
)

# Установка через pacman
# --needed не переустанавливает то, что уже есть
# --noconfirm не задает лишних вопросов
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

echo "--- Установка завершена успешно! ---"
echo "Теперь можно настраивать конфиги и запускаться."
