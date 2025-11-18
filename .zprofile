# ~/.zprofile
# Enhanced cross-platform configuration for login shells
# This file runs at login, before .zshrc

# ---------- System Detection ----------
case "$(uname -s)" in
    Linux*)     export SYSTEM="Linux";;
    Darwin*)    export SYSTEM="macOS";;
    CYGWIN*)    export SYSTEM="Windows";;
    MINGW*)     export SYSTEM="Windows";;
    *)          export SYSTEM="Unknown";;
esac

# Check if running in WSL
if [[ -f /proc/version ]] && grep -q Microsoft /proc/version; then
    export SYSTEM="WSL"
fi

# ---------- Path Configuration ----------
# Core paths that should be loaded once at login

# Set base PATH
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Add user bin directories
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
export PATH="$HOME/scripts:$PATH"

# System-specific paths
if [[ "$SYSTEM" == "macOS" ]]; then
    # Apple Silicon Mac
    if [[ -d "/opt/homebrew/bin" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    # Intel Mac
    elif [[ -d "/usr/local/bin" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    # Add macOS specific paths
    export PATH="/Library/Apple/usr/bin:$PATH"
elif [[ "$SYSTEM" == "WSL" ]]; then
    # WSL-specific paths
    export PATH="/mnt/c/Windows/System32:$PATH"
    export WINHOME="/mnt/c/Users/$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r\n')"
fi

# ---------- Environment Variables ----------
# Set default editors (used by many programs)
export EDITOR="nvim"
export VISUAL="nvim"

# Set XDG Base Directory paths
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# Locale settings
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Less configuration
export LESS="-R"
export LESSHISTFILE="$XDG_CACHE_HOME/less/history"

# Color man pages
export MANPAGER="less -R --use-color -Dd+r -Du+b"
export MANROFFOPT="-c"

# ---------- Development Environment ----------
# Python settings
export PYTHONDONTWRITEBYTECODE=1  # Don't create __pycache__ directories
export PYTHONUNBUFFERED=1        # Unbuffered output

# Node.js settings
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"

# Java settings (if Java is installed)
if command -v java &>/dev/null; then
    export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null || echo "/usr/lib/jvm/default-java")
fi

# Go settings (if Go is installed)
if command -v go &>/dev/null; then
    export GOPATH="$HOME/go"
    export PATH="$PATH:$GOPATH/bin"
fi

# Rust settings (if Rust is installed)
if [[ -d "$HOME/.cargo" ]]; then
    export CARGO_HOME="$HOME/.cargo"
    export PATH="$PATH:$CARGO_HOME/bin"
fi

# ---------- Local Configuration ----------
# Load local settings that shouldn't be committed to git
if [[ -f "$HOME/.zprofile.local" ]]; then
    source "$HOME/.zprofile.local"
fi

# Ensure ~/.local/bin exists
mkdir -p "$HOME/.local/bin"

# Create XDG base directories if they don't exist
mkdir -p "$XDG_CONFIG_HOME"
mkdir -p "$XDG_DATA_HOME"
mkdir -p "$XDG_CACHE_HOME"
mkdir -p "$LESSHISTFILE:h"

eval "$(/opt/homebrew/bin/brew shellenv)"

# added by Snowflake SnowSQL installer v1.2
export PATH=/Applications/SnowSQL.app/Contents/MacOS:$PATH
