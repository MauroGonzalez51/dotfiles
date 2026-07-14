if [[ -d "$HOME/.cargo/bin" ]]; then
    export PATH="$PATH:$HOME/.cargo/bin"
fi

if [[ -d "/usr/lib/jvm/default/" ]]; then
    export JAVA_HOME="/usr/lib/jvm/default/"
    export PATH="$PATH:/usr/lib/jvm/default/bin"
fi

export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.local/share/pnpm/bin:$PATH
