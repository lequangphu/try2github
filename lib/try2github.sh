#!/bin/sh
# try2github - Core POSIX functions
# Source this file for shell-agnostic functionality

# Configuration
TRY2GITHUB_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/try2github"
TRY2GITHUB_CONFIG_FILE="$TRY2GITHUB_CONFIG_DIR/config.yaml"

# Default paths (overridable via env vars)
TRY2GITHUB_TRIES_DIR="${TRY2GITHUB_TRIES_DIR:-$HOME/src/tries}"
TRY2GITHUB_REPOS_DIR="${TRY2GITHUB_REPOS_DIR:-$HOME/src/github.com}"
TRY2GITHUB_GITHUB_USER="${TRY2GITHUB_GITHUB_USER:-$(git config --global user.name 2>/dev/null || echo "")}"
TRY2GITHUB_TEMPLATES_DIR="${TRY2GITHUB_TEMPLATES_DIR:-$TRY2GITHUB_CONFIG_DIR/templates}"

# Get the directory where this script is located
TRY2GITHUB_ROOT="${TRY2GITHUB_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# ============================================
# _try2github_date_prefix - Get current date prefix
# ============================================
_try2github_date_prefix() {
    date +%Y-%m-%d
}

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
# _try2github_copy_template - Copy template to project
# ============================================
_try2github_copy_template() {
    local project_path="$1"
    local template="$2"
    local project_name="$3"
    local date_str="$4"
    
    local template_dir=""
    
    # Check user templates first, then built-in
    if [ -d "$TRY2GITHUB_TEMPLATES_DIR/$template" ]; then
        template_dir="$TRY2GITHUB_TEMPLATES_DIR/$template"
    elif [ -d "$TRY2GITHUB_ROOT/templates/$template" ]; then
        template_dir="$TRY2GITHUB_ROOT/templates/$template"
    fi
    
    if [ -n "$template_dir" ]; then
        # Copy template files (including hidden files)
        cp -r "$template_dir"/. "$project_path/" 2>/dev/null || cp -r "$template_dir"/* "$project_path/" 2>/dev/null || true
        
        # Substitute variables in template files
        for file in "$project_path"/*; do
            if [ -f "$file" ]; then
                sed -i.bak "s/{{PROJECT_NAME}}/$project_name/g" "$file" 2>/dev/null
                sed -i.bak "s/{{DATE}}/$date_str/g" "$file" 2>/dev/null
                sed -i.bak "s/{{AUTHOR}}/$TRY2GITHUB_GITHUB_USER/g" "$file" 2>/dev/null
                rm -f "$file.bak"
            fi
        done
        return 0
    fi
    
    return 1
}

# ============================================
# try2github_try - Create a new experiment
# Usage: try2github_try <name> [template]
# ============================================
try2github_try() {
    local name="${1:-$(date +%Y-%m-%d)-untitled}"
    local template="${2:-default}"
    local date_prefix=$(_try2github_date_prefix)
    local project_path="$TRY2GITHUB_TRIES_DIR/${date_prefix}-${name}"
    
    # Check if already exists
    if [ -d "$project_path" ]; then
        echo "Error: $project_path already exists" >&2
        return 1
    fi
    
    # Create directory
    mkdir -p "$project_path"
    
    # Try to copy template
    if ! _try2github_copy_template "$project_path" "$template" "$name" "$date_prefix"; then
        # Create minimal structure
        cat > "$project_path/README.md" << EOF
# $name

Started: $(date)
Status: Experimental

## Purpose

## Notes

## Decision Log

## Promotion Criteria
- [ ] Has README with purpose
- [ ] Has working code
- [ ] Solves a real problem
- [ ] Worth maintaining
EOF
    fi
    
    # Initialize git
    (cd "$project_path" && git init -q 2>/dev/null)
    
    echo "Created: $project_path"
    
    # Change to directory if running interactively
    if [ -n "$TRY2GITHUB_AUTO_CD" ]; then
        cd "$project_path" 2>/dev/null || true
    fi
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
        echo "Example: try2github_promote dspy-app dspy-oracle-kit" >&2
        return 1
    fi
    
    # Find the try directory
    local try_path=$(_try2github_find_try "$try_pattern")
    
    if [ -z "$try_path" ]; then
        echo "Error: No try found matching '$try_pattern'" >&2
        echo "Available tries:" >&2
        ls -1 "$TRY2GITHUB_TRIES_DIR" 2>/dev/null || echo "  (none)" >&2
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
    
    # Change to directory if running interactively
    if [ -n "$TRY2GITHUB_AUTO_CD" ]; then
        cd "$repo_path" 2>/dev/null || true
    fi
}

# ============================================
# try2github_repo - List and navigate repos
# Usage: try2github_repo [ls|cd|open|path] [name]
# ============================================
try2github_repo() {
    local user_dir="$TRY2GITHUB_REPOS_DIR/$TRY2GITHUB_GITHUB_USER"
    
    # Ensure directory exists
    mkdir -p "$user_dir"
    
    # No args = list repos
    if [ $# -eq 0 ]; then
        ls -1 "$user_dir" 2>/dev/null
        return 0
    fi
    
    local cmd="$1"
    
    case "$cmd" in
        ls|list)
            ls -1 "$user_dir" 2>/dev/null
            ;;
        cd)
            if [ -z "$2" ]; then
                cd "$user_dir" 2>/dev/null || return 1
                return 0
            fi
            local target=$(_try2github_find_repo "$2")
            if [ -n "$target" ]; then
                cd "$target" 2>/dev/null && echo "$(basename "$target")"
            else
                echo "No repo matching '$2'" >&2
                return 1
            fi
            ;;
        open)
            if [ -z "$2" ]; then
                if command -v gh >/dev/null 2>&1; then
                    gh repo view --web 2>/dev/null || echo "Not a git repo" >&2
                else
                    echo "GitHub CLI (gh) not installed" >&2
                    return 1
                fi
            else
                local url="https://github.com/$TRY2GITHUB_GITHUB_USER/$2"
                if command -v open >/dev/null 2>&1; then
                    open "$url"
                elif command -v xdg-open >/dev/null 2>&1; then
                    xdg-open "$url"
                else
                    echo "$url"
                fi
            fi
            ;;
        path)
            echo "$user_dir"
            ;;
        *)
            # Try to cd to repo matching the arg
            local target=$(_try2github_find_repo "$cmd")
            if [ -n "$target" ]; then
                cd "$target" 2>/dev/null && echo "$(basename "$target")"
            else
                echo "Unknown: $cmd" >&2
                echo "Usage: try2github_repo [ls|cd|open|path] [name]" >&2
                return 1
            fi
            ;;
    esac
}


