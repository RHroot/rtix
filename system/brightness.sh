#!/bin/sh
set -eu

msg() { printf '==> %s\n' "$*"; }

RULE_FILE="/etc/udev/rules.d/90-backlight.rules"

# Check if rule already exists
if [ -f "$RULE_FILE" ]; then
  msg "Brightness udev rule already exists. Skipping."
else
  msg "Creating brightness udev rule..."

  sudo tee "$RULE_FILE" >/dev/null <<'EOF'
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="acpi_video0", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="acpi_video0", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"

ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"

ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl*", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl*", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
EOF

  msg "Reloading udev rules..."
  sudo udevadm control --reload-rules
  sudo udevadm trigger --subsystem-match=backlight
fi

# Check if user is in video group
if groups "$USER" | grep -q '\bvideo\b'; then
  msg "User $USER is already in video group. Skipping."
else
  msg "Adding $USER to video group..."
  sudo usermod -aG video "$USER"
  msg "NOTE: Log out and back in for group changes to take effect."
fi
