# =============================================================================
#  Enhanced Cross-Platform .zshrc for Data Engineering & Development
#  No frameworks - just pure Zsh optimized for performance
# =============================================================================

# ---------- Environment Detection ----------
# More robust OS detection
case "$(uname -s)" in
    Linux*)     export SYSTEM="Linux";;
    Darwin*)    export SYSTEM="macOS";;
    CYGWIN*)    export SYSTEM="Windows";;
    MINGW*)     export SYSTEM="Windows";;
    *)          export SYSTEM="Unknown";;
esac

# Enhanced WSL detection (more reliable)
if [[ -f /proc/version ]]; then
    if grep -q "Microsoft" /proc/version || grep -q "WSL" /proc/version; then
        export SYSTEM="WSL"
        # Extract Windows username for later use
        export WINDOWS_USERNAME=$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r\n')
    fi
fi

# ---------- Zsh-specific Settings ----------
# Load colors for prompt and syntax
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

# ---------- Dotfiles Management ----------
# Set up dotfiles path and alias (using bare repository approach)
alias dotfiles="git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"

# ---------- Shell Configuration ----------
# Set default editor
export EDITOR='nvim'
export VISUAL='nvim'

# ---------- Color Configuration ----------
# Enable color support
if [[ "$SYSTEM" == "macOS" ]]; then
    export CLICOLOR=1
    export LSCOLORS=ExFxBxDxCxegedabagacad
else
    alias ls='ls --color=auto'
fi

# Git info in prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '[%b]'

# Set prompt
if [[ "$SYSTEM" == "WSL" ]]; then
    # WSL prompt with Windows username
    PROMPT="%{$fg[cyan]%}%n%{$reset_color%}@%{$fg[green]%}WSL(%{$fg[yellow]%}$WINDOWS_USERNAME%{$fg[green]%})%{$reset_color%}:%{$fg[blue]%}%~%{$reset_color%}"
    PROMPT+=' %{$fg[yellow]%}${vcs_info_msg_0_}%{$reset_color%}'
    PROMPT+=$'\n❯ '
else
    # Standard prompt for other systems
    PROMPT="%{$fg[cyan]%}%n%{$reset_color%}@%{$fg[green]%}%m%{$reset_color%}:%{$fg[blue]%}%~%{$reset_color%}"
    PROMPT+=' %{$fg[yellow]%}${vcs_info_msg_0_}%{$reset_color%}'
    PROMPT+=$'\n❯ '
fi

# ---------- Navigation Aliases ----------
# Core directory shortcuts
if [[ "$SYSTEM" == "WSL" ]]; then
    # Windows paths (faster than OneDrive)
    WIN_USER_DIR="/mnt/c/Users/$WINDOWS_USERNAME"
    alias wh="cd $WIN_USER_DIR"
    alias lh="cd $HOME"
    alias ws="cd $HOME/workspace"
    alias res="cd $HOME/resources"
    alias brain="cd $HOME/second-brain"
    alias pers="cd $HOME/personal"
    alias dl="cd $HOME/downloads"
    alias dat="cd $HOME/data"
    alias scr="cd $HOME/scripts"
    alias arch="cd $HOME/archives"
    
    # OneDrive backup shortcuts if applicable
    if [[ -d "$WIN_USER_DIR/OneDrive - West Monroe" ]]; then
        ONEDRIVE_DIR="$WIN_USER_DIR/OneDrive - West Monroe"
        alias wsod="cd \"$ONEDRIVE_DIR/workspace\""
        alias resod="cd \"$ONEDRIVE_DIR/resources\""
        alias brainod="cd \"$ONEDRIVE_DIR/second-brain\""
        alias datod="cd \"$ONEDRIVE_DIR/data\""
        alias archod="cd \"$ONEDRIVE_DIR/archives\""
        
        # Sync to OneDrive alias
        if [[ -f "$HOME/scripts/sync-to-onedrive.sh" ]]; then
            alias syncod="$HOME/scripts/sync-to-onedrive.sh"
        fi
    fi
else
    # Regular paths for macOS and Linux Mint
    alias ws="cd $HOME/workspace"
    alias pj="cd $HOME/projects"
    alias rs="cd $HOME/resources"
    alias br="cd $HOME/second-brain"
    alias ps="cd $HOME/personal"
    alias dl="cd $HOME/downloads"
    alias dt="cd $HOME/data"
    alias sc="cd $HOME/scripts"
    alias ak="cd $HOME/archives"
