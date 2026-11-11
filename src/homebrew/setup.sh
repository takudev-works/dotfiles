#!/bin/bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$THIS_DIR/../../utils.sh"

DECLINED_FORMULAE_FILE="$HOME/.config/dotfiles/declined-formulae"
DECLINED_CASKS_FILE="$HOME/.config/dotfiles/declined-casks"

setup_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    if is_mdm_mode; then
      log "エラー: Homebrew が入っていません。MDM モードでは入れないので、先に入れてください"
      exit 1
    fi

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
      run_as_admin softwareupdate --install-rosetta --agree-to-license
    else
      log "Rosetta 2 は入っています"
    fi
  fi
}

brewfile_formulae() {
  brew bundle list --formula --file="$THIS_DIR/Brewfile"
}

brewfile_casks() {
  brew bundle list --cask --file="$THIS_DIR/Brewfile"
}

run_brew_bundle() {
  if is_mdm_mode; then
    # brew bundle で formula と cask を入れないのは、install_formulae_interactively と install_casks_interactively で 1 つずつ聞いてから入れるため
    HOMEBREW_BUNDLE_BREW_SKIP="$(brewfile_formulae | tr '\n' ' ')" \
      HOMEBREW_BUNDLE_CASK_SKIP="$(brewfile_casks | tr '\n' ' ')" \
      brew bundle "$@"
  else
    brew bundle "$@"
  fi
}

ask_to_install() {
  local name=$1
  local declined_file=$2
  local answer

  mkdir -p "$(dirname "$declined_file")"
  touch "$declined_file"

  if grep -qxF "$name" "$declined_file"; then
    return 1
  fi

  if [ ! -t 0 ]; then
    log "$name を入れるかを聞けないので飛ばします"
    return 1
  fi

  read -r -p "$name を入れますか？ [y/N] " answer || answer=""
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    return 0
  fi

  echo "$name" >>"$declined_file"
  log "$name は入れません。聞き直すときは $declined_file から消してください"
  return 1
}

install_formulae_interactively() {
  log "入っていない formula を入れるかを聞きます"

  local installed
  installed="$(brew list --formula -1)"

  local formula
  local formulae=()
  while IFS= read -r formula; do
    formulae+=("$formula")
  done < <(brewfile_formulae)

  for formula in "${formulae[@]}"; do
    if grep -qxF "$formula" <<<"$installed"; then
      continue
    fi

    if ask_to_install "$formula" "$DECLINED_FORMULAE_FILE"; then
      brew install --formula "$formula"
    fi
  done
}

cask_apps() {
  local cask_info=$1
  local cask=$2

  jq -r --arg token "$cask" '
    .casks[] | select(.token == $token) | .artifacts[] | .app? // empty | .[]
    | if type == "object" then .target // empty else . end
  ' <<<"$cask_info"
}

is_cask_app_present() {
  local cask_info=$1
  local cask=$2
  local app

  while IFS= read -r app; do
    app="${app##*/}"
    if [ -e "/Applications/$app" ] || [ -e "$HOME/Applications/$app" ]; then
      return 0
    fi
  done < <(cask_apps "$cask_info" "$cask")

  return 1
}

cask_needs_admin() {
  local cask_info=$1
  local cask=$2

  jq -e --arg token "$cask" '
    any(.casks[] | select(.token == $token) | .artifacts[]; type == "object" and (has("pkg") or has("installer")))
  ' <<<"$cask_info" >/dev/null
}

install_casks_interactively() {
  log "入っていないアプリを入れるかを聞きます"

  local casks=()
  local cask
  while IFS= read -r cask; do
    casks+=("$cask")
  done < <(brewfile_casks)

  local cask_info
  cask_info="$(brew info --cask --json=v2 "${casks[@]}")"

  local installed
  installed="$(brew list --cask -1)"

  local app_dir="/Applications"
  if [ ! -w "$app_dir" ]; then
    app_dir="$HOME/Applications"
  fi

  for cask in "${casks[@]}"; do
    if grep -qxF "$cask" <<<"$installed"; then
      continue
    fi

    if is_cask_app_present "$cask_info" "$cask"; then
      log "$cask は Homebrew の外で入っているので飛ばします"
      continue
    fi

    if cask_needs_admin "$cask_info" "$cask"; then
      log "$cask はインストーラに管理者権限が要るので飛ばします"
      continue
    fi

    if ask_to_install "$cask" "$DECLINED_CASKS_FILE"; then
      brew install --cask --appdir="$app_dir" "$cask"
    fi
  done
}

validate_brewfile() {
  log "Brewfile を検査します"
  if [ ! -f "$THIS_DIR/Brewfile" ]; then
    log "エラー: Brewfile がありません"
    exit 1
  fi

  if ! run_brew_bundle check --file="$THIS_DIR/Brewfile" --no-upgrade >/dev/null 2>&1; then
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
    run_brew_bundle --file="$THIS_DIR/Brewfile"
    if is_mdm_mode; then
      install_formulae_interactively
      install_casks_interactively
    fi
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
