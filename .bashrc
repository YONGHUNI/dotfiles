# ~/.bashrc — unified (WSL + HPC)

# PATH guard against duplication
[[ ":$PATH:" != *":$HOME/bin:"* ]] && export PATH="$HOME/bin:$PATH"

# Module loads (HPC only)
if type module &>/dev/null; then
    module load clang/20 julia/1.11 R/4.5 2>/dev/null
fi

# Kerberos ticket reminder for MPCDF SSH access.
if [[ $- == *i* ]] && command -v klist >/dev/null 2>&1; then
    if ! klist -s; then
        echo "[kerberos] No valid ticket found. Run: kinit USER@REALM"
    fi
fi

# ==========================================================
# Custom Bash Prompt: Powerline with Git Status
# ==========================================================

BG_SSH="\[\033[41m\]"
FG_SSH="\[\033[97m\]"
BG_MEM="\[\033[44m\]"
FG_MEM="\[\033[97m\]"
BG_PY="\[\033[43m\]"
FG_PY="\[\033[30m\]"
BG_GRAY="\[\033[100m\]"
FG_WHITE="\[\033[97m\]"
FG_GREEN="\[\033[32m\]"
FG_MAGENTA="\[\033[35m\]"
RESET="\[\033[0m\]"

SEP_R=""
SEP_L=""

function timer_start() {
    if [[ -z $timer_start_time ]]; then
        if [[ -n "${EPOCHREALTIME:-}" ]]; then
            timer_start_time=${EPOCHREALTIME/./}
            timer_start_time=${timer_start_time:0:-3}
        else
            timer_start_time=$(date +%s%3N 2>/dev/null)
        fi
    fi
}

function build_custom_prompt() {
    # 1. Execution Time
    local timer_show="0ms"
    if [[ -n $timer_start_time ]]; then
        local timer_end_time
        if [[ -n "${EPOCHREALTIME:-}" ]]; then
            timer_end_time=${EPOCHREALTIME/./}
            timer_end_time=${timer_end_time:0:-3}
        else
            timer_end_time=$(date +%s%3N 2>/dev/null)
        fi
        local elapsed=$((timer_end_time - timer_start_time))
        local ms=$((elapsed % 1000))
        local s=$((elapsed / 1000))
        if ((s > 0)); then
            timer_show="${s}.${ms}s"
        else
            timer_show="${ms}ms"
        fi
        unset timer_start_time
    fi

    # 2. Memory Usage
    local mem_info="  MEM: N/A "
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
            [[ ${used_gb::1} == "." ]] && used_gb="0${used_gb}"
            local total_gb="${total_gb_10%?}.${total_gb_10: -1}"
            [[ ${total_gb::1} == "." ]] && total_gb="0${total_gb}"
            mem_info="  MEM: ${pct}% | ${used_gb}/${total_gb}GB "
        fi
    fi

    # 3. Host Info (red=remote, green=local)
    local host_info=""
    local host_bg=""
    if [[ -n "${SSH_CLIENT:-}" || -n "${SSH_TTY:-}" ]]; then
        host_info="  \h "
        host_bg="\[\033[41m\]"
        host_sep_fg="\[\033[31m\]"
    else
        host_info="  \h "
        host_bg="\[\033[42m\]"
        host_sep_fg="\[\033[32m\]"
    fi

    # 4. Python Environment
    local py_raw=""
    if [[ -n "${VIRTUAL_ENV:-}" ]]; then
        py_raw="  $(basename "$VIRTUAL_ENV") "
    elif [[ -n "${CONDA_DEFAULT_ENV:-}" ]]; then
        py_raw="  ${CONDA_DEFAULT_ENV} "
    fi

    # 5. Git Info (branch + staged/modified/untracked)
    local git_raw=""
    local git_branch
    git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    if [[ -n $git_branch ]]; then
        local staged=0 modified=0 untracked=0
        while IFS= read -r line; do
            local idx="${line:0:1}"
            local wt="${line:1:1}"
            if [[ "$line" == "??"* ]]; then
                ((untracked++))
            else
                [[ "$idx" != " " && "$idx" != "?" ]] && ((staged++))
                [[ "$wt" != " " && "$wt" != "?" ]] && ((modified++))
            fi
        done < <(git status --porcelain 2>/dev/null)

        git_raw="  ${git_branch}"
        [[ $staged -gt 0 ]] && git_raw+=" +${staged}"
        [[ $modified -gt 0 ]] && git_raw+=" ~${modified}"
        [[ $untracked -gt 0 ]] && git_raw+=" ?${untracked}"
        git_raw+=" "
    fi

    # 6. Right Modules with Powerline
    local right_modules=""
    local right_len=0

    if [[ -n $py_raw ]]; then
        right_modules+="\[\033[33m\]${SEP_L}${BG_PY}${FG_PY}${py_raw}"
        ((right_len += ${#py_raw} + 1))
        if [[ -n $git_raw ]]; then
            right_modules+="\[\033[90m\]${SEP_L}${BG_GRAY}${FG_GREEN}${git_raw}"
            ((right_len += ${#git_raw} + 1))
        fi
        right_modules+="${RESET}"
    elif [[ -n $git_raw ]]; then
        right_modules+="\[\033[90m\]${SEP_L}${BG_GRAY}${FG_GREEN}${git_raw}${RESET}"
        ((right_len += ${#git_raw} + 1))
    fi

    local cols=${COLUMNS:-$(tput cols)}
    local right_col=$(( cols - right_len ))
    [[ $right_col -lt 1 ]] && right_col=1

    # 7. Build PS1
    PS1=""
    PS1+="${host_bg}${FG_SSH}${host_info}${BG_MEM}${host_sep_fg}${SEP_R}"
    PS1+="${BG_MEM}${FG_MEM} ${mem_info} ${BG_GRAY}\[\033[34m\]${SEP_R}"
    PS1+="${FG_WHITE} ⏱ ${timer_show} ${RESET}${FG_GRAY}${SEP_R}${RESET}"

    if [[ -n $right_modules ]]; then
        PS1+="\[\033[${right_col}G\]${right_modules}"
    fi

    PS1+="\n╭─ ♥ \t |  \j | ${FG_MAGENTA}\w${RESET}\n╰─\$ "
}

trap 'timer_start' DEBUG
PROMPT_COMMAND=build_custom_prompt

# >>> mamba initialize (conditional) >>>
if [[ -x "$HOME/bin/micromamba" ]]; then
    export MAMBA_EXE="$HOME/bin/micromamba"
    export MAMBA_ROOT_PREFIX="$HOME/.local/share/mamba"
    __mamba_setup="$("$MAMBA_EXE" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__mamba_setup"
    else
        alias micromamba="$MAMBA_EXE"
    fi
    unset __mamba_setup
    mamba() { micromamba "$@"; }
    micromamba activate base
fi
# <<< mamba initialize <<<
