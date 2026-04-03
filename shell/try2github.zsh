#!/bin/zsh
# try2github - Zsh integration
# Source this file in your ~/.zshrc

# Get the directory where this script is located
local TRY2GITHUB_SHELL_DIR="${0:A:h}"
local TRY2GITHUB_ROOT="${TRY2GITHUB_SHELL_DIR:h}"

# Export root for core functions
export TRY2GITHUB_ROOT

# Source the core library
source "$TRY2GITHUB_ROOT/lib/try2github.sh"

# ============================================
# try - Create a new experiment (zsh wrapper)
# ============================================
try() {
    TRY2GITHUB_AUTO_CD=1 try2github_try "$@"
}

# ============================================
# promote - Promote try to GitHub repo
# ============================================
promote() {
    TRY2GITHUB_AUTO_CD=1 try2github_promote "$@"
}

# ============================================
# repo - Navigate GitHub repos
# ============================================
repo() {
    if [ $# -eq 0 ]; then
        try2github_repo ls
    else
        TRY2GITHUB_AUTO_CD=1 try2github_repo "$@"
    fi
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
compdef _try_complete try 2>/dev/null
compdef _repo_complete repo 2>/dev/null
compdef _promote_complete promote 2>/dev/null

# ============================================
# Aliases (optional)
# ============================================
alias tr='try'
alias pr='promote'
