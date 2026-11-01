#!/bin/bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$THIS_DIR/../../utils.sh"

# command -v で確かめないのは、init.sh の中ではまだ ~/.local/bin が PATH に無いため
if [ -x "$HOME/.local/bin/claude" ]; then
  log "Claude Code は入っています"
else
  log "Claude Code を入れます"
  curl -fsSL https://claude.ai/install.sh | bash
fi

link_files "$THIS_DIR" "$HOME/.claude" settings.json statusline-command.sh
