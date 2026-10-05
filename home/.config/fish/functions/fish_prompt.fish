function _nixprompt_config
    # Define active features
    set -g use_colors true
    set -g use_glyphs true
    set -g use_badges true

    # Define custom colors
    set -g color_primary "785cea"
    set -g color_secondary "f5992e"
    set -g color_neutral "6B9E6B"
    set -g color_global ""

    set -g glyph_badge_left ""
    set -g glyph_badge_right ""

    # Define main color
    if is_root
        set color_global $color_secondary
    else
        set color_global $color_primary
    end

    # Prevent NF glyphs on console sessions
    if is_console
        set use_glyphs false
    end

    set -g GIT_PS1_SHOWUNTRACKEDFILES 1
    set -g GIT_PS1_SHOWDIRTYSTATE 1
end


### Renderers

function render_identity
    set -l cmd_status $argv[1]
    set -l glyph
    set -l label

    # Define glyph
    if is_error $cmd_status
        if test "$use_glyphs" = true; set glyph ""; else; set glyph "!"; end
        # Add blinking effect to error state glyph
        set glyph "\e[5m$glyph\e[25m"
    else if is_ssh
        if test "$use_glyphs" = true; set glyph "󰌘"; else; set glyph "*"; end
    else if is_root
        if test "$use_glyphs" = true; set glyph ""; else; set glyph "#"; end
    else
        if test "$use_glyphs" = true; set glyph ""; else; set glyph "\$"; end
    end

    # Define label
    if is_ssh; or is_su
        set -l host (prompt_hostname)
        if test -z "$host"
            set host "$hostname"
        end
        set label "$USER@$host"
    else if is_git
        set label (get_git_project)
    else
        set label (prompt_hostname)
        if test -z "$label"
            set label "$hostname"
        end
    end

    # Global fallback to ensure identity is never empty
    if test -z "$label"
        set label "$USER"
    end

    # Rendering logic
    if test "$use_badges" = true
        make_badge "$glyph $label"
    else
        make_label "$glyph $label"
    end
end

function render_timestamp
    set -l label (date +%I:%M:%S)

    # Rendering logic
    if test "$use_badges" = true
        make_label "$label"
    else
        make_label "[$label]" "$color_neutral"
    end
end

function render_path
    set -l glyph ""
    set -l label (prompt_pwd)

    # Rendering logic
    if test "$use_glyphs" = true
        printf "%s %s" (make_label "$glyph") "$label"
    else
        printf "%s" "$label"
    end
end

function render_git
    set -l glyph ""

    # Prevent if not a repository
    if not is_git
        return
    end

    set -l branch ""
    set -l ahead 0
    set -l has_untracked false
    set -l has_unstaged false
    set -l has_staged false
    set -l has_removed false

    # Use porcelain v2 to get branch, upstream, and file status in one fast call
    for line in (git status --porcelain=v2 -b 2>/dev/null)
        if string match -qr '^# branch\.head ' -- $line
            set branch (string replace "# branch.head " "" -- $line)
        else if string match -qr '^# branch\.ab ' -- $line
            set -l parts (string split " " -- $line)
            # parts[3] is like +N or -N. We extract the number starting from the 2nd character.
            set ahead (string sub -s 2 -- $parts[3])
        else if string match -qr '^\? ' -- $line
            set has_untracked true
        else if string match -qr '^[12u] ' -- $line
            set -l xy (string sub -s 3 -l 2 -- $line)
            set -l x (string sub -s 1 -l 1 -- $xy)
            set -l y (string sub -s 2 -l 1 -- $xy)

            if test "$x" != "."
                set has_staged true
            end
            if test "$y" != "."
                set has_unstaged true
                if test "$y" = "D"
                    set has_removed true
                end
            end
            if test "$x" = "D"
                set has_removed true
            end
        end
    end

    if test -z "$branch" -o "$branch" = "(detached)"
        return
    end

    set -l git_status ""

    # Build status string with your custom symbols
    if test "$has_untracked" = true
        set git_status "$git_status ?"
    end
    if test "$has_unstaged" = true
        set git_status "$git_status !"
    end
    if test "$has_removed" = true
        set git_status "$git_status -"
    end

    # Upper arrow if needs pushing AND everything is committed (clean tree)
    if test "$ahead" -gt 0 -a "$has_unstaged" = false -a "$has_untracked" = false -a "$has_removed" = false -a "$has_staged" = false
        set git_status "$git_status ↑"
    end

    set -l label "$branch$git_status"

    # Use brackets instead of badges
    if test "$use_badges" != true
        set label "($label)"
    end

    # Prepend glyph to label
    if test "$use_glyphs" = true
        set label "$glyph $label"
    end

    # Build format string
    set -l format
    if test "$use_badges" = true
        set format (make_badge "$label" "$color_neutral")
    else if test "$use_colors" = true
        set format (make_label "$label" "$color_secondary")
    else
        set format "$label"
    end

    printf "%s" "$format"
