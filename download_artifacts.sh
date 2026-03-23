#!/bin/bash
# ==============================================================================
# Скрипт скачивания артефактов с GitHub Actions
# ==============================================================================

set -e

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

REPO="Galayuda/kernel-build-custom-v2"
OUTPUT_DIR="${1:-/tmp/kernel_github}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Скачивание артефактов GitHub Actions                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo

# Проверка gh (GitHub CLI)
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Ошибка: GitHub CLI (gh) не найден${NC}"
    echo ""
    echo "Установите:"
    echo "  emerge --sync && emerge app-misc/gh"
    exit 1
fi

# Проверка авторизации
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Ошибка: Не авторизован в GitHub${NC}"
    echo ""
    echo "Выполните:"
    echo "  gh auth login"
    exit 1
fi

# Создаём папку
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

echo -e "${YELLOW}[1/3] Поиск последнего запуска workflow...${NC}"

# Получаем ID последнего успешного запуска
RUN_ID=$(gh run list --repo "$REPO" --branch main --status success --limit 1 --json databaseId --jq '.[0].databaseId')

if [ -z "$RUN_ID" ]; then
    echo -e "${RED}Ошибка: Не найдено успешных сборок${NC}"
    exit 1
fi

echo -e "   ✅ Найдена сборка: #$RUN_ID"

# ==============================================================================
# Скачивание артефактов
# ==============================================================================
echo
echo -e "${YELLOW}[2/3] Скачивание артефактов...${NC}"

# Скачиваем все артефакты
gh run download "$RUN_ID" --repo "$REPO" --dir "$OUTPUT_DIR"

echo -e "   ✅ Артефакты скачаны"

# ==============================================================================
# Проверка и распаковка
# ==============================================================================
echo
echo -e "${YELLOW}[3/3] Проверка артефактов...${NC}"

# bzImage
if [ -d "$OUTPUT_DIR/bzImage-6.18.9" ]; then
    mv "$OUTPUT_DIR/bzImage-6.18.9/bzImage" "$OUTPUT_DIR/bzImage"
    rm -rf "$OUTPUT_DIR/bzImage-6.18.9"
    echo -e "   ✅ bzImage: $(ls -lh "$OUTPUT_DIR/bzImage" | awk '{print $5}')"
else
    echo -e "   ${RED}bzImage не найден!${NC}"
fi

# modules
if [ -d "$OUTPUT_DIR/modules-6.18.9" ]; then
    mv "$OUTPUT_DIR/modules-6.18.9" "$OUTPUT_DIR/modules"
    MODULES_SIZE=$(du -sh "$OUTPUT_DIR/modules" | cut -f1)
    echo -e "   ✅ modules: $MODULES_SIZE"
else
    echo -e "   ${RED}modules не найдены!${NC}"
fi

# .config (если есть)
if [ -d "$OUTPUT_DIR/config-6.18.9" ]; then
    mv "$OUTPUT_DIR/config-6.18.9/.config.backup" "$OUTPUT_DIR/.config" 2>/dev/null || true
    rm -rf "$OUTPUT_DIR/config-6.18.9"
    if [ -f "$OUTPUT_DIR/.config" ]; then
        echo -e "   ✅ .config: скачан"
    fi
fi

# ==============================================================================
# Итоговая информация
# ==============================================================================
echo
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ АРТЕФАКТЫ СКАЧАНЫ!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo
echo -e "${CYAN}Папка: $OUTPUT_DIR${NC}"
echo
ls -lh "$OUTPUT_DIR" | grep -E "bzImage|modules|\.config"
echo
echo -e "${YELLOW}Для установки выполните:${NC}"
echo "  sudo /home/user/soft/kernel-github-action/install_kernel_github.sh $OUTPUT_DIR"
echo
