#!/bin/sh

for svc in tlp ufw dbus thermald fail2ban bluetooth NetworkManager nvidia-persistenced; do
  sudo rc-update add "$svc" default 2>/dev/null || true
done
