setopt incappendhistory

# ===========================
# 環境変数
# ===========================

# 手元だけの環境変数
[[ -f ~/.zsh_envvars ]] && source ~/.zsh_envvars

# 基本
export LANG="ja_JP.UTF-8"
export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=50000
export SAVEHIST=50000
export DIRSTACKSIZE=100

# PATH
typeset -U path PATH

# Android の開発
export ANDROID_HOME=$HOME/Library/Android/sdk
path=(
  $ANDROID_HOME/emulator
  $ANDROID_HOME/platform-tools
  $path
)

# claude や uv が入る場所
path=($path $HOME/.local/bin)

# ツールの設定
export RUST_WITHOUT="rust-docs"
export PATH

# 開発
export RUBY_DEBUG_DAP_SHOW_PROTOCOL=1
export AWS_PROFILE="default"

# ===========================
# zsh のオプション
# ===========================

setopt hist_ignore_all_dups # 同じコマンドをヒストリに残さない
setopt share_history        # 同時に起動したzshの間でヒストリを共有
setopt correct              # コマンドのスペルを訂正
setopt no_beep              # ビープ音を鳴らさない
setopt AUTO_PUSHD           # ディレクトリを移動したら自動的にpushd

# ===========================
# バージョン管理
# ===========================

if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# ===========================
# プラグインとツール
# ===========================

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=($HOME/.docker/completions $fpath)
# End of Docker CLI completions

autoload -Uz compinit
compinit

# starship
eval "$(starship init zsh)"

