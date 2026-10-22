#!/bin/bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$THIS_DIR/../../utils.sh"

if [ "$(uname)" != "Darwin" ]; then
  log "エラー: このスクリプトは macOS 専用です"
  exit 1
fi

configure_sound_effects() {
  log "効果音を設定します"

  sudo nvram StartupMute=%01 #起動音をミュート

  log "効果音を設定しました"
}

configure_scrollbar() {
  log "スクロールバーを設定します"

  defaults write NSGlobalDomain AppleShowScrollBars -string "Always" # スクロールバーを常に表示

  log "スクロールバーを設定しました"
}

configure_appearance() {
  log "外観を設定します"

  defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"                   # 外観モードをダークに
  defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool false # 外観の自動切り替えを無効化

  log "外観を設定しました"
}

configure_time() {
  log "日付と時刻を設定します"

  defaults write NSGlobalDomain AppleICUForce24HourTime -bool true  # 24時間表示にする
  defaults write com.apple.menuextra.clock Show24Hour -bool true    # メニューバーの時計を24時間表示にする
  defaults write com.apple.menuextra.clock ShowAMPM -bool true      # AM/PM を表示（24時間表示時は無視される）
  defaults write com.apple.menuextra.clock ShowDate -int 0          # 日付の表示は自動
  defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true # 曜日を表示
  defaults write com.apple.menuextra.clock ShowSeconds -bool true   # 秒を表示

  log "日付と時刻を設定しました"
}

configure_battery() {
  log "バッテリーを設定します"

  sudo pmset -a LowPowerMode 0 # Low Power Modeを無効化

  log "バッテリーを設定しました"
}

configure_screenshot() {
  log "スクリーンショットを設定します"

  defaults write com.apple.screencapture "disable-shadow" -bool true  # スクリーンショットに影を付けない
  defaults write com.apple.screencapture location "${HOME}/Downloads" # スクリーンショットの保存先をDownloadsに変更
  defaults write com.apple.screencapture type -string "png"           # スクリーンショットのファイル形式をPNGに変更

  log "スクリーンショットを設定しました"
}

configure_controlcenter() {
  log "コントロールセンターを設定します"

  # メニューバーに表示するかどうか
  defaults write com.apple.controlcenter "NSStatusItem Visible WiFi" -bool false                   # Wi-Fi: メニューバーに表示しない
  defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool false              # Bluetooth: メニューバーに表示しない
  defaults write com.apple.controlcenter "NSStatusItem Visible AirDrop" -bool false                # AirDrop: メニューバーに表示しない
  defaults write com.apple.controlcenter "NSStatusItem Visible FocusModes" -bool false             # Focus: メニューバーに表示しない
  defaults write com.apple.controlcenter "NSStatusItem Visible StageManager" -bool false           # Stage Manager: メニューバーに表示しない
  defaults write com.apple.controlcenter "NSStatusItem Visible Display" -bool true                 # Display: メニューバーに表示する
  defaults write com.apple.controlcenter "NSStatusItem Visible AccessibilityShortcuts" -bool false # Accessibility Shortcuts: メニューバーに表示しない
  defaults write com.apple.controlcenter "NSStatusItem Visible TimeMachine" -bool false            # Time Machine: メニューバーに表示しない
  defaults write com.apple.controlcenter "NSStatusItem Visible VPN" -bool false                    # VPN: メニューバーに表示しない
  defaults write com.apple.controlcenter "NSStatusItem Visible Weather" -bool false                # Weather: メニューバーに表示しない
  defaults write com.apple.controlcenter "NSStatusItem Visible Shortcuts" -bool false              # Shortcuts: メニューバーに表示しない
  defaults write com.apple.controlcenter "NSStatusItem Visible BentoBox" -bool true                # コントロールセンター本体のアイコンをメニューバーに表示
  defaults write com.apple.Spotlight "NSStatusItem Visible Item" -bool false                       # Spotlight: メニューバーに表示しない
  defaults write com.apple.Siri "StatusMenuVisible" -bool false                                    # Siri: メニューバーに表示しない

  # コントロールセンター内に表示するかどうか
  defaults write com.apple.controlcenter "NSStatusItem VisibleCC Battery" -bool true # Battery: コントロールセンターに表示
  defaults write com.apple.controlcenter "NSStatusItem VisibleCC Sound" -bool true   # Sound: コントロールセンターに表示
  defaults write com.apple.controlcenter "NSStatusItem VisibleCC Clock" -bool true   # 時計: コントロールセンターに表示
  defaults write com.apple.controlcenter BatteryShowPercentage -bool true            # バッテリー残量をパーセントで表示

  restart_app ControlCenter

  log "コントロールセンターを設定しました"
}

