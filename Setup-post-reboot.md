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

**Verification includes:** NVIDIA driver, CUDA toolkit, Docker NVIDIA runtime, PyTorch CUDA support, TensorRT packages, data folders, **networking** (NetworkManager + netplan: DHCP + camera static; optional WiFi), and **timezone** (America/Chicago). Machine setup is complete after this playbook.

**WiFi (connect automatically):** Netplan renderer is set to NetworkManager via **01-network-manager.yaml**. The playbook installs `network-manager`, `rfkill`, and `iw`, then creates two NM profiles (no BSSID lock): **OFFICEGST-2.4GHz** (band bg, autoconnect-priority 100) and **OFFICEGST-5GHz** (band a, priority 10). For open SSIDs, security fields are cleared (no password/key-mgmt values). It also enables WiFi radio, sets the device managed/up, and attempts non-fatal connect only when SSID is visible. If OFFICEGST is absent the playbook still succeeds and NetworkManager will autoconnect when the network appears. To use a different SSID: `-e "machine_wifi_ssid=OtherNetwork"`.

**Camera NIC auto-check warning:** `post-reboot-verify.yml` now probes camera reachability at `192.168.1.100`. If no ethernet adapter can reach that target (excluding any adapter that can ping `8.8.8.8`), it logs and prints a warning that manual camera adapter setup is required.

### WiFi verification and troubleshooting (terminal-first)

Use this after `post-reboot-verify.yml` if WiFi does not come up immediately.

1. Confirm tools and interface:
```bash
which nmcli rfkill iw
ip -br link
iw dev
```

2. Check soft/hard block and radio state:
```bash
rfkill list
nmcli radio all
```

3. If blocked/down, un-block and bring device up:
```bash
sudo rfkill unblock all
nmcli radio wifi on
sudo ip link set <wifi_iface> up
nmcli device set <wifi_iface> managed yes
nmcli device connect <wifi_iface>
```

4. Scan and confirm the expected SSID is visible:
```bash
nmcli dev wifi rescan
nmcli -f IN-USE,SSID,BSSID,CHAN,SIGNAL,SECURITY device wifi list | grep -E '^\*|IN-USE|OFFICEGST'
```

5. Validate open-network profile settings (no security fields, no BSSID pin):
```bash
nmcli -f connection.id,802-11-wireless.ssid,802-11-wireless.band,802-11-wireless.bssid,802-11-wireless-security.key-mgmt,802-11-wireless-security.psk connection show "OFFICEGST-2.4GHz"
nmcli -f connection.id,802-11-wireless.ssid,802-11-wireless.band,802-11-wireless.bssid,802-11-wireless-security.key-mgmt,802-11-wireless-security.psk connection show "OFFICEGST-5GHz"
```

6. If old/incorrect profiles exist, recreate clean open-network profiles:
```bash
IFACE="<wifi_iface>"
SSID="OFFICEGST"
nmcli -t -f NAME connection show | grep -qx "${SSID}-2.4GHz" && nmcli connection delete "${SSID}-2.4GHz" || true
nmcli -t -f NAME connection show | grep -qx "${SSID}-5GHz" && nmcli connection delete "${SSID}-5GHz" || true
nmcli -t -f NAME connection show | grep -qx "${SSID}" && nmcli connection delete "${SSID}" || true
nmcli connection add type wifi ifname "${IFACE}" con-name "${SSID}-2.4GHz" ssid "${SSID}" 802-11-wireless.band bg connection.autoconnect yes connection.autoconnect-priority 100 ipv4.method auto ipv6.method auto
nmcli connection add type wifi ifname "${IFACE}" con-name "${SSID}-5GHz" ssid "${SSID}" 802-11-wireless.band a connection.autoconnect yes connection.autoconnect-priority 10 ipv4.method auto ipv6.method auto
nmcli connection modify "${SSID}-2.4GHz" 802-11-wireless-security.key-mgmt "" 802-11-wireless-security.psk ""
nmcli connection modify "${SSID}-5GHz" 802-11-wireless-security.key-mgmt "" 802-11-wireless-security.psk ""
nmcli connection up "${SSID}-2.4GHz" || nmcli connection up "${SSID}-5GHz"
```

