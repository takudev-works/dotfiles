#!/bin/bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$THIS_DIR/../../utils.sh"

LOCAL_GITCONFIG="$HOME/.gitconfig.local"

set_git_user() {
  local key=$1
  local value=$2
  local default=$3

  if [ -n "$value" ]; then
    git config --file "$LOCAL_GITCONFIG" "$key" "$value"
    log "$key を $value にしました"
    return
  fi

  if git config --file "$LOCAL_GITCONFIG" --get "$key" >/dev/null 2>&1; then
    log "$key は $LOCAL_GITCONFIG にあるので変えません"
    return
  fi

  git config --file "$LOCAL_GITCONFIG" "$key" "$default"
  log "$key を既定の $default にしました"
}

link_files "$THIS_DIR" "$HOME" .gitconfig .gitignore_global .czrc
set_git_user user.name "${DOTFILES_GIT_USER_NAME:-}" "Takuya Iwashiro"
set_git_user user.email "${DOTFILES_GIT_USER_EMAIL:-}" "takuya.iwashiro@takudev.net"
