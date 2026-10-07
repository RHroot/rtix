#!/bin/sh
set -eu

msg() { printf '\n==> %s\n' "$*"; }
info() { printf '  -> %s\n' "$*"; }
skip() { printf '  -> [SKIP] %s\n' "$*"; }
update() { printf '  -> [UPDATE] %s\n' "$*"; }
done_msg() { printf '  -> [DONE] %s\n' "$*"; }
tip() { printf '\n  -> [TIP] %s\n' "$*"; }
verify() { printf '  -> [VERIFY] %s\n' "$*"; }

msg "Checking power management packages..."
PACKAGES="tlp tlp-openrc thermald thermald-openrc upower"
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
  skip "All power management packages already installed."
fi

msg "Configuring TLP..."
TLP_CUSTOM_CONF="/etc/tlp.d/99-custom.conf"
DESIRED_TLP='CPU_SCALING_GOVERNOR_ON_AC="powersave"
CPU_SCALING_GOVERNOR_ON_BAT="powersave"
CPU_ENERGY_PERF_POLICY_ON_AC="balance_performance"
CPU_ENERGY_PERF_POLICY_ON_BAT="balance_power"
CPU_SCALING_MAX_FREQ_ON_BAT=2600000
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
START_CHARGE_THRESH_BAT1=75
STOP_CHARGE_THRESH_BAT1=80'

NEEDS_UPDATE="false"
if [ ! -f "$TLP_CUSTOM_CONF" ]; then
  NEEDS_UPDATE="true"
else
  for setting in $DESIRED_TLP; do
    key=$(echo "$setting" | cut -d= -f1)
    value=$(echo "$setting" | cut -d= -f2-)
    if ! grep -q "^${key}=${value}" "$TLP_CUSTOM_CONF" 2>/dev/null; then
      NEEDS_UPDATE="true"
      break
    fi
  done
fi

if [ "$NEEDS_UPDATE" = "true" ]; then
  if [ -f "$TLP_CUSTOM_CONF" ]; then
    update "TLP configuration changed, updating..."
  else
    info "Writing TLP custom configuration..."
  fi
  sudo tee "$TLP_CUSTOM_CONF" >/dev/null <<'TLPEOF'
CPU_SCALING_GOVERNOR_ON_AC="powersave"
CPU_SCALING_GOVERNOR_ON_BAT="powersave"
CPU_ENERGY_PERF_POLICY_ON_AC="balance_performance"
CPU_ENERGY_PERF_POLICY_ON_BAT="balance_power"
CPU_SCALING_MAX_FREQ_ON_BAT=2600000
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
START_CHARGE_THRESH_BAT1=75
STOP_CHARGE_THRESH_BAT1=80
TLPEOF
  done_msg "TLP configuration updated."
  sudo rc-service tlp restart >/dev/null 2>&1 || true
else
  skip "TLP configuration already optimal."
fi

msg "Configuring UPower thresholds..."
UPOWER_CONF="/etc/UPower/UPower.conf"
NEEDS_UPDATE="false"
for key in PercentageLow PercentageCritical PercentageAction CriticalAction; do
  case $key in
    PercentageLow) val="30" ;;
    PercentageCritical) val="20" ;;
    PercentageAction) val="15" ;;
    CriticalAction) val="Suspend" ;;
  esac
  current=$(grep "^${key}=" "$UPOWER_CONF" 2>/dev/null | cut -d= -f2 || echo "")
  if [ "$current" != "$val" ]; then
    NEEDS_UPDATE="true"
    break
  fi
done

if [ "$NEEDS_UPDATE" = "true" ]; then
  update "UPower thresholds changed, updating..."
  sudo sed -i 's/^PercentageLow=.*/PercentageLow=30/' "$UPOWER_CONF"
  sudo sed -i 's/^PercentageCritical=.*/PercentageCritical=20/' "$UPOWER_CONF"
  sudo sed -i 's/^PercentageAction=.*/PercentageAction=15/' "$UPOWER_CONF"
  sudo sed -i 's/^CriticalAction=.*/CriticalAction=Suspend/' "$UPOWER_CONF"
  sudo sed -i 's/^AllowRiskyCriticalPowerAction=.*/AllowRiskyCriticalPowerAction=true/' "$UPOWER_CONF"
  done_msg "UPower thresholds updated (30%/20%/15%) with Suspend action."
else
  skip "UPower thresholds already configured."
fi

msg "Enabling services..."
for svc in tlp thermald; do
  if rc-update show default 2>/dev/null | grep -q "\b$svc\b"; then
    skip "$svc already enabled."
  else
    info "Enabling $svc..."
    sudo rc-update add "$svc" default >/dev/null
    done_msg "$svc enabled."
  fi

  if rc-service "$svc" status 2>/dev/null | grep -q "started"; then
    skip "$svc is already running."
  else
    info "Starting $svc..."
    sudo rc-service "$svc" start >/dev/null
    done_msg "$svc started."
  fi
done

tip "UPower will automatically suspend at 15% battery (runs via D-Bus activation)."
verify "pgrep -a upowerd && grep -E '^(PercentageAction|CriticalAction)' /etc/UPower/UPower.conf"
