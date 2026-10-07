#!/bin/sh
set -eu

msg() { printf '\n==> %s\n' "$*"; }
skip() { printf '  -> [SKIP] %s\n' "$*"; }
ok() { printf '  -> [DONE] %s\n' "$*"; }
warn() { printf '  -> [WARN] %s\n' "$*" >&2; }

SERVICES="ufw udev dbus cronie elogind alsasound syslog-ng bluetoothd NetworkManager nvidia-persistenced"

msg "Ensuring core OpenRC services are enabled..."

for svc in $SERVICES; do
  # udev belongs in boot runlevel, others in default
  case "$svc" in
    udev) rl="boot" ;;
    *) rl="default" ;;
  esac

  # 1. Check if init script exists (catches missing -openrc packages)
  if [ ! -x "/etc/init.d/$svc" ]; then
    warn "$svc: init script not found. Install the corresponding -openrc package."
    continue
  fi

  # 2. Check if already enabled in any runlevel
  if rc-update show 2>/dev/null | awk '{print $1}' | grep -qx "$svc"; then
    skip "$svc already enabled."
  else
    if sudo rc-update add "$svc" "$rl"; then
      ok "$svc enabled in $rl runlevel."
    else
      warn "$svc: failed to enable."
      continue
    fi
  fi

  # 3. Start if not running
  if sudo rc-service "$svc" status >/dev/null 2>&1; then
    skip "$svc already running."
  else
    if sudo rc-service "$svc" start; then
      ok "$svc started."
    else
      warn "$svc: failed to start."
    fi
  fi
done

msg "Service bootstrap complete."
