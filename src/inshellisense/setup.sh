#!/bin/bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$THIS_DIR/../../utils.sh"

link_files "$THIS_DIR" "$HOME/.config/inshellisense" rc.toml

log "inshellisense の zsh 用のファイルを作ります"
is init zsh >/dev/null
