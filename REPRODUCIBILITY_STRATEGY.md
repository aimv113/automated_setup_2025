# Reproducibility Strategy

## Overview

This playbook implements a **frozen, reproducible, offline-capable** installation model for the entire NVIDIA GPU stack. Every component from NVIDIA driver to TensorRT is version-locked and stored locally, ensuring identical environments across installations and immunity to upstream repository changes.

## Philosophy

Traditional GPU stack installations suffer from non-determinism:
- **Repository drift**: NVIDIA and Ubuntu regularly update or remove old versions
- **Automatic upgrades**: `apt upgrade` can silently break compatibility
- **Network dependency**: Installers may become unavailable after 6-12 months
- **Version mismatches**: Mixed Ubuntu/NVIDIA repositories create conflicts

This playbook solves all of these problems with **three layers of protection**:

1. **Local Repositories**: Store all installers in `/opt/installers/` for offline rebuilds
2. **Package Holding**: Use `dpkg hold` to prevent upgrades
3. **Unattended-Upgrades Blacklist**: Block automatic security updates of GPU packages

## Version-Locked Components

### Complete GPU Stack

| Component | Version | Packages Held | Storage Location |
|-----------|---------|---------------|------------------|
| **NVIDIA Driver** | 580.95.05 | ~15 packages | `/opt/installers/nvidia-driver/` |
| **CUDA Toolkit** | 13.0.0 | ~20+ packages | `/opt/installers/cuda/` |
| **TensorRT** | 10.13.3 | 9 packages | `/opt/installers/tensorrt/` |
| **PyTorch** | Latest cu130 | - | Python venv (pip freeze) |

### NVIDIA Driver Packages (Held)

All packages matching `nvidia.*-580` are held, including:
- `nvidia-driver-580`
- `nvidia-utils-580`
- `libnvidia-gl-580`
- `libnvidia-compute-580`
- `libnvidia-decode-580`
- `libnvidia-encode-580`
- `nvidia-kernel-common-580`
- `nvidia-dkms-580`
- And ~7 additional dependencies

### CUDA Packages (Held)

All packages matching `cuda-*-13-0` and `libcu*` related to 13.0:
- `cuda-toolkit-13-0`
- `cuda-runtime-13-0`
- `cuda-libraries-13-0`
- `cuda-libraries-dev-13-0`
- `cuda-nvcc-13-0`
- `cuda-cudart-13-0`
- `cuda-cudart-dev-13-0`
- `libcublas-13-0`
- `libcufft-13-0`
- `libcurand-13-0`
- `libcusparse-13-0`
- `libcusolver-13-0`
- And ~10+ additional CUDA libraries

### TensorRT Packages (Held)

Exactly 9 packages held (as per existing strategy):
- `tensorrt-dev`
- `tensorrt-libs`
- `libnvinfer10`
- `libnvinfer-dev`
- `libnvinfer-headers-dev`
- `libnvinfer-plugin10`
- `libnvonnxparsers10`
- `python3-libnvinfer`
- `python3-libnvinfer-dev`

## Verification Commands

### Check Held Packages

```bash
# View all held GPU stack packages
dpkg --get-selections | grep hold | grep -E 'nvidia|cuda|tensorrt'

# Count by component
echo "NVIDIA Driver packages held:"
dpkg --get-selections | grep hold | grep -E 'nvidia.*-580' | wc -l

echo "CUDA packages held:"
dpkg --get-selections | grep hold | grep -E 'cuda-|libcu' | wc -l

echo "TensorRT packages held:"
dpkg --get-selections | grep hold | grep -E 'tensorrt|libnvinfer' | wc -l
```

### Verify Local Installers

```bash
# Check installer storage
ls -lh /opt/installers/nvidia-driver/
ls -lh /opt/installers/cuda/
ls -lh /opt/installers/tensorrt/

# Verify total storage used
du -sh /opt/installers/
```

### Test Upgrade Protection

```bash
# This should show NO GPU stack packages
sudo apt update
apt list --upgradable | grep -E 'nvidia|cuda|tensorrt'

# Safe test (dry-run)
sudo apt upgrade --dry-run | grep -E 'nvidia|cuda|tensorrt'
```

### Check Unattended-Upgrades Blacklist

```bash
# Verify blacklist file exists
cat /etc/apt/apt.conf.d/51nvidia-blacklist
```

## Manual Upgrade Procedures

### When to Upgrade

