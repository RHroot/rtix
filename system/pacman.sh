#!/bin/sh
set -eu

msg() { printf '\n==> %s\n' "$*"; }
info() { printf '  -> %s\n' "$*"; }
skip() { printf '  -> [SKIP] %s\n' "$*"; }
done_msg() { printf '  -> [DONE] %s\n' "$*"; }
tip() { printf '\n  -> [TIP] %s\n' "$*"; }
verify() { printf '  -> [VERIFY] %s\n' "$*"; }

msg "Optimizing /etc/pacman.conf..."

if [ ! -f /etc/pacman.conf.original ]; then
  info "Creating original backup..."
  sudo cp /etc/pacman.conf /etc/pacman.conf.original
  done_msg "Backup saved to /etc/pacman.conf.original."
else
  skip "Original backup already exists."
fi

enable_setting() {
  local key="$1"
  local value="${2:-}"

  if grep -qE "^${key}([[:space:]]|$|=)" /etc/pacman.conf; then
    skip "$key is already active."
    return
  fi

  info "Enabling $key..."
  if [ -n "$value" ]; then
    sudo sed -i -E "s/^#[[:space:]]*${key}( =.*)?$/${key} = ${value}/" /etc/pacman.conf
  else
    sudo sed -i -E "s/^#[[:space:]]*${key}$/${key}/" /etc/pacman.conf
  fi
}

enable_setting "Color"
enable_setting "VerbosePkgLists"
enable_setting "ILoveCandy"

CORES=$(nproc)
if [ "$CORES" -lt 4 ]; then
  PARALLEL=4
elif [ "$CORES" -gt 8 ]; then
  PARALLEL=8
else
  PARALLEL=$CORES
fi

info "Detected $CORES CPU cores. Setting ParallelDownloads = $PARALLEL."
sudo sed -i -E "s/^#?[[:space:]]*ParallelDownloads[[:space:]]*=.*/ParallelDownloads = ${PARALLEL}/" /etc/pacman.conf
done_msg "ParallelDownloads optimized."

if grep -qE "^#\[lib32\]" /etc/pacman.conf; then
  info "Enabling [lib32] repository..."
  sudo sed -i 's/^#\[lib32\]/[lib32]/' /etc/pacman.conf
  sudo sed -i '/^\[lib32\]/,+1 s/^#Include/Include/' /etc/pacman.conf
  done_msg "[lib32] repository enabled."
else
  skip "[lib32] repository is already enabled."
fi

# Chaotic-AUR Setup (Lowest Priority)
if ! grep -q '^\[chaotic-aur\]' /etc/pacman.conf; then
  info "Setting up Chaotic-AUR (lowest priority)..."
  KEY_ID="3056513887B78AEB"

  # Dynamically fetch and sign key
  if sudo pacman-key --recv-key "$KEY_ID" --keyserver keyserver.ubuntu.com >/dev/null 2>&1; then
    sudo pacman-key --lsign-key "$KEY_ID" >/dev/null
    done_msg "Chaotic-AUR key fetched and signed."
  else
    msg "[ERROR] Failed to fetch Chaotic-AUR key. Skipping setup."
    exit 1
  fi

  # Install keyring and mirrorlist packages
  info "Installing Chaotic-AUR keyring and mirrorlist..."
  sudo pacman -U --noconfirm \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' >/dev/null

  # Append to the VERY END of pacman.conf to ensure lowest priority
  printf "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n" | sudo tee -a /etc/pacman.conf >/dev/null

  info "Syncing package databases..."
  sudo pacman -Sy --noconfirm >/dev/null
  done_msg "Chaotic-AUR configured at lowest priority."
else
  skip "Chaotic-AUR is already configured."
fi

tip "Repository priority is now: system > world > galaxy > lib32 > chaotic-aur"
verify "grep -E '^(Color|VerbosePkgLists|ILoveCandy|ParallelDownloads|\[chaotic-aur\])' /etc/pacman.conf"
