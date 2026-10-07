# Linux System Information Commands (Artix/OpenRC Edition)

A concise reference of useful commands to inspect system, hardware, and OS details on Artix with OpenRC.

______________________________________________________________________

## Core System Overview

### /etc/os-release
OS identity (replaces hostnamectl on OpenRC).

    cat /etc/os-release

______________________________________________________________________

### uname
Low-level kernel/system info.

    uname -a    # everything
    uname -r    # kernel version
    uname -m    # architecture

______________________________________________________________________

### fastfetch
Pretty system summary (you already have it installed).

    fastfetch
    fastfetch -c my.jsonc   # your custom preset

______________________________________________________________________

## CPU Information

### lscpu
Detailed CPU architecture and features.

    lscpu

______________________________________________________________________

### /proc/cpuinfo
Raw CPU details from kernel.

    cat /proc/cpuinfo

______________________________________________________________________

### cpupower
CPU frequency and governor info.

    cpupower frequency-info
    cpupower monitor           # real-time power states

______________________________________________________________________

## Memory

### free
Shows RAM and swap usage.

    free -h

______________________________________________________________________

### vmstat
Virtual memory statistics.

    vmstat 1    # refresh every second

______________________________________________________________________

## Disk & Storage

### lsblk
Lists block devices (disks, partitions).

    lsblk
    lsblk -f    # with filesystem info

______________________________________________________________________

### df
Filesystem disk usage.

    df -h
    df -hT      # with filesystem type

______________________________________________________________________

### btrfs (your filesystem)

    btrfs filesystem show
    btrfs filesystem usage /
    btrfs scrub status /

______________________________________________________________________

## Hardware Information

### lshw
Detailed hardware inventory.

    sudo lshw -short

______________________________________________________________________

### inxi
Clean, human-readable system summary.

    inxi -Fxz    # full info, hide sensitive data

______________________________________________________________________

### hwinfo
Alternative hardware probe.

    sudo hwinfo --short

______________________________________________________________________

## Firmware / BIOS

### dmidecode
BIOS/firmware details.

    sudo dmidecode -t bios
    sudo dmidecode -t system

______________________________________________________________________

### fwupdmgr
Manage firmware updates (if installed).

    fwupdmgr get-devices
    fwupdmgr get-updates

______________________________________________________________________

## Network

### ip
Modern network interface tool.

    ip a
    ip route

______________________________________________________________________

### ss
Socket statistics (replacement for netstat).

    ss -tuln        # listening ports
    ss -tnp         # established connections with process

______________________________________________________________________

### nmcli
NetworkManager control.

    nmcli general status
    nmcli device status
    nmcli connection show

______________________________________________________________________

### drill
DNS lookup (you have Unbound DoT set up).

    drill cloudflare.com
    drill -T cloudflare.com @127.0.0.1   # via your local DoT resolver

______________________________________________________________________

## Logs & Boot Info

### dmesg
Kernel ring buffer (boot messages).

    dmesg | less
    dmesg -T           # human-readable timestamps
    dmesg | grep -i error

______________________________________________________________________

### /var/log/
System logs (replaces journalctl on OpenRC).

    less /var/log/messages       # main system log
    less /var/log/rc.log         # OpenRC boot log
    sudo less /var/log/pacman.log
    tail -f /var/log/messages    # follow in real-time

______________________________________________________________________

### uptime
System running time and load.

    uptime

______________________________________________________________________

## OpenRC Services

### rc-status
Current state of all services.

    rc-status
    rc-status default    # services in default runlevel

______________________________________________________________________

### rc-update
Manage services across runlevels.

    rc-update show                    # all enabled services
    rc-update add <service> default   # enable at boot
    rc-update del <service> default   # disable at boot

______________________________________________________________________

### rc-service
Control services manually.

    rc-service <service> status
    rc-service <service> start
    rc-service <service> stop
    rc-service <service> restart

______________________________________________________________________

## Power Management

### tlp-stat
TLP power management details.

    sudo tlp-stat -s     # summary
    sudo tlp-stat -b     # battery info
    sudo tlp-stat -c     # active config

______________________________________________________________________

### upower
Battery and power devices.

    upower -d
    upower -i /org/freedesktop/UPower/devices/battery_BAT0

______________________________________________________________________

### acpi
Quick battery/thermal status.

    acpi -V              # everything
    acpi -b              # battery only
    acpi -t              # thermal only

______________________________________________________________________

## DNS-over-TLS (Unbound)

    sudo unbound-control status
    sudo unbound-control stats_noreset | grep cachehits
    sudo unbound-control lookup cloudflare.com

______________________________________________________________________

## NVIDIA

    nvidia-smi                    # GPU status and processes
    nvidia-smi -q                 # detailed info
    nvidia-offload glxinfo | grep "OpenGL vendor"   # test offload

______________________________________________________________________

## Quick Combined View (Alias)

Add this to your shell config (~/.config/fish/conf.d/ or ~/.profile):

Bash/Zsh:
    alias sysinfo="cat /etc/os-release | grep PRETTY && echo && lscpu | head -15 && echo && free -h && echo && rc-status"

Fish:
    alias sysinfo="cat /etc/os-release | grep PRETTY; echo; lscpu | head -15; echo; free -h; echo; rc-status"

______________________________________________________________________

## Notes

- No systemd: hostnamectl, journalctl, systemctl don't exist on Artix/OpenRC
- Logs: Use /var/log/messages and dmesg instead of journalctl
- Services: Use rc-service and rc-update instead of systemctl
- Prefer modern tools: ip over ifconfig, ss over netstat
- Fastfetch: Your best friend for a pretty system overview

______________________________________________________________________

## Minimal Daily Set

If you only remember a few commands:

    fastfetch              # pretty overview
    lscpu                  # CPU info
    free -h                # RAM usage
    lsblk                  # disks
    df -h                  # filesystem usage
    rc-status              # service states
    dmesg | tail           # recent kernel messages

______________________________________________________________________

End of file.
