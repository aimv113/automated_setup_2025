# Repository Guidelines

## Project Structure & Module Organization
This repository is Ansible-first and documentation-heavy.
- `ubuntu-setup.yml`: primary provisioning playbook for Ubuntu 24.04 + NVIDIA/CUDA/TensorRT stack.
- `post-reboot-verify.yml`: post-reboot verification and machine-finalization tasks (network/timezone/data dirs).
- `templates/`: netplan templates used by verification networking tasks.
- `camera-settings/`: camera config artifact (`XNZ-L6320AConfigTOBE.bin`).
- `king_detector-drop-in/`: service/setup files for integration with the separate `king_detector` repo.
- Root docs (`README.md`, `SETUP_WORKFLOW.md`, `Install-system.md`, `Setup-post-reboot.md`, `DECISIONS.md`) are the operational source of truth.

## Build, Test, and Development Commands
Run from repo root:
- `ansible-playbook ubuntu-setup.yml -K -vv`: main machine setup (often run twice with reboot between passes).
- `ansible-playbook post-reboot-verify.yml -K -vv`: required verification/finalization after reboot.
- `ansible-playbook ubuntu-setup.yml --syntax-check`: validate playbook syntax before committing.
- `ansible-playbook post-reboot-verify.yml --syntax-check`: syntax-check verification playbook.
- `ansible-playbook ubuntu-setup.yml -K -vv --check`: dry-run for safe review (where supported by tasks).

## Coding Style & Naming Conventions
- Use YAML with 2-space indentation and lowercase `snake_case` variable names (for example `tensorrt_version_full`).
- Keep tasks grouped in numbered sections with clear section headers, matching existing playbook style.
- Prefer explicit, descriptive task names (`- name:`) and consistent logging to `/var/log/ansible-*`.
- Keep templates and file names descriptive (`99-machine-network.yaml.j2`, `ssh-public-keys.txt`).

## Testing Guidelines
There is no unit test suite; validation is operational:
- Run syntax checks on both playbooks before opening a PR.
- Run `ubuntu-setup.yml`, reboot if required, then run `post-reboot-verify.yml`.
- Verify idempotency by re-running changed playbook(s); second run should report minimal/no changes.
- Capture key verification outputs (`nvidia-smi`, `nvcc --version`, Docker GPU check) in PR notes.

## Commit & Pull Request Guidelines
- Match existing history style: short, imperative commit subjects (`Fix ...`, `Add ...`, `Update ...`).
- Keep commits scoped to a single concern (for example WiFi detection, SSH docs, kernel pinning).
- PRs should include: what changed, why, impacted playbook/docs, and exact test commands run.
- Link related issue/task when available and include relevant logs/screenshots for setup regressions.

## Security & Configuration Tips
- Treat `ssh-public-keys.txt` as sensitive operational config; review diffs carefully.
- Avoid committing secrets (VPN tokens, private keys, credentials, machine-specific identifiers).
- When changing pinned GPU versions, update related variables/docs together to preserve reproducibility.
