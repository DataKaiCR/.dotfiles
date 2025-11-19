#!/usr/bin/env zsh
# Modern CLI Tools Configuration
# Performance-optimized aliases and integrations
# All tools are Rust/Go - zero performance impact

# ============================================================================
# BAT - Better cat with syntax highlighting
# ============================================================================

export BAT_THEME="Nord"  # Matches your terminal theme
export BAT_STYLE="numbers,changes,header"

# Aliases
alias cat='bat --style=plain --paging=never'
alias catp='bat --style=plain'  # Plain without line numbers
alias preview='bat --style=numbers,changes,header'
alias batt='bat --theme=gruvbox-dark'  # Alternative theme

# Use bat for man pages
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# ============================================================================
# EZA - Modern ls replacement
# ============================================================================

# Core aliases
alias ls='eza --icons --group-directories-first'
alias ll='eza --long --git --icons --group-directories-first'
alias la='eza --long --all --git --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons'
alias ltt='eza --tree --level=3 --icons'

# Specialized views
alias lg='eza --long --git --icons --no-filesize --no-time --no-user --no-permissions'  # Git-focused
alias lf='eza --long --icons --sort=modified'  # Sort by modified time
alias lz='eza --long --icons --sort=size'  # Sort by size

# ============================================================================
# ZOXIDE - Smart cd with learning
# ============================================================================

# Initialize zoxide (replaces cd)
eval "$(zoxide init zsh)"

# Keep traditional cd available
alias cd='z'
alias cdi='zi'  # Interactive selection with fzf

# Quick project jumps (will learn your patterns)
# After using a few times:
#   z cert     → ~/projects/cert-study-platform
#   z dbx      → ~/projects/dbx-hub
#   z script   → ~/scriptorium

# ============================================================================
# FZF Integration with Modern Tools
# ============================================================================

# Use bat for preview in fzf
export FZF_DEFAULT_OPTS="
  --preview 'bat --style=numbers --color=always --line-range :500 {}'
  --preview-window right:60%:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-u:preview-page-up'
  --bind 'ctrl-d:preview-page-down'
"

# Use fd instead of find for fzf (if you have it)
if command -v fd > /dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# ============================================================================
# LAZYGIT Configuration
# ============================================================================

alias lg='lazygit'
alias lzg='lazygit'

# Quick git operations (still use lazygit for complex stuff)
alias gst='git status'
alias glog='git log --oneline --graph --decorate --all'

# ============================================================================
# GH - GitHub CLI
# ============================================================================

# Quick PR operations
alias prc='gh pr create --fill'
alias prv='gh pr view --web'
alias prs='gh pr status'
alias prl='gh pr list'
alias prcheck='gh pr checks'

# Quick repo operations
alias repo='gh repo view --web'
alias repos='gh repo list'

# Issues
alias issue='gh issue create'
alias issues='gh issue list'

# ============================================================================
# YQ - YAML query tool (like jq for YAML)
# ============================================================================

alias yq-pretty='yq -C'  # Colored output
alias yq-json='yq -o json'  # Convert YAML to JSON

# Quick queries
alias yq-keys='yq "keys"'  # Show top-level keys
alias yq-project='yq ".project" .project.toml'  # Query project info

# ============================================================================
# Cloud CLI Enhancements
# ============================================================================

# AWS helpers
alias awsl='aws s3 ls'
alias awsid='aws sts get-caller-identity'
alias awsec2='aws ec2 describe-instances --output table'

# Azure helpers
alias azls='az resource list --output table'
alias azid='az account show'

# Databricks helpers
alias dbxls='databricks workspace list'
alias dbxclusters='databricks clusters list'

# ============================================================================
# Performance Monitoring (Optional)
# ============================================================================

# Show command execution time for slow commands
REPORTTIME=10  # Show time for commands that take > 10 seconds

# ============================================================================
# Tmux Sessionizer Cache Management
# ============================================================================

