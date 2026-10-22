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
