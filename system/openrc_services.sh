#!/bin/sh
set -eu

msg() { printf '\n==> %s\n' "$*"; }
skip() { printf '  -> [SKIP] %s\n' "$*"; }
done_msg() { printf '  -> [DONE] %s\n' "$*"; }

msg "Ensuring core OpenRC services are enabled..."

for svc in ufw dbus alsasound bluetoothd NetworkManager nvidia-persistenced; do
  if rc-update show default 2>/dev/null | grep -q "\b$svc\b"; then
    skip "$svc already enabled."
  else
    sudo rc-update add "$svc" default >/dev/null 2>&1 || true
    done_msg "$svc enabled in default runlevel."
  fi
done

msg "Service bootstrap complete."
