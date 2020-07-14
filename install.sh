#!/bin/bash

HOMEDIR_PATH="$(realpath "${1:-"${HOME}/homedir"}")"
DOTFILES_PATH="$(realpath "${HOME}/share/dotfiles")"

do_it() {
  if [ -d "${HOMEDIR_PATH}" ]; then
    echo "ngmy/homedir already exists in '${HOMEDIR_PATH}'. Skip download."
  else
    echo "Downloading ngmy/homedir to '${HOMEDIR_PATH}'..."
    git clone https://github.com/ngmy/homedir.git "${HOMEDIR_PATH}"
  fi
  find "${HOMEDIR_PATH}" -name '*' \
    -not -name '.git' \
    -not -name 'LICENSE' \
    -not -name 'README.md' \
    -not -name 'install.sh' \
    -mindepth 1 -maxdepth 1 \
    | xargs basename \
    | xargs -I {} git -C "${HOMEDIR_PATH}" ls-tree --name-only HEAD {} \
    | rsync -ahv \
      --exclude='.gitkeep' \
      --files-from=- "${HOMEDIR_PATH}/" "${HOME}"
  curl -LSs https://raw.githubusercontent.com/ngmy/dotfiles/master/install.sh | bash -s -- "${DOTFILES_PATH}"
}

do_it_for_mac() {
  ln -fnsv "${HOME}/Documents" "${HOME}/docs"
  ln -fnsv "${HOME}/Desktop" "${HOME}/var/desktop"
}

do_it_for_wsl2() {
  WIN_USERPROFILE="$(cmd.exe /c "<nul set /p=%UserProfile%" 2>/dev/null)"
  WIN_USERPROFILE_DRIVE="${WIN_USERPROFILE%%:*}:\\"
  USERPROFILE_MOUNT="$(findmnt --noheadings --first-only --output TARGET "${WIN_USERPROFILE_DRIVE}")"
  WIN_USERPROFILE_DIR="${WIN_USERPROFILE#*:}"
  USERPROFILE="${USERPROFILE_MOUNT}${WIN_USERPROFILE_DIR//\\//}"

  ln -fnsv "${USERPROFILE}/OneDrive/ドキュメント" "${HOME}/docs"
  ln -fnsv "${USERPROFILE}/OneDrive/デスクトップ" "${HOME}/var/desktop"
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
