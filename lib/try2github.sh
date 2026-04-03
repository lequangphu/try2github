#!/bin/sh
# try2github - Core POSIX functions for promote, repo, clone
# Note: 'try' command is provided by tobi/try (gem install try-cli)

# Configuration
TRY2GITHUB_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/try2github"

# Default paths (overridable via env vars)
TRY2GITHUB_TRIES_DIR="${TRY2GITHUB_TRIES_DIR:-${TRY_PATH:-$HOME/src/tries}}"
TRY2GITHUB_REPOS_DIR="${TRY2GITHUB_REPOS_DIR:-$HOME/src/github.com}"
TRY2GITHUB_GITHUB_USER="${TRY2GITHUB_GITHUB_USER:-$(git config --global user.name 2>/dev/null || echo "")}"

# Get the directory where this script is located
TRY2GITHUB_ROOT="${TRY2GITHUB_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# ============================================
# _try2github_find_try - Find try by pattern
# ============================================
_try2github_find_try() {
    local pattern="$1"
    find "$TRY2GITHUB_TRIES_DIR" -maxdepth 1 -type d -name "*${pattern}*" 2>/dev/null | head -1
}

# ============================================
# _try2github_find_repo - Find repo by pattern
# ============================================
_try2github_find_repo() {
    local pattern="$1"
    local user_dir="$TRY2GITHUB_REPOS_DIR/$TRY2GITHUB_GITHUB_USER"
    find "$user_dir" -maxdepth 1 -type d -name "*${pattern}*" 2>/dev/null | head -1
}

# ============================================
# try2github_promote - Promote try to GitHub repo
# Usage: try2github_promote <try-pattern> <repo-name>
# ============================================
try2github_promote() {
    local try_pattern="$1"
    local repo_name="$2"
    
    if [ -z "$try_pattern" ] || [ -z "$repo_name" ]; then
        echo "Usage: try2github_promote <try-pattern> <repo-name>" >&2
        return 1
    fi
    
    # Find the try directory
    local try_path=$(_try2github_find_try "$try_pattern")
    
    if [ -z "$try_path" ]; then
        echo "Error: No try found matching '$try_pattern'" >&2
        return 1
    fi
    
    local try_name=$(basename "$try_path")
    local user_dir="$TRY2GITHUB_REPOS_DIR/$TRY2GITHUB_GITHUB_USER"
    local repo_path="$user_dir/$repo_name"
    
    # Ensure user directory exists
    mkdir -p "$user_dir"
    
    # Check if repo already exists
    if [ -d "$repo_path" ]; then
        echo "Error: Repo already exists at $repo_path" >&2
        return 1
    fi
    
    # Move the directory
    echo "Promoting: $try_name -> $repo_name"
    mv "$try_path" "$repo_path"
    
    # Setup git and GitHub
    cd "$repo_path" || return 1
    
    # Check if already has git remote
    if ! git remote get-url origin 2>/dev/null; then
        # Check if gh is available
        if command -v gh >/dev/null 2>&1; then
            echo "Creating GitHub repo: $TRY2GITHUB_GITHUB_USER/$repo_name"
            gh repo create "$repo_name" --private --source=. --push 2>/dev/null || {
                echo "Warning: Failed to create GitHub repo."
            }
        else
            echo "GitHub CLI (gh) not found."
        fi
    else
        echo "Existing git remote found, pushing..."
        git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null || true
    fi
    
    echo "Promoted to $repo_path"
}

# ============================================
# try2github_repo - List repos
# Usage: try2github_repo ls
# ============================================
try2github_repo() {
    local user_dir="$TRY2GITHUB_REPOS_DIR/$TRY2GITHUB_GITHUB_USER"
    mkdir -p "$user_dir"
    ls -1 "$user_dir" 2>/dev/null
}
