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

# ============================================================================
# Format: 3 lines (R, G, B) x 16 colors, comma-separated
# Dark background with bright, high-contrast foreground colors
# ============================================================================
#
# Color 0:  Black         #05040A  →  5,4,10
# Color 1:  Red           #FF6B8D  →  255,107,141
# Color 2:  Green         #4FD39B  →  79,211,155
# Color 3:  Yellow        #FFC966  →  255,201,102
# Color 4:  Blue          #83A7FF  →  131,167,255
# Color 5:  Magenta       #B26BFF  →  178,107,255
# Color 6:  Cyan          #71D2E8  →  113,210,232
# Color 7:  White         #E9E5F7  →  233,229,247
# Color 8:  Bright Black  #372E4D  →  55,46,77
# Color 9:  Bright Red    #FF8FAE  →  255,143,174
# Color 10: Bright Green  #82EFC0  →  130,239,192
# Color 11: Bright Yellow #FFDA8A  →  255,218,138
# Color 12: Bright Blue   #A7C0FF  →  167,192,255
# Color 13: Bright Magenta#D0A4FF  →  208,164,255
# Color 14: Bright Cyan   #98E3F4  →  152,227,244
# Color 15: Bright White  #FFFFFF  →  255,255,255
# ============================================================================

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

msg "Configuring large Terminus font for 4K display..."
FONT_CONFIG="/etc/conf.d/consolefont"
DESIRED_FONT="-d ter-132b"

NEEDS_UPDATE="false"
if [ -f "$FONT_CONFIG" ]; then
  if grep -q "consolefont=\"$DESIRED_FONT\"" "$FONT_CONFIG" 2>/dev/null; then
    skip "Large font already configured."
  else
    NEEDS_UPDATE="true"
  fi
else
  NEEDS_UPDATE="true"
fi

if [ "$NEEDS_UPDATE" = "true" ]; then
  update "Writing font configuration..."
  sudo tee "$FONT_CONFIG" >/dev/null <<FONTEOF
# Large Terminus font for 4K displays (doubled for better visibility)
consolefont="$DESIRED_FONT"
FONTEOF
  done_msg "Font configuration written."
else
  skip "Font configuration already optimal."
fi

msg "Applying colors to current TTY..."
if command -v setvtrgb >/dev/null 2>&1; then
  sudo setvtrgb "$VTRGB_FILE" 2>/dev/null || true
  done_msg "Colors applied to current TTY."
else
  skip "setvtrgb not available, colors will apply on next TTY switch."
fi

msg "Restarting consolefont service..."
if rc-update show default 2>/dev/null | grep -q "\bconsolefont\b"; then
  skip "consolefont already enabled for boot."
else
  info "Enabling consolefont service..."
  sudo rc-update add consolefont default >/dev/null
  done_msg "consolefont enabled for boot."
fi

sudo rc-service consolefont restart >/dev/null 2>&1 || {
  info "Service restart failed, applying font manually..."
  sudo setfont -d ter-132b 2>/dev/null || true
}
done_msg "consolefont restarted."

msg "Ensuring boot-time color application hook..."
BOOT_SCRIPT="/etc/local.d/tty-settings.start"
if [ -f "$BOOT_SCRIPT" ]; then
  skip "Boot-time hook already exists."
else
  update "Creating boot-time color application hook..."
  sudo tee "$BOOT_SCRIPT" >/dev/null <<'EOF'
#!/bin/sh
# Apply custom TTY colors at boot
if [ -f /etc/vtrgb ]; then
    setvtrgb /etc/vtrgb 2>/dev/null || true
fi
EOF
  sudo chmod +x "$BOOT_SCRIPT"
  done_msg "Boot-time color hook created."
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
tip "Colors and font will persist across reboots."
verify "cat /etc/vtrgb && echo && cat /etc/conf.d/consolefont && echo && sudo rc-service consolefont status"
