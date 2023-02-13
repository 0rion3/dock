if [ -d $ZSH/plugins/git-prompt ]; then

  ZSH_THEME_GIT_PROMPT_PREFIX=" "
  ZSH_THEME_GIT_PROMPT_SUFFIX=""
  ZSH_THEME_GIT_PROMPT_SEPARATOR=" %F{7}|%f "
  ZSH_THEME_GIT_PROMPT_SEPARATOR_2=""
  ZSH_THEME_GIT_PROMPT_DETACHED="%{$fg_bold[cyan]%}:"
  ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg_bold[magenta]%}"
  ZSH_THEME_GIT_PROMPT_UPSTREAM_SYMBOL="%{$fg_bold[yellow]%}⟳ "
  ZSH_THEME_GIT_PROMPT_UPSTREAM_PREFIX=" %{$fg[red]%}(%{$fg[yellow]%}"
  ZSH_THEME_GIT_PROMPT_UPSTREAM_SUFFIX="%{$fg[red]%})"
  ZSH_THEME_GIT_PROMPT_BEHIND=" ↓"
  ZSH_THEME_GIT_PROMPT_AHEAD=" ↑"
  ZSH_THEME_GIT_PROMPT_UNMERGED=" %{$fg_bold[red]%} "
  ZSH_THEME_GIT_PROMPT_STAGED=" %{$fg[green]%} $Bold"
  ZSH_THEME_GIT_PROMPT_UNSTAGED=" %{$fg_bold[yellow]%} "
  ZSH_THEME_GIT_PROMPT_UNTRACKED=" %F{7} %B"
  ZSH_THEME_GIT_PROMPT_STASHED=" %{$fg_bold[blue]%}⚑ "
  ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✔ "
  unset ZSH_GIT_PROMPT_SHOW_STASH

  ZSH_GIT_BRANCH_NAME_LENGTH=10
  ZSH_GIT_SHOW_LAST_COMMIT_SHA=1

  # Theming variables for the secondary prompt
  ZSH_THEME_GIT_PROMPT_SECONDARY_PREFIX=""
  ZSH_THEME_GIT_PROMPT_SECONDARY_SUFFIX=""
  ZSH_THEME_GIT_PROMPT_TAGS_SEPARATOR=", "
  ZSH_THEME_GIT_PROMPT_TAGS_PREFIX="🏷 "
  ZSH_THEME_GIT_PROMPT_TAGS_SUFFIX=""
  ZSH_THEME_GIT_PROMPT_TAG="%F{24}"
  ZSH_THEME_GIT_PROMT_LAST_COMMIT_SHA="%F{244}"

fi

PROJECT_DIR="$HOME/main"
path_prompt() {
  if [[ $PWD == $PROJECT_DIR/* ]]; then
    path="${PWD/#$PROJECT_DIR/ }"
    echo "%{$fg[green]%}%$path%{$reset_color%}"
  elif [[ $PWD != $PROJECT_DIR ]]; then
    echo " %{$fg[green]%}%~%{$reset_color%}"
  fi
}

EXTRA_SPACE="\u20"
CONTAINER_ICON="⊡"
PATH_PROMPT='$(path_prompt)'
# This conditional allows users to define their own prompt in .zshrc and get
# it overwritten by a file that loads the mounted read-only version of .zshrc
# from the host machine.
if [[ -z DOCKER_PROMPT ]]; then
  DOCKER_PROMPT="%F{244}% $CONTAINER_ICON $DOCKER_IMAGE_SUFFIX%{$fg_bold[blue]%} ⋑ $DOCKER_PROJECT_BASE_NAME%{$reset_color%}"
fi
PROMPT="$DOCKER_PROMPT$PATH_PROMPT %{$fg[yellow]%}\$%f "
RPROMPT=""
RPROMPT='$(gitprompt)'
