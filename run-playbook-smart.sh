#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <playbook.yml> [ansible-playbook args...]"
  exit 1
fi

playbook="$1"
shift

if [[ ! -f "$playbook" ]]; then
  echo "Playbook not found: $playbook"
  exit 1
fi

ask_pass_already_set="false"
for arg in "$@"; do
  if [[ "$arg" == "-K" || "$arg" == "--ask-become-pass" ]]; then
    ask_pass_already_set="true"
    break
  fi
done

if [[ "$ask_pass_already_set" == "true" ]]; then
  exec ansible-playbook "$playbook" "$@"
fi

# Root user or active sudo timestamp: run without become prompt.
if [[ "${EUID}" -eq 0 ]] || sudo -n true 2>/dev/null; then
  echo "Using existing sudo privileges; running without -K."
  exec ansible-playbook "$playbook" "$@"
fi

echo "No active sudo privileges; running with -K."
exec ansible-playbook "$playbook" -K "$@"

