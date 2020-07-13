#!/bin/bash

doIt() {
    rsync --exclude=".git" \
        --exclude=".gitkeep" \
        --exclude="LICENSE" \
        --exclude="README.md" \
        --exclude="install.sh" \
        -ahv . ~
}

if [ "$(uname)" == 'Darwin' ]; then
    # Mac
    doIt
    ln -fns ~/Documents ~/docs
    ln -fns ~/Desktop ~/var/desktop
else
    echo "Your platform ($(uname -a)) is not supported."
    exit 1
fi
