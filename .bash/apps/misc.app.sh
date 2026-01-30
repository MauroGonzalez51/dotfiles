if command -v shopt >/dev/null 2>&1; then
    shopt -s autocd
fi

if [ -f  /usr/share/doc/pkgfile/command-not-found.bash ]; then
    source /usr/share/doc/pkgfile/command-not-found.bash
fi
