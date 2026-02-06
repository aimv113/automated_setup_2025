# Setup workflow

This document describes the full setup flow, what is automated, and what stays manual. See [Install-system.md](Install-system.md) and [Setup-post-reboot.md](Setup-post-reboot.md) for step-by-step instructions.

---

## Intended workflow

1. **ZeroTier (manual)** – Install and join your network so you can reach the machine (e.g. from HPE iLO).
2. **Ubuntu** – Install Ubuntu Desktop or Server (optionally send SSH keys during Server install).
3. **SSH** – Enable SSH and add your public key to `~/.ssh/authorized_keys` on the server so you can use Terminus (or skip if you sent keys at install).
4. **Clone repo** – On the server: `git clone ... automated_setup_2025`, `cd automated_setup_2025`.
5. **Run playbook** – `ansible-playbook ubuntu-setup.yml -K`. At start you will see:
   - **Network info** (Ethernet/WiFi MACs, IPs) – record these if needed.
   - **Healthchecks.io** URL (optional; Enter to skip).
   - **Boot mode** – 1 = GNOME on boot, 2 = minimal X / king_detector (no GNOME).
   - **Git user.name / user.email** for commits on this machine.
   - **GitHub SSH key** – the playbook generates a key and displays it; add it to GitHub (Settings → SSH and GPG keys → New SSH key), then press Enter to continue.
6. **Reboot** – `sudo reboot`.
7. **Post-reboot verify** – Run `ansible-playbook post-reboot-verify.yml -K -vv` (must pass).
8. **App deploy (optional)** – To deploy king_detector and crane display: `ansible-playbook ~/automated_setup_2025/app-deploy.yml -K -vv` (run from anywhere). See [Setup-post-reboot.md](Setup-post-reboot.md) section 9. Then work through the rest of that checklist (camera settings, etc.).

---

## What’s in the instructions

- **Pre-connection:** ZeroTier (correct URL: zerotier.com), SSH enable, add key to `authorized_keys`.
- **SSH key reminder:** Send keys at Ubuntu install or add Terminus key manually; playbook can deploy keys from `ssh-public-keys.txt`.
- **Post-reboot:** Checklist (verify playbook, Firefox, crontab, VNC, VS Code, data folders, touch screen, camera settings); boot mode (GNOME vs minimal X) noted.
- **Boot mode:** Choice at playbook start; when minimal X, playbook installs xdotool and x11-xserver-utils.

---

## What’s automated

- Keys from `ssh-public-keys.txt` deployed to `~/.ssh/authorized_keys`.
- SSH: port 33412, key-only (PasswordAuthentication no), single-place config (no duplicate lines).
- Git: user.name, user.email, SSH default for GitHub (`url.insteadOf`), GitHub SSH key generated and displayed; you add the key to GitHub once.
- Data folders: `data/`, `data/jpg/`, `data/video/`, `data/jpg/no_hook`, `data/jpg/no_overlay` under `~/code/king_detector` (and in post-reboot-verify).
- Network info (MACs, IPs) printed at playbook start for recording.
- No systemd reboot timer; scheduled reboots via root crontab only (you set this in post-reboot).

---

## What stays manual

- ZeroTier install and join.
- Adding your SSH key at install or before first run (if not using playbook-deployed keys).
- Root crontab (0 6,18 * * * /sbin/reboot and log line).
- Camera website/serving and uploading config (`camera-settings/XNZ-L6320AConfigTOBE.bin`).
- VNC login, VS Code login and extensions, cloning other repos, project venvs, fwupd disable, touch screen calibration (if used).

---

## Target deployment: GNOME vs minimal X

- **Boot mode 1 (GNOME):** Full desktop on boot; standard GDM and desktop workflow.
- **Boot mode 2 (minimal X / king_detector):** Boot to server (no GNOME); run crane display via xinit and wrapper (xdotool, xrandr). Deps `xdotool` and `x11-xserver-utils` are installed by the playbook when you choose this option. The crane-display service and scripts live in the king_detector repo, not in this repo.

---

## Camera settings

Config file in this repo: `camera-settings/XNZ-L6320AConfigTOBE.bin`. Upload/configure and set up website hosting manually; tick off in [Setup-post-reboot.md](Setup-post-reboot.md) when done.
