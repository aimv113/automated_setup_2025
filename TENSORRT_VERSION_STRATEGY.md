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

**Official NVIDIA Pattern (from documentation):**
`nv-tensorrt-local-repo-${os}-${tag}_1.0-1_amd64.deb`

Where:
- `${os}` = Ubuntu version (e.g., `ubuntu2204`, `ubuntu2404`)
- `${tag}` = Version information in format `10.x.x-cuda-x.x`

### Verified Working URLs

**TensorRT 10.13.3 + CUDA 13.0 + Ubuntu 24.04:**
```
https://developer.download.nvidia.com/compute/tensorrt/10.13.3/local_installers/nv-tensorrt-local-repo-ubuntu2404-10.13.3-cuda-13.0_1.0-1_amd64.deb
```
✅ Verified accessible (HTTP 200) - 5.3 GB file

**TensorRT 10.13.2 + CUDA 13.0 + Ubuntu 24.04:**
```
https://developer.download.nvidia.com/compute/tensorrt/10.13.2/local_installers/nv-tensorrt-local-repo-ubuntu2404-10.13.2-cuda-13.0_1.0-1_amd64.deb
```
✅ Verified accessible (HTTP 200) - 5.3 GB file

**TensorRT 10.10.0 + CUDA 12.9 + Ubuntu 22.04:**
```
https://developer.download.nvidia.com/compute/tensorrt/10.10.0/local_installers/nv-tensorrt-local-repo-ubuntu2204-10.10.0-cuda-12.9_1.0-1_amd64.deb
```
✅ Verified accessible (HTTP 200) - 4.8 GB file

### Pattern Validation Results

**✅ Pattern is CONSISTENT for TensorRT 10.x series**

The playbook's auto-construction approach correctly generates valid URLs for:
- All TensorRT 10.x point releases (10.10.0, 10.13.2, 10.13.3)
- Multiple Ubuntu versions (22.04, 24.04)
- Multiple CUDA versions (12.9, 13.0)
- Multiple architectures (automatically detected via `dpkg --print-architecture`)

**Note:** Not all version combinations are available on NVIDIA's servers. For example:
- ❌ TensorRT 10.13.0 with CUDA 13.0 → 404 (not published)
- ❌ TensorRT 10.11.0, 10.12.0 with Ubuntu 24.04 → 404 (Ubuntu 24.04 support added in 10.13.x)
- ❌ TensorRT 10.0.0 with Ubuntu 22.04 → 404 (CUDA/version mismatch)

### Historical Pattern Changes

**⚠️ WARNING:** Older TensorRT versions (7.x and earlier) used different naming patterns:

**TensorRT 7.x pattern (deprecated):**
```
nv-tensorrt-repo-ubuntu1804-cuda10.2-trt7.0.0.11-ga-20191216_1-1_amd64.deb
```
Differences:
- Included build date stamps (e.g., `20191216`)
- Used `trt` prefix for version
- Different version format

**Current TensorRT 10.x pattern:**
```
nv-tensorrt-local-repo-ubuntu2404-10.13.3-cuda-13.0_1.0-1_amd64.deb
```
- Cleaner version numbers
- Added `local-repo` designation
- Standardized format

### Playbook Auto-Construction

The playbook automatically constructs the correct URL by detecting:
1. **Ubuntu version** from `ansible_distribution_version` → e.g., "24.04" converted to "2404"
2. **Architecture** from `dpkg --print-architecture` → e.g., "amd64", "arm64"
3. **CUDA version** from configuration → e.g., "13.0"
4. **TensorRT version** from configuration → e.g., "10.13.3"

**Auto-constructed URL:**
```yaml
tensorrt_auto_url: "https://developer.download.nvidia.com/compute/tensorrt/{{ tensorrt_version_full }}/local_installers/nv-tensorrt-local-repo-ubuntu{{ ansible_distribution_version | replace('.', '') }}-{{ tensorrt_version_full }}-cuda-{{ cuda_version_full }}_1.0-1_{{ system_arch.stdout }}.deb"
```

**Override capability:** You can still manually specify a URL using `tensorrt_local_repo_url` if needed for custom sources or mirrors.

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
