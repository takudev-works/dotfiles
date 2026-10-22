#!/bin/bash

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error_handler() {
  log "エラー: $1 行目で失敗しました"
  exit 1
}

restart_app() {
  killall "$1" 2>/dev/null || true
}

run_setup() {
  local module=$1
  local module_dir="$THIS_DIR/src/$module"
  log "$module をセットアップします"

  if [ ! -d "$module_dir" ]; then
    log "エラー: $module のディレクトリがありません"
    return 1
  fi

  if [ ! -f "$module_dir/setup.sh" ]; then
    log "エラー: $module の setup.sh がありません"
    return 1
  fi

  cd "$module_dir" || return 1
  ./setup.sh
  cd "$THIS_DIR" || return 1
}
