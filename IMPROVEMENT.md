# Improvement Audit

Prioritised list of issues. Items marked **by design** are intentional and not issues.

---

## Priority 1 — Correctness

### 1.1 pip package name for TensorRT — confirmed correct
- **File:** `post-reboot-verify.yml`
- **Package:** `nvidia-tensorrt` — exists on PyPI (https://pypi.org/project/nvidia-tensorrt/). It is a stub meta-package that depends on `tensorrt`, so the install works correctly.
- **No change needed.**

### 1.2 Version locking in hardcoded paths (by design)
- **Files:** `post-reboot-verify.yml` CUDA path (`/usr/local/cuda-13.0/bin/nvcc`), Docker image (`nvidia/cuda:13.0.0-...`), `ubuntu-setup.yml` CUDA download URL embedding driver version.
- **Decision:** Version locking across the full GPU stack is intentional. Updating any version requires a deliberate, coordinated change to all related vars/paths.
- **Action:** No change to locking. Add a comment in `vars/common.yml` noting this dependency so the update path is clear.

### 1.3 Touchscreen packages installed unconditionally
- **Lines:** `233a–233d/243` in `ubuntu-setup.yml`
- **Current:** Always installs xorg-input packages and writes eGalax xorg.conf regardless of hardware.
- **Action:** Detect touchscreen via `lsusb` first. If found, auto-proceed with a tick. If not found, prompt the user (since all machines should have one, a missing device may indicate a connection issue). ✅ Fixed.

---

## Priority 2 — Maintainability

### 2.1 Per-section log-writing shell tasks are boilerplate
- **Scale:** ~20 dedicated `shell` tasks in `ubuntu-setup.yml` and ~10 in `post-reboot-verify.yml` whose only job is writing section headers to the log file.
- **Note:** User does not actively use log files.
- **Action:** Remove all per-section log tasks. Keep log file initialisation and final summary only. ✅ Fixed.

### 2.2 Duplicate variables across both playbooks
- **Vars:** `ssh_user`, `user_home`, `app_data_path` defined identically in both playbooks. GPU stack version vars defined in `ubuntu-setup.yml` but hardcoded in `post-reboot-verify.yml`.
- **Action:** Extract to `vars/common.yml`. Both playbooks import it via `vars_files`. Also useful for operators updating ethernet interface names or IPs. ✅ Fixed.

### 2.3 Task numbering is fragile and inconsistent
- **Examples:** `233a/243`, `233b/243` (fractional), handlers counted in total, total is wrong after any insertion.
- **Action:** Remove the `n/total` prefix from all task names. Section comment headers already provide structure. ✅ Fixed.

### 2.4 Unnamed `debug` tasks
- **Pattern:** `- debug: msg: "..."` without a `name:` field, ~15 times across both files.
- **Impact:** Ansible output shows `TASK [debug]` with no context.
- **Action:** Add `name:` to every debug task. ✅ Fixed.

### 2.5 Final summary block duplicated verbatim
- **Issue:** The final summary is written once via shell to the log and once via `debug` — identical content must be kept in sync.
- **Action:** Write summary to a var/fact, reuse in both. Addressed as part of log simplification (2.1).

---

## Priority 3 — Documentation

### 3.1 README.md: GPU stack section repeated twice, conflicting layer count
- **Issue:** "Frozen GPU Stack" table appears twice. First instance says "Four Layers", second says "Three Layers".
- **Action:** One table. Deep reference material (offline rebuild scripts, manual upgrade procedures) already exists in `REPRODUCIBILITY_STRATEGY.md` — replace with a link. ✅ Fixed.

### 3.2 README.md: TensorRT URL construction section is mid-doc noise
- **Issue:** ~30 lines of URL pattern detail buried in README.
- **Action:** Cut to two lines with a pointer to `TENSORRT_URL_VERIFICATION.md`. ✅ Fixed.

### 3.3 Install-system.md: sections labelled out of order
- **Issue:** Section sequence is `0 → 1 → 2 → c → b → 3 → 5` — out of order, `b` appears after `c`.
- **Action:** Relabel sequentially as a clean numbered checklist. ✅ Fixed.

### 3.4 Setup-post-reboot.md: raw notes at top, missing section numbers
- **Issue:** File opens with an incomplete sentence ("Add back up IP route, follow link online..."). Sections jump from `1` to `6`, then `7` to `10`.
- **Note:** `sudo tailscale up` at the top is correct — it's the first thing to do post-boot.
- **Action:** Keep tailscale command. Remove the raw-note sentence. Renumber sections sequentially. ✅ Fixed.

### 3.5 Setup-post-reboot.md: Appendix A networking manual fixes
- **Issue:** ~80 lines of shell recovery scripts at the end — reference material, not a checklist step.
- **Action:** Move Appendix A content into `WIFI_SETUP.md` (already the home for networking recovery). Replace with a one-line pointer. ✅ Fixed.

### 3.6 `detailed creation docs/` folder
- **Contents:** Development/research artifacts. Most durable content absorbed into `CLAUDE.md`.
- **Action:** Archive or delete `to-do.md`, `cuda13.md`. Retain `REPRODUCIBILITY_STRATEGY.md` and `TENSORRT_URL_VERIFICATION.md` at root (already referenced). Pending.

### 3.7 `2026-02/` planning folder
- **Contents:** `PLAN.md`, `CHANGELOG.md` — completed batch planning artifacts.
- **Action:** Delete or move to archive. Pending.

### 3.8 SETUP_WORKFLOW.md overlaps with README
- **Issue:** Both describe the same 10-step flow.
- **Action:** README becomes a two-paragraph summary with pointers. `SETUP_WORKFLOW.md` is the canonical step list. ✅ Fixed as part of README update.

---

## Confirmed Non-Issues (by design)

- **ZeroTier network ID hardcoded in `Install-system.md`:** Intentional — same pattern as CUDA version locking.
- **CUDA/NVIDIA/TensorRT version values hardcoded:** Intentional frozen stack. Coordinated update required; comment in `vars/common.yml` makes this clear.
- **`sudo tailscale up` first in `Setup-post-reboot.md`:** Correct — this is the first action needed post-boot.
- **`DECISIONS.md` references removed features:** Low priority. Could be annotated against git history in a future pass.
- **`CHANGELOG.md` length:** Not urgent. Archive old entries when it exceeds ~100 lines.
