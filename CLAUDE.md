# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Two Ansible playbooks for automated Ubuntu 24.04 setup with NVIDIA GPU support, ML environment, and monitoring. Designed for bare metal and VM installations with automatic environment detection.

**Playbooks:**
1. `ubuntu-setup.yml` - Main installation (run first)
2. `post-reboot-verify.yml` - Post-reboot verification (run after reboot)
3. `app-deploy.yml` - App deploy (king_detector, crane display); run after post-reboot-verify passes. Documented in [Setup-post-reboot.md](Setup-post-reboot.md) section 9.

## Running the Playbooks

**Step 1: Initial setup**
```bash
ansible-playbook ubuntu-setup.yml -K -vv  # -K=sudo prompt, -vv=verbose
```

**Interactive Prompt:** On first run, playbook prompts for Healthchecks.io URL (optional - can skip by pressing Enter).

**Step 2: Reboot**
```bash
sudo reboot
```

**Step 3: Verify installation**
```bash
ansible-playbook post-reboot-verify.yml -K -vv
```

Test idempotency by running setup twice (second run should show no changes).

## Architecture

### Playbook Structure (19 Sections)

Interactive healthcheck prompt + sections 1-16 + reboot check + final message in `ubuntu-setup.yml` (1130 lines):
0. Healthcheck Prompt → 1. Log Init → 2. System Update → 3. Tools → 4. SSH (port 33412) → 5. UFW → 6. Auto-Reboot → 7. Tailscale → 8. RealVNC → 9. VS Code → 10. Display/VM Detection → 11. NVIDIA Driver → 12. CUDA → 13. TensorRT → 14. Docker+NVIDIA → 15. Python → 16. Healthchecks (5min, optional) → 17. ML Environment → 18. Reboot Check → 19. Final Message

### Critical Design Patterns

**1. VM Detection (Lines 344-427)**
Uses `systemd-detect-virt` to detect virtualization and apply different configs:
- **Physical**: Standard NVIDIA GPU + Xorg
- **VM**: QXL display driver, disable AutoAddGPU, remove NVIDIA X11 configs

Sets `is_virtual_machine` and `virtualization_type` facts. Critical because NVIDIA display drivers conflict with VM display drivers.

**2. TensorRT Auto-Construction (Lines 513-689)**
Smart URL construction based on system detection:
- Detects Ubuntu version, architecture automatically
- Constructs download URL from configuration variables
- Three installation methods: `local` (recommended), `network`, `auto`
- Always applies `dpkg hold` to prevent version upgrades
- See [TENSORRT_URL_VERIFICATION.md](TENSORRT_URL_VERIFICATION.md) for verified URL patterns

**3. Logging Architecture**
Every section writes to `/var/log/ansible-ubuntu-setup-<timestamp>.log` (created lines 40-56). Includes section headers, status, versions, errors.

**4. Error Handling**
Non-critical sections use `block/rescue` (Tailscale, RealVNC, VS Code, CUDA, TensorRT, Docker). Critical sections (system update, NVIDIA driver) fail entire playbook.

**5. Version Locking Strategy (Frozen Installation Model)**
The playbook implements a fully reproducible GPU stack with three layers of protection:

**Layer 1: Local Repositories** (`/opt/installers/`)
- NVIDIA Driver 580.95.05: Local repo .deb stored in `/opt/installers/nvidia-driver/`
- CUDA Toolkit 13.0.0: Local repo .deb stored in `/opt/installers/cuda/`
- TensorRT 10.13.3: Local repo .deb stored in `/opt/installers/tensorrt/`
- Enables offline rebuilds and immunity to upstream removal

**Layer 2: Package Holding** (`dpkg hold`)
- NVIDIA Driver: ~15 packages held (all `nvidia.*-580`)
- CUDA Toolkit: ~20+ packages held (all `cuda-*-13-0` and `libcu*`)
- TensorRT: 9 packages held (exact list in TENSORRT_VERSION_STRATEGY.md)
- Prevents `apt upgrade` from touching GPU stack

**Layer 3: Unattended-Upgrades Blacklist** (`/etc/apt/apt.conf.d/51nvidia-blacklist`)
- Blacklists: `nvidia-driver-*`, `cuda-*`, `tensorrt-*`, `libnvinfer*`
- Prevents automatic security updates from breaking compatibility
- Defensive protection even if holds are manually cleared

**Result**: 100% GPU stack reproducibility. See [REPRODUCIBILITY_STRATEGY.md](REPRODUCIBILITY_STRATEGY.md) for complete documentation.

### Configuration Variables (Lines 13-41)

