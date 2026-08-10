alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
alias yayf="yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:75% | xargs -ro yay -S"

sudo() {
    if ! command sudo -n true 2>/dev/null; then
        notify-send -u critical "Password Required"
    fi

    command sudo "$@"
}

code() {
    if type -P code &>/dev/null; then
        command code "$@"
        return $?
    fi

    if type -P code-insiders &>/dev/null; then
        command code-insiders "$@"
        return $?
    fi

    echo "bash: code: command not found" >&2
    return 127
}