Only upgrade GPU stack components when:
1. New TensorRT version requires newer CUDA
2. Critical security vulnerability discovered
3. New GPU hardware requires newer driver
4. Testing new ML framework features

**⚠️ NEVER upgrade one component in isolation** - always check compatibility matrix first.

### Compatibility Matrix

| NVIDIA Driver | CUDA Toolkit | TensorRT | PyTorch CUDA |
|---------------|--------------|----------|--------------|
| 580.x | 13.0 | 10.13.3 | cu130 |
| 550.x | 12.4 | 10.0.x | cu124 |
| 535.x | 12.1 | 8.6.x | cu121 |

### Upgrade NVIDIA Driver (580 → 585 example)

```bash
# 1. Unhold current driver packages
sudo apt-mark unhold nvidia-driver-580 nvidia-utils-580
# Or unhold all:
dpkg --get-selections | grep hold | grep nvidia-580 | awk '{print $1}' | xargs sudo apt-mark unhold

# 2. Update playbook variables
# Edit ubuntu-setup.yml:
nvidia_driver_version: "585"
nvidia_driver_version_full: "585.0.0"
nvidia_driver_local_repo_url: "https://us.download.nvidia.com/XFree86/Linux-x86_64/585.0.0/nvidia-driver-local-repo-ubuntu2404-585.0.0_1.0-1_amd64.deb"

# 3. Run playbook to install new version
ansible-playbook ubuntu-setup.yml -K -vv

# 4. Reboot and verify
sudo reboot
nvidia-smi
```

### Upgrade CUDA Toolkit (13.0 → 13.1 example)

```bash
# 1. Check TensorRT compatibility first!
# Visit: https://docs.nvidia.com/deeplearning/tensorrt/support-matrix/index.html

# 2. Unhold CUDA packages
dpkg --get-selections | grep hold | grep -E 'cuda-|libcu' | awk '{print $1}' | xargs sudo apt-mark unhold

# 3. Update playbook variables
# Edit ubuntu-setup.yml:
cuda_version: "13-1"
cuda_version_full: "13.1"
cuda_version_full_numeric: "13.1.0"
cuda_local_repo_url: "https://developer.download.nvidia.com/compute/cuda/13.1.0/local_installers/cuda-repo-ubuntu2404-13-1-local_13.1.0-1_amd64.deb"

# 4. Run playbook
ansible-playbook ubuntu-setup.yml -K -vv

# 5. Update PyTorch to match
# Edit post-reboot-verify.yml:
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu131

# 6. Reboot and verify
sudo reboot
nvcc --version
ansible-playbook post-reboot-verify.yml -K -vv
```

### Upgrade TensorRT (10.13.3 → 10.14.0 example)

```bash
# 1. Unhold TensorRT packages
dpkg --get-selections | grep hold | grep -E 'tensorrt|libnvinfer' | awk '{print $1}' | xargs sudo apt-mark unhold

# 2. Update playbook variables
# Edit ubuntu-setup.yml:
tensorrt_version_major: "10.14"
tensorrt_version_full: "10.14.0"
tensorrt_version_pattern: "10.14.*"

# 3. Run playbook
ansible-playbook ubuntu-setup.yml -K -vv

# 4. Verify
dpkg -l | grep tensorrt
```

## Offline Rebuild Capability

### Backup Installers

```bash
# Archive local installers for offline storage
cd /opt
sudo tar -czf installers-backup-$(date +%Y%m%d).tar.gz installers/

# Store backup on:
# - Network share
# - Git LFS
# - USB drive
# - Cloud storage
```

### Restore and Rebuild Offline

```bash
# 1. Copy installers to new machine
scp installers-backup-20250131.tar.gz user@newmachine:/opt/
ssh user@newmachine
cd /opt
sudo tar -xzf installers-backup-20250131.tar.gz

# 2. Copy playbook
scp -r ~/automated_setup_2025 user@newmachine:~/

# 3. Run playbook (offline mode)
cd ~/automated_setup_2025
ansible-playbook ubuntu-setup.yml -K -vv

# Playbook will use local installers from /opt/installers/
# No internet required!
```

### Disaster Recovery

If GPU stack breaks:

```bash
# 1. Check what's held
dpkg --get-selections | grep hold | grep -E 'nvidia|cuda|tensorrt'

# 2. If nothing held - system was upgraded externally
# Restore from backup:
cd ~/automated_setup_2025
ansible-playbook ubuntu-setup.yml -K -vv --tags=nvidia,cuda,tensorrt

# 3. Or manually reinstall from local repos
sudo dpkg -i /opt/installers/nvidia-driver/nvidia-driver-local-repo.deb
sudo dpkg -i /opt/installers/cuda/cuda-repo-local.deb
# ... follow installation steps
```

