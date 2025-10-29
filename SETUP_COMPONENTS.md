# Ubuntu 24.04 Automated Setup Components

This playbook configures a complete Ubuntu 24.04 system with development tools, NVIDIA GPU support, monitoring, and networking.

## System Configuration

### 1. System Update
- Full system package update and upgrade (`apt dist-upgrade`)

### 2. Common Utilities & Monitoring Tools
- **Build Tools**: build-essential, git, cmake
- **Archive Tools**: unzip, zip
- **Network Tools**: wget, curl, netcat-traditional, net-tools
- **Text Editors**: vim, nano
- **File Tools**: tree
- **JSON Tools**: jq
- **Process Tools**: psmisc
- **Monitoring Tools**:
  - htop (process monitor)
  - btop (resource monitor)
  - bmon (bandwidth monitor)
  - iftop (network monitor)
  - nvtop (NVIDIA GPU monitor)
  - wavemon (wireless monitor)
  - lm-sensors (hardware sensors)
  - speedtest-cli (network speed testing)

### 3. SSH Configuration
- OpenSSH server installation
- Custom SSH port (configurable, default: 33412)
- Password and public key authentication enabled
- Root login disabled

### 4. Firewall (UFW)
- UFW firewall enabled
- SSH port allowed through firewall
- Non-interactive configuration

### 5. Auto-Reboot Timer
- Systemd timer for daily automatic reboots
- Configurable time (default: 3:00 AM)
- Persistent timer configuration

### 6. Tailscale VPN
- Tailscale repository and GPG key
- Tailscale package installation
- Tailscaled service enabled and started
- Manual authentication required post-install (`sudo tailscale up`)

### 7. RealVNC Server
- RealVNC Server installation (version 7.13.0)
- Direct .deb package download and installation

### 8. Visual Studio Code
- Microsoft repository and GPG key
- VS Code package installation
- Latest stable version

### 9. Display Server Configuration
- **VM Detection**: Automatic detection using `systemd-detect-virt`
- **Xorg Configuration**: Wayland disabled, Xorg forced via GDM3
- **VM Display Fix**: QXL display driver configuration for virtual machines
- **X11 Config**: Automatic GPU configuration based on environment

### 10. NVIDIA Driver
- NVIDIA driver installation (version 580)
- Graphics drivers PPA repository
- Kernel Mode Setting (KMS) enabled
- GRUB configuration updated with `nvidia-drm.modeset=1`
- Video memory preservation configured

### 11. CUDA Toolkit
- CUDA Toolkit 13.0 installation
- Official NVIDIA CUDA repository
- Environment variables configured (`/etc/profile.d/cuda.sh`)
- Library paths configured (`/etc/ld.so.conf.d/cuda.conf`)
- System-wide PATH and LD_LIBRARY_PATH setup

### 12. TensorRT
- TensorRT 10.13 installation with version pinning
- Multiple TensorRT packages:
  - tensorrt-dev
  - tensorrt-libs
  - libnvinfer10
  - libnvinfer-dev
  - libnvinfer-headers-dev
  - libnvinfer-plugin10
  - libnvonnxparsers10
  - python3-libnvinfer
  - python3-libnvinfer-dev
- Package version pinning (dpkg hold) to prevent unwanted upgrades
- Fallback to latest version if specific version unavailable

### 13. Docker + NVIDIA Runtime
- **Docker Installation**:
  - Docker CE (Community Edition)
  - Docker CLI
  - containerd.io
  - Docker Buildx plugin
  - Docker Compose plugin
- **NVIDIA Container Toolkit**:
  - NVIDIA container runtime
  - NVIDIA Docker repository
  - Docker daemon configured with NVIDIA as default runtime
- User added to docker group for non-root access

### 14. Python & Development Tools
- Python 3 and Python 3.12
- pip (Python package manager)
- venv (virtual environment support)
- python3-dev (development headers)

### 15. Healthchecks.io Service
- Systemd service for healthcheck pings
- Systemd timer (every 30 seconds)
- curl-based ping script
- Automatic boot startup with 15-second delay
- Configurable healthcheck URL

### 16. Auto Test Python Environment
- **Directory**: `~/code/auto_test`
- **Virtual Environment**: Python 3.12 venv
- **ML Packages Installed**:
  - PyTorch with CUDA 12.1 support
  - torchvision
  - torchaudio
  - Ultralytics (YOLOv8/v11)
  - nvidia-tensorrt (Python bindings)
  - onnxruntime-gpu
- **CUDA Verification**: Automated check for GPU availability
- **Activation Script**: `~/code/auto_test/activate.sh` for easy environment activation

## Configuration Variables

The playbook uses these configurable variables (set at top of playbook):

- `ssh_port`: SSH port number (default: 33412)
- `ssh_user`: Username for SSH and Docker group
- `healthchecks_url`: Healthchecks.io ping endpoint
- `auto_reboot_time`: Daily reboot time in HH:MM format (default: "03:00")
- `nvidia_driver_version`: NVIDIA driver version (default: "580")
- `cuda_version`: CUDA version short format (default: "13-0")
- `cuda_version_full`: CUDA version full format (default: "13.0")
- `tensorrt_version`: TensorRT version pattern (default: "10.13.*")
- `tensorrt_full_version`: TensorRT full version (default: "10.13.*-1+cuda13.0")
- `realvnc_version`: RealVNC version (default: "7.13.0")

## Logging

- Comprehensive logging to `/var/log/ansible-ubuntu-setup-<timestamp>.log`
- Each section logs its status and output
- Final summary includes all installed components and versions

## Post-Installation Manual Steps

1. **Tailscale**: Run `sudo tailscale up` to authenticate
2. **RealVNC**: Configure VNC server settings and authentication
3. **Auto Test Environment**: Activate with `source ~/code/auto_test/activate.sh`
4. **Docker**: Log out and back in for docker group membership to take effect

## System Requirements

- Ubuntu 24.04 LTS (Noble Numbat)
- NVIDIA GPU (for GPU-related components)
- Internet connection for package downloads
- Root/sudo access
