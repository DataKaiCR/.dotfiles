# =============================================================================
#  Enhanced Cross-Platform .zshrc for Data Engineering & Development
# =============================================================================

# ---------- Environment Detection ----------
# Determine OS type and set variables accordingly
case "$(uname -s)" in
    Linux*)     SYSTEM="Linux";;
    Darwin*)    SYSTEM="macOS";;
    CYGWIN*)    SYSTEM="Windows";;
    MINGW*)     SYSTEM="Windows";;
    *)          SYSTEM="Unknown";;
esac

# Check if running in WSL
if [[ -f /proc/version ]] && grep -q Microsoft /proc/version; then
    SYSTEM="WSL"
fi

# ---------- Zsh-specific Settings ----------
# Load colors
autoload -U colors && colors

# Configure history
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# Enable auto-completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Enable vi mode
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

# Set default editor
export EDITOR='nvim'
export VISUAL='nvim'

# ---------- Dotfiles Management ----------
# Set up dotfiles path and alias (using bare repository approach)
alias dotfiles="git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"

# ---------- Prompt Configuration ----------
# Git info in prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '[%b]'

# Set prompt
PROMPT='%F{cyan}%n%f@%F{green}%m%f:%F{blue}%~%f %F{yellow}${vcs_info_msg_0_}%f
❯ '

# ---------- Navigation Aliases ----------
# Core directory shortcuts
alias ws="cd $HOME/workspace"
alias res="cd $HOME/resources"
alias brain="cd $HOME/second-brain"
alias pers="cd $HOME/personal"
alias dl="cd $HOME/downloads"
alias dat="cd $HOME/data"
alias scr="cd $HOME/scripts"
alias arch="cd $HOME/archives"

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
    if [[ "$SYSTEM" == "Linux" ]]; then
        sudo apt update && sudo apt upgrade -y
    elif [[ "$SYSTEM" == "macOS" ]]; then
        brew update && brew upgrade
    elif [[ "$SYSTEM" == "WSL" ]]; then
        sudo apt update && sudo apt upgrade -y
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
    lsof -i tcp:$1 | awk 'NR!=1 {print $2}' | xargs kill
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

# ---------- System-Specific Configurations ----------
# macOS-specific settings
if [[ "$SYSTEM" == "macOS" ]]; then
    # Homebrew path
    export PATH="/opt/homebrew/bin:$PATH"
    
    # macOS clipboard interaction
    alias pbp="pbpaste"
    alias pbc="pbcopy"
    
    # Open files with default app
    alias o="open"
    
    # Flush DNS cache
    alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
fi

# Linux-specific settings
if [[ "$SYSTEM" == "Linux" && "$SYSTEM" != "WSL" ]]; then
    # Clipboard interaction (requires xclip)
    alias pbcopy="xclip -selection clipboard"
    alias pbpaste="xclip -selection clipboard -o"
    
    # Open files with default app
    alias o="xdg-open"
fi

# WSL-specific settings
if [[ "$SYSTEM" == "WSL" ]]; then
    # Fix interop issue with Windows
    export BROWSER="wslview"
    
    # Access Windows home directory
    export WINHOME="/mnt/c/Users/$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r')"
    alias cdwin="cd $WINHOME"
    
    # Open Windows Explorer in current directory
    alias explorer="explorer.exe ."
    
    # Windows integration for common apps
    alias code="code.exe"
    
    # Windows paths (faster than OneDrive)
    WIN_USER_DIR="/mnt/c/Users/hstecher"
    alias wh="cd $WIN_USER_DIR"
    alias lh="cd $HOME"
    
    # OneDrive backup shortcuts
    ONEDRIVE_DIR="$WIN_USER_DIR/OneDrive - West Monroe"
    alias wsod="cd \"$ONEDRIVE_DIR/workspace\""
    alias resod="cd \"$ONEDRIVE_DIR/resources\""
    alias brainod="cd \"$ONEDRIVE_DIR/second-brain\""
    alias datod="cd \"$ONEDRIVE_DIR/data\""
    alias archod="cd \"$ONEDRIVE_DIR/archives\""
    
    # Sync to OneDrive alias
    alias syncod="$HOME/scripts/sync-to-onedrive.sh"
fi

# ---------- Path Configurations ----------
# Add local bin directories to PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/scripts:$PATH"

# ---------- Load Local Configuration ----------
# Source local settings that shouldn't be committed to git
if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi

# ---------- Optional Plugin Management ----------
# Check for Homebrew zsh plugins
if [[ "$SYSTEM" == "macOS" ]]; then
    # Check for zsh-syntax-highlighting
    if [ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
        source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    fi
    
    # Check for zsh-autosuggestions
    if [ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
        source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    fi
fi

# Welcome message
echo "Welcome back, $(whoami)! ($SYSTEM)"
echo "Current directory: $(pwd)"
echo "Today is $(date '+%A, %B %d, %Y')"

# Automatically start tmux if not already running
if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    # Only start tmux in interactive shells
    case $- in
        *i*)
            # Don't nest tmux sessions
            if [ -z "$TMUX" ]; then
                # Attach to existing session or create a new one
                tmux attach || tmux
            fi
            ;;
    esac
fi