# Refresh tmux-sessionizer cache manually
tsrefresh() {
    local cache_file="${TMPDIR:-/tmp}/tmux-sessionizer-cache-$USER"
    rm -f "$cache_file"
    echo "🔄 Refreshing cache..."

    # Trigger a rebuild by running sessionizer in background
    (tmux-sessionizer 2>&1 <<< "" &>/dev/null &)

    # Wait a moment for cache to build
    sleep 1

    if [[ -f "$cache_file" ]]; then
        echo "✓ Cache refreshed! Found $(wc -l < $cache_file | tr -d ' ') projects"
    else
        echo "⚠️  Cache not built yet. Run sessionizer to build it."
    fi
}

# Show cache info
alias tsinfo='CACHE="${TMPDIR:-/tmp}/tmux-sessionizer-cache-$USER"; if [ -f "$CACHE" ]; then echo "Cache: $CACHE"; echo "Projects: $(wc -l < $CACHE)"; echo "Age: $(( ($(date +%s) - $(stat -f %m "$CACHE")) / 60 )) minutes"; else echo "No cache found. Run tmux-sessionizer to build."; fi'

# ============================================================================
# Zoxide + Project CLI Integration
# ============================================================================

# Jump to project and show info
zp() {
    if [ -z "$1" ]; then
        echo "Usage: zp <project-pattern>"
        echo "Example: zp cert"
        return 1
    fi
    z "$1" && project here
}

# Jump to project and check cloud context
zc() {
    if [ -z "$1" ]; then
        echo "Usage: zc <project-pattern>"
        echo "Example: zc cert"
        return 1
    fi
    z "$1" && cstat
}

# Jump to project and open in nvim
zn() {
    if [ -z "$1" ]; then
        echo "Usage: zn <project-pattern>"
        echo "Example: zn cert"
        return 1
    fi
    z "$1" && nvim .
}

# Jump to project, show info, and check cloud (complete workflow)
zwork() {
    if [ -z "$1" ]; then
        echo "Usage: zwork <project-pattern>"
        echo "Example: zwork cert"
        return 1
    fi
    z "$1" && echo "" && project here && echo "" && cstat
}

# ============================================================================
# Utility Functions
# ============================================================================

# Quick file search with preview
ff() {
    local file
    file=$(fzf --preview 'bat --style=numbers --color=always {}') && nvim "$file"
}

# Search file contents and open in nvim
rg-edit() {
    if [ -z "$1" ]; then
        echo "Usage: rg-edit <pattern>"
        return 1
    fi

    local file line
    local result=$(rg --line-number --no-heading --color=always "$1" | fzf --ansi)

    if [ -n "$result" ]; then
        file=$(echo "$result" | cut -d: -f1)
        line=$(echo "$result" | cut -d: -f2)
        nvim "+$line" "$file"
    fi
}

# Quick project file search
pf() {
    local file
    file=$(fd --type f | fzf --preview 'bat --style=numbers --color=always {}') && nvim "$file"
}

# Quick directory jump with eza preview
zd() {
    local dir
    dir=$(fd --type d | fzf --preview 'eza --tree --level=2 --icons {}') && z "$dir"
}

# ============================================================================
# Git Delta Integration
# ============================================================================

# Delta is configured in ~/.gitconfig (see below)
# But add some aliases for manual use
alias diff='delta'
alias gdiff='git diff | delta'
alias gshow='git show | delta'

# ============================================================================
# Performance Notes
# ============================================================================

# All these tools are FAST:
# - bat:      Rust (faster than cat for large files with syntax highlighting)
# - eza:      Rust (faster than ls with more features)
# - zoxide:   Rust (learns in background, zero overhead)
# - delta:    Rust (only runs for git diff)
# - lazygit:  Go (only runs when called)
# - gh:       Go (only runs when called)
# - yq:       Go (only runs when called)

# No tools run on every command prompt
# No background processes
# No shell hooks except zoxide (minimal overhead)