fi

# Custom projects
alias pjtl="cd $HOME/projects/trulieve"

# Quick directory traversal
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# List directory contents
if [[ "$SYSTEM" == "macOS" ]]; then
    alias ls="ls -G"
    alias ll="ls -lhG"
    alias la="ls -lahG"
else
    alias ls="ls --color=auto"
    alias ll="ls -lh --color=auto"
    alias la="ls -lah --color=auto"
fi

# grep colors
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"

# ---------- Development Tools ----------
# Git shortcuts
alias g="git"
alias ga="git add"
alias gc="git commit"
alias gco="git checkout"
alias gp="git push"
alias gl="git pull"
alias gs="git status"
alias gd="git diff"
alias gb="git branch"
alias glog="git log --oneline --graph --decorate"

# Dotfiles shortcuts
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Neovim shortcuts
alias v="nvim"
alias vi="nvim"
alias vim="nvim"

# Easier directory creation
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# ---------- Data Engineering Tools ----------
# Python environment
alias py="python3"
alias python="python3"
alias pip="pip3"

# Virtual environment
alias venv="python3 -m venv venv"
alias activate="source venv/bin/activate"

# Jupyter shortcuts
alias jn="jupyter notebook"
alias jl="jupyter lab"

# Docker shortcuts
alias d="docker"
alias dc="docker-compose"
alias dps="docker ps"
alias di="docker images"

# SQL shortcuts
alias pg="psql -U postgres"

# ---------- System Operations ----------
# System info
alias meminfo="free -h"
alias cpuinfo="lscpu"
alias diskinfo="df -h"

# Update system (cross-platform)
update() {
    if [[ "$SYSTEM" == "Linux" || "$SYSTEM" == "WSL" ]]; then
        sudo apt update && sudo apt upgrade -y
    elif [[ "$SYSTEM" == "macOS" ]]; then
        brew update && brew upgrade
    fi
}

# Search file contents
ff() { 
    find . -type f -not -path "*/\.*" -not -path "*/venv/*" -not -path "*/node_modules/*" -exec grep -l "$1" {} \;
}

# Search for files
fn() {
    find . -type f -name "*$1*" -not -path "*/\.*" -not -path "*/venv/*" -not -path "*/node_modules/*"
}

# Kill process on port
killport() {
    if [[ "$SYSTEM" == "macOS" ]]; then
        lsof -i tcp:$1 | awk 'NR!=1 {print $2}' | xargs kill
    else
        fuser -k $1/tcp
    fi
}

# ---------- File Operations ----------
# Create a backup of a file
bak() {
    cp "$1" "$1.bak"
}

# Extract various archive types
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# ---------- Workflow Helpers ----------
# Create a new project directory with common subdirectories
newproject() {
    mkdir -p "$1"/{src,docs,tests,data,notebooks}
    touch "$1/README.md"
    cd "$1"
    echo "# $1" > README.md
    echo "Project $1 created with standard directories"
}

# Start a quick Python environment
pyinit() {
    python3 -m venv venv
    source venv/bin/activate
    pip install ipython jupyter pandas numpy matplotlib seaborn scikit-learn
    echo "Python environment initialized with common data science packages"
}

# Quick notes
note() {
    if [ ! -d "$HOME/second-brain/daily" ]; then
        mkdir -p "$HOME/second-brain/daily"
    fi
    local date=$(date +%Y-%m-%d)
    local note_file="$HOME/second-brain/daily/$date.md"
    
    if [ ! -f "$note_file" ]; then
        echo "# Notes for $date" > "$note_file"
        echo "" >> "$note_file"
    fi
    
    if [ "$1" ]; then
        echo "- $(date +%H:%M): $*" >> "$note_file"
        echo "Note added"
    else
        $EDITOR "$note_file"
    fi
}

# Use NeoFetch if available
if command -v neofetch &> /dev/null; then
    alias sysinfo="neofetch"
fi

