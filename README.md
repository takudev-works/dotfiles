# dotfiles

Mac の開発環境の設定と、それを入れるスクリプト。

## 準備

App Store と Apple ID にログインしておく。

## スクリプトの実行

```bash
bash init.sh
```

スクリプトの中で何度か `sudo` を呼ぶので、アカウントのパスワードを聞かれる。nvram とログインウインドウに書く設定は、再起動するまで効かない。

`init.sh` は `src/` の下にあるツールごとの `setup.sh` を順に実行する。1 つだけやり直すときは、その `setup.sh` を直接実行する（例: `bash src/zsh/setup.sh`）。

## 開発の準備

手元では次の順に実行する。`init.sh` を実行したあとなら、最初の 2 つは済んでいる。

```sh
mise install      # mise.toml の版の bun、lefthook、actionlint、zizmor、shellcheck を入れる
mise run setup    # 依存と git hook を入れる
bun run validate  # CI と同じ検査
```

前もって `mise` を入れておく（入れ方は https://mise.jdx.dev/getting-started.html ）。初めて使う repo では、`mise trust` で `mise.toml` を信頼してから実行する。

## 開発

lint の設定は [takudev-works/dev-config](https://github.com/takudev-works/dev-config) を devDependencies として入れて使う。`init.sh` の中で `mise run setup` を実行し、dev-config と git hook を入れる。`src/markdownlint/setup.sh` は、エディタが読めるように dev-config の markdownlint の正本を `~/.config/markdownlint/markdownlint-cli2.mjs` にリンクする。`src/cspell/setup.sh` は、個人の単語の `cspell.json` を `~/.config/cspell` にリンクする。

変更は PR で出し、`Org Requirements`（check の名前は `dev-config / validate`）が通ってから merge する。push の前に `bun run validate` を実行する。CI でも同じ検査をする。

## 手で行う設定

`src/mac/setup.sh` は、`defaults`、`pmset`、`nvram`、`pluginkit` で変えられる設定を扱う。それ以外の次の項目は手で行う。

### 自動入力とパスワード

全体のスイッチと、標準の「パスワード」アプリによる自動入力の設定は、`~/Library/Application Support/com.apple.AuthenticationServices/CredentialProviders` に保存される。このディレクトリは TCC（macOS のプライバシー保護の仕組み）で守られていて、スクリプトからは書けない。

1. システム設定 > 一般 > 自動入力とパスワード を開く。
2. **パスワードとパスキーを自動入力** をオンにする。
3. **自動入力元** で **パスワード**（標準のアプリ）をオフにする。
4. **自動入力元** で **1Password** をオンにする。

手順 4 は、`configure_autofill_passwords` が `pluginkit` で拡張機能を有効にする。`init.sh` は `homebrew` の手順で 1Password を入れてから `mac` の手順を実行する。拡張機能が見つからないときは、ログに「1Password の自動入力の拡張機能が無いので飛ばします」と出る。そのときは 1Password を一度起動してから `bash src/mac/setup.sh` を実行し直すか、手順 4 を手で行う。

### Gatekeeper

`spctl --master-enable` はもう無いので、`configure_security` は今の状態を表示するだけにしている。`spctl --status` の結果が `assessments enabled` 以外なら、復旧モード（Recovery OS）で起動して Gatekeeper を有効に戻す。

### ロックダウンモード

`configure_security` は `/Library/Preferences/com.apple.security.lockdown` の `Mode` キーに書くが、ロックダウンモードを変える正式な方法は システム設定 > プライバシーとセキュリティ > ロックダウンモード で、再起動も要る。スクリプトを実行した後に、この画面で状態を確かめる。

### FileVault

FileVault がオフのとき、`configure_security` は `sudo fdesetup enable` を実行する。アカウントのパスワードを聞かれ、復旧キーが表示される。次に進む前に復旧キーを保存する。

### メニューバーのアイコンの並び

スクリプトが決めるのはどのアイコンを出すかだけで、並び順は決めない。並び順は `com.apple.controlcenter` の `NSStatusItem Preferred Position *` キーに保存される。Command キーを押しながらアイコンをドラッグして並べ替える。

### Dock に置くアプリ

スクリプトは Dock の大きさ、位置、動きを設定するが、どのアプリを置くかは決めない。アプリの追加と並べ替えは手で行う。

### スクリプトに入れていないキー

次の 2 つのキーは今のマシンでは設定されているが、システム設定のどの項目にあたるか分からなかったので、`src/mac/setup.sh` に入れていない。

- `com.apple.WindowManager HideDesktop`
- `com.apple.WindowManager AppWindowGroupingBehavior`

新しいマシンでデスクトップやウインドウのまとめ方の動きがおかしいときは、システム設定 > デスクトップと Dock を手で見直す。

### その他

- コンピュータ名を変える
- ウォレットと Apple Pay を設定する
- Touch ID の指紋を追加する
- Apple Watch で Mac のロックを解除できるようにする
- スクリーンセーバを設定する
- 壁紙をランダムに変わるように設定する
- 集中モードを設定する
- Night Shift をオフにする
- True Tone をオフにする
- 明るさの自動調節をオフにする
- 生体認証（Touch ID）で Mac のロックを解除できるようにする
- キーボードの入力ソースを Google 日本語入力に変える
- 標準の Web ブラウザを Google Chrome に変える
- 各アプリを設定する
- ESET を設定する
