#!/bin/bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"

if command -v source >/dev/null 2>&1; then
  SOURCE_CMD="source"
else
  SOURCE_CMD="."
fi

$SOURCE_CMD "${THIS_DIR}/../../utils.sh"

check_requirements() {
  if ! command -v xcode-select &>/dev/null; then
    log "エラー: xcode-select コマンドがありません"
    return 1
  fi
}

install_xcode_command_line_tools() {
  if ! xcode-select -p &>/dev/null; then
    log "Xcode Command Line Tools を入れます"
    xcode-select --install
    log "表示されたダイアログでインストールを終えてください"
    log "インストールが終わったら、init.sh をもう一度実行してください"
    exit 1
  else
    log "Xcode Command Line Tools は入っています"
  fi
}

main() {
  check_requirements || exit 1
  install_xcode_command_line_tools || exit 1
}

main
