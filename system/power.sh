#!/bin/sh
set -eu

msg() { printf '\n==> %s\n' "$*"; }
info() { printf '  -> %s\n' "$*"; }
skip() { printf '  -> [SKIP] %s\n' "$*"; }
update() { printf '  -> [UPDATE] %s\n' "$*"; }
done_msg() { printf '  -> [DONE] %s\n' "$*"; }
tip() { printf '\n  -> [TIP] %s\n' "$*"; }
verify() { printf '  -> [VERIFY] %s\n' "$*"; }

CURRENT_USER="${SUDO_USER:-$(whoami)}"

msg "Checking power management packages..."
PACKAGES="tlp tlp-openrc thermald thermald-openrc upower libnotify"
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
    PercentageAction) val="10" ;;
    CriticalAction) val="HybridSleep" ;;
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
  sudo sed -i 's/^PercentageAction=.*/PercentageAction=10/' "$UPOWER_CONF"
  sudo sed -i 's/^CriticalAction=.*/CriticalAction=HybridSleep/' "$UPOWER_CONF"
  done_msg "UPower thresholds updated (30%/20%/10%)."
else
  skip "UPower thresholds already configured."
fi

msg "Setting up battery monitor service..."
MONITOR_SCRIPT="/usr/local/bin/battery-monitor"
SERVICE_FILE="/etc/init.d/battery-monitor"

if [ -f "$MONITOR_SCRIPT" ] && grep -q "upower -i" "$MONITOR_SCRIPT"; then
  skip "Battery monitor script already exists."
else
  info "Creating battery monitor script..."
  sudo tee "$MONITOR_SCRIPT" >/dev/null <<'MONITOREOF'
#!/bin/sh
LAST_WARNING="none"
while true; do
    WARNING=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null | grep "warning-level" | awk '{print $2}')
    PERCENTAGE=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null | grep "percentage" | awk '{print $2}')
    STATE=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null | grep "state" | awk '{print $2}')
    if [ "$STATE" = "discharging" ] && [ "$WARNING" != "$LAST_WARNING" ]; then
        case "$WARNING" in
            low) notify-send -u normal "Battery Low" "Battery at ${PERCENTAGE}% - Please plug in charger" -i battery-low ;;
            critical) notify-send -u critical "Battery Critical" "Battery at ${PERCENTAGE}% - System will suspend soon" -i battery-caution ;;
            action) notify-send -u critical "Battery Emergency" "Suspending now!" -i battery-empty; sleep 5; loginctl suspend ;;
        esac
        LAST_WARNING="$WARNING"
    elif [ "$STATE" = "charging" ] || [ "$STATE" = "fully-charged" ]; then
        LAST_WARNING="none"
    fi
    sleep 60
done
MONITOREOF
  sudo chmod +x "$MONITOR_SCRIPT"
  done_msg "Battery monitor script created."
fi

NEEDS_UPDATE="false"
if [ ! -f "$SERVICE_FILE" ]; then
  NEEDS_UPDATE="true"
elif ! grep -q "command_user=\"${CURRENT_USER}\"" "$SERVICE_FILE" 2>/dev/null; then
  NEEDS_UPDATE="true"
fi

if [ "$NEEDS_UPDATE" = "true" ]; then
  if [ -f "$SERVICE_FILE" ]; then
    update "Service user changed to ${CURRENT_USER}, updating..."
  else
    info "Creating OpenRC service..."
  fi
  sudo tee "$SERVICE_FILE" >/dev/null <<SERVICEEOF
#!/sbin/openrc-run
name="battery-monitor"
description="Battery level monitor with desktop notifications"
command="/usr/local/bin/battery-monitor"
command_user="${CURRENT_USER}"
command_background="yes"
pidfile="/run/\${RC_SVCNAME}.pid"
depend() { need localmount; after bootmisc; }
start_pre() { checkpath --directory --owner ${CURRENT_USER}:${CURRENT_USER} /run/\${RC_SVCNAME}; }
SERVICEEOF
  sudo chmod +x "$SERVICE_FILE"
  done_msg "OpenRC service created/updated for user: ${CURRENT_USER}."
  if rc-service battery-monitor status 2>/dev/null | grep -q "started"; then
    sudo rc-service battery-monitor restart >/dev/null 2>&1 || true
  fi
else
  skip "Battery monitor service already configured for user: ${CURRENT_USER}."
fi

msg "Enabling services..."
for svc in tlp thermald battery-monitor; do
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

tip "Battery monitor will now notify you at 30%, 20%, and suspend at 10%."
verify "sudo tlp-stat -s | grep -E '(TLP profile|Power source)'"
