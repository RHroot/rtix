#!/bin/sh
set -eu

msg() { printf '\n==> %s\n' "$*"; }
info() { printf '  -> %s\n' "$*"; }
skip() { printf '  -> [SKIP] %s\n' "$*"; }
done_msg() { printf '  -> [DONE] %s\n' "$*"; }
tip() { printf '\n  -> [TIP] %s\n' "$*"; }
verify() { printf '  -> [VERIFY] %s\n' "$*"; }

msg "Configuring environment variables..."

ENV_FILE="/etc/environment"
if grep -q "PAGER=bat" "$ENV_FILE" 2>/dev/null && grep -q "EDITOR=nvim" "$ENV_FILE" 2>/dev/null; then
  skip "/etc/environment already configured."
else
  info "Appending to /etc/environment..."
  sudo tee -a "$ENV_FILE" >/dev/null <<'EOF'

# Custom Environment Variables
PAGER=bat
COLORTERM=truecolor
MANROFFOPT=-c
MANPAGER="sh -c 'col -bx | bat -l man -p'"
BROWSER=helium
EDITOR=nvim
VISUAL=nvim
XCURSOR_SIZE=30
XCURSOR_THEME=Bibata-Modern-Ice
QT_STYLE_OVERRIDE=adwaita-dark
GTK_THEME=Flat-Remix-GTK-Violet-Darkest
EOF
  done_msg "/etc/environment updated."
fi

PROFILE="$HOME/.profile"
if grep -q 'XDG_CONFIG_HOME' "$PROFILE" 2>/dev/null; then
  skip "~/.profile already configured."
else
  info "Appending XDG and PATH to ~/.profile..."
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
  done_msg "~/.profile updated."
fi

FISH_DIR="$HOME/.config/fish/conf.d"
mkdir -p "$FISH_DIR"

if [ ! -f "$FISH_DIR/00-path.fish" ]; then
  info "Creating fish path config..."
  echo 'fish_add_path ~/.local/bin ~/.local/share ~/.cargo/bin ~/.bun/bin ~/go/bin' >"$FISH_DIR/00-path.fish"
  done_msg "fish path config created."
else
  skip "fish path config already exists."
fi

if [ ! -f "$FISH_DIR/10-env.fish" ]; then
  info "Creating fish env config..."
  cat >"$FISH_DIR/10-env.fish" <<'FISH_EOF'
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_DATA_HOME "$HOME/.local/share"
set -gx XDG_CACHE_HOME "$HOME/.cache"
set -gx LESSHISTFILE "$HOME/.cache/less_history"
set -gx PYTHON_HISTORY "$HOME/.local/share/python/history"
FISH_EOF
  done_msg "fish env config created."
else
  skip "fish env config already exists."
fi

tip "Restart your terminal or run 'source ~/.profile' to apply changes."
verify "echo \$EDITOR && echo \$XDG_CONFIG_HOME"
