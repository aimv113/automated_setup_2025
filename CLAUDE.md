# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Single Ansible playbook (`ubuntu-setup.yml`) for automated Ubuntu 24.04 setup with NVIDIA GPU support, ML environment, and monitoring. Designed for bare metal and VM installations with automatic environment detection.

## Running the Playbook

```bash
ansible-playbook ubuntu-setup.yml -K -vv  # -K=sudo prompt, -vv=verbose
```

Test idempotency by running twice (second run should show no changes).

## Architecture

### Playbook Structure (17 Sections)

Sections 0-16 plus final message in `ubuntu-setup.yml` (1027 lines):
0. Log Init → 1. System Update → 2. Tools → 3. SSH (port 33412) → 4. UFW → 5. Auto-Reboot → 6. Tailscale → 7. RealVNC → 8. VS Code → 9. Display/VM Detection → 10. NVIDIA Driver → 11. CUDA → 12. TensorRT → 13. Docker+NVIDIA → 14. Python → 15. Healthchecks → 16. ML Environment → 17. Final Message

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

### Configuration Variables (Lines 7-33)

```yaml
ssh_port: 33412
ssh_user: "{{ ansible_env.USER }}"
healthchecks_url: "https://hc-ping.com/..."
auto_reboot_time: "03:00"

nvidia_driver_version: "580"
cuda_version: "13-0"              # Short format for apt packages
cuda_version_full: "13.0"         # Full format for display

# TensorRT configuration
tensorrt_version_major: "10.13"
tensorrt_version_full: "10.13.3"
tensorrt_version_pattern: "10.13.*"
tensorrt_install_method: "local"  # or "network" or "auto"
tensorrt_local_repo_url: ""       # Auto-constructed if empty

realvnc_version: "7.13.0"
```

**Important:** Update both short and full version formats together. TensorRT URL is auto-constructed unless you override `tensorrt_local_repo_url`.

## Installation Compliance

**✅ ALL SECTIONS FULLY COMPLIANT** with official installation methods:

| Section | Lines | Method |
|---------|-------|--------|
| Tailscale | 223-272 | Official GPG key and repository list |
| RealVNC | 274-295 | Direct .deb download from NVIDIA |
| VS Code | 297-341 | Modern keyring location (`/usr/share/keyrings/`) |
| NVIDIA Driver | 430-475 | Official `ubuntu-drivers install nvidia:580-server` |
| CUDA Toolkit | 477-510 | Official NVIDIA keyring and repository |
| TensorRT | 513-689 | Smart URL auto-construction, dual method with fail-safe |
| Docker + NVIDIA Runtime | 691-803 | Dynamic arch/codename, `nvidia-ctk runtime configure` |

**Full technical analysis:** [INSTALLATION_COMPARISON_REPORT.md](INSTALLATION_COMPARISON_REPORT.md)

## Post-Installation Verification

```bash
# Check log
sudo tail -100 /var/log/ansible-ubuntu-setup-*.log

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
- **TENSORRT_VERSION_STRATEGY.md**: Version locking strategy
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

## Key Files and Line Ranges

- **ubuntu-setup.yml**: Main playbook (1027 lines total)
  - Variables: 7-33
  - VM Detection: 344-427
  - NVIDIA Driver: 430-475
  - CUDA: 477-510
  - TensorRT: 513-689
  - Docker: 691-803
