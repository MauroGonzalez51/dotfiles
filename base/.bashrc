[[ $- != *i* ]] && return

source ~/.bash/apps/ble.manual.sh

for app in ~/.bash/apps/*.app.sh; do
    name="$(basename "$app" .app.sh)"
    [ -f "$(dirname "$app")/$name.override.sh" ] && continue
    source "$app"
done

for override in ~/.bash/apps/*.override.sh; do
    [ -f "$override" ] && source "$override"
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

if command -v fastfetch >/dev/null 2>&1 &&
    [ -z "$TMUX" ] &&
    [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ] &&
    [ -z "$NVIM" ]; then
    fastfetch --config ~/.config/fastfetch/config.jsonc
fi

source ~/.bash/apps/zoxide.manual.sh

[[ ${BLE_VERSION-} ]] && ble-attach
