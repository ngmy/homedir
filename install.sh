#!/bin/bash

set -Ceuxo pipefail

is_mac() {
  [ "$(uname)" == 'Darwin' ]
}

is_linux() {
  [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]
}

is_wsl2() {
  [[ "$(uname -r)" =~ 'microsoft' ]]
}

download() {
  if [ -d "${homedir_path}" ]; then
    echo "ngmy/homedir already exists in '${homedir_path}'."
    local yn
    read -p 'Do you want to re-download ngmy/homedir and continue the installation? (y/N)' yn
    if [ "${yn}" != 'y' ]; then
      echo 'The installation was canceled.'
      exit 1
    fi
    echo "Downloading ngmy/homedir to '${homedir_path}'..."
    git -C "${homedir_path}" pull origin master
  else
    echo "Downloading ngmy/homedir to '${homedir_path}'..."
    git clone https://github.com/ngmy/homedir.git "${homedir_path}"
  fi
}

install_for_all() {
  find "${homedir_path}" \
    -mindepth 1 -maxdepth 1 \
    -name '*' \
    -not -name '.git' \
    -not -name 'LICENSE' \
    -not -name 'README.md' \
    -not -name 'install.sh' \
    | xargs -I {} basename {} \
    | xargs -I {} git -C "${homedir_path}" ls-tree --name-only HEAD {} \
    | rsync -hrv \
      --exclude='.gitkeep' \
      --files-from=- "${homedir_path}/" "${HOME}"
}

install_for_mac() {
  ln -fnsv "${HOME}/Documents" "${HOME}/docs"
  ln -fnsv "${HOME}/Desktop" "${HOME}/var/desktop"
  ln -fnsv "${HOME}/Downloads" "${HOME}/var/downloads"
}

install_for_wsl2() {
  local -r win_user_profile_path="$(cmd.exe /c "<nul set /p=%UserProfile%" 2>/dev/null)"
  local -r win_user_profile_drive="${win_user_profile_path%%:*}:"
  local -r user_profile_mount_path="$(findmnt --noheadings --first-only --output TARGET "${win_user_profile_drive}\\")"
  local -r win_user_profile_path_without_drive="${win_user_profile_path#*:}"
  local -r user_profile_path="${user_profile_mount_path}${win_user_profile_path_without_drive//\\//}"

  ln -fnsv "${user_profile_path}/OneDrive/ドキュメント" "${HOME}/docs"
  ln -fnsv "${user_profile_path}/OneDrive/デスクトップ" "${HOME}/var/desktop"
  ln -fnsv "${user_profile_path}/OneDrive/作業" "${HOME}/work"
  ln -fnsv "${user_profile_path}/Downloads" "${HOME}/var/downloads"
}

execute_tasks() {
  local -r tasks=("$@")
  local task
  for task in "${tasks[@]}"; do
    eval "${task}"
  done
}

main() {
  local -r homedir_path="$(realpath "${1:-"${HOME}/homedir"}")"

  local -r mac_tasks=(
    'download'
    'install_for_all'
    'install_for_mac'
  )
  local -r wsl2_tasks=(
    'download'
    'install_for_all'
    'install_for_wsl2'
  )

  if is_mac; then
    execute_tasks "${mac_tasks[@]}"
  elif is_wsl2; then
    execute_tasks "${wsl2_tasks[@]}"
  else
    echo "Your platform ($(uname -a)) is not supported."
    exit 1
  fi
}

main "$@"
