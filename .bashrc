# If not running interactively, don't do anything
[[ $- != *i* ]] && return

source ~/.bash/apps/env.sh

source ~/.bash/apps/oh-my-posh.sh
source ~/.bash/apps/homebrew.sh
source ~/.bash/apps/nvm.sh
source ~/.bash/apps/yazi.sh
source ~/.bash/apps/pyenv.sh
source ~/.bash/apps/proto.sh

source ~/.bash/completions/moon-completion.sh
source ~/.bash/completions/ruff-completion.sh

source ~/.bash/alias.sh
source ~/.bash/path.sh

neofetch --config $HOME/.config/neofetch/config.conf

source ~/.bash/apps/zoxide.sh
