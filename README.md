# Linux Kernel 6.18.9-custom_v2 Build

Автоматическая сборка ядра Linux через GitHub Actions.

## 📦 Что здесь

- **Workflow**: `.github/workflows/kernel-build.yml` — конфигурация GitHub Actions
- **Config**: `config_core` — конфигурация ядра 6.18.9-custom_v2

## 🚀 Как запустить сборку

### 1. Push в GitHub

```bash
cd /home/user/soft/kernel-github-action
git init
git add .
git commit -m "Initial commit: kernel 6.18.9-custom_v2 build"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

### 2. Запустить Actions

1. Открой репозиторий на GitHub
2. Перейди на вкладку **Actions**
3. Выбери **"Build Linux Kernel 6.18.9-custom_v2"**
4. Нажми **"Run workflow"**
5. Жди ~30-60 минут

### 3. Скачать результат

После завершения:
- В разделе **Artifacts** скачай:
  - `bzImage-6.18.9` — образ ядра
  - `config-6.18.9` — конфигурация
  - `modules-6.18.9` — модули

## 📊 Характеристики сборки

| Параметр | Значение |
|----------|----------|
| **Версия ядра** | 6.18.9 |
| **Конфигурация** | custom_v2 (-45% опций) |
| **Время сборки** | ~30-60 минут |
| **Ресурсы GitHub** | 2 CPU, 7 GB RAM |
| **Лимит** | 2000 минут/месяц |

## 🔧 Локальная сборка (альтернатива)

```bash
cd /usr/src/linux-6.18.9-custom_v2
make -j4 bzImage modules
```

## 📝 Оптимизации custom_v2

Отключено:
- ❌ AMD/NVIDIA GPU
- ❌ KVM/XEN виртуализация
- ❌ Bluetooth
- ❌ IPv6
- ❌ Btrfs/XFS
- ❌ Netfilter (iptables)
- ❌ NVMe (нет NVMe дисков)
- ❌ Thunderbolt
- ❌ RAID/DM
- ❌ NLS кодировки (только UTF-8)

Включено:
- ✅ WiFi IWLWIFI (Intel)
- ✅ Звук HDA (Realtek + HDMI)
- ✅ Intel GPU I915
- ✅ USB XHCI/HID
- ✅ EXT4

## ⚠️ Примечания

- Репозиторий **публичный** — конфиг виден всем
- Артефакты хранятся **30 дней**
- Для приватного репозитория: 2000 минут/месяц лимит

## 🔗 Ссылки

- [Документация GitHub Actions](https://docs.github.com/en/actions)
- [Linux Kernel Documentation](https://www.kernel.org/doc/html/latest/)
