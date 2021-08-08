#!/usr/bin/env zsh

set -e

# Get the current path
SCRIPT_DIR="${0:A:h}"
cd "${SCRIPT_DIR}"

# Default XDG paths
XDG_CACHE_HOME="${HOME}/.cache"
XDG_CONFIG_HOME="${HOME}/.config"
XDG_DATA_HOME="${HOME}/.local/share"
VIMINIT='let $MYVIMRC="'${SCRIPT_DIR}'/vim/vimrc" | source $MYVIMRC'

# Create required directories
print "Creating required directory tree..."
mkdir -p "${XDG_CONFIG_HOME}"/git/local
mkdir -p "${XDG_CACHE_HOME}"/{vim/{backup,swap,undo},zsh}
mkdir -p "${XDG_DATA_HOME}"/{{goenv,nodenv}/plugins,zsh,man/man1}
mkdir -p "${HOME}"/.local/{bin,etc}
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
ln -sf "${SCRIPT_DIR}/configs/gitconfig" "${XDG_CONFIG_HOME}/git/config"
ln -sf "${SCRIPT_DIR}/configs/gitattributes" "${XDG_CONFIG_HOME}/git/attributes"
ln -sf "${SCRIPT_DIR}/configs/gitignore" "${XDG_CONFIG_HOME}/git/ignore"
ln -sf "${SCRIPT_DIR}/configs/mc.ini" "${XDG_CONFIG_HOME}/mc/ini"
ln -sf "${SCRIPT_DIR}/configs/htoprc" "${XDG_CONFIG_HOME}/htop/htoprc"
ln -sf "${SCRIPT_DIR}/configs/ranger" "${XDG_CONFIG_HOME}/ranger/rc.conf"
ln -sf "${SCRIPT_DIR}/configs/gemrc" "${XDG_CONFIG_HOME}/gem/gemrc"
ln -snf "${SCRIPT_DIR}/configs/ranger-plugins" "${XDG_CONFIG_HOME}/ranger/plugins"
print "  ...done"

# Make sure submodules are installed
print "Syncing submodules..."
git submodule sync > /dev/null
git submodule update --init --recursive > /dev/null
git clean -ffd
print "  ...done"

# Install hook to call deploy script after successful pull
print "Installing git hooks..."
mkdir -p .git/hooks
ln -sf ../../deploy.zsh .git/hooks/post-merge
ln -sf ../../deploy.zsh .git/hooks/post-checkout
print "  ...done"

if (( ${+commands[vim]} )); then
    # Generating vim help tags
    print "Generating vim helptags..."
    nohup vim -c 'silent! helptags ALL | q' </dev/null &>/dev/null
    print "  ...done"
fi

# Link goenv plugins to $GOENV_ROOT
print "Linking goenv plugins..."
hlsearch)65M
ln -snf "${SCRIPT_DIR}/env-wrappers/goenv/goenv/plugins/go-build" "${XDG_DATA_HOME}/goenv/plugins/go-build"
print "  ...done"

# Link nodenv plugins to $NODENV_ROOT
print "Linking nodenv plugins..."
ln -snf "${SCRIPT_DIR}/env-wrappers/nodenv/node-build" "${XDG_DATA_HOME}/nodenv/plugins/node-build"
ln -snf "${SCRIPT_DIR}/env-wrappers/nodenv/nodenv-aliases" "${XDG_DATA_HOME}/nodenv/plugins/nodenv-aliases"
ln -snf "${SCRIPT_DIR}/env-wrappers/nodenv/nodenv-env" "${XDG_DATA_HOME}/nodenv/plugins/nodenv-env"
ln -snf "${SCRIPT_DIR}/env-wrappers/nodenv/nodenv-man" "${XDG_DATA_HOME}/nodenv/plugins/nodenv-man"
ln -snf "${SCRIPT_DIR}/env-wrappers/nodenv/nodenv-package-rehash" "${XDG_DATA_HOME}/nodenv/plugins/nodenv-package-rehash"
ln -snf "${SCRIPT_DIR}/env-wrappers/nodenv/nodenv-update" "${XDG_DATA_HOME}/nodenv/plugins/nodenv-update"
ln -snf "${SCRIPT_DIR}/env-wrappers/nodenv/node-build-update-defs" "${XDG_DATA_HOME}/nodenv/plugins/node-build-update-defs"
print "  ...done"

# Trigger zsh run with powerlevel10k prompt to download gitstatusd
print "Downloading gitstatusd for powerlevel10k..."
$SHELL -is <<<'' &>/dev/null
print "  ...done"


# Install crontab task to pull updates every midnight
print "Installing cron job for periodic updates..."
local cron_task="cd ${SCRIPT_DIR} && git -c user.name=cron.update -c user.email=cron@localhost stash && git pull && git stash pop"
local cron_schedule="0 0 * * * ${cron_task}"
if cat <(fgrep -i -v "${cron_task}" <(crontab -l)) <(echo "${cron_schedule}") | crontab -; then
    print "  ...done"
else
    print "Please add \`cd ${SCRIPT_DIR} && git pull\` to your crontab or just ignore this, you can always update dotfiles manually"
fi
