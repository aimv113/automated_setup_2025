# Post-reboot instructions

After running the main setup playbook and rebooting, work through this checklist.

Add back up IP route, follow link online and connect with DMB git hub account
```bash
sudo tailscale up
```

## a. Modify ssh standard port in .ssh/config (ON LOCAL MACHINE)
```bash
sudo nano .ssh/config
```

## b. add / update IP in Terminus & key to remote
```bash
ip a
sudo nano ~/.ssh/authorized_keys
```

## c. sanity check ssh config on remote
```bash
sudo nano /etc/ssh/sshd_config
```
---

## 1. Verify playbook

- [ ] Run the verification playbook:

```bash
cd ~/automated_setup_2025
ansible-playbook post-reboot-verify.yml -K
```

**Verification includes:** NVIDIA driver, CUDA toolkit, Docker NVIDIA runtime, PyTorch CUDA support, TensorRT packages, data folders, **networking** (single netplan: DHCP + camera static), and **timezone** (America/Chicago). Machine setup is complete after this playbook.

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

verify with 
```bash
sudo crontab -l
```
(you should see reboot and cron_test.log entries at 0 6,18). To change times, edit with `sudo crontab -e`.

---

## 4. VNC

- [ ] Open and log into the VNC server.

---

## 5. VS Code and Git

- [ ] Install extensions (e.g. Python, Data preview, indent rainbow, rainbow csv).

---


## 6. Touch screen (if applicable)

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

## 7. King_detector setup (crane display)

# Vew instructions at [King codebase](https://github.com/davematthewsband/king_detector/tree/2.9.0)

**Manual steps after the script:**

1. **Rsync models** (from your Mac):  
   `rsync -avz --progress -e "ssh -p 33412" /Volumes/shell/models/current/ lift@<machine>:~/data/models/`
2. **Camera time:** SSH forward camera, open browser, set camera time to match computer:  
   `ssh -p 33412 -L 8080:192.168.1.100:80 lift@<machine>` then open `http://localhost:8080`.

   Make sure timezone of remote machine and camera match (timezone is set by post-reboot-verify).
3. **SSH config:** Add the host to `~/.ssh/config` on your laptop (e.g. `Host Mars2`).
4. **Start crane** (on the machine when ready):  
   `sudo systemctl start crane-display-standalone.service && sudo journalctl -u crane-display-standalone -f`
5. **FFMPEG** :  
   ```bash
   sudo apt update && sudo apt install ffmpeg -y
   ```

---

## 10. Camera settings

- [ ] After king_detector setup (and once camera is reachable): upload/configure camera config. Config file in this repo: `camera-settings/XNZ-L6320AConfigTOBE.bin`. Website/serving is set up manually.

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
