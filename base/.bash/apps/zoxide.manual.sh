if command -v zoxide >/dev/null 2>&1; then
    export _ZO_DOCTOR=0
    eval "$(zoxide init --cmd cd bash)"
fi
