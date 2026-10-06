#!/bin/sh
set -eu

msg() { printf '==> %s\n' "$*"; }

msg "Setting system-wide environment variables"

sudo tee /etc/environment >/dev/null <<'EOF'
PAGER=bat
COLORTERM=truecolor
MANROFFOPT=-c
MANPAGER=sh -c 'col -bx | bat -l man -p'

BROWSER=helium

EDITOR=nvim
VISUAL=nvim

MIRU_MODE=sub
MIRU_MENU=rofi
MIRU_PLAYER=mpv
MIRU_QUALITY=best
MIRU_DOWNLOAD_DIR=.

XCURSOR_SIZE=30
XCURSOR_THEME=Bibata-Modern-Ice
QT_STYLE_OVERRIDE "adwaita-dark"
GTK_THEME=Flat-Remix-GTK-Violet-Darkest
EOF

msg "Configuring Bash (~/.profile)"

PROFILE="$HOME/.profile"
if ! grep -q 'XDG_CONFIG_HOME' "$PROFILE" 2>/dev/null; then
  cat >>"$PROFILE" <<'PROFILE_EOF'
# XDG Base Directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export LESSHISTFILE="$HOME/.cache/less_history"
export PYTHON_HISTORY="$HOME/.local/share/python/history"

# Custom PATH
export PATH="$HOME/.local/bin:$HOME/.local/share:$HOME/.cargo/bin:$HOME/.bun/bin:$HOME/go/bin:$PATH"
PROFILE_EOF
  msg "Added XDG and PATH to ~/.profile"
else
  msg "~/.profile already configured. Skipping."
fi

msg "Configuring Fish (conf.d/ structure)"

FISH_DIR="$HOME/.config/fish"
CONF_D="$FISH_DIR/conf.d"
mkdir -p "$CONF_D"

# PATH setup
PATH_FISH="$CONF_D/00-path.fish"
if [ ! -f "$PATH_FISH" ]; then
  cat >"$PATH_FISH" <<'FISH_EOF'
fish_add_path ~/.local/bin ~/.local/share ~/.cargo/bin ~/.bun/bin ~/go/bin
FISH_EOF
  msg "Created conf.d/path.fish"
else
  msg "conf.d/path.fish already exists. Skipping."
fi

# Environment variables
ENV_FISH="$CONF_D/10-env.fish"
if [ ! -f "$ENV_FISH" ]; then
  cat >"$ENV_FISH" <<'FISH_EOF'
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_DATA_HOME "$HOME/.local/share"
set -gx XDG_CACHE_HOME "$HOME/.cache"
set -gx LESSHISTFILE "$HOME/.cache/less_history"
set -gx PYTHON_HISTORY "$HOME/.local/share/python/history"
FISH_EOF
  msg "Created conf.d/env.fish"
else
  msg "conf.d/env.fish already exists. Skipping."
fi

msg "Environment configured"
