# Install system

Step-by-step guide to get from bare hardware to a running Ubuntu machine ready for the setup playbook.

---

## 1. BIOS (optional)

**Auto power-on with power:** Power and thermal → auto power on.

---

## 2. Install Ubuntu 24.04

Fresh Server Installation (Recommended)**
Download Ubuntu 24.04 Server, boot from USB. During the installer you can send SSH keys from GitHub — do this to skip the manual key step below.

For the recommended disk layout (ext4 `/data` + btrfs system snapshots) see [PARTITION_LAYOUT_GUIDE.md](PARTITION_LAYOUT_GUIDE.md).


## 3. Reboot before running the playbook.


## 4. Connect via ZeroTier (optional, for remote/iLO access)

Install ZeroTier and join your network:

```bash
curl -s https://install.zerotier.com | sudo bash
sudo zerotier-cli join 8286ac0e475bfb64
```

Approve the new device at [my.zerotier.com](https://my.zerotier.com/network/8286ac0e475bfb64), copy the assigned IP, add it to Terminus.

Update your Mac's hosts file and SSH config:
```bash
ip a
```
Copy to terminus & mac

```bash
sudo nano ~/.ssh/config
ssh-keygen -R <old-ip>    # clear stale host key if needed
```

---

## 5. Install Ansible, clone repo, and run the setup playbook

```bash
sudo apt update && sudo apt upgrade -y && sudo apt install ansible git -y
git clone https://github.com/aimv113/automated_setup_2025.git
cd automated_setup_2025
ansible-playbook ubuntu-setup.yml -K
```

**Standard run (single pass):** prompts for:
- WiFi strategy — press Enter to accept the default (option 1: standard in-kernel drivers, no kernel changes)
- Boot mode: GNOME or minimal X / king_detector
- Git `user.name` / `user.email` and GitHub SSH key (near end of run)
- Healthchecks.io ping URL (optional; press Enter to skip)

**If you chose option 3 (HWE kernel, advanced — RTL8812AU USB WiFi adapter only):**
The playbook installs kernel 6.17 and exits. Reboot (`sudo reboot`), then run the same command again to continue.

If WiFi does not come up after the normal flow, use the dedicated recovery playbook: [WIFI_SETUP.md](WIFI_SETUP.md).

**Duration:** ~20–30 minutes depending on download speed.

---

## 6. Reboot and verify

```bash
sudo reboot
```

Then follow [Setup-post-reboot.md](Setup-post-reboot.md).
