if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
    export HOMEBREW_CURLRC=1
    export HOMEBREW_NO_REQUIRE_TAP_TRUST=1
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
