# Final plan: setup instructions and automation (2026-02)

**Overview:** Improve setup instructions (ZeroTier-first flow, SSH key reminder, post-reboot checklist with camera settings), automate Terminus key deployment, Git setup with SSH and GitHub key, ongoing changelog/decisions at repo root, and all documented decisions below. This document is the single source of truth for implementation.

**How to use this plan:** Work through the **Implementation order** section below, then implement each area (Instructions, Automation, Docs, Repo root files). When implementing, update root **CHANGELOG.md** and **DECISIONS.md** with what was done and why.

---

## Implementation order

1. **Repo root (first):** Create **CHANGELOG.md** and **DECISIONS.md** in repo root; add initial entries (e.g. "2026-02: Plan finalized; implementation in progress" and decisions from "Decisions and new requirements").
2. **ubuntu-setup.yml:** Remove systemd reboot section; add network info at start; add healthchecks + boot-mode prompts; add Git section (user.name, user.email, SSH default, generate key, display key, pause); fix SSH block (deploy keys from file, single-place config, PasswordAuthentication no); add data-folders creation (configurable path). Run Git and key tasks as `ssh_user` (become_user / delegate or run before become).
3. **post-reboot-verify.yml (if used for data folders):** Add task(s) to create data/jpg/video/no_hook/no_overlay when path exists, or rely on ubuntu-setup if path is known.
4. **Install-system.md:** Rewrite section 0 (ZeroTier + SSH first); SSH key reminder; step 4 note (playbook adds keys + lock-down); replace "Optional: Lock Down SSH" with short note; mention Git/SSH key prompt and network info at start.
5. **Setup-post-reboot.md:** Restructure as checklist; items 1–12 and boot mode; exact crontab lines; touch screen note for server + xinit; camera settings; data folders (created by default or manual).
6. **SETUP_WORKFLOW.md:** New file with full workflow, boot mode, automated vs manual, camera and data folders; link from README.
7. **README.md:** One-line pointer to SETUP_WORKFLOW.md; one sentence that `ssh-public-keys.txt` is used by the playbook.
8. **CHANGELOG.md / DECISIONS.md:** Append entries for each change and decision as you implement.

---

## Decisions and new requirements (locked in)

- **Reboot:** Use cron only; remove systemd daily-reboot timer from the playbook. Root crontab (6 and 18) is the only scheduled reboot mechanism.
- **SSH password lock-down:** Mandatory. Playbook must set `PasswordAuthentication no` (and related) after deploying keys; not optional.
- **README note for ssh-public-keys.txt:** Yes. Add one sentence in README that this file is used by the playbook to deploy keys to `authorized_keys`. Leave **ssh-public-keys.txt** file as-is (key only, no comment in the file).
- **Boot mode prompt at start of playbook:** Add an interactive prompt (same style as the Healthchecks URL prompt) near the start: "Do you want GNOME to open on boot, or the minimal X / king_detector approach (boot to non-GNOME, xdotool-style)?" Store choice (e.g. `boot_mode: gnome` | `boot_mode: minimal_x`). Use it to tailor instructions or later steps (e.g. when `minimal_x`: ensure xdotool and x11-xserver-utils are installed by default, and document target use case in SETUP_WORKFLOW / post-reboot).
- **SETUP_WORKFLOW / target use case:** Same as above – the boot mode choice is the "option when they're setting up" (like healthchecks); document both paths (GNOME on boot vs minimal X / king_detector) in SETUP_WORKFLOW based on that choice.
- **Data folders:** Always created by default in the normal run of the playbook (or post-reboot-verify). Add task(s) to create `data/`, `data/jpg/`, `data/video/`, `data/jpg/no_hook`, `data/jpg/no_overlay` under a configurable path (e.g. default `~/code/king_detector` or a variable). No longer optional.
- **Network info at Ansible start:** At playbook start (e.g. before or right after the healthchecks/boot-mode prompts), output for the user to record: Ethernet adapters (MAC address, current IP, connected or not) and MAC address of any WiFi interface. Use `ip link` / `ip addr` (or similar) and display formatted (e.g. in a debug task or a small script that prints to stdout).
- **SSH config not messy:** Ensure each option in `/etc/ssh/sshd_config` (Port, PasswordAuthentication, PubkeyAuthentication, PermitRootLogin) appears only once. Do not append a block that leaves earlier defaults (e.g. `# Port 22`) in place and adds duplicates at the end. Use lineinfile to set/update the existing directive in place, or a single managed block that replaces/omits the defaults so the file has one clear set of values (e.g. Port 33412, PasswordAuthentication no, etc.). Leave **ssh-public-keys.txt** as-is (key only).
- **Ongoing changelog and decision log at repo root:** Create and maintain two files in the **root** of this codebase: (1) **CHANGELOG.md** – ongoing log of what changes were made to the script(s), when, and where (e.g. "2026-02-xx: ubuntu-setup.yml – removed systemd reboot timer; added Git SSH key generation"). (2) **DECISIONS.md** – ongoing log of what decisions were made and why (e.g. "Reboot via cron only – so we can have twice-daily (6 and 18) without maintaining systemd timer; user preference."). These are living docs; update them when implementing and whenever future decisions or script changes happen.
- **Git setup in playbook (SSH default, key for GitHub):** In **ubuntu-setup.yml** add a section (e.g. after Tools or after SSH) that: (1) Sets **git user.name** and **git user.email** for the `ssh_user` (prompt at start like healthchecks, or use variables). (2) Sets Git to use **SSH instead of HTTPS** by default: `git config --global url."git@github.com:".insteadOf "https://github.com/"` so clones/pushes/pulls use SSH. (3) Generates a **secure SSH key** for Git (e.g. ed25519) for the remote machine, in `~/.ssh/` for `ssh_user`, with a distinct name (e.g. `id_ed25519_github`) so it does not overwrite the key used for login. (4) **Displays the public key** to the user (e.g. cat the .pub file in a debug or shell task so it is printed to stdout). (5) **Prompts the user** (pause task) with instructions: "Add this key to GitHub: Settings → SSH and GPG keys → New SSH key. Paste the key above, then press Enter here to continue." So the remote machine can pull repos and send commits via SSH once the user adds the key to their GitHub account.

