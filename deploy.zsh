#!/usr/bin/env zsh

set -e

zmodload -m -F zsh/files b:zf_\*

# Get the current path
SCRIPT_DIR="${0:A:h}"
cd "${SCRIPT_DIR}"

# Default XDG paths
XDG_CACHE_HOME="${HOME}/.cache"
XDG_CONFIG_HOME="${HOME}/.config"
XDG_DATA_HOME="${HOME}/.local/share"
VIMINIT='let $MYVIMRC="'${SCRIPT_DIR}'/nvim/init.lua" | source $MYVIMRC'

# Create required directories 
print "Creating required directory tree..."
zf_mkdir -p "${XDG_CONFIG_HOME}"/{git/local,htop,gnupg,alacritty}
zf_mkdir -p "${XDG_CACHE_HOME}"/{nvim/{backup,swap,undo},zsh}
zf_mkdir -p "${XDG_DATA_HOME}"/{zsh,man/man1,nvim/spell,gnupg,terminfo}
zf_mkdir -p "${HOME}"/{.local/{bin,etc},.ssh}
zf_chmod 700 "${XDG_CONFIG_HOME}/gnupg"
print "  ...done"

# Link zshenv if needed
print "Checking for ZDOTDIR env variable..."
if [[ "${ZDOTDIR}" = "${SCRIPT_DIR}/zsh" ]]; then
    print "  ...present and valid, skipping .zshenv symlink"
else
    ln -sf "${SCRIPT_DIR}/zsh/.zshenv" "${ZDOTDIR:-${HOME}}/.zshenv"
    print "  ...failed to match this script dir, symlinking .zshenv"
fi

# Link config files
print "Linking config files..."
zf_ln -sf "${SCRIPT_DIR}/configs/gitconfig" "${XDG_CONFIG_HOME}/git/config"
zf_ln -sf "${SCRIPT_DIR}/configs/gitattributes" "${XDG_CONFIG_HOME}/git/attributes"
zf_ln -sf "${SCRIPT_DIR}/configs/gitignore" "${XDG_CONFIG_HOME}/git/ignore"
zf_ln -sf "${SCRIPT_DIR}/configs/alacritty.yml" "${XDG_CONFIG_HOME}/alacritty/alacritty.yml"
zf_ln -sf "${SCRIPT_DIR}/configs/ssh_config" "${HOME}/.ssh/config"

print "  ...done"

# Make sure submodules are installed
print "Syncing submodules..."
git submodule sync > /dev/null
git submodule update --init --recursive > /dev/null
print "  ...done"

# Install hook to call deploy script after successful pull
print "Installing git hooks..."
zf_mkdir -p .git/hooks
zf_ln -sf ../../deploy.zsh .git/hooks/post-merge
zf_ln -sf ../../deploy.zsh .git/hooks/post-checkout
print "  ...done"

# Link gpg configs to $GNUPGHOME
print "Linking gnupg configs..."
zf_ln -sf "${SCRIPT_DIR}/configs/gpg.conf" "${XDG_CONFIG_HOME}/gnupg/gpg.conf"
zf_ln -sf "${SCRIPT_DIR}/configs/gpg-agent.conf" "${XDG_CONFIG_HOME}/gnupg/gpg-agent.conf"
print "  ...done"

if (( ${+commands[nvim]} )); then
    # Generating vim help tags
    print "Generating nvim helptags..."
    nohup nvim -c 'silent! helptags ALL | q' </dev/null &>/dev/null
    print "  ...done"
fi

# Trigger zsh run with powerlevel10k prompt to download gitstatusd
print "Downloading gitstatusd for powerlevel10k..."
$SHELL -is <<<'' &>/dev/null
print "  ...done"

# Download/refresh TLDR pages
print "Downloading TLDR pages..."
tldr -u &> /dev/null
print "  ...done"

# Generate tmux-256color terminfo
print "Generating tmux-256color.info"
if [[ "${OSTYPE}" = darwin* ]]; then
    /opt/homebrew/opt/ncurses/bin/infocmp tmux-256color > ~/tmux-256color.info
    tic -xe tmux-256color ~/tmux-256color.info
fi
