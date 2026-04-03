#!/bin/zsh
# try2github - Zsh integration
# Source this file in your ~/.zshrc

# Detect install location
if [[ -d "$HOME/.local/share/try2github" ]]; then
    TRY2GITHUB_ROOT="$HOME/.local/share/try2github"
elif [[ -d "${0:A:h:h}" ]]; then
    TRY2GITHUB_ROOT="${0:A:h:h}"
fi

export TRY2GITHUB_ROOT
export TRY2GITHUB_GITHUB_USER="${TRY2GITHUB_GITHUB_USER:-lequangphu}"

# Source the core library
source "$TRY2GITHUB_ROOT/lib/try2github.sh"

# ============================================
# try - Create a new experiment (zsh wrapper)
# ============================================
try() {
    try2github_try "$@"
    local result=$?
    # Auto-cd if successful and only given a name
    if [[ $result -eq 0 && $# -eq 1 && -d "$TRY2GITHUB_TRIES_DIR"/*"$1"* ]]; then
        local target=$(find "$TRY2GITHUB_TRIES_DIR" -maxdepth 1 -type d -name "*$1*" | head -1)
        [[ -n "$target" ]] && cd "$target"
    fi
    return $result
}

# ============================================
# promote - Promote try to GitHub repo
# ============================================
promote() {
    try2github_promote "$@"
    local result=$?
    # Auto-cd if successful
    if [[ $result -eq 0 && -d "$TRY2GITHUB_REPOS_DIR/$TRY2GITHUB_GITHUB_USER/$2" ]]; then
        cd "$TRY2GITHUB_REPOS_DIR/$TRY2GITHUB_GITHUB_USER/$2"
    fi
    return $result
}

# ============================================
# repo - Navigate GitHub repos
# ============================================
repo() {
    local cmd="${1:-ls}"
    
    case "$cmd" in
        ls|list)
            try2github_repo ls
            ;;
        cd)
            if [[ -z "$2" ]]; then
                cd "$TRY2GITHUB_REPOS_DIR/$TRY2GITHUB_GITHUB_USER"
            else
                local target=$(find "$TRY2GITHUB_REPOS_DIR/$TRY2GITHUB_GITHUB_USER" -maxdepth 1 -type d -name "*$2*" | head -1)
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
            echo "$TRY2GITHUB_REPOS_DIR/$TRY2GITHUB_GITHUB_USER"
            ;;
        *)
            # Shorthand: try to cd to repo matching the arg
            local target=$(find "$TRY2GITHUB_REPOS_DIR/$TRY2GITHUB_GITHUB_USER" -maxdepth 1 -type d -name "*$cmd*" | head -1)
            if [[ -n "$target" ]]; then
                cd "$target"
                echo "$(basename "$target")"
            else
                echo "Unknown: $cmd" >&2
                return 1
            fi
            ;;
    esac
}

# ============================================
# Completion functions
# ============================================

_repo_complete() {
    local -a repos
    repos=(${(f)"$(try2github_repo ls 2>/dev/null)"})
    _describe -t repos 'repos' repos
}

_promote_complete() {
    local -a tries
    local tries_dir="$TRY2GITHUB_TRIES_DIR"
    tries=(${(f)"$(ls -1 "$tries_dir" 2>/dev/null)"})
    _describe -t tries 'tries' tries
}

# Register completions
compdef _repo_complete repo 2>/dev/null
compdef _promote_complete promote 2>/dev/null

# ============================================
# clone - Clone external repos to proper location
# Usage: clone <github-url>
# Example: clone https://github.com/NousResearch/hermes-agent-self-evolution.git
# Clones to ~/src/github.com/NousResearch/hermes-agent-self-evolution
# ============================================
clone() {
    local url="$1"
    
    if [[ -z "$url" ]]; then
        echo "Usage: clone <github-url>"
        return 1
    fi
    
    # Extract user and repo from URL
    # Supports: https://github.com/user/repo.git or git@github.com:user/repo.git
    local user repo
    
    if [[ "$url" == *"github.com"* ]]; then
        # HTTPS: https://github.com/user/repo.git
        # SSH: git@github.com:user/repo.git
        user=$(echo "$url" | sed -E 's|.*github\.com[/:]([^/]+)/.*|\1|')
        repo=$(echo "$url" | sed -E 's|.*github\.com[/:][^/]+/([^/]+)(\.git)?$|\1|')
    else
        echo "Error: URL must contain github.com"
        return 1
    fi
    
    if [[ -z "$user" || -z "$repo" ]]; then
        echo "Error: Could not parse user/repo from URL"
        echo "Usage: clone https://github.com/user/repo.git"
        return 1
    fi
    
    local target="$HOME/src/github.com/$user/$repo"
    
    if [[ -d "$target" ]]; then
        echo "Directory already exists: $target"
        echo "Use: cd $target"
        return 1
    fi
    
    echo "Cloning to: $target"
    mkdir -p "$(dirname "$target")"
    
    if git clone "$url" "$target"; then
        cd "$target"
        echo "Cloned: $(basename "$target")"
    else
        echo "Clone failed"
        return 1
    fi
}

# ============================================
# Aliases
# ============================================
alias tr='try'
alias pr='promote'
compdef _promote_complete promote 2>/dev/null

# ============================================
# Aliases (optional)
# ============================================
alias tr='try'
alias pr='promote'
