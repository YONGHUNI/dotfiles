# ~/.bashrc — shared interactive Bash configuration

# Keep a small user-local bin directory available without duplicating PATH entries.
[[ ":$PATH:" != *":$HOME/bin:"* ]] && export PATH="$HOME/bin:$PATH"

# The rest of this file is interactive-shell behavior only.
[[ $- != *i* ]] && return

# ==========================================================
# Custom Bash Prompt: Powerline with environment + Git status
# ==========================================================

BG_REMOTE="\[\033[41m\]"
BG_LOCAL="\[\033[42m\]"
BG_MEM="\[\033[44m\]"
BG_SHELL="\[\033[46m\]"
BG_PY="\[\033[43m\]"
BG_GRAY="\[\033[100m\]"
FG_WHITE="\[\033[97m\]"
FG_BLACK="\[\033[30m\]"
FG_GREEN="\[\033[32m\]"
FG_MAGENTA="\[\033[35m\]"
FG_RED="\[\033[31m\]"
FG_BLUE="\[\033[34m\]"
FG_CYAN="\[\033[36m\]"
FG_YELLOW="\[\033[33m\]"
FG_GRAY="\[\033[90m\]"
RESET="\[\033[0m\]"

SEP_R=""
SEP_L=""

function timer_start() {
    if [[ -z ${timer_start_time:-} ]]; then
        if [[ -n ${EPOCHREALTIME:-} ]]; then
            timer_start_time=${EPOCHREALTIME/./}
            timer_start_time=${timer_start_time:0:-3}
        else
            timer_start_time=$(date +%s%3N 2>/dev/null)
        fi
    fi
}