configure_dock_desktop() {
  log "Dock とデスクトップを設定します"

  # Dock
  defaults write com.apple.dock tilesize -int 48                            # アイコンサイズを48pxに
  defaults write com.apple.dock magnification -bool false                   # Dock の拡大を無効化
  defaults write com.apple.dock orientation -string "bottom"                # 位置を下
  defaults write com.apple.dock mineffect -string "genie"                   # 最小化エフェクトをジニーに
  defaults write NSGlobalDomain AppleActionOnDoubleClick -string "Maximize" # タイトルバーのダブルクリックをズームに
  defaults write com.apple.dock minimize-to-application -bool true          # ウィンドウをアプリアイコンに最小化する
  defaults write com.apple.dock autohide -bool true                         # Dock を自動的に隠す
  defaults write com.apple.dock launchanim -bool false                      # アプリ起動時のアニメーションをオフ
  defaults write com.apple.dock show-process-indicators -bool true          # 開いているアプリのインジケーターを表示
  defaults write com.apple.dock show-recents -bool false                    # 最近使ったアプリを Dock に表示しない
  defaults write com.apple.dock autohide-delay -float 0                     # 自動的に隠した Dock を再表示するまでの待ち時間をなくす
  defaults write com.apple.dock largesize -int 96                           # 拡大時のアイコンサイズ（拡大は無効なので実際には使われない）
  defaults write com.apple.dock no-bouncing -bool false                     # 通知時に Dock アイコンを跳ねさせる

  # Desktop & Stage Manager 設定
  defaults write com.apple.finder CreateDesktop -bool true                               # デスクトップアイテムを表示
  defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool true     # デスクトップを表示するために壁紙をクリック
  defaults write com.apple.WindowManager StageManager -bool false                        # Stage Manager を無効化
  defaults write com.apple.WindowManager GloballyEnabled -bool false                     # Stage Manager を無効化（全体トグル）
  defaults write com.apple.WindowManager AutoHide -bool false                            # Stage Manager のサイドバーを自動的に隠さない
  defaults write com.apple.WindowManager ShowRecentApplications -bool true               # 最近使ったアプリを Stage Manager に表示
  defaults write com.apple.WindowManager GroupWindowsByApplication -string "all-at-once" # アプリのウィンドウ表示を「すべて同時」

  # ウィジェット設定
  defaults write com.apple.desktoppicture ShowWidgets -bool true             # デスクトップにウィジェットを表示
  defaults write com.apple.StageManager ShowWidgets -bool true               # Stage Manager でウィジェットを表示
  defaults write com.apple.WindowManager StandardHideWidgets -bool false     # 通常のデスクトップでウィジェットを隠さない
  defaults write com.apple.WindowManager StageManagerHideWidgets -bool false # Stage Manager 使用時もウィジェットを隠さない

  # Windows 設定
  defaults write NSGlobalDomain AppleWindowTabbingMode -string "fullscreen" # タブ優先（フルスクリーン時のみ）
  defaults write NSGlobalDomain NSCloseAlwaysConfirmsChanges -bool false    # ドキュメント変更時の確認をオフ
  defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false        # アプリ終了時にウィンドウを閉じる

  # タイル化関連の設定（すべてオフ）
  defaults write com.apple.WindowManager EnableTiling -bool false
  defaults write com.apple.WindowManager EnableFullscreenOnDrag -bool false
  defaults write com.apple.WindowManager EnableSnapToEdge -bool false
  defaults write com.apple.WindowManager TiledWindowsHaveMargins -bool false
  defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false
  defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false
  defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false
  defaults write com.apple.WindowManager EnableTilingOptionAccelerator -bool false

  # Mission Control 設定
  defaults write com.apple.dock mru-spaces -bool false                        # 最近使用した順に Space を自動配置しない
  defaults write com.apple.dock appswitcher-all-displays -bool true           # アプリ切り替え時に開いている Space に移動
  defaults write com.apple.spaces spans-displays -bool false                  # ディスプレイごとに Space を分離しない
  defaults write com.apple.dock expose-group-by-app -bool false               # アプリごとにウィンドウをグループ化しない
  defaults write com.apple.dock enterMissionControlByTopWindowDrag -bool true # 画面上部へのウィンドウドラッグで Mission Control に入る
  defaults write com.apple.dock hot-corners -bool true                        # ホットコーナーを有効化

  # ホットコーナー（1=なし, 2=Mission Control, 4=デスクトップ, 5=スクリーンセーバ開始, 11=Launchpad, 12=通知センター, 13=画面をロック, 14=クイックメモ）
  defaults write com.apple.dock wvous-tl-corner -int 1   # 左上: なし
  defaults write com.apple.dock wvous-tl-modifier -int 0 # 左上: 修飾キーなし
  defaults write com.apple.dock wvous-br-corner -int 14  # 右下: クイックメモ

  # 設定を適用
  restart_app Dock
  restart_app Finder

  log "Dock とデスクトップを設定しました"
}

