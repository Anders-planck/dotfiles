# Personal Zsh configuration file. It is strongly recommended to keep all
# shell customization and configuration (including exported environment
# variables such as PATH) in this file or in files sourced from it.
#
# Documentation: https://github.com/romkatv/zsh4humans/blob/v5/README.md.

# Periodic auto-update on Zsh startup: 'ask' or 'no'.
# You can manually run `z4h update` to update everything.
zstyle ':z4h:' auto-update      'no'
# Ask whether to auto-update this often; has no effect if auto-update is 'no'.
zstyle ':z4h:' auto-update-days '28'

# Keyboard type: 'mac' or 'pc'.
zstyle ':z4h:bindkey' keyboard  'mac'

# Don't start tmux automatically.
zstyle ':z4h:' start-tmux no

# Whether to move prompt to the bottom when zsh starts and on Ctrl+L.
zstyle ':z4h:' prompt-at-bottom 'no'

# Mark up shell's output with semantic information.
zstyle ':z4h:' term-shell-integration 'yes'

# Right-arrow key accepts one character ('partial-accept') from
# command autosuggestions or the whole thing ('accept')?
zstyle ':z4h:autosuggestions' forward-char 'accept'

# Recursively traverse directories when TAB-completing files.
zstyle ':z4h:fzf-complete' recurse-dirs 'no'

# Enable direnv to automatically source .envrc files.
zstyle ':z4h:direnv'         enable 'yes'
# Show "loading" and "unloading" notifications from direnv.
zstyle ':z4h:direnv:success' notify 'yes'

# Enable ('yes') or disable ('no') automatic teleportation of z4h over
# SSH when connecting to these hosts.
zstyle ':z4h:ssh:example-hostname1'   enable 'yes'
zstyle ':z4h:ssh:*.example-hostname2' enable 'no'
# The default value if none of the overrides above match the hostname.
zstyle ':z4h:ssh:*'                   enable 'no'

# Send these files over to the remote host when connecting over SSH to the
# enabled hosts.
zstyle ':z4h:ssh:*' send-extra-files '~/.nanorc' '~/.env.zsh'

# Clone additional Git repositories from GitHub.
#
# `z4h install` only queues; the actual download happens inside `z4h init`
# and is skipped entirely when the repo is already in $Z4H. Nothing here
# touches the network on a warm cache.
_gh_repos=(
    ohmyzsh/ohmyzsh
    mroth/evalcache
)
for r in $_gh_repos; do
    z4h install $r || return
done
unset _gh_repos r

# Install or update core components (fzf, zsh-autosuggestions, etc.) and
# initialize Zsh. After this point console I/O is unavailable until Zsh
# is fully initialized. Everything that requires user interaction or can
# perform network I/O must be done above. Everything else is best done below.
z4h init || return

# Define key bindings.
z4h bindkey undo Ctrl+/   Shift+Tab  # undo the last command line change
z4h bindkey redo Option+/            # redo the last undone command line change

z4h bindkey z4h-cd-back    Shift+Left   # cd into the previous directory
z4h bindkey z4h-cd-forward Shift+Right  # cd into the next directory
z4h bindkey z4h-cd-up      Shift+Up     # cd into the parent directory
z4h bindkey z4h-cd-down    Shift+Down   # cd into a child directory

# Autoload functions.
autoload -Uz zmv
autoload -Uz colors && colors

# Define functions and completions.
function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
compdef _directories md

# Define aliases.
alias tree='tree -a -I .git'

# Add flags to existing aliases.
alias ls="${aliases[ls]:-ls} -A"

# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt glob_dots     # no special treatment for file names with a leading dot
setopt no_auto_menu  # require an extra TAB press to open the completion menu

# Extend PATH
path=(
    ~/opt
    ~/bin
    ~/.local/bin
    /usr/local/bin
    /usr/local/sbin
    $path
)

# Extend FPATH
fpath=(~/.zsh/completions $fpath)

# Export environment variables.
export GPG_TTY=$TTY