---

## Terminal history context (from your test run)

Your sequence on the test machine was:

1. **ZeroTier** – `curl -s https://install.zerotier.com | sudo bash`, then `sudo zerotier-cli join 8286ac0e475bfb64` (note: URL is **zerotier** not zeroteir).
2. **SSH** – `systemctl status ssh`, then (from another session) `nano /etc/ssh/sshd_config` and `nano ~/.ssh/authorized_keys` so you could use Terminus.
3. **Crontab** – `sudo crontab -e` early in the process.
4. **Desktop on Server** – Checked with `dpkg -l | grep ubuntu-desktop`, then `apt install ubuntu-desktop`, `set-default graphical.target`, reboot.
5. **Playbook** – `apt install ansible git`, `git clone` repo, `cd automated_setup_2025`, `ansible-playbook ubuntu-setup.yml -K` (first run without `-K` then with).
6. **After playbook** – `nano /etc/ssh/sshd_config` again and `sudo reboot`; later again `nano ~/.ssh/authorized_keys` and `systemctl restart ssh`.

So: pre-connection (ZeroTier + SSH + authorized_keys) is done manually first; the playbook could deploy the Terminus key from the repo so you don't need to edit `authorized_keys` again after the first run or on re-runs. Instructions should match this flow and call out the correct ZeroTier URL.

---

## Target deployment context (server + minimal X + crane display)

In practice the system **pivoted to booting to server (no GNOME)** and then running a single fullscreen app (crane display) on a minimal X session. That flow is:

- **Boot:** Server (e.g. `multi-user.target`), no display manager.
- **Service:** `crane-display-standalone.service` runs xinit; the xinit client runs only the crane display; when the app exits, X exits.
- **Wrapper (in king_detector repo):** A client script calls `crane-display-fullscreen-wrapper.sh`, which sets resolution via **xrandr**, runs `crane_display.py` as user `lift` with display dimensions from **xdotool getdisplaygeometry**, and uses **xdotool** to find the "Crane Display" window and resize it to fullscreen (workaround for OpenCV fullscreen on minimal X with no WM).
- **Deps for this path:** `xdotool`, `x11-xserver-utils` (xrandr); app and systemd unit live in the **king_detector** codebase, not in automated_setup_2025.

This playbook only prepares the base system. The crane-display setup is documented here so that **SETUP_WORKFLOW.md** (or the post-reboot doc) can briefly state that the target use case may be "server boot + minimal X + crane display from king_detector" and that deps like `xdotool` and `x11-xserver-utils` are needed for that path (optional post-reboot checklist item). We do **not** add playbook tasks for king_detector or the crane-display service.

