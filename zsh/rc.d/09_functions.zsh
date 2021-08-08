# List all directories leading up to a filename; this is useful to see
# if some permissions are blocking access to a file.
lspath () {
    local pathlist
    if [[ "${1}" = "${1##/}" ]]; then
        pathlist=(/ ${(s:/:)PWD} ${(s:/:)1})
    else
        pathlist=(/ ${(s:/:)1})
    fi
    local allpaths=()
    local filepath=${pathlist[0]}
    shift pathlist
    for i in ${pathlist[@]}; do
        allpaths=(${allpaths[@]} ${filepath})
        filepath="${filepath%/}/$i"
    done
    allpaths=(${allpaths[@]} ${filepath})
    ls -ld "${allpaths[@]}"
}

# Grep from ps output
psg () {
    if [[ ${#} -eq 0 ]]; then
        echo "Please specify process search pattern"
        return 2
    fi
    local psaux=$(ps aux)
    local result
    if result=$(grep --color=always -i "[${1[1]}]${1#?}" <<< ${psaux}); then
        { echo ${${(f)psaux}[1]}; echo ${result}; } | less -FRX
    else
        echo "No process found matching pattern '${1}'"
        return 1
    fi
}

# Do something for each directory, handle Ctrl+C interrupts
ineachdir () {
    {
        setopt localoptions localtraps

        TRAPINT () {
            echo ${fg[white]}"--- IED: Caught SIGINT, aborting."${fg[default]}
            return $(( 128 + $1 ))
        }

        local cwd dir exitcode ied_opts
        local -A ied_status
        cwd=${PWD}

        zparseopts -E -D -M -A ied_opts -- -ignore-errors -status-table i=-ignore-errors s=-status-table

        if [[ ${#} -eq 0 ]]; then
            cat << EOH
Usage: ineachdir [-i | --ignore-errors] [-s | --status-table] <command>

Perform specified <command> in each directory.

Arguments:
    -i, --ignore-errors    Ignore <command> execution error,
                           continue to next dir

    -s, --status-table     Show status table at the end

Example:
    ineachdir -s git pull --prune
EOH
            return 0
        fi

        for dir in */; do
            echo ${fg[white]}"--- IED: Executing '$@' in '${cwd}/${dir}'..."${fg[default]}
            cd "${cwd}/${dir}"
            $@
            exitcode=$?
            if (( ${+ied_opts[--status-table]} )); then
                ied_status[${dir}]=${exitcode}
            fi
            if [[ ${exitcode} -ne 0 ]]; then
                if (( ${+ied_opts[--ignore-errors]} )); then
                    echo ${fg[yellow]}"--- IED: '$@' returned ${exitcode}, ignoring."${fg[default]}
                else
                    echo ${fg[red]}"--- IED: '$@' returned ${exitcode}, aborting."${fg[default]}
                    return $(( 128 + ${exitcode} ))
                fi
            fi
            echo
        done

        if (( ${+ied_opts[--status-table]} )); then
            echo ${fg[white]}"--- IED: Execution results"${fg[default]}
            for dir exitcode in ${(kv)ied_status}; do
                if [[ ${exitcode} -ne 0 ]]; then
                    exitcode="${fg[yellow]}${exitcode}${fg[default]}"
                fi
                printf '%s\n' "${(r:35:)dir}: ${(%)exitcode}"
            done
        fi
    } always {
        cd "${cwd}"
        unfunction TRAPINT
    }
}

# Autoexpand "..." to "../.." and so on
_zsh-dot () {
    if [[ ${LBUFFER} = *.. ]]; then
        LBUFFER+=/..
    else
        LBUFFER+=.
    fi
}
zle -N _zsh-dot
bindkey . _zsh-dot

# Print apt history
apt-history () {
    case "${1}" in
    install)
        if [[ -e /var/log/dpkg.log ]]; then
            zgrep --no-filename ' installed' "$(ls -rt /var/log/dpkg*)"
        else
            journalctl -n1000 -t dpkg | grep ' installed'
        fi
        ;;
    upgrade|remove)
        if [[ -e /var/log/dpkg.log ]]; then
            zgrep --no-filename "${1}" "$(ls -rt /var/log/dpkg*)"
        else
            journalctl -n1000 -t dpkg | grep "${1}"
        fi
        ;;
    *)
        echo "Parameters:"
        echo " install - Lists all packages that have been installed."
        echo " upgrade - Lists all packages that have been upgraded."
        echo " remove - Lists all packages that have been removed."
        ;;
    esac
}

# vpaste uploader
vpaste () {
    local uri="http://vpaste.net/"
    local out
    if [[ -f "${1}" ]]; then
        out=$(curl -s -F "text=<${1}" "${uri}?${2}")
    else
        out=$(curl -s -F 'text=<-' "${uri}?${1}")
    fi
    echo "${out}"
    if (( ${+commands[xclip]} )) && [[ ! -z "${DISPLAY}" ]]; then
        echo -n "${out}" | xclip -i -selection primary
        echo -n "${out}" | xclip -i -selection clipboard
    elif (( ${+commands[pbcopy]} )); then
        echo -n "${out}" | pbcopy
    fi
}

# z via fzf selector
fz () {
    cd "$(z -l | sed 's/^[0-9. ]*//' | \
          fzf --height=50% --no-sort --tac --layout=reverse-list --filepath-word --query="$*" \
              --preview='LC_COLLATE=C ls -l -v --almost-all --group-directories-first --classify --color=always --human-readable {}' )"
}

# git log browser with fzf
fgl () {
    git rev-parse --is-inside-work-tree &> /dev/null || return
    git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
    fzf --ansi --height=50% --no-sort --layout=reverse-list --multi --bind='ctrl-s:toggle-sort' \
        --header='Press CTRL-S to toggle sort' \
        --preview='grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always | head -200' |
    grep -o "[a-f0-9]\{7,\}"
}

# git branch selector with fzf
fgb () {
    git rev-parse --is-inside-work-tree &> /dev/null || return
    git checkout $(git branch --color=always -a | grep -v 'HEAD' | sort --ignore-case |
                   fzf --ansi --height=50% --no-sort --tac --layout=reverse-list --preview-window=right:70% --query="${@}" \
                       --header='Red are remote, white are local, green is current' \
                       --preview='git log --color=always --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) | head -200' |
                   sed 's/^..//' | sed 's#^remotes/origin/##')
}

# git diff by files with fzf
fgd () {
    git rev-parse --is-inside-work-tree &> /dev/null || return
    local preview_cmd files commit repo highlighter
    [[ $# -ne 0 ]] && {
        if git rev-parse "$1" -- &>/dev/null ; then
            commit="$1" && files=("${@:2}")
        else
            files=("$@")
        fi
    }
    if (( ${+commands[diff-so-fancy]} )); then
        highlighter='| diff-so-fancy'
    else
        highlighter=''
    fi
    repo="$(git rev-parse --show-toplevel)"
    preview_cmd="xargs -I% git --no-pager diff --color=always ${commit} -- '${repo}/%' <<< {} ${highlighter}"
    git --no-pager diff --name-only ${commit} -- ${files[*]} |
        fzf --exit-0 --ansi --height=50% --preview-window=right:50% --no-sort --tac --layout=reverse-list --preview="${preview_cmd}"
}

# recursively search for string, feed matches to fzf with preview, launch vim with selected match
bag () {
    # prefer ag to grep
    if (( ${+commands[ag]} )); then
        search_cmd () { ag --nogroup --color "$*" }
    else
        search_cmd () { grep --line-number --recursive --ignore-case --color=always "$*" }
    fi

    # use bat with syntax highlight support, if it's avaialble
    local preview_cmd
    if (( ${+commands[bat]} )); then
        preview_cmd='bat --paging=never --terminal-width=${FZF_PREVIEW_COLUMNS} --color=always --style=plain,numbers,changes \
                         --line-range=${from}:${till} --highlight-line=${line} ${filename}'
    else
        # replace here used to highligh line with match
        preview_cmd='sed -n -E "s/(.*'$*'.*)/'$bg[grey]'\1'$reset_color'/gI;${from},${till}p" < ${filename}'
    fi

    local result=$(search_cmd "$*" |
        fzf --exit-0 --ansi --layout=reverse-list --no-sort --height=50% --preview-window=right:50% \
            --preview='match={};
                       filename=${${(s.:.)match}[1]};
                       line=${${(s.:.)match}[2]};
                       from=$((line-10 > 1 ? line-10 : 1));
                       till=$((line+10));'${preview_cmd}
    )
    if [[ -n "${result}" ]]; then
        vi "${${(s.:.)result}[1]}" +"${${(s.:.)result}[2]}"
    else
        return 1
    fi
}

# sudo wrapper to handle noglob and nocorrect aliases
do_sudo () {
    integer glob=1
    local -a run
    run=(command sudo)
    if [[ ${#} -gt 1 && ${1} = -u ]]; then
        run+=(${1} ${2})
        shift; shift
    fi
    while (( ${#} )); do
        case "${1}" in
            command|exec|-) shift; break ;;
            nocorrect) shift ;;
            noglob) glob=0; shift ;;
            *) break ;;
        esac
    done
    if (( glob )); then
        ${run} $~==*
    else
        ${run} $==*
    fi
}

evalcache () {
    local eval_cache_dir="${XDG_CACHE_HOME}/zsh/eval"
    local cache_file="${eval_cache_dir}/${1##*/}.zsh"

    # revalidate cache every 20 hours
    if [[ ! -e "${cache_file}" || -n "${cache_file}"(#qN.mh+20) ]]; then
        # cache miss
        if (( ${+commands[${1}]} )); then
            mkdir -p "${eval_cache_dir}"
            command "$@" > "${cache_file}"
            source "${cache_file}"
        else
            echo "evalcache ERROR: $1 is not available in PATH" >&2
        fi
    else
        # cache hit
        source "${cache_file}"
    fi
}