# Source additional local files if they exist.
z4h source $HOME/.zsh/*_*.zsh
# z4h source --compile $HOME/.zsh/??_*.zsh

# Use additional Git repositories pulled in with `z4h install`.
#
# This is just an example that you should delete. It does nothing useful.
# z4h source ohmyzsh/ohmyzsh/lib/diagnostics.zsh  # source an individual file
# z4h load   ohmyzsh/ohmyzsh/plugins/emoji-clock  # load a plugin

# Define named directories: ~w <=> Windows home directory on WSL.
[[ -z $z4h_win_home ]] || hash -d w=$z4h_win_home

# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt glob_dots     # no special treatment for file names with a leading dot
setopt no_auto_menu  # require an extra TAB press to open the completion menu

# Disable command not found
[[ ! -v functions[command_not_found_handler] ]] || unfunction command_not_found_handler

# ---- Node / nvm (lazy) -----------------------------------------------------
# Sourcing nvm.sh plus `nvm use default` cost ~900 ms on every single startup.
# Instead: resolve the 'default' alias with a pure-zsh glob (~1 ms) and put that
# version on PATH; nvm itself loads on first use via the stub below.
export NVM_DIR="$HOME/.nvm"
_nvm_default_bin=()
if [[ -r $NVM_DIR/alias/default ]]; then
    _nvm_default_bin=($NVM_DIR/versions/node/v$(<$NVM_DIR/alias/default)*(N/n))
    (( $#_nvm_default_bin )) && _nvm_default_bin=($_nvm_default_bin[-1]/bin)
fi

nvm() {
    unfunction nvm
    [[ -s /opt/homebrew/opt/nvm/nvm.sh ]] && source /opt/homebrew/opt/nvm/nvm.sh
    [[ -s /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm ]] &&
        source /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm
    nvm "$@"
}

# ---- PATH ------------------------------------------------------------------
# Every entry in one place, highest precedence first. `typeset -U` drops
# duplicates (keeping the first), so re-sourcing ~/.zshrc can't grow PATH.
# This block reproduces the exact precedence the old scattered exports produced.
typeset -U path PATH

export ANDROID_HOME="$HOME/Library/Android/sdk"
export NDK_HOME="$ANDROID_HOME/ndk/29.0.13599879"

path=(
    ~/.opencode/bin                                         # opencode
    ~/.antigravity/antigravity/bin                          # Antigravity
    ~/.bun/bin                                              # Bun
    /Library/Frameworks/Python.framework/Versions/3.11/bin   # Python 3.11 (wins over 3.13)
    /Library/Frameworks/Python.framework/Versions/3.13/bin   # Python 3.13
    $NDK_HOME                                               # Android NDK
    $ANDROID_HOME/emulator
    $ANDROID_HOME/tools
    $ANDROID_HOME/tools/bin
    $ANDROID_HOME/platform-tools
    /opt/homebrew/opt/llvm/bin                              # LLVM (keg-only)
    ~/.codeium/windsurf/bin                                 # Windsurf
    $_nvm_default_bin                                       # Node (nvm default)
    ~/.console-ninja/.bin                                   # Console Ninja
    $path
    "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
    ~/.maestro/bin
)
unset _nvm_default_bin

# asdf v0.15+ is a standalone binary; no shell script to source

# ---- Docker Desktop CLI completions ---------------------------------------
# Only the fpath entry is needed. Do NOT call `compinit` here: z4h runs its own
# (deferred, via `zle -F`) after the prompt is up, and an eager compinit both
# rebuilt the dump (~200 ms) and clobbered z4h's completion setup.
fpath=(~/.docker/completions $fpath)

# ---- Tooling ---------------------------------------------------------------
# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

[[ -x $HOME/.local/bin/mise ]] && eval "$($HOME/.local/bin/mise activate zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ---- Secrets ---------------------------------------------------------------
# Tokens live in a 0600 file outside any git repo, never in this file.
[[ -r ~/.config/zsh/secrets.zsh ]] && source ~/.config/zsh/secrets.zsh
