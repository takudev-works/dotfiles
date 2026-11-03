#!/bin/bash

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

require_files() {
  local dir=$1
  shift
  local missing=0
  local file

  for file in "$@"; do
    if [ ! -f "$dir/$file" ]; then
      log "エラー: $dir に $file がありません"
      missing=1
    fi
  done

  return "$missing"
}

link_files() {
  local src_dir=$1
  local dest_dir=$2
  local file
  shift 2

  require_files "$src_dir" "$@" || return 1
  mkdir -p "$dest_dir"
  for file in "$@"; do
    ln -snfv "$src_dir/$file" "$dest_dir/$file"
  done
  log "$* を $dest_dir にリンクしました"
}

load_brew_env() {
  local brew_path
  if [[ "$(uname -m)" == "arm64" ]]; then
    brew_path="/opt/homebrew/bin/brew"
  else
    brew_path="/usr/local/bin/brew"
  fi

  # ~/.zprofile に書き足さないのは、src/zsh/.zprofile へのリンクで、brew shellenv はそちらに書いてあるため
  eval "$($brew_path shellenv)"
}

is_mdm_mode() {
  [ "${DOTFILES_MDM:-}" = "1" ]
}

run_as_admin() {
  if is_mdm_mode; then
    log "管理者権限が要るので飛ばします: $*"
    return 0
  fi

  sudo "$@"
}

restart_app() {
  killall "$1" 2>/dev/null || true
}

run_setup() {
  local module=$1
  local setup_script="$THIS_DIR/src/$module/setup.sh"
  log "$module をセットアップします"

  if [ ! -f "$setup_script" ]; then
    log "エラー: $setup_script がありません"
    return 1
  fi

  bash "$setup_script"
}
