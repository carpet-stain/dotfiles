#!/usr/bin/env zsh

set -e

zmodload -m -F zsh/files b:zf_\*

# +-------------+
# | macOS SETUP |
# +-------------+

if [[ $OSTYPE = darwin* ]]; then
    # Check for Command Line Tools
    print "Checking Command Line Tools for Xcode..."
    xcode-select -p &> /dev/null
    if [ $? -ne 0 ]; then
        print "Command Line Tools for Xcode not found. Installing from softwareupdate..."

        # This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
        zf_touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;

        PROD=$(softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')
        softwareupdate -i "$PROD" --verbose;
    else
        print "Command Line Tools for Xcode have been installed."
    fi

    # Check for Homebrew
    if [[ $(command -v brew) == "" ]]; then
        echo "Installing Hombrew"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        print "Homebrew already installed... Skipping"
    fi

    # Install Brewfile packages
    brew bundle --quiet --no-lock
    print "Installing personal packages..."
    brew bundle --quiet --no-lock --file=Brewfile.personal
fi

# +----------------+
# | XDG COMPLIANCE |
# +----------------+

# Get the current path
SCRIPT_DIR=${0:A:h}
cd $SCRIPT_DIR

# Default XDG paths
XDG_CACHE_HOME=$HOME/.cache
XDG_CONFIG_HOME=$HOME/.config
XDG_DATA_HOME=$HOME/.local/share
VIMINIT='let $MYVIMRC="'$SCRIPT_DIR'/nvim/init.lua" | source $MYVIMRC'

# Create required directories 
print "Creating required directory tree..."
zf_mkdir -p $XDG_CONFIG_HOME/{git/local,htop,gnupg,alacritty}
zf_mkdir -p $XDG_CACHE_HOME/{nvim/{backup,swap,undo},zsh}
zf_mkdir -p $XDG_DATA_HOME/{zsh,man/man1,nvim/spell,gnupg,terminfo}
zf_mkdir -p $HOME/{.local/{bin,etc},.ssh}
zf_chmod 700 $XDG_CONFIG_HOME/gnupg
print "  ...done"

# Link zshenv if needed
zf_ln -sf $SCRIPT_DIR/zsh/.zshenv $HOME/.zshenv
print "  ...failed to match this script dir, symlinking .zshenv"

# Link config files
print "Linking config files..."
zf_ln -sf $SCRIPT_DIR/configs/gitconfig $XDG_CONFIG_HOME/git/config
zf_ln -sf $SCRIPT_DIR/configs/gitattributes $XDG_CONFIG_HOME/git/attributes
zf_ln -sf $SCRIPT_DIR/configs/gitignore $XDG_CONFIG_HOME/git/ignore
zf_ln -sf $SCRIPT_DIR/configs/alacritty.yml $XDG_CONFIG_HOME/alacritty/alacritty.yml
zf_ln -sf $SCRIPT_DIR/configs/ssh_config $HOME/.ssh/config
zf_ln -sf $SCRIPT_DIR/configs/batconfig $XDG_CONFIG_HOME/bat/config
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
zf_ln -sf $SCRIPT_DIR/configs/gpg.conf $XDG_CONFIG_HOME/gnupg/gpg.conf
zf_ln -sf $SCRIPT_DIR/configs/gpg-agent.conf $XDG_CONFIG_HOME/gnupg/gpg-agent.conf
print "  ...done"

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
if [[ $OSTYPE = darwin* ]]; then
    /opt/homebrew/opt/ncurses/bin/infocmp -x tmux-256color > ~/tmux-256color.info
    tic -x -o $XDG_DATA_HOME/terminfo ~/tmux-256color.info
    rm -f ~/tmux-256color.info
fi
print "  ...done"
