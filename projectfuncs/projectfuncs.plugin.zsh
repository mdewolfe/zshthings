#!/usr/bin/env zsh

go_to_project() {
  selected_dir=$(
    fd -a -t d -d 1 --color=never . $HOME/Documents/projects | \
    fzf +s -i +m --no-mouse --scheme=path \
      --border=rounded --border-label-pos=4:bottom --border-label=" Got To Project " \
      --color=dark \
      --preview='bat --color=always -r :55 -l md {}README.md 2>/dev/null || echo "No README Found"' \
      --preview-window=right,60% \
      --preview-label='README.md' \
      --preview-label-pos=4:bottom
  )

  if [ -z "$selected_dir" ]; then
    echo "\nNothing chosen!\n"
    return 0
  fi

  cd $selected_dir

  return 0
}
alias gtp='go_to_project'


go_to_project_root() {
  local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -n $git_root ]]; then
    cd "$git_root" || return
  else
    echo "\033[31mNot inside a Git repository\033[0m" >&2
  fi
}
alias gtpr='go_to_project_root'
