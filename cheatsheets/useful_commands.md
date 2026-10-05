# Linux System Information Commands

A concise reference of useful commands to inspect system, hardware, and OS details.

______________________________________________________________________

## 🧠 Core System Overview

### `hostnamectl`

Provides a structured summary of system identity, OS, kernel, and firmware.

```bash
hostnamectl
```

______________________________________________________________________

### `uname`

Low-level kernel/system info.

```bash
uname -a    # everything
uname -r    # kernel version
uname -m    # architecture
```

______________________________________________________________________

## ⚙️ CPU Information

### `lscpu`

Detailed CPU architecture and features.

```bash
lscpu
```

______________________________________________________________________

### `/proc/cpuinfo`

Raw CPU details from kernel.

```bash
cat /proc/cpuinfo
```

______________________________________________________________________

## 💾 Memory

### `free`

Shows RAM and swap usage.

```bash
free -h
```

______________________________________________________________________

## 💽 Disk & Storage

### `lsblk`

Lists block devices (disks, partitions).

```bash
lsblk
```

______________________________________________________________________

### `df`

Filesystem disk usage.

```bash
df -h
```

______________________________________________________________________

## 🧱 Hardware Information

### `lshw` (may need install)

Detailed hardware inventory.

```bash
sudo lshw -short
```

______________________________________________________________________

### `inxi` (optional tool)

Clean, human-readable system summary.

```bash
inxi -Fx
```

______________________________________________________________________

## 🔌 Firmware / BIOS

### `hostnamectl`

Already includes firmware version and age.

______________________________________________________________________

### `fwupdmgr`

Manage firmware updates.

```bash
fwupdmgr get-devices
fwupdmgr get-updates
```

______________________________________________________________________

## 🌐 Network

### `ip`

Modern network interface tool.

```bash
ip a
```

______________________________________________________________________

### `ss`

Socket statistics (replacement for netstat).

```bash
ss -tuln
```

______________________________________________________________________

## 🔍 Logs & Boot Info

### `journalctl`

System logs.

```bash
journalctl -b
```

______________________________________________________________________

### `uptime`

System running time and load.

```bash
uptime
```

______________________________________________________________________

## 🧪 Quick Combined View (Alias)

Add this to your shell config (`.zshrc` / `.bashrc`):

```bash
alias sysinfo="hostnamectl && echo && lscpu | head -15 && echo && free -h"
```

______________________________________________________________________

## ✅ Notes

- Prefer modern tools (`ip`, `ss`) over deprecated ones (`ifconfig`, `netstat`)
- `hostnamectl` is best for quick overview
- Combine commands depending on use case (debugging vs monitoring)

______________________________________________________________________

## 📌 Minimal Daily Set

If you only remember a few commands:

```bash
hostnamectl
lscpu
free -h
lsblk
df -h
```

______________________________________________________________________

End of file.
