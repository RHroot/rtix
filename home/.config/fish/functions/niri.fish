function niri --wraps niri
    if set -q XDG_RUNTIME_DIR
        if test -z "$NIRI_SOCKET"; or not command niri msg outputs >/dev/null 2>&1
            for sock in (ls -1t -- "$XDG_RUNTIME_DIR"/niri*.sock 2>/dev/null)
                if test -S "$sock"; and env NIRI_SOCKET="$sock" command niri msg outputs >/dev/null 2>&1
                    set -gx NIRI_SOCKET "$sock"
                    break
                end
            end
        end
    end

    command niri $argv
end
