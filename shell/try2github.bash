#!/bin/bash
# try2github - Bash integration
# Source this file in your ~/.bashrc

# Get the directory where this script is located
TRY2GITHUB_SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRY2GITHUB_ROOT="$(dirname "$TRY2GITHUB_SHELL_DIR")"

# Export root for core functions
export TRY2GITHUB_ROOT

# Source the core library
source "$TRY2GITHUB_ROOT/lib/try2github.sh"

# ============================================
# try - Create a new experiment (bash wrapper)
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
# Completion for Bash (basic)
# ============================================

# Enable bash completion if available
if [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# Basic completion functions
_try_complete_bash() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local tries=$(ls -1 "$TRY2GITHUB_TRIES_DIR" 2>/dev/null | tr '\n' ' ')
    COMPREPLY=($(compgen -W "$tries" -- "$cur"))
}

_repo_complete_bash() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local repos=$(try2github_repo ls 2>/dev/null | tr '\n' ' ')
    COMPREPLY=($(compgen -W "$repos" -- "$cur"))
}

# Register completions
complete -F _try_complete_bash try
complete -F _repo_complete_bash repo
complete -F _try_complete_bash promote
