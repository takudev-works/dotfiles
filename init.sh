#!/bin/bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"

if command -v source >/dev/null 2>&1; then
  SOURCE_CMD="source"
else
  SOURCE_CMD="."
fi

$SOURCE_CMD "${THIS_DIR}/utils.sh"

main() {
  log "セットアップを始めます"

  run_setup "fonts"
  run_setup "xcode"
  run_setup "homebrew"
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
  run_setup "claude"
  run_setup "zsh"

  log "セットアップが終わりました"
}

main
