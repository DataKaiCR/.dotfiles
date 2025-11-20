# Neovim Configuration Structure

This document outlines the organization and components of my Neovim configuration. The setup uses lazy.nvim for plugin management and follows a modular approach for maintainability.

## Directory Structure

```
.config/nvim/
├── init.lua                 # Main entry point
├── structure.md             # This documentation file
└── lua/
    └── datakai/            # Personal namespace
        ├── init.lua        # Module initialization
        ├── lazy_init.lua   # Plugin manager setup
        ├── remap.lua       # General keybindings
        ├── set.lua         # Editor settings
        ├── utils/          # Utility modules
        │   ├── dotfiles.lua       # Dotfiles management
        │   ├── git_account.lua    # Git account switching
        │   ├── markdown.lua       # Markdown helpers
        │   ├── note_manager.lua   # Note creation/management
        │   └── obsidian_keymaps.lua # Obsidian-specific keymaps
        └── lazy/           # Plugin configurations
            ├── cloak.lua          # Sensitive information hiding
            ├── colors.lua         # Color schemes
            ├── completion.lua     # Autocompletion
            ├── copilot.lua        # GitHub Copilot
            ├── fugitive.lua       # Git commands
            ├── git.lua            # Git integrations
            ├── harpoon.lua        # Quick file navigation
            ├── lsp.lua            # Language Server Protocol
            ├── markdown.lua       # Markdown enhancements
            ├── obsidian.lua       # Obsidian note-taking
            ├── telescope.lua      # Fuzzy finder
            ├── treesitter.lua     # Syntax parsing
            ├── trouble.lua        # Diagnostics UI
            └── undotree.lua       # Undo history visualization
```

## Configuration Components

### Core Files

- **init.lua**: Entry point that loads the personal namespace
- **lazy_init.lua**: Sets up lazy.nvim plugin manager
- **remap.lua**: Global keymaps not specific to any plugin
- **set.lua**: Vim options and settings

### Utility Modules

- **dotfiles.lua**: Functions for managing dotfiles in a bare git repository
- **git_account.lua**: Tools for switching between git identities
- **markdown.lua**: Helper functions for working with Markdown
- **note_manager.lua**: Utilities for creating and managing notes
- **obsidian_keymaps.lua**: Centralized keymappings for Obsidian integration

### Knowledge Management System

The configuration includes a comprehensive setup for knowledge management with Obsidian:

#### Folder Structure (in ~/scriptorium/)
- `00-inbox`: Capture zone for new notes
- `00-journal`: Daily notes and journals
- `10-projects`: Project notes (following PARA methodology)
- `20-areas`: Areas of responsibility
- `30-resources`: Reference materials and resources
- `40-archives`: Completed or inactive items
- `50-zettelkasten`: Permanent notes following Zettelkasten method
- `60-input`: Input processing (future use)
- `70-output`: Output creation (future use)

#### Note Types and Templates
Each folder corresponds to a specific note type with dedicated templates and frontmatter.

## Keybinding Philosophy

- `<Space>` is used as the leader key
- Plugin-specific keybindings are grouped by plugin prefix:
  - `<leader>z*`: Obsidian/note-taking commands
  - `<leader>g*`: Git commands
  - `<leader>d*`: Dotfiles management
  - `<leader>p*`: Telescope/navigation commands

## Dotfiles Management

This configuration is managed using a bare git repository approach:
- Repository: `~/.dotfiles`
- Working directory: `$HOME`
- Custom commands in `dotfiles.lua` handle the workflow

## Custom Features

### Note Management
The note manager provides:
- Template-based note creation
- Proper frontmatter handling
- Project metadata extraction
- Quick note capture
- Daily journal creation

### Git Identity Management
Tools for:
- Switching between multiple git identities
- Creating client-specific worktrees with proper identity
- Initializing repositories with the correct account

### Obsidian Integration
- Full integration with the Obsidian knowledge base
- Specialized commands for different note types
- Markdown preview and syntax enhancements
