#!/bin/bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
DEV_CONFIG_DIR="$THIS_DIR/../../node_modules/dev-config"
SOURCE_FILE="dist/markdownlint-cli2.mjs"
TARGET_FILE="markdownlint-cli2.mjs"
TARGET_DIR="$HOME/.config/markdownlint"

if command -v source >/dev/null 2>&1; then
  SOURCE_CMD="source"
else
  SOURCE_CMD="."
fi

$SOURCE_CMD "${THIS_DIR}/../../utils.sh"

check_requirements() {
  if [ ! -f "$DEV_CONFIG_DIR/$SOURCE_FILE" ]; then
    log "エラー: dev-config の $SOURCE_FILE がありません。先に repo のルートで 'mise run setup' を実行してください"
    return 1
  fi
}

install_markdownlint_config() {
  mkdir -p "$TARGET_DIR" || return 1
  ln -snfv "$(cd "$DEV_CONFIG_DIR" && pwd)/$SOURCE_FILE" "$TARGET_DIR/$TARGET_FILE" || return 1
  log "$TARGET_FILE を $TARGET_DIR にリンクしました"
}

main() {
  check_requirements || exit 1
  install_markdownlint_config || exit 1
}

main