**Touchscreen without GNOME:** The touchscreen setup (packages + `/etc/X11/xorg.conf.d/99-touchscreen.conf`) works with minimal X; only the GDM-specific steps (WaylandEnable in gdm3/custom.conf, `systemctl restart gdm`) are skipped when using server + xinit.

---

## Current state

- **Install-system.md** has a brief "Connection" block (ZeroTier + SSH) at the top, then Ubuntu install, SSH enable, an "Optional: Lock Down SSH" block, clone repo, run playbook. The flow is a bit fragmented and the SSH key step is only a one-line "# send ssh keys!!".
- **Setup-post-reboot.md** is a list of manual steps (verify playbook, Firefox, crontab, VNC, VS Code, extensions, venv, etc.) with no tick-off structure; no mention of camera settings.
- **Playbook** runs on `localhost` (you SSH in, clone the repo, then run it). It configures SSH (port 33412, PubkeyAuthentication yes, PasswordAuthentication yes) but does not manage `~/.ssh/authorized_keys`.
- **Terminus key** is already in the repo as ssh-public-keys.txt (one line: Termius-generated key). No playbook task uses it yet.
- **Camera config** is in camera-settings/XNZ-L6320AConfigTOBE.bin; you will do website setup manually and want a post-reboot tick-off.

---

## 1. Instructions: pre-connection and ZeroTier

**Goal:** Make "getting from HPE iLO to SSH" a clear, manual-only section.

- In **Install-system.md**, turn the current "a. BIOS", "b. Connection (Zeroteir)", "Ssh lock down" into a clear **"0. Before Ubuntu: access and SSH"** section:
  - **ZeroTier (manual):** Install and join so you can reach the machine from your laptop (e.g. from HPE iLO). Use the correct URL: `https://install.zerotier.com` (not zeroteir). Steps: `curl -s https://install.zerotier.com | sudo bash`, then `sudo zerotier-cli join <your-network-id>`.
  - **SSH:** Enable SSH, then add your public key so Terminus works: on the server run `nano ~/.ssh/authorized_keys` (and optionally `nano /etc/ssh/sshd_config`). After SSH config changes, `sudo systemctl restart ssh` or reboot if needed.
- Keep "add key to authorized_keys" in this first-access section; cross-reference the "SSH key reminder" below.

**Outcome:** One place that says "do ZeroTier and basic SSH access first; this is manual and is how we get from iLO to a usable SSH session."

---

## 2. Instructions: SSH key reminder and Terminus

**Goal:** Document when/how to add your SSH key, and that the playbook can deploy the Terminus key from the repo.

- In **Install-system.md** (and optionally a short note in **README.md**):
  - **If using Ubuntu Server installer:** Remind that you can "Send SSH keys" during install so the first user already has your key in `~/.ssh/authorized_keys`.
  - **Otherwise:** Before (or right after) the first SSH session, add your Terminus (or other) public key to the remote `~/.ssh/authorized_keys` so you can use Terminus for the rest of the setup.
  - Add a short note: "The playbook can add the Terminus key from the repo for you — see step 4 (Run the Setup Playbook). Ensure `ssh-public-keys.txt` in the repo contains the keys you want deployed."

**Outcome:** Clear "add SSH key" reminder and link to the automated key deployment.

---

## 3. Automation: playbook changes (SSH, reboot, prompts, network info, data folders)

**SSH and keys**
- **Keep** `ssh-public-keys.txt` in the repo as-is (key only; no comment in file). README documents that the playbook uses it to deploy keys.
- In **ubuntu-setup.yml** in the **SSH configuration** block (after "Configure SSH port and authentication", around ~325):
  - Ensure `~/.ssh` exists for `ssh_user` (e.g. `file` task, mode `0700`, owner/group `ssh_user`).
  - Add a task that deploys keys from the repo into `authorized_keys` using Ansible's `authorized_key` module in a loop over lines from `ssh-public-keys.txt`, with `state: present` so duplicates are idempotent. Guard: run only if `ssh-public-keys.txt` exists (e.g. `stat` to check existence).
  - **Mandatory:** After keys are deployed, set `PasswordAuthentication no` (and related) and restart sshd.
  - **SSH config clarity:** Ensure each option (Port, PasswordAuthentication, PubkeyAuthentication, PermitRootLogin) appears only once in `/etc/ssh/sshd_config`. Use lineinfile to set/update in place, or a single managed block; do not append a block that leaves e.g. `# Port 22` at top and Port 33412 at bottom.

