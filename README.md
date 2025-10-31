# Automated Setup 2025

## Initial Ubuntu 24.04.3 Setup

### 1. Configure SSH Service

```bash
sudo systemctl start ssh
sudo systemctl enable ssh
```

Get remote IP address:
```bash
hostname -I
```

Ssh into remote machine
```bash
ssh lift@ip address
```


After setting up remote machine and successful ssh connection and key from local machine is sent, lock it down
```bash
sudo ufw allow 33412/tcp && \
if systemctl list-unit-files | grep -q '^ssh.socket'; then \
  sudo systemctl disable --now ssh.socket && \
  sudo systemctl mask ssh.socket && \
  sudo systemctl enable --now ssh.service; \
fi && \
sudo sed -i '/^\s*Port\s\+[0-9]\+/d' /etc/ssh/sshd_config && \
sudo sed -i '1i Port 33412' /etc/ssh/sshd_config && \
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
sudo sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config && \
sudo sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
sudo systemctl daemon-reload && \
sudo systemctl restart ssh && \
sudo systemctl status ssh --no-pager

```

install lightweight desktop
```bash
sudo apt install --no-install-recommends xubuntu-desktop -y
```

Dummy driver for virtual monitor
```bash
sudo apt install -y xserver-xorg-video-dummy && sudo mkdir -p /etc/X11/xorg.conf.d && sudo tee /etc/X11/xorg.conf.d/10-dummy.conf > /dev/null <<'EOF'
Section "Device"
  Identifier "DummyGPU"
  Driver "dummy"
  VideoRam 256000
EndSection

Section "Monitor"
  Identifier "VirtualMonitor"
  HorizSync 28-80
  VertRefresh 48-75
  Modeline "1920x1080" 172.80 1920 2040 2248 2576 1080 1083 1088 1120
EndSection

Section "Screen"
  Identifier "Screen0"
  Device "DummyGPU"
  Monitor "VirtualMonitor"
  DefaultDepth 24
  SubSection "Display"
    Depth 24
    Modes "1920x1080"
  EndSubSection
EndSection
EOF
```


### 1. Update System and Install Required Packages, Clone Repository and Run Setup

```bash
sudo apt update
sudo apt install openssh-server ansible git -y
git clone https://github.com/aimv113/automated_setup_2025.git
cd automated_setup_2025/
ansible-playbook ubuntu-setup.yml -K
```


**Note:** The playbook will prompt you to create a Healthchecks.io URL. You can:
- Create a free account at https://healthchecks.io and paste the ping URL when prompted
- Press Enter to skip healthcheck monitoring

### 4. Reboot and Verify

After the initial setup completes, **reboot the system** to load the NVIDIA driver:

```bash
sudo reboot
```

After reboot, run the verification playbook to confirm everything is working:

```bash
cd automated_setup_2025/
ansible-playbook post-reboot-verify.yml -K
```

This will verify:
- ✅ NVIDIA driver is loaded
- ✅ CUDA toolkit is available
- ✅ Docker can access GPU
- ✅ PyTorch CUDA support is enabled
- ✅ TensorRT is installed

### 5. Copy SSH Keys

```bash
ssh-copy-id -p 33412 finn@<ip-address>
```

---

## Post-Installation Information

### What Gets Installed

The playbook automatically installs and configures:
- **NVIDIA Driver 580** with CUDA 13.0
- **TensorRT 10.13.3** (version-locked with `dpkg hold` - safe with `apt upgrade`)
- **Docker** with NVIDIA Container Toolkit
- **Tailscale** and **RealVNC Server**
- **Python 3.12** virtual environment at `~/code/auto_test`
- Daily system reboot at 6:00 AM
- Healthchecks.io monitoring (5 min interval, optional)
- SSH on custom port 33412
- **Automatic VM detection** and display fixes (if running in a VM)

### TensorRT Installation - Smart Configuration

The playbook **automatically constructs** the correct TensorRT download URL based on your configuration:

**Configuration variables:**
```yaml
tensorrt_version_full: "10.13.3"    # Version to install
cuda_version_full: "13.0"            # CUDA version
tensorrt_install_method: "local"     # Installation method
```

**Installation methods:**
- `"local"` - Download and use local repository (recommended - guarantees version availability)
- `"network"` - Use CUDA network repository (only works while version available)
- `"auto"` - Try local first, fall back to network if download fails

**Auto-constructed URL:**
```
https://developer.download.nvidia.com/compute/tensorrt/10.13.3/local_installers/nv-tensorrt-local-repo-ubuntu2404-10.13.3-cuda-13.0_1.0-1_amd64.deb
```

The playbook detects:
- ✅ Ubuntu version (24.04)
- ✅ Architecture (amd64, arm64, etc.)
- ✅ CUDA version (13.0)
- ✅ TensorRT version (10.13.3)

**Override with custom URL** (optional):
```yaml
tensorrt_local_repo_url: "https://your-server.com/tensorrt.deb"
```

**URL Pattern Verification:** The auto-construction approach has been verified to work correctly for TensorRT 10.x series across multiple Ubuntu versions (22.04, 24.04), CUDA versions (12.9, 13.0), and architectures. See [TENSORRT_URL_VERIFICATION.md](TENSORRT_URL_VERIFICATION.md) for detailed test results.

