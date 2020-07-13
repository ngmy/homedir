#!/bin/bash

HOMEDIR_PATH="${1:-"${HOME}/homedir"}"

do_it() {
  if [ -d "${HOMEDIR_PATH}" ]; then
    echo "ngmy/homedir already exists in '${HOMEDIR_PATH}'. Skip download."
  else
    echo "Downloading ngmy/homedir to '${HOMEDIR_PATH}'..."
    git clone https://github.com/ngmy/homedir.git "${HOMEDIR_PATH}"
  fi
  rsync --exclude='.git' \
    --exclude='.gitkeep' \
    --exclude='LICENSE' \
    --exclude='README.md' \
    --exclude='install.sh' \
    -ahv "${HOMEDIR_PATH}/" "${HOME}"
}

do_it_for_mac() {
  ln -fns "${HOME}/Documents" "${HOME}/docs"
  ln -fns "${HOME}/Desktop" "${HOME}/var/desktop"
}

do_it_for_wsl2() {
  WIN_USERPROFILE="$(cmd.exe /c "<nul set /p=%UserProfile%" 2>/dev/null)"
  WIN_USERPROFILE_DRIVE="${WIN_USERPROFILE%%:*}:\\"
  USERPROFILE_MOUNT="$(findmnt --noheadings --first-only --output TARGET "${WIN_USERPROFILE_DRIVE}")"
  WIN_USERPROFILE_DIR="${WIN_USERPROFILE#*:}"
  USERPROFILE="${USERPROFILE_MOUNT}${WIN_USERPROFILE_DIR//\\//}"

  ln -fns "${USERPROFILE}/OneDrive/ドキュメント" "${HOME}/docs"
  ln -fns "${USERPROFILE}/OneDrive/デスクトップ" "${HOME}/var/desktop"
}

if [ "$(uname)" == 'Darwin' ]; then
  # Mac
  do_it
  do_it_for_mac
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' -a -d '/mnt/c' ]; then
  # WSL 2
  do_it
  do_it_for_wsl2
else
  echo "Your platform ($(uname -a)) is not supported."
  exit 1
fi
