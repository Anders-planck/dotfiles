#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}==>${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)    OS="macos";;
        Linux*)     OS="linux";;
        MINGW*)     OS="windows";;
        *)          OS="unknown";;
    esac
    echo "$OS"
}

# Function to create necessary directories
setup_directories() {
    print_status "Setting up directories..."
    
    # Create .config directory if it doesn't exist
    mkdir -p "$HOME/.config"
    
    # Create other necessary directories
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.ghq"
}

# Function to install dependencies based on OS
install_dependencies() {
    local os=$(detect_os)
    print_status "Installing dependencies for $os..."
    
    # Ensure Homebrew is in PATH for both shells
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    case "$os" in
        "macos")
            # Check if Homebrew is installed
            if ! command_exists brew; then
                print_status "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                # Add Homebrew to PATH
                if [ -f "/opt/homebrew/bin/brew" ]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                elif [ -f "/usr/local/bin/brew" ]; then
                    eval "$(/usr/local/bin/brew shellenv)"
                fi
            fi
            
            # Install required packages
            print_status "Installing required packages..."
            brew install neovim fish tmux git lazygit ripgrep fd eza ghq fzf
            brew install font-sauce-code-pro-nerd-font
            
            # Add Homebrew paths to Fish configuration
            mkdir -p "$HOME/.config/fish/conf.d"
            cat > "$HOME/.config/fish/conf.d/brew.fish" << 'EOF'
# Add Homebrew to PATH
if test -f "/opt/homebrew/bin/brew"
    eval (/opt/homebrew/bin/brew shellenv)
else if test -f "/usr/local/bin/brew"
    eval (/usr/local/bin/brew shellenv)
end
EOF
            ;;
            
        "linux")
            # Detect package manager
            if command_exists apt; then
                print_status "Installing required packages using apt..."
                sudo apt update
                sudo apt install -y neovim fish tmux git ripgrep fd-find eza ghq fzf
            elif command_exists dnf; then
                print_status "Installing required packages using dnf..."
                sudo dnf install -y neovim fish tmux git ripgrep fd-find eza ghq fzf
            else
                print_error "Unsupported package manager. Please install the required packages manually."
                exit 1
            fi
            ;;
            
        "windows")
            print_warning "Windows installation requires manual setup. Please follow the Windows setup guide."
            exit 1
            ;;
    esac
}

