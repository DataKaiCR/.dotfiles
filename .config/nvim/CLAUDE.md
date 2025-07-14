# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal Neovim configuration that uses a modular architecture under the `lua/datakai/` namespace. The configuration emphasizes knowledge management, dotfiles synchronization, and cross-platform compatibility.

## Architecture

The codebase follows this structure:
- `init.lua` - Minimal entry point that requires the datakai module
- `lua/datakai/init.lua` - Main initialization including LSP setup and autocommands
- `lua/datakai/lazy_init.lua` - Bootstrap and configuration for lazy.nvim plugin manager
- `lua/datakai/lazy/*.lua` - Individual plugin configurations (one file per plugin)
- `lua/datakai/utils/*.lua` - Utility modules for git, dotfiles, notes, and platform compatibility

## Key Features & Utilities

### Dotfiles Management
The configuration includes a sophisticated dotfiles management system (`lua/datakai/utils/dotfiles.lua`) that:
- Uses git bare repository stored in `~/.dotfiles`
- Provides commands to add, commit, and sync dotfiles across machines
- Integrates with file operations (move, rename, delete)
- Access via `<leader>d` keybindings

### Knowledge Management
Deep integration with Obsidian vault located at `~/repos/notes/personal-notes/`:
- Custom note creation with templates
- Follows PARA method + Zettelkasten organization
- Access via `<leader>z` keybindings

### Multiple Git Identities
Supports switching between different git configurations (`lua/datakai/utils/git_account.lua`):
- Configurations stored in `git_accounts.lua`
- Switch accounts via `<leader>ga` command

## Development Commands

This configuration has no build system, tests, or linting setup. Development workflow relies on:
- LSP for diagnostics and formatting
- Auto-formatting on save for supported file types
- Git integration through fugitive

To reload configuration after changes:
```vim
:source %
```

To check for plugin updates:
```vim
:Lazy update
```

## Plugin Management

Uses lazy.nvim with configurations in `lua/datakai/lazy/`. When adding new plugins:
1. Create a new file in `lua/datakai/lazy/`
2. Follow the existing pattern:
   ```lua
   return {
       'plugin/name',
       dependencies = { ... },
       config = function()
           -- setup here
       end
   }
   ```

## Important Keybinding Patterns

- Leader key: `<Space>`
- Plugin commands: `<leader>p*` (Telescope), `<leader>g*` (Git), `<leader>z*` (Obsidian)
- LSP commands: Active when LSP attaches (gd, K, <leader>vrn, etc.)
- System clipboard: `<leader>y` (yank), `<leader>p` (paste)

## Cross-Platform Considerations

The configuration supports Windows, WSL, macOS, and Linux. Platform-specific logic is handled in `lua/datakai/utils/platform.lua`. When making changes:
- Test clipboard operations across platforms
- Use the provided platform detection utilities
- Consider path separators and home directory differences

## Python Development Setup

The configuration includes comprehensive Python development support:

### LSP and Tools
- **Basedpyright**: Modern Python language server (fork of Pyright with better defaults)
- **Ruff**: Fast Python linter and formatter (replaces Black, isort, flake8, etc.)
- **Debugpy**: Python debugging via nvim-dap

### Key Features
1. **Virtual Environment Management** (`<leader>vs`): Automatically detect and switch between virtual environments
2. **REPL Integration** (`<leader>rs`): IPython REPL with code execution support
3. **Debugging** (`<leader>d*`): Full debugging capabilities with DAP UI
4. **Docker Support**: Integration for containerized development workflows

### Python Keybindings
- `<leader>vs` - Select virtual environment
- `<leader>rs` - Start Python REPL
- `<leader>rc` - Send code to REPL
- `<leader>db` - Toggle debugger breakpoint
- `<leader>dc` - Continue debugging
- `<leader>nd` - Generate docstring

### Docker Development
- Docker LSP and docker-compose support configured
- Devcontainer integration available
- Docker keybindings under `<leader>k*` and `<leader>cd*`