# direnv
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# zsh のプラグイン
if [[ -n "$HOMEBREW_PREFIX" ]]; then
  if [[ -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  fi
  if [[ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets cursor)
  fi
fi

# terraform の補完
autoload -U +X bashcompinit && bashcompinit
if command -v terraform &>/dev/null; then
  complete -o nospace -C "$(command -v terraform)" terraform
fi

# ===========================
# alias と関数
# ===========================

# 手元だけの alias
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases

# 基本
alias g='git'
alias galias='git config --get-regexp ^alias\.'
alias d='docker'
alias tf='terraform'
alias awsprofile='aws --profile default sts get-caller-identity'
alias awsprofilelist='aws configure list-profiles'

# Docker
alias di='docker images'
alias db='docker build'
alias dbx='docker buildx build --platform linux/amd64'
alias dr='docker rm'
alias dri='docker rmi'
alias dl='docker ps'
alias dla='docker ps -a'
alias dpa='docker system prune -a'
alias dpa24='docker system prune -a --filter "until=24h"'
alias dpv='docker volume prune'

# Terraform
alias tfp='terraform plan'
alias tfa='terraform apply'

# 標準のコマンド
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias ls='ls --color=auto'
alias ll='ls -la --color=auto'
alias l.='ls -d .* --color=auto'

# 開発の作業
alias gm='brew update && brew upgrade && brew cleanup && brew autoremove && brew doctor'
alias cdr='cd $(git rev-parse --show-toplevel)'
alias saml2awssetup="bash -c 'read -sp \"ClientID: \" client_id && echo && read -sp \"ClientSecret: \" client_secret && echo && saml2aws configure --client-id=\$client_id --client-secret=\$client_secret'"
alias saml2awslogin='saml2aws login --session-duration 14400 --force --skip-prompt --browser-type=chrome'

# AI
alias c='~/.local/bin/claude'

# 手元だけの関数
[[ -f ~/.zsh_functions ]] && source ~/.zsh_functions

# git の作業
function checkout_origin_pr {
  if [[ $# -ne 1 ]]; then
    echo "Usage: checkout_origin_pr <PR_NUMBER>"
    return 1
  fi

  local pr_number=$1
  local pr_branch="pr-$pr_number"

  echo "Fetching PR #$pr_number from origin..."
  if ! git fetch origin "pull/$pr_number/head:$pr_branch"; then
    echo "Error: Failed to fetch PR #$pr_number"
    return 1
  fi

  echo "Checking out PR #$pr_number as $pr_branch"
  git checkout "$pr_branch"
}
alias gcpr='checkout_origin_pr'

function checkout_upstream_pr {
  if [[ $# -ne 1 ]]; then
    echo "Usage: checkout_upstream_pr <PR_NUMBER>"
    return 1
  fi

  local pr_number=$1
  local pr_branch="upstream-pr-$pr_number"

  echo "Fetching PR #$pr_number from upstream..."
  if ! git fetch upstream "pull/$pr_number/head:$pr_branch"; then
    echo "Error: Failed to fetch PR #$pr_number"
    return 1
  fi

  echo "Checking out PR #$pr_number as $pr_branch"
  git checkout "$pr_branch"
}
alias gcupr='checkout_upstream_pr'

function checkout_merge_base_commit {
  if [[ $# -ne 3 ]]; then
    echo "Usage: checkout_merge_base_commit <new-branch-name> <branch-A> <branch-B>"
    return 1
  fi

  local new_branch=$1
  local branch_a=$2
  local branch_b=$3

  local base_commit
  if ! base_commit=$(git merge-base "$branch_a" "$branch_b"); then
    echo "Error: Failed to find merge-base between $branch_a and $branch_b"
    return 1
  fi

  echo "Creating branch '$new_branch' at merge-base commit $base_commit..."
  if ! git branch "$new_branch" "$base_commit"; then
    echo "Error: Failed to create branch '$new_branch'"
    return 1
  fi

  echo "Switching to branch '$new_branch'"
  if ! git checkout "$new_branch"; then
    echo "Error: Failed to checkout branch '$new_branch'"
    return 1
  fi
}
alias gcmb='checkout_merge_base_commit'

function git_switch_branch_with_suffix() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: git_switch_branch_with_suffix <suffix>"
    return 1
  fi

  local suffix=$1

  local current_branch
  if ! current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null); then
    echo "Error: Not a git repository or cannot determine the current branch."
    return 1
  fi

  local new_branch="${current_branch}-${suffix}"
  if git show-ref --verify --quiet "refs/heads/$new_branch"; then
    echo "Error: Branch '$new_branch' already exists."
    return 1
  fi

  echo "Creating and switching to branch: $new_branch"
  if ! git switch -c "$new_branch"; then
    echo "Error: Failed to create and switch to branch '$new_branch'."
    return 1
  fi
}
alias gscws='git_switch_branch_with_suffix'

function update_git_repos() {
  local BASE_DIR="$HOME/workspace"

  if [[ ! -d "$BASE_DIR" ]]; then
    echo "Error: BASE_DIR ($BASE_DIR) does not exist."
    return 1
  fi

  for dir in "$BASE_DIR"/*/*/; do
    if [[ -d "$dir" && -d "$dir/.git" ]]; then
      echo "Processing: $dir"
      cd "$dir" || continue

      local DEFAULT_BRANCH
      DEFAULT_BRANCH=$(git remote show origin | awk '/HEAD branch/ {print $NF}')

      if [[ -n "$DEFAULT_BRANCH" ]]; then
        echo "Pulling latest changes from $DEFAULT_BRANCH..."
        git checkout "$DEFAULT_BRANCH" && git pull origin "$DEFAULT_BRANCH"
      else
        echo "Warning: Could not determine default branch for $dir"
      fi

      cd "$BASE_DIR" || return 1
    else
      echo "Skipping (not a git repository): $dir"
    fi
  done

  echo "All repositories updated."
}
alias ugr='update_git_repos'

# 本体を { } ではなく ( ) にして、中の cd を呼び出し元のシェルに残さない
function git_prune_local() (
  cd "$(git worktree list --porcelain | sed -n '1s/^worktree //p')" || exit
  # followRemoteHEAD を既定の create のままにしないのは、origin/HEAD が無いときに作るだけで、デフォルトブランチの名前が変わっても古いブランチを指したままになるため
  git -c remote.origin.followRemoteHEAD=always fetch --prune || exit

  local default_branch
  default_branch=$(git symbolic-ref --short refs/remotes/origin/HEAD) || exit
  default_branch=${default_branch#origin/}

  git switch "$default_branch" || exit
  git pull || exit

  git worktree prune
  git worktree list --porcelain | sed -n 's/^worktree //p' | tail -n +2 | while read -r worktree; do
    git worktree remove "$worktree"
  done
  git for-each-ref --format='%(refname:short)' refs/heads | grep -vxF "$default_branch" | while read -r branch; do
    git branch -D "$branch"
  done

  mise install
)
alias pralias='git_prune_local'

function git_prune_local_all() {
  local git_dir
  for git_dir in **/.git(N/); do
    echo "== ${git_dir:h}"
    (cd "${git_dir:h}" && git_prune_local)
  done
}
alias praliasall='git_prune_local_all'

function expo-config() {
  APP_ENV="$1" npx expo config --type public
}

# ===========================
# 補完
# ===========================

# ほかの設定より前に置かないのは、ここで inshellisense のシェルに切り替わり、元のシェルはこの行より後ろを読まずに終わるため
[[ -f "$HOME/.local/share/inshellisense/init/zsh/init.zsh" ]] && source "$HOME/.local/share/inshellisense/init/zsh/init.zsh"