# Function to setup Fish shell configuration
setup_fish() {
    print_status "Setting up Fish shell..."
    
    # Install Fisher (plugin manager)
    if ! fish -c 'type -q fisher'; then
        print_status "Installing Fisher..."
        fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
    fi

    # Install Fish plugins
    print_status "Installing Fish plugins..."
    fish -c "fisher install jethrokuan/z IlanCosman/tide@v6 PatrickF1/fzf.fish"

    # Set fzf_preview_dir_cmd for fzf.fish
    fish -c 'set -U fzf_preview_dir_cmd "eza --all --color=always"'

    # Create Fish config directory
    mkdir -p "$HOME/.config/fish/conf.d"
    
    # Add Homebrew paths to Fish configuration
    cat > "$HOME/.config/fish/config.fish" << 'EOF'
# Add Homebrew to PATH
if test -f "/opt/homebrew/bin/brew"
    eval (/opt/homebrew/bin/brew shellenv)
else if test -f "/usr/local/bin/brew"
    eval (/usr/local/bin/brew shellenv)
end

# Add Homebrew paths to PATH
set -gx PATH /opt/homebrew/bin $PATH
set -gx PATH /opt/homebrew/sbin $PATH
set -gx PATH /usr/local/bin $PATH
set -gx PATH /usr/local/sbin $PATH

# Source other configurations
for f in $HOME/.config/fish/conf.d/*.fish
    source $f
end
EOF

    # Copy fish configuration
    print_status "Copying Fish configuration..."
    cp -r .config/fish/* "$HOME/.config/fish/"
}

# Function to setup Neovim
setup_neovim() {
    print_status "Setting up Neovim..."
    
    # Create Neovim config directory
    mkdir -p "$HOME/.config/nvim"
    
    # Check if existing config exists and backup if it does
    if [ -d "$HOME/.config/nvim" ] && [ "$(ls -A "$HOME/.config/nvim")" ]; then
        print_status "Backing up existing Neovim configuration..."
        local backup_dir=$(mktemp -d)
        cp -r "$HOME/.config/nvim"/* "$backup_dir/"
        
        # Remove existing config
        rm -rf "$HOME/.config/nvim"/*
    fi
    
    # Create a temporary directory for the new config
    local temp_dir=$(mktemp -d)
    
    # Install new configuration
    print_status "Installing new Neovim configuration..."
    if ! git clone https://github.com/craftzdog/solarized-osaka.nvim.git "$temp_dir"; then
        print_error "Failed to clone new Neovim configuration. Restoring backup..."
        rm -rf "$HOME/.config/nvim"/*
        cp -r "$backup_dir"/* "$HOME/.config/nvim/"
        rm -rf "$backup_dir" "$temp_dir"
        exit 1
    fi
    
    # Move the new configuration to the final location
    if ! cp -r "$temp_dir"/* "$HOME/.config/nvim/"; then
        print_error "Failed to install new Neovim configuration. Restoring backup..."
        rm -rf "$HOME/.config/nvim"/*
        cp -r "$backup_dir"/* "$HOME/.config/nvim/"
        rm -rf "$backup_dir" "$temp_dir"
        exit 1
    fi
    
    # Clean up temporary directories
    rm -rf "$temp_dir"
    
    # If we got here, the new config was installed successfully
    if [ -d "$backup_dir" ]; then
        print_status "New Neovim configuration installed successfully."
        # ask if we want to remove the old config
        print_status "Would you like to remove the old Neovim configuration? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            rm -rf "$backup_dir"
        fi
    fi
}

# Function to setup Git configuration
setup_git() {
    print_status "Setting up Git configuration..."
    
    # Copy Git configuration
    cp .gitconfig "$HOME/.gitconfig"
    cp .gitignore "$HOME/.gitignore"
}

# Function to setup Tmux
setup_tmux() {
    print_status "Setting up Tmux..."
    
    # Create Tmux config directory
    mkdir -p "$HOME/.config/tmux"
    
    # Copy Tmux configuration
    cp -r .config/tmux/* "$HOME/.config/tmux/"
}

# Function to install Nerd Fonts
install_nerd_fonts() {
    print_status "Installing Sauce Code Pro Nerd Font..."
    
    # Install the font using Homebrew
    brew install font-sauce-code-pro-nerd-font
    
    # Set as default font in iTerm2 if it exists
    if [ -d "/Applications/iTerm.app" ]; then
        print_status "Setting Sauce Code Pro Nerd Font as default in iTerm2..."
        defaults write com.googlecode.iterm2 "Normal Font" -string "SauceCodeProNerdFontComplete-Regular"
        defaults write com.googlecode.iterm2 "Non Ascii Font" -string "SauceCodeProNerdFontComplete-Regular"
        print_status "iTerm2 font configuration completed. Please restart iTerm2 for changes to take effect."
    fi
    
    print_status "Sauce Code Pro Nerd Font installation completed!"
}

# Function to set Fish as default shell
set_fish_default() {
    print_status "Setting Fish as default shell..."
    
    # Ensure Homebrew is in PATH before switching
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    # Check if Fish is in /etc/shells
    if ! grep -q "$(which fish)" /etc/shells; then
        print_status "Adding Fish to /etc/shells..."
        echo "$(which fish)" | sudo tee -a /etc/shells
    fi
    
    # Set Fish as default shell
    chsh -s "$(which fish)"
    print_status "Fish has been set as your default shell. Please log out and log back in for changes to take effect."
    print_status "After logging back in, run 'source ~/.config/fish/config.fish' to ensure all paths are properly set."
}

# Main installation process
main() {
    print_status "Starting installation process..."
    
    # Setup directories
    setup_directories
    
    # Install dependencies
    install_dependencies
    
    # Setup configurations
    setup_fish
    setup_git
    setup_tmux
    
    # Ask about Neovim installation
    print_status "Would you like to install Neovim configuration? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        setup_neovim
    fi
    
    # Ask about Nerd Font installation
    print_status "Would you like to install Sauce Code Pro Nerd Font? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        install_nerd_fonts
    fi
    
    # Ask about setting Fish as default shell
    print_status "Would you like to set Fish as your default shell? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        set_fish_default
    fi
    
    print_status "Installation completed successfully!"
    print_status "Please restart your terminal to start using the new configuration."
}

# Run main function
main 