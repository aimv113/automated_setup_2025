# Decisions

Ongoing log of decisions made and why.

## 2026-02

- **Reboot via cron only, not systemd:** User wants twice-daily reboots at 6 and 18; cron is simpler for that. Playbook no longer installs the systemd daily-reboot timer; root crontab is the only scheduled reboot mechanism. Avoids duplicate mechanism at 6 AM.

- **SSH password lock-down mandatory:** After deploying keys from `ssh-public-keys.txt`, the playbook must set `PasswordAuthentication no` (and related). Not optional; ensures key-only auth once keys are in place.

- **Boot mode prompt at playbook start:** User chooses GNOME on boot vs minimal X / king_detector (xdotool) approach. Stored as `boot_mode`; used to install xdotool/x11-xserver-utils when minimal_x and to tailor docs.

- **Data folders created by default:** `data/`, `data/jpg/`, `data/video/`, `data/jpg/no_hook`, `data/jpg/no_overlay` created under a configurable path (e.g. `~/code/king_detector`) in the normal run. No longer optional.

- **Network info at Ansible start:** Playbook displays Ethernet adapters (MAC, IP, connected) and WiFi MAC(s) at start so the user can record them (e.g. for ZeroTier or documentation).

- **SSH config single-place:** Each option in `sshd_config` (Port, PasswordAuthentication, etc.) appears only once. Use lineinfile or a single block; do not append a block that leaves commented defaults (e.g. `# Port 22`) at top and active values at bottom.

- **Ongoing CHANGELOG and DECISIONS at repo root:** This file and CHANGELOG.md live in repo root and are updated whenever script changes or decisions are made. 2026-02/ holds the planned batch; root files are the living project log.

- **Git setup in playbook:** Set git user.name and user.email; use SSH by default for GitHub (`url.insteadOf`); generate ed25519 key for the remote machine; display public key and prompt user to add it to GitHub so the machine can pull/push via SSH.

- **README note for ssh-public-keys.txt:** One sentence in README that this file is used by the playbook to deploy keys to `authorized_keys`. File itself left as-is (key only, no comment).

*(Implementation completed 2026-02; see CHANGELOG.md for script changes.)*