**Reboot**
- **Remove** the "5. AUTO-REBOOT SYSTEMD TIMER" section from ubuntu-setup.yml (do not create or enable daily-reboot.service / daily-reboot.timer). Scheduled reboots are via root crontab only (documented in post-reboot).

**Prompts at start (same style as Healthchecks)**
- **Boot mode prompt:** Near the start of the playbook (e.g. after or alongside the Healthchecks URL prompt), add a pause: "Do you want GNOME to open on boot, or the minimal X / king_detector approach (boot to non-GNOME, xdotool-style)?" Store as e.g. `boot_mode: gnome` | `boot_mode: minimal_x`. Use this fact later (e.g. when `minimal_x`: install xdotool and x11-xserver-utils by default; tailor SETUP_WORKFLOW / post-reboot instructions).

**Network info at start**
- **Early in playbook** (e.g. before or right after the healthchecks and boot-mode prompts): run tasks that gather and **display** for the user to record: Ethernet adapters (MAC address, current IP, connected or not) and MAC address of any WiFi interface. Use `ip link` / `ip addr` (or similar) and format output (e.g. debug task or shell that prints to stdout).

**Data folders**
- **Always by default:** Add task(s) in the normal run (ubuntu-setup.yml or post-reboot-verify.yml) to create `data/`, `data/jpg/`, `data/video/`, `data/jpg/no_hook`, `data/jpg/no_overlay` under a configurable path (e.g. default `~/code/king_detector` or a variable). Part of standard run, not optional.

**Git setup (SSH default, key for GitHub)**
- **ubuntu-setup.yml** – New section (e.g. after Tools or after SSH) for the connecting user (`ssh_user`):
  1. **git config:** Set `user.name` and `user.email` (prompt at start like healthchecks, or vars e.g. `git_user_name`, `git_user_email`).
  2. **SSH default:** `git config --global url."git@github.com:".insteadOf "https://github.com/"` so clone/push/pull use SSH.
  3. **Generate SSH key:** Run `ssh-keygen -t ed25519 -C "github-{{ ansible_hostname }}" -f ~/.ssh/id_ed25519_github -N ""` (or prompt for passphrase) for `ssh_user`; use a distinct filename so it does not overwrite the login key.
  4. **Display public key:** Output the contents of `~/.ssh/id_ed25519_github.pub` to stdout (e.g. `cat` in a shell task or `debug` with `var`).
  5. **Pause:** Prompt user: "Add this key to GitHub (Settings → SSH and GPG keys → New SSH key). Paste the key above, then press Enter to continue." So the user can add the key to GitHub and the remote machine can pull/push via SSH.
- Optionally add `~/.ssh/config` entry so `Host github.com` uses `IdentityFile ~/.ssh/id_ed25519_github` for Git only.

**Outcome:** Running the playbook after clone automatically adds the Terminus key (and any other keys in `ssh-public-keys.txt`) to the user's `authorized_keys`.

---

## 4. Instructions: post-reboot checklist and camera settings

**Goal:** Make post-reboot steps a clear tick-off list and add camera settings as a manual tick-off.

- Restructure **Setup-post-reboot.md** into a **checklist** (markdown `- [ ]` / `- [x]` items):
  - 1. Verify playbook – run `post-reboot-verify.yml` (keep existing command).
  - 2. Firefox default browser – keep existing commands.
  - 3. Crontab – Use **root** crontab: `sudo crontab -e`. Document exactly: `0 6,18 * * * /sbin/reboot` and `0 6,18 * * * echo "Cron executed at $(date)" >> /var/log/cron_test.log`. Scheduled reboots are via cron only (playbook does not install systemd reboot timer).
  - 4. VNC – Open and log into VNC server.
  - 5. VS Code – log into Git, download extensions (list as now).
  - 6. Clone repo (if different from setup repo).
  - 7. Python venv – keep existing.
  - 8. rev4.3 / tensor-check – keep as-is.
  - 9. fwupd disable – keep existing.
  - 10. Touch screen – keep if applicable; note that when using server + xinit (no GDM), skip GDM-specific steps (WaylandEnable, restart gdm); packages and `/etc/X11/xorg.conf.d/99-touchscreen.conf` still apply.
  - 11. Camera settings – New item: "Upload/configure camera config for the device. Config file in repo: `camera-settings/XNZ-L6320AConfigTOBE.bin`. Website/serving is set up manually."
  - 12. Data folders – Created by default by the playbook/post-reboot-verify (see Automation). If not automated for a given path, document manual `mkdir -p` as fallback.
  - Boot mode – If user chose minimal X at playbook start: post-reboot steps (or playbook) install `xdotool`, `x11-xserver-utils` and document king_detector/minimal X path; if GNOME: document desktop-on-boot path.
