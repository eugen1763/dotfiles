if status is-interactive
    # Aliases (fish has color by default, but these ensure consistency)
    alias ls 'ls --color=auto'
    alias grep 'grep --color=auto'
end

# PATH
fish_add_path -g /home/finn/.opencode/bin
fish_add_path -g /home/finn/.local/bin

# Auto-start Hyprland on tty1
if not set -q WAYLAND_DISPLAY; and test (tty) = /dev/tty1
    exec start-hyprland
end
export PATH="$HOME/.local/bin:$PATH"

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
