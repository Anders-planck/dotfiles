# dotfiles

Personal configuration files and scripts.

## Structure

```
.config/        → App configs (nvim, fish, tmux, lazygit, ghostty, mise)
.scripts/       → IDE launcher scripts
vscode/         → VS Code settings and custom CSS
zsh/            → Zsh config and plugins
fonts/          → Nerd Font installer
scripts/        → Backup/restore and utility scripts
install.sh      → macOS/Linux setup script
install.ps1     → Windows setup script
```

## Setup

```sh
git clone https://github.com/Anders-planck/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

### Zsh

`zsh/` is a [zsh4humans](https://github.com/romkatv/zsh4humans) setup. `zsh/install`
symlinks `.zshrc`, `.zshenv`, `.p10k.zsh` and `.zsh/` into `$HOME`; the numbered
files in `zsh/.zsh/` are sourced in order by `z4h source`.

### Secrets

Tokens are **not** kept in `.zshrc` — that file is mode 0644 and readable by every
process on the machine. They live in `~/.config/zsh/secrets.zsh` (mode 0600), which
`.zshrc` sources last:

```sh
mkdir -p ~/.config/zsh && chmod 700 ~/.config/zsh
cp .config/zsh/secrets.zsh.example ~/.config/zsh/secrets.zsh
chmod 600 ~/.config/zsh/secrets.zsh
```

### Startup-cost rules

The shell startup budget is easy to wreck. Two rules that cost ~2 s when broken:

- **Never shadow a system binary with a shell function.** An `md5()` wrapper hides
  `/sbin/md5`; Powerlevel10k calls `md5 -- <file>` while building the prompt, and a
  wrapper that does `cat $1` receives `--`, runs a bare `cat`, and **reads from the
  terminal** — the shell hangs showing only `Last login: …` until you hit Ctrl+C.
  It is intermittent: p10k only takes that path on a stat-cache miss. See the
  warning comment in `zsh/.zsh/20_functions.zsh`.
- **Cache anything that shells out at startup.** `thefuck --alias` costs ~900 ms and
  `nvm use default` ~630 ms. Route slow init commands through `_evalcache`
  (`zsh/.zsh/04_evalcache.zsh`); `.zshrc` resolves the nvm default with a pure-zsh
  glob and loads `nvm` lazily on first call.

Also: don't call `compinit` from `.zshrc` — z4h runs its own, deferred via `zle -F`
after the prompt is up. Adding `fpath` entries is enough.

### mise

`.config/mise/config.toml` is a template meant for `~/.config/mise/`. Inside this
checkout mise's `chpwd` hook will flag it as untrusted on every prompt. Silence it
with `mise trust --ignore .config/mise/config.toml` — do **not** use plain
`mise trust`, which would let it auto-install every tool pinned to `latest` whenever
you `cd` here.
