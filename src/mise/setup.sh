#!/bin/bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$THIS_DIR/../../utils.sh"

if ! command -v mise >/dev/null 2>&1; then
  log "エラー: mise が入っていません"
  exit 1
fi

link_files "$THIS_DIR" "$HOME/.config/mise" config.toml
mise install
