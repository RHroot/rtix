#!/bin/sh
set -eu

msg() { printf '\n==> %s\n' "$*"; }
info() { printf '  -> %s\n' "$*"; }
skip() { printf '  -> [SKIP] %s\n' "$*"; }
done_msg() { printf '  -> [DONE] %s\n' "$*"; }
tip() { printf '\n  -> [TIP] %s\n' "$*"; }
verify() { printf '  -> [VERIFY] %s\n' "$*"; }

if [ "${1:-}" = "remove" ]; then
  msg "Removing paru and Chaotic-AUR..."
  sudo pacman -Rns --noconfirm paru 2>/dev/null || true
  sudo sed -i '/^\[chaotic-aur\]/,/Include = \/etc\/pacman\.d\/chaotic-mirrorlist/d' /etc/pacman.conf
  sudo pacman -Rns --noconfirm chaotic-keyring chaotic-mirrorlist 2>/dev/null || true
  sudo pacman -Sc --noconfirm
  done_msg "Cleanup complete."
  exit 0
fi

msg "Setting up AUR helpers..."

if command -v paru >/dev/null 2>&1; then
  skip "paru is already installed."
else
  info "Building and installing paru..."
  REMOVE_RUST="false"
  if pacman -Q rust >/dev/null 2>&1; then
    REMOVE_RUST="false"
  else
    REMOVE_RUST="true"
  fi

  sudo pacman -S --needed --noconfirm base-devel rust git >/dev/null

  BUILD_DIR="$(mktemp -d)"
  trap 'rm -rf "$BUILD_DIR"' EXIT
  git clone https://aur.archlinux.org/paru.git "$BUILD_DIR/paru" >/dev/null 2>&1
  cd "$BUILD_DIR/paru"
  makepkg -si --noconfirm >/dev/null

  if [ "$REMOVE_RUST" = "true" ]; then
    info "Removing rust build dependency to free up space..."
    sudo pacman -Rns --noconfirm rust >/dev/null
  fi
  done_msg "paru installed successfully."
fi

if grep -q '^\[chaotic-aur\]' /etc/pacman.conf; then
  skip "Chaotic-AUR is already configured."
else
  info "Setting up Chaotic-AUR with high priority..."
  KEY_ID="3056513887B78AEB"
  KEY_FETCHED="false"

  for server in "keyserver.ubuntu.com" "pgp.mit.edu" "keys.gnupg.net"; do
    if timeout 10 sudo pacman-key --recv-key "$KEY_ID" --keyserver "$server" >/dev/null 2>&1; then
      KEY_FETCHED="true"
      break
    fi
  done

  if [ "$KEY_FETCHED" = "false" ]; then
    printf "\n[ERROR] Could not fetch key automatically.\n"
    printf "Please run manually:\n  sudo pacman-key --recv-key %s --keyserver keyserver.ubuntu.com\n  sudo pacman-key --lsign-key %s\n" "$KEY_ID" "$KEY_ID"
    exit 1
  fi

  sudo pacman-key --lsign-key "$KEY_ID" >/dev/null
  sudo pacman -U --noconfirm \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' >/dev/null

  if grep -q '^\[system\]' /etc/pacman.conf; then
    sudo sed -i 's/^\(\[system\]\)/[chaotic-aur]\nInclude = \/etc\/pacman.d\/chaotic-mirrorlist\n\n\1/' /etc/pacman.conf
  elif grep -q '^\[world\]' /etc/pacman.conf; then
    sudo sed -i 's/^\(\[world\]\)/[chaotic-aur]\nInclude = \/etc\/pacman.d\/chaotic-mirrorlist\n\n\1/' /etc/pacman.conf
  else
    printf "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n" | sudo tee -a /etc/pacman.conf >/dev/null
  fi
  sudo pacman -Sy --noconfirm >/dev/null
  done_msg "Chaotic-AUR configured with high priority."
fi

tip "Use 'paru -S <package>' to install AUR packages."
verify "paru -V"
