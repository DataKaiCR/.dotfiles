# Tmux Workflow Aliases
# Source this in your .zshrc: source ~/.config/tmux/aliases.zsh

# Sessionizer - THE most important alias
alias tf='tmux-sessionizer'
alias tsetup='tmux-project-setup'  # Setup project with layout

# Tmux session management
alias tls='tmux ls'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tk='tmux kill-session -t'
alias tkill='tmux kill-server'  # Nuclear option - kills all sessions

# Tmux resurrect shortcuts
alias tsave='tmux run-shell ~/.config/tmux/plugins/tmux-resurrect/scripts/save.sh'
alias trestore='tmux run-shell ~/.config/tmux/plugins/tmux-resurrect/scripts/restore.sh'

# Development session launchers (creates or attaches)
tdev() {
    local session="${1:-dev}"
    if tmux has-session -t "$session" 2>/dev/null; then
        tmux attach -t "$session"
    else
        tmux new -s "$session"
    fi
}

# Quick switch to named session (from within tmux)
ts() {
    if [ -z "$1" ]; then
        tmux choose-session
    else
        if [ -n "$TMUX" ]; then
            tmux switch-client -t "$1" 2>/dev/null || echo "Session '$1' not found. Use 'tf' to create it."
        else
            tmux attach -t "$1" 2>/dev/null || echo "Session '$1' not found. Use 'tf' to create it."
        fi
    fi
}

# List all git projects
tprojects() {
    echo "📦 All Git Projects:\n"
    find ~/projects -name ".git" -type d 2>/dev/null | sed 's|/.git||' | sed "s|$HOME/projects/||" | sort
}
