# try2github

Experiment locally, promote to GitHub when ready.

A lightweight CLI workflow for managing experimental projects that may become production repositories.

## Quick Start

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/lequangphu/try2github/main/install.sh | bash

# Create an experiment
try my-idea

# Work on it, iterate...

# Promote to GitHub when ready
promote my-idea my-idea-repo
```

## Overview

```
~/src/
├── github.com/
│   └── yourname/          # Production repos (created via promote)
│       ├── project-a/
│       └── project-b/
└── tries/                 # Experiments (disposable, dated)
    ├── 2026-04-03-my-idea/
    └── 2026-04-05-another-test/
```

## Commands

### `try <name> [template]`

Create a new experiment in `~/src/tries/` with a date prefix.

```bash
try my-new-project              # Creates ~/src/tries/2026-04-03-my-new-project/
try my-api --template node      # Uses node template
try my-ml --template python     # Uses python template
```

**Templates:**
- `default` - Minimal README only
- `python` - Python project structure (src/, tests/, notebooks/)
- `node` - Node.js project structure (src/, tests/, package.json)
- `data` - Data science structure (notebooks/, queries/)

### `promote <try-pattern> <repo-name>`

Move an experiment to production and create a GitHub repository.

```bash
promote my-idea my-project        # Promotes 2026-04-03-my-idea to github.com/yourname/my-project
```

Requirements:
- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated

### `repo [ls|cd|open|path] [name]`

Navigate your GitHub repositories.

```bash
repo                    # List all repos
repo cd my-project      # Change to matching repo
repo open               # Open current repo on GitHub
repo path               # Print repos directory path
repo my-project         # Shorthand: cd to matching repo
```

## Installation

### One-liner (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/lequangphu/try2github/main/install.sh | bash
```

### Manual

```bash
git clone https://github.com/lequangphu/try2github.git ~/.local/share/try2github
source ~/.local/share/try2github/shell/try2github.zsh  # or .bash for bash
```

### Requirements

- `git` (required)
- `gh` (GitHub CLI) - for `promote` command to create GitHub repos

## Configuration

Set environment variables to customize paths:

```bash
# ~/.zshrc or ~/.bashrc
export TRY2GITHUB_TRIES_DIR="$HOME/experiments"
export TRY2GITHUB_REPOS_DIR="$HOME/projects/github.com"
export TRY2GITHUB_GITHUB_USER="myusername"
```

Or create a config file at `~/.config/try2github/config.yaml` (future feature).

## Custom Templates

Add custom templates to `~/.config/try2github/templates/<name>/`:

```
~/.config/try2github/templates/
├── my-python/
│   ├── README.md
│   ├── requirements.txt
│   └── src/
└── my-web/
    ├── README.md
    ├── package.json
    └── src/
```

Template variables:
- `{{PROJECT_NAME}}` - Project name
- `{{DATE}}` - Current date (YYYY-MM-DD)
- `{{AUTHOR}}` - Git user name

## Workflow Example

```bash
# 1. Start experimenting
try oracle-detection --template python
cd oracle-detection
# ... hack on it ...

# 2. Iterate in tries/
try oracle-detection-v2 --template python
cd oracle-detection-v2
# ... better version ...

# 3. Ready to publish
promote oracle-detection-v2 oracle-manipulation-detector
# Creates GitHub repo, pushes code, ready for CI/CD

# 4. Navigate repos
repo cd oracle
# Work on production code
```

## Shell Support

- **Zsh**: Full support with completions
- **Bash**: Full support with basic completions
- **Fish**: Not yet implemented (contributions welcome)

## Why try2github?

- **Low friction** for starting experiments (no repo creation ceremony)
- **Clean separation** between disposable tries and production repos
- **Dated organization** makes it easy to find recent work
- **Easy promotion** when an experiment proves valuable
- **Mirrors Go's GOPATH** structure for consistency

## License

MIT

## Contributing

Contributions welcome! Priority areas:
- Fish shell support
- Homebrew formula
- More templates
- FZF integration for fuzzy finding

See [Issues](https://github.com/lequangphu/try2github/issues) for ideas.
