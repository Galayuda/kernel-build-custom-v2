#!/bin/bash
# ==============================================================================
# Скрипт установки ядра из GitHub Actions
# Автоматически создаёт initramfs с правильными модулями
# ==============================================================================

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Версия ядра
KERNEL_VERSION="6.18.9-github"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Установка ядра из GitHub Actions                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Ошибка: Запустите от root (sudo $0)${NC}"
    exit 1
fi

# Проверка аргументов
if [ -z "$1" ]; then
    echo -e "${YELLOW}Использование:${NC}"
    echo "  $0 <путь_к_папке_с_артефактами>"
    echo ""
    echo "Пример:"
    echo "  sudo $0 /tmp/kernel_github"
    echo ""
    echo "Структура папки должна содержать:"
    echo "  - bzImage (образ ядра)"
    echo "  - modules/ (папка с модулями)"
    echo "  - .config (конфигурация, опционально)"
    exit 1
fi

ARTIFACTS_DIR="$1"

# Проверка наличия артефактов
echo -e "${YELLOW}[1/6] Проверка артефактов...${NC}"

if [ ! -f "$ARTIFACTS_DIR/bzImage" ]; then
    echo -e "   ${RED}Ошибка: bzImage не найден в $ARTIFACTS_DIR${NC}"
    exit 1
fi

if [ ! -d "$ARTIFACTS_DIR/modules" ]; then
    echo -e "   ${RED}Ошибка: Папка modules не найдена в $ARTIFACTS_DIR${NC}"
    exit 1
fi

echo -e "   ✅ bzImage: найден ($(ls -lh "$ARTIFACTS_DIR/bzImage" | awk '{print $5}'))"
echo -e "   ✅ modules: найдены ($(du -sh "$ARTIFACTS_DIR/modules" | cut -f1))"

# ==============================================================================
# Очистка старых модулей
# ==============================================================================
echo
echo -e "${YELLOW}[2/6] Очистка старых модулей...${NC}"

MODULES_DIR="/lib/modules/${KERNEL_VERSION}"
if [ -d "$MODULES_DIR" ]; then
    echo -e "   ${YELLOW}⚠️  Удаляю старую папку модулей...${NC}"
    rm -rf "$MODULES_DIR"
    echo -e "   ✅ Удалено: $MODULES_DIR"
else
    echo -e "   ℹ️  Старых модулей нет"
fi

# ==============================================================================
# Установка модулей
# ==============================================================================
echo
echo -e "${YELLOW}[3/6] Установка модулей...${NC}"

mkdir -p "$MODULES_DIR"
cp -r "$ARTIFACTS_DIR/modules/"* "$MODULES_DIR/"

echo -e "   ✅ Модули установлены в $MODULES_DIR"
echo -e "   📊 Размер: $(du -sh "$MODULES_DIR" | cut -f1)"

# depmod
echo -e "   📝 Генерация зависимостей модулей..."
depmod -a "$KERNEL_VERSION"
echo -e "   ✅ depmod завершён"

# ==============================================================================
# Установка ядра
# ==============================================================================
echo
echo -e "${YELLOW}[4/6] Установка ядра...${NC}"

cp "$ARTIFACTS_DIR/bzImage" "/boot/vmlinuz-${KERNEL_VERSION}"
echo -e "   ✅ Ядро скопировано: /boot/vmlinuz-${KERNEL_VERSION}"

# Сохраняем конфиг если есть
if [ -f "$ARTIFACTS_DIR/.config" ]; then
    cp "$ARTIFACTS_DIR/.config" "/boot/config-${KERNEL_VERSION}"
    echo -e "   ✅ Конфиг сохранён: /boot/config-${KERNEL_VERSION}"
fi

# ==============================================================================
# Создание initramfs
# ==============================================================================
echo
echo -e "${YELLOW}[5/6] Создание initramfs...${NC}"

# КРИТИЧНО: модули для ранней загрузки
# Графика, USB, HID, звук, WiFi, файловые системы
echo -e "   📝 Создание initramfs с модулями..."

