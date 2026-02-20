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
./run-playbook-smart.sh post-reboot-verify.yml
```

**Verification includes:** NVIDIA driver, CUDA toolkit, Docker NVIDIA runtime, PyTorch CUDA support, TensorRT packages, data folders, **networking** (NetworkManager + netplan: DHCP + camera static; optional WiFi), and **timezone** (America/Chicago). Machine setup is complete after this playbook.

**WiFi (connect automatically):** Netplan renderer is set to NetworkManager via **01-network-manager.yaml**. The playbook installs `network-manager`, `rfkill`, and `iw`, unblocks WiFi, enables radio, sets device managed/up, recreates the two NM profiles (no BSSID lock): **OFFICEGST-2.4GHz** (band bg, autoconnect-priority 100) and **OFFICEGST-5GHz** (band a, priority 10), sets open security mode with `wifi-sec.key-mgmt none`, then attempts a non-fatal connect only when SSID is visible. If OFFICEGST is absent the playbook still succeeds and NetworkManager will autoconnect when the network appears. To use a different SSID: `-e "machine_wifi_ssid=OtherNetwork"`.

For dedicated WiFi recovery (smart adapter/kernel detection + interactive strategy confirmation), use: [WIFI_SETUP.md](WIFI_SETUP.md).

**Camera NIC auto-check warning:** `post-reboot-verify.yml` now probes camera reachability at `192.168.1.100`. If no ethernet adapter can reach that target (excluding any adapter that can ping `8.8.8.8`), it logs and prints a warning that manual camera adapter setup is required.

### Network sanity checks (WiFi + camera)

Use this after `post-reboot-verify.yml`. Keep this section check-only; manual recovery commands are in **Appendix A** below.

Set variables first:
```bash
IFACE="wls2"        # replace with your WiFi interface
SSID="OFFICEGST"    # replace if you used a different machine_wifi_ssid
CAM_IFACE="ens3f0"  # replace with your camera ethernet interface
CAM_IP="192.168.1.100"
```

1. Check WiFi radio, device state, and visible networks:
```bash
nmcli radio wifi
nmcli device status
nmcli dev wifi rescan
nmcli -f IN-USE,SSID,BSSID,CHAN,SIGNAL,SECURITY device wifi list | grep -E "^\*|IN-USE|$SSID"
```

2. Check WiFi autoconnect profiles and priority:
```bash
nmcli -f NAME,AUTOCONNECT,AUTOCONNECT-PRIORITY,DEVICE connection show | grep "$SSID"
```

3. Check active WiFi connection and IP:
```bash
nmcli -f GENERAL.STATE,GENERAL.CONNECTION,IP4.ADDRESS dev show "$IFACE"
iw dev "$IFACE" link
```

4. Check camera interface and camera reachability:
```bash
ip -br addr show "$CAM_IFACE"
ping -c 3 -I "$CAM_IFACE" "$CAM_IP"
```

If any check fails, go to **Appendix A. Networking manual fixes**.

---
## 6. Touch screen (if applicable)

- [ ] Verify base touchscreen setup from main playbook:

```bash
dpkg -l | grep -E 'xserver-xorg-input-(libinput|evdev|multitouch)|xinput-calibrator'
ls -l /etc/X11/xorg.conf.d/99-touchscreen.conf
xinput list | grep -i 'egalax\|touch'
```

**If you use server + xinit (no GDM):** Skip the GDM steps (WaylandEnable in `/etc/gdm3/custom.conf` and `sudo systemctl restart gdm`). `/etc/X11/xorg.conf.d/99-touchscreen.conf` is applied when X starts via xinit.

**If you use GDM:** Run `sudo sed -i 's/#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf` and `sudo systemctl restart gdm`.

- [ ] If touch offset is wrong, run calibrator:

```bash
sudo xinput_calibrator
```

Then update calibration values in:
`/etc/X11/xorg.conf.d/99-touchscreen.conf`

- [ ] Validate calibration values:
`xinput list-props "$(xinput list | grep -i 'egalax' | grep -o 'id=[0-9]*' | cut -d= -f2)" | grep -E "Evdev Axis Calibration|Driver"`
- [ ] Run touch test: clone and run [touch-test](https://github.com/aimv113/touch-test/) to confirm touch tracking behavior.

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

---

## Appendix A. Networking manual fixes (only if checks fail)

### A1. WiFi manual reset/recreate (open SSID)

```bash
IFACE="wls2"      # replace with your WiFi interface
SSID="OFFICEGST"  # replace with your SSID

sudo rfkill unblock all
sudo nmcli radio wifi on
sudo ip link set "$IFACE" up
sudo nmcli device set "$IFACE" managed yes

sudo nmcli -t -f NAME connection show | grep -E "^${SSID}" | xargs -r -I{} sudo nmcli connection delete "{}"

sudo nmcli connection add \
  type wifi ifname "$IFACE" \
  con-name "${SSID}-2.4GHz" \
  ssid "$SSID" \
  802-11-wireless.band bg \
  connection.autoconnect yes \
  connection.autoconnect-priority 100 \
  ipv4.method auto \
  ipv6.method auto
sudo nmcli connection modify "${SSID}-2.4GHz" wifi-sec.key-mgmt none

sudo nmcli connection add \
  type wifi ifname "$IFACE" \
  con-name "${SSID}-5GHz" \
  ssid "$SSID" \
  802-11-wireless.band a \
  connection.autoconnect yes \
  connection.autoconnect-priority 10 \
  ipv4.method auto \
  ipv6.method auto
sudo nmcli connection modify "${SSID}-5GHz" wifi-sec.key-mgmt none

sudo nmcli connection up "${SSID}-2.4GHz" || sudo nmcli connection up "${SSID}-5GHz"
```

### A2. Camera NIC manual recovery

```bash
CAM_IP="192.168.1.100"
for i in $(ls /sys/class/net); do
  [ "$i" = "lo" ] && continue
  [ -d "/sys/class/net/$i/wireless" ] && continue
  case "$i" in zt*|tailscale*|docker*|br-*|virbr*|veth*|tun*|tap*|wg*|ppp*) continue ;; esac
  [ -e "/sys/class/net/$i/device" ] || continue
  ping -c 1 -W 2 -I "$i" 8.8.8.8 >/dev/null 2>&1 && continue
  sudo ip link set "$i" up
  sudo ip addr add 192.168.1.254/24 dev "$i" 2>/dev/null || true
  ping -c 1 -W 2 -I "$i" "$CAM_IP" >/dev/null 2>&1 && echo "camera_iface=$i"
  sudo ip addr del 192.168.1.254/24 dev "$i" 2>/dev/null || true
done
```

After finding `camera_iface`, assign camera IP:

```bash
sudo ip addr flush dev <camera_iface>
sudo ip addr add 192.168.1.200/24 dev <camera_iface>
sudo ip link set <camera_iface> up
ping -c 3 -I <camera_iface> 192.168.1.100
```

### A3. Network config file locations

```bash
# Primary files to inspect/edit (50-cloud-init may be absent by design)
ls -l /etc/netplan/01-network-manager.yaml /etc/netplan/99-machine-network.yaml /etc/netplan/50-cloud-init.yaml 2>/dev/null || true

# Current NetworkManager profiles
nmcli -f NAME,UUID,TYPE,DEVICE connection show

# Re-apply the full post-reboot network automation
cd ~/automated_setup_2025
./run-playbook-smart.sh post-reboot-verify.yml -vv
```