configure_notifications() {
  log "通知を設定します"

  defaults write com.apple.notificationcenterui bannerPreviewStyle -int 2               # 通知のプレビューを「ロック解除時のみ」に設定
  defaults write com.apple.notificationcenterui doNotDisturb -bool true                 # ディスプレイがスリープ中でも通知を許可しない
  defaults write com.apple.notificationcenterui screenSharingDoNotDisturb -bool true    # 画面ミラーリングまたは共有時の通知を許可しない
  defaults write com.apple.notificationcenterui iPhoneNotificationForwarding -bool true # iPhone からの通知を許可

  restart_app NotificationCenter

  log "通知を設定しました"
}

configure_sound() {
  log "サウンドを設定します"

  sudo nvram SystemAudioVolume="%80"                                                                           # 起動音の音量（ミュート自体は configure_sound_effects の StartupMute で行う）
  defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -bool true                                     # UI のサウンドエフェクトを有効化
  defaults write -g com.apple.sound.beep.feedback -bool false                                                  # 音量変更時のフィードバック音を無効化
  defaults write com.apple.systemsound "com.apple.sound.beep.sound" -string "/System/Library/Sounds/Boop.aiff" # 警告音を "Boop" に設定

  log "サウンドを設定しました"
}

configure_focus() {
  log "集中モードを設定します"

  defaults write com.apple.ncprefs.plist focusMode -dict-add "shareAcrossDevices" -bool true # フォーカスモードをデバイス間で共有する
  defaults write com.apple.ncprefs.plist focusMode -dict-add "focusStatus" -bool true        # フォーカスステータスをアプリと共有する

  restart_app NotificationCenter

  log "集中モードを設定しました"
}

configure_lock_screen() {
  log "ロック画面を設定します"

  defaults -currentHost write com.apple.screensaver idleTime -int 180 # スクリーンセーバーの開始時間（3 分）
  sudo pmset -b displaysleep 5                                        # バッテリー使用時のディスプレイオフ時間（5 分）
  sudo pmset -c displaysleep 5                                        # 電源接続時のディスプレイオフ時間（5 分）
  defaults write com.apple.screensaver askForPassword -int 1          # スクリーンセーバーやディスプレイオフ後のパスワード要求を即時に設定
  defaults write com.apple.screensaver askForPasswordDelay -int 0

  # ロック画面の表示オプション
  defaults write com.apple.menuextra.clock IsAnalog -bool false                           # デジタル時計を表示
  sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false # ゲストユーザーを無効化

  log "ロック画面を設定しました"
}

configure_security() {
  log "セキュリティを設定します"

  # 許可するアプリのソースは「App Store & Known Developers」（macOS の既定値）
  # spctl での変更は現行 macOS では Recovery からしか行えないため、状態の確認だけする
  if spctl --status 2>/dev/null | grep -q "assessments enabled"; then
    log "Gatekeeper は有効です"
  else
    log "Gatekeeper が無効です。復旧モード（Recovery OS）で有効にしてください"
  fi

  sudo defaults write /Library/Preferences/com.apple.AccessorySecurity "AccessorySecurityPolicy" -int 1 # アクセサリの接続を「新しいアクセサリの接続を確認」に設定
  sudo defaults write /Library/Preferences/com.apple.security.lockdown "Mode" -bool false               # Lockdown Mode をオフに設定（Lockdown Mode の変更は手動が推奨される）
  if ! fdesetup status | grep -q "FileVault is On."; then                                               # FileVault を有効化
    sudo fdesetup enable
  else
    log "FileVault は有効なので飛ばします"
  fi
  defaults write com.apple.screensaver askForPassword -int 1      # スクリーンセーバーやスリープ解除時にパスワードを要求
  defaults write com.apple.screensaver askForPasswordDelay -int 0 # スクリーンセーバーやスリープ解除後のパスワード要求を即時に

  log "セキュリティを設定しました"
}

