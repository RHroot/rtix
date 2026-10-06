#!/bin/sh
set -e

# ==============================================================================
# MODE: REMOVE
# ==============================================================================
if [ "$1" = "remove" ]; then
  echo "==> Removing paru and Chaotic-AUR..."

  # Remove paru
  sudo pacman -Rns --noconfirm paru 2>/dev/null || true

  # Remove Chaotic-AUR config from pacman.conf
  sudo sed -i '/^\[chaotic-aur\]/,/Include = \/etc\/pacman.d\/chaotic-mirrorlist/d' /etc/pacman.conf

  # Remove Chaotic-AUR packages
  sudo pacman -Rns --noconfirm chaotic-keyring chaotic-mirrorlist 2>/dev/null || true

  # Clean pacman cache
  sudo pacman -Sc --noconfirm

  echo "==> Cleanup complete."
  exit 0
fi

# ==============================================================================
# MODE: INSTALL PARU (if not present)
# ==============================================================================
if command -v paru >/dev/null 2>&1; then
  echo "==> paru is already installed. Skipping build."
else
  echo "==> Building and installing paru..."

  # Track if rust was pre-existing to clean it up later
  if pacman -Qq rust >/dev/null 2>&1; then
    REMOVE_RUST=false
  else
    REMOVE_RUST=true
  fi

  sudo pacman -S --needed --noconfirm base-devel rust git

  BUILD_DIR="$(mktemp -d)"
  trap 'rm -rf "$BUILD_DIR"' EXIT

  git clone https://aur.archlinux.org/paru.git "$BUILD_DIR/paru"
  cd "$BUILD_DIR/paru"
  makepkg -si --noconfirm

  if [ "$REMOVE_RUST" = "true" ]; then
    echo "==> Removing rust to free up space..."
    sudo pacman -Rns --noconfirm rust
  fi
fi

# ==============================================================================
# MODE: SETUP CHAOTIC-AUR (if not present)
# ==============================================================================
if ! grep -q '^\[chaotic-aur\]' /etc/pacman.conf; then
  echo "==> Setting up Chaotic-AUR with high priority..."

  # CORRECT CURRENT KEY ID (Pedro Henrique Lara Campos)
  KEY_ID="3056513887B78AEB"
  KEY_FETCHED=false

  echo "==> Fetching Chaotic-AUR key..."
  for server in "keyserver.ubuntu.com" "pgp.mit.edu" "keys.gnupg.net"; do
    echo "  -> Trying $server..."
    if timeout 10 sudo pacman-key --recv-key "$KEY_ID" --keyserver "$server" 2>/dev/null; then
      KEY_FETCHED=true
      break
    fi
  done

  if [ "$KEY_FETCHED" = "false" ]; then
    echo ""
    echo "==> ERROR: Could not fetch key automatically."
    echo "==> Please run these commands manually, then run this script again:"
    echo ""
    echo "    sudo pacman-key --recv-key $KEY_ID --keyserver keyserver.ubuntu.com"
    echo "    sudo pacman-key --lsign-key $KEY_ID"
    echo ""
    exit 1
  fi

  sudo pacman-key --lsign-key "$KEY_ID"
  echo "==> Key imported successfully."

  echo "==> Installing Chaotic-AUR keyring and mirrorlist..."
  sudo pacman -U --noconfirm \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

  echo "==> Adding Chaotic-AUR to pacman.conf with high priority..."
  # Use robust GNU sed to insert BEFORE [system], [world], or [core]
  if grep -q '^\[system\]' /etc/pacman.conf; then
    sudo sed -i 's/^\(\[system\]\)/[chaotic-aur]\nInclude = \/etc\/pacman.d\/chaotic-mirrorlist\n\n\1/' /etc/pacman.conf
  elif grep -q '^\[world\]' /etc/pacman.conf; then
    sudo sed -i 's/^\(\[world\]\)/[chaotic-aur]\nInclude = \/etc\/pacman.d\/chaotic-mirrorlist\n\n\1/' /etc/pacman.conf
  elif grep -q '^\[core\]' /etc/pacman.conf; then
    sudo sed -i 's/^\(\[core\]\)/[chaotic-aur]\nInclude = \/etc\/pacman.d\/chaotic-mirrorlist\n\n\1/' /etc/pacman.conf
  else
    printf "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n" | sudo tee -a /etc/pacman.conf >/dev/null
  fi

  sudo pacman -Sy --noconfirm
  echo "==> Chaotic-AUR setup complete."
else
  echo "==> Chaotic-AUR is already configured. Skipping."
fi

echo "==> All done! You can now use 'pacman' to install pre-compiled AUR packages."
