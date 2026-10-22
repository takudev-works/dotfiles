#!/bin/bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$THIS_DIR/../../utils.sh"

if ! command -v xcode-select &>/dev/null; then
  log "エラー: xcode-select コマンドがありません"
  exit 1
fi

if xcode-select -p &>/dev/null; then
  log "Xcode Command Line Tools は入っています"
  exit 0
fi

log "Xcode Command Line Tools を入れます"
xcode-select --install
log "表示されたダイアログでインストールを終えてください"
log "インストールが終わったら、init.sh をもう一度実行してください"
exit 1
