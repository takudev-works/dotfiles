#!/bin/bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$THIS_DIR/../../utils.sh"

DEV_CONFIG_DIST="$(cd "$THIS_DIR/../.." && pwd)/node_modules/@takudev-works/dev-config/dist"

if ! link_files "$DEV_CONFIG_DIST" "$HOME/.config/markdownlint" markdownlint-cli2.mjs; then
  log "先に repo のルートで 'mise run setup' を実行してください"
  exit 1
fi
