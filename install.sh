#!/bin/bash
# try2github installer
# Usage: curl -fsSL https://raw.githubusercontent.com/lequangphu/try2github/main/install.sh | bash

set -e

REPO_URL="https://github.com/lequangphu/try2github"
INSTALL_DIR="${HOME}/.local/share/try2github"
BIN_DIR="${HOME}/.local/bin"

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

install_try2github() {
    print_status "Installing try2github..."
    
    # Detect shell
    local shell=$(detect_shell)
    print_status "Detected shell: $shell"
    
    # Clone or update repository
    if [ -d "$INSTALL_DIR" ]; then
        print_status "Updating existing installation..."
        cd "$INSTALL_DIR" && git pull origin main 2>/dev/null || true
    else
        print_status "Cloning try2github..."
        mkdir -p "$(dirname "$INSTALL_DIR")"
        git clone "$REPO_URL.git" "$INSTALL_DIR"
    fi
    
    # Ensure bin directory exists
    mkdir -p "$BIN_DIR"
    
    # Create wrapper scripts in bin directory
    cat > "$BIN_DIR/try" << 'EOF'
#!/bin/bash
export TRY2GITHUB_ROOT="${HOME}/.local/share/try2github"
source "$TRY2GITHUB_ROOT/lib/try2github.sh"
TRY2GITHUB_AUTO_CD=1 try2github_try "$@"
EOF
    chmod +x "$BIN_DIR/try"
    
    cat > "$BIN_DIR/promote" << 'EOF'
#!/bin/bash
export TRY2GITHUB_ROOT="${HOME}/.local/share/try2github"
source "$TRY2GITHUB_ROOT/lib/try2github.sh"
TRY2GITHUB_AUTO_CD=1 try2github_promote "$@"
EOF
    chmod +x "$BIN_DIR/promote"
    
    cat > "$BIN_DIR/repo" << 'EOF'
#!/bin/bash
export TRY2GITHUB_ROOT="${HOME}/.local/share/try2github"
source "$TRY2GITHUB_ROOT/lib/try2github.sh"
if [ $# -eq 0 ]; then
    try2github_repo ls
else
    TRY2GITHUB_AUTO_CD=1 try2github_repo "$@"
fi
EOF
    chmod +x "$BIN_DIR/repo"
    

    
    # Get RC file
    local rc_file=$(get_rc_file "$shell")
    
    # Add to PATH if needed
    if ! echo "$PATH" | grep -q "$BIN_DIR"; then
        print_warning "$BIN_DIR is not in PATH"
        
        if [ -n "$rc_file" ] && [ -f "$rc_file" ]; then
            print_status "Adding $BIN_DIR to PATH in $rc_file"
            echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$rc_file"
        else
            print_warning "Please add $BIN_DIR to your PATH manually"
        fi
    fi
    
    # Source shell integration for completions
    if [ -n "$rc_file" ] && [ -f "$rc_file" ]; then
        local source_line="source \"$INSTALL_DIR/shell/try2github.$shell\""
        if ! grep -q "$source_line" "$rc_file" 2>/dev/null; then
            print_status "Adding shell integration to $rc_file"
            echo "" >> "$rc_file"
            echo "# try2github" >> "$rc_file"
            echo "$source_line" >> "$rc_file"
        fi
    fi
    
    # Create config directory
    mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/try2github"
    
    print_status "Installation complete!"
    echo ""
    echo "Commands available:"
    echo "  try <name> [template]      - Create a new experiment"
    echo "  promote <try> <repo>       - Promote try to GitHub repo"
    echo "  repo [ls|cd|open] [name]   - List and navigate repos"
    echo ""
    echo "Templates: default, python, node, data"
    echo ""
    
    if [ -n "$rc_file" ]; then
        print_warning "Please restart your shell or run: source $rc_file"
    fi
}

# Check for dependencies
print_status "Checking dependencies..."

if ! command -v git >/dev/null 2>&1; then
    print_error "git is required but not installed."
    exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
    print_warning "GitHub CLI (gh) not found. Install it for 'promote' to work:"
    print_warning "  https://cli.github.com/"
fi

# Run installation
install_try2github
