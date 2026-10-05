#!/bin/sh
set -e

# 1. Exit immediately if paru is already installed
if command -v paru >/dev/null 2>&1; then
  echo "paru is already installed. Skipping."
  exit 0
fi

# 2. Check if rust was already installed so we don't remove it later
if pacman -Qq rust >/dev/null 2>&1; then
  REMOVE_RUST=false
else
  REMOVE_RUST=true
fi

# 3. Install build dependencies
sudo pacman -S --needed --noconfirm base-devel rust git

# 4. Use a safe temporary directory
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

# 5. Clone, build, and install
git clone https://aur.archlinux.org/paru.git "$BUILD_DIR/paru"
cd "$BUILD_DIR/paru"
makepkg -si --noconfirm

# 6. Remove rust only if we just installed it for this script
if [ "$REMOVE_RUST" = "true" ]; then
  echo "Removing rust to free up space..."
  sudo pacman -Rns --noconfirm rust
fi
