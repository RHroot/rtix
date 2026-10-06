#!/bin/sh
set -eu

msg() { printf '==> %s\n' "$*"; }
info() { printf '  -> %s\n' "$*"; }
skip() { printf '  -> [SKIP] %s\n' "$*"; }
done_msg() { printf '  -> [DONE] %s\n' "$*"; }

# ==============================================================================
# STEP 1: NetworkManager Configuration
# ==============================================================================
msg "Configuring NetworkManager..."

NM_CONF_DIR="/etc/NetworkManager/conf.d"
sudo mkdir -p "$NM_CONF_DIR"

# 1a. Disable NM DNS management
DNS_CONF="$NM_CONF_DIR/dns.conf"
if [ -f "$DNS_CONF" ] && grep -q "dns=none" "$DNS_CONF" && grep -q "rc-manager=unmanaged" "$DNS_CONF"; then
  skip "NetworkManager DNS config already optimal"
else
  info "Writing NetworkManager DNS config..."
  sudo tee "$DNS_CONF" >/dev/null <<'EOF'
[main]
dns=none
rc-manager=unmanaged
EOF
  done_msg "NetworkManager DNS config updated"
fi

# 1b. Disable WiFi powersave
WIFI_CONF="$NM_CONF_DIR/wifi-powersave.conf"
if [ -f "$WIFI_CONF" ] && grep -q "wifi.powersave=2" "$WIFI_CONF"; then
  skip "NetworkManager WiFi powersave already disabled"
else
  info "Writing NetworkManager WiFi powersave config..."
  sudo tee "$WIFI_CONF" >/dev/null <<'EOF'
[connection]
wifi.powersave=2
EOF
  done_msg "NetworkManager WiFi powersave config updated"
fi

# ==============================================================================
# STEP 2: Unbound (DNS-over-TLS & Caching)
# ==============================================================================
msg "Configuring Unbound (DNS-over-TLS)..."

# 2a. Install unbound and openrc init script if missing
if ! pacman -Q unbound unbound-openrc >/dev/null 2>&1; then
  info "Installing unbound and unbound-openrc..."
  sudo pacman -S --noconfirm --needed unbound unbound-openrc >/dev/null 2>&1
  done_msg "Unbound packages installed"
else
  skip "Unbound packages already installed"
fi

# 2b. Create Unbound DoT configuration
UNBOUND_CONF_DIR="/etc/unbound/unbound.conf.d"
sudo mkdir -p "$UNBOUND_CONF_DIR"
DOT_CONF="$UNBOUND_CONF_DIR/dot.conf"

if [ -f "$DOT_CONF" ] && grep -q "forward-addr: 1.1.1.1@853#cloudflare-dns.com" "$DOT_CONF" && grep -q "tls-upstream: yes" "$DOT_CONF"; then
  skip "Unbound DoT config already exists and is optimal"
else
  info "Writing Unbound DoT configuration..."
  sudo tee "$DOT_CONF" >/dev/null <<'EOF'
server:
    do-tcp: yes
    tls-cert-bundle: /etc/ssl/certs/ca-bundle.crt
    cache-max-ttl: 86400
    do-ip4: yes
    do-ip6: yes
    # Equivalent to DNSSEC allow-downgrade
    harden-dnssec-stripped: no
    # Force upstream connections to use TLS
    tls-upstream: yes

forward-zone:
    name: "."
    # Cloudflare
    forward-addr: 1.1.1.1@853#cloudflare-dns.com
    forward-addr: 1.0.0.1@853#cloudflare-dns.com
    # Google
    forward-addr: 8.8.8.8@853#dns.google
    forward-addr: 8.8.4.4@853#dns.google
    # Quad9
    forward-addr: 9.9.9.9@853#dns.quad9.net
    forward-addr: 149.112.112.112@853#dns.quad9.net
EOF
  done_msg "Unbound DoT config written"
fi

