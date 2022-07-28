# Attach to a tmux session, if there's any. Do this only for remote SSH sessions, don't mess local tmux sessions
# Handoff to tmux early, as rest of the rc config isn't needed for this
if (( ${+commands[tmux]} )) && [[ ! -v TMUX ]] && pgrep -u "${EUID}" tmux &>/dev/null && [[ -v SSH_TTY ]] && [[ ! -v MC_SID ]]; then
    exec tmux attach
fi

# Enable profiling
zmodload zsh/zprof

(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv export zsh)"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv hook zsh)"

setopt HIST_IGNORE_ALL_DUPS # remove all earlier duplicate lines
setopt APPEND_HISTORY # history appends to existing file
setopt SHARE_HISTORY # import new commands from the history file also in other zsh-session
setopt EXTENDED_HISTORY # save each commands beginning timestamp and the duration to the history file
setopt HIST_REDUCE_BLANKS # trim multiple insgnificant blanks in history
setopt HIST_IGNORE_SPACE # don’t store lines starting with space

# in order to use #, ~ and ^ for filename generation grep word
# *~(*.gz|*.bz|*.bz2|*.zip|*.Z) -> searches for word not in compressed files
# don't forget to quote '^', '~' and '#'!
setopt EXTENDED_GLOB # treat special characters as part of patterns
setopt CORRECT_ALL # try to correct the spelling of all arguments in a line
setopt NO_FLOW_CONTROL # disable stupid annoying keys
setopt MULTIOS # allows multiple input and output redirections
setopt AUTO_CD # if the command is directory and cannot be executed, perform cd to this directory
setopt CLOBBER # allow > redirection to truncate existing files
setopt BRACE_CCL # allow brace character class list expansion
setopt NO_BEEP # do not beep on errors
setopt NO_NOMATCH # try to avoid the 'zsh: no matches found...'
setopt INTERACTIVE_COMMENTS # allow use of comments in interactive code
setopt AUTO_PARAM_SLASH # complete folders with / at end
setopt LIST_TYPES # mark type of completion suggestions
setopt HASH_LIST_ALL # whenever a command completion is attempted, make sure the entire command path is hashed first
setopt COMPLETE_IN_WORD # allow completion from within a word/phrase
setopt ALWAYS_TO_END # move cursor to the end of a completed word
setopt LONG_LIST_JOBS # display PID when suspending processes as well
setopt AUTO_RESUME # attempt to resume existing job before creating a new process
setopt NOTIFY # report status of background jobs immediately
#setopt NO_HUP # Don't send SIGHUP to backgrou processes when the shell exits
#setopt AUTO_PUSHD # Make cd push the old directory onto the directory stack
#setopt PUSHD_IGNORE_DUPS # don't push the same dir twice
#setopt NO_GLOB_DOTS # * shouldn't match dotfiles. ever.
#setopt NO_SH_WORD_SPLIT # use zsh style word splitting
#setopt INTERACTIVE_COMMENTS # enable interactive comments
#stty -ixon # Disable flowcontrol
unsetopt RM_STAR_SILENT # notify when rm is running with *
setopt RM_STAR_WAIT # wait for 10 seconds confirmation when running rm with *

# a bit fancy than default
PROMPT_EOL_MARK='%K{red} %k'

HISTFILE="${XDG_DATA_HOME}/zsh/history"
HISTSIZE=10000
SAVEHIST=10000

# Initialize colors
autoload -U colors
colors

# Fullscreen command line edit
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

# Ctrl+W stops on path delimiters
autoload -U select-word-style
select-word-style bash

# Enable run-help module
(( $+aliases[run-help] )) && unalias run-help
autoload -Uz run-help
alias help=run-help

# enable url-quote-magic
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

# enable bracketed paste
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

# compatability with zsh-autosuggestion
pasteinit() {
    OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
    zle -N self-insert url-quote-magic
}

pastefinish() {
    zle -N self-insert $OLD_SELF_INSERT
}

zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# Use default provided history search widgets
autoload -Uz up-line-or-beginning-search
zle -N up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search
zle -N down-line-or-beginning-search

# Enable functions from archive plugin
fpath+="${ZDOTDIR}/plugins/archive"
autoload -Uz archive lsarchive unarchive

# Custom personal functions
# Don't use -U as we need aliases here
autoload -z lspath bag fgb fgd fgl fz ineachdir psg vpaste

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

zmodload zsh/terminfo