- Keep all existing commands in each section; only add structure and the new items.

**Outcome:** A single post-reboot checklist with a dedicated tick-off for camera settings and optional touchscreen/minimal-X notes.

---

## 5. Instructions: Lock down SSH (handled by playbook)

- The playbook sets `PasswordAuthentication no` after deploying keys (mandatory). In **Install-system.md** replace or shorten the long "Optional: Lock Down SSH" block with a note: "The playbook configures SSH on port 33412 and, after adding keys from `ssh-public-keys.txt`, disables password authentication. If you need to lock down before the first playbook run, use the steps in [link or appendix]."

---

## 6. Documentation for this update

**Goal:** One place that describes what changed in instructions vs automation vs manual.

- Add **SETUP_WORKFLOW.md** (or docs/INSTRUCTIONS_UPDATE.md) that covers:
  - **Intended workflow:** ZeroTier (manual) → Ubuntu install (optional: send SSH keys) → SSH in → clone repo → run playbook (prompts: healthchecks URL, boot mode GNOME vs minimal X; deploys keys, SSH lock-down, network info at start; no systemd reboot timer; cron for reboots) → reboot → post-reboot checklist (including camera settings, data folders).
  - **What's in the instructions:** Pre-connection/ZeroTier, SSH key reminder, post-reboot checklist with camera tick-off; boot mode choice at playbook start.
  - **What's automated:** Terminus/key deployment from `ssh-public-keys.txt`; SSH lock-down (port + no password auth); data folders by default; network info (MACs, IPs) printed at start for user to record.
  - **What stays manual:** ZeroTier install/join, adding key at install or before first run, camera website setup, crontab (6 and 18), and other post-reboot items.
  - **Target deployment:** Boot mode prompt determines path (GNOME on boot vs minimal X / king_detector); document both and deps (xdotool, x11-xserver-utils) for minimal X.
  - **Camera settings:** Reference to `camera-settings/` and that website hosting is manual; checklist item in Setup-post-reboot.md.
- Add a one-line pointer from **README.md** to this doc. Add one sentence in **README.md** that `ssh-public-keys.txt` is used by the playbook to deploy keys to `authorized_keys`.

**Outcome:** Clear record of the update and a single place to read the full workflow.

---

## 7. Ongoing CHANGELOG and DECISIONS at repo root

**Goal:** Single place in the repo for ongoing "what changed" and "what we decided and why."

- **Create in repo root** (if not already present):
  - **CHANGELOG.md** – Chronological log of **changes to the script(s)**. Each entry: date (or version), what changed (e.g. "ubuntu-setup.yml: removed systemd reboot timer; added Git SSH key generation and prompt"), and where (file/section). Append new entries when implementing or when making script changes. Can start with the 2026-02 batch of changes.
  - **DECISIONS.md** – Log of **decisions made and why**. Each entry: decision (e.g. "Reboot via cron only, not systemd"), rationale (e.g. "User wants twice-daily at 6 and 18; cron is simpler for that; avoid duplicate mechanism at 6 AM."). Append when locking in decisions (e.g. from this plan). Keeps context for future readers and avoids re-debating.
- **Maintenance:** When implementing this plan, add the first entries to both files. Thereafter, update CHANGELOG.md whenever the playbooks or scripts are changed, and DECISIONS.md whenever a significant decision is made (e.g. "Git: use SSH by default so remote machine can push/pull without HTTPS tokens.").
- **Relationship to 2026-02:** The folder `2026-02/` holds the **planned** updates (PLAN.md, CHANGELOG of planned items). The **root** CHANGELOG.md and DECISIONS.md are the **ongoing** project log; they record what was actually done and decided over the life of the repo.

**Outcome:** Anyone can read CHANGELOG.md for "what changed in the scripts" and DECISIONS.md for "what we decided and why."

---

## Summary

