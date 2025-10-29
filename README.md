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
ansible-playbook ubuntu-setup.yml -K -vv
```

### 4. Copy SSH Keys

```bash
ssh-copy-id -p 33412 finn@<ip-address>
```

---

## Post-Installation Information

### What Gets Installed

The playbook automatically installs and configures:
- **NVIDIA Driver 580** with CUDA 13.0
- **TensorRT 10.13** (version-pinned and held from upgrades)
- **Docker** with NVIDIA Container Toolkit
- **Tailscale** and **RealVNC Server**
- **Python 3.12** virtual environment at `~/code/auto_test`
- Daily system reboot at 3:00 AM
- Healthchecks.io monitoring (30s interval)
- SSH on custom port 33412
- **Automatic VM detection** and display fixes (if running in a VM)

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