dracut --force \
    --kver "$KERNEL_VERSION" \
    --add-drivers "i915 drm_kms_helper ttm drm_display_helper drm_buddy video i2c-algo-bit" \
    --add-drivers "xhci-hcd xhci-pci ehci-hcd ehci-pci ohci-hcd ohci-pci uhci-hcd" \
    --add-drivers "hid-generic hid-apple hid-logitech hid-cherry hid-microsoft" \
    --add-drivers "snd-hda-core snd-hda-intel snd-hda-codec snd-hda-codec-realtek snd-hda-codec-hdmi" \
    --add-drivers "iwlwifi cfg80211 mac80211 iwlmvm" \
    --add-drivers "ext4 crc32c_generic sd_mod" \
    "/boot/initramfs-${KERNEL_VERSION}.img" \
    "$KERNEL_VERSION" 2>&1 | tail -5

if [ -f "/boot/initramfs-${KERNEL_VERSION}.img" ]; then
    INITRAMFS_SIZE=$(du -sh "/boot/initramfs-${KERNEL_VERSION}.img" | cut -f1)
    echo -e "   ✅ initramfs создан: /boot/initramfs-${KERNEL_VERSION}.img (${INITRAMFS_SIZE})"
else
    echo -e "   ${RED}Ошибка: initramfs не создан!${NC}"
    exit 1
fi

# ==============================================================================
# Обновление GRUB
# ==============================================================================
echo
echo -e "${YELLOW}[6/6] Обновление GRUB...${NC}"

# UUID разделов
ROOT_UUID="a35252ab-fcc5-4518-89b4-818a2dbd60fb"
RESUME_PARTUUID="c7f48d95-8cad-4f50-8de7-5b80735d6e17"

# Проверяем есть ли уже запись для этого ядра
if ! grep -q "vmlinuz-${KERNEL_VERSION}" /etc/grub.d/06_custom_menu 2>/dev/null; then
    echo -e "   📝 Добавление записи в GRUB..."
    
    # Вставляем новую запись после Calculate
    sed -i "/menuentry 'Calculate Linux/i\\
menuentry 'GitHub ${KERNEL_VERSION} (Actions)' --class calculate --class gnu-linux --class gnu --class os {\\
    linux   /boot/vmlinuz-${KERNEL_VERSION} root=UUID=${ROOT_UUID} ro fbcon=map:0 resume=PARTUUID=${RESUME_PARTUUID} rd.retry=40 calculate=video:modesetting quiet verbose\\
    initrd  /boot/initramfs-${KERNEL_VERSION}.img\\
}\\
" /etc/grub.d/06_custom_menu
    
    echo -e "   ✅ Запись добавлена"
else
    echo -e "   ℹ️  Запись уже существует"
fi

# Обновляем GRUB
grub-mkconfig -o /boot/grub/grub.cfg 2>&1 | tail -3
echo -e "   ✅ GRUB обновлён"

# ==============================================================================
# Итоговая информация
# ==============================================================================
echo
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ ЯДРО УСТАНОВЛЕНО!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo
echo -e "${CYAN}Установленные файлы:${NC}"
echo "  • Ядро:      /boot/vmlinuz-${KERNEL_VERSION}"
echo "  • Initramfs: /boot/initramfs-${KERNEL_VERSION}.img"
echo "  • Модули:    /lib/modules/${KERNEL_VERSION}/"
if [ -f "/boot/config-${KERNEL_VERSION}" ]; then
    echo "  • Конфиг:    /boot/config-${KERNEL_VERSION}"
fi
echo
echo -e "${CYAN}Для загрузки:${NC}"
echo "  1. Перезагрузитесь: sudo reboot"
echo "  2. Выберите 'GitHub ${KERNEL_VERSION}' в меню GRUB"
echo "  3. Проверьте: uname -r"
echo
echo -e "${CYAN}Проверка после загрузки:${NC}"
echo "  • Ядро:      uname -r"
echo "  • Графика:   glxinfo | grep 'OpenGL renderer'"
echo "  • Звук:      lsmod | grep snd"
echo "  • WiFi:      lsmod | grep iwl"
echo "  • USB:       lsusb"
echo
echo -e "${YELLOW}Если что-то не работает:${NC}"
echo "  • Клавиатура/мышь: проверьте загрузку hid-generic"
echo "  • Графика: проверьте загрузку i915"
echo "  • Звук: проверьте загрузку snd-hda-intel"
echo "  • Пересоздайте initramfs с нужными модулями"
echo
