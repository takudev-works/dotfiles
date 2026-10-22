#!/bin/bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$THIS_DIR/../../utils.sh"

FONT_DIR="$HOME/Library/Fonts"

if [ ! -d "$FONT_DIR" ]; then
  log "エラー: フォントのディレクトリ $FONT_DIR がありません"
  exit 1
fi

if ! compgen -G "$THIS_DIR/*.ttf" >/dev/null; then
  log "エラー: $THIS_DIR に .ttf ファイルがありません"
  exit 1
fi

log "フォントを $FONT_DIR に入れます"
cp -v "$THIS_DIR"/*.ttf "$FONT_DIR"
log "フォントを入れました"
