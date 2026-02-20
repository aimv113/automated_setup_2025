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
./run-playbook-smart.sh wifi-recovery.yml
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
./run-playbook-smart.sh wifi-recovery.yml \
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
./run-playbook-smart.sh wifi-recovery.yml \
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
