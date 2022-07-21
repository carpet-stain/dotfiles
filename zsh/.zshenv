# Determine own path if ZDOTDIR isn't set or home symlink exists
if [[ -z "${ZDOTDIR}" || -L "${HOME}/.zshenv" ]]; then
    local homezshenv="${HOME}/.zshenv"
    export ZDOTDIR="${homezshenv:A:h}"
fi
# DOTFILES dir is parent to ZDOTDIR
export DOTFILES="${ZDOTDIR%/*}"
export BREW_EXECUTABLE="/usr/local/bin"

# Load zsh/files module to provide some builtins for file modifications
zmodload -F -m zsh/files b:zf_\*

# Prefered editor and pager
export VISUAL=nvim
export EDITOR=nvim
export VIMINIT='let $MYVIMRC="$DOTFILES/nvim/init.vim" | source $MYVIMRC'
export PAGER=less
export LESS="--RAW-CONTROL-CHARS --ignore-case --hilite-unread --LONG-PROMPT --window=-4 --tabs=4"
export READNULLCMD=${PAGER}

# XDG basedir spec compliance
if [[ ! -v XDG_CONFIG_HOME ]]; then
    export XDG_CONFIG_HOME"=${HOME}/.config"
fi
if [[ ! -v XDG_CACHE_HOME ]]; then
    export XDG_CACHE_HOME="${HOME}/.cache"
fi
if [[ ! -v XDG_DATA_HOME ]]; then
    export XDG_DATA_HOME="${HOME}/.local/share"
fi
if [[ ! -v XDG_STATE_HOME ]]; then
    export XDG_STATE_HOME="${HOME}/.local/state"
fi
if [[ ! -v XDG_RUNTIME_DIR ]]; then
    export XDG_RUNTIME_DIR="${TMPDIR:-/tmp}/runtime-${USER}"
fi

export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
export LESSHISTFILE="${XDG_DATA_HOME}/lesshst"
export DOCKER_CONFIG="${XDG_CONFIG_HOME}/docker"
export MACHINE_STORAGE_PATH="${XDG_DATA_HOME}/docker/machine"
export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}/bundle"
export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}/bundle"
export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}/bundle"
export MINIKUBE_HOME="${XDG_DATA_HOME}/minikube"
export VAGRANT_HOME="${XDG_DATA_HOME}/vagrant"
export HTOPRC="${XDG_CONFIG_HOME}/htop/htoprc"
export PACKER_CONFIG="${XDG_CONFIG_HOME}/packer"
export PACKER_CACHE_DIR="${XDG_CACHE_HOME}/packer"
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/config"
export NPM_CONFIG_CACHE="${XDG_CACHE_HOME}/npm"
export ANSIBLE_LOCAL_TEMP="${XDG_RUNTIME_DIR}/ansible/tmp"
export GOPATH="${XDG_DATA_HOME}/go"
export TASKDATA="${XDG_DATA_HOME}/task"
export TASKRC="${XDG_CONFIG_HOME}/task/taskrc"
export GTK2_RC_FILES="${XDG_CONFIG_HOME}/gtk-2.0/gtkrc"

# Ensure we have local paths enabled
path=(/usr/local/bin /usr/local/sbin ${path})

if [[ "${OSTYPE}" = darwin* ]]; then
    # Enable gnu version of utilities on macOS, if installed
    for gnuutil in coreutils gnu-sed gnu-tar grep; do
        if [[ -d /usr/local/opt/${gnuutil}/libexec/gnubin ]]; then
            path=(/usr/local/opt/${gnuutil}/libexec/gnubin ${path})
        fi
        if [[ -d /usr/local/opt/${gnuutil}/libexec/gnuman ]]; then
            MANPATH="/usr/local/opt/${gnuutil}/libexec/gnuman:${MANPATH}"
        fi
    done
    # Prefer curl installed via brew
    if [[ -d /usr/local/opt/curl/bin ]]; then
        path=(/usr/local/opt/curl/bin ${path})
    fi
fi

# Enable local binaries and man pages
path=(${HOME}/.local/bin ${path})
MANPATH="${XDG_DATA_HOME}/man:${MANPATH}"

# Add go binaries to paths
path=(${GOPATH}/bin ${path})

# Add custom functions and completions
fpath=(${ZDOTDIR}/fpath ${fpath})

# Keep SSH_AUTH_SOCK valid across several attachments to the remote tmux session
if (( EUID != 0 )); then
    if [[ -S "${GNUPGHOME}/S.gpg-agent.ssh" ]]; then
        zf_ln -sf "${GNUPGHOME}/S.gpg-agent.ssh" "${HOME}/.ssh/ssh_auth_sock"
    elif [[ -S "${XDG_RUNTIME_DIR}/ssh-agent.socket" ]]; then
        zf_ln -sf "${XDG_RUNTIME_DIR}/ssh-agent.socket" "${HOME}/.ssh/ssh_auth_sock"
    elif [[ -S "${SSH_AUTH_SOCK}" ]] && [[ ! -h "${SSH_AUTH_SOCK}" ]] && [[ "${SSH_AUTH_SOCK}" != "${HOME}/.ssh/ssh_auth_sock" ]]; then
        zf_ln -sf "${SSH_AUTH_SOCK}" "${HOME}/.ssh/ssh_auth_sock"
    fi
    export SSH_AUTH_SOCK="${HOME}/.ssh/ssh_auth_sock"
fi

# Disable global zsh configuration
# We're doing all configuration ourselves
unsetopt GLOBAL_RCS

# XDG compliance
ZSHZ_DATA="${XDG_CACHE_HOME}/zsh/z"
# match to uncommon prefix
ZSHZ_UNCOMMON=1
# ignore case when lowercase, match case with uppercase
ZSHZ_CASE=smart

source "${ZDOTDIR}/plugins/z/zsh-z.plugin.zsh"
