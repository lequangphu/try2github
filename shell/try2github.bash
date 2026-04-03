#!/bin/bash
# try2github - Bash integration
# Extends tobi/try with GitHub workflow features
#
# Requirements: tobi/try must be installed (gem install try-cli)

# ============================================
# Check for tobi/try dependency
# ============================================
if ! command -v try &>/dev/null; then
    echo "Error: try2github requires tobi/try (gem install try-cli)" >&2
    return 1
fi

# ============================================
# Configuration
# ============================================
TRY2GITHUB_SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRY2GITHUB_ROOT="$(dirname "$TRY2GITHUB_SHELL_DIR")"

export TRY2GITHUB_ROOT
export TRY2GITHUB_GITHUB_USER="${TRY2GITHUB_GITHUB_USER:-lequangphu}"
export TRY2GITHUB_TRIES_DIR="${TRY_PATH:-$HOME/src/tries}"
export TRY2GITHUB_REPOS_DIR="${TRY2GITHUB_REPOS_DIR:-$HOME/src/github.com}"

# Source the core library
source "$TRY2GITHUB_ROOT/lib/try2github.sh"

# ============================================
# promote - Promote try to GitHub repo
# ============================================
promote() {
    local try_pattern="$1"
    local repo_name="$2"
    
    if [ -z "$try_pattern" ] || [ -z "$repo_name" ]; then
        echo "Usage: promote <try-name> <repo-name>" >&2
        echo "Example: promote redis-test my-redis-project" >&2
        return 1
    fi
    
    # Find try directory
    local try_path=""
    local tries_dir="$TRY2GITHUB_TRIES_DIR"
    
    for dir in "$tries_dir"/*; do
        if [ -d "$dir" ]; then
            local basename=$(basename "$dir")
            if echo "$basename" | grep -q "$try_pattern"; then
                try_path="$dir"
                break
            fi
        fi
    done
    
    if [ -z "$try_path" ]; then
        echo "Error: No try found matching '$try_pattern'" >&2
        ls -1 "$tries_dir" 2>/dev/null || echo "  (none)" >&2
        return 1
    fi
    
    local try_name=$(basename "$try_path")
    local user_dir="$TRY2GITHUB_REPOS_DIR/$TRY2GITHUB_GITHUB_USER"
    local repo_path="$user_dir/$repo_name"
    
    mkdir -p "$user_dir"
    
    if [ -d "$repo_path" ]; then
        echo "Error: Repo already exists at $repo_path" >&2
        return 1
    fi
    
    echo "Promoting: $try_name -> $repo_name"
    mv "$try_path" "$repo_path"
    cd "$repo_path" || return 1
    
    if ! git remote get-url origin 2>/dev/null; then
        if command -v gh &>/dev/null; then
            echo "Creating GitHub repo: $TRY2GITHUB_GITHUB_USER/$repo_name"
            gh repo create "$repo_name" --private --source=. --push 2>/dev/null || {
                echo "Warning: Failed to create GitHub repo."
            }
        else
            echo "GitHub CLI (gh) not found."
        fi
    fi
    
    echo "Promoted to $repo_path"
}

# ============================================
# repo - Navigate GitHub repos
# ============================================
repo() {
    local cmd="${1:-ls}"
    local user_dir="$TRY2GITHUB_REPOS_DIR/$TRY2GITHUB_GITHUB_USER"
    
    mkdir -p "$user_dir"
    
    case "$cmd" in
        ls|list)
            ls -1 "$user_dir" 2>/dev/null
            ;;
        cd)
            if [ -z "$2" ]; then
                cd "$user_dir"
            else
                local target=$(find "$user_dir" -maxdepth 1 -type d -name "*$2*" | head -1)
                if [ -n "$target" ]; then
                    cd "$target"
                    echo "$(basename "$target")"
                else
                    echo "No repo matching '$2'" >&2
                    return 1
                fi
            fi
            ;;
        open)
            if [ -z "$2" ]; then
                gh repo view --web 2>/dev/null || echo "Not a git repo" >&2
            else
                gh repo view "$TRY2GITHUB_GITHUB_USER/$2" --web 2>/dev/null || open "https://github.com/$TRY2GITHUB_GITHUB_USER/$2"
            fi
            ;;
        path)
            echo "$user_dir"
            ;;
        *)
            local target=$(find "$user_dir" -maxdepth 1 -type d -name "*$cmd*" | head -1)
            if [ -n "$target" ]; then
                cd "$target"
                echo "$(basename "$target")"
            else
                echo "Usage: repo [ls|cd|open|path] [name]" >&2
                return 1
            fi
            ;;
    esac
}

# ============================================
# clone - Clone external repos to proper location
# ============================================
clone() {
    local url="$1"
    
    if [ -z "$url" ]; then
        echo "Usage: clone <github-url>" >&2
        return 1
    fi
    
    local user repo
    
    case "$url" in
        *github.com*)
            user=$(echo "$url" | sed -E 's|.*github\.com[/:]([^/]+)/.*|\1|')
            repo=$(echo "$url" | sed -E 's|.*github\.com[/:][^/]+/([^/]+)\.git.*|\1|')
            if [ -z "$repo" ]; then
                repo=$(echo "$url" | sed -E 's|.*github\.com[/:][^/]+/([^/]+).*|\1|')
            fi
            ;;
        *)
            echo "Error: URL must contain github.com" >&2
            return 1
            ;;
    esac
    
    if [ -z "$user" ] || [ -z "$repo" ]; then
        echo "Error: Could not parse user/repo" >&2
        return 1
    fi
    
    local target="$HOME/src/github.com/$user/$repo"
    
    if [ -d "$target" ]; then
        echo "Directory exists: $target"
        cd "$target"
        return 0
    fi
    
    echo "Cloning to: $target"
    mkdir -p "$(dirname "$target")"
    
    if git clone "$url" "$target"; then
        cd "$target"
        echo "Cloned: $(basename "$target")"
    else
        echo "Clone failed" >&2
        return 1
    fi
}

# ============================================
# Aliases
# ============================================
alias pr='promote'