configure_autofill_passwords() {
  log "自動入力とパスワードを設定します"

  defaults write com.apple.onetimepasscodes DeleteVerificationCodes -bool false # 確認コードを使用後に自動削除しない

  # AutoFill の候補元として 1Password の拡張機能を有効化
  if [ -n "$(pluginkit -m -i com.1password.1password.autofill-extension 2>/dev/null)" ]; then
    pluginkit -e use -i com.1password.1password.autofill-extension
  else
    log "1Password の自動入力の拡張機能が無いので飛ばします"
  fi

  # 「AutoFill Passwords and Passkeys」本体のオンオフと、候補元「Passwords」(Apple 純正) のオフは
  # ~/Library/Application Support/com.apple.AuthenticationServices 配下に保存され、
  # TCC で保護されていて defaults からは書き換えられないため、System Settings で手動設定する
  log "システム設定 > 一般 > 自動入力とパスワード で、「パスワードとパスキーを自動入力」をオン、自動入力元の「パスワード」をオフに手で設定してください"

  log "自動入力とパスワードを設定しました"
}

configure_keyboard() {
  log "キーボードを設定します"

  defaults write NSGlobalDomain KeyRepeat -int 2                                                          # キーリピート速度（0 が最速、2 以上で遅くなる）
  defaults write NSGlobalDomain InitialKeyRepeat -int 15                                                  # キーリピート開始の遅延（短くする）
  defaults write com.apple.BezelServices kDim -bool true                                                  # 暗い環境でのキーボードバックライト自動調整を有効化
  defaults write com.apple.BezelServices kDimTime -int 0                                                  # 非アクティブ時にキーボードバックライトをオフにしない（Never）
  defaults write com.apple.HIToolbox AppleFnUsageType -int 0                                              # 🌐キーで入力ソースを切り替え
  defaults write NSGlobalDomain AppleKeyboardUIMode -int 3                                                # キーボードナビゲーションを有効化（Tab で UI 要素を移動）
  defaults write com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMEnabled -bool false # 音声入力を無効化
  defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false                          # オートピリオド（自動句読点）を無効化
  defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false                              # 自動大文字変換を無効化
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false                          # 自動スペルチェックを無効化

  log "キーボードを設定しました"
}

configure_trackpad() {
  log "トラックパッドを設定します"

  defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3                                                   # トラッキング速度（1 ～ 3 の範囲で設定）
  defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 1                                         # クリック強度（0=軽い, 1=中, 2=強い）
  defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 1                                        # クリック強度（0=軽い, 1=中, 2=強い）
  defaults write com.apple.AppleMultitouchTrackpad ActuationStrength -int 0                                           # 静音クリック（Quiet Click）を有効化
  defaults write com.apple.AppleMultitouchTrackpad ForceSuppressed -bool true                                         # 強めのクリックと触覚フィードバックを有効化
  defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 0                               # ルックアップ & データ検出をオフ
  defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true                                      # 副ボタンのクリック（2 本指でクリック）
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true                     # 副ボタンのクリック（2 本指でクリック）
  defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true                                                # タップでクリックを有効化
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true                               # タップでクリックを有効化
  defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true                                             # ナチュラルスクロール（指の動きに合わせてスクロール）
  defaults write com.apple.AppleMultitouchTrackpad TrackpadPinch -bool true                                           # ピンチでズーム
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadPinch -bool true                          # ピンチでズーム
  defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerDoubleTapGesture -int 1                           # スマートズーム（2 本指でダブルタップ）
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerDoubleTapGesture -int 1          # スマートズーム（2 本指でダブルタップ）
  defaults write com.apple.AppleMultitouchTrackpad TrackpadRotate -bool true                                          # 2 本指で回転
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRotate -bool true                         # 2 本指で回転
  defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool true                                        # ページ間スワイプ（2 本指で左右）
  defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 1                        # ページ間スワイプ（2 本指で左右）
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 1       # ページ間スワイプ（2 本指で左右）
  defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int 2                         # フルスクリーンアプリの切り替え（4 本指で左右）
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerHorizSwipeGesture -int 2        # フルスクリーンアプリの切り替え（4 本指で左右）
  defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 1                  # 通知センター（2 本指で右端からスワイプ）
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 1 # 通知センター（2 本指で右端からスワイプ）
  defaults write com.apple.dock showMissionControlGestureEnabled -bool true                                           # Mission Control（4 本指で上にスワイプ）
  defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture -int 2                          # Mission Control（4 本指で上にスワイプ）
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerVertSwipeGesture -int 2         # Mission Control（4 本指で上にスワイプ）
  defaults write com.apple.dock showAppExposeGestureEnabled -bool false                                               # App Exposé をオフ
  defaults write com.apple.dock showLaunchpadGestureEnabled -bool true                                                # Launchpad（親指と 3 本指でピンチ）
  defaults write com.apple.dock showDesktopGestureEnabled -bool true                                                  # デスクトップ表示（親指と 3 本指で広げる）

  log "トラックパッドを設定しました"
}

