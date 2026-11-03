#!/bin/bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$THIS_DIR/utils.sh"

main() {
  if [ "${1:-}" = "--mdm" ]; then
    export DOTFILES_MDM=1
    shift
  fi

  if is_mdm_mode; then
    log "MDM モードで実行します。管理者権限が要る設定は飛ばし、入っていないアプリは入れるかを聞きます"
  fi

  if [ "$#" -gt 0 ]; then
    local module
    for module in "$@"; do
      run_setup "$module"
    done
    return
  fi

  log "セットアップを始めます"

  run_setup "fonts"
  run_setup "xcode"
  run_setup "homebrew"
  # homebrew の setup.sh が通した PATH に頼らないのは、setup.sh が子プロセスで動き、ここに残らないため
  load_brew_env
  run_setup "mac"
  run_setup "git"
  run_setup "tmux"
  run_setup "mise"

  log "この repo の依存と git hook を入れます"
  mise trust "$THIS_DIR/mise.toml"
  mise --cd "$THIS_DIR" run setup

  run_setup "markdownlint"
  run_setup "cspell"
  run_setup "starship"
  run_setup "inshellisense"
  run_setup "claude"
  run_setup "zsh"

  log "セットアップが終わりました"
}

main "$@"