# 2c. Enable unbound-control interface
REMOTE_CONTROL_CONF="$UNBOUND_CONF_DIR/remote-control.conf"
if [ -f "$REMOTE_CONTROL_CONF" ] && grep -q "control-enable: yes" "$REMOTE_CONTROL_CONF"; then
  skip "Unbound remote-control already enabled"
else
  info "Writing Unbound remote-control configuration..."
  sudo tee "$REMOTE_CONTROL_CONF" >/dev/null <<'EOF'
remote-control:
    control-enable: yes
    control-interface: 127.0.0.1
    control-port: 8953
    server-key-file: /etc/unbound/unbound_server.key
    server-cert-file: /etc/unbound/unbound_server.pem
    control-key-file: /etc/unbound/unbound_control.key
    control-cert-file: /etc/unbound/unbound_control.pem
EOF
  done_msg "Unbound remote-control config written"
fi

# 2d. Generate SSL certificates for unbound-control if missing
if [ -f "/etc/unbound/unbound_server.key" ] && [ -f "/etc/unbound/unbound_control.key" ]; then
  skip "Unbound control certificates already exist"
else
  info "Generating unbound-control SSL certificates..."
  sudo unbound-control-setup >/dev/null 2>&1
  done_msg "Unbound control certificates generated"
fi

# 2e. Ensure main unbound.conf includes conf.d directory
UNBOUND_MAIN_CONF="/etc/unbound/unbound.conf"
if grep -q "^include: /etc/unbound/unbound.conf.d/\*.conf" "$UNBOUND_MAIN_CONF"; then
  skip "Unbound main config already includes conf.d"
else
  info "Adding include directive to unbound.conf..."
  echo 'include: /etc/unbound/unbound.conf.d/*.conf' | sudo tee -a "$UNBOUND_MAIN_CONF" >/dev/null
  done_msg "Include directive added to unbound.conf"
fi

# 2f. Point system resolv.conf to local unbound and make immutable
RESOLV_CONF="/etc/resolv.conf"
if [ -f "$RESOLV_CONF" ] && grep -q "^nameserver 127.0.0.1$" "$RESOLV_CONF"; then
  # Check if it's already immutable
  if lsattr "$RESOLV_CONF" 2>/dev/null | grep -q '\bi\b'; then
    skip "resolv.conf already points to 127.0.0.1 and is immutable"
  else
    info "Making resolv.conf immutable..."
    sudo chattr +i "$RESOLV_CONF"
    done_msg "resolv.conf is now immutable"
  fi
else
  info "Updating resolv.conf to use local Unbound..."
  # Remove immutable flag if it exists, remove old file, create new one
  sudo chattr -i "$RESOLV_CONF" 2>/dev/null || true
  sudo rm -f "$RESOLV_CONF"
  echo "nameserver 127.0.0.1" | sudo tee "$RESOLV_CONF" >/dev/null
  sudo chattr +i "$RESOLV_CONF"
  done_msg "resolv.conf updated and made immutable"
fi

# 2g. Enable and start Unbound service
if rc-update show default 2>/dev/null | grep -q '\bunbound\b'; then
  skip "Unbound service already enabled in default runlevel"
else
  info "Enabling Unbound service..."
  sudo rc-update add unbound default
  done_msg "Unbound service enabled"
fi

if rc-service unbound status 2>/dev/null | grep -q "started"; then
  skip "Unbound service is already running"
else
  info "Starting Unbound service..."
  sudo rc-service unbound start
  done_msg "Unbound service started"
fi

# ==============================================================================
# FINALIZE: Restart NetworkManager to apply DNS changes
# ==============================================================================
msg "Restarting NetworkManager to apply DNS changes..."
sudo rc-service NetworkManager restart
done_msg "NetworkManager restarted"

echo ""
msg "Network optimization complete!"
info "Verify DoT is working: drill -T cloudflare.com"
info "Check unbound stats: sudo unbound-control stats_noreset"
