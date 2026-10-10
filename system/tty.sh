#!/bin/sh
set -eu

msg() { printf '\n==> %s\n' "$*"; }
info() { printf '  -> %s\n' "$*"; }
skip() { printf '  -> [SKIP] %s\n' "$*"; }
update() { printf '  -> [UPDATE] %s\n' "$*"; }
done_msg() { printf '  -> [DONE] %s\n' "$*"; }
tip() { printf '\n  -> [TIP] %s\n' "$*"; }
verify() { printf '  -> [VERIFY] %s\n' "$*"; }

msg "Installing TTY enhancement packages..."
PACKAGES="terminus-font kbd"
MISSING=""
for pkg in $PACKAGES; do
  if ! pacman -Q "$pkg" >/dev/null 2>&1; then
    MISSING="$MISSING $pkg"
  fi
done

if [ -n "$MISSING" ]; then
  info "Installing missing packages:$MISSING"
  sudo pacman -S --noconfirm --needed $MISSING >/dev/null
  done_msg "Packages installed."
else
  skip "All TTY packages already installed."
fi

msg "Configuring custom TTY color scheme (vibrant original)..."
VTRGB_FILE="/etc/vtrgb"

CUSTOM_COLORS='5,255,79,255,131,178,113,233,55,255,130,255,167,208,152,255
4,107,211,201,167,107,210,229,46,143,239,218,192,164,227,255
10,141,155,102,255,255,232,247,77,174,192,138,255,255,244,255'

NEEDS_UPDATE="false"
if [ -f "$VTRGB_FILE" ]; then
  CURRENT=$(cat "$VTRGB_FILE" 2>/dev/null || echo "")
  if [ "$CURRENT" = "$CUSTOM_COLORS" ]; then
    skip "Custom color scheme already configured."
  else
    NEEDS_UPDATE="true"
  fi
else
  NEEDS_UPDATE="true"
fi

if [ "$NEEDS_UPDATE" = "true" ]; then
  update "Writing vibrant custom TTY color scheme..."
  printf '%s\n' "$CUSTOM_COLORS" | sudo tee "$VTRGB_FILE" >/dev/null
  done_msg "Custom color scheme written to $VTRGB_FILE."
else
  skip "TTY color scheme already optimal."
fi

msg "Applying settings to current TTY..."
sudo setvtrgb "$VTRGB_FILE" 2>/dev/null || true
sudo setfont -d ter-v32b 2>/dev/null || true
done_msg "Colors and font applied to current TTY."

msg "Creating runit service for boot persistence..."
SV_DIR="/etc/runit/sv/console-setup"
if [ -d "$SV_DIR" ] && [ -x "$SV_DIR/run" ]; then
  skip "console-setup runit service already exists."
else
  update "Creating console-setup runit service..."
  sudo mkdir -p "$SV_DIR"
  sudo tee "$SV_DIR/run" >/dev/null <<'EOF'
#!/bin/sh
for tty in /dev/tty[1-6]; do
    setfont -d ter-v32b -C "$tty" 2>/dev/null || true
    setvtrgb /etc/vtrgb -C "$tty" 2>/dev/null || true
done
exec sleep infinity
EOF
  sudo chmod +x "$SV_DIR/run"
  done_msg "console-setup service created."
fi

if [ -L "/run/runit/service/console-setup" ]; then
  skip "console-setup already enabled."
else
  info "Enabling console-setup service..."
  sudo ln -s "$SV_DIR" "/run/runit/service/console-setup"
  done_msg "console-setup enabled for boot."
fi

msg "Displaying color palette (vibrant original)..."
printf '\n'
printf '  Color 0:  Black         #05040A\n'
printf '  Color 1:  Red           #FF6B8D\n'
printf '  Color 2:  Green         #4FD39B\n'
printf '  Color 3:  Yellow        #FFC966\n'
printf '  Color 4:  Blue          #83A7FF\n'
printf '  Color 5:  Magenta       #B26BFF\n'
printf '  Color 6:  Cyan          #71D2E8\n'
printf '  Color 7:  White         #E9E5F7\n'
printf '  Color 8:  Bright Black  #372E4D\n'
printf '  Color 9:  Bright Red    #FF8FAE\n'
printf '  Color 10: Bright Green  #82EFC0\n'
printf '  Color 11: Bright Yellow #FFDA8A\n'
printf '  Color 12: Bright Blue   #A7C0FF\n'
printf '  Color 13: Bright Magenta#D0A4FF\n'
printf '  Color 14: Bright Cyan   #98E3F4\n'
printf '  Color 15: Bright White  #FFFFFF\n'
printf '\n'

tip "TTY now uses vibrant, high-contrast colors and large doubled Terminus font."
tip "Switch to any TTY (Ctrl+Alt+F2) to see the changes immediately."
tip "Colors and font will persist across reboots via the console-setup runit service."
verify "sv status console-setup && cat /etc/vtrgb"
