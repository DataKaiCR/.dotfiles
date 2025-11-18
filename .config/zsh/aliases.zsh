# =============================================================================
#  Aliases & Functions
#  Sourced by .zshrc
# =============================================================================

# ---------- Dotfiles Management ----------
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# ---------- Project Navigation ----------
# Active projects
alias dojo="cd ~/projects/dojo"
alias dkos="cd ~/projects/dkos"
alias dk="cd ~/projects/dk"
alias cert="cd ~/projects/cert-study-platform"
alias bgf="cd ~/projects/boardgamefinder"
alias swarm="cd ~/projects/multi-agent-data-engineering-swarm"
alias llm="cd ~/projects/llm-swarm-engine"

# West Monroe client projects
alias dbx="cd ~/projects/dbx-data-integration-hub"
alias keplr="cd ~/projects/keplrdatabricks"
alias adventure="cd ~/projects/adventure_works"
alias expresspros="cd ~/projects/expresspros-cicd-docs"

# DataKai projects
alias vision="cd ~/projects/datakai-vision"

# Special aliases with env loading
alias dojo-db='cd ~/projects/dojo && source .env && psql -h $DB_HOST -U $DB_USER -d $DB_NAME'

# Common directories
alias pj="cd ~/projects"
alias ak="cd ~/archive"
alias sb="cd ~/scriptorium"
alias cfg="cd ~/.config"

# ---------- Quick Directory Traversal ----------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# ---------- List Directory Contents ----------
if [[ "$SYSTEM" == "macOS" ]]; then
    alias ls="ls -G"
    alias ll="ls -lhG"
    alias la="ls -lahG"
else
    alias ls="ls --color=auto"
    alias ll="ls -lh --color=auto"
    alias la="ls -lah --color=auto"
fi

# ---------- Grep Colors ----------
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"

# ---------- Git Shortcuts ----------
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

# ---------- Editor Shortcuts ----------
alias v="nvim"
alias vi="nvim"
alias vim="nvim"

# ---------- Python Shortcuts ----------
alias py="python3"
alias python="python3"
alias pip="pip3"
alias venv="python3 -m venv venv"
alias activate="source venv/bin/activate"

# ---------- Jupyter Shortcuts ----------
alias jn="jupyter notebook"
alias jl="jupyter lab"

# ---------- Docker Shortcuts ----------
alias d="docker"
alias dc="docker-compose"
alias dps="docker ps"
alias di="docker images"

# ---------- SQL Shortcuts ----------
alias pg="psql -U postgres"

# ---------- System Info ----------
alias meminfo="free -h"
alias cpuinfo="lscpu"
alias diskinfo="df -h"

# ---------- macOS-Specific Aliases ----------
if [[ "$SYSTEM" == "macOS" ]]; then
    alias pbp="pbpaste"
    alias pbc="pbcopy"
    alias o="open"
    alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
    alias showfiles="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"
    alias hidefiles="defaults write com.apple.finder AppleShowAllFiles NO; killall Finder"
    alias mdpreview="brew list grip &>/dev/null || brew install grip; grip -b"
fi

# ---------- Linux-Specific Aliases ----------
if [[ "$SYSTEM" == "Linux" && "$SYSTEM" != "WSL" ]]; then
    command -v xclip >/dev/null && {
        alias pbcopy="xclip -selection clipboard"
        alias pbpaste="xclip -selection clipboard -o"
    }
    alias o="xdg-open"
    alias apt-update="sudo apt update && sudo apt list --upgradable"
    alias apt-upgrade="sudo apt update && sudo apt upgrade -y"
    alias apt-clean="sudo apt autoremove -y && sudo apt clean"
    alias fdisk="sudo fdisk -l"

    if [[ -f /etc/linuxmint/info ]]; then
        alias update-mint="sudo apt update && sudo apt upgrade -y && flatpak update -y"
    fi
fi

# ---------- WSL-Specific Aliases ----------
if [[ "$SYSTEM" == "WSL" ]]; then
    alias cdwin="cd $WINHOME"
    alias explorer="explorer.exe ."
    alias code="code.exe"
    alias clip="clip.exe"
    alias paste="powershell.exe -command 'Get-Clipboard' | tr -d '\r'"
fi

# ---------- Functions ----------

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

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
    if [ ! -d "$HOME/scriptorium/00-inbox" ]; then
        mkdir -p "$HOME/scriptorium/00-inbox"
    fi
    local date=$(date +%Y-%m-%d)
    local note_file="$HOME/scriptorium/00-inbox/$date.md"

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
