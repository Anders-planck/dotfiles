# The only zsh file that must live in $HOME.
#
# zsh always reads ~/.zshenv from $HOME before anything else; everything after
# this point follows $ZDOTDIR. Pointing ZDOTDIR at $XDG_CONFIG_HOME/zsh is what
# lets the rest of the zsh config live under ~/.config/zsh like every other app.
#
# Keep this file to environment variables only. It is sourced by *every* zsh
# invocation, including non-interactive scripts — slow logic here is paid
# everywhere.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Hand off to the real zshenv. zsh will not do this for us: it reads
# $ZDOTDIR/.zshenv only when ZDOTDIR was already set before this file ran.
[[ -r "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
