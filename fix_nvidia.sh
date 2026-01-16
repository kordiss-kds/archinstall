#!/bin/bash

echo "--- 1. Исправление ключей CachyOS ---"
sudo pacman-key --recv-keys F3B607488DB359F5
sudo pacman-key --lsign-key F3B607488DB359F5

echo "--- 2. Принудительное обновление баз данных ---"
# -Syy заставляет pacman заново скачать файлы баз, даже если он думает, что они свежие
sudo pacman -Syy

echo "--- 3. Поиск доступного драйвера ---"
# Проверяем, есть ли версия именно от CachyOS
if pacman -Sl cachyos-v3 | grep -q "nvidia-open-cachyos"; then
    echo "Найдена версия cachyos, устанавливаю..."
    sudo pacman -S --needed nvidia-open-cachyos nvidia-utils lib32-nvidia-utils
else
    echo "Версия cachyos не найдена. Устанавливаю стандартную версию nvidia-open..."
    sudo pacman -S --needed nvidia-open nvidia-utils lib32-nvidia-utils
fi

echo "--- 4. Обновление конфигурации ядра ---"
sudo mkinitcpio -P

echo "----------------------------------------------------"
echo "Готово! Теперь ОБЯЗАТЕЛЬНО введи: reboot"
echo "После перезагрузки проверь карту командой: nvidia-smi"
echo "----------------------------------------------------"