```yaml
ssh_port: 33412
ssh_user: "{{ ansible_env.USER }}"
auto_reboot_time: "06:00"
# healthchecks_url - Prompted interactively during run

# Local installer storage for reproducible builds
installers_base_path: "/opt/installers"

# NVIDIA Driver configuration (local repository method)
nvidia_driver_version: "580"
nvidia_driver_version_full: "580.95.05"
nvidia_driver_local_repo_url: "https://us.download.nvidia.com/..."

# CUDA Toolkit configuration (local repository method)
cuda_version: "13-0"              # Short format for apt packages
cuda_version_full: "13.0"         # Full format for display
cuda_version_full_numeric: "13.0.2"  # Full version with patch
cuda_local_repo_url: "https://developer.download.nvidia.com/..."

# TensorRT configuration (local repository method)
tensorrt_version_major: "10.13"
tensorrt_version_full: "10.13.3"
tensorrt_version_pattern: "10.13.*"
tensorrt_install_method: "local"  # or "network" or "auto"
tensorrt_local_repo_url: ""       # Auto-constructed if empty

realvnc_version: "7.13.0"
```

**Important:** Update both short and full version formats together. All installers are downloaded to `/opt/installers/` for offline rebuilds.

## Installation Compliance

**✅ ALL SECTIONS FULLY COMPLIANT** with official installation methods:

| Section | Lines | Method |
|---------|-------|--------|
| Tailscale | 223-272 | Official GPG key and repository list |
| RealVNC | 274-295 | Direct .deb download from NVIDIA |
| VS Code | 297-341 | Modern keyring location (`/usr/share/keyrings/`) |
| NVIDIA Driver | 430-475 | Official `ubuntu-drivers install nvidia:580` (desktop with display) |
| CUDA Toolkit | 477-510 | Official NVIDIA keyring and repository |
| TensorRT | 513-689 | Smart URL auto-construction, dual method with fail-safe |
| Docker + NVIDIA Runtime | 691-803 | Dynamic arch/codename, `nvidia-ctk runtime configure` |

**Full technical analysis:** [INSTALLATION_COMPARISON_REPORT.md](INSTALLATION_COMPARISON_REPORT.md)

## Post-Installation Verification

After running `ubuntu-setup.yml`, **reboot the system**, then run `post-reboot-verify.yml` to verify all components:

```bash
sudo reboot  # Reboot first!

# After reboot, run verification playbook
ansible-playbook post-reboot-verify.yml -K -vv
```

The verification playbook checks:
- ✅ NVIDIA driver loaded (`nvidia-smi`)
- ✅ CUDA toolkit available (`nvcc --version`)
- ✅ Docker NVIDIA runtime working
- ✅ PyTorch CUDA support enabled
- ✅ TensorRT packages installed

**Manual verification (alternative):**
```bash
# Check logs
sudo tail -100 /var/log/ansible-ubuntu-setup-*.log
sudo tail -100 /var/log/ansible-post-reboot-verify-*.log

# Verify GPU stack
nvidia-smi
nvcc --version
docker run --rm --gpus all nvidia/cuda:13.0-base-ubuntu24.04 nvidia-smi

# Verify ML environment
source ~/code/auto_test/activate.sh
python3 -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"

# Check services
systemctl status tailscaled docker
systemctl list-timers  # Should show auto-reboot and healthcheck

# Check TensorRT pinning
dpkg --get-selections | grep hold  # Should show tensorrt packages
```

## Modifying the Playbook

**Adding Packages:** Add numbered section with separator, use `block/rescue` for non-critical, log to `{{ log_file }}`, update SETUP_COMPONENTS.md

**Version Updates:** Update both short/full version vars, check compatibility (Driver→CUDA→TensorRT→PyTorch), test TensorRT URL with `curl -I`, update README.md

**Method Changes:** Check INSTALLATION_COMPARISON_REPORT.md for compliance, test on fresh VM, update docs

## Documentation

- **README.md**: User setup instructions
- **SETUP_COMPONENTS.md**: Installed components list
- **INSTALLATION_COMPARISON_REPORT.md**: Compliance analysis vs official docs
- **REPRODUCIBILITY_STRATEGY.md**: Complete frozen installation model documentation
- **TENSORRT_VERSION_STRATEGY.md**: TensorRT version locking (legacy, see REPRODUCIBILITY_STRATEGY.md for full stack)
- **TENSORRT_URL_VERIFICATION.md**: Verified URL patterns
- **CLAUDE.md**: This file (AI guidance)

## VM vs Bare Metal Testing

Playbook behavior differs based on VM detection. Test both:

```bash
# Check environment type
systemd-detect-virt  # "none" = bare metal, else shows VM type (qemu, kvm, etc.)

# Expected behavior:
# - VM: QXL display driver, no NVIDIA X11 config
# - Bare Metal: NVIDIA display config, full GPU support

ansible-playbook ubuntu-setup.yml -K -vv
```

## Key Line Ranges

- **ubuntu-setup.yml** (~1200 lines): Variables 13-41, Local Installer Storage 104-136, System Update 139-152, Tools 155-220, SSH 223-270, UFW 273-293, Auto-Reboot 296-340, Tailscale 343-392, RealVNC 395-416, VS Code 419-475, Display/VM Detection 478-551, NVIDIA Driver (Local Repo) 546-643, CUDA (Local Repo) 646-754, TensorRT (Local Repo) 757-932, Unattended-Upgrades Blacklist 935-967, Repository Cleanup 970-992, Docker+NVIDIA 995-1100+, Python Environment, Healthchecks, ML Environment, Reboot Check, Final Message
