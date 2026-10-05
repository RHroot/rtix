# 📖 The Complete Guide to Writing and Managing `systemd` Services

______________________________________________________________________

## 🟢 Introduction: What is `systemd`?

`systemd` is the **init system** (PID 1) on most modern Linux distributions. It is the first process that starts at boot and manages:

- **System initialization** (boot targets, mounts, devices).
- **Service supervision** (starting, stopping, restarting daemons).
- **Logging** via `journald`.
- **Dependencies & ordering** of services.
- **Extra features** like scheduling (`.timer`), on-demand activation (`.socket`), and filesystem triggers (`.path`).

The building block of systemd is the **unit file** — a text configuration file that defines how systemd should manage something.

______________________________________________________________________

## 🟢 Unit Types

Units are identified by their **file extension**:

| Unit Type | Extension | Purpose |
|-------------|------------|---------|
| **Service** | `.service` | Runs daemons or applications (most common). |
| **Socket** | `.socket` | On-demand service activation via sockets. |
| **Timer** | `.timer` | Task scheduling (cron replacement). |
| **Target** | `.target` | Groups of units (like runlevels). |
| **Path** | `.path` | Trigger when a file/directory changes. |
| **Mount** | `.mount` | Manage filesystems. |
| **Automount** | `.automount` | Auto-mount filesystems on demand. |
| **Device** | `.device` | Manage hardware devices. |
| **Slice** | `.slice` | Control resources via cgroups. |
| **Scope** | `.scope` | Manage external processes not started by systemd. |

👉 You will mostly work with **`.service`** files, but other units can extend functionality.

______________________________________________________________________

## 🟢 Anatomy of a `.service` File

A unit file is an **INI-style** text file. It typically has three sections:

```ini
[Unit]
Description=My Custom Service
Documentation=https://example.com/docs
After=network.target
Requires=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/myapp/server.py
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/bin/kill -TERM $MAINPID
Restart=on-failure
RestartSec=5
User=myuser
WorkingDirectory=/opt/myapp
Environment="PORT=8080" "ENV=production"
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

______________________________________________________________________

## 🟢 Section 1: `[Unit]`

Defines **metadata and dependencies**.

- `Description=` → Short text about the service.
- `Documentation=` → Link(s) to docs/manpages.
- `Requires=` → Strong dependency (service fails if dependency fails).
- `Wants=` → Soft dependency (not fatal if missing).
- `After=` / `Before=` → Startup/shutdown ordering.
- `Conflicts=` → Ensure two units never run together.
- `ConditionXYZ=` → Conditional start (e.g., `ConditionPathExists=/etc/myapp.conf`).

______________________________________________________________________

## 🟢 Section 2: `[Service]`

Defines **how the service runs**.

### 🔹 Service Types

- `Type=simple` → Default, run `ExecStart` directly.
- `Type=forking` → For traditional daemons that fork.
- `Type=oneshot` → For short-lived tasks (e.g., setup scripts).
- `Type=notify` → Service signals systemd when ready.
- `Type=dbus` → For services using D-Bus.

### 🔹 Commands

- `ExecStart=` → Main command (required).
- `ExecReload=` → Reload command (`systemctl reload`).
- `ExecStop=` → Stop command.
- `ExecStartPre=` / `ExecStartPost=` → Commands before/after start.
- `ExecStopPost=` → Commands after stop.

### 🔹 Restart Policies

```ini
Restart=no          # Default
Restart=on-failure  # Restart if exit code != 0
Restart=always      # Always restart
Restart=on-abort    # Restart if killed by signal
RestartSec=5        # Delay before restart
```

### 🔹 Runtime Options

- `User=` / `Group=` → Run as non-root.
- `WorkingDirectory=` → Change directory before running.
- `Environment=` → Inline environment variables.
- `EnvironmentFile=` → Load env vars from file.
- `PIDFile=` → Required for `Type=forking`.

### 🔹 Logging

- `StandardOutput=journal`
- `StandardError=journal`
- Can log to files:
  ```ini
  StandardOutput=append:/var/log/myapp.log
  ```

______________________________________________________________________

## 🟢 Section 3: `[Install]`

Defines how this unit integrates into the system.

- `WantedBy=` → Which target pulls this in (commonly `multi-user.target`).
- `RequiredBy=` → Stronger dependency version.
- `Also=` → Enable multiple units together.

Used with:

```bash
systemctl enable myservice.service
systemctl disable myservice.service
```

______________________________________________________________________

## 🟢 Managing Services

### Start/Stop/Restart

```bash
systemctl start myservice.service
systemctl stop myservice.service
systemctl restart myservice.service
systemctl reload myservice.service
```

### Enable/Disable at Boot

```bash
systemctl enable myservice.service
systemctl disable myservice.service
```

### Status & Logs

```bash
systemctl status myservice.service
journalctl -u myservice.service
journalctl -u myservice.service -f   # Follow logs live
```

### Apply Changes

```bash
systemctl daemon-reload
```

______________________________________________________________________

## 🟢 Advanced Features

### 🔹 Multiple Instances (Template Units)

```ini
[Service]
ExecStart=/usr/bin/myapp --config /etc/myapp/%i.conf
```

Run instances:

```bash
systemctl start myapp@instance1
systemctl start myapp@instance2
```

______________________________________________________________________

### 🔹 Resource Control (cgroups)

```ini
[Service]
MemoryLimit=500M
CPUQuota=50%
TasksMax=200
```

______________________________________________________________________

### 🔹 Security Hardening

```ini
[Service]
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadOnlyPaths=/etc
ReadWritePaths=/var/lib/myapp
```

______________________________________________________________________

### 🔹 Timeouts

```ini
TimeoutStartSec=30
TimeoutStopSec=15
```

______________________________________________________________________

## 🟢 Debugging and Diagnostics

- Verify syntax:
  ```bash
  systemd-analyze verify myservice.service
  ```
- Boot performance:
  ```bash
  systemd-analyze blame
  ```
- Show dependencies:
  ```bash
  systemctl list-dependencies myservice.service
  ```

______________________________________________________________________

## 🟢 Practical Examples

### Example 1: Long-Running Daemon

```ini
[Unit]
Description=Gunicorn Web Server
After=network.target

