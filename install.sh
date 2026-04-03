#!/bin/bash
# try2github installer
# Usage: curl -fsSL https://raw.githubusercontent.com/lequangphu/try2github/main/install.sh | bash

set -e

REPO_URL="https://github.com/lequangphu/try2github"
INSTALL_DIR="${HOME}/.local/share/try2github"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[x]${NC} $1"
}

detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

get_rc_file() {
    local shell="$1"
    case "$shell" in
        zsh)
            echo "${ZDOTDIR:-$HOME}/.zshrc"
            ;;
        bash)
            echo "$HOME/.bashrc"
            ;;
        *)
            echo ""
            ;;
    esac
}

check_prerequisites() {
    # Check for tobi/try
    if ! command -v try &>/dev/null; then
        print_error "tobi/try is required but not installed."
        echo "Install it first:"
        echo "  gem install try-cli"
        echo ""
        echo "Then add to your shell RC:"
        echo '  eval "$(try init ~/src/tries)"'
        exit 1
    fi
    
    print_status "Found tobi/try"
}

cleanup_old_install() {
    # Remove old standalone scripts if they exist
    local bin_dir="$HOME/.local/bin"
    local old_scripts="$bin_dir/try $bin_dir/promote $bin_dir/repo $bin_dir/clone $bin_dir/tries"
    local found=0
    
    for script in $old_scripts; do
        if [ -f "$script" ]; then
            found=1
            rm -f "$script"
            print_status "Removed old script: $script"
        fi
    done
    
    if [ $found -eq 1 ]; then
        echo ""
        print_warning "Old standalone scripts have been removed."
        print_warning "Commands are now shell functions (sourced into your shell)."
    fi
}

install_try2github() {
    print_status "Installing try2github..."
    
    # Detect shell
    local shell=$(detect_shell)
    print_status "Detected shell: $shell"
    
    # Check prerequisites
    check_prerequisites
    
    # Cleanup old install
    cleanup_old_install
    
    # Clone or update repository
    if [ -d "$INSTALL_DIR" ]; then
        print_status "Updating existing installation..."
        cd "$INSTALL_DIR" && git pull origin main 2>/dev/null || true
    else
        print_status "Cloning try2github..."
        mkdir -p "$(dirname "$INSTALL_DIR")"
        git clone "$REPO_URL.git" "$INSTALL_DIR"
    fi
    
    # Get RC file
    local rc_file=$(get_rc_file "$shell")
    
    # Source shell integration
    if [ -n "$rc_file" ] && [ -f "$rc_file" ]; then
        local source_line="source \"$INSTALL_DIR/shell/try2github.$shell\""
        if ! grep -q "$source_line" "$rc_file" 2>/dev/null; then
            print_status "Adding try2github to $rc_file"
            echo "" >> "$rc_file"
            echo "# try2github" >> "$rc_file"
            echo "$source_line" >> "$rc_file"
        fi
    fi
    
    print_status "Installation complete!"
    echo ""
    echo "Commands added:"
    echo "  promote <try> <repo>     - Promote try to GitHub repo"
    echo "  repo [ls|cd|open] [name] - Navigate GitHub repos"
    echo "  clone <github-url>       - Clone external repos"
    echo ""
    echo "Note: 'try' command comes from tobi/try (already installed)"
    echo ""
    if [ -n "$rc_file" ]; then
        print_warning "Please restart your shell or run: source $rc_file"
    fi
}

# Run installation
install_try2github