| Area | Action |
|------|--------|
| **Instructions** | ZeroTier-first "pre-connection" section in Install-system.md; SSH key reminder (installer + Terminus); post-reboot as tick-off checklist; camera settings tick-off; boot mode (GNOME vs minimal X) from playbook prompt; cron-only reboots (no systemd timer). |
| **Automation** | Deploy keys from `ssh-public-keys.txt` to `~/.ssh/authorized_keys`; mandatory SSH lock-down (PasswordAuthentication no); single-place SSH config (no duplicate/comment mess); remove systemd reboot timer; add boot-mode prompt and network-info (MACs, IPs) at start; create data folders by default (configurable path). |
| **Manual (documented)** | ZeroTier; adding key at install or before first run; camera website setup; root crontab for 6 and 18; other post-reboot steps. |
| **Repo** | Keep `ssh-public-keys.txt` as-is (key only); document its role in README. |
| **Docs** | New SETUP_WORKFLOW.md (workflow, boot mode, automated vs manual); README link + one sentence for ssh-public-keys.txt. **Repo root:** CHANGELOG.md (ongoing script changes); DECISIONS.md (decisions and why). |
| **Git setup** | Playbook: git user.name/user.email; SSH default (url insteadOf); generate ed25519 key for GitHub; display public key; pause to add key to GitHub. |

No changes to the camera-settings binary itself or to how you host it; only documentation and a checklist item.

---

## Implementation checklist (tick as done)

**Repo root**
- [ ] Create `CHANGELOG.md` with first entry (plan finalized / implementation started).
- [ ] Create `DECISIONS.md` with entries from "Decisions and new requirements" (reboot=cron, SSH lock-down mandatory, boot mode prompt, data folders by default, network info at start, SSH config single-place, ongoing logs, Git setup).

**ubuntu-setup.yml**
- [ ] Remove section "5. AUTO-REBOOT SYSTEMD TIMER" (daily-reboot.service, daily-reboot.timer, enable timer).
- [ ] Early in tasks: add task(s) to display network info (Ethernet MAC, IP, connected; WiFi MAC) for user to record.
- [ ] Add boot-mode prompt (after or with healthchecks): "GNOME on boot or minimal X / king_detector?" Store as `boot_mode`.
- [ ] Add Git section (for `ssh_user`): prompt or vars for git user.name, user.email; `git config --global url."git@github.com:".insteadOf "https://github.com/"`; generate `~/.ssh/id_ed25519_github` (ed25519); display public key; pause "Add key to GitHub, then Enter."
- [ ] SSH block: ensure `~/.ssh` exists; deploy keys from `ssh-public-keys.txt` via `authorized_key` (loop, guard if file exists); set PasswordAuthentication no (and related); ensure each option in sshd_config appears once (lineinfile or single block, no duplicate at bottom); restart sshd.
- [ ] Add data-folders task(s): create `data/`, `data/jpg/`, `data/video/`, `data/jpg/no_hook`, `data/jpg/no_overlay` under configurable path (default e.g. `~/code/king_detector`). When `boot_mode == minimal_x`: install xdotool, x11-xserver-utils.

**post-reboot-verify.yml (optional)**
- [ ] If data folders created here instead: add task(s) to create same dirs when app path exists.

**Install-system.md**
- [ ] Section "0. Before Ubuntu: access and SSH" with ZeroTier (correct URL), SSH (authorized_keys, optional sshd_config, restart ssh).
- [ ] SSH key reminder (installer "Send SSH keys"; else add Terminus key; playbook deploys from repo).
- [ ] Step 4: note playbook adds keys and disables password auth; mention Git key prompt and network info at start.
- [ ] Replace long "Optional: Lock Down SSH" block with short note (playbook does it; link to appendix if lock-down before first run).

**Setup-post-reboot.md**
- [ ] Restructure as checklist (`- [ ]`). Items 1–12: verify playbook, Firefox, crontab (exact two lines), VNC, VS Code, clone repo, venv, rev4.3, fwupd, touch screen (note: skip GDM steps when server + xinit), camera settings (file in repo, website manual), data folders (by default or manual). Boot mode: minimal X vs GNOME path.
- [ ] Crontab: `0 6,18 * * * /sbin/reboot` and `0 6,18 * * * echo "Cron executed at $(date)" >> /var/log/cron_test.log`; note cron-only (no systemd timer).

**SETUP_WORKFLOW.md**
- [ ] New file: intended workflow; boot mode choice; what's automated (keys, lock-down, data folders, network info, Git/SSH key); what stays manual; camera settings; both paths (GNOME vs minimal X).

**README.md**
- [ ] One-line pointer to SETUP_WORKFLOW.md.
- [ ] One sentence: `ssh-public-keys.txt` is used by the playbook to deploy keys to `authorized_keys`.

**Final**
- [ ] Append to root CHANGELOG.md: list of script changes (ubuntu-setup, post-reboot-verify, new docs).
- [ ] Append to root DECISIONS.md any additional rationale recorded during implementation.
