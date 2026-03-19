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
