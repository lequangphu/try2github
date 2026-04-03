#!/bin/zsh
# try2github - Zsh integration
# Extends tobi/try with GitHub workflow features
# 
# Requirements: tobi/try must be installed (gem install try-cli)
#
# Add to ~/.zshrc:
#   eval "$(try init ~/src/tries)"  # tobi/try initialization
#   source ~/.local/share/try2github/shell/try2github.zsh

# ============================================
# Check for tobi/try dependency
# ============================================
if ! command -v try &>/dev/null; then
    echo "Error: try2github requires tobi/try (gem install try-cli)" >&2
    return 1
fi

# ============================================
# Helper: Detect GitHub username
# ============================================
_try2github_detect_github_user() {
    # Try gh CLI first
    if command -v gh &>/dev/null; then
        gh api user -q .login 2>/dev/null && return 0
    fi
    # Fall back to git config
    git config --global user.name 2>/dev/null && return 0
    # Return empty
    echo ""
}

# ============================================
# Configuration
# ============================================
if [[ -d "$HOME/.local/share/try2github" ]]; then
    TRY2GITHUB_ROOT="$HOME/.local/share/try2github"
elif [[ -d "${0:A:h:h}" ]]; then
    TRY2GITHUB_ROOT="${0:A:h:h}"
fi

export TRY2GITHUB_ROOT
# Auto-detect if not set by user
export TRY2GITHUB_GITHUB_USER="${TRY2GITHUB_GITHUB_USER:-$(_try2github_detect_github_user)}"
export TRY2GITHUB_TRIES_DIR="${TRY_PATH:-$HOME/src/tries}"
export TRY2GITHUB_REPOS_DIR="${TRY2GITHUB_REPOS_DIR:-$HOME/src/github.com}"

# Source the core library (for promote, repo, clone)
source "$TRY2GITHUB_ROOT/lib/try2github.sh"

