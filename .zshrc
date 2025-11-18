# =============================================================================
#  Enhanced Cross-Platform .zshrc for Data Engineering & Development
#  No frameworks - just pure Zsh optimized for performance
# =============================================================================

# ---------- Environment Detection ----------
case "$(uname -s)" in
    Linux*)     export SYSTEM="Linux";;
    Darwin*)    export SYSTEM="macOS";;
    CYGWIN*)    export SYSTEM="Windows";;
    MINGW*)     export SYSTEM="Windows";;
    *)          export SYSTEM="Unknown";;
esac

# Enhanced WSL detection
if [[ -f /proc/version ]]; then
    if grep -q "Microsoft" /proc/version || grep -q "WSL" /proc/version; then
        export SYSTEM="WSL"
        export WINDOWS_USERNAME=$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r\n')
    fi
fi

# ---------- Zsh-specific Settings ----------
autoload -U colors && colors

# Configure history
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt appendhistory
setopt histignorealldups
setopt share_history
setopt hist_verify
setopt hist_ignore_space

# Enable auto-completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'

# Enable vi mode with usability improvements
bindkey -v
export KEYTIMEOUT=1

# Better vi mode with some emacs keybindings for usability
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
bindkey '^r' history-incremental-search-backward

# Fix home, end and delete keys
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

# ---------- Shell Configuration ----------
export EDITOR='nvim'
export VISUAL='nvim'

# ---------- Color Configuration ----------
if [[ "$SYSTEM" == "macOS" ]]; then
    export CLICOLOR=1
    export LSCOLORS=ExFxBxDxCxegedabagacad
else
    alias ls='ls --color=auto'
fi

# ---------- Prompt Configuration ----------
# Git info in prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '[%b]'

# Set prompt
if [[ "$SYSTEM" == "WSL" ]]; then
    PROMPT="%{$fg[cyan]%}%n%{$reset_color%}@%{$fg[green]%}WSL(%{$fg[yellow]%}$WINDOWS_USERNAME%{$fg[green]%})%{$reset_color%}:%{$fg[blue]%}%~%{$reset_color%}"
    PROMPT+=' %{$fg[yellow]%}${vcs_info_msg_0_}%{$reset_color%}'
    PROMPT+=$'\n❯ '
else
    PROMPT="%{$fg[cyan]%}%n%{$reset_color%}@%{$fg[green]%}%m%{$reset_color%}:%{$fg[blue]%}%~%{$reset_color%}"
    PROMPT+=' %{$fg[yellow]%}${vcs_info_msg_0_}%{$reset_color%}'
    PROMPT+=$'\n❯ '
fi

# ---------- WSL-Specific Settings ----------
if [[ "$SYSTEM" == "WSL" ]]; then
    export BROWSER="wslview"
    export WINHOME="/mnt/c/Users/$WINDOWS_USERNAME"
fi

# ---------- Path Configurations ----------
export PATH="$PATH:/usr/local/bin"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/scripts:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/Library/Python/3.9/bin:$PATH"

# PostgreSQL
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# Add Go path if Go is installed
if command -v go &>/dev/null; then
    export GOPATH="$HOME/go"
    export PATH="$PATH:$GOPATH/bin"
fi

# Add Rust path if Rust is installed
if [[ -d "$HOME/.cargo/bin" ]]; then
    export PATH="$PATH:$HOME/.cargo/bin"
fi

# Add Deno path if Deno is installed
if [[ -d "$HOME/.deno" ]]; then
    export DENO_INSTALL="$HOME/.deno"
    export PATH="$PATH:$DENO_INSTALL/bin"
fi

# ---------- Tool Integration ----------
# Homebrew (macOS)
if [[ "$SYSTEM" == "macOS" ]]; then
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# Node version manager (nvm)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv &>/dev/null; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

# Deno environment
[ -s "$HOME/.deno/env" ] && . "$HOME/.deno/env"

# UV environment
[ -s "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# ---------- FZF Integration ----------
if [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh

    # Enhanced file search with preview
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview 'cat {}'"

    # Use fd if available for better performance
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
    else
        export FZF_DEFAULT_COMMAND="find . -type f -not -path '*/\.git/*' -not -path '*/node_modules/*'"
    fi
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# ---------- Syntax Highlighting and Autosuggestions ----------
[[ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

[[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# ---------- Tmux Integration ----------
if command -v tmux &>/dev/null && [[ -z "$TMUX" ]]; then
    if [[ $- == *i* ]]; then
        tmux attach -t default || tmux new -s default
    fi
fi

# Tmux workflow aliases
if [ -f ~/.config/tmux/aliases.zsh ]; then
    source ~/.config/tmux/aliases.zsh
fi

# ---------- Load Aliases & Functions ----------
if [ -f ~/.config/zsh/aliases.zsh ]; then
    source ~/.config/zsh/aliases.zsh
fi

# ---------- Load Local Configuration ----------
# Source local settings that shouldn't be committed to git
if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi

# ---------- Starship Prompt ----------
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

# ---------- System Info ----------
if command -v neofetch &>/dev/null; then
    alias sysinfo="neofetch"
fi

# ---------- Welcome Message ----------
echo "Welcome back, $(whoami)! ($SYSTEM)"
echo "Current directory: $(pwd)"
echo "Today is $(date '+%A, %B %d, %Y')"
