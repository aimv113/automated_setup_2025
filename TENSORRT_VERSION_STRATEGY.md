# TensorRT Version Locking Strategy

## Problem Statement

When NVIDIA releases TensorRT 11, they will likely **remove TensorRT 10.13 from their network repository**. This would break automated installations that rely on specific versions.

## Solution: Local Repository + dpkg hold

The playbook now uses a **dual-method approach** with local repository as default:

### Default Configuration (Recommended)

```yaml
tensorrt_local_repo_url: "https://developer.download.nvidia.com/compute/tensorrt/10.13.3/local_installers/nv-tensorrt-local-repo-ubuntu2404-10.13.3-cuda-13.0_1.0-1_amd64.deb"
```

**Benefits:**
- ✅ **Version guaranteed forever** - Local repo contains only TensorRT 10.13.3
- ✅ **Works after TensorRT 11 release** - Not affected by network repo changes
- ✅ **Safe with `apt upgrade`** - `dpkg hold` prevents upgrades
- ✅ **No silent failures** - Explicit version control

### Alternative: Network Repository

```yaml
tensorrt_local_repo_url: ""  # Empty string
```

**Behavior:**
- ✅ Uses CUDA network repository (simpler while 10.13 available)
- ✅ Checks if TensorRT 10.13.* exists in repo
- ❌ **FAILS IMMEDIATELY** if version not found (no silent installation of wrong version)
- ✅ Provides clear error message with instructions

## Version Locking Mechanism

Regardless of installation method, the playbook uses `dpkg hold` to lock the version:

```bash
# After installation, verify:
dpkg --get-selections | grep -E "(tensorrt|libnvinfer)" | grep hold

# Output shows:
tensorrt-dev                hold
tensorrt-libs               hold
libnvinfer10                hold
libnvinfer-dev              hold
libnvinfer-headers-dev      hold
libnvinfer-plugin10         hold
libnvonnxparsers10          hold
python3-libnvinfer          hold
python3-libnvinfer-dev      hold
```

## Safe to Run apt upgrade

```bash
sudo apt update
sudo apt upgrade

# TensorRT packages will be "kept back":
The following packages have been kept back:
  tensorrt-dev tensorrt-libs libnvinfer10 ...
```

**TensorRT will stay at 10.13 permanently until you manually unhold the packages.**

## Compatibility Matrix

| Component | Version | Notes |
|-----------|---------|-------|
| Ubuntu | 24.04 (Noble) | LTS release |
| CUDA | 13.0 | Latest CUDA release (August 2025) |
| TensorRT | 10.13.3 | Latest 10.13 point release |
| NVIDIA Driver | 580+ | Required for CUDA 13.0 |

## URL Pattern Reference

### TensorRT Local Repository URLs

**Format:**
```
https://developer.download.nvidia.com/compute/tensorrt/{VERSION}/local_installers/nv-tensorrt-local-repo-{OS}-{VERSION}-cuda-{CUDA}_1.0-1_amd64.deb
```

**Examples:**

CUDA 13.0:
```
https://developer.download.nvidia.com/compute/tensorrt/10.13.3/local_installers/nv-tensorrt-local-repo-ubuntu2404-10.13.3-cuda-13.0_1.0-1_amd64.deb
```

CUDA 12.9:
```
https://developer.download.nvidia.com/compute/tensorrt/10.13.3/local_installers/nv-tensorrt-local-repo-ubuntu2404-10.13.3-cuda-12.9_1.0-1_amd64.deb
```

## When TensorRT 11 is Released

**Scenario:** NVIDIA releases TensorRT 11 and removes 10.13 from network repository.

**With Local Repo (Default):**
```yaml
tensorrt_local_repo_url: "https://developer.download.nvidia.com/compute/tensorrt/10.13.3/..."
```
✅ **Continues to work** - Downloads from permanent local repo file
✅ **Version guaranteed** - Always installs 10.13.3

**With Network Repo:**
```yaml
tensorrt_local_repo_url: ""
```
❌ **Fails immediately** with error message:
```
TensorRT 10.13.* not found in network repository!

When newer TensorRT versions are released, NVIDIA removes old versions from the network repo.

SOLUTION: Download the TensorRT 10.13.* local repo package from:
https://developer.nvidia.com/tensorrt

Then set tensorrt_local_repo_url variable to the download URL or local file path.
```

**No silent installation of TensorRT 11** - Playbook will not proceed.

## Manual Version Upgrade (If Needed)

If you later want to upgrade to TensorRT 11:

```bash
# 1. Unhold packages
sudo apt-mark unhold tensorrt-dev tensorrt-libs libnvinfer10 libnvinfer-dev \
  libnvinfer-headers-dev libnvinfer-plugin10 libnvonnxparsers10 \
  python3-libnvinfer python3-libnvinfer-dev

# 2. Update playbook to use TensorRT 11 local repo
# tensorrt_local_repo_url: "https://developer.download.nvidia.com/compute/tensorrt/11.x.x/..."

# 3. Re-run playbook
ansible-playbook ubuntu-setup.yml -K -vv

# 4. Packages will be held at new version
```

## Testing the Configuration

### Verify TensorRT Installation
```bash
# Check installed version
dpkg -l | grep -E "(tensorrt|libnvinfer)" | grep -v "^rc"

# Verify packages are held
dpkg --get-selections | grep -E "(tensorrt|libnvinfer)" | grep hold

# Test upgrade safety
sudo apt update
sudo apt upgrade --dry-run | grep tensorrt
```

### Verify CUDA/TensorRT Compatibility
```bash
# Check CUDA version
nvcc --version

# Check TensorRT version in Python
python3 << EOF
import tensorrt as trt
print(f"TensorRT version: {trt.__version__}")
EOF
```

## Summary

This strategy provides:

1. ✅ **Version Guarantee** - Local repo ensures 10.13.3 availability forever
2. ✅ **Upgrade Safety** - `dpkg hold` prevents accidental upgrades
3. ✅ **No Silent Failures** - Explicit errors if version unavailable
4. ✅ **Production Ready** - Reliable for automated deployments
5. ✅ **Flexible** - Can switch between local and network methods

**Default: Local repository method for guaranteed version control.**
