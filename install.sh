#!/bin/bash

# Laptop Setup Script
# This script sets up a development environment based on the configurations in this repo

set -e  # Exit on any error

echo "🚀 Starting laptop setup..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is designed for macOS"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Homebrew if not present
install_homebrew() {
    if ! command_exists brew; then
        echo "📦 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        echo "✅ Homebrew already installed"
    fi
}

# Function to install Oh My Zsh
install_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "🐚 Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        echo "✅ Oh My Zsh already installed"
    fi
}

# Function to install zsh plugins
install_zsh_plugins() {
    echo "🔌 Installing Zsh plugins..."
    
    # zsh-autosuggestions
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi
    
    # fzf-tab
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab" ]; then
        git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab
    fi
}

# Main installation function
main() {
    echo "🔧 Installing development tools..."
    
    # Install Homebrew first
    install_homebrew
    
    # Update Homebrew
    echo "🔄 Updating Homebrew..."
    brew update
    
    # Install essential tools via Homebrew
    echo "📋 Installing essential tools..."
    
    # Core development tools
    brew_packages=(
        "git"
        "docker"
        "docker-compose"
        "gh"           # GitHub CLI
        "awscli"       # AWS CLI
        "zoxide"       # Smart cd command
        "starship"     # Cross-shell prompt
        "eza"          # Modern ls replacement
        "fnm"          # Fast Node Manager
        "pnpm"         # Package manager
        "mysql-client" # MySQL client
        "cargo"        # Rust package manager
        "composer"     # PHP package manager
        "fzf"          # Fuzzy finder
    )
    
    for package in "${brew_packages[@]}"; do
        if ! brew list "$package" &>/dev/null; then
            echo "📦 Installing $package..."
            brew install "$package"
        else
            echo "✅ $package already installed"
        fi
    done
    
    # Install Bun (JavaScript runtime and package manager)
    if ! command_exists bun; then
        echo "📦 Installing Bun..."
        curl -fsSL https://bun.sh/install | bash
    else
        echo "✅ Bun already installed"
    fi
    
    # Install Oh My Zsh and plugins
    install_oh_my_zsh
    install_zsh_plugins
    
    # Setup Docker networks for Traefik
    echo "🐳 Setting up Docker networks..."
    docker network create traefik 2>/dev/null || echo "✅ Traefik network already exists"
    docker network create haproxy 2>/dev/null || echo "✅ HAProxy network already exists"
    
    # Setup directories referenced in .zshrc
    echo "📁 Creating necessary directories..."
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/share"
    mkdir -p "$HOME/.docker/completions"
    mkdir -p "$HOME/.eza/completions/zsh"
    
    # Copy .zshrc if it doesn't exist or ask to replace
    if [ ! -f "$HOME/.zshrc" ] || [ "$HOME/.zshrc" -ot ".zshrc" ]; then
        echo "📝 Setting up .zshrc..."
        if [ -f "$HOME/.zshrc" ]; then
            cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
            echo "💾 Backed up existing .zshrc"
        fi
        cp .zshrc "$HOME/.zshrc"
        echo "✅ Copied .zshrc to home directory"
    fi
    
    # Create placeholder files referenced in .zshrc
    touch "$HOME/.env" 2>/dev/null || true
    touch "$HOME/.bash_aliases" 2>/dev/null || true
    touch "$HOME/.fnm.sh" 2>/dev/null || true
    touch "$HOME/.functions.sh" 2>/dev/null || true
    
    # Setup FZF if not already done
    if [ ! -d "$HOME/.local/share/fzf" ]; then
        echo "🔍 Setting up FZF..."
        mkdir -p "$HOME/.local/share"
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.local/share/fzf"
        "$HOME/.local/share/fzf/install" --all
    fi
    
    # Install OpenCode if not present
    if ! command_exists opencode; then
        echo "💻 OpenCode not found. You may want to install it manually."
        echo "   Visit: https://github.com/sst/opencode for installation instructions"
    fi
    
    echo ""
    echo "🎉 Setup complete!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Configure your .env file with necessary environment variables"
    echo "3. Set up your .functions.sh with custom functions"
    echo "4. Run 'docker-compose up -d' in the traefik directory to start services"
    echo "5. Configure DNS to use 127.0.0.1:53 for .local domains"
    echo ""
    echo "🔧 Tools installed:"
    echo "   • Homebrew package manager"
    echo "   • Oh My Zsh with plugins"
    echo "   • Docker and Docker Compose"
    echo "   • GitHub CLI (gh)"
    echo "   • AWS CLI"
    echo "   • Node.js tooling (fnm, pnpm, bun)"
    echo "   • Development utilities (fzf, eza, zoxide, starship)"
    echo "   • Traefik and HAProxy Docker networks"
    echo ""
    echo "Happy coding! 🚀"
}

# Run main function
main "$@"
