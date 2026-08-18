# dotfiles

Personal configuration files and scripts. macOS-first, zsh + zsh4humans.

## Structure

Everything under `home/` is mirrored into `$HOME`. Everything else is repo tooling
and is never installed.

```
home/                → mirrored into $HOME, file by file, as symlinks
  .zshenv            → the only file that must sit at $HOME root; sets ZDOTDIR
  .config/
    zsh/             → .zshrc, .zshenv, .p10k.zsh, conf.d/NN_*.zsh
    git/             → config, ignore   (XDG; NOT ~/.gitconfig)
    nvim/ tmux/ ghostty/ lazygit/ mise/ powershell/
  .local/bin/        → user scripts on PATH

mise.toml            → task runner for this repo (`mise tasks`)
Brewfile             → packages, casks, fonts, VS Code extensions
install.sh           → the only installer
bin/                 → bootstrap, update, fonts, iterm2, vscode, backup/restore
iterm2/              → iTerm2 preferences, read from here (see below)
vscode/              → VS Code config, copied not linked (see below)
.github/workflows/   → gitleaks, shellcheck, sandboxed install test
.chezmoiroot         → "home" — ready for chezmoi, not required
```

## Tasks

`mise run <task>` from the repo root; `mise tasks` lists them all.

| Task | What it does |
|---|---|
| `install` | packages + symlinks + secrets + verification |
| `link` / `dry` | symlinks only / show what would change |
| `tools` | install missing CLI tools, then verify |
| `fonts` | audit fonts: referenced, installed, unmanaged by brew |
| `lint` | shellcheck the sh/bash scripts, `zsh -n` the zsh files |
| `secrets` | scan the repo and its full history for credentials |
| `export` | pull live VS Code / iTerm2 / Brewfile state back into the repo |
| `brew:check` | report drift between the Brewfile and what is installed |
| `update` | pull, then upgrade Homebrew packages and mise tools |
| `doctor` | full health check |

`brew:check` exits non-zero whenever anything is merely *outdated*, not only when
missing — font casks in particular drift constantly. Treat it as a drift report.

## Setup

```sh
git clone https://github.com/Anders-planck/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` installs everything in the `Brewfile`, links `home/` into `$HOME`,
seeds `~/.config/zsh/secrets.zsh` (0600), and verifies the tools resolve.

```sh
./install.sh --dry-run     # show what would change, touch nothing
./install.sh --link-only   # skip brew bundle
bin/bootstrap --check      # verify tools only
update_zsh                 # git pull this repo
```

It is safe to re-run. Anything real it would overwrite is moved to
`~/.dotfiles-backup/<timestamp>/` first.

## Zsh

`~/.zshenv` sets `ZDOTDIR="$XDG_CONFIG_HOME/zsh"`, so the rest of the zsh config
lives at `~/.config/zsh/` like every other app. The numbered files in `conf.d/`
are sourced in order by `z4h source`.

### Startup-cost rules

Two rules that cost seconds per shell when broken:

- **Never shadow a system binary with a shell function.** An `md5()` wrapper hides
  `/sbin/md5`; Powerlevel10k calls `md5 -- <file>` while building the prompt, and a
  wrapper doing `cat $1` receives `--`, runs a bare `cat`, and **reads from the
  terminal** — the shell hangs showing only `Last login: …` until Ctrl+C. Intermittent,
  because p10k only takes that path on a stat-cache miss. See `conf.d/20_functions.zsh`.
- **Cache anything that shells out at startup.** Route slow init commands through
  `_evalcache` (`conf.d/04_evalcache.zsh`).

Also: don't call `compinit` from `.zshrc` — z4h runs its own, deferred via `zle -F`.
Adding an `fpath` entry is enough.

## Versions

`mise` manages language runtimes — it replaces nvm, asdf and fnm, which were all
installed at once and fought over PATH. Versions are **pinned** in
`home/.config/mise/config.toml`: `latest` re-resolves against the GitHub API on
every shell start and fails with rate-limit warnings when unauthenticated.

## Secrets

Tokens are never in `.zshrc` — that file is 0644 and readable by every process.
They live in `~/.config/zsh/secrets.zsh` (0600), sourced last:

```sh
cp home/.config/zsh/secrets.zsh.example ~/.config/zsh/secrets.zsh
chmod 600 ~/.config/zsh/secrets.zsh
```

CI runs `gitleaks` over the full history on every push.

## iTerm2

iTerm2 does not read prefs from a fixed path in `$HOME`; it reads
`com.googlecode.iterm2.plist` from a folder you nominate. So the plist lives at
`iterm2/` rather than under `home/`, and a script sets the pointer:

```sh
bin/iterm2 setup     # point iTerm2 at this repo (quit iTerm2 first)
bin/iterm2 export    # copy live prefs back into the repo, as diffable XML
bin/iterm2 status    # show what iTerm2 is currently configured to do
```

## VS Code

Not symlinked: VS Code rewrites `settings.json` itself whenever you change a
setting in the UI, and would fight a link into the repo. Sync explicitly instead:

```sh
bin/vscode export       # live config -> repo (sanitises secrets)
bin/vscode apply        # repo -> live config
bin/vscode status       # what differs
bin/vscode extensions   # reinstall everything in extensions.txt
```

`mcp.json` is **not** tracked: it carries live Bearer tokens for Sanity and Neon.
Only `mcp.json.example` is committed, with the tokens replaced, and `export`
refuses to finish if a real token survives sanitising.

On macOS the User directory is `~/Library/Application Support/Code/User`, not XDG.

## Fonts

Nerd Fonts come from the `Brewfile`. `brew tap homebrew/cask-fonts` no longer
works — the tap is in Homebrew's deprecated list and the command hard-errors; font
casks now live in `homebrew/cask` with no tap needed.

```sh
bin/fonts           # install every font cask in the Brewfile
bin/fonts --used    # which fonts the configs reference, and whether they exist
bin/fonts --check   # the above, plus fonts installed outside Homebrew
```

Two fonts are installed by hand and Homebrew cannot reinstall them on a fresh
machine: **DankMono** (commercial, no cask — and the first entry in the VS Code
font stack) and **RecMono** (a cask exists, but the loose files in
`~/Library/Fonts` shadow it and the cask refuses to install over them).
