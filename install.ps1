# PowerShell script for Windows installation

# Function to print status messages
function Write-Status {
    param([string]$Message)
    Write-Host "==> $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "Error: $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "Warning: $Message" -ForegroundColor Yellow
}

# Function to check if a command exists
function Test-Command {
    param([string]$Command)
    return [bool](Get-Command -Name $Command -ErrorAction SilentlyContinue)
}

# Function to create necessary directories
function Setup-Directories {
    Write-Status "Setting up directories..."
    
    # Create .config directory if it doesn't exist
    New-Item -ItemType Directory -Force -Path "$HOME\.config"
    
    # Create other necessary directories
    New-Item -ItemType Directory -Force -Path "$HOME\.local\bin"
    New-Item -ItemType Directory -Force -Path "$HOME\.ghq"
}

# Function to install dependencies
function Install-Dependencies {
    Write-Status "Installing dependencies..."
    
    # Check if Scoop is installed
    if (-not (Test-Command scoop)) {
        Write-Status "Installing Scoop..."
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
        irm get.scoop.sh | iex
    }
    
    # Install required packages
    Write-Status "Installing required packages..."
    scoop install neovim fish tmux git lazygit ripgrep fd eza ghq fzf
    
    # Install PowerShell modules
    Write-Status "Installing PowerShell modules..."
    Install-Module -Name PSReadLine -Force -SkipPublisherCheck
    Install-Module -Name Terminal-Icons -Force
    Install-Module -Name PSFzf -Force
}

# Function to setup Fish shell
function Setup-Fish {
    Write-Status "Setting up Fish shell..."
    
    # Create Fish config directory
    New-Item -ItemType Directory -Force -Path "$HOME\.config\fish\conf.d"
    
    # Install Fisher (plugin manager)
    if (-not (Test-Command fisher)) {
        Write-Status "Installing Fisher..."
        Invoke-Expression (curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish)
    }
    
    # Install Fish plugins
    Write-Status "Installing Fish plugins..."
    fisher install jethrokuan/z IlanCosman/tide@v6 PatrickF1/fzf.fish
    
    # Set fzf_preview_dir_cmd
    $fzfConfig = @"
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
"@
    Set-Content -Path "$HOME\.config\fish\config.fish" -Value $fzfConfig
    
    # Copy fish configuration
    Write-Status "Copying Fish configuration..."
    Copy-Item -Path ".config\fish\*" -Destination "$HOME\.config\fish" -Recurse -Force
}

# Function to setup Git configuration
function Setup-Git {
    Write-Status "Setting up Git configuration..."
    
    # Copy Git configuration
    Copy-Item -Path ".gitconfig" -Destination "$HOME\.gitconfig" -Force
    Copy-Item -Path ".gitignore" -Destination "$HOME\.gitignore" -Force
}

# Function to setup Neovim
function Setup-Neovim {
    Write-Status "Setting up Neovim..."
    
    # Create Neovim config directory
    New-Item -ItemType Directory -Force -Path "$HOME\.config\nvim"
    
    # Backup existing config if it exists
    if (Test-Path "$HOME\.config\nvim\*") {
        Write-Status "Backing up existing Neovim configuration..."
        $backupDir = Join-Path $env:TEMP "nvim_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item -Path "$HOME\.config\nvim\*" -Destination $backupDir -Recurse -Force
    }
    
    # Install new configuration
    Write-Status "Installing new Neovim configuration..."
    try {
        git clone https://github.com/craftzdog/solarized-osaka.nvim.git "$HOME\.config\nvim"
        Remove-Item -Path "$HOME\.config\nvim\.git" -Recurse -Force
    }
    catch {
        Write-Error "Failed to install new Neovim configuration. Restoring backup..."
        if ($backupDir) {
            Remove-Item -Path "$HOME\.config\nvim\*" -Recurse -Force
            Copy-Item -Path "$backupDir\*" -Destination "$HOME\.config\nvim" -Recurse -Force
        }
        throw
    }
}

# Function to install Nerd Fonts
function Install-NerdFonts {
    Write-Status "Installing Sauce Code Pro Nerd Font..."
    
    # Install the font using Scoop
    scoop install font-saucecodepro-nerd-font
    
    Write-Status "Sauce Code Pro Nerd Font installation completed!"
}

# Function to set Fish as default shell
function Set-FishDefault {
    Write-Status "Setting Fish as default shell..."
    
    # Add Fish to PATH if not already present
    $fishPath = (Get-Command fish).Source
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if (-not $userPath.Contains($fishPath)) {
        [Environment]::SetEnvironmentVariable("PATH", "$userPath;$fishPath", "User")
    }
    
    Write-Status "Fish has been set as your default shell. Please restart your terminal for changes to take effect."
}

# Main installation process
function Main {
    Write-Status "Starting installation process..."
    
    # Setup directories
    Setup-Directories
    
    # Install dependencies
    Install-Dependencies
    
    # Setup configurations
    Setup-Fish
    Setup-Git
    
    # Ask about Neovim installation
    $response = Read-Host "Would you like to install Neovim configuration? (y/N)"
    if ($response -match '^[yY]$') {
        Setup-Neovim
    }
    
    # Ask about Nerd Font installation
    $response = Read-Host "Would you like to install Sauce Code Pro Nerd Font? (y/N)"
    if ($response -match '^[yY]$') {
        Install-NerdFonts
    }
    
    # Ask about setting Fish as default shell
    $response = Read-Host "Would you like to set Fish as your default shell? (y/N)"
    if ($response -match '^[yY]$') {
        Set-FishDefault
    }
    
    Write-Status "Installation completed successfully!"
    Write-Status "Please restart your terminal to apply the changes."
}

# Run main function
Main 