#!/usr/bin/env bash
source $HOME/.dockrc

# TODO: Currently is only useful in Tilix Terminal. Add other popular
#       terminals support.
#       See documentation/TERMINALS.txt

if [[ $ssh_username == "root" ]]; then
  ssh_terminal_theme=$TERMINAL_ROOT_THEME
fi

if [[ -z $ssh_terminal_theme ]]; then
  ssh_terminal_theme="${TERMINAL_THEMES[$project_name]}"
  if [[ -z $ssh_terminal_theme ]]; then
    ssh_terminal_theme="${TERMINAL_THEMES["$project_base_name"]}"
  fi
fi
if [[ -z $ssh_terminal_theme ]]; then ssh_terminal_theme="Dockguest"; fi

# Makes terminal program do things (such as changing color in Tilix)
# when HOSTNAME changes, which is accomplished below with:
TerminalTheme_change_to_container_theme() {
  printf "\033]7;file://%s/\007" "${ssh_terminal_theme}"
}

# Revert to the original theme when exiting the container.
TerminalTheme_revert_to_original() {
  printf "\033]7;file://%s/\007" "default:"
}
