if [[ -d "$HOME/.cargo/bin" ]]; then
    export PATH="$PATH:$HOME/.cargo/bin"
fi

export PATH="$PATH:$HOME/.local/share/pnpm/bin"
export PATH=$HOME/.local/bin:$PATH
