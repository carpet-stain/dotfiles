#!/usr/bin/env zsh

set -e

# Load Zsh modules for managing files
zmodload -m -F zsh/files b:zf_rm b:zf_ln b:zf_mkdir

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

# Function to create required directories
create_directories() {
  print "Creating required directory tree..."
  zf_mkdir -p $XDG_CONFIG_HOME/{bat/themes,git,htop,alacritty,ripgrep,tealdeer,fsh,homebrew}
  zf_mkdir -p $XDG_CACHE_HOME/{nvim,zsh,tmux,direnv,git,bat,ripgrep,eza,fonts,icons,tealdear,zsh-abbr,zoxide}
  zf_mkdir -p $XDG_DATA_HOME/{zsh,nvim,terminfo,man,ssh,bat,direnv,fzf/history,pip,tmux,git,eza,tealdear,zoxide}
  zf_mkdir -p $XDG_STATE_HOME/zsh/{history}
  zf_mkdir -p $HOME/.ssh
  print "  ...done"
}

# Function to link config files
link_configs() {
  print "Linking config files..."

  # Git related files
  zf_ln -sf $DOTFILES_DIR/zsh/.zshenv $HOME/.zshenv
  zf_ln -sf $DOTFILES_DIR/theme/zsh-fsh/themes/catppuccin-mocha.ini $XDG_CONFIG_HOME/fsh/catppuccin-mocha.ini
  zf_ln -sf $DOTFILES_DIR/alacritty.toml $XDG_CONFIG_HOME/alacritty/alacritty.toml
  zf_ln -sf $DOTFILES_DIR/theme/alacritty/catppuccin-mocha.toml $XDG_CONFIG_HOME/alacritty/catppuccin-mocha.toml
  zf_ln -sf $DOTFILES_DIR/htoprc $XDG_CONFIG_HOME/htop/htoprc
  zf_ln -sf $DOTFILES_DIR/theme/btop/themes/catppuccin_mocha.theme $XDG_CONFIG_HOME/btop/themes/catppuccin_mocha.theme
  zf_ln -sf $DOTFILES_DIR/batconfig $XDG_CONFIG_HOME/bat/config
  zf_ln -sf $DOTFILES_DIR/theme/bat/themes/Catppuccin\ Mocha.tmTheme $XDG_CONFIG_HOME/bat/themes/Catppuccin\ Mocha.tmTheme
  zf_ln -sf $DOTFILES_DIR/git/attributes $XDG_CONFIG_HOME/git/attributes
  zf_ln -sf $DOTFILES_DIR/git/committemplate $XDG_CONFIG_HOME/git/committemplate
  zf_ln -sf $DOTFILES_DIR/git/config $XDG_CONFIG_HOME/git/config
  zf_ln -sf $DOTFILES_DIR/git/ignore $XDG_CONFIG_HOME/git/ignore
  zf_ln -sf $DOTFILES_DIR/theme/delta/catppuccin.gitconfig $XDG_CONFIG_HOME/git/catppuccin.gitconfig
  zf_ln -sf $DOTFILES_DIR/ripgreprc $XDG_CONFIG_HOME/ripgrep/config
  zf_ln -sf $DOTFILES_DIR/curlrc $XDG_CONFIG_HOME/curlrc
  zf_ln -sf $DOTFILES_DIR/tealdeerconfig.toml $XDG_CONFIG_HOME/tealdeer/config.toml
  zf_ln -sf $DOTFILES_DIR/fzfrc $XDG_CONFIG_HOME/fzfrc
  zf_ln -sf $DEPLOY_DIR/brew.env $XDG_CONFIG_HOME/homebrew/brew.env
  zf_ln -sf $DEPLOY_DIR/Brewfile $XDG_CONFIG_HOME/homebrew/Brewfile

  # SSH config
  cp $DOTFILES_DIR/sshconfig $HOME/.ssh/config
  print "  ...done"
}

# +----------+
# | Homebrew |
# +----------+

# Check for Homebrew
install_homebrew() {
  if [[ -z $(command -v brew) ]]; then
    print "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    print "Homebrew already installed... Skipping"
  fi
}

# Install Brewfile packages
install_brewfile() {
  print "Installing Brewfile packages..."
  eval "$(brew shellenv)"
  brew bundle --file=$DEPLOY_DIR/Brewfile
}

# Sync Git submodules
sync_submodules() {
  print "Syncing submodules..."
  git submodule sync > /dev/null
  git submodule update --init --recursive > /dev/null
  print "  ...done"
}

# Trigger zsh run to download gitstatusd
download_gitstatusd() {
  print "Downloading gitstatusd for powerlevel10k..."
  $SHELL -is <<<'' &>/dev/null
  print "  ...done"
}

# Refresh TLDR pages
refresh_tldr() {
  print "Downloading TLDR pages..."
  tldr -u &>/dev/null
  print "  ...done"
}

# Rebuild bat cache
rebuild_bat_cache() {
  print "Rebuilding bat cache..."
  bat cache --build &>/dev/null
  print "  ...done"
}

# Generate tmux-256color terminfo
generate_tmux_terminfo() {
  print "Generating tmux-256color.info..."
  $HOMEBREW_PREFIX/opt/ncurses/bin/infocmp -x tmux-256color > ~/tmux-256color.info
  tic -x -o $XDG_DATA_HOME/terminfo ~/tmux-256color.info
  zf_rm -f ~/tmux-256color.info
  print "  ...done"
}

# Execute functions
create_directories
link_configs
install_homebrew
install_brewfile
sync_submodules
download_gitstatusd
refresh_tldr
rebuild_bat_cache
generate_tmux_terminfo
