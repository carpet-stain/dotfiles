#!/usr/bin/env zsh

set -e

# Load Zsh modules for managing files
zmodload -m -F zsh/files b:zf_ln b:zf_mkdir

# +----------------+
# | XDG COMPLIANCE |
# +----------------+

# Get the current script directory
DEPLOY_DIR=$(dirname $(realpath $0))
DOTFILES_DIR=$DEPLOY_DIR:h

# Default XDG paths
XDG_CACHE_HOME=$HOME/.cache
XDG_CONFIG_HOME=$HOME/.config
XDG_DATA_HOME=$HOME/.local/share
XDG_STATE_HOME=$HOME/.local/state

# XDG_RUNTIME_DIR is for non-persistent, temporary files (like sockets).
# On macOS, the system-provided $TMPDIR is the correct, secure,
# and non-persistent location to use.
XDG_RUNTIME_DIR=$TMPDIR

# Function to create required directories
create_directories() {
  print "Creating required directory tree..."
  zf_mkdir -p $XDG_CONFIG_HOME/{bat,direnv,git,htop,alacritty,ripgrep,tealdeer,fsh,homebrew,nvim}
  zf_mkdir -p $XDG_CACHE_HOME/{nvim,zsh,tmux,direnv,git,bat,ripgrep,eza,fonts,icons,tealdeer,zsh-abbr,zoxide}
  zf_mkdir -p $XDG_DATA_HOME/{zsh,nvim,terminfo,man,ssh,bat,direnv,fzf/history,pip,tmux,git,eza,tealdeer,zoxide}
  zf_mkdir -p $XDG_STATE_HOME/zsh/{history}
  zf_mkdir -p $XDG_RUNTIME_DIR/Homebrew
  zf_mkdir -p $HOME/.ssh
  print "  ...done"
}

# Symlink config files
link_configs() {
  print "Linking config files..."

  zf_ln -sf $DOTFILES_DIR/zsh/.zshenv $HOME/.zshenv
  zf_ln -sf $DOTFILES_DIR/theme/zsh-fsh/themes/catppuccin-mocha.ini $XDG_CONFIG_HOME/fsh/catppuccin-mocha.ini

  zf_ln -sf $DOTFILES_DIR/nvim/init.lua $XDG_CONFIG_HOME/nvim/init.lua
  zf_ln -sfn $DOTFILES_DIR/nvim/lua $XDG_CONFIG_HOME/nvim/lua

  zf_ln -sf $DOTFILES_DIR/alacritty.toml $XDG_CONFIG_HOME/alacritty/alacritty.toml
  zf_ln -sf $DOTFILES_DIR/theme/alacritty/catppuccin-mocha.toml $XDG_CONFIG_HOME/alacritty/catppuccin-mocha.toml

  zf_ln -sf $DOTFILES_DIR/htoprc $XDG_CONFIG_HOME/htop/htoprc

  zf_ln -sf $DOTFILES_DIR/batconfig $XDG_CONFIG_HOME/bat/config

  zf_ln -sf $DOTFILES_DIR/git/attributes $XDG_CONFIG_HOME/git/attributes
  zf_ln -sf $DOTFILES_DIR/git/committemplate $XDG_CONFIG_HOME/git/committemplate
  zf_ln -sf $DOTFILES_DIR/git/config $XDG_CONFIG_HOME/git/config
  zf_ln -sf $DOTFILES_DIR/git/ignore $XDG_CONFIG_HOME/git/ignore
  zf_ln -sf $DOTFILES_DIR/theme/delta/catppuccin.gitconfig $XDG_CONFIG_HOME/git/catppuccin.gitconfig

  zf_ln -sf $DOTFILES_DIR/ripgreprc $XDG_CONFIG_HOME/ripgrep/config
  zf_ln -sf $DOTFILES_DIR/curlrc $XDG_CONFIG_HOME/curlrc
  zf_ln -sf $DOTFILES_DIR/tealdeerconfig.toml $XDG_CONFIG_HOME/tealdeer/config.toml

  zf_ln -sf $DEPLOY_DIR/brew.env $XDG_CONFIG_HOME/homebrew/brew.env
  zf_ln -sf $DEPLOY_DIR/Brewfile $XDG_CONFIG_HOME/homebrew/Brewfile

  # SSH config. I don't want to symlink this, just merely copy.
  cp "$DOTFILES_DIR/sshconfig" "$HOME/.ssh/config"
  print "...done\n"
}

# +----------+
# | Homebrew |
# +----------+

# Check for Homebrew
install_homebrew() {
  if [[ -z $(command -v brew) ]]; then
    print "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    print "Homebrew already installed... Skipping"
  fi
}

# Install Brewfile packages
install_brewfile() {
  print "Installing Brewfile packages..."
  # brew bundle --file=$DEPLOY_DIR/Brewfile
}

# Sync Git submodules
sync_submodules() {
  print "Syncing submodules..."
  git submodule sync > /dev/null
  git submodule update --init --recursive > /dev/null
  print "...done\n"
}

# Trigger zsh run to download gitstatusd
download_gitstatusd() {
  print "Downloading gitstatusd for powerlevel10k..."
  $SHELL -is <<< '' &> /dev/null
  print "...done\n"
}

set_fsh() {
  print "Setting fast-syntax-highlighting theme..."
  $SHELL -is <<< 'fast-theme -q XDG:catppuccin-mocha' &> /dev/null
  print "...done\n"
}

# Refresh TLDR pages
refresh_tldr() {
  print "Downloading TLDR pages..."
  tldr -u &> /dev/null
  print "...done\n"
}

# Generate tmux-256color terminfo
generate_tmux_terminfo() {
  print "Generating tmux-256color.info..."
  $HOMEBREW_PREFIX/opt/ncurses/bin/infocmp -x tmux-256color | tic -x -o "$XDG_DATA_HOME/terminfo" -
  print "  ...done\n"
}

set_neovim() {
  # Launch nvim to trigger Lazy and download plugins
  print "Downloading Neovim plugins and generating help tags..."
  command nvim --headless -c "helptags ALL" -c "qall" &> /dev/null

  # Launch Neovim and install Mason dependancies
  print "Installing LSP servers/tools..."
  # NOTE: `MasonInstallAll` isn't a neovim builtin.
  # It's a user command declared in:  './nvim/lua/conf/lang/mason.lua'
  command nvim --headless -c "MasonInstallAll" -c "qall" &> /dev/null
  print "...done\n"
}

# Execute functions
create_directories
link_configs
install_homebrew
install_brewfile
sync_submodules
download_gitstatusd
set_fsh
refresh_tldr
generate_tmux_terminfo
set_neovim