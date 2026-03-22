#!/bin/bash

# ============================================================================
# download_artifacts.sh - Скачать артефакты с GitHub Actions
# ============================================================================

# НАСТРОЙКИ
REPO="Galayuda/kernel-build-custom-v2"
TOKEN=""  # ← Вставь свой токен сюда!
RUN_ID="" # ← Можно указать конкретный запуск (или оставь пустым для последнего)

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# ШАГ 1: Проверка токена
# ============================================================================
if [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ Ошибка: GitHub токен не указан!${NC}"
    echo ""
    echo "Как получить токен:"
    echo "  1. Открой: https://github.com/settings/tokens"
    echo "  2. Нажми 'Generate new token (classic)'"
    echo "  3. Name: 'kernel-artifacts'"
    echo "  4. Scopes: ✅ repo (полный доступ)"
    echo "  5. Нажми 'Generate token'"
    echo "  6. Скопируй токен (ghp_...)"
    echo "  7. Вставь в этот скрипт: TOKEN=\"ghp_...\""
    echo ""
    exit 1
fi

# ============================================================================
# ШАГ 2: Найти последний запуск (если RUN_ID не указан)
# ============================================================================
if [ -z "$RUN_ID" ]; then
    echo -e "${BLUE}🔍 Поиск последнего завершённого запуска...${NC}"
    
    RUN_ID=$(curl -s -H "Authorization: Bearer $TOKEN" \
        "https://api.github.com/repos/$REPO/actions/runs?status=success&per_page=1" \
        | jq -r '.workflow_runs[0].id')
    
    if [ -z "$RUN_ID" ] || [ "$RUN_ID" = "null" ]; then
        echo -e "${RED}❌ Не удалось найти завершённые запуски!${NC}"
        echo "Проверь токен и имя репозитория"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Найден запуск: $RUN_ID${NC}"
fi

# ============================================================================
# ШАГ 3: Список артефактов
# ============================================================================
echo ""
echo -e "${BLUE}📦 Артефакты для запуска #$RUN_ID:${NC}"
echo ""

ARTIFACTS=$(curl -s -H "Authorization: Bearer $TOKEN" \
    "https://api.github.com/repos/$REPO/actions/runs/$RUN_ID/artifacts")

# Показать список артефактов
echo "$ARTIFACTS" | jq -r '.artifacts[] | "  - \(.name) (ID: \(.id), \(.size_in_bytes) байт)"'

# Проверка есть ли артефакты
ARTIFACT_COUNT=$(echo "$ARTIFACTS" | jq -r '.artifacts | length')
if [ "$ARTIFACT_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ Артефакты не найдены!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Найдено артефактов: $ARTIFACT_COUNT${NC}"
echo ""

# ============================================================================
# ШАГ 4: Скачать каждый артефакт
# ============================================================================
echo -e "${BLUE}📥 Скачивание артефактов...${NC}"
echo ""

# Создать папку для загрузки
DOWNLOAD_DIR="$HOME/Загрузки/kernel-artifacts-$RUN_ID"
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

# Скачать каждый артефакт
echo "$ARTIFACTS" | jq -r '.artifacts[] | "\(.id) \(.name)"' | while read ARTIFACT_ID ARTIFACT_NAME; do
    echo -e "${YELLOW}⬇️  Скачивание: $ARTIFACT_NAME${NC}"
    
    # URL для скачивания
    DOWNLOAD_URL="https://api.github.com/repos/$REPO/actions/artifacts/$ARTIFACT_ID/zip"
    
    # Скачать с wget
    wget -q \
        --header="Authorization: Bearer $TOKEN" \
        --output-document="$ARTIFACT_NAME.zip" \
        "$DOWNLOAD_URL"
    
    if [ -f "$ARTIFACT_NAME.zip" ]; then
        echo -e "${GREEN}   ✅ Скачано: $ARTIFACT_NAME.zip ($(ls -lh "$ARTIFACT_NAME.zip" | awk '{print $5}'))${NC}"
        
        # Распаковать
        echo -e "   📦 Распаковка..."
        unzip -q "$ARTIFACT_NAME.zip"
        rm "$ARTIFACT_NAME.zip"
        
        # Показать что внутри
        echo -e "   📁 Содержимое:"
        ls -lh | grep -v "^d" | tail -n +2 | awk '{print "      " $9 " (" $5 ")"}'
    else
        echo -e "${RED}   ❌ Ошибка скачивания!${NC}"
    fi
    
    echo ""
done

# ============================================================================
# ШАГ 5: Итог
# ============================================================================
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              СКАЧИВАНИЕ ЗАВЕРШЕНО! ✅                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "📁 Файлы в: ${GREEN}$DOWNLOAD_DIR${NC}"
echo ""
echo -e "📋 Содержимое:"
ls -lh "$DOWNLOAD_DIR"
echo ""
echo -e "${YELLOW}Для установки ядра:${NC}"
echo "  1. bzImage → /boot/vmlinuz-6.18.9-github"
echo "  2. modules/* → /lib/modules/6.18.9-github/"
echo "  3. sudo grub-mkconfig -o /boot/grub/grub.cfg"
echo ""
