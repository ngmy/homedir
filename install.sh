#!/bin/bash

HOMEDIR_PATH="${HOME}/homedir"

do_it() {
  if [ -d "${HOMEDIR_PATH}" ]; then
    echo "homedir already exists in '${HOMEDIR_PATH}'. Skip download."
  else
    echo "Downloading homedir to '${HOMEDIR_PATH}'..."
    git clone https://github.com/ngmy/homedir.git "${HOMEDIR_PATH}"
  fi
  rsync --exclude='.git' \
    --exclude='.gitkeep' \
    --exclude='LICENSE' \
    --exclude='README.md' \
    --exclude='install.sh' \
    -ahv "${HOMEDIR_PATH}/" "${HOME}"
}

if [ "$(uname)" == 'Darwin' ]; then
  # Mac
  do_it
  ln -fns "${HOME}/Documents" "${HOME}/docs"
  ln -fns "${HOME}/Desktop" "${HOME}/var/desktop"
else
  echo "Your platform ($(uname -a)) is not supported."
  exit 1
fi
