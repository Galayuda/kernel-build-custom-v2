# ⚡ БЫСТРЫЙ СТАРТ — Установка ядра из GitHub Actions

## 1️⃣ Запусти сборку

https://github.com/Galayuda/kernel-build-custom-v2/actions

- Выбери **"Build Linux Kernel 6.18.9-custom_v2"**
- Нажми **"Run workflow"**
- Config type: **`custom`** ✅
- Жди ~36 минут

---

## 2️⃣ Скачай артефакты

```bash
cd /home/user/soft/kernel-github-action
./download_artifacts.sh
```

Или вручную через браузер на GitHub.

---

## 3️⃣ Установи ядро

```bash
sudo ./install_kernel_github.sh /tmp/kernel_github
```

---

## 4️⃣ Перезагрузись

```bash
reboot
```

Выбери **"GitHub 6.18.9-github_v2 (Actions)"** в GRUB.

---

## 5️⃣ Проверь

```bash
uname -r              # Должно быть: 6.18.9-github_v2
glxinfo | grep renderer  # Графика Intel
lsmod | grep snd      # Звук
lsmod | grep iwl      # WiFi
lsusb                 # USB устройства
```

---

## ✅ ВСЁ РАБОТАЕТ?

- ✅ Клавиатура/мышь работают сразу
- ✅ Графика видна на консоли
- ✅ Звук определяется
- ✅ WiFi подключается

**Поздравляю! Ядро работает!** 🎉

---

## ❌ ЧТО-ТО НЕ ТАК?

Смотри **INSTALL_GUIDE.md** — там подробные решения проблем.
