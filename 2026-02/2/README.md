# App deploy (king_detector)

Third playbook: deploy king_detector and get the machine ready to run the crane display. **Run only after `post-reboot-verify.yml` has run and passed.**

## When to run

1. `ansible-playbook ubuntu-setup.yml -K -vv`
2. Reboot: `sudo reboot`
3. `ansible-playbook post-reboot-verify.yml -K -vv` (must pass)
4. **Then:** `ansible-playbook 2026-02/2/app-deploy.yml -K -vv`

Run from the repo root (e.g. `~/automated_setup_2025` or your clone path).

## What it does

- **Prompts:** Asks for build version (branch, e.g. `2.9.0`) and machine name (e.g. `Mars2`).
- **Packages:** Installs `xdotool`, `x11-xserver-utils` (for crane fullscreen wrapper).
- **Ethernet:** Detects interfaces that are UP but have no internet; assigns static IPs (192.168.1.200, 192.168.1.201, …) via netplan `99-camera-static.yaml`. Leaves DHCP/internet interfaces unchanged.
- **Clone:** Clones king_detector from GitHub (SSH) at the requested branch into `~/code/king_detector`.
- **.env:** Builds `.env` from the repo’s `admin/env-file.md`, replacing hardcoded machine names (e.g. mars2) with the name you gave. Fallback template if that file is missing.
- **Data/models:** Ensures `~/data` and `~/data/models` exist.
- **Venv:** Creates `.venv` in the repo and installs from `requirementsAutoUbuntu24cuda13.txt`.
- **Crane service:** Installs and enables `crane-display-standalone.service`, sets default target to multi-user, disables GDM (no graphical login).
- **Timezone:** Sets `America/Chicago` (Houston).
- **Final message:** Prints manual steps: rsync models, camera time sync (SSH forward), add host to `~/.ssh/config`, start crane service.

## Prerequisites

- Post-reboot-verify has been run and passed.
- GitHub SSH is working for user `lift` (e.g. `ssh-add` run for the GitHub key) so `git clone git@github.com:davematthewsband/king_detector.git` works.

## Manual steps after run

1. **Rsync models** (from your Mac):  
   `rsync -avz --progress -e "ssh -p 33412" /Volumes/shell/models/current/ lift@<machine>:~/data/models/`
2. **Camera time:** SSH forward camera, open browser, set camera time to match computer.
3. **SSH config:** Add the host to `~/.ssh/config` (e.g. `Host Mars2`).
4. **Start crane:** On the machine: `sudo systemctl start crane-display-standalone.service`; logs: `sudo journalctl -u crane-display-standalone -f`.

## Files

- `app-deploy.yml` – main playbook
- `templates/crane-display-standalone.service.j2` – systemd unit
- `templates/99-camera-static.yaml.j2` – netplan fragment for camera interfaces
- `templates/env_king_detector.j2` – fallback .env when `admin/env-file.md` is missing