function build_custom_prompt() {
    # 1. Execution time
    local timer_show="0ms"
    if [[ -n ${timer_start_time:-} ]]; then
        local timer_end_time
        if [[ -n ${EPOCHREALTIME:-} ]]; then
            timer_end_time=${EPOCHREALTIME/./}
            timer_end_time=${timer_end_time:0:-3}
        else
            timer_end_time=$(date +%s%3N 2>/dev/null)
        fi

        local elapsed=$((timer_end_time - timer_start_time))
        local ms=$((elapsed % 1000))
        local s=$((elapsed / 1000))

        if ((s > 0)); then
            printf -v timer_show '%d.%03ds' "$s" "$ms"
        else
            timer_show="${ms}ms"
        fi
        unset timer_start_time
    fi

    # 2. Memory usage
    local mem_raw="  MEM: N/A "
    if [[ -f /proc/meminfo ]]; then
        local mem_total=0 mem_avail=0
        while IFS=" :" read -r key val _; do
            case "$key" in
                MemTotal) mem_total=$val ;;
                MemAvailable) mem_avail=$val ;;
            esac
            [[ $mem_total -gt 0 && $mem_avail -gt 0 ]] && break
        done < /proc/meminfo

        if ((mem_total > 0)); then
            local mem_used=$((mem_total - mem_avail))
            local pct=$((mem_used * 100 / mem_total))
            local used_gb_10=$((mem_used * 10 / 1048576))
            local total_gb_10=$((mem_total * 10 / 1048576))
            local used_gb="${used_gb_10%?}.${used_gb_10: -1}"
            local total_gb="${total_gb_10%?}.${total_gb_10: -1}"

            [[ ${used_gb::1} == "." ]] && used_gb="0${used_gb}"
            [[ ${total_gb::1} == "." ]] && total_gb="0${total_gb}"
            mem_raw="  MEM: ${pct}% | ${used_gb}/${total_gb}GB "
        fi
    fi

    # 3. Host info (red=remote, green=local)
    local short_host=${HOSTNAME%%.*}
    local host_raw host_bg host_sep_fg
    if [[ -n ${SSH_CLIENT:-} || -n ${SSH_TTY:-} ]]; then
        host_raw="  ${short_host} "
        host_bg=$BG_REMOTE
        host_sep_fg=$FG_RED
    else
        host_raw="  ${short_host} "
        host_bg=$BG_LOCAL
        host_sep_fg=$FG_GREEN
    fi

    local timer_raw=" ⏱ ${timer_show} "
    local left_len=$(( ${#host_raw} + ${#mem_raw} + ${#timer_raw} + 3 ))

    local left_render=""
    left_render+="${host_bg}${FG_WHITE}${host_raw}"
    left_render+="${BG_MEM}${host_sep_fg}${SEP_R}${FG_WHITE}${mem_raw}"
    left_render+="${BG_GRAY}${FG_BLUE}${SEP_R}${FG_WHITE}${timer_raw}"
    left_render+="${RESET}${FG_GRAY}${SEP_R}${RESET}"

    # 4. Shell / project environment context
    # Pixi exports PIXI_PROJECT_NAME / PIXI_ENVIRONMENT_NAME.
    # Nix shells export IN_NIX_SHELL. Set NIX_SHELL_NAME in a shellHook if
    # a project wants a custom Nix shell label.
    local shell_raw=""
    local shell_label=""

    if [[ -n ${IN_NIX_SHELL:-} ]]; then
        shell_label="nix"
        [[ -n ${NIX_SHELL_NAME:-} ]] && shell_label="nix:${NIX_SHELL_NAME}"
    fi

    if [[ -n ${PIXI_ENVIRONMENT_NAME:-} || -n ${PIXI_PROJECT_NAME:-} ]]; then
        local pixi_label=${PIXI_PROJECT_NAME:-${PIXI_ENVIRONMENT_NAME:-default}}
        if [[ -n ${PIXI_PROJECT_NAME:-} && -n ${PIXI_ENVIRONMENT_NAME:-} && ${PIXI_ENVIRONMENT_NAME} != "default" ]]; then
            pixi_label+="/${PIXI_ENVIRONMENT_NAME}"
        fi

        if [[ -n $shell_label ]]; then
            shell_label+=" + pixi:${pixi_label}"
        else
            shell_label="pixi:${pixi_label}"
        fi
    fi

    [[ -n $shell_label ]] && shell_raw="  ${shell_label} "

    # 5. Python environment
    # Pixi already gets a dedicated shell module, so suppress the Conda-style
    # duplicate that Pixi may expose through CONDA_DEFAULT_ENV.
    local py_raw=""
    if [[ -z ${PIXI_ENVIRONMENT_NAME:-} && -z ${PIXI_PROJECT_NAME:-} ]]; then
        if [[ -n ${VIRTUAL_ENV:-} ]]; then
            py_raw="  $(basename "$VIRTUAL_ENV") "
        elif [[ -n ${CONDA_DEFAULT_ENV:-} ]]; then
            py_raw="  ${CONDA_DEFAULT_ENV} "
        fi
    fi

    # 6. Git info (branch + staged/modified/untracked)
    local git_raw=""
    local git_branch
    git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    if [[ -n $git_branch ]]; then
        local staged=0 modified=0 untracked=0
        while IFS= read -r line; do
            local idx="${line:0:1}"
            local wt="${line:1:1}"

            if [[ $line == "??"* ]]; then
                ((untracked++))
            else
                [[ $idx != " " && $idx != "?" ]] && ((staged++))
                [[ $wt != " " && $wt != "?" ]] && ((modified++))
            fi
        done < <(git status --porcelain=v1 2>/dev/null)

        git_raw="  ${git_branch}"
        [[ $staged -gt 0 ]] && git_raw+=" +${staged}"
        [[ $modified -gt 0 ]] && git_raw+=" ~${modified}"
        [[ $untracked -gt 0 ]] && git_raw+=" ?${untracked}"
        git_raw+=" "
    fi

    # 7. Right-side modules
    local right_modules=""
    local right_len=0

    if [[ -n $shell_raw ]]; then
        right_modules+="${FG_CYAN}${SEP_L}${BG_SHELL}${FG_BLACK}${shell_raw}"
        ((right_len += ${#shell_raw} + 1))
    fi

    if [[ -n $py_raw ]]; then
        right_modules+="${FG_YELLOW}${SEP_L}${BG_PY}${FG_BLACK}${py_raw}"
        ((right_len += ${#py_raw} + 1))
    fi

    if [[ -n $git_raw ]]; then
        right_modules+="${FG_GRAY}${SEP_L}${BG_GRAY}${FG_GREEN}${git_raw}"
        ((right_len += ${#git_raw} + 1))
    fi

    [[ -n $right_modules ]] && right_modules+="${RESET}"

    # Bash string length is only an approximation for Nerd Font glyph width.
    # Keep a small gap so the two prompt sides never collide visually.
    local cols=${COLUMNS:-$(tput cols 2>/dev/null || printf '80')}
    local gap=3
    local right_col=$((cols - right_len + 1))
    [[ $right_col -lt 1 ]] && right_col=1

    # 8. Build PS1
    # Wide terminal: right modules stay on the first line.
    # Narrow terminal: right modules move to their own right-aligned line.
    PS1="${left_render}"

    if [[ -n $right_modules ]]; then
        if ((left_len + gap + right_len <= cols)); then
            PS1+="\[\033[${right_col}G\]${right_modules}"
        else
            PS1+="\n\[\033[${right_col}G\]${right_modules}"
        fi
    fi

    PS1+="\n╭─ ♥ \t |  \j | ${FG_MAGENTA}\w${RESET}\n╰─\$ "
}

# Preserve other prompt hooks installed by tools such as terminal integrations.
if [[ ${PROMPT_COMMAND:-} != *build_custom_prompt* ]]; then
    PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND};}build_custom_prompt"
fi

# Start timing when Bash begins executing the next command.
trap 'timer_start' DEBUG
