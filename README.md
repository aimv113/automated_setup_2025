# Automated Setup 2025

Automated Ubuntu 24.04 setup with NVIDIA GPU support, CUDA, TensorRT, Docker, ML environment, and monitoring. Designed for the crane-detection hardware (bare metal, NVIDIA GPU, eGalax touchscreen, camera NIC).

For the full step-by-step setup flow see **[SETUP_WORKFLOW.md](SETUP_WORKFLOW.md)**.

---

## Quick start

```bash
# On the target machine:
sudo apt update && sudo apt install ansible git -y
git clone https://github.com/aimv113/automated_setup_2025.git
cd automated_setup_2025
ansible-playbook ubuntu-setup.yml -K
```

See [Install-system.md](Install-system.md) for pre-requisites (Ubuntu install, SSH access).

**Standard run (single pass):**
The playbook prompts for WiFi strategy (press Enter for option 1: standard in-kernel drivers), boot mode, Git identity, and Healthchecks URL; then runs the full setup. If the sudo password prompt (`BECOME password:`) appears, enter it once — it's cached for the rest of the run.

**If you need the HWE kernel (option 3 at the WiFi prompt — advanced, RTL8812AU only):**
Pass 1 installs kernel 6.17 and exits for a reboot. Reboot (`sudo reboot`), then run the playbook again to continue.

After setup completes, reboot and run the verification playbook:

```bash
sudo reboot
ansible-playbook post-reboot-verify.yml -K
```

Post-reboot steps (Tailscale, king_detector setup, camera settings) are in [Setup-post-reboot.md](Setup-post-reboot.md).

---

## What gets installed

### GPU stack (version-locked)

| Component | Version | Method |
|-----------|---------|--------|
| NVIDIA Driver | 580.95.05 | Local `.deb` repository |
| CUDA Toolkit | 13.0.2 | Local `.deb` repository |
| TensorRT | 10.13.3 | Local `.deb` repository |
| PyTorch | Latest cu130 | pip (Python venv) |

**Version protection (4 layers):**
1. Local installers cached in `/opt/installers/` — immune to upstream removal, enables offline rebuilds
2. `dpkg hold` on ~44 packages — `apt upgrade` will never touch the GPU stack
3. Unattended-upgrades blacklist (`/etc/apt/apt.conf.d/51nvidia-blacklist`)
4. APT preferences with Pin-Priority 1001

To update any version, update `vars/common.yml` and the related URLs in `ubuntu-setup.yml` together. See [REPRODUCIBILITY_STRATEGY.md](detailed%20creation%20docs/REPRODUCIBILITY_STRATEGY.md) for full details.

### Additional components

| Component | Notes |
|-----------|-------|
| Docker + NVIDIA Container Toolkit | GPU-enabled containers |
| Tailscale VPN | Installed; `sudo tailscale up` to activate |
| RealVNC Server | Version 7.13.0 |
| VS Code | Latest from Microsoft repository |
| Python 3.12 venv | At `~/code/auto_test` — PyTorch, Ultralytics, TensorRT, ONNX Runtime GPU |
| SSH | Port 33412, key-only (keys from `ssh-public-keys.txt`) |
| UFW firewall | Configured for SSH port + standard services |
| Scheduled reboots | 06:00 and 18:00 via root cron |
| Healthchecks.io | Optional — prompted during setup |
| Touchscreen | eGalax USB — detected via lsusb, prompted if not found |

### VM vs bare metal

Playbook detects virtualisation with `systemd-detect-virt`:
- **Bare metal:** Full NVIDIA display stack (Xorg, KMS, Wayland disabled)
- **VM:** QXL display driver, NVIDIA GPU compute only (no display conflicts)

### WiFi

WiFi strategy is chosen at playbook start (press Enter for option 1):
1. Standard — use existing in-kernel drivers, check WiFi and ethernet  [default]
2. DKMS path for RTL8812AU (`morrownr/8812au-20210820`)
3. HWE kernel — install/pin kernel 6.17 (advanced, RTL8812AU only)
4. Manual / skip

`post-reboot-verify.yml` configures NetworkManager + netplan: DHCP on the internet NIC, static `192.168.1.200` on `camera_expected_interface` (default `ens3f0`), and two WiFi profiles (`OFFICEGST-2.4GHz` priority 100, `OFFICEGST-5GHz` priority 10). If that interface is unavailable, it falls back to camera auto-detection. Override SSID with `-e "machine_wifi_ssid=OtherNetwork"` and camera NIC with `-e "camera_expected_interface=enp3s0"`.

For WiFi recovery after setup see [WIFI_SETUP.md](WIFI_SETUP.md).

---

## SSH keys

The playbook deploys keys from `ssh-public-keys.txt` to `~/.ssh/authorized_keys`. Ensure this file contains the public keys you want before running.

---

## Verification commands

```bash
nvidia-smi
nvcc --version
docker run --rm --gpus all nvidia/cuda:13.0.2-base-ubuntu24.04 nvidia-smi

source ~/code/auto_test/activate.sh
python3 -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"

dpkg --get-selections | grep hold | grep -E 'nvidia|cuda|tensorrt'
```
