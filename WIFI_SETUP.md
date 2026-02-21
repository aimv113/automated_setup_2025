# WiFi setup and recovery

Use this page when WiFi did not come up during the normal setup flow and you want a dedicated, smart recovery run.

The standard/default flow remains unchanged:
- `ubuntu-setup.yml` still handles the main WiFi readiness policy.
- `post-reboot-verify.yml` still applies NetworkManager + netplan + WiFi profiles in the standard post-boot path.

This playbook is an additional fallback path only.

---

## When to run this

Run this if either is true:
- WiFi was skipped intentionally in a first pass and now needs setup.
- WiFi policy/setup in the main flow did not produce a working wireless interface.

Run from repo root:

```bash
ansible-playbook wifi-recovery.yml -K
```

Use `-v` only if you need extra debugging detail.

---

## What it detects automatically

`wifi-recovery.yml` performs hardware and kernel detection before applying changes:
- USB adapter detection (`lsusb`), including Realtek RTL8812AU/8821AU family (`0bda:8812`, `0bda:0811`, and `8812au/8821au` signatures)
- PCIe wireless adapter detection (`lspci`)
- Loaded wireless modules (`lsmod`)
- Active wireless interfaces (`/sys/class/net/*/wireless`)
- Running kernel check (native RTL8812AU support threshold at kernel `>= 6.13`)
- Standard kernel candidate check (`linux-generic` installed vs candidate in apt)

It then proposes a recommended strategy and asks for confirmation.
Before execution, it prints the exact action plan for the selected strategy and requires confirmation (`YES`) before continuing.

---

## Strategy options (interactive)

The playbook prompts with:
1. Apply recommended strategy
2. Force native/in-kernel path
3. Force DKMS path (RTL8812AU only)
4. Install HWE kernel baseline (reboot required)
5. Abort
6. Install newer standard kernel baseline (`linux-generic`) when available

### Recommendation logic summary
- RTL8812AU/8821AU family present + active wireless interface -> prefer native path
- RTL8812AU/8821AU family present + no interface and kernel `>= 6.13` -> try native path first
- RTL8812AU/8821AU family present + no interface and kernel `< 6.13` -> recommend DKMS path
- Other adapter + wireless interface already present -> native path
- No adapter detected -> stop and report

---

## Non-interactive usage

You can preselect behavior with vars:

```bash
ansible-playbook wifi-recovery.yml -K \
  -e "wifi_interactive=false wifi_strategy_selection=recommended machine_wifi_ssid=OFFICEGST"
```

Allowed `wifi_strategy_selection` values:
- `recommended`
- `native`
- `dkms`
- `hwe_kernel`
- `standard_kernel`
- `abort`

Optional secure SSID example:

```bash
ansible-playbook wifi-recovery.yml -K \
  -e "machine_wifi_ssid=MySSID machine_wifi_psk=MyPassword"
```

If `machine_wifi_psk` is empty, playbook configures open-network profiles.

---

## What it configures

After strategy confirmation, the playbook:
- Ensures NetworkManager/rfkill/iw and support tools are installed
- Brings WiFi radio/interface under NetworkManager control
- Creates/aligns two WiFi profiles:
  - `<SSID>-2.4GHz` (`bg`, autoconnect-priority `100`)
  - `<SSID>-5GHz` (`a`, autoconnect-priority `10`)
- Clears security fields for open networks, or sets WPA-PSK when `machine_wifi_psk` is provided
- Attempts connection when SSID is visible

---

## Validation commands

After run, validate with:

```bash
nmcli device status
nmcli -f GENERAL.STATE,GENERAL.CONNECTION,IP4.ADDRESS dev show <wifi_iface>
iw dev <wifi_iface> link
```

---

## Notes

- HWE kernel path installs HWE meta packages and exits with reboot instructions.
- Standard kernel path installs `linux-generic` + `linux-headers-generic` when a newer candidate exists and exits with reboot instructions.
- DKMS path is implemented here for RTL8812AU only.
- Log file location: `/var/log/ansible-wifi-recovery-<timestamp>.log`.

---

## Manual networking fixes (post-setup recovery)

Use these if `post-reboot-verify.yml` ran but WiFi or the camera NIC are not working.

### WiFi: manual reset / recreate profile (open SSID)

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

### Camera NIC: find and assign static IP

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

After finding `camera_iface`, persist with netplan:

```bash
CAM_IFACE="ens3f0"          # camera interface found above
INTERNET_IFACE="ens21f0"    # internet interface

sudo ip addr flush dev "$CAM_IFACE"
sudo ip addr add 192.168.1.200/24 dev "$CAM_IFACE"
sudo ip link set "$CAM_IFACE" up
ping -c 3 -I "$CAM_IFACE" 192.168.1.100

sudo tee /etc/netplan/99-machine-network.yaml > /dev/null <<EOF
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    ${INTERNET_IFACE}:
      dhcp4: true
    ${CAM_IFACE}:
      dhcp4: false
      addresses:
        - 192.168.1.200/24
      optional: true
EOF

sudo netplan generate && sudo netplan apply
sleep 2
ip -br addr show "$CAM_IFACE"
ping -c 3 -I "$CAM_IFACE" 192.168.1.100
```

### Network config file locations

```bash
ls -l /etc/netplan/01-network-manager.yaml /etc/netplan/99-machine-network.yaml /etc/netplan/50-cloud-init.yaml 2>/dev/null || true
nmcli -f NAME,UUID,TYPE,DEVICE connection show
ansible-playbook post-reboot-verify.yml -K -vv
```
