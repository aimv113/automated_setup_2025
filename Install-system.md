# Install system

## 0. Before Ubuntu: access and SSH

Do this first so you can get from HPE iLO (or console) to a usable SSH session.

### a. BIOS (optional)
**Auto power on with power:** Power and thermal → auto power on.



## 1. Ubuntu

**Option A: Fresh Server Installation (Recommended)**  
Download Ubuntu 24.04 Server, boot from USB

Make sure to expand home area to 4+ TB
<img width="798" height="486" alt="image" src="https://github.com/user-attachments/assets/b91ae766-74e0-4882-ad93-b41cf6421497" />

<img width="290" height="112" alt="image" src="https://github.com/user-attachments/assets/3396e9e5-dd4f-4c0f-ac42-a87571b976ff" />

SSH keys from GIT

**Option B: Server + Desktop (Advanced)**  
If you installed Ubuntu Server, you can add the desktop environment:

```bash
sudo apt update
sudo apt install ubuntu-desktop -y
sudo systemctl set-default graphical.target
sudo systemctl get-default   # should output: graphical.target
```

**Note:** After installing the desktop, reboot before running the playbook if needed.

---

## 2. Configure SSH service (for remote access) if using ubuntu server this is already done as a server install step - where keys are loaded from github

Enable SSH for remote management:

```bash
sudo systemctl start ssh
sudo systemctl enable ssh
```

Get your machine's IP address (e.g. via ZeroTier or LAN):

```bash
hostname -I
```

Connect from your local machine (use the port you set, e.g. 33412 if you locked down early):

```bash
ssh -p 33412 username@<ip-address>
```

Or if still on default port 22:

```bash
ssh username@<ip-address>
```

---

### c. SSH: enable and add your key - *not needed if installing server*

On the server, enable SSH and add your **public key** so you can use Terminus (or another client) for the rest of the setup:

- Enable SSH: `sudo systemctl start ssh` and `sudo systemctl enable ssh`.
- Add your key: on the server run `nano ~/.ssh/authorized_keys` and paste your Terminus (or other) public key. If you prefer to edit SSH daemon settings first, run `nano /etc/ssh/sshd_config` (e.g. set Port 33412 if you want).
- After any SSH config change: `sudo systemctl restart ssh` or reboot.

**Reminder:** If you install **Ubuntu Server**, you can **Send SSH keys** during the installer so the first user already has your key in `~/.ssh/authorized_keys`. Otherwise add the key manually as above. The playbook can also add keys from the repo for you (see step 4); ensure `ssh-public-keys.txt` in the repo contains the keys you want deployed.

---

### b. Connection: ZeroTier (manual)

Install and join ZeroTier so you can reach the machine from your laptop (e.g. from HPE iLO). Use the **correct** URL (zerotier, not zeroteir):

```bash
curl -s https://install.zerotier.com | sudo bash
sudo zerotier-cli join 8286ac0e475bfb64
```

(Get your network ID from the ZeroTier dashboard.)

### SSH into machine

## 3. Install Ansible and clone repository

```bash
sudo apt update
sudo apt install ansible git -y
git clone https://github.com/aimv113/automated_setup_2025.git
cd automated_setup_2025/
```

---

## 4. Run the setup playbook

```bash
ansible-playbook ubuntu-setup.yml -K
```

**Flags:** `-K` = sudo password; `-vv` = verbose (optional).

**At the start the playbook will:**
- Show **network info** (Ethernet and WiFi MACs, IPs) for you to record.
- Prompt for **Healthchecks.io** ping URL (optional; press Enter to skip).
- Prompt for **boot mode:** 1 = GNOME on boot, 2 = minimal X / king_detector (no GNOME).
- Prompt for **Git user.name** and **user.email** (for commits on this machine).
- Generate a **GitHub SSH key** and display it; you will be prompted to add it to GitHub (Settings → SSH and GPG keys → New SSH key), then press Enter to continue.

**What the playbook does:**
- Deploys keys from `ssh-public-keys.txt` in the repo to `~/.ssh/authorized_keys` and configures SSH on port 33412 with **password authentication disabled** (key-only).
- Pre-flight checks, system update, tools, firewall, Git (SSH default, GitHub key), data folders, Tailscale, RealVNC, VS Code, display/VM detection, NVIDIA driver, CUDA, TensorRT, Docker, Python, Healthchecks, ML environment.
- **Scheduled reboots** are **not** installed by the playbook; use root crontab (see [Post boot instructions](Setup-post-reboot.md)).
- **Git/SSH:** The playbook sets `~/.ssh/config` so `github.com` uses `~/.ssh/id_ed25519_github`. After adding the key to GitHub, `git clone`/`git push` should work without running `ssh-agent` or `ssh-add`. If you still get errors (e.g. in some GUI or non-interactive shells), run: `eval "$(ssh-agent -s)"` then `ssh-add ~/.ssh/id_ed25519_github`.

**If you need to lock down SSH (port 33412, key-only) before the first playbook run**, do that manually (e.g. edit `/etc/ssh/sshd_config` and `~/.ssh/authorized_keys`, then restart ssh). Otherwise the playbook does it for you after adding keys from the repo.

**Duration:** ~20–30 minutes (depends on downloads).

---

## 5. Reboot and verify

After the setup completes, reboot to load the NVIDIA driver:

```bash
sudo reboot
```

Then follow [Post boot instructions](Setup-post-reboot.md).