[Service]
Type=simple
User=webapp
WorkingDirectory=/srv/webapp
ExecStart=/usr/local/bin/gunicorn -b 0.0.0.0:8000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
```

______________________________________________________________________

### Example 2: One-Shot Script

```ini
[Unit]
Description=Initialize Database
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/init-db.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
```

______________________________________________________________________

### Example 3: Timer + Service (Cron Replacement)

**Service:**

```ini
[Unit]
Description=Backup Service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
```

**Timer:**

```ini
[Unit]
Description=Run Backup Daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

Enable timer:

```bash
systemctl enable --now backup.timer
```

______________________________________________________________________

## 🟢 Best Practices

✅ Always run as non-root (`User=`).\
✅ Use `Restart=on-failure` for daemons.\
✅ Prefer `journalctl` logs over log files.\
✅ Store custom units in `/etc/systemd/system/` (not `/usr/lib`).\
✅ Use `systemctl edit myservice` instead of editing vendor files directly.

______________________________________________________________________

## 🟢 Master `.service` Template

Here’s a **copy-paste template** with everything you might need:

```ini
[Unit]
Description=My Custom Service
Documentation=man:myservice(8) https://example.com/docs
Requires=network.target
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/myapp --option
ExecStartPre=/usr/bin/echo "Starting..."
ExecStartPost=/usr/bin/echo "Started!"
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/bin/kill -TERM $MAINPID
ExecStopPost=/usr/bin/echo "Stopped!"
PIDFile=/run/myapp.pid

Restart=on-failure
RestartSec=5

User=myuser
Group=mygroup
WorkingDirectory=/var/lib/myapp
Environment="ENV=production"
EnvironmentFile=-/etc/myapp/env

StandardOutput=journal
StandardError=journal

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
MemoryLimit=500M
CPUQuota=50%

TimeoutStartSec=30
TimeoutStopSec=15

[Install]
WantedBy=multi-user.target
```

______________________________________________________________________

## ✅ Conclusion

With this guide, you can:

- Understand **systemd units and services**.
- Write `.service` files with **all functionality**.
- Use advanced features: templates, timers, resource control, hardening.
- Debug and optimize your system services.
