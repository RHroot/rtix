#!/bin/sh
set -eu

msg() { printf '\n==> %s\n' "$*"; }
info() { printf '  -> %s\n' "$*"; }
skip() { printf '  -> [SKIP] %s\n' "$*"; }
update() { printf '  -> [UPDATE] %s\n' "$*"; }
done_msg() { printf '  -> [DONE] %s\n' "$*"; }
tip() { printf '\n  -> [TIP] %s\n' "$*"; }
verify() { printf '  -> [VERIFY] %s\n' "$*"; }

msg "Configuring NetworkManager..."
NM_CONF_DIR="/etc/NetworkManager/conf.d"
sudo mkdir -p "$NM_CONF_DIR"

if [ -f "$NM_CONF_DIR/dns.conf" ] && grep -q "dns=none" "$NM_CONF_DIR/dns.conf"; then
  skip "NetworkManager DNS config already optimal."
else
  info "Writing NetworkManager DNS config..."
  sudo tee "$NM_CONF_DIR/dns.conf" >/dev/null <<'EOF'
[main]
dns=none
rc-manager=unmanaged
EOF
  done_msg "NetworkManager DNS config updated."
fi

if [ -f "$NM_CONF_DIR/wifi-powersave.conf" ] && grep -q "wifi.powersave=2" "$NM_CONF_DIR/wifi-powersave.conf"; then
  skip "NetworkManager WiFi powersave already disabled."
else
  info "Writing NetworkManager WiFi powersave config..."
  sudo tee "$NM_CONF_DIR/wifi-powersave.conf" >/dev/null <<'EOF'
[connection]
wifi.powersave=2
EOF
  done_msg "NetworkManager WiFi powersave config updated."
fi

msg "Configuring Unbound (DNS-over-TLS)..."
UNBOUND_UPDATED="false"

if ! pacman -Q unbound unbound-openrc >/dev/null 2>&1; then
  info "Installing unbound and unbound-openrc..."
  sudo pacman -S --noconfirm --needed unbound unbound-openrc >/dev/null
  done_msg "Unbound packages installed."
else
  skip "Unbound packages already installed."
fi

UNBOUND_CONF_DIR="/etc/unbound/unbound.conf.d"
sudo mkdir -p "$UNBOUND_CONF_DIR"

if [ -f "$UNBOUND_CONF_DIR/dot.conf" ] && grep -q "tls-upstream: yes" "$UNBOUND_CONF_DIR/dot.conf"; then
  skip "Unbound DoT config already optimal."
else
  update "Writing Unbound DoT configuration..."
  sudo tee "$UNBOUND_CONF_DIR/dot.conf" >/dev/null <<'EOF'
server:
    do-tcp: yes
    tls-cert-bundle: /etc/ssl/certs/ca-bundle.crt
    cache-max-ttl: 86400
    do-ip4: yes
    do-ip6: yes
    harden-dnssec-stripped: no
    tls-upstream: yes

forward-zone:
    name: "."
    forward-addr: 1.1.1.1@853#cloudflare-dns.com
    forward-addr: 1.0.0.1@853#cloudflare-dns.com
    forward-addr: 8.8.8.8@853#dns.google
    forward-addr: 8.8.4.4@853#dns.google
    forward-addr: 9.9.9.9@853#dns.quad9.net
    forward-addr: 149.112.112.112@853#dns.quad9.net
EOF
  UNBOUND_UPDATED="true"
  done_msg "Unbound DoT config written."
fi

if [ -f "$UNBOUND_CONF_DIR/remote-control.conf" ] && grep -q "control-enable: yes" "$UNBOUND_CONF_DIR/remote-control.conf"; then
  skip "Unbound remote-control already enabled."
else
  update "Writing Unbound remote-control configuration..."
  sudo tee "$UNBOUND_CONF_DIR/remote-control.conf" >/dev/null <<'EOF'
remote-control:
    control-enable: yes
    control-interface: 127.0.0.1
    control-port: 8953
    server-key-file: /etc/unbound/unbound_server.key
    server-cert-file: /etc/unbound/unbound_server.pem
    control-key-file: /etc/unbound/unbound_control.key
    control-cert-file: /etc/unbound/unbound_control.pem
EOF
  UNBOUND_UPDATED="true"
  done_msg "Unbound remote-control config written."
fi

if [ -f "/etc/unbound/unbound_server.key" ] && [ -f "/etc/unbound/unbound_control.key" ]; then
  skip "Unbound control certificates already exist."
else
  info "Generating unbound-control SSL certificates..."
  sudo unbound-control-setup >/dev/null 2>&1
  done_msg "Unbound control certificates generated."
fi

if grep -q "^include: /etc/unbound/unbound.conf.d/\*.conf" /etc/unbound/unbound.conf; then
  skip "Unbound main config already includes conf.d."
else
  update "Adding include directive to unbound.conf..."
  echo 'include: /etc/unbound/unbound.conf.d/*.conf' | sudo tee -a /etc/unbound/unbound.conf >/dev/null
  UNBOUND_UPDATED="true"
  done_msg "Include directive added."
fi

RESOLV_CONF="/etc/resolv.conf"
if [ -f "$RESOLV_CONF" ] && grep -q "^nameserver 127.0.0.1$" "$RESOLV_CONF" && lsattr "$RESOLV_CONF" 2>/dev/null | grep -q '\bi\b'; then
  skip "resolv.conf already points to 127.0.0.1 and is immutable."
else
  update "Updating resolv.conf to use local Unbound..."
  sudo chattr -i "$RESOLV_CONF" 2>/dev/null || true
  sudo rm -f "$RESOLV_CONF"
  echo "nameserver 127.0.0.1" | sudo tee "$RESOLV_CONF" >/dev/null
  sudo chattr +i "$RESOLV_CONF"
  done_msg "resolv.conf updated and made immutable."
fi

if rc-update show default 2>/dev/null | grep -q '\bunbound\b'; then
  skip "Unbound service already enabled."
else
  info "Enabling Unbound service..."
  sudo rc-update add unbound default >/dev/null
  done_msg "Unbound service enabled."
fi

if [ "$UNBOUND_UPDATED" = "true" ]; then
  info "Restarting Unbound to apply new configuration..."
  sudo rc-service unbound restart >/dev/null 2>&1 || true
  done_msg "Unbound restarted."
elif rc-service unbound status 2>/dev/null | grep -q "started"; then
  skip "Unbound service is already running."
else
  info "Starting Unbound service..."
  sudo rc-service unbound start >/dev/null 2>&1 || true
  done_msg "Unbound service started."
fi

msg "Restarting NetworkManager to apply DNS changes..."
sudo rc-service NetworkManager restart >/dev/null 2>&1 || true
done_msg "NetworkManager restarted."

tip "DNS queries are now encrypted via DoT and cached locally."
verify "drill -T cloudflare.com @127.0.0.1"
