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
    fzf --tmux 80% -i +m --no-mouse \
      --border=rounded --border-label-pos=4:bottom --border-label=" Current: $current_branch " \
      --color=dark | \
    tr -d '[:space:]'
  )
  if [ -z "$selected_branch" ]; then
    return 1
  fi

  echo "\n"
  git checkout $selected_branch
  logit

  return 0
}
alias ggch='git_checkout'

git_reset_hard() {
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  git fetch origin $current_branch
  git reset --hard origin/$current_branch
  logit

  return 0
}
alias ggrsh='git_reset_hard'

git_rebase_default_branch() {
  read -r default_branch < default_branch.txt
  git fetch origin $default_branch && \
    git rebase origin/$default_branch && \
    echo "\n\n" && \
    git status &&
    logit
  return 0
}
alias ggrbd='git_rebase_default_branch'

git_reset_hard_default_branch() {
  read -r default_branch<default_branch.txt && \
    git fetch origin $default_branch && \
    git reset --hard origin/$default_branch && \
    echo "\n\n" && \
    git status && \
    logit
  return 0
}
alias ggrshd='git_reset_hard_default_branch'

git_checkout_default_branch() {
  read -r default_branch<default_branch.txt
  git checkout $default_branch
  logit
  return 0
}
alias ggcd="git_checkout_default_branch"

git_pull_default_branch() {
  read -r default_branch<default_branch.txt
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
    fzf --tmux 80% -i +m --no-mouse \
      --border=rounded --border-label-pos=4:bottom --border-label=" Reset Soft To... " \
      --color=dark | \
    cut -d " " -f1
  )
  if [ -z "$selected_ref" ]; then
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

git_push_origin_hard() {
  current_branch=$(git rev-parse --abbrev-ref HEAD)

  ORANGE=$'\033[38;5;208m'
  YELLOW=$'\033[0;33m'
  NC=$'\033[0m' # No Color

  echo "\n\n\n"
  read -qs "choice?${YELLOW}CONFIRM${NC} git push -f ${ORANGE}origin $current_branch${NC}? (y/n) "
  echo

  if [[ ! $choice =~ ^[Yy] ]]; then
    echo "Aborting git push -f $current_branch"
    return 0
  fi

  git push -f origin $current_branch
}
alias ggpf='git_push_origin_hard'