end

function render_prompt
    set -l glyph

    # Define glyph
    if test "$use_glyphs" = true; and test "$use_badges" = true
        set glyph "󱞩"
    else
        set glyph "→"
    end

    # Prepend space character to match badge
    if test "$use_badges" = true
        set glyph " $glyph"
    end

    # Use bold glyph
    if test "$use_glyphs" = true; and test "$use_badges" = true
        set glyph "\e[1m$glyph\e[0m"
    end

    # Prepend newline character
    printf "\n%s" (make_label "$glyph")
end


### Helpers

function hex_to_ansi
    set -l hex (string replace -r "^#" "" $argv[1])
    set -l include_bg $argv[2]

    set -l r (math "0x"(string sub -s 1 -l 2 $hex))
    set -l g (math "0x"(string sub -s 3 -l 2 $hex))
    set -l b (math "0x"(string sub -s 5 -l 2 $hex))

    if test "$include_bg" = true
        printf "30;48;2;%s;%s;%s" $r $g $b
    else
    printf "2;%s;%s;%s" $r $g $b
    end

end

function make_label
    set -l content $argv[1]
    set -l color $argv[2]

    # Fall back to the global color
    if test -z "$color"
        set color $color_global
    end

    # Prevent empty content
    if test -z "$content"
        return
    end

    if test "$use_colors" = true
        printf "\e[38;%sm" (hex_to_ansi "$color")
    end

    printf "%b" "$content"

    if test "$use_colors" = true
        printf "\e[0m"
    end
end

function make_badge
    set -l content $argv[1]
    set -l color $argv[2]

    # Fall back to the global color
    if test -z "$color"
        set color $color_global
    end

    set -l glyph_left ""
    set -l glyph_right ""
    set -l ansi_sequence ""

    # Prevent empty content
    if test -z "$content"
        return
    end

    if test "$use_glyphs" = true
        # Use NF rounded corners
        set glyph_left $glyph_badge_left
        set glyph_right $glyph_badge_right
    else
        # Use plain padding
        set content " $content "
    end

    # Pick ANSI sequence: truecolor bg or reverse video
    set -l ansi
    if test "$use_colors" = true
        set ansi (hex_to_ansi "$color" true)
    else
        set ansi 7
    end

    make_label "$glyph_left" "$color"
    printf "\e[%sm%b\e[0m" "$ansi" "$content"
    make_label "$glyph_right" "$color"
end


### Predicates

function is_root
    test (id -u) -eq 0
end

function is_su
    test -n "$LOGNAME"; and test "$USER" != "$LOGNAME"
end

function is_ssh
    set -q SSH_CLIENT
end

function is_console
    test -t 1; and test "$TERM" = linux
end

function is_error
    set -l code $argv[1]
    test "$code" -ne 0 -a "$code" -ne 130
end

function is_git
    set -l project (get_git_project)
    test -n "$project"
end

# Get the top-level repository name
function get_git_project
    if not command -q git
        return
    end

    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    and basename "$root"
end


### Hooks

# Print a blank line before each prompt (except after startup or clear)
function __print_blank --on-event fish_prompt
    if set -q __was_printed
        echo
    end
    set -g __was_printed 1
end

# Reset the blank-line flag when the screen is cleared
function clear
    command clear
    set -e __was_printed
end


### Initialize

function fish_prompt
    set -l last_status $status

    if not set -q _nixprompt_configured
        _nixprompt_config
        set -g _nixprompt_configured 1
    end

    set -l segments identity path git prompt
    for segment in $segments
        set -l renderer "render_$segment"
        if functions -q "$renderer"
            eval "$renderer $last_status"
            printf " "
        end
    end
end
