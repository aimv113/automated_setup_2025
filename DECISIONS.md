# Decisions

Ongoing log of decisions made and why.

## 2026-02

- **Reboot via cron only, not systemd:** User wants twice-daily reboots at 6 and 18; cron is simpler for that. Playbook no longer uses a systemd daily-reboot timer. The **main playbook (ubuntu-setup.yml) now installs** the scheduled reboot automatically: root cron entries for `0 6,18 * * * /sbin/reboot` and a matching log line so reboots happen at 06:00 and 18:00 without any manual crontab edit.

- **SSH password lock-down mandatory:** After deploying keys from `ssh-public-keys.txt`, the playbook must set `PasswordAuthentication no` (and related). Not optional; ensures key-only auth once keys are in place.

- **Boot mode prompt at playbook start:** User chooses GNOME on boot vs minimal X / king_detector (xdotool) approach. Stored as `boot_mode`; used to install xdotool/x11-xserver-utils when minimal_x and to tailor docs.

- **Data folders created by default:** `data/`, `data/jpg/`, `data/video/`, `data/jpg/no_hook`, `data/jpg/no_overlay` created under a configurable path (default `~/`, so `~/data` sits next to `~/code`) in the normal run. No longer optional.

- **Network info at Ansible start:** Playbook displays Ethernet adapters (MAC, IP, connected) and WiFi MAC(s) at start so the user can record them (e.g. for ZeroTier or documentation).

- **SSH config single-place:** Each option in `sshd_config` (Port, PasswordAuthentication, etc.) appears only once. Use lineinfile or a single block; do not append a block that leaves commented defaults (e.g. `# Port 22`) at top and active values at bottom.

- **Ongoing CHANGELOG and DECISIONS at repo root:** This file and CHANGELOG.md live in repo root and are updated whenever script changes or decisions are made. 2026-02/ holds the planned batch; root files are the living project log.

- **Git setup in playbook:** Set git user.name and user.email; use SSH by default for GitHub (`url.insteadOf`); generate ed25519 key for the remote machine; display public key and prompt user to add it to GitHub so the machine can pull/push via SSH.

- **README note for ssh-public-keys.txt:** One sentence in README that this file is used by the playbook to deploy keys to `authorized_keys`. File itself left as-is (key only, no comment).

- **Machine setup complete after post-reboot-verify:** “Machine setup” is finished when `post-reboot-verify.yml` has passed. That playbook now includes **networking** (NetworkManager + netplan: default-route interface DHCP, other UP ethernet interfaces static 192.168.1.200, .201, …; optional WiFi SSID; 50-cloud-init removed to avoid conflicts) and **timezone** (e.g. America/Chicago, configurable). App/program setup (king_detector venv, crane-display service, .env, etc.) lives in the king_detector repo and is run from there via a setup script; this repo no longer includes app-deploy.yml.

- **NetworkManager + netplan + WiFi (2.4/5) pattern:** Networking uses NetworkManager as netplan renderer (not systemd-networkd). Install NetworkManager; write **01-network-manager.yaml** (renderer only) and **99-machine-network.yaml** (ethernets); apply netplan. WiFi: create two NM profiles (2.4 GHz band bg priority 100, 5 GHz band a priority 10) without bringing them up; run idempotent **modify** every time to keep settings aligned; optionally connect only when SSID is visible (non-fatal). Default SSID OFFICEGST; playbook succeeds even if SSID absent; autoconnect takes over when network appears. Do not restart NetworkManager during SSH-only bootstrap.

*(Implementation completed 2026-02; see CHANGELOG.md for script changes.)*
