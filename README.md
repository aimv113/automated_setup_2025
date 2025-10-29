# Automated Setup 2025

## Initial Ubuntu 24.04.3 Setup

### 1. Update System and Install Required Packages

```bash
sudo apt update
sudo apt install openssh-server ansible git -y
```

### 2. Configure SSH Service

```bash
sudo systemctl start ssh
sudo systemctl enable ssh
```

### 3. Clone Repository and Run Setup

Get your IP address:
```bash
hostname -I
```

SSH into the machine:
```bash
ssh finn@<ip-address>
```

Clone the repository:
```bash
git clone https://github.com/aimv113/automated_setup_2025.git
cd automated_setup_2025/
```

Run the Ansible playbook:
```bash
ansible-playbook ubuntu-setup.yml -K
```

**Note:** The playbook will prompt you to create a Healthchecks.io URL. You can:
- Create a free account at https://healthchecks.io and paste the ping URL when prompted
- Press Enter to skip healthcheck monitoring

### 4. Copy SSH Keys

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

## Package Management

### TensorRT Version Pinning

TensorRT 10.13 is automatically pinned to prevent accidental upgrades during `apt update` or `apt upgrade`.

**Held packages:**
- `tensorrt-dev`
- `tensorrt-libs`
- `libnvinfer10`
- `libnvinfer-dev`
- `libnvinfer-headers-dev`
- `libnvinfer-plugin10`
- `libnvonnxparsers10`
- `python3-libnvinfer`
- `python3-libnvinfer-dev`

### Check Held Packages

View all held packages:
```bash
dpkg --get-selections | grep hold
```

Check TensorRT-specific packages:
```bash
dpkg --get-selections | grep -E "(tensorrt|libnvinfer)" | grep hold
```

### Manually Upgrade TensorRT (if needed)

If you need to upgrade TensorRT in the future:

```bash
# Unhold packages
sudo apt-mark unhold tensorrt-dev tensorrt-libs libnvinfer10 libnvinfer-dev \
  libnvinfer-headers-dev libnvinfer-plugin10 libnvonnxparsers10 \
  python3-libnvinfer python3-libnvinfer-dev

# Update and upgrade
sudo apt update && sudo apt upgrade

# Hold packages again at new version
sudo apt-mark hold tensorrt-dev tensorrt-libs libnvinfer10 libnvinfer-dev \
  libnvinfer-headers-dev libnvinfer-plugin10 libnvonnxparsers10 \
  python3-libnvinfer python3-libnvinfer-dev
```


