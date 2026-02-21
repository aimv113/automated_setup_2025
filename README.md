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
./run-playbook-smart.sh ubuntu-setup.yml
```

See [Install-system.md](Install-system.md) for pre-requisites (Ubuntu install, SSH access).

**Two-pass run on fresh machines:**
1. Pass 1 installs/pins the HWE kernel baseline (`6.17.0-14-generic`) and exits if a reboot is needed.
2. Reboot, then run the same command again. Playbook prompts for WiFi strategy, boot mode, Git identity, and Healthchecks URL; then runs the full setup.

After setup completes, reboot and run the verification playbook:

```bash
sudo reboot
./run-playbook-smart.sh post-reboot-verify.yml
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

WiFi strategy is chosen at playbook start:
1. HWE kernel update path (recommended for RTL8812AU)
2. DKMS path for RTL8812AU (`morrownr/8812au-20210820`)
3. Native Linux in-kernel driver
4. Manual / skip

`post-reboot-verify.yml` configures NetworkManager + netplan: DHCP on the internet NIC, static `192.168.1.200` on the camera NIC, and two WiFi profiles (`OFFICEGST-2.4GHz` priority 100, `OFFICEGST-5GHz` priority 10). Override SSID with `-e "machine_wifi_ssid=OtherNetwork"`.

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
