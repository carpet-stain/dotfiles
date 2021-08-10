if (( ${+commands[ranger]} )); then
    ranger () {
        if [[ -v RANGER_LEVEL ]]; then
            exit
        fi

        local ranger_pwd_file="$(mktemp -t ranger_pwd.XXXXXXXXXX)"

        command ranger --choosedir="${ranger_pwd_file}" "${@}"

        if [[ -r ${ranger_pwd_file} ]]; then
            local ranger_last_pwd=$(<"${ranger_pwd_file}")
            if [[ -d ${ranger_last_pwd} ]] && [[ ${ranger_last_pwd} != ${PWD} ]]; then
                cd "${ranger_last_pwd}"
            fi
            rm -f "${ranger_pwd_file}"
        fi
    }

    # Change ranger CWD to PWD on subshell exit
    if [[ -v RANGER_LEVEL ]]; then
        _ranger_cd () {
            print "cd ${PWD}" > "${XDG_RUNTIME_DIR}/ranger-ipc.${PPID}"
        }
        add-zsh-hook zshexit _ranger_cd
    fi
fi
