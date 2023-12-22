PATH=$HOME/bin:$PATH

# Because we want UTF-8
source /etc/default/locale

export ZSH=$HOME/.zsh
export VISUAL=vim
export EDITOR="$VISUAL"
export TERM="xterm-256color"
export ZSH_DISABLE_COMPFIX=true
export DISABLE_AUTO_UPDATE=true
setopt prompt_subst # allows for prompt substitution and functions in PS1, PS1, RPS1 and RPS2
unsetopt correct_all
CASE_SENSITIVE="true"
ENABLE_CORRECTION=false


# Gets rid of % sign at the end of and output that occasionally shows due to
# the so called "partial line". Happens with curl output, for example. More on this here:
#   * Official man: https://zsh.sourceforge.io/Doc/Release/Options.html#Prompting
#   * Solution: https://unix.stackexchange.com/questions/167582/why-zsh-ends-a-line-with-a-highlighted-percent-symbol
PROMPT_EOL_MARK=''

# Search history with text already entered at the prompt
autoload -U history-search-end
setopt no_share_history
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[[A" history-substring-search-up
bindkey "^[[B" history-substring-search-down

export ZSH=$HOME/.zsh

# see $ZSH/themes
# If the the host machine doesn't have font-awesome installed some of they icons
# will appear as blank charachters. For example this if you don't see this Docker logo icon  
# it means your system doesn't have FontAwesome. But that's fine: we'll just use
# common utf-charachters instead by setting a non-font-awesome theme.
if [[ -n "DOCK_HOST_FONTAWESOME_INSTALLED" ]]; then
  ZSH_THEME='dock0'
else
  ZSH_THEME='dock0_no_fontawesome'
fi

# Note, this isn't actually full .oh-my-zsh installation with all the plugins no one ever uses.
# This is just one file copied from the original source. We source this file, because it's
# has convenient functions for loading plugins, but this while .oh-my-zsh installation thing
# with tons of stuff - anyone should avoid that on any machines, not just inside containers.
# 
# First we list plugins to load in an array, which is actually one of the few useful
# things .oh-my-zsh provides. The rest are mostly expendable.
plugins=( git-prompt history-substring-search )

# Prevents Vim from freezing up when Ctrl+s is pressed,
# which is a shortcut for :wq that's already set in .vimrc
stty -ixon

source $ZSH/oh-my-zsh.sh

if test -e "$HOME/.shared_shell_env"; then
  source $HOME/.shared_shell_env
fi