# ============================================
# promote - Promote a try to GitHub repo
# Usage: promote <try-name> <repo-name>
# ============================================
promote() {
    local try_pattern="$1"
    local repo_name="$2"
    
    if [[ -z "$try_pattern" || -z "$repo_name" ]]; then
        echo "Usage: promote <try-name> <repo-name>" >&2
        echo "Example: promote redis-test my-redis-project" >&2
        return 1
    fi
    
    # Find the try directory using fuzzy match (tobi/try style)
    local try_path=""
    local tries_dir="$TRY2GITHUB_TRIES_DIR"
    
    # Try exact match first
    for dir in "$tries_dir"/*; do
        if [[ "$(basename "$dir")" == *"$try_pattern"* ]]; then
            try_path="$dir"
            break
        fi
    done
    
    if [[ -z "$try_path" ]]; then
        echo "Error: No try found matching '$try_pattern'" >&2
        echo "Available tries:" >&2
        ls -1 "$tries_dir" 2>/dev/null || echo "  (none)" >&2
        return 1
    fi
    
    local try_name=$(basename "$try_path")
    local user_dir="$TRY2GITHUB_REPOS_DIR/$TRY2GITHUB_GITHUB_USER"
    local repo_path="$user_dir/$repo_name"
    
    # Ensure user directory exists
    mkdir -p "$user_dir"
    
    # Check if repo already exists
    if [[ -d "$repo_path" ]]; then
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
        if command -v gh &>/dev/null; then
            echo "Creating GitHub repo: $TRY2GITHUB_GITHUB_USER/$repo_name"
            gh repo create "$repo_name" --private --source=. --push 2>/dev/null || {
                echo "Warning: Failed to create GitHub repo. Created local repo only."
                echo "Run 'gh repo create' manually later."
            }
        else
            echo "GitHub CLI (gh) not found. Created local repo only."
            echo "Install gh: https://cli.github.com/"
        fi
    else
        echo "Existing git remote found, pushing..."
        git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null || true
    fi
    
    echo "Promoted to $repo_path"
}

# ============================================
# repo - Navigate GitHub repos
# Usage: repo [ls|cd|open|path|fav] [name]
# ============================================
repo() {
    local cmd="${1:-ls}"
    local user_dir="$TRY2GITHUB_REPOS_DIR/$TRY2GITHUB_GITHUB_USER"
    
    # Ensure directory exists
    mkdir -p "$user_dir"
    
    case "$cmd" in
        ls|list)
            ls -1 "$user_dir" 2>/dev/null
            ;;
        cd)
            if [[ -z "$2" ]]; then
                cd "$user_dir"
            else
                local target=$(find "$user_dir" -maxdepth 1 -type d -name "*$2*" | head -1)
                if [[ -n "$target" ]]; then
                    cd "$target"
                    echo "$(basename "$target")"
                else
                    echo "No repo matching '$2'" >&2
                    return 1
                fi
            fi
            ;;
        open)
            if [[ -z "$2" ]]; then
                gh repo view --web 2>/dev/null || echo "Not a git repo" >&2
            else
                gh repo view "$TRY2GITHUB_GITHUB_USER/$2" --web 2>/dev/null || open "https://github.com/$TRY2GITHUB_GITHUB_USER/$2"
            fi
            ;;
        path)
            echo "$user_dir"
            ;;
        fav|favorites)
            # Use tobi/try's favorites interface for repos
            echo "GitHub repos (fuzzy search):"
            local repo_list=$(ls -1 "$user_dir" 2>/dev/null | tr '\n' ' ')
            if command -v fzf &>/dev/null; then
                local selected=$(ls -1 "$user_dir" | fzf --prompt="repo> ")
                [[ -n "$selected" ]] && cd "$user_dir/$selected" && echo "$selected"
            else
                echo "Install fzf for fuzzy repo selection: brew install fzf"
                repo ls
            fi
            ;;
        *)
            # Shorthand: try to cd to repo matching the arg
            local target=$(find "$user_dir" -maxdepth 1 -type d -name "*$cmd*" | head -1)
            if [[ -n "$target" ]]; then
                cd "$target"
                echo "$(basename "$target")"
            else
                echo "Unknown: $cmd" >&2
                echo "Usage: repo [ls|cd|open|path|fav] [name]" >&2
                return 1
            fi
            ;;
    esac
}

# ============================================
# clone - Clone external repos to proper location
# Usage: clone <github-url>
# ============================================
clone() {
    local url="$1"
    
    if [[ -z "$url" ]]; then
        echo "Usage: clone <github-url>" >&2
        return 1
    fi
    
    # Extract user and repo from URL
    local user repo
    
    if [[ "$url" == *"github.com"* ]]; then
        # HTTPS: https://github.com/user/repo.git
        # SSH: git@github.com:user/repo.git
        user=$(echo "$url" | sed -E 's|.*github\.com[/:]([^/]+)/.*|\1|')
        repo=$(echo "$url" | sed -E 's|.*github\.com[/:][^/]+/([^/]+)\.git.*|\1|')
        # If no .git extension, extract without it
        if [[ -z "$repo" ]]; then
            repo=$(echo "$url" | sed -E 's|.*github\.com[/:][^/]+/([^/]+).*|\1|')
        fi
    else
        echo "Error: URL must contain github.com" >&2
        return 1
    fi
    
    if [[ -z "$user" || -z "$repo" ]]; then
        echo "Error: Could not parse user/repo from URL" >&2
        echo "Usage: clone https://github.com/user/repo.git" >&2
        return 1
    fi
    
    local target="$HOME/src/github.com/$user/$repo"
    
    if [[ -d "$target" ]]; then
        echo "Directory already exists: $target"
        echo "Use: cd $target"
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
# Completions
# ============================================
_repo_complete() {
    local -a repos
    repos=(${(f)"$(repo ls 2>/dev/null)"})
    _describe -t repos 'repos' repos
}

_promote_complete() {
    local -a tries
    local tries_dir="$TRY2GITHUB_TRIES_DIR"
    tries=(${(f)"$(ls -1 "$tries_dir" 2>/dev/null)"})
    _describe -t tries 'tries' tries
}

compdef _repo_complete repo 2>/dev/null
compdef _promote_complete promote 2>/dev/null

# ============================================
# Aliases
# ============================================
alias pr='promote'
