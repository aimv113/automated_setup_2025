# King_detector setup drop-in

Copy the contents of **admin/** into your king_detector repo under **admin/**:

- `admin/setup-crane-machine.sh` – setup script (make executable: `chmod +x admin/setup-crane-machine.sh`)
- `admin/SETUP.md` – instructions for running the script and manual steps
- `admin/crane-display-standalone.service` – systemd unit file (used by the script)

After copying, run the script from the king_detector repo root as described in **admin/SETUP.md**.
