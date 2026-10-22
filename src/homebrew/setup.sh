#!/bin/bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"

if command -v source >/dev/null 2>&1; then
  SOURCE_CMD="source"
else
  SOURCE_CMD="."
fi

$SOURCE_CMD "${THIS_DIR}/../../utils.sh"

setup_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    log "Homebrew を入れます"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    log "Homebrew は入っています"
  fi

  local brew_path
  if [[ "$(uname -m)" == "arm64" ]]; then
    brew_path="/opt/homebrew/bin/brew"
  else
    brew_path="/usr/local/bin/brew"
  fi

  # ~/.zprofile に書き足さないのは、src/zsh/.zprofile へのリンクで、brew shellenv はそちらに書いてあるため
  eval "$($brew_path shellenv)"
}

setup_rosetta() {
  if [[ "$(uname -m)" == "arm64" ]]; then
    log "Rosetta 2 を入れます"
    if ! pkgutil --pkg-info=com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
      sudo softwareupdate --install-rosetta --agree-to-license
    else
      log "Rosetta 2 は入っています"
    fi
  fi
}

validate_brewfile() {
  log "Brewfile を検査します"
  if [ ! -f "$THIS_DIR/Brewfile" ]; then
    log "エラー: Brewfile がありません"
    exit 1
  fi

  if ! brew bundle check --file="$THIS_DIR/Brewfile" --no-upgrade >/dev/null 2>&1; then
    log "警告: Brewfile に問題がありそうです"
  else
    log "Brewfile の検査が終わりました"
  fi
}

maintenance() {
  log "brew doctor を実行します"
  if ! brew doctor; then
    log "警告: brew doctor が問題を見つけました"
  fi

  log "更新を確かめます"
  brew update

  log "パッケージを更新します"
  brew upgrade

  if [ -f "$THIS_DIR/Brewfile" ]; then
    log "Brewfile のパッケージを入れます"
    brew bundle --file="$THIS_DIR/Brewfile"
  else
    log "警告: Brewfile がありません"
  fi

  log "不要なパッケージを消します"
  brew autoremove

  log "古い版とキャッシュを消します"
  brew cleanup

  log "Brewfile にないパッケージを確かめます"
  # --force を付けないのは、付けると Brewfile にないパッケージをアンインストールするため
  # 失敗として扱わないのは、プロンプトを出せないと、消すものの一覧を出して 1 で終わるため
  brew bundle cleanup --file="$THIS_DIR/Brewfile" </dev/null || true
}

main() {
  log "Homebrew のセットアップを始めます"

  setup_homebrew
  setup_rosetta
  validate_brewfile
  maintenance

  log "Homebrew のセットアップが終わりました"
}

main
