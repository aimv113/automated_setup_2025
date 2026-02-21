# Post-reboot checklist

Work through this after the main setup playbook has run and the machine has rebooted.

---

## 1. Tailscale

Connect to the VPN so the machine is reachable remotely:

```bash
sudo tailscale up
```

Add route back IP if needed and approve in the Tailscale admin console.

---

## 2. Update local SSH config (on your Mac)

```bash
nano ~/.ssh/config
```

Add or update the host entry with the correct IP and port 33412. Then clear any stale host key:

```bash
ssh-keygen -R <machine-ip>
```

Update the host in Terminus with the new IP and verify the SSH key is in place on the remote.

---

## 3. Run the verification playbook

```bash
cd ~/automated_setup_2025
sudo apt update
ansible-playbook post-reboot-verify.yml
```

**What this does:** verifies NVIDIA driver, CUDA, Docker GPU runtime, PyTorch CUDA support, TensorRT packages, data folders, networking (NetworkManager + netplan: DHCP + camera static; optional WiFi), and timezone (America/Chicago).

**Machine setup is complete after this playbook passes.**

After it runs, do a quick network sanity check:

```bash
IFACE="wls2"          # your WiFi interface
SSID="OFFICEGST"
CAM_IFACE="ens3f0"    # your camera ethernet interface

nmcli radio wifi
nmcli device status
nmcli -f IN-USE,SSID,CHAN,SIGNAL device wifi list | grep "$SSID"
nmcli -f NAME,AUTOCONNECT,AUTOCONNECT-PRIORITY,DEVICE connection show | grep "$SSID"
ip -br addr show "$CAM_IFACE"
ping -c 3 -I "$CAM_IFACE" 192.168.1.100
```

If anything fails see [WIFI_SETUP.md](WIFI_SETUP.md) for manual recovery commands.

---

## 4. Touch screen (if applicable)

Verify setup:

```bash
dpkg -l | grep -E 'xserver-xorg-input-(libinput|evdev|multitouch)|xinput-calibrator'
ls -l /etc/X11/xorg.conf.d/99-touchscreen.conf
xinput list | grep -i 'egalax\|touch'
```

If using GDM: `sudo sed -i 's/#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf && sudo systemctl restart gdm`

If touch offset is wrong, run calibrator and update values in `/etc/X11/xorg.conf.d/99-touchscreen.conf`:

```bash
sudo xinput_calibrator
```

---

## 5. King_detector setup (crane display)

Follow instructions at the [king_detector repo](https://github.com/davematthewsband/king_detector/tree/2.9.0).

**Manual steps after the setup script:**

1. **Rsync models** from your Mac:
   ```bash
   rsync -avz --progress -e "ssh -p 33412" /Volumes/shell/models/current/ lift@<machine>:/data/models/
   ```

2. **Set camera time:** SSH-forward the camera web UI, then match the camera clock to the machine:
   ```bash
   ssh -p 33412 -L 8080:192.168.1.100:80 lift@<machine>
   # open http://localhost:8080 and set clock
   ```

3. **SSH config:** Add the host to `~/.ssh/config` on your Mac (e.g. `Host Mars2`).

4. **Start crane display:**
   ```bash
   sudo systemctl start crane-display-standalone.service
   sudo journalctl -u crane-display-standalone -f
   ```

5. **Install ffmpeg:**
   ```bash
   sudo apt update && sudo apt install ffmpeg -y
   ```

---

## 6. Camera settings

Upload the camera config file once the camera is reachable:

- Config file in this repo: `camera-settings/XNZ-L6320AConfigTOBE.bin`
- Access via the SSH-forwarded camera web UI (see step 5 above).

---

## 7. TensorRT check

In your app repo (e.g. rev4.3): run `tests/tensorRT/tensor-check.py` or equivalent.

---

## 8. fwupd popup fix (optional)

Disable fwupd to avoid the Apport crash popup:

```bash
sudo systemctl disable --now fwupd-refresh.service fwupd-refresh.timer
```

---

## Boot mode note

If **minimal X / king_detector** boot mode was selected at playbook start, the machine boots to server (no GNOME). The crane-display service starts via xinit from the king_detector repo. `xdotool` and `x11-xserver-utils` are already installed by the playbook.
