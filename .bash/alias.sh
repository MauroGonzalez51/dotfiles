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
