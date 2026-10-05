function hyprctl_fixed
  set -l d "$XDG_RUNTIME_DIR/hypr"
  if not test -d "$d"
    set d "/run/user/"(id -u)"/hypr"
  end

  if not test -d "$d"
    printf 'no hypr socket dir: %s\n' "$d" >&2
    return 1
  end

  set -l ssout (ss -xlp 2>/dev/null || true)

  # Use existing signature if valid
  if set -q HYPRLAND_INSTANCE_SIGNATURE
    set -l cand "$d/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock"
    if string match -q "*$cand*" $ssout
      hyprctl $argv
      return $status
    end
  end

  # Find valid instance
  for dir in $d/*/
    set -l path (string trim -r -c / $dir)/.socket.sock
    if string match -q "*$path*" $ssout
      set -gx HYPRLAND_INSTANCE_SIGNATURE (basename (string trim -r -c / $dir))
      hyprctl $argv
      return $status
    end
  end

  # Fallback: newest directory
  set -l arr (ls -1dt $d/*/ 2>/dev/null)
  if test (count $arr) -gt 0
    set -gx HYPRLAND_INSTANCE_SIGNATURE (basename (string trim -r -c / $arr[1]))
  end

  hyprctl $argv
end