**Note:** TensorRT is version-locked with `dpkg hold`, so `sudo apt upgrade` will **NOT** upgrade it.

### Python Virtual Environment

The setup creates a ready-to-use Python environment at `~/code/auto_test` with:
- Python 3.12
- PyTorch with CUDA support
- Ultralytics (YOLO)
- TensorRT Python bindings
- ONNX Runtime GPU

Activate the environment:
```bash
source ~/code/auto_test/activate.sh
```

### Virtual Machine Detection

The playbook automatically detects if it's running in a virtual machine using `systemd-detect-virt` and applies appropriate fixes.

**Supported virtualization platforms:**
- QEMU/KVM
- VMware
- VirtualBox
- Hyper-V
- And others detected by systemd

**Automatic VM fixes applied:**
- QXL display driver configuration
- Disables AutoAddGPU to prevent conflicts
- Removes conflicting NVIDIA X11 configs
- Optimizes display server for VM environments

**Manual VM detection check:**
```bash
systemd-detect-virt
```

If the command returns anything other than `none`, you're running in a VM and the display fixes will be automatically applied.

---

## Package Management & Reproducibility

### Frozen GPU Stack (100% Reproducible)

The entire NVIDIA GPU stack is **version-locked** to ensure reproducibility:

| Component | Version | Method | Packages Held |
|-----------|---------|--------|---------------|
| **NVIDIA Driver** | 580.95.05 | Local repository | ~15 packages |
| **CUDA Toolkit** | 13.0.0 | Local repository | ~20+ packages |
| **TensorRT** | 10.13.3 | Local repository | 9 packages |

All installers are stored in `/opt/installers/` for offline rebuilds.

### Three Layers of Protection

1. **Local Repositories** (`/opt/installers/`): Immunity to upstream removal
2. **Package Holding** (`dpkg hold`): Prevents `apt upgrade`
3. **Unattended-Upgrades Blacklist** (`/etc/apt/apt.conf.d/51nvidia-blacklist`): Blocks automatic updates

### Check Held Packages

**View all GPU stack held packages:**
```bash
dpkg --get-selections | grep hold | grep -E 'nvidia|cuda|tensorrt'
```

**Count by component:**
```bash
echo "NVIDIA Driver packages held:"
dpkg --get-selections | grep hold | grep -E 'nvidia.*-580' | wc -l

echo "CUDA packages held:"
dpkg --get-selections | grep hold | grep -E 'cuda-|libcu' | wc -l

echo "TensorRT packages held:"
dpkg --get-selections | grep hold | grep -E 'tensorrt|libnvinfer' | wc -l
```

### Held Package Details

**NVIDIA Driver (580.95.05):** All packages matching `nvidia.*-580`, including:
- `nvidia-driver-580`, `nvidia-utils-580`, `libnvidia-gl-580`, `libnvidia-compute-580`, etc.

**CUDA Toolkit (13.0):** All packages matching `cuda-*-13-0`, including:
- `cuda-toolkit-13-0`, `cuda-runtime-13-0`, `cuda-libraries-13-0`, `cuda-nvcc-13-0`, etc.

**TensorRT (10.13.3):** Exactly 9 packages:
- `tensorrt-dev`, `tensorrt-libs`, `libnvinfer10`, `libnvinfer-dev`, `libnvinfer-headers-dev`, `libnvinfer-plugin10`, `libnvonnxparsers10`, `python3-libnvinfer`, `python3-libnvinfer-dev`

### Verify Local Installers

```bash
# Check installer storage
ls -lh /opt/installers/nvidia-driver/
ls -lh /opt/installers/cuda/
ls -lh /opt/installers/tensorrt/

# Verify total storage used (~2-3 GB)
du -sh /opt/installers/
```

### Offline Rebuild Capability

```bash
# Backup installers for offline storage
cd /opt
sudo tar -czf installers-backup-$(date +%Y%m%d).tar.gz installers/

# Restore and rebuild on new machine (no internet required)
scp installers-backup-20250131.tar.gz user@newmachine:/opt/
ssh user@newmachine
cd /opt && sudo tar -xzf installers-backup-20250131.tar.gz
# Run playbook - will use local installers
cd ~/automated_setup_2025
ansible-playbook ubuntu-setup.yml -K -vv
```

### Manual Upgrade Procedures

**⚠️ IMPORTANT:** Never upgrade one component in isolation. Check compatibility matrix first: [REPRODUCIBILITY_STRATEGY.md](REPRODUCIBILITY_STRATEGY.md)

**Quick upgrade example (TensorRT only):**
```bash
# 1. Unhold TensorRT packages
dpkg --get-selections | grep hold | grep -E 'tensorrt|libnvinfer' | awk '{print $1}' | xargs sudo apt-mark unhold

# 2. Update playbook variables in ubuntu-setup.yml
# tensorrt_version_full: "10.14.0"

# 3. Run playbook
ansible-playbook ubuntu-setup.yml -K -vv

# 4. Reboot and verify
sudo reboot
```

**For complete upgrade procedures**, see: [REPRODUCIBILITY_STRATEGY.md](REPRODUCIBILITY_STRATEGY.md)


