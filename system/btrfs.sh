#!/bin/sh
set -eu

msg() { printf '\n==> %s\n' "$*"; }
info() { printf '  -> %s\n' "$*"; }
skip() { printf '  -> [SKIP] %s\n' "$*"; }
done_msg() { printf '  -> [DONE] %s\n' "$*"; }
tip() { printf '\n  -> [TIP] %s\n' "$*"; }
verify() { printf '  -> [VERIFY] %s\n' "$*"; }

msg "Checking for btrfs filesystems..."
BTRFS_MOUNTS=$(findmnt -n -o TARGET -t btrfs 2>/dev/null | tr '\n' ' ' || true)

if [ -z "$BTRFS_MOUNTS" ]; then
  skip "No btrfs filesystems detected. Nothing to do."
  exit 0
fi

info "Found btrfs mounts:"
for m in $BTRFS_MOUNTS; do info "  $m"; done
echo ""

msg "Checking cron daemon..."
if ! command -v crontab >/dev/null 2>&1; then
  info "Installing cronie-openrc..."
  sudo pacman -S --noconfirm --needed cronie-openrc >/dev/null
  done_msg "cronie installed."
else
  skip "cronie is already installed."
fi

if ! rc-service cronie status 2>/dev/null | grep -q "started"; then
  msg "Enabling cronie service..."
  sudo rc-update add cronie default >/dev/null 2>&1 || true
  sudo rc-service cronie start >/dev/null 2>&1 || true
  done_msg "cronie enabled and started."
else
  skip "cronie is already running."
fi

CRON_DIR="/etc/cron.weekly"
if [ ! -d "$CRON_DIR" ]; then
  msg "Creating $CRON_DIR..."
  sudo mkdir -p "$CRON_DIR"
  done_msg "Directory created."
else
  skip "$CRON_DIR already exists."
fi

FSTAB_BAK="/etc/fstab.bak.pre-btrfs-opt"
if [ ! -f "$FSTAB_BAK" ]; then
  msg "Backing up /etc/fstab..."
  sudo cp /etc/fstab "$FSTAB_BAK"
  done_msg "Backup saved to $FSTAB_BAK."
else
  skip "fstab backup already exists at $FSTAB_BAK."
fi

msg "Optimizing btrfs mount options..."
for mount_point in $BTRFS_MOUNTS; do
  info "Checking $mount_point..."
  fstab_line=$(grep -E "^[^#].*[[:space:]]${mount_point}[[:space:]]" /etc/fstab 2>/dev/null || true)

  if [ -z "$fstab_line" ]; then
    skip "$mount_point not found in fstab (might be a subvolume)."
    continue
  fi

  current_opts=$(echo "$fstab_line" | awk '{print $4}')
  new_opts="$current_opts"
  changed="false"

  for opt in "compress=zstd:3" "noatime" "space_cache=v2" "discard=async"; do
    case "$opt" in
      compress=*)
        if echo "$current_opts" | grep -q "compress="; then continue; fi
        ;;
      *)
        if echo "$current_opts" | grep -q "$opt"; then continue; fi
        ;;
    esac
    new_opts="${new_opts},${opt}"
    changed="true"
    info "  Adding: $opt"
  done

  if [ "$changed" = "true" ]; then
    sudo awk -v mp="$mount_point" -v old="$current_opts" -v new="$new_opts" '
      $0 ~ "^[^#]" && $2 == mp { sub(old, new) } { print }
    ' /etc/fstab >/tmp/fstab.tmp
    sudo mv /tmp/fstab.tmp /etc/fstab
    done_msg "$mount_point: fstab updated."
  else
    skip "$mount_point: all options already optimal."
  fi
done

msg "Setting up btrfs maintenance cron jobs..."
CRON_FILE="/etc/cron.weekly/btrfs-maintenance"

if [ -f "$CRON_FILE" ] && grep -q "btrfs scrub" "$CRON_FILE"; then
  skip "btrfs maintenance cron job already exists."
else
  info "Creating weekly maintenance script..."
  BTRFS_UUIDS=$(lsblk -n -o UUID,FSTYPE 2>/dev/null | awk '$2=="btrfs" {print $1}' | sort -u || true)

  sudo tee "$CRON_FILE" >/dev/null <<'CRON_HEADER'
#!/bin/sh
# btrfs maintenance: weekly fstrim, scrub, and light balance
fstrim --all 2>/dev/null || true
CRON_HEADER

  if [ -n "$BTRFS_UUIDS" ]; then
    for uuid in $BTRFS_UUIDS; do
      mount_target=$(findmnt -n -o TARGET -U "$uuid" 2>/dev/null || true)
      if [ -n "$mount_target" ]; then
        echo "btrfs scrub start -Bd \"$mount_target\" 2>/dev/null || true" | sudo tee -a "$CRON_FILE" >/dev/null
      fi
    done
  fi

  for mount_point in $BTRFS_MOUNTS; do
    echo "btrfs balance start -dusage=50 -musage=50 \"$mount_point\" 2>/dev/null || true" | sudo tee -a "$CRON_FILE" >/dev/null
  done

  sudo chmod +x "$CRON_FILE"
  done_msg "Cron job created at $CRON_FILE."
fi

tip "Reboot or run 'sudo mount -o remount /' to apply new mount options."
verify "findmnt -o TARGET,FSTYPE,OPTIONS -t btrfs | grep compress"
