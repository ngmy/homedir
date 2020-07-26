#!/bin/bash

is_mac() {
  [ "$(uname)" == 'Darwin' ]
}

is_linux() {
  [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]
}

is_wsl2() {
  [ is_linux -a -d '/mnt/c' ]
}

is_wt() {
  [ -n "${WT_SESSION}" ]
}

install_for_all() {
  local HOMEDIR_PATH="$(realpath "${1:-"${HOME}/homedir"}")"

  if [ -d "${HOMEDIR_PATH}" ]; then
    echo "ngmy/homedir already exists in '${HOMEDIR_PATH}'."
    local YN
    read -p 'Do you want to re-download ngmy/homedir and continue the installation? (y/N)' YN
    if [ "${YN}" != 'y' ]; then
      echo 'The installation was canceled.'
      exit 1
    fi
    echo "Downloading ngmy/homedir to '${HOMEDIR_PATH}'..."
    git -C "${HOMEDIR_PATH}" pull origin master
  else
    echo "Downloading ngmy/homedir to '${HOMEDIR_PATH}'..."
    git clone https://github.com/ngmy/homedir.git "${HOMEDIR_PATH}"
  fi

  find "${HOMEDIR_PATH}" \
    -mindepth 1 -maxdepth 1 \
    -name '*' \
    -not -name '.git' \
    -not -name 'LICENSE' \
    -not -name 'README.md' \
    -not -name 'install.sh' \
    | xargs -I {} basename {} \
    | xargs -I {} git -C "${HOMEDIR_PATH}" ls-tree --name-only HEAD {} \
    | rsync -ahv \
      --exclude='.gitkeep' \
      --files-from=- "${HOMEDIR_PATH}/" "${HOME}"
}

install_for_mac() {
  ln -fnsv "${HOME}/Documents" "${HOME}/docs"
  ln -fnsv "${HOME}/Desktop" "${HOME}/var/desktop"
  ln -fnsv "${HOME}/Downloads" "${HOME}/var/downloads"
}

install_for_wsl2() {
  local WIN_USER_PROFILE_PATH="$(cmd.exe /c "<nul set /p=%UserProfile%" 2>/dev/null)"
  local WIN_USER_PROFILE_DRIVE="${WIN_USER_PROFILE_PATH%%:*}:"
  local USER_PROFILE_MOUNT_PATH="$(findmnt --noheadings --first-only --output TARGET "${WIN_USER_PROFILE_DRIVE}\\")"
  local WIN_USER_PROFILE_PATH_WITHOUT_DRIVE="${WIN_USER_PROFILE_PATH#*:}"
  local USER_PROFILE_PATH="${USER_PROFILE_MOUNT_PATH}${WIN_USER_PROFILE_PATH_WITHOUT_DRIVE//\\//}"

  ln -fnsv "${USER_PROFILE_PATH}/OneDrive/ドキュメント" "${HOME}/docs"
  ln -fnsv "${USER_PROFILE_PATH}/OneDrive/デスクトップ" "${HOME}/var/desktop"
  ln -fnsv "${USER_PROFILE_PATH}/Downloads" "${HOME}/var/downloads"
}

install_dotfiles() {
  local DOTFILES_PATH="$(realpath "${HOME}/share/dotfiles")"
  bash <(curl -LSs https://raw.githubusercontent.com/ngmy/dotfiles/master/install.sh) "${DOTFILES_PATH}"
}

install_wt_settings() {
  if is_wt; then
    local WT_SETTINGS_PATH="$(realpath "${HOME}/tmp/wt-settings")"
    bash <(curl -LSs https://raw.githubusercontent.com/ngmy/wt-settings/master/install.sh) "${WT_SETTINGS_PATH}"
  fi
}

execute_tasks() {
  local TASKS=("$@")
  local task
  for task in "${TASKS[@]}"; do
    eval "${task}"
  done
}

MAC_TASKS=(
  'install_for_all'
  'install_for_mac'
  'install_dotfiles'
)

WSL2_TASKS=(
  'install_for_all'
  'install_for_wsl2'
  'install_dotfiles'
  'install_wt_settings'
)

if is_mac; then
  execute_tasks "${MAC_TASKS[@]}"
elif is_wsl2; then
  execute_tasks "${WSL2_TASKS[@]}"
else
  echo "Your platform ($(uname -a)) is not supported."
  exit 1
fi
