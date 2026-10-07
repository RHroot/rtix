#!/bin/sh
set -eu

msg() { printf '\n==> %s\n' "$*"; }
info() { printf '  -> %s\n' "$*"; }
skip() { printf '  -> [SKIP] %s\n' "$*"; }
done_msg() { printf '  -> [DONE] %s\n' "$*"; }
tip() { printf '\n  -> [TIP] %s\n' "$*"; }
verify() { printf '  -> [VERIFY] %s\n' "$*"; }

RULE_FILE="/etc/udev/rules.d/90-backlight.rules"
CURRENT_USER="${SUDO_USER:-$(whoami)}"

msg "Configuring backlight permissions..."

if [ -f "$RULE_FILE" ] && grep -q 'SUBSYSTEM=="backlight"' "$RULE_FILE"; then
  skip "Backlight udev rule already exists."
else
  info "Creating backlight udev rule..."
  sudo tee "$RULE_FILE" >/dev/null <<'EOF'
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="acpi_video0", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="acpi_video0", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl*", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl*", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
EOF
  info "Reloading udev rules..."
  sudo udevadm control --reload-rules >/dev/null
  sudo udevadm trigger --subsystem-match=backlight >/dev/null
  done_msg "Backlight udev rule applied."
fi

if groups "$CURRENT_USER" 2>/dev/null | grep -q '\bvideo\b'; then
  skip "User '$CURRENT_USER' is already in the 'video' group."
else
  info "Adding '$CURRENT_USER' to 'video' group..."
  sudo usermod -aG video "$CURRENT_USER"
  done_msg "Group membership updated."
fi

tip "Log out and log back in for group changes to take effect."
verify "groups $CURRENT_USER | grep video"
