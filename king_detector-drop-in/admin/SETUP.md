# King_detector machine setup (crane display)

This document describes how to set up a machine for king_detector and the crane display **after** the automated_setup_2025 playbooks have been run (ubuntu-setup.yml and post-reboot-verify.yml). That automation already configures the GPU stack, networking (netplan), timezone, data folders, and (if you chose minimal X) xdotool and x11-xserver-utils.

## Prerequisites

- Ubuntu 24.04.
- **automated_setup_2025** has been run through **post-reboot-verify.yml** (machine setup is complete: networking, timezone, data dirs).
- GitHub SSH working for user `lift` (or the deploy user you use) if the script will clone the repo.

## Run the setup script

On the machine (or over SSH), from the king_detector repo root:

```bash
cd ~/code/king_detector   # or clone first: git clone ... king_detector && cd king_detector
sudo ./admin/setup-crane-machine.sh
```

You will be prompted for **machine name** (e.g. Mars2) unless you set it via env:

```bash
MACHINE_NAME=Mars2 sudo -E ./admin/setup-crane-machine.sh
```

If the repo is not yet cloned, the script can clone it. Set the branch with:

```bash
MACHINE_NAME=Mars2 KING_DETECTOR_BRANCH=2.9.0 sudo -E ./admin/setup-crane-machine.sh
```

## What the script does

1. **Clone / ensure repo** – If `~/code/king_detector` is missing, clones from GitHub (branch from `KING_DETECTOR_BRANCH` or prompt).
2. **Machine name** – From prompt or `MACHINE_NAME` env var.
3. **.env** – Creates from `admin/env-file.md` (replacing mars2/Mars2 with machine name) or a fallback template; sets `MODEL_DIR` to `/data/models`.
4. **Directories** – Ensures `/data` and `/data/models`.
5. **Venv and pip** – Creates `.venv` in repo root if missing; installs from `requirementsAutoUbuntu24cuda13.txt`; installs `lap>=0.5.12`.
6. **xinit** – Installs the `xinit` package if missing.
7. **crane-display-standalone.service** – Copies `admin/crane-display-standalone.service` to `/etc/systemd/system/`, enables it (does not start it).
8. **Boot and GDM** – Sets default target to multi-user, disables GDM.
9. **xinitrc-crane** – Makes `admin/xinitrc-crane` executable.
10. **Final message** – Prints the manual steps below.

## After the script: manual steps

1. **Rsync models** (from your Mac):  
   `rsync -avz --progress -e "ssh -p 33412" /Volumes/shell/models/current/ lift@<machine>:/data/models/`

2. **Camera time:** SSH forward the camera, open a browser, set the camera time to match the computer:  
   `ssh -p 33412 -L 8080:192.168.1.100:80 lift@<machine>` then open `http://localhost:8080`.  
   Ensure the timezone of the remote machine and camera match (timezone was set by post-reboot-verify).

3. **SSH config:** Add the host to `~/.ssh/config` on your laptop (e.g. `Host Mars2`).

4. **Start crane** (on the machine when ready):  
   `sudo systemctl start crane-display-standalone.service`  
   `sudo journalctl -u crane-display-standalone -f`

## Troubleshooting

- **xinit missing** – The script installs the `xinit` package; if you hit errors before that, run `sudo apt-get install -y xinit` and re-run.
- **lap missing** – The script runs `pip install "lap>=0.5.12"`; if you added it later, run that inside the repo venv and restart the service.
- **Service path / user** – `admin/crane-display-standalone.service` uses `/home/lift` and `lift`; if your deploy user is different, edit the unit file before running the script or adjust the script’s `DEPLOY_USER`.
- **Clone fails** – Ensure GitHub SSH works for the deploy user (e.g. `ssh -T git@github.com` as that user).
