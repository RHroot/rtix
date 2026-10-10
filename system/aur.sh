#!/bin/sh
set -eu

msg() { printf '\n==> %s\n' "$*"; }
info() { printf '  -> %s\n' "$*"; }
skip() { printf '  -> [SKIP] %s\n' "$*"; }
done_msg() { printf '  -> [DONE] %s\n' "$*"; }
tip() { printf '\n  -> [TIP] %s\n' "$*"; }

# Remove mode
if [ "${1:-}" = "remove" ]; then
  msg "Removing AUR helpers and cleaning up..."
  sudo pacman -Rns --noconfirm paru yay 2>/dev/null || true
  sudo pacman -Sc --noconfirm
  done_msg "Cleanup complete."
  exit 0
fi

# Get choice
HELPER="${1:-}"
if [ -z "$HELPER" ]; then
  printf "Choose AUR helper (paru/yay): "
  read -r HELPER
fi

HELPER=$(echo "$HELPER" | tr '[:upper:]' '[:lower:]')
if [ "$HELPER" != "paru" ] && [ "$HELPER" != "yay" ]; then
  msg "[ERROR] Invalid choice. Please choose 'paru' or 'yay'."
  exit 1
fi

msg "Setting up $HELPER..."

if command -v "$HELPER" >/dev/null 2>&1; then
  skip "$HELPER is already installed."
  exit 0
fi

# Determine build dependency
if [ "$HELPER" = "paru" ]; then
  BUILD_DEP="rust"
else
  BUILD_DEP="go"
fi

# Check if dependency was already installed
REMOVE_DEP="false"
if ! pacman -Q "$BUILD_DEP" >/dev/null 2>&1; then
  REMOVE_DEP="true"
fi

info "Installing build dependencies ($BUILD_DEP)..."
sudo pacman -S --needed --noconfirm base-devel git "$BUILD_DEP" >/dev/null

BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

info "Cloning and building $HELPER..."
git clone "https://aur.archlinux.org/${HELPER}.git" "$BUILD_DIR/$HELPER" >/dev/null 2>&1
cd "$BUILD_DIR/$HELPER"
makepkg -si --noconfirm >/dev/null

# Cleanup
if [ "$REMOVE_DEP" = "true" ]; then
  info "Removing temporary build dependency ($BUILD_DEP) to free up space..."
  sudo pacman -Rns --noconfirm "$BUILD_DEP" >/dev/null
fi

sudo pacman -Sc --noconfirm >/dev/null
done_msg "$HELPER installed successfully."
tip "Use '$HELPER -S <package>' to install AUR packages."
