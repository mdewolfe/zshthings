#!/usr/bin/env zsh

logit() {
  echo "\n"
  git --no-pager log \
    --pretty=format:"%C(magenta)%h%x09%C(red)%an%x09%C(white)%ad%x09%C(yellow)%s" \
    -n 10
  echo "\n"
}

git_checkout() {
  isgitrepo=$(git rev-parse --is-inside-work-tree)
  if [ -z $isgitrepo ]; then
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    >&2 echo -e "\n${RED}No branch to checkout!${NC}\n"
    return 0
  fi

  current_branch=$(git rev-parse --abbrev-ref HEAD)
  selected_branch=$(git branch | \
    rg -v "^\* $current_branch" | \
    sed 's/^[[:space:]]*//' | \
    fzf -i +m --no-mouse \
      --border=rounded --border-label-pos=4:bottom --border-label=" Current: $current_branch " \
      --preview='git --no-pager log {} -n 5' \
      --color=dark | \
    tr -d '[:space:]'
  )
  if [ -z "$selected_branch" ]; then
    return 0
  fi

  echo "\n"
  git checkout $selected_branch
  logit

  return 0
}
alias ggch='git_checkout'

git_checkout_tag() {
  isgitrepo=$(git rev-parse --is-inside-work-tree)
  if [ -z $isgitrepo ]; then
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    >&2 echo -e "\n${RED}No branch to checkout!${NC}\n"
    return 0
  fi

  git diff-index --cached --quiet HEAD --
  local staged=$?
  if [ $staged -eq 1 ]; then
    echo "\n\033[0;31mHAS STAGED STAGED CHANGES\033[0m\n\n" >&2
    return 1
  fi

  git diff-index --quiet HEAD --
  local unstaged=$?
  if [ $unstaged -eq 1 ]; then
    echo "\n\033[0;31mHAS UNSTAGED CHANGES!!\033[0m\n\n" >&2
    return 1
  fi

  local current_branch=$(git rev-parse --abbrev-ref HEAD)
  local selected_tag=$(git tag | \
    sed 's/^[[:space:]]*//' | \
    fzf -i +m --no-mouse \
      --border=rounded --border-label-pos=4:bottom --border-label=" Current: $current_branch " \
      --preview='git --no-pager log {} -n 5' \
      --color=dark | \
    tr -d '[:space:]'
  )
  if [ -z "$selected_tag" ]; then
    return 0
  fi

  echo "\n"
  git checkout $selected_tag
  logit

  return 0
}
alias ggcot='git_checkout_tag'

git_checkout_commit() {
  git diff-index --cached --quiet HEAD --
  local staged=$?
  if [ $staged -eq 1 ]; then
    echo "\nHAS STAGED: ${staged}\n\n"
    return 0
  fi

  git diff-index --quiet HEAD --
  local unstaged=$?
  if [ $unstaged -eq 1 ]; then
    echo "\nHAS UNSTAGED: ${unstaged}\n\n" >&2
    return 0
  fi

  selected_ref=$(git --no-pager log --pretty=format:"%h %an %s %ad" -n 30 | \
    fzf -i +m --no-mouse \
      --border=rounded --border-label-pos=4:bottom --border-label=" Checkout commit... " \
      --preview='echo {} | cut -d" " -f1 | xargs git --no-pager show --color=always -s' \
      --color=dark | \
    cut -d " " -f1
  )

  if [ -z $selected_ref ]; then
    echo "No ref selected" >&2
    return 0
  fi

  git checkout $selected_ref
}
alias ggcc='git_checkout_commit'

git_reset_hard() {
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  git fetch origin $current_branch
  git reset --hard origin/$current_branch
  logit

  return 0
}
alias ggrsh='git_reset_hard'

git_rebase_default_branch() {
  local default_branch=$(<.default_branch)
  git fetch origin $default_branch && \
    git rebase origin/$default_branch && \
    echo "\n\n" && \
    git status &&
    logit
  return 0
}
alias ggrbd='git_rebase_default_branch'

git_reset_hard_default_branch() {
  # TODO: add confirmation
  local default_branch=$(<.default_branch)
    git fetch origin $default_branch && \
    git reset --hard origin/$default_branch && \
    echo "\n\n" && \
    git status && \
    logit
  return 0
}
alias ggrshd='git_reset_hard_default_branch'

git_checkout_default_branch() {
  local default_branch=$(<.default_branch)
  git checkout $default_branch
  logit
  return 0
}
alias ggcd="git_checkout_default_branch"

git_pull_default_branch() {
  local default_branch=$(<.default_branch)
  git pull origin $default_branch
  return 0
}
alias ggpdb="git_pull_default_branch"

git_reset_soft_to_ref() {
  isgitrepo=$(git rev-parse --is-inside-work-tree)
  if [ -z $isgitrepo ]; then
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    >&2 echo -e "\n${RED}Not a git repo!${NC}\n"
    return 0
  fi

  selected_ref=$(git --no-pager log --pretty=format:"%h %an %s %ad" -n 30 | \
    fzf -i +m --no-mouse \
      --border=rounded --border-label-pos=4:bottom --border-label=" Reset Soft To... " \
      --preview='echo {} | cut -d" " -f1 | xargs git --no-pager show --color=always -s' \
      --color=dark | \
    cut -d " " -f1
  )
  if [ -z "$selected_ref" ]; then
    echo "No ref selected" >&2
    return 0
  fi

  git reset --soft $selected_ref
  logit
  return 0
}
alias ggrss="git_reset_soft_to_ref"

git_show_status() {
  echo "\n"
  git status && logit
  return 0
}
alias ggst='git_show_status'


git_full_checkout() {
  if [ -z "$1" ]; then
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    >&2 echo -e "${RED}No branch to checkout!${NC}"
    return 1
  fi

  echo "\nChecking moving to branch $1\n"

  git fetch origin $1 && git checkout $1 && git reset --hard origin/$1 && logit
}
alias ggfco="git_full_checkout"

git_push_origin() {
  git push origin $(git rev-parse --abbrev-ref HEAD)
}
alias ggpo='git_push_origin'

git_push_current_branch() {
  local current_branch

  ORANGE=$'\033[38;5;208m'
  YELLOW=$'\033[0;33m'
  NC=$'\033[0m' # No Color
  if ! current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null); then
    echo "\n${YELLOW}Not a Git repo${NC}\n\n"
    return 0
  fi

  if [[ $current_branch == "HEAD" ]]; then
    echo "\n${YELLOW}In a detached HEAD state.${NC}\n\n"
    return 0
  fi

  git push origin $current_branch
}
alias ggpb='git_push_current_branch'

git_push_origin_hard() {
  local current_branch

  ORANGE=$'\033[38;5;208m'
  YELLOW=$'\033[0;33m'
  NC=$'\033[0m' # No Color
  if ! current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null); then
    echo "\n${YELLOW}Not a Git repo${NC}\n\n"
    return 0
  fi

  if [[ $current_branch == "HEAD" ]]; then
    echo "\n${YELLOW}In a detached HEAD state.${NC}\n\n"
    return 0
  fi

  echo "\n\n"
  read -qs "choice?${YELLOW}CONFIRM${NC} git push -f ${ORANGE}origin $current_branch${NC}? (y/n) "
  echo

  if [[ ! $choice =~ ^[Yy] ]]; then
    echo "Aborting git push -f $current_branch"
    return 0
  fi

  git push -f origin $current_branch
}
alias ggpf='git_push_origin_hard'
