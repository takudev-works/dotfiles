#!/bin/bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$THIS_DIR/../../utils.sh"

setup_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    log "Homebrew を入れます"
    install_homebrew_pkg
  else
    log "Homebrew は入っています"
  fi

  load_brew_env
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

setup_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    log "attestation を確かめるための gh を入れます"
    # gh 自身の attestation を確かめないのは、確かめるには gh で GitHub にログインしている必要があるため
    HOMEBREW_NO_VERIFY_ATTESTATIONS=1 brew install gh
  fi

  if ! gh auth status >/dev/null 2>&1; then
    log "attestation を確かめるために、gh で GitHub にログインします"
    gh auth login
  fi
}

install_homebrew_pkg() {
  if [[ "$(uname -m)" != "arm64" ]]; then
    log "エラー: Homebrew の .pkg は Apple Silicon の Mac 向けにしか無いので、https://brew.sh の手順で手で入れてください"
    exit 1
  fi

  local team_id="927JGANW46"
  local pkg_dir
  pkg_dir="$(mktemp -d)"
  local pkg="$pkg_dir/Homebrew.pkg"

  # install.sh を使わないのは、取った中身を確かめる手段が無いため
  curl -fsSL -o "$pkg" https://github.com/Homebrew/brew/releases/latest/download/Homebrew.pkg

  # 署名があるかだけで済ませないのは、Apple が発行した Developer ID なら誰の署名でも通るため
  if ! pkgutil --check-signature "$pkg" | grep -qE "^ *1\. Developer ID Installer: .+ \($team_id\)$"; then
    log "エラー: Homebrew.pkg の署名が Homebrew の Team ID（$team_id）のものではありません"
    exit 1
  fi

  if ! spctl --assess --type install "$pkg" >/dev/null 2>&1; then
    log "エラー: Homebrew.pkg が Apple の公証（notarization）を通っていません"
    exit 1
  fi

  sudo installer -pkg "$pkg" -target /
  rm -rf "$pkg_dir"
}

main() {
  log "Homebrew のセットアップを始めます"

  link_files "$THIS_DIR" "$HOME/.homebrew" brew.env
  setup_homebrew
  setup_rosetta
  setup_gh
  validate_brewfile
  maintenance

  log "Homebrew のセットアップが終わりました"
}

main
