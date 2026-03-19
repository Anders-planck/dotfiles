# FZF configuration for Fish shell
set -q FZF_LEGACY_KEYBINDINGS; or set -U FZF_LEGACY_KEYBINDINGS 0

# Add FZF to PATH if it exists
if test -d /opt/homebrew/opt/fzf/shell
    set -gx PATH /opt/homebrew/opt/fzf/bin $PATH
    source /opt/homebrew/opt/fzf/shell/key-bindings.fish
end 