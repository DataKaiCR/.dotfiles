# Dotfiles

Personal dotfiles managed using the bare repository pattern.

## Setup

On a new machine:

```bash
# Clone as bare repo
git clone --bare git@github.com:DataKaiCR/.dotfiles.git $HOME/.dotfiles

# Define the alias
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Checkout files
dotfiles checkout

# Hide untracked files
dotfiles config --local status.showUntrackedFiles no
```

## Usage

Use `dotfiles` instead of `git`:

```bash
dotfiles status
dotfiles add .zshrc
dotfiles commit -m "Update zshrc"
dotfiles push
```

## Structure

- **Shell**: `.zshrc`, `.bashrc` - Cross-platform shell configuration
- **Editor**: `.config/nvim/` - Neovim configuration
- **Git**: `.config/git/` - Git configs with conditional includes for multi-identity
- **Tmux**: `.config/tmux/` - Tmux config with plugin management
- **Scripts**: `.local/bin/` - Custom utilities
  - `tmux-sessionizer` - Fuzzy project switcher with metadata
  - `project` - CLI for project metadata management
  - `tmux-project-setup` - Auto-configured tmux layouts

## Project Metadata System

Projects use `.project.toml` files for metadata tracking:
- Flat directory structure in `~/projects/` and `~/archive/`
- Metadata-driven organization (owner, status, tech stack, etc.)
- See `.config/docs/PROJECT_METADATA_SYSTEM.md` for details

## Key Features

- **Bare repo pattern** - No symlinks, files in natural locations
- **Cross-platform** - macOS, Linux, WSL support
- **Multi-git-identity** - Automatic switching per project
- **Tmux workflow** - Session persistence, project layouts, metadata search