# ---------- System-Specific Configurations ----------
# WSL-specific settings
if [[ "$SYSTEM" == "WSL" ]]; then
    # Fix interop issue with Windows
    export BROWSER="wslview"
    
    # Access Windows home directory
    export WINHOME="/mnt/c/Users/$WINDOWS_USERNAME"
    alias cdwin="cd $WINHOME"
    
    # Open Windows Explorer in current directory
    alias explorer="explorer.exe ."
    
    # Windows integration for common apps
    alias code="code.exe"
    
    # Clipboard
    alias clip="clip.exe"
    alias paste="powershell.exe -command 'Get-Clipboard' | tr -d '\r'"
fi

# macOS-specific settings
if [[ "$SYSTEM" == "macOS" ]]; then
    # Homebrew Path Settings
    if [[ -f /opt/homebrew/bin/brew ]]; then
        # Apple Silicon Mac
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        # Intel Mac
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    # macOS clipboard interaction
    alias pbp="pbpaste"
    alias pbc="pbcopy"
    
    # Open files with default app
    alias o="open"
    
    # Flush DNS cache
    alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
    
    # Show/hide hidden files
    alias showfiles="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"
    alias hidefiles="defaults write com.apple.finder AppleShowAllFiles NO; killall Finder"
    
    # Preview markdown files
    alias mdpreview="brew list grip &>/dev/null || brew install grip; grip -b"
fi

# Linux-specific settings
if [[ "$SYSTEM" == "Linux" && "$SYSTEM" != "WSL" ]]; then
    # Clipboard interaction (requires xclip)
    command -v xclip >/dev/null && {
        alias pbcopy="xclip -selection clipboard"
        alias pbpaste="xclip -selection clipboard -o"
    }
    
    # Open files with default app
    alias o="xdg-open"
    
    # Linux system commands
    alias apt-update="sudo apt update && sudo apt list --upgradable"
    alias apt-upgrade="sudo apt update && sudo apt upgrade -y"
    alias apt-clean="sudo apt autoremove -y && sudo apt clean"
    alias fdisk="sudo fdisk -l"
    
    # If on Linux Mint specifically
    if [[ -f /etc/linuxmint/info ]]; then
        alias update-mint="sudo apt update && sudo apt upgrade -y && flatpak update -y"
    fi
fi

# ---------- Path Configurations ----------
# Add local bin directories to PATH
export PATH="$PATH:/usr/local/bin"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/scripts:$PATH"
export PATH="$HOME/bin:$PATH"

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

# Node version manager (nvm) setup
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ---------- Terminal Integration ----------
# Integrate with Wezterm if available
if [[ -n "$WEZTERM_PANE" ]]; then
    # Wezterm specific configurations
    bindkey -s '^W' '\C-a\C-k\C-u wezterm cli split-pane\n'
fi

# ---------- FZF Integration ----------
# Set up fzf if installed
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
    
    # Navigate to directory with fzf
    fcd() {
        local dir
        dir=$(find ${1:-.} -path '*/\.*' -prune -o -type d -print 2> /dev/null | fzf +m) && cd "$dir"
    }
    
    # Edit file with fzf
    fvim() {
        local file
        file=$(fzf --preview 'cat {}') && nvim "$file"
    }
    
    # Git commit browser
    fcommit() {
        git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" | \
        fzf --ansi --no-sort --reverse --tiebreak=index --preview \
        'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1; }; f {}' \
        --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
                FZF-EOF"
    }
fi

# ---------- Load Local Configuration ----------
# Source local settings that shouldn't be committed to git
if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi

# ---------- Syntax Highlighting and Autosuggestions ----------
# Simple plugin loading without Oh My Zsh
# Only load if the plugins exist
[[ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

[[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# ---------- Tmux Integration ----------
# Automatically start tmux if not already running
if command -v tmux &>/dev/null && [[ -z "$TMUX" ]]; then
    # Only start tmux in interactive shells and if not already in tmux
    if [[ $- == *i* ]]; then
        # If tmux is detached, attach to it, otherwise create a new session
        tmux attach -t default || tmux new -s default
    fi
fi

# Starship prompt integration
eval "$(starship init zsh)"

# ---------- Welcome Message ----------
echo "Welcome back, $(whoami)! ($SYSTEM)"
echo "Current directory: $(pwd)"
echo "Today is $(date '+%A, %B %d, %Y')"
. "/Users/hstecher/.deno/env"


