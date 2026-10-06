#!/bin/sh
set -e

echo "==> Optimizing /etc/pacman.conf..."

# 1. Single static backup (prevents infinite backups)
if [ ! -f /etc/pacman.conf.original ]; then
  sudo cp /etc/pacman.conf /etc/pacman.conf.original
  echo "  -> Original backup saved to /etc/pacman.conf.original"
else
  echo "  -> Backup already exists. Skipping backup step."
fi

# Helper function to safely enable settings
enable_setting() {
  local key="$1"
  local value="$2"

  # Check if the setting is already active (starts with key, not #)
  if grep -qE "^${key}([[:space:]]|$|=)" /etc/pacman.conf; then
    echo "  -> ${key} is already active."
    return
  fi

  echo "  -> Enabling ${key}..."
  if [ -n "$value" ]; then
    sudo sed -i -E "s/^#[[:space:]]*${key}( =.*)?$/${key} = ${value}/" /etc/pacman.conf
  else
    sudo sed -i -E "s/^#[[:space:]]*${key}$/${key}/" /etc/pacman.conf
  fi
}

# 2. Enable Visual & Functional Improvements
enable_setting "Color"
enable_setting "VerbosePkgLists"
enable_setting "ILoveCandy"

# 3. Dynamic Parallel Downloads (Force update to optimal value, min 4, max 8)
CORES=$(nproc)
if [ "$CORES" -lt 4 ]; then
  PARALLEL=4
elif [ "$CORES" -gt 8 ]; then
  PARALLEL=8
else
  PARALLEL=$CORES
fi

echo "  -> Detected $CORES CPU cores. Forcing ParallelDownloads = $PARALLEL."
# Force replace any existing ParallelDownloads line (commented or not, any value)
sudo sed -i -E "s/^#?[[:space:]]*ParallelDownloads[[:space:]]*=.*/ParallelDownloads = ${PARALLEL}/" /etc/pacman.conf

# 4. Enable lib32 repository (32-bit compatibility for Steam, Wine, Discord, etc.)
if grep -qE "^#\[lib32\]" /etc/pacman.conf; then
  echo "  -> Enabling [lib32] repository..."
  sudo sed -i 's/^#\[lib32\]/[lib32]/' /etc/pacman.conf
  # Uncomment the Include line immediately following [lib32]
  sudo sed -i '/^\[lib32\]/,+1 s/^#Include/Include/' /etc/pacman.conf
else
  echo "  -> [lib32] repository is already enabled."
fi

echo ""
echo "==> pacman.conf optimized successfully!"
echo "==> To restore the original file, run: sudo cp /etc/pacman.conf.original /etc/pacman.conf"
