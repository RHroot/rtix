#!/bin/sh

for svc in NetworkManager bluetooth tlp thermald fail2ban ufw nvidia-persistenced; do
  sudo rc-update add "$svc" default 2>/dev/null || true
done