configure_mouse() {
  log "マウスを設定します"

  defaults write NSGlobalDomain com.apple.mouse.scaling -float 1.5                                   # マウスのトラッキング速度（トラックパッド側は configure_trackpad で設定）
  defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true                            # ナチュラルスクロール（オン）
  defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string "TwoButton" # 副ボタンクリック（右クリックを有効化）
  defaults write NSGlobalDomain com.apple.mouse.doubleClickThreshold -float 0.75                     # ダブルクリックの速度（最速に近い設定）
  defaults write NSGlobalDomain com.apple.scrollwheel.scaling -float 0.75                            # スクロール速度（中程度に設定）

  log "マウスを設定しました"
}

configure_finder() {
  log "Finderを設定します"

  # Finder のデフォルト並び順を「Kind」に設定
  defaults write com.apple.finder FXPreferredGroupBy -string "Kind"

  # 隠しファイルを表示
  defaults write com.apple.finder AppleShowAllFiles -bool true

  # すべてのファイル拡張子を表示
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  # 新規書類の保存先を iCloud ではなくローカルにする
  defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

  # Finder の UI 設定
  defaults write com.apple.finder ShowPathbar -bool true              # パスバーを表示
  defaults write com.apple.finder ShowStatusBar -bool false           # ステータスバーを表示しない
  defaults write com.apple.finder ShowSidebar -bool true              # サイドバーを表示
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv" # 既定の表示形式をリストに
  defaults write com.apple.finder FXArrangeGroupViewBy -string "Name" # グループ内の並び順を名前順に
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true  # Finder ウィンドウタイトルにフルパスを表示
  defaults write com.apple.finder FinderSounds -bool false            # Finder のサウンドをオフ
  defaults write com.apple.finder FinderSpawnTab -bool true           # 新しいウィンドウの代わりにタブで開く

  # ゴミ箱の設定
  defaults write com.apple.finder WarnOnEmptyTrash -bool false
  defaults write com.apple.finder FXRemoveOldTrashItems -bool false # 30 日後にゴミ箱から削除する設定を無効化

  # ダウンロードしたアプリの初回警告を無効化
  defaults write com.apple.LaunchServices LSQuarantine -bool false

  # デスクトップに表示するアイテム
  defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
  defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
  defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
  defaults write com.apple.finder ShowMountedServersOnDesktop -bool false

  # Finder ウィンドウのデフォルトフォルダ（カスタムパス）
  defaults write com.apple.finder NewWindowTarget -string "PfLo"
  defaults write com.apple.finder NewWindowTargetPath -string "file:///Users/$(whoami)/"

  # 検索時のデフォルト動作（Mac 全体を検索）
  defaults write com.apple.finder FXDefaultSearchScope -string "SCev"

  # 拡張子変更時の警告を有効化
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool true
  defaults write com.apple.finder FXICloudDriveWarning -bool true

  # Sidebar の設定（完全リセット & 追加）
  defaults write com.apple.sidebarlists systemitems -dict \
    ShowRecents -bool false \
    ShowAirDrop -bool true \
    ShowApplications -bool true \
    ShowDownloads -bool true \
    ShowDesktop -bool false \
    ShowMovies -bool false \
    ShowMusic -bool false \
    ShowPictures -bool false \
    ShowiCloudDrive -bool true \
    ShowiCloudDocuments -bool true \
    ShowiCloudShared -bool true \
    ShowHardDisks -bool true \
    ShowExternalHardDrives -bool true \
    ShowRemovable -bool true \
    ShowCloudStorage -bool true \
    ShowBonjour -bool true \
    ShowConnectedServers -bool true \
    ShowRecentTags -bool true

  # Finder を再起動（変更を反映）
  sleep 1
  restart_app Finder

  log "Finderを設定しました"
}

main() {
  local steps=(
    configure_sound_effects
    configure_scrollbar
    configure_appearance
    configure_time
    configure_battery
    configure_screenshot
    configure_controlcenter
    configure_dock_desktop
    configure_notifications
    configure_sound
    configure_focus
    configure_lock_screen
    configure_security
    configure_autofill_passwords
    configure_keyboard
    configure_trackpad
    configure_mouse
    configure_finder
  )

  for step in "${steps[@]}"; do
    "$step"
    echo ""
  done
}

main
