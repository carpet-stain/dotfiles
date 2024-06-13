#!/usr/bin/env zsh

set -e

zmodload -m -F zsh/files b:zf_\*

# +-------------+
# | macOS SETUP |
# +-------------+

# Check for Homebrew
if [[ $(command -v brew) == "" ]]; then
	echo "Installing Hombrew"
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
	print "Homebrew already installed... Skipping"
fi

# Install Brewfile packages
eval "$(brew shellenv)"
export HOMEBREW_PREFIX=/opt/homebrew
export HOMEBREW_VERBOSE_USING_DOTS=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_CASK_OPTS=--require-sha
brew bundle --quiet --no-lock --file=Brewfile
# print "Installing personal packages..."
# brew bundle --quiet --no-lock --file=Brewfile.personal

# +----------------+
# | XDG COMPLIANCE |
# +----------------+

# Get the current path
DEPLOY_DIR=${0:A:h}
SCRIPT_DIR=$DEPLOY_DIR:h
cd $SCRIPT_DIR

# Default XDG paths
XDG_CACHE_HOME=$HOME/.cache
XDG_CONFIG_HOME=$HOME/.config
XDG_DATA_HOME=$HOME/.local/share
XDG_STATE_HOME=$HOME/.local/state

# Create required directories
print "Creating required directory tree..."
zf_mkdir -p $XDG_CONFIG_HOME/{git,htop,gnupg,alacritty,bat}
zf_chmod 700 $XDG_CONFIG_HOME/gnupg
zf_mkdir -p $XDG_CACHE_HOME/{nvim,zsh}
zf_mkdir -p $XDG_DATA_HOME/{{goenv,pyenv,nodenv},zsh,nvim,gnupg,terminfo}
zf_mkdir -p $XDG_STATE_HOME/zsh
zf_mkdir -p $HOME/.ssh
print "  ...done"

# Link config files
print "Linking config files..."
zf_ln -sf $SCRIPT_DIR/zsh/.zshenv $HOME/.zshenv
zf_ln -sf $SCRIPT_DIR/alacritty.yml $XDG_CONFIG_HOME/alacritty/alacritty.yml
zf_ln -sf $SCRIPT_DIR/batconfig $XDG_CONFIG_HOME/bat/config
zf_ln -sf $SCRIPT_DIR/curlrc $XDG_CONFIG_HOME/curlrc
zf_ln -sf $SCRIPT_DIR/git/attributes $XDG_CONFIG_HOME/git/attributes
zf_ln -sf $SCRIPT_DIR/git/committemplate $XDG_CONFIG_HOME/git/committemplate
zf_ln -sf $SCRIPT_DIR/git/config $XDG_CONFIG_HOME/git/config
zf_ln -sf $SCRIPT_DIR/git/ignore $XDG_CONFIG_HOME/git/ignore
zf_ln -sf $SCRIPT_DIR/gpg-agent.conf $XDG_CONFIG_HOME/gnupg/gpg-agent.conf
zf_ln -sf $SCRIPT_DIR/gpg.conf $XDG_CONFIG_HOME/gnupg/gpg.conf
zf_ln -sf $SCRIPT_DIR/htoprc $XDG_CONFIG_HOME/htop/htoprc
cp $SCRIPT_DIR/sshconfig $HOME/.ssh/config
print "  ...done"

# Make sure submodules are installed
print "Syncing submodules..."
git submodule sync >/dev/null
git submodule update --init --recursive >/dev/null
print "  ...done"

# Trigger zsh run with powerlevel10k prompt to download gitstatusd
print "Downloading gitstatusd for powerlevel10k..."
$SHELL -is <<<'' &>/dev/null
print "  ...done"

# Download/refresh TLDR pages
print "Downloading TLDR pages..."
tldr -u &>/dev/null
print "  ...done"

# Generate tmux-256color terminfo
print "Generating tmux-256color.info"
if [[ $OSTYPE = darwin* ]]; then
	$HOMEBREW_PREFIX/opt/ncurses/bin/infocmp -x tmux-256color >~/tmux-256color.info
	tic -x -o $XDG_DATA_HOME/terminfo ~/tmux-256color.info
	zf_rm -f ~/tmux-256color.info
fi
print "  ...done"