## Troubleshooting

### Package Conflicts

**Symptom**: `apt` reports version conflicts during upgrade attempt

**Solution**:
```bash
# Check which repo is conflicting
apt-cache policy nvidia-driver-580
apt-cache policy cuda-toolkit-13-0

# Force held status
echo "nvidia-driver-580 hold" | sudo dpkg --set-selections
echo "cuda-toolkit-13-0 hold" | sudo dpkg --set-selections
```

### Held Packages Lost

**Symptom**: `dpkg --get-selections | grep hold` shows fewer packages than expected

**Solution**:
```bash
# Re-run playbook to re-apply holds
ansible-playbook ubuntu-setup.yml -K -vv --tags=nvidia,cuda,tensorrt

# Or manually re-hold
dpkg -l | grep '^ii' | grep nvidia-580 | awk '{print $2}' | xargs -I {} sudo dpkg --set-selections <<< "{} hold"
```

### Local Repo Missing

**Symptom**: `/opt/installers/` is empty or missing

**Solution**:
```bash
# Re-create from playbook
ansible-playbook ubuntu-setup.yml -K -vv

# Or restore from backup
cd /opt
sudo tar -xzf /path/to/installers-backup-20250131.tar.gz
```

### Unattended-Upgrades Still Upgrading

**Symptom**: GPU packages upgraded despite blacklist

**Solution**:
```bash
# Verify blacklist exists
cat /etc/apt/apt.conf.d/51nvidia-blacklist

# Check unattended-upgrades logs
tail -100 /var/log/unattended-upgrades/unattended-upgrades.log | grep -i nvidia

# Re-create blacklist
ansible-playbook ubuntu-setup.yml -K -vv --tags=unattended-upgrades
```

## Best Practices

### 1. Version Compatibility Testing
Always test version upgrades in a VM or staging system first:
```bash
# Spin up test VM
multipass launch --name gpu-test --cpus 4 --memory 8G --disk 50G 24.04

# Copy playbook and test
multipass transfer automated_setup_2025 gpu-test:~/
multipass shell gpu-test
cd ~/automated_setup_2025
ansible-playbook ubuntu-setup.yml -K -vv
```

### 2. Regular Backups
Schedule monthly backups of `/opt/installers/`:
```bash
# Add to cron
0 2 1 * * cd /opt && tar -czf /backup/installers-backup-$(date +\%Y\%m\%d).tar.gz installers/
```

### 3. Documentation Updates
When upgrading versions, update:
- `ubuntu-setup.yml` variables
- `README.md` version matrix
- `CLAUDE.md` line ranges
- This document's compatibility matrix

### 4. Git LFS for Installers (Optional)
Store installers in Git LFS for team-wide reproducibility:
```bash
cd automated_setup_2025
git lfs track "/opt/installers/**/*.deb"
git lfs push --all
```

## Security Considerations

### Holding Security Updates

**Trade-off**: Frozen versions may miss security patches

**Mitigation**:
1. Subscribe to NVIDIA security mailing list
2. Monitor CVE databases for GPU-related vulnerabilities
3. Test security updates in staging before production
4. Schedule quarterly security review of held packages

### Verifying Installer Integrity

```bash
# Check SHA256 of downloaded installers
cd /opt/installers/nvidia-driver
sha256sum nvidia-driver-local-repo.deb

# Compare against NVIDIA's published checksums
# https://developer.nvidia.com/cuda-downloads (checksums link)
```

## Future Improvements

1. **Automated checksum verification** during installation
2. **Version compatibility validation** before upgrades
3. **Rollback mechanism** using dpkg snapshots
4. **Centralized installer mirror** for multi-machine deployments
5. **Integration with configuration management** (Puppet, Chef, Salt)

## References

- [NVIDIA Driver Archive](https://www.nvidia.com/Download/Find.aspx)
- [CUDA Toolkit Archive](https://developer.nvidia.com/cuda-toolkit-archive)
- [TensorRT Archive](https://developer.nvidia.com/tensorrt)
- [TensorRT Support Matrix](https://docs.nvidia.com/deeplearning/tensorrt/support-matrix/index.html)
- [PyTorch CUDA Compatibility](https://pytorch.org/get-started/locally/)
- [Ubuntu Unattended-Upgrades](https://help.ubuntu.com/community/AutomaticSecurityUpdates)
