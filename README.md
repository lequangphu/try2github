# try2github

**try2github** extends [tobi/try](https://github.com/tobi/try) with GitHub workflow features.

It adds commands to move your experiments (tries) to GitHub repositories, and manage your production repos.

## Requirements

- [tobi/try](https://github.com/tobi/try) — Install first:
  ```bash
  gem install try-cli
  ```

## What It Does

```
~/src/
├── tries/                      # Your experiments (managed by tobi/try)
│   ├── 2026-04-03-redis-test/
│   └── 2026-04-05-api-client/
└── github.com/
    ├── lequangphu/             # Your production repos
    │   ├── trading_bot/
    │   └── try2github/
    └── NousResearch/           # External repos
        └── hermes-agent/
```

## Commands

### `try` — From tobi/try

Fuzzy search and navigate your experiments.

```bash
try                    # Interactive fuzzy finder
try redis              # Search for redis-related tries
```

Install tobi/try first: `gem install try-cli`

### `promote <try-name> <repo-name>`

Move a try to your GitHub repos and create a GitHub repository.

```bash
promote redis-test my-redis-project
# Moves ~/src/tries/2026-04-03-redis-test to ~/src/github.com/lequangphu/my-redis-project
# Creates GitHub repo, pushes code
```

### `repo [ls|cd|open|path|fav] [name]`

Navigate your GitHub repositories.

```bash
repo                   # List all repos
repo cd trading        # Change to matching repo
repo open              # Open current repo on GitHub
repo path              # Print repos directory path
repo fav               # Fuzzy select (requires fzf)
repo trading           # Shorthand: cd to matching repo
```

### `clone <github-url>`

Clone external repos to the proper namespaced location.

```bash
# Don't do this (clutters home directory):
git clone https://github.com/NousResearch/hermes-agent-self-evolution.git

# Do this instead:
clone https://github.com/NousResearch/hermes-agent-self-evolution.git
# Clones to ~/src/github.com/NousResearch/hermes-agent-self-evolution
```

## Installation

### 1. Install tobi/try (Required)

```bash
gem install try-cli
```

### 2. Install try2github

```bash
# Clone to your own repos
git clone https://github.com/lequangphu/try2github.git ~/src/github.com/lequangphu/try2github

# Install
cd ~/src/github.com/lequangphu/try2github && make install
```

### 3. Add to Shell

Add to `~/.zshrc`:

```bash
# tobi/try - for managing experiments
eval "$(try init ~/src/tries)"

# try2github - for GitHub workflow
source ~/.local/share/try2github/shell/try2github.zsh
```

Then reload:
```bash
source ~/.zshrc
```

---

## For AI Agents (Claude, Copilot, etc.)

If you are an AI agent helping a user set up try2github, follow these steps:

### Prerequisites Check
1. Check if Ruby is installed: `command -v ruby`
2. Check if gem is available: `command -v gem`
3. If not, install Ruby: `brew install ruby` (macOS) or `apt-get install ruby` (Linux)

### Installation Steps
```bash
# 1. Install try2github (this will auto-install tobi/try if missing)
cd ~/src/github.com/lequangphu/try2github && make install

# 2. Add to user's shell config (~/.zshrc or ~/.bashrc)
echo 'eval "$(try init ~/src/tries)"' >> ~/.zshrc
echo 'source ~/.local/share/try2github/shell/try2github.zsh' >> ~/.zshrc

# 3. Reload shell config
source ~/.zshrc
```

### Verify Installation
```bash
which try      # Should show tobi/try
which promote  # Should be a function
type repo      # Should be a function
type clone     # Should be a function
```

### Common Tasks
- **Create experiment**: `try <name>` (uses tobi/try's fuzzy finder)
- **Promote to GitHub**: `promote <try-name> <repo-name>`
- **List repos**: `repo`
- **Navigate repos**: `repo cd <name>` or `repo <name>`
- **Clone external repo**: `clone <github-url>`

---

## Workflow Example

```bash
# 1. Create experiment using tobi/try's fuzzy finder
try redis-pool

# Work on it...

# 2. Promote to GitHub when ready
promote redis-pool redis-connection-pool

# 3. Navigate production repos
repo cd redis

# 4. Clone someone else's repo
clone https://github.com/NousResearch/hermes-agent-self-evolution.git
```

## Configuration

Set environment variables in `~/.zshrc`:

```bash
export TRY2GITHUB_GITHUB_USER="yourusername"  # Default: lequangphu
export TRY2GITHUB_REPOS_DIR="$HOME/projects"   # Default: ~/src/github.com
export TRY_PATH="$HOME/experiments"            # tobi/try path
```

## Differences from tobi/try

| Feature | tobi/try | try2github |
|---------|----------|------------|
| `try` command | ✅ Fuzzy finder for tries | ❌ Not included (use tobi/try) |
| `promote` | ❌ No | ✅ Move tries to GitHub |
| `repo` | ❌ No | ✅ Navigate GitHub repos |
| `clone` | ❌ No | ✅ Clone to proper location |

**try2github does not replace tobi/try — it extends it.**

## Shell Support

- **Zsh**: Full support with completions
- **Bash**: Full support with basic completions

## Requirements

- Ruby (for tobi/try)
- git
- gh (GitHub CLI) — for `promote` to create GitHub repos

## License

MIT
