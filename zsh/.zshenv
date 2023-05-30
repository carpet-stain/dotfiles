# Determine own path if ZDOTDIR isn't set or home symlink exists
if [[ -z "${ZDOTDIR}" || -L "${HOME}/.zshenv" ]]; then
    local homezshenv="${HOME}/.zshenv"
    export ZDOTDIR="${homezshenv:A:h}"
fi

# DOTFILES dir is parent to ZDOTDIR
export DOTFILES="${ZDOTDIR%/*}"

# Disable global zsh configuration

unsetopt GLOBAL_RCS

# Enable profiling, if requested via env var
# do `ZSH_ZPROF_ENABLE=1 exec zsh`
if [[ -v ZSH_ZPROF_ENABLE ]]; then
    zmodload zsh/zprof
fi

# Load zsh/files module to provide some builtins for file modifications
zmodload -F -m zsh/files b:zf_\*

# +---------+
# | EXPORTS |
# +---------+

# Prefered editor and pager
export VISUAL=nvim
export EDITOR=nvim
export VIMINIT='let $MYVIMRC="$DOTFILES/nvim/init.lua" | source $MYVIMRC'
export PAGER=less
export LESS="--RAW-CONTROL-CHARS --ignore-case --hilite-unread --LONG-PROMPT --window=-4 --tabs=4"
export READNULLCMD=${PAGER}

# make sure gpg knows about current TTY
export GPG_TTY=${TTY}

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

# Homebrew
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_VERBOSE_USING_DOTS=1
export HOMEBREW_PREFIX=/opt/homebrew

# Reported from XDG-NINJA
export GNUPGHOME=${XDG_DATA_HOME}/gnupg
export LESSHISTFILE=${XDG_DATA_HOME}/lesshst
export DOCKER_CONFIG=${XDG_CONFIG_HOME}/docker
export MACHINE_STORAGE_PATH=${XDG_DATA_HOME}/docker/machine
export MINIKUBE_HOME=${XDG_DATA_HOME}/minikube
export VAGRANT_HOME=${XDG_DATA_HOME}/vagrant
export HTOPRC=${XDG_CONFIG_HOME}/htop/htoprc
export PACKER_CONFIG=${XDG_CONFIG_HOME}/packer
export PACKER_CACHE_DIR=${XDG_CACHE_HOME}/packer
export NPM_CONFIG_USERCONFIG=${XDG_CONFIG_HOME}/npm/config
export NPM_CONFIG_CACHE=${XDG_CACHE_HOME}/npm
export HTTPIE_CONFIG_DIR=${XDG_CONFIG_HOME}/httpie
export ANSIBLE_LOCAL_TEMP=${XDG_RUNTIME_DIR}/ansible/tmp
export ELECTRUMDIR=$XDG_DATA_HOME/electrum
export TERMINFO="$XDG_DATA_HOME"/terminfo
export TERMINFO_DIRS="$XDG_DATA_HOME"/terminfo:/usr/share/terminfo
export GOBIN=${HOMEBREW_PREFIX}/bin/go
export GOPATH=${XDG_DATA_HOME}/go

# +-------+
# | PATHS |
# +-------+

# Add custom functions and completions
fpath=(${ZDOTDIR}/fpath ${fpath})

# in order to use #, ~ and ^ for filename generation grep word
# *~(*.gz|*.bz|*.bz2|*.zip|*.Z) -> searches for word not in compressed files
# don't forget to quote '^', '~' and '#'!
setopt EXTENDED_GLOB # treat special characters as part of patterns

# Initialize path.
# If dirs are missing, they won't be added due to null globbing.
path=(
  $HOME/{,s}bin(N)
  /opt/{homebrew,local}/{,s}bin(N)
  /usr/local/{,s}bin(N)
  $path
)

if [[ "${OSTYPE}" = darwin* ]]; then
    autoload -z evalcache
    evalcache brew shellenv

    # Enable gnu version of utilities on macOS, if installed
    for gnuutil in coreutils gnu-sed gnu-tar grep; do
        if [[ -d ${HOMEBREW_PREFIX}/opt/${gnuutil}/libexec/gnubin ]]; then
            path=(${HOMEBREW_PREFIX}/opt/${gnuutil}/libexec/gnubin ${path})
        fi
        if [[ -d ${HOMEBREW_PREFIX}/opt/${gnuutil}/libexec/gnuman ]]; then
            MANPATH="${HOMEBREW_PREFIX}/opt/${gnuutil}/libexec/gnuman:${MANPATH}"
        fi
    done
    # Prefer curl installed via brew
    if [[ -d ${HOMEBREW_PREFIX}/opt/curl/bin ]]; then
        path=(${HOMEBREW_PREFIX}/opt/curl/bin ${path})
    fi
fi

# Enable local binaries and man pages
path=(${HOME}/.local/bin ${path})
MANPATH="${XDG_DATA_HOME}/man:${MANPATH}"

# Add go binaries to paths
path=(${GOPATH}/bin ${path})