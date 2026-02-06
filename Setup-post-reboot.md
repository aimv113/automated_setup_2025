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

The main playbook (**ubuntu-setup.yml**) installs root cron entries for reboots at **06:00 and 18:00** and a log line. No manual edit needed unless you want to change the schedule.

- [ ] Optional: verify with `sudo crontab -l` (you should see reboot and cron_test.log entries at 0 6,18). To change times, edit with `sudo crontab -e`.

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

Data folders are created **automatically** by the main playbook (**ubuntu-setup.yml**) and ensured by **post-reboot-verify.yml** in the **root of your home directory**: `~/data`, `~/data/jpg`, `~/data/video`, `~/data/jpg/no_hook`, `~/data/jpg/no_overlay` (so `~/data` sits next to `~/code`). No manual step needed for the default path.

- [ ] Optional: verify with `ls ~/data` (you should see `jpg`, `video`; under `jpg`: `no_hook`, `no_overlay`). Only if you overrode `app_data_path` during setup, create the same structure under that path, e.g. `mkdir -p ~/data/jpg/no_hook ~/data/jpg/no_overlay ~/data/video`.

---

## 8. Touch screen (if applicable)

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

## 9. App deploy (king_detector)

Run this **only after** `post-reboot-verify.yml` has passed. It deploys king_detector and prepares the machine for the crane display.

- [ ] Run from anywhere (use the path where you cloned the repo):

```bash
ansible-playbook ~/automated_setup_2025/app-deploy.yml -K -vv
```

**Prompts:** You will be asked for the **build version** (branch, e.g. `2.9.0`) and **machine name** (e.g. `Mars2`).

**What it does:** Installs `xdotool` and `x11-xserver-utils`; detects ethernet interfaces with no internet and sets static IPs (192.168.1.200, 192.168.1.201, …) for camera links; clones king_detector from GitHub at the requested branch into `~/code/king_detector`; creates `.env` from the repo’s `admin/env-file.md` (machine name substituted); ensures `~/data` and `~/data/models`; creates venv and installs from `requirementsAutoUbuntu24cuda13.txt`; installs and enables `crane-display-standalone.service`, sets multi-user default, disables GDM; sets timezone to America/Chicago; prints the manual steps below.

**Prerequisites:** GitHub SSH working for user `lift` (e.g. `ssh-add` run for the GitHub key) so the clone succeeds.

**Manual steps after the playbook:**

1. **Rsync models** (from your Mac):  
   `rsync -avz --progress -e "ssh -p 33412" /Volumes/shell/models/current/ lift@<machine>:~/data/models/`
2. **Camera time:** SSH forward camera, open browser, set camera time to match computer:  
   `ssh -p 33412 -L 8080:192.168.1.100:80 lift@<machine>` then open `http://localhost:8080`.

MAKE SURE TO CHECK TIMEZONE OF REMOTE MACHINE AND CAMERA MATCH
   
4. **SSH config:** Add the host to `~/.ssh/config` on your laptop (e.g. `Host Mars2`).
5. **Start crane** (on the machine when ready):  
   `sudo systemctl start crane-display-standalone.service && sudo journalctl -u crane-display-standalone -f`

---

## 10. Camera settings

- [ ] After app deploy (and once camera is reachable): upload/configure camera config. Config file in this repo: `camera-settings/XNZ-L6320AConfigTOBE.bin`. Website/serving is set up manually.

---

## 11. rev4.3 / tensor-check

- [ ] In your app repo (e.g. rev4.3): run `tests/tensorRT/tensor-check.py` or equivalent.

---

## 12. fwupd popup fix

- [ ] Disable fwupd refresh to avoid the Apport crash popup (optional):

```bash
sudo systemctl disable --now fwupd-refresh.service fwupd-refresh.timer
```

---

## Boot mode: minimal X / king_detector

If you chose **minimal X** at playbook start, the playbook installed `xdotool` and `x11-xserver-utils`. Your crane-display service and scripts live in the king_detector repo (not in this repo). See SETUP_WORKFLOW.md for the full flow and both paths (GNOME on boot vs minimal X).
