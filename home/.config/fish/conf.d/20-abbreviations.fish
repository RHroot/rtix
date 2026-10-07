# Navigation
abbr -a d "z"
abbr -a pd "cd -"
abbr -a .. "cd .."
abbr -a ... "cd ../.."
abbr -a .... "cd ../../.."
abbr -a ..... "cd ../../../.."

# Editors
abbr -a v "vim"
abbr -a n "nvim"

# Tmux
abbr -a ta "tmux attach"
abbr -a td "tmux detach"
abbr -a tns "tmux new -s"

# System helpers
abbr -a psa "ps auxf"
abbr -a psg "ps aux | rg"
abbr -a openports "netstat -tulanp"

# System control
abbr -a shutnow "shutdown now"

# File operations
abbr -a rm "rm -iv"
abbr -a cp "cp -iv"
abbr -a mv "mv -iv"
abbr -a cpr "cp -riv"
abbr -a rmd "rm -rfv"
abbr -a mkdir "mkdir -pv"

# Disk usage
abbr -a mountedinfo "df -hT"
abbr -a duf "duf -hide special"
abbr -a folders "du -h --max-depth=1"
abbr -a diskspace "du -S | sort -n -r | nvim -"

# Permissions & security
abbr -a sha1 "openssl sha1"
abbr -a own "sudo chown -R $USER"

# Dev & tools
abbr -a ga "git add"
abbr -a gd "git diff"
abbr -a gs "git status"
abbr -a gp "git push -u"
abbr -a myip "curl ifconfig.me"
abbr -a oc "opencode --port 3000"
abbr -a bright "brightnessctl set"
abbr -a grep "grep --color=always"
abbr -a rg "rg -uui --color=always"
abbr -a nettest "nix shell nixpkgs#speedtest-go --command speedtest-go"
abbr -a antigravity "nix run github:jacopone/antigravity-nix#google-antigravity-cli"

# Utilities
abbr -a ff "fastfetch -c my.jsonc"
abbr -a wget "wget -c --limit-rate=15m"

# System Information
abbr -a open "xdg-open"
abbr -a vol "wpctl get-volume @DEFAULT_AUDIO_SINK@"

# LS commands
abbr -a la "ls -A"
abbr -a lz "ls -lhAi"
abbr -a lh 'set m .*; and [ "$m" != ".*" ]; and ls -d $m 2>/dev/null'
abbr -a list "tree -a 2>/dev/null || ls -R"
