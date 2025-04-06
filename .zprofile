# ~/.zprofile
# This file runs at login, before .zshrc
# Use it for environment variables that should be set once

# Set PATH
export PATH="$HOME/bin:/usr/local/bin:$PATH"

# Add Homebrew to PATH (Apple Silicon Macs)
if [ -d "/opt/homebrew/bin" ]; then
    export PATH="/opt/homebrew/bin:$PATH"
    export PATH="/opt/homebrew/sbin:$PATH"
fi

# Add Homebrew to PATH (Intel Macs)
if [ -d "/usr/local/bin" ]; then
    export PATH="/usr/local/bin:$PATH"
    export PATH="/usr/local/sbin:$PATH"
fi

# Set default editors
export EDITOR="nvim"
export VISUAL="nvim"

eval "$(/opt/homebrew/bin/brew shellenv)"

# added by Snowflake SnowSQL installer
export PATH=/home/wmhstecher/bin:$PATH
