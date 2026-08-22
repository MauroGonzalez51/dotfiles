export EDITOR="nvim"
export VISUAL="nvim"
export DOCKER_BUILDKIT=1

# tired of using it every time
export PUPPETEER_SKIP_DOWNLOAD=true
if [ -x /usr/bin/chromium ]; then
    export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
fi