# Create a zkbd compatible hash
typeset -A key
key[Home]=${terminfo[khome]}
key[End]=${terminfo[kend]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[PageUp]=${terminfo[kpp]}
key[PageDown]=${terminfo[knp]}
key[Backspace]=${terminfo[kbs]}
key[ShiftTab]="${terminfo[kcbt]}"
# man 5 user_caps
key[CtrlLeft]=${terminfo[kLFT5]}
key[CtrlRight]=${terminfo[kRIT5]}

# Setup keys accordingly
[[ -n "${key[Home]}"      ]] && bindkey "${key[Home]}"       beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey "${key[End]}"        end-of-line
[[ -n "${key[Insert]}"    ]] && bindkey "${key[Insert]}"     overwrite-mode
[[ -n "${key[Delete]}"    ]] && bindkey "${key[Delete]}"     delete-char
[[ -n "${key[Left]}"      ]] && bindkey "${key[Left]}"       backward-char
[[ -n "${key[Right]}"     ]] && bindkey "${key[Right]}"      forward-char
[[ -n "${key[Up]}"        ]] && bindkey "${key[Up]}"         up-line-or-beginning-search
[[ -n "${key[Down]}"      ]] && bindkey "${key[Down]}"       down-line-or-beginning-search
[[ -n "${key[PageUp]}"    ]] && bindkey "${key[PageUp]}"     beginning-of-buffer-or-history
[[ -n "${key[PageDown]}"  ]] && bindkey "${key[PageDown]}"   end-of-buffer-or-history
[[ -n "${key[Backspace]}" ]] && bindkey "${key[Backspace]}"  backward-delete-char
[[ -n "${key[ShiftTab]}"  ]] && bindkey "${key[ShiftTab]}"   reverse-menu-complete
[[ -n "${key[CtrlLeft]}"  ]] && bindkey "${key[CtrlLeft]}"   backward-word
[[ -n "${key[CtrlRight]}" ]] && bindkey "${key[CtrlRight]}"  forward-word

# Make dot key autoexpand "..." to "../.." and so on
_zsh-dot () {
    if [[ ${LBUFFER} = *.. ]]; then
        LBUFFER+=/..
    else
        LBUFFER+=.
    fi
}
zle -N _zsh-dot
bindkey . _zsh-dot

# Enable powerlevel10k prompt
source "${ZDOTDIR}/plugins/powerlevel10k/powerlevel10k.zsh-theme"

# Losely based on results from `p10k configure`

# Temporarily change options.
'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
    emulate -L zsh -o extended_glob

    # Unset all configuration options. This allows you to apply configuration changes without
    # restarting zsh. Edit ~/.p10k.zsh and type `source ~/.p10k.zsh`.
    unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

    # Configure left prompt
    typeset -ga POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
        vim_shell
        context
        dir
        vcs
        virtualenv
        pyenv
        goenv
        nodenv
        terraform
        kubecontext
        aws
        status
        command_execution_time
        background_jobs
        newline
        prompt_char
    )

    # Disable right prompt
    typeset -g POWERLEVEL9K_DISABLE_RPROMPT=true

    # Defines character set used by powerlevel10k. It's best to let `p10k configure` set it for you.
    typeset -g POWERLEVEL9K_MODE=compatible
    # When set to `moderate`, some icons will have an extra space after them. This is meant to avoid
    # icon overlap when using non-monospace fonts. When set to `none`, spaces are not added.
    typeset -g POWERLEVEL9K_ICON_PADDING=none

    # Basic style options that define the overall look of your prompt. You probably don't want to
    # change them.
    typeset -g POWERLEVEL9K_BACKGROUND=                            # transparent background
    typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=  # no surrounding whitespace
    typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '  # separate segments with a space
    typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=        # no end-of-line symbol

    # When set to true, icons appear before content on both sides of the prompt. When set
    # to false, icons go after content. If empty or not set, icons go before content in the left
    # prompt and after content in the right prompt.
    #
    # You can also override it for a specific segment:
    #
    #   POWERLEVEL9K_STATUS_ICON_BEFORE_CONTENT=false
    #
    # Or for a specific segment in specific state:
    #
    #   POWERLEVEL9K_DIR_NOT_WRITABLE_ICON_BEFORE_CONTENT=false
    typeset -g POWERLEVEL9K_ICON_BEFORE_CONTENT=true

    # Add an empty line before each prompt.
    typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
    # Disable ruler
    typeset -g POWERLEVEL9K_SHOW_RULER=false

    ################################[ prompt_char: prompt symbol ]################################
    # Green prompt symbol if the last command succeeded.
    typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=76
    # Red prompt symbol if the last command failed.
    typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196
    # Default prompt symbol.
    typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_{VIINS,VICMD,VIVIS,VIOWR}_CONTENT_EXPANSION='%#'
    typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true
    # No line terminator if prompt_char is the last segment.
    typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
    # No line introducer if prompt_char is the first segment.
    typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=

    ##################################[ dir: current directory ]##################################
    # Default current directory color.
    typeset -g POWERLEVEL9K_DIR_FOREGROUND=31
    # If directory is too long, shorten some of its segments to the shortest possible unique
    # prefix. The shortened directory can be tab-completed to the original.
    typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
    # Replace removed segment suffixes with this symbol.
    typeset -g POWERLEVEL9K_SHORTEN_DELIMITER=
    # Color of the shortened directory segments.
    typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=103
    # Color of the anchor directory segments. Anchor segments are never shortened. The first
    # segment is always an anchor.
    typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=39
    # Display anchor directory segments in bold.
    typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
    # Don't shorten directories that contain any of these files. They are anchors.
    local anchor_files=(
        .bzr
        .citc
        .git
        .hg
        .node-version
        .python-version
        .go-version
        .tool-version
        .shorten_folder_marker
        .svn
        .terraform
        CVS
        Cargo.toml
        composer.json
        go.mod
        package.json
        stack.yaml
    )
    typeset -g POWERLEVEL9K_SHORTEN_FOLDER_MARKER="(${(j:|:)anchor_files})"
    # If set to "first" ("last"), remove everything before the first (last) subdirectory that contains
    # files matching $POWERLEVEL9K_SHORTEN_FOLDER_MARKER. For example, when the current directory is
    # /foo/bar/git_repo/nested_git_repo/baz, prompt will display git_repo/nested_git_repo/baz (first)
    # or nested_git_repo/baz (last). This assumes that git_repo and nested_git_repo contain markers
    # and other directories don't.
    #
    # Optionally, "first" and "last" can be followed by ":<offset>" where <offset> is an integer.
    # This moves the truncation point to the right (positive offset) or to the left (negative offset)
    # relative to the marker. Plain "first" and "last" are equivalent to "first:0" and "last:0"
    # respectively.
    typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=false
    # Don't shorten this many last directory segments. They are anchors.
    typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
    # Shorten directory if it's longer than this even if there is space for it. The value can
    # be either absolute (e.g., '80') or a percentage of terminal width (e.g, '50%'). If empty,
    # directory will be shortened only when prompt doesn't fit or when other parameters demand it
    # (see POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS and POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS_PCT below).
    # If set to `0`, directory will always be shortened to its minimum length.
    typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=80
    # When `dir` segment is on the last prompt line, try to shorten it enough to leave at least this
    # many columns for typing commands.
    typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
    # When `dir` segment is on the last prompt line, try to shorten it enough to leave at least
    # COLUMNS * POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS_PCT * 0.01 columns for typing commands.
    typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS_PCT=50
    # If set to true, embed a hyperlink into the directory. Useful for quickly
    # opening a directory in the file manager simply by clicking the link.
    # Can also be handy when the directory is shortened, as it allows you to see
    # the full directory that was used in previous commands.
    typeset -g POWERLEVEL9K_DIR_HYPERLINK=false

    # Enable special styling for non-writable and non-existent directories. See POWERLEVEL9K_LOCK_ICON
    # and POWERLEVEL9K_DIR_CLASSES below.
    typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=v3

    # The default icon shown next to non-writable and non-existent directories when
    # POWERLEVEL9K_DIR_SHOW_WRITABLE is set to v3.
    typeset -g POWERLEVEL9K_LOCK_ICON='#'

    # Override default ETC_ICON as unicode cog symbol doesn't render properly with current font.
    typeset -g POWERLEVEL9K_ETC_ICON=

    #####################################[ vcs: git status ]######################################
    # Branch icon. Set this parameter to '\uF126 ' for the popular Powerline branch icon.
    typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=

    # Untracked files icon. It's really a question mark, your font isn't broken.
    # Change the value of this parameter to show a different icon.
    typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'

    # Formatter for Git status.
    #
    # Example output: master ⇣42⇡42 *42 merge ~42 +42 !42 ?42.
    #
    # You can edit the function to customize how Git status looks.
    #
    # VCS_STATUS_* parameters are set by gitstatus plugin. See reference:
    # https://github.com/romkatv/gitstatus/blob/master/gitstatus.plugin.zsh.
    function my_git_formatter() {
        emulate -L zsh

        if [[ -n $P9K_CONTENT ]]; then
            # If P9K_CONTENT is not empty, use it. It's either "loading" or from vcs_info (not from
            # gitstatus plugin). VCS_STATUS_* parameters are not available in this case.
            typeset -g my_git_format=$P9K_CONTENT
            return
        fi

        if (( $1 )); then
            # Styling for up-to-date Git status.
            local       meta='%f'     # default foreground
            local      clean='%76F'   # green foreground
            local   modified='%178F'  # yellow foreground
            local  untracked='%39F'   # blue foreground
            local conflicted='%196F'  # red foreground
        else
            # Styling for incomplete and stale Git status.
            local       meta='%244F'  # grey foreground
            local      clean='%244F'  # grey foreground
            local   modified='%244F'  # grey foreground
            local  untracked='%244F'  # grey foreground
            local conflicted='%244F'  # grey foreground
        fi

        local res

        if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
            local branch=${(V)VCS_STATUS_LOCAL_BRANCH}
            # If local branch name is at most 32 characters long, show it in full.
            # Otherwise show the first 12 … the last 12.
            # Tip: To always show local branch name in full without truncation, delete the next line.
            (( $#branch > 32 )) && branch[13,-13]="…"  # <-- this line
            res+="${clean}${(g::)POWERLEVEL9K_VCS_BRANCH_ICON}${branch//\%/%%}"
        fi

        if [[ -n $VCS_STATUS_TAG
              # Show tag only if not on a branch.
              # Tip: To always show tag, delete the next line.
              && -z $VCS_STATUS_LOCAL_BRANCH  # <-- this line
        ]]; then
            local tag=${(V)VCS_STATUS_TAG}
            # If tag name is at most 32 characters long, show it in full.
            # Otherwise show the first 12 … the last 12.
            # Tip: To always show tag name in full without truncation, delete the next line.
            (( $#tag > 32 )) && tag[13,-13]="…"  # <-- this line
            res+="${meta}#${clean}${tag//\%/%%}"
        fi

        # Display the current Git commit if there is no branch and no tag.
        # Tip: To always display the current Git commit, delete the next line.
        [[ -z $VCS_STATUS_LOCAL_BRANCH && -z $VCS_STATUS_TAG ]] &&  # <-- this line
        res+="${meta}@${clean}${VCS_STATUS_COMMIT[1,8]}"

        # Show tracking branch name if it differs from local branch.
        if [[ -n ${VCS_STATUS_REMOTE_BRANCH:#$VCS_STATUS_LOCAL_BRANCH} ]]; then
            res+="${meta}:${clean}${(V)VCS_STATUS_REMOTE_BRANCH//\%/%%}"
        fi

        # ⇣42 if behind the remote.
        (( VCS_STATUS_COMMITS_BEHIND )) && res+=" ${clean}⇣${VCS_STATUS_COMMITS_BEHIND}"
        # ⇡42 if ahead of the remote; no leading space if also behind the remote: ⇣42⇡42.
        (( VCS_STATUS_COMMITS_AHEAD && !VCS_STATUS_COMMITS_BEHIND )) && res+=" "
        (( VCS_STATUS_COMMITS_AHEAD  )) && res+="${clean}⇡${VCS_STATUS_COMMITS_AHEAD}"
        # ⇠42 if behind the push remote.
        (( VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+=" ${clean}⇠${VCS_STATUS_PUSH_COMMITS_BEHIND}"
        (( VCS_STATUS_PUSH_COMMITS_AHEAD && !VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+=" "
        # ⇢42 if ahead of the push remote; no leading space if also behind: ⇠42⇢42.
        (( VCS_STATUS_PUSH_COMMITS_AHEAD  )) && res+="${clean}⇢${VCS_STATUS_PUSH_COMMITS_AHEAD}"
        # *42 if have stashes.
        (( VCS_STATUS_STASHES        )) && res+=" ${clean}*${VCS_STATUS_STASHES}"
        # 'merge' if the repo is in an unusual state.
        [[ -n $VCS_STATUS_ACTION     ]] && res+=" ${conflicted}${VCS_STATUS_ACTION}"
        # ~42 if have merge conflicts.
        (( VCS_STATUS_NUM_CONFLICTED )) && res+=" ${conflicted}~${VCS_STATUS_NUM_CONFLICTED}"
        # +42 if have staged changes.
        (( VCS_STATUS_NUM_STAGED     )) && res+=" ${modified}+${VCS_STATUS_NUM_STAGED}"
        # !42 if have unstaged changes.
        (( VCS_STATUS_NUM_UNSTAGED   )) && res+=" ${modified}!${VCS_STATUS_NUM_UNSTAGED}"
        # ?42 if have untracked files. It's really a question mark, your font isn't broken.
        # See POWERLEVEL9K_VCS_UNTRACKED_ICON above if you want to use a different icon.
        # Remove the next line if you don't want to see untracked files at all.
        (( VCS_STATUS_NUM_UNTRACKED  )) && res+=" ${untracked}${(g::)POWERLEVEL9K_VCS_UNTRACKED_ICON}${VCS_STATUS_NUM_UNTRACKED}"
        # "─" if the number of unstaged files is unknown. This can happen due to
        # POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY (see below) being set to a non-negative number lower
        # than the number of files in the Git index, or due to bash.showDirtyState being set to false
        # in the repository config. The number of staged and untracked files may also be unknown
        # in this case.
        (( VCS_STATUS_HAS_UNSTAGED == -1 )) && res+=" ${modified}─"

        typeset -g my_git_format=$res
    }
    functions -M my_git_formatter 2>/dev/null

    # Don't count the number of unstaged, untracked and conflicted files in Git repositories with
    # more than this many files in the index. Negative value means infinity.
    #
    # If you are working in Git repositories with tens of millions of files and seeing performance
    # sagging, try setting POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY to a number lower than the output
    # of `git ls-files | wc -l`. Alternatively, add `bash.showDirtyState = false` to the repository's
    # config: `git config bash.showDirtyState false`.
    typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=-1

    # Don't show Git status in prompt for repositories whose workdir matches this pattern.
    # For example, if set to '~', the Git repository at $HOME/.git will be ignored.
    # Multiple patterns can be combined with '|': '~(|/foo)|/bar/baz/*'.
    typeset -g POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN='~'

    # Disable the default Git status formatting.
    typeset -g POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=true
    # Install our own Git status formatter.
    typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${$((my_git_formatter(1)))+${my_git_format}}'
    typeset -g POWERLEVEL9K_VCS_LOADING_CONTENT_EXPANSION='${$((my_git_formatter(0)))+${my_git_format}}'
    # Enable counters for staged, unstaged, etc.
    typeset -g POWERLEVEL9K_VCS_{STAGED,UNSTAGED,UNTRACKED,CONFLICTED,COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=-1

    # Icon color.
    typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_COLOR=76
    typeset -g POWERLEVEL9K_VCS_LOADING_VISUAL_IDENTIFIER_COLOR=244
    # Custom icon.
    typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_EXPANSION=
    # Custom prefix.
    # typeset -g POWERLEVEL9K_VCS_PREFIX='%fon '

    # Show status of repositories of these types. You can add svn and/or hg if you are
    # using them. If you do, your prompt may become slow even when your current directory
    # isn't in an svn or hg reposotiry.
    typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)

    # These settings are used for repositories other than Git or when gitstatusd fails and
    # Powerlevel10k has to fall back to using vcs_info.
    typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=76
    typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=76
    typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=178

    ##########################[ status: exit code of the last command ]###########################
    # Enable OK_PIPE, ERROR_PIPE and ERROR_SIGNAL status states to allow us to enable, disable and
    # style them independently from the regular OK and ERROR state.
    typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true

    # Status on success. No content, just an icon. No need to show it if prompt_char is enabled as
    # it will signify success by turning green.
    typeset -g POWERLEVEL9K_STATUS_OK=false
    typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=70
    typeset -g POWERLEVEL9K_STATUS_OK_VISUAL_IDENTIFIER_EXPANSION='√'

    # Status when some part of a pipe command fails but the overall exit status is zero. It may look
    # like this: 1|0.
    typeset -g POWERLEVEL9K_STATUS_OK_PIPE=true
    typeset -g POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND=70
    typeset -g POWERLEVEL9K_STATUS_OK_PIPE_VISUAL_IDENTIFIER_EXPANSION='√'

    # Status when it's just an error code (e.g., '1'). No need to show it if prompt_char is enabled as
    # it will signify error by turning red.
    typeset -g POWERLEVEL9K_STATUS_ERROR=false
    typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=160
    typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='x'

    # Status when the last command was terminated by a signal.
    typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true
    typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=160
    # Use terse signal names: "INT" instead of "SIGINT(2)".
    typeset -g POWERLEVEL9K_STATUS_VERBOSE_SIGNAME=true

    # Status when some part of a pipe command fails and the overall exit status is also non-zero.
    # It may look like this: 1|0.
    typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE=true
    typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=160
    typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_VISUAL_IDENTIFIER_EXPANSION='х'

    ###################[ command_execution_time: duration of the last command ]###################
    # Show duration of the last command if takes at least this many seconds.
    typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
    # Show this many fractional digits. Zero means round to seconds.
    typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
    # Execution time color.
    typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=101
    # Duration format: 1d 2h 3m 4s.
    typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
    # Custom icon.
    typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_VISUAL_IDENTIFIER_EXPANSION=
    # Custom prefix.
    # typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PREFIX='%ftook '

    #######################[ background_jobs: presence of background jobs ]#######################
    # Don't show the number of background jobs.
    typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false
    # Background jobs color.
    typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=70
    # Custom icon.
    typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VISUAL_IDENTIFIER_EXPANSION='≡'

    #################[ ranger: ranger shell (https://github.com/ranger/ranger) ]##################
    # Ranger shell color.
    typeset -g POWERLEVEL9K_RANGER_FOREGROUND=081
    # Custom icon.
    typeset -g POWERLEVEL9K_RANGER_VISUAL_IDENTIFIER_EXPANSION='rngr'

    ######################[ nnn: nnn shell (https://github.com/jarun/nnn) ]#######################
    # Nnn shell color.
    typeset -g POWERLEVEL9K_NNN_FOREGROUND=72
    # Custom icon.
    typeset -g POWERLEVEL9K_NNN_VISUAL_IDENTIFIER_EXPANSION='nnn'

    ###########################[ vim_shell: vim shell indicator (:sh) ]###########################
    # Vim shell indicator color.
    typeset -g POWERLEVEL9K_VIM_SHELL_FOREGROUND=28
    # Custom icon.
    typeset -g POWERLEVEL9K_VIM_SHELL_VISUAL_IDENTIFIER_EXPANSION='vim'

    ######[ midnight_commander: midnight commander shell (https://midnight-commander.org/) ]######
    # Midnight Commander shell color.
    typeset -g POWERLEVEL9K_MIDNIGHT_COMMANDER_FOREGROUND=230
    # Custom icon.
    typeset -g POWERLEVEL9K_MIDNIGHT_COMMANDER_VISUAL_IDENTIFIER_EXPANSION='mc'

    ##################################[ context: user@hostname ]##################################
    # Context color when running with privileges.
    typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=178
    # Context color in SSH without privileges.
    typeset -g POWERLEVEL9K_CONTEXT_{REMOTE,REMOTE_SUDO}_FOREGROUND=180
    # Default context color (no privileges, no SSH).
    typeset -g POWERLEVEL9K_CONTEXT_FOREGROUND=180

    # Context format when running with privileges: bold user@hostname.
    typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE='%B%n@%m'
    # Context format when in SSH without privileges: user@hostname.
    typeset -g POWERLEVEL9K_CONTEXT_{REMOTE,REMOTE_SUDO}_TEMPLATE='%n@%m'
    # Default context format (no privileges, no SSH): user@hostname.
    typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%n@%m'

    # Don't show context unless running with privileges or in SSH.
    # Tip: Remove the next line to always show context.
    typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_{CONTENT,VISUAL_IDENTIFIER}_EXPANSION=

    # Custom icon.
    # typeset -g POWERLEVEL9K_CONTEXT_VISUAL_IDENTIFIER_EXPANSION='⭐'
    # Custom prefix.
    # typeset -g POWERLEVEL9K_CONTEXT_PREFIX='%fwith '

    ###[ virtualenv: python virtual environment (https://docs.python.org/3/library/venv.html) ]###
    # Python virtual environment color.
    typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=37
    # Don't show Python version next to the virtual environment name.
    typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
    # If set to "false", won't show virtualenv if pyenv is already shown.
    # If set to "if-different", won't show virtualenv if it's the same as pyenv.
    typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_WITH_PYENV='if-different'
    # Separate environment name from Python version only with a space.
    typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=
    # Custom icon.
    # typeset -g POWERLEVEL9K_VIRTUALENV_VISUAL_IDENTIFIER_EXPANSION='⭐'

    ######################[ pyenv, rbenv, goenv, nodenv,plenv,luaenv,jenv ]#######################
    typeset -g POWERLEVEL9K_{PYENV,RBENV,GOENV,NODENV,PLENV,LUAENV,JENV}_FOREGROUND=37
    typeset -g POWERLEVEL9K_{PYENV,RBENV,GOENV,NODENV,PLENV,LUAENV,JENV}_PROMPT_ALWAYS_SHOW=false

    # Pyenv segment format. The following parameters are available within the expansion.
    #
    # - P9K_CONTENT                Current pyenv environment (pyenv version-name).
    # - P9K_PYENV_PYTHON_VERSION   Current python version (python --version).
    #
    # The default format has the following logic:
    #
    # 1. Display "$P9K_CONTENT $P9K_PYENV_PYTHON_VERSION" if $P9K_PYENV_PYTHON_VERSION is not
    #   empty and unequal to $P9K_CONTENT.
    # 2. Otherwise display just "$P9K_CONTENT".
    typeset -g POWERLEVEL9K_PYENV_CONTENT_EXPANSION='${P9K_CONTENT}${${P9K_PYENV_PYTHON_VERSION:#$P9K_CONTENT}:+ $P9K_PYENV_PYTHON_VERSION}'

    #############[ kubecontext: current kubernetes context (https://kubernetes.io/) ]#############
    # Show kubecontext only when the the command you are typing invokes one of these tools.
    # Tip: Remove the next line to always show kubecontext.
    typeset -g POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND='kubectl|helm|kubens|kubectx|oc|istioctl|kogito|k9s|helmfile|fluxctl|stern'

    ################[ terraform: terraform workspace (https://www.terraform.io) ]#################
    # Don't show terraform workspace if it's literally "default".
    typeset -g POWERLEVEL9K_TERRAFORM_SHOW_DEFAULT=false
    typeset -g POWERLEVEL9K_TERRAFORM_SHOW_ON_COMMAND='terraform|make'

    #[ aws: aws profile (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) ]#
    # Show aws only when the the command you are typing invokes one of these tools.
    typeset -g POWERLEVEL9K_AWS_SHOW_ON_COMMAND='aws|awless|terraform|pulumi|terragrunt|make'
    typeset -g POWERLEVEL9K_AWS_FOREGROUND=208

    # Transient prompt works similarly to the builtin transient_rprompt option. It trims down prompt
    # when accepting a command line. Supported values:
    #
    #   - off:      Don't change prompt when accepting a command line.
    #   - always:   Trim down prompt when accepting a command line.
    #   - same-dir: Trim down prompt when accepting a command line unless this is the first command
    #               typed after changing current working directory.
    typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=same-dir

    # Instant prompt mode.
    #
    #   - off:     Disable instant prompt. Choose this if you've tried instant prompt and found
    #              it incompatible with your zsh configuration files.
    #   - quiet:   Enable instant prompt and don't print warnings when detecting console output
    #              during zsh initialization. Choose this if you've read and understood
    #              https://github.com/romkatv/powerlevel10k/blob/master/README.md#instant-prompt.
    #   - verbose: Enable instant prompt and print a warning when detecting console output during
    #              zsh initialization. Choose this if you've never tried instant prompt, haven't
    #              seen the warning, or if you are unsure what this all means.
    typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose

    # Hot reload allows you to change POWERLEVEL9K options after Powerlevel10k has been initialized.
    # For example, you can type POWERLEVEL9K_BACKGROUND=red and see your prompt turn red. Hot reload
    # can slow down prompt by 1-2 milliseconds, so it's better to keep it turned off unless you
    # really need it.
    typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true
}

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'

# Some handy suffix aliases
alias -s log=less

# Human file sizes
alias df="df -Th"
alias du="du -hc"

# Handy stuff and a bit of XDG compliance
alias grep="grep --color=auto --binary-files=without-match --devices=skip"
(( ${+commands[tmux]} )) && {
    alias tmux="tmux -f ${DOTFILES}/tmux/tmux.conf"
    alias stmux="tmux new-session 'sudo -i'"
}
(( ${+commands[wget]} )) && alias wget="wget --hsts-file=${XDG_CACHE_HOME}/wget-hsts"
alias ls="ls --group-directories-first --color=auto --classify"
alias ll="LC_COLLATE=C ls -l -v --almost-all --human-readable"

# History suppression
alias clear=" clear"
alias pwd=" pwd"
alias exit=" exit"

# Safety
alias rm="rm -I"

# Suppress suggestions and globbing
alias find="noglob find"
alias touch="nocorrect touch"
alias mkdir="nocorrect mkdir"
alias cp="nocorrect cp"
(( ${+commands[ag]} )) && alias ag="noglob ag"
(( ${+commands[fd]} )) && alias fd="noglob fd"

# sudo wrapper which is able to expand aliases and handle noglob/nocorrect builtins
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
alias sudo="noglob do_sudo "

evalcache () {
    local cache_dir="${XDG_CACHE_HOME}/zsh/eval"
    local cache_file="${cache_dir}/${(j:_:)@:gs/\//_}.zsh"

    if [[ -r "${cache_file}" ]] && ! whence ${1} > /dev/null; then
        # remove cache file when it's present, but arg isn't executable
        echo "evalcache ERROR: $1 isn't executable, removing cache file" >&2
        zf_rm -f "${cache_file}*"
    elif [[ ! -e "${cache_file}" || -n "${cache_file}"(#qN.mh+20) ]]; then
        # revalidate cache every 20 hours
        # cache miss
        if (( ${+commands[${1}]} )); then
            zf_mkdir -p "${cache_dir}"
            command "$@" > "${cache_file}"
            source "${cache_file}"
            # zrecompile cache file in background
            {
                autoload -Uz zrecompile
                zrecompile -pq "${cache_file}"
            } &!
        else
            echo "evalcache ERROR: $1 is not available in PATH" >&2
        fi
    else
        # cache hit
        source "${cache_file}"
    fi
}

compdefcache () {
    local cache_dir="${XDG_CACHE_HOME}/zsh/fpath"
    local cache_file="${cache_dir}/_${1##/*}"

    # revalidate cache every 20 hours
    if [[ -r "${cache_file}" ]] && ! whence ${1} > /dev/null; then
        # remove cache file when it's present, but arg isn't executable
        echo "compdefcache ERROR: $1 isn't executable, removing cache file" >&2
        zf_rm -f "${cache_file}"
    elif [[ ! -e "${cache_file}" || -n "${cache_file}"(#qN.mh+20) ]]; then
        # revalidate cache every 20 hours
        # cache miss, create compdef file
        if (( ${+commands[${1}]} )); then
            zf_mkdir -p "${cache_dir}"
            command "$@" > "${cache_file}"
        else
            echo "compdefcache ERROR: $1 is not available in PATH" >&2
        fi
    else
        # cache hit, do nothing
    fi
}

# Color man
# Set originally "bold" as "bold and red"
# Set originally "underline" as "underline and green"
man () {
    # termcap codes
    # md    start bold
    # mb    start blink
    # me    turn off bold, blink and underline
    # so    start standout (reverse video)
    # se    stop standout
    # us    start underline
    # ue    stop underline
    LESS_TERMCAP_md=$(echoti bold; echoti setaf 1) \
    LESS_TERMCAP_mb=$(echoti blink) \
    LESS_TERMCAP_me=$(echoti sgr0) \
    LESS_TERMCAP_so=$(echoti smso) \
    LESS_TERMCAP_se=$(echoti rmso) \
    LESS_TERMCAP_us=$(echoti smul; echoti setaf 2) \
    LESS_TERMCAP_ue=$(echoti sgr0) \
    nocorrect noglob command man ${@}
}

# Enable color support of ls
if (( ${+commands[dircolors]} )); then
    evalcache dircolors "${ZDOTDIR}/plugins/dircolors-solarized/dircolors.256dark"
fi

# Enable diff with colors
if (( ${+commands[colordiff]} )); then
    alias diff="colordiff -Naur"
fi

# Make less more friendly
if (( $#commands[(i)lesspipe(|.sh)] )); then
    export LESSOPEN="| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-"
    export LESS_ADVANCED_PREPROCESSOR=1
fi

# Don't indicate virtualenv in pyenv, indication is done in pure
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Lazy init wrapper on first call
() {
    local wrapper
    local wrappers=(goenv nodenv pyenv)
    for wrapper in "${wrappers[@]}"; do
        eval "${wrapper} () {
            unset -f ${wrapper}
            export ${wrapper:u}_ROOT=\"\${XDG_DATA_HOME}/${wrapper}\"
            evalcache ${wrapper} init -
            ${wrapper} \${@}
            if [[ $wrapper == \"pyenv\" ]]; then
                evalcache ${wrapper} init --path
            fi
        }"
    done
}

# Alias commands supported by grc
if (( ${+commands[grc]} )); then
    () {
        local grc_commands=(blkid df dig dnf du env free gcc getfacl getsebool
                            ifconfig ip iptables last lsattr lsblk lsmod lspci
                            mount mtr netstat nmap ping ps pv semanage ss stat
                            sysctl systemctl tcpdump traceroute tune2fs ulimit
                            uptime vmstat w wdiff who)
        local grc_command

        for grc_command in ${grc_commands[@]}; do
            if (( ${+commands[$grc_command]} )); then
                $grc_command() {
                    grc --colour=auto ${commands[$0]} "${@}"
                }
            fi
        done
    }
fi
# Completion tweaks
zstyle ':completion:*:default'      list-colors         "${(s.:.)LS_COLORS}"
zstyle ':completion:*'              list-dirs-first     true
zstyle ':completion:*'              verbose             true
zstyle ':completion::complete:*'    use-cache           true
zstyle ':completion::complete:*'    cache-path          "${XDG_CACHE_HOME}/zsh/compcache"
zstyle ':completion:*:descriptions' format              [%d]
zstyle ':completion:*:manuals'      separate-sections   true

# Enable cached completions, if present
if [[ -d "${XDG_CACHE_HOME}/zsh/fpath" ]]; then
    fpath+="${XDG_CACHE_HOME}/zsh/fpath"
fi

# Additional completions
fpath+="${ZDOTDIR}/plugins/completions/src"

# Make sure complist is loaded
zmodload zsh/complist

# Init completions, but regenerate compdump only once a day.
# The globbing is a little complicated here:
# - '#q' is an explicit glob qualifier that makes globbing work within zsh's [[ ]] construct.
# - 'N' makes the glob pattern evaluate to nothing when it doesn't match (rather than throw a globbing error)
# - '.' matches "regular files"
# - 'mh+20' matches files (or directories or whatever) that are older than 20 hours.
autoload -Uz compinit
if [[ -n "${XDG_CACHE_HOME}/zsh/compdump"(#qN.mh+20) ]]; then
    compinit -i -u -d "${XDG_CACHE_HOME}/zsh/compdump"
    # zrecompile fresh compdump in background
    {
        autoload -Uz zrecompile
        zrecompile -pq "${XDG_CACHE_HOME}/zsh/compdump"
    } &!
else
    compinit -i -u -C -d "${XDG_CACHE_HOME}/zsh/compdump"
fi

# Enable bash completions too
autoload -Uz bashcompinit
bashcompinit

export FZF_DEFAULT_OPTS="--ansi"
# Try to use fd or ag, if available as default fzf command
if (( ${+commands[fd]} )); then
    export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --exclude .git --color=always'
    export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
elif (( ${+commands[ag]} )); then
    export FZF_DEFAULT_COMMAND='ag --ignore .git -g ""'
    export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
fi

# Enable fzf key bindings and completions
source "/usr/local/opt/fzf/shell/key-bindings.zsh"
source "/usr/local/opt/fzf/shell/completion.zsh"

# Use fzf for tab completions
source "${ZDOTDIR}/plugins/fzf-tab/fzf-tab.zsh"
zstyle ':fzf-tab:*' prefix ''

# Enable autoenv plugin
source "${ZDOTDIR}/plugins/autoenv/autoenv.zsh"

# Autopairs plugin
source "${ZDOTDIR}/plugins/autopair/autopair.zsh"

source "${ZDOTDIR}/plugins/abbr/zsh-abbr.zsh"
export MANPATH=${ZDOTDIR}/plugins/abbr/man:$MANPATH

# monkey patch abbr for better autosuggestion compatibility
_abbr_widget_expand_and_space() {
  emulate -LR zsh
  _abbr_widget_expand
  'builtin' 'command' -v _zsh_autosuggest_fetch &>/dev/null && _zsh_autosuggest_fetch
  zle self-insert
}

# Highlighting plugin
source "${ZDOTDIR}/plugins/syntax-highlighting/zsh-syntax-highlighting.zsh"
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets regexp cursor)
# Highlight known abbrevations
typeset -A ZSH_HIGHLIGHT_REGEXP
ZSH_HIGHLIGHT_REGEXP+=('(^| )('${(j:|:)${(k)ABBR_REGULAR_USER_ABBREVIATIONS}}')($| )' 'fg=blue')

# Enable experimental async autosuggestions
ZSH_AUTOSUGGEST_USE_ASYNC=1
# Don't rebind widgets by autosuggestion, it's already sourced pretty late
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
# Enable experimental completion suggestions, if `history` returns nothing
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Ignore suggestions for abbreviations
ZSH_AUTOSUGGEST_HISTORY_IGNORE=${(j:|:)${(k)ABBR_REGULAR_USER_ABBREVIATIONS}}
ZSH_AUTOSUGGEST_COMPLETION_IGNORE=${ZSH_AUTOSUGGEST_HISTORY_IGNORE}

# Autosuggestions plugin
source "${ZDOTDIR}/plugins/autosuggestions/zsh-autosuggestions.zsh"

# Clear suggestions after paste
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(
    bracketed-paste
)

# Force path arrays to have unique values only
typeset -U path cdpath fpath manpath