7. Confirm link + IP + route:
```bash
iw dev <wifi_iface> link
ip a show <wifi_iface>
ip route
```

8. Quick failure triage if still not connected:
```bash
nmcli device status
nmcli -f GENERAL.STATE,GENERAL.CONNECTION,IP4.ADDRESS dev show <wifi_iface>
sudo journalctl -u NetworkManager -b --no-pager | tail -n 120
sudo journalctl -k -b --no-pager | grep -Ei 'wlan|wifi|rfkill|firmware|8812|88..au|rtw88|usb' | tail -n 150
```

---

## 1b. Camera interface manual recovery (only if warning appears)

Use this when `post-reboot-verify.yml` reports camera probe failure (`192.168.1.100 unreachable`).

1. List ethernet interfaces:
```bash
ip -br link
```

2. Exclude internet-connected interfaces (leave these untouched):
```bash
for i in $(ls /sys/class/net); do
  [ "$i" = "lo" ] && continue
  [ -d "/sys/class/net/$i/wireless" ] && continue
  case "$i" in zt*|tailscale*|docker*|br-*|virbr*|veth*|tun*|tap*|wg*|ppp*) continue ;; esac
  [ -e "/sys/class/net/$i/device" ] || continue
  ping -c 1 -W 2 -I "$i" 8.8.8.8 >/dev/null 2>&1 && echo "$i has internet (skip)"
done
```

3. Probe remaining ethernet interfaces for camera reachability:
```bash
for i in $(ls /sys/class/net); do
  [ "$i" = "lo" ] && continue
  [ -d "/sys/class/net/$i/wireless" ] && continue
  case "$i" in zt*|tailscale*|docker*|br-*|virbr*|veth*|tun*|tap*|wg*|ppp*) continue ;; esac
  [ -e "/sys/class/net/$i/device" ] || continue
  ping -c 1 -W 2 -I "$i" 8.8.8.8 >/dev/null 2>&1 && continue
  sudo ip link set "$i" up
  sudo ip addr add 192.168.1.254/24 dev "$i" 2>/dev/null || true
  if ping -c 1 -W 2 -I "$i" 192.168.1.100 >/dev/null 2>&1; then
    echo "camera_iface=$i"
  fi
  sudo ip addr del 192.168.1.254/24 dev "$i" 2>/dev/null || true
done
```

4. Assign camera static IP on the found interface (replace `<camera_iface>`):
```bash
sudo ip addr flush dev <camera_iface>
sudo ip addr add 192.168.1.200/24 dev <camera_iface>
sudo ip link set <camera_iface> up
ping -c 3 -I <camera_iface> 192.168.1.100
```

5. Persist in netplan (`/etc/netplan/99-machine-network.yaml`), then apply:
```bash
sudo nano /etc/netplan/99-machine-network.yaml
sudo netplan generate && sudo netplan apply
```

6. Re-run verification playbook:
```bash
cd ~/automated_setup_2025
ansible-playbook post-reboot-verify.yml -K -vv
```

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
   ```bash
   rsync -avz --progress -e "ssh -p 33412" /Volumes/shell/models/current/ lift@<machine>:/data/models/
   ```
2. **Camera time:** SSH forward camera, open browser, set camera time to match computer:  
   ```bash
   ssh -p 33412 -L 8080:192.168.1.100:80 lift@<machine>
   ```
   then open `http://localhost:8080`. Make sure timezone of remote machine and camera match (timezone is set by post-reboot-verify).
3. **SSH config:** Add the host to `~/.ssh/config` on your laptop (e.g. `Host Mars2`).
4. **Start crane** (on the machine when ready):
   ```bash
   sudo systemctl start crane-display-standalone.service && sudo journalctl -u crane-display-standalone -f
   ```
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
