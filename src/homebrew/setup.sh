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

  if command -v brew >/dev/null 2>&1; then
    local brew_path
    if [[ "$(uname -m)" == "arm64" ]]; then
      brew_path="/opt/homebrew/bin/brew"
      log "Apple Silicon 向けに環境を設定します"
    else
      brew_path="/usr/local/bin/brew"
      log "Intel Mac 向けに環境を設定します"
    fi

    local shell_env="eval \"\$(${brew_path} shellenv)\""
    touch ~/.zprofile

    if grep -q "eval.*brew shellenv" ~/.zprofile; then
      (
        tmp_file=$(mktemp)
        trap 'rm -f "$tmp_file"' EXIT

        awk '
          /eval.*brew shellenv/ { if (!seen) print; seen=1; next }
          { print }
        ' ~/.zprofile >"$tmp_file" && mv "$tmp_file" ~/.zprofile
      )
    else
      echo "$shell_env" >>~/.zprofile
    fi
    # ~ を $HOME にしないのは、展開しないで ~ のまま表示するため
    # shellcheck disable=SC2088
    log "~/.zprofile の Homebrew の環境設定を更新しました"
    eval "$($brew_path shellenv)"
  fi
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
  brew doctor

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
  local unmanaged_formulae
  unmanaged_formulae=$(brew bundle cleanup --file="$THIS_DIR/Brewfile" --force)
  if [ -n "$unmanaged_formulae" ]; then
    log "警告: 次のパッケージは Brewfile にありません"
    echo "$unmanaged_formulae"
  fi
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
