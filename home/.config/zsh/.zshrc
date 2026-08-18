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

# direnv is deliberately NOT enabled: mise's own docs mark direnv deprecated in
# favour of `[env]` in mise.toml, and the z4h integration adds a per-prompt hook.
# zstyle ':z4h:direnv' enable 'yes'

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
#
# ohmyzsh/ohmyzsh was cloned here but never sourced (the `z4h source`/`z4h load`
# lines below are commented out) — 13 MB of dead third-party shell code on every
# machine. Removed. Add it back only alongside an actual `z4h source` line.
_gh_repos=(
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
fpath=($ZDOTDIR/conf.d/completions $fpath)

# Export environment variables.
export GPG_TTY=$TTY

# Source additional local files if they exist.
z4h source $ZDOTDIR/conf.d/*_*.zsh
# z4h source --compile $ZDOTDIR/conf.d/??_*.zsh

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

# ---- Node -------------------------------------------------------------------
# Node is managed by mise (see `mise use -g node@24`), which puts it on PATH via
# `mise activate` further down. The old nvm block is gone: nvm, asdf and fnm were
# all installed at once and fought over PATH. mise reads .nvmrc/.node-version too
# (enable with: mise settings add idiomatic_version_file_enable_tools node).

# ---- PATH ------------------------------------------------------------------
# Every entry in one place, highest precedence first. `typeset -U` drops
# duplicates (keeping the first), so re-sourcing ~/.zshrc can't grow PATH.
# This block reproduces the exact precedence the old scattered exports produced.
typeset -U path PATH

# Android SDK / NDK. Installed by Android Studio, not by this repo — the paths
# are guarded so a machine without them does not carry dead PATH entries.
export ANDROID_HOME="$HOME/Library/Android/sdk"
export NDK_HOME="$ANDROID_HOME/ndk/29.0.13599879"
_android_path=()
if [[ -d $ANDROID_HOME ]]; then
    _android_path=(
        $NDK_HOME(N/)
        $ANDROID_HOME/emulator(N/)
        $ANDROID_HOME/tools(N/)
        $ANDROID_HOME/tools/bin(N/)
        $ANDROID_HOME/platform-tools(N/)
    )
fi

path=(
    ~/.opencode/bin                                         # opencode
    ~/.antigravity/antigravity/bin                          # Antigravity
    ~/.bun/bin                                              # Bun
    # Python comes from mise, not the python.org framework installers. Those
    # two entries used to sit near the front of PATH and shadowed everything.
    $_android_path                                          # Android SDK/NDK, if present
    /opt/homebrew/opt/llvm/bin                              # LLVM (keg-only)
    ~/.codeium/windsurf/bin                                 # Windsurf
    ~/.console-ninja/.bin                                   # Console Ninja
    $path
    "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
    ~/.maestro/bin
)
unset _android_path

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

# mise, resolved from PATH rather than a hardcoded ~/.local/bin. It is installed
# via Homebrew so `brew upgrade` keeps it current: `mise self-update` calls the
# GitHub releases API directly and fails with 403 when unauthenticated — unlike
# tool resolution, it does not pick up a token from `gh`.
(( $+commands[mise] )) && eval "$(mise activate zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ---- Secrets ---------------------------------------------------------------
# Tokens live in a 0600 file ($ZDOTDIR/secrets.zsh), never in this file.
[[ -r $ZDOTDIR/secrets.zsh ]] && source $ZDOTDIR/secrets.zsh
