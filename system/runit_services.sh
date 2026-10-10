#!/bin/sh
set -eu

msg() { printf '\n==> %s\n' "$*"; }
skip() { printf '  -> [SKIP] %s\n' "$*"; }
ok() { printf '  -> [DONE] %s\n' "$*"; }
warn() { printf '  -> [WARN] %s\n' "$*" >&2; }

# Exact names from your /etc/runit/sv/ (alsa removed)
SERVICES="ufw udevd dbus cronie elogind bluetoothd NetworkManager"

msg "Ensuring core runit services are enabled..."

for svc in $SERVICES; do
  if [ ! -d "/etc/runit/sv/$svc" ]; then
    warn "$svc: not found in /etc/runit/sv/."
    continue
  fi

  if [ -L "/run/runit/service/$svc" ]; then
    skip "$svc already enabled."
  else
    if sudo ln -s "/etc/runit/sv/$svc" "/run/runit/service/$svc"; then
      ok "$svc enabled."
      # runsvdir starts it automatically. We skip 'sv start' to avoid the supervise/control error.
      continue
    else
      warn "$svc: failed to enable."
      continue
    fi
  fi

  # Only manually start if it was already enabled but stopped
  if sv status "$svc" >/dev/null 2>&1; then
    skip "$svc already running."
  else
    if sudo sv start "$svc" >/dev/null 2>&1; then
      ok "$svc started."
    else
      warn "$svc: failed to start."
    fi
  fi
done

msg "Service bootstrap complete."
