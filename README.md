# Automated Setup 2025

Automated Ubuntu 24.04 setup with NVIDIA GPU support, CUDA, TensorRT, Docker, ML environment, and monitoring. Features a **frozen, reproducible GPU stack** with four layers of protection.

## Prerequisites

**Recommended:** Ubuntu 24.04 Desktop (GNOME)
- Full desktop environment with GDM3
- Wayland automatically disabled, Xorg configured
- NVIDIA display drivers configured for bare metal and VM setups

**Supported:** Ubuntu 24.04 Server + Desktop Environment
- The playbook gracefully handles LightDM (Xubuntu) or no display manager
- See "Display Manager Compatibility" section below

## Initial Ubuntu 24.04 Setup

### 1. Install Ubuntu Desktop

**Option A: Fresh Installation (Recommended)**
Download Ubuntu 24.04 Desktop from [ubuntu.com](https://ubuntu.com/download/desktop) and install with default GNOME desktop.

**Option B: Server + Desktop (Advanced)**
If you installed Ubuntu Server, you can add the desktop environment:
```bash
sudo apt update
sudo apt install ubuntu-desktop -y

# Set system to boot into graphical desktop by default
sudo systemctl set-default graphical.target

# Verify the default target
sudo systemctl get-default
# Should output: graphical.target
```

**Note:** After installing the desktop, you may want to reboot before running the playbook to ensure the graphical environment is fully initialized.

### 2. Configure SSH Service (For Remote Access)

Enable SSH for remote management:
```bash
sudo systemctl start ssh
sudo systemctl enable ssh
```

Get your machine's IP address:
```bash
hostname -I
```

Connect from your local machine:
```bash
ssh username@<ip-address>
```

# send ssh keys!!

**Optional: Lock Down SSH (Recommended after key exchange)**

After copying your SSH key to the remote machine, secure SSH:
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

This will:
- Change SSH port to 33412
- Disable password authentication
- Enable key-only authentication

### 3. Install Ansible and Clone Repository

```bash
sudo apt update
sudo apt install ansible git -y
git clone https://github.com/aimv113/automated_setup_2025.git
cd automated_setup_2025/
```

### 4. Run the Setup Playbook

```bash
ansible-playbook ubuntu-setup.yml -K
```

**Flags:**
- `-K`: Prompts for sudo password
- `-vv`: Verbose output (optional, but helpful for troubleshooting)

**Interactive Prompt:**
The playbook will prompt you to create a Healthchecks.io URL (optional monitoring):
- Create a free account at https://healthchecks.io and paste the ping URL when prompted
- Or press **Enter** to skip healthcheck monitoring

**What Happens:**
- ✅ Pre-flight validation (disk space, network)
- ✅ Downloads NVIDIA driver 580.95.05, CUDA 13.0, TensorRT 10.13.3 to `/opt/installers/`
- ✅ Installs entire GPU stack from local repositories
- ✅ Applies four layers of protection (dpkg hold, unattended-upgrades blacklist, APT preferences)
- ✅ Creates version manifest and SHA-256 checksums
- ✅ Configures Docker, Tailscale, RealVNC, VS Code
- ✅ Sets up Python ML environment
- ✅ Configures daily auto-reboot at 6 AM

**Duration:** ~20-30 minutes (depends on internet speed for initial downloads)

### 5. Reboot and Verify

After the initial setup completes, **reboot the system** to load the NVIDIA driver:

```bash
sudo reboot
```

After reboot, run the verification playbook to confirm everything is working:

```bash
cd ~/automated_setup_2025
ansible-playbook post-reboot-verify.yml -K
```

**Verification includes:**
- ✅ NVIDIA driver loaded (`nvidia-smi`)
- ✅ CUDA toolkit available (`nvcc --version`)
- ✅ Docker NVIDIA runtime working
- ✅ PyTorch CUDA 13.0 support enabled
- ✅ TensorRT packages installed and held

---

```bash
sudo snap remove firefox
sudo add-apt-repository ppa:mozillateam/ppa -y
sudo apt update
sudo apt install firefox -y
xdg-settings set default-web-browser firefox.desktop
```



## What Gets Installed

### Frozen GPU Stack (100% Reproducible)

| Component | Version | Method | Protection |
|-----------|---------|--------|------------|
| **NVIDIA Driver** | 580.95.05 | Local repository | 4 layers |
| **CUDA Toolkit** | 13.0.2 | Local repository | 4 layers |
| **TensorRT** | 10.13.3 | Local repository | 4 layers |
| **PyTorch** | Latest (cu130) | pip (Python venv) | - |

**Four Layers of Protection:**
1. Local installers in `/opt/installers/` (offline capability)
2. Package holding with `dpkg hold` (~44+ packages)
3. Unattended-upgrades blacklist
4. APT preferences with Pin-Priority 1001

**Result:** `apt upgrade` will **NEVER** touch your GPU stack! ✅

### Additional Components

- **Docker** with NVIDIA Container Toolkit
- **Tailscale** VPN (optional - requires manual setup)
- **RealVNC Server** (version 7.13.0)
- **VS Code** (latest from Microsoft repository)
- **Python 3.12** virtual environment at `~/code/auto_test` with ML libraries
- **SSH** on custom port 33412 (key-only authentication)
- **UFW** firewall configured
- **Daily auto-reboot** at 6:00 AM
- **Healthchecks.io** monitoring (5 min interval, optional)

### Display Manager Compatibility

**Ubuntu Desktop (GNOME + GDM3):** ✅ Fully supported and recommended
- Wayland automatically disabled
- Xorg configured with NVIDIA drivers
- KMS (Kernel Mode Setting) enabled

**Ubuntu Server + Xubuntu (LightDM):** ✅ Supported
- Playbook detects LightDM and configures appropriately
- No Wayland to disable

**Headless (No Display Manager):** ✅ Supported
- Playbook gracefully skips display manager configuration
- GPU compute still works perfectly

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
- **Python 3.12** (venv)
- **PyTorch 2.x** with CUDA 13.0 support (cu130 wheels)
- **Ultralytics** (YOLO v8/v11)
- **TensorRT** Python bindings
- **ONNX Runtime GPU**

Activate the environment:
```bash
source ~/code/auto_test/activate.sh
python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
```

### Virtual Machine Detection & Display Configuration

The playbook automatically detects if it's running in a virtual machine using `systemd-detect-virt` and applies environment-specific configurations.

**Physical Machine (Bare Metal):**
- ✅ NVIDIA driver with full display support
- ✅ Xorg configured with NVIDIA acceleration
- ✅ KMS (Kernel Mode Setting) enabled
- ✅ Wayland disabled (GDM3)

**Virtual Machine (QEMU/KVM/VMware/VirtualBox/Hyper-V):**
- ✅ QXL display driver configured
- ✅ AutoAddGPU disabled to prevent conflicts
- ✅ NVIDIA X11 configs removed (GPU used for compute only)
- ✅ Display optimized for VM environment

**Check your environment:**
```bash
systemd-detect-virt
# "none" = physical machine
# "qemu", "kvm", "vmware", etc. = virtual machine
```

**Note:** VM detection happens automatically - no configuration needed!

---

## Package Management & Reproducibility

### Frozen GPU Stack (100% Reproducible)

The entire NVIDIA GPU stack is **version-locked** to ensure reproducibility:

| Component | Version | Method | Packages Held |
|-----------|---------|--------|---------------|
| **NVIDIA Driver** | 580.95.05 | Local repository | ~15 packages |
| **CUDA Toolkit** | 13.0.2 | Local repository | ~20+ packages |
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


