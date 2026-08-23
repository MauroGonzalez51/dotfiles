if command -v oh-my-posh >/dev/null 2>&1; then
    _omp_theme=~/.local/state/caelestia/theme/theme.omp.json
    _omp_args=()
    # No caelestia scheme generated yet (fresh machine) - fall back to oh-my-posh's default theme
    [ -f "$_omp_theme" ] && _omp_args=(--config "$_omp_theme")
    eval "$(oh-my-posh init bash "${_omp_args[@]}")"
    unset _omp_theme _omp_args
fi
