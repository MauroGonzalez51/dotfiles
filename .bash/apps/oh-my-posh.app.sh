if command -v oh-my-posh >/dev/null 2>&1; then
    export POSH_THEMES_PATH=/usr/share/oh-my-posh/themes/
    eval "$(oh-my-posh init bash --config $POSH_THEMES_PATH/nordtron.omp.json)"
fi
