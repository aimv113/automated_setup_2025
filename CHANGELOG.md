# Changelog

Ongoing log of changes to the scripts and playbooks in this repository.

## 2026-02

- **ubuntu-setup.yml (Git setup fix and move):** Fixed "unexpected parameter type in action: AnsibleSequence" on the "Set git user.name and user.email" task by changing `command` from a list to a string with `quote` filter: `command: 'git config --global {{ item.key | quote }} {{ item.value | quote }}'`. Moved the entire Git setup block (prompts for user.name/user.email, git config, GitHub SSH key generation, pause to add key) from section 5 (after firewall) to section 17 at the end of the playbook, so the user is prompted for Git identity at the end of the run rather than in the middle. Log and final summary now record "17. GIT SETUP" and include "Git configured (SSH for GitHub)" in the completion message.

- **Plan finalized:** Setup instructions and automation (2026-02). Implementation in progress: repo root CHANGELOG.md and DECISIONS.md created; ubuntu-setup.yml and docs to follow per 2026-02/PLAN.md.

- **ubuntu-setup.yml:** Removed section "5. AUTO-REBOOT SYSTEMD TIMER" (no daily-reboot.service/timer). Added at start: network info display (Ethernet/WiFi MACs, IPs). Added boot-mode prompt (GNOME vs minimal X). Added section "5. GIT SETUP": prompts for git user.name/user.email, `url.insteadOf` for GitHub SSH, generate `~/.ssh/id_ed25519_github`, display public key, pause to add key to GitHub. SSH block rewritten: ensure `~/.ssh`, deploy keys from `ssh-public-keys.txt` via `authorized_key`, set Port/PasswordAuthentication no/PubkeyAuthentication/PermitRootLogin via lineinfile (single place), notify restart sshd. Added section "5b. DATA FOLDERS": create `app_data_path` and data/jpg/video/no_hook/no_overlay. When boot_mode minimal_x: install xdotool, x11-xserver-utils.

- **post-reboot-verify.yml:** Added vars `app_data_path`. Added section "7. DATA FOLDERS": ensure app_data_path and create data/jpg/video/no_hook/no_overlay.

- **Install-system.md:** Replaced with section "0. Before Ubuntu" (ZeroTier correct URL, SSH, add key); SSH key reminder (installer or manual; playbook deploys from repo). Step 4: playbook does network info, healthchecks, boot mode, Git prompts, GitHub key, keys from repo, SSH lock-down; no systemd reboot (crontab only). Replaced long "Optional: Lock Down SSH" block with short note.

- **Setup-post-reboot.md:** Restructured as checklist (1–12): verify playbook, Firefox, crontab (exact two lines), VNC, VS Code, clone repo, data folders, venv, rev4.3, fwupd, touch screen (note for server+xinit), camera settings; boot mode note.

- **SETUP_WORKFLOW.md:** New file: full workflow, what’s automated vs manual, boot mode (GNOME vs minimal X), camera settings.

- **README.md:** Pointer to SETUP_WORKFLOW.md; sentence that ssh-public-keys.txt is used by the playbook to deploy keys to authorized_keys.
