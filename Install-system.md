
**Option A: Fresh Installation (Recommended)**
Download Ubuntu 24.04 Desktop from [ubuntu.com](https://ubuntu.com/download/desktop) and install with default GNOME desktop.

**Option B: Server + Desktop (Advanced)**
If you installed Ubuntu Server, you can add the desktop environment:
```bash
sudo apt update
sudo apt install ubuntu-desktop -y

# Set system to boot into graphical desktop by default
sudo systemctl set-default graphical.target

# Verify the default target
sudo systemctl get-default
# Should output: graphical.target
```

**Note:** After installing the desktop, you may want to reboot before running the playbook to ensure the graphical environment is fully initialized.

### 2. Configure SSH Service (For Remote Access)

Enable SSH for remote management:
```bash
sudo systemctl start ssh
sudo systemctl enable ssh
```

Get your machine's IP address:
```bash
hostname -I
```

Connect from your local machine:
```bash
ssh username@<ip-address>
```

# send ssh keys!!

**Optional: Lock Down SSH (Recommended after key exchange)**

After copying your SSH key to the remote machine, secure SSH:
```bash
sudo ufw allow 33412/tcp && \
if systemctl list-unit-files | grep -q '^ssh.socket'; then \
  sudo systemctl disable --now ssh.socket && \
  sudo systemctl mask ssh.socket && \
  sudo systemctl enable --now ssh.service; \
fi && \
sudo sed -i '/^\s*Port\s\+[0-9]\+/d' /etc/ssh/sshd_config && \
sudo sed -i '1i Port 33412' /etc/ssh/sshd_config && \
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
sudo sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config && \
sudo sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
sudo systemctl daemon-reload && \
sudo systemctl restart ssh && \
sudo systemctl status ssh --no-pager
```

This will:
- Change SSH port to 33412
- Disable password authentication
- Enable key-only authentication

### 3. Install Ansible and Clone Repository

```bash
sudo apt update
sudo apt install ansible git -y
git clone https://github.com/aimv113/automated_setup_2025.git
cd automated_setup_2025/
```

### 4. Run the Setup Playbook

```bash
ansible-playbook ubuntu-setup.yml -K
```

**Flags:**
- `-K`: Prompts for sudo password
- `-vv`: Verbose output (optional, but helpful for troubleshooting)

**Interactive Prompt:**
The playbook will prompt you to create a Healthchecks.io URL (optional monitoring):
- Create a free account at https://healthchecks.io and paste the ping URL when prompted
- Or press **Enter** to skip healthcheck monitoring

**What Happens:**
- ✅ Pre-flight validation (disk space, network)
- ✅ Downloads NVIDIA driver 580.95.05, CUDA 13.0, TensorRT 10.13.3 to `/opt/installers/`
- ✅ Installs entire GPU stack from local repositories
- ✅ Applies four layers of protection (dpkg hold, unattended-upgrades blacklist, APT preferences)
- ✅ Creates version manifest and SHA-256 checksums
- ✅ Configures Docker, Tailscale, RealVNC, VS Code
- ✅ Sets up Python ML environment
- ✅ Configures daily auto-reboot at 6 AM

**Duration:** ~20-30 minutes (depends on internet speed for initial downloads)

### 5. Reboot and Verify

After the initial setup completes, **reboot the system** to load the NVIDIA driver:

```bash
sudo reboot
```

Move onto [Post boot instructions](Setup-post-reboot.md)