#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export EDITOR="code"

export POSH_THEMES_PATH=/usr/share/oh-my-posh/themes/

# Adding homebrew to $PATH
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

eval "$(oh-my-posh init bash --config $POSH_THEMES_PATH/tokyonight_storm.omp.json)"

if command -v pyenv 1>/dev/null 2>&1; then
   eval "$(pyenv init - bash)" 
fi

source /usr/share/nvm/init-nvm.sh

# Yazi setup
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# pyenv setup
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

export RUST_RCLOUD_CONFIG="/etc/rust-rcloud/config.json"

# proto
export PROTO_HOME="$HOME/.proto";
export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH";

neofetch --config $HOME/.config/neofetch/config.conf
