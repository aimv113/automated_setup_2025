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

### Playbook Structure (16 Sequential Sections)

Monolithic file with: System Update → Tools → SSH (port 33412) → UFW → Auto-Reboot → Tailscale → RealVNC → VS Code → **Display/VM Detection** → NVIDIA Driver → CUDA → **TensorRT (pinned)** → Docker+NVIDIA → Python → Healthchecks → ML Environment

### Critical Design Patterns

**1. VM Detection (Lines 284-365)**
Uses `systemd-detect-virt` to detect virtualization and apply different configs:
- **Physical**: Standard NVIDIA GPU + Xorg
- **VM**: QXL display driver, disable AutoAddGPU, remove NVIDIA X11 configs

Sets `is_virtual_machine` and `virtualization_type` facts. Critical because NVIDIA display drivers conflict with VM drivers.

**2. TensorRT Version Pinning (Lines 438-554)**
Explicitly pins TensorRT 10.13 with `dpkg hold` to prevent upgrades. Two-stage: try specific version → fallback to latest → always hold packages. Version mismatches break ML apps.

**3. Logging Architecture**
Every section writes to `/var/log/ansible-ubuntu-setup-<timestamp>.log` (created lines 27-43). Includes section headers, status, versions, errors.

**4. Error Handling**
Non-critical sections use `block/rescue` (Tailscale, RealVNC, VS Code, CUDA, TensorRT, Docker). Critical sections (system update, NVIDIA driver) fail entire playbook.

### Configuration Variables (Lines 7-20)

```yaml
ssh_port: 33412
nvidia_driver_version: "580"
cuda_version: "13-0"          # Short format
cuda_version_full: "13.0"     # Full format
tensorrt_version: "10.13.*"
tensorrt_full_version: "10.13.*-1+cuda13.0"
realvnc_version: "7.13.0"
healthchecks_url: "https://hc-ping.com/..."
auto_reboot_time: "03:00"
```

**Always update both short AND full version formats together.**

## Installation Compliance (see INSTALLATION_COMPARISON_REPORT.md)

**✅ FULLY COMPLIANT (Follow Official Docs):**
- **Tailscale** (lines 212-257): Uses official GPG key and repository list
- **Visual Studio Code** (lines 286-321): Modern keyring location (`/usr/share/keyrings/`), no deprecated modules
- **NVIDIA Driver** (lines 396-438): Uses `ubuntu-drivers install nvidia:580-server` (official Ubuntu method)
- **CUDA Toolkit** (lines 440-449): Official NVIDIA keyring and repository
- **NVIDIA Container Toolkit** (lines 643-677): Uses `nvidia-ctk runtime configure --runtime=docker` (official NVIDIA method)
- **Python environment**: Standard Ubuntu packages and venv

**⚠️ ACCEPTABLE DEVIATIONS (Low Priority):**
- **Docker**: Hardcodes arch/codename (only matters for multi-arch/multi-version support)
- **TensorRT**: Uses network repo instead of local repo (acceptable for automation, includes version pinning)

**All official documentation links available in INSTALLATION_COMPARISON_REPORT.md**

## Post-Installation Verification

```bash
# Check log
sudo tail -100 /var/log/ansible-ubuntu-setup-*.log

# Verify GPU stack
nvidia-smi
nvcc --version
docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi

# Verify ML environment
source ~/code/auto_test/activate.sh
python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"

# Check services and timers
systemctl status tailscaled docker
systemctl list-timers

# Check pinned packages
dpkg --get-selections | grep hold
```

## Modifying the Playbook

**Adding Packages:**
1. Add numbered section with comment block
2. Use `block/rescue` for non-critical installs
3. Log to `{{ log_file }}`
4. Add debug output
5. Update SETUP_COMPONENTS.md

**Version Updates:**
1. Update **both** short and full version variables
2. Verify compatibility matrix (CUDA ↔ TensorRT ↔ PyTorch)
3. Test TensorRT pinning still works
4. Update README.md

**Changing Methods:**
1. Check INSTALLATION_COMPARISON_REPORT.md for current deviations
2. Test on fresh Ubuntu 24.04 VM
3. Update comparison report

## Documentation Structure

- `README.md`: User instructions
- `SETUP_COMPONENTS.md`: Installed components list
- `INSTALLATION_COMPARISON_REPORT.md`: Technical analysis vs official docs
- `CLAUDE.md`: This file

## VM vs Bare Metal Testing

Playbook behavior differs based on VM detection. Test both:

```bash
# Check environment
systemd-detect-virt  # "none" = bare metal, else shows VM type

# VM: Should apply QXL config
# Bare Metal: Should apply NVIDIA display config
ansible-playbook ubuntu-setup.yml -K -vv
```
