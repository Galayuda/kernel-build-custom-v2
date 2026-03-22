#!/bin/bash

# ============================================================================
# download_artifacts_v2.sh - Скачать артефакты с GitHub Actions
# ВЕРСИЯ 2: Использует curl вместо wget (лучше работает с GitHub API)
# ============================================================================

# НАСТРОЙКИ - ВСТАВЬ СВОИ ЗНАЧЕНИЯ!
REPO="Galayuda/kernel-build-custom-v2"
TOKEN=""  # ← Вставь свой GitHub токен сюда (ghp_...)
RUN_ID="23406183266" # ← Твой номер сборки (из URL actions)

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# Проверка токена
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
    echo "  7. Вставь в этот скрипт (строка 10)"
    echo ""
    exit 1
fi

# ============================================================================
# Список артефактов
# ============================================================================
echo ""
echo -e "${BLUE}📦 Артефакты для запуска #$RUN_ID:${NC}"
echo ""

ARTIFACTS_JSON=$(curl -sL \
    -H "Authorization: token $TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$REPO/actions/runs/$RUN_ID/artifacts")

# Показать список
echo "$ARTIFACTS_JSON" | jq -r '.artifacts[] | "  - \(.name) (ID: \(.id), \(.size_in_bytes) байт)"'

ARTIFACT_COUNT=$(echo "$ARTIFACTS_JSON" | jq -r '.artifacts | length')
if [ "$ARTIFACT_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ Артефакты не найдены!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Найдено артефактов: $ARTIFACT_COUNT${NC}"
echo ""

# ============================================================================
# Скачивание
# ============================================================================
echo -e "${BLUE}📥 Скачивание артефактов...${NC}"
echo ""

DOWNLOAD_DIR="$HOME/Загрузки/kernel-artifacts-$RUN_ID"
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

# Скачать каждый артефакт
echo "$ARTIFACTS_JSON" | jq -r '.artifacts[] | "\(.id) \(.name)"' | while read ARTIFACT_ID ARTIFACT_NAME; do
    echo -e "${YELLOW}⬇️  Скачивание: $ARTIFACT_NAME${NC}"
    
    DOWNLOAD_URL="https://api.github.com/repos/$REPO/actions/artifacts/$ARTIFACT_ID/zip"
    
    # curl с авторизацией
    curl -sL \
        -H "Authorization: token $TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -o "$ARTIFACT_NAME.zip" \
        "$DOWNLOAD_URL"
    
    if [ -f "$ARTIFACT_NAME.zip" ] && [ -s "$ARTIFACT_NAME.zip" ]; then
        SIZE=$(ls -lh "$ARTIFACT_NAME.zip" | awk '{print $5}')
        echo -e "${GREEN}   ✅ Скачано: $ARTIFACT_NAME.zip ($SIZE)${NC}"
        
        unzip -q "$ARTIFACT_NAME.zip"
        rm "$ARTIFACT_NAME.zip"
        
        echo -e "   📁 Содержимое:"
        ls -lh | grep -v "^d" | tail -n +2 | awk '{print "      " $9 " (" $5 ")"}'
    else
        echo -e "${RED}   ❌ Ошибка! Файл пустой.${NC}"
    fi
    
    echo ""
done

# ============================================================================
# Итог
# ============================================================================
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              СКАЧИВАНИЕ ЗАВЕРШЕНО! ✅                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "📁 Файлы в: ${GREEN}$DOWNLOAD_DIR${NC}"
echo ""
ls -lh "$DOWNLOAD_DIR"
echo ""
echo -e "${YELLOW}Для установки ядра:${NC}"
echo "  1. bzImage → /boot/vmlinuz-6.18.9-github"
echo "  2. modules/* → /lib/modules/6.18.9-github/"
echo "  3. sudo grub-mkconfig -o /boot/grub/grub.cfg"
echo ""
