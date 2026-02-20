# Setup workflow

This document describes the full setup flow, what is automated, and what stays manual. See [Install-system.md](Install-system.md) and [Setup-post-reboot.md](Setup-post-reboot.md) for step-by-step instructions.

---

## Intended workflow

1. **ZeroTier (manual)** – Install and join your network so you can reach the machine (e.g. from HPE iLO).
2. **Ubuntu** – Install Ubuntu Desktop or Server (optionally send SSH keys during Server install).
3. **SSH** – Enable SSH and add your public key to `~/.ssh/authorized_keys` on the server so you can use Terminus (or skip if you sent keys at install).
4. **Clone repo** – On the server: `git clone ... automated_setup_2025`, `cd automated_setup_2025`.
5. **Run playbook (pass 1)** – `ansible-playbook ubuntu-setup.yml -K`. Early in the run it installs/pins the HWE kernel baseline (`6.17.0-14-generic`) and exits if that kernel is not active yet.
6. **Reboot** – `sudo reboot`.
7. **Run playbook again (pass 2)** – `ansible-playbook ubuntu-setup.yml -K`.
   - If kernel baseline is still not active, the playbook exits before asking most interactive questions.
   - Once kernel baseline is active, it prompts for:
   - **Boot mode** – 1 = GNOME on boot, 2 = minimal X / king_detector (no GNOME).
   - **Deployment mode + WiFi readiness decision** (runs early; option to skip WiFi enforcement for test/check runs).
   - Near the end of the run, it prompts for:
   - **Healthchecks.io** URL (optional; Enter to skip).
   - Near completion, it displays **network info** (Ethernet/WiFi MACs, IPs) for final recording.
   - **Git user.name / user.email** for commits on this machine (later in run).
   - **GitHub SSH key** – standard `~/.ssh/id_ed25519` key is generated (if missing) and displayed later in the run; add it to GitHub, then continue.
8. **Reboot** – `sudo reboot`.
9. **Post-reboot verify** – Run `ansible-playbook post-reboot-verify.yml -K -vv` (must pass). Machine setup is then **complete** (networking and timezone are set by this playbook).
10. **King_detector setup** – Run the setup script in the king_detector repo (see that repo’s admin/SETUP.md). See [Setup-post-reboot.md](Setup-post-reboot.md) section 9. Then work through the rest of that checklist (camera settings, etc.).

---

## What’s in the instructions

- **Pre-connection:** ZeroTier (correct URL: zerotier.com), SSH enable, add key to `authorized_keys`.
- **SSH key reminder:** Send keys at Ubuntu install or add Terminus key manually; playbook can deploy keys from `ssh-public-keys.txt`.
- **Post-reboot:** Checklist (verify playbook, Firefox, crontab, VNC, VS Code, data folders, camera settings); touch screen is mostly verify/calibrate only.
- **Boot mode:** Choice at playbook start; when minimal X, playbook installs xdotool and x11-xserver-utils.

---

## What’s automated

- Keys from `ssh-public-keys.txt` deployed to `~/.ssh/authorized_keys`.
- SSH: port 33412, key-only (PasswordAuthentication no), single-place config (no duplicate lines).
- Git: user.name, user.email, SSH default for GitHub (`url.insteadOf`), standard `~/.ssh/id_ed25519` key generated/displayed if missing; you add the key to GitHub once.
- Data folders: `data/`, `data/jpg/`, `data/video/`, `data/jpg/no_hook`, `data/jpg/no_overlay`, `data/ad_hoc/`, `data/ad_hoc/jpg/`, `data/ad_hoc/video/` under `~/` (post-reboot-verify).
- Network info (MACs, IPs) printed near playbook completion for recording.
- Touchscreen base setup near end of `ubuntu-setup.yml` (packages + `/etc/X11/xorg.conf.d/99-touchscreen.conf`).
- **Networking (NetworkManager + netplan):** post-reboot-verify installs NetworkManager, `rfkill`, and `iw`, then writes a single netplan with renderer NetworkManager (default-route interface DHCP, other ethernet interfaces static 192.168.1.200, .201, …; optional WiFi SSID). For open WiFi, set `wifi-sec.key-mgmt none` and do not pin BSSID. Removes 50-cloud-init to avoid conflicts.
- **Timezone:** post-reboot-verify sets timezone (default America/Chicago).
- No systemd reboot timer; scheduled reboots via root crontab only (playbook installs this).

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
