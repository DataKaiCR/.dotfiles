#!/bin/bash
# ~/.bash_profile: executed by the command interpreter for login shells.

# Source global definitions
if [ -f /etc/profile ]; then
    . /etc/profile
fi

# Include .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

# Set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# Set PATH so it includes user's private .local/bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Environment variables for XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# Ensure SSH agent is running
if [ -z "$SSH_AUTH_SOCK" ] ; then
    eval "$(ssh-agent -s)" > /dev/null
fi
. "/home/wmhstecher/.deno/env"