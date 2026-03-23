# 📋 ОТЧЁТ О СБОРКЕ И ИСПРАВЛЕНИЯХ

## ❌ ЧТО ПОШЛО НЕ ТАК В ПЕРВОЙ СБОРКЕ

### Проблема 1: Сборка использовала старый коммит
- **Коммит:** `659cb3d` (от 23 марта 12:00)
- **Проблема:** `CONFIG_DRM_I915=y` (встроенная графика)
- **Результат:** Графика не работала при загрузке

### Проблема 2: .config.backup не найден при проверке
- **Причина:** Workflow искал `.config.backup` в папке `linux-build/`
- **На самом деле:** Файл сохранялся в `$GITHUB_WORKSPACE/.config.backup`
- **Результат:** Ошибка на шаге Verify artifacts

---

## ✅ ЧТО ИСПРАВЛЕНО

### 1. Конфигурация ядра
**Файл:** `.config`
- `CONFIG_DRM_I915=m` (было `=y`) ← **ГРАФИКА ТЕПЕРЬ МОДУЛЕМ**
- `CONFIG_USB_XHCI_PCI=y` ← USB встроен
- `CONFIG_HID_GENERIC=y` ← Клавиатура/мышь встроены
- `CONFIG_SND_HDA*=m` ← Звук модулями

**Почему `i915=m` а не `=y`?**
- В работающем ядре Calculate `i915` — модуль
- При `i915=y` возникает конфликт с `efifb` на ранней загрузке
- Модуль загружается позже через initramfs — всё работает

---

### 2. Workflow
**Файл:** `.github/workflows/kernel-build.yml`
- Исправлён путь к `.config.backup` в шаге Verify
- Теперь: `ls -lh "$GITHUB_WORKSPACE/.config.backup"`

---

### 3. Скрипты установки
**Файл:** `install_kernel_github.sh`
- Автоматическое создание initramfs с правильными модулями
- Включает: i915, xhci, hid, snd-hda, iwlwifi
- Обновление GRUB с правильной записью

---

## 🚀 ЧТО ДЕЛАТЬ ТЕПЕРЬ

### 1. Запусти новую сборку

https://github.com/Galayuda/kernel-build-custom-v2/actions

1. Выбери **"Build Linux Kernel 6.18.9-custom_v2"**
2. Нажми **"Run workflow"**
3. Config type: **`custom`** ✅
4. Жди ~32-36 минут

---

### 2. Скачай артефакты

**Вариант A: Через браузер**
- Открой последний запуск (должен быть зелёным ✅)
- Внизу секция **"Artifacts"**
- Скачай:
  - `bzImage-6.18.9.zip`
  - `modules-6.18.9.zip`
  - `config-6.18.9.zip` (опционально)

**Вариант B: Через скрипт**
```bash
cd /home/user/soft/kernel-github-action
./download_artifacts.sh
```

---

### 3. Распакуй артефакты

```bash
mkdir -p /tmp/kernel_github
cd /tmp/kernel_github

# Распакуй bzImage
unzip ~/Downloads/bzImage-6.18.9.zip

# Распакуй модули
unzip ~/Downloads/modules-6.18.9.zip

# Проверь структуру
ls -la
# Должно быть: bzImage, modules/
```

---

### 4. Установи ядро

```bash
sudo /home/user/soft/kernel-github-action/install_kernel_github.sh /tmp/kernel_github
```

**Что сделает скрипт:**
1. ✅ Установит модули в `/lib/modules/6.18.9-github/`
2. ✅ Скопирует ядро в `/boot/vmlinuz-6.18.9-github`
3. ✅ Создаст initramfs с модулями (~20-30 MB)
4. ✅ Обновит GRUB

---

### 5. Перезагрузись

```bash
sudo reboot
```

В меню GRUB выбери **"GitHub 6.18.9-github (Actions)"**

---

### 6. Проверь работу

```bash
# Версия ядра
uname -r
# Должно быть: 6.18.9-github

# Графика
glxinfo | grep "OpenGL renderer"
# Должно быть: Mesa Intel(R) HD Graphics 405 (BSW)

# Звук
aplay -l
# Должны быть устройства

# WiFi
iwconfig
# Должен быть беспроводной интерфейс

# USB
lsusb
# Должны быть USB устройства
```

---

## 📊 ОЖИДАЕМЫЕ РАЗМЕРЫ

| Файл | Размер |
|------|--------|
| `bzImage` | ~9.5 MB |
| `modules` | ~166 MB |
| `initramfs` | ~20-30 MB |

---

## 🔧 ВОЗМОЖНЫЕ ПРОБЛЕМЫ

### Клавиатура/мышь не работают
```bash
# Пересоздай initramfs
sudo dracut --force --kver 6.18.9-github \
    --add-drivers "hid-generic xhci-hcd xhci-pci" \
    /boot/initramfs-6.18.9-github.img
```

### Нет графики
```bash
# Проверь загрузку i915
lsmod | grep i915

# Если пусто - пересоздай initramfs
sudo dracut --force --kver 6.18.9-github \
    --add-drivers "i915 drm_kms_helper" \
    /boot/initramfs-6.18.9-github.img
```

### Нет звука
```bash
# Пересоздай initramfs со звуком
sudo dracut --force --kver 6.18.9-github \
    --add-drivers "snd-hda-intel snd-hda-codec-realtek" \
    /boot/initramfs-6.18.9-github.img
```

---

## ✅ КРИТЕРИИ УСПЕХА

- ✅ Ядро загружается: `uname -r` → `6.18.9-github`
- ✅ Графика работает: консоль видна, нет ошибок
- ✅ Клавиатура/мышь работают сразу
- ✅ Звук определяется: `aplay -l` показывает устройства
- ✅ WiFi работает: `iwconfig` показывает интерфейс
- ✅ initramfs ~20-30 MB (не 200 MB!)

---

## 📝 ЗАМЕТКИ

1. **initramfs создаётся через dracut** — это стандарт для Calculate Linux
2. **Модули копируются из артефактов GitHub** — не нужно компилировать локально
3. **GRUB обновляется автоматически** — запись добавляется в 06_custom_menu
4. **UUID разделов** уже прописаны в скрипте

---

## 🔗 ССЫЛКИ

- Репозиторий: https://github.com/Galayuda/kernel-build-custom-v2
- Workflow: https://github.com/Galayuda/kernel-build-custom-v2/actions
- Последняя сборка: проверь статус на GitHub

---

**Удачи со сборкой! 🎯**
