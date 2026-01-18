#!/bin/bash

# Цвета для красоты
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}--- 1. Установка необходимых пакетов ---${NC}"
sudo pacman -S --needed --noconfirm snapper grub-btrfs snap-pac inotify-tools

echo -e "${GREEN}--- 2. Подготовка конфигурации Snapper ---${NC}"
# Если конфиг уже есть, удаляем его для чистой настройки
if [ -f "/etc/snapper/configs/root" ]; then
    sudo snapper -c root delete-config
fi

# Размонтируем и удаляем папку .snapshots, если она осталась от старых попыток
sudo umount /.snapshots 2>/dev/null
sudo rm -rf /.snapshots

# Создаем новый конфиг для корня
sudo snapper -c root create-config /

echo -e "${GREEN}--- 3. Настройка Btrfs подтома для снимков ---${NC}"
# Snapper создал обычную папку. Удаляем её и создаем правильный подтом
sudo btrfs subvolume delete /.snapshots
sudo mkdir /.snapshots

# Монтируем подтом снимков из fstab (предполагаем, что он там есть)
# Если ты ставил по стандарту CachyOS/Arch, подтом называется @snapshots
sudo mount -a
echo "Подтом .snapshots примонтирован."

echo -e "${GREEN}--- 4. Настройка прав (группа wheel) ---${NC}"
sudo chmod a+rx /.snapshots
sudo chown :wheel /.snapshots
sudo sed -i 's/ALLOW_GROUPS=""/ALLOW_GROUPS="wheel"/' /etc/snapper/configs/root

echo -e "${GREEN}--- 5. Установка лимитов хранения ---${NC}"
# Ограничиваем количество снимков, чтобы не забить диск
sudo snapper -c root set-config "TIMELINE_LIMIT_HOURLY=5"
sudo snapper -c root set-config "TIMELINE_LIMIT_DAILY=7"
sudo snapper -c root set-config "TIMELINE_LIMIT_WEEKLY=0"
sudo snapper -c root set-config "TIMELINE_LIMIT_MONTHLY=0"
sudo snapper -c root set-config "TIMELINE_LIMIT_YEARLY=0"

echo -e "${GREEN}--- 6. Включение служб автоматизации ---${NC}"
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
sudo systemctl enable --now grub-btrfsd

echo -e "${GREEN}--- 7. Обновление GRUB ---${NC}"
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo -e "${GREEN}--------------------------------------------------${NC}"
echo -e "${GREEN}НАСТРОЙКА SNAPPER ЗАВЕРШЕНА!${NC}"
echo "Теперь при каждом обновлении пакетов будет создаваться снимок."
echo "Первый снимок вручную: snapper -c root create -d 'Initial Snapshot'"
echo -e "${GREEN}--------------------------------------------------${NC}"
