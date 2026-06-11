export ANDROID_HOME=/opt/android-sdk

if pacman -Qi android-sdk &> /dev/null; then
    subdirs=("tools" "tools/bin" "platform-tools")

    for dir in "${subdirs[@]}"; do
        path="$ANDROID_HOME/$dir"
        if [ -d "$path" ]; then
            export PATH="$PATH:$path"
        fi
    done
fi
