#!/bin/bash
# ==============================================================================
# Простой скрипт обновления GRUB
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Обновление GRUB меню...${NC}"

# Проверка прав
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Запустите от root${NC}"
    exit 1
fi

# UUID
ROOT_UUID="a35252ab-fcc5-4518-89b4-818a2dbd60fb"
RESUME_PARTUUID="c7f48d95-8cad-4f50-8de7-5b80735d6e17"

echo -e "${YELLOW}[1/4] Очистка старых записей...${NC}"
rm -f /etc/grub.d/06_custom_menu
chmod -x /etc/grub.d/07_passwd 2>/dev/null || true
chmod -x /etc/grub.d/10_linux 2>/dev/null || true
chmod -x /etc/grub.d/30_os-prober 2>/dev/null || true
echo "   ✅ Очистка завершена"

echo -e "${YELLOW}[2/4] Создание меню...${NC}"

cat > /etc/grub.d/06_custom_menu << 'EOF'
#!/bin/sh
cat << 'GRUBMENU'
set timeout=5
set timeout_style=menu
set default=0

if background_image -m stretch /boot/grub/grub-calculate.png; then
  set color_normal=white/black
  set color_highlight=black/light-gray
else
  set color_normal=white/black
  set color_highlight=black/light-gray
fi

menuentry 'Calculate Linux 6.18.9-calculate (ОСНОВНОЕ)' --class calculate --class gnu-linux --class gnu --class os {
    linux   /boot/vmlinuz-6.18.9-calculate root=UUID=a35252ab-fcc5-4518-89b4-818a2dbd60fb ro fbcon=map:0 resume=PARTUUID=c7f48d95-8cad-4f50-8de7-5b80735d6e17 rd.retry=40 calculate=video:modesetting quiet verbose
    initrd  /boot/initramfs-6.18.9-calculate.img
}

menuentry 'GitHub 6.18.9-github (Actions)' --class calculate --class gnu-linux --class gnu --class os {
    linux   /boot/vmlinuz-6.18.9-github root=UUID=a35252ab-fcc5-4518-89b4-818a2dbd60fb ro fbcon=map:0 resume=PARTUUID=c7f48d95-8cad-4f50-8de7-5b80735d6e17 rd.retry=40 calculate=video:modesetting quiet verbose
    initrd  /boot/initramfs-6.18.9-github.img
}

menuentry 'Memtest86+ (ПРОВЕРКА ПАМЯТИ)' --class memtest {
    linux16 /boot/memtest86+-5.01.bin
}
GRUBMENU
EOF

chmod +x /etc/grub.d/06_custom_menu
echo "   ✅ Меню создано"

echo -e "${YELLOW}[3/4] Генерация GRUB...${NC}"
grub-mkconfig -o /boot/grub/grub.cfg 2>&1 | tail -3
echo "   ✅ GRUB обновлён"

echo -e "${YELLOW}[4/4] Проверка...${NC}"
echo ""
echo -e "${GREEN}Записи меню:${NC}"
grep "^menuentry" /boot/grub/grub.cfg | head -10

echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}✅ GRUB готов!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo "Порядок загрузки:"
echo "  1. Calculate Linux 6.18.9-calculate (ОСНОВНОЕ)"
echo "  2. GitHub 6.18.9-github (Actions)"
echo "  3. Memtest86+"
echo ""
