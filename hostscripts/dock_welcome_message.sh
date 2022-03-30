#!/usr/bin/env bash
source $HOME/.dockrc
source $DOCK_PATH/lib/container.sh
source $BASHJAZZ_PATH/utils/formatting.sh

user=${1:-root}

# To disable welcome messages from being printed upon connecting
# simply add DISABLE_DOCK_WELCOME MESSAGE=1 into ~/.dockrc 
if [[ -z $DISABLE_DOCK_WELCOME_MESSAGE ]]; then

  # This file will first print a generic short welcome message that
  # applies to all images regardless, and then invoke and print the output of the
  # usr/local/etc/welcome_message.sh file inside the running container
  # (provided it exists).
  #
  # Additionally, you can create specific welcome messages for each individual
  # user inside the container by creating ~/dock_bin/welcome_message.sh files
  # that will besourced from the /usr/local/etc/welcome_message.sh as well. 

  # 1. Printing generic welcome message from the host.
  printf "$(color dim)"
  printf "  | Thank you for using $(color blue)dock$(color off).$(color dim)
  | Full documentation along with the
  | repository and maintainers contact info can currently be found at
  | $(color light_blue)https://dock.orion3.space. $(color off)Type $(color cyan)exit$(color off) to return to host.\n\n"


  btc_addr="$(cat $DOCK_PATH/DONATE | grep -Eo 'bc1.*$')"
  printf "  • Consider donating Bitcoin to $(color yellow)$btc_addr$(color off)
  • and visiting $(color light_blue)https://dock.orion3.space/donate$(color off) to learn about
  • alternative payment methods for donations and purposes
  • for which donations will be used. Thank you.\n"

  # 2. Printing welcome message from the container with some additional info.
  #    This is where you'd normally put some details about the OS and software
  #    installed and some other things.
  printf "$(color dim)"
  Container_exec -u $user \
    'test -f /usr/local/etc/welcome_message.sh && /usr/local/etc/welcome_message.sh'
  printf "$(color off)"

fi
