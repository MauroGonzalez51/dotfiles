# If not running interactively, don't do anything
[[ $- != *i* ]] && return

source ~/.bash/apps/ble.manual.sh

for app in ~/.bash/apps/*.app.sh; do
    [ -f "$app" ] && source "$app"
done

if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion

    for completion in ~/.bash/completions/*.sh; do
        [ -f "$completion" ] && source "$completion"
    done
fi

source ~/.bash/alias.sh
source ~/.bash/env.sh
source ~/.bash/path.sh

if command -v fastfetch >/dev/null 2>&1 \
    && [ -z "$TMUX" ] \
    && [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    fastfetch --config ~/.config/fastfetch/config.jsonc
fi

source ~/.bash/apps/zoxide.manual.sh

[[ ${BLE_VERSION-} ]] && ble-attach
