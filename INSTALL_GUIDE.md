# 📋 ИНСТРУКЦИЯ ПО УСТАНОВКЕ ЯДРА ИЗ GITHUB ACTIONS

## ✅ ЧТО ИСПРАВЛЕНО В КОНФИГУРАЦИИ

| Опция | Значение | Почему |
|-------|----------|--------|
| `CONFIG_DRM_I915` | **`=m`** | Графика должна быть модулем (не встроенной!) |
| `CONFIG_USB_XHCI_PCI` | **`=y`** | USB контроллер встроен для ранней загрузки |
| `CONFIG_HID_GENERIC` | **`=y`** | Клавиатура/мышь встроены |
| `CONFIG_INPUT_EVDEV` | **`=y`** | Input events встроены |
| `CONFIG_SND_HDA*` | **`=m`** | Звук модулями (загрузится через initramfs) |

---

## 🚀 ПОШАГОВАЯ ИНСТРУКЦИЯ

### ШАГ 1: Дождись завершения сборки

Зайди на https://github.com/Galayuda/kernel-build-custom-v2/actions

Дождись зелёной галочки ✅ на сборке.

---

### ШАГ 2: Скачай артефакты

**Вариант A: Через браузер**
1. Открой последний запуск workflow
2. Внизу страницы найди секцию **"Artifacts"**
3. Скачай:
   - `bzImage-6.18.9.zip`
   - `modules-6.18.9.zip`

**Вариант B: Через скрипт (рекомендуется)**
```bash
cd /home/user/soft/kernel-github-action
./download_artifacts.sh
```

---

### ШАГ 3: Распакуй артефакты

```bash
# Создай папку
mkdir -p /tmp/kernel_github
cd /tmp/kernel_github

# Распакуй bzImage
unzip ~/Downloads/bzImage-6.18.9.zip

# Распакуй модули
unzip ~/Downloads/modules-6.18.9.zip

# Проверь структуру
ls -la
# Должно быть:
# - bzImage
# - modules/ (папка с драйверами)
```

---

### ШАГ 4: Установи ядро

**Вариант A: Автоматическая установка (рекомендуется)**
```bash
sudo /home/user/soft/kernel-github-action/install_kernel_github.sh /tmp/kernel_github
```

**Вариант B: Ручная установка**
```bash
# 1. Установка модулей
sudo mkdir -p /lib/modules/6.18.9-github_v2
sudo cp -r /tmp/kernel_github/modules/* /lib/modules/6.18.9-github_v2/
sudo depmod -a 6.18.9-github_v2

# 2. Установка ядра
sudo cp /tmp/kernel_github/bzImage /boot/vmlinuz-6.18.9-github_v2

# 3. Создание initramfs
sudo dracut --force \
    --kver 6.18.9-github_v2 \
    --add-drivers "i915 xhci-hcd xhci-pci hid-generic snd-hda-core snd-hda-intel iwlwifi" \
    /boot/initramfs-6.18.9-github_v2.img \
    6.18.9-github_v2

# 4. Обновление GRUB
sudo /home/user/soft/kernel-github-action/update_grub_simple.sh
```

---

### ШАГ 5: Перезагрузись

```bash
reboot
```

В меню GRUB выбери **"GitHub 6.18.9-github_v2 (Actions)"**

---

### ШАГ 6: Проверь работу

После загрузки выполни:

```bash
# Версия ядра
uname -r
# Должно быть: 6.18.9-github_v2

# Графика
glxinfo | grep "OpenGL renderer"
# Должно быть: Mesa Intel(R) HD Graphics 405 (BSW)

# Звук
lsmod | grep snd
# Должно быть: snd_hda_intel, snd_hda_codec, etc.

# WiFi
lsmod | grep iwl
# Должно быть: iwlwifi, iwlmvm

# USB
lsusb
# Должен показать устройства
```

---

## 🔧 ВОЗМОЖНЫЕ ПРОБЛЕМЫ И РЕШЕНИЯ

### Проблема 1: Клавиатура/мышь не работают

**Причина:** HID драйверы не загрузились

**Решение:**
```bash
# Пересоздай initramfs с явным указанием модулей
sudo dracut --force --kver 6.18.9-github_v2 \
    --add-drivers "hid-generic hid-apple xhci-hcd xhci-pci" \
    /boot/initramfs-6.18.9-github_v2.img
```

---

### Проблема 2: Нет графики

**Причина:** i915 не загрузился

**Решение:**
```bash
# Проверь загрузку модуля
lsmod | grep i915

# Если пусто - пересоздай initramfs
sudo dracut --force --kver 6.18.9-github_v2 \
    --add-drivers "i915 drm_kms_helper" \
    /boot/initramfs-6.18.9-github_v2.img
```

---

### Проблема 3: Нет звука

**Причина:** Модули snd_hda не в initramfs

**Решение:**
```bash
# Пересоздай initramfs со звуком
sudo dracut --force --kver 6.18.9-github_v2 \
    --add-drivers "snd-hda-core snd-hda-intel snd-hda-codec-realtek" \
    /boot/initramfs-6.18.9-github_v2.img
```

---

### Проблема 4: initramfs слишком большой (>50MB)

**Причина:** Включены лишние модули

**Решение:**
```bash
# Посмотри что внутри
mkdir /tmp/initramfs_check
cd /tmp/initramfs_check
zcat /boot/initramfs-6.18.9-github_v2.img | cpio -idmv 2>&1 | tail -5

# Размер модулей
du -sh lib/modules/6.18.9-github_v2/
```

---

## 📊 ОЖИДАЕМЫЕ РАЗМЕРЫ

| Файл | Ожидаемый размер |
|------|------------------|
| `bzImage` | ~9.5 MB |
| `modules` | ~166 MB |
| `initramfs` | ~20-30 MB |

---

## 🎯 КРИТЕРИИ УСПЕХА

✅ Ядро загружается: `uname -r` показывает `6.18.9-github_v2`
✅ Графика работает: консоль видна, нет ошибок i915
✅ Клавиатура/мышь работают сразу после загрузки
✅ Звук определяется: `aplay -l` показывает устройства
✅ WiFi работает: `iwconfig` показывает беспроводные интерфейсы

---

## 📝 ЗАМЕТКИ

- **initramfs создаётся с помощью dracut** — это стандарт для Calculate Linux
- **Модули копируются напрямую** из артефактов GitHub
- **GRUB обновляется автоматически** через update_grub_simple.sh
- **UUID разделов** уже прописаны в скрипте (проверь свои если отличаются)

---

## 🔗 ССЫЛКИ

- Репозиторий: https://github.com/Galayuda/kernel-build-custom-v2
- Workflow: https://github.com/Galayuda/kernel-build-custom-v2/actions
