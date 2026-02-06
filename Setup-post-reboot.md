# Post-reboot instructions

After running the main setup playbook and rebooting, work through this checklist.

---

## 1. Verify playbook

- [ ] Run the verification playbook:

```bash
cd ~/automated_setup_2025
ansible-playbook post-reboot-verify.yml -K
```

**Verification includes:** NVIDIA driver, CUDA toolkit, Docker NVIDIA runtime, PyTorch CUDA support, TensorRT packages.

---

## 2. Firefox default browser

- [ ] Set Firefox as default browser:

```bash
xdg-settings set default-web-browser firefox_firefox.desktop
xdg-mime default firefox_firefox.desktop x-scheme-handler/http
xdg-mime default firefox_firefox.desktop x-scheme-handler/https
```

---

## 3. Crontab (scheduled reboots)

Scheduled reboots are via **root crontab** only (the playbook does not install a systemd reboot timer).

- [ ] Edit root crontab: `sudo crontab -e` and add:

```bash
0 6,18 * * * /sbin/reboot
0 6,18 * * * echo "Cron executed at $(date)" >> /var/log/cron_test.log
```

(Reboots at 06:00 and 18:00; the second line logs that cron ran.)

---

## 4. VNC

- [ ] Open and log into the VNC server.

---

## 5. VS Code and Git

- [ ] Open VS Code and log into Git online.
- [ ] Install extensions (e.g. Python, Data preview, indent rainbow, rainbow csv).

---

## 6. Clone repo

- [ ] Clone your app repo(s) if different from the setup repo (e.g. `~/code/king_detector`). The playbook configures Git with SSH for GitHub and creates a key you added to GitHub, so you can pull/push via SSH.

---

## 7. Data folders

- [ ] Data folders (`data/`, `data/jpg/`, `data/video/`, `data/jpg/no_hook`, `data/jpg/no_overlay`) are created by default in your home directory (`~/data` next to `~/code`) by the playbook and/or post-reboot-verify. If you use a different path (set `app_data_path`), create them manually:

```bash
mkdir -p ~/code/king_detector/data/jpg/no_hook ~/code/king_detector/data/jpg/no_overlay ~/code/king_detector/data/video
```

---

## 8. Python venv

- [ ] Set up project venv if needed, e.g.:

```bash
python -m pip install --upgrade pip setuptools wheel
pip install ultralytics tensorrt==10.13.3.9 onnxruntime-gpu==1.23.2 cvzone onvif_zeep
```

(ML environment is already at `~/code/auto_test`; activate with `source ~/code/auto_test/activate.sh`.)

---

## 9. rev4.3 / tensor-check

- [ ] In your app repo (e.g. rev4.3): run `tests/tensorRT/tensor-check.py` or equivalent.

---

## 10. fwupd popup fix

- [ ] Disable fwupd refresh to avoid the Apport crash popup (optional):

```bash
sudo systemctl disable --now fwupd-refresh.service fwupd-refresh.timer
```

---

## 11. Touch screen (if applicable)

- [ ] Install packages and add Xorg config:

```bash
sudo apt update
sudo apt install xserver-xorg-input-libinput xserver-xorg-input-evdev xserver-xorg-input-multitouch xinput-calibrator -y
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/99-touchscreen.conf > /dev/null <<'EOF'
Section "InputClass"
    Identifier "Touchscreen"
    MatchProduct "eGalax Inc. USB TouchController"
    MatchDevicePath "/dev/input/event*"
    Driver "evdev"
    Option "Calibration" "0 4095 0 4095"
    Option "InvertX" "0"
    Option "InvertY" "0"
EndSection
EOF
```

**If you use server + xinit (no GDM):** Skip the GDM steps (WaylandEnable in `/etc/gdm3/custom.conf` and `sudo systemctl restart gdm`). The config above is applied when X starts via xinit.

**If you use GDM:** Run `sudo sed -i 's/#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf` and `sudo systemctl restart gdm`.

- [ ] Verify: `xinput list-props "$(xinput list | grep -i 'egalax' | grep -o 'id=[0-9]*' | cut -d= -f2)" | grep -E "Evdev Axis Calibration|Driver"`

---

## 12. Camera settings

- [ ] Upload/configure camera config for the device. Config file in this repo: `camera-settings/XNZ-L6320AConfigTOBE.bin`. Website/serving is set up manually.

---

## Boot mode: minimal X / king_detector

If you chose **minimal X** at playbook start, the playbook installed `xdotool` and `x11-xserver-utils`. Your crane-display service and scripts live in the king_detector repo (not in this repo). See SETUP_WORKFLOW.md for the full flow and both paths (GNOME on boot vs minimal X